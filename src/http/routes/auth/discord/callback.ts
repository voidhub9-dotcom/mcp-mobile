import type { IncomingMessage, ServerResponse } from "http";
import { discordOAuthConfigured } from "../../../../discord/config.js";
import { escapeHtml, redirect, sendMessage } from "../../../../discord/http.js";
import { consumeState, exchangeCode } from "../../../../discord/oauth.js";

// GET /auth/discord/callback?code=...&state=...
// Exchanges the code, stores the encrypted tokens, then returns to the Void Hub RPC page.

const ERROR_HELP: Record<string, string> = {
    access_denied: "You cancelled on Discord's screen. Nothing was linked.",
    invalid_scope: "This Discord app isn't allowed to use Rich Presence yet. In the Developer Portal, open the app, then <b>Discord Social SDK → Getting Started</b>, submit the form, wait a minute, and try again.",
    invalid_request: "Discord didn't accept the request. Check that the redirect in the Developer Portal is exactly the server's <code>DISCORD_REDIRECT_URI</code>.",
    unauthorized_client: "This Discord app can't use this login flow. Check <code>DISCORD_CLIENT_ID</code> is this app's Application ID.",
};

export async function GET(_req: IncomingMessage, res: ServerResponse, url: URL): Promise<void> {
    if (!discordOAuthConfigured()) {
        sendMessage(res, 503, "error", "Discord isn't set up on the server", "<p>The <code>DISCORD_*</code> variables are missing.</p>");
        return;
    }
    const error = url.searchParams.get("error");
    const userKey = consumeState(url.searchParams.get("state"));
    if (error) {
        const help = ERROR_HELP[error] ?? "Discord stopped the login.";
        sendMessage(res, 400, "error", "Discord linking didn't finish", `<p>${help}</p><p class="hint">Discord said: <code>${escapeHtml(error)}</code></p>`, "Try again");
        return;
    }
    if (!userKey) {
        sendMessage(res, 400, "error", "That link expired", "<p>The login took longer than 10 minutes, or the server restarted in the middle. Just start again.</p>", "Start again");
        return;
    }
    const code = url.searchParams.get("code");
    if (!code) {
        sendMessage(res, 400, "error", "Discord didn't send a code", "<p>Start the link again.</p>", "Start again");
        return;
    }
    try {
        const link = await exchangeCode(userKey, code);
        console.error(`[Discord] Linked Discord user ${link.discordUserId ?? "(unknown id)"} for "${userKey}".`);
        redirect(res, "/auth/discord?linked=1");
    }
    catch (err) {
        console.error("[Discord] Code exchange failed:", (err as Error).message);
        sendMessage(res, 502, "error", "Discord linking failed", `<p>The server couldn't swap the login code with Discord. Usually <code>DISCORD_CLIENT_SECRET</code> is wrong, or the redirect in the Developer Portal doesn't match <code>DISCORD_REDIRECT_URI</code> exactly.</p><pre>${escapeHtml((err as Error).message)}</pre>`, "Try again");
    }
}
