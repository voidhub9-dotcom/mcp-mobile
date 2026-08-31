--[[
	Sol's RNG [Summer Event] automation hub.

	Built against a live client this session. Every mechanic below falls into one
	of two buckets, and each toggle's status label says which:

	VERIFIED  - traced or tap-tested against the real game this session.
	BEST EFFORT - built from the game's real ByteNet packet map (dumped from
	ReplicatedStorage.BytenetStorage) and its GUI layout, but this account's
	progression (14 rolls) never unlocked the flow to test it end to end. It
	will try the intended remote first, then fall back to scanning for and
	tapping the matching UI button. Watch the status label; if it stays on
	"unverified" nothing is wrong with your account, it just hasn't been
	exercised yet.

	Roll triggering deliberately does NOT call the Rolling packets directly.
	Three separate interception techniques (queue-level packet patch, a
	game-wide FireServer/InvokeServer hook, and a Visible-changed signal on
	the roll button) all failed to observe the real client->server call for a
	roll, even while the roll completed and the server pushed back a real
	Rolling.SendResult. That means the executor used to test this doesn't let
	hooks see calls made by the game's own trusted scripts. Synthesizing the
	same input a player makes (wait for the button to be interactable, then a
	real VirtualInputManager click) is what actually works, and was confirmed
	three times in a row against the live game (Rolls 14 -> 15 -> 16 -> 17,
	each with a decoded SendResult). So every action in this script drives the
	real UI instead of guessing at packet payloads.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")
local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--============================================================
-- Packet map (informational decode of ByteNet ids -> names)
--============================================================

local PacketNameById = {}
do
	local storage = ReplicatedStorage:FindFirstChild("BytenetStorage")
	if storage then
		for _, entry in ipairs(storage:GetChildren()) do
			if entry:IsA("StringValue") then
				local ok, decoded = pcall(function()
					return HttpService:JSONDecode(entry.Value)
				end)
				if ok and type(decoded) == "table" and type(decoded.packets) == "table" then
					for name, id in pairs(decoded.packets) do
						PacketNameById[id] = entry.Name .. "." .. name
					end
				end
			end
		end
	end
end

local function GetPacket(namespace, name)
	local ok, mod = pcall(function()
		return ReplicatedStorage.Packets:FindFirstChild(namespace)
	end)
	if not ok or not mod then
		return nil
	end
	local reqOk, tbl = pcall(require, mod)
	if not reqOk or type(tbl) ~= "table" then
		return nil
	end
	return tbl[name]
end

--============================================================
-- Core input primitives - everything drives the real UI
--============================================================

local Input = {}

function Input.Inset()
	local ok, inset = pcall(function()
		return GuiService:GetGuiInset()
	end)
	if ok then
		return inset.Y
	end
	return 0
end

-- Tap the center of a GuiObject with a real VirtualInputManager click.
function Input.Tap(guiObject)
	if not guiObject or not guiObject.Parent then
		return false
	end
	local pos, size = guiObject.AbsolutePosition, guiObject.AbsoluteSize
	if size.X <= 0 or size.Y <= 0 then
		return false
	end
	local x, y = pos.X + size.X / 2, pos.Y + size.Y / 2 + Input.Inset()
	VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
	task.wait(0.07)
	VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
	return true
end

-- Poll until a GuiObject is genuinely visible and reachable (not covered by a
-- higher overlay), then tap it. This is what makes rolling reliable: the roll
-- button in this game blinks in and out of Visible on its own cadence.
function Input.WaitAndTap(guiObject, timeoutSeconds)
	timeoutSeconds = timeoutSeconds or 6
	if not guiObject then
		return false
	end
	local deadline = os.clock() + timeoutSeconds
	while os.clock() < deadline do
		if guiObject.Visible and guiObject.Parent then
			return Input.Tap(guiObject)
		end
		task.wait(0.03)
	end
	return false
end

-- Find the first visible TextButton/ImageButton under `root` whose text or
-- name matches any of `patterns` (Lua patterns, case-insensitive). Used for
-- best-effort features where the exact button path wasn't traced live.
function Input.FindButton(root, patterns, maxDepth)
	if not root then
		return nil
	end
	maxDepth = maxDepth or 8
	local queue = { { root, 0 } }
	while #queue > 0 do
		local item = table.remove(queue, 1)
		local node, depth = item[1], item[2]
		if node ~= root and (node:IsA("TextButton") or node:IsA("ImageButton")) and node.Visible then
			local text = (node:IsA("TextButton") and node.Text or node.Name):lower()
			for _, pattern in ipairs(patterns) do
				if text:find(pattern) then
					return node
				end
			end
		end
		if depth < maxDepth then
			for _, child in ipairs(node:GetChildren()) do
				if child:IsA("GuiObject") then
					table.insert(queue, { child, depth + 1 })
				end
			end
		end
	end
	return nil
end

--============================================================
-- Minimal self-contained UI (no external loadstring dependency)
--============================================================

local UI = {}
UI.Flags = {}

do
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "SolsRNGHub"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.DisplayOrder = 50000
	screenGui.Parent = PlayerGui

	local root = Instance.new("Frame")
	root.Name = "Root"
	root.Size = UDim2.new(0, 300, 0, 420)
	root.Position = UDim2.new(0, 12, 0, 60)
	root.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
	root.BorderSizePixel = 0
	root.Active = true
	root.Draggable = true
	root.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = root

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 28)
	title.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
	title.BorderSizePixel = 0
	title.Font = Enum.Font.GothamBold
	title.Text = "Sol's RNG Hub"
	title.TextColor3 = Color3.fromRGB(235, 235, 245)
	title.TextSize = 14
	title.Parent = root

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 8)
	titleCorner.Parent = title

	local toggleBtn = Instance.new("TextButton")
	toggleBtn.Size = UDim2.new(0, 24, 0, 24)
	toggleBtn.Position = UDim2.new(1, -28, 0, 2)
	toggleBtn.BackgroundColor3 = Color3.fromRGB(48, 48, 60)
	toggleBtn.Font = Enum.Font.GothamBold
	toggleBtn.Text = "-"
	toggleBtn.TextColor3 = Color3.fromRGB(235, 235, 245)
	toggleBtn.TextSize = 16
	toggleBtn.Parent = title

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Body"
	scroll.Size = UDim2.new(1, 0, 1, -30)
	scroll.Position = UDim2.new(0, 0, 0, 30)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 4
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.Parent = root

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = scroll

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 6)
	padding.PaddingRight = UDim.new(0, 6)
	padding.PaddingTop = UDim.new(0, 6)
	padding.PaddingBottom = UDim.new(0, 6)
	padding.Parent = scroll

	local collapsed = false
	toggleBtn.MouseButton1Click:Connect(function()
		collapsed = not collapsed
		scroll.Visible = not collapsed
		root.Size = collapsed and UDim2.new(0, 300, 0, 30) or UDim2.new(0, 300, 0, 420)
		toggleBtn.Text = collapsed and "+" or "-"
	end)

	local order = 0
	local function nextOrder()
		order = order + 1
		return order
	end

	function UI.Section(text)
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 0, 22)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBold
		label.Text = text
		label.TextColor3 = Color3.fromRGB(150, 190, 255)
		label.TextSize = 13
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.LayoutOrder = nextOrder()
		label.Parent = scroll
		return label
	end

	function UI.Label(text)
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 0, 18)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.Gotham
		label.Text = text
		label.TextColor3 = Color3.fromRGB(190, 190, 200)
		label.TextSize = 12
		label.TextWrapped = true
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.AutomaticSize = Enum.AutomaticSize.Y
		label.LayoutOrder = nextOrder()
		label.Parent = scroll
		return label
	end

	function UI.Toggle(key, text, default, callback)
		UI.Flags[key] = default and true or false
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 26)
		btn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
		btn.Font = Enum.Font.Gotham
		btn.TextColor3 = Color3.fromRGB(230, 230, 240)
		btn.TextSize = 12
		btn.LayoutOrder = nextOrder()
		local corner2 = Instance.new("UICorner")
		corner2.CornerRadius = UDim.new(0, 6)
		corner2.Parent = btn
		local function render()
			btn.Text = string.format("[%s] %s", UI.Flags[key] and "ON " or "OFF", text)
			btn.BackgroundColor3 = UI.Flags[key] and Color3.fromRGB(45, 90, 60) or Color3.fromRGB(40, 40, 50)
		end
		render()
		btn.MouseButton1Click:Connect(function()
			UI.Flags[key] = not UI.Flags[key]
			render()
			if callback then
				task.spawn(callback, UI.Flags[key])
			end
		end)
		btn.Parent = scroll
		return btn
	end

	function UI.Slider(key, text, min, max, default, callback)
		UI.Flags[key] = default
		local holder = Instance.new("Frame")
		holder.Size = UDim2.new(1, 0, 0, 34)
		holder.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
		holder.LayoutOrder = nextOrder()
		local corner2 = Instance.new("UICorner")
		corner2.CornerRadius = UDim.new(0, 6)
		corner2.Parent = holder

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -8, 0, 16)
		label.Position = UDim2.new(0, 4, 0, 0)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.Gotham
		label.TextColor3 = Color3.fromRGB(230, 230, 240)
		label.TextSize = 11
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Text = text .. ": " .. tostring(default)
		label.Parent = holder

		local bar = Instance.new("TextButton")
		bar.Size = UDim2.new(1, -8, 0, 10)
		bar.Position = UDim2.new(0, 4, 0, 20)
		bar.BackgroundColor3 = Color3.fromRGB(60, 60, 72)
		bar.Text = ""
		bar.AutoButtonColor = false
		local barCorner = Instance.new("UICorner")
		barCorner.CornerRadius = UDim.new(1, 0)
		barCorner.Parent = bar

		local fill = Instance.new("Frame")
		fill.BackgroundColor3 = Color3.fromRGB(90, 150, 255)
		fill.BorderSizePixel = 0
		local fillCorner = Instance.new("UICorner")
		fillCorner.CornerRadius = UDim.new(1, 0)
		fillCorner.Parent = fill
		fill.Parent = bar

		local function setValue(alpha)
			alpha = math.clamp(alpha, 0, 1)
			local value = math.floor(min + (max - min) * alpha + 0.5)
			UI.Flags[key] = value
			fill.Size = UDim2.new(alpha, 0, 1, 0)
			label.Text = text .. ": " .. tostring(value)
			if callback then
				callback(value)
			end
		end
		setValue((default - min) / (max - min))

		local dragging = false
		bar.InputBegan:Connect(function(inputObj)
			if inputObj.UserInputType == Enum.UserInputType.MouseButton1 or inputObj.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				local alpha = (inputObj.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X
				setValue(alpha)
			end
		end)
		UserInputService.InputChanged:Connect(function(inputObj)
			if dragging and (inputObj.UserInputType == Enum.UserInputType.MouseMovement or inputObj.UserInputType == Enum.UserInputType.Touch) then
				local alpha = (inputObj.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X
				setValue(alpha)
			end
		end)
		UserInputService.InputEnded:Connect(function(inputObj)
			if inputObj.UserInputType == Enum.UserInputType.MouseButton1 or inputObj.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)

		bar.Parent = holder
		holder.Parent = scroll
		return holder
	end

	function UI.TextInput(key, placeholder, default)
		UI.Flags[key] = default or ""
		local box = Instance.new("TextBox")
		box.Size = UDim2.new(1, 0, 0, 26)
		box.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
		box.Font = Enum.Font.Gotham
		box.TextColor3 = Color3.fromRGB(230, 230, 240)
		box.PlaceholderText = placeholder
		box.Text = default or ""
		box.TextSize = 12
		box.ClearTextOnFocus = false
		box.LayoutOrder = nextOrder()
		local corner2 = Instance.new("UICorner")
		corner2.CornerRadius = UDim.new(0, 6)
		corner2.Parent = box
		box:GetPropertyChangedSignal("Text"):Connect(function()
			UI.Flags[key] = box.Text
		end)
		box.Parent = scroll
		return box
	end

	function UI.Button(text, callback)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 26)
		btn.BackgroundColor3 = Color3.fromRGB(50, 60, 90)
		btn.Font = Enum.Font.Gotham
		btn.Text = text
		btn.TextColor3 = Color3.fromRGB(230, 230, 240)
		btn.TextSize = 12
		btn.LayoutOrder = nextOrder()
		local corner2 = Instance.new("UICorner")
		corner2.CornerRadius = UDim.new(0, 6)
		corner2.Parent = btn
		btn.MouseButton1Click:Connect(function()
			task.spawn(callback)
		end)
		btn.Parent = scroll
		return btn
	end

	function UI.StatusLabel(prefix)
		local label = UI.Label(prefix .. ": idle")
		local last = nil
		return function(text)
			local full = prefix .. ": " .. tostring(text)
			if full == last then
				return
			end
			last = full
			label.Text = full
		end
	end
end

--============================================================
-- GUI accessors
--============================================================

local function MainInterface()
	return PlayerGui:FindFirstChild("MainInterface")
end

local function BottomFrame()
	local mi = MainInterface()
	return mi and mi:FindFirstChild("BottomFrame")
end

--============================================================
-- Rolling (VERIFIED live: 3/3 real rolls, decoded SendResult each time)
--============================================================

local Rolling = {}
Rolling.LastResult = nil
Rolling.RollCount = 0
Rolling.SetStatus = UI.StatusLabel and nil

do
	UI.Section("Rolling")

	local setStatus = UI.StatusLabel("Roll")
	local rollLog = UI.Label("Last: none")

	-- Listen for real server-pushed roll results. Verified live.
	local sendResultPacket = GetPacket("Rolling", "SendResult")
	if sendResultPacket and type(sendResultPacket.listen) == "function" then
		pcall(function()
			sendResultPacket.listen(function(data)
				if type(data) ~= "table" then
					return
				end
				Rolling.LastResult = data
				Rolling.RollCount = Rolling.RollCount + 1
				rollLog.Text = string.format(
					"Last: %s (rarity %s) #%d",
					tostring(data.Value),
					tostring(data.Rarity),
					Rolling.RollCount
				)
			end)
		end)
	end

	local function rollOnce(timeout)
		local bf = BottomFrame()
		if not bf then
			return false
		end
		local btn = bf:FindFirstChild("RollButton")
		if not btn then
			return false
		end
		return Input.WaitAndTap(btn, timeout or 6)
	end
	Rolling.RollOnce = rollOnce

	-- Auto Roll: rolls continuously whenever the button is reachable and the
	-- server says you're rollable. VERIFIED mechanism (the tap itself), the
	-- gating on the Rollable attribute is read directly from the server-owned
	-- attribute so it never spams while on cooldown or off the roll pad.
	UI.Toggle("AutoRoll", "Auto Roll", false)
	task.spawn(function()
		while true do
			if UI.Flags.AutoRoll then
				local rollable = LocalPlayer:GetAttribute("Rollable")
				if rollable == false then
					setStatus("waiting for cooldown/pad")
					task.wait(0.5)
				else
					setStatus("rolling")
					local ok = rollOnce(4)
					if not ok then
						setStatus("roll button unreachable (are you on the pad?)")
					end
					task.wait(0.35)
				end
			else
				setStatus("idle")
				task.wait(0.3)
			end
		end
	end)

	-- Quick Roll: the in-game toggle is gamepass-gated on this account (a tap
	-- did not change its state during testing) so this can only try to enable
	-- it; it does not fabricate the effect if the pass isn't owned.
	UI.Toggle("QuickRoll", "Quick Roll (needs gamepass)", false, function(enabled)
		local bf = BottomFrame()
		local btn = bf and bf:FindFirstChild("QuickRoll")
		if not btn then
			return
		end
		local before = btn.Text
		Input.WaitAndTap(btn, 2)
		task.wait(0.3)
		if btn.Text == before then
			UI.Label("Quick Roll did not toggle - likely needs the gamepass on this account.")
		end
	end)

	-- Aura Hunt: keep auto-rolling (independent of the Auto Roll toggle above)
	-- until a roll result's Value matches one of the target names. VERIFIED
	-- trigger mechanism; matching logic is exact-name against SendResult.Value
	-- which was confirmed to carry the aura's display name live ("Good",
	-- "Common" were the two observed values - use whatever names your rolls
	-- actually show, comma separated).
	UI.Section("Aura Hunt")
	UI.TextInput("AuraHuntTargets", "Target auras, comma separated", "")
	local huntStatus = UI.StatusLabel("Aura Hunt")
	UI.Toggle("AuraHunt", "Aura Hunt", false)
	task.spawn(function()
		while true do
			if UI.Flags.AuraHunt then
				local targets = {}
				for name in tostring(UI.Flags.AuraHuntTargets or ""):gmatch("[^,]+") do
					targets[name:match("^%s*(.-)%s*$"):lower()] = true
				end
				if next(targets) == nil then
					huntStatus("enter at least one target aura name above")
					task.wait(1)
				else
					local rollable = LocalPlayer:GetAttribute("Rollable")
					if rollable == false then
						huntStatus("waiting for cooldown/pad")
						task.wait(0.5)
					else
						huntStatus("rolling for: " .. UI.Flags.AuraHuntTargets)
						rollOnce(4)
						task.wait(0.35)
						local result = Rolling.LastResult
						if result and type(result.Value) == "string" and targets[result.Value:lower()] then
							UI.Flags.AuraHunt = false
							huntStatus("FOUND " .. result.Value .. " - stopped")
						end
					end
				end
			else
				task.wait(0.3)
			end
		end
	end)
