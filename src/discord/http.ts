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

// ---- Page shell (matches the "Void Hub RPC" Figma design) -------------------------

export type Tone = "ok" | "error" | "info";

// Lucide icons (same set used in the Figma file).
const ICON_PATHS: Record<string, string> = {
    lock: '<rect width="18" height="11" x="3" y="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/>',
    eye: '<path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/>',
    shield: '<path d="M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-.81c2 0 4.5-1.2 6.24-2.72a1.17 1.17 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z"/><path d="m9 12 2 2 4-4"/>',
    check: '<path d="M20 6 9 17l-5-5"/>',
    logout: '<path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><path d="m16 17 5-5-5-5"/><path d="M21 12H9"/>',
    alert: '<path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3"/><path d="M12 9v4"/><path d="M12 17h.01"/>',
    info: '<circle cx="12" cy="12" r="10"/><path d="M12 16v-4"/><path d="M12 8h.01"/>',
    game: '<path d="M6 11h4"/><path d="M8 9v4"/><path d="M15 12h.01"/><path d="M18 10h.01"/><path d="M17.32 5H6.68a4 4 0 0 0-3.978 3.59c-.006.052-.01.101-.017.152C2.604 9.416 2 14.456 2 16a3 3 0 0 0 3 3c1 0 1.5-.5 2-1l1.414-1.414A2 2 0 0 1 9.828 16h4.344a2 2 0 0 1 1.414.586L17 18c.5.5 1 1 2 1a3 3 0 0 0 3-3c0-1.545-.604-6.584-.685-7.258-.007-.05-.011-.1-.017-.151A4 4 0 0 0 17.32 5z"/>',
    arrow: '<path d="M5 12h14"/><path d="m12 5 7 7-7 7"/>',
    zap: '<path d="M13 2 3 14h9l-1 8 10-12h-9l1-8z"/>',
    refresh: '<path d="M3 12a9 9 0 0 1 9-9 9.75 9.75 0 0 1 6.74 2.74L21 8"/><path d="M21 3v5h-5"/><path d="M21 12a9 9 0 0 1-9 9 9.75 9.75 0 0 1-6.74-2.74L3 16"/><path d="M8 16H3v5"/>',
    unlink: '<path d="m18.84 12.25 1.72-1.71h-.02a5.004 5.004 0 0 0-.12-7.07 5.006 5.006 0 0 0-6.95 0l-1.72 1.71"/><path d="m5.17 11.75-1.71 1.71a5.004 5.004 0 0 0 .12 7.07 5.006 5.006 0 0 0 6.95 0l1.71-1.71"/><path d="M8 2v3"/><path d="M2 8h3"/><path d="M16 19v3"/><path d="M19 16h3"/>',
    link: '<path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/>',
    clock: '<circle cx="12" cy="12" r="10"/><path d="M12 6v6l4 2"/>',
};

export function icon(name: string, size = 18, strokeWidth = 2): string {
    return `<svg class="i" width="${size}" height="${size}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="${strokeWidth}" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${ICON_PATHS[name] ?? ""}</svg>`;
}

export const LOGO_SVG = (size = 40) => `<svg width="${size}" height="${size}" viewBox="0 0 40 40" aria-hidden="true"><defs><linearGradient id="vhg" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#8B5CF6"/><stop offset="1" stop-color="#5865F2"/></linearGradient></defs><rect width="40" height="40" rx="12" fill="url(#vhg)"/><path d="M11 12h5.2L20 24.2 23.8 12H29l-7 17h-4z" fill="#fff"/></svg>`;

