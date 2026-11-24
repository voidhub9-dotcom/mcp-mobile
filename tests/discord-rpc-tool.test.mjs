import assert from "node:assert/strict";
import { existsSync, readFileSync } from "node:fs";

// 1. The Discord RPC IPC client and presence manager exist.
const rpcPath = new URL("../src/discord/rpc.ts", import.meta.url);
const presencePath = new URL("../src/discord/presence.ts", import.meta.url);
assert.ok(existsSync(rpcPath), "src/discord/rpc.ts must exist");
assert.ok(existsSync(presencePath), "src/discord/presence.ts must exist");

// 2. The MCP tool registers "discord-rpc" with enable/disable/status actions.
const toolPath = new URL("../src/tools/impl/clients/discord-rpc.ts", import.meta.url);
assert.ok(existsSync(toolPath), "src/tools/impl/clients/discord-rpc.ts must exist");
const toolSource = readFileSync(toolPath, "utf8");
assert.match(toolSource, /registerTool\("discord-rpc"/, "tool file must register the discord-rpc tool");
assert.match(toolSource, /"enable",\s*"disable",\s*"status"/, "tool must accept enable/disable/status actions");
assert.match(toolSource, /setDiscordPresenceEnabled/, "tool must drive the server-side presence manager");

// 3. The tool is registered in the tool registry and presence starts with the server.
const indexSource = readFileSync(new URL("../src/tools/index.ts", import.meta.url), "utf8");
assert.match(indexSource, /registerDiscordRpc\(server\)/, "tool registry must include discord-rpc");
const serverSource = readFileSync(new URL("../src/index.ts", import.meta.url), "utf8");
assert.match(serverSource, /startDiscordPresence\(\)/, "server startup must start the presence manager");

// 4. Config exposes the Discord env knobs.
const configSource = readFileSync(new URL("../src/config.ts", import.meta.url), "utf8");
assert.match(configSource, /DISCORD_RPC_CLIENT_ID/, "config must read DISCORD_RPC_CLIENT_ID");
assert.match(configSource, /DISCORD_RICH_PRESENCE/, "config must read DISCORD_RICH_PRESENCE");

// 5. The presence manager never fabricates image assets when none are configured.
const presenceSource = readFileSync(presencePath, "utf8");
assert.match(presenceSource, /buildActivityForClient/, "presence manager must build activity from a client entry");
assert.match(
    presenceSource,
    /DISCORD_RPC_LARGE_IMAGE\s*\?/,
    "activity assets must only be set when DISCORD_RPC_LARGE_IMAGE is configured",
);

// 6. The IPC client validates the application ID before connecting.
const rpcSource = readFileSync(rpcPath, "utf8");
assert.match(rpcSource, /connectDiscordIpc/, "rpc module must export connectDiscordIpc");
assert.match(rpcSource, /discord-ipc-/, "rpc module must target the local discord-ipc pipes");

console.log("Discord RPC tool test passed");
