# Termux Agent

The Termux agent gives the MCP server a remote shell on the phone. It runs as
its own bridge client (shown in `list-clients` as `mobile=termux-agent/android`)
and serves the `phone-shell` MCP tool: shell commands with stdout/stderr and
exit code, straight from an AI agent to your phone.

This closes the one gap in-game hops cannot: Roblox blocks client-initiated
teleports into universes owned by a different creator, so a connected client
can never jump into another game on its own. From the phone shell you can:

```bash
termux-open-url "roblox://placeId=2753915549/"                       # launch straight into any game
termux-open-url "roblox://placeId=2753915549&gameInstanceId=<jobId>" # target a specific server
```

plus everything else a non-root Termux shell can do.

## Server side

1. Generate a token: `openssl rand -hex 32`
2. Set it as the `TERMUX_TOKEN` environment variable on the deployment
   (Railway: Variables; Docker: `-e TERMUX_TOKEN=...`; Termux host: export it).
3. Redeploy. Until `TERMUX_TOKEN` is set, the agent registration endpoint
   refuses connections with a 503.

## Phone side

```bash
pkg install curl -y
mkdir -p ~/.mcp-agent
# save your token once so foreground, background, and boot starts all find it
echo 'MCP_AGENT_TOKEN=<the same token>' > ~/.mcp-agent/env
curl -fsSL https://<your-deployment>.up.railway.app/termux/agent.sh \
  -o ~/.mcp-agent/agent.sh
bash ~/.mcp-agent/agent.sh    # foreground test run
```

When it looks good, background it:

```bash
nohup bash ~/.mcp-agent/agent.sh >> ~/.mcp-agent/agent.log 2>&1 &
```

Optional environment variables (env vars win over `~/.mcp-agent/env`):

- `MCP_AGENT_BRIDGE` — bridge base URL (defaults to the public deployment)
- `MCP_AGENT_NAME` — friendly name shown in `list-clients` (defaults to device model)
- `MCP_AGENT_TOKEN` — the shared secret (required)

## Staying alive

Android is the enemy of long-running background processes. The agent already
acquires a wake lock (`termux-wake-lock`) and writes its pid to
`~/.mcp-agent/agent.pid`; the rest is phone configuration:

1. **Do not swipe Termux from recents**, just press Home. Swiping kills the
   process tree; backgrounding keeps the `nohup` agent alive.
2. **Exclude Termux from battery optimization** (Android Settings → Apps →
   Termux → Battery → Unrestricted). Without this Android will kill the agent
   within hours or minutes, wake lock or not.
3. **Survive reboots with Termux:Boot** (F-Droid addon):

```bash
# one time: install the Termux:Boot app from F-Droid and OPEN it once
mkdir -p ~/.termux/boot
curl -fsSL https://<your-deployment>.up.railway.app/termux/agent.sh \
  -o ~/.mcp-agent/agent.sh        # (agent must exist at ~/.mcp-agent/agent.sh)
curl -fsSL https://<your-deployment>.up.railway.app/termux/boot.sh -o ~/.termux/boot/mcp-agent.sh
chmod +x ~/.termux/boot/mcp-agent.sh
```

The boot hook waits 30s for the network, reuses `~/.mcp-agent/env`, refuses to
double-start (checks the pid file), and starts the agent in the background.

When in doubt, check `~/.mcp-agent/agent.log`.

## Security model

- The agent only registers when the token matches the server's `TERMUX_TOKEN`
  (constant-time compare, 401 on mismatch).
- The server never accepts inbound connections from the phone: the agent
  long-polls `/poll` and answers through `/respond`, exactly like the in-game
  connectors.
- Commands run as the Termux user (no root) with the timeout the `phone-shell`
  tool requested.