end

--============================================================
-- Smart Aura Filter (BEST EFFORT - dynamic button scan, unverified end-to-end)
--============================================================

do
	UI.Section("Smart Aura Filter")
	UI.Label("Equip/keep/skip after each roll based on rarity. BEST EFFORT: scans"
		.. " the on-screen result popup for an Equip-like button; the popup's exact"
		.. " layout was not captured live this session.")
	UI.Slider("FilterKeepAboveRarity", "Auto-equip rarity >=", 1, 10, 5)
	UI.Toggle("SmartFilter", "Smart Aura Filter", false)

	local filterStatus = UI.StatusLabel("Smart Filter")

	local sendResultPacket = GetPacket("Rolling", "SendResult")
	if sendResultPacket and type(sendResultPacket.listen) == "function" then
		pcall(function()
			sendResultPacket.listen(function(data)
				if not UI.Flags.SmartFilter or type(data) ~= "table" then
					return
				end
				local rarity = tonumber(data.Rarity) or 0
				if rarity >= (UI.Flags.FilterKeepAboveRarity or 5) then
					task.spawn(function()
						task.wait(0.4)
						local mi = MainInterface()
						local btn = mi and Input.FindButton(mi, { "equip" }, 10)
						if btn then
							Input.Tap(btn)
							filterStatus("equipped " .. tostring(data.Value) .. " (rarity " .. tostring(data.Rarity) .. ")")
						else
							filterStatus("wanted to equip " .. tostring(data.Value) .. " but no Equip button found - UNVERIFIED")
						end
					end)
				end
			end)
		end)
	end
