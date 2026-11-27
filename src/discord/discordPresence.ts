import { DISCORD_API_BASE, DISCORD_BUTTON_URL, DISCORD_CLIENT_ID, DISCORD_SHOW_GAME_BUTTON, PRESENCE_GAME_BUTTON_LABEL, DISCORD_SHOW_GAME_ICON, DISCORD_HTTP_TIMEOUT_MS, DISCORD_LARGE_IMAGE_KEY, DISCORD_PRESENCE_PLATFORM, PRESENCE_BUTTON_LABEL, type PresencePlatform, PRESENCE_IDLE_TIMEOUT_MS, PRESENCE_KEEPALIVE_MS, PRESENCE_LARGE_TEXT, PRESENCE_NAME, PRESENCE_STATE, PRESENCE_THROTTLE_MS, discordOAuthConfigured, } from "./config.js";
import { getGameIconUrl } from "./game-icon.js";
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
    platform: PresencePlatform;
    application_id?: string;
    details: string;
    state: string;
    timestamps: { start: number };
    assets: { large_image: string; large_text: string; small_image?: string; small_text?: string };
    buttons?: { label: string; url: string }[];
}

/** The Roblox game the active client is in, if any. */
export interface PresenceGame {
    placeId: number;
    placeName: string;
}

interface UserPresenceState {
    sessionStart: number;
    lastActivityAt: number;
    lastPushAt: number;
    details: string;
    game: PresenceGame | null;
    /** details + placeId of the last successful push, to detect changes. */
    pushedKey: string | null;
    timer: NodeJS.Timeout | null;
    inflight: boolean;
    lastErrorLogAt: number;
}

const states = new Map<string, UserPresenceState>();
let heartbeat: NodeJS.Timeout | null = null;
// Flipped off for the rest of the process if Discord rejects the button payload.
let buttonsAccepted = true;
// Flipped off if Discord rejects external (Roblox CDN) image URLs.
let gameIconsAccepted = true;

function stateKey(details: string, game: PresenceGame | null): string {
    return `${details}|${game?.placeId ?? ""}`;
}

export function presenceEnabled(): boolean {
    return discordOAuthConfigured() && tokenStorageAvailable();
}

export interface BuildActivityOptions {
    includeButtons?: boolean;
    game?: PresenceGame | null;
    /** https URL of the game's icon; when set it becomes the big image. */
    gameIconUrl?: string | null;
}

/** Title shown in bold: the Roblox game's name when in a game, else "VoidHub RPC". */
export function presenceTitle(game: PresenceGame | null | undefined): string {
    return game?.placeName?.trim() ? truncate(game.placeName, 128) : PRESENCE_NAME;
}

/** Up to two buttons (Discord's limit): "See Game Page" for the current game, then "Get VoidHub". */
export function presenceButtons(game: PresenceGame | null | undefined): { label: string; url: string }[] {
    const buttons: { label: string; url: string }[] = [];
    if (DISCORD_SHOW_GAME_BUTTON && game && game.placeId > 0)
        buttons.push({ label: PRESENCE_GAME_BUTTON_LABEL, url: `https://www.roblox.com/games/${game.placeId}` });
    if (DISCORD_BUTTON_URL)
        buttons.push({ label: PRESENCE_BUTTON_LABEL, url: DISCORD_BUTTON_URL });
    return buttons.slice(0, 2);
}

export function buildActivity(details: string, startMs: number, options: BuildActivityOptions = {}): PresenceActivity {
    const includeButtons = options.includeButtons ?? buttonsAccepted;
    const activity: PresenceActivity = {
        name: presenceTitle(options.game),
        type: 0, // Playing
        platform: DISCORD_PRESENCE_PLATFORM,
        ...(DISCORD_CLIENT_ID ? { application_id: DISCORD_CLIENT_ID } : {}),
        details: truncate(details, 128),
        state: PRESENCE_STATE,
        timestamps: { start: startMs },
        assets: { large_image: DISCORD_LARGE_IMAGE_KEY, large_text: PRESENCE_LARGE_TEXT },
    };
    if (options.gameIconUrl) {
        activity.assets = {
            large_image: options.gameIconUrl,
            large_text: truncate(options.game?.placeName || "Roblox", 128),
            small_image: DISCORD_LARGE_IMAGE_KEY,
            small_text: PRESENCE_LARGE_TEXT,
        };
    }
    const buttons = includeButtons ? presenceButtons(options.game) : [];
    if (buttons.length)
        activity.buttons = buttons;
    return activity;
}

