import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { InMemoryTransport } from "@modelcontextprotocol/sdk/inMemory.js";
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { registerAllTools } from "../tools/index.js";

let client: Client | null = null;
let connected = false;

/**
 * Create a dedicated internal McpServer for DeepSeek agent use,
 * then link an in-memory MCP client to it.
 *
 * We create a SEPARATE server (not the public HTTP/stdio one) because
 * an McpServer should only be connected to one transport at a time.
 * Both servers register the same tools, so the DeepSeek agent has
 * access to the full tool set in-process.
 */
export async function initMcpClient(): Promise<Client> {
  if (client && connected) return client;

  const internalServer = new McpServer(
    { name: "roblox-mcp-internal", version: "2.0.0" },
    {
      instructions:
        "Internal MCP server for DeepSeek agent. Provides the same tools as the main server.",
    }
  );

  // Register all tools on the internal server
  registerAllTools(internalServer);

  // Create linked in-memory transport pair
  const [clientTransport, serverTransport] = InMemoryTransport.createLinkedPair();

  client = new Client(
    { name: "deepseek-agent", version: "1.0.0" },
    { capabilities: {} }
  );

  // Connect server to one end, client to the other
  await internalServer.connect(serverTransport);
  await client.connect(clientTransport);
  connected = true;

  console.error("[DeepSeek] In-memory MCP client connected to internal server.");
  return client;
}

export function getMcpClient(): Client | null {
  return connected ? client : null;
}
