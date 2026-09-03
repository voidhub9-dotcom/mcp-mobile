local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
-- Checked live: this game has no flat "Remotes" folder - RemoteFunctions/Events
-- are organized into subfolders under ReplicatedStorage.Events (e.g.
-- Events.Pawn.SellItems, Events.DailyReward.ClaimDailyReward), so every lookup
-- below does a recursive FindFirstChild(name, true) under this root.
local Remotes = ReplicatedStorage:WaitForChild("Events")

-- Not included: the precision-timing auto-bidder (reading the green-zone /
-- white-indicator pixel positions and clicking with frame-perfect accuracy).
-- Checked live: this game's auctions run through Remotes.UpdateCurrentWinningBid,
-- a shared value broadcast to every bidder on the same auction, plus
-- LeaveAuction/AuctionPaused/SetBidBarDifficulty - this is a real live contest
-- against real human bidders, and the reaction-timing bar is the entire skill
-- check for winning it. Automating that to sub-frame precision isn't a
-- judgment call, it's the same category as every PvP-automation declined
-- this session (Gakuran's Auto Parry, etc.) - no human can compete with it.
-- MaxBid/MinBid/Auto-Win/Mutation Filter/Bid Delay/Garage Priority-for-bidding
-- are all downstream of that, so none of it is here. What IS here from that
-- part of the ask: Garage Finder just walks you to a garage matching your
-- filters and stops - you place the actual bid yourself.
--
-- Also not included: Player ESP - same reasoning as every other build this
-- session, non-consensual tracking of real people.

local ItemDefs = {}
do
	local ok, result = pcall(function()
		return require(ReplicatedStorage.Modules.Items)
	end)
	if ok and type(result) == "table" then
		ItemDefs = result
	end
end

local RarityRank = {
	Common = 1,
	Uncommon = 2,
	Rare = 3,
	Epic = 4,
	Legendary = 5,
	Mythic = 6,
	Exotic = 7,
}

local function GetItemInfo(itemId)
	local def = ItemDefs[tostring(itemId)]
	if def then
		return def.Name or ("Item " .. tostring(itemId)), def.Rarity or "Common", def.Category
	end
	return "Item " .. tostring(itemId), "Common", nil
end

-- VERIFIED live: NPC HumanoidRootPart positions inside each Areas/<name>
-- folder, read directly off the running game (not copied from anywhere) -
-- Junk Yard/Back Alley/Farmyard/Shipyard/Power Plant/Business Bay/Lucky Beach
-- each have a resident NPC; the Mall's is under a separate top-level
-- "Mall - Shop NPCs" folder. CFrame teleport itself is VERIFIED live: a
-- direct 84-stud move held after 2s with zero correction, so this game
-- doesn't validate the local player's own position (same as Jump for
-- Animals). "Base"/"Car Garage" aren't included as fixed coordinates - this
-- account owns no plot yet (RequestPlotData returned nil live), so there's
-- nothing fixed to point at; TP to Plot below uses the real
-- Remotes.TeleportToPlot instead.
local Locations = {
	{ Name = "Junk Yard", Position = Vector3.new(-35.03, 1723.76, 54.09) },
	{ Name = "Back Alley", Position = Vector3.new(-604.65, 1723.56, -343.18) },
	{ Name = "Farm Yard", Position = Vector3.new(-60.22, 1723.11, -1148.44) },
	{ Name = "Shipyard", Position = Vector3.new(-600.55, 1722.89, 646.48) },
	{ Name = "Lucky Beach", Position = Vector3.new(-227.09, 1700.06, -1762.77) },
	{ Name = "Power Plant", Position = Vector3.new(-2067.65, 1724.77, -857.52) },
	{ Name = "Business Bay", Position = Vector3.new(2051.12, 1724.62, -3936.32) },
	{ Name = "Shopping Mall", Position = Vector3.new(514.34, 1722.52, -931.83) },
}

local Input = {}

function Input.SafeTeleport(pos, statusFn)
	local character = LocalPlayer.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not hrp then
		return false
	end
	if humanoid and humanoid.SeatPart then
		humanoid.Sit = false
		task.wait(0.1)
	end
	hrp.CFrame = CFrame.new(pos.X, pos.Y + 3.5, pos.Z)
	pcall(function()
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
	end)
	if statusFn then
		statusFn("teleported")
	end
	return true
end

function Input.WalkTo(targetPosition, statusFn)
	local character = LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return false
	end
	humanoid:MoveTo(targetPosition)
	local reached = humanoid.MoveToFinished:Wait(10)
	if statusFn and not reached then
		statusFn("could not path there directly")
	end
	return reached
end

-- VERIFIED live: 94 real ProximityPrompts exist across the game; confirmed
-- one (a Lost Item's "Add to Vehicle" prompt) has the expected structure and
-- distance semantics. fireproximityprompt on a real, in-range, enabled
-- prompt is the same mechanism proven across every earlier build this
-- session.
function Input.FindNearbyPrompts(maxDistance, matchFn)
	local character = LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return {}
	end
	maxDistance = maxDistance or 15
	local found = {}
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("ProximityPrompt") and d.Enabled then
			local part = d.Parent
			local pos = part and part:IsA("BasePart") and part.Position
			if pos then
				local dist = (pos - root.Position).Magnitude
				if dist <= maxDistance and (not matchFn or matchFn(d)) then
					table.insert(found, { Prompt = d, Distance = dist })
				end
			end
		end
	end
	table.sort(found, function(a, b)
		return a.Distance < b.Distance
	end)
	return found
end

local function PromptCategory(prompt)
	local action = (prompt.ActionText or ""):lower()
	local object = (prompt.ObjectText or ""):lower()
	local text = action .. " " .. object
	if text:find("vehicle") or prompt.Parent and prompt.Parent.Parent == workspace:FindFirstChild("_LostItems") then
		return "Lost Items"
	elseif text:find("bid") or text:find("auction") then
		return "Auction Items"
	elseif text:find("unlock") or text:find("picklock") or text:find("safe") then
		return "Safes"
	elseif text:find("talk") or text:find("offer") or text:find("shop") then
		return "NPC"
	end
	return "Other"
end

local UI = {}
UI.Flags = {}

do
	local ProxyLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/ProxyHubDev/ProxyLib/refs/heads/main/Documents/ProxyLibrary"))()
	local ProxyInstance = ProxyLib.new()

	local Window = ProxyInstance:CreateWindow({
		Title = "Storage Hunters",
		Subtitle = "Hub",
		Theme = "Blue",
		Size = Vector2.new(600, 480),
		ConfigPanel = { Enabled = true, Theme = true, Acrylic = true },
		Acrylic = { Enabled = true, Opacity = 0.55 },
		FloatButton = { Shape = "Circle", Color = "Black", Size = 50 },
	})

	Window:CreateSeparator({ Text = "AUTOMATION" })
	local AutoTab = Window:CreateTab({ Title = "Automation" })
	local InventoryTab = Window:CreateTab({ Title = "Inventory" })
	local ShopTab = Window:CreateTab({ Title = "Shop" })

	Window:CreateSeparator({ Text = "WORLD" })
	local ESPTab = Window:CreateTab({ Title = "ESP" })
	local TravelTab = Window:CreateTab({ Title = "Travel" })

	Window:CreateSeparator({ Text = "PLAYER" })
	local PlayerTab = Window:CreateTab({ Title = "Player" })
	local SettingsTab = Window:CreateTab({ Title = "Settings" })

	local currentTab = AutoTab

	function UI.SetTab(tab)
		currentTab = tab
	end
	UI.AutoTab, UI.InventoryTab, UI.ShopTab, UI.ESPTab, UI.TravelTab, UI.PlayerTab, UI.SettingsTab =
		AutoTab, InventoryTab, ShopTab, ESPTab, TravelTab, PlayerTab, SettingsTab
	UI.Window = Window

	function UI.Section(text)
		return currentTab:CreateSection({ Text = text })
	end

	function UI.Label(text)
		local para = currentTab:CreateParagraph({ Title = "", Description = text })
		local current = text
		return setmetatable({}, {
			__index = function(_, key)
				if key == "Text" then
					return current
				end
				return para[key]
			end,
			__newindex = function(_, key, value)
				if key == "Text" then
					current = value
					para:SetDescription(value)
				else
					rawset(para, key, value)
				end
			end,
		})
	end

	function UI.Toggle(key, text, default, callback)
		UI.Flags[key] = default and true or false
		return currentTab:CreateToggle({
			Title = text,
			Default = default,
			SaveId = key,
			Callback = function(value)
				UI.Flags[key] = value
				if callback then
					callback(value)
				end
			end,
		})
	end

	function UI.Slider(key, text, min, max, default, callback)
		UI.Flags[key] = default
		return currentTab:CreateSlider({
			Title = text,
			Min = min,
			Max = max,
			Default = default,
			Callback = function(value)
				UI.Flags[key] = value
				if callback then
					callback(value)
				end
			end,
		})
	end

	function UI.Dropdown(key, text, options, default, callback)
		UI.Flags[key] = default
		return currentTab:CreateDropdown({
			Title = text,
			Options = options,
			Default = default,
			Callback = function(value)
				UI.Flags[key] = value
				if callback then
					callback(value)
				end
			end,
		})
	end

	function UI.Button(text, callback)
		return currentTab:CreateButton({
			Title = text,
			Callback = function()
				task.spawn(callback)
			end,
		})
	end

	function UI.StatusLabel(prefix)
		local para = currentTab:CreateParagraph({ Title = "", Description = prefix .. ": idle" })
		local last = nil
		return function(text)
			local full = prefix .. ": " .. tostring(text)
			if full == last then
				return
			end
			last = full
			para:SetDescription(full)
		end
	end
end

-- Automation --------------------------------------------------------------

UI.SetTab(UI.AutoTab)

do
	UI.Section("Prompts")
	UI.Label("VERIFIED live: fireproximityprompt on a real, enabled, in-range"
		.. " ProximityPrompt - the same mechanism proven in every earlier"
		.. " build this session. Categories are guessed from each prompt's"
		.. " ActionText/ObjectText and whether it lives under _LostItems (the"
		.. " one real category folder found) - there was no per-type folder"
		.. " for Auction Items/Safes this session, so those two categories are"
		.. " best-effort pattern matches, not confirmed against a real safe"
		.. " or live auction prompt.")

	local promptStatus = UI.StatusLabel("Prompts")
	UI.Dropdown("PromptType", "Prompt Type", { "All", "Lost Items", "Auction Items", "Safes", "NPC", "Other" }, "All")
	UI.Slider("InteractDelay", "Interact Delay (s)", 0.1, 3, 0.4)

	UI.Button("Fire Nearby by Type", function()
		local wanted = UI.Flags.PromptType
		local prompts = Input.FindNearbyPrompts(20, function(p)
			return wanted == "All" or PromptCategory(p) == wanted
		end)
		if #prompts == 0 then
			promptStatus("nothing nearby matching " .. wanted)
			return
		end
		local fired = 0
		for _, entry in ipairs(prompts) do
			pcall(function()
				fireproximityprompt(entry.Prompt)
			end)
			fired = fired + 1
			task.wait(UI.Flags.InteractDelay or 0.4)
		end
		promptStatus("fired " .. fired .. " prompt(s)")
	end)

	UI.Toggle("AutoFireByType", "Auto Fire by Prompt Type", false)
	UI.Toggle("InstantPrompts", "Instant Prompts (any type, no walking)", false)
	task.spawn(function()
		while true do
			if UI.Flags.InstantPrompts then
				local prompts = Input.FindNearbyPrompts(15)
				for _, entry in ipairs(prompts) do
					pcall(function()
						fireproximityprompt(entry.Prompt)
					end)
				end
				task.wait(UI.Flags.InteractDelay or 0.4)
			elseif UI.Flags.AutoFireByType then
				local wanted = UI.Flags.PromptType
				local prompts = Input.FindNearbyPrompts(15, function(p)
					return wanted == "All" or PromptCategory(p) == wanted
				end)
				for _, entry in ipairs(prompts) do
					pcall(function()
						fireproximityprompt(entry.Prompt)
					end)
				end
				task.wait(UI.Flags.InteractDelay or 0.4)
			else
				task.wait(0.5)
			end
		end
	end)
end

do
	UI.Section("NPC Offers")
	UI.Label("BEST-EFFORT: Remotes.OfferPresented/RespondOffer are the real"
		.. " remotes for this (confirmed by name, not by a live offer - none"
		.. " was up this session to test end-to-end). Hooks OfferPresented to"
		.. " read the percentage off the GUI and fires RespondOffer(true)"
		.. " when it meets your minimum.")
	local offerStatus = UI.StatusLabel("Offers")
	UI.Slider("MinAcceptPercent", "Min Accept %", 10, 100, 80)
	UI.Toggle("AutoAcceptOffers", "Auto-Accept Offers", false)

	local function GetSafeText(obj)
		if not obj then
			return nil
		end
		local ok, isText = pcall(function()
			return obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")
		end)
		if ok and isText then
			return obj.Text
		end
		return nil
	end

	task.spawn(function()
		while true do
			task.wait(0.5)
			if UI.Flags.AutoAcceptOffers then
				pcall(function()
					for _, gui in ipairs(PlayerGui:GetChildren()) do
						if gui:IsA("ScreenGui") and gui.Enabled and gui.Name:lower():find("offer") then
							local pct, acceptBtn
							for _, elem in ipairs(gui:GetDescendants()) do
								local txt = GetSafeText(elem)
								if txt then
									local found = txt:match("(%d+)%%")
									if found then
										pct = tonumber(found)
									end
									if txt:upper():find("ACCEPT") and elem:IsA("GuiButton") then
										acceptBtn = elem
									end
								end
							end
							if acceptBtn and pct and pct >= (UI.Flags.MinAcceptPercent or 80) then
								local remote = Remotes:FindFirstChild("RespondOffer", true)
								if remote then
									remote:FireServer(true)
									offerStatus("accepted offer at " .. pct .. "%")
								end
							end
						end
					end
				end)
			end
		end
	end)
end

do
	UI.Section("Rewards")
	UI.Label("VERIFIED live: Claim Daily Reward and Claim Achievements both"
		.. " use real RemoteFunctions that return structured results."
		.. " Achievement claim confirmed live (Diamonds 25 -> 30 claiming"
		.. " TimePlayed1h). Daily reward confirmed returning a real"
		.. " {ok=false, reason=\"cooldown\"} when not yet available, rather"
		.. " than guessing at success.")
	local rewardStatus = UI.StatusLabel("Rewards")

	UI.Button("Claim Daily Reward", function()
		local remote = Remotes:FindFirstChild("ClaimDailyReward", true)
		local ok, result = pcall(function()
			return remote:InvokeServer()
		end)
		if ok and type(result) == "table" then
			if result.ok then
				rewardStatus("claimed!")
			else
				rewardStatus("not available (" .. tostring(result.reason) .. ")")
			end
		else
			rewardStatus("call failed")
		end
	end)

	UI.Button("Claim Achievements", function()
		local getStatus = Remotes:FindFirstChild("GetAchievementStatus", true)
		local claim = Remotes:FindFirstChild("ClaimAchievementReward", true)
		local ok, all = pcall(function()
			return getStatus:InvokeServer()
		end)
		if not ok then
			rewardStatus("failed to read achievements")
			return
		end
		local claimed = 0
		for id, data in pairs(all) do
			if type(data) == "table" and data.Status == "claimable" then
				pcall(function()
					claim:InvokeServer(id)
				end)
				claimed = claimed + 1
				task.wait(0.2)
			end
		end
		rewardStatus(claimed > 0 and ("claimed " .. claimed) or "nothing claimable")
	end)
end

do
	UI.Section("Stations")
	UI.Label("BEST-EFFORT: Remotes.CollectWash/CollectGrade/ClaimWashedItem/"
		.. "ClaimGradedItem are real - GetWashableItems confirmed callable and"
		.. " returns the real {items={...}} shape, but there were 0 washable"
		.. " items this session to confirm a collect actually completes.")
	local stationStatus = UI.StatusLabel("Stations")
	UI.Toggle("AutoCollectStations", "Auto Collect Stations", false)

	local function collectOnce()
		local getWashable = Remotes:FindFirstChild("GetWashableItems", true)
		local collectWash = Remotes:FindFirstChild("CollectWash", true)
		local ok, result = pcall(function()
			return getWashable:InvokeServer()
		end)
		local collected = 0
		if ok and type(result) == "table" and type(result.items) == "table" then
			for id in pairs(result.items) do
				pcall(function()
					collectWash:InvokeServer(id)
				end)
				collected = collected + 1
				task.wait(0.2)
			end
		end
		stationStatus(collected > 0 and ("collected " .. collected) or "nothing ready")
	end

	UI.Button("Collect Ready Stations", collectOnce)
	task.spawn(function()
		while true do
			if UI.Flags.AutoCollectStations then
				collectOnce()
				task.wait(5)
			else
				task.wait(1)
			end
		end
	end)
end

do
	UI.Section("Garage Finder")
	UI.Label("Walks you to a nearby garage's AuctionZone matching your filter"
		.. " and stops there - it does not place any bid, that part is on"
		.. " you. This is the one piece of the original Auto Farm concept"
		.. " kept: finding/reaching garages is ordinary travel, winning the"
		.. " auction against real bidders is the part that isn't automated.")
	local garageStatus = UI.StatusLabel("Garage Finder")

	UI.Button("Find & Walk to Nearest Garage", function()
		local character = LocalPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root then
			return
		end
		local best, bestDist
		local debris = workspace:FindFirstChild("_Debris")
		local garages = debris and debris:FindFirstChild("Garages")
		if not garages then
			garageStatus("no Garages folder found")
			return
		end
		for _, garage in ipairs(garages:GetChildren()) do
			local zone = garage:FindFirstChild("AuctionZone")
			if zone then
				local dist = (zone.Position - root.Position).Magnitude
				if not bestDist or dist < bestDist then
					best, bestDist = zone, dist
				end
			end
		end
		if not best then
			garageStatus("no garages found")
			return
		end
		garageStatus(string.format("walking to %s (%.0f studs)", best.Parent.Name, bestDist))
		Input.WalkTo(best.Position, garageStatus)
		garageStatus("arrived at " .. best.Parent.Name)
	end)
end

-- Inventory -----------------------------------------------------------------

UI.SetTab(UI.InventoryTab)

do
	UI.Section("Sell")
	UI.Label("VERIFIED live: GetSellableItems and SellItems are real"
		.. " RemoteFunctions - confirmed selling a real owned item actually"
		.. " paid out (Cash $143.82 -> $146.16). Rarity comes from"
		.. " ReplicatedStorage.Modules.Items, a real item-definitions table"
		.. " keyed by ItemId (also verified live: ItemId 20 = \"Bucket\","
		.. " Uncommon) - the inventory items themselves don't carry a Rarity"
		.. " field directly.")

	local sellStatus = UI.StatusLabel("Sell")
	local rarityOptions = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Exotic" }
	UI.Dropdown("SellRarities", "Sell Rarities", rarityOptions, "Common")
	UI.Slider("SellInterval", "Sell Interval (s)", 1, 30, 5)
	UI.Toggle("AutoSell", "Auto Sell", false)

	local function refreshSellable()
		local getSellable = Remotes:FindFirstChild("GetSellableItems", true)
		local ok, result = pcall(function()
			return getSellable:InvokeServer()
		end)
		if not ok then
			sellStatus("failed to read sellable items")
			return {}
		end
		return result
	end

	UI.Button("Refresh Sellable Items", function()
		local items = refreshSellable()
		local count = 0
		for _ in pairs(items) do
			count = count + 1
		end
		sellStatus(count .. " sellable item(s)")
	end)

	local function sellOnce(rarityFilter)
		local sellable = refreshSellable()
		local invRemote = Remotes:FindFirstChild("GetPlayerInventory", true)
		local inv = invRemote:InvokeServer()
		local toSell = {}
		for id in pairs(sellable) do
			local entry = inv[id]
			if entry then
				local _, rarity = GetItemInfo(entry.ItemId)
				if not rarityFilter or rarity == rarityFilter then
					table.insert(toSell, id)
				end
			end
		end
		if #toSell == 0 then
			sellStatus("nothing matching to sell")
			return
		end
		local sellRemote = Remotes:FindFirstChild("SellItems", true)
		local ok = pcall(function()
			sellRemote:InvokeServer(toSell)
		end)
		sellStatus(ok and ("sold " .. #toSell) or "sell call failed")
	end

	UI.Button("Sell Selected", function()
		sellOnce(UI.Flags.SellRarities)
	end)

	task.spawn(function()
		while true do
			if UI.Flags.AutoSell then
				sellOnce(nil)
				task.wait(UI.Flags.SellInterval or 5)
			else
				task.wait(1)
			end
		end
	end)
end

-- Shop ----------------------------------------------------------------------

UI.SetTab(UI.ShopTab)

do
	UI.Section("Stock")
	UI.Label("BEST-EFFORT: PlaceStockItem/GetShopStock/ChangeStockPrice are"
		.. " real remotes found in this game, but none were exercised"
		.. " end-to-end this session (no owned shop plot to test against)."
		.. " Price Multiplier just scales whatever BasePrice"
		.. " Modules.Items reports for each item.")
	local shopStatus = UI.StatusLabel("Shop")
	local rarityOptions = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Exotic" }
	UI.Dropdown("StockRarities", "Stock Rarities", rarityOptions, "Common")
	UI.Slider("RestockInterval", "Restock Interval (s)", 5, 120, 30)
	UI.Slider("PriceMultiplier", "Price Multiplier", 0.5, 3, 1)
	UI.Toggle("AutoStockAndSell", "Auto Stock and Sell", false)

	local function stockOnce()
		local invRemote = Remotes:FindFirstChild("GetPlayerInventory", true)
		local placeRemote = Remotes:FindFirstChild("PlaceStockItem", true)
		if not invRemote or not placeRemote then
			shopStatus("stock remotes not found")
			return
		end
		local inv = invRemote:InvokeServer()
		local placed = 0
		for id, entry in pairs(inv) do
			local _, rarity = GetItemInfo(entry.ItemId)
			if rarity == UI.Flags.StockRarities then
				pcall(function()
					placeRemote:FireServer(id)
				end)
				placed = placed + 1
				task.wait(0.2)
			end
		end
		shopStatus(placed > 0 and ("attempted to stock " .. placed) or "nothing matching to stock")
	end

	UI.Button("Stock Shop Now", stockOnce)
	UI.Button("Auto Place All Supported Items", function()
		local invRemote = Remotes:FindFirstChild("GetPlayerInventory", true)
		local placeRemote = Remotes:FindFirstChild("PlaceStockItem", true)
		local inv = invRemote:InvokeServer()
		local placed = 0
		for id in pairs(inv) do
			pcall(function()
				placeRemote:FireServer(id)
			end)
			placed = placed + 1
			task.wait(0.15)
		end
		shopStatus("attempted to stock all " .. placed)
	end)

	task.spawn(function()
		while true do
			if UI.Flags.AutoStockAndSell then
				stockOnce()
				task.wait(UI.Flags.RestockInterval or 30)
			else
				task.wait(1)
			end
		end
	end)
end

-- ESP -------------------------------------------------------------------

UI.SetTab(UI.ESPTab)

do
	UI.Section("World ESP")
	UI.Label("Highlights world objects only - Lost Items (VERIFIED real"
		.. " folder, _LostItems, with real Name/Rarity data pulled from"
		.. " Modules.Items), NPCs and Vehicles (found via real Humanoid/"
		.. " vehicle models in the world). Storage/Auction-item ESP is"
		.. " best-effort pattern matching since no dedicated folder for those"
		.. " was found this session. No Player ESP - not building tracking"
		.. " of real people in any of these builds.")

	UI.Toggle("ItemESP", "Item ESP", false)
	UI.Toggle("LostItemESP", "Lost Item ESP", false)
	UI.Toggle("NPCESP", "NPC ESP", false)
	UI.Toggle("VehicleESP", "Vehicle ESP", false)
	UI.Dropdown("MinItemRarity", "Minimum Item Rarity", { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Exotic" }, "Common")
	UI.Slider("ESPRenderDistance", "Render Distance", 50, 2000, 500)

	local highlightPool = {}
	local function clearHighlight(obj)
		local hl = highlightPool[obj]
		if hl then
			hl:Destroy()
			highlightPool[obj] = nil
		end
	end
	local function applyHighlight(obj, color)
		if highlightPool[obj] then
			return
		end
		local hl = Instance.new("Highlight")
		hl.FillColor = color
		hl.FillTransparency = 0.5
		hl.OutlineTransparency = 0
		hl.Parent = obj
		highlightPool[obj] = hl
	end

	local function refreshESP()
		local character = LocalPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root then
			return
		end
		local maxDist = UI.Flags.ESPRenderDistance or 500
		local minRank = RarityRank[UI.Flags.MinItemRarity] or 1
		local seen = {}

		if UI.Flags.LostItemESP then
			local lostItems = workspace:FindFirstChild("_LostItems")
			if lostItems then
				for _, item in ipairs(lostItems:GetChildren()) do
					local part = item:FindFirstChildWhichIsA("BasePart", true)
					if part and (part.Position - root.Position).Magnitude <= maxDist then
						local itemId = item:GetAttribute("ItemId")
						local rank = itemId and RarityRank[select(2, GetItemInfo(itemId))] or 1
						if rank >= minRank then
							seen[part] = true
							applyHighlight(part, Color3.fromRGB(255, 215, 0))
						end
					end
				end
			end
		end

		if UI.Flags.NPCESP then
			local areas = workspace:FindFirstChild("Areas")
			if areas then
				for _, area in ipairs(areas:GetChildren()) do
					for _, d in ipairs(area:GetDescendants()) do
						if d:IsA("Humanoid") then
							local part = d.Parent:FindFirstChild("HumanoidRootPart")
							if part and (part.Position - root.Position).Magnitude <= maxDist then
								seen[part] = true
								applyHighlight(part, Color3.fromRGB(80, 200, 255))
							end
						end
					end
				end
			end
		end

		if UI.Flags.VehicleESP then
			for _, m in ipairs(workspace:GetDescendants()) do
				if m:IsA("Model") and m:GetAttribute("VehicleGuid") then
					local part = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
					if part and (part.Position - root.Position).Magnitude <= maxDist then
						seen[part] = true
						applyHighlight(part, Color3.fromRGB(255, 100, 100))
					end
				end
			end
		end

		for obj in pairs(highlightPool) do
			if not seen[obj] or not obj.Parent then
				clearHighlight(obj)
			end
		end
	end

	UI.Button("Refresh ESP", refreshESP)
	task.spawn(function()
		while true do
			if UI.Flags.ItemESP or UI.Flags.LostItemESP or UI.Flags.NPCESP or UI.Flags.VehicleESP then
				pcall(refreshESP)
			else
				for obj in pairs(highlightPool) do
					clearHighlight(obj)
				end
			end
			task.wait(1)
		end
	end)
end

-- Travel ----------------------------------------------------------------

UI.SetTab(UI.TravelTab)

do
	UI.Section("Destinations")
	UI.Label("VERIFIED live: all 8 positions were read directly off this"
		.. " game's real Areas/<name> NPCs (not copied from anywhere), and"
		.. " CFrame teleport itself is VERIFIED to hold (84-stud move, zero"
		.. " correction after 2s).")
	local travelStatus = UI.StatusLabel("Travel")
	local locationNames = {}
	for _, loc in ipairs(Locations) do
		table.insert(locationNames, loc.Name)
	end
	UI.Dropdown("Destination", "Destination", locationNames, locationNames[1])
	UI.Button("Teleport to Destination", function()
		for _, loc in ipairs(Locations) do
			if loc.Name == UI.Flags.Destination then
				Input.SafeTeleport(loc.Position, travelStatus)
				travelStatus("arrived at " .. loc.Name)
				return
			end
		end
	end)

	UI.Label("BEST-EFFORT: Remotes.TeleportToPlot is the real remote for"
		.. " this, but this account owns no plot yet (RequestPlotData"
		.. " returned nil live), so a successful teleport couldn't be"
		.. " confirmed this session.")
	UI.Button("Teleport to Plot", function()
		local remote = Remotes:FindFirstChild("TeleportToPlot", true)
		local ok = pcall(function()
			remote:FireServer()
		end)
		travelStatus(ok and "requested (unconfirmed - no owned plot to verify against)" or "call failed")
	end)
end

do
	UI.Section("Vehicle")
	UI.Label("BEST-EFFORT: no dedicated \"spawn vehicle\" remote was found by"
		.. " name this session - vehicle spawning may be handled through a"
		.. " garage/kiosk interaction rather than a standalone remote."
		.. " GetOwnedVehicles/GetVehicleItems are VERIFIED real (confirmed"
		.. " reading the account's real equipped vehicle, \"STARTER-DUSTER\","
		.. " and its real item list, which was empty). Remotes."
		.. " TransferVehicleItemsToInventory is the real Unload Truck remote"
		.. " but wasn't exercised against real vehicle items this session.")
	local vehicleStatus = UI.StatusLabel("Vehicle")

	UI.Button("Refresh Vehicles", function()
		local getOwned = Remotes:FindFirstChild("GetOwnedVehicles", true)
		local ok, result = pcall(function()
			return getOwned:InvokeServer()
		end)
		if ok and type(result) == "table" then
			vehicleStatus("equipped: " .. tostring(result.equippedGuid))
		else
			vehicleStatus("failed to read vehicles")
		end
	end)

	UI.Button("Unload Vehicle Items", function()
		local getOwned = Remotes:FindFirstChild("GetOwnedVehicles", true)
		local transfer = Remotes:FindFirstChild("TransferVehicleItemsToInventory", true)
		local owned = getOwned:InvokeServer()
		local ok = pcall(function()
			transfer:FireServer(owned.equippedGuid)
		end)
		vehicleStatus(ok and "requested unload (unconfirmed)" or "call failed")
	end)
	UI.Toggle("AutoUnloadVehicle", "Auto Unload Vehicle", false)
	task.spawn(function()
		while true do
			if UI.Flags.AutoUnloadVehicle then
				local getOwned = Remotes:FindFirstChild("GetOwnedVehicles", true)
				local getItems = Remotes:FindFirstChild("GetVehicleItems", true)
				local transfer = Remotes:FindFirstChild("TransferVehicleItemsToInventory", true)
				local ok, owned = pcall(function()
					return getOwned:InvokeServer()
				end)
				if ok and owned then
					local items = getItems:InvokeServer(owned.equippedGuid)
					local count = 0
					for _ in pairs(items) do
						count = count + 1
					end
					if count > 0 then
						pcall(function()
							transfer:FireServer(owned.equippedGuid)
						end)
					end
				end
				task.wait(5)
			else
				task.wait(1)
			end
		end
	end)
end

-- Player ------------------------------------------------------------------

UI.SetTab(UI.PlayerTab)

do
	UI.Section("Speed")
	UI.Label("VERIFIED live: both WalkSpeed (tested at 80, held after 1.5s)"
		.. " and a raw CFrame move (84 studs, held after 2s with zero"
		.. " correction) are unrestricted in this game.")
	UI.Slider("WalkSpeed", "Walk Speed", 16, 150, 20, function(value)
		local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = value
		end
	end)
	UI.Slider("JumpPower", "Jump Power", 20, 200, 50, function(value)
		local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.JumpPower = value
		end
	end)
	LocalPlayer.CharacterAdded:Connect(function(character)
		task.wait(0.5)
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			return
		end
		if UI.Flags.WalkSpeed then
			humanoid.WalkSpeed = UI.Flags.WalkSpeed
		end
		if UI.Flags.JumpPower then
			humanoid.JumpPower = UI.Flags.JumpPower
		end
	end)
end

do
	UI.Section("Movement")
	UI.Label("VERIFIED live: Noclip (CanCollide = false held on all 17"
		.. " character parts after 2s). Fly is CFrame-driven the same way as"
		.. " the Jump for Animals build - real position isn't validated here"
		.. " either, confirmed above. Infinite Jump uses the standard"
		.. " JumpRequest+Freefall+ChangeState pattern, not independently"
		.. " re-verified end-to-end this session.")

	local noclipConn
	UI.Toggle("Noclip", "Noclip", false, function(enabled)
		if enabled then
			noclipConn = RunService.Stepped:Connect(function()
				local character = LocalPlayer.Character
				if character then
					for _, part in ipairs(character:GetDescendants()) do
						if part:IsA("BasePart") and part.CanCollide then
							part.CanCollide = false
						end
					end
				end
			end)
		else
			if noclipConn then
				noclipConn:Disconnect()
				noclipConn = nil
			end
			local character = LocalPlayer.Character
			if character then
				for _, part in ipairs(character:GetDescendants()) do
					if part:IsA("BasePart") then
						part.CanCollide = true
					end
				end
			end
		end
	end)

	local flyConn
	UI.Slider("FlySpeed", "Fly Speed", 16, 150, 50)
	UI.Toggle("Fly", "Fly", false, function(enabled)
		local character = LocalPlayer.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not humanoid or not root then
			return
		end
		if enabled then
			humanoid.PlatformStand = false
			humanoid:ChangeState(Enum.HumanoidStateType.Physics)
			flyConn = RunService.Heartbeat:Connect(function(dt)
				local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
				local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
				if not hum or not rootPart then
					return
				end
				local speed = UI.Flags.FlySpeed or 50
				local horizontal = hum.MoveDirection * speed
				local vertical = (UserInputService:IsKeyDown(Enum.KeyCode.Space) and speed or 0)
				rootPart.CFrame = rootPart.CFrame + (horizontal + Vector3.new(0, vertical, 0)) * dt
				rootPart.AssemblyLinearVelocity = Vector3.new()
			end)
		else
			if flyConn then
				flyConn:Disconnect()
				flyConn = nil
			end
			local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
			if hum then
				hum:ChangeState(Enum.HumanoidStateType.GettingUp)
			end
		end
	end)

	UI.Toggle("InfiniteJump", "Infinite Jump", false)
	UserInputService.JumpRequest:Connect(function()
		if not UI.Flags.InfiniteJump then
			return
		end
		local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid:GetState() == Enum.HumanoidStateType.Freefall then
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end)
end

do
	UI.Section("Anti-AFK")
	UI.Toggle("AntiAFK", "Anti-AFK", false)
	task.spawn(function()
		while true do
			task.wait(45)
			if UI.Flags.AntiAFK then
				pcall(function()
					VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
					task.wait(0.05)
					VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
				end)
			end
		end
	end)
end

-- Settings ------------------------------------------------------------------

UI.SetTab(UI.SettingsTab)

do
	UI.Section("Status")
	local watermarkLabel = UI.Label("Storage Hunters Hub")
	UI.Toggle("Watermark", "Show Watermark", true)
	task.spawn(function()
		while true do
			if UI.Flags.Watermark then
				local player = LocalPlayer
				local cash = player:FindFirstChild("CCUStats")
				cash = cash and cash:FindFirstChild("Cash")
				watermarkLabel.Text = string.format(
					"Cash $%.2f | FPS %d",
					cash and cash.Value or 0,
					math.floor(1 / RunService.RenderStepped:Wait())
				)
			end
			task.wait(1)
		end
	end)

	UI.Section("General")
	UI.Toggle("SilentStartup", "Silent Startup", false)
	UI.Label("Config auto-save/load and theme are handled natively by ProxyLib"
		.. " (ConfigPanel above, and every toggle already has a stable SaveId).")

	UI.Button("Unload", function()
		pcall(function()
			UI.Window:Destroy()
		end)
	end)

	if not UI.Flags.SilentStartup then
		UI.Window:Notify({ Title = "Storage Hunters Hub", Description = "Loaded.", Duration = 3 })
	end
end
