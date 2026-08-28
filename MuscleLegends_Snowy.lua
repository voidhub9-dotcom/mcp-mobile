local SNOWY_URL = ""
local SNOWY_FILE = "SnowyStudios.luau"

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local function loadSnowy()
    if getgenv and typeof(getgenv().SnowyStudiosLibrary) == "table" then
        return getgenv().SnowyStudiosLibrary
    end
    local source
    if isfile and readfile and isfile(SNOWY_FILE) then
        source = readfile(SNOWY_FILE)
    elseif SNOWY_URL ~= "" then
        local ok, body = pcall(function()
            return game:HttpGet(SNOWY_URL)
        end)
        source = ok and body or nil
    end
    if not source then
        error("SnowyStudios.luau not found: put it in your executor folder or set SNOWY_URL", 0)
    end
    local chunk = loadstring(source)
    local lib = chunk()
    if getgenv then
        getgenv().SnowyStudiosLibrary = lib
    end
    return lib
end

local Snowy = loadSnowy()

local rEvents = ReplicatedStorage:WaitForChild("rEvents", 10)
if not rEvents then
    error("This script only runs in Muscle Legends", 0)
end

local NET = {
    machineInteract = rEvents:WaitForChild("machineInteractRemote"),
    areaTravel = rEvents:WaitForChild("areaTravelRemote"),
    rebirth = rEvents:WaitForChild("rebirthRemote"),
    openCrystal = rEvents:WaitForChild("openCrystalRemote"),
    checkChest = rEvents:WaitForChild("checkChestRemote"),
    group = rEvents:WaitForChild("groupRemote"),
    freeGift = rEvents:WaitForChild("freeGiftClaimRemote"),
    fortuneWheel = rEvents:WaitForChild("openFortuneWheelRemote"),
    ultimates = rEvents:WaitForChild("ultimatesRemote"),
    petShop = rEvents:WaitForChild("cPetShopRemote"),
    quests = rEvents:WaitForChild("questsEvent"),
    equipPet = rEvents:WaitForChild("equipPetEvent"),
    sellPet = rEvents:WaitForChild("sellPetEvent"),
    evolvePet = rEvents:WaitForChild("petEvolveEvent"),
    countdown = rEvents:WaitForChild("giveCountdownRewardEvent"),
    consumeBoost = rEvents:FindFirstChild("consumeBoostEvent"),
    rejoin = rEvents:FindFirstChild("rejoinServerEvent"),
}

local muscleEvent = LocalPlayer:WaitForChild("muscleEvent")
local shared_ = ReplicatedStorage:WaitForChild("shared")
local catalogs = shared_:WaitForChild("catalogs")
local GlobalFunctions = require(shared_.modules.GlobalFunctions)

local machinesFolder = Workspace:WaitForChild("machinesFolder")
local treadmillsFolder = Workspace:WaitForChild("Treadmills")
local areaCircles = Workspace:WaitForChild("areaCircles")

local leaderstats = LocalPlayer:WaitForChild("leaderstats")
local StrengthValue = leaderstats:WaitForChild("Strength")
local RebirthsValue = leaderstats:WaitForChild("Rebirths")
local AgilityValue = LocalPlayer:WaitForChild("Agility")
local DurabilityValue = LocalPlayer:WaitForChild("Durability")
local GemsValue = LocalPlayer:WaitForChild("Gems")
local TokensValue = LocalPlayer:WaitForChild("Tokens")
local petsFolder = LocalPlayer:WaitForChild("petsFolder")
local equippedPets = LocalPlayer:WaitForChild("equippedPets")
local powerUpsFolder = LocalPlayer:WaitForChild("powerUpsFolder")
local consumablesFolder = LocalPlayer:WaitForChild("consumablesFolder")
local questsFolder = LocalPlayer:WaitForChild("Quests")
local machineInUse = LocalPlayer:WaitForChild("machineInUse")
local treadmillInUse = LocalPlayer:WaitForChild("treadmillInUse")
local maxPetCapacity = LocalPlayer:WaitForChild("maxPetCapacity")

local CHEST_NAMES = {
    "Golden Chest",
    "Enchanted Chest",
    "Magma Chest",
    "Mythical Chest",
    "Legends Chest",
    "Jungle Chest",
    "Industrial Chest",
}

local RARITY_RANK = {
    Basic = 1,
    Advanced = 2,
    Rare = 3,
    Epic = 4,
    Unique = 5,
}

local Flags = Snowy.Flags
local window

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

local function notify(kind, title, text, duration)
    if not window then
        return
    end
    window:Notify({ Type = kind, Title = title, Text = text, Duration = duration or 4 })
end

local function character()
    local char = LocalPlayer.Character
    if char and char.Parent then
        return char
    end
    return nil
end

local function humanoid()
    local char = character()
    return char and char:FindFirstChildOfClass("Humanoid") or nil
end

local function rootPart()
    local char = character()
    return char and char:FindFirstChild("HumanoidRootPart") or nil
end

local function alive()
    local hum = humanoid()
    return hum ~= nil and hum.Health > 0
end

local function teleportTo(cframe)
    local root = rootPart()
    if not root or typeof(cframe) ~= "CFrame" then
        return false
    end
    root.CFrame = cframe
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    return true
end

local function invoke(remote, ...)
    if typeof(remote) ~= "Instance" then
        return false
    end
    local packed = table.pack(pcall(function(...)
        return remote:InvokeServer(...)
    end, ...))
    if packed[1] ~= true then
        return false
    end
    return true, table.unpack(packed, 2, packed.n)
end

local function fire(remote, ...)
    if typeof(remote) ~= "Instance" then
        return false
    end
    return (pcall(function(...)
        remote:FireServer(...)
    end, ...))
end

local function shortNumber(value)
    local number = tonumber(value) or 0
    local suffixes = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx" }
    local index = 1
    while number >= 1000 and index < #suffixes do
        number /= 1000
        index += 1
    end
    if index == 1 then
        return string.format("%d", number)
    end
    return string.format("%.2f%s", number, suffixes[index])
end

local function statValue(name)
    if name == "Strength" then
        return StrengthValue.Value
    elseif name == "Agility" then
        return AgilityValue.Value
    elseif name == "Durability" then
        return DurabilityValue.Value
    end
    return 0
end

local function weakestStat()
    local best, bestValue = "Strength", math.huge
    for _, name in ipairs({ "Strength", "Durability", "Agility" }) do
        local value = statValue(name)
        if value < bestValue then
            best, bestValue = name, value
        end
    end
    return best
