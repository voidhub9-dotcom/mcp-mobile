import { DISCORD_RICH_PRESENCE, DISCORD_RPC_CLIENT_ID, DISCORD_RPC_LARGE_IMAGE } from "../config.js";
import { getClientById, getActiveClientId, getActiveClients } from "../bridge/handlers/shared/registry.js";
import type { RobloxClient } from "../bridge/types.js";
import { connectDiscordIpc, DiscordRpcError, type DiscordActivity, type DiscordIpcConnection } from "./rpc.js";

const TICK_MS = 5000;

type PresenceState = "disabled" | "enabled";

let state: PresenceState = DISCORD_RICH_PRESENCE ? "enabled" : "disabled";
let clientId: string | null = DISCORD_RPC_CLIENT_ID || null;
let connection: DiscordIpcConnection | null = null;
let lastSignature: string | null = null;
let lastError: string | null = null;
let lastAttemptAt = 0;
let timer: NodeJS.Timeout | null = null;
let startedAt = 0;

export function buildActivityForClient(client: RobloxClient, now = Date.now()): DiscordActivity {
    return {
        details: `Playing ${client.placeName || client.placeId}`,
        state: `as ${client.username}`,
        timestamps: { start: client.connectedAt || now },
        ...(DISCORD_RPC_LARGE_IMAGE
            ? {
                  assets: {
                      large_image: DISCORD_RPC_LARGE_IMAGE,
                      large_text: client.placeName || String(client.placeId),
                      small_text: client.mobile ? `mobile (${client.executor ?? "mobile"})` : "desktop",
                  },
              }
            : {}),
    };
}

function pickClient(): RobloxClient | undefined {
    const activeId = getActiveClientId();
    if (activeId) {
        const active = getClientById(activeId);
        if (active)
            return active;
    }
    return getActiveClients()[0];
}

async function ensureConnection(): Promise<DiscordIpcConnection | null> {
    if (!clientId) {
        lastError = "No Discord application client ID configured. Pass clientId or set DISCORD_RPC_CLIENT_ID.";
        return null;
    }
    if (connection?.isConnected())
        return connection;
    if (Date.now() - lastAttemptAt < 15_000)
        return null;
    lastAttemptAt = Date.now();
    try {
        connection = await connectDiscordIpc(clientId);
        lastError = null;
        console.error(`[Discord RPC] Connected to the local Discord client (app ${clientId}).`);
        lastSignature = null;
        return connection;
    }
    catch (err) {
        connection = null;
        lastError = err instanceof DiscordRpcError ? err.message : String(err);
        return null;
    }
}

async function refreshPresence(): Promise<void> {
    if (state !== "enabled")
        return;
    const client = pickClient();
    const conn = await ensureConnection();
    if (!conn)
        return;
    const signature = client
        ? `${client.clientId}:${client.placeId}:${client.jobId}:${client.username}:${client.connectedAt}`
        : "none";
    if (signature === lastSignature)
        return;
    lastSignature = signature;
    try {
        if (!client) {
            await conn.setActivity(null);
            return;
        }
        await conn.setActivity(buildActivityForClient(client));
        console.error(`[Discord RPC] Presence updated: ${client.username} @ ${client.placeName || client.placeId}.`);
    }
    catch (err) {
        lastError = err instanceof Error ? err.message : String(err);
        lastSignature = null;
        conn.close();
        connection = null;
    }
}

export function startDiscordPresence(): void {
    if (timer)
        return;
    startedAt = Date.now();
    timer = setInterval(() => {
        void refreshPresence();
    }, TICK_MS);
    timer.unref();
    void refreshPresence();
}

export async function setDiscordPresenceEnabled(enabled: boolean, explicitClientId?: string): Promise<void> {
    if (explicitClientId) {
        const previous = clientId;
        clientId = explicitClientId.trim();
        if (previous && previous !== clientId) {
            connection?.close();
            connection = null;
            lastSignature = null;
        }
    }
    if (enabled) {
        state = "enabled";
        lastSignature = null;
        await refreshPresence();
        return;
    }
    state = "disabled";
    if (connection?.isConnected()) {
        try {
            await connection.setActivity(null);
        }
        catch {
        }
    }
    connection?.close();
    connection = null;
    lastSignature = null;
}

export function getDiscordPresenceStatus(): {
    state: `${PresenceState}`;
    clientId: string | null;
    connected: boolean;
    activityClient: string | null;
    lastError: string | null;
} {
    const client = pickClient();
    return {
        state,
        clientId,
        connected: connection?.isConnected() === true,
        activityClient: client ? `${client.username} @ ${client.placeName || client.placeId}` : null,
        lastError,
    };
}

export function presenceRunningForMs(now = Date.now()): number {
    return timer && startedAt ? now - startedAt : 0;
}

export function formatDiscordPresenceStatusForTool(): string {
    const status = getDiscordPresenceStatus();
    const lines = [
        `Discord Rich Presence is ${status.state}.`,
        status.clientId ? `Application ID: ${status.clientId}` : "Application ID: not configured",
        `IPC connection: ${status.connected ? "connected" : "not connected"}`,
        status.activityClient ? `Showing: ${status.activityClient}` : "Showing: nothing (no active Roblox client)",
    ];
    if (status.lastError)
        lines.push(`Last error: ${status.lastError}`);
    return lines.join("\n");
}
