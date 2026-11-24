#!/data/data/com.termux/files/usr/bin/bash
# ═══════════════════════════════════════════════════════════════
# mcp-mobile Termux agent boot hook (for the Termux:Boot addon).
#
# Survives device reboots: Termux:Boot runs this script automatically
# shortly after the phone starts.
#
# One-time install on the phone:
#   1. Install the Termux:Boot app from F-Droid and OPEN it once
#      (it only registers its hooks on first launch).
#   2. Save your token:
#         mkdir -p ~/.mcp-agent
#         echo 'MCP_AGENT_TOKEN=<TERMUX_TOKEN from the server>' > ~/.mcp-agent/env
#   3. Copy this hook into the Termux:Boot directory:
#         mkdir -p ~/.termux/boot
#         cp boot.sh ~/.termux/boot/mcp-agent.sh
#         chmod +x ~/.termux/boot/mcp-agent.sh
#      (Termux:Boot runs every executable script in ~/.termux/boot at boot.)
#
# Also exclude Termux from battery optimization or Android may kill
# the agent anyway.
# ═══════════════════════════════════════════════════════════════
set -u

sleep 30 # wait for the network to come up after boot

BASE="$HOME/.mcp-agent"
LOG="$BASE/agent.log"
ENV_FILE="$BASE/env"
AGENT="$BASE/agent.sh"

if [ ! -f "$AGENT" ]; then
    echo "[boot] $AGENT missing; nothing to start" >> "$LOG"
    exit 0
fi
if [ -f "$ENV_FILE" ]; then
    . "$ENV_FILE"
fi
if [ -z "${MCP_AGENT_TOKEN:-}" ]; then
    echo "[boot] MCP_AGENT_TOKEN missing in $ENV_FILE; not starting" >> "$LOG"
    exit 0
fi
# already running?
PIDFILE="$BASE/agent.pid"
if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE" 2>/dev/null)" 2>/dev/null; then
    exit 0
fi
echo "[boot] starting agent $(date)" >> "$LOG"
nohup bash "$AGENT" >> "$LOG" 2>&1 &
echo $! > "$PIDFILE"
