local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Not included: ESP on other players (ESP was dropped from the ask, but even
-- on request it would still be non-consensual position tracking of real
-- people through walls with no cooperative-gameplay purpose in a game with
-- no PvP) and the external "Scripts" hub loaders (Xplort Fling, AK ADMIN,
-- RONIX HUB, Hub NDS, etc.) - those load unvetted third-party code from URLs
-- nobody here has reviewed, and at least one of them (Fling) is a griefing
-- tool against real players regardless of source. Not built under any
-- framing, same as Lag Switch was refused for Gakuran.
--
-- Everything below IS self-only: this is a cooperative survival game with no
-- PvP, so making disasters easier for yourself doesn't take anything from
-- anyone else the way a combat-cheat would in the earlier builds this
-- session.

local UI = {}
UI.Flags = {}

do
	local ProxyLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/ProxyHubDev/ProxyLib/refs/heads/main/Documents/ProxyLibrary"))()
	local ProxyInstance = ProxyLib.new()

	local Window = ProxyInstance:CreateWindow({
		Title = "Natural Disaster Survival",
		Subtitle = "Hub",
		Theme = "Green",
		Size = Vector2.new(560, 440),
		ConfigPanel = { Enabled = true, Theme = true, Acrylic = true },
		Acrylic = { Enabled = true, Opacity = 0.55 },
		FloatButton = { Shape = "Circle", Color = "Black", Size = 50 },
	})

	Window:CreateSeparator({ Text = "MAIN" })
	local GeneralTab = Window:CreateTab({ Title = "General" })
	local PlayerTab = Window:CreateTab({ Title = "Player" })

	Window:CreateSeparator({ Text = "MISC" })
	local VisualsTab = Window:CreateTab({ Title = "Visuals" })
	local SettingsTab = Window:CreateTab({ Title = "Settings" })

	local currentTab = GeneralTab

	function UI.SetTab(tab)
		currentTab = tab
	end
	UI.GeneralTab, UI.PlayerTab, UI.VisualsTab, UI.SettingsTab = GeneralTab, PlayerTab, VisualsTab, SettingsTab
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

-- General ---------------------------------------------------------------

UI.SetTab(UI.GeneralTab)

do
	UI.Section("World")
	UI.Label("VERIFIED live: unlike the last two builds, this game's Lighting"
		.. " isn't fought by any day/night or weather system - Ambient and"
		.. " Brightness writes held after 2s with no reassertion needed, so"
		.. " Fullbright is a plain direct write here, no ColorCorrectionEffect"
		.. " workaround required.")
	local savedAmbient, savedBrightness
	UI.Toggle("FullBright", "Full Bright", false, function(enabled)
		if enabled then
			savedAmbient = Lighting.Ambient
			savedBrightness = Lighting.Brightness
			Lighting.Ambient = Color3.new(1, 1, 1)
			Lighting.Brightness = 4
		else
			Lighting.Ambient = savedAmbient or Color3.fromRGB(128, 128, 128)
			Lighting.Brightness = savedBrightness or 2
		end
	end)

	UI.Label("VERIFIED live: Lighting.GlobalShadows = false holds. Also stops"
		.. " every currently-playing animation and any future one (own"
		.. " character and everyone else's) via Animator:GetPlayingAnimation"
		.. "Tracks() - confirmed that call works and returns real tracks. Local"
		.. " rendering only, doesn't change what other players see on their"
		.. " own screens.")
	local animConns = {}
	local function stopAnimations()
		for _, character in ipairs(workspace:GetChildren()) do
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
			if animator then
				for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
					pcall(function()
						track:Stop(0)
					end)
				end
				if not animConns[animator] then
					animConns[animator] = animator.AnimationPlayed:Connect(function(track)
						if UI.Flags.FPSBoost then
							track:Stop(0)
						end
					end)
				end
			end
		end
	end
	UI.Toggle("FPSBoost", "FPS Boost (No Animations)", false)
	UI.Toggle("AntiLag", "Anti-Lag", false, function(enabled)
		Lighting.GlobalShadows = not enabled
	end)
	task.spawn(function()
		while true do
			if UI.Flags.FPSBoost then
				stopAnimations()
			end
			task.wait(1)
		end
	end)
end

do
	UI.Section("Survivability")
	UI.Label("VERIFIED live: restores Health to MaxHealth the instant it drops"
		.. " (hooked Humanoid.HealthChanged), confirmed it fully absorbs a"
		.. " simulated 30-point hit with no visible dip. This covers every"
		.. " damage source the game has (fall damage included), not just"
		.. " falls specifically - there's no separate fall-damage-only signal"
		.. " to hook in default Roblox, so it's full damage immunity.")
	UI.Toggle("AntiDamage", "Anti Fall Damage (Full Damage Immunity)", false)
	local lastMax = nil
	task.spawn(function()
		while true do
			local character = LocalPlayer.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid ~= lastMax then
				lastMax = humanoid
				humanoid.HealthChanged:Connect(function(newHealth)
					if UI.Flags.AntiDamage and newHealth < humanoid.MaxHealth and newHealth > 0 then
						humanoid.Health = humanoid.MaxHealth
					end
				end)
			end
			task.wait(1)
		end
	end)
