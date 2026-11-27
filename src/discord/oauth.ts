import crypto from "node:crypto";
import { DISCORD_API_BASE, DISCORD_AUTHORIZE_URL, DISCORD_CLIENT_ID, DISCORD_CLIENT_SECRET, DISCORD_HTTP_TIMEOUT_MS, DISCORD_REDIRECT_URI, DISCORD_SCOPES, } from "./config.js";
import { getLink, saveLink, type DiscordLink } from "./token-store.js";

// Discord OAuth2: authorize URL, code exchange, refresh, revoke.

interface TokenResponse {
    access_token: string;
    refresh_token?: string;
    expires_in: number;
    scope: string;
    token_type: string;
    id_token?: string;
}

/** Refresh when the access token has less than this left. */
const REFRESH_MARGIN_MS = 5 * 60_000;

// CSRF state -> { userKey, expires }. One-time use, 10 minute lifetime.
const pendingStates = new Map<string, { userKey: string; expires: number }>();
const STATE_TTL_MS = 10 * 60_000;

export function createAuthorizeUrl(userKey: string): { url: string; state: string } {
    const now = Date.now();
    for (const [s, v] of pendingStates)
        if (v.expires < now)
            pendingStates.delete(s);
    const state = crypto.randomBytes(24).toString("base64url");
    pendingStates.set(state, { userKey, expires: now + STATE_TTL_MS });
    const params = new URLSearchParams({
        response_type: "code",
        client_id: DISCORD_CLIENT_ID ?? "",
        redirect_uri: DISCORD_REDIRECT_URI ?? "",
        scope: DISCORD_SCOPES.join(" "),
        state,
        prompt: "consent",
    });
    return { url: `${DISCORD_AUTHORIZE_URL}?${params.toString()}`, state };
}

/** Returns the userKey the state was issued for, or null if unknown/expired. Consumes it. */
export function consumeState(state: string | null): string | null {
    if (!state)
        return null;
    const entry = pendingStates.get(state);
    pendingStates.delete(state);
    if (!entry || entry.expires < Date.now())
        return null;
    return entry.userKey;
}

function clientAuthHeader(): string {
    return "Basic " + Buffer.from(`${DISCORD_CLIENT_ID}:${DISCORD_CLIENT_SECRET}`).toString("base64");
}

async function tokenRequest(body: Record<string, string>): Promise<TokenResponse> {
    const resp = await fetch(`${DISCORD_API_BASE}/oauth2/token`, {
        method: "POST",
        headers: {
            "Content-Type": "application/x-www-form-urlencoded",
            Authorization: clientAuthHeader(),
        },
        body: new URLSearchParams(body).toString(),
        signal: AbortSignal.timeout(DISCORD_HTTP_TIMEOUT_MS),
    });
    const text = await resp.text();
    if (!resp.ok) {
        const err = new Error(`Discord token endpoint returned ${resp.status}: ${text.slice(0, 300)}`) as Error & { status?: number; body?: string };
        err.status = resp.status;
        err.body = text;
        throw err;
    }
    return JSON.parse(text) as TokenResponse;
}

/** Pull the Discord user id out of the OpenID id_token (`sub` claim). Signature isn't needed: it came straight from Discord over TLS. */
export function userIdFromIdToken(idToken: string | undefined): string | null {
    if (!idToken)
        return null;
    try {
        const payload = idToken.split(".")[1];
        const claims = JSON.parse(Buffer.from(payload, "base64url").toString("utf8")) as { sub?: unknown };
        return typeof claims.sub === "string" ? claims.sub : null;
    }
    catch {
        return null;
    }
}

async function fetchUserId(accessToken: string): Promise<string | null> {
    // /oauth2/@me works with any bearer token; `user` is present when Discord exposes it for the granted scopes.
    try {
        const resp = await fetch(`${DISCORD_API_BASE}/oauth2/@me`, {
            headers: { Authorization: `Bearer ${accessToken}` },
            signal: AbortSignal.timeout(DISCORD_HTTP_TIMEOUT_MS),
        });
        if (!resp.ok)
            return null;
        const data = (await resp.json()) as { user?: { id?: string } };
        return data.user?.id ?? null;
    }
    catch {
        return null;
    }
}

function toLink(tok: TokenResponse, previous: DiscordLink | null, discordUserId: string | null): DiscordLink {
    return {
        discordUserId: discordUserId ?? previous?.discordUserId ?? null,
        accessToken: tok.access_token,
        refreshToken: tok.refresh_token ?? previous?.refreshToken ?? null,
        expiresAt: Date.now() + Math.max(0, tok.expires_in) * 1000,
        scope: tok.scope,
        linkedAt: previous?.linkedAt ?? Date.now(),
        sessionToken: previous?.sessionToken ?? null,
    };
}

export async function exchangeCode(userKey: string, code: string): Promise<DiscordLink> {
    const tok = await tokenRequest({
        grant_type: "authorization_code",
        code,
        redirect_uri: DISCORD_REDIRECT_URI ?? "",
    });
    const discordUserId = userIdFromIdToken(tok.id_token) ?? (await fetchUserId(tok.access_token));
    const previous = await getLink(userKey);
    const link = toLink(tok, null, discordUserId);
    // Keep the previous session token so the old presence can still be cleared.
    link.sessionToken = previous?.sessionToken ?? null;
    await saveLink(userKey, link);
    return link;
}

// One refresh in flight per user, so concurrent tool calls don't burn the refresh token twice.
const refreshing = new Map<string, Promise<DiscordLink | null>>();

export async function refreshLink(userKey: string, link: DiscordLink): Promise<DiscordLink | null> {
    const inflight = refreshing.get(userKey);
    if (inflight)
        return inflight;
    const run = (async () => {
        if (!link.refreshToken)
            return null;
        try {
            const tok = await tokenRequest({ grant_type: "refresh_token", refresh_token: link.refreshToken });
            const next = toLink(tok, link, userIdFromIdToken(tok.id_token));
            const current = await getLink(userKey);
            if (!current || current.linkedAt !== link.linkedAt)
                return null; // unlinked or relinked while refreshing
            await saveLink(userKey, next);
            return next;
        }
        catch (err) {
            console.error(`[Discord] Token refresh failed for "${userKey}": ${(err as Error).message}`);
            return null;
        }
    })();
    refreshing.set(userKey, run);
    try {
        return await run;
    }
    finally {
        refreshing.delete(userKey);
    }
}

/** Linked token that is valid for at least REFRESH_MARGIN_MS more, refreshing if needed. */
export async function getValidLink(userKey: string): Promise<DiscordLink | null> {
    const link = await getLink(userKey);
    if (!link)
        return null;
    if (link.expiresAt - Date.now() > REFRESH_MARGIN_MS)
        return link;
    return (await refreshLink(userKey, link)) ?? (link.expiresAt > Date.now() ? link : null);
}

export async function revokeToken(token: string, hint: "access_token" | "refresh_token"): Promise<void> {
    try {
        await fetch(`${DISCORD_API_BASE}/oauth2/token/revoke`, {
            method: "POST",
            headers: {
                "Content-Type": "application/x-www-form-urlencoded",
                Authorization: clientAuthHeader(),
            },
            body: new URLSearchParams({ token, token_type_hint: hint }).toString(),
            signal: AbortSignal.timeout(DISCORD_HTTP_TIMEOUT_MS),
        });
    }
    catch (err) {
        console.error(`[Discord] Token revoke failed: ${(err as Error).message}`);
    }
}