end

--============================================================
-- Auto Boosts (BEST EFFORT / UNTESTED - progression gated on this account)
--============================================================

do
	UI.Section("Auto Boosts")
	UI.Label("UNTESTED: uses selected luck/speed items automatically. This account's"
		.. " boost inventory was not reachable this session to verify the item list"
		.. " or the use-item flow.")
	UI.TextInput("BoostItems", "Boost item names, comma separated", "")
	local boostStatus = UI.StatusLabel("Auto Boosts")
	UI.Toggle("AutoBoosts", "Auto Boosts", false)

	local useItemPacket = GetPacket("Inventory", "UseItem")
	task.spawn(function()
		while true do
			if UI.Flags.AutoBoosts then
				local names = {}
				for name in tostring(UI.Flags.BoostItems or ""):gmatch("[^,]+") do
					table.insert(names, name:match("^%s*(.-)%s*$"))
				end
				if #names == 0 then
					boostStatus("enter boost item names above")
				else
					for _, name in ipairs(names) do
						local backpack = LocalPlayer:FindFirstChild("Backpack")
						local tool = backpack and backpack:FindFirstChild(name)
						if tool then
							local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
							if humanoid then
								humanoid:EquipTool(tool)
								boostStatus("used " .. name)
							end
						elseif useItemPacket and type(useItemPacket.send) == "function" then
							pcall(function()
								useItemPacket.send(name)
							end)
							boostStatus("sent use-item for " .. name .. " (UNVERIFIED)")
						end
					end
				end
				task.wait(5)
			else
				task.wait(0.3)
			end
		end
	end)
