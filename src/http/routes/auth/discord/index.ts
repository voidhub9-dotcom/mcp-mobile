import type { IncomingMessage, ServerResponse } from "http";
import { readBody } from "../../../body.js";
import { within, previewLogoUrl } from "../../../../discord/app-assets.js";
import { DEFAULT_DISCORD_USER_KEY, DISCORD_CLIENT_ID, DISCORD_CLIENT_SECRET, DISCORD_REDIRECT_URI, DISCORD_SHOW_GAME_ICON, PRESENCE_IDLE_TIMEOUT_MS, PRESENCE_LARGE_TEXT, PRESENCE_STATE, TOKEN_ENCRYPTION_KEY, TOKEN_STORE_PERSISTENT, } from "../../../../discord/config.js";
import { getPresenceStatus, presenceButtons, presenceTitle } from "../../../../discord/discordPresence.js";
import { getGameIconUrl } from "../../../../discord/game-icon.js";
import { authRequired, authorize, clearAuthCookie, escapeHtml, hasValidAuthCookie, icon, LOGO_SVG, parseForm, redirect, sendMessage, sendPage, serverTokenMatches, setAuthCookie, toast, type Tone } from "../../../../discord/http.js";
import { createAuthorizeUrl } from "../../../../discord/oauth.js";
import { getLink, tokenStorageAvailable } from "../../../../discord/token-store.js";
import { currentGame } from "../../../../discord/tool-hook.js";

// GET  /auth/discord            VoidHub RPC page: sign in (once per device), status, preview, actions
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
    sendMessage(res, 503, "error", "Discord isn't set up yet", `The server is missing ${missing.length === 1 ? "a variable" : `${missing.length} variables`}: ${missing.map((m) => `<code>${m}</code>`).join(" ")}`, "Reload", {
        steps: ["Open Railway → your service → <b>Variables</b>", `Add ${missing.map((m) => `<code>${m}</code>`).join(", ")}`, "Wait for the redeploy to finish, then reload this page"],
    });
    return true;
}

function startDiscord(res: ServerResponse): void {
    const { url } = createAuthorizeUrl(DEFAULT_DISCORD_USER_KEY);
    res.writeHead(302, { Location: url, "Cache-Control": "no-store" });
    res.end();
}

const FLASH: Record<string, { tone: Tone; html: string }> = {
    linked: { tone: "ok", html: "<b>Discord linked.</b> Tap <b>Send test presence</b> to try it." },
    tested: { tone: "ok", html: "<b>Test sent.</b> Check your Discord profile. Buttons only show to other people." },
    unlinked: { tone: "info", html: "<b>Discord unlinked.</b> Tokens were revoked and deleted." },
    signedout: { tone: "info", html: "Signed out on this device." },
};

const EYE_SCRIPT = `document.querySelectorAll('[data-eye]').forEach(function(b){b.addEventListener('click',function(){var i=document.getElementById(b.getAttribute('data-eye'));if(!i)return;var show=i.type==='password';i.type=show?'text':'password';b.setAttribute('aria-pressed',String(show));b.setAttribute('aria-label',show?'Hide token':'Show token');});});`;

