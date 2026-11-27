# Claude Code (CLI) Setup

> This guide configures a **local stdio** MCP server for Claude Code. For a public HTTPS server used in Claude's remote connector interface, use the [Claude Remote Connector Guide](claude-connector.md).

## 1. Add the MCP server

Run this command in your terminal:

```bash
claude mcp add roblox-executor-mcp -- node /path/to/roblox-executor-mcp/dist/index.js
```

Replace `/path/to/roblox-executor-mcp` with the actual path where you cloned the repo.

This adds the server to your local project config (`.claude/settings.local.json`). To add it globally instead, use:

```bash
claude mcp add --global roblox-executor-mcp -- node /path/to/roblox-executor-mcp/dist/index.js
```

## 2. Verify

Start Claude Code and run:

```
/mcp
```

You should see `roblox-executor-mcp` listed with a status of `connected`. If it shows `failed`:

- Make sure you ran `pnpm install && pnpm run build` first
- Check that the path to `dist/index.js` is correct
- Ensure Node.js ≥ 18 is installed

## Managing the server

```bash
# List configured MCP servers
claude mcp list

# Remove the server
claude mcp remove roblox-executor-mcp
```

## Optional: Discord Rich Presence (VoidHub RPC)

To show **Playing VoidHub RPC** on your Discord profile while Claude Code runs tools, pass the Discord variables when adding the server:

```bash
claude mcp add roblox-executor-mcp \
  -e DISCORD_CLIENT_ID=1234567890123456789 \
  -e DISCORD_CLIENT_SECRET=your-client-secret \
  -e DISCORD_REDIRECT_URI=http://localhost:16384/auth/discord/callback \
  -e TOKEN_ENCRYPTION_KEY=$(openssl rand -hex 32) \
  -- node /path/to/roblox-executor-mcp/dist/index.js
```

Then open `http://localhost:16384/auth/discord` once to link your account. Keep the same `TOKEN_ENCRYPTION_KEY` if you re-add the server, or you'll need to link again. See [VoidHub RPC](discord-rpc.md) for the Developer Portal steps.
