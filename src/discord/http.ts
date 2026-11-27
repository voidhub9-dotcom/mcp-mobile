import crypto from "node:crypto";
import type { IncomingMessage, ServerResponse } from "http";
import { MCP_AUTH_TOKEN } from "../config.js";

// Shared helpers for the /auth/discord routes.
//
// The server only has a single shared MCP_AUTH_TOKEN, so linking/unlinking is
// gated by that token when it is set (otherwise anyone who finds the Railway
// URL could replace the linked Discord account). Without MCP_AUTH_TOKEN the
// routes are open, matching how the rest of the server behaves locally.

export function authRequired(): boolean {
    return Boolean(MCP_AUTH_TOKEN);
}

export function serverTokenMatches(provided: string | null | undefined): boolean {
    if (!MCP_AUTH_TOKEN)
        return true;
    if (!provided)
        return false;
    const a = crypto.createHash("sha256").update(provided).digest();
    const b = crypto.createHash("sha256").update(MCP_AUTH_TOKEN).digest();
    return crypto.timingSafeEqual(a, b);
}

export function bearerToken(req: IncomingMessage): string | null {
    const header = req.headers.authorization || "";
    const match = /^Bearer\s+(.+)$/i.exec(header);
    return match ? match[1].trim() : null;
}

export function escapeHtml(value: string): string {
    return value.replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c] as string);
}

export function sendHtml(res: ServerResponse, status: number, title: string, bodyHtml: string): void {
    res.writeHead(status, {
        "Content-Type": "text/html; charset=utf-8",
        "Cache-Control": "no-store",
        "Referrer-Policy": "no-referrer",
        "X-Frame-Options": "DENY",
    });
    res.end(`<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>${escapeHtml(title)}</title></head><body style="font-family:system-ui;max-width:40rem;margin:3rem auto;padding:0 1rem;line-height:1.5"><h1>${escapeHtml(title)}</h1>${bodyHtml}</body></html>`);
}

export function sendJson(res: ServerResponse, status: number, value: unknown): void {
    res.writeHead(status, { "Content-Type": "application/json", "Cache-Control": "no-store" });
    res.end(JSON.stringify(value));
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
