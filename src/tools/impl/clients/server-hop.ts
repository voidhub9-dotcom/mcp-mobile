import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import { describeResponse, sendAndWait } from "../../factory.js";
import { maxOutputCharsSchema } from "../../schemas.js";
import { PUBLIC_BASE_URL, WS_PORT } from "../../../config.js";

interface ServerHopParams {
    action: "hop" | "list" | "rejoin";
    mode: "random" | "lowest-players" | "lowest-ping";
    targetPlaceId: number;
    jobId: string;
    maxPages: number;
    excludeJobIds: string[];
    queueReconnect: boolean;
    defaultBridge: string;
}

// The hop runs entirely inside the Roblox client. The tool rides the existing
// get-data-by-code bridge type so both the desktop and mobile connectors can
// serve it without any connector artifact changes.
function buildServerHopSource(params: ServerHopParams): string {
    const luauStr = (value: string): string => JSON.stringify(value);
    const excludeList = params.excludeJobIds.map(luauStr).join(", ");

    const payload = `
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local HopAction = ${luauStr(params.action)}
local HopMode = ${luauStr(params.mode)}
local TargetPlaceId = ${params.targetPlaceId}
local WantJobId = ${luauStr(params.jobId)}
local MaxPages = ${params.maxPages}
local QueueReconnect = ${params.queueReconnect}
local ExcludeJobIds = { ${excludeList} }

local function fail(errorText)
    return { success = false, error = errorText }
end

local player = Players.LocalPlayer
if not player then
    return fail("no LocalPlayer available (client is not in a live server)")
end

local currentPlaceId = game.PlaceId
local currentJobId = tostring(game.JobId or "")
local listPlaceId = (TargetPlaceId ~= 0) and TargetPlaceId or currentPlaceId

local excluded = {}
excluded[currentJobId] = true
for _, id in ipairs(ExcludeJobIds) do
    excluded[tostring(id)] = true
end

local servers = {}
local scanned = 0
local pages = 0
local cursor = nil

-- skip the list scan when a direct jobId (or rejoin) makes it unnecessary
if (HopAction ~= "rejoin") and not (HopAction == "hop" and WantJobId ~= "") then
repeat
    local url = "https://games.roblox.com/v1/games/" .. listPlaceId .. "/servers/Public?limit=100&sortOrder=2&excludeFullGames=true"
    if cursor then
        url = url .. "&cursor=" .. cursor
    end
    url = url .. "&_=" .. string.format("%.0f", os.clock() * 1000)
    local okBody, body = pcall(function()
        return game:HttpGet(url)
    end)
    if not okBody then
        return fail("server list request failed: " .. tostring(body))
    end
    local okDecode, decoded = pcall(function()
        return HttpService:JSONDecode(body)
    end)
    if not okDecode then
        return fail("server list JSON could not be decoded")
    end
    for _, s in ipairs(decoded.data or {}) do
        scanned = scanned + 1
        table.insert(servers, {
            id = tostring(s.id),
            playerCount = s.playerCount or 0,
            maxPlayers = s.maxPlayers or 0,
            ping = s.ping or 0,
            fps = s.fps or 0,
        })
    end
    cursor = decoded.nextPageCursor
    pages = pages + 1
    if cursor then
        task.wait(0.2)
    end
until (not cursor) or (pages >= MaxPages)

-- legacy endpoint fallback when the modern API returns an empty list
if #servers == 0 then
    local legacyUrl = "https://www.roblox.com/games/getgameinstancesjson?placeId=" .. listPlaceId .. "&startindex=0"
    local okLegacy, legacyBody = pcall(function()
        return game:HttpGet(legacyUrl)
    end)
    if okLegacy then
        local okLegacyDecode, legacyData = pcall(function()
            return HttpService:JSONDecode(legacyBody)
        end)
        if okLegacyDecode and type(legacyData) == "table" and type(legacyData.Collection) == "table" then
            for _, s in ipairs(legacyData.Collection) do
                scanned = scanned + 1
                table.insert(servers, {
                    id = tostring(s.JobID or s.JobId or ""),
                    playerCount = s.CurrentPlayers or 0,
                    maxPlayers = s.Capacity or 0,
                    ping = s.Ping or 0,
                    fps = s.Fps or 0,
                })
            end
        end
    end
end
end

if HopAction == "list" then
    local filtered = {}
    for _, s in ipairs(servers) do
        if not excluded[s.id] then
            table.insert(filtered, s)
        end
    end
    table.sort(filtered, function(a, b)
        return a.playerCount < b.playerCount
    end)
    local shown = {}
    for i = 1, math.min(10, #filtered) do
        table.insert(shown, filtered[i])
    end
    return {
        success = true,
        action = "list",
        placeId = listPlaceId,
        serversSeen = scanned,
        candidates = #filtered,
        servers = shown,
    }
end

local chosenJobId = ""
local chosenPlaceId = currentPlaceId
local chosenServer = nil

if HopAction == "rejoin" then
    if currentJobId == "" then
        return fail("cannot rejoin: current JobId is empty")
    end
    chosenJobId = currentJobId
else
    chosenPlaceId = listPlaceId
    if WantJobId ~= "" then
        chosenJobId = WantJobId
    else
        local candidates = {}
        for _, s in ipairs(servers) do
            if not excluded[s.id] then
                table.insert(candidates, s)
            end
        end
        if #candidates == 0 then
            if TargetPlaceId ~= 0 and TargetPlaceId ~= currentPlaceId then
                -- new game with no visible public servers: a plain teleport is the only option
                chosenJobId = ""
            else
                return fail("no other public servers found among " .. scanned .. " scanned entries; game may be full, private, or gated")
            end
        elseif HopMode == "lowest-players" then
            chosenServer = candidates[1]
            for _, s in ipairs(candidates) do
                if s.playerCount < chosenServer.playerCount then
                    chosenServer = s
                end
            end
        elseif HopMode == "lowest-ping" then
            chosenServer = candidates[1]
            for _, s in ipairs(candidates) do
                if s.ping < chosenServer.ping then
                    chosenServer = s
                end
            end
        else
            chosenServer = candidates[math.random(#candidates)]
        end
        if chosenServer then
            chosenJobId = chosenServer.id
        end
    end
end

local reconnectQueued = false
if QueueReconnect and type(queue_on_teleport) == "function" then
    local reconnectSource = [==[
task.wait(3)
local genv = getgenv()
local connectorPath = (genv.MCP_ActiveBridge ~= nil) and "/script.luau" or "/mobile-connector.luau"
local bridge = tostring(genv.BridgeURL or genv.bridgeurl or "${params.defaultBridge}")
bridge = bridge:gsub("/+$", "")
if bridge:sub(1, 7) ~= "http://" and bridge:sub(1, 8) ~= "https://" then
    bridge = "http://" .. bridge
end
for attempt = 1, 15 do
    genv.MCP_Loaded = nil
    pcall(function()
        loadstring(game:HttpGet(bridge .. connectorPath))()
    end)
    if genv.MCP_Loaded == true then
        break
    end
    task.wait(2)
end
]==]
    pcall(queue_on_teleport, reconnectSource)
    reconnectQueued = true
end

local okTeleport, teleportError
if chosenJobId ~= "" then
    okTeleport, teleportError = pcall(function()
        TeleportService:TeleportToPlaceInstance(chosenPlaceId, chosenJobId, player)
    end)
else
    okTeleport, teleportError = pcall(function()
        TeleportService:Teleport(chosenPlaceId, player)
    end)
end
if not okTeleport then
    return {
        success = false,
        error = "teleport failed: " .. tostring(teleportError),
        serversSeen = scanned,
        reconnectQueued = reconnectQueued,
    }
end

-- give the bridge a moment to deliver this response before the client unloads
task.wait(1)

return {
    success = true,
    action = HopAction,
    fromPlaceId = currentPlaceId,
    fromJobId = currentJobId,
    toPlaceId = chosenPlaceId,
    toJobId = (chosenJobId ~= "") and chosenJobId or "(default server of target game)",
    chosenServer = chosenServer,
    serversSeen = scanned,
    pagesScanned = pages,
    teleportInitiated = true,
    reconnectQueued = reconnectQueued,
    reconnectNote = reconnectQueued
        and "connector will auto-reload in the new server via queue_on_teleport"
        or "queue_on_teleport unavailable on this executor: reconnect via your autoexec loader or re-run the connector script",
}
`;
    return `setthreadidentity(8);\n${payload}`;
}

