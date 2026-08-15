import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import { sendAndWait } from "../../factory.js";
import { maxOutputCharsSchema } from "../../schemas.js";
export default function register(server: McpServer): void {
    server.registerTool("client-screenshot", {
        title: "Take a screenshot from the Roblox client (cross-platform)",
        description: "Capture a screenshot from the connected Roblox client itself, using in-game viewport capture. Works on any platform (Windows, Mac, mobile) — unlike screenshot-window which requires Windows OS-level capture. The client executor must support a screenshot function (screenshot, takescreenshot) or the http_get screenshot:// protocol. Returns a base64 image.",
        inputSchema: z.object({
            maxWidth: z
                .number()
                .describe("Maximum image width in pixels (default: 1280). Lower values cost fewer vision tokens.")
                .optional()
                .default(1280),
            quality: z
                .number()
                .describe("JPEG/PNG quality percentage (default: 80, range 20-100).")
                .optional()
                .default(80),
            maxOutputChars: maxOutputCharsSchema,
        }),
    }, async ({ maxWidth, quality, maxOutputChars }) => sendAndWait({
        type: "client-screenshot",
        data: { maxWidth, quality },
        maxOutputChars,
        stampClient: true,
        failureMessage: () => "Failed to capture client screenshot. The connected executor may not support in-game screenshot capture.",
    }));
}
