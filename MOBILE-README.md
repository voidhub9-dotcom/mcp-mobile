# Mobile Roblox Executor MCP

> **An MCP server that lets AI agents interact with Roblox games running on mobile devices.**

Connect AI agents (Claude, Cursor, etc.) to Roblox games running on your phone via mobile executors like Delta, CodeX, and VegaX. Execute code, inspect game state, search instances, and more — all from your AI assistant.

## What's New

This extends the [Roblox Executor MCP](README.md) to work with **mobile Roblox executors** on Android and iOS. The key innovation is a mobile-adapted Luau connector that:

- **Auto-detects executor capabilities** — probes for available APIs (loadstring, request, WebSocket, decompile, etc.) and provides compatibility shims for missing functions
- **Forces HTTP polling** — mobile executors often don't support WebSocket, so the connector falls back to HTTP polling automatically
- **Gracefully degrades** — tools that require unsupported APIs return clear error messages instead of crashing
- **Reports capabilities to the server** — the MCP server knows exactly what each mobile client can do, and AI agents can query this with `get-client-capabilities`

## Architecture

```
┌─────────────┐     MCP stdio    ┌──────────────────┐    HTTP polling    ┌───────────────────┐
│  AI Client  │ <──────────────> │  MCP Server (PC) │ <────────────────> │  Mobile Executor  │
│  Claude,    │                   │  Port 16384       │                    │  Delta / CodeX     │
│  Cursor...  │                   │                   │                    │  Android / iOS     │
└─────────────┘                   └──────────────────┘                    └───────────────────┘
```

The MCP server runs on your PC. The mobile executor on your phone loads the mobile connector script, which connects to the server over your local network.

## Three Ways to Run on Mobile

### Option A: Mobile-Only (No PC) — Android

Run everything from your phone using Termux. The MCP server runs on your phone alongside the Roblox executor.

```bash
# In Termux:
git clone https://github.com/vonsalt/mcp-mobile.git
cd mcp-mobile
bash termux-setup.sh
bash termux-start.sh --cf
```

Then in your Roblox executor:
```lua
loadstring(game:HttpGet("http://localhost:16384/mobile-connector.luau"))("localhost:16384")
```

See the [Mobile-Only Setup Guide](docs/setup-mobile-only.md) for full details.

### Option B: Mobile-Only (No PC) — iOS

Deploy the MCP server to a free cloud service (Railway or Render). Your iPhone's Roblox executor and AI client both connect to it over HTTPS. No local server needed.

```lua
getgenv().BridgeURL = "https://YOUR-APP.up.railway.app"
getgenv().MCP_AUTH_TOKEN = "your-token"
loadstring(game:HttpGet("https://YOUR-APP.up.railway.app/mobile-connector.luau"))()
```

See the [iOS Cloud Setup Guide](docs/setup-ios-cloud.md) for full details.

### Option C: Mobile + PC

The MCP server runs on your PC, your phone's executor connects over WiFi.

```lua
loadstring(game:HttpGet("http://YOUR_PC_IP:16384/mobile-connector.luau"))("YOUR_PC_IP:16384")
```

See the [Mobile Setup Guide](docs/setup-mobile.md) for full details.

## Files

| File | Description |
|------|-------------|
| `mobile-connector.luau` | Standalone mobile connector script (served at `/mobile-connector.luau`) |
| `mobile-probe.luau` | Capability probe script (served at `/mobile-probe.luau`) |
| `connector-src/mobile-connector.luau` | Source for the mobile connector |
| `connector-src/mobile-probe.luau` | Source for the capability probe |
| `src/http/routes/mobile-connector.luau.ts` | Route serving the mobile connector |
| `src/http/routes/mobile-probe.luau.ts` | Route serving the capability probe |
| `src/tools/impl/clients/get-client-capabilities.ts` | MCP tool for querying client capabilities |
| `docs/setup-mobile.md` | Detailed mobile setup guide |

