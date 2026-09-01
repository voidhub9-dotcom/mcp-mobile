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

-- Rolls only through a real synthesized click: the roll button blinks in and
-- out of Visible on its own cadence, so this polls until it's actually there.
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

local UI = {}
UI.Flags = {}

do
	local ProxyLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/ProxyHubDev/ProxyLib/refs/heads/main/Documents/ProxyLibrary"))()
	local ProxyInstance = ProxyLib.new()

	local Window = ProxyInstance:CreateWindow({
		Title = "Sol's RNG",
		Subtitle = "Hub",
		Theme = "Blue",
		Size = Vector2.new(560, 440),
		ConfigPanel = { Enabled = true, Theme = true, Acrylic = true },
		Acrylic = { Enabled = true, Opacity = 0.55 },
	})

	Window:CreateSeparator({ Text = "ROLLING" })
	local RollTab = Window:CreateTab({ Title = "Rolling" })

	Window:CreateSeparator({ Text = "AUTOMATION" })
	local FarmTab = Window:CreateTab({ Title = "Farm" })

	Window:CreateSeparator({ Text = "MISC" })
	local TravelTab = Window:CreateTab({ Title = "Travel" })
	local ExtraTab = Window:CreateTab({ Title = "Extra" })

	local currentTab = RollTab

	function UI.SetTab(tab)
		currentTab = tab
	end
	UI.RollTab, UI.FarmTab, UI.TravelTab, UI.ExtraTab = RollTab, FarmTab, TravelTab, ExtraTab

	function UI.Section(text)
		return currentTab:CreateSection({ Text = text })
	end

	-- Wraps CreateParagraph so call sites can still do `label.Text = ...`
	-- instead of `:SetDescription(...)`.
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

	function UI.TextInput(key, placeholder, default)
		UI.Flags[key] = default or ""
		return currentTab:CreateTextBox({
			Title = placeholder,
			Placeholder = placeholder,
			Default = default or "",
			Callback = function(text)
				UI.Flags[key] = text
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

	Window:Notify({ Title = "Sol's RNG Hub", Description = "Loaded.", Duration = 3 })
end

local function MainInterface()
	return PlayerGui:FindFirstChild("MainInterface")
end

local function BottomFrame()
	local mi = MainInterface()
	return mi and mi:FindFirstChild("BottomFrame")
end

local Rolling = {}
Rolling.LastResult = nil
Rolling.RollCount = 0

do
	UI.Section("Rolling")

	local setStatus = UI.StatusLabel("Roll")
	local rollLog = UI.Label("Last: none")

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

	-- The in-game Quick Roll toggle is gamepass-gated on this account; this
	-- only tries to enable it, it doesn't fabricate the effect.
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

	UI.Section("Smart Aura Filter")
	UI.Label("Equip/keep/skip after each roll based on rarity. Scans the on-screen"
		.. " result popup for an Equip-like button.")
	UI.Slider("FilterKeepAboveRarity", "Auto-equip rarity >=", 1, 10, 5)
	UI.Toggle("SmartFilter", "Smart Aura Filter", false)

	local filterStatus = UI.StatusLabel("Smart Filter")
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
							filterStatus("wanted to equip " .. tostring(data.Value) .. " but no Equip button found")
						end
					end)
				end
			end)
		end)
	end
end

UI.SetTab(UI.FarmTab)

do
	UI.Section("Auto Boosts")
	UI.Label("Uses selected luck/speed items automatically.")
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
							boostStatus("sent use-item for " .. name)
						end
					end
				end
				task.wait(5)
			else
				task.wait(0.3)
			end
		end
	end)

	UI.Section("Auto Collect")
	UI.Label("Walks to nearby ground items and touches them.")
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

local function autoLoop(sectionName, flagKey, label, openPatterns, actionPatterns, interval)
	UI.Section(sectionName)
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
						status("no matching button found")
					end
				end
				task.wait(interval or 3)
			else
				task.wait(0.3)
			end
		end
	end)
end

autoLoop("Auto Craft", "AutoCraft", "Auto Craft", { "craft" }, { "craft", "auto add" }, 4)
autoLoop("Auto Quests", "AutoQuests", "Auto Quests", { "quest" }, { "claim", "accept", "complete" }, 4)
autoLoop("Auto Rewards", "AutoRewards", "Auto Rewards", { "reward", "achievement", "season" }, { "claim" }, 5)
autoLoop("Auto Fishing", "AutoFishing", "Auto Fishing", { "fish" }, { "cast", "catch", "sell" }, 2)
autoLoop("Memory Match", "MemoryMatch", "Auto Memory Match", { "memory", "match" }, { "start", "play" }, 3)

UI.SetTab(UI.TravelTab)

do
	UI.Section("Safe Travel")
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

UI.SetTab(UI.ExtraTab)

do
	UI.Section("Performance Mode")
	local perfStatus = UI.StatusLabel("Performance Mode")

	local heavyOverlayOriginal = {}
	local originalGlobalShadows = Lighting.GlobalShadows

	UI.Toggle("PerformanceMode", "Performance Mode", false, function(enabled)
		if enabled then
			for _, gui in ipairs(PlayerGui:GetChildren()) do
				if gui:IsA("ScreenGui") and gui.DisplayOrder >= 3000 then
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
			Lighting.GlobalShadows = originalGlobalShadows
			perfStatus("restored")
		end
	end)

	UI.Section("Extra Features")

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

	local flightConn
	local flightForce
	UI.Toggle("Flight", "Flight", false, function(enabled)
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

	UI.Toggle("AntiAFK", "Anti-AFK", false)
	LocalPlayer.Idled:Connect(function()
		if UI.Flags.AntiAFK then
			pcall(function()
				VirtualUser:CaptureController()
				VirtualUser:ClickButton2(Vector2.new())
			end)
		end
	end)

	UI.Toggle("AutoReconnect", "Auto Reconnect", false)
	game.Close:Connect(function()
		if UI.Flags.AutoReconnect then
			pcall(function()
				TeleportService:Teleport(game.PlaceId, LocalPlayer)
			end)
		end
	end)

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
