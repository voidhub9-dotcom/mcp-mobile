local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Not included, on purpose - this is a live PvP melee/parry game, and almost
-- the entire original feature list either auto-plays a fight against a real
-- opponent or sees through walls to do it: Auto Parry and everything under
-- Combat, Face Lock/Sticky Target/Select Player/Whitelist under Targeting,
-- all of Rhythm (auto-perfects the piano/song minigame that has its own real
-- leaderboard - RhythmStatsLeaderboard - so this is a leaderboard-integrity
-- cheat, not just a combat one), Player ESP and everything under it (a
-- wallhack on real people), Speedhack/Fly/Infinite Jump/Infinite Stamina/
-- Auto Sprint/Noclip, and Teleport -> Players (lets you warp onto a chosen
-- opponent, which is a targeting tool in this game, not travel).
--
-- Lag Switch specifically is not a line-drawing judgment call like the rest
-- of this list - it manipulates your own connection to disrupt hit
-- registration for other real players' sessions. Not built under any
-- framing.

local Input = {}

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
		if not humanoid.MoveToFinished:Wait() then
			break
		end
	end
	return true
end

local UI = {}
UI.Flags = {}

do
	local ProxyLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/ProxyHubDev/ProxyLib/refs/heads/main/Documents/ProxyLibrary"))()
	local ProxyInstance = ProxyLib.new()

	local Window = ProxyInstance:CreateWindow({
		Title = "Gakuran",
		Subtitle = "Hub",
		Theme = "Purple",
		Size = Vector2.new(560, 440),
		ConfigPanel = { Enabled = true, Theme = true, Acrylic = true },
		Acrylic = { Enabled = true, Opacity = 0.55 },
		FloatButton = { Shape = "Circle", Color = "Black", Size = 50 },
	})

	Window:CreateSeparator({ Text = "WORLD" })
	local WorldTab = Window:CreateTab({ Title = "World" })
	local TravelTab = Window:CreateTab({ Title = "Teleport" })

	Window:CreateSeparator({ Text = "CHARACTER" })
	local CharTab = Window:CreateTab({ Title = "Character" })

	Window:CreateSeparator({ Text = "MISC" })
	local SettingsTab = Window:CreateTab({ Title = "Settings" })

	local currentTab = WorldTab

	function UI.SetTab(tab)
		currentTab = tab
	end
	UI.WorldTab, UI.TravelTab, UI.CharTab, UI.SettingsTab = WorldTab, TravelTab, CharTab, SettingsTab
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

-- World -----------------------------------------------------------------

UI.SetTab(UI.WorldTab)

local ColorCorrection
do
	ColorCorrection = Lighting:FindFirstChild("HubColorCorrection")
	if not ColorCorrection then
		ColorCorrection = Instance.new("ColorCorrectionEffect")
		ColorCorrection.Name = "HubColorCorrection"
		ColorCorrection.Parent = Lighting
	end
end

do
	UI.Section("Lighting")
	UI.Label("VERIFIED live: Lighting.Ambient gets reverted by this game's own"
		.. " day/night cycle within about a second (tested directly), so"
		.. " Full Bright / Night Mode / Ambient here all go through a"
		.. " ColorCorrectionEffect instead, which is untouched by that cycle -"
		.. " confirmed both TintColor and Brightness hold. Camera FOV is not"
		.. " included: this game's camera module resets FieldOfView every"
		.. " frame even against a continuous RenderStepped write, and no"
		.. " override property could be found this session.")

	UI.Toggle("FullBright", "Full Bright", false, function(enabled)
		if enabled then
			ColorCorrection.Brightness = 0.6
			ColorCorrection.Contrast = -0.2
		else
			ColorCorrection.Brightness = 0
			ColorCorrection.Contrast = 0
		end
	end)

	UI.Toggle("NightMode", "Night Mode", false, function(enabled)
		if enabled then
			ColorCorrection.TintColor = Color3.fromRGB(80, 90, 140)
			ColorCorrection.Brightness = -0.35
		else
			ColorCorrection.TintColor = Color3.new(1, 1, 1)
			ColorCorrection.Brightness = UI.Flags.FullBright and 0.6 or 0
		end
	end)

	UI.Slider("AmbientR", "Ambient R", 0, 255, 255)
	UI.Slider("AmbientG", "Ambient G", 0, 255, 255)
	UI.Slider("AmbientB", "Ambient B", 0, 255, 255)
	UI.Button("Apply Ambient", function()
		ColorCorrection.TintColor = Color3.fromRGB(
			UI.Flags.AmbientR or 255,
			UI.Flags.AmbientG or 255,
			UI.Flags.AmbientB or 255
		)
	end)
end

