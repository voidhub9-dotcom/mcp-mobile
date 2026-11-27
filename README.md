<p align="center">
  <img src="docs/banner-new.svg" alt="Roblox Executor MCP" width="900"/>
</p>

# Roblox Executor MCP Server

An MCP server that allows Agents to interact with a running Roblox game client — execute code, inspect scripts, spy on remotes, and more.

## Dashboard

Roblox Executor MCP includes a local web dashboard at:

```text
http://localhost:16384/
```

Use it to see connected Roblox clients, inspect scripts, run tools, view server logs, configure semantic search, and index games for semantic script search.

## Features

- **Code Execution** — Run Lua code and fetch data from the game client.
- **Script Inspection** — Decompile scripts and search across all sources.
- **Instance Search** — CSS-like selectors and hierarchy trees.
- **Remote Spy** — Intercept, log, block, and ignore Remotes/Bindables via [Cobalt](https://github.com/notpoiu/cobalt). Basic remote inventory mode as fallback.
- **GUI Interaction** — Click buttons and type into text boxes.
- **Screenshot** — Capture screenshots on Windows (OS-level) or any platform (client-side viewport capture). The AI receives actual images it can visually analyze.
- **Multi-Client** — Connect multiple Roblox clients at once.
- **Primary / Secondary** — Multiple MCP instances auto-coordinate with automatic promotion. Supports remote relaying via `--baseurl`. See [Advanced](docs/advanced.md).
- **Game Understanding** — Player state snapshot, game GUI inspection, activity tracing, and game system discovery for writing automation scripts.
- **Anti-Cheat Tools** — Scan games for anti-cheat systems with detailed severity-level reports.
- **Anti-AFK** — Automatically prevents idle disconnections by responding to the `Player.Idled` event. Keeps you in the game. Control it on demand with the `anti-afk` MCP tool (`enable` / `disable` / `status`).
- **Server Hop** — Hop the connected client to another public server (`random`, `lowest-players`, `lowest-ping`, or an exact `jobId`), into a different game entirely (`placeId`), or back into the current server (`rejoin`). The connector queues itself via `queue_on_teleport` so the bridge auto-reloads in the destination server and the agent keeps remote control while you are away. See [Server Hop](#server-hop).
- **Termux Phone Agent** — a shell agent for Termux on the phone, served the same way as the in-game connectors. The `phone-shell` tool runs commands on the phone and returns output and exit code. This is how the agent moves you between GAMES (`termux-open-url "roblox://placeId=..."`), since Roblox blocks cross-creator teleports from inside a client. See [Termux Phone Agent](#termux-phone-agent).
- **VoidHub RPC (Discord Rich Presence)** — Link your Discord account once and the server (cloud, phone or PC) shows **Void Hub RPC** as your Discord activity while MCP tools run (e.g. "Making a script"), then clears it after a few idle minutes. No Discord desktop app or local RPC needed. See [VoidHub RPC](docs/discord-rpc.md).
- **Claude Remote Connector Support** — Works as a secure custom connector in Claude's web interface. See the [Claude Remote Connector Guide](docs/claude-connector.md).
- **Custom AI Chat** — Built-in chat interface at `/ai` supporting any Anthropic-compatible API with api-key, bearer token, or custom header auth. Screenshot images are passed to the AI as vision content.
- **Mobile Support** — Works with mobile executors (Delta, CodeX, VegaX, etc.) with fallbacks for missing APIs. See the [Mobile Setup Guide](docs/setup-mobile.md) or [Mobile-Only Setup Guide](docs/setup-mobile-only.md).

## Tutorial

[![roblox-executor-mcp installation guide](http://img.youtube.com/vi/Tcy5RNf1TRc/0.jpg)](https://youtube.com/watch?v=Tcy5RNf1TRc)

## Prerequisites

- **Node.js** ≥ 18
- **Bun** ≥ 1.3 for the interactive OpenTUI harness installer
- **A Roblox executor** that supports `loadstring`, `request`, and (preferably) `WebSocket`

## Quick Start

### 1. Clone the server

```bash
git clone https://github.com/voidhub9-dotcom/mcp-mobile.git
cd mcp-mobile
```

### 2. Run the harness installer

The installer builds the server, lets you choose AI clients, writes supported MCP configs, and prints the Roblox loader script.

```bash
npm run install:harnesses
```

The normal server build consumes the committed `connector.luau` artifact, so harness installs do not require Darklua. Connector developers can install the pinned tool with `rokit install`, edit `connector-src/`, and regenerate the artifact with `npm run build:connector`.

The picker is built with [OpenTUI](https://opentui.com/) and runs through Bun. `npm run install:harnesses` installs Bun first if it is not already available. It shows detected local clients by default; if none are detected, it warns you to install a harness first. Press `s` in the picker or pass `--show-all-harnesses` to reveal every supported config target. If your terminal has trouble with the interactive picker, use the plain numbered prompt:

```bash
npm run install:harnesses -- --plain
```

The installer can also place the Roblox loader into a detected executor autoexec folder, such as MacSploit on macOS or supported Windows executor autoexec folders. Use the prompt, or run:

```bash
npm run getscript -- --autoexec
```

It can also help with:

- cross-machine setup on the same LAN
- copying the Roblox loader to your clipboard
- optional Ollama `embeddinggemma` setup for semantic indexing
- pulling latest repo changes before install/build

To update an existing install later, run:

```bash
npm run update
```

The update command can stop currently running MCP server processes, optionally pull latest changes, and always rebuilds the server.

### Manual setup

If you prefer to configure a client yourself, use the setup guide for your client:

| Client         | Guide                                       |
| -------------- | ------------------------------------------- |
| Cursor         | [Setup Guide](docs/setup-cursor.md)         |
| Claude Desktop | [Setup Guide](docs/setup-claude-desktop.md) |
| **Claude (Web / Mobile / Remote)** | [**Remote Connector Guide**](docs/claude-connector.md) |
| Claude Code    | [Setup Guide](docs/setup-claude-code.md)    |
| Codex CLI      | [Setup Guide](docs/setup-codex.md)          |
| Windsurf       | [Setup Guide](docs/setup-windsurf.md)       |
| Antigravity    | [Setup Guide](docs/setup-antigravity.md)    |
| BLACKBOX AI    | [Setup Guide](docs/setup-blackbox.md)       |
| ZCode          | [Setup Guide](docs/setup-zcode.md)          |
| **Mobile**     | [**Mobile Setup Guide**](docs/setup-mobile.md) |
| Discord Rich Presence (optional, any client) | [VoidHub RPC](docs/discord-rpc.md) |

### 3. Connect from Roblox

The installer prints this for you. Put it in your executor or Auto Execute:

```lua
while not getgenv().MCP_Loaded do
    local bridgeUrl = getgenv().BridgeURL or "localhost:16384"
    pcall(function() loadstring(game:HttpGet("http://" .. bridgeUrl .. "/script.luau"))() end)

    task.wait(0.15)
end
```

**Optional settings** (set before the `loadstring`):

```lua
getgenv().BridgeURL = "10.0.0.4:16384"                  -- default: localhost:16384
getgenv().DisableWebSocket = true                        -- force HTTP polling
getgenv().DisableInitialScriptDecompMapping = true       -- skip initial decompilation
getgenv().MCP_FailedScriptResyncInterval = 30            -- retry failed script syncs periodically
getgenv().MCP_FailedScriptResyncBatchSize = 8            -- bound each periodic retry batch
getgenv().MCP_DisableAntiAFK = true                       -- disable anti-AFK (enabled by default)
```

After the MCP server starts and Roblox connects, open the dashboard:

```text
http://localhost:16384/
```

## Mobile Support

This MCP server works with **mobile Roblox executors** (Delta, CodeX, VegaX, etc.) on Android and iOS.

### Mobile-Only (No PC Needed) — Android

Run everything from your phone using Termux. See the [Mobile-Only Setup Guide](docs/setup-mobile-only.md).

```bash
# In Termux:
git clone https://github.com/voidhub9-dotcom/mcp-mobile.git
cd mcp-mobile
bash termux-setup.sh
bash termux-start.sh --cf
```

Then in your Roblox executor:
```lua
loadstring(game:HttpGet("http://localhost:16384/mobile-connector.luau"))("localhost:16384")
```

### Mobile-Only (No PC Needed) — iOS

Deploy the MCP server to a free cloud service (Railway/Render). Your iPhone connects to it over HTTPS. See the [iOS Cloud Setup Guide](docs/setup-ios-cloud.md).

```lua
-- In your Roblox executor:
getgenv().BridgeURL = "https://YOUR-APP.up.railway.app"
getgenv().MCP_AUTH_TOKEN = "your-token"
loadstring(game:HttpGet("https://YOUR-APP.up.railway.app/mobile-connector.luau"))()
```

### Mobile + PC Setup

If you have a PC, see the [Mobile Setup Guide](docs/setup-mobile.md).

```lua
loadstring(game:HttpGet("http://YOUR_PC_IP:16384/mobile-connector.luau"))("YOUR_PC_IP:16384")
```

## Server Hop

The `server-hop` MCP tool lets an AI agent move your Roblox client between servers, or into a different game entirely, without anyone touching the device. Built for unattended remote control (cloud deployment + phone executor):

- **hop** — leave the current server for another public server. Pick by `mode`: `random`, `lowest-players`, or `lowest-ping`, or pass an exact `jobId`. Pass a `placeId` to hop into a different game.
- **list** — preview candidate servers (players, ping, fps) without hopping.
- **rejoin** — teleport back into the current server.

```text
server-hop { action: "hop", mode: "lowest-players" }        // emptiest server of the current game
server-hop { action: "hop", placeId: 2753915549 }            // hop into a different game
server-hop { action: "list" }                               // preview servers first
server-hop { action: "rejoin" }                             // back into the current server
```

The public server list comes straight from the Roblox games API inside the client (up to `maxPages` x 100 servers scanned). After the teleport, the connector reloads itself via `queue_on_teleport` (when the executor supports it, e.g. Delta) so the bridge reconnects automatically and the agent keeps full tool access in the new server. If the executor lacks `queue_on_teleport`, keep the loader in your autoexec folder so it reconnects on its own.

## Termux Phone Agent

The `phone-shell` MCP tool runs shell commands in Termux on the phone and returns stdout/stderr and the exit code. The agent registers as its own bridge client (visible in `list-clients` as `mobile=termux-agent/android`) and authenticates with the `TERMUX_TOKEN` environment variable set on the server.

Why it exists: Roblox refuses client-initiated teleports into universes owned by a different creator, so the `server-hop` tool can never jump your connected client into another game. The phone shell closes that gap:

```text
phone-shell { command: 'termux-open-url "roblox://placeId=2753915549/"' }   // launch straight into any game
phone-shell { command: 'termux-open-url "roblox://placeId=...&gameInstanceId=<jobId>"' }
```

Setup:

1. Server: set `TERMUX_TOKEN` (e.g. `openssl rand -hex 32`) as an environment variable and redeploy.
2. Phone (Termux):

```bash
curl -fsSL https://<your-deployment>.up.railway.app/termux/agent.sh -o agent.sh
export MCP_AGENT_TOKEN=<the same token>
nohup bash agent.sh >> ~/.mcp-agent/agent.log 2>&1 &
```

The Roblox connector in your autoexec folder and the Termux agent run side by side: the connector gives remote control inside the game, the agent gives remote control of the phone itself.

## VoidHub RPC (Discord Rich Presence)

> Full guide, including local, Termux and Render setups, troubleshooting, and tool → details mapping: [docs/discord-rpc.md](docs/discord-rpc.md).

The server can set your Discord Rich Presence straight from Railway, using Discord Social SDK OAuth2 (scopes `openid sdk.social_layer_presence`) and a headless presence session. While MCP tools are being called, your profile shows:

| Field | Value |
|-------|-------|
| Activity | Playing **Void Hub RPC** |
| Details | What the agent is doing, e.g. `Making a script`, `Spying on remotes`, `Running get-game-info` |
| State | `Connected via Void Hub MCP` |
| Elapsed time | Since the first tool call of the session |
| Large image | Icon of the Roblox game you're in (tooltip: game name). Falls back to `DISCORD_LARGE_IMAGE_KEY` |
| Small image | `DISCORD_LARGE_IMAGE_KEY` (your logo), tooltip `Void Hub MCP` |
| Button | **Get Void Hub** → `DISCORD_BUTTON_URL` |

Updates are throttled to one per 15 seconds and kept alive while you're active. The presence is cleared after 5 minutes with no tool calls. Discord calls never block or fail a tool: if you haven't linked Discord, or Discord is down or slow, tools run exactly as before.

### 1. Discord Developer Portal

1. Go to <https://discord.com/developers/applications> → **New Application**, named e.g. "Void Hub RPC". The application name is what Discord shows as the activity name.
2. **Social SDK**: open **Discord Social SDK → Getting Started**, fill in the form, and enable the Social SDK for the app. The `sdk.social_layer_presence` scope only works once this is enabled.
3. **OAuth2 → Redirects**: add `https://<your-railway-domain>/auth/discord/callback` and save.
4. **OAuth2**: copy the **Client ID**, and **Reset Secret** to get the **Client Secret**.
5. **Rich Presence → Art Assets**: upload your logo with the key `void_logo`, or set `DISCORD_LARGE_IMAGE_KEY` to an `https://` image URL.

### 2. Railway variables

In your Railway service → **Variables**, add:

| Variable | Required | Example / default | Purpose |
|----------|----------|-------------------|---------|
| `DISCORD_CLIENT_ID` | yes | `1234567890` | OAuth2 client id |
| `DISCORD_CLIENT_SECRET` | yes | — | OAuth2 client secret |
| `DISCORD_REDIRECT_URI` | yes | `https://your-app.up.railway.app/auth/discord/callback` | Must exactly match the portal redirect |
| `TOKEN_ENCRYPTION_KEY` | yes | output of `openssl rand -hex 32` | Encrypts stored tokens (AES-256-GCM) |
| `DISCORD_LARGE_IMAGE_KEY` | no | `void_logo` | Art asset key or image URL |
| `DISCORD_SHOW_GAME_ICON` | no | `true` | `false` to always use your logo as the big image |
| `DISCORD_BUTTON_URL` | no | `https://your-site/void-hub` | "Get Void Hub" button link (no button if empty) |
| `MCP_AUTH_TOKEN` | strongly recommended | — | Gates linking and unlinking (see below) |
| `DISCORD_TOKEN_STORE_PATH` | recommended | `/data/discord-links.json` | Put tokens on a Railway volume so they survive redeploys |
| `DISCORD_PRESENCE_IDLE_MS` | no | `300000` | Idle time before the presence is cleared |
| `DISCORD_PRESENCE_THROTTLE_MS` | no | `15000` | Minimum gap between updates (cannot go below 15000) |
| `DISCORD_PRESENCE_KEEPALIVE_MS` | no | `120000` | How often the presence is re-sent while active |

Railway's filesystem is wiped on every deploy. Attach a **Volume** (e.g. mounted at `/data`) and set `DISCORD_TOKEN_STORE_PATH=/data/discord-links.json`, or you'll need to re-link after each deploy. If `TOKEN_ENCRYPTION_KEY` changes, existing links can't be decrypted and you must re-link.

### 3. Link your account

Open `https://<your-railway-domain>/auth/discord`. If `MCP_AUTH_TOKEN` is set, enter it first, then approve on Discord. Use the same page's **Unlink Discord** button to remove the link.

### Endpoints

| Method | Path | Auth (when `MCP_AUTH_TOKEN` is set) | What it does |
|--------|------|------|--------------|
| `GET` | `/auth/discord` | form asks for the token | Starts linking. Redirects to Discord with a one-time CSRF `state` (or shows the token form) |
| `POST` | `/auth/discord` | `server_token` form field | Checks the token, then redirects to Discord |
| `GET` | `/auth/discord/callback` | CSRF `state` | Exchanges the code, then stores encrypted access and refresh tokens |
| `POST` | `/auth/discord/unlink` | `Authorization: Bearer <MCP_AUTH_TOKEN>` or `server_token` field | Clears the live presence, revokes the tokens at Discord, deletes them |
| `GET` | `/auth/discord/status` | `Authorization: Bearer <MCP_AUTH_TOKEN>` | JSON: configured, linked, token expiry, current presence |

```bash
curl -X POST -H "Authorization: Bearer $MCP_AUTH_TOKEN" https://your-app.up.railway.app/auth/discord/unlink
```

Access tokens are refreshed automatically when they are within 5 minutes of expiry, or if Discord rejects them. The server has a single shared `MCP_AUTH_TOKEN`, so there is one linked Discord account per deployment.

## Claude (claude.ai) Custom Connector

This server works as a **custom connector** in Claude's web interface (claude.ai). Claude connects to your MCP server over HTTPS using the Streamable HTTP transport.

### Quick Setup

1. **Start the server in HTTP mode:**
```bash
node dist/index.js --http
```

2. **Expose it via HTTPS** (Claude requires HTTPS). Use a tunnel or cloud deployment:
```bash
# Option A: Cloudflare Tunnel (free, no signup needed for quick tunnels)
cloudflared tunnel --url http://localhost:16384

# Option B: Deploy to Railway/Render (provides HTTPS natively)
# See docs/setup-ios-cloud.md for cloud deployment guide
```

3. **Set an auth token** for security:
```bash
MCP_AUTH_TOKEN=your-secret-token node dist/index.js --http
```

4. **Add the connector in Claude:**
   - Go to **Settings > Connectors > Add custom connector**
   - **Name:** `Roblox MCP`
   - **URL:** `https://YOUR-TUNNEL-URL/mcp` (do **not** append `?token=`)
   - Leave OAuth fields blank unless you deliberately use a pre-registered client
   - Click **Add**, then **Connect**
   - On the Roblox MCP sign-in page, enter the `MCP_AUTH_TOKEN` configured on the server and choose **Authorize Roblox MCP**

   > Claude discovers OAuth metadata, registers a connector client, and receives a short-lived OAuth token. Do not store the long-lived server token in the connector URL.

5. **Connect your Roblox client** using the connector script:
```lua
loadstring(game:HttpGet("http://localhost:16384/mobile-connector.luau"))()
```

For deployment, OAuth authorization, end-to-end testing, and tool-permission guidance, see the [Claude Remote Connector Guide](docs/claude-connector.md).

## Custom AI Integration

This server includes a **built-in AI chat interface** — no separate AI client needed. It supports **any Anthropic-compatible API** with flexible auth modes (api-key, bearer token, or custom header), so you can use Claude, DeepSeek, or any compatible provider. Screenshots taken in-game are passed to the AI as vision content — the AI can actually see the game screen.

### Setup

1. Open the chat page in your browser:
```
http://localhost:16384/ai          # local
https://YOUR-APP.up.railway.app/ai  # cloud
```
2. Tap **Settings** and configure:
   - **API Key** — your API key or bearer token
   - **Auth Type** — `api-key` (x-api-key header), `bearer` (Authorization: Bearer), or custom header
   - **Base URL** — the Anthropic-compatible endpoint (e.g. `https://api.anthropic.com`)
   - **API Version** — e.g. `2023-06-01`
   - **Default Model** — e.g. `claude-sonnet-4-20250514`
   - **Extended Thinking** — toggle to show the AI's reasoning process
3. Start chatting — the AI can use all MCP tools (execute code, inspect scripts, search, GUI interaction, take screenshots and see them, etc.)

### Environment Variables (optional, for cloud deployment)

| Env Var | Default | Description |
|---------|---------|-------------|
| `CUSTOM_AI_API_KEY` | — | API key |
| `CUSTOM_AI_BASE_URL` | `https://api.anthropic.com` | Anthropic-compatible base URL |
| `CUSTOM_AI_API_VERSION` | `2023-06-01` | API version header |
| `CUSTOM_AI_MODEL` | `claude-sonnet-4-20250514` | Default model |
| `CUSTOM_AI_MAX_TOKENS` | `16000` | Max response tokens |
| `CUSTOM_AI_THINKING_ENABLED` | `false` | Enable extended thinking |
| `CUSTOM_AI_THINKING_BUDGET` | `10000` | Thinking token budget |
| `CUSTOM_AI_AUTH_TYPE` | `api-key` | Auth mode: `api-key` (x-api-key header) or `bearer` (Authorization: Bearer) |
| `CUSTOM_AI_BEARER_TOKEN` | — | Bearer token for OAuth/proxy auth |
| `CUSTOM_AI_AUTH_HEADER` | — | Custom auth header name override |

## Community

Have a suggestion or need help? Join the [Discord server](https://discord.gg/FJcJMuze7S).

## Security

> **This server allows arbitrary code execution.** Only use with AI clients you trust. For any publicly reachable deployment, set a strong `MCP_AUTH_TOKEN`; each cloned deployment automatically derives its own OAuth origin and Claude receives short-lived OAuth tokens. Never expose an unauthenticated deployment to the internet. See [Advanced](docs/advanced.md) for details.

## License

[MIT](LICENSE)
