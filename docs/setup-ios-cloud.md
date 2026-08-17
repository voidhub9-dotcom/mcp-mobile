# iOS Setup (Cloud Deployment)

> Run the MCP server in the cloud — your iPhone's Roblox executor and your AI client both connect to it over HTTPS. No PC or local server needed.

Since iOS doesn't have Termux, the MCP server runs on a free cloud service instead. Your iPhone connects to it just like any other website.

```
Cloud (Railway/Render):
  ┌─────────────────────────────────────────┐
  │  MCP Server (HTTP mode)                  │
  │  Port 16384                              │
  │  ┌─────────────┐  ┌──────────────────┐  │
  │  │ /mcp         │  │ /register        │  │
  │  │ (Claude.ai)  │  │ /poll /respond   │  │
  │  │              │  │ (Roblox)         │  │
  │  └─────────────┘  └──────────────────┘  │
  │  ┌─────────────────────────────────────┐  │
  │  │ /mobile-connector.luau (loader)     │  │
  │  └─────────────────────────────────────┘  │
  └─────────────────────────────────────────┘
        ▲                          ▲
        │ HTTPS                    │ HTTPS
   ┌────┴────┐              ┌──────┴──────┐
   │ Claude  │              │  iPhone     │
   │ .ai     │              │  Delta/CodeX│
   └─────────┘              └─────────────┘
```

## Prerequisites

- An **iPhone** (or any device) with a mobile Roblox executor (Delta, CodeX, etc.)
- A **GitHub account** (to fork the repo and deploy)
- A **Claude Pro or Max plan** (required for custom connectors on claude.ai)

## Step 1: Fork the Repository

