import type { IncomingMessage, ServerResponse } from "http";
import { readBody } from "../../../body.js";
import { within, resolveAssetImage } from "../../../../discord/app-assets.js";
import { DEFAULT_DISCORD_USER_KEY, DISCORD_BUTTON_URL, DISCORD_CLIENT_ID, DISCORD_CLIENT_SECRET, DISCORD_LARGE_IMAGE_KEY, DISCORD_REDIRECT_URI, DISCORD_SHOW_GAME_ICON, PRESENCE_BUTTON_LABEL, PRESENCE_IDLE_TIMEOUT_MS, PRESENCE_LARGE_TEXT, PRESENCE_NAME, PRESENCE_STATE, TOKEN_ENCRYPTION_KEY, } from "../../../../discord/config.js";
import { getPresenceStatus } from "../../../../discord/discordPresence.js";
import { getGameIconUrl } from "../../../../discord/game-icon.js";
import { authRequired, authorize, clearAuthCookie, escapeHtml, hasValidAuthCookie, parseForm, redirect, sendMessage, sendPage, serverTokenMatches, setAuthCookie, type Tone } from "../../../../discord/http.js";
import { createAuthorizeUrl } from "../../../../discord/oauth.js";
import { getLink, tokenStorageAvailable } from "../../../../discord/token-store.js";
import { currentGame } from "../../../../discord/tool-hook.js";

// GET  /auth/discord            Void Hub RPC page: sign in (once per device), status, preview, actions
// GET  /auth/discord?start=1    Redirect straight to Discord's authorize screen (when authorized)
// POST /auth/discord            action=login | link | logout

function missingConfig(): string[] {
    const missing: string[] = [];
    if (!DISCORD_CLIENT_ID)
        missing.push("DISCORD_CLIENT_ID");
    if (!DISCORD_CLIENT_SECRET)
        missing.push("DISCORD_CLIENT_SECRET");
    if (!DISCORD_REDIRECT_URI)
        missing.push("DISCORD_REDIRECT_URI");
    if (!TOKEN_ENCRYPTION_KEY || !tokenStorageAvailable())
        missing.push("TOKEN_ENCRYPTION_KEY");
    return missing;
}

function notConfigured(res: ServerResponse): boolean {
    const missing = missingConfig();
    if (missing.length === 0)
        return false;
    sendMessage(res, 503, "error", "Discord isn't set up on the server yet", `<p>Add ${missing.length === 1 ? "this variable" : "these variables"} in Railway → <b>Variables</b>, then redeploy:</p><p>${missing.map((m) => `<code>${m}</code>`).join(" ")}</p><p class="hint">Full guide: <code>docs/discord-rpc.md</code></p>`, "Reload");
    return true;
}

function startDiscord(res: ServerResponse): void {
    const { url } = createAuthorizeUrl(DEFAULT_DISCORD_USER_KEY);
    res.writeHead(302, { Location: url, "Cache-Control": "no-store" });
    res.end();
}

const FLASH: Record<string, { tone: Tone; html: string }> = {
    linked: { tone: "ok", html: "<b>Discord linked.</b> Tap <b>Send test presence</b> to check your profile." },
    tested: { tone: "ok", html: "<b>Test sent.</b> Discord accepted it. Open your Discord profile to see it." },
    unlinked: { tone: "info", html: "<b>Discord unlinked.</b> Tokens were revoked and deleted." },
    signedout: { tone: "info", html: "Signed out on this device." },
    badtoken: { tone: "error", html: "<b>Wrong token.</b> Enter the <code>MCP_AUTH_TOKEN</code> from Railway exactly." },
};

function loginPage(res: ServerResponse, status = 200, flash?: string): void {
    sendPage(res, status, {
        title: "Sign in",
        banner: flash ? FLASH[flash] ?? null : null,
        body: `<section class="card"><h1>Sign in</h1><p>Enter this server's <code>MCP_AUTH_TOKEN</code>. You only need to do this once: this device is remembered for 30 days.</p>
<form method="post" action="/auth/discord"><input type="hidden" name="action" value="login">
<input name="server_token" type="password" autocomplete="current-password" required autofocus placeholder="MCP_AUTH_TOKEN" aria-label="MCP_AUTH_TOKEN">
<button class="btn" type="submit">Continue</button></form></section>`,
    });
}

function fmtAgo(ms: number): string {
    const s = Math.max(0, Math.round((Date.now() - ms) / 1000));
    if (s < 60)
        return `${s}s ago`;
    const m = Math.round(s / 60);
    return m < 60 ? `${m} min ago` : `${Math.round(m / 60)} h ago`;
}

function fmtElapsed(startMs: number | null): string {
    if (!startMs)
        return "00:00 elapsed";
    const s = Math.max(0, Math.floor((Date.now() - startMs) / 1000));
    const mm = String(Math.floor(s / 60) % 60).padStart(2, "0");
    const ss = String(s % 60).padStart(2, "0");
    const hh = Math.floor(s / 3600);
    return `${hh ? `${hh}:` : ""}${mm}:${ss} elapsed`;
}