export default function register(server: McpServer): void {
    server.registerTool("server-hop", {
        title: "Server hop and remote game control",
        description:
            "Drive the connected Roblox client across servers while the device is unattended. " +
            "Actions: 'hop' leaves the current server for another public server (use mode to pick random/lowest-players/lowest-ping, pass jobId to target a specific server, " +
            "or pass placeId to hop into a different game entirely). 'list' previews candidate servers without hopping. " +
            "'rejoin' teleports back into the current server. After a hop the connector queues itself via queue_on_teleport when the executor supports it, " +
            "so the agent keeps remote control in the new server without anyone touching the device.",
        inputSchema: z.object({
            action: z
                .enum(["hop", "list", "rejoin"])
                .describe("What to do. Default 'hop'.")
                .optional()
                .default("hop"),
            placeId: z
                .number()
                .int()
                .positive()
                .describe("Optional target placeId to hop into a different game. Leave unset to stay in the current game.")
                .optional(),
            jobId: z
                .string()
                .describe("Optional exact jobId to hop into (of the current game, or of placeId when both are given).")
                .optional(),
            mode: z
                .enum(["random", "lowest-players", "lowest-ping"])
                .describe("How to pick the destination server. Default 'random'.")
                .optional()
                .default("random"),
            maxPages: z
                .number()
                .int()
                .min(1)
                .max(10)
                .describe("Server list pages to scan before picking (100 servers per page). Default 3.")
                .optional()
                .default(3),
            excludeJobIds: z
                .array(z.string())
                .describe("Optional extra jobIds to skip (the current server is always excluded).")
                .optional(),
            queueReconnect: z
                .boolean()
                .describe("Queue the connector loader via queue_on_teleport so the bridge reconnects in the destination server. Default true.")
                .optional()
                .default(true),
            timeout: z
                .number()
                .describe("Timeout in milliseconds for the hop response (default 45000, max 120000).")
                .optional()
                .default(45000),
            maxOutputChars: maxOutputCharsSchema,
        }),
    }, async ({ action, placeId, jobId, mode, maxPages, excludeJobIds, queueReconnect, timeout, maxOutputChars }) => {
        const clampedTimeout = Math.min(Math.max(timeout, 10000), 120000);
        const defaultBridge = PUBLIC_BASE_URL
            ? PUBLIC_BASE_URL.replace(/\/$/, "")
            : `http://localhost:${WS_PORT}`;
        const source = buildServerHopSource({
            action,
            mode,
            // placeId 0 means "current game"
            targetPlaceId: placeId ?? 0,
            jobId: (jobId ?? "").trim(),
            maxPages,
            excludeJobIds: excludeJobIds ?? [],
            queueReconnect,
            defaultBridge,
        });
        console.error(`Server hop (${action}) requested in the active client...`);
        return sendAndWait({
            type: "get-data-by-code",
            data: { source },
            timeoutMs: clampedTimeout,
            maxOutputChars,
            stampClient: true,
            truncationHint: "Rerun server-hop with action 'list' to preview fewer servers, or pass a smaller maxOutputChars.",
            failureMessage: (response) => "Failed to server hop: " + describeResponse(response),
        });
    });
}
