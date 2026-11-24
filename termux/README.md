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
curl -fsSL https://<your-deployment>.up.railway.app/termux/agent.sh -o agent.sh
export MCP_AGENT_TOKEN=<the same token>
bash agent.sh          # foreground
```

Keep it alive across sessions:

```bash
mkdir -p ~/.mcp-agent
nohup bash agent.sh >> ~/.mcp-agent/agent.log 2>&1 &
```

Optional environment variables:

- `MCP_AGENT_BRIDGE` — bridge base URL (defaults to the public deployment)
- `MCP_AGENT_NAME` — friendly name shown in `list-clients` (defaults to device model)
- `MCP_AGENT_TOKEN` — the shared secret (required)

## Security model

- The agent only registers when the token matches the server's `TERMUX_TOKEN`
  (constant-time compare, 401 on mismatch).
- The server never accepts inbound connections from the phone: the agent
  long-polls `/poll` and answers through `/respond`, exactly like the in-game
  connectors.
- Commands run as the Termux user (no root) with the timeout the `phone-shell`
  tool requested.
