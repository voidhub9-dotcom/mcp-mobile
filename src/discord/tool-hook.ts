import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { DEFAULT_DISCORD_USER_KEY } from "./config.js";
import { getActiveClientId, getActiveClients, resolveTargetClient } from "../bridge/handlers/shared/registry.js";
import { clearUserPresence, getPresenceStatus, presenceEnabled, toolUsedWithin, updateGamePresence, updateUserPresence, type PresenceGame } from "./discordPresence.js";

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

/** The game the active Roblox client is in, or null (no client, Termux shell, unknown place). */
export function currentGame(): PresenceGame | null {
    try {
        // Prefer the active client; skip non-game clients (e.g. the Termux shell, placeId 0).
        let client = resolveTargetClient(getActiveClientId());
        if (!client || !(client.placeId > 0))
            client = getActiveClients().filter((c) => c.placeId > 0).sort((a, b) => b.lastRegistrationAt - a.lastRegistrationAt)[0] ?? null;
        if (!client)
            return null;
        return { placeId: client.placeId, placeName: client.placeName || "Roblox" };
    }
    catch {
        return null;
    }
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
                    updateUserPresence(DEFAULT_DISCORD_USER_KEY, actionForTool(name), currentGame());
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

// ---- Game watcher ------------------------------------------------------------------
// Starts the Discord presence as soon as a Roblox client connects (no tool call
// needed), keeps it alive while the game stays connected, and clears it when the
// game goes away.

const GAME_WATCH_INTERVAL_MS = 5_000;
let watcher: NodeJS.Timeout | null = null;
let lastPlaceId: number | null = null;

export function checkGamePresence(): void {
    try {
        if (!presenceEnabled())
            return;
        const game = currentGame();
        if (game) {
            if (game.placeId !== lastPlaceId)
                console.error(`[Discord] Game connected: ${game.placeName} (${game.placeId}); updating presence.`);
            lastPlaceId = game.placeId;
            updateGamePresence(DEFAULT_DISCORD_USER_KEY, game);
            return;
        }
        if (lastPlaceId !== null) {
            lastPlaceId = null;
            // Left the game. Keep it only if the AI is still actively using tools.
            if (getPresenceStatus(DEFAULT_DISCORD_USER_KEY).active && !toolUsedWithin(DEFAULT_DISCORD_USER_KEY, 60_000)) {
                console.error("[Discord] Game disconnected; clearing presence.");
                void clearUserPresence(DEFAULT_DISCORD_USER_KEY);
            }
        }
    }
    catch (err) {
        console.error("[Discord] Game watcher error:", (err as Error).message);
    }
}

export function startGamePresenceWatcher(): void {
    if (watcher || !presenceEnabled())
        return;
    watcher = setInterval(checkGamePresence, GAME_WATCH_INTERVAL_MS);
    watcher.unref?.();
    console.error("[Discord] Watching for Roblox games to show VoidHub RPC automatically.");
}
