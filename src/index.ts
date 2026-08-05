#!/usr/bin/env node

import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { StreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/streamableHttp.js";
import crypto from "crypto";

import { boot } from "./bridge/boot.js";
import { setMcpTransport } from "./bridge/mcp-transport.js";
import { registerAllTools } from "./tools/index.js";
import { initMcpClient } from "./custom-ai/mcp-client.js";
import { installServerLogCapture } from "./http/server-logs.js";
import { registerLocalDecompilerLifetime } from "./decompiler/local-process-lifetime.js";

// Install log capture early so all console.error calls are buffered.
installServerLogCapture();
registerLocalDecompilerLifetime();

// Import config for CLI arg parsing and startup logging.
import { SERVER_NAME, HTTP_MODE, MCP_PORT, MCP_AUTH_TOKEN, WS_PORT } from "./config.js";

const server = new McpServer(
  {
    name: SERVER_NAME,
    version: "2.0.0",
    description:
      "Expose MCP tools for inspecting, executing Luau in, and interacting with connected Roblox game clients. Dashboard: http://localhost:16384/.",
  },
  {
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
  }
);

registerAllTools(server);

// Custom AI integration: in-memory MCP client for tool listing/calling
// Creates a separate internal McpServer so the public server's transport is unaffected.
if (HTTP_MODE) {
  void initMcpClient().catch((err) => {
    console.error("[Custom AI] Failed to init MCP client:", err);
  });
}

if (HTTP_MODE) {
  // ── Streamable HTTP transport mode (for mobile/cloud use) ──
  // The MCP transport is mounted into the existing bridge HTTP server
  // (see primary.ts) so both bridge routes and /mcp share one port.
  const transport = new StreamableHTTPServerTransport({
    sessionIdGenerator: () => crypto.randomUUID(),
  });

  server.connect(transport);
  setMcpTransport(transport);

  console.error(`MCP Server started in HTTP mode.`);
  console.error(`  Bridge + MCP on port ${WS_PORT}.`);
  console.error(`  MCP endpoint: http://localhost:${WS_PORT}/mcp`);
  console.error(`  Roblox loader: http://localhost:${WS_PORT}/mobile-connector.luau`);
  if (MCP_AUTH_TOKEN) {
    console.error(`  Auth: enabled (MCP_AUTH_TOKEN set)`);
  } else {
    console.error(`  Auth: disabled (set MCP_AUTH_TOKEN env var for cloud use)`);
  }
} else {
  // ── Default stdio mode ──
  const transport = new StdioServerTransport();
  server.connect(transport);
  console.error("MCP Server started and connected via stdio.");
}

void boot();
