import { z } from "zod";
import { toolTextResponse } from "../../factory.js";
import { scratchpadWrite, scratchpadRead } from "../../../scratchpad/store.js";
export default function register(server) {
    server.registerTool("scratchpad-write", {
        title: "Write Scratchpad Entry",
        description: "Write or overwrite a named scratchpad entry. Mobile Roblox clients can also write entries via POST /api/scratchpad. Use this to store notes, script output, or state for later retrieval.",
        inputSchema: z.object({
            key: z.string().describe("The scratchpad key. Allowed chars: word chars, hyphens, dots, colons, @ and /."),
            value: z.string().describe("The value to store (up to 64 KB)."),
        }),
    }, ({ key, value }) => {
        const result = scratchpadWrite(key, value, "mcp");
        if (!result.ok) {
            return toolTextResponse(`Failed to write scratchpad: ${result.error}`, {}, true);
        }
        const entry = scratchpadRead(key);
        return toolTextResponse(`Scratchpad entry written.\nkey: ${entry.key}\nbytes: ${Buffer.byteLength(entry.value, "utf8")}\nupdated: ${new Date(entry.updatedAt).toISOString()}`);
    });
}
