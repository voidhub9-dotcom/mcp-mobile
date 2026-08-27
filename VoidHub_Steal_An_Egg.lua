-- VoidHub | Steal An Egg | by von63rd | v1
-- Powered by ProxyLib

if not game:IsLoaded() then
	game.Loaded:Wait()
end

local function applyBypass()
	local getupvalues = debug.getupvalues or getupvalues
	local setrawmetatable = setrawmetatable or debug.setmetatable or setmetatable

	local targets = filtergc("function", {
		Constants = { "gmatch", "GetFullName" },
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
						end,
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
		print("[VoidHub] Anti-Cheat bypassed successfully!")
		break
	end
	task.wait(0.2)
end

if not bypassSuccess then
	warn("[VoidHub] Anti-cheat function not found yet, proceeding with fallback...")
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
local Camera = Workspace.CurrentCamera

local GAME_NAME = "Steal An Egg"
local HUB_NAME = "VoidHub"
local HUB_VERSION = "v1"
local DISCORD_INVITE = "https://discord.gg/Wsarxj9Gzz"
local HUB_ICON = "rbxassetid://101833678008843"

local ICONS = {
	activity = "rbxassetid://10709752035",
	bone = "rbxassetid://10709781605",
	bookopen = "rbxassetid://10709781717",
	charge = "rbxassetid://10709790202",
	clock = "rbxassetid://10709805144",
	coins = "rbxassetid://10709811110",
	crown = "rbxassetid://10709818626",
	egg = "rbxassetid://10723345518",
	eye = "rbxassetid://10723346959",
	feather = "rbxassetid://10723354671",
	flame = "rbxassetid://10723376114",
	gauge = "rbxassetid://10723395708",
	globe = "rbxassetid://10723404337",
	hand = "rbxassetid://10723405649",
	heart = "rbxassetid://10723406885",
	info = "rbxassetid://10723415903",
	listordered = "rbxassetid://10723427199",
	mappin = "rbxassetid://10734886004",
	menu = "rbxassetid://10734887784",
	move = "rbxassetid://10734900011",
	refreshcw = "rbxassetid://10734933222",
	save = "rbxassetid://10734941499",
	send = "rbxassetid://10734943902",
	server = "rbxassetid://10734949856",
	settings = "rbxassetid://10734950309",
	shoppingcart = "rbxassetid://10734952479",
	star = "rbxassetid://10734966248",
	sword = "rbxassetid://10734975486",
	tags = "rbxassetid://10734976739",
	target = "rbxassetid://10734977012",
	trendingup = "rbxassetid://10747363465",
	user = "rbxassetid://10747373176",
	users = "rbxassetid://10747373426",
}

local ProxyLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/ProxyHubDev/ProxyLib/refs/heads/main/Documents/ProxyLibrary"))()
local Lib = ProxyLib.new()

local Window = Lib:CreateWindow({
	Title = HUB_NAME,
	Subtitle = GAME_NAME .. " | by von63rd | " .. HUB_VERSION,
	Icon = HUB_ICON,
	Size = Vector2.new(560, 420),
	MinSize = Vector2.new(380, 260),
	MaxSize = Vector2.new(820, 620),
	TypeUI = "Modern",
	Theme = "Purple",
	Language = "English",
	AutoSave = true,
	AutoLoad = true,

	Acrylic = {
		Enabled = true,
		Opacity = 1,
	},

	BackgroundImage = {
		Id = "rbxassetid://000000000",
		Active = false,
	},

	TitleConfig = {
		Gradient = true,
		Colors = { Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255) },
		Words = {
			{ Text = "Void", Colors = { Color3.fromRGB(255, 255, 255) } },
			{ Text = "Hub", Colors = { Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255) } },
		},
	},

	FloatButton = {
		Shape = "Circle",
		Color = "Black",
		Size = 46,
		Icon = HUB_ICON,
	},

	ConfigPanel = {
		Enabled = true,
		Acrylic = true,
		Theme = true,
		Fps = true,
		Ping = true,
		Profile = true,
		HideNotify = true,
		Language = true,
		BackgroundImage = false,
	},
})

local Unloaded = false

local function Notify(text, duration, title)
	Window:Notify({
		Title = title or HUB_NAME,
		Text = tostring(text),
		Duration = tonumber(duration) or 4,
	})
end

Notify(GAME_NAME .. " | by von63rd | " .. HUB_VERSION, 4, "VoidHub Loaded")

local Remotes, Constants, Save, BaseUpgradeClient, EggTypes
local Areas, Assets, Gears, Trails, Treadmills
local EggCmds, PlotCmds, AreaEggSlotIdentity, AssetCmds, AssetItemSerialization, FuseKernelUtil
local NET

