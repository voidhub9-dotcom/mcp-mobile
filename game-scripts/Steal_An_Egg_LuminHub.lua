if not game:IsLoaded() then game.Loaded:Wait() end

if _G.LuminHubShutdown then pcall(_G.LuminHubShutdown) end

local ScriptGeneration = (_G.LuminHubGeneration or 0) + 1
_G.LuminHubGeneration = ScriptGeneration

local Running      = {}
local Connections  = {}
local Threads      = {}
local Visuals      = {}

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
        local char = Players.LocalPlayer.Character
        if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Anchored = false
                part.CanCollide = true
            end
        end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
    end)

    local stale = _G.LuminHubLibrary
    _G.LuminHubLibrary  = nil
    _G.LuminHubDebug    = nil
    _G.LuminHubRunning  = nil
    if stale then
        task.spawn(function() pcall(function() stale:Unload() end) end)
    end
end

local TemplateConfig = {
    Branding = {
        WindowTitle  = " ",
        Footer       = "discord.gg/luminhub",
    },
    Game = {
        ExpectedPlaceVersion = 385,
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
}

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
local VirtualUser
local Workspace          = cloneref(game:GetService("Workspace"))
local ReplicatedStorage  = cloneref(game:GetService("ReplicatedStorage"))
local Lighting           = cloneref(game:GetService("Lighting"))
local Stats              = cloneref(game:GetService("Stats"))
local LogService         = cloneref(game:GetService("LogService"))
local ScriptContext      = cloneref(game:GetService("ScriptContext"))
local CollectionService  = cloneref(game:GetService("CollectionService"))

local LocalPlayer = Players.LocalPlayer

local GuiHost = (gethui and gethui()) or CoreGui

do
    local hookFunction   = resolveFunction(hookfunction)
    local hookMetamethod = resolveFunction(hookmetamethod)
    local getNamecall    = resolveFunction(getnamecallmethod)

    local okNet, ClientNetwork = pcall(function()
        local rs = cloneref and game:GetService("ReplicatedStorage") or ReplicatedStorage
        return require(rs:WaitForChild("Library"):WaitForChild("Client"):WaitForChild("Network"))
    end)
    local okConst, Constants = pcall(function()
        local rs = game:GetService("ReplicatedStorage")
        return require(rs:WaitForChild("Library"):WaitForChild("Globals"):WaitForChild("Constants"))
    end)

    local ReportRemote
    if okConst and type(Constants) == "table" then
        local sync = Constants.NETWORK_MAP and Constants.NETWORK_MAP.RuntimeSync
        if type(sync) == "table" then
            ReportRemote = sync.REPORT
        end
    end

    if okNet and type(ClientNetwork) == "table" and type(ClientNetwork.Fire) == "function" and hookFunction then
        pcall(function()
            local origFire
            origFire = hookFunction(ClientNetwork.Fire, function(remote, ...)
                if ReportRemote ~= nil and remote == ReportRemote then
                    return
                end
                return origFire(remote, ...)
            end)
        end)
    end

    if hookMetamethod and getNamecall and ReportRemote ~= nil and typeof(ReportRemote) == "Instance" then
        pcall(function()
            local origNamecall
            origNamecall = hookMetamethod(game, "__namecall", function(self, ...)
                if self == ReportRemote and getNamecall() == "FireServer" then
                    return
                end
                return origNamecall(self, ...)
            end)
        end)
    end
end

do
    local hookFunction = resolveFunction(hookfunction)
    local newCC        = resolveFunction(newcclosure, function(f) return f end)

    local function silence(name)
        local env = (type(getgenv) == "function" and getgenv()) or _G
        local old = env[name]
        if type(old) == "function" and hookFunction then
            pcall(function() hookFunction(old, newCC(function() end)) end)
        end
        pcall(function() env[name] = function() end end)
    end

    for _, name in ipairs({
        "print", "warn", "rconsoleprint", "rconsoleinfo",
        "rconsolewarn", "rconsoleerr", "printconsole", "printidentity",
    }) do
        silence(name)
    end

    local function killLogListeners()
        if not getconnections then return end
        for _, signal in ipairs({ LogService.MessageOut, ScriptContext.Error }) do
            pcall(function()
                for _, conn in ipairs(getconnections(signal)) do
                    pcall(function() conn:Disable() end)
                end
            end)
        end
    end

    local function clearOutput()
        pcall(function() LogService:ClearOutput() end)
    end

    killLogListeners()
    clearOutput()

    local myGen = ScriptGeneration
    task.spawn(function()
        while myGen == _G.LuminHubGeneration do
            killLogListeners()
            clearOutput()
            task.wait(5)
        end
    end)
end

local function neutralizeFrameLoops()
    if not (getconnections and debug and debug.getinfo) then return end
    local signals = {
        RunService.Heartbeat,
        RunService.Stepped,
        RunService.PreSimulation,
        RunService.PostSimulation,
        RunService.PreRender,
        RunService.RenderStepped,
    }
    for _, signal in ipairs(signals) do
        for _, conn in ipairs(getconnections(signal)) do
            local ok, fn = pcall(function() return conn.Function end)
            if ok and type(fn) == "function" then
                local info = debug.getinfo(fn, "S")
                local src  = (info and info.short_src) or ""
                if src == "" or src:find("UGI.ContentCatalog", 1, true) then
                    pcall(function() conn:Disable() end)
                end
            end
        end
    end
end

neutralizeFrameLoops()

local Library = loadstring(game:HttpGet(TemplateConfig.Dependencies.LibraryUrl))()
_G.LuminHubLibrary = Library

local repo = "http://luminon.top/obsidian/"
local ThemeManager = loadstring(game:HttpGet(repo .. "Addons/ThemeManager.lua"))()
local SaveManager  = loadstring(game:HttpGet(repo .. "Addons/SaveManager.lua"))()

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

local ZoneList = {}
do
    local okAreas, AreasConfig = pcall(function()
        return require(Directory:WaitForChild("Areas"))
    end)
    if okAreas and type(AreasConfig) == "table" and type(AreasConfig.Directory) == "table" then
        for zoneName in pairs(AreasConfig.Directory) do
            table.insert(ZoneList, zoneName)
        end
    end
    if #ZoneList == 0 then
        ZoneList = {
            "Abyss Ocean", "Cherry Blossom", "Cosmic", "Desert", "Forest",
            "Jungle", "Lake", "Prehistoric", "Snow", "Volcano",
        }
    end
    table.sort(ZoneList)
end

local RarityNumber   = {}
local RarityColour   = {}
local RarityOrder    = {}
local AssetInfo      = {}
local DisplayToAsset = {}

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

local Ext = {
    AreaDirectory = {},
    GearDirectory = {},
    Constants     = {},
}

do
    local function tryRequire(...)
        local node = ReplicatedStorage
        for _, name in ipairs({ ... }) do
            if not node then return nil end
            node = node:FindFirstChild(name)
        end
        if not node then return nil end
        local ok, mod = pcall(require, node)
        return ok and mod or nil
    end

    local areas = tryRequire("Directory", "Areas")
    if type(areas) == "table" and type(areas.Directory) == "table" then
        Ext.AreaDirectory = areas.Directory
    end

    local gears = tryRequire("Directory", "Gears")
    if type(gears) == "table" and type(gears.Directory) == "table" then
        Ext.GearDirectory = gears.Directory
    end

    Ext.BatConfig     = tryRequire("Library", "Modules", "BatController", "Config") or {}
    Ext.BloomPolicy   = tryRequire("Library", "Modules", "SakuraBloomPolicy")
    Ext.ToolGuard     = tryRequire("Library", "Client", "ToolGameplayGuard")
    Ext.Ragdoll       = tryRequire("Library", "Modules", "Ragdoll")
    Ext.ClientSave    = tryRequire("Library", "Client", "Save")
    Ext.CurrencyCmds  = tryRequire("Library", "Client", "CurrencyCmds")
    Ext.SpeedUtil     = tryRequire("Library", "Util", "SpeedUpgradeUtil")
    Ext.Constants     = tryRequire("Library", "Globals", "Constants") or {}

    local sakura    = tryRequire("Directory", "Sakura") or {}
    local bloom     = type(sakura.Bloom) == "table" and sakura.Bloom or {}
    local incubator = type(sakura.Incubator) == "table" and sakura.Incubator or {}

    Ext.Sakura = {
        TreeTag      = sakura.TreeTag or "SakuraBloomTree",
        CrystalTag   = sakura.CrystalTag or "SakuraCrystal",
        EventName    = sakura.EventName or "GreatBloom",
        CurrencyId   = sakura.CurrencyId or "SakuraCrystals",
        MutationName = sakura.MutationName or "Sakura",
        CraneAssetId = (type(sakura.Quest) == "table" and sakura.Quest.CraneAssetId) or "Crane",
        AreaId       = (type(sakura.AreaDisplay) == "table" and sakura.AreaDisplay.DisplayName)
            or "Cherry Blossom",
        EndsAtAttr   = bloom.EndsAtAttribute or "GreatBloomEndsAt",
        HitRange     = tonumber(bloom.HitRange) or 10,
        HitCooldown  = tonumber(bloom.HitCooldownSeconds) or 0.6,
        HitHold      = tonumber(bloom.HitHoldSeconds) or 0.2,
        PickupRange  = tonumber(bloom.CrystalPickupRange) or 10,
        CrystalLife  = tonumber(bloom.CrystalLifetimeSeconds) or 60,
        Duration     = tonumber(bloom.DurationSeconds) or 285,
        Interval     = tonumber(bloom.IntervalSeconds) or 1800,
        WarnSeconds  = tonumber(bloom.EndingWarningSeconds) or 30,
        UnlockCost   = tonumber(incubator.Cost) or 1000,
        MaxCharge    = tonumber(incubator.MaxChargePercent) or 150,
    }

    Ext.BatRange     = tonumber(Ext.BatConfig.Range) or 15
    Ext.BatTolerance = tonumber(Ext.BatConfig.HitTolerance) or 2
end

function Ext.batHitboxScalar()
    if type(Ext.BatConfig.GetHitboxScalar) ~= "function" then return 1 end
    local ok, scalar = pcall(Ext.BatConfig.GetHitboxScalar)
    return (ok and tonumber(scalar)) or 1
end

function Ext.batServerRange(gearName)
    local bonus = 0
    local gear  = gearName and Ext.GearDirectory[gearName]
    if type(gear) == "table" and type(gear.BatControllerData) == "table" then
        bonus = tonumber(gear.BatControllerData.RangeBonus) or 0
    end
    return (Ext.BatRange + Ext.BatTolerance + bonus) * Ext.batHitboxScalar()
end

local function rarityNum(name)
    if not name then return 0 end
    return RarityNumber[name] or 0
end

local function assetRarity(category)
    local info = AssetInfo[category]
    return info and info.rarity or nil
end

local Flags = {}
_G.LuminHubRunning = Running

local Status = {
    Steal = "Idle",
    Sell  = "Idle",
    Fuse  = "Idle",
    Guard = "Unknown",
    Farm  = "Idle",
}

local doRejoin

local CarryCooldowns, CarryFails = {}, {}
local GlobalCarryCooldown = 0
local PlaceCooldown       = 0
local InventoryFull       = false
local InventoryFullCount  = 0
local SnipeQueue          = {}
local WebhookSent         = {}

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

local function protectChar(char)
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false) end)
    pcall(function() hum.BreakJointsOnDeath = false end)
    pcall(function() hum.MaxHealth = math.huge hum.Health = math.huge end)
end

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

local function flatDist(a, b)
    local d = a - b
    return (Vector3.new(d.X, 0, d.Z)).Magnitude
end

local Move = {
    cancel    = false,
    lastFail  = nil,
    moving    = false,
    speed     = nil,
    rollbacks = 0,
    lastNote  = "",
}

function Move:BaseSpeed()
    return math.max(tonumber(Flags.TweenSpeed) or 300, 20)
end

function Move:CurrentSpeed()
    return math.clamp(self.speed or self:BaseSpeed(), 20, 2000)
end

function Move:Penalise()
    if Flags.AdaptiveSpeed == false then return end
    local now = self:CurrentSpeed()

    self.speed = math.max(60, math.floor(now * 0.65))
    self.rollbacks = self.rollbacks + 1
    self.lastNote = string.format("rolled back, speed %d -> %d", now, self.speed)
end

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

