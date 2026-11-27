import type { IncomingMessage, ServerResponse } from "http";
import { readBody } from "../../../body.js";
import { DEFAULT_DISCORD_USER_KEY, discordOAuthConfigured } from "../../../../discord/config.js";
import { clearUserPresence } from "../../../../discord/discordPresence.js";
import { bearerToken, parseForm, sendHtml, sendJson, serverTokenMatches, wantsJson } from "../../../../discord/http.js";
import { revokeToken } from "../../../../discord/oauth.js";
import { deleteLink, getLink } from "../../../../discord/token-store.js";

// POST /auth/discord/unlink
// Auth (when MCP_AUTH_TOKEN is set): `Authorization: Bearer <MCP_AUTH_TOKEN>` or form/JSON field `server_token`.
// Clears the live presence, revokes the tokens at Discord, and deletes them from storage.

export async function POST(req: IncomingMessage, res: ServerResponse): Promise<void> {
    const json = wantsJson(req) || Boolean(req.headers.authorization);
    const form = parseForm(await readBody(req), req.headers["content-type"]);
    if (!serverTokenMatches(bearerToken(req) ?? form.server_token)) {
        if (json)
            sendJson(res, 401, { error: "unauthorized" });
        else
            sendHtml(res, 401, "Unauthorized", `<p>That server token is incorrect. <a href="/auth/discord">Go back</a>.</p>`);
        return;
    }
    const userKey = DEFAULT_DISCORD_USER_KEY;
    const link = await getLink(userKey);
    await clearUserPresence(userKey);
    if (link && discordOAuthConfigured()) {
        // Revoking either token invalidates the grant; do both best-effort, in the background.
        void revokeToken(link.accessToken, "access_token");
        if (link.refreshToken)
            void revokeToken(link.refreshToken, "refresh_token");
    }
    await deleteLink(userKey);
    console.error(`[Discord] Unlinked Discord for "${userKey}".`);
    if (json)
        sendJson(res, 200, { ok: true, wasLinked: Boolean(link) });
    else
        sendHtml(res, 200, "Discord unlinked", `<p>${link ? "Your Discord account was unlinked and its tokens were revoked." : "No Discord account was linked."} <a href="/auth/discord">Link again</a>.</p>`);
}
