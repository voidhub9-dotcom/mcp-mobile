# ZCode Setup

ZCode reads user-level MCP servers from `~/.zcode/cli/config.json` under `mcp.servers`. The harness installer can merge this server into that file without replacing your other ZCode settings.

## Installer

Run the installer, reveal all harnesses if ZCode was not detected automatically, and select **ZCode**:

```bash
npm run install:harnesses -- --show-all-harnesses
```

The generated configuration has this shape:

```json
{
  "mcp": {
    "servers": {
      "roblox-mcp": {
        "command": "node",
        "args": [
          "/absolute/path/to/roblox-executor-mcp/dist/index.js",
          "--server-name",
          "roblox-mcp"
        ]
      }
    }
  }
}
```

The installer preserves unrelated keys and MCP servers already present in the file and writes a `.bak` copy before changing an existing config.

## Verify in ZCode

1. Restart ZCode or reload its window.
2. Open **Settings -> MCP Servers**.
3. Confirm `roblox-mcp` is listed and enabled.
4. Run the Roblox loader printed by the installer in your executor.

See ZCode's [MCP server documentation](https://zcode.z.ai/en/docs/mcp-services) for its UI and workspace-level configuration options.

## Optional: Discord Rich Presence (VoidHub RPC)

To show **Playing Void Hub RPC** on your Discord profile while the AI runs tools, add the Discord variables to this server's `"env"` object under `mcp.servers.roblox-mcp` in `~/.zcode/cli/config.json`, then open `http://localhost:16384/auth/discord` once to link your account. See [VoidHub RPC](discord-rpc.md#local-ai-clients-claude-desktop-claude-code-cursor-windsurf-codex-antigravity-zcode-blackbox) for the Developer Portal steps and a config example.