function Move:Attempt(targetPos, timeout)
    local root = getRoot()
    if not root then return false, false end
    self.moving = true
    self.lastFail = nil

    local speed  = self:CurrentSpeed()
    local start  = os.clock()
    local stalls = 0
    local frames = 0
    local closest = math.huge

    local restore = {}
    local char = getCharacter()
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                restore[#restore + 1] = part
                part.CanCollide = false
            end
        end
    end
    local function releaseCollisions()
        for _, part in ipairs(restore) do
            if part.Parent then pcall(function() part.CanCollide = true end) end
        end
        table.clear(restore)
    end

    while os.clock() - start < timeout do
        if self.cancel then self.lastFail = "cancelled" self.moving = false releaseCollisions() return false, false end
        root = getRoot()
        if not root then self.lastFail = string.format("lost character after %d frames", frames) self.moving = false releaseCollisions() return false, false end

        local here = root.Position
        local toGo = targetPos - here
        local dist = toGo.Magnitude
        if dist <= 6 then self.moving = false releaseCollisions() return true, false end
        if dist < closest then closest = dist end

        local dt   = RunService.Heartbeat:Wait()
        local step = math.min(speed * dt, dist)

        root = getRoot()
        if not root then self.lastFail = string.format("lost character after %d frames", frames) self.moving = false releaseCollisions() return false, false end
        root.CFrame = CFrame.new(here + toGo.Unit * step)

        root.AssemblyLinearVelocity  = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero

        RunService.Heartbeat:Wait()
        root = getRoot()
        if not root then self.lastFail = string.format("lost character after %d frames", frames) self.moving = false releaseCollisions() return false, false end

        frames = frames + 1

        local progressed = (root.Position - here).Magnitude
        if progressed < math.min(step * 0.1, 0.5) then
            stalls = stalls + 1
            if stalls >= 12 then
                self.lastFail = string.format("stalled %d frames, %.0f studs out",
                    frames, (root.Position - targetPos).Magnitude)
                self.moving = false releaseCollisions() return false, true
            end
        else
            stalls = 0
        end
    end

    root = getRoot()
    local remaining = root and (root.Position - targetPos).Magnitude or -1
    local arrived = remaining >= 0 and remaining <= 14
    if not arrived then
        self.lastFail = string.format("timeout %.1fs at speed %d, %d frames, %.0f studs out",
            os.clock() - start, speed, frames, remaining)
    end
    self.moving = false
    releaseCollisions()
    return arrived or false, not arrived
end

function Move:TweenOnce(targetPos, timeout)
    local root = getRoot()
    if not root then return false, false end

    local goalPos = Vector3.new(targetPos.X, root.Position.Y, targetPos.Z)

    local speed = self:CurrentSpeed()
    local dist  = flatDist(root.Position, goalPos)
    if dist <= 6 then return true, false end

    self.moving = true
    self.lastFail = nil

    local restore = {}
    local char = getCharacter()
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                restore[#restore + 1] = part
                part.CanCollide = false
            end
        end
    end
    local function releaseCollisions()
        for _, part in ipairs(restore) do
            if part.Parent then pcall(function() part.CanCollide = true end) end
        end
        table.clear(restore)
    end

    pcall(function() Workspace:RequestStreamAsync(goalPos) end)
    local okCreate, tween = pcall(function()
        return TweenService:Create(root, TweenInfo.new(dist / speed, Enum.EasingStyle.Linear), { CFrame = CFrame.new(goalPos) })
    end)
    if not okCreate or not tween then
        self.moving = false
        releaseCollisions()
        return self:Attempt(targetPos, timeout)
    end

    local start    = os.clock()
    local deadline = start + math.min(timeout, dist / speed + 2)
    local stalls, lastDist = 0, dist

    tween:Play()

    while os.clock() < deadline do
        if self.cancel then
            tween:Cancel()
            self.lastFail = "cancelled"
            self.moving = false
            releaseCollisions()
            return false, false
        end
        root = getRoot()
        if not root then
            tween:Cancel()
            self.lastFail = "lost character"
            self.moving = false
            releaseCollisions()
            return false, false
        end

        local remain = flatDist(root.Position, goalPos)
        if remain <= 6 then
            tween:Cancel()
            break
        end

        root.AssemblyLinearVelocity  = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero

        RunService.Heartbeat:Wait()

        root = getRoot()
        if not root then tween:Cancel() self.moving = false releaseCollisions() return false, false end
        local now = flatDist(root.Position, goalPos)

        if now > lastDist + 1 then
            stalls = stalls + 1
            if stalls >= 8 then
                tween:Cancel()
                self.lastFail = string.format("rolled back during tween, %.0f studs out", now)
                self.moving = false
                releaseCollisions()
                return false, true
            end
        elseif now < lastDist - 0.5 then
            stalls = 0
        end
        lastDist = now
    end

    tween:Cancel()
    root = getRoot()
    if not root then
        self.moving = false
        releaseCollisions()
        return false, false
    end

    if flatDist(root.Position, targetPos) <= 8 and math.abs(root.Position.Y - targetPos.Y) > 1.5 then
        local dy = math.abs(targetPos.Y - root.Position.Y)
        local okV, vtween = pcall(function()
            return TweenService:Create(root, TweenInfo.new(math.max(dy, 1) / speed, Enum.EasingStyle.Linear), { CFrame = CFrame.new(targetPos) })
        end)
        if okV and vtween then
            vtween:Play()
            local vdeadline = os.clock() + dy / speed + 1
            while os.clock() < vdeadline do
                if self.cancel then vtween:Cancel() break end
                root = getRoot()
                if not root then vtween:Cancel() break end
                if (root.Position - targetPos).Magnitude <= 3 then break end
                RunService.Heartbeat:Wait()
            end
            vtween:Cancel()
        else
            pcall(function() root.CFrame = CFrame.new(targetPos) end)
        end
    end

    root = getRoot()
    local remaining = root and (root.Position - targetPos).Magnitude or -1
    local arrived = remaining >= 0 and remaining <= 8
    if not arrived then
        self.lastFail = string.format("tween timeout %.1fs, %.0f studs out", os.clock() - start, remaining)
    end
    self.moving = false
    releaseCollisions()
    return arrived or false, not arrived
end

function Move:To(targetPos, timeoutSeconds)
    self.cancel = false

    local mode = Flags.MoveMode or "Tween"
    local root0 = getRoot()
    local dist0 = root0 and flatDist(root0.Position, targetPos) or 0

    local timeout = timeoutSeconds
    if not timeout then
        local sp = self:CurrentSpeed()
        timeout = math.clamp(dist0 / math.max(sp, 20) * 3 + 3, 4, 30)
    end

    if mode == "Instant" or Flags.InstantMove then
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
        local ok, rolledBack = self:TweenOnce(targetPos, timeout)
        if ok then
            self:Reward()
            return true
        end
        if not rolledBack then return false end
        self:Penalise()
        Status.Steal = (Flags.AdaptiveSpeed and self.lastNote ~= "")
            and ("Adapting: " .. self.lastNote)
            or "Retrying travel"
        task.wait(0.2)
    end
    return false
end

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

local function listToSet(value)
    if value == nil then return nil end

    if type(value) == "string" then
        if value == "" then return nil end
        return { [value] = true }
    end

    if type(value) ~= "table" then return nil end

    local set, count = {}, 0

    for _, v in ipairs(value) do
        if type(v) == "string" then
            set[v] = true
            count = count + 1
        end
    end

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

local function getGuardAreas()
    local objs = Workspace:FindFirstChild("__OBJECTS")
    if not objs then return nil end
    local areas = objs:FindFirstChild("Areas")
    if not areas then return nil end
    return areas:FindFirstChild("GuardAreas")
end

local function getGuardReport()
    local report = {}
    local container = getGuardAreas()
    if not container then return report end
    local root = getRoot()
    for _, area in ipairs(container:GetChildren()) do
        local guard = area:FindFirstChild("Guard")
        if guard then

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

local function isGuardAwake(selectedZones)
    local zoneFilter = listToSet(selectedZones)
    for _, g in ipairs(getGuardReport()) do
        if (not zoneFilter) or zoneFilter[g.areaId] then
            if g.awake then
                if Flags.ForestGuardBypass and g.areaId == "Forest" then

                else
                    return true, g.areaId
                end
            end
        end
    end
    return false
end

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

local function eggPassesFilters(egg)
    if egg.State ~= "Slot" and not Flags.SnipeDropped then return false end
    if string.find(egg.Uid or "", "FirstAreaEgg") then return false end

    local category = egg.AssetCategory
    if not category then return false end

    local zoneSet = listToSet(Flags.StealZones)
    if zoneSet and egg.AreaId and not zoneSet[egg.AreaId] then return false end

    local minR = Flags.FarmMinRarity
    if minR and minR ~= "" then
        if rarityNum(assetRarity(category)) < rarityNum(minR) then return false end
    end

    local rarSet = listToSet(Flags.StealRarities)
    if rarSet and not rarSet[assetRarity(category)] then return false end

    local eggSet = listToSet(Flags.SelectEggs)
    if eggSet then
        local info = AssetInfo[category]
        if not (info and eggSet[info.display]) then return false end
    end

    local mutSet = listToSet(Flags.SelectMutations)
    if mutSet then
        local found = false
        for _, m in ipairs(getEggMutations(egg)) do
            if mutSet[m] then found = true break end
        end
        if not found then return false end
    end

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

local function startLoop(name, func)
    if Running[name] then return end
    Running[name] = true
    local myGen = ScriptGeneration
    task.spawn(function()
        while Running[name] and myGen == _G.LuminHubGeneration do
            pcall(func)
            task.wait()
        end
        Running[name] = false
    end)
end

local function stopLoop(name) Running[name] = false end

startLoop("ACSweep", function()
    neutralizeFrameLoops()
    task.wait(5)
end)

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

local EspEntries = {}

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

local God = {
    regrabs   = 0,
    flings    = 0,
    lastHit   = 0,
    carrying  = false,
    carryUid  = nil,
    active    = false,
}

local LuminGod = {}
do
    local connections, characterConnections = {}, {}
    local character, humanoid, root
    local anchor, lockUntil, hitAt = nil, 0, 0
    local carriedUid, uidUntil = nil, 0
    local pendingDrop, pendingToken, dropAt = nil, 0, 0
    local regrabBusy, lastTriedToken = false, 0
    local EggCmds, Ragdoll

    local trail, TRAIL_BACK = {}, 0.18

    local function pushTrail(cf)
        local now = os.clock()
        table.insert(trail, { t = now, cf = cf })
        while #trail > 0 and now - trail[1].t > 0.6 do table.remove(trail, 1) end
    end

    local function trailAnchor(fallback)
        local cutoff = os.clock() - TRAIL_BACK
        for i = #trail, 1, -1 do
            if trail[i].t <= cutoff then return trail[i].cf end
        end
        return trail[1] and trail[1].cf or fallback
    end

    local function disconnectList(list)
        for _, c in ipairs(list) do pcall(function() c:Disconnect() end) end
        table.clear(list)
    end

    local function releaseGameAnchor()
        if not root then return end
        if root.Anchored then
            root.Anchored = false
            root.AssemblyLinearVelocity = Vector3.zero
        end
    end

    local function clearPhysics()
        if not God.active or not (character and humanoid and root) then return end
        releaseGameAnchor()
        if Ragdoll and Ragdoll.ClearClientRagdoll then
            pcall(Ragdoll.ClearClientRagdoll, character)
        end
        root.AssemblyLinearVelocity  = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.Running) end)
    end

    local function tryRegrab(record, token)
        if not God.active or regrabBusy or token ~= pendingToken
            or token == lastTriedToken or type(record) ~= "table" then
            return
        end
        local uid = tostring(record.Uid or "")
        if uid == "" or uid ~= tostring(carriedUid or "") then return end

        regrabBusy = true
        lastTriedToken = token

        task.spawn(function()
            local key
            if uid:sub(1, 13) == "FirstAreaEgg_" and record.AreaId and record.NestId then
                key = tostring(record.AreaId) .. ":" .. tostring(record.NestId)
            end

            local deadline = os.clock() + 0.65
            repeat
                if not God.active or token ~= pendingToken then break end
                local ok, success = pcall(EggCmds.RequestCarryAreaEgg, uid, key)
                if ok and success == true then
                    uidUntil     = math.huge
                    God.regrabs  = God.regrabs + 1
                    God.carrying = true
                    Status.Steal = "GodMode: re-grabbed after hit (" .. God.regrabs .. ")"
                    break
                end
                task.wait(0.05)
            until os.clock() >= deadline

            regrabBusy = false
        end)
    end

    local function attachCharacter(newCharacter)
        disconnectList(characterConnections)
        table.clear(trail)
        character = newCharacter
        humanoid  = newCharacter:WaitForChild("Humanoid", 10)
        root      = newCharacter:WaitForChild("HumanoidRootPart", 10)
        if not (humanoid and root) then return end

        protectChar(newCharacter)

        pcall(function()
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
            humanoid.BreakJointsOnDeath = false
        end)

        table.insert(characterConnections, humanoid.HealthChanged:Connect(function(h)
            if God.active and h < 1 then
                pcall(function() humanoid.Health = humanoid.MaxHealth end)
            end
        end))

        table.insert(characterConnections, humanoid.StateChanged:Connect(function(_, state)
            if not God.active or state ~= Enum.HumanoidStateType.Physics then return end

            if Move.moving then return end
            hitAt       = os.clock()
            anchor      = trailAnchor(root.CFrame)
            lockUntil   = hitAt + 0.45
            God.lastHit = hitAt
            God.flings  = God.flings + 1

            clearPhysics()
            task.defer(clearPhysics)

            if pendingDrop and math.abs(hitAt - dropAt) <= 0.2 then
                tryRegrab(pendingDrop, pendingToken)
            end
        end))

        table.insert(characterConnections, RunService.PostSimulation:Connect(function()
            if not God.active or not root then return end

            if not anchor and not Move.moving
                and humanoid:GetState() ~= Enum.HumanoidStateType.Physics then
                pushTrail(root.CFrame)
            end

            releaseGameAnchor()

            if Move.moving then
                anchor = nil
                return
            end

            if anchor and os.clock() < lockUntil then
                root.CFrame = anchor
                root.AssemblyLinearVelocity  = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
                if humanoid:GetState() == Enum.HumanoidStateType.Physics then
                    clearPhysics()
                end
            else
                anchor = nil
            end
        end))

        pcall(function()
            local snapshot = EggCmds.GetAreaEggSnapshot()
            for _, record in pairs((snapshot and snapshot.Records) or {}) do
                if record.State == "Carried" and record.CarrierUserId == LocalPlayer.UserId then
                    carriedUid   = tostring(record.Uid)
                    uidUntil     = math.huge
                    God.carrying = true
                    God.carryUid = carriedUid
                    break
                end
            end
        end)
    end

    function LuminGod:Start()
        if God.active then return true end

        startLoop("GodAlive", function()
            if God.active and humanoid then
                pcall(function()
                    humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
                    humanoid.BreakJointsOnDeath = false
                end)
            end
            task.wait(1)
        end)

        local okE, cmds = pcall(function()
            return require(ReplicatedStorage.Library.Client.EggCmds)
        end)
        if not okE or type(cmds) ~= "table" then
            showToast("Lumin Hub", "GodMode: EggCmds unavailable")
            return false
        end
        EggCmds = cmds
        pcall(function()
            Ragdoll = require(ReplicatedStorage.Library.Modules.Ragdoll)
        end)

        God.active = true

        table.insert(connections, EggCmds.AreaEggCarryStateChanged:Connect(function(state)
            if state and state.IsCarrying and state.Uid then
                carriedUid   = tostring(state.Uid)
                uidUntil     = math.huge
                God.carrying = true
                God.carryUid = carriedUid
            elseif carriedUid then

                uidUntil     = os.clock() + 1
                God.carrying = false
            end
        end))

        table.insert(connections, EggCmds.AreaEggUpdated:Connect(function(record)
            if not God.active or type(record) ~= "table" or record.State ~= "Dropped" then return end
            if tostring(record.Uid or "") ~= tostring(carriedUid or "") or os.clock() > uidUntil then
                return
            end

            pendingToken = pendingToken + 1
            pendingDrop  = record
            dropAt       = os.clock()
            local token  = pendingToken

            if math.abs(dropAt - hitAt) <= 0.2 then
                tryRegrab(record, token)
            else
                task.delay(0.08, function()
                    if God.active and token == pendingToken
                        and math.abs(hitAt - dropAt) <= 0.2 then
                        tryRegrab(record, token)
                    end
                end)
            end
        end))

        table.insert(connections, LocalPlayer.CharacterAdded:Connect(function(newCharacter)
            task.wait(0.2)
            if God.active then attachCharacter(newCharacter) end
        end))

        if LocalPlayer.Character then attachCharacter(LocalPlayer.Character) end
        return true
    end

    function LuminGod:Stop()
        God.active = false
        stopLoop("GodAlive")
        clearPhysics()
        disconnectList(characterConnections)
        disconnectList(connections)
        anchor, pendingDrop = nil, nil
        if humanoid then
            pcall(function()
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
            end)
        end
    end
