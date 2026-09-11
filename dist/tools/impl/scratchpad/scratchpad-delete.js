import { z } from "zod";
import { toolTextResponse } from "../../factory.js";
import { scratchpadDelete, scratchpadClear } from "../../../scratchpad/store.js";
export default function register(server) {
    server.registerTool("scratchpad-delete", {
        title: "Delete Scratchpad Entry",
        description: "Delete a specific scratchpad entry by key. Omit the key to clear all entries.",
        inputSchema: z.object({
            key: z.string().optional().describe("The scratchpad key to delete. Omit to clear every entry."),
        }),
    }, ({ key }) => {
        if (key) {
            const deleted = scratchpadDelete(key);
            return toolTextResponse(deleted ? `Deleted scratchpad entry: ${key}` : `No entry found for key: ${key}`, {}, !deleted);
        }
        const cleared = scratchpadClear();
        return toolTextResponse(`Cleared all ${cleared} scratchpad entry(ies).`);
    });
}
