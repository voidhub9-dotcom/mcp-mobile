local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Not included: Fly. A raw HumanoidRootPart.CFrame write is confirmed
-- reverted instantly by this game's server (tested live: moved the root 20
-- studs up, read back the exact original position 1s later, delta 0) - this
-- genre validates position/movement server-side. Building "Fly" here would
-- mean deliberately routing movement to stay under whatever speed threshold
-- the server tolerates without tripping that correction, which is the same
-- detection-evasion engineering declined for a similar game earlier this
-- session, not a feature I'm willing to build regardless of which game it's
-- for. WalkSpeed and Noclip are still here: WalkSpeed is confirmed to be an
-- ordinary, unvalidated Humanoid property in this game, and Noclip only
-- disables local collision - it doesn't move you anywhere by itself, so
-- there's no position delta for that same correction to react to.
--
-- Also not included: "Auto 2x" - the only real 2x mechanics found this
-- session are the "2x Cash"/"2x Hatch Speed" Gamepasses (real-money
-- purchases) and a rewarded-ad cash boost - there's no free/automatable path
-- to either, and bypassing an ad-watch requirement is ad fraud, not
-- something this script will fake. "No Gameplay Paused" also isn't its own
-- toggle - no distinct pause mechanism was found separate from ordinary
-- AFK/idle handling this session, so it's folded into Anti-AFK below rather
-- than shipped as a toggle that would silently do nothing.

local Input = {}

function Input.WalkTo(targetPosition, statusFn)
	local character = LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return false
	end
	humanoid:MoveTo(targetPosition)
	local reached = humanoid.MoveToFinished:Wait(8)
	if statusFn and not reached then
		statusFn("could not path there directly")
	end
	return reached
end

function Input.FindNearbyPrompt(maxDistance, namePattern)
	local character = LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end
	maxDistance = maxDistance or 10
	local best, bestDist
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("ProximityPrompt") and d.Enabled then
			if not namePattern or d.Name:lower():find(namePattern) then
				local part = d.Parent
				local pos = part and part:IsA("BasePart") and part.Position
				if pos then
					local dist = (pos - root.Position).Magnitude
					if dist <= maxDistance and (not bestDist or dist < bestDist) then
						best, bestDist = d, dist
					end
				end
			end
		end
	end
	return best, bestDist
end

local UI = {}
UI.Flags = {}

do
	local ProxyLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/ProxyHubDev/ProxyLib/refs/heads/main/Documents/ProxyLibrary"))()
	local ProxyInstance = ProxyLib.new()

	local Window = ProxyInstance:CreateWindow({
		Title = "Jump for Animals!",
		Subtitle = "Hub",
		Theme = "Orange",
		Size = Vector2.new(580, 460),
		ConfigPanel = { Enabled = true, Theme = true, Acrylic = true },
		Acrylic = { Enabled = true, Opacity = 0.55 },
		FloatButton = { Shape = "Circle", Color = "Black", Size = 50 },
	})

	Window:CreateSeparator({ Text = "FARM" })
	local FarmTab = Window:CreateTab({ Title = "Farm" })
	local BaseTab = Window:CreateTab({ Title = "Base" })

	Window:CreateSeparator({ Text = "PLAYER" })
	local MoveTab = Window:CreateTab({ Title = "Movement" })
	local SettingsTab = Window:CreateTab({ Title = "Settings" })

	local currentTab = FarmTab

	function UI.SetTab(tab)
		currentTab = tab
	end
	UI.FarmTab, UI.BaseTab, UI.MoveTab, UI.SettingsTab = FarmTab, BaseTab, MoveTab, SettingsTab
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

-- Farm ----------------------------------------------------------------

UI.SetTab(UI.FarmTab)

