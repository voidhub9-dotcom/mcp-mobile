import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import { sendAndWait } from "../../factory.js";
import { maxOutputCharsSchema } from "../../schemas.js";

export default function register(server: McpServer): void {
    server.registerTool("anti-afk", {
        title: "Control anti-AFK protection",
        description: "Controls the connector's anti-AFK protection, which prevents idle disconnections by answering the local Player.Idled event with VirtualUser input. Actions: 'enable' connects (or re-connects) the Idled handler, 'disable' disconnects it so idle kicks are no longer blocked, 'status' reports whether anti-AFK is currently active. Anti-AFK is enabled by default when the connector loads unless getgenv().MCP_DisableAntiAFK is set.",
        inputSchema: z.object({
            action: z
                .enum(["enable", "disable", "status"])
                .describe("What to do with anti-AFK protection. Default 'status'.")
                .optional()
                .default("status"),
            maxOutputChars: maxOutputCharsSchema,
        }),
    }, async ({ action, maxOutputChars }) => sendAndWait({
        type: "anti-afk",
        data: { action },
        maxOutputChars,
        stampClient: true,
        failureMessage: () => "Failed to control anti-AFK.",
    }));
}
