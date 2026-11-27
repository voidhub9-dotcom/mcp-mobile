import os from "node:os";
import path from "node:path";

// Discord Social SDK / "VoidHub RPC" configuration. Everything is optional:
// when DISCORD_CLIENT_ID / DISCORD_CLIENT_SECRET are missing the feature is
// simply disabled and the MCP server behaves exactly as before.

function envInt(name: string, fallback: number, min: number, max: number): number {
    const parsed = parseInt(process.env[name] || "", 10);
    if (!Number.isFinite(parsed))
        return fallback;
    return Math.min(Math.max(parsed, min), max);
}

export const DISCORD_API_BASE = "https://discord.com/api/v10";
export const DISCORD_AUTHORIZE_URL = "https://discord.com/oauth2/authorize";
export const DISCORD_SCOPES = ["openid", "sdk.social_layer_presence"] as const;

export const DISCORD_CLIENT_ID: string | null = process.env.DISCORD_CLIENT_ID?.trim() || null;
export const DISCORD_CLIENT_SECRET: string | null = process.env.DISCORD_CLIENT_SECRET?.trim() || null;
export const DISCORD_REDIRECT_URI: string | null = process.env.DISCORD_REDIRECT_URI?.trim() || null;
export const DISCORD_LARGE_IMAGE_KEY: string = process.env.DISCORD_LARGE_IMAGE_KEY?.trim() || "void_logo";
export const DISCORD_BUTTON_URL: string | null = process.env.DISCORD_BUTTON_URL?.trim() || null;
export const TOKEN_ENCRYPTION_KEY: string | null = process.env.TOKEN_ENCRYPTION_KEY?.trim() || null;

/** Where encrypted tokens live. Point this at a Railway volume so links survive redeploys. */
export const DISCORD_TOKEN_STORE_PATH: string = process.env.DISCORD_TOKEN_STORE_PATH?.trim() ||
    path.join(os.homedir(), ".roblox-mcp", "discord-links.json");

/** Show the current Roblox game's icon as the big image (Void Hub logo becomes the small badge). */
export const DISCORD_SHOW_GAME_ICON: boolean = !/^(0|false|no|off)$/i.test(process.env.DISCORD_SHOW_GAME_ICON?.trim() || "");

/** Activity platform Discord requires on headless-session activities. */
export const PRESENCE_PLATFORMS = ["desktop", "android", "ios", "xbox", "samsung", "ps4", "ps5", "embedded"] as const;
export type PresencePlatform = (typeof PRESENCE_PLATFORMS)[number];
export const DISCORD_PRESENCE_PLATFORM: PresencePlatform = (() => {
    const raw = (process.env.DISCORD_PRESENCE_PLATFORM || "").trim().toLowerCase();
    return (PRESENCE_PLATFORMS as readonly string[]).includes(raw) ? (raw as PresencePlatform) : "desktop";
})();

/** Minimum gap between two presence pushes for the same user. */
export const PRESENCE_THROTTLE_MS = envInt("DISCORD_PRESENCE_THROTTLE_MS", 15_000, 15_000, 300_000);
/** End the headless session after this long without MCP tool calls. */
export const PRESENCE_IDLE_TIMEOUT_MS = envInt("DISCORD_PRESENCE_IDLE_MS", 5 * 60_000, 60_000, 60 * 60_000);
/** Re-send the current activity this often while active, so the session never lapses. */
export const PRESENCE_KEEPALIVE_MS = envInt("DISCORD_PRESENCE_KEEPALIVE_MS", 2 * 60_000, 30_000, 10 * 60_000);
/** Hard cap on any single Discord HTTP call. */
export const DISCORD_HTTP_TIMEOUT_MS = 8_000;

export const PRESENCE_NAME = "Void Hub RPC";
export const PRESENCE_STATE = "Connected via Void Hub MCP";
export const PRESENCE_LARGE_TEXT = "Void Hub MCP";
export const PRESENCE_BUTTON_LABEL = "Get Void Hub";

/** Single-user deployments (one shared MCP_AUTH_TOKEN) store their link under this id. */
export const DEFAULT_DISCORD_USER_KEY = "default";

export function discordOAuthConfigured(): boolean {
    return Boolean(DISCORD_CLIENT_ID && DISCORD_CLIENT_SECRET && DISCORD_REDIRECT_URI);
}
