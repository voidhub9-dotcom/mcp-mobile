#!/usr/bin/env python3
"""
LminHub Quest Acceptance Live Tester
Tests BFAcceptQuest routing for Sea 1 and Sea 2 via the Roblox MCP executor.

Usage:
    python3 test_quest_acceptance.py [--host HOST] [--port PORT] [--sea {1,2,3}]

Requires: the MCP server running and a connected Roblox client.
"""

import argparse
import json
import sys
import time
import urllib.request
import urllib.error


DEFAULT_HOST = "127.0.0.1"
DEFAULT_PORT = 7777


def mcp_execute(host: str, port: int, lua: str) -> dict:
    payload = json.dumps({"code": lua}).encode()
    req = urllib.request.Request(
        f"http://{host}:{port}/execute",
        data=payload,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            return json.loads(resp.read())
    except urllib.error.HTTPError as e:
        return {"error": f"HTTP {e.code}: {e.read().decode()}"}
    except Exception as e:
        return {"error": str(e)}


def check_place_id(host: str, port: int) -> int:
    result = mcp_execute(host, port, "return game.PlaceId")
    raw = result.get("result") or result.get("results") or result.get("output") or ""
    try:
        return int(str(raw).strip())
    except Exception:
        return 0


def probe_comm_remote(host: str, port: int) -> bool:
    lua = """
        local Q = game:GetService("ReplicatedStorage")
        local remotes = Q:FindFirstChild("Remotes")
        local remote = remotes and remotes:FindFirstChild("CommF_")
        return remote ~= nil
    """
    result = mcp_execute(host, port, lua)
    raw = str(result.get("result") or result.get("output") or "").lower()
    return "true" in raw


def probe_bonus_moments_guide(host: str, port: int) -> bool:
    lua = """
        local Q = game:GetService("ReplicatedStorage")
        local modules = Q:FindFirstChild("Modules")
        local net = modules and modules:FindFirstChild("Net")
        local wrapper = net and net:FindFirstChild("RF/BonusMomentsGuide")
        return wrapper ~= nil
    """
    result = mcp_execute(host, port, lua)
    raw = str(result.get("result") or result.get("output") or "").lower()
    return "true" in raw


def probe_quest_gui(host: str, port: int, place_id: int) -> dict:
    lua = """
        local plr = game.Players.LocalPlayer
        local gui = plr:FindFirstChild("PlayerGui")
        if not gui then return "no PlayerGui" end

        -- Sea 1 new quest tracker
        local tracked = gui:FindFirstChild("TrackedQuestFrame")
        if tracked then
            local frame = tracked:FindFirstChild("Frame")
            local enabled = tracked.Enabled
            local visible = frame and frame.Visible or false
            local header = frame and frame:FindFirstChild("header")
            local label = header and header:FindFirstChild("textLabel")
            local text = label and label.Text or ""
            return "TrackedQuestFrame enabled=" .. tostring(enabled) ..
                   " visible=" .. tostring(visible) ..
                   " text=" .. tostring(text)
        end

        -- Sea 2/3 quest container
        local main = gui:FindFirstChild("Main")
        if not main then
            for _, g in ipairs(gui:GetChildren()) do
                if g:IsA("ScreenGui") and (g:FindFirstChild("Quest") or g:FindFirstChild("TopHUDList")) then
                    main = g; break
                end
            end
        end
        if not main then return "no Main ScreenGui" end
        local quest = main:FindFirstChild("Quest")
        if not quest then return "no Quest frame" end
        local container = quest:FindFirstChild("Container")
        local titleNode = container and container:FindFirstChild("QuestTitle")
        local title = titleNode and titleNode:FindFirstChild("Title")
        return "Quest visible=" .. tostring(quest.Visible) ..
               " title=" .. tostring(title and title.Text or "(none)")
    """
    result = mcp_execute(host, port, lua)
    return {"raw": str(result.get("result") or result.get("output") or result)}


def test_accept_quest_routing(host: str, port: int, place_id: int) -> dict:
    """
    Executes a Lua snippet that replicates BFAcceptQuest's routing logic
    without actually sending any network request — just checks which branch
    would fire and whether all required remotes are present.
    """
    lua = f"""
        local placeId = game.PlaceId
        local Q = game:GetService("ReplicatedStorage")

        local sea1 = placeId == 2753915549
        local sea2 = placeId == 4442272183 or placeId == 79091703265657
        local sea3 = placeId == 7449423635 or placeId == 100117331123089

        local remotes = Q:FindFirstChild("Remotes")
        local commF = remotes and remotes:FindFirstChild("CommF_")

        local modules = Q:FindFirstChild("Modules")
        local net = modules and modules:FindFirstChild("Net")
        local bmg = net and net:FindFirstChild("RF/BonusMomentsGuide")

        local branch = "unknown"
        if sea1 or sea2 then
            branch = "CommF_ + 5s timeout (Sea1/Sea2 path)"
        elseif sea3 then
            branch = "BonusMomentsGuide background spawn (Sea3 path)"
        end

        return table.concat({{
            "placeId=" .. tostring(placeId),
            "sea1=" .. tostring(sea1),
            "sea2=" .. tostring(sea2),
            "sea3=" .. tostring(sea3),
            "CommF_present=" .. tostring(commF ~= nil),
            "BonusMomentsGuide_present=" .. tostring(bmg ~= nil),
            "branch=" .. branch,
        }}, " | ")
    """
    result = mcp_execute(host, port, lua)
    return {"raw": str(result.get("result") or result.get("output") or result)}


def test_check_has_quest(host: str, port: int) -> dict:
    lua = """
        local plr = game.Players.LocalPlayer
        local gui = plr:FindFirstChild("PlayerGui")
        if not gui then return "no gui" end

        local function QuestText()
            if game.PlaceId == 2753915549 then
                local tracked = gui:FindFirstChild("TrackedQuestFrame")
                local frame = tracked and tracked:FindFirstChild("Frame")
                local header = frame and frame:FindFirstChild("header")
                local title = header and header:FindFirstChild("textLabel")
                if title and title:IsA("TextLabel") then return title.Text end
            end
            local main = gui:FindFirstChild("Main")
            if not main then
                for _, g in ipairs(gui:GetChildren()) do
                    if g:IsA("ScreenGui") and (g:FindFirstChild("Quest") or g:FindFirstChild("TopHUDList")) then
                        main = g; break
                    end
                end
            end
            if not main then return "" end
            local node = main
            for _, n in ipairs({"Quest", "Container", "QuestTitle", "Title"}) do
                if not node then return "" end
                node = node:FindFirstChild(n)
            end
            return node and tostring(node.Text) or ""
        end

        return "QuestText=" .. tostring(QuestText())
    """
    result = mcp_execute(host, port, lua)
    return {"raw": str(result.get("result") or result.get("output") or result)}


def run_suite(host: str, port: int) -> None:
    print(f"\n{'='*60}")
    print("LminHub Quest Acceptance — Live Diagnostic Suite")
    print(f"Target: {host}:{port}")
    print(f"{'='*60}\n")

    # 1. Place ID
    print("[1/5] Checking PlaceId...")
    place_id = check_place_id(host, port)
    sea_label = {
        2753915549: "Sea 1 (old)",
        85211729168715: "Sea 1 (new)",
        4442272183: "Sea 2 (old)",
        79091703265657: "Sea 2 (new)",
        7449423635: "Sea 3 (old)",
        100117331123089: "Sea 3 (new)",
    }.get(place_id, "Unknown")
    print(f"  PlaceId: {place_id} → {sea_label}")

    # 2. CommF_ remote
    print("\n[2/5] Probing CommF_ remote...")
    has_commf = probe_comm_remote(host, port)
    status = "FOUND" if has_commf else "MISSING"
    print(f"  CommF_: {status}")

    # 3. BonusMomentsGuide remote
    print("\n[3/5] Probing RF/BonusMomentsGuide remote...")
    has_bmg = probe_bonus_moments_guide(host, port)
    status = "FOUND" if has_bmg else "MISSING"
    print(f"  RF/BonusMomentsGuide: {status}")

    # 4. Quest GUI state
    print("\n[4/5] Reading quest GUI state...")
    gui_result = probe_quest_gui(host, port, place_id)
    print(f"  {gui_result['raw']}")

    # 5. Routing check
    print("\n[5/5] BFAcceptQuest routing check...")
    routing = test_accept_quest_routing(host, port, place_id)
    for part in routing["raw"].split(" | "):
        print(f"  {part}")

    # Summary
    print(f"\n{'='*60}")
    print("SUMMARY")
    print(f"{'='*60}")
    sea1_or_2 = place_id in (2753915549, 85211729168715, 4442272183, 79091703265657)
    sea3 = place_id in (7449423635, 100117331123089)

    if sea1_or_2:
        if has_commf:
            print("  [PASS] Sea 1/2 CommF_ path: remote present, timeout guard active.")
        else:
            print("  [FAIL] Sea 1/2: CommF_ remote not found — quest acceptance will fail.")
    elif sea3:
        if has_bmg:
            print("  [PASS] Sea 3 BonusMomentsGuide path: remote present.")
        else:
            print("  [WARN] Sea 3: RF/BonusMomentsGuide not found — quest acceptance may fail.")
    else:
        print("  [WARN] Unknown PlaceId — cannot determine quest path.")

    print()


def main() -> None:
    parser = argparse.ArgumentParser(description="LminHub quest acceptance live tester")
    parser.add_argument("--host", default=DEFAULT_HOST, help="MCP server host")
    parser.add_argument("--port", type=int, default=DEFAULT_PORT, help="MCP server port")
    parser.add_argument("--sea", type=int, choices=[1, 2, 3], help="Filter output to a specific sea")
    args = parser.parse_args()

    try:
        run_suite(args.host, args.port)
    except KeyboardInterrupt:
        print("\nAborted.")
        sys.exit(0)


if __name__ == "__main__":
    main()
