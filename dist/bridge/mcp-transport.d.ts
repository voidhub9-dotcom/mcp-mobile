import type { StreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/streamableHttp.js";
export declare function setMcpTransport(t: StreamableHTTPServerTransport | null): void;
export declare function getMcpTransport(): StreamableHTTPServerTransport | null;