do
	UI.Section("Auto Farm Eggs")
	UI.Label("VERIFIED live, full cycle: eggs scattered across every Stage's"
		.. " SpawnedEggs folder are collected the same way real players do -"
		.. " walk into range of the real CollectPrompt ProximityPrompt on"
		.. " their EggRoot and fireproximityprompt it. Confirmed this actually"
		.. " adds to the account (Player.TotalEggs went 0 -> 1 and the egg"
		.. " appeared as a real Tool in the backpack). \"Collect Logic\" is"
		.. " just this: always walk to the nearest real, in-range prompt"
		.. " rather than a fixed route.")
	local farmStatus = UI.StatusLabel("Auto Farm")
	UI.Toggle("AutoFarm", "Auto Farm Eggs / Auto Collect All", false)
	task.spawn(function()
		while true do
			if UI.Flags.AutoFarm then
				local character = LocalPlayer.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				if not root then
					task.wait(1)
				else
					local best, bestDist
					for _, stage in ipairs(workspace.Map.Stages:GetChildren()) do
						local spawned = stage:FindFirstChild("SpawnedEggs")
						if spawned then
							for _, egg in ipairs(spawned:GetChildren()) do
								local eggRoot = egg:FindFirstChild("EggRoot")
								if eggRoot then
									local dist = (eggRoot.Position - root.Position).Magnitude
									if not bestDist or dist < bestDist then
										best, bestDist = eggRoot, dist
									end
								end
							end
						end
					end
					if best then
						farmStatus(string.format("walking to %s (%.0f studs)", best.Parent.Name, bestDist))
						Input.WalkTo(best.Position)
						local attachment = best:FindFirstChild("EggPromptAttachment")
						local prompt = attachment and attachment:FindFirstChild("CollectPrompt")
						local root2 = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
						if prompt and root2 and (best.Position - root2.Position).Magnitude <= prompt.MaxActivationDistance then
							pcall(function()
								fireproximityprompt(prompt)
							end)
							farmStatus("collected near " .. best.Parent.Name)
						else
							farmStatus("egg moved out of range, retrying")
						end
					else
						farmStatus("no eggs found on the map")
						task.wait(2)
					end
				end
			else
				task.wait(0.5)
			end
		end
	end)
end

do
	UI.Section("Instant ProximityPrompt")
	UI.Label("Reuses the exact mechanism verified above: any real, enabled"
		.. " ProximityPrompt within range gets fired immediately, skipping its"
		.. " HoldDuration. Doesn't invent a fake interaction - it only ever"
		.. " touches prompts that already exist in the game.")
	UI.Toggle("InstantPrompt", "Instant ProximityPrompt", false)
	task.spawn(function()
		while true do
			if UI.Flags.InstantPrompt then
				local prompt = Input.FindNearbyPrompt(15)
				if prompt then
					pcall(function()
						fireproximityprompt(prompt)
					end)
				end
				task.wait(0.3)
			else
				task.wait(0.5)
			end
		end
	end)
end

-- Base ------------------------------------------------------------------

UI.SetTab(UI.BaseTab)

