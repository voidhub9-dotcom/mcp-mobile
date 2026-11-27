import { DISCORD_API_BASE, DISCORD_BUTTON_URL, DISCORD_CLIENT_ID, DISCORD_HTTP_TIMEOUT_MS, DISCORD_LARGE_IMAGE_KEY, PRESENCE_BUTTON_LABEL, PRESENCE_IDLE_TIMEOUT_MS, PRESENCE_KEEPALIVE_MS, PRESENCE_LARGE_TEXT, PRESENCE_NAME, PRESENCE_STATE, PRESENCE_THROTTLE_MS, discordOAuthConfigured, } from "./config.js";
import { getValidLink, refreshLink } from "./oauth.js";
import { getLink, saveLink, tokenStorageAvailable, type DiscordLink } from "./token-store.js";

// Cloud Rich Presence ("VoidHub RPC") via Discord headless sessions.
//
// The server holds the user's `sdk.social_layer_presence` bearer token and
// sets their activity over HTTP, so no Discord client or local RPC is needed.
//
//   POST /users/@me/headless-sessions          { activities: [...], token? } -> { token, activities }
//   POST /users/@me/headless-sessions/delete   { token }
//
// Every public function here is fire-and-forget: it never throws and never
// makes the caller wait on Discord.

const HEADLESS_SESSION_PATH = "/users/@me/headless-sessions";
const HEADLESS_SESSION_DELETE_PATH = "/users/@me/headless-sessions/delete";
const HEARTBEAT_INTERVAL_MS = 30_000;

export interface PresenceActivity {
    name: string;
    type: 0;
    application_id?: string;
    details: string;
    state: string;
    timestamps: { start: number };
    assets: { large_image: string; large_text: string };
    buttons?: { label: string; url: string }[];
}

interface UserPresenceState {
    sessionStart: number;
    lastActivityAt: number;
    lastPushAt: number;
    details: string;
    pushedDetails: string | null;
    timer: NodeJS.Timeout | null;
    inflight: boolean;
    lastErrorLogAt: number;
}

const states = new Map<string, UserPresenceState>();
let heartbeat: NodeJS.Timeout | null = null;
// Flipped off for the rest of the process if Discord rejects the button payload.
let buttonsAccepted = true;

export function presenceEnabled(): boolean {
    return discordOAuthConfigured() && tokenStorageAvailable();
}

export function buildActivity(details: string, startMs: number, includeButtons = buttonsAccepted): PresenceActivity {
    const activity: PresenceActivity = {
        name: PRESENCE_NAME,
        type: 0, // Playing
        ...(DISCORD_CLIENT_ID ? { application_id: DISCORD_CLIENT_ID } : {}),
        details: truncate(details, 128),
        state: PRESENCE_STATE,
        timestamps: { start: startMs },
        assets: { large_image: DISCORD_LARGE_IMAGE_KEY, large_text: PRESENCE_LARGE_TEXT },
    };
    if (includeButtons && DISCORD_BUTTON_URL)
        activity.buttons = [{ label: PRESENCE_BUTTON_LABEL, url: DISCORD_BUTTON_URL }];
    return activity;
}

function truncate(text: string, max: number): string {
    const clean = text.trim() || "Using Void Hub";
    return clean.length > max ? clean.slice(0, max - 1) + "…" : clean;
}

/**
 * Record that `userKey` is doing `action` and (throttled) push it to Discord.
 * Synchronous, never throws, never awaits the network.
 */
export function updateUserPresence(userKey: string, action: string): void {
    try {
        if (!presenceEnabled())
            return;
        const now = Date.now();
        let st = states.get(userKey);
        if (!st) {
            st = {
                sessionStart: now,
                lastActivityAt: now,
                lastPushAt: 0,
                details: action,
                pushedDetails: null,
                timer: null,
                inflight: false,
                lastErrorLogAt: 0,
            };
            states.set(userKey, st);
        }
        st.lastActivityAt = now;
        st.details = action;
        ensureHeartbeat();
        schedulePush(userKey, st, false);
    }
    catch (err) {
        console.error("[Discord] updateUserPresence failed:", (err as Error).message);
    }
}

function schedulePush(userKey: string, st: UserPresenceState, force: boolean): void {
    if (st.timer || st.inflight)
        return; // the pending push will pick up the latest details
    const now = Date.now();
    if (!force && st.details === st.pushedDetails && now - st.lastPushAt < PRESENCE_KEEPALIVE_MS)
        return;
    const wait = Math.max(0, st.lastPushAt + PRESENCE_THROTTLE_MS - now);
    st.timer = setTimeout(() => {
        st.timer = null;
        void runPush(userKey, st);
    }, wait);
    st.timer.unref?.();
}

async function runPush(userKey: string, st: UserPresenceState): Promise<void> {
    if (states.get(userKey) !== st)
        return; // session ended meanwhile
    st.inflight = true;
    const details = st.details;
    try {
        await pushPresence(userKey, details, st.sessionStart);
        st.pushedDetails = details;
    }
    catch (err) {
        const now = Date.now();
        if (now - st.lastErrorLogAt > 60_000) {
            st.lastErrorLogAt = now;
            console.error(`[Discord] Presence update failed for "${userKey}": ${(err as Error).message}`);
        }
    }
    finally {
        st.inflight = false;
        st.lastPushAt = Date.now(); // also on failure, so errors back off at the throttle rate
    }
    if (states.get(userKey) === st && st.details !== st.pushedDetails)
        schedulePush(userKey, st, false);
}

