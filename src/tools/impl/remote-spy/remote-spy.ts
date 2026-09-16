import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import { describeResponse, sendAndWait } from "../../factory.js";
import { maxOutputCharsSchema } from "../../schemas.js";
const inputSchema = z.discriminatedUnion("operation", [
    z.object({
        operation: z.literal("list"),
        direction: z
            .enum(["Incoming", "Outgoing", "Both"])
            .describe("Call direction to inspect (default: Both)")
            .optional()
            .default("Both"),
        nameFilter: z
            .string()
            .describe("Case-insensitive substring filter for remote names")
            .optional(),
        limit: z
            .number()
            .describe("Maximum remote entries to return (default: 5, max: 100)")
            .optional()
            .default(5),
        maxCallsPerRemote: z
            .number()
            .describe("Recent calls to include per remote when summaryOnly is false (default: 1, max: 20)")
            .optional()
            .default(1),
        summaryOnly: z
            .boolean()
            .describe("Return names, state, and call counts without argument payloads (default: true)")
            .optional()
            .default(true),
        maxOutputChars: maxOutputCharsSchema,
    }),
    z.object({ operation: z.literal("clear") }),
    z.object({ operation: z.literal("status") }),
    z.object({
        operation: z.literal("inject"),
        source: z
            .string()
            .describe(
                "Luau source code of a remote spy script to inject and execute. " +
                "The script runs in thread identity 8 and may set getgenv().MCP_CustomRemoteSpy " +
                "= { type, getLogs, clear, status } for full MCP integration. " +
                "Compatible with Hydroxide (sets getgenv().Hydroxide) and generic spies " +
                "that write to getgenv().RemoteSpy or getgenv().RS."
            ),
        maxOutputChars: maxOutputCharsSchema,
    }),
]);
export default function register(server: McpServer): void {
    server.registerTool("remote-spy", {
        title: "Inspect remote inventory and activity",
        description:
            "Remote spy diagnostics with multi-backend compatibility. " +
            "Use 'inject' to load a custom spy script (Hydroxide, custom hookfunction spy, etc.) — " +
            "subsequent 'list' calls read from that spy's live call log. " +
            "Without an injected spy, 'list' falls back through: getgenv().Hydroxide → " +
            "getgenv().RemoteSpy/RS → built-in read-only inventory scanner. " +
            "Never invokes, blocks, edits, or replays remotes. " +
            "Start with summaryOnly=true and a small limit, then narrow by name before requesting call arguments.",
        inputSchema,
    }, async (input) => {
        const maxOutputChars = (input.operation === "list" || input.operation === "inject")
            ? input.maxOutputChars
            : undefined;
        return sendAndWait({
            type: "remote-spy",
            data: input,
            maxOutputChars,
            stampClient: true,
            truncationHint: "Rerun remote-spy list with summaryOnly=true, a nameFilter, a lower limit, or fewer calls per remote.",
            failureMessage: (response) => "Failed to use remote spy: " + describeResponse(response),
        });
    });
}