1. Open Safari on your iPhone
2. Go to [github.com/voidhub9-dotcom/mcp-mobile](https://github.com/voidhub9-dotcom/mcp-mobile)
3. Tap **Fork** in the top right
4. You now have your own copy at `github.com/YOUR_USERNAME/mcp-mobile`

## Step 2: Deploy to Railway (Free)

Railway gives you a free public HTTPS URL for your server.

1. Open [railway.app](https://railway.app) in Safari
2. Tap **Login** and sign in with your GitHub account
3. Tap **New Project**
4. Select **Deploy from GitHub repo**
5. Choose your fork: `YOUR_USERNAME/mcp-mobile`
6. Railway auto-detects the `Dockerfile` and starts building
7. Wait 2-3 minutes for the build to complete
8. Go to **Settings > Networking > Generate Domain**
9. You now have a URL like `https://mcp-mobile-production.up.railway.app`

### Set the auth token (important for security)

1. In Railway, go to your project > **Variables**
2. Add a variable:
   - Key: `MCP_AUTH_TOKEN`
   - Value: any random string (e.g., type 20 random characters)
3. The server auto-restarts with the new token

## Alternative: Deploy to Render (Free)

1. Open [render.com](https://render.com) in Safari
2. Sign in with GitHub
3. Tap **New +** > **Web Service**
4. Connect your GitHub repo: `YOUR_USERNAME/mcp-mobile`
5. Render auto-detects `render.yaml` — just confirm the settings
6. Add environment variable `MCP_AUTH_TOKEN` with a random string
7. Tap **Create Web Service**
8. Wait for deployment — you get a URL like `https://mcp-mobile.onrender.com`

## Step 3: Connect Your iPhone's Roblox Executor

In your mobile Roblox executor (Delta, CodeX, etc.), run:

```lua
-- Set your cloud URL and auth token
getgenv().BridgeURL = "https://YOUR-APP.up.railway.app"
getgenv().MCP_AUTH_TOKEN = "YOUR_TOKEN_HERE"

-- Load the connector
loadstring(game:HttpGet("https://YOUR-APP.up.railway.app/mobile-connector.luau"))()
```

Replace `YOUR-APP.up.railway.app` with your actual Railway/Render URL, and `YOUR_TOKEN_HERE` with the auth token you set.

The connector automatically:
- Uses HTTPS (no need to add `http://` prefix)
- Sends your auth token on every request
- Falls back to HTTP polling if WebSocket is unavailable

## Step 4: Connect Claude (claude.ai) as a Custom Connector

This is the recommended way to use the server — Claude's web interface connects directly to your cloud MCP endpoint over HTTPS. No JSON config files needed.

### Add the connector in Claude

1. Go to [claude.ai](https://claude.ai) in your browser
2. Click your profile picture (bottom left) > **Settings**
3. Go to the **Connectors** tab
4. Click **Add custom connector**
5. Fill in the fields:
   - **Name:** `Roblox MCP`
   - **Remote MCP server URL:** `https://YOUR-APP.up.railway.app/mcp?token=YOUR_TOKEN_HERE`
   - Expand **Advanced settings**
   - **OAuth Client ID:** leave blank
   - **OAuth Client Secret:** leave blank
6. Click **Add**
7. The connector should now show as **Connected**

> **Important:** Claude's custom connector dialog does not support custom headers (like `Authorization: Bearer ...`). Instead, pass your auth token as a `?token=` query parameter in the URL. The server accepts both methods.
>
> **Note:** Custom connectors require a **Claude Pro or Max** plan, or an Owner/Primary Owner role on a Team/Enterprise plan. Free tier does not support custom connectors.

### Verify the connection

1. Start a new chat in Claude
2. You should see a **Roblox MCP** tool icon in the chat toolbar
3. Try asking: "List my connected Roblox clients" — Claude will call the `list-clients` tool
4. If you get a response with your client info, everything is working

### What Claude can do

Once connected, Claude can:
- Execute Luau code in your Roblox game
- Inspect and decompile scripts
- Search instances and game hierarchy
- Take screenshots and visually analyze them
- Scan for anti-cheat systems
- Get player state, game GUIs, and game systems
- Click buttons and type into text boxes
- Spy on remote events
- Keep you in the game (anti-AFK is enabled by default)

### Alternative: Use the Built-in Custom AI Chat

The server also includes a built-in AI chat at `/ai` that supports any Anthropic-compatible API:

1. Add `CUSTOM_AI_API_KEY` as an environment variable in Railway/Render
2. Open `https://YOUR-APP.up.railway.app/ai` in your browser
3. Configure your API key and model in Settings
4. Start chatting — same tool access as Claude

## Step 5: Use It

Now you can chat with Claude.ai and it can:
- Execute Luau code in your Roblox game
- Inspect game state (instances, scripts, console output)
- Search for instances and UI elements
- Interact with GUI (click buttons, type text)
- Get game info and capabilities

## Quick Reference

| What | URL / Command |
|------|---------------|
| Cloud server | `https://YOUR-APP.up.railway.app` |
| Claude connector URL | `https://YOUR-APP.up.railway.app/mcp` |
| Built-in AI chat | `https://YOUR-APP.up.railway.app/ai` |
| Dashboard | `https://YOUR-APP.up.railway.app/` |
| Roblox loader | `loadstring(game:HttpGet("https://YOUR-APP.up.railway.app/mobile-connector.luau"))()` |

## Troubleshooting

### Claude says "Connector failed" or "Unauthorized"
- Make sure you included `?token=YOUR_TOKEN_HERE` in the connector URL — Claude can't send custom headers, so the token must be in the query parameter
- The token must match the `MCP_AUTH_TOKEN` env var on your server exactly
- Remove any `Mcp-Session-Id` header — it's managed automatically by Claude

### Claude says "No Roblox client connected"
- Load the connector script in your Roblox executor first (Step 3)
- Check the dashboard at `https://YOUR-APP.up.railway.app/` to see if your client shows up
- Make sure `getgenv().BridgeURL` and `getgenv().MCP_AUTH_TOKEN` are set correctly before loading the connector

### Server won't start on Railway/Render
- Check the build logs in the Railway/Render dashboard
- Make sure the port is set to `16384` (should be automatic via `PORT` env var)
- If using a different platform, set `PORT=16384` as an environment variable

### Roblox can't connect
- Make sure you set `getgenv().BridgeURL` to the full HTTPS URL including `https://`
- Make sure you set `getgenv().MCP_AUTH_TOKEN` to match the server's `MCP_AUTH_TOKEN`
- Try loading the connector URL in Safari first to verify it serves the Luau script

### "Unauthorized" errors
- The auth token on the server and in `getgenv().MCP_AUTH_TOKEN` must match exactly
- The `/mobile-connector.luau` route is public (no auth needed to fetch the script)
- All other routes (register, poll, respond, /mcp) require the Bearer token

### Server goes to sleep (Render free tier)
Render's free tier sleeps after 15 minutes of inactivity. To wake it:
- Just send any request (e.g., open the dashboard URL in Safari)
- Consider upgrading to a paid plan for always-on

### Railway free tier limits
Railway gives $5 of free credits per month. The server uses minimal resources (~50MB RAM), so it should last the full month.

## Security Notes

- **Always set `MCP_AUTH_TOKEN`** when deploying to the cloud — without it, anyone with the URL can execute code in your Roblox client
- The tunnel URL is public — only share it with AI clients you trust
- This allows arbitrary code execution in your Roblox client
- Only use with Roblox experiences you own or have permission to test
- Rotate the auth token periodically

## Experimental: iSH (Local iOS Server)

iSH is an Alpine Linux shell for iOS that can run some Linux binaries. It's slow and limited, but can run Node.js for local testing.

1. Install [iSH](https://apps.apple.com/us/app/ish-shell/id1436802278) from the App Store
2. In iSH:
```bash
apk add nodejs npm git
git clone https://github.com/YOUR_USERNAME/mcp-mobile.git
cd mcp-mobile
npm install --ignore-scripts
npx tsc
node dist/index.js --http
```

**Limitations of iSH:**
- Very slow (Node.js runs in emulated x86)
- iOS will kill iSH in the background after a few minutes
- No WebSocket support (HTTP polling works fine though)
- Not recommended for production use

The cloud deployment approach above is strongly recommended over iSH.