const STYLES = `
:root{--bg:#0A0B10;--surface:#13141B;--raised:#1B1C26;--border:#262838;--text:#F1F2F7;--muted:#8E91A6;--accent:#6C63FF;--ok:#3BD16F;--err:#FF5A5F;--card-dc:#18191F;--act:#111216}
*{box-sizing:border-box}
html,body{margin:0}
body{min-height:100vh;background:var(--bg);color:var(--text);font:15px/1.5 Inter,ui-sans-serif,system-ui,-apple-system,"Segoe UI",Roboto,sans-serif;letter-spacing:-.01em;-webkit-font-smoothing:antialiased;overflow-x:hidden;position:relative}
body::before,body::after{content:"";position:fixed;z-index:0;width:380px;height:320px;border-radius:50%;filter:blur(120px);pointer-events:none}
body::before{left:-120px;top:-160px;background:#5B3DF5;opacity:.55}
body::after{right:-210px;top:-120px;background:#B23CF0;opacity:.35}
.wrap{position:relative;z-index:1;max-width:440px;margin:0 auto;padding:56px 24px 40px;display:flex;flex-direction:column;gap:20px}
.i{flex:none;display:block}
.head{display:flex;align-items:center;gap:12px}
.head .t{flex:1;min-width:0}
.head b{display:block;font-size:17px;font-weight:700;line-height:1.3}
.head span{display:block;font-size:13px;font-weight:500;color:var(--muted)}
.pill{display:inline-flex;align-items:center;gap:6px;padding:6px 10px;border-radius:999px;font-size:12px;font-weight:600;background:#3BD16F1F;color:var(--ok)}
.pill::before{content:"";width:7px;height:7px;border-radius:50%;background:currentColor}
.pill.off{background:#8E91A61F;color:var(--muted)}
.hero{display:flex;flex-direction:column;gap:14px;padding-top:28px}
.badge{width:64px;height:64px;border-radius:20px;display:flex;align-items:center;justify-content:center;color:#fff}
.badge.accent{background:linear-gradient(135deg,#8B5CF6,#5865F2);box-shadow:0 12px 32px -8px #6C63FF80}
.badge.error{background:#FF5A5F24;border:1px solid #FF5A5F66;color:var(--err)}
.badge.ok{background:#3BD16F24;border:1px solid #3BD16F66;color:var(--ok)}
.badge.info{background:#6C63FF24;border:1px solid #6C63FF66;color:#A5A0FF}
h1{margin:0;font-size:30px;line-height:1.15;font-weight:700;letter-spacing:-.025em}
.lead{margin:0;font-size:15px;line-height:1.5;color:var(--muted)}
.lead b,.lead code{color:var(--text)}
.chip{align-self:flex-start;padding:6px 10px;border-radius:8px;background:#FF5A5F1F;color:var(--err);font-size:12px;font-weight:600}
.card{background:var(--surface);border:1px solid var(--border);border-radius:20px;padding:18px;display:flex;flex-direction:column;gap:14px}
.label{font-size:13px;font-weight:600}
.caps{font-size:11px;font-weight:700;letter-spacing:.08em;text-transform:uppercase;color:var(--muted)}
.input{display:flex;align-items:center;gap:10px;background:var(--bg);border:1.5px solid var(--border);border-radius:14px;padding:0 8px 0 16px;transition:border-color .15s,box-shadow .15s}
.input:focus-within{border-color:var(--accent);box-shadow:0 0 0 4px #6C63FF40}
.input input{flex:1;min-width:0;background:transparent;border:0;outline:0;color:var(--text);font:600 16px/1 inherit;font-family:inherit;padding:15px 0}
.input input::placeholder{color:#5E6176;font-weight:500}
.eye{appearance:none;border:0;background:transparent;color:var(--muted);padding:8px;border-radius:10px;cursor:pointer}
.eye:hover{color:var(--text);background:#ffffff0d}
.note{display:flex;align-items:center;gap:8px;font-size:13px;font-weight:500;color:var(--muted)}
.note .i{color:var(--ok)}
.foot{margin:0;text-align:center;font-size:13px;color:var(--muted)}
form{margin:0}
.btn{appearance:none;width:100%;display:flex;align-items:center;justify-content:center;gap:10px;border-radius:14px;padding:15px 20px;font:600 15px/1.2 inherit;font-family:inherit;letter-spacing:-.01em;cursor:pointer;text-decoration:none;border:1px solid transparent;transition:transform .08s,filter .15s}
.btn:active{transform:translateY(1px)}
.btn.primary{color:#fff;background:linear-gradient(90deg,#8B5CF6,#5865F2);border-color:#ffffff24;box-shadow:0 8px 24px -6px #6C63FF73}
.btn.primary:hover{filter:brightness(1.08)}
.btn.secondary{color:var(--text);background:var(--raised);border-color:var(--border)}
.btn.secondary:hover{background:#22232f}
.btn.danger{color:var(--err);background:#FF5A5F14;border-color:#FF5A5F59}
.btn.danger:hover{background:#FF5A5F22}
.btn.link{color:var(--muted);background:transparent;padding:8px;font-weight:500;font-size:14px}
.btn.link:hover{color:var(--text)}
.actions{display:flex;flex-direction:column;gap:10px}
.toast{display:flex;align-items:center;gap:12px;padding:12px 14px;border-radius:14px;font-size:14px;font-weight:500}
.toast .dot{flex:none;width:24px;height:24px;border-radius:50%;display:flex;align-items:center;justify-content:center;color:var(--bg)}
.toast.ok{background:#3BD16F1A;border:1px solid #3BD16F4D}.toast.ok .dot{background:var(--ok)}
.toast.error{background:#FF5A5F1A;border:1px solid #FF5A5F4D}.toast.error .dot{background:var(--err)}
.toast.info{background:#6C63FF1A;border:1px solid #6C63FF4D}.toast.info .dot{background:var(--accent);color:#fff}
.dc{position:relative;background:var(--card-dc);border:1px solid var(--border);border-radius:22px;overflow:hidden;box-shadow:0 20px 40px -12px #00000080}
.dc .banner{height:84px;background:linear-gradient(135deg,#5B3DF5,#B23CF0)}
.dc .av{position:absolute;left:16px;top:44px;width:88px;height:88px;border-radius:50%;border:6px solid var(--card-dc);background:linear-gradient(135deg,#22D3EE,#6C63FF);display:flex;align-items:center;justify-content:center;font-size:30px;font-weight:700;overflow:visible}
.dc .av img{width:100%;height:100%;border-radius:50%;object-fit:cover}
.dc .av .on{position:absolute;right:-2px;bottom:-2px;width:24px;height:24px;border-radius:50%;background:var(--ok);border:4px solid var(--card-dc)}
.dc .av .on.idle{background:#80848E}
.dc .body{padding:6px 16px 16px;display:flex;flex-direction:column;gap:14px}
.dc .names{padding-left:92px;min-height:44px}
.dc .names b{display:block;font-size:18px;font-weight:700;line-height:1.3;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.dc .names span{font-size:13px;font-weight:500;color:var(--muted)}
.act{background:var(--act);border-radius:16px;padding:14px;display:flex;flex-direction:column;gap:12px}
.act .row{display:flex;align-items:center;gap:14px}
.art{position:relative;flex:none;width:80px;height:80px}
.art .big{width:76px;height:76px;border-radius:14px;object-fit:cover;background:linear-gradient(135deg,#F59E0B,#EF4444);display:flex;align-items:center;justify-content:center;color:#fff}
.art .big.logo{background:linear-gradient(135deg,#8B5CF6,#5865F2)}
.art .ring{position:absolute;right:-4px;bottom:-4px;width:34px;height:34px;border-radius:50%;background:var(--act);display:flex;align-items:center;justify-content:center}
.art .ring img,.art .ring svg{width:28px;height:28px;border-radius:50%}
.act .t{min-width:0;display:flex;flex-direction:column;gap:2px}
.act .t b{font-size:15px;font-weight:700}
.act .t div{font-size:13px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.act .t .m{color:var(--muted)}
.act .t .time{display:flex;align-items:center;gap:5px;color:var(--ok);font-weight:600}
.act .get{text-align:center;padding:10px;border-radius:10px;background:#ffffff14;font-size:14px;font-weight:600}
.tiles{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:10px}
.tile{background:var(--raised);border:1px solid var(--border);border-radius:16px;padding:14px;display:flex;flex-direction:column;gap:8px;min-width:0}
.tile .k{font-size:12px;font-weight:500;color:var(--muted)}
.tile .v{display:flex;align-items:center;gap:6px;font-size:13px;font-weight:600;color:var(--ok);min-width:0}
.tile .v span{white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.tile .v::before{content:"";flex:none;width:8px;height:8px;border-radius:50%;background:currentColor;box-shadow:0 0 8px currentColor}
.tile .v.off{color:var(--muted)}.tile .v.off::before{box-shadow:none}
.steps{display:flex;flex-direction:column;gap:14px;margin:0;padding:0;list-style:none}
.steps li{display:flex;gap:12px;align-items:flex-start;font-size:15px;font-weight:500;line-height:1.4}
.steps .n{flex:none;width:26px;height:26px;border-radius:50%;background:#6C63FF2E;color:#A5A0FF;display:flex;align-items:center;justify-content:center;font-size:13px;font-weight:700}
code{font:600 12.5px ui-monospace,SFMono-Regular,Menlo,monospace;background:#ffffff0f;border:1px solid var(--border);padding:1px 6px;border-radius:6px;word-break:break-all}
pre{margin:0;font:12.5px/1.5 ui-monospace,SFMono-Regular,Menlo,monospace;background:var(--bg);border:1px solid var(--border);border-radius:12px;padding:12px;white-space:pre-wrap;word-break:break-word;color:#FFC9CA}
.card p{margin:0;color:#C9CBD8;line-height:1.5}
.small{font-size:13px;color:var(--muted)}
a{color:#A5A0FF}
@media (prefers-reduced-motion:reduce){.btn{transition:none}}
`;

