local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local Teams = game:GetService("Teams")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Not included, on purpose: AutoShoot, AutoDribble/Auto Collect (the ball),
-- AutoTackle (prediction), Goal Aim Assist, Auto Pass/Tackle/Deke, Fire
-- Tackle/Deke/Header/Bicycle Kick, all the curve/swerve "Exploits", Tackle
-- Boost, Dribble Boost, Trajectory Visualiser, Feet Circle, Speed (+7v7
-- bypass), WalkSpeed/Velocity/CFrame Speed, JumpPower, Infinite Stamina,
-- Always Jump, Auto GK selector (no role-select remote exists in this game -
-- only Remotes.GKHitbox, a server-side hitbox helper, not a picker), Coins
-- Spoof, Leaderboard Spoof, Cosmetics Unlock All/Cards, Shoe/Gamepass/Deke/
-- Celebration Spoof, and "Unlock celebrations". Those either play the live
-- 7v7 match for you / give an aim or movement edge over real opponents, or
-- fabricate stats/ownership the account doesn't actually have.

local Input = {}

-- Same technique verified working in BlockSpin: real Humanoid movement via
-- PathfindingService, not a CFrame snap (this game also runs server-side
-- position validation on tools like the ones above, so a snap wouldn't be
-- reliable even for pure QoL travel).
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
		Title = "Realistic Street Soccer",
		Subtitle = "Hub",
		Theme = "Blue",
		Size = Vector2.new(560, 440),
		ConfigPanel = { Enabled = true, Theme = true, Acrylic = true },
		Acrylic = { Enabled = true, Opacity = 0.55 },
		FloatButton = { Shape = "Circle", Color = "Black", Size = 50 },
	})

	Window:CreateSeparator({ Text = "PLAYER" })
	local CustomTab = Window:CreateTab({ Title = "Customization" })

	Window:CreateSeparator({ Text = "LOBBY" })
	local LobbyTab = Window:CreateTab({ Title = "Lobby" })
	local GameplayTab = Window:CreateTab({ Title = "Gameplay" })

	Window:CreateSeparator({ Text = "MISC" })
	local SettingsTab = Window:CreateTab({ Title = "Settings" })

	local currentTab = CustomTab

	function UI.SetTab(tab)
		currentTab = tab
	end
	UI.CustomTab, UI.LobbyTab, UI.GameplayTab, UI.SettingsTab = CustomTab, LobbyTab, GameplayTab, SettingsTab
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

	function UI.TextInput(key, text, placeholder, callback)
		return currentTab:CreateTextBox({
			Title = text,
			Placeholder = placeholder,
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

-- Customization --------------------------------------------------------

UI.SetTab(UI.CustomTab)

do
	UI.Section("Skin / Hair Randomizer")
	UI.Label("VERIFIED live: fires the real Remotes.Avatar(\"SkinTone\", ...) and"
		.. " Remotes.Avatar(\"Accessory1\", ...) calls, confirmed the Avatar data"
		.. " folder updates. Only picks from the base skin tones (not the VIP one,"
		.. " which needs a gamepass) and from hair styles this account actually"
		.. " owns (read live from levelsystem.Inventory.accessories) - it doesn't"
		.. " grant anything new.")

	local SkinTones = { "SkinTone1", "SkinTone2", "SkinTone3", "SkinTone4" }

	local function ownedAccessories()
		local list = {}
		local inv = LocalPlayer:FindFirstChild("levelsystem")
		inv = inv and inv:FindFirstChild("Inventory")
		inv = inv and inv:FindFirstChild("accessories")
		if inv then
			for _, item in ipairs(inv:GetChildren()) do
				table.insert(list, item.Name)
			end
		end
		if #list == 0 then
			list = { "None" }
		end
		return list
	end

	local randomStatus = UI.StatusLabel("Randomizer")

	local function randomizeOnce()
		local avatarRemote = Remotes:FindFirstChild("Avatar")
		if not avatarRemote then
			randomStatus("Remotes.Avatar not found")
			return
		end
		local skin = SkinTones[math.random(1, #SkinTones)]
		local accessories = ownedAccessories()
		local hair = accessories[math.random(1, #accessories)]
		pcall(function()
			avatarRemote:FireServer("SkinTone", skin)
		end)
		task.wait(0.3)
		pcall(function()
			avatarRemote:FireServer("Accessory1", hair)
		end)
		randomStatus(skin .. " / " .. hair)
	end

	UI.Button("Randomize Now", randomizeOnce)

	UI.Toggle("AutoRandomize", "Auto Randomize (on interval)", false)
	UI.Slider("RandomizeInterval", "Interval (seconds)", 15, 300, 60)
	task.spawn(function()
		while true do
			if UI.Flags.AutoRandomize then
				randomizeOnce()
				task.wait(UI.Flags.RandomizeInterval or 60)
			else
				task.wait(1)
			end
		end
	end)
end

-- Lobby ------------------------------------------------------------------

UI.SetTab(UI.LobbyTab)

do
	UI.Section("Auto Claim Rewards")
	UI.Label("Fires the real DailyRewardEvents.ClaimReward remote - confirmed it"
		.. " fires with no error. This account didn't actually gain coins when"
		.. " tested, because the daily streak here requires joining the game's"
		.. " Roblox group first (that's the game's own gate, shown in its own"
		.. " reward UI, not a limitation of this script) - once that's true for"
		.. " your account this should just work.")
	local claimStatus = UI.StatusLabel("Auto Claim")
	UI.Toggle("AutoClaim", "Auto Claim Rewards", false)
	local function claimOnce()
		local remote = ReplicatedStorage:FindFirstChild("DailyRewardEvents")
		remote = remote and remote:FindFirstChild("ClaimReward")
		if not remote then
			claimStatus("ClaimReward remote not found")
			return
		end
		pcall(function()
			remote:FireServer()
		end)
		claimStatus("claim requested at " .. os.date("%H:%M:%S"))
	end
	UI.Button("Claim Now", claimOnce)
	task.spawn(function()
		while true do
			if UI.Flags.AutoClaim then
				claimOnce()
				task.wait(300)
			else
				task.wait(2)
			end
		end
	end)
end

do
	UI.Section("Team Joiner")
	UI.Label("BEST-EFFORT, not fully verified: walks to the 7v7 queue pad"
		.. " (Workspace.Lobby.7v7Mode.PlayHere, real PathfindingService movement,"
		.. " same mechanism verified for travel in the BlockSpin build) and then"
		.. " fires the real Remotes.TeamChange remote with your picked side."
		.. " Firing TeamChange alone from the waiting area did not change this"
		.. " account's team this session, so the actual switch may only be"
		.. " accepted once you're queued/in a live match - watch the status line.")

	local teamNames = {}
	for _, team in ipairs(Teams:GetTeams()) do
		if team.Name ~= "Fans" then
			table.insert(teamNames, team.Name)
		end
	end
	if #teamNames == 0 then
		teamNames = { "Home", "Away" }
	end

	local teamStatus = UI.StatusLabel("Team Joiner")
	UI.Dropdown("PreferredTeam", "Preferred Side", teamNames, teamNames[1])

	UI.Button("Walk to Queue & Join", function()
		local pad = workspace:FindFirstChild("Lobby")
		pad = pad and pad:FindFirstChild("7v7Mode")
		pad = pad and pad:FindFirstChild("PlayHere")
		if not pad then
			teamStatus("queue pad not found")
			return
		end
		teamStatus("walking to queue")
		Input.WalkTo(pad.Position, teamStatus)
		task.wait(0.5)
		local remote = Remotes:FindFirstChild("TeamChange")
		if remote then
			pcall(function()
				remote:FireServer(UI.Flags.PreferredTeam)
			end)
		end
		task.wait(1)
		teamStatus("requested " .. tostring(UI.Flags.PreferredTeam) .. " - current team: " .. tostring(LocalPlayer.Team and LocalPlayer.Team.Name))
	end)
end

-- Gameplay -----------------------------------------------------------------

UI.SetTab(UI.GameplayTab)

do
	UI.Section("Gameplay Automation")
	UI.Label("Nothing here on purpose. AutoShoot, AutoDribble/ball collection,"
		.. " AutoTackle, Goal Aim Assist, Auto Pass/Tackle/Deke, the Fire"
		.. " Tackle/Deke/Header/Bicycle Kick combos, the curve/swerve ball-physics"
		.. " exploits, Tackle/Dribble Boost, and movement/stamina buffs would all"
		.. " play the live 7v7 match for you or give a mechanical edge over real"
		.. " human opponents - that's the same line drawn for the BlockSpin build."
		.. " An Auto GK selector isn't here either: this game has no role-select"
		.. " remote, only Remotes.GKHitbox, which is a server-side hitbox helper,"
		.. " not something a client can pick a role with.")
end

-- Settings ------------------------------------------------------------------

UI.SetTab(UI.SettingsTab)

do
	UI.Section("Camera")
	UI.Label("VERIFIED live: the game's camera-shake events run through exactly"
		.. " one connection on Remotes.Shake.OnClientEvent - this disables that"
		.. " connection directly (confirmed :Disable()/:Enable() both work and"
		.. " hold). Purely a local visual change, doesn't touch other players.")
	UI.Toggle("NoShake", "No Shake", false, function(enabled)
		local remote = Remotes:FindFirstChild("Shake")
		if not remote then
			return
		end
		local ok, conns = pcall(getconnections, remote.OnClientEvent)
		if not ok or not conns then
			return
		end
		for _, conn in ipairs(conns) do
			pcall(function()
				if enabled then
					conn:Disable()
				else
					conn:Enable()
				end
			end)
		end
	end)
end

do
	UI.Section("Streamer Mode")
	UI.Label("VERIFIED live: overwrites the two labels that actually show your"
		.. " name above your own head (Head.BillboardGui.Frame.NameLabel and"
		.. " Head.PlayerCard.Frame.TextLabel) - confirmed the text holds with no"
		.. " server correction. Local-only, cosmetic, doesn't touch other"
		.. " players' clients or the leaderboard.")

	local displayName = "Player"
	local function applyStreamerName()
		local character = LocalPlayer.Character
		local head = character and character:FindFirstChild("Head")
		if not head then
			return
		end
		local billboard = head:FindFirstChild("BillboardGui")
		local nameLabel = billboard and billboard:FindFirstChild("Frame")
		nameLabel = nameLabel and nameLabel:FindFirstChild("NameLabel")
		if nameLabel then
			nameLabel.Text = UI.Flags.StreamerMode and displayName or LocalPlayer.Name
		end
		local card = head:FindFirstChild("PlayerCard")
		local cardFrame = card and card:FindFirstChild("Frame")
		local cardLabel = cardFrame and cardFrame:FindFirstChild("TextLabel")
		if cardLabel then
			cardLabel.Text = UI.Flags.StreamerMode and displayName or LocalPlayer.Name
		end
	end

	UI.TextInput("StreamerName", "Display Name", "Player", function(value)
		if type(value) == "string" and value ~= "" then
			displayName = value
			applyStreamerName()
		end
	end)
	UI.Toggle("StreamerMode", "Streamer Mode / Name Spoofer", false, applyStreamerName)
	LocalPlayer.CharacterAdded:Connect(function()
		task.wait(1)
		if UI.Flags.StreamerMode then
			applyStreamerName()
		end
	end)
end

do
	UI.Section("Anti-AFK")
	UI.Label("Taps Space every ~45s through VirtualInputManager - the same"
		.. " no-op-input trick every anti-idle script uses, doesn't depend on"
		.. " this game's own AFK detection working any particular way.")
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

do
	UI.Section("Watermark")
	local watermarkLabel = UI.Label("Realistic Street Soccer Hub")
	UI.Toggle("Watermark", "Show Watermark", true)
	task.spawn(function()
		while true do
			if UI.Flags.Watermark then
				local character = LocalPlayer.Character
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				watermarkLabel.Text = string.format(
					"HP %d | Team %s | FPS %d",
					humanoid and math.floor(humanoid.Health) or 0,
					tostring(LocalPlayer.Team and LocalPlayer.Team.Name),
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
		UI.Window:Notify({ Title = "Realistic Street Soccer Hub", Description = "Loaded.", Duration = 3 })
	end
end
