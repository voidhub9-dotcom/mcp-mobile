# Advanced Configuration

## Primary / Secondary Mode

By default, the server starts as a **primary** on port `16384`. If that port is already in use, it automatically becomes a **secondary** that relays all tool calls through the primary. When the primary disconnects, a secondary will promote itself automatically.

### Remote primary (`--baseurl`)

If your AI client runs on macOS/Linux but Roblox is on a Windows machine, you can relay through a remote primary:

```json
{
  "mcpServers": {
    "roblox-executor-mcp": {
      "command": "node",
      "args": [
        "/path/to/roblox-executor-mcp/dist/index.js",
        "--baseurl",
        "http://<windows-ip>:16384"
      ]
    }
  }
}
```

**Fallback behavior:**

| Scenario | Result |
|---|---|
| Remote reachable | Secondary relay to remote host |
| Remote unreachable | Falls back to primary locally |
| Remote unreachable + local port taken | Secondary to local primary |

> `screenshot-window` and `list-roblox-windows` are forwarded over HTTP to the primary, so a Mac secondary can capture windows on a Windows primary.

## Connector Options

Set these in Roblox **before** running the connector:

| Variable | Default | Description |
|---|---|---|
| `getgenv().BridgeURL` | `localhost:16384` | Server address to connect to |
| `getgenv().DisableWebSocket` | `false` | Force HTTP polling instead of WebSocket |
| `getgenv().DisableInitialScriptDecompMapping` | `false` | Skip decompiling all scripts on connect |
| `getgenv().MCP_FailedScriptResyncInterval` | `30` | Seconds before the first failed-script resync; repeated failures back off to five minutes |
| `getgenv().MCP_FailedScriptResyncBatchSize` | `8` | Maximum failed scripts queued by one periodic resync tick |

Failed script mappings are retried automatically in bounded batches. A resync prioritizes the provider that the original attempt actually reached, then uses the configured provider order as fallback.

The connector supports two transport modes:
- **WebSocket** (preferred) — persistent connection, lower latency
- **HTTP Polling** — fallback for executors that don't support WebSocket

## Dashboard

A live status dashboard is available at `http://localhost:16384/` when the server is running. It shows connected clients, server role, and uptime.

Under **Settings → Decompiler fallbacks**, choose **Add provider → Custom provider** to add an HTTP decompiler to the fallback chain. You can add multiple custom providers; each keeps an independent workflow, fallback position, endpoint, authentication, headers, timeout, and health state. The custom-provider editor uses a pannable, zoomable node canvas: add blocks, drag them into place, and connect their ports to define the bytecode-to-source path. Bytecode and Source are permanent boundary blocks. Use Set Variable to name the current raw or base64 value, then reference it in the Request headers or body with `{{variable_name}}`; the optional API key is available as `{{api_key}}`. Type `{{` for autocomplete, use the arrow keys to choose a variable, and press Enter or Tab to insert it. Undo and redo are available from the toolbar or with Command/Ctrl+Z, Command/Ctrl+Shift+Z, and Ctrl+Y. The Request response port can connect directly to Source for plain text or through Parse JSON for a configurable dot-path field.

## Server Hop (`server-hop`)

The `server-hop` tool rides the existing `get-data-by-code` bridge type, so both the desktop and mobile connectors serve it without any connector artifact changes. The hop itself runs inside the Roblox client:

1. The client fetches the public server list from the Roblox games API (`games.roblox.com/v1/games/<placeId>/servers/Public`, up to `maxPages` pages of 100), with the legacy `getgameinstancesjson` endpoint as a fallback when the modern API returns nothing.
2. The current `jobId` (plus any `excludeJobIds`) is filtered out, and a destination is picked by `mode`: `random`, `lowest-players`, or `lowest-ping`. With an explicit `jobId` the list scan is skipped entirely.
3. Before teleporting, the connector loader is queued with `queue_on_teleport` when the executor provides it. The queued script resets `MCP_Loaded`, picks the right connector (`/script.luau` when the desktop bridge marker `MCP_ActiveBridge` is present, otherwise `/mobile-connector.luau`), and reloads it in the destination server so remote control survives the hop.
4. `TeleportService:TeleportToPlaceInstance` (or `TeleportService:Teleport` for a cross-game hop with no listed servers) initiates the move, and the result table (chosen server, players, ping, reconnect status) is returned to the agent.

