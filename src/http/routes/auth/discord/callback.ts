import type { IncomingMessage, ServerResponse } from "http";
import { discordOAuthConfigured } from "../../../../discord/config.js";
import { escapeHtml, redirect, sendMessage } from "../../../../discord/http.js";
import { consumeState, exchangeCode } from "../../../../discord/oauth.js";

// GET /auth/discord/callback?code=...&state=...
// Exchanges the code, stores the encrypted tokens, then returns to the VoidHub RPC page.

const ERROR_HELP: Record<string, { text: string; steps?: string[] }> = {
    access_denied: { text: "You cancelled on Discord's screen. Nothing was linked." },
    invalid_scope: {
        text: "This Discord app isn't allowed to use Rich Presence yet.",
        steps: ["Open your app in the Discord Developer Portal", "Go to <b>Discord Social SDK → Getting Started</b>", "Submit the form, wait a minute, try again"],
    },
    invalid_request: {
        text: "Discord didn't accept the request.",
        steps: ["Developer Portal → your app → <b>OAuth2 → Redirects</b>", "Make sure it exactly matches the server's <code>DISCORD_REDIRECT_URI</code>", "Save, then try again"],
    },
    unauthorized_client: {
        text: "This Discord app can't use this login flow.",
        steps: ["Check <code>DISCORD_CLIENT_ID</code> in Railway is this app's <b>Application ID</b>", "Redeploy, then try again"],
    },
};

export async function GET(_req: IncomingMessage, res: ServerResponse, url: URL): Promise<void> {
    if (!discordOAuthConfigured()) {
        sendMessage(res, 503, "error", "Discord isn't set up on the server", "The <code>DISCORD_*</code> variables are missing.");
        return;
    }
    const error = url.searchParams.get("error");
    const userKey = consumeState(url.searchParams.get("state"));
    if (error) {
        const help = ERROR_HELP[error] ?? { text: "Discord stopped the login." };
        sendMessage(res, 400, "error", "Discord linking didn't finish", help.text, "Try again", { code: error, steps: help.steps });
        return;
    }
    if (!userKey) {
        sendMessage(res, 400, "error", "That link expired", "The login took longer than 10 minutes, or the server restarted in the middle. Just start again.", "Start again");
        return;
    }
    const code = url.searchParams.get("code");
    if (!code) {
        sendMessage(res, 400, "error", "Discord didn't send a code", "Start the link again.", "Start again");
        return;
    }
    try {
        const link = await exchangeCode(userKey, code);
        console.error(`[Discord] Linked Discord user ${link.discordUserId ?? "(unknown id)"} for "${userKey}".`);
        redirect(res, "/auth/discord?linked=1");
    }
    catch (err) {
        console.error("[Discord] Code exchange failed:", (err as Error).message);
        sendMessage(res, 502, "error", "Discord linking failed", "The server couldn't swap the login code with Discord.", "Try again", {
            steps: ["Check <code>DISCORD_CLIENT_SECRET</code> in Railway is the newest secret", "Check the portal redirect exactly matches <code>DISCORD_REDIRECT_URI</code>"],
            detail: `<div class="caps">Error from Discord</div><pre>${escapeHtml((err as Error).message)}</pre>`,
        });
    }
}
