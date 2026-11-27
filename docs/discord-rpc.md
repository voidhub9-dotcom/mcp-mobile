# VoidHub RPC (Discord Rich Presence)

VoidHub RPC shows what your AI agent is doing as Discord Rich Presence. The **server** sets your presence, using Discord Social SDK OAuth2 (scopes `openid sdk.social_layer_presence`) and a headless presence session. Discord doesn't need to be running on the same machine, so this works on Railway, Render, a Termux phone server, or a PC.

It's optional. If the Discord variables aren't set, the server behaves exactly as before.

## What it looks like

| Field | Value |
|-------|-------|
| Activity | Playing **the Roblox game you're in** (e.g. `[🐟] Net a Fish!`), or **VoidHub RPC** when no game is connected |
| Details | `Using VoidHub` while in a game, or what the agent is doing right now for 2 minutes after each tool call (see [Tool → details](#tool--details)) |
| State | `Connected via VoidHub MCP` |
| Elapsed time | Since the first tool call of the current session |
| Large image | The icon of the **Roblox game you're in**, with the game's name as the tooltip. If no game is connected, or the icon can't be loaded, it shows `DISCORD_LARGE_IMAGE_KEY` with the tooltip `VoidHub MCP` |
| Small image | `DISCORD_LARGE_IMAGE_KEY` (your VoidHub logo) in the corner of the game icon, tooltip `VoidHub MCP` |
| Buttons | **See Game Page** → the game's Roblox page (when in a game), and **Get VoidHub** → `DISCORD_BUTTON_URL` (default `https://discord.gg/4AdJr8emK2`) |

## How it behaves

- **Starts as soon as a Roblox game connects.** The server checks every 5 seconds; when your connector is running in a game, the presence turns on with that game's name, icon and buttons. The line under the title says `Using VoidHub`. It stays on while the game is connected and clears when the game disconnects.
- Every MCP tool call updates the presence, at most once every **15 seconds**. If several calls land inside that window, Discord gets the most recent one.
- While tools keep running, the presence is re-sent every **2 minutes** so it doesn't lapse.
- After **5 minutes** with no tool calls, the presence session ends and the status disappears. The next tool call starts a new session with a fresh timer.
- **Tools are never slowed or failed by Discord.** If you haven't linked an account, the update is skipped. If Discord is down, slow (8 second limit), rate-limiting, or rejecting the token, the error is logged as `[Discord] ...` and the tool result is unchanged.
- The big image follows the game your active Roblox client is in. The icon comes from Roblox's public thumbnails API and is cached for an hour per game. When you change games, the next update shows the new icon. If Discord refuses the external image link, the server switches to your logo for the rest of the run.
- Access tokens refresh automatically when they're within 5 minutes of expiry, or if Discord rejects them.

## 1. Create the Discord application

1. Open <https://discord.com/developers/applications> and choose **New Application**. Discord shows the application name as the activity name, so "VoidHub RPC" is a good choice.
2. **Discord Social SDK → Getting Started**: fill in the form and enable the Social SDK. The `sdk.social_layer_presence` scope is rejected until this is on.
3. **OAuth2 → Redirects**: add the callback URL for your server (see the table below) and save. It must match `DISCORD_REDIRECT_URI` exactly.
4. **OAuth2**: copy the **Client ID**, then choose **Reset Secret** and copy the **Client Secret**.
5. **Rich Presence → Art Assets**: upload your logo with the key `void_logo`. Alternatively, set `DISCORD_LARGE_IMAGE_KEY` to an `https://` image URL.

| Where the server runs | Redirect URI |
|------|------|
| Railway | `https://YOUR-APP.up.railway.app/auth/discord/callback` |
| Render | `https://YOUR-APP.onrender.com/auth/discord/callback` |
| Custom domain or tunnel | `https://your-domain/auth/discord/callback` |
| Local PC, or a Termux phone server linked from the phone's browser | `http://localhost:16384/auth/discord/callback` |

Quick tunnels (`trycloudflare.com`) change URL on every restart, so you'd have to update the redirect each time. For a tunnel setup, the localhost redirect is usually easier: the link only has to happen once, from a browser on the same device as the server.

## 2. Set the variables

| Variable | Required | Example / default | Purpose |
|----------|----------|-------------------|---------|
| `DISCORD_CLIENT_ID` | yes | `1234567890123456789` | OAuth2 client ID |
| `DISCORD_CLIENT_SECRET` | yes | — | OAuth2 client secret |
| `DISCORD_REDIRECT_URI` | yes | `https://YOUR-APP.up.railway.app/auth/discord/callback` | Must match the portal redirect exactly |
| `TOKEN_ENCRYPTION_KEY` | yes | output of `openssl rand -hex 32` | 32-byte key that encrypts stored tokens (AES-256-GCM). Accepts 64 hex characters or base64 |
| `DISCORD_LARGE_IMAGE_KEY` | no | `void_logo` | Art Asset key or image URL. If no Art Asset with this key exists, the built-in VoidHub logo URL is used |
| `DISCORD_BUTTON_URL` | no | `https://discord.gg/4AdJr8emK2` | Link for the **Get VoidHub** button (`off` hides it) |
| `DISCORD_SHOW_GAME_BUTTON` | no | `true` | `false` hides the **See Game Page** button |
| `DISCORD_PRESENCE_PLATFORM` | no | `desktop` | Platform reported to Discord: `desktop`, `android`, `ios`, `xbox`, `ps4`, `ps5`, `samsung` or `embedded` |
| `DISCORD_SHOW_GAME_ICON` | no | `true` | Set to `false` to always use your logo as the big image instead of the current game's icon |
| `MCP_AUTH_TOKEN` | cloud: yes | — | Protects linking and unlinking (and the rest of the server) |
| `DISCORD_TOKEN_STORE_PATH` | no | the Railway Volume if attached, else `~/.roblox-mcp/discord-links.json` | Where encrypted tokens are saved |
| `DISCORD_PRESENCE_IDLE_MS` | no | `300000` | Idle time before the presence is cleared (1 to 60 minutes) |
| `DISCORD_PRESENCE_THROTTLE_MS` | no | `15000` | Minimum gap between updates (cannot go below 15000) |
| `DISCORD_PRESENCE_KEEPALIVE_MS` | no | `120000` | How often the presence is re-sent while active |

A commented template is in [`.env.example`](../.env.example).

### Railway

Open your service, go to **Variables**, add the variables above, and redeploy. Railway's disk is wiped on every deploy, so **attach a Volume** mounted at `/data`. The server detects it (`RAILWAY_VOLUME_MOUNT_PATH`) and saves the link there automatically, so you link once and it stays linked through redeploys and every game. Without a Volume, the VoidHub RPC page shows a red warning and you'd have to re-link after each deploy.

### Render

Open your service, go to **Environment**, and add the same variables. `render.yaml` already lists the Discord ones. Render's free tier has no persistent disk, so expect to re-link after each redeploy, or attach a paid Disk and point `DISCORD_TOKEN_STORE_PATH` at it.

### Local AI clients (Claude Desktop, Claude Code, Cursor, Windsurf, Codex, Antigravity, ZCode, BLACKBOX)

The AI client starts the server, so put the variables in the server's `env` block in the client's MCP config:

```json
{
  "mcpServers": {
    "roblox-mcp": {
      "command": "node",
      "args": ["/path/to/roblox-executor-mcp/dist/index.js", "--server-name", "roblox-mcp"],
      "env": {
        "DISCORD_CLIENT_ID": "1234567890123456789",
        "DISCORD_CLIENT_SECRET": "your-client-secret",
        "DISCORD_REDIRECT_URI": "http://localhost:16384/auth/discord/callback",
        "TOKEN_ENCRYPTION_KEY": "64-hex-characters-from-openssl-rand-hex-32",
        "DISCORD_BUTTON_URL": "https://your-site/void-hub"
      }
    }
  }
}
```

The other clients use the same keys in their own config format:
- **Codex** (`config.toml`): add an `[mcp_servers.roblox-executor-mcp.env]` table.
- **Claude Code**: pass `-e KEY=value` to `claude mcp add` for each variable.

Use the **same** `TOKEN_ENCRYPTION_KEY` for every client on the machine, because they share one token file. Restart the client after editing its config.

### Termux (Android)

Export the variables before starting the server, for example by adding them to `~/.bashrc`:

```bash
export DISCORD_CLIENT_ID=1234567890123456789
export DISCORD_CLIENT_SECRET=your-client-secret
export DISCORD_REDIRECT_URI=http://localhost:16384/auth/discord/callback
export TOKEN_ENCRYPTION_KEY=$(cat ~/.voidhub-rpc-key 2>/dev/null || (openssl rand -hex 32 | tee ~/.voidhub-rpc-key))
```

The last line creates the key once and reuses it on every start.

## 3. Link your account and test it

1. Open `/auth/discord` on your server, for example `https://YOUR-APP.up.railway.app/auth/discord` or `http://localhost:16384/auth/discord`.
2. If `MCP_AUTH_TOKEN` is set, enter it and choose **Continue**. You only do this once per device: the page remembers you for 30 days with a secure, HttpOnly cookie. **Sign out on this device** forgets it, and changing `MCP_AUTH_TOKEN` signs every device out.
   Then choose **Link Discord**.
3. Approve on Discord. You'll land on a **Discord linked** page.
4. Back on the VoidHub RPC page, choose **Send test presence**. The server sends **Testing VoidHub RPC** to Discord right away and shows Discord's answer:
   - **Test sent**: open your Discord profile. You should see **Playing VoidHub RPC**. If a Roblox client is connected, the big image is that game's icon.
   - **Discord said no**: the page shows Discord's exact error. See [Troubleshooting](#troubleshooting).
5. After that, any MCP tool call (from Claude, the built-in `/ai` chat, or any MCP client) updates the presence automatically.

The page also shows your link status, whether the presence is live, the connected Roblox game, and a preview of how your Discord card looks.

To remove the link, open `/auth/discord` and choose **Unlink Discord**, or use curl:

```bash
curl -X POST -H "Authorization: Bearer $MCP_AUTH_TOKEN" https://YOUR-APP.up.railway.app/auth/discord/unlink
```

Unlinking clears the live presence, revokes the tokens at Discord, and deletes them from storage.

## Endpoints

| Method | Path | Auth (when `MCP_AUTH_TOKEN` is set) | What it does |
|--------|------|------|--------------|
| `GET` | `/auth/discord` | Sign-in form, then the remembered-device cookie | The VoidHub RPC page: status, presence preview, and buttons |
| `GET` | `/auth/discord?start=1` | Cookie | Redirects straight to Discord with a one-time CSRF `state` |
| `POST` | `/auth/discord` | `action=login` with `server_token`, otherwise the cookie | `login` (remember this device), `link` (go to Discord), `logout` |
| `GET` | `/auth/discord/callback` | CSRF `state` (10 min, single use) | Exchanges the `code`, then stores encrypted access and refresh tokens |
| `POST` | `/auth/discord/test` | Bearer header, `server_token` field, or the cookie | Sends a **Testing VoidHub RPC** presence immediately (no throttle) and returns Discord's answer |
| `POST` | `/auth/discord/unlink` | Bearer header, `server_token` field, or the cookie | Clears the presence, revokes the tokens, deletes them |
| `GET` | `/auth/discord/status` | Bearer header or the cookie | JSON health check (below) |

```bash
curl -H "Authorization: Bearer $MCP_AUTH_TOKEN" https://YOUR-APP.up.railway.app/auth/discord/status
```

```json
{
  "configured": true,
  "tokenStorage": true,
  "enabled": true,
  "linked": true,
  "discordUserId": "123456789012345678",
  "tokenExpiresAt": "2026-12-04T12:00:00.000Z",
  "presence": { "active": true, "pushInFlight": false, "pushScheduled": false, "details": "Making a script", "sessionStart": 1764240000000, "lastActivityAt": 1764240120000 }
}
```

## Tool → details

The line under the game name follows what the AI is doing:

| Stage | Shown on Discord | Triggered by |
|------|------|------|
| In game | Using VoidHub | A Roblox game is connected and nothing else is happening |
| Exploring | 🔍 Exploring the game | `get-game-info`, `get-player-state`, `get-game-guis`, `search-instances`, `get-descendants-tree`, `find-game-systems`, `trace-game-activity`, `research-game`, screenshots |
| Reading | 📜 Reading game scripts | `get-script-content`, `script-grep`, `semantic-search-scripts`, `get-ai-script-context` |
| Spying | 📡 Spying on remotes | `remote-spy`, `decrypt-remote` |
| Building | 🛠️ Building a script | `execute`, `execute-file` |
| Testing | 🧪 Testing features | `get-data-by-code`, `get-console-output`, `click-button`, `type-text-box` |
| Fixing | 🐞 Fixing a bug | A building/testing tool returned an error |
| Finished | ✅ Finished a script | Building/testing/fixing went quiet for 90 seconds (stays 15 minutes) |
| Anti-cheat | 🛡️ Checking anti-cheat | `scan-anticheat`, `anticheat-bypass` |
| Hopping | 🌍 Hopping servers | `server-hop` |

Housekeeping tools (`list-clients`, `set-active-client`, `anti-afk`, …) don't change the line. A stage stays for 2 minutes after its last tool call.

### The AI's own status: `discord-status`

The AI can set an exact line with the `discord-status` MCP tool, for example `phase=building, status="Building Pet Sim auto-farm"` shows **🛠️ Building Pet Sim auto-farm**, and `phase=finished, status="Finished auto-farm script"` shows **✅ Finished auto-farm script**. The server's MCP instructions tell the AI to call it at milestones (start building, testing, fixing, finished). A custom status wins over the automatic stages for 10 minutes or until replaced; `action=clear` goes back to automatic.

To change the automatic wording, edit `STAGE_TEXT` in [`src/discord/discordPresence.ts`](../src/discord/discordPresence.ts) and `STAGE_BY_TOOL` in [`src/discord/tool-hook.ts`](../src/discord/tool-hook.ts).

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| "Discord linking is not configured" | One of `DISCORD_CLIENT_ID`, `DISCORD_CLIENT_SECRET`, `DISCORD_REDIRECT_URI` or `TOKEN_ENCRYPTION_KEY` is missing. Add it and restart or redeploy. |
| Discord shows "Invalid OAuth2 redirect_uri" | The redirect in the Developer Portal doesn't match `DISCORD_REDIRECT_URI` exactly. Check the scheme, host, port, and that there's no trailing slash. |
| Discord says the scope is invalid | The Social SDK isn't enabled for the app (step 1.2). |
| "Discord linking failed" after approving | Usually a wrong `DISCORD_CLIENT_SECRET` or a redirect mismatch. The server log shows Discord's exact error. |
| "Link expired" | The link page was open for more than 10 minutes, or the server restarted mid-flow. Start again at `/auth/discord`. |
| `linked: false` after a redeploy | The token file was wiped. Add a volume and set `DISCORD_TOKEN_STORE_PATH`. |
| "Could not decrypt stored token" in logs | `TOKEN_ENCRYPTION_KEY` changed. Link again. |
| Big image shows your logo, not the game | No Roblox client is connected (check the dashboard), the icon lookup failed, or Discord refused the image link. If it was refused, the server log has a `[Discord] Discord rejected the game icon URL` line. |
| Test says **Discord said no** with `400 Invalid Form Body` | Discord wants a field the server doesn't send yet. Send the exact error text to the maintainer. |
| Test says **Discord said no** with `401` | The token was revoked or expired and couldn't refresh. Unlink, then link again. |
| Test says **Discord said no** with `403` or `404` | The Social SDK isn't enabled for the app, or Discord doesn't allow this kind of presence for your app yet. Send the exact error text to the maintainer. |
| No **Get VoidHub** / **See Game Page** buttons on your profile | Discord never shows Rich Presence buttons on **your own** profile. Ask a friend to look, or open **What Discord saved** on the VoidHub RPC page to see the buttons Discord stored. |
| Linked, but nothing on your profile | Presence only appears while tools are running. Check `/auth/discord/status`. Look for `[Discord]` errors in the server log, and make sure **User Settings → Activity Privacy → Share your detected activities with others** is on in Discord. |
| `[Discord] ... rate limited` | Raise `DISCORD_PRESENCE_THROTTLE_MS`. |

## Security

- Tokens are encrypted at rest with AES-256-GCM using `TOKEN_ENCRYPTION_KEY`, written with `0600` permissions, and never returned by any endpoint.
- Keep `TOKEN_ENCRYPTION_KEY` and `DISCORD_CLIENT_SECRET` in your host's variable settings or the client's `env` block. Never commit them.
- The remembered-device cookie is HttpOnly, `SameSite=Lax`, `Secure` over HTTPS, scoped to `/auth/discord`, and signed with a key derived from `MCP_AUTH_TOKEN`. Requests that carry the cookie from another website are rejected.
- On a public deployment, set `MCP_AUTH_TOKEN`. It's what stops strangers from linking their own Discord account to your server or unlinking yours.
- The server has one shared `MCP_AUTH_TOKEN`, so each deployment links **one** Discord account.
- Unlinking revokes the grant at Discord. You can also remove it yourself under Discord **User Settings → Authorized Apps**.

## Implementation notes

- `src/discord/discordPresence.ts`: the session manager (throttle, keepalive, idle clear, headless-session calls).
- `src/discord/oauth.ts`: authorize URL, code exchange, refresh, revoke.
- `src/discord/token-store.ts`: the encrypted JSON store. Other server processes sharing the file see link changes within 30 seconds.
- `src/discord/game-icon.ts`: looks up the current game's icon (`thumbnails.roblox.com/v1/places/gameicons`).
- `src/discord/tool-hook.ts`: wraps `server.registerTool` so every tool call fires `updateUserPresence()` before the tool runs, without waiting on Discord.
- `src/http/routes/auth/discord/*`: the HTTP routes.
- Presence uses `POST /users/@me/headless-sessions` (with `{ activities, token? }`) and `POST /users/@me/headless-sessions/delete` (with `{ token }`). The paths are constants at the top of `discordPresence.ts`. If Discord rejects the button format, the server drops the button and keeps updating presence.
