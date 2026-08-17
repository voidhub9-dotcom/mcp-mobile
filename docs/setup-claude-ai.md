# Claude (claude.ai) Setup

> Connect Claude.ai as an MCP client over the web. Claude calls your server's `/mcp` endpoint using Streamable HTTP, and the server forwards each tool call to your Roblox client.

Claude.ai only accepts **HTTPS** URLs for custom connectors — plain `http://localhost` will not work. This guide shows two ways to get a public HTTPS endpoint in front of your server: a quick local tunnel, or a managed cloud deployment.

```
                 HTTPS (Streamable HTTP)              WebSocket / HTTP polling
  ┌─────────┐ ────────────────────────────────► ┌────────────────────────┐ ◄────────────────────► ┌───────────────────┐
  │ Claude  │   POST https://YOUR_HOST/mcp      │  MCP Server             │                       │  Roblox client    │
  │ .ai     │   Authorization: Bearer <token>  │  Port 16384 (--http)    │                       │  (Delta/CodeX/PC) │
  └─────────┘                                   │  Mcp-Session-Id        │                       └───────────────────┘
                                                └────────────────────────┘
```

## Prerequisites

- A built copy of this server (`npm run build`)
- **Node.js** ≥ 18
- A **Roblox executor** connected as a client (PC or mobile) — see [Mobile Setup](setup-mobile.md)
- A **paid Claude plan** (Pro or Max) or an Owner/Primary Owner role on a Team/Enterprise plan — custom connectors are not available on the Free tier

## Step 1: Get an HTTPS endpoint

Pick **one** of the options below.

### Option A: Local server + tunnel (quickest to try)

Start the server in HTTP mode on your machine:

```bash
npm run build
npm run start:http
# or: node dist/index.js --http
```

You should see:

```
[Config] --http mode enabled. MCP Streamable HTTP transport on port 16384.
```

Now expose port `16384` to the internet over HTTPS. Any tunnel that terminates TLS and forwards to `localhost:16384` works.

**Cloudflare Quick Tunnel** (free, no account):

```bash
# install once: https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/
cloudflared tunnel --url http://localhost:16384
```

Look for a line like:

```
+--------------------------------------------------------------------------------------------+
|  Your quick Tunnel has been created! Visit it at (it may take some time to be reachable): |
|  https://random-words-xxxx.trycloudflare.com                                              |
+--------------------------------------------------------------------------------------------+
```

**ngrok** (free, requires account):

```bash
ngrok http 16384
```

Copy the forwarding URL, e.g. `https://abcd-1-2-3-4.ngrok-free.app`.

> Keep the tunnel process running for as long as you want Claude to reach the server. The URL changes every time you restart a quick tunnel.

### Option B: Cloud deployment (always-on HTTPS)

Deploy the server to Railway or Render, which provide a native HTTPS domain. This mirrors the [iOS Cloud Setup](setup-ios-cloud.md).

