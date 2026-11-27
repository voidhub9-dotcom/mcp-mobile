import type { IncomingMessage, ServerResponse } from "http";
import { DEFAULT_DISCORD_USER_KEY, discordOAuthConfigured } from "../../../../discord/config.js";
import { getPresenceStatus, presenceEnabled } from "../../../../discord/discordPresence.js";
import { bearerToken, sendJson, serverTokenMatches } from "../../../../discord/http.js";
import { getLink, tokenStorageAvailable } from "../../../../discord/token-store.js";

// GET /auth/discord/status  (Authorization: Bearer <MCP_AUTH_TOKEN> when set)

export async function GET(req: IncomingMessage, res: ServerResponse): Promise<void> {
    if (!serverTokenMatches(bearerToken(req))) {
        sendJson(res, 401, { error: "unauthorized" });
        return;
    }
    const link = await getLink(DEFAULT_DISCORD_USER_KEY);
    sendJson(res, 200, {
        configured: discordOAuthConfigured(),
        tokenStorage: tokenStorageAvailable(),
        enabled: presenceEnabled(),
        linked: Boolean(link),
        discordUserId: link?.discordUserId ?? null,
        tokenExpiresAt: link ? new Date(link.expiresAt).toISOString() : null,
        presence: getPresenceStatus(DEFAULT_DISCORD_USER_KEY),
    });
}
