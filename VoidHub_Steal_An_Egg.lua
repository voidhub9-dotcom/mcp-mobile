-- VoidHub | Steal An Egg | by von63rd | v1
-- Powered by VoidHub- UI Library

if not game:IsLoaded() then
	game.Loaded:Wait()
end

local function applyBypass()
	local getupvalues = debug.getupvalues or getupvalues
	local setrawmetatable = setrawmetatable or debug.setmetatable or setmetatable

	local targets = filtergc("function", {
		Constants = { "gmatch", "GetFullName" }
	})

	if type(targets) == "function" then
		targets = { targets }
	elseif type(targets) ~= "table" then
		targets = {}
	end

	local hookedCount = 0
	for _, func in ipairs(targets) do
		local uvs = getupvalues(func)
		if uvs then
			for _, tableObj in pairs(uvs) do
				if typeof(tableObj) == "table" then
					setrawmetatable(tableObj, {
						__newindex = function(_, index, value)
							warn(`[VoidHub] Blocked detection {index} {value}`)
						end
					})
					hookedCount = hookedCount + 1
				end
			end
		end
	end

	return hookedCount > 0
end

local bypassSuccess = false
for _ = 1, 30 do
	local ok, hooked = pcall(applyBypass)
	if ok and hooked then
		bypassSuccess = true
		print("[VoidHub] Anti-Cheat Bypassed successfully!")
		break
	end
	task.wait(0.2)
end

if not bypassSuccess then
	warn("[VoidHub] Warning: Anti-cheat function not found yet, proceeding with fallback...")
end

task.wait(0.5)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local GAME_NAME = "Steal An Egg"
local HUB_NAME = "VoidHub"
local HUB_ICON = "rbxassetid://101833678008843"
local DISCORD_INVITE = "https://discord.gg/Wsarxj9Gzz"

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
local Constants = require(ReplicatedStorage.Shared.Globals.Constants)
local Save = require(ReplicatedStorage.Shared.Save)
local BaseUpgradeClient = require(ReplicatedStorage.Client.BaseUpgrade)
local EggTypes = require(ReplicatedStorage.Shared.Types.Eggs)
local Areas = require(ReplicatedStorage.Data.Areas)
local Assets = require(ReplicatedStorage.Data.Assets)
local Gears = require(ReplicatedStorage.Data.Gears)
local Trails = require(ReplicatedStorage.Data.Trails)
local Treadmills = require(ReplicatedStorage.Data.Treadmills)

local EggCmds
do
	local eggState = require(ReplicatedStorage.Client.EggState)
	EggCmds = {
		GetAreaEggSnapshot = eggState.ReadFieldEggs,
		RequestAreaEggSnapshot = eggState.SyncFieldEggs,
		AreaEggCarryStateChanged = eggState.CarryChanged,
		RequestCarryAreaEgg = eggState.CarryFieldEgg,
		RequestDropHeldAreaEgg = function()
			return eggState.DropFieldEgg("PlayerRequest")
		end,
		IsLocalEggReady = eggState.IsReadyToHatch,
		RequestHatchEgg = eggState.BeginHatch,
		RequestCompleteHatchEgg = eggState.FinishHatch,
		RequestEquipTool = eggState.WearEggTool,
		RequestPlaceEgg = eggState.PlantEgg,
	}
end

local PlotCmds
do
	local plotState = require(ReplicatedStorage.Client.PlotState)
	PlotCmds = {
		GetRespawnPointCFrame = plotState.FindRespawnCFrame,
		GetPlotData = plotState.ResolvePlot,
		IsWorldPositionWithinLocalPlotBounds = plotState.ContainsLocalPoint,
		GetSlotOwner = plotState.LookupOwner,
	}
end

local AreaEggSlotIdentity
do
	local slotId = require(ReplicatedStorage.Shared.Util.AreaEggSlotIdentity)
	AreaEggSlotIdentity = {
		IsFirstAreaUid = slotId.LooksLikeFirstAreaUid,
		BuildSlotKey = slotId.SlotKey,
	}
end

local AssetCmds
do
	local roster = require(ReplicatedStorage.Client.AssetRoster)
	AssetCmds = {
		GetRuntimeSnapshot = roster.ReadSnapshot,
	}
end

local AssetItemSerialization
do
	local items = require(ReplicatedStorage.Shared.Util.AssetItems)
	AssetItemSerialization = {
		Deserialize = items.Decode,
	}
end

local FuseKernelUtil
do
	local fuse = require(ReplicatedStorage.Shared.Util.FuseKernel)
	FuseKernelUtil = {
		CanSelectPet = fuse.MayEnterFuse,
		CalculateFusePrice = fuse.PriceFor,
	}
end

local NET = {
	Backpack = {
		EQUIP_BEST = Remotes.Haul.WearBest,
	},
	Plots = {
		REQUEST_BASE_UPGRADE = Remotes.Homestead.AskBaseTierRaise,
	},
	Treadmills = {
		REQUEST_UPGRADE = Remotes.Treadmill.AskTierRaise,
		REQUEST_EQUIP_STATIC = Remotes.Treadmill.AskWearStill,
		REQUEST_UNEQUIP = Remotes.Treadmill.AskDoff,
	},
	Index = {
		REQUEST_CLAIM_ALL = Remotes.Codex.AskRedeemAll,
	},
	AssetInventory = {
		SELL_ASSET = Remotes.PetSatchel.SellPet,
	},
	OfflineAssets = {
		GET_SUMMARY = Remotes.AwayEarnings.FetchSummary,
		REQUEST_REDEEM = Remotes.AwayEarnings.AskCollect,
	},
	FuseMachine = {
		COMPLETE_REVEAL = Remotes.Fusery.FinishReveal,
		ACKNOWLEDGE_INFO = Remotes.Fusery.ConfirmBriefing,
		INSERT_MOB = Remotes.Fusery.LoadPet,
		START_FUSE = Remotes.Fusery.BeginFuse,
	},
	Trails = {
		REQUEST_PURCHASE = Remotes.Trailwear.AskPurchase,
		REQUEST_SELECT = Remotes.Trailwear.AskChoose,
		WORN_SNAPSHOT = Remotes.Trailwear.AskWornSnapshot,
	},
	GroupReward = {
		CLAIM_REWARD = Remotes.GroupPerk.RedeemPerk,
	},
}