1. Fork [github.com/vonsalt/mcp-mobile](https://github.com/vonsalt/mcp-mobile)
2. Deploy the fork:
   - **Railway:** New Project → Deploy from GitHub repo → pick your fork → Settings → Networking → Generate Domain
   - **Render:** New + → Web Service → connect your repo (the `render.yaml` is auto-detected) → Create Web Service
3. Wait 2–3 minutes for the build. You'll get a URL like `https://mcp-mobile-production.up.railway.app`.

Cloud platforms set the `PORT` env var automatically; the server reads it and listens on that port. No `--http` flag is needed in the Docker/start command the platform uses — the repo's `Dockerfile` and `render.yaml` already start the server in HTTP mode.

## Step 2: Set the auth token (required for security)

Set `MCP_AUTH_TOKEN` to a long random string. The server checks every request for `Authorization: Bearer <token>` and rejects anything that doesn't match.

- **Local:** start the server with the env var:

  ```bash
  export MCP_AUTH_TOKEN="$(openssl rand -hex 24)"
  echo "Your token: $MCP_AUTH_TOKEN"
  npm run start:http
  ```

- **Cloud (Railway/Render):** add an environment variable in the dashboard:
  - Key: `MCP_AUTH_TOKEN`
  - Value: any random string (e.g. 32+ characters)

> Without `MCP_AUTH_TOKEN`, anyone who knows your URL can execute Luau in your Roblox client. Never deploy to the cloud without it.

## Step 3: Add the connector in Claude

1. Open [claude.ai](https://claude.ai) and sign in.
2. Go to **Settings → Connectors → Add custom connector**.
   - On **Team/Enterprise** plans this lives under **Organization settings → Connectors → Add → Custom → Web** (done by an Owner), and members then go to **Customize → Connectors** to click **Connect**.
3. Fill in:
   - **Name:** `Roblox MCP` (or anything you like)
   - **URL:** your HTTPS `/mcp` endpoint, e.g.
     - `https://random-words-xxxx.trycloudflare.com/mcp` (tunnel)
     - `https://mcp-mobile-production.up.railway.app/mcp` (cloud)
4. Add the Bearer token as a request header (this is how static token auth works in Claude — leave the OAuth Client ID/Secret fields blank):
   - Open the **Request headers** section.
   - Add a header named `authorization` (it's on Claude's allowlist).
   - Value: `Bearer YOUR_TOKEN_HERE` — include the word `Bearer`, a space, then your token. Most servers reject a bare token without the `Bearer ` prefix.
   - Mark it **Required**.
5. Click **Add**, then **Connect**.

Claude will call the endpoint and list the available tools. You should see a green "Connected" status.

> The OAuth Client ID and Secret fields are **optional** — only fill them in if you've built a full OAuth authorization server. This server uses a static Bearer token, so use the Request headers approach instead.

## Step 4: Connect the Roblox client

The MCP server only exposes tools; an actual Roblox client must be connected for tool calls to do anything. Connect one the same way you would for any other AI client.

**PC executor** (local — same machine as the server):

```lua
loadstring(game:HttpGet("http://localhost:16384/mobile-connector.luau"))()
```

**Mobile executor** (Delta, CodeX, etc.) pointing at a cloud deployment:

```lua
getgenv().BridgeURL = "https://YOUR-APP.up.railway.app"
getgenv().MCP_AUTH_TOKEN = "YOUR_TOKEN_HERE"
loadstring(game:HttpGet("https://YOUR-APP.up.railway.app/mobile-connector.luau"))()
```

Replace `YOUR-APP.up.railway.app` and `YOUR_TOKEN_HERE` with your real values. The connector auto-detects executor capabilities and falls back to HTTP polling if WebSocket isn't available.

Confirm a client is connected by opening the dashboard at `https://YOUR_HOST/` (or `http://localhost:16384/` locally) — you should see the client listed.

## Step 5: Use it

In a Claude chat, the connector is available under **Customize → Connectors**. Ask Claude to use it, e.g.:

- "What game am I in? Get the game info."
- "Search for a ScreenGui with a sell button and click it."
- "Execute a script that prints my current leaderstats."

Claude routes each tool call to your `/mcp` endpoint, which relays it to the connected Roblox client.

## Available tools

Once connected, Claude sees these tools (all require an active Roblox client unless noted):

| Tool | What it does |
|------|--------------|
| `get-game-info` | Place/universe metadata, local player identity. Call this first. |
| `list-clients` | List connected Roblox clients with clientIds. |
| `set-active-client` | Route future tool calls to a specific client. |
| `get-client-capabilities` | Executor name, platform, and which APIs are available. |
| `execute` | Run Luau and return serialized values. |
| `execute-file` | Run a local `.luau`/`.lua` file (no return value). |
| `get-data-by-code` | Targeted value probes (preferred over `execute` for reads). |
| `get-console-output` | Read recent developer console logs. |
| `get-script-content` | Decompiled source for a script by path/proxy/getter. |
| `script-grep` | Regex/literal search across decompiled scripts. |
| `semantic-search-scripts` | Find scripts by behavior when names are unknown. |
| `search-instances` | CSS-like `QueryDescendants` selectors against a root. |
| `get-descendants-tree` | Instance hierarchy tree under a path. |
| `get-player-state` | Snapshot of character, leaderstats, backpack, nearby parts. |
| `get-game-guis` | Visible ScreenGuis and their buttons/text boxes. |
| `trace-game-activity` | Before/after state deltas to reveal game mechanics. |
| `find-game-systems` | Discover quest/shop/teleport/NPC instances by keyword. |
| `scan-anticheat` | Detect kick/ban, speed checks, executor detection, etc. |
| `anticheat-bypass` | Generate a tailored bypass script (review before running). |
| `decrypt-remote` | Find, hook, and capture encrypted RemoteEvents/Functions. |
| `remote-spy` | Inspect/control the Cobalt remote spy (block/unblock/ignore). |
| `click-button` | Fire a TextButton/ImageButton's GUI signals. |
| `type-text-box` | Enter text into a TextBox (keystrokes or direct set). |
| `client-screenshot` | In-game viewport screenshot (any platform). |
| `screenshot-window` | OS-level Roblox window screenshot (Windows). |
| `list-roblox-windows` | List visible Roblox OS windows with PIDs. |

## Troubleshooting

### 401 Unauthorized

The `Authorization` header Claude sends doesn't match `MCP_AUTH_TOKEN` on the server.

- Confirm the header value is exactly `Bearer ` + your token (with the space).
- Confirm `MCP_AUTH_TOKEN` is set on the **server process that's actually running** (restart it after changing the env var).
- On cloud deployments, re-check the variable in the Railway/Render dashboard — a typo or trailing space will break it.
- If you skipped Step 2 and ran without a token, either set one and add the header, or (local testing only) leave `MCP_AUTH_TOKEN` unset so the server accepts all requests.

### 404 / "Session not found"

Claude reuses a `Mcp-Session-Id` across requests. Sessions expire after 30 minutes of inactivity.

- This usually fixes itself on the next request (Claude gets a 404, re-initializes, and retries).
- If it persists: disconnect and reconnect the connector in **Settings → Connectors**.
- Restarting the server wipes all sessions — reconnect after a restart.

### "No client connected" / tool calls return an error

Tools need a live Roblox client. The server exposes the tools regardless of whether a client is connected.

- Verify a client shows up in the dashboard (`https://YOUR_HOST/`).
- Re-run the loader in your executor.
- Make sure `getgenv().BridgeURL` and `getgenv().MCP_AUTH_TOKEN` match the server's URL and token.
- Mobile clients: if WebSocket fails, the connector falls back to HTTP polling — give it a few seconds.

### CORS errors

The server already sends permissive CORS headers on the `/mcp` route:

```
Access-Control-Allow-Origin: *
Access-Control-Allow-Headers: Content-Type, Accept, Authorization, Mcp-Session-Id
```

If you still see CORS errors in a browser-based client:

- Make sure you're hitting `/mcp` (not `/`) — CORS headers are only applied to the MCP route.
- If you put a reverse proxy or CDN in front of the server, ensure it forwards the `Authorization` and `Mcp-Session-Id` headers and doesn't strip the CORS response headers.
- Cloudflare Quick Tunnels and Railway/Render do this correctly out of the box.

### Tunnel URL changed

Quick tunnels (Cloudflare `trycloudflare.com`, free ngrok) generate a new URL on each restart. Update the connector URL in Claude's settings, or use a named Cloudflare Tunnel / ngrok reserved domain for a stable URL.

### Cloud server is asleep (Render free tier)

Render's free tier sleeps after 15 minutes of inactivity. Wake it by opening the dashboard URL, or upgrade to a paid plan for always-on. Railway gives $5/month of free credits — the server uses ~50MB RAM, so it lasts the month.

## Security notes

- **Always set `MCP_AUTH_TOKEN`** for anything reachable from the internet. Without it, anyone with the URL can run arbitrary Luau in your Roblox client.
- The `/mobile-connector.luau` route is public (no auth) so executors can fetch the loader; every other route requires the Bearer token.
- The tunnel/cloud URL is public — only share it with AI clients you trust.
- This grants arbitrary code execution in your Roblox client. Only use it with experiences you own or have permission to test.
- Rotate the token periodically, and revoke it by changing `MCP_AUTH_TOKEN` and restarting the server.
