#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# Roblox Executor MCP - Termux Setup Script (Mobile-Only)
# 
# Run this in Termux on your Android phone to set up the entire
# MCP server without needing a PC.
#
# Usage:
#   pkg install git -y && git clone <repo> && cd roblox-executor-mcp && bash termux-setup.sh
# ═══════════════════════════════════════════════════════════════

set -e

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║   Roblox Executor MCP - Mobile Setup (Termux)            ║"
echo "║   No PC needed - everything runs on your phone             ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# ─── Check Termux ───
if [ -z "$TERMUX_VERSION" ]; then
    echo "✗ This script must be run in Termux."
    echo "  Install Termux from F-Droid: https://f-droid.org/packages/com.termux/"
    exit 1
fi

echo "→ Detected Termux $TERMUX_VERSION"

# ─── Install Node.js ───
echo "→ Checking Node.js..."
if ! command -v node &> /dev/null; then
    echo "→ Installing Node.js..."
    pkg install nodejs -y
else
    echo "  Node.js already installed: $(node --version)"
fi

# ─── Install git if needed ───
if ! command -v git &> /dev/null; then
    echo "→ Installing git..."
    pkg install git -y
fi

# ─── Install dependencies ───
echo "→ Installing npm dependencies..."
npm install --ignore-scripts 2>&1 | tail -3

# ─── Build ───
echo "→ Building TypeScript..."
npx tsc 2>&1 | tail -5
node scripts/copy-assets.mjs 2>/dev/null || true

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║   Setup Complete!                                          ║"
echo "╠════════════════════════════════════════════════════════════╣"
echo "║                                                            ║"
echo "║   To start the MCP server:                                 ║"
echo "║                                                            ║"
echo "║     bash termux-start.sh                                   ║"
echo "║                                                            ║"
echo "║   This starts:                                             ║"
echo "║   1. MCP Server (HTTP mode) on port 3001                   ║"
echo "║   2. Bridge server on port 16384                           ║"
echo "║   3. ngrok tunnel (if installed) for remote access        ║"
echo "║                                                            ║"
echo "║   Then in your Roblox executor (Delta/CodeX), run:        ║"
echo "║                                                            ║"
echo "║     loadstring(game:HttpGet(                               ║"
echo "║       'http://localhost:16384/mobile-connector.luau'       ║"
echo "║     ))('localhost:16384')                                  ║"
echo "║                                                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
