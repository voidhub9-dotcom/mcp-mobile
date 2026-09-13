-- No remote dependency during startup.  A failed external attack module used to
if not game:IsLoaded() then pcall(function() game.Loaded:Wait() end) end
local Y = game.Players;
local d = Y.LocalPlayer;
local initialCharacter = d.Character or d.CharacterAdded:Wait();
local R = initialCharacter:WaitForChild("HumanoidRootPart", 15);
local Q = game:GetService("ReplicatedStorage");
local PlayerData = d:WaitForChild("Data", 20);
local LevelValue = PlayerData and PlayerData:FindFirstChild("Level");
local r = LevelValue and LevelValue.Value or 0;
local a = game:GetService("TeleportService");
local w = game:GetService("TweenService");
local F = game:GetService("Lighting");
local M = workspace:FindFirstChild("Enemies") or workspace:WaitForChild("Enemies", 20);
local K = game:GetService("VirtualInputManager");
local n = game:GetService("VirtualUser");
local I = d.Team;
local W = game:GetService("RunService");
local N = game:GetService("Stats");
local EnergyValue = initialCharacter:FindFirstChild("Energy") or initialCharacter:WaitForChild("Energy", 10);
local D = EnergyValue and EnergyValue.Value or 0;
local A = game:GetService("Players");
local u = A.LocalPlayer:WaitForChild("PlayerGui");
local g = A.LocalPlayer;
local z = g:WaitForChild("Backpack");
local i = g.Character or g.CharacterAdded:Wait();
local U = {};
local C = {};
local v = {};
local m = {};
local y = false;
local b = false;
local c = true;
local H = false;
local S = false;
local o = false;
local Z = false;
local T = .1;
local L = 0;
local P = 25;
-- Compatibility aliases for new system
plr = d
replicated = Q
Root = R
C = R
Lv = r
TeleportService = a
TW = w
Lighting = F
Enemies = M
vim1 = K
vim2 = n
TeamSelf = I
RunSer = W
Stats = N
Energy = D
shouldTween = false
d.CharacterAdded:Connect(function(character)
    local root = character:WaitForChild("HumanoidRootPart", 10)
    if root and d.Character == character then
        i, R, Root, C, HRP = character, root, root, root, root
    end
end)
if LevelValue then
	LevelValue:GetPropertyChangedSignal("Value"):Connect(function()
		r, Lv = LevelValue.Value, LevelValue.Value
	end)
end


if not game:IsLoaded() then
	pcall(function() game.Loaded:Wait() end);
end;
World1, World2, World3 = false, false, false;
if game.PlaceId == 2753915549 or game.PlaceId == 85211729168715 then
	World1 = true;
elseif game.PlaceId == 4442272183 or game.PlaceId == 79091703265657 then
	World2 = true;
elseif game.PlaceId == 7449423635 or game.PlaceId == 100117331123089 then
	World3 = true;
end;
Marines = function()
		Q.Remotes.CommF_:InvokeServer("SetTeam", "Marines");
	end;

-- SUBMERGED ISLAND AUTO-TELEPORT (3rd Sea)

function HandleSubmergedIslandTeleport(playerLevel, questPos, hrp)
	if not hrp then return false end
	
	-- Check if player is at Submerged Island level range
	if playerLevel >= 2600 then
		local distance = (questPos.Position - hrp.Position).Magnitude
		
		if distance > 10000 then
			local tikiNPC = CFrame.new(-16269.7041, 25.2288494, 1373.65955, 0.99739098, 1.47309942e-09, -0.07218909, -4.00651912e-09, 0.99999994, -2.51183763e-09, 0.07218908, 5.75363091e-10, 0.99739092)
			_tp(tikiNPC)
			task.wait(2)
			
			-- Trigger submarine worker to travel to Submerged Island
			local args = {"TravelToSubmergedIsland"}
			pcall(function()
				game:GetService("ReplicatedStorage").Modules.Net:FindFirstChild("RF/SubmarineWorkerSpeak"):InvokeServer(unpack(args))
			end)
			
			print("[OK] Traveling to Submerged Island...")
			return true
		end
	end
	
	return false
end


Pirates = function()
		Q.Remotes.CommF_:InvokeServer("SetTeam", "Pirates");
	end;
-- BACKGROUND VIDEO (VonLib API)
-- Set background video on the UI window
if _Window then
	task.spawn(function()
		task.wait(1)
		_Window:SetBackgroundVideo("https://files.catbox.moe/5f9loy.webm", 0.5)
		print("[OK] Background video loaded on UI")
	end)
end

-- TEXT GRADIENT SUPPORT
function CreateGradientLabel(parent, text, colors, rotation)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 30)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextSize = 13
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Parent = parent
	
	local gradient = Instance.new("UIGradient")
	gradient.Parent = label
	
	if colors and #colors >= 2 then
		local colorSequence = {}
		for i, color in ipairs(colors) do
			table.insert(colorSequence, ColorSequenceKeypoint.new((i - 1) / (#colors - 1), color))
		end
		gradient.Color = ColorSequence.new(colorSequence)
	else
		gradient.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(138, 43, 226)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 255, 255))
		}
	end
	
	gradient.Rotation = rotation or 0
	return label
end

function UpdateGradientLabel(label, newText, newColors, newRotation)
	if label and label:IsA("TextLabel") then
		if newText then label.Text = newText end
		
		local gradient = label:FindFirstChildOfClass("UIGradient")
		if gradient then gradient:Destroy() end
		
		gradient = Instance.new("UIGradient")
		gradient.Parent = label
		
		if newColors and #newColors >= 2 then
			local colorSequence = {}
			for i, color in ipairs(newColors) do
				table.insert(colorSequence, ColorSequenceKeypoint.new((i - 1) / (#newColors - 1), color))
			end
			gradient.Color = ColorSequence.new(colorSequence)
		end
		
		if newRotation then gradient.Rotation = newRotation end
	end
end

-- IMPROVED MOB HEIGHT & BRING SYSTEM
_G.MobHeight = _G.MobHeight or 20
_B = false
PosMon = nil
_G.BringRange = _G.BringRange or 235
_G.MaxBringMobs = _G.MaxBringMobs or 3

local BRING_TWEEN_SPEED = 180
local function TweenInfoBringFor(dist)
	return TweenInfo.new(math.max(0.05, dist / BRING_TWEEN_SPEED), Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
end
local function zeroVelocity(part)
	if not part then return end
	pcall(function()
		part.AssemblyLinearVelocity = Vector3.zero
		part.AssemblyAngularVelocity = Vector3.zero
	end)
end

-- restores it once travel finishes.
local function setCharacterNoclip(char, on)
	if not char then return end
	pcall(function()
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = not on
			end
		end
	end)
end

local function IsRaidMob(mob)
	local n = mob.Name:lower()
	if n:find("raid") or n:find("microchip") or n:find("island") then return true end
	if mob:GetAttribute("IsRaid") or mob:GetAttribute("RaidMob") or mob:GetAttribute("IsBoss") then return true end
	local hum = mob:FindFirstChild("Humanoid")
	if hum and hum.WalkSpeed == 0 then return true end
	if mob.Parent and tostring(mob.Parent):lower():find("_worldorigin") then return true end
	return false
end

BringEnemy = function()
	if not _B then return end
	local char = plr.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	
	pcall(function() sethiddenproperty(plr, "SimulationRadius", math.huge) end)
	
	local targetPos = PosMon or hrp.Position
	local enemies = workspace.Enemies:GetChildren()
	local count = 0
	
	for _, mob in ipairs(enemies) do
		if count >= _G.MaxBringMobs then break end
		local hum = mob:FindFirstChild("Humanoid")
		local root = mob:FindFirstChild("HumanoidRootPart")
		
		if hum and root and hum.Health > 0 and not IsRaidMob(mob) then
			local dist = (root.Position - targetPos).Magnitude
			if dist <= _G.BringRange and not root:GetAttribute("Tweening") then
				count = count + 1
				root:SetAttribute("Tweening", true)
				local tween = w:Create(root, TweenInfoBringFor(dist), { CFrame = CFrame.new(targetPos) })
				tween:Play()
				tween.Completed:Once(function()
					if root then
						zeroVelocity(root)
						root:SetAttribute("Tweening", false)
					end
				end)
			end
		end
	end
end

(function()
if World1 then
	U = {
			"The Gorilla King",
			"Bobby",
			"The Saw",
			"Yeti",
			"Mob Leader",
			"Vice Admiral",
			"Saber Expert",
			"Warden",
			"Chief Warden",
			"Swan",
			"Magma Admiral",
			"Fishman Lord",
			"Wysper",
			"Thunder God",
			"Cyborg",
			"Ice Admiral",
			"Greybeard",
		};
elseif World2 then
	U = {
			"Diamond",
			"Jeremy",
			"Fajita",
			"Don Swan",
			"Smoke Admiral",
			"Awakened Ice Admiral",
			"Tide Keeper",
			"Darkbeard",
			"Cursed Captain",
			"Order",
		};
elseif World3 then
	U = {
			"Stone",
			"Hydra Leader",
			"Kilo Admiral",
			"Captain Elephant",
			"Beautiful Pirate",
			"Cake Queen",
			"Longma",
			"Soul Reaper",
		};
end;
end)()
(function()
if World1 then
	v = {
			"Leather + Scrap Metal",
			"Angel Wings",
			"Magma Ore",
			"Fish Tail",
		};
elseif World2 then
	v = {
			"Leather + Scrap Metal",
			"Radioactive Material",
			"Ectoplasm",
			"Mystic Droplet",
			"Magma Ore",
			"Vampire Fang",
		};
elseif World3 then
	v = {
			"Scrap Metal",
			"Demonic Wisp",
			"Conjured Cocoa",
			"Dragon Scale",
			"Gunpowder",
			"Fish Tail",
			"Mini Tusk",
		};
end;
end)()
local j = {
		"Flame",
		"Ice",
		"Quake",
		"Light",
		"Dark",
		"String",
		"Rumble",
		"Magma",
		"Human: Buddha",
		"Sand",
		"Bird: Phoenix",
		"Dough",
	};
local G = {
		"Snow Lurker",
		"Arctic Warrior",
		"Hidden Key",
		"Awakened Ice Admiral",
	};
local q = {
		Mob = "Mythological Pirate",
		Mob2 = "Cursed Skeleton",
		"Hell\'s Messenger",
		Mob3 = "Cursed Skeleton",
		"Heaven\'s Guardian",
	};
local t = {
		"Part",
		"SpawnLocation",
		"Terrain",
		"WedgePart",
		"MeshPart",
	};
local X = { "Swan Pirate", "Jeremy" };
local h = { "Forest Pirate", "Captain Elephant" };
local B = { "Fajita", "Jeremy", "Diamond" };
local l = {
		"Beast Hunter",
		"Lantern",
		"Guardian",
		"Grand Brigade",
		"Dinghy",
		"Sloop",
		"The Sentinel",
	};
local p = { "Cookie Crafter" };
local E = { "Reborn Skeleton" };
local e = {
		["Pirate Millionaire"] = CFrame.new(-712.82727050, 98.57704925, 5711.95410156),
		["Pistol Billionaire"] = CFrame.new(-723.43316650, 147.42906188, 5931.99316406),
		["Dragon Crew Warrior"] = CFrame.new(7021.50439453, 55.76270294, -730.12908935),
		["Dragon Crew Archer"] = CFrame.new(6625, 378, 244),
		["Female Islander"] = CFrame.new(4692.79394531, 797.97668457, 858.84802246),
		["Venomous Assailant"] = CFrame.new(4902, 670, 39),
		["Marine Commodore"] = CFrame.new(2401, 123, -7589),
		["Marine Rear Admiral"] = CFrame.new(3588, 229, -7085),
		["Fishman Raider"] = CFrame.new(-10941, 332, -8760),
		["Fishman Captain"] = CFrame.new(-11035, 332, -9087),
		["Forest Pirate"] = CFrame.new(-13446, 413, -7760),
		["Mythological Pirate"] = CFrame.new(-13510, 584, -6987),
		["Jungle Pirate"] = CFrame.new(-11778, 426, -10592),
		["Musketeer Pirate"] = CFrame.new(-13282, 496, -9565),
		["Reborn Skeleton"] = CFrame.new(-8764, 142, 5963),
		["Living Zombie"] = CFrame.new(-10227, 421, 6161),
		["Demonic Soul"] = CFrame.new(-9579, 6, 6194),
		["Posessed Mummy"] = CFrame.new(-9579, 6, 6194),
		["Peanut Scout"] = CFrame.new(-1993, 187, -10103),
		["Peanut President"] = CFrame.new(-2215, 159, -10474),
		["Ice Cream Chef"] = CFrame.new(-877, 118, -11032),
		["Ice Cream Commander"] = CFrame.new(-877, 118, -11032),
		["Cookie Crafter"] = CFrame.new(-2021, 38, -12028),
		["Cake Guard"] = CFrame.new(-2024, 38, -12026),
		["Baking Staff"] = CFrame.new(-1932, 38, -12848),
		["Head Baker"] = CFrame.new(-1932, 38, -12848),
		["Cocoa Warrior"] = CFrame.new(95, 73, -12309),
		["Chocolate Bar Battler"] = CFrame.new(647, 42, -12401),
		["Sweet Thief"] = CFrame.new(116, 36, -12478),
		["Candy Rebel"] = CFrame.new(47, 61, -12889),
		Ghost = CFrame.new(5251, 5, 1111),
	};
EquipWeapon = function(Y)
		if not Y then
			return;
		end;
		if d.Backpack:FindFirstChild(Y) then
			d.Character.Humanoid:EquipTool(d.Backpack:FindFirstChild(Y));
		end;
	end;
weaponSc = function(Y)
		for d, R in pairs(d.Backpack:GetChildren()) do
			if R:IsA("Tool") then
				if R.ToolTip == Y then
					EquipWeapon(R.Name);
				end;
			end;
		end;
	end;
local O = workspace:FindFirstChild("Rocks");
if O then
	O:Destroy();
end;
gay = (function()
		local Y = game:GetService("Lighting");
		local d = Y:FindFirstChild("LightingLayers");
		if d and (game:GetService("Lighting") and game:GetService("Lighting")) then
			local Y = d:FindFirstChild("DarkFog");
			if Y then
				Y:Destroy();
			end;
		end;
		local R = workspace:FindFirstChild("_WorldOrigin");
		R = R and R:FindFirstChild("Foam;");
		if R then
			R:Destroy();
		end;
	end)();
local f = {};
f.__index = f;
f.Alive = function(Y)
		if not Y then
			return;
		end;
		local d = Y:FindFirstChild("Humanoid");
		return d and d.Health > 0;
	end;
f.Pos = function(Y, d)
		return (R.Position - Y.Position).Magnitude <= d;
	end;
f.Dist = function(Y, d)
		return (R.Position - (Y:FindFirstChild("HumanoidRootPart")).Position).Magnitude <= d;
	end;
f.DistH = function(Y, d)
		return (R.Position - (Y:FindFirstChild("HumanoidRootPart")).Position).Magnitude > d;
	end;
f.LastActivate = 0;
f.Activate = function()
	local now = os.clock()
	if now - f.LastActivate < .16 then return false end
	local character = d.Character
	local tool = character and character:FindFirstChildOfClass("Tool")
	if not tool and _G.SelectWeapon then
		pcall(function() EquipWeapon(_G.SelectWeapon) end)
		tool = character and character:FindFirstChildOfClass("Tool")
	end
	if not tool then return false end
	f.LastActivate = now
	return pcall(function() tool:Activate() end)
end;
f.Kill = function(Y, d)
		if Y and d then
			if not Y:GetAttribute("Locked") then
				Y:SetAttribute("Locked", Y.HumanoidRootPart.CFrame);
			end;
			PosMon = (Y:GetAttribute("Locked")).Position;
			BringEnemy();
			EquipWeapon(_G.SelectWeapon);
			local d = game.Players.LocalPlayer.Character:FindFirstChildOfClass("Tool");
			local R = d and d.ToolTip or "";
			if R == "Blox Fruit" then
				_tp((Y.HumanoidRootPart.CFrame * CFrame.new(0, 10, 0)) * CFrame.Angles(0, math.rad(90), 0));
			else
				_tp((Y.HumanoidRootPart.CFrame * CFrame.new(0, 30, 0)) * CFrame.Angles(0, math.rad(180), 0));
			end;
			if RandomCFrame then
				task.wait(.5);
				_tp(Y.HumanoidRootPart.CFrame * CFrame.new(0, 30, 25));
				task.wait(.5);
				_tp(Y.HumanoidRootPart.CFrame * CFrame.new(25, 30, 0));
				task.wait(.5);
				_tp(Y.HumanoidRootPart.CFrame * CFrame.new(-25, 30, 0));
				task.wait(.5);
				_tp(Y.HumanoidRootPart.CFrame * CFrame.new(0, 30, 25));
				task.wait(.5);
				_tp(Y.HumanoidRootPart.CFrame * CFrame.new(-25, 30, 0));
			end;
			f.Activate();
		end;
	end;
f.Kill2 = function(Y, d)
		if Y and d then
			if not Y:GetAttribute("Locked") then
				Y:SetAttribute("Locked", Y.HumanoidRootPart.CFrame);
			end;
			PosMon = (Y:GetAttribute("Locked")).Position;
			BringEnemy();
			EquipWeapon(_G.SelectWeapon);
			local d = game.Players.LocalPlayer.Character:FindFirstChildOfClass("Tool");
			local R = d and d.ToolTip or "";
			if R == "Blox Fruit" then
				_tp((Y.HumanoidRootPart.CFrame * CFrame.new(0, 10, 0)) * CFrame.Angles(0, math.rad(90), 0));
			else
				_tp((Y.HumanoidRootPart.CFrame * CFrame.new(0, 30, 8)) * CFrame.Angles(0, math.rad(180), 0));
			end;
			if RandomCFrame then
				task.wait(.1);
				_tp(Y.HumanoidRootPart.CFrame * CFrame.new(0, 30, 25));
				task.wait(.1);
				_tp(Y.HumanoidRootPart.CFrame * CFrame.new(25, 30, 0));
				task.wait(.1);
				_tp(Y.HumanoidRootPart.CFrame * CFrame.new(-25, 30, 0));
				task.wait(.1);
				_tp(Y.HumanoidRootPart.CFrame * CFrame.new(0, 30, 25));
				task.wait(.1);
				_tp(Y.HumanoidRootPart.CFrame * CFrame.new(-25, 30, 0));
			end;
		end;
	end;
f.KillSea = function(Y, d)
		if Y and d then
			if not Y:GetAttribute("Locked") then
				Y:SetAttribute("Locked", Y.HumanoidRootPart.CFrame);
			end;
			PosMon = (Y:GetAttribute("Locked")).Position;
			BringEnemy();
			EquipWeapon(_G.SelectWeapon);
			local d = game.Players.LocalPlayer.Character:FindFirstChildOfClass("Tool");
			local R = d and d.ToolTip or "";
			if R == "Blox Fruit" then
				_tp((Y.HumanoidRootPart.CFrame * CFrame.new(0, 10, 0)) * CFrame.Angles(0, math.rad(90), 0));
			else
				notween(Y.HumanoidRootPart.CFrame * CFrame.new(0, 50, 8));
				task.wait(.85);
				notween(Y.HumanoidRootPart.CFrame * CFrame.new(0, 400, 0));
				task.wait(1);
			end;
		end;
	end;
f.Sword = function(Y, d)
		if Y and d then
			if not Y:GetAttribute("Locked") then
				Y:SetAttribute("Locked", Y.HumanoidRootPart.CFrame);
			end;
			PosMon = (Y:GetAttribute("Locked")).Position;
			BringEnemy();
			weaponSc("Sword");
			_tp(Y.HumanoidRootPart.CFrame * CFrame.new(0, 30, 0));
			if RandomCFrame then
				task.wait(.1);
				_tp(Y.HumanoidRootPart.CFrame * CFrame.new(0, 30, 25));
				task.wait(.1);
				_tp(Y.HumanoidRootPart.CFrame * CFrame.new(25, 30, 0));
				task.wait(.1);
				_tp(Y.HumanoidRootPart.CFrame * CFrame.new(-25, 30, 0));
				task.wait(.1);
				_tp(Y.HumanoidRootPart.CFrame * CFrame.new(0, 30, 25));
				task.wait(.1);
				_tp(Y.HumanoidRootPart.CFrame * CFrame.new(-25, 30, 0));
			end;
		end;
	end;
f.Mas = function(Y, d)
		if Y and d then
			if not Y:GetAttribute("Locked") then
				Y:SetAttribute("Locked", Y.HumanoidRootPart.CFrame);
			end;
			PosMon = (Y:GetAttribute("Locked")).Position;
			BringEnemy();
			if Y.Humanoid.Health <= HealthM then
				_tp(Y.HumanoidRootPart.CFrame * CFrame.new(0, 20, 0));
				Useskills("Blox Fruit", "Z");
				Useskills("Blox Fruit", "X");
				Useskills("Blox Fruit", "C");
			else
				weaponSc("Melee");
				_tp(Y.HumanoidRootPart.CFrame * CFrame.new(0, 30, 0));
			end;
		end;
	end;
f.Masgun = function(Y, d)
		if Y and d then
			if not Y:GetAttribute("Locked") then
				Y:SetAttribute("Locked", Y.HumanoidRootPart.CFrame);
			end;
			PosMon = (Y:GetAttribute("Locked")).Position;
			BringEnemy();
			if Y.Humanoid.Health <= HealthM then
				_tp(Y.HumanoidRootPart.CFrame * CFrame.new(0, 35, 8));
				Useskills("Gun", "Z");
				Useskills("Gun", "X");
			else
				weaponSc("Melee");
				_tp(Y.HumanoidRootPart.CFrame * CFrame.new(0, 30, 0));
			end;
		end;
	end;
statsSetings = function(Y, R)
		if Y == "Melee" then
			if d.Data.Points.Value ~= 0 then
				Q.Remotes.CommF_:InvokeServer("AddPoint", "Melee", R);
			end;
		elseif Y == "Defense" then
			if d.Data.Points.Value ~= 0 then
				Q.Remotes.CommF_:InvokeServer("AddPoint", "Defense", R);
			end;
		elseif Y == "Sword" then
			if d.Data.Points.Value ~= 0 then
				Q.Remotes.CommF_:InvokeServer("AddPoint", "Sword", R);
			end;
		elseif Y == "Gun" then
			if d.Data.Points.Value ~= 0 then
				Q.Remotes.CommF_:InvokeServer("AddPoint", "Gun", R);
			end;
		elseif Y == "Devil" then
			if d.Data.Points.Value ~= 0 then
				Q.Remotes.CommF_:InvokeServer("AddPoint", "Demon Fruit", R);
			end;
		end;
	end;
BringEnemy = function()
		if not _B then
			return;
		end;
		local moved = 0;
		local enemies = workspace:FindFirstChild("Enemies");
		for Y, R in pairs(enemies and enemies:GetChildren() or {}) do
			local primary = R.PrimaryPart or R:FindFirstChild("HumanoidRootPart");
			if primary and R:FindFirstChild("Humanoid") and R.Humanoid.Health > 0 then
				if moved < 18 and typeof(PosMon) == "Vector3" and (primary.Position - PosMon).Magnitude <= 350 then
					primary.CFrame = CFrame.new(PosMon + Vector3.new((moved % 3) * 1.5, 0, math.floor(moved / 3) * 1.5));
					primary.CanCollide = false;
					(R:FindFirstChild("Humanoid")).WalkSpeed = 0;
					(R:FindFirstChild("Humanoid")).JumpPower = 0;
					moved = moved + 1;
					if sethiddenproperty then pcall(sethiddenproperty, d, "SimulationRadius", math.huge); end;
				end;
			end;
		end;
	end;
Useskills = function(Y, d)
		if Y == "Melee" then
			weaponSc("Melee");
			if d == "Z" then
				K:SendKeyEvent(true, "Z", false, game);
				K:SendKeyEvent(false, "Z", false, game);
			elseif d == "X" then
				K:SendKeyEvent(true, "X", false, game);
				K:SendKeyEvent(false, "X", false, game);
			elseif d == "C" then
				K:SendKeyEvent(true, "C", false, game);
				K:SendKeyEvent(false, "C", false, game);
			end;
		elseif Y == "Sword" then
			weaponSc("Sword");
			if d == "Z" then
				K:SendKeyEvent(true, "Z", false, game);
				K:SendKeyEvent(false, "Z", false, game);
			elseif d == "X" then
				K:SendKeyEvent(true, "X", false, game);
				K:SendKeyEvent(false, "X", false, game);
			end;
		elseif Y == "Blox Fruit" then
			weaponSc("Blox Fruit");
			if d == "Z" then
				K:SendKeyEvent(true, "Z", false, game);
				K:SendKeyEvent(false, "Z", false, game);
			elseif d == "X" then
				K:SendKeyEvent(true, "X", false, game);
				K:SendKeyEvent(false, "X", false, game);
			elseif d == "C" then
				K:SendKeyEvent(true, "C", false, game);
				K:SendKeyEvent(false, "C", false, game);
			elseif d == "V" then
				K:SendKeyEvent(true, "V", false, game);
				K:SendKeyEvent(false, "V", false, game);
			end;
		elseif Y == "Gun" then
			weaponSc("Gun");
			if d == "Z" then
				K:SendKeyEvent(true, "Z", false, game);
				K:SendKeyEvent(false, "Z", false, game);
			elseif d == "X" then
				K:SendKeyEvent(true, "X", false, game);
				K:SendKeyEvent(false, "X", false, game);
			end;
		end;
		if Y == "nil" and d == "Y" then
			K:SendKeyEvent(true, "Y", false, game);
			K:SendKeyEvent(false, "Y", false, game);
		end;
	end;
local s = getrawmetatable(game);
local x = s.__namecall;
setreadonly(s, false);
s.__namecall = newcclosure(function(...)
		local Y = getnamecallmethod();
		local d = { ... };
		if tostring(Y) == "FireServer" then
			if tostring(d[1]) == "RemoteEvent" then
				if tostring(d[2]) ~= "true" and tostring(d[2]) ~= "false" then
					if _G.FarmMastery_G and not b or _G.FarmMastery_Dev or _G.FarmBlazeEM or _G.Prehis_Skills or _G.SeaBeast1 or _G.FishBoat or _G.PGB or _G.Leviathan1 or _G.Complete_Trials or _G.AimMethod and ABmethod == "AimBots Skill" or _G.AimMethod and ABmethod == "Auto Aimbots" then
						d[2] = MousePos;
						return x(unpack(d));
					end;
				end;
			end;
		end;
		return x(...);
	end);
GetConnectionEnemies = function(Y)
		local wanted = {};
		for _, name in ipairs(typeof(Y) == "table" and Y or {Y}) do wanted[string.lower(tostring(name))] = true end;
		local function matches(model)
			if not model:IsA("Model") then return false end;
			local lower = string.lower(model.Name);
			for name in pairs(wanted) do if lower == name or string.find(lower, name, 1, true) then return true end end;
			return false;
		end;
		local folders = {Q, game.Workspace:FindFirstChild("Enemies"), game.Workspace:FindFirstChild("Characters"), game.Workspace:FindFirstChild("SeaEvents")};
		local seen = {};
		for _, folder in ipairs(folders) do
			for _, R in ipairs(folder and folder:GetChildren() or {}) do
				if not seen[R] and matches(R) and R:FindFirstChildOfClass("Humanoid") and R:FindFirstChildOfClass("Humanoid").Health > 0 then
					seen[R] = true;
					return R;
				end;
			end;
		end;
	end;
LowCpu = function()
		local Y = true;
		local d = game;
		local R = d.Workspace;
		local Q = d.Lighting;
		local r = R.Terrain;
		r.WaterWaveSize = 0;
		r.WaterWaveSpeed = 0;
		r.WaterReflectance = 0;
		r.WaterTransparency = 0;
		Q.GlobalShadows = false;
		Q.FogEnd = 9000000000.0;
		Q.Brightness = 0;
		(settings()).Rendering.QualityLevel = "Level01";
		for d, R in pairs(d:GetDescendants()) do
			if R:IsA("Part") or R:IsA("Union") or R:IsA("CornerWedgePart") or R:IsA("TrussPart") then
				R.Material = "Plastic";
				R.Reflectance = 0;
			elseif R:IsA("Decal") or R:IsA("Texture") and Y then
				R.Transparency = 1;
			elseif R:IsA("ParticleEmitter") or R:IsA("Trail") then
				R.Lifetime = NumberRange.new(0);
			elseif R:IsA("Explosion") then
				R.BlastPressure = 1;
				R.BlastRadius = 1;
			elseif R:IsA("Fire") or R:IsA("SpotLight") or R:IsA("Smoke") or R:IsA("Sparkles") then
				R.Enabled = false;
			elseif R:IsA("MeshPart") then
				R.Material = "Plastic";
				R.Reflectance = 0;
				R.TextureID = 10385902758728957;
			end;
		end;
		for Y, d in pairs(Q:GetChildren()) do
			if d:IsA("BlurEffect") or d:IsA("SunRaysEffect") or d:IsA("ColorCorrectionEffect") or d:IsA("BloomEffect") or d:IsA("DepthOfFieldEffect") then
				d.Enabled = false;
			end;
		end;
	end;
CheckF = function()
		if GetBP("Dragon-Dragon") or GetBP("Gas-Gas") or GetBP("Yeti-Yeti") or GetBP("Kitsune-Kitsune") or GetBP("T-Rex-T-Rex") then
			return true;
		end;
	end;
CheckBoat = function()
		for Y, R in pairs(workspace.Boats:GetChildren()) do
			if tostring(R.Owner.Value) == tostring(d.Name) then
				return R;
			end;
		end;
		return false;
	end;
CheckEnemiesBoat = function()
		for Y, d in pairs(workspace.Enemies:GetChildren()) do
			if d.Name == "FishBoat" and (d:FindFirstChild("Health")).Value > 0 then
				return true;
			end;
		end;
		return false;
	end;
CheckPirateGrandBrigade = function()
		for Y, d in pairs(workspace.Enemies:GetChildren()) do
			if (d.Name == "PirateGrandBrigade" or d.Name == "PirateBrigade") and (d:FindFirstChild("Health")).Value > 0 then
				return true;
			end;
		end;
		return false;
	end;
CheckShark = function()
		for Y, d in pairs(workspace.Enemies:GetChildren()) do
			if d.Name == "Shark" and f.Alive(d) then
				return true;
			end;
		end;
		return false;
	end;
CheckTerrorShark = function()
		for Y, d in pairs(workspace.Enemies:GetChildren()) do
			if d.Name == "Terrorshark" and f.Alive(d) then
				return true;
			end;
		end;
		return false;
	end;
CheckPiranha = function()
		for Y, d in pairs(workspace.Enemies:GetChildren()) do
			if d.Name == "Piranha" and f.Alive(d) then
				return true;
			end;
		end;
		return false;
	end;
CheckFishCrew = function()
		for Y, d in pairs(workspace.Enemies:GetChildren()) do
			if (d.Name == "Fish Crew Member" or d.Name == "Haunted Crew Member") and f.Alive(d) then
				return true;
			end;
		end;
		return false;
	end;
CheckHauntedCrew = function()
		for Y, d in pairs(workspace.Enemies:GetChildren()) do
			if d.Name == "Haunted Crew Member" and f.Alive(d) then
				return true;
			end;
		end;
		return false;
	end;
CheckSeaBeast = function()
		if workspace.SeaBeasts:FindFirstChild("SeaBeast1") then
			return true;
		end;
		return false;
	end;
CheckLeviathan = function()
		if workspace.SeaBeasts:FindFirstChild("Leviathan") then
			return true;
		end;
		return false;
	end;
UpdStFruit = function()
		for Y, R in next, d.Backpack:GetChildren() do
			StoreFruit = R:FindFirstChild("EatRemote", true);
			if StoreFruit then
				Q.Remotes.CommF_:InvokeServer("StoreFruit", StoreFruit.Parent:GetAttribute("OriginalName"), d.Backpack:FindFirstChild(R.Name));
			end;
		end;
	end;
collectFruits = function(Y)
		if Y then
			local Y = d.Character;
			for d, R in pairs(workspace:GetChildren()) do
				if string.find(R.Name, "Fruit") then
					R.Handle.CFrame = Y.HumanoidRootPart.CFrame;
				end;
			end;
		end;
	end;
Getmoon = function()
		if World1 then
			return F.FantasySky.MoonTextureId;
		elseif World2 then
			return F.FantasySky.MoonTextureId;
		elseif World3 then
			return F.Sky.MoonTextureId;
		end;
	end;
DropFruits = function()
		for Y, R in next, d.Backpack:GetChildren() do
			if string.find(R.Name, "Fruit") then
				EquipWeapon(R.Name);
				task.wait(.1);
				if d.PlayerGui.Main.Dialogue.Visible == true then
					d.PlayerGui.Main.Dialogue.Visible = false;
				end;
				EquipWeapon(R.Name);
				(d.Character:FindFirstChild(R.Name)).EatRemote:InvokeServer("Drop");
			end;
		end;
		for Y, R in pairs(d.Character:GetChildren()) do
			if string.find(R.Name, "Fruit") then
				EquipWeapon(R.Name);
				task.wait(.1);
				if d.PlayerGui.Main.Dialogue.Visible == true then
					d.PlayerGui.Main.Dialogue.Visible = false;
				end;
				EquipWeapon(R.Name);
				(d.Character:FindFirstChild(R.Name)).EatRemote:InvokeServer("Drop");
			end;
		end;
	end;
GetBP = function(Y)
		return d.Backpack:FindFirstChild(Y) or d.Character:FindFirstChild(Y);
	end;
GetIn = function(Y)
		for R, Q in pairs(Q.Remotes.CommF_:InvokeServer("getInventory")) do
			if type(Q) == "table" then
				if Q.Name == Y or d.Character:FindFirstChild(Y) or d.Backpack:FindFirstChild(Y) then
					return true;
				end;
			end;
		end;
		return false;
	end;
GetM = function(Y)
		for d, R in pairs(Q.Remotes.CommF_:InvokeServer("getInventory")) do
			if type(R) == "table" then
				if R.Type == "Material" then
					if R.Name == Y then
						return R.Count;
					end;
				end;
			end;
		end;
		return 0;
	end;
GetWP = function(Y)
		local inv = Q.Remotes.CommF_:InvokeServer("getInventory");
		if type(inv) ~= "table" then
			return false;
		end;
		for R, Q in pairs(inv) do
			if type(Q) == "table" then
				if Q.Type == "Sword" then
					if Q.Name == Y or d.Character:FindFirstChild(Y) or d.Backpack:FindFirstChild(Y) then
						return true;
					end;
				end;
			end;
		end;
		return false;
	end;
getInfinity_Ability = function(Y, Q)
		if not R then
			return;
		end;
		if Y == "Soru" and Q then
			for Y, R in next, getgc() do
				if d.Character.Soru then
					if typeof(R) == "function" and (getfenv(R)).script == d.Character.Soru then
						for Y, R in next, getupvalues(R) do
							if typeof(R) == "table" then
								repeat
									task.wait(T);
									R.LastUse = 0;
								until not Q or d.Character.Humanoid.Health <= 0;
							end;
						end;
					end;
				end;
			end;
		elseif Y == "Energy" and Q then
			d.Character.Energy.Changed:connect(function()
				if Q then
					d.Character.Energy.Value = D;
				end;
			end);
		elseif Y == "Observation" and Q then
			local Y = d.VisionRadius;
			Y.Value = math.huge;
		end;
	end;
Hop = function()
		local placeId = game.PlaceId;
		local player = game.Players.LocalPlayer;
		local ts = game:GetService("TeleportService");
		local hs = game:GetService("HttpService");
		local CF_API = "https://job.idshowmeat.workers.dev";
		local httpReq = request or (syn and syn.request) or (http and http.request);
		local function cfRequest(url, method, body)
			if httpReq then
				local ok, res = pcall(httpReq, {
					Url = url, Method = method or "GET",
					Headers = { ["Content-Type"] = "application/json" },
					Body = body and hs:JSONEncode(body) or nil
				});
				if ok and res and res.StatusCode == 200 then
					return pcall(function() return hs:JSONDecode(res.Body) end);
				end;
			end;
			return false, nil;
		end;
		local function fetchAndPushJobs()
			local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?limit=100", placeId);
			local ok, raw = pcall(function() return game:HttpGet(url) end);
			if not ok or not raw then return end;
			local ok2, data = pcall(function() return hs:JSONDecode(raw) end);
			if not ok2 or not data or not data.data then return end;
			local jobs = {};
			for _, s in ipairs(data.data) do
				if s.id and s.playing < (s.maxPlayers or 50) then
					table.insert(jobs, s.id);
				end;
			end;
			if #jobs > 0 then
				cfRequest(CF_API .. "/push", "POST", { place = tostring(placeId), jobs = jobs });
			end;
		end;
		local function hopViaAPI()
			local ok, res = cfRequest(CF_API .. "/pop?place=" .. tostring(placeId), "GET");
			if ok and res and res.job then
				pcall(function() ts:TeleportToPlaceInstance(placeId, res.job, player) end);
				return true;
			end;
			return false;
		end;
		if not hopViaAPI() then
			fetchAndPushJobs();
			task.wait(0.5);
			hopViaAPI();
		end;
	end;
local J = Instance.new("Part", workspace);
J.Size = Vector3.new(1, 1, 1);
J.Name = "Rip_Indra";
J.Anchored = true;
J.CanCollide = false;
J.CanTouch = false;
J.Transparency = 1;
local Yz = workspace:FindFirstChild(J.Name);
if Yz and Yz ~= J then
	Yz:Destroy();
end;
task.spawn(function()
	while task.wait() do
		if J and J.Parent == workspace then
			if y then
				(getgenv()).OnFarm = true;
			else
				(getgenv()).OnFarm = false;
			end;
		else
			(getgenv()).OnFarm = false;
		end;
	end;
end);
task.spawn(function()
	local Y = game.Players.LocalPlayer;
	repeat
		task.wait();
	until Y.Character and Y.Character.PrimaryPart;
	J.CFrame = Y.Character.PrimaryPart.CFrame;
	while task.wait() do
		pcall(function()
			if (getgenv()).OnFarm then
				if J and J.Parent == workspace then
					local d = Y.Character and Y.Character.PrimaryPart;
					if d and (d.Position - J.Position).Magnitude <= 200 then
						d.CFrame = J.CFrame;
					else
						J.CFrame = d.CFrame;
					end;
				end;
				local d = Y.Character;
				if d then
					for Y, d in pairs(d:GetChildren()) do
						if d:IsA("BasePart") then
							d.CanCollide = false;
						end;
					end;
				end;
			else
				local d = Y.Character;
				if d then
					for Y, d in pairs(d:GetChildren()) do
						if d:IsA("BasePart") then
							d.CanCollide = true;
						end;
					end;
				end;
			end;
		end);
	end;
end);
-- One owner for character movement: no stale root after respawn and no snap-back.
VoidTravel = VoidTravel or { Tween = nil, Target = nil, Token = 0, Speed = 160 }
local function VoidRoot()
	local character = plr.Character
	return character and character:FindFirstChild("HumanoidRootPart"), character
end
_tp = function(target)
	if typeof(target) ~= "CFrame" then return false, "invalid destination" end
	local root, character = VoidRoot()
	if not root or not character then return false, "waiting for character" end
	if VoidTravel.Tween and VoidTravel.Tween.PlaybackState == Enum.PlaybackState.Playing
		and VoidTravel.Target and (VoidTravel.Target.Position - target.Position).Magnitude <= 16 then
		return true, "travelling"
	end
	VoidTravel.Token = VoidTravel.Token + 1
	local token = VoidTravel.Token
	if VoidTravel.Tween and VoidTravel.Tween.PlaybackState == Enum.PlaybackState.Playing then VoidTravel.Tween:Cancel() end
	local distance = (target.Position - root.Position).Magnitude
	if distance <= 3 then return true, "already there" end
	local speed = math.clamp(tonumber(getgenv().TweenSpeed) or VoidTravel.Speed, 40, 160)
	local params = RaycastParams.new()
	params.IgnoreWater = true
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	local hit = workspace:Raycast(target.Position + Vector3.new(0, 180, 0), Vector3.new(0, -360, 0), params)
	local destination = target
	if hit and math.abs(hit.Position.Y - target.Position.Y) > 30 then
		destination = CFrame.new(target.Position.X, hit.Position.Y + 4, target.Position.Z) * (target - target.Position)
	end
	shouldTween, getgenv().OnFarm = true, false
	local tween = game:GetService("TweenService"):Create(root, TweenInfo.new(math.max(distance / speed, .08), Enum.EasingStyle.Linear), { CFrame = destination })
	VoidTravel.Tween = tween
	VoidTravel.Target = destination
	zeroVelocity(root)
	tween:Play()
	task.spawn(function()
		while tween.PlaybackState == Enum.PlaybackState.Playing and token == VoidTravel.Token do
			if not shouldTween then tween:Cancel(); break end
			zeroVelocity(root)
			task.wait(.1)
		end
		if token == VoidTravel.Token then
			zeroVelocity(root)
			VoidTravel.Tween = nil
			VoidTravel.Target = nil
			getgenv().OnFarm = true
		end
	end)
	return true, "travelling"
end;

TeleportToTarget = function(I)
_tp(I)
end;

notween = function(I)
	return _tp(I)
end;


function BTP(I)
	local e = game.Players.LocalPlayer;
	local K = e.Character.HumanoidRootPart;
	local n = e.Character.Humanoid;
	local d = e.PlayerGui.Main;
	local z = I.Position;
	local H = K.Position;

	repeat
		K.CFrame = I;
		d.Quest.Visible = false;

		if (K.Position - H).Magnitude > 1 then
			H = K.Position;
			K.CFrame = I;
		end;

		task.wait(.5);
	until (I.Position - K.Position).Magnitude <= 2000;
end;

function TeleportConditional(hrp, targetCFrame, threshold)
	if not hrp or not targetCFrame then return end
	
	local dist = (targetCFrame.Position - hrp.Position).Magnitude  
	if dist > threshold then  
		_tp(targetCFrame)  
	end
end;

task.spawn(function()
	while task.wait() do
		pcall(function()
			if _G.SailBoat_Hydra or _G.WardenBoss or _G.AutoFactory or _G.HighestMirage or _G.HCM or _G.PGB or _G.Leviathan1 or _G.UPGDrago or _G.Complete_Trials or _G.TpDrago_Prehis or _G.BuyDrago or _G.AutoFireFlowers or _G.DT_Uzoth or _G.AutoBerry or _G.Prehis_Find or _G.Prehis_Skills or _G.Prehis_DB or _G.Prehis_DE or _G.FarmBlazeEM or _G.Dojoo or _G.CollectPresent or _G.AutoLawKak or _G.TpLab or _G.AutoPhoenixF or _G.AutoFarmChest or _G.AutoHytHallow or _G.LongsWord or _G.BlackSpikey or _G.AutoHolyTorch or _G.TrainDrago or _G.AutoSaber or _G.FarmMastery_Dev or _G.CitizenQuest or _G.AutoEctoplasm or _G.KeysRen or _G.Auto_Rainbow_Haki or _G.obsFarm or _G.AutoBigmom or _G.Doughv2 or _G.AuraBoss or _G.Raiding or _G.Auto_Cavender or _G.TpPly or _G.Bartilo_Quest or _G.Level or _G.FarmEliteHunt or _G.AutoZou or _G.AutoFarm_Bone or (getgenv()).AutoMaterial or _G.CraftVM or _G.FrozenTP or _G.TPDoor or _G.AcientOne or _G.AutoFarmNear or _G.AutoRaidCastle or _G.DarkBladev3 or _G.AutoFarmRaid or _G.Auto_Cake_Prince or _G.Addealer or _G.TPNpc or _G.TwinHook or _G.FindMirage or _G.FarmChestM or _G.Shark or _G.TerrorShark or _G.Piranha or _G.MobCrew or _G.SeaBeast1 or _G.FishBoat or _G.AutoPole or _G.AutoPoleV2 or _G.Auto_SuperHuman or _G.AutoDeathStep or _G.Auto_SharkMan_Karate or _G.Auto_Electric_Claw or _G.AutoDragonTalon or _G.Auto_Def_DarkCoat or _G.Auto_God_Human or _G.Auto_Tushita or _G.AutoMatSoul or _G.AutoKenVTWO or _G.AutoSerpentBow or _G.AutoFMon or _G.Auto_Soul_Guitar or _G.TPGEAR or _G.AutoSaw or _G.AutoTridentW2 or _G.Auto_StartRaid or _G.AutoEvoRace or _G.AutoGetQuestBounty or _G.MarinesCoat or _G.TravelDres or _G.Defeating or _G.DummyMan or _G.Auto_Yama or _G.Auto_SwanGG or _G.SwanCoat or _G.AutoEcBoss or _G.Auto_Mink or _G.Auto_Human or _G.Auto_Skypiea or _G.Auto_Fish or _G.CDK_TS or _G.CDK_YM or _G.CDK or _G.AutoFarmGodChalice or _G.AutoFistDarkness or _G.AutoMiror or _G.Teleport or _G.AutoKilo or _G.AutoGetUsoap or _G.Praying or _G.TryLucky or _G.AutoColShad or _G.AutoUnHaki or _G.Auto_DonAcces or _G.AutoRipIngay or _G.DragoV3 or _G.DragoV1 or _G.SailBoats or NextIs or _G.FarmGodChalice or _G.IceBossRen or senth or senth2 or _G.Lvthan or _G.beasthunter or _G.DangerLV or _G.Relic123 or _G.tweenKitsune or _G.Collect_Ember or _G.AutofindKitIs or _G.snaguine or _G.TwFruits or _G.tweenKitShrine or _G.Tp_LgS or _G.Tp_MasterA or _G.tweenShrine or _G.FarmMastery_G or _G.FarmMastery_S then
				shouldTween = true;
				if not d.Character.HumanoidRootPart:FindFirstChild("BodyClip") then
					local Y = Instance.new("BodyVelocity");
					Y.Name = "BodyClip";
					Y.Parent = d.Character.HumanoidRootPart;
					Y.MaxForce = Vector3.new(100000, 100000, 100000);
					Y.Velocity = Vector3.new(0, 0, 0);
				end;
				if not d.Character:FindFirstChild("highlight") then
					local Y = Instance.new("Highlight");
					Y.Name = "highlight";
					Y.Enabled = true;
					Y.FillColor = Color3.fromRGB(255, 255, 255);
					Y.OutlineColor = Color3.fromRGB(255, 255, 255);
					Y.FillTransparency = .5;
					Y.OutlineTransparency = .2;
					Y.Parent = d.Character;
				end;
				for Y, d in pairs(d.Character:GetDescendants()) do
					if d:IsA("BasePart") then
						d.CanCollide = false;
					end;
				end;
			else
				shouldTween = false;
				if d.Character.HumanoidRootPart:FindFirstChild("BodyClip") then
					(d.Character.HumanoidRootPart:FindFirstChild("BodyClip")):Destroy();
				end;
				if d.Character:FindFirstChild("highlight") then
					(d.Character:FindFirstChild("highlight")):Destroy();
				end;
			end;
		end);
	end;
end);
MaterialMon = function()
		local Y = game.Players.LocalPlayer;
		local d = Y.Character and Y.Character:FindFirstChild("HumanoidRootPart");
		if not d then
			return;
		end;
		shouldRequestEntrance = function(Y, R)
				local r = (d.Position - Y).Magnitude;
				if r >= R then
					Q.Remotes.CommF_:InvokeServer("requestEntrance", Y);
				end;
			end;
		if World1 then
			if SelectMaterial == "Angel Wings" then
				MMon = {
						"Shanda",
						"Royal Squad",
						"Royal Soldier",
						"Wysper",
						"Thunder God",
					};
				MPos = CFrame.new(-4698, 845, -1912);
				SP = "Default";
				local Y = Vector3.new(-4607.82275, 872.54248, -1667.55688);
				shouldRequestEntrance(Y, 10000);
			elseif SelectMaterial == "Leather + Scrap Metal" then
				MMon = { "Brute", "Pirate" };
				MPos = CFrame.new(-1145, 15, 4350);
				SP = "Default";
			elseif SelectMaterial == "Magma Ore" then
				MMon = { "Military Soldier", "Military Spy", "Magma Admiral" };
				MPos = CFrame.new(-5815, 84, 8820);
				SP = "Default";
			elseif SelectMaterial == "Fish Tail" then
				MMon = { "Fishman Warrior", "Fishman Commando", "Fishman Lord" };
				MPos = CFrame.new(61123, 19, 1569);
				SP = "Default";
				local Y = Vector3.new(61163.8515625, 5.34234237, 1819.78417968);
				shouldRequestEntrance(Y, 17000);
			end;
		elseif World2 then
			if SelectMaterial == "Leather + Scrap Metal" then
				MMon = { "Marine Captain" };
				MPos = CFrame.new(-2010.50598144, 73.00115966, -3326.62084960);
				SP = "Default";
			elseif SelectMaterial == "Magma Ore" then
				MMon = { "Magma Ninja", "Lava Pirate" };
				MPos = CFrame.new(-5428, 78, -5959);
				SP = "Default";
			elseif SelectMaterial == "Ectoplasm" then
				MMon = {
						"Ship Deckhand",
						"Ship Engineer",
						"Ship Steward",
						"Ship Officer",
					};
				MPos = CFrame.new(911.35827636, 125.95812988, 33159.5390625);
				SP = "Default";
				local Y = Vector3.new(61163.8515625, 5.34234237, 1819.78417968);
				shouldRequestEntrance(Y, 18000);
			elseif SelectMaterial == "Mystic Droplet" then
				MMon = { "Water Fighter" };
				MPos = CFrame.new(-3385, 239, -10542);
				SP = "Default";
			elseif SelectMaterial == "Radioactive Material" then
				MMon = { "Factory Staff" };
				MPos = CFrame.new(295, 73, -56);
				SP = "Default";
			elseif SelectMaterial == "Vampire Fang" then
				MMon = { "Vampire" };
				MPos = CFrame.new(-6033, 7, -1317);
				SP = "Default";
			end;
		elseif World3 then
			if SelectMaterial == "Scrap Metal" then
				MMon = { "Jungle Pirate", "Forest Pirate" };
				MPos = CFrame.new(-11975.78515625, 331.77340698, -10620.03027343);
				SP = "Default";
			elseif SelectMaterial == "Fish Tail" then
				MMon = { "Fishman Raider", "Fishman Captain" };
				MPos = CFrame.new(-10993, 332, -8940);
				SP = "Default";
			elseif SelectMaterial == "Conjured Cocoa" then
				MMon = { "Chocolate Bar Battler", "Cocoa Warrior" };
				MPos = CFrame.new(620.63446044, 78.93644714, -12581.36914062);
				SP = "Default";
			elseif SelectMaterial == "Dragon Scale" then
				MMon = { "Dragon Crew Archer", "Dragon Crew Warrior" };
				MPos = CFrame.new(6594, 383, 139);
				SP = "Default";
			elseif SelectMaterial == "Gunpowder" then
				MMon = { "Pistol Billionaire" };
				MPos = CFrame.new(-84.85569000, 85.62061309, 6132.00878906);
				SP = "Default";
			elseif SelectMaterial == "Mini Tusk" then
				MMon = { "Mythological Pirate" };
				MPos = CFrame.new(-13545, 470, -6917);
				SP = "Default";
			elseif SelectMaterial == "Demonic Wisp" then
				MMon = { "Demonic Soul" };
				MPos = CFrame.new(-9495.68066406, 453.58624267, 5977.34863281);
				SP = "Default";
			end;
		end;
	end;
function CheckQuest()
	MyLevel = (game:GetService("Players")).LocalPlayer.Data.Level.Value;
	if World1 then
		if MyLevel >= 1 and MyLevel <= 9 then
			Mon = "Bandit";
			LevelQuest = 1;
			NameQuest = "BanditQuest1";
			NameMon = "Bandit";
			CFrameQuest = CFrame.new(1059.37195, 15.4495068, 1550.4231, .939700544, 0, -0.34199836, 0, 1, 0, .341998369, 0, .939700544);
			CFrameMon = CFrame.new(1045.96264648, 27.00250816, 1560.8203125);
		elseif MyLevel >= 10 and MyLevel <= 14 then
			Mon = "Monkey";
			LevelQuest = 1;
			NameQuest = "JungleQuest";
			NameMon = "Monkey";
			CFrameQuest = CFrame.new(-1598.08911, 35.5501175, 153.377838, 0, 0, 1, 0, 1, 0, -1, 0, 0);
			CFrameMon = CFrame.new(-1448.51806640, 67.85301208, 11.46579647);
		elseif MyLevel >= 15 and MyLevel <= 29 then
			Mon = "Gorilla";
			LevelQuest = 2;
			NameQuest = "JungleQuest";
			NameMon = "Gorilla";
			CFrameQuest = CFrame.new(-1598.08911, 35.5501175, 153.377838, 0, 0, 1, 0, 1, 0, -1, 0, 0);
			CFrameMon = CFrame.new(-1129.88366699, 40.46354675, -525.42370605);
		elseif MyLevel >= 30 and MyLevel <= 39 then
			Mon = "Pirate";
			LevelQuest = 1;
			NameQuest = "BuggyQuest1";
			NameMon = "Pirate";
			CFrameQuest = CFrame.new(-1141.07483, 4.10001802, 3831.5498, .965929627, 0, -0.25880479, 0, 1, 0, .258804798, 0, .965929627);
			CFrameMon = CFrame.new(-1103.51342773, 13.75205230, 3896.09106445);
		elseif MyLevel >= 40 and MyLevel <= 59 then
			Mon = "Brute";
			LevelQuest = 2;
			NameQuest = "BuggyQuest1";
			NameMon = "Brute";
			CFrameQuest = CFrame.new(-1141.07483, 4.10001802, 3831.5498, .965929627, 0, -0.25880479, 0, 1, 0, .258804798, 0, .965929627);
			CFrameMon = CFrame.new(-1140.08374023, 14.80988502, 4322.92138671);
		elseif MyLevel >= 60 and MyLevel <= 74 then
			Mon = "Desert Bandit";
			LevelQuest = 1;
			NameQuest = "DesertQuest";
			NameMon = "Desert Bandit";
			CFrameQuest = CFrame.new(894.488647, 5.14000702, 4392.43359, .819155693, 0, -0.57357126, 0, 1, 0, .573571265, 0, .819155693);
			CFrameMon = CFrame.new(924.79980468, 6.44867467, 4481.5859375);
		elseif MyLevel >= 75 and MyLevel <= 89 then
			Mon = "Desert Officer";
			LevelQuest = 2;
			NameQuest = "DesertQuest";
			NameMon = "Desert Officer";
			CFrameQuest = CFrame.new(894.488647, 5.14000702, 4392.43359, .819155693, 0, -0.57357126, 0, 1, 0, .573571265, 0, .819155693);
			CFrameMon = CFrame.new(1608.28222656, 8.61422443, 4371.00732421);
		elseif MyLevel >= 90 and MyLevel <= 99 then
			Mon = "Snow Bandit";
			LevelQuest = 1;
			NameQuest = "SnowQuest";
			NameMon = "Snow Bandit";
			CFrameQuest = CFrame.new(1389.74451, 88.1519318, -1298.90796, -0.34204268, 0, .939684391, 0, 1, 0, -0.93968439, 0, -0.34204268);
			CFrameMon = CFrame.new(1354.34790039, 87.27277374, -1393.94653320);
		elseif MyLevel >= 100 and MyLevel <= 119 then
			Mon = "Snowman";
			LevelQuest = 2;
			NameQuest = "SnowQuest";
			NameMon = "Snowman";
			CFrameQuest = CFrame.new(1389.74451, 88.1519318, -1298.90796, -0.34204268, 0, .939684391, 0, 1, 0, -0.93968439, 0, -0.34204268);
			CFrameMon = CFrame.new(1201.64123535, 144.57958984, -1550.06701660);
		elseif MyLevel >= 120 and MyLevel <= 149 then
			Mon = "Chief Petty Officer";
			LevelQuest = 1;
			NameQuest = "MarineQuest2";
			NameMon = "Chief Petty Officer";
			CFrameQuest = CFrame.new(-5039.58643, 27.3500385, 4324.68018, 0, 0, -1, 0, 1, 0, 1, 0, 0);
			CFrameMon = CFrame.new(-4881.23095703, 22.65204429, 4273.75244140);
		elseif MyLevel >= 150 and MyLevel <= 174 then
			Mon = "Sky Bandit";
			LevelQuest = 1;
			NameQuest = "SkyQuest";
			NameMon = "Sky Bandit";
			CFrameQuest = CFrame.new(-4839.53027, 716.368591, -2619.44165, .866007268, 0, .500031412, 0, 1, 0, -0.50003141, 0, .866007268);
			CFrameMon = CFrame.new(-4953.20703125, 295.74420166, -2899.22900390);
		elseif MyLevel >= 175 and MyLevel <= 189 then
			Mon = "Dark Master";
			LevelQuest = 2;
			NameQuest = "SkyQuest";
			NameMon = "Dark Master";
			CFrameQuest = CFrame.new(-4839.53027, 716.368591, -2619.44165, .866007268, 0, .500031412, 0, 1, 0, -0.50003141, 0, .866007268);
			CFrameMon = CFrame.new(-5259.84472656, 391.39767456, -2229.03540039);
		elseif MyLevel >= 190 and MyLevel <= 209 then
			Mon = "Prisoner";
			LevelQuest = 1;
			NameQuest = "PrisonerQuest";
			NameMon = "Prisoner";
			CFrameQuest = CFrame.new(5308.93115, 1.65517521, 475.120514, -0.08942747, -5.00292918e-09, -0.99599331, 1.60817859e-09, 1, -5.16744869e-09, .995993316, -2.06384709e-09, -0.08942747);
			CFrameMon = CFrame.new(5098.97363281, -0.32040581, 474.23733520);
		elseif MyLevel >= 210 and MyLevel <= 249 then
			Mon = "Dangerous Prisoner";
			LevelQuest = 2;
			NameQuest = "PrisonerQuest";
			NameMon = "Dangerous Prisoner";
			CFrameQuest = CFrame.new(5308.93115, 1.65517521, 475.120514, -0.08942747, -5.00292918e-09, -0.99599331, 1.60817859e-09, 1, -5.16744869e-09, .995993316, -2.06384709e-09, -0.08942747);
			CFrameMon = CFrame.new(5654.56347656, 15.63340187, 866.29919433);
		elseif MyLevel >= 250 and MyLevel <= 274 then
			Mon = "Toga Warrior";
			LevelQuest = 1;
			NameQuest = "ColosseumQuest";
			NameMon = "Toga Warrior";
			CFrameQuest = CFrame.new(-1580.04663, 6.35000277, -2986.47534, -0.51503729, 0, -0.85716772, 0, 1, 0, .857167721, 0, -0.51503729);
			CFrameMon = CFrame.new(-1820.21484375, 51.68385696, -2740.66503906);
		elseif MyLevel >= 275 and MyLevel <= 299 then
			Mon = "Gladiator";
			LevelQuest = 2;
			NameQuest = "ColosseumQuest";
			NameMon = "Gladiator";
			CFrameQuest = CFrame.new(-1580.04663, 6.35000277, -2986.47534, -0.51503729, 0, -0.85716772, 0, 1, 0, .857167721, 0, -0.51503729);
			CFrameMon = CFrame.new(-1292.83813476, 56.38088226, -3339.03149414);
		elseif MyLevel >= 300 and MyLevel <= 324 then
			Mon = "Military Soldier";
			LevelQuest = 1;
			NameQuest = "MagmaQuest";
			NameMon = "Military Soldier";
			CFrameQuest = CFrame.new(-5313.37012, 10.9500084, 8515.29395, -0.49995946, 0, .866048813, 0, 1, 0, -0.86604881, 0, -0.49995946);
			CFrameMon = CFrame.new(-5411.16455078, 11.08155441, 8454.29296875);
		elseif MyLevel >= 325 and MyLevel <= 374 then
			Mon = "Military Spy";
			LevelQuest = 2;
			NameQuest = "MagmaQuest";
			NameMon = "Military Spy";
			CFrameQuest = CFrame.new(-5313.37012, 10.9500084, 8515.29395, -0.49995946, 0, .866048813, 0, 1, 0, -0.86604881, 0, -0.49995946);
			CFrameMon = CFrame.new(-5802.86816406, 86.26241302, 8828.859375);
		elseif MyLevel >= 375 and MyLevel <= 399 then
			Mon = "Fishman Warrior";
			LevelQuest = 1;
			NameQuest = "FishmanQuest";
			NameMon = "Fishman Warrior";
			CFrameQuest = CFrame.new(61122.65234375, 18.49744224, 1569.39978027);
			CFrameMon = CFrame.new(60878.30078125, 18.48283004, 1543.75744628);
			if (getgenv()).AutoFarm and (CFrameQuest.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude > 10000 then
				(game:GetService("ReplicatedStorage")).Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(61163.8515625, 11.6796875, 1819.78417968));
			end;
		elseif MyLevel >= 400 and MyLevel <= 449 then
			Mon = "Fishman Commando";
			LevelQuest = 2;
			NameQuest = "FishmanQuest";
			NameMon = "Fishman Commando";
			CFrameQuest = CFrame.new(61122.65234375, 18.49744224, 1569.39978027);
			CFrameMon = CFrame.new(61922.6328125, 18.48283004, 1493.93432617);
			if (getgenv()).AutoFarm and (CFrameQuest.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude > 10000 then
				(game:GetService("ReplicatedStorage")).Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(61163.8515625, 11.6796875, 1819.78417968));
			end;
		elseif MyLevel >= 450 and MyLevel <= 474 then
			Mon = "God\'s Guard";
			LevelQuest = 1;
			NameQuest = "SkyExp1Quest";
			NameMon = "God\'s Guard";
			CFrameQuest = CFrame.new(-4721.88867, 843.874695, -1949.96643, .996191859, 0, -0.08718843, 0, 1, 0, .0871884301, 0, .996191859);
			CFrameMon = CFrame.new(-4710.04296875, 845.27697753, -1927.30798339);
			if (getgenv()).AutoFarm and (CFrameQuest.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude > 10000 then
				(game:GetService("ReplicatedStorage")).Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(-4607.82275, 872.54248, -1667.55688));
			end;
		elseif MyLevel >= 475 and MyLevel <= 524 then
			Mon = "Shanda";
			LevelQuest = 2;
			NameQuest = "SkyExp1Quest";
			NameMon = "Shanda";
			CFrameQuest = CFrame.new(-7859.09814, 5544.19043, -381.476196, -0.42259299, 0, .906319618, 0, 1, 0, -0.90631961, 0, -0.42259299);
			CFrameMon = CFrame.new(-7678.48974609, 5566.40380859, -497.21560668);
			if (getgenv()).AutoFarm and (CFrameQuest.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude > 10000 then
				(game:GetService("ReplicatedStorage")).Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(-7894.61767578, 5547.14160156, -380.29119873));
			end;
		elseif MyLevel >= 525 and MyLevel <= 549 then
			Mon = "Royal Squad";
			LevelQuest = 1;
			NameQuest = "SkyExp2Quest";
			NameMon = "Royal Squad";
			CFrameQuest = CFrame.new(-7906.81592, 5634.6626, -1411.99194, 0, 0, -1, 0, 1, 0, 1, 0, 0);
			CFrameMon = CFrame.new(-7624.25244140, 5658.13330078, -1467.35424804);
		elseif MyLevel >= 550 and MyLevel <= 624 then
			Mon = "Royal Soldier";
			LevelQuest = 2;
			NameQuest = "SkyExp2Quest";
			NameMon = "Royal Soldier";
			CFrameQuest = CFrame.new(-7906.81592, 5634.6626, -1411.99194, 0, 0, -1, 0, 1, 0, 1, 0, 0);
			CFrameMon = CFrame.new(-7836.75341796, 5645.6640625, -1790.62365722);
		elseif MyLevel >= 625 and MyLevel <= 649 then
			Mon = "Galley Pirate";
			LevelQuest = 1;
			NameQuest = "FountainQuest";
			NameMon = "Galley Pirate";
			CFrameQuest = CFrame.new(5259.81982, 37.3500175, 4050.0293, .087131381, 0, .996196866, 0, 1, 0, -0.99619686, 0, .087131381);
			CFrameMon = CFrame.new(5551.02197265, 78.90135192, 3930.41284179);
		elseif MyLevel >= 650 then
			Mon = "Galley Captain";
			LevelQuest = 2;
			NameQuest = "FountainQuest";
			NameMon = "Galley Captain";
			CFrameQuest = CFrame.new(5259.81982, 37.3500175, 4050.0293, .087131381, 0, .996196866, 0, 1, 0, -0.99619686, 0, .087131381);
			CFrameMon = CFrame.new(5441.95166015, 42.50205993, 4950.09375);
		end;
	elseif World2 then
		if MyLevel >= 700 and MyLevel <= 724 then
			Mon = "Raider";
			LevelQuest = 1;
			NameQuest = "Area1Quest";
			NameMon = "Raider";
			CFrameQuest = CFrame.new(-429.543518, 71.7699966, 1836.18188, -0.22495985, 0, -0.97436809, 0, 1, 0, .974368095, 0, -0.22495985);
			CFrameMon = CFrame.new(-728.32672119, 52.77931976, 2345.77050781);
		elseif MyLevel >= 725 and MyLevel <= 774 then
			Mon = "Mercenary";
			LevelQuest = 2;
			NameQuest = "Area1Quest";
			NameMon = "Mercenary";
			CFrameQuest = CFrame.new(-429.543518, 71.7699966, 1836.18188, -0.22495985, 0, -0.97436809, 0, 1, 0, .974368095, 0, -0.22495985);
			CFrameMon = CFrame.new(-1004.32440185, 80.15886688, 1424.61938476);
		elseif MyLevel >= 775 and MyLevel <= 799 then
			Mon = "Swan Pirate";
			LevelQuest = 1;
			NameQuest = "Area2Quest";
			NameMon = "Swan Pirate";
			CFrameQuest = CFrame.new(638.43811, 71.769989, 918.282898, .139203906, 0, .99026376, 0, 1, 0, -0.99026376, 0, .139203906);
			CFrameMon = CFrame.new(1068.66430664, 137.61428833, 1322.10607910);
		elseif MyLevel >= 800 and MyLevel <= 874 then
			Mon = "Factory Staff";
			NameQuest = "Area2Quest";
			LevelQuest = 2;
			NameMon = "Factory Staff";
			CFrameQuest = CFrame.new(632.698608, 73.1055908, 918.666321, -0.03197223, 8.96074881e-10, -0.99948877, 1.36326533e-10, 1, 8.92172336e-10, .999488771, -1.07732087e-10, -0.03197223);
			CFrameMon = CFrame.new(73.07867431, 81.86344146, -27.47067260);
		elseif MyLevel >= 875 and MyLevel <= 899 then
			Mon = "Marine Lieutenant";
			LevelQuest = 1;
			NameQuest = "MarineQuest3";
			NameMon = "Marine Lieutenant";
			CFrameQuest = CFrame.new(-2440.79639, 71.7140732, -3216.06812, .866007268, 0, .500031412, 0, 1, 0, -0.50003141, 0, .866007268);
			CFrameMon = CFrame.new(-2821.37231445, 75.89727783, -3070.08911132);
		elseif MyLevel >= 900 and MyLevel <= 949 then
			Mon = "Marine Captain";
			LevelQuest = 2;
			NameQuest = "MarineQuest3";
			NameMon = "Marine Captain";
			CFrameQuest = CFrame.new(-2440.79639, 71.7140732, -3216.06812, .866007268, 0, .500031412, 0, 1, 0, -0.50003141, 0, .866007268);
			CFrameMon = CFrame.new(-1861.23107910, 80.17658233, -3254.69750976);
		elseif MyLevel >= 950 and MyLevel <= 974 then
			Mon = "Zombie";
			LevelQuest = 1;
			NameQuest = "ZombieQuest";
			NameMon = "Zombie";
			CFrameQuest = CFrame.new(-5497.06152, 47.5923004, -795.237061, -0.29242146, 0, -0.95628953, 0, 1, 0, .95628953, 0, -0.29242146);
			CFrameMon = CFrame.new(-5657.77685546, 78.96973419, -928.68701171);
		elseif MyLevel >= 975 and MyLevel <= 999 then
			Mon = "Vampire";
			LevelQuest = 2;
			NameQuest = "ZombieQuest";
			NameMon = "Vampire";
			CFrameQuest = CFrame.new(-5497.06152, 47.5923004, -795.237061, -0.29242146, 0, -0.95628953, 0, 1, 0, .95628953, 0, -0.29242146);
			CFrameMon = CFrame.new(-6037.66796875, 32.18463897, -1340.65979003);
		elseif MyLevel >= 1000 and MyLevel <= 1049 then
			Mon = "Snow Trooper";
			LevelQuest = 1;
			NameQuest = "SnowMountainQuest";
			NameMon = "Snow Trooper";
			CFrameQuest = CFrame.new(609.858826, 400.119904, -5372.25928, -0.37460410, 0, .92718488, 0, 1, 0, -0.92718488, 0, -0.37460410);
			CFrameMon = CFrame.new(549.14733886, 427.38705444, -5563.69873046);
		elseif MyLevel >= 1050 and MyLevel <= 1099 then
			Mon = "Winter Warrior";
			LevelQuest = 2;
			NameQuest = "SnowMountainQuest";
			NameMon = "Winter Warrior";
			CFrameQuest = CFrame.new(609.858826, 400.119904, -5372.25928, -0.37460410, 0, .92718488, 0, 1, 0, -0.92718488, 0, -0.37460410);
			CFrameMon = CFrame.new(1142.74511718, 475.63980102, -5199.41650390);
		elseif MyLevel >= 1100 and MyLevel <= 1124 then
			Mon = "Lab Subordinate";
			LevelQuest = 1;
			NameQuest = "IceSideQuest";
			NameMon = "Lab Subordinate";
			CFrameQuest = CFrame.new(-6064.06885, 15.2422857, -4902.97852, .453972578, 0, -0.89101564, 0, 1, 0, .891015649, 0, .453972578);
			CFrameMon = CFrame.new(-5707.47167968, 15.95170974, -4513.39208984);
		elseif MyLevel >= 1125 and MyLevel <= 1174 then
			Mon = "Horned Warrior";
			LevelQuest = 2;
			NameQuest = "IceSideQuest";
			NameMon = "Horned Warrior";
			CFrameQuest = CFrame.new(-6064.06885, 15.2422857, -4902.97852, .453972578, 0, -0.89101564, 0, 1, 0, .891015649, 0, .453972578);
			CFrameMon = CFrame.new(-6341.36669921, 15.95177078, -5723.16210937);
		elseif MyLevel >= 1175 and MyLevel <= 1199 then
			Mon = "Magma Ninja";
			LevelQuest = 1;
			NameQuest = "FireSideQuest";
			NameMon = "Magma Ninja";
			CFrameQuest = CFrame.new(-5428.03174, 15.0622921, -5299.43457, -0.88295221, 0, .469463557, 0, 1, 0, -0.46946355, 0, -0.88295221);
			CFrameMon = CFrame.new(-5449.67285156, 76.65874481, -5808.20068359);
		elseif MyLevel >= 1200 and MyLevel <= 1249 then
			Mon = "Lava Pirate";
			LevelQuest = 2;
			NameQuest = "FireSideQuest";
			NameMon = "Lava Pirate";
			CFrameQuest = CFrame.new(-5428.03174, 15.0622921, -5299.43457, -0.88295221, 0, .469463557, 0, 1, 0, -0.46946355, 0, -0.88295221);
			CFrameMon = CFrame.new(-5213.33154296, 49.73788070, -4701.45117187);
		elseif MyLevel >= 1250 and MyLevel <= 1274 then
			Mon = "Ship Deckhand";
			LevelQuest = 1;
			NameQuest = "ShipQuest1";
			NameMon = "Ship Deckhand";
			CFrameQuest = CFrame.new(1037.80127, 125.092171, 32911.6016);
			CFrameMon = CFrame.new(1212.01110839, 150.79205322, 33059.24609375);
			if (getgenv()).AutoFarm and (CFrameQuest.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude > 10000 then
				(game:GetService("ReplicatedStorage")).Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(923.21252441, 126.97600555, 32852.83203125));
			end;
		elseif MyLevel >= 1275 and MyLevel <= 1299 then
			Mon = "Ship Engineer";
			LevelQuest = 2;
			NameQuest = "ShipQuest1";
			NameMon = "Ship Engineer";
			CFrameQuest = CFrame.new(1037.80127, 125.092171, 32911.6016);
			CFrameMon = CFrame.new(919.47863769, 43.54401397, 32779.96875);
			if (getgenv()).AutoFarm and (CFrameQuest.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude > 10000 then
				(game:GetService("ReplicatedStorage")).Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(923.21252441, 126.97600555, 32852.83203125));
			end;
		elseif MyLevel >= 1300 and MyLevel <= 1324 then
			Mon = "Ship Steward";
			LevelQuest = 1;
			NameQuest = "ShipQuest2";
			NameMon = "Ship Steward";
			CFrameQuest = CFrame.new(968.80957, 125.092171, 33244.125);
			CFrameMon = CFrame.new(919.43853759, 129.55599975, 33436.03515625);
			if (getgenv()).AutoFarm and (CFrameQuest.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude > 10000 then
				(game:GetService("ReplicatedStorage")).Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(923.21252441, 126.97600555, 32852.83203125));
			end;
		elseif MyLevel >= 1325 and MyLevel <= 1349 then
			Mon = "Ship Officer";
			LevelQuest = 2;
			NameQuest = "ShipQuest2";
			NameMon = "Ship Officer";
			CFrameQuest = CFrame.new(968.80957, 125.092171, 33244.125);
			CFrameMon = CFrame.new(1036.01794433, 181.43904113, 33315.7265625);
			if (getgenv()).AutoFarm and (CFrameQuest.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude > 10000 then
				(game:GetService("ReplicatedStorage")).Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(923.21252441, 126.97600555, 32852.83203125));
			end;
		elseif MyLevel >= 1350 and MyLevel <= 1374 then
			Mon = "Arctic Warrior";
			LevelQuest = 1;
			NameQuest = "FrostQuest";
			NameMon = "Arctic Warrior";
			CFrameQuest = CFrame.new(5667.6582, 26.7997818, -6486.08984, -0.93358790, 0, -0.35834950, 0, 1, 0, .358349502, 0, -0.93358790);
			CFrameMon = CFrame.new(5966.24609375, 62.97002029, -6179.3828125);
			if (getgenv()).AutoFarm and (CFrameQuest.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude > 10000 then
				(game:GetService("ReplicatedStorage")).Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(-6508.55810546, 5000.03499603, -132.83953857));
			end;
		elseif MyLevel >= 1375 and MyLevel <= 1424 then
			Mon = "Snow Lurker";
			LevelQuest = 2;
			NameQuest = "FrostQuest";
			NameMon = "Snow Lurker";
			CFrameQuest = CFrame.new(5667.6582, 26.7997818, -6486.08984, -0.93358790, 0, -0.35834950, 0, 1, 0, .358349502, 0, -0.93358790);
			CFrameMon = CFrame.new(5407.07373046, 69.19437408, -6880.88037109);
		elseif MyLevel >= 1425 and MyLevel <= 1449 then
			Mon = "Sea Soldier";
			LevelQuest = 1;
			NameQuest = "ForgottenQuest";
			NameMon = "Sea Soldier";
			CFrameQuest = CFrame.new(-3054.44458, 235.544281, -10142.8193, .990270376, 0, -0.13915664, 0, 1, 0, .13915664, 0, .990270376);
			CFrameMon = CFrame.new(-3028.22363281, 64.67451477, -9775.42675781);
		elseif MyLevel >= 1450 then
			Mon = "Water Fighter";
			LevelQuest = 2;
			NameQuest = "ForgottenQuest";
			NameMon = "Water Fighter";
			CFrameQuest = CFrame.new(-3054, 240, -10146);
			CFrameMon = CFrame.new(-3291, 252, -10501);
		end;
	elseif World3 then
		if MyLevel >= 1500 and MyLevel <= 1524 then
			Mon = "Pirate Millionaire";
			LevelQuest = 1;
			NameQuest = "PiratePortQuest";
			NameMon = "Pirate Millionaire";
			CFrameQuest = CFrame.new(-290.074677, 42.9034653, 5581.58984, .965929627, 0, -0.25880479, 0, 1, 0, .258804798, 0, .965929627);
			CFrameMon = CFrame.new(-245.99638366, 47.30615234, 5584.10058593);
		elseif MyLevel >= 1525 and MyLevel <= 1574 then
			Mon = "Pistol Billionaire";
			LevelQuest = 2;
			NameQuest = "PiratePortQuest";
			NameMon = "Pistol Billionaire";
			CFrameQuest = CFrame.new(-290.074677, 42.9034653, 5581.58984, .965929627, 0, -0.25880479, 0, 1, 0, .258804798, 0, .965929627);
			CFrameMon = CFrame.new(-187.33015441, 86.23987579, 6013.51367187);
		elseif MyLevel >= 1575 and MyLevel <= 1599 then
			Mon = "Dragon Crew Warrior";
			LevelQuest = 1;
			NameQuest = "DragonCrewQuest";
			NameMon = "Dragon Crew Warrior";
			CFrameQuest = CFrame.new(6738.96142578, 127.81645965, -713.51147460);
			CFrameMon = CFrame.new(6920.71435546, 56.15597152, -942.50445556);
		elseif MyLevel >= 1600 and MyLevel <= 1624 then
			Mon = "Dragon Crew Archer";
			NameQuest = "DragonCrewQuest";
			LevelQuest = 2;
			NameMon = "Dragon Crew Archer";
			CFrameQuest = CFrame.new(6738.96142578, 127.81645965, -713.51147460);
			CFrameMon = CFrame.new(6817.91259765, 484.80444335, 513.41412353);
		elseif MyLevel >= 1625 and MyLevel <= 1649 then
			Mon = "Hydra Enforcer";
			NameQuest = "VenomCrewQuest";
			LevelQuest = 1;
			NameMon = "Hydra Enforcer";
			CFrameQuest = CFrame.new(5213.87402343, 1004.50427246, 758.69445800);
			CFrameMon = CFrame.new(4584.69287109, 1002.64355468, 705.79589843);
		elseif MyLevel >= 1650 and MyLevel <= 1699 then
			Mon = "Venomous Assailant";
			NameQuest = "VenomCrewQuest";
			LevelQuest = 2;
			NameMon = "Venomous Assailant";
			CFrameQuest = CFrame.new(5213.87402343, 1004.50427246, 758.69445800);
			CFrameMon = CFrame.new(4638.78564453, 1078.94091796, 881.80023193);
		elseif MyLevel >= 1700 and MyLevel <= 1724 then
			Mon = "Marine Commodore";
			LevelQuest = 1;
			NameQuest = "MarineTreeIsland";
			NameMon = "Marine Commodore";
			CFrameQuest = CFrame.new(2180.54126, 27.8156815, -6741.5498, -0.96592974, 0, .258804798, 0, 1, 0, -0.25880479, 0, -0.96592974);
			CFrameMon = CFrame.new(2286.0078125, 73.13391876, -7159.80908203);
		elseif MyLevel >= 1725 and MyLevel <= 1774 then
			Mon = "Marine Rear Admiral";
			NameMon = "Marine Rear Admiral";
			NameQuest = "MarineTreeIsland";
			LevelQuest = 2;
			CFrameQuest = CFrame.new(2179.98828125, 28.73123931, -6740.05517578);
			CFrameMon = CFrame.new(3656.77368164, 160.52406311, -7001.59863281);
		elseif MyLevel >= 1775 and MyLevel <= 1799 then
			Mon = "Fishman Raider";
			LevelQuest = 1;
			NameQuest = "DeepForestIsland3";
			NameMon = "Fishman Raider";
			CFrameQuest = CFrame.new(-10581.6563, 330.872955, -8761.18652, -0.88295221, 0, .469463557, 0, 1, 0, -0.46946355, 0, -0.88295221);
			CFrameMon = CFrame.new(-10407.52636718, 331.76263427, -8368.51660156);
		elseif MyLevel >= 1800 and MyLevel <= 1824 then
			Mon = "Fishman Captain";
			LevelQuest = 2;
			NameQuest = "DeepForestIsland3";
			NameMon = "Fishman Captain";
			CFrameQuest = CFrame.new(-10581.6563, 330.872955, -8761.18652, -0.88295221, 0, .469463557, 0, 1, 0, -0.46946355, 0, -0.88295221);
			CFrameMon = CFrame.new(-10994.70117187, 352.38140869, -9002.11035156);
		elseif MyLevel >= 1825 and MyLevel <= 1849 then
			Mon = "Forest Pirate";
			LevelQuest = 1;
			NameQuest = "DeepForestIsland";
			NameMon = "Forest Pirate";
			CFrameQuest = CFrame.new(-13234.04, 331.488495, -7625.40137, .707134247, 0, -0.70707929, 0, 1, 0, .707079291, 0, .707134247);
			CFrameMon = CFrame.new(-13274.47851562, 332.37814331, -7769.58056640);
		elseif MyLevel >= 1850 and MyLevel <= 1899 then
			Mon = "Mythological Pirate";
			LevelQuest = 2;
			NameQuest = "DeepForestIsland";
			NameMon = "Mythological Pirate";
			CFrameQuest = CFrame.new(-13234.04, 331.488495, -7625.40137, .707134247, 0, -0.70707929, 0, 1, 0, .707079291, 0, .707134247);
			CFrameMon = CFrame.new(-13680.60742187, 501.08154296, -6991.18945312);
		elseif MyLevel >= 1900 and MyLevel <= 1924 then
			Mon = "Jungle Pirate";
			LevelQuest = 1;
			NameQuest = "DeepForestIsland2";
			NameMon = "Jungle Pirate";
			CFrameQuest = CFrame.new(-12680.3818, 389.971039, -9902.01953, -0.08713150, 0, .996196866, 0, 1, 0, -0.99619686, 0, -0.08713150);
			CFrameMon = CFrame.new(-12256.16015625, 331.73828125, -10485.83691406);
		elseif MyLevel >= 1925 and MyLevel <= 1974 then
			Mon = "Musketeer Pirate";
			LevelQuest = 2;
			NameQuest = "DeepForestIsland2";
			NameMon = "Musketeer Pirate";
			CFrameQuest = CFrame.new(-12680.3818, 389.971039, -9902.01953, -0.08713150, 0, .996196866, 0, 1, 0, -0.99619686, 0, -0.08713150);
			CFrameMon = CFrame.new(-13457.90429687, 391.54565429, -9859.17773437);
		elseif MyLevel >= 1975 and MyLevel <= 1999 then
			Mon = "Reborn Skeleton";
			LevelQuest = 1;
			NameQuest = "HauntedQuest1";
			NameMon = "Reborn Skeleton";
			CFrameQuest = CFrame.new(-9479.2168, 141.215088, 5566.09277, 0, 0, 1, 0, 1, 0, -1, 0, 0);
			CFrameMon = CFrame.new(-8763.72363281, 165.72299194, 6159.86181640);
		elseif MyLevel >= 2000 and MyLevel <= 2024 then
			Mon = "Living Zombie";
			LevelQuest = 2;
			NameQuest = "HauntedQuest1";
			NameMon = "Living Zombie";
			CFrameQuest = CFrame.new(-9479.2168, 141.215088, 5566.09277, 0, 0, 1, 0, 1, 0, -1, 0, 0);
			CFrameMon = CFrame.new(-10144.13183593, 138.62667846, 5838.08886718);
		elseif MyLevel >= 2025 and MyLevel <= 2049 then
			Mon = "Demonic Soul";
			LevelQuest = 1;
			NameQuest = "HauntedQuest2";
			NameMon = "Demonic Soul";
			CFrameQuest = CFrame.new(-9516.99316, 172.017181, 6078.46533, 0, 0, -1, 0, 1, 0, 1, 0, 0);
			CFrameMon = CFrame.new(-9505.87207031, 172.10482788, 6158.99316406);
		elseif MyLevel >= 2050 and MyLevel <= 2074 then
			Mon = "Posessed Mummy";
			LevelQuest = 2;
			NameQuest = "HauntedQuest2";
			NameMon = "Posessed Mummy";
			CFrameQuest = CFrame.new(-9516.99316, 172.017181, 6078.46533, 0, 0, -1, 0, 1, 0, 1, 0, 0);
			CFrameMon = CFrame.new(-9582.02246093, 6.25152730, 6205.47851562);
		elseif MyLevel >= 2075 and MyLevel <= 2099 then
			Mon = "Peanut Scout";
			LevelQuest = 1;
			NameQuest = "NutsIslandQuest";
			NameMon = "Peanut Scout";
			CFrameQuest = CFrame.new(-2104.39086914, 38.10416793, -10194.21875, 0, 0, -1, 0, 1, 0, 1, 0, 0);
			CFrameMon = CFrame.new(-2143.24194335, 47.72198486, -10029.99511718);
		elseif MyLevel >= 2100 and MyLevel <= 2124 then
			Mon = "Peanut President";
			LevelQuest = 2;
			NameQuest = "NutsIslandQuest";
			NameMon = "Peanut President";
			CFrameQuest = CFrame.new(-2104.39086914, 38.10416793, -10194.21875, 0, 0, -1, 0, 1, 0, 1, 0, 0);
			CFrameMon = CFrame.new(-1859.35400390, 38.10316848, -10422.4296875);
		elseif MyLevel >= 2125 and MyLevel <= 2149 then
			Mon = "Ice Cream Chef";
			LevelQuest = 1;
			NameQuest = "IceCreamIslandQuest";
			NameMon = "Ice Cream Chef";
			CFrameQuest = CFrame.new(-820.64825439, 65.81952667, -10965.79589843, 0, 0, -1, 0, 1, 0, 1, 0, 0);
			CFrameMon = CFrame.new(-872.24658203, 65.81957244, -10919.95703125);
		elseif MyLevel >= 2150 and MyLevel <= 2199 then
			Mon = "Ice Cream Commander";
			LevelQuest = 2;
			NameQuest = "IceCreamIslandQuest";
			NameMon = "Ice Cream Commander";
			CFrameQuest = CFrame.new(-820.64825439, 65.81952667, -10965.79589843, 0, 0, -1, 0, 1, 0, 1, 0, 0);
			CFrameMon = CFrame.new(-558.06103515, 112.04895782, -11290.77441406);
		elseif MyLevel >= 2200 and MyLevel <= 2224 then
			Mon = "Cookie Crafter";
			LevelQuest = 1;
			NameQuest = "CakeQuest1";
			NameMon = "Cookie Crafter";
			CFrameQuest = CFrame.new(-2021.32007, 37.7982254, -12028.7295, .957576931, -8.80302053e-08, .288177818, 6.9301187e-08, 1, 7.51931211e-08, -0.28817781, -5.2032135e-08, .957576931);
			CFrameMon = CFrame.new(-2374.13671875, 37.79826354, -12125.30859375);
		elseif MyLevel >= 2225 and MyLevel <= 2249 then
			Mon = "Cake Guard";
			LevelQuest = 2;
			NameQuest = "CakeQuest1";
			NameMon = "Cake Guard";
			CFrameQuest = CFrame.new(-2021.32007, 37.7982254, -12028.7295, .957576931, -8.80302053e-08, .288177818, 6.9301187e-08, 1, 7.51931211e-08, -0.28817781, -5.2032135e-08, .957576931);
			CFrameMon = CFrame.new(-1598.30700683, 43.77319717, -12244.58105468);
		elseif MyLevel >= 2250 and MyLevel <= 2274 then
			Mon = "Baking Staff";
			LevelQuest = 1;
			NameQuest = "CakeQuest2";
			NameMon = "Baking Staff";
			CFrameQuest = CFrame.new(-1927.91602, 37.7981339, -12842.5391, -0.96804446, 4.22142143e-08, .250778586, 4.74911062e-08, 1, 1.49904711e-08, -0.25077858, 2.64211941e-08, -0.96804446);
			CFrameMon = CFrame.new(-1887.80993652, 77.61850738, -12998.35058593);
		elseif MyLevel >= 2275 and MyLevel <= 2299 then
			Mon = "Head Baker";
			LevelQuest = 2;
			NameQuest = "CakeQuest2";
			NameMon = "Head Baker";
			CFrameQuest = CFrame.new(-1927.91602, 37.7981339, -12842.5391, -0.96804446, 4.22142143e-08, .250778586, 4.74911062e-08, 1, 1.49904711e-08, -0.25077858, 2.64211941e-08, -0.96804446);
			CFrameMon = CFrame.new(-2216.18823242, 82.88452148, -12869.29394531);
		elseif MyLevel >= 2300 and MyLevel <= 2324 then
			Mon = "Cocoa Warrior";
			LevelQuest = 1;
			NameQuest = "ChocQuest1";
			NameMon = "Cocoa Warrior";
			CFrameQuest = CFrame.new(233.22836303, 29.87600135, -12201.23339843);
			CFrameMon = CFrame.new(-21.55328369, 80.57499694, -12352.38769531);
		elseif MyLevel >= 2325 and MyLevel <= 2349 then
			Mon = "Chocolate Bar Battler";
			LevelQuest = 2;
			NameQuest = "ChocQuest1";
			NameMon = "Chocolate Bar Battler";
			CFrameQuest = CFrame.new(233.22836303, 29.87600135, -12201.23339843);
			CFrameMon = CFrame.new(582.59057617, 77.18809509, -12463.16210937);
		elseif MyLevel >= 2350 and MyLevel <= 2374 then
			Mon = "Sweet Thief";
			LevelQuest = 1;
			NameQuest = "ChocQuest2";
			NameMon = "Sweet Thief";
			CFrameQuest = CFrame.new(150.50663757, 30.69369316, -12774.50292968);
			CFrameMon = CFrame.new(165.18847656, 76.05885314, -12600.83691406);
		elseif MyLevel >= 2375 and MyLevel <= 2399 then
			Mon = "Candy Rebel";
			LevelQuest = 2;
			NameQuest = "ChocQuest2";
			NameMon = "Candy Rebel";
			CFrameQuest = CFrame.new(150.50663757, 30.69369316, -12774.50292968);
			CFrameMon = CFrame.new(134.86563110, 77.24768066, -12876.54785156);
		elseif MyLevel >= 2400 and MyLevel <= 2424 then
			Mon = "Candy Pirate";
			LevelQuest = 1;
			NameQuest = "CandyQuest1";
			NameMon = "Candy Pirate";
			CFrameQuest = CFrame.new(-1150.04003906, 20.37893486, -14446.33496093);
			CFrameMon = CFrame.new(-1310.50036621, 26.01652336, -14562.40429687);
		elseif MyLevel >= 2425 and MyLevel <= 2449 then
			Mon = "Snow Demon";
			LevelQuest = 2;
			NameQuest = "CandyQuest1";
			NameMon = "Snow Demon";
			CFrameQuest = CFrame.new(-1150.04003906, 20.37893486, -14446.33496093);
			CFrameMon = CFrame.new(-880.20062255, 71.24776458, -14538.609375);
		elseif MyLevel >= 2450 and MyLevel <= 2474 then
			Mon = "Isle Outlaw";
			LevelQuest = 1;
			NameQuest = "TikiQuest1";
			NameMon = "Isle Outlaw";
			CFrameQuest = CFrame.new(-16547.74804687, 61.13533401, -173.41360473);
			CFrameMon = CFrame.new(-16442.81445312, 116.13899993, -264.46377563);
		elseif MyLevel >= 2475 and MyLevel <= 2524 then
			Mon = "Island Boy";
			LevelQuest = 2;
			NameQuest = "TikiQuest1";
			NameMon = "Island Boy";
			CFrameQuest = CFrame.new(-16547.74804687, 61.13533401, -173.41360473);
			CFrameMon = CFrame.new(-16901.26171875, 84.06756591, -192.88906860);
		elseif MyLevel >= 2525 and MyLevel <= 2549 then
			Mon = "Isle Champion";
			LevelQuest = 2;
			NameQuest = "TikiQuest2";
			NameMon = "Isle Champion";
			CFrameQuest = CFrame.new(-16539.078125, 55.68632888, 1051.57385253);
			CFrameMon = CFrame.new(-16641.6796875, 235.78254699, 1031.28295898);
		elseif MyLevel >= 2550 and MyLevel <= 2574 then
			Mon = "Serpent Hunter";
			LevelQuest = 1;
			NameQuest = "TikiQuest3";
			NameMon = "Serpent Hunter";
			CFrameQuest = CFrame.new(-16665.1914, 104.596405, 1579.69434, .951068401, 0, -0.30898046, 0, 1, 0, .308980465, 0, .951068401);
			CFrameMon = CFrame.new(-16521.0625, 106.09285, 1488.78467, .469467044, 0, .882950008, 0, 1, 0, -0.88295000, 0, .469467044);
		elseif MyLevel >= 2575 and MyLevel <= 2599 then
			Mon = "Skull Slayer";
			LevelQuest = 2;
			NameQuest = "TikiQuest3";
			NameMon = "Skull Slayer";
			CFrameQuest = CFrame.new(-16665.1914, 104.596405, 1579.69434, .951068401, 0, -0.30898046, 0, 1, 0, .308980465, 0, .951068401);
			CFrameMon = CFrame.new(-16855.043, 122.457253, 1478.15308, -0.99939227, 0, -0.03486879, 0, 1, 0, .0348687991, 0, -0.99939227);
		elseif MyLevel >= 2600 and MyLevel <= 2624 then
			CFrameQuest = CFrame.new(10780.10742187, -2087.72143554, 9261.86523437);
			if ((getgenv()).AutoFarm or _G.Level) and (CFrameQuest.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude > 10000 then
				_tp(CFrame.new(-16269.7041, 25.2288494, 1373.65955, 0.99739098, 1.47309942e-09, -0.07218909, -4.00651912e-09, 0.99999994, -2.51183763e-09, 0.07218908, 5.75363091e-10, 0.99739092));
				task.wait(2);
				Q.Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(-16269.7041, 25.2288494, 1373.65955));
				task.wait(1);
				local args = {"TravelToSubmergedIsland"};
				game:GetService("ReplicatedStorage").Modules.Net:FindFirstChild("RF/SubmarineWorkerSpeak"):InvokeServer(unpack(args));
				return;
			end;
			Mon = "Reef Bandit";
			LevelQuest = 1;
			NameQuest = "SubmergedQuest1";
			NameMon = "Reef Bandit";
			CFrameMon = CFrame.new(10943.0811, -2083.03516, 9177.33691, -0.99871325, -0.04612046, .021090759, -0.04515713, .998007238, .0440727882, -0.02308138, .0430636741, -0.99880564);
		elseif MyLevel >= 2625 and MyLevel <= 2649 then
			CFrameQuest = CFrame.new(10780.10742187, -2087.72143554, 9261.86523437);
			if ((getgenv()).AutoFarm or _G.Level) and (CFrameQuest.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude > 10000 then
				_tp(CFrame.new(-16269.7041, 25.2288494, 1373.65955, 0.99739098, 1.47309942e-09, -0.07218909, -4.00651912e-09, 0.99999994, -2.51183763e-09, 0.07218908, 5.75363091e-10, 0.99739092));
				task.wait(2);
				Q.Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(-16269.7041, 25.2288494, 1373.65955));
				task.wait(1);
				local args = {"TravelToSubmergedIsland"};
				game:GetService("ReplicatedStorage").Modules.Net:FindFirstChild("RF/SubmarineWorkerSpeak"):InvokeServer(unpack(args));
				return;
			end;
			Mon = "Coral Pirate";
			LevelQuest = 2;
			NameQuest = "SubmergedQuest1";
			NameMon = "Coral Pirate";
			CFrameMon = CFrame.new(10713.4473, -2093.04517, 9307.14844, .325602472, 7.02769976e-05, .945506752, -7.02769976e-05, 1, -5.01261711e-05, -0.94550675, -5.01261711e-05, .325602472);
		elseif MyLevel >= 2650 and MyLevel <= 2674 then
			CFrameQuest = CFrame.new(10883.58789062, -2086.19702148, 10032.19628906);
			if ((getgenv()).AutoFarm or _G.Level) and (CFrameQuest.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude > 10000 then
				_tp(CFrame.new(-16269.7041, 25.2288494, 1373.65955, 0.99739098, 1.47309942e-09, -0.07218909, -4.00651912e-09, 0.99999994, -2.51183763e-09, 0.07218908, 5.75363091e-10, 0.99739092));
				task.wait(2);
				Q.Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(-16269.7041, 25.2288494, 1373.65955));
				task.wait(1);
				local args = {"TravelToSubmergedIsland"};
				game:GetService("ReplicatedStorage").Modules.Net:FindFirstChild("RF/SubmarineWorkerSpeak"):InvokeServer(unpack(args));
				return;
			end;
			Mon = "Sea Chanter";
			LevelQuest = 1;
			NameQuest = "SubmergedQuest2";
			NameMon = "Sea Chanter";
			CFrameMon = CFrame.new(10647.60644531, -2077.62573242, 10079.96289062);
		elseif MyLevel >= 2675 and MyLevel <= 2699 then
			CFrameQuest = CFrame.new(9635.87011718, -1992.44812011, 9614.39355468);
			if ((getgenv()).AutoFarm or _G.Level) and (CFrameQuest.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude > 10000 then
				_tp(CFrame.new(-16269.7041, 25.2288494, 1373.65955, 0.99739098, 1.47309942e-09, -0.07218909, -4.00651912e-09, 0.99999994, -2.51183763e-09, 0.07218908, 5.75363091e-10, 0.99739092));
				task.wait(2);
				Q.Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(-16269.7041, 25.2288494, 1373.65955));
				task.wait(1);
				local args = {"TravelToSubmergedIsland"};
				game:GetService("ReplicatedStorage").Modules.Net:FindFirstChild("RF/SubmarineWorkerSpeak"):InvokeServer(unpack(args));
				return;
			end;
			Mon = "High Disciple";
			LevelQuest = 1;
			NameQuest = "SubmergedQuest3";
			NameMon = "High Disciple";
			CFrameMon = CFrame.new(9843.578125, -1993.45593261, 9696.48046875);
		elseif MyLevel >= 2700 then
			CFrameQuest = CFrame.new(9635.87011718, -1992.44812011, 9614.39355468);
			if ((getgenv()).AutoFarm or _G.Level) and (CFrameQuest.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude > 10000 then
				_tp(CFrame.new(-16269.7041, 25.2288494, 1373.65955, 0.99739098, 1.47309942e-09, -0.07218909, -4.00651912e-09, 0.99999994, -2.51183763e-09, 0.07218908, 5.75363091e-10, 0.99739092));
				task.wait(2);
				Q.Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(-16269.7041, 25.2288494, 1373.65955));
				task.wait(1);
				local args = {"TravelToSubmergedIsland"};
				game:GetService("ReplicatedStorage").Modules.Net:FindFirstChild("RF/SubmarineWorkerSpeak"):InvokeServer(unpack(args));
				return;
			end;
			Mon = "Grand Devotee";
			LevelQuest = 2;
			NameQuest = "SubmergedQuest3";
			NameMon = "Grand Devotee";
			CFrameMon = CFrame.new(9591.0546875, -1993.47424316, 9808.70507812);
		end;
	end;
end;
-- VonLib - loaded from GitHub raw.
local VonLibrary = loadstring(game:HttpGet(
	"https://raw.githubusercontent.com/VoidDeveloper67/VonLib/refs/heads/main/main.luau"
))();

-- Compatibility bridge.
-- without modification.

local _Window = nil;
local Kz = {};

-- Notification helper
function Kz.CreateNoti(cfg, force)
	if _Window then
		_Window:Notify({
			Title   = cfg.Title   or "VoidHub",
			Content = cfg.Desc    or cfg.Description or cfg.Content or "",
			Duration = cfg.Time  or cfg.Duration or 5,
			Image   = cfg.Image,
		});
	end;
end;

-- Create* methods forward to VonLib's Tab:Add* calls.
local function _makeSection(Tab, sectionTitle)
	if sectionTitle and sectionTitle ~= "" then
		Tab:AddSection(sectionTitle);
	end;
	local S = {};

	function S.CreateToggle(cfg)
		return Tab:AddToggle({
			Name        = cfg.Title       or cfg.Name or "",
			Description = cfg.Description or cfg.Desc or "",
			Default     = cfg.Default     or false,
			Callback    = cfg.Callback,
		});
	end;

	function S.CreateButton(cfg)
		return Tab:AddButton({
			Name     = cfg.Title    or cfg.Name or "",
			Debounce = cfg.Debounce or 0,
			Callback = cfg.Callback,
		});
	end;

	-- Dropdown: old API uses Values=, new API uses Options=
	function S.CreateDropdown(cfg)
        local options = cfg.Values or cfg.Options or {}
        if type(options) ~= "table" then options = {} end
        local multi = cfg.Multi == true or cfg.MultiSelect == true
        local default = cfg.Default
        if type(default) == "boolean" then default = nil end
        if type(default) == "number" then default = options[default] end
        if multi then
            if type(default) == "string" then default = {default} end
            if type(default) ~= "table" then default = {} end
        elseif type(default) == "table" then
            default = default[1]
        end
        return Tab:AddDropdown({
            Name = cfg.Title or cfg.Name or "",
            Description = cfg.Description or cfg.Desc or "",
            Options = options, Default = default, MultiSelect = multi,
            Callback = cfg.Callback,
        })
    end;

	-- Slider: old API passes callback as optional second arg
	function S.CreateSlider(cfg, externalCb)
		return Tab:AddSlider({
			Name        = cfg.Title     or cfg.Name or "",
			Description = cfg.Desc      or "",
			Min         = cfg.Min       or 0,
			Max         = cfg.Max       or 100,
			Increment   = cfg.Increment or 1,
			Default     = cfg.Default   or 0,
			Callback    = externalCb    or cfg.Callback,
		});
	end;

	function S.CreateLabel(cfg)
		local text = (cfg.Title or "") .. (cfg.Content or "");
		local lbl = Tab:AddLabel(text);
		local obj = {};
		function obj:SetDesc(newText)
			lbl:SetText(newText);
		end;
		obj.Set = obj.SetDesc;
		obj.SetText = obj.SetDesc;
		return obj;
	end;

	-- TextBox (CreateBox in the old API)
	function S.CreateBox(cfg)
		return Tab:AddTextBox({
			Name          = cfg.Title        or cfg.Name or "",
			Description   = cfg.Description  or cfg.Desc or "",
			Placeholder   = cfg.Placeholder  or "",
			ClearOnFocus  = cfg.ClearOnFocus or false,
			Callback      = cfg.Callback,
		});
	end;

	return S;
end;

-- Tab factory: wraps a VonLib Tab and exposes CreateSection
local function _makeTabWrapper(Tab)
	local T = {};
	function T.CreateSection(title)
		return _makeSection(Tab, title);
	end;
	return T;
end;

-- Main window factory (replaces Kz.CreateMain / Cz.T)
function Kz.CreateMain(cfg)
	_Window = VonLibrary:MakeWindow({
		Title       = "VoidHub",
		SubTitle    = "by von63rd | Sea " .. (World1 and "1" or World2 and "2" or World3 and "3" or "?"),
		ScriptFolder = "VoidHubBloxFruits",
	});

	-- Keyboard + mobile minimizer
	local _Min = _Window:NewMinimizer({ KeyCode = Enum.KeyCode.RightControl });
	_Min:CreateMobileMinimizer({
		Image  = "rbxassetid://101833678008843",
		Size   = UDim2.new(0, 35, 0, 35),
		Corner = { CornerRadius = UDim.new(0, 6) },
	});

	-- Welcome notification
	_Window:Notify({
		Title    = "VoidHub Loaded",
		Content  = "VoidHub by von63rd | RightCtrl to Minimize",
		Image    = "rbxassetid://101833678008843",
		Duration = 5,
	});

	local Cz = {};

	-- Tab builder: matches old Cz.T({ Page_Name=..., Page_Title=... })
	function Cz.T(tabCfg)
		local title = tabCfg.Page_Title or tabCfg.Page_Name or "Tab";
		local icon  = tabCfg.Icon or "rbxassetid://10734966248"; -- star default

		-- Per-tab icon selection by title keyword
		local tl = title:lower();
		if tl:find("farm") and not tl:find("item") then
			icon = "rbxassetid://10734975486";
		elseif tl:find("config") then
			icon = "rbxassetid://10734950309";
		elseif tl:find("fighting") then
			icon = "rbxassetid://10734975692";
		elseif tl:find("item") then
			icon = "rbxassetid://10734909540";
		elseif tl:find("sea") then
			icon = "rbxassetid://10747376931";
		elseif tl:find("mirage") or tl:find("racev4") or tl:find("race") then
			icon = "rbxassetid://10734966248";
		elseif tl:find("drago") or tl:find("dojo") then
			icon = "rbxassetid://10723376114";
		elseif tl:find("prehistoric") then
			icon = "rbxassetid://10709781605";
		elseif tl:find("raid") then
			icon = "rbxassetid://10734951847";
		elseif tl:find("combat") or tl:find("pvp") then
			icon = "rbxassetid://10734977012";
		elseif tl:find("teleport") then
			icon = "rbxassetid://10734886202";
		elseif tl:find("fruit") then
			icon = "rbxassetid://10709761889";
		elseif tl:find("shop") then
			icon = "rbxassetid://10734952479";
		elseif tl:find("misc") then
			icon = "rbxassetid://10734887784";
		end;

		local Tab = _Window:MakeTab({ Title = title, Icon = icon });
		return _makeTabWrapper(Tab);
	end;

	return Cz;
end;

-- VoidHub colour constants.
local VoidHubTheme = {
	primary_accent   = Color3.fromRGB(0, 255, 200),
	secondary_accent = Color3.fromRGB(0, 255, 150),
	neon_cyan        = Color3.fromRGB(0, 255, 255),
	neon_green       = Color3.fromRGB(0, 255, 100),
	neon_red         = Color3.fromRGB(255, 0, 50),
	neon_purple      = Color3.fromRGB(170, 0, 255),
	neon_pink        = Color3.fromRGB(255, 0, 150),
	bg_dark          = Color3.fromRGB(10, 10, 15),
	bg_darker        = Color3.fromRGB(20, 20, 20),
	bg_button        = Color3.fromRGB(25, 25, 30),
	bg_button_dark   = Color3.fromRGB(20, 20, 20),
	text_white       = Color3.fromRGB(255, 255, 255),
	text_dark        = Color3.fromRGB(0, 0, 0),
	accent_blue      = Color3.fromRGB(0, 160, 255),
	enemy_red        = Color3.fromRGB(255, 50, 50),
	success_green    = Color3.fromRGB(0, 255, 150),
	hot_pink         = Color3.fromRGB(255, 100, 200),
	deep_green       = Color3.fromRGB(0, 200, 50),
	pure_red         = Color3.fromRGB(255, 0, 0),
};
local _T = VoidHubTheme;

local Cz = Kz.CreateMain({ Desc = "" });
local vz = Cz.T({ Page_Name = "Farm", Page_Title = "Farm" });
local mz = Cz.T({ Page_Name = "Config", Page_Title = "Config" });
VoidSecretTab = Cz.T({ Page_Name = "Auto Secret Quests", Page_Title = "Auto Secret Quests" });
local yz = Cz.T({ Page_Name = "Fighting Style", Page_Title = "Fighting Style" });
local bz = Cz.T({ Page_Name = "Items Farm", Page_Title = "Items Farm" });
local cz = Cz.T({ Page_Name = "Sea Events", Page_Title = "Sea Events" });
local Hz = Cz.T({ Page_Name = "Mirage + RaceV4", Page_Title = "Mirage + RaceV4" });
local Sz = Cz.T({ Page_Name = "Drago Dojo", Page_Title = "Drago Dojo" });
local oz = Cz.T({ Page_Name = "Prehistoric", Page_Title = "Prehistoric" });
local Zz = Cz.T({ Page_Name = "Raid", Page_Title = "Raid" });
local Tz = Cz.T({ Page_Name = "Combat PVP", Page_Title = "Combat PVP" });
local kz = Cz.T({ Page_Name = "Teleport", Page_Title = "Teleport" });
local Lz = Cz.T({ Page_Name = "Fruits", Page_Title = "Fruits" });
local Pz = Cz.T({ Page_Name = "Shop", Page_Title = "Shop" });
local jz = Cz.T({ Page_Name = "Misc", Page_Title = "Misc" });
local Gz = vz.CreateSection("Farm");
Gz.CreateToggle({
	Title = "Auto Farm Level",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.Level = Y;
	end,
});
VoidS1Farm = { NextQuestAt = 0, Status = "idle", LastError = nil, QuestName = nil, QuestConfirmedAt = 0, ActiveTarget = nil };
function VoidQuestState()
	local tracked = u:FindFirstChild("TrackedQuestFrame", true);
	local frame = tracked and tracked:FindFirstChild("Frame");
	if frame then
		local header = frame:FindFirstChild("header");
		local title = header and header:FindFirstChild("textLabel");
		local enabled = not tracked:IsA("ScreenGui") or tracked.Enabled;
		return enabled and frame.Visible, title and title.Text or "";
	end;
	local main = u:FindFirstChild("Main");
	local quest = main and main:FindFirstChild("Quest");
	local container = quest and quest:FindFirstChild("Container");
	local heading = container and container:FindFirstChild("QuestTitle");
	local title = heading and heading:FindFirstChild("Title");
	return quest ~= nil and quest.Visible, title and title.Text or "";
end;
function CheckHasQuest(name)
    local q = VoidQuestSnapshot
    if type(q) == "table" and type(q.Task) == "table" then
        for target in pairs(q.Task) do
            if tostring(target):lower() == tostring(name):lower() then
				VoidS1Farm.QuestName, VoidS1Farm.QuestConfirmedAt = tostring(name):lower(), os.clock();
				return true
			end
        end
    end
	local visible, title = VoidQuestState();
	if name == nil then return false end
	local wanted = tostring(name):lower()
	local shown = tostring(title):lower()
	if visible and shown:find(wanted, 1, true) then
		VoidS1Farm.QuestName, VoidS1Farm.QuestConfirmedAt = wanted, os.clock();
		return true
	end
	-- Current quest titles abbreviate longer enemy names on small/mobile UI.
	local from, matched = 1, 0
	for word in wanted:gmatch("[%a%d]+") do
		if #word >= 3 then
			local stem = word:sub(1, math.min(#word, 3))
			local at = shown:find(stem, from, true)
			if not at then matched = 0; break end
			from, matched = at + #stem, matched + 1
		end
	end
	if visible and matched > 0 then
		VoidS1Farm.QuestName, VoidS1Farm.QuestConfirmedAt = wanted, os.clock();
		return true
	end
	local activeHumanoid = VoidS1Farm.ActiveTarget and VoidS1Farm.ActiveTarget:FindFirstChildOfClass("Humanoid");
	if activeHumanoid and activeHumanoid.Health > 0 and VoidS1Farm.QuestName == wanted then return true end
	return VoidS1Farm.QuestName == wanted and os.clock() - VoidS1Farm.QuestConfirmedAt <= 6
end;
function VoidS1Request(...)
	local args = table.pack(...);
	local done, ok, result = false, false, nil;
	local worker = task.spawn(function()
		ok, result = pcall(function() return Q.Remotes.CommF_:InvokeServer(table.unpack(args, 1, args.n)); end);
		done = true;
	end);
	local deadline = os.clock() + 5;
	while not done and os.clock() < deadline do task.wait(.1); end;
	if not done then pcall(task.cancel, worker); error("Quest request timed out", 0); end;
	if not ok then error(tostring(result), 0); end;
	return result;
end;
function VoidS1Spawn(name, fallback, root)
	local state = VoidS1Farm;
	local now = os.clock();
	if state.SpawnName == name and state.Spawn and state.Spawn.Parent and now < (state.SpawnUntil or 0) then
		return state.Spawn.CFrame * CFrame.new(0, 3, 0);
	end;
	local origin = workspace:FindFirstChild("_WorldOrigin");
	local folder = origin and origin:FindFirstChild("EnemySpawns");
	local best, distance;
	for _, part in ipairs(folder and folder:GetChildren() or {}) do
		if part:IsA("BasePart") and part.Name:gsub("%s*%[Lv%..-%]", ""):lower() == tostring(name):lower() then
			local n = (part.Position - root.Position).Magnitude;
			if part ~= state.Spawn and (not distance or n < distance) then best, distance = part, n; end;
		end;
	end;
	best = best or (state.SpawnName == name and state.Spawn and state.Spawn.Parent and state.Spawn);
	if not best then return fallback; end;
	state.Spawn, state.SpawnName, state.SpawnUntil = best, name, now + 10;
	return best.CFrame * CFrame.new(0, 3, 0);
end;
Gz.CreateToggle({
	Title = "Auto Travel Dressrosa",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.TravelDres = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		pcall(function()
			if _G.TravelDres then
				if d.Data.Level.Value >= 700 then
					if workspace.Map.Ice.Door.CanCollide == true and workspace.Map.Ice.Door.Transparency == 0 then
						Q.Remotes.CommF_:InvokeServer("DressrosaQuestProgress", "Detective");
						EquipWeapon("Key");
						repeat
							task.wait();
							_tp(CFrame.new(1347.7124, 37.3751602, -1325.6488));
						until not _G.TravelDres or R.Position == (CFrame.new(1347.7124, 37.3751602, -1325.6488)).Position;
					elseif workspace.Map.Ice.Door.CanCollide == false and workspace.Map.Ice.Door.Transparency == 1 then
						if M:FindFirstChild("Ice Admiral") then
							for Y, d in pairs(M:GetChildren()) do
								if d.Name == "Ice Admiral" and f.Alive(d) then
									repeat
										task.wait();
										f.Kill(d, _G.TravelDres);
									until _G.TravelDres == false or d.Humanoid.Health <= 0;
									Q.Remotes.CommF_:InvokeServer("TravelDressrosa");
								end;
							end;
						else
							_tp(CFrame.new(1347.7124, 37.3751602, -1325.6488));
						end;
					else
						Q.Remotes.CommF_:InvokeServer("TravelDressrosa");
					end;
				end;
			end;
		end);
	end;
end);
Gz.CreateToggle({
	Title = "Auto Zou Quest",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.AutoZou = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		pcall(function()
			if _G.AutoZou then
				if d.Data.Level.Value >= 1500 then
					if Q.Remotes.CommF_:InvokeServer("BartiloQuestProgress", "Bartilo") == 3 then
						if (Q.Remotes.CommF_:InvokeServer("GetUnlockables")).FlamingoAccess ~= nil then
							Q.Remotes.CommF_:InvokeServer("F_", "TravelZou");
							if Q.Remotes.CommF_:InvokeServer("ZQuestProgress", "Check") == 0 then
								local Y = GetConnectionEnemies("rip_indra");
								if Y then
									repeat
										task.wait();
										f.Kill(Y, _G.AutoZou);
									until not _G.AutoZou or not Y.Parent or Y.Humanoid.Health <= 0;
									Check = 2;
									repeat
										task.wait();
										Q.Remotes.CommF_:InvokeServer("F_", "TravelZou");
									until Check == 1;
								else
									Q.Remotes.CommF_:InvokeServer("F_", "ZQuestProgress", "Check");
									task.wait(.1);
									Q.Remotes.CommF_:InvokeServer("F_", "ZQuestProgress", "Begin");
								end;
							elseif Q.Remotes.CommF_:InvokeServer("ZQuestProgress", "Check") == 1 then
								Q.Remotes.CommF_:InvokeServer("F_", "TravelZou");
							else
								local Y = GetConnectionEnemies("Don Swan");
								if Y then
									repeat
										task.wait();
										f.Kill(Y, _G.AutoZou);
									until not _G.AutoZou or not Y.Parent or Y.Humanoid.Health <= 0;
								else
									repeat
										task.wait();
										_tp(CFrame.new(2288.802, 15.1870775, 863.034607));
									until not _G.AutoZou or R.Position == (CFrame.new(2288.802, 15.1870775, 863.034607)).Position;
									if R.CFrame == CFrame.new(2288.802, 15.1870775, 863.034607) then
										notween(CFrame.new(2288.802, 15.1870775, 863.034607));
									end;
								end;
							end;
						else
							if (Q.Remotes.CommF_:InvokeServer("GetUnlockables")).FlamingoAccess == nil then
								TabelDevilFruitStore = {};
								TabelDevilFruitOpen = {};
								for Y, d in pairs(Q.Remotes.CommF_:InvokeServer("getInventoryFruits")) do
									for Y, d in pairs(d) do
										if Y == "Name" then
											table.insert(TabelDevilFruitStore, d);
										end;
									end;
								end;
								for Y, d in next, (game.ReplicatedStorage:WaitForChild("Remotes")).CommF_:InvokeServer("GetFruits") do
									if d.Price >= 1000000 then
										table.insert(TabelDevilFruitOpen, d.Name);
									end;
								end;
								for Y, R in pairs(TabelDevilFruitOpen) do
									for Y, r in pairs(TabelDevilFruitStore) do
										if R == r and (Q.Remotes.CommF_:InvokeServer("GetUnlockables")).FlamingoAccess == nil then
											if not d.Backpack:FindFirstChild(r) then
												Q.Remotes.CommF_:InvokeServer("F_", "LoadFruit", r);
											else
												Q.Remotes.CommF_:InvokeServer("F_", "TalkTrevor", "1");
												Q.Remotes.CommF_:InvokeServer("F_", "TalkTrevor", "2");
												Q.Remotes.CommF_:InvokeServer("F_", "TalkTrevor", "3");
											end;
										end;
									end;
								end;
								Q.Remotes.CommF_:InvokeServer("F_", "TalkTrevor", "1");
								Q.Remotes.CommF_:InvokeServer("F_", "TalkTrevor", "2");
								Q.Remotes.CommF_:InvokeServer("F_", "TalkTrevor", "3");
							end;
						end;
					else
						if Q.Remotes.CommF_:InvokeServer("BartiloQuestProgress", "Bartilo") == 0 then
							if string.find(d.PlayerGui.Main.Quest.Container.QuestTitle.Title.Text, "Swan Pirates") and (string.find(d.PlayerGui.Main.Quest.Container.QuestTitle.Title.Text, "50") and d.PlayerGui.Main.Quest.Visible == true) then
								local Y = GetConnectionEnemies("Swan Pirate");
								if Y then
									pcall(function()
										repeat
											task.wait();
											f.Kill(Y, _G.AutoZou);
										until not Y.Parent or Y.Humanoid.Health <= 0 or _G.AutoZou == false or d.PlayerGui.Main.Quest.Visible == false;
									end);
								else
									_tp(CFrame.new(1057.92761, 137.614319, 1242.08069));
								end;
							else
								_tp(CFrame.new(-456.28952, 73.0200958, 299.895966));
							end;
						elseif Q.Remotes.CommF_:InvokeServer("BartiloQuestProgress", "Bartilo") == 1 then
							local Y = GetConnectionEnemies("Jeremy");
							if Y then
								repeat
									task.wait();
									f.Kill(Y, _G.AutoZou);
								until not Y.Parent or Y.Humanoid.Health <= 0 or _G.AutoZou == false;
							else
								_tp(CFrame.new(2099.88159, 448.931, 648.997375));
							end;
						elseif Q.Remotes.CommF_:InvokeServer("BartiloQuestProgress", "Bartilo") == 2 then
							repeat
								task.wait();
								_tp(CFrame.new(-1836, 11, 1714));
							until not _G.AutoZou or R.Position == (CFrame.new(-1836, 11, 1714)).Position;
							if R.CFrame == CFrame.new(-1836, 11, 1714) then
								notween(CFrame.new(-1836, 11, 1714));
							end;
							notween(CFrame.new(-1850.49329, 13.1789551, 1750.89685));
							task.wait(.1);
							notween(CFrame.new(-1858.87305, 19.3777466, 1712.01807));
							task.wait(.1);
							notween(CFrame.new(-1803.94324, 16.5789185, 1750.89685));
							task.wait(.1);
							notween(CFrame.new(-1858.55835, 16.8604317, 1724.79541));
							task.wait(.1);
							notween(CFrame.new(-1869.54224, 15.987854, 1681.00659));
							task.wait(.1);
							notween(CFrame.new(-1800.0979, 16.4978027, 1684.52368));
							task.wait(.1);
							notween(CFrame.new(-1819.26343, 14.795166, 1717.90625));
							task.wait(.1);
							notween(CFrame.new(-1813.51843, 14.8604736, 1724.79541));
						end;
					end;
				end;
			end;
		end);
	end;
end);
local qz = vz.CreateSection("Miscellanea / Quest");
qz.CreateToggle({
	Title = "Auto Farm Nearest",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.AutoFarmNear = Y;
	end,
});
task.spawn(function()
	while task.wait() do
		pcall(function()
			if _G.AutoFarmNear then
				for Y, d in pairs(workspace.Enemies:GetChildren()) do
					if d:FindFirstChild("Humanoid") or d:FindFirstChild("HumanoidRootPart") then
						if d.Humanoid.Health > 0 then
							repeat
								task.wait();
								f.Kill(d, _G.AutoFarmNear);
							until not _G.AutoFarmNear or not d.Parent or d.Humanoid.Health <= 0;
						end;
					end;
				end;
			end;
		end);
	end;
end);
qz.CreateToggle({
	Title = "Auto Factory Raid",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.AutoFactory = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		pcall(function()
			if _G.AutoFactory then
				local Y = GetConnectionEnemies("Core");
				if Y then
					repeat
						task.wait();
						EquipWeapon(_G.SelectWeapon);
						_tp(CFrame.new(448.46756, 199.356781, -441.389252));
					until Y.Humanoid.Health <= 0 or _G.AutoFactory == false;
				else
					_tp(CFrame.new(448.46756, 199.356781, -441.389252));
				end;
			end;
		end);
	end;
end);
qz.CreateToggle({
	Title = "Auto Pirate Raid",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.AutoRaidCastle = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		if _G.AutoRaidCastle then
			pcall(function()
				local Y = CFrame.new(-5496.17432, 313.768921, -2841.53027, .924894512, 7.37058015e-09, .380223751, 3.5881019e-08, 1, -1.06665446e-07, -0.38022375, 1.12297109e-07, .924894512);
				if ((CFrame.new(-5539.31152343, 313.80053710, -2972.37231445)).Position - R.Position).Magnitude <= 500 then
					for Y, d in pairs(workspace.Enemies:GetChildren()) do
						if d:FindFirstChild("HumanoidRootPart") and (d:FindFirstChild("Humanoid") and d.Humanoid.Health > 0) then
							if d.Name then
								if (d.HumanoidRootPart.Position - R.Position).Magnitude <= 2000 then
									repeat
										task.wait();
										f.Kill(d, _G.AutoRaidCastle);
									until not _G.AutoRaidCastle or not d.Parent or d.Humanoid.Health <= 0 or not workspace.Enemies:FindFirstChild(d.Name);
								end;
							end;
						end;
					end;
				else
					local d = {
							"Galley Pirate",
							"Galley Captain",
							"Raider",
							"Mercenary",
							"Vampire",
							"Zombie",
							"Snow Trooper",
							"Winter Warrior",
							"Lab Subordinate",
							"Horned Warrior",
							"Magma Ninja",
							"Lava Pirate",
							"Ship Deckhand",
							"Ship Engineer",
							"Ship Steward",
							"Ship Officer",
							"Arctic Warrior",
							"Snow Lurker",
							"Sea Soldier",
							"Water Fighter",
						};
					for R = 1, #d, 1 do
						if Q:FindFirstChild(d[R]) then
							for R, Q in pairs(Q:GetChildren()) do
								if table.find(d, Q.Name) then
									_tp(Y);
								end;
							end;
						end;
					end;
				end;
			end);
		end;
	end;
end);
qz.CreateDropdown({
	Title = "Choose Material",
	Description = "",
	Values = v,
	Default = nil,
	Multi = false,
	Callback = function(Y)
		(getgenv()).SelectMaterial = Y;
	end,
});
qz.CreateToggle({
	Title = "Auto Materials",
	Description = "",
	Default = false,
	Callback = function(Y)
		(getgenv()).AutoMaterial = Y;
	end,
});
task.spawn(function()
	local function Y(Y, d)
		local humanoid = Y and Y:FindFirstChildOfClass("Humanoid");
		if humanoid and Y:FindFirstChild("HumanoidRootPart") and humanoid.Health > 0 then
			if string.lower(Y.Name) == string.lower(tostring(d)) then
				repeat
					task.wait();
					f.Kill(Y, (getgenv()).AutoMaterial);
				until not (getgenv()).AutoMaterial or not Y.Parent or Y.Humanoid.Health <= 0;
			end;
		end;
	end;
	local function d()
		local origin = game:GetService("Workspace"):FindFirstChild("_WorldOrigin");
		local spawns = origin and origin:FindFirstChild("EnemySpawns");
		if not spawns then return end;
		for Y, d in pairs(spawns:GetChildren()) do
			for Y, R in ipairs(MMon) do
				if d:IsA("BasePart") and string.find(string.lower(d.Name), string.lower(R), 1, true) then
					local root = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart");
					if root and (root.Position - d.Position).Magnitude >= 10 then
						_tp(d.CFrame * (Pos or CFrame.new(0, 20, 0)));
					end;
				end;
			end;
		end;
	end;
	while task.wait() do
		if (getgenv()).AutoMaterial then
			pcall(function()
				if not (getgenv()).SelectMaterial then return end;
				MaterialMon((getgenv()).SelectMaterial);
				if type(MMon) ~= "table" or #MMon == 0 or typeof(MPos) ~= "CFrame" then return end;
				local target;
				for _, name in ipairs(MMon) do target = GetConnectionEnemies(name); if target then break end end;
				if target then
					Y(target, target.Name);
				else
					if not f.Pos(MPos, 12) then _tp(MPos) end;
					d();
				end;
			end);
		end;
	end;
end);
qz.CreateToggle({
	Title = "Auto Farm Ectoplasm",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.AutoEctoplasm = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		pcall(function()
			if _G.AutoEctoplasm then
				local Y = {
						"Ship Deckhand",
						"Ship Engineer",
						"Ship Steward",
						"Ship Officer",
						"Arctic Warrior",
					};
				local d = GetConnectionEnemies(Y);
				if f.Alive(d) then
					repeat
						task.wait();
						f.Kill(d, _G.AutoEctoplasm);
					until not _G.AutoEctoplasm or not d.Parent or d.Humanoid.Health <= 0;
				else
					Q.Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(923.21252441, 126.97600555, 32852.83203125));
				end;
			end;
		end);
	end;
end);
qz.CreateToggle({
	Title = "Auto Done Bartilo Quest",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.Bartilo_Quest = Y;
	end,
});
task.spawn(function()
	while task.wait(.1) do
		pcall(function()
			if _G.Bartilo_Quest and r >= 850 then
				local Y = d.PlayerGui.Main.Quest;
				if Q.Remotes.CommF_:InvokeServer("BartiloQuestProgress", "Bartilo") == 0 then
					_G.Level = false;
					if Y.Visible == true then
						local R = GetConnectionEnemies("Swan Pirate");
						if R then
							local R = GetConnectionEnemies(X);
							if R then
								repeat
									task.wait();
									if not string.find(d.PlayerGui.Main.Quest.Container.QuestTitle.Title.Text, "Swan Pirate") then
										Q.Remotes.CommF_:InvokeServer("AbandonQuest");
									else
										f.Kill(R, _G.Bartilo_Quest);
									end;
								until _G.Bartilo_Quest == false or not R.Parent or R.Humanoid.Health <= 0 or Y.Visible == false or not R:FindFirstChild("HumanoidRootPart");
							end;
						else
							_tp(CFrame.new(970.369446, 142.653198, 1217.3667, .162079468, -4.85452638e-08, -0.98677772, 1.03357589e-08, 1, -4.74980872e-08, .986777723, -2.50063148e-09, .162079468));
						end;
					else
						repeat
							task.wait();
							_tp(CFrame.new(-461.533203, 72.3478546, 300.311096, .050853312, 0, -0.99870610, 0, 1, 0, .998706102, 0, .050853312));
						until ((CFrame.new(-461.533203, 72.3478546, 300.311096, .050853312, 0, -0.99870610, 0, 1, 0, .998706102, 0, .050853312)).Position - d.Character.HumanoidRootPart.Position).Magnitude <= 20 or _G.Bartilo_Quest == false;
						if ((CFrame.new(-461.533203, 72.3478546, 300.311096, .050853312, 0, -0.99870610, 0, 1, 0, .998706102, 0, .050853312)).Position - d.Character.HumanoidRootPart.Position).Magnitude <= 1 then
							Q.Remotes.CommF_:InvokeServer("StartQuest", "BartiloQuest", 1);
						end;
					end;
				elseif Q.Remotes.CommF_:InvokeServer("BartiloQuestProgress", "Bartilo") == 1 then
					_G.Level = false;
					local d = GetConnectionEnemies("Jeremy");
					if d then
						repeat
							task.wait();
							f.Kill(d, _G.Bartilo_Quest);
						until _G.Bartilo_Quest == false or not d.Parent or d.Humanoid.Health <= 0 or Y.Visible == false or not d:FindFirstChild("HumanoidRootPart");
					else
						_tp(CFrame.new(2158.97412, 449.056244, 705.411682, -0.75419956, -4.17389057e-09, -0.65664523, -4.47752875e-08, 1, 4.50709301e-08, .656645238, 6.3393955e-08, -0.75419956));
					end;
				elseif Q.Remotes.CommF_:InvokeServer("BartiloQuestProgress", "Bartilo") == 2 then
					repeat
						task.wait();
						_tp(CFrame.new(-1830.83972, 10.5578213, 1680.60229, .979988456, -2.02152783e-08, -0.19905428, 2.20792113e-08, 1, 7.1442483e-09, .199054286, -1.13962431e-08, .979988456));
					until ((CFrame.new(-1830.83972, 10.5578213, 1680.60229, .979988456, -2.02152783e-08, -0.19905428, 2.20792113e-08, 1, 7.1442483e-09, .199054286, -1.13962431e-08, .979988456)).Position - d.Character.HumanoidRootPart.Position).Magnitude <= 1 or _G.Bartilo_Quest == false;
					task.wait(.5);
					d.Character.HumanoidRootPart.CFrame = workspace.Map.Dressrosa.BartiloPlates.Plate1.CFrame;
					task.wait(.5);
					d.Character.HumanoidRootPart.CFrame = workspace.Map.Dressrosa.BartiloPlates.Plate2.CFrame;
					task.wait(.5);
					d.Character.HumanoidRootPart.CFrame = workspace.Map.Dressrosa.BartiloPlates.Plate3.CFrame;
					task.wait(.5);
					d.Character.HumanoidRootPart.CFrame = workspace.Map.Dressrosa.BartiloPlates.Plate4.CFrame;
					task.wait(.5);
					d.Character.HumanoidRootPart.CFrame = workspace.Map.Dressrosa.BartiloPlates.Plate5.CFrame;
					task.wait(.5);
					d.Character.HumanoidRootPart.CFrame = workspace.Map.Dressrosa.BartiloPlates.Plate6.CFrame;
					task.wait(.5);
					d.Character.HumanoidRootPart.CFrame = workspace.Map.Dressrosa.BartiloPlates.Plate7.CFrame;
					task.wait(.5);
					d.Character.HumanoidRootPart.CFrame = workspace.Map.Dressrosa.BartiloPlates.Plate8.CFrame;
					task.wait(2.5);
				end;
			end;
		end);
	end;
end);
qz.CreateToggle({
	Title = "Auto Done Citizen Quest",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.CitizenQuest = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		pcall(function()
			if _G.CitizenQuest then
				if r >= 1800 and (Q.Remotes.CommF_:InvokeServer("CitizenQuestProgress")).KilledBandits == false then
					if string.find(d.PlayerGui.Main.Quest.Container.QuestTitle.Title.Text, "Forest Pirate") and (string.find(d.PlayerGui.Main.Quest.Container.QuestTitle.Title.Text, "50") and d.PlayerGui.Main.Quest.Visible == true) then
						local Y = GetConnectionEnemies("Forest Pirate");
						if Y then
							repeat
								task.wait();
								f.Kill(Y, _G.CitizenQuest);
							until _G.CitizenQuest == false or not Y.Parent or Y.Humanoid.Health <= 0 or d.PlayerGui.Main.Quest.Visible == false;
						else
							_tp(CFrame.new(-13206.45214843, 425.89199829, -7964.55371093));
						end;
					else
						_tp(CFrame.new(-12443.8671875, 332.40396118, -7675.48925781));
						if (Vector3.new(-12443.8671875, 332.40396118, -7675.48925781) - d.Character.HumanoidRootPart.Position).Magnitude <= 30 then
							task.wait(1.5);
							Q.Remotes.CommF_:InvokeServer("StartQuest", "CitizenQuest", 1);
						end;
					end;
				elseif r >= 1800 and (Q.Remotes.CommF_:InvokeServer("CitizenQuestProgress")).KilledBoss == false then
					local Y = GetConnectionEnemies("Captain Elephant");
					if d.PlayerGui.Main.Quest.Visible and (string.find(d.PlayerGui.Main.Quest.Container.QuestTitle.Title.Text, "Captain Elephant") and d.PlayerGui.Main.Quest.Visible == true) then
						if Y then
							repeat
								task.wait();
								f.Kill(Y, _G.CitizenQuest);
							until _G.CitizenQuest == false or Y.Humanoid.Health <= 0 or not Y.Parent or d.PlayerGui.Main.Quest.Visible == false;
						else
							_tp(CFrame.new(-13374.88964843, 421.27752685, -8225.20898437));
						end;
					else
						_tp(CFrame.new(-12443.8671875, 332.40396118, -7675.48925781));
						if ((CFrame.new(-12443.8671875, 332.40396118, -7675.48925781)).Position - d.Character.HumanoidRootPart.Position).Magnitude <= 4 then
							task.wait(1.5);
							Q.Remotes.CommF_:InvokeServer("CitizenQuestProgress", "Citizen");
						end;
					end;
				elseif r >= 1800 and Q.Remotes.CommF_:InvokeServer("CitizenQuestProgress", "Citizen") == 2 then
					_tp(CFrame.new(-12512.13867187, 340.39279174, -9872.8203125));
				end;
			end;
		end);
	end;
end);
qz.CreateToggle({
	Title = "Auto Training Dummy",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.DummyMan = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		if _G.DummyMan then
			pcall(function()
				if d.PlayerGui.Main.Quest.Visible == false then
					local Y = { [1] = "ArenaTrainer" };
					((Q:WaitForChild("Remotes")):WaitForChild("CommF_")):InvokeServer(unpack(Y));
				else
					local Y = GetConnectionEnemies("Training Dummy");
					if Y then
						repeat
							task.wait();
							f.Kill(Y, _G.DummyMan);
						until not _G.DummyMan or not Y.Parent or Y.Humanoid.Health <= 0;
					else
						_tp(CFrame.new(3688.00512695, 12.74694347, 170.20953369));
					end;
				end;
			end);
		end;
	end;
end);
qz.CreateToggle({
	Title = "Auto Collect Berry",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.AutoBerry = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		if _G.AutoBerry then
			local Y = game:GetService("CollectionService");
			local d = game:GetService("Players");
			local R = d.LocalPlayer;
			local Q = Y:GetTagged("BerryBush");
			local r, a = math.huge;
			for Y = 1, #Q, 1 do
				local d = Q[Y];
				for Y, R in pairs(d:GetAttributes()) do
					if not BerryArray or table.find(BerryArray, R) then
						_tp(d.Parent:GetPivot());
						for Y = 1, #Q, 1 do
							local d = Q[Y];
							for Y, d in pairs(d:GetChildren()) do
								if not BerryArray or table.find(BerryArray, d) then
									_tp(d.WorldPivot);
									fireproximityprompt(d.ProximityPrompt, math.huge);
								end;
							end;
						end;
					end;
				end;
			end;
		end;
	end;
end);
qz.CreateToggle({
	Title = "Auto Collect Chest",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.AutoFarmChest = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		if _G.AutoFarmChest then
			pcall(function()
				local Y = game:GetService("CollectionService");
				local d = game:GetService("Players");
				local R = d.LocalPlayer;
				local Q = R.Character or R.CharacterAdded:Wait();
				if not Q then
					return;
				end;
				local r = (Q:GetPivot()).Position;
				local a = Y:GetTagged("_ChestTagged");
				local w, F = math.huge, nil;
				for Y = 1, #a, 1 do
					local d = a[Y];
					local R = ((d:GetPivot()).Position - r).Magnitude;
					if not SelectedIsland or d:IsDescendantOf(SelectedIsland) then
						if not d:GetAttribute("IsDisabled") and R < w then
							w = R;
							F = d;
						end;
					end;
				end;
				if F then
					_tp(F:GetPivot());
				end;
			end);
		end;
	end;
end);
local Vz = vz.CreateSection("Miscellanea / Fishing");
local tz = game:GetService("ReplicatedStorage");
local Xz = game:GetService("Players");
local hz = game:GetService("Workspace");
local Bz = Xz.LocalPlayer;
local lz = Bz.Character or Bz.CharacterAdded:Wait();
local pz = lz:WaitForChild("HumanoidRootPart");
local Ez = tz:WaitForChild("Modules");
local ez = Ez:WaitForChild("Net");
local Oz = tz:WaitForChild("FishReplicated");
local fz = Oz:FindFirstChild("FishingRequest");
local sz = Oz:FindFirstChild("FishingRemote");
local xz = Oz:WaitForChild("FishingClient");
local Jz = require(xz:WaitForChild("Config"));
local YF = tz:WaitForChild("Util");
local dF = require(YF:WaitForChild("GetWaterHeightAtLocation"));
local RF = ez:FindFirstChild("RF/JobsRemoteFunction");
local QF = ez:FindFirstChild("RF/Craft");
local function rF()
	if not RF then
		return;
	end;
	pcall(function()
		RF:InvokeServer("FishingNPC", "FirstTimeFreeRod");
		RF:InvokeServer("LoadItem", _G.SelectedRod, { "Gear" });
	end);
	task.wait(.5);
	local Y = Bz:FindFirstChild("Data") and Bz.Data:FindFirstChild("FishingData");
	if Y and table.find({ "None", nil }, Y:GetAttribute("SelectedBait")) then
		local Y, d = pcall(function()
				return RF:InvokeServer("getInventory");
			end);
		if Y and d then
			for Y, d in pairs(d) do
				if d.Type == "Bait" and d.Name == _G.SelectedBait then
					RF:InvokeServer("LoadItem", d.Name, { "Usables" });
					return;
				end;
			end;
		end;
		if QF then
			QF:InvokeServer("Craft", _G.SelectedBait);
			task.wait(2);
		end;
	end;
end;
local function aF()
	local Y = lz:FindFirstChildOfClass("Humanoid");
	if not lz:FindFirstChild(_G.SelectedRod) then
		local d = Bz.Backpack:FindFirstChild(_G.SelectedRod);
		if d and Y then
			Y:EquipTool(d);
			task.wait(.3);
		end;
	end;
end;
local function wF()
	local Y = dF(pz.Position);
	local d = pz.CFrame.LookVector * (Jz.Rod.MaxLaunchDistance or 50);
	local R, Q = hz:FindPartOnRayWithIgnoreList(Ray.new(lz.Head.Position, d), { lz, hz.Characters, hz.Enemies });
	if not Q then
		return pz.Position + Vector3.new(0, -10, 0);
	end;
	local r, a = hz:FindPartOnRayWithIgnoreList(Ray.new(Q + Vector3.new(0, 3, 0), Vector3.new(0, -500, 0)), { lz, hz.Characters, hz.Enemies });
	if a and a.Y < Y then
		return Vector3.new(Q.X, math.max(a.Y, Y), Q.Z);
	end;
	return Q;
end;
local function FF()
	if not fz then
		return;
	end;
	pcall(function()
		fz:InvokeServer("StartCasting");
		task.wait(.7);
		fz:InvokeServer("CastLineAtLocation", wF(), 100, true);
	end);
end;
local function MF()
	if not fz then
		return;
	end;
	pcall(function()
		fz:InvokeServer("Catching", 1);
		task.wait(.25);
		fz:InvokeServer("Catch", 1);
	end);
end;
local KF = {
		"Fishing Rod",
		"Gold Rod",
		"Shark Rod",
		"Shell Rod",
		"Treasure Rod",
	};
local nF = {
		"Basic Bait",
		"Kelp Bait",
		"Good Bait",
		"Abyssal Bait",
		"Frozen Bait",
		"Epic Bait",
		"Carnivore Bait",
	};
Vz.CreateDropdown({
	Title = "Select Fishing Rod",
	Description = "",
	Values = KF,
	Default = "Fishing Rod",
	Callback = function(Y)
		_G.SelectedRod = Y;
	end,
});
Vz.CreateDropdown({
	Title = "Select Bait",
	Description = "",
	Values = nF,
	Default = "Basic Bait",
	Callback = function(Y)
		_G.SelectedBait = Y;
	end,
});
Vz.CreateToggle({
	Title = "Auto Fishing",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.AutoFishing = Y;
		if V then
			task.spawn(function()
				while _G.AutoFishing do
					task.wait(.3);
					pcall(function()
						lz = Bz.Character or Bz.CharacterAdded:Wait();
						pz = lz:WaitForChild("HumanoidRootPart");
						rF();
						aF();
						local Y = lz:FindFirstChild(_G.SelectedRod);
						if Y then
							local d = Y:GetAttribute("ServerState") or Y:GetAttribute("State");
							if d == "Biting" then
								MF();
							elseif d == "ReeledIn" or d == "Idle" or not d then
								FF();
							end;
						else
							print("[WARN] Rod not found in Character");
						end;
					end);
				end;
			end);
		end;
	end,
});
local IF = vz.CreateSection("Miscellanea / Mastery");
local WF = { "Cake", "Bone" };
IF.CreateDropdown({
	Title = "Choose Island",
	Description = "",
	Values = WF,
	Default = "Cake",
	Callback = function(Y)
		SelectIsland = Y;
	end,
});
IF.CreateToggle({
	Title = "Auto Mastery Fruits",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.FarmMastery_Dev = Y;
	end,
});
task.spawn(function()
	W.RenderStepped:Connect(function()
		pcall(function()
			if _G.FarmMastery_Dev or _G.FarmMastery_G or _G.FarmMastery_S then
				for Y, d in pairs(d.PlayerGui.Notifications:GetChildren()) do
					if d.Name == "NotificationTemplate" then
						if string.find(d.Text, "Skill locked!") then
							d:Destroy();
						end;
					end;
				end;
			end;
		end);
	end);
end);
task.spawn(function()
	while task.wait(T) do
		if _G.FarmMastery_Dev then
			pcall(function()
				local root = d.Character and d.Character:FindFirstChild("HumanoidRootPart");
				local best, bestDistance;
				for _, mob in ipairs(workspace:FindFirstChild("Enemies") and workspace.Enemies:GetChildren() or {}) do
					local hum, hrp = mob:FindFirstChildOfClass("Humanoid"), mob:FindFirstChild("HumanoidRootPart");
					local distance = root and hrp and (hrp.Position-root.Position).Magnitude;
					if hum and hum.Health > 0 and distance and (not bestDistance or distance < bestDistance) then best, bestDistance = mob, distance; end;
				end;
				if best then
					HealthM = math.max(1, best.Humanoid.MaxHealth * .7);
					repeat task.wait(.05); MousePos = best.HumanoidRootPart.Position; f.Mas(best, _G.FarmMastery_Dev);
					until not _G.FarmMastery_Dev or not best.Parent or best.Humanoid.Health <= 0;
				elseif typeof(CFrameMon) == "CFrame" then _tp(CFrameMon); end;
			end);
		end;
	end;
end);
IF.CreateToggle({
	Title = "Auto Mastery Gun",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.FarmMastery_G = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		if _G.FarmMastery_G then
			pcall(function()
				if SelectIsland == "Cake" then
					local Y = GetConnectionEnemies(p);
					if Y then
						HealthM = (Y.Humanoid.MaxHealth * 70) / 100;
						repeat
							task.wait();
							MousePos = Y.HumanoidRootPart.Position;
							f.Masgun(Y, _G.FarmMastery_G);
							local R = Q:FindFirstChild("Modules");
							local r = R:FindFirstChild("Net");
							local a = r:FindFirstChild("RE/ShootGunEvent");
							if (d.Character:FindFirstChildOfClass("Tool")).ToolTip ~= "Gun" then
								return;
							end;
							if d.Character:FindFirstChildOfClass("Tool") and (d.Character:FindFirstChildOfClass("Tool")).Name == "Skull Guitar" then
								b = true;
								(d.Character:FindFirstChildOfClass("Tool")).RemoteEvent:FireServer("TAP", MousePos);
								if _G.FarmMastery_G then
									K:SendMouseButtonEvent(0, 0, 0, true, game, 1);
									task.wait(.05);
									K:SendMouseButtonEvent(0, 0, 0, false, game, 1);
									task.wait(.05);
								end;
							elseif d.Character:FindFirstChildOfClass("Tool") and (d.Character:FindFirstChildOfClass("Tool")).Name ~= "Skull Guitar" then
								b = false;
								a:FireServer(MousePos, { Y.HumanoidRootPart });
								if _G.FarmMastery_G then
									K:SendMouseButtonEvent(0, 0, 0, true, game, 1);
									task.wait(.05);
									K:SendMouseButtonEvent(0, 0, 0, false, game, 1);
									task.wait(.05);
								end;
							end;
						until _G.FarmMastery_G == false or Y.Humanoid.Health <= 0 or not Y.Parent;
						b = false;
					else
						_tp(CFrame.new(-1943.67651367, 251.50956726, -12337.88085937));
					end;
				elseif SelectIsland == "Bone" then
					local Y = GetConnectionEnemies(E);
					if Y then
						HealthM = (Y.Humanoid.MaxHealth * 70) / 100;
						repeat
							task.wait();
							MousePos = Y.HumanoidRootPart.Position;
							f.Masgun(Y, _G.FarmMastery_G);
							local R = Q:FindFirstChild("Modules");
							local r = R:FindFirstChild("Net");
							local a = r:FindFirstChild("RE/ShootGunEvent");
							if (d.Character:FindFirstChildOfClass("Tool")).ToolTip ~= "Gun" then
								return;
							end;
							if d.Character:FindFirstChildOfClass("Tool") and (d.Character:FindFirstChildOfClass("Tool")).Name == "Skull Guitar" then
								b = true;
								(d.Character:FindFirstChildOfClass("Tool")).RemoteEvent:FireServer("TAP", MousePos);
								if _G.FarmMastery_G then
									K:SendMouseButtonEvent(0, 0, 0, true, game, 1);
									task.wait(.05);
									K:SendMouseButtonEvent(0, 0, 0, false, game, 1);
									task.wait(.05);
								end;
							elseif d.Character:FindFirstChildOfClass("Tool") and (d.Character:FindFirstChildOfClass("Tool")).Name ~= "Skull Guitar" then
								b = false;
								a:FireServer(MousePos, { Y.HumanoidRootPart });
								if _G.FarmMastery_G then
									K:SendMouseButtonEvent(0, 0, 0, true, game, 1);
									task.wait(.05);
									K:SendMouseButtonEvent(0, 0, 0, false, game, 1);
									task.wait(.05);
								end;
							end;
						until _G.FarmMastery_G == false or Y.Humanoid.Health <= 0 or not Y.Parent;
						b = false;
					else
						_tp(CFrame.new(-9495.68066406, 453.58624267, 5977.34863281));
					end;
				end;
			end);
		end;
	end;
end);
IF.CreateToggle({
	Title = "Auto Mastery All Sword",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.FarmMastery_S = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		pcall(function()
			if _G.FarmMastery_S then
				if SelectIsland == "Cake" then
					for Y, d in next, Q.Remotes.CommF_:InvokeServer("getInventory") do
						if type(d) == "table" then
							if d.Type == "Sword" then
								SwordName = d.Name;
								if tonumber(d.Mastery) >= 1 or tonumber(d.Mastery) <= 599 then
									local Y = GetConnectionEnemies(p);
									if GetBP(SwordName) then
										if Y then
											repeat
												task.wait();
												f.Sword(Y, _G.FarmMastery_S);
											until _G.FarmMastery_S == false or not Y.Parent or Y.Humanoid.Healh <= 0;
										else
											_tp(CFrame.new(-1943.67651367, 251.50956726, -12337.88085937));
										end;
									else
										Q.Remotes.CommF_:InvokeServer("LoadItem", SwordName);
									end;
								elseif tonumber(d.Mastery) >= 600 then
									if GetBP(SwordName) then
										return nil;
									else
										Q.Remotes.CommF_:InvokeServer("LoadItem", SwordName);
									end;
								end;
								break;
							end;
						end;
					end;
				elseif SelectIsland == "Bone" then
					for Y, d in next, Q.Remotes.CommF_:InvokeServer("getInventory") do
						if type(d) == "table" then
							if d.Type == "Sword" then
								SwordName = d.Name;
								if tonumber(d.Mastery) >= 1 or tonumber(d.Mastery) <= 599 then
									local Y = GetConnectionEnemies(E);
									if GetBP(SwordName) then
										if Y then
											repeat
												task.wait();
												f.Sword(Y, _G.FarmMastery_S);
											until _G.FarmMastery_S == false or not Y.Parent or Y.Humanoid.Healh <= 0;
										else
											_tp(CFrame.new(-9495.68066406, 453.58624267, 5977.34863281));
										end;
									else
										Q.Remotes.CommF_:InvokeServer("LoadItem", SwordName);
									end;
								elseif tonumber(d.Mastery) >= 600 then
									if GetBP(SwordName) then
										return nil;
									else
										Q.Remotes.CommF_:InvokeServer("LoadItem", SwordName);
									end;
								end;
								break;
							end;
						end;
					end;
				end;
			end;
		end);
	end;
end);
local NF = vz.CreateSection("Generals Quests / Items");
local DF = NF.CreateLabel({ Title = "Cake Princes :", Content = "" });
local AF = NF.CreateLabel({ Title = " Bones :", Content = "" });
task.spawn(function()
	while task.wait(.2) do
		pcall(function()
			local Y = string.match(Q.Remotes.CommF_:InvokeServer("CakePrinceSpawner"), "%d+");
			if Y then
				DF:SetDesc(" Killed : " .. 500 - Y);
			end;
		end);
	end;
end);
task.spawn(function()
	while task.wait(.2) do
		pcall(function()
			AF:SetDesc(" Bones : " .. GetM("Bones"));
		end);
	end;
end);
NF.CreateToggle({
	Title = "Auto Cake Prince",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.Auto_Cake_Prince = Y;
	end,
});
task.spawn(function()
	while task.wait() do
		if _G.Auto_Cake_Prince then
			pcall(function()
				local player = game.Players.LocalPlayer;
				local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart");
				if not root then return end;
				local cakeLoaf = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("CakeLoaf");
				local mirror = cakeLoaf and cakeLoaf:FindFirstChild("BigMirror");
				local gate = mirror and mirror:FindFirstChild("Other");
				local boss = GetConnectionEnemies("Cake Prince");
				if boss then
					repeat task.wait(.1); f.Kill2(boss, _G.Auto_Cake_Prince); until not _G.Auto_Cake_Prince or not boss.Parent or not boss:FindFirstChildOfClass("Humanoid") or boss:FindFirstChildOfClass("Humanoid").Health <= 0;
					return;
				end;
				local mobs = {"Cookie Crafter", "Cake Guard", "Baking Staff", "Head Baker"};
				local target = GetConnectionEnemies(mobs);
				if target then
					f.Kill(target, _G.Auto_Cake_Prince);
				else
					local destination = gate and gate.Transparency == 0 and CFrame.new(-2151.82, 149.32, -12404.91) or CFrame.new(-2077, 252, -12373);
					if (destination.Position - root.Position).Magnitude > 60 then _tp(destination) end;
				end;
			end);
		end;
	end;
end);
NF.CreateToggle({
	Title = "Auto Bones",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.AutoFarm_Bone = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		if _G.AutoFarm_Bone then
			pcall(function()
				local Y = game.Players.LocalPlayer;
				local d = Y.Character and Y.Character:FindFirstChild("HumanoidRootPart");
				local R = Y.PlayerGui.Main.Quest;
				local Q = {
						"Reborn Skeleton",
						"Living Zombie",
						"Demonic Soul",
						"Posessed Mummy",
					};
				if not d then
					return;
				end;
				local r = GetConnectionEnemies(Q);
				if r then
					if _G.AcceptQuestC and not R.Visible then
						local Y = CFrame.new(-9516.99316, 172.017181, 6078.46533, 0, 0, -1, 0, 1, 0, 1, 0, 0);
						_tp(Y);
						while (Y.Position - d.Position).Magnitude > 50 do
							task.wait(.2);
						end;
						local R = math.random(1, 4);
						local Q = {
								[1] = { "StartQuest", "HauntedQuest2", 2 },
								[2] = { "StartQuest", "HauntedQuest2", 1 },
								[3] = { "StartQuest", "HauntedQuest1", 1 },
								[4] = { "StartQuest", "HauntedQuest1", 2 },
							};
						local r, a = pcall(function()
								return game.ReplicatedStorage.Remotes.CommF_:InvokeServer(unpack(Q[R]));
							end);
					end;
					repeat
						task.wait();
						f.Kill(r, _G.AutoFarm_Bone);
					until not _G.AutoFarm_Bone or r.Humanoid.Health <= 0 or not r.Parent or _G.AcceptQuestC and not R.Visible;
				else
					_tp(CFrame.new(-9495.68066406, 453.58624267, 5977.34863281));
				end;
			end);
		end;
	end;
end);
NF.CreateToggle({
	Title = "Accept Quests",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.AcceptQuestC = Y;
	end,
});
NF.CreateToggle({
	Title = "Auto Farm Mirror",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.AutoMiror = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		if _G.AutoMiror then
			pcall(function()
				local Y = GetConnectionEnemies("Dough King");
				if Y then
					repeat
						task.wait();
						f.Kill(Y, _G.AutoMiror);
					until not _G.AutoMiror or not Y.Parent or Y.Humanoid.Health <= 0;
				else
					_tp(CFrame.new(-1943.67651367, 251.50956726, -12337.88085937));
				end;
			end);
		end;
	end;
end);
NF.CreateToggle({
	Title = "Auto Soul Reaper [Fully]",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.AutoHytHallow = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		if _G.AutoHytHallow then
			pcall(function()
				local Y = GetConnectionEnemies("Soul Reaper");
				if Y then
					repeat
						task.wait();
						f.Kill(Y, _G.AutoHytHallow);
					until Y.Humanoid.Health <= 0 or _G.AutoHytHallow == false;
				else
					if not GetBP("Hallow Essence") then
						repeat
							task.wait(.1);
							Q.Remotes.CommF_:InvokeServer("Bones", "Buy", 1, 1);
						until _G.AutoHytHallow == false or GetBP("Hallow Essence");
					else
						repeat
							task.wait(.1);
							_tp(CFrame.new(-8932.32226562, 146.83154296, 6062.55078125));
						until _G.AutoHytHallow == false or d.Character.HumanoidRootPart.CFrame == CFrame.new(-8932.32226562, 146.83154296, 6062.55078125);
						EquipWeapon("Hallow Essence");
					end;
				end;
			end);
		end;
	end;
end);
NF.CreateToggle({
	Title = "Auto Random Bones",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.Auto_Random_Bone = Y;
	end,
});
local VoidGacha = { NextBones = 0, NextFruit = 0 }
local function VoidCloseGachaGui()
	local gui = plr:FindFirstChildOfClass("PlayerGui")
	if not gui then return end
	for _, object in ipairs(gui:GetDescendants()) do
		if object:IsA("GuiButton") and string.lower(object.Name) == "close" and object.Visible then
			pcall(function() object:Activate() end)
		end
	end
end
task.spawn(function()
	while task.wait(T) do
		pcall(function()
			if _G.Auto_Random_Bone and os.clock() >= VoidGacha.NextBones then
				VoidGacha.NextBones = os.clock() + 1.25
				Q.Remotes.CommF_:InvokeServer("Bones", "Buy", 1, 1);
				VoidCloseGachaGui()
			end;
		end);
	end;
end);
NF.CreateToggle({
	Title = "Auto Try Luck Gravestone",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.TryLucky = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		if _G.TryLucky then
			local Y = CFrame.new(-8761.31542968, 164.85829162, 6161.15673828);
			if d.Character.HumanoidRootPart.CFrame ~= Y then
				_tp(CFrame.new(-8761.31542968, 164.85829162, 6161.15673828));
			elseif d.Character.HumanoidRootPart.CFrame == Y then
				Q.Remotes.CommF_:InvokeServer("gravestoneEvent", 1);
			end;
		end;
	end;
end);
NF.CreateToggle({
	Title = "Auto Pray Gravestone",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.Praying = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		if _G.Praying then
			local Y = CFrame.new(-8761.31542968, 164.85829162, 6161.15673828);
			if d.Character.HumanoidRootPart.CFrame ~= Y then
				_tp(CFrame.new(-8761.31542968, 164.85829162, 6161.15673828));
			elseif d.Character.HumanoidRootPart.CFrame == Y then
				Q.Remotes.CommF_:InvokeServer("gravestoneEvent", 2);
			end;
		end;
	end;
end);
local uF = vz.CreateSection("Unlocked Dungeon");
uF.CreateToggle({
	Title = "Auto Unlock Dough Dungeon",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.Doughv2 = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		if _G.Doughv2 then
			pcall(function()
				local map = workspace:FindFirstChild("Map");
				local cakeLoaf = map and map:FindFirstChild("CakeLoaf");
				local redDoor = cakeLoaf and cakeLoaf:FindFirstChild("RedDoor");
				local redKey = GetBP("Red Key");
				if redDoor and redKey then
						repeat
							task.wait();
							_tp(CFrame.new(-2681.97998, 64.3921585, -12853.7363, .149007782, -1.87902192e-08, .98883605, 3.60619588e-08, 1, 1.35681812e-08, -0.98883605, 3.36376011e-08, .149007782));
						until not _G.Doughv2 or not d.Character or not d.Character:FindFirstChild("HumanoidRootPart") or (d.Character.HumanoidRootPart.Position - Vector3.new(-2681.97998, 64.3921585, -12853.7363)).Magnitude <= 5;
						EquipWeapon("Red Key");
				elseif GetConnectionEnemies("Dough King") then
					local Y = GetConnectionEnemies("Dough King");
					if Y then
						repeat
							task.wait();
							f.Kill(Y, _G.Doughv2);
						until not _G.Doughv2 or not Y.Parent or Y.Humanoid.Health <= 0;
					else
						_tp(CFrame.new(-1943.67651367, 251.50956726, -12337.88085937));
					end;
				elseif redKey then
					Q.Remotes.CommF_:InvokeServer("CakeScientist", "Check");
					Q.Remotes.CommF_:InvokeServer("RaidsNpc", "Check");
				end;
				if GetBP("Sweet Chalice") then
					Q.Remotes.CommF_:InvokeServer("CakePrinceSpawner", true);
					_G.AutoMiror = true;
				else
					_G.AutoMiror = false;
				end;
				if GetBP("God\'s Chalice") and GetM("Conjured Cocoa") >= 10 then
					Q.Remotes.CommF_:InvokeServer("SweetChaliceNpc");
				end;
				if not d.Backpack:FindFirstChild("God\'s Chalice") or d.Character:FindFirstChild("God\'s Chalice") then
					_G.FarmEliteHunt = true;
				else
					_G.FarmEliteHunt = false;
				end;
				if GetM("Conjured Cocoa") <= 10 then
					local Y = { "Cocoa Warrior", "Chocolate Bar Battler" };
					local d = GetConnectionEnemies(Y);
					if d then
						repeat
							task.wait();
							f.Kill(d, _G.Doughv2);
						until _G.Doughv2 == false or not d.Parent or d.Humanoid.Health <= 0;
					else
						_tp(CFrame.new(402.71890258, 81.06050109, -12259.54296875));
					end;
				end;
			end);
		end;
	end;
end);
uF.CreateToggle({
	Title = "Auto Unlock Phoenix Dungeon",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.AutoPhoenixF = Y;
	end,
});
task.spawn(function()
	while task.wait(.1) do
		if _G.AutoPhoenixF then
			pcall(function()
				if GetBP("Bird-Bird: Phoenix") then
					if d.Backpack:FindFirstChild(d.Data.DevilFruit.Value) then
						if (d.Backpack:FindFirstChild(d.Data.DevilFruit.Value)).Level.Value >= 400 then
							_tp(CFrame.new(-2812.76708984, 254.80346679, -12595.56054687));
							if ((CFrame.new(-2812.76708984, 254.80346679, -12595.56054687)).Position - d.Character.HumanoidRootPart.Position).Magnitude <= 10 then
								Q.Remotes.CommF_:InvokeServer("SickScientist", "Check");
								Q.Remotes.CommF_:InvokeServer("SickScientist", "Heal");
							end;
						end;
					elseif d.Character:FindFirstChild(d.Data.DevilFruit.Value) then
						if (d.Character:FindFirstChild(d.Data.DevilFruit.Value)).Level.Value >= 400 then
							_tp(CFrame.new(-2812.76708984, 254.80346679, -12595.56054687));
							if ((CFrame.new(-2812.76708984, 254.80346679, -12595.56054687)).Position - d.Character.HumanoidRootPart.Position).Magnitude <= 10 then
								Q.Remotes.CommF_:InvokeServer("SickScientist", "Check");
								Q.Remotes.CommF_:InvokeServer("SickScientist", "Heal");
							end;
						end;
					end;
				end;
			end);
		end;
	end;
end);
local gF = vz.CreateSection("Buso/Aura Colours");
gF.CreateToggle({
	Title = "Auto Teleport Barista Cousin",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.Tp_MasterA = Y;
	end,
});
task.spawn(function()
	while task.wait() do
		if _G.Tp_MasterA then
			pcall(function()
				for Y, d in pairs(Q.NPCs:GetChildren()) do
					if d.Name == "Barista Cousin" then
						_tp(d.HumanoidRootPart.CFrame);
					end;
				end;
			end);
		end;
	end;
end);
gF.CreateButton({ Title = "Buy Buso Colors", Callback = function()
		Q.Remotes.CommF_:InvokeServer("ColorsDealer", "2");
	end });
gF.CreateToggle({
	Title = "Auto Rainbow Colors",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.Auto_Rainbow_Haki = Y;
	end,
});
task.spawn(function()
	pcall(function()
		while task.wait(T) do
			if _G.Auto_Rainbow_Haki then
				if d.PlayerGui.Main.Quest.Visible == false then
					if _G.GetQFast then
						if d.PlayerGui.Main.Quest.Visible == false then
							Q.Remotes.CommF_:InvokeServer("HornedMan", "Bet");
						end;
					else
						Rainbow1 = CFrame.new(-11892.0703125, 930.57672119, -8760.15917968);
						if d.Character.HumanoidRootPart.CFrame ~= Rainbow1 then
							_tp(Rainbow1);
						elseif d.Character.HumanoidRootPart.CFrame == Rainbow1 then
							task.wait(1);
							Q.Remotes.CommF_:InvokeServer("HornedMan", "Bet");
						end;
					end;
				elseif d.PlayerGui.Main.Quest.Visible == true and string.find(d.PlayerGui.Main.Quest.Container.QuestTitle.Title.Text, "Stone") then
					local Y = GetConnectionEnemies("Stone");
					if Y then
						repeat
							task.wait();
							f.Kill(Y, _G.Auto_Rainbow_Haki);
						until _G.Auto_Rainbow_Haki == false or Y.Humanoid.Health <= 0 or not Y.Parent or d.PlayerGui.Main.Quest.Visible == false;
					else
						_tp(CFrame.new(-1086.11621, 38.8425903, 6768.71436, .0231462717, -0.59267669, .805107772, 2.03251839e-05, .805323839, .592835128, -0.99973207, -0.01370555, .0186523199));
					end;
				elseif d.PlayerGui.Main.Quest.Visible == true and string.find(d.PlayerGui.Main.Quest.Container.QuestTitle.Title.Text, "Hydra Leader") then
					local Y = GetConnectionEnemies("Hydra Leader");
					if Y then
						repeat
							task.wait();
							f.Kill(Y, _G.Auto_Rainbow_Haki);
						until _G.Auto_Rainbow_Haki == false or Y.Humanoid.Health <= 0 or not Y.Parent or d.PlayerGui.Main.Quest.Visible == false;
					else
						Q.Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(5643.45263671, 1013.08581542, -340.51025390));
						local Y = Vector3.new(5643.45263671, 1013.08581542, -340.51025390);
						local R = CFrame.new(5821.89794921, 1019.09509277, -73.71923065);
						if d.Character.HumanoidRootPart.CFrame.Position == Y then
							_tp(R);
						end;
					end;
				elseif d.PlayerGui.Main.Quest.Visible == true and string.find(d.PlayerGui.Main.Quest.Container.QuestTitle.Title.Text, "Kilo Admiral") then
					local Y = GetConnectionEnemies("Kilo Admiral");
					if Y then
						repeat
							task.wait();
							f.Kill(Y, _G.Auto_Rainbow_Haki);
						until _G.Auto_Rainbow_Haki == false or Y.Humanoid.Health <= 0 or not Y.Parent or d.PlayerGui.Main.Quest.Visible == false;
					else
						_tp(CFrame.new(2877.61743, 423.558685, -7207.31006, -0.98959159, 0, -0.14390490, 0, 1.00000012, 0, .143904924, 0, -0.98959147));
					end;
				elseif d.PlayerGui.Main.Quest.Visible == true and string.find(d.PlayerGui.Main.Quest.Container.QuestTitle.Title.Text, "Captain Elephant") then
					local Y = GetConnectionEnemies("Captain Elephant");
					if Y then
						repeat
							task.wait();
							f.Kill(Y, _G.Auto_Rainbow_Haki);
						until _G.Auto_Rainbow_Haki == false or Y.Humanoid.Health <= 0 or not Y.Parent or d.PlayerGui.Main.Quest.Visible == false;
					else
						local Y = Vector3.new(-12471.16992187, 374.94024658, -7551.67773437);
						local R = CFrame.new(-13376.7578125, 433.28689575, -8071.39257812);
						if d.Character.HumanoidRootPart.CFrame.Position ~= Y then
							Q.Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(-12471.16992187, 374.94024658, -7551.67773437));
						elseif d.Character.HumanoidRootPart.CFrame.Position == Y then
							_tp(R);
						end;
					end;
				elseif d.PlayerGui.Main.Quest.Visible == true and string.find(d.PlayerGui.Main.Quest.Container.QuestTitle.Title.Text, "Beautiful Pirate") then
					local Y = GetConnectionEnemies("Captain Elephant");
					if Y then
						repeat
							task.wait();
							f.Kill(Y, _G.Auto_Rainbow_Haki);
						until _G.Auto_Rainbow_Haki == false or Y.Humanoid.Health <= 0 or not Y.Parent or d.PlayerGui.Main.Quest.Visible == false;
					else
						Q.Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(5314.54638671, 22.56221961, -127.06755065));
					end;
				end;
			end;
		end;
	end);
end);
gF.CreateToggle({
	Title = "Accept Rainbow Quest Faster",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.GetQFast = Y;
	end,
});
local zF = vz.CreateSection("Instinct / Observation");
zF.CreateToggle({
	Title = "Auto Farm Observation",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.obsFarm = Y;
	end,
});
task.spawn(function()
	while task.wait(.2) do
		pcall(function()
			if _G.obsFarm then
				Q.Remotes.CommE:FireServer("Ken", true);
				if d:GetAttribute("KenDodgesLeft") == 0 then
					c = false;
				elseif d:GetAttribute("KenDodgesLeft") > 0 then
					Q.Remotes.CommE:FireServer("Ken", true);
					c = true;
				end;
			end;
		end);
	end;
end);
task.spawn(function()
	while task.wait(.2) do
		pcall(function()
			if _G.obsFarm then
				if World1 then
					if workspace.Enemies:FindFirstChild("Galley Captain") then
						if c then
							repeat
								task.wait();
								d.Character.HumanoidRootPart.CFrame = (workspace.Enemies:FindFirstChild("Galley Captain")).HumanoidRootPart.CFrame * CFrame.new(3, 0, 0);
							until _G.obsFarm == false or c == false;
						else
							repeat
								task.wait();
								d.Character.HumanoidRootPart.CFrame = (workspace.Enemies:FindFirstChild("Galley Captain")).HumanoidRootPart.CFrame * CFrame.new(0, 50, 0);
							until _G.obsFarm == false or c;
						end;
					else
						_tp(CFrame.new(5533.29785, 88.1079102, 4852.3916));
					end;
				elseif World2 then
					if workspace.Enemies:FindFirstChild("Lava Pirate") then
						if c then
							repeat
								task.wait();
								d.Character.HumanoidRootPart.CFrame = (workspace.Enemies:FindFirstChild("Lava Pirate")).HumanoidRootPart.CFrame * CFrame.new(3, 0, 0);
							until _G.obsFarm == false or c == false;
						else
							repeat
								task.wait();
								d.Character.HumanoidRootPart.CFrame = (workspace.Enemies:FindFirstChild("Lava Pirate")).HumanoidRootPart.CFrame * CFrame.new(0, 50, 0);
							until _G.obsFarm == false or c;
						end;
					else
						_tp(CFrame.new(-5478.39209, 15.9775667, -5246.9126));
					end;
				elseif World3 then
					if workspace.Enemies:FindFirstChild("Venomous Assailant") then
						if c then
							repeat
								task.wait();
								_tp((workspace.Enemies:FindFirstChild("Venomous Assailant")).HumanoidRootPart.CFrame * CFrame.new(3, 0, 0));
							until _G.obsFarm == false or c == false;
						else
							repeat
								task.wait();
								_tp((workspace.Enemies:FindFirstChild("Venomous Assailant")).HumanoidRootPart.CFrame * CFrame.new(0, 50, 0));
							until _G.obsFarm == false or c;
						end;
					else
						_tp(CFrame.new(4530.35400390, 656.75695800, -131.60952758));
					end;
				end;
			end;
		end);
	end;
end);
zF.CreateToggle({
	Title = "Auto Observation V2",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.AutoKenVTWO = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		if _G.AutoKenVTWO then
			pcall(function()
				local Y = CFrame.new(-12444.78515625, 332.40396118, -7673.18066406);
				local R = "Kuy";
				local r = CFrame.new(-10920.125, 624.20275878, -10266.99511718);
				local a = CFrame.new(-13277.56835937, 370.34185791, -7821.15722656);
				local w = CFrame.new(-13493.12890625, 318.89553833, -8373.79199218);
				if d.PlayerGui.Main.Quest.Visible == true and string.find(d.PlayerGui.Main.Quest.Container.QuestTitle.Title.Text, "Defeat 50 Forest Pirates") then
					local Y = GetConnectionEnemies("Forest Pirate");
					if Y then
						repeat
							task.wait();
							f.Kill(Y, _G.AutoKenVTWO);
						until not _G.AutoKenVTWO or Y.Humanoid.Health <= 0 or d.PlayerGui.Main.Quest.Visible == false;
					else
						_tp(a);
					end;
				elseif d.PlayerGui.Main.Quest.Visible == true then
					local Y = GetConnectionEnemies("Captain Elephant");
					if Y then
						repeat
							task.wait();
							f.Kill(Y, _G.AutoKenVTWO);
						until not _G.AutoKenVTWO or Y.Humanoid.Health <= 0 or d.PlayerGui.Main.Quest.Visible == false;
					else
						_tp(w);
					end;
				elseif d.PlayerGui.Main.Quest.Visible == false then
					Q.Remotes.CommF_:InvokeServer("CitizenQuestProgress", "Citizen");
					task.wait(.1);
					Q.Remotes.CommF_:InvokeServer("StartQuest", "CitizenQuest", 1);
				end;
				if Q.Remotes.CommF_:InvokeServer("CitizenQuestProgress", "Citizen") == 2 then
					_tp(CFrame.new(-12513.51953125, 340.11373901, -9873.04882812));
				end;
				if not d.Backpack:FindFirstChild("Fruit Bowl") or not d.Character:FindFirstChild("Fruit Bowl") then
					if not GetBP("Fruit Bowl") then
						if not GetBP("Apple") then
							Q.Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(-12471.16992187, 374.94024658, -7551.67773437));
							for Y, R in pairs(workspace:GetDescendants()) do
								if R.Name == "Apple" then
									R.Handle.CFrame = d.Character.HumanoidRootPart.CFrame * CFrame.new(0, 1, 10);
									task.wait();
									firetouchinterest(d.Character.HumanoidRootPart, R.Handle, 0);
									task.wait();
								end;
							end;
						elseif not GetBP("Banana") then
							_tp(CFrame.new(2286.0078125, 73.13391876, -7159.80908203));
							for Y, R in pairs(workspace:GetDescendants()) do
								if R.Name == "Banana" then
									R.Handle.CFrame = d.Character.HumanoidRootPart.CFrame * CFrame.new(0, 1, 10);
									task.wait();
									firetouchinterest(d.Character.HumanoidRootPart, R.Handle, 0);
									task.wait();
								end;
							end;
						elseif not GetBP("Pineapple") then
							_tp(CFrame.new(-712.82727050, 98.57704925, 5711.95410156));
							for Y, R in pairs(workspace:GetDescendants()) do
								if R.Name == "Pineapple" then
									R.Handle.CFrame = d.Character.HumanoidRootPart.CFrame * CFrame.new(0, 1, 10);
									task.wait();
									firetouchinterest(d.Character.HumanoidRootPart, R.Handle, 0);
									task.wait();
								end;
							end;
						end;
					end;
					if d.Backpack:FindFirstChild("Banana") and (d.Backpack:FindFirstChild("Apple") and d.Backpack:FindFirstChild("Pineapple")) or d:FindFirstChild("Banana") and (d:FindFirstChild("Apple") and d:FindFirstChild("Pineapple")) then
						repeat
							task.wait();
							_tp(Y);
						until _G.AutoKenVTWO or d.Character.HumanoidRootPart.CFrame == Y;
						Q.Remotes.CommF_:InvokeServer("CitizenQuestProgress", "Citizen");
					end;
					if d.Backpack:FindFirstChild("Fruit Bowl") or d.Character:FindFirstChild("Fruit Bowl") then
						if d.Character.HumanoidRootPart.CFrame ~= r then
							_tp(r);
						elseif d.Character.HumanoidRootPart.CFrame == r then
							Q.Remotes.CommF_:InvokeServer("KenTalk2", "Start");
							task.wait(.1);
							Q.Remotes.CommF_:InvokeServer("KenTalk2", "Buy");
						end;
					end;
				end;
			end);
		end;
	end;
end);
local iF = vz.CreateSection("Upgrade Races V3");
iF.CreateToggle({
	Title = "Auto Upgrade Mink V3",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.Auto_Mink = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		pcall(function()
			if _G.Auto_Mink then
				if Q.Remotes.CommF_:InvokeServer("Alchemist", "1") ~= 2 then
					if Q.Remotes.CommF_:InvokeServer("Alchemist", "1") == 0 then
						Q.Remotes.CommF_:InvokeServer("Alchemist", "2");
					elseif Q.Remotes.CommF_:InvokeServer("Alchemist", "1") == 1 then
						if not d.Backpack:FindFirstChild("Flower 1") and not d.Character:FindFirstChild("Flower 1") then
							_tp(workspace.Flower1.CFrame);
						elseif not d.Backpack:FindFirstChild("Flower 2") and not d.Character:FindFirstChild("Flower 2") then
							_tp(workspace.Flower2.CFrame);
						elseif not d.Backpack:FindFirstChild("Flower 3") and not d.Character:FindFirstChild("Flower 3") then
							local Y = GetConnectionEnemies("Swan Pirate");
							if Y then
								repeat
									task.wait();
									f.Kill(Y, _G.Auto_Mink);
								until GetBP("Flower 3") or not Y.Parent or Y.Humanoid.Health <= 0 or _G.Auto_Mink == false;
							else
								_tp(CFrame.new(980.09851074, 121.33129882, 1287.20935058));
							end;
						end;
					elseif Q.Remotes.CommF_:InvokeServer("Alchemist", "1") == 2 then
						Q.Remotes.CommF_:InvokeServer("Alchemist", "3");
					end;
				elseif Q.Remotes.CommF_:InvokeServer("Wenlocktoad", "1") == 0 then
					Q.Remotes.CommF_:InvokeServer("Wenlocktoad", "2");
				elseif Q.Remotes.CommF_:InvokeServer("Wenlocktoad", "1") == 1 then
					_G.AutoFarmChest = true;
				else
					_G.AutoFarmChest = false;
				end;
			end;
		end);
	end;
end);
iF.CreateToggle({
	Title = "Auto Upgrade Human V3",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.Auto_Human = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		pcall(function()
			if _G.Auto_Human then
				if Q.Remotes.CommF_:InvokeServer("Alchemist", "1") ~= -2 then
					if Q.Remotes.CommF_:InvokeServer("Alchemist", "1") == 0 then
						Q.Remotes.CommF_:InvokeServer("Alchemist", "2");
					elseif Q.Remotes.CommF_:InvokeServer("Alchemist", "1") == 1 then
						if not d.Backpack:FindFirstChild("Flower 1") and not d.Character:FindFirstChild("Flower 1") then
							_tp(workspace.Flower1.CFrame);
						elseif not d.Backpack:FindFirstChild("Flower 2") and not d.Character:FindFirstChild("Flower 2") then
							_tp(workspace.Flower2.CFrame);
						elseif not d.Backpack:FindFirstChild("Flower 3") and not d.Character:FindFirstChild("Flower 3") then
							local Y = GetConnectionEnemies("Swan Pirate");
							if Y then
								repeat
									task.wait();
									f.Kill(Y, _G.Auto_Human);
								until d.Backpack:FindFirstChild("Flower 3") or not Y.Parent or Y.Humanoid.Health <= 0 or _G.Auto_Human == false;
							else
								_tp(CFrame.new(980.09851074, 121.33129882, 1287.20935058));
							end;
						end;
					elseif Q.Remotes.CommF_:InvokeServer("Alchemist", "1") == 2 then
						Q.Remotes.CommF_:InvokeServer("Alchemist", "3");
					end;
				elseif Q.Remotes.CommF_:InvokeServer("Wenlocktoad", "1") == 0 then
					Q.Remotes.CommF_:InvokeServer("Wenlocktoad", "2");
				elseif Q.Remotes.CommF_:InvokeServer("Wenlocktoad", "1") == 1 then
					local Y = GetConnectionEnemies(B[1]);
					if Y then
						repeat
							task.wait();
							f.Kill(Y, _G.Auto_Human);
						until Y.Humanoid.Health <= 0 or not Y.Parent or not _G.Auto_Human;
					else
						_tp(CFrame.new(-2172.73999023, 103.32216644, -4015.02539062));
					end;
					local d = GetConnectionEnemies(B[2]);
					if d then
						repeat
							task.wait();
							f.Kill(d, _G.Auto_Human);
						until d.Humanoid.Health <= 0 or not d.Parent or not _G.Auto_Human;
					else
						_tp(CFrame.new(2006.92614746, 448.95666503, 853.98284912));
					end;
					local R = GetConnectionEnemies(B[3]);
					if R then
						repeat
							task.wait();
							f.Kill(R, _G.Auto_Human);
						until R.Humanoid.Health <= 0 or not R.Parent or not _G.Auto_Human;
					else
						_tp(CFrame.new(-1576.71667480, 198.59265136, 13.72428607));
					end;
				end;
			end;
		end);
	end;
end);
iF.CreateToggle({
	Title = "Auto Upgrade Skypiea V3",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.Auto_Skypiea = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		pcall(function()
			if _G.Auto_Skypiea then
				if Q.Remotes.CommF_:InvokeServer("Alchemist", "1") ~= -2 then
					if Q.Remotes.CommF_:InvokeServer("Alchemist", "1") == 0 then
						Q.Remotes.CommF_:InvokeServer("Alchemist", "2");
					elseif Q.Remotes.CommF_:InvokeServer("Alchemist", "1") == 1 then
						if not d.Backpack:FindFirstChild("Flower 1") and not d.Character:FindFirstChild("Flower 1") then
							_tp(workspace.Flower1.CFrame);
						elseif not d.Backpack:FindFirstChild("Flower 2") and not d.Character:FindFirstChild("Flower 2") then
							_tp(workspace.Flower2.CFrame);
						elseif not d.Backpack:FindFirstChild("Flower 3") and not d.Character:FindFirstChild("Flower 3") then
							local Y = GetConnectionEnemies("Swan Pirate");
							if Y then
								repeat
									task.wait();
									f.Kill(Y, _G.Auto_Skypiea);
								until d.Backpack:FindFirstChild("Flower 3") or not Y.Parent or Y.Humanoid.Health <= 0 or _G.Auto_Skypiea == false;
							else
								_tp(CFrame.new(980.09851074, 121.33129882, 1287.20935058));
							end;
						end;
					elseif Q.Remotes.CommF_:InvokeServer("Alchemist", "1") == 2 then
						Q.Remotes.CommF_:InvokeServer("Alchemist", "3");
					end;
				elseif Q.Remotes.CommF_:InvokeServer("Wenlocktoad", "1") == 0 then
					Q.Remotes.CommF_:InvokeServer("Wenlocktoad", "2");
				elseif Q.Remotes.CommF_:InvokeServer("Wenlocktoad", "1") == 1 then
					for Y, R in pairs(game.Players:GetChildren()) do
						if R.Name ~= d.Name and tostring(R.Data.Race.Value) == "Skypiea" then
							repeat
								task.wait();
								_tp((R.HumanoidRootPart.CFrame * CFrame.new(0, 8, 0)) * CFrame.Angles(math.rad(-45), 0, 0));
							until R.Humanoid.Health <= 0 or _G.Auto_Skypiea == false;
						end;
					end;
				end;
			end;
		end);
	end;
end);
iF.CreateToggle({
	Title = "Auto Upgrade FishMan V3",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.Auto_Fish = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		pcall(function()
			if _G.Auto_Fish then
				if Q.Remotes.CommF_:InvokeServer("Alchemist", "1") ~= -2 then
					if Q.Remotes.CommF_:InvokeServer("Alchemist", "1") == 0 then
						Q.Remotes.CommF_:InvokeServer("Alchemist", "2");
					elseif Q.Remotes.CommF_:InvokeServer("Alchemist", "1") == 1 then
						if not d.Backpack:FindFirstChild("Flower 1") and not d.Character:FindFirstChild("Flower 1") then
							_tp(workspace.Flower1.CFrame);
						elseif not d.Backpack:FindFirstChild("Flower 2") and not d.Character:FindFirstChild("Flower 2") then
							_tp(workspace.Flower2.CFrame);
						elseif not d.Backpack:FindFirstChild("Flower 3") and not d.Character:FindFirstChild("Flower 3") then
							local Y = GetConnectionEnemies("Swan Pirate");
							if Y then
								repeat
									task.wait();
									f.Kill(Y, _G.Auto_Fish);
								until d.Backpack:FindFirstChild("Flower 3") or not Y.Parent or Y.Humanoid.Health <= 0 or _G.Auto_Fish == false;
							else
								_tp(CFrame.new(980.09851074, 121.33129882, 1287.20935058));
							end;
						end;
					elseif Q.Remotes.CommF_:InvokeServer("Alchemist", "1") == 2 then
						Q.Remotes.CommF_:InvokeServer("Alchemist", "3");
					end;
				elseif Q.Remotes.CommF_:InvokeServer("Wenlocktoad", "1") == 0 then
					Q.Remotes.CommF_:InvokeServer("Wenlocktoad", "2");
				elseif Q.Remotes.CommF_:InvokeServer("Wenlocktoad", "1") == 1 then
					warn("Sea Beast Soon");
				end;
			end;
		end);
	end;
end);
local UF = vz.CreateSection("Dark Dragger + Valkyrie");
UF.CreateToggle({
	Title = "Auto Valkyrie",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.AutoRipIngay = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		pcall(function()
			if _G.AutoRipIngay then
				local Y = GetConnectionEnemies("rip_indra");
				if not GetWP("Dark Dagger") or not GetIn("Valkyrie") and Y then
					repeat
						task.wait();
						f.Kill(Y, _G.AutoRipIngay);
					until not _G.AutoRipIngay or not Y.Parent or Y.Humanoid.Health <= 0;
				else
					Q.Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(-5097.93164, 316.447021, -3142.66602, -0.40500789, -4.31682743e-08, .914313197, -1.90943332e-08, 1, 3.8755779e-08, -0.91431319, -1.76180437e-09, -0.40500789));
					task.wait(.1);
					_tp(CFrame.new(-5344.82226562, 423.98541259, -2725.09301757));
				end;
			end;
		end);
	end;
end);
UF.CreateToggle({
	Title = "Auto Unlocked Puzzle",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.AutoUnHaki = Y;
	end,
});
AuraSkin = function(Y)
		local d = { [1] = { StorageName = Y, Type = "AuraSkin", Context = "Equip" } };
		(((Q:WaitForChild("Modules")):WaitForChild("Net")):WaitForChild("RF/FruitCustomizerRF")):InvokeServer(unpack(d));
	end;
VaildColor = function(Y)
		if Y and Y.BrickColor then
			return tostring(Y.BrickColor) == "Lime green";
		end;
	end;
HakiCalculate = function(Y)
		local d = { ["Really red"] = "Pure Red", Oyster = "Snow White", ["Hot pink"] = "Winter Sky" };
		if Y and Y.BrickColor then
			return d[tostring(Y.BrickColor)];
		end;
	end;
task.spawn(function()
	while task.wait(T) do
		if _G.AutoUnHaki then
			pcall(function()
				local Y = workspace.Map["Boat Castle"]:FindFirstChild("Summoner");
				if Y and Y:FindFirstChild("Circle") then
					for Y, d in pairs((Y:FindFirstChild("Circle")):GetChildren()) do
						if d.Name == "Part" then
							local Y = d:FindFirstChild("Part");
							if VaildColor(Y) == false then
								AuraSkin(HakiCalculate(d));
								repeat
									task.wait();
									_tp(d.CFrame);
								until VaildColor(Y) == true or not _G.AutoUnHaki;
							end;
						end;
					end;
				end;
			end);
		end;
	end;
end);
local CF = mz.CreateSection("Settings / Configure");
CF.CreateDropdown({
	Title = "Select Weapon",
	Description = "",
	Values = {
		"Melee",
		"Sword",
		"Blox Fruit",
		"Gun",
	},
	Default = "Melee",
	Multi = false,
	Callback = function(Y)
		if _G.ChooseWP ~= nil then
			_G.ChooseWP_UserSet = true;
		end;
		_G.ChooseWP = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		pcall(function()
			if _G.ChooseWP == "Melee" then
				for Y, R in pairs(d.Backpack:GetChildren()) do
					if R.ToolTip == "Melee" then
						if d.Backpack:FindFirstChild(tostring(R.Name)) then
							_G.SelectWeapon = R.Name;
						end;
					end;
				end;
			elseif _G.ChooseWP == "Sword" then
				for Y, R in pairs(d.Backpack:GetChildren()) do
					if R.ToolTip == "Sword" then
						if d.Backpack:FindFirstChild(tostring(R.Name)) then
							_G.SelectWeapon = R.Name;
						end;
					end;
				end;
			elseif _G.ChooseWP == "Gun" then
				for Y, R in pairs(d.Backpack:GetChildren()) do
					if R.ToolTip == "Gun" then
						if d.Backpack:FindFirstChild(tostring(R.Name)) then
							_G.SelectWeapon = R.Name;
						end;
					end;
				end;
			elseif _G.ChooseWP == "Blox Fruit" then
				for Y, R in pairs(d.Backpack:GetChildren()) do
					if R.ToolTip == "Blox Fruit" then
						if d.Backpack:FindFirstChild(tostring(R.Name)) then
							_G.SelectWeapon = R.Name;
						end;
					end;
				end;
			end;
		end);
	end;
end);
CF.CreateToggle({
	Title = "Initialize Attack [M1/Melee/Sword]",
	Description = "[ Not Supported Gas M1 ]",
	Default = true,
	Callback = function(Y)
		_G.Seriality = Y;
	end,
});
CF.CreateSlider({
	Title = "Tween Speed",
	Description = "Control the speed of tween teleportation",
	Min = 50,
	Max = 900,
	Default = 180,
	Increment = 10,
}, function(Y)
	getgenv().TweenSpeedFar = Y;
	getgenv().TweenSpeedNear = Y;
end);
CF.CreateSlider({
	Title = "Boat Speed",
	Description = "Maximum speed for your current boat",
	Min = 50,
	Max = 1000,
	Default = 350,
	Increment = 10,
}, function(Y)
	getgenv().BFBoatSpeed = tonumber(Y) or 350;
end);
task.spawn(function()
	while task.wait(.25) do
		local boats = workspace:FindFirstChild("Boats");
		local humanoid = d.Character and d.Character:FindFirstChildOfClass("Humanoid");
		local occupiedSeat = humanoid and humanoid.SeatPart;
		local boat;
		if occupiedSeat and boats and occupiedSeat:IsDescendantOf(boats) then
			local node = occupiedSeat;
			while node.Parent and node.Parent ~= boats do node = node.Parent; end;
			if node.Parent == boats then boat = node; end;
		end;
		if not boat and boats then
			local ok, owned = pcall(CheckBoat);
			if ok then boat = owned; end;
		end;
		local seat = boat and boat:FindFirstChild("VehicleSeat", true);
		if seat and seat:IsA("VehicleSeat") then
			seat.MaxSpeed = math.clamp(tonumber(getgenv().BFBoatSpeed) or 350, 50, 1000);
		end;
	end;
end);
CF.CreateToggle({
	Title = "Bring Mobs",
	Description = "",
	Default = true,
	Callback = function(Y)
		_B = Y;
	end,
});
CF.CreateToggle({
	Title = "Auto Turn on Buso",
	Description = "",
	Default = true,
	Callback = function(Y)
		Boud = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		pcall(function()
			if Boud then
				local Y = { "HasBuso", "Buso" };
				if not d.Character:FindFirstChild(Y[1]) then
					Q.Remotes.CommF_:InvokeServer(Y[2]);
				end;
			end;
		end);
	end;
end);
CF.CreateToggle({
	Title = "Auto Turn on Race V3",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.RaceClickAutov3 = Y;
	end,
});
CF.CreateToggle({
	Title = "Auto Turn on Race V4",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.RaceClickAutov4 = Y;
	end,
});
task.spawn(function()
	while task.wait(.2) do
		pcall(function()
			if _G.RaceClickAutov3 then
				repeat
					Q.Remotes.CommE:FireServer("ActivateAbility");
					task.wait(30);
				until not _G.RaceClickAutov3;
			end;
		end);
	end;
end);
task.spawn(function()
	while task.wait(.2) do
		pcall(function()
			if _G.RaceClickAutov4 then
				if d.Character:FindFirstChild("RaceEnergy") then
					if (d.Character:FindFirstChild("RaceEnergy")).Value == 1 then
						Useskills("nil", "Y");
					end;
				end;
			end;
		end);
	end;
end);
CF.CreateToggle({
	Title = "Auto Turn on Spin Position",
	Description = "",
	Default = false,
	Callback = function(Y)
		RandomCFrame = Y;
	end,
});
CF.CreateToggle({
	Title = "Turn on Bypass Teleport",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.Bypass = Y;
	end,
});
CF.CreateToggle({
	Title = "Panic Mode",
	Description = "turn on for safe ur health if low",
	Default = false,
	Callback = function(Y)
		_G.Safemode = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		pcall(function()
			if _G.Safemode then
				local Y = (d.Character.Humanoid.Health / d.Character.Humanoid.MaxHealth) * 100;
				if Y < P then
					shouldTween = true;
					_tp(R.CFrame * CFrame.new(0, 500, 0));
				else
					shouldTween = false;
				end;
			end;
		end);
	end;
end);
CF.CreateToggle({
	Title = "Anti AFK",
	Description = "",
	Default = true,
	Callback = function(Y)
		_G.AntiAFK = Y;
	end,
});
d.Idled:connect(function()
	if not _G.AntiAFK then return end;
	n:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame);
	task.wait(1);
	n:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame);
end);
CF.CreateToggle({
	Title = "Remove Hit VFX",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.DistroyHit = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		if _G.DistroyHit then
			pcall(function()
				local Y = {
						"SlashHit",
						"CurvedRing",
						"SwordSlash",
						"SlashTail",
					};
				for Y, d in pairs(workspace._WorldOrigin:GetChildren()) do
					if table.find(__Effect, d.Name) then
						d:Destroy();
					end;
				end;
			end);
		end;
	end;
end);
CF.CreateToggle({
	Title = "Remove Death & Respawned VFX",
	Description = "",
	Default = false,
	Callback = function(Y)
		RDeath = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		pcall(function()
			if RDeath then
				if Q.Effect.Container:FindFirstChild("Death") then
					Q.Effect.Container.Death:Destroy();
				end;
				if Q.Effect.Container:FindFirstChild("Respawn") then
					Q.Effect.Container.Respawn:Destroy();
				end;
			end;
		end);
	end;
end);
CF.CreateToggle({
	Title = "Disable Notify",
	Description = "",
	Default = false,
	Callback = function(Y)
		RemoveDamage = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		pcall(function()
			if RemoveDamage then
				Q.Assets.GUI.DamageCounter.Enabled = false;
				d.PlayerGui.Notifications.Enabled = false;
			else
				Q.Assets.GUI.DamageCounter.Enabled = true;
				d.PlayerGui.Notifications.Enabled = true;
			end;
		end);
	end;
end);
local vF = mz.CreateSection("Stats Upgrade");
vF.CreateSlider({
	Title = "Stats Value",
	Min = 0,
	Max = 1000,
	Default = 10,
	Precise = true,
}, function(Y)
	pSats = Y;
end);
vF.CreateToggle({
	Title = "Auto Melee",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.Auto_Melee = Y;
	end,
});
vF.CreateToggle({
	Title = "Auto Swords",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.Auto_Sword = Y;
	end,
});
vF.CreateToggle({
	Title = "Auto Gun",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.Auto_Gun = Y;
	end,
});
vF.CreateToggle({
	Title = "Auto Blox Fruit",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.Auto_DevilFruit = Y;
	end,
});
vF.CreateToggle({
	Title = "Auto Defense",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.Auto_Defense = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		pcall(function()
			if _G.Auto_Melee then
				statsSetings("Melee", pSats);
			end;
		end);
	end;
end);
task.spawn(function()
	while task.wait(T) do
		pcall(function()
			if _G.Auto_Sword then
				statsSetings("Sword", pSats);
			end;
		end);
	end;
end);
task.spawn(function()
	while task.wait(T) do
		pcall(function()
			if _G.Auto_Gun then
				statsSetings("Gun", pSats);
			end;
		end);
	end;
end);
task.spawn(function()
	while task.wait(T) do
		pcall(function()
			if _G.Auto_DevilFruit then
				statsSetings("Devil", pSats);
			end;
		end);
	end;
end);
task.spawn(function()
	while task.wait(T) do
		pcall(function()
			if _G.Auto_Defense then
				statsSetings("Defense", pSats);
			end;
		end);
	end;
end);
local mF = yz.CreateSection("Fighting Melee Styles");
mF.CreateToggle({
	Title = "Auto Superhuman",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.Auto_SuperHuman = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		pcall(function()
			if _G.Auto_SuperHuman then
				local Y = d.Data.Beli.Value;
				local R = d.Data.Fragments.Value;
				if d:FindFirstChild("WeaponAssetCache") then
					if not GetBP("Superhuman") then
						if not GetBP("Black Leg") then
							if Y >= 150000 then
								Q.Remotes.CommF_:InvokeServer("BuyBlackLeg");
							end;
						elseif GetBP("Black Leg") and (GetBP("Black Leg")).Level.Value < 299 then
							_G.Level = true;
						elseif GetBP("Black Leg") and (GetBP("Black Leg")).Level.Value >= 300 then
							_G.Level = false;
						end;
						if not GetBP("Electro") then
							if Y >= 500000 then
								Q.Remotes.CommF_:InvokeServer("BuyElectro");
							end;
						elseif GetBP("Electro") and (GetBP("Electro")).Level.Value < 299 then
							_G.Level = true;
						elseif GetBP("Electro") and (GetBP("Electro")).Level.Value >= 300 then
							_G.Level = false;
						end;
						if not GetBP("Fishman Karate") then
							if Y >= 750000 then
								Q.Remotes.CommF_:InvokeServer("BuyFishmanKarate");
							end;
						elseif GetBP("Fishman Karate") and (GetBP("Fishman Karate")).Level.Value < 299 then
							_G.Level = true;
						elseif GetBP("Fishman Karate") and (GetBP("Fishman Karate")).Level.Value >= 300 then
							_G.Level = false;
						end;
						if not GetBP("Dragon Claw") then
							if R >= 1500 then
								Q.Remotes.CommF_:InvokeServer("BlackbeardReward", "DragonClaw", "2");
							end;
						elseif GetBP("Dragon Claw") and (GetBP("Dragon Claw")).Level.Value < 299 then
							_G.Level = true;
						elseif GetBP("Dragon Claw") and (GetBP("Dragon Claw")).Level.Value >= 300 then
							_G.Level = false;
						end;
						TweenToStyleDealer({"Superhuman"});
						Q.Remotes.CommF_:InvokeServer("BuySuperhuman");
					end;
				end;
			end;
		end);
	end;
end);
mF.CreateToggle({
	Title = "Auto DeathStep",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.AutoDeathStep = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		if _G.AutoDeathStep then
			pcall(function()
				if d:FindFirstChild("WeaponAssetCache") then
					if not GetBP("Death Step") then
						if not GetBP("Black Leg") then
							Q.Remotes.CommF_:InvokeServer("BuyBlackLeg");
						end;
						if GetBP("Black Leg") and (GetBP("Black Leg")).Level.Value >= 400 then
							TweenToStyleDealer({"Death Step"});
							Q.Remotes.CommF_:InvokeServer("BuyDeathStep");
							_G.Level = false;
						elseif GetBP("Black Leg") and (GetBP("Black Leg")).Level.Value < 399 then
							_G.Level = true;
						end;
						if GetBP("Black Leg") or (GetBP("Black Leg")).Level.Value >= 400 then
							if workspace.Map.IceCastle.Hall.LibraryDoor.PhoeyuDoor.Transparency == 0 then
								if GetBP("Library Key") then
									repeat
										task.wait();
										_tp(CFrame.new(6371.20019531, 296.63433837, -6841.18115234));
									until not _G.AutoDeathStep or R.Position == (CFrame.new(6371.20019531, 296.63433837, -6841.18115234)).Position;
									if R.CFrame == CFrame.new(6371.20019531, 296.63433837, -6841.18115234) then
										Q.Remotes.CommF_:InvokeServer("BuyDeathStep");
									end;
								elseif not GetBP("Library Key") then
									local Y = GetConnectionEnemies("Awakened Ice Admiral");
									if Y then
										repeat
											task.wait();
											f.Kill(Y, _G.AutoDeathStep);
										until not Y.Parent or Y.Humanoid.Health <= 0 or _G.AutoDeathStep == false or GetBP("Library Key") or GetBP("Death Step");
									else
										_tp(CFrame.new(5668.97802734, 28.51998901, -6483.35205078));
									end;
								end;
							end;
						end;
					end;
				end;
			end);
		end;
	end;
end);
mF.CreateToggle({
	Title = "Auto Sharkman Karate",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.Auto_SharkMan_Karate = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		if _G.Auto_SharkMan_Karate then
			pcall(function()
				if d:FindFirstChild("WeaponAssetCache") then
					if not GetBP("Sharkman Karate") then
						if not GetBP("Fishman Karate") then
							Q.Remotes.CommF_:InvokeServer("BuyFishmanKarate");
						end;
						if GetBP("Fishman Karate") and (GetBP("Fishman Karate")).Level.Value >= 400 then
							TweenToStyleDealer({"Sharkman Karate", "Sharkman"});
							Q.Remotes.CommF_:InvokeServer("BuySharkmanKarate");
							_G.Level = false;
						elseif GetBP("Fishman Karate") and (GetBP("Fishman Karate")).Level.Value < 399 then
							_G.Level = true;
						end;
						if GetBP("Fishman Karate") or (GetBP("Fishman Karate")).Level.Value >= 400 then
							if GetBP("Water Key") then
								if string.find(Q.Remotes.CommF_:InvokeServer("BuySharkmanKarate"), "keys") then
									if GetBP("Water Key") then
										repeat
											task.wait();
											_tp(CFrame.new(-2604.6958, 239.432526, -10315.1982, .0425701365, 0, -0.99909341, 0, 1, 0, .999093413, 0, .0425701365));
										until not _G.Auto_SharkMan_Karate or R.Position == (CFrame.new(-2604.6958, 239.432526, -10315.1982, .0425701365, 0, -0.99909341, 0, 1, 0, .999093413, 0, .0425701365)).Position;
										Q.Remotes.CommF_:InvokeServer("BuySharkmanKarate");
									end;
								end;
							elseif not GetBP("Water Key") then
								local Y = GetConnectionEnemies("Tide Keeper");
								if Y then
									repeat
										task.wait();
										f.Kill(Y, _G.Auto_SharkMan_Karate);
									until not Y.Parent or Y.Humanoid.Health <= 0 or _G.Auto_SharkMan_Karate == false or GetBP("Water Key") or GetBP("Sharkman Karate");
								else
									_tp(CFrame.new(-3053.98144531, 237.18954467, -10145.0390625));
								end;
							end;
						end;
					end;
				end;
			end);
		end;
	end;
end);
mF.CreateToggle({
	Title = "Auto ElectricClaw",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.Auto_Electric_Claw = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		if _G.Auto_Electric_Claw then
			pcall(function()
				if d:FindFirstChild("WeaponAssetCache") then
					if not GetBP("Electro") then
						Q.Remotes.CommF_:InvokeServer("BuyElectro");
					end;
					if GetBP("Electro") and (GetBP("Electro")).Level.Value >= 400 then
						TweenToStyleDealer({"Electric Claw", "Electricity"});
						Q.Remotes.CommF_:InvokeServer("BuyElectricClaw", "Start");
						Q.Remotes.CommF_:InvokeServer("BuyElectricClaw");
					elseif GetBP("Electro") and (GetBP("Electro")).Level.Value < 400 then
						repeat
							_G.AutoFarm_Bone = true;
							task.wait();
						until not _G.Auto_Electric_Claw or GetBP("Electric Claw");
						_G.AutoFarm_Bone = false;
					end;
				end;
			end);
		end;
	end;
end);
mF.CreateToggle({
	Title = "Auto DragonTalon",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.AutoDragonTalon = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		if _G.AutoDragonTalon then
			pcall(function()
				if d:FindFirstChild("WeaponAssetCache") then
					if not GetBP("Dragon Claw") then
						Q.Remotes.CommF_:InvokeServer("BlackbeardReward", "DragonClaw", "2");
					end;
					if GetBP("Dragon Claw") and (GetBP("Dragon Claw")).Level.Value >= 400 then
						Q.Remotes.CommF_:InvokeServer("Bones", "Buy", 1, 1);
						TweenToStyleDealer({"Dragon Talon", "Longma"});
						Q.Remotes.CommF_:InvokeServer("BuyDragonTalon");
					elseif GetBP("Dragon Claw") and (GetBP("Dragon Claw")).Level.Value < 400 then
						repeat
							_G.AutoFarm_Bone = true;
							task.wait();
						until not _G.AutoDragonTalon or GetBP("Dragon Talon");
						_G.AutoFarm_Bone = false;
					end;
				end;
			end);
		end;
	end;
end);
mF.CreateToggle({
	Title = "Auto Godhuman",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.Auto_God_Human = Y;
	end,
});
task.spawn(function()
	while task.wait() do
		pcall(function()
			if _G.Auto_God_Human then
				if Q.Remotes.CommF_:InvokeServer("BuyGodhuman", true) == "Bring me 20 Fish Tails, 20 Magma Ore, 10 Dragon Scales and 10 Mystic Droplets." then
					if GetM("Dragon Scale") == false or GetM("Dragon Scale") < 10 then
						if World3 then
							r = 1575;
							_G.Level = true;
						else
							Q.Remotes.CommF_:InvokeServer("TravelZou");
						end;
					elseif GetM("Fish Tail") == false or GetM("Fish Tail") < 20 then
						if World3 then
							r = 1775;
							_G.Level = true;
						else
							Q.Remotes.CommF_:InvokeServer("TravelZou");
						end;
					elseif GetM("Mystic Droplet") == false or GetM("Mystic Droplet") < 10 then
						if World2 then
							r = 1425;
							_G.Level = true;
						else
							Q.Remotes.CommF_:InvokeServer("TravelDressrosa");
						end;
					elseif GetM("Magma Ore") == false or GetM("Magma Ore") < 20 then
						if World2 then
							r = 1175;
							_G.Level = true;
						else
							Q.Remotes.CommF_:InvokeServer("TravelDressrosa");
						end;
					end;
				elseif Q.Remotes.CommF_:InvokeServer("BuyGodhuman", true) == 3 then
					return nil;
				else
					TweenToStyleDealer({"Strongest", "Godhuman", "God Human"});
					Q.Remotes.CommF_:InvokeServer("BuyGodhuman");
				end;
			end;
		end);
	end;
end);
mF.CreateToggle({
	Title = "Auto SanguineArt",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.snaguine = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		if _G.snaguine then
			pcall(function()
				if not GetBP("Sanguine Art") then
					TweenToStyleDealer({"Sanguine"});
					Q.Remotes.CommF_:InvokeServer("Sanguine Art");
				end;
				if not GetBP("Sanguine Art") then
					if GetM("Leviathan Heart") >= 1 then
						print("Completed!!");
					else
						if World3 then
							_G.DangerSc = "Lv Infinite";
							_G.SailBoats = true;
						else
							_G.SailBoats = false;
						end;
					end;
					if GetM("Vampire Fang") <= 19 then
						if World2 then
							local Y = GetConnectionEnemies("Vampire");
							if Y then
								repeat
									task.wait();
									f.Kill(Y, _G.snaguine);
								until not _G.snaguine or Y.Humanoid.Health <= 0 or not Y.Parent;
							else
								_tp(CFrame.new(-6041.29248046, 6.40271091, -1304.63330078));
							end;
						else
							Q.Remotes.CommF_:InvokeServer("TravelDressrosa");
						end;
					end;
					if GetM("Vampire Fang") >= 20 and GetM("Demonic Wisp") <= 19 then
						if World3 then
							local Y = GetConnectionEnemies("Demonic Soul");
							if Y then
								repeat
									task.wait();
									f.Kill(Y, _G.snaguine);
								until not _G.snaguine or Y.Humanoid.Health <= 0 or not Y.Parent;
							else
								_tp(CFrame.new(-9495.68066406, 453.58624267, 5977.34863281));
							end;
						else
							Q.Remotes.CommF_:InvokeServer("TravelZou");
						end;
					end;
					if GetM("Vampire Fang") >= 20 and (GetM("Demonic Wisp") >= 20 and GetM("Dark Fragment") <= 1) then
						if World2 then
							local Y = GetConnectionEnemies("Darkbeard");
							if Y then
								repeat
									task.wait();
									f.Kill(Y, _G.snaguine);
								until not _G.snaguine or Y.Humanoid.Health <= 0 or not Y.Parent;
							else
								_tp(CFrame.new(3798.45751953, 13.82669067, -3399.80664062));
							end;
						else
							Q.Remotes.CommF_:InvokeServer("TravelDressrosa");
						end;
					end;
				else
					Q.Remotes.CommF_:InvokeServer("BuySanguineArt");
				end;
			end);
		end;
	end;
end);
local yF = bz.CreateSection("Tushita + Yama");
local bF = yF.CreateLabel({ Title = "Elites Process ", Content = "" });
task.spawn(function()
	while task.wait(T) do
		pcall(function()
			bF:SetDesc("Elite Procress :  " .. Q.Remotes.CommF_:InvokeServer("EliteHunter", "Progress"));
		end);
	end;
end);
yF.CreateToggle({
	Title = "Auto Elite Quest",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.FarmEliteHunt = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		pcall(function()
			if _G.FarmEliteHunt then
				if d.PlayerGui.Main.Quest.Visible == true then
					if string.find(d.PlayerGui.Main.Quest.Container.QuestTitle.Title.Text, "Diablo") or string.find(d.PlayerGui.Main.Quest.Container.QuestTitle.Title.Text, "Urban") or string.find(d.PlayerGui.Main.Quest.Container.QuestTitle.Title.Text, "Deandre") then
						for Y, d in pairs(Q:GetChildren()) do
							if string.find(d.Name, "Diablo") or string.find(d.Name, "Urban") or string.find(d.Name, "Deandre") then
								_tp(d.HumanoidRootPart.CFrame);
							end;
						end;
						for Y, R in pairs(M:GetChildren()) do
							if (string.find(R.Name, "Diablo") or string.find(R.Name, "Urban") or string.find(R.Name, "Deandre")) and f.Alive(R) then
								repeat
									task.wait();
									f.Kill(R, _G.FarmEliteHunt);
								until not _G.FarmEliteHunt or d.PlayerGui.Main.Quest.Visible == false or not R.Parent or R.Humanoid.Health <= 0;
							end;
						end;
					end;
				else
					Q.Remotes.CommF_:InvokeServer("EliteHunter");
				end;
			end;
		end);
	end;
end);
yF.CreateToggle({
	Title = "Stop when got God\'s Chalice",
	Description = "",
	Default = true,
	Callback = function(Y)
		_G.StopWhenChalice = Y;
	end,
});
task.spawn(function()
	while task.wait(.2) do
		if _G.StopWhenChalice and _G.FarmEliteHunt then
			pcall(function()
				if GetBP("God\'s Chalice") or GetBP("Sweet Chalice") or GetBP("Fist of Darkness") then
					_G.FarmEliteHunt = false;
				end;
			end);
		end;
	end;
end);
yF.CreateToggle({
	Title = "Auto Tushita Sword",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.Auto_Tushita = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		pcall(function()
			if _G.Auto_Tushita then
				if workspace.Map.Turtle:FindFirstChild("TushitaGate") then
					if not GetBP("Holy Torch") then
						_tp(CFrame.new(5148.03613, 162.352493, 910.548218));
						task.wait(.7);
					else
						EquipWeapon("Holy Torch");
						task.wait(1);
						repeat
							task.wait();
							_tp(CFrame.new(-10752, 417, -9366));
						until not _G.Auto_Tushita or ((CFrame.new(-10752, 417, -9366)).Position - d.Character.HumanoidRootPart.Position).Magnitude <= 10;
						task.wait(.7);
						repeat
							task.wait();
							_tp(CFrame.new(-11672, 334, -9474));
						until not _G.Auto_Tushita or ((CFrame.new(-11672, 334, -9474)).Position - d.Character.HumanoidRootPart.Position).Magnitude <= 10;
						task.wait(.7);
						repeat
							task.wait();
							_tp(CFrame.new(-12132, 521, -10655));
						until not _G.Auto_Tushita or ((CFrame.new(-12132, 521, -10655)).Position - d.Character.HumanoidRootPart.Position).Magnitude <= 10;
						task.wait(.7);
						repeat
							task.wait();
							_tp(CFrame.new(-13336, 486, -6985));
						until not _G.Auto_Tushita or ((CFrame.new(-13336, 486, -6985)).Position - d.Character.HumanoidRootPart.Position).Magnitude <= 10;
						task.wait(.7);
						repeat
							task.wait();
							_tp(CFrame.new(-13489, 332, -7925));
						until not _G.Auto_Tushita or ((CFrame.new(-13489, 332, -7925)).Position - d.Character.HumanoidRootPart.Position).Magnitude <= 10;
					end;
				else
					local Y = GetConnectionEnemies("Longma");
					if Y then
						repeat
							task.wait();
							f.Kill(Y, _G.Auto_Tushita);
						until Y.Humanoid.Health <= 0 or not _G.Auto_Tushita or not Y.Parent;
					else
						if Q:FindFirstChild("Longma") then
							_tp((Q:FindFirstChild("Longma")).HumanoidRootPart.CFrame * CFrame.new(0, 40, 0));
						end;
					end;
				end;
			end;
		end);
	end;
end);
yF.CreateToggle({
	Title = "Auto Yama Sword",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.Auto_Yama = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		pcall(function()
			if _G.Auto_Yama then
				if Q.Remotes.CommF_:InvokeServer("EliteHunter", "Progress") < 30 then
					_G.FarmEliteHunt = true;
				elseif Q.Remotes.CommF_:InvokeServer("EliteHunter", "Progress") > 30 then
					_G.FarmEliteHunt = false;
					if (workspace.Map.Waterfall.SealedKatana.Handle.Position - d.Character.HumanoidRootPart.Position).Magnitude >= 20 then
						_tp(workspace.Map.Waterfall.SealedKatana.Handle.CFrame);
						local Y = GetConnectionEnemies("Ghost");
						if Y then
							repeat
								task.wait();
								f.Kill(Y, _G.Auto_Yama);
							until Y.Humanoid.Health <= 0 or not Y.Parent or not _G.Auto_Yama;
							fireclickdetector(workspace.Map.Waterfall.SealedKatana.Handle.ClickDetector);
						end;
					end;
				end;
			end;
		end);
	end;
end);
local cF = bz.CreateSection("Cursed Dual Katana");
local HF = cF.CreateLabel({ Title = " Number Cursed dual katana quests ", Content = "Quest Numbers :" });
task.spawn(function()
	while task.wait(.2) do
		if QuestYama_1 == true then
			HF:SetDesc(" Quest Numbers : yama quest 1");
		elseif QuestYama_2 == true then
			HF:SetDesc(" Quest Numbers : yama quest 2");
		elseif QuestYama_3 == true then
			HF:SetDesc(" Quest Numbers : yama quest 3");
		elseif QuestTushita_1 == true then
			HF:SetDesc(" Quest Numbers : tushita quest 1");
		elseif QuestTushita_2 == true then
			HF:SetDesc(" Quest Numbers : tushita quest 2");
		elseif QuestTushita_2 == true then
			HF:SetDesc(" Quest Numbers: tushita quest 2");
		elseif GetWP("Cursed Dual Katana") then
			HF:SetDesc(" Quest Numbers: CDK done!!");
		end;
	end;
end);
cF.CreateToggle({
	Title = "Auto Get CDK [ Last Quest ]",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.CDK = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		pcall(function()
			if _G.CDK then
				Q.Remotes.CommF_:InvokeServer("CDKQuest", "Progress", "Good");
				Q.Remotes.CommF_:InvokeServer("CDKQuest", "Progress", "Evil");
				Q.Remotes.CommF_:InvokeServer("CDKQuest", "StartTrial", "Boss");
				local Y = GetConnectionEnemies("Cursed Skeleton Boss");
				if Y then
					repeat
						task.wait();
						if d.Character:FindFirstChild("Yama") or d.Backpack:FindFirstChild("Yama") then
							EquipWeapon("Yama");
						elseif d.Character:FindFirstChild("Tushita") or d.Backpack:FindFirstChild("Tushita") then
							EquipWeapon("Tushita");
						end;
						_tp(Y.HumanoidRootPart.CFrame * CFrame.new(0, 20, 0));
					until not _G.CDK or not Y.Parent or Y.Humanoid.Health <= 0;
				else
					_tp(CFrame.new(-12318.19335937, 601.95184326, -6538.66210937));
					task.wait(.5);
					_tp(workspace.Map.Turtle.Cursed.BossDoor.CFrame);
				end;
			end;
		end);
	end;
end);
cF.CreateToggle({
	Title = "Auto Yama CDK",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.CDK_YM = Y;
	end,
});
task.spawn(function()
	while task.wait() do
		pcall(function()
			if _G.CDK_YM then
				if tostring(Q.Remotes.CommF_:InvokeServer("CDKQuest", "OpenDoor")) ~= "opened" then
					Q.Remotes.CommF_:InvokeServer("CDKQuest", "OpenDoor");
					Q.Remotes.CommF_:InvokeServer("CDKQuest", "OpenDoor", true);
				else
					if (Q.Remotes.CommF_:InvokeServer("CDKQuest", "Progress")).Finished == nil then
						Q.Remotes.CommF_:InvokeServer("CDKQuest", "StartTrial", "Evil");
						Q.Remotes.CommF_:InvokeServer("CDKQuest", "StartTrial", "Evil");
					elseif (Q.Remotes.CommF_:InvokeServer("CDKQuest", "Progress")).Finished == false then
						if tonumber((Q.Remotes.CommF_:InvokeServer("CDKQuest", "Progress")).Evil) == -3 then
							QuestYama_1 = true;
							QuestYama_2 = false;
							QuestYama_3 = false;
							repeat
								task.wait();
								if not workspace.Enemies:FindFirstChild("Forest Pirate") then
									_tp(CFrame.new(-13223.52148437, 428.19381713, -7766.06787109));
								else
									local Y = GetConnectionEnemies("Forest Pirate");
									if Y then
										_tp((workspace.Enemies:FindFirstChild("Forest Pirate")).HumanoidRootPart.CFrame);
									end;
								end;
							until tonumber((Q.Remotes.CommF_:InvokeServer("CDKQuest", "Progress")).Evil) == 1 or not _G.CDK_YM;
						elseif tonumber((Q.Remotes.CommF_:InvokeServer("CDKQuest", "Progress")).Evil) == -4 then
							QuestYama_1 = false;
							QuestYama_2 = true;
							QuestYama_3 = false;
							for Y, d in pairs((game:GetService("Players")).LocalPlayer.QuestHaze:GetChildren()) do
								for Y, r in pairs(e) do
									if string.find(Y, d.Name) and d.Value > 0 then
										if (r.Position - R.Position).Magnitude <= 1000 and workspace.Enemies:FindFirstChild(Y) then
											for Y, d in pairs(workspace.Enemies:GetChildren()) do
												if d:FindFirstChild("HumanoidRootPart") and (d:FindFirstChild("Humanoid") and ((d:FindFirstChild("Humanoid")).Health > 0 and d:FindFirstChild("HazeESP"))) then
													repeat
														task.wait();
														f.Kill(d, _G.CDK_YM);
													until not _G.CDK_YM or tonumber((Q.Remotes.CommF_:InvokeServer("CDKQuest", "Progress")).Evil) == 2 or not d:FindFirstChild("HazeESP") or d.Humanoid.Health <= 0;
												end;
											end;
										else
											_tp(r);
										end;
									end;
								end;
							end;
						elseif tonumber((Q.Remotes.CommF_:InvokeServer("CDKQuest", "Progress")).Evil) == -5 then
							QuestYama_1 = false;
							QuestYama_2 = false;
							QuestYama_3 = true;
							if workspace.Map:FindFirstChild("HellDimension") then
								if (R.Position - workspace.Map.HellDimension.Spawn.Position).Magnitude <= 1000 then
									for Y, d in pairs(workspace.Map.HellDimension.Exit:GetChildren()) do
										if tonumber(Y) == 2 then
											repeat
												task.wait();
												R.CFrame = workspace.Map.HellDimension.Exit.CFrame;
											until not _G.CDK_YM or tonumber((Q.Remotes.CommF_:InvokeServer("CDKQuest", "Progress")).Evil) == 3;
										end;
									end;
									EquipWeapon(_G.SelectWeapon);
									if tonumber((Q.Remotes.CommF_:InvokeServer("CDKQuest", "Progress")).Evil) ~= 3 then
										repeat
											task.wait();
											repeat
												task.wait();
												_tp(workspace.Map.HellDimension.Torch1.Particles.CFrame);
												for Y, d in pairs(workspace.Map.HellDimension:GetDescendants()) do
													if d:IsA("ProximityPrompt") then
														fireproximityprompt(d);
													end;
												end;
											until (workspace.Map.HellDimension.Torch1.Particles.Position - R.Position).Magnitude < 5;
											task.wait(2);
											_G.T1Yama = true;
										until not _G.CDK_YM or _G.T1Yama or tonumber((Q.Remotes.CommF_:InvokeServer("CDKQuest", "Progress")).Evil) == 3;
										repeat
											task.wait();
											repeat
												task.wait();
												_tp(workspace.Map.HellDimension.Torch2.Particles.CFrame);
												for Y, d in pairs(workspace.Map.HellDimension:GetDescendants()) do
													if d:IsA("ProximityPrompt") then
														fireproximityprompt(d);
													end;
												end;
											until (workspace.Map.HellDimension.Torch2.Particles.Position - R.Position).Magnitude < 5;
											task.wait(2);
											_G.T2Yama = true;
										until _G.T2Yama or _G.CDK_YM == false or tonumber((Q.Remotes.CommF_:InvokeServer("CDKQuest", "Progress")).Evil) == 3;
										repeat
											task.wait();
											repeat
												task.wait();
												_tp(workspace.Map.HellDimension.Torch3.Particles.CFrame);
												for Y, d in pairs(workspace.Map.HellDimension:GetDescendants()) do
													if d:IsA("ProximityPrompt") then
														fireproximityprompt(d);
													end;
												end;
											until (workspace.Map.HellDimension.Torch3.Particles.Position - R.Position).Magnitude < 5;
											task.wait(2);
											_G.T3Yama = true;
										until _G.T3Yama or _G.CDK_YM == false or tonumber((Q.Remotes.CommF_:InvokeServer("CDKQuest", "Progress")).Evil) == 3;
									end;
									for Y, d in pairs(workspace.Enemies:GetChildren()) do
										if ((d:FindFirstChild("HumanoidRootPart")).Position - workspace.Map.HellDimension.Spawn.Position).Magnitude <= 300 then
											if d:FindFirstChild("HumanoidRootPart") and (d:FindFirstChild("Humanoid") and (d:FindFirstChild("Humanoid")).Health > 0) then
												repeat
													task.wait();
													f.Kill(d, _G.CDK_YM);
												until not _G.CDK_YM or d.Humanoid.Health <= 0 or not d.Parent or tonumber((Q.Remotes.CommF_:InvokeServer("CDKQuest", "Progress")).Evil) == 3;
											end;
										end;
									end;
								end;
							end;
						end;
					end;
				end;
			end;
		end);
	end;
end);
task.spawn(function()
	while task.wait() do
		pcall(function()
			if _G.CDK_YM then
				if tonumber((Q.Remotes.CommF_:InvokeServer("CDKQuest", "Progress")).Evil) == -5 then
					if not workspace.Map:FindFirstChild("HellDimension") or (R.Position - workspace.Map.HellDimension.Spawn.Position).Magnitude > 1000 then
						local Y = GetConnectionEnemies("Soul Reaper");
						if Y then
							repeat
								task.wait();
								_tp(Y.HumanoidRootPart.CFrame);
							until Y.Humanoid.Health <= 0 or not _G.CDK_YM or not Y.Parent or tonumber((Q.Remotes.CommF_:InvokeServer("CDKQuest", "Progress")).Evil) == 3 or workspace.Map:FindFirstChild("HellDimension") and (R.Position - workspace.Map.HellDimension.Spawn.Position).Magnitude <= 1000;
						elseif d.Backpack:FindFirstChild("Hallow Essence") or d.Character:FindFirstChild("Hallow Essence") then
							repeat
								_tp(CFrame.new(-8932.32226562, 146.83154296, 6062.55078125));
								task.wait();
							until ((CFrame.new(-8932.32226562, 146.83154296, 6062.55078125)).Position - R.Position).Magnitude <= 8;
							EquipWeapon("Hallow Essence");
						elseif Q:FindFirstChild("Soul Reaper") and (Q:FindFirstChild("Soul Reaper")).Humanoid.Health > 0 then
							_tp((Q:FindFirstChild("Soul Reaper")).HumanoidRootPart.CFrame);
						else
							if Q.Remotes.CommF_:InvokeServer("Bones", "Check") < 50 and (not workspace.Enemies:FindFirstChild("Soul Reaper") and (not Q:FindFirstChild("Soul Reaper") and not workspace.Map:FindFirstChild("HellDimension"))) then
								if workspace.Enemies:FindFirstChild("Reborn Skeleton") or workspace.Enemies:FindFirstChild("Living Zombie") or workspace.Enemies:FindFirstChild("Domenic Soul") or workspace.Enemies:FindFirstChild("Posessed Mummy") then
									for Y, d in pairs(workspace.Enemies:GetChildren()) do
										if d.Name == "Reborn Skeleton" or d.Name == "Living Zombie" or d.Name == "Demonic Soul" or d.Name == "Posessed Mummy" then
											if d:FindFirstChild("HumanoidRootPart") and (d:FindFirstChild("Humanoid") and (d:FindFirstChild("Humanoid")).Health > 0) then
												repeat
													task.wait();
													f.Kill(d, _G.CDK_YM);
												until not _G.CDK_YM or d.Humanoid.Health <= 0 or not d.Parent;
											end;
										end;
									end;
								else
									_tp(CFrame.new(-9515.22558593, 164.00622558, 5785.38330078));
								end;
							else
								Q.Remotes.CommF_:InvokeServer("Bones", "Buy", 1, 1);
							end;
						end;
					end;
				end;
			end;
		end);
	end;
end);
cF.CreateToggle({
	Title = "Auto Tushita CDK",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.CDK_TS = Y;
	end,
});
task.spawn(function()
	while task.wait() do
		pcall(function()
			if _G.CDK_TS then
				if tostring(Q.Remotes.CommF_:InvokeServer("CDKQuest", "OpenDoor")) ~= "opened" then
					task.wait(.7);
					Q.Remotes.CommF_:InvokeServer("CDKQuest", "OpenDoor");
					task.wait(.3);
					Q.Remotes.CommF_:InvokeServer("CDKQuest", "OpenDoor", true);
				else
					if (Q.Remotes.CommF_:InvokeServer("CDKQuest", "Progress")).Finished == nil then
						Q.Remotes.CommF_:InvokeServer("CDKQuest", "StartTrial", "Good");
					elseif (Q.Remotes.CommF_:InvokeServer("CDKQuest", "Progress")).Finished == false then
						if tonumber((Q.Remotes.CommF_:InvokeServer("CDKQuest", "Progress")).Good) == -3 then
							QuestTushita_1 = true;
							QuestTushita_2 = false;
							QuestTushita_3 = false;
							repeat
								task.wait();
								_tp(CFrame.new(-4602.51074218, 16.44654273, -2880.99804687));
							until ((CFrame.new(-4602.51074218, 16.44654273, -2880.99804687)).Position - (game:GetService("Players")).LocalPlayer.Character.HumanoidRootPart.Position).Magnitude <= 3 or not _G.CDK_TS or tonumber((Q.Remotes.CommF_:InvokeServer("CDKQuest", "Progress")).Good) == 1;
							if ((CFrame.new(-4602.51074218, 16.44654273, -2880.99804687)).Position - (game:GetService("Players")).LocalPlayer.Character.HumanoidRootPart.Position).Magnitude <= 10 then
								task.wait(.7);
								Q.Remotes.CommF_:InvokeServer("CDKQuest", "BoatQuest", workspace.NPCs:FindFirstChild("Luxury Boat Dealer"), "Check");
								task.wait(.5);
								Q.Remotes.CommF_:InvokeServer("CDKQuest", "BoatQuest", workspace.NPCs:FindFirstChild("Luxury Boat Dealer"));
							end;
							task.wait(1);
							repeat
								task.wait();
								_tp(CFrame.new(4001.18530273, 10.08939933, -2654.86328125));
							until ((CFrame.new(4001.18530273, 10.08939933, -2654.86328125)).Position - (game:GetService("Players")).LocalPlayer.Character.HumanoidRootPart.Position).Magnitude <= 3 or not _G.CDK_TS or tonumber((Q.Remotes.CommF_:InvokeServer("CDKQuest", "Progress")).Good) == 1;
							if ((CFrame.new(4001.18530273, 10.08939933, -2654.86328125)).Position - (game:GetService("Players")).LocalPlayer.Character.HumanoidRootPart.Position).Magnitude <= 10 then
								task.wait(.7);
								Q.Remotes.CommF_:InvokeServer("CDKQuest", "BoatQuest", workspace.NPCs:FindFirstChild("Luxury Boat Dealer"), "Check");
								task.wait(.5);
								Q.Remotes.CommF_:InvokeServer("CDKQuest", "BoatQuest", workspace.NPCs:FindFirstChild("Luxury Boat Dealer"));
							end;
							task.wait(1);
							repeat
								task.wait();
								_tp(CFrame.new(-9530.76367187, 7.24520874, -8375.50878906));
							until ((CFrame.new(-9530.76367187, 7.24520874, -8375.50878906)).Position - (game:GetService("Players")).LocalPlayer.Character.HumanoidRootPart.Position).Magnitude <= 3 or not _G.CDK_TS or tonumber((Q.Remotes.CommF_:InvokeServer("CDKQuest", "Progress")).Good) == 1;
							if ((CFrame.new(-9530.76367187, 7.24520874, -8375.50878906)).Position - (game:GetService("Players")).LocalPlayer.Character.HumanoidRootPart.Position).Magnitude <= 10 then
								task.wait(.7);
								Q.Remotes.CommF_:InvokeServer("CDKQuest", "BoatQuest", workspace.NPCs:FindFirstChild("Luxury Boat Dealer"), "Check");
								task.wait(.5);
								Q.Remotes.CommF_:InvokeServer("CDKQuest", "BoatQuest", workspace.NPCs:FindFirstChild("Luxury Boat Dealer"));
							end;
							task.wait(1);
						elseif tonumber((Q.Remotes.CommF_:InvokeServer("CDKQuest", "Progress")).Good) == -4 then
							QuestTushita_1 = false;
							QuestTushita_2 = true;
							QuestTushita_3 = false;
							repeat
								task.wait();
								_G.AutoRaidCastle = true;
							until not _G.CDK_TS or tonumber((Q.Remotes.CommF_:InvokeServer("CDKQuest", "Progress")).Good) == 2;
							_G.AutoRaidCastle = false;
						elseif tonumber((Q.Remotes.CommF_:InvokeServer("CDKQuest", "Progress")).Good) == -5 then
							QuestTushita_1 = false;
							QuestTushita_2 = false;
							QuestTushita_3 = true;
							if workspace.Enemies:FindFirstChild("Cake Queen") then
								for Y, d in pairs(workspace.Enemies:GetChildren()) do
									if d.Name == "Cake Queen" then
										if d:FindFirstChild("Humanoid") and (d:FindFirstChild("HumanoidRootPart") and d.Humanoid.Health > 0) then
											repeat
												task.wait();
												f.Kill(d, _G.CDK_TS);
											until not _G.CDK_TS or not d.Parent or d.Humanoid.Health <= 0 or tonumber((Q.Remotes.CommF_:InvokeServer("CDKQuest", "Progress")).Good) == 3;
										end;
									end;
								end;
							elseif Q:FindFirstChild("Cake Queen") and (Q:FindFirstChild("Cake Queen")).Humanoid.Health > 0 then
								_tp((Q:FindFirstChild("Cake Queen")).HumanoidRootPart.CFrame * CFrame.new(0, 30, 0));
							else
								if (game.Players.LocalPlayer.Character.HumanoidRootPart.Position - workspace.Map.HeavenlyDimension.Spawn.Position).Magnitude <= 1000 then
									for Y, d in pairs(workspace.Map.HeavenlyDimension.Exit:GetChildren()) do
										Ex = Y;
									end;
									if Ex == 2 then
										repeat
											task.wait();
											game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = workspace.Map.HeavenlyDimension.Exit.CFrame;
										until not _G.CDK_TS or tonumber((Q.Remotes.CommF_:InvokeServer("CDKQuest", "Progress")).Good) == 3;
									end;
									repeat
										task.wait();
										repeat
											task.wait();
											_tp(CFrame.new(-22529.6171875, 5275.77392578, 3873.57128906));
											for Y, d in pairs(workspace.Map.HeavenlyDimension:GetDescendants()) do
												if d:IsA("ProximityPrompt") then
													fireproximityprompt(d);
												end;
											end;
										until ((CFrame.new(-22529.6171875, 5275.77392578, 3873.57128906)).Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude < 5;
										task.wait(2);
										_G.DoneT1 = true;
									until not _G.CDK_TS or _G.DoneT1;
									repeat
										task.wait();
										repeat
											task.wait();
											_tp(CFrame.new(-22637.29101562, 5281.36523437, 3749.28857421));
											for Y, d in pairs(workspace.Map.HeavenlyDimension:GetDescendants()) do
												if d:IsA("ProximityPrompt") then
													fireproximityprompt(d);
												end;
											end;
										until ((CFrame.new(-22637.29101562, 5281.36523437, 3749.28857421)).Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude < 5;
										task.wait(2);
										_G.DoneT2 = true;
									until _G.DoneT2 or _G.CDK_TS == false;
									repeat
										task.wait();
										repeat
											task.wait();
											_tp(CFrame.new(-22791.14453125, 5277.16552734, 3764.57006835));
											for Y, d in pairs(workspace.Map.HeavenlyDimension:GetDescendants()) do
												if d:IsA("ProximityPrompt") then
													fireproximityprompt(d);
												end;
											end;
										until ((CFrame.new(-22791.14453125, 5277.16552734, 3764.57006835)).Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude < 5;
										task.wait(2);
										_G.DoneT3 = true;
									until _G.DoneT3 or _G.CDK_TS == false;
									for Y, d in pairs(workspace.Enemies:GetChildren()) do
										if ((d:FindFirstChild("HumanoidRootPart")).Position - (CFrame.new(-22695.7012, 5270.93652, 3814.42847, .11794927, 3.32185834e-08, .99301964, -8.73070718e-08, 1, -2.30819008e-08, -0.99301964, -8.3975138e-08, .11794927)).Position).Magnitude <= 300 then
											if d:FindFirstChild("HumanoidRootPart") and (d:FindFirstChild("Humanoid") and (d:FindFirstChild("Humanoid")).Health > 0) then
												repeat
													task.wait();
													f.Kill(d, _G.CDK_TS);
												until not _G.CDK_TS or d.Humanoid.Health <= 0 or not d.Parent;
											end;
										end;
									end;
								end;
							end;
						end;
					end;
				end;
			end;
		end);
	end;
end);
local SF = bz.CreateSection("True Triple Katana Sword");
SF.CreateButton({ Title = "Buy Legendary Sword", Callback = function()
		Q.Remotes.CommF_:InvokeServer("LegendarySwordDealer", "1");
		Q.Remotes.CommF_:InvokeServer("LegendarySwordDealer", "2");
		Q.Remotes.CommF_:InvokeServer("LegendarySwordDealer", "3");
	end });
SF.CreateButton({ Title = "Buy True Triple Katana Sword", Callback = function()
		Q.Remotes.CommF_:InvokeServer("MysteriousMan", "2");
	end });
SF.CreateToggle({
	Title = "Tween to Legendary Sword Dealer",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.Tp_LgS = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		if _G.Tp_LgS then
			pcall(function()
				for Y, d in pairs(Q.NPCs:GetChildren()) do
					if d.Name == "Legendary Sword Dealer " then
						_tp(d.HumanoidRootPart.CFrame);
					end;
				end;
			end);
		end;
	end;
end);
local oF = bz.CreateSection("Pole / God Enal\'s");
oF.CreateToggle({
	Title = "Auto Pole V1",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.AutoPole = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		if _G.AutoPole then
			pcall(function()
				local Y = GetConnectionEnemies("Thunder God");
				if Y then
					repeat
						task.wait();
						f.Kill(Y, _G.AutoPole);
					until not _G.AutoPole or not Y.Parent or Y.Humanoid.Health <= 0;
				else
					_tp(CFrame.new(-7994.984375, 5761.02539062, -2088.64794921));
				end;
			end);
		end;
	end;
end);
oF.CreateToggle({
	Title = "Auto Pole V2 [Beta]",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.AutoPoleV2 = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		pcall(function()
			if _G.AutoPoleV2 then
				if not GetBP("Pole (1st Form)") then
					Q.Remotes.CommF_:InvokeServer("LoadItem", "Pole (1st Form)");
				end;
				if not GetBP("Pole (2nd Form)") then
					Q.Remotes.CommF_:InvokeServer("LoadItem", "Pole (2nd Form)");
				end;
				if GetBP("Pole (1st Form)") and (GetBP("Pole (1st Form)")).Level.Value <= 179 then
					_G.Level = true;
				elseif GetBP("Pole (1st Form)") and (GetBP("Pole (1st Form)")).Level.Value >= 180 then
					_G.Level = false;
				end;
				if not GetBP("Rumble Fruit") then
					return;
				end;
				if (GetBP("Rumble Fruit")).AwakenedMoves:FindFirstChild("Z") and ((GetBP("Rumble Fruit")).AwakenedMoves:FindFirstChild("X") and ((GetBP("Rumble Fruit")).AwakenedMoves:FindFirstChild("C") and ((GetBP("Rumble Fruit")).AwakenedMoves:FindFirstChild("V") and (GetBP("Rumble Fruit")).AwakenedMoves:FindFirstChild("F")))) then
					_G.SelectChip = nil;
					_G.Raiding = false;
					_G.Auto_Awakener = false;
					if d.Data.Fragments.Value >= 5000 then
						Q.Remotes.CommF_:InvokeServer("Thunder God", "Talk");
						task.wait(T);
						Q.Remotes.CommF_:InvokeServer("Thunder God", "Sure");
					end;
				elseif Q.Remotes.CommF_:InvokeServer("Awakener", "Check") == nil or Q.Remotes.CommF_:InvokeServer("Awakener", "Check") == 0 then
					_G.SelectChip = "Rumble";
					local Y = Q.Remotes.CommF_:InvokeServer("RaidsNpc", "Select", _G.SelectChip);
					if Y then
						Y:Stop();
					end;
					_G.Raiding = true;
					_G.Auto_Awakener = true;
				end;
			end;
		end);
	end;
end);
local ZF = bz.CreateSection("Items Law/Order Sword");
ZF.CreateToggle({
	Title = "Auto Law Sword",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.AutoLawKak = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		if _G.AutoLawKak then
			pcall(function()
				local Y = GetConnectionEnemies("Order");
				if Y then
					repeat
						task.wait();
						f.Kill(Y, _G.AutoLawKak);
					until _G.AutoLawKak == false or not Y.Parent or Y.Humanoid.Health <= 0;
				else
					_tp(CFrame.new(-6217.20214843, 28.04764556, -5053.13574218));
				end;
			end);
		end;
	end;
end);
ZF.CreateButton({ Title = "Buy Microchip Law", Callback = function()
		Q.Remotes.CommF_:InvokeServer("BlackbeardReward", "Microchip", "2");
	end });
ZF.CreateButton({ Title = "Start Law Raids", Callback = function()
		fireclickdetector(workspace.Map.CircleIsland.RaidSummon.Button.Main.ClickDetector);
	end });
local TF = bz.CreateSection("East Blue Misc");
TF.CreateToggle({
	Title = "Auto Saw Sword",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.AutoSaw = Y;
	end,
});
task.spawn(function()
	while task.wait(.2) do
		pcall(function()
			if _G.AutoSaw then
				local Y = GetConnectionEnemies("The Saw");
				if Y then
					repeat
						task.wait();
						f.Kill(Y, _G.AutoSaw);
					until _G.AutoSaw == false or Y.Humanoid.Health <= 0;
				else
					_tp(CFrame.new(-784.89715576, 72.42738342, 1603.58227539));
				end;
			end;
		end);
	end;
end);
TF.CreateToggle({
	Title = "Auto Saber Sword",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.AutoSaber = Y;
	end,
});
task.spawn(function()
	while task.wait(.2) do
		pcall(function()
			if _G.AutoSaber and (d.Data.Level.Value >= 200 and (not d.Backpack:FindFirstChild("Saber") and not d.Character:FindFirstChild("Saber"))) then
				if workspace.Map.Jungle.Final.Part.Transparency == 0 then
					if workspace.Map.Jungle.QuestPlates.Door.Transparency == 0 then
						if ((CFrame.new(-1612.55884, 36.9774132, 148.719543, .37091279, 3.0717151e-09, -0.92866772, 3.97099491e-08, 1, 1.91679348e-08, .928667724, -4.39869794e-08, .37091279)).Position - d.Character.HumanoidRootPart.Position).Magnitude <= 100 then
							_tp(d.Character.HumanoidRootPart.CFrame);
							task.wait(.5);
							d.Character.HumanoidRootPart.CFrame = workspace.Map.Jungle.QuestPlates.Plate1.Button.CFrame;
							task.wait(.5);
							d.Character.HumanoidRootPart.CFrame = workspace.Map.Jungle.QuestPlates.Plate2.Button.CFrame;
							task.wait(.5);
							d.Character.HumanoidRootPart.CFrame = workspace.Map.Jungle.QuestPlates.Plate3.Button.CFrame;
							task.wait(.5);
							d.Character.HumanoidRootPart.CFrame = workspace.Map.Jungle.QuestPlates.Plate4.Button.CFrame;
							task.wait(.5);
							d.Character.HumanoidRootPart.CFrame = workspace.Map.Jungle.QuestPlates.Plate5.Button.CFrame;
							task.wait(.5);
						else
							_tp(CFrame.new(-1612.55884, 36.9774132, 148.719543, .37091279, 3.0717151e-09, -0.92866772, 3.97099491e-08, 1, 1.91679348e-08, .928667724, -4.39869794e-08, .37091279));
						end;
					else
						if workspace.Map.Desert.Burn.Part.Transparency == 0 then
							if d.Backpack:FindFirstChild("Torch") or d.Character:FindFirstChild("Torch") then
								EquipWeapon("Torch");
								firetouchinterest(d.Character.Torch.Handle, workspace.Map.Desert.Burn.Fire, 0);
								firetouchinterest(d.Character.Torch.Handle, workspace.Map.Desert.Burn.Fire, 1);
								_tp(CFrame.new(1114.61475, 5.04679728, 4350.22803, -0.64846658, -1.28799094e-09, .761243105, -5.70652914e-10, 1, 1.20584542e-09, -0.76124310, 3.47544882e-10, -0.64846658));
							else
								_tp(CFrame.new(-1610.00757, 11.5049858, 164.001587, .984807551, -0.16772228, -0.04498181, .17364943, .951244235, .254912198, 3.42372805e-05, -0.25885051, .965917408));
							end;
						else
							if Q.Remotes.CommF_:InvokeServer("ProQuestProgress", "SickMan") ~= 0 then
								Q.Remotes.CommF_:InvokeServer("ProQuestProgress", "GetCup");
								task.wait(.5);
								EquipWeapon("Cup");
								task.wait(.5);
								Q.Remotes.CommF_:InvokeServer("ProQuestProgress", "FillCup", d.Character.Cup);
								task.wait(T);
								Q.Remotes.CommF_:InvokeServer("ProQuestProgress", "SickMan");
							else
								if Q.Remotes.CommF_:InvokeServer("ProQuestProgress", "RichSon") == nil then
									Q.Remotes.CommF_:InvokeServer("ProQuestProgress", "RichSon");
								elseif Q.Remotes.CommF_:InvokeServer("ProQuestProgress", "RichSon") == 0 then
									if workspace.Enemies:FindFirstChild("Mob Leader") or Q:FindFirstChild("Mob Leader") then
										_tp(CFrame.new(-2967.59521, -4.91089821, 5328.70703, .342208564, -0.02278490, .939347804, .0251603816, .999569714, .0150796166, -0.93928712, .0184739735, .342634559));
										for Y, d in pairs(workspace.Enemies:GetChildren()) do
											if d.Name == "Mob Leader" and f.Alive(d) then
												repeat
													task.wait();
													f.Kill(d, _G.AutoSaber);
												until d.Humanoid.Health <= 0 or _G.AutoSaber == false;
											end;
										end;
									end;
								elseif Q.Remotes.CommF_:InvokeServer("ProQuestProgress", "RichSon") == 1 then
									Q.Remotes.CommF_:InvokeServer("ProQuestProgress", "RichSon");
									EquipWeapon("Relic");
									_tp(CFrame.new(-1404.91504, 29.9773273, 3.80598116, .876514494, 5.66906877e-09, .481375456, 2.53851997e-08, 1, -5.79995607e-08, -0.48137545, 6.30572643e-08, .876514494));
								end;
							end;
						end;
					end;
				else
					if workspace.Enemies:FindFirstChild("Saber Expert") or Q:FindFirstChild("Saber Expert") then
						for Y, d in pairs(workspace.Enemies:GetChildren()) do
							if d.Name == "Saber Expert" and f.Alive(d) then
								repeat
									task.wait();
									f.Kill(d, _G.AutoSaber);
								until d.Humanoid.Health <= 0 or _G.AutoSaber == false;
								if d.Humanoid.Health <= 0 then
									Q.Remotes.CommF_:InvokeServer("ProQuestProgress", "PlaceRelic");
								end;
							end;
						end;
					else
						_tp(CFrame.new(-1401.85046, 29.9773273, 8.81916237, .85820812, 8.76083845e-08, .513301849, -8.55007443e-08, 1, -2.77243419e-08, -0.51330184, -2.00944328e-08, .85820812));
					end;
				end;
			end;
		end);
	end;
end);
TF.CreateToggle({
	Title = "Auto Cybrog",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.AutoColShad = Y;
	end,
});
task.spawn(function()
	while task.wait(.2) do
		if _G.AutoColShad then
			pcall(function()
				local Y = GetConnectionEnemies("Cyborg");
				if Y then
					repeat
						task.wait();
						f.Kill(Y, _G.AutoColShad);
					until _G.AutoColShad == false or not Y.Parent or Y.Humanoid.Health <= 0;
				else
					_tp(CFrame.new(6094.02490234, 73.77005004, 3825.73486328));
				end;
			end);
		end;
	end;
end);
TF.CreateToggle({
	Title = "Auto Usoap\'s Hat",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.AutoGetUsoap = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		pcall(function()
			if _G.AutoGetUsoap then
				for Y, Q in pairs(workspace.Characters:GetChildren()) do
					if Q.Name ~= d.Name then
						if Q.Humanoid.Health > 0 and (Q:FindFirstChild("HumanoidRootPart") and (Q.Parent and (R.Position - Q.HumanoidRootPart.Position).Magnitude <= 230)) then
							repeat
								task.wait();
								EquipWeapon(_G.SelectWeapon);
								_tp(Q.HumanoidRootPart.CFrame * CFrame.new(1, 1, 2));
							until _G.AutoGetUsoap == false or Q.Humanoid.Health <= 0 or not Q.Parent or not Q:FindFirstChild("HumanoidRootPart") or not Q:FindFirstChild("Humanoid");
						end;
					end;
				end;
			end;
		end);
	end;
end);
TF.CreateToggle({
	Title = "Auto Bisento V2",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.Greybeard = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		if _G.Greybeard then
			pcall(function()
				if not GetWP("Bisento") then
					Q.Remotes.CommF_:InvokeServer("BuyItem", "Bisento");
				elseif GetWP("Bisento") then
					Q.Remotes.CommF_:InvokeServer("LoadItem", "Bisento");
					local Y = GetConnectionEnemies("Greybeard");
					if Y then
						repeat
							task.wait();
							f.Kill(Y, _G.Greybeard);
						until _G.Greybeard == false or not Y.Parent or Y.Humanoid.Health <= 0;
					else
						_tp(CFrame.new(-5023.38330078, 28.65203285, 4332.38183593));
					end;
				end;
			end);
		end;
	end;
end);
TF.CreateToggle({
	Title = "Auto Warden Sword",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.WardenBoss = Y;
	end,
});
task.spawn(function()
	while task.wait(.1) do
		if _G.WardenBoss then
			pcall(function()
				local Y = GetConnectionEnemies("Chief Warden");
				if Y then
					repeat
						task.wait();
						f.Kill(Y, _G.WardenBoss);
					until _G.WardenBoss == false or not Y.Parent or Y.Humanoid.Health <= 0;
				else
					_tp(CFrame.new(5206.92578, .997753382, 814.976746, .342041343, -0.00062915, .939684749, .00191645394, .999998152, -2.80422337e-05, -0.93968296, .00181045406, .342041939));
				end;
			end);
		end;
	end;
end);
TF.CreateToggle({
	Title = "Auto Marine Coat",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.MarinesCoat = Y;
	end,
});
task.spawn(function()
	while task.wait(.1) do
		if _G.MarinesCoat then
			pcall(function()
				local Y = GetConnectionEnemies("Vice Admiral");
				if Y then
					repeat
						task.wait();
						f.Kill(Y, _G.MarinesCoat);
					until _G.MarinesCoat == false or not Y.Parent or Y.Humanoid.Health <= 0;
				else
					_tp(CFrame.new(-5006.54541015, 88.03208160, 4353.16210937));
				end;
			end);
		end;
	end;
end);
TF.CreateToggle({
	Title = "Auto Swan Coat",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.SwanCoat = Y;
	end,
});
task.spawn(function()
	while task.wait(.1) do
		if _G.SwanCoat then
			pcall(function()
				local Y = GetConnectionEnemies("Swan");
				if Y then
					repeat
						task.wait();
						f.Kill(Y, _G.SwanCoat);
					until _G.SwanCoat == false or not Y.Parent or Y.Humanoid.Health <= 0;
				else
					_tp(CFrame.new(5325.09619, 7.03906584, 719.570679, -0.30906081, 0, .951042235, 0, 1, 0, -0.95104223, 0, -0.30906081));
				end;
			end);
		end;
	end;
end);
local kF = bz.CreateSection("Rengoku Sword");
kF.CreateToggle({
	Title = "Auto Rengoku Sword",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.IceBossRen = Y;
	end,
});
task.spawn(function()
	pcall(function()
		while task.wait(.1) do
			if _G.IceBossRen then
				local Y = GetConnectionEnemies("Awakened Ice Admiral");
				if Y then
					repeat
						task.wait();
						f.Kill(Y, _G.IceBossRen);
					until _G.IceBossRen == false or not Y.Parent or Y.Humanoid.Health <= 0;
				else
					_tp(CFrame.new(5668.97802734, 28.51998901, -6483.35205078));
				end;
			end;
		end;
	end);
end);
kF.CreateToggle({
	Title = "Auto Key Rengoku",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.KeysRen = Y;
	end,
});
task.spawn(function()
	while task.wait(.1) do
		pcall(function()
			if _G.KeysRen then
				if d.Backpack:FindFirstChild(G[3]) or d.Character:FindFirstChild(G[3]) then
					EquipWeapon(G[3]);
					task.wait(.1);
					_tp(CFrame.new(6571.12011718, 299.23028564, -6967.84179687));
				else
					local Y = GetConnectionEnemies(G);
					if Y then
						repeat
							task.wait();
							f.Kill(Y, _G.KeysRen);
						until d.Backpack:FindFirstChild(G[3]) or _G.KeysRen == false or not Y.Parent or Y.Humanoid.Health <= 0;
					else
						_tp(CFrame.new(5439.71679687, 84.42094421, -6715.16357421));
					end;
				end;
			end;
		end);
	end;
end);
kF.CreateToggle({
	Title = "Auto Dragon Trident",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.AutoTridentW2 = Y;
	end,
});
task.spawn(function()
	while task.wait(.1) do
		pcall(function()
			if _G.AutoTridentW2 then
				local Y = GetConnectionEnemies("Tide Keeper");
				if Y then
					repeat
						task.wait();
						f.Kill(Y, _G.AutoTridentW2);
					until _G.AutoTridentW2 == false or not Y.Parent or Y.Humanoid.Health <= 0;
				else
					_tp(CFrame.new(-3795.64233398, 105.88877105, -11421.30761718));
				end;
			end;
		end);
	end;
end);
kF.CreateToggle({
	Title = "Auto Long Sword",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.LongsWord = Y;
	end,
});
task.spawn(function()
	while task.wait(.1) do
		pcall(function()
			if _G.LongsWord then
				local Y = GetConnectionEnemies("Diamond");
				if Y then
					repeat
						task.wait();
						f.Kill(Y, _G.LongsWord);
					until _G.LongsWord == false or not Y.Parent or Y.Humanoid.Health <= 0;
				else
					_tp(CFrame.new(-1576.71667480, 198.59265136, 13.72428607));
				end;
			end;
		end);
	end;
end);
kF.CreateToggle({
	Title = "Auto Black Spikey",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.BlackSpikey = Y;
	end,
});
task.spawn(function()
	while task.wait(.1) do
		if _G.BlackSpikey then
			pcall(function()
				local Y = GetConnectionEnemies("Jeremy");
				if Y then
					repeat
						task.wait();
						f.Kill(Y, _G.BlackSpikey);
					until _G.BlackSpikey == false or not Y.Parent or Y.Humanoid.Health <= 0;
				else
					_tp(CFrame.new(2006.92614746, 448.95666503, 853.98284912));
				end;
			end);
		end;
	end;
end);
kF.CreateToggle({
	Title = "Auto Dark Blade V3",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.DarkBladev3 = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		pcall(function()
			if _G.DarkBladev3 and World2 then
				if not GetBP("Dark Blade") then
					Q.Remotes.CommF_:InvokeServer("LoadItem", "Dark Blade");
				end;
				if GetBP("Fist of Darkness") > 1 then
					if not workspace.Enemies:FindFirstChild("Darkbeard") then
						_tp(CFrame.new(3677.08203125, 62.75193786, -3144.83325195));
					elseif GetConnectionEnemies("Darkbeard") and GetBP("Fist of Darkness") >= 1 then
						repeat
							task.wait();
							_tp(CFrame.new(-5719.36376953, 48.50590515, -782.97595214));
						until not _G.DarkBladev3 or R.Position == (CFrame.new(-5719.36376953, 48.50590515, -782.97595214)).Position;
						fireclickdetector(workspace.Map.GraveIsland.Mountain.Rocks.Button.ClickDetector);
					end;
				else
					_G.AutoFarmChest = true;
				end;
			end;
		end);
	end;
end);
kF.CreateToggle({
	Title = "Auto Midnight Blade",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.AutoEcBoss = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		pcall(function()
			if _G.AutoEcBoss then
				if GetM("Ectoplasm") >= 99 then
					Q.Remotes.CommF_:InvokeServer("Ectoplasm", "Buy", 3);
				elseif GetM("Ectoplasm") <= 99 then
					local Y = GetConnectionEnemies("Cursed Captain");
					if Y then
						repeat
							task.wait();
							f.Kill(Y, _G.AutoEcBoss);
						until not _G.AutoEcBoss or not Y.Parent or Y.Humanoid.Health <= 0;
					else
						Q.Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(923.21252441, 126.97600555, 32852.83203125));
						task.wait(.5);
						_tp(CFrame.new(916.928589, 181.092773, 33422));
					end;
				end;
			end;
		end);
	end;
end);
kF.CreateToggle({
	Title = "Auto Darkbeard",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.Auto_Def_DarkCoat = Y;
	end,
});
task.spawn(function()
	while task.wait(.1) do
		if _G.Auto_Def_DarkCoat then
			pcall(function()
				if GetBP("Fist of Darkness") and not workspace.Enemies:FindFirstChild("Darkbeard") then
					_tp(CFrame.new(3677.08203125, 62.75193786, -3144.83325195));
				elseif GetConnectionEnemies("Darkbeard") then
					local Y = GetConnectionEnemies("Darkbeard");
					if Y then
						repeat
							task.wait();
							f.Kill(Y, _G.Auto_Def_DarkCoat);
						until _G.Auto_Def_DarkCoat == false or not Y.Parent or Y.Humanoid.Helath <= 0;
					end;
				elseif not GetBP("Fist of Darkness") and not GetConnectionEnemies("Darkbeard") then
					repeat
						task.wait(.1);
						_G.AutoFarmChest = true;
					until not _G.Auto_Def_DarkCoat or GetBP("Fist of Darkness") or GetConnectionEnemies("Darkbeard");
					_G.AutoFarmChest = false;
				end;
			end);
		end;
	end;
end);
kF.CreateToggle({
	Title = "Auto Unlocked DonSwan",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.Auto_DonAcces = Y;
	end,
});
task.spawn(function()
	while task.wait(.1) do
		if _G.Auto_DonAcces then
			pcall(function()
				if (Q.Remotes.CommF_:InvokeServer("GetUnlockables")).FlamingoAccess == nil and d.Data.Level.Value >= 1500 then
					FruitPrice = {};
					FruitStore = {};
					for Y, d in next, (Q:WaitForChild("Remotes")).CommF_:InvokeServer("GetFruits") do
						if d.Price >= 1000000 then
							table.insert(FruitPrice, d.Name);
						end;
					end;
					for Y, R in pairs(Q.Remotes.CommF_:InvokeServer("getInventoryFruits")) do
						for Y, d in pairs(R) do
							if Y == "Name" then
								table.insert(FruitStore, d);
							end;
						end;
						Q.Remotes.CommF_:InvokeServer("Cousin", "Buy");
						for Y, R in pairs(FruitPrice) do
							for Y, r in pairs(FruitStore) do
								if R == r and (Q.Remotes.CommF_:InvokeServer("GetUnlockables")).FlamingoAccess == nil then
									_G.StoreF = false;
									if not d.Backpack:FindFirstChild(FruitStore) then
										Q.Remotes.CommF_:InvokeServer("LoadFruit", tostring(R));
									else
										Q.Remotes.CommF_:InvokeServer("TalkTrevor", "1");
										Q.Remotes.CommF_:InvokeServer("TalkTrevor", "2");
										Q.Remotes.CommF_:InvokeServer("TalkTrevor", "3");
									end;
								end;
							end;
						end;
						if (Q.Remotes.CommF_:InvokeServer("GetUnlockables")).FlamingoAccess ~= nil then
							_G.StoreF = true;
							_G.Auto_DonAcces = false;
						end;
					end;
				end;
			end);
		end;
	end;
end);
kF.CreateToggle({
	Title = "Auto Swan Glasses",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.Auto_SwanGG = Y;
	end,
});
task.spawn(function()
	while task.wait(.2) do
		if _G.Auto_SwanGG then
			pcall(function()
				local Y = GetConnectionEnemies("Don Swan");
				if Y then
					repeat
						task.wait();
						f.Kill(Y, _G.Auto_SwanGG);
					until _G.Auto_SwanGG == false or not Y.Parent or Y.Humanoid.Health <= 0;
				else
					_tp(CFrame.new(2286.20043945, 15.17783927, 863.83886718));
				end;
			end);
		end;
	end;
end);
local LF = bz.CreateSection("Cavender + Twin Hooks + Bigmom");
LF.CreateToggle({
	Title = "Auto Bigmom",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.AutoBigmom = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		if _G.AutoBigmom then
			pcall(function()
				local Y = GetConnectionEnemies("Cake Queen");
				if Y then
					repeat
						task.wait();
						f.Kill(Y, _G.AutoBigmom);
					until not _G.AutoBigmom or not Y.Parent or Y.Humanoid.Health <= 0;
				else
					_tp(CFrame.new(-709.3133, 381.6006, -11011.3965));
				end;
			end);
		end;
	end;
end);
LF.CreateToggle({
	Title = "Auto Canvendish Sword",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.Auto_Cavender = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		pcall(function()
			if _G.Auto_Cavender then
				local Y = GetConnectionEnemies("Beautiful Pirate");
				if Y then
					repeat
						task.wait();
						f.Kill(Y, _G.Auto_Cavender);
					until not _G.Auto_Cavender or Y.Humanoid.Health <= 0;
				else
					_tp(CFrame.new(5283.6094, 22.5622, -110.7829));
				end;
			end;
		end);
	end;
end);
LF.CreateToggle({
	Title = "Auto Twin Hooks",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.TwinHook = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		pcall(function()
			if _G.TwinHook then
				local Y = GetConnectionEnemies("Captain Elephant");
				if Y then
					repeat
						task.wait();
						f.Kill(Y, _G.TwinHook);
					until not _G.TwinHook or Y.Humanoid.Health <= 0;
				else
					Q.Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(-12471.1699, 374.9402, -7551.6777));
					task.wait(.2);
					_tp(CFrame.new(-13376.7578, 433.2869, -8071.3926));
				end;
			end;
		end);
	end;
end);
LF.CreateToggle({
	Title = "Auto Serpent Bow",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.AutoSerpentBow = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		if _G.AutoSerpentBow then
			local Y = GetConnectionEnemies("Hydra Leader");
			if Y then
				repeat
					task.wait();
					f.Kill(Y, _G.AutoSerpentBow);
				until not _G.AutoSerpentBow or not Y.Parent or Y.Humanoid.Health <= 0;
			else
				_tp(CFrame.new(5821.898, 1019.0951, -73.7192));
			end;
		end;
	end;
end);
LF.CreateToggle({
	Title = "Auto Lei Accessory",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.AutoKilo = Y;
	end,
});
task.spawn(function()
	while task.wait(.2) do
		if _G.AutoKilo then
			pcall(function()
				local Y = GetConnectionEnemies("Kilo Admiral");
				if Y then
					repeat
						task.wait();
						f.Kill(Y, _G.AutoKilo);
					until not _G.AutoKilo or not Y.Parent or Y.Humanoid.Health <= 0;
				else
					_tp(CFrame.new(2764.2234, 432.4615, -7144.458));
				end;
			end);
		end;
	end;
end);
local PF = cz.CreateSection("Sea Event / Setting Sail");
local jF = {
		"Guardian",
		"PirateGrandBrigade",
		"MarineGrandBrigade",
		"PirateBrigade",
		"MarineBrigade",
		"PirateSloop",
		"MarineSloop",
		"Beast Hunter",
	};
local GF = {
		"Lv 1",
		"Lv 2",
		"Lv 3",
		"Lv 4",
		"Lv 5",
		"Lv 6",
		"Lv Infinite",
	};
local qF = PF.CreateLabel({ Title = " Spy Status ", Content = "" });
task.spawn(function()
	while task.wait(.2) do
		pcall(function()
			local Y = string.match(Q.Remotes.CommF_:InvokeServer("InfoLeviathan", "1"), "%d+");
			if Y then
				qF:SetDesc(" Spy Leviathan  : " .. tostring(Y));
				if tostring(Y) == 5 then
					qF:SetDesc(" Spy Leviathan : Already Done!!");
				end;
			end;
		end);
	end;
end);
PF.CreateButton({ Title = "Buy Fracments with Spy", Callback = function()
		((Q:WaitForChild("Remotes")):WaitForChild("CommF_")):InvokeServer("InfoLeviathan", "2");
	end });
local VF = PF.CreateLabel({ Title = " FlozenDimension Status ", Content = "" });
task.spawn(function()
	pcall(function()
		while task.wait(.2) do
			if workspace._WorldOrigin.Locations:FindFirstChild("Frozen Dimension") then
				VF:SetDesc(" Flozen Dimension : True");
			else
				VF:SetDesc(" Flozen Dimension : False");
			end;
		end;
	end);
end);
PF.CreateToggle({
	Title = "Auto Teleport Frozen Dimension",
	Description = "turn on for teleport to frozen dimension and start the leviathan gate",
	Default = false,
	Callback = function(Y)
		_G.FrozenTP = Y;
	end,
});
task.spawn(function()
	while task.wait(.1) do
		if _G.FrozenTP then
			pcall(function()
				if workspace.Map:FindFirstChild("LeviathanGate") then
					_tp(workspace.Map.LeviathanGate.CFrame);
					((Q:WaitForChild("Remotes")):WaitForChild("CommF_")):InvokeServer("OpenLeviathanGate");
				end;
			end);
		end;
	end;
end);
PF.CreateToggle({
	Title = "Auto Drive To Hydra Island",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.SailBoat_Hydra = Y;
	end,
});
task.spawn(function()
	while task.wait() do
		if _G.SailBoat_Hydra and World3 then
			pcall(function()
				local Y = CheckBoat();
				if not Y then
					local Y = CFrame.new(-16927.451, 9.086, 433.864);
					TeleportToTarget(Y);
					if (Y.Position - d.Character.HumanoidRootPart.Position).Magnitude <= 10 then
						Q.Remotes.CommF_:InvokeServer("BuyBoat", _G.SelectedBoat);
					end;
				elseif Y then
					if d.Character.Humanoid.Sit == false then
						local d = Y.VehicleSeat.CFrame * CFrame.new(0, 1, 0);
						_tp(d);
					else
						repeat
							task.wait();
							if CheckEnemiesBoat() or CheckPirateGrandBrigade() or CheckTerrorShark() then
								_tp(CFrame.new(5433, 150, 290));
							else
								_tp(CFrame.new(5433, 35, 290));
							end;
						until _G.SailBoat_Hydra == false or (d.Character:WaitForChild("Humanoid")).Sit == false;
						d.Character.Humanoid.Sit = false;
					end;
				end;
			end);
		end;
	end;
end);
PF.CreateDropdown({
	Title = "Choose Boats",
	Description = "",
	Values = jF,
	Default = "Guardian",
	Multi = false,
	Callback = function(Y)
		_G.SelectedBoat = Y;
	end,
});
PF.CreateButton({ Title = "Buy Boats", Callback = function()
		Q.Remotes.CommF_:InvokeServer("BuyBoat", _G.SelectedBoat);
	end });
PF.CreateDropdown({
	Title = "Choose Sea Level",
	Description = "",
	Values = GF,
	Default = "Lv 1",
	Multi = false,
	Callback = function(Y)
		_G.DangerSc = Y;
	end,
});
PF.CreateToggle({
	Title = "Auto Sail Boat",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.SailBoats = Y;
	end,
});
task.spawn(function()
	while task.wait() do
		if _G.SailBoats and World3 and false then
			pcall(function()
				local Y = CheckBoat();
				if not Y and (not (CheckShark() and _G.Shark or CheckTerrorShark() and _G.TerrorShark or CheckFishCrew() and _G.MobCrew or CheckPiranha() and _G.Piranha) and (not (CheckEnemiesBoat() and _G.FishBoat) and (not (CheckSeaBeast() and _G.SeaBeast1) and (not (_G.PGB and CheckPirateGrandBrigade()) and (not (_G.HCM and CheckHauntedCrew()) and not (_G.Leviathan1 and CheckLeviathan())))))) then
					local Y = CFrame.new(-16927.451, 9.086, 433.864);
					TeleportToTarget(Y);
					if (Y.Position - d.Character.HumanoidRootPart.Position).Magnitude <= 10 then
						Q.Remotes.CommF_:InvokeServer("BuyBoat", _G.SelectedBoat);
					end;
				elseif Y and (not (CheckShark() and _G.Shark or CheckTerrorShark() and _G.TerrorShark or CheckFishCrew() and _G.MobCrew or CheckPiranha() and _G.Piranha) and (not (CheckEnemiesBoat() and _G.FishBoat) and (not (CheckSeaBeast() and _G.SeaBeast1) and (not (_G.PGB and CheckPirateGrandBrigade()) and (not (_G.HCM and CheckHauntedCrew()) and not (_G.Leviathan1 and CheckLeviathan())))))) then
					if d.Character.Humanoid.Sit == false then
						local d = Y.VehicleSeat.CFrame * CFrame.new(0, 1, 0);
						_tp(d);
					else
						if _G.DangerSc == "Lv 1" then
							CFrameSelectedZone = CFrame.new(-21998.375, 30.0006084, -682.309143);
						elseif _G.DangerSc == "Lv 2" then
							CFrameSelectedZone = CFrame.new(-26779.5215, 30.0005474, -822.858032);
						elseif _G.DangerSc == "Lv 3" then
							CFrameSelectedZone = CFrame.new(-31171.957, 30.0001011, -2256.93774);
						elseif _G.DangerSc == "Lv 4" then
							CFrameSelectedZone = CFrame.new(-34054.6875, 30.2187767, -2560.12012);
						elseif _G.DangerSc == "Lv 5" then
							CFrameSelectedZone = CFrame.new(-38887.5547, 30.0004578, -2162.99023);
						elseif _G.DangerSc == "Lv 6" then
							CFrameSelectedZone = CFrame.new(-44541.7617, 30.0003204, -1244.8584);
						elseif _G.DangerSc == "Lv Infinite" then
							CFrameSelectedZone = CFrame.new(-10000000, 31, 37016.25);
						end;
						repeat
							task.wait();
							if not _G.FishBoat and CheckEnemiesBoat() or not _G.PGB and CheckPirateGrandBrigade() or not _G.TerrorShark and CheckTerrorShark() then
								_tp(CFrameSelectedZone * CFrame.new(0, 150, 0));
							else
								_tp(CFrameSelectedZone);
							end;
						until _G.SailBoats == false or CheckShark() and _G.Shark or CheckTerrorShark() and _G.TerrorShark or CheckFishCrew() and _G.MobCrew or CheckPiranha() and _G.Piranha or CheckSeaBeast() and _G.SeaBeast1 or CheckEnemiesBoat() and _G.FishBoat or _G.Leviathan1 and CheckLeviathan() or _G.HCM and CheckHauntedCrew() or _G.PGB and CheckPirateGrandBrigade() or (d.Character:WaitForChild("Humanoid")).Sit == false;
						d.Character.Humanoid.Sit = false;
					end;
				end;
			end);
		end;
	end;
end);
task.spawn(function()
	while task.wait(T) do
		pcall(function()
			for Y, d in pairs(workspace.Boats:GetChildren()) do
				for Y, d in pairs(workspace.Boats[d.Name]:GetDescendants()) do
					if d:IsA("BasePart") then
						if _G.SailBoats or _G.Prehis_Find or _G.FindMirage or _G.SailBoat_Hydra or _G.AutofindKitIs then
							d.CanCollide = false;
						else
							d.CanCollide = true;
						end;
					end;
				end;
			end;
		end);
	end;
end);
local tF = cz.CreateSection("Entity Sea Event");
tF.CreateToggle({
	Title = "Auto Shark",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.Shark = Y;
	end,
});
tF.CreateToggle({
	Title = "Auto Piranha",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.Piranha = Y;
	end,
});
tF.CreateToggle({
	Title = "Auto Terror Shark",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.TerrorShark = Y;
	end,
});
tF.CreateToggle({
	Title = "Auto Fish Crew Member",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.MobCrew = Y;
	end,
});
tF.CreateToggle({
	Title = "Auto Haunted Crew Member",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.HCM = Y;
	end,
});
tF.CreateToggle({
	Title = "Auto Attack PirateGrandBrigade",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.PGB = Y;
	end,
});
tF.CreateToggle({
	Title = "Auto Attack Fish Boat",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.FishBoat = Y;
	end,
});
tF.CreateToggle({
	Title = "Auto Attack Sea Beast",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.SeaBeast1 = Y;
	end,
});
tF.CreateToggle({
	Title = "Auto Attack Leviathan",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.Leviathan1 = Y;
	end,
});
task.spawn(function()
	while task.wait() do
		pcall(function()
			if World3 then return end;
			if _G.Shark then
				local Y = { "Shark" };
				if CheckShark() then
					for d, R in pairs(workspace.Enemies:GetChildren()) do
						if table.find(Y, R.Name) then
							if f.Alive(R) then
								repeat
									task.wait();
									f.Kill(R, _G.Shark);
								until _G.Shark == false or not R.Parent or R.Humanoid.Health <= 0;
							end;
						end;
					end;
				end;
			end;
			if _G.TerrorShark then
				local Y = { "Terrorshark" };
				if CheckTerrorShark() then
					for d, R in pairs(workspace.Enemies:GetChildren()) do
						if table.find(Y, R.Name) then
							if f.Alive(R) then
								repeat
									task.wait();
									f.KillSea(R, _G.TerrorShark);
								until _G.TerrorShark == false or not R.Parent or R.Humanoid.Health <= 0;
							end;
						end;
					end;
				end;
			end;
			if _G.Piranha then
				local Y = { "Piranha" };
				if CheckPiranha() then
					for d, R in pairs(workspace.Enemies:GetChildren()) do
						if table.find(Y, R.Name) then
							if f.Alive(R) then
								repeat
									task.wait();
									f.Kill(R, _G.Piranha);
								until _G.Piranha == false or not R.Parent or R.Humanoid.Health <= 0;
							end;
						end;
					end;
				end;
			end;
			if _G.MobCrew then
				local Y = { "Fish Crew Member" };
				if CheckFishCrew() then
					for d, R in pairs(workspace.Enemies:GetChildren()) do
						if table.find(Y, R.Name) then
							if f.Alive(R) then
								repeat
									task.wait();
									f.Kill(R, _G.MobCrew);
								until _G.MobCrew == false or not R.Parent or R.Humanoid.Health <= 0;
							end;
						end;
					end;
				end;
			end;
			if _G.HCM then
				local Y = { "Haunted Crew Member" };
				if CheckHauntedCrew() then
					for d, R in pairs(workspace.Enemies:GetChildren()) do
						if table.find(Y, R.Name) then
							if f.Alive(R) then
								repeat
									task.wait();
									f.Kill(R, _G.HCM);
								until _G.HCM == false or not R.Parent or R.Humanoid.Health <= 0;
							end;
						end;
					end;
				end;
			end;
			if _G.SeaBeast1 then
				if workspace.SeaBeasts:FindFirstChild("SeaBeast1") then
					for Y, R in pairs(workspace.SeaBeasts:GetChildren()) do
						if R:FindFirstChild("HumanoidRootPart") and (R:FindFirstChild("Health") and R.Health.Value > 0) then
							repeat
								task.wait();
								task.spawn(function()
									_tp(CFrame.new(R.HumanoidRootPart.Position.X, (game:GetService("Workspace")).Map["WaterBase-Plane"].Position.Y + 200, R.HumanoidRootPart.Position.Z));
								end);
								if d:DistanceFromCharacter(R.HumanoidRootPart.CFrame.Position) <= 500 then
									AitSeaSkill_Custom = R.HumanoidRootPart.CFrame;
									MousePos = AitSeaSkill_Custom.Position;
									if CheckF() then
										weaponSc("Blox Fruit");
										Useskills("Blox Fruit", "Z");
										Useskills("Blox Fruit", "X");
										Useskills("Blox Fruit", "C");
									else
										Useskills("Melee", "Z");
										Useskills("Melee", "X");
										Useskills("Melee", "C");
										task.wait(.1);
										Useskills("Sword", "Z");
										Useskills("Sword", "X");
										task.wait(.1);
										Useskills("Blox Fruit", "Z");
										Useskills("Blox Fruit", "X");
										Useskills("Blox Fruit", "C");
										task.wait(.1);
										Useskills("Gun", "Z");
										Useskills("Gun", "X");
									end;
								end;
							until _G.SeaBeast1 == false or not R:FindFirstChild("HumanoidRootPart") or not R.Parent or R.Health.Value <= 0;
						end;
					end;
				end;
			end;
			if _G.Leviathan1 then
				if workspace.SeaBeasts:FindFirstChild("Leviathan") then
					for Y, R in pairs(workspace.SeaBeasts:GetChildren()) do
						if R:FindFirstChild("HumanoidRootPart") and (R:FindFirstChild("Leviathan Segment") and (R:FindFirstChild("Health") and R.Health.Value > 0)) then
							repeat
								task.wait();
								task.spawn(function()
									_tp(CFrame.new(R.HumanoidRootPart.Position.X, (game:GetService("Workspace")).Map["WaterBase-Plane"].Position.Y + 200, R.HumanoidRootPart.Position.Z));
								end);
								if d:DistanceFromCharacter(R.HumanoidRootPart.CFrame.Position) <= 500 then
									MousePos = (R:FindFirstChild("Leviathan Segment")).Position;
									if CheckF() then
										weaponSc("Blox Fruit");
										Useskills("Blox Fruit", "Z");
										Useskills("Blox Fruit", "X");
										Useskills("Blox Fruit", "C");
									else
										Useskills("Melee", "Z");
										Useskills("Melee", "X");
										Useskills("Melee", "C");
										task.wait(.1);
										Useskills("Sword", "Z");
										Useskills("Sword", "X");
										task.wait(.1);
										Useskills("Blox Fruit", "Z");
										Useskills("Blox Fruit", "X");
										Useskills("Blox Fruit", "C");
										task.wait(.1);
										Useskills("Gun", "Z");
										Useskills("Gun", "X");
									end;
								end;
							until _G.Leviathan1 == false or not R:FindFirstChild("HumanoidRootPart") or not R.Parent or R.Health.Value <= 0;
						end;
					end;
				end;
			end;
			if _G.FishBoat then
				if CheckEnemiesBoat() then
					for Y, R in pairs(workspace.Enemies:GetChildren()) do
						if R:FindFirstChild("Health") and (R.Health.Value > 0 and R:FindFirstChild("VehicleSeat")) then
							repeat
								task.wait();
								task.spawn(function()
									if R.Name == "FishBoat" then
										_tp(R.Engine.CFrame * CFrame.new(0, -50, -25));
									end;
								end);
								if d:DistanceFromCharacter(R.Engine.CFrame.Position) <= 150 then
									AitSeaSkill_Custom = R.Engine.CFrame;
									MousePos = AitSeaSkill_Custom.Position;
									if CheckF() then
										weaponSc("Blox Fruit");
										Useskills("Blox Fruit", "Z");
										Useskills("Blox Fruit", "X");
										Useskills("Blox Fruit", "C");
									else
										Useskills("Melee", "Z");
										Useskills("Melee", "X");
										Useskills("Melee", "C");
										task.wait(.1);
										Useskills("Sword", "Z");
										Useskills("Sword", "X");
										task.wait(.1);
										Useskills("Blox Fruit", "Z");
										Useskills("Blox Fruit", "X");
										Useskills("Blox Fruit", "C");
										task.wait(.1);
										Useskills("Gun", "Z");
										Useskills("Gun", "X");
									end;
								end;
							until _G.FishBoat == false or not R:FindFirstChild("VehicleSeat") or R.Health.Value <= 0;
						end;
					end;
				end;
			end;
			if _G.PGB then
				if CheckPirateGrandBrigade() then
					for Y, R in pairs(workspace.Enemies:GetChildren()) do
						if R:FindFirstChild("Health") and (R.Health.Value > 0 and R:FindFirstChild("VehicleSeat")) then
							repeat
								task.wait();
								task.spawn(function()
									if R.Name == "PirateBrigade" then
										_tp(R.Engine.CFrame * CFrame.new(0, -30, -10));
									elseif R.Name == "PirateGrandBrigade" then
										_tp(R.Engine.CFrame * CFrame.new(0, -50, -50));
									end;
								end);
								if d:DistanceFromCharacter(R.Engine.CFrame.Position) <= 150 then
									AitSeaSkill_Custom = R.Engine.CFrame;
									MousePos = AitSeaSkill_Custom.Position;
									if CheckF() then
										weaponSc("Blox Fruit");
										Useskills("Blox Fruit", "Z");
										Useskills("Blox Fruit", "X");
										Useskills("Blox Fruit", "C");
									else
										Useskills("Melee", "Z");
										Useskills("Melee", "X");
										Useskills("Melee", "C");
										task.wait(.1);
										Useskills("Sword", "Z");
										Useskills("Sword", "X");
										task.wait(.1);
										Useskills("Blox Fruit", "Z");
										Useskills("Blox Fruit", "X");
										Useskills("Blox Fruit", "C");
										task.wait(.1);
										Useskills("Gun", "Z");
										Useskills("Gun", "X");
									end;
								end;
							until _G.PGB == false or not R:FindFirstChild("VehicleSeat") or R.Health.Value <= 0;
						end;
					end;
				end;
			end;
		end);
	end;
end);
local XF = cz.CreateSection("Kitsune Island / Event");
local hF = XF.CreateLabel({ Title = " Kitsune Island Status ", Content = "" });
task.spawn(function()
	while task.wait(.2) do
		if workspace.Map:FindFirstChild("KitsuneIsland") or workspace._WorldOrigin.Locations:FindFirstChild("Kitsune Island") then
			hF:SetDesc(" Kitsune Island : True");
		else
			hF:SetDesc(" Kitsune Island : False");
		end;
	end;
end);
XF.CreateToggle({
	Title = "Auto Find Kitsune Island",
	Description = "turn on for finding & tween kitsune island",
	Default = false,
	Callback = function(Y)
		_G.AutofindKitIs = Y;
	end,
});
task.spawn(function()
	while task.wait() do
		if _G.AutofindKitIs then
			pcall(function()
				if not workspace._WorldOrigin.Locations:FindFirstChild("Kitsune Island", true) then
					local Y = CheckBoat();
					if not Y then
						local Y = CFrame.new(-16927.451, 9.086, 433.864);
						TeleportToTarget(Y);
						if (Y.Position - d.Character.HumanoidRootPart.Position).Magnitude <= 10 then
							Q.Remotes.CommF_:InvokeServer("BuyBoat", _G.SelectedBoat);
						end;
					else
						if d.Character.Humanoid.Sit == false then
							local d = Y.VehicleSeat.CFrame * CFrame.new(0, 1, 0);
							_tp(d);
						else
							local Y = CFrame.new(-10000000, 31, 37016.25);
							repeat
								task.wait();
								if CheckEnemiesBoat() or CheckTerrorShark() or CheckPirateGrandBrigade() then
									_tp(CFrame.new(-10000000, 150, 37016.25));
								else
									_tp(CFrame.new(-10000000, 31, 37016.25));
								end;
							until not _G.AutofindKitIs or (Y.Position - d.Character.HumanoidRootPart.Position).Magnitude <= 10 or workspace._WorldOrigin.Locations:FindFirstChild("Kitsune Island") or d.Character.Humanoid.Sit == false;
							d.Character.Humanoid.Sit = false;
						end;
					end;
				else
					_tp((workspace._WorldOrigin.Locations:FindFirstChild("Kitsune Island")).CFrame * CFrame.new(0, 500, 0));
				end;
			end);
		end;
	end;
end);
XF.CreateToggle({
	Title = "Auto Teleport to Shrine Actived",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.tweenShrine = Y;
	end,
});
task.spawn(function()
	while task.wait(.1) do
		if _G.tweenShrine then
			pcall(function()
				local Y = workspace.Map:FindFirstChild("KitsuneIsland") or game.Workspace._WorldOrigin.Locations:FindFirstChild("Kitsune Island");
				local d = Y:FindFirstChild("ShrineActive");
				if d then
					for d, R in next, d:GetDescendants() do
						if R:IsA("BasePart") and R.Name:find("NeonShrinePart") then
							(Q.Modules.Net:FindFirstChild("RE/TouchKitsuneStatue")):FireServer();
							repeat
								task.wait();
								_tp(R.CFrame * CFrame.new(0, 2, 0));
							until _G.tweenShrine == false or not Y;
						end;
					end;
				else
					_tp((workspace._WorldOrigin.Locations:FindFirstChild("Kitsune Island")).CFrame * CFrame.new(0, 500, 0));
				end;
			end);
		end;
	end;
end);
XF.CreateToggle({
	Title = "Auto Collect Azure Ember",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.Collect_Ember = Y;
	end,
});
task.spawn(function()
	while task.wait(.1) do
		if _G.Collect_Ember then
			pcall(function()
				if workspace:WaitForChild("AttachedAzureEmber") or workspace:WaitForChild("EmberTemplate") then
					notween(((workspace:WaitForChild("EmberTemplate")):FindFirstChild("Part")).CFrame);
				else
					_tp((workspace._WorldOrigin.Locations:FindFirstChild("Kitsune Island")).CFrame * CFrame.new(0, 500, 0));
					Q.Modules.Net["RF/KitsuneStatuePray"]:InvokeServer();
				end;
			end);
		end;
	end;
end);
XF.CreateToggle({
	Title = "Auto Trade Azure Ember",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.Trade_Ember = Y;
	end,
});
task.spawn(function()
	while task.wait(.1) do
		if _G.Trade_Ember then
			pcall(function()
				if workspace._WorldOrigin.Locations:FindFirstChild("Kitsune Island", true) then
					(Q.Modules.Net:FindFirstChild("RF/KitsuneStatuePray")):InvokeServer();
				end;
			end);
		end;
	end;
end);
XF.CreateButton({ Title = "Trade Items Azure", Callback = function()
		(Q.Modules.Net:FindFirstChild("RF/KitsuneStatuePray")):InvokeServer();
	end });
XF.CreateButton({ Title = "Talk with kitsune statue", Callback = function()
		(Q.Modules.Net:FindFirstChild("RE/TouchKitsuneStatue")):FireServer();
	end });
local BF = Hz.CreateSection("Mystic Island / Full Moon");
FullMOOn = BF.CreateLabel({ Title = " FullMoon Status ", Content = "" });
Ismirage = BF.CreateLabel({ Title = " Mirage Island Status ", Content = "" });
task.spawn(function()
	while task.wait(.2) do
		if workspace.Map:FindFirstChild("MysticIsland") or workspace._WorldOrigin.Locations:FindFirstChild("Mirage Island") then
			Ismirage:SetDesc(" Mirage Island : True");
		else
			Ismirage:SetDesc(" Mirage Island : False");
		end;
	end;
end);
task.spawn(function()
	while task.wait(.2) do
		pcall(function()
			moon8 = "http://www.roblox.com/asset/?id=9709150401";
			moon7 = "http://www.roblox.com/asset/?id=9709150086";
			moon6 = "http://www.roblox.com/asset/?id=9709149680";
			moon5 = "http://www.roblox.com/asset/?id=9709149431";
			moon4 = "http://www.roblox.com/asset/?id=9709149052";
			moon3 = "http://www.roblox.com/asset/?id=9709143733";
			moon2 = "http://www.roblox.com/asset/?id=9709139597";
			moon1 = "http://www.roblox.com/asset/?id=9709135895";
			moon = Getmoon();
			if moon == moon1 then
				FullMOOn:SetDesc("Moon : 0 / 8");
			elseif moon == moon2 then
				FullMOOn:SetDesc("Moon : 1 / 8");
			elseif moon == moon3 then
				FullMOOn:SetDesc("Moon : 2 / 8");
			elseif moon == moon4 then
				FullMOOn:SetDesc("Moon : 3 / 8 [ Next Night ]");
			elseif moon == moon5 then
				FullMOOn:SetDesc("Moon : 4 / 8 [ Full Moon ]");
			elseif moon == moon6 then
				FullMOOn:SetDesc("Moon : 5 / 8 [ Last Night ]");
			elseif moon == moon7 then
				FullMOOn:SetDesc("Moon : 6 / 8");
			elseif moon == moon8 then
				FullMOOn:SetDesc("Moon : 7 / 8");
			end;
		end);
	end;
end);
BF.CreateToggle({
	Title = "Auto Find Mirage Island",
	Description = "turn on for finding & tween mirage island",
	Default = false,
	Callback = function(Y)
		_G.FindMirage = Y;
	end,
});
task.spawn(function()
	while task.wait() do
		if _G.FindMirage then
			pcall(function()
				if not workspace._WorldOrigin.Locations:FindFirstChild("Mirage Island", true) then
					local Y = CheckBoat();
					if not Y then
						local Y = CFrame.new(-16927.451, 9.086, 433.864);
						TeleportToTarget(Y);
						if (Y.Position - d.Character.HumanoidRootPart.Position).Magnitude <= 10 then
							Q.Remotes.CommF_:InvokeServer("BuyBoat", _G.SelectedBoat);
						end;
					else
						if d.Character.Humanoid.Sit == false then
							local d = Y.VehicleSeat.CFrame * CFrame.new(0, 1, 0);
							_tp(d);
						else
							repeat
								task.wait();
								local Y = CFrame.new(-10000000, 31, 37016.25);
								if CheckEnemiesBoat() or CheckTerrorShark() or CheckPirateGrandBrigade() then
									_tp(CFrame.new(-10000000, 150, 37016.25));
								else
									_tp(CFrame.new(-10000000, 31, 37016.25));
								end;
							until not _G.FindMirage or (Y.Position - d.Character.HumanoidRootPart.Position).Magnitude <= 10 or workspace._WorldOrigin.Locations:FindFirstChild("Mirage Island") or d.Character.Humanoid.Sit == false;
							d.Character.Humanoid.Sit = false;
						end;
					end;
				else
					_tp(workspace.Map.MysticIsland.Center.CFrame * CFrame.new(0, 300, 0));
				end;
			end);
		end;
	end;
end);
BF.CreateToggle({
	Title = "Auto Tween To Highest Point",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.HighestMirage = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		if _G.HighestMirage then
			pcall(function()
				if workspace._WorldOrigin.Locations:FindFirstChild("Mirage Island", true) then
					_tp(workspace.Map.MysticIsland.Center.CFrame * CFrame.new(0, 400, 0));
				end;
			end);
		end;
	end;
end);
BF.CreateToggle({
	Title = "Auto Collect Gear",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.TPGEAR = Y;
	end,
});
task.spawn(function()
	pcall(function()
		while task.wait(.1) do
			if _G.TPGEAR then
				for Y, d in pairs((workspace.Map:FindFirstChild("MysticIsland")):GetChildren()) do
					if d.Name == "Part" and d.ClassName == "MeshPart" then
						_tp(d.CFrame);
					end;
				end;
			end;
		end;
	end);
end);
BF.CreateToggle({
	Title = "Change Transparency can see",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.can = Y;
	end,
});
task.spawn(function()
	pcall(function()
		while task.wait(T) do
			if _G.can then
				for Y, d in pairs((workspace.Map:FindFirstChild("MysticIsland")):GetChildren()) do
					if d.Name == "Part" then
						if d.ClassName == "MeshPart" then
							d.Transparency = 0;
						else
							d.Transparency = 1;
						end;
					end;
				end;
			end;
		end;
	end);
end);
BF.CreateToggle({
	Title = "Auto Tween Advanced Fruit Dealer",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.Addealer = Y;
	end,
});
task.spawn(function()
	while task.wait() do
		if _G.Addealer then
			pcall(function()
				for Y, d in pairs(Q.NPCs:GetChildren()) do
					if d.Name == "Advanced Fruit Dealer" then
						_tp(d.HumanoidRootPart.CFrame);
					end;
				end;
			end);
		end;
	end;
end);
BF.CreateToggle({
	Title = "Auto Collect Mirage Chest",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.FarmChestM = Y;
	end,
});
task.spawn(function()
	while task.wait(.2) do
		if _G.FarmChestM then
			pcall(function()
				if workspace.Map.MysticIsland.Chests:FindFirstChild("DiamondChest") or workspace.Map.MysticIsland.Chests:FindFirstChild("FragChest") then
					local Y = game:GetService("CollectionService");
					local d = game:GetService("Players");
					local R = d.LocalPlayer;
					local Q = R.Character or R.CharacterAdded:Wait();
					if not Q then
						return;
					end;
					local r = (Q:GetPivot()).Position;
					local a = Y:GetTagged("_ChestTagged");
					local w, F = math.huge, nil;
					for Y = 1, #a, 1 do
						local d = a[Y];
						local R = ((d:GetPivot()).Position - r).Magnitude;
						if not SelectedIsland or d:IsDescendantOf(SelectedIsland) then
							if not d:GetAttribute("IsDisabled") and R < w then
								w = R;
								F = d;
							end;
						end;
					end;
					if F then
						_tp(F:GetPivot());
					end;
				end;
			end);
		end;
	end;
end);
local lF = Hz.CreateSection("Skull Guitars / Misc");
local pF = lF.CreateLabel({ Title = " Skull Guitar Quests ", Content = "" });
task.spawn(function()
	while task.wait(.2) do
		pcall(function()
			if Quest1 == true then
				pF:SetDesc(" Quest Number : Quest1");
			elseif Quest2 == true then
				pF:SetDesc(" Quest Number : Quest2");
			elseif Quest3 == true then
				pF:SetDesc(" Quest Number : Quest3");
			elseif Quest4 == true then
				pF:SetDesc(" Quest Number : Quest4");
			elseif GetWP("Skull Guitar") then
				pF:SetDesc(" Quest Number : Collect!!");
			else
				pF:SetDesc(" Quest Number : No Quest!!");
			end;
		end);
	end;
end);
lF.CreateToggle({
	Title = "Auto Skull Guitar",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.Auto_Soul_Guitar = Y;
	end,
});
task.spawn(function()
	while task.wait() do
		if _G.Auto_Soul_Guitar then
			pcall(function()
				local Y = GetConnectionEnemies("Living Zombie");
				if Y then
					Y.HumanoidRootPart.CFrame = CFrame.new(-10138.39746093, 138.65246582, 5902.89208984);
					Y.Head.CanCollide = false;
					Y.Humanoid.Sit = false;
					Y.HumanoidRootPart.CanCollide = false;
					Y.Humanoid.JumpPower = 0;
					Y.Humanoid.WalkSpeed = 0;
					if Y.Humanoid:FindFirstChild("Animator") then
						(Y.Humanoid:FindFirstChild("Animator")):Destroy();
					end;
				end;
			end);
		end;
	end;
end);
function getT(Y)
	local d;
	if Y == 1 then
		d = workspace.Map["Haunted Castle"].Tablet.Segment1.Line.Rotation;
	elseif Y == 3 then
		d = workspace.Map["Haunted Castle"].Tablet.Segment3.Line.Rotation;
	elseif Y == 4 then
		d = workspace.Map["Haunted Castle"].Tablet.Segment4.Line.Rotation;
	elseif Y == 7 then
		d = workspace.Map["Haunted Castle"].Tablet.Segment7.Line.Rotation;
	elseif Y == 10 then
		d = workspace.Map["Haunted Castle"].Tablet.Segment10.Line.Rotation;
	end;
	if d then
		return d.Z;
	end;
end;
function getRT(Y)
	local d = workspace.Map["Haunted Castle"].Trophies.Quest;
	local R;
	for d, Q in pairs(d:GetChildren()) do
		if Y == 1 and (Q.Name == "Trophy1" and Q:FindFirstChild("Handle")) then
			R = Q.Handle.Rotation;
		elseif Y == 2 and (Q.Name == "Trophy2" and Q:FindFirstChild("Handle")) then
			R = Q.Handle.Rotation;
		elseif Y == 3 and (Q.Name == "Trophy3" and Q:FindFirstChild("Handle")) then
			R = Q.Handle.Rotation;
		elseif Y == 4 and (Q.Name == "Trophy4" and Q:FindFirstChild("Handle")) then
			R = Q.Handle.Rotation;
		elseif Y == 5 and (Q.Name == "Trophy5" and Q:FindFirstChild("Handle")) then
			R = Q.Handle.Rotation;
		end;
		if R then
			return R.Z;
		end;
	end;
end;
GetFirePlacard = function(Y, d)
		if tostring(workspace.Map["Haunted Castle"]["Placard" .. Y][d].Indicator.BrickColor) ~= "Pearl" then
			fireclickdetector(workspace.Map["Haunted Castle"]["Placard" .. Y][d].ClickDetector);
		end;
	end;
task.spawn(function()
	repeat
		task.wait();
	until _G.Auto_Soul_Guitar;
	while task.wait(T) do
		pcall(function()
			if _G.Auto_Soul_Guitar then
				if World3 then
					Q.Remotes.CommF_:InvokeServer("gravestoneEvent", 2);
					Q.Remotes.CommF_:InvokeServer("gravestoneEvent", 2, true);
					if Q.Remotes.CommF_:InvokeServer("GuitarPuzzleProgress", "Check") == nil then
						_tp(CFrame.new(-8655.01660156, 141.31669616, 6160.02246093));
						Q.Remotes.CommF_:InvokeServer("gravestoneEvent", 2);
						Q.Remotes.CommF_:InvokeServer("gravestoneEvent", 2, true);
					elseif (Q.Remotes.CommF_:InvokeServer("GuitarPuzzleProgress", "Check")).Swamp == false then
						Quest1 = true;
						Quest2 = false;
						Quest3 = false;
						Quest4 = false;
						local Y = GetConnectionEnemies("Living Zombie");
						if Y then
							repeat
								task.wait();
								f.Kill(Y, _G.Auto_Soul_Guitar);
							until not _G.Auto_Soul_Guitar or Y.Humanoid.Health <= 0 or not Y.Parent or workspace.Map["Haunted Castle"].SwampWater.Color ~= Color3.fromRGB(117, 0, 0);
						else
							_tp(CFrame.new(-10170.72753906, 138.65246582, 5934.26513671));
						end;
					elseif (Q.Remotes.CommF_:InvokeServer("GuitarPuzzleProgress", "Check")).Gravestones == false then
						Quest1 = false;
						Quest2 = true;
						Quest3 = false;
						Quest4 = false;
						GetFirePlacard("7", "Left");
						GetFirePlacard("6", "Left");
						GetFirePlacard("5", "Left");
						GetFirePlacard("4", "Right");
						GetFirePlacard("3", "Left");
						GetFirePlacard("2", "Right");
						GetFirePlacard("1", "Right");
					elseif (Q.Remotes.CommF_:InvokeServer("GuitarPuzzleProgress", "Check")).Ghost == false then
						Q.Remotes.CommF_:InvokeServer("GuitarPuzzleProgress", "Ghost");
						Q.Remotes.CommF_:InvokeServer("GuitarPuzzleProgress", "Ghost", true);
					elseif (Q.Remotes.CommF_:InvokeServer("GuitarPuzzleProgress", "Check")).Trophies == false then
						Quest1 = false;
						Quest2 = false;
						Quest3 = true;
						Quest4 = false;
						_tp(CFrame.new(-9532.82324218, 6.47166776, 6078.06835937));
						repeat
							task.wait();
							local Y = getRT(1);
							local d = getT(1);
							if Y and d then
								fireclickdetector(workspace.Map["Haunted Castle"].Tablet.Segment1:FindFirstChild("ClickDetector"));
							end;
						until Y == d;
						repeat
							task.wait();
							local Y = getRT(2);
							local d = getT(3);
							if Y and d then
								fireclickdetector(workspace.Map["Haunted Castle"].Tablet.Segment3:FindFirstChild("ClickDetector"));
							end;
						until Y == d;
						repeat
							task.wait();
							local Y = getRT(3);
							local d = getT(4);
							if Y and d then
								fireclickdetector(workspace.Map["Haunted Castle"].Tablet.Segment4:FindFirstChild("ClickDetector"));
							end;
						until Y == d;
						repeat
							task.wait();
							local Y = getRT(4);
							local d = getT(7);
							if Y and d then
								fireclickdetector(workspace.Map["Haunted Castle"].Tablet.Segment7:FindFirstChild("ClickDetector"));
							end;
						until Y == d;
						repeat
							task.wait();
							local Y = getRT(5);
							local d = getT(10);
							if Y and d then
								fireclickdetector(workspace.Map["Haunted Castle"].Tablet.Segment10:FindFirstChild("ClickDetector"));
							end;
						until Y == d;
						repeat
							task.wait();
							fireclickdetector(workspace.Map["Haunted Castle"].Tablet.Segment2:FindFirstChild("ClickDetector"));
							fireclickdetector(workspace.Map["Haunted Castle"].Tablet.Segment5:FindFirstChild("ClickDetector"));
							fireclickdetector(workspace.Map["Haunted Castle"].Tablet.Segment6:FindFirstChild("ClickDetector"));
							fireclickdetector(workspace.Map["Haunted Castle"].Tablet.Segment8:FindFirstChild("ClickDetector"));
							fireclickdetector(workspace.Map["Haunted Castle"].Tablet.Segment9:FindFirstChild("ClickDetector"));
						until workspace.Map["Haunted Castle"].Tablet.Segment2.Line.Rotation.Z == 0 or workspace.Map["Haunted Castle"].Tablet.Segment5.Line.Rotation.Z == 0 or workspace.Map["Haunted Castle"].Tablet.Segment6.Line.Rotation.Z == 0 or workspace.Map["Haunted Castle"].Tablet.Segment8.Line.Rotation.Z == 0 or workspace.Map["Haunted Castle"].Tablet.Segment9.Line.Rotation.Z == 0;
					elseif (Q.Remotes.CommF_:InvokeServer("GuitarPuzzleProgress", "Check")).Pipes == false then
						Quest1 = false;
						Quest2 = false;
						Quest3 = false;
						Quest4 = true;
						_tp(workspace.Map["Haunted Castle"]["Lab Puzzle"].ColorFloor.Model.Part3.CFrame);
						fireclickdetector(workspace.Map["Haunted Castle"]["Lab Puzzle"].ColorFloor.Model.Part3.ClickDetector);
						_tp(workspace.Map["Haunted Castle"]["Lab Puzzle"].ColorFloor.Model.Part4.CFrame);
						fireclickdetector(workspace.Map["Haunted Castle"]["Lab Puzzle"].ColorFloor.Model.Part4.ClickDetector);
						fireclickdetector(workspace.Map["Haunted Castle"]["Lab Puzzle"].ColorFloor.Model.Part4.ClickDetector);
						fireclickdetector(workspace.Map["Haunted Castle"]["Lab Puzzle"].ColorFloor.Model.Part4.ClickDetector);
						_tp(workspace.Map["Haunted Castle"]["Lab Puzzle"].ColorFloor.Model.Part6.CFrame);
						fireclickdetector(workspace.Map["Haunted Castle"]["Lab Puzzle"].ColorFloor.Model.Part6.ClickDetector);
						fireclickdetector(workspace.Map["Haunted Castle"]["Lab Puzzle"].ColorFloor.Model.Part6.ClickDetector);
						_tp(workspace.Map["Haunted Castle"]["Lab Puzzle"].ColorFloor.Model.Part8.CFrame);
						fireclickdetector(workspace.Map["Haunted Castle"]["Lab Puzzle"].ColorFloor.Model.Part8.ClickDetector);
						_tp(workspace.Map["Haunted Castle"]["Lab Puzzle"].ColorFloor.Model.Part10.CFrame);
						fireclickdetector(workspace.Map["Haunted Castle"]["Lab Puzzle"].ColorFloor.Model.Part10.ClickDetector);
						fireclickdetector(workspace.Map["Haunted Castle"]["Lab Puzzle"].ColorFloor.Model.Part10.ClickDetector);
						fireclickdetector(workspace.Map["Haunted Castle"]["Lab Puzzle"].ColorFloor.Model.Part10.ClickDetector);
					end;
				end;
			end;
		end);
	end;
end);
lF.CreateToggle({
	Title = "Auto Farm Material Skull Guitar",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.AutoMatSoul = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		pcall(function()
			if _G.AutoMatSoul and GetWP("Skull Guitar") == false then
				if GetM("Bones") >= 500 and (GetM("Ectoplasm") >= 250 and GetM("Dark Fragment") >= 1) then
					Q.Remotes.CommF_:InvokeServer("soulGuitarBuy", true);
				else
					if GetM("Ectoplasm") <= 250 then
						if _G.AutoMatSoul and World2 then
							local Y = {
									"Ship Deckhand",
									"Ship Engineer",
									"Ship Steward",
									"Ship Officer",
									"Arctic Warrior",
								};
							local d = GetConnectionEnemies(Y);
							if d then
								repeat
									task.wait();
									f.Kill(d, _G.AutoMatSoul);
								until not _G.AutoMatSoul or not d.Parent or d.Humanoid.Health <= 0;
							else
								Q.Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(923.21252441, 126.97600555, 32852.83203125));
							end;
						else
							Q.Remotes.CommF_:InvokeServer("TravelDressrosa");
						end;
					elseif GetM("Dark Fragment") < 1 then
						if _G.AutoMatSoul and World2 then
							local Y = GetConnectionEnemies("Darkbeard");
							if Y then
								repeat
									task.wait();
									f.Kill(Y, _G.AutoMatSoul);
								until not _G.AutoMatSoul or not Y.Parent or Y.Humanoid.Health <= 0;
							else
								_tp(CFrame.new(3798.45751953, 13.82669067, -3399.80664062));
							end;
						else
							Q.Remotes.CommF_:InvokeServer("TravelDressrosa");
						end;
						if not GetConnectionEnemies("Darkbeard") then
							Hop();
						end;
					elseif GetM("Bones") <= 500 then
						if _G.AutoMatSoul and World3 then
							local Y = {
									"Reborn Skeleton",
									"Living Zombie",
									"Demonic Soul",
									"Posessed Mummy",
								};
							local d = GetConnectionEnemies(Y);
							if d then
								repeat
									task.wait();
									f.Kill(d, _G.AutoMatSoul);
								until not _G.AutoMatSoul or d.Humanoid.Health <= 0 or not d.Parent or d.Humanoid.Health <= 0;
							else
								_tp(CFrame.new(-9504.85644531, 172.14292907, 6057.25976562));
							end;
						else
							Q.Remotes.CommF_:InvokeServer("TravelZou");
						end;
					end;
				end;
			end;
		end);
	end;
end);
lF.CreateButton({ Title = "Talk With Stone", Callback = function()
		((Q:WaitForChild("Remotes")):WaitForChild("CommF_")):InvokeServer("RaceV4Progress", "Begin");
		((Q:WaitForChild("Remotes")):WaitForChild("CommF_")):InvokeServer("RaceV4Progress", "Check");
		((Q:WaitForChild("Remotes")):WaitForChild("CommF_")):InvokeServer("RaceV4Progress", "Teleport");
		((Q:WaitForChild("Remotes")):WaitForChild("CommF_")):InvokeServer("RaceV4Progress", "Continue");
	end });
lF.CreateToggle({
	Title = "Auto Look At Moon",
	Description = "",
	Default = false,
	Callback = function(Y)
		LookM = Y;
	end,
});
function MoveCamtoMoon()
	workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position, F:GetMoonDirection() + workspace.CurrentCamera.CFrame.Position);
	d.Character.HumanoidRootPart.CFrame = CFrame.new(d.Character.HumanoidRootPart.Position, F:GetMoonDirection() + d.Character.HumanoidRootPart.CFrame.Position);
end;
task.spawn(function()
	while task.wait() do
		if LookM then
			MoveCamtoMoon();
			task.wait(.1);
			Q.Remotes.CommE:FireServer("ActivateAbility");
		end;
	end;
end);
local EF = Hz.CreateSection("Trials Quests / Misc V4");
local eF = EF.CreateLabel({ Title = " Tiers V4 Status ", Content = "" });
task.spawn(function()
	pcall(function()
		while task.wait(.2) do
			eF:SetDesc(" Tiers - V4  :" .. (" " .. d.Data.Race.C.Value));
		end;
	end);
end);
EF.CreateToggle({
	Title = "Auto Pull Lever",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.Lver = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		if _G.Lver then
			pcall(function()
				for Y, d in pairs(workspace.Map["Temple of Time"]:GetDescendants()) do
					if d.Name == "ProximityPrompt" then
						fireproximityprompt(d, math.huge);
					end;
				end;
			end);
		end;
	end;
end);
EF.CreateToggle({
	Title = "Auto Train V4",
	Description = "turn on for farm tier + auto upgrade your tier level",
	Default = false,
	Callback = function(Y)
		_G.AcientOne = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		pcall(function()
			if _G.AcientOne then
				local Y = {
						"Reborn Skeleton",
						"Living Zombie",
						"Demonic Soul",
						"Posessed Mummy",
					};
				for R = 1, #Y, 1 do
					if (d.Character:FindFirstChild("RaceEnergy")).Value == 1 then
						K:SendKeyEvent(true, "Y", false, game);
						Q.Remotes.CommF_:InvokeServer("UpgradeRace", "Buy");
						_tp(CFrame.new(-8987.04101562, 215.86206054, 5886.71044921));
					elseif (d.Character:FindFirstChild("RaceTransformed")).Value == false then
						local d = GetConnectionEnemies(Y);
						if d then
							repeat
								task.wait();
								f.Kill(d, _G.AcientOne);
							until _G.AcientOne == false or d.Humanoid.Health <= 0 or not d.Parent;
						else
							_tp(CFrame.new(-9495.68066406, 453.58624267, 5977.34863281));
						end;
					end;
				end;
			end;
		end);
	end;
end);
EF.CreateButton({ Title = "Teleport to Temple of Time", Callback = function()
		TpTemple();
	end });
function TpTemple()
	local Y = (game.ReplicatedStorage:WaitForChild("MapStash")):FindFirstChild("Temple of Time");
	(game:GetService("Players")).LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(28286, 14897, 103);
	if Y then
		Y.Parent = workspace:WaitForChild("Map");
	end;
end;
EF.CreateButton({ Title = "Teleport to Ancient One", Callback = function()
		TpTemple();
		notween(CFrame.new(28981.55273437, 14888.42675781, -120.24584960));
	end });
EF.CreateButton({ Title = "Teleport to Ancient Clock", Callback = function()
		TpTemple();
		notween(CFrame.new(29549, 15069, -88));
	end });
EF.CreateToggle({
	Title = "Auto Teleport to Race Doors",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.TPDoor = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		pcall(function()
			if _G.TPDoor then
				if tostring(d.Data.Race.Value) == "Mink" then
					_tp(CFrame.new(29020.66015625, 14889.42675781, -379.26828002));
				elseif tostring(d.Data.Race.Value) == "Fishman" then
					_tp(CFrame.new(28224.05664062, 14889.42675781, -210.58720397));
				elseif tostring(d.Data.Race.Value) == "Cyborg" then
					_tp(CFrame.new(28492.4140625, 14894.42675781, -422.11001586));
				elseif tostring(d.Data.Race.Value) == "Skypiea" then
					_tp(CFrame.new(28967.40820312, 14918.07519531, 234.31198120));
				elseif tostring(d.Data.Race.Value) == "Ghoul" then
					_tp(CFrame.new(28672.72070312, 14889.12792968, 454.59616088));
				elseif tostring(d.Data.Race.Value) == "Human" then
					_tp(CFrame.new(29237.29492187, 14889.42675781, -206.94955444));
				end;
			end;
		end);
	end;
end);
EF.CreateToggle({
	Title = "Auto Complete Trial Race",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.Complete_Trials = Y;
	end,
});
GetSeaBeastTrial = function()
		if not workspace.Map:FindFirstChild("FishmanTrial") then
			return nil;
		end;
		if workspace._WorldOrigin.Locations:FindFirstChild("Trial of Water") then
			FishmanTrial = workspace._WorldOrigin.Locations:FindFirstChild("Trial of Water");
		end;
		if FishmanTrial then
			for Y, d in next, workspace.SeaBeasts:GetChildren() do
				if d:FindFirstChild("HumanoidRootPart") and (d.HumanoidRootPart.Position - FishmanTrial.Position).Magnitude <= 1500 then
					if d.Health.Value > 0 then
						return d;
					end;
				end;
			end;
		end;
	end;
task.spawn(function()
	while task.wait(T) do
		pcall(function()
			if _G.Complete_Trials then
				if tostring(d.Data.Race.Value) == "Mink" then
					notween(workspace.Map.MinkTrial.Ceiling.CFrame * CFrame.new(0, -20, 0));
				end;
			end;
		end);
	end;
end);
task.spawn(function()
	while task.wait(T) do
		pcall(function()
			if _G.Complete_Trials then
				if tostring(d.Data.Race.Value) == "Fishman" then
					if GetSeaBeastTrial() then
						repeat
							task.wait();
							task.spawn(function()
								_tp(CFrame.new((GetSeaBeastTrial()).HumanoidRootPart.Position.X, (game:GetService("Workspace")).Map["WaterBase-Plane"].Position.Y + 300, (GetSeaBeastTrial()).HumanoidRootPart.Position.Z));
							end);
							MousePos = (GetSeaBeastTrial()).HumanoidRootPart.Position;
							Useskills("Melee", "Z");
							Useskills("Melee", "X");
							Useskills("Melee", "C");
							task.wait(.1);
							Useskills("Sword", "Z");
							Useskills("Sword", "X");
							task.wait(.1);
							Useskills("Blox Fruit", "Z");
							Useskills("Blox Fruit", "X");
							Useskills("Blox Fruit", "C");
							task.wait(.1);
							Useskills("Gun", "Z");
							Useskills("Gun", "X");
						until _G.Complete_Trials == false or not GetSeaBeastTrial();
					end;
				end;
			end;
		end);
	end;
end);
task.spawn(function()
	while task.wait(T) do
		pcall(function()
			if _G.Complete_Trials then
				if tostring(d.Data.Race.Value) == "Cyborg" then
					_tp(workspace.Map.CyborgTrial.Floor.CFrame * CFrame.new(0, 500, 0));
				end;
			end;
		end);
	end;
end);
task.spawn(function()
	while task.wait(T) do
		pcall(function()
			if _G.Complete_Trials then
				if tostring(d.Data.Race.Value) == "Skypiea" then
					notween(workspace.Map.SkyTrial.Model.FinishPart.CFrame);
				end;
			end;
		end);
	end;
end);
task.spawn(function()
	while task.wait(.1) do
		pcall(function()
			if _G.Complete_Trials then
				if tostring(d.Data.Race.Value) == "Human" or tostring(d.Data.Race.Value) == "Ghoul" then
					local Y = { "Ancient Vampire", "Ancient Zombie" };
					local d = GetConnectionEnemies(Y);
					if d then
						repeat
							task.wait();
							f.Kill(d, _G.Complete_Trials);
						until _G.Complete_Trials == false or not d.Parent or d.Humanoid.Health <= 0;
					end;
				end;
			end;
		end);
	end;
end);
EF.CreateToggle({
	Title = "Auto Kill Player After Trial",
	Description = "turn on for kill player after the race trials",
	Default = false,
	Callback = function(Y)
		_G.Defeating = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		pcall(function()
			if _G.Defeating then
				for Y, Q in pairs(workspace.Characters:GetChildren()) do
					if Q.Name ~= d.Name then
						if Q.Humanoid.Health > 0 and (Q:FindFirstChild("HumanoidRootPart") and (Q.Parent and (R.Position - Q.HumanoidRootPart.Position).Magnitude <= 250)) then
							repeat
								task.wait();
								EquipWeapon(_G.SelectWeapon);
								_tp(Q.HumanoidRootPart.CFrame * CFrame.new(0, 0, 15));
								sethiddenproperty(d, "SimulationRadius", math.huge);
							until _G.Defeating == false or Q.Humanoid.Health <= 0 or not Q.Parent or not Q:FindFirstChild("HumanoidRootPart") or not Q:FindFirstChild("Humanoid");
						end;
					end;
				end;
			end;
		end);
	end;
end);
local OF = Sz.CreateSection("Dojo Quest & Drago Race");
OF.CreateToggle({
	Title = "Auto Dojo Trainer",
	Description = "turn on for do dojo belt quest white to black",
	Default = false,
	Callback = function(Y)
		_G.Dojoo = Y;
	end,
});
function printBeltName(Y)
	if type(Y) == "table" and Y.Quest.BeltName then
		return Y.Quest.BeltName;
	end;
end;
task.spawn(function()
	while task.wait(T) do
		if _G.Dojoo then
			pcall(function()
				local Y = { [1] = { NPC = "Dojo Trainer", Command = "RequestQuest" } };
				local R = (Q.Modules.Net:FindFirstChild("RF/InteractDragonQuest")):InvokeServer(unpack(Y));
				local r = printBeltName(R);
				if H == false and (not R and not r) then
					_tp(CFrame.new(5865.0234375, 1208.31542968, 871.15185546));
					H = true;
				elseif H == true and ((CFrame.new(5865.0234375, 1208.31542968, 871.15185546)).Position - d.Character.HumanoidRootPart.Position).Magnitude <= 50 then
					if r == "White" then
						local Y = GetConnectionEnemies("Skull Slayer");
						if Y then
							repeat
								task.wait();
								f.Kill(Y, _G.Dojoo);
							until not R or not _G.Dojoo or not f.Alive(Y);
						else
							_tp(CFrame.new(-16759.58984375, 71.28376770, 1595.33996582));
						end;
					elseif r == "Yellow" then
						repeat
							task.wait();
							_G.SeaBeast1 = true;
							_G.TerrorShark = true;
							_G.Shark = true;
							_G.Piranha = true;
							_G.MobCrew = true;
							_G.FishBoat = true;
							_G.SailBoats = true;
						until not _G.Dojoo or not R;
						_G.SeaBeast1 = false;
						_G.TerrorShark = false;
						_G.Shark = false;
						_G.Piranha = false;
						_G.MobCrew = false;
						_G.FishBoat = false;
						_G.SailBoats = false;
					elseif r == "Green" then
						repeat
							task.wait();
							_G.SailBoats = true;
						until not _G.Dojoo or not R;
						_G.SailBoats = false;
					elseif r == "Purple" then
						repeat
							task.wait();
							_G.FarmEliteHunt = true;
						until not _G.Dojoo or not R;
						_G.FarmEliteHunt = false;
					elseif r == "Red" then
						repeat
							task.wait();
							_G.SailBoats = true;
							_G.FishBoat = true;
						until not _G.Dojoo or not R;
						_G.SailBoats = false;
						_G.FishBoat = false;
					elseif r == "Black" then
						repeat
							task.wait();
							if workspace.Map:FindFirstChild("PrehistoricIsland") or workspace._WorldOrigin.Locations:FindFirstChild("Prehistoric Island") then
								_G.Prehis_Find = true;
								if workspace.Map.PrehistoricIsland.Core.ActivationPrompt:FindFirstChild("ProximityPrompt", true) then
									_G.Prehis_Skills = false;
									_G.Prehis_Find = true;
								else
									_G.Prehis_Skills = true;
									_G.Prehis_Find = false;
								end;
							else
								_G.Prehis_Find = true;
								_G.Prehis_Skills = false;
							end;
						until not _G.Dojoo or not R;
						_G.Prehis_Find = false;
						_G.Prehis_Skills = false;
					elseif r == "Orange" or r == "Blue" then
						return nil;
					end;
				end;
				if not R then
					H = false;
					local Y = { [1] = { NPC = "Dojo Trainer", Command = "ClaimQuest" } };
					(Q.Modules.Net:FindFirstChild("RF/InteractDragonQuest")):InvokeServer(unpack(Y));
				end;
			end);
		end;
	end;
end);
OF.CreateToggle({
	Title = "Auto Dragon Hunter",
	Description = "turn on for farm blaze ember + auto collect blaze ember",
	Default = false,
	Callback = function(Y)
		_G.FarmBlazeEM = Y;
	end,
});
checkQuesta = function()
		local Y = { [1] = { Context = "Check" } };
		local d = nil;
		pcall(function()
			local Y = { [1] = { Context = "RequestQuest" } };
			((((game:GetService("ReplicatedStorage")):WaitForChild("Modules")):WaitForChild("Net")):WaitForChild("RF/DragonHunter")):InvokeServer(unpack(Y));
		end);
		local R, Q = pcall(function()
				d = ((((game:GetService("ReplicatedStorage")):WaitForChild("Modules")):WaitForChild("Net")):WaitForChild("RF/DragonHunter")):InvokeServer(unpack(Y));
			end);
		local r = false;
		local a;
		local w;
		local F;
		if d then
			if d.Text then
				r = true;
				local Y = d.Text;
				if string.find(tostring(Y), "Defeat") then
					F = 1;
					a = string.sub(tostring(Y), 8, 9);
					a = tonumber(a);
					local d = { "Hydra Enforcer", "Venomous Assailant" };
					for d, R in pairs(d) do
						if string.find(Y, R) then
							w = R;
							break;
						end;
					end;
				elseif string.find(tostring(Y), "Destroy") then
					a = 10;
					F = 2;
					w = nil;
				end;
			end;
		end;
		return r, w, a, F;
	end;
BackTODoJo = function()
		for Y, d in pairs((game:GetService("Players")).LocalPlayer.PlayerGui.Notifications:GetChildren()) do
			if d.Name == "NotificationTemplate" then
				if string.find(d.Text, "Head back to the Dojo to complete more tasks") then
					return true;
				end;
			end;
		end;
		return false;
	end;
DragonMobClear = function(Y, d, R)
		if workspace.Enemies:FindFirstChild(d) then
			for R, Q in pairs(workspace.Enemies:GetChildren()) do
				if Q.Name == d and f.Alive(Q) then
					if Y then
						f.Kill(Q, Y);
					end;
				end;
			end;
		else
			_tp(R);
		end;
	end;
task.spawn(function()
	while task.wait() do
		if _G.FarmBlazeEM then
			pcall(function()
				local Y, d, Q, r = checkQuesta();
				if Y == true and not BackTODoJo() then
					if r == 1 then
						if d == "Hydra Enforcer" or d == "Venomous Assailant" then
							repeat
								task.wait();
								DragonMobClear(true, d, CFrame.new(4620.61572265, 1002.29547119, 399.08688354));
							until not _G.FarmBlazeEM or not Y or BackTODoJo();
						end;
					elseif r == 2 then
						if workspace.Map.Waterfall.IslandModel:FindFirstChild("Meshes/bambootree", true) then
							repeat
								task.wait();
								task.spawn(function()
									_tp((workspace.Map.Waterfall.IslandModel:FindFirstChild("Meshes/bambootree", true)).CFrame * CFrame.new(4, 0, 0));
								end);
								if ((workspace.Map.Waterfall.IslandModel:FindFirstChild("Meshes/bambootree", true)).Position - R.Position).Magnitude <= 200 then
									MousePos = (workspace.Map.Waterfall.IslandModel:FindFirstChild("Meshes/bambootree", true)).Position;
									Useskills("Melee", "Z");
									Useskills("Melee", "X");
									Useskills("Melee", "C");
									task.wait(.5);
									Useskills("Sword", "Z");
									Useskills("Sword", "X");
									task.wait(.5);
									Useskills("Blox Fruit", "Z");
									Useskills("Blox Fruit", "X");
									Useskills("Blox Fruit", "C");
									task.wait(.5);
									Useskills("Gun", "Z");
									Useskills("Gun", "X");
								end;
							until not _G.FarmBlazeEM or not Y or BackTODoJo();
						end;
					end;
				else
					_tp(CFrame.new(5813, 1208, 884));
					DragonMobClear(false, nil, nil);
				end;
			end);
		end;
	end;
end);
task.spawn(function()
	while task.wait(.1) do
		if _G.FarmBlazeEM then
			pcall(function()
				if workspace.EmberTemplate:FindFirstChild("Part") then
					game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = workspace.EmberTemplate.Part.CFrame;
				end;
			end);
		end;
	end;
end);
local fF = Sz.CreateSection("Drago Trial");
GetQuestDracoLevel = function()
		local Y = { [1] = { NPC = "Dragon Wizard", Command = "Upgrade" } };
		return (Q.Modules.Net:FindFirstChild("RF/InteractDragonQuest")):InvokeServer(unpack(Y));
	end;
fF.CreateToggle({
	Title = "Tween To Upgrade Droco Trial",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.UPGDrago = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		pcall(function()
			if _G.UPGDrago then
				if GetQuestDracoLevel() == false then
					return nil;
				elseif GetQuestDracoLevel() == true then
					if ((CFrame.new(5814.42724609, 1208.32678222, 884.57855224)).Position - R.Position).Magnitude >= 300 then
						_tp(CFrame.new(5814.42724609, 1208.32678222, 884.57855224));
					else
						_tp(CFrame.new(5814.42724609, 1208.32678222, 884.57855224));
						local Y = { [1] = { NPC = "Dragon Wizard", Command = "Upgrade" } };
						(Q.Modules.Net:FindFirstChild("RF/InteractDragonQuest")):InvokeServer(unpack(Y));
					end;
				end;
			end;
		end);
	end;
end);
fF.CreateToggle({
	Title = "Auto Drago (V1)",
	Description = "turn on for auto quest1 auto prehistoric event + collect dragon eggs",
	Default = false,
	Callback = function(Y)
		_G.DragoV1 = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		pcall(function()
			if _G.DragoV1 then
				if GetM("Dragon Egg") <= 0 then
					repeat
						task.wait();
						_G.Prehis_Find = true;
						_G.Prehis_Skills = true;
						_G.Prehis_DE = true;
					until not _G.DragoV1 or GetM("Dragon Egg") >= 1;
					_G.Prehis_Find = false;
					_G.Prehis_Skills = false;
					_G.Prehis_DE = false;
				end;
			end;
		end);
	end;
end);
fF.CreateToggle({
	Title = "Auto Drago (V2)",
	Description = "turn on for auto kill Forest Pirate & Collect fireflower",
	Default = false,
	Callback = function(Y)
		_G.AutoFireFlowers = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		if _G.AutoFireFlowers then
			local Y = workspace:FindFirstChild("FireFlowers");
			local d = GetConnectionEnemies("Forest Pirate");
			if d then
				repeat
					task.wait();
					f.Kill(d, _G.AutoFireFlowers);
				until not _G.AutoFireFlowers or not d.Parent or d.Humanoid.Health <= 0 or Y;
			else
				_tp(CFrame.new(-13206.45214843, 425.89199829, -7964.55371093));
			end;
			if Y then
				for Y, d in pairs(Y:GetChildren()) do
					if d:IsA("Model") and d.PrimaryPart then
						local Y = d.PrimaryPart.Position;
						local R = game.Players.LocalPlayer.Character.HumanoidRootPart.Position;
						local Q = (Y - R).Magnitude;
						if Q <= 100 then
							K:SendKeyEvent(true, "E", false, game);
							task.wait(1.5);
							K:SendKeyEvent(false, "E", false, game);
						else
							_tp(CFrame.new(Y));
						end;
					end;
				end;
			end;
		end;
	end;
end);
fF.CreateToggle({
	Title = "Auto Drago (V3)",
	Description = "turn on for sea event kill terror shark",
	Default = false,
	Callback = function(Y)
		_G.DragoV3 = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		pcall(function()
			if _G.DragoV3 then
				repeat
					task.wait();
					_G.DangerSc = "Lv Infinite";
					_G.SailBoats = true;
					_G.TerrorShark = true;
				until not _G.DragoV3;
				_G.DangerSc = "Lv 1";
				_G.SailBoats = false;
				_G.TerrorShark = false;
			end;
		end);
	end;
end);
fF.CreateToggle({
	Title = "Auto Relic Drago Trial [Beta]",
	Description = "turn on for auto trial v4 you have to COLLECT RELIC by your self",
	Default = false,
	Callback = function(Y)
		_G.Relic123 = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		if _G.Relic123 then
			pcall(function()
				if workspace.Map:FindFirstChild("DracoTrial") then
					Q.Remotes.DracoTrial:InvokeServer();
					task.wait(.5);
					repeat
						task.wait();
						_tp(CFrame.new(-39934.9765625, 10685.359375, 22999.34375));
					until not _G.Relic123 or R.Position == (CFrame.new(-39934.9765625, 10685.359375, 22999.34375)).Position;
					repeat
						task.wait();
						_tp(CFrame.new(-40511.25390625, 9376.40136718, 23458.37890625));
					until not _G.Relic123 or R.Position == (CFrame.new(-40511.25390625, 9376.40136718, 23458.37890625)).Position;
					task.wait(2.5);
					repeat
						task.wait();
						_tp(CFrame.new(-39914.65625, 10685.38476562, 23000.17773437));
					until not _G.Relic123 or R.Position == (CFrame.new(-39914.65625, 10685.38476562, 23000.17773437)).Position;
					repeat
						task.wait();
						_tp(CFrame.new(-40045.83203125, 9376.3984375, 22791.28710937));
					until not _G.Relic123 or R.Position == (CFrame.new(-40045.83203125, 9376.3984375, 22791.28710937)).Position;
					task.wait(2.5);
					repeat
						task.wait();
						_tp(CFrame.new(-39908.5, 10685.40527343, 22990.04296875));
					until not _G.Relic123 or R.Position == (CFrame.new(-39908.5, 10685.40527343, 22990.04296875)).Position;
					repeat
						task.wait();
						_tp(CFrame.new(-39609.5, 9376.40039062, 23472.94335975));
					until not _G.Relic123 or R.Position == (CFrame.new(-39609.5, 9376.40039062, 23472.94335975)).Position;
				else
					local Y = workspace.Map.PrehistoricIsland:FindFirstChild("TrialTeleport");
					if Y and Y:IsA("Part") then
						_tp(CFrame.new(Y.Position));
					end;
				end;
			end);
		end;
	end;
end);
fF.CreateToggle({
	Title = "Auto Train Drago v4",
	Description = "turn on for training Drago race v4 + auto upgrade tier",
	Default = false,
	Callback = function(Y)
		_G.TrainDrago = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		pcall(function()
			if _G.TrainDrago then
				local Y = { "Venomous Assailant", "Hydra Enforcer" };
				for R = 1, #Y, 1 do
					if (d.Character:FindFirstChild("RaceEnergy")).Value == 1 then
						K:SendKeyEvent(true, "Y", false, game);
						Q.Remotes.CommF_:InvokeServer("UpgradeRace", "Buy", 2);
						_tp(CFrame.new(4620.61572265, 1002.29547119, 399.08688354));
					elseif (d.Character:FindFirstChild("RaceTransformed")).Value == false then
						local d = GetConnectionEnemies(Y);
						if d then
							repeat
								task.wait();
								f.Kill(d, _G.TrainDrago);
							until _G.TrainDrago == false or d.Humanoid.Health <= 0 or not d.Parent;
						else
							_tp(CFrame.new(4620.61572265, 1002.29547119, 399.08688354));
						end;
					end;
				end;
			end;
		end);
	end;
end);
fF.CreateToggle({
	Title = "Tween to Drago Trials",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.TpDrago_Prehis = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		if _G.TpDrago_Prehis then
			local Y = workspace.Map.PrehistoricIsland:FindFirstChild("TrialTeleport");
			if Y and Y:IsA("Part") then
				_tp(CFrame.new(Y.Position));
			end;
		end;
	end;
end);
fF.CreateToggle({
	Title = "Swap Drago Race",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.BuyDrago = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		if _G.BuyDrago then
			pcall(function()
				if ((CFrame.new(5814.42724609, 1208.32678222, 884.57855224)).Position - R.Position).Magnitude >= 300 then
					_tp(CFrame.new(5814.42724609, 1208.32678222, 884.57855224));
				else
					_tp(CFrame.new(5814.42724609, 1208.32678222, 884.57855224));
					local Y = { [1] = { NPC = "Dragon Wizard", Command = "DragonRace" } };
					(Q.Modules.Net:FindFirstChild("RF/InteractDragonQuest")):InvokeServer(unpack(Y));
				end;
			end);
		end;
	end;
end);
fF.CreateToggle({
	Title = "Upgrade Dragon Talon With Uzoth",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.DT_Uzoth = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		if _G.DT_Uzoth then
			local Y = CFrame.new(5661.89014, 1211.31909, 864.836731, .811413169, -1.36805838e-08, -0.58447301, 4.75227395e-08, 1, 4.25682458e-08, .584473014, -6.23161966e-08, .811413169);
			_tp(Y);
			if (Y.Position - d.Character.HumanoidRootPart.Position).Magnitude <= 25 then
				local Y = { NPC = "Uzoth", Command = "Upgrade" };
				Q.Modules.Net["RF/InteractDragonQuest"]:InvokeServer(Y);
			end;
		end;
	end;
end);
local sF = oz.CreateSection("Volcanic Magnet");
sF.CreateToggle({
	Title = "Auto Craft Volcanic Magnet",
	Description = "turn on for auto farm material and craft volcanic magnet & stop when you have 1 volcanic magnet",
	Default = false,
	Callback = function(Y)
		_G.CraftVM = Y;
	end,
});
sF.CreateButton({ Title = "Craft Volcanic Magnet", Callback = function()
		Q.Remotes.CommF_:InvokeServer("CraftItem", "Craft", "Volcanic Magnet");
	end });
task.spawn(function()
	while task.wait(T) do
		pcall(function()
			if _G.CraftVM then
				if GetM("Volcanic Magnet") < 1 then
					if GetM("Scrap Metal") >= 10 and GetM("Blaze Ember") >= 15 then
						Q.Remotes.CommF_:InvokeServer("CraftItem", "Craft", "Volcanic Magnet");
					elseif GetM("Scrap Metal") < 10 then
						local Y = GetConnectionEnemies("Forest Pirate");
						if Y then
							repeat
								task.wait();
								f.Kill(Y, _G.CraftVM);
							until not _G.CraftVM or not Y.Parent or Y.Humanoid.Health <= 0 or GetM("Scrap Metal") >= 10;
						else
							_tp(CFrame.new(-13206.45214843, 425.89199829, -7964.55371093));
						end;
					elseif GetM("Blaze Ember") < 15 then
						repeat
							task.wait();
							_G.FarmBlazeEM = true;
						until not _G.CraftVM or GetM("Blaze Ember") >= 15;
						_G.FarmBlazeEM = false;
					end;
				end;
			end;
		end);
	end;
end);
local xF = oz.CreateSection("Prehistoric Island");
local JF = xF.CreateLabel({ Title = " Prehistoric Island Status ", Content = "" });
task.spawn(function()
	while task.wait(.2) do
		if workspace.Map:FindFirstChild("PrehistoricIsland") or workspace._WorldOrigin.Locations:FindFirstChild("Prehistoric Island") then
			JF:SetDesc(" Prehistoric Island : True");
		else
			JF:SetDesc(" Prehistoric Island : False");
		end;
	end;
end);
xF.CreateToggle({
	Title = "Auto Find Prehistoric Island",
	Description = "turn on for finding & tween & start prehistoric island",
	Default = false,
	Callback = function(Y)
		_G.Prehis_Find = Y;
	end,
});
local Yq = nil;
task.spawn(function()
	while task.wait() do
		if _G.Prehis_Find then
			pcall(function()
				if not workspace._WorldOrigin.Locations:FindFirstChild("Prehistoric Island", true) then
					local Y = CheckBoat();
					if not Y then
						local Y = CFrame.new(-16927.451, 9.086, 433.864);
						TeleportToTarget(Y);
						if (Y.Position - d.Character.HumanoidRootPart.Position).Magnitude <= 10 then
							Q.Remotes.CommF_:InvokeServer("BuyBoat", _G.SelectedBoat);
						end;
					else
						if d.Character.Humanoid.Sit == false then
							local d = Y.VehicleSeat.CFrame * CFrame.new(0, 1, 0);
							_tp(d);
						else
							repeat
								task.wait();
								local Y = CFrame.new(-10000000, 31, 37016.25);
								if CheckEnemiesBoat() or CheckTerrorShark() or CheckPirateGrandBrigade() then
									_tp(CFrame.new(-10000000, 150, 37016.25));
								else
									_tp(CFrame.new(-10000000, 31, 37016.25));
								end;
							until not _G.Prehis_Find or (Y.Position - d.Character.HumanoidRootPart.Position).Magnitude <= 10 or workspace._WorldOrigin.Locations:FindFirstChild("Prehistoric Island") or d.Character.Humanoid.Sit == false;
							d.Character.Humanoid.Sit = false;
						end;
					end;
				else
					if ((workspace._WorldOrigin.Locations:FindFirstChild("Prehistoric Island")).CFrame.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude >= 2000 then
						_tp((workspace._WorldOrigin.Locations:FindFirstChild("Prehistoric Island")).CFrame);
					end;
					if workspace.Map:FindFirstChild("PrehistoricIsland", true) or workspace._WorldOrigin.Locations:FindFirstChild("Prehistoric Island", true) then
						if workspace.Map.PrehistoricIsland.Core.ActivationPrompt:FindFirstChild("ProximityPrompt", true) then
							if d:DistanceFromCharacter(workspace.Map.PrehistoricIsland.Core.ActivationPrompt.CFrame.Position) <= 150 then
								fireproximityprompt(workspace.Map.PrehistoricIsland.Core.ActivationPrompt.ProximityPrompt, math.huge);
								K:SendKeyEvent(true, "E", false, game);
								task.wait(1.5);
								K:SendKeyEvent(false, "E", false, game);
							end;
							_tp(workspace.Map.PrehistoricIsland.Core.ActivationPrompt.CFrame);
						end;
					end;
				end;
			end);
		end;
	end;
end);
xF.CreateToggle({
	Title = "Auto Patch Prehistoric Event",
	Description = "turn on for auto patch volcano + kill aura lava golems + auto remove lava",
	Default = false,
	Callback = function(Y)
		_G.Prehis_Skills = Y;
	end,
});
task.spawn(function()
	while task.wait() do
		if _G.Prehis_Skills then
			local Y = game.Workspace.Map:FindFirstChild("PrehistoricIsland");
			if Y then
				for Y, d in pairs(Y:GetDescendants()) do
					if d:IsA("Part") and (d.Name:lower()):find("lava") then
						d:Destroy();
					end;
					if d:IsA("MeshPart") and (d.Name:lower()):find("lava") then
						d:Destroy();
					end;
				end;
				local d = game.Workspace.Map.PrehistoricIsland.Core:FindFirstChild("InteriorLava");
				if d and d:IsA("Model") then
					d:Destroy();
				end;
				local R = workspace.Map:FindFirstChild("PrehistoricIsland");
				if R then
					local Y = workspace.Map.PrehistoricIsland:FindFirstChild("TrialTeleport");
					for d, R in pairs(R:GetDescendants()) do
						if R.Name == "TouchInterest" then
							if not (Y and R:IsDescendantOf(Y)) then
								R.Parent:Destroy();
							end;
						end;
					end;
				end;
			end;
		end;
	end;
end);
task.spawn(function()
	while task.wait() do
		pcall(function()
			if _G.Prehis_Skills then
				if workspace.Enemies:FindFirstChild("Lava Golem") then
					local Y = GetConnectionEnemies("Lava Golem");
					if Y then
						repeat
							task.wait();
							f.Kill(Y, _G.Prehis_Skills);
							Y.Humanoid:ChangeState(15);
						until not _G.Prehis_Skills or not Y.Parent or Y.Humanoid.Health <= 0;
					end;
				end;
				for Y, R in pairs(game.Workspace.Map.PrehistoricIsland.Core.VolcanoRocks:GetChildren()) do
					if R:FindFirstChild("VFXLayer") then
						if (R:FindFirstChild("VFXLayer")).At0.Glow.Enabled == true or R.VFXLayer.At0.Glow.Enabled == true then
							repeat
								task.wait();
								_tp(R.VFXLayer.CFrame);
								if R.VFXLayer.At0.Glow.Enabled == true and d:DistanceFromCharacter(R.VFXLayer.CFrame.Position) <= 150 then
									MousePos = R.VFXLayer.CFrame.Position;
									Useskills("Melee", "Z");
									task.wait(.5);
									Useskills("Melee", "X");
									task.wait(.5);
									Useskills("Melee", "C");
									task.wait(.5);
									Useskills("Blox Fruit", "Z");
									task.wait(.5);
									Useskills("Blox Fruit", "X");
									task.wait(.5);
									Useskills("Blox Fruit", "C");
								end;
							until not _G.Prehis_Skills or (R:FindFirstChild("VFXLayer")).At0.Glow.Enabled == false or R.VFXLayer.At0.Glow.Enabled == false;
						end;
					end;
				end;
			end;
		end);
	end;
end);
xF.CreateToggle({
	Title = "Auto Collect Dino Bones",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.Prehis_DB = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		pcall(function()
			if _G.Prehis_DB then
				if workspace:FindFirstChild("DinoBone") then
					for Y, d in pairs(workspace:GetChildren()) do
						if d.Name == "DinoBone" then
							_tp(d.CFrame);
						end;
					end;
				end;
			end;
		end);
	end;
end);
xF.CreateToggle({
	Title = "Auto Collect Dragon Eggs",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.Prehis_DE = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		pcall(function()
			if _G.Prehis_DE then
				if workspace.Map.PrehistoricIsland.Core.SpawnedDragonEggs:FindFirstChild("DragonEgg") then
					_tp((workspace.Map.PrehistoricIsland.Core.SpawnedDragonEggs:FindFirstChild("DragonEgg")).Molten.CFrame);
					fireproximityprompt(workspace.Map.PrehistoricIsland.Core.SpawnedDragonEggs.DragonEgg.Molten.ProximityPrompt, 30);
				end;
			end;
		end);
	end;
end);
xF.CreateToggle({
	Title = "Auto Reset When Complete Volcano",
	Description = "Reset When Complete Volcano not collect dino bones and else..",
	Default = false,
	Callback = function(Y)
		_G.ResetPH = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		pcall(function()
			if _G.ResetPH then
				local Y = workspace.Map.PrehistoricIsland:FindFirstChild("TrialTeleport");
				if Y and Y:FindFirstChild("TouchInterest") then
					d.Character.Humanoid.Health = 0;
				else
					if workspace:FindFirstChild("DinoBone") then
						for Y, d in pairs(workspace:GetChildren()) do
							if d.Name == "DinoBone" then
								_tp(d.CFrame);
							end;
						end;
					end;
				end;
			end;
		end);
	end;
end);
local dq = Zz.CreateSection("Dungeon Event / Raiding");
local Rq = dq.CreateLabel({ Title = " Raiding Status ", Content = "" });
task.spawn(function()
	while task.wait(.2) do
		pcall(function()
			if d.PlayerGui.Main.Timer.Visible == true then
				Rq:SetDesc(" Raiding Statud : True");
			else
				Rq:SetDesc(" Raiding Statud : False");
			end;
		end);
	end;
end);
j = {
		"Flame",
		"Ice",
		"Quake",
		"Light",
		"Dark",
		"String",
		"Rumble",
		"Magma",
		"Human: Buddha",
		"Sand",
		"Bird: Phoenix",
		"Dough",
	};
dq.CreateDropdown({
	Title = "Select Chip",
	Description = "",
	Values = j,
	Default = "Flame",
	Multi = false,
	Callback = function(Y)
		_G.SelectChip = Y;
	end,
});
dq.CreateToggle({
	Title = "Auto Select Dungeon Chip",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.AutoSelectDungeon = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		if _G.AutoSelectDungeon then
			pcall(function()
				if GetBP("Flame-Flame") then
					_G.SelectChip = "Flame";
				elseif GetBP("Ice-Ice") then
					_G.SelectChip = "Ice";
				elseif GetBP("Quake-Quake") then
					_G.SelectChip = "Quake";
				elseif GetBP("Light-Light") then
					_G.SelectChip = "Light";
				elseif GetBP("Dark-Dark") then
					_G.SelectChip = "Dark";
				elseif GetBP("String-String") then
					_G.SelectChip = "String";
				elseif GetBP("Rumble-Rumble") then
					_G.SelectChip = "Rumble";
				elseif GetBP("Magma-Magma") then
					_G.SelectChip = "Magma";
				elseif GetBP("Human-Human: Buddha Fruit") then
					_G.SelectChip = "Human: Buddha";
				elseif GetBP("Dough-Dough") then
					_G.SelectChip = "Dough";
				elseif GetBP("Sand-Sand") then
					_G.SelectChip = "Sand";
				elseif GetBP("Bird-Bird: Phoenix") then
					_G.SelectChip = "Bird: Phoenix";
				else
					_G.SelectChip = "Ice";
				end;
			end);
		end;
	end;
end);
dq.CreateButton({ Title = "Buy Dungeon Chips [Beli]", Callback = function()
		if not GetBP("Special Microchip") then
			Q.Remotes.CommF_:InvokeServer("RaidsNpc", "Select", _G.SelectChip);
		end;
	end });
dq.CreateButton({ Title = "Buy Dungeon Chips [Devil Fruit]", Callback = function()
		if GetBP("Special Microchip") then
			return;
		end;
		local Y = {};
		local d = {};
		for d, R in next, (Q:WaitForChild("Remotes")).CommF_:InvokeServer("GetFruits") do
			if R.Price <= 490000 then
				table.insert(Y, R.Name);
			end;
		end;
		for Y, d in pairs(Y) do
			for Y, R in pairs(j) do
				if not GetBP("Special Microchip") then
					Q.Remotes.CommF_:InvokeServer("LoadFruit", tostring(d));
					Q.Remotes.CommF_:InvokeServer("RaidsNpc", "Select", _G.SelectChip);
				end;
			end;
		end;
	end });
local Qq = Zz.CreateSection("Raiding Menu");
Qq.CreateToggle({
	Title = "Auto Start Raid",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.Auto_StartRaid = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		pcall(function()
			if _G.Auto_StartRaid then
				if d.PlayerGui.Main.TopHUDList.RaidTimer.Visible == false then
					if GetBP("Special Microchip") then
						if World2 then
							_tp(CFrame.new(-6438.73535, 250.645355, -4501.50684));
							fireclickdetector(workspace.Map.CircleIsland.RaidSummon2.Button.Main.ClickDetector);
						elseif World3 then
							Q.Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(-5097.93164, 316.447021, -3142.66602, -0.40500789, -4.31682743e-08, .914313197, -1.90943332e-08, 1, 3.8755779e-08, -0.91431319, -1.76180437e-09, -0.40500789));
							fireclickdetector(workspace.Map["Boat Castle"].RaidSummon2.Button.Main.ClickDetector);
						end;
					end;
				end;
			end;
		end);
	end;
end);
Qq.CreateToggle({
	Title = "Teleport To Lab",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.TpLab = Y;
		task.spawn(function()
			while _G.TpLab do
				task.wait(T);
				if _G.TpLab then
					if World2 then
						_tp(CFrame.new(-6438.73535, 250.645355, -4501.50684));
					elseif World3 then
						_tp(CFrame.new(-5017.40869, 314.844055, -2823.0127, -0.92574381, 4.48217499e-08, -0.37815123, 4.55503146e-09, 1, 1.07377559e-07, .378151238, 9.7681621e-08, -0.92574381));
					end;
				end;
			end;
		end);
	end,
});
Qq.CreateToggle({
	Title = "Auto Complete Raid [Safety]",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.Raiding = Y;
	end,
});
task.spawn(function()
	pcall(function()
		while task.wait(T) do
			if _G.Raiding then
				if d.PlayerGui.Main.TopHUDList.RaidTimer.Visible == true then
					local Y = {
							"Island5",
							"Island 4",
							"Island 3",
							"Island 2",
							"Island 1",
						};
					for Y, d in ipairs(Y) do
						local R = (game:GetService("Workspace"))._WorldOrigin.Locations:FindFirstChild(d);
						if R then
							for Y, d in pairs(workspace.Enemies:GetChildren()) do
								if d:FindFirstChild("Humanoid") or d:FindFirstChild("HumanoidRootPart") then
									if d.Humanoid.Health > 0 then
										repeat
											task.wait();
											f.Kill(d, _G.Raiding);
											NextIs = false;
										until not _G.Raiding or not d.Parent or d.Humanoid.Health <= 0;
										NextIs = true;
									end;
								end;
							end;
						end;
					end;
				else
					NextIs = false;
				end;
			else
				NextIs = false;
			end;
		end;
	end);
end);
Qq.CreateToggle({
	Title = "Kill Aura",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.KillH = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		if _G.KillH then
			for Y, R in pairs(workspace.Enemies:GetChildren()) do
				if f.Alive(R) then
					pcall(function()
						repeat
							task.wait(T);
							sethiddenproperty(d, "SimulationRadius", math.huge);
							R:BreakJoints();
							R.Humanoid.Health = 0;
							R.HumanoidRootPart.CanCollide = false;
						until not _G.KillH or not R.Parent or R.Humanoid.Health <= 0;
					end);
				end;
			end;
		end;
	end;
end);
Qq.CreateToggle({
	Title = "Auto Next Island",
	Description = "",
	Default = false,
	Callback = function(Y)
		NextIs = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		if NextIs then
			if d.PlayerGui.Main.TopHUDList.RaidTimer.Visible == true then
				if workspace._WorldOrigin.Locations:FindFirstChild("Island 5") then
					_tp((workspace._WorldOrigin.Locations:FindFirstChild("Island 5")).CFrame * CFrame.new(0, 50, 100));
				elseif workspace._WorldOrigin.Locations:FindFirstChild("Island 4") then
					_tp((workspace._WorldOrigin.Locations:FindFirstChild("Island 4")).CFrame * CFrame.new(0, 50, 100));
				elseif workspace._WorldOrigin.Locations:FindFirstChild("Island 3") then
					_tp((workspace._WorldOrigin.Locations:FindFirstChild("Island 3")).CFrame * CFrame.new(0, 50, 100));
				elseif workspace._WorldOrigin.Locations:FindFirstChild("Island 2") then
					_tp((workspace._WorldOrigin.Locations:FindFirstChild("Island 2")).CFrame * CFrame.new(0, 50, 100));
				elseif workspace._WorldOrigin.Locations:FindFirstChild("Island 1") then
					_tp((workspace._WorldOrigin.Locations:FindFirstChild("Island 1")).CFrame * CFrame.new(0, 50, 100));
				end;
			end;
		end;
	end;
end);
Qq.CreateToggle({
	Title = "Auto Awakening",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.Auto_Awakener = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		pcall(function()
			if _G.Auto_Awakener then
				Q.Remotes.CommF_:InvokeServer("Awakener", "Check");
				Q.Remotes.CommF_:InvokeServer("Awakener", "Awaken");
			end;
		end);
	end;
end);
local rq = Tz.CreateSection("Combat / Aimbot");
__indexPlayer = rq.CreateLabel({ Title = "All Players On Server :", Content = "" });
task.spawn(function()
	while task.wait(T) do
		pcall(function()
			for Y, d in pairs((game:GetService("Players")):GetPlayers()) do
				if Y == 12 then
					__indexPlayer:SetDesc("All Players :" .. (" " .. (Y .. " / 12 [Max]")));
				elseif Y == 1 then
					__indexPlayer:SetDesc("All Players  :" .. (" " .. (Y .. " / 12")));
				else
					__indexPlayer:SetDesc("All Players  :" .. (" " .. (Y .. " / 12")));
				end;
			end;
		end);
	end;
end);
__AimBotTurn = rq.CreateLabel({ Title = "Aimbot Status :", Content = "" });
local aq = { "AimBots Skill", "Auto Aimbots" };
Checking_AimStatus = function()
		if _G.AimCam then
			return "Aimbot Camera";
		end;
		return "";
	end;
task.spawn(function()
	while task.wait(.2) do
		pcall(function()
			if _G.AimMethod then
				__AimBotTurn:SetDesc("Aimbot - Skills : True");
			elseif (_G.AimCam or _G.AimbotGun) and _G.AimMethod then
				__AimBotTurn:SetDesc("Aimbot - Skills |" .. (Checking_AimStatus() .. " :True"));
			else
				__AimBotTurn:SetDesc("Aimbot - Skills : False");
			end;
		end);
	end;
end);
local wq = {};
for Y, d in pairs((game:GetService("Players")):GetChildren()) do
	table.insert(wq, d.Name);
end;
rq.CreateDropdown({
	Title = "Choose Players",
	Description = "",
	Values = wq,
	Default = false,
	Multi = false,
	Callback = function(Y)
		_G.PlayersList = Y;
	end,
});
rq.CreateToggle({
	Title = "Teleport to choose players",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.TpPly = Y;
		task.spawn(function()
			pcall(function()
				while _G.TpPly do
					task.wait();
					_tp((game:GetService("Players"))[_G.PlayersList].Character.HumanoidRootPart.CFrame);
				end;
			end);
		end);
	end,
});
rq.CreateToggle({
	Title = "Spectate Choose Players",
	Description = "",
	Default = false,
	Callback = function(Y)
		SpectatePlys = Y;
		task.spawn(function()
			repeat
				task.wait(.1);
				pcall(function()
					local target = _G.PlayersList and (game:GetService("Players")):FindFirstChild(_G.PlayersList);
					local targetChar = target and target.Character;
					local targetHumanoid = targetChar and targetChar:FindFirstChild("Humanoid");
					if targetHumanoid then
						workspace.Camera.CameraSubject = targetHumanoid;
					end;
				end);
			until not SpectatePlys;
			workspace.Camera.CameraSubject = d.Character.Humanoid;
		end);
	end,
});
rq.CreateDropdown({
	Title = "Choose Aim Method",
	Description = "",
	Values = aq,
	Default = false,
	Multi = false,
	Callback = function(Y)
		ABmethod = Y;
	end,
});
rq.CreateToggle({
	Title = "Aimbot Method Skills",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.AimMethod = Y;
	end,
});
task.spawn(function()
	while task.wait() do
		pcall(function()
			if _G.AimMethod and ABmethod == "AimBots Skill" then
				for Y, d in pairs((game:GetService("Players")):GetPlayers()) do
					if d.Name == _G.PlayersList and d.Team ~= game.Players.LocalPlayer.Team then
						MousePos = (d.Character:FindFirstChild("HumanoidRootPart")).Position;
					end;
				end;
			end;
		end);
	end;
end);
task.spawn(function()
	while task.wait() do
		pcall(function()
			if _G.AimMethod and ABmethod == "Auto Aimbots" then
				local Y = math.huge;
				for R, Q in pairs((game:GetService("Players")):GetPlayers()) do
					if Q.Name ~= d.Name and Q.Team ~= game.Players.LocalPlayer.Team then
						local R = Q:DistanceFromCharacter(d.Character.HumanoidRootPart.Position);
						if R < Y then
							Y = R;
							MousePos = (Q.Character:FindFirstChild("HumanoidRootPart")).Position;
						end;
					end;
				end;
			end;
		end);
	end;
end);
rq.CreateToggle({
	Title = "Aimbot Camera Closet Players",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.AimCam = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		pcall(function()
			if _G.AimCam then
				local R = workspace.CurrentCamera;
				closestplayer = function()
						local R = math.huge;
						local Q = nil;
						for Y, r in next, Y:GetPlayers() do
							if r ~= d then
								if r.Character and (r.Character:FindFirstChild("Head") and (_G.AimCam and r.Character.Humanoid.Health > 0)) then
									local Y = (r.Character.Head.Position - d.Character.Head.Position).Magnitude;
									if Y < R then
										R = Y;
										Q = r;
									end;
								end;
							end;
						end;
						return Q;
					end;
				repeat
					task.wait();
					R.CFrame = CFrame.new(R.CFrame.Position, (closestplayer()).Character.HumanoidRootPart.Position);
				until _G.AimCam == false or Mag > dist;
			end;
		end);
	end;
end);
local Fq = Tz.CreateSection("LocalPlayer Settings / Misc");
Fq.CreateToggle({
	Title = "Instance Mink V3 [ INF ]",
	Description = "turn on for make mink v3 infinity",
	Default = false,
	Callback = function(Y)
		InfAblities = Y;
	end,
});
task.spawn(function()
	while task.wait(.2) do
		pcall(function()
			if InfAblities then
				if not d.Character.HumanoidRootPart:FindFirstChild("Agility") then
					local Y = Q.FX.Agility:Clone();
					Y.Name = "Agility";
					Y.Parent = d.Character.HumanoidRootPart;
				end;
			else
				d.Character.HumanoidRootPart.Agility:Destroy();
			end;
		end);
	end;
end);
Fq.CreateToggle({
	Title = "Instance Energy [ INF ]",
	Description = "turn on for make energy infinity",
	Default = false,
	Callback = function(Y)
		infEnergy = Y;
		if Y then
			getInfinity_Ability("Energy", infEnergy);
		end;
	end,
});
Fq.CreateToggle({
	Title = "Instance Soru [ INF ]",
	Description = "turn on for make soru infinity",
	Default = false,
	Callback = function(Y)
		_G.InfSoru = Y;
		if Y then
			getInfinity_Ability("Soru", _G.InfSoru);
		end;
	end,
});
Fq.CreateToggle({
	Title = "Instance Observation Range [ INF ]",
	Description = "turn on for make observation range infinity",
	Default = false,
	Callback = function(Y)
		_G.InfiniteObRange = Y;
		if Y then
			getInfinity_Ability("Observation", _G.InfiniteObRange);
		end;
	end,
});
local Mq = Tz.CreateSection("Settings Combat / Aimbot Settings");
Mq.CreateToggle({
	Title = "Ignore Same Teams",
	Description = "turn on for ignore not aimbot same team",
	Default = false,
	Callback = function(Y)
		_G.NoAimTeam = Y;
	end,
});
Mq.CreateToggle({
	Title = "Accept Allies",
	Description = "turn on for auto accept ally",
	Default = false,
	Callback = function(Y)
		_G.AcceptAlly = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		if _G.AcceptAlly then
			pcall(function()
				for Y, R in pairs(Y:GetChildren()) do
					if R.Name ~= d.Name and (R:FindFirstChild("Humanoid") and R:FindFirstChild("HumanoidRootPart")) then
						((Q:WaitForChild("Remotes")):WaitForChild("CommF_")):InvokeServer("AcceptAlly", R.Name);
					end;
				end;
			end);
		end;
	end;
end);
local Kq = Tz.CreateSection("Esp Items / Entity / Island");
function isnil(Y)
	return Y == nil;
end;
local function nq(Y)
	return math.floor(tonumber(Y) + .5);
end;
Number = math.random(1, 1000000);
EspPly = function()
		for Y, d in next, game.Players:GetChildren() do
			pcall(function()
				if not isnil(d.Character) then
					if PlayerEsp then
						if not isnil(d.Character.Head) and not d.Character.Head:FindFirstChild("NameEsp" .. Number) then
							local Y = Instance.new("BillboardGui", d.Character.Head);
							Y.Name = "NameEsp" .. Number;
							Y.ExtentsOffset = Vector3.new(0, 1, 0);
							Y.Size = UDim2.new(1, 200, 1, 30);
							Y.Adornee = d.Character.Head;
							Y.AlwaysOnTop = true;
							local R = Instance.new("TextLabel", Y);
							R.Font = Enum.Font.Code;
							R.FontSize = "Size14";
							R.TextWrapped = true;
							R.Text = d.Name .. (" \n" .. (nq(((game:GetService("Players")).LocalPlayer.Character.Head.Position - d.Character.Head.Position).Magnitude / 3) .. " M"));
							R.Size = UDim2.new(1, 0, 1, 0);
							R.TextYAlignment = "Top";
							R.BackgroundTransparency = 1;
							R.TextStrokeTransparency = .5;
							if d.Team == I then
								R.TextColor3 = Color3.new(0, 0, 254);
							else
								R.TextColor3 = Color3.new(255, 0, 0);
							end;
						else
							d.Character.Head["NameEsp" .. Number].TextLabel.Text = d.Data.Level.Value .. (" | " .. (d.Name .. (" | " .. (nq(((game:GetService("Players")).LocalPlayer.Character.Head.Position - d.Character.Head.Position).Magnitude / 3) .. (" M\nHealth : " .. (nq((d.Character.Humanoid.Health * 100) / d.Character.Humanoid.MaxHealth) .. "%"))))));
						end;
					else
						if d.Character.Head:FindFirstChild("NameEsp" .. Number) then
							(d.Character.Head:FindFirstChild("NameEsp" .. Number)):Destroy();
						end;
					end;
				end;
			end);
		end;
	end;
LocationEsp = function()
		for Y, d in next, workspace._WorldOrigin.Locations:GetChildren() do
			pcall(function()
				if IslandESP then
					if d.Name ~= "Sea" then
						if not d:FindFirstChild("NameEsp") then
							local Y = Instance.new("BillboardGui", d);
							Y.Name = "NameEsp";
							Y.ExtentsOffset = Vector3.new(0, 1, 0);
							Y.Size = UDim2.new(1, 200, 1, 30);
							Y.Adornee = d;
							Y.AlwaysOnTop = true;
							local R = Instance.new("TextLabel", Y);
							R.Font = Enum.Font.Code;
							R.FontSize = "Size14";
							R.TextWrapped = true;
							R.Size = UDim2.new(1, 0, 1, 0);
							R.TextYAlignment = "Top";
							R.BackgroundTransparency = 1;
							R.TextStrokeTransparency = .5;
							R.TextColor3 = Color3.fromRGB(98, 252, 252);
						else
							d.NameEsp.TextLabel.Text = d.Name .. ("   \n" .. (nq(((game:GetService("Players")).LocalPlayer.Character.Head.Position - d.Position).Magnitude / 3) .. " M"));
						end;
					end;
				else
					if d:FindFirstChild("NameEsp") then
						(d:FindFirstChild("NameEsp")):Destroy();
					end;
				end;
			end);
		end;
	end;
DevEsp = function()
		for Y, d in next, workspace:GetChildren() do
			pcall(function()
				if DevilFruitESP then
					if string.find(d.Name, "Fruit") then
						if not d.Handle:FindFirstChild("NameEsp" .. Number) then
							local Y = Instance.new("BillboardGui", d.Handle);
							Y.Name = "NameEsp" .. Number;
							Y.ExtentsOffset = Vector3.new(0, 1, 0);
							Y.Size = UDim2.new(1, 200, 1, 30);
							Y.Adornee = d.Handle;
							Y.AlwaysOnTop = true;
							local R = Instance.new("TextLabel", Y);
							R.Font = Enum.Font.Code;
							R.FontSize = "Size14";
							R.TextWrapped = true;
							R.Size = UDim2.new(1, 0, 1, 0);
							R.TextYAlignment = "Top";
							R.BackgroundTransparency = 1;
							R.TextStrokeTransparency = .5;
							R.TextColor3 = Color3.fromRGB(255, 255, 255);
							R.Text = d.Name .. (" \n" .. (nq(((game:GetService("Players")).LocalPlayer.Character.Head.Position - d.Handle.Position).Magnitude / 3) .. " M"));
						else
							d.Handle["NameEsp" .. Number].TextLabel.Text = "[" .. (d.Name .. ("]" .. ("   \n" .. (nq(((game:GetService("Players")).LocalPlayer.Character.Head.Position - d.Handle.Position).Magnitude / 3) .. " M"))));
						end;
					end;
				else
					if d.Handle:FindFirstChild("NameEsp" .. Number) then
						(d.Handle:FindFirstChild("NameEsp" .. Number)):Destroy();
					end;
				end;
			end);
		end;
	end;
flowerEsp = function()
		for Y, d in pairs(workspace:GetChildren()) do
			pcall(function()
				if d.Name == "Flower2" or d.Name == "Flower1" then
					if FlowerESP then
						if not d:FindFirstChild("NameEsp" .. Number) then
							local Y = Instance.new("BillboardGui", d);
							Y.Name = "NameEsp" .. Number;
							Y.ExtentsOffset = Vector3.new(0, 1, 0);
							Y.Size = UDim2.new(1, 200, 1, 30);
							Y.Adornee = d;
							Y.AlwaysOnTop = true;
							local R = Instance.new("TextLabel", Y);
							R.Font = Enum.Font.Code;
							R.FontSize = "Size14";
							R.TextWrapped = true;
							R.Size = UDim2.new(1, 0, 1, 0);
							R.TextYAlignment = "Top";
							R.BackgroundTransparency = 1;
							R.TextStrokeTransparency = .5;
							R.TextColor3 = Color3.fromRGB(88, 214, 252);
							if d.Name == "Flower1" then
								R.Text = "Blue Flower" .. (" \n" .. (nq(((game:GetService("Players")).LocalPlayer.Character.Head.Position - d.Position).Magnitude / 3) .. " M"));
								R.TextColor3 = Color3.fromRGB(88, 214, 252);
							end;
							if d.Name == "Flower2" then
								R.Text = "Red Flower" .. (" \n" .. (nq(((game:GetService("Players")).LocalPlayer.Character.Head.Position - d.Position).Magnitude / 3) .. " M"));
								R.TextColor3 = Color3.fromRGB(88, 214, 252);
							end;
						else
							d["NameEsp" .. Number].TextLabel.Text = d.Name .. ("   \n" .. (nq(((game:GetService("Players")).LocalPlayer.Character.Head.Position - d.Position).Magnitude / 3) .. " M"));
						end;
					else
						if d:FindFirstChild("NameEsp" .. Number) then
							(d:FindFirstChild("NameEsp" .. Number)):Destroy();
						end;
					end;
				end;
			end);
		end;
	end;
EventIslandEsp = function()
		for Y, R in pairs(workspace._WorldOrigin.Locations:GetChildren()) do
			pcall(function()
				if EspEventIsland then
					if R.Name == "Mirage Island" or R.Name == "Prehistoric Island" or R.Name == "Kitsune Island" then
						if not R:FindFirstChild("NameEsp") then
							local Y = Instance.new("BillboardGui", R);
							Y.Name = "NameEsp";
							Y.ExtentsOffset = Vector3.new(0, 1, 0);
							Y.Size = UDim2.new(1, 200, 1, 30);
							Y.Adornee = R;
							Y.AlwaysOnTop = true;
							local d = Instance.new("TextLabel", Y);
							d.Font = "Code";
							d.FontSize = "Size14";
							d.TextWrapped = true;
							d.Size = UDim2.new(1, 0, 1, 0);
							d.TextYAlignment = "Top";
							d.BackgroundTransparency = 1;
							d.TextStrokeTransparency = .5;
							d.TextColor3 = Color3.fromRGB(80, 245, 245);
						else
							R.NameEsp.TextLabel.Text = R.Name .. ("   \n" .. (nq((d.Character.Head.Position - R.Position).Magnitude / 3) .. " M"));
						end;
					end;
				elseif R:FindFirstChild("NameEsp") then
					(R:FindFirstChild("NameEsp")):Destroy();
				end;
			end);
		end;
	end;
gearEsp = function()
		for Y, R in pairs(workspace.Map.MysticIsland:GetDescendants()) do
			pcall(function()
				if ESPGear then
					if R.Name == "Part" and R.Material == Enum.Material.Neon then
						if not R:FindFirstChild("NameEsp") then
							local Y = Instance.new("BillboardGui", R);
							Y.Name = "NameEsp";
							Y.ExtentsOffset = Vector3.new(0, 1, 0);
							Y.Size = UDim2.new(1, 200, 1, 30);
							Y.Adornee = R;
							Y.AlwaysOnTop = true;
							local d = Instance.new("TextLabel", Y);
							d.Font = "Code";
							d.FontSize = "Size14";
							d.TextWrapped = true;
							d.Size = UDim2.new(1, 0, 1, 0);
							d.TextYAlignment = "Top";
							d.BackgroundTransparency = 1;
							d.TextStrokeTransparency = .5;
							d.TextColor3 = Color3.fromRGB(80, 245, 245);
						else
							R.NameEsp.TextLabel.Text = "Gear" .. ("   \n" .. (nq((d.Character.Head.Position - R.Position).Magnitude / 3) .. " M"));
						end;
					end;
				else
					if R:FindFirstChild("NameEsp") then
						(R:FindFirstChild("NameEsp")):Destroy();
					end;
				end;
			end);
		end;
	end;
AdvanFruitEsp = function()
		if advanEsp == true then
			for Y, R in pairs(Q.NPCs:GetChildren()) do
				if R.Name == "Advanced Fruit Dealer" then
					if not workspace:FindFirstChild("Adv") then
						Adv = Instance.new("Part");
						Adv.Name = "Adv";
						Adv.Transparency = 1;
						Adv.Size = Vector3.new(1, 1, 1);
						Adv.Anchored = true;
						Adv.CanCollide = false;
						Adv.Parent = workspace;
						Adv.CFrame = R.HumanoidRootPart.CFrame;
					elseif workspace:FindFirstChild("Adv") then
						if not Adv:FindFirstChild("NameEsp") then
							local Y = Instance.new("BillboardGui", Adv);
							Y.Name = "NameEsp";
							Y.ExtentsOffset = Vector3.new(0, 1, 0);
							Y.Size = UDim2.new(1, 200, 1, 30);
							Y.Adornee = Adv;
							Y.AlwaysOnTop = true;
							local d = Instance.new("TextLabel", Y);
							d.Font = "Code";
							d.FontSize = "Size14";
							d.TextWrapped = true;
							d.Size = UDim2.new(1, 0, 1, 0);
							d.TextYAlignment = "Top";
							d.BackgroundTransparency = 1;
							d.TextStrokeTransparency = .5;
							d.TextColor3 = Color3.fromRGB(80, 245, 245);
						else
							Adv.NameEsp.TextLabel.Text = R.Name .. ("   \n" .. (nq((d.Character.Head.Position - R.HumanoidRootPart.Position).Magnitude / 3) .. " M"));
						end;
					end;
				end;
			end;
		else
			if workspace:FindFirstChild("Adv") then
				(workspace:FindFirstChild("Adv")):Destroy();
			end;
		end;
	end;
HakiClorEsp = function()
		if ColorEsp == true then
			for Y, R in pairs(Q.NPCs:GetChildren()) do
				if R.Name == "Barista Cousin" then
					if not workspace:FindFirstChild("Gay") then
						Gay = Instance.new("Part");
						Gay.Name = "Gay";
						Gay.Transparency = 1;
						Gay.Size = Vector3.new(1, 1, 1);
						Gay.Anchored = true;
						Gay.CanCollide = false;
						Gay.Parent = workspace;
						Gay.CFrame = R.HumanoidRootPart.CFrame;
					elseif workspace:FindFirstChild("Gay") then
						if not Gay:FindFirstChild("NameEsp") then
							local Y = Instance.new("BillboardGui", Gay);
							Y.Name = "NameEsp";
							Y.ExtentsOffset = Vector3.new(0, 1, 0);
							Y.Size = UDim2.new(1, 200, 1, 30);
							Y.Adornee = Gay;
							Y.AlwaysOnTop = true;
							local d = Instance.new("TextLabel", Y);
							d.Font = "Code";
							d.FontSize = "Size14";
							d.TextWrapped = true;
							d.Size = UDim2.new(1, 0, 1, 0);
							d.TextYAlignment = "Top";
							d.BackgroundTransparency = 1;
							d.TextStrokeTransparency = .5;
							d.TextColor3 = Color3.fromRGB(80, 245, 245);
						else
							Gay.NameEsp.TextLabel.Text = R.Name .. ("   \n" .. (nq((d.Character.Head.Position - R.HumanoidRootPart.Position).Magnitude / 3) .. " M"));
						end;
					end;
				end;
			end;
		else
			if workspace:FindFirstChild("Gay") then
				(workspace:FindFirstChild("Gay")):Destroy();
			end;
		end;
	end;
LegenSword = function()
		if LegenS == true then
			for Y, R in pairs(Q.NPCs:GetChildren()) do
				if R.Name == "Legendary Sword Dealer " then
					if not workspace:FindFirstChild("Lgd") then
						Lgd = Instance.new("Part");
						Lgd.Name = "Lgd";
						Lgd.Transparency = 1;
						Lgd.Size = Vector3.new(1, 1, 1);
						Lgd.Anchored = true;
						Lgd.CanCollide = false;
						Lgd.Parent = workspace;
						Lgd.CFrame = R.HumanoidRootPart.CFrame;
					elseif workspace:FindFirstChild("Lgd") then
						if not Lgd:FindFirstChild("NameEsp") then
							local Y = Instance.new("BillboardGui", Lgd);
							Y.Name = "NameEsp";
							Y.ExtentsOffset = Vector3.new(0, 1, 0);
							Y.Size = UDim2.new(1, 200, 1, 30);
							Y.Adornee = Lgd;
							Y.AlwaysOnTop = true;
							local d = Instance.new("TextLabel", Y);
							d.Font = "Code";
							d.FontSize = "Size14";
							d.TextWrapped = true;
							d.Size = UDim2.new(1, 0, 1, 0);
							d.TextYAlignment = "Top";
							d.BackgroundTransparency = 1;
							d.TextStrokeTransparency = .5;
							d.TextColor3 = Color3.fromRGB(80, 245, 245);
						else
							Lgd.NameEsp.TextLabel.Text = R.Name .. ("   \n" .. (nq((d.Character.Head.Position - R.HumanoidRootPart.Position).Magnitude / 3) .. " M"));
						end;
					end;
				end;
			end;
		else
			if workspace:FindFirstChild("Lgd") then
				(workspace:FindFirstChild("Lgd")):Destroy();
			end;
		end;
	end;
ChestEsp = function()
		if ChestESP then
			local Y = game:GetService("CollectionService");
			local d = game:GetService("Players");
			local R = d.LocalPlayer;
			local Q = R.Character or R.CharacterAdded:Wait();
			local r = (Q:GetPivot()).Position;
			local a = Y:GetTagged("_ChestTagged");
			for Y, d in ipairs(a) do
				local R = false;
				repeat
					if not SelectedIsland or d:IsDescendantOf(SelectedIsland) then
						if not d:GetAttribute("IsDisabled") then
							local Y;
							local Q, a = pcall(function()
									return (d:GetPivot()).Position;
								end);
							if Q then
								Y = a;
							elseif d:IsA("BasePart") then
								Y = d.Position;
							else
								R = true;
								break;
							end;
							local w = (Y - r).Magnitude;
							local F = (d:GetFullName()):gsub("[^%w_]", "_");
							local M = d:FindFirstChild("ChestEspAttachment");
							if not M then
								local Y = Instance.new("Attachment");
								Y.Name = "ChestEspAttachment";
								Y.Parent = d;
								Y.Position = Vector3.new(0, 3, 0);
								local R = Instance.new("BillboardGui");
								R.Name = "NameEsp";
								R.Size = UDim2.new(0, 200, 0, 30);
								R.Adornee = Y;
								R.ExtentsOffset = Vector3.new(0, 1, 0);
								R.AlwaysOnTop = true;
								R.Parent = Y;
								local Q = Instance.new("TextLabel");
								Q.Font = Enum.Font.Code;
								Q.TextSize = 14;
								Q.TextWrapped = true;
								Q.Size = UDim2.new(1, 0, 1, 0);
								Q.TextYAlignment = Enum.TextYAlignment.Top;
								Q.BackgroundTransparency = 1;
								Q.TextStrokeTransparency = .5;
								Q.TextColor3 = Color3.fromRGB(80, 245, 245);
								Q.Parent = R;
							end;
							local K = M and M:FindFirstChild("NameEsp");
							if K then
								local Y = math.floor(w / 3);
								local R = d.Name:gsub("Label", "");
								K.TextLabel.Text = string.format("[%s] %d M", R, Y);
							end;
							if _G_AutoFarmChest and w <= 20 then
								if M then
									M:Destroy();
								end;
							end;
						end;
					end;
					R = true;
				until true;
				if not R then
					break;
				end;
			end;
		else
			for Y, d in ipairs((game:GetService("CollectionService")):GetTagged("_ChestTagged")) do
				local R = d:FindFirstChild("ChestEspAttachment");
				if R then
					R:Destroy();
				end;
			end;
		end;
	end;
berriesEsp = function()
		if BerryEsp then
			local Y = game:GetService("CollectionService");
			local d = game:GetService("Players");
			local R = d.LocalPlayer;
			local Q = Y:GetTagged("BerryBush");
			for Y, d in ipairs(Q) do
				local Q = (d.Parent:GetPivot()).Position;
				for Y, d in pairs(d:GetAttributes()) do
					if d and (not BerryArray or table.find(BerryArray, d)) then
						local Y = "BerryEspPart_" .. (d .. ("_" .. tostring(Q)));
						local r = workspace:FindFirstChild(Y);
						if not r then
							r = Instance.new("Part");
							r.Name = Y;
							r.Transparency = 1;
							r.Size = Vector3.new(1, 1, 1);
							r.Anchored = true;
							r.CanCollide = false;
							r.Parent = workspace;
							r.CFrame = CFrame.new(Q);
						end;
						if not r:FindFirstChild("NameEsp") then
							local Y = Instance.new("BillboardGui", r);
							Y.Name = "NameEsp";
							Y.ExtentsOffset = Vector3.new(0, 1, 0);
							Y.Size = UDim2.new(0, 200, 0, 30);
							Y.Adornee = r;
							Y.AlwaysOnTop = true;
							local d = Instance.new("TextLabel", Y);
							d.Font = Enum.Font.Code;
							d.TextSize = 14;
							d.TextWrapped = true;
							d.Size = UDim2.new(1, 0, 1, 0);
							d.TextYAlignment = Enum.TextYAlignment.Top;
							d.BackgroundTransparency = 1;
							d.TextStrokeTransparency = .5;
							d.TextColor3 = Color3.fromRGB(80, 245, 245);
							d.Parent = Y;
						end;
						local a = r:FindFirstChild("NameEsp");
						local w = (R.Character.Head.Position - Q).Magnitude / 3;
						a.TextLabel.Text = "[" .. (d .. ("]" .. (" " .. (math.round(w) .. " M"))));
						if _G.AutoBerry and math.round(w) <= 20 then
							r:Destroy();
						end;
					end;
				end;
			end;
		else
			for Y, d in ipairs(workspace:GetChildren()) do
				if d:IsA("Part") and d.Name:match("BerryEspPart_.*") then
					d:Destroy();
				end;
			end;
		end;
	end;
Kq.CreateToggle({
	Title = "Esp Berries",
	Description = "",
	Default = false,
	Callback = function(Y)
		BerryEsp = Y;
		task.spawn(function()
			while BerryEsp do
				task.wait();
				berriesEsp();
			end;
		end);
	end,
});
Kq.CreateToggle({
	Title = "Esp Players",
	Description = "",
	Default = false,
	Callback = function(Y)
		PlayerEsp = Y;
		task.spawn(function()
			while PlayerEsp do
				task.wait();
				EspPly();
			end;
		end);
	end,
});
Kq.CreateToggle({
	Title = "Esp Chests",
	Description = "",
	Default = false,
	Callback = function(Y)
		ChestESP = Y;
		task.spawn(function()
			while ChestESP do
				task.wait();
				ChestEsp();
			end;
		end);
	end,
});
Kq.CreateToggle({
	Title = "Esp Fruits",
	Description = "",
	Default = false,
	Callback = function(Y)
		DevilFruitESP = Y;
		task.spawn(function()
			while DevilFruitESP do
				task.wait();
				DevEsp();
			end;
		end);
	end,
});
Kq.CreateToggle({
	Title = "Esp Island Location",
	Description = "",
	Default = false,
	Callback = function(Y)
		IslandESP = Y;
		task.spawn(function()
			while IslandESP do
				task.wait();
				LocationEsp();
			end;
		end);
	end,
});
(function()
if World2 then
	Kq.CreateToggle({
		Title = "Esp Flower",
		Description = "",
		Default = false,
		Callback = function(Y)
			FlowerESP = Y;
			task.spawn(function()
				while FlowerESP do
					task.wait();
					flowerEsp();
				end;
			end);
		end,
	});
	Kq.CreateToggle({
		Title = "Esp Legendary Sword",
		Description = "",
		Default = false,
		Callback = function(Y)
			LegenS = Y;
			task.spawn(function()
				while LegenS do
					task.wait();
					LegenSword();
				end;
			end);
		end,
	});
end;
end)()
(function()
if World2 or World3 then
	Kq.CreateToggle({
		Title = "Esp Aura Colour Dealers",
		Description = "",
		Default = false,
		Callback = function(Y)
			ColorEsp = Y;
			task.spawn(function()
				while ColorEsp do
					task.wait();
					HakiClorEsp();
				end;
			end);
		end,
	});
end;
end)()
(function()
if World3 then
	Kq.CreateToggle({
		Title = "Esp Gears",
		Description = "",
		Default = false,
		Callback = function(Y)
			ESPGear = Y;
			task.spawn(function()
				while ESPGear do
					task.wait();
					gearEsp();
				end;
			end);
		end,
	});
	Kq.CreateToggle({
		Title = "Esp SeaEvent Island",
		Description = "",
		Default = false,
		Callback = function(Y)
			EspEventIsland = Y;
			task.spawn(function()
				while EspEventIsland do
					task.wait();
					EventIslandEsp();
				end;
			end);
		end,
	});
	Kq.CreateToggle({
		Title = "Esp Advanced Fruits Dealer",
		Description = "",
		Default = false,
		Callback = function(Y)
			advanEsp = Y;
			task.spawn(function()
				while advanEsp do
					task.wait();
					AdvanFruitEsp();
				end;
			end);
		end,
	});
end;
end)()
local Iq = kz.CreateSection("Travel - Worlds");
Iq.CreateButton({ Title = "Travel East Blue (World 1)", Callback = function()
		Q.Remotes.CommF_:InvokeServer("TravelMain");
	end });
Iq.CreateButton({ Title = "Travel Dressrosa (World 2)", Callback = function()
		Q.Remotes.CommF_:InvokeServer("TravelDressrosa");
	end });
Iq.CreateButton({ Title = "Travel Zou (World 3)", Callback = function()
		Q.Remotes.CommF_:InvokeServer("TravelZou");
	end });
local Wq = kz.CreateSection("Travel - Island");
Location = {};
for Y, d in pairs(workspace._WorldOrigin.Locations:GetChildren()) do
	table.insert(Location, d.Name);
end;
Wq.CreateDropdown({
	Title = "Select Travelling",
	Description = "",
	Values = Location,
	Default = false,
	Multi = false,
	Callback = function(Y)
		_G.Island = Y;
	end,
});
Wq.CreateToggle({
	Title = "Auto Travel",
	Description = "Automatic teleport to pos island",
	Default = false,
	Callback = function(Y)
		_G.Teleport = Y;
		if Y then
			task.spawn(function()
				local sea3SafeTargets = {
					["Port Town"] = CFrame.new(-611, 87, 6436),
					["Hydra Island"] = CFrame.new(5298, 604, 344),
					["Dragon Dojo"] = CFrame.new(5704, 1198, 937),
					["Great Tree"] = CFrame.new(3036, 845, -7150),
					["Castle on the Sea"] = CFrame.new(-5437, 345, -2702),
					["Mansion"] = CFrame.new(-12548, 320, -7488),
					["Floating Turtle"] = CFrame.new(-12165, 380, -8455),
					["Haunted Castle"] = CFrame.new(-9531, 172, 5763),
					["North Pole"] = CFrame.new(-1142, 87, -14481),
					["Tiki Outpost"] = CFrame.new(-16642, 243, 435),
				}
				while _G.Teleport do
					local locations = workspace:FindFirstChild("_WorldOrigin") and workspace._WorldOrigin:FindFirstChild("Locations");
					local island = locations and locations:FindFirstChild(_G.Island, true);
					local root = d.Character and d.Character:FindFirstChild("HumanoidRootPart");
					if not island or not root then break; end;
					local target = World3 and sea3SafeTargets[_G.Island] or nil;
					target = target or island.CFrame * CFrame.new(0, 30, 0);
					if (root.Position-target.Position).Magnitude <= 10 then break; end;
					if World1 and target.Position.Y > 3000 and (root.Position-target.Position).Magnitude > 3500 then
						Q.Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(-7894, 5547, -380));
					elseif World1 and target.Position.X > 30000 and (root.Position-target.Position).Magnitude > 3500 then
						Q.Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(61163, 11, 1819));
					elseif World3 and _G.Island == "Castle on the Sea" and (root.Position-target.Position).Magnitude > 3500 then
						Q.Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(-5098, 316, -3143));
					elseif World3 and _G.Island == "Mansion" and (root.Position-target.Position).Magnitude > 3500 then
						Q.Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(-12471, 375, -7552));
					else
						_tp(target);
					end;
					task.wait(.25);
				end;
				_G.Teleport = false;
			end);
		end;
	end,
});
local Nq = kz.CreateSection("Travel - Portal");
(function()
if World1 then
	Location_Portal = { "Lower Sky", "Upper Sky", "UnderWater" };
elseif World2 then
	Location_Portal = { "SwanRoom", "Cursed Ship" };
elseif World3 then
	Location_Portal = {
			"Castle On The Sea",
			"Mansion Cafe",
			"Hydra Teleport",
			"Canvendish Room",
			"Temple of Time",
		};
end;
end)()
Nq.CreateDropdown({
	Title = "Select Portal",
	Description = "",
	Values = Location_Portal,
	Default = false,
	Multi = false,
	Callback = function(Y)
		_G.Island_PT = Y;
	end,
});
Nq.CreateButton({ Title = "requestEntrance", Callback = function()
		if _G.Island_PT == "Lower Sky" then
			Q.Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(-4607.82275, 872.54248, -1667.55688));
		elseif _G.Island_PT == "Upper Sky" then
			Q.Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(-7894.61767578, 5547.14160156, -380.29119873));
		elseif _G.Island_PT == "UnderWater" then
			Q.Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(61163, 11, 1819));
		elseif _G.Island_PT == "SwanRoom" then
			Q.Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(2285, 15, 905));
		elseif _G.Island_PT == "Cursed Ship" then
			Q.Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(923, 126, 32852));
		elseif _G.Island_PT == "Castle On The Sea" then
			Q.Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(-5097.93164, 316.447021, -3142.66602, -0.40500789, -4.31682743e-08, .914313197, -1.90943332e-08, 1, 3.8755779e-08, -0.91431319, -1.76180437e-09, -0.40500789));
		elseif _G.Island_PT == "Mansion Cafe" then
			Q.Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(-12471.16992187, 374.94024658, -7551.67773437));
		elseif _G.Island_PT == "Hydra Teleport" then
			Q.Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(5643.45263671, 1013.08581542, -340.51025390));
		elseif _G.Island_PT == "Canvendish Room" then
			Q.Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(5314.54638671, 22.56221961, -127.06755065));
		elseif _G.Island_PT == "Temple of Time" then
			Q.Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(28310.0234, 14895.1123, 109.456741, -0.46969014, -2.85620132e-08, -0.88283133, -3.23509219e-08, 1, -1.51411736e-08, .882831335, 2.14487486e-08, -0.46969014));
		end;
	end });
local Dq = kz.CreateSection("Travel - NPCs");
for Y, d in pairs(Q.NPCs:GetChildren()) do
	table.insert(m, d.Name);
end;
Dq.CreateDropdown({
	Title = "Select NPCs",
	Description = "",
	Values = m,
	Default = false,
	Multi = false,
	Callback = function(Y)
		NPClist = Y;
	end,
});
Dq.CreateToggle({
	Title = "Auto Tween to NPCs",
	Description = "Automatic teleport to pos Npcs",
	Default = false,
	Callback = function(Y)
		_G.TPNpc = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		if _G.TPNpc then
			pcall(function()
				for Y, d in pairs(Q.NPCs:GetChildren()) do
					if d.Name == NPClist then
						_tp(d.HumanoidRootPart.CFrame);
					end;
				end;
			end);
		end;
	end;
end);
local Aq = Lz.CreateSection("Fruits Options");
local uq = {};
local function gq(Y)
	local d = tostring(Y);
	while true do
		d, k = d:gsub("^(-?%d+)(%d%d%d)", "%1,%2");
		if k == 0 then
			break;
		end;
	end;
	return d;
end;
for Y, d in pairs(Q.Remotes.CommF_:InvokeServer("GetFruits", true)) do
	if d.OnSale == true then
		local Y = gq(d.Price);
		local R = d.Name;
		table.insert(uq, R);
	end;
end;
local zq = {};
for Y, d in pairs(Q.Remotes.CommF_:InvokeServer("GetFruits", false)) do
	if d.OnSale == true then
		local Y = gq(d.Price);
		local R = d.Name;
		table.insert(zq, R);
	end;
end;
Aq.CreateDropdown({
	Title = "Select Fruit Stock",
	Description = "",
	Values = zq,
	Default = false,
	Multi = false,
	Callback = function(Y)
		_G.SelectFruit = Y;
	end,
});
Aq.CreateButton({ Title = "Buy Basic Stock", Callback = function()
		Q.Remotes.CommF_:InvokeServer("PurchaseRawFruit", _G.SelectFruit);
	end });
Aq.CreateDropdown({
	Title = "Select Mirage Fruit",
	Description = "",
	Values = uq,
	Default = false,
	Multi = false,
	Callback = function(Y)
		SelectF_Adv = Y;
	end,
});
local iq = {};
for Y, d in pairs(Q.Remotes.CommF_:InvokeServer("GetFruits", false)) do
	if d.OnSale == true then
		local Y = gq(d.Price);
		local R = d.Name;
		table.insert(iq, R);
	end;
end;
Aq.CreateButton({ Title = "Buy Mirage Stock", Callback = function()
		Q.Remotes.CommF_:InvokeServer("PurchaseRawFruit", SelectF_Adv);
	end });
Aq.CreateToggle({
	Title = "Auto Random Fruit",
	Description = "Automatic random devil fruit",
	Default = false,
	Callback = function(Y)
		_G.Random_Auto = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		pcall(function()
			if _G.Random_Auto and os.clock() >= VoidGacha.NextFruit then
				VoidGacha.NextFruit = os.clock() + 2
				Q.Remotes.CommF_:InvokeServer("Cousin", "Buy");
				VoidCloseGachaGui()
			end;
		end);
	end;
end);
Aq.CreateToggle({
	Title = "Auto Drop Fruit",
	Description = "Automatic drop devil fruit",
	Default = false,
	Callback = function(Y)
		_G.DropFruit = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		if _G.DropFruit then
			pcall(function()
				DropFruits();
			end);
		end;
	end;
end);
Aq.CreateToggle({
	Title = "Auto Store Fruit",
	Description = "Automatic store devil fruit",
	Default = false,
	Callback = function(Y)
		_G.StoreF = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		if _G.StoreF then
			pcall(function()
				UpdStFruit();
			end);
		end;
	end;
end);
Aq.CreateToggle({
	Title = "Auto Tween to Fruit",
	Description = "Automatic tween to get devil fruit",
	Default = false,
	Callback = function(Y)
		_G.TwFruits = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		if _G.TwFruits then
			pcall(function()
				for Y, d in pairs(workspace:GetChildren()) do
					if string.find(d.Name, "Fruit") then
						_tp(d.Handle.CFrame);
					end;
				end;
			end);
		end;
	end;
end);
Aq.CreateToggle({
	Title = "Auto Collect Fruit",
	Description = "Automatic bring devil fruit",
	Default = false,
	Callback = function(Y)
		_G.InstanceF = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		if _G.InstanceF then
			pcall(function()
				collectFruits(_G.InstanceF);
			end);
		end;
	end;
end);
local Uq = Pz.CreateSection("Shop Options");
Uq.CreateButton({ Title = "Buy Buso", Callback = function()
		TweenToStyleDealer({"Haki"});
		Q.Remotes.CommF_:InvokeServer("BuyHaki", "Buso");
	end });
Uq.CreateButton({ Title = "Buy Geppo", Callback = function()
		TweenToStyleDealer({"Haki"});
		Q.Remotes.CommF_:InvokeServer("BuyHaki", "Geppo");
	end });
Uq.CreateButton({ Title = "Buy Soru", Callback = function()
		TweenToStyleDealer({"Haki"});
		Q.Remotes.CommF_:InvokeServer("BuyHaki", "Soru");
	end });
Uq.CreateButton({ Title = "Buy Ken", Callback = function()
		TweenToStyleDealer({"Ken"});
		Q.Remotes.CommF_:InvokeServer("KenTalk", "Buy");
	end });
local Cq = Pz.CreateSection("Fighting - Style");
Cq.CreateButton({ Title = "Buy Black Leg", Callback = function()
		TweenToStyleDealer({"Black Leg"});
		Q.Remotes.CommF_:InvokeServer("BuyBlackLeg");
	end });
Cq.CreateButton({ Title = "Buy Electro", Callback = function()
		TweenToStyleDealer({"Electro"});
		Q.Remotes.CommF_:InvokeServer("BuyElectro");
	end });
Cq.CreateButton({ Title = "Buy Fishman Karate", Callback = function()
		TweenToStyleDealer({"Fishman Karate"});
		Q.Remotes.CommF_:InvokeServer("BuyFishmanKarate");
	end });
Cq.CreateButton({ Title = "Buy DragonClaw", Callback = function()
		TweenToStyleDealer({"Dragon Claw"});
		Q.Remotes.CommF_:InvokeServer("BlackbeardReward", "DragonClaw", "2");
	end });
Cq.CreateButton({ Title = "Buy Superhuman", Callback = function()
		TweenToStyleDealer({"Superhuman"});
		Q.Remotes.CommF_:InvokeServer("BuySuperhuman");
	end });
Cq.CreateButton({ Title = "Buy Death Step", Callback = function()
		TweenToStyleDealer({"Death Step"});
		Q.Remotes.CommF_:InvokeServer("BuyDeathStep");
	end });
Cq.CreateButton({ Title = "Buy Sharkman Karate", Callback = function()
		TweenToStyleDealer({"Sharkman Karate", "Sharkman"});
		Q.Remotes.CommF_:InvokeServer("BuySharkmanKarate");
	end });
Cq.CreateButton({ Title = "Buy ElectricClaw", Callback = function()
		TweenToStyleDealer({"Electric Claw", "Electricity"});
		Q.Remotes.CommF_:InvokeServer("BuyElectricClaw");
	end });
Cq.CreateButton({ Title = "Buy DragonTalon", Callback = function()
		TweenToStyleDealer({"Dragon Talon", "Longma"});
		Q.Remotes.CommF_:InvokeServer("BuyDragonTalon");
	end });
Cq.CreateButton({ Title = "Buy Godhuman", Callback = function()
		TweenToStyleDealer({"Strongest", "Godhuman", "God Human"});
		Q.Remotes.CommF_:InvokeServer("BuyGodhuman");
	end });
Cq.CreateButton({ Title = "Buy SanguineArt", Callback = function()
		TweenToStyleDealer({"Sanguine"});
		Q.Remotes.CommF_:InvokeServer("BuySanguineArt");
	end });
local vq = Pz.CreateSection("Accessory");
vq.CreateButton({ Title = "Buy Tomoe Ring", Callback = function()
		Q.Remotes.CommF_:InvokeServer("BuyItem", "Tomoe Ring");
	end });
vq.CreateButton({ Title = "Buy Black Cape", Callback = function()
		Q.Remotes.CommF_:InvokeServer("BuyItem", "Black Cape");
	end });
vq.CreateButton({ Title = "Buy Swordsman Hat", Callback = function()
		Q.Remotes.CommF_:InvokeServer("BuyItem", "Swordsman Hat");
	end });
vq.CreateButton({ Title = "Buy Bizarre Rifle", Callback = function()
		Q.Remotes.CommF_:InvokeServer("Ectoplasm", "Buy", 1);
	end });
vq.CreateButton({ Title = "Buy Ghoul Mask", Callback = function()
		Q.Remotes.CommF_:InvokeServer("Ectoplasm", "Buy", 2);
	end });
local mq = Pz.CreateSection("Accessory SeaEvent");
mq.CreateButton({ Title = "Craft Dragonheart", Callback = function()
		Q.Remotes.CommF_:InvokeServer("CraftItem", "Craft", "Dragonheart");
	end });
mq.CreateButton({ Title = "Craft Dragonstorm", Callback = function()
		Q.Remotes.CommF_:InvokeServer("CraftItem", "Craft", "Dragonstorm");
	end });
mq.CreateButton({ Title = "Craft DinoHood", Callback = function()
		Q.Remotes.CommF_:InvokeServer("CraftItem", "Craft", "DinoHood");
	end });
mq.CreateButton({ Title = "Craft SharkTooth", Callback = function()
		Q.Remotes.CommF_:InvokeServer("CraftItem", "Craft", "SharkTooth");
	end });
mq.CreateButton({ Title = "Craft TerrorJaw", Callback = function()
		Q.Remotes.CommF_:InvokeServer("CraftItem", "Craft", "TerrorJaw");
	end });
mq.CreateButton({ Title = "Craft SharkAnchor", Callback = function()
		Q.Remotes.CommF_:InvokeServer("CraftItem", "Craft", "SharkAnchor");
	end });
mq.CreateButton({ Title = "Craft LeviathanCrown", Callback = function()
		Q.Remotes.CommF_:InvokeServer("CraftItem", "Craft", "LeviathanCrown");
	end });
mq.CreateButton({ Title = "Craft LeviathanShield", Callback = function()
		Q.Remotes.CommF_:InvokeServer("CraftItem", "Craft", "LeviathanShield");
	end });
mq.CreateButton({ Title = "Craft LeviathanBoat", Callback = function()
		Q.Remotes.CommF_:InvokeServer("CraftItem", "Craft", "LeviathanBoat");
	end });
mq.CreateButton({ Title = "Craft LegendaryScroll", Callback = function()
		Q.Remotes.CommF_:InvokeServer("CraftItem", "Craft", "LegendaryScroll");
	end });
mq.CreateButton({ Title = "Craft MythicalScroll", Callback = function()
		Q.Remotes.CommF_:InvokeServer("CraftItem", "Craft", "MythicalScroll");
	end });
local yq = Pz.CreateSection("Weapon World1");
yq.CreateButton({ Title = "Buy Cutlass", Callback = function()
		Q.Remotes.CommF_:InvokeServer("BuyItem", "Cutlass");
	end });
yq.CreateButton({ Title = "Buy Katana", Callback = function()
		Q.Remotes.CommF_:InvokeServer("BuyItem", "Katana");
	end });
yq.CreateButton({ Title = "Buy Iron Mace", Callback = function()
		Q.Remotes.CommF_:InvokeServer("BuyItem", "Iron Mace");
	end });
yq.CreateButton({ Title = "Buy Duel Katana", Callback = function()
		Q.Remotes.CommF_:InvokeServer("BuyItem", "Duel Katana");
	end });
yq.CreateButton({ Title = "Buy Triple Katana", Callback = function()
		Q.Remotes.CommF_:InvokeServer("BuyItem", "Triple Katana");
	end });
yq.CreateButton({ Title = "Buy Pipe", Callback = function()
		Q.Remotes.CommF_:InvokeServer("BuyItem", "Pipe");
	end });
yq.CreateButton({ Title = "Buy Dual-Headed Blade", Callback = function()
		Q.Remotes.CommF_:InvokeServer("BuyItem", "Dual-Headed Blade");
	end });
yq.CreateButton({ Title = "Buy Bisento", Callback = function()
		Q.Remotes.CommF_:InvokeServer("BuyItem", "Bisento");
	end });
yq.CreateButton({ Title = "Buy Soul Cane", Callback = function()
		Q.Remotes.CommF_:InvokeServer("BuyItem", "Soul Cane");
	end });
yq.CreateButton({ Title = "Buy Slingshot", Callback = function()
		Q.Remotes.CommF_:InvokeServer("BuyItem", "Slingshot");
	end });
yq.CreateButton({ Title = "Buy Musket", Callback = function()
		Q.Remotes.CommF_:InvokeServer("BuyItem", "Musket");
	end });
yq.CreateButton({ Title = "Buy Dual Flintlock", Callback = function()
		Q.Remotes.CommF_:InvokeServer("BuyItem", "Dual Flintlock");
	end });
yq.CreateButton({ Title = "Buy Flintlock", Callback = function()
		Q.Remotes.CommF_:InvokeServer("BuyItem", "Flintlock");
	end });
yq.CreateButton({ Title = "Buy Refined Flintlock", Callback = function()
		Q.Remotes.CommF_:InvokeServer("BuyItem", "Refined Flintlock");
	end });
yq.CreateButton({ Title = "Buy Cannon", Callback = function()
		Q.Remotes.CommF_:InvokeServer("BuyItem", "Cannon");
	end });
yq.CreateButton({ Title = "Buy Kabucha", Callback = function()
		Q.Remotes.CommF_:InvokeServer("BlackbeardReward", "Slingshot", "2");
	end });
local bq = Pz.CreateSection("Fragments shop");
bq.CreateButton({ Title = "Buy Refund Stats", Callback = function()
		Q.Remotes.CommF_:InvokeServer("BlackbeardReward", "Refund", "2");
	end });
bq.CreateButton({ Title = "Buy Reroll Race", Callback = function()
		Q.Remotes.CommF_:InvokeServer("BlackbeardReward", "Reroll", "2");
	end });
bq.CreateButton({ Title = "Buy Ghoul Race (2.5k)", Callback = function()
		Q.Remotes.CommF_:InvokeServer("Ectoplasm", " Change", 4);
	end });
bq.CreateButton({ Title = "Buy Cyborg Race (2.5k)", Callback = function()
		Q.Remotes.CommF_:InvokeServer("CyborgTrainer", " Buy");
	end });
local cq = jz.CreateSection("Server - Function");
cq.CreateButton({ Title = "Rejoin Server", Callback = function()
		(game:GetService("TeleportService")):Teleport(game.PlaceId, game.Players.LocalPlayer);
	end });
cq.CreateButton({ Title = "Hop Server", Callback = function()
		Hop();
	end });
cq.CreateButton({ Title = "Hop to Lowest Players", Callback = function()
		Hop();
	end });
cq.CreateButton({ Title = "Hop to Lowest Pings Server", Callback = function()
		Hop();
	end });
cq.CreateBox({
	Title = "JobID",
	Placeholder = "Type something...",
	Default = "",
	Number = false,
}, function(Y)
	_G.JobId = Y;
end);
task.spawn(function()
	while task.wait(T) do
		if _G.JobId then
			pcall(function()
				local Y;
				Y = d.OnTeleport:Connect(function(d)
						if d == Enum.TeleportState.Failed then
							Y:Disconnect();
							if workspace:FindFirstChild("Message") then
								workspace.Message:Destroy();
							end;
						end;
					end);
			end);
		end;
	end;
end);
cq.CreateButton({ Title = "Teleport [Job ID]", Callback = function()
		Q.__ServerBrowser:InvokeServer("teleport", _G.JobId);
	end });
cq.CreateButton({ Title = "Copy JobID", Callback = function()
		setclipboard(tostring(game.JobId));
	end });
local Hq = jz.CreateSection("Player Gui / Others");
Hq.CreateButton({ Title = "Open Awakenings Expert", Callback = function()
		d.PlayerGui.Main.AwakeningToggler.Visible = true;
	end });
Hq.CreateButton({ Title = "Open Title Selection", Callback = function()
		Q.Remotes.CommF_:InvokeServer("getTitles", true);
		d.PlayerGui.Main.Titles.Visible = true;
	end });
Hq.CreateToggle({
	Title = "Disable Chat GUI",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.Rechat = Y;
		local d = game:GetService("StarterGui");
		if _G.Rechat then
			d:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false);
		else
			d:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true);
		end;
	end,
});
Hq.CreateToggle({
	Title = "Disable Leader Board GUI",
	Description = "",
	Default = false,
	Callback = function(Y)
		ReLeader = Y;
		local d = game:GetService("StarterGui");
		if ReLeader then
			d:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false);
		else
			d:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true);
		end;
	end,
});
Hq.CreateButton({ Title = "Set Pirate Team", Callback = function()
		Pirates();
	end });
Hq.CreateButton({ Title = "Set Marine Team", Callback = function()
		Marines();
	end });
Hq.CreateToggle({
	Title = "Unlock All Portals",
	Description = "unlocked portal for who doesn\'t defeat rip_indra",
	Default = false,
	Callback = function(Y)
		_G.PortalUnLock = Y;
	end,
});
task.spawn(function()
	while task.wait(T) do
		pcall(function()
			if _G.PortalUnLock then
				if f.Pos(CstlePos_Miti, 8) then
					Q.Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(-12471.16992187, 374.94024658, -7551.67773437));
				elseif f.Pos(Man3Pos_Miti, 8) then
					Q.Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(-5072.08984375, 314.54129028, -3151.10986328));
				elseif f.Pos(HydraPos_Miti, 8) then
					Q.Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(5748.75878906, 610.44982910, -267.81704711));
				elseif f.Pos(HydratoCastle, 8) then
					Q.Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(-5072.08984375, 314.54129028, -3151.10986328));
				end;
			end;
		end);
	end;
end);
local Sq = jz.CreateSection("Graphics / Haki Stats");
HakiSt = {
		"State 0",
		"State 1",
		"State 2",
		"State 3",
		"State 4",
		"State 5",
	};
Sq.CreateDropdown({
	Title = "Select Haki States",
	Description = "",
	Values = HakiSt,
	Default = false,
	Multi = false,
	Callback = function(Y)
		_G.SelectStateHaki = Y;
	end,
});
Sq.CreateButton({ Title = "ChangeBusoStage", Callback = function()
		if _G.SelectStateHaki == "State 0" then
			Q.Remotes.CommF_:InvokeServer("ChangeBusoStage", 0);
		elseif _G.SelectStateHaki == "State 1" then
			Q.Remotes.CommF_:InvokeServer("ChangeBusoStage", 1);
		elseif _G.SelectStateHaki == "State 2" then
			Q.Remotes.CommF_:InvokeServer("ChangeBusoStage", 2);
		elseif _G.SelectStateHaki == "State 3" then
			Q.Remotes.CommF_:InvokeServer("ChangeBusoStage", 3);
		elseif _G.SelectStateHaki == "State 4" then
			Q.Remotes.CommF_:InvokeServer("ChangeBusoStage", 4);
		elseif _G.SelectStateHaki == "State 5" then
			Q.Remotes.CommF_:InvokeServer("ChangeBusoStage", 5);
		end;
	end });
Sq.CreateToggle({
	Title = "Turn on RTX Mode",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.RTXMode = Y;
		local R = game.Lighting;
		local Q = Instance.new("ColorCorrectionEffect", R);
		local r = Instance.new("ColorCorrectionEffect", R);
		local a = R.Ambient;
		local w = R.Brightness;
		local F = R.ColorShift_Top;
		local M = Q.Brightness;
		local K = Q.Contrast;
		local n = Q.TintColor;
		local I = r.TintColor;
		task.spawn(function()
			while _G.RTXMode do
				task.wait();
				R.Ambient = Color3.fromRGB(33, 33, 33);
				R.Brightness = .3;
				Q.Brightness = .176;
				Q.Contrast = .39;
				Q.TintColor = Color3.fromRGB(217, 145, 57);
				game.Lighting.FogEnd = 999;
				if not d.Character.HumanoidRootPart:FindFirstChild("PointLight") then
					local Y = Instance.new("PointLight");
					Y.Parent = d.Character.HumanoidRootPart;
					Y.Range = 15;
					Y.Color = Color3.fromRGB(217, 145, 57);
				end;
			end;
			R.Ambient = a;
			R.Brightness = w;
			R.ColorShift_Top = F;
			Q.Contrast = K;
			Q.Brightness = M;
			Q.TintColor = n;
			r.TintColor = I;
			game.Lighting.FogEnd = 2500;
			local Y = d.Character.HumanoidRootPart:FindFirstChild("PointLight");
			if Y then
				Y:Destroy();
			end;
		end);
	end,
});
Sq.CreateButton({ Title = "Turn on Fast Mode", Callback = function()
		for Y, d in next, workspace:GetDescendants() do
			if table.find(t, d.ClassName) then
				d.Material = "Plastic";
			end;
		end;
	end });
Sq.CreateButton({ Title = "Turn on Low CPU", Callback = function()
		LowCpu();
	end });
Sq.CreateButton({ Title = "Turn on increase Boats", Callback = function()
		for Y, R in pairs(workspace.Boats:GetDescendants()) do
			if table.find(jF, R.Name) and tostring(R.Owner.Value) == tostring(d.Name) then
				R.VehicleSeat.MaxSpeed = 350;
				R.VehicleSeat.Torque = .2;
				R.VehicleSeat.TurnSpeed = 5;
				R.VehicleSeat.HeadsUpDisplay = true;
			end;
		end;
	end });
Sq.CreateButton({ Title = "Remove Sky Fog", Callback = function()
		if F:FindFirstChild("LightingLayers") then
			F.LightingLayers:Destroy();
		end;
		if F:FindFirstChild("SeaTerrorCC") then
			F.SeaTerrorCC:Destroy();
		end;
		if F:FindFirstChild("FantasySky") then
			F.FantasySky:Destroy();
		end;
	end });
local oq = jz.CreateSection("Configure - God");
oq.CreateButton({ Title = "Rain Fruits (Client)", Callback = function()
		for Y, R in pairs((game:GetObjects("rbxassetid://14759368201"))[1]:GetChildren()) do
			R.Parent = game.Workspace.Map;
			R:MoveTo(d.Character.PrimaryPart.Position + Vector3.new(math.random(-50, 50), 100, math.random(-50, 50)));
			if R.Fruit:FindFirstChild("AnimationController") then
				((R.Fruit:FindFirstChild("AnimationController")):LoadAnimation(R.Fruit:FindFirstChild("Idle"))):Play();
			end;
			R.Handle.Touched:Connect(function(Y)
				if Y.Parent == d.Character then
					R.Parent = d.Backpack;
					d.Character.Humanoid:EquipTool(R);
				end;
			end);
		end;
	end });
oq.CreateToggle({ Title = "Turn on Full Bright", Default = false, Callback = function(Y)
		bright = Y;
		if Y then
			F.Ambient = Color3.new(1, 1, 1);
			F.ColorShift_Bottom = Color3.new(1, 1, 1);
			F.ColorShift_Top = Color3.new(1, 1, 1);
		else
			F.Ambient = Color3.new(0, 0, 0);
			F.ColorShift_Bottom = Color3.new(0, 0, 0);
			F.ColorShift_Top = Color3.new(0, 0, 0);
		end;
	end });
Cheat_DayNight = { "Day", "Night" };
oq.CreateDropdown({
	Title = "Select Time",
	Description = "",
	Values = Cheat_DayNight,
	Default = false,
	Multi = false,
	Callback = function(Y)
		_G.SelectDN = Y;
	end,
});
oq.CreateToggle({
	Title = "Turn on Time",
	Description = "",
	Default = false,
	Callback = function(Y)
		_G.daylightN = Y;
	end,
});
task.spawn(function()
	while task.wait() do
		if _G.daylightN then
			if _G.SelectDN == "Day" then
				F.ClockTime = 12;
			elseif _G.SelectDN == "Night" then
				F.ClockTime = 0;
			end;
		end;
	end;
end);
oq.CreateToggle({
	Title = "Turn on Walk on Water",
	Description = "walk on water",
	Default = true,
	Callback = function(Y)
		_G.WalkWater_Part = Y;
		local d = (game:GetService("Workspace")).Map["WaterBase-Plane"];
		if _G.WalkWater_Part then
			d.Size = Vector3.new(1000, 112, 1000);
		else
			d.Size = Vector3.new(1000, 80, 1000);
		end;
	end,
});
oq.CreateToggle({
	Title = "Turn on Ice Walk",
	Description = "Ice walk just like walk on water but have ice effect",
	Default = false,
	Callback = function(Y)
		_G.WalkWater = Y;
	end,
});
task.spawn(function()
	while task.wait(0.1) do  -- throttled (was every frame - lag fix)
		if _G.WalkWater then
			pcall(function()
				if d.Character and d.Character:FindFirstChild("LeftFoot") then
					local Y = Q.Assets.Models.IceSpikes4:Clone();
					Y.Parent = workspace;
					Y.Size = Vector3.new(3 + math.random(10, 12), 1.7, 3 + math.random(10, 12));
					Y.Color = Color3.fromRGB(128, 187, 219);
					Y.CFrame = CFrame.new(d.Character.Head.Position.X, -3.8, d.Character.Head.Position.Z) * CFrame.Angles((math.random() - .5) * .06, math.random() * 7, (math.random() - .5) * .07);
					local R = {};
					R.Size = Vector3.new(0, .3, 0);
					local r = w:Create(Y, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), R);
					r.Completed:Connect(function()
						Y:Destroy();
					end);
					r:Play();
				end;
			end);
		end;
	end;
end);
local Zq = game.Players.LocalPlayer;
local function Tq(Y)
	if not Y then
		return false;
	end;
	local d = Y:FindFirstChild("Humanoid");
	return d and d.Health > 0;
end;
local function kq(Y, d)
	local R = (game:GetService("Workspace")).Enemies:GetChildren();
	local Q = (game:GetService("Players")):GetPlayers();
	local r = {};
	local a = (Y:GetPivot()).Position;
	for Y, R in ipairs(R) do
		local Q = R:FindFirstChild("HumanoidRootPart");
		if Q and Tq(R) then
			local Y = (Q.Position - a).Magnitude;
			if Y <= d then
				table.insert(r, R);
			end;
		end;
	end;
	for Y, R in ipairs(Q) do
		if R ~= Zq and R.Character then
			local Y = R.Character:FindFirstChild("HumanoidRootPart");
			if Y and Tq(R.Character) then
				local Q = (Y.Position - a).Magnitude;
				if Q <= d then
					table.insert(r, R.Character);
				end;
			end;
		end;
	end;
	return r;
end;
function AttackNoCoolDown()
	local Y = (game:GetService("Players")).LocalPlayer;
	local d = Y.Character;
	if not d then
		return;
	end;
	local R = nil;
	for Y, d in ipairs(d:GetChildren()) do
		if d:IsA("Tool") then
			R = d;
			break;
		end;
	end;
	if not R then
		return;
	end;
	local Q = kq(d, 60);
	if #Q == 0 then
		return;
	end;
	local r = game:GetService("ReplicatedStorage");
	local a = r:FindFirstChild("Modules");
	if not a then
		return;
	end;
	local w = ((r:WaitForChild("Modules")):WaitForChild("Net")):WaitForChild("RE/RegisterAttack");
	local F = ((r:WaitForChild("Modules")):WaitForChild("Net")):WaitForChild("RE/RegisterHit");
	if not w or not F then
		return;
	end;
	local M, K = {}, nil;
	for Y, d in ipairs(Q) do
		if not d:GetAttribute("IsBoat") then
			local Y = {
					"RightLowerArm",
					"RightUpperArm",
					"LeftLowerArm",
					"LeftUpperArm",
					"RightHand",
					"LeftHand",
				};
			local R = d:FindFirstChild(Y[math.random(#Y)]) or d.PrimaryPart;
			if R then
				table.insert(M, { d, R });
				K = R;
			end;
		end;
	end;
	if not K then
		return;
	end;
	w:FireServer(0);
	local n = Y:FindFirstChild("PlayerScripts");
	if not n then
		return;
	end;
	local I = n:FindFirstChildOfClass("LocalScript");
	while not I do
		n.ChildAdded:Wait();
		I = n:FindFirstChildOfClass("LocalScript");
	end;
	local W;
	if getsenv then
		local Y, d = pcall(getsenv, I);
		if Y and d then
			W = d._G.SendHitsToServer;
		end;
	end;
	local N, D = pcall(function()
			return (require(a.Flags)).COMBAT_REMOTE_THREAD or false;
		end);
	if N and (D and W) then
		W(K, M);
	elseif N and not D then
		F:FireServer(K, M);
	end;
end;
CameraShakerR = require(game.ReplicatedStorage.Util.CameraShaker);
CameraShakerR:Stop();
get_Monster = function()
		for Y, R in pairs(workspace.Enemies:GetChildren()) do
			local Q = R:FindFirstChild("UpperTorso") or R:FindFirstChild("Head");
			if R:FindFirstChild("HumanoidRootPart", true) and Q then
				if (R.Head.Position - d.Character.HumanoidRootPart.Position).Magnitude <= 50 then
					return true, Q.Position;
				end;
			end;
		end;
		for Y, d in pairs(workspace.SeaBeasts:GetChildren()) do
			if d:FindFirstChild("HumanoidRootPart") and (d:FindFirstChild("Health") and d.Health.Value > 0) then
				return true, d.HumanoidRootPart.Position;
			end;
		end;
		for Y, d in pairs(workspace.Enemies:GetChildren()) do
			if d:FindFirstChild("Health") and (d.Health.Value > 0 and d:FindFirstChild("VehicleSeat")) then
				return true, d.Engine.Position;
			end;
		end;
	end;
Actived = function()
		local Y = game.Players.LocalPlayer.Character:FindFirstChildOfClass("Tool");
		for Y, d in next, getconnections(Y.Activated) do
			if typeof(d.Function) == "function" then
				getupvalues(d.Function);
			end;
		end;
	end;
task.spawn(function()
	W.Heartbeat:Connect(function()
		pcall(function()
			if not _G.Seriality then
				return;
			end;
			AttackNoCoolDown();
			local Y = game.Players.LocalPlayer.Character:FindFirstChildOfClass("Tool");
			local d = Y.ToolTip;
			local R, Q = get_Monster();
			if d == "Blox Fruit" then
				if R then
					local d = Y:FindFirstChild("LeftClickRemote");
					if d then
						Actived();
						d:FireServer(Vector3.new(.01, -500, .01), 1, true);
						d:FireServer(false);
					end;
				end;
			end;
		end);
	end);
end);

do
	BringEnemy = function()
		if not _B then return end
		local char = plr.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		pcall(function() sethiddenproperty(plr, "SimulationRadius", math.huge) end)

		local targetPos = PosMon or hrp.Position
		local enemies = workspace.Enemies:GetChildren()
		local count = 0
		local maxMobs = tonumber(_G.MaxBringMobs) or 6
		local range = tonumber(_G.BringRange) or 60

		for _, mob in ipairs(enemies) do
			if count >= maxMobs then break end
			local hum = mob:FindFirstChild("Humanoid")
			local root = mob:FindFirstChild("HumanoidRootPart")

			if hum and root and hum.Health > 0 and not IsRaidMob(mob) then
				local dist = (root.Position - targetPos).Magnitude
				if dist <= range and not root:GetAttribute("Tweening") then
					count = count + 1
					root:SetAttribute("Tweening", true)
					local tween = w:Create(root, TweenInfoBring, { CFrame = CFrame.new(targetPos) })
					tween:Play()
					tween.Completed:Once(function()
						if root then root:SetAttribute("Tweening", false) end
					end)
				end
			end
		end
	end
end

function TweenToStyleDealer(namePatterns, timeout)
	local routes = {
		["black leg"] = {world=1, cf=CFrame.new(-990.727, 26.028, 4025.687)},
		["electro"] = {world=1, cf=CFrame.new(-4628.888, 12.13, -355.718)},
		["fishman karate"] = {world=1, cf=CFrame.new(61715.234, 52.999, 871.929), entrance=Vector3.new(61163, 11, 1819)},
		["dragon claw"] = {world=2, cf=CFrame.new(-3427.668, 292.121, -1058.597)},
		["superhuman"] = {world=2, cf=CFrame.new(-4997.826, 724.124, -2624.133)},
		["death step"] = {world=2, cf=CFrame.new(6357.457, 296.634, -6840.953)},
		["sharkman karate"] = {world=2, cf=CFrame.new(-2604.696, 239.433, -10315.198)},
		["electric claw"] = {world=3, cf=CFrame.new(-10371.472, 330.765, -10131.419)},
		["dragon talon"] = {world=3, cf=CFrame.new(-9555, 393, 6151)},
		["strongest"] = {world=3, cf=CFrame.new(-14913.561, 278.654, -2258.288)},
		["sanguine"] = {world=3, cf=CFrame.new(-16927.451, 9.086, 433.864)},
	}
	local route
	for _, pattern in ipairs(namePatterns) do route = route or routes[string.lower(pattern)] end
	local currentWorld = World1 and 1 or World2 and 2 or World3 and 3 or 0
	if route and route.world ~= currentWorld then
		if route.world == 1 then Q.Remotes.CommF_:InvokeServer("TravelMain")
		elseif route.world == 2 then Q.Remotes.CommF_:InvokeServer("TravelDressrosa")
		else Q.Remotes.CommF_:InvokeServer("TravelZou") end
		return false
	end
	local holder = workspace:FindFirstChild("NPCs")
	local char = plr.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return false end

	local targetCFrame
	for _, npc in ipairs(holder and holder:GetChildren() or {}) do
		local npcRoot = npc:IsA("Model") and (npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart)
		if npcRoot then
			local lname = string.lower(npc.Name)
			for _, pattern in ipairs(namePatterns) do
				if string.find(lname, string.lower(pattern), 1, true) then
					targetCFrame = npcRoot.CFrame
					break
				end
			end
		end
		if targetCFrame then break end
	end
	if not targetCFrame and route then targetCFrame = route.cf end
	if not targetCFrame then return false end
	if route and route.entrance and (root.Position - targetCFrame.Position).Magnitude > 12000 then
		Q.Remotes.CommF_:InvokeServer("requestEntrance", route.entrance)
		task.wait(.8)
	end

	local deadline = os.clock() + (tonumber(timeout) or 8)
	repeat
		char = plr.Character
		root = char and char:FindFirstChild("HumanoidRootPart")
		if not root then return false end
		if (root.Position - targetCFrame.Position).Magnitude <= 6 then
			return true
		end
		_tp(targetCFrame)
		task.wait(.2)
	until os.clock() >= deadline
	return (root.Position - targetCFrame.Position).Magnitude <= 10
end

do
	BetterFarm = {
		Enabled = true,
		Strategy = "Highest XP",
		Ladder = {},
		LadderAt = 0,
		SpawnCache = {},
		NpcCache = {},
		Choice = nil,
	};
	local BF = BetterFarm

	local function BF_Short(value)
		value = tonumber(value) or 0
		if value >= 1e9 then return string.format("%.1fB", value / 1e9) end
		if value >= 1e6 then return string.format("%.1fM", value / 1e6) end
		if value >= 1e3 then return string.format("%.1fK", value / 1e3) end
		return string.format("%d", value)
	end

	function BF.BuildLadder(force)
		local now = os.clock()
		if not force and #BF.Ladder > 0 and now < BF.LadderAt + 60 then
			return BF.Ladder
		end
		local ok, quests = pcall(function()
			return require((game:GetService("ReplicatedStorage")):WaitForChild("Quests", 5))
		end)
		if not ok or type(quests) ~= "table" then
			return BF.Ladder
		end
		local ladder = {}
		for questId, tiers in pairs(quests) do
			if type(tiers) == "table" then
				for tier, entry in pairs(tiers) do
					if type(entry) == "table" and type(entry.Task) == "table" then
						local mobName, kills = nil, 0
						for mob, count in pairs(entry.Task) do
							kills = kills + (tonumber(count) or 0)
							if not mobName then mobName = mob end
						end
						local exp = tonumber((entry.Reward or {}).Exp) or 0
						if type(tier) == "number" and mobName and kills > 0 and exp > 0 then
							table.insert(ladder, {
								Id = questId,
								Tier = tier,
								LevelReq = tonumber(entry.LevelReq) or 0,
								Mob = mobName,
								Kills = kills,
								Exp = exp,
								Beli = tonumber((entry.Reward or {}).Beli) or 0,
								PerKill = exp / kills,
								Boss = kills == 1,
							});
						end
					end
				end
			end
		end
		table.sort(ladder, function(a, b)
			if a.LevelReq == b.LevelReq then return a.Exp > b.Exp end
			return a.LevelReq < b.LevelReq
		end)
		BF.Ladder = ladder
		BF.LadderAt = now
		BF.SpawnCache = {}
		return ladder
	end

	function BF.SpawnPoints(mobName)
		local cached = BF.SpawnCache[mobName]
		if cached and os.clock() < (cached.At or 0) + 15 then
			return cached.Points, cached.Level
		end
		local origin = workspace:FindFirstChild("_WorldOrigin")
		local holder = origin and origin:FindFirstChild("EnemySpawns")
		local points, maxLevel = {}, 0
		if holder then
			local prefix = string.lower(mobName) .. " ["
			for _, part in ipairs(holder:GetChildren()) do
				local name = string.lower(part.Name)
				if string.sub(name, 1, #prefix) == prefix or name == string.lower(mobName) then
					local active = part:GetAttribute("Active")
					if active ~= false then
						local pos
						if part:IsA("BasePart") then
							pos = part.Position
						elseif part:IsA("Model") then
							local ok, piv = pcall(part.GetPivot, part)
							if ok then pos = piv.Position end
						end
						if pos then
							table.insert(points, pos)
							local lv = tonumber(string.match(part.Name, "%[Lv%.%s*(%d+)")) or 0
							if lv > maxLevel then maxLevel = lv end
						end
					end
				end
			end
		end
		BF.SpawnCache[mobName] = { Points = points, Level = maxLevel, At = os.clock() }
		return points, maxLevel
	end

	function BF.HasSpawns(mobName)
		local points = BF.SpawnPoints(mobName)
		return #points > 0
	end

	function BF.BestCluster(mobName)
		local points = BF.SpawnPoints(mobName)
		if #points == 0 then return nil end
		local sum = Vector3.new()
		for _, p in ipairs(points) do sum = sum + p end
		return sum / #points
	end

	function BF.PickQuest(level)
		local ladder = BF.BuildLadder()
		local best
		for _, entry in ipairs(ladder) do
			if entry.LevelReq <= level and not entry.Boss and BF.HasSpawns(entry.Mob) then
				if not best then
					best = entry
				elseif BF.Strategy == "Best XP Per Kill" then
					if entry.PerKill > best.PerKill then best = entry end
				elseif entry.LevelReq > best.LevelReq
					or (entry.LevelReq == best.LevelReq and entry.Exp > best.Exp) then
					best = entry
				end
			end
		end
		return best
	end

	function BF.FindGiver(questId, near)
		local cachedPos = BF.NpcCache[questId]
		if cachedPos then return cachedPos, "cached" end
		local holder = workspace:FindFirstChild("NPCs")
		if not holder then return nil, "no-npc-folder" end
        local aliases = {
            BanditQuest1="Bandit Quest Giver", JungleQuest="Adventurer",
            BuggyQuest1="Pirate Adventurer", DesertQuest="Desert Adventurer",
            SnowQuest="Villager", MarineQuest="Marine Leader", MarineQuest2="Marine",
            SkyQuest="Sky Adventurer", PrisonerQuest="Jail Keeper", ImpelQuest="Head Jailer",
            ColosseumQuest="Colosseum Quest Giver", MagmaQuest="The Mayor",
            FishmanQuest="King Neptune", SkyExp1Quest="Mole",
            SkyExp2Quest="Sky Quest Giver 2", FountainQuest="Freezeburg Quest Giver",
        }
        local guideOk, guide = pcall(require, Q:FindFirstChild("GuideModule"))
        if guideOk and guide.Data then
            for part, entry in pairs(guide.Data.NPCList or {}) do
                if entry.InternalQuestName == questId then
                    if typeof(part) == "Instance" and part:IsA("BasePart") and part.Parent then
                        return part.Position, "live registry"
                    elseif typeof(entry.Position) == "Vector3" then
                        return entry.Position, "live registry"
                    end
                end
            end
        end
        local named = aliases[questId] and holder:FindFirstChild(aliases[questId])
        if named and named:IsA("Model") then return named:GetPivot().Position, "live NPC" end

		local wanted = string.lower(string.gsub(questId, "Quest%d*$", ""))
		local best, bestDistance
		for _, npc in ipairs(holder:GetChildren()) do
			local root = npc:IsA("Model") and npc:FindFirstChild("HumanoidRootPart")
			if root and string.find(string.lower(npc.Name), "quest giver", 1, true) then
				local label = string.lower(string.gsub(npc.Name, " Quest Giver.*$", ""))
				if wanted ~= "" and label == wanted then
					BF.NpcCache[questId] = root.Position
					return root.Position, "name-match"
				end
				local distance = near and (root.Position - near).Magnitude or 0
				if not best or distance < bestDistance then
					best, bestDistance = root.Position, distance
				end
			end
		end
		if best and near and bestDistance <= 2500 then
			return best, "nearest"
		end
		return nil, "not-found"
	end

	function BF.Apply()
		local level = (game:GetService("Players")).LocalPlayer.Data.Level.Value
		if level <= 0 then
			BF.Choice = nil
			return false, "waiting-for-data"
		end
		local ladder = BF.BuildLadder()
		if #ladder == 0 then
			BF.Choice = nil
			return false, "no-quest-list"
		end
		local choice = BF.PickQuest(level)
		if not choice then
			BF.Choice = nil
			return false, "no-quest-for-level"
		end
		local centre = BF.BestCluster(choice.Mob)
		local sameAsLast = NameQuest == choice.Id and LevelQuest == choice.Tier
		local giver
		if sameAsLast and typeof(CFrameQuest) == "CFrame" then
            giver = BF.FindGiver(choice.Id, centre)
        end
        if not giver then
            giver = BF.FindGiver(choice.Id, centre)
		end
        BF.NeedsGiver = giver == nil
        if not giver then giver = centre end
		if not giver then
			BF.Choice = nil
			return false, "no-quest-giver"
		end
		Mon = choice.Mob
		NameMon = choice.Mob
		NameQuest = choice.Id
		LevelQuest = choice.Tier
		CFrameQuest = CFrame.new(giver)
		if centre then
			CFrameMon = CFrame.new(centre)
		elseif typeof(CFrameMon) ~= "CFrame" then
			CFrameMon = CFrame.new(giver)
		end
		BF.Choice = choice
		return true, string.format(
			"%s Lv%d - %s x%d for %s xp",
			choice.Id, choice.LevelReq, choice.Mob, choice.Kills, BF_Short(choice.Exp)
		)
	end
end

(function()
if World1 or World2 or World3 then
	local S1_NextQuestActionAt = 0
	local S1_NpcMissAt = {}
	local S1_QuestGuiLabel

	pcall(function()
		S1_QuestGuiLabel = Gz.CreateLabel({ Title = "Better Farm: off", Content = "" })
	end)

	Gz.CreateToggle({
		Title = "Better Farm (Priority Mode)",
		Description = "Reads current quests and NPCs in this sea",
		Default = true,
		Callback = function(Y)
			BetterFarm.Enabled = Y
			if Y then
				BetterFarm.BuildLadder(true)
			end
		end,
	})
	Gz.CreateDropdown({
		Title = "Priority",
		Description = "",
		Values = { "Highest XP", "Best XP Per Kill" },
		Default = "Highest XP",
		Multi = false,
		Callback = function(Y)
			BetterFarm.Strategy = Y
		end,
	})

	local S1_AutoHealTriggered = false
	local S1_LastLegacyCheckAt = 0

	local function S1_LegacyDataStale()
		if type(NameQuest) ~= "string" or NameQuest == "" then return false end
		local ok, quests = pcall(function()
			return require((game:GetService("ReplicatedStorage")):WaitForChild("Quests", 3))
		end)
		if not ok or type(quests) ~= "table" then
			return false
		end
		if quests[NameQuest] == nil then
			return true
		end
		if type(Mon) == "string" and Mon ~= "" and not BetterFarm.HasSpawns(Mon) then
			return true
		end
		return false
	end

	local function S1_ApplyQuestData()
		if not BetterFarm.Enabled and not S1_AutoHealTriggered then
			local now = os.clock()
			if now >= S1_LastLegacyCheckAt + 8 then
				S1_LastLegacyCheckAt = now
				CheckQuest()
				if S1_LegacyDataStale() then
					S1_AutoHealTriggered = true
					BetterFarm.Enabled = true
					BetterFarm.BuildLadder(true)
					pcall(function()
						if S1_QuestGuiLabel then
							S1_QuestGuiLabel:Set("Better Farm: live quest data enabled")
						end
					end)
					pcall(function()
						Kz.CreateNoti({
							Title = "VoidHub",
							Content = "Quest data changed; switched to live quest mode",
							Duration = 6,
						})
					end)
				end
			end
		end
		if BetterFarm.Enabled then
			local ok, reason = BetterFarm.Apply()
			if ok then
				pcall(function()
					if S1_QuestGuiLabel then
						S1_QuestGuiLabel:Set("Better Farm: " .. tostring(reason))
					end
				end)
				return
			end
			pcall(function()
				if S1_QuestGuiLabel then
					S1_QuestGuiLabel:Set("Better Farm: " .. tostring(reason) .. " (fallback)")
				end
			end)
		end
		CheckQuest()
	end

	local function S1_ReachNpc(hrp, target, tolerance)
		if not hrp or not target then return false end
		if (hrp.Position - target.Position).Magnitude <= tolerance then
			return true
		end
		_tp(target)
		return false
	end

	-- One bounded step per tick: quest acceptance, combat, or spawn search.
	local function S1_FarmStep()
		local char = plr.Character;
		local hrp = char and char:FindFirstChild("HumanoidRootPart");
		local health = char and char:FindFirstChildOfClass("Humanoid");
		if not hrp or not health or health.Health <= 0 then return "waiting for respawn"; end;
		i, R, HRP = char, hrp, hrp;
        if VoidUpdate30 and (VoidUpdate30.Magnet or VoidUpdate30.Secrets) then return "paused for event farm" end
        S1_ApplyQuestData();
        if BetterFarm.Enabled and BetterFarm.NeedsGiver then
            BetterFarm.Enabled = false
            CheckQuest()
            if S1_QuestGuiLabel then S1_QuestGuiLabel:Set("Level farm: using quest fallback") end
        end
        if type(Mon) ~= "string" or not NameQuest or not LevelQuest or typeof(CFrameQuest) ~= "CFrame" then return "waiting for quest data"; end;
		local state = VoidS1Farm;
		if not CheckHasQuest(NameMon) then
			if not S1_ReachNpc(hrp, CFrameQuest, 6) then return "moving to quest"; end;
			if os.clock() < state.NextQuestAt then return "waiting for quest confirmation"; end;
			state.NextQuestAt = os.clock() + 8;
			if VoidQuestState() then
				VoidS1Request("AbandonQuest");
				task.wait(.3);
			end;
			if not _G.Level then return "off"; end;
			VoidS1Request("StartQuest", NameQuest, LevelQuest);
			local deadline = os.clock() + 3;
			repeat task.wait(.2) until CheckHasQuest(NameMon) or os.clock() >= deadline or not _G.Level;
			return CheckHasQuest(NameMon) and "quest accepted" or "waiting for quest confirmation";
		end;
		state.NextQuestAt = 0;
		if _G.ChooseWP_UserSet ~= true then _G.ChooseWP = "Melee"; end;
		local folder = workspace:FindFirstChild("Enemies");
		local target, nearest;
		for _, mob in ipairs(folder and folder:GetChildren() or {}) do
			local root = mob:FindFirstChild("HumanoidRootPart");
			local humanoid = mob:FindFirstChildOfClass("Humanoid");
			if root and humanoid and humanoid.Health > 0 and mob.Name:gsub("%s*%[Lv%..-%]", ""):lower() == Mon:lower() then
				local distance = (root.Position - hrp.Position).Magnitude;
				if not nearest or distance < nearest then target, nearest = mob, distance; end;
			end;
		end;
		if target then
			VoidS1Farm.ActiveTarget = target;
			f.Kill(target, _G.Level);
			return "combat";
		end;
		VoidS1Farm.ActiveTarget = nil;
		local spawn = VoidS1Spawn(NameMon, CFrameMon, hrp);
		if typeof(spawn) ~= "CFrame" then return "waiting for spawn data"; end;
		CFrameMon = spawn;
		if (hrp.Position - spawn.Position).Magnitude > 30 then _tp(spawn); return "moving to enemies"; end;
		return "waiting for enemies";
	end;
	task.spawn(function()
		while task.wait(.45) do
			if _G.Level and BetterFarm.Enabled then
				pcall(function()
					local activeTarget = VoidS1Farm.ActiveTarget
					local targetHumanoid = activeTarget and activeTarget:FindFirstChildOfClass("Humanoid")
					local hasLiveTarget = targetHumanoid and targetHumanoid.Health > 0
					local hasActiveQuest = CheckHasQuest(NameMon)
					if not hasLiveTarget and not hasActiveQuest then
						local ok = BetterFarm.Apply()
						if not ok then CheckQuest() end
					end
				end)
			end
		end
	end)
	task.spawn(function()
		while task.wait(.2) do
			if _G.Level then
				local ok, status = pcall(S1_FarmStep);
				VoidS1Farm.Status = ok and status or "error";
				VoidS1Farm.LastError = not ok and tostring(status) or nil;
				pcall(function()
					if S1_QuestGuiLabel then S1_QuestGuiLabel:Set("Level farm: " .. tostring(status)); end;
				end);
				if not ok then task.wait(1); end;
			else
				VoidS1Farm.Status = "off";
			end;
		end;
	end)

end
end)()


(function()
if World3 then
	local S3_DealerCF  = CFrame.new(-16927.451, 9.086, 433.864);
	local S3_BuyLastAt = 0;
	local S3_SitLastAt = 0;
	local S3_ZoneMap = {
		["Lv 1"]        = CFrame.new(-21998.375, 30.0006084, -682.309143),
		["Lv 2"]        = CFrame.new(-26779.5215, 30.0005474, -822.858032),
		["Lv 3"]        = CFrame.new(-31171.957, 30.0001011, -2256.93774),
		["Lv 4"]        = CFrame.new(-34054.6875, 30.2187767, -2560.12012),
		["Lv 5"]        = CFrame.new(-38887.5547, 30.0004578, -2162.99023),
		["Lv 6"]        = CFrame.new(-44541.7617, 30.0003204, -1244.8584),
		["Lv Infinite"] = CFrame.new(-10000000, 31, 37016.25),
	};

	local function S3_HasEnemy()
		return (CheckShark() and _G.Shark)
			or (CheckTerrorShark() and _G.TerrorShark)
			or (CheckFishCrew() and _G.MobCrew)
			or (CheckPiranha() and _G.Piranha)
			or (CheckEnemiesBoat() and _G.FishBoat)
			or (CheckSeaBeast() and _G.SeaBeast1)
			or (_G.Leviathan1 and CheckLeviathan())
			or (_G.HCM and CheckHauntedCrew())
			or (_G.PGB and CheckPirateGrandBrigade());
	end;

	local function S3_TargetZone()
		local key = tostring(_G.DangerSc or "Lv 1");
		local zone = S3_ZoneMap[key] or S3_ZoneMap["Lv 1"];
		CFrameSelectedZone = zone;
		return zone;
	end;

	local function S3_Water()
		local plane = workspace.Map:FindFirstChild("WaterBase-Plane");
		return plane and plane:IsA("BasePart") and plane.Position.Y or 25;
	end;

	-- boat buying: synchronous nav, no async-tween race
	task.spawn(function()
		while task.wait(.5) do
			if _G.SailBoats then
				pcall(function()
					if not CheckBoat() then
						local char = d.Character;
						local hrp = char and char:FindFirstChild("HumanoidRootPart");
						if not hrp then return end;
						if S3_HasEnemy() then return end;
						local now = os.clock();
						if now - S3_BuyLastAt < 6 then return end;
						notween(S3_DealerCF);
						task.wait(.45);
						S3_BuyLastAt = now;
						Q.Remotes.CommF_:InvokeServer("BuyBoat", _G.SelectedBoat);
						for _ = 1, 25 do
							task.wait(.3);
							if CheckBoat() then break end;
						end;
					end;
				end);
			end;
		end;
	end);

	-- boarding: seat:Sit direct, not proximity-based
	task.spawn(function()
		while task.wait(.25) do
			if _G.SailBoats then
				pcall(function()
					local humanoid = d.Character and d.Character:FindFirstChildOfClass("Humanoid");
					if not humanoid or humanoid.Sit then return end;
					if S3_HasEnemy() then return end;
					local boat = CheckBoat();
					if not boat then return end;
					local seat = boat:FindFirstChild("VehicleSeat");
					if not seat then return end;
					local now = os.clock();
					if now - S3_SitLastAt < 1.5 then return end;
					S3_SitLastAt = now;
					local char = d.Character;
					local root = char and char:FindFirstChild("HumanoidRootPart");
					if not root then return end;
					root.CFrame = seat.CFrame * CFrame.new(0, 2.5, 0);
					task.wait(.08);
					pcall(function() seat:Sit(humanoid); end);
				end);
			end;
		end;
	end);

	task.spawn(function()
		while task.wait(.05) do
			if _G.SailBoats then
				pcall(function()
					local humanoid = d.Character and d.Character:FindFirstChildOfClass("Humanoid");
					if not humanoid or not humanoid.Sit then return end;
					if S3_HasEnemy() then return end;
					local boat = CheckBoat();
					if not boat then return end;
					local seat = boat:FindFirstChild("VehicleSeat");
					if not seat then return end;
					local zone = S3_TargetZone();
					if (seat.Position - zone.Position).Magnitude > 80 then
						seat.CFrame = zone;
					end;
				end);
			end;
		end;
	end);

	-- auto-unsit on enemy detection for faster combat response
	task.spawn(function()
		while task.wait(.1) do
			if _G.SailBoats then
				pcall(function()
					local humanoid = d.Character and d.Character:FindFirstChildOfClass("Humanoid");
					if humanoid and humanoid.Sit and S3_HasEnemy() then
						humanoid.Sit = false;
					end;
				end);
			end;
		end;
	end);

	-- boost boat speed on spawn
	task.spawn(function()
		local lastBoat = nil;
		while task.wait(1) do
			pcall(function()
				local boat = CheckBoat();
				if boat and boat ~= lastBoat then
					lastBoat = boat;
					local seat = boat:FindFirstChild("VehicleSeat");
					if seat then
						seat.MaxSpeed  = 350;
						seat.Torque    = 0.2;
						seat.TurnSpeed = 5;
					end;
				elseif not boat then
					lastBoat = nil;
				end;
			end);
		end;
	end);

	-- auto-rebuy on boat sink
	task.spawn(function()
		local hadBoat = false;
		local rebuyAt = 0;
		while task.wait(.5) do
			if _G.SailBoats then
				pcall(function()
					local boat = CheckBoat();
					if boat then
						hadBoat = true;
					elseif hadBoat then
						hadBoat = false;
						local now = os.clock();
						if now - rebuyAt < 3 then return end;
						rebuyAt = now;
						notween(S3_DealerCF);
						task.wait(.4);
						S3_BuyLastAt = now;
						Q.Remotes.CommF_:InvokeServer("BuyBoat", _G.SelectedBoat);
					end;
				end);
			else
				hadBoat = false;
			end;
		end;
	end);

	task.spawn(function()
		while task.wait() do
			pcall(function()
				if _G.Shark and CheckShark() then
					for _, R in pairs(workspace.Enemies:GetChildren()) do
						if R.Name == "Shark" and f.Alive(R) then
							repeat
								task.wait();
								f.Kill(R, _G.Shark);
							until _G.Shark == false or not R.Parent or R.Humanoid.Health <= 0;
						end;
					end;
				end;
			end);
		end;
	end);

	task.spawn(function()
		while task.wait() do
			pcall(function()
				if _G.TerrorShark and CheckTerrorShark() then
					for _, R in pairs(workspace.Enemies:GetChildren()) do
						if R.Name == "Terrorshark" and f.Alive(R) then
							repeat
								task.wait();
								f.KillSea(R, _G.TerrorShark);
							until _G.TerrorShark == false or not R.Parent or R.Humanoid.Health <= 0;
						end;
					end;
				end;
			end);
		end;
	end);

	task.spawn(function()
		while task.wait() do
			pcall(function()
				if _G.Piranha and CheckPiranha() then
					for _, R in pairs(workspace.Enemies:GetChildren()) do
						if R.Name == "Piranha" and f.Alive(R) then
							repeat
								task.wait();
								f.Kill(R, _G.Piranha);
							until _G.Piranha == false or not R.Parent or R.Humanoid.Health <= 0;
						end;
					end;
				end;
			end);
		end;
	end);

	task.spawn(function()
		while task.wait() do
			pcall(function()
				if _G.MobCrew and CheckFishCrew() then
					for _, R in pairs(workspace.Enemies:GetChildren()) do
						if R.Name == "Fish Crew Member" and f.Alive(R) then
							repeat
								task.wait();
								f.Kill(R, _G.MobCrew);
							until _G.MobCrew == false or not R.Parent or R.Humanoid.Health <= 0;
						end;
					end;
				end;
			end);
		end;
	end);

	task.spawn(function()
		while task.wait() do
			pcall(function()
				if _G.HCM and CheckHauntedCrew() then
					for _, R in pairs(workspace.Enemies:GetChildren()) do
						if R.Name == "Haunted Crew Member" and f.Alive(R) then
							repeat
								task.wait();
								f.Kill(R, _G.HCM);
							until _G.HCM == false or not R.Parent or R.Humanoid.Health <= 0;
						end;
					end;
				end;
			end);
		end;
	end);

	task.spawn(function()
		while task.wait() do
			pcall(function()
				if _G.SeaBeast1 and workspace.SeaBeasts:FindFirstChild("SeaBeast1") then
					for _, R in pairs(workspace.SeaBeasts:GetChildren()) do
						if R:FindFirstChild("HumanoidRootPart") and R:FindFirstChild("Health") and R.Health.Value > 0 then
							local waterY = S3_Water();
							repeat
								task.wait();
								task.spawn(function()
									_tp(CFrame.new(R.HumanoidRootPart.Position.X, waterY + 200, R.HumanoidRootPart.Position.Z));
								end);
								if d:DistanceFromCharacter(R.HumanoidRootPart.CFrame.Position) <= 500 then
									AitSeaSkill_Custom = R.HumanoidRootPart.CFrame;
									MousePos = AitSeaSkill_Custom.Position;
									if CheckF() then
										weaponSc("Blox Fruit");
										Useskills("Blox Fruit", "Z");
										Useskills("Blox Fruit", "X");
										Useskills("Blox Fruit", "C");
									else
										Useskills("Melee", "Z");
										Useskills("Melee", "X");
										Useskills("Melee", "C");
										task.wait(.1);
										Useskills("Sword", "Z");
										Useskills("Sword", "X");
										task.wait(.1);
										Useskills("Blox Fruit", "Z");
										Useskills("Blox Fruit", "X");
										Useskills("Blox Fruit", "C");
										task.wait(.1);
										Useskills("Gun", "Z");
										Useskills("Gun", "X");
									end;
								end;
							until _G.SeaBeast1 == false or not R:FindFirstChild("HumanoidRootPart") or not R.Parent or R.Health.Value <= 0;
						end;
					end;
				end;
			end);
		end;
	end);

	task.spawn(function()
		while task.wait() do
			pcall(function()
				if _G.Leviathan1 and workspace.SeaBeasts:FindFirstChild("Leviathan") then
					for _, R in pairs(workspace.SeaBeasts:GetChildren()) do
						if R:FindFirstChild("HumanoidRootPart") and R:FindFirstChild("Leviathan Segment") and R:FindFirstChild("Health") and R.Health.Value > 0 then
							local waterY = S3_Water();
							repeat
								task.wait();
								task.spawn(function()
									_tp(CFrame.new(R.HumanoidRootPart.Position.X, waterY + 200, R.HumanoidRootPart.Position.Z));
								end);
								if d:DistanceFromCharacter(R.HumanoidRootPart.CFrame.Position) <= 500 then
									MousePos = (R:FindFirstChild("Leviathan Segment")).Position;
									if CheckF() then
										weaponSc("Blox Fruit");
										Useskills("Blox Fruit", "Z");
										Useskills("Blox Fruit", "X");
										Useskills("Blox Fruit", "C");
									else
										Useskills("Melee", "Z");
										Useskills("Melee", "X");
										Useskills("Melee", "C");
										task.wait(.1);
										Useskills("Sword", "Z");
										Useskills("Sword", "X");
										task.wait(.1);
										Useskills("Blox Fruit", "Z");
										Useskills("Blox Fruit", "X");
										Useskills("Blox Fruit", "C");
										task.wait(.1);
										Useskills("Gun", "Z");
										Useskills("Gun", "X");
									end;
								end;
							until _G.Leviathan1 == false or not R:FindFirstChild("HumanoidRootPart") or not R.Parent or R.Health.Value <= 0;
						end;
					end;
				end;
			end);
		end;
	end);

	task.spawn(function()
		while task.wait() do
			pcall(function()
				if _G.FishBoat and CheckEnemiesBoat() then
					for _, R in pairs(workspace.Enemies:GetChildren()) do
						if R:FindFirstChild("Health") and R.Health.Value > 0 and R:FindFirstChild("VehicleSeat") and R.Name == "FishBoat" then
							repeat
								task.wait();
								task.spawn(function()
									_tp(R.Engine.CFrame * CFrame.new(0, -50, -25));
								end);
								if d:DistanceFromCharacter(R.Engine.CFrame.Position) <= 150 then
									AitSeaSkill_Custom = R.Engine.CFrame;
									MousePos = AitSeaSkill_Custom.Position;
									if CheckF() then
										weaponSc("Blox Fruit");
										Useskills("Blox Fruit", "Z");
										Useskills("Blox Fruit", "X");
										Useskills("Blox Fruit", "C");
									else
										Useskills("Melee", "Z");
										Useskills("Melee", "X");
										Useskills("Melee", "C");
										task.wait(.1);
										Useskills("Sword", "Z");
										Useskills("Sword", "X");
										task.wait(.1);
										Useskills("Blox Fruit", "Z");
										Useskills("Blox Fruit", "X");
										Useskills("Blox Fruit", "C");
										task.wait(.1);
										Useskills("Gun", "Z");
										Useskills("Gun", "X");
									end;
								end;
							until _G.FishBoat == false or not R:FindFirstChild("VehicleSeat") or R.Health.Value <= 0;
						end;
					end;
				end;
			end);
		end;
	end);

	task.spawn(function()
		while task.wait() do
			pcall(function()
				if _G.PGB and CheckPirateGrandBrigade() then
					for _, R in pairs(workspace.Enemies:GetChildren()) do
						if R:FindFirstChild("Health") and R.Health.Value > 0 and R:FindFirstChild("VehicleSeat")
							and (R.Name == "PirateBrigade" or R.Name == "PirateGrandBrigade") then
							repeat
								task.wait();
								task.spawn(function()
									if R.Name == "PirateBrigade" then
										_tp(R.Engine.CFrame * CFrame.new(0, -30, -10));
									elseif R.Name == "PirateGrandBrigade" then
										_tp(R.Engine.CFrame * CFrame.new(0, -50, -50));
									end;
								end);
								if d:DistanceFromCharacter(R.Engine.CFrame.Position) <= 150 then
									AitSeaSkill_Custom = R.Engine.CFrame;
									MousePos = AitSeaSkill_Custom.Position;
									if CheckF() then
										weaponSc("Blox Fruit");
										Useskills("Blox Fruit", "Z");
										Useskills("Blox Fruit", "X");
										Useskills("Blox Fruit", "C");
									else
										Useskills("Melee", "Z");
										Useskills("Melee", "X");
										Useskills("Melee", "C");
										task.wait(.1);
										Useskills("Sword", "Z");
										Useskills("Sword", "X");
										task.wait(.1);
										Useskills("Blox Fruit", "Z");
										Useskills("Blox Fruit", "X");
										Useskills("Blox Fruit", "C");
										task.wait(.1);
										Useskills("Gun", "Z");
										Useskills("Gun", "X");
									end;
								end;
							until _G.PGB == false or not R:FindFirstChild("VehicleSeat") or R.Health.Value <= 0;
						end;
					end;
				end;
			end);
		end;
	end);
end
end)()

-- Update 30: Magnet Tokens (workspace-wide name scan + hover kill) and Island Secrets.
task.spawn(function()
    local player = game:GetService("Players").LocalPlayer
    local rs = game:GetService("ReplicatedStorage")
    local collection = game:GetService("CollectionService")
    local previous = getgenv().VoidUpdate30
    if previous and previous.Destroy then previous:Destroy() end
    local state = {Alive=true, Magnet=false, Secrets=false, Selected=nil,
        Progress={}, Catalog={}, Status="Off", LastAttack=0, LastRefresh=0, InFlight={},
        Target=nil, BestDistance=math.huge, ProgressAt=0}
    getgenv().VoidUpdate30 = state
    VoidUpdate30 = state
    local magnetDeadMobs = {}
    local MAGNET_SEA_PATROL = {
        [1] = {
            {name="Pirate Starter",   pos=Vector3.new(1059, 20, 1550)},
            {name="Marine Starter",   pos=Vector3.new(-2573, 20, 2046)},
            {name="Middle Town",      pos=Vector3.new(-690, 20, 1583)},
            {name="Jungle",           pos=Vector3.new(-1598, 35, 153)},
            {name="Pirate Village",   pos=Vector3.new(-1141, 20, 3831)},
            {name="Desert",           pos=Vector3.new(894, 20, 4392)},
            {name="Frozen Village",   pos=Vector3.new(1389, 88, -1298)},
            {name="Marine Fortress",  pos=Vector3.new(-938, 20, -3678)},
            {name="Prison",           pos=Vector3.new(67, 42, -2947)},
            {name="Colosseum",        pos=Vector3.new(594, 101, -1244)},
            {name="Magma Village",    pos=Vector3.new(-5528, 20, 8691)},
            {name="Lower Sky",        pos=Vector3.new(-4607, 872, -1667)},
            {name="Upper Sky",        pos=Vector3.new(-7894, 5547, -380), entrance=Vector3.new(-7894, 5547, -380)},
            {name="Underwater City",  pos=Vector3.new(61163, 20, 1819), entrance=Vector3.new(61163, 11, 1819)},
            {name="Fountain City",    pos=Vector3.new(5132, 20, 4037)},
        },
        [2] = {
            {name="Kingdom of Rose",  pos=Vector3.new(-195, 155, 280)},
            {name="Cafe",             pos=Vector3.new(-380, 73, 303)},
            {name="Factory",          pos=Vector3.new(431, 238, -433)},
            {name="Mansion",          pos=Vector3.new(-393, 367, 688)},
            {name="Swan's Room",      pos=Vector3.new(2294, 20, 663)},
            {name="Colosseum",        pos=Vector3.new(-1836, 73, 1360)},
            {name="Green Zone",       pos=Vector3.new(-2341, 155, -3396)},
            {name="Graveyard Island", pos=Vector3.new(-5578, 88, -782)},
            {name="Dark Arena",       pos=Vector3.new(3807, 20, -3452)},
            {name="Snow Mountain",    pos=Vector3.new(856, 50, -5278)},
            {name="Hot and Cold",     pos=Vector3.new(-5734, 49, -5146)},
            {name="Ice Castle",       pos=Vector3.new(6062, 155, -6881)},
            {name="Forgotten Island", pos=Vector3.new(-3194, 155, -10795)},
            {name="Cursed Ship",      pos=Vector3.new(923, 143, 33073), entrance=Vector3.new(923, 126, 32852)},
        },
        [3] = {
			{name="Port Town",       pos=Vector3.new(-611, 57, 6436)},
			{name="Hydra Island",    pos=Vector3.new(5298, -990, 344)},
			{name="Dragon Dojo",     pos=Vector3.new(5704, 1168, 937)},
			{name="Great Tree",      pos=Vector3.new(3036, 815, -7150)},
			{name="Castle on the Sea",pos=Vector3.new(-5437, 815, -2702), entrance=Vector3.new(-5098, 316, -3143)},
			{name="Mansion",         pos=Vector3.new(-12548, 290, -7488), entrance=Vector3.new(-12471, 375, -7552)},
			{name="Floating Turtle", pos=Vector3.new(-12165, -549, -8455)},
			{name="Haunted Castle",  pos=Vector3.new(-9531, -133, 5763)},
			{name="Sea of Treats 1", pos=Vector3.new(-1506, 57, -10725)},
			{name="Sea of Treats 2", pos=Vector3.new(-2038, 57, -12551)},
			{name="Sea of Treats 3", pos=Vector3.new(112, 57, -12795)},
			{name="North Pole",      pos=Vector3.new(-1142, 57, -14481)},
			{name="Tiki Outpost",    pos=Vector3.new(-16642, 213, 435)},
			{name="Submerged Island",pos=Vector3.new(10533, -2030, 9940)},
        },
    }
    local MAGNET_SEA_PLACE_IDS = {[1]=85211729168715,[2]=79091703265657,[3]=100117331123090}

    local function magnetGetSea()
        local pid = game.PlaceId
        for sea, id in pairs(MAGNET_SEA_PLACE_IDS) do if pid == id then return sea end end
        if pid == 2753915549 then return 1 end
        if pid == 4442272183 then return 2 end
        if pid == 7449423635 then return 3 end
        if World2 then return 2 end
        if World3 then return 3 end
        return 1
    end
    local VOIDHUB_JOB_API = "https://job.idshowmeat.workers.dev"
    local VOIDHUB_LOADER_URL = "https://voidon.top/api/loader/main"
    local function magnetQueueAutoResume()
        if typeof(queue_on_teleport) ~= "function" then return end
        local sourceUrl = tostring(getgenv().VoidHubSourceURL or VOIDHUB_LOADER_URL)
        local bootstrap = string.format([[
task.spawn(function()
    loadstring(game:HttpGet(%q))()
    local deadline = os.clock() + 20
    while os.clock() < deadline do
        if VoidUpdate30 then
            VoidUpdate30.Magnet = true
            break
        end
        task.wait(0.5)
    end
end)
]], sourceUrl)
        pcall(function() queue_on_teleport(bootstrap) end)
    end
    local _hs = game:GetService("HttpService")
    local _httpReq = (typeof(request) == "function" and request)
        or (syn and typeof(syn.request) == "function" and syn.request)
        or (http and typeof(http.request) == "function" and http.request)
        or nil
    local function magnetApiReq(method, path, body)
        if not _httpReq then return nil end
        local ok, res = pcall(_httpReq, {
            Url = VOIDHUB_JOB_API .. path,
            Method = method,
            Headers = {["Content-Type"] = "application/json"},
            Body = body and _hs:JSONEncode(body) or nil,
        })
        if not ok or not res or not res.Body then return nil end
        local ok2, data = pcall(_hs.JSONDecode, _hs, res.Body)
        return ok2 and data or nil
    end
    local function magnetFetchFromRoblox(placeId)
        local ok, raw = pcall(game.HttpGet, game, "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?limit=100&sortOrder=Desc")
        if not ok or not raw then return {} end
        local ok2, parsed = pcall(_hs.JSONDecode, _hs, raw)
        if not ok2 or not parsed or not parsed.data then return {} end
        local ids = {}
        for _, s in ipairs(parsed.data) do
            if s.id and s.id ~= game.JobId and (s.playing or 0) > 0 then table.insert(ids, s.id) end
        end
        return ids
    end
    local function magnetRefreshPool(placeId)
        local ids = magnetFetchFromRoblox(placeId)
        if #ids > 0 then
            pcall(magnetApiReq, "POST", "/push", {place=tostring(placeId), jobs=ids})
        end
    end
    local function magnetHopServer(placeId)
        local data = magnetApiReq("GET", "/pop?place=" .. tostring(placeId), nil)
        if data and data.job then
            magnetQueueAutoResume()
            pcall(function()
                game:GetService("TeleportService"):TeleportToPlaceInstance(placeId, data.job, player)
            end)
            return true, data.job
        end
        magnetRefreshPool(placeId)
        task.wait(0.5)
        data = magnetApiReq("GET", "/pop?place=" .. tostring(placeId), nil)
        if data and data.job then
            magnetQueueAutoResume()
            pcall(function()
                game:GetService("TeleportService"):TeleportToPlaceInstance(placeId, data.job, player)
            end)
            return true, data.job
        end
        return false
    end
    task.spawn(function() magnetRefreshPool(game.PlaceId) end)
    local MAGNET_PATROL_ISLANDS = MAGNET_SEA_PATROL[magnetGetSea()] or MAGNET_SEA_PATROL[1]
    local MAGNET_ISLAND_DWELL = 3
    local magnetPatrolIndex = 1
    local magnetIslandDeadline = nil
    local magnetPatrolCyclesEmpty = 0

    -- to the first island in the list.
    local function magnetNearestIslandIndex()
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return 1 end
        local best, bestDist = 1, math.huge
        for idx, island in ipairs(MAGNET_PATROL_ISLANDS) do
            local dist = (Vector3.new(island.pos.X, root.Position.Y, island.pos.Z) - root.Position).Magnitude
            if dist < bestDist then best, bestDist = idx, dist end
        end
        return best
    end

    function state:StopMovement()
        if self.TravelTween then self.TravelTween:Cancel(); self.TravelTween=nil end
        local c = player.Character
        local h = c and c:FindFirstChildOfClass("Humanoid")
        local root = c and c:FindFirstChild("HumanoidRootPart")
        if h and root then h:Move(Vector3.zero); h:MoveTo(root.Position) end
        self.Target = nil
    end
    function state:Destroy()
        self.Alive, self.Magnet, self.Secrets = false, false, false
        self:StopMovement()
    end

    function state:EquipMelee()
        local char = player.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if not char or not humanoid then return nil, "Waiting for character" end
        local selected
        for _, container in ipairs({char, player.Backpack}) do
            for _, tool in ipairs(container:GetChildren()) do
                if tool:IsA("Tool") and tool.ToolTip == "Melee" then
                    selected = tool
                    break
                end
            end
            if selected then break end
        end
        if not selected then return nil, "No melee fighting style found" end
        humanoid:EquipTool(selected)
        _G.SelectWeapon, _G.ChooseWP, _G.ChooseWP_UserSet = selected.Name, "Melee", false
        return selected
    end

    function state:TravelToMarineFortress()
        if not World1 then return true end
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if not root or not humanoid or humanoid.Health <= 0 then return false, "Waiting for character" end
        local tool, toolReason = self:EquipMelee()
        if not tool then return false, toolReason end
        local map = rs:FindFirstChild("Definitions")
        map = map and map:FindFirstChild("Map")
        local data = map and map:FindFirstChild("DEFINITIONS")
        data = data and data:FindFirstChild("LIBRARY")
        local sea = data and data:FindFirstChild("Sea1")
        local fortress = sea and sea:FindFirstChild("Marine Fortress")
        if not fortress then return false, "Marine Fortress map data unavailable" end
        local config = require(fortress)
        local marineNpc = workspace:FindFirstChild("NPCs") and workspace.NPCs:FindFirstChild("Marine")
        local destination = marineNpc and marineNpc:GetPivot().Position or (config.World and config.World.Position)
        if typeof(destination) ~= "Vector3" then return false, "Marine Fortress destination unavailable" end
        local function horizontalDistance()
            local delta = root.Position - destination
            return Vector2.new(delta.X, delta.Z).Magnitude
        end
        if horizontalDistance() <= 100 then return true end
        local speed = math.max(50, tonumber(getgenv().TweenSpeedFar) or 180)
        local tween = game:GetService("TweenService"):Create(root,
            TweenInfo.new(math.max(.1, (root.Position - destination).Magnitude / speed), Enum.EasingStyle.Linear),
            {CFrame=CFrame.new(destination + Vector3.new(0, 3, 0))})
        self.TravelTween = tween
        self.Status = "Tweening to Marine Fortress with " .. tool.Name
        zeroVelocity(root)
        setCharacterNoclip(char, true)
        tween:Play()
        repeat
            zeroVelocity(root)
            task.wait(.2)
        until tween.PlaybackState ~= Enum.PlaybackState.Playing
            or not state.Alive or not state.Magnet or player.Character ~= char or humanoid.Health <= 0
        if tween.PlaybackState == Enum.PlaybackState.Playing then tween:Cancel() end
        zeroVelocity(root)
        setCharacterNoclip(char, false)
        if self.TravelTween == tween then self.TravelTween = nil end
        if not state.Alive or not state.Magnet then return false, "Travel cancelled" end
        if player.Character ~= char or humanoid.Health <= 0 then return false, "Character changed during travel" end
        task.wait(1)
        if horizontalDistance() > 100 then return false, "Marine Fortress tween was blocked; retry from Sea 1" end
        return true
    end

    function state:TravelToSecret(entry)
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if not root or not humanoid or humanoid.Health <= 0 then return false, "Waiting for character" end
        if self.TravelTween and self.TravelTween.PlaybackState == Enum.PlaybackState.Playing then
            return false, "Travelling to " .. entry.Island
        end
        local map = rs:FindFirstChild("Definitions")
        map = map and map:FindFirstChild("Map")
        local data = map and map:FindFirstChild("DEFINITIONS")
        data = data and data:FindFirstChild("LIBRARY")
        local sea = data and data:FindFirstChild("Sea1")
        local island = sea and sea:FindFirstChild(entry.Island)
        if not island then return false, "No map route for " .. entry.Island end
        local ok, config = pcall(require, island)
        local destination = ok and config and config.World and config.World.Position
        if typeof(destination) ~= "Vector3" then return false, "No destination for " .. entry.Island end
        local distance = (root.Position - destination).Magnitude
        if distance <= 120 then return true end
        local speed = math.max(50, tonumber(getgenv().TweenSpeedFar) or 180)
        local tween = game:GetService("TweenService"):Create(root,
            TweenInfo.new(math.max(.1, distance / speed), Enum.EasingStyle.Linear),
            {CFrame=CFrame.new(destination + Vector3.new(0, 4, 0))})
        self.TravelTween = tween
        tween.Completed:Connect(function()
            if self.TravelTween == tween then self.TravelTween = nil end
            zeroVelocity(root)
            setCharacterNoclip(char, false)
        end)
        zeroVelocity(root)
        setCharacterNoclip(char, true)
        tween:Play()
        return false, "Travelling to " .. entry.Island
    end

    function state:InteractNearby()
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not root or not fireproximityprompt then return false end
        local nearest, nearestDistance
        for _, prompt in ipairs(workspace:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") then
                local holder = prompt.Parent
                local pos
                if holder and holder:IsA("BasePart") then pos = holder.Position
                elseif holder and holder:IsA("Attachment") then pos = holder.WorldPosition
                elseif holder and holder:IsA("Model") then pos = holder:GetPivot().Position end
                local distance = pos and (pos - root.Position).Magnitude
                if distance and distance <= math.max(16, prompt.MaxActivationDistance or 0)
                    and (not nearestDistance or distance < nearestDistance) then
                    nearest, nearestDistance = prompt, distance
                end
            end
        end
        if not nearest then return false end
        fireproximityprompt(nearest)
        return true, nearest.ActionText ~= "" and nearest.ActionText or nearest.ObjectText
    end

    function state:Call(key, callback)
        if self.InFlight[key] then return false, "Request still pending" end
        local ticket = {Done=false}
        self.InFlight[key] = ticket
        task.spawn(function()
            ticket.Result = table.pack(pcall(callback))
            ticket.Done = true
            if self.InFlight[key] == ticket then self.InFlight[key] = nil end
        end)
        local deadline = os.clock() + 5
        repeat task.wait(.1) until ticket.Done or not self.Alive or os.clock() >= deadline
        if not ticket.Done then return false, "Server response pending" end
        return table.unpack(ticket.Result, 1, ticket.Result.n)
    end

    function state:Refresh()
        local net = rs:FindFirstChild("Modules")
        net = net and net:FindFirstChild("Net")
        local remote = net and net:FindFirstChild("RF/RequestBonusMomentReplication")
        if not remote then return false, "Secret progress unavailable in this sea" end
        local ok, response = self:Call("Progress", function()
            return remote:InvokeServer({Type="GetMomentProgress"})
        end)
        if not ok or type(response) ~= "table" or type(response.Data) ~= "table" then
            return false, tostring(response or "Progress not received")
        end
        self.Progress, self.Catalog = response.Data, {}
        for address, complete in pairs(response.Data) do
            local sea, island, name = address:match("^([^/]+)/([^/]+)/(.+)$")
            if name then
                self.Catalog[#self.Catalog+1] = {
                    Address=address, Sea=sea, Island=island,
                    Name=name, Complete=complete==true,
                }
            end
        end
        table.sort(self.Catalog, function(a,b) return a.Address < b.Address end)
        self.LastRefresh = os.clock()
        return true
    end

    -- and other lower-power executors.
    state.MagnetCandidates, state.MagnetCandidateAt = {}, -math.huge
    function state:IsMagnetMob(v)
        if not (v and v:IsA("Model")) or v == player.Character then return false end
        if magnetDeadMobs[v] and os.clock() < magnetDeadMobs[v] then return false end
        local hum, hrp = v:FindFirstChildOfClass("Humanoid"), v:FindFirstChild("HumanoidRootPart")
        if not hum or hum.Health <= 0 or not hrp then return false end
        if v:GetAttribute("MagnetEnemy") == true or v:GetAttribute("MagnetEvent") == true
            or v:GetAttribute("IsMagnetized") == true then return true end
        local label = (v.Name .. " " .. tostring(hum.DisplayName or "")):lower()
        if label:find("magnet") or label:find("overcharged") then return true end
        for _, tag in ipairs({"Magnet Event", "MagnetEnemy", "Magnetized", "Magnetised"}) do
            if collection:HasTag(v, tag) then return true end
        end
        local marker = v:FindFirstChild("Magnet", true) or v:FindFirstChild("MagnetEnemy", true)
            or v:FindFirstChild("Overcharged", true)
        return marker ~= nil
    end

    function state:RefreshMagnetCandidates(force)
        if not force and os.clock() - self.MagnetCandidateAt < 1.25 then return end
        self.MagnetCandidateAt = os.clock()
        local result, seen = {}, {}
        local function add(v)
            if v and not seen[v] then seen[v] = true; result[#result+1] = v end
        end
        for _, folderName in ipairs({"Enemies", "Characters", "NPCs"}) do
            local folder = workspace:FindFirstChild(folderName)
            for _, v in ipairs(folder and folder:GetChildren() or {}) do add(v) end
        end
        for _, tag in ipairs({"Magnet Event", "MagnetEnemy", "Magnetized", "Magnetised"}) do
            for _, v in ipairs(collection:GetTagged(tag)) do add(v:IsA("Model") and v or v:FindFirstAncestorOfClass("Model")) end
        end
        self.MagnetCandidates = result
    end

    function state:FindMagnet()
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not root then return nil end
        self:RefreshMagnetCandidates(false)
        local nearest, nearestDist = nil, math.huge
        for _, v in ipairs(self.MagnetCandidates) do
            if self:IsMagnetMob(v) then
                local hrp = v:FindFirstChild("HumanoidRootPart")
                local distance = hrp and (hrp.Position - root.Position).Magnitude
                if distance and distance < nearestDist then nearest, nearestDist = v, distance end
            end
        end
        return nearest, nearestDist
    end

    function state:PatrolTo(island)
        local char = player.Character
        local root, hum = char and char:FindFirstChild("HumanoidRootPart"), char and char:FindFirstChildOfClass("Humanoid")
        if not root or not hum or hum.Health <= 0 then return false, "Waiting for character" end
        if self.TravelTween and self.TravelTween.PlaybackState == Enum.PlaybackState.Playing then
            return false, "Travelling to " .. island.name
        end
        if island.entrance and (root.Position - island.pos).Magnitude > 3500 then
            local remotes = rs:FindFirstChild("Remotes")
            local comm = remotes and remotes:FindFirstChild("CommF_")
            if comm then
                pcall(comm.InvokeServer, comm, "requestEntrance", island.entrance)
                task.wait(.8)
                pcall(function() player:RequestStreamAroundAsync(island.pos, 8) end)
            end
        end
        local flat = Vector3.new(island.pos.X - root.Position.X, 0, island.pos.Z - root.Position.Z)
        if flat.Magnitude <= 90 then
            pcall(function() player:RequestStreamAroundAsync(island.pos, 8) end)
            return true, "Scanning " .. island.name
        end
        local step = math.min(flat.Magnitude, 650)
        local fallbackY = root.Position.Y < 3 and (island.pos.Y + 4) or root.Position.Y
        local destination = Vector3.new(root.Position.X + flat.Unit.X * step, fallbackY, root.Position.Z + flat.Unit.Z * step)
        local rayParams = RaycastParams.new()
        rayParams.IgnoreWater = true
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        rayParams.FilterDescendantsInstances = {char}
        local ray = workspace:Raycast(destination + Vector3.new(0, 180, 0), Vector3.new(0, -360, 0), rayParams)
        if ray then destination = Vector3.new(destination.X, ray.Position.Y + 4, destination.Z) end
        local speed = math.clamp(tonumber(getgenv().TweenSpeedFar) or 180, 80, 350)
        local tween = w:Create(root, TweenInfo.new(math.max(.2, step / speed), Enum.EasingStyle.Linear), {CFrame=CFrame.new(destination)})
        self.TravelTween = tween
        self.Status = "Moving to " .. island.name
        tween.Completed:Connect(function()
            if self.TravelTween == tween then self.TravelTween = nil end
            if root and root.Parent then zeroVelocity(root) end
        end)
        zeroVelocity(root)
        tween:Play()
        return false, self.Status
    end

    -- Searches workspace.Enemies by predicate for Island Secret combat stages.
    function state:FindEnemy(predicate)
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not root then return nil end
        local folder = workspace:FindFirstChild("Enemies")
        local best, nearest
        for _, mob in ipairs(folder and folder:GetChildren() or {}) do
            local h    = mob:FindFirstChildOfClass("Humanoid")
            local part = mob:FindFirstChild("HumanoidRootPart")
            if h and h.Health > 0 and part and predicate(mob) then
                local dist = (part.Position - root.Position).Magnitude
                if not nearest or dist < nearest then best=mob; nearest=dist end
            end
        end
        return best, nearest
    end

    function state:Fight(mob, distance)
        local char   = player.Character
        local h      = char and char:FindFirstChildOfClass("Humanoid")
        local root   = char and char:FindFirstChild("HumanoidRootPart")
        local target = mob and mob:FindFirstChild("HumanoidRootPart")
        if not h or h.Health <= 0 or not root or not target then return "Waiting for character" end
        if self.Target ~= mob then
            self.Target=mob; self.BestDistance=distance; self.ProgressAt=os.clock()
        end
        if distance < (self.BestDistance or math.huge) - 1 then
            self.BestDistance=distance; self.ProgressAt=os.clock()
        end
        if distance > 7 then
            if os.clock() - (self.ProgressAt or 0) > 8 then
                self:StopMovement()
                return "Route obstructed near " .. mob.Name
            end
            h:MoveTo(target.Position)
            return "Approaching " .. mob.Name
        end
        h:Move(Vector3.zero); h:MoveTo(root.Position)
        local tool = char:FindFirstChildOfClass("Tool")
        if not tool then
            for _, candidate in ipairs(player.Backpack:GetChildren()) do
                if candidate:IsA("Tool")
                    and (candidate.ToolTip == "Melee" or candidate.ToolTip == "Sword")
                then
                    h:EquipTool(candidate); tool=candidate; break
                end
            end
        end
        if not tool then return "Equip a melee or sword weapon" end
        if os.clock() - self.LastAttack >= .35 then tool:Activate(); self.LastAttack=os.clock() end
        return "Fighting " .. mob.Name
    end

    -- Combat-automatable secret stages.
    local combat = {
        ["Rescue Hasan"]      = {["Desert Skeleton"]=true},
        ["King's Apprentice"] = {
            ["Gladiator"]=true,
            ["Upgraded Gladiator"]=true,
            ["Supreme Gladiator"]=true,
        },
    }

    local hints = {
        ["Tavern Brawl"]              = "Pirate Village: get the Tavern rumour from the Quest Giver, approach the door, choose Breach Door, then defeat all 3 Tavern Pirates.",
        ["Windmill Maintenance"]      = "Pirate Village: equip a cutting weapon and cut all 5 ropes at the windmill.",
        ["Chef's Kiss"]               = "Pirate Village: Tavern top floor -> cauldron -> add any Fish and Yeti Fur -> Cook, then defeat the Awakened Chef.",
        ["The Thieving Monkey"]       = "Jungle: follow the footprints to the marked tree, M1 it until the monkey falls, defeat it, then return the Adventurer's Hat.",
        ["Zipline Repair"]            = "Jungle: at Gorilla King, take the Grapple Hook on the right side of the zipline tree, climb it, then throw the hook at the new building.",
        ["Archaeologist's Tablet"]    = "Desert: behind the treasure-chest area are 8 sand-covered stones; use M1 on every stone until the portal glows.",
        ["Rescue Hasan"]              = "Desert: take the chest by the 2 cacti and coconut tree, follow the opened underground path and ladder into the pyramid, defeat 4 enemies, then talk to Hasan.",
        ["Prickly Harvest"]           = "Desert: use a sword or M1 to chop 10 Cactus Petals, then return to the Pirate Adventurer.",
        ["Breaking the Ice"]          = "Frozen Village: use melee to break the ice surrounding the Ability Teacher.",
        ["Snowman"]                   = "Frozen Village: at the Yeti spawn during winter/snow, roll and join 3 snowballs to build the snowman.",
        ["Frozen Defense"]            = "Frozen Village: ask the Secret Masters NPC in Middle Town which boss stirs next; if it is Yeti, break 3 green snowballs to light all torches, then defeat Awakened Yeti.",
        ["King's Apprentice"]         = "Colosseum: start the arena, then Gladiator waves are handled automatically.",
        ["Legendary Creator Statues"] = "Colosseum: use the matching Sword, Gun, Melee, and Fruit attacks on the four creator statues.",
        ["Fortress Flagpole"]         = "Marine Fortress: speak to Parl us, take the rope, then use the flagpole prompt to raise the flag.",
        ["Battle Plans"]              = "Marine Fortress: use both front buster cannons to begin the fortress objective.",
        ["Escape from Alcatraz"]      = "Prison: confront each escaped prisoner before attacking - one digs in front of the Quest Giver, one is left by the wall, and one builds a raft outside.",
        ["Lever Jailbreak"]           = "Prison: use the coloured levers in their displayed order; the order changes per run.",
        ["Evil Slimes"]               = "Magma Village: destroy the pot in the middle of the lava pool, then defeat every spawned enemy.",
        ["One Last Eruption"]         = "Magma Village: if Secret Masters says Magma Admiral is next, destroy the lava pockets around the volcano, then defeat Awakened Magma Admiral.",
        ["Magma Ore Extraction"]      = "Magma Village: enter the secret seaside volcano entrance, take the elevator, avoid workers, and destroy the Magma Drill.",
        ["Pearl of the Deep"]         = "Underwater City: align the crystal beam toward the sea urchin, then open the clam when available.",
        ["Beyond the Bubble"]         = "Underwater City: follow the bubble stream into the hidden cove and open the chest.",
        ["Temple Intel"]              = "Upper Sky: open the Antique Temple, align its light beams, take the intel, and return it to Sky Quest Giver 2.",
        ["Fountain Pipe Repair"]      = "Fountain City: repair the pipe objective, then use the ship cannon launch to turn it in.",
    }

    function state:SecretStep()
        if not World1 then return "Island Secrets are Sea 1 content" end
        if not self.Selected then return "Select a secret from the dropdown" end
        local entry
        for _, v in ipairs(self.Catalog) do
            if v.Address == self.Selected then entry=v; break end
        end
        if not entry then return "Refresh the quest list" end
        if self.Progress[entry.Address] == true then
            self.Secrets=false; self:StopMovement()
            return "Completed: " .. entry.Name
        end
        local controller = rs.Controllers and rs.Controllers:FindFirstChild("BonusMomentsController")
        local ok, module = pcall(require, controller)
        local loaded = ok and module:GetLoadedMoments()[entry.Name]
        if not loaded then
            local arrived, route = self:TravelToSecret(entry)
            if not arrived then return route end
            return "Loading " .. entry.Name .. " at " .. entry.Island
        end
        local names = combat[entry.Name]
        if names and loaded.Active then
            local mob, dist = self:FindEnemy(function(m)
                return names[m.Name:gsub("%s*%[Lv%..-%]", "")] == true
            end)
            if mob then return self:Fight(mob, dist) end
            self:StopMovement()
            return "Waiting for next wave"
        end
        if not loaded.Active then
            local interacted, objective = self:InteractNearby()
            if interacted then return "Interacting with " .. objective end
        end
        self:StopMovement()
        return hints[entry.Name] or "Manual step required - check in-game objective"
    end

    -- UI
    local eventSection  = vz.CreateSection("Update 30 / Magnet Tokens")
    local secretBanner = VoidSecretTab.CreateSection("Notice")
    secretBanner.CreateLabel({Title="The Secret Quests are being worked on as of right now, bare with us to see live progress. Join our Discord:"})
    secretBanner.CreateLabel({Title="https://discord.gg/getvoidhub"})
    secretBanner.CreateButton({Title="Copy Discord Link", Callback=function()
        setclipboard(tostring("https://discord.gg/getvoidhub"))
    end})

    local secretSection = VoidSecretTab.CreateSection("Island Secrets")
    local statusLabel   = eventSection.CreateLabel({Title="Magnet: off"})

    local magnetToggle
    magnetToggle = eventSection.CreateToggle({
        Title    = "Auto Magnet Tokens",
        Default  = false,
        Description = "All seas: patrols streamed islands and farms Magnetized/Magnetised NPCs when they exist.",
        Callback = function(value)
            state.Magnet = value == true
            if state.Magnet then
                state.Secrets=false; _G.Level=false; state.NeedsFortress = false
                magnetPatrolIndex = magnetNearestIslandIndex()
                magnetIslandDeadline = nil
            else
                state:StopMovement()
            end
        end,
    })

    local secretStatus = secretSection.CreateLabel({Title="Loading secret progress..."})
    local selection    = secretSection.CreateDropdown({
        Title    = "Secret quest",
        Values   = {},
        Default  = nil,
        Callback = function(value) state.Selected=value; state:StopMovement() end,
    })
    secretSection.CreateToggle({
        Title    = "Auto Secret Quests",
        Default  = false,
        Description = "Sea 1 only. Auto-fights loaded combat stages and shows the verified route for every other selected secret.",
        Callback = function(value)
            state.Secrets = value == true
            if state.Secrets then state.Magnet=false; _G.Level=false else state:StopMovement() end
        end,
    })

    local function refreshUi()
        local ok, reason = state:Refresh()
        if not state.Alive then return end
        if not ok then secretStatus:SetDesc(reason); return end
        local values, completed = {}, 0
        for _, v in ipairs(state.Catalog) do
            values[#values+1] = v.Address
            if v.Complete then completed += 1 end
        end
        if selection then
            if selection.SetOptions then selection:SetOptions(values)
            elseif selection.Refresh then selection:Refresh(values)
            elseif selection.CLEAR_DROPDOWN and selection.ADD_DROPDOWN_OPTION then
                selection.CLEAR_DROPDOWN()
                for _, val in ipairs(values) do selection.ADD_DROPDOWN_OPTION(val) end
            end
        end
        secretStatus:SetDesc(string.format("Secrets completed: %d / %d", completed, #values))
    end

    secretSection.CreateButton({Title="Refresh quests", Callback=function() task.spawn(refreshUi) end})
    secretSection.CreateButton({Title="Stop all helpers", Callback=function()
        state.Magnet, state.Secrets=false, false
        state:StopMovement()
        secretStatus:SetDesc("Stopped")
    end})
    secretSection.CreateLabel({Title="Island Secrets are Sea 1 content only."})

    state.RefreshUI = refreshUi
    task.spawn(refreshUi)

    task.spawn(function()
        while state.Alive do
            task.wait(.3)
            local ok, result = pcall(function()
                if state.Magnet then
                    local melee, meleeReason = state:EquipMelee()
                    if not melee then return meleeReason end
                    local nearest, nearestDist = state:FindMagnet()
                    if nearest then
                        magnetPatrolCyclesEmpty = 0
                        -- melee tool's normal activation path.
                        local result = state:Fight(nearest, nearestDist)
                        local h2 = nearest:FindFirstChildOfClass("Humanoid")
                        if h2 and h2.Health <= 0 then magnetDeadMobs[nearest] = os.clock() + 10 end
                        return result .. " - " .. nearest.Name .. " (" .. math.round(nearestDist) .. "st)"
                    end
                    local island = MAGNET_PATROL_ISLANDS[magnetPatrolIndex]
                    local arrived, route = state:PatrolTo(island)
                    if not arrived then return route end
                    if not magnetIslandDeadline then magnetIslandDeadline = os.clock() + MAGNET_ISLAND_DWELL end
                    if os.clock() < magnetIslandDeadline then
                        return "Scanning " .. island.name .. string.format(" (%.1fs left)", magnetIslandDeadline - os.clock())
                    end
                    magnetIslandDeadline = nil
                    magnetPatrolIndex = magnetPatrolIndex + 1
                    if magnetPatrolIndex > #MAGNET_PATROL_ISLANDS then
                        magnetPatrolIndex = 1
                        magnetPatrolCyclesEmpty = magnetPatrolCyclesEmpty + 1
                    end
                    if magnetPatrolCyclesEmpty >= 2 then
                        magnetPatrolCyclesEmpty = 0
                        magnetPatrolIndex = 1
                        local hopped, jobId = magnetHopServer(game.PlaceId)
                        if hopped then
                            task.wait(3)
                            return "Hopping to server " .. tostring(jobId):sub(1,8) .. "..."
                        end
                        return "Job queue empty - refetching next cycle"
                    end
                    return "Advancing to " .. MAGNET_PATROL_ISLANDS[magnetPatrolIndex].name
                elseif state.Secrets then
                    return state:SecretStep()
                end
                return "Off"
            end)
            state.Status = ok and result or ("Error: " .. tostring(result))
            if state.Magnet then
                statusLabel:SetDesc("Magnet: " .. state.Status)
            elseif state.Secrets then
                secretStatus:SetDesc(state.Status)
            else
                statusLabel:SetDesc("Magnet: off")
            end
            if state.Secrets and os.clock() - state.LastRefresh >= 15 then state:Refresh() end
        end
    end)
end)
