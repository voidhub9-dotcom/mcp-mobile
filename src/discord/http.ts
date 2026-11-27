import crypto from "node:crypto";
import type { IncomingMessage, ServerResponse } from "http";
import { MCP_AUTH_TOKEN } from "../config.js";

// Shared helpers for the /auth/discord routes.
//
// The server has one shared MCP_AUTH_TOKEN, so linking/unlinking is gated by
// that token when it is set (otherwise anyone who finds the Railway URL could
// replace the linked Discord account). After the token is entered once, the
// browser gets a signed, HttpOnly "remember this device" cookie so it isn't
// asked again. Without MCP_AUTH_TOKEN the routes are open (local use).

export function authRequired(): boolean {
    return Boolean(MCP_AUTH_TOKEN);
}

function sha256(value: string): Buffer {
    return crypto.createHash("sha256").update(value).digest();
}

export function serverTokenMatches(provided: string | null | undefined): boolean {
    if (!MCP_AUTH_TOKEN)
        return true;
    if (!provided)
        return false;
    return crypto.timingSafeEqual(sha256(provided), sha256(MCP_AUTH_TOKEN));
}

export function bearerToken(req: IncomingMessage): string | null {
    const header = req.headers.authorization || "";
    const match = /^Bearer\s+(.+)$/i.exec(header);
    return match ? match[1].trim() : null;
}

// ---- "Remember this device" cookie -------------------------------------------------

export const AUTH_COOKIE = "voidhub_rpc_auth";
const AUTH_COOKIE_MAX_AGE_S = 30 * 24 * 60 * 60;

/** HMAC key derived from MCP_AUTH_TOKEN, so rotating the token signs everyone out. */
function cookieKey(): Buffer {
    return crypto.createHmac("sha256", MCP_AUTH_TOKEN ?? "").update("voidhub-rpc-cookie-v1").digest();
}

function signCookie(expiresAtS: number): string {
    const mac = crypto.createHmac("sha256", cookieKey()).update(String(expiresAtS)).digest("base64url");
    return `${expiresAtS}.${mac}`;
}

export function readCookies(req: IncomingMessage): Record<string, string> {
    const out: Record<string, string> = {};
    for (const part of (req.headers.cookie || "").split(";")) {
        const idx = part.indexOf("=");
        if (idx > 0)
            out[part.slice(0, idx).trim()] = decodeURIComponent(part.slice(idx + 1).trim());
    }
    return out;
}

export function hasValidAuthCookie(req: IncomingMessage): boolean {
    if (!MCP_AUTH_TOKEN)
        return false;
    const raw = readCookies(req)[AUTH_COOKIE];
    const [exp, mac] = (raw || "").split(".");
    const expS = Number(exp);
    if (!mac || !Number.isFinite(expS) || expS * 1000 < Date.now())
        return false;
    const expected = signCookie(expS);
    return crypto.timingSafeEqual(sha256(expected), sha256(raw));
}

function isHttps(req: IncomingMessage): boolean {
    const proto = String(req.headers["x-forwarded-proto"] || "").split(",")[0].trim();
    return proto === "https" || Boolean((req.socket as { encrypted?: boolean }).encrypted);
}

function cookieAttrs(req: IncomingMessage, maxAge: number): string {
    return `Path=/auth/discord; HttpOnly; SameSite=Lax; Max-Age=${maxAge}${isHttps(req) ? "; Secure" : ""}`;
}

export function setAuthCookie(req: IncomingMessage, res: ServerResponse): void {
    const exp = Math.floor(Date.now() / 1000) + AUTH_COOKIE_MAX_AGE_S;
    res.setHeader("Set-Cookie", `${AUTH_COOKIE}=${encodeURIComponent(signCookie(exp))}; ${cookieAttrs(req, AUTH_COOKIE_MAX_AGE_S)}`);
}

export function clearAuthCookie(req: IncomingMessage, res: ServerResponse): void {
    res.setHeader("Set-Cookie", `${AUTH_COOKIE}=; ${cookieAttrs(req, 0)}`);
}

/**
 * Cookie-authenticated POSTs must come from this site. SameSite=Lax already
 * blocks cross-site POSTs from carrying the cookie; this is belt and braces.
 */
export function sameOrigin(req: IncomingMessage): boolean {
    const origin = req.headers.origin;
    if (!origin || origin === "null")
        return true; // some mobile browsers omit it on same-site form posts
    const host = String(req.headers["x-forwarded-host"] || req.headers.host || "").split(",")[0].trim();
    try {
        return new URL(origin).host === host;
    }
    catch {
        return false;
    }
}

/**
 * Is this request allowed? Accepts (in order) no-auth mode, a Bearer header,
 * a `server_token` form field (and then remembers the device), or the cookie.
 */
