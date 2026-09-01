local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Real coordinates pulled from Workspace.AirDropPoints this session; the
-- server keeps this loaded regardless of streaming, unlike Workspace.Buildings.
local Locations = {
	{ Name = "Medical Clinic", Position = Vector3.new(-192.19, 277.78, -493.83) },
	{ Name = "Gun Store", Position = Vector3.new(-230.09, 251.28, -296.75) },
	{ Name = "Bike Shop", Position = Vector3.new(253.90, 280.64, -273.26) },
	{ Name = "Jack's Hardware Store", Position = Vector3.new(-127.57, 272.55, 156.63) },
	{ Name = "Sam's Motel", Position = Vector3.new(-123.40, 273.60, 491.74) },
	{ Name = "Police Department", Position = Vector3.new(-509.98, 251.31, -124.37) },
	{ Name = "Burger Place", Position = Vector3.new(179.35, 251.33, -170.38) },
	{ Name = "Quick-11", Position = Vector3.new(129.62, 272.61, 188.76) },
	{ Name = "Car Wash", Position = Vector3.new(563.50, 251.28, 70.70) },
	{ Name = "Skate Park", Position = Vector3.new(-605.98, 251.05, 484.82) },
	{ Name = "Basketball Court", Position = Vector3.new(112.97, 251.13, -535.55) },
	{ Name = "Park Center", Position = Vector3.new(-538.25, 251.36, 294.60) },
	{ Name = "Radio Tower", Position = Vector3.new(301.17, 251.14, -604.80) },
	{ Name = "Beach", Position = Vector3.new(937.19, 247.56, 714.64) },
	{ Name = "Beach Quay", Position = Vector3.new(158.62, 251.55, 807.44) },
	{ Name = "Beach Pier", Position = Vector3.new(-356.88, 251.25, 925.09) },
	{ Name = "Lake", Position = Vector3.new(372.53, 251.00, -907.92) },
	{ Name = "Lake Apartments", Position = Vector3.new(1097.26, 301.10, -591.94) },
	{ Name = "Blue Apartments", Position = Vector3.new(938.84, 251.14, -141.27) },
	{ Name = "Rich Cul de Sac", Position = Vector3.new(965.38, 251.07, 120.79) },
	{ Name = "Main Cul de Sac", Position = Vector3.new(980.53, 251.11, -368.40) },
	{ Name = "Main Intersection", Position = Vector3.new(-12.32, 251.11, -30.96) },
	{ Name = "Graveyard", Position = Vector3.new(-565.31, 251.25, -479.91) },
}

local Input = {}

