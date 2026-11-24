import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import {
    formatDiscordPresenceStatusForTool,
    setDiscordPresenceEnabled,
} from "../../../discord/presence.js";

export default function register(server: McpServer): void {
    server.registerTool("discord-rpc", {
        title: "Control Discord Rich Presence",
        description:
            "Controls the server's Discord Rich Presence integration, which shows the active connected Roblox client (game, username, connection time) as the user's Discord activity. Actions: 'enable' starts or re-starts presence updates (optionally switching the Discord application via clientId), 'disable' clears the activity and stops updates, 'status' reports the current state. Requires the Discord desktop app running on the machine running this server, and a Discord application ID (set DISCORD_RPC_CLIENT_ID or pass clientId — create one at https://discord.com/developers/applications).",
        inputSchema: z.object({
            action: z
                .enum(["enable", "disable", "status"])
                .describe("What to do with Discord Rich Presence. Default 'status'.")
                .optional()
                .default("status"),
            clientId: z
                .string()
                .regex(/^\d{5,25}$/)
                .describe(
                    "Discord application ID to use for the presence. Optional — defaults to DISCORD_RPC_CLIENT_ID.",
                )
                .optional(),
        }),
    }, async ({ action, clientId }) => {
        if (action === "enable") {
            await setDiscordPresenceEnabled(true, clientId);
        }
        else if (action === "disable") {
            await setDiscordPresenceEnabled(false);
        }
        return {
            content: [
                {
                    type: "text" as const,
                    text: formatDiscordPresenceStatusForTool(),
                },
            ],
        };
    });
}
