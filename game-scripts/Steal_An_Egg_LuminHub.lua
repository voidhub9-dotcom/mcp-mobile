--[[
    Lumin Hub - Steal An Egg
    Rewrite: fixes + expanded feature set.

    All game data paths in this file were verified live against
    PlaceId 107778070777162 (Steal An Egg, PlaceVersion 373).
]]

if not game:IsLoaded() then game.Loaded:Wait() end

if _G.LuminHubShutdown then pcall(_G.LuminHubShutdown) end

local ScriptGeneration = (_G.LuminHubGeneration or 0) + 1
_G.LuminHubGeneration = ScriptGeneration

--=====================================================================
-- Lifecycle registry
--=====================================================================

local Running      = {}   -- loopName -> bool
local Connections  = {}   -- tracked RBXScriptConnections
local Threads      = {}   -- tracked spawned threads (flag tables)
local Visuals      = {}   -- key -> Instance (ESP, body movers, gui)

local function trackConn(conn)
    if conn then table.insert(Connections, conn) end
    return conn
end

local function disconnectAll()
    for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
    table.clear(Connections)
end

local function destroyVisuals(prefix)
    for key, obj in pairs(Visuals) do
        if (not prefix) or key:sub(1, #prefix) == prefix then
            pcall(function() obj:Destroy() end)
            Visuals[key] = nil
        end
    end
end

local function stopAllLoops()
    for name in pairs(Running) do Running[name] = false end
    for _, t in ipairs(Threads) do t.alive = false end
    table.clear(Threads)
end

_G.LuminHubShutdown = function()
    _G.LuminHubGeneration = (_G.LuminHubGeneration or 0) + 1
    stopAllLoops()
    disconnectAll()
    destroyVisuals(nil)
    pcall(function()
        if _G.LuminHubLibrary then _G.LuminHubLibrary:Unload() end
    end)
    _G.LuminHubLibrary  = nil
    _G.LuminHubDebug    = nil
    _G.LuminHubRunning  = nil
end

--=====================================================================
-- Config
--=====================================================================

local TemplateConfig = {
    Branding = {
        WindowTitle  = " ",
        Footer       = "discord.gg/luminhub",
        IconAssetId  = 73375080218088,
        IconFile     = "A7.png",
        IconUrl      = "http://luminon.top/A7.png",
        IconFallback = "rbxassetid://73375080218088",
    },
    Game = {
        ExpectedPlaceVersion = 373,
        ThemeFolder   = "LuminTheme",
        SaveFolder    = "LuminHub",
        SaveSubFolder = "StealAnEgg",
    },
    Interface = {
        ToggleKeybind = Enum.KeyCode.RightControl,
        DesktopSize   = UDim2.fromOffset(600, 520),
        MobileSize    = UDim2.fromOffset(400, 350),
        CornerRadius  = 10,
    },
    Dependencies = { LibraryUrl = "https://luminon.top/testing/Library.lua" },
    Loading      = { Title = "Lumin Hub", TotalSteps = 4 },
}

--=====================================================================
-- Executor / service resolution  (all locals - no global leaks)
--=====================================================================

local function resolveFunction(candidate, fallback)
    if type(candidate) == "function" then return candidate end
    return fallback
end

local cloneref     = resolveFunction(cloneref, function(...) return ... end)
local httprequest  = resolveFunction(
    request or http_request or (syn and syn.request) or (http and http.request) or (fluxus and fluxus.request))
local protectgui   = resolveFunction(protectgui or (syn and syn.protect_gui), function() end)
local getconnections = resolveFunction(getconnections)
local firesignal     = resolveFunction(firesignal)

local Players            = cloneref(game:GetService("Players"))
local CoreGui            = cloneref(game:GetService("CoreGui"))
local UserInputService   = cloneref(game:GetService("UserInputService"))
local TweenService       = cloneref(game:GetService("TweenService"))
local HttpService        = cloneref(game:GetService("HttpService"))
local RunService         = cloneref(game:GetService("RunService"))
local TeleportService     = cloneref(game:GetService("TeleportService"))
local VirtualUser        = cloneref(game:GetService("VirtualUser"))
local Workspace          = cloneref(game:GetService("Workspace"))
local ReplicatedStorage  = cloneref(game:GetService("ReplicatedStorage"))
local Lighting           = cloneref(game:GetService("Lighting"))
local Stats              = cloneref(game:GetService("Stats"))

local LocalPlayer = Players.LocalPlayer

-- ESP host: prefer the executor's hidden container so ESP objects are not
-- parented into the game's own instance tree.
local GuiHost = (gethui and gethui()) or CoreGui

--=====================================================================
-- Library + loading screen
--=====================================================================

local function resolveLuminIcon()
    local b = TemplateConfig.Branding
    if not (writefile and isfile and getcustomasset) then return b.IconFallback end
    local ok, asset = pcall(function()
        if not isfile(b.IconFile) then writefile(b.IconFile, game:HttpGet(b.IconUrl)) end
        return getcustomasset(b.IconFile)
    end)
    return ok and asset or b.IconFallback
end

local Library = loadstring(game:HttpGet(TemplateConfig.Dependencies.LibraryUrl))()
_G.LuminHubLibrary = Library

local Loading = Library:CreateLoading({
    Title       = TemplateConfig.Loading.Title,
    Icon        = TemplateConfig.Branding.IconAssetId,
    CurrentStep = 1,
    TotalSteps  = TemplateConfig.Loading.TotalSteps,
})
Loading:SetMessage("Initializing")
Loading:SetDescription("Loading configuration...")
Loading:ShowSidebarPage(true)
Loading.Sidebar:AddLabel("User: " .. LocalPlayer.Name)
Loading.Sidebar:AddLabel("Version: " .. tostring(LRM_ScriptVersion or "Developer"))
Loading.Sidebar:AddLabel("Game: Steal An Egg")

local repo = "http://luminon.top/obsidian/"
local ThemeManager = loadstring(game:HttpGet(repo .. "Addons/ThemeManager.lua"))()
local SaveManager  = loadstring(game:HttpGet(repo .. "Addons/SaveManager.lua"))()

Loading:SetCurrentStep(2)
Loading:SetDescription("Loading game data...")

--=====================================================================
-- Game data
--=====================================================================

local Network   = ReplicatedStorage:WaitForChild("Network")
local Directory = ReplicatedStorage:WaitForChild("Directory")

local RarityConfig, AssetConfig, RebirthConfig, BaseConfig, TrailConfig
pcall(function()
    RarityConfig  = require(Directory.Rarity)
    AssetConfig   = require(Directory.Assets)
    RebirthConfig = require(Directory.Rebirths)
    BaseConfig    = require(Directory.Bases)
    TrailConfig   = require(Directory.Trails)
end)

-- Verified live: workspace.__OBJECTS.Areas.GuardAreas children are named
-- "<Area> Guard" and each holds a "Guard" model carrying an AreaId attribute.
local ZoneList = {
    "Abyss Ocean", "Cosmic", "Desert", "Forest", "Jungle",
    "Lake", "Prehistoric", "Snow", "Volcano",
}

-- Rarity tables ------------------------------------------------------
-- Built once. The old code rescanned AssetConfig.ByRarity (84 entries,
-- nested) on every single egg on every loop tick.

local RarityNumber   = {}   -- canonical rarity name -> number
local RarityColour   = {}   -- canonical rarity name -> Color3
local RarityOrder    = {}   -- ascending list of canonical rarity names
local AssetInfo      = {}   -- category -> { rarity, rarityNum, weight, earn, display }
local DisplayToAsset = {}   -- "Name [Rarity]" -> category

do
    local seen = {}
    if RarityConfig and RarityConfig.Rarities then
        for name, data in pairs(RarityConfig.Rarities) do
            if type(data) == "table" then
                local id  = data._id or name
                local num = tonumber(data.RarityNumber) or 0
                RarityNumber[name] = num
                if not RarityNumber[id] then RarityNumber[id] = num end
                if typeof(data.Color) == "Color3" then
                    RarityColour[name] = data.Color
                    RarityColour[id]   = RarityColour[id] or data.Color
                end
                if not seen[id] then
                    seen[id] = num
                end
            end
        end
    end

    -- Only rarities that eggs actually roll (AssetConfig.ByRarity keys).
    local pool = {}
    if AssetConfig and AssetConfig.ByRarity then
        for rarityName in pairs(AssetConfig.ByRarity) do
            table.insert(pool, rarityName)
        end
    end
    if #pool == 0 then
        for id in pairs(seen) do table.insert(pool, id) end
    end
    table.sort(pool, function(a, b)
        return (RarityNumber[a] or 0) < (RarityNumber[b] or 0)
    end)
    RarityOrder = pool

    if AssetConfig and AssetConfig.Directory then
        for category, entry in pairs(AssetConfig.Directory) do
            if type(entry) == "table" then
                local rarity = "Unknown"
                if type(entry.Rarity) == "table" then
                    rarity = entry.Rarity._id or rarity
                elseif type(entry.Rarity) == "string" then
                    rarity = entry.Rarity
                end
                local display = tostring(entry.DisplayName or category) .. " [" .. rarity .. "]"
                AssetInfo[category] = {
                    rarity    = rarity,
                    rarityNum = RarityNumber[rarity] or 0,
                    weight    = tonumber(entry.ModelWeight) or 0,
                    earn      = tonumber(entry.EarningRate) or 0,
                    display   = display,
                }
                DisplayToAsset[display] = category
            end
        end
    end
end

local EggNameList = {}
for display in pairs(DisplayToAsset) do table.insert(EggNameList, display) end
table.sort(EggNameList, function(a, b)
    local ca, cb = DisplayToAsset[a], DisplayToAsset[b]
    local ra = AssetInfo[ca] and AssetInfo[ca].rarityNum or 0
    local rb = AssetInfo[cb] and AssetInfo[cb].rarityNum or 0
    if ra ~= rb then return ra > rb end
    return a < b
end)

local TrailList = {}
if TrailConfig and TrailConfig.Directory then
    for name in pairs(TrailConfig.Directory) do table.insert(TrailList, name) end
    table.sort(TrailList)
end

local function rarityNum(name)
    if not name then return 0 end
    return RarityNumber[name] or 0
end

local function assetRarity(category)
    local info = AssetInfo[category]
    return info and info.rarity or nil
end

--=====================================================================
-- State
--=====================================================================

local Flags = {}
_G.LuminHubRunning = Running

local Status = {
    Steal = "Idle",
    Sell  = "Idle",
    Fuse  = "Idle",
    Guard = "Unknown",
    Farm  = "Idle",
}

-- Forward declaration: the Settings tab wires a button to this before
-- the watchdog section defines it.
local doRejoin

local CarryCooldowns, CarryFails = {}, {}
local GlobalCarryCooldown = 0
local PlaceCooldown       = 0
local InventoryFull       = false
local InventoryFullCount  = 0
local SnipeQueue          = {}
local WebhookSent         = {}

--=====================================================================
-- Remote helpers
--=====================================================================

-- The old invokeRemote returned only pcall's success flag, so every
-- "if ok then" treated a server-side rejection as a success.
-- This returns (transportOk, serverResult) and callers check both.
local function invokeRemote(name, ...)
    local remote = Network:FindFirstChild(name)
    if not (remote and remote:IsA("RemoteFunction")) then return false, nil end
    local args = table.pack(...)
    local ok, res = pcall(function()
        return remote:InvokeServer(table.unpack(args, 1, args.n))
    end)
    if not ok then return false, nil end
    return true, res
end

-- true only when the transport worked AND the server did not return false/nil
local function remoteSucceeded(name, ...)
    local ok, res = invokeRemote(name, ...)
    if not ok then return false end
    if res == false or res == nil then return false end
    return true
end

local function fireRemote(name, ...)
    local remote = Network:FindFirstChild(name)
    if not (remote and remote:IsA("RemoteEvent")) then return false end
    local args = table.pack(...)
    pcall(function() remote:FireServer(table.unpack(args, 1, args.n)) end)
    return true
end

--=====================================================================
-- Character helpers
--=====================================================================

local function getCharacter() return LocalPlayer.Character end

local function getRoot()
    local char = getCharacter()
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local char = getCharacter()
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

local function getSpeedStat()
    -- Verified: "Get Stats" returns an empty table in this build.
    -- The live values live on leaderstats.
    local ls = LocalPlayer:FindFirstChild("leaderstats")
    if not ls then return 0 end
    local speed = ls:FindFirstChild("Speed")
    return speed and tonumber(speed.Value) or 0
end

local function getMoneyStat()
    local ls = LocalPlayer:FindFirstChild("leaderstats")
    if not ls then return 0 end
    local m = ls:FindFirstChild("Money/s")
    return m and tonumber(m.Value) or 0
end

--=====================================================================
-- Anti-death  (keeps the character alive across tweens)
--=====================================================================

-- The game runs death/fall handling from RunService connections owned by
-- its AnalyticsDebug script. Tweening the root trips those handlers, so
-- they get disabled; everything else on those signals is left alone.
local function killACConns()
    for _, signal in ipairs({ "PreSimulation", "PostSimulation", "Heartbeat", "Stepped" }) do
        local ok, conns = pcall(function() return getconnections(RunService[signal]) end)
        if ok and conns then
            for _, c in ipairs(conns) do
                local f
                pcall(function() f = c.Function end)
                local src = f and select(2, pcall(function() return debug.info(f, "s") end)) or ""
                if type(src) == "string" and src:find("AnalyticsDebug") then
                    pcall(function() c.Enabled = false end)
                    pcall(function() c:Disable() end)
                end
            end
        end
    end
end

local function protectChar(char)
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false) end)
    pcall(function() hum.BreakJointsOnDeath = false end)
    pcall(function() hum.MaxHealth = math.huge hum.Health = math.huge end)
end

-- Lands the player on solid ground instead of inside an egg nest or in
-- mid-air, which is what makes a tween arrival survivable.
local function groundAt(pos)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local exclude = { getCharacter() }
    local objs = Workspace:FindFirstChild("__OBJECTS")
    local areas = objs and objs:FindFirstChild("Areas")
    local guardAreas = areas and areas:FindFirstChild("GuardAreas")
    if guardAreas then
        for _, area in ipairs(guardAreas:GetChildren()) do
            local nests = area:FindFirstChild("Nests")
            if nests then table.insert(exclude, nests) end
            local guard = area:FindFirstChild("Guard")
            if guard then table.insert(exclude, guard) end
        end
    end
    params.FilterDescendantsInstances = exclude
    local hit = Workspace:Raycast(pos + Vector3.new(0, 60, 0), Vector3.new(0, -600, 0), params)
    return hit and (hit.Position + Vector3.new(0, 3.2, 0)) or (pos + Vector3.new(0, 3, 0))
end

--=====================================================================
-- Movement  (Smart Tween / Instant)
--=====================================================================

local Move = {
    cancel    = false,
    moving    = false,   -- true while the hub is deliberately relocating us
    speed     = nil,   -- current adaptive speed, nil = use the slider value
    rollbacks = 0,
    lastNote  = "",
}

function Move:BaseSpeed()
    return math.max(tonumber(Flags.TweenSpeed) or 300, 20)
end

function Move:CurrentSpeed()
    return math.clamp(self.speed or self:BaseSpeed(), 20, 2000)
end

-- The server rolled us back: it rejected the per-tick displacement.
-- Drop the rate and try again -- repeated backoff converges on whatever
-- this server actually tolerates.
function Move:Penalise()
    local now = self:CurrentSpeed()
    self.speed = math.max(25, math.floor(now * 0.65))
    self.rollbacks = self.rollbacks + 1
    self.lastNote = string.format("rolled back, speed %d -> %d", now, self.speed)