-- Confirmed live: an instant HumanoidRootPart.CFrame write gets corrected back
-- by the server within a frame or two. Travel here walks the path instead,
-- which is ordinary Humanoid movement and isn't reverted.
function Input.WalkTo(targetPosition, statusFn)
	local character = LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root then
		return false
	end

	local path = PathfindingService:CreatePath({
		AgentRadius = 2,
		AgentHeight = 5,
		AgentCanJump = true,
	})
	local ok = pcall(function()
		path:ComputeAsync(root.Position, targetPosition)
	end)
	if not ok or path.Status ~= Enum.PathStatus.Success then
		humanoid:MoveTo(targetPosition)
		if statusFn then
			statusFn("no clear path, walking directly")
		end
		return true
	end

	for i, waypoint in ipairs(path:GetWaypoints()) do
		if statusFn then
			statusFn(string.format("waypoint %d/%d", i, #path:GetWaypoints()))
		end
		if waypoint.Action == Enum.PathWaypointAction.Jump then
			humanoid.Jump = true
		end
		humanoid:MoveTo(waypoint.Position)
		local reached = humanoid.MoveToFinished:Wait()
		if not reached then
			break
		end
	end
	return true
end

function Input.FindNearbyPrompt(patterns, maxDistance)
	local character = LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end
	maxDistance = maxDistance or 15
	local best, bestDist
	for _, descendant in ipairs(workspace:GetDescendants()) do
		if descendant:IsA("ProximityPrompt") then
			local part = descendant.Parent
			local worldPos
			if part and part:IsA("BasePart") then
				worldPos = part.Position
			elseif part and part:IsA("Model") then
				worldPos = part:GetPivot().Position
			end
			if worldPos then
				local dist = (worldPos - root.Position).Magnitude
				if dist <= maxDistance then
					local haystack = (descendant.ActionText .. " " .. descendant.ObjectText .. " " .. descendant.Name):lower()
					for _, pattern in ipairs(patterns) do
						if haystack:find(pattern) then
							if not bestDist or dist < bestDist then
								best, bestDist = descendant, dist
							end
						end
					end
				end
			end
		end
	end
	return best, bestDist
end

function Input.TriggerPrompt(prompt)
	if not prompt then
		return false
	end
	return (pcall(function()
		fireproximityprompt(prompt)
	end))
end

local UI = {}
UI.Flags = {}

do
	local ProxyLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/ProxyHubDev/ProxyLib/refs/heads/main/Documents/ProxyLibrary"))()
	local ProxyInstance = ProxyLib.new()

	local Window = ProxyInstance:CreateWindow({
		Title = "BlockSpin",
		Subtitle = "Hub",
		Theme = "Red",
		Size = Vector2.new(580, 460),
		ConfigPanel = { Enabled = true, Theme = true, Acrylic = true },
		Acrylic = { Enabled = true, Opacity = 0.55 },
		FloatButton = { Shape = "Circle", Color = "Black", Size = 50 },
	})

	Window:CreateSeparator({ Text = "AUTOMATION" })
	local FarmTab = Window:CreateTab({ Title = "Automation" })

	Window:CreateSeparator({ Text = "PLAYER" })
	local MoveTab = Window:CreateTab({ Title = "Movement" })
	local PlayerTab = Window:CreateTab({ Title = "Player" })

	Window:CreateSeparator({ Text = "WORLD" })
	local WorldTab = Window:CreateTab({ Title = "World" })
	local TravelTab = Window:CreateTab({ Title = "Teleports" })

	Window:CreateSeparator({ Text = "MISC" })
	local SettingsTab = Window:CreateTab({ Title = "Settings" })

	local currentTab = FarmTab

	function UI.SetTab(tab)
		currentTab = tab
	end
	UI.FarmTab, UI.MoveTab, UI.PlayerTab, UI.WorldTab, UI.TravelTab, UI.SettingsTab =
		FarmTab, MoveTab, PlayerTab, WorldTab, TravelTab, SettingsTab
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

-- Automation ------------------------------------------------------------
-- Every loop below drives the game's own ProximityPrompt, the same input a
-- player gives by walking up and holding E. Confirmed live: fireproximityprompt
-- exists on this executor and the game's job modules (Jobs.Janitor,
-- Jobs.ShelfStocking, Jobs.SteakhouseCook, ATM.ATM, World.Dumpster) are all
-- prompt-driven client controllers, not a custom remote payload. None of the
-- loops below have been run to a full successful cycle live - watch the
-- status label.

local function ActionDelay(base)
	return UI.Flags.RiskMode and base * 0.5 or base
end

local function promptAutoLoop(sectionName, flagKey, label, patterns, radius, interval)
	UI.Section(sectionName)
	local status = UI.StatusLabel(sectionName)
	UI.Toggle(flagKey, label, false)
	task.spawn(function()
		while true do
			if UI.Flags[flagKey] then
				local prompt, dist = Input.FindNearbyPrompt(patterns, radius or 15)
				if prompt then
					status(string.format("triggering %s (%.0f studs)", prompt.ActionText ~= "" and prompt.ActionText or prompt.Name, dist))
					Input.TriggerPrompt(prompt)
				else
					status("nothing nearby - walk to a work site")
				end
				task.wait(ActionDelay(interval or 1))
			else
				task.wait(0.3)
			end
		end
	end)
end

UI.SetTab(UI.FarmTab)

promptAutoLoop("Auto Shelf", "AutoShelf", "Auto Shelf (shelf_stocker)", { "stock", "shelf", "box" }, 12, 0.8)
promptAutoLoop("Auto Steak House", "AutoSteak", "Auto Steak House", { "cook", "grill", "fridge", "steak" }, 12, 0.8)
promptAutoLoop("Janitor Farm", "AutoJanitor", "Janitor Farm (Auto Mop)", { "mop", "clean", "puddle", "janitor" }, 12, 0.8)
promptAutoLoop("Dumpster Farm", "AutoDumpster", "Dumpster Farm", { "dumpster", "trash", "search" }, 12, 0.8)

do
	UI.Section("Auto ATM")
	UI.Label("Full ATM automation is UNTESTED end to end - it triggers whatever ATM"
		.. " prompt is nearby (hack / deposit / withdraw) and keeps trying, but the"
		.. " actual heist minigame was never completed live this session.")
	local atmStatus = UI.StatusLabel("Auto ATM")
	UI.Toggle("AutoATM", "Auto ATM Farm", false)
	UI.Toggle("AutoDeposit", "Auto Deposit", false)
	task.spawn(function()
		while true do
			if UI.Flags.AutoATM or UI.Flags.AutoDeposit then
				local patterns = {}
				if UI.Flags.AutoATM then
					table.insert(patterns, "atm")
					table.insert(patterns, "hack")
				end
				if UI.Flags.AutoDeposit then
					table.insert(patterns, "deposit")
				end
				local prompt, dist = Input.FindNearbyPrompt(patterns, 12)
				if prompt then
					atmStatus(string.format("triggering %s (%.0f studs)", prompt.ActionText ~= "" and prompt.ActionText or prompt.Name, dist))
					Input.TriggerPrompt(prompt)
				else
					atmStatus("no ATM prompt nearby")
				end
				task.wait(ActionDelay(1))
			else
				task.wait(0.3)
			end
		end
	end)
end

do
	UI.Section("Auto Collect")
	UI.Label("Crate opening: collects, finishes, and skips crate animations via"
		.. " their ProximityPrompts/UI buttons.")
	local crateStatus = UI.StatusLabel("Auto Collect")
	UI.Toggle("AutoCrate", "Auto Collect / Finish / Skip Crate", false)
	task.spawn(function()
		while true do
			if UI.Flags.AutoCrate then
				local prompt = Input.FindNearbyPrompt({ "crate", "open", "collect" }, 12)
				if prompt then
					crateStatus("triggering crate prompt")
					Input.TriggerPrompt(prompt)
				end
				local gui = PlayerGui:FindFirstChild("CrateSpinningGui")
				if gui and gui.Enabled then
					for _, descendant in ipairs(gui:GetDescendants()) do
						if descendant:IsA("TextButton") and descendant.Visible then
							local text = descendant.Text:lower()
							if text:find("skip") or text:find("claim") or text:find("continue") then
								pcall(function()
									descendant.MouseButton1Click:Fire()
								end)
							end
						end
					end
				end
				task.wait(ActionDelay(0.5))
			else
				task.wait(0.3)
			end
		end
	end)
end

-- Movement ----------------------------------------------------------------

UI.SetTab(UI.MoveTab)

do
	UI.Section("Speed")
	UI.Label("Instant position teleport is corrected by the server (confirmed live)."
		.. " WalkSpeed itself is a normal Humanoid property write - some games clamp"
		.. " it server-side, this account's ceiling wasn't tested past default.")
	UI.Slider("WalkSpeed", "Speed Hack", 8, 80, 8, function(value)
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

	UI.Slider("JumpPower", "Jump Power", 23, 120, 23, function(value)
		local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.JumpPower = value
		end
	end)

	UI.Toggle("InfiniteStamina", "Infinite Stamina", false)
	task.spawn(function()
		while true do
			if UI.Flags.InfiniteStamina then
				pcall(function()
					LocalPlayer:SetAttribute("SprintBar", 1)
				end)
			end
			task.wait(0.5)
		end
	end)

	UI.Slider("FOV", "FOV", 70, 120, 70, function(value)
		workspace.CurrentCamera.FieldOfView = value
	end)
end

do
	UI.Section("Vehicle")
	UI.Label("No vehicle was spawned in the server this session, so Vehicle Speed"
		.. " & Boost, Anti Crash, Auto Reseat, and Bring Vehicle are left out rather"
		.. " than shipped as toggles with no verified mechanism behind them. The real"
		.. " API surface is there (Modules.Game.VehicleSystem.Vehicle /.VehicleSeat,"
		.. " confirmed get_car_player_is_in exists) - wiring these up needs a session"
		.. " with an actual car to test against.")
end

-- Player --------------------------------------------------------------------

UI.SetTab(UI.PlayerTab)

do
	UI.Section("Survivability")
	UI.Label("Hide Name is VERIFIED live (toggles the real"
		.. " HumanoidRootPart.CharacterBillboardGui.Enabled, confirmed it sticks)."
		.. " Anti Ragdoll blocks the Humanoid's own state change into Ragdoll/Physics"
		.. " rather than calling into the game's Ragdoll module (that module has no"
		.. " exposed toggle - only initiate/ragdoll/is_ragdolling internals) and was"
		.. " not fired against a real ragdoll hit; if stomping in this game works by"
		.. " forcing the same Ragdoll state, this also covers Anti Stomp.")

	UI.Toggle("AntiRagdoll", "Anti Ragdoll", false, function(enabled)
		local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			return
		end
		if enabled then
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
		else
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, true)
		end
	end)
	LocalPlayer.CharacterAdded:Connect(function(character)
		if not UI.Flags.AntiRagdoll then
			return
		end
		local humanoid = character:WaitForChild("Humanoid", 10)
		if humanoid then
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
		end
	end)

	UI.Toggle("HideName", "Hide Name", false, function(enabled)
		local character = LocalPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local nameTag = root and root:FindFirstChild("CharacterBillboardGui")
		if nameTag then
			nameTag.Enabled = not enabled
		end
	end)
	LocalPlayer.CharacterAdded:Connect(function(character)
		if not UI.Flags.HideName then
			return
		end
		local root = character:WaitForChild("HumanoidRootPart", 10)
		local nameTag = root and root:WaitForChild("CharacterBillboardGui", 5)
		if nameTag then
			nameTag.Enabled = false
		end
	end)

	UI.Section("Recovery")
	UI.Toggle("AutoRespawn", "Auto Respawn", false)
	LocalPlayer.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid", 10)
		if not humanoid then
			return
		end
		humanoid.Died:Connect(function()
			if UI.Flags.AutoRespawn then
				task.wait(2)
				pcall(function()
					LocalPlayer:LoadCharacter()
				end)
			end
		end)
	end)

	local combatLogStatus = UI.StatusLabel("Combat Log Watch")
	UI.Toggle("CombatLogWatch", "Combat Log Watch", false)
	Players.PlayerRemoving:Connect(function(player)
		if UI.Flags.CombatLogWatch and LocalPlayer:GetAttribute("IsInCombat") then
			combatLogStatus(player.Name .. " left mid-combat")
		end
	end)

	UI.Button("Panic Reset", function()
		pcall(function()
			LocalPlayer:LoadCharacter()
		end)
	end)
	UI.Button("Safe Reset", function()
		local character = LocalPlayer.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Health = 0
		end
	end)