function truncate(text: string, max: number): string {
    const clean = text.trim() || "Using VoidHub";
    return clean.length > max ? clean.slice(0, max - 1) + "…" : clean;
}

/**
 * Record that `userKey` is doing `action` and (throttled) push it to Discord.
 * Synchronous, never throws, never awaits the network.
 */
export function updateUserPresence(userKey: string, action: string, game: PresenceGame | null = null): void {
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
                game,
                pushedKey: null,
                timer: null,
                inflight: false,
                lastErrorLogAt: 0,
            };
            states.set(userKey, st);
        }
        st.lastActivityAt = now;
        st.details = action;
        st.game = game;
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
    if (!force && stateKey(st.details, st.game) === st.pushedKey && now - st.lastPushAt < PRESENCE_KEEPALIVE_MS)
        return;
    // Clamp so a clock jump can never stall updates for longer than one throttle window.
    const wait = Math.min(PRESENCE_THROTTLE_MS, Math.max(0, st.lastPushAt + PRESENCE_THROTTLE_MS - now));
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
    const game = st.game;
    try {
        await pushPresence(userKey, details, st.sessionStart, game);
        st.pushedKey = stateKey(details, game);
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
    if (states.get(userKey) === st && stateKey(st.details, st.game) !== st.pushedKey)
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

async function pushPresence(userKey: string, details: string, sessionStart: number, game: PresenceGame | null): Promise<void> {
    let link = await getValidLink(userKey);
    if (!link)
        return; // not linked (or token dead): silently skip
    const wantIcon = DISCORD_SHOW_GAME_ICON && gameIconsAccepted && game !== null;
    let gameIconUrl = wantIcon ? await getGameIconUrl(game.placeId) : null;
    let useToken = true;
    let refreshed = false;
    for (let attempt = 0; attempt < 5; attempt++) {
        const body: { activities: PresenceActivity[]; token?: string } = {
            activities: [buildActivity(details, sessionStart, { game, gameIconUrl })],
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
        if (resp.status === 400 && gameIconUrl && /image|asset|url/i.test(text)) {
            gameIconsAccepted = false;
            gameIconUrl = null;
            console.error("[Discord] Discord rejected the game icon URL; using the VoidHub logo instead.");
            continue;
        }
        if (resp.status === 400 && buttonsAccepted && /button/i.test(text)) {
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

/**
 * Manual test (the "Send test presence" button): pushes immediately, bypassing
 * the throttle, and reports Discord's answer instead of only logging it.
 * The session then idles out like a normal one.
 */
export async function sendTestPresence(userKey: string, details: string, game: PresenceGame | null): Promise<{ ok: boolean; error?: string }> {
    const now = Date.now();
    let st = states.get(userKey);
    if (!st) {
        st = { sessionStart: now, lastActivityAt: now, lastPushAt: 0, details, game, pushedKey: null, timer: null, inflight: false, lastErrorLogAt: 0 };
        states.set(userKey, st);
    }
    if (st.timer) {
        clearTimeout(st.timer);
        st.timer = null;
    }
    st.lastActivityAt = now;
    st.details = details;
    st.game = game;
    ensureHeartbeat();
    st.inflight = true;
    try {
        if (!(await getValidLink(userKey)))
            return { ok: false, error: "No usable Discord token (not linked, or the refresh failed). Link again." };
        await pushPresence(userKey, details, st.sessionStart, game);
        st.pushedKey = stateKey(details, game);
        return { ok: true };
    }
    catch (err) {
        return { ok: false, error: (err as Error).message };
    }
    finally {
        st.inflight = false;
        st.lastPushAt = Date.now();
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

export function getPresenceStatus(userKey: string): { active: boolean; pushInFlight: boolean; pushScheduled: boolean; details: string | null; game: PresenceGame | null; sessionStart: number | null; lastActivityAt: number | null } {
    const st = states.get(userKey);
    return {
        active: Boolean(st),
        pushInFlight: Boolean(st?.inflight),
        pushScheduled: Boolean(st?.timer),
        details: st?.details ?? null,
        game: st?.game ?? null,
        sessionStart: st?.sessionStart ?? null,
        lastActivityAt: st?.lastActivityAt ?? null,
    };
}