export function authorize(req: IncomingMessage, res: ServerResponse, formToken?: string | null): boolean {
    if (!authRequired())
        return true;
    if (serverTokenMatches(bearerToken(req)))
        return true;
    if (formToken && serverTokenMatches(formToken)) {
        setAuthCookie(req, res);
        return true;
    }
    return hasValidAuthCookie(req) && sameOrigin(req);
}

// ---- Responses ---------------------------------------------------------------------

export function escapeHtml(value: string): string {
    return value.replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c] as string);
}

export function sendJson(res: ServerResponse, status: number, value: unknown): void {
    res.writeHead(status, { "Content-Type": "application/json", "Cache-Control": "no-store" });
    res.end(JSON.stringify(value));
}

export function redirect(res: ServerResponse, location: string): void {
    res.writeHead(303, { Location: location, "Cache-Control": "no-store" });
    res.end();
}

export function wantsJson(req: IncomingMessage): boolean {
    const accept = req.headers.accept || "";
    const type = req.headers["content-type"] || "";
    return accept.includes("application/json") || type.includes("application/json");
}

export function parseForm(raw: string, contentType: string | undefined): Record<string, string> {
    if ((contentType || "").includes("application/json")) {
        try {
            const parsed = JSON.parse(raw) as Record<string, unknown>;
            return Object.fromEntries(Object.entries(parsed).map(([k, v]) => [k, String(v ?? "")]));
        }
        catch {
            return {};
        }
    }
    return Object.fromEntries(new URLSearchParams(raw));
}

// ---- Page shell ----------------------------------------------------------------------

export type Tone = "ok" | "error" | "info";

const LOGO_SVG = `<svg viewBox="0 0 48 48" width="40" height="40" aria-hidden="true"><defs><linearGradient id="vh" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#7c5cff"/><stop offset="1" stop-color="#5865f2"/></linearGradient></defs><rect width="48" height="48" rx="14" fill="url(#vh)"/><path d="M13 14h6.2L24 28.6 28.8 14H35l-8.4 21h-5.2z" fill="#fff"/></svg>`;

const STYLES = `
:root{--bg:#0b0c10;--bg2:#12131a;--card:#16171f;--card2:#1d1e28;--line:#272938;--text:#eceef5;--muted:#9a9db0;--accent:#5865f2;--accent2:#7c5cff;--ok:#23a55a;--err:#f23f43;--warn:#f0b232;--radius:16px}
*{box-sizing:border-box}
html,body{margin:0}
body{min-height:100vh;background:radial-gradient(1200px 600px at 10% -10%,#262a6b55,transparent 60%),radial-gradient(900px 500px at 110% 10%,#5b2fa055,transparent 60%),var(--bg);color:var(--text);font:15px/1.55 ui-sans-serif,system-ui,-apple-system,"Segoe UI",Roboto,sans-serif;-webkit-font-smoothing:antialiased}
.wrap{max-width:480px;margin:0 auto;padding:28px 16px 48px}
.brand{display:flex;align-items:center;gap:12px;margin-bottom:22px}
.brand b{display:block;font-size:17px;letter-spacing:.2px}
.brand span{color:var(--muted);font-size:13px}
.card{background:linear-gradient(180deg,var(--card),var(--bg2));border:1px solid var(--line);border-radius:var(--radius);padding:20px;margin-bottom:14px;box-shadow:0 10px 30px #0006}
h1{font-size:22px;line-height:1.25;margin:0 0 6px}
h2{font-size:13px;text-transform:uppercase;letter-spacing:.08em;color:var(--muted);margin:0 0 12px;font-weight:600}
p{margin:0 0 12px;color:#c9cbd8}
p:last-child{margin-bottom:0}
code{font:12.5px ui-monospace,SFMono-Regular,Menlo,monospace;background:#0006;border:1px solid var(--line);padding:1px 6px;border-radius:6px;color:#dfe2ff;word-break:break-all}
pre{font:12.5px/1.5 ui-monospace,SFMono-Regular,Menlo,monospace;background:#0008;border:1px solid var(--line);border-radius:12px;padding:12px;white-space:pre-wrap;word-break:break-word;color:#ffd5d6;margin:0 0 12px}
.banner{display:flex;gap:10px;align-items:flex-start;border-radius:12px;padding:12px 14px;margin-bottom:14px;border:1px solid}
.banner.ok{background:#23a55a1a;border-color:#23a55a55}
.banner.error{background:#f23f431a;border-color:#f23f4355}
.banner.info{background:#5865f21a;border-color:#5865f255}
.banner .dot{flex:none;width:10px;height:10px;border-radius:50%;margin-top:7px}
.banner.ok .dot{background:var(--ok)}.banner.error .dot{background:var(--err)}.banner.info .dot{background:var(--accent)}
.row{display:flex;align-items:center;justify-content:space-between;gap:12px;padding:10px 0;border-top:1px solid var(--line)}
.row:first-of-type{border-top:0;padding-top:0}
.row .k{color:var(--muted)}
.pill{display:inline-flex;align-items:center;gap:6px;font-size:13px;font-weight:600;padding:3px 10px;border-radius:999px;background:#ffffff10}
.pill::before{content:"";width:8px;height:8px;border-radius:50%;background:currentColor}
.pill.ok{color:#4ade80}.pill.off{color:var(--muted)}.pill.warn{color:var(--warn)}
form{margin:0}
.actions{display:grid;gap:10px}
.btn{appearance:none;display:flex;align-items:center;justify-content:center;gap:8px;width:100%;border:0;border-radius:12px;padding:13px 16px;font:600 15px/1 inherit;font-family:inherit;color:#fff;background:linear-gradient(180deg,var(--accent),#4752c4);cursor:pointer;text-decoration:none;box-shadow:0 6px 18px #5865f240}
.btn:active{transform:translateY(1px)}
.btn.secondary{background:var(--card2);border:1px solid var(--line);box-shadow:none;color:var(--text)}
.btn.danger{background:transparent;border:1px solid #f23f4366;color:#ff8a8c;box-shadow:none}
.btn.ghost{background:transparent;box-shadow:none;color:var(--muted);font-weight:500;padding:8px}
input[type=password],input[type=text]{width:100%;background:#0b0c10;border:1px solid var(--line);border-radius:12px;padding:13px 14px;color:var(--text);font:15px inherit;font-family:inherit;margin:0 0 12px;outline:none}
input:focus{border-color:var(--accent);box-shadow:0 0 0 3px #5865f233}
.hint{font-size:13px;color:var(--muted);margin-top:10px}
.presence{background:#111218;border:1px solid var(--line);border-radius:14px;padding:14px}
.presence .label{font-size:11px;font-weight:700;letter-spacing:.06em;text-transform:uppercase;color:var(--muted);margin-bottom:10px}
.pr{display:flex;gap:12px;align-items:center}
.art{position:relative;flex:none;width:84px;height:84px}
.art .big{width:84px;height:84px;border-radius:12px;object-fit:cover;background:linear-gradient(135deg,var(--accent2),var(--accent));display:flex;align-items:center;justify-content:center}
.art .small{position:absolute;right:-6px;bottom:-6px;width:30px;height:30px;border-radius:50%;border:3px solid #111218;background:var(--accent);object-fit:cover}
.pr .t{min-width:0}
.pr .t b{display:block;font-size:15px}
.pr .t div{color:#c9cbd8;font-size:13.5px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.pr .t .time{color:#4ade80;font-size:13px}
.fakebtn{margin-top:12px;text-align:center;font-size:13.5px;font-weight:600;padding:9px;border-radius:8px;background:#ffffff14;color:#dfe1ea}
.foot{text-align:center;color:#6c6f82;font-size:12px;margin-top:20px}
a{color:#9aa4ff}
`;