end

-- World -----------------------------------------------------------------

UI.SetTab(UI.WorldTab)

do
	UI.Section("Lighting")
	-- Confirmed live: both Lighting.Brightness and Lighting.ClockTime are fought
	-- by this game's own day/night cycle - a one-shot write, and even a
	-- continuous every-frame RenderStepped reassignment, both get overwritten
	-- within about a second (verified: forced Brightness=4 every frame for 3s,
	-- read back 2.75). Time of Day has no working client-side override within
	-- what was verifiable this session, so it isn't included rather than
	-- shipped as a slider that silently does nothing.
	--
	-- ColorCorrectionEffect.Brightness is a separate, purely client-side visual
	-- layer the day/night cycle doesn't touch - confirmed it holds (set 0.4,
	-- read back 0.4 after 1s). Brightness/FullBright use that instead.
	local colorCorrection = Lighting:FindFirstChild("HubColorCorrection")
	if not colorCorrection then
		colorCorrection = Instance.new("ColorCorrectionEffect")
		colorCorrection.Name = "HubColorCorrection"
		colorCorrection.Parent = Lighting
	end

	UI.Slider("Brightness", "Brightness Boost", -1, 1, 0, function(value)
		colorCorrection.Brightness = value
	end)

	UI.Toggle("FullBright", "FullBright", false, function(enabled)
		if enabled then
			colorCorrection.Brightness = 0.6
			colorCorrection.Contrast = -0.2
		else
			colorCorrection.Brightness = UI.Flags.Brightness or 0
			colorCorrection.Contrast = 0
		end
	end)
