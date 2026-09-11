import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import { toolTextResponse } from "../../factory.js";
import { scratchpadList } from "../../../scratchpad/store.js";

export default function register(server: McpServer): void {
    server.registerTool("scratchpad-list", {
        title: "List Scratchpad Entries",
        description: "List all scratchpad entries currently stored on the MCP server. Shows key, source, size, and timestamps. Entries are sorted newest-first.",
        inputSchema: z.object({}),
    }, () => {
        const entries = scratchpadList();
        if (entries.length === 0) {
            return toolTextResponse("Scratchpad is empty.");
        }
        const lines = entries.map((e) => {
            const bytes = Buffer.byteLength(e.value, "utf8");
            const age = Math.round((Date.now() - e.updatedAt) / 1000);
            return `${e.key}  [${bytes}B, source=${e.source}, ${age}s ago]`;
        });
        return toolTextResponse(`${entries.length} entry(ies):\n${lines.join("\n")}`);
    });
}
