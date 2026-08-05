--// ════════════════════════════════════════════════════════════════ \\\\--
--// Mobile Roblox Executor MCP Connector
--// Standalone single-file connector for mobile Roblox executors
--// (Delta, CodeX, VegaX, ArceusX, Cryptic, Ronix, etc.)
--//
--// This script auto-detects the executor's capabilities and provides
--// compatibility shims for missing APIs. It uses HTTP polling by
--// default (WebSocket optional) to communicate with the MCP server.
--//
--// Usage:
--//   getgenv().BridgeURL = "YOUR_PC_IP:16384"
--//   loadstring(game:HttpGet("http://YOUR_PC_IP:16384/mobile-connector.luau"))()
--//
--// Or with auto-detection:
--//   loadstring(game:HttpGet("http://YOUR_PC_IP:16384/mobile-connector.luau"))("YOUR_PC_IP:16384")
--// ════════════════════════════════════════════════════════════════ \\\\--

if getgenv().MCP_Loaded == true then
    return
end
getgenv().MCP_Loaded = true

--// Parse bridge URL from argument or getgenv \\\\
local BridgeURL = (select(1, ...)) or getgenv().BridgeURL or getgenv().bridgeurl or "localhost:16384"
getgenv().BridgeURL = BridgeURL
getgenv().bridgeurl = BridgeURL

--// Wait for game to load \\\\
if not game:IsLoaded() then
    game.Loaded:Wait()
end

--// ─── Services ───────────────────────────────────────────────────── \\\\
local cloneref = cloneref or function(x) return x end

local HttpService = cloneref(game:GetService("HttpService"))
local LogService = cloneref(game:GetService("LogService"))
local Players = cloneref(game:GetService("Players"))
local MarketplaceService = cloneref(game:GetService("MarketplaceService"))
local UserInputService = cloneref(game:GetService("UserInputService"))

--// ─── Capability Detection ──────────────────────────────────────── \\\\--

local Capabilities = {}
local ExecutorName = "Unknown"
local Platform = "Unknown"

local function DetectExecutor()
    local detectors = {
        { name = "Delta", fn = function() return type(getgenv().Delta) ~= "nil" or type(isdelta) == "function" end },
        { name = "CodeX", fn = function() return type(getgenv().CodeX) ~= "nil" or type(iscodex) == "function" end },
        { name = "VegaX", fn = function() return type(getgenv().VegaX) ~= "nil" end },
        { name = "ArceusX", fn = function() return type(getgenv().ArceusX) ~= "nil" end },
        { name = "Cryptic", fn = function() return type(getgenv().Cryptic) ~= "nil" end },
        { name = "Ronix", fn = function() return type(getgenv().Ronix) ~= "nil" end },
        { name = "Hydrogen", fn = function() return type(getgenv().Hydrogen) ~= "nil" end },
        { name = "Electron", fn = function() return type(getgenv().Electron) ~= "nil" end },
        { name = "Wave", fn = function() return type(getgenv().Wave) ~= "nil" end },
        { name = "MacSploit", fn = function() return type(getgenv().MacSploit) ~= "nil" end },
    }
    for _, det in ipairs(detectors) do
        local ok, found = pcall(det.fn)
        if ok and found then return det.name end
    end
    if type(identifyexecutor) == "function" then
        local ok, info = pcall(identifyexecutor)
        if ok and type(info) == "string" and info ~= "" then return info end
    end
    return "Unknown"
end

local function DetectPlatform()
    -- Try UserInputService touch detection
    pcall(function()
        if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
            Platform = "Mobile"
        elseif UserInputService.MouseEnabled then
            Platform = "Desktop"
        end
    end)
    -- Try OS env detection
    pcall(function()
        if type(getgenv().OS) == "string" then
            Platform = getgenv().OS
        end
    end)
    return Platform
end

local function CheckCap(name, fn)
    local ok, result = pcall(fn)
    Capabilities[name] = ok and result == true
end

