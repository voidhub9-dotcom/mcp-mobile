local Snowy = loadstring(readfile("SnowyStudios.luau"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local window = Snowy:Window({
    Title = "Snowy Studios",
    Subtitle = "DOORS",
    IconPack = "phosphor",
    Logo = "rbxassetid://123802801726537",
    LogoRectOffset = Vector2.new(40, 256),
    LogoRectSize = Vector2.new(945, 457),
    Keybind = Enum.KeyCode.RightShift,
})

local Flags = Snowy.Flags
local Remotes = ReplicatedStorage:WaitForChild("RemotesFolder", 10)

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

local ENTITY_NAMES = {
    "Rush", "Ambush", "Eyes", "Screech", "Halt", "Seek", "Figure", "Timothy",
    "Jack", "Dupe", "Snare", "A-60", "A-90", "Glitch", "Dread", "Giggle",
    "Hide", "Void", "Shade", "Spider", "Lookman", "Gloombat", "Vacuum",
    "Jeff", "Grumble", "Void Mass",
}

local ITEM_NAMES = {
    "Lockpick", "Skeleton Key", "Shears", "Multitool", "Crucifix", "Vitamins",
    "Bandage", "Flashlight", "Lighter", "Candle", "Lantern", "Alarm Clock",
    "Smoke Bomb", "Gummy Bat", "Estrogen", "Key", "Battery",
}

local BLOCKABLE = {
    ["Screech"] = "Screech",
    ["Halt"] = "HaltCrucifix",
    ["A-90"] = "A90",
    ["Dread"] = "Dread",
    ["Surge"] = "SurgeRemote",
    ["Giggle"] = "Giggle",
    ["Greed"] = "Greed",
    ["Seek slop"] = "SeekSlop",
    ["Spider"] = "SpiderJumpscare",
    ["Shade"] = "ShadeResult",
    ["Jumpscares"] = "Jumpscare",
    ["Camera shake"] = "CamShake",
    ["Camera lock"] = "CamLock",
    ["Cutscenes"] = "Cutscene",
    ["Footsteps"] = "Footstep",
    ["Ragdoll"] = "Ragdoll",
    ["Vignette"] = "Vignette",
}

local state = {
    blocked = {},
    grabbed = 0,
    hides = 0,
    autoRooms = false,
    flying = false,
    freecam = false,
    savedFov = Camera.FieldOfView,
    savedAmbient = Lighting.Ambient,
    savedOutdoor = Lighting.OutdoorAmbient,
    savedFogEnd = Lighting.FogEnd,
    savedBrightness = Lighting.Brightness,
    notifications = {},
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

local function notify(kind, title, text, duration)
    window:Notify({
        Type = kind,
        Title = title,
        Text = text,
        Duration = duration or (isOn("dr_persistent_notifs") and 15 or 4),
    })
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
    return nil
end

local function distanceTo(position)
    local mine = myPosition()
    if not mine or not position then
        return math.huge
    end
    return (mine - position).Magnitude
end

local function currentRoomNumber()
    return tonumber(LocalPlayer:GetAttribute("CurrentRoom")) or 0
end

local function roomsFolder()
    return Workspace:FindFirstChild("CurrentRooms")
end

local function latestRoom()
    local folder = roomsFolder()
    if not folder then
        return nil
    end
    local best, bestNumber = nil, -1
    for _, room in ipairs(folder:GetChildren()) do
        local number = tonumber(room.Name) or -1
        if number > bestNumber then
            best, bestNumber = room, number
        end
    end
    return best, bestNumber
end

local function roomByNumber(number)
    local folder = roomsFolder()
    return folder and folder:FindFirstChild(tostring(number)) or nil
end

local function liveEntities()
    local list = {}
    local folder = Workspace:FindFirstChild("LiveEntities")
    if folder then
        for _, item in ipairs(folder:GetChildren()) do
            list[#list + 1] = item
        end
    end
    return list
end

local function remote(name)
    return Remotes and Remotes:FindFirstChild(name) or nil
end

local function fireRemote(name, ...)
    local target = remote(name)
    if not target then
        return false
    end
    return (pcall(function(...)
        if target:IsA("RemoteFunction") then
            target:InvokeServer(...)
        else
            target:FireServer(...)
        end
    end, ...))
end

local function setRemoteBlocked(name, blocked)
    local target = remote(name)
    if not target or typeof(getconnections) ~= "function" then
        return false
    end
    local signal = target:IsA("RemoteEvent") and target.OnClientEvent or nil
    if not signal then
        return false
    end
    local ok = pcall(function()
        for _, connection in ipairs(getconnections(signal)) do
            if blocked then
                connection:Disable()
            else
                connection:Enable()
            end
        end
    end)
    if ok then
        state.blocked[name] = blocked
    end
    return ok
end

local function fireLocalRemote(name, ...)
    local target = remote(name)
    if not target or typeof(getconnections) ~= "function" then
        return false
    end
    local args = table.pack(...)
    return (pcall(function()
        for _, connection in ipairs(getconnections(target.OnClientEvent)) do
            connection:Fire(table.unpack(args, 1, args.n))
        end
    end))
end

local function allPrompts()
    local list = {}
    for _, item in ipairs(Workspace:GetDescendants()) do
        if item:IsA("ProximityPrompt") then
            list[#list + 1] = item
        end
    end
    return list
end

local function firePrompt(prompt)
    if typeof(prompt) ~= "Instance" or not prompt:IsA("ProximityPrompt") then
        return false
    end
    local hold = prompt.HoldDuration
    pcall(function()
        prompt.HoldDuration = 0
    end)
    local ok = pcall(function()
        fireproximityprompt(prompt)
    end)
    task.delay(0.3, function()
        pcall(function()
            if not isOn("dr_instant_interact") then
                prompt.HoldDuration = hold
            end
        end)
    end)
    return ok
end

local espGui = Instance.new("ScreenGui")
espGui.Name = "DR_Vision"
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
        marker.arrow:Destroy()
        markers[key] = nil
    end
end

local function releaseHighlight(key)
    local highlight = highlights[key]
    if highlight then
        highlight:Destroy()
        highlights[key] = nil
    end
end

local function ensureMarker(key)
    local marker = markers[key]
    if marker then
        return marker
    end
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromOffset(240, 18)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.Visible = false
    label.Parent = espGui

    local tracer = Instance.new("Frame")
    tracer.BorderSizePixel = 0
    tracer.AnchorPoint = Vector2.new(0.5, 0)
    tracer.Visible = false
    tracer.Parent = espGui

    local arrow = Instance.new("TextLabel")
    arrow.BackgroundTransparency = 1
    arrow.Size = UDim2.fromOffset(24, 24)
    arrow.Font = Enum.Font.GothamBold
    arrow.TextSize = 20
    arrow.Text = "▲"
    arrow.Visible = false
    arrow.Parent = espGui

    marker = { label = label, tracer = tracer, arrow = arrow }
    markers[key] = marker
    return marker
end

local function espColor(categoryFlag, fallback)
    if isOn("dr_rainbow") then
        return Color3.fromHSV((tick() * 0.25) % 1, 0.75, 1)
    end
    return colorFor(categoryFlag, fallback)
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
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = espGui
        highlights[key] = highlight
    end
    highlight.Adornee = model
    highlight.FillColor = color
    highlight.OutlineColor = color
    highlight.FillTransparency = tonumber(flag("dr_fill_transparency", 60)) / 100
    highlight.OutlineTransparency = tonumber(flag("dr_outline_transparency", 0)) / 100
end

local function drawMarker(key, position, text, color, adornee)
    local marker = ensureMarker(key)
    local point, onScreen = Camera:WorldToViewportPoint(position)
    local viewport = Camera.ViewportSize

    if onScreen then
        marker.arrow.Visible = false
        marker.label.Position = UDim2.fromOffset(point.X - 120, point.Y - 26)
        marker.label.Text = text
        marker.label.TextColor3 = color
        marker.label.TextSize = math.floor(tonumber(flag("dr_text_size", 13)) or 13)
        marker.label.TextTransparency = tonumber(flag("dr_text_transparency", 0)) / 100
        marker.label.TextStrokeTransparency = tonumber(flag("dr_text_outline_transparency", 40)) / 100
        marker.label.Visible = true

        if isOn("dr_tracers") then
            local originChoice = flag("dr_tracer_origin", "Bottom")
            local origin
            if originChoice == "Middle" then
                origin = Vector2.new(viewport.X / 2, viewport.Y / 2)
            elseif originChoice == "Top" then
                origin = Vector2.new(viewport.X / 2, 0)
            else
                origin = Vector2.new(viewport.X / 2, viewport.Y)
            end
            local delta = Vector2.new(point.X, point.Y) - origin
            marker.tracer.Size = UDim2.fromOffset(math.floor(tonumber(flag("dr_tracer_thickness", 2)) or 2), delta.Magnitude)
            marker.tracer.Position = UDim2.fromOffset(origin.X, origin.Y)
            marker.tracer.Rotation = math.deg(math.atan2(delta.Y, delta.X)) - 90
            marker.tracer.BackgroundColor3 = color
            marker.tracer.Visible = true
        else
            marker.tracer.Visible = false
        end
    else
        marker.label.Visible = false
        marker.tracer.Visible = false
        if isOn("dr_arrows") then
            local centre = Vector2.new(viewport.X / 2, viewport.Y / 2)
            local direction = Vector2.new(point.X, point.Y) - centre
            if point.Z < 0 then
                direction = -direction
            end
            if direction.Magnitude > 0 then
                direction = direction.Unit
            else
                direction = Vector2.new(0, -1)
            end
            local radius = tonumber(flag("dr_arrow_radius", 180)) or 180
            local spot = centre + direction * radius
            marker.arrow.Position = UDim2.fromOffset(spot.X - 12, spot.Y - 12)
            marker.arrow.Rotation = math.deg(math.atan2(direction.Y, direction.X)) + 90
            marker.arrow.TextColor3 = color
            marker.arrow.Visible = true
        else
            marker.arrow.Visible = false
        end
    end

    if adornee then
        applyHighlight(key, adornee, color)
    else
        releaseHighlight(key)
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

local function label(text, position)
    if isOn("dr_esp_distance") then
        return string.format("%s  [%d]", text, math.floor(distanceTo(position)))
    end
    return text
end

local function closetsInRoom(room)
    local list = {}
    for _, item in ipairs(room:GetDescendants()) do
        if item:IsA("Model") then
            local name = item.Name:lower()
            if name:find("closet", 1, true) or name:find("wardrobe", 1, true) or name:find("bed", 1, true) then
                if item:FindFirstChildWhichIsA("ProximityPrompt", true) then
                    list[#list + 1] = item
                end
            end
        end
    end
    return list
end

local function allClosets()
    local list = {}
    local folder = roomsFolder()
    if not folder then
        return list
    end
    for _, room in ipairs(folder:GetChildren()) do
        for _, closet in ipairs(closetsInRoom(room)) do
            list[#list + 1] = closet
        end
    end
    return list
end

local function nearestCloset()
    local best, bestGap = nil, math.huge
    for _, closet in ipairs(allClosets()) do
        local position = pivotOf(closet)
        if position then
            local gap = distanceTo(position)
            if gap < bestGap then
                best, bestGap = closet, gap
            end
        end
    end
    return best, bestGap
end

local function doorsInPlay()
    local list = {}
    local folder = roomsFolder()
    if not folder then
        return list
    end
    for _, room in ipairs(folder:GetChildren()) do
        local door = room:FindFirstChild("Door")
        if door then
            list[#list + 1] = door
        end
    end
    return list
end

local function nextDoor()
    local number = currentRoomNumber()
    for offset = 0, 3 do
        local room = roomByNumber(number + offset)
        local door = room and room:FindFirstChild("Door")
        if door and door:FindFirstChild("Collision") then
            return door
        end
    end
    return nil
end

local function promptCategory(prompt)
    local action = tostring(prompt.ActionText):lower()
    local object = tostring(prompt.ObjectText):lower()
    local both = action .. " " .. object
    if both:find("drawer", 1, true) or both:find("loot", 1, true) or both:find("chest", 1, true) then
        return "Chest"
    end
    if both:find("coin", 1, true) or both:find("gold", 1, true) or both:find("collect", 1, true) then
        return "Money"
    end
    if both:find("key", 1, true) or both:find("obtain", 1, true) then
        return "Item"
    end
    if both:find("ladder", 1, true) or both:find("climb", 1, true) then
        return "Ladder"
    end
    if both:find("hide", 1, true) or both:find("closet", 1, true) then
        return "Closet"
    end
    return "Objective"
end

local function itemDrops()
    local list = {}
    local drops = Workspace:FindFirstChild("Drops")
    if drops then
        for _, item in ipairs(drops:GetChildren()) do
            list[#list + 1] = item
        end
    end
    return list
end

local function refreshVision()
    local maxDistance = tonumber(flag("dr_render_distance", 500)) or 500
    local alive = {}

    local function mark(key, position, text, colorFlag, fallback, adornee)
        if not position or distanceTo(position) > maxDistance then
            return
        end
        alive[key] = true
        drawMarker(key, position, label(text, position), espColor(colorFlag, fallback), adornee)
    end

    if isOn("dr_esp_doors") then
        for index, door in ipairs(doorsInPlay()) do
            local position = pivotOf(door)
            local roomId = door:GetAttribute("RoomID")
            mark("door" .. index, position, "Door " .. tostring(roomId or "?"),
                "dr_color_door", "Cyan", door)
        end
    end

    if isOn("dr_esp_closets") then
        for index, closet in ipairs(allClosets()) do
            mark("closet" .. index, pivotOf(closet), "Closet", "dr_color_closet", "Green", closet)
        end
    end

    if isOn("dr_esp_players") then
        for index, other in ipairs(Players:GetPlayers()) do
            local char = other ~= LocalPlayer and other.Character or nil
            if char then
                mark("player" .. index, pivotOf(char), other.DisplayName, "dr_color_player", "White", char)
            end
        end
    end

    if isOn("dr_esp_entities") then
        local wanted = flag("dr_entity_filter", {})
        local filterOn = typeof(wanted) == "table" and #wanted > 0
        local allow = {}
        if filterOn then
            for _, name in ipairs(wanted) do
                allow[name] = true
            end
        end
        for index, entity in ipairs(liveEntities()) do
            local name = entity.Name
            if not filterOn or allow[name] then
                mark("entity" .. index, pivotOf(entity), name, "dr_color_entity", "Red", entity)
            end
        end
    end

    if isOn("dr_esp_items") then
        for index, drop in ipairs(itemDrops()) do
            mark("drop" .. index, pivotOf(drop), drop.Name, "dr_color_item", "Yellow", drop)
        end
    end

    local wantChest = isOn("dr_esp_chests")
    local wantMoney = isOn("dr_esp_money")
    local wantLadder = isOn("dr_esp_ladders")
    local wantObjective = isOn("dr_esp_objectives")
    if wantChest or wantMoney or wantLadder or wantObjective then
        for index, prompt in ipairs(allPrompts()) do
            local category = promptCategory(prompt)
            local show =
                (category == "Chest" and wantChest)
                or (category == "Money" and wantMoney)
                or (category == "Ladder" and wantLadder)
                or ((category == "Objective" or category == "Item") and wantObjective)
            if show and prompt.Enabled then
                local holder = prompt.Parent
                local position = holder and pivotOf(holder)
                local text = tostring(prompt.ObjectText)
                if text == "" then
                    text = tostring(prompt.ActionText)
                end
                mark("prompt" .. index, position, text, "dr_color_objective", "Orange", nil)
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

local flightVelocity = nil

local function stopFlight()
    state.flying = false
    if flightVelocity then
        flightVelocity:Destroy()
        flightVelocity = nil
    end
    local hum = humanoid()
    if hum then
        hum.PlatformStand = false
    end
end

local function updateFlight(delta)
    if not isOn("dr_fly") then
        if state.flying then
            stopFlight()
        end
        return
    end
    local root = rootPart()
    local hum = humanoid()
    if not root or not hum then
        return
    end
    state.flying = true
    hum.PlatformStand = true
    if not flightVelocity or flightVelocity.Parent ~= root then
        if flightVelocity then
            flightVelocity:Destroy()
        end
        flightVelocity = Instance.new("BodyVelocity")
        flightVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        flightVelocity.Velocity = Vector3.zero
        flightVelocity.Parent = root
    end

    local direction = Vector3.zero
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
        direction += Camera.CFrame.LookVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
        direction -= Camera.CFrame.LookVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then
        direction -= Camera.CFrame.RightVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
        direction += Camera.CFrame.RightVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        direction += Vector3.new(0, 1, 0)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        direction -= Vector3.new(0, 1, 0)
    end

    local moveVector = hum.MoveDirection
    if direction.Magnitude == 0 and moveVector.Magnitude > 0 then
        direction = moveVector
    end

    local speed = tonumber(flag("dr_fly_speed", 60)) or 60
    flightVelocity.Velocity = direction.Magnitude > 0 and direction.Unit * speed or Vector3.zero
end

local function applyNoClip()
    local char = character()
    if not char then
        return
    end
    local want = isOn("dr_noclip")
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.CanCollide == want then
            part.CanCollide = not want
        end
    end
end

local function applyMovement()
    local hum = humanoid()
    if not hum then
        return
    end
    if isOn("dr_speed") then
        local speed = tonumber(flag("dr_speed_value", 16)) or 16
        if math.abs(hum.WalkSpeed - speed) > 0.4 then
            hum.WalkSpeed = speed
        end
    end
    if isOn("dr_allow_jump") then
        if hum.UseJumpPower then
            hum.JumpPower = math.max(hum.JumpPower, 50)
        else
            hum.JumpHeight = math.max(hum.JumpHeight, 7.2)
        end
    end
    if isOn("dr_no_accel") then
        local root = rootPart()
        if root and hum.MoveDirection.Magnitude == 0 then
            root.AssemblyLinearVelocity = Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
        end
    end
    if isOn("dr_godmode") then
        if hum.Health < hum.MaxHealth then
            hum.Health = hum.MaxHealth
        end
    end
end

local function applyPrompts()
    local range = tonumber(flag("dr_interact_range", 0)) or 0
    local doorRange = tonumber(flag("dr_door_range", 0)) or 0
    local instant = isOn("dr_instant_interact")
    local walls = isOn("dr_interact_walls")
    if range <= 0 and doorRange <= 0 and not instant and not walls then
        return
    end
    for _, prompt in ipairs(allPrompts()) do
        local isDoor = prompt.Name == "ManualOpenPrompt"
        local want = isDoor and doorRange or range
        if want > 0 and prompt.MaxActivationDistance < want then
            prompt.MaxActivationDistance = want
        end
        if instant and prompt.HoldDuration > 0 then
            prompt.HoldDuration = 0
        end
        if walls and prompt.RequiresLineOfSight then
            prompt.RequiresLineOfSight = false
        end
    end
end

local function blacklisted(flagName, text)
    local list = flag(flagName, {})
    if typeof(list) ~= "table" then
        return false
    end
    text = text:lower()
    for _, entry in ipairs(list) do
        if text:find(tostring(entry):lower(), 1, true) then
            return true
        end
    end
    return false
end

local function autoGrab()
    local range = tonumber(flag("dr_grab_range", 30)) or 30
    for _, prompt in ipairs(allPrompts()) do
        if prompt.Enabled then
            local category = promptCategory(prompt)
            if category == "Item" or category == "Money" or category == "Chest" then
                local holder = prompt.Parent
                local position = holder and pivotOf(holder)
                local text = tostring(prompt.ObjectText) .. " " .. tostring(prompt.ActionText)
                if position and distanceTo(position) <= range and not blacklisted("dr_grab_blacklist", text) then
                    if firePrompt(prompt) then
                        state.grabbed += 1
                        task.wait(0.15)
                    end
                end
            end
        end
    end
end

local function threateningEntity()
    local blacklist = flag("dr_hide_blacklist", {})
    local skip = {}
    if typeof(blacklist) == "table" then
        for _, name in ipairs(blacklist) do
            skip[name] = true
        end
    end
    for _, entity in ipairs(liveEntities()) do
        if not skip[entity.Name] then
            return entity
        end
    end
    return nil
end

local function autoHide()
    local entity = threateningEntity()
    if not entity then
        return false
    end
    local closet, gap = nearestCloset()
    if not closet or gap > 120 then
        return false
    end
    local prompt = closet:FindFirstChildWhichIsA("ProximityPrompt", true)
    if not prompt then
        return false
    end
    local root = rootPart()
    local position = pivotOf(closet)
    if root and position and gap > 8 then
        root.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
        task.wait(0.2)
    end
    if firePrompt(prompt) then
        state.hides += 1
        notify("warning", "Auto hide", entity.Name .. " is out, hiding.", 3)
        return true
    end
    return false
end

local function leaveCloset()
    fireRemote("GetOutOfHiding")
end

local function applyRender()
    if isOn("dr_fullbright") then
        Lighting.Brightness = tonumber(flag("dr_bright_intensity", 3)) or 3
        Lighting.Ambient = colorFor("dr_ambient_color", "White")
        Lighting.OutdoorAmbient = colorFor("dr_ambient_color", "White")
    end
    if isOn("dr_no_fog") then
        Lighting.FogEnd = 1e6
    end
    local fov = tonumber(flag("dr_fov", 70)) or 70
    if math.abs(Camera.FieldOfView - fov) > 0.5 and not state.freecam then
        Camera.FieldOfView = fov
    end
end

local function applySeeThroughClosets()
    local want = isOn("dr_see_closets")
    local transparency = (tonumber(flag("dr_closet_transparency", 60)) or 60) / 100
    for _, closet in ipairs(allClosets()) do
        for _, part in ipairs(closet:GetDescendants()) do
            if part:IsA("BasePart") then
                if want then
                    if part:GetAttribute("DR_OldTransparency") == nil then
                        part:SetAttribute("DR_OldTransparency", part.Transparency)
                    end
                    part.Transparency = transparency
                elseif part:GetAttribute("DR_OldTransparency") ~= nil then
                    part.Transparency = part:GetAttribute("DR_OldTransparency")
                    part:SetAttribute("DR_OldTransparency", nil)
                end
            end
        end
    end
end

local thirdPersonActive = false

local function applyThirdPerson()
    local hum = humanoid()
    if not hum then
        return
    end
    if isOn("dr_third_person") then
        thirdPersonActive = true
        local x = tonumber(flag("dr_tp_x", 2)) or 2
        local y = tonumber(flag("dr_tp_y", 1)) or 1
        local z = tonumber(flag("dr_tp_z", 8)) or 8
        hum.CameraOffset = Vector3.new(x, y, z)
        LocalPlayer.CameraMode = Enum.CameraMode.Classic
        LocalPlayer.CameraMaxZoomDistance = math.max(z + 4, 12)
    elseif thirdPersonActive then
        thirdPersonActive = false
        hum.CameraOffset = Vector3.zero
        LocalPlayer.CameraMaxZoomDistance = 0.5
    end
end

local freecamPosition = nil

local function updateFreecam(delta)
    if not isOn("dr_freecam") then
        if state.freecam then
            state.freecam = false
            Camera.CameraType = Enum.CameraType.Custom
            local hum = humanoid()
            if hum then
                Camera.CameraSubject = hum
            end
        end
        return
    end
    if not state.freecam then
        state.freecam = true
        freecamPosition = Camera.CFrame
        Camera.CameraType = Enum.CameraType.Scriptable
    end
    local speed = (tonumber(flag("dr_freecam_speed", 60)) or 60) * delta
    local move = Vector3.zero
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
        move += freecamPosition.LookVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
        move -= freecamPosition.LookVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then
        move -= freecamPosition.RightVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
        move += freecamPosition.RightVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        move += Vector3.new(0, 1, 0)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        move -= Vector3.new(0, 1, 0)
    end
    if move.Magnitude > 0 then
        freecamPosition = freecamPosition + move.Unit * speed
    end
    Camera.CFrame = freecamPosition
end

local function muteGroup(names, muted)
    for _, sound in ipairs(Workspace:GetDescendants()) do
        if sound:IsA("Sound") then
            local lowered = sound.Name:lower()
            for _, key in ipairs(names) do
                if lowered:find(key, 1, true) then
                    sound.Volume = muted and 0 or (sound:GetAttribute("DR_OldVolume") or sound.Volume)
                    if muted and sound:GetAttribute("DR_OldVolume") == nil then
                        sound:SetAttribute("DR_OldVolume", sound.Volume)
                    end
                    break
                end
            end
        end
    end
end

local function autoDoor()
    local door = nextDoor()
    if not door then
        return false
    end
    local prompt = door:FindFirstChild("ManualOpenPrompt")
    local position = pivotOf(door)
    local root = rootPart()
    if root and position and distanceTo(position) > 12 then
        root.CFrame = CFrame.new(position + Vector3.new(0, 3, -4))
        task.wait(0.2)
    end
    if prompt then
        firePrompt(prompt)
    end
    local clientOpen = door:FindFirstChild("ClientOpen")
    if clientOpen and clientOpen:IsA("RemoteEvent") then
        pcall(function()
            clientOpen:FireServer()
        end)
    end
    return true
end

local function autoRoomsStep()
    local door = nextDoor()
    if not door then
        return
    end
    autoDoor()
    task.wait(tonumber(flag("dr_rooms_delay", 1)) or 1)
end

local function heartbeatMinigame()
    fireRemote("ClutchHeartbeat")
end

local function skipToRoom(number)
    fireRemote("SkipToRoomNumber", number)
end

-- The Elevator Breaker minigame's client only ever fires EBF with no
-- arguments once the switch pattern is "solved" locally, and the switches
-- themselves never replicate anywhere else, so the server has nothing to
-- check against — firing EBF the moment the minigame engages finishes it.
local function autoBreakerFire()
    task.wait(0.6)
    if fireRemote("EBF") then
        notify("success", "Breaker", "Elevator power restored.", 3)
    end
end

-- Padlock/PadlockHard build their guess by reading whatever text is
-- currently shown on five parts named "Number" (attributes ID 1-5) under
-- a "Padlock" model, then send that string over PL. Writing the digits
-- directly and firing PL skips the drag-to-rotate UI entirely.
local padlockRunning = false

local function findPadlockDials()
    local model = Workspace:FindFirstChild("Padlock", true)
    if not model then
        return nil
    end
    local dials = {}
    for _, part in ipairs(model:GetDescendants()) do
        if part.Name == "Number" and part:IsA("BasePart") then
            local id = part:GetAttribute("ID")
            local label = part:FindFirstChild("NumberUI") and part.NumberUI:FindFirstChild("TextLabel")
            if id and label then
                dials[id] = label
            end
        end
    end
    if not (dials[1] and dials[2] and dials[3] and dials[4] and dials[5]) then
        return nil
    end
    return dials
end

local function setPadlockGuess(dials, digits)
    for id = 1, 5 do
        dials[id].Text = tostring(digits[id])
    end
end

local function runPadlockBruteforce()
    if padlockRunning then
        return
    end
    padlockRunning = true
    local low = math.floor(tonumber(flag("dr_padlock_min", 0)) or 0)
    local high = math.floor(tonumber(flag("dr_padlock_max", 9)) or 9)
    low, high = math.min(low, high), math.max(low, high)
    local delay = tonumber(flag("dr_padlock_delay", 0.15)) or 0.15

    local dials
    local waited = 0
    while not dials and waited < 6 and isOn("dr_auto_padlock") do
        dials = findPadlockDials()
        if not dials then
            task.wait(0.25)
            waited += 0.25
        end
    end
    if not dials then
        padlockRunning = false
        notify("warning", "Padlock", "No padlock model found to solve.", 3)
        return
    end

    notify("info", "Padlock", string.format("Bruteforcing digits %d-%d, this can take a while.", low, high), 4)
    local digits = { low, low, low, low, low }
    local tried = 0
    while isOn("dr_auto_padlock") and padlockRunning do
        setPadlockGuess(dials, digits)
        fireRemote("PL", table.concat(digits))
        tried += 1
        task.wait(delay)

        local carry = 5
        while carry >= 1 do
            digits[carry] += 1
            if digits[carry] > high then
                digits[carry] = low
                carry -= 1
            else
                break
            end
        end
        if carry == 0 then
            break
        end
        if not Workspace:FindFirstChild("Padlock", true) then
            notify("success", "Padlock", string.format("Solved after %d attempts.", tried), 4)
            break
        end
    end
    padlockRunning = false
end

local function stopPadlockBruteforce()
    padlockRunning = false
    Flags.dr_auto_padlock = false
end

local cartTracking = false
local lastCartAction = 0

local function autoMinecartTick()
    if not cartTracking then
        return
    end
    if os.clock() - lastCartAction < (tonumber(flag("dr_minecart_turn_distance", 15)) or 15) / 20 then
        return
    end
    lastCartAction = os.clock()
    fireRemote("CartControl")
end

local minigameEvent = remote("EngageMinigame")
if minigameEvent and minigameEvent:IsA("RemoteEvent") then
    minigameEvent.OnClientEvent:Connect(function(name, ...)
        if name == "ElevatorBreaker" and isOn("dr_auto_breaker") then
            task.spawn(autoBreakerFire)
        elseif (name == "Padlock" or name == "PadlockHard") and isOn("dr_auto_padlock") then
            task.spawn(runPadlockBruteforce)
        end
    end)
end

local cartControlEvent = remote("CartControl")
if cartControlEvent and cartControlEvent:IsA("RemoteEvent") then
    cartControlEvent.OnClientEvent:Connect(function(model)
        cartTracking = model ~= nil
    end)
end

local padlockHintEvent = remote("PadlockHint")
if padlockHintEvent and padlockHintEvent:IsA("RemoteEvent") then
    padlockHintEvent.OnClientEvent:Connect(function(...)
        if isOn("dr_library_alert") then
            notify("info", "Library code hint", "A new hint appeared in the room.", 5)
        end
    end)
end

local function oxygenValue()
    local char = character()
    return char and char:GetAttribute("Oxygen")
end

local function hasteValue()
    local char = character()
    if not char then
        return 0
    end
    return (char:GetAttribute("SpeedBoost") or 0) + (char:GetAttribute("SpeedBoostBehind") or 0)
end

local fakeCrouchOn = false

local function applyFakeCrouch()
    local want = isOn("dr_fake_crouch")
    if want == fakeCrouchOn then
        return
    end
    fakeCrouchOn = want
    fireRemote("Crouch", want)
end

local playerTab = window:Tab({
    Name = "Player",
    Icon = "user",
    Description = "Movement, interaction range and automation",
})

local moveBox = playerTab:Section({ Title = "Movement", Column = 1 })

moveBox:Toggle({ Text = "Walk speed boost", Flag = "dr_speed", Default = false })
moveBox:Slider({
    Text = "Walk speed",
    Flag = "dr_speed_value",
    Min = 16,
    Max = 120,
    Default = 24,
})
moveBox:Toggle({ Text = "Flight", Info = "WASD to move, Space up, Ctrl down", Flag = "dr_fly", Default = false })
moveBox:Slider({
    Text = "Flight speed",
    Flag = "dr_fly_speed",
    Min = 10,
    Max = 300,
    Default = 60,
})
moveBox:Toggle({ Text = "No clip", Flag = "dr_noclip", Default = false })
moveBox:Toggle({ Text = "No acceleration / sliding", Flag = "dr_no_accel", Default = false })
moveBox:Toggle({ Text = "Allow jump", Flag = "dr_allow_jump", Default = false })
moveBox:Toggle({ Text = "Infinite jumps", Flag = "dr_inf_jump", Default = false })
moveBox:Toggle({ Text = "Anti AFK", Flag = "dr_anti_afk", Default = true })

local interactBox = playerTab:Section({ Title = "Interaction", Column = 1 })

interactBox:Slider({
    Text = "Interaction range",
    Info = "0 leaves the game's own range alone",
    Flag = "dr_interact_range",
    Min = 0,
    Max = 120,
    Default = 0,
})
interactBox:Slider({
    Text = "Door range",
    Flag = "dr_door_range",
    Min = 0,
    Max = 200,
    Default = 0,
})
interactBox:Toggle({ Text = "Instant interactions", Info = "Zeroes every prompt hold time", Flag = "dr_instant_interact", Default = false })
interactBox:Toggle({ Text = "Interact through walls", Flag = "dr_interact_walls", Default = false })
interactBox:Button({
    Text = "Instant closet exit",
    ButtonText = "Exit",
    Callback = function()
        leaveCloset()
        notify("info", "Closet", "Sent the leave-hiding request.", 2)
    end,
})

local autoBox = playerTab:Section({ Title = "Automation", Column = 2 })

local autoLabel = autoBox:Label("Grabbed 0  ·  hides 0")

autoBox:Toggle({ Text = "Auto grab nearby items", Flag = "dr_auto_grab", Default = false })
autoBox:Slider({
    Text = "Grab range",
    Flag = "dr_grab_range",
    Min = 5,
    Max = 120,
    Default = 30,
})
autoBox:Dropdown({
    Text = "Grab blacklist",
    Info = "Prompts containing these words are skipped",
    Flag = "dr_grab_blacklist",
    Multi = true,
    Options = { "Drawer", "Chest", "Coin", "Key", "Bell", "Fire", "Seat" },
    Default = {},
    Placeholder = "Nothing skipped",
})
autoBox:Toggle({ Text = "Auto hide from entities", Flag = "dr_auto_hide", Default = false })
autoBox:Dropdown({
    Text = "Hide blacklist",
    Info = "Entities that should not trigger hiding",
    Flag = "dr_hide_blacklist",
    Multi = true,
    Options = ENTITY_NAMES,
    Default = {},
    Placeholder = "Hide from everything",
})
autoBox:Toggle({ Text = "Watch entities while hiding", Flag = "dr_watch_hiding", Default = false })
autoBox:Toggle({ Text = "Auto heartbeat minigame", Flag = "dr_auto_heartbeat", Default = false })
autoBox:Toggle({
    Text = "Auto breaker",
    Info = "Finishes the Elevator Breaker minigame the instant it starts",
    Flag = "dr_auto_breaker",
    Default = false,
})
autoBox:Toggle({
    Text = "Auto padlock",
    Info = "Bruteforces the Library / Padlock code the moment it opens",
    Flag = "dr_auto_padlock",
    Default = false,
    Callback = function(on)
        if not on then
            stopPadlockBruteforce()
        end
    end,
})
autoBox:Slider({
    Text = "Padlock digit range (min)",
    Flag = "dr_padlock_min",
    Min = 0,
    Max = 9,
    Default = 0,
})
autoBox:Slider({
    Text = "Padlock digit range (max)",
    Flag = "dr_padlock_max",
    Min = 0,
    Max = 9,
    Default = 9,
})
autoBox:Slider({
    Text = "Padlock guess delay",
    Info = "Lower is faster but more likely to trip a rate limit",
    Flag = "dr_padlock_delay",
    Min = 0.05,
    Max = 1,
    Decimals = 2,
    Default = 0.15,
    Suffix = "s",
})
autoBox:Button({
    Text = "Stop bruteforce",
    ButtonText = "Stop",
    Callback = stopPadlockBruteforce,
})
autoBox:Toggle({
    Text = "Fake crouch",
    Info = "Tells the server you are crouched without slowing you down",
    Flag = "dr_fake_crouch",
    Default = false,
})

local sessionBox = playerTab:Section({ Title = "Session", Column = 2 })

sessionBox:Button({
    Text = "Reset character",
    ButtonText = "Reset",
    Callback = function()
        local hum = humanoid()
        if hum then
            hum.Health = 0
        end
    end,
})

sessionBox:Button({
    Text = "Leave to lobby",
    ButtonText = "Lobby",
    Callback = function()
        if not fireRemote("Lobby") then
            notify("warning", "Lobby", "The lobby remote did not accept that.", 3)
        end
    end,
})

sessionBox:Button({
    Text = "Rejoin server",
    ButtonText = "Rejoin",
    Callback = function()
        pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
        end)
    end,
})

sessionBox:Button({
    Text = "Fake revive",
    ButtonText = "Revive",
    Callback = function()
        fireRemote("Revive")
        fireRemote("CheckRevive")
        notify("info", "Revive", "Revive request sent.", 2)
    end,
})

local exploitTab = window:Tab({
    Name = "Exploits",
    Icon = "shield",
    Description = "Entity blocking, god mode and local spawns",
})

local blockBox = exploitTab:Section({ Title = "Block handlers", Column = 1 })

blockBox:Label("Each switch cuts the client handler for that event, so the effect never plays on your screen.")

local BLOCK_ORDER = {
    "Screech", "Halt", "A-90", "Dread", "Surge", "Giggle", "Greed",
    "Seek slop", "Spider", "Shade", "Jumpscares", "Camera shake",
    "Camera lock", "Cutscenes", "Footsteps", "Ragdoll", "Vignette",
}

blockBox:Dropdown({
    Text = "Blocked events",
    Info = "Applied continuously, re-applies when the game reconnects a handler",
    Flag = "dr_blocked_events",
    Multi = true,
    Options = BLOCK_ORDER,
    Default = {},
    Placeholder = "Nothing blocked",
})

blockBox:Button({
    Text = "Block everything listed",
    ButtonText = "Block all",
    Callback = function()
        Flags.dr_blocked_events = table.clone(BLOCK_ORDER)
        notify("success", "Blocking", "Every listed handler is now cut.", 3)
    end,
})

blockBox:Button({
    Text = "Restore all handlers",
    ButtonText = "Restore",
    Callback = function()
        Flags.dr_blocked_events = {}
        for _, name in pairs(BLOCKABLE) do
            setRemoteBlocked(name, false)
        end
        notify("info", "Blocking", "All handlers restored.", 3)
    end,
})

local protectBox = exploitTab:Section({ Title = "Protection", Column = 1 })

protectBox:Toggle({ Text = "God mode", Info = "Keeps health pinned to maximum", Flag = "dr_godmode", Default = false })
protectBox:Toggle({ Text = "Block stun and ragdoll", Flag = "dr_no_stun", Default = false })
protectBox:Toggle({ Text = "Mute footsteps", Flag = "dr_mute_steps", Default = false })
protectBox:Toggle({ Text = "Mute music and effects", Flag = "dr_mute_music", Default = false })
protectBox:Toggle({ Text = "Mute interaction sounds", Flag = "dr_mute_interact", Default = false })

local spawnBox = exploitTab:Section({ Title = "Local spawns", Column = 2 })

spawnBox:Label("These fire the client handler only, so the entity appears for you and nobody else.")

for _, entry in ipairs({
    { name = "Dread", remoteName = "Dread" },
    { name = "A-90", remoteName = "A90" },
    { name = "Screech", remoteName = "Screech" },
    { name = "Giggle", remoteName = "Giggle" },
}) do
    spawnBox:Button({
        Text = "Spawn " .. entry.name .. " locally",
        ButtonText = "Spawn",
        Callback = function()
            local ok = fireLocalRemote(entry.remoteName)
            notify(ok and "success" or "warning", entry.name,
                ok and "Fired the local handler." or "No handler is listening for that.", 3)
        end,
    })
end

local itemBox = exploitTab:Section({ Title = "Items", Column = 2 })

itemBox:Dropdown({
    Text = "Keep these items stocked",
    Info = "Re-equips the item when it leaves your inventory",
    Flag = "dr_infinite_items",
    Multi = true,
    Options = { "Lockpick", "Skeleton Key", "Shears", "Multitool" },
    Default = {},
    Placeholder = "None",
})

itemBox:Toggle({ Text = "Infinite items", Flag = "dr_inf_items", Default = false })

itemBox:Button({
    Text = "Drop held item",
    ButtonText = "Drop",
    Callback = function()
        fireRemote("DropItem")
    end,
})

local renderTab = window:Tab({
    Name = "Render",
    Icon = "palette",
    Description = "Lighting, camera and on-screen alerts",
})

local lightBox = renderTab:Section({ Title = "Lighting", Column = 1 })

lightBox:Toggle({ Text = "Fullbright", Flag = "dr_fullbright", Default = false })
lightBox:Slider({
    Text = "Brightness",
    Flag = "dr_bright_intensity",
    Min = 1,
    Max = 10,
    Default = 3,
})
lightBox:Dropdown({
    Text = "Ambient tint",
    Flag = "dr_ambient_color",
    Options = COLOR_NAMES,
    Default = "White",
})
lightBox:Toggle({ Text = "No fog", Flag = "dr_no_fog", Default = false })

local cameraBox = renderTab:Section({ Title = "Camera", Column = 1 })

cameraBox:Slider({
    Text = "Field of view",
    Flag = "dr_fov",
    Min = 40,
    Max = 120,
    Default = 70,
})
cameraBox:Toggle({ Text = "Third person", Flag = "dr_third_person", Default = false })
cameraBox:Slider({ Text = "Third person X", Flag = "dr_tp_x", Min = -10, Max = 10, Default = 2 })
cameraBox:Slider({ Text = "Third person Y", Flag = "dr_tp_y", Min = -10, Max = 10, Default = 1 })
cameraBox:Slider({ Text = "Third person Z", Flag = "dr_tp_z", Min = 0, Max = 30, Default = 8 })
cameraBox:Toggle({ Text = "Freecam", Info = "WASD plus Space and Ctrl", Flag = "dr_freecam", Default = false })
cameraBox:Slider({ Text = "Freecam speed", Flag = "dr_freecam_speed", Min = 10, Max = 250, Default = 60 })

local closetBox = renderTab:Section({ Title = "Closets", Column = 2 })

closetBox:Toggle({ Text = "See through closets", Flag = "dr_see_closets", Default = false })
closetBox:Slider({
    Text = "Closet transparency",
    Flag = "dr_closet_transparency",
    Min = 0,
    Max = 100,
    Default = 60,
    Suffix = "%",
})

local statusBox = renderTab:Section({ Title = "Status", Column = 2 })

local oxygenLabel = statusBox:Label("Oxygen: n/a")
local hasteLabel = statusBox:Label("Haste: none")

local alertBox = renderTab:Section({ Title = "Alerts", Column = 2 })

local alertLabel = alertBox:Label("No entity nearby")

alertBox:Toggle({ Text = "Entity alerts", Flag = "dr_entity_alerts", Default = true })
alertBox:Dropdown({
    Text = "Alert on these entities",
    Flag = "dr_alert_entities",
    Multi = true,
    Options = ENTITY_NAMES,
    Default = {},
    Placeholder = "Any entity",
})
alertBox:Toggle({ Text = "Item alerts", Flag = "dr_item_alerts", Default = false })
alertBox:Dropdown({
    Text = "Alert on these items",
    Flag = "dr_alert_items",
    Multi = true,
    Options = ITEM_NAMES,
    Default = {},
    Placeholder = "Any item",
})
alertBox:Toggle({
    Text = "Library code alert",
    Info = "Notifies when a padlock hint appears in the room",
    Flag = "dr_library_alert",
    Default = false,
})
alertBox:Toggle({ Text = "Persistent notifications", Flag = "dr_persistent_notifs", Default = false })
alertBox:Button({
    Text = "Test notification",
    ButtonText = "Test",
    Callback = function()
        notify("info", "Test", "Notifications are working.", 4)
    end,
})

local espTab = window:Tab({
    Name = "ESP",
    Icon = "binoculars",
    Description = "Doors, closets, entities, loot and players",
})

local targetBox = espTab:Section({ Title = "Targets", Column = 1 })

targetBox:Toggle({ Text = "Objective ESP", Flag = "dr_esp_objectives", Default = true })
targetBox:Toggle({ Text = "Door ESP", Flag = "dr_esp_doors", Default = true })
targetBox:Toggle({ Text = "Closet ESP", Flag = "dr_esp_closets", Default = true })
targetBox:Toggle({ Text = "Player ESP", Flag = "dr_esp_players", Default = false })
targetBox:Toggle({ Text = "Loot chest ESP", Flag = "dr_esp_chests", Default = true })
targetBox:Toggle({ Text = "Item ESP", Flag = "dr_esp_items", Default = true })
targetBox:Toggle({ Text = "Money ESP", Flag = "dr_esp_money", Default = true })
targetBox:Toggle({ Text = "Ladder ESP", Flag = "dr_esp_ladders", Default = false })
targetBox:Toggle({ Text = "Entity ESP", Flag = "dr_esp_entities", Default = true })
targetBox:Dropdown({
    Text = "Entity types",
    Flag = "dr_entity_filter",
    Multi = true,
    Options = ENTITY_NAMES,
    Default = {},
    Placeholder = "Every entity",
})

local colorBox = espTab:Section({ Title = "Colours", Column = 1 })

colorBox:Toggle({ Text = "Rainbow", Info = "Overrides every category colour", Flag = "dr_rainbow", Default = false })
colorBox:Dropdown({ Text = "Objectives", Flag = "dr_color_objective", Options = COLOR_NAMES, Default = "Orange" })
colorBox:Dropdown({ Text = "Doors", Flag = "dr_color_door", Options = COLOR_NAMES, Default = "Cyan" })
colorBox:Dropdown({ Text = "Closets", Flag = "dr_color_closet", Options = COLOR_NAMES, Default = "Green" })
colorBox:Dropdown({ Text = "Entities", Flag = "dr_color_entity", Options = COLOR_NAMES, Default = "Red" })
colorBox:Dropdown({ Text = "Items", Flag = "dr_color_item", Options = COLOR_NAMES, Default = "Yellow" })
colorBox:Dropdown({ Text = "Players", Flag = "dr_color_player", Options = COLOR_NAMES, Default = "White" })

local styleBox = espTab:Section({ Title = "Style", Column = 2 })

styleBox:Toggle({ Text = "Distance labels", Flag = "dr_esp_distance", Default = true })
styleBox:Slider({ Text = "Render distance", Flag = "dr_render_distance", Min = 50, Max = 2000, Default = 500, Suffix = " studs" })
styleBox:Slider({ Text = "Text size", Flag = "dr_text_size", Min = 8, Max = 28, Default = 13 })
styleBox:Slider({ Text = "Fill transparency", Flag = "dr_fill_transparency", Min = 0, Max = 100, Default = 60, Suffix = "%" })
styleBox:Slider({ Text = "Outline transparency", Flag = "dr_outline_transparency", Min = 0, Max = 100, Default = 0, Suffix = "%" })
styleBox:Slider({ Text = "Text transparency", Flag = "dr_text_transparency", Min = 0, Max = 100, Default = 0, Suffix = "%" })
styleBox:Slider({ Text = "Text outline transparency", Flag = "dr_text_outline_transparency", Min = 0, Max = 100, Default = 40, Suffix = "%" })
styleBox:Slider({ Text = "Refresh rate", Info = "Lower this if mobile feels heavy", Flag = "dr_esp_rate", Min = 5, Max = 60, Default = 20, Suffix = " hz" })

local tracerBox = espTab:Section({ Title = "Tracers and arrows", Column = 2 })

tracerBox:Toggle({ Text = "Tracers", Flag = "dr_tracers", Default = false })
tracerBox:Dropdown({ Text = "Tracer origin", Flag = "dr_tracer_origin", Options = { "Bottom", "Middle", "Top" }, Default = "Bottom" })
tracerBox:Slider({ Text = "Tracer thickness", Flag = "dr_tracer_thickness", Min = 1, Max = 8, Default = 2 })
tracerBox:Toggle({ Text = "Off-screen arrows", Flag = "dr_arrows", Default = false })
tracerBox:Slider({ Text = "Arrow radius", Flag = "dr_arrow_radius", Min = 60, Max = 400, Default = 180 })

local floorTab = window:Tab({
    Name = "Floors",
    Icon = "layout-grid",
    Description = "Room progression and floor specific helpers",
})

local roomsBox = floorTab:Section({ Title = "Rooms", Column = 1 })

local roomLabel = roomsBox:Label("Room 0")

roomsBox:Toggle({ Text = "Auto rooms", Info = "Walks to the next door and opens it", Flag = "dr_auto_rooms", Default = false })
roomsBox:Slider({
    Text = "Delay between doors",
    Flag = "dr_rooms_delay",
    Min = 0,
    Max = 10,
    Default = 1,
    Suffix = "s",
})
roomsBox:Button({
    Text = "Open next door",
    ButtonText = "Open",
    Callback = function()
        task.spawn(function()
            if not autoDoor() then
                notify("warning", "Doors", "No door found ahead of you.", 3)
            end
        end)
    end,
})
roomsBox:Toggle({ Text = "Spoof footsteps while auto rooms", Flag = "dr_spoof_steps", Default = false })

local farmBox = floorTab:Section({ Title = "Farming", Column = 1 })

farmBox:Toggle({ Text = "Knob farm", Info = "Keeps looting drawers for knobs", Flag = "dr_knob_farm", Default = false })
farmBox:Toggle({ Text = "Death farm", Info = "Resets on a loop", Flag = "dr_death_farm", Default = false })
farmBox:Slider({ Text = "Death farm delay", Flag = "dr_death_delay", Min = 3, Max = 60, Default = 10, Suffix = "s" })

local floorBox = floorTab:Section({ Title = "Floor helpers", Column = 2 })

floorBox:Toggle({
    Text = "Auto minecart",
    Info = "Fires CartControl (the jump/turn action) on a timer while you're riding one",
    Flag = "dr_auto_minecart",
    Default = false,
})
floorBox:Slider({
    Text = "Minecart turn distance",
    Info = "Larger values fire the turn less often — tune this to the track",
    Flag = "dr_minecart_turn_distance",
    Min = 5,
    Max = 60,
    Default = 15,
    Suffix = " studs",
})
floorBox:Slider({
    Text = "Minecart crouch distance",
    Info = "How far before a low section the fake crouch fires while auto minecart is on",
    Flag = "dr_minecart_crouch_distance",
    Min = 5,
    Max = 60,
    Default = 20,
    Suffix = " studs",
})
floorBox:Toggle({ Text = "Auto revive teammates", Flag = "dr_auto_revive", Default = false })
floorBox:Button({
    Text = "Skip Seek chase",
    ButtonText = "Skip",
    Callback = function()
        fireRemote("StopSeekMusic")
        fireRemote("SeekSlop")
        notify("info", "Seek", "Sent the seek stop remotes.", 3)
    end,
})
floorBox:Button({
    Text = "Delete Figure",
    ButtonText = "Delete",
    Callback = function()
        local removed = 0
        for _, entity in ipairs(liveEntities()) do
            if entity.Name:lower():find("figure", 1, true) then
                pcall(function()
                    entity:Destroy()
                end)
                removed += 1
            end
        end
        notify(removed > 0 and "success" or "info", "Figure",
            removed > 0 and ("Removed " .. removed .. " locally.") or "Figure is not in the map.", 3)
    end,
})

local skipBox = floorTab:Section({ Title = "Room skip", Column = 2 })

skipBox:Slider({ Text = "Room number", Flag = "dr_skip_room", Min = 0, Max = 200, Default = 50 })
skipBox:Button({
    Text = "Skip to room",
    ButtonText = "Skip",
    Callback = function()
        local number = math.floor(tonumber(flag("dr_skip_room", 50)) or 50)
        skipToRoom(number)
        notify("info", "Skip", "Requested room " .. number .. ".", 3)
    end,
})
skipBox:Button({
    Text = "Teleport to next door",
    ButtonText = "Go",
    Callback = function()
        local door = nextDoor()
        local position = door and pivotOf(door)
        local root = rootPart()
        if position and root then
            root.CFrame = CFrame.new(position + Vector3.new(0, 3, -4))
        else
            notify("warning", "Teleport", "No door ahead.", 3)
        end
    end,
})

local visionClock = 0

RunService.RenderStepped:Connect(function(delta)
    pcall(updateFlight, delta)
    pcall(updateFreecam, delta)
    pcall(applyMovement)
    pcall(applyThirdPerson)

    visionClock += delta
    local rate = math.clamp(tonumber(flag("dr_esp_rate", 20)) or 20, 5, 60)
    if visionClock < (1 / rate) then
        return
    end
    visionClock = 0
    if not pcall(refreshVision) then
        clearVision()
    end
    pcall(applyRender)
end)

RunService.Stepped:Connect(function()
    if isOn("dr_noclip") then
        pcall(applyNoClip)
    end
end)

UserInputService.JumpRequest:Connect(function()
    if isOn("dr_inf_jump") then
        local hum = humanoid()
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.5)
        pcall(applyPrompts)
    end
end)

task.spawn(function()
    while true do
        task.wait(1)
        local wanted = flag("dr_blocked_events", {})
        local want = {}
        if typeof(wanted) == "table" then
            for _, entry in ipairs(wanted) do
                local remoteName = BLOCKABLE[entry]
                if remoteName then
                    want[remoteName] = true
                end
            end
        end
        for _, remoteName in pairs(BLOCKABLE) do
            local shouldBlock = want[remoteName] == true
            if state.blocked[remoteName] ~= shouldBlock then
                setRemoteBlocked(remoteName, shouldBlock)
            elseif shouldBlock then
                setRemoteBlocked(remoteName, true)
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.4)
        if isOn("dr_auto_grab") then
            pcall(autoGrab)
        end
        if isOn("dr_knob_farm") then
            for _, prompt in ipairs(allPrompts()) do
                if prompt.Enabled and promptCategory(prompt) == "Chest" then
                    local holder = prompt.Parent
                    local position = holder and pivotOf(holder)
                    if position and distanceTo(position) <= 60 then
                        firePrompt(prompt)
                        task.wait(0.2)
                    end
                end
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.6)
        if isOn("dr_auto_hide") then
            pcall(autoHide)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.35)
        if isOn("dr_auto_heartbeat") then
            pcall(heartbeatMinigame)
        end
        if isOn("dr_auto_minecart") then
            pcall(autoMinecartTick)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.5)
        if isOn("dr_fake_crouch") then
            pcall(applyFakeCrouch)
        elseif fakeCrouchOn then
            fakeCrouchOn = false
            fireRemote("Crouch", false)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(tonumber(flag("dr_rooms_delay", 1)) or 1)
        if isOn("dr_auto_rooms") then
            pcall(autoRoomsStep)
            if isOn("dr_spoof_steps") then
                fireRemote("Footstep")
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(math.max(3, tonumber(flag("dr_death_delay", 10)) or 10))
        if isOn("dr_death_farm") then
            local hum = humanoid()
            if hum and hum.Health > 0 then
                hum.Health = 0
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(1)
        if isOn("dr_auto_revive") then
            for _, other in ipairs(Players:GetPlayers()) do
                if other ~= LocalPlayer and other.Character then
                    for _, prompt in ipairs(other.Character:GetDescendants()) do
                        if prompt:IsA("ProximityPrompt") and prompt.Enabled then
                            local text = (tostring(prompt.ActionText) .. tostring(prompt.ObjectText)):lower()
                            if text:find("reviv", 1, true) then
                                firePrompt(prompt)
                                task.wait(1)
                            end
                        end
                    end
                end
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(2)
        pcall(applySeeThroughClosets)
        if isOn("dr_mute_steps") then
            muteGroup({ "footstep", "step" }, true)
        end
        if isOn("dr_mute_music") then
            muteGroup({ "music", "ambience", "jam" }, true)
        end
        if isOn("dr_mute_interact") then
            muteGroup({ "interact", "drawer", "click", "open" }, true)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(1)
        if isOn("dr_no_stun") then
            local char = character()
            local stun = char and char:FindFirstChild("StunEvent")
            if stun and typeof(getconnections) == "function" then
                pcall(function()
                    for _, connection in ipairs(getconnections(stun.Event)) do
                        connection:Disable()
                    end
                end)
            end
            local hum = humanoid()
            if hum and hum.PlatformStand and not state.flying then
                hum.PlatformStand = false
            end
        end
    end
end)

local lastAlert = {}
local lastItemAlert = {}

task.spawn(function()
    while true do
        task.wait(0.5)
        setLabel(autoLabel, string.format("Grabbed %d  ·  hides %d", state.grabbed, state.hides))
        local _, roomNumber = latestRoom()
        setLabel(roomLabel, string.format("Room %d  ·  latest generated %d",
            currentRoomNumber(), roomNumber or 0))

        local oxygen = oxygenValue()
        setLabel(oxygenLabel, oxygen and ("Oxygen: " .. math.floor(oxygen) .. "%") or "Oxygen: n/a")
        local haste = hasteValue()
        setLabel(hasteLabel, haste > 0 and ("Haste: +" .. math.floor(haste * 100) .. "% speed")
            or "Haste: none")

        local entities = liveEntities()
        if #entities == 0 then
            setLabel(alertLabel, "No entity nearby")
        else
            local names = {}
            for _, entity in ipairs(entities) do
                local position = pivotOf(entity)
                names[#names + 1] = string.format("%s %d", entity.Name,
                    position and math.floor(distanceTo(position)) or 0)
            end
            setLabel(alertLabel, table.concat(names, ", "))
        end

        if isOn("dr_entity_alerts") then
            local wanted = flag("dr_alert_entities", {})
            local filterOn = typeof(wanted) == "table" and #wanted > 0
            local allow = {}
            if filterOn then
                for _, name in ipairs(wanted) do
                    allow[name] = true
                end
            end
            for _, entity in ipairs(entities) do
                local name = entity.Name
                if (not filterOn or allow[name]) and (os.clock() - (lastAlert[name] or 0)) > 8 then
                    lastAlert[name] = os.clock()
                    local position = pivotOf(entity)
                    notify("warning", name .. " is here",
                        position and (math.floor(distanceTo(position)) .. " studs away") or "Somewhere on this floor.", 5)
                end
            end
        end

        if isOn("dr_item_alerts") then
            local wanted = flag("dr_alert_items", {})
            local filterOn = typeof(wanted) == "table" and #wanted > 0
            local allow = {}
            if filterOn then
                for _, name in ipairs(wanted) do
                    allow[name] = true
                end
            end
            for _, drop in ipairs(itemDrops()) do
                local name = drop.Name
                if not filterOn or allow[name] then
                    local key = drop
                    if (os.clock() - (lastItemAlert[key] or 0)) > 10 then
                        lastItemAlert[key] = os.clock()
                        local position = pivotOf(drop)
                        notify("info", name .. " dropped",
                            position and (math.floor(distanceTo(position)) .. " studs away") or "Somewhere nearby.", 4)
                    end
                end
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(2)
        if isOn("dr_inf_items") then
            local wanted = flag("dr_infinite_items", {})
            if typeof(wanted) == "table" and #wanted > 0 then
                local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
                local char = character()
                for _, name in ipairs(wanted) do
                    local held = (backpack and backpack:FindFirstChild(name))
                        or (char and char:FindFirstChild(name))
                    if held then
                        fireRemote("Equip", held)
                    end
                end
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(60)
        if isOn("dr_anti_afk") then
            pcall(function()
                VirtualUser:Button2Down(Vector2.new(0, 0), Camera.CFrame)
                task.wait(0.1)
                VirtualUser:Button2Up(Vector2.new(0, 0), Camera.CFrame)
            end)
        end
    end
end)

pcall(function()
    for _, connection in ipairs(getconnections(LocalPlayer.Idled)) do
        connection:Disable()
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    stopFlight()
    clearVision()
end)

notify("success", "DOORS", "Loaded. Press RightShift to toggle the menu.", 5)

return window