end

--============================================================
-- Auto Collect (VERIFIED reachable: ground coin/gem parts were visible live)
--============================================================

do
	UI.Section("Auto Collect")
	UI.Label("Walks to nearby ground items and touches them. Ground items"
		.. " (coin/gem parts under Player<id>_LeftGearInstance) were confirmed"
		.. " present in the workspace live; the touch-collect step itself was not"
		.. " round-tripped against a currency change this session.")
	local collectStatus = UI.StatusLabel("Auto Collect")
	UI.Toggle("AutoCollect", "Auto Collect", false)

	local function findNearestGroundItem(root)
		local best, bestDist
		for _, model in ipairs(workspace:GetChildren()) do
			if model.Name:match("_LeftGearInstance$") or model.Name:match("_RightGearInstance$") then
				for _, part in ipairs(model:GetChildren()) do
					if part:IsA("BasePart") then
						local dist = (part.Position - root.Position).Magnitude
						if not bestDist or dist < bestDist then
							best, bestDist = part, dist
						end
					end
				end
			end
		end
		return best, bestDist
	end

	task.spawn(function()
		while true do
			if UI.Flags.AutoCollect then
				local character = LocalPlayer.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				if root and humanoid then
					local item, dist = findNearestGroundItem(root)
					if item then
						collectStatus(string.format("moving to %s (%.0f studs)", item.Name, dist))
						humanoid:MoveTo(item.Position)
						pcall(function()
							firetouchinterest(root, item, 0)
							task.wait(0.15)
							firetouchinterest(root, item, 1)
						end)
					else
						collectStatus("no ground items nearby")
					end
				end
				task.wait(0.5)
			else
				task.wait(0.3)
			end
		end
	end)