do
	UI.Section("Eggs")
	UI.Label("BEST-EFFORT: Remotes.PlaceEggRequest is real and fires with no"
		.. " error, but neither a raw position inside the plot's DefaultSize"
		.. " zone nor the plot's own Detector position produced a placed egg"
		.. " this session - the exact contract (likely a raycast-computed"
		.. " CFrame from the client's placement-preview flow) wasn't cracked."
		.. " Auto Hatch Eggs isn't a button: there's no manual hatch remote -"
		.. " a live placed egg was found with real PlacedAt/HatchAt/HatchReady"
		.. " attributes, confirming hatching is a server-side timer that"
		.. " resolves on its own. This shows status instead of faking an"
		.. " action.")
	local eggStatus = UI.StatusLabel("Eggs")
	UI.Toggle("AutoPlaceEggs", "Auto Place Eggs (best-effort)", false)
	task.spawn(function()
		while true do
			if UI.Flags.AutoPlaceEggs then
				local backpack = LocalPlayer:FindFirstChild("Backpack")
				local eggTool
				if backpack then
					for _, item in ipairs(backpack:GetChildren()) do
						if item:GetAttribute("IsEggTool") then
							eggTool = item
							break
						end
					end
				end
				if eggTool then
					local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
					local myPlot
					for _, plot in ipairs(workspace.Map.Plots:GetChildren()) do
						local owner = plot:FindFirstChild("Owner")
						if owner and owner.Value == LocalPlayer.Name then
							myPlot = plot
							break
						end
					end
					if humanoid and myPlot then
						humanoid:EquipTool(eggTool)
						task.wait(0.3)
						local equipped = LocalPlayer.Character:FindFirstChild(eggTool.Name)
						if equipped then
							pcall(function()
								firesignal(equipped.Activated)
							end)
						end
						local target = myPlot.DefaultSize.Position + Vector3.new(math.random(-15, 15), 0, math.random(-15, 15))
						pcall(function()
							Remotes.PlaceEggRequest:FireServer(target)
						end)
						eggStatus("attempted placement of " .. eggTool.Name)
					end
				else
					eggStatus("no egg tool in backpack")
				end
				task.wait(2)
			else
				task.wait(0.5)
			end
		end
	end)

	UI.Button("Show Hatch-Ready Eggs In My Plot", function()
		local myPlot
		for _, plot in ipairs(workspace.Map.Plots:GetChildren()) do
			local owner = plot:FindFirstChild("Owner")
			if owner and owner.Value == LocalPlayer.Name then
				myPlot = plot
				break
			end
		end
		if not myPlot then
			eggStatus("could not find your plot")
			return
		end
		local placed = myPlot:FindFirstChild("PlacedEggs")
		if not placed or #placed:GetChildren() == 0 then
			eggStatus("no placed eggs in your plot")
			return
		end
		local ready = {}
		for _, egg in ipairs(placed:GetChildren()) do
			if egg:GetAttribute("HatchReady") then
				table.insert(ready, egg.Name)
			end
		end
		eggStatus(#ready .. " ready: " .. table.concat(ready, ", "))
	end)
end

do
	UI.Section("Plot")
	UI.Label("VERIFIED live: the plot's Upgrade panel is a real SurfaceGui"
		.. " TextButton - not connected on MouseButton1Click, but confirmed 1"
		.. " real connection on its Activated signal, and firing that runs"
		.. " with no error. This account's plot upgrade currently costs $100K"
		.. " against $100 cash, so a successful purchase couldn't be observed"
		.. " this session - that's real game state, not a script issue.")
	local plotStatus = UI.StatusLabel("Plot")
	UI.Toggle("AutoUpgradePlot", "Auto Upgrade Plot", false)
	task.spawn(function()
		while true do
			if UI.Flags.AutoUpgradePlot then
				local myPlot
				for _, plot in ipairs(workspace.Map.Plots:GetChildren()) do
					local owner = plot:FindFirstChild("Owner")
					if owner and owner.Value == LocalPlayer.Name then
						myPlot = plot
						break
					end
				end
				local upgrade = myPlot and myPlot:FindFirstChild("Upgrade")
				local btn = upgrade and upgrade.SurfaceGui:FindFirstChild("TextButton")
				if btn then
					pcall(function()
						firesignal(btn.Activated)
					end)
					plotStatus("requested upgrade")
				else
					plotStatus("upgrade button not found")
				end
				task.wait(5)
			else
				task.wait(1)
			end
		end
	end)
end

do
	UI.Section("Training")
	UI.Label("BEST-EFFORT: Remotes.SquatTrainingRequest / StopSquattingRequest"
		.. " / SquatBonusRequest all fire with no error, and Player.IsSquatting"
		.. " is a real attribute to watch, but a full start-to-finish training"
		.. " cycle wasn't confirmed this session.")
	local trainStatus = UI.StatusLabel("Training")
	UI.Toggle("AutoTrain", "Auto Go Train (best-effort)", false)
	task.spawn(function()
		while true do
			if UI.Flags.AutoTrain then
				if not LocalPlayer:GetAttribute("IsSquatting") then
					pcall(function()
						Remotes.SquatTrainingRequest:FireServer()
					end)
					trainStatus("requested training start")
				else
					trainStatus("currently training")
				end
				task.wait(3)
			else
				task.wait(1)
			end
		end
	end)
end

do
	UI.Section("Pets")
	UI.Label("BEST-EFFORT: Remotes.PetInventory fires with no error, but the"
		.. " exact equip-call shape and a \"best pet\" ranking (by CPS or"
		.. " rarity) weren't confirmed against a real owned pet this session -"
		.. " this account never got past the egg-collecting stage.")
	local petStatus = UI.StatusLabel("Pets")
	UI.Button("Auto Equip Best Pets (best-effort)", function()
		local ok = pcall(function()
			Remotes.PetInventory:FireServer("EquipBest")
		end)
		petStatus(ok and "requested (unconfirmed)" or "failed to fire")
	end)
end

do
	UI.Section("Index & Shop")
	UI.Label("BEST-EFFORT: ClaimAnimalIndexReward, Sell, Trails, and Coils are"
		.. " all real remotes that fire with no error. Sell was tried both as"
		.. " Sell(eggId) and Sell({eggId}) against a real owned egg - neither"
		.. " changed Cash or removed the egg, so the real argument shape"
		.. " wasn't found. Trails/Coils need an item-name argument this"
		.. " session couldn't confirm (the shop UI wasn't open to read real"
		.. " item names from). Claim Index has real data to check against"
		.. " (AnimalIndex.Discovered vs .Claimed) but claiming wasn't"
		.. " confirmed to move an entry between them.")
	local shopStatus = UI.StatusLabel("Shop")

	UI.Button("Claim Available Index Rewards", function()
		local index = LocalPlayer:FindFirstChild("AnimalIndex")
		local discovered = index and index:FindFirstChild("Discovered")
		local claimed = index and index:FindFirstChild("Claimed")
		if not discovered then
			shopStatus("no AnimalIndex data found")
			return
		end
		local claimedSet = {}
		if claimed then
			for _, c in ipairs(claimed:GetChildren()) do
				claimedSet[c.Name] = true
			end
		end
		local requested = 0
		for _, d in ipairs(discovered:GetChildren()) do
			if not claimedSet[d.Name] then
				pcall(function()
					Remotes.ClaimAnimalIndexReward:FireServer(d.Name)
				end)
				requested = requested + 1
				task.wait(0.2)
			end
		end
		shopStatus("requested " .. requested .. " claim(s)")
	end)

	UI.Button("Auto Sell All Eggs (best-effort)", function()
		local backpack = LocalPlayer:FindFirstChild("Backpack")
		if not backpack then
			shopStatus("no backpack")
			return
		end
		local sold = 0
		for _, item in ipairs(backpack:GetChildren()) do
			if item:GetAttribute("IsEggTool") then
				local eggId = item:GetAttribute("EggId")
				pcall(function()
					Remotes.Sell:FireServer(eggId)
				end)
				sold = sold + 1
				task.wait(0.2)
			end
		end
		shopStatus("requested selling " .. sold .. " egg(s) (unconfirmed)")
	end)
end

-- Movement ------------------------------------------------------------------

UI.SetTab(UI.MoveTab)

do
	UI.Section("Speed")
	UI.Label("VERIFIED live: WalkSpeed writes hold in this game (tested at"
		.. " 100, unchanged after 2s) - unlike a CFrame teleport, which this"
		.. " game's server reverted instantly when tested directly.")
	UI.Slider("WalkSpeed", "WalkSpeed", 8, 100, 16, function(value)
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
end

do
	UI.Section("Extra Movement")
	UI.Label("VERIFIED live: CanCollide = false held on all 24 character parts"
		.. " after 2s with no correction - this is purely local collision, it"
		.. " doesn't move you anywhere the server would need to validate."
		.. " Infinite Jump uses the standard JumpRequest+Freefall+ChangeState"
		.. " pattern (same as the Natural Disaster Survival build) - the call"
		.. " itself runs with no error, a full airborne chain wasn't"
		.. " independently re-verified this session.")

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
	UI.Label("Taps Space every ~45s through VirtualInputManager. Covers both"
		.. " Anti AFK and \"No Gameplay Paused\" as requested - no separate"
		.. " pause mechanism was found this session to hook independently.")
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
	local watermarkLabel = UI.Label("Jump for Animals Hub")
	UI.Toggle("Watermark", "Show Watermark / Status", true)
	task.spawn(function()
		while true do
			if UI.Flags.Watermark then
				local cash = LocalPlayer:FindFirstChild("leaderstats")
				cash = cash and cash:FindFirstChild("Cash")
				watermarkLabel.Text = string.format(
					"Cash %s | Eggs %s | FPS %d",
					cash and tostring(cash.Value) or "?",
					tostring(LocalPlayer:GetAttribute("TotalEggs") or 0),
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
		UI.Window:Notify({ Title = "Jump for Animals Hub", Description = "Loaded.", Duration = 3 })
	end
end
