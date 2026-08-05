import { Client } from "@modelcontextprotocol/sdk/client/index.js";
/**
 * Create a dedicated internal McpServer for DeepSeek agent use,
 * then link an in-memory MCP client to it.
 *
 * We create a SEPARATE server (not the public HTTP/stdio one) because
 * an McpServer should only be connected to one transport at a time.
 * Both servers register the same tools, so the DeepSeek agent has
 * access to the full tool set in-process.
 */
export declare function initMcpClient(): Promise<Client>;
export declare function getMcpClient(): Client | null;
