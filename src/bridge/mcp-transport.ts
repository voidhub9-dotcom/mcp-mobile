import type { StreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/streamableHttp.js";

let transport: StreamableHTTPServerTransport | null = null;

export function setMcpTransport(t: StreamableHTTPServerTransport | null): void {
  transport = t;
}

export function getMcpTransport(): StreamableHTTPServerTransport | null {
  return transport;
}
