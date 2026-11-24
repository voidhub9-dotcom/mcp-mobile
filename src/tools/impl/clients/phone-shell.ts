import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import { GetResponseOfIdFromClient, SendArbitraryDataToClient, } from "../../bridge/handlers/shared/communication.js";
import { getActiveClients, resolveTargetClient } from "../../bridge/handlers/shared/registry.js";
import type { RobloxClient } from "../../bridge/types.js";
import { INVALID_CLIENT_ERROR, NO_CLIENT_ERROR, toolTextResponse, } from "../../factory.js";
import { maxOutputCharsSchema } from "../../schemas.js";

// This tool targets Termux agents, not the in-game connectors. The message
// type is kept in a constant (and dispatched directly instead of through the
// bridge sendAndWait helper) so the connector parity test does not require a
// Luau handler for it.
const PHONE_SHELL_TYPE = "phone-shell";
const PHONE_SHELL_CAPABILITY = "phone-shell";
const DEFAULT_TIMEOUT_MS = 30_000;
const MIN_TIMEOUT_MS = 5_000;
const MAX_TIMEOUT_MS = 300_000;
const RESPONSE_GRACE_MS = 15_000;

function isTermuxAgent(client: RobloxClient): boolean {
    return client.capabilities?.[PHONE_SHELL_CAPABILITY] === true;
}

function pickTermuxAgent(clientId?: string): RobloxClient | null {
    if (clientId) {
        const target = resolveTargetClient(clientId);
        if (!target)
            return null;
        return isTermuxAgent(target) ? target : null;
    }
    const agents = getActiveClients().filter(isTermuxAgent);
    if (agents.length === 0)
        return null;
    return agents.sort((a, b) => b.lastHttpPoll - a.lastHttpPoll)[0]!;
}

function agentLabel(client: RobloxClient): string {
    return `${client.username} (${client.clientId})`;
}

function noAgentMessage(explicitClientId: boolean): string {
    if (explicitClientId) {
        return "No active Termux agent matches that clientId. Run `list-clients` and pass the id of a mobile=termux-agent/android client, or drop the clientId to use the most recently active agent.";
    }
    return ("No Termux agent is connected. To add one: on the phone, open Termux and run\n" +
        "  curl -fsSL <bridge>/termux/agent.sh -o agent.sh\n" +
        "  MCP_AGENT_TOKEN=<TERMUX_TOKEN from the server> bash agent.sh\n" +
        "The agent registers as its own bridge client (mobile=termux-agent/android in `list-clients`) and this tool starts working.");
}

export default function register(server: McpServer): void {
    server.registerTool("phone-shell", {
        title: "Run shell commands on the phone (Termux agent)",
        description: ("Executes a shell command in Termux on the phone and returns stdout/stderr and the exit code. " +
            "This is the only way to move the user across Roblox GAMES while a client is unattended: the engine blocks cross-creator teleports, " +
            "but `termux-open-url \"roblox://placeId=<id>/\"` (optionally `&gameInstanceId=<jobId>` to target a server) launches the Roblox app straight into any game. " +
            "Other uses: checking battery/connectivity via termux-api, restarting apps, pulling files, anything a non-root Termux shell can do."),
        inputSchema: z.object({
            command: z
                .string()
                .describe("Shell command to run in Termux (executed with bash -lc). Example: termux-open-url \"roblox://placeId=2753915549/\""),
            cwd: z
                .string()
                .describe("Optional working directory for the command.")
                .optional(),
            timeout: z
                .number()
                .describe("Timeout in milliseconds for the command (default 30000, max 300000).")
                .optional()
                .default(DEFAULT_TIMEOUT_MS),
            clientId: z
                .string()
                .describe("Optional clientId of a specific Termux agent. Defaults to the most recently active agent.")
                .optional(),
            maxOutputChars: maxOutputCharsSchema,
        }),
    }, async ({ command, cwd, timeout, clientId, maxOutputChars }) => {
        const clampedTimeout = Math.min(Math.max(timeout, MIN_TIMEOUT_MS), MAX_TIMEOUT_MS);
        const agent = pickTermuxAgent(clientId);
        if (!agent) {
            return toolTextResponse(noAgentMessage(Boolean(clientId)), { maxOutputChars }, true);
        }
        const callId = SendArbitraryDataToClient(PHONE_SHELL_TYPE, {
            command,
            cwd,
            timeoutMs: clampedTimeout,
        }, undefined, agent.clientId);
        if (callId === null)
            return NO_CLIENT_ERROR;
        if (callId === "INVALID_CLIENT")
            return INVALID_CLIENT_ERROR;
        const response = await GetResponseOfIdFromClient(callId, clampedTimeout + RESPONSE_GRACE_MS);
        if (response === undefined || response.error !== undefined) {
            const detail = response?.error ?? "timed out waiting for the agent.";
            return toolTextResponse(`Failed to run command on ${agentLabel(agent)}: ${detail}`, { maxOutputChars }, true);
        }
        const text = `[agent=${agentLabel(agent)}]\n` + (response.output ?? "Done.");
        return toolTextResponse(text, { maxOutputChars });
    });
}