Known limits: teleports only work from a live session (after a hard kick the client has no character to teleport, so `rejoin` reports that case instead of teleporting), and executors without `queue_on_teleport` rely on an autoexec loader to reconnect (the tool result says which path was taken).

## Phone Shell (`phone-shell`)

The `phone-shell` tool sends shell commands to a Termux agent on the phone. The agent is a bridge client like the in-game connectors: it registers through `/termux/register` (authenticated against the server's `TERMUX_TOKEN` environment variable with a constant-time compare), long-polls `/poll`, and answers through `/respond`. The agent carries the `phone-shell` capability; the tool picks the most recently active agent or an explicit `clientId`, dispatches a `phone-shell` message directly (`SendArbitraryDataToClient`, not the bridge `sendAndWait` helper), and resolves the response.

1. Commands run through `bash -lc` as the Termux user (no root), with the timeout the tool requested (clamped 5s to 300s) plus output truncation through the standard tool limits.
2. The response is stdout, stderr (under a `[stderr]` marker), and the exit code on a trailing `[exit: N]` line, prefixed by the agent identity.
3. If the agent is missing, the tool returns setup instructions instead of a generic failure.

Known limits: cross-game movement is the main use case (`termux-open-url "roblox://placeId=<id>/"`, optionally `&gameInstanceId=<jobId>` to target a server), because client-initiated teleports into a different creator's universe are refused by the engine itself. The agent only reaches what a non-root Termux shell can reach.

## Discord Rich Presence (VoidHub RPC)

The server can set the linked user's Discord Rich Presence over HTTP (Discord Social SDK OAuth2, scopes `openid sdk.social_layer_presence`, headless presence session). Nothing runs on the Discord client side. Full guide: [VoidHub RPC](discord-rpc.md).

- **Hook:** `installPresenceToolHook()` wraps `server.registerTool` in `createMcpServer()`, so every tool fires `updateUserPresence("default", action)`. The call is synchronous, throws nothing, and never waits on the network.
- **Throttle / keepalive / idle:** at most one push per `DISCORD_PRESENCE_THROTTLE_MS` (15s minimum), a re-send every `DISCORD_PRESENCE_KEEPALIVE_MS` (2 min) while active, and the session ends after `DISCORD_PRESENCE_IDLE_MS` (5 min) without tool calls.
- **Storage:** AES-256-GCM-encrypted JSON at `DISCORD_TOKEN_STORE_PATH` (default `~/.roblox-mcp/discord-links.json`). Primary and secondary instances on one machine share the file and see link changes within 30 seconds. Give every instance the same `TOKEN_ENCRYPTION_KEY`.
- **Primary / secondary:** linking routes are served by whichever instance owns the HTTP port (the primary). Presence is sent by whichever instance handles the tool call, so secondaries need the Discord variables too.
- **Routes:** `/auth/discord`, `/auth/discord/callback`, `/auth/discord/unlink`, `/auth/discord/status`. When `MCP_AUTH_TOKEN` is set, all of them except the callback require it.

## Security

- Discord OAuth tokens for VoidHub RPC are encrypted at rest with `TOKEN_ENCRYPTION_KEY` and are never returned by any endpoint. See [VoidHub RPC → Security](discord-rpc.md#security).

**This server allows arbitrary code execution.** Any connected AI client can run Lua code in your Roblox session, take screenshots, and read client data.

**Never expose port `16384` to the internet.** There is no authentication. For cross-machine setups:

- Use a **local network** or **VPN**
- Use an **SSH tunnel**: `ssh -L 16384:localhost:16384 user@windows-machine`
- **Never** forward the port through a public router or cloud firewall

For a publicly hosted Streamable HTTP MCP endpoint used by Claude, configure a strong `MCP_AUTH_TOKEN` and follow the [Claude Remote Connector Guide](claude-connector.md). That guide documents the separate OAuth-protected `/mcp` flow; it does not make an unauthenticated raw bridge safe to expose.
