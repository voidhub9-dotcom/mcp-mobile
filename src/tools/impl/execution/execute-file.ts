import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import fs from "fs";
import { z } from "zod";
import { sendFireAndForget, toolTextResponse } from "../../factory.js";
import { threadContextSchema } from "../../schemas.js";
import { exportTextToPasteVoid } from "../../../shared/paste-void.js";

export default function register(server: McpServer): void {
    server.registerTool("execute-file", {
        title: "Execute a Luau file in the Roblox Game Client",
        description: "Execute a .luau or .lua script in the active Roblox client. ALWAYS pass the script as the content param — do NOT use filePath, as local file paths like /tmp/ do not exist in this environment. The script is uploaded to pastevoid.base44.app and executed on the client via loadstring(HttpGet). Use get-data-by-code when you need returned values.",
        inputSchema: z.object({
            content: z
                .string()
                .optional()
                .describe("Raw Luau/Lua script content to upload and execute. ALWAYS use this instead of filePath."),
            filePath: z
                .string()
                .optional()
                .describe("DO NOT USE — local file paths do not exist in this environment. Use content instead."),
            threadContext: threadContextSchema,
        }),
    }, async ({ filePath, content, threadContext }) => {
        let code: string;
        let source: string;

        if (content) {
            code = content;
            source = "inline content";
        } else if (filePath) {
            if (!fs.existsSync(filePath)) {
                return toolTextResponse(`File not found: ${filePath}`, {}, true);
            }
            code = fs.readFileSync(filePath, "utf-8");
            source = filePath;
        } else {
            return toolTextResponse("Provide either filePath or content.", {}, true);
        }

        const upload = await exportTextToPasteVoid(code, { language: "lua", title: "mcp-execute" });
        if (!upload.ok || !upload.url) {
            return toolTextResponse(`Failed to upload script to paste-void: ${upload.error ?? "unknown error"}`, {}, true);
        }
        const rawUrl = upload.url;

        console.error(`Uploaded script from ${source} to ${rawUrl}, executing in thread ${threadContext}...`);

        const loadstringSource = `setthreadidentity(${threadContext})\nloadstring(game:HttpGet("${rawUrl}"))()`;

        return sendFireAndForget({
            type: "execute",
            data: { source: loadstringSource },
            successMessage: `Script executed via ${rawUrl} (thread context ${threadContext})`,
        });
    });
}
