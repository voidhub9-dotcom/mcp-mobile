import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { DEFAULT_DISCORD_USER_KEY } from "./config.js";
import { updateUserPresence } from "./discordPresence.js";

// Maps MCP tool names to the "details" line shown on Discord.
const ACTION_BY_TOOL: Record<string, string> = {
    "execute": "Making a script",
    "execute-file": "Making a script",
    "get-data-by-code": "Testing a script",
    "get-ai-script-context": "Making a script",
    "get-script-content": "Reading game scripts",
    "script-grep": "Searching game scripts",
    "semantic-search-scripts": "Searching game scripts",
    "remote-spy": "Spying on remotes",
    "decrypt-remote": "Reverse engineering remotes",
    "scan-anticheat": "Scanning for anti-cheat",
    "anticheat-bypass": "Researching anti-cheat",
    "client-screenshot": "Taking a screenshot",
    "screenshot-window": "Taking a screenshot",
    "server-hop": "Hopping servers",
    "research-game": "Researching a game",
    "trace-game-activity": "Tracing game activity",
    "find-game-systems": "Mapping game systems",
    "click-button": "Automating the game UI",
    "type-text-box": "Automating the game UI",
};

export function actionForTool(toolName: string): string {
    return ACTION_BY_TOOL[toolName] ?? `Running ${toolName}`;
}

/**
 * Wrap `server.registerTool` so every tool handler first fires a presence
 * update. Must run before tools are registered. The hook is synchronous and
 * swallows all errors, so tool execution is never delayed or failed by Discord.
 */
export function installPresenceToolHook(server: McpServer): void {
    const original = server.registerTool.bind(server) as (...args: unknown[]) => unknown;
    (server as unknown as { registerTool: (...args: unknown[]) => unknown }).registerTool = (...args: unknown[]) => {
        const name = args[0];
        const cbIndex = args.length - 1;
        const cb = args[cbIndex];
        if (typeof name === "string" && typeof cb === "function") {
            args[cbIndex] = function (this: unknown, ...cbArgs: unknown[]) {
                try {
                    updateUserPresence(DEFAULT_DISCORD_USER_KEY, actionForTool(name));
                }
                catch {
                    // never let presence affect the tool
                }
                return (cb as (...a: unknown[]) => unknown).apply(this, cbArgs);
            };
        }
        return original(...args);
    };
}