end

-- Clean arrival: creep back toward the slider value so a one-off stall
-- does not pin us slow forever.
function Move:Reward()
    local base = self:BaseSpeed()
    if self.speed and self.speed < base then
        self.speed = math.min(base, math.floor(self.speed * 1.2) + 10)
        self.lastNote = string.format("clean, speed -> %d", self.speed)
    end
    self.rollbacks = 0
end

function Move:Stop()
    self.cancel = true
    local root = getRoot()
    if root and root.Anchored then root.Anchored = false end
end

-- One movement attempt. Rather than tweening the whole distance in one
-- go (which this game's character replication reverts), the root is
-- advanced in per-frame increments of speed*dt. Each step is small
-- enough to survive validation, and a step that fails to land is what
-- tells us the rate is too high.
function Move:Attempt(targetPos, timeout)
    local root = getRoot()
    if not root then self.moving = false return false, false end
    self.moving = true

    local speed  = self:CurrentSpeed()
    local start  = os.clock()
    local stalls = 0

    while os.clock() - start < timeout do
        if self.cancel then self.moving = false return false, false end
        root = getRoot()
        if not root then self.moving = false return false, false end

        local here = root.Position
        local toGo = targetPos - here
        local dist = toGo.Magnitude
        if dist <= 5 then self.moving = false return true, false end

        local dt   = RunService.Heartbeat:Wait()
        local step = math.min(speed * dt, dist)
        local want = here + toGo.Unit * step

        root.CFrame = CFrame.new(want)
        RunService.Heartbeat:Wait()

        root = getRoot()
        if not root then self.moving = false return false, false end

        -- How much of the step actually survived?
        local moved = (root.Position - here).Magnitude
        if moved < step * 0.35 then
            stalls = stalls + 1
            -- three consecutive rejected steps is a rollback, not a hiccup
            if stalls >= 3 then self.moving = false return false, true end
        else
            stalls = 0
        end
    end

    root = getRoot()
    local arrived = root and (root.Position - targetPos).Magnitude <= 12
    self.moving = false
    return arrived or false, not arrived
end

function Move:To(targetPos, timeoutSeconds)
    self.cancel = false
    local timeout = timeoutSeconds or 8

    -- Instant mode keeps the old snap behaviour for anyone who wants it.
    if Flags.InstantMove then
        local root = getRoot()
        if not root then return false end
        self.moving = true
        local deadline = os.clock() + math.min(timeout, 2)
        while os.clock() < deadline do
            if self.cancel then return false end
            root = getRoot()
            if not root then return false end
            root.CFrame = CFrame.new(targetPos)
            if (root.Position - targetPos).Magnitude < 6 then self.moving = false return true end
            task.wait(0.05)
        end
        root = getRoot()
        self.moving = false
        return (root and (root.Position - targetPos).Magnitude < 12) or false
    end

    for _ = 1, 5 do
        local ok, rolledBack = self:Attempt(targetPos, timeout)
        if ok then
            self:Reward()
            return true
        end
        if not rolledBack then return false end
        self:Penalise()
        Status.Steal = "Adapting: " .. self.lastNote
        task.wait(0.2)
    end
    return false
end

--=====================================================================
-- Plot helpers
--=====================================================================

local CachedPlot, CachedPlotAt = nil, 0

local function getMyPlot()
    if CachedPlot and CachedPlot.Parent and os.clock() - CachedPlotAt < 20 then
        return CachedPlot
    end
    local plots = Workspace:FindFirstChild("Plots")
    if not plots then return nil end
    local ok, state = invokeRemote("Plots: RequestState")
    if not ok or type(state) ~= "table" or type(state.OwnersBySlot) ~= "table" then
        return nil
    end
    for slot, userId in pairs(state.OwnersBySlot) do
        if userId == LocalPlayer.UserId then
            local plot = plots:FindFirstChild(tostring(slot))
            if plot then
                CachedPlot, CachedPlotAt = plot, os.clock()
                return plot
            end
        end
    end
    return nil
end

local function getPlotCenter()
    local plot = getMyPlot()
    if not plot then return nil end
    local center = plot:FindFirstChild("CenterPoint") or plot:FindFirstChild("SpawnPoint")
    if center then return center.Position end
    if plot.PrimaryPart then return plot.PrimaryPart.Position end
    return nil
end

local function isAtBase()
    local center = getPlotCenter()
    local root   = getRoot()
    if not (center and root) then return false end
    return (root.Position - center).Magnitude < 150
end

--=====================================================================
-- Selection helpers
--=====================================================================

-- Multi-select dropdowns hand back a set ({Forest = true}), single-select
-- ones hand back a bare string, and a cleared dropdown hands back nil.
-- Normalise all three into a set, or nil meaning "no filter".
local function listToSet(value)
    if value == nil then return nil end

    if type(value) == "string" then
        if value == "" then return nil end
        return { [value] = true }
    end

    if type(value) ~= "table" then return nil end

    local set, count = {}, 0
    -- array form: { "Forest", "Desert" }
    for _, v in ipairs(value) do
        if type(v) == "string" then
            set[v] = true
            count = count + 1
        end
    end
    -- set form: { Forest = true, Desert = false }
    if count == 0 then
        for k, v in pairs(value) do
            if v == true and type(k) == "string" then
                set[k] = true
                count = count + 1
            end
        end
    end

    if count == 0 then return nil end
    return set
end

--=====================================================================
-- Guards
--=====================================================================

local function getGuardAreas()
    local objs = Workspace:FindFirstChild("__OBJECTS")
    if not objs then return nil end
    local areas = objs:FindFirstChild("Areas")
    if not areas then return nil end
    return areas:FindFirstChild("GuardAreas")
end

-- Returns a list of { areaId, awake, state, distance }.
local function getGuardReport()
    local report = {}
    local container = getGuardAreas()
    if not container then return report end
    local root = getRoot()
    for _, area in ipairs(container:GetChildren()) do
        local guard = area:FindFirstChild("Guard")
        if guard then
            -- The model is named "<Area> Guard"; the AreaId attribute holds
            -- the bare zone name that egg records use.
            local areaId = guard:GetAttribute("AreaId")
                or (area.Name:gsub("%s*Guard$", ""))
            local sleeping = guard:GetAttribute("Sleeping")
            local state    = guard:GetAttribute("GuardState")
            local awake    = (sleeping ~= true) or (state ~= nil and state ~= "Sleeping")
            local dist
            local gRoot = guard:FindFirstChild("HumanoidRootPart")
            if gRoot and root then dist = (gRoot.Position - root.Position).Magnitude end
            table.insert(report, {
                areaId = areaId,
                awake  = awake,
                state  = state or (sleeping == true and "Sleeping" or "Unknown"),
                dist   = dist,
                model  = guard,
            })
        end
    end
    return report
end

-- Reads the guard's AreaId attribute rather than the container's name, so
-- the zone match survives any renaming of the GuardAreas children.
local function isGuardAwake(selectedZones)
    local zoneFilter = listToSet(selectedZones)
    for _, g in ipairs(getGuardReport()) do
        if (not zoneFilter) or zoneFilter[g.areaId] then
            if g.awake then
                if Flags.ForestGuardBypass and g.areaId == "Forest" then
                    -- Forest guard is deposit-based, not a kill guard.
                else
                    return true, g.areaId
                end
            end
        end
    end
    return false
end

--=====================================================================
-- Egg / pet data
--=====================================================================

local function getAreaEggs()
    local ok, data = invokeRemote("Eggs: RequestAreaEggSnapshot")
    if not ok or type(data) ~= "table" then return {} end
    return data.Records or {}
end

local function extractOwnRecords(data)
    if type(data) ~= "table" then return {} end
    for _, v in pairs(data) do
        if type(v) == "table" and v.OwnerUserId == LocalPlayer.UserId and type(v.Records) == "table" then
            return v.Records
        end
    end
    for _, v in pairs(data) do
        if type(v) == "table" and type(v.Records) == "table" then return v.Records end
    end
    return {}
end

local function getMyEggs()
    local ok, data = invokeRemote("Eggs: RequestRuntimeSnapshot")
    if not ok then return {} end
    return extractOwnRecords(data)
end

local function getPets()
    local ok, data = invokeRemote("ActiveAssets: RequestRuntimeSnapshot")
    if not ok then return {} end
    return extractOwnRecords(data)
end

local function countTable(t)
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
end

local function getBestPets()
    local sorted = {}
    for uid, pet in pairs(getPets()) do
        local itemData = pet.ItemData or {}
        if not itemData.InFuse then
            table.insert(sorted, { uid = uid, mps = pet.MoneyPerSecond or 0, data = pet })
        end
    end
    table.sort(sorted, function(a, b) return a.mps > b.mps end)
    return sorted
end

local function getEquippedCategories()
    local equipped = {}
    local char = getCharacter()
    if char then
        for _, item in ipairs(char:GetChildren()) do
            if item:IsA("Tool") then equipped[item.Name] = true end
        end
    end
    return equipped
end

-- "Weight" is the asset's ModelWeight scaled by the rolled AssetScale.
local function getEggWeight(egg)
    local info = AssetInfo[egg.AssetCategory]
    local base = info and info.weight or 0
    local scale = tonumber(egg.AssetScale) or 1
    return base * scale
end

local function getEggMutations(egg)
    local out = {}
    if type(egg.Mutations) == "table" then
        for _, m in pairs(egg.Mutations) do table.insert(out, tostring(m)) end
    end
    return out
end

--=====================================================================
-- Egg filtering
--=====================================================================

local function eggPassesFilters(egg)
    if egg.State ~= "Slot" and not Flags.SnipeDropped then return false end
    if string.find(egg.Uid or "", "FirstAreaEgg") then return false end

    local category = egg.AssetCategory
    if not category then return false end

    -- zone
    local zoneSet = listToSet(Flags.StealZones)
    if zoneSet and egg.AreaId and not zoneSet[egg.AreaId] then return false end

    -- minimum rarity
    local minR = Flags.FarmMinRarity
    if minR and minR ~= "" then
        if rarityNum(assetRarity(category)) < rarityNum(minR) then return false end
    end

    -- explicit rarity multi-select (exact match, when used)
    local rarSet = listToSet(Flags.StealRarities)
    if rarSet and not rarSet[assetRarity(category)] then return false end

    -- explicit egg multi-select
    local eggSet = listToSet(Flags.SelectEggs)
    if eggSet then
        local info = AssetInfo[category]
        if not (info and eggSet[info.display]) then return false end
    end

    -- mutation multi-select
    local mutSet = listToSet(Flags.SelectMutations)
    if mutSet then
        local found = false
        for _, m in ipairs(getEggMutations(egg)) do
            if mutSet[m] then found = true break end
        end
        if not found then return false end
    end

    -- weight floor
    local minW = tonumber(Flags.MinEggWeight) or 0
    if minW > 0 and getEggWeight(egg) < minW then return false end

    return true
end

local function eggScore(egg)
    local info = AssetInfo[egg.AssetCategory]
    local r = info and info.rarityNum or 0
    return r * 1e9 + getEggWeight(egg)
end

local function pickTargetEgg(eggs)
    local candidates = {}
    for _, egg in pairs(eggs) do
        if eggPassesFilters(egg) and not (
            (CarryCooldowns[egg.Uid] or 0) > os.clock() or GlobalCarryCooldown > os.clock()
        ) then
            table.insert(candidates, egg)
        end
    end
    if #candidates == 0 then return nil end

    if Flags.PrioritySystem ~= false then
        table.sort(candidates, function(a, b) return eggScore(a) > eggScore(b) end)
    elseif Flags.DistantTarget then
        local root = getRoot()
        if root then
            table.sort(candidates, function(a, b)
                local pa = a.BoundsCFrame and a.BoundsCFrame.Position or Vector3.zero
                local pb = b.BoundsCFrame and b.BoundsCFrame.Position or Vector3.zero
                return (pa - root.Position).Magnitude > (pb - root.Position).Magnitude
            end)
        end
    else
        local root = getRoot()
        if root then
            table.sort(candidates, function(a, b)
                local pa = a.BoundsCFrame and a.BoundsCFrame.Position or Vector3.zero
                local pb = b.BoundsCFrame and b.BoundsCFrame.Position or Vector3.zero
                return (pa - root.Position).Magnitude < (pb - root.Position).Magnitude
            end)
        end
    end
    return candidates[1]
end

--=====================================================================
-- Carry cooldown bookkeeping
--=====================================================================

local function markCarryFail(uid)
    local fails = (CarryFails[uid] or 0) + 1
    CarryFails[uid] = fails
    CarryCooldowns[uid] = os.clock() + math.min(5 + fails * 3, 25)
    local total = 0
    for _, n in pairs(CarryFails) do total = total + n end
    if total >= 5 then GlobalCarryCooldown = os.clock() + 10 end
end

local function clearCarryFail(uid)
    CarryFails[uid] = nil
    CarryCooldowns[uid] = nil
end

--=====================================================================
-- Loop scheduler
--=====================================================================

local function startLoop(name, func)
    if Running[name] then return end
    Running[name] = true
    local myGen = ScriptGeneration
    task.spawn(function()
        while Running[name] and myGen == _G.LuminHubGeneration do
            local ok, err = pcall(func)
            if not ok and Flags.DebugMode then warn("[LuminHub] " .. name .. ": " .. tostring(err)) end
            task.wait()
        end
        Running[name] = false
    end)
end

local function stopLoop(name) Running[name] = false end

-- A generation-guarded spawn for one-off background threads, so they die
-- on unload instead of surviving into the next execution.
local function spawnTracked(fn)
    local handle = { alive = true }
    table.insert(Threads, handle)
    local myGen = ScriptGeneration
    task.spawn(function()
        while handle.alive and myGen == _G.LuminHubGeneration do
            local ok = pcall(fn)
            if not ok then break end
        end
    end)
    return handle
end

local function showToast(title, desc)
    pcall(function()
        Library:Notify({ Title = title, Description = desc or "", Time = 3 })
    end)
end

--=====================================================================
-- UI confirmation clicking
--=====================================================================

local function clickGuiButton(button)
    if not (button and button:IsA("GuiButton")) then return false end
    local visible = button.Visible
    local p = button.Parent
    while visible and p and p:IsA("GuiObject") do
        if not p.Visible then visible = false end
        p = p.Parent
    end
    if not visible then return false end

    if firesignal then
        pcall(function() firesignal(button.Activated) end)
    end
    if getconnections then
        pcall(function()
            for _, c in ipairs(getconnections(button.Activated)) do c:Fire() end
        end)
        pcall(function()
            for _, c in ipairs(getconnections(button.MouseButton1Click)) do c:Fire() end
        end)
    end
    return true
end

local function clickYesButton()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return false end
    local msgGui = pg:FindFirstChild("Message")
    if not msgGui then return false end
    local yes = msgGui:FindFirstChild("Yes", true)
    return clickGuiButton(yes)
end

--=====================================================================
-- ESP
--=====================================================================

-- ESP ----------------------------------------------------------------
-- Everything is parented to the executor GUI host and adorned, so no
-- objects are inserted into the game's own tree. Each entry owns a
-- Highlight, a BillboardGui and an optional tracer, tracked under one
-- key so cleanup can never leak.

local Camera = Workspace.CurrentCamera

local function resolvePart(inst)
    if not inst then return nil end
    if inst:IsA("BasePart") then return inst end
    if inst:IsA("Model") then
        return inst.PrimaryPart
            or inst:FindFirstChild("HumanoidRootPart")
            or inst:FindFirstChild("Hitbox")
            or inst:FindFirstChildWhichIsA("BasePart", true)
    end
    return nil
end

local EspEntries = {}   -- key -> { part, gui, label, highlight, tracer }

local function espDestroy(key)
    local e = EspEntries[key]
    if not e then return end
    for _, k in ipairs({ "gui", "highlight", "tracer" }) do
        if e[k] then pcall(function() e[k]:Destroy() end) end
    end
    EspEntries[key] = nil
    Visuals["esp_" .. key] = nil
end

local function espClear(prefix)
    for key in pairs(EspEntries) do
        if (not prefix) or key:sub(1, #prefix) == prefix then espDestroy(key) end
    end
end

-- opts: colour, text, highlight (bool), tracer (bool), maxDistance
local function espUpsert(key, adornee, opts)
    local part = resolvePart(adornee)
    if not part then espDestroy(key) return end

    local e = EspEntries[key]
    if e and e.part ~= part then
        espDestroy(key)
        e = nil
    end

    if not e then
        local gui = Instance.new("BillboardGui")
        gui.Name          = "LuminESP"
        gui.Adornee       = part
        gui.Size          = UDim2.fromOffset(220, 42)
        gui.StudsOffset   = Vector3.new(0, 2.8, 0)
        gui.AlwaysOnTop   = true
        gui.ResetOnSpawn  = false
        gui.ClipsDescendants = false

        local label = Instance.new("TextLabel")
        label.Name                   = "Info"
        label.Size                   = UDim2.fromScale(1, 1)
        label.BackgroundTransparency = 1
        label.TextScaled             = false
        label.TextSize               = 14
        label.Font                   = Enum.Font.GothamBold
        label.RichText               = true
        label.TextStrokeTransparency = 0.35
        label.TextStrokeColor3       = Color3.new(0, 0, 0)
        label.TextYAlignment         = Enum.TextYAlignment.Bottom
        label.Parent                 = gui

        gui.Parent = GuiHost
        pcall(protectgui, gui)

        e = { part = part, gui = gui, label = label }
        EspEntries[key] = e
        Visuals["esp_" .. key] = gui
    end

    local colour = opts.colour or Color3.new(1, 1, 1)

    -- highlight
    if opts.highlight then
        if not e.highlight then
            local hl = Instance.new("Highlight")
            hl.Name                = "LuminHL"
            hl.Adornee             = part
            hl.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
            hl.FillTransparency    = 0.62
            hl.OutlineTransparency = 0
            hl.Parent              = GuiHost
            e.highlight = hl
        end
        e.highlight.FillColor    = colour
        e.highlight.OutlineColor = colour
    elseif e.highlight then
        pcall(function() e.highlight:Destroy() end)
        e.highlight = nil
    end

    -- tracer from the bottom of the screen
    if opts.tracer then
        if not e.tracer and Drawing then
            local ok, line = pcall(function() return Drawing.new("Line") end)
            if ok then
                line.Thickness = 1
                line.Visible   = false
                e.tracer = line
            end
        end
    elseif e.tracer then
        pcall(function() e.tracer:Remove() end)
        pcall(function() e.tracer:Destroy() end)
        e.tracer = nil
    end

    local root = getRoot()
    local dist = root and (part.Position - root.Position).Magnitude or 0
    local maxD = opts.maxDistance or 5000
    local show = dist <= maxD

    e.gui.Enabled = show
    if e.highlight then e.highlight.Enabled = show end

    if show then
        e.label.Text = string.format(
            '<font color="#%s">%s</font>  <font color="#c8c8c8">%dm</font>',
            colour:ToHex(), opts.text or key, math.floor(dist))
        e.label.TextColor3 = colour
    end

    if e.tracer then
        if show then
            local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
            if onScreen then
                e.tracer.Visible = true
                e.tracer.Color   = colour
                e.tracer.From    = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                e.tracer.To      = Vector2.new(sp.X, sp.Y)
            else
                e.tracer.Visible = false
            end
        else
            e.tracer.Visible = false
        end
    end
end

--=====================================================================
-- GodMode
--=====================================================================
--
-- Guard hits do three things: they fling you, they ragdoll you, and they
-- knock the egg out of your hands (DropReasons.GuardHit). GodMode
-- cancels all three so a carry run cannot be interrupted.
--
-- The carry-state event only reports { IsCarrying, Uid, AreaId,
-- AssetCategory, SpeedMultiplier } -- there is no drop reason on it. So
-- the hub marks its own deliberate drops, and any other transition from
-- carrying to not-carrying is treated as a hit and re-grabbed. Without
-- that distinction GodMode would fight the farm loop by snatching the
-- egg back up the instant it was delivered to the plot.

local God = {
    carrying        = false,
    carryUid        = nil,
    carryArea       = nil,
    intentionalDrop = false,
    regrabs         = 0,
    lastHit         = 0,
    regrabbing      = false,
    flings          = 0,
    lastRegrab      = 0,
    burst           = 0,
    burstStart      = 0,
}

-- Anything above this is a knockback, not running.
local FLING_VELOCITY = 60
-- A single frame never legitimately moves you this far on foot.
local FLING_STEP     = 10
-- How long to pin the character after a hit lands.
local FLING_LOCK     = 1.25

-- Position lock. The knockback is applied server-side -- there is no
-- client code doing it, so clamping our own velocity happens after the
-- displacement has already replicated. Instead we remember where we were
-- standing and, the moment a frame moves us further than walking could,
-- put us straight back and hold there. This cancels the fling whatever
-- mechanism produced it: velocity, impulse, or a server CFrame write.
local Fling = { lastPos = nil, lockUntil = 0, anchor = nil }

local function godAntiFling()
    local root = getRoot()
    if not root then Fling.lastPos = nil return end

    local now = os.clock()

    -- Never fight our own movement.
    if Move.moving or Flags.Fly then
        Fling.lastPos   = root.Position
        Fling.lockUntil = 0
        return
    end

    if now < Fling.lockUntil and Fling.anchor then
        root.CFrame                 = CFrame.new(Fling.anchor)
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        return
    end

    local pos = root.Position
    if Fling.lastPos then
        local step = (pos - Fling.lastPos).Magnitude
        local vel  = root.AssemblyLinearVelocity.Magnitude
        if step > FLING_STEP or vel > FLING_VELOCITY then
            Fling.anchor    = Fling.lastPos
            Fling.lockUntil = now + FLING_LOCK
            God.lastHit     = now
            God.flings      = (God.flings or 0) + 1
            root.CFrame                 = CFrame.new(Fling.anchor)
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            return
        end
    end
    Fling.lastPos = pos
end

local function godStripMovers(char)
    if not char then return end
    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("BodyVelocity") or d:IsA("BodyAngularVelocity") or d:IsA("BodyThrust")
            or d:IsA("BodyForce") or d:IsA("BodyGyro") or d:IsA("VectorForce")
            or d:IsA("LinearVelocity") or d:IsA("AngularVelocity") then
            -- leave the hub's own fly movers alone
            if d ~= Visuals["_fly_bv"] and d ~= Visuals["_fly_bg"] then
                pcall(function() d:Destroy() end)
            end
        end
    end
end

local function godCalmCharacter()
    local char = getCharacter()
    if not char then return end
    local root = getRoot()
    local hum  = getHumanoid()

    if root and not Flags.Fly then
        local vel = root.AssemblyLinearVelocity
        if vel.Magnitude > FLING_VELOCITY then
            root.AssemblyLinearVelocity = Vector3.new(0, math.clamp(vel.Y, -50, 0), 0)
            God.lastHit = os.clock()
        end
        if root.AssemblyAngularVelocity.Magnitude > 10 then
            root.AssemblyAngularVelocity = Vector3.zero
        end
    end

    if hum then
        if hum.PlatformStand and not Flags.Fly then hum.PlatformStand = false end
        local state = hum:GetState()
        if state == Enum.HumanoidStateType.Ragdoll
            or state == Enum.HumanoidStateType.FallingDown
            or state == Enum.HumanoidStateType.Physics
            or state == Enum.HumanoidStateType.Seated then
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
            God.lastHit = os.clock()
        end
    end
end

local function godHardenHumanoid(char)
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    for _, s in ipairs({
        Enum.HumanoidStateType.Ragdoll,
        Enum.HumanoidStateType.FallingDown,
        Enum.HumanoidStateType.Physics,
        Enum.HumanoidStateType.Dead,
    }) do
        pcall(function() hum:SetStateEnabled(s, false) end)
    end
    pcall(function() hum.BreakJointsOnDeath = false end)
end

-- Re-grab the egg the guard just knocked loose.
--
-- Single-flight and rate limited. Testing showed that without this every
-- drop event spawns another re-grab thread, and a flickering carry state
-- makes them pile up and fight each other -- the egg oscillates between
-- Dropped and Carried and the attempt count runs away.
local function godRegrab(uid)
    if not uid then return false end
    if God.regrabbing then return false end
    if os.clock() - (God.lastRegrab or 0) < 1.25 then return false end

    -- If the server keeps taking it straight back, stop fighting it.
    if God.burst and God.burst > 4 and os.clock() - (God.burstStart or 0) < 10 then
        Status.Steal = "GodMode: server keeps dropping, backing off"
        return false
    end
    if os.clock() - (God.burstStart or 0) > 10 then
        God.burst, God.burstStart = 0, os.clock()
    end

    local remote = Network:FindFirstChild("Eggs: RequestAreaEggCarry")
    if not remote then return false end

    God.regrabbing = true
    God.lastRegrab = os.clock()
    God.burst = (God.burst or 0) + 1

    local function finish(v)
        God.regrabbing = false
        return v
    end

    local deadline = os.clock() + 6
    while os.clock() < deadline do
        if not Flags.GodMode then return finish(false) end
        if God.carrying then return finish(true) end

        local ok, res = pcall(function()
            return remote:InvokeServer({ Uid = uid })
        end)
        if ok and res == true then
            God.regrabs = God.regrabs + 1
            God.carrying = true
            God.carryUid = uid
            Status.Steal = "GodMode: re-grabbed after hit (" .. God.regrabs .. ")"
            return finish(true)
        end

        -- A dropped egg lands at our feet; nudge onto it and retry.
        local root = getRoot()
        if root then
            for _, rec in pairs(getAreaEggs()) do
                if rec.Uid == uid and rec.BoundsCFrame then
                    pcall(function()
                        root.CFrame = CFrame.new(groundAt(rec.BoundsCFrame.Position))
                    end)
                    break
                end
            end
        end
        task.wait(0.15)
    end
    return finish(false)
end

-- Called by the hub whenever it drops on purpose.
local function godMarkIntentionalDrop()
    God.intentionalDrop = true
    task.delay(1.5, function() God.intentionalDrop = false end)
end

do
    local carryState = Network:FindFirstChild("Eggs: AreaEggCarryState")
    if carryState and carryState:IsA("RemoteEvent") then
        trackConn(carryState.OnClientEvent:Connect(function(payload)
            if type(payload) ~= "table" then return end
            local wasCarrying = God.carrying
            local lastUid     = God.carryUid

            God.carrying = payload.IsCarrying == true
            if God.carrying then
                God.carryUid  = payload.Uid or lastUid
                God.carryArea = payload.AreaId or God.carryArea
                return
            end

            -- carrying -> not carrying
            if not (Flags.GodMode and wasCarrying) then return end
            if God.intentionalDrop then return end

            local uid = payload.Uid or lastUid
            task.spawn(function() godRegrab(uid) end)
        end))
    end
end

--=====================================================================
-- Pet actions
--=====================================================================

local function sellPetsByFilter(minKeepRarity, exactSet)
    local equipped = getEquippedCategories()
    local sold = 0
    for uid, pet in pairs(getPets()) do
        local itemData = pet.ItemData or {}
        local category = itemData.Category
        local mutated  = itemData.Mutations and next(itemData.Mutations) ~= nil
        local inFuse   = itemData.InFuse
        local isEquipped = category and equipped[category]

        local blocked = inFuse
            or (Flags.NeverSellMutated ~= false and mutated)
            or (Flags.NeverSellEquipped ~= false and isEquipped)

        if not blocked and category then
            local rar = assetRarity(category)
            local shouldSell
            if exactSet then
                shouldSell = exactSet[rar] == true
            else
                -- keep anything at or above the keep threshold
                shouldSell = rarityNum(rar) < rarityNum(minKeepRarity)
            end
            if shouldSell then
                if remoteSucceeded("ActiveAssets: RequestSell", uid) then
                    sold = sold + 1
                    Status.Sell = "Sold " .. category
                    task.wait(math.max(tonumber(Flags.SellDelay) or 0, 0.05))
                end
            end
        end
    end
    return sold
end

local function deleteOwnPets()
    local equipped = getEquippedCategories()
    local count = 0
    for uid, pet in pairs(getPets()) do
        local itemData = pet.ItemData or {}
        local mutated  = itemData.Mutations and next(itemData.Mutations) ~= nil
        if not itemData.InFuse and not mutated and not equipped[itemData.Category] then
            if remoteSucceeded("ActiveAssets: RequestSell", uid) then count = count + 1 end
            task.wait(0.05)
        end
    end
    return count
end

-- BUG FIX: the old version fired StartFuse before inserting mobs, and its
-- retry used "i = i - 1" inside a numeric for loop, which does nothing.
local function autoFusePets(maxPairs)
    local pets = getBestPets()
    local fused = 0
    local index = 1
    local pairsWanted = math.min(maxPairs or 1, math.floor(#pets / 2))

    while fused < pairsWanted and index + 1 <= #pets do
        local p1, p2 = pets[index], pets[index + 1]
        index = index + 2
        if not (p1 and p2) then break end

        local d1 = p1.data.ItemData or {}
        local d2 = p2.data.ItemData or {}
        if not (d1.InFuse or d2.InFuse) then
            local in1 = remoteSucceeded("FuseMachine: InsertMob", p1.uid)
            local in2 = remoteSucceeded("FuseMachine: InsertMob", p2.uid)
            if in1 and in2 then
                if remoteSucceeded("FuseMachine: StartFuse") then
                    task.wait(0.35)
                    invokeRemote("FuseMachine: CompleteReveal")
                    invokeRemote("FuseMachine: AcknowledgeInfo")
                    fused = fused + 1
                end
            end
            -- always clear the machine so a failed pair does not jam it
            invokeRemote("FuseMachine: RemoveMob", p1.uid)
            invokeRemote("FuseMachine: RemoveMob", p2.uid)
            task.wait(0.6)
        end
    end
    return fused
end

--=====================================================================
-- Steal cycle
--=====================================================================

-- The server tracks whether you have entered the play corridor, and it
-- only registers when you cross the entry plane under humanoid control --
-- teleporting straight to an egg is refused with "Enter the gameplay area
-- first" no matter how close you land. Verified live: after this routine
-- the identical carry request returns true.
local GameplayEntered = false

local function enterGameplayArea()
    local root, hum = getRoot(), getHumanoid()
    local objs  = Workspace:FindFirstChild("__OBJECTS")
    local areas = objs and objs:FindFirstChild("Areas")
    local start = areas and areas:FindFirstChild("StartArea")
    if not (root and hum and start) then return false end

    Status.Steal = "Entering gameplay area"
    root.CFrame = CFrame.new(groundAt(start.Position - Vector3.new(6, 0, 0)))
    task.wait(1.2)

    local goal = start.Position + Vector3.new(40, 0, 0)
    local t0 = os.clock()
    while os.clock() - t0 < 12 do
        root = getRoot()
        if not root then return false end
        if (root.Position - goal).Magnitude <= 8 then break end
        hum = getHumanoid()
        if hum then hum:MoveTo(goal) end
        task.wait(0.2)
    end

    GameplayEntered = true
    return true
end

local function placeHeldEggs(limit)
    local placed = 0
    local eggs = getMyEggs()
    for uid in pairs(eggs) do
        local ok, res = invokeRemote("Eggs: RequestPlaceEgg", {
            Uid = uid, LocalCFrame = CFrame.new(0, 0, 0),
        })
        if ok and res ~= false and res ~= nil then
            placed = placed + 1
            InventoryFull = false
        else
            InventoryFull = true
            InventoryFullCount = countTable(eggs)
            PlaceCooldown = os.clock() + 15
            break
        end
        task.wait(math.max(tonumber(Flags.FarmDelay) or 0, 0.1))
        if limit and placed >= limit then break end
    end
    return placed
end

local function stealOnce(target)
    local root = getRoot()
    local plotCenter = getPlotCenter()
    if not (root and plotCenter and target) then return false end

    local targetCFrame = target.BoundsCFrame or target.BottomCFrame
    if typeof(targetCFrame) ~= "CFrame" then return false end
    -- Land on the ground beside the nest rather than inside it.
    local targetPos = groundAt(targetCFrame.Position)

    Status.Steal = "Travelling to " .. (target.AssetCategory or "?")
    if not Move:To(targetPos) then
        Status.Steal = "Travel interrupted"
        return false
    end

    -- Hold position while the carry request resolves. The prompt's
    -- MaxActivationDistance is 8 studs in this build.
    --
    -- The remote answers (ok, reason): the server hands back a readable
    -- string such as "Enter the gameplay area first" when it refuses.
    -- Surfacing it beats retrying blindly into a cooldown.
    local carried, reason = false, nil
    for _ = 1, 5 do
        root = getRoot()
        if not root then break end
        root.CFrame = CFrame.new(targetPos)
        local remote = Network:FindFirstChild("Eggs: RequestAreaEggCarry")
        if not remote then break end
        local ok, res, why = pcall(function()
            return remote:InvokeServer({ Uid = target.Uid })
        end)
        if ok and res == true then
            carried = true
            clearCarryFail(target.Uid)
            break
        end
        if ok and type(why) == "string" then reason = why end
        task.wait(0.12)
    end

    if not carried then
        markCarryFail(target.Uid)
        if reason then
            Status.Steal = "Blocked: " .. reason
            -- This refusal is about the player, not the egg, so it would hit
            -- every egg in turn. Re-enter the corridor and clear the strike.
            if reason:lower():find("gameplay area") then
                GameplayEntered = false
                clearCarryFail(target.Uid)
                enterGameplayArea()
            end
        else
            Status.Steal = "Carry failed: " .. (target.AssetCategory or "?")
        end
        return false
    end

    Status.Steal = "Returning with " .. (target.AssetCategory or "?")
    Move:To(plotCenter)
    -- Deliberate: GodMode must not snatch this back off the plot.
    godMarkIntentionalDrop()
    invokeRemote("Eggs: RequestAreaEggDrop", {})
    task.wait(0.25)

    if Flags.AutoPlaceAfterSteal and PlaceCooldown < os.clock() then
        -- Instant Place empties the whole inventory; otherwise place one.
        local placed = placeHeldEggs(if Flags.InstantPlace then nil else 1)
        if placed > 0 then
            Status.Steal = "Stole + placed " .. (target.AssetCategory or "?")
        else
            Status.Steal = "Inventory/plot full - placing paused"
        end
    else
        Status.Steal = "Stole " .. (target.AssetCategory or "?")
    end
    return true
end

--=====================================================================
-- Webhook
--=====================================================================

local function sendWebhook(egg)
    local url = Flags.WebhookUrl
    if not url or url == "" or not httprequest then return end
    if WebhookSent[egg.Uid] then return end
    WebhookSent[egg.Uid] = true

    local info = AssetInfo[egg.AssetCategory] or {}
    local body = HttpService:JSONEncode({
        content = (Flags.WebhookMention ~= "" and Flags.WebhookMention or nil),
        embeds = { {
            title = "Rare egg spawned",
            color = 16007990,
            fields = {
                { name = "Egg",    value = tostring(info.display or egg.AssetCategory), inline = true },
                { name = "Area",   value = tostring(egg.AreaId or "?"),                 inline = true },
                { name = "Weight", value = string.format("%.1f", getEggWeight(egg)),    inline = true },
                { name = "Server", value = game.JobId,                                  inline = false },
            },
        } },
    })
    pcall(function()
        httprequest({
            Url = url,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = body,
        })
    end)
end

--=====================================================================
-- Interface
--=====================================================================

Loading:SetCurrentStep(3)
Loading:SetDescription("Building interface...")
task.wait()

local Options = Library.Options
local Toggles = Library.Toggles
Library.NotifyOnError = true
Library.ForceCheckbox  = true

local windowSize = Library.IsMobile and TemplateConfig.Interface.MobileSize
    or TemplateConfig.Interface.DesktopSize

local Window = Library:CreateWindow({
    Title         = TemplateConfig.Branding.WindowTitle,
    Footer        = TemplateConfig.Branding.Footer,
    Size          = windowSize,
    Icon          = resolveLuminIcon(),
    ToggleKeybind = TemplateConfig.Interface.ToggleKeybind,
    Center        = true,
    AutoShow      = true,
    CornerRadius  = TemplateConfig.Interface.CornerRadius,
})

local Tabs = {
    Home       = Window:AddTab("Home",       "square-user",      "Account, game, and script information."),
    Farm       = Window:AddTab("Farm",       "flag",             "Egg stealing and filters."),
    Automation = Window:AddTab("Automation", "cpu",              "Eggs, pets, and progression."),
    Sell       = Window:AddTab("Sell",       "coins",            "Selling, fusing, and inventory."),
    Visual     = Window:AddTab("Visual",     "eye",              "ESP, intel, and movement."),
    Utility    = Window:AddTab("Utility",    "wrench",           "Player, server, and performance."),
    Config     = Window:AddTab("Settings",   "settings",         "Interface, themes, and configs."),
}

do
    local expected = tonumber(TemplateConfig.Game.ExpectedPlaceVersion) or 0
    local current  = tonumber(game.PlaceVersion) or 0
    if expected > 0 and current > expected then
        Tabs.Home:UpdateWarningBox({
            Visible = true,
            Title   = "WARNING",
            Text    = ("Built for place version %d, this server is %d. Some features may be out of date.")
                :format(expected, current),
        })
    else
        Tabs.Home:UpdateWarningBox({ Visible = false })
    end
end

--=====================================================================
-- HOME
--=====================================================================

do
    local totalSeconds    = tonumber(LRM_SecondsLeft) or 0
    local totalExecutions = tonumber(LRM_TotalExecutions) or 0
    local method, timeLeft

    if totalSeconds == -1 or totalSeconds == math.huge then
        timeLeft, method = "Lifetime / Infinite", "Lifetime Key"
    elseif totalSeconds > 0 then
        timeLeft = string.format("%d days, %d hours, %d minutes",
            math.floor(totalSeconds / 86400),
            math.floor((totalSeconds % 86400) / 3600),
            math.floor((totalSeconds % 3600) / 60))
        method = "Key System"
    else
        timeLeft, method = "Unknown", "Developer Script"
    end

    local ok, url, ready = pcall(function()
        return Players:GetUserThumbnailAsync(
            LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
    end)

    local panel
    pcall(function()
        panel = Tabs.Home:AddPlayerPanel({
            AssetId       = ok and url or nil,
            ImageSize     = UDim2.fromOffset(64, 64),
            AvatarBoxSize = UDim2.fromOffset(72, 72),
            Height        = 100,
            TopOffset     = 10,
            Title         = string.format(
                '<b>Welcome To <font color="rgb(199, 0, 255)">Lumin</font>, @%s!</b>', LocalPlayer.Name),
            Subtitle      = "",
            Lines         = {
                string.format('Method: <b><font color="rgb(199, 0, 255)">%s</font></b>', method),
                string.format('Execution Amount: <b><font color="rgb(199, 0, 255)">%s</font></b>', totalExecutions),
                string.format('Remaining Time: <b><font color="rgb(199, 0, 255)">%s</font></b>', timeLeft),
            },
        })
    end)

    local Credits = Tabs.Home:AddLeftGroupbox("Credits", "sparkle")
    Credits:AddLabel("Credits To Lumin Developers:\nThanks for supporting Lumin Hub :p")
    Credits:AddCopyLabel("CopyDiscord", {
        Text    = "discord.gg/luminhub",
        Value   = "https://discord.gg/luminhub",
        Tooltip = "Click to copy",
        Color   = Color3.fromRGB(200, 0, 120),
        Size    = 14,
    })

    local GameBox = Tabs.Home:AddLeftGroupbox("Game", "app-window")
    GameBox:AddLabel("Place Version: " .. game.PlaceVersion)
    local statLabel = GameBox:AddLabel("Stats:\nLoading...", true)
    local timeLabel = GameBox:AddLabel("Time Elapsed:\nLoading...", true)

    local serverType = "Missing"
    pcall(function()
        local rrs = cloneref(game:GetService("RobloxReplicatedStorage"))
        local remote = rrs:FindFirstChild("GetServerType")
        if remote and remote:IsA("RemoteFunction") then
            local ok2, res = pcall(remote.InvokeServer, remote)
            local raw = ok2 and tostring(res) or "Failed"
            serverType =
                raw == "StandardServer" and "Public"
                or raw == "VIPServer" and "Private"
                or raw == "ReservedServer" and "Private Match"
                or "Unknown or Unsupported"
        end
    end)
    GameBox:AddLabel("Server Variant: " .. serverType)

    local VersionBox = Tabs.Home:AddRightGroupbox("Version", "hash")
    VersionBox:AddLabel("Script Version: " .. tostring(LRM_ScriptVersion or "v2.0"))

    -- BUG FIX: this used a bare `while task.wait(1)` loop that survived
    -- unload and stacked one extra loop per re-execution.
    spawnTracked(function()
        task.wait(1)
        local t = Workspace.DistributedGameTime
        pcall(function()
            timeLabel:SetText(string.format("Time Elapsed:\n%d days\n%d hours\n%d minutes\n%d seconds",
                math.floor(t / 86400), math.floor((t % 86400) / 3600),
                math.floor((t % 3600) / 60), math.floor(t % 60)))
            statLabel:SetText(string.format("Stats:\nSpeed: %s\nMoney/s: %s",
                tostring(getSpeedStat()), tostring(getMoneyStat())))
        end)
    end)

    local Support = Tabs.Home:AddRightGroupbox("Games Supported", "gamepad-2")
    Support:AddLabel(
        '<font color="rgb(0, 255, 0)">*</font> Working and Updated\n' ..
        '<font color="rgb(255, 255, 0)">*</font> Unstable and Experimental\n' ..
        '<font color="rgb(255, 0, 0)">*</font> Not Working or Outdated', true)
    pcall(function()
        local chunk = loadstring(game:HttpGet("https://luminon.top/game.txt"))
        if not chunk then return end
        local a, b = chunk()
        local text = b or a
        if text then Support:AddLabel(tostring(text), true) end
    end)
end

--=====================================================================
-- FARM
--=====================================================================

local FilterGB = Tabs.Farm:AddLeftGroupbox("Filters", "filter")

FilterGB:AddDropdown("FarmMinRarity", {
    Text    = "Minimum Rarity",
    Tooltip = "Ignores anything below this tier. Leave blank to allow all.",
    Values  = RarityOrder,
    Default = nil,
    AllowNull = true,
    Callback = function(v) Flags.FarmMinRarity = v end,
})

FilterGB:AddDropdown("StealRarities", {
    Text     = "Exact Rarities",
    Tooltip  = "Optional. When set, ONLY these exact tiers are farmed.",
    Values   = RarityOrder,
    Multi     = true,
    AllowNull = true,
    Callback = function(v) Flags.StealRarities = v end,
})

FilterGB:AddDropdown("StealZones", {
    Text     = "Zones",
    Tooltip  = "Leave empty to farm every zone.",
    Values   = ZoneList,
    Multi     = true,
    AllowNull = true,
    Callback = function(v) Flags.StealZones = v end,
})

FilterGB:AddDropdown("SelectEggs", {
    Text       = "Specific Eggs",
    Tooltip    = "Optional whitelist of individual eggs.",
    Searchable = true,
    Values     = EggNameList,
    Multi     = true,
    AllowNull = true,
    Callback = function(v) Flags.SelectEggs = v end,
})

FilterGB:AddDropdown("SelectMutations", {
    Text     = "Mutations",
    Tooltip  = "Optional. Only take eggs carrying one of these mutations.",
    Values   = { "Silver", "Gold", "Diamond", "Rainbow", "Frost", "Magma", "Shiny" },
    Multi     = true,
    AllowNull = true,
    Callback = function(v) Flags.SelectMutations = v end,
})

FilterGB:AddSlider("MinEggWeight", {
    Text     = "Min Egg Weight",
    Tooltip  = "ModelWeight x AssetScale from the game's asset directory.",
    Min      = 0,
    Max      = 20000,
    Default  = 0,
    Rounding = 0,
    Callback = function(v) Flags.MinEggWeight = v end,
})

FilterGB:AddButton("Select All Zones", function()
    Options.StealZones:SetValue(ZoneList)
    Flags.StealZones = ZoneList
    showToast("Lumin Hub", "All zones selected")
end):AddButton("Clear Zones", function()
    Options.StealZones:SetValue(nil)
    Flags.StealZones = {}
    showToast("Lumin Hub", "Zone filter cleared")
end)

local MoveGB = Tabs.Farm:AddRightGroupbox("Movement", "move")

MoveGB:AddToggle("SmartTween", {
    Text    = "Smart Tween",
    Tooltip = "Moves at a bounded stud/s rate instead of snapping the CFrame every frame.",
    Default = true,
    Callback = function(v) Flags.SmartTween = v end,
})

MoveGB:AddSlider("TweenSpeed", {
    Text     = "Tween Speed",
    Suffix   = " studs/s",
    Min      = 50,
    Max      = 1000,
    Default  = 300,
    Rounding = 0,
    Callback = function(v) Flags.TweenSpeed = v end,
})

MoveGB:AddToggle("InstantMove", {
    Text    = "Instant Move",
    Tooltip = "Overrides Smart Tween and snaps directly to the target.",
    Default = false,
    Callback = function(v) Flags.InstantMove = v end,
})

MoveGB:AddToggle("DistantTarget", {
    Text    = "Distant Egg Target",
    Tooltip = "With Priority off, targets the furthest matching egg instead of the nearest.",
    Default = false,
    Callback = function(v) Flags.DistantTarget = v end,
})

local DelayGB = Tabs.Farm:AddRightGroupbox("Delay Manager", "timer")

DelayGB:AddSlider("FarmDelay", {
    Text = "Farm Delay", Suffix = "s",
    Min = 0, Max = 5, Default = 0, Rounding = 2,
    Callback = function(v) Flags.FarmDelay = v end,
})

DelayGB:AddSlider("SellDelay", {
    Text = "Sell Delay", Suffix = "s",
    Min = 0, Max = 5, Default = 0, Rounding = 2,
    Callback = function(v) Flags.SellDelay = v end,
})

local StealGB = Tabs.Farm:AddLeftGroupbox("Auto Farm", "flag")

StealGB:AddToggle("PrioritySystem", {
    Text    = "Prioritize Rarity",
    Tooltip = "Highest rarity first, then heaviest.",
    Default = true,
    Callback = function(v) Flags.PrioritySystem = v end,
})

StealGB:AddToggle("AutoPlaceAfterSteal", {
    Text    = "Auto Place After Steal",
    Default = true,
    Callback = function(v) Flags.AutoPlaceAfterSteal = v end,
})

StealGB:AddToggle("InstantPlace", {
    Text    = "Instant Place",
    Tooltip = "Places the whole inventory each trip instead of one egg.",
    Default = false,
    Callback = function(v) Flags.InstantPlace = v end,
})

StealGB:AddToggle("SnipeDropped", {
    Text    = "Snipe Dropped Eggs",
    Tooltip = "Also targets eggs that are not sitting in a nest slot.",
    Default = false,
    Callback = function(v) Flags.SnipeDropped = v end,
})

StealGB:AddToggle("ForestGuardBypass", {
    Text    = "Forest Guard Bypass",
    Tooltip = "Does not pause farming for the Forest guard.",
    Default = false,
    Callback = function(v) Flags.ForestGuardBypass = v end,
})

StealGB:AddToggle("AutoSteal", {
    Text    = "Auto Farm Egg",
    Default = false,
    Callback = function(val)
        Flags.AutoSteal = val
        if not val then
            stopLoop("AutoSteal")
            Move:Stop()
            Status.Steal = "Idle"
            return
        end
        startLoop("AutoSteal", function()
            local zones = Flags.StealZones or {}

            -- Register with the corridor once per life before farming.
            if not GameplayEntered then
                enterGameplayArea()
                task.wait(0.3)
            end

            local awake, zone = isGuardAwake(zones)
            if awake then
                Status.Steal = "Guard awake in " .. tostring(zone) .. " - waiting"
                task.wait(0.5)
                return
            end
            if GlobalCarryCooldown > os.clock() then
                Status.Steal = "Cooldown"
                task.wait(0.5)
                return
            end
            if InventoryFull then
                if countTable(getMyEggs()) < InventoryFullCount then
                    InventoryFull = false
                else
                    Status.Steal = "Inventory full - waiting"
                    task.wait(2)
                    return
                end
            end

            -- Spawn sniper queue takes precedence over the normal scan.
            -- The area snapshot's Records is a plain array, so a sniped uid
            -- has to be found by scanning rather than indexed directly.
            local snapshot = getAreaEggs()
            local target = table.remove(SnipeQueue, 1)
            if target then
                local live
                for _, rec in pairs(snapshot) do
                    if rec.Uid == target.Uid then live = rec break end
                end
                target = (live and eggPassesFilters(live)) and live or nil
            end
            target = target or pickTargetEgg(snapshot)

            if not target then
                Status.Steal = "No matching eggs"
                task.wait(0.5)
                return
            end

            stealOnce(target)
            task.wait(math.max(tonumber(Flags.FarmDelay) or 0, 0.1))
        end)
    end,
})

StealGB:AddButton("Force Resume", function()
    InventoryFull, InventoryFullCount = false, 0
    PlaceCooldown, GlobalCarryCooldown = 0, 0
    table.clear(CarryFails)
    table.clear(CarryCooldowns)
    showToast("Lumin Hub", "Farm state reset")
end)

local StealStatus = StealGB:AddLabel("Last Steal: Idle", true)

local SniperGB = Tabs.Farm:AddLeftGroupbox("Spawn Sniper", "crosshair")

SniperGB:AddDropdown("SnipeMinRarity", {
    Text      = "Sniper Min Rarity",
    Values    = RarityOrder,
    Default   = nil,
    AllowNull = true,
    Callback  = function(v) Flags.SnipeMinRarity = v end,
})

SniperGB:AddToggle("SpawnSniper", {
    Text    = "Spawn Sniper",
    Tooltip = "Listens for newly spawned eggs and jumps the farm queue.",
    Default = false,
    Callback = function(val)
        Flags.SpawnSniper = val
        if not val then table.clear(SnipeQueue) end
    end,
})

local ActionsGB = Tabs.Farm:AddRightGroupbox("Actions", "zap")

ActionsGB:AddButton("Teleport to Base", function()
    local c = getPlotCenter()
    if c then Move:To(c) end
    showToast("Lumin Hub", "Teleported to base")
end):AddButton("Drop Held Egg", function()
    godMarkIntentionalDrop()
    invokeRemote("Eggs: RequestAreaEggDrop", {})
    showToast("Lumin Hub", "Dropped held egg")
end)

ActionsGB:AddButton("Place All Eggs", function()
    local n = placeHeldEggs(nil)
    showToast("Lumin Hub", "Placed " .. n .. " eggs")
end):AddButton("Teleport to Lobby", function()
    fireRemote("Plots: RequestLobbyTeleport")
    showToast("Lumin Hub", "Teleporting to lobby")
end)

ActionsGB:AddToggle("AutoRecover", {
    Text    = "Auto Recover Egg",
    Tooltip = "Returns to base and re-places anything left in your inventory.",
    Default = false,
    Callback = function(val)
        Flags.AutoRecover = val
        if val then
            startLoop("AutoRecover", function()
                if countTable(getMyEggs()) > 0 and not Flags.AutoSteal then
                    local c = getPlotCenter()
                    if c then Move:To(c) end
                    placeHeldEggs(nil)
                end
                task.wait(5)
            end)
        else
            stopLoop("AutoRecover")
        end
    end,
})

ActionsGB:AddToggle("AutoReturnBase", {
    Text    = "Auto Return to Base",
    Default = false,
    Callback = function(val)
        Flags.AutoReturnBase = val
        if val then
            startLoop("AutoReturnBase", function()
                if not Flags.AutoSteal and not isAtBase() then
                    local c = getPlotCenter()
                    if c then Move:To(c) end
                end
                task.wait(3)
            end)
        else
            stopLoop("AutoReturnBase")
        end
    end,
})

--=====================================================================
-- AUTOMATION
--=====================================================================

local EggsGB = Tabs.Automation:AddLeftGroupbox("Eggs", "egg")

EggsGB:AddToggle("AutoHatch", {
    Text    = "Auto Hatch Eggs",
    Default = false,
    Callback = function(val)
        Flags.AutoHatch = val
        if val then
            startLoop("AutoHatch", function()
                for uid in pairs(getMyEggs()) do
                    if not Running["AutoHatch"] then return end
                    if not remoteSucceeded("Eggs: RequestHatchEgg", uid) then
                        invokeRemote("Eggs: RequestSkipGrowth", uid)
                        task.wait(0.15)
                        invokeRemote("Eggs: RequestHatchEgg", uid)
                    end
                    task.wait(0.2)
                    invokeRemote("Eggs: RequestCompleteHatchEgg", uid)
                    task.wait(0.25)
                end
                task.wait(1.5)
            end)
        else
            stopLoop("AutoHatch")
        end
    end,
})

EggsGB:AddToggle("AutoPlace", {
    Text    = "Auto Place Eggs",
    Tooltip = "Travels to base and fills slots from inventory.",
    Default = false,
    Callback = function(val)
        Flags.AutoPlace = val
        if val then
            startLoop("AutoPlace", function()
                if countTable(getMyEggs()) == 0 then task.wait(3) return end
                if not isAtBase() and not Flags.AutoSteal then
                    local c = getPlotCenter()
                    if c then Move:To(c) end
                end
                placeHeldEggs(nil)
                task.wait(2)
            end)
        else
            stopLoop("AutoPlace")
        end
    end,
})

EggsGB:AddToggle("AutoEquipBest", {
    Text    = "Auto Equip Best",
    Default = false,
    Callback = function(val)
        Flags.AutoEquipBest = val
        if val then
            startLoop("AutoEquipBest", function()
                invokeRemote("Backpack: EquipBest")
                task.wait(4)
            end)
        else
            stopLoop("AutoEquipBest")
        end
    end,
})

EggsGB:AddToggle("AutoFavorite", {
    Text    = "Auto Favorite Rares",
    Tooltip = "Favorites anything at or above the minimum rarity so it is never sold.",
    Default = false,
    Callback = function(val)
        Flags.AutoFavorite = val
        if val then
            startLoop("AutoFavorite", function()
                local minR = Flags.FavoriteMinRarity
                if minR and minR ~= "" then
                    for uid, pet in pairs(getPets()) do
                        local cat = (pet.ItemData or {}).Category
                        if cat and rarityNum(assetRarity(cat)) >= rarityNum(minR) then
                            fireRemote("AssetInventory: SetFavorite", uid, true)
                            task.wait(0.08)
                        end
                    end
                end
                task.wait(8)
            end)
        else
            stopLoop("AutoFavorite")
        end
    end,
})

EggsGB:AddDropdown("FavoriteMinRarity", {
    Text      = "Favorite Min Rarity",
    Values    = RarityOrder,
    Default   = nil,
    AllowNull = true,
    Callback  = function(v) Flags.FavoriteMinRarity = v end,
})

local ProgGB = Tabs.Automation:AddRightGroupbox("Progression", "trending-up")

-- BUG FIX: the old Auto Rebirth read speed from the "Get Stats" remote,
-- which returns an empty table in this build, so its `speedPower > 0`
-- guard was never satisfied and the feature never fired. Speed lives on
-- leaderstats; the Rebirth GUI's ProgressText carries the live threshold.
local function getRebirthProgress()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    local gui = pg and pg:FindFirstChild("Rebirth")
    if gui then
        for _, d in ipairs(gui:GetDescendants()) do
            if d:IsA("TextLabel") and d.Name == "ProgressText" then
                local have, need = d.Text:match("([%d%.]+)%s*/%s*([%d%.]+)")
                if have and need then return tonumber(have), tonumber(need) end
            end
        end
    end
    -- fall back to the rebirth requirement table
    local speed = getSpeedStat()
    if RebirthConfig then
        for i = 1, 30 do
            local tier = RebirthConfig[i]
            if not tier then break end
            local req = tier.Requirements and tier.Requirements.RequiredSpeedPower
            if req and speed < req then return speed, req end
        end
    end
    return speed, nil
end

ProgGB:AddToggle("AutoRebirth", {
    Text    = "Auto Rebirth",
    Tooltip = "Rebirths as soon as the speed requirement is met.",
    Default = false,
    Callback = function(val)
        Flags.AutoRebirth = val
        if val then
            startLoop("AutoRebirth", function()
                local have, need = getRebirthProgress()
                if need and have and have >= need then
                    local pg = LocalPlayer:FindFirstChild("PlayerGui")
                    local gui = pg and pg:FindFirstChild("Rebirth")
                    if gui then
                        for _, d in ipairs(gui:GetDescendants()) do
                            if d:IsA("ImageButton") and d.Name == "Rebirth" then
                                clickGuiButton(d)
                                break
                            end
                        end
                    end
                end
                task.wait(3)
            end)
        else
            stopLoop("AutoRebirth")
        end
    end,
})

ProgGB:AddToggle("AutoBase", {
    Text = "Auto Upgrade Base", Default = false,
    Callback = function(val)
        Flags.AutoBase = val
        if val then
            startLoop("AutoBase", function()
                fireRemote("Plots: RequestBaseUpgrade")
                task.wait(2)
            end)
        else stopLoop("AutoBase") end
    end,
})

ProgGB:AddToggle("AutoTreadmillUpgrade", {
    Text = "Auto Upgrade Treadmill", Default = false,
    Callback = function(val)
        Flags.AutoTreadmillUpgrade = val
        if val then
            startLoop("AutoTreadmillUpgrade", function()
                invokeRemote("Treadmills: RequestUpgrade")
                task.wait(2)
            end)
        else stopLoop("AutoTreadmillUpgrade") end
    end,
})

ProgGB:AddToggle("AFKTreadmill", {
    Text    = "AFK Treadmill",
    Tooltip = "Holds you on the treadmill to bank speed.",
    Default = false,
    Callback = function(val)
        Flags.AFKTreadmill = val
        if val then
            startLoop("AFKTreadmill", function()
                local plot = getMyPlot()
                local pad  = plot and plot:FindFirstChild("TreadmillBottom")
                local root = getRoot()
                if pad and root then
                    if (root.Position - pad.Position).Magnitude > 6 then
                        root.CFrame = pad.CFrame * CFrame.new(0, 3, 0)
                    end
                end
                task.wait(1)
            end)
        else stopLoop("AFKTreadmill") end
    end,
})

-- BUG FIX: the old Auto Buy Trails hardcoded "GoldenTrail"/"SecretTrail".
-- The real directory holds 10 trails; buy/equip the best one available.
ProgGB:AddDropdown("TrailChoice", {
    Text      = "Trail",
    Values    = TrailList,
    Default   = TrailList[1],
    AllowNull = true,
    Callback  = function(v) Flags.TrailChoice = v end,
})

ProgGB:AddToggle("AutoTrails", {
    Text = "Auto Buy / Equip Trail", Default = false,
    Callback = function(val)
        Flags.AutoTrails = val
        if val then
            startLoop("AutoTrails", function()
                local choice = Flags.TrailChoice
                if choice and choice ~= "" then
                    invokeRemote("Trails: RequestPurchase", choice)
                    task.wait(0.4)
                    invokeRemote("Trails: RequestSelect", choice)
                end
                task.wait(5)
            end)
        else stopLoop("AutoTrails") end
    end,
})

local ClaimGB = Tabs.Automation:AddLeftGroupbox("Auto Claim", "gift")

local claimJobs = {
    { key = "AutoClaimIndex",   text = "Auto Claim Index",       remote = "Index: RequestClaimAll",   wait = 6 },
    { key = "AutoClaimGroup",   text = "Auto Claim Group Reward", remote = "GroupReward: ClaimReward", wait = 8 },
    { key = "AutoClaimOffline", text = "Claim Offline Earnings",  remote = "OfflineAssets: Redeem",    wait = 12 },
}

for _, job in ipairs(claimJobs) do
    ClaimGB:AddToggle(job.key, {
        Text = job.text, Default = false,
        Callback = function(val)
            Flags[job.key] = val
            if val then
                startLoop(job.key, function()
                    invokeRemote(job.remote)
                    task.wait(job.wait)
                end)
            else stopLoop(job.key) end
        end,
    })
end

local CodesGB = Tabs.Automation:AddRightGroupbox("Codes", "ticket")

-- Verified path: PlayerGui.Codes.Frame.Input.Input (TextBox) and
-- PlayerGui.Codes.Frame.Bottom.Claim (button). There is no codes remote.
local function redeemCode(code)
    local pg  = LocalPlayer:FindFirstChild("PlayerGui")
    local gui = pg and pg:FindFirstChild("Codes")
    if not gui then return false end
    local frame = gui:FindFirstChild("Frame")
    if not frame then return false end
    local input = frame:FindFirstChild("Input")
    local box   = input and input:FindFirstChild("Input")
    local bottom = frame:FindFirstChild("Bottom")
    local claim = bottom and bottom:FindFirstChild("Claim")
    if not (box and box:IsA("TextBox") and claim) then return false end

    local wasEnabled = gui.Enabled
    gui.Enabled = true
    box.Text = code
    task.wait(0.15)
    local ok = clickGuiButton(claim)
    task.wait(0.35)
    gui.Enabled = wasEnabled
    return ok
end

local codeInput = CodesGB:AddInput("ManualCodes", {
    Text        = "Codes (comma separated)",
    Placeholder = "code1, code2",
})

CodesGB:AddButton("Redeem Codes", function()
    local raw = codeInput.Value or ""
    local n = 0
    for code in raw:gmatch("[^,%s]+") do
        if redeemCode(code) then n = n + 1 end
        task.wait(0.5)
    end
    showToast("Lumin Hub", "Submitted " .. n .. " codes")
end)

--=====================================================================
-- SELL
--=====================================================================

local SellGB = Tabs.Sell:AddLeftGroupbox("Auto Sell", "coins")

SellGB:AddDropdown("KeepMinRarity", {
    Text    = "Keep Min Rarity",
    Tooltip = "Anything BELOW this tier gets sold.",
    Values  = RarityOrder,
    Default = RarityOrder[3] or RarityOrder[1],
    Callback = function(v) Flags.KeepMinRarity = v end,
})

SellGB:AddDropdown("SellRarities", {
    Text     = "Exact Sell Rarities",
    Tooltip  = "Optional. When set, overrides Keep Min Rarity and sells only these tiers.",
    Values   = RarityOrder,
    Multi     = true,
    AllowNull = true,
    Callback = function(v) Flags.SellRarities = v end,
})

SellGB:AddToggle("NeverSellMutated",  { Text = "Never Sell Mutated",  Default = true,
    Callback = function(v) Flags.NeverSellMutated = v end })
SellGB:AddToggle("NeverSellEquipped", { Text = "Never Sell Equipped", Default = true,
    Callback = function(v) Flags.NeverSellEquipped = v end })
SellGB:AddToggle("AutoSellConfirm",   { Text = "Auto Confirm Sell",   Default = true,
    Callback = function(v) Flags.AutoSellConfirm = v end })

SellGB:AddToggle("AutoSell", {
    Text = "Auto Sell Pets", Default = false,
    Callback = function(val)
        Flags.AutoSell = val
        if val then
            startLoop("AutoSell", function()
                local exact = listToSet(Flags.SellRarities)
                local sold = sellPetsByFilter(Flags.KeepMinRarity, exact)
                if sold == 0 then Status.Sell = "Nothing to sell" end
                task.wait(math.max(tonumber(Flags.SellDelay) or 0, 2))
            end)
        else
            stopLoop("AutoSell")
            Status.Sell = "Idle"
        end
    end,
})

SellGB:AddButton("Sell Now", function()
    local sold = sellPetsByFilter(Flags.KeepMinRarity, listToSet(Flags.SellRarities))
    showToast("Lumin Hub", "Sold " .. sold .. " pets")
end):AddButton("Sell Lowest", function()
    local best = getBestPets()
    local worst = best[#best]
    if not worst then showToast("Lumin Hub", "No pets") return end
    if remoteSucceeded("ActiveAssets: RequestSell", worst.uid) then
        Status.Sell = "Sold lowest earner"
        showToast("Lumin Hub", "Sold lowest earner")
    end
end)

local SellStatus = SellGB:AddLabel("Last Sell: Idle", true)

local FuseGB = Tabs.Sell:AddRightGroupbox("Auto Fuse", "git-merge")

FuseGB:AddSlider("FuseCount", {
    Text = "Fuse Pairs Per Cycle",
    Min = 1, Max = 10, Default = 3, Rounding = 0,
    Callback = function(v) Flags.FuseCount = v end,
})

FuseGB:AddToggle("AutoFuse", {
    Text = "Auto Fuse Pets", Default = false,
    Callback = function(val)
        Flags.AutoFuse = val
        if val then
            startLoop("AutoFuse", function()
                local n = autoFusePets(Flags.FuseCount or 3)
                Status.Fuse = n > 0 and ("Fused " .. n .. " pairs") or "No pets to fuse"
                task.wait(10)
            end)
        else
            stopLoop("AutoFuse")
            Status.Fuse = "Idle"
        end
    end,
})

FuseGB:AddButton("Fuse Once", function()
    local n = autoFusePets(Flags.FuseCount or 3)
    Status.Fuse = "Fused " .. n .. " pairs"
    showToast("Lumin Hub", "Fused " .. n .. " pairs")
end)

local FuseStatus = FuseGB:AddLabel("Last Fuse: Idle", true)

local DeleteGB = Tabs.Sell:AddLeftGroupbox("Cleanup", "trash-2")

DeleteGB:AddToggle("AutoDeleteOwnPets", {
    Text    = "Auto Delete Own Pets (FPS)",
    Tooltip = "Sells every non-mutated, non-equipped pet to cut render load.",
    Default = false,
    Callback = function(val)
        Flags.AutoDeleteOwnPets = val
        if val then
            startLoop("AutoDeleteOwnPets", function()
                local n = deleteOwnPets()
                if n > 0 then Status.Sell = "Deleted " .. n .. " pets" end
                task.wait(8)
            end)
        else stopLoop("AutoDeleteOwnPets") end
    end,
})

DeleteGB:AddButton("Delete All Own Pets", function()
    local n = deleteOwnPets()
    showToast("Lumin Hub", "Deleted " .. n .. " pets")
end)

--=====================================================================
-- VISUAL
--=====================================================================

local ESPGB = Tabs.Visual:AddLeftGroupbox("ESP", "eye")

ESPGB:AddDropdown("EspMinRarity", {
    Text      = "ESP Min Rarity",
    Values    = RarityOrder,
    Default   = nil,
    AllowNull = true,
    Callback  = function(v) Flags.EspMinRarity = v end,
})

ESPGB:AddSlider("EspDistance", {
    Text     = "ESP Distance",
    Suffix   = " studs",
    Min      = 100,
    Max      = 5000,
    Default  = 2500,
    Rounding = 0,
    Callback = function(v) Flags.EspDistance = v end,
})

ESPGB:AddToggle("EspHighlight", {
    Text = "Highlights", Default = true,
    Callback = function(v) Flags.EspHighlight = v end,
})

ESPGB:AddToggle("EspTracers", {
    Text = "Tracers", Default = false,
    Tooltip = "Draws a line from the bottom of the screen to each egg.",
    Callback = function(v) Flags.EspTracers = v end,
})

ESPGB:AddToggle("EggESP", {
    Text = "Egg ESP", Default = false,
    Callback = function(val)
        Flags.EggESP = val
        if val then
            startLoop("EggESP", function()
                local slots = Workspace:FindFirstChild("AreaEggSlotsClient")
                local alive = {}
                local minR  = Flags.EspMinRarity
                local maxD  = tonumber(Flags.EspDistance) or 2500

                for _, egg in pairs(getAreaEggs()) do
                    local uid, cat = egg.Uid, egg.AssetCategory
                    if uid and cat then
                        local info   = AssetInfo[cat]
                        local rarity = info and info.rarity or "Unknown"
                        if (not minR) or minR == "" or rarityNum(rarity) >= rarityNum(minR) then
                            local slot = slots and slots:FindFirstChild(uid)
                            if slot then
                                local key = "egg_" .. uid
                                alive[key] = true
                                local muts = getEggMutations(egg)
                                local name = (info and info.display) and cat or cat
                                local text = string.format("%s [%s]  %.0fkg%s",
                                    name, rarity, getEggWeight(egg),
                                    #muts > 0 and (" " .. table.concat(muts, "/")) or "")
                                espUpsert(key, slot, {
                                    colour      = RarityColour[rarity] or Color3.new(1, 1, 1),
                                    text        = text,
                                    highlight   = Flags.EspHighlight ~= false,
                                    tracer      = Flags.EspTracers == true,
                                    maxDistance = maxD,
                                })
                            end
                        end
                    end
                end
                for key in pairs(EspEntries) do
                    if key:sub(1, 4) == "egg_" and not alive[key] then espDestroy(key) end
                end
                task.wait(0.4)
            end)
        else
            stopLoop("EggESP")
            espClear("egg_")
        end
    end,
})

-- Guards live under __OBJECTS.Areas.GuardAreas.<Area>.Guard;
-- workspace._Guards exists but is always empty in this build.
ESPGB:AddToggle("GuardESP", {
    Text = "Guard ESP", Default = false,
    Callback = function(val)
        Flags.GuardESP = val
        if val then
            startLoop("GuardESP", function()
                local maxD = tonumber(Flags.EspDistance) or 2500
                local alive = {}
                for _, g in ipairs(getGuardReport()) do
                    local key = "guard_" .. g.areaId
                    alive[key] = true
                    espUpsert(key, g.model, {
                        colour      = g.awake and Color3.fromRGB(255, 70, 70)
                                              or Color3.fromRGB(130, 130, 140),
                        text        = string.format("%s Guard - %s", g.areaId, tostring(g.state)),
                        highlight   = Flags.EspHighlight ~= false,
                        tracer      = Flags.EspTracers == true,
                        maxDistance = maxD,
                    })
                end
                for key in pairs(EspEntries) do
                    if key:sub(1, 6) == "guard_" and not alive[key] then espDestroy(key) end
                end
                task.wait(0.4)
            end)
        else
            stopLoop("GuardESP")
            espClear("guard_")
        end
    end,
})

ESPGB:AddToggle("PlayerESP", {
    Text = "Player ESP", Default = false,
    Callback = function(val)
        Flags.PlayerESP = val
        if val then
            startLoop("PlayerESP", function()
                local maxD = tonumber(Flags.EspDistance) or 2500
                local alive = {}
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer and plr.Character then
                        local key = "player_" .. plr.UserId
                        alive[key] = true
                        local ls    = plr:FindFirstChild("leaderstats")
                        local money = ls and ls:FindFirstChild("Money/s")
                        local hum   = plr.Character:FindFirstChildOfClass("Humanoid")
                        espUpsert(key, plr.Character, {
                            colour = (hum and hum.Health <= 0)
                                and Color3.fromRGB(120, 120, 120)
                                or Color3.fromRGB(90, 200, 255),
                            text = string.format("%s%s", plr.DisplayName,
                                money and ("  " .. tostring(money.Value)) or ""),
                            highlight   = Flags.EspHighlight ~= false,
                            tracer      = Flags.EspTracers == true,
                            maxDistance = maxD,
                        })
                    end
                end
                for key in pairs(EspEntries) do
                    if key:sub(1, 7) == "player_" and not alive[key] then espDestroy(key) end
                end
                task.wait(0.4)
            end)
        else
            stopLoop("PlayerESP")
            espClear("player_")
        end
    end,
})

ESPGB:AddToggle("PlotESP", {
    Text = "Plot ESP", Default = false,
    Callback = function(val)
        Flags.PlotESP = val
        if val then
            startLoop("PlotESP", function()
                local plots = Workspace:FindFirstChild("Plots")
                if not plots then task.wait(5) return end
                local ok, state = invokeRemote("Plots: RequestState")
                local owners = (ok and type(state) == "table") and state.OwnersBySlot or {}
                local alive = {}
                for _, plot in ipairs(plots:GetChildren()) do
                    local sign = plot:FindFirstChild("PlotSign") or plot:FindFirstChild("CenterPoint")
                    if sign then
                        local key = "plot_" .. plot.Name
                        alive[key] = true
                        local ownerId = owners[tonumber(plot.Name)] or owners[plot.Name]
                        local who = "empty"
                        local colour = Color3.fromRGB(150, 150, 150)
                        if ownerId then
                            local p = Players:GetPlayerByUserId(ownerId)
                            who = p and p.DisplayName or tostring(ownerId)
                            colour = (ownerId == LocalPlayer.UserId)
                                and Color3.fromRGB(90, 255, 140) or Color3.fromRGB(255, 210, 0)
                        end
                        espUpsert(key, sign, {
                            colour      = colour,
                            text        = "Plot " .. plot.Name .. " - " .. who,
                            highlight   = false,
                            tracer      = false,
                            maxDistance = tonumber(Flags.EspDistance) or 2500,
                        })
                    end
                end
                for key in pairs(EspEntries) do
                    if key:sub(1, 5) == "plot_" and not alive[key] then espDestroy(key) end
                end
                task.wait(3)
            end)
        else
            stopLoop("PlotESP")
            espClear("plot_")
        end
    end,
})

ESPGB:AddButton({
    Text = "Clear All ESP",
    Tooltip = "Removes every ESP object without touching the toggles.",
    Func = function()
        espClear(nil)
        showToast("Lumin Hub", "ESP cleared")
    end,
})

local IntelGB = Tabs.Visual:AddRightGroupbox("Server Intel", "radar")

local guardLabel  = IntelGB:AddLabel("Guards: loading...", true)
local intelLabel  = IntelGB:AddLabel("Players: loading...", true)
local resetLabel  = IntelGB:AddLabel("Egg reset: --", true)

IntelGB:AddToggle("GuardRadar", {
    Text    = "Guard Threat Radar",
    Tooltip = "Live guard state and distance readout.",
    Default = false,
    Callback = function(v) Flags.GuardRadar = v end,
})

IntelGB:AddButton("Copy Server Intel", function()
    local lines = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        local ls = plr:FindFirstChild("leaderstats")
        local money = ls and ls:FindFirstChild("Money/s")
        table.insert(lines, string.format("%s  %s", plr.Name, money and tostring(money.Value) or "?"))
    end
    if setclipboard then setclipboard(table.concat(lines, "\n")) end
    showToast("Lumin Hub", "Copied " .. #lines .. " players")
end)

local WebhookGB = Tabs.Visual:AddRightGroupbox("Webhook", "webhook")

local webhookUrl = WebhookGB:AddInput("WebhookUrl", {
    Text = "Discord Webhook URL", Placeholder = "https://discord.com/api/webhooks/...",
})
local webhookMention = WebhookGB:AddInput("WebhookMention", {
    Text = "Mention", Placeholder = "<@everyone>",
})

WebhookGB:AddDropdown("WebhookMinRarity", {
    Text      = "Webhook Min Rarity",
    Values    = RarityOrder,
    Default   = RarityOrder[#RarityOrder - 2] or RarityOrder[#RarityOrder],
    AllowNull = true,
    Callback  = function(v) Flags.WebhookMinRarity = v end,
})

WebhookGB:AddToggle("WebhookEnabled", {
    Text = "Rare Egg Alerts", Default = false,
    Callback = function(v)
        Flags.WebhookEnabled = v
        Flags.WebhookUrl     = webhookUrl.Value
        Flags.WebhookMention = webhookMention.Value
    end,
})

local MoveGB2 = Tabs.Visual:AddLeftGroupbox("Movement", "person-standing")

MoveGB2:AddSlider("WalkSpeed", {
    Text = "Walk Speed", Min = 16, Max = 500, Default = 16, Rounding = 0,
    Callback = function(val)
        Flags.WalkSpeed = val
        if val > 16 then
            startLoop("WalkSpeed", function()
                local hum = getHumanoid()
                if hum then hum.WalkSpeed = Flags.WalkSpeed end
                task.wait(0.2)
            end)
        else
            stopLoop("WalkSpeed")
            local hum = getHumanoid()
            if hum then hum.WalkSpeed = 16 end
        end
    end,
})

MoveGB2:AddSlider("JumpPower", {
    Text = "Jump Power", Min = 50, Max = 500, Default = 50, Rounding = 0,
    Callback = function(val)
        Flags.JumpPower = val
        if val > 50 then
            startLoop("JumpPower", function()
                local hum = getHumanoid()
                if hum then hum.JumpPower = Flags.JumpPower end
                task.wait(0.2)
            end)
        else
            stopLoop("JumpPower")
        end
    end,
})

-- BUG FIX: the old toggle created a brand new JumpRequest connection on
-- every enable and never disconnected it, so N toggles meant N handlers.
MoveGB2:AddToggle("InfiniteJump", {
    Text = "Infinite Jump", Default = false,
    Callback = function(v) Flags.InfiniteJump = v end,
})

MoveGB2:AddToggle("NoClip", {
    Text = "NoClip", Default = false,
    Callback = function(val)
        Flags.NoClip = val
        if not val then
            local char = getCharacter()
            if char then
                for _, p in ipairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = true end
                end
            end
        end
    end,
})

MoveGB2:AddSlider("FlySpeed", {
    Text = "Fly Speed", Min = 20, Max = 400, Default = 100, Rounding = 0,
    Callback = function(v) Flags.FlySpeed = v end,
})

-- The old Fly read WASD only, which is dead weight on a mobile executor.
-- This version follows the camera and uses the humanoid's MoveDirection,
-- so the on-screen thumbstick drives it too.
MoveGB2:AddToggle("Fly", {
    Text = "Fly", Default = false,
    Callback = function(val)
        Flags.Fly = val
        if val then
            local root = getRoot()
            local cam  = Workspace.CurrentCamera
            if not (root and cam) then
                showToast("Lumin Hub", "No character to fly")
                return
            end
            local bv = Instance.new("BodyVelocity")
            bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            bv.Velocity = Vector3.zero
            bv.Parent = root
            local bg = Instance.new("BodyGyro")
            bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
            bg.P = 10000
            bg.CFrame = root.CFrame
            bg.Parent = root
            Visuals["_fly_bv"], Visuals["_fly_bg"] = bv, bg

            startLoop("Fly", function()
                local hum = getHumanoid()
                if hum then hum.PlatformStand = true end
                local dir = Vector3.zero
                if hum and hum.MoveDirection.Magnitude > 0 then
                    dir = hum.MoveDirection
                end
                if UserInputService.KeyboardEnabled then
                    local c = Workspace.CurrentCamera
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + c.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - c.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - c.CFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + c.CFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.yAxis end
                    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.yAxis end
                end
                if Flags.FlyUp then dir = dir + Vector3.yAxis end
                if Flags.FlyDown then dir = dir - Vector3.yAxis end
                bv.Velocity = dir.Magnitude > 0
                    and dir.Unit * (tonumber(Flags.FlySpeed) or 100) or Vector3.zero
                bg.CFrame = Workspace.CurrentCamera.CFrame
                task.wait()
            end)
        else
            stopLoop("Fly")
            for _, k in ipairs({ "_fly_bv", "_fly_bg" }) do
                if Visuals[k] then pcall(function() Visuals[k]:Destroy() end) Visuals[k] = nil end
            end
            local hum = getHumanoid()
            if hum then hum.PlatformStand = false end
        end
    end,
})

MoveGB2:AddToggle("FlyUp",   { Text = "Fly Up (hold)",   Default = false,
    Callback = function(v) Flags.FlyUp = v end })
MoveGB2:AddToggle("FlyDown", { Text = "Fly Down (hold)", Default = false,
    Callback = function(v) Flags.FlyDown = v end })

--=====================================================================
-- UTILITY
--=====================================================================

local PlayerGB = Tabs.Utility:AddLeftGroupbox("Player", "user")

PlayerGB:AddToggle("GodMode", {
    Text    = "GodMode",
    Tooltip = "Anti-fling, anti-ragdoll, and instant egg re-grab when a guard hits you. Walk the whole way home.",
    Default = false,
    Callback = function(val)
        Flags.GodMode = val
        if val then
            godHardenHumanoid(getCharacter())
            godStripMovers(getCharacter())
            -- PreSimulation runs before the physics step, so the lock
            -- lands ahead of the knockback rather than chasing it.
            Flags._godStep = trackConn(RunService.Stepped:Connect(function()
                if not Flags.GodMode then return end
                godAntiFling()
            end))
            startLoop("GodMode", function()
                godCalmCharacter()
                RunService.Heartbeat:Wait()
            end)
            -- Purge knockback movers the guard adds to the character.
            local char = getCharacter()
            if char then
                Flags._godMoverConn = trackConn(char.DescendantAdded:Connect(function(d)
                    if not Flags.GodMode then return end
                    if d:IsA("BodyVelocity") or d:IsA("BodyAngularVelocity") or d:IsA("BodyThrust")
                        or d:IsA("BodyForce") or d:IsA("VectorForce")
                        or d:IsA("LinearVelocity") or d:IsA("AngularVelocity") then
                        if d ~= Visuals["_fly_bv"] and d ~= Visuals["_fly_bg"] then
                            task.defer(function() pcall(function() d:Destroy() end) end)
                            God.lastHit = os.clock()
                        end
                    end
                end))
            end
            showToast("Lumin Hub", "GodMode on - hits will not stop the carry")
        else
            stopLoop("GodMode")
        end
    end,
})

local GodStatus = PlayerGB:AddLabel("GodMode: idle", true)

PlayerGB:AddToggle("AntiAFK", {
    Text = "Anti AFK", Default = true,
    Callback = function(v) Flags.AntiAFK = v end,
})

-- The player carries a RagdollEndTime attribute; clearing PlatformStand
-- and restoring the humanoid state shortens the knockdown.
PlayerGB:AddToggle("AntiRagdoll", {
    Text = "Anti Ragdoll", Default = false,
    Callback = function(val)
        Flags.AntiRagdoll = val
        if val then
            startLoop("AntiRagdoll", function()
                local hum = getHumanoid()
                if hum then
                    if hum.PlatformStand and not Flags.Fly then hum.PlatformStand = false end
                    if hum:GetState() == Enum.HumanoidStateType.Ragdoll
                        or hum:GetState() == Enum.HumanoidStateType.FallingDown
                        or hum:GetState() == Enum.HumanoidStateType.Physics then
                        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                    end
                end
                task.wait(0.25)
            end)
        else stopLoop("AntiRagdoll") end
    end,
})

-- Client-side only: it keeps the local humanoid topped up so you are not
-- yanked back by local death handling. The server still owns real damage.
PlayerGB:AddToggle("AntiDie", {
    Text    = "Anti Die",
    Tooltip = "Keeps the local humanoid alive and runs home when a guard closes in.",
    Default = false,
    Callback = function(val)
        Flags.AntiDie = val
        _G.__SAE_AntiDeath = val
        if val then
            protectChar(getCharacter())
            killACConns()
            startLoop("AntiDie", function()
                killACConns()
                local hum = getHumanoid()
                if hum and hum.Health < hum.MaxHealth then
                    pcall(function() hum.Health = hum.MaxHealth end)
                end
                task.wait(0.5)
            end)
        else
            -- BUG FIX: the old code called stopLoop("AntiDie") for a loop
            -- that never existed, so Anti Die could not be switched off.
            stopLoop("AntiDie")
        end
    end,
})

PlayerGB:AddToggle("CarryProtect", {
    Text    = "Carry Protect",
    Tooltip = "Runs for base if an awake guard gets within 80 studs.",
    Default = false,
    Callback = function(val)
        Flags.CarryProtect = val
        if val then
            startLoop("CarryProtect", function()
                for _, g in ipairs(getGuardReport()) do
                    if g.awake and g.dist and g.dist < 80 and g.state ~= "ReturningHome" then
                        local c = getPlotCenter()
                        if c then
                            Move:Stop()
                            local root = getRoot()
                            if root then root.CFrame = CFrame.new(c) end
                        end
                        break
                    end
                end
                task.wait(0.3)
            end)
        else stopLoop("CarryProtect") end
    end,
})

PlayerGB:AddButton("Reset Character", function()
    invokeRemote("ClientCharacter: RequestCharacterReset")
    local hum = getHumanoid()
    if hum then hum.Health = 0 end
end)

local ServerGB = Tabs.Utility:AddRightGroupbox("Server", "server")

local jobIdInput = ServerGB:AddInput("JobId_Input", {
    Text = "Join JobId", Placeholder = "Enter JobId here",
})

ServerGB:AddButton("Join JobId", function()
    local jobId = jobIdInput.Value
    if jobId and #jobId > 0 then
        TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, LocalPlayer)
    else
        showToast("Lumin Hub", "Please enter a valid JobId")
    end
end):AddButton("Copy JobId", function()
    if setclipboard then
        setclipboard(game.JobId)
        showToast("Lumin Hub", "Copied JobId")
    end
end)

-- BUG FIX: the old Rejoin kicked the player first, which killed the
-- teleport that was supposed to follow it.
ServerGB:AddButton("Rejoin", function()
    showToast("Lumin Hub", "Rejoining...")
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end)

ServerGB:AddDropdown("HopMethod", {
    Text    = "Hop Method",
    Values  = { "Least Populated", "Most Populated", "Random" },
    Default = "Least Populated",
    Callback = function(v) Flags.HopMethod = v end,
})

-- BUG FIX: the old hop had no pagination, did not exclude full servers,
-- and could pick the server you are already in.
local function serverHop()
    if not httprequest then
        showToast("Lumin Hub", "Executor has no HTTP request function")
        return
    end
    local best, cursor = nil, ""
    for _ = 1, 3 do
        local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100&excludeFullGames=true")
            :format(game.PlaceId)
        if cursor ~= "" then url = url .. "&cursor=" .. cursor end
        local ok, res = pcall(httprequest, { Url = url, Method = "GET" })
        if not (ok and res and res.Body) then break end
        local okJson, data = pcall(function() return HttpService:JSONDecode(res.Body) end)
        if not (okJson and type(data) == "table" and data.data) then break end

        for _, srv in ipairs(data.data) do
            if srv.id ~= game.JobId and srv.playing and srv.maxPlayers
                and srv.playing < srv.maxPlayers then
                if Flags.HopMethod == "Random" then
                    if not best or math.random() < 0.3 then best = srv end
                elseif Flags.HopMethod == "Most Populated" then
                    if not best or srv.playing > best.playing then best = srv end
                else
                    if not best or srv.playing < best.playing then best = srv end
                end
            end
        end
        cursor = data.nextPageCursor or ""
        if cursor == "" then break end
    end

    if best then
        showToast("Lumin Hub", "Hopping to a server with " .. tostring(best.playing) .. " players")
        TeleportService:TeleportToPlaceInstance(game.PlaceId, best.id, LocalPlayer)
    else
        showToast("Lumin Hub", "No server found - retrying via normal teleport")
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end
end

ServerGB:AddButton("Server Hop", serverHop)

ServerGB:AddToggle("AutoHopEmpty", {
    Text    = "Auto Hop When No Eggs",
    Tooltip = "Hops if nothing matches your filters for 60 seconds.",
    Default = false,
    Callback = function(val)
        Flags.AutoHopEmpty = val
        if val then
            local emptySince = nil
            startLoop("AutoHopEmpty", function()
                if pickTargetEgg(getAreaEggs()) then
                    emptySince = nil
                else
                    emptySince = emptySince or os.clock()
                    if os.clock() - emptySince > 60 then serverHop() end
                end
                task.wait(5)
            end)
        else stopLoop("AutoHopEmpty") end
    end,
})

local PerfGB = Tabs.Utility:AddLeftGroupbox("Performance", "refresh-ccw")

PerfGB:AddToggle("FPSBoost", {
    Text = "FPS Boost", Default = false,
    Callback = function(state)
        Flags.FPSBoost = state
        if state then
            local terrain = Workspace:FindFirstChildOfClass("Terrain")
            if terrain then
                terrain.WaterWaveSize   = 0
                terrain.WaterWaveSpeed  = 0
                terrain.WaterReflectance = 0
                terrain.WaterTransparency = 1
            end
            Lighting.GlobalShadows = false
            Lighting.FogEnd   = 9e9
            Lighting.FogStart = 9e9
            pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
            for _, v in ipairs(game:GetDescendants()) do
                if v:IsA("BasePart") then
                    v.Material = Enum.Material.Plastic
                    v.Reflectance = 0
                elseif v:IsA("Decal") then
                    v.Transparency = 1
                elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
                    v.Lifetime = NumberRange.new(0)
                end
            end
            -- tracked so it is disconnected on unload
            Flags._fpsConn = trackConn(Workspace.DescendantAdded:Connect(function(child)
                if not Flags.FPSBoost then return end
                if child:IsA("ForceField") or child:IsA("Sparkles") or child:IsA("Smoke")
                    or child:IsA("Fire") or child:IsA("Beam") or child:IsA("Explosion")
                    or child:IsA("ParticleEmitter") or child:IsA("Trail") then
                    task.defer(function() pcall(function() child:Destroy() end) end)
                end
            end))
            showToast("Lumin Hub", "FPS Boost enabled")
        else
            showToast("Lumin Hub", "FPS Boost disabled")
        end
    end,
})

PerfGB:AddToggle("LowGraphics", {
    Text = "Low Graphics", Default = false,
    Callback = function(state)
        Flags.LowGraphics = state
        if state then
            startLoop("LowGraphics", function()
                pcall(function()
                    local r = settings().Rendering
                    r.QualityLevel     = Enum.QualityLevel.Level01
                    r.EditQualityLevel = Enum.QualityLevel.Level01
                end)
                task.wait(1)
            end)
        else stopLoop("LowGraphics") end
    end,
})

PerfGB:AddToggle("BlackScreen", {
    Text = "Black Screen", Default = false,
    Callback = function(state)
        Flags.BlackScreen = state
        if state then
            local gui = Instance.new("ScreenGui")
            gui.Name            = "LuminBlackScreen"
            gui.ResetOnSpawn    = false
            gui.IgnoreGuiInset  = true
            gui.DisplayOrder    = 9
            local frame = Instance.new("Frame")
            frame.BackgroundColor3 = Color3.new(0, 0, 0)
            frame.Size            = UDim2.fromScale(1, 1)
            frame.BorderSizePixel = 0
            frame.Parent = gui
            gui.Parent = GuiHost
            pcall(protectgui, gui)
            Visuals["_blackscreen"] = gui
        else
            destroyVisuals("_blackscreen")
        end
    end,
})

--=====================================================================
-- SETTINGS
--=====================================================================

local menuGroup = Tabs.Config:AddLeftGroupbox("Menu", "text-align-center")

menuGroup:AddToggle("KeybindMenuOpen", {
    Text = "Open Keybind Menu", Default = false,
    Callback = function(v) Library.KeybindFrame.Visible = v end,
})

menuGroup:AddToggle("AutoExecute_Toggle", {
    Text    = "Auto Execute",
    Tooltip = "Queues the Lumin loader for the next teleport.",
    Default = false,
    Callback = function(enabled)
        if not enabled then return end
        if type(queue_on_teleport) ~= "function" then
            showToast("Lumin Hub", "Your executor does not support queue_on_teleport")
            Toggles.AutoExecute_Toggle:SetValue(false)
            return
        end
        queue_on_teleport([[
            %USER_KEY%;
            loadstring(game:HttpGet("http://luminon.top/loader.lua"))()
        ]])
    end,
})

menuGroup:AddToggle("ShowWatermark", {
    Text = "Show Watermark", Default = true,
    Callback = function(v) Library:SetWatermarkVisibility(v) end,
})

menuGroup:AddToggle("NotifyOnError", {
    Text = "Notify On Error", Default = true,
    Callback = function(v) Library.NotifyOnError = v end,
})

menuGroup:AddToggle("DebugMode", {
    Text    = "Debug Mode",
    Tooltip = "Warns to the console when a loop errors.",
    Default = false,
    Callback = function(v) Flags.DebugMode = v end,
})

menuGroup:AddDropdown("NotificationSide", {
    Values = { "Left", "Right" }, Default = "Right", Text = "Notification Side",
    Callback = function(v) Library:SetNotifySide(v) end,
})

menuGroup:AddDropdown("DPIDropdown", {
    Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
    Default = "100%", Text = "DPI Scale",
    Callback = function(v) Library:SetDPIScale(tonumber((v:gsub("%%", "")))) end,
})

menuGroup:AddToggle("ShowCustomCursor", {
    Text = "Custom Cursor", Default = false,
    Callback = function(v) Library.ShowCustomCursor = v end,
})
Library.ShowCustomCursor = false

menuGroup:AddDivider()

menuGroup:AddToggle("AutoRejoin", {
    Text    = "Auto Rejoin On Kick",
    Tooltip = "Teleports back in when the disconnect prompt appears, and queues the loader so the hub restarts itself.",
    Default = false,
    Callback = function(v)
        Flags.AutoRejoin = v
        if v and type(queue_on_teleport) ~= "function" then
            showToast("Lumin Hub", "Rejoin works, but this executor cannot auto-execute on the new server.")
        end
    end,
})

menuGroup:AddInput("RejoinPayload", {
    Text        = "Rejoin Loader",
    Placeholder = "loadstring(game:HttpGet(\"...\"))()",
    Tooltip     = "Runs on the new server after a rejoin. Leave blank for the default loader.",
    Callback    = function(v) Flags.RejoinPayload = v end,
})

menuGroup:AddButton({
    Text    = "Rejoin Now",
    Tooltip = "Manual server rejoin using the same path as the watchdog.",
    Func    = function() doRejoin("manual") end,
})

menuGroup:AddDivider()
menuGroup:AddButton("Unload", function()
    stopAllLoops()
    disconnectAll()
    destroyVisuals(nil)
    Library:Unload()
end)

--=====================================================================
-- Import / Export
--=====================================================================

do
    local ImEx = Tabs.Config:AddRightGroupbox("Import / Export", "file-input")
    local importFile, importName = "File-Link", "LuminFileName"

    ImEx:AddInputWithButtons("ImportFile", {
        Text = "Import Config (URL or JSON)",
        LeftInput  = { Default = importFile, Placeholder = "File-Link or JSON",
            Callback = function(v) importFile = v end },
        RightInput = { Default = importName, Placeholder = "File-Name",
            Callback = function(v) importName = v end },
    })

    local function configPath(name)
        SaveManager:CheckFolderTree()
        local paths = SaveManager:GetPaths()
        if SaveManager:CheckSubFolder(true) then
            return paths[4] .. "/" .. name .. ".json"
        end
        return paths[3] .. "/" .. name .. ".json"
    end

    ImEx:AddButton("Import File", function()
        local fullPath = configPath(importName)
        if isfile(fullPath) then
            showToast("Import Canceled", "A file with this name already exists.")
            return
        end
        local content
        if importFile:match("^%s*{") or importFile:match("^%s*%[") then
            content = importFile
        else
            if not httprequest then showToast("Failed", "No HTTP function") return end
            local ok, res = pcall(httprequest, { Url = importFile, Method = "GET" })
            if not (ok and res and res.Body) then
                showToast("Failed", "Could not fetch URL.")
                return
            end
            content = res.Body
        end
        if not pcall(function() HttpService:JSONDecode(content) end) then
            showToast("Invalid JSON", "Only valid JSON content can be imported.")
            return
        end
        local okWrite, err = pcall(writefile, fullPath, content)
        showToast(okWrite and "Success" or "Failed",
            okWrite and "Imported config" or ("Failed to import: " .. tostring(err)))
    end)

    ImEx:AddDropdown("ExportConfig_List", {
        Text = "Config list", Values = SaveManager:RefreshConfigList(), AllowNull = true,
    })

    ImEx:AddButton("Export File", function()
        local name = Options.ExportConfig_List.Value
        if not name or name == "" then
            showToast("Failed", "No config selected to export.")
            return
        end
        local ok, content = pcall(readfile, configPath(name))
        if not ok then
            showToast("Failed", "Failed to read config: " .. tostring(content))
            return
        end
        if setclipboard then setclipboard(content) end
        showToast("Success", string.format("Exported %q to clipboard", name))
    end)

    ImEx:AddButton("Refresh List", function()
        Options.ExportConfig_List:SetValues(SaveManager:RefreshConfigList())
        Options.ExportConfig_List:SetValue(nil)
        showToast("Refreshed", "Config list updated.")
    end)
end

--=====================================================================
-- Rejoin watchdog
--=====================================================================

-- Kicks and disconnects surface as Roblox's own error prompt in CoreGui.
-- Watching for it lets us teleport straight back instead of sitting on
-- the "Leave"/"Reconnect" screen. The loader is queued first so the hub
-- comes back up by itself on the new server.
local LOADER_SOURCE = [[
loadstring(game:HttpGet("]] .. (getgenv().LuminHubSource
    or "https://raw.githubusercontent.com/voidhub9-dotcom/mcp-mobile/main/game-scripts/Steal_An_Egg_LuminHub.lua")
    .. [["))()
]]

local function queueLoader()
    if type(queue_on_teleport) ~= "function" then return false end
    local payload = Flags.RejoinPayload
    if not payload or payload == "" then payload = LOADER_SOURCE end
    local ok = pcall(queue_on_teleport, payload)
    return ok
end

local Rejoining = false

function doRejoin(why)
    if Rejoining then return end
    Rejoining = true
    queueLoader()
    warn("[LuminHub] rejoining: " .. tostring(why))
    task.spawn(function()
        for attempt = 1, 6 do
            local ok = pcall(function()
                TeleportService:Teleport(game.PlaceId, LocalPlayer)
            end)
            if ok then task.wait(6) else task.wait(2) end
            -- exponential-ish backoff if the teleport was rejected
            task.wait(math.min(2 ^ attempt, 20))
        end
        Rejoining = false
    end)
end

-- Roblox's disconnect UI lives at CoreGui.RobloxPromptGui.promptOverlay
-- and gains an ErrorPrompt child when the client is kicked or drops.
local function watchForKick()
    local prompt = CoreGui:FindFirstChild("RobloxPromptGui")
    local overlay = prompt and prompt:FindFirstChild("promptOverlay")
    if not overlay then return end
    trackConn(overlay.ChildAdded:Connect(function(child)
        if not Flags.AutoRejoin then return end
        if child.Name:find("ErrorPrompt") or child.Name:find("Error") then
            task.wait(1)
            doRejoin("error prompt: " .. child.Name)
        end
    end))
end

--=====================================================================
-- Runtime wiring
--=====================================================================

-- Anti idle (tracked, so it dies on unload)
trackConn(LocalPlayer.Idled:Connect(function()
    if Flags.AntiAFK == false then return end
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end))

-- Single infinite-jump handler, gated by the flag instead of by
-- creating a new connection per toggle.
trackConn(UserInputService.JumpRequest:Connect(function()
    if not Flags.InfiniteJump then return end
    local hum = getHumanoid()
    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end))

-- NoClip on Stepped (one handler, flag gated)
trackConn(RunService.Stepped:Connect(function()
    if not Flags.NoClip then return end
    local char = getCharacter()
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
    end
end))

-- Re-apply movement stats after a respawn
trackConn(LocalPlayer.CharacterAdded:Connect(function(char)
    -- A respawn drops the server's record of corridor entry.
    GameplayEntered = false
    task.wait(0.2)
    if Flags.AntiDie then
        protectChar(char)
        killACConns()
    end
    if Flags.GodMode then
        godHardenHumanoid(char)
        godStripMovers(char)
    end
    God.carrying, God.carryUid = false, nil
    task.wait(0.6)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if Flags.WalkSpeed and Flags.WalkSpeed > 16 then hum.WalkSpeed = Flags.WalkSpeed end
    if Flags.JumpPower and Flags.JumpPower > 50 then hum.JumpPower = Flags.JumpPower end
end))

watchForKick()

-- Sell confirmation watcher
startLoop("SellConfirmWatcher", function()
    if Flags.AutoSellConfirm then clickYesButton() end
    task.wait(0.25)
end)

-- Spawn sniper + webhook: react to egg updates instead of polling.
local function considerNewEgg(record)
    if type(record) ~= "table" or not record.AssetCategory then return end
    local rarity = assetRarity(record.AssetCategory)

    if Flags.WebhookEnabled then
        Flags.WebhookUrl     = webhookUrl.Value
        Flags.WebhookMention = webhookMention.Value
        local minR = Flags.WebhookMinRarity
        if (not minR) or minR == "" or rarityNum(rarity) >= rarityNum(minR) then
            sendWebhook(record)
        end
    end

    if Flags.SpawnSniper and Flags.AutoSteal then
        local minR = Flags.SnipeMinRarity
        local passes = (not minR) or minR == "" or rarityNum(rarity) >= rarityNum(minR)
        if passes and eggPassesFilters(record) then
            table.insert(SnipeQueue, 1, record)
            if #SnipeQueue > 10 then table.remove(SnipeQueue) end
        end
    end
end

do
    local updated = Network:FindFirstChild("Eggs: AreaEggUpdated")
    if updated and updated:IsA("RemoteEvent") then
        trackConn(updated.OnClientEvent:Connect(function(record)
            pcall(considerNewEgg, record)
        end))
    end
    local batch = Network:FindFirstChild("Eggs: AreaEggBatchUpdated")
    if batch and batch:IsA("RemoteEvent") then
        trackConn(batch.OnClientEvent:Connect(function(records)
            if type(records) ~= "table" then return end
            for _, rec in pairs(records) do pcall(considerNewEgg, rec) end
        end))
    end
end

-- Guard wake handler: bail home when a guard wakes and targets us.
do
    local wake = Network:FindFirstChild("Guards: WakeUp")
    if wake and wake:IsA("RemoteEvent") then
        trackConn(wake.OnClientEvent:Connect(function()
            if not (Flags.AntiDie or Flags.CarryProtect) then return end
            local root = getRoot()
            local center = getPlotCenter()
            if not (root and center) then return end
            for _, g in ipairs(getGuardReport()) do
                if g.awake and g.dist and g.dist < 80 and g.state ~= "ReturningHome" then
                    Move:Stop()
                    pcall(function() root.CFrame = CFrame.new(center) end)
                    return
                end
            end
        end))
    end
end

-- BUG FIX: the old status labels were written once at build time and then
-- never touched, so "Last Steal / Last Sell / Last Fuse" were always Idle.
spawnTracked(function()
    task.wait(0.5)
    pcall(function()
        StealStatus:SetText("Last Steal: " .. Status.Steal)
        SellStatus:SetText("Last Sell: " .. Status.Sell)
        FuseStatus:SetText("Last Fuse: " .. Status.Fuse)

        if GodStatus then
            if Flags.GodMode then
                local since = os.clock() - (God.lastHit or 0)
                GodStatus:SetText(string.format(
                    "GodMode: on | carrying %s | re-grabs %d | flings blocked %d | last hit %s",
                    God.carrying and (God.carryUid and God.carryUid:sub(1, 6) or "yes") or "no",
                    God.regrabs,
                    God.flings or 0,
                    God.lastHit > 0 and string.format("%.0fs ago", since) or "none"))
            else
                GodStatus:SetText("GodMode: off")
            end
        end

        if Flags.GuardRadar then
            local parts = {}
            for _, g in ipairs(getGuardReport()) do
                table.insert(parts, string.format("%s: %s%s",
                    g.areaId, g.awake and "AWAKE" or "asleep",
                    g.dist and string.format(" (%.0f)", g.dist) or ""))
            end
            guardLabel:SetText("Guards:\n" .. (#parts > 0 and table.concat(parts, "\n") or "none found"))
        else
            guardLabel:SetText("Guards: radar off")
        end

        local rows = {}
        local players = Players:GetPlayers()
        table.sort(players, function(a, b)
            local la = a:FindFirstChild("leaderstats")
            local lb = b:FindFirstChild("leaderstats")
            local ma = la and la:FindFirstChild("Money/s")
            local mb = lb and lb:FindFirstChild("Money/s")
            return (ma and ma.Value or 0) > (mb and mb.Value or 0)
        end)
        for i, plr in ipairs(players) do
            if i > 6 then break end
            local ls = plr:FindFirstChild("leaderstats")
            local m  = ls and ls:FindFirstChild("Money/s")
            table.insert(rows, string.format("%d. %s  %s", i, plr.Name, m and tostring(m.Value) or "?"))
        end
        intelLabel:SetText("Players (" .. #players .. "):\n" .. table.concat(rows, "\n"))

        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        local timerGui = pg and pg:FindFirstChild("GameResetTimer")
        local resetText = "--"
        if timerGui then
            for _, d in ipairs(timerGui:GetDescendants()) do
                if d:IsA("TextLabel") and d.Text ~= "" then resetText = d.Text break end
            end
        end
        resetLabel:SetText("Egg reset: " .. resetText)
    end)
end)

--=====================================================================
-- Defaults
--=====================================================================

Flags.StealZones        = {}
Flags.StealRarities     = {}
Flags.SelectEggs        = {}
Flags.SelectMutations   = {}
Flags.FarmMinRarity     = nil
Flags.MinEggWeight      = 0
Flags.SmartTween        = true
Flags.TweenSpeed        = 300
Flags.InstantMove       = false
Flags.DistantTarget     = false
Flags.FarmDelay         = 0
Flags.SellDelay         = 0
Flags.PrioritySystem    = true
Flags.AutoPlaceAfterSteal = true
Flags.InstantPlace      = false
Flags.SnipeDropped      = false
Flags.ForestGuardBypass = false
Flags.NeverSellMutated  = true
Flags.NeverSellEquipped = true
Flags.AutoSellConfirm   = true
Flags.KeepMinRarity     = RarityOrder[3] or RarityOrder[1]
Flags.FuseCount         = 3
Flags.WalkSpeed         = 16
Flags.JumpPower         = 50
Flags.FlySpeed          = 100
Flags.AntiAFK           = true
Flags.GodMode           = false
Flags.HighlightESP      = true
Flags.HopMethod         = "Least Populated"
Flags.DebugMode         = false

_G.LuminHubDebug = function()
    return {
        status  = Status,
        running = Running,
        flags   = Flags,
        queue   = #SnipeQueue,
        plot    = CachedPlot and CachedPlot.Name or "unknown",
    }
end

--=====================================================================
-- Watermark + unload
--=====================================================================

do
    local frameTimer, frameCounter, fps = tick(), 0, 60
    trackConn(RunService.RenderStepped:Connect(function()
        frameCounter += 1
        if tick() - frameTimer >= 1 then
            fps, frameTimer, frameCounter = frameCounter, tick(), 0
        end
        local ping = 0
        pcall(function()
            ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        end)
        Library:SetWatermark(("Lumin Hub | %d fps | %d ms"):format(math.floor(fps), ping))
    end))
end

Library:OnUnload(function()
    UserInputService.MouseIconEnabled = true
    pcall(function() RunService:UnbindFromRenderStep("ShowCursor") end)
    Move:Stop()
    stopAllLoops()
    disconnectAll()
    destroyVisuals(nil)
    local hum = getHumanoid()
    if hum then
        pcall(function()
            hum.PlatformStand = false
            hum.WalkSpeed = 16
            hum.JumpPower = 50
        end)
    end
    _G.LuminHubLibrary = nil
end)

Library:SetWatermarkVisibility(true)
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind", "JobId_Input", "WebhookUrl", "WebhookMention" })
ThemeManager:SetFolder(TemplateConfig.Game.ThemeFolder)
SaveManager:SetFolder(TemplateConfig.Game.SaveFolder)
SaveManager:SetSubFolder(TemplateConfig.Game.SaveSubFolder)
SaveManager:BuildConfigSection(Tabs.Config)
ThemeManager:ApplyToTab(Tabs.Config)
SaveManager:LoadAutoloadConfig()

Loading:SetCurrentStep(4)
Loading:SetDescription("Ready")
task.defer(function() Loading:Continue() end)

Library:Notify({
    Title = "Lumin Hub",
    Description = "Loaded successfully. Steal An Egg.",
    Time = 4,
})