local OBSIDIAN_REPO = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(OBSIDIAN_REPO .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(OBSIDIAN_REPO .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(OBSIDIAN_REPO .. "addons/SaveManager.lua"))()

if getgenv then
	local previous = getgenv().VoidHubStealAnEgg
	if typeof(previous) == "table" and previous.Unload then
		pcall(function()
			previous.Unload()
		end)
	end
end

-- Black & white, white accent - set before CreateWindow so every element
-- (including the ones CreateWindow itself builds) renders with these
-- colors from the first frame instead of flashing the default purple.
Library.Scheme.BackgroundColor = Color3.fromRGB(8, 8, 8)
Library.Scheme.MainColor = Color3.fromRGB(20, 20, 20)
Library.Scheme.AccentColor = Color3.fromRGB(255, 255, 255)
Library.Scheme.OutlineColor = Color3.fromRGB(45, 45, 45)
Library.Scheme.FontColor = Color3.new(1, 1, 1)

local Window = Library:CreateWindow({
	Title = HUB_NAME,
	Footer = GAME_NAME .. " | by von63rd | v1",
	Icon = HUB_ICON,
	Size = UDim2.fromOffset(660, 480),
	NotifySide = "Right",
	ShowCustomCursor = true,
	Animations = {
		ToggleWindow = true,
		TabSwitch = true,
		Groupbox = true,
		Dropdown = true,
		KeyPicker = true,
	},
})

local Toggles = Library.Toggles
local Options = Library.Options

local Unloaded = false
local State = {}
local F = {}

F.notify = function(text, duration)
	if Unloaded then
		return
	end
	Library:Notify({ Title = HUB_NAME, Description = tostring(text), Time = duration or 4 })
end

F.isOn = function(name)
	if Unloaded then
		return false
	end
	return State[name] == true
end

F.optionValue = function(name, fallback)
	local value = State[name]
	if value == nil then
		return fallback
	end
	return value
end

F.multiSelected = function(name)
	local value = F.optionValue(name, {})
	if typeof(value) ~= "table" then
		return {}
	end
	local selected = {}
	for key, on in pairs(value) do
		if on == true then
			selected[key] = true
		elseif typeof(key) == "number" and typeof(on) == "string" then
			selected[on] = true
		end
	end
	return selected
end

F.multiHasAny = function(name)
	return next(F.multiSelected(name)) ~= nil
end

F.selectionAllows = function(name, value)
	if not F.multiHasAny(name) then
		return true
	end
	return F.multiSelected(name)[value] == true
end

-- ============================================================
-- Control wrappers
--
-- Obsidian registers every control into the global Library.Toggles /
-- Library.Options tables by the Idx you give it, each with :SetValue()
-- - and SaveManager persists anything in those tables for free once
-- SaveManager:BuildConfigSection is wired up in Settings, so there is
-- no need for a hand-rolled config system here.
-- ============================================================

local function AddToggle(section, id, title, default, callback, tooltip)
	State[id] = default == true
	section:AddToggle(id, {
		Text = title,
		Default = default == true,
		Tooltip = tooltip,
		Callback = function(value)
			State[id] = value == true
			if callback then
				task.spawn(callback, value == true)
			end
		end,
	})
end

local function AddSlider(section, id, title, min, max, default, suffix, callback, tooltip)
	State[id] = default
	section:AddSlider(id, {
		Text = title,
		Min = min,
		Max = max,
		Default = default,
		Rounding = 0,
		Suffix = suffix,
		Tooltip = tooltip,
		Callback = function(value)
			State[id] = value
			if callback then
				task.spawn(callback, value)
			end
		end,
	})
end

local function AddDropdown(section, id, title, options, default, callback, tooltip)
	State[id] = default
	section:AddDropdown(id, {
		Values = options,
		Default = default,
		Multi = false,
		Text = title,
		Searchable = #options > 8,
		Tooltip = tooltip,
		Callback = function(value)
			State[id] = value
			if callback then
				task.spawn(callback, value)
			end
		end,
	})
end

local function AddMultiSelect(section, id, title, options, defaults, callback, tooltip)
	local defaultSet = {}
	for _, name in ipairs(defaults or {}) do
		defaultSet[name] = true
	end
	State[id] = defaultSet
	section:AddDropdown(id, {
		Values = options,
		Multi = true,
		Text = title,
		Searchable = #options > 8,
		Tooltip = tooltip,
		Callback = function(value)
			State[id] = value
			if callback then
				task.spawn(callback, value)
			end
		end,
	})
	if next(defaultSet) then
		Options[id]:SetValue(defaultSet)
	end
end

local function AddButton(section, title, callback, tooltip)
	section:AddButton({
		Text = title,
		Tooltip = tooltip,
		Func = function()
			task.spawn(function()
				local ok, err = pcall(callback)
				if not ok then
					warn("[VoidHub] " .. tostring(err))
				end
			end)
		end,
	})
end

local function AddTextBox(section, id, title, placeholder, callback, tooltip)
	State[id] = ""
	section:AddInput(id, {
		Default = "",
		Text = title,
		Placeholder = placeholder,
		Finished = true,
		Tooltip = tooltip,
		Callback = function(value)
			State[id] = value
			if callback then
				task.spawn(callback, value)
			end
		end,
	})
end

F.setControl = function(id, value)
	State[id] = value
	pcall(function()
		local toggle = Toggles[id]
		if toggle then
			toggle:SetValue(value)
			return
		end
		local option = Options[id]
		if option then
			option:SetValue(value)
		end
	end)
end

F.copyText = function(text, message)
	if setclipboard then
		setclipboard(text)
	elseif toclipboard then
		toclipboard(text)
	else
		F.notify("Your executor does not support copying to the clipboard")
		return
	end
	F.notify(message)
end

local RARITY_RANK = {}
local RARITY_VALUES = {}

do
	local BASE_LADDER = {
		"Common", "Uncommon", "Rare", "Epic", "Legendary",
		"Mythic", "Cosmic", "Secret", "Eternal", "Divine",
	}

	local ladderIndex = {}
	for index, name in ipairs(BASE_LADDER) do
		ladderIndex[name] = index
	end

	local found = {}

	local function rarityOrder(entry)
		if typeof(entry) ~= "table" then
			return nil
		end
		return tonumber(entry.Order)
			or tonumber(entry.Priority)
			or tonumber(entry.Index)
			or tonumber(entry.Tier)
			or tonumber(entry.Rank)
			or tonumber(entry.Level)
	end

	local function remember(name, order)
		if typeof(name) ~= "string" or name == "" then
			return
		end
		local entry = found[name]
		if not entry then
			entry = {}
			found[name] = entry
		end
		if typeof(order) == "number" and (entry.order == nil or order < entry.order) then
			entry.order = order
		end
	end

	pcall(function()
		for _, asset in pairs(Assets.Directory) do
			if typeof(asset) == "table" and typeof(asset.Rarity) == "table" then
				remember(asset.Rarity._id or asset.Rarity.DisplayName, rarityOrder(asset.Rarity))
			end
		end
	end)

	pcall(function()
		local dataFolder = ReplicatedStorage:FindFirstChild("Data")
		local module = dataFolder and dataFolder:FindFirstChild("Rarities")
		if not module then
			return
		end
		local loaded = require(module)
		local directory = typeof(loaded) == "table" and (loaded.Directory or loaded) or nil
		if typeof(directory) ~= "table" then
			return
		end
		for key, entry in pairs(directory) do
			if typeof(entry) == "table" then
				local name = entry._id or entry.DisplayName or (typeof(key) == "string" and key or nil)
				if name and found[name] then
					remember(name, rarityOrder(entry) or (typeof(key) == "number" and key or nil))
				end
			end
		end
	end)

	local scanned = 0
	for _ in pairs(found) do
		scanned += 1
	end
	if scanned < 2 then
		for _, name in ipairs(BASE_LADDER) do
			remember(name, nil)
		end
	end

	local ordered = {}
	for name, entry in pairs(found) do
		table.insert(ordered, {
			name = name,
			order = entry.order,
			ladder = ladderIndex[name],
		})
	end

	local everyOneOrdered = #ordered > 0
	for _, entry in ipairs(ordered) do
		if entry.order == nil then
			everyOneOrdered = false
			break
		end
	end

	table.sort(ordered, function(a, b)
		if everyOneOrdered then
			if a.order ~= b.order then
				return a.order < b.order
			end
			return a.name < b.name
		end
		if (a.ladder ~= nil) ~= (b.ladder ~= nil) then
			return a.ladder ~= nil
		end
		if a.ladder and b.ladder then
			return a.ladder < b.ladder
		end
		if (a.order ~= nil) ~= (b.order ~= nil) then
			return a.order ~= nil
		end
		if a.order and b.order then
			return a.order < b.order
		end
		return a.name < b.name
	end)

	for rank, entry in ipairs(ordered) do
		table.insert(RARITY_VALUES, entry.name)
		RARITY_RANK[entry.name] = rank
	end
end

local ZONE_VALUES = {}
for areaId in pairs(Areas.Directory) do
	table.insert(ZONE_VALUES, areaId)
end
table.sort(ZONE_VALUES)

local UPGRADE_VALUES = { "Base", "Treadmill" }

local TRAIL_VALUES = {}
local TRAIL_ID_BY_NAME = {}
local TRAIL_PRICE_BY_NAME = {}
do
	local ordered = {}
	for id, data in pairs(Trails.Directory) do
		table.insert(ordered, {
			id = id,
			name = data.DisplayName,
			price = tonumber(data.Price) or 0,
		})
	end
	table.sort(ordered, function(a, b)
		return a.price < b.price
	end)
	for _, entry in ipairs(ordered) do
		table.insert(TRAIL_VALUES, entry.name)
		TRAIL_ID_BY_NAME[entry.name] = entry.id
		TRAIL_PRICE_BY_NAME[entry.name] = entry.price
	end
end

local GEAR_COST_BY_NAME = {}
do
	for _, data in pairs(Gears.Directory or Gears) do
		if typeof(data) == "table" and typeof(data.DisplayName) == "string" then
			GEAR_COST_BY_NAME[data.DisplayName] = tonumber(data.MoneyCost) or 0
		end
	end
end

local MUTATION_VALUES = {}

do
	local BASE_MUTATIONS = { "Golden", "Rainbow", "Silver" }
	local found = {}
	local ordered = {}

	local function remember(name)
		if typeof(name) ~= "string" or name == "" or found[name] then
			return
		end
		found[name] = true
		table.insert(ordered, name)
	end

	pcall(function()
		local dataFolder = ReplicatedStorage:FindFirstChild("Data")
		local module = dataFolder and dataFolder:FindFirstChild("Mutations")
		if not module then
			return
		end
		local loaded = require(module)
		local directory = typeof(loaded) == "table" and (loaded.Directory or loaded) or nil
		if typeof(directory) ~= "table" then
			return
		end
		for key, entry in pairs(directory) do
			if typeof(entry) == "table" then
				remember(entry._id or entry.DisplayName or (typeof(key) == "string" and key or nil))
			elseif typeof(entry) == "string" then
				remember(entry)
			elseif typeof(key) == "string" then
				remember(key)
			end
		end
	end)

	table.sort(ordered)

	for _, name in ipairs(BASE_MUTATIONS) do
		remember(name)
	end

	MUTATION_VALUES = ordered
end

local PRIORITY_VALUES = { "Rarest", "Nearest", "Furthest", "Biggest Size" }

local FUSE_TARGET_VALUES = { "Highest Rarity", "Lowest Rarity", "Most Duplicates" }

local PRIORITY_TASKS = { "Auto Steal Egg", "Auto Place Egg", "Auto Hatch", "Auto Treadmill" }

local PRIORITY_SLOTS = { "PrioritySlot1", "PrioritySlot2", "PrioritySlot3", "PrioritySlot4" }

local HOP_MODES = { "No Matching Eggs", "Timed Interval", "After Steal Count" }

local jobIdText = tostring(game.JobId)
local shortJobIdText = #jobIdText > 18 and (string.sub(jobIdText, 1, 18) .. "...") or jobIdText

local sessionStart = os.clock()

F.getRoot = function()
	local character = LocalPlayer.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

F.getHumanoid = function()
	local character = LocalPlayer.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

F.netInvoke = function(remote, ...)
	if typeof(remote) ~= "Instance" then
		return nil
	end
	local done = false
	local results = nil
	local args = table.pack(...)
	task.spawn(function()
		local packed
		if remote:IsA("RemoteFunction") then
			packed = table.pack(pcall(function()
				return remote:InvokeServer(table.unpack(args, 1, args.n))
			end))
		elseif remote:IsA("RemoteEvent") then
			packed = table.pack(pcall(function()
				remote:FireServer(table.unpack(args, 1, args.n))
				return true
			end))
		else
			packed = table.pack(false)
		end
		results = packed
		done = true
	end)
	local deadline = os.clock() + 8
	while not done and os.clock() < deadline do
		task.wait(0.05)
	end
	if not done or results[1] ~= true then
		return nil
	end
	return results[2], results[3]
end

F.netCall = function(remote, ...)
	if typeof(remote) == "Instance" and remote:IsA("RemoteEvent") then
		local ok = pcall(function(...)
			remote:FireServer(...)
		end, ...)
		return ok
	end
	return F.netInvoke(remote, ...)
end

local GuardAreasFolder = Workspace:WaitForChild("__OBJECTS"):WaitForChild("Areas"):WaitForChild("GuardAreas")
local AreasFolder = Workspace:WaitForChild("__OBJECTS"):WaitForChild("Areas")

local ZONE_ORDER = {
	"Forest",
	"Lake",
	"Desert",
	"Jungle",
	"Snow",
	"Volcano",
	"Abyss Ocean",
	"Prehistoric",
	"Cosmic",
}

F.getLaneZ = function()
	local gameplay = AreasFolder:FindFirstChild("GameplayZ")
	if gameplay and gameplay:IsA("BasePart") then
		return gameplay.Position.Z
	end
	local sep = AreasFolder:FindFirstChild("SeparationLine")
	if sep and sep:IsA("BasePart") then
		return sep.Position.Z
	end
	return -365.5
end

F.getLaneY = function()
	local gameplay = AreasFolder:FindFirstChild("GameplayZ")
	if gameplay and gameplay:IsA("BasePart") then
		return gameplay.Position.Y + 3
	end
	local root = F.getRoot()
	return root and root.Position.Y or 70
end

F.getEntryPosition = function()
	local startArea = AreasFolder:FindFirstChild("StartArea")
	if startArea and startArea:IsA("BasePart") then
		return Vector3.new(startArea.Position.X, F.getLaneY(), F.getLaneZ())
	end
	local sep = AreasFolder:FindFirstChild("SeparationLine")
	if sep and sep:IsA("BasePart") then
		return Vector3.new(sep.Position.X, F.getLaneY(), F.getLaneZ())
	end
	return Vector3.new(543.5, F.getLaneY(), F.getLaneZ())
end

F.getZoneModel = function(areaId)
	return GuardAreasFolder:FindFirstChild(areaId)
end

F.getZoneLaneCenter = function(areaId)
	local zone = F.getZoneModel(areaId)
	if not zone then
		return nil
	end
	local bounds = zone:FindFirstChild("Bounds")
	if bounds and bounds:IsA("BasePart") then
		return Vector3.new(bounds.Position.X, F.getLaneY(), F.getLaneZ())
	end
	local ok, cf = pcall(function()
		return zone:GetBoundingBox()
	end)
	if ok and cf then
		return Vector3.new(cf.Position.X, F.getLaneY(), F.getLaneZ())
	end
	return nil
end

F.getCorridorBounds = function()
	local minX, maxX = math.huge, -math.huge
	local minZ, maxZ = math.huge, -math.huge
	for _, name in ipairs(ZONE_ORDER) do
		local zone = F.getZoneModel(name)
		local bounds = zone and zone:FindFirstChild("Bounds")
		if bounds and bounds:IsA("BasePart") then
			local halfX = bounds.Size.X * 0.5
			local halfZ = bounds.Size.Z * 0.5
			minX = math.min(minX, bounds.Position.X - halfX)
			maxX = math.max(maxX, bounds.Position.X + halfX)
			minZ = math.min(minZ, bounds.Position.Z - halfZ)
			maxZ = math.max(maxZ, bounds.Position.Z + halfZ)
		end
	end
	local entry = F.getEntryPosition()
	minX = math.min(minX, entry.X - 20)
	return minX, maxX, minZ, maxZ
end

F.clampToCorridor = function(position, allowLobby)
	if allowLobby then
		return position
	end
	local minX, maxX, minZ, maxZ = F.getCorridorBounds()
	return Vector3.new(
		math.clamp(position.X, minX, maxX),
		position.Y,
		math.clamp(position.Z, minZ, maxZ)
	)
end

F.rawTeleport = function(position)
	local root = F.getRoot()
	if not root or typeof(position) ~= "Vector3" then
		return false
	end
	root.CFrame = CFrame.new(position) * (root.CFrame - root.CFrame.Position)
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	return true
end

F.travelTo = function(goalPosition, allowLobby)
	if typeof(goalPosition) ~= "Vector3" or Unloaded then
		return false
	end
	local target = F.clampToCorridor(goalPosition, allowLobby == true)
	if not F.rawTeleport(target) then
		return false
	end
	task.wait()
	return true
end

F.getEggPosition = function(record)
	local goal = record.BottomCFrame or record.BoundsCFrame
	if not goal then
		return nil
	end
	local eggPos = goal.Position
	local _, _, minZ, maxZ = F.getCorridorBounds()
	return Vector3.new(eggPos.X, eggPos.Y + 2, math.clamp(eggPos.Z, minZ, maxZ))
end

F.getBasePosition = function()
	local respawn = PlotCmds.GetRespawnPointCFrame()
	if respawn then
		return respawn.Position
	end
	local plot = PlotCmds.GetPlotData()
	if plot and plot.CenterPoint then
		return plot.CenterPoint.Position
	end
	if plot and plot.PetArea then
		return plot.PetArea.Position
	end
	return nil
end

F.getSave = function()
	local ok, data = pcall(function()
		return Save.Get()
	end)
	if ok then
		return data
	end
	return nil
end

F.resolveRarity = function(assetCategory)
	if typeof(assetCategory) ~= "string" then
		return nil
	end
	local asset = Assets.Directory[assetCategory]
	if not asset or not asset.Rarity then
		return nil
	end
	return asset.Rarity._id or asset.Rarity.DisplayName
end

F.getAreaEggs = function()
	local snap = EggCmds.GetAreaEggSnapshot()
	if typeof(snap) ~= "table" or typeof(snap.Records) ~= "table" then
		pcall(function()
			EggCmds.RequestAreaEggSnapshot()
		end)
		snap = EggCmds.GetAreaEggSnapshot()
	end
	if typeof(snap) ~= "table" or typeof(snap.Records) ~= "table" then
		return {}
	end
	local eggs = {}
	for _, record in pairs(snap.Records) do
		if typeof(record) == "table" and typeof(record.Uid) == "string" then
			table.insert(eggs, record)
		end
	end
	return eggs
end

local carryingEgg = false
local hopStealCount = 0

local onEggClaimed = nil

local carryConnection = EggCmds.AreaEggCarryStateChanged:Connect(function(state)
	local nowCarrying = typeof(state) == "table" and state.IsCarrying == true
	if nowCarrying and not carryingEgg then
		hopStealCount += 1
		if onEggClaimed then
			onEggClaimed(state)
		end
	end
	carryingEgg = nowCarrying
end)

F.isCarrying = function()
	return carryingEgg
end

F.recordMutations = function(record)
	local list = {}
	if typeof(record) ~= "table" then
		return list
	end
	if typeof(record.Mutations) == "table" then
		for _, mutation in pairs(record.Mutations) do
			if typeof(mutation) == "string" then
				table.insert(list, mutation)
			end
		end
	end
	if typeof(record.BaseMutation) == "string" then
		table.insert(list, record.BaseMutation)
	end
	return list
end

F.matchesMutationFilter = function(optionName, record)
	if not F.multiHasAny(optionName) then
		return true
	end
	local wanted = F.multiSelected(optionName)
	for _, mutation in ipairs(F.recordMutations(record)) do
		if wanted[mutation] then
			return true
		end
	end
	return false
end

F.matchesEggFilters = function(record, areaOption, rarityOption, mutationOption)
	if areaOption then
		local areaId = record.AreaId
		if typeof(areaId) ~= "string" or not F.selectionAllows(areaOption, areaId) then
			return false
		end
	end
	local rarity = F.resolveRarity(record.AssetCategory)
	if typeof(rarity) ~= "string" or not F.selectionAllows(rarityOption, rarity) then
		return false
	end
	return F.matchesMutationFilter(mutationOption, record)
end

F.eggInventoryCount = function()
	local data = F.getSave()
	local inventory = data and data.EggInventory
	if typeof(inventory) ~= "table" then
		return 0
	end
	local total = 0
	for _ in pairs(inventory) do
		total += 1
	end
	return total
end

F.eggInventoryFull = function()
	local limit = tonumber(EggTypes.MAX_INVENTORY) or math.huge
	return F.eggInventoryCount() >= limit
end

local AreaEggSlots = Workspace:FindFirstChild("AreaEggSlotsClient") or Workspace:WaitForChild("AreaEggSlotsClient", 10)

F.getSlotEggPosition = function(eggModel)
	local part = eggModel:FindFirstChild("Hitbox")
		or eggModel:FindFirstChild("CustomBoundingBox")
		or eggModel:FindFirstChildOfClass("BasePart")
	return part and part.Position or eggModel:GetPivot().Position
end

F.isBigEgg = function(record)
	if not F.isOn("StealBigEggs") then
		return false
	end
	local scale = tonumber(record.AssetScale)
	if not scale then
		return false
	end
	return scale >= (tonumber(F.optionValue("StealBigEggScale", 2)) or 2)
end

F.eggScore = function(record)
	local rarity = F.resolveRarity(record.AssetCategory) or "Common"
	return RARITY_RANK[rarity] or 0
end

F.isStealCandidate = function(record, ignoreFilters)
	if typeof(record) ~= "table" or typeof(record.Uid) ~= "string" then
		return false
	end
	if record.State ~= "Slot" and record.State ~= "Dropped" then
		return false
	end
	if ignoreFilters then
		return true
	end
	if F.isBigEgg(record) and F.selectionAllows("StealZones", record.AreaId) then
		return true
	end
	if not F.isOn("AutoStealSelected") then
		return false
	end
	return F.matchesEggFilters(record, "StealZones", "StealRarities", "StealMutations")
end

F.pickStealTarget = function()
	local slots = AreaEggSlots and AreaEggSlots:GetChildren() or {}
	if #slots == 0 then
		return nil
	end
	local recordByUid = {}
	for _, record in ipairs(F.getAreaEggs()) do
		if typeof(record.Uid) == "string" then
			recordByUid[record.Uid] = record
		end
	end
	local ignoreFilters = F.isOn("AutoStealAll") and not F.isOn("AutoStealSelected")
	local root = F.getRoot()
	local priority = F.optionValue("StealPriority", "Rarest")
	local best, bestScore = nil, -math.huge
	for _, slot in ipairs(slots) do
		local record = recordByUid[slot.Name]
		local eligible = (record ~= nil and F.isStealCandidate(record, ignoreFilters))
			or (record == nil and ignoreFilters)
		if eligible then
			local pos = F.getSlotEggPosition(slot)
			local dist = (root and pos) and (root.Position - pos).Magnitude or math.huge
			local score
			if priority == "Nearest" then
				score = -dist
			elseif priority == "Furthest" then
				score = dist
			elseif priority == "Biggest Size" then
				score = record and tonumber(record.AssetScale) or 0
			else
				score = (record and F.eggScore(record) or 0) * 100000 - math.min(dist, 99999)
			end
			if score > bestScore then
				best = slot
				bestScore = score
			end
		end
	end
	return best
end

F.tryCarryEgg = function(eggModel)
	if not eggModel then
		return false
	end
	local uid = eggModel.Name
	local slotKey = nil
	if AreaEggSlotIdentity.IsFirstAreaUid(uid) then
		for _, record in ipairs(F.getAreaEggs()) do
			if record.Uid == uid then
				slotKey = AreaEggSlotIdentity.BuildSlotKey(record.AreaId, record.NestId)
				break
			end
		end
	end
	local ok, success = pcall(function()
		return EggCmds.RequestCarryAreaEgg(uid, slotKey)
	end)
	return (ok and success == true) or F.isCarrying()
end

local RETURN_PACE = 0.08
local MOVE_SPEED = 300
local STEAL_SETTINGS = {
	GrabDelay = 0.55,
	ReturnPace = 0.12,
	CorridorMidpoint = Vector3.new(527, 71, -352),
}

F.swapStealHumanoid = function()
	local char = LocalPlayer.Character
	if not char then
		return false
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then
		return false
	end
	if hum:GetAttribute("VoidHubStealHum") == true then
		return true
	end
	for _, scr in ipairs(char:GetDescendants()) do
		if scr:IsA("LocalScript") and string.find(scr.Name, "PushBack") then
			pcall(function()
				scr.Disabled = true
				scr:Destroy()
			end)
		end
	end
	hum.Archivable = true
	local clone = hum:Clone()
	if not clone then
		return false
	end
	clone:SetAttribute("VoidHubStealHum", true)
	clone.Sit = false
	clone.PlatformStand = false
	clone.AutoRotate = true
	hum:Destroy()
	clone.Parent = char
	local root = char:FindFirstChild("HumanoidRootPart")
	if root then
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end
	pcall(function()
		clone:ChangeState(Enum.HumanoidStateType.Running)
	end)
	return char:FindFirstChildOfClass("Humanoid") ~= nil
end

F.groundedY = function(x, z, fallbackY)
	local laneY = F.getLaneY()
	local root = F.getRoot()
	local humanoid = F.getHumanoid()
	local hip = (humanoid and humanoid.HipHeight > 0 and humanoid.HipHeight) or 2
	local half = root and root.Size.Y * 0.5 or 1
	local standOffset = hip + half
	local maxFloor = laneY + 1.5
	local ignore = {}
	if LocalPlayer.Character then
		table.insert(ignore, LocalPlayer.Character)
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local originY = laneY + 40
	local bestGroundY = nil
	for _ = 1, 20 do
		params.FilterDescendantsInstances = ignore
		local hit = Workspace:Raycast(Vector3.new(x, originY, z), Vector3.new(0, -160, 0), params)
		if not hit then
			break
		end
		local hitY = hit.Position.Y
		local name = hit.Instance.Name
		local isGround = name == "Ground" or string.find(string.lower(name), "ground", 1, true) ~= nil
		if isGround then
			bestGroundY = hitY
			break
		end
		if hitY <= maxFloor then
			bestGroundY = hitY
			break
		end
		table.insert(ignore, hit.Instance)
	end
	if bestGroundY then
		return math.clamp(bestGroundY + standOffset, laneY - 2, laneY + 5)
	end
	if typeof(fallbackY) == "number" then
		return math.clamp(fallbackY, laneY - 2, laneY + 5)
	end
	return laneY + 3
end

F.tweenTo = function(targetX, _laneY, laneZ)
	local root = F.getRoot()
	if not root then
		return false
	end
	local humanoid = F.getHumanoid()
	if humanoid then
		humanoid.Sit = false
		humanoid.PlatformStand = true
	end
	local targetGroundY = F.groundedY(targetX, laneZ, root.Position.Y)
	local targetCFrame = CFrame.new(targetX, targetGroundY, laneZ)
	local dist = (root.Position - targetCFrame.Position).Magnitude
	if dist < 1 then
		root.CFrame = targetCFrame
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
		if humanoid then
			humanoid.PlatformStand = false
			pcall(function()
				humanoid:ChangeState(Enum.HumanoidStateType.Running)
			end)
		end
		return true
	end
	local speed = math.clamp(tonumber(F.optionValue("StealSpeed", MOVE_SPEED)) or MOVE_SPEED, 50, 1000)
	local duration = math.max(0.04, dist / speed)
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	local tween = TweenService:Create(root, TweenInfo.new(duration, Enum.EasingStyle.Linear), { CFrame = targetCFrame })
	tween:Play()
	tween.Completed:Wait()
	root.CFrame = targetCFrame
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	if humanoid then
		humanoid.PlatformStand = false
		pcall(function()
			humanoid:ChangeState(Enum.HumanoidStateType.Running)
		end)
	end
	return true
end

F.stealingEnabled = function()
	return F.isOn("AutoStealSelected") or F.isOn("AutoStealAll") or F.isOn("StealBigEggs")
end

F.stealEgg = function(record)
	F.swapStealHumanoid()
	local eggPos = F.getSlotEggPosition(record)
	local root = F.getRoot()
	if not root then
		return false
	end
	local homeX = root.Position.X
	local homeZ = root.Position.Z
	local mid = STEAL_SETTINGS.CorridorMidpoint
	local homeY = F.groundedY(homeX, homeZ, root.Position.Y)

	F.tweenTo(mid.X, nil, mid.Z)
	if not F.stealingEnabled() then
		return false
	end

	F.tweenTo(eggPos.X, nil, eggPos.Z)
	root = F.getRoot()
	if root then
		local eggY = F.groundedY(eggPos.X, eggPos.Z, eggPos.Y)
		root.CFrame = CFrame.new(eggPos.X, eggY, eggPos.Z)
		root.AssemblyLinearVelocity = Vector3.zero
	end
	if not F.stealingEnabled() then
		return false
	end

	local startTime = tick()
	while (tick() - startTime) < STEAL_SETTINGS.GrabDelay and F.stealingEnabled() do
		F.tryCarryEgg(record)
		if F.isCarrying() then
			task.wait(0.08)
			break
		end
		task.wait(0.04)
	end

	F.tweenTo(mid.X, nil, mid.Z)
	F.tweenTo(homeX, nil, homeZ)
	root = F.getRoot()
	if root then
		root.CFrame = CFrame.new(homeX, homeY, homeZ)
		root.AssemblyLinearVelocity = Vector3.zero
	end
	task.wait(STEAL_SETTINGS.ReturnPace)

	return F.isCarrying()
end

local stealBusy = false

F.stealBlockedByInventory = function()
	return F.eggInventoryFull()
end

F.runAutoSteal = function()
	if F.isCarrying() or F.stealBlockedByInventory() then
		return
	end
	local target = F.pickStealTarget()
	if not target then
		return
	end
	return F.stealEgg(target)
end

F.buildLaneWaypoints = function(fromPos, targetIndex)
	local waypoints = {}
	local laneZ = F.getLaneZ()
	local laneY = F.getLaneY()
	if math.abs(fromPos.Z - laneZ) > 8 then
		table.insert(waypoints, Vector3.new(fromPos.X, laneY, laneZ))
	end
	return waypoints
end

F.returnToBase = function(shouldContinue)
	local base = F.getBasePosition()
	local root = F.getRoot()
	if not base or not root then
		return false
	end
	if shouldContinue and not shouldContinue() then
		return false
	end
	local eggZ = root.Position.Z
	F.rawTeleport(Vector3.new(558, 71, eggZ))
	task.wait(RETURN_PACE)
	if shouldContinue and not shouldContinue() then
		return false
	end
	F.rawTeleport(Vector3.new(546, 71, eggZ))
	task.wait(RETURN_PACE)
	if shouldContinue and not shouldContinue() then
		return false
	end
	F.rawTeleport(Vector3.new(base.X, base.Y + 5, base.Z))
	task.wait(0.12)
	return true
end

F.runAutoReturn = function()
	if not F.isCarrying() then
		return
	end
	F.returnToBase(function()
		return F.isOn("AutoReturn") and F.isCarrying()
	end)
	local root = F.getRoot()
	if root and PlotCmds.IsWorldPositionWithinLocalPlotBounds(root.Position) then
		local deadline = os.clock() + 4
		while os.clock() < deadline and F.isCarrying() and F.isOn("AutoReturn") do
			task.wait(0.15)
		end
	end
end

F.runAutoDropEgg = function()
	if not F.isCarrying() then
		return
	end
	pcall(function()
		EggCmds.RequestDropHeldAreaEgg()
	end)
end

local hopDryStart = 0
local hopSessionStart = os.clock()
local hopping = false

F.hasMatchingEgg = function()
	return F.pickStealTarget() ~= nil
end

local hopBlacklist = {}
local hopFailedReason = nil
local hopCooldownUntil = 0

if getgenv then
	local history = getgenv().VoidHubStealAnEggHopHistory
	if typeof(history) ~= "table" then
		history = {}
		getgenv().VoidHubStealAnEggHopHistory = history
	end
	hopBlacklist = history
end

F.rememberVisited = function(jobId)
	if typeof(jobId) ~= "string" or jobId == "" then
		return
	end
	local count = 0
	for _ in pairs(hopBlacklist) do
		count += 1
	end
	if count >= 300 then
		table.clear(hopBlacklist)
	end
	hopBlacklist[jobId] = true
end

F.rememberVisited(tostring(game.JobId))

local hopFailConnection = TeleportService.TeleportInitFailed:Connect(function(player, result, message)
	if player ~= LocalPlayer then
		return
	end
	hopFailedReason = tostring(message or result)
end)

F.fetchServerPage = function(cursor)
	local url = string.format(
		"https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&excludeFullGames=true&limit=100",
		game.PlaceId
	)
	if cursor then
		url = url .. "&cursor=" .. cursor
	end
	local ok, body = pcall(function()
		return game:HttpGet(url)
	end)
	if not ok or typeof(body) ~= "string" then
		return nil
	end
	local decoded, data = pcall(function()
		return HttpService:JSONDecode(body)
	end)
	if not decoded or typeof(data) ~= "table" or typeof(data.data) ~= "table" then
		return nil
	end
	return data
end

F.pickHopTargets = function()
	local candidates = {}
	local cursor = nil
	for _ = 1, 4 do
		local data = F.fetchServerPage(cursor)
		if not data then
			break
		end
		for _, server in ipairs(data.data) do
			if typeof(server) == "table" and typeof(server.id) == "string" and server.id ~= game.JobId and not hopBlacklist[server.id] then
				local playing = tonumber(server.playing) or 0
				local capacity = tonumber(server.maxPlayers) or 0
				if capacity <= 0 or playing < capacity then
					table.insert(candidates, { id = server.id, playing = playing })
				end
			end
		end
		cursor = typeof(data.nextPageCursor) == "string" and data.nextPageCursor or nil
		if not cursor or #candidates >= 40 then
			break
		end
		task.wait(0.25)
	end
	if #candidates == 0 then
		return candidates
	end
	table.sort(candidates, function(a, b)
		return a.playing < b.playing
	end)
	return candidates
end

F.tryTeleportTo = function(jobId)
	hopFailedReason = nil
	local ok = pcall(function()
		TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, LocalPlayer)
	end)
	if not ok then
		return false
	end
	local deadline = os.clock() + 20
	while os.clock() < deadline do
		if hopFailedReason then
			return false
		end
		if Unloaded then
			return true
		end
		task.wait(0.25)
	end
	return true