function loginPage(res: ServerResponse, status = 200, badToken = false): void {
    sendPage(res, status, {
        title: "Sign in",
        body: `<section class="hero"><span class="eyebrow">VoidHub RPC</span><h1>Sign in.</h1><p class="lead">Enter this server's <code>MCP_AUTH_TOKEN</code>. You only do this once on this device.</p></section>
${badToken ? toast("error", "<b>Wrong token.</b> Copy it exactly from Railway → Variables.") : ""}
<form class="card" method="post" action="/auth/discord"><input type="hidden" name="action" value="login">
<label class="label" for="tok">Server token</label>
<div class="input"><input id="tok" name="server_token" type="password" autocomplete="current-password" autocapitalize="off" autocorrect="off" spellcheck="false" required autofocus placeholder="Paste MCP_AUTH_TOKEN"><button class="eye" type="button" data-eye="tok" aria-label="Show token" aria-pressed="false">${icon("eye", 20)}</button></div>
<button class="btn primary" type="submit">Continue ${icon("arrow")}</button>
<div class="note">${icon("shield", 16)}Remembered for 30 days · secure cookie</div></form>
<p class="foot">Lost the token? It's in Railway → Variables.</p>`,
        script: EYE_SCRIPT,
    });
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
        within(previewLogoUrl(), 2500),
    ]);

    const name = link?.discordUsername || (link ? "Discord account" : "Not linked yet");
    const initial = escapeHtml((link?.discordUsername || "V").trim().charAt(0).toUpperCase() || "V");
    const avatar = link?.discordAvatarUrl
        ? `<img src="${escapeHtml(link.discordAvatarUrl)}" alt="">`
        : initial;
    const sub = link
        ? (link.discordUserId ? `ID ${escapeHtml(link.discordUserId)}` : "Linked to VoidHub RPC")
        : "Link Discord to show your presence";

    // Activity art: game icon (big) + logo badge, or the logo alone.
    const bigTitle = gameIcon && game ? game.placeName : PRESENCE_LARGE_TEXT;
    let art: string;
    if (gameIcon) {
        art = `<div class="big" role="img" aria-label="${escapeHtml(bigTitle)}" title="${escapeHtml(bigTitle)}" style="background:#26262b url('${escapeHtml(gameIcon)}') center/cover"></div><span class="ring">${logo ? `<span class="bgimg" style="background-image:url('${escapeHtml(logo)}')"></span>` : LOGO_SVG(24)}</span>`;
    }
    else if (logo) {
        art = `<div class="big" role="img" aria-label="${escapeHtml(PRESENCE_LARGE_TEXT)}" title="${escapeHtml(PRESENCE_LARGE_TEXT)}" style="background:#26262b url('${escapeHtml(logo)}') center/cover"></div>`;
    }
    else {
        art = `<div class="big logo">${icon("game", 34)}</div>`;
    }

    const profile = `<section class="panel"><div class="dc" aria-label="Discord profile preview"><div class="banner"></div>
<div class="av">${avatar}<span class="on${presence.active ? "" : " idle"}"></span></div>
<div class="body"><div class="names"><b>${escapeHtml(name)}</b><span>${sub}</span></div>
<div class="act"><div class="caps">${presence.active ? "Playing" : "Playing · preview"}</div>
<div class="row"><div class="art">${art}</div><div class="t"><b>${escapeHtml(presenceTitle(game))}</b><div>${escapeHtml(presence.details ?? "Using VoidHub")}</div><div class="m">${escapeHtml(PRESENCE_STATE)}</div><div class="time">${icon("game", 13)}${fmtElapsed(presence.sessionStart)}</div></div></div>
${presenceButtons(game).map((b) => `<a class="get" href="${escapeHtml(b.url)}" target="_blank" rel="noopener noreferrer">${escapeHtml(b.label)}</a>`).join("")}</div></div></div></section>`;

    const chip = (ic: string, v: string, on: boolean, wide = false) => `<div class="chip ${on ? "on" : "off"}${wide ? " wide" : ""}">${icon(ic, 18)}<span>${escapeHtml(v)}</span></div>`;
    const tiles = `<section class="chips">${chip(link ? "check" : "link", link ? "Discord linked" : "Not linked", Boolean(link))}${chip("zap", presence.active ? "Presence live" : "Presence idle", presence.active)}${chip("game", game ? game.placeName : "No game connected", Boolean(game), true)}</section>`;

    const signOut = authRequired()
        ? `<form method="post" action="/auth/discord"><input type="hidden" name="action" value="logout"><button class="btn link" type="submit">${icon("logout", 16)}Sign out on this device</button></form>`
        : "";
    const actions = link
        ? `<section class="sec"><h2>Controls.</h2><p>Test it, relink, or remove the link.</p></section><section class="actions">
<form method="post" action="/auth/discord/test"><button class="btn primary" type="submit">${icon("zap")}Send test presence</button></form>
<form method="post" action="/auth/discord"><input type="hidden" name="action" value="link"><button class="btn secondary" type="submit">${icon("refresh")}Relink Discord</button></form>
<form method="post" action="/auth/discord/unlink"><button class="btn danger" type="submit">${icon("unlink")}Unlink Discord</button></form>
${signOut}</section>`
        : `<section class="actions">
<form method="post" action="/auth/discord"><input type="hidden" name="action" value="link"><button class="btn primary" type="submit">${icon("link")}Link Discord</button></form>
${signOut}</section>`;

    const saved = presence.lastSaved
        ? `<details class="card saved"><summary class="label">What Discord saved</summary><p class="small">Exactly what Discord stored for your status on the last update. Buttons only show to <b>other people</b> on Discord, never on your own profile.</p><pre>${escapeHtml(JSON.stringify(presence.lastSaved, null, 2))}</pre></details>`
        : "";
    const volumeWarn = TOKEN_STORE_PERSISTENT ? "" : toast("error", "<b>Your Discord link is wiped on every redeploy.</b> In Railway, open your service → right-click → <b>Attach Volume</b>, set the mount path to <code>/data</code>, then link once more. After that it stays linked.");
    const note = `<p class="foot">Updates while the AI uses tools · clears after ${Math.round(PRESENCE_IDLE_TIMEOUT_MS / 60_000)} idle minutes</p>`;
    const pill = presence.active ? `<span class="pill">Live</span>` : link ? `<span class="pill off">Idle</span>` : "";
    sendPage(res, 200, {
        title: link ? "Dashboard" : "Link Discord",
        headerRight: pill,
        body: `<section class="hero"><span class="eyebrow">Discord Rich Presence</span><h1>${link ? "You're live." : "Go live."}</h1><p class="lead">${link ? "Your Discord shows the game you're in and what the AI is building." : "Link Discord once. Your status follows every game automatically."}</p></section>` + volumeWarn + (flash && FLASH[flash] ? toast(FLASH[flash].tone, FLASH[flash].html) : "") + profile + tiles + actions + saved + note,
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
            loginPage(res, 401, true);
            return;
        }
        setAuthCookie(req, res);
        redirect(res, "/auth/discord");
        return;
    }
    // action === "link"
    if (!authorize(req, res, form.server_token)) {
        loginPage(res, 401, Boolean(form.server_token));
        return;
    }
    startDiscord(res);
}