local modulesLoaded = pcall(function()
	Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
	Constants = require(ReplicatedStorage.Shared.Globals.Constants)
	Save = require(ReplicatedStorage.Shared.Save)
	BaseUpgradeClient = require(ReplicatedStorage.Client.BaseUpgrade)
	EggTypes = require(ReplicatedStorage.Shared.Types.Eggs)
	Areas = require(ReplicatedStorage.Data.Areas)
	Assets = require(ReplicatedStorage.Data.Assets)
	Gears = require(ReplicatedStorage.Data.Gears)
	Trails = require(ReplicatedStorage.Data.Trails)
	Treadmills = require(ReplicatedStorage.Data.Treadmills)

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

	local plotState = require(ReplicatedStorage.Client.PlotState)
	PlotCmds = {
		GetRespawnPointCFrame = plotState.FindRespawnCFrame,
		GetPlotData = plotState.ResolvePlot,
		IsWorldPositionWithinLocalPlotBounds = plotState.ContainsLocalPoint,
		GetSlotOwner = plotState.LookupOwner,
	}

	local slotId = require(ReplicatedStorage.Shared.Util.AreaEggSlotIdentity)
	AreaEggSlotIdentity = {
		IsFirstAreaUid = slotId.LooksLikeFirstAreaUid,
		BuildSlotKey = slotId.SlotKey,
	}

	local roster = require(ReplicatedStorage.Client.AssetRoster)
	AssetCmds = {
		GetRuntimeSnapshot = roster.ReadSnapshot,
	}

	local items = require(ReplicatedStorage.Shared.Util.AssetItems)
	AssetItemSerialization = {
		Deserialize = items.Decode,
	}

	local fuse = require(ReplicatedStorage.Shared.Util.FuseKernel)
	FuseKernelUtil = {
		CanSelectPet = fuse.MayEnterFuse,
		CalculateFusePrice = fuse.PriceFor,
	}

	NET = {
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
end)

if not modulesLoaded then
	Notify("This script only runs inside " .. GAME_NAME .. ". Join the game and execute again.", 8, "Wrong Game")
	return
end

local F = {}
local State = {}
local Components = {}

if getgenv then
	local previous = getgenv().VoidHubStealAnEgg
	if typeof(previous) == "table" and typeof(previous.Unload) == "function" then
		pcall(previous.Unload)
	end
	getgenv().VoidHubStealAnEgg = {
		Unload = function()
			if typeof(F.unload) == "function" then
				F.unload()
			end
		end,
	}
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

local function AddToggle(tab, id, config)
	State[id] = config.Default == true
	local callback = config.Callback
	local component = tab:CreateToggle({
		Title = config.Title,
		Description = config.Description,
		Icon = config.Icon,
		Default = config.Default == true,
		SaveId = id,
		Callback = function(value)
			State[id] = value == true
			if callback then
				callback(value == true)
			end
		end,
	})
	Components[id] = component
	return component
end

local function AddSlider(tab, id, config)
	State[id] = config.Default
	local callback = config.Callback
	local component = tab:CreateSlider({
		Title = config.Title,
		Min = config.Min,
		Max = config.Max,
		Default = config.Default,
		SaveId = id,
		Callback = function(value)
			State[id] = value
			if callback then
				callback(value)
			end
		end,
	})
	Components[id] = component
	return component
end

local function AddDropdown(tab, id, config)
	State[id] = config.Default
	local callback = config.Callback
	local component = tab:CreateDropdown({
		Title = config.Title,
		Icon = config.Icon,
		Options = config.Options,
		Multiple = config.Multiple == true,
		Default = config.Default,
		SaveId = id,
		Callback = function(value)
			State[id] = value
			if callback then
				callback(value)
			end
		end,
	})
	Components[id] = component
	return component
end

local function AddTextBox(tab, id, config)
	State[id] = config.Default or ""
	local callback = config.Callback
	local component = tab:CreateTextBox({
		Title = config.Title,
		Placeholder = config.Placeholder,
		MaxLength = config.MaxLength or 200,
		Default = config.Default or "",
		SaveId = id,
		Callback = function(text)
			State[id] = text
			if callback then
				callback(text)
			end
		end,
	})
	Components[id] = component
	return component
end

local RARITY_RANK = {
	Common = 1,
	Uncommon = 2,
	Rare = 3,
	Epic = 4,
	Legendary = 5,
	Mythic = 6,
	Cosmic = 7,
	Secret = 8,
	Eternal = 9,
	Divine = 10,
}

local RARITY_VALUES = {
	"Common",
	"Uncommon",
	"Rare",
	"Epic",
	"Legendary",
	"Mythic",
	"Cosmic",
	"Secret",
	"Eternal",
	"Divine",
}

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

local MUTATION_VALUES = { "Golden", "Rainbow", "Silver" }

local PRIORITY_VALUES = { "Rarest", "Nearest", "Furthest", "Biggest Size" }

local FUSE_TARGET_VALUES = { "Highest Rarity", "Lowest Rarity", "Most Duplicates" }

local PRIORITY_TASKS = { "Auto Steal Egg", "Auto Place Egg", "Auto Hatch", "Auto Treadmill" }

local PRIORITY_SLOTS = { "PrioritySlot1", "PrioritySlot2", "PrioritySlot3", "PrioritySlot4" }

local HOP_MODES = { "No Matching Eggs", "Timed Interval", "After Steal Count" }

local jobIdText = tostring(game.JobId)
local shortJobIdText = #jobIdText > 18 and (string.sub(jobIdText, 1, 18) .. "...") or jobIdText

local sessionStart = os.clock()

F.copyText = function(text, message)
	if setclipboard then
		setclipboard(text)
	elseif toclipboard then
		toclipboard(text)
	else
		Notify("Your executor does not support copying to the clipboard")
		return
	end
	Notify(message)
end

F.copyDiscord = function()
	F.copyText(DISCORD_INVITE, "Copied the VoidHub Discord invite")
end

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
		Notify("Server hop found no candidates, retrying in 30s")
		return false
	end
	Notify(string.format("Server hopping: %s", tostring(reason or "requested")))
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
	Notify("Server hop failed, retrying in 10s")
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
	Notify("Your farm has no free egg spots left")
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
				local mutations = F.recordMutations(record)
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
		return F.getFuseMachinePosition()
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
	if rank >= 9 then
		return Color3.fromRGB(210, 150, 255)
	elseif rank >= 7 then
		return Color3.fromRGB(255, 110, 160)
	elseif rank >= 5 then
		return Color3.fromRGB(255, 190, 80)
	elseif rank >= 3 then
		return Color3.fromRGB(120, 200, 255)
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
					Color3.fromRGB(160, 140, 255),
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

F.formatElapsed = function(seconds)
	local total = math.max(0, math.floor(seconds))
	local hours = math.floor(total / 3600)
	local minutes = math.floor((total % 3600) / 60)
	if hours > 0 then
		return string.format("%dh %dm", hours, minutes)
	end
	return string.format("%dm", minutes)
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
		color = 11832063,
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

--// Interface

Window:CreateSeparator({ Text = "Farming" })

local TabEggs = Window:CreateTab({
	Title = "Eggs",
	Subtitle = "Stealing & Handling",
	Icon = ICONS.egg,
})

TabEggs:CreateSection({ Text = "Steal Eggs", Icon = ICONS.hand })

AddDropdown(TabEggs, "StealZones", {
	Title = "Areas",
	Icon = ICONS.mappin,
	Options = ZONE_VALUES,
	Multiple = true,
	Default = {},
})

AddDropdown(TabEggs, "StealRarities", {
	Title = "Rarities",
	Icon = ICONS.star,
	Options = RARITY_VALUES,
	Multiple = true,
	Default = {},
})

AddDropdown(TabEggs, "StealMutations", {
	Title = "Mutations",
	Icon = ICONS.flame,
	Options = MUTATION_VALUES,
	Multiple = true,
	Default = {},
})

AddDropdown(TabEggs, "StealPriority", {
	Title = "Target Priority",
	Icon = ICONS.target,
	Options = PRIORITY_VALUES,
	Default = "Rarest",
})

AddToggle(TabEggs, "AutoStealSelected", {
	Title = "Auto Steal Selected",
	Description = "Only steals eggs matching the filters above",
	Default = false,
})

AddToggle(TabEggs, "AutoStealAll", {
	Title = "Auto Steal All",
	Description = "Ignores every filter and grabs anything",
	Default = false,
})

AddSlider(TabEggs, "StealSpeed", {
	Title = "Steal Speed",
	Min = 50,
	Max = 1000,
	Default = 300,
})

AddToggle(TabEggs, "StealBigEggs", {
	Title = "Steal Big Eggs",
	Description = "Always grabs oversized eggs",
	Default = false,
})

AddSlider(TabEggs, "StealBigEggScale", {
	Title = "Big Egg Minimum Size",
	Min = 1,
	Max = 50,
	Default = 2,
})

AddToggle(TabEggs, "AutoDropEgg", {
	Title = "Auto Drop Held Egg",
	Default = false,
})

AddToggle(TabEggs, "AutoReturn", {
	Title = "Auto Return to Base",
	Description = "Carries stolen eggs back to your plot",
	Default = true,
})

TabEggs:CreateSection({ Text = "Egg Handling", Icon = ICONS.refreshcw })

AddDropdown(TabEggs, "LifecycleRarities", {
	Title = "Rarities",
	Icon = ICONS.star,
	Options = RARITY_VALUES,
	Multiple = true,
	Default = {},
})

AddDropdown(TabEggs, "LifecycleMutations", {
	Title = "Mutations",
	Icon = ICONS.flame,
	Options = MUTATION_VALUES,
	Multiple = true,
	Default = {},
})

AddToggle(TabEggs, "AutoPlaceSelected", {
	Title = "Auto Place Selected",
	Default = false,
})

AddToggle(TabEggs, "AutoPlaceAll", {
	Title = "Auto Place All",
	Default = false,
})

AddToggle(TabEggs, "AutoOpenReadyEggs", {
	Title = "Auto Hatch Ready",
	Default = false,
})

TabEggs:CreateSection({ Text = "Server Hop", Icon = ICONS.server })

AddToggle(TabEggs, "AutoServerHop", {
	Title = "Auto Server Hop",
	Default = false,
})

AddDropdown(TabEggs, "HopMode", {
	Title = "Hop When",
	Icon = ICONS.refreshcw,
	Options = HOP_MODES,
	Default = HOP_MODES[1],
})

AddSlider(TabEggs, "HopValue", {
	Title = "Threshold (s / min / steals)",
	Min = 1,
	Max = 200,
	Default = 15,
})

TabEggs:CreateButton({
	Title = "Hop Now",
	Description = "Jumps to a fresh server right away",
	Icon = ICONS.server,
	Callback = function()
		task.spawn(function()
			hopCooldownUntil = 0
			F.serverHop("Manual hop")
		end)
	end,
})

local TabPets = Window:CreateTab({
	Title = "Pets",
	Subtitle = "Fusing & Selling",
	Icon = ICONS.bone,
})

TabPets:CreateSection({ Text = "Pets", Icon = ICONS.bone })

AddToggle(TabPets, "AutoEquipBest", {
	Title = "Auto Equip Best Pets",
	Default = false,
})

TabPets:CreateSection({ Text = "Auto Fuse", Icon = ICONS.flame })

AddToggle(TabPets, "AutoFusePets", {
	Title = "Auto Fuse Pets [Beta]",
	Default = false,
})

AddDropdown(TabPets, "FuseRarities", {
	Title = "Fuse Rarities",
	Icon = ICONS.star,
	Options = RARITY_VALUES,
	Multiple = true,
	Default = {},
})

AddDropdown(TabPets, "FuseMutations", {
	Title = "Fuse Mutations",
	Icon = ICONS.flame,
	Options = MUTATION_VALUES,
	Multiple = true,
	Default = {},
})

AddDropdown(TabPets, "FuseTarget", {
	Title = "Pick Group By",
	Icon = ICONS.target,
	Options = FUSE_TARGET_VALUES,
	Default = "Highest Rarity",
})

AddToggle(TabPets, "FuseKeepMutated", {
	Title = "Never Fuse Mutated",
	Default = true,
})

AddToggle(TabPets, "FuseKeepEquipped", {
	Title = "Never Fuse Equipped",
	Default = true,
})

AddToggle(TabPets, "FuseAutoReveal", {
	Title = "Auto Complete Reveal",
	Default = true,
})

AddSlider(TabPets, "FuseMaxScale", {
	Title = "Maximum Scale to Fuse",
	Min = 0,
	Max = 10,
	Default = 10,
})

AddSlider(TabPets, "FuseKeepPerCategory", {
	Title = "Keep Per Pet Type",
	Min = 0,
	Max = 20,
	Default = 0,
})

AddSlider(TabPets, "FuseInterval", {
	Title = "Fuse Interval (s)",
	Min = 1,
	Max = 120,
	Default = 8,
})

TabPets:CreateButton({
	Title = "Fuse Now",
	Icon = ICONS.flame,
	Callback = function()
		task.spawn(function()
			F.runAutoFusePets(true)
		end)
	end,
})

TabPets:CreateSection({ Text = "Auto Sell Pets", Icon = ICONS.tags })

AddToggle(TabPets, "AutoSellPets", {
	Title = "Auto Sell Pets",
	Default = false,
})

AddDropdown(TabPets, "SellRarities", {
	Title = "Sell Rarities",
	Icon = ICONS.star,
	Options = RARITY_VALUES,
	Multiple = true,
	Default = {},
})

AddDropdown(TabPets, "SellMutations", {
	Title = "Sell Mutations",
	Icon = ICONS.flame,
	Options = MUTATION_VALUES,
	Multiple = true,
	Default = {},
})

AddToggle(TabPets, "SellKeepMutated", {
	Title = "Never Sell Mutated",
	Default = true,
})

AddToggle(TabPets, "SellKeepEquipped", {
	Title = "Never Sell Equipped",
	Default = true,
})

AddSlider(TabPets, "SellMaxScale", {
	Title = "Maximum Scale to Sell",
	Min = 0,
	Max = 10,
	Default = 10,
})

AddSlider(TabPets, "SellInterval", {
	Title = "Sell Interval (s)",
	Min = 1,
	Max = 120,
	Default = 6,
})

TabPets:CreateSection({ Text = "Auto Sell Eggs", Icon = ICONS.egg })

AddToggle(TabPets, "AutoSellEggs", {
	Title = "Auto Sell Eggs",
	Default = false,
})

AddDropdown(TabPets, "SellEggRarities", {
	Title = "Sell Rarities",
	Icon = ICONS.star,
	Options = RARITY_VALUES,
	Multiple = true,
	Default = {},
})

AddSlider(TabPets, "SellEggInterval", {
	Title = "Sell Interval (s)",
	Min = 1,
	Max = 120,
	Default = 8,
})

TabPets:CreateSection({ Text = "Earnings", Icon = ICONS.coins })

AddToggle(TabPets, "AutoClaimOffline", {
	Title = "Claim Offline Earnings",
	Default = false,
})

local TabShop = Window:CreateTab({
	Title = "Shop",
	Subtitle = "Upgrades & Gear",
	Icon = ICONS.shoppingcart,
})

TabShop:CreateSection({ Text = "Upgrades", Icon = ICONS.trendingup })

AddToggle(TabShop, "AutoUpgrades", {
	Title = "Auto Buy Upgrades",
	Default = false,
})

AddDropdown(TabShop, "UpgradeTypes", {
	Title = "Upgrades",
	Icon = ICONS.trendingup,
	Options = UPGRADE_VALUES,
	Multiple = true,
	Default = { "Base", "Treadmill" },
})

TabShop:CreateSection({ Text = "Index", Icon = ICONS.bookopen })

AddToggle(TabShop, "AutoClaimIndex", {
	Title = "Auto Claim Index",
	Default = false,
})

AddToggle(TabShop, "AutoClaimGroupReward", {
	Title = "Auto Claim Group Reward",
	Default = false,
})

TabShop:CreateSection({ Text = "Trails", Icon = ICONS.star })

AddToggle(TabShop, "AutoBuyTrail", {
	Title = "Auto Buy Trail",
	Default = false,
})

AddDropdown(TabShop, "TrailWanted", {
	Title = "Trails",
	Icon = ICONS.star,
	Options = TRAIL_VALUES,
	Multiple = true,
	Default = {},
})

AddToggle(TabShop, "AutoEquipBestTrail", {
	Title = "Auto Equip Best Trail",
	Default = false,
})

TabShop:CreateSection({ Text = "Training", Icon = ICONS.activity })

AddToggle(TabShop, "AutoTreadmill", {
	Title = "Auto Treadmill Training",
	Default = false,
})

TabShop:CreateSection({ Text = "Gear", Icon = ICONS.sword })

AddToggle(TabShop, "AutoEquipBestGear", {
	Title = "Auto Equip Best Gear",
	Default = false,
})

local TabPriority = Window:CreateTab({
	Title = "Priority",
	Subtitle = "Task Order",
	Icon = ICONS.listordered,
})

TabPriority:CreateSection({ Text = "Task Order", Icon = ICONS.listordered })

TabPriority:CreateParagraph({
	Title = "How it works",
	Icon = ICONS.info,
	Description = "The hub runs one automation task at a time. Slot 1 runs first, then slot 2 and so on. Duplicate picks are ignored.",
})

for index, slot in ipairs(PRIORITY_SLOTS) do
	AddDropdown(TabPriority, slot, {
		Title = string.format("Priority %d", index),
		Icon = ICONS.listordered,
		Options = PRIORITY_TASKS,
		Default = PRIORITY_TASKS[index],
	})
end

Window:CreateSidebarLine()
Window:CreateSeparator({ Text = "Visuals" })

local TabEsp = Window:CreateTab({
	Title = "ESP",
	Subtitle = "World Vision",
	Icon = ICONS.eye,
})

TabEsp:CreateSection({ Text = "Targets", Icon = ICONS.eye })

AddToggle(TabEsp, "EspWorldEggs", {
	Title = "World Egg ESP",
	Icon = ICONS.egg,
	Default = false,
})

AddToggle(TabEsp, "EspCarriedEggs", {
	Title = "Carried & Dropped Egg ESP",
	Icon = ICONS.egg,
	Default = false,
})

AddToggle(TabEsp, "EspGuards", {
	Title = "Guard ESP",
	Icon = ICONS.user,
	Default = false,
})

AddToggle(TabEsp, "EspPets", {
	Title = "Pet ESP",
	Icon = ICONS.bone,
	Default = false,
})

AddToggle(TabEsp, "EspPlayers", {
	Title = "Player ESP",
	Icon = ICONS.users,
	Default = false,
})

AddToggle(TabEsp, "EspMachines", {
	Title = "Machine ESP",
	Icon = ICONS.gauge,
	Default = false,
})

AddToggle(TabEsp, "EspPlots", {
	Title = "Plot ESP",
	Icon = ICONS.mappin,
	Default = false,
})

TabEsp:CreateSection({ Text = "Render", Icon = ICONS.target })

AddSlider(TabEsp, "EspDistance", {
	Title = "Render Distance (studs)",
	Min = 100,
	Max = 6000,
	Default = 2000,
})

local TabMovement = Window:CreateTab({
	Title = "Movement",
	Subtitle = "Character & Teleports",
	Icon = ICONS.move,
})

TabMovement:CreateSection({ Text = "Character", Icon = ICONS.move })

AddToggle(TabMovement, "WalkSpeedEnabled", {
	Title = "Walk Speed Override",
	Default = false,
	Callback = function(value)
		if not value then
			local humanoid = F.getHumanoid()
			if humanoid then
				humanoid.WalkSpeed = 16
			end
		end
	end,
})

AddSlider(TabMovement, "WalkSpeed", {
	Title = "Walk Speed",
	Min = 16,
	Max = 500,
	Default = 32,
})

AddToggle(TabMovement, "JumpPowerEnabled", {
	Title = "Jump Power Override",
	Default = false,
	Callback = function(value)
		if not value then
			local humanoid = F.getHumanoid()
			if humanoid then
				humanoid.JumpPower = 50
			end
		end
	end,
})

AddSlider(TabMovement, "JumpPower", {
	Title = "Jump Power",
	Min = 10,
	Max = 500,
	Default = 50,
})

AddToggle(TabMovement, "InfJump", {
	Title = "Infinite Jump",
	Default = false,
})

AddToggle(TabMovement, "NoClip", {
	Title = "NoClip",
	Default = false,
})

TabMovement:CreateSection({ Text = "Fly", Icon = ICONS.feather })

AddToggle(TabMovement, "Fly", {
	Title = "Fly",
	Description = "WASD to move, Space up, Left Ctrl down",
	Default = false,
	Callback = function(value)
		if not value then
			local humanoid = F.getHumanoid()
			if humanoid then
				humanoid.PlatformStand = false
			end
		end
	end,
})

AddSlider(TabMovement, "FlySpeed", {
	Title = "Fly Speed",
	Min = 10,
	Max = 400,
	Default = 60,
})

TabMovement:CreateSection({ Text = "Waypoints", Icon = ICONS.mappin })

AddDropdown(TabMovement, "WaypointTarget", {
	Title = "Waypoint",
	Icon = ICONS.mappin,
	Options = WAYPOINT_VALUES,
	Default = "Base",
})

TabMovement:CreateButton({
	Title = "Teleport to Waypoint",
	Icon = ICONS.mappin,
	Callback = function()
		task.spawn(function()
			local position = F.resolveWaypoint(F.optionValue("WaypointTarget", "Base"))
			if not position then
				Notify("That waypoint is not available right now")
				return
			end
			if not F.travelTo(position, true) then
				Notify("Teleport failed")
			end
		end)
	end,
})

Window:CreateSidebarLine()
Window:CreateSeparator({ Text = "Hub" })

local TabWebhook = Window:CreateTab({
	Title = "Webhook",
	Subtitle = "Discord Logging",
	Icon = ICONS.send,
})

TabWebhook:CreateSection({ Text = "Webhook", Icon = ICONS.send })

AddToggle(TabWebhook, "WebhookEnabled", {
	Title = "Enable Webhooks",
	Default = false,
})

AddTextBox(TabWebhook, "WebhookUrl", {
	Title = "Webhook URL",
	Placeholder = "https://discord.com/api/webhooks/...",
	MaxLength = 250,
	Default = "",
})

AddTextBox(TabWebhook, "WebhookPingId", {
	Title = "Ping User ID",
	Placeholder = "123456789012345678",
	MaxLength = 30,
	Default = "",
})

AddSlider(TabWebhook, "WebhookInterval", {
	Title = "Summary Interval (min)",
	Min = 1,
	Max = 180,
	Default = 15,
})

AddToggle(TabWebhook, "WebhookEggSpawns", {
	Title = "List Spawned Eggs",
	Default = true,
})

AddDropdown(TabWebhook, "WebhookRarities", {
	Title = "Rarities",
	Icon = ICONS.star,
	Options = RARITY_VALUES,
	Multiple = true,
	Default = {},
})

AddToggle(TabWebhook, "WebhookDisconnectAlerts", {
	Title = "Disconnect Alerts",
	Default = false,
})

TabWebhook:CreateButton({
	Title = "Send Summary Now",
	Icon = ICONS.send,
	Callback = function()
		task.spawn(function()
			Notify(F.sendSummary() and "Summary sent" or "Webhook send failed")
		end)
	end,
})

local TabSettings = Window:CreateTab({
	Title = "Settings",
	Subtitle = "Hub & Performance",
	Icon = ICONS.settings,
})

TabSettings:CreateSection({ Text = "Menu", Icon = ICONS.menu })

AddToggle(TabSettings, "AntiAfk", {
	Title = "Anti-AFK",
	Default = true,
})

AddToggle(TabSettings, "AntiGameplayPause", {
	Title = "No Gameplay Paused",
	Default = true,
	Callback = function(value)
		F.applyAntiGameplayPause(value)
	end,
})

AddToggle(TabSettings, "AutoHideUi", {
	Title = "Auto Hide UI",
	Description = "Hides the window right after you enable it",
	Default = false,
	Callback = function(value)
		if not value then
			return
		end
		task.defer(function()
			local frame = Window:GetMainFrame()
			if frame then
				frame.Visible = false
			end
		end)
	end,
})

AddToggle(TabSettings, "AutoReconnect", {
	Title = "Auto Reconnect",
	Default = false,
})

AddTextBox(TabSettings, "AutoExecuteUrl", {
	Title = "Auto Execute Script URL",
	Placeholder = "https://raw.githubusercontent.com/.../script.lua",
	MaxLength = 250,
	Default = "",
})

local autoExecuteConnection = nil

AddToggle(TabSettings, "AutoExecute", {
	Title = "Auto Execute",
	Description = "Re-runs the URL above after a server hop",
	Default = false,
	Callback = function(value)
		if not value then
			return
		end
		local queueTeleport = (syn and syn.queue_on_teleport) or queue_on_teleport or (fluxus and fluxus.queue_on_teleport)
		if not queueTeleport then
			Notify("queue_on_teleport is not supported by your executor")
			return
		end
		if tostring(F.optionValue("AutoExecuteUrl", "")) == "" then
			Notify("Paste the raw script URL into the box above first")
			return
		end
		if autoExecuteConnection then
			return
		end
		autoExecuteConnection = LocalPlayer.OnTeleport:Connect(function()
			local url = tostring(F.optionValue("AutoExecuteUrl", ""))
			if F.isOn("AutoExecute") and url ~= "" then
				queueTeleport('loadstring(game:HttpGet("' .. url .. '"))()')
			end
		end)
	end,
})

local MenuKeys = { Enum.KeyCode.LeftAlt }

TabSettings:CreateKeyBind({
	Title = "Menu Keybind",
	Default = Enum.KeyCode.LeftAlt,
	Callback = function(keys)
		if typeof(keys) == "table" then
			MenuKeys = keys
		end
	end,
})

TabSettings:CreateSection({ Text = "Performance", Icon = ICONS.gauge })

AddToggle(TabSettings, "FpsBoost", {
	Title = "FPS Boost",
	Default = false,
	Callback = function(value)
		F.applyFpsBoost(value)
	end,
})

AddToggle(TabSettings, "AutoDeleteOwnPets", {
	Title = "Auto Delete Own Pets",
	Default = false,
})

AddSlider(TabSettings, "FpsCap", {
	Title = "FPS Cap",
	Min = 15,
	Max = 360,
	Default = 60,
	Callback = function(value)
		F.applyFpsCap(value)
	end,
})

AddToggle(TabSettings, "DisableRendering", {
	Title = "Disable 3D Rendering",
	Default = false,
	Callback = function(value)
		F.applyRendering(value)
	end,
})

TabSettings:CreateSection({ Text = "Config", Icon = ICONS.save })

TabSettings:CreateButton({
	Title = "Export Config to Clipboard",
	Icon = ICONS.save,
	Callback = function()
		local ok, encoded = pcall(function()
			return HttpService:JSONEncode(State)
		end)
		if not ok then
			Notify("Failed to encode the config")
			return
		end
		F.copyText(encoded, "Config copied to clipboard")
	end,
})

local importBox = AddTextBox(TabSettings, "ConfigImportSource", {
	Title = "Paste exported config here",
	Placeholder = "{ ... }",
	MaxLength = 6000,
	Default = "",
})

TabSettings:CreateButton({
	Title = "Import Config",
	Icon = ICONS.save,
	Callback = function()
		local source = tostring(F.optionValue("ConfigImportSource", "")):match("^%s*(.-)%s*$")
		if source == "" then
			Notify("Paste an exported config into the box first")
			return
		end
		local ok, decoded = pcall(function()
			return HttpService:JSONDecode(source)
		end)
		if not ok or typeof(decoded) ~= "table" then
			Notify("That is not a valid exported config")
			return
		end
		local applied = 0
		for key, value in pairs(decoded) do
			if key ~= "ConfigImportSource" then
				local component = Components[key]
				if component and typeof(component.Set) == "function" then
					if pcall(function()
						component:Set(value)
					end) then
						applied += 1
					else
						State[key] = value
						applied += 1
					end
				elseif State[key] ~= nil then
					State[key] = value
					applied += 1
				end
			end
		end
		if applied == 0 then
			Notify("No settings in that config matched this script")
			return
		end
		if importBox and typeof(importBox.Set) == "function" then
			pcall(function()
				importBox:Set("")
			end)
		end
		State.ConfigImportSource = ""
		Notify(string.format("Imported %d setting%s", applied, applied == 1 and "" or "s"), 6)
	end,
})

TabSettings:CreateButton({
	Title = "Unload Hub",
	Description = "Closes VoidHub and restores your character",
	Icon = ICONS.settings,
	Confirmation = true,
	Callback = function()
		F.unload()
	end,
})

local TabInfo = Window:CreateTab({
	Title = "Info",
	Subtitle = "About & Credits",
	Icon = ICONS.info,
})

local executorName = "Unknown"
pcall(function()
	if identifyexecutor then
		local name, version = identifyexecutor()
		if type(name) == "string" and name ~= "" then
			executorName = type(version) == "string" and version ~= "" and (name .. " " .. version) or name
		end
	end
end)

TabInfo:CreateSection({ Text = "Session", Icon = ICONS.user })

TabInfo:CreateParagraph({
	Title = "Player",
	Icon = ICONS.user,
	DescriptionWords = {
		"Logged in as ",
		{ Text = LocalPlayer.Name, Colors = { Color3.fromRGB(180, 140, 255) } },
		"\nExecutor: ",
		{ Text = executorName, Colors = { Color3.fromRGB(140, 220, 170) } },
		"\nStatus: ",
		{ Text = "Keyless", Colors = { Color3.fromRGB(140, 220, 170) } },
	},
})

local SessionParagraph = TabInfo:CreateParagraph({
	Title = "Server",
	Icon = ICONS.clock,
	Description = string.format("Place ID: %s\nJob ID: %s\nSession time: 0s", tostring(game.PlaceId), shortJobIdText),
})

TabInfo:CreateButton({
	Title = "Copy Join Script",
	Description = "Copies a teleport script for this exact server",
	Icon = ICONS.server,
	Callback = function()
		local joinScript = string.format(
			'game:GetService("TeleportService"):TeleportToPlaceInstance(%d, "%s", game:GetService("Players").LocalPlayer)',
			game.PlaceId,
			jobIdText
		)
		F.copyText(joinScript, "Copied join script to clipboard")
	end,
})

TabInfo:CreateSection({ Text = "Credits", Icon = ICONS.crown })

TabInfo:CreateParagraph({
	Title = "VoidHub",
	Icon = ICONS.star,
	DescriptionWords = {
		GAME_NAME .. " Script Hub",
		"\nVersion: ",
		{ Text = HUB_VERSION, Colors = { Color3.fromRGB(180, 140, 255) } },
		"\nMade with care for the community.",
	},
})

TabInfo:CreateParagraph({
	Title = "Credits",
	Icon = ICONS.heart,
	DescriptionWords = {
		{ Text = "Credits: von63rd", Colors = { Color3.fromRGB(255, 50, 50) } },
		"\nScript Developer & Designer",
	},
})

TabInfo:CreateSection({ Text = "Community", Icon = ICONS.globe })

TabInfo:CreateDiscordInvite({
	Title = "VoidHub Community",
	Description = "Join for updates, support & more!",
	Icon = HUB_ICON,
	Banner = HUB_ICON,
	Link = DISCORD_INVITE,
	Button = "Join Discord",
})

TabInfo:CreateParagraph({
	Title = "Quick Tips",
	Icon = ICONS.charge,
	Description = "- Auto Steal Selected uses the filters, Auto Steal All ignores them\n- Auto Return carries stolen eggs home for you\n- The Priority tab decides which task runs first\n- Server Hop can farm fresh eggs while you are away\n- Configs save on their own, or export them from Settings",
})

--// Runtime

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

local renderOverlay = nil
local renderRows = {}

local RENDER_ROWS = {
	"money",
	"speed",
	"pets",
	"eggs",
	"stolen",
	"session",
}

F.destroyRenderOverlay = function()
	if renderOverlay then
		pcall(function()
			renderOverlay:Destroy()
		end)
	end
	renderOverlay = nil
	table.clear(renderRows)
end

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
	backdrop.BackgroundColor3 = Color3.fromRGB(12, 10, 18)
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
	title.Text = HUB_NAME .. " | " .. GAME_NAME
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
		row.TextColor3 = Color3.fromRGB(130, 124, 150)
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
	pcall(function()
		RunService:Set3dRenderingEnabled(not disabled)
	end)
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
			Notify("FPS cap is not supported by your executor")
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

local menuKeyConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if Unloaded or gameProcessed then
		return
	end
	for _, key in ipairs(MenuKeys) do
		if input.KeyCode == key then
			local frame = Window:GetMainFrame()
			if frame then
				frame.Visible = not frame.Visible
			end
			break
		end
	end
end)