end

do
	UI.Section("World Item ESP")
	UI.Label("Highlights world objects only (items, chests, ATMs) - not players.")
	local highlightPool = {}
	UI.Toggle("WorldESP", "Highlight Items / Chests / ATMs", false)
	task.spawn(function()
		while true do
			if UI.Flags.WorldESP then
				local seen = {}
				local dropped = workspace:FindFirstChild("DroppedItems")
				if dropped then
					for _, item in ipairs(dropped:GetChildren()) do
						if item:IsA("BasePart") or item:IsA("Model") then
							seen[item] = true
							if not highlightPool[item] then
								local hl = Instance.new("Highlight")
								hl.FillColor = Color3.fromRGB(90, 200, 255)
								hl.FillTransparency = 0.5
								hl.Parent = item
								highlightPool[item] = hl
							end
						end
					end
				end
				for object, hl in pairs(highlightPool) do
					if not seen[object] or not object.Parent then
						hl:Destroy()
						highlightPool[object] = nil
					end
				end
			else
				for object, hl in pairs(highlightPool) do
					hl:Destroy()
					highlightPool[object] = nil
				end
			end
			task.wait(1)
		end
	end)
end

do
	UI.Section("Server")
	UI.Button("Server Hop", function()
		pcall(function()
			TeleportService:Teleport(game.PlaceId, LocalPlayer)
		end)
	end)
	UI.Button("Rejoin", function()
		pcall(function()
			TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
		end)
	end)
	local hopStatus = UI.StatusLabel("Join Smallest")
	UI.Button("Join Smallest", function()
		hopStatus("fetching server list...")
		local ok, response = pcall(function()
			return HttpService:JSONDecode(game:HttpGet(
				"https://games.roblox.com/v1/games/" .. tostring(game.PlaceId) .. "/servers/Public?sortOrder=Asc&limit=100"
			))
		end)
		if not ok or type(response) ~= "table" or type(response.data) ~= "table" then
			hopStatus("could not fetch server list")
			return
		end
		local best
		for _, server in ipairs(response.data) do
			if server.id ~= game.JobId and (not best or server.playing < best.playing) then
				best = server
			end
		end
		if best then
			hopStatus("joining " .. best.playing .. "-player server")
			pcall(function()
				TeleportService:TeleportToPlaceInstance(game.PlaceId, best.id, LocalPlayer)
			end)
		else
			hopStatus("no smaller server found")
		end
	end)