-- Core execution
CheckCap("loadstring", function() return type(loadstring) == "function" end)
CheckCap("getgenv", function() return type(getgenv) == "function" end)
CheckCap("setthreadidentity", function() return type(setthreadidentity) == "function" end)
CheckCap("setidentity", function() return type(setidentity) == "function" end)

-- HTTP
CheckCap("request", function() return type(request) == "function" end)
CheckCap("http_request", function() return type(http_request) == "function" end)
CheckCap("syn_request", function() return type(syn) == "table" and type(syn.request) == "function" end)
CheckCap("http_get", function() return type(http_get) == "function" end)

-- WebSocket
CheckCap("WebSocket", function() return type(WebSocket) == "table" and type(WebSocket.connect) == "function" end)

-- Script/Decompilation
CheckCap("getscriptbytecode", function() return type(getscriptbytecode) == "function" end)
CheckCap("decompile", function() return type(decompile) == "function" end)
CheckCap("getscripthash", function() return type(getscripthash) == "function" end)
CheckCap("getscripts", function() return type(getscripts) == "function" end)
CheckCap("getnilinstances", function() return type(getnilinstances) == "function" end)

-- Instance/Reflection
CheckCap("cloneref", function() return type(cloneref) == "function" end)
CheckCap("getinstances", function() return type(getinstances) == "function" end)
CheckCap("firesignal", function() return type(firesignal) == "function" end)

-- Input
CheckCap("VirtualInputManager", function() return Instance.new("VirtualInputManager") ~= nil end)
CheckCap("keypress", function() return type(keypress) == "function" end)

ExecutorName = DetectExecutor()
DetectPlatform()

--// ─── Compatibility Shims ───────────────────────────────────────── \\\\--

--// Unified HTTP request function with fallbacks \\\\
local HTTPRequest
if Capabilities.request then
    HTTPRequest = request
elseif Capabilities.http_request then
    HTTPRequest = http_request
elseif Capabilities.syn_request then
    HTTPRequest = syn.request
elseif Capabilities.http_get then
    -- http_get is GET-only; wrap it for basic polling
    HTTPRequest = function(opts)
        if opts.Method and opts.Method ~= "GET" then
            -- Try game:HttpPost for POST requests
            if opts.Method == "POST" and type(game.HttpPost) == "function" then
                local body = game:HttpPost(opts.Url, opts.Body or "", "application/json")
                return { Body = body, StatusCode = 200, Success = true }
            end
            error("http_get does not support " .. tostring(opts.Method) .. " requests")
        end
        local body = http_get(opts.Url)
        return { Body = body, StatusCode = 200, Success = true }
    end
else
    -- Last resort: game:HttpGet for GET, game:HttpPost for POST
    HTTPRequest = function(opts)
        if opts.Method and opts.Method ~= "GET" then
            if opts.Method == "POST" and type(game.HttpPost) == "function" then
                local body = game:HttpPost(opts.Url, opts.Body or "", "application/json")
                return { Body = body, StatusCode = 200, Success = true }
            end
            error("No HTTP function available for " .. tostring(opts.Method))
        end
        local body = game:HttpGet(opts.Url)
        return { Body = body, StatusCode = 200, Success = true }
    end
end

--// Unified setthreadidentity with fallback \\\\
local function SetThreadIdentity(level)
    if Capabilities.setthreadidentity then
        setthreadidentity(level)
    elseif Capabilities.setidentity then
        setidentity(level)
    end
    -- If neither is available, execution runs at default identity
end

--// Safe decompile with fallback \\\\
local function SafeDecompile(script)
    if Capabilities.decompile then
        return decompile(script)
    end
    return nil
end

--// Safe getscriptbytecode with fallback \\\\
local function SafeGetBytecode(script)
    if Capabilities.getscriptbytecode then
        return getscriptbytecode(script)
    end
    return nil
end