async function dashboard(res: ServerResponse, flash: string | null): Promise<void> {
    const link = await getLink(DEFAULT_DISCORD_USER_KEY);
    const presence = getPresenceStatus(DEFAULT_DISCORD_USER_KEY);
    const game = presence.game ?? currentGame();
    const [gameIcon, logo] = await Promise.all([
        game && DISCORD_SHOW_GAME_ICON ? within(getGameIconUrl(game.placeId), 2500) : Promise.resolve(null),
        within(resolveAssetImage(DISCORD_LARGE_IMAGE_KEY), 2500),
    ]);

    const who = link
        ? escapeHtml(link.discordUsername || (link.discordUserId ? `User ${link.discordUserId}` : "Linked account"))
        : "";
    const avatar = link?.discordAvatarUrl
        ? `<img src="${escapeHtml(link.discordAvatarUrl)}" alt="" width="22" height="22" style="border-radius:50%;vertical-align:-6px;margin-right:6px">`
        : "";
    const accountRow = link
        ? `<span class="pill ok">Linked</span>`
        : `<span class="pill off">Not linked</span>`;
    const presenceRow = presence.active
        ? `<span class="pill ok">Showing</span>`
        : `<span class="pill off">Idle</span>`;
    const statusCard = `<section class="card"><h2>Status</h2>
<div class="row"><span class="k">Discord</span>${accountRow}</div>
${link ? `<div class="row"><span class="k">Account</span><span>${avatar}${who}</span></div>` : ""}
<div class="row"><span class="k">Presence</span>${presenceRow}</div>
${presence.active && presence.lastActivityAt ? `<div class="row"><span class="k">Last tool call</span><span>${fmtAgo(presence.lastActivityAt)}</span></div>` : ""}
<div class="row"><span class="k">Roblox game</span><span>${game ? escapeHtml(game.placeName) : `<span class="pill off">None connected</span>`}</span></div>
</section>`;

    const bigImg = gameIcon ?? logo;
    const bigTitle = gameIcon && game ? game.placeName : PRESENCE_LARGE_TEXT;
    const bigHtml = bigImg
        ? `<img class="big" src="${escapeHtml(bigImg)}" alt="${escapeHtml(bigTitle)}" title="${escapeHtml(bigTitle)}">`
        : `<div class="big"><svg viewBox="0 0 48 48" width="44" height="44" aria-hidden="true"><path d="M13 14h6.2L24 28.6 28.8 14H35l-8.4 21h-5.2z" fill="#fff"/></svg></div>`;
    const smallHtml = gameIcon
        ? (logo ? `<img class="small" src="${escapeHtml(logo)}" alt="" title="${escapeHtml(PRESENCE_LARGE_TEXT)}">` : `<span class="small"></span>`)
        : "";
    const preview = `<section class="card"><h2>${presence.active ? "Live on your profile" : "Preview"}</h2><div class="presence"><div class="label">Playing</div>
<div class="pr"><div class="art">${bigHtml}${smallHtml}</div><div class="t"><b>${escapeHtml(PRESENCE_NAME)}</b><div>${escapeHtml(presence.details ?? "Making a script")}</div><div>${escapeHtml(PRESENCE_STATE)}</div><div class="time">${fmtElapsed(presence.sessionStart)}</div></div></div>
${DISCORD_BUTTON_URL ? `<div class="fakebtn">${escapeHtml(PRESENCE_BUTTON_LABEL)}</div>` : ""}</div>
<p class="hint">Updates while the AI uses tools and clears after ${Math.round(PRESENCE_IDLE_TIMEOUT_MS / 60_000)} idle minutes.${game && !gameIcon && DISCORD_SHOW_GAME_ICON ? " The game icon will show once Roblox returns it." : ""}</p></section>`;

    const actions = link
        ? `<section class="actions">
<form method="post" action="/auth/discord/test"><button class="btn" type="submit">Send test presence</button></form>
<form method="post" action="/auth/discord"><input type="hidden" name="action" value="link"><button class="btn secondary" type="submit">Relink Discord</button></form>
<form method="post" action="/auth/discord/unlink"><button class="btn danger" type="submit">Unlink Discord</button></form>
${authRequired() ? `<form method="post" action="/auth/discord"><input type="hidden" name="action" value="logout"><button class="btn ghost" type="submit">Sign out on this device</button></form>` : ""}
</section>`
        : `<section class="actions">
<form method="post" action="/auth/discord"><input type="hidden" name="action" value="link"><button class="btn" type="submit">Link Discord</button></form>
${authRequired() ? `<form method="post" action="/auth/discord"><input type="hidden" name="action" value="logout"><button class="btn ghost" type="submit">Sign out on this device</button></form>` : ""}
</section>`;

    sendPage(res, 200, {
        title: link ? "Dashboard" : "Link Discord",
        banner: flash ? FLASH[flash] ?? null : null,
        body: statusCard + preview + actions,
    });
}

export async function GET(req: IncomingMessage, res: ServerResponse, url: URL): Promise<void> {
    if (notConfigured(res))
        return;
    const signedIn = !authRequired() || hasValidAuthCookie(req);
    if (!signedIn) {
        loginPage(res);
        return;
    }
    if (url.searchParams.get("start") === "1") {
        startDiscord(res);
        return;
    }
    const flash = ["linked", "tested", "unlinked", "signedout"].find((k) => url.searchParams.has(k)) ?? null;
    await dashboard(res, flash);
}

export async function POST(req: IncomingMessage, res: ServerResponse): Promise<void> {
    if (notConfigured(res))
        return;
    const form = parseForm(await readBody(req), req.headers["content-type"]);
    const action = form.action || "link";
    if (action === "logout") {
        clearAuthCookie(req, res);
        redirect(res, "/auth/discord?signedout=1");
        return;
    }
    if (action === "login") {
        if (!authRequired()) {
            redirect(res, "/auth/discord");
            return;
        }
        if (!serverTokenMatches(form.server_token)) {
            loginPage(res, 401, "badtoken");
            return;
        }
        setAuthCookie(req, res);
        redirect(res, "/auth/discord");
        return;
    }
    // action === "link"
    if (!authorize(req, res, form.server_token)) {
        loginPage(res, 401, form.server_token ? "badtoken" : undefined);
        return;
    }
    startDiscord(res);
}
