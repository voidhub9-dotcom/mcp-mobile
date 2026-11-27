# Codex Setup

## 1. Add the MCP server

Open Codex and go to **Settings** > **MCP**, then add a new server:

- **Name:** `roblox-executor-mcp`
- **Type:** `STDIO`
- **Command:** `node`
- **Args:** `/path/to/roblox-executor-mcp/dist/index.js`

Replace `/path/to/roblox-executor-mcp` with the actual path where you cloned the repo.

## 1. Open the config file

The Codex CLI config is located at `~/.codex/config.toml`. Open it in your editor.

## 2. Add the MCP server

Add the following to your `config.toml`:

```toml
[mcp_servers.roblox-executor-mcp]
command = "node"
args = ["/path/to/roblox-executor-mcp/dist/index.js"]
```

Replace `/path/to/roblox-executor-mcp` with the actual path where you cloned the repo.

## 3. Restart Codex

Restart your Codex session for the new server to connect.

## Verify

After setup, the MCP tools should appear in your Codex session. If they don't:

- Make sure you ran `pnpm install && pnpm run build` first
- Check that the path to `dist/index.js` is correct
- Ensure Node.js ≥ 18 is installed

## Optional: Discord Rich Presence (VoidHub RPC)

To show **Playing VoidHub RPC** on your Discord profile while the AI runs tools, add the Discord variables to this server's `[mcp_servers.roblox-executor-mcp.env]` table in `~/.codex/config.toml`, then open `http://localhost:16384/auth/discord` once to link your account. See [VoidHub RPC](discord-rpc.md#local-ai-clients-claude-desktop-claude-code-cursor-windsurf-codex-antigravity-zcode-blackbox) for the Developer Portal steps and a config example.
