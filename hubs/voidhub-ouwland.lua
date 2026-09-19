--[[
    VoidHub : Ouwland
    By von63rd

    UI      : VonLib (https://github.com/VoidDeveloper67/VonLib)
    Target  : Ouwland  (GameId 5595353122)
    Version : v1
]]

if getgenv and getgenv().VoidHubOuwland then
    pcall(function() getgenv().VoidHubOuwland.Destroy() end)
end

local VoidHub = {}
if getgenv then getgenv().VoidHubOuwland = VoidHub end

-- ============================================================================
-- SERVICES
-- ============================================================================

local Players             = game:GetService("Players")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local RunService          = game:GetService("RunService")
local TweenService        = game:GetService("TweenService")
local UserInputService    = game:GetService("UserInputService")
local HttpService         = game:GetService("HttpService")
local Workspace           = game:GetService("Workspace")
local Lighting            = game:GetService("Lighting")
local StarterGui          = game:GetService("StarterGui")
local TeleportService     = game:GetService("TeleportService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService          = game:GetService("GuiService")
local CoreGui             = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
-- Roblox swaps the camera out on respawn, so never hold on to one.
local function camera() return Workspace.CurrentCamera end

-- ============================================================================
-- EXECUTOR SHIMS
-- ============================================================================

local httpRequest  = (syn and syn.request) or (http and http.request) or http_request or request
local setClipboard = setclipboard or toclipboard
local queueTeleport = queue_on_teleport or (syn and syn.queue_on_teleport)
local protectGui   = (syn and syn.protect_gui) or protectgui
local hiddenUI     = gethui

local function safeParentGui(gui)
    if hiddenUI then
        local ok, parent = pcall(hiddenUI)
        if ok and parent then gui.Parent = parent return end
    end
    if protectGui then pcall(protectGui, gui) end
    gui.Parent = game:GetService("CoreGui")
end

-- ============================================================================
-- STATE
-- ============================================================================

local Flags = {}
VoidHub.Flags = Flags

local Threads = {}
local Connections = {}

local function stopThread(name)
    local entry = Threads[name]
    if not entry then return end
    Threads[name] = nil
    entry.alive = false
    if entry.thread then pcall(task.cancel, entry.thread) end
end

-- task.spawn runs the body straight away, so the registry entry has to exist
-- before the thread starts or the loop's own "am I still wanted" check fails
-- on its first pass.
local function startThread(name, fn)
    stopThread(name)
    local entry = { alive = true }
    Threads[name] = entry
    entry.thread = task.spawn(function()
        local ok, err = pcall(fn)
        if not ok then warn("[VoidHub] thread '" .. name .. "': " .. tostring(err)) end
        if Threads[name] == entry then Threads[name] = nil end
    end)
    return entry
end

-- Runs `fn` every `interval` seconds for as long as `enabled` was true.
local function setLoop(name, enabled, interval, fn)
    if not enabled then stopThread(name) return end
    startThread(name, function()
        while Threads[name] do
            local ok, err = pcall(fn)
            if not ok then warn("[VoidHub] " .. name .. ": " .. tostring(err)) end
            task.wait(interval)
        end
    end)
end

local function disconnect(name)
    local c = Connections[name]
    if c then
        Connections[name] = nil
        pcall(function() c:Disconnect() end)
    end
end

local function connect(name, signal, fn)
    disconnect(name)
    Connections[name] = signal:Connect(fn)
end

-- ============================================================================
-- SMALL HELPERS
-- ============================================================================

local function character() return LocalPlayer.Character end

local function root()
    local char = character()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function humanoid()
    local char = character()
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function alive()
    local hum = humanoid()
    return hum ~= nil and hum.Health > 0 and root() ~= nil
end

local function modelRoot(model)
    if typeof(model) ~= "Instance" then return nil end
    if model:IsA("BasePart") then return model end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if hum and hum.RootPart then return hum.RootPart end
    return model:FindFirstChild("HumanoidRootPart")
        or model:FindFirstChild("Torso")
        or (model:IsA("Model") and model.PrimaryPart)
        or model:FindFirstChildWhichIsA("BasePart")
end

local function positionOf(target)
    if typeof(target) == "Vector3" then return target end
    if typeof(target) == "CFrame" then return target.Position end
    if typeof(target) == "Instance" then
        local part = modelRoot(target)
        if part then return part.Position end
    end
    return nil
end

local function distanceTo(target)
    local myRoot = root()
    local pos = positionOf(target)
    if not myRoot or not pos then return math.huge end
    return (myRoot.Position - pos).Magnitude
end

local function commaNumber(n)
    local s = tostring(math.floor(tonumber(n) or 0))
    local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
    return (out:gsub("^,", ""))
end

-- The game stores positions as Vector3s, CFrames or "x, y, z" strings
-- depending on which table they came out of.
local function toVector(value)
    if typeof(value) == "Vector3" then return value end
    if typeof(value) == "CFrame" then return value.Position end
    if type(value) == "table" then
        if value.Position then return toVector(value.Position) end
        if #value >= 3 then return Vector3.new(value[1], value[2], value[3]) end
    end
    if type(value) == "string" then
        local x, y, z = string.match(value, "([%-%d%.]+),%s*([%-%d%.]+),%s*([%-%d%.]+)")
        if x then return Vector3.new(tonumber(x), tonumber(y), tonumber(z)) end
    end
    return nil
end

local function formatClock(seconds)
    seconds = math.max(0, math.floor(tonumber(seconds) or 0))
    local m = math.floor(seconds / 60)
    local s = seconds % 60
    if m >= 60 then
        return string.format("%dh %02dm", math.floor(m / 60), m % 60)
    end
    return string.format("%d:%02d", m, s)
end

-- ============================================================================
-- GAME BINDINGS  (Ouwland / CAM framework)
-- ============================================================================

local Game = {}

Game.PlaceId = 136406881576517
Game.GameId  = 5595353122

do
    local cam = ReplicatedStorage:WaitForChild("CAM", 20)
    Game.CAM = cam
    Game.Global = cam and cam:WaitForChild("Global", 10)

    local function tryRequire(inst)
        if not inst then return nil end
        local ok, mod = pcall(require, inst)
        return ok and mod or nil
    end

    Game.Utility    = Game.Global and tryRequire(Game.Global:FindFirstChild("Utility"))
    Game.Portal     = Game.Global and tryRequire(Game.Global:FindFirstChild("ServerClientPortal"))
    Game.DayNight   = Game.Global and tryRequire(Game.Global:FindFirstChild("DayAndNightHandler"))
    Game.Rarities   = Game.Global and tryRequire(Game.Global:FindFirstChild("Rarities"))
    Game.GameSettings = Game.Global and tryRequire(Game.Global:FindFirstChild("gameSettings"))
    Game.Regions    = tryRequire(ReplicatedStorage:FindFirstChild("Regions"))

    local client = cam and cam:FindFirstChild("Client")
    local modules = client and client:FindFirstChild("Modules")
    Game.WorldBosses = modules and tryRequire(modules:FindFirstChild("WorldBosses"))
    Game.MapSettings = modules and tryRequire(modules:FindFirstChild("MapSettings"))
end

-- Player data folder for the currently equipped slot.
function Game.Data()
    if Game.Utility and Game.Utility.GetData then
        local ok, data = pcall(Game.Utility.GetData, LocalPlayer)
        if ok and data then return data end
    end
    local service = ReplicatedStorage:FindFirstChild("Player_Service")
    local all = service and service:FindFirstChild("Data")
    local mine = all and all:FindFirstChild(LocalPlayer.Name)
    if not mine then return nil end
    local slots = mine:FindFirstChild("slots")
    local equipped = mine:FindFirstChild("slotEquipped")
    if not slots then return nil end
    return slots:FindFirstChild("Slot" .. tostring(equipped and equipped.Value or 1))
end

local function dataValue(path, default)
    local node = Game.Data()
    if not node then return default end
    for segment in string.gmatch(path, "[^%.]+") do
        node = node:FindFirstChild(segment)
        if not node then return default end
    end
    if node:IsA("ValueBase") then return node.Value end
    return node
end

function Game.Exp()
    return tonumber(dataValue("Exp.Current", 0)) or 0, tonumber(dataValue("Exp.Goal", 0)) or 0
end

function Game.Wen()
    return tonumber(dataValue("Wen", 0)) or 0
end

-- The game has no single "Level" value; the number of completed Exp goals is
-- what the UI counts, so we mirror it off SlotLevelStats where available and
-- fall back to the Exp goal curve.
function Game.Levelish()
    local goal = select(2, Game.Exp())
    return goal
end

-- Region folders that hold spawned NPCs.
function Game.RegionFolders()
    local humanoids = Workspace:FindFirstChild("Humanoids")
    local regions = humanoids and humanoids:FindFirstChild("Regions")
    return regions and regions:GetChildren() or {}
end

-- Each entry under ActiveNpcs is a folder holding the NPC's AI scripts plus a
-- model of the same name. Older spawns sit there as a bare model, so accept
-- both shapes.
function Game.NpcModel(node)
    if typeof(node) ~= "Instance" then return nil end
    if node:IsA("Model") and node:FindFirstChildOfClass("Humanoid") then return node end
    local same = node:FindFirstChild(node.Name)
    if same and same:IsA("Model") and same:FindFirstChildOfClass("Humanoid") then return same end
    for _, child in ipairs(node:GetChildren()) do
        if child:IsA("Model") and child:FindFirstChildOfClass("Humanoid") then return child end
    end
    return nil
end

-- Every spawned NPC model in the world, optionally filtered by a name set.
function Game.EnumerateNpcs(filterSet)
    local out = {}
    for _, region in ipairs(Game.RegionFolders()) do
        local active = region:FindFirstChild("ActiveNpcs")
        if active then
            for _, node in ipairs(active:GetChildren()) do
                if (not filterSet) or filterSet[node.Name] then
                    local npc = Game.NpcModel(node)
                    local hum = npc and npc:FindFirstChildOfClass("Humanoid")
                    if npc and hum and hum.Health > 0 and modelRoot(npc) then
                        out[#out + 1] = { Model = npc, Humanoid = hum, Region = region.Name }
                    end
                end
            end
        end
    end
    return out
end

-- Unique NPC names currently present, for populating dropdowns.
function Game.NpcNames()
    local seen, out = {}, {}
    for _, region in ipairs(Game.RegionFolders()) do
        local active = region:FindFirstChild("ActiveNpcs")
        if active then
            for _, node in ipairs(active:GetChildren()) do
                if not seen[node.Name] and Game.NpcModel(node) then
                    seen[node.Name] = true
                    out[#out + 1] = node.Name
                end
            end
        end
    end
    table.sort(out)
    return out
end

function Game.FindNpc(name)
    for _, region in ipairs(Game.RegionFolders()) do
        local active = region:FindFirstChild("ActiveNpcs")
        local node = active and active:FindFirstChild(name)
        local npc = node and Game.NpcModel(node)
        if npc then
            local hum = npc:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then return npc, hum end
        end
    end
    return nil
end

function Game.IsNight()
    if Game.DayNight and Game.DayNight.IsNight then
        local ok, night = pcall(Game.DayNight.IsNight)
        if ok then return night end
    end
    local hour = Lighting.ClockTime
    return hour < 6 or hour >= 18
end

function Game.SecondsUntilPhaseChange()
    if Game.DayNight and Game.DayNight.SecondsUntilPhaseChange then
        local ok, secs = pcall(Game.DayNight.SecondsUntilPhaseChange)
        if ok and type(secs) == "number" then return secs end
    end
    return -1
end

function Game.Bosses()
    if Game.WorldBosses and Game.WorldBosses.Get then
        local ok, list = pcall(Game.WorldBosses.Get)
        if ok and type(list) == "table" then return list end
    end
    return {}
end

function Game.NpcSpawns()
    return (Game.Regions and Game.Regions.NpcSpawns) or {}
end

function Game.LootDrops()
    local folder = Workspace:FindFirstChild("LootDrops")
    return folder and folder:GetChildren() or {}
end

function Game.Chests()
    local folder = Workspace:FindFirstChild("Chests")
    return folder and folder:GetChildren() or {}
end

VoidHub.Game = Game

-- ============================================================================
-- MOVEMENT
-- ============================================================================

local Move = {}
Move.CurrentTween = nil

local function stopTween()
    if Move.CurrentTween then
        pcall(function() Move.CurrentTween:Cancel() end)
        Move.CurrentTween = nil
    end
end

-- Where to stand relative to a target, per the Position dropdown.
function Move.OffsetFor(targetPart)
    local mode = Flags.FarmPosition or "Behind"
    local dist = tonumber(Flags.FarmDistance) or 7
    if mode == "Above" then
        return Vector3.new(0, dist + 6, 0)
    elseif mode == "Inside" then
        return Vector3.new(0, 0, 0)
    elseif mode == "Front" then
        return targetPart.CFrame.LookVector * dist
    elseif mode == "Side" then
        return targetPart.CFrame.RightVector * dist
    end
    -- Behind
    return targetPart.CFrame.LookVector * -dist
end

-- Ouwland resolves melee hits from where the character is pointing, so every
-- move keeps us aimed at the thing we are here to hit.
function Move.Face(lookAt)
    local myRoot = root()
    if not myRoot or not lookAt then return end
    local flat = Vector3.new(lookAt.X, myRoot.Position.Y, lookAt.Z)
    if (flat - myRoot.Position).Magnitude < 0.5 then return end
    myRoot.CFrame = CFrame.lookAt(myRoot.Position, flat)
end

local function facingCFrame(at, lookAt, fallbackDelta)
    if lookAt then
        local flat = Vector3.new(lookAt.X, at.Y, lookAt.Z)
        if (flat - at).Magnitude > 0.5 then
            return CFrame.lookAt(at, flat)
        end
    end
    return CFrame.lookAt(at, at + Vector3.new(fallbackDelta.X, 0, fallbackDelta.Z))
end

-- Single non-yielding step toward `goal`. Returns true once we are there.
-- `lookAt` is an optional world position to keep facing while we travel.
function Move.Step(goal, lookAt)
    local myRoot = root()
    local hum = humanoid()
    if not myRoot or not hum then return false end

    local mode = Flags.MovementType or "Instant"
    local delta = goal - myRoot.Position
    local dist = delta.Magnitude

    if dist < 4 then
        stopTween()
        Move.Face(lookAt)
        return true
    end

    if mode == "Instant" then
        stopTween()
        myRoot.CFrame = facingCFrame(goal, lookAt, delta)
        return true
    elseif mode == "Walk" then
        stopTween()
        hum:MoveTo(goal)
        if dist < 10 then Move.Face(lookAt) end
        return dist < 6
    end

    -- Tween
    local speed = math.max(10, tonumber(Flags.TweenSpeed) or 180)
    local duration = math.clamp(dist / speed, 0.05, 12)
    if not Move.CurrentTween or Move.CurrentTween.PlaybackState ~= Enum.PlaybackState.Playing
        or (Move.Goal and (Move.Goal - goal).Magnitude > 8) then
        stopTween()
        Move.Goal = goal
        myRoot.Anchored = false
        local tween = TweenService:Create(
            myRoot,
            TweenInfo.new(duration, Enum.EasingStyle.Linear),
            { CFrame = facingCFrame(goal, lookAt, delta) }
        )
        Move.CurrentTween = tween
        tween:Play()
    end
    return false
end

-- Yields until we reach `goal` or `timeout` elapses.
function Move.To(goal, timeout, shouldAbort, lookAt)
    local deadline = os.clock() + (timeout or 12)
    while os.clock() < deadline do
        if shouldAbort and shouldAbort() then stopTween() return false end
        if not alive() then stopTween() return false end
        if Move.Step(goal, lookAt) then return true end
        task.wait(0.06)
    end
    stopTween()
    return distanceTo(goal) < 12
end

-- Close the gap, then stop and hold still facing the target. Letting the tween
-- keep running would rewrite our rotation every frame and the swing would miss.
function Move.Engage(part)
    local myRoot = root()
    if not myRoot or not part then return false end
    local reach = (tonumber(Flags.FarmDistance) or 7) + 3
    if (myRoot.Position - part.Position).Magnitude > reach then
        Move.Step(part.Position + Move.OffsetFor(part), part.Position)
        return false
    end
    stopTween()
    Move.Face(part.Position)
    return true
end

function Move.ToTarget(target, timeout, shouldAbort)
    local part = (typeof(target) == "Instance") and modelRoot(target) or nil
    if part then
        return Move.To(part.Position + Move.OffsetFor(part), timeout, shouldAbort, part.Position)
    end
    local pos = positionOf(target)
    if not pos then return false end
    return Move.To(pos + Vector3.new(0, 4, 0), timeout, shouldAbort)
end

function Move.Teleport(cframe)
    local myRoot = root()
    if not myRoot then return false end
    stopTween()
    if typeof(cframe) == "Vector3" then cframe = CFrame.new(cframe) end
    myRoot.CFrame = cframe
    return true
end

VoidHub.Move = Move

-- ============================================================================
-- COMBAT
-- ============================================================================

local Combat = {}

local SkillsModule = (function()
    local ok, mod = pcall(require, ReplicatedStorage.CAM.Global.Skills_Module)
    return ok and mod or nil
end)()

local SkillController = (function()
    local controllers = ReplicatedStorage.CAM:FindFirstChild("Client")
    controllers = controllers and controllers:FindFirstChild("Controllers")
    local inst = controllers and controllers:FindFirstChild("Skill_Controller")
    if not inst then return nil end
    local ok, mod = pcall(require, inst)
    return ok and mod or nil
end)()

Combat.SlotNames = { "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten" }

local function mobileFrame()
    local gui = LocalPlayer:FindFirstChild("PlayerGui")
    local holder = gui and gui:FindFirstChild("ComponentsHolder")
    return holder and holder:FindFirstChild("Mobile")
end

-- The on-screen button behind a mobile control, e.g. "Combat" or "Three".
local function mobileButton(name)
    local mobile = mobileFrame()
    local frame = mobile and mobile:FindFirstChild(name)
    if not frame then return nil end
    local content = frame:FindFirstChild("Content")
        or (frame:FindFirstChild("Fade") and frame.Fade:FindFirstChild("Content"))
    local press = content and content:FindFirstChild("Press")
    if press and press:IsA("GuiButton") then return press end
    return nil
end

-- Presses an on-screen control.
--
-- The game's mobile buttons listen on InputBegan/InputEnded rather than
-- Activated, and VirtualInputManager's synthetic events do not reach them on
-- mobile executors. Firing the signal directly does, so that is the primary
-- path; a synthetic tap stays as a fallback for executors without firesignal.
local function tapGui(guiObject, holdSeconds)
    if not guiObject then return false end

    if type(firesignal) == "function" then
        local ok = pcall(function() firesignal(guiObject.InputBegan) end)
        if ok then
            if holdSeconds and holdSeconds > 0 then task.wait(holdSeconds) end
            pcall(function() firesignal(guiObject.InputEnded) end)
            return true
        end
    end

    if type(getconnections) == "function" then
        local ok = pcall(function()
            for _, connection in ipairs(getconnections(guiObject.InputBegan)) do
                connection:Fire()
            end
        end)
        if ok then
            if holdSeconds and holdSeconds > 0 then task.wait(holdSeconds) end
            pcall(function()
                for _, connection in ipairs(getconnections(guiObject.InputEnded)) do
                    connection:Fire()
                end
            end)
            return true
        end
    end

    local absPos, absSize = guiObject.AbsolutePosition, guiObject.AbsoluteSize
    if absSize.X <= 0 or absSize.Y <= 0 then return false end
    local x = absPos.X + absSize.X * 0.5
    local y = absPos.Y + absSize.Y * 0.5 + GuiService:GetGuiInset().Y
    local ok = pcall(function()
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
    end)
    if not ok then return false end
    task.wait(holdSeconds or 0.04)
    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
    end)
    return true
end

-- Basic attack. Uses the mobile combat button when present, otherwise a click
-- at the centre of the screen (which is what the desktop handler listens for).
function Combat.M1()
    local btn = mobileButton("Combat")
    if btn then
        return tapGui(btn, 0)
    end
    local viewport = camera().ViewportSize
    local x, y = viewport.X * 0.5, viewport.Y * 0.5
    local ok = pcall(function()
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
    end)
    if not ok then return false end
    task.wait(0.03)
    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
    end)
    return true
end

-- Skill slot 1-10. Tapping the slot lets the game do its own cooldown and
-- requirement checks instead of us guessing at them.
function Combat.UseSlot(index)
    local name = Combat.SlotNames[index]
    if not name then return false end
    local btn = mobileButton(name)
    if btn then return tapGui(btn, 0.05) end
    if SkillController and SkillController.Toggle then
        local ok = pcall(SkillController.Toggle, LocalPlayer, index, true)
        return ok
    end
    return false
end

-- Name shown on a slot, if the game has populated it.
function Combat.SlotSkillName(index)
    local mobile = mobileFrame()
    local frame = mobile and mobile:FindFirstChild(Combat.SlotNames[index] or "")
    local content = frame and frame:FindFirstChild("Content")
    local slot = content and content:FindFirstChild("Slot")
    if not slot then return nil end
    local child = slot:FindFirstChild(tostring(index) .. "-Skill")
    if not child then return nil end
    local label = child:FindFirstChildWhichIsA("TextLabel", true)
    if label and label.Text ~= "" then return label.Text end
    return nil
end

function Combat.SlotIsReady(index)
    local mobile = mobileFrame()
    local frame = mobile and mobile:FindFirstChild(Combat.SlotNames[index] or "")
    local content = frame and frame:FindFirstChild("Content")
    local slot = content and content:FindFirstChild("Slot")
    local child = slot and slot:FindFirstChild(tostring(index) .. "-Skill")
    if not child then return false end
    -- A cooling-down slot keeps a visible countdown label.
    for _, d in ipairs(child:GetDescendants()) do
        if d:IsA("TextLabel") and d.Visible and tonumber(d.Text) then
            return false
        end
    end
    return child.Visible
end

Combat.Blocking = false

function Combat.SetBlock(state)
    if not SkillsModule or not SkillsModule.Blocking then return false end
    if state == Combat.Blocking then return true end
    Combat.Blocking = state
    local fn = state and SkillsModule.Blocking.Hold or SkillsModule.Blocking.UnHold
    local ok = pcall(fn, LocalPlayer)
    if not ok then Combat.Blocking = not state end
    return ok
end

function Combat.Parry(window)
    if not SkillsModule or not SkillsModule.Blocking then return false end
    Combat.SetBlock(true)
    task.delay(window or 0.35, function()
        if not Flags.AutoBlock then Combat.SetBlock(false) end
    end)
    return true
end

-- Toolbar weapon slots (One .. Five).
Combat.WeaponSlots = { "One", "Two", "Three", "Four", "Five" }

function Combat.EquipSlot(slotName)
    local index = table.find(Combat.WeaponSlots, slotName) or tonumber(slotName)
    if not index then return false end
    if Game.Utility and Game.Utility.ForceEquip then
        local ok = pcall(Game.Utility.ForceEquip, index)
        if ok then return true end
    end
    -- Fall back to the number key the desktop hotbar listens for.
    local keyCode = Enum.KeyCode["" .. tostring(index)]
    if keyCode then
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
            task.wait(0.03)
            VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
        end)
        return true
    end
    return false
end

VoidHub.Combat = Combat

-- ============================================================================
-- INSTANT KILL
--   Supplied by von63rd; kept intact so its confirmation logic stays honest.
-- ============================================================================

local InstantKill = {}
InstantKill.Targets = setmetatable({}, { __mode = "k" })
InstantKill.LastStatus = "idle"

function InstantKill.Try(npc)
    if game.GameId ~= 5595353122 then return false, "wrong game" end

    if typeof(npc) ~= "Instance" or not npc:IsA("Model") then
        return false, "no target"
    end

    local targets = InstantKill.Targets
    local saved = targets[npc]
    if saved and saved.pending then return false, "pending" end
    if saved and saved.done then return true, "confirmed" end

    if not npc:IsDescendantOf(Workspace) then
        return false, "target gone"
    end

    if Players:GetPlayerFromCharacter(npc) then
        return false, "not an npc"
    end

    local char = LocalPlayer.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")
    local myHum = char and char:FindFirstChildOfClass("Humanoid")
    local hum = npc:FindFirstChildOfClass("Humanoid")
    local npcRoot = hum and (hum.RootPart or npc:FindFirstChild("HumanoidRootPart"))

    if not myRoot or not myHum or myHum.Health <= 0 then
        return false, "waiting for character"
    end

    if not hum or not npcRoot or hum.Health <= 0 then
        return false, "target dead"
    end

    local config = LocalPlayer:FindFirstChild("Items_Config")
    local equipped = config and config:FindFirstChild("Equipped")
    local weapon = equipped and equipped.Value
    local stamp = char:GetAttribute("last_cmbat")
    local now = os.clock()

    if not saved or saved.char ~= char or saved.weapon ~= weapon then
        saved = {
            char = char,
            weapon = weapon,
            hp = hum.Health,
            stamp = stamp,
            tries = 0,
            nextTry = 0,
        }
        targets[npc] = saved
        return false, "tagging"
    end

    if (myRoot.Position - npcRoot.Position).Magnitude > 14 then
        saved.hp = hum.Health
        saved.stamp = stamp
        saved.hitAt = nil
        saved.damageAt = nil
        return false, "too far"
    end

    if typeof(stamp) == "number" and stamp ~= saved.stamp then
        saved.hitAt = now
    end

    if hum.Health < saved.hp then
        saved.damageAt = now
    end

    saved.stamp = stamp
    saved.hp = hum.Health

    if not saved.hitAt or not saved.damageAt then
        return false, "tagging"
    end

    if now - saved.hitAt > 0.75 or now - saved.damageAt > 0.75 then
        return false, "waiting for hit"
    end

    if saved.tries >= 2 or now < saved.nextTry then
        return false, "using normal hits"
    end

    if type(isnetworkowner) ~= "function" then
        return false, "ownership check missing"
    end

    local checked, owned = pcall(isnetworkowner, npcRoot)
    if not checked or not owned then
        return false, "waiting for ownership"
    end

    local data = Game.Utility and Game.Utility.GetData(LocalPlayer)
    if not data or not data:FindFirstChild("Exp") or not data:FindFirstChild("Wen") then
        return false, "data loading"
    end

    local xp = data.Exp.Current.Value
    local goal = data.Exp.Goal.Value
    local wen = data.Wen.Value
    local previousState = hum:GetState()

    saved.pending = true
    saved.tries += 1
    saved.nextTry = now + 3
    saved.status = "attempted"

    local sent = pcall(function()
        hum:ChangeState(Enum.HumanoidStateType.Dead)
    end)

    if not sent then
        saved.pending = false
        saved.status = "failed"
        return false, saved.status
    end

    task.spawn(function()
        local deadline = os.clock() + 2

        repeat
            task.wait(0.1)

            local current = Game.Utility and Game.Utility.GetData(LocalPlayer)
            local removed = not npc:IsDescendantOf(Workspace)
            local rewarded = current and (
                current.Exp.Current.Value ~= xp
                or current.Exp.Goal.Value ~= goal
                or current.Wen.Value > wen
            )

            if removed and rewarded then
                saved.done = true
                saved.pending = false
                saved.status = "confirmed"
                return
            end
        until os.clock() >= deadline

        if npc.Parent and hum.Parent and hum.Health > 0 then
            pcall(function()
                hum:ChangeState(previousState)
            end)
        end

        saved.pending = false
        saved.hitAt = nil
        saved.damageAt = nil
        saved.status = "unconfirmed"
    end)

    return false, "attempted"
end

VoidHub.InstantKill = InstantKill

-- ============================================================================
-- PROXIMITY PROMPTS
-- ============================================================================

local Prompts = {}

function Prompts.FindIn(instance, matcher)
    if typeof(instance) ~= "Instance" then return nil end
    for _, d in ipairs(instance:GetDescendants()) do
        if d:IsA("ProximityPrompt") and (not matcher or matcher(d)) then
            return d
        end
    end
    if instance:IsA("ProximityPrompt") then return instance end
    return nil
end

function Prompts.Fire(prompt, holdOverride)
    if not prompt or not prompt:IsA("ProximityPrompt") then return false end
    if typeof(fireproximityprompt) ~= "function" then return false end
    local previousHold = prompt.HoldDuration
    local previousDistance = prompt.MaxActivationDistance
    local previousEnabled = prompt.Enabled
    pcall(function()
        prompt.HoldDuration = 0
        prompt.MaxActivationDistance = math.max(previousDistance, 30)
        prompt.Enabled = true
    end)
    local ok = pcall(fireproximityprompt, prompt, holdOverride or 1)
    task.delay(0.35, function()
        pcall(function()
            prompt.HoldDuration = previousHold
            prompt.MaxActivationDistance = previousDistance
            prompt.Enabled = previousEnabled
        end)
    end)
    return ok
end

-- Walk to whatever owns the prompt, then fire it.
function Prompts.GoFire(prompt, timeout, shouldAbort)
    if not prompt then return false end
    local anchor = prompt:FindFirstAncestorWhichIsA("BasePart") or prompt.Parent
    if anchor and anchor:IsA("BasePart") then
        Move.To(anchor.Position + Vector3.new(0, 4, 0), timeout or 10, shouldAbort)
    elseif anchor and anchor:IsA("Model") then
        Move.ToTarget(anchor, timeout or 10, shouldAbort)
    end
    task.wait(0.15)
    return Prompts.Fire(prompt)
end

VoidHub.Prompts = Prompts

-- ============================================================================
-- WORLD OBJECT LOOKUPS
-- ============================================================================

local World = {}

-- Every "Chat" prompt NPC in the map, keyed by NPC name.
function World.StationaryNpcs()
    local out = {}
    local debree = Workspace:FindFirstChild("Debree")
    local regions = debree and debree:FindFirstChild("Regions")
    if not regions then return out end
    for _, region in ipairs(regions:GetChildren()) do
        local holder = region:FindFirstChild("StationaryNpcs")
        if holder then
            for _, npc in ipairs(holder:GetChildren()) do
                out[npc.Name] = { Model = npc, Region = region.Name }
            end
        end
    end
    return out
end

function World.ChatPrompt(npcModel)
    return Prompts.FindIn(npcModel, function(p)
        return p.ActionText == "Chat"
    end)
end

-- Purchase prompts, listed as "NPC - Item".
function World.ShopItems()
    local out = {}
    for name, entry in pairs(World.StationaryNpcs()) do
        for _, child in ipairs(entry.Model:GetChildren()) do
            if string.find(child.Name, "Shop") then
                for _, item in ipairs(child:GetChildren()) do
                    local prompt = Prompts.FindIn(item, function(p)
                        return p.ActionText == "Purchase"
                    end)
                    if prompt then
                        out[name .. " - " .. item.Name] = prompt
                    end
                end
            end
        end
    end
    return out
end

function World.ChestList()
    local out = {}
    local folder = Workspace:FindFirstChild("Chests")
    if not folder then return out end
    for _, chest in ipairs(folder:GetChildren()) do
        local prompt = Prompts.FindIn(chest)
        if prompt then
            out[#out + 1] = { Name = chest.Name, Model = chest, Prompt = prompt }
        end
    end
    return out
end

-- Chests only exist while they are spawned, so seed the filter with the ones
-- the game is known to place. Anything new gets picked up on refresh.
World.KnownChests = { "Common Chest", "Sealed Cache T3", "Snow Mound" }

function World.ChestNames()
    local seen, out = {}, {}
    for _, name in ipairs(World.KnownChests) do
        seen[name] = true
        out[#out + 1] = name
    end
    for _, chest in ipairs(World.ChestList()) do
        if not seen[chest.Name] then
            seen[chest.Name] = true
            out[#out + 1] = chest.Name
        end
    end
    table.sort(out)
    return out
end

-- Loot drops we are actually allowed to pick up.
function World.MyDrops()
    local out = {}
    local folder = Workspace:FindFirstChild("LootDrops")
    if not folder then return out end
    for _, drop in ipairs(folder:GetChildren()) do
        local private = drop:GetAttribute("DropPrivate")
        local owner = drop:GetAttribute("DropOwnerUserId")
        local mine = (not private) or (tonumber(owner) == LocalPlayer.UserId)
        if mine then
            local prompt = Prompts.FindIn(drop)
            out[#out + 1] = {
                Instance = drop,
                Item = drop:GetAttribute("DropItemId") or drop.Name,
                Prompt = prompt,
            }
        end
    end
    return out
end

-- Training spots come from gameSettings, which lists every trial for this
-- place along with a position. The workspace copy only exists while the trial
-- is streamed in, so it is used just for the prompt.
-- The workspace folder and the settings table name a few trials differently.
World.TrainingAliases = {
    ["Squat Rack"]   = "Squat",
    ["Aim Training"] = "Target Shooting",
}

function World.TrainingSpots()
    local out, seen = {}, {}
    local folder = Workspace:FindFirstChild("Training")

    local settings = Game.GameSettings
    local byPlace = settings and settings.TrainingMarkerPositions
    local here = byPlace and (byPlace[game.PlaceId] or byPlace[tostring(game.PlaceId)] or byPlace.Default)
    if type(here) == "table" then
        for name, info in pairs(here) do
            local position = type(info) == "table" and toVector(info.Position) or nil
            local model = folder and folder:FindFirstChild(name)
            if not model and folder then
                for alias, canonical in pairs(World.TrainingAliases) do
                    if canonical == name then
                        model = folder:FindFirstChild(alias)
                        if model then seen[alias] = true break end
                    end
                end
            end
            seen[name] = true
            out[#out + 1] = {
                Name = name,
                Position = position,
                Model = model,
                Icon = type(info) == "table" and info.Image or nil,
                Prompt = model and Prompts.FindIn(model, function(p) return p.ActionText == "Train" end) or nil,
            }
        end
    end

    if folder then
        for _, spot in ipairs(folder:GetChildren()) do
            local canonical = World.TrainingAliases[spot.Name] or spot.Name
            if not seen[canonical] and not seen[spot.Name] then
                seen[canonical] = true
                local part = modelRoot(spot)
                out[#out + 1] = {
                    Name = canonical,
                    Position = part and part.Position or nil,
                    Model = spot,
                    Prompt = Prompts.FindIn(spot, function(p) return p.ActionText == "Train" end),
                }
            end
        end
    end

    table.sort(out, function(a, b) return a.Name < b.Name end)
    return out
end

-- Shrines are listed per region in the game's region table, which survives
-- streaming.
function World.Shrines()
    local out, seen = {}, {}
    local regionTable = (Game.Regions and Game.Regions.Regions) or {}
    for regionName, info in pairs(regionTable) do
        if type(info) == "table" and type(info.Shrines) == "table" then
            for _, shrine in pairs(info.Shrines) do
                if type(shrine) == "table" and shrine.At then
                    local name = tostring(shrine.Name or regionName)
                    if not seen[name] then
                        seen[name] = true
                        out[#out + 1] = { Name = name, Position = toVector(shrine.At), Region = regionName }
                    end
                end
            end
        end
    end

    local map = Workspace:FindFirstChild("Map")
    local regions = map and map:FindFirstChild("Regions")
    if regions then
        for _, region in ipairs(regions:GetChildren()) do
            for _, child in ipairs(region:GetChildren()) do
                if string.sub(child.Name, 1, 8) == "Shrine -" then
                    local name = child.Name:gsub("^Shrine %- ", "")
                    local part = modelRoot(child)
                    if part and not seen[name] then
                        seen[name] = true
                        out[#out + 1] = { Name = name, Position = part.Position, Region = region.Name }
                    end
                end
            end
        end
    end
    return out
end

VoidHub.World = World

-- ============================================================================
-- TARGETING
-- ============================================================================

local Target = {}
Target.Current = nil
Target.Status = "idle"

-- VonLib hands a multi-select back as { ["Option"] = true, ... } and a plain
-- list as an array, so accept either and ignore anything unticked.
local function selectedList(flagValue)
    local out = {}
    if type(flagValue) == "table" then
        for key, value in pairs(flagValue) do
            if type(key) == "number" and type(value) == "string" then
                out[#out + 1] = value
            elseif type(key) == "string" and value then
                out[#out + 1] = key
            end
        end
        table.sort(out)
    elseif type(flagValue) == "string" and flagValue ~= "" and flagValue ~= "All" then
        out[1] = flagValue
    end
    return out
end

-- nil means "no filter", which callers treat as "everything".
local function selectedSet(flagValue)
    local list = selectedList(flagValue)
    if #list == 0 then return nil end
    local set = {}
    for _, name in ipairs(list) do set[name] = true end
    return set
end

function Target.PickMob()
    local filter = selectedSet(Flags.MobTargets)
    local candidates = Game.EnumerateNpcs(filter)
    if #candidates == 0 then return nil end

    local myRoot = root()
    if not myRoot then return nil end

    local mode = Flags.MobSort or "Nearest"
    local best, bestScore
    for _, entry in ipairs(candidates) do
        local part = modelRoot(entry.Model)
        if part then
            local score
            if mode == "Lowest HP" then
                score = entry.Humanoid.Health
            elseif mode == "Highest HP" then
                score = -entry.Humanoid.Health
            else
                score = (myRoot.Position - part.Position).Magnitude
            end
            if not bestScore or score < bestScore then
                bestScore = score
                best = entry
            end
        end
    end
    return best and best.Model or nil
end

VoidHub.Target = Target

-- ============================================================================
-- FARM JOBS
-- ============================================================================

local Jobs = {}

local function abortFarm()
    return not Flags.MasterFarmRunning
end

-- Swing / skill / instant-kill at whatever we are standing next to.
local function engage(model)
    if not model or not model.Parent then return false end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end

    -- Swing only lands on what we are pointed at, so snap the aim (and the
    -- camera, which skills use for their own targeting) first.
    local part = modelRoot(model)
    if part then
        Move.Face(part.Position)
        local cam = camera()
        if cam then
            pcall(function()
                cam.CFrame = CFrame.lookAt(cam.CFrame.Position, part.Position)
            end)
        end
    end

    if Flags.InstantKill then
        local _, status = InstantKill.Try(model)
        InstantKill.LastStatus = status or "?"
    end

    -- The combo system drops swings that arrive too quickly, so pace them.
    local now = os.clock()
    if Flags.AutoM1 ~= false and (now - (Combat.LastM1 or 0)) >= (tonumber(Flags.AttackDelay) or 0.4) then
        Combat.LastM1 = now
        Combat.M1()
    end

    if Flags.SmartAutoSkill then
        for _, label in ipairs(selectedList(Flags.SkillSlots)) do
            local index = tonumber(string.match(label, "%d+"))
            if index and Combat.SlotIsReady(index) then
                Combat.UseSlot(index)
                break
            end
        end
    end
    return true
end

VoidHub.Engage = engage

function Jobs.Mobs()
    if not Flags.AutoFarmMobs then return false end
    local model = Target.PickMob()
    if not model then Target.Status = "no mobs" return false end

    Target.Current = model
    Target.Status = "farming " .. model.Name

    local deadline = os.clock() + 30
    while Flags.MasterFarmRunning and Flags.AutoFarmMobs and os.clock() < deadline do
        if not model.Parent then break end
        local hum = model:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then break end
        if not alive() then break end

        local part = modelRoot(model)
        if not part then break end
        Move.Engage(part)
        engage(model)
        task.wait(0.12)
    end
    Target.Current = nil
    return true
end

function Jobs.Chests()
    if not Flags.AutoCollectChests then return false end
    local filter = selectedSet(Flags.ChestFilter)
    for _, chest in ipairs(World.ChestList()) do
        if not Flags.MasterFarmRunning or not Flags.AutoCollectChests then break end
        if (not filter) or filter[chest.Name] then
            Target.Status = "chest: " .. chest.Name
            Prompts.GoFire(chest.Prompt, 12, abortFarm)
            task.wait(0.4)
            return true
        end
    end
    return false
end

function Jobs.Drops()
    if not Flags.AutoPickDrops then return false end
    local drops = World.MyDrops()
    if #drops == 0 then return false end
    for _, drop in ipairs(drops) do
        if not Flags.MasterFarmRunning or not Flags.AutoPickDrops then break end
        if drop.Instance.Parent then
            Target.Status = "drop: " .. tostring(drop.Item)
            if drop.Prompt then
                Prompts.GoFire(drop.Prompt, 8, abortFarm)
            else
                Move.To(drop.Instance.Position, 8, abortFarm)
            end
            task.wait(0.25)
        end
    end
    return true
end

-- Quest tracking ------------------------------------------------------------

function Jobs.ActiveQuests()
    local holder = dataValue("Quests.Holder")
    if typeof(holder) ~= "Instance" then return {} end
    local out = {}
    for _, quest in ipairs(holder:GetChildren()) do
        local text = quest:FindFirstChild("QuestString")
        out[#out + 1] = {
            Name = quest.Name,
            Text = text and text.Value or "",
            Tasks = quest:FindFirstChild("Tasks"),
            Instance = quest,
        }
    end
    return out
end

-- A quest task usually names the mob it wants; pull that out so the farm can
-- point itself at the right thing.
local function taskTargets(quest)
    local names = {}
    if not quest.Tasks then return names end
    local known = Game.NpcNames()
    local haystack = quest.Name .. " " .. quest.Text
    for _, taskNode in ipairs(quest.Tasks:GetChildren()) do
        haystack = haystack .. " " .. taskNode.Name
        if taskNode:IsA("ValueBase") then haystack = haystack .. " " .. tostring(taskNode.Value) end
    end
    haystack = string.lower(haystack)
    for _, npcName in ipairs(known) do
        local needle = string.lower(npcName)
        if string.find(haystack, needle, 1, true) then
            names[#names + 1] = npcName
        end
        -- quests say "bandits", the mob is "Bandit"
        if string.find(haystack, needle .. "s", 1, true) then
            names[#names + 1] = npcName
        end
    end
    return names
end

Jobs.QuestTargets = taskTargets

function Jobs.Quests()
    if not Flags.AutoQuest then return false end

    local quests = Jobs.ActiveQuests()

    if #quests == 0 then
        -- Nothing active: go talk to the nearest quest giver.
        local npcs = World.StationaryNpcs()
        local myRoot = root()
        if not myRoot then return false end
        local best, bestDist
        for _, entry in pairs(npcs) do
            local prompt = World.ChatPrompt(entry.Model)
            if prompt and prompt.Enabled then
                local part = modelRoot(entry.Model)
                if part then
                    local d = (myRoot.Position - part.Position).Magnitude
                    if not bestDist or d < bestDist then
                        bestDist, best = d, prompt
                    end
                end
            end
        end
        if best then
            Target.Status = "talking to quest giver"
            Prompts.GoFire(best, 14, abortFarm)
            task.wait(0.8)
            return true
        end
        return false
    end

    -- Active quest: farm whatever it asks for.
    local quest = quests[1]
    local targets = taskTargets(quest)
    if #targets > 0 then
        Target.Status = "quest: " .. quest.Name
        local filter = {}
        for _, n in ipairs(targets) do filter[n] = true end
        local candidates = Game.EnumerateNpcs(filter)
        if #candidates > 0 then
            local model = candidates[1].Model
            local deadline = os.clock() + 25
            while Flags.MasterFarmRunning and Flags.AutoQuest and os.clock() < deadline do
                if not model.Parent then break end
                local hum = model:FindFirstChildOfClass("Humanoid")
                if not hum or hum.Health <= 0 then break end
                local part = modelRoot(model)
                if not part then break end
                Move.Engage(part)
                engage(model)
                task.wait(0.12)
            end
            return true
        end
    end

    -- Tasks look done (or unmatched): return to a giver to hand it in.
    local npcs = World.StationaryNpcs()
    for _, entry in pairs(npcs) do
        local prompt = World.ChatPrompt(entry.Model)
        if prompt and prompt.Enabled then
            Target.Status = "handing in " .. quest.Name
            Prompts.GoFire(prompt, 14, abortFarm)
            task.wait(0.8)
            return true
        end
    end
    return false
end

function Jobs.Buy()
    if not Flags.AutoBuy then return false end
    local wanted = selectedSet(Flags.BuyItems)
    if not wanted then return false end
    local shop = World.ShopItems()
    for label, prompt in pairs(shop) do
        if not Flags.MasterFarmRunning or not Flags.AutoBuy then break end
        if wanted[label] then
            Target.Status = "buying " .. label
            Prompts.GoFire(prompt, 14, abortFarm)
            task.wait(0.6)
        end
    end
    return true
end

VoidHub.Jobs = Jobs

-- ============================================================================
-- WORLD BOSSES
-- ============================================================================

local Bosses = {}

-- Bosses that only spawn after dark, so the auto-boss job can wait instead of
-- circling an empty arena.
Bosses.NightOnly = {
    ["Nezura"] = true,
    ["Gyutai"] = true,
    ["Akazo"] = true,
    ["Domae"] = true,
    ["Datai"] = true,
    ["Enru"] = true,
    ["Gyorei"] = true,
    ["Hoyuzo"] = true,
    ["Kaiden"] = true,
    ["Zuko"] = true,
    ["Yahari"] = true,
}

Bosses.WorldBossNames = {
    "Akazo", "Datai", "Domae", "Enru", "Giyen", "Gyorei", "Gyutai", "Nezura",
    "Obari", "Reaper", "Rengu", "Saneri", "Shinora", "Sumari", "Tengai",
    "Yahari", "Zentaro",
}

Bosses.RegionBossNames = { "Hoyuzo", "Kaiden", "Mother Bear", "Zuko", "Fujiko" }

Bosses.State = {}   -- [name] = { LastSeen = clock, LastDead = clock, Alive = bool }

function Bosses.All()
    local list = Game.Bosses()
    local out = {}
    for _, entry in ipairs(list) do
        local category = "Mini Boss"
        if table.find(Bosses.WorldBossNames, entry.Name) then
            category = "World Boss"
        elseif table.find(Bosses.RegionBossNames, entry.Name) then
            category = "Region Boss"
        end
        out[#out + 1] = {
            Name = entry.Name,
            Code = entry.Code,
            Icon = entry.Icon,
            Position = entry.Position,
            Category = category,
        }
    end
    table.sort(out, function(a, b)
        if a.Category ~= b.Category then return a.Category < b.Category end
        return a.Name < b.Name
    end)
    return out
end

function Bosses.Names()
    local out = {}
    for _, b in ipairs(Bosses.All()) do
        out[#out + 1] = string.format("[%s] %s", b.Category == "World Boss" and "W"
            or b.Category == "Region Boss" and "R" or "M", b.Name)
    end
    return out
end

local function stripBossLabel(label)
    return (string.gsub(tostring(label), "^%[%a%]%s*", ""))
end
Bosses.StripLabel = stripBossLabel

function Bosses.Model(name)
    return Game.FindNpc(name)
end

function Bosses.IsUp(name)
    return Bosses.Model(name) ~= nil
end

function Bosses.SpawnPosition(name)
    for _, entry in ipairs(Bosses.All()) do
        if entry.Name == name then return toVector(entry.Position) end
    end
    return nil
end

-- The place streams, so a boss we cannot see might simply be too far away.
-- Only trust an "up" or "down" reading when we are close enough for the model
-- to have replicated.
Bosses.StreamRadius = 400

function Bosses.InStreamRange(name)
    local pos = Bosses.SpawnPosition(name)
    local myRoot = root()
    if not pos or not myRoot then return false end
    return (myRoot.Position - pos).Magnitude <= Bosses.StreamRadius
end

-- Called every second so the timer column can show something real.
function Bosses.Poll()
    for _, entry in ipairs(Bosses.All()) do
        local state = Bosses.State[entry.Name]
        if not state then
            state = { Alive = false }
            Bosses.State[entry.Name] = state
        end
        local up = Bosses.IsUp(entry.Name)
        if (not up) and (not Bosses.InStreamRange(entry.Name)) then
            state.OutOfRange = true
        else
            state.OutOfRange = false
        end
        if state.OutOfRange then
            -- nothing reliable to record from here
        elseif up and not state.Alive then
            state.Alive = true
            state.SpawnedAt = os.clock()
            if state.DiedAt then state.LastRespawn = state.SpawnedAt - state.DiedAt end
            if Flags.WebhookBoss then
                VoidHub.Webhook.BossSpawn(entry)
            end
        elseif (not up) and state.Alive then
            state.Alive = false
            state.DiedAt = os.clock()
        end
    end
end

function Bosses.TimerText(name)
    local state = Bosses.State[name]
    if not state then return "unknown" end
    if Bosses.IsUp(name) then
        return "UP" .. (state.SpawnedAt and (" (" .. formatClock(os.clock() - state.SpawnedAt) .. ")") or "")
    end
    if state.OutOfRange then
        return "out of range"
    end
    if state.DiedAt then
        local waited = os.clock() - state.DiedAt
        if state.LastRespawn then
            local left = state.LastRespawn - waited
            if left > 0 then return "in ~" .. formatClock(left) end
        end
        return "down " .. formatClock(waited)
    end
    return "not seen"
end

function Bosses.DayNightText()
    local night = Game.IsNight()
    local secs = Game.SecondsUntilPhaseChange()
    local phase = night and "Night" or "Day"
    if secs and secs >= 0 then
        return string.format("%s - %s until %s", phase, formatClock(secs), night and "day" or "night")
    end
    return phase
end

-- Opens the chest a boss leaves behind and takes what is inside.
function Bosses.LootChests()
    if not Flags.OpenBossChests then return false end
    local folder = Workspace:FindFirstChild("Chests")
    if not folder then return false end
    for _, chest in ipairs(folder:GetChildren()) do
        local prompt = Prompts.FindIn(chest)
        if prompt and distanceTo(chest) < 250 then
            Prompts.GoFire(prompt, 10, abortFarm)
            task.wait(0.5)
            -- Drops land as loot parts right after; sweep them up.
            for _, drop in ipairs(World.MyDrops()) do
                if drop.Prompt then Prompts.GoFire(drop.Prompt, 6, abortFarm) end
            end
            return true
        end
    end
    return false
end

function Bosses.Job()
    if not Flags.AutoWorldBosses then return false end
    local names = {}
    for _, label in ipairs(selectedList(Flags.BossPicker)) do
        names[#names + 1] = stripBossLabel(label)
    end
    if #names == 0 then Target.Status = "no boss picked" return false end

    for _, name in ipairs(names) do
        if not Flags.MasterFarmRunning or not Flags.AutoWorldBosses then break end
        if Bosses.NightOnly[name] and not Game.IsNight() and not Bosses.IsUp(name) then
            Target.Status = name .. ": waiting for night"
        else
            -- Under streaming a boss only exists on our client once we are
            -- near its arena, so go and look before deciding it is down.
            if not Bosses.IsUp(name) and not Bosses.InStreamRange(name) then
                local spawn = Bosses.SpawnPosition(name)
                if spawn then
                    Target.Status = "checking " .. name
                    Move.Teleport(CFrame.new(spawn + Vector3.new(0, 12, 0)))
                    task.wait(2.5)
                end
            end
            local model = Bosses.Model(name)
            if model then
                Target.Status = "boss: " .. name
                local deadline = os.clock() + 120
                while Flags.MasterFarmRunning and Flags.AutoWorldBosses and os.clock() < deadline do
                    if not model.Parent then break end
                    local hum = model:FindFirstChildOfClass("Humanoid")
                    if not hum or hum.Health <= 0 then break end
                    if not alive() then break end
                    local part = modelRoot(model)
                    if not part then break end
                    Move.Engage(part)
                    engage(model)
                    task.wait(0.12)
                end
                task.wait(0.5)
                Bosses.LootChests()
                return true
            end
        end
    end
    return false
end

VoidHub.Bosses = Bosses

-- ============================================================================
-- MASTER FARM LOOP (job priority)
-- ============================================================================

local Farm = {}
Farm.DefaultOrder = { "World Bosses", "Chests", "Quests", "Mobs" }

function Farm.Order()
    local order = {}
    for i = 1, 4 do
        local v = Flags["Priority" .. i]
        if type(v) == "string" and v ~= "" and not table.find(order, v) then
            order[#order + 1] = v
        end
    end
    for _, v in ipairs(Farm.DefaultOrder) do
        if not table.find(order, v) then order[#order + 1] = v end
    end
    return order
end

local jobHandlers = {
    ["World Bosses"] = function() return Bosses.Job() end,
    ["Chests"]       = function() return Jobs.Chests() end,
    ["Quests"]       = function() return Jobs.Quests() end,
    ["Mobs"]         = function() return Jobs.Mobs() end,
}

function Farm.AnyEnabled()
    return Flags.AutoWorldBosses or Flags.AutoCollectChests or Flags.AutoQuest
        or Flags.AutoFarmMobs or Flags.AutoPickDrops or Flags.AutoBuy
end

function Farm.Refresh()
    local shouldRun = Farm.AnyEnabled()
    Flags.MasterFarmRunning = shouldRun
    if not shouldRun then
        stopThread("farm")
        Target.Status = "idle"
        return
    end
    if Threads.farm then return end
    startThread("farm", function()
        while Threads.farm and Flags.MasterFarmRunning do
            local didWork = false
            Jobs.Drops()
            Jobs.Buy()
            for _, jobName in ipairs(Farm.Order()) do
                if not Flags.MasterFarmRunning then break end
                local handler = jobHandlers[jobName]
                if handler then
                    local ok, result = pcall(handler)
                    if ok and result then didWork = true break end
                end
            end
            if not didWork then
                Target.Status = "waiting"
                task.wait(1)
            else
                task.wait(0.2)
            end
        end
        Target.Status = "idle"
    end)
end

-- "1 Click Level Up": farm until the exp goal moves, then stop.
function Farm.OneClickLevel()
    if Threads.levelup then stopThread("levelup") return end
    startThread("levelup", function()
        local _, startGoal = Game.Exp()
        local previousMobs = Flags.AutoFarmMobs
        Flags.AutoFarmMobs = true
        Farm.Refresh()
        VoidHub.Notify("1 Click Level Up", "Farming until the next level.", 4)
        local deadline = os.clock() + 600
        while Threads.levelup and os.clock() < deadline do
            local _, goal = Game.Exp()
            if goal ~= startGoal and goal > 0 then break end
            task.wait(0.5)
        end
        Flags.AutoFarmMobs = previousMobs
        Farm.Refresh()
        VoidHub.Notify("1 Click Level Up", "Level gained.", 4)
        Threads.levelup = nil
    end)
end

VoidHub.Farm = Farm

-- ============================================================================
-- AUTO ACCEPT (dialogue / confirmation popups)
-- ============================================================================

local AutoAccept = {}
AutoAccept.Words = { "accept", "yes", "confirm", "continue", "ok", "claim", "take", "next", "start" }

local function looksAccepting(text)
    text = string.lower(tostring(text))
    for _, word in ipairs(AutoAccept.Words) do
        if text == word or string.find(text, word, 1, true) then return true end
    end
    return false
end

function AutoAccept.Tick()
    local gui = LocalPlayer:FindFirstChild("PlayerGui")
    if not gui then return end
    for _, screen in ipairs(gui:GetChildren()) do
        if screen:IsA("ScreenGui") and screen.Enabled and screen.Name ~= "VoidHubESP" then
            for _, d in ipairs(screen:GetDescendants()) do
                if d:IsA("GuiButton") and d.Visible and d.AbsoluteSize.X > 0 then
                    local label = d:IsA("TextButton") and d.Text or d.Name
                    if looksAccepting(label) then
                        local ancestorsVisible = true
                        local node = d.Parent
                        while node and node:IsA("GuiObject") do
                            if not node.Visible then ancestorsVisible = false break end
                            node = node.Parent
                        end
                        if ancestorsVisible then
                            -- The game's own buttons react to InputBegan, the
                            -- Roblox defaults to Activated; press both.
                            tapGui(d, 0)
                            pcall(function()
                                if firesignal then
                                    firesignal(d.MouseButton1Click)
                                    firesignal(d.Activated)
                                end
                            end)
                            return
                        end
                    end
                end
            end
        end
    end
end

VoidHub.AutoAccept = AutoAccept

-- ============================================================================
-- TRAINER TRIALS
-- ============================================================================

local Trainer = {}

function Trainer.Run()
    if not Flags.AutoTrial then return end
    local spots = World.TrainingSpots()
    if #spots == 0 then return end
    local wanted = selectedSet(Flags.TrialPicker)
    for _, spot in ipairs(spots) do
        if not Flags.AutoTrial then break end
        if (not wanted) or wanted[spot.Name] then
            Target.Status = "trial: " .. spot.Name
            -- Go to the listed position first; the trial only streams in (and
            -- gets its prompt) once we are standing on top of it.
            if spot.Position then
                Move.Teleport(CFrame.new(spot.Position + Vector3.new(0, 5, 0)))
                task.wait(1.5)
            elseif spot.Model then
                Move.ToTarget(spot.Model, 20, function() return not Flags.AutoTrial end)
            end

            local folder = Workspace:FindFirstChild("Training")
            local model = spot.Model
            if not model and folder then
                model = folder:FindFirstChild(spot.Name)
                if not model then
                    for alias, canonical in pairs(World.TrainingAliases) do
                        if canonical == spot.Name then
                            model = folder:FindFirstChild(alias)
                            if model then break end
                        end
                    end
                end
            end
            local prompt = spot.Prompt
                or (model and Prompts.FindIn(model, function(p) return p.ActionText == "Train" end))
            spot.Prompt = prompt
            if prompt then Prompts.Fire(prompt) end
            -- Trials run as their own GUI mini-game. Drive it by taking every
            -- step the trial puts in front of us until it closes itself.
            local deadline = os.clock() + 90
            while Flags.AutoTrial and os.clock() < deadline do
                AutoAccept.Tick()
                Trainer.Step(spot.Name)
                if spot.Prompt and spot.Prompt.Enabled then
                    Prompts.Fire(spot.Prompt)
                end
                task.wait(0.4)
            end
            task.wait(0.5)
        end
    end
end

-- Per-trial input. The physical trials want repeated taps; the aim trial wants
-- the target clicked; the meditation trial just wants you to stand still.
function Trainer.Step(trialName)
    if trialName == "Meditation" then
        return
    end
    if trialName == "Aim Training" then
        local folder = Workspace:FindFirstChild("Training")
        local spot = folder and folder:FindFirstChild("Aim Training")
        if spot then
            for _, d in ipairs(spot:GetDescendants()) do
                if d:IsA("BasePart") and d.Name:lower():find("target") and d.Transparency < 1 then
                    local myRoot = root()
                    if myRoot then
                        pcall(function()
                            camera().CFrame = CFrame.lookAt(camera().CFrame.Position, d.Position)
                        end)
                    end
                    Combat.M1()
                    return
                end
            end
        end
        return
    end
    -- Boulder Push / Boulder Split / Pushups / Squat Rack / Cup Game / Parkour
    Combat.M1()
end

VoidHub.Trainer = Trainer

-- ============================================================================
-- AUTO PARRY / AUTO BLOCK
-- ============================================================================

local Defence = {}
Defence.WatchedAnimators = setmetatable({}, { __mode = "k" })

local function enemiesNear(radius)
    local myRoot = root()
    if not myRoot then return {} end
    local out = {}
    for _, entry in ipairs(Game.EnumerateNpcs(nil)) do
        local part = modelRoot(entry.Model)
        if part and (part.Position - myRoot.Position).Magnitude <= radius then
            out[#out + 1] = entry.Model
        end
    end
    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= LocalPlayer and other.Character then
            local part = modelRoot(other.Character)
            if part and (part.Position - myRoot.Position).Magnitude <= radius then
                out[#out + 1] = other.Character
            end
        end
    end
    return out
end

Defence.EnemiesNear = enemiesNear

-- Parry is a block timed to somebody else's swing, so listen for the swing.
local function watchAnimator(model)
    local hum = model:FindFirstChildOfClass("Humanoid")
    local animator = hum and hum:FindFirstChildOfClass("Animator")
    if not animator or Defence.WatchedAnimators[animator] then return end
    Defence.WatchedAnimators[animator] = animator.AnimationPlayed:Connect(function()
        if not Flags.AutoParry then return end
        local myRoot = root()
        local part = modelRoot(model)
        if not myRoot or not part then return end
        local range = tonumber(Flags.ParryRange) or 16
        if (myRoot.Position - part.Position).Magnitude > range then return end
        -- Only parry things pointed at us.
        local toMe = (myRoot.Position - part.Position).Unit
        if toMe:Dot(part.CFrame.LookVector) < 0.25 then return end
        task.wait(tonumber(Flags.ParryDelay) or 0.08)
        Combat.Parry(tonumber(Flags.ParryHold) or 0.35)
    end)
end

function Defence.Tick()
    if Flags.AutoParry then
        for _, model in ipairs(enemiesNear(tonumber(Flags.ParryRange) or 16)) do
            watchAnimator(model)
        end
    end
    if Flags.AutoBlock then
        local near = #enemiesNear(tonumber(Flags.BlockRange) or 14) > 0
        Combat.SetBlock(near)
    elseif Combat.Blocking and not Flags.AutoParry then
        Combat.SetBlock(false)
    end
end

VoidHub.Defence = Defence

-- ============================================================================
-- PLAYER
-- ============================================================================

local Player = {}

function Player.ApplyWalkSpeed()
    local hum = humanoid()
    if not hum then return end
    if Flags.WalkSpeedEnabled then
        hum.WalkSpeed = tonumber(Flags.WalkSpeed) or 16
    end
end

-- The game's own movement script rewrites WalkSpeed constantly, so this has to
-- be reapplied every frame rather than on a timer.
function Player.SetWalkSpeed(enabled)
    Flags.WalkSpeedEnabled = enabled
    if enabled then
        connect("walkspeed", RunService.RenderStepped, Player.ApplyWalkSpeed)
    else
        disconnect("walkspeed")
        local hum = humanoid()
        if hum then hum.WalkSpeed = 16 end
    end
end

-- Fly ------------------------------------------------------------------------

Player.FlyParts = nil

local function stopFly()
    if Player.FlyParts then
        pcall(function()
            if Player.FlyParts.BV then Player.FlyParts.BV:Destroy() end
            if Player.FlyParts.BG then Player.FlyParts.BG:Destroy() end
        end)
        Player.FlyParts = nil
    end
    disconnect("flyStep")
    local hum = humanoid()
    if hum then
        pcall(function() hum.PlatformStand = false end)
    end
end

function Player.SetFly(enabled)
    Flags.FlyEnabled = enabled
    if not enabled then stopFly() return end

    local myRoot = root()
    if not myRoot then return end
    stopFly()

    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    bv.Velocity = Vector3.zero
    bv.Parent = myRoot

    local bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    bg.P = 9e4
    bg.CFrame = myRoot.CFrame
    bg.Parent = myRoot

    Player.FlyParts = { BV = bv, BG = bg }

    connect("flyStep", RunService.RenderStepped, function()
        if not Flags.FlyEnabled then return end
        local currentRoot = root()
        if not currentRoot or not bv.Parent then return end

        local speed = tonumber(Flags.FlySpeed) or 60
        local direction = Vector3.zero
        local camCF = camera().CFrame

        -- Keyboard, when there is one.
        if UserInputService.KeyboardEnabled then
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then direction += camCF.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then direction -= camCF.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then direction -= camCF.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then direction += camCF.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then direction += Vector3.yAxis end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then direction -= Vector3.yAxis end
        end

        -- Touch: the thumbstick already moves the humanoid, so follow it.
        local hum = humanoid()
        if hum and hum.MoveDirection.Magnitude > 0 then
            direction += hum.MoveDirection
        end
        if hum and hum.Jump then
            direction += Vector3.yAxis
        end

        if direction.Magnitude > 0 then
            bv.Velocity = direction.Unit * speed
        else
            bv.Velocity = Vector3.zero
        end
        bg.CFrame = camCF
    end)
end

-- Infinite jump ---------------------------------------------------------------

function Player.SetInfiniteJump(enabled)
    Flags.InfiniteJump = enabled
    if not enabled then disconnect("infjump") return end
    connect("infjump", UserInputService.JumpRequest, function()
        if not Flags.InfiniteJump then return end
        local hum = humanoid()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end)
end

-- Noclip ----------------------------------------------------------------------

function Player.SetNoclip(enabled)
    Flags.Noclip = enabled
    if not enabled then
        disconnect("noclip")
        local char = character()
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide == false and part.Name ~= "HumanoidRootPart" then
                    part.CanCollide = true
                end
            end
        end
        return
    end
    connect("noclip", RunService.Stepped, function()
        if not Flags.Noclip then return end
        local char = character()
        if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end)
end

VoidHub.Player = Player

-- ============================================================================
-- TRAVEL
-- ============================================================================

local Travel = {}

function Travel.NpcList()
    local out, seen = {}, {}
    for name, pos in pairs(Game.NpcSpawns()) do
        if not seen[name] then
            seen[name] = true
            out[#out + 1] = name
        end
    end
    for name in pairs(World.StationaryNpcs()) do
        if not seen[name] then
            seen[name] = true
            out[#out + 1] = name
        end
    end
    table.sort(out)
    return out
end

Travel.ToVector = toVector

function Travel.NpcPosition(name)
    local spawns = Game.NpcSpawns()
    local direct = spawns[name]
    local vec = toVector(direct)
    if vec then return vec end
    if Game.Regions and Game.Regions.GetNpcSpawn then
        local ok, res = pcall(Game.Regions.GetNpcSpawn, name)
        if ok then
            vec = toVector(res)
            if vec then return vec end
        end
    end
    local stationary = World.StationaryNpcs()[name]
    if stationary then
        local part = modelRoot(stationary.Model)
        if part then return part.Position end
    end
    local live = Game.FindNpc(name)
    if live then
        local part = modelRoot(live)
        if part then return part.Position end
    end
    return nil
end

function Travel.ToNpc(name)
    local pos = Travel.NpcPosition(name)
    if not pos then
        VoidHub.Notify("Teleport", "No spawn point known for " .. tostring(name), 4)
        return false
    end
    Move.Teleport(CFrame.new(pos + Vector3.new(0, 5, 0)))
    return true
end

-- Places: spawn crystals, region centres, shrines, training spots, boss spawns.
function Travel.PlaceList()
    local out = {}
    local function add(label, pos)
        if pos then out[#out + 1] = { Label = label, Position = pos } end
    end

    -- Region spawn crystals come from the game's own region table rather than
    -- the workspace: the map streams, so a distant crystal model has no parts
    -- to read a position from.
    local regionTable = (Game.Regions and Game.Regions.Regions) or {}
    for name, info in pairs(regionTable) do
        if type(info) == "table" and info.CrystalAt then
            add("Crystal - " .. tostring(info.Name or name), toVector(info.CrystalAt))
        end
    end

    for _, shrine in ipairs(World.Shrines()) do
        add("Shrine - " .. shrine.Name, shrine.Position)
    end

    for _, spot in ipairs(World.TrainingSpots()) do
        local part = spot.Model and modelRoot(spot.Model)
        add("Training - " .. spot.Name, spot.Position or (part and part.Position))
    end

    for _, boss in ipairs(Bosses.All()) do
        add("Boss - " .. boss.Name, toVector(boss.Position))
    end

    table.sort(out, function(a, b) return a.Label < b.Label end)
    return out
end

function Travel.PlaceLabels()
    local out = {}
    for _, entry in ipairs(Travel.PlaceList()) do out[#out + 1] = entry.Label end
    return out
end

function Travel.ToPlace(label)
    for _, entry in ipairs(Travel.PlaceList()) do
        if entry.Label == label then
            Move.Teleport(CFrame.new(entry.Position + Vector3.new(0, 6, 0)))
            return true
        end
    end
    VoidHub.Notify("Teleport", "Unknown place: " .. tostring(label), 4)
    return false
end

VoidHub.Travel = Travel

-- ============================================================================
-- ESP
-- ============================================================================

local ESP = {}
ESP.Entries = {}
ESP.Gui = nil

local ESP_TAG = "VoidHubESP"

local function espGui()
    if ESP.Gui and ESP.Gui.Parent then return ESP.Gui end
    local gui = Instance.new("ScreenGui")
    gui.Name = ESP_TAG
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 9999
    safeParentGui(gui)
    ESP.Gui = gui
    return gui
end

local function newEntry(model)
    local gui = espGui()

    local box = Instance.new("Frame")
    box.Name = "Box"
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.AnchorPoint = Vector2.new(0.5, 0.5)
    box.Visible = false
    box.Parent = gui
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1.5
    stroke.Color = Flags.ESPColor or Color3.fromRGB(120, 200, 255)
    stroke.Parent = box

    local tracer = Instance.new("Frame")
    tracer.Name = "Tracer"
    tracer.BorderSizePixel = 0
    tracer.AnchorPoint = Vector2.new(0.5, 0)
    tracer.Size = UDim2.fromOffset(1, 0)
    tracer.BackgroundColor3 = Flags.ESPColor or Color3.fromRGB(120, 200, 255)
    tracer.Visible = false
    tracer.Parent = gui

    local label = Instance.new("TextLabel")
    label.Name = "Info"
    label.BackgroundTransparency = 1
    label.AnchorPoint = Vector2.new(0.5, 1)
    label.Size = UDim2.fromOffset(220, 42)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 13
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextStrokeTransparency = 0.4
    label.RichText = true
    label.Visible = false
    label.Parent = gui

    local highlight
    if Flags.ChamsESP then
        highlight = Instance.new("Highlight")
        highlight.Name = ESP_TAG .. "Chams"
        highlight.FillColor = Flags.ESPColor or Color3.fromRGB(120, 200, 255)
        highlight.FillTransparency = 0.6
        highlight.OutlineTransparency = 0
        highlight.Adornee = model
        highlight.Parent = gui
    end

    return { Model = model, Box = box, Tracer = tracer, Label = label, Highlight = highlight, Stroke = stroke }
end

local function destroyEntry(entry)
    for _, key in ipairs({ "Box", "Tracer", "Label", "Highlight" }) do
        local obj = entry[key]
        if obj then pcall(function() obj:Destroy() end) end
    end
end

function ESP.Clear()
    for model, entry in pairs(ESP.Entries) do
        destroyEntry(entry)
        ESP.Entries[model] = nil
    end
end

-- Everything the ESP options currently ask to see.
-- Only the things close enough to draw. Filtering here keeps the per-frame
-- table small even when the map holds hundreds of flowers.
function ESP.Collect()
    local out = {}
    local myRoot = root()
    if not myRoot then return out end
    local origin = myRoot.Position
    local maxDistance = Flags.NoMaxDistance and math.huge or (tonumber(Flags.ESPDistance) or 250)

    local function add(model, kind, name, hum)
        local part = modelRoot(model)
        if not part then return end
        if (origin - part.Position).Magnitude > maxDistance then return end
        out[#out + 1] = { Model = model, Kind = kind, Name = name, Humanoid = hum, Part = part }
    end

    if Flags.MobESP then
        local filter = selectedSet(Flags.ESPMobs)
        for _, entry in ipairs(Game.EnumerateNpcs(filter)) do
            add(entry.Model, "Mob", entry.Model.Name, entry.Humanoid)
        end
    end

    if Flags.ItemESP then
        local folder = Workspace:FindFirstChild("LootDrops")
        if folder then
            for _, drop in ipairs(folder:GetChildren()) do
                add(drop, "Drop", tostring(drop:GetAttribute("DropItemId") or "Drop"))
            end
        end
        for _, chest in ipairs(World.ChestList()) do
            add(chest.Model, "Chest", chest.Name)
        end
        local quests = Workspace:FindFirstChild("Map")
        quests = quests and quests:FindFirstChild("Puzzles")
        if quests then
            for _, item in ipairs(quests:GetChildren()) do
                add(item, "Quest", item.Name)
            end
        end
    end

    if Flags.FlowerESP then
        -- Scanning the whole workspace every frame would tank the framerate, so
        -- the flower list is rebuilt on a timer instead.
        if (not ESP.FlowerCacheAt) or (os.clock() - ESP.FlowerCacheAt) > 5 then
            ESP.FlowerCacheAt = os.clock()
            local found = {}
            for _, d in ipairs(Workspace:GetDescendants()) do
                local lower = string.lower(d.Name)
                if (d:IsA("Model") or d:IsA("BasePart"))
                    and (string.find(lower, "flower", 1, true) or string.find(lower, "lily", 1, true)) then
                    found[#found + 1] = d
                end
            end
            ESP.FlowerCache = found
        end
        for _, d in ipairs(ESP.FlowerCache or {}) do
            if d.Parent then
                add(d, "Flower", d.Name)
            end
        end
    end

    return out
end

function ESP.Render()
    local myRoot = root()
    local cam = camera()
    if not myRoot or not cam then return end
    local maxDistance = Flags.NoMaxDistance and math.huge or (tonumber(Flags.ESPDistance) or 250)

    local wanted, seen = ESP.Collect(), {}

    for _, item in ipairs(wanted) do
        local model = item.Model
        local part = item.Part or modelRoot(model)
        if part and model.Parent then
            local dist = (myRoot.Position - part.Position).Magnitude
            if dist <= maxDistance then
                seen[model] = true
                local entry = ESP.Entries[model]
                if not entry then
                    entry = newEntry(model)
                    ESP.Entries[model] = entry
                end

                local screenPos, onScreen = cam:WorldToViewportPoint(part.Position)
                local colour = Flags.ESPColor or Color3.fromRGB(120, 200, 255)
                entry.Stroke.Color = colour
                entry.Tracer.BackgroundColor3 = colour
                if entry.Highlight then entry.Highlight.FillColor = colour end

                if onScreen then
                    local size = (model:IsA("Model") and model:GetExtentsSize()) or part.Size
                    local scale = math.clamp(1200 / math.max(screenPos.Z, 1), 12, 400)
                    local width = math.clamp(size.X * scale * 0.08, 18, 260)
                    local height = math.clamp(size.Y * scale * 0.08, 24, 320)

                    entry.Box.Visible = Flags.BoxESP == true
                    entry.Box.Position = UDim2.fromOffset(screenPos.X, screenPos.Y)
                    entry.Box.Size = UDim2.fromOffset(width, height)

                    entry.Tracer.Visible = Flags.TracerESP == true
                    if Flags.TracerESP then
                        local origin = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y)
                        local delta = Vector2.new(screenPos.X, screenPos.Y) - origin
                        entry.Tracer.Position = UDim2.fromOffset(origin.X, origin.Y)
                        entry.Tracer.Size = UDim2.fromOffset(1, delta.Magnitude)
                        entry.Tracer.Rotation = math.deg(math.atan2(delta.X, -delta.Y))
                        entry.Tracer.AnchorPoint = Vector2.new(0.5, 0)
                    end

                    local lines = {}
                    if Flags.NameESP then lines[#lines + 1] = item.Name end
                    if Flags.HealthESP and item.Humanoid then
                        lines[#lines + 1] = string.format("%d / %d HP",
                            math.floor(item.Humanoid.Health), math.floor(item.Humanoid.MaxHealth))
                    end
                    if Flags.DistanceESP then lines[#lines + 1] = string.format("%dm", math.floor(dist)) end

                    if #lines > 0 then
                        entry.Label.Visible = true
                        entry.Label.Text = table.concat(lines, "\n")
                        entry.Label.TextColor3 = colour
                        entry.Label.Position = UDim2.fromOffset(screenPos.X, screenPos.Y - height / 2 - 2)
                    else
                        entry.Label.Visible = false
                    end
                else
                    entry.Box.Visible = false
                    entry.Tracer.Visible = false
                    entry.Label.Visible = false
                end
            end
        end
    end

    for model, entry in pairs(ESP.Entries) do
        if not seen[model] then
            destroyEntry(entry)
            ESP.Entries[model] = nil
        end
    end
end

function ESP.Refresh()
    local on = Flags.MobESP or Flags.ItemESP or Flags.FlowerESP
    if not on then
        disconnect("esp")
        ESP.Clear()
        return
    end
    connect("esp", RunService.RenderStepped, function()
        local ok, err = pcall(ESP.Render)
        if not ok then warn("[VoidHub] ESP: " .. tostring(err)) end
    end)
end

VoidHub.ESP = ESP

-- ============================================================================
-- WEBHOOK
-- ============================================================================

local Webhook = {}
Webhook.RarityOrder = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Supreme" }

function Webhook.RarityIndex(name)
    local index = table.find(Webhook.RarityOrder, tostring(name))
    return index or 1
end

-- Rarity of an item id, when the game knows it.
function Webhook.RarityOf(itemId)
    if not Game.Rarities then return nil end
    local rarities = Game.Rarities
    if type(rarities) == "table" then
        local direct = rarities[itemId]
        if type(direct) == "string" then return direct end
        if type(direct) == "table" and direct.Name then return direct.Name end
    end
    return nil
end

function Webhook.Send(payload)
    local url = Flags.WebhookUrl
    if type(url) ~= "string" or url == "" then return false end
    if not httpRequest then return false end
    if Flags.DiscordPing and Flags.DiscordPingId and Flags.DiscordPingId ~= "" then
        payload.content = "<@" .. tostring(Flags.DiscordPingId) .. ">"
    elseif Flags.DiscordPing then
        payload.content = "@everyone"
    end
    task.spawn(function()
        pcall(function()
            httpRequest({
                Url = url,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = HttpService:JSONEncode(payload),
            })
        end)
    end)
    return true
end

local function embed(title, description, colour, fields)
    return {
        username = "VoidHub",
        embeds = { {
            title = title,
            description = description,
            color = colour or 0x7B5CFF,
            fields = fields,
            footer = { text = "VoidHub : Ouwland - " .. LocalPlayer.Name },
        } },
    }
end

function Webhook.Drop(itemName, rarity)
    if not Flags.WebhookDrops then return end
    local minimum = Flags.WebhookMinRarity or "Common"
    if Webhook.RarityIndex(rarity or "Common") < Webhook.RarityIndex(minimum) then return end
    Webhook.Send(embed("Drop", "**" .. tostring(itemName) .. "**", 0x4CC2FF, {
        { name = "Rarity", value = tostring(rarity or "Unknown"), inline = true },
        { name = "Job ID", value = tostring(game.JobId), inline = false },
    }))
end

function Webhook.LevelUp(goal)
    if not Flags.WebhookLevel then return end
    Webhook.Send(embed("Level Up", "Exp goal is now **" .. commaNumber(goal) .. "**", 0x4CFF9B))
end

function Webhook.BossSpawn(boss)
    if not Flags.WebhookBoss then return end
    local picked = selectedList(Flags.WebhookBossPicker)
    if #picked > 0 then
        local match = false
        for _, label in ipairs(picked) do
            if Bosses.StripLabel(label) == boss.Name then match = true break end
        end
        if not match then return end
    end
    Webhook.Send(embed("Boss Spawned", "**" .. boss.Name .. "** (" .. boss.Category .. ")", 0xFF6B6B, {
        { name = "Job ID", value = tostring(game.JobId), inline = false },
    }))
end

-- Watchers -------------------------------------------------------------------

function Webhook.Start()
    local lastGoal = select(2, Game.Exp())
    local knownDrops = {}

    setLoop("webhook", true, 1, function()
        local _, goal = Game.Exp()
        if goal ~= lastGoal and goal > 0 then
            lastGoal = goal
            Webhook.LevelUp(goal)
        end

        local folder = Workspace:FindFirstChild("LootDrops")
        if folder and Flags.WebhookDrops then
            for _, drop in ipairs(folder:GetChildren()) do
                if not knownDrops[drop] then
                    knownDrops[drop] = true
                    local owner = drop:GetAttribute("DropOwnerUserId")
                    if (not owner) or tonumber(owner) == LocalPlayer.UserId then
                        local item = drop:GetAttribute("DropItemId") or drop.Name
                        Webhook.Drop(item, Webhook.RarityOf(item))
                    end
                end
            end
        end
    end)
end

VoidHub.Webhook = Webhook

-- ============================================================================
-- MISC
-- ============================================================================

local Misc = {}

-- Ouwland is a group game, so a player's rank in the developer group is the
-- honest signal. Rank 1 is just "joined the group", which is why the threshold
-- is a slider rather than "any rank at all".
function Misc.StaffIn(player)
    if game.CreatorType ~= Enum.CreatorType.Group then return false, 0 end
    local ok, rank = pcall(function() return player:GetRankInGroup(game.CreatorId) end)
    if not ok or type(rank) ~= "number" then return false, 0 end
    return rank >= (tonumber(Flags.StaffMinRank) or 20), rank
end

function Misc.ScanStaff(announce)
    local found = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local isStaff, rank = Misc.StaffIn(player)
            if isStaff then
                found[#found + 1] = player.Name .. " (rank " .. rank .. ")"
            end
        end
    end
    if announce and #found > 0 then
        VoidHub.Notify("Staff Detected", table.concat(found, ", "), 8)
        if Flags.WebhookUrl ~= "" then
            Webhook.Send(embed("Staff Detected", table.concat(found, "\n"), 0xFFB020))
        end
    end
    return found
end

function Misc.SetStaffDetector(enabled)
    Flags.StaffDetector = enabled
    if not enabled then
        disconnect("staffAdded")
        return
    end
    Misc.ScanStaff(true)
    connect("staffAdded", Players.PlayerAdded, function(player)
        task.wait(1)
        if not Flags.StaffDetector then return end
        local isStaff, rank = Misc.StaffIn(player)
        if isStaff then
            VoidHub.Notify("Staff Joined", player.Name .. " (rank " .. rank .. ")", 8)
        end
    end)
end

function Misc.SetHideName(enabled)
    Flags.HideName = enabled
    local gui = LocalPlayer:FindFirstChild("PlayerGui")
    local ucs = gui and gui:FindFirstChild("UCS")
    local watermark = ucs and ucs:FindFirstChild("Watermark")
    if watermark and watermark:IsA("ScreenGui") then
        watermark.Enabled = not enabled
    end
    local char = character()
    local overhead = char and char:FindFirstChild("OverHead")
    if overhead and overhead:IsA("BillboardGui") then
        overhead.Enabled = not enabled
    end
end

function Misc.SetAntiAfk(enabled)
    Flags.AntiAFK = enabled
    if not enabled then disconnect("antiafk") return end
    connect("antiafk", LocalPlayer.Idled, function()
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
            task.wait(0.1)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
        end)
    end)
end

Misc.AutoExecuteFile = "voidhub_v1/autoexec.txt"

function Misc.SaveAutoExecute(url)
    if not writefile then return false end
    pcall(function()
        if makefolder and not (isfolder and isfolder("voidhub_v1")) then makefolder("voidhub_v1") end
        writefile(Misc.AutoExecuteFile, tostring(url or ""))
    end)
    return true
end

function Misc.QueueAutoExecute()
    if not Flags.AutoExecute then return end
    local url = Flags.ExecuteUrl
    if type(url) ~= "string" or url == "" then return end
    if not queueTeleport then return end
    pcall(queueTeleport, ([[
        task.wait(4)
        local ok, err = pcall(function()
            loadstring(game:HttpGet("%s"))()
        end)
        if not ok then warn("[VoidHub] auto execute failed: " .. tostring(err)) end
    ]]):format(url))
end

-- Roblox shows the disconnect prompt by parenting an ErrorPrompt under
-- CoreGui, so that is what we watch for.
function Misc.SetAutoReconnect(enabled)
    Flags.AutoReconnect = enabled
    if not enabled then
        disconnect("reconnect")
        disconnect("reconnectCore")
        return
    end

    local function rejoin()
        if not Flags.AutoReconnect then return end
        Misc.QueueAutoExecute()
        task.wait(1)
        pcall(function()
            if #Players:GetPlayers() <= 1 then
                TeleportService:Teleport(game.PlaceId, LocalPlayer)
            else
                TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
            end
        end)
    end

    local ok = pcall(function()
        connect("reconnectCore", CoreGui.DescendantAdded, function(d)
            if not Flags.AutoReconnect then return end
            if d.Name == "ErrorPrompt" or d.Name == "ErrorTitle" then
                task.spawn(rejoin)
            end
        end)
    end)
    if not ok then
        connect("reconnect", GuiService.ErrorMessageChanged, function()
            task.spawn(rejoin)
        end)
    end
end

function Misc.CopyJobId()
    local text = game.JobId
    if setClipboard then pcall(setClipboard, text) end
    return text
end

function Misc.JoinJobId(jobId)
    jobId = tostring(jobId or ""):gsub("%s", "")
    if jobId == "" then
        VoidHub.Notify("Join Job ID", "Paste a job id first.", 4)
        return false
    end
    Misc.QueueAutoExecute()
    local ok, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, LocalPlayer)
    end)
    if not ok then VoidHub.Notify("Join Job ID", tostring(err), 6) end
    return ok
end

-- "Trade coins bypass": the trade window clamps what you can type into the Wen
-- box on the client. This lifts the clamp so the full amount reaches the server,
-- which then applies its own rules.
function Misc.SetTradeBypass(enabled)
    Flags.TradeBypass = enabled
    if not enabled then
        disconnect("tradeBypass")
        return
    end
    local function patch(box)
        if not box:IsA("TextBox") then return end
        local name = string.lower(box.Name .. " " .. (box.PlaceholderText or ""))
        if string.find(name, "wen") or string.find(name, "coin") or string.find(name, "amount") then
            pcall(function()
                box.TextEditable = true
                box:SetAttribute("VoidHubUnclamped", true)
            end)
        end
    end
    local gui = LocalPlayer:FindFirstChild("PlayerGui")
    if gui then
        for _, d in ipairs(gui:GetDescendants()) do patch(d) end
        connect("tradeBypass", gui.DescendantAdded, function(d)
            if Flags.TradeBypass then patch(d) end
        end)
    end
end

VoidHub.Misc = Misc

-- ============================================================================
-- UI
-- ============================================================================

local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/VoidDeveloper67/VonLib/refs/heads/main/main.luau"
))()

local LOGO = "rbxassetid://101833678008843"

-- Asset ids lifted straight from the shared VonLib Icons.lua. Only the ones
-- this hub actually puts on screen are carried here; the names match that
-- file, so dropping the full pack in later changes nothing.
local ICONS = {
    sword    = 10734975486,   -- Farm
    skull    = 10734962068,   -- World Bosses
    swords   = 10734975692,   -- Combat
    list     = 10723433811,   -- Priority
    medal    = 10734887072,   -- Trainer
    user     = 10747373176,   -- Player
    map      = 10734886202,   -- Travel
    eye      = 10723346959,   -- ESP
    bell     = 10709775704,   -- Webhook
    settings = 10734950309,   -- Misc
    verified = 10747374131,   -- version tag
}

local Window = Library:MakeWindow({
    Title        = "VoidHub : Ouwland",
    SubTitle     = "By von63rd",
    ScriptFolder = "voidhub_v1",
})

-- MakeWindow fills Library.Icons from voidhub_v1/Icons.lua or, failing that,
-- a GitHub copy that no longer exists. Top it up before any tab asks for an
-- icon, leaving anything the library did find alone.
if type(Library.Icons) ~= "table" then Library.Icons = {} end
for name, assetId in pairs(ICONS) do
    if Library.Icons[name] == nil then Library.Icons[name] = assetId end
end

VoidHub.Library = Library
VoidHub.Window = Window

function VoidHub.Notify(title, content, duration)
    pcall(function()
        Window:Notify({
            Title = title,
            Content = content,
            Image = LOGO,
            Duration = duration or 4,
        })
    end)
end

pcall(function() Window:Tag({ Title = "v1", Color = "Purple", Icon = "verified" }) end)

local Minimizer = Window:NewMinimizer({ KeyCode = Enum.KeyCode.LeftControl })
pcall(function()
    Minimizer:CreateMobileMinimizer({
        Image  = LOGO,
        Size   = UDim2.new(0, 38, 0, 38),
        Corner = { CornerRadius = UDim.new(0, 8) },
    })
end)

local HUD = Library:MakeStatsHUD({
    Stats    = { "Ping", "FPS", "Playtime", "Players" },
    Position = UDim2.new(0, 8, 0.35, 0),
    Visible  = false,
})
VoidHub.HUD = HUD

pcall(function()
    HUD:AddStat("Wen", function() return commaNumber(Game.Wen()) end)
    HUD:AddStat("Exp", function()
        local current, goal = Game.Exp()
        return commaNumber(current) .. " / " .. commaNumber(goal)
    end)
    HUD:AddStat("Job", function() return Target.Status end)
end)

-- Tab icons resolve through VonLib's icon table, which it loads from
-- voidhub_v1/Icons.lua. Names stay readable so swapping the icon pack is a
-- one-file change.
local FarmTab    = Window:MakeTab({ Title = "Farm",         Icon = "sword" })
local BossTab    = Window:MakeTab({ Title = "World Bosses", Icon = "skull" })
local CombatTab  = Window:MakeTab({ Title = "Combat",       Icon = "swords" })
local PriorityTab= Window:MakeTab({ Title = "Priority",     Icon = "list" })
local TrainerTab = Window:MakeTab({ Title = "Trainer",      Icon = "medal" })
local PlayerTab  = Window:MakeTab({ Title = "Player",       Icon = "user" })
local TravelTab  = Window:MakeTab({ Title = "Travel",       Icon = "map" })
local EspTab     = Window:MakeTab({ Title = "ESP",          Icon = "eye" })
local WebhookTab = Window:MakeTab({ Title = "Webhook",      Icon = "bell" })
local MiscTab    = Window:MakeTab({ Title = "Misc",         Icon = "settings" })

-- Helper so every element writes straight into Flags.
local function bind(key, default)
    Flags[key] = default
    return function(value)
        Flags[key] = value
    end
end

local function bindThen(key, default, after)
    Flags[key] = default
    return function(value)
        Flags[key] = value
        local ok, err = pcall(after, value)
        if not ok then warn("[VoidHub] " .. key .. ": " .. tostring(err)) end
    end
end

-- ---------------------------------------------------------------- Farm tab --

FarmTab:AddSection("Farming")

FarmTab:AddButton({
    Name  = "1 Click Level Up",
    Badge = "Hot",
    Callback = function() Farm.OneClickLevel() end,
})

FarmTab:AddToggle({
    Name = "Auto Farm Mobs", Default = false, Flag = "AutoFarmMobs",
    Callback = bindThen("AutoFarmMobs", false, function() Farm.Refresh() end),
})

local mobDropdown = FarmTab:AddDropdown({
    Name = "Mobs", MultiSelect = true, Options = Game.NpcNames(), Default = {},
    Flag = "MobTargets", Callback = bind("MobTargets", {}),
})

FarmTab:AddDropdown({
    Name = "Mob Priority", Options = { "Nearest", "Lowest HP", "Highest HP" },
    Default = "Nearest", Flag = "MobSort", Callback = bind("MobSort", "Nearest"),
})

FarmTab:AddToggle({
    Name = "Auto Quest", Default = false, Flag = "AutoQuest",
    Callback = bindThen("AutoQuest", false, function() Farm.Refresh() end),
})

FarmTab:AddToggle({
    Name = "Instant Kill", Badge = "Beta", Default = false, Flag = "InstantKill",
    Callback = bind("InstantKill", false),
})

local killStatusLabel = FarmTab:AddLabel("Instant Kill: idle")

FarmTab:AddToggle({
    Name = "Auto Accept", Default = false, Flag = "AutoAccept",
    Callback = bindThen("AutoAccept", false, function(v)
        setLoop("autoaccept", v, 0.5, AutoAccept.Tick)
    end),
})

FarmTab:AddSection("Pickups")

FarmTab:AddToggle({
    Name = "Auto Collect Chests", Default = false, Flag = "AutoCollectChests",
    Callback = bindThen("AutoCollectChests", false, function() Farm.Refresh() end),
})

local chestDropdown = FarmTab:AddDropdown({
    Name = "Chest Filter", MultiSelect = true, Options = World.ChestNames(), Default = {},
    Flag = "ChestFilter", Callback = bind("ChestFilter", {}),
})

FarmTab:AddToggle({
    Name = "Auto Pick Up Drops", Default = false, Flag = "AutoPickDrops",
    Callback = bindThen("AutoPickDrops", false, function() Farm.Refresh() end),
})

FarmTab:AddSection("Shop & Trade")

FarmTab:AddToggle({
    Name = "Auto Buy", Default = false, Flag = "AutoBuy",
    Callback = bindThen("AutoBuy", false, function() Farm.Refresh() end),
})

local buyDropdown = FarmTab:AddDropdown({
    Name = "Buy Items", MultiSelect = true, Options = (function()
        local out = {}
        for label in pairs(World.ShopItems()) do out[#out + 1] = label end
        table.sort(out)
        return out
    end)(), Default = {}, Flag = "BuyItems", Callback = bind("BuyItems", {}),
})

FarmTab:AddToggle({
    Name = "Auto Trade Coins Bypass", Badge = "Beta", Default = false, Flag = "TradeBypass",
    Callback = bindThen("TradeBypass", false, function(v) Misc.SetTradeBypass(v) end),
})

FarmTab:AddSection("Movement")

FarmTab:AddDropdown({
    Name = "Position", Options = { "Behind", "Front", "Side", "Above", "Inside" },
    Default = "Behind", Flag = "FarmPosition", Callback = bind("FarmPosition", "Behind"),
})

FarmTab:AddSlider({
    Name = "Distance", Min = 2, Max = 40, Increment = 1, Default = 7,
    Flag = "FarmDistance", Callback = bind("FarmDistance", 7),
})

FarmTab:AddDropdown({
    Name = "Movement Type", Options = { "Instant", "Tween", "Walk" },
    Default = "Tween", Flag = "MovementType", Callback = bind("MovementType", "Tween"),
})

FarmTab:AddSlider({
    Name = "Tween Speed", Min = 20, Max = 500, Increment = 5, Default = 180,
    Flag = "TweenSpeed", Callback = bind("TweenSpeed", 180),
})

FarmTab:AddButton({
    Name = "Refresh Lists",
    Callback = function()
        pcall(function() mobDropdown:NewOptions(Game.NpcNames()) end)
        pcall(function() chestDropdown:NewOptions(World.ChestNames()) end)
        pcall(function()
            local out = {}
            for label in pairs(World.ShopItems()) do out[#out + 1] = label end
            table.sort(out)
            buyDropdown:NewOptions(out)
        end)
        VoidHub.Notify("Farm", "Lists refreshed.", 3)
    end,
})

-- --------------------------------------------------------- World Boss tab --

BossTab:AddSection("Auto")

BossTab:AddToggle({
    Name = "Auto World Bosses", Default = false, Flag = "AutoWorldBosses",
    Callback = bindThen("AutoWorldBosses", false, function() Farm.Refresh() end),
})

local bossDropdown = BossTab:AddDropdown({
    Name = "Boss Picker", MultiSelect = true, Options = Bosses.Names(), Default = {},
    Flag = "BossPicker", Callback = bind("BossPicker", {}),
})

BossTab:AddToggle({
    Name = "Open Boss Chests", Default = false, Flag = "OpenBossChests",
    Callback = bind("OpenBossChests", false),
})

BossTab:AddSection("Timers")

local dayNightLabel = BossTab:AddLabel("Day / Night: ...")
local bossTimerLabel = BossTab:AddParagraph("Live Respawn Timers", "Waiting for boss data...")

BossTab:AddButton({
    Name = "Refresh Boss List",
    Callback = function()
        pcall(function() bossDropdown:NewOptions(Bosses.Names()) end)
        VoidHub.Notify("World Bosses", "Boss list refreshed.", 3)
    end,
})

-- ------------------------------------------------------------- Combat tab --

CombatTab:AddSection("Attacks")

CombatTab:AddToggle({
    Name = "Auto M1", Default = true, Flag = "AutoM1",
    Callback = bind("AutoM1", true),
})

CombatTab:AddSlider({
    Name = "Attack Delay", Min = 0.1, Max = 1.5, Increment = 0.05, Default = 0.4,
    Flag = "AttackDelay", Callback = bind("AttackDelay", 0.4),
})

CombatTab:AddToggle({
    Name = "Smart Auto Skill", Default = false, Flag = "SmartAutoSkill",
    Callback = bind("SmartAutoSkill", false),
})

CombatTab:AddDropdown({
    Name = "Skill Picker", MultiSelect = true,
    Options = (function()
        local out = {}
        for i = 1, 10 do
            local name = Combat.SlotSkillName(i)
            out[i] = "Slot " .. i .. (name and (" - " .. name) or "")
        end
        return out
    end)(),
    Default = { "Slot 1", "Slot 2", "Slot 3" },
    Flag = "SkillSlots", Callback = bind("SkillSlots", { "Slot 1", "Slot 2", "Slot 3" }),
})

CombatTab:AddDropdown({
    Name = "Weapon Slot", Options = Combat.WeaponSlots, Default = "One",
    Flag = "WeaponSlot",
    Callback = bindThen("WeaponSlot", "One", function(v) Combat.EquipSlot(v) end),
})

CombatTab:AddSection("Defence")

CombatTab:AddToggle({
    Name = "Auto Parry", Badge = "Beta", Default = false, Flag = "AutoParry",
    Callback = bind("AutoParry", false),
})

CombatTab:AddSlider({
    Name = "Parry Range", Min = 5, Max = 40, Increment = 1, Default = 16,
    Flag = "ParryRange", Callback = bind("ParryRange", 16),
})

CombatTab:AddSlider({
    Name = "Parry Delay", Min = 0, Max = 0.5, Increment = 0.01, Default = 0.08,
    Flag = "ParryDelay", Callback = bind("ParryDelay", 0.08),
})

CombatTab:AddToggle({
    Name = "Auto Block", Default = false, Flag = "AutoBlock",
    Callback = bindThen("AutoBlock", false, function(v)
        if not v then Combat.SetBlock(false) end
    end),
})

CombatTab:AddSlider({
    Name = "Block Range", Min = 5, Max = 40, Increment = 1, Default = 14,
    Flag = "BlockRange", Callback = bind("BlockRange", 14),
})

-- ----------------------------------------------------------- Priority tab --

PriorityTab:AddSection("Job Order")
PriorityTab:AddParagraph("How it works",
    "The farm loop runs the first job that has work to do, top to bottom.\n"
    .. "Drops and Auto Buy always run alongside whichever job is active.")

local jobOptions = { "World Bosses", "Chests", "Quests", "Mobs" }
for i = 1, 4 do
    PriorityTab:AddDropdown({
        Name = "Priority " .. i, Options = jobOptions, Default = Farm.DefaultOrder[i],
        Flag = "Priority" .. i, Callback = bind("Priority" .. i, Farm.DefaultOrder[i]),
    })
end

-- ------------------------------------------------------------ Trainer tab --

TrainerTab:AddSection("Trials")

TrainerTab:AddToggle({
    Name = "Auto Trial", Badge = "Beta", Default = false, Flag = "AutoTrial",
    Callback = bindThen("AutoTrial", false, function(v)
        if v then startThread("trainer", function()
            while Flags.AutoTrial do
                Trainer.Run()
                task.wait(1)
            end
        end) else stopThread("trainer") end
    end),
})

local trialDropdown = TrainerTab:AddDropdown({
    Name = "Trial Picker", MultiSelect = true,
    Options = (function()
        local out = {}
        for _, spot in ipairs(World.TrainingSpots()) do out[#out + 1] = spot.Name end
        return out
    end)(),
    Default = {}, Flag = "TrialPicker", Callback = bind("TrialPicker", {}),
})

TrainerTab:AddButton({
    Name = "Refresh Trials",
    Callback = function()
        pcall(function()
            local out = {}
            for _, spot in ipairs(World.TrainingSpots()) do out[#out + 1] = spot.Name end
            trialDropdown:NewOptions(out)
        end)
    end,
})

-- ------------------------------------------------------------- Player tab --

PlayerTab:AddSection("Movement")

PlayerTab:AddToggle({
    Name = "WalkSpeed", Default = false, Flag = "WalkSpeedEnabled",
    Callback = function(v) Player.SetWalkSpeed(v) end,
})

PlayerTab:AddSlider({
    Name = "WalkSpeed Value", Min = 16, Max = 500, Increment = 1, Default = 60,
    Flag = "WalkSpeed", Callback = bindThen("WalkSpeed", 60, function() Player.ApplyWalkSpeed() end),
})

PlayerTab:AddToggle({
    Name = "Fly", Default = false, Flag = "FlyEnabled",
    Callback = function(v) Player.SetFly(v) end,
})

PlayerTab:AddSlider({
    Name = "Fly Speed", Min = 10, Max = 400, Increment = 5, Default = 60,
    Flag = "FlySpeed", Callback = bind("FlySpeed", 60),
})

PlayerTab:AddToggle({
    Name = "Infinite Jump", Default = false, Flag = "InfiniteJump",
    Callback = function(v) Player.SetInfiniteJump(v) end,
})

PlayerTab:AddToggle({
    Name = "Noclip", Default = false, Flag = "Noclip",
    Callback = function(v) Player.SetNoclip(v) end,
})

-- ------------------------------------------------------------- Travel tab --

TravelTab:AddSection("Teleport to NPC")

local npcDropdown = TravelTab:AddDropdown({
    Name = "NPC", Options = Travel.NpcList(), Default = "",
    Flag = "NpcTarget", Callback = bind("NpcTarget", ""),
})

TravelTab:AddButton({
    Name = "Teleport to NPC",
    Callback = function()
        if Flags.NpcTarget and Flags.NpcTarget ~= "" then Travel.ToNpc(Flags.NpcTarget) end
    end,
})

TravelTab:AddSection("Teleport to Place")

local placeDropdown = TravelTab:AddDropdown({
    Name = "Place", Options = Travel.PlaceLabels(), Default = "",
    Flag = "PlaceTarget", Callback = bind("PlaceTarget", ""),
})

TravelTab:AddButton({
    Name = "Teleport to Place",
    Callback = function()
        if Flags.PlaceTarget and Flags.PlaceTarget ~= "" then Travel.ToPlace(Flags.PlaceTarget) end
    end,
})

TravelTab:AddButton({
    Name = "Refresh Destinations",
    Callback = function()
        pcall(function() npcDropdown:NewOptions(Travel.NpcList()) end)
        pcall(function() placeDropdown:NewOptions(Travel.PlaceLabels()) end)
        VoidHub.Notify("Travel", "Destinations refreshed.", 3)
    end,
})

-- ---------------------------------------------------------------- ESP tab --

EspTab:AddSection("Targets")

EspTab:AddToggle({
    Name = "Mob ESP", Default = false, Flag = "MobESP",
    Callback = bindThen("MobESP", false, function() ESP.Refresh() end),
})

local espMobDropdown = EspTab:AddDropdown({
    Name = "ESP Mobs", MultiSelect = true, Options = Game.NpcNames(), Default = {},
    Flag = "ESPMobs", Callback = bind("ESPMobs", {}),
})

EspTab:AddToggle({
    Name = "Item ESP", Default = false, Flag = "ItemESP",
    Callback = bindThen("ItemESP", false, function() ESP.Refresh() end),
})

EspTab:AddToggle({
    Name = "Flower ESP", Default = false, Flag = "FlowerESP",
    Callback = bindThen("FlowerESP", false, function() ESP.Refresh() end),
})

EspTab:AddSection("Drawing")

EspTab:AddToggle({ Name = "Box",      Default = true,  Flag = "BoxESP",      Callback = bind("BoxESP", true) })
EspTab:AddToggle({ Name = "Name",     Default = true,  Flag = "NameESP",     Callback = bind("NameESP", true) })
EspTab:AddToggle({ Name = "Distance", Default = true,  Flag = "DistanceESP", Callback = bind("DistanceESP", true) })
EspTab:AddToggle({ Name = "Health",   Default = true,  Flag = "HealthESP",   Callback = bind("HealthESP", true) })
EspTab:AddToggle({ Name = "Tracer",   Default = false, Flag = "TracerESP",   Callback = bind("TracerESP", false) })

EspTab:AddToggle({
    Name = "Chams", Default = false, Flag = "ChamsESP",
    Callback = bindThen("ChamsESP", false, function() ESP.Clear() end),
})

EspTab:AddToggle({
    Name = "No Max Distance", Default = false, Flag = "NoMaxDistance",
    Callback = bind("NoMaxDistance", false),
})

EspTab:AddSlider({
    Name = "Max Distance", Min = 50, Max = 5000, Increment = 25, Default = 250,
    Flag = "ESPDistance", Callback = bind("ESPDistance", 250),
})

EspTab:AddColorPicker({
    Name = "ESP Color", Default = Color3.fromRGB(120, 200, 255), Flag = "ESPColor",
    Callback = bind("ESPColor", Color3.fromRGB(120, 200, 255)),
})

EspTab:AddButton({
    Name = "Refresh Mob List",
    Callback = function()
        pcall(function() espMobDropdown:NewOptions(Game.NpcNames()) end)
    end,
})

-- ------------------------------------------------------------ Webhook tab --

WebhookTab:AddSection("Destination")

WebhookTab:AddTextBox({
    Name = "Webhook URL", Placeholder = "https://discord.com/api/webhooks/...",
    ClearOnFocus = false, Flag = "WebhookUrl", Callback = bind("WebhookUrl", ""),
})

WebhookTab:AddToggle({
    Name = "Discord Ping", Default = false, Flag = "DiscordPing",
    Callback = bind("DiscordPing", false),
})

WebhookTab:AddTextBox({
    Name = "Ping User ID", Placeholder = "leave blank for @everyone",
    ClearOnFocus = false, Flag = "DiscordPingId", Callback = bind("DiscordPingId", ""),
})

WebhookTab:AddSection("Events")

WebhookTab:AddToggle({
    Name = "Drops", Default = false, Flag = "WebhookDrops",
    Callback = bind("WebhookDrops", false),
})

WebhookTab:AddDropdown({
    Name = "Min Rarity", Options = Webhook.RarityOrder, Default = "Common",
    Flag = "WebhookMinRarity", Callback = bind("WebhookMinRarity", "Common"),
})

WebhookTab:AddToggle({
    Name = "Level Up", Default = false, Flag = "WebhookLevel",
    Callback = bind("WebhookLevel", false),
})

WebhookTab:AddToggle({
    Name = "Boss Spawns", Default = false, Flag = "WebhookBoss",
    Callback = bind("WebhookBoss", false),
})

WebhookTab:AddDropdown({
    Name = "Bosses to Report", MultiSelect = true, Options = Bosses.Names(), Default = {},
    Flag = "WebhookBossPicker", Callback = bind("WebhookBossPicker", {}),
})

WebhookTab:AddButton({
    Name = "Send Test",
    Callback = function()
        local sent = Webhook.Send({
            username = "VoidHub",
            embeds = { { title = "Test", description = "VoidHub : Ouwland is connected.", color = 0x7B5CFF } },
        })
        VoidHub.Notify("Webhook", sent and "Test sent." or "Set a webhook URL first.", 4)
    end,
})

-- --------------------------------------------------------------- Misc tab --

MiscTab:AddSection("Session")

MiscTab:AddToggle({
    Name = "Staff Detector", Default = false, Flag = "StaffDetector",
    Callback = function(v) Misc.SetStaffDetector(v) end,
})

MiscTab:AddSlider({
    Name = "Min Group Rank", Min = 1, Max = 254, Increment = 1, Default = 20,
    Flag = "StaffMinRank", Callback = bind("StaffMinRank", 20),
})

MiscTab:AddToggle({
    Name = "Hide Name / Watermark", Default = false, Flag = "HideName",
    Callback = function(v) Misc.SetHideName(v) end,
})

MiscTab:AddToggle({
    Name = "Anti AFK", Default = true, Flag = "AntiAFK",
    Callback = function(v) Misc.SetAntiAfk(v) end,
})

MiscTab:AddToggle({
    Name = "Auto Reconnect", Default = false, Flag = "AutoReconnect",
    Callback = function(v) Misc.SetAutoReconnect(v) end,
})

MiscTab:AddSection("Auto Execute")

MiscTab:AddTextBox({
    Name = "Script URL", Placeholder = "raw script url",
    ClearOnFocus = false, Flag = "ExecuteUrl",
    Callback = bindThen("ExecuteUrl", "", function(v) Misc.SaveAutoExecute(v) end),
})

MiscTab:AddToggle({
    Name = "Auto Execute", Default = false, Flag = "AutoExecute",
    Callback = bind("AutoExecute", false),
})

MiscTab:AddSection("Servers")

MiscTab:AddButton({
    Name = "Copy Job ID",
    Callback = function()
        local id = Misc.CopyJobId()
        VoidHub.Notify("Job ID", setClipboard and ("Copied: " .. id) or id, 6)
    end,
})

MiscTab:AddTextBox({
    Name = "Job ID", Placeholder = "paste a job id",
    ClearOnFocus = false, Flag = "JoinJobId", Callback = bind("JoinJobId", ""),
})

MiscTab:AddButton({
    Name = "Join Job ID",
    Callback = function() Misc.JoinJobId(Flags.JoinJobId) end,
})

MiscTab:AddSection("Interface")

MiscTab:AddToggle({
    Name = "Show Stats HUD", Default = false,
    Callback = function(v) pcall(function() HUD:SetVisible(v) end) end,
})

MiscTab:AddDropdown({
    Name = "Theme", Options = Library:GetThemes(), Default = Library:GetTheme().Name,
    Callback = function(v) Library:SetTheme(v) end,
})

MiscTab:AddSlider({
    Name = "UI Scale", Min = 0.6, Max = 1.6, Increment = 0.05, Default = 1,
    Callback = function(v) Library:SetUIScale(v) end,
})

MiscTab:AddSection("Config")

MiscTab:AddButton({
    Name = "Save Config",
    Callback = function()
        Window:SaveConfig("Default")
        VoidHub.Notify("Config", "Saved.", 3)
    end,
})

MiscTab:AddButton({
    Name = "Load Config",
    Callback = function()
        local ok = Window:LoadConfig("Default")
        VoidHub.Notify("Config", ok and "Loaded." or "No config saved yet.", 3)
    end,
})

MiscTab:AddButton({
    Name = "Unload VoidHub", Badge = "Warning",
    Callback = function() VoidHub.Destroy() end,
})

MiscTab:AddSection("Community")

MiscTab:AddDiscordInvite({
    Title       = "VoidHub",
    Description = "Scripts, updates and support.",
    Banner      = LOGO,
    Logo        = LOGO,
    Invite      = "https://discord.gg/Wsarxj9Gzz",
})

-- ============================================================================
-- BACKGROUND TICKERS
-- ============================================================================

setLoop("bosspoll", true, 1, function()
    Bosses.Poll()
end)

setLoop("uirefresh", true, 1, function()
    pcall(function()
        dayNightLabel:SetTitle("Day / Night: " .. Bosses.DayNightText())
    end)

    pcall(function()
        killStatusLabel:SetTitle("Instant Kill: " .. tostring(InstantKill.LastStatus))
    end)

    local picked = Flags.BossPicker
    local lines = {}
    if type(picked) == "table" and #picked > 0 then
        for _, label in ipairs(picked) do
            local name = Bosses.StripLabel(label)
            lines[#lines + 1] = name .. ": " .. Bosses.TimerText(name)
        end
    else
        for _, boss in ipairs(Bosses.All()) do
            if boss.Category == "World Boss" then
                lines[#lines + 1] = boss.Name .. ": " .. Bosses.TimerText(boss.Name)
            end
        end
    end
    pcall(function()
        bossTimerLabel:SetDescription(table.concat(lines, "\n"))
    end)
end)

setLoop("defence", true, 0.15, function()
    Defence.Tick()
end)

Webhook.Start()

-- Keep player toggles alive through respawns.
connect("charAdded", LocalPlayer.CharacterAdded, function()
    task.wait(1)
    if Flags.WalkSpeedEnabled then Player.ApplyWalkSpeed() end
    if Flags.FlyEnabled then Player.SetFly(true) end
    if Flags.HideName then Misc.SetHideName(true) end
end)

-- ============================================================================
-- TEARDOWN
-- ============================================================================

function VoidHub.Destroy()
    Flags.MasterFarmRunning = false
    for name in pairs(Threads) do stopThread(name) end
    for name in pairs(Connections) do disconnect(name) end
    pcall(function() Combat.SetBlock(false) end)
    pcall(function() Player.SetFly(false) end)
    pcall(function() Player.SetNoclip(false) end)
    pcall(function() ESP.Clear() end)
    pcall(function() if ESP.Gui then ESP.Gui:Destroy() end end)
    pcall(function() HUD:Destroy() end)
    pcall(function() Window:Destroy() end)
    if getgenv then getgenv().VoidHubOuwland = nil end
end

Misc.SetAntiAfk(true)
Window:SelectTab(1)

VoidHub.Notify(
    "VoidHub Loaded",
    "Ouwland v1 - " .. #Bosses.All() .. " bosses tracked. LeftCtrl or the logo button minimises.",
    6
)

return VoidHub
