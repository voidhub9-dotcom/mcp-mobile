import { z } from "zod";
import { toolTextResponse } from "../../factory.js";
import { scratchpadRead } from "../../../scratchpad/store.js";
export default function register(server) {
    server.registerTool("scratchpad-read", {
        title: "Read Scratchpad Entry",
        description: "Read a named scratchpad entry that was written by a mobile Roblox client or a previous tool call. Returns the stored value and metadata.",
        inputSchema: z.object({
            key: z.string().describe("The scratchpad key to read."),
        }),
    }, ({ key }) => {
        const entry = scratchpadRead(key);
        if (!entry) {
            return toolTextResponse(`No scratchpad entry found for key: "${key}"`, {}, true);
        }
        const age = Math.round((Date.now() - entry.updatedAt) / 1000);
        const out = [
            `key: ${entry.key}`,
            `source: ${entry.source}`,
            `updated: ${new Date(entry.updatedAt).toISOString()} (${age}s ago)`,
            `created: ${new Date(entry.createdAt).toISOString()}`,
            `---`,
            entry.value,
        ].join("\n");
        return toolTextResponse(out);
    });
}
