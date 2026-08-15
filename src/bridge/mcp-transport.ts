import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StreamableHTTPServerTransport, } from "@modelcontextprotocol/sdk/server/streamableHttp.js";
import crypto from "crypto";
import { SERVER_NAME } from "../config.js";
import { registerAllTools } from "../tools/index.js";
const SERVER_INFO = {
    name: SERVER_NAME,
    version: "2.0.0" as const,
    description: "Expose MCP tools for inspecting, executing Luau in, and interacting with connected Roblox game clients. Dashboard: http://localhost:16384/.",
};
const SERVER_OPTIONS = {
    instructions: [
        "Roblox executor MCP server. Recommended workflow to keep results small and accurate:",
        "1. Call get-game-info first to understand what game the client is in, who the local player is, and the game state.",
        "2. If multiple clients may be connected, call list-clients then set-active-client before anything else.",
        "3. Explore structure cheaply first: get-descendants-tree (summaryOnly) or search-instances with a tight selector and low limit; widen only when needed.",
        "4. Find code with script-grep (exact identifiers/regex) or semantic-search-scripts (behavior); then read just the relevant range with get-script-content (use startLine/endLine).",
        "5. Use get-data-by-code only for small, targeted value probes — prefer the specialized inspection tools above, and have the returned code return compact values, never whole instances or large tables.",
        "6. After execute / execute-file, verify effects with a small get-console-output (low limit) or a targeted get-data-by-code probe.",
        "7. Keep tool outputs lean: prefer summaryOnly, filters, and low limits; only raise maxOutputChars when a single result truly needs it. Large/raw outputs degrade reasoning quality.",
        "8. For remote spying, use remote-spy with operation=list first. Start with summaryOnly=true and a low limit; narrow by name before requesting call arguments or changing block/ignore state. If Cobalt is not available, the tool falls back to basic remote inventory mode.",
        "9. For mobile clients, call get-client-capabilities to check which tools are supported on the connected executor.",
        "10. When writing Luau code for execute/get-data-by-code, always use pcall() for any Roblox API call that may fail, and return compact results (not full instances). Use setthreadidentity(8) at the start of code that needs elevated permissions.",
    ].join("\n"),
};
export function createMcpServer(): McpServer {
    const server = new McpServer(SERVER_INFO, SERVER_OPTIONS);
    registerAllTools(server);
    return server;
}
interface McpSession {
    transport: StreamableHTTPServerTransport;
    server: McpServer;
    createdAt: number;
    lastUsed: number;
}
const sessions = new Map<string, McpSession>();
const SESSION_TTL_MS = 30 * 60 * 1000;
export function createSession(): McpSession {
    const transport = new StreamableHTTPServerTransport({
        sessionIdGenerator: () => crypto.randomUUID(),
        enableJsonResponse: true,
        keepAliveMs: 5000,
        onsessioninitialized: (sessionId: string) => {
            session.createdAt = Date.now();
            sessions.set(sessionId, session);
            cleanupStaleSessions();
            console.error(`[MCP] Session ${sessionId} created. Active sessions: ${sessions.size}`);
        },
    });
    const server = createMcpServer();
    const session: McpSession = {
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
export function getSession(sessionId: string): McpSession | undefined {
    const session = sessions.get(sessionId);
    if (session) {
        session.lastUsed = Date.now();
    }
    return session;
}
export function deleteSession(sessionId: string): boolean {
    const session = sessions.get(sessionId);
    if (!session)
        return false;
    session.transport.close();
    sessions.delete(sessionId);
    console.error(`[MCP] Session ${sessionId} deleted. Active: ${sessions.size}`);
    return true;
}
export function activeSessionCount(): number {
    return sessions.size;
}
function cleanupStaleSessions(): void {
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
