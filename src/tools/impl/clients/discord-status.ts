import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import { DEFAULT_DISCORD_USER_KEY } from "../../../discord/config.js";
import { STAGE_TEXT, getPresenceStatus, setCustomStatus } from "../../../discord/discordPresence.js";
import { currentGame } from "../../../discord/tool-hook.js";
import { toolTextResponse } from "../../factory.js";

const PHASE_EMOJI: Record<string, string> = {
    exploring: "🔍",
    reading: "📜",
    building: "🛠️",
    testing: "🧪",
    fixing: "🐞",
    finished: "✅",
};

export default function register(server: McpServer): void {
    server.registerTool("discord-status", {
        title: "Set the VoidHub Discord status",
        description: "Sets the line shown under the game name on the user's Discord Rich Presence (VoidHub RPC), e.g. 'Building Pet Sim auto-farm' or 'Finished auto-farm script'. Call it at milestones: when you start building a script, start testing it, hit a bug, and when the script is finished. Keep it short (under ~60 characters) and never include secrets, tokens or personal data. The status stays for 10 minutes or until replaced; pass action='clear' to go back to automatic statuses. Does nothing visible if the user hasn't linked Discord.",
        inputSchema: z.object({
            action: z.enum(["set", "clear"]).optional().default("set").describe("'set' shows `status`; 'clear' returns to automatic statuses."),
            status: z.string().max(100).optional().describe("What you're doing, e.g. 'Building Pet Sim auto-farm'."),
            phase: z.enum(["exploring", "reading", "building", "testing", "fixing", "finished"]).optional()
                .describe("Adds a matching emoji: exploring 🔍, reading 📜, building 🛠️, testing 🧪, fixing 🐞, finished ✅."),
        }),
    }, async ({ action, status, phase }) => {
        if (action === "clear") {
            const r = setCustomStatus(DEFAULT_DISCORD_USER_KEY, null, currentGame());
            return toolTextResponse(r.ok ? "Discord status back to automatic." : `Not changed: ${r.reason}`, {}, !r.ok);
        }
        const base = (status ?? "").trim() || (phase ? STAGE_TEXT[phase].replace(/^\S+\s/, "") : "");
        if (!base)
            return toolTextResponse("Give a `status` (or at least a `phase`).", {}, true);
        const text = phase && !/^\p{Extended_Pictographic}/u.test(base) ? `${PHASE_EMOJI[phase]} ${base}` : base;
        const r = setCustomStatus(DEFAULT_DISCORD_USER_KEY, text, currentGame());
        if (!r.ok)
            return toolTextResponse(`Not shown: ${r.reason}`, {}, true);
        const linked = getPresenceStatus(DEFAULT_DISCORD_USER_KEY).active;
        return toolTextResponse(`Discord status set to "${text}"${linked ? "" : " (it shows once a Discord account is linked)"}.`);
    });
}