## New MCP Tool: `get-client-capabilities`

Returns the capability profile of the active client:

- Executor name (Delta, CodeX, etc.)
- Platform (Android, iOS, Desktop)
- Available APIs (loadstring, request, WebSocket, decompile, etc.)
- Which MCP tools will work on this client

Example output:
```
Client: abc-123-def
Executor: Delta
Platform: Mobile
Capabilities:
  [OK] loadstring
  [OK] request
  [--] WebSocket
  [OK] getgenv
  [OK] setthreadidentity
  [--] decompile
  [--] getscriptbytecode
Tool Availability:
  [OK] execute
  [OK] get-data-by-code
  [OK] get-console-output
  [OK] get-game-info
  [NA] get-script-content
  [NA] script-grep
```

## Mobile Compatibility Shims

The mobile connector includes these compatibility layers:

### HTTP Request Fallback
Tries `request` → `http_request` → `syn.request` → `http_get` → `game:HttpGet`/`game:HttpPost`

### Thread Identity Fallback
Tries `setthreadidentity` → `setidentity` → runs at default identity

### JSON Encoding
Tries LuaEncode (from GitHub) → falls back to a built-in simple JSON encoder

### GUI Interaction
Tries `firesignal` → falls back to `VirtualInputManager` touch simulation

### Script Inspection
Tries `decompile` → `getscriptbytecode` → returns clear error if neither is available

## Supported Executors

Tested (or expected to work) with:

- **Delta** — Android & iOS, most popular mobile executor
- **CodeX** — Android & iOS, comparable to Delta
- **VegaX** — Android only
- **ArceusX** — Android only
- **Cryptic** — Android only
- **Ronix** — Android only
- **Hydrogen** — Android & iOS
- **Wave** — Android & iOS

## Limitations

- **No screenshots** — screenshot capture is Windows desktop only
- **Limited script inspection** — many mobile executors don't support `decompile` or `getscriptbytecode`
- **No semantic search** — requires decompilation which is often unavailable on mobile
- **Slower than WebSocket** — HTTP polling has slightly higher latency
- **No remote spy (limited)** — depends on executor API support

## Security

- **Arbitrary code execution** — this server allows AI agents to execute arbitrary Luau code in your Roblox client. Only use with trusted AI clients.
- **No authentication on port 16384** — never expose this port to the internet. Use Tailscale or SSH tunnels for cross-network access.
- **Only use with your own experiences** — or experiences where you have permission to test.

## DeepSeek AI Integration

This server includes a **built-in DeepSeek chat interface** at `/deepseek`. No separate AI client needed — DeepSeek's API powers the AI, and all MCP tools (execute, inspect, search, GUI, etc.) are automatically available.

### Quick Setup

1. Get a DeepSeek API key from [platform.deepseek.com/api_keys](https://platform.deepseek.com/api_keys)
2. Set it as an env var (recommended) or paste it in the chat UI Settings:
```bash
export DEEPSEEK_API_KEY="sk-your-key-here"
```
3. Open the chat page in your phone browser:
```
http://localhost:16384/deepseek        # Termux (Android)
https://YOUR-APP.up.railway.app/deepseek  # Cloud (iOS/Android)
```
4. If using cloud with auth, also set your bridge auth token in Settings.

### Config

| Env Var | Default | Description |
|---------|---------|-------------|
| `DEEPSEEK_API_KEY` | — | API key (starts with `sk-`) |
| `DEEPSEEK_MODEL` | `deepseek-v4-flash` | Model name |
| `DEEPSEEK_BASE_URL` | `https://api.deepseek.com` | API base URL |
| `DEEPSEEK_MAX_TOKENS` | `8192` | Max response tokens |

## Full Documentation

- [Main README](README.md)
- [Mobile Setup Guide](docs/setup-mobile.md)
- [Advanced Configuration](docs/advanced.md)