export interface PageOptions {
    title: string;
    /** Right side of the header (e.g. a status pill). */
    headerRight?: string;
    body: string;
    /** Inline script, sent with a CSP nonce. */
    script?: string;
}

export function header(right = ""): string {
    return `<header class="head">${LOGO_SVG(40)}<div class="t"><b>Void Hub RPC</b><span>Discord Rich Presence</span></div>${right}</header>`;
}

export function toast(tone: Tone, html: string): string {
    const ic = tone === "ok" ? icon("check", 14, 3) : tone === "error" ? icon("alert", 14, 2.5) : icon("info", 14, 2.5);
    return `<div class="toast ${tone}" role="status"><span class="dot">${ic}</span><div>${html}</div></div>`;
}

export function renderPage(opts: PageOptions, nonce = ""): string {
    const script = opts.script ? `<script nonce="${nonce}">${opts.script}</script>` : "";
    return `<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover"><meta name="color-scheme" content="dark"><meta name="theme-color" content="#0A0B10"><title>${escapeHtml(opts.title)} · Void Hub RPC</title><link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin><link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap"><style>${STYLES}</style></head><body><main class="wrap">${header(opts.headerRight ?? "")}${opts.body}</main>${script}</body></html>`;
}

export function sendPage(res: ServerResponse, status: number, opts: PageOptions): void {
    const nonce = crypto.randomBytes(16).toString("base64");
    res.writeHead(status, {
        "Content-Type": "text/html; charset=utf-8",
        "Cache-Control": "no-store",
        "Referrer-Policy": "no-referrer",
        "X-Frame-Options": "DENY",
        "X-Content-Type-Options": "nosniff",
        "Content-Security-Policy": `default-src 'none'; style-src 'unsafe-inline' https://fonts.googleapis.com; font-src https://fonts.gstatic.com; img-src https: data:; script-src 'nonce-${nonce}'; form-action 'self' https://discord.com; base-uri 'none'; frame-ancestors 'none'`,
    });
    res.end(renderPage(opts, nonce));
}

