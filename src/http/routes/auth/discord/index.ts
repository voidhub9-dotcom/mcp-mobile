import type { IncomingMessage, ServerResponse } from "http";
import { readBody } from "../../../body.js";
import { DEFAULT_DISCORD_USER_KEY, discordOAuthConfigured } from "../../../../discord/config.js";
import { authRequired, parseForm, sendHtml, serverTokenMatches } from "../../../../discord/http.js";
import { createAuthorizeUrl } from "../../../../discord/oauth.js";
import { tokenStorageAvailable } from "../../../../discord/token-store.js";

// GET  /auth/discord  -> redirect to Discord (or show the server-token form when MCP_AUTH_TOKEN is set)
// POST /auth/discord  -> verify server token, then redirect to Discord

function notConfigured(res: ServerResponse): boolean {
    if (discordOAuthConfigured() && tokenStorageAvailable())
        return false;
    sendHtml(res, 503, "Discord linking is not configured", "<p>Set <code>DISCORD_CLIENT_ID</code>, <code>DISCORD_CLIENT_SECRET</code>, <code>DISCORD_REDIRECT_URI</code> and <code>TOKEN_ENCRYPTION_KEY</code> on the server, then redeploy.</p>");
    return true;
}

function redirectToDiscord(res: ServerResponse): void {
    const { url } = createAuthorizeUrl(DEFAULT_DISCORD_USER_KEY);
    res.writeHead(302, { Location: url, "Cache-Control": "no-store" });
    res.end();
}

function tokenForm(res: ServerResponse, status = 200, error?: string): void {
    sendHtml(res, status, "Void Hub RPC", `${error ? `<p style="color:#b00020">${error}</p>` : ""}
<p>Link your Discord account so Void Hub MCP can show what you're doing as Rich Presence. Enter this server's <code>MCP_AUTH_TOKEN</code> to continue.</p>
<form method="post" action="/auth/discord">
  <input name="server_token" type="password" autocomplete="current-password" required autofocus placeholder="MCP_AUTH_TOKEN" style="width:100%;max-width:28rem;padding:0.6rem;margin-bottom:0.75rem"><br>
  <button type="submit" style="padding:0.6rem 1rem">Link Discord</button>
  <button type="submit" formaction="/auth/discord/unlink" style="padding:0.6rem 1rem;margin-left:0.5rem">Unlink Discord</button>
</form>`);
}

export async function GET(_req: IncomingMessage, res: ServerResponse): Promise<void> {
    if (notConfigured(res))
        return;
    if (authRequired()) {
        tokenForm(res);
        return;
    }
    redirectToDiscord(res);
}

export async function POST(req: IncomingMessage, res: ServerResponse): Promise<void> {
    if (notConfigured(res))
        return;
    const form = parseForm(await readBody(req), req.headers["content-type"]);
    if (!serverTokenMatches(form.server_token)) {
        tokenForm(res, 401, "That server token is incorrect.");
        return;
    }
    redirectToDiscord(res);
}
