import type { IncomingMessage, ServerResponse } from "http";
import { readBody } from "../../../body.js";
import { DEFAULT_DISCORD_USER_KEY } from "../../../../discord/config.js";
import { presenceEnabled, sendTestPresence } from "../../../../discord/discordPresence.js";
import { authorize, escapeHtml, parseForm, redirect, sendJson, sendMessage, wantsJson } from "../../../../discord/http.js";
import { getLink } from "../../../../discord/token-store.js";
import { currentGame } from "../../../../discord/tool-hook.js";

// POST /auth/discord/test
// Sends a "Testing Void Hub RPC" presence right away (no throttle) and shows Discord's answer.
// Auth (when MCP_AUTH_TOKEN is set): Bearer header, `server_token` field, or the remembered-device cookie.

export async function POST(req: IncomingMessage, res: ServerResponse): Promise<void> {
    const json = wantsJson(req) || Boolean(req.headers.authorization);
    const form = parseForm(await readBody(req), req.headers["content-type"]);
    const fail = (status: number, title: string, html: string) => json
        ? sendJson(res, status, { ok: false, error: title })
        : sendMessage(res, status, "error", title, html);
    if (!authorize(req, res, form.server_token))
        return fail(401, "Not signed in", "Open the Void Hub RPC page and sign in with your <code>MCP_AUTH_TOKEN</code> first.");
    if (!presenceEnabled())
        return fail(503, "Discord isn't set up on the server", "Check the <code>DISCORD_*</code> and <code>TOKEN_ENCRYPTION_KEY</code> variables.");
    if (!(await getLink(DEFAULT_DISCORD_USER_KEY)))
        return fail(409, "No Discord account linked yet", "Tap <b>Link Discord</b> first.");
    const game = currentGame();
    const result = await sendTestPresence(DEFAULT_DISCORD_USER_KEY, "Testing Void Hub RPC", game);
    if (!result.ok) {
        console.error(`[Discord] Test presence failed: ${result.error}`);
        if (json)
            return sendJson(res, 502, { ok: false, error: result.error, game });
        return sendMessage(res, 502, "error", "Discord said no", "Discord rejected the test presence. Send the error below to whoever runs the server.", "Back to Void Hub RPC", {
            detail: `<div class="caps">Error from Discord</div><pre>${escapeHtml(result.error ?? "unknown error")}</pre>`,
        });
    }
    if (json)
        return sendJson(res, 200, { ok: true, game });
    redirect(res, "/auth/discord?tested=1");
}