export interface MessageExtras {
    /** Short code shown in a red chip, e.g. Discord's error code. */
    code?: string;
    /** Numbered "How to fix" steps (HTML allowed). */
    steps?: string[];
    /** Extra HTML in a card under the hero (e.g. a <pre> with the raw error). */
    detail?: string;
    /** Where the button goes (default: back to /auth/discord). */
    href?: string;
}

/** Full-screen message: icon badge, big title, explanation, optional steps, one button. */
export function sendMessage(res: ServerResponse, status: number, tone: Tone, title: string, html: string, buttonLabel = "Back to Void Hub RPC", extras: MessageExtras = {}): void {
    const badgeIcon = tone === "error" ? "alert" : tone === "ok" ? "check" : "info";
    const steps = extras.steps?.length
        ? `<section class="card"><div class="caps">How to fix</div><ol class="steps">${extras.steps.map((s, i) => `<li><span class="n">${i + 1}</span><span>${s}</span></li>`).join("")}</ol></section>`
        : "";
    const detail = extras.detail ? `<section class="card">${extras.detail}</section>` : "";
    sendPage(res, status, {
        title,
        body: `<section class="hero"><div class="badge ${tone}">${icon(badgeIcon, 28)}</div><h1>${escapeHtml(title)}</h1><div class="lead">${html}</div>${extras.code ? `<span class="chip">Discord said: ${escapeHtml(extras.code)}</span>` : ""}</section>${steps}${detail}<a class="btn primary" href="${escapeHtml(extras.href ?? "/auth/discord")}">${icon("arrow")}${escapeHtml(buttonLabel)}</a>`,
    });
}

/** Kept for older callers. */
export function sendHtml(res: ServerResponse, status: number, title: string, bodyHtml: string): void {
    sendMessage(res, status, status >= 400 ? "error" : "info", title, bodyHtml);
}