export interface PageOptions {
    title: string;
    banner?: { tone: Tone; html: string } | null;
    body: string;
}

export function renderPage(opts: PageOptions): string {
    const banner = opts.banner
        ? `<div class="banner ${opts.banner.tone}"><span class="dot"></span><div>${opts.banner.html}</div></div>`
        : "";
    return `<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover"><meta name="color-scheme" content="dark"><meta name="theme-color" content="#0b0c10"><title>${escapeHtml(opts.title)} · Void Hub RPC</title><style>${STYLES}</style></head><body><main class="wrap"><header class="brand">${LOGO_SVG}<div><b>Void Hub RPC</b><span>Discord Rich Presence for Void Hub MCP</span></div></header>${banner}${opts.body}<p class="foot">Void Hub MCP</p></main></body></html>`;
}

export function sendPage(res: ServerResponse, status: number, opts: PageOptions): void {
    res.writeHead(status, {
        "Content-Type": "text/html; charset=utf-8",
        "Cache-Control": "no-store",
        "Referrer-Policy": "no-referrer",
        "X-Frame-Options": "DENY",
        "X-Content-Type-Options": "nosniff",
        "Content-Security-Policy": "default-src 'none'; style-src 'unsafe-inline'; img-src https: data:; form-action 'self' https://discord.com; base-uri 'none'; frame-ancestors 'none'",
    });
    res.end(renderPage(opts));
}

/** Simple message page (errors, results). */
export function sendMessage(res: ServerResponse, status: number, tone: Tone, title: string, html: string, backLabel = "Back to Void Hub RPC"): void {
    sendPage(res, status, {
        title,
        banner: { tone, html: `<b>${escapeHtml(title)}</b>` },
        body: `<section class="card">${html}</section><a class="btn secondary" href="/auth/discord">${escapeHtml(backLabel)}</a>`,
    });
}

/** Kept for older callers. */
export function sendHtml(res: ServerResponse, status: number, title: string, bodyHtml: string): void {
    sendMessage(res, status, status >= 400 ? "error" : "info", title, bodyHtml);
}