end

local paceFactors = {
    ["Game cooldown"] = 1,
    ["Relaxed"] = 1.6,
    ["Faster"] = 0.6,
}

local function pacedWait(base)
    local factor = paceFactors[flag("ml_pace", "Game cooldown")] or 1
    local delay = math.max(0.15, (tonumber(base) or 1) * factor)
    if isOn("ml_natural") then
        delay += delay * (math.random() * 0.36 - 0.18)
    end
    task.wait(delay)
end

local busy = false

local function withMovement(fn)
    if busy then
        return false
    end
    busy = true
    local ok, err = pcall(fn)
    busy = false
    if not ok then
        warn("[Muscle Legends] " .. tostring(err))
    end
    return ok
end

local function isMuscleKingMachine(machine)
    return machine.Name:lower():find("muscle king", 1, true) ~= nil
        or machine.Name:lower():find("king ", 1, true) ~= nil
end

local function machineGain(machine, stat)
    local key = stat == "Agility" and "agilityGain" or (stat == "Durability" and "durabilityGain" or "strengthGain")
    local value = machine:FindFirstChild(key)
    return value and value.Value or 0
end

local function machineTier(machine)
    local requirements = machine:FindFirstChild("requirements")
    local tier = 0
    if requirements then
        for _, requirement in ipairs(requirements:GetChildren()) do
            if requirement:IsA("ValueBase") and typeof(requirement.Value) == "number" then
                tier = math.max(tier, requirement.Value)
            end
        end
    end
    return tier
end

local function usableMachines(stat)
    local root = rootPart()
    local list = {}
    for _, machine in ipairs(machinesFolder:GetChildren()) do
        local seat = machine:FindFirstChild("interactSeat")
        local requirements = machine:FindFirstChild("requirements")
        if seat and requirements and seat.Occupant == nil then
            local allowed = GlobalFunctions.checkIfPlayerCanUseMachine(LocalPlayer, requirements)
            if allowed and (isOn("ml_muscle_king") or not isMuscleKingMachine(machine)) then
                local gain = machineGain(machine, stat)
                if gain > 0 then
                    table.insert(list, {
                        machine = machine,
                        seat = seat,
                        gain = gain,
                        tier = machineTier(machine),
                        repTime = machine:FindFirstChild("repTime") and machine.repTime.Value or 1,
                        distance = root and (root.Position - seat.Position).Magnitude or math.huge,
                    })
                end
            end
        end
    end
    return list
end