do
	UI.Section("Performance")
	UI.Label("VERIFIED live: Lighting.GlobalShadows = false holds (confirmed"
		.. " over 2s, not fought like Ambient). Also strips local particle/trail/"
		.. " beam effects, a standard client-only rendering cut.")
	local disabledEffects = {}
	UI.Toggle("LowGFX", "Low GFX", false, function(enabled)
		Lighting.GlobalShadows = not enabled
		if enabled then
			for _, d in ipairs(workspace:GetDescendants()) do
				if (d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam")) and d.Enabled then
					d.Enabled = false
					table.insert(disabledEffects, d)
				end
			end
		else
			for _, d in ipairs(disabledEffects) do
				if d.Parent then
					d.Enabled = true
				end
			end
			table.clear(disabledEffects)
		end
	end)
end

-- Teleport ----------------------------------------------------------------

UI.SetTab(UI.TravelTab)

do
	UI.Section("Waypoint")
	UI.Label("Self-only travel: saves your current position and walks back to"
		.. " it via real PathfindingService movement (same mechanism verified"
		.. " in the BlockSpin and Realistic Street Soccer builds), falling back"
		.. " to a direct MoveTo when no path is found. Teleporting to another"
		.. " player isn't here - in this game that's a way to warp onto a"
		.. " chosen opponent, which is a targeting tool, not travel.")

	local savedPosition = nil
	local waypointStatus = UI.StatusLabel("Waypoint")

	UI.Button("Save Waypoint", function()
		local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		if not root then
			waypointStatus("no character")
			return
		end
		savedPosition = root.Position
		waypointStatus(string.format("saved (%.0f, %.0f, %.0f)", savedPosition.X, savedPosition.Y, savedPosition.Z))
	end)

	UI.Button("Teleport to Waypoint", function()
		if not savedPosition then
			waypointStatus("no waypoint saved yet")
			return
		end
		waypointStatus("walking to waypoint")
		Input.WalkTo(savedPosition, waypointStatus)
		waypointStatus("arrived")
	end)
end

-- Character -----------------------------------------------------------------

UI.SetTab(UI.CharTab)

do
	UI.Section("Reroll")
	UI.Label("BEST-EFFORT, not fully verified: this game's real appearance"
		.. " reroll flow is three RemoteFunctions - RerollSpin (get a new"
		.. " random candidate), RerollSubmit (keep it), RerollUndo (revert)."
		.. " RerollSpin(\"HairColor\") confirmed returning true live, but"
		.. " Submit and Undo both returned false this session and the"
		.. " Character.HairDescription attribute never changed - likely a"
		.. " currency/cooldown gate (Remotes.BulkRerollBalance suggests"
		.. " rerolls cost something) rather than a wrong call shape, but that"
		.. " couldn't be confirmed. There's no separate exact-color picker"
		.. " remote - only this random-reroll one - so \"Change Hair Color\""
		.. " is this same Spin/Submit flow, not an arbitrary color picker.")

	local rerollStatus = UI.StatusLabel("Reroll")
	UI.Dropdown("RerollCategory", "Category", { "HairColor", "Face", "Hair" }, "HairColor")

	UI.Button("Spin", function()
		local remote = Remotes:FindFirstChild("RerollSpin")
		if not remote then
			rerollStatus("RerollSpin remote not found")
			return
		end
		local ok, result = pcall(function()
			return remote:InvokeServer(UI.Flags.RerollCategory)
		end)
		rerollStatus("spin(" .. tostring(UI.Flags.RerollCategory) .. ") -> " .. tostring(ok and result or "error"))
	end)

	UI.Button("Submit (Keep)", function()
		local remote = Remotes:FindFirstChild("RerollSubmit")
		if not remote then
			rerollStatus("RerollSubmit remote not found")
			return
		end
		local ok, result = pcall(function()
			return remote:InvokeServer(UI.Flags.RerollCategory)
		end)
		rerollStatus("submit(" .. tostring(UI.Flags.RerollCategory) .. ") -> " .. tostring(ok and result or "error"))
	end)

	UI.Button("Stop All Rerolls (Undo)", function()
		local remote = Remotes:FindFirstChild("RerollUndo")
		if not remote then
			rerollStatus("RerollUndo remote not found")
			return
		end
		local ok, result = pcall(function()
			return remote:InvokeServer(UI.Flags.RerollCategory)
		end)
		rerollStatus("undo(" .. tostring(UI.Flags.RerollCategory) .. ") -> " .. tostring(ok and result or "error"))
	end)

	UI.Button("Show Current Values", function()
		local character = LocalPlayer.Character
		if not character then
			rerollStatus("no character")
			return
		end
		local parts = {}
		for key, value in pairs(character:GetAttributes()) do
			if tostring(key):find("Description") then
				table.insert(parts, tostring(key) .. "=" .. tostring(value))
			end
		end
		if #parts == 0 then
			rerollStatus("no *Description attributes found on Character")
		else
			rerollStatus(table.concat(parts, ", "))
		end
	end)
end

do
	UI.Section("Character")
	UI.Label("VERIFIED live, with a correction: this game runs its own health/"
		.. " respawn system on top of the Humanoid - setting Health to 0 does"
		.. " zero it out, but neither Player:LoadCharacter() nor the real"
		.. " Remotes.Revive actually brought the character back afterward"
		.. " (tested both, health stayed at 0 for 10+ seconds). What does"
		.. " reliably work is setting Health back to MaxHealth directly - this"
		.. " account owns network ownership of its own Humanoid, so the write"
		.. " sticks instantly and isn't fought. \"Instant Respawn\" below is"
		.. " that full-heal, not a true teleport-to-spawn respawn - shipping"
		.. " it as the real respawn would have been a fabricated claim.")
	UI.Button("Kill Self", function()
		local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Health = 0
		end
	end)
	UI.Button("Instant Respawn (Full Heal)", function()
		local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Health = humanoid.MaxHealth
		end
	end)
end

-- Settings ------------------------------------------------------------------

UI.SetTab(UI.SettingsTab)

do
	UI.Section("Watermark")
	local watermarkLabel = UI.Label("Gakuran Hub")
	UI.Toggle("Watermark", "Show Watermark", true)
	task.spawn(function()
		while true do
			if UI.Flags.Watermark then
				local character = LocalPlayer.Character
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				watermarkLabel.Text = string.format(
					"HP %d | FPS %d",
					humanoid and math.floor(humanoid.Health) or 0,
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
		UI.Window:Notify({ Title = "Gakuran Hub", Description = "Loaded.", Duration = 3 })
	end
end