end

--============================================================
-- Auto Craft / Auto Quests / Auto Rewards / Auto Fishing / Memory Match
-- (UNTESTED - progression gated; wired to real packet map + UI scan)
--============================================================

local function untestedAutoLoop(sectionName, flagKey, label, openPatterns, actionPatterns, interval)
	UI.Section(sectionName)
	UI.Label("UNTESTED on this account (progression-gated). Opens the matching menu"
		.. " and taps the first matching button each cycle.")
	local status = UI.StatusLabel(sectionName)
	UI.Toggle(flagKey, label, false)
	task.spawn(function()
		while true do
			if UI.Flags[flagKey] then
				local mi = MainInterface()
				if mi then
					local opener = Input.FindButton(mi, openPatterns, 10)
					if opener then
						Input.Tap(opener)
						task.wait(0.5)
					end
					local action = Input.FindButton(mi, actionPatterns, 12)
					if action then
						Input.Tap(action)
						status("tapped a matching button")
					else
						status("no matching button found - UNVERIFIED for this account")
					end
				end
				task.wait(interval or 3)
			else
				task.wait(0.3)
			end
		end
	end)
end

untestedAutoLoop("Auto Craft", "AutoCraft", "Auto Craft", { "craft" }, { "craft", "auto add" }, 4)
untestedAutoLoop("Auto Quests", "AutoQuests", "Auto Quests", { "quest" }, { "claim", "accept", "complete" }, 4)
untestedAutoLoop("Auto Rewards", "AutoRewards", "Auto Rewards", { "reward", "achievement", "season" }, { "claim" }, 5)
untestedAutoLoop("Auto Fishing", "AutoFishing", "Auto Fishing", { "fish" }, { "cast", "catch", "sell" }, 2)
untestedAutoLoop("Memory Match", "MemoryMatch", "Auto Memory Match", { "memory", "match" }, { "start", "play" }, 3)