local function pickMachine(stat)
    local list = usableMachines(stat)
    if #list == 0 then
        return nil
    end
    local strategy = flag("ml_machine_strategy", "Best stat gain")
    if strategy == "Closest" then
        table.sort(list, function(a, b)
            return a.distance < b.distance
        end)
    elseif strategy == "Highest tier" then
        table.sort(list, function(a, b)
            return a.tier > b.tier
        end)
    elseif strategy == "Random" then
        return list[math.random(1, #list)]
    else
        table.sort(list, function(a, b)
            return (a.gain / math.max(a.repTime, 0.1)) > (b.gain / math.max(b.repTime, 0.1))
        end)
    end
    return list[1]
end

local currentSeat = nil

local function dismount()
    if currentSeat ~= nil or machineInUse.Value ~= nil then
        currentSeat = nil
        invoke(NET.machineInteract, "leaveMachine")
    end
    local hum = humanoid()
    if hum then
        if hum.Sit or hum.SeatPart then
            hum.Sit = false
            pcall(function()
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end)
            task.wait(0.35)
        end
    end
end

local function leaveMachine()
    dismount()
end

local function mountedOnMachine()
    local char = character()
    if not char then
        return false
    end
    local hum = humanoid()
    return (hum and hum.SeatPart ~= nil)
        or char:GetAttribute("MachineStandingMount") == true
        or char:GetAttribute("MachineScaleFrozen") == true
end

local function trainOnMachine(stat)
    local entry = pickMachine(stat)
    if not entry then
        return false
    end
    dismount()
    if not teleportTo(entry.seat.CFrame + Vector3.new(0, 3, 0)) then
        return false
    end
    task.wait(0.35)
    local ok, mounted = invoke(NET.machineInteract, "useMachine", entry.seat)
    if not ok or mounted ~= true then
        return false
    end
    currentSeat = entry.seat
    task.wait(0.25)

    local deadline = os.clock() + 12
    while os.clock() < deadline and isOn("ml_autofarm") and alive() do
        if not mountedOnMachine() then
            break
        end
        if entry.seat.Parent == nil then
            break
        end
        fire(muscleEvent, "rep", entry.seat)
        pacedWait(entry.repTime)
    end
    leaveMachine()
    return true
end

local function toolCadence(tool)
    local repTime = tool:FindFirstChild("repTime")
    if repTime then
        return repTime.Value
    end
    local attackTime = tool:FindFirstChild("attackTime")
    if attackTime then
        return attackTime.Value
    end
    return 1
end

local function collectTools()
    local list = {}
    local containers = { LocalPlayer:FindFirstChildOfClass("Backpack"), character() }
    for _, container in ipairs(containers) do
        if container then
            for _, tool in ipairs(container:GetChildren()) do
                if tool:IsA("Tool") then
                    local gain = tool:FindFirstChild("strengthGain")
                    local punch = tool:FindFirstChild("attackTime")
                    if gain or punch then
                        table.insert(list, {
                            tool = tool,
                            punch = punch ~= nil,
                            gain = gain and gain.Value or 0,
                            cadence = toolCadence(tool),
                        })
                    end
                end
            end
        end
    end
    return list
end

local function pickTool(mode)
    local list = collectTools()
    if #list == 0 then
        return nil
    end
    if mode == "Punch training" then
        for _, entry in ipairs(list) do
            if entry.punch then
                return entry
            end
        end
        return nil
    end
    if mode == "Weight training" then
        local best
        for _, entry in ipairs(list) do
            if not entry.punch and (not best or entry.gain > best.gain) then
                best = entry
            end
        end
        return best
    end
    local best
    for _, entry in ipairs(list) do
        local rate = entry.gain / math.max(entry.cadence, 0.1)
        if entry.punch and entry.gain == 0 then
            rate = 1 / math.max(entry.cadence, 0.1)
        end
        if not best or rate > (best.gain / math.max(best.cadence, 0.1)) then
            best = entry
        end
    end
    return best
end

local function kingsGymAnchor()
    for _, circle in ipairs(areaCircles:GetChildren()) do
        local areaName = circle:FindFirstChild("areaName")
        if areaName and areaName.Value == "Muscle King" then
            return circle:IsA("BasePart") and circle.CFrame or circle:GetPivot()
        end
    end
    return nil
end

local function trainWithTool(mode)
    local entry = pickTool(mode)
    if not entry then
        return false
    end
    local hum = humanoid()
    if not hum then
        return false
    end
    dismount()
    if entry.tool.Parent ~= character() then
        pcall(function()
            hum:EquipTool(entry.tool)
        end)
        task.wait(0.3)
    end
    if entry.tool.Parent ~= character() then
        return false
    end

    local anchor = isOn("ml_lock_kings_gym") and kingsGymAnchor() or nil
    if anchor then
        teleportTo(anchor + Vector3.new(0, 5, 0))
        task.wait(0.2)
    end

    local deadline = os.clock() + 10
    while os.clock() < deadline and isOn("ml_autofarm") and alive() do
        if entry.tool.Parent ~= character() then
            break
        end
        pcall(function()
            entry.tool:Activate()
        end)
        if anchor then
            local root = rootPart()
            if root and (root.Position - anchor.Position).Magnitude > 60 then
                teleportTo(anchor + Vector3.new(0, 5, 0))
            end
        end
        pacedWait(entry.cadence)
    end
    return true
end

local function pickTreadmill()
    local root = rootPart()
    local best
    for _, treadmill in ipairs(treadmillsFolder:GetChildren()) do
        local part = treadmill:FindFirstChild("treadmillPart")
        local requirements = treadmill:FindFirstChild("requirements")
        local amount = treadmill:FindFirstChild("agilityAmount")
        if part and amount then
            local allowed = requirements == nil
                or GlobalFunctions.checkIfPlayerCanUseMachine(LocalPlayer, requirements)
            if allowed then
                local entry = {
                    part = part,
                    gain = amount.Value,
                    distance = root and (root.Position - part.Position).Magnitude or math.huge,
                }
                if not best or entry.gain > best.gain then
                    best = entry
                end
            end
        end
    end
    return best
end

local function runTreadmill()
    local entry = pickTreadmill()
    if not entry then
        return false
    end
    dismount()
    local top = entry.part.Position + Vector3.new(0, entry.part.Size.Y / 2 + 3, 0)
    if not teleportTo(CFrame.new(top)) then
        return false
    end
    task.wait(1)
    if treadmillInUse.Value == nil then
        teleportTo(CFrame.new(top + Vector3.new(1, 0, 1)))
        task.wait(1)
    end
    local deadline = os.clock() + 15
    while os.clock() < deadline and isOn("ml_treadmill") and alive() do
        local root = rootPart()
        if not root then
            break
        end
        if (root.Position - top).Magnitude > 8 then
            teleportTo(CFrame.new(top))
        end
        task.wait(0.5)
    end
    return treadmillInUse.Value ~= nil
end

local rebirthLabel

local function requiredRebirthStrength()
    local ok, value = pcall(function()
        return GlobalFunctions.calculateRequiredRebirthStrength(RebirthsValue.Value, LocalPlayer)
    end)
    if ok and tonumber(value) then
        return tonumber(value)
    end
    return nil
end

local function rebirthMultiplierTarget()
    local timing = flag("ml_rebirth_timing", "Immediately")
    if timing == "Save 25% extra" then
        return 1.25
    elseif timing == "Wait for double" then
        return 2
    end
    return 1
end

local function petLooksLikeRebirthPet(pet)
    local name = pet.Name:lower()
    if name:find("rebirth") then
        return true
    end
    for _, child in ipairs(pet:GetDescendants()) do
        if child:IsA("ValueBase") and tostring(child.Name):lower():find("rebirth") then
            return true
        end
    end
    return false
end

local function inventoryPets()
    local list = {}
    for _, folder in ipairs(petsFolder:GetChildren()) do
        if folder:IsA("Folder") then
            for _, pet in ipairs(folder:GetChildren()) do
                if pet:IsA("StringValue") then
                    table.insert(list, { pet = pet, rarity = folder.Name })
                end
            end
        end
    end
    return list
end

local function hasDoubleRebirthPet()
    for _, entry in ipairs(inventoryPets()) do
        if entry.pet.Name:lower():find("x2 rebirth") or entry.pet.Name:lower():find("double rebirth") then
            return true
        end
    end
    return false
end

local function unequipAllPets()
    for _, slot in ipairs(equippedPets:GetChildren()) do
        local reference = slot:FindFirstChild("petReference")
        if slot:IsA("ObjectValue") and reference and reference.Value then
            fire(NET.equipPet, "unequipPet", reference.Value)
            task.wait(0.12)
        end
    end
end

local function petScore(entry, priority)
    local pet, rarity = entry.pet, entry.rarity
    local score = (RARITY_RANK[rarity] or 0) * 1000
    local level = pet:FindFirstChild("level")
    if level then
        score += level.Value * 10
    end
    for _, child in ipairs(pet:GetDescendants()) do
        if child:IsA("ValueBase") and typeof(child.Value) == "number" then
            local name = tostring(child.Name):lower()
            if priority == "Strength" and name:find("strength") then
                score += child.Value * 100
            elseif priority == "Agility" and name:find("agility") then
                score += child.Value * 100
            elseif priority == "Durability" and name:find("durability") then
                score += child.Value * 100
            elseif priority == "Rebirth bonus" and name:find("rebirth") then
                score += child.Value * 100
            elseif priority == "Total bonuses" then
                score += child.Value
            end
        end
    end
    if priority == "Rarity" then
        score = (RARITY_RANK[rarity] or 0) * 10000 + score
    end
    return score
end

local function equipBestPets(priority)
    local list = inventoryPets()
    if #list == 0 then
        return 0
    end
    priority = priority or flag("ml_pet_priority", "Total bonuses")
    table.sort(list, function(a, b)
        return petScore(a, priority) > petScore(b, priority)
    end)
    local slots = #equippedPets:GetChildren()
    unequipAllPets()
    task.wait(0.2)
    local equipped = 0
    for _, entry in ipairs(list) do
        if equipped >= slots then
            break
        end
        fire(NET.equipPet, "equipPet", entry.pet)
        equipped += 1
        task.wait(0.15)
    end
    return equipped
end

local function equipRebirthPets()
    local list = {}
    for _, entry in ipairs(inventoryPets()) do
        if petLooksLikeRebirthPet(entry.pet) then
            table.insert(list, entry)
        end
    end
    if #list == 0 then
        return false
    end
    unequipAllPets()
    task.wait(0.2)
    local slots = #equippedPets:GetChildren()
    for index, entry in ipairs(list) do
        if index > slots then
            break
        end
        fire(NET.equipPet, "equipPet", entry.pet)
        task.wait(0.15)
    end
    return true
end

local function doRebirth(manual)
    local required = requiredRebirthStrength()
    if required and StrengthValue.Value < required and not manual then
        return false
    end
    return withMovement(function()
        local restore = false
        if isOn("ml_rebirth_pets") then
            restore = equipRebirthPets()
            task.wait(0.4)
        end
        local ok, result = invoke(NET.rebirth, "rebirthRequest")
        task.wait(0.6)
        if restore then
            equipBestPets("Strength")
        end
        if ok and result ~= false then
            notify("success", "Rebirth", "Rebirthed at " .. shortNumber(StrengthValue.Value) .. " strength.", 4)
        elseif manual then
            notify("warning", "Rebirth", "The server refused the rebirth request.", 4)
        end
    end)
end

local function updateRebirthLabel()
    if not rebirthLabel then
        return
    end
    local required = requiredRebirthStrength()
    local text
    if required then
        local target = math.floor(required * rebirthMultiplierTarget())
        text = string.format(
            "Next rebirth at: %s  ·  you have %s  ·  rebirths: %d",
            shortNumber(target),
            shortNumber(StrengthValue.Value),
            RebirthsValue.Value
        )
    else
        text = "Next rebirth at: ?"
    end
    pcall(function()
        rebirthLabel:Set(text)
    end)
end

local function chestModels()
    local list = {}
    for _, model in ipairs(Workspace:GetChildren()) do
        if model:IsA("Model") and model.Name:lower():find("chest") then
            table.insert(list, model)
        end
    end
    return list
end

local function chestModelFor(chestName)
    local key = chestName:gsub("%s", ""):lower()
    for _, model in ipairs(chestModels()) do
        if model.Name:lower() == key then
            return model
        end
    end
    return nil
end

local function claimChest(chestName, travel)
    if travel then
        local model = chestModelFor(chestName)
        if model then
            local pivot = model:GetPivot()
            teleportTo(pivot + Vector3.new(0, 6, 0))
            task.wait(0.45)
        end
    end
    local ok, claimed, reward, amount = invoke(NET.checkChest, chestName)
    if ok and claimed == true then
        notify("success", "Chest claimed", string.format(
            "%s gave %s %s",
            chestName,
            shortNumber(amount or 0),
            tostring(reward or "reward")
        ), 4)
        return true
    end
    return false
end

local function chestRoute()
    local mode = flag("ml_chest_route", "All ready chests")
    if mode == "Selected chest" then
        return { flag("ml_chest_pick", CHEST_NAMES[1]) }
    end
    if mode == "Nearest ready chest" then
        local root = rootPart()
        local ordered = {}
        for _, name in ipairs(CHEST_NAMES) do
            local model = chestModelFor(name)
            local distance = math.huge
            if model and root then
                distance = (root.Position - model:GetPivot().Position).Magnitude
            end
            table.insert(ordered, { name = name, distance = distance })
        end
        table.sort(ordered, function(a, b)
            return a.distance < b.distance
        end)
        return { ordered[1] and ordered[1].name or CHEST_NAMES[1] }
    end
    return CHEST_NAMES
end

local function claimAllChests(travel)
    local claimed = 0
    for _, name in ipairs(chestRoute()) do
        if claimChest(name, travel) then
            claimed += 1
        end
        task.wait(0.3)
    end
    return claimed
end

local function claimQuests()
    local collected = 0
    for _, category in ipairs(questsFolder:GetChildren()) do
        if category:IsA("Folder") and category.Name ~= "completedQuests" then
            for _, quest in ipairs(category:GetChildren()) do
                local ok, complete = pcall(GlobalFunctions.checkForCompleteQuest, quest)
                if ok and complete == true then
                    fire(NET.quests, "collectQuest", quest)
                    collected += 1
                    task.wait(0.25)
                end
            end
        end
    end
    return collected
end

local function claimFreeGifts()
    local claimed = 0
    for giftNumber = 1, 10 do
        local ok, success = invoke(NET.freeGift, "claimGift", giftNumber)
        if ok and success == true then
            claimed += 1
        end
        task.wait(0.2)
    end
    return claimed
end

local function spinFortuneWheel()
    local chances = catalogs:FindFirstChild("fortuneWheelChances")
    local config = chances and chances:FindFirstChild("Fortune Wheel")
    if not config then
        return false
    end
    local ok, result = invoke(NET.fortuneWheel, "openFortuneWheel", config)
    return ok and typeof(result) == "table"
end

local BIG_BOOSTS = {
    ["TOUGH Bar"] = true,
    ["ULTRA Shake"] = true,
    ["Protein Egg"] = true,
    ["Tropical Shake"] = true,
}

local function boostList()
    local list = {}
    for _, item in ipairs(consumablesFolder:GetChildren()) do
        table.insert(list, item)
    end
    return list
end

local function consumeBoost(item, amount)
    if not NET.consumeBoost then
        return false
    end
    return fire(NET.consumeBoost, item, amount or 1)
end

local function useBoosts(includeBig)
    local used = 0
    for _, item in ipairs(boostList()) do
        local big = BIG_BOOSTS[item.Name] == true
        if includeBig or not big then
            if consumeBoost(item, 1) then
                used += 1
                task.wait(0.35)
            end
        end
    end
    return used
end

local function ultimateNames()
    local folder = catalogs:FindFirstChild("gameUltimatesFolder")
    local list = {}
    if folder then
        for _, item in ipairs(folder:GetChildren()) do
            table.insert(list, item.Name)
        end
    end
    table.sort(list)
    return list
end

local function upgradeUltimates()
    local plan = flag("ml_ultimate_plan", {})
    if typeof(plan) ~= "table" then
        return 0
    end
    local upgraded = 0
    for _, name in ipairs(plan) do
        local ok, result = invoke(NET.ultimates, "upgradeUltimate", name)
        if ok and result == true then
            upgraded += 1
            notify("success", "Ultimate upgraded", name, 3)
            task.wait(0.4)
        end
    end
    return upgraded
end

local function crystalNames()
    local folder = catalogs:FindFirstChild("crystalPrices")
    local list = {}
    if folder then
        for _, item in ipairs(folder:GetChildren()) do
            table.insert(list, item.Name)
        end
    end
    return list
end

local function crystalPrice(name)
    local folder = catalogs:FindFirstChild("crystalPrices")
    local entry = folder and folder:FindFirstChild(name)
    if not entry then
        return nil
    end
    local price = entry:FindFirstChild("price")
    local priceType = entry:FindFirstChild("priceType")
    return price and price.Value or nil, priceType and priceType.Value or "Gems"
end

local function currencyValue(priceType)
    if priceType == "Tokens" then
        return TokensValue.Value
    elseif priceType == "Gems" then
        return GemsValue.Value
    elseif priceType == "Strength" then
        return StrengthValue.Value
    elseif priceType == "Agility" then
        return AgilityValue.Value
    elseif priceType == "Durability" then
        return DurabilityValue.Value
    end
    return 0
end

local function petStorageFull()
    local pets = GlobalFunctions.calculatePetCapacity(petsFolder) or 0
    local powerUps = GlobalFunctions.calculatePowerUpCapacity(powerUpsFolder) or 0
    local cap = maxPetCapacity.Value
    if cap <= 0 then
        return false
    end
    return pets >= cap or powerUps >= cap
end

local function pickCrystal()
    local strategy = flag("ml_crystal_strategy", "Selected crystal")
    local reserve = tonumber(flag("ml_crystal_reserve", 0)) or 0
    if strategy == "Selected crystal" then
        local name = flag("ml_crystal_pick", crystalNames()[1])
        local price, priceType = crystalPrice(name)
        if price and currencyValue(priceType) - reserve >= price then
            return name
        end
        return nil
    end
    local candidates = {}
    for _, name in ipairs(crystalNames()) do
        local price, priceType = crystalPrice(name)
        if price and currencyValue(priceType) - reserve >= price then
            table.insert(candidates, { name = name, price = price })
        end
    end
    if #candidates == 0 then
        return nil
    end
    table.sort(candidates, function(a, b)
        if strategy == "Cheapest affordable" then
            return a.price < b.price
        end
        return a.price > b.price
    end)
    return candidates[1].name
end

local function openCrystal(name, amount)
    if not name then
        return false
    end
    if isOn("ml_crystal_protect") and petStorageFull() then
        return false
    end
    amount = math.max(1, math.floor(tonumber(amount) or 1))
    if amount > 1 then
        local ok, result = invoke(NET.openCrystal, "openCrystalBulk", name, amount)
        return ok and result ~= false
    end
    local ok, result = invoke(NET.openCrystal, "openCrystal", name)
    return ok and result ~= false
end

local function evolveReadyPets()
    local counts = {}
    for _, entry in ipairs(inventoryPets()) do
        if not entry.pet:FindFirstChild("evolved") then
            counts[entry.pet.Name] = (counts[entry.pet.Name] or 0) + 1
        end
    end
    local evolved = 0
    for name, count in pairs(counts) do
        if count >= 5 then
            fire(NET.evolvePet, "evolvePet", name)
            evolved += 1
            task.wait(0.4)
        end
    end
    return evolved
end

local function duplicateReport()
    local counts = {}
    for _, entry in ipairs(inventoryPets()) do
        if not entry.pet:FindFirstChild("evolved") then
            counts[entry.pet.Name] = (counts[entry.pet.Name] or 0) + 1
        end
    end
    local ready = {}
    for name, count in pairs(counts) do
        if count >= 5 then
            table.insert(ready, string.format("%s x%d", name, count))
        end
    end
    table.sort(ready)
    return ready
end

local function petShopEntries()
    local folder = shared_:FindFirstChild("runtime")
    folder = folder and folder:FindFirstChild("cPetShopFolder")
    local list = {}
    if folder then
        for _, entry in ipairs(folder:GetChildren()) do
            table.insert(list, entry)
        end
    end
    table.sort(list, function(a, b)
        return (a:GetAttribute("Price") or 0) < (b:GetAttribute("Price") or 0)
    end)
    return list
end

local function petShopNames()
    local list = {}
    for _, entry in ipairs(petShopEntries()) do
        table.insert(list, entry.Name)
    end
    return list
end

local function buyShopPet(name)
    for _, entry in ipairs(petShopEntries()) do
        if entry.Name == name then
            local ok, result = invoke(NET.petShop, entry)
            return ok and result == true
        end
    end
    return false
end

local function areaEntries()
    local seen, list = {}, {}
    for _, circle in ipairs(areaCircles:GetChildren()) do
        local areaName = circle:FindFirstChild("areaName")
        if areaName and not seen[areaName.Value] then
            seen[areaName.Value] = true
            table.insert(list, { name = areaName.Value, circle = circle })
        end
    end
    table.sort(list, function(a, b)
        return a.name < b.name
    end)
    return list
end

local function areaNames()
    local list = {}
    for _, entry in ipairs(areaEntries()) do
        table.insert(list, entry.name)
    end
    return list
end

local function travelToArea(name)
    for _, entry in ipairs(areaEntries()) do
        if entry.name == name then
            dismount()
            local pivot = entry.circle:IsA("BasePart") and entry.circle.CFrame or entry.circle:GetPivot()
            teleportTo(pivot + Vector3.new(0, 6, 0))
            task.wait(0.6)
            local action = entry.circle:FindFirstChild("universeTeleport") and "teleportToArea" or "travelToArea"
            local ok, result = invoke(NET.areaTravel, action, entry.circle)
            if ok and result == false then
                notify("warning", "Area locked", name .. " needs more rebirths or strength — moved you there anyway.", 4)
            end
            return true
        end
    end
    return false
end

local function rejoinServer()
    if NET.rejoin then
        fire(NET.rejoin)
        task.wait(0.5)
    end
    pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end)
end

window = Snowy:Window({
    Title = "Snowy Studios",
    Subtitle = "Muscle Legends",
    IconPack = "phosphor",
    Keybind = Enum.KeyCode.RightShift,
    MobileButton = true,
})

local farmTab = window:Tab({
    Name = "Farm",
    Icon = "zap",
    Description = "Training, machines and rebirth progression",
})

local farmBox = farmTab:Section({ Title = "Auto farm", Column = 1 })

farmBox:Toggle({
    Text = "Enable auto farm",
    Info = "Runs training and progression from this one switch",
    Flag = "ml_autofarm",
    Default = false,
    Callback = function(on)
        notify(on and "success" or "info", on and "Auto farm on" or "Auto farm off",
            on and "Training loop is running." or "Training loop stopped.", 3)
        if not on then
            leaveMachine()
        end
    end,
})

farmBox:Dropdown({
    Text = "Stat target",
    Info = "Which stat the farm should push",
    Flag = "ml_stat_target",
    Options = { "Auto (weakest stat)", "Strength", "Durability", "Agility", "Balanced" },
    Default = "Auto (weakest stat)",
})

farmBox:Dropdown({
    Text = "Strength method",
    Info = "How strength is trained when strength is the target",
    Flag = "ml_method",
    Options = { "Auto (fastest)", "Punch training", "Weight training", "Best machine", "Balanced training" },
    Default = "Auto (fastest)",
})

farmBox:Dropdown({
    Text = "Training pace",
    Info = "Relaxed adds delay, faster shortens it — the server still throttles reps",
    Flag = "ml_pace",
    Options = { "Game cooldown", "Relaxed", "Faster" },
    Default = "Game cooldown",
})

farmBox:Toggle({
    Text = "Natural training timing",
    Info = "Varies each delay slightly instead of a fixed tick",
    Flag = "ml_natural",
    Default = true,
})

local machineBox = farmTab:Section({ Title = "Machines", Column = 1 })

machineBox:Dropdown({
    Text = "Machine strategy",
    Flag = "ml_machine_strategy",
    Options = { "Best stat gain", "Highest tier", "Closest", "Random" },
    Default = "Best stat gain",
})

machineBox:Toggle({
    Text = "Include Muscle King machines",
    Info = "Only useful once Muscle King is unlocked",
    Flag = "ml_muscle_king",
    Default = false,
})

machineBox:Toggle({
    Text = "Auto treadmill",
    Info = "Stands on the best treadmill your agility allows",
    Flag = "ml_treadmill",
    Default = false,
})

local rebirthBox = farmTab:Section({ Title = "Rebirth", Column = 2 })

rebirthLabel = rebirthBox:Label("Next rebirth at: ?")

rebirthBox:Toggle({
    Text = "Auto rebirth",
    Info = "Rebirths as soon as the requirement is met",
    Flag = "ml_autorebirth",
    Default = false,
})

rebirthBox:Dropdown({
    Text = "Rebirth timing",
    Flag = "ml_rebirth_timing",
    Options = { "Immediately", "Save 25% extra", "Wait for double" },
    Default = "Immediately",
})

rebirthBox:Toggle({
    Text = "Rebirth pet loadouts",
    Info = "Equips rebirth pets before rebirthing, strength pets after",
    Flag = "ml_rebirth_pets",
    Default = false,
})

rebirthBox:Toggle({
    Text = "Wait for x2 rebirth pet",
    Info = "Holds the rebirth until a x2 rebirth pet is owned",
    Flag = "ml_rebirth_double",
    Default = false,
})

rebirthBox:Toggle({
    Text = "Fast rebirth (rep packs)",
    Info = "Consumes strength boosts to reach the requirement sooner",
    Flag = "ml_rebirth_fast",
    Default = false,
})

rebirthBox:Button({
    Text = "Rebirth now",
    ButtonText = "Rebirth",
    Callback = function()
        task.spawn(doRebirth, true)
    end,
})

local boostTab = window:Tab({
    Name = "Boosts",
    Icon = "gauge",
    Description = "Consumables and ultimate upgrades",
})

local boostBox = boostTab:Section({ Title = "Boosts", Column = 1 })

boostBox:Toggle({
    Text = "Auto use boosts",
    Info = "Consumes boosts from your inventory as they arrive",
    Flag = "ml_autoboost",
    Default = false,
})

boostBox:Toggle({
    Text = "Save big boosts for push",
    Info = "Holds TOUGH Bar, ULTRA Shake and eggs back",
    Flag = "ml_save_big",
    Default = true,
})

boostBox:Button({
    Text = "Use all boosts now",
    ButtonText = "Use all",
    Callback = function()
        task.spawn(function()
            local used = useBoosts(true)
            notify(used > 0 and "success" or "info", "Boosts",
                used > 0 and ("Used " .. used .. " boosts.") or "No boosts in your inventory.", 3)
        end)
    end,
})

local ultimateBox = boostTab:Section({ Title = "Ultimates", Column = 2 })

ultimateBox:Toggle({
    Text = "Auto upgrade ultimates",
    Info = "Buys the ultimates in your plan whenever they are affordable",
    Flag = "ml_autoultimate",
    Default = false,
})

ultimateBox:Dropdown({
    Text = "Upgrade plan",
    Info = "Ultimates are bought in the order you pick them",
    Flag = "ml_ultimate_plan",
    Multi = true,
    Options = ultimateNames(),
    Default = {},
    Placeholder = "No ultimates",
})

ultimateBox:Button({
    Text = "Upgrade plan now",
    ButtonText = "Upgrade",
    Callback = function()
        task.spawn(function()
            local count = upgradeUltimates()
            notify(count > 0 and "success" or "info", "Ultimates",
                count > 0 and ("Upgraded " .. count .. ".") or "Nothing affordable right now.", 3)
        end)
    end,
})

local collectTab = window:Tab({
    Name = "Collect",
    Icon = "check-circle",
    Description = "Chests, quests, gifts and timed rewards",
})

local chestBox = collectTab:Section({ Title = "Chests", Column = 1 })

chestBox:Toggle({
    Text = "Auto chests",
    Flag = "ml_autochest",
    Default = false,
})

chestBox:Dropdown({
    Text = "Chest route",
    Flag = "ml_chest_route",
    Options = { "All ready chests", "Nearest ready chest", "Selected chest" },
    Default = "All ready chests",
})

chestBox:Dropdown({
    Text = "Selected chest",
    Flag = "ml_chest_pick",
    Options = CHEST_NAMES,
    Default = CHEST_NAMES[1],
})

chestBox:Toggle({
    Text = "Travel to chest first",
    Info = "Teleports to the chest before claiming it",
    Flag = "ml_chest_travel",
    Default = false,
})

chestBox:Button({
    Text = "Claim all chests",
    ButtonText = "Claim",
    Callback = function()
        task.spawn(function()
            local claimed = claimAllChests(isOn("ml_chest_travel"))
            notify(claimed > 0 and "success" or "info", "Chests",
                claimed > 0 and ("Claimed " .. claimed .. " chests.") or "No chests are ready yet.", 3)
        end)
    end,
})

local collectorBox = collectTab:Section({ Title = "Collectors", Column = 2 })

collectorBox:Toggle({ Text = "Auto NPC quests", Flag = "ml_autoquest", Default = false })
collectorBox:Toggle({ Text = "Auto group reward", Flag = "ml_autogroup", Default = false })
collectorBox:Toggle({ Text = "Auto free gifts", Flag = "ml_autogift", Default = false })
collectorBox:Toggle({ Text = "Auto fortune wheel", Flag = "ml_autowheel", Default = false })
collectorBox:Toggle({ Text = "Auto countdown reward", Flag = "ml_autocountdown", Default = false })

collectorBox:Divider()

collectorBox:Button({
    Text = "Collect everything now",
    ButtonText = "Collect",
    Callback = function()
        task.spawn(function()
            local quests = claimQuests()
            local gifts = claimFreeGifts()
            invoke(NET.group, "groupRewards")
            fire(NET.countdown, "giveCountdownReward")
            notify("success", "Collectors", string.format("%d quests, %d gifts collected.", quests, gifts), 4)
        end)
    end,
})

local petTab = window:Tab({
    Name = "Pets",
    Icon = "sparkle",
    Description = "Hatching, loadouts, evolving and the pet shop",
})

local hatchBox = petTab:Section({ Title = "Hatching", Column = 1 })

hatchBox:Dropdown({
    Text = "Crystal",
    Flag = "ml_crystal_pick",
    Options = crystalNames(),
    Default = crystalNames()[1],
})

hatchBox:Dropdown({
    Text = "Crystal strategy",
    Flag = "ml_crystal_strategy",
    Options = { "Selected crystal", "Most expensive affordable", "Cheapest affordable" },
    Default = "Selected crystal",
})

hatchBox:Toggle({
    Text = "Auto hatch",
    Flag = "ml_autohatch",
    Default = false,
})

hatchBox:Slider({
    Text = "Hatch interval",
    Flag = "ml_hatch_interval",
    Min = 1, Max = 60, Default = 5,
    Suffix = "s",
})

hatchBox:Slider({
    Text = "Bulk amount",
    Info = "How many crystals each purchase opens",
    Flag = "ml_hatch_bulk",
    Min = 1, Max = 10, Default = 1,
})

hatchBox:Slider({
    Text = "Currency reserve",
    Info = "Keeps this much currency unspent",
    Flag = "ml_crystal_reserve",
    Min = 0, Max = 1000000, Default = 0,
})

hatchBox:Toggle({
    Text = "Stop when storage is full",
    Flag = "ml_crystal_protect",
    Default = true,
})

hatchBox:Button({
    Text = "Hatch x1",
    ButtonText = "Hatch",
    Callback = function()
        task.spawn(function()
            local name = pickCrystal() or flag("ml_crystal_pick", nil)
            notify(openCrystal(name, 1) and "success" or "warning", "Hatch",
                tostring(name or "No crystal"), 3)
        end)
    end,
})

hatchBox:Button({
    Text = "Hatch x10",
    ButtonText = "Hatch",
    Callback = function()
        task.spawn(function()
            local name = pickCrystal() or flag("ml_crystal_pick", nil)
            notify(openCrystal(name, 10) and "success" or "warning", "Hatch x10",
                tostring(name or "No crystal"), 3)
        end)
    end,
})

local petBox = petTab:Section({ Title = "Loadout", Column = 2 })

petBox:Toggle({
    Text = "Auto equip best pets",
    Flag = "ml_autoequip",
    Default = false,
})

petBox:Dropdown({
    Text = "Pet priority",
    Flag = "ml_pet_priority",
    Options = { "Total bonuses", "Strength", "Agility", "Durability", "Rebirth bonus", "Rarity" },
    Default = "Total bonuses",
})

petBox:Button({
    Text = "Equip best now",
    ButtonText = "Equip",
    Callback = function()
        task.spawn(function()
            local count = equipBestPets()
            notify(count > 0 and "success" or "info", "Pets",
                count > 0 and ("Equipped " .. count .. " pets.") or "You do not own any pets yet.", 3)
        end)
    end,
})

petBox:Toggle({
    Text = "Auto evolve ready pets",
    Info = "Combines any pet you own five copies of",
    Flag = "ml_autoevolve",
    Default = false,
})

petBox:Button({
    Text = "Scan for evolvable pets",
    ButtonText = "Scan",
    Callback = function()
        task.spawn(function()
            local ready = duplicateReport()
            notify(#ready > 0 and "success" or "info", "Evolve scan",
                #ready > 0 and table.concat(ready, ", ") or "No pet has five copies yet.", 5)
        end)
    end,
})

local shopBox = petTab:Section({ Title = "Pet shop", Column = 2 })

local shopLabel = shopBox:Label("Pick a pet to see its price.")

shopBox:Dropdown({
    Text = "Shop pet",
    Flag = "ml_shop_pet",
    Options = petShopNames(),
    Default = petShopNames()[1],
    Callback = function(name)
        for _, entry in ipairs(petShopEntries()) do
            if entry.Name == name then
                pcall(function()
                    shopLabel:Set(string.format(
                        "%s — %s %s · %s",
                        entry.Name,
                        shortNumber(entry:GetAttribute("Price") or 0),
                        tostring(entry:GetAttribute("PriceType") or "?"),
                        tostring(entry:GetAttribute("Rarity") or "?")
                    ))
                end)
                return
            end
        end
    end,
})

shopBox:Toggle({
    Text = "Auto buy selected pet",
    Flag = "ml_autoshop",
    Default = false,
})

shopBox:Button({
    Text = "Buy selected pet",
    ButtonText = "Buy",
    Callback = function()
        task.spawn(function()
            local name = flag("ml_shop_pet", nil)
            notify(buyShopPet(name) and "success" or "warning", "Pet shop",
                tostring(name or "Nothing selected"), 3)
        end)
    end,
})

local miscTab = window:Tab({
    Name = "Misc",
    Icon = "settings",
    Description = "Utilities, teleports and interface",
})

local utilityBox = miscTab:Section({ Title = "Utilities", Column = 1 })

utilityBox:Toggle({
    Text = "Anti AFK",
    Info = "Keeps the client from being kicked for inactivity",
    Flag = "ml_antiafk",
    Default = true,
})

utilityBox:Toggle({
    Text = "Lock tool farming in King's Gym",
    Info = "Holds your character in the Muscle King area while training with tools",
    Flag = "ml_lock_kings_gym",
    Default = false,
})

utilityBox:Button({
    Text = "Stop all features",
    ButtonText = "Stop",
    Callback = function()
        for _, name in ipairs({
            "ml_autofarm", "ml_treadmill", "ml_autorebirth", "ml_autoboost", "ml_autoultimate",
            "ml_autochest", "ml_autoquest", "ml_autogroup", "ml_autogift", "ml_autowheel",
            "ml_autocountdown", "ml_autohatch", "ml_autoequip", "ml_autoevolve", "ml_autoshop",
        }) do
            Flags[name] = false
        end
        leaveMachine()
        notify("warning", "Stopped", "Every automated feature is now off.", 4)
    end,
})

local teleportBox = miscTab:Section({ Title = "Teleports", Column = 2 })

teleportBox:Dropdown({
    Text = "Select area",
    Flag = "ml_area",
    Options = areaNames(),
    Default = areaNames()[1],
})

teleportBox:Button({
    Text = "Teleport to area",
    ButtonText = "Travel",
    Callback = function()
        task.spawn(function()
            local name = flag("ml_area", nil)
            notify(travelToArea(name) and "success" or "warning", "Travel",
                tostring(name or "No area selected"), 3)
        end)
    end,
})

teleportBox:Button({
    Text = "Rejoin server",
    ButtonText = "Rejoin",
    Callback = function()
        task.spawn(rejoinServer)
    end,
})

local uiBox = miscTab:Section({ Title = "Interface", Column = 2 })

uiBox:Keybind({
    Text = "Menu keybind",
    Flag = "ml_menu_key",
    Default = Enum.KeyCode.RightShift,
    OnChanged = function(key)
        window:SetKeybind(key)
    end,
})

uiBox:Button({
    Text = "Unload script",
    ButtonText = "Unload",
    Callback = function()
        for _, name in ipairs({ "ml_autofarm", "ml_treadmill", "ml_autorebirth" }) do
            Flags[name] = false
        end
        leaveMachine()
        window:Destroy()
    end,
})

local function targetStat()
    local target = flag("ml_stat_target", "Auto (weakest stat)")
    if target == "Auto (weakest stat)" then
        return weakestStat()
    elseif target == "Balanced" then
        local order = { "Strength", "Durability", "Agility" }
        return order[(math.floor(os.clock() / 20) % 3) + 1]
    end
    return target
end

local function runTrainingCycle()
    local stat = targetStat()

    if stat == "Agility" then
        if withMovement(runTreadmill) then
            return
        end
    end

    local method = flag("ml_method", "Auto (fastest)")

    if stat ~= "Strength" then
        method = "Best machine"
    end

    if method == "Punch training" or method == "Weight training" then
        if trainWithTool(method) then
            return
        end
        method = "Best machine"
    end

    if method == "Balanced training" then
        local order = { "Strength", "Durability", "Agility" }
        stat = order[(math.floor(os.clock() / 15) % 3) + 1]
        method = "Best machine"
    end

    if method == "Best machine" then
        if withMovement(function()
            trainOnMachine(stat)
        end) then
            return
        end
    end

    local tool = pickTool("Auto")
    local machine = pickMachine(stat)
    local toolRate = tool and (tool.gain / math.max(tool.cadence, 0.1)) or 0
    local machineRate = machine and (machine.gain / math.max(machine.repTime, 0.1)) or 0

    if machine and machineRate >= toolRate then
        withMovement(function()
            trainOnMachine(stat)
        end)
    elseif tool then
        trainWithTool("Auto")
    end
end

task.spawn(function()
    while true do
        task.wait(0.2)
        if isOn("ml_autofarm") and alive() then
            local ok, err = pcall(runTrainingCycle)
            if not ok then
                warn("[Muscle Legends] farm cycle: " .. tostring(err))
                task.wait(1)
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(1)
        if isOn("ml_treadmill") and not isOn("ml_autofarm") and alive() then
            withMovement(runTreadmill)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(2)
        updateRebirthLabel()
        if isOn("ml_autorebirth") and alive() then
            local required = requiredRebirthStrength()
            if required then
                local target = required * rebirthMultiplierTarget()
                local blocked = isOn("ml_rebirth_double") and not hasDoubleRebirthPet()
                if StrengthValue.Value >= target and not blocked then
                    doRebirth(false)
                elseif isOn("ml_rebirth_fast") and StrengthValue.Value < target then
                    useBoosts(true)
                end
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(15)
        if isOn("ml_autoboost") then
            useBoosts(not isOn("ml_save_big"))
        end
        if isOn("ml_autoultimate") then
            upgradeUltimates()
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(30)
        if isOn("ml_autochest") then
            withMovement(function()
                claimAllChests(isOn("ml_chest_travel"))
            end)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(10)
        if isOn("ml_autoquest") then
            claimQuests()
        end
        if isOn("ml_autogroup") then
            invoke(NET.group, "groupRewards")
        end
        if isOn("ml_autogift") then
            claimFreeGifts()
        end
        if isOn("ml_autowheel") then
            spinFortuneWheel()
        end
        if isOn("ml_autocountdown") then
            fire(NET.countdown, "giveCountdownReward")
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(math.max(1, tonumber(flag("ml_hatch_interval", 5)) or 5))
        if isOn("ml_autohatch") then
            openCrystal(pickCrystal(), flag("ml_hatch_bulk", 1))
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(20)
        if isOn("ml_autoequip") then
            equipBestPets()
        end
        if isOn("ml_autoevolve") then
            evolveReadyPets()
        end
        if isOn("ml_autoshop") then
            buyShopPet(flag("ml_shop_pet", nil))
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(60)
        if isOn("ml_antiafk") then
            local camera = Workspace.CurrentCamera
            if camera then
                pcall(function()
                    VirtualUser:Button2Down(Vector2.new(0, 0), camera.CFrame)
                    task.wait(0.1)
                    VirtualUser:Button2Up(Vector2.new(0, 0), camera.CFrame)
                end)
            end
        end
    end
end)

pcall(function()
    for _, connection in ipairs(getconnections(LocalPlayer.Idled)) do
        connection:Disable()
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    currentSeat = nil
    busy = false
end)

updateRebirthLabel()

notify("success", "Muscle Legends", "Loaded. Press RightShift or the MENU pill to toggle.", 5)

return window
