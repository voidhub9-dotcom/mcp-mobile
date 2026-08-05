#!/usr/bin/env node

import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { boot } from "./bridge/boot.js";
import { createMcpServer } from "./bridge/mcp-transport.js";
import { initMcpClient } from "./custom-ai/mcp-client.js";
import { installServerLogCapture } from "./http/server-logs.js";
import { registerLocalDecompilerLifetime } from "./decompiler/local-process-lifetime.js";

// Install log capture early so all console.error calls are buffered.
installServerLogCapture();
registerLocalDecompilerLifetime();

// Import config for CLI arg parsing and startup logging.
import { HTTP_MODE, MCP_AUTH_TOKEN, WS_PORT } from "./config.js";

// Validate that the McpServer factory works at boot (registers all tools).
// The actual server instances are created per-session by the session manager.
if (HTTP_MODE) {
  // Warm up the factory to catch tool registration errors early.
  createMcpServer();
}

// Custom AI integration: in-memory MCP client for tool listing/calling
// Creates a separate internal McpServer so the public server's transport is unaffected.
if (HTTP_MODE) {
  void initMcpClient().catch((err) => {
    console.error("[Custom AI] Failed to init MCP client:", err);
  });
}

if (HTTP_MODE) {
  // ── Streamable HTTP transport mode (for mobile/cloud use) ──
  // Sessions are created on-demand by the session manager (see primary.ts).
  // Each AI client gets its own transport + McpServer pair.
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
  const server = createMcpServer();
  server.connect(transport);
  console.error("MCP Server started and connected via stdio.");
}

void boot();
