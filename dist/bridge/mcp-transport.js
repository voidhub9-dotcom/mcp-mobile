import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StreamableHTTPServerTransport, } from "@modelcontextprotocol/sdk/server/streamableHttp.js";
import crypto from "crypto";
import { SERVER_NAME } from "../config.js";
import { registerAllTools } from "../tools/index.js";
const SERVER_INFO = {
    name: SERVER_NAME,
    version: "2.0.0",
    description: "Expose MCP tools for inspecting, executing Luau in, and interacting with connected Roblox game clients. Dashboard: http://localhost:16384/.",
};
const SERVER_OPTIONS = {
    instructions: [
        "Roblox executor MCP server. Recommended workflow to keep results small and accurate:",
        "1. If multiple clients may be connected, call list-clients then set-active-client before anything else.",
        "2. Explore structure cheaply first: get-descendants-tree (summaryOnly) or search-instances with a tight selector and low limit; widen only when needed.",
        "3. Find code with script-grep (exact identifiers/regex) or semantic-search-scripts (behavior); then read just the relevant range with get-script-content (use startLine/endLine).",
        "4. Use get-data-by-code only for small, targeted value probes — prefer the specialized inspection tools above, and have the returned code return compact values, never whole instances or large tables.",
        "5. After execute / execute-file, verify effects with a small get-console-output (low limit) or a targeted get-data-by-code probe.",
        "6. Keep tool outputs lean: prefer summaryOnly, filters, and low limits; only raise maxOutputChars when a single result truly needs it. Large/raw outputs degrade reasoning quality.",
        "7. For remote spying, use remote-spy with operation=list first. Start with summaryOnly=true and a low limit; narrow by name before requesting call arguments or changing block/ignore state.",
        "8. For mobile clients, call get-client-capabilities to check which tools are supported on the connected executor.",
    ].join("\n"),
};
export function createMcpServer() {
    const server = new McpServer(SERVER_INFO, SERVER_OPTIONS);
    registerAllTools(server);
    return server;
}
const sessions = new Map();
const SESSION_TTL_MS = 30 * 60 * 1000;
export function createSession() {
    const transport = new StreamableHTTPServerTransport({
        sessionIdGenerator: () => crypto.randomUUID(),
        enableJsonResponse: true,
        keepAliveMs: 5000,
        onsessioninitialized: (sessionId) => {
            session.createdAt = Date.now();
            sessions.set(sessionId, session);
            cleanupStaleSessions();
            console.error(`[MCP] Session ${sessionId} created. Active sessions: ${sessions.size}`);
        },
    });
    const server = createMcpServer();
    const session = {
        transport,
        server,
        createdAt: 0,
        lastUsed: Date.now(),
    };
    transport.onclose = () => {
        for (const [id, s] of sessions) {
            if (s === session) {
                sessions.delete(id);
                console.error(`[MCP] Session ${id} closed. Active: ${sessions.size}`);
                break;
            }
        }
    };
    server.connect(transport);
    return session;
}
export function getSession(sessionId) {
    const session = sessions.get(sessionId);
    if (session) {
        session.lastUsed = Date.now();
    }
    return session;
}
export function deleteSession(sessionId) {
    const session = sessions.get(sessionId);
    if (!session)
        return false;
    session.transport.close();
    sessions.delete(sessionId);
    console.error(`[MCP] Session ${sessionId} deleted. Active: ${sessions.size}`);
    return true;
}
export function activeSessionCount() {
    return sessions.size;
}
function cleanupStaleSessions() {
    const now = Date.now();
    for (const [id, session] of sessions) {
        if (now - session.lastUsed > SESSION_TTL_MS) {
            session.transport.close();
            sessions.delete(id);
            console.error(`[MCP] Session ${id} expired (idle). Active: ${sessions.size}`);
        }
    }
}
setInterval(cleanupStaleSessions, 5 * 60 * 1000).unref();
