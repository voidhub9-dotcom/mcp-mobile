import type { IncomingMessage, ServerResponse } from "http";
import { discordOAuthConfigured } from "../../../../discord/config.js";
import { escapeHtml, sendHtml } from "../../../../discord/http.js";
import { consumeState, exchangeCode } from "../../../../discord/oauth.js";

// GET /auth/discord/callback?code=...&state=...
// Exchanges the code, then stores the encrypted tokens for the user the state was issued to.

export async function GET(_req: IncomingMessage, res: ServerResponse, url: URL): Promise<void> {
    if (!discordOAuthConfigured()) {
        sendHtml(res, 503, "Discord linking is not configured", "<p>Discord OAuth environment variables are missing on the server.</p>");
        return;
    }
    const error = url.searchParams.get("error");
    const userKey = consumeState(url.searchParams.get("state"));
    if (error) {
        sendHtml(res, 400, "Discord linking cancelled", `<p>Discord returned: <code>${escapeHtml(error)}</code>. <a href="/auth/discord">Try again</a>.</p>`);
        return;
    }
    if (!userKey) {
        sendHtml(res, 400, "Link expired", `<p>The login request was invalid or expired (CSRF state mismatch). <a href="/auth/discord">Start again</a>.</p>`);
        return;
    }
    const code = url.searchParams.get("code");
    if (!code) {
        sendHtml(res, 400, "Missing code", `<p>Discord did not return an authorization code. <a href="/auth/discord">Start again</a>.</p>`);
        return;
    }
    try {
        const link = await exchangeCode(userKey, code);
        console.error(`[Discord] Linked Discord user ${link.discordUserId ?? "(unknown id)"} for "${userKey}".`);
        sendHtml(res, 200, "Discord linked", `<p>Your Discord account${link.discordUserId ? ` (<code>${escapeHtml(link.discordUserId)}</code>)` : ""} is linked. Your Rich Presence will show <strong>Void Hub RPC</strong> while MCP tools are running, and clears itself after a few idle minutes.</p><p>You can close this tab.</p>`);
    }
    catch (err) {
        console.error("[Discord] Code exchange failed:", (err as Error).message);
        sendHtml(res, 502, "Discord linking failed", `<p>Could not exchange the authorization code with Discord. Check that <code>DISCORD_REDIRECT_URI</code> exactly matches the redirect configured in the Developer Portal. <a href="/auth/discord">Try again</a>.</p>`);
    }
}