end

F.serverHop = function(reason)
	if hopping or os.clock() < hopCooldownUntil then
		return false
	end
	hopping = true
	local candidates = F.pickHopTargets()
	if typeof(candidates) ~= "table" or #candidates == 0 then
		hopCooldownUntil = os.clock() + 30
		hopping = false
		F.notify("Server hop found no candidates, retrying in 30s")
		return false
	end
	F.notify(string.format("Server hopping: %s", tostring(reason or "requested")))
	if F.isOn("WebhookEnabled") then
		F.sendSummary()
		task.wait(0.6)
	end
	for round = 1, 3 do
		if round > 1 then
			candidates = F.pickHopTargets()
			if typeof(candidates) ~= "table" or #candidates == 0 then
				break
			end
		end
		for index = 1, math.min(#candidates, 10) do
			if Unloaded then
				hopping = false
				return false
			end
			local pick = candidates[index]
			F.rememberVisited(pick.id)
			if F.tryTeleportTo(pick.id) then
				hopping = false
				return true
			end
			task.wait(0.5)
		end
	end
	hopCooldownUntil = os.clock() + 10
	hopping = false
	F.notify("Server hop failed, retrying in 10s")
	return false
end

F.runServerHop = function()
	if F.isCarrying() or hopping then
		return
	end
	local mode = F.optionValue("HopMode", HOP_MODES[1])
	local value = tonumber(F.optionValue("HopValue", 15)) or 15
	local now = os.clock()
	if mode == "Timed Interval" then
		if now - hopSessionStart >= value * 60 then
			F.serverHop("Interval reached")
		end
		return
	end
	if mode == "After Steal Count" then
		if hopStealCount >= value then
			F.serverHop(string.format("Stole %d eggs", hopStealCount))
		end
		return
	end
	if F.hasMatchingEgg() then
		hopDryStart = 0
		return
	end
	if hopDryStart == 0 then
		hopDryStart = now
		return
	end
	if now - hopDryStart >= value then
		hopDryStart = 0
		F.serverHop("No matching eggs in this server")
	end
end

local lastEquipBest = 0

F.runAutoEquipBest = function()
	local now = Workspace:GetServerTimeNow()
	if now - lastEquipBest < 5 then
		return
	end
	lastEquipBest = now
	F.netCall(NET.Backpack.EQUIP_BEST)
end

F.runAutoUpgrades = function()
	local selected = F.multiSelected("UpgradeTypes")
	if not F.multiHasAny("UpgradeTypes") then
		selected = { Base = true, Treadmill = true }
	end
	local data = F.getSave()
	if not data then
		return
	end
	if selected.Base then
		if BaseUpgradeClient.IsNextTierAffordable(data) then
			F.netCall(NET.Plots.REQUEST_BASE_UPGRADE)
			task.wait(0.35)
		end
	end
	if selected.Treadmill then
		local level = tonumber(data.TreadmillUpgradeLevel) or 0
		local nextConfig = Treadmills.GetByUpgradeLevel(level + 1)
		if nextConfig and data.Money >= (tonumber(nextConfig.Price) or math.huge) then
			F.netCall(NET.Treadmills.REQUEST_UPGRADE, nextConfig._id)
			task.wait(0.35)
		end
	end
end

F.runAutoClaimIndex = function()
	F.netCall(NET.Index.REQUEST_CLAIM_ALL)
end

F.runAutoOpenReadyEggs = function()
	local data = F.getSave()
	local inventory = data and data.EggInventory
	if typeof(inventory) ~= "table" then
		return
	end
	local hatchedAny = false
	for uid, record in pairs(inventory) do
		if Unloaded or not F.isOn("AutoOpenReadyEggs") then
			return hatchedAny
		end
		if typeof(uid) == "string" and typeof(record) == "table" and record.Placement ~= nil then
			if F.matchesEggFilters(record, nil, "LifecycleRarities", "LifecycleMutations") then
				local ready = false
				pcall(function()
					ready = EggCmds.IsLocalEggReady(uid) == true
				end)
				if ready then
					local hatched = false
					pcall(function()
						hatched = EggCmds.RequestHatchEgg(uid) == true
					end)
					if hatched then
						hatchedAny = true
						pcall(function()
							EggCmds.RequestCompleteHatchEgg(uid)
						end)
						task.wait(0.35)
					end
				end
			end
		end
	end
	return hatchedAny
end

local placeSlotIndex = 1
local plotFullUntil = 0

F.isPlotFull = function()
	return os.clock() < plotFullUntil
end

F.markPlotFull = function()
	if F.isPlotFull() then
		return
	end
	plotFullUntil = os.clock() + 30
	F.notify("Farm has no free egg spots left")
end

F.getPetAreaStandPosition = function()
	local plot = PlotCmds.GetPlotData()
	if plot and plot.PetArea then
		return plot.PetArea.Position + Vector3.new(0, 4, 0)
	end
	return F.getBasePosition()
end

F.isNearPlot = function()
	local root = F.getRoot()
	if not root then
		return false
	end
	if PlotCmds.IsWorldPositionWithinLocalPlotBounds(root.Position) then
		return true
	end
	local stand = F.getPetAreaStandPosition()
	return stand ~= nil and (root.Position - stand).Magnitude <= 30
end

F.ensureAtPlot = function(shouldContinue)
	if shouldContinue and not shouldContinue() then
		return false
	end
	if F.isNearPlot() then
		return true
	end
	local stand = F.getPetAreaStandPosition()
	if not stand then
		return false
	end
	return F.travelTo(stand, true)
end

F.getPlacementLocalCFrames = function()
	local plot = PlotCmds.GetPlotData()
	if not plot or not plot.PetArea or not plot.CenterPoint then
		return {}
	end
	local petArea = plot.PetArea
	local center = plot.CenterPoint
	local size = petArea.Size
	local frames = {}
	local step = 7
	for x = -size.X * 0.5 + 5, size.X * 0.5 - 5, step do
		for z = -size.Z * 0.5 + 5, size.Z * 0.5 - 5, step do
			local world = petArea.CFrame:PointToWorldSpace(Vector3.new(x, 1, z))
			table.insert(frames, center.CFrame:ToObjectSpace(CFrame.new(world)))
		end
	end
	return frames
end

F.placingEnabled = function()
	return F.isOn("AutoPlaceSelected") or F.isOn("AutoPlaceAll")
end

F.getUnplacedEggUids = function()
	local data = F.getSave()
	local inventory = data and data.EggInventory
	local list = {}
	if typeof(inventory) ~= "table" then
		return list
	end
	local ignoreFilters = F.isOn("AutoPlaceAll") and not F.isOn("AutoPlaceSelected")
	for uid, egg in pairs(inventory) do
		if typeof(uid) == "string" and typeof(egg) == "table" and egg.Placement == nil then
			if ignoreFilters or F.matchesEggFilters(egg, nil, "LifecycleRarities", "LifecycleMutations") then
				table.insert(list, uid)
			end
		end
	end
	return list
end

F.runAutoPlaceEggs = function(force)
	if F.isCarrying() then
		return
	end
	local function canPlace()
		return (force == true or F.placingEnabled()) and not F.isCarrying()
	end
	local unplaced = F.getUnplacedEggUids()
	if #unplaced == 0 then
		return
	end
	if not F.ensureAtPlot(canPlace) then
		return
	end
	local slots = F.getPlacementLocalCFrames()
	if #slots == 0 then
		return
	end
	local placedAny = false
	for _, uid in ipairs(unplaced) do
		if Unloaded or not canPlace() then
			return placedAny
		end
		if not F.isNearPlot() and not F.ensureAtPlot(canPlace) then
			return placedAny
		end
		pcall(function()
			EggCmds.RequestEquipTool(uid)
		end)
		task.wait(0.15)
		local placed = false
		for offset = 0, #slots - 1 do
			local index = ((placeSlotIndex + offset - 1) % #slots) + 1
			local success = false
			pcall(function()
				success = EggCmds.RequestPlaceEgg(uid, slots[index]) == true
			end)
			if success then
				placeSlotIndex = index + 1
				placed = true
				placedAny = true
				task.wait(0.25)
				break
			end
		end
		if not placed then
			F.markPlotFull()
			return placedAny
		end
		plotFullUntil = 0
	end
	return placedAny
end

F.getPetItemData = function(record)
	local ok, itemData = pcall(AssetItemSerialization.Deserialize, record)
	if not ok or typeof(itemData) ~= "table" then
		return nil
	end
	return itemData
end

F.getSellablePets = function()
	local data = F.getSave()
	local inventory = data and data.Inventory
	local list = {}
	if typeof(inventory) ~= "table" then
		return list
	end
	local equipped = data.EquippedAssets or {}
	local maxScale = tonumber(F.optionValue("SellMaxScale", 10)) or 10
	local keepMutated = F.isOn("SellKeepMutated")
	local keepEquipped = F.isOn("SellKeepEquipped")
	for uid, record in pairs(inventory) do
		if typeof(uid) == "string" and typeof(record) == "table" then
			local itemData = F.getPetItemData(record)
			local isEquipped = table.find(equipped, uid) ~= nil
			if itemData and itemData.IsFavorite ~= true and itemData.InFuse ~= true and not (keepEquipped and isEquipped) then
				local mutations = {}
				if typeof(record.Mutations) == "table" then
					for _, mutation in pairs(record.Mutations) do
						if typeof(mutation) == "string" then
							table.insert(mutations, mutation)
						end
					end
				end
				if typeof(record.BaseMutation) == "string" then
					table.insert(mutations, record.BaseMutation)
				end
				local blockedByMutation = keepMutated and #mutations > 0
				local mutationAllowed = true
				if not blockedByMutation and F.multiHasAny("SellMutations") then
					mutationAllowed = false
					local wanted = F.multiSelected("SellMutations")
					for _, mutation in ipairs(mutations) do
						if wanted[mutation] then
							mutationAllowed = true
							break
						end
					end
				end
				local scale = tonumber(record.Scale) or 0
				local rarity = F.resolveRarity(record.Category)
				local rarityAllowed
				if F.multiHasAny("SellRarities") then
					rarityAllowed = typeof(rarity) == "string" and F.multiSelected("SellRarities")[rarity] == true
				else
					rarityAllowed = true
				end
				if not blockedByMutation
					and mutationAllowed
					and scale <= maxScale
					and rarityAllowed
				then
					table.insert(list, uid)
				end
			end
		end
	end
	return list
end

F.getSellableEggUids = function()
	local data = F.getSave()
	local inventory = data and data.EggInventory
	local list = {}
	if typeof(inventory) ~= "table" then
		return list
	end
	for uid, record in pairs(inventory) do
		if typeof(uid) == "string" and typeof(record) == "table" and record.Placement == nil then
			local rarity = F.resolveRarity(record.AssetCategory)
			local allowed
			if F.multiHasAny("SellEggRarities") then
				allowed = typeof(rarity) == "string" and F.multiSelected("SellEggRarities")[rarity] == true
			else
				allowed = true
			end
			if allowed then
				table.insert(list, uid)
			end
		end
	end
	return list
end

F.findToolByUid = function(uid)
	local containers = { LocalPlayer.Character, LocalPlayer:FindFirstChildOfClass("Backpack") }
	for _, container in ipairs(containers) do
		if container then
			for _, tool in ipairs(container:GetChildren()) do
				if tool:IsA("Tool") and tool:GetAttribute("UID") == uid then
					return tool
				end
			end
		end
	end
	return nil
end

F.holdUid = function(uid)
	local character = LocalPlayer.Character
	local humanoid = F.getHumanoid()
	if not character or not humanoid then
		return false
	end
	local tool = F.findToolByUid(uid)
	if not tool then
		return false
	end
	if tool.Parent == character then
		return true
	end
	pcall(function()
		humanoid:EquipTool(tool)
	end)
	local deadline = os.clock() + 1
	while os.clock() < deadline do
		if tool.Parent == LocalPlayer.Character then
			return true
		end
		task.wait(0.05)
	end
	return false
end

F.sellUid = function(uid)
	if not F.holdUid(uid) then
		return false
	end
	F.netCall(NET.AssetInventory.SELL_ASSET, uid)
	local deadline = os.clock() + 2
	while os.clock() < deadline do
		local data = F.getSave()
		local inventory = data and (data.Inventory or {})
		local eggs = data and (data.EggInventory or {})
		if data and inventory[uid] == nil and eggs[uid] == nil then
			return true
		end
		task.wait(0.1)
	end
	return false
end

F.runAutoSellEggs = function()
	for _, uid in ipairs(F.getSellableEggUids()) do
		if Unloaded or not F.isOn("AutoSellEggs") or F.isCarrying() then
			return
		end
		pcall(function()
			EggCmds.RequestEquipTool(uid)
		end)
		task.wait(0.15)
		F.sellUid(uid)
		task.wait(0.15)
	end
end

F.runAutoSellPets = function()
	for _, uid in ipairs(F.getSellablePets()) do
		if Unloaded or not F.isOn("AutoSellPets") or F.isCarrying() then
			return
		end
		F.sellUid(uid)
		task.wait(0.15)
	end
end

F.runClaimOfflineEarnings = function()
	local summary = F.netInvoke(NET.OfflineAssets.GET_SUMMARY)
	if typeof(summary) ~= "table" then
		return
	end
	if (tonumber(summary.ClaimableAmount) or 0) <= 0 then
		return
	end
	F.netCall(NET.OfflineAssets.REQUEST_REDEEM)
end

F.isOwnRenderedPet = function(model)
	return model:GetAttribute("OwnerUserId") == LocalPlayer.UserId
end

F.deleteOwnPetRenders = function()
	local renders = Workspace:FindFirstChild("ClientRenderedAssets")
	if not renders then
		return
	end
	for _, model in ipairs(renders:GetChildren()) do
		if F.isOwnRenderedPet(model) then
			pcall(function()
				model:Destroy()
			end)
		end
	end
end

F.getFuseMachinePosition = function()
	local machines = Workspace:FindFirstChild("__OBJECTS")
	machines = machines and machines:FindFirstChild("Machines")
	local model = machines and machines:FindFirstChild("FuseMachine")
	if not model then
		return nil
	end
	local ok, cf = pcall(function()
		return model:GetPivot()
	end)
	if ok and cf then
		return cf.Position + Vector3.new(0, 4, 0)
	end
	return nil
end

F.fuseGroups = function(data)
	local inventory = data and data.Inventory
	local groups = {}
	if typeof(inventory) ~= "table" then
		return groups
	end
	local equipped = data.EquippedAssets or {}
	local keepEquipped = F.isOn("FuseKeepEquipped")
	local keepMutated = F.isOn("FuseKeepMutated")
	local maxScale = tonumber(F.optionValue("FuseMaxScale", 10)) or 10
	for uid, record in pairs(inventory) do
		if typeof(uid) == "string" and typeof(record) == "table" then
			local category = record.Category
			local canSelect = false
			if typeof(category) == "string" then
				pcall(function()
					canSelect = FuseKernelUtil.CanSelectPet(uid, record, category, false) == true
				end)
			end
			if canSelect and not (keepEquipped and table.find(equipped, uid) ~= nil) then
				local mutations = F.recordMutations(record)
				local mutationAllowed = not (keepMutated and #mutations > 0)
				if mutationAllowed and F.multiHasAny("FuseMutations") then
					mutationAllowed = false
					local wanted = F.multiSelected("FuseMutations")
					for _, mutation in ipairs(mutations) do
						if wanted[mutation] then
							mutationAllowed = true
							break
						end
					end
				end
				local rarity = F.resolveRarity(category)
				local scale = tonumber(record.Scale) or 0
				if mutationAllowed
					and scale <= maxScale
					and (rarity == nil or F.selectionAllows("FuseRarities", rarity))
				then
					local bucket = groups[category]
					if not bucket then
						bucket = {}
						groups[category] = bucket
					end
					table.insert(bucket, { uid = uid, scale = scale })
				end
			end
		end
	end
	return groups
end

F.pickFuseGroup = function(data)
	local groups = F.fuseGroups(data)
	local keep = math.floor(tonumber(F.optionValue("FuseKeepPerCategory", 0)) or 0)
	local mode = F.optionValue("FuseTarget", "Highest Rarity")
	local bestCategory = nil
	local bestScore = -math.huge
	for category, bucket in pairs(groups) do
		table.sort(bucket, function(a, b)
			return a.scale < b.scale
		end)
		if #bucket - keep >= 3 then
			local rank = RARITY_RANK[F.resolveRarity(category) or "Common"] or 0
			local score
			if mode == "Most Duplicates" then
				score = #bucket
			elseif mode == "Lowest Rarity" then
				score = -rank
			else
				score = rank
			end
			if score > bestScore then
				bestScore = score
				bestCategory = category
			end
		end
	end
	if not bestCategory then
		return nil
	end
	local picked = {}
	for index = 1, 3 do
		picked[index] = groups[bestCategory][index].uid
	end
	return picked
end

F.fusePrice = function(data, uids)
	local inventory = data and data.Inventory
	if typeof(inventory) ~= "table" then
		return nil
	end
	local items = {}
	for index, uid in ipairs(uids) do
		local itemData = inventory[uid] and F.getPetItemData(inventory[uid])
		if not itemData then
			return nil
		end
		items[index] = itemData
	end
	local ok, price = pcall(FuseKernelUtil.CalculateFusePrice, items)
	if not ok then
		return nil
	end
	return tonumber(price)
end

F.runAutoFusePets = function(force)
	local data = F.getSave()
	if not data then
		return
	end
	local function fusingEnabled()
		return force == true or F.isOn("AutoFusePets")
	end
	if data.FusionLocked == true then
		if F.isOn("FuseAutoReveal") or force == true then
			F.netInvoke(NET.FuseMachine.COMPLETE_REVEAL)
		end
		return
	end
	local picked = F.pickFuseGroup(data)
	if not picked then
		return
	end
	local price = F.fusePrice(data, picked)
	if price and (tonumber(data.Money) or 0) < price then
		return
	end
	local machine = F.getFuseMachinePosition()
	if machine and not F.travelTo(machine, true) then
		return
	end
	if data.FusionInfoAcknowledged ~= true then
		F.netInvoke(NET.FuseMachine.ACKNOWLEDGE_INFO)
	end
	for _, uid in ipairs(picked) do
		if Unloaded or not fusingEnabled() then
			return
		end
		F.netInvoke(NET.FuseMachine.INSERT_MOB, uid)
		task.wait(0.2)
	end
	F.netInvoke(NET.FuseMachine.START_FUSE)
	return true
end

F.runAutoBuyTrail = function()
	local data = F.getSave()
	if not data then
		return
	end
	local selected = F.multiSelected("TrailWanted")
	if not F.multiHasAny("TrailWanted") then
		return
	end
	local inventory = data.TrailInventory or {}
	for _, name in ipairs(TRAIL_VALUES) do
		if selected[name] then
			local id = TRAIL_ID_BY_NAME[name]
			if id and not inventory[id] then
				local price = TRAIL_PRICE_BY_NAME[name] or 0
				if data.Money >= price then
					F.netCall(NET.Trails.REQUEST_PURCHASE, id)
					task.wait(0.35)
					data = F.getSave() or data
					inventory = data.TrailInventory or inventory
				end
			end
		end
	end
end

local WAYPOINT_VALUES = { "Base", "Pet Area", "Treadmill", "Fuse Machine", "Lobby Entry" }
for _, zone in ipairs(ZONE_ORDER) do
	table.insert(WAYPOINT_VALUES, zone)
end

F.resolveWaypoint = function(name)
	if typeof(name) ~= "string" then
		return nil
	end
	if name == "Base" then
		return F.getBasePosition()
	elseif name == "Pet Area" then
		local plot = PlotCmds.GetPlotData()
		return plot and plot.PetArea and (plot.PetArea.Position + Vector3.new(0, 4, 0)) or nil
	elseif name == "Treadmill" then
		local plot = PlotCmds.GetPlotData()
		local bottom = plot and plot.PlotFolder and plot.PlotFolder:FindFirstChild("TreadmillBottom")
		return (bottom and bottom:IsA("BasePart")) and (bottom.Position + Vector3.new(0, 4, 0)) or nil
	elseif name == "Fuse Machine" then
		local objects = Workspace:FindFirstChild("__OBJECTS")
		local machines = objects and objects:FindFirstChild("Machines")
		local model = machines and machines:FindFirstChild("FuseMachine")
		if not model then
			return nil
		end
		local ok, cf = pcall(function()
			return model:GetPivot()
		end)
		return ok and cf and (cf.Position + Vector3.new(0, 4, 0)) or nil
	elseif name == "Lobby Entry" then
		return F.getEntryPosition()
	end
	return F.getZoneLaneCenter(name)
end

F.getTreadmillStand = function()
	local plot = PlotCmds.GetPlotData()
	local folder = plot and plot.PlotFolder
	local bottom = folder and folder:FindFirstChild("TreadmillBottom")
	if bottom and bottom:IsA("BasePart") then
		return bottom.Position + Vector3.new(0, 4, 0)
	end
	return nil
end

local treadmillActive = false

F.isDoubleSpeedVisible = function()
	local ok, visible = pcall(function()
		local pGui = LocalPlayer:FindFirstChild("PlayerGui")
		local elem = pGui and pGui:FindFirstChild("Elements")
		local left = elem and elem:FindFirstChild("Left")
		local tools = left and left:FindFirstChild("Tools")
		local doubleSpeed = tools and tools:FindFirstChild("DoubleYourSpeed")
		return doubleSpeed ~= nil and doubleSpeed.Visible == true
	end)
	return ok and visible == true
end

F.dismountTreadmill = function()
	pcall(function()
		local VIM = game:GetService("VirtualInputManager")
		VIM:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
		task.wait(0.05)
		VIM:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
	end)
	local humanoid = F.getHumanoid()
	if humanoid then
		humanoid.Jump = true
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end

F.runAutoTreadmillTraining = function()
	local stand = F.getTreadmillStand()
	if not stand then
		return
	end
	local root = F.getRoot()
	if not root then
		return
	end
	if (root.Position - stand).Magnitude > 12 and not F.travelTo(stand, true) then
		return
	end
	F.netInvoke(NET.Treadmills.REQUEST_EQUIP_STATIC)
	treadmillActive = true
	return true
end

F.stopTreadmillTraining = function()
	treadmillActive = false
	pcall(function()
		F.netInvoke(NET.Treadmills.REQUEST_UNEQUIP)
	end)
	if F.isDoubleSpeedVisible() then
		F.dismountTreadmill()
		task.wait(0.1)
		if F.isDoubleSpeedVisible() then
			F.dismountTreadmill()
		end
	end
end

F.runAutoEquipBestTrail = function()
	local data = F.getSave()
	local inventory = data and data.TrailInventory
	if typeof(inventory) ~= "table" then
		return
	end
	local bestId = nil
	local bestPrice = -1
	for _, name in ipairs(TRAIL_VALUES) do
		local id = TRAIL_ID_BY_NAME[name]
		if id and inventory[id] then
			local price = TRAIL_PRICE_BY_NAME[name] or 0
			if price > bestPrice then
				bestPrice = price
				bestId = id
			end
		end
	end
	local worn = F.netInvoke(NET.Trails.WORN_SNAPSHOT)
	local equipped = typeof(worn) == "table" and worn[tostring(LocalPlayer.UserId)]
	if not bestId or equipped == bestId then
		return
	end
	F.netInvoke(NET.Trails.REQUEST_SELECT, bestId)
end

F.gearBaseName = function(toolName)
	return (tostring(toolName):gsub("%s*%[X%d+%]%s*$", ""))
end

F.runAutoEquipBestGear = function()
	local character = LocalPlayer.Character
	local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
	local humanoid = F.getHumanoid()
	if not character or not backpack or not humanoid then
		return
	end
	local best = nil
	local bestCost = -1
	for _, tool in ipairs(backpack:GetChildren()) do
		if tool:IsA("Tool") then
			local cost = GEAR_COST_BY_NAME[F.gearBaseName(tool.Name)]
			if cost and cost > bestCost then
				bestCost = cost
				best = tool
			end
		end
	end
	for _, tool in ipairs(character:GetChildren()) do
		if tool:IsA("Tool") then
			local cost = GEAR_COST_BY_NAME[F.gearBaseName(tool.Name)]
			if cost and cost >= bestCost then
				return
			end
		end
	end
	if best then
		pcall(function()
			humanoid:EquipTool(best)
		end)
	end
end

F.runAutoClaimGroupReward = function()
	local data = F.getSave()
	if data and data.ClaimedGroupReward == true then
		return
	end
	local inGroup = false
	pcall(function()
		inGroup = LocalPlayer:IsInGroupAsync(Constants.GROUP_ID) == true
	end)
	F.netInvoke(NET.GroupReward.CLAIM_REWARD, inGroup)
end

F.formatNumber = function(value)
	local number = tonumber(value) or 0
	local suffixes = { "", "K", "M", "B", "T", "Qa", "Qi" }
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

F.formatElapsed = function(seconds)
	local total = math.max(0, math.floor(seconds))
	local hours = math.floor(total / 3600)
	local minutes = math.floor((total % 3600) / 60)
	if hours > 0 then
		return string.format("%dh %dm", hours, minutes)
	end
	return string.format("%dm", minutes)
end

F.formatClock = function(seconds)
	local elapsed = math.floor(seconds)
	if elapsed < 60 then
		return elapsed .. "s"
	elseif elapsed < 3600 then
		return string.format("%dm %ds", elapsed // 60, elapsed % 60)
	end
	return string.format("%dh %dm", elapsed // 3600, (elapsed % 3600) // 60)
end

local espFolder = Instance.new("Folder")
espFolder.Name = "VoidHubEsp"
espFolder.Parent = Workspace

local espObjects = {}
local espSeen = {}

F.releaseEsp = function(key)
	local entry = espObjects[key]
	if not entry then
		return
	end
	if entry.highlight then
		entry.highlight:Destroy()
	end
	if entry.billboard then
		entry.billboard:Destroy()
	end
	if entry.anchor then
		entry.anchor:Destroy()
	end
	espObjects[key] = nil
end

F.espColorFor = function(rarity)
	local rank = RARITY_RANK[rarity or ""] or 0
	local total = #RARITY_VALUES
	if total <= 0 then
		total = 10
	end
	local position = rank / total
	if position >= 0.9 then
		return Color3.fromRGB(255, 120, 255)
	elseif position >= 0.7 then
		return Color3.fromRGB(255, 90, 90)
	elseif position >= 0.5 then
		return Color3.fromRGB(255, 190, 80)
	elseif position >= 0.3 then
		return Color3.fromRGB(110, 195, 255)
	end
	return Color3.fromRGB(190, 200, 215)
end

F.ensureEspEntry = function(key, color)
	local entry = espObjects[key]
	if entry then
		return entry
	end
	local anchor = Instance.new("Part")
	anchor.Name = "EspAnchor"
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.Parent = espFolder

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "EspLabel"
	billboard.AlwaysOnTop = true
	billboard.Size = UDim2.fromOffset(220, 34)
	billboard.StudsOffset = Vector3.new(0, 2.5, 0)
	billboard.Adornee = anchor
	billboard.Parent = anchor

	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 13
	label.TextStrokeTransparency = 0.4
	label.TextColor3 = color
	label.RichText = false
	label.Parent = billboard

	entry = {
		anchor = anchor,
		billboard = billboard,
		label = label,
		highlight = nil,
	}
	espObjects[key] = entry
	return entry
end

F.drawEspAt = function(key, position, text, color, adornee)
	local entry = F.ensureEspEntry(key, color)
	entry.anchor.CFrame = CFrame.new(position)
	entry.label.Text = text
	entry.label.TextColor3 = color
	if adornee and adornee.Parent then
		if not entry.highlight then
			local highlight = Instance.new("Highlight")
			highlight.FillTransparency = 0.6
			highlight.OutlineTransparency = 0
			highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			highlight.Parent = espFolder
			entry.highlight = highlight
		end
		entry.highlight.Adornee = adornee
		entry.highlight.FillColor = color
		entry.highlight.OutlineColor = color
	elseif entry.highlight then
		entry.highlight:Destroy()
		entry.highlight = nil
	end
	espSeen[key] = true
end

F.espDistanceLimit = function()
	return tonumber(F.optionValue("EspDistance", 2000)) or 2000
end

F.withinEspRange = function(position)
	local root = F.getRoot()
	if not root then
		return false
	end
	return (root.Position - position).Magnitude <= F.espDistanceLimit()
end

F.collectEggEsp = function()
	local worldOn = F.isOn("EspWorldEggs")
	local carriedOn = F.isOn("EspCarriedEggs")
	if not worldOn and not carriedOn then
		return
	end
	for _, record in ipairs(F.getAreaEggs()) do
		local goal = record.BottomCFrame or record.BoundsCFrame
		if goal then
			local state = record.State
			local isWorld = state == "Slot"
			local isLoose = state == "Carried" or state == "Dropped"
			if (isWorld and worldOn) or (isLoose and carriedOn) then
				local position = goal.Position
				if F.withinEspRange(position) then
					local rarity = F.resolveRarity(record.AssetCategory)
					local asset = Assets.Directory[record.AssetCategory or ""]
					local name = (asset and asset.DisplayName) or tostring(record.AssetCategory)
					local text = string.format("%s [%s]", name, tostring(rarity or "?"))
					if isLoose then
						text = string.format("%s\n%s", text, tostring(state))
					end
					F.drawEspAt("egg_" .. record.Uid, position, text, F.espColorFor(rarity), nil)
				end
			end
		end
	end
end

F.collectGuardEsp = function()
	if not F.isOn("EspGuards") then
		return
	end
	for _, zone in ipairs(GuardAreasFolder:GetChildren()) do
		local guard = zone:FindFirstChild("Guard")
		local pivotOk, pivot = pcall(function()
			return guard and guard:GetPivot()
		end)
		if pivotOk and pivot and F.withinEspRange(pivot.Position) then
			local state = guard:GetAttribute("GuardState")
			F.drawEspAt(
				"guard_" .. zone.Name,
				pivot.Position,
				string.format("Guard %s\n%s", zone.Name, tostring(state or "Idle")),
				Color3.fromRGB(255, 140, 90),
				guard
			)
		end
	end
end

F.collectPetEsp = function()
	if not F.isOn("EspPets") then
		return
	end
	local renders = Workspace:FindFirstChild("ClientRenderedAssets")
	if not renders then
		return
	end
	local data = F.getSave()
	local ownInventory = (data and data.Inventory) or {}
	local runtimeRecords = {}
	pcall(function()
		for _, slot in pairs(AssetCmds.GetRuntimeSnapshot() or {}) do
			if typeof(slot) == "table" and typeof(slot.Records) == "table" then
				for uid, record in pairs(slot.Records) do
					runtimeRecords[uid] = record
				end
			end
		end
	end)
	for _, model in ipairs(renders:GetChildren()) do
		local uid = model:GetAttribute("UID")
		local pivotOk, pivot = pcall(function()
			return model:GetPivot()
		end)
		if typeof(uid) == "string" and pivotOk and pivot and F.withinEspRange(pivot.Position) then
			local category = nil
			local earnings = nil
			local owned = ownInventory[uid]
			if typeof(owned) == "table" then
				category = owned.Category
			end
			local runtime = runtimeRecords[uid]
			if typeof(runtime) == "table" then
				category = category or (runtime.ItemData and runtime.ItemData.Category)
				earnings = tonumber(runtime.MoneyPerSecond)
			end
			local asset = Assets.Directory[category or ""]
			local rarity = F.resolveRarity(category)
			local text = string.format(
				"%s [%s]",
				(asset and asset.DisplayName) or tostring(category or "Pet"),
				tostring(rarity or "?")
			)
			if earnings then
				text = string.format("%s\n%s/s", text, F.formatNumber(earnings))
			end
			F.drawEspAt("pet_" .. model.Name, pivot.Position, text, F.espColorFor(rarity), model)
		end
	end
end

F.collectPlayerEsp = function()
	if not F.isOn("EspPlayers") then
		return
	end
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root and F.withinEspRange(root.Position) then
				F.drawEspAt(
					"player_" .. player.Name,
					root.Position,
					string.format("%s\n%d studs", player.DisplayName, math.floor((F.getRoot() and (F.getRoot().Position - root.Position).Magnitude) or 0)),
					Color3.fromRGB(120, 190, 255),
					character
				)
			end
		end
	end
end

F.collectMachineEsp = function()
	if not F.isOn("EspMachines") then
		return
	end
	local objects = Workspace:FindFirstChild("__OBJECTS")
	local machines = objects and objects:FindFirstChild("Machines")
	if not machines then
		return
	end
	for _, model in ipairs(machines:GetChildren()) do
		local pivotOk, pivot = pcall(function()
			return model:GetPivot()
		end)
		if pivotOk and pivot and F.withinEspRange(pivot.Position) then
			F.drawEspAt("machine_" .. model.Name, pivot.Position, model.Name, Color3.fromRGB(230, 200, 120), model)
		end
	end
end

F.collectPlotEsp = function()
	if not F.isOn("EspPlots") then
		return
	end
	local plots = Workspace:FindFirstChild("Plots")
	if not plots then
		return
	end
	for _, plot in ipairs(plots:GetChildren()) do
		local sign = plot:FindFirstChild("PlotSign")
		local anchorPart = sign or plot:FindFirstChild("CenterPoint")
		if anchorPart and anchorPart:IsA("BasePart") and F.withinEspRange(anchorPart.Position) then
			local owner = nil
			pcall(function()
				owner = PlotCmds.GetSlotOwner(tonumber(plot.Name))
			end)
			local ownerName = "Empty"
			local ownerUserId = tonumber(owner)
			if ownerUserId then
				local ownerPlayer = Players:GetPlayerByUserId(ownerUserId)
				if ownerPlayer then
					ownerName = ownerPlayer.DisplayName
					if ownerPlayer == LocalPlayer then
						ownerName = ownerName .. " (You)"
					end
				else
					ownerName = "User " .. tostring(ownerUserId)
				end
			end
			F.drawEspAt(
				"plot_" .. plot.Name,
				anchorPart.Position,
				string.format("Plot %s\n%s", plot.Name, ownerName),
				Color3.fromRGB(200, 170, 255),
				nil
			)
		end
	end
end

F.runEsp = function()
	table.clear(espSeen)
	F.collectEggEsp()
	F.collectGuardEsp()
	F.collectPetEsp()
	F.collectPlayerEsp()
	F.collectMachineEsp()
	F.collectPlotEsp()
	for key in pairs(espObjects) do
		if not espSeen[key] then
			F.releaseEsp(key)
		end
	end
end

F.clearAllEsp = function()
	for key in pairs(espObjects) do
		F.releaseEsp(key)
	end
end

F.httpPost = function(payload)
	local sender = (syn and syn.request) or (http and http.request) or http_request or request
	if typeof(sender) ~= "function" then
		return false
	end
	local url = tostring(F.optionValue("WebhookUrl", "") or "")
	if url == "" then
		return false
	end
	local encoded
	local ok = pcall(function()
		encoded = HttpService:JSONEncode(payload)
	end)
	if not ok then
		return false
	end
	local sent = pcall(sender, {
		Url = url,
		Method = "POST",
		Headers = { ["Content-Type"] = "application/json" },
		Body = encoded,
	})
	return sent
end

F.countTable = function(value)
	if typeof(value) ~= "table" then
		return 0
	end
	local total = 0
	for _ in pairs(value) do
		total += 1
	end
	return total
end

local lastSummary = os.clock()
local knownEggUids = {}
local knownPetUids = {}
local watcherPrimed = false
local lastRebirth = nil
local lastStealCount = 0
local sessionSteals = 0
local sessionPets = 0
local sessionRebirths = 0
local spawnLog = {}
local stealLog = {}

F.webhookPing = function()
	local id = tostring(F.optionValue("WebhookPingId", "") or ""):gsub("%D", "")
	if id == "" then
		return nil
	end
	return string.format("<@%s>", id)
end

F.sendWebhookEmbed = function(embed, withPing)
	if not F.isOn("WebhookEnabled") then
		return false
	end
	local payload = {
		username = HUB_NAME,
		embeds = { embed },
	}
	if withPing then
		payload.content = F.webhookPing()
	end
	return F.httpPost(payload)
end

F.embedField = function(name, value, inline)
	return { name = name, value = value, inline = inline ~= false }
end

F.assetName = function(category)
	local asset = Assets.Directory[category or ""]
	return (asset and asset.DisplayName) or tostring(category or "Unknown")
end

F.spawnPassesFilter = function(rarity)
	return F.selectionAllows("WebhookRarities", rarity or "")
end

F.findAreaEggRecord = function(uid)
	for _, record in ipairs(F.getAreaEggs()) do
		if record.Uid == uid then
			return record
		end
	end
	return nil
end

onEggClaimed = function(state)
	if typeof(state) ~= "table" then
		return
	end
	local record = typeof(state.Uid) == "string" and F.findAreaEggRecord(state.Uid) or nil
	local category = (record and record.AssetCategory) or state.AssetCategory
	local parts = {
		string.format("**%s** `%s`", F.assetName(category), tostring(F.resolveRarity(category) or "?")),
	}
	local areaId = (record and record.AreaId) or state.AreaId
	if typeof(areaId) == "string" then
		table.insert(parts, areaId)
	end
	if record then
		local scale = tonumber(record.AssetScale)
		if scale then
			table.insert(parts, string.format("x%.2f", scale))
		end
		local mutations = F.recordMutations(record)
		if #mutations > 0 then
			table.insert(parts, table.concat(mutations, ", "))
		end
	end
	if #stealLog < 100 then
		table.insert(stealLog, table.concat(parts, " | "))
	end
end

F.buildSummaryEmbed = function()
	local data = F.getSave()
	local fields = {}
	if data then
		table.insert(fields, F.embedField("Money", "`" .. F.formatNumber(data.Money) .. "`"))
		table.insert(fields, F.embedField("Speed Power", "`" .. F.formatNumber(data.SpeedPower) .. "`"))
		table.insert(fields, F.embedField("Rebirth", "`" .. tostring(data.Rebirth or 0) .. "`"))
		table.insert(fields, F.embedField("Base Level", "`" .. tostring(data.BaseUpgradeLevel or 0) .. "`"))
		table.insert(fields, F.embedField("Treadmill Level", "`" .. tostring(data.TreadmillUpgradeLevel or 0) .. "`"))
		table.insert(fields, F.embedField("Pets Owned", "`" .. tostring(F.countTable(data.Inventory)) .. "`"))
	end

	local activity = {
		string.format("Eggs stolen: **%d**", sessionSteals),
		string.format("Pets obtained: **%d**", sessionPets),
		string.format("Rebirths: **%d**", sessionRebirths),
	}
	table.insert(fields, F.embedField("Since Last Summary", table.concat(activity, "\n"), false))

	if #stealLog > 0 then
		local lines = {}
		local used = 0
		local shown = 0
		for index = 1, #stealLog do
			local line = stealLog[index]
			if used + #line + 1 > 900 then
				break
			end
			table.insert(lines, line)
			used += #line + 1
			shown += 1
		end
		if shown < #stealLog then
			table.insert(lines, string.format("... and %d more", #stealLog - shown))
		end
		table.insert(fields, F.embedField(string.format("Eggs Obtained (%d)", #stealLog), table.concat(lines, "\n"), false))
	end

	if #spawnLog > 0 then
		local ordered = table.clone(spawnLog)
		table.sort(ordered, function(a, b)
			if a.rank == b.rank then
				return a.order < b.order
			end
			return a.rank > b.rank
		end)
		local lines = {}
		for index = 1, math.min(#ordered, 15) do
			table.insert(lines, ordered[index].text)
		end
		if #spawnLog > 15 then
			table.insert(lines, string.format("... and %d more", #spawnLog - 15))
		end
		table.insert(fields, F.embedField(string.format("Eggs Spawned (%d)", #spawnLog), table.concat(lines, "\n"), false))
	end

	return {
		author = { name = GAME_NAME .. " | " .. HUB_NAME },
		title = "Session Summary",
		description = string.format(
			"**Player** `%s`\n**Server** `%s`\n**Runtime** `%s`",
			LocalPlayer.Name,
			shortJobIdText,
			F.formatElapsed(os.clock() - sessionStart)
		),
		color = 11829247,
		fields = fields,
		footer = { text = HUB_NAME .. " | by von63rd" },
		timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
	}
end

F.sendSummary = function()
	local embed = F.buildSummaryEmbed()
	local sent = F.sendWebhookEmbed(embed, true)
	if sent then
		sessionSteals = 0
		sessionPets = 0
		sessionRebirths = 0
		table.clear(spawnLog)
		table.clear(stealLog)
	end
	return sent
end

F.trackWebhookEvents = function()
	local data = F.getSave()
	if not data then
		return
	end
	if not watcherPrimed then
		watcherPrimed = true
		for uid in pairs(data.Inventory or {}) do
			knownPetUids[uid] = true
		end
		for _, record in ipairs(F.getAreaEggs()) do
			knownEggUids[record.Uid] = true
		end
		lastRebirth = tonumber(data.Rebirth) or 0
		lastStealCount = hopStealCount
		return
	end

	sessionSteals += math.max(0, hopStealCount - lastStealCount)
	lastStealCount = hopStealCount

	for uid in pairs(data.Inventory or {}) do
		if knownPetUids[uid] == nil then
			knownPetUids[uid] = true
			sessionPets += 1
		end
	end

	local rebirth = tonumber(data.Rebirth) or 0
	if lastRebirth and rebirth > lastRebirth then
		sessionRebirths += rebirth - lastRebirth
	end
	lastRebirth = rebirth

	local present = {}
	local logSpawns = F.isOn("WebhookEggSpawns")
	for _, record in ipairs(F.getAreaEggs()) do
		present[record.Uid] = true
		if knownEggUids[record.Uid] == nil then
			knownEggUids[record.Uid] = true
			local rarity = F.resolveRarity(record.AssetCategory)
			if logSpawns and F.spawnPassesFilter(rarity) and #spawnLog < 60 then
				table.insert(spawnLog, {
					rank = RARITY_RANK[rarity or ""] or 0,
					order = #spawnLog,
					text = string.format(
						"**%s** `%s` in %s",
						F.assetName(record.AssetCategory),
						tostring(rarity or "?"),
						tostring(record.AreaId)
					),
				})
			end
		end
	end
	for uid in pairs(knownEggUids) do
		if not present[uid] then
			knownEggUids[uid] = nil
		end
	end
end

F.runWebhookSummary = function()
	local interval = (tonumber(F.optionValue("WebhookInterval", 15)) or 15) * 60
	if os.clock() - lastSummary < interval then
		return
	end
	lastSummary = os.clock()
	F.sendSummary()
end

F.applyAntiGameplayPause = function(enabled)
	pcall(function()
		game:GetService("GuiService"):SetGameplayPausedNotificationEnabled(not enabled)
	end)

	pcall(function()
		local notification = game:GetService("CoreGui"):FindFirstChild("RobloxNetworkPauseNotification")
		if notification then
			notification.Enabled = not enabled
		end
	end)

	if not enabled then
		return
	end

	pcall(function()
		if sethiddenproperty then
			sethiddenproperty(LocalPlayer, "GameplayPaused", false)
		else
			LocalPlayer.GameplayPaused = false
		end
	end)
end

local renderingDisabled = false
local renderOverlay = nil
local renderRows = {}

F.destroyRenderOverlay = function()
	if renderOverlay then
		pcall(function()
			renderOverlay:Destroy()
		end)
	end
	renderOverlay = nil
	table.clear(renderRows)
end

local RENDER_ROWS = {
	"money",
	"speed",
	"pets",
	"eggs",
	"stolen",
	"session",
}

F.buildRenderOverlay = function()
	if renderOverlay and renderOverlay.Parent then
		return
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = "VoidHubRenderInfo"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 500
	gui.Parent = (gethui and gethui()) or game:GetService("CoreGui")

	local backdrop = Instance.new("Frame")
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
	backdrop.BorderSizePixel = 0
	backdrop.Parent = gui

	local title = Instance.new("TextLabel")
	title.AnchorPoint = Vector2.new(0.5, 1)
	title.Position = UDim2.fromScale(0.5, 0.5)
	title.Size = UDim2.fromOffset(400, 30)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamMedium
	title.TextSize = 24
	title.TextColor3 = Color3.fromRGB(226, 230, 238)
	title.Text = HUB_NAME
	title.Parent = backdrop

	local invite = Instance.new("TextLabel")
	invite.AnchorPoint = Vector2.new(0.5, 0)
	invite.Position = UDim2.new(0.5, 0, 0.5, 6)
	invite.Size = UDim2.fromOffset(400, 22)
	invite.BackgroundTransparency = 1
	invite.Font = Enum.Font.Code
	invite.TextSize = 15
	invite.TextColor3 = Color3.fromRGB(180, 140, 255)
	invite.Text = DISCORD_INVITE
	invite.Parent = backdrop

	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0, 1)
	panel.Position = UDim2.new(0, 28, 1, -28)
	panel.Size = UDim2.fromOffset(240, #RENDER_ROWS * 19)
	panel.BackgroundTransparency = 1
	panel.Parent = backdrop

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 2)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = panel

	for index, name in ipairs(RENDER_ROWS) do
		local row = Instance.new("TextLabel")
		row.BackgroundTransparency = 1
		row.Size = UDim2.new(1, 0, 0, 17)
		row.Font = Enum.Font.Code
		row.TextSize = 13
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.TextColor3 = Color3.fromRGB(120, 124, 134)
		row.Text = name
		row.LayoutOrder = index
		row.Parent = panel
		renderRows[name] = row
	end

	renderOverlay = gui
end

F.updateRenderOverlay = function()
	if not renderOverlay or not renderOverlay.Parent then
		F.buildRenderOverlay()
	end
	local data = F.getSave()
	if not data then
		return
	end
	local values = {
		money = F.formatNumber(data.Money),
		speed = F.formatNumber(data.SpeedPower),
		pets = tostring(F.countTable(data.Inventory)),
		eggs = tostring(F.countTable(data.EggInventory)),
		stolen = tostring(hopStealCount),
		session = F.formatClock(os.clock() - sessionStart),
	}
	for name, row in pairs(renderRows) do
		if row.Parent then
			row.Text = string.format("%-8s %s", name, tostring(values[name] or "-"))
		end
	end
end

F.applyRendering = function(disabled)
	local ok = pcall(function()
		RunService:Set3dRenderingEnabled(not disabled)
	end)
	if ok then
		renderingDisabled = disabled
	end
	if disabled then
		F.buildRenderOverlay()
		F.updateRenderOverlay()
	else
		F.destroyRenderOverlay()
	end
end

local EFFECT_CLASSES = {
	ParticleEmitter = true,
	Trail = true,
	Smoke = true,
	Fire = true,
	Sparkles = true,
}

local fpsBoostSaved = nil
local fpsBoostConnection = nil

F.setEffectEnabled = function(instance, enabled)
	pcall(function()
		instance.Enabled = enabled
	end)
end

F.enableFpsBoost = function()
	if fpsBoostSaved then
		return
	end
	local terrain = Workspace:FindFirstChildOfClass("Terrain")
	local quality = nil
	pcall(function()
		quality = settings().Rendering.QualityLevel
	end)
	fpsBoostSaved = {
		QualityLevel = quality,
		GlobalShadows = Lighting.GlobalShadows,
		FogEnd = Lighting.FogEnd,
		Terrain = terrain,
		WaterWaveSize = terrain and terrain.WaterWaveSize,
		WaterReflectance = terrain and terrain.WaterReflectance,
		Effects = {},
	}
	pcall(function()
		settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
	end)
	Lighting.GlobalShadows = false
	Lighting.FogEnd = 1e6
	if terrain then
		terrain.WaterWaveSize = 0
		terrain.WaterReflectance = 0
	end
	for _, instance in ipairs(Workspace:GetDescendants()) do
		if EFFECT_CLASSES[instance.ClassName] and instance.Enabled then
			table.insert(fpsBoostSaved.Effects, instance)
			F.setEffectEnabled(instance, false)
		end
	end
	fpsBoostConnection = Workspace.DescendantAdded:Connect(function(instance)
		if EFFECT_CLASSES[instance.ClassName] and F.isOn("FpsBoost") then
			F.setEffectEnabled(instance, false)
		end
	end)
end

F.disableFpsBoost = function()
	if fpsBoostConnection then
		fpsBoostConnection:Disconnect()
		fpsBoostConnection = nil
	end
	local saved = fpsBoostSaved
	if not saved then
		return
	end
	fpsBoostSaved = nil
	if saved.QualityLevel then
		pcall(function()
			settings().Rendering.QualityLevel = saved.QualityLevel
		end)
	end
	Lighting.GlobalShadows = saved.GlobalShadows
	Lighting.FogEnd = saved.FogEnd
	if saved.Terrain and saved.Terrain.Parent then
		saved.Terrain.WaterWaveSize = saved.WaterWaveSize
		saved.Terrain.WaterReflectance = saved.WaterReflectance
	end
	for _, instance in ipairs(saved.Effects) do
		F.setEffectEnabled(instance, true)
	end
end

F.applyFpsBoost = function(enabled)
	if enabled then
		F.enableFpsBoost()
	else
		F.disableFpsBoost()
	end
end

local fpsCapWarned = false

F.applyFpsCap = function(value)
	local setter = setfpscap or (syn and syn.set_fps_cap)
	if typeof(setter) ~= "function" then
		if not fpsCapWarned then
			fpsCapWarned = true
			F.notify("FPS cap is not supported by your executor")
		end
		return
	end
	pcall(setter, math.clamp(tonumber(value) or 60, 15, 360))
end

F.rejoinServer = function()
	local ok = pcall(function()
		TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
	end)
	if not ok then
		pcall(function()
			TeleportService:Teleport(game.PlaceId, LocalPlayer)
		end)
	end
end

local disconnectHandled = false

F.handleDisconnect = function(reason)
	if disconnectHandled then
		return
	end
	disconnectHandled = true
	if F.isOn("WebhookDisconnectAlerts") then
		F.sendWebhookEmbed({
			author = { name = GAME_NAME .. " | " .. HUB_NAME },
			title = "Disconnected",
			description = string.format("**Player** `%s`\n**Reason** %s", LocalPlayer.Name, tostring(reason or "Connection lost")),
			color = 15158332,
			footer = { text = HUB_NAME .. " | by von63rd" },
			timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
		}, true)
	end
	if F.isOn("AutoReconnect") then
		task.delay(2, F.rejoinServer)
	end
end

local antiAfkLastInput = tick()
local antiAfkLastTap = tick()

pcall(function()
	for _, connection in ipairs(getconnections(LocalPlayer.Idled)) do
		pcall(function()
			connection:Disable()
		end)
	end
end)

F.antiAfkTap = function()
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	VirtualUser:Button2Down(Vector2.new(0, 0), camera.CFrame)
	task.wait(0.1)
	VirtualUser:Button2Up(Vector2.new(0, 0), camera.CFrame)
	antiAfkLastTap = tick()
end

local antiAfkBeganConnection = UserInputService.InputBegan:Connect(function()
	antiAfkLastInput = tick()
end)

local antiAfkChangedConnection = UserInputService.InputChanged:Connect(function(input)
	local inputType = input.UserInputType
	if inputType == Enum.UserInputType.MouseMovement or inputType == Enum.UserInputType.Gamepad1 then
		antiAfkLastInput = tick()
	end
end)

-- ============================================================
-- Window / tabs
--
-- Obsidian's Window:AddTab(Name, IconName) icon is a Lucide icon name
-- (see https://lucide.dev/) resolved through Library:GetIcon, not a
-- raw rbxassetid, and every AddGroupbox call needs an explicit Side.
-- ============================================================

local TabSteal = Window:AddTab("Steal", "hand")
local TabEggs = Window:AddTab("Eggs", "egg")
local TabPets = Window:AddTab("Pets", "bone")
local TabShop = Window:AddTab("Shop", "store")
local TabEsp = Window:AddTab("ESP", "eye")
local TabMovement = Window:AddTab("Movement", "move")
local TabPriority = Window:AddTab("Priority", "list")
local TabServer = Window:AddTab("Server", "server")
local TabWebhooks = Window:AddTab("Webhooks", "send")
local TabSettings = Window:AddTab("Settings", "settings")
local TabInfo = Window:AddTab("Info", "info")

-- ===== Steal =====

local StealFilters = TabSteal:AddGroupbox({ Side = "Left", Name = "Filters" })

AddMultiSelect(StealFilters, "StealZones", "Steal Areas", ZONE_VALUES, {})
AddMultiSelect(StealFilters, "StealRarities", "Steal Rarities", RARITY_VALUES, {})
AddMultiSelect(StealFilters, "StealMutations", "Steal Mutations", MUTATION_VALUES, {})
AddDropdown(StealFilters, "StealPriority", "Target Priority", PRIORITY_VALUES, "Rarest")

local StealAutomation = TabSteal:AddGroupbox({ Side = "Left", Name = "Automation" })

AddToggle(StealAutomation, "AutoStealSelected", "Auto Steal Selected", false)
AddToggle(StealAutomation, "AutoStealAll", "Auto Steal All", false)
AddToggle(StealAutomation, "StealBigEggs", "Steal Big Eggs", false)
AddSlider(StealAutomation, "StealBigEggScale", "Big Egg Minimum Size", 1, 50, 2, "x")
AddSlider(StealAutomation, "StealSpeed", "Steal Speed", 50, 1000, 300)

local StealCarrying = TabSteal:AddGroupbox({ Side = "Right", Name = "Carrying" })

AddToggle(StealCarrying, "AutoReturn", "Auto Return to Base", true)
AddToggle(StealCarrying, "AutoDropEgg", "Auto Drop Held Egg", false)

-- ===== Eggs =====

local EggFilters = TabEggs:AddGroupbox({ Side = "Left", Name = "Filters" })

AddMultiSelect(EggFilters, "LifecycleRarities", "Egg Rarities", RARITY_VALUES, {})
AddMultiSelect(EggFilters, "LifecycleMutations", "Egg Mutations", MUTATION_VALUES, {})

local EggLifecycle = TabEggs:AddGroupbox({ Side = "Left", Name = "Place & Hatch" })

AddToggle(EggLifecycle, "AutoPlaceSelected", "Auto Place Selected", false)
AddToggle(EggLifecycle, "AutoPlaceAll", "Auto Place All", false)
AddToggle(EggLifecycle, "AutoOpenReadyEggs", "Auto Hatch Ready", false)

local EggSell = TabEggs:AddGroupbox({ Side = "Right", Name = "Auto Sell Eggs" })

AddToggle(EggSell, "AutoSellEggs", "Auto Sell Eggs", false)
AddMultiSelect(EggSell, "SellEggRarities", "Sell Egg Rarities", RARITY_VALUES, {})
AddSlider(EggSell, "SellEggInterval", "Sell Egg Interval", 1, 120, 8, "s")

-- ===== Pets =====

local PetEquip = TabPets:AddGroupbox({ Side = "Left", Name = "Equip" })

AddToggle(PetEquip, "AutoEquipBest", "Auto Equip Best Pets", false)

local PetFuse = TabPets:AddGroupbox({ Side = "Left", Name = "Auto Fuse" })

AddToggle(PetFuse, "AutoFusePets", "Auto Fuse Pets [Beta]", false)
AddMultiSelect(PetFuse, "FuseRarities", "Fuse Rarities", RARITY_VALUES, {})
AddMultiSelect(PetFuse, "FuseMutations", "Fuse Mutations", MUTATION_VALUES, {})
AddDropdown(PetFuse, "FuseTarget", "Pick Group By", FUSE_TARGET_VALUES, "Highest Rarity")
AddSlider(PetFuse, "FuseMaxScale", "Maximum Scale to Fuse", 0, 10, 10, "x")
AddSlider(PetFuse, "FuseKeepPerCategory", "Keep Per Pet Type", 0, 20, 0)
AddSlider(PetFuse, "FuseInterval", "Fuse Interval", 1, 120, 8, "s")
AddToggle(PetFuse, "FuseAutoReveal", "Auto Complete Reveal", true)
AddToggle(PetFuse, "FuseKeepMutated", "Never Fuse Mutated", true)
AddToggle(PetFuse, "FuseKeepEquipped", "Never Fuse Equipped", true)
AddButton(PetFuse, "Fuse Now", function()
	task.spawn(function()
		F.runAutoFusePets(true)
	end)
end)

local PetSell = TabPets:AddGroupbox({ Side = "Right", Name = "Auto Sell Pets" })

AddToggle(PetSell, "AutoSellPets", "Auto Sell Pets", false)
AddMultiSelect(PetSell, "SellRarities", "Sell Pet Rarities", RARITY_VALUES, {})
AddMultiSelect(PetSell, "SellMutations", "Sell Pet Mutations", MUTATION_VALUES, {})
AddSlider(PetSell, "SellMaxScale", "Maximum Scale to Sell", 0, 10, 10, "x")
AddSlider(PetSell, "SellInterval", "Sell Pet Interval", 1, 120, 6, "s")
AddToggle(PetSell, "SellKeepMutated", "Never Sell Mutated", true)
AddToggle(PetSell, "SellKeepEquipped", "Never Sell Equipped", true)

local PetEarnings = TabPets:AddGroupbox({ Side = "Right", Name = "Earnings" })

AddToggle(PetEarnings, "AutoClaimOffline", "Claim Offline Earnings", false)

-- ===== Shop =====

local ShopUpgrades = TabShop:AddGroupbox({ Side = "Left", Name = "Upgrades" })

AddToggle(ShopUpgrades, "AutoUpgrades", "Auto Buy Upgrades", false)
AddMultiSelect(ShopUpgrades, "UpgradeTypes", "Upgrades", UPGRADE_VALUES, { "Base", "Treadmill" })

local ShopRewards = TabShop:AddGroupbox({ Side = "Left", Name = "Rewards" })

AddToggle(ShopRewards, "AutoClaimIndex", "Auto Claim Index", false)
AddToggle(ShopRewards, "AutoClaimGroupReward", "Auto Claim Group Reward", false)

local ShopTrails = TabShop:AddGroupbox({ Side = "Right", Name = "Trails" })

AddToggle(ShopTrails, "AutoBuyTrail", "Auto Buy Trail", false)
AddMultiSelect(ShopTrails, "TrailWanted", "Trails", TRAIL_VALUES, {})
AddToggle(ShopTrails, "AutoEquipBestTrail", "Auto Equip Best Trail", false)

local ShopTraining = TabShop:AddGroupbox({ Side = "Right", Name = "Training & Gear" })

AddToggle(ShopTraining, "AutoTreadmill", "Auto Treadmill Training", false)
AddToggle(ShopTraining, "AutoEquipBestGear", "Auto Equip Best Gear", false)

-- ===== ESP =====

local EspEggs = TabEsp:AddGroupbox({ Side = "Left", Name = "Eggs" })

AddToggle(EspEggs, "EspWorldEggs", "World Egg ESP", false)
AddToggle(EspEggs, "EspCarriedEggs", "Carried & Dropped Eggs", false)

local EspWorld = TabEsp:AddGroupbox({ Side = "Right", Name = "World" })

AddToggle(EspWorld, "EspGuards", "Guard ESP", false)
AddToggle(EspWorld, "EspPets", "Pet ESP", false)
AddToggle(EspWorld, "EspPlayers", "Player ESP", false)
AddToggle(EspWorld, "EspMachines", "Machine ESP", false)
AddToggle(EspWorld, "EspPlots", "Plot ESP", false)
AddSlider(EspWorld, "EspDistance", "Render Distance", 100, 6000, 2000, " studs")

-- ===== Movement =====

local MoveCharacter = TabMovement:AddGroupbox({ Side = "Left", Name = "Character" })

AddToggle(MoveCharacter, "WalkSpeedEnabled", "Walk Speed Override", false, function(value)
	if not value then
		local humanoid = F.getHumanoid()
		if humanoid then
			humanoid.WalkSpeed = 16
		end
	end
end)
AddSlider(MoveCharacter, "WalkSpeed", "Walk Speed", 16, 500, 32)
AddToggle(MoveCharacter, "JumpPowerEnabled", "Jump Power Override", false)
AddSlider(MoveCharacter, "JumpPower", "Jump Power", 10, 500, 50)
AddToggle(MoveCharacter, "InfJump", "Infinite Jump", false)
AddToggle(MoveCharacter, "NoClip", "NoClip", false)

local MoveFly = TabMovement:AddGroupbox({ Side = "Left", Name = "Fly" })

AddToggle(MoveFly, "Fly", "Fly (WASD, Space up, Ctrl down)", false, function(value)
	if not value then
		local humanoid = F.getHumanoid()
		if humanoid then
			humanoid.PlatformStand = false
		end
	end
end)
AddSlider(MoveFly, "FlySpeed", "Fly Speed", 10, 400, 60)

local MoveTeleport = TabMovement:AddGroupbox({ Side = "Right", Name = "Teleport" })

AddDropdown(MoveTeleport, "WaypointTarget", "Waypoint", WAYPOINT_VALUES, "Base")
AddButton(MoveTeleport, "Teleport to Waypoint", function()
	task.spawn(function()
		local position = F.resolveWaypoint(F.optionValue("WaypointTarget", nil))
		if not position then
			F.notify("That waypoint is not available right now")
			return
		end
		if not F.travelTo(position, true) then
			F.notify("Teleport failed")
		end
	end)
end)

-- ===== Priority =====

local PriorityOrder = TabPriority:AddGroupbox({ Side = "Left", Name = "Task Order" })

for index, slot in ipairs(PRIORITY_SLOTS) do
	AddDropdown(PriorityOrder, slot, string.format("Priority %d", index), PRIORITY_TASKS, PRIORITY_TASKS[index])
end

-- ===== Server =====

local ServerHop = TabServer:AddGroupbox({ Side = "Left", Name = "Server Hop" })

AddToggle(ServerHop, "AutoServerHop", "Auto Server Hop", false)
AddDropdown(ServerHop, "HopMode", "Hop When", HOP_MODES, "No Matching Eggs")
AddSlider(ServerHop, "HopValue", "Threshold", 1, 200, 15)
AddButton(ServerHop, "Hop Now", function()
	task.spawn(function()
		hopCooldownUntil = 0
		F.serverHop("Manual hop")
	end)
end)

local ServerConnection = TabServer:AddGroupbox({ Side = "Right", Name = "Connection" })

AddToggle(ServerConnection, "AutoReconnect", "Auto Reconnect", false)
AddButton(ServerConnection, "Copy Join Script", function()
	local joinScript = string.format(
		'game:GetService("TeleportService"):TeleportToPlaceInstance(%d, "%s", game:GetService("Players").LocalPlayer)',
		game.PlaceId,
		jobIdText
	)
	F.copyText(joinScript, "Copied join script to clipboard")
end)

-- ===== Webhooks =====

local WebhookMain = TabWebhooks:AddGroupbox({ Side = "Left", Name = "Webhook" })

AddToggle(WebhookMain, "WebhookEnabled", "Enable Webhooks", false)
AddTextBox(WebhookMain, "WebhookUrl", "Webhook URL", "https://discord.com/api/webhooks/...")
AddTextBox(WebhookMain, "WebhookPingId", "Ping User ID", "123456789012345678")
AddSlider(WebhookMain, "WebhookInterval", "Summary Interval", 1, 180, 15, " min")
AddButton(WebhookMain, "Send Summary Now", function()
	task.spawn(function()
		F.notify(F.sendSummary() and "Summary sent" or "Webhook send failed")
	end)
end)

local WebhookContents = TabWebhooks:AddGroupbox({ Side = "Right", Name = "Contents" })

AddToggle(WebhookContents, "WebhookEggSpawns", "List Spawned Eggs", true)
AddMultiSelect(WebhookContents, "WebhookRarities", "Only Report Rarities", RARITY_VALUES, {})
AddToggle(WebhookContents, "WebhookDisconnectAlerts", "Disconnect Alerts", false)

-- ===== Settings =====

local SettingsMenu = TabSettings:AddGroupbox({ Side = "Left", Name = "Menu" })

AddToggle(SettingsMenu, "AntiAfk", "Anti-AFK", true)
AddToggle(SettingsMenu, "AntiGameplayPause", "No Gameplay Paused", true, function(value)
	F.applyAntiGameplayPause(value)
end)
AddToggle(SettingsMenu, "DisableRendering", "Disable 3D Rendering", false, function(value)
	F.applyRendering(value)
end)

local SettingsPerformance = TabSettings:AddGroupbox({ Side = "Left", Name = "Performance" })

AddToggle(SettingsPerformance, "FpsBoost", "FPS Boost", false, function(value)
	F.applyFpsBoost(value)
end)
AddToggle(SettingsPerformance, "AutoDeleteOwnPets", "Auto Delete Own Pets", false)
AddSlider(SettingsPerformance, "FpsCap", "FPS Cap", 15, 360, 60, nil, function(value)
	F.applyFpsCap(value)
end)

local SettingsKeybind = TabSettings:AddGroupbox({ Side = "Right", Name = "Keybind" })

SettingsKeybind:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {
	Default = "LeftAlt",
	NoUI = true,
	Text = "Menu keybind",
})
Library.ToggleKeybind = Options.MenuKeybind

local SettingsDanger = TabSettings:AddGroupbox({ Side = "Right", Name = "Danger Zone" })

local PANIC_TOGGLES = {
	"AutoStealSelected", "AutoStealAll", "StealBigEggs", "AutoDropEgg",
	"AutoPlaceSelected", "AutoPlaceAll", "AutoOpenReadyEggs", "AutoSellEggs",
	"AutoFusePets", "AutoSellPets", "AutoEquipBest", "AutoClaimOffline",
	"AutoUpgrades", "AutoClaimIndex", "AutoClaimGroupReward", "AutoBuyTrail",
	"AutoEquipBestTrail", "AutoTreadmill", "AutoEquipBestGear",
	"AutoServerHop", "Fly", "NoClip", "InfJump",
}

F.panic = function()
	for _, id in ipairs(PANIC_TOGGLES) do
		F.setControl(id, false)
	end
	F.notify("Panic - every automation toggle is off", 3)
end

AddButton(SettingsDanger, "Panic Stop", F.panic)
AddButton(SettingsDanger, "Unload VoidHub", function()
	F.unload()
end)

-- Config (save/load/autoload) and Theme sections for the Settings tab are
-- built by SaveManager:BuildConfigSection / ThemeManager:ApplyToTab near
-- the bottom of the script, once every control on this tab exists.

-- ===== Info =====

local InfoCommunity = TabInfo:AddGroupbox({ Side = "Left", Name = "Community" })

AddButton(InfoCommunity, "Copy Discord Link", function()
	F.copyText(DISCORD_INVITE, "Copied Discord invite to clipboard")
end)
AddButton(InfoCommunity, "Copy Credits", function()
	F.copyText(HUB_NAME .. " - Steal An Egg Script Hub | Credits: von63rd | Script Developer & Designer", "Copied credits")
end)

-- ============================================================
-- Movement / anti-detect event handlers
-- ============================================================

local Camera = Workspace.CurrentCamera

RunService.Stepped:Connect(function()
	if Unloaded then
		return
	end
	if F.isOn("NoClip") then
		local character = LocalPlayer.Character
		if character then
			for _, part in ipairs(character:GetDescendants()) do
				if part:IsA("BasePart") and part.CanCollide then
					part.CanCollide = false
				end
			end
		end
	end
end)

UserInputService.JumpRequest:Connect(function()
	if Unloaded then
		return
	end
	if F.isOn("InfJump") then
		local humanoid = F.getHumanoid()
		if humanoid then
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end
end)

RunService.RenderStepped:Connect(function(dt)
	if Unloaded then
		return
	end

	if F.isOn("WalkSpeedEnabled") then
		local humanoid = F.getHumanoid()
		if humanoid then
			humanoid.WalkSpeed = tonumber(F.optionValue("WalkSpeed", 32)) or 32
		end
	end

	if F.isOn("JumpPowerEnabled") then
		local humanoid = F.getHumanoid()
		if humanoid then
			humanoid.UseJumpPower = true
			humanoid.JumpPower = tonumber(F.optionValue("JumpPower", 50)) or 50
		end
	end

	if F.isOn("Fly") then
		local root = F.getRoot()
		local humanoid = F.getHumanoid()
		if root and humanoid then
			humanoid.PlatformStand = true
			local direction = Vector3.zero
			if UserInputService:IsKeyDown(Enum.KeyCode.W) then
				direction = direction + Camera.CFrame.LookVector
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then
				direction = direction - Camera.CFrame.LookVector
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then
				direction = direction - Camera.CFrame.RightVector
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then
				direction = direction + Camera.CFrame.RightVector
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
				direction = direction + Vector3.new(0, 1, 0)
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
				direction = direction - Vector3.new(0, 1, 0)
			end
			root.Velocity = Vector3.zero
			if direction.Magnitude > 0 then
				root.CFrame = root.CFrame + direction.Unit * (tonumber(F.optionValue("FlySpeed", 60)) or 60) * dt
			end
		end
	end
end)

LocalPlayer.CharacterAdded:Connect(function()
	if Unloaded then
		return
	end
	task.wait(0.35)
	if F.stealingEnabled() then
		F.swapStealHumanoid()
	end
end)

task.spawn(function()
	while not Unloaded do
		task.wait(0.1)
		if not F.stealingEnabled() then
			continue
		end
		local root = F.getRoot()
		local humanoid = F.getHumanoid()
		if not root or not humanoid or humanoid:GetAttribute("VoidHubStealHum") ~= true then
			continue
		end
		local laneY = F.getLaneY()
		local vel = root.AssemblyLinearVelocity
		if root.Position.Y > laneY + 12 then
			local y = F.groundedY(root.Position.X, root.Position.Z, laneY)
			root.CFrame = CFrame.new(root.Position.X, y, root.Position.Z)
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
		elseif math.abs(vel.Y) > 4 then
			root.AssemblyLinearVelocity = Vector3.new(vel.X, 0, vel.Z)
		end
	end
end)

task.spawn(function()
	while not Unloaded do
		task.wait(0.2)
		if F.stealingEnabled() then
			F.swapStealHumanoid()
		end
	end
end)

task.spawn(function()
	while not Unloaded do
		task.wait(0.2)
		if stealBusy then
			continue
		end
		if F.isOn("AutoDropEgg") and F.isCarrying() then
			stealBusy = true
			pcall(F.runAutoDropEgg)
			stealBusy = false
		elseif F.isOn("AutoReturn") and F.isCarrying() then
			stealBusy = true
			pcall(F.runAutoReturn)
			stealBusy = false
		end
	end
end)

local PRIORITY_HANDLERS = {
	["Auto Steal Egg"] = {
		Interval = 0.2,
		Ready = function()
			return F.stealingEnabled() and not F.isCarrying() and not F.stealBlockedByInventory()
		end,
		Run = function()
			return F.runAutoSteal()
		end,
	},
	["Auto Place Egg"] = {
		Interval = 2,
		Ready = function()
			return F.placingEnabled()
				and not F.isCarrying()
				and not F.isPlotFull()
				and #F.getUnplacedEggUids() > 0
		end,
		Run = function()
			return F.runAutoPlaceEggs()
		end,
	},
	["Auto Hatch"] = {
		Interval = 2,
		Ready = function()
			return F.isOn("AutoOpenReadyEggs") and not F.isCarrying()
		end,
		Run = function()
			return F.runAutoOpenReadyEggs()
		end,
	},
	["Auto Treadmill"] = {
		Interval = 4,
		Ready = function()
			return F.isOn("AutoTreadmill") and not F.isCarrying()
		end,
		Run = function()
			return F.runAutoTreadmillTraining()
		end,
	},
}

local priorityLastRun = {}

F.priorityOrder = function()
	local order = {}
	local used = {}
	for _, slot in ipairs(PRIORITY_SLOTS) do
		local name = F.optionValue(slot, nil)
		if PRIORITY_HANDLERS[name] and not used[name] then
			used[name] = true
			table.insert(order, name)
		end
	end
	for _, name in ipairs(PRIORITY_TASKS) do
		if not used[name] then
			used[name] = true
			table.insert(order, name)
		end
	end
	return order
end

task.spawn(function()
	while not Unloaded do
		task.wait(0.2)
		if stealBusy then
			continue
		end
		for _, name in ipairs(F.priorityOrder()) do
			local handler = PRIORITY_HANDLERS[name]
			if handler.Ready() and os.clock() - (priorityLastRun[name] or 0) >= handler.Interval then
				priorityLastRun[name] = os.clock()
				if name ~= "Auto Treadmill" and (treadmillActive or F.isDoubleSpeedVisible()) then
					pcall(F.stopTreadmillTraining)
				end
				stealBusy = true
				local ok, worked = pcall(handler.Run)
				stealBusy = false
				if ok and worked then
					break
				end
			end
		end
	end
end)

task.spawn(function()
	while not Unloaded do
		task.wait(3)
		if F.isOn("AutoServerHop") and not stealBusy then
			pcall(F.runServerHop)
		end
	end
end)

task.spawn(function()
	while not Unloaded do
		task.wait(5)
		if F.isOn("AutoEquipBest") and not stealBusy then
			pcall(F.runAutoEquipBest)
		end
	end
end)

task.spawn(function()
	while not Unloaded do
		task.wait(tonumber(F.optionValue("SellInterval", 6)) or 6)
		if F.isOn("AutoSellPets") and not stealBusy and not F.isCarrying() then
			pcall(F.runAutoSellPets)
		end
	end
end)

task.spawn(function()
	while not Unloaded do
		task.wait(tonumber(F.optionValue("SellEggInterval", 8)) or 8)
		if F.isOn("AutoSellEggs") and not stealBusy and not F.isCarrying() then
			stealBusy = true
			pcall(F.runAutoSellEggs)
			stealBusy = false
		end
	end
end)

task.spawn(function()
	while not Unloaded do
		task.wait(1)
		if (treadmillActive or F.isDoubleSpeedVisible()) and not F.isOn("AutoTreadmill") then
			pcall(F.stopTreadmillTraining)
		end
	end
end)

task.spawn(function()
	while not Unloaded do
		task.wait(5)
		if F.isOn("AutoEquipBestTrail") then
			pcall(F.runAutoEquipBestTrail)
		end
		if F.isOn("AutoEquipBestGear") then
			pcall(F.runAutoEquipBestGear)
		end
	end
end)

task.spawn(function()
	while not Unloaded do
		task.wait(20)
		if F.isOn("AutoClaimGroupReward") then
			pcall(F.runAutoClaimGroupReward)
		end
	end
end)

task.spawn(function()
	while not Unloaded do
		task.wait(0.4)
		local anyEsp = F.isOn("EspWorldEggs")
			or F.isOn("EspCarriedEggs")
			or F.isOn("EspGuards")
			or F.isOn("EspPets")
			or F.isOn("EspPlayers")
			or F.isOn("EspMachines")
			or F.isOn("EspPlots")
		if anyEsp then
			pcall(F.runEsp)
		elseif next(espObjects) ~= nil then
			pcall(F.clearAllEsp)
		end
	end
end)

task.spawn(function()
	while not Unloaded do
		task.wait(5)
		if F.isOn("WebhookEnabled") then
			pcall(F.trackWebhookEvents)
			pcall(F.runWebhookSummary)
		end
	end
end)

task.spawn(function()
	while not Unloaded do
		task.wait(tonumber(F.optionValue("FuseInterval", 8)) or 8)
		if F.isOn("AutoFusePets") and not stealBusy and not F.isCarrying() then
			stealBusy = true
			pcall(F.runAutoFusePets)
			stealBusy = false
		end
	end
end)

task.spawn(function()
	while not Unloaded do
		task.wait(1)
		if F.isOn("AutoDeleteOwnPets") then
			pcall(F.deleteOwnPetRenders)
		end
	end
end)

task.spawn(function()
	while not Unloaded do
		task.wait(15)
		if F.isOn("AutoClaimOffline") then
			pcall(F.runClaimOfflineEarnings)
		end
	end
end)

task.spawn(function()
	while not Unloaded do
		task.wait(2)
		if F.isOn("AutoUpgrades") and not F.isCarrying() then
			pcall(F.runAutoUpgrades)
		end
	end
end)

task.spawn(function()
	while not Unloaded do
		task.wait(8)
		if F.isOn("AutoClaimIndex") then
			pcall(F.runAutoClaimIndex)
		end
	end
end)

task.spawn(function()
	while not Unloaded do
		task.wait(6)
		if F.isOn("AutoBuyTrail") and not F.isCarrying() then
			pcall(F.runAutoBuyTrail)
		end
	end
end)

task.spawn(function()
	while not Unloaded do
		task.wait(1)
		if F.isOn("DisableRendering") then
			pcall(F.updateRenderOverlay)
		elseif renderOverlay then
			pcall(F.destroyRenderOverlay)
		end
	end
end)

task.spawn(function()
	while not Unloaded do
		task.wait(1)
		if F.isOn("AntiGameplayPause") then
			F.applyAntiGameplayPause(true)
		end
	end
end)

task.spawn(function()
	local coreGui = game:GetService("CoreGui")
	while not Unloaded do
		task.wait(1)
		if F.isOn("AutoReconnect") or F.isOn("WebhookDisconnectAlerts") then
			local prompt = coreGui:FindFirstChild("RobloxPromptGui")
			local errorPrompt = prompt and prompt:FindFirstChild("promptOverlay")
			if errorPrompt then
				for _, child in ipairs(errorPrompt:GetChildren()) do
					if child.Name:find("ErrorPrompt") and child.Visible then
						F.handleDisconnect("Roblox error prompt")
						break
					end
				end
			end
		end
	end
end)

task.spawn(function()
	while not Unloaded do
		task.wait(2)
		if F.isOn("AntiAfk") then
			local idle = tick() - antiAfkLastInput
			local sinceTap = tick() - antiAfkLastTap
			if idle >= 300 and sinceTap >= 60 then
				pcall(F.antiAfkTap)
			elseif idle < 300 and sinceTap >= 300 then
				pcall(F.antiAfkTap)
			end
		end
	end
end)

local function stopAutomation()
	pcall(F.applyAntiGameplayPause, false)
	pcall(F.applyRendering, false)
	pcall(F.applyFpsBoost, false)
	pcall(F.destroyRenderOverlay)
	pcall(F.stopTreadmillTraining)
	pcall(F.clearAllEsp)

	if espFolder then
		pcall(function()
			espFolder:Destroy()
		end)
	end

	pcall(function()
		antiAfkBeganConnection:Disconnect()
	end)
	pcall(function()
		antiAfkChangedConnection:Disconnect()
	end)
	pcall(function()
		if carryConnection then
			carryConnection:Disconnect()
		end
	end)
	pcall(function()
		if hopFailConnection then
			hopFailConnection:Disconnect()
		end
	end)

	if getgenv then
		getgenv().VoidHubStealAnEgg = nil
	end
end

-- Handles the "Unload VoidHub" button: stop automation, then hand off to
-- the library's own Unload() (which fires Library:OnUnload below and tears
-- down the UI). Guarded by Unloaded so this can't run twice.
F.unload = function()
	if Unloaded then
		return
	end
	Unloaded = true
	stopAutomation()

	pcall(function()
		if not Library.Unloaded then
			Library:Unload()
		end
	end)
end

-- Also covers the library's own close/unload UI, which calls
-- Library:Unload() directly without going through F.unload().
Library:OnUnload(function()
	if Unloaded then
		return
	end
	Unloaded = true
	stopAutomation()
end)

if getgenv then
	getgenv().VoidHubStealAnEgg = { Unload = F.unload }
end

SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
SaveManager:SetFolder("VoidHub/StealAnEgg")
SaveManager:BuildConfigSection(TabSettings)

ThemeManager:SetLibrary(Library)
ThemeManager:SetFolder("VoidHub/StealAnEgg")
ThemeManager:ApplyToTab(TabSettings)

SaveManager:LoadAutoloadConfig()

F.applyAntiGameplayPause(true)

F.notify("Loaded - " .. GAME_NAME .. " | by von63rd | v1", 4)