end

local NoAnims = { active = false }
do
    local conns = {}

    local function stopTracks(char)
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
            pcall(function() track:Stop(0) end)
        end
    end

    local function attachNoAnims(char)
        local hum = char and char:WaitForChild("Humanoid", 10)
        if not hum then return end
        stopTracks(char)
        local c = hum.AnimationPlayed:Connect(function(track)
            if NoAnims.active then pcall(function() track:Stop(0) end) end
        end)
        table.insert(conns, c)
        trackConn(c)
    end

    function NoAnims:Start()
        if NoAnims.active then return end
        NoAnims.active = true
        if LocalPlayer.Character then attachNoAnims(LocalPlayer.Character) end
        local c = LocalPlayer.CharacterAdded:Connect(function(char)
            if not NoAnims.active then return end
            task.wait(0.2)
            attachNoAnims(char)
        end)
        table.insert(conns, c)
        trackConn(c)
    end

    function NoAnims:Stop()
        NoAnims.active = false
        for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
        table.clear(conns)
    end
end

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

            invokeRemote("FuseMachine: RemoveMob", p1.uid)
            invokeRemote("FuseMachine: RemoveMob", p2.uid)
            task.wait(0.6)
        end
    end
    return fused
end

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
    Move:To(goal, 12)

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

    local basePos
    if target.BottomCFrame and typeof(target.BottomCFrame) == "CFrame" then
        basePos = target.BottomCFrame.Position
    elseif target.BoundsCFrame and typeof(target.BoundsCFrame) == "CFrame" then
        basePos = target.BoundsCFrame.Position
    end
    if not basePos then return false end

    local targetPos = basePos + Vector3.new(0, 3.0, 0)

    Status.Steal = "Travelling to " .. (target.AssetCategory or "?")
    if not Move:To(targetPos) then
        Status.Steal = "Travel failed: " .. tostring(Move.lastFail or "unknown")
        return false
    end

    local carried, reason = false, nil
    for _ = 1, 6 do
        root = getRoot()
        if not root then break end

        root.CFrame = CFrame.new(targetPos)
        root.AssemblyLinearVelocity  = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        local remote = Network:FindFirstChild("Eggs: RequestAreaEggCarry")
        if not remote then break end
        local ok, res, why = pcall(function()
            return remote:InvokeServer({
                Uid = target.Uid,

                FirstAreaSlotKey = (tostring(target.Uid):sub(1, 13) == "FirstAreaEgg_"
                    and target.AreaId and target.NestId)
                    and (tostring(target.AreaId) .. ":" .. tostring(target.NestId))
                    or nil,
            })
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

    local okE, cmds = pcall(function()
        return require(ReplicatedStorage.Library.Client.EggCmds)
    end)

    local function getLiveRecord()
        if not (okE and type(cmds) == "table" and type(cmds.GetAreaEggSnapshot) == "function") then
            return nil
        end
        local okS, snap = pcall(cmds.GetAreaEggSnapshot)
        if not okS or type(snap) ~= "table" then return nil end
        for _, rec in pairs(snap.Records or {}) do
            if tostring(rec.Uid) == tostring(target.Uid) then return rec end
        end
        return nil
    end

    local function carriedByUs(rec)
        return rec ~= nil and rec.State == "Carried" and rec.CarrierUserId == LocalPlayer.UserId
    end

    local legs = {}
    do
        local objs  = Workspace:FindFirstChild("__OBJECTS")
        local areas = objs and objs:FindFirstChild("Areas")
        local start = areas and areas:FindFirstChild("StartArea")
        if start then
            table.insert(legs, { pos = groundAt(start.Position + Vector3.new(40, 0, 0)), budget = 15 })
            table.insert(legs, { pos = groundAt(start.Position - Vector3.new(6, 0, 0)),  budget = 10 })
        end
        table.insert(legs, { pos = plotCenter })
    end

    local regrabbed = 0
    while true do
        local rec
        for _, leg in ipairs(legs) do
            Move:To(leg.pos, leg.budget)
            rec = getLiveRecord()
            if not carriedByUs(rec) then break end
        end
        rec = rec or getLiveRecord()

        if carriedByUs(rec) then break end

        if rec and rec.State == "Dropped" and regrabbed < 3 then
            regrabbed = regrabbed + 1
            Status.Steal = "Guard hit - re-grabbing (" .. regrabbed .. ")"
            local dropPos = (rec.BottomCFrame and rec.BottomCFrame.Position)
                or (rec.BoundsCFrame and rec.BoundsCFrame.Position)
            if not dropPos then break end
            Move:To(dropPos + Vector3.new(0, 3.0, 0), 15)
            local remote = Network:FindFirstChild("Eggs: RequestAreaEggCarry")
            if not remote then break end
            local ok2, res2 = pcall(function()
                return remote:InvokeServer({
                    Uid = rec.Uid,
                    FirstAreaSlotKey = (tostring(rec.Uid):sub(1, 13) == "FirstAreaEgg_"
                        and rec.AreaId and rec.NestId)
                        and (tostring(rec.AreaId) .. ":" .. tostring(rec.NestId))
                        or nil,
                })
            end)
            if not (ok2 and res2 == true) then break end
        else
            break
        end
    end

    local function isStillCarrying()
        return carriedByUs(getLiveRecord())
    end

    local claimDeadline = os.clock() + 2.5
    while os.clock() < claimDeadline and isStillCarrying() do
        task.wait(0.2)
    end

    if isStillCarrying() then
        invokeRemote("Eggs: RequestAreaEggDrop", {})
        task.wait(0.25)
    end

    if Flags.AutoPlaceAfterSteal and PlaceCooldown < os.clock() then

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

Ext.DropOdds = {}

do
    for areaId, entry in pairs(Ext.AreaDirectory) do
        if type(entry) == "table" and type(entry.DropTable) == "table" then
            local rows, total = {}, 0
            for _, drop in ipairs(entry.DropTable) do
                local category, weight
                if type(drop) == "table" then
                    category = drop[1] or drop.Category or drop.Asset or drop.AssetCategory
                    weight   = tonumber(drop[2] or drop.Weight or drop.Chance)
                end
                if category and weight and weight > 0 then
                    rows[#rows + 1] = { cat = tostring(category), weight = weight }
                    total = total + weight
                end
            end
            if total > 0 then
                table.sort(rows, function(a, b) return a.weight < b.weight end)
                local byCat = {}
                for _, row in ipairs(rows) do
                    row.pct   = row.weight / total * 100
                    row.oneIn = total / row.weight
                    byCat[row.cat] = row
                end
                Ext.DropOdds[tostring(areaId)] = { total = total, rows = rows, byCat = byCat }
            end
        end
    end
end

function Ext.shortNumber(value)
    value = tonumber(value) or 0
    local units = { "", "K", "M", "B", "T", "Qd", "Qn" }
    local index = 1
    while value >= 1000 and index < #units do
        value = value / 1000
        index = index + 1
    end
    if index == 1 then return string.format("%d", value) end
    return string.format("%.2f%s", value, units[index])
end

function Ext.eggOdds(areaId, category)
    local table_ = Ext.DropOdds[tostring(areaId)]
    local row = table_ and table_.byCat[tostring(category)]
    if not row then return nil, nil end
    return row.pct, row.oneIn
end

function Ext.formatOneIn(oneIn)
    if not oneIn then return "?" end
    if oneIn >= 1000 then return string.format("1 in %d", math.floor(oneIn + 0.5)) end
    return string.format("1 in %.1f", oneIn)
end

Ext.ServerLuck = { value = 1, at = 0 }

function Ext.serverLuck()
    if os.clock() - Ext.ServerLuck.at < 30 then return Ext.ServerLuck.value end
    Ext.ServerLuck.at = os.clock()
    local ok, state = invokeRemote("ServerLuck:GetState")
    if ok and type(state) == "table" then
        Ext.ServerLuck.value = tonumber(state.Multiplier) or Ext.ServerLuck.value
    end
    return Ext.ServerLuck.value
end

Ext.AreaOrder = { list = {}, at = 0 }

function Ext.areaOrder(force)
    if not force and #Ext.AreaOrder.list > 0 and os.clock() - Ext.AreaOrder.at < 60 then
        return Ext.AreaOrder.list
    end

    local sums, counts = {}, {}
    for _, egg in pairs(getAreaEggs()) do
        local areaId = egg.AreaId and tostring(egg.AreaId)
        local bounds = egg.BoundsCFrame
        if areaId and typeof(bounds) == "CFrame" then
            sums[areaId]   = (sums[areaId] or 0) + bounds.Position.X
            counts[areaId] = (counts[areaId] or 0) + 1
        end
    end

    local ordered = {}
    for areaId, sum in pairs(sums) do
        ordered[#ordered + 1] = { id = areaId, x = sum / counts[areaId] }
    end
    table.sort(ordered, function(a, b) return a.x < b.x end)

    local list = {}
    for _, entry in ipairs(ordered) do list[#list + 1] = entry.id end

    if #list == 0 then
        for _, zone in ipairs(ZoneList) do list[#list + 1] = zone end
    end

    Ext.AreaOrder.list, Ext.AreaOrder.at = list, os.clock()
    return list
end

Ext.EggFinder = {
    rows      = {},
    updatedAt = 0,
    scanned   = 0,
}

function Ext.refreshEggFinder()
    local root  = getRoot()
    local minR  = Flags.FinderMinRarity
    local zones = listToSet(Flags.FinderZones)
    local rows  = {}
    local total = 0

    for _, egg in pairs(getAreaEggs()) do
        total = total + 1
        local category = egg.AssetCategory
        local info     = category and AssetInfo[category]
        local areaId   = tostring(egg.AreaId or "?")
        local passes   = info ~= nil

        if passes and minR and minR ~= "" and rarityNum(info.rarity) < rarityNum(minR) then
            passes = false
        end
        if passes and zones and not zones[areaId] then passes = false end

        if passes then
            local bounds = typeof(egg.BoundsCFrame) == "CFrame" and egg.BoundsCFrame.Position or nil
            local pct, oneIn = Ext.eggOdds(areaId, category)
            rows[#rows + 1] = {
                cat     = category,
                display = info.display,
                rarity  = info.rarity,
                rarNum  = info.rarityNum,
                area    = areaId,
                pos     = bounds,
                dist    = (bounds and root) and (bounds - root.Position).Magnitude or nil,
                muts    = table.concat(getEggMutations(egg), " + "),
                weight  = getEggWeight(egg),
                pct     = pct,
                oneIn   = oneIn,
                uid     = egg.Uid,
                state   = tostring(egg.State or "?"),
            }
        end
    end

    table.sort(rows, function(a, b)
        if a.rarNum ~= b.rarNum then return a.rarNum > b.rarNum end
        local ao, bo = a.oneIn or 0, b.oneIn or 0
        if ao ~= bo then return ao > bo end
        return (a.dist or math.huge) < (b.dist or math.huge)
    end)

    Ext.EggFinder.rows      = rows
    Ext.EggFinder.updatedAt = os.clock()
    Ext.EggFinder.scanned   = total
    return rows
end

function Ext.eggFinderText(limit)
    local rows = Ext.EggFinder.rows
    if Ext.EggFinder.updatedAt == 0 then return "Egg Finder is off." end
    if #rows == 0 then
        return string.format("No eggs match (%d on the field).", Ext.EggFinder.scanned)
    end

    local lines = {
        string.format("%d of %d eggs match  |  luck x%.2f",
            #rows, Ext.EggFinder.scanned, Ext.serverLuck()),
    }
    for index, row in ipairs(rows) do
        if index > (limit or 8) then break end
        lines[#lines + 1] = string.format(
            "%d. %s [%s]\n    %s  %s  %.0fkg%s%s",
            index,
            row.cat,
            row.rarity,
            row.area,
            row.dist and string.format("%.0f studs", row.dist) or "distance ?",
            row.weight,
            row.pct and string.format("  %.2f%% (%s)", row.pct, Ext.formatOneIn(row.oneIn)) or "",
            row.muts ~= "" and ("  " .. row.muts) or "")
    end
    return table.concat(lines, "\n")
end

Ext.CarryWatch = { byUser = {}, at = 0, mineUntil = 0, mine = nil, mineUid = nil }

function Ext.refreshCarryWatch()
    if os.clock() - Ext.CarryWatch.at < 0.75 then return Ext.CarryWatch.byUser end
    Ext.CarryWatch.at = os.clock()

    local loose = {}
    for _, egg in pairs(getAreaEggs()) do
        if egg.State ~= "Slot" and typeof(egg.BoundsCFrame) == "CFrame" then
            loose[#loose + 1] = { pos = egg.BoundsCFrame.Position, egg = egg }
        end
    end

    local carriers = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        local char = plr.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root then
            for _, entry in ipairs(loose) do
                if (entry.pos - root.Position).Magnitude <= 12 then
                    carriers[plr.UserId] = {
                        player = plr,
                        root   = root,
                        egg    = entry.egg,
                        cat    = entry.egg.AssetCategory,
                    }
                    break
                end
            end
        end
    end

    Ext.CarryWatch.byUser = carriers
    if carriers[LocalPlayer.UserId] then
        Ext.CarryWatch.mineUntil = os.clock() + 3
    end
    return carriers
end

do
    local carryState = Network:FindFirstChild("Eggs: AreaEggCarryState")
    if carryState and carryState:IsA("RemoteEvent") then
        trackConn(carryState.OnClientEvent:Connect(function(state)
            if type(state) ~= "table" then return end
            Ext.CarryWatch.mine    = state.IsCarrying == true
            Ext.CarryWatch.mineUid = state.Uid
        end))
    end
end

function Ext.amCarryingEgg()
    if Ext.CarryWatch.mine ~= nil then return Ext.CarryWatch.mine end
    if os.clock() < Ext.CarryWatch.mineUntil then return true end
    Ext.refreshCarryWatch()
    return Ext.CarryWatch.byUser[LocalPlayer.UserId] ~= nil
end

Ext.BatAura = {
    lastSwing = 0,
    swings    = 0,
    status    = "Idle",
    bat       = nil,
}

function Ext.batTier(gearName)
    local gear = Ext.GearDirectory[gearName]
    return tonumber(gear and gear.IndexBatTier) or 0
end

function Ext.ownedBatNames()
    local owned = {}
    if Ext.ClientSave and type(Ext.ClientSave.GetUnsafe) == "function" then
        local ok, save = pcall(Ext.ClientSave.GetUnsafe)
        if ok and type(save) == "table" and type(save.GearInventory) == "table" then
            for gearName, count in pairs(save.GearInventory) do
                if (tonumber(count) or 0) > 0 and Ext.batTier(gearName) > 0 then
                    owned[tostring(gearName)] = true
                end
            end
        end
    end
    for _, container in ipairs({ getCharacter(), LocalPlayer:FindFirstChild("Backpack") }) do
        if container then
            for _, item in ipairs(container:GetChildren()) do
                if item:IsA("Tool") and item:GetAttribute("IsBat") then
                    owned[tostring(item:GetAttribute("GearName") or item.Name)] = true
                end
            end
        end
    end
    return owned
end

function Ext.bestOwnedBat()
    local best, bestTier = nil, -1
    for gearName in pairs(Ext.ownedBatNames()) do
        local tier = Ext.batTier(gearName)
        if tier > bestTier then best, bestTier = gearName, tier end
    end
    return best, bestTier
end

function Ext.areaForBat(gearName)
    for areaId, entry in pairs(Ext.AreaDirectory) do
        if type(entry) == "table" and tostring(entry.IndexBatGearId) == tostring(gearName) then
            return tostring(areaId)
        end
    end
    return nil
end

function Ext.findBatTool(gearName)
    for _, container in ipairs({ getCharacter(), LocalPlayer:FindFirstChild("Backpack") }) do
        if container then
            for _, item in ipairs(container:GetChildren()) do
                if item:IsA("Tool") and item:GetAttribute("IsBat") then
                    if (not gearName) or tostring(item:GetAttribute("GearName")) == tostring(gearName) then
                        return item
                    end
                end
            end
        end
    end
    return nil
end

function Ext.equipBestBat()
    if Ext.amCarryingEgg() then
        Ext.BatAura.status = "Holding an egg - not swapping tools"
        return nil
    end

    local char, hum = getCharacter(), getHumanoid()
    if not (char and hum) then return nil end

    local wanted = Ext.bestOwnedBat()
    local tool   = Ext.findBatTool(wanted)

    if not tool and wanted then
        local areaId = Ext.areaForBat(wanted)
        if areaId then
            invokeRemote("Index: RequestEquipAreaBat", areaId)
            task.wait(0.35)
            tool = Ext.findBatTool(wanted)
        end
    end

    tool = tool or Ext.findBatTool(nil)
    if not tool then
        Ext.BatAura.status = "No bat owned"
        return nil
    end

    if tool.Parent ~= char then
        pcall(function() hum:EquipTool(tool) end)
        task.wait(0.15)
        tool = Ext.findBatTool(tostring(tool:GetAttribute("GearName"))) or tool
    end

    Ext.BatAura.bat = tool
    return (tool.Parent == char) and tool or nil
end

function Ext.batOnCooldown(tool)
    if not tool then return true end
    if tool:GetAttribute("CooldownActive") == true then return true end

    local endsAt = tonumber(tool:GetAttribute("CooldownEndTime")) or 0
    if endsAt > 0 then
        local okNow, now = pcall(function() return Workspace:GetServerTimeNow() end)
        if okNow and now < endsAt then return true end
    end

    local minGap = math.max(tonumber(Flags.BatMinInterval) or 0.6, 0.6)
    return (os.clock() - Ext.BatAura.lastSwing) < minGap
end

function Ext.batTargetEligible(player)
    local char = player and player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if not (char and root and hum and hum.Health > 0) then return false end

    if Ext.Ragdoll and type(Ext.Ragdoll.IsRagdolled) == "function" then
        local ok, ragdolled = pcall(Ext.Ragdoll.IsRagdolled, char)
        if ok and ragdolled then return false end
    end

    if Ext.ToolGuard and type(Ext.ToolGuard.IsPlayerInGameplayArea) == "function" then
        local ok, inArea = pcall(Ext.ToolGuard.IsPlayerInGameplayArea, player)
        if ok and not inArea then return false end
    end

    return true
end

function Ext.batTargets()
    local root = getRoot()
    if not root then return {} end

    local bat       = Ext.BatAura.bat
    local gearName  = bat and tostring(bat:GetAttribute("GearName")) or Ext.bestOwnedBat()
    local range     = Ext.batServerRange(gearName)
    local carriers  = Ext.refreshCarryWatch()
    local plotRange = tonumber(Flags.BatPlotRadius) or 0
    local center    = plotRange > 0 and getPlotCenter() or nil

    local found = {}
    for userId, entry in pairs(carriers) do
        if userId ~= LocalPlayer.UserId and entry.root and entry.root.Parent
            and Ext.batTargetEligible(entry.player) then
            local dist = (entry.root.Position - root.Position).Magnitude
            if dist <= range then
                local nearPlot = true
                if center then
                    nearPlot = (entry.root.Position - center).Magnitude <= plotRange
                end
                if nearPlot then
                    found[#found + 1] = {
                        player = entry.player,
                        dist   = dist,
                        cat    = entry.cat,
                        root   = entry.root,
                    }
                end
            end
        end
    end

    table.sort(found, function(a, b) return a.dist < b.dist end)
    return found
end

function Ext.swingBat(tool)
    local char = getCharacter()
    if not (tool and char and tool.Parent == char) then return false end

    if Ext.ToolGuard and type(Ext.ToolGuard.CanActivateLocal) == "function" then
        local okGuard, allowed = pcall(Ext.ToolGuard.CanActivateLocal, tool)
        if okGuard and not allowed then
            Ext.BatAura.status = "Outside the gameplay area"
            return false
        end
    end

    local ok = pcall(function() tool:Activate() end)
    if ok then
        Ext.BatAura.lastSwing = os.clock()
        Ext.BatAura.swings    = Ext.BatAura.swings + 1
    end
    return ok
end

function Ext.batAuraText()
    local bat      = Ext.BatAura.bat
    local gearName = bat and tostring(bat:GetAttribute("GearName")) or Ext.bestOwnedBat()
    return string.format("Bat Aura: %s\nSwings %d   Reach %.1f studs%s",
        Ext.BatAura.status, Ext.BatAura.swings, Ext.batServerRange(gearName),
        gearName and ("\nBat: " .. gearName .. " (tier " .. Ext.batTier(gearName) .. ")") or "")
end

Ext.SakuraStatus = { text = "Idle", trees = 0, crystals = 0, hits = 0, collected = 0 }

function Ext.serverNow()
    local ok, now = pcall(function() return Workspace:GetServerTimeNow() end)
    if ok and now then return now end
    return os.time()
end

function Ext.bloomEndsAt()
    local holders = { Workspace, ReplicatedStorage, Lighting }
    local crystalFolder = Workspace:FindFirstChild("SakuraCrystals")
    if crystalFolder then table.insert(holders, crystalFolder) end
    for _, holder in ipairs(holders) do
        local ok, value = pcall(function() return holder:GetAttribute(Ext.Sakura.EndsAtAttr) end)
        if ok and tonumber(value) then return tonumber(value) end
        for _, child in ipairs(holder:GetChildren()) do
            local okChild, childValue = pcall(function() return child:GetAttribute(Ext.Sakura.EndsAtAttr) end)
            if okChild and tonumber(childValue) then return tonumber(childValue) end
        end
    end
    return nil
end

function Ext.taggedInWorkspace(tag)
    local out = {}
    for _, inst in ipairs(CollectionService:GetTagged(tag)) do
        if inst:IsDescendantOf(Workspace) then out[#out + 1] = inst end
    end
    return out
end

function Ext.bloomActive()
    local trees = Ext.taggedInWorkspace(Ext.Sakura.TreeTag)
    if #trees > 0 then return true, #trees end
    local endsAt = Ext.bloomEndsAt()
    if endsAt and endsAt > 0 then return Ext.serverNow() < endsAt, 0 end
    return false, 0
end

function Ext.bloomSecondsLeft()
    local endsAt = Ext.bloomEndsAt()
    if not (endsAt and endsAt > 0) then return nil end
    return math.max(0, endsAt - Ext.serverNow())
end

function Ext.sortedByDistance(instances)
    local root = getRoot()
    local out = {}
    for _, inst in ipairs(instances) do
        local part = resolvePart(inst)
        if part then
            out[#out + 1] = {
                inst = inst,
                part = part,
                dist = root and (part.Position - root.Position).Magnitude or math.huge,
            }
        end
    end
    table.sort(out, function(a, b) return a.dist < b.dist end)
    return out
end

function Ext.crystalReach()
    return Ext.Sakura.PickupRange
end

function Ext.treeReach(tree)
    local radius = tonumber(tree and tree:GetAttribute("Radius")) or 0
    return radius + Ext.Sakura.HitRange
end

function Ext.collectCrystals(budgetSeconds)
    local deadline  = os.clock() + (budgetSeconds or 6)
    local collected = 0

    for _, entry in ipairs(Ext.sortedByDistance(Ext.taggedInWorkspace(Ext.Sakura.CrystalTag))) do
        if os.clock() > deadline then break end
        if not (Running["SakuraFarm"] or Running["SakuraCollect"]) then break end

        if entry.part.Parent then
            local root = getRoot()
            if root and (entry.part.Position - root.Position).Magnitude > Ext.crystalReach() * 0.6 then
                Move:To(entry.part.Position + Vector3.new(0, 3, 0), 8)
            end

            if Flags.SakuraDirectCollect then
                invokeRemote("Sakura: CollectCrystal", entry.inst)
            end

            local waited = 0
            while entry.part.Parent and waited < 0.8 do
                waited = waited + task.wait(0.1)
            end
            if not entry.part.Parent then
                collected = collected + 1
                Ext.SakuraStatus.collected = Ext.SakuraStatus.collected + 1
            end
        end
    end

    return collected
end

function Ext.farmBloomTrees()
    local active = Ext.bloomActive()
    if not active then
        local left = Ext.bloomSecondsLeft()
        Ext.SakuraStatus.text = (left and left > 0)
            and string.format("%s ends in %ds", Ext.Sakura.EventName, left)
            or (Ext.Sakura.EventName .. " is not running")
        return false
    end

    if not Ext.incubatorUnlocked() then
        Ext.SakuraStatus.text = "Incubator locked - trees cannot be hit yet"
        return false
    end

    local bat = Ext.equipBestBat()
    if not bat then
        Ext.SakuraStatus.text = "Need a bat equipped to hit trees"
        return false
    end

    local trees = Ext.sortedByDistance(Ext.taggedInWorkspace(Ext.Sakura.TreeTag))
    Ext.SakuraStatus.trees = #trees
    if #trees == 0 then
        Ext.SakuraStatus.text = "Waiting for trees to spawn"
        return false
    end

    local target = trees[1]
    local root   = getRoot()
    if not root then return false end

    local reach = Ext.treeReach(target.inst)
    local function horizontal()
        local here = getRoot()
        if not here then return math.huge end
        local delta = target.part.Position - here.Position
        return Vector3.new(delta.X, 0, delta.Z).Magnitude
    end

    if horizontal() > reach * 0.7 then
        Ext.SakuraStatus.text = "Travelling to tree"
        Move:To(target.part.Position + Vector3.new(0, 3, 0), 12)
    end

    Ext.SakuraStatus.text = string.format("Working a %s tree (%s/%s hits), %d up",
        tostring(target.inst:GetAttribute("Size") or "?"),
        tostring(target.inst:GetAttribute("Hits") or "?"),
        tostring(target.inst:GetAttribute("HitsRequired") or "?"),
        #trees)

    local held = 0
    while target.part.Parent and Running["SakuraFarm"] and held < 30 do
        if getCharacter() and bat.Parent ~= getCharacter() then
            bat = Ext.equipBestBat()
            if not bat then break end
        end
        if horizontal() > reach * 0.85 then
            Move:To(target.part.Position + Vector3.new(0, 3, 0), 8)
        end
        if Flags.SakuraDirectHit then
            fireRemote("Sakura: HitTree", target.inst)
        end
        Ext.SakuraStatus.hits = Ext.SakuraStatus.hits + 1
        held = held + task.wait(0.25)
    end

    Ext.SakuraStatus.crystals = #Ext.taggedInWorkspace(Ext.Sakura.CrystalTag)
    Ext.collectCrystals(6)
    return true
end

function Ext.saveData()
    if not (Ext.ClientSave and type(Ext.ClientSave.GetUnsafe) == "function") then return nil end
    local ok, save = pcall(Ext.ClientSave.GetUnsafe)
    if ok and type(save) == "table" then return save end
    return nil
end

function Ext.sakuraState()
    local save = Ext.saveData()
    return type(save) == "table" and type(save.Sakura) == "table" and save.Sakura or nil
end

function Ext.sakuraCrystals()
    if Ext.CurrencyCmds and type(Ext.CurrencyCmds.Get) == "function" then
        local ok, amount = pcall(Ext.CurrencyCmds.Get, Ext.Sakura.CurrencyId)
        if ok and tonumber(amount) then return tonumber(amount) end
    end
    local save = Ext.saveData()
    return tonumber(save and save[Ext.Sakura.CurrencyId]) or 0
end

function Ext.incubatorUnlocked()
    if Ext.BloomPolicy and type(Ext.BloomPolicy.IsUnlocked) == "function"
        and Ext.ClientSave and type(Ext.ClientSave.Get) == "function" then
        local okLoaded, loaded = pcall(Ext.ClientSave.IsLocalDataLoaded)
        local okSave, save     = pcall(Ext.ClientSave.Get)
        if okLoaded and okSave then
            local ok, unlocked = pcall(Ext.BloomPolicy.IsUnlocked, loaded, save)
            if ok then return unlocked == true end
        end
    end

    local state = Ext.sakuraState()
    if type(state) == "table" and state.Unlocked ~= nil then
        return state.Unlocked == true
    end

    return Workspace:FindFirstChild("IncubatorDead") == nil
end

function Ext.ownedCraneUid()
    local save = Ext.saveData()
    if type(save) ~= "table" then return nil end

    if type(save.Inventory) == "table" then
        for uid, item in pairs(save.Inventory) do
            if type(item) == "table" and tostring(item.Category) == Ext.Sakura.CraneAssetId then
                return tostring(uid), "pet"
            end
        end
    end
    if type(save.EggInventory) == "table" then
        for uid, item in pairs(save.EggInventory) do
            if type(item) == "table" and tostring(item.AssetCategory) == Ext.Sakura.CraneAssetId then
                return tostring(uid), "egg"
            end
        end
    end
    return nil
end

function Ext.dormantTreePosition()
    local dead = Workspace:FindFirstChild("IncubatorDead")
    local part = dead and resolvePart(dead)
    if part then return part.Position end

    local objs   = Workspace:FindFirstChild("__OBJECTS")
    local areas  = objs and objs:FindFirstChild("Areas")
    local cherry = areas and areas:FindFirstChild("CherryBlossom")
    local anchor = cherry and cherry:FindFirstChild("IncubatorAnchor")
    return anchor and anchor.Position or nil
end

function Ext.unlockSakuraIncubator(travel)
    if Ext.incubatorUnlocked() then
        return false, "Incubator is already unlocked"
    end

    local uid, source = Ext.ownedCraneUid()
    if not uid then
        return false, "No " .. Ext.Sakura.CraneAssetId .. " owned - nothing sent"
    end

    if travel ~= false then
        local pos = Ext.dormantTreePosition()
        if pos then Move:To(pos + Vector3.new(0, 4, 0), 20) end
    end

    if source == "egg" then
        invokeRemote("Eggs: RequestHatchEgg", uid)
        task.wait(0.2)
        invokeRemote("Eggs: RequestCompleteHatchEgg", uid)
        task.wait(0.4)
        uid = Ext.ownedCraneUid() or uid
    end

    local ok, res = invokeRemote("Sakura: ReturnCrane")

    if ok and res ~= false and res ~= nil then
        return true, "Incubator unlocked"
    end
    return false, "Server refused the unlock"
end

function Ext.runIncubator()
    if not Ext.incubatorUnlocked() then return false, "Incubator locked" end

    local state = Ext.sakuraState() or {}
    local notes = {}

    if state.Egg == false or state.Egg == nil then
        local eggs = getMyEggs()
        local bestUid, bestScore
        for uid, egg in pairs(eggs) do
            local score = eggScore(egg)
            if not bestScore or score > bestScore then bestUid, bestScore = uid, score end
        end
        if bestUid then
            local ok, res = invokeRemote("Sakura: InsertEgg", bestUid)
            if ok and res ~= false and res ~= nil then
                notes[#notes + 1] = "egg inserted"
            end
        end
    end

    local crystals = Ext.sakuraCrystals()
    if crystals > 0 then
        local ok, res = invokeRemote("Sakura: Deposit", crystals)
        if not (ok and res ~= false and res ~= nil) then
            ok, res = invokeRemote("Sakura: Deposit")
        end
        if ok and res ~= false and res ~= nil then
            notes[#notes + 1] = string.format("deposited %d", crystals)
        end
    end

    if Flags.SakuraAutoMutate then
        local ok, res = invokeRemote("Sakura: Mutate")
        if ok and res ~= false and res ~= nil then
            notes[#notes + 1] = "mutated"
        end
    end

    return #notes > 0, #notes > 0 and table.concat(notes, ", ") or "nothing to do"
end

Ext.GlobalFarm = {
    index      = 1,
    enteredAt  = 0,
    savedZones = nil,
    status     = "Idle",
    area       = nil,
}

function Ext.setZoneSelection(zones)
    Flags.StealZones = zones
    pcall(function()
        local dropdown = Library.Options and Library.Options.StealZones
        if dropdown and dropdown.SetValue then dropdown:SetValue(zones) end
    end)
end

function Ext.globalFarmAreas()
    local order = Ext.areaOrder()
    local stop  = Flags.GlobalFarmLastArea
    if not stop or stop == "" then return order end

    local out = {}
    for _, areaId in ipairs(order) do
        out[#out + 1] = areaId
        if areaId == stop then break end
    end
    return #out > 0 and out or order
end

function Ext.areaHasTargets(areaId)
    for _, egg in pairs(getAreaEggs()) do
        if tostring(egg.AreaId) == tostring(areaId) and eggPassesFilters(egg) then
            return true
        end
    end
    return false
end

function Ext.advanceGlobalFarm()
    local areas = Ext.globalFarmAreas()
    if #areas == 0 then
        Ext.GlobalFarm.status = "No areas detected"
        return
    end

    Ext.GlobalFarm.index = (Ext.GlobalFarm.index % #areas) + 1
    local areaId = areas[Ext.GlobalFarm.index]
    Ext.GlobalFarm.area      = areaId
    Ext.GlobalFarm.enteredAt = os.clock()
    Ext.setZoneSelection({ areaId })
    Ext.GlobalFarm.status = string.format("Farming %s (%d/%d)", areaId, Ext.GlobalFarm.index, #areas)
end

Ext.Travel = { lastCalibration = nil }

function Ext.realSpeedPower()
    local save = Ext.saveData()
    local power = tonumber(save and save.SpeedPower)
    if power and power > 0 then return power end
    return getSpeedStat()
end

function Ext.speedModifier()
    if not (Ext.SpeedUtil and type(Ext.SpeedUtil.GetSpeedModifierFromPower) == "function") then
        return nil
    end
    local ok, modifier = pcall(Ext.SpeedUtil.GetSpeedModifierFromPower, Ext.realSpeedPower())
    return ok and tonumber(modifier) or nil
end

function Ext.movementLimit()
    local hum  = getHumanoid()
    local walk = hum and tonumber(hum.WalkSpeed) or 0

    if walk > 16 then
        Ext.Travel.lastWalk = walk
        return walk, "live walk speed"
    end

    if Ext.Travel.lastWalk then return Ext.Travel.lastWalk, "last known" end

    return math.max(walk, tonumber(Ext.Constants.BASE_WALK_SPEED) or 16), "base speed"
end

function Ext.calibrateFastTravel(apply)
    local limit, source = Ext.movementLimit()
    local margin = tonumber(Flags.TravelMargin)
    if not margin then
        margin = tonumber(Ext.Constants.CLIENT_OVERLAP_MARGIN) or 0.95
    end

    local speed = limit * margin
    if Move.rollbacks and Move.rollbacks > 0 then
        speed = speed * math.max(0.6, 1 - 0.1 * Move.rollbacks)
    end
    speed = math.clamp(math.floor(speed), 60, 2000)

    if apply then
        Flags.TweenSpeed = speed
        Move.speed = speed
        Move.rollbacks = 0
        pcall(function()
            local slider = Library.Options and Library.Options.TweenSpeed
            if slider and slider.SetValue then slider:SetValue(speed) end
        end)
    end

    local modifier = Ext.speedModifier()
    Ext.Travel.lastCalibration = string.format(
        "Speed Power %s%s\nMovement limit %.0f (%s)\nTravel speed %d  (margin %.2f)",
        Ext.shortNumber(Ext.realSpeedPower()),
        modifier and string.format("  (x%s from the speed curve)", Ext.shortNumber(modifier)) or "",
        limit, source, speed, margin)
    return speed, limit
end

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
    ToggleKeybind = TemplateConfig.Interface.ToggleKeybind,
    Center        = true,
    AutoShow      = true,
    CornerRadius  = TemplateConfig.Interface.CornerRadius,
})

local Tabs = {
    Home       = Window:AddTab("Home", nil, "Account, game, and script information."),
    Farm       = Window:AddTab("Farm", nil, "Egg stealing and filters."),
    Automation = Window:AddTab("Automation", nil, "Eggs, pets, progression, and inventory."),
    Intel      = Window:AddTab("Intel", nil, "ESP, server intel, and webhook."),
    Sakura     = Window:AddTab("Sakura", nil, "Great Bloom, crystals, and the Sakura incubator."),
    System     = Window:AddTab("System", nil, "Player, server, performance, and configs."),
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

    local Credits = Tabs.Home:AddLeftGroupbox("Credits")
    Credits:AddLabel("Credits To Lumin Developers:\nThanks for supporting Lumin Hub :p")
    Credits:AddCopyLabel("CopyDiscord", {
        Text    = "discord.gg/luminhub",
        Value   = "https://discord.gg/luminhub",
        Tooltip = "Click to copy",
        Color   = Color3.fromRGB(200, 0, 120),
        Size    = 14,
    })

    local GameBox = Tabs.Home:AddLeftGroupbox("Game")
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

    local VersionBox = Tabs.Home:AddRightGroupbox("Version")
    VersionBox:AddLabel("Script Version: " .. tostring(LRM_ScriptVersion or "v2.0"))

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

    local Support = Tabs.Home:AddRightGroupbox("Games Supported")
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

local TBL, TBR
local StealGB = Tabs.Farm:AddLeftGroupbox("Auto Farm")
local FilterGB = Tabs.Farm:AddRightGroupbox("Filters")

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

StealGB:AddDropdown("MoveMode", {
    Text    = "Travel Mode",
    Tooltip = "Tween glides the root at distance/speed, locked to your current height; the anti-cheat frame loops are disabled so it sticks. Instant snaps.",
    Values  = { "Tween", "Instant" },
    Default = "Tween",
    Callback = function(v)
        Flags.MoveMode = v
        Flags.InstantMove = (v == "Instant")
    end,
})

StealGB:AddSlider("TweenSpeed", {
    Text     = "Tween Speed",
    Suffix   = " studs/s",
    Tooltip  = "Studs per second for Tween mode. 200 measured clean with the frame loops disabled.",
    Min      = 50,
    Max      = 900,
    Default  = 300,
    Rounding = 0,
    Callback = function(v) Flags.TweenSpeed = v end,
})

StealGB:AddInput("TweenSpeedInput", {
    Text        = "Set Tween Speed",
    Placeholder = "studs/s (50-900)",
    Numeric     = true,
    Finished    = true,
    Callback = function(v)
        local n = tonumber(v)
        if not n then return end
        n = math.clamp(math.floor(n), 50, 900)
        Flags.TweenSpeed = n
        Options.TweenSpeed:SetValue(n)
    end,
})

StealGB:AddToggle("AdaptiveSpeed", {
    Text    = "Adaptive Speed",
    Tooltip = "Backs the speed off if the server ever refuses the movement. Off by default: with velocity zeroing it is not needed.",
    Default = false,
    Callback = function(v) Flags.AdaptiveSpeed = v end,
})

StealGB:AddToggle("DistantTarget", {
    Text    = "Distant Egg Target",
    Tooltip = "With Priority off, targets the furthest matching egg instead of the nearest.",
    Default = false,
    Callback = function(v) Flags.DistantTarget = v end,
})

StealGB:AddSlider("FarmDelay", {
    Text = "Farm Delay", Suffix = "s",
    Min = 0, Max = 5, Default = 0, Rounding = 2,
    Callback = function(v) Flags.FarmDelay = v end,
})

StealGB:AddButton("Force Resume", function()
    InventoryFull, InventoryFullCount = false, 0
    PlaceCooldown, GlobalCarryCooldown = 0, 0
    table.clear(CarryFails)
    table.clear(CarryCooldowns)
    showToast("Lumin Hub", "Farm state reset")
end)

local StealStatus = StealGB:AddLabel("Last Steal: Idle", true)

local SniperGB = Tabs.Farm:AddRightGroupbox("Spawn Sniper")

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

local ActionsGB = Tabs.Farm:AddRightGroupbox("Actions")

ActionsGB:AddButton("Teleport to Base", function()
    local c = getPlotCenter()
    if c then Move:To(c) end
    showToast("Lumin Hub", "Teleported to base")
end):AddButton("Drop Held Egg", function()
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

do

local GlobalGB = Tabs.Farm:AddLeftGroupbox("Global Auto Farm")

GlobalGB:AddDropdown("GlobalFarmLastArea", {
    Text      = "Farm Up To",
    Tooltip   = "Walks the areas in map order and stops after this one.",
    Values    = ZoneList,
    Default   = nil,
    AllowNull = true,
    Callback  = function(v) Flags.GlobalFarmLastArea = v end,
})

GlobalGB:AddSlider("GlobalAreaSeconds", {
    Text     = "Seconds Per Area",
    Tooltip  = "Moves on early when an area runs out of matching eggs.",
    Min      = 10,
    Max      = 240,
    Default  = 45,
    Rounding = 0,
    Callback = function(v) Flags.GlobalAreaSeconds = v end,
})

GlobalGB:AddToggle("GlobalFarmSkipGuards", {
    Text    = "Skip Guarded Areas",
    Tooltip = "Rotates past any area whose guard is awake instead of waiting.",
    Default = true,
    Callback = function(v) Flags.GlobalFarmSkipGuards = v end,
})

GlobalGB:AddToggle("GlobalAutoFarm", {
    Text    = "Global Auto Farm",
    Tooltip = "Farms every area from Forest to Cherry Blossom. The order is read"
        .. " from the live map, so areas added by an update are picked up on their own.",
    Default = false,
    Callback = function(val)
        Flags.GlobalAutoFarm = val

        if not val then
            stopLoop("GlobalFarm")
            if Ext.GlobalFarm.savedZones then
                Ext.setZoneSelection(Ext.GlobalFarm.savedZones)
                Ext.GlobalFarm.savedZones = nil
            end
            Ext.GlobalFarm.status = "Idle"
            Ext.GlobalFarm.area   = nil
            return
        end

        Ext.GlobalFarm.savedZones = Flags.StealZones
        Ext.GlobalFarm.index      = 0
        Ext.advanceGlobalFarm()

        pcall(function()
            if Toggles.AutoSteal and not Toggles.AutoSteal.Value then
                Toggles.AutoSteal:SetValue(true)
            end
        end)

        startLoop("GlobalFarm", function()
            local areas = Ext.globalFarmAreas()
            if #areas == 0 then
                Ext.GlobalFarm.status = "No areas detected yet"
                task.wait(3)
                return
            end

            local areaId = Ext.GlobalFarm.area
            local dwell  = tonumber(Flags.GlobalAreaSeconds) or 45
            local held   = os.clock() - Ext.GlobalFarm.enteredAt

            local guarded = false
            if Flags.GlobalFarmSkipGuards ~= false and areaId then
                guarded = isGuardAwake({ areaId })
            end

            if (not areaId) or guarded or held >= dwell or not Ext.areaHasTargets(areaId) then
                Ext.advanceGlobalFarm()
            else
                Ext.GlobalFarm.status = string.format("Farming %s (%d/%d)  %ds left",
                    areaId, Ext.GlobalFarm.index, #areas, math.max(0, math.floor(dwell - held)))
            end

            task.wait(2)
        end)
    end,
})

local globalLabel = GlobalGB:AddLabel("Rotation: idle", true)

local TravelGB = Tabs.Farm:AddLeftGroupbox("Fast Travel")

TravelGB:AddSlider("TravelMargin", {
    Text     = "Safety Margin",
    Tooltip  = "Fraction of the movement limit to travel at. The game's own"
        .. " client margin is 0.95.",
    Min      = 0.5,
    Max      = 1,
    Default  = tonumber(Ext.Constants.CLIENT_OVERLAP_MARGIN) or 0.95,
    Rounding = 2,
    Callback = function(v) Flags.TravelMargin = v end,
})

local travelLabel = TravelGB:AddLabel("Not calibrated yet", true)

TravelGB:AddButton("Calibrate Fast Travel", function()
    local speed = Ext.calibrateFastTravel(true)
    travelLabel:SetText(Ext.Travel.lastCalibration or "Calibrated")
    showToast("Lumin Hub", string.format("Travel speed set to %d", speed))
end)

TravelGB:AddToggle("AutoCalibrateTravel", {
    Text    = "Keep Recalibrating",
    Tooltip = "Rechecks after rebirths, speed upgrades and rollbacks.",
    Default = false,
    Callback = function(val)
        Flags.AutoCalibrateTravel = val
        if not val then stopLoop("TravelCalibrate") return end
        startLoop("TravelCalibrate", function()
            Ext.calibrateFastTravel(true)
            pcall(function() travelLabel:SetText(Ext.Travel.lastCalibration or "") end)
            task.wait(20)
        end)
    end,
})

local BatGB = Tabs.Farm:AddRightGroupbox("Bat Aura")

BatGB:AddSlider("BatPlotRadius", {
    Text     = "Plot Radius",
    Tooltip  = "Only swings at carriers this close to your base. 0 means anywhere.",
    Min      = 0,
    Max      = 400,
    Default  = 150,
    Rounding = 0,
    Callback = function(v) Flags.BatPlotRadius = v end,
})

BatGB:AddSlider("BatMinInterval", {
    Text     = "Minimum Swing Gap",
    Tooltip  = "The bat controller debounces its own swings at 0.6s and drops"
        .. " anything faster, so this cannot usefully go lower.",
    Min      = 0.6,
    Max      = 3,
    Default  = 0.6,
    Rounding = 2,
    Callback = function(v) Flags.BatMinInterval = v end,
})

BatGB:AddToggle("BatAura", {
    Text    = "Bat Aura",
    Tooltip = "Equips your highest tier bat and swings at players carrying eggs"
        .. " inside the server's real hit range. It never swaps tools while you"
        .. " are holding an egg.",
    Default = false,
    Callback = function(val)
        Flags.BatAura = val
        if not val then
            stopLoop("BatAura")
            Ext.BatAura.status = "Idle"
            return
        end

        startLoop("BatAura", function()
            if Ext.amCarryingEgg() then
                Ext.BatAura.status = "Carrying an egg - holding fire"
                task.wait(0.5)
                return
            end

            local targets = Ext.batTargets()
            if #targets == 0 then
                Ext.BatAura.status = "No carriers in range"
                task.wait(0.4)
                return
            end

            local bat = (Ext.BatAura.bat and Ext.BatAura.bat.Parent == getCharacter())
                and Ext.BatAura.bat or Ext.equipBestBat()
            if not bat then
                task.wait(1)
                return
            end

            if Ext.batOnCooldown(bat) then
                Ext.BatAura.status = "Cooling down"
                task.wait(0.15)
                return
            end

            local target = targets[1]
            Ext.BatAura.status = string.format("Swinging at %s (%.0f studs)",
                target.player.Name, target.dist)
            Ext.swingBat(bat)
            task.wait(0.1)
        end)
    end,
})

BatGB:AddButton("Equip Best Bat", function()
    local bat = Ext.equipBestBat()
    showToast("Lumin Hub", bat
        and ("Equipped " .. tostring(bat:GetAttribute("GearName") or bat.Name))
        or Ext.BatAura.status)
end)

local batLabel = BatGB:AddLabel("Bat Aura: idle", true)

local FinderGB = Tabs.Intel:AddLeftGroupbox("Egg Finder")

FinderGB:AddDropdown("FinderMinRarity", {
    Text      = "Minimum Rarity",
    Values    = RarityOrder,
    Default   = nil,
    AllowNull = true,
    Callback  = function(v) Flags.FinderMinRarity = v end,
})

FinderGB:AddDropdown("FinderZones", {
    Text      = "Areas",
    Tooltip   = "Leave empty to look everywhere.",
    Values    = ZoneList,
    Multi     = true,
    AllowNull = true,
    Callback  = function(v) Flags.FinderZones = v end,
})

FinderGB:AddSlider("FinderInterval", {
    Text     = "Refresh Seconds",
    Tooltip  = "The finder polls on a timer. Nothing runs per frame.",
    Min      = 1,
    Max      = 15,
    Default  = 3,
    Rounding = 0,
    Callback = function(v) Flags.FinderInterval = v end,
})

FinderGB:AddSlider("FinderRows", {
    Text     = "Rows Shown",
    Min      = 3,
    Max      = 20,
    Default  = 8,
    Rounding = 0,
    Callback = function(v) Flags.FinderRows = v end,
})

FinderGB:AddToggle("EggFinder", {
    Text    = "Egg Finder",
    Tooltip = "Lists the best eggs on the map with rarity, area, distance,"
        .. " mutations and the real drop odds.",
    Default = false,
    Callback = function(val)
        Flags.EggFinder = val
        if not val then
            stopLoop("EggFinder")
            Ext.EggFinder.rows, Ext.EggFinder.updatedAt = {}, 0
            return
        end
        startLoop("EggFinder", function()
            Ext.refreshEggFinder()
            task.wait(math.clamp(tonumber(Flags.FinderInterval) or 3, 1, 15))
        end)
    end,
})

local finderLabel = FinderGB:AddLabel("Egg Finder is off.", true)

FinderGB:AddButton("Travel To Best", function()
    if #Ext.EggFinder.rows == 0 then Ext.refreshEggFinder() end
    local best = Ext.EggFinder.rows[1]
    if not (best and best.pos) then
        showToast("Lumin Hub", "Nothing to travel to")
        return
    end
    showToast("Lumin Hub", "Travelling to " .. best.cat)
    task.spawn(function()
        Move:To(best.pos + Vector3.new(0, 3, 0))
    end)
end):AddButton("Copy Finder List", function()
    if setclipboard then pcall(setclipboard, Ext.eggFinderText(50)) end
    showToast("Lumin Hub", "Egg list copied")
end)

local BloomGB   = Tabs.Sakura:AddLeftGroupbox("Great Bloom")
local CherryGB  = Tabs.Sakura:AddLeftGroupbox("Cherry Blossom")
local IncubGB   = Tabs.Sakura:AddRightGroupbox("Sakura Incubator")
local SakuraInfoGB = Tabs.Sakura:AddRightGroupbox("Status")

BloomGB:AddLabel(string.format(
    "The game swings at bloom trees on its own every 0.15s while you hold a"
    .. " bat and the incubator is unlocked, so this just keeps you in reach."
    .. "\nTrees %s, crystals %s. Reach is the tree's Radius + %d studs, pickup"
    .. " %d. A bloom lasts %ds and returns every %d minutes.",
    Ext.Sakura.TreeTag, Ext.Sakura.CrystalTag, Ext.Sakura.HitRange,
    Ext.Sakura.PickupRange, Ext.Sakura.Duration, math.floor(Ext.Sakura.Interval / 60)), true)

BloomGB:AddToggle("SakuraFarm", {
    Text    = "Auto Farm Trees",
    Tooltip = "Keeps a bat equipped and parks you inside a tree's reach so the"
        .. " game's own swing loop works it, then sweeps the crystals. Only"
        .. " runs while a bloom is actually active.",
    Default = false,
    Callback = function(val)
        Flags.SakuraFarm = val
        if not val then
            stopLoop("SakuraFarm")
            Move:Stop()
            Ext.SakuraStatus.text = "Idle"
            return
        end
        startLoop("SakuraFarm", function()
            local worked = Ext.farmBloomTrees()
            task.wait(worked and 0.3 or 3)
        end)
    end,
})

BloomGB:AddToggle("SakuraCollect", {
    Text    = "Auto Collect Crystals",
    Tooltip = "Sweeps loose crystals without chopping anything.",
    Default = false,
    Callback = function(val)
        Flags.SakuraCollect = val
        if not val then
            stopLoop("SakuraCollect")
            return
        end
        startLoop("SakuraCollect", function()
            if #Ext.taggedInWorkspace(Ext.Sakura.CrystalTag) == 0 then
                task.wait(2)
                return
            end
            Ext.collectCrystals(8)
            task.wait(0.5)
        end)
    end,
})

BloomGB:AddToggle("SakuraDirectHit", {
    Text    = "Direct Tree Hits",
    Tooltip = "The Great Bloom client already auto-swings for you every 0.15s."
        .. " Turn this on to also send HitTree yourself.",
    Default = false,
    Callback = function(v) Flags.SakuraDirectHit = v end,
})

BloomGB:AddToggle("SakuraDirectCollect", {
    Text    = "Direct Crystal Pickup",
    Tooltip = "Also calls the collect remote instead of only walking into range.",
    Default = false,
    Callback = function(v) Flags.SakuraDirectCollect = v end,
})

CherryGB:AddButton("Teleport To Cherry Blossom", function()
    local areas = Ext.areaOrder(true)
    local last  = areas[#areas]
    local target
    for _, egg in pairs(getAreaEggs()) do
        if tostring(egg.AreaId) == Ext.Sakura.AreaId and typeof(egg.BoundsCFrame) == "CFrame" then
            target = egg.BoundsCFrame.Position
            break
        end
    end
    target = target or Ext.dormantTreePosition()
    if not target then
        showToast("Lumin Hub", "Cherry Blossom not found (last area: " .. tostring(last) .. ")")
        return
    end
    task.spawn(function()
        Move:To(target + Vector3.new(0, 4, 0))
    end)
    showToast("Lumin Hub", "Travelling to " .. Ext.Sakura.AreaId)
end)

CherryGB:AddToggle("CherryFarm", {
    Text    = "Farm Cherry Blossom Eggs",
    Tooltip = "Points the egg farm at Cherry Blossom only.",
    Default = false,
    Callback = function(val)
        Flags.CherryFarm = val
        if val then
            Ext.setZoneSelection({ Ext.Sakura.AreaId })
            pcall(function()
                if Toggles.AutoSteal and not Toggles.AutoSteal.Value then
                    Toggles.AutoSteal:SetValue(true)
                end
            end)
        end
    end,
})

CherryGB:AddButton("Place All Eggs", function()
    local placed = placeHeldEggs(nil)
    showToast("Lumin Hub", string.format("Placed %d egg%s", placed, placed == 1 and "" or "s"))
end):AddButton("Hatch All Eggs", function()
    task.spawn(function()
        local hatched = 0
        for uid in pairs(getMyEggs()) do
            if not remoteSucceeded("Eggs: RequestHatchEgg", uid) then
                invokeRemote("Eggs: RequestSkipGrowth", uid)
                task.wait(0.15)
                invokeRemote("Eggs: RequestHatchEgg", uid)
            end
            task.wait(0.2)
            invokeRemote("Eggs: RequestCompleteHatchEgg", uid)
            hatched = hatched + 1
            task.wait(0.25)
        end
        showToast("Lumin Hub", string.format("Hatched %d", hatched))
    end)
end)

IncubGB:AddLabel(string.format(
    "Unlocking hands a %s pet back to the dormant tree. Nothing is sent"
    .. " unless you own one, and nothing is sent once it is already unlocked.",
    Ext.Sakura.CraneAssetId), true)

IncubGB:AddButton("Unlock Incubator Now", function()
    local ok, why = Ext.unlockSakuraIncubator(true)
    showToast("Lumin Hub", why)
end)

IncubGB:AddToggle("AutoUnlockSakura", {
    Text    = "Auto Unlock Incubator",
    Tooltip = "Waits until you actually own a " .. Ext.Sakura.CraneAssetId
        .. ", then unlocks once and stops.",
    Default = false,
    Callback = function(val)
        Flags.AutoUnlockSakura = val
        if not val then stopLoop("SakuraUnlock") return end
        startLoop("SakuraUnlock", function()
            if Ext.incubatorUnlocked() then
                stopLoop("SakuraUnlock")
                pcall(function()
                    if Toggles.AutoUnlockSakura then Toggles.AutoUnlockSakura:SetValue(false) end
                end)
                return
            end
            if Ext.ownedCraneUid() then
                local ok, why = Ext.unlockSakuraIncubator(true)
                showToast("Lumin Hub", why)
                if ok then
                    stopLoop("SakuraUnlock")
                    pcall(function()
                        if Toggles.AutoUnlockSakura then Toggles.AutoUnlockSakura:SetValue(false) end
                    end)
                    return
                end
            end
            task.wait(10)
        end)
    end,
})

IncubGB:AddToggle("SakuraAutoMutate", {
    Text    = "Mutate When Charged",
    Tooltip = "Rolls the " .. Ext.Sakura.MutationName .. " mutation once the charge is up.",
    Default = false,
    Callback = function(v) Flags.SakuraAutoMutate = v end,
})

IncubGB:AddToggle("AutoIncubator", {
    Text    = "Auto Incubator",
    Tooltip = "Inserts your best egg, deposits crystals and keeps the charge topped up.",
    Default = false,
    Callback = function(val)
        Flags.AutoIncubator = val
        if not val then stopLoop("AutoIncubator") return end
        startLoop("AutoIncubator", function()
            Ext.runIncubator()
            task.wait(6)
        end)
    end,
})

local sakuraLabel = SakuraInfoGB:AddLabel("Loading...", true)

spawnTracked(function()
    task.wait(1)
    pcall(function()
        finderLabel:SetText(Ext.eggFinderText(tonumber(Flags.FinderRows) or 8))
        batLabel:SetText(Ext.batAuraText())
        travelLabel:SetText(Ext.Travel.lastCalibration or "Not calibrated yet")
        globalLabel:SetText("Rotation: " .. Ext.GlobalFarm.status)

        local active, treeCount = Ext.bloomActive()
        local left = Ext.bloomSecondsLeft()
        sakuraLabel:SetText(string.format(
            "%s: %s%s\nTrees up: %d   Crystals out: %d\nCrystals held: %s\nHits %d   Collected %d\nIncubator: %s\n%s: %s\n%s",
            Ext.Sakura.EventName,
            active and "ACTIVE" or "idle",
            (left and left > 0) and string.format(" (%dm %02ds left)", math.floor(left / 60), left % 60) or "",
            treeCount > 0 and treeCount or #Ext.taggedInWorkspace(Ext.Sakura.TreeTag),
            #Ext.taggedInWorkspace(Ext.Sakura.CrystalTag),
            Ext.shortNumber(Ext.sakuraCrystals()),
            Ext.SakuraStatus.hits, Ext.SakuraStatus.collected,
            Ext.incubatorUnlocked() and "unlocked" or "locked",
            Ext.Sakura.CraneAssetId,
            Ext.ownedCraneUid() and "owned" or "none",
            Ext.SakuraStatus.text))
    end)
end)

end

TBL = Tabs.Automation:AddLeftGroupbox("Automation"):AddTabbox()
TBR = Tabs.Automation:AddRightGroupbox("Inventory"):AddTabbox()
local EggsGB = TBL:AddTab({ Name = "Eggs", Tooltip = "Egg automation" })

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

local ProgGB = TBL:AddTab({ Name = "Progression", Tooltip = "Rebirths, bases, treadmills" })

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

local ClaimGB = TBL:AddTab({ Name = "Auto Claim", Tooltip = "Index, group, offline rewards" })

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

local CodesGB = Tabs.Automation:AddLeftGroupbox("Codes")

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

local SellGB = TBR:AddTab({ Name = "Auto Sell", Tooltip = "Sell pets" })

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
SellGB:AddToggle("AutoSellConfirm",   { Text = "Auto Confirm Sell",   Default = false,
    Callback = function(v) Flags.AutoSellConfirm = v end })

SellGB:AddSlider("SellDelay", {
    Text = "Sell Delay", Suffix = "s",
    Min = 0, Max = 5, Default = 0, Rounding = 2,
    Callback = function(v) Flags.SellDelay = v end,
})

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

local FuseGB = TBR:AddTab({ Name = "Auto Fuse", Tooltip = "Fuse pets" })

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

local DeleteGB = TBR:AddTab({ Name = "Cleanup", Tooltip = "Delete pets" })

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

TBL = Tabs.Intel:AddLeftGroupbox("Visuals"):AddTabbox()
TBR = Tabs.Intel:AddRightGroupbox("Intel"):AddTabbox()
local LiveGB = TBL:AddTab({ Name = "Field Right Now", Tooltip = "Current field contents" })
local liveLabel = LiveGB:AddLabel("Reading field...", true)

local ESPGB = TBL:AddTab({ Name = "ESP", Tooltip = "ESP settings" })

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

local IntelGB = TBR:AddTab({ Name = "Server Intel", Tooltip = "Server intel" })

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

local WebhookGB = TBR:AddTab({ Name = "Webhook", Tooltip = "Discord webhook" })

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

TBL = Tabs.System:AddLeftGroupbox("System"):AddTabbox()
TBR = Tabs.System:AddRightGroupbox("Settings"):AddTabbox()
local PlayerGB = TBL:AddTab({ Name = "Player", Tooltip = "Player utilities" })

PlayerGB:AddToggle("GodMode", {
    Text    = "GodMode",
    Tooltip = "Anti-fling, anti-ragdoll, and instant egg re-grab when a guard hits you.",
    Default = false,
    Callback = function(val)
        Flags.GodMode = val
        if val then
            if LuminGod:Start() then
                showToast("Lumin Hub", "GodMode on - hits will not stop the carry")
            else
                Toggles.GodMode:SetValue(false)
            end
        else
            LuminGod:Stop()
        end
    end,
})

PlayerGB:AddSlider("FlingSensitivity", {
    Text     = "Fling Sensitivity",
    Tooltip  = "Multiple of your walk speed that counts as a knockback. Lower catches softer hits; too low and running trips it.",
    Min      = 1.2,
    Max      = 4,
    Default  = 1.6,
    Rounding = 1,
    Callback = function(v) Flags.FlingSensitivity = v end,
})

local GodStatus = PlayerGB:AddLabel("GodMode: idle", true)

PlayerGB:AddToggle("AntiAFK", {
    Text = "Anti AFK", Default = false,
    Callback = function(v) Flags.AntiAFK = v end,
})

PlayerGB:AddToggle("NoAnims", {
    Text    = "No Animations",
    Tooltip = "Stops every character animation the moment it plays.",
    Default = false,
    Callback = function(v)
        Flags.NoAnims = v
        if v then NoAnims:Start() else NoAnims:Stop() end
    end,
})

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

local antiDieHum, antiDieConn

PlayerGB:AddToggle("AntiDie", {
    Text    = "Anti Die",
    Tooltip = "Clamps health above 0 the instant it drops, so the death chain never starts.",
    Default = false,
    Callback = function(val)
        Flags.AntiDie = val
        _G.__SAE_AntiDeath = val
        if val then
            protectChar(getCharacter())
            startLoop("AntiDie", function()
                local hum = getHumanoid()
                if hum then
                    if hum ~= antiDieHum then
                        if antiDieConn then pcall(function() antiDieConn:Disconnect() end) end
                        antiDieHum = hum
                        antiDieConn = hum.HealthChanged:Connect(function(h)
                            if Flags.AntiDie and h < 1 then
                                pcall(function() antiDieHum.Health = antiDieHum.MaxHealth end)
                            end
                        end)
                    end
                    if hum.Health < hum.MaxHealth then
                        pcall(function() hum.Health = hum.MaxHealth end)
                    end
                end
                task.wait(0.5)
            end)
        else
            stopLoop("AntiDie")
            if antiDieConn then pcall(function() antiDieConn:Disconnect() end) end
            antiDieHum, antiDieConn = nil, nil
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

local MoveGB2 = TBL:AddTab({ Name = "Movement", Tooltip = "Fly, noclip, speed" })

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

local ServerGB = TBL:AddTab({ Name = "Server", Tooltip = "Server hop and rejoin" })

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

local PerfGB = TBR:AddTab({ Name = "Performance", Tooltip = "Performance tweaks" })

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

local menuGroup = TBR:AddTab({ Name = "Menu", Tooltip = "Menu settings" })

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

do
    local ImEx = TBR:AddTab({ Name = "Import / Export", Tooltip = "Config import/export" })
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

local LOADER_SOURCE
do
    local env = (type(getgenv) == "function" and getgenv()) or _G
    local source = env and env.LuminHubSource
    if type(source) == "string" and source ~= "" then
        LOADER_SOURCE = [[
loadstring(game:HttpGet("]] .. source .. [["))()
]]
    end
end

local function queueLoader()
    if type(queue_on_teleport) ~= "function" then return false end
    local payload = Flags.RejoinPayload
    if not payload or payload == "" then payload = LOADER_SOURCE end
    if not payload or payload == "" then return false end
    local ok = pcall(queue_on_teleport, payload)
    return ok
end

local Rejoining = false

function doRejoin(why)
    if Rejoining then return end
    Rejoining = true
    queueLoader()
    task.spawn(function()
        for attempt = 1, 6 do
            local ok = pcall(function()
                TeleportService:Teleport(game.PlaceId, LocalPlayer)
            end)
            if ok then task.wait(6) else task.wait(2) end

            task.wait(math.min(2 ^ attempt, 20))
        end
        Rejoining = false
    end)
end

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

watchForKick()

trackConn(LocalPlayer.Idled:Connect(function()
    if Flags.AntiAFK == false then return end
    pcall(function()
        if VirtualUser == nil then
            VirtualUser = game:FindService("VirtualUser") or game:FindFirstChildWhichIsA("VirtualUser")
        end
        if VirtualUser then
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end
    end)
end))

trackConn(UserInputService.JumpRequest:Connect(function()
    if not Flags.InfiniteJump then return end
    local hum = getHumanoid()
    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end))

trackConn(RunService.Stepped:Connect(function()
    if not Flags.NoClip then return end
    local char = getCharacter()
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
    end
end))

trackConn(LocalPlayer.CharacterAdded:Connect(function(char)

    GameplayEntered = false
    task.wait(0.2)
    if Flags.AntiDie then
        protectChar(char)
    end
    God.carrying, God.carryUid = false, nil
    God.anchored = false
    task.wait(0.6)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if Flags.WalkSpeed and Flags.WalkSpeed > 16 then hum.WalkSpeed = Flags.WalkSpeed end
    if Flags.JumpPower and Flags.JumpPower > 50 then hum.JumpPower = Flags.JumpPower end
end))

startLoop("SellConfirmWatcher", function()
    if Flags.AutoSellConfirm then clickYesButton() end
    task.wait(0.25)
end)

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
                    "GodMode: on | carrying %s | re-grabs %d | hits %d | last hit %s",
                    God.carrying and (God.carryUid and God.carryUid:sub(1, 6) or "yes") or "no",
                    God.regrabs, God.flings,
                    (God.lastHit or 0) > 0 and string.format("%.0fs ago", since) or "none"))
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

        do
            local best, bestScore, byRarity, total = nil, -1, {}, 0
            for _, egg in pairs(getAreaEggs()) do
                local cat = egg.AssetCategory
                local info = cat and AssetInfo[cat]
                if info then
                    total = total + 1
                    byRarity[info.rarity] = (byRarity[info.rarity] or 0) + 1
                    local sc = info.rarityNum * 1e9 + getEggWeight(egg)
                    if sc > bestScore then
                        bestScore = sc
                        best = string.format("%s [%s] %.0fkg in %s",
                            cat, info.rarity, getEggWeight(egg), tostring(egg.AreaId))
                    end
                end
            end
            local parts = {}
            for i = #RarityOrder, 1, -1 do
                local r = RarityOrder[i]
                if byRarity[r] then parts[#parts + 1] = string.format("%s x%d", r, byRarity[r]) end
            end
            liveLabel:SetText(string.format("%d eggs up\nBest: %s\n%s",
                total, best or "none", table.concat(parts, "  ")))
        end

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

Flags.StealZones        = {}
Flags.StealRarities     = {}
Flags.SelectEggs        = {}
Flags.SelectMutations   = {}
Flags.FarmMinRarity     = nil
Flags.MinEggWeight      = 0
Flags.AdaptiveSpeed     = false
Flags.MoveMode          = "Tween"
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
Flags.AutoSellConfirm   = false
Flags.KeepMinRarity     = RarityOrder[3] or RarityOrder[1]
Flags.FuseCount         = 3
Flags.WalkSpeed         = 16
Flags.JumpPower         = 50
Flags.FlySpeed          = 100
Flags.AntiAFK           = false
Flags.GodMode           = false
Flags.NoAnims           = false
Flags.HighlightESP      = true
Flags.HopMethod         = "Least Populated"
Flags.DebugMode         = false

Flags.EggFinder            = false
Flags.FinderMinRarity      = nil
Flags.FinderZones          = {}
Flags.FinderInterval       = 3
Flags.FinderRows           = 8
Flags.BatAura              = false
Flags.BatPlotRadius        = 150
Flags.BatMinInterval       = 0.6
Flags.SakuraFarm           = false
Flags.SakuraCollect        = false
Flags.SakuraDirectCollect  = false
Flags.SakuraDirectHit      = false
Flags.SakuraAutoMutate     = false
Flags.AutoIncubator        = false
Flags.AutoUnlockSakura     = false
Flags.CherryFarm           = false
Flags.GlobalAutoFarm       = false
Flags.GlobalFarmLastArea   = nil
Flags.GlobalAreaSeconds    = 45
Flags.GlobalFarmSkipGuards = true
Flags.AutoCalibrateTravel  = false
Flags.TravelMargin         = tonumber(Ext.Constants.CLIENT_OVERLAP_MARGIN) or 0.95

_G.LuminHubDebug = function()
    return {
        status  = Status,
        running = Running,
        flags   = Flags,
        queue   = #SnipeQueue,
        plot    = CachedPlot and CachedPlot.Name or "unknown",
    }
end

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

    local r = getRoot()
    if r and r.Anchored then r.Anchored = false end
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

local function queueSelfForTeleport()
    if type(queue_on_teleport) ~= "function" then return end
    if not LOADER_SOURCE or LOADER_SOURCE == "" then return end
    pcall(queue_on_teleport, LOADER_SOURCE)
end

queueSelfForTeleport()

Library:SetWatermarkVisibility(true)
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind", "JobId_Input", "WebhookUrl", "WebhookMention" })
ThemeManager:SetFolder(TemplateConfig.Game.ThemeFolder)
SaveManager:SetFolder(TemplateConfig.Game.SaveFolder)
SaveManager:SetSubFolder(TemplateConfig.Game.SaveSubFolder)
SaveManager:BuildConfigSection(Tabs.System)
ThemeManager:ApplyToTab(Tabs.System)

Library:Notify({
    Title = "Lumin Hub",
    Description = "Loaded safely. Automation and config autoload are off.",
    Time = 4,
})