--// ─── Base64 Encoder ────────────────────────────────────────────── \\\\--
local base64_encode
do
    local b = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    base64_encode = base64encode or function(data)
        return ((data:gsub(".", function(x)
            local r, byt = "", x:byte()
            for i = 8, 1, -1 do r = r .. (byt % 2^i - byt % 2^(i-1) > 0 and "1" or "0") end
            return r
        end) .. "0000"):gsub("%d%d%d?%d?%d?%d?", function(x)
            if #x < 6 then return "" end
            local c = 0
            for i = 1, 6 do c = c + (x:sub(i, i) == "1" and 2^(6-i) or 0) end
            return b:sub(c + 1, c + 1)
        end) .. ({ "", "==", "=" })[#data % 3 + 1])
    end
end

--// ─── JSON Encoder (fallback if LuaEncode unavailable) ──────────── \\\\--
local function SimpleJSONEncode(value, seen)
    seen = seen or {}
    local t = type(value)

    if t == "nil" then return "null"
    elseif t == "boolean" then return value and "true" or "false"
    elseif t == "number" then
        if value ~= value then return "null" end -- NaN
        if value == math.huge then return "1e999" end
        if value == -math.huge then return "-1e999" end
        return tostring(value)
    elseif t == "string" then
        local escaped = value:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n"):gsub("\r", "\\r"):gsub("\t", "\\t")
        return '"' .. escaped .. '"'
    elseif t == "Instance" then
        local ok, fullName = pcall(function() return value:GetFullName() end)
        return '"' .. (ok and fullName or tostring(value)):gsub('"', '\\"') .. '"'
    elseif t ~= "table" then
        return '"' .. tostring(value):gsub('"', '\\"') .. '"'
    end

    if seen[value] then return '"<cyclic>"' end
    seen[value] = true

    -- Detect array vs object
    local isArray = true
    local count = 0
    for k, _ in pairs(value) do
        count = count + 1
        if type(k) ~= "number" then isArray = false break end
    end

    local parts = {}
    if isArray and count > 0 then
        for _, v in ipairs(value) do
            table.insert(parts, SimpleJSONEncode(v, seen))
        end
        seen[value] = nil
        return "[" .. table.concat(parts, ",") .. "]"
    else
        for k, v in pairs(value) do
            local keyStr = type(k) == "string" and k or tostring(k)
            table.insert(parts, '"' .. keyStr:gsub('"', '\\"') .. '":' .. SimpleJSONEncode(v, seen))
        end
        seen[value] = nil
        return "{" .. table.concat(parts, ",") .. "}"
    end
end

-- Try to load LuaEncode from GitHub, fall back to simple encoder
local LuaEncode
do
    local ok, encoded = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/chadhyatt/LuaEncode/refs/heads/master/src/LuaEncode.lua"))()
    end)
    if ok and type(encoded) == "function" then
        LuaEncode = encoded
    else
        LuaEncode = function(value, _)
            return SimpleJSONEncode(value)
        end
    end
end

--// ─── Output Sanitizer ──────────────────────────────────────────── \\\\--
local SANITIZE_MAX_DEPTH = 8
local SANITIZE_MAX_ENTRIES = 60
local SANITIZE_MAX_STRING = 500

local function SanitizeForOutput(value, depth, seen)
    depth = depth or 0
    local vt = typeof(value)

    if vt == "Instance" then
        local ok, fullName = pcall(function() return value:GetFullName() end)
        return ok and fullName or tostring(value)
    elseif vt == "string" then
        if #value > SANITIZE_MAX_STRING then
            return string.sub(value, 1, SANITIZE_MAX_STRING)
                .. "...(+" .. (#value - SANITIZE_MAX_STRING) .. " chars omitted)"
        end
        return value
    elseif vt == "number" or vt == "boolean" or vt == "nil" then
        return value
    elseif vt ~= "table" then
        return tostring(value)
    end

    if depth >= SANITIZE_MAX_DEPTH then return "<table: max depth reached>" end
    seen = seen or {}
    if seen[value] then return "<cyclic table>" end
    seen[value] = true

    local result = {}
    local count = 0
    local omitted = 0
    for k, v in pairs(value) do
        if count >= SANITIZE_MAX_ENTRIES then
            omitted = omitted + 1
        else
            count = count + 1
            local key = k
            if typeof(k) ~= "string" and typeof(k) ~= "number" then
                key = tostring(k)
            end
            result[key] = SanitizeForOutput(v, depth + 1, seen)
        end
    end
    if omitted > 0 then
        result["__omitted"] = omitted .. " more entries omitted"
    end
    seen[value] = nil
    return result
end

--// ─── Session ID Generation ─────────────────────────────────────── \\\\--
local function GenerateSessionGuid()
    local ok, guid = pcall(function() return HttpService:GenerateGUID(false) end)
    if ok and type(guid) == "string" and guid ~= "" then return guid end
    return tostring(os.clock()) .. "-" .. tostring(math.random(1, 1000000000))
end

local function GetClientIdentityKey()
    local player = Players.LocalPlayer
    return table.concat({
        tostring(game.PlaceId or 0),
        tostring(game.JobId or ""),
        tostring(player and player.UserId or 0),
    }, ":")
end

local function GetStableClientSessionId()
    local identityKey = GetClientIdentityKey()
    if type(getgenv().MCP_ClientSessionId) ~= "string" or getgenv().MCP_ClientIdentityKey ~= identityKey then
        getgenv().MCP_ClientSessionId = GenerateSessionGuid()
        getgenv().MCP_ClientIdentityKey = identityKey
    end
    return getgenv().MCP_ClientSessionId
end

--// ─── Registration Info ─────────────────────────────────────────── \\\\--
local function GetRegistrationInfo()
    local player = Players.LocalPlayer
    local placeName = "Unknown"
    pcall(function()
        local productInfo = MarketplaceService:GetProductInfo(game.PlaceId)
        placeName = productInfo.Name
    end)
    return {
        type = "register",
        username = player and player.Name or "Unknown",
        userId = player and player.UserId or 0,
        placeId = game.PlaceId,
        jobId = game.JobId,
        placeName = placeName,
        sessionId = GetStableClientSessionId(),
        -- Mobile-specific fields
        mobile = true,
        executor = ExecutorName,
        platform = Platform,
        capabilities = Capabilities,
    }
end

--// ─── Bridge: Message Handlers ──────────────────────────────────── \\\\--
local Callbacks = {}
local RawCallbacks = {}

local function FormatResponse(message, id, isError)
    if isError then
        return { error = tostring(message), success = false, id = id }
    end
    local output = SanitizeForOutput(message)
    if typeof(output) ~= "table" then output = { output } end
    return {
        output = LuaEncode(output, { Prettify = false }),
        success = true,
        id = id,
    }
end

local function HandleMessage(data)
    if Callbacks[data.type] then
        local success, result = pcall(function() return Callbacks[data.type](data) end)
        if success and result == nil then return nil end
        if not success then return FormatResponse(result, data.id, true) end
        if RawCallbacks[data.type] then
            return { output = tostring(result), success = true, id = data.id }
        end
        return FormatResponse(result, data.id, false)
    end
    return nil
end

--// ─── Register Tool Handlers ────────────────────────────────────── \\\\--

-- Core: execute code
Callbacks["execute"] = function(data)
    task.defer(function()
        SetThreadIdentity(8)
        loadstring(data.source)()
    end)
end

-- Core: get data by code
Callbacks["get-data-by-code"] = function(data)
    SetThreadIdentity(8)
    return table.pack(loadstring(data.source)())
end

-- Core: get console output
RawCallbacks["get-console-output"] = true
Callbacks["get-console-output"] = function(data)
    local limit = math.max(1, math.min(tonumber(data.limit) or 20, 200))
    local logsOrder = data.logsOrder or "NewestFirst"
    local filter = data.filter
    local hasFilter = type(filter) == "string" and filter ~= ""
    local summaryOnly = data.summaryOnly == true

    local logs = LogService:GetLogHistory()
    local results = {}
    local matchedCount = 0
    local countsByLevel = {}

    local function matchesFilter(logEntry)
        if not hasFilter then return true end
        return string.find(logEntry.message, filter, 1, true) ~= nil
    end

    local MAX_LOG_MSG = 500
    local function formatMsg(msg)
        local out = tostring(msg or "")
        if #out > MAX_LOG_MSG then
            out = string.sub(out, 1, MAX_LOG_MSG) .. "...(+" .. (#out - MAX_LOG_MSG) .. " chars omitted)"
        end
        return out
    end

    if logsOrder == "NewestFirst" then
        for i = #logs, 1, -1 do
            local entry = logs[i]
            if not matchesFilter(entry) then continue end
            matchedCount = matchedCount + 1
            local lvl = entry.messageType and entry.messageType.Name or "Unknown"
            countsByLevel[lvl] = (countsByLevel[lvl] or 0) + 1
            if #results < limit then table.insert(results, entry) end
        end
    else
        for _, entry in ipairs(logs) do
            if not matchesFilter(entry) then continue end
            matchedCount = matchedCount + 1
            local lvl = entry.messageType and entry.messageType.Name or "Unknown"
            countsByLevel[lvl] = (countsByLevel[lvl] or 0) + 1
            if #results < limit then table.insert(results, entry) end
        end
    end

    local lines = {}
    if summaryOnly then
        table.insert(lines, string.format("Matched %d logs.", matchedCount))
        for lvl, count in pairs(countsByLevel) do
            table.insert(lines, string.format("%s: %d", lvl, count))
        end
        return table.concat(lines, "\n")
    end

    table.insert(lines, string.format("Displaying %d/%d logs:", #results, matchedCount))
    for _, entry in ipairs(results) do
        table.insert(lines, string.format("[%s t=%s] %s",
            entry.messageType.Name, tostring(entry.timestamp), formatMsg(entry.message)))
    end
    return table.concat(lines, "\n")
end

-- Instance: get game info
Callbacks["get-game-info"] = function(data)
    local productInfo = MarketplaceService:GetProductInfo(game.PlaceId)
    local info = {
        PlaceId = game.PlaceId,
        GameId = game.GameId,
        PlaceVersion = game.PlaceVersion,
        PlaceName = productInfo.Name,
        Creator = productInfo.Creator.Name,
        CreatorType = tostring(productInfo.Creator.CreatorType),
        CreatorId = productInfo.Creator.CreatorTargetId,
        JobId = game.JobId,
        -- Mobile-specific info
        Mobile = true,
        Executor = ExecutorName,
        Platform = Platform,
    }
    -- ServerType requires RobloxReplicatedStorage access which may not be available on mobile
    pcall(function()
        local RobloxReplicatedStorage = cloneref(game:GetService("RobloxReplicatedStorage"))
        info.ServerType = RobloxReplicatedStorage.GetServerType:InvokeServer()
    end)
    if data.includeDescription == true then
        info.PlaceDescription = productInfo.Description
    end
    return info
end

-- Instance: search instances
Callbacks["search-instances"] = function(data)
    local rootInstance = loadstring("return " .. data.root)()
    local instances = rootInstance:QueryDescendants(data.selector)
    local limit = math.max(1, math.min(tonumber(data.limit) or 20, 100))
    local results = {}
    for i, inst in ipairs(instances) do
        if i > limit then break end
        local fullName = inst.Name
        pcall(function() fullName = inst:GetFullName() end)
        table.insert(results, {
            Name = inst.Name,
            ClassName = inst.ClassName,
            Path = fullName,
            DebugId = inst:GetDebugId(),
        })
    end
    return { count = #instances, limited = #instances > limit, results = results }
end

-- Instance: get descendants tree
Callbacks["get-descendants-tree"] = function(data)
    local rootInstance = loadstring("return " .. data.root)()
    assert(typeof(rootInstance) == "Instance", "Root path did not resolve to a valid Instance.")
    local maxDepth = math.max(0, math.min(tonumber(data.maxDepth) or 2, 5))
    local maxChildren = math.max(1, math.min(tonumber(data.maxChildren) or 20, 30))
    local classFilter = data.classFilter or ""
    local hasFilter = classFilter ~= ""
    local summaryOnly = data.summaryOnly == true
    local MAX_NODES = 300
    local nodeBudget = MAX_NODES
    local budgetHit = false

    if summaryOnly then
        local classCounts = {}
        local visited, matched = 0, 0
        local function walk(inst, depth)
            if depth > maxDepth then return end
            for _, child in inst:GetChildren() do
                visited = visited + 1
                if not hasFilter or child:IsA(classFilter) then
                    matched = matched + 1
                    classCounts[child.ClassName] = (classCounts[child.ClassName] or 0) + 1
                end
                if depth < maxDepth then walk(child, depth + 1) end
            end
        end
        walk(rootInstance, 1)
        return {
            Root = { Name = rootInstance.Name, ClassName = rootInstance.ClassName, ChildCount = #rootInstance:GetChildren() },
            MaxDepth = maxDepth,
            ClassFilter = hasFilter and classFilter or nil,
            VisitedDescendants = visited,
            MatchedDescendants = matched,
            ClassCounts = classCounts,
        }
    end

    local function buildTree(inst, depth)
        if depth > maxDepth then return nil end
        local children = inst:GetChildren()
        local childNodes = {}
        local shown = 0
        local total = #children
        for _, child in ipairs(children) do
            if shown >= maxChildren then break end
            if nodeBudget <= 0 then budgetHit = true break end
            if hasFilter and not child:IsA(classFilter) then
                if depth < maxDepth then
                    local subtree = buildTree(child, depth + 1)
                    if subtree and subtree.Children and #subtree.Children > 0 then
                        table.insert(childNodes, subtree)
                        shown = shown + 1
                    end
                end
            else
                nodeBudget = nodeBudget - 1
                local node = { Name = child.Name, ClassName = child.ClassName, ChildCount = #child:GetChildren() }
                if depth < maxDepth and node.ChildCount > 0 then
                    local subtree = buildTree(child, depth + 1)
                    if subtree then node.Children = subtree.Children end
                end
                table.insert(childNodes, node)
                shown = shown + 1
            end
        end
        return {
            Name = inst.Name,
            ClassName = inst.ClassName,
            ChildCount = total,
            TruncatedAt = shown < total and shown or nil,
            Children = childNodes,
        }
    end

    local tree = buildTree(rootInstance, 0)
    if budgetHit and type(tree) == "table" then
        tree.Note = "Output capped at " .. MAX_NODES .. " nodes. Narrow with classFilter, lower maxDepth, or summaryOnly=true."
    end
    return tree
end

-- GUI: type text box (with mobile compatibility)
Callbacks["type-text-box"] = function(data)
    local path = data.path
    local text = data.string or data.text
    local enter = data.enter
    local useKeyPress = data.useKeyPress

    local textBox
    if typeof(path) == "string" then
        textBox = loadstring("return " .. path)()
    else
        textBox = path
    end

    assert(typeof(textBox) == "Instance", "Path did not resolve to a valid Instance.")
    assert(textBox:IsA("TextBox"), "Resolved Instance is not a TextBox.")

    textBox:CaptureFocus()
    task.wait(0.05)

    if useKeyPress and Capabilities.VirtualInputManager then
        local VirtualInputManager = Instance.new("VirtualInputManager")
        pcall(function()
            for i = 1, #text do
                VirtualInputManager:SendTextInput(text:sub(i, i), nil, game)
                task.wait(0.01)
            end
        end)
    else
        textBox.Text = text
    end

    if enter then
        textBox:ReleaseFocus(true)
    else
        textBox:ReleaseFocus(false)
    end

    return { status = "success", message = "Successfully typed into TextBox." }
end

-- GUI: click button (with mobile compatibility)
Callbacks["click-button"] = function(data)
    local path = data.path
    local action = data.Action or data.action

    local button
    if typeof(path) == "string" then
        button = loadstring("return " .. path)()
    else
        button = path
    end

    assert(typeof(button) == "Instance", "Path did not resolve to a valid Instance.")
    assert(button:IsA("GuiButton"), "Resolved Instance is not a GuiButton.")

    if not Capabilities.firesignal then
        -- Fallback: try VirtualInputManager for touch simulation
        if Capabilities.VirtualInputManager then
            local VirtualInputManager = Instance.new("VirtualInputManager")
            pcall(function()
                VirtualInputManager:SendTouchEvent(true, button.AbsolutePosition.X, button.AbsolutePosition.Y, game)
                task.wait(0.05)
                VirtualInputManager:SendTouchEvent(false, button.AbsolutePosition.X, button.AbsolutePosition.Y, game)
            end)
            return { status = "success", message = "Simulated touch on button (firesignal unavailable)." }
        end
        error("Your executor does not support 'firesignal' or touch simulation.")
    end

    local Signals = { "Activated", "MouseButton1Down", "MouseButton2Down", "MouseButton1Click", "MouseButton2Click" }
    if action then
        assert(table.find(Signals, action), "Invalid action. Valid: " .. table.concat(Signals, ", "))
        firesignal(button[action])
    else
        for _, sig in ipairs(Signals) do
            pcall(function() firesignal(button[sig]) end)
        end
    end
    return { status = "success", message = "Successfully fired click signals on Button." }
end

-- Script: get script content (with mobile fallback)
Callbacks["get-script-content"] = function(data)
    local script
    if typeof(data.script) == "string" then
        script = loadstring("return " .. data.script)()
    else
        script = data.script
    end
    assert(typeof(script) == "Instance" and script:IsA("LuaSourceContainer"),
        "Path did not resolve to a LuaSourceContainer.")

    -- Try decompile first
    local source = SafeDecompile(script)
    if source then return source end

    -- Try getscriptbytecode + external decompiler (may not be available on mobile)
    local bytecode = SafeGetBytecode(script)
    if bytecode then
        return "-- Bytecode retrieved but decompiler not available on this executor.\n-- Bytecode length: " .. #bytecode .. " bytes"
    end

    error("Neither decompile() nor getscriptbytecode() is available on this executor. Script inspection is limited.")
end

-- Script: script grep (limited on mobile)
Callbacks["script-grep"] = function(data)
    if not Capabilities.getscripts then
        error("getscripts() is not available on this executor. Script grep is unavailable.")
    end

    local pattern = data.pattern
    local limit = math.max(1, math.min(tonumber(data.limit) or 10, 50))
    local isRegex = data.regex == true
    local results = {}

    for _, script in ipairs(getscripts()) do
        if #results >= limit then break end
        local source = SafeDecompile(script)
        if source then
            local found = false
            if isRegex then
                found = pcall(string.find, source, pattern) and string.find(source, pattern) ~= nil
            else
                found = string.find(source, pattern, 1, true) ~= nil
            end
            if found then
                local name = script.Name
                pcall(function() name = script:GetFullName() end)
                table.insert(results, { Name = name, ClassName = script.ClassName })
            end
        end
    end

    return { count = #results, results = results }
end

--// ─── HTTP Polling Bridge ───────────────────────────────────────── \\\\--

local function IsAlive()
    local success, result = pcall(function()
        local response
        local thread = task.spawn(function()
            local ok, data = pcall(HTTPRequest, {
                Url = "http://" .. BridgeURL,
                Method = "GET",
            })
            if ok then response = data end
        end)
        local start = os.clock()
        repeat task.wait(0.05) until response ~= nil or os.clock() - start > 5
        if response == nil then
            task.cancel(thread)
            return false
        end
        return response.StatusCode == 426 or response.StatusCode == 200
    end)
    return success and result or false
end

--// Main connection loop \\\\
local function Connect()
    local retryDelay = 0.5
    local maxRetryDelay = 5
    local maxAttempts = 10
    local attempts = 0

    -- Wait for server to be alive
    while not IsAlive() do
        attempts = attempts + 1
        if attempts >= maxAttempts then
            print("[Mobile MCP] Failed to connect to bridge server at " .. BridgeURL .. " after " .. maxAttempts .. " attempts")
            return false
        end
        task.wait(retryDelay)
        retryDelay = math.min(retryDelay * 1.5, maxRetryDelay)
    end

    -- Register with server
    local clientId = nil
    pcall(function()
        local regResponse = HTTPRequest({
            Url = "http://" .. BridgeURL .. "/register",
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode(GetRegistrationInfo()),
        })
        if regResponse.StatusCode == 200 and regResponse.Body then
            local regData = HttpService:JSONDecode(regResponse.Body)
            clientId = regData.clientId
        end
    end)

    if not clientId then
        print("[Mobile MCP] Failed to register with server")
        return false
    end

    print("[Mobile MCP] Connected! Client ID: " .. clientId)
    print("[Mobile MCP] Executor: " .. ExecutorName .. " | Platform: " .. Platform)

    -- Polling loop
    local connected = true
    local pollInterval = 0.15 -- Slightly slower for mobile
    local consecutiveFailures = 0

    while connected do
        local gotCommands = false
        local success, _ = pcall(function()
            local pollUrl = "http://" .. BridgeURL .. "/poll"
            if clientId then
                pollUrl = pollUrl .. "?clientId=" .. clientId
            end
            local response = HTTPRequest({
                Url = pollUrl,
                Method = "GET",
            })

            if response.StatusCode ~= 204 and response.StatusCode ~= 200 then
                consecutiveFailures = consecutiveFailures + 1
                if consecutiveFailures >= 3 then
                    connected = false
                end
                return
            end

            consecutiveFailures = 0

            if response.Body and response.Body ~= "" then
                local data = HttpService:JSONDecode(response.Body)
                local commands = {}
                if typeof(data) == "table" and data.type == nil and #data > 0 then
                    commands = data
                elseif typeof(data) == "table" and data.type ~= nil then
                    commands = { data }
                end

                for _, command in ipairs(commands) do
                    gotCommands = true
                    task.spawn(function()
                        local result = HandleMessage(command)
                        if result == nil then return end
                        pcall(function()
                            HTTPRequest({
                                Url = "http://" .. BridgeURL .. "/respond",
                                Method = "POST",
                                Headers = { ["Content-Type"] = "application/json" },
                                Body = HttpService:JSONEncode(result),
                            })
                        end)
                    end)
                end
            end
        end)

        if not success then
            consecutiveFailures = consecutiveFailures + 1
            if consecutiveFailures >= 3 then
                connected = false
            end
        end

        if not gotCommands then
            task.wait(pollInterval)
        end
    end

    print("[Mobile MCP] Disconnected from server")
    return false
end

--// ─── Main Loop ─────────────────────────────────────────────────── \\\\--
-- Skip script decompilation mapping on mobile (saves resources and avoids
-- executor API incompatibilities)
getgenv().DisableInitialScriptDecompMapping = true

print("[Mobile MCP] Starting mobile connector...")
print("[Mobile MCP] Bridge URL: " .. BridgeURL)
print("[Mobile MCP] Executor: " .. ExecutorName)
print("[Mobile MCP] Platform: " .. Platform)
print("[Mobile MCP] Capabilities:")
for name, available in pairs(Capabilities) do
    print("  " .. (available and "[OK]" or "[--]") .. " " .. name)
end

-- Reconnect loop
while true do
    local success = pcall(Connect)
    if not success then
        print("[Mobile MCP] Connection error, retrying in 3 seconds...")
    end
    task.wait(3)
end
