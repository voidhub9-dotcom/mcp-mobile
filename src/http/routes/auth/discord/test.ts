import type { IncomingMessage, ServerResponse } from "http";
import { readBody } from "../../../body.js";
import { DEFAULT_DISCORD_USER_KEY } from "../../../../discord/config.js";
import { presenceEnabled, sendTestPresence } from "../../../../discord/discordPresence.js";
import { bearerToken, escapeHtml, parseForm, sendHtml, sendJson, serverTokenMatches, wantsJson } from "../../../../discord/http.js";
import { getLink } from "../../../../discord/token-store.js";
import { currentGame } from "../../../../discord/tool-hook.js";

// POST /auth/discord/test
// Sends a "Testing Void Hub RPC" presence right away (no throttle) and shows Discord's answer.
// Auth (when MCP_AUTH_TOKEN is set): Bearer header or `server_token` form/JSON field.

export async function POST(req: IncomingMessage, res: ServerResponse): Promise<void> {
    const json = wantsJson(req) || Boolean(req.headers.authorization);
    const form = parseForm(await readBody(req), req.headers["content-type"]);
    const fail = (status: number, message: string) => json
        ? sendJson(res, status, { error: message })
        : sendHtml(res, status, "Test failed", `<p>${message} <a href="/auth/discord">Go back</a>.</p>`);
    if (!serverTokenMatches(bearerToken(req) ?? form.server_token))
        return fail(401, "That server token is incorrect.");
    if (!presenceEnabled())
        return fail(503, "Discord isn't configured on the server (check the DISCORD_* and TOKEN_ENCRYPTION_KEY variables).");
    if (!(await getLink(DEFAULT_DISCORD_USER_KEY)))
        return fail(409, "No Discord account is linked yet. Link it first.");
    const game = currentGame();
    const result = await sendTestPresence(DEFAULT_DISCORD_USER_KEY, "Testing Void Hub RPC", game);
    if (!result.ok) {
        console.error(`[Discord] Test presence failed: ${result.error}`);
        if (json)
            return sendJson(res, 502, { ok: false, error: result.error, game });
        return sendHtml(res, 502, "Discord said no", `<p>Discord rejected the test presence:</p><pre style="white-space:pre-wrap;background:#f3f3f3;padding:0.75rem">${escapeHtml(result.error ?? "unknown error")}</pre><p>Send this error to whoever set up the server. <a href="/auth/discord">Back</a></p>`);
    }
    if (json) {
        sendJson(res, 200, { ok: true, game });
        return;
    }
    sendHtml(res, 200, "Test sent", `<p>Sent <strong>Testing Void Hub RPC</strong> to Discord${game ? ` with the icon for <strong>${escapeHtml(game.placeName)}</strong>` : " (no Roblox game connected, so the Void Hub logo is used)"}.</p>
<p>Discord accepted it. Check your Discord profile now. It clears itself after 5 minutes with no activity. If nothing shows up, check the Railway logs for lines starting with <code>[Discord]</code>.</p>
<p><a href="/auth/discord">Back</a></p>`);
}