async function discordPost(path: string, accessToken: string, body: unknown): Promise<Response> {
    return fetch(`${DISCORD_API_BASE}${path}`, {
        method: "POST",
        headers: { "Content-Type": "application/json", Authorization: `Bearer ${accessToken}` },
        body: JSON.stringify(body),
        signal: AbortSignal.timeout(DISCORD_HTTP_TIMEOUT_MS),
    });
}

async function pushPresence(userKey: string, details: string, sessionStart: number): Promise<void> {
    let link = await getValidLink(userKey);
    if (!link)
        return; // not linked (or token dead): silently skip
    let useToken = true;
    let refreshed = false;
    for (let attempt = 0; attempt < 4; attempt++) {
        const body: { activities: PresenceActivity[]; token?: string } = {
            activities: [buildActivity(details, sessionStart)],
        };
        if (useToken && link.sessionToken)
            body.token = link.sessionToken;
        const resp = await discordPost(HEADLESS_SESSION_PATH, link.accessToken, body);
        if (resp.ok) {
            const data = (await resp.json().catch(() => ({}))) as { token?: string };
            if (data.token && data.token !== link.sessionToken)
                await saveIfStillLinked(userKey, link, { ...link, sessionToken: data.token });
            return;
        }
        const text = await resp.text().catch(() => "");
        if (resp.status === 401 && !refreshed) {
            refreshed = true;
            const next = await refreshLink(userKey, link);
            if (!next)
                throw new Error("Discord rejected the token and refresh failed; re-link at /auth/discord.");
            link = next;
            continue;
        }
        if ((resp.status === 400 || resp.status === 404) && useToken && link.sessionToken) {
            // Stale/expired session token: start a fresh session.
            useToken = false;
            continue;
        }
        if (resp.status === 400 && buttonsAccepted && DISCORD_BUTTON_URL && /button/i.test(text)) {
            buttonsAccepted = false;
            console.error("[Discord] Discord rejected the presence button; continuing without it.");
            continue;
        }
        if (resp.status === 429) {
            throw new Error(`rate limited by Discord (retry after ${resp.headers.get("retry-after") ?? "?"}s)`);
        }
        throw new Error(`Discord returned ${resp.status}: ${text.slice(0, 300)}`);
    }
}

/** Persist only if the user hasn't unlinked/relinked while a request was in flight. */
async function saveIfStillLinked(userKey: string, expected: DiscordLink, next: DiscordLink): Promise<void> {
    const current = await getLink(userKey);
    if (current && current.refreshToken === expected.refreshToken && current.linkedAt === expected.linkedAt)
        await saveLink(userKey, next);
}

async function deleteHeadlessSession(userKey: string, link: DiscordLink | null): Promise<void> {
    if (!link?.sessionToken)
        return;
    try {
        const resp = await discordPost(HEADLESS_SESSION_DELETE_PATH, link.accessToken, { token: link.sessionToken });
        if (!resp.ok && resp.status !== 404)
            console.error(`[Discord] Ending headless session for "${userKey}" returned ${resp.status}.`);
    }
    catch (err) {
        console.error(`[Discord] Ending headless session for "${userKey}" failed: ${(err as Error).message}`);
    }
}

/** End the user's presence session now (idle timeout, unlink). Never throws. */
export async function clearUserPresence(userKey: string): Promise<void> {
    const st = states.get(userKey);
    if (st?.timer)
        clearTimeout(st.timer);
    states.delete(userKey);
    try {
        const link = (await getValidLink(userKey)) ?? (await getLink(userKey));
        await deleteHeadlessSession(userKey, link);
        if (link?.sessionToken)
            await saveIfStillLinked(userKey, link, { ...link, sessionToken: null });
    }
    catch (err) {
        console.error(`[Discord] clearUserPresence failed for "${userKey}": ${(err as Error).message}`);
    }
}

function ensureHeartbeat(): void {
    if (heartbeat)
        return;
    heartbeat = setInterval(() => {
        const now = Date.now();
        for (const [userKey, st] of states) {
            if (now - st.lastActivityAt > PRESENCE_IDLE_TIMEOUT_MS) {
                console.error(`[Discord] "${userKey}" idle for ${Math.round(PRESENCE_IDLE_TIMEOUT_MS / 60_000)} min; clearing presence.`);
                void clearUserPresence(userKey);
            }
            else if (now - st.lastPushAt >= PRESENCE_KEEPALIVE_MS) {
                schedulePush(userKey, st, true);
            }
        }
        if (states.size === 0 && heartbeat) {
            clearInterval(heartbeat);
            heartbeat = null;
        }
    }, HEARTBEAT_INTERVAL_MS);
    heartbeat.unref?.();
}

export function getPresenceStatus(userKey: string): { active: boolean; pushInFlight: boolean; pushScheduled: boolean; details: string | null; sessionStart: number | null; lastActivityAt: number | null } {
    const st = states.get(userKey);
    return {
        active: Boolean(st),
        pushInFlight: Boolean(st?.inflight),
        pushScheduled: Boolean(st?.timer),
        details: st?.details ?? null,
        sessionStart: st?.sessionStart ?? null,
        lastActivityAt: st?.lastActivityAt ?? null,
    };
}
