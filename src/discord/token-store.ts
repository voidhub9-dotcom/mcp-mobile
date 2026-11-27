import crypto from "node:crypto";
import fs from "node:fs/promises";
import { withFileTransaction, writeJsonAtomic } from "../shared/atomic-json.js";
import { DISCORD_TOKEN_STORE_PATH, TOKEN_ENCRYPTION_KEY } from "./config.js";

// Encrypted-at-rest store for Discord OAuth tokens, keyed by MCP user key
// (currently always "default", since the server has one shared MCP_AUTH_TOKEN).

export interface DiscordLink {
    discordUserId: string | null;
    /** Display name / avatar from the OpenID id_token, when Discord includes them. */
    discordUsername?: string | null;
    discordAvatarUrl?: string | null;
    accessToken: string;
    refreshToken: string | null;
    /** epoch ms */
    expiresAt: number;
    scope: string;
    linkedAt: number;
    /** Current headless-session token, so a restart can still clear the old presence. */
    sessionToken?: string | null;
}

interface EncryptedBlob {
    iv: string;
    tag: string;
    data: string;
}

interface StoreFile {
    version: 1;
    links: Record<string, EncryptedBlob>;
}

let cachedKey: Buffer | null | undefined;
let warnedNoKey = false;

/**
 * Accepts 64 hex chars or base64 that decodes to exactly 32 bytes. Anything
 * else is stretched with SHA-256 (with a warning) rather than crashing boot.
 */
export function resolveEncryptionKey(raw: string | null = TOKEN_ENCRYPTION_KEY): Buffer | null {
    if (!raw)
        return null;
    if (/^[0-9a-fA-F]{64}$/.test(raw))
        return Buffer.from(raw, "hex");
    try {
        const b64 = Buffer.from(raw, "base64");
        if (b64.length === 32)
            return b64;
    }
    catch {
        // fall through
    }
    console.error("[Discord] TOKEN_ENCRYPTION_KEY is not 32 bytes (64 hex chars or base64). Deriving a key with SHA-256; generate a proper key with `openssl rand -hex 32`.");
    return crypto.createHash("sha256").update(raw, "utf8").digest();
}

function getKey(): Buffer | null {
    if (cachedKey === undefined)
        cachedKey = resolveEncryptionKey();
    if (!cachedKey && !warnedNoKey) {
        warnedNoKey = true;
        console.error("[Discord] TOKEN_ENCRYPTION_KEY is not set. Discord account linking is disabled because tokens cannot be stored encrypted.");
    }
    return cachedKey;
}

export function tokenStorageAvailable(): boolean {
    return getKey() !== null;
}

export function encryptJson(value: unknown, key: Buffer): EncryptedBlob {
    const iv = crypto.randomBytes(12);
    const cipher = crypto.createCipheriv("aes-256-gcm", key, iv);
    const data = Buffer.concat([cipher.update(JSON.stringify(value), "utf8"), cipher.final()]);
    return { iv: iv.toString("base64"), tag: cipher.getAuthTag().toString("base64"), data: data.toString("base64") };
}

export function decryptJson<T>(blob: EncryptedBlob, key: Buffer): T {
    const decipher = crypto.createDecipheriv("aes-256-gcm", key, Buffer.from(blob.iv, "base64"));
    decipher.setAuthTag(Buffer.from(blob.tag, "base64"));
    const plain = Buffer.concat([decipher.update(Buffer.from(blob.data, "base64")), decipher.final()]);
    return JSON.parse(plain.toString("utf8")) as T;
}

async function readStore(): Promise<StoreFile> {
    try {
        const raw = await fs.readFile(DISCORD_TOKEN_STORE_PATH, "utf8");
        const parsed = JSON.parse(raw) as Partial<StoreFile>;
        if (parsed && typeof parsed.links === "object" && parsed.links)
            return { version: 1, links: parsed.links };
    }
    catch {
        // missing or unreadable: start empty
    }
    return { version: 1, links: {} };
}

// Decrypted links are cached in memory so the tool hot path rarely touches disk.
// Entries expire so that other server processes sharing the same store file
// (e.g. several local stdio instances) notice a link/unlink within CACHE_TTL_MS.
const CACHE_TTL_MS = 30_000;
const memory = new Map<string, { link: DiscordLink | null; at: number }>();

export async function getLink(userKey: string): Promise<DiscordLink | null> {
    const cached = memory.get(userKey);
    if (cached && Date.now() - cached.at < CACHE_TTL_MS)
        return cached.link;
    const key = getKey();
    if (!key)
        return null;
    const store = await readStore();
    const blob = store.links[userKey];
    let link: DiscordLink | null = null;
    if (blob) {
        try {
            link = decryptJson<DiscordLink>(blob, key);
        }
        catch {
            console.error(`[Discord] Could not decrypt stored token for "${userKey}" (TOKEN_ENCRYPTION_KEY changed?). Re-link at /auth/discord.`);
        }
    }
    memory.set(userKey, { link, at: Date.now() });
    return link;
}

export async function saveLink(userKey: string, link: DiscordLink): Promise<void> {
    const key = getKey();
    if (!key)
        throw new Error("TOKEN_ENCRYPTION_KEY is not configured.");
    memory.set(userKey, { link, at: Date.now() });
    await withFileTransaction(DISCORD_TOKEN_STORE_PATH, async () => {
        const store = await readStore();
        store.links[userKey] = encryptJson(link, key);
        await writeJsonAtomic(DISCORD_TOKEN_STORE_PATH, store);
    });
}

export async function deleteLink(userKey: string): Promise<void> {
    memory.set(userKey, { link: null, at: Date.now() });
    await withFileTransaction(DISCORD_TOKEN_STORE_PATH, async () => {
        const store = await readStore();
        if (!(userKey in store.links))
            return;
        delete store.links[userKey];
        await writeJsonAtomic(DISCORD_TOKEN_STORE_PATH, store);
    });
}
