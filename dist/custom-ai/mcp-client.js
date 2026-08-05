import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { InMemoryTransport } from "@modelcontextprotocol/sdk/inMemory.js";
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { registerAllTools } from "../tools/index.js";
let client = null;
let connected = false;
/**
 * Create a dedicated internal McpServer for the custom AI agent,
 * then link an in-memory MCP client to it.
 *
 * We create a SEPARATE server (not the public HTTP/stdio one) because
 * an McpServer should only be connected to one transport at a time.
 */
export async function initMcpClient() {
    if (client && connected)
        return client;
    const internalServer = new McpServer({ name: "roblox-mcp-internal", version: "2.0.0" }, {
        instructions: "Internal MCP server for custom AI agent. Provides the same tools as the main server.",
    });
    registerAllTools(internalServer);
    const [clientTransport, serverTransport] = InMemoryTransport.createLinkedPair();
    client = new Client({ name: "custom-ai-agent", version: "1.0.0" }, { capabilities: {} });
    await internalServer.connect(serverTransport);
    await client.connect(clientTransport);
    connected = true;
    console.error("[Custom AI] In-memory MCP client connected to internal server.");
    return client;
}
export function getMcpClient() {
    return connected ? client : null;
}
