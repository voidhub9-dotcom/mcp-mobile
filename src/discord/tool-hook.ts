import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { DEFAULT_DISCORD_USER_KEY } from "./config.js";
import { getActiveClientId, getActiveClients, resolveTargetClient } from "../bridge/handlers/shared/registry.js";
import { STAGE_TEXT, clearUserPresence, getPresenceStatus, presenceEnabled, toolUsedWithin, updateGamePresence, updateUserPresence, type PresenceGame, type PresenceStage } from "./discordPresence.js";

// Maps MCP tool names to a work stage; the stage decides the "details" line on Discord.
// Tools mapped to "keep" (housekeeping) leave the current line alone.
const STAGE_BY_TOOL: Record<string, PresenceStage | "keep"> = {
    "execute": "building",
    "execute-file": "building",
    "get-data-by-code": "testing",
    "get-console-output": "testing",
    "click-button": "testing",
    "type-text-box": "testing",
    "get-ai-script-context": "reading",
    "get-script-content": "reading",
    "script-grep": "reading",
    "semantic-search-scripts": "reading",
    "remote-spy": "spying",
    "decrypt-remote": "spying",
    "scan-anticheat": "anticheat",
    "anticheat-bypass": "anticheat",
    "get-game-info": "exploring",
    "get-player-state": "exploring",
    "get-game-guis": "exploring",
    "search-instances": "exploring",
    "get-descendants-tree": "exploring",
    "find-game-systems": "exploring",
    "trace-game-activity": "exploring",
    "research-game": "exploring",
    "client-screenshot": "exploring",
    "screenshot-window": "exploring",
    "list-roblox-windows": "keep",
    "server-hop": "hopping",
    "list-clients": "keep",
    "set-active-client": "keep",
    "get-client-capabilities": "keep",
    "get-connector-health": "keep",
    "get-loadstring": "keep",
    "get-session-alerts": "keep",
    "create-diagnostic-snapshot": "keep",
    "anti-afk": "keep",
    "phone-shell": "keep",
    "discord-status": "keep",
};

export function stageForTool(toolName: string): PresenceStage | "keep" {
    return STAGE_BY_TOOL[toolName] ?? "other";
}

/** The details line a tool call shows (kept for callers/tests). */
export function actionForTool(toolName: string): string {
    const stage = stageForTool(toolName);
    return stage === "keep" ? STAGE_TEXT.other : STAGE_TEXT[stage];
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
            const stage = stageForTool(name);
            args[cbIndex] = function (this: unknown, ...cbArgs: unknown[]) {
                try {
                    if (stage === "keep") {
                        const game = currentGame();
                        if (game)
                            updateGamePresence(DEFAULT_DISCORD_USER_KEY, game);
                    }
                    else
                        updateUserPresence(DEFAULT_DISCORD_USER_KEY, STAGE_TEXT[stage], currentGame(), stage);
                }
                catch {
                    // never let presence affect the tool
                }
                const result = (cb as (...a: unknown[]) => unknown).apply(this, cbArgs);
                // A failed build/test call means the AI is now fixing something.
                if (stage === "building" || stage === "testing") {
                    Promise.resolve(result).then((r) => {
                        if (r && typeof r === "object" && (r as { isError?: boolean }).isError)
                            updateUserPresence(DEFAULT_DISCORD_USER_KEY, STAGE_TEXT.fixing, currentGame(), "fixing");
                    }, () => updateUserPresence(DEFAULT_DISCORD_USER_KEY, STAGE_TEXT.fixing, currentGame(), "fixing")).catch(() => undefined);
                }
                return result;
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
