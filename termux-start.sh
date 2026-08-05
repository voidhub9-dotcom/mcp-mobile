#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# Roblox Executor MCP - Mobile Launcher (Termux)
# 
# Starts the MCP server in HTTP mode + bridge server.
# Optionally starts ngrok/cloudflare tunnel for remote access.
#
# Usage:
#   bash termux-start.sh              # Start with ngrok (if available)
#   bash termux-start.sh --no-tunnel  # Start without tunnel
#   bash termux-start.sh --cf         # Start with cloudflare tunnel
# ═══════════════════════════════════════════════════════════════

set -e

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║   Roblox MCP - Mobile Launcher                             ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

USE_TUNNEL=true
USE_CLOUDFLARE=false

for arg in "$@"; do
    case $arg in
        --no-tunnel) USE_TUNNEL=false ;;
        --cf) USE_TUNNEL=true; USE_CLOUDFLARE=true ;;
    esac
done

# ─── Check build exists ───
if [ ! -f "dist/index.js" ]; then
    echo "→ Build not found. Building now..."
    npx tsc 2>&1 | tail -5
    node scripts/copy-assets.mjs 2>/dev/null || true
fi

if [ ! -f "dist/index.js" ]; then
    echo "✗ Build failed. Run 'bash termux-setup.sh' first."
    exit 1
fi

echo "→ Starting MCP Server in HTTP mode..."
echo "  Bridge + MCP: http://localhost:16384"
echo "  MCP endpoint: http://localhost:16384/mcp"
echo ""

# ─── Start ngrok if requested ───
TUNNEL_URL=""
if $USE_TUNNEL; then
    if $USE_CLOUDFLARE; then
        echo "→ Starting Cloudflare Quick Tunnel..."
        echo "  (This creates a free public HTTPS URL)"
        cloudflared tunnel --url http://localhost:16384 > /tmp/cf-tunnel.log 2>&1 &
        CF_PID=$!
        echo "  Waiting for tunnel URL..."
        sleep 5
        TUNNEL_URL=$(grep -o 'https://[^ ]*trycloudflare.com' /tmp/cf-tunnel.log 2>/dev/null | head -1)
        if [ -n "$TUNNEL_URL" ]; then
            echo "  ✓ Cloudflare tunnel: $TUNNEL_URL/mcp"
        else
            echo "  ✗ Cloudflare tunnel failed. Check /tmp/cf-tunnel.log"
            echo "  Continuing without tunnel..."
            kill $CF_PID 2>/dev/null || true
        fi
    elif command -v ngrok &> /dev/null; then
        echo "→ Starting ngrok tunnel..."
        ngrok http 16384 > /tmp/ngrok-tunnel.log 2>&1 &
        NGROK_PID=$!
        echo "  Waiting for tunnel URL..."
        sleep 3
        TUNNEL_URL=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null | grep -o 'https://[^"]*' | head -1)
        if [ -n "$TUNNEL_URL" ]; then
            echo "  ✓ ngrok tunnel: $TUNNEL_URL/mcp"
        else
            echo "  ✗ ngrok tunnel failed."
            echo "  Continuing without tunnel..."
            kill $NGROK_PID 2>/dev/null || true
        fi
    else
        echo "! ngrok/cloudflared not installed."
        echo "  Install ngrok:   pip install pyngrok && ngrok authtoken YOUR_TOKEN"
        echo "  Install cloudflared: pkg install cloudflared"
        echo "  Or use --no-tunnel to skip."
        echo ""
    fi
fi

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║   Server is starting!                                      ║"
echo "╠════════════════════════════════════════════════════════════╣"
echo ""

if [ -n "$TUNNEL_URL" ]; then
    echo "  🌐 Public MCP URL: $TUNNEL_URL/mcp"
    echo ""
    echo "  Add this to your AI client (Claude/ChatGPT):"
    echo "  {"
    echo "    \"mcpServers\": {"
    echo "      \"roblox\": {"
    echo "        \"type\": \"http\","
    echo "        \"url\": \"$TUNNEL_URL/mcp\""
    echo "      }"
    echo "    }"
    echo "  }"
    echo ""
fi

echo "  📱 In your Roblox executor (Delta/CodeX), run:"
echo ""
echo "     loadstring(game:HttpGet("
echo "       'http://localhost:16384/mobile-connector.luau'"
echo "     ))('localhost:16384')"
echo ""
echo "  📊 Dashboard: http://localhost:16384/"
echo "  🤖 Custom AI chat: http://localhost:16384/ai"
if [ -n "$CUSTOM_AI_API_KEY" ]; then
    echo "  ✓ Custom AI API key set (env)"
else
    echo "  ℹ Set CUSTOM_AI_API_KEY env var or paste key in chat UI Settings"
fi
echo ""
echo "  Press Ctrl+C to stop."
echo ""
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# ─── Start the MCP server ───
exec node dist/index.js --http