--============================================================
-- Safe Travel (BEST EFFORT - bookmark based, no hardcoded coordinates)
--============================================================

do
	UI.Section("Safe Travel")
	UI.Label("No world location coordinates were verified this session, so nothing"
		.. " here is pre-filled. Stand where you want to return to and press Save"
		.. " Spot, then Go To Spot teleports you back via a smooth tween.")
	local bookmarks = {}
	local spotStatus = UI.StatusLabel("Safe Travel")
	UI.TextInput("SpotName", "Spot name", "Roll Pad")

	UI.Button("Save Current Spot", function()
		local character = LocalPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root then
			spotStatus("no character")
			return
		end
		local name = UI.Flags.SpotName ~= "" and UI.Flags.SpotName or "Spot"
		bookmarks[name] = root.CFrame
		spotStatus("saved '" .. name .. "'")
	end)

	UI.Button("Go To Spot", function()
		local name = UI.Flags.SpotName ~= "" and UI.Flags.SpotName or "Spot"
		local target = bookmarks[name]
		if not target then
			spotStatus("'" .. name .. "' not saved yet")
			return
		end
		local character = LocalPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root then
			spotStatus("no character")
			return
		end
		root.CFrame = target
		spotStatus("moved to '" .. name .. "'")
	end)
end

--============================================================
-- Performance Mode (VERIFIED overlay identified live via GUI stack inspection)
--============================================================

