import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/streamableHttp.js";
/** Create a fresh McpServer with all tools registered. */
export declare function createMcpServer(): McpServer;
interface McpSession {
    transport: StreamableHTTPServerTransport;
    server: McpServer;
    createdAt: number;
    lastUsed: number;
}
/**
 * Create a new MCP session: a fresh transport + server pair.
 *
 * The SDK's StreamableHTTPServerTransport only supports one session at a
 * time (single `_initialized` flag + single `sessionId`).  To allow
 * multiple AI clients to connect simultaneously we must create a new
 * transport/server pair per session.
 */
export declare function createSession(): McpSession;
/** Look up an existing session by ID and update its last-used timestamp. */
export declare function getSession(sessionId: string): McpSession | undefined;
/** Gracefully close and remove a session. */
export declare function deleteSession(sessionId: string): boolean;
/** Number of active sessions. */
export declare function activeSessionCount(): number;
export {};
