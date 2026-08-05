import { createServer } from "http";
import { WebSocketServer } from "ws";
import { WS_PORT, MCP_AUTH_TOKEN, HTTP_MODE } from "../../../config.js";
import { dispatchHttp, dispatchWs, loadRoutes } from "../../../http/router.js";
import { createSession, getSession, deleteSession } from "../../mcp-transport.js";
import { resetPrimaryState, setInstanceRole, } from "../shared/communication.js";
import { resetRegistry } from "../shared/registry.js";
// Routes that require auth when MCP_AUTH_TOKEN is set.
// Dashboard HTML, CSS, JS, SVG, and script loaders stay public.
const PROTECTED_ROUTES = new Set([
    "/mcp",
    "/register",
    "/poll",
    "/respond",
    "/decompile",
    "/decompile-plan",
    "/decompiler-observations",
    "/mcp-relay",
    "/script-source-cache",
    "/script-sources",
]);
function checkAuth(req, res) {
    if (!MCP_AUTH_TOKEN)
        return true; // auth disabled
    const pathname = req.url?.split("?")[0] || "";
    // /api/admin-session is exempt: it has its own localhost origin check.
    // This lets the dashboard bootstrap even when MCP_AUTH_TOKEN is set.
    if (pathname === "/api/admin-session")
        return true;
    // Protect /api/* and specific bridge routes; dashboard assets stay public
    if (!PROTECTED_ROUTES.has(pathname) && !pathname.startsWith("/api/"))
        return true;
    // Accept Bearer token (MCP_AUTH_TOKEN)
    const auth = req.headers["authorization"];
    if (auth === `Bearer ${MCP_AUTH_TOKEN}`)
        return true;
    // Accept local admin token (for dashboard access from same machine)
    const adminToken = req.headers["x-roblox-mcp-admin-token"];
    if (typeof adminToken === "string" && adminToken.length > 0) {
        // The local-admin module already validates origin + loopback;
        // if the header is present, trust the requiresLocalAdminRequest check
        // that the router applies separately for sensitive admin routes.
        return true;
    }
    res.writeHead(401, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ error: "Unauthorized" }));
    return false;
}
export async function startAsPrimary() {
    await loadRoutes();
    return new Promise((resolve, reject) => {
        setInstanceRole("primary");
        resetRegistry();
        resetPrimaryState();
        const httpServer = createServer((req, res) => {
            // CORS for remote/cloud access
            res.setHeader("Access-Control-Allow-Origin", "*");
            res.setHeader("Access-Control-Allow-Methods", "GET, POST, DELETE, OPTIONS");
            res.setHeader("Access-Control-Allow-Headers", "Content-Type, Accept, Authorization, Mcp-Session-Id");
            if (req.method === "OPTIONS") {
                res.writeHead(204);
                res.end();
                return;
            }
            // MCP Streamable HTTP endpoint (when --http mode is active)
            if (HTTP_MODE && req.url?.split("?")[0] === "/mcp") {
                if (!checkAuth(req, res))
                    return;
                const sessionId = req.headers["mcp-session-id"];
                // DELETE → close session
                if (req.method === "DELETE") {
                    if (sessionId && deleteSession(sessionId)) {
                        res.writeHead(200);
                        res.end();
                    }
                    else {
                        res.writeHead(404, { "Content-Type": "application/json" });
                        res.end(JSON.stringify({ jsonrpc: "2.0", error: { code: -32001, message: "Session not found" }, id: null }));
                    }
                    return;
                }
                // Existing session → delegate to that session's transport
                if (sessionId) {
                    const session = getSession(sessionId);
                    if (session) {
                        void session.transport.handleRequest(req, res);
                    }
                    else {
                        res.writeHead(404, { "Content-Type": "application/json" });
                        res.end(JSON.stringify({ jsonrpc: "2.0", error: { code: -32001, message: "Session not found" }, id: null }));
                    }
                    return;
                }
                // No session ID → create a new session for this request.
                // The transport itself will validate that this is an initialize request;
                // non-initialize requests without a session ID get a 400 from the SDK.
                const session = createSession();
                void session.transport.handleRequest(req, res);
                return;
            }
            // Auth check for all other routes in cloud mode
            if (MCP_AUTH_TOKEN && !checkAuth(req, res))
                return;
            void dispatchHttp(req, res);
        });
        httpServer.on("error", (err) => {
            if (err.code === "EADDRINUSE") {
                reject(err);
            }
            else {
                console.error("[Primary] HTTP server error:", err);
                reject(err);
            }
        });
        httpServer.listen(WS_PORT, () => {
            console.error(`[Primary] MCP Bridge listening on port ${WS_PORT} (WebSocket + HTTP)`);
            const wss = new WebSocketServer({ server: httpServer });
            wss.on("connection", (ws, req) => dispatchWs(ws, req));
            resolve();
        });
    });
}