local steppedConnection = RunService.Stepped:Connect(function()
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

local jumpConnection = UserInputService.JumpRequest:Connect(function()
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

local renderConnection = RunService.RenderStepped:Connect(function(dt)
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

local characterConnection = LocalPlayer.CharacterAdded:Connect(function()
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
		if F.isOn("AntiGameplayPause") then
			F.applyAntiGameplayPause(true)
		end
		if F.isOn("DisableRendering") then
			pcall(F.updateRenderOverlay)
		elseif renderOverlay then
			pcall(F.destroyRenderOverlay)
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

task.spawn(function()
	while not Unloaded do
		task.wait(1)
		pcall(function()
			SessionParagraph:SetDescription(string.format(
				"Place ID: %s\nJob ID: %s\nSession time: %s",
				tostring(game.PlaceId),
				shortJobIdText,
				F.formatClock(os.clock() - sessionStart)
			))
		end)
	end
end)

F.unload = function()
	if Unloaded then
		return
	end
	Unloaded = true
	pcall(F.applyAntiGameplayPause, false)
	pcall(F.applyRendering, false)
	pcall(F.applyFpsBoost, false)
	pcall(F.destroyRenderOverlay)
	pcall(F.stopTreadmillTraining)
	pcall(F.clearAllEsp)
	pcall(function()
		espFolder:Destroy()
	end)
	for _, connection in ipairs({
		antiAfkBeganConnection,
		antiAfkChangedConnection,
		menuKeyConnection,
		steppedConnection,
		jumpConnection,
		renderConnection,
		characterConnection,
		carryConnection,
		hopFailConnection,
		autoExecuteConnection,
	}) do
		pcall(function()
			connection:Disconnect()
		end)
	end
	autoExecuteConnection = nil
	local humanoid = F.getHumanoid()
	if humanoid then
		pcall(function()
			humanoid.PlatformStand = false
			humanoid.WalkSpeed = 16
			humanoid.JumpPower = 50
		end)
	end
	if getgenv then
		getgenv().VoidHubStealAnEgg = nil
	end
	pcall(function()
		Window:Destroy()
	end)
end

-- Pull saved values back into the runtime state once AutoLoad has settled.
task.delay(1.5, function()
	if Unloaded then
		return
	end
	for name, component in pairs(Components) do
		if typeof(component) == "table" and typeof(component.Get) == "function" then
			local ok, value = pcall(component.Get, component)
			if ok and value ~= nil then
				State[name] = value
			end
		end
	end
	State.ConfigImportSource = ""
	if F.isOn("AntiGameplayPause") then
		F.applyAntiGameplayPause(true)
	end
	if F.isOn("FpsBoost") then
		F.applyFpsBoost(true)
	end
	if F.isOn("DisableRendering") then
		F.applyRendering(true)
	end
	F.applyFpsCap(F.optionValue("FpsCap", 60))
end)

Window:Notify({
	Title = "VoidHub Ready",
	Text = "All systems initialized. Good luck!",
	Duration = 4,
	ColoredWords = {
		{ Text = "VoidHub", Colors = { Color3.fromRGB(180, 140, 255) } },
	},
})
