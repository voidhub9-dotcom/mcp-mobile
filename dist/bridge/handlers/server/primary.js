import { createServer } from "http";
import { WebSocketServer } from "ws";
import { WS_PORT, MCP_AUTH_TOKEN, HTTP_MODE } from "../../../config.js";
import { dispatchHttp, dispatchWs, loadRoutes } from "../../../http/router.js";
import { getMcpTransport } from "../../mcp-transport.js";
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
    // Protect /api/* and specific bridge routes; dashboard assets stay public
    if (!PROTECTED_ROUTES.has(pathname) && !pathname.startsWith("/api/"))
        return true;
    const auth = req.headers["authorization"];
    if (auth === `Bearer ${MCP_AUTH_TOKEN}`)
        return true;
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
            if (HTTP_MODE && req.url === "/mcp") {
                const transport = getMcpTransport();
                if (transport) {
                    if (!checkAuth(req, res))
                        return;
                    void transport.handleRequest(req, res);
                    return;
                }
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
