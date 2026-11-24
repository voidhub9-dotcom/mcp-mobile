#!/data/data/com.termux/files/usr/bin/bash
# ═══════════════════════════════════════════════════════════════
# mcp-mobile Termux Agent
#
# Long-polls the mcp-mobile bridge and executes `phone-shell`
# commands, giving an AI agent remote shell access to the phone.
# The agent registers as its own bridge client (termux-agent).
#
# Configure (env or edit the defaults below):
#   export MCP_AGENT_BRIDGE="https://<your-deployment>.up.railway.app"
#   export MCP_AGENT_TOKEN="<TERMUX_TOKEN configured on the server>"
#   export MCP_AGENT_NAME="pixel"   # optional, defaults to device model
#
# Run in the foreground:
#   bash agent.sh
#
# Keep alive across sessions:
#   mkdir -p ~/.mcp-agent
#   nohup bash agent.sh >> ~/.mcp-agent/agent.log 2>&1 &
# ═══════════════════════════════════════════════════════════════
set -u

BRIDGE="${MCP_AGENT_BRIDGE:-https://mcp-mobile-production200.up.railway.app}"
TOKEN="${MCP_AGENT_TOKEN:-}"
NAME="${MCP_AGENT_NAME:-$(getprop ro.product.model 2>/dev/null | tr ' ' '-')}"
[ -z "$NAME" ] && NAME="android-phone"

if [ -z "$TOKEN" ]; then
    echo "[agent] MCP_AGENT_TOKEN is not set."
    echo "[agent] Set it to the same value as the TERMUX_TOKEN environment variable on the mcp server."
    exit 1
fi

command -v python3 >/dev/null 2>&1 || {
    echo "[agent] python3 not found, installing..."
    pkg install -y python
}

exec python3 - "$BRIDGE" "$TOKEN" "$NAME" <<'PYEOF'
import json
import os
import subprocess
import sys
import time
import urllib.error
import urllib.request

BRIDGE = sys.argv[1].rstrip("/")
TOKEN = sys.argv[2]
NAME = sys.argv[3]


def log(msg):
    print(f"[agent] {msg}", flush=True)


def http(method, path, body=None, timeout=25):
    url = BRIDGE + path
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method)
    if data is not None:
        req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            raw = resp.read()
            return resp.status, (raw.decode("utf-8", "replace") if raw else "")
    except urllib.error.HTTPError as e:
        # HTTP errors are answers, not exceptions: surface status and body.
        raw = e.read()
        return e.code, (raw.decode("utf-8", "replace") if raw else "")


def register():
    while True:
        try:
            status, text = http("POST", "/termux/register", {"token": TOKEN, "name": NAME})
            if status == 200:
                client_id = json.loads(text)["clientId"]
                log(f"registered as '{NAME}', clientId={client_id}")
                return client_id
            body = text.strip()
            if status == 503:
                log("server refused: TERMUX_TOKEN is not configured on the server side.")
                log("Add TERMUX_TOKEN as an environment variable on the mcp server and redeploy, then retry.")
                sys.exit(2)
            if status == 401:
                log("invalid token (401). MCP_AGENT_TOKEN must match the server TERMUX_TOKEN.")
                sys.exit(3)
            log(f"register failed ({status}) {body[:120]}, retrying in 5s")
        except Exception as e:
            log(f"register error: {e}, retrying in 5s")
        time.sleep(5)


def respond(payload):
    for _ in range(3):
        try:
            status, _ = http("POST", "/respond", payload)
            if status == 200:
                return
            log(f"respond failed ({status})")
        except Exception as e:
            log(f"respond error: {e}, retrying")
        time.sleep(1)


def run_shell(msg):
    try:
        timeout_ms = int(msg.get("timeoutMs") or 30000)
    except (TypeError, ValueError):
        timeout_ms = 30000
    timeout_ms = max(1000, min(timeout_ms, 600000))
    cwd = msg.get("cwd")
    try:
        if cwd and not os.path.isdir(cwd):
            respond({"id": msg.get("id"), "error": f"cwd does not exist: {cwd}"})
            return
        proc = subprocess.run(
            ["bash", "-lc", msg["command"]],
            capture_output=True,
            text=True,
            timeout=timeout_ms / 1000.0 + 2.0,
            cwd=cwd or None,
        )
        text = proc.stdout or ""
        err = proc.stderr or ""
        if err:
            text += ("\n" if text else "") + "[stderr]\n" + err
        text += f"\n[exit: {proc.returncode}]"
        respond({"id": msg.get("id"), "output": text, "exitCode": proc.returncode})
    except subprocess.TimeoutExpired:
        respond({"id": msg.get("id"), "error": f"command timed out after {timeout_ms}ms"})
    except Exception as e:
        respond({"id": msg.get("id"), "error": f"agent error: {e}"})


def main():
    log(f"termux agent starting, bridge={BRIDGE}")
    client_id = register()
    log("polling for jobs...")
    while True:
        try:
            status, text = http("GET", f"/poll?clientId={client_id}", timeout=20)
            if status == 404:
                log("server lost our registration, re-registering")
                client_id = register()
                continue
            if status == 204:
                continue
            for item in json.loads(text):
                msg = item if isinstance(item, dict) else json.loads(item)
                if msg.get("type") == "phone-shell":
                    log(f"$ {msg.get('command')}")
                    run_shell(msg)
                else:
                    respond({
                        "id": msg.get("id"),
                        "error": f"termux agent does not handle message type {msg.get('type')}",
                    })
        except KeyboardInterrupt:
            log("agent stopped")
            return
        except Exception as e:
            log(f"poll error: {e}, retrying in 3s")
            time.sleep(3)


main()
PYEOF
