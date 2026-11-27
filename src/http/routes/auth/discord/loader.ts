import type { IncomingMessage, ServerResponse } from "http";
import { MCP_AUTH_TOKEN } from "../../../../config.js";
import { authRequired, authorize, sendJson } from "../../../../discord/http.js";

// GET /auth/discord/loader
// The ready-to-paste Roblox loader for this server, with the real MCP_AUTH_TOKEN
// filled in. Only for signed-in browsers (the remembered-device cookie) or a
// Bearer token, because the token lets whoever has it run code in the client.

function publicBase(req: IncomingMessage): string {
    const proto = String(req.headers["x-forwarded-proto"] || "").split(",")[0].trim()
        || ((req.socket as { encrypted?: boolean }).encrypted ? "https" : "http");
    const host = String(req.headers["x-forwarded-host"] || req.headers.host || "localhost").split(",")[0].trim();
    return `${proto}://${host}`;
}

export async function GET(req: IncomingMessage, res: ServerResponse): Promise<void> {
    if (!authorize(req, res)) {
        sendJson(res, 401, { error: "sign_in_required", signIn: "/auth/discord?next=/" });
        return;
    }
    const base = publicBase(req);
    const lines = [`getgenv().BridgeURL = "${base}"`];
    if (authRequired() && MCP_AUTH_TOKEN)
        lines.push(`getgenv().MCP_AUTH_TOKEN = ${JSON.stringify(MCP_AUTH_TOKEN)}`);
    lines.push(`loadstring(game:HttpGet("${base}/mobile-connector.luau"))()`);
    sendJson(res, 200, { snippet: lines.join("\n"), hasToken: authRequired() });
}
