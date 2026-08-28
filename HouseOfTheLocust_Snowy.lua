local Snowy = loadstring(readfile("SnowyStudios.luau"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local window = Snowy:Window({
    Title = "Snowy Studios",
    Subtitle = "House of the Locust",
    IconPack = "phosphor",
    Logo = "rbxassetid://123802801726537",
    LogoRectOffset = Vector2.new(40, 256),
    LogoRectSize = Vector2.new(945, 457),
    Keybind = Enum.KeyCode.RightShift,
})

local Flags = Snowy.Flags

local COLORS = {
    Red = Color3.fromRGB(255, 70, 70),
    Orange = Color3.fromRGB(255, 150, 60),
    Yellow = Color3.fromRGB(255, 225, 80),
    Green = Color3.fromRGB(90, 235, 120),
    Cyan = Color3.fromRGB(90, 220, 255),
    Blue = Color3.fromRGB(110, 150, 255),
    Purple = Color3.fromRGB(190, 130, 255),
    Pink = Color3.fromRGB(255, 120, 200),
    White = Color3.fromRGB(245, 245, 245),
}

local COLOR_NAMES = { "Red", "Orange", "Yellow", "Green", "Cyan", "Blue", "Purple", "Pink", "White" }

local OBJECTIVE_WORDS = {
    "exit", "keyhole", "keycard", "reader", "wire", "cutter", "cube", "door",
}

local state = {
    escapeRunning = false,
    escapeStep = "idle",
    escapeStatus = "Idle",
    dodges = 0,
    revives = 0,
    lastDodge = 0,
    searched = {},
    cabinetOrder = {},
    stepsDone = {},
}

local function flag(name, fallback)
    local value = Flags[name]
    if value == nil then
        return fallback
    end
    return value
end

local function isOn(name)
    return Flags[name] == true
end

local function colorFor(name, fallback)
    return COLORS[flag(name, fallback)] or COLORS[fallback]
end

local function setLabel(handle, text)
    local root = handle and handle.Instance
    if typeof(root) ~= "Instance" then
        return
    end
    if root:IsA("TextLabel") then
        root.Text = text
        return
    end
    for _, item in ipairs(root:GetDescendants()) do
        if item:IsA("TextLabel") then
            item.Text = text
            return
        end
    end
end

local function character()
    local char = LocalPlayer.Character
    return (char and char.Parent) and char or nil
end

local function humanoid()
    local char = character()
    return char and char:FindFirstChildOfClass("Humanoid") or nil
end

local function rootPart()
    local char = character()
    return char and char:FindFirstChild("HumanoidRootPart") or nil
end

local function myPosition()
    local root = rootPart()
    if root then
        return root.Position
    end
    local char = character()
    return char and char:GetPivot().Position or nil
end

local function pivotOf(instance)
    if not instance or not instance.Parent then
        return nil
    end
    if instance:IsA("BasePart") then
        return instance.Position
    end
    if instance:IsA("Model") then
        local ok, pivot = pcall(function()
            return instance:GetPivot().Position
        end)
        if ok then
            return pivot
        end
    end
    if instance:IsA("Tool") then
        local handle = instance:FindFirstChild("Handle")
        if handle then
            return handle.Position
        end
    end
    return nil
end

local function distanceTo(position)
    local mine = myPosition()
    if not mine or not position then
        return math.huge
    end
    return (mine - position).Magnitude
end

local function teleportTo(position, offset)
    local root = rootPart()
    if not root or not position or root.Anchored then
        return false
    end
    root.CFrame = CFrame.new(position + (offset or Vector3.new(0, 3, 0)))
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    return true
end

local function glideTo(position, stopDistance)
    local root = rootPart()
    if not root or root.Anchored then
        return false
    end
    local mine = root.Position
    local gap = (position - mine).Magnitude
    if gap <= stopDistance then
        return true
    end
    local speed = math.max(20, tonumber(flag("hotl_travel_speed", 90)) or 90)
    local duration = math.clamp((gap - stopDistance) / speed, 0.05, 6)
    local goal = position - (position - mine).Unit * stopDistance
    local tween = TweenService:Create(root, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        CFrame = CFrame.new(goal + Vector3.new(0, 3, 0)),
    })
    tween:Play()
    tween.Completed:Wait()
    root.AssemblyLinearVelocity = Vector3.zero
    return true
end

local function travelTo(position, stopDistance)
    stopDistance = stopDistance or 6
    local root = rootPart()
    if not root or root.Anchored or not position then
        return false
    end
    if isOn("hotl_smooth_movement") then
        return glideTo(position, stopDistance)
    end
    local steps = 0
    while steps < 60 do
        local mine = myPosition()
        if not mine then
            return false
        end
        local gap = (position - mine).Magnitude
        if gap <= stopDistance then
            return true
        end
        local step = math.min(gap - stopDistance, 40)
        local direction = (position - mine).Unit
        teleportTo(mine + direction * step, Vector3.zero)
        steps += 1
        task.wait(0.08)
    end
    return distanceTo(position) <= stopDistance * 2
end

local function firePrompt(prompt)
    if typeof(prompt) ~= "Instance" or not prompt:IsA("ProximityPrompt") then
        return false
    end
    local held = prompt.HoldDuration
    local sight = prompt.RequiresLineOfSight
    local distance = prompt.MaxActivationDistance
    pcall(function()
        prompt.HoldDuration = 0
        prompt.RequiresLineOfSight = false
        prompt.MaxActivationDistance = math.max(distance, 60)
    end)
    local ok = pcall(function()
        fireproximityprompt(prompt)
    end)
    task.delay(0.4, function()
        pcall(function()
            prompt.HoldDuration = held
            prompt.RequiresLineOfSight = sight
            prompt.MaxActivationDistance = distance
        end)
    end)
    return ok
end

local function promptsIn(instance)
    local list = {}
    if not instance or not instance.Parent then
        return list
    end
    for _, item in ipairs(instance:GetDescendants()) do
        if item:IsA("ProximityPrompt") and item.Enabled then
            list[#list + 1] = item
        end
    end
    return list
end

local function firstPromptIn(instance)
    return promptsIn(instance)[1]
end

local function locustModels()
    local list = {}
    local entities = Workspace:FindFirstChild("Entities")
    if entities then
        for _, item in ipairs(entities:GetChildren()) do
            if item:IsA("Model") and item:FindFirstChildOfClass("Humanoid") then
                list[#list + 1] = item
            end
        end
    end
    if #list == 0 then
        for _, item in ipairs(Workspace:GetChildren()) do
            if item:IsA("Model") and item.Name:lower():find("locust", 1, true)
                and item:FindFirstChildOfClass("Humanoid") then
                list[#list + 1] = item
            end
        end
    end
    return list
end

local function nearestLocust()
    local best, bestDistance = nil, math.huge
    for _, monster in ipairs(locustModels()) do
        local position = pivotOf(monster)
        if position then
            local gap = distanceTo(position)
            if gap < bestDistance then
                best, bestDistance = monster, gap
            end
        end
    end
    return best, bestDistance
end

local function cabinets()
    local folder = Workspace:FindFirstChild("Cabinets")
    if not folder then
        return {}
    end
    return folder:GetChildren()
end

local function cabinetPrompt(cabinet)
    local interact = cabinet:FindFirstChild("Interact")
    if interact then
        local prompt = interact:FindFirstChildOfClass("ProximityPrompt")
        if prompt then
            return prompt
        end
    end
    return firstPromptIn(cabinet)
end

local function cabinetSearched(cabinet)
    if state.searched[cabinet] then
        return true
    end
    if cabinet:GetAttribute("Searched") == true then
        return true
    end
    local prompt = cabinetPrompt(cabinet)
    if prompt and prompt.Enabled == false then
        return true
    end
    return false
end

local function matchesObjective(name)
    name = name:lower()
    for _, word in ipairs(OBJECTIVE_WORDS) do
        if name:find(word, 1, true) then
            return true
        end
    end
    return false
end

local function objectiveTargets()
    local list, seen = {}, {}
    local function add(instance, label)
        if not instance or seen[instance] then
            return
        end
        local position = pivotOf(instance)
        if not position then
            return
        end
        seen[instance] = true
        list[#list + 1] = { instance = instance, label = label, position = position }
    end

    for _, item in ipairs(Workspace:GetChildren()) do
        if (item:IsA("Model") or item:IsA("BasePart") or item:IsA("Tool"))
            and item.Name ~= "Cabinets" and matchesObjective(item.Name) then
            add(item, item.Name)
        end
    end

    for _, item in ipairs(Workspace:GetDescendants()) do
        if item:IsA("ProximityPrompt") and item.Enabled then
            local object = tostring(item.ObjectText)
            local action = tostring(item.ActionText)
            if object ~= "Cabinet" and (matchesObjective(object) or matchesObjective(action)) then
                local holder = item.Parent
                if holder and holder.Parent and holder.Parent:IsA("Model") then
                    holder = holder.Parent
                end
                add(holder, object ~= "" and object or action)
            end
        end
    end

    return list
end

local function findObjective(...)
    local words = { ... }
    for _, target in ipairs(objectiveTargets()) do
        local label = (target.label or ""):lower()
        local name = target.instance.Name:lower()
        for _, word in ipairs(words) do
            if label:find(word, 1, true) or name:find(word, 1, true) then
                return target
            end
        end
    end
    return nil
end

local espGui = Instance.new("ScreenGui")
espGui.Name = "HOTL_Vision"
espGui.ResetOnSpawn = false
espGui.IgnoreGuiInset = true
espGui.DisplayOrder = 9999
espGui.Parent = (gethui and gethui()) or LocalPlayer:WaitForChild("PlayerGui")

local markers = {}
local highlights = {}

local function releaseMarker(key)
    local marker = markers[key]
    if marker then
        marker.label:Destroy()
        marker.tracer:Destroy()
        markers[key] = nil
    end
end

local function ensureMarker(key)
    local marker = markers[key]
    if marker then
        return marker
    end
    local label = Instance.new("TextLabel")
    label.Name = "Marker"
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromOffset(220, 18)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.TextStrokeTransparency = 0.35
    label.Visible = false
    label.Parent = espGui

    local tracer = Instance.new("Frame")
    tracer.Name = "Tracer"
    tracer.BorderSizePixel = 0
    tracer.AnchorPoint = Vector2.new(0.5, 0)
    tracer.Visible = false
    tracer.Parent = espGui

    marker = { label = label, tracer = tracer }
    markers[key] = marker
    return marker
end

local function releaseHighlight(key)
    local highlight = highlights[key]
    if highlight then
        highlight:Destroy()
        highlights[key] = nil
    end
end

local function applyHighlight(key, model, color)
    if not model or not model.Parent then
        releaseHighlight(key)
        return
    end
    local hasPart = model:IsA("BasePart") or model:FindFirstChildWhichIsA("BasePart", true) ~= nil
    if not hasPart then
        releaseHighlight(key)
        return
    end
    local highlight = highlights[key]
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.FillTransparency = 0.55
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = espGui
        highlights[key] = highlight
    end
    highlight.Adornee = model
    highlight.FillColor = color
    highlight.OutlineColor = color
end

local function drawMarker(key, position, text, color, tracerOn)
    local marker = ensureMarker(key)
    local point, onScreen = Camera:WorldToViewportPoint(position)
    if not onScreen then
        marker.label.Visible = false
        marker.tracer.Visible = false
        return
    end
    marker.label.Position = UDim2.fromOffset(point.X - 110, point.Y - 26)
    marker.label.Text = text
    marker.label.TextColor3 = color
    marker.label.Visible = true

    if tracerOn then
        local viewport = Camera.ViewportSize
        local origin = Vector2.new(viewport.X / 2, viewport.Y)
        local target = Vector2.new(point.X, point.Y)
        local delta = target - origin
        local length = delta.Magnitude
        marker.tracer.Size = UDim2.fromOffset(2, length)
        marker.tracer.Position = UDim2.fromOffset(origin.X, origin.Y)
        marker.tracer.Rotation = math.deg(math.atan2(delta.Y, delta.X)) - 90
        marker.tracer.BackgroundColor3 = color
        marker.tracer.Visible = true
    else
        marker.tracer.Visible = false
    end
end

local function clearVision()
    for key in pairs(markers) do
        releaseMarker(key)
    end
    for key in pairs(highlights) do
        releaseHighlight(key)
    end
end

local function describe(text, position)
    if isOn("hotl_show_distance") then
        return string.format("%s  [%d]", text, math.floor(distanceTo(position)))
    end
    return text
end

local function refreshVision()
    local maxDistance = tonumber(flag("hotl_max_distance", 400)) or 400
    local alive = {}

    if isOn("hotl_monster_esp") then
        local color = colorFor("hotl_monster_color", "Red")
        for index, monster in ipairs(locustModels()) do
            local position = pivotOf(monster)
            if position and distanceTo(position) <= maxDistance then
                local key = "monster" .. index
                alive[key] = true
                drawMarker(key, position + Vector3.new(0, 3, 0),
                    describe("Locust", position), color, isOn("hotl_monster_tracer"))
                if isOn("hotl_monster_chams") then
                    applyHighlight(key, monster, color)
                else
                    releaseHighlight(key)
                end
            end
        end
    end

    if isOn("hotl_cabinet_esp") then
        local color = colorFor("hotl_cabinet_color", "Cyan")
        local nearestCount = math.floor(tonumber(flag("hotl_cabinet_chams_count", 5)) or 5)
        local ordered = {}
        for index, cabinet in ipairs(cabinets()) do
            local position = pivotOf(cabinet)
            if position then
                ordered[#ordered + 1] = { cabinet = cabinet, position = position, index = index }
            end
        end
        table.sort(ordered, function(a, b)
            return distanceTo(a.position) < distanceTo(b.position)
        end)
        for rank, entry in ipairs(ordered) do
            local searched = cabinetSearched(entry.cabinet)
            local hidden = searched and isOn("hotl_hide_searched")
            local key = "cabinet" .. entry.index
            if not hidden and distanceTo(entry.position) <= maxDistance then
                alive[key] = true
                local text = searched and "Cabinet (searched)" or "Cabinet"
                drawMarker(key, entry.position + Vector3.new(0, 3, 0),
                    describe(text, entry.position), color, false)
                if isOn("hotl_cabinet_chams") and rank <= nearestCount and not searched then
                    applyHighlight(key, entry.cabinet, color)
                else
                    releaseHighlight(key)
                end
            end
        end
    end

    if isOn("hotl_player_esp") then
        local color = colorFor("hotl_player_color", "Green")
        for index, other in ipairs(Players:GetPlayers()) do
            local char = other ~= LocalPlayer and other.Character or nil
            local position = char and pivotOf(char)
            if position and distanceTo(position) <= maxDistance then
                local key = "player" .. index
                alive[key] = true
                local hum = char:FindFirstChildOfClass("Humanoid")
                local health = hum and math.floor(hum.Health) or 0
                local downed = health <= 0
                local text = string.format("%s%s", other.DisplayName, downed and " (down)" or "")
                drawMarker(key, position + Vector3.new(0, 3.5, 0),
                    describe(text, position), downed and COLORS.Red or color,
                    isOn("hotl_player_tracer"))
                if isOn("hotl_player_chams") then
                    applyHighlight(key, char, downed and COLORS.Red or color)
                else
                    releaseHighlight(key)
                end
            end
        end
    end

    if isOn("hotl_objective_esp") then
        local color = colorFor("hotl_objective_color", "Yellow")
        for index, target in ipairs(objectiveTargets()) do
            if distanceTo(target.position) <= maxDistance then
                local key = "objective" .. index
                alive[key] = true
                drawMarker(key, target.position + Vector3.new(0, 3, 0),
                    describe(target.label, target.position), color, false)
                if isOn("hotl_objective_chams") then
                    applyHighlight(key, target.instance, color)
                else
                    releaseHighlight(key)
                end
            end
        end
    end

    for key in pairs(markers) do
        if not alive[key] then
            releaseMarker(key)
            releaseHighlight(key)
        end
    end
end

local function setStatus(text)
    state.escapeStatus = text
end

local function abortEscape()
    state.escapeRunning = false
    Flags.hotl_auto_escape = false
    state.escapeStep = "idle"
    setStatus("Stopped")
end

local function keepGoing()
    return state.escapeRunning and character() ~= nil
end

local function fleeIfNeeded()
    local radius = tonumber(flag("hotl_flee_radius", 45)) or 45
    local _, gap = nearestLocust()
    if gap <= radius then
        setStatus(string.format("Locust %d studs away, holding", math.floor(gap)))
        return true
    end
    return false
end

local function stepCubePuzzle()
    setStatus("Step 1: cube puzzle")
    local found = false
    for _, target in ipairs(objectiveTargets()) do
        if target.label:lower():find("cube", 1, true) or target.instance.Name:lower():find("cube", 1, true) then
            found = true
            if not keepGoing() then
                return false
            end
            travelTo(target.position, 6)
            task.wait(0.3)
            local prompt = firstPromptIn(target.instance)
            if prompt then
                firePrompt(prompt)
                task.wait(0.5)
            end
        end
    end
    state.stepsDone["Cube puzzle"] = found
    return found
end

local function stepWirecutter()
    setStatus("Step 2: wirecutter")
    local tool = Workspace:FindFirstChild("WireCutter")
    if not tool then
        for _, item in ipairs(Workspace:GetDescendants()) do
            if item:IsA("Tool") and item.Name:lower():find("cut", 1, true) then
                tool = item
                break
            end
        end
    end
    if not tool then
        state.stepsDone["Wirecutter"] = false
        return false
    end
    local position = pivotOf(tool)
    if position then
        travelTo(position, 4)
        task.wait(0.4)
    end
    local prompt = firstPromptIn(tool)
    if prompt then
        firePrompt(prompt)
    end
    task.wait(0.5)
    local held = LocalPlayer:FindFirstChildOfClass("Backpack")
    local got = (held and held:FindFirstChild(tool.Name) ~= nil)
        or (character() and character():FindFirstChild(tool.Name) ~= nil)
    state.stepsDone["Wirecutter"] = got
    return got
end

local function stepCabinetSearch()
    setStatus("Step 3: searching cabinets")
    local instant = isOn("hotl_instant_search")
    local ordered = {}
    for _, cabinet in ipairs(cabinets()) do
        local position = pivotOf(cabinet)
        if position and not cabinetSearched(cabinet) then
            ordered[#ordered + 1] = { cabinet = cabinet, position = position }
        end
    end
    table.sort(ordered, function(a, b)
        return distanceTo(a.position) < distanceTo(b.position)
    end)

    for _, entry in ipairs(ordered) do
        if not keepGoing() then
            return false
        end
        while fleeIfNeeded() and keepGoing() do
            task.wait(0.4)
        end
        setStatus(string.format("Step 3: cabinet %d left", #ordered))
        travelTo(entry.position, 5)
        task.wait(instant and 0.15 or 0.45)
        local prompt = cabinetPrompt(entry.cabinet)
        if prompt then
            firePrompt(prompt)
            task.wait(instant and 0.35 or 1.1)
        end
        state.searched[entry.cabinet] = true

        local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
        if backpack and backpack:FindFirstChild("Key") then
            state.stepsDone["Key"] = true
            return true
        end
    end
    state.stepsDone["Key"] = false
    return false
end

local function stepKeycardGrab()
    if not isOn("hotl_include_keycard") then
        return true
    end
    setStatus("Step 4: keycard off the Locust")
    local monster = nearestLocust()
    if not monster then
        state.stepsDone["Keycard"] = false
        return false
    end
    local position = pivotOf(monster)
    if not position then
        state.stepsDone["Keycard"] = false
        return false
    end
    travelTo(position, 8)
    task.wait(0.3)
    local grabbed = false
    for _, prompt in ipairs(promptsIn(monster)) do
        firePrompt(prompt)
        grabbed = true
        task.wait(0.4)
    end
    local target = findObjective("keycard")
    if target then
        travelTo(target.position, 5)
        local prompt = firstPromptIn(target.instance)
        if prompt then
            firePrompt(prompt)
            grabbed = true
        end
    end
    state.stepsDone["Keycard"] = grabbed
    return grabbed
end

local function stepUnlock()
    setStatus("Step 5: unlocking the door")
    local done = false
    for _, words in ipairs({ { "keyhole" }, { "keycard", "reader" }, { "wire", "door" } }) do
        if not keepGoing() then
            return false
        end
        local target = findObjective(table.unpack(words))
        if target then
            travelTo(target.position, 5)
            task.wait(0.3)
            local prompt = firstPromptIn(target.instance)
            if prompt then
                firePrompt(prompt)
                done = true
                task.wait(0.6)
            end
        end
    end
    state.stepsDone["Unlock"] = done
    return done
end

local function stepExit()
    setStatus("Step 6: exit")
    local target = findObjective("exit")
    if not target then
        state.stepsDone["Exit"] = false
        return false
    end
    travelTo(target.position, 4)
    task.wait(0.3)
    local prompt = firstPromptIn(target.instance)
    if prompt then
        firePrompt(prompt)
    end
    state.stepsDone["Exit"] = true
    return true
end

local STEPS = {
    { name = "Cube puzzle", run = stepCubePuzzle },
    { name = "Wirecutter", run = stepWirecutter },
    { name = "Cabinet search", run = stepCabinetSearch },
    { name = "Keycard grab", run = stepKeycardGrab },
    { name = "Unlock", run = stepUnlock },
    { name = "Exit", run = stepExit },
}

local function runStep(index)
    local step = STEPS[index]
    if not step then
        return
    end
    task.spawn(function()
        state.escapeRunning = true
        local ok, err = pcall(step.run)
        state.escapeRunning = false
        if not ok then
            setStatus("Error in " .. step.name)
            warn("[House of the Locust] " .. tostring(err))
        else
            setStatus(step.name .. " finished")
        end
    end)
end

local function runFullEscape()
    state.escapeRunning = true
    table.clear(state.stepsDone)
    for index, step in ipairs(STEPS) do
        if not keepGoing() then
            setStatus("Stopped")
            return
        end
        state.escapeStep = step.name
        local ok = pcall(step.run)
        if not ok then
            warn("[House of the Locust] step failed: " .. step.name)
        end
        task.wait(0.4)
        if index == #STEPS then
            setStatus("Escape sequence complete")
        end
    end
    state.escapeRunning = false
    Flags.hotl_auto_escape = false
end

local function dodgeLocust()
    local safe = tonumber(flag("hotl_safe_distance", 30)) or 30
    local emergency = tonumber(flag("hotl_emergency_distance", 14)) or 14
    local monster, gap = nearestLocust()
    if not monster or gap > safe then
        return
    end
    local position = pivotOf(monster)
    local mine = myPosition()
    if not position or not mine then
        return
    end
    if os.clock() - state.lastDodge < 0.35 then
        return
    end
    state.lastDodge = os.clock()
    local away = (mine - position)
    if away.Magnitude < 1 then
        away = Vector3.new(1, 0, 0)
    end
    local push = gap <= emergency and 45 or 18
    teleportTo(mine + away.Unit * push, Vector3.zero)
    state.dodges += 1
end

local jumpscareBlocked = false

local function setJumpscareBlock(blocked)
    local event = ReplicatedStorage:FindFirstChild("JumpscareEvent")
    if not event or typeof(getconnections) ~= "function" then
        return false
    end
    local ok = pcall(function()
        for _, connection in ipairs(getconnections(event.OnClientEvent)) do
            if blocked then
                connection:Disable()
            else
                connection:Enable()
            end
        end
    end)
    if ok then
        jumpscareBlocked = blocked
    end
    return ok
end

local function unstickCamera()
    local hum = humanoid()
    if not hum or hum.Health <= 0 or hum.PlatformStand then
        return
    end
    if Camera.CameraType ~= Enum.CameraType.Custom then
        Camera.CameraType = Enum.CameraType.Custom
    end
    if Camera.CameraSubject ~= hum then
        Camera.CameraSubject = hum
    end
end

local savedSpot = nil

local function collectRewardPrompts()
    local claimed = 0
    for _, item in ipairs(Workspace:GetDescendants()) do
        if item:IsA("ProximityPrompt") and item.Enabled then
            local text = (tostring(item.ActionText) .. " " .. tostring(item.ObjectText)):lower()
            if text:find("claim", 1, true) or text:find("reward", 1, true)
                or text:find("collect", 1, true) or text:find("pick", 1, true) then
                local holder = item.Parent
                local position = holder and pivotOf(holder)
                if position and distanceTo(position) <= 400 then
                    travelTo(position, 5)
                    firePrompt(item)
                    claimed += 1
                    task.wait(0.35)
                end
            end
        end
    end

    local gui = LocalPlayer:FindFirstChild("PlayerGui")
    if gui then
        for _, item in ipairs(gui:GetDescendants()) do
            if (item:IsA("TextButton") or item:IsA("ImageButton")) and item.Visible then
                local text = (tostring(item.Name) .. " " .. tostring(item:IsA("TextButton") and item.Text or "")):lower()
                if text:find("claim", 1, true) or text:find("reward", 1, true) or text:find("collect", 1, true) then
                    pcall(function()
                        for _, connection in ipairs(getconnections(item.MouseButton1Click)) do
                            connection:Fire()
                        end
                    end)
                    claimed += 1
                    task.wait(0.25)
                end
            end
        end
    end
    return claimed
end

local function applyFastProgression()
    local speed = tonumber(flag("hotl_walk_speed", 16)) or 16
    local hum = humanoid()
    if hum and not hum.PlatformStand and hum.Health > 0 then
        if math.abs(hum.WalkSpeed - speed) > 0.5 then
            hum.WalkSpeed = speed
        end
    end
    for _, item in ipairs(Workspace:GetDescendants()) do
        if item:IsA("ProximityPrompt") and item.HoldDuration > 0 then
            pcall(function()
                item.HoldDuration = 0
            end)
        end
    end
end

local function teleportTarget(choice)
    if choice == "Exit" then
        local target = findObjective("exit")
        return target and target.position or nil
    elseif choice == "Nearest cabinet" or choice == "Nearest unsearched cabinet" then
        local best, bestGap = nil, math.huge
        for _, cabinet in ipairs(cabinets()) do
            local position = pivotOf(cabinet)
            local skip = choice == "Nearest unsearched cabinet" and cabinetSearched(cabinet)
            if position and not skip then
                local gap = distanceTo(position)
                if gap < bestGap then
                    best, bestGap = position, gap
                end
            end
        end
        return best
    elseif choice == "Wirecutter" then
        local tool = Workspace:FindFirstChild("WireCutter")
        return tool and pivotOf(tool) or nil
    elseif choice == "Keycard" then
        local target = findObjective("keycard")
        return target and target.position or nil
    elseif choice == "Cube puzzle" then
        local target = findObjective("cube")
        return target and target.position or nil
    elseif choice == "Locust" then
        local monster = nearestLocust()
        return monster and pivotOf(monster) or nil
    elseif choice == "Spawn" then
        local spawn = Workspace:FindFirstChild("SpawnLocation")
        return spawn and spawn.Position or nil
    elseif choice == "Saved spot" then
        return savedSpot
    end
    return nil
end

local function panicTeleport()
    local mine = myPosition()
    if not mine then
        return false
    end
    local monster = nearestLocust()
    local best, bestGap = nil, -1
    for _, cabinet in ipairs(cabinets()) do
        local position = pivotOf(cabinet)
        if position and not cabinetSearched(cabinet) then
            local gap = monster and (position - pivotOf(monster)).Magnitude or distanceTo(position)
            if gap > bestGap then
                best, bestGap = position, gap
            end
        end
    end
    if not best then
        return false
    end
    teleportTo(best)
    return true
end

local espTab = window:Tab({
    Name = "ESP",
    Icon = "binoculars",
    Description = "Monster, cabinet and objective vision",
})

local monsterBox = espTab:Section({ Title = "Monster", Column = 1 })

monsterBox:Toggle({
    Text = "Monster ESP",
    Info = "Tracks every Locust in the house",
    Flag = "hotl_monster_esp",
    Default = true,
})

monsterBox:Toggle({
    Text = "Monster chams",
    Flag = "hotl_monster_chams",
    Default = true,
})

monsterBox:Toggle({
    Text = "Monster tracer",
    Info = "Draws a line from the bottom of your screen",
    Flag = "hotl_monster_tracer",
    Default = false,
})

monsterBox:Dropdown({
    Text = "Monster colour",
    Flag = "hotl_monster_color",
    Options = COLOR_NAMES,
    Default = "Red",
})

local cabinetBox = espTab:Section({ Title = "Cabinets", Column = 1 })

cabinetBox:Toggle({
    Text = "Cabinet ESP",
    Info = "All 28 cabinets, even the ones streamed out",
    Flag = "hotl_cabinet_esp",
    Default = true,
})

cabinetBox:Toggle({
    Text = "Hide searched cabinets",
    Flag = "hotl_hide_searched",
    Default = true,
})

cabinetBox:Toggle({
    Text = "Cabinet chams",
    Flag = "hotl_cabinet_chams",
    Default = false,
})

cabinetBox:Slider({
    Text = "Cham nearest cabinets",
    Info = "Only the closest few get filled in",
    Flag = "hotl_cabinet_chams_count",
    Min = 1,
    Max = 28,
    Default = 5,
})

cabinetBox:Dropdown({
    Text = "Cabinet colour",
    Flag = "hotl_cabinet_color",
    Options = COLOR_NAMES,
    Default = "Cyan",
})

local playerBox = espTab:Section({ Title = "Players", Column = 2 })

playerBox:Toggle({
    Text = "Player ESP",
    Info = "Names and distance for everyone else in the house",
    Flag = "hotl_player_esp",
    Default = true,
})

playerBox:Toggle({
    Text = "Player chams",
    Flag = "hotl_player_chams",
    Default = false,
})

playerBox:Toggle({
    Text = "Player tracer",
    Flag = "hotl_player_tracer",
    Default = false,
})

playerBox:Dropdown({
    Text = "Player colour",
    Info = "Downed players always show red",
    Flag = "hotl_player_color",
    Options = COLOR_NAMES,
    Default = "Green",
})

local objectiveBox = espTab:Section({ Title = "Objectives", Column = 2 })

objectiveBox:Toggle({
    Text = "Objective ESP",
    Info = "Exit, keyhole, keycard reader, door wire, wirecutter and cubes",
    Flag = "hotl_objective_esp",
    Default = true,
})

objectiveBox:Toggle({
    Text = "Objective chams",
    Flag = "hotl_objective_chams",
    Default = true,
})

objectiveBox:Dropdown({
    Text = "Objective colour",
    Flag = "hotl_objective_color",
    Options = COLOR_NAMES,
    Default = "Yellow",
})

local visionBox = espTab:Section({ Title = "General", Column = 2 })

visionBox:Toggle({
    Text = "Show distance",
    Flag = "hotl_show_distance",
    Default = true,
})

visionBox:Slider({
    Text = "Max distance",
    Flag = "hotl_max_distance",
    Min = 50,
    Max = 1000,
    Default = 400,
    Suffix = " studs",
})

visionBox:Keybind({
    Text = "Toggle all ESP",
    Info = "Flips every ESP switch at once",
    Flag = "hotl_esp_key",
    Default = Enum.KeyCode.F,
    Mode = "Toggle",
    Callback = function(active)
        for _, name in ipairs({
            "hotl_monster_esp", "hotl_cabinet_esp", "hotl_objective_esp",
        }) do
            Flags[name] = active
        end
        if not active then
            clearVision()
        end
        window:Notify({
            Type = "info",
            Title = active and "ESP on" or "ESP off",
            Text = active and "Monster, cabinet and objective ESP enabled." or "All ESP hidden.",
            Duration = 2,
        })
    end,
})

visionBox:Button({
    Text = "Where am I up to",
    ButtonText = "Check",
    Callback = function()
        task.spawn(function()
            local searched, total = 0, 0
            for _, cabinet in ipairs(cabinets()) do
                total += 1
                if cabinetSearched(cabinet) then
                    searched += 1
                end
            end
            local names = {}
            for _, target in ipairs(objectiveTargets()) do
                names[#names + 1] = target.label
            end
            window:Notify({
                Type = "info",
                Title = string.format("Cabinets %d/%d searched", searched, total),
                Text = #names > 0 and ("Objectives up: " .. table.concat(names, ", ")) or "No objectives are active yet.",
                Duration = 8,
            })
        end)
    end,
})

local escapeTab = window:Tab({
    Name = "Auto Escape",
    Icon = "zap",
    Description = "Runs the escape from the cubes to the door",
})

local runBox = escapeTab:Section({ Title = "Full run", Column = 1 })

local escapeLabel = runBox:Label("Idle")

runBox:Toggle({
    Text = "Full auto escape",
    Info = "Every step in order, cubes through to the exit",
    Flag = "hotl_auto_escape",
    Default = false,
    Callback = function(on)
        if on then
            task.spawn(runFullEscape)
            window:Notify({
                Type = "success",
                Title = "Auto escape started",
                Text = "Running every step in sequence.",
                Duration = 3,
            })
        else
            abortEscape()
        end
    end,
})

runBox:Button({
    Text = "Stop / abort",
    ButtonText = "Abort",
    Callback = function()
        abortEscape()
        window:Notify({
            Type = "warning",
            Title = "Aborted",
            Text = "The escape run was stopped.",
            Duration = 3,
        })
    end,
})

local stepBox = escapeTab:Section({ Title = "Single steps", Column = 1 })

for index, step in ipairs(STEPS) do
    stepBox:Button({
        Text = string.format("Step %d - %s", index, step.name),
        ButtonText = "Run",
        Callback = function()
            runStep(index)
        end,
    })
end

local optionBox = escapeTab:Section({ Title = "Options", Column = 2 })

optionBox:Toggle({
    Text = "Instant search",
    Info = "Skips the pause between cabinet searches",
    Flag = "hotl_instant_search",
    Default = false,
})

optionBox:Slider({
    Text = "Locust flee radius",
    Info = "Waits instead of searching while the Locust is this close",
    Flag = "hotl_flee_radius",
    Min = 0,
    Max = 150,
    Default = 45,
    Suffix = " studs",
})

optionBox:Toggle({
    Text = "Include keycard grab",
    Info = "Runs step 4 as part of the full sequence",
    Flag = "hotl_include_keycard",
    Default = true,
})

optionBox:Button({
    Text = "Progress report",
    ButtonText = "Report",
    Callback = function()
        local lines = {}
        for _, step in ipairs(STEPS) do
            local done = state.stepsDone[step.name]
            lines[#lines + 1] = string.format("%s: %s", step.name, done and "done" or "pending")
        end
        window:Notify({
            Type = "info",
            Title = "Escape progress",
            Text = table.concat(lines, " | "),
            Duration = 8,
        })
    end,
})

local autoTab = window:Tab({
    Name = "Automation",
    Icon = "gauge",
    Description = "Auto win, farming, rewards and progression",
})

local winBox = autoTab:Section({ Title = "Auto win", Column = 1 })

local farmLabel = winBox:Label("Rounds won this session: 0")

winBox:Toggle({
    Text = "Auto win",
    Info = "Runs the whole escape the moment a round is playable",
    Flag = "hotl_auto_win",
    Default = false,
    Callback = function(on)
        window:Notify({
            Type = on and "success" or "info",
            Title = on and "Auto win armed" or "Auto win off",
            Text = on and "It will escape as soon as you can move." or "No longer escaping automatically.",
            Duration = 3,
        })
    end,
})

winBox:Toggle({
    Text = "Auto farm rounds",
    Info = "Keeps winning round after round without you touching it",
    Flag = "hotl_auto_farm",
    Default = false,
})

winBox:Slider({
    Text = "Delay between rounds",
    Flag = "hotl_farm_delay",
    Min = 1,
    Max = 60,
    Default = 8,
    Suffix = "s",
})

local rewardBox = autoTab:Section({ Title = "Rewards", Column = 1 })

rewardBox:Toggle({
    Text = "Auto collect rewards",
    Info = "Claims reward prompts in the map and claim buttons on screen",
    Flag = "hotl_auto_rewards",
    Default = true,
})

rewardBox:Button({
    Text = "Collect rewards now",
    ButtonText = "Collect",
    Callback = function()
        task.spawn(function()
            local claimed = collectRewardPrompts()
            window:Notify({
                Type = claimed > 0 and "success" or "info",
                Title = "Rewards",
                Text = claimed > 0 and (claimed .. " claimed.") or "Nothing to claim right now.",
                Duration = 3,
            })
        end)
    end,
})

local progressBox = autoTab:Section({ Title = "Fast progression", Column = 2 })

progressBox:Toggle({
    Text = "Fast progression",
    Info = "Zeroes prompt hold times and applies your walk speed",
    Flag = "hotl_fast_progression",
    Default = false,
})

progressBox:Slider({
    Text = "Walk speed",
    Flag = "hotl_walk_speed",
    Min = 16,
    Max = 120,
    Default = 26,
})

local smoothBox = autoTab:Section({ Title = "Smooth GUI", Column = 2 })

smoothBox:Toggle({
    Text = "Smooth movement",
    Info = "Glides between targets instead of snapping, much less jarring",
    Flag = "hotl_smooth_movement",
    Default = true,
})

smoothBox:Slider({
    Text = "Travel speed",
    Flag = "hotl_travel_speed",
    Min = 20,
    Max = 400,
    Default = 90,
    Suffix = " studs/s",
})

smoothBox:Slider({
    Text = "ESP refresh rate",
    Info = "Lower this if the menu feels heavy on mobile",
    Flag = "hotl_esp_rate",
    Min = 5,
    Max = 60,
    Default = 20,
    Suffix = " hz",
})

local teleportTab = window:Tab({
    Name = "Teleports",
    Icon = "globe",
    Description = "Jump to objectives, cabinets and players",
})

local tpBox = teleportTab:Section({ Title = "Objectives", Column = 1 })

tpBox:Dropdown({
    Text = "Destination",
    Flag = "hotl_tp_target",
    Options = {
        "Exit", "Nearest cabinet", "Nearest unsearched cabinet", "Wirecutter",
        "Keycard", "Cube puzzle", "Locust", "Spawn", "Saved spot",
    },
    Default = "Exit",
})

tpBox:Button({
    Text = "Teleport",
    ButtonText = "Go",
    Callback = function()
        task.spawn(function()
            local choice = flag("hotl_tp_target", "Exit")
            local position = teleportTarget(choice)
            if not position then
                window:Notify({
                    Type = "warning",
                    Title = "Teleport",
                    Text = choice .. " is not in the map right now.",
                    Duration = 3,
                })
                return
            end
            if not travelTo(position, 4) then
                window:Notify({
                    Type = "warning",
                    Title = "Teleport",
                    Text = "You are anchored, so the game is holding you in place.",
                    Duration = 4,
                })
                return
            end
            window:Notify({ Type = "success", Title = "Teleport", Text = "Arrived at " .. choice .. ".", Duration = 2 })
        end)
    end,
})

tpBox:Button({
    Text = "Save current spot",
    ButtonText = "Save",
    Callback = function()
        savedSpot = myPosition()
        window:Notify({
            Type = savedSpot and "success" or "warning",
            Title = "Saved spot",
            Text = savedSpot and "Position stored, pick Saved spot to come back." or "Could not read your position.",
            Duration = 3,
        })
    end,
})

local tpPlayerBox = teleportTab:Section({ Title = "Players", Column = 2 })

local NOBODY = "Nobody else in the server"
local playerOptions = { NOBODY }

local playerDropdown = tpPlayerBox:Dropdown({
    Text = "Player",
    Info = "Hit refresh after someone joins or leaves",
    Flag = "hotl_tp_player",
    Options = playerOptions,
    Default = NOBODY,
})

local function refreshPlayerList()
    table.clear(playerOptions)
    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= LocalPlayer then
            playerOptions[#playerOptions + 1] = other.Name
        end
    end
    if #playerOptions == 0 then
        playerOptions[1] = NOBODY
    end
    playerDropdown:Set(playerOptions[1])
    return #playerOptions, playerOptions[1] ~= NOBODY
end

tpPlayerBox:Button({
    Text = "Refresh player list",
    ButtonText = "Refresh",
    Callback = function()
        local count, real = refreshPlayerList()
        window:Notify({
            Type = real and "success" or "info",
            Title = "Players",
            Text = real and (count .. " other players listed.") or "You are alone in this server.",
            Duration = 3,
        })
    end,
})

tpPlayerBox:Button({
    Text = "Teleport to player",
    ButtonText = "Go",
    Callback = function()
        task.spawn(function()
            local name = flag("hotl_tp_player", nil)
            local other = name and Players:FindFirstChild(name)
            local position = other and other.Character and pivotOf(other.Character)
            if not position then
                window:Notify({ Type = "warning", Title = "Teleport", Text = "That player has no character right now.", Duration = 3 })
                return
            end
            travelTo(position, 5)
        end)
    end,
})

local protectionTab = window:Tab({
    Name = "Protection",
    Icon = "shield",
    Description = "Dodging, jumpscare blocking and revives",
})

local dodgeBox = protectionTab:Section({ Title = "Dodging", Column = 1 })

dodgeBox:Toggle({
    Text = "Auto dodge",
    Info = "Pushes you away when the Locust closes in",
    Flag = "hotl_auto_dodge",
    Default = true,
})

dodgeBox:Slider({
    Text = "Safe distance",
    Info = "Starts dodging inside this range",
    Flag = "hotl_safe_distance",
    Min = 5,
    Max = 120,
    Default = 30,
    Suffix = " studs",
})

dodgeBox:Slider({
    Text = "Emergency distance",
    Info = "Below this you get thrown much further",
    Flag = "hotl_emergency_distance",
    Min = 3,
    Max = 60,
    Default = 14,
    Suffix = " studs",
})

local safetyBox = protectionTab:Section({ Title = "Safety", Column = 2 })

local safetyLabel = safetyBox:Label("Locust: unknown")

safetyBox:Toggle({
    Text = "Anti jumpscare",
    Info = "Cuts the client handler that hijacks your camera and screams",
    Flag = "hotl_anti_jumpscare",
    Default = true,
    Callback = function(on)
        if not setJumpscareBlock(on) then
            window:Notify({
                Type = "warning",
                Title = "Anti jumpscare",
                Text = "Your executor does not expose getconnections.",
                Duration = 4,
            })
        end
    end,
})

safetyBox:Toggle({
    Text = "Unstick camera",
    Info = "Puts the camera back on your character if a scare leaves it locked",
    Flag = "hotl_unstick_camera",
    Default = true,
})

safetyBox:Toggle({
    Text = "Auto revive",
    Flag = "hotl_auto_revive",
    Default = true,
})

safetyBox:Button({
    Text = "Panic teleport",
    ButtonText = "Panic",
    Callback = function()
        task.spawn(function()
            window:Notify({
                Type = panicTeleport() and "success" or "warning",
                Title = "Panic teleport",
                Text = "Sent you to the cabinet furthest from the Locust.",
                Duration = 3,
            })
        end)
    end,
})

local visionClock = 0

RunService.RenderStepped:Connect(function(delta)
    visionClock += delta
    local rate = math.clamp(tonumber(flag("hotl_esp_rate", 20)) or 20, 5, 60)
    if visionClock < (1 / rate) then
        return
    end
    visionClock = 0
    if not pcall(refreshVision) then
        clearVision()
    end
    if isOn("hotl_unstick_camera") then
        pcall(unstickCamera)
    end
end)

local function roundPlayable()
    local hum = humanoid()
    local root = rootPart()
    return hum ~= nil and root ~= nil
        and hum.Health > 0
        and not hum.PlatformStand
        and not root.Anchored
end

task.spawn(function()
    local wins = 0
    while true do
        task.wait(1)
        if (isOn("hotl_auto_win") or isOn("hotl_auto_farm")) and not state.escapeRunning then
            if roundPlayable() then
                setStatus("Auto win: starting")
                local ok = pcall(runFullEscape)
                if ok then
                    wins += 1
                    setLabel(farmLabel, "Rounds won this session: " .. wins)
                end
                if isOn("hotl_auto_farm") then
                    local delay = tonumber(flag("hotl_farm_delay", 8)) or 8
                    setStatus("Waiting " .. delay .. "s for the next round")
                    task.wait(delay)
                else
                    Flags.hotl_auto_win = false
                end
            else
                setStatus("Waiting for a playable round")
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(6)
        if isOn("hotl_auto_rewards") then
            pcall(collectRewardPrompts)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(1)
        if isOn("hotl_fast_progression") then
            pcall(applyFastProgression)
        end
    end
end)

Players.PlayerAdded:Connect(refreshPlayerList)
Players.PlayerRemoving:Connect(function()
    task.delay(0.5, refreshPlayerList)
end)
refreshPlayerList()

task.spawn(function()
    while true do
        task.wait(0.1)
        if isOn("hotl_auto_dodge") then
            pcall(dodgeLocust)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.35)
        setLabel(escapeLabel, string.format("%s  ·  %s",
            state.escapeRunning and ("Running: " .. state.escapeStep) or "Idle", state.escapeStatus))
        local _, gap = nearestLocust()
        setLabel(safetyLabel, string.format("Locust: %s  ·  dodges %d  ·  revives %d",
            gap < math.huge and (math.floor(gap) .. " studs") or "unknown", state.dodges, state.revives))
    end
end)

task.spawn(function()
    while true do
        task.wait(0.5)
        local want = isOn("hotl_anti_jumpscare")
        if want ~= jumpscareBlocked then
            setJumpscareBlock(want)
        end
        if want then
            local gui = LocalPlayer:FindFirstChild("PlayerGui")
            local jumpscare = gui and gui:FindFirstChild("Jumpscare")
            if jumpscare then
                for _, item in ipairs(jumpscare:GetChildren()) do
                    if item:IsA("Sound") and item.IsPlaying then
                        item:Stop()
                    end
                end
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(1)
        if isOn("hotl_auto_revive") then
            local revived = false
            for _, other in ipairs(Players:GetPlayers()) do
                if other ~= LocalPlayer and other.Character then
                    for _, prompt in ipairs(promptsIn(other.Character)) do
                        local text = (tostring(prompt.ActionText) .. tostring(prompt.ObjectText)):lower()
                        if text:find("reviv", 1, true) or text:find("help", 1, true) then
                            local position = pivotOf(other.Character)
                            if position and distanceTo(position) <= 250 then
                                travelTo(position, 5)
                                firePrompt(prompt)
                                state.revives += 1
                                revived = true
                                task.wait(1.5)
                            end
                        end
                    end
                end
            end

            local hum = humanoid()
            local downed = (hum and hum.Health <= 0)
                or (LocalPlayer:GetAttribute("Downed") == true)
                or (LocalPlayer:GetAttribute("Knocked") == true)
            if downed and not revived then
                local revive = ReplicatedStorage:FindFirstChild("ReviveEvent")
                if revive and revive:IsA("RemoteEvent") then
                    pcall(function()
                        revive:FireServer()
                    end)
                    task.wait(2)
                end
            end
        end
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    table.clear(state.searched)
    clearVision()
end)

window:Notify({
    Type = "success",
    Title = "House of the Locust",
    Text = "Loaded. Press RightShift to toggle, F for all ESP.",
    Duration = 5,
})

return window