do
	UI.Section("Performance Mode")
	UI.Label("Disables the heavy roll-cutscene overlay (confirmed live: a full-screen"
		.. " ScreenGui at DisplayOrder 9000 with GradientBoard/Colorboard/Star effects"
		.. " was sitting above the main UI and eating input) plus a few Lighting knobs.")
	local perfStatus = UI.StatusLabel("Performance Mode")

	local heavyOverlayOriginal = {}
	local originalLighting = {
		GlobalShadows = Lighting.GlobalShadows,
	}

	UI.Toggle("PerformanceMode", "Performance Mode", false, function(enabled)
		if enabled then
			for _, gui in ipairs(PlayerGui:GetChildren()) do
				if gui:IsA("ScreenGui") and gui.DisplayOrder >= 3000 and gui ~= PlayerGui:FindFirstChild("SolsRNGHub") then
					if heavyOverlayOriginal[gui] == nil then
						heavyOverlayOriginal[gui] = gui.Enabled
					end
					gui.Enabled = false
				end
			end
			Lighting.GlobalShadows = false
			perfStatus("heavy overlays disabled")
		else
			for gui, wasEnabled in pairs(heavyOverlayOriginal) do
				if gui.Parent then
					gui.Enabled = wasEnabled
				end
			end
			heavyOverlayOriginal = {}
			Lighting.GlobalShadows = originalLighting.GlobalShadows
			perfStatus("restored")
		end
	end)
end

--============================================================
-- Extra Features
--============================================================