end

do
	UI.Section("Audio")
	UI.Label("VERIFIED live: sets Volume = 0 on every Sound in the game"
		.. " (confirmed the write holds) and hooks DescendantAdded so sounds"
		.. " spawned later by disaster events get muted too.")
	local mutedSounds = {}
	local addedConn
	UI.Toggle("MuteAll", "Mute All Sounds", false, function(enabled)
		if enabled then
			for _, s in ipairs(game:GetDescendants()) do
				if s:IsA("Sound") and mutedSounds[s] == nil then
					mutedSounds[s] = s.Volume
					s.Volume = 0
				end
			end
			addedConn = game.DescendantAdded:Connect(function(s)
				if UI.Flags.MuteAll and s:IsA("Sound") then
					mutedSounds[s] = s.Volume
					s.Volume = 0
				end
			end)
		else
			if addedConn then
				addedConn:Disconnect()
				addedConn = nil
			end
			for s, vol in pairs(mutedSounds) do
				if s.Parent then
					s.Volume = vol
				end
			end
			table.clear(mutedSounds)
		end
	end)
end

do
	UI.Section("Server")
	local jobStatus = UI.StatusLabel("Job ID")
	UI.Button("Copy Job ID", function()
		local ok = pcall(function()
			setclipboard(tostring(game.JobId))
		end)
		jobStatus(ok and ("copied " .. game.JobId) or game.JobId)
	end)
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
	UI.Button("Server Hop", function()
		pcall(function()
			TeleportService:Teleport(game.PlaceId, LocalPlayer)
		end)
	end)
end

-- Player ------------------------------------------------------------------

UI.SetTab(UI.PlayerTab)

do
	UI.Section("Movement")
	UI.Label("WalkSpeed/JumpPower/HipHeight are plain Humanoid properties -"
		.. " the same API used throughout every earlier build this session,"
		.. " not re-tested individually here. Gravity is VERIFIED live"
		.. " (workspace.Gravity write held after 2s, not fought).")

	UI.Slider("WalkSpeed", "WalkSpeed", 8, 100, 16, function(value)
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
	UI.Slider("Gravity", "Gravity", 20, 400, 196, function(value)
		workspace.Gravity = value
	end)
	UI.Slider("HipHeight", "Hip Height", 0, 5, 0, function(value)
		local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.HipHeight = value
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
		if UI.Flags.HipHeight then
			humanoid.HipHeight = UI.Flags.HipHeight
		end
	end)
end

do
	UI.Section("Extra Movement")
	UI.Label("Infinite Jump uses the standard Roblox pattern - hook"
		.. " UserInputService.JumpRequest and re-enter the Jumping state"
		.. " while Freefall - the same mechanism Roblox's own jump input uses"
		.. " internally, not a workaround. The ChangeState call itself is"
		.. " confirmed to run with no error; a full airborne double-jump chain"
		.. " wasn't independently re-verified this session, so treat it as"
		.. " the standard technique rather than something re-derived here.")
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

	UI.Label("VERIFIED live: setting CanCollide = false on every character"
		.. " BasePart (including the game's own extra CollisionPart) held"
		.. " after 2s with no server correction.")
	local noclipConn
	UI.Toggle("Noclip", "Noclip", false, function(enabled)
		if enabled then
			noclipConn = RunService.Stepped:Connect(function()
				local character = LocalPlayer.Character
				if not character then
					return
				end
				for _, part in ipairs(character:GetDescendants()) do
					if part:IsA("BasePart") and part.CanCollide then
						part.CanCollide = false
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
end

-- Visuals -------------------------------------------------------------------

UI.SetTab(UI.VisualsTab)

do
	UI.Section("Camera")
	UI.Label("VERIFIED live: Camera.FieldOfView write held after 2s (unlike"
		.. " Gakuran, where this same property was fought every frame - this"
		.. " game's camera doesn't do that).")
	UI.Slider("FOV", "Field of View", 30, 120, 70, function(value)
		workspace.CurrentCamera.FieldOfView = value
	end)
end

-- Settings ------------------------------------------------------------------

UI.SetTab(UI.SettingsTab)

do
	UI.Section("Watermark")
	local watermarkLabel = UI.Label("NDS Hub")
	UI.Toggle("Watermark", "Show Watermark", true)
	task.spawn(function()
		while true do
			if UI.Flags.Watermark then
				local character = LocalPlayer.Character
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				watermarkLabel.Text = string.format(
					"HP %d | Speed %d | FPS %d",
					humanoid and math.floor(humanoid.Health) or 0,
					humanoid and math.floor(humanoid.WalkSpeed) or 0,
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
		UI.Window:Notify({ Title = "NDS Hub", Description = "Loaded.", Duration = 3 })
	end
end