end

-- Teleports ---------------------------------------------------------------

UI.SetTab(UI.TravelTab)

do
	UI.Section("Smart Travel")
	UI.Label("Walks the path via PathfindingService (falls back to a direct MoveTo"
		.. " if no path is found). Car/Bike travel modes need a vehicle to verify"
		.. " against and aren't implemented yet.")

	local locationNames = {}
	for _, location in ipairs(Locations) do
		table.insert(locationNames, location.Name)
	end
	table.sort(locationNames)

	local travelStatus = UI.StatusLabel("Travel")
	UI.Dropdown("TravelTarget", "Location", locationNames, locationNames[1])

	UI.Button("Walk There", function()
		local target
		for _, location in ipairs(Locations) do
			if location.Name == UI.Flags.TravelTarget then
				target = location
				break
			end
		end
		if not target then
			travelStatus("pick a location first")
			return
		end
		travelStatus("walking to " .. target.Name)
		Input.WalkTo(target.Position, travelStatus)
		travelStatus("arrived at " .. target.Name)
	end)
end

-- Settings ------------------------------------------------------------------

UI.SetTab(UI.SettingsTab)

do
	UI.Section("Watermark")
	local watermarkLabel = UI.Label("BlockSpin Hub")
	UI.Toggle("Watermark", "Show Watermark", true)
	task.spawn(function()
		while true do
			if UI.Flags.Watermark then
				local character = LocalPlayer.Character
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				watermarkLabel.Text = string.format(
					"HP %d | Speed %d | Ping %dms | FPS %d",
					humanoid and math.floor(humanoid.Health) or 0,
					humanoid and math.floor(humanoid.WalkSpeed) or 0,
					math.floor((LocalPlayer:GetAttribute("ServerPing") or 0) * 1000),
					math.floor(1 / RunService.RenderStepped:Wait())
				)
			end
			task.wait(1)
		end
	end)

	UI.Section("General")
	UI.Toggle("SilentStartup", "Silent Startup", false)
	UI.Toggle("RiskMode", "Risk Mode (shorter delay between automation actions)", false)
	UI.Label("Config auto-save/load and theme are handled natively by ProxyLib"
		.. " (ConfigPanel above, and every toggle already has a stable SaveId).")

	UI.Button("Unload", function()
		pcall(function()
			UI.Window:Destroy()
		end)
	end)

	if not UI.Flags.SilentStartup then
		UI.Window:Notify({ Title = "BlockSpin Hub", Description = "Loaded.", Duration = 3 })
	end
end