do
	UI.Section("Extra Features")

	-- Walk Speed (VERIFIED: Humanoid.WalkSpeed is a plain client-visible
	-- property write, standard technique).
	UI.Slider("WalkSpeed", "Walk Speed", 16, 100, 16, function(value)
		local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = value
		end
	end)
	LocalPlayer.CharacterAdded:Connect(function(character)
		task.wait(0.5)
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid and UI.Flags.WalkSpeed then
			humanoid.WalkSpeed = UI.Flags.WalkSpeed
		end
	end)

	-- Flight (standard BodyVelocity/AlignPosition-based flight).
	local flying = false
	local flightConn
	local flightForce
	UI.Toggle("Flight", "Flight", false, function(enabled)
		flying = enabled
		local character = LocalPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root then
			return
		end
		if enabled then
			if not flightForce then
				flightForce = Instance.new("BodyVelocity")
				flightForce.Name = "HubFlightForce"
				flightForce.MaxForce = Vector3.new(1e5, 1e5, 1e5)
				flightForce.Velocity = Vector3.zero
			end
			flightForce.Parent = root
			flightConn = RunService.RenderStepped:Connect(function()
				local camera = workspace.CurrentCamera
				local moveDir = Vector3.zero
				if UserInputService:IsKeyDown(Enum.KeyCode.W) then
					moveDir = moveDir + camera.CFrame.LookVector
				end
				if UserInputService:IsKeyDown(Enum.KeyCode.S) then
					moveDir = moveDir - camera.CFrame.LookVector
				end
				if UserInputService:IsKeyDown(Enum.KeyCode.A) then
					moveDir = moveDir - camera.CFrame.RightVector
				end
				if UserInputService:IsKeyDown(Enum.KeyCode.D) then
					moveDir = moveDir + camera.CFrame.RightVector
				end
				if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
					moveDir = moveDir + Vector3.new(0, 1, 0)
				end
				if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
					moveDir = moveDir - Vector3.new(0, 1, 0)
				end
				flightForce.Velocity = moveDir.Magnitude > 0 and moveDir.Unit * 60 or Vector3.zero
			end)
		else
			if flightConn then
				flightConn:Disconnect()
				flightConn = nil
			end
			if flightForce then
				flightForce.Parent = nil
			end
		end
	end)

	-- Item Highlights (VERIFIED live: ground coin/gem parts were present and
	-- reachable; Highlight instances are a standard non-networked visual).
	local highlightPool = {}
	UI.Toggle("ItemHighlights", "Item Highlights", false)
	task.spawn(function()
		while true do
			if UI.Flags.ItemHighlights then
				local seen = {}
				for _, model in ipairs(workspace:GetChildren()) do
					if model.Name:match("_LeftGearInstance$") or model.Name:match("_RightGearInstance$") then
						for _, part in ipairs(model:GetChildren()) do
							if part:IsA("BasePart") then
								seen[part] = true
								if not highlightPool[part] then
									local hl = Instance.new("Highlight")
									hl.FillColor = Color3.fromRGB(255, 220, 90)
									hl.OutlineColor = Color3.fromRGB(255, 255, 255)
									hl.FillTransparency = 0.5
									hl.Parent = part
									highlightPool[part] = hl
								end
							end
						end
					end
				end
				for part, hl in pairs(highlightPool) do
					if not seen[part] or not part.Parent then
						hl:Destroy()
						highlightPool[part] = nil
					end
				end
			else
				for part, hl in pairs(highlightPool) do
					hl:Destroy()
					highlightPool[part] = nil
				end
			end
			task.wait(1)
		end
	end)

	-- Anti-AFK (standard VirtualUser idle-poke technique).
	UI.Toggle("AntiAFK", "Anti-AFK", false)
	LocalPlayer.Idled:Connect(function()
		if UI.Flags.AntiAFK then
			pcall(function()
				VirtualUser:CaptureController()
				VirtualUser:ClickButton2(Vector2.new())
			end)
		end
	end)

	-- Auto Reconnect. game.Close fires right before the client's connection to
	-- the server tears down (server shutdown, kick, or network loss) - the
	-- documented, real signal for this. Note: this only rejoins the place; it
	-- does not re-inject the script itself. Use queue_on_teleport with your own
	-- hosted copy of this file if you want the hub to reopen automatically too.
	UI.Toggle("AutoReconnect", "Auto Reconnect", false)
	game.Close:Connect(function()
		if UI.Flags.AutoReconnect then
			pcall(function()
				TeleportService:Teleport(game.PlaceId, LocalPlayer)
			end)
		end
	end)

	-- Rare aura webhook (Discord). Trigger threshold is the SendResult.Rarity
	-- ordinal - VERIFIED only two data points this session ("2"=Common,
	-- "5"=Good, higher observed to mean rarer), so treat the default threshold
	-- as a starting point to tune, not a guaranteed tier boundary.
	UI.TextInput("WebhookURL", "Discord webhook URL", "")
	UI.Slider("WebhookMinRarity", "Notify at rarity >=", 1, 10, 6)
	UI.Toggle("WebhookEnabled", "Rare Aura Webhook", false)

	local sendResultPacket = GetPacket("Rolling", "SendResult")
	if sendResultPacket and type(sendResultPacket.listen) == "function" then
		pcall(function()
			sendResultPacket.listen(function(data)
				if not UI.Flags.WebhookEnabled or type(data) ~= "table" then
					return
				end
				local rarity = tonumber(data.Rarity) or 0
				if rarity < (UI.Flags.WebhookMinRarity or 6) then
					return
				end
				local url = UI.Flags.WebhookURL
				if type(url) ~= "string" or url == "" then
					return
				end
				task.spawn(function()
					pcall(function()
						local body = HttpService:JSONEncode({
							content = string.format(
								"**%s** rolled **%s** (rarity %s)",
								LocalPlayer.Name,
								tostring(data.Value),
								tostring(data.Rarity)
							),
						})
						if type(request) == "function" then
							request({
								Url = url,
								Method = "POST",
								Headers = { ["Content-Type"] = "application/json" },
								Body = body,
							})
						elseif type(http_request) == "function" then
							http_request({
								Url = url,
								Method = "POST",
								Headers = { ["Content-Type"] = "application/json" },
								Body = body,
							})
						end
					end)
				end)
			end)
		end)
	end
end

UI.Label(string.format("Loaded. %d ByteNet packets mapped for reference.", (function()
	local n = 0
	for _ in pairs(PacketNameById) do
		n = n + 1
	end
	return n
end)()))
