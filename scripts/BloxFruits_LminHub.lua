local Y = game.Players;
local d = Y.LocalPlayer or Y.PlayerAdded:Wait();
local i = d.Character;
local R = i and i:FindFirstChild("HumanoidRootPart");
local Q = game:GetService("ReplicatedStorage");
local playerData = d:FindFirstChild("Data") or d:WaitForChild("Data", 30);
local levelValue = playerData and playerData:FindFirstChild("Level");
local r = levelValue and levelValue.Value or 1;
local a = game:GetService("TeleportService");
local w = game:GetService("TweenService");
local F = game:GetService("Lighting");
local M = workspace.Enemies;
local K = game:GetService("VirtualInputManager");
local n = game:GetService("VirtualUser");
local I = d.Team;
local W = game:GetService("RunService");
local N = game:GetService("Stats");
local energyValue = i and i:FindFirstChild("Energy");
local D = energyValue and energyValue.Value or 0;
local A = game:GetService("Players");
local u = A.LocalPlayer:WaitForChild("PlayerGui");
local g = A.LocalPlayer;
local z = g:WaitForChild("Backpack");
local U = {};
local v = {};
local m = {};
local b = false;
local c = true;
local Z = false;
local T = .1;
local P = 25;
local MainGuiCache = nil;
local function MainGui()
	if MainGuiCache and MainGuiCache.Parent then
		return MainGuiCache;
	end;
	MainGuiCache = u:FindFirstChild("Main");
	if not MainGuiCache then
		for _, gui in ipairs(u:GetChildren()) do
			if gui:IsA("ScreenGui") and (gui:FindFirstChild("Quest") or gui:FindFirstChild("TopHUDList")) then
				MainGuiCache = gui;
				break;
			end;
		end;
	end;
	return MainGuiCache;
end;
local function GuiNode(...)
	local node = MainGui();
	for _, name in ipairs({ ... }) do
		if not node then
			return nil;
		end;
		node = node:FindFirstChild(name);
	end;
	return node;
end;
local function GuiShown(...)
	local node = GuiNode(...);
	return node ~= nil and node.Visible == true;
end;
local function SetGuiShown(value, ...)
	local node = GuiNode(...);
	if node then
		node.Visible = value;
		return true;
	end;
	return false;
end;
local function QuestText()
	local node = GuiNode("Quest", "Container", "QuestTitle", "Title");
	if node then
		return tostring(node.Text);
	end;
	return "";
end;
NetRemote = function(name)
	local modules = Q:FindFirstChild("Modules");
	local net = modules and modules:FindFirstChild("Net");
	return net and net:FindFirstChild(name);
end;
NetInvoke = function(name, ...)
	local remote = NetRemote(name);
	if not remote then
		return nil;
	end;
	local ok, result = pcall(remote.InvokeServer, remote, ...);
	if ok then
		return result;
	end;
	return nil;
end;
NetFire = function(name, ...)
	local remote = NetRemote(name);
	if remote then
		pcall(remote.FireServer, remote, ...);
	end;
end;
local function FindNamed(name)
	return workspace:FindFirstChild(name);
end;
local function TpNamed(name)
	local target = FindNamed(name);
	if target and target.CFrame then
		_tp(target.CFrame);
		return true;
	end;
	return false;
end;
do
	local previousUI = getgenv().BloxFruitsUI;
	local previousLibrary = previousUI and previousUI.Library;
	if previousLibrary and not previousLibrary.Unloaded and type(previousLibrary.Unload) == "function" then
		pcall(previousLibrary.Unload, previousLibrary);
	end;
end;
local UI = { Stopped = false };
local function IdleWait(active, interval)
	if active then
		if interval then
			task.wait(interval);
		else
			task.wait();
		end;
	else
		task.wait(.75);
	end;
	return not UI.Stopped;
end;

local plr = d
local C = R
local Lv = r
local TeleportService = a
local Lighting = F
local Enemies = M
local Stats = N
local Energy = D
local shouldTween = false
BFMove = {
	Tween = nil,
	Target = nil,
	Root = nil,
	Connection = nil,
	ForceTween = false,
	SupportRoot = nil,
	SupportBody = nil,
	ResetToken = 0,
	ResetBusy = false,
	ResetUsed = false,
	ResetNextAt = 0,
};
getgenv().BFResetOnBypass = getgenv().BFResetOnBypass ~= false;
local function updateCharacter(character)
	i = character;
	R = character and character:FindFirstChild("HumanoidRootPart");
	C = R;
	local currentEnergy = character and character:FindFirstChild("Energy");
	D = currentEnergy and currentEnergy.Value or 0;
	Energy = D;
end
if i then
	updateCharacter(i);
end
UI.CharacterAddedConnection = d.CharacterAdded:Connect(function(character)
	character:WaitForChild("HumanoidRootPart", 30);
	updateCharacter(character);
end);
UI.CharacterRemovingConnection = d.CharacterRemoving:Connect(function(character)
	if i == character then
		updateCharacter(nil);
	end;
end);

if not game:IsLoaded() then
	game.Loaded:Wait();
end;
if game.PlaceId == 2753915549 or game.PlaceId == 85211729168715 then
	World1 = true;
elseif game.PlaceId == 4442272183 or game.PlaceId == 79091703265657 then
	World2 = true;
elseif game.PlaceId == 7449423635 or game.PlaceId == 100117331123089 then
	World3 = true;
end;
Marines = function()
		BFComm("SetTeam", "Marines");
	end;


Pirates = function()
		BFComm("SetTeam", "Pirates");
	end;

_G.MobHeight = _G.MobHeight or 20
_B = false
PosMon = nil

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
		["Pirate Millionaire"] = CFrame.new(-712.82727050781, 98.577049255371, 5711.9541015625),
		["Pistol Billionaire"] = CFrame.new(-723.43316650391, 147.42906188965, 5931.9931640625),
		["Dragon Crew Warrior"] = CFrame.new(7021.5043945312, 55.762702941895, -730.12908935547),
		["Dragon Crew Archer"] = CFrame.new(6625, 378, 244),
		["Female Islander"] = CFrame.new(4692.7939453125, 797.97668457031, 858.84802246094),
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
		local backpack = d:FindFirstChild("Backpack");
		local tool = backpack and backpack:FindFirstChild(Y);
		local character = d.Character;
		local humanoid = character and character:FindFirstChildOfClass("Humanoid");
		if tool and humanoid then
			humanoid:EquipTool(tool);
		end;
	end;
WeaponOrder = { "Melee", "Sword", "Blox Fruit", "Gun" };
EnsureWeapon = function()
		local character = d.Character;
		local backpack = d:FindFirstChild("Backpack");
		local selected = _G.SelectWeapon;
		if type(selected) == "string" and selected ~= "" then
			local selectedTool = character and character:FindFirstChild(selected) or backpack and backpack:FindFirstChild(selected);
			if selectedTool and selectedTool:IsA("Tool") then
				return selected;
			end;
			_G.SelectWeapon = nil;
		end;
		local held = character and character:FindFirstChildOfClass("Tool");
		if held then
			_G.SelectWeapon = held.Name;
			return _G.SelectWeapon;
		end;
		if not backpack then
			return nil;
		end;
		local children = backpack:GetChildren();
		for _, kind in ipairs(WeaponOrder) do
			for _, tool in ipairs(children) do
				if tool:IsA("Tool") and tool.ToolTip == kind then
					_G.SelectWeapon = tool.Name;
					return _G.SelectWeapon;
				end;
			end;
		end;
		for _, tool in ipairs(children) do
			if tool:IsA("Tool") then
				_G.SelectWeapon = tool.Name;
				return _G.SelectWeapon;
			end;
		end;
		return nil;
	end;
EquippedToolTip = function()
		local character = d.Character;
		local tool = character and character:FindFirstChildOfClass("Tool");
		if tool then
			return tostring(tool.ToolTip);
		end;
		return "";
	end;
weaponSc = function(Y)
		local character = d.Character;
		local equipped = character and character:FindFirstChildOfClass("Tool");
		if equipped and equipped.ToolTip == Y then
			return equipped.Name;
		end;
		local backpack = d:FindFirstChild("Backpack");
		if not backpack then
			return nil;
		end;
		for _, tool in ipairs(backpack:GetChildren()) do
			if tool:IsA("Tool") and tool.ToolTip == Y then
				EquipWeapon(tool.Name);
				return tool.Name;
			end;
		end;
		return nil;
	end;
local f = {};
f.__index = f;
local BFAttackUntil = 0;
local function BFTouchAttack()
	BFAttackUntil = os.clock() + .5;
end;
f.Alive = function(Y)
		if not Y then
			return;
		end;
		local d = Y:FindFirstChild("Humanoid");
		return d and d.Health > 0;
	end;
UI.CombatOffsets = {
	CFrame.new(0, 30, 25),
	CFrame.new(25, 30, 0),
	CFrame.new(-25, 30, 0),
	CFrame.new(0, 30, -25),
	CFrame.new(-25, 30, 0),
};
function UI.RunCombatOffsets(target)
	for _, offset in ipairs(UI.CombatOffsets) do
		task.wait(.12);
		local targetRoot = target and target.Parent and target:FindFirstChild("HumanoidRootPart");
		if not targetRoot or not f.Alive(target) then
			break;
		end;
		local position = targetRoot.Position;
		if position.Y < 10 then
			position = Vector3.new(position.X, 50, position.Z);
		end;
		_tp(CFrame.new(position) * offset);
	end;
end;
f.Pos = function(Y, distance)
		local character = plr.Character;
		local root = R or character and character:FindFirstChild("HumanoidRootPart");
		local position;
		if typeof(Y) == "CFrame" or typeof(Y) == "Vector3" then
			position = typeof(Y) == "CFrame" and Y.Position or Y;
		elseif typeof(Y) == "Instance" then
			local part = Y:IsA("BasePart") and Y or Y:FindFirstChildWhichIsA("BasePart", true);
			position = part and part.Position;
		end;
		return root ~= nil and position ~= nil and (root.Position - position).Magnitude <= (tonumber(distance) or 8);
	end;
f.Dist = function(Y, d)
		local character = plr.Character;
		local root = R or character and character:FindFirstChild("HumanoidRootPart");
		local target = Y and Y:FindFirstChild("HumanoidRootPart");
		return root ~= nil and target ~= nil and (root.Position - target.Position).Magnitude <= d;
	end;
f.DistH = function(Y, d)
		local character = plr.Character;
		local root = R or character and character:FindFirstChild("HumanoidRootPart");
		local target = Y and Y:FindFirstChild("HumanoidRootPart");
		return root ~= nil and target ~= nil and (root.Position - target.Position).Magnitude > d;
	end;
f.Kill = function(Y, d)
		if Y and d and Y:FindFirstChild("HumanoidRootPart") then
			BFTouchAttack();
			if not Y:GetAttribute("Locked") then
				Y:SetAttribute("Locked", Y.HumanoidRootPart.CFrame);
			end;
			PosMon = (Y:GetAttribute("Locked")).Position;
			BringEnemy();
			EquipWeapon(_G.BFCombatWeapon or EnsureWeapon());
			local R = EquippedToolTip();
			if R == "Blox Fruit" then
				_tp((Y.HumanoidRootPart.CFrame * CFrame.new(0, 10, 0)) * CFrame.Angles(0, math.rad(90), 0));
			else
				_tp((Y.HumanoidRootPart.CFrame * CFrame.new(0, 30, 0)) * CFrame.Angles(0, math.rad(180), 0));
			end;
			if getgenv().BFRandomCFrame then
				UI.RunCombatOffsets(Y);
			end;
		end;
	end;
f.Kill2 = function(Y, d)
		if Y and d and Y:FindFirstChild("HumanoidRootPart") then
			BFTouchAttack();
			if not Y:GetAttribute("Locked") then
				Y:SetAttribute("Locked", Y.HumanoidRootPart.CFrame);
			end;
			PosMon = (Y:GetAttribute("Locked")).Position;
			BringEnemy();
			EquipWeapon(_G.BFCombatWeapon or EnsureWeapon());
			local R = EquippedToolTip();
			if R == "Blox Fruit" then
				_tp((Y.HumanoidRootPart.CFrame * CFrame.new(0, 10, 0)) * CFrame.Angles(0, math.rad(90), 0));
			else
				_tp((Y.HumanoidRootPart.CFrame * CFrame.new(0, 30, 8)) * CFrame.Angles(0, math.rad(180), 0));
			end;
			if getgenv().BFRandomCFrame then
				UI.RunCombatOffsets(Y);
			end;
		end;
	end;
f.KillSea = function(Y, d)
		if Y and d and Y:FindFirstChild("HumanoidRootPart") then
			BFTouchAttack();
			if not Y:GetAttribute("Locked") then
				Y:SetAttribute("Locked", Y.HumanoidRootPart.CFrame);
			end;
			PosMon = (Y:GetAttribute("Locked")).Position;
			BringEnemy();
			EquipWeapon(_G.BFCombatWeapon or EnsureWeapon());
			local R = EquippedToolTip();
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
		if Y and d and Y:FindFirstChild("HumanoidRootPart") then
			BFTouchAttack();
			if not Y:GetAttribute("Locked") then
				Y:SetAttribute("Locked", Y.HumanoidRootPart.CFrame);
			end;
			PosMon = (Y:GetAttribute("Locked")).Position;
			BringEnemy();
			if SwordName then
				EquipWeapon(SwordName);
			else
				weaponSc("Sword");
			end;
			_tp(Y.HumanoidRootPart.CFrame * CFrame.new(0, 30, 0));
			if getgenv().BFRandomCFrame then
				UI.RunCombatOffsets(Y);
			end;
		end;
	end;
f.Mas = function(Y, d)
		if Y and d and Y:FindFirstChild("HumanoidRootPart") then
			BFTouchAttack();
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
		if Y and d and Y:FindFirstChild("HumanoidRootPart") then
			BFTouchAttack();
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
BFStatNames = {
	Melee = "Melee",
	Defense = "Defense",
	Sword = "Sword",
	Gun = "Gun",
	Devil = "Demon Fruit",
};
statsSetings = function(Y, R)
		local remoteName = BFStatNames[Y];
		local data = d:FindFirstChild("Data");
		local points = data and data:FindFirstChild("Points");
		local available = math.floor(tonumber(points and points.Value) or 0);
		if not remoteName or available <= 0 then
			return false;
		end;
		local amount = math.max(1, math.min(math.floor(tonumber(R) or 1), available));
		BFComm("AddPoint", remoteName, amount);
		return true;
	end;
ExtendSimulationRadius = function()
	if type(sethiddenproperty) == "function" then
		pcall(sethiddenproperty, d, "SimulationRadius", math.huge);
	end;
end;
BFBringNextAt = 0;
BFRadiusNextAt = 0;
UI.BroughtEnemyOriginal = setmetatable({}, { __mode = "k" });
function UI.RestoreBroughtEnemies()
	for humanoid, state in pairs(UI.BroughtEnemyOriginal) do
		if humanoid.Parent then
			humanoid.WalkSpeed = state.WalkSpeed;
			humanoid.JumpPower = state.JumpPower;
		end;
		if state.Part and state.Part.Parent then
			if typeof(state.CFrame) == "CFrame" then
				state.Part.CFrame = state.CFrame;
			end;
			state.Part.CanCollide = state.CanCollide;
		end;
		UI.BroughtEnemyOriginal[humanoid] = nil;
	end;
end;
BringEnemy = function()
		if not _B or typeof(PosMon) ~= "Vector3" then
			return;
		end;
		local now = os.clock();
		if now < BFBringNextAt then
			return;
		end;
		BFBringNextAt = now + .08;
		if now >= BFRadiusNextAt then
			BFRadiusNextAt = now + 1;
			ExtendSimulationRadius();
		end;
		for _, R in pairs(M:GetChildren()) do
			local humanoid = R:FindFirstChild("Humanoid");
			local primary = R.PrimaryPart or R:FindFirstChild("HumanoidRootPart");
			if humanoid and primary and humanoid.Health > 0 then
				if (primary.Position - PosMon).Magnitude <= 300 then
					if not UI.BroughtEnemyOriginal[humanoid] then
						UI.BroughtEnemyOriginal[humanoid] = {
							WalkSpeed = humanoid.WalkSpeed,
							JumpPower = humanoid.JumpPower,
							Part = primary,
							CFrame = primary.CFrame,
							CanCollide = primary.CanCollide,
						};
					end;
					primary.CFrame = CFrame.new(PosMon);
					primary.CanCollide = true;
					humanoid.WalkSpeed = 0;
					humanoid.JumpPower = 0;
				end;
			end;
		end;
	end;
task.spawn(function()
	while not UI.Stopped and task.wait(.25) do
		if next(UI.BroughtEnemyOriginal) ~= nil and os.clock() >= BFAttackUntil then
			UI.RestoreBroughtEnemies();
		end;
	end;
	UI.RestoreBroughtEnemies();
end);
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
do
	local previousAimRestore = getgenv().BFAimNamecallRestore;
	if type(previousAimRestore) == "function" then
		pcall(previousAimRestore);
	end;
	local s = getrawmetatable(game);
	local x = s.__namecall;
	UI.AimRedirectCount = 0;
	UI.AimLastRedirectKind = nil;
	UI.AimLastRedirectRemote = nil;
	UI.AimLastRedirectTarget = nil;
	setreadonly(s, false);
	local BFAimNamecallHook;
	BFAimNamecallHook = newcclosure(function(...)
		local Y = getnamecallmethod();
		local d = { ... };
		if tostring(Y) == "FireServer" then
			local remote = d[1];
			local remoteName = tostring(remote);
			if _G.AimbotGun and remoteName == "RE/ShootGunEvent" and typeof(MousePos) == "Vector3" then
				d[2] = MousePos;
				UI.AimRedirectCount = UI.AimRedirectCount + 1;
				UI.AimLastRedirectKind = "gun";
				UI.AimLastRedirectRemote = remoteName;
				UI.AimLastRedirectTarget = MousePos;
				return x(unpack(d));
			end;
			if _G.AimbotGun and remoteName == "RemoteEvent" and d[2] == "TAP" and typeof(MousePos) == "Vector3" then
				d[3] = MousePos;
				UI.AimRedirectCount = UI.AimRedirectCount + 1;
				UI.AimLastRedirectKind = "gun-tap";
				UI.AimLastRedirectRemote = remoteName;
				UI.AimLastRedirectTarget = MousePos;
				return x(unpack(d));
			end;
			if remoteName == "RemoteEvent" and typeof(d[2]) == "Vector3" and typeof(MousePos) == "Vector3" then
				if _G.FarmMastery_G and not b or _G.FarmMastery_Dev or _G.FarmBlazeEM or _G.Prehis_Skills or _G.SeaBeast1 or _G.FishBoat or _G.PGB or _G.Leviathan1 or _G.Complete_Trials or _G.AimMethod and ABmethod == "AimBots Skill" or _G.AimMethod and ABmethod == "Auto Aimbots" then
					d[2] = MousePos;
					UI.AimRedirectCount = UI.AimRedirectCount + 1;
					UI.AimLastRedirectKind = "skill";
					UI.AimLastRedirectRemote = remoteName;
					UI.AimLastRedirectTarget = MousePos;
					return x(unpack(d));
				end;
			end;
		end;
		return x(...);
		end);
	s.__namecall = BFAimNamecallHook;
	setreadonly(s, true);
	UI.RestoreAimNamecall = function()
		pcall(function()
			if s.__namecall == BFAimNamecallHook then
				setreadonly(s, false);
				s.__namecall = x;
				setreadonly(s, true);
			end;
		end);
		if getgenv().BFAimNamecallRestore == UI.RestoreAimNamecall then
			getgenv().BFAimNamecallRestore = nil;
		end;
	end;
	getgenv().BFAimNamecallRestore = UI.RestoreAimNamecall;
end;
GetConnectionEnemies = function(Y)
		local names;
		if type(Y) == "table" then
			names = {};
			for _, name in ipairs(Y) do
				names[name] = true;
			end;
		end;
		local function matches(name)
			return names and names[name] == true or name == Y;
		end;
		for d, R in pairs(Q:GetChildren()) do
			if R:IsA("Model") and matches(R.Name) and (R:FindFirstChild("Humanoid") and R.Humanoid.Health > 0) then
				return R;
			end;
		end;
		for d, R in next, M:GetChildren() do
			if R:IsA("Model") and matches(R.Name) and (R:FindFirstChild("Humanoid") and R.Humanoid.Health > 0) then
				return R;
			end;
		end;
	end;
CheckF = function()
		if GetBP("Dragon-Dragon") or GetBP("Gas-Gas") or GetBP("Yeti-Yeti") or GetBP("Kitsune-Kitsune") or GetBP("T-Rex-T-Rex") then
			return true;
		end;
	end;
CheckBoat = function()
		local boats = workspace:FindFirstChild("Boats");
		if not boats then
			return false;
		end;
		for _, boat in pairs(boats:GetChildren()) do
			local owner = boat:FindFirstChild("Owner");
			if owner and owner:IsA("ValueBase") and tostring(owner.Value) == tostring(d.Name) then
				return boat;
			end;
		end;
		return false;
	end;
CheckEnemiesBoat = function()
		for _, enemy in pairs(M:GetChildren()) do
			local health = enemy:FindFirstChild("Health");
			local value = health and health:IsA("ValueBase") and tonumber(health.Value);
			if enemy.Name == "FishBoat" and value and value > 0 then
				return true;
			end;
		end;
		return false;
	end;
CheckPirateGrandBrigade = function()
		for _, enemy in pairs(M:GetChildren()) do
			local health = enemy:FindFirstChild("Health");
			local value = health and health:IsA("ValueBase") and tonumber(health.Value);
			if (enemy.Name == "PirateGrandBrigade" or enemy.Name == "PirateBrigade") and value and value > 0 then
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
		local beasts = workspace:FindFirstChild("SeaBeasts");
		return beasts ~= nil and beasts:FindFirstChild("SeaBeast1") ~= nil;
	end;
CheckLeviathan = function()
		local beasts = workspace:FindFirstChild("SeaBeasts");
		return beasts ~= nil and beasts:FindFirstChild("Leviathan") ~= nil;
	end;
-- Physical fruits no longer carry an EatRemote, so the old detector matched
-- nothing and Auto Store Fruit silently did nothing. Identify them by the ItemId
-- attribute instead, which resolves to the Fruits bracket in ItemConfig. The
-- server callback (CommF_.StoreFruit) still takes (originalName, tool).
BFFruitToolName = function(tool)
		if not tool then
			return nil;
		end;
		local original = tool:GetAttribute("OriginalName");
		if type(original) == "string" and original ~= "" then
			return original;
		end;
		local config = inventoryCache.GetConfig();
		local itemId = tool:GetAttribute("ItemId");
		local definition = config and itemId and (config[itemId] or config[tostring(itemId)]);
		if definition and definition.Id then
			local display = tostring(definition.Id);
			local name = display:match("^(.-)%s*%[[^%]]+%]$") or display;
			return (name:gsub("^%s*%-%-%s*", ""));
		end;
		return (tool.Name:gsub("%s*Fruit$", ""));
	end;
BFIsFruitTool = function(tool)
		if not tool or not tool:IsA("Tool") then
			return false;
		end;
		if tool:FindFirstChild("EatRemote", true) then
			return true;
		end;
		local config = inventoryCache.GetConfig();
		local itemId = tool:GetAttribute("ItemId");
		local definition = config and itemId and (config[itemId] or config[tostring(itemId)]);
		if definition and definition.Brackets == "Fruits" then
			return true;
		end;
		return tool.Name:match("%sFruit$") ~= nil;
	end;
UpdStFruit = function()
		local backpack = d:FindFirstChild("Backpack");
		if not backpack then
			return false, 0;
		end;
		local stored = 0;
		for _, tool in ipairs(backpack:GetChildren()) do
			if BFIsFruitTool(tool) then
				local name = BFFruitToolName(tool);
				if name then
					BFComm("StoreFruit", name, tool);
					stored = stored + 1;
					task.wait(.15);
				end;
			end;
		end;
		return stored > 0, stored;
	end;
-- CommF_ "getInventoryFruits" was removed from the game and now returns nil, which
-- made every stored-fruit lookup (raid fruit, Zou unlock) bail out immediately.
-- Read the fruits straight out of the inventory snapshot instead.
BFStoredFruits = function()
		local fruits = {};
		for _, item in pairs(inventorySnapshot()) do
			if type(item) == "table" and item.Bracket == "Fruits" and type(item.Name) == "string" and item.Name ~= "" then
				table.insert(fruits, { Name = item.Name, Count = tonumber(item.Count) or 1 });
			end;
		end;
		return fruits;
	end;
-- LoadFruit("Creation-Creation") hands back a tool called "Creation Fruit", so the
-- old `FindFirstChild(fruitName)` check never matched and the raid loop re-issued
-- LoadFruit forever instead of moving on.
BFFindFruitTool = function(fruitName)
		if type(fruitName) ~= "string" or fruitName == "" then
			return nil;
		end;
		local base = fruitName:match("^(.-)%-") or fruitName;
		local candidates = { fruitName, base .. " Fruit", base };
		local character = d.Character;
		local backpack = d:FindFirstChild("Backpack");
		for _, container in ipairs({ backpack, character }) do
			if container then
				for _, name in ipairs(candidates) do
					local tool = container:FindFirstChild(name);
					if tool then
						return tool;
					end;
				end;
				for _, tool in ipairs(container:GetChildren()) do
					if BFIsFruitTool(tool) and BFFruitToolName(tool) == fruitName then
						return tool;
					end;
				end;
			end;
		end;
		return nil;
	end;
BFFindWorldFruit = function(nearestOnly)
		local character = d.Character;
		local root = character and character:FindFirstChild("HumanoidRootPart");
		if not root then
			return nil;
		end;
		local best, bestDistance;
		for _, object in ipairs(workspace:GetChildren()) do
			local handle = object:FindFirstChild("Handle");
			local eatRemote = object:FindFirstChild("EatRemote", true);
			if handle and handle:IsA("BasePart") and (eatRemote or string.find(string.lower(object.Name), "fruit", 1, true)) then
				if not nearestOnly then
					handle.CFrame = root.CFrame;
				else
					local distance = (handle.Position - root.Position).Magnitude;
					if not bestDistance or distance < bestDistance then
						best = handle;
						bestDistance = distance;
					end;
				end;
			end;
		end;
		return best, bestDistance;
	end;
collectFruits = function(active)
		if active then
			BFFindWorldFruit(false);
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
		local backpack = d:FindFirstChild("Backpack");
		local character = d.Character;
		local containers = {};
		if backpack then
			table.insert(containers, backpack);
		end;
		if character then
			table.insert(containers, character);
		end;
		for _, container in ipairs(containers) do
			for _, tool in ipairs(container:GetChildren()) do
				local eatRemote = tool:FindFirstChild("EatRemote", true);
				if eatRemote then
					if container == backpack then
						EquipWeapon(tool.Name);
						task.wait(.1);
						character = d.Character;
						tool = character and character:FindFirstChild(tool.Name) or tool;
						eatRemote = tool and tool:FindFirstChild("EatRemote", true) or eatRemote;
					end;
					if GuiShown("Dialogue") then
						SetGuiShown(false, "Dialogue");
					end;
					if eatRemote and eatRemote:IsA("RemoteFunction") then
						pcall(eatRemote.InvokeServer, eatRemote, "Drop");
					elseif eatRemote and eatRemote:IsA("RemoteEvent") then
						pcall(eatRemote.FireServer, eatRemote, "Drop");
					end;
					return true;
				end;
			end;
		end;
		return false;
	end;
local inventoryCache = {
	Data = {},
	UpdatedAt = 0,
	ConfigTried = false,
	BracketTypes = {
		Swords = "Sword",
		Materials = "Material",
		Guns = "Gun",
		Fruits = "Blox Fruit",
		Accessories = "Accessory",
		Gear = "Gear",
		Fish = "Fish",
		Usables = "Usable",
		Consumables = "Consumable",
		Trinkets = "Trinket",
		Titles = "Title",
		Skins = "Skin",
		Premium = "Premium",
		Backgrounds = "Background",
		Configurables = "Configurable",
	},
};
inventoryCache.GetConfig = function()
	if inventoryCache.ConfigTried then
		return inventoryCache.Config;
	end;
	inventoryCache.ConfigTried = true;
	local itemConfig = Q:FindFirstChild("ItemConfig");
	local data = itemConfig and itemConfig:FindFirstChild("Data");
	local module = data and data:FindFirstChild("Inventory");
	if module and module:IsA("ModuleScript") then
		local ok, result = pcall(require, module);
		if ok and type(result) == "table" then
			inventoryCache.Config = result;
		end;
	end;
	return inventoryCache.Config;
end;
inventoryCache.FindReplication = function(value, depth, visited)
	if type(value) ~= "table" or depth < 0 or visited[value] then
		return nil;
	end;
	visited[value] = true;
	local candidate = rawget(value, d.UserId) or rawget(value, tostring(d.UserId));
	if type(candidate) == "table" and type(rawget(candidate, "GetItems")) == "function" then
		return candidate;
	end;
	if depth == 0 then
		return nil;
	end;
	local inspected = 0;
	for _, nested in pairs(value) do
		inspected = inspected + 1;
		if inspected > 200 then
			break;
		end;
		if type(nested) == "table" then
			local found = inventoryCache.FindReplication(nested, depth - 1, visited);
			if found then
				return found;
			end;
		end;
	end;
	return nil;
end;
inventoryCache.ResolveReplication = function()
	local cached = inventoryCache.Replication;
	if type(cached) == "table" and type(rawget(cached, "GetItems")) == "function" then
		return cached;
	end;
	if type(getconnections) ~= "function" or type(debug) ~= "table" or type(debug.getinfo) ~= "function" or type(debug.getupvalues) ~= "function" then
		return nil;
	end;
	local event = NetRemote("RE/OnItemValueChanged");
	if not event or not event:IsA("RemoteEvent") then
		return nil;
	end;
	local ok, connections = pcall(getconnections, event.OnClientEvent);
	if not ok or type(connections) ~= "table" then
		return nil;
	end;
	for _, connection in pairs(connections) do
		local callback = connection and connection.Function;
		if type(callback) == "function" then
			local infoOk, info = pcall(debug.getinfo, callback);
			if infoOk and type(info) == "table" and info.source == "=ReplicatedStorage.ItemReplicationService" then
				local upvaluesOk, upvalues = pcall(debug.getupvalues, callback);
				if upvaluesOk and type(upvalues) == "table" then
					for _, upvalue in pairs(upvalues) do
						local found = inventoryCache.FindReplication(upvalue, 2, {});
						if found then
							inventoryCache.Replication = found;
							return found;
						end;
					end;
				end;
			end;
		end;
	end;
	return nil;
end;
-- The live item rows are flat {ItemId, NetworkedUID, Key, Value} tuples that have
-- to be folded back into one record per item before anything can read them.
inventoryCache.BuildFromRows = function(rows)
	if type(rows) ~= "table" then
		return nil;
	end;
	local grouped = {};
	for _, row in pairs(rows) do
		if type(row) == "table" and row.ItemId ~= nil then
			local key = tostring(row.ItemId) .. "\0" .. tostring(row.NetworkedUID or "");
			local record = grouped[key];
			if not record then
				record = {
					ItemId = row.ItemId,
					NetworkedUID = row.NetworkedUID,
				};
				grouped[key] = record;
			end;
			if row.Key ~= nil then
				record[row.Key] = row.Value;
			else
				for field, value in pairs(row) do
					record[field] = value;
				end;
			end;
		end;
	end;
	local config = inventoryCache.GetConfig();
	local inventory = {};
	for _, record in pairs(grouped) do
		if record.IsOwned == true then
			local definition = config and (config[record.ItemId] or config[tostring(record.ItemId)]);
			local display = tostring(definition and definition.Id or record.Name or record.ItemId);
			local name = display:match("^(.-)%s*%[[^%]]+%]$") or display;
			-- Some config ids are commented out as "-- Bisento [PhysicalMoveset-1]";
			-- keeping the dashes made every name comparison miss.
			name = name:gsub("^%s*%-%-%s*", ""):gsub("^%s+", ""):gsub("%s+$", "");
			record.Name = name;
			record.Type = inventoryCache.BracketTypes[definition and definition.Brackets];
			record.Bracket = definition and definition.Brackets or nil;
			record.Count = tonumber(record.Quantity) or 0;
			table.insert(inventory, record);
		end;
	end;
	return inventory;
end;
inventoryCache.ReplicatedSnapshot = function()
	local cache = inventoryCache.ResolveReplication();
	local method = type(cache) == "table" and rawget(cache, "GetItems") or nil;
	if type(method) ~= "function" then
		return nil;
	end;
	local ok, rows = pcall(method, cache);
	if not ok or type(rows) ~= "table" then
		inventoryCache.Replication = nil;
		return nil;
	end;
	return inventoryCache.BuildFromRows(rows);
end;
-- Official server read. Works without the debug library, so it is the reliable
-- fallback when the replication cache cannot be scraped. The old fallbacks
-- ("getInventory" on CommF_ and on the jobs remote) no longer exist: the jobs
-- one now throws "attempt to call a nil value" and CommF_ just returns nil.
inventoryCache.RemoteSnapshot = function()
	local remote = NetRemote("RF/GetAllItemValues");
	if not remote or not remote:IsA("RemoteFunction") then
		return nil;
	end;
	local ok, rows = pcall(remote.InvokeServer, remote);
	if not ok then
		return nil;
	end;
	return inventoryCache.BuildFromRows(rows);
end;
local function inventorySnapshot()
	local now = os.clock();
	if now - inventoryCache.UpdatedAt < 2 then
		return inventoryCache.Data;
	end;
	inventoryCache.UpdatedAt = now;
	local inventory = inventoryCache.ReplicatedSnapshot();
	if type(inventory) ~= "table" or #inventory == 0 then
		inventory = inventoryCache.RemoteSnapshot();
	end;
	if type(inventory) == "table" and #inventory > 0 then
		inventoryCache.Data = inventory;
	end;
	return inventoryCache.Data;
end;
UI.InventorySnapshot = inventorySnapshot;
local function localItem(name)
	local character = d.Character;
	local backpack = d:FindFirstChild("Backpack");
	return backpack and backpack:FindFirstChild(name) or character and character:FindFirstChild(name);
end;
GetBP = function(Y)
		return localItem(Y);
	end;
GetIn = function(Y)
		if localItem(Y) then
			return true;
		end;
		for _, item in pairs(inventorySnapshot()) do
			if type(item) == "table" then
				if item.Name == Y then
					return true;
				end;
			end;
		end;
		return false;
	end;
GetM = function(Y)
		for _, item in pairs(inventorySnapshot()) do
			if type(item) == "table" then
				if item.Type == "Material" then
					if item.Name == Y then
						return tonumber(item.Count) or 0;
					end;
				end;
			end;
		end;
		return 0;
	end;
GetWP = function(Y)
		if localItem(Y) then
			return true;
		end;
		for _, item in pairs(inventorySnapshot()) do
			if type(item) == "table" then
				if item.Type == "Sword" then
					if item.Name == Y then
						return true;
					end;
				end;
			end;
		end;
			return false;
		end;
BFComm = function(...)
		local remotes = Q:FindFirstChild("Remotes");
		local remote = remotes and remotes:FindFirstChild("CommF_");
		if not remote then
			return nil;
		end;
		local ok, result = pcall(remote.InvokeServer, remote, ...);
		if ok then
			return result;
		end;
		return nil;
	end;
BFCommE = function(...)
		local remotes = Q:FindFirstChild("Remotes");
		local remote = remotes and remotes:FindFirstChild("CommE");
		if not remote then
			return false;
		end;
		return pcall(remote.FireServer, remote, ...);
	end;
BFCDKProgress = function(key)
		local progress = BFComm("CDKQuest", "Progress");
		if type(progress) ~= "table" then
			return nil, false;
		end;
		return progress[key], true;
	end;
local BFBonesCache = {
	Value = 0,
	UpdatedAt = -math.huge,
};
GetBones = function(force)
		local now = os.clock();
		if not force and now - BFBonesCache.UpdatedAt < 1 then
			return BFBonesCache.Value;
		end;
		local value = tonumber(BFComm("Bones", "Check"));
		if value then
			BFBonesCache.Value = value;
			BFBonesCache.UpdatedAt = now;
		end;
		return BFBonesCache.Value;
	end;
BFFindLocalItemLike = function(fragment)
		fragment = string.lower(tostring(fragment or ""));
		for _, container in ipairs({ d:FindFirstChild("Backpack"), d.Character }) do
			if container then
				for _, item in ipairs(container:GetChildren()) do
					if string.find(string.lower(item.Name), fragment, 1, true) then
						return item;
					end;
				end;
			end;
		end;
	end;
BFInventoryEntryLike = function(fragment, itemType)
		fragment = string.lower(tostring(fragment or ""));
		for _, item in pairs(inventorySnapshot()) do
			if type(item) == "table" and string.find(string.lower(tostring(item.Name or "")), fragment, 1, true) and (not itemType or item.Type == itemType) then
				return item;
			end;
		end;
	end;
BFHasItemLike = function(fragment, itemType)
		return BFFindLocalItemLike(fragment) ~= nil or BFInventoryEntryLike(fragment, itemType) ~= nil;
	end;
BFHasItemNamed = function(itemName)
		local expected = string.lower(tostring(itemName or ""));
		for _, container in ipairs({ d:FindFirstChild("Backpack"), d.Character }) do
			if container then
				for _, item in ipairs(container:GetChildren()) do
					if string.lower(item.Name) == expected then
						return true;
					end;
				end;
			end;
		end;
		for _, item in pairs(inventorySnapshot()) do
			if type(item) == "table" and string.lower(tostring(item.Name or "")) == expected then
				return true;
			end;
		end;
		return false;
	end;
BFAcquisitionItems = {
		BF_Toggle_Auto_Law_Sword = "Koko",
		BF_Toggle_Auto_Saw_Sword = "Shark Saw",
		BF_Toggle_Auto_Cybrog = "Cool Shades",
		BF_Toggle_Auto_Usoap_s_Hat = "Usopp's Hat",
		BF_Toggle_Auto_Warden_Sword = "Warden's Sword",
		BF_Toggle_Auto_Marine_Coat = "Coat",
		BF_Toggle_Auto_Swan_Coat = "Pink Coat",
		BF_Toggle_Auto_Rengoku_Sword = "Rengoku",
		BF_Toggle_Auto_Dragon_Trident = "Dragon Trident",
		BF_Toggle_Auto_Long_Sword = "Longsword",
		BF_Toggle_Auto_Midnight_Blade = "Midnight Blade",
		BF_Toggle_Auto_Swan_Glasses = "Swan Glasses",
		BF_Toggle_Auto_Canvendish_Sword = "Canvander",
		BF_Toggle_Auto_Twin_Hooks = "Twin Hooks",
		BF_Toggle_Auto_Serpent_Bow = "Serpent Bow",
		BF_Toggle_Auto_Lei_Accessory = "Lei",
		BF_Toggle_Auto_Pole_V1 = "Pole (1st Form)",
		BF_Toggle_Auto_Pole_V2_Beta = "Pole (2nd Form)",
		BF_Toggle_Auto_Saber_Sword = "Saber",
		BF_Toggle_Auto_Tushita_Sword = "Tushita",
		BF_Toggle_Auto_Yama_Sword = "Yama",
		BF_Toggle_Auto_Get_CDK_Last_Quest = "Cursed Dual Katana",
		BF_Toggle_Auto_Yama_CDK = "Cursed Dual Katana",
		BF_Toggle_Auto_Tushita_CDK = "Cursed Dual Katana",
	};
BFStopOwnedAcquisition = function(toggleId)
		local itemName = BFAcquisitionItems[toggleId];
		if itemName and BFHasItemNamed(itemName) then
			UI.DisableToggle(toggleId);
			return true;
		end;
		return false;
	end;
BFItemMasteryLike = function(fragment)
		local tool = BFFindLocalItemLike(fragment);
		if tool then
			local value = tool:FindFirstChild("Level") or tool:FindFirstChild("Mastery");
			if value and tonumber(value.Value) then
				return tonumber(value.Value);
			end;
		end;
		local item = BFInventoryEntryLike(fragment);
		return item and tonumber(item.Mastery or item.Level) or 0;
	end;
BFNameKey = function(value)
		return string.lower((tostring(value):gsub("[^%w]", "")));
	end;
BFFindChild = function(parent, name)
		if not parent then
			return nil;
		end;
		local exact = parent:FindFirstChild(name);
		if exact then
			return exact;
		end;
		local key = BFNameKey(name);
		for _, child in ipairs(parent:GetChildren()) do
			if BFNameKey(child.Name) == key then
				return child;
			end;
		end;
		return nil;
	end;
BFMapNode = function(...)
		local path = { ... };
		local roots = { workspace };
		local map = workspace:FindFirstChild("Map");
		if map then
			table.insert(roots, 1, map);
		end;
		for _, root in ipairs(roots) do
			local node = root;
			for _, name in ipairs(path) do
				if not node then
					break;
				end;
				node = BFFindChild(node, name);
			end;
			if node then
				return node;
			end;
		end;
		return nil;
	end;
BFWorldLocations = function()
		local origin = workspace:FindFirstChild("_WorldOrigin");
		return origin and origin:FindFirstChild("Locations");
	end;
BFWorldLocation = function(name, recursive)
		local locations = BFWorldLocations();
		return locations and locations:FindFirstChild(name, recursive == true) or nil;
	end;
BFWorldLocationChildren = function()
		local locations = BFWorldLocations();
		return locations and locations:GetChildren() or {};
	end;
-- Raid islands are NOT parented under workspace._WorldOrigin.Locations (that folder
-- only holds permanent world islands such as "Hydra Island"/"Submerged Island"), so the
-- old BFWorldLocation("Island N") lookup always returned nil and Auto Next Island never
-- moved. Resolve them against the roots the raid actually streams them into instead.
BFRaidIslandNames = { "Island 1", "Island 2", "Island 3", "Island 4", "Island 5" };
BFRaidIslandRoots = function()
		local roots = {};
		local locations = BFWorldLocations();
		if locations then
			roots[#roots + 1] = locations;
		end;
		local map = workspace:FindFirstChild("Map");
		if map then
			roots[#roots + 1] = map;
		end;
		roots[#roots + 1] = workspace;
		return roots;
	end;
BFResolveRaidIsland = function(name)
		for _, root in ipairs(BFRaidIslandRoots()) do
			local node = root:FindFirstChild(name);
			local part = node and BFFirstPart(node);
			if part then
				return part;
			end;
		end;
		return nil;
	end;
BFRaidIslandList = function()
		local list = {};
		for index, name in ipairs(BFRaidIslandNames) do
			local part = BFResolveRaidIsland(name);
			if part then
				list[#list + 1] = { Index = index, Name = name, Part = part };
			end;
		end;
		return list;
	end;
BFRaidIslandHasEnemies = function(part, radius)
		if not part then
			return false;
		end;
		local enemies = workspace:FindFirstChild("Enemies");
		if not enemies then
			return false;
		end;
		radius = tonumber(radius) or 900;
		for _, enemy in ipairs(enemies:GetChildren()) do
			local humanoid = enemy:FindFirstChild("Humanoid") or enemy:FindFirstChildOfClass("Humanoid");
			local root = enemy:FindFirstChild("HumanoidRootPart");
			if humanoid and root and humanoid.Health > 0 and (root.Position - part.Position).Magnitude <= radius then
				return true;
			end;
		end;
		return false;
	end;
-- Pick the island the raid actually wants next: the lowest-numbered island that still
-- has something alive on it, otherwise step forward from whichever island we are stood
-- on. Never re-target the island we are already clearing.
BFRaidNextIsland = function(root)
		local list = BFRaidIslandList();
		if #list == 0 then
			return nil;
		end;
		for _, entry in ipairs(list) do
			if BFRaidIslandHasEnemies(entry.Part) then
				return entry.Part, entry.Name;
			end;
		end;
		if not root then
			return list[1].Part, list[1].Name;
		end;
		local nearest, nearestDistance;
		for _, entry in ipairs(list) do
			local distance = (entry.Part.Position - root.Position).Magnitude;
			if not nearestDistance or distance < nearestDistance then
				nearest, nearestDistance = entry, distance;
			end;
		end;
		if nearest and nearestDistance and nearestDistance > 350 then
			return nearest.Part, nearest.Name;
		end;
		for _, entry in ipairs(list) do
			if nearest and entry.Index > nearest.Index then
				return entry.Part, entry.Name;
			end;
		end;
		return nearest and nearest.Part or list[1].Part, nearest and nearest.Name or list[1].Name;
	end;
BFFirstPart = function(root)
		if not root then
			return nil;
		end;
		if root:IsA("BasePart") then
			return root;
		end;
		if root:IsA("Model") then
			local primary = root.PrimaryPart or root:FindFirstChild("HumanoidRootPart", true);
			if primary and primary:IsA("BasePart") then
				return primary;
			end;
		end;
		return root:FindFirstChildWhichIsA("BasePart", true);
	end;
BFCharacterPart = function()
		local player = game:GetService("Players").LocalPlayer;
		local character = player and player.Character;
		if not character then
			return nil;
		end;
		local part = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head");
		if part and part:IsA("BasePart") then
			return part;
		end;
		return BFFirstPart(character);
	end;
BFEnsureEspLabel = function(host, guiName, color, size, offset)
		if not host or not host:IsA("BasePart") then
			return nil, nil;
		end;
		local gui = host:FindFirstChild(guiName);
		if gui and not gui:IsA("BillboardGui") then
			gui:Destroy();
			gui = nil;
		end;
		if not gui then
			gui = Instance.new("BillboardGui");
			gui.Name = guiName;
			gui.Parent = host;
		end;
		gui.ExtentsOffset = offset or Vector3.new(0, 1, 0);
		gui.Size = size or UDim2.new(1, 200, 1, 30);
		gui.Adornee = host;
		gui.AlwaysOnTop = true;
		local label = gui:FindFirstChild("TextLabel");
		if label and not label:IsA("TextLabel") then
			label:Destroy();
			label = nil;
		end;
		if not label then
			label = Instance.new("TextLabel");
			label.Name = "TextLabel";
			label.Parent = gui;
		end;
		label.Font = Enum.Font.Code;
		label.TextSize = 14;
		label.TextWrapped = true;
		label.Size = UDim2.new(1, 0, 1, 0);
		label.TextYAlignment = Enum.TextYAlignment.Top;
		label.BackgroundTransparency = 1;
		label.TextStrokeTransparency = .5;
		label.TextColor3 = color or Color3.fromRGB(255, 255, 255);
		return gui, label;
	end;
BFNpcEsp = function(enabled, markerName, exactName, containsName)
		local marker = workspace:FindFirstChild(markerName);
		if not enabled then
			if marker then
				marker:Destroy();
			end;
			return;
		end;
		local ownPart = BFCharacterPart();
		local npcs = workspace:FindFirstChild("NPCs");
		if not ownPart or not npcs then
			if marker then
				marker:Destroy();
			end;
			return;
		end;
		local npc;
		for _, candidate in ipairs(npcs:GetChildren()) do
			local matches = exactName and candidate.Name == exactName or containsName and string.find(candidate.Name, containsName, 1, true);
			if matches then
				npc = candidate;
				break;
			end;
		end;
		local target = BFFirstPart(npc);
		if not target then
			if marker then
				marker:Destroy();
			end;
			return;
		end;
		if marker and not marker:IsA("Part") then
			marker:Destroy();
			marker = nil;
		end;
		if not marker then
			marker = Instance.new("Part");
			marker.Name = markerName;
			marker.Transparency = 1;
			marker.Size = Vector3.new(1, 1, 1);
			marker.Anchored = true;
			marker.CanCollide = false;
			marker.CanQuery = false;
			marker.CanTouch = false;
			marker.Parent = workspace;
		end;
		marker.CFrame = target.CFrame;
		local _, label = BFEnsureEspLabel(marker, "NameEsp", Color3.fromRGB(80, 245, 245));
		if label then
			label.Text = npc.Name .. ("   \n" .. (nq((ownPart.Position - target.Position).Magnitude / 3) .. " M"));
		end;
	end;
BFClearBerryMarkers = function(root, active)
		if not root then
			return;
		end;
		for _, child in ipairs(root:GetChildren()) do
			if child:IsA("Part") and string.sub(child.Name, 1, 13) == "BerryEspPart_" and (not active or not active[child.Name]) then
				child:Destroy();
			end;
		end;
	end;
BFUpdateBerryBush = function(bush, ownPart, selected)
		local parent = bush.Parent;
		if not parent then
			return;
		end;
		local success, pivot = pcall(function()
			return parent:GetPivot();
		end);
		local host = BFFirstPart(parent) or BFFirstPart(bush);
		local position = success and pivot.Position or host and host.Position;
		if not position then
			return;
		end;
		local active = {};
		for _, value in pairs(bush:GetAttributes()) do
			local berryName = type(value) == "string" and value or nil;
			if berryName and (not selected or selected[berryName]) then
				local markerName = "BerryEspPart_" .. berryName;
				active[markerName] = true;
				local marker = bush:FindFirstChild(markerName);
				if marker and not marker:IsA("Part") then
					marker:Destroy();
					marker = nil;
				end;
				if not marker then
					marker = Instance.new("Part");
					marker.Name = markerName;
					marker.Transparency = 1;
					marker.Size = Vector3.new(1, 1, 1);
					marker.Anchored = true;
					marker.CanCollide = false;
					marker.CanQuery = false;
					marker.CanTouch = false;
					marker.Parent = bush;
				end;
				marker.CFrame = CFrame.new(position);
				local distance = math.round((ownPart.Position - position).Magnitude / 3);
				if _G.AutoBerry and distance <= 20 then
					marker:Destroy();
				else
					local _, label = BFEnsureEspLabel(marker, "NameEsp", Color3.fromRGB(80, 245, 245), UDim2.new(0, 200, 0, 30));
					if label then
						label.Text = "[" .. (berryName .. ("] " .. (distance .. " M")));
					end;
				end;
			end;
		end;
		BFClearBerryMarkers(bush, active);
	end;
BFAttackSeaBeastStep = function(beast, active)
		local targetRoot = beast and beast:FindFirstChild("HumanoidRootPart");
		local health = beast and beast:FindFirstChild("Health");
		if not active or not targetRoot or not health or (tonumber(health.Value) or 0) <= 0 then
			return false;
		end;
		local plane = BFMapNode("WaterBase-Plane");
		local waterY = plane and plane:IsA("BasePart") and plane.Position.Y or targetRoot.Position.Y;
		_tp(CFrame.new(targetRoot.Position.X, waterY + 200, targetRoot.Position.Z));
		local character = d.Character;
		local root = character and character:FindFirstChild("HumanoidRootPart");
		if root and (root.Position - targetRoot.Position).Magnitude <= 500 then
			MousePos = targetRoot.Position;
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
		return true;
	end;
BFNameNeedleCache = setmetatable({}, { __mode = "k" });
BFNameNeedles = function(names)
	if type(names) ~= "table" then
		return string.lower(tostring(names));
	end;
	local cached = BFNameNeedleCache[names];
	if cached then
		return cached;
	end;
	cached = {};
	for index, name in ipairs(names) do
		cached[index] = string.lower(tostring(name));
	end;
	BFNameNeedleCache[names] = cached;
	return cached;
end;
BFFindLiveEnemyLike = function(names)
		local needles = BFNameNeedles(names);
		local singleNeedle = type(needles) == "string";
		local enemies = M;
		if not enemies or not enemies.Parent then
			enemies = workspace:FindFirstChild("Enemies");
			M = enemies;
		end;
		if not enemies then
			return nil;
		end;
		for _, enemy in ipairs(enemies:GetChildren()) do
			local humanoid = enemy:FindFirstChildOfClass("Humanoid");
			if humanoid and humanoid.Health > 0 then
				local enemyName = string.lower(enemy.Name);
				if singleNeedle then
					if string.find(enemyName, needles, 1, true) then
						return enemy;
					end;
				else
					for _, needle in ipairs(needles) do
						if string.find(enemyName, needle, 1, true) then
							return enemy;
						end;
					end;
				end;
			end;
		end;
	end;
	BFFindNearestEnemy = function(origin)
		if typeof(origin) ~= "Vector3" then
			local character = d.Character;
			local root = character and character:FindFirstChild("HumanoidRootPart");
			origin = root and root.Position or nil;
		end;
		if typeof(origin) ~= "Vector3" then
			return nil;
		end;
		local enemies = workspace:FindFirstChild("Enemies");
		if not enemies then
			return nil;
		end;
		local nearest = nil;
		local nearestDistance = math.huge;
		for _, enemy in ipairs(enemies:GetChildren()) do
			local humanoid = enemy:FindFirstChildOfClass("Humanoid");
			local enemyRoot = enemy:FindFirstChild("HumanoidRootPart");
			if humanoid and enemyRoot and humanoid.Health > 0 then
				local distance = (enemyRoot.Position - origin).Magnitude;
				if distance < nearestDistance then
					nearest = enemy;
					nearestDistance = distance;
				end;
			end;
		end;
		return nearest, nearestDistance;
	end;
	BFFindStoredEnemyLike = function(names)
		local needles = BFNameNeedles(names);
		local singleNeedle = type(needles) == "string";
		for _, enemy in ipairs(Q:GetChildren()) do
			if enemy:IsA("Model") and enemy:FindFirstChildOfClass("Humanoid") then
				local enemyName = string.lower(enemy.Name);
				if singleNeedle then
					if string.find(enemyName, needles, 1, true) then
						return enemy;
					end;
				else
					for _, needle in ipairs(needles) do
						if string.find(enemyName, needle, 1, true) then
							return enemy;
						end;
					end;
				end;
			end;
		end;
	end;
BFMoveNear = function(target, tolerance)
		local targetCFrame = target;
		if typeof(target) == "Instance" then
			local part = BFFirstPart(target);
			targetCFrame = part and part.CFrame or nil;
		elseif typeof(target) == "Vector3" then
			targetCFrame = CFrame.new(target);
		end;
		local character = d.Character;
		local root = character and character:FindFirstChild("HumanoidRootPart");
		if typeof(targetCFrame) ~= "CFrame" or not root then
			return false;
		end;
		if (targetCFrame.Position - root.Position).Magnitude <= (tonumber(tolerance) or 8) then
			return true;
		end;
		_tp(targetCFrame);
		return false;
	end;
BFHumanoid = function()
		local character = d.Character;
		return character and character:FindFirstChildOfClass("Humanoid");
	end;
BFDataValue = function(name)
		local data = d:FindFirstChild("Data");
		local value = data and data:FindFirstChild(name);
		return value and value.Value or nil;
	end;
UI.InfiniteAbilityState = {};
function UI.RestoreInfiniteObservation()
	local state = UI.InfiniteAbilityState;
	if state.Observation and state.Observation.Parent and state.ObservationValue ~= nil then
		state.Observation.Value = state.ObservationValue;
	end;
	state.Observation = nil;
	state.ObservationValue = nil;
end;
function UI.RestoreInfiniteAgility()
	local state = UI.InfiniteAbilityState;
	if state.Agility and state.Agility.Parent then
		state.Agility:Destroy();
	end;
	state.Agility = nil;
end;
function UI.RestoreInfiniteAbilities()
	UI.RestoreInfiniteObservation();
	UI.RestoreInfiniteAgility();
	UI.InfiniteAbilityState.Energy = nil;
	UI.InfiniteAbilityState.EnergyValue = nil;
	UI.InfiniteAbilityState.Soru = nil;
	UI.InfiniteAbilityState.SoruTables = nil;
end;
getInfinity_Ability = function(Y, Q)
		if not Q then
			return;
		end;
		local state = UI.InfiniteAbilityState;
		if Y == "Soru" then
			local character = d.Character;
			local soru = character and character:FindFirstChild("Soru");
			if not soru or type(getgc) ~= "function" or type(getfenv) ~= "function" or type(getupvalues) ~= "function" then
				return;
			end;
			if state.Soru ~= soru then
				state.Soru = soru;
				state.SoruTables = setmetatable({}, { __mode = "k" });
				for _, candidate in next, getgc() do
					if typeof(candidate) == "function" then
						local ok, environment = pcall(getfenv, candidate);
						if ok and environment and environment.script == soru then
							local gotUpvalues, upvalues = pcall(getupvalues, candidate);
							if gotUpvalues and type(upvalues) == "table" then
								for _, upvalue in next, upvalues do
									if type(upvalue) == "table" and rawget(upvalue, "LastUse") ~= nil then
										state.SoruTables[upvalue] = true;
									end;
								end;
							end;
						end;
					end;
				end;
			end;
			for upvalue in pairs(state.SoruTables or {}) do
				upvalue.LastUse = 0;
			end;
		elseif Y == "Energy" then
			local character = d.Character;
			local energy = character and character:FindFirstChild("Energy");
			if not energy then
				return;
			end;
			if state.Energy ~= energy then
				state.Energy = energy;
				state.EnergyValue = energy.Value;
			end;
			energy.Value = state.EnergyValue;
		elseif Y == "Observation" then
			local radius = d:FindFirstChild("VisionRadius");
			if not radius then
				return;
			end;
			if state.Observation ~= radius then
				UI.RestoreInfiniteObservation();
				state.Observation = radius;
				state.ObservationValue = radius.Value;
			end;
			radius.Value = math.huge;
		end;
	end;
Hop = function()
		local browser = Q:FindFirstChild("__ServerBrowser");
		if not browser then
			return;
		end;
		pcall(function()
			for Y = math.random(1, math.random(40, 75)), 100, 1 do
				local servers = browser:InvokeServer(Y);
				if type(servers) == "table" then
					for jobId, server in next, servers do
						if type(server) == "table" and tonumber(server.Count) and tonumber(server.Count) < 12 then
							a:TeleportToPlaceInstance(game.PlaceId, jobId, d);
							return;
						end;
					end;
				end;
			end;
		end);
	end;
BFSetTweenSupport = function(root, enabled)
	if enabled and root then
		BFMove.SupportRoot = root;
		if type(UI.SetCharacterCollisionOwner) == "function" then
			UI.SetCharacterCollisionOwner("Tween", true);
		end;
		local body = root:FindFirstChild("BFTweenBodyClip");
		if not body then
			body = Instance.new("BodyVelocity");
			body.Name = "BFTweenBodyClip";
			body.MaxForce = Vector3.new(100000, 100000, 100000);
			body.Velocity = Vector3.new(0, 0, 0);
			body.Parent = root;
		end;
		BFMove.SupportBody = body;
		return;
	end;
	if type(UI.SetCharacterCollisionOwner) == "function" then
		UI.SetCharacterCollisionOwner("Tween", false);
	end;
	local body = BFMove.SupportBody;
	if body and body.Parent then
		body:Destroy();
	end;
	BFMove.SupportRoot = nil;
	BFMove.SupportBody = nil;
end;
BFCancelTween = function()
		if BFMove.Connection then
			BFMove.Connection:Disconnect();
			BFMove.Connection = nil;
		end;
		if BFMove.Tween and BFMove.Tween.PlaybackState == Enum.PlaybackState.Playing then
			pcall(BFMove.Tween.Cancel, BFMove.Tween);
		end;
		BFMove.Tween = nil;
		BFMove.Target = nil;
		BFMove.Root = nil;
		BFMove.ForceTween = false;
		BFSetTweenSupport(nil, false);
	end;
BFResetTeleportStop = function()
	BFMove.ResetToken = BFMove.ResetToken + 1;
	BFMove.ResetBusy = false;
	BFMove.ResetUsed = false;
	BFMove.ResetNextAt = 0;
end;
BFResetTeleport = function(target)
	if typeof(target) ~= "CFrame" or UI.Stopped or BFMove.ResetBusy or BFMove.ResetUsed or os.clock() < BFMove.ResetNextAt then
		return false;
	end;
	local character = d.Character;
	local humanoid = character and character:FindFirstChildOfClass("Humanoid");
	if not humanoid or humanoid.Health <= 0 then
		return false;
	end;
	BFMove.ResetBusy = true;
	BFMove.ResetUsed = true;
	BFMove.ResetToken = BFMove.ResetToken + 1;
	local token = BFMove.ResetToken;
	BFCancelTween();
	pcall(function()
		humanoid.Health = 0;
		humanoid:ChangeState(Enum.HumanoidStateType.Dead);
	end);
	local deadline = os.clock() + 8;
	while not UI.Stopped and _G.Bypass and token == BFMove.ResetToken and os.clock() < deadline do
		local nextCharacter = d.Character;
		local nextHumanoid = nextCharacter and nextCharacter:FindFirstChildOfClass("Humanoid");
		local nextRoot = nextCharacter and nextCharacter:FindFirstChild("HumanoidRootPart");
		if nextCharacter ~= character and nextHumanoid and nextHumanoid.Health > 0 and nextRoot then
			if nextRoot.Anchored then
				nextRoot.Anchored = false;
			end;
			nextRoot.CFrame = target;
			BFMove.ResetBusy = false;
			BFMove.ResetNextAt = os.clock() + 1;
			return true;
		end;
		task.wait(.1);
	end;
	if token == BFMove.ResetToken then
		BFMove.ResetBusy = false;
		BFMove.ResetUsed = false;
		BFMove.ResetNextAt = os.clock() + 2;
	end;
	return false;
end;
_tp = function(I, forceTween)
		if typeof(I) ~= "CFrame" then
			return;
		end;
		local character = plr.Character;
		local root = character and character:FindFirstChild("HumanoidRootPart");
		if not root then
			return;
		end;
		shouldTween = true;
		if root.Anchored then
			root.Anchored = false;
			task.wait();
		end;
		local distance = (I.Position - root.Position).Magnitude;
		if distance <= 3 then
			if BFMove.Root == root then
				BFCancelTween();
			end;
			root.CFrame = I;
			return;
		end;
		if _G.Bypass and not forceTween then
			if type(BFSmartTeleport) == "function" and BFSmartTeleport(I, root) then
				return;
			end;
			if distance > 700 and getgenv().BFResetOnBypass ~= false and BFResetTeleport(I) then
				return;
			end;
			character = plr.Character;
			root = character and character:FindFirstChild("HumanoidRootPart");
			if not root then
				return;
			end;
			BFCancelTween();
			root.CFrame = I;
			return;
		end;
		if BFMove.Tween and BFMove.Root == root and BFMove.Tween.PlaybackState == Enum.PlaybackState.Playing and BFMove.Target and (BFMove.Target.Position - I.Position).Magnitude <= 6 then
			BFMove.ForceTween = BFMove.ForceTween or forceTween == true;
			return BFMove.Tween;
		end;
		BFCancelTween();
		local speed = distance <= 90 and (getgenv().TweenSpeedNear or 200) or (getgenv().TweenSpeedFar or 200);
		speed = tonumber(speed) or 200;
		if speed <= 0 then
			speed = 200;
		end;
		local humanoid = character:FindFirstChildOfClass("Humanoid");
		if humanoid and humanoid.Sit then
			root.CFrame = CFrame.new(root.Position.X, I.Y, root.Position.Z);
		end;
		local tween = w:Create(root, TweenInfo.new(distance / speed, Enum.EasingStyle.Linear), { CFrame = I });
		BFMove.Tween = tween;
		BFMove.Target = I;
		BFMove.Root = root;
		BFMove.ForceTween = forceTween == true;
		BFSetTweenSupport(root, true);
		BFMove.Connection = tween.Completed:Connect(function()
			if BFMove.Tween == tween then
				if BFMove.Connection then
					BFMove.Connection:Disconnect();
				end;
				BFMove.Tween = nil;
				BFMove.Target = nil;
				BFMove.Root = nil;
				BFMove.Connection = nil;
				BFMove.ForceTween = false;
				BFSetTweenSupport(nil, false);
			end;
		end);
		tween:Play();
		return tween;
	end;
getgenv().BFTweenTo = _tp;

TeleportToTarget = function(I)
_tp(I)
end;

notween = function(I)
if typeof(I) ~= "CFrame" then
return;
end;
local character = plr.Character;
local HRP = character and character:FindFirstChild("HumanoidRootPart");
if HRP then
HRP.CFrame = I;
end;
end;

function TeleportConditional(hrp, targetCFrame, threshold)
	if not hrp or not targetCFrame then return end

	local dist = (targetCFrame.Position - hrp.Position).Magnitude
	if dist > threshold then
		_tp(targetCFrame)
	end
end;

UI.CharacterCollisionOwners = {};
UI.CharacterCollisionOriginal = setmetatable({}, { __mode = "k" });
function UI.RestoreCharacterCollisions()
	if next(UI.CharacterCollisionOwners) ~= nil then
		return;
	end;
	UI.CharacterCollisionApplied = nil;
	if UI.CharacterCollisionHook then
		UI.CharacterCollisionHook:Disconnect();
		UI.CharacterCollisionHook = nil;
	end;
	for part, original in pairs(UI.CharacterCollisionOriginal) do
		if part.Parent then
			part.CanCollide = original == 1;
		end;
		UI.CharacterCollisionOriginal[part] = nil;
	end;
end;
UI.CharacterCollisionApplied = nil;
function UI.SetCharacterCollisionOwner(owner, enabled)
	if enabled then
		UI.CharacterCollisionOwners[owner] = true;
	else
		UI.CharacterCollisionOwners[owner] = nil;
	end;
	if next(UI.CharacterCollisionOwners) == nil then
		UI.CharacterCollisionApplied = nil;
		UI.RestoreCharacterCollisions();
		return;
	end;
	local character = d.Character;
	if not character then
		UI.CharacterCollisionApplied = nil;
		return;
	end;
	-- This used to walk every character descendant on each call, and the movement
	-- watcher calls it ten times a second. Re-apply only when the character
	-- actually changed, and let the descendant hook cover parts added later.
	if UI.CharacterCollisionApplied == character then
		return;
	end;
	UI.CharacterCollisionApplied = character;
	UI.CharacterCollisionParts = {};
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			if UI.CharacterCollisionOriginal[part] == nil then
				UI.CharacterCollisionOriginal[part] = part.CanCollide and 1 or 0;
			end;
			part.CanCollide = false;
			table.insert(UI.CharacterCollisionParts, part);
		end;
	end;
	if UI.CharacterCollisionHook then
		UI.CharacterCollisionHook:Disconnect();
	end;
	UI.CharacterCollisionHook = character.DescendantAdded:Connect(function(part)
		if not part:IsA("BasePart") then
			return;
		end;
		if next(UI.CharacterCollisionOwners) == nil then
			return;
		end;
		if UI.CharacterCollisionOriginal[part] == nil then
			UI.CharacterCollisionOriginal[part] = part.CanCollide and 1 or 0;
		end;
		part.CanCollide = false;
		table.insert(UI.CharacterCollisionParts, part);
	end);
end;
-- Cheap per-tick re-assert for noclip: the game re-enables CanCollide on some
-- state changes, and walking GetDescendants five times a second to catch that was
-- the single most expensive thing the hub did.
function UI.ReassertCharacterCollisions()
	if next(UI.CharacterCollisionOwners) == nil then
		return;
	end;
	local parts = UI.CharacterCollisionParts;
	if type(parts) ~= "table" then
		return;
	end;
	for index = #parts, 1, -1 do
		local part = parts[index];
		if not part or not part.Parent then
			table.remove(parts, index);
		elseif part.CanCollide then
			part.CanCollide = false;
		end;
	end;
end;
function UI.ClearCharacterCollisionOwners()
	for owner in pairs(UI.CharacterCollisionOwners) do
		UI.CharacterCollisionOwners[owner] = nil;
	end;
	UI.RestoreCharacterCollisions();
end;

-- Movement flags used to be one 140-term `or` chain evaluated ten times a second.
-- Same semantics, but table-driven so it is readable and stops at the first hit.
local BFMovementFlags = {
	"SailBoat_Hydra", "WardenBoss", "AutoFactory", "HighestMirage", "HCM", "PGB", "Leviathan1", "UPGDrago",
	"Complete_Trials", "TpDrago_Prehis", "BuyDrago", "AutoFireFlowers", "DT_Uzoth", "AutoBerry",
	"Prehis_Find", "Prehis_Skills", "Prehis_DB", "Prehis_DE", "FarmBlazeEM", "Dojoo", "CollectPresent",
	"AutoLawKak", "TpLab", "AutoPhoenixF", "AutoFarmChest", "AutoHytHallow", "LongsWord", "BlackSpikey",
	"AutoHolyTorch", "TrainDrago", "AutoSaber", "FarmMastery_Dev", "CitizenQuest", "AutoEctoplasm", "KeysRen",
	"Auto_Rainbow_Haki", "obsFarm", "AutoBigmom", "Doughv2", "AuraBoss", "Raiding", "Auto_Cavender", "TpPly",
	"Bartilo_Quest", "Level", "FarmEliteHunt", "AutoZou", "AutoFarm_Bone", "AutoMaterial", "CraftVM",
	"FrozenTP", "TPDoor", "AcientOne", "AutoFarmNear", "AutoRaidCastle", "DarkBladev3", "AutoFarmRaid",
	"Auto_Cake_Prince", "Addealer", "TPNpc", "TwinHook", "FindMirage", "FarmChestM", "Shark", "TerrorShark",
	"Piranha", "MobCrew", "SeaBeast1", "FishBoat", "AutoPole", "AutoPoleV2", "Auto_SuperHuman",
	"AutoDeathStep", "Auto_SharkMan_Karate", "Auto_Electric_Claw", "AutoDragonTalon", "Auto_Def_DarkCoat",
	"Auto_God_Human", "Auto_Tushita", "AutoMatSoul", "AutoKenVTWO", "AutoSerpentBow", "AutoFMon",
	"Auto_Soul_Guitar", "TPGEAR", "AutoSaw", "AutoTridentW2", "Auto_StartRaid", "AutoEvoRace",
	"AutoGetQuestBounty", "MarinesCoat", "TravelDres", "Defeating", "DummyMan", "Auto_Yama", "Auto_SwanGG",
	"SwanCoat", "AutoEcBoss", "Auto_Mink", "Auto_Human", "Auto_Skypiea", "Auto_Fish", "CDK_TS", "CDK_YM",
	"CDK", "AutoFarmGodChalice", "AutoFistDarkness", "AutoMiror", "Teleport", "AutoKilo", "AutoGetUsoap",
	"Praying", "TryLucky", "AutoColShad", "AutoUnHaki", "Auto_DonAcces", "AutoRipIngay", "DragoV3", "DragoV1",
	"SailBoats", "FarmGodChalice", "IceBossRen", "Lvthan", "beasthunter", "DangerLV", "Relic123",
	"tweenKitsune", "Collect_Ember", "AutofindKitIs", "snaguine", "TwFruits", "tweenKitShrine", "Tp_LgS",
	"Tp_MasterA", "tweenShrine", "FarmMastery_G", "FarmMastery_S"
};
local BFMovementBareFlags = {
	"NextIs", "senth", "senth2"
};
local function BFMovementActive()
	for _, name in ipairs(BFMovementFlags) do
		if _G[name] then
			return true;
		end;
	end;
	for _, name in ipairs(BFMovementBareFlags) do
		if getfenv()[name] then
			return true;
		end;
	end;
	return false;
end;
function UI.ClearMovementBodyClip(character)
	character = character or d.Character;
	local root = character and character:FindFirstChild("HumanoidRootPart");
	local clip = root and root:FindFirstChild("BodyClip");
	if clip then
		clip:Destroy();
	end;
	local highlight = character and character:FindFirstChild("highlight");
	if highlight then
		highlight:Destroy();
	end;
end;
-- A stranded BodyClip (zero-velocity BodyVelocity with 100k force) is what left
-- the character frozen mid-air. Drop it on death and on every respawn so it can
-- never outlive the farm loop that created it.
task.spawn(function()
	local function watch(character)
		if not character then
			return;
		end;
		local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 10);
		if humanoid then
			humanoid.Died:Connect(function()
				UI.ClearMovementBodyClip(character);
			end);
		end;
	end;
	watch(d.Character);
	d.CharacterAdded:Connect(function(character)
		UI.CharacterCollisionApplied = nil;
		watch(character);
	end);
	d.CharacterRemoving:Connect(function(character)
		UI.ClearMovementBodyClip(character);
	end);
end);

task.spawn(function()
	while not UI.Stopped and task.wait(.1) do
		pcall(function()
			local character = d.Character;
			local root = character and character:FindFirstChild("HumanoidRootPart");
			if not character or not root then
				shouldTween = false;
				BFCancelTween();
				return;
			end;
			local movementActive = BFMovementActive();
			UI.SetCharacterCollisionOwner("Movement", movementActive);
			if movementActive then
				shouldTween = true;
				if not root:FindFirstChild("BodyClip") then
					local clip = Instance.new("BodyVelocity");
					clip.Name = "BodyClip";
					clip.MaxForce = Vector3.new(100000, 100000, 100000);
					clip.Velocity = Vector3.new(0, 0, 0);
					clip.Parent = root;
				end;
				-- `character` is the value we already null-checked. The old code read
				-- d.Character again here, and when the character despawned between the
				-- two reads it threw, skipping the cleanup branch below and leaving the
				-- BodyClip attached: the air-stuck bug.
				if not character:FindFirstChild("highlight") then
					local highlight = Instance.new("Highlight");
					highlight.Name = "highlight";
					highlight.Enabled = true;
					highlight.FillColor = Color3.fromRGB(255, 255, 255);
					highlight.OutlineColor = Color3.fromRGB(255, 255, 255);
					highlight.FillTransparency = .5;
					highlight.OutlineTransparency = .2;
					highlight.Parent = character;
				end;
			else
				shouldTween = BFMove.Tween ~= nil;
				if BFMove.Tween and not BFMove.ForceTween then
					BFCancelTween();
				end;
				UI.ClearMovementBodyClip(character);
			end;
		end);
	end;
end);

MaterialMon = function(selectedMaterial)
		local Y = game.Players.LocalPlayer;
		local d = Y.Character and Y.Character:FindFirstChild("HumanoidRootPart");
		if not d then
			return;
		end;
		shouldRequestEntrance = function(Y, R)
				local r = (d.Position - Y).Magnitude;
				if r >= R then
					BFComm("requestEntrance", Y);
				end;
			end;
		if World1 then
			if selectedMaterial == "Angel Wings" then
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
			elseif selectedMaterial == "Leather + Scrap Metal" then
				MMon = { "Brute", "Pirate" };
				MPos = CFrame.new(-1145, 15, 4350);
				SP = "Default";
			elseif selectedMaterial == "Magma Ore" then
				MMon = { "Military Soldier", "Military Spy", "Magma Admiral" };
				MPos = CFrame.new(-5815, 84, 8820);
				SP = "Default";
			elseif selectedMaterial == "Fish Tail" then
				MMon = { "Fishman Warrior", "Fishman Commando", "Fishman Lord" };
				MPos = CFrame.new(61123, 19, 1569);
				SP = "Default";
				local Y = Vector3.new(61163.8515625, 5.342342376709, 1819.7841796875);
				shouldRequestEntrance(Y, 17000);
			end;
		elseif World2 then
			if selectedMaterial == "Leather + Scrap Metal" then
				MMon = { "Marine Captain" };
				MPos = CFrame.new(-2010.5059814453, 73.001159667969, -3326.6208496094);
				SP = "Default";
			elseif selectedMaterial == "Magma Ore" then
				MMon = { "Magma Ninja", "Lava Pirate" };
				MPos = CFrame.new(-5428, 78, -5959);
				SP = "Default";
			elseif selectedMaterial == "Ectoplasm" then
				MMon = {
						"Ship Deckhand",
						"Ship Engineer",
						"Ship Steward",
						"Ship Officer",
					};
				MPos = CFrame.new(911.35827636719, 125.95812988281, 33159.5390625);
				SP = "Default";
				local Y = Vector3.new(923.21252441406, 126.9760055542, 32852.83203125);
				shouldRequestEntrance(Y, 18000);
			elseif selectedMaterial == "Mystic Droplet" then
				MMon = { "Water Fighter" };
				MPos = CFrame.new(-3385, 239, -10542);
				SP = "Default";
			elseif selectedMaterial == "Radioactive Material" then
				MMon = { "Factory Staff" };
				MPos = CFrame.new(295, 73, -56);
				SP = "Default";
			elseif selectedMaterial == "Vampire Fang" then
				MMon = { "Vampire" };
				MPos = CFrame.new(-6033, 7, -1317);
				SP = "Default";
			end;
		elseif World3 then
			if selectedMaterial == "Scrap Metal" then
				MMon = { "Jungle Pirate", "Forest Pirate" };
				MPos = CFrame.new(-11975.78515625, 331.77340698242, -10620.030273438);
				SP = "Default";
			elseif selectedMaterial == "Fish Tail" then
				MMon = { "Fishman Raider", "Fishman Captain" };
				MPos = CFrame.new(-10993, 332, -8940);
				SP = "Default";
			elseif selectedMaterial == "Conjured Cocoa" then
				MMon = { "Chocolate Bar Battler", "Cocoa Warrior" };
				MPos = CFrame.new(620.63446044922, 78.936447143555, -12581.369140625);
				SP = "Default";
			elseif selectedMaterial == "Dragon Scale" then
				MMon = { "Dragon Crew Archer", "Dragon Crew Warrior" };
				MPos = CFrame.new(6594, 383, 139);
				SP = "Default";
			elseif selectedMaterial == "Gunpowder" then
				MMon = { "Pistol Billionaire" };
				MPos = CFrame.new(-84.855690002441, 85.620613098145, 6132.0087890625);
				SP = "Default";
			elseif selectedMaterial == "Mini Tusk" then
				MMon = { "Mythological Pirate" };
				MPos = CFrame.new(-13545, 470, -6917);
				SP = "Default";
			elseif selectedMaterial == "Demonic Wisp" then
				MMon = { "Demonic Soul" };
				MPos = CFrame.new(-9495.6806640625, 453.58624267578, 5977.3486328125);
				SP = "Default";
			end;
		end;
	end;
function CheckQuest()
	local selfCharacter = d.Character;
	local selfRoot = selfCharacter and selfCharacter:FindFirstChild("HumanoidRootPart");
	if not selfRoot then
		return;
	end;
	local playerData = d:FindFirstChild("Data");
	local levelValue = playerData and playerData:FindFirstChild("Level");
	if not levelValue then
		return;
	end;
	MyLevel = levelValue.Value;
	if World1 then
		if MyLevel >= 1 and MyLevel <= 9 then
			Mon = "Bandit";
			LevelQuest = 1;
			NameQuest = "BanditQuest1";
			NameMon = "Bandit";
			CFrameQuest = CFrame.new(1059.37195, 15.4495068, 1550.4231, .939700544, 0, -0.341998369, 0, 1, 0, .341998369, 0, .939700544);
			CFrameMon = CFrame.new(1045.9626464844, 27.002508163452, 1560.8203125);
		elseif MyLevel >= 10 and MyLevel <= 14 then
			Mon = "Monkey";
			LevelQuest = 1;
			NameQuest = "JungleQuest";
			NameMon = "Monkey";
			CFrameQuest = CFrame.new(-1598.08911, 35.5501175, 153.377838, 0, 0, 1, 0, 1, 0, -1, 0, 0);
			CFrameMon = CFrame.new(-1448.5180664062, 67.853012084961, 11.465796470642);
		elseif MyLevel >= 15 and MyLevel <= 29 then
			Mon = "Gorilla";
			LevelQuest = 2;
			NameQuest = "JungleQuest";
			NameMon = "Gorilla";
			CFrameQuest = CFrame.new(-1598.08911, 35.5501175, 153.377838, 0, 0, 1, 0, 1, 0, -1, 0, 0);
			CFrameMon = CFrame.new(-1129.8836669922, 40.46354675293, -525.42370605469);
		elseif MyLevel >= 30 and MyLevel <= 39 then
			Mon = "Pirate";
			LevelQuest = 1;
			NameQuest = "BuggyQuest1";
			NameMon = "Pirate";
			CFrameQuest = CFrame.new(-1141.07483, 4.10001802, 3831.5498, .965929627, 0, -0.258804798, 0, 1, 0, .258804798, 0, .965929627);
			CFrameMon = CFrame.new(-1103.5134277344, 13.752052307129, 3896.0910644531);
		elseif MyLevel >= 40 and MyLevel <= 59 then
			Mon = "Brute";
			LevelQuest = 2;
			NameQuest = "BuggyQuest1";
			NameMon = "Brute";
			CFrameQuest = CFrame.new(-1141.07483, 4.10001802, 3831.5498, .965929627, 0, -0.258804798, 0, 1, 0, .258804798, 0, .965929627);
			CFrameMon = CFrame.new(-1140.0837402344, 14.809885025024, 4322.9213867188);
		elseif MyLevel >= 60 and MyLevel <= 74 then
			Mon = "Desert Bandit";
			LevelQuest = 1;
			NameQuest = "DesertQuest";
			NameMon = "Desert Bandit";
			CFrameQuest = CFrame.new(894.488647, 5.14000702, 4392.43359, .819155693, 0, -0.573571265, 0, 1, 0, .573571265, 0, .819155693);
			CFrameMon = CFrame.new(924.7998046875, 6.4486746788025, 4481.5859375);
		elseif MyLevel >= 75 and MyLevel <= 89 then
			Mon = "Desert Officer";
			LevelQuest = 2;
			NameQuest = "DesertQuest";
			NameMon = "Desert Officer";
			CFrameQuest = CFrame.new(894.488647, 5.14000702, 4392.43359, .819155693, 0, -0.573571265, 0, 1, 0, .573571265, 0, .819155693);
			CFrameMon = CFrame.new(1608.2822265625, 8.6142244338989, 4371.0073242188);
		elseif MyLevel >= 90 and MyLevel <= 99 then
			Mon = "Snow Bandit";
			LevelQuest = 1;
			NameQuest = "SnowQuest";
			NameMon = "Snow Bandit";
			CFrameQuest = CFrame.new(1389.74451, 88.1519318, -1298.90796, -0.342042685, 0, .939684391, 0, 1, 0, -0.939684391, 0, -0.342042685);
			CFrameMon = CFrame.new(1354.3479003906, 87.272773742676, -1393.9465332031);
		elseif MyLevel >= 100 and MyLevel <= 119 then
			Mon = "Snowman";
			LevelQuest = 2;
			NameQuest = "SnowQuest";
			NameMon = "Snowman";
			CFrameQuest = CFrame.new(1389.74451, 88.1519318, -1298.90796, -0.342042685, 0, .939684391, 0, 1, 0, -0.939684391, 0, -0.342042685);
			CFrameMon = CFrame.new(1201.6412353516, 144.57958984375, -1550.0670166016);
		elseif MyLevel >= 120 and MyLevel <= 149 then
			Mon = "Chief Petty Officer";
			LevelQuest = 1;
			NameQuest = "MarineQuest2";
			NameMon = "Chief Petty Officer";
			CFrameQuest = CFrame.new(-5039.58643, 27.3500385, 4324.68018, 0, 0, -1, 0, 1, 0, 1, 0, 0);
			CFrameMon = CFrame.new(-4881.2309570312, 22.652044296265, 4273.7524414062);
		elseif MyLevel >= 150 and MyLevel <= 174 then
			Mon = "Sky Bandit";
			LevelQuest = 1;
			NameQuest = "SkyQuest";
			NameMon = "Sky Bandit";
			CFrameQuest = CFrame.new(-4839.53027, 716.368591, -2619.44165, .866007268, 0, .500031412, 0, 1, 0, -0.500031412, 0, .866007268);
			CFrameMon = CFrame.new(-4953.20703125, 295.74420166016, -2899.2290039062);
		elseif MyLevel >= 175 and MyLevel <= 189 then
			Mon = "Dark Master";
			LevelQuest = 2;
			NameQuest = "SkyQuest";
			NameMon = "Dark Master";
			CFrameQuest = CFrame.new(-4839.53027, 716.368591, -2619.44165, .866007268, 0, .500031412, 0, 1, 0, -0.500031412, 0, .866007268);
			CFrameMon = CFrame.new(-5259.8447265625, 391.39767456055, -2229.0354003906);
		elseif MyLevel >= 190 and MyLevel <= 209 then
			Mon = "Prisoner";
			LevelQuest = 1;
			NameQuest = "PrisonerQuest";
			NameMon = "Prisoner";
			CFrameQuest = CFrame.new(5308.93115, 1.65517521, 475.120514, -0.0894274712, -5.00292918e-09, -0.995993316, 1.60817859e-09, 1, -5.16744869e-09, .995993316, -2.06384709e-09, -0.0894274712);
			CFrameMon = CFrame.new(5098.9736328125, -0.3204058110714, 474.23733520508);
		elseif MyLevel >= 210 and MyLevel <= 249 then
			Mon = "Dangerous Prisoner";
			LevelQuest = 2;
			NameQuest = "PrisonerQuest";
			NameMon = "Dangerous Prisoner";
			CFrameQuest = CFrame.new(5308.93115, 1.65517521, 475.120514, -0.0894274712, -5.00292918e-09, -0.995993316, 1.60817859e-09, 1, -5.16744869e-09, .995993316, -2.06384709e-09, -0.0894274712);
			CFrameMon = CFrame.new(5654.5634765625, 15.633401870728, 866.29919433594);
		elseif MyLevel >= 250 and MyLevel <= 274 then
			Mon = "Toga Warrior";
			LevelQuest = 1;
			NameQuest = "ColosseumQuest";
			NameMon = "Toga Warrior";
			CFrameQuest = CFrame.new(-1580.04663, 6.35000277, -2986.47534, -0.515037298, 0, -0.857167721, 0, 1, 0, .857167721, 0, -0.515037298);
			CFrameMon = CFrame.new(-1820.21484375, 51.683856964111, -2740.6650390625);
		elseif MyLevel >= 275 and MyLevel <= 299 then
			Mon = "Gladiator";
			LevelQuest = 2;
			NameQuest = "ColosseumQuest";
			NameMon = "Gladiator";
			CFrameQuest = CFrame.new(-1580.04663, 6.35000277, -2986.47534, -0.515037298, 0, -0.857167721, 0, 1, 0, .857167721, 0, -0.515037298);
			CFrameMon = CFrame.new(-1292.8381347656, 56.380882263184, -3339.0314941406);
		elseif MyLevel >= 300 and MyLevel <= 324 then
			Mon = "Military Soldier";
			LevelQuest = 1;
			NameQuest = "MagmaQuest";
			NameMon = "Military Soldier";
			CFrameQuest = CFrame.new(-5313.37012, 10.9500084, 8515.29395, -0.499959469, 0, .866048813, 0, 1, 0, -0.866048813, 0, -0.499959469);
			CFrameMon = CFrame.new(-5411.1645507812, 11.081554412842, 8454.29296875);
		elseif MyLevel >= 325 and MyLevel <= 374 then
			Mon = "Military Spy";
			LevelQuest = 2;
			NameQuest = "MagmaQuest";
			NameMon = "Military Spy";
			CFrameQuest = CFrame.new(-5313.37012, 10.9500084, 8515.29395, -0.499959469, 0, .866048813, 0, 1, 0, -0.866048813, 0, -0.499959469);
			CFrameMon = CFrame.new(-5802.8681640625, 86.262413024902, 8828.859375);
		elseif MyLevel >= 375 and MyLevel <= 399 then
			Mon = "Fishman Warrior";
			LevelQuest = 1;
			NameQuest = "FishmanQuest";
			NameMon = "Fishman Warrior";
			CFrameQuest = CFrame.new(61122.65234375, 18.497442245483, 1569.3997802734);
			CFrameMon = CFrame.new(60878.30078125, 18.482830047607, 1543.7574462891);
			if (getgenv()).AutoFarm and (CFrameQuest.Position - selfRoot.Position).Magnitude > 10000 then
				BFComm("requestEntrance", Vector3.new(61163.8515625, 11.6796875, 1819.7841796875));
			end;
		elseif MyLevel >= 400 and MyLevel <= 449 then
			Mon = "Fishman Commando";
			LevelQuest = 2;
			NameQuest = "FishmanQuest";
			NameMon = "Fishman Commando";
			CFrameQuest = CFrame.new(61122.65234375, 18.497442245483, 1569.3997802734);
			CFrameMon = CFrame.new(61922.6328125, 18.482830047607, 1493.9343261719);
			if (getgenv()).AutoFarm and (CFrameQuest.Position - selfRoot.Position).Magnitude > 10000 then
				BFComm("requestEntrance", Vector3.new(61163.8515625, 11.6796875, 1819.7841796875));
			end;
		elseif MyLevel >= 450 and MyLevel <= 474 then
			Mon = "God\'s Guard";
			LevelQuest = 1;
			NameQuest = "SkyExp1Quest";
			NameMon = "God\'s Guard";
			CFrameQuest = CFrame.new(-4721.88867, 843.874695, -1949.96643, .996191859, 0, -0.0871884301, 0, 1, 0, .0871884301, 0, .996191859);
			CFrameMon = CFrame.new(-4710.04296875, 845.27697753906, -1927.3079833984);
			if (getgenv()).AutoFarm and (CFrameQuest.Position - selfRoot.Position).Magnitude > 10000 then
				BFComm("requestEntrance", Vector3.new(-4607.82275, 872.54248, -1667.55688));
			end;
		elseif MyLevel >= 475 and MyLevel <= 524 then
			Mon = "Shanda";
			LevelQuest = 2;
			NameQuest = "SkyExp1Quest";
			NameMon = "Shanda";
			CFrameQuest = CFrame.new(-7859.09814, 5544.19043, -381.476196, -0.422592998, 0, .906319618, 0, 1, 0, -0.906319618, 0, -0.422592998);
			CFrameMon = CFrame.new(-7678.4897460938, 5566.4038085938, -497.21560668945);
			if (getgenv()).AutoFarm and (CFrameQuest.Position - selfRoot.Position).Magnitude > 10000 then
				BFComm("requestEntrance", Vector3.new(-7894.6176757813, 5547.1416015625, -380.29119873047));
			end;
		elseif MyLevel >= 525 and MyLevel <= 549 then
			Mon = "Royal Squad";
			LevelQuest = 1;
			NameQuest = "SkyExp2Quest";
			NameMon = "Royal Squad";
			CFrameQuest = CFrame.new(-7906.81592, 5634.6626, -1411.99194, 0, 0, -1, 0, 1, 0, 1, 0, 0);
			CFrameMon = CFrame.new(-7624.2524414062, 5658.1333007812, -1467.3542480469);
		elseif MyLevel >= 550 and MyLevel <= 624 then
			Mon = "Royal Soldier";
			LevelQuest = 2;
			NameQuest = "SkyExp2Quest";
			NameMon = "Royal Soldier";
			CFrameQuest = CFrame.new(-7906.81592, 5634.6626, -1411.99194, 0, 0, -1, 0, 1, 0, 1, 0, 0);
			CFrameMon = CFrame.new(-7836.7534179688, 5645.6640625, -1790.6236572266);
		elseif MyLevel >= 625 and MyLevel <= 649 then
			Mon = "Galley Pirate";
			LevelQuest = 1;
			NameQuest = "FountainQuest";
			NameMon = "Galley Pirate";
			CFrameQuest = CFrame.new(5259.81982, 37.3500175, 4050.0293, .087131381, 0, .996196866, 0, 1, 0, -0.996196866, 0, .087131381);
			CFrameMon = CFrame.new(5551.0219726562, 78.901351928711, 3930.4128417969);
		elseif MyLevel >= 650 then
			Mon = "Galley Captain";
			LevelQuest = 2;
			NameQuest = "FountainQuest";
			NameMon = "Galley Captain";
			CFrameQuest = CFrame.new(5259.81982, 37.3500175, 4050.0293, .087131381, 0, .996196866, 0, 1, 0, -0.996196866, 0, .087131381);
			CFrameMon = CFrame.new(5441.9516601562, 42.502059936523, 4950.09375);
		end;
	elseif World2 then
		if MyLevel >= 700 and MyLevel <= 724 then
			Mon = "Raider";
			LevelQuest = 1;
			NameQuest = "Area1Quest";
			NameMon = "Raider";
			CFrameQuest = CFrame.new(-429.543518, 71.7699966, 1836.18188, -0.22495985, 0, -0.974368095, 0, 1, 0, .974368095, 0, -0.22495985);
			CFrameMon = CFrame.new(-728.32672119141, 52.779319763184, 2345.7705078125);
		elseif MyLevel >= 725 and MyLevel <= 774 then
			Mon = "Mercenary";
			LevelQuest = 2;
			NameQuest = "Area1Quest";
			NameMon = "Mercenary";
			CFrameQuest = CFrame.new(-429.543518, 71.7699966, 1836.18188, -0.22495985, 0, -0.974368095, 0, 1, 0, .974368095, 0, -0.22495985);
			CFrameMon = CFrame.new(-1004.3244018555, 80.158866882324, 1424.6193847656);
		elseif MyLevel >= 775 and MyLevel <= 799 then
			Mon = "Swan Pirate";
			LevelQuest = 1;
			NameQuest = "Area2Quest";
			NameMon = "Swan Pirate";
			CFrameQuest = CFrame.new(638.43811, 71.769989, 918.282898, .139203906, 0, .99026376, 0, 1, 0, -0.99026376, 0, .139203906);
			CFrameMon = CFrame.new(1068.6643066406, 137.61428833008, 1322.1060791016);
		elseif MyLevel >= 800 and MyLevel <= 874 then
			Mon = "Factory Staff";
			NameQuest = "Area2Quest";
			LevelQuest = 2;
			NameMon = "Factory Staff";
			CFrameQuest = CFrame.new(632.698608, 73.1055908, 918.666321, -0.0319722369, 8.96074881e-10, -0.999488771, 1.36326533e-10, 1, 8.92172336e-10, .999488771, -1.07732087e-10, -0.0319722369);
			CFrameMon = CFrame.new(73.078674316406, 81.863441467285, -27.470672607422);
		elseif MyLevel >= 875 and MyLevel <= 899 then
			Mon = "Marine Lieutenant";
			LevelQuest = 1;
			NameQuest = "MarineQuest3";
			NameMon = "Marine Lieutenant";
			CFrameQuest = CFrame.new(-2440.79639, 71.7140732, -3216.06812, .866007268, 0, .500031412, 0, 1, 0, -0.500031412, 0, .866007268);
			CFrameMon = CFrame.new(-2821.3723144531, 75.897277832031, -3070.0891113281);
		elseif MyLevel >= 900 and MyLevel <= 949 then
			Mon = "Marine Captain";
			LevelQuest = 2;
			NameQuest = "MarineQuest3";
			NameMon = "Marine Captain";
			CFrameQuest = CFrame.new(-2440.79639, 71.7140732, -3216.06812, .866007268, 0, .500031412, 0, 1, 0, -0.500031412, 0, .866007268);
			CFrameMon = CFrame.new(-1861.2310791016, 80.176582336426, -3254.6975097656);
		elseif MyLevel >= 950 and MyLevel <= 974 then
			Mon = "Zombie";
			LevelQuest = 1;
			NameQuest = "ZombieQuest";
			NameMon = "Zombie";
			CFrameQuest = CFrame.new(-5497.06152, 47.5923004, -795.237061, -0.29242146, 0, -0.95628953, 0, 1, 0, .95628953, 0, -0.29242146);
			CFrameMon = CFrame.new(-5657.7768554688, 78.969734191895, -928.68701171875);
		elseif MyLevel >= 975 and MyLevel <= 999 then
			Mon = "Vampire";
			LevelQuest = 2;
			NameQuest = "ZombieQuest";
			NameMon = "Vampire";
			CFrameQuest = CFrame.new(-5497.06152, 47.5923004, -795.237061, -0.29242146, 0, -0.95628953, 0, 1, 0, .95628953, 0, -0.29242146);
			CFrameMon = CFrame.new(-6037.66796875, 32.184638977051, -1340.6597900391);
		elseif MyLevel >= 1000 and MyLevel <= 1049 then
			Mon = "Snow Trooper";
			LevelQuest = 1;
			NameQuest = "SnowMountainQuest";
			NameMon = "Snow Trooper";
			CFrameQuest = CFrame.new(609.858826, 400.119904, -5372.25928, -0.374604106, 0, .92718488, 0, 1, 0, -0.92718488, 0, -0.374604106);
			CFrameMon = CFrame.new(549.14733886719, 427.38705444336, -5563.6987304688);
		elseif MyLevel >= 1050 and MyLevel <= 1099 then
			Mon = "Winter Warrior";
			LevelQuest = 2;
			NameQuest = "SnowMountainQuest";
			NameMon = "Winter Warrior";
			CFrameQuest = CFrame.new(609.858826, 400.119904, -5372.25928, -0.374604106, 0, .92718488, 0, 1, 0, -0.92718488, 0, -0.374604106);
			CFrameMon = CFrame.new(1142.7451171875, 475.63980102539, -5199.4165039062);
		elseif MyLevel >= 1100 and MyLevel <= 1124 then
			Mon = "Lab Subordinate";
			LevelQuest = 1;
			NameQuest = "IceSideQuest";
			NameMon = "Lab Subordinate";
			CFrameQuest = CFrame.new(-6064.06885, 15.2422857, -4902.97852, .453972578, 0, -0.891015649, 0, 1, 0, .891015649, 0, .453972578);
			CFrameMon = CFrame.new(-5707.4716796875, 15.951709747314, -4513.3920898438);
		elseif MyLevel >= 1125 and MyLevel <= 1174 then
			Mon = "Horned Warrior";
			LevelQuest = 2;
			NameQuest = "IceSideQuest";
			NameMon = "Horned Warrior";
			CFrameQuest = CFrame.new(-6064.06885, 15.2422857, -4902.97852, .453972578, 0, -0.891015649, 0, 1, 0, .891015649, 0, .453972578);
			CFrameMon = CFrame.new(-6341.3666992188, 15.951770782471, -5723.162109375);
		elseif MyLevel >= 1175 and MyLevel <= 1199 then
			Mon = "Magma Ninja";
			LevelQuest = 1;
			NameQuest = "FireSideQuest";
			NameMon = "Magma Ninja";
			CFrameQuest = CFrame.new(-5428.03174, 15.0622921, -5299.43457, -0.882952213, 0, .469463557, 0, 1, 0, -0.469463557, 0, -0.882952213);
			CFrameMon = CFrame.new(-5449.6728515625, 76.658744812012, -5808.2006835938);
		elseif MyLevel >= 1200 and MyLevel <= 1249 then
			Mon = "Lava Pirate";
			LevelQuest = 2;
			NameQuest = "FireSideQuest";
			NameMon = "Lava Pirate";
			CFrameQuest = CFrame.new(-5428.03174, 15.0622921, -5299.43457, -0.882952213, 0, .469463557, 0, 1, 0, -0.469463557, 0, -0.882952213);
			CFrameMon = CFrame.new(-5213.3315429688, 49.737880706787, -4701.451171875);
		elseif MyLevel >= 1250 and MyLevel <= 1274 then
			Mon = "Ship Deckhand";
			LevelQuest = 1;
			NameQuest = "ShipQuest1";
			NameMon = "Ship Deckhand";
			CFrameQuest = CFrame.new(1037.80127, 125.092171, 32911.6016);
			CFrameMon = CFrame.new(1212.0111083984, 150.79205322266, 33059.24609375);
			if (getgenv()).AutoFarm and (CFrameQuest.Position - selfRoot.Position).Magnitude > 10000 then
				BFComm("requestEntrance", Vector3.new(923.21252441406, 126.9760055542, 32852.83203125));
			end;
		elseif MyLevel >= 1275 and MyLevel <= 1299 then
			Mon = "Ship Engineer";
			LevelQuest = 2;
			NameQuest = "ShipQuest1";
			NameMon = "Ship Engineer";
			CFrameQuest = CFrame.new(1037.80127, 125.092171, 32911.6016);
			CFrameMon = CFrame.new(919.47863769531, 43.544013977051, 32779.96875);
			if (getgenv()).AutoFarm and (CFrameQuest.Position - selfRoot.Position).Magnitude > 10000 then
				BFComm("requestEntrance", Vector3.new(923.21252441406, 126.9760055542, 32852.83203125));
			end;
		elseif MyLevel >= 1300 and MyLevel <= 1324 then
			Mon = "Ship Steward";
			LevelQuest = 1;
			NameQuest = "ShipQuest2";
			NameMon = "Ship Steward";
			CFrameQuest = CFrame.new(968.80957, 125.092171, 33244.125);
			CFrameMon = CFrame.new(919.43853759766, 129.55599975586, 33436.03515625);
			if (getgenv()).AutoFarm and (CFrameQuest.Position - selfRoot.Position).Magnitude > 10000 then
				BFComm("requestEntrance", Vector3.new(923.21252441406, 126.9760055542, 32852.83203125));
			end;
		elseif MyLevel >= 1325 and MyLevel <= 1349 then
			Mon = "Ship Officer";
			LevelQuest = 2;
			NameQuest = "ShipQuest2";
			NameMon = "Ship Officer";
			CFrameQuest = CFrame.new(968.80957, 125.092171, 33244.125);
			CFrameMon = CFrame.new(1036.0179443359, 181.4390411377, 33315.7265625);
			if (getgenv()).AutoFarm and (CFrameQuest.Position - selfRoot.Position).Magnitude > 10000 then
				BFComm("requestEntrance", Vector3.new(923.21252441406, 126.9760055542, 32852.83203125));
			end;
		elseif MyLevel >= 1350 and MyLevel <= 1374 then
			Mon = "Arctic Warrior";
			LevelQuest = 1;
			NameQuest = "FrostQuest";
			NameMon = "Arctic Warrior";
			CFrameQuest = CFrame.new(5667.6582, 26.7997818, -6486.08984, -0.933587909, 0, -0.358349502, 0, 1, 0, .358349502, 0, -0.933587909);
			CFrameMon = CFrame.new(5966.24609375, 62.970020294189, -6179.3828125);
			if (getgenv()).AutoFarm and (CFrameQuest.Position - selfRoot.Position).Magnitude > 10000 then
				BFComm("requestEntrance", Vector3.new(-6508.5581054688, 5000.0349960327, -132.83953857422));
			end;
		elseif MyLevel >= 1375 and MyLevel <= 1424 then
			Mon = "Snow Lurker";
			LevelQuest = 2;
			NameQuest = "FrostQuest";
			NameMon = "Snow Lurker";
			CFrameQuest = CFrame.new(5667.6582, 26.7997818, -6486.08984, -0.933587909, 0, -0.358349502, 0, 1, 0, .358349502, 0, -0.933587909);
			CFrameMon = CFrame.new(5407.0737304688, 69.194374084473, -6880.8803710938);
		elseif MyLevel >= 1425 and MyLevel <= 1449 then
			Mon = "Sea Soldier";
			LevelQuest = 1;
			NameQuest = "ForgottenQuest";
			NameMon = "Sea Soldier";
			CFrameQuest = CFrame.new(-3054.44458, 235.544281, -10142.8193, .990270376, 0, -0.13915664, 0, 1, 0, .13915664, 0, .990270376);
			CFrameMon = CFrame.new(-3028.2236328125, 64.674514770508, -9775.4267578125);
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
			CFrameQuest = CFrame.new(-290.074677, 42.9034653, 5581.58984, .965929627, 0, -0.258804798, 0, 1, 0, .258804798, 0, .965929627);
			CFrameMon = CFrame.new(-245.99638366699, 47.30615234375, 5584.1005859375);
		elseif MyLevel >= 1525 and MyLevel <= 1574 then
			Mon = "Pistol Billionaire";
			LevelQuest = 2;
			NameQuest = "PiratePortQuest";
			NameMon = "Pistol Billionaire";
			CFrameQuest = CFrame.new(-290.074677, 42.9034653, 5581.58984, .965929627, 0, -0.258804798, 0, 1, 0, .258804798, 0, .965929627);
			CFrameMon = CFrame.new(-187.33015441895, 86.239875793457, 6013.513671875);
		elseif MyLevel >= 1575 and MyLevel <= 1599 then
			Mon = "Dragon Crew Warrior";
			LevelQuest = 1;
			NameQuest = "DragonCrewQuest";
			NameMon = "Dragon Crew Warrior";
			CFrameQuest = CFrame.new(6738.9614257812, 127.81645965576, -713.51147460938);
			CFrameMon = CFrame.new(6920.7143554688, 56.1559715271, -942.50445556641);
		elseif MyLevel >= 1600 and MyLevel <= 1624 then
			Mon = "Dragon Crew Archer";
			NameQuest = "DragonCrewQuest";
			LevelQuest = 2;
			NameMon = "Dragon Crew Archer";
			CFrameQuest = CFrame.new(6738.9614257812, 127.81645965576, -713.51147460938);
			CFrameMon = CFrame.new(6817.9125976562, 484.80444335938, 513.41412353516);
		elseif MyLevel >= 1625 and MyLevel <= 1649 then
			Mon = "Hydra Enforcer";
			NameQuest = "VenomCrewQuest";
			LevelQuest = 1;
			NameMon = "Hydra Enforcer";
			CFrameQuest = CFrame.new(5213.8740234375, 1004.5042724609, 758.69445800781);
			CFrameMon = CFrame.new(4584.6928710938, 1002.6435546875, 705.7958984375);
		elseif MyLevel >= 1650 and MyLevel <= 1699 then
			Mon = "Venomous Assailant";
			NameQuest = "VenomCrewQuest";
			LevelQuest = 2;
			NameMon = "Venomous Assailant";
			CFrameQuest = CFrame.new(5213.8740234375, 1004.5042724609, 758.69445800781);
			CFrameMon = CFrame.new(4638.7856445312, 1078.9409179688, 881.80023193359);
		elseif MyLevel >= 1700 and MyLevel <= 1724 then
			Mon = "Marine Commodore";
			LevelQuest = 1;
			NameQuest = "MarineTreeIsland";
			NameMon = "Marine Commodore";
			CFrameQuest = CFrame.new(2180.54126, 27.8156815, -6741.5498, -0.965929747, 0, .258804798, 0, 1, 0, -0.258804798, 0, -0.965929747);
			CFrameMon = CFrame.new(2286.0078125, 73.133918762207, -7159.8090820312);
		elseif MyLevel >= 1725 and MyLevel <= 1774 then
			Mon = "Marine Rear Admiral";
			NameMon = "Marine Rear Admiral";
			NameQuest = "MarineTreeIsland";
			LevelQuest = 2;
			CFrameQuest = CFrame.new(2179.98828125, 28.731239318848, -6740.0551757813);
			CFrameMon = CFrame.new(3656.7736816406, 160.52406311035, -7001.5986328125);
		elseif MyLevel >= 1775 and MyLevel <= 1799 then
			Mon = "Fishman Raider";
			LevelQuest = 1;
			NameQuest = "DeepForestIsland3";
			NameMon = "Fishman Raider";
			CFrameQuest = CFrame.new(-10581.6563, 330.872955, -8761.18652, -0.882952213, 0, .469463557, 0, 1, 0, -0.469463557, 0, -0.882952213);
			CFrameMon = CFrame.new(-10407.526367188, 331.76263427734, -8368.5166015625);
		elseif MyLevel >= 1800 and MyLevel <= 1824 then
			Mon = "Fishman Captain";
			LevelQuest = 2;
			NameQuest = "DeepForestIsland3";
			NameMon = "Fishman Captain";
			CFrameQuest = CFrame.new(-10581.6563, 330.872955, -8761.18652, -0.882952213, 0, .469463557, 0, 1, 0, -0.469463557, 0, -0.882952213);
			CFrameMon = CFrame.new(-10994.701171875, 352.38140869141, -9002.1103515625);
		elseif MyLevel >= 1825 and MyLevel <= 1849 then
			Mon = "Forest Pirate";
			LevelQuest = 1;
			NameQuest = "DeepForestIsland";
			NameMon = "Forest Pirate";
			CFrameQuest = CFrame.new(-13234.04, 331.488495, -7625.40137, .707134247, 0, -0.707079291, 0, 1, 0, .707079291, 0, .707134247);
			CFrameMon = CFrame.new(-13274.478515625, 332.37814331055, -7769.5805664062);
		elseif MyLevel >= 1850 and MyLevel <= 1899 then
			Mon = "Mythological Pirate";
			LevelQuest = 2;
			NameQuest = "DeepForestIsland";
			NameMon = "Mythological Pirate";
			CFrameQuest = CFrame.new(-13234.04, 331.488495, -7625.40137, .707134247, 0, -0.707079291, 0, 1, 0, .707079291, 0, .707134247);
			CFrameMon = CFrame.new(-13680.607421875, 501.08154296875, -6991.189453125);
		elseif MyLevel >= 1900 and MyLevel <= 1924 then
			Mon = "Jungle Pirate";
			LevelQuest = 1;
			NameQuest = "DeepForestIsland2";
			NameMon = "Jungle Pirate";
			CFrameQuest = CFrame.new(-12680.3818, 389.971039, -9902.01953, -0.0871315002, 0, .996196866, 0, 1, 0, -0.996196866, 0, -0.0871315002);
			CFrameMon = CFrame.new(-12256.16015625, 331.73828125, -10485.836914062);
		elseif MyLevel >= 1925 and MyLevel <= 1974 then
			Mon = "Musketeer Pirate";
			LevelQuest = 2;
			NameQuest = "DeepForestIsland2";
			NameMon = "Musketeer Pirate";
			CFrameQuest = CFrame.new(-12680.3818, 389.971039, -9902.01953, -0.0871315002, 0, .996196866, 0, 1, 0, -0.996196866, 0, -0.0871315002);
			CFrameMon = CFrame.new(-13457.904296875, 391.54565429688, -9859.177734375);
		elseif MyLevel >= 1975 and MyLevel <= 1999 then
			Mon = "Reborn Skeleton";
			LevelQuest = 1;
			NameQuest = "HauntedQuest1";
			NameMon = "Reborn Skeleton";
			CFrameQuest = CFrame.new(-9479.2168, 141.215088, 5566.09277, 0, 0, 1, 0, 1, 0, -1, 0, 0);
			CFrameMon = CFrame.new(-8763.7236328125, 165.72299194336, 6159.8618164062);
		elseif MyLevel >= 2000 and MyLevel <= 2024 then
			Mon = "Living Zombie";
			LevelQuest = 2;
			NameQuest = "HauntedQuest1";
			NameMon = "Living Zombie";
			CFrameQuest = CFrame.new(-9479.2168, 141.215088, 5566.09277, 0, 0, 1, 0, 1, 0, -1, 0, 0);
			CFrameMon = CFrame.new(-10144.131835938, 138.6266784668, 5838.0888671875);
		elseif MyLevel >= 2025 and MyLevel <= 2049 then
			Mon = "Demonic Soul";
			LevelQuest = 1;
			NameQuest = "HauntedQuest2";
			NameMon = "Demonic Soul";
			CFrameQuest = CFrame.new(-9516.99316, 172.017181, 6078.46533, 0, 0, -1, 0, 1, 0, 1, 0, 0);
			CFrameMon = CFrame.new(-9505.8720703125, 172.10482788086, 6158.9931640625);
		elseif MyLevel >= 2050 and MyLevel <= 2074 then
			Mon = "Posessed Mummy";
			LevelQuest = 2;
			NameQuest = "HauntedQuest2";
			NameMon = "Posessed Mummy";
			CFrameQuest = CFrame.new(-9516.99316, 172.017181, 6078.46533, 0, 0, -1, 0, 1, 0, 1, 0, 0);
			CFrameMon = CFrame.new(-9582.0224609375, 6.2515273094177, 6205.478515625);
		elseif MyLevel >= 2075 and MyLevel <= 2099 then
			Mon = "Peanut Scout";
			LevelQuest = 1;
			NameQuest = "NutsIslandQuest";
			NameMon = "Peanut Scout";
			CFrameQuest = CFrame.new(-2104.3908691406, 38.104167938232, -10194.21875, 0, 0, -1, 0, 1, 0, 1, 0, 0);
			CFrameMon = CFrame.new(-2143.2419433594, 47.721984863281, -10029.995117188);
		elseif MyLevel >= 2100 and MyLevel <= 2124 then
			Mon = "Peanut President";
			LevelQuest = 2;
			NameQuest = "NutsIslandQuest";
			NameMon = "Peanut President";
			CFrameQuest = CFrame.new(-2104.3908691406, 38.104167938232, -10194.21875, 0, 0, -1, 0, 1, 0, 1, 0, 0);
			CFrameMon = CFrame.new(-1859.3540039062, 38.103168487549, -10422.4296875);
		elseif MyLevel >= 2125 and MyLevel <= 2149 then
			Mon = "Ice Cream Chef";
			LevelQuest = 1;
			NameQuest = "IceCreamIslandQuest";
			NameMon = "Ice Cream Chef";
			CFrameQuest = CFrame.new(-820.64825439453, 65.819526672363, -10965.795898438, 0, 0, -1, 0, 1, 0, 1, 0, 0);
			CFrameMon = CFrame.new(-872.24658203125, 65.81957244873, -10919.95703125);
		elseif MyLevel >= 2150 and MyLevel <= 2199 then
			Mon = "Ice Cream Commander";
			LevelQuest = 2;
			NameQuest = "IceCreamIslandQuest";
			NameMon = "Ice Cream Commander";
			CFrameQuest = CFrame.new(-820.64825439453, 65.819526672363, -10965.795898438, 0, 0, -1, 0, 1, 0, 1, 0, 0);
			CFrameMon = CFrame.new(-558.06103515625, 112.04895782471, -11290.774414062);
		elseif MyLevel >= 2200 and MyLevel <= 2224 then
			Mon = "Cookie Crafter";
			LevelQuest = 1;
			NameQuest = "CakeQuest1";
			NameMon = "Cookie Crafter";
			CFrameQuest = CFrame.new(-2021.32007, 37.7982254, -12028.7295, .957576931, -8.80302053e-08, .288177818, 6.9301187e-08, 1, 7.51931211e-08, -0.288177818, -5.2032135e-08, .957576931);
			CFrameMon = CFrame.new(-2374.13671875, 37.798263549805, -12125.30859375);
		elseif MyLevel >= 2225 and MyLevel <= 2249 then
			Mon = "Cake Guard";
			LevelQuest = 2;
			NameQuest = "CakeQuest1";
			NameMon = "Cake Guard";
			CFrameQuest = CFrame.new(-2021.32007, 37.7982254, -12028.7295, .957576931, -8.80302053e-08, .288177818, 6.9301187e-08, 1, 7.51931211e-08, -0.288177818, -5.2032135e-08, .957576931);
			CFrameMon = CFrame.new(-1598.3070068359, 43.773197174072, -12244.581054688);
		elseif MyLevel >= 2250 and MyLevel <= 2274 then
			Mon = "Baking Staff";
			LevelQuest = 1;
			NameQuest = "CakeQuest2";
			NameMon = "Baking Staff";
			CFrameQuest = CFrame.new(-1927.91602, 37.7981339, -12842.5391, -0.96804446, 4.22142143e-08, .250778586, 4.74911062e-08, 1, 1.49904711e-08, -0.250778586, 2.64211941e-08, -0.96804446);
			CFrameMon = CFrame.new(-1887.8099365234, 77.618507385254, -12998.350585938);
		elseif MyLevel >= 2275 and MyLevel <= 2299 then
			Mon = "Head Baker";
			LevelQuest = 2;
			NameQuest = "CakeQuest2";
			NameMon = "Head Baker";
			CFrameQuest = CFrame.new(-1927.91602, 37.7981339, -12842.5391, -0.96804446, 4.22142143e-08, .250778586, 4.74911062e-08, 1, 1.49904711e-08, -0.250778586, 2.64211941e-08, -0.96804446);
			CFrameMon = CFrame.new(-2216.1882324219, 82.884521484375, -12869.293945312);
		elseif MyLevel >= 2300 and MyLevel <= 2324 then
			Mon = "Cocoa Warrior";
			LevelQuest = 1;
			NameQuest = "ChocQuest1";
			NameMon = "Cocoa Warrior";
			CFrameQuest = CFrame.new(233.22836303711, 29.876001358032, -12201.233398438);
			CFrameMon = CFrame.new(-21.553283691406, 80.574996948242, -12352.387695312);
		elseif MyLevel >= 2325 and MyLevel <= 2349 then
			Mon = "Chocolate Bar Battler";
			LevelQuest = 2;
			NameQuest = "ChocQuest1";
			NameMon = "Chocolate Bar Battler";
			CFrameQuest = CFrame.new(233.22836303711, 29.876001358032, -12201.233398438);
			CFrameMon = CFrame.new(582.59057617188, 77.188095092773, -12463.162109375);
		elseif MyLevel >= 2350 and MyLevel <= 2374 then
			Mon = "Sweet Thief";
			LevelQuest = 1;
			NameQuest = "ChocQuest2";
			NameMon = "Sweet Thief";
			CFrameQuest = CFrame.new(150.50663757324, 30.693693161011, -12774.502929688);
			CFrameMon = CFrame.new(165.1884765625, 76.058853149414, -12600.836914062);
		elseif MyLevel >= 2375 and MyLevel <= 2399 then
			Mon = "Candy Rebel";
			LevelQuest = 2;
			NameQuest = "ChocQuest2";
			NameMon = "Candy Rebel";
			CFrameQuest = CFrame.new(150.50663757324, 30.693693161011, -12774.502929688);
			CFrameMon = CFrame.new(134.86563110352, 77.247680664062, -12876.547851562);
		elseif MyLevel >= 2400 and MyLevel <= 2424 then
			Mon = "Candy Pirate";
			LevelQuest = 1;
			NameQuest = "CandyQuest1";
			NameMon = "Candy Pirate";
			CFrameQuest = CFrame.new(-1150.0400390625, 20.378934860229, -14446.334960938);
			CFrameMon = CFrame.new(-1310.5003662109, 26.016523361206, -14562.404296875);
		elseif MyLevel >= 2425 and MyLevel <= 2449 then
			Mon = "Snow Demon";
			LevelQuest = 2;
			NameQuest = "CandyQuest1";
			NameMon = "Snow Demon";
			CFrameQuest = CFrame.new(-1150.0400390625, 20.378934860229, -14446.334960938);
			CFrameMon = CFrame.new(-880.20062255859, 71.247764587402, -14538.609375);
		elseif MyLevel >= 2450 and MyLevel <= 2474 then
			Mon = "Isle Outlaw";
			LevelQuest = 1;
			NameQuest = "TikiQuest1";
			NameMon = "Isle Outlaw";
			CFrameQuest = CFrame.new(-16547.748046875, 61.135334014893, -173.41360473633);
			CFrameMon = CFrame.new(-16442.814453125, 116.13899993896, -264.46377563477);
		elseif MyLevel >= 2475 and MyLevel <= 2524 then
			Mon = "Island Boy";
			LevelQuest = 2;
			NameQuest = "TikiQuest1";
			NameMon = "Island Boy";
			CFrameQuest = CFrame.new(-16547.748046875, 61.135334014893, -173.41360473633);
			CFrameMon = CFrame.new(-16901.26171875, 84.067565917969, -192.88906860352);
		elseif MyLevel >= 2525 and MyLevel <= 2550 then
			Mon = "Isle Champion";
			LevelQuest = 2;
			NameQuest = "TikiQuest2";
			NameMon = "Isle Champion";
			CFrameQuest = CFrame.new(-16539.078125, 55.686328887939, 1051.5738525391);
			CFrameMon = CFrame.new(-16641.6796875, 235.78254699707, 1031.2829589844);
		elseif MyLevel >= 2550 and MyLevel <= 2574 then
			Mon = "Serpent Hunter";
			LevelQuest = 1;
			NameQuest = "TikiQuest3";
			NameMon = "Serpent Hunter";
			CFrameQuest = CFrame.new(-16665.1914, 104.596405, 1579.69434, .951068401, 0, -0.308980465, 0, 1, 0, .308980465, 0, .951068401);
			CFrameMon = CFrame.new(-16521.0625, 106.09285, 1488.78467, .469467044, 0, .882950008, 0, 1, 0, -0.882950008, 0, .469467044);
		elseif MyLevel >= 2575 and MyLevel <= 2599 then
			Mon = "Skull Slayer";
			LevelQuest = 2;
			NameQuest = "TikiQuest3";
			NameMon = "Skull Slayer";
			CFrameQuest = CFrame.new(-16665.1914, 104.596405, 1579.69434, .951068401, 0, -0.308980465, 0, 1, 0, .308980465, 0, .951068401);
			CFrameMon = CFrame.new(-16855.043, 122.457253, 1478.15308, -0.999392271, 0, -0.0348687991, 0, 1, 0, .0348687991, 0, -0.999392271);
		elseif MyLevel >= 2600 and MyLevel <= 2624 then
			CFrameQuest = CFrame.new(10780.107421875, -2087.7214355469, 9261.865234375);
			if ((getgenv()).AutoFarm or _G.Level) and (CFrameQuest.Position - selfRoot.Position).Magnitude > 10000 then
				_tp(CFrame.new(-16269.7041, 25.2288494, 1373.65955, 0.997390985, 1.47309942e-09, -0.0721890926, -4.00651912e-09, 0.99999994, -2.51183763e-09, 0.0721890852, 5.75363091e-10, 0.997390926));
				task.wait(2);
				BFComm("requestEntrance", Vector3.new(-16269.7041, 25.2288494, 1373.65955));
				task.wait(1);
				local args = {"TravelToSubmergedIsland"};
				pcall(function() local submarine = game:GetService("ReplicatedStorage").Modules.Net:FindFirstChild("RF/SubmarineWorkerSpeak"); if submarine then submarine:InvokeServer(unpack(args)); end; end);
				return;
			end;
			Mon = "Reef Bandit";
			LevelQuest = 1;
			NameQuest = "SubmergedQuest1";
			NameMon = "Reef Bandit";
			CFrameMon = CFrame.new(10943.0811, -2083.03516, 9177.33691, -0.998713255, -0.0461204648, .021090759, -0.0451571345, .998007238, .0440727882, -0.0230813865, .0430636741, -0.998805642);
		elseif MyLevel >= 2625 and MyLevel <= 2649 then
			CFrameQuest = CFrame.new(10780.107421875, -2087.7214355469, 9261.865234375);
			if ((getgenv()).AutoFarm or _G.Level) and (CFrameQuest.Position - selfRoot.Position).Magnitude > 10000 then
				_tp(CFrame.new(-16269.7041, 25.2288494, 1373.65955, 0.997390985, 1.47309942e-09, -0.0721890926, -4.00651912e-09, 0.99999994, -2.51183763e-09, 0.0721890852, 5.75363091e-10, 0.997390926));
				task.wait(2);
				BFComm("requestEntrance", Vector3.new(-16269.7041, 25.2288494, 1373.65955));
				task.wait(1);
				local args = {"TravelToSubmergedIsland"};
				pcall(function() local submarine = game:GetService("ReplicatedStorage").Modules.Net:FindFirstChild("RF/SubmarineWorkerSpeak"); if submarine then submarine:InvokeServer(unpack(args)); end; end);
				return;
			end;
			Mon = "Coral Pirate";
			LevelQuest = 2;
			NameQuest = "SubmergedQuest1";
			NameMon = "Coral Pirate";
			CFrameMon = CFrame.new(10713.4473, -2093.04517, 9307.14844, .325602472, 7.02769976e-05, .945506752, -7.02769976e-05, 1, -5.01261711e-05, -0.945506752, -5.01261711e-05, .325602472);
		elseif MyLevel >= 2650 and MyLevel <= 2674 then
			CFrameQuest = CFrame.new(10883.587890625, -2086.1970214844, 10032.196289062);
			if ((getgenv()).AutoFarm or _G.Level) and (CFrameQuest.Position - selfRoot.Position).Magnitude > 10000 then
				_tp(CFrame.new(-16269.7041, 25.2288494, 1373.65955, 0.997390985, 1.47309942e-09, -0.0721890926, -4.00651912e-09, 0.99999994, -2.51183763e-09, 0.0721890852, 5.75363091e-10, 0.997390926));
				task.wait(2);
				BFComm("requestEntrance", Vector3.new(-16269.7041, 25.2288494, 1373.65955));
				task.wait(1);
				local args = {"TravelToSubmergedIsland"};
				pcall(function() local submarine = game:GetService("ReplicatedStorage").Modules.Net:FindFirstChild("RF/SubmarineWorkerSpeak"); if submarine then submarine:InvokeServer(unpack(args)); end; end);
				return;
			end;
			Mon = "Sea Chanter";
			LevelQuest = 1;
			NameQuest = "SubmergedQuest2";
			NameMon = "Sea Chanter";
			CFrameMon = CFrame.new(10647.606445312, -2077.6257324219, 10079.962890625);
		elseif MyLevel >= 2675 and MyLevel <= 2699 then
			CFrameQuest = CFrame.new(9635.8701171875, -1992.4481201172, 9614.3935546875);
			if ((getgenv()).AutoFarm or _G.Level) and (CFrameQuest.Position - selfRoot.Position).Magnitude > 10000 then
				_tp(CFrame.new(-16269.7041, 25.2288494, 1373.65955, 0.997390985, 1.47309942e-09, -0.0721890926, -4.00651912e-09, 0.99999994, -2.51183763e-09, 0.0721890852, 5.75363091e-10, 0.997390926));
				task.wait(2);
				BFComm("requestEntrance", Vector3.new(-16269.7041, 25.2288494, 1373.65955));
				task.wait(1);
				local args = {"TravelToSubmergedIsland"};
				pcall(function() local submarine = game:GetService("ReplicatedStorage").Modules.Net:FindFirstChild("RF/SubmarineWorkerSpeak"); if submarine then submarine:InvokeServer(unpack(args)); end; end);
				return;
			end;
			Mon = "High Disciple";
			LevelQuest = 1;
			NameQuest = "SubmergedQuest3";
			NameMon = "High Disciple";
			CFrameMon = CFrame.new(9843.578125, -1993.4559326172, 9696.48046875);
		elseif MyLevel >= 2700 then
			CFrameQuest = CFrame.new(9635.8701171875, -1992.4481201172, 9614.3935546875);
			if ((getgenv()).AutoFarm or _G.Level) and (CFrameQuest.Position - selfRoot.Position).Magnitude > 10000 then
				_tp(CFrame.new(-16269.7041, 25.2288494, 1373.65955, 0.997390985, 1.47309942e-09, -0.0721890926, -4.00651912e-09, 0.99999994, -2.51183763e-09, 0.0721890852, 5.75363091e-10, 0.997390926));
				task.wait(2);
				BFComm("requestEntrance", Vector3.new(-16269.7041, 25.2288494, 1373.65955));
				task.wait(1);
				local args = {"TravelToSubmergedIsland"};
				pcall(function() local submarine = game:GetService("ReplicatedStorage").Modules.Net:FindFirstChild("RF/SubmarineWorkerSpeak"); if submarine then submarine:InvokeServer(unpack(args)); end; end);
				return;
			end;
			Mon = "Grand Devotee";
			LevelQuest = 2;
			NameQuest = "SubmergedQuest3";
			NameMon = "Grand Devotee";
			CFrameMon = CFrame.new(9591.0546875, -1993.4742431641, 9808.705078125);
		end;
	end;
end;
	UI.BuildId = "lumin-20260810-lifecycle-v116";
getgenv().BloxFruitsBuild = UI.BuildId;
getgenv().BloxFruitsUI = UI;
UI.Library = loadstring(game:HttpGet("https://luminon.top/testing/Library.lua"))();
UI.Library.NotifyOnError = true;
function UI.LabelWait(interval)
	if UI.Stopped or UI.Library.Unloaded then
		return false;
	end;
	if UI.Library.Toggled then
		task.wait(interval or 5);
	else
		task.wait(2);
	end;
	return not UI.Stopped and not UI.Library.Unloaded;
end;
UI.Options = UI.Library.Options;
UI.Toggles = UI.Library.Toggles;
function UI.DisableToggle(id)
	local toggle = UI.Toggles[id];
	if toggle and type(toggle.SetValue) == "function" then
		toggle:SetValue(false);
		return;
	end;
	if id == "BF_Toggle_Auto_Unlocked_DonSwan" then
		_G.Auto_DonAcces = false;
	end;
end;
UI.Repo = "http://luminon.top/obsidian/";
UI.ThemeManager = loadstring(game:HttpGet(UI.Repo .. "Addons/ThemeManager.lua"))();
UI.SaveManager = loadstring(game:HttpGet(UI.Repo .. "Addons/SaveManager.lua"))();
UI.CustomIcon = nil;
if writefile and isfile and getcustomasset then
	pcall(function()
		if not isfile("A7.png") then
			writefile("A7.png", game:HttpGet("http://luminon.top/A7.png"));
		end;
		UI.CustomIcon = getcustomasset("A7.png");
	end);
end;
UI.Window = UI.Library:CreateWindow({
	Title = " ",
	Footer = "Blox Fruits",
	Size = UI.Library.IsMobile and UDim2.fromOffset(400, 350) or UDim2.fromOffset(600, 520),
	Icon = UI.CustomIcon,
	ToggleKeybind = Enum.KeyCode.RightControl,
	Center = true,
	AutoShow = true,
	CornerRadius = 10,
});
UI.RootTabs = {
	Player = UI.Window:AddTab("Profile", "square-user", "Player profile and key information"),
	Priority = UI.Window:AddTab("Priority", "list-ordered", "Priority mode: run one task at a time, highest priority first"),
	Farm = UI.Window:AddTab("Farm", "sprout", "Leveling, quests and mastery"),
	Items = UI.Window:AddTab("Items", "sword", "Styles, weapons and shops"),
	Events = UI.Window:AddTab("Events", "ship", "Sea, race and raid events"),
	Combat = UI.Window:AddTab("Combat", "crosshair", "Combat and visuals"),
	World = UI.Window:AddTab("World", "map", "Travel and fruits"),
	Utility = UI.Window:AddTab("Utility", "wrench", "Character, server and performance"),
	Setting = UI.Window:AddTab("Setting", "settings", "Interface and configurations"),
};
UI.Groups = {
	{ Root = "Priority", Title = "Priority Mode", Side = "Left", Icon = "list-ordered", Sections = {
		{ Key = "BF/PriorityMode", Name = "Order", Icon = "arrow-down-up", Tip = "Choose which task wins when several are enabled" },
	} },
	{ Root = "Priority", Title = "Status", Side = "Right", Icon = "activity", Sections = {
		{ Key = "BF/PriorityStatus", Name = "Status", Icon = "gauge", Tip = "What priority mode is currently running" },
	} },
	{ Root = "Farm", Title = "Leveling", Side = "Left", Icon = "trending-up", Sections = {
		{ Key = "Farm", Name = "Auto Farm", Icon = "zap", Tip = "Level farming" },
		{ Key = "Miscellanea / Quest", Name = "Quests", Icon = "scroll-text", Tip = "Quest automation" },
		{ Key = "Generals Quests / Items", Name = "General", Icon = "clipboard-list", Tip = "General quests" },
	} },
	{ Root = "Farm", Title = "Progression", Side = "Right", Icon = "award", Sections = {
		{ Key = "Miscellanea / Mastery", Name = "Mastery", Icon = "badge", Tip = "Mastery farming" },
		{ Key = "Sword Mastery", Name = "Sword Mastery", Icon = "swords", Tip = "Sword selection and mastery limits" },
		{ Key = "BF/Notifications", Name = "Notifications", Icon = "bell", Tip = "Boss and rare island alerts" },
		{ Key = "Upgrade Races V3", Name = "Race V3", Icon = "dna", Tip = "Race V3 upgrade" },
		{ Key = "Instinct / Observation", Name = "Instinct", Icon = "eye-off", Tip = "Observation haki" },
		{ Key = "Buso/Aura Colours", Name = "Aura", Icon = "palette", Tip = "Buso and aura colours" },
	} },
	{ Root = "Farm", Title = "Extras", Side = "Left", Icon = "puzzle", Sections = {
		{ Key = "Miscellanea / Fishing", Name = "Fishing", Icon = "fish", Tip = "Auto fishing" },
		{ Key = "Gacha", Name = "Gacha", Icon = "dices", Tip = "Gacha banner status and rolls" },
		{ Key = "Unlocked Dungeon", Name = "Dungeon", Icon = "castle", Tip = "Dungeon unlock" },
		{ Key = "Dark Dagger + Valkyrie", Name = "Dagger", Icon = "shield-alert", Tip = "Dark dagger and Valkyrie" },
	} },
	{ Root = "Items", Title = "Fighting Styles", Side = "Left", Icon = "dumbbell", Sections = {
		{ Key = "Fighting Melee Styles", Name = "Melee", Icon = "hand", Tip = "Melee styles" },
		{ Key = "Fighting - Style", Name = "Purchase", Icon = "coins", Tip = "Buy fighting styles" },
	} },
	{ Root = "Items", Title = "Swords", Side = "Right", Icon = "swords", Sections = {
		{ Key = "Tushita + Yama", Name = "Tushita", Icon = "star", Tip = "Tushita and Yama" },
		{ Key = "Cursed Dual Katana", Name = "CDK", Icon = "gem", Tip = "Cursed Dual Katana" },
		{ Key = "True Triple Katana Sword", Name = "Triple Katana", Icon = "layers", Tip = "True Triple Katana" },
		{ Key = "Items Law/Order Sword", Name = "Law Order", Icon = "tag", Tip = "Law and Order swords" },
		{ Key = "Rengoku Sword", Name = "Rengoku", Icon = "medal", Tip = "Rengoku sword" },
	} },
	{ Root = "Items", Title = "Gear", Side = "Left", Icon = "axe", Sections = {
		{ Key = "Pole / God Enel", Name = "Pole", Icon = "milestone", Tip = "Pole and Thunder God Enel" },
		{ Key = "Canvander + Twin Hooks + Big Mom", Name = "Canvander", Icon = "anchor", Tip = "Canvander, Twin Hooks, and Big Mom" },
		{ Key = "East Blue Misc", Name = "East Blue", Icon = "compass", Tip = "East Blue items" },
		{ Key = "Weapon World1", Name = "W1 Weapons", Icon = "hammer", Tip = "First sea weapons" },
	} },
	{ Root = "Items", Title = "Shops", Side = "Right", Icon = "store", Sections = {
		{ Key = "Shop Options", Name = "General Shop", Icon = "shopping-cart", Tip = "General shop" },
		{ Key = "Accessory", Name = "Accessory", Icon = "crown", Tip = "Accessories" },
		{ Key = "Accessory SeaEvent", Name = "Sea Gear", Icon = "life-buoy", Tip = "Sea event accessories" },
		{ Key = "Fragments shop", Name = "Fragments", Icon = "boxes", Tip = "Fragment shop" },
	} },
	{ Root = "Events", Title = "Sea Events", Side = "Left", Icon = "sailboat", Sections = {
		{ Key = "Sea Event / Setting Sail", Name = "Setting Sail", Icon = "wind", Tip = "Setting sail events" },
		{ Key = "Entity Sea Event", Name = "Entities", Icon = "shield", Tip = "Sea entities" },
		{ Key = "Kitsune Island / Event", Name = "Kitsune", Icon = "rabbit", Tip = "Kitsune island" },
	} },
	{ Root = "Events", Title = "Mirage and Race V4", Side = "Right", Icon = "moon", Sections = {
		{ Key = "Mystic Island / Full Moon", Name = "Full Moon", Icon = "sparkles", Tip = "Mystic island" },
		{ Key = "Skull Guitar / Misc", Name = "Skull Guitar", Icon = "cloud-fog", Tip = "Skull guitar" },
		{ Key = "Trials Quests / Misc V4", Name = "Race V4", Icon = "activity", Tip = "Race V4 trials" },
	} },
	{ Root = "Events", Title = "Dojo and Draco", Side = "Left", Icon = "flame", Sections = {
		{ Key = "Dojo Quest & Draco Race", Name = "Dojo Quest", Icon = "graduation-cap", Tip = "Dojo quest" },
		{ Key = "Draco Trial", Name = "Draco Trial", Icon = "mountain-snow", Tip = "Draco trial" },
	} },
	{ Root = "Events", Title = "Prehistoric", Side = "Right", Icon = "bone", Sections = {
		{ Key = "Volcanic Magnet", Name = "Volcanic", Icon = "mountain", Tip = "Volcanic magnet" },
		{ Key = "Prehistoric Island", Name = "Island", Icon = "egg", Tip = "Prehistoric island" },
	} },
	{ Root = "Events", Title = "Raids", Side = "Left", Icon = "skull", Sections = {
		{ Key = "Dungeon Event / Raiding", Name = "Dungeon Raid", Icon = "tower-control", Tip = "Dungeon raid" },
		{ Key = "Raiding Menu", Name = "Raid Menu", Icon = "list-checks", Tip = "Raid menu" },
	} },
	{ Root = "Combat", Title = "Combat", Side = "Left", Icon = "target", Sections = {
		{ Key = "Combat / Aimbot", Name = "Aimbot", Icon = "radar", Tip = "Aimbot" },
		{ Key = "Settings Combat / Aimbot Settings", Name = "Aim Settings", Icon = "cog", Tip = "Aimbot settings" },
		{ Key = "LocalPlayer Settings / Misc", Name = "Local Player", Icon = "gamepad-2", Tip = "Local player combat" },
	} },
	{ Root = "Combat", Title = "Visuals", Side = "Right", Icon = "scan-eye", Sections = {
		{ Key = "Esp Items / Entity / Island", Name = "ESP", Icon = "eye", Tip = "ESP options" },
	} },
	{ Root = "World", Title = "Travel", Side = "Left", Icon = "navigation", Sections = {
		{ Key = "Travel - Worlds", Name = "Worlds", Icon = "globe", Tip = "World travel" },
		{ Key = "Travel - Island", Name = "Islands", Icon = "tree-palm", Tip = "Island travel" },
		{ Key = "Travel - Portal", Name = "Portals", Icon = "door-open", Tip = "Portal travel" },
		{ Key = "Travel - NPCs", Name = "NPCs", Icon = "users", Tip = "NPC travel" },
	} },
	{ Root = "World", Title = "Fruits", Side = "Right", Icon = "cherry", Sections = {
		{ Key = "Fruits Options", Name = "Fruits", Icon = "apple", Tip = "Fruit options" },
	} },
	{ Root = "Utility", Title = "Script", Side = "Left", Icon = "sliders-horizontal", Sections = {
		{ Key = "Settings / Configure", Name = "Config", Icon = "folder-cog", Tip = "Script configuration" },
		{ Key = "Stats Upgrade", Name = "Stats", Icon = "chart-no-axes-column", Tip = "Stat upgrades" },
	} },
	{ Root = "Utility", Title = "Interface", Side = "Right", Icon = "app-window", Sections = {
		{ Key = "Player Gui / Others", Name = "Game UI", Icon = "text-align-center", Tip = "Game interface" },
		{ Key = "Graphics / Haki Stats", Name = "Graphics", Icon = "paintbrush", Tip = "Graphics options" },
		{ Key = "Configure - God", Name = "Movement", Icon = "footprints", Tip = "Movement options" },
	} },
	{ Root = "Utility", Title = "Server", Side = "Left", Icon = "server", Sections = {
		{ Key = "Server - Function", Name = "Game Server", Icon = "wifi", Tip = "Server functions" },
		{ Key = "BF/ServerTools", Name = "Rejoin Hop", Icon = "signal", Tip = "Rejoin and server hop" },
	} },
	{ Root = "Utility", Title = "Character", Side = "Right", Icon = "person-standing", Sections = {
		{ Key = "BF/PlayerMods", Name = "Player Mods", Icon = "plus", Tip = "Speed, jump and noclip" },
	} },
	{ Root = "Utility", Title = "Performance", Side = "Left", Icon = "cpu", Sections = {
		{ Key = "BF/Optimize", Name = "Optimize", Icon = "refresh-ccw", Tip = "FPS and graphics" },
	} },
	{ Root = "Setting", Title = "Configs", Side = "Left", Icon = "save", Sections = {
		{ Key = "BF/ConfigFiles", Name = "Files", Icon = "file-text", Tip = "Save and load configs" },
		{ Key = "BF/Themes", Name = "Themes", Icon = "sparkle", Tip = "Interface theme" },
		{ Key = "BF/Transfer", Name = "Transfer", Icon = "file-input", Tip = "Import and export configs" },
	} },
	{ Root = "Setting", Title = "Menu", Side = "Right", Icon = "list", Sections = {
		{ Key = "BF/Display", Name = "Display", Icon = "gauge", Tip = "Watermark and scaling" },
		{ Key = "BF/Behaviour", Name = "Behaviour", Icon = "timer", Tip = "Keybinds and reconnect" },
	} },
};
UI.Sections = {};
UI.Tabboxes = {};
function UI.GetTabbox(root, title, side, icon)
	local key = tostring(root) .. "|" .. tostring(title);
	local existing = UI.Tabboxes[key];
	if existing then
		return existing;
	end;
	local parent = UI.RootTabs[root] or UI.RootTabs.Utility;
	local group;
	if side == "Right" then
		group = parent:AddRightGroupbox(title, icon);
	else
		group = parent:AddLeftGroupbox(title, icon);
	end;
	local tabbox = group:AddTabbox();
	UI.Tabboxes[key] = tabbox;
	return tabbox;
end;
function UI.BuildLayout()
	for _, group in ipairs(UI.Groups) do
		local tabbox = UI.GetTabbox(group.Root, group.Title, group.Side, group.Icon);
		for _, entry in ipairs(group.Sections) do
			local tab = tabbox:AddTab({
				Name = entry.Name,
				Icon = entry.Icon,
				Tooltip = entry.Tip or entry.Name,
			});
			UI.Sections[entry.Key] = tab;
		end;
	end;
end;
UI.BuildLayout();
UI.ManagedFlags = {};
function UI.RegisterManagedFlag(name, initialValue)
	local state = UI.ManagedFlags[name];
	if not state then
		state = {
			UserValue = initialValue == true,
			Drivers = {},
			Suppressors = {},
		};
		UI.ManagedFlags[name] = state;
	end;
	_G[name] = state.UserValue;
end;
function UI.RefreshManagedFlag(name)
	local state = UI.ManagedFlags[name];
	if not state then
		return;
	end;
	if next(state.Suppressors) then
		_G[name] = false;
	elseif next(state.Drivers) then
		_G[name] = true;
	else
		_G[name] = state.UserValue;
	end;
end;
function UI.SetManagedUserFlag(name, value)
	local state = UI.ManagedFlags[name];
	if not state then
		_G[name] = value == true;
		return;
	end;
	state.UserValue = value == true;
	UI.RefreshManagedFlag(name);
end;
function UI.DriveManagedFlag(owner, name)
	local state = UI.ManagedFlags[name];
	if not state then
		return;
	end;
	state.Drivers[owner] = true;
	state.Suppressors[owner] = nil;
	UI.RefreshManagedFlag(name);
end;
function UI.SuppressManagedFlag(owner, name)
	local state = UI.ManagedFlags[name];
	if not state then
		return;
	end;
	state.Suppressors[owner] = true;
	state.Drivers[owner] = nil;
	UI.RefreshManagedFlag(name);
end;
function UI.ReleaseManagedFlag(owner, name)
	local state = UI.ManagedFlags[name];
	if not state then
		return;
	end;
	state.Drivers[owner] = nil;
	state.Suppressors[owner] = nil;
	UI.RefreshManagedFlag(name);
end;
UI.ManagedValues = {};
function UI.RegisterManagedValue(name, initialValue)
	UI.ManagedValues[name] = UI.ManagedValues[name] or {
		UserValue = initialValue,
		Drivers = {},
	};
	_G[name] = UI.ManagedValues[name].UserValue;
end;
function UI.RefreshManagedValue(name)
	local state = UI.ManagedValues[name];
	if not state then
		return;
	end;
	local value = state.UserValue;
	for _, driverValue in pairs(state.Drivers) do
		value = driverValue;
		break;
	end;
	_G[name] = value;
end;
function UI.SetManagedUserValue(name, value)
	local state = UI.ManagedValues[name];
	if not state then
		_G[name] = value;
		return;
	end;
	state.UserValue = value;
	UI.RefreshManagedValue(name);
end;
function UI.DriveManagedValue(owner, name, value)
	local state = UI.ManagedValues[name];
	if not state then
		return;
	end;
	state.Drivers[owner] = value;
	UI.RefreshManagedValue(name);
end;
function UI.ReleaseManagedValue(owner, name)
	local state = UI.ManagedValues[name];
	if not state then
		return;
	end;
	state.Drivers[owner] = nil;
	UI.RefreshManagedValue(name);
end;
function UI.ReleaseManagedOwner(owner)
	for name, state in pairs(UI.ManagedFlags) do
		if state.Drivers[owner] or state.Suppressors[owner] then
			state.Drivers[owner] = nil;
			state.Suppressors[owner] = nil;
			UI.RefreshManagedFlag(name);
		end;
	end;
	for name, state in pairs(UI.ManagedValues) do
		if state.Drivers[owner] ~= nil then
			state.Drivers[owner] = nil;
			UI.RefreshManagedValue(name);
		end;
	end;
end;
UI.RegisterManagedFlag("SailBoats", false);
UI.RegisterManagedFlag("Shark", false);
UI.RegisterManagedFlag("Piranha", false);
UI.RegisterManagedFlag("TerrorShark", false);
UI.RegisterManagedFlag("MobCrew", false);
UI.RegisterManagedFlag("HCM", false);
UI.RegisterManagedFlag("PGB", false);
UI.RegisterManagedFlag("FishBoat", false);
UI.RegisterManagedFlag("SeaBeast1", false);
UI.RegisterManagedFlag("Leviathan1", false);
UI.RegisterManagedFlag("Prehis_Find", false);
UI.RegisterManagedFlag("Prehis_Skills", false);
UI.RegisterManagedFlag("Prehis_DB", false);
UI.RegisterManagedFlag("Prehis_DE", false);
UI.RegisterManagedFlag("FarmBlazeEM", false);
UI.RegisterManagedFlag("AutoPole", false);
UI.RegisterManagedFlag("Auto_StartRaid", false);
UI.RegisterManagedFlag("Raiding", false);
UI.RegisterManagedFlag("Auto_Awakener", false);
UI.RegisterManagedFlag("NextIs", false);
UI.RegisterManagedValue("DangerSc", "Lv 1");
UI.RegisterManagedValue("SelectChip", "Flame");
UI.RegisterManagedValue("BFCombatWeapon", nil);
function UI.BuildPlayerTab()
	local playerTab = UI.RootTabs.Player;
	local totalSeconds = tonumber(LRM_SecondsLeft) or 0;
	local totalExecutions = tonumber(LRM_TotalExecutions) or 0;
	local method;
	local timeLeftString;
	if totalSeconds == -1 or totalSeconds == math.huge then
		timeLeftString = "Lifetime / Infinite";
		method = "Lifetime Key";
	elseif totalSeconds > 0 then
		timeLeftString = string.format("%d days, %d hours, %d minutes", math.floor(totalSeconds / 86400), math.floor((totalSeconds % 86400) / 3600), math.floor((totalSeconds % 3600) / 60));
		method = "Key System";
	else
		timeLeftString = "Unknown";
		method = "Developer Script";
	end;
	local thumb = "rbxasset://textures/ui/GuiImagePlaceholder.png";
	local ready = false;
	pcall(function()
		thumb, ready = Y:GetUserThumbnailAsync(d.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100);
	end);
	local panel = playerTab:AddPlayerPanel({
		AssetId = thumb,
		ImageSize = UDim2.fromOffset(64, 64),
		AvatarBoxSize = UDim2.fromOffset(72, 72),
		Height = 100,
		TopOffset = 10,
		Title = string.format("<b>Welcome To <font color=\"rgb(199, 0, 255)\">Lumin</font>, @%s!</b>", d.Name),
		Subtitle = "",
		Lines = {
			string.format("Method: <b><font color=\"rgb(199, 0, 255)\">%s</font></b>", method),
			string.format("Execution Amount: <b><font color=\"rgb(199, 0, 255)\">%s</font></b>", totalExecutions),
			string.format("Remaining Time: <b><font color=\"rgb(199, 0, 255)\">%s</font></b>", timeLeftString),
		},
	});
	if not ready then
		task.spawn(function()
			local tries = 0;
			repeat
				task.wait(.25);
				pcall(function()
					thumb, ready = Y:GetUserThumbnailAsync(d.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100);
				end);
				tries = tries + 1;
			until ready or tries > 20 or UI.Library.Unloaded;
			if ready and panel then
				panel:SetImage(thumb);
			end;
		end);
	end;
	local defaultCollapsed = UI.Library.DefaultCollapsed;
	UI.Library.DefaultCollapsed = false;
	local credits = playerTab:AddLeftGroupbox("Credits", "sparkle");
	local version = playerTab:AddRightGroupbox("Version", "hash");
	local gameInfo = playerTab:AddLeftGroupbox("Game", "app-window");
	local support = playerTab:AddRightGroupbox("Games Supported", "gamepad-2");
	UI.Library.DefaultCollapsed = defaultCollapsed;
	credits:AddLabel("Credits To Lumin Developers:\nThanks for supporting Lumin Hub :p");
	credits:AddCopyLabel("BF_CopyDiscord", {
		Text = "discord.gg/luminhub",
		CopyValue = "https://discord.gg/luminhub",
		Tooltip = "Click to copy",
		Color = Color3.fromRGB(200, 0, 120),
		Size = 14,
	});
	version:AddLabel("Script Version: " .. tostring(LRM_ScriptVersion or "v0000"));
	local gameLabel = gameInfo:AddLabel("Time Elapsed:\nLoading...", true);
	task.spawn(function()
		while not UI.Stopped and task.wait(1) do
			if UI.Library.Unloaded then
				return;
			end;
			local elapsed = workspace.DistributedGameTime;
			gameLabel:SetText(string.format("Time Elapsed:\n%d days\n%d hours\n%d minutes\n%d seconds", math.floor(elapsed / 86400), math.floor((elapsed % 86400) / 3600), math.floor((elapsed % 3600) / 60), math.floor(elapsed % 60)));
		end;
	end);
	gameInfo:AddLabel("Place Version: " .. tostring(game.PlaceVersion));
	local serverType = "Unknown";
	pcall(function()
		local reference = cloneref or clonereference or function(instance) return instance; end;
		local remote = reference(game:GetService("RobloxReplicatedStorage")):FindFirstChild("GetServerType");
		if not remote or not remote:IsA("RemoteFunction") then
			serverType = "Missing";
			return;
		end;
		local result = remote:InvokeServer();
		local variants = {
			StandardServer = "Public",
			VIPServer = "Private",
			ReservedServer = "Private Match",
		};
		serverType = variants[tostring(result)] or "Unknown or Unsupported";
	end);
	gameInfo:AddLabel("Server Variant: " .. serverType);
	local green = '<font color="rgb(0, 255, 0)">*</font>';
	local yellow = '<font color="rgb(255, 255, 0)">*</font>';
	local red = '<font color="rgb(255, 0, 0)">*</font>';
	support:AddLabel(green .. " Working and Updated\n" .. yellow .. " Unstable and Experimental\n" .. red .. " Not Working or Outdated", true);
	task.spawn(function()
		local ok, first, second = pcall(function()
			return loadstring(game:HttpGet("https://luminon.top/game.txt"))();
		end);
		if ok and first then
			support:AddLabel(first, second);
		end;
	end);
end;
UI.BuildPlayerTab();
local Gz = UI.Sections["Farm"];
UI.RegisterManagedFlag("Level", false);
Gz:AddToggle("BF_Toggle_Auto_Farm_Level", {
	Text = "Auto Farm Level",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		UI.SetManagedUserFlag("Level", Y);
		if Y and type(CheckQuest) == "function" then
			UI.AutoFarmLastError = nil;
			UI.AutoFarmNextQuestAt = 0;
			UI.AutoFarmNextQuestRefreshAt = 0;
			pcall(CheckQuest);
		elseif not Y and not _B then
			UI.RestoreBroughtEnemies();
		end;
		if not Y and UI.SetAutoFarmStatus then
			UI.SetAutoFarmStatus("idle");
		end;
	end,
});
function CheckHasQuest(Y)
	if not Y or not GuiShown("Quest") then
		return false;
	end;
	return string.find(string.lower(QuestText()), string.lower(tostring(Y)), 1, true) ~= nil;
end;
UI.AutoFarmStatus = "idle";
UI.AutoFarmLastError = nil;
UI.AutoFarmNextErrorNoticeAt = 0;
UI.AutoFarmNextQuestAt = 0;
UI.AutoFarmNextQuestRefreshAt = 0;
UI.AutoFarmTarget = nil;
UI.AutoFarmStatusLabel = Gz:AddLabel({ DoesWrap = true, Text = "Level farm: idle" });
function UI.SetAutoFarmStatus(status)
	status = tostring(status or "working");
	if status ~= UI.AutoFarmStatus then
		UI.AutoFarmStatus = status;
		UI.AutoFarmStatusLabel:SetText("Level farm: " .. status:gsub("%-", " "));
	end;
end;
UI.AutoFarmStep = function()
	if not _G.Level then
		UI.AutoFarmTarget = nil;
		return "inactive";
	end;
	local character = d.Character;
	local root = character and character:FindFirstChild("HumanoidRootPart");
	if not root then
		UI.AutoFarmTarget = nil;
		return "waiting-for-character";
	end;
	HRP = root;
	local currentLevel = tonumber(BFDataValue("Level")) or 0;
	local location = tostring(g:GetAttribute("CurrentLocation") or "");
	if currentLevel >= 2600 and location ~= "Submerged Island" and location ~= "Sealed Cavern" then
		UI.AutoFarmTarget = nil;
		local submarine = CFrame.new(-16269.4121, 24.7584076, 1371.70752, -0.999348342, -0.00479344372, .0357791297, -0.00262145093, .998164296, .0605080314, -0.036003489, .0603748076, -0.997526407);
		if BFMoveNear(submarine, 5) then
			NetInvoke("RF/SubmarineWorkerSpeak", "TravelToSubmergedIsland");
			return "entering-submerged";
		end;
		return "moving-to-submarine";
	end;
	local now = os.clock();
	if now >= UI.AutoFarmNextQuestRefreshAt or not Mon or not NameMon or typeof(CFrameQuest) ~= "CFrame" or typeof(CFrameMon) ~= "CFrame" then
		UI.AutoFarmNextQuestRefreshAt = now + 1;
		CheckQuest();
	end;
	if not Mon or not NameMon or not NameQuest or not LevelQuest or typeof(CFrameQuest) ~= "CFrame" or typeof(CFrameMon) ~= "CFrame" then
		UI.AutoFarmTarget = nil;
		return "waiting-for-quest-data";
	end;
	if not CheckHasQuest(NameMon) then
		UI.AutoFarmTarget = nil;
		if GuiShown("Quest") and now >= UI.AutoFarmNextQuestAt then
			BFComm("AbandonQuest");
			UI.AutoFarmNextQuestAt = now + 1;
		end;
		if not BFMoveNear(CFrameQuest, 4) then
			return "moving-to-quest";
		end;
		if now >= UI.AutoFarmNextQuestAt then
			BFComm("StartQuest", NameQuest, LevelQuest);
			UI.AutoFarmNextQuestAt = now + 2;
		end;
		if CheckHasQuest(NameMon) then
			BFMoveNear(CFrameMon, 40);
			return "quest-started";
		end;
		return "starting-quest";
	end;
	UI.AutoFarmNextQuestAt = 0;
	local enemy = BFFindLiveEnemyLike(Mon);
	UI.AutoFarmTarget = enemy;
	if enemy then
		f.Kill(enemy, _G.Level);
		return "combat";
	end;
	if BFMoveNear(CFrameMon, 40) then
		return "waiting-for-enemy";
	end;
	return "moving-to-enemy";
end;
task.spawn(function()
	while IdleWait(_G.Level, .1) do
		if _G.Level then
			local ok, status = pcall(UI.AutoFarmStep);
			if ok then
				UI.SetAutoFarmStatus(status);
			else
				UI.AutoFarmLastError = tostring(status);
				UI.SetAutoFarmStatus("error");
				if os.clock() >= UI.AutoFarmNextErrorNoticeAt then
					UI.AutoFarmNextErrorNoticeAt = os.clock() + 8;
					UI.Library:Notify("Level farm error: " .. UI.AutoFarmLastError, 8);
				end;
				task.wait(1);
			end;
		end;
	end;
end);
Gz:AddToggle("BF_Toggle_Auto_Travel_Dressrosa", {
	Text = "Auto Travel Dressrosa",
	Tooltip = "Complete the Ice Admiral route and travel to Second Sea",
	Default = false,
	Callback = function(Y)
		_G.TravelDres = Y;
		if Y then
			UI.DressrosaNextQuestAt = 0;
			UI.DressrosaNextTravelAt = 0;
		elseif UI.DressrosaStatus ~= "complete" then
			UI.SetDressrosaStatus("idle");
		end;
	end,
});
UI.DressrosaStatus = "idle";
UI.DressrosaNextQuestAt = 0;
UI.DressrosaNextTravelAt = 0;
UI.DressrosaStatusLabel = Gz:AddLabel({ DoesWrap = true, Text = "Dressrosa: idle" });
function UI.SetDressrosaStatus(status)
	status = tostring(status or "working");
	if status ~= UI.DressrosaStatus then
		UI.DressrosaStatus = status;
		UI.DressrosaStatusLabel:SetText("Dressrosa: " .. status:gsub("%-", " "));
	end;
end;
task.spawn(function()
	while IdleWait(_G.TravelDres, .25) do
		if _G.TravelDres then
			local ok = pcall(function()
				if World2 then
					UI.SetDressrosaStatus("complete");
					UI.DisableToggle("BF_Toggle_Auto_Travel_Dressrosa");
					return;
				end;
				if not World1 then
					UI.SetDressrosaStatus("wrong-world");
					return;
				end;
				if (tonumber(BFDataValue("Level")) or 0) < 700 then
					UI.SetDressrosaStatus("level-700-required");
					return;
				end;
				local iceDoor = BFMapNode("Ice", "Door");
				if not iceDoor or not iceDoor:IsA("BasePart") then
					UI.SetDressrosaStatus("waiting-for-ice-door");
					return;
				end;
				local target = CFrame.new(1347.7124, 37.3751602, -1325.6488);
				local doorClosed = iceDoor.CanCollide and iceDoor.Transparency < 1;
				if doorClosed then
					local now = os.clock();
					if now >= UI.DressrosaNextQuestAt then
						UI.DressrosaNextQuestAt = now + 2;
						BFComm("DressrosaQuestProgress", "Detective");
					end;
					EquipWeapon("Key");
					BFMoveNear(target, 8);
					UI.SetDressrosaStatus("unlocking-ice-door");
					return;
				end;
				local enemy = GetConnectionEnemies("Ice Admiral");
				if enemy then
					UI.SetDressrosaStatus("fighting-ice-admiral");
					repeat
						task.wait();
						f.Kill(enemy, _G.TravelDres);
					until not _G.TravelDres or not enemy.Parent or not f.Alive(enemy);
					return;
				end;
				if not BFMoveNear(target, 15) then
					UI.SetDressrosaStatus("waiting-for-ice-admiral");
					return;
				end;
				local now = os.clock();
				if now >= UI.DressrosaNextTravelAt then
					UI.DressrosaNextTravelAt = now + 3;
					UI.SetDressrosaStatus("traveling");
					BFComm("TravelDressrosa");
				end;
			end);
			if not ok then
				UI.SetDressrosaStatus("error");
			end;
		end;
	end;
end);
UI.ZouStatus = "idle";
UI.ZouNextActionAt = 0;
UI.ZouNextTravelAt = 0;
UI.ZouStatusLabel = nil;
function UI.SetZouStatus(status)
	status = tostring(status or "working");
	if status ~= UI.ZouStatus then
		UI.ZouStatus = status;
		if UI.ZouStatusLabel then
			UI.ZouStatusLabel:SetText("Zou: " .. status:gsub("%-", " "));
		end;
	end;
end;
function UI.RequestZouTravel()
	if not _G.AutoZou or not World2 then
		return false;
	end;
	local now = os.clock();
	if now < UI.ZouNextTravelAt then
		return false;
	end;
	UI.ZouNextTravelAt = now + 3;
	UI.SetZouStatus("traveling");
	BFComm("F_", "TravelZou");
	return true;
end;
Gz:AddToggle("BF_Toggle_Auto_Zou_Quest", {
	Text = "Auto Zou Quest",
	Tooltip = "Complete Second Sea progression and travel to Third Sea",
	Default = false,
	Callback = function(Y)
		_G.AutoZou = Y;
		_G.Zou = Y;
		if Y then
			UI.ZouNextActionAt = 0;
			UI.ZouNextTravelAt = 0;
		elseif UI.ZouStatus ~= "complete" then
			UI.SetZouStatus("idle");
		end;
	end,
});
UI.ZouStatusLabel = Gz:AddLabel({ DoesWrap = true, Text = "Zou: " .. UI.ZouStatus:gsub("%-", " ") });
task.spawn(function()
	while IdleWait(_G.AutoZou, .25) do
		if _G.AutoZou then
			local ok = pcall(function()
				if World3 then
					UI.SetZouStatus("complete");
					UI.DisableToggle("BF_Toggle_Auto_Zou_Quest");
					return;
				end;
				if not World2 then
					UI.SetZouStatus("wrong-world");
					return;
				end;
				if (tonumber(BFDataValue("Level")) or 0) < 1500 then
					UI.SetZouStatus("level-1500-required");
					return;
				end;
				local bartiloProgress = BFComm("BartiloQuestProgress", "Bartilo");
				if bartiloProgress == 3 then
					local unlockables = BFComm("GetUnlockables");
					if type(unlockables) ~= "table" then
						UI.SetZouStatus("waiting-for-progress");
						return;
					end;
					if unlockables.FlamingoAccess ~= nil then
						UI.RequestZouTravel();
						local zouProgress = BFComm("ZQuestProgress", "Check");
						if zouProgress == 0 then
							local enemy = GetConnectionEnemies("rip_indra");
							if enemy then
								UI.SetZouStatus("fighting-rip-indra");
								repeat
									task.wait();
									f.Kill(enemy, _G.AutoZou);
								until not _G.AutoZou or not enemy.Parent or not f.Alive(enemy);
								if not _G.AutoZou then
									return;
								end;
								local attempts = 0;
								local progress = BFComm("ZQuestProgress", "Check");
								repeat
									task.wait(1);
									if UI.RequestZouTravel() then
										attempts = attempts + 1;
									end;
									progress = BFComm("ZQuestProgress", "Check");
								until not _G.AutoZou or progress ~= 0 or attempts >= 10;
							else
								UI.SetZouStatus("starting-zou-quest");
								local now = os.clock();
								if now >= UI.ZouNextActionAt then
									UI.ZouNextActionAt = now + 2;
									BFComm("F_", "ZQuestProgress", "Check");
									task.wait(.1);
									if _G.AutoZou then
										BFComm("F_", "ZQuestProgress", "Begin");
									end;
								end;
							end;
						elseif zouProgress == 1 then
							UI.RequestZouTravel();
						else
							local enemy = GetConnectionEnemies("Don Swan");
							if enemy then
								UI.SetZouStatus("fighting-don-swan");
								repeat
									task.wait();
									f.Kill(enemy, _G.AutoZou);
								until not _G.AutoZou or not enemy.Parent or not f.Alive(enemy);
							else
								UI.SetZouStatus("waiting-for-don-swan");
								local target = CFrame.new(2288.802, 15.1870775, 863.034607);
								if BFMoveNear(target, 8) and _G.AutoZou and f.Pos(target, 8) then
									notween(target);
								end;
							end;
						end;
					else
						UI.SetZouStatus("unlocking-flamingo-access");
						local now = os.clock();
						if now < UI.ZouNextActionAt then
							return;
						end;
						UI.ZouNextActionAt = now + 2;
						TabelDevilFruitStore = {};
						TabelDevilFruitOpen = {};
						local storedFruits = BFStoredFruits();
						if type(storedFruits) ~= "table" then
							return;
						end;
						for _, fruitData in pairs(storedFruits) do
							if type(fruitData) == "table" and type(fruitData.Name) == "string" then
								table.insert(TabelDevilFruitStore, fruitData.Name);
							end;
						end;
						local fruits = BFComm("GetFruits");
						if type(fruits) == "table" then
							for _, fruit in next, fruits do
								if type(fruit) == "table" and type(fruit.Name) == "string" and (tonumber(fruit.Price) or 0) >= 1000000 then
									table.insert(TabelDevilFruitOpen, fruit.Name);
								end;
							end;
						end;
						local handledFruit = false;
						for _, openFruit in pairs(TabelDevilFruitOpen) do
							for _, storedFruit in pairs(TabelDevilFruitStore) do
								if openFruit == storedFruit then
									if not BFFindFruitTool(storedFruit) then
										BFComm("F_", "LoadFruit", storedFruit);
									end;
									handledFruit = true;
									break;
								end;
							end;
							if handledFruit then
								break;
							end;
						end;
						BFComm("F_", "TalkTrevor", "1");
						BFComm("F_", "TalkTrevor", "2");
						BFComm("F_", "TalkTrevor", "3");
					end;
				elseif bartiloProgress == 0 then
					UI.SetZouStatus("bartilo-swan-pirates");
					if string.find(QuestText(), "Swan Pirates") and string.find(QuestText(), "50") and GuiShown("Quest") then
						local enemy = GetConnectionEnemies("Swan Pirate");
						if enemy then
							repeat
								task.wait();
								f.Kill(enemy, _G.AutoZou);
							until not _G.AutoZou or not enemy.Parent or not f.Alive(enemy) or not GuiShown("Quest");
						else
							_tp(CFrame.new(1057.92761, 137.614319, 1242.08069));
						end;
					else
						_tp(CFrame.new(-456.28952, 73.0200958, 299.895966));
					end;
				elseif bartiloProgress == 1 then
					UI.SetZouStatus("bartilo-jeremy");
					local enemy = GetConnectionEnemies("Jeremy");
					if enemy then
						repeat
							task.wait();
							f.Kill(enemy, _G.AutoZou);
						until not _G.AutoZou or not enemy.Parent or not f.Alive(enemy);
					else
						_tp(CFrame.new(2099.88159, 448.931, 648.997375));
					end;
				elseif bartiloProgress == 2 then
					UI.SetZouStatus("bartilo-maze");
					local target = CFrame.new(-1836, 11, 1714);
					if not BFMoveNear(target, 8) then
						return;
					end;
					if not _G.AutoZou then
						return;
					end;
					if f.Pos(target, 8) then
						notween(target);
					end;
					local route = {
						CFrame.new(-1850.49329, 13.1789551, 1750.89685),
						CFrame.new(-1858.87305, 19.3777466, 1712.01807),
						CFrame.new(-1803.94324, 16.5789185, 1750.89685),
						CFrame.new(-1858.55835, 16.8604317, 1724.79541),
						CFrame.new(-1869.54224, 15.987854, 1681.00659),
						CFrame.new(-1800.0979, 16.4978027, 1684.52368),
						CFrame.new(-1819.26343, 14.795166, 1717.90625),
						CFrame.new(-1813.51843, 14.8604736, 1724.79541),
					};
					for _, waypoint in ipairs(route) do
						if not _G.AutoZou then
							return;
						end;
						notween(waypoint);
						task.wait(.1);
					end;
				else
					UI.SetZouStatus("waiting-for-bartilo-progress");
				end;
			end);
			if not ok then
				UI.SetZouStatus("error");
			end;
		end;
	end;
end);
local qz = UI.Sections["Miscellanea / Quest"];
qz:AddToggle("BF_Toggle_Auto_Farm_Nearest", {
	Text = "Auto Farm Nearest",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		_G.AutoFarmNear = Y;
	end,
});
task.spawn(function()
	while IdleWait(_G.AutoFarmNear, .1) do
		if _G.AutoFarmNear then
			pcall(function()
				local enemy = BFFindNearestEnemy();
				if not enemy then
					return;
				end;
				repeat
					task.wait();
					f.Kill(enemy, _G.AutoFarmNear);
				until not _G.AutoFarmNear or not enemy.Parent or enemy.Humanoid.Health <= 0;
			end);
		end;
	end;
end);
qz:AddToggle("BF_Toggle_Auto_Factory_Raid", {
	Text = "Auto Factory Raid",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		_G.AutoFactory = Y;
		_G.FactoryRaids = Y;
	end,
});
task.spawn(function()
	while IdleWait(_G.AutoFactory, .2) do
		pcall(function()
			if _G.AutoFactory then
				local Y = BFFindLiveEnemyLike("Core");
				if Y then
					f.Kill2(Y, _G.AutoFactory);
				else
					_tp(CFrame.new(448.46756, 199.356781, -441.389252));
				end;
			end;
		end);
	end;
end);
UI.RegisterManagedFlag("AutoRaidCastle", false);
qz:AddToggle("BF_Toggle_Auto_Pirate_Raid", {
	Text = "Auto Pirate Raid",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		UI.SetManagedUserFlag("AutoRaidCastle", Y);
	end,
});
UI.PirateRaidEnemyNames = {
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
task.spawn(function()
	while IdleWait(_G.AutoRaidCastle, .2) do
		if _G.AutoRaidCastle then
			pcall(function()
				if not World3 then
					return;
				end;
				local root = BFCharacterPart();
				if not root then
					return;
				end;
				local castleCenter = CFrame.new(-5539.3115234375, 313.80053710938, -2972.3723144531);
				local raidTarget = CFrame.new(-5496.17432, 313.768921, -2841.53027, .924894512, 7.37058015e-09, .380223751, 3.5881019e-08, 1, -1.06665446e-07, -0.380223751, 1.12297109e-07, .924894512);
				if (castleCenter.Position - root.Position).Magnitude <= 500 then
					for _, enemy in pairs(workspace.Enemies:GetChildren()) do
						local enemyRoot = enemy:FindFirstChild("HumanoidRootPart");
						root = BFCharacterPart();
						if root and enemyRoot and f.Alive(enemy) and (enemyRoot.Position - root.Position).Magnitude <= 2000 then
							repeat
								task.wait();
								f.Kill(enemy, _G.AutoRaidCastle);
							until not _G.AutoRaidCastle or not enemy.Parent or not f.Alive(enemy) or not workspace.Enemies:FindFirstChild(enemy.Name);
						end;
					end;
				else
					if BFFindStoredEnemyLike(UI.PirateRaidEnemyNames) then
						BFMoveNear(raidTarget, 20);
					end;
				end;
			end);
		end;
	end;
end);
UI.RegisterManagedValue("SelectMaterial", v[1]);
UI.RegisterManagedFlag("AutoMaterial", false);
qz:AddDropdown("BF_Dropdown_Choose_Material", {
	Text = "Choose Material",
	Tooltip = "",
	Values = v,
	Default = v[1],
	Multi = false,
	Callback = function(Y)
		UI.SetManagedUserValue("SelectMaterial", Y);
	end,
});
qz:AddToggle("BF_Toggle_Auto_Materials", {
	Text = "Auto Materials",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		UI.SetManagedUserFlag("AutoMaterial", Y);
	end,
});
task.spawn(function()
	local function Y(Y, d)
		if Y:FindFirstChild("Humanoid") and (Y:FindFirstChild("HumanoidRootPart") and Y.Humanoid.Health > 0) then
			if Y.Name == d then
				repeat
					task.wait();
					f.Kill(Y, _G.AutoMaterial);
				until not _G.AutoMaterial or not Y.Parent or Y.Humanoid.Health <= 0;
			end;
		end;
	end;
	local function d()
		for Y, d in pairs((game:GetService("Workspace"))._WorldOrigin.EnemySpawns:GetChildren()) do
			for Y, R in ipairs(MMon) do
				if string.find(d.Name, R) then
					if not f.Pos(d, 10) then
						_tp(d.CFrame * CFrame.new(0, _G.MobHeight or 20, 0));
					end;
				end;
			end;
		end;
	end;
	while IdleWait(_G.AutoMaterial) do
		if _G.AutoMaterial then
			pcall(function()
				if _G.SelectMaterial then
					MaterialMon(_G.SelectMaterial);
					_tp(MPos);
				end;
				for d, R in ipairs(MMon) do
					for d, Q in pairs(workspace.Enemies:GetChildren()) do
						Y(Q, R);
					end;
				end;
				d();
			end);
		end;
	end;
end);
qz:AddToggle("BF_Toggle_Auto_Farm_Ectoplasm", {
	Text = "Auto Farm Ectoplasm",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		_G.AutoEctoplasm = Y;
	end,
});
task.spawn(function()
	while IdleWait(_G.AutoEctoplasm, T) do
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
					BFComm("requestEntrance", Vector3.new(923.21252441406, 126.9760055542, 32852.83203125));
				end;
			end;
		end);
	end;
end);
qz:AddToggle("BF_Toggle_Auto_Done_Bartilo_Quest", {
	Text = "Auto Done Bartilo Quest",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		_G.Bartilo_Quest = Y;
		if not Y then
			UI.ReleaseManagedFlag("BartiloQuest", "Level");
		end;
	end,
});
task.spawn(function()
	while IdleWait(_G.Bartilo_Quest, .1) do
		pcall(function()
			if _G.Bartilo_Quest then
				local currentLevel = tonumber(BFDataValue("Level")) or 0;
				if not World2 or currentLevel < 850 then
					UI.ReleaseManagedFlag("BartiloQuest", "Level");
					return;
				end;
				local progress = BFComm("BartiloQuestProgress", "Bartilo");
				if progress == 0 then
					UI.SuppressManagedFlag("BartiloQuest", "Level");
					if GuiShown("Quest") then
						local R = GetConnectionEnemies("Swan Pirate");
						if R then
							repeat
								task.wait();
								if not string.find(QuestText(), "Swan Pirate") then
									BFComm("AbandonQuest");
								else
									f.Kill(R, _G.Bartilo_Quest);
								end;
							until not _G.Bartilo_Quest or not f.Alive(R) or not GuiShown("Quest");
						else
							_tp(CFrame.new(970.369446, 142.653198, 1217.3667, .162079468, -4.85452638e-08, -0.986777723, 1.03357589e-08, 1, -4.74980872e-08, .986777723, -2.50063148e-09, .162079468));
						end;
					else
						local questTarget = CFrame.new(-461.533203, 72.3478546, 300.311096, .050853312, 0, -0.998706102, 0, 1, 0, .998706102, 0, .050853312);
						if BFMoveNear(questTarget, 5) then
							BFComm("StartQuest", "BartiloQuest", 1);
						end;
					end;
				elseif progress == 1 then
					UI.SuppressManagedFlag("BartiloQuest", "Level");
					local d = GetConnectionEnemies("Jeremy");
					if d then
						repeat
							task.wait();
							f.Kill(d, _G.Bartilo_Quest);
						until not _G.Bartilo_Quest or not f.Alive(d) or not GuiShown("Quest");
					else
						_tp(CFrame.new(2158.97412, 449.056244, 705.411682, -0.754199564, -4.17389057e-09, -0.656645238, -4.47752875e-08, 1, 4.50709301e-08, .656645238, 6.3393955e-08, -0.754199564));
					end;
				elseif progress == 2 then
					UI.SuppressManagedFlag("BartiloQuest", "Level");
					local mazeTarget = CFrame.new(-1830.83972, 10.5578213, 1680.60229, .979988456, -2.02152783e-08, -0.199054286, 2.20792113e-08, 1, 7.1442483e-09, .199054286, -1.13962431e-08, .979988456);
					if BFMoveNear(mazeTarget, 3) then
						local plates = BFMapNode("Dressrosa", "BartiloPlates");
						local root = d.Character and d.Character:FindFirstChild("HumanoidRootPart");
						if plates and root then
							for index = 1, 8 do
								if not _G.Bartilo_Quest then
									break;
								end;
								local plate = plates:FindFirstChild("Plate" .. index);
								if plate and plate:IsA("BasePart") then
									root.CFrame = plate.CFrame;
									task.wait(.5);
								end;
							end;
						end;
					end;
				else
					UI.ReleaseManagedFlag("BartiloQuest", "Level");
				end;
			end;
		end);
	end;
end);
_G.CitizenQuest = false;
UI.CitizenStatus = "idle";
UI.CitizenStatusLabel = nil;
UI.CitizenProgress = nil;
UI.CitizenStage = nil;
UI.CitizenNextProgressAt = 0;
UI.CitizenNextActionAt = 0;
UI.CitizenQuestTarget = CFrame.new(-12443.8671875, 332.40396118164, -7675.4892578125);
UI.CitizenForestPirates = CFrame.new(-13206.452148438, 425.89199829102, -7964.5537109375);
UI.CitizenCaptainElephant = CFrame.new(-13374.889648438, 421.27752685547, -8225.208984375);
UI.CitizenTreasure = CFrame.new(-12512.138671875, 340.39279174805, -9872.8203125);
function UI.SetCitizenStatus(status)
	status = tostring(status or "working");
	if status ~= UI.CitizenStatus then
		UI.CitizenStatus = status;
		if UI.CitizenStatusLabel then
			UI.CitizenStatusLabel:SetText("Citizen: " .. status:gsub("%-", " "));
		end;
	end;
end;
qz:AddToggle("BF_Toggle_Auto_Done_Citizen_Quest", {
	Text = "Auto Done Citizen Quest",
	Tooltip = "Complete the Forest Pirate and Captain Elephant stages, then find the Citizen treasure",
	Default = false,
	Callback = function(Y)
		_G.CitizenQuest = Y;
		if Y then
			UI.CitizenProgress = nil;
			UI.CitizenStage = nil;
			UI.CitizenNextProgressAt = 0;
			UI.CitizenNextActionAt = 0;
		else
			UI.SetCitizenStatus("idle");
		end;
	end,
});
UI.CitizenStatusLabel = qz:AddLabel({ DoesWrap = true, Text = "Citizen: idle" });
function UI.CitizenQuestStep(active)
	if not active then
		return "idle";
	end;
	if _G.AutoKenVTWO then
		return "observation-v2-controls-citizen";
	end;
	if not World3 then
		return "third-sea-required";
	end;
	if (tonumber(BFDataValue("Level")) or 0) < 1800 then
		return "level-1800-required";
	end;
	local now = os.clock();
	if now >= UI.CitizenNextProgressAt then
		UI.CitizenNextProgressAt = now + 1.5;
		local progress = BFComm("CitizenQuestProgress");
		if type(progress) == "table" then
			UI.CitizenProgress = progress;
		end;
		local stage = tonumber(BFComm("CitizenQuestProgress", "Citizen"));
		if stage ~= nil then
			UI.CitizenStage = stage;
		end;
	end;
	local progress = UI.CitizenProgress;
	if type(progress) ~= "table" then
		return "waiting-for-citizen-progress";
	end;
	local questVisible = GuiShown("Quest");
	local questText = questVisible and QuestText() or "";
	if progress.KilledBandits == false then
		if questVisible and string.find(questText, "Forest Pirate", 1, true) and string.find(questText, "50", 1, true) then
			local enemy = GetConnectionEnemies("Forest Pirate");
			if enemy then
				f.Kill(enemy, active);
				return "fighting-forest-pirates";
			end;
			BFMoveNear(UI.CitizenForestPirates, 30);
			return "waiting-for-forest-pirates";
		elseif questVisible then
			return "unrelated-quest-active";
		elseif not BFMoveNear(UI.CitizenQuestTarget, 30) then
			return "moving-to-citizen";
		elseif now >= UI.CitizenNextActionAt then
			UI.CitizenNextActionAt = now + 2;
			BFComm("StartQuest", "CitizenQuest", 1);
		end;
		return "starting-forest-pirate-quest";
	elseif progress.KilledBoss == false then
		if questVisible and string.find(questText, "Captain Elephant", 1, true) then
			local enemy = GetConnectionEnemies("Captain Elephant");
			if enemy then
				f.Kill(enemy, active);
				return "fighting-captain-elephant";
			end;
			BFMoveNear(UI.CitizenCaptainElephant, 30);
			return "waiting-for-captain-elephant";
		elseif questVisible then
			return "unrelated-quest-active";
		elseif not BFMoveNear(UI.CitizenQuestTarget, 4) then
			return "returning-to-citizen";
		elseif now >= UI.CitizenNextActionAt then
			UI.CitizenNextActionAt = now + 2;
			BFComm("CitizenQuestProgress", "Citizen");
		end;
		return "starting-captain-elephant-stage";
	elseif UI.CitizenStage == 2 then
		BFMoveNear(UI.CitizenTreasure, 5);
		return "finding-citizen-treasure";
	end;
	return "waiting-for-citizen-treasure-stage";
end;
task.spawn(function()
	while IdleWait(_G.CitizenQuest, .25) do
		if _G.CitizenQuest then
			local ok, status = pcall(UI.CitizenQuestStep, _G.CitizenQuest);
			UI.SetCitizenStatus(ok and status or "error");
		end;
	end;
end);
qz:AddToggle("BF_Toggle_Auto_Training_Dummy", {
	Text = "Auto Training Dummy",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		_G.DummyMan = Y;
	end,
});
task.spawn(function()
	while IdleWait(_G.DummyMan, T) do
		if _G.DummyMan then
			pcall(function()
				if not GuiShown("Quest") then
					BFComm("ArenaTrainer");
				else
					local Y = GetConnectionEnemies("Training Dummy");
					if Y then
						repeat
							task.wait();
							f.Kill(Y, _G.DummyMan);
						until not _G.DummyMan or not Y.Parent or Y.Humanoid.Health <= 0;
					else
						_tp(CFrame.new(3688.0051269531, 12.746943473816, 170.20953369141));
					end;
				end;
			end);
		end;
	end;
end);
qz:AddToggle("BF_Toggle_Auto_Collect_Berry", {
	Text = "Auto Collect Berry",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		_G.AutoBerry = Y;
	end,
});
task.spawn(function()
	while IdleWait(_G.AutoBerry, T) do
		if _G.AutoBerry then
			pcall(function()
				local collectionService = game:GetService("CollectionService");
				local character = d.Character;
				local root = character and character:FindFirstChild("HumanoidRootPart");
				if not root then
					return;
				end;
				local bestPrompt, bestTarget, bestDistance;
				for _, bush in ipairs(collectionService:GetTagged("BerryBush")) do
					local selected = type(BerryArray) ~= "table" or #BerryArray == 0;
					if not selected then
						for _, value in pairs(bush:GetAttributes()) do
							if table.find(BerryArray, value) then
								selected = true;
								break;
							end;
						end;
					end;
					if selected then
						local prompt = bush:FindFirstChildWhichIsA("ProximityPrompt", true);
						local part = BFFirstPart(bush);
						local target = part and part.CFrame or nil;
						if prompt and target then
							local distance = (target.Position - root.Position).Magnitude;
							if not bestDistance or distance < bestDistance then
								bestPrompt = prompt;
								bestTarget = target;
								bestDistance = distance;
							end;
						end;
					end;
				end;
				if bestPrompt and bestTarget and type(fireproximityprompt) == "function" and BFMoveNear(bestTarget, math.max(bestPrompt.MaxActivationDistance - 1, 3)) then
					pcall(fireproximityprompt, bestPrompt);
				end;
			end);
		end;
	end;
end);
UI.RegisterManagedFlag("AutoFarmChest", false);
qz:AddToggle("BF_Toggle_Auto_Collect_Chest", {
	Text = "Auto Collect Chest",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		UI.SetManagedUserFlag("AutoFarmChest", Y);
	end,
});
task.spawn(function()
	while IdleWait(_G.AutoFarmChest, T) do
		if _G.AutoFarmChest then
			pcall(function()
				local Y = game:GetService("CollectionService");
				local d = game:GetService("Players");
				local R = d.LocalPlayer;
				local Q = R.Character;
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
local BFFish = {
	RodName = "Fishing Rod",
	BaitName = "Basic Bait",
	MaxLaunchDistance = 32.5,
	Caught = 0,
	SetupAt = 0,
	RodReady = false,
	BaitReady = false,
	StatusText = nil,
	Rods = {
		"Fishing Rod",
		"Gold Rod",
		"Shark Rod",
		"Shell Rod",
		"Treasure Rod",
	},
	Baits = {
		"Basic Bait",
		"Kelp Bait",
		"Good Bait",
		"Abyssal Bait",
		"Frozen Bait",
		"Epic Bait",
		"Carnivore Bait",
	},
};
do
	local players = game:GetService("Players");
	local replicated = game:GetService("ReplicatedStorage");
	local section = UI.Sections["Miscellanea / Fishing"];
	local player = players.LocalPlayer;
	local fishReplicated = replicated:FindFirstChild("FishReplicated");
	local request = fishReplicated and fishReplicated:FindFirstChild("FishingRequest");
	local fishingClient = fishReplicated and fishReplicated:FindFirstChild("FishingClient");
	local net = replicated:FindFirstChild("Modules");
	net = net and net:FindFirstChild("Net");
	local jobs = net and net:FindFirstChild("RF/JobsRemoteFunction");
	local craft = net and net:FindFirstChild("RF/Craft");
	local waterHeight;

	-- Config.Rod.MaxLaunchDistance is 32.5 in the live game; the old hardcoded 50
	-- made the server reject the cast.
	if fishingClient then
		local config = fishingClient:FindFirstChild("Config");
		if config and config:IsA("ModuleScript") then
			local ok, result = pcall(require, config);
			if ok and type(result) == "table" and type(result.Rod) == "table" then
				BFFish.MaxLaunchDistance = tonumber(result.Rod.MaxLaunchDistance) or BFFish.MaxLaunchDistance;
			end;
		end;
	end;

	-- GetWaterHeightAtLocation now returns a callable table, not a function.
	-- The old `type(result) == "function"` check left the resolver nil, which made
	-- every cast bail out before it started.
	do
		local util = replicated:FindFirstChild("Util");
		local module = util and util:FindFirstChild("GetWaterHeightAtLocation");
		if module and module:IsA("ModuleScript") then
			local ok, result = pcall(require, module);
			if ok then
				if type(result) == "function" then
					waterHeight = result;
				elseif type(result) == "table" then
					local direct = rawget(result, "getWaterHeightAtLocation");
					if type(direct) == "function" then
						waterHeight = direct;
					else
						local meta = getmetatable(result);
						if type(meta) == "table" and type(rawget(meta, "__call")) == "function" then
							waterHeight = function(position)
								return result(position);
							end;
						end;
					end;
				end;
			end;
		end;
	end;

	function BFFish.WaterHeight(position)
		if not waterHeight then
			return nil;
		end;
		local ok, height = pcall(waterHeight, position);
		if ok and type(height) == "number" then
			return height;
		end;
		return nil;
	end;

	function BFFish.Status(value)
		local text = "Fishing: " .. tostring(value);
		if text == BFFish.StatusText then
			return;
		end;
		BFFish.StatusText = text;
		local label = BFFish.StatusLabel;
		if label and type(label.SetText) == "function" then
			pcall(label.SetText, label, text);
		end;
	end;
	UI.SetFishingStatus = BFFish.Status;

	function BFFish.FindRod(rodName)
		local character = player.Character;
		local backpack = player:FindFirstChild("Backpack");
		return (backpack and backpack:FindFirstChild(rodName)) or (character and character:FindFirstChild(rodName)) or nil;
	end;

	function BFFish.Owns(name)
		if type(UI.InventorySnapshot) ~= "function" then
			return false;
		end;
		for _, item in pairs(UI.InventorySnapshot()) do
			if type(item) == "table" and item.Name == name and (tonumber(item.Count or item.Quantity) or 0) > 0 then
				return true;
			end;
		end;
		return false;
	end;

	-- The old version re-ran the whole rod/bait setup (two server invokes plus a
	-- 0.5s yield) on every single loop tick, which reset the cast each cycle.
	function BFFish.Setup(force)
		if not jobs then
			return;
		end;
		local now = os.clock();
		if not force and BFFish.RodReady and BFFish.BaitReady and now - BFFish.SetupAt < 30 then
			return;
		end;
		BFFish.SetupAt = now;
		local rodName = BFFish.RodName;
		if not BFFish.FindRod(rodName) then
			pcall(function()
				jobs:InvokeServer("FishingNPC", "FirstTimeFreeRod");
			end);
			pcall(function()
				jobs:InvokeServer("LoadItem", rodName, { "Gear" });
			end);
			task.wait(.5);
		end;
		BFFish.RodReady = BFFish.FindRod(rodName) ~= nil;
		local data = player:FindFirstChild("Data");
		local fishingData = data and data:FindFirstChild("FishingData");
		if not fishingData then
			BFFish.BaitReady = true;
			return;
		end;
		local selected = fishingData:GetAttribute("SelectedBait");
		if selected ~= nil and selected ~= "None" and selected ~= "" then
			BFFish.BaitReady = true;
			return;
		end;
		if BFFish.Owns(BFFish.BaitName) then
			pcall(function()
				jobs:InvokeServer("LoadItem", BFFish.BaitName, { "Usables" });
			end);
			task.wait(.3);
		elseif craft then
			pcall(function()
				craft:InvokeServer("Craft", BFFish.BaitName);
			end);
			task.wait(1);
		end;
		selected = fishingData:GetAttribute("SelectedBait");
		BFFish.BaitReady = selected ~= nil and selected ~= "None" and selected ~= "";
	end;

	function BFFish.Equip()
		local character = player.Character;
		local humanoid = character and character:FindFirstChildOfClass("Humanoid");
		if not character or not humanoid then
			return nil;
		end;
		local equipped = character:FindFirstChild(BFFish.RodName);
		if equipped then
			return equipped;
		end;
		local backpack = player:FindFirstChild("Backpack");
		local stored = backpack and backpack:FindFirstChild(BFFish.RodName);
		if stored then
			humanoid:EquipTool(stored);
			task.wait(.25);
			return character:FindFirstChild(BFFish.RodName);
		end;
		return nil;
	end;

	function BFFish.CastPosition()
		local character = player.Character;
		local root = character and character:FindFirstChild("HumanoidRootPart");
		if not root then
			return nil;
		end;
		local head = character:FindFirstChild("Head") or root;
		local ignore = { character };
		local characters = workspace:FindFirstChild("Characters");
		local enemies = workspace:FindFirstChild("Enemies");
		if characters then
			table.insert(ignore, characters);
		end;
		if enemies then
			table.insert(ignore, enemies);
		end;
		local surface = BFFish.WaterHeight(root.Position);
		local direction = root.CFrame.LookVector * BFFish.MaxLaunchDistance;
		local hitPart, hitPosition = workspace:FindPartOnRayWithIgnoreList(Ray.new(head.Position, direction), ignore);
		local target = (hitPart and hitPosition) or (root.Position + root.CFrame.LookVector * (BFFish.MaxLaunchDistance * .6));
		if surface then
			return Vector3.new(target.X, surface, target.Z);
		end;
		return Vector3.new(target.X, root.Position.Y - 10, target.Z);
	end;

	function BFFish.Cast()
		if not request then
			return false;
		end;
		local target = BFFish.CastPosition();
		if not target then
			return false;
		end;
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart");
		local strength = BFFish.MaxLaunchDistance;
		if root then
			strength = math.clamp((target - root.Position).Magnitude, 1, BFFish.MaxLaunchDistance);
		end;
		if not pcall(function()
			request:InvokeServer("StartCasting");
		end) then
			return false;
		end;
		task.wait(.35);
		return (pcall(function()
			request:InvokeServer("CastLineAtLocation", target, strength, true);
		end));
	end;

	-- Verified against the live game: Catch(1, 1, 1) returns true and the fish
	-- lands. The old Catching(1) / Catch(1) signature was silently discarded.
	function BFFish.Catch()
		if not request then
			return false;
		end;
		pcall(function()
			request:InvokeServer("Catching", true, { fastBite = true });
		end);
		task.wait(.4);
		local ok, landed = pcall(function()
			return request:InvokeServer("Catch", 1, 1, 1);
		end);
		task.wait(.2);
		pcall(function()
			request:InvokeServer("ReeledIn");
		end);
		return ok and landed == true;
	end;

	function BFFish.Abort()
		if not request then
			return false;
		end;
		return (pcall(function()
			request:InvokeServer("ReeledIn");
		end));
	end;

	_G.SelectedRod = _G.SelectedRod or BFFish.RodName;
	_G.SelectedBait = _G.SelectedBait or BFFish.BaitName;

	section:AddDropdown("BF_Dropdown_Select_Fishing_Rod", {
		Text = "Select Fishing Rod",
		Tooltip = "",
		Values = BFFish.Rods,
		Default = "Fishing Rod",
		Callback = function(value)
			if type(value) == "string" and value ~= "" then
				BFFish.RodName = value;
				_G.SelectedRod = value;
				BFFish.RodReady = false;
			end;
		end,
	});
	section:AddDropdown("BF_Dropdown_Select_Bait", {
		Text = "Select Bait",
		Tooltip = "",
		Values = BFFish.Baits,
		Default = "Basic Bait",
		Callback = function(value)
			if type(value) == "string" and value ~= "" then
				BFFish.BaitName = value;
				_G.SelectedBait = value;
				BFFish.BaitReady = false;
			end;
		end,
	});
	section:AddToggle("BF_Toggle_Auto_Fishing", {
		Text = "Auto Fishing",
		Tooltip = "",
		Default = false,
		Callback = function(value)
			_G.AutoFishing = value;
			if value then
				BFFish.RodReady = false;
				BFFish.BaitReady = false;
				BFFish.SetupAt = 0;
			end;
		end,
	});
	BFFish.StatusLabel = section:AddLabel({ DoesWrap = true, Text = "Fishing: idle" });

	task.spawn(function()
		local lastState, stateSince;
		while IdleWait(_G.AutoFishing, .25) do
			if not _G.AutoFishing then
				lastState, stateSince = nil, nil;
				BFFish.Status("idle");
			else
				pcall(function()
					local character = player.Character;
					local humanoid = character and character:FindFirstChildOfClass("Humanoid");
					local root = character and character:FindFirstChild("HumanoidRootPart");
					if not character or not root or not humanoid or humanoid.Health <= 0 then
						BFFish.RodReady = false;
						BFFish.Status("waiting for character");
						task.wait(1);
						return;
					end;
					BFFish.Setup(false);
					local rod = BFFish.Equip();
					if not rod then
						BFFish.RodReady = false;
						BFFish.Status("no " .. tostring(BFFish.RodName) .. " available");
						task.wait(1);
						return;
					end;
					-- ServerState is authoritative: ReeledIn -> Fishing -> Biting.
					-- The client-only State attribute desyncs when the hub drives the
					-- remotes directly, which is why the old loop stalled.
					local state = rod:GetAttribute("ServerState") or rod:GetAttribute("State");
					if state ~= lastState then
						lastState = state;
						stateSince = os.clock();
					end;
					if state == "Biting" then
						if BFFish.Catch() then
							BFFish.Caught = BFFish.Caught + 1;
						end;
						BFFish.Status("caught " .. BFFish.Caught);
						task.wait(.5);
					elseif state == "ReeledIn" or state == nil then
						BFFish.Status("casting (caught " .. BFFish.Caught .. ")");
						BFFish.Cast();
						task.wait(.8);
					else
						BFFish.Status(tostring(state) .. " (caught " .. BFFish.Caught .. ")");
						if stateSince and os.clock() - stateSince > 45 then
							BFFish.Abort();
							stateSince = os.clock();
						end;
					end;
				end);
			end;
		end;
	end);
end;
-- Gacha status. The live banner data comes from RF/GachaNetworkRF:
--   {Context = "GetInfo"}     -> array of {StorageName, Chance, RollGuarantee}
--   {Context = "GetHardPity"} -> current hard pity counter
-- and the box rotation / roll cost from Modules.Gacha.SharedGachaUtil.
local BFGacha = {
	Banner = "PremiumXmasGacha25",
	Box = nil,
	Enabled = false,
	CostName = nil,
	CostValue = nil,
	HardPity = 0,
	Rewards = {},
	Week = nil,
	RotatesIn = nil,
	StatusLabel = nil,
	RewardLabel = nil,
	LastText = nil,
	LastRewardText = nil,
	Refreshing = false,
};
do
	local section = UI.Sections["Gacha"];
	if section then
		local function util()
			local modules = Q:FindFirstChild("Modules");
			local gacha = modules and modules:FindFirstChild("Gacha");
			local shared = gacha and gacha:FindFirstChild("SharedGachaUtil");
			if not shared or not shared:IsA("ModuleScript") then
				return nil;
			end;
			local ok, result = pcall(require, shared);
			if ok and type(result) == "table" then
				return result;
			end;
			return nil;
		end;

		local function query(context)
			local remote = NetRemote("RF/GachaNetworkRF");
			if not remote or not remote:IsA("RemoteFunction") then
				return nil;
			end;
			local ok, result = pcall(remote.InvokeServer, remote, {
				Context = context,
				BoxName = BFGacha.Banner,
			});
			if ok then
				return result;
			end;
			return nil;
		end;
		BFGacha.Query = query;

		local function setLabel(label, key, text)
			if BFGacha[key] == text then
				return;
			end;
			BFGacha[key] = text;
			if label and type(label.SetText) == "function" then
				pcall(label.SetText, label, text);
			end;
		end;

		function BFGacha.Refresh()
			if BFGacha.Refreshing then
				return;
			end;
			BFGacha.Refreshing = true;
			local shared = util();
			if shared then
				local ok, week = pcall(shared.getCurrentWeekName);
				BFGacha.Week = ok and week or nil;
				BFGacha.RotatesIn = tonumber(shared.GACHA_ROTATES_IN);
				if BFGacha.Week and type(shared.getGachaFromWeekName) == "function" then
					local okBox, box = pcall(shared.getGachaFromWeekName, BFGacha.Week);
					if okBox and type(box) == "table" then
						BFGacha.Box = tostring(box.BOX_NAME or "?");
						BFGacha.Enabled = box.ENABLED == true;
						if type(box.ROLL_COST) == "table" then
							BFGacha.CostName = box.ROLL_COST.Name and tostring(box.ROLL_COST.Name) or nil;
							BFGacha.CostValue = tonumber(box.ROLL_COST.Value);
						end;
					end;
				end;
			end;
			local pity = query("GetHardPity");
			BFGacha.HardPity = tonumber(pity) or BFGacha.HardPity or 0;
			local info = query("GetInfo");
			if type(info) == "table" then
				local rewards = {};
				for _, entry in pairs(info) do
					if type(entry) == "table" and entry.StorageName then
						table.insert(rewards, {
							Name = tostring(entry.StorageName),
							Chance = tonumber(entry.Chance) or 0,
							Guarantee = tonumber(entry.RollGuarantee),
						});
					end;
				end;
				table.sort(rewards, function(a, b)
					return a.Chance > b.Chance;
				end);
				BFGacha.Rewards = rewards;
			end;
			BFGacha.Refreshing = false;
			BFGacha.Render();
		end;

		function BFGacha.Render()
			local parts = {};
			table.insert(parts, "Banner: " .. tostring(BFGacha.Banner));
			if BFGacha.Box then
				table.insert(parts, "Rotation: " .. tostring(BFGacha.Box) .. (BFGacha.Week and (" (" .. tostring(BFGacha.Week) .. ")") or ""));
			end;
			table.insert(parts, "Event box: " .. (BFGacha.Enabled and "open" or "closed"));
			if BFGacha.CostValue then
				local owned = BFGacha.CostName and BFGacha.Balance(BFGacha.CostName) or nil;
				table.insert(parts, "Cost: " .. tostring(BFGacha.CostValue) .. " " .. tostring(BFGacha.CostName or "?")
					.. (owned and (" | you have " .. tostring(owned)) or ""));
			end;
			table.insert(parts, "Hard pity: " .. tostring(BFGacha.HardPity));
			setLabel(BFGacha.StatusLabel, "LastText", "Gacha\n" .. table.concat(parts, "\n"));

			local lines = {};
			for index, reward in ipairs(BFGacha.Rewards) do
				if index > 8 then
					break;
				end;
				local line = string.format("%s  %.2f%%", reward.Name, reward.Chance * 100);
				if reward.Guarantee then
					line = line .. string.format("  (guaranteed by %d)", reward.Guarantee);
				end;
				table.insert(lines, line);
			end;
			if #lines == 0 then
				lines[1] = "no reward table available";
			end;
			setLabel(BFGacha.RewardLabel, "LastRewardText", "Rewards\n" .. table.concat(lines, "\n"));
		end;

		function BFGacha.Balance(currencyName)
			if type(currencyName) ~= "string" then
				return nil;
			end;
			local data = d:FindFirstChild("Data");
			local direct = data and data:FindFirstChild(currencyName);
			if direct and typeof(direct.Value) == "number" then
				return direct.Value;
			end;
			for _, item in pairs(inventorySnapshot()) do
				if type(item) == "table" and item.Name == currencyName then
					return tonumber(item.Count) or 0;
				end;
			end;
			return nil;
		end;

		BFGacha.StatusLabel = section:AddLabel({ DoesWrap = true, Text = "Gacha: loading" });
		BFGacha.RewardLabel = section:AddLabel({ DoesWrap = true, Text = "Rewards: loading" });
		section:AddDropdown("BF_Dropdown_Gacha_Banner", {
			Text = "Banner",
			Tooltip = "Which gacha box the status and rolls target",
			Values = { "PremiumXmasGacha25", "GachaData", "SummerWeek2Gacha", "SummerWeek3Gacha", "SummerWeek4Gacha", "SummerWeek5Gacha" },
			Default = "PremiumXmasGacha25",
			Callback = function(value)
				if type(value) == "string" and value ~= "" then
					BFGacha.Banner = value;
					task.spawn(BFGacha.Refresh);
				end;
			end,
		});
		section:AddButton({
			Text = "Refresh Gacha Status",
			Tooltip = "Re-read banner odds and pity from the server",
			Func = function()
				task.spawn(BFGacha.Refresh);
			end,
		});
		task.spawn(function()
			task.wait(2);
			while not UI.Stopped do
				pcall(BFGacha.Refresh);
				task.wait(30);
			end;
		end);
	end;
end;
local IF = UI.Sections["Miscellanea / Mastery"];
local WF = { "Cake", "Bone" };
SelectIsland = SelectIsland or "Cake";
IF:AddDropdown("BF_Dropdown_Choose_Island", {
	Text = "Choose Island",
	Tooltip = "",
	Values = WF,
	Default = "Cake",
	Callback = function(Y)
		SelectIsland = Y;
	end,
});
local selectedMastery = "Blox Fruit";
local autoMasterySelected = false;
local function ApplySelectedMastery()
	_G.FarmMastery_Dev = autoMasterySelected and selectedMastery == "Blox Fruit";
	_G.FarmMastery_G = autoMasterySelected and selectedMastery == "Gun";
	_G.FarmMastery_S = autoMasterySelected and selectedMastery == "Sword";
	if not _G.FarmMastery_S and type(UI.SetSwordMasteryStatus) == "function" then
		UI.SetSwordMasteryStatus("idle");
	end;
end;
IF:AddDropdown("BF_Dropdown_Selected_Mastery", {
	Text = "Mastery Type",
	Tooltip = "Choose which weapon category to master",
	Values = { "Blox Fruit", "Gun", "Sword" },
	Default = "Blox Fruit",
	Callback = function(Y)
		selectedMastery = Y;
		ApplySelectedMastery();
	end,
});
IF:AddToggle("BF_Toggle_Auto_Mastery_Selected", {
	Text = "Auto Mastery Selected",
	Tooltip = "Farm mastery for the selected weapon category",
	Default = false,
	Callback = function(Y)
		autoMasterySelected = Y;
		ApplySelectedMastery();
	end,
});
UI.SwordMastery = {
	Selected = nil,
	Lock = 600,
	AutoSwitch = false,
	Values = {},
	Dropdown = nil,
	StatusLabel = nil,
};
function UI.SwordMasteryValues()
	local values = {};
	local seen = {};
	for _, item in pairs(inventorySnapshot()) do
		if type(item) == "table" and item.Type == "Sword" and type(item.Name) == "string" and item.Name ~= "" and not seen[item.Name] then
			seen[item.Name] = true;
			values[#values + 1] = item.Name;
		end;
	end;
	table.sort(values);
	table.insert(values, 1, "Automatic");
	if #values == 1 then
		values[2] = "No Swords Found";
	end;
	return values;
end;
function UI.SetSwordMasteryStatus(value)
	local label = UI.SwordMastery.StatusLabel;
	if label then
		pcall(label.SetText, label, "Sword Mastery: " .. tostring(value));
	end;
end;
function UI.RefreshSwordMasteryList(notify)
	local state = UI.SwordMastery;
	local values = UI.SwordMasteryValues();
	state.Values = values;
	local selected = state.Selected;
	if not table.find(values, selected) then
		selected = "Automatic";
		state.Selected = nil;
	end;
	if state.Dropdown then
		pcall(state.Dropdown.SetValues, state.Dropdown, values);
		pcall(state.Dropdown.SetValue, state.Dropdown, selected or "Automatic");
	end;
	if notify then
		UI.Library:Notify("Sword list refreshed (" .. tostring(math.max(#values - 1 - (values[2] == "No Swords Found" and 1 or 0), 0)) .. ")", 4);
	end;
	return values;
end;
UI.SwordMastery.Values = UI.SwordMasteryValues();
UI.SwordMastery.Selected = nil;
UI.SwordMastery.Dropdown = UI.Sections["Sword Mastery"]:AddDropdown("BF_Dropdown_Sword_Mastery_Select", {
	Text = "Select Sword",
	Tooltip = "Choose the sword used by Auto Mastery Selected",
	Values = UI.SwordMastery.Values,
	Default = "Automatic",
	Multi = false,
	Callback = function(value)
		UI.SwordMastery.Selected = value ~= "Automatic" and value ~= "No Swords Found" and value or nil;
		if UI.SwordMastery.Selected then
			SwordName = UI.SwordMastery.Selected;
		end;
	end,
});
UI.Sections["Sword Mastery"]:AddButton({
	Text = "Refresh Sword List",
	Tooltip = "Reload owned swords from inventory",
	Func = function()
		UI.RefreshSwordMasteryList(true);
	end,
});
UI.Sections["Sword Mastery"]:AddSlider("BF_Slider_Sword_Mastery_Lock", {
	Text = "Mastery Level Lock",
	Tooltip = "Stop or switch when the selected sword reaches this mastery",
	Min = 1,
	Max = 600,
	Default = 600,
	Rounding = 0,
	Callback = function(value)
		UI.SwordMastery.Lock = tonumber(value) or 600;
	end,
});
UI.Sections["Sword Mastery"]:AddToggle("BF_Toggle_Auto_Switch_Sword", {
	Text = "Auto Switch Sword",
	Tooltip = "Choose the lowest-mastery owned sword below the lock",
	Default = false,
	Callback = function(value)
		UI.SwordMastery.AutoSwitch = value == true;
		if UI.SwordMastery.AutoSwitch then
			-- Drop the pin so the next tick re-picks the lowest sword immediately.
			UI.SwordMastery.Selected = nil;
			UI.RefreshSwordMasteryList(false);
		end;
	end,
});
UI.SwordMastery.StatusLabel = UI.Sections["Sword Mastery"]:AddLabel({ DoesWrap = true, Text = "Sword Mastery: idle" });
-- The hub loads before the inventory has replicated, so the first sword list is
-- almost always empty. Refresh it once real items show up instead of forcing the
-- user to hit "Refresh Sword List" by hand.
task.spawn(function()
	local seen = 0;
	while not UI.Stopped do
		local ok = pcall(function()
			local count = 0;
			for _, item in pairs(inventorySnapshot()) do
				if type(item) == "table" and item.Type == "Sword" then
					count = count + 1;
				end;
			end;
			if count ~= seen then
				seen = count;
				UI.RefreshSwordMasteryList(false);
			end;
		end);
		if not ok then
			task.wait(5);
		end;
		task.wait(seen > 0 and 15 or 3);
	end;
end);
UI.Sections["Sword Mastery"]:AddLabel({ DoesWrap = true, Text = "Select Sword as the mastery type, then enable Auto Mastery Selected." });

UI.Library:GiveSignal(W.RenderStepped:Connect(function()
	if UI.Stopped then
		return;
	end;
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
end));
task.spawn(function()
	while IdleWait(_G.FarmMastery_Dev, T) do
		if _G.FarmMastery_Dev then
			pcall(function()
				if SelectIsland == "Cake" then
					local Y = BFFindLiveEnemyLike(p);
					if Y then
						HealthM = (Y.Humanoid.MaxHealth * 70) / 100;
						repeat
							task.wait();
							MousePos = Y.HumanoidRootPart.Position;
							f.Mas(Y, _G.FarmMastery_Dev);
						until _G.FarmMastery_Dev == false or not Y.Parent or not f.Alive(Y);
					else
						_tp(CFrame.new(-1943.6765136719, 251.50956726074, -12337.880859375));
					end;
				elseif SelectIsland == "Bone" then
					local Y = BFFindLiveEnemyLike(E);
					if Y then
						HealthM = (Y.Humanoid.MaxHealth * 70) / 100;
						repeat
							task.wait();
							MousePos = Y.HumanoidRootPart.Position;
							f.Mas(Y, _G.FarmMastery_Dev);
						until _G.FarmMastery_Dev == false or not Y.Parent or not f.Alive(Y);
					else
						_tp(CFrame.new(-9495.6806640625, 453.58624267578, 5977.3486328125));
					end;
				end;
			end);
		end;
	end;
end);
task.spawn(function()
	while IdleWait(_G.FarmMastery_G, T) do
		if _G.FarmMastery_G then
			pcall(function()
				local enemyNames = SelectIsland == "Bone" and E or p;
				local destination = SelectIsland == "Bone" and CFrame.new(-9495.6806640625, 453.58624267578, 5977.3486328125) or CFrame.new(-1943.6765136719, 251.50956726074, -12337.880859375);
				local target = BFFindLiveEnemyLike(enemyNames);
				if not target then
					_tp(destination);
					return;
				end;
				HealthM = (target.Humanoid.MaxHealth * 70) / 100;
				repeat
					task.wait();
					local root = target:FindFirstChild("HumanoidRootPart");
					if not root then
						break;
					end;
					MousePos = root.Position;
					f.Masgun(target, _G.FarmMastery_G);
					local tool = i and i:FindFirstChildOfClass("Tool");
					if tool and tool.ToolTip == "Gun" then
						if tool.Name == "Skull Guitar" then
							b = true;
							local remote = tool:FindFirstChild("RemoteEvent");
							if remote then
								pcall(remote.FireServer, remote, "TAP", MousePos);
							end;
						else
							b = false;
							local remote = NetRemote("RE/ShootGunEvent");
							if remote then
								pcall(remote.FireServer, remote, MousePos, { root });
							end;
						end;
						if _G.FarmMastery_G then
							K:SendMouseButtonEvent(0, 0, 0, true, game, 1);
							task.wait(.05);
							K:SendMouseButtonEvent(0, 0, 0, false, game, 1);
							task.wait(.05);
						end;
					end;
				until not _G.FarmMastery_G or not target.Parent or not f.Alive(target);
				b = false;
			end);
		end;
	end;
end);
BFMasterySwordCandidate = function()
	local state = UI.SwordMastery;
	local limit = math.clamp(tonumber(state.Lock) or 600, 1, 600);
	local selected = state.Selected;
	local selectedMastery;
	local bestName;
	local bestMastery = math.huge;
	for _, item in pairs(inventorySnapshot()) do
		if type(item) == "table" and item.Type == "Sword" then
			local mastery = tonumber(item.Mastery) or 0;
			if item.Name == selected then
				selectedMastery = mastery;
			end;
			if mastery < limit and mastery < bestMastery then
				bestName = item.Name;
				bestMastery = mastery;
			end;
		end;
	end;
	-- With Auto Switch on, always ride the lowest-mastery sword that is still under
	-- the lock. The old order returned the pinned sword first, so the toggle only
	-- ever did anything after that one sword had already maxed out.
	if state.AutoSwitch and bestName then
		if bestName ~= selected then
			state.Selected = bestName;
			SwordName = bestName;
			if state.Dropdown then
				pcall(state.Dropdown.SetValue, state.Dropdown, bestName);
			end;
		end;
		return bestName, bestMastery, limit;
	end;
	if selected and selectedMastery and selectedMastery < limit then
		return selected, selectedMastery, limit;
	end;
	if selected and selectedMastery == nil then
		local fallback = BFItemMasteryLike(selected);
		if fallback and fallback >= limit then
			return nil, fallback, limit;
		end;
		return selected, fallback, limit;
	end;
	if selected and not state.AutoSwitch then
		return nil, selectedMastery, limit;
	end;
	if selected and state.AutoSwitch and bestName and bestName ~= selected then
		state.Selected = bestName;
		if state.Dropdown then
			pcall(state.Dropdown.SetValue, state.Dropdown, bestName);
		end;
	end;
	return bestName, bestMastery, limit;
end;
task.spawn(function()
	while IdleWait(_G.FarmMastery_S, T) do
		if _G.FarmMastery_S then
			pcall(function()
				local swordName, mastery, limit = BFMasterySwordCandidate();
				if not swordName then
					UI.SetSwordMasteryStatus(UI.SwordMastery.Selected and (UI.SwordMastery.Selected .. " complete") or "all swords complete");
					UI.DisableToggle("BF_Toggle_Auto_Mastery_Selected");
					task.wait(1);
					return;
				end;
				UI.SetSwordMasteryStatus(swordName .. " [" .. tostring(mastery or BFItemMasteryLike(swordName)) .. "/" .. tostring(limit) .. "]");
				SwordName = swordName;
				if not GetBP(swordName) then
					BFComm("LoadItem", swordName);
					task.wait(.5);
					return;
				end;
				local enemyNames = SelectIsland == "Bone" and E or p;
				local target = BFFindLiveEnemyLike(enemyNames);
				if not target then
					local destination = SelectIsland == "Bone" and CFrame.new(-9495.6806640625, 453.58624267578, 5977.3486328125) or CFrame.new(-1943.6765136719, 251.50956726074, -12337.880859375);
					BFMoveNear(destination, 40);
					return;
				end;
				repeat
					task.wait();
					f.Sword(target, _G.FarmMastery_S);
				until not _G.FarmMastery_S or not target.Parent or target.Humanoid.Health <= 0;
			end);
		end;
	end;
end);
UI.SpawnNotifications = {
	BossEnabled = false,
	RareEnabled = false,
	SeenBosses = setmetatable({}, { __mode = "k" }),
	SeenIslands = setmetatable({}, { __mode = "k" }),
	SeenMirageAttribute = false,
	RareKeys = {
		mysticisland = "Mirage Island",
		mirageisland = "Mirage Island",
		kitsuneisland = "Kitsune Island",
		prehistoricisland = "Prehistoric Island",
	},
	BossKeys = {},
	CollectionService = game:GetService("CollectionService"),
};
function UI.BuildBossNotificationKeys()
	local keys = {};
	for _, name in ipairs(U) do
		keys[BFNameKey(name)] = true;
	end;
	return keys;
end;
UI.SpawnNotifications.BossKeys = UI.BuildBossNotificationKeys();
function UI.IsBossNotificationTarget(model)
	if not model or not model:IsA("Model") then
		return false;
	end;
	local humanoid = model:FindFirstChildOfClass("Humanoid");
	if not humanoid or humanoid.Health <= 0 then
		return false;
	end;
	for _, attribute in ipairs({ "Boss", "IsBoss", "RaidBoss" }) do
		if model:GetAttribute(attribute) == true or humanoid:GetAttribute(attribute) == true then
			return true;
		end;
	end;
	local tagged = false;
	pcall(function()
		tagged = UI.SpawnNotifications.CollectionService:HasTag(model, "Boss");
	end);
	if tagged then
		return true;
	end;
	local key = BFNameKey(model.Name);
	local displayKey = BFNameKey(humanoid.DisplayName);
	if string.find(key, "boss", 1, true) or string.find(displayKey, "boss", 1, true) then
		return true;
	end;
	for bossKey in pairs(UI.SpawnNotifications.BossKeys) do
		if bossKey ~= "" and (string.find(key, bossKey, 1, true) or string.find(displayKey, bossKey, 1, true)) then
			return true;
		end;
	end;
	return false;
end;
function UI.NotifyBossSpawn(instance)
	if not UI.SpawnNotifications.BossEnabled then
		return;
	end;
	local model = instance and instance:IsA("Humanoid") and instance.Parent or instance;
	if not model or UI.SpawnNotifications.SeenBosses[model] or not UI.IsBossNotificationTarget(model) then
		return;
	end;
	UI.SpawnNotifications.SeenBosses[model] = true;
	UI.Library:Notify("Boss Spawned: " .. tostring(model.Name), 10);
end;
function UI.RareIslandName(instance)
	if not instance or not (instance:IsA("Model") or instance:IsA("Folder") or instance:IsA("BasePart")) then
		return nil;
	end;
	return UI.SpawnNotifications.RareKeys[BFNameKey(instance.Name)];
end;
function UI.NotifyRareIsland(instance)
	if not UI.SpawnNotifications.RareEnabled or UI.SpawnNotifications.SeenIslands[instance] then
		return;
	end;
	local name = UI.RareIslandName(instance);
	if not name then
		return;
	end;
	UI.SpawnNotifications.SeenIslands[instance] = true;
	UI.Library:Notify("Rare Island: " .. name .. " spawned!", 10);
end;
function UI.ScanBossNotifications()
	local enemies = workspace:FindFirstChild("Enemies");
	for _, model in ipairs(enemies and enemies:GetChildren() or {}) do
		UI.NotifyBossSpawn(model);
	end;
end;
function UI.ScanRareIslandNotifications()
	for _, instance in ipairs(workspace:GetChildren()) do
		UI.NotifyRareIsland(instance);
	end;
	local map = workspace:FindFirstChild("Map");
	for _, instance in ipairs(map and map:GetChildren() or {}) do
		UI.NotifyRareIsland(instance);
	end;
end;
function UI.CheckMirageNotificationAttribute()
	local active = d:GetAttribute("MirageIsland") or d:GetAttribute("Mirage");
	if active and UI.SpawnNotifications.RareEnabled and not UI.SpawnNotifications.SeenMirageAttribute then
		UI.SpawnNotifications.SeenMirageAttribute = true;
		UI.Library:Notify("Rare Island: Mirage Island spawned!", 10);
	elseif not active then
		UI.SpawnNotifications.SeenMirageAttribute = false;
	end;
end;
UI.Sections["BF/Notifications"]:AddToggle("BF_Toggle_Boss_Spawn_Notification", {
	Text = "Boss Spawn Notification",
	Tooltip = "Alert when a live boss model appears",
	Default = false,
	Callback = function(value)
		UI.SpawnNotifications.BossEnabled = value == true;
		UI.SpawnNotifications.SeenBosses = setmetatable({}, { __mode = "k" });
		if value then
			UI.ScanBossNotifications();
		end;
	end,
});
UI.Sections["BF/Notifications"]:AddToggle("BF_Toggle_Rare_Island_Notification", {
	Text = "Rare Island Spawn Notification",
	Tooltip = "Alert for Mirage, Kitsune, and Prehistoric islands",
	Default = false,
	Callback = function(value)
		UI.SpawnNotifications.RareEnabled = value == true;
		UI.SpawnNotifications.SeenIslands = setmetatable({}, { __mode = "k" });
		UI.SpawnNotifications.SeenMirageAttribute = false;
		if value then
			UI.ScanRareIslandNotifications();
			UI.CheckMirageNotificationAttribute();
		end;
	end,
});
UI.Sections["BF/Notifications"]:AddLabel({ DoesWrap = true, Text = "Alerts are event-driven and only repeat for a newly spawned instance." });
UI.Library:GiveSignal(workspace.DescendantAdded:Connect(function(instance)
	if not UI.SpawnNotifications.BossEnabled and not UI.SpawnNotifications.RareEnabled then
		return;
	end;
	pcall(function()
		if instance:IsA("Humanoid") then
			UI.NotifyBossSpawn(instance);
		elseif instance:IsA("Model") then
			UI.NotifyBossSpawn(instance);
			UI.NotifyRareIsland(instance);
		elseif instance:IsA("Folder") or instance:IsA("BasePart") then
			UI.NotifyRareIsland(instance);
		end;
	end);
end));
UI.Library:GiveSignal(d:GetAttributeChangedSignal("MirageIsland"):Connect(UI.CheckMirageNotificationAttribute));
UI.Library:GiveSignal(d:GetAttributeChangedSignal("Mirage"):Connect(UI.CheckMirageNotificationAttribute));
BFEliteEnemyNames = { "Diablo", "Urban", "Deandre" };
BFEliteStep = function(active)
		if not active then
			return;
		end;
		if GuiShown("Quest") then
			if string.find(QuestText(), "Diablo", 1, true) or string.find(QuestText(), "Urban", 1, true) or string.find(QuestText(), "Deandre", 1, true) then
				local enemy = BFFindLiveEnemyLike(BFEliteEnemyNames);
				if enemy then
					f.Kill2(enemy, active);
					return;
				end;
				local stored = BFFindStoredEnemyLike(BFEliteEnemyNames);
				if stored then
					BFMoveNear(stored, 25);
				end;
			else
				BFComm("AbandonQuest");
			end;
		else
			BFComm("EliteHunter");
		end;
	end;
BFCakeEnemyNames = { "Cookie Crafter", "Cake Guard", "Baking Staff", "Head Baker" };
BFCocoaEnemyNames = { "Cocoa Warrior", "Chocolate Bar Battler" };
BFCakeFarmStep = function(active)
		local enemy = BFFindLiveEnemyLike(BFCakeEnemyNames);
		if enemy then
			f.Kill2(enemy, active);
		else
			BFMoveNear(CFrame.new(-2077, 252, -12373), 40);
		end;
	end;
BFUnlockResponseComplete = function(value)
		if value == true then
			return true;
		end;
		if type(value) == "string" then
			local text = string.lower(value);
			return string.find(text, "already", 1, true) ~= nil
				or string.find(text, "unlocked", 1, true) ~= nil
				or string.find(text, "complete", 1, true) ~= nil;
		end;
		if type(value) == "table" then
			return value.Unlocked == true or value.Complete == true or value.Completed == true or value.Success == true;
		end;
		return false;
	end;
BFDoughStep = function(active, unlockRaid)
		if not active then
			return "inactive";
		end;
		if not World3 then
			return "wrong-world";
		end;
		if unlockRaid then
			if UI.DoughUnlockComplete then
				return "complete";
			end;
			if os.clock() >= (UI.DoughUnlockCheckAt or 0) then
				UI.DoughUnlockCheckAt = os.clock() + 3;
				local scientistUnlocked = BFComm("CakeScientist", "Check");
				BFComm("RaidsNpc", "Check");
				if BFUnlockResponseComplete(scientistUnlocked) then
					UI.DoughUnlockComplete = true;
					return "complete";
				end;
			end;
		end;
		local boss = BFFindLiveEnemyLike("Dough King");
		if boss then
			f.Kill2(boss, active);
			return "combat";
		end;
		local storedBoss = BFFindStoredEnemyLike("Dough King");
		if storedBoss then
			BFMoveNear(storedBoss, 40);
			return "moving-to-dough-king";
		end;
		if unlockRaid then
			local key = BFFindLocalItemLike("red key");
			local door = BFMapNode("CakeLoaf", "RedDoor");
			if not door and key then
				local scientist, scientistRoot;
				if type(BFFindNpc) == "function" then
					scientist, scientistRoot = BFFindNpc("Cake Scientist");
				end;
				local cakeLoaf = BFMapNode("CakeLoaf");
				local target = scientistRoot or BFFirstPart(scientist) or BFFirstPart(cakeLoaf) or CFrame.new(-2710.976, 63.477, -12895.638);
				if not BFMoveNear(target, 12) then
					return "moving-to-cake-scientist";
				end;
				BFComm("CakeScientist", "Check");
				BFComm("RaidsNpc", "Check");
				return "checking-red-key";
			elseif door and key then
				local doorPart = BFFirstPart(door);
				local target = doorPart or CFrame.new(-2681.97998, 64.3921585, -12853.7363);
				if BFMoveNear(target, 2) then
					EquipWeapon(key.Name);
					task.wait(.25);
					local character = d.Character;
					local equipped = character and character:FindFirstChild(key.Name);
					local handle = equipped and equipped:FindFirstChild("Handle");
					local root = character and character:FindFirstChild("HumanoidRootPart");
					local toucher = handle and handle:IsA("BasePart") and handle or root;
					if toucher and doorPart and type(firetouchinterest) == "function" then
						pcall(firetouchinterest, toucher, doorPart, 0);
						task.wait(.1);
						pcall(firetouchinterest, toucher, doorPart, 1);
					end;
					task.wait(.4);
					local scientistUnlocked = BFComm("CakeScientist", "Check");
					BFComm("RaidsNpc", "Check");
					local remainingKey = BFFindLocalItemLike("red key");
					local remainingDoor = BFMapNode("CakeLoaf", "RedDoor");
					local remainingDoorPart = BFFirstPart(remainingDoor);
					if BFUnlockResponseComplete(scientistUnlocked) or not remainingKey and (not remainingDoor or remainingDoorPart and remainingDoorPart.CanCollide == false) then
						UI.DoughUnlockComplete = true;
						return "complete";
					end;
					return "unlocking-red-door";
				end;
				return "moving-to-red-door";
			end;
		end;
		local sweet = BFFindLocalItemLike("sweet chalice");
		if sweet then
			EquipWeapon(sweet.Name);
			BFComm("CakePrinceSpawner", true);
			BFCakeFarmStep(active);
			return "summoning-dough-king";
		end;
		local chalice = BFFindLocalItemLike("god's chalice");
		if chalice then
			if GetM("Conjured Cocoa") >= 10 then
				BFComm("SweetChaliceNpc");
				task.wait(.75);
				return "crafting-sweet-chalice";
			else
				local cocoaEnemy = BFFindLiveEnemyLike(BFCocoaEnemyNames);
				if cocoaEnemy then
					f.Kill2(cocoaEnemy, active);
				else
					BFMoveNear(CFrame.new(402.7189, 81.0605, -12259.543), 40);
				end;
				return "farming-cocoa";
			end;
		end;
		if not BFHasItemLike("mirror fractal") or unlockRaid then
			BFEliteStep(active);
			return "hunting-elite";
		end;
		return "complete";
	end;
BFPhoenixUnlockStep = function(active)
		if not active then
			return "inactive";
		end;
		if not World3 then
			return "wrong-world";
		end;
		local data = d:FindFirstChild("Data");
		local fruit = data and data:FindFirstChild("DevilFruit");
		local phoenix = BFFindLocalItemLike("phoenix");
		if not phoenix and (not fruit or not string.find(string.lower(tostring(fruit.Value)), "phoenix", 1, true)) then
			return "requires-phoenix";
		end;
		if BFItemMasteryLike("phoenix") < 400 then
			return "requires-400-mastery";
		end;
		if UI.PhoenixUnlockComplete then
			return "complete";
		end;
		if os.clock() >= (UI.PhoenixUnlockCheckAt or 0) then
			UI.PhoenixUnlockCheckAt = os.clock() + 3;
			if BFUnlockResponseComplete(BFComm("SickScientist", "Check")) then
				UI.PhoenixUnlockComplete = true;
				return "complete";
			end;
		end;
		local scientist, scientistRoot;
		if type(BFFindNpc) == "function" then
			scientist, scientistRoot = BFFindNpc("Sick Scientist");
		end;
		local target = scientistRoot or BFFirstPart(scientist) or CFrame.new(-2812.7671, 254.8035, -12595.5605);
		if not BFMoveNear(target, 10) then
			return "moving-to-scientist";
		end;
		local scientistUnlocked = BFComm("SickScientist", "Check");
		task.wait(.25);
		local healed = BFComm("SickScientist", "Heal");
		if BFUnlockResponseComplete(scientistUnlocked) or BFUnlockResponseComplete(healed) then
			UI.PhoenixUnlockComplete = true;
			return "complete";
		end;
		return "checking-unlock";
	end;
local NF = UI.Sections["Generals Quests / Items"];
local DF = NF:AddLabel({ DoesWrap = true, Text = "Cake Princes :" });
local AF = NF:AddLabel({ DoesWrap = true, Text = " Bones :" });
task.spawn(function()
	while UI.LabelWait(5) do
		pcall(function()
			local Y = string.match(BFComm("CakePrinceSpawner"), "%d+");
			if Y then
				DF:SetText(" Killed : " .. 500 - Y);
			end;
		end);
	end;
end);
task.spawn(function()
	while UI.LabelWait(5) do
		pcall(function()
			AF:SetText(" Bones : " .. GetBones());
		end);
	end;
end);
NF:AddToggle("BF_Toggle_Auto_Cake_Prince", {
	Text = "Auto Cake Prince",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		_G.Auto_Cake_Prince = Y;
	end,
});
task.spawn(function()
	while IdleWait(_G.Auto_Cake_Prince, .2) do
		if _G.Auto_Cake_Prince then
			pcall(function()
				local boss = BFFindLiveEnemyLike("Cake Prince");
				if boss then
					f.Kill2(boss, _G.Auto_Cake_Prince);
				else
					BFComm("CakePrinceSpawner");
					BFCakeFarmStep(_G.Auto_Cake_Prince);
				end;
			end);
		end;
	end;
end);
UI.RegisterManagedFlag("AutoFarm_Bone", false);
NF:AddToggle("BF_Toggle_Auto_Bones", {
	Text = "Auto Bones",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		UI.SetManagedUserFlag("AutoFarm_Bone", Y);
	end,
});
task.spawn(function()
	while IdleWait(_G.AutoFarm_Bone, T) do
		if _G.AutoFarm_Bone then
			pcall(function()
				local Y = game.Players.LocalPlayer;
				local d = Y.Character and Y.Character:FindFirstChild("HumanoidRootPart");
				local Q = {
						"Reborn Skeleton",
						"Living Zombie",
						"Demonic Soul",
						"Posessed Mummy",
						"Possessed Mummy",
					};
				if not d then
					return;
				end;
				local r = GetConnectionEnemies(Q);
				if r then
					if _G.AcceptQuestC and not GuiShown("Quest") then
						local Y = CFrame.new(-9516.99316, 172.017181, 6078.46533, 0, 0, -1, 0, 1, 0, 1, 0, 0);
						while _G.AutoFarm_Bone and not BFMoveNear(Y, 50) do
							task.wait(.2);
						end;
						if not _G.AutoFarm_Bone then
							return;
						end;
						local R = math.random(1, 4);
						local Q = {
								[1] = { "StartQuest", "HauntedQuest2", 2 },
								[2] = { "StartQuest", "HauntedQuest2", 1 },
								[3] = { "StartQuest", "HauntedQuest1", 1 },
								[4] = { "StartQuest", "HauntedQuest1", 2 },
							};
						local r, a = pcall(function()
								return BFComm(unpack(Q[R]));
							end);
					end;
					repeat
						task.wait();
						f.Kill(r, _G.AutoFarm_Bone);
					until not _G.AutoFarm_Bone or not r.Parent or not f.Alive(r) or _G.AcceptQuestC and not GuiShown("Quest");
				else
					_tp(CFrame.new(-9495.6806640625, 453.58624267578, 5977.3486328125));
				end;
			end);
		end;
	end;
end);
NF:AddToggle("BF_Toggle_Accept_Quests", {
	Text = "Accept Quests",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		_G.AcceptQuestC = Y;
	end,
});
NF:AddToggle("BF_Toggle_Auto_Farm_Mirror", {
	Text = "Auto Farm Mirror",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		_G.AutoMiror = Y;
	end,
});
task.spawn(function()
	while IdleWait(_G.AutoMiror, .2) do
		if _G.AutoMiror then
			pcall(function()
				BFDoughStep(_G.AutoMiror, false);
			end);
		end;
	end;
end);
_G.BFAllowBoneSpending = false;
NF:AddToggle("BF_Toggle_Allow_Bone_Spending", {
	Text = "Allow Bone Spending",
	Tooltip = "Required before any automation can roll Bones",
	Default = false,
	Callback = function(Y)
		_G.BFAllowBoneSpending = Y;
	end,
});
NF:AddToggle("BF_Toggle_Auto_Soul_Reaper_Fully", {
	Text = "Auto Soul Reaper [Fully]",
	Tooltip = "Farm Bones, roll with permission, summon Hallow Essence, and defeat Soul Reaper",
	Default = false,
	Callback = function(Y)
		_G.AutoHytHallow = Y;
		if Y then
			BFSoulReaperNextRoll = 0;
			BFSoulReaperNextSummon = 0;
			BFSoulReaperNextTravel = 0;
			BFSoulReaperSummonPendingUntil = 0;
		else
			UI.ReleaseManagedOwner("SoulReaper");
			BFSoulReaperStoredEnemy = nil;
			BFSoulReaperStoredNearAt = 0;
			BFSoulReaperStoredIgnoreUntil = 0;
			BFSoulReaperNextSummon = 0;
			BFSoulReaperSummonPendingUntil = 0;
			if UI.SoulReaperStatusLabel then
				UI.SoulReaperStatus = "idle";
				UI.SoulReaperStatusLabel:SetText("Soul Reaper: idle");
			end;
		end;
	end,
});
UI.SoulReaperStatus = "idle";
UI.SoulReaperStatusLabel = NF:AddLabel({ DoesWrap = true, Text = "Soul Reaper: idle" });
BFBoneEnemyNames = { "Reborn Skeleton", "Living Zombie", "Demonic Soul", "Posessed Mummy", "Possessed Mummy" };
BFSoulReaperNextRoll = 0;
BFSoulReaperNextSummon = 0;
BFSoulReaperNextTravel = 0;
BFSoulReaperSummonPendingUntil = 0;
BFSoulReaperStoredEnemy = nil;
BFSoulReaperStoredNearAt = 0;
BFSoulReaperStoredIgnoreUntil = 0;
BFSoulReaperStep = function(active)
		if not active then
			UI.ReleaseManagedOwner("SoulReaper");
			return "inactive";
		end;
		local now = os.clock();
		if not World3 then
			UI.ReleaseManagedOwner("SoulReaper");
			if now >= BFSoulReaperNextTravel then
				BFSoulReaperNextTravel = now + 3;
				if World2 then
					BFComm("TravelZou");
				else
					BFComm("TravelDressrosa");
				end;
			end;
			return "traveling-to-third-sea";
		end;
		local enemy = BFFindLiveEnemyLike("Soul Reaper");
		if enemy then
			UI.ReleaseManagedOwner("SoulReaper");
			BFSoulReaperSummonPendingUntil = 0;
			BFSoulReaperStoredEnemy = nil;
			BFSoulReaperStoredNearAt = 0;
			BFSoulReaperStoredIgnoreUntil = 0;
			f.Kill2(enemy, active);
			return "combat";
		end;
		if now < BFSoulReaperSummonPendingUntil then
			UI.ReleaseManagedOwner("SoulReaper");
			return "waiting-for-soul-reaper";
		end;
		local storedEnemy = BFFindStoredEnemyLike("Soul Reaper");
		if storedEnemy ~= BFSoulReaperStoredEnemy then
			BFSoulReaperStoredEnemy = storedEnemy;
			BFSoulReaperStoredNearAt = 0;
			BFSoulReaperStoredIgnoreUntil = 0;
		end;
		if storedEnemy and now >= BFSoulReaperStoredIgnoreUntil then
			UI.ReleaseManagedOwner("SoulReaper");
			local storedPart = BFFirstPart(storedEnemy);
			local character = d.Character;
			local root = character and character:FindFirstChild("HumanoidRootPart");
			if storedPart and root then
				local distance = (storedPart.Position - root.Position).Magnitude;
				if distance > 40 then
					BFSoulReaperStoredNearAt = 0;
					BFMoveNear(storedPart, 40);
					return "moving-to-soul-reaper";
				end;
				if BFSoulReaperStoredNearAt == 0 then
					BFSoulReaperStoredNearAt = now;
				end;
				if now - BFSoulReaperStoredNearAt < 5 then
					return "waiting-for-soul-reaper";
				end;
				BFSoulReaperStoredIgnoreUntil = now + 12;
				BFSoulReaperStoredNearAt = 0;
			end;
		end;
		local essence = BFFindLocalItemLike("hallow essence");
		if essence then
			UI.ReleaseManagedOwner("SoulReaper");
			local summoner = BFMapNode("Haunted Castle", "Summoner");
			local detection = summoner and summoner:FindFirstChild("Detection", true);
			local target = detection or summoner or CFrame.new(-8932.3223, 146.8315, 6062.5508);
			if not BFMoveNear(target, 6) then
				return "moving-to-summoner";
			end;
			if now < BFSoulReaperNextSummon then
				return "awaiting-summon";
			end;
			BFSoulReaperNextSummon = now + 2.5;
			EquipWeapon(essence.Name);
			task.wait(.2);
			local character = d.Character;
			local equipped = character and character:FindFirstChild(essence.Name);
			local root = character and character:FindFirstChild("HumanoidRootPart");
			if equipped and equipped:IsA("Tool") then
				pcall(equipped.Activate, equipped);
			end;
			if detection and detection:IsA("BasePart") and type(firetouchinterest) == "function" then
				local handle = equipped and equipped:FindFirstChild("Handle");
				local toucher = handle and handle:IsA("BasePart") and handle or root;
				if toucher then
					pcall(firetouchinterest, toucher, detection, 0);
					task.wait(.1);
					pcall(firetouchinterest, toucher, detection, 1);
				end;
			end;
			if equipped then
				BFSoulReaperSummonPendingUntil = now + 12;
			end;
			return "summoning";
		end;
		if (tonumber(GetBones()) or 0) >= 50 then
			UI.ReleaseManagedOwner("SoulReaper");
			if not _G.BFAllowBoneSpending then
				return "awaiting-spend-permission";
			end;
			if os.clock() >= BFSoulReaperNextRoll then
				BFSoulReaperNextRoll = os.clock() + 1;
				BFComm("Bones", "Buy", 1, 1);
			end;
			return "rolling-essence";
		end;
		UI.DriveManagedFlag("SoulReaper", "AutoFarm_Bone");
		return "farming-bones";
	end;
getgenv().BFSoulReaperStep = BFSoulReaperStep;
task.spawn(function()
	while IdleWait(_G.AutoHytHallow, .25) do
		if _G.AutoHytHallow then
			local ok, status = pcall(BFSoulReaperStep, _G.AutoHytHallow);
			status = ok and tostring(status or "working") or "error";
			if not ok then
				UI.ReleaseManagedOwner("SoulReaper");
			end;
			if status ~= UI.SoulReaperStatus then
				UI.SoulReaperStatus = status;
				UI.SoulReaperStatusLabel:SetText("Soul Reaper: " .. status:gsub("%-", " "));
			end;
		end;
	end;
	UI.ReleaseManagedOwner("SoulReaper");
end);
NF:AddToggle("BF_Toggle_Auto_Random_Bones", {
	Text = "Auto Random Bones",
	Tooltip = "Spend 50 Bones per roll while Allow Bone Spending is enabled",
	Default = false,
	Callback = function(Y)
		_G.Auto_Random_Bone = Y;
		if Y then
			UI.RandomBonesNextAt = 0;
			-- The roll is gated behind Allow Bone Spending. Without this warning the
			-- toggle just sat there doing nothing and looked broken.
			if not _G.BFAllowBoneSpending then
				pcall(function()
					UI.Library:Notify("Auto Random Bones needs 'Allow Bone Spending' enabled", 5);
				end);
			end;
		end;
	end,
});
UI.RandomBonesNextAt = 0;
UI.RandomBonesRolled = 0;
UI.RandomBonesStatus = nil;
UI.RandomBonesStatusLabel = NF:AddLabel({ DoesWrap = true, Text = "Auto Random Bones: idle" });
function UI.SetRandomBonesStatus(value)
	if UI.RandomBonesStatus == value then
		return;
	end;
	UI.RandomBonesStatus = value;
	if UI.RandomBonesStatusLabel then
		pcall(UI.RandomBonesStatusLabel.SetText, UI.RandomBonesStatusLabel, "Auto Random Bones: " .. tostring(value));
	end;
end;
task.spawn(function()
	while IdleWait(_G.Auto_Random_Bone, .25) do
		pcall(function()
			if not _G.Auto_Random_Bone then
				UI.SetRandomBonesStatus("idle");
				return;
			end;
			if not _G.BFAllowBoneSpending then
				UI.SetRandomBonesStatus("blocked - enable Allow Bone Spending");
				return;
			end;
			local bones = tonumber(GetBones()) or 0;
			if bones < 50 then
				UI.SetRandomBonesStatus("waiting for bones (" .. bones .. "/50)");
				return;
			end;
			local now = os.clock();
			if now >= UI.RandomBonesNextAt then
				UI.RandomBonesNextAt = now + 1;
				if BFComm("Bones", "Buy", 1, 1) then
					UI.RandomBonesRolled = UI.RandomBonesRolled + 1;
				end;
				UI.SetRandomBonesStatus("rolled " .. UI.RandomBonesRolled .. " (" .. bones .. " bones)");
			end;
		end);
	end;
	UI.SetRandomBonesStatus("idle");
end);
UI.GravestoneTarget = CFrame.new(-8761.3154296875, 164.85829162598, 6161.1567382813);
UI.GravestoneNextAt = { Luck = 0, Pray = 0 };
UI.GravestoneStatus = { Luck = "idle", Pray = "idle" };
UI.GravestoneStatusLabel = nil;
function UI.SetGravestoneStatus(action, status)
	status = tostring(status or "working");
	if UI.GravestoneStatus[action] ~= status then
		UI.GravestoneStatus[action] = status;
		if UI.GravestoneStatusLabel then
			UI.GravestoneStatusLabel:SetText("Gravestone: luck " .. UI.GravestoneStatus.Luck:gsub("%-", " ") .. " | pray " .. UI.GravestoneStatus.Pray:gsub("%-", " "));
		end;
	end;
end;
function UI.GravestoneStep(action, command, active)
	if not active then
		return "idle";
	end;
	if not World3 then
		return "wrong-world";
	end;
	if not BFMoveNear(UI.GravestoneTarget, 5) then
		return "moving";
	end;
	local now = os.clock();
	if now < UI.GravestoneNextAt[action] then
		return "cooldown";
	end;
	UI.GravestoneNextAt[action] = now + 2;
	BFComm("gravestoneEvent", command);
	return "requested";
end;
NF:AddToggle("BF_Toggle_Auto_Try_Luck_Gravestone", {
	Text = "Auto Try Luck Gravestone",
	Tooltip = "Approach the Haunted Castle gravestone and retry Try Luck every two seconds",
	Default = false,
	Callback = function(Y)
		_G.TryLucky = Y;
		if Y then
			UI.GravestoneNextAt.Luck = 0;
		else
			UI.SetGravestoneStatus("Luck", "idle");
		end;
	end,
});
task.spawn(function()
	while IdleWait(_G.TryLucky, .25) do
		if _G.TryLucky then
			local ok, status = pcall(UI.GravestoneStep, "Luck", 1, _G.TryLucky);
			UI.SetGravestoneStatus("Luck", ok and status or "error");
		end;
	end;
end);
NF:AddToggle("BF_Toggle_Auto_Pray_Gravestone", {
	Text = "Auto Pray Gravestone",
	Tooltip = "Approach the Haunted Castle gravestone and retry Pray every two seconds",
	Default = false,
	Callback = function(Y)
		_G.Praying = Y;
		if Y then
			UI.GravestoneNextAt.Pray = 0;
		else
			UI.SetGravestoneStatus("Pray", "idle");
		end;
	end,
});
task.spawn(function()
	while IdleWait(_G.Praying, .25) do
		if _G.Praying then
			local ok, status = pcall(UI.GravestoneStep, "Pray", 2, _G.Praying);
			UI.SetGravestoneStatus("Pray", ok and status or "error");
		end;
	end;
end);
UI.GravestoneStatusLabel = NF:AddLabel({ DoesWrap = true, Text = "Gravestone: luck idle | pray idle" });
local uF = UI.Sections["Unlocked Dungeon"];
uF:AddToggle("BF_Toggle_Auto_Unlock_Dough_Dungeon", {
	Text = "Auto Unlock Dough Dungeon",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		_G.Doughv2 = Y;
		if Y then
			UI.DoughUnlockCheckAt = 0;
		end;
		if not Y and UI.DoughUnlockStatusLabel and UI.DoughUnlockStatus ~= "complete" then
			UI.DoughUnlockStatus = "idle";
			UI.DoughUnlockStatusLabel:SetText("Dough unlock: idle");
		end;
	end,
});
UI.DoughUnlockStatus = "idle";
UI.DoughUnlockComplete = false;
UI.DoughUnlockCheckAt = 0;
UI.DoughUnlockStatusLabel = uF:AddLabel({ DoesWrap = true, Text = "Dough unlock: idle" });
task.spawn(function()
	while IdleWait(_G.Doughv2, .5) do
		if _G.Doughv2 then
			local ok, status = pcall(BFDoughStep, _G.Doughv2, true);
			status = ok and tostring(status or "working") or "error";
			if status ~= UI.DoughUnlockStatus then
				UI.DoughUnlockStatus = status;
				UI.DoughUnlockStatusLabel:SetText("Dough unlock: " .. status:gsub("%-", " "));
			end;
			if status == "complete" then
				UI.DisableToggle("BF_Toggle_Auto_Unlock_Dough_Dungeon");
			end;
		end;
	end;
end);
uF:AddToggle("BF_Toggle_Auto_Unlock_Phoenix_Dungeon", {
	Text = "Auto Unlock Phoenix Dungeon",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		_G.AutoPhoenixF = Y;
		if Y then
			UI.PhoenixUnlockCheckAt = 0;
		end;
		if not Y and UI.PhoenixUnlockStatusLabel and UI.PhoenixUnlockStatus ~= "complete" then
			UI.PhoenixUnlockStatus = "idle";
			UI.PhoenixUnlockStatusLabel:SetText("Phoenix unlock: idle");
		end;
	end,
});
UI.PhoenixUnlockStatus = "idle";
UI.PhoenixUnlockComplete = false;
UI.PhoenixUnlockCheckAt = 0;
UI.PhoenixUnlockStatusLabel = uF:AddLabel({ DoesWrap = true, Text = "Phoenix unlock: idle" });
task.spawn(function()
	while IdleWait(_G.AutoPhoenixF, .5) do
		if _G.AutoPhoenixF then
			local ok, status = pcall(BFPhoenixUnlockStep, _G.AutoPhoenixF);
			status = ok and tostring(status or "working") or "error";
			if status ~= UI.PhoenixUnlockStatus then
				UI.PhoenixUnlockStatus = status;
				UI.PhoenixUnlockStatusLabel:SetText("Phoenix unlock: " .. status:gsub("%-", " "));
			end;
			if status == "complete" then
				UI.DisableToggle("BF_Toggle_Auto_Unlock_Phoenix_Dungeon");
			end;
		end;
	end;
end);
local gF = UI.Sections["Buso/Aura Colours"];
gF:AddToggle("BF_Toggle_Auto_Teleport_Barista_Cousin", {
	Text = "Auto Teleport Barista Cousin",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		_G.Tp_MasterA = Y;
	end,
});
task.spawn(function()
	while IdleWait(_G.Tp_MasterA) do
		if _G.Tp_MasterA then
			pcall(function()
				local root;
				if type(BFFindNpc) == "function" then
					root = select(2, BFFindNpc("Barista Cousin"));
				end;
				if root and root:IsA("BasePart") then
					_tp(root.CFrame);
				end;
			end);
		end;
	end;
end);
gF:AddButton({ Text = "Buy Buso Colors", Func = function()
		BFComm("ColorsDealer", "2");
	end });
_G.Auto_Rainbow_Haki = false;
_G.GetQFast = false;
UI.RainbowStatus = "idle";
UI.RainbowStatusLabel = nil;
UI.RainbowNextActionAt = 0;
UI.RainbowNextEntranceAt = 0;
UI.RainbowQuestGiver = CFrame.new(-11892.0703125, 930.57672119141, -8760.1591796875);
UI.RainbowBossRoutes = {
	{ Name = "Stone", Status = "stone", Fallback = CFrame.new(-1086.11621, 38.8425903, 6768.71436, .0231462717, -0.592676699, .805107772, 2.03251839e-05, .805323839, .592835128, -0.999732077, -0.0137055516, .0186523199) },
	{ Name = "Hydra Leader", Status = "hydra-leader", Entrance = Vector3.new(5643.4526367188, 1013.0858154297, -340.51025390625), Fallback = CFrame.new(5821.8979492188, 1019.0950927734, -73.719230651855) },
	{ Name = "Kilo Admiral", Status = "kilo-admiral", Fallback = CFrame.new(2877.61743, 423.558685, -7207.31006, -0.989591599, 0, -0.143904909, 0, 1.00000012, 0, .143904924, 0, -0.989591479) },
	{ Name = "Captain Elephant", Status = "captain-elephant", Entrance = Vector3.new(-12471.169921875, 374.94024658203, -7551.677734375), Fallback = CFrame.new(-13376.7578125, 433.28689575195, -8071.392578125) },
	{ Name = "Beautiful Pirate", Status = "beautiful-pirate", Entrance = Vector3.new(5314.5463867188, 22.562219619751, -127.06755065918) },
};
function UI.SetRainbowStatus(status)
	status = tostring(status or "working");
	if status ~= UI.RainbowStatus then
		UI.RainbowStatus = status;
		if UI.RainbowStatusLabel then
			UI.RainbowStatusLabel:SetText("Rainbow Colors: " .. status:gsub("%-", " "));
		end;
	end;
end;
gF:AddToggle("BF_Toggle_Auto_Rainbow_Colors", {
	Text = "Auto Rainbow Colors",
	Tooltip = "Complete the Horned Man boss chain for Rainbow Saviour",
	Default = false,
	Callback = function(Y)
		_G.Auto_Rainbow_Haki = Y;
		if Y then
			UI.RainbowNextActionAt = 0;
			UI.RainbowNextEntranceAt = 0;
		else
			UI.SetRainbowStatus("idle");
		end;
	end,
});
UI.RainbowStatusLabel = gF:AddLabel({ DoesWrap = true, Text = "Rainbow Colors: idle" });
function UI.RainbowQuestStep(active)
	if not active then
		return "idle";
	end;
	if not World3 then
		return "third-sea-required";
	end;
	local now = os.clock();
	if not GuiShown("Quest") then
		if not _G.GetQFast and not BFMoveNear(UI.RainbowQuestGiver, 5) then
			return "moving-to-horned-man";
		end;
		if now >= UI.RainbowNextActionAt then
			UI.RainbowNextActionAt = now + 2;
			BFComm("HornedMan", "Bet");
		end;
		return "requesting-rainbow-quest";
	end;
	local questText = QuestText();
	for _, route in ipairs(UI.RainbowBossRoutes) do
		if string.find(questText, route.Name, 1, true) then
			local enemy = GetConnectionEnemies(route.Name);
			if enemy then
				f.Kill(enemy, active);
				return "fighting-" .. route.Status;
			end;
			if route.Entrance and now >= UI.RainbowNextEntranceAt then
				UI.RainbowNextEntranceAt = now + 2;
				BFComm("requestEntrance", route.Entrance);
			end;
			if route.Fallback then
				BFMoveNear(route.Fallback, 20);
			end;
			return "waiting-for-" .. route.Status;
		end;
	end;
	return "unrelated-quest-active";
end;
task.spawn(function()
	while IdleWait(_G.Auto_Rainbow_Haki, .25) do
		if _G.Auto_Rainbow_Haki then
			local ok, status = pcall(UI.RainbowQuestStep, _G.Auto_Rainbow_Haki);
			UI.SetRainbowStatus(ok and status or "error");
		end;
	end;
end);
gF:AddToggle("BF_Toggle_Accept_Rainbow_Quest_Faster", {
	Text = "Accept Rainbow Quest Faster",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		_G.GetQFast = Y;
	end,
});
local zF = UI.Sections["Instinct / Observation"];
zF:AddToggle("BF_Toggle_Auto_Farm_Observation", {
	Text = "Auto Farm Observation",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		_G.obsFarm = Y;
	end,
});
task.spawn(function()
	while IdleWait(_G.obsFarm, .2) do
		pcall(function()
			if _G.obsFarm then
				BFCommE("Ken", true);
				if d:GetAttribute("KenDodgesLeft") == 0 then
					c = false;
				elseif d:GetAttribute("KenDodgesLeft") > 0 then
				BFCommE("Ken", true);
					c = true;
				end;
			end;
		end);
	end;
end);
task.spawn(function()
	local targets = {
		[1] = { Name = "Galley Captain", Fallback = CFrame.new(5533.29785, 88.1079102, 4852.3916) },
		[2] = { Name = "Lava Pirate", Fallback = CFrame.new(-5478.39209, 15.9775667, -5246.9126) },
		[3] = { Name = "Venomous Assailant", Fallback = CFrame.new(4530.3540039063, 656.75695800781, -131.60952758789) },
	};
	while IdleWait(_G.obsFarm, .2) do
		pcall(function()
			if _G.obsFarm then
				local world = World1 and 1 or World2 and 2 or World3 and 3 or nil;
				local target = world and targets[world];
				if not target then
					return;
				end;
				local enemy = workspace.Enemies:FindFirstChild(target.Name);
				local enemyRoot = enemy and enemy:FindFirstChild("HumanoidRootPart");
				if enemyRoot then
					_tp(enemyRoot.CFrame * (c and CFrame.new(3, 0, 0) or CFrame.new(0, 50, 0)));
				else
					_tp(target.Fallback);
				end;
			end;
		end);
	end;
end);
_G.AutoKenVTWO = false;
UI.ObservationV2Status = "idle";
UI.ObservationV2StatusLabel = nil;
UI.ObservationV2Progress = nil;
UI.ObservationV2NextProgressAt = 0;
UI.ObservationV2NextActionAt = 0;
UI.ObservationV2NextFruitAt = 0;
UI.ObservationV2NextEntranceAt = 0;
UI.ObservationV2Citizen = CFrame.new(-12444.78515625, 332.40396118164, -7673.1806640625);
UI.ObservationV2HungryMan = CFrame.new(-10920.125, 624.20275878906, -10266.995117188);
UI.ObservationV2ForestPirates = CFrame.new(-13277.568359375, 370.34185791016, -7821.1572265625);
UI.ObservationV2CaptainElephant = CFrame.new(-13493.12890625, 318.89553833008, -8373.7919921875);
UI.ObservationV2Banana = CFrame.new(2286.0078125, 73.133918762207, -7159.8090820312);
UI.ObservationV2Pineapple = CFrame.new(-712.82727050781, 98.577049255371, 5711.9541015625);
function UI.SetObservationV2Status(status)
	status = tostring(status or "working");
	if status ~= UI.ObservationV2Status then
		UI.ObservationV2Status = status;
		if UI.ObservationV2StatusLabel then
			UI.ObservationV2StatusLabel:SetText("Observation V2: " .. status:gsub("%-", " "));
		end;
	end;
end;
zF:AddToggle("BF_Toggle_Auto_Observation_V2", {
	Text = "Auto Observation V2",
	Tooltip = "Complete the Citizen quest, collect the fruit bowl, and unlock Observation V2",
	Default = false,
	Callback = function(Y)
		_G.AutoKenVTWO = Y;
		if Y then
			UI.ObservationV2Progress = nil;
			UI.ObservationV2NextProgressAt = 0;
			UI.ObservationV2NextActionAt = 0;
			UI.ObservationV2NextFruitAt = 0;
			UI.ObservationV2NextEntranceAt = 0;
		else
			UI.SetObservationV2Status("idle");
		end;
	end,
});
UI.ObservationV2StatusLabel = zF:AddLabel({ DoesWrap = true, Text = "Observation V2: idle" });
BFCollectObservationFruit = function(name)
	local character = d.Character;
	local root = character and character:FindFirstChild("HumanoidRootPart");
	if not root or type(firetouchinterest) ~= "function" then
		return false;
	end;
	local object = workspace:FindFirstChild(name, true);
	local handle = object and (object:IsA("BasePart") and object or object:FindFirstChild("Handle", true));
	if handle and handle:IsA("BasePart") then
		handle.CFrame = root.CFrame * CFrame.new(0, 1, 10);
		pcall(firetouchinterest, root, handle, 0);
		task.wait(.1);
		pcall(firetouchinterest, root, handle, 1);
		return true;
	end;
	return false;
end;
function UI.ObservationV2FruitStep(name, target, status, now)
	if target and not BFMoveNear(target, 20) then
		return "moving-to-" .. status;
	end;
	if now >= UI.ObservationV2NextFruitAt then
		UI.ObservationV2NextFruitAt = now + 1;
		BFCollectObservationFruit(name);
	end;
	return "collecting-" .. status;
end;
function UI.ObservationV2Step(active)
	if not active then
		return "idle";
	end;
	if not World3 then
		return "third-sea-required";
	end;
	if (tonumber(BFDataValue("Level")) or 0) < 1800 then
		return "level-1800-required";
	end;
	local now = os.clock();
	if now >= UI.ObservationV2NextProgressAt then
		UI.ObservationV2NextProgressAt = now + 1.5;
		local progress = tonumber(BFComm("CitizenQuestProgress", "Citizen"));
		if progress ~= nil then
			UI.ObservationV2Progress = progress;
		end;
	end;
	local progress = UI.ObservationV2Progress;
	if progress == 2 then
		if not GetBP("Fruit Bowl") then
			if not GetBP("Apple") then
				if now >= UI.ObservationV2NextEntranceAt then
					UI.ObservationV2NextEntranceAt = now + 2;
					BFComm("requestEntrance", Vector3.new(-12471.169921875, 374.94024658203, -7551.677734375));
				end;
				return UI.ObservationV2FruitStep("Apple", nil, "apple", now);
			elseif not GetBP("Banana") then
				return UI.ObservationV2FruitStep("Banana", UI.ObservationV2Banana, "banana", now);
			elseif not GetBP("Pineapple") then
				return UI.ObservationV2FruitStep("Pineapple", UI.ObservationV2Pineapple, "pineapple", now);
			elseif not BFMoveNear(UI.ObservationV2Citizen, 5) then
				return "returning-fruit-to-citizen";
			elseif now >= UI.ObservationV2NextActionAt then
				UI.ObservationV2NextActionAt = now + 2;
				BFComm("CitizenQuestProgress", "Citizen");
			end;
			return "turning-in-fruit";
		end;
		if not BFMoveNear(UI.ObservationV2HungryMan, 5) then
			return "moving-to-hungry-man";
		end;
		if now >= UI.ObservationV2NextActionAt then
			UI.ObservationV2NextActionAt = now + 2;
			BFComm("KenTalk2", "Start");
			task.wait(.1);
			if active and _G.AutoKenVTWO then
				BFComm("KenTalk2", "Buy");
			end;
		end;
		return "unlocking-observation-v2";
	end;
	local questVisible = GuiShown("Quest");
	local questText = questVisible and QuestText() or "";
	if string.find(questText, "Forest Pirate", 1, true) then
		local enemy = GetConnectionEnemies("Forest Pirate");
		if enemy then
			f.Kill(enemy, active);
			return "fighting-forest-pirates";
		end;
		BFMoveNear(UI.ObservationV2ForestPirates, 30);
		return "waiting-for-forest-pirates";
	elseif string.find(questText, "Captain Elephant", 1, true) then
		local enemy = GetConnectionEnemies("Captain Elephant");
		if enemy then
			f.Kill(enemy, active);
			return "fighting-captain-elephant";
		end;
		BFMoveNear(UI.ObservationV2CaptainElephant, 30);
		return "waiting-for-captain-elephant";
	elseif questVisible then
		return "unrelated-quest-active";
	elseif progress == nil then
		return "waiting-for-citizen-progress";
	elseif not BFMoveNear(UI.ObservationV2Citizen, 5) then
		return "moving-to-citizen";
	elseif now >= UI.ObservationV2NextActionAt then
		UI.ObservationV2NextActionAt = now + 2;
		BFComm("CitizenQuestProgress", "Citizen");
		task.wait(.1);
		if active and _G.AutoKenVTWO then
			BFComm("StartQuest", "CitizenQuest", 1);
		end;
	end;
	return "starting-citizen-quest";
end;
task.spawn(function()
	while IdleWait(_G.AutoKenVTWO, .25) do
		if _G.AutoKenVTWO then
			local ok, status = pcall(UI.ObservationV2Step, _G.AutoKenVTWO);
			UI.SetObservationV2Status(ok and status or "error");
		end;
	end;
end);
local iF = UI.Sections["Upgrade Races V3"];
local selectedRaceV3 = "Mink";
local autoUpgradeSelectedRaceV3 = false;
UI.RaceV3NextProtocolAt = 0;
UI.RaceV3Alchemist = nil;
UI.RaceV3Wenlock = nil;
UI.RaceV3Status = "idle";
UI.RaceV3StatusLabel = nil;
UI.RaceV3HumanRouteIndex = 1;
UI.RaceV3HumanTargets = {
	{ Name = B[1], Position = CFrame.new(-2172.7399902344, 103.32216644287, -4015.025390625) },
	{ Name = B[2], Position = CFrame.new(2006.9261474609, 448.95666503906, 853.98284912109) },
	{ Name = B[3], Position = CFrame.new(-1576.7166748047, 198.59265136719, 13.724286079407) },
};
UI.RaceV3HumanNames = { B[1], B[2], B[3] };
function UI.SetRaceV3Status(status)
	status = tostring(status or "working");
	if status ~= UI.RaceV3Status then
		UI.RaceV3Status = status;
		if UI.RaceV3StatusLabel then
			UI.RaceV3StatusLabel:SetText("Race V3: " .. status:gsub("%-", " "));
		end;
	end;
end;
function UI.ResetRaceV3Protocol()
	UI.RaceV3NextProtocolAt = 0;
	UI.RaceV3Alchemist = nil;
	UI.RaceV3Wenlock = nil;
	UI.RaceV3HumanRouteIndex = 1;
end;
local function ApplySelectedRaceV3()
	_G.Auto_Mink = autoUpgradeSelectedRaceV3 and selectedRaceV3 == "Mink";
	_G.Auto_Human = autoUpgradeSelectedRaceV3 and selectedRaceV3 == "Human";
	_G.Auto_Skypiea = autoUpgradeSelectedRaceV3 and selectedRaceV3 == "Skypiea";
	_G.Auto_Fish = autoUpgradeSelectedRaceV3 and selectedRaceV3 == "Fishman";
	if not _G.Auto_Mink then
		UI.ReleaseManagedFlag("RaceV3Mink", "AutoFarmChest");
	end;
end;
iF:AddDropdown("BF_Dropdown_Selected_Race_V3", {
	Text = "Race",
	Tooltip = "Choose the race V3 path to automate",
	Values = { "Mink", "Human", "Skypiea", "Fishman" },
	Default = "Mink",
	Callback = function(Y)
		selectedRaceV3 = Y;
		UI.ResetRaceV3Protocol();
		ApplySelectedRaceV3();
	end,
});
iF:AddToggle("BF_Toggle_Auto_Upgrade_Selected_Race_V3", {
	Text = "Auto Upgrade Selected",
	Tooltip = "Automatically upgrade the selected race to V3",
	Default = false,
	Callback = function(Y)
		autoUpgradeSelectedRaceV3 = Y;
		UI.ResetRaceV3Protocol();
		ApplySelectedRaceV3();
		if not Y then
			UI.SetRaceV3Status("idle");
		end;
	end,
});
UI.RaceV3StatusLabel = iF:AddLabel({ DoesWrap = true, Text = "Race V3: idle" });
function UI.RaceV3Protocol()
	local now = os.clock();
	if now >= UI.RaceV3NextProtocolAt then
		UI.RaceV3NextProtocolAt = now + 2;
		UI.RaceV3Alchemist = BFComm("Alchemist", "1");
		UI.RaceV3Wenlock = nil;
		if UI.RaceV3Alchemist == -2 then
			UI.RaceV3Wenlock = BFComm("Wenlocktoad", "1");
			if UI.RaceV3Wenlock == 0 then
				BFComm("Wenlocktoad", "2");
			end;
		elseif UI.RaceV3Alchemist == 0 then
			BFComm("Alchemist", "2");
		elseif UI.RaceV3Alchemist == 2 then
			BFComm("Alchemist", "3");
		end;
	end;
	return UI.RaceV3Alchemist, UI.RaceV3Wenlock;
end;
function UI.RaceV3FlowerStep(active)
	if not GetBP("Flower 1") then
		TpNamed("Flower1");
		return "collecting-flower-1";
	end;
	if not GetBP("Flower 2") then
		TpNamed("Flower2");
		return "collecting-flower-2";
	end;
	if not GetBP("Flower 3") then
		local enemy = GetConnectionEnemies("Swan Pirate");
		if enemy then
			f.Kill(enemy, active);
			return "fighting-for-flower-3";
		end;
		BFMoveNear(CFrame.new(980.09851074219, 121.33129882812, 1287.2093505859), 30);
		return "moving-to-swan-pirates";
	end;
	return "turning-in-flowers";
end;
function UI.RaceV3HumanStep(active)
	local enemy = GetConnectionEnemies(UI.RaceV3HumanNames);
	if enemy then
		f.Kill(enemy, active);
		return "fighting-human-boss";
	end;
	local stored = BFFindStoredEnemyLike(UI.RaceV3HumanNames);
	if stored then
		BFMoveNear(stored, 30);
		return "moving-to-human-boss";
	end;
	local target = UI.RaceV3HumanTargets[UI.RaceV3HumanRouteIndex];
	if target and BFMoveNear(target.Position, 30) then
		UI.RaceV3HumanRouteIndex = UI.RaceV3HumanRouteIndex % #UI.RaceV3HumanTargets + 1;
	end;
	return "searching-human-bosses";
end;
function UI.RaceV3SkypieaStep()
	local ownRoot = BFCharacterPart();
	if not ownRoot then
		return "waiting-for-character";
	end;
	local target;
	local targetRoot;
	local nearest = math.huge;
	for _, player in ipairs(Y:GetPlayers()) do
		local data = player:FindFirstChild("Data");
		local race = data and data:FindFirstChild("Race");
		local character = player.Character;
		local humanoid = character and character:FindFirstChildOfClass("Humanoid");
		local root = character and character:FindFirstChild("HumanoidRootPart");
		if player ~= d and race and tostring(race.Value) == "Skypiea" and humanoid and humanoid.Health > 0 and root then
			local distance = (ownRoot.Position - root.Position).Magnitude;
			if distance < nearest then
				nearest = distance;
				target = player;
				targetRoot = root;
			end;
		end;
	end;
	if not target or not targetRoot then
		return "waiting-for-skypiea-player";
	end;
	EquipWeapon(EnsureWeapon());
	MousePos = targetRoot.Position;
	BFTouchAttack();
	ExtendSimulationRadius();
	_tp((targetRoot.CFrame * CFrame.new(0, 8, 0)) * CFrame.Angles(math.rad(-45), 0, 0));
	return "attacking-skypiea-player";
end;
function UI.RaceV3FishmanStep(active)
	local beasts = workspace:FindFirstChild("SeaBeasts");
	for _, beast in ipairs(beasts and beasts:GetChildren() or {}) do
		local health = beast:FindFirstChild("Health");
		if health and (tonumber(health.Value) or 0) > 0 then
			BFAttackSeaBeastStep(beast, active);
			return "attacking-sea-beast";
		end;
	end;
	return "waiting-for-sea-beast";
end;
function UI.RaceV3Step(race, active)
	if not active then
		return "idle";
	end;
	if not World2 then
		UI.ReleaseManagedFlag("RaceV3Mink", "AutoFarmChest");
		return "wrong-world";
	end;
	UI.ReleaseManagedFlag("RaceV3Mink", "AutoFarmChest");
	local alchemist, wenlock = UI.RaceV3Protocol();
	if alchemist == nil then
		return "waiting-for-alchemist";
	end;
	if alchemist ~= -2 then
		if alchemist == 1 then
			return UI.RaceV3FlowerStep(active);
		end;
		return alchemist == 0 and "starting-flower-quest" or "turning-in-flowers";
	end;
	if wenlock == nil then
		return "waiting-for-wenlock";
	end;
	if wenlock == 0 then
		return "starting-race-v3-quest";
	end;
	if wenlock ~= 1 then
		return "complete-or-cooldown";
	end;
	if race == "Mink" then
		UI.DriveManagedFlag("RaceV3Mink", "AutoFarmChest");
		return "collecting-chests";
	elseif race == "Human" then
		return UI.RaceV3HumanStep(active);
	elseif race == "Skypiea" then
		return UI.RaceV3SkypieaStep();
	elseif race == "Fishman" then
		return UI.RaceV3FishmanStep(active);
	end;
	return "unsupported-race";
end;
task.spawn(function()
	while IdleWait(autoUpgradeSelectedRaceV3, .25) do
		if autoUpgradeSelectedRaceV3 then
			local ok, status = pcall(UI.RaceV3Step, selectedRaceV3, autoUpgradeSelectedRaceV3);
			UI.SetRaceV3Status(ok and status or "error");
		end;
	end;
	UI.ReleaseManagedFlag("RaceV3Mink", "AutoFarmChest");
end);
local UF = UI.Sections["Dark Dagger + Valkyrie"];
BFDaggerStep = function(active)
		if not active then
			return "inactive";
		end;
		if not World3 then
			return "wrong-world";
		end;
		if BFHasItemLike("dark dagger", "Sword") and BFHasItemLike("valkyrie") then
			return "complete";
		end;
		local enemy = BFFindLiveEnemyLike("rip_indra");
		if enemy then
			f.Kill2(enemy, active);
			return "combat";
		end;
		if os.clock() >= (UI.DaggerNextEntrance or 0) then
			UI.DaggerNextEntrance = os.clock() + 2;
			BFComm("requestEntrance", Vector3.new(-5097.93164, 316.447021, -3142.66602));
		end;
		local stored = BFFindStoredEnemyLike("rip_indra");
		if stored then
			BFMoveNear(stored, 30);
			return "moving-to-rip-indra";
		end;
		BFMoveNear(CFrame.new(-5344.8223, 423.9854, -2725.093), 30);
		return "waiting-for-rip-indra";
	end;
UF:AddToggle("BF_Toggle_Auto_Valkyrie", {
	Text = "Auto Valkyrie",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		_G.AutoRipIngay = Y;
		if not Y and UI.DaggerStatusLabel and UI.DaggerStatus ~= "complete" then
			UI.DaggerStatus = "idle";
			UI.DaggerStatusLabel:SetText("Dagger / Valkyrie: idle");
		end;
	end,
});
UI.DaggerStatus = "idle";
UI.DaggerStatusLabel = UF:AddLabel({ DoesWrap = true, Text = "Dagger / Valkyrie: idle" });
task.spawn(function()
	while IdleWait(_G.AutoRipIngay, .25) do
		if _G.AutoRipIngay then
			local ok, status = pcall(BFDaggerStep, _G.AutoRipIngay);
			status = ok and tostring(status or "working") or "error";
			if status ~= UI.DaggerStatus then
				UI.DaggerStatus = status;
				UI.DaggerStatusLabel:SetText("Dagger / Valkyrie: " .. status:gsub("%-", " "));
			end;
			if status == "complete" then
				UI.DisableToggle("BF_Toggle_Auto_Valkyrie");
			end;
		end;
	end;
end);
UF:AddToggle("BF_Toggle_Auto_Unlocked_Puzzle", {
	Text = "Auto Unlock Aura Puzzle",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		_G.AutoUnHaki = Y;
		if not Y and UI.AuraPuzzleStatusLabel and UI.AuraPuzzleStatus ~= "complete" then
			UI.AuraPuzzleStatus = "idle";
			UI.AuraPuzzleStatusLabel:SetText("Aura puzzle: idle");
		end;
	end,
});
UI.AuraPuzzleStatus = "idle";
UI.AuraPuzzleStatusLabel = UF:AddLabel({ DoesWrap = true, Text = "Aura puzzle: idle" });
AuraSkin = function(Y)
		if not Y then
			return nil;
		end;
		local result = NetInvoke("RF/FruitCustomizerRF", { StorageName = Y, Type = "AuraSkin", Context = "Equip" });
		if result == nil or result == false then
			result = BFComm("activateColor", Y);
		end;
		return result;
	end;
local BFAuraRequests = {};
BFRequestAuraSkin = function(aura)
		if not aura or BFAuraRequests[aura] then
			return false;
		end;
		BFAuraRequests[aura] = true;
		local ok = pcall(AuraSkin, aura);
		BFAuraRequests[aura] = nil;
		return ok;
	end;
VaildColor = function(Y)
		return Y ~= nil and Y:IsA("BasePart") and tostring(Y.BrickColor) == "Lime green";
	end;
HakiCalculate = function(Y)
		local d = { ["Really red"] = "Pure Red", Oyster = "Snow White", ["Hot pink"] = "Winter Sky" };
		if Y and Y:IsA("BasePart") then
			return d[tostring(Y.BrickColor)];
		end;
	end;
BFResolvePuzzleCircle = function()
		if BFPuzzleCircle and BFPuzzleCircle.Parent then
			return BFPuzzleCircle;
		end;
		if BFPuzzleCheckedAt and os.clock() - BFPuzzleCheckedAt < 5 then
			return nil;
		end;
		BFPuzzleCheckedAt = os.clock();
		local circle = BFMapNode("Boat Castle", "Summoner", "Circle");
		if circle then
			BFPuzzleCircle = circle;
			return circle;
		end;
		for _, descendant in ipairs(workspace:GetDescendants()) do
			if descendant.Name == "Circle" and descendant.Parent and descendant.Parent.Name == "Summoner" then
				BFPuzzleCircle = descendant;
				return descendant;
			end;
		end;
	end;
BFAuraPuzzleStep = function(active)
		if not active then
			return "inactive";
		end;
		if not World3 then
			return "wrong-world";
		end;
		local circle = BFResolvePuzzleCircle();
		if not circle then
			BFMoveNear(CFrame.new(-5097.93164, 316.447021, -3142.66602), 250);
			return "streaming-puzzle";
		end;
		local sawColor = false;
		for _, button in ipairs(circle:GetChildren()) do
			local colorPart = nil;
			local touchPart = nil;
			local parts = button:IsA("BasePart") and { button } or {};
			for _, descendant in ipairs(button:GetDescendants()) do
				if descendant:IsA("BasePart") then
					table.insert(parts, descendant);
				end;
			end;
			for _, part in ipairs(parts) do
				if HakiCalculate(part) or VaildColor(part) then
					colorPart = part;
				end;
				if part:FindFirstChildOfClass("TouchTransmitter") or part:FindFirstChild("TouchInterest") then
					touchPart = part;
				end;
			end;
			if colorPart then
				sawColor = true;
			end;
			if colorPart and not VaildColor(colorPart) then
				local aura = HakiCalculate(colorPart);
				local target = touchPart or colorPart;
				if not aura then
					return "unknown-color";
				end;
				if not BFMoveNear(target.CFrame, 3) then
					return "moving-to-button";
				end;
				if not BFRequestAuraSkin(aura) then
					return "aura-equip-error";
				end;
				local character = d.Character;
				local root = character and character:FindFirstChild("HumanoidRootPart");
				if not root then
					return "waiting-for-character";
				end;
				if type(firetouchinterest) ~= "function" then
					return "touch-unavailable";
				end;
				pcall(firetouchinterest, root, target, 0);
				task.wait(.1);
				pcall(firetouchinterest, root, target, 1);
				return "activating-button";
			end;
		end;
		return sawColor and "complete" or "waiting-for-buttons";
	end;
task.spawn(function()
	while IdleWait(_G.AutoUnHaki, .25) do
		if _G.AutoUnHaki then
			local ok, status = pcall(BFAuraPuzzleStep, _G.AutoUnHaki);
			status = ok and tostring(status or "working") or "error";
			if status ~= UI.AuraPuzzleStatus then
				UI.AuraPuzzleStatus = status;
				UI.AuraPuzzleStatusLabel:SetText("Aura puzzle: " .. status:gsub("%-", " "));
			end;
			if status == "complete" then
				UI.DisableToggle("BF_Toggle_Auto_Unlocked_Puzzle");
			end;
		end;
	end;
end);
_G.ChooseWP = _G.ChooseWP or "Melee";
local CF = UI.Sections["Settings / Configure"];
CF:AddDropdown("BF_Dropdown_Select_Weapon", {
	Text = "Select Weapon",
	Tooltip = "",
	Values = {
		"Melee",
		"Sword",
		"Blox Fruit",
		"Gun",
	},
	Default = "Melee",
	Multi = false,
	Callback = function(Y)
		_G.ChooseWP = Y;
	end,
});
task.spawn(function()
	while IdleWait(_G.ChooseWP, 1) do
		if _G.ChooseWP then
			pcall(function()
				local backpack = d:FindFirstChild("Backpack");
				if not backpack then
					return;
				end;
				for _, tool in ipairs(backpack:GetChildren()) do
					if tool:IsA("Tool") and tool.ToolTip == _G.ChooseWP then
						_G.SelectWeapon = tool.Name;
					end;
				end;
			end);
		end;
	end;
end);
CF:AddToggle("BF_Toggle_Initialize_Attack_M1_Melee_Sword", {
	Text = "Initialize Attack [M1/Melee/Sword]",
	Tooltip = "[ Not Supported Gas M1 ]",
	Default = false,
	Callback = function(Y)
		_G.Seriality = Y;
	end,
});
CF:AddSlider("BF_Slider_Tween_Speed", {
	Text = "Tween Speed",
	Tooltip = "Control the speed of tween teleportation",
	Min = 50,
	Max = 380,
	Default = 200,
	Rounding = 0,
	Callback = function(Y)
		getgenv().TweenSpeedFar = Y;
		getgenv().TweenSpeedNear = Y;
	end,
});
CF:AddToggle("BF_Toggle_Bring_Mobs", {
	Text = "Bring Mobs",
	Tooltip = "",
	Default = true,
	Callback = function(Y)
		_B = Y;
		if not Y then
			UI.RestoreBroughtEnemies();
		end;
	end,
});
CF:AddToggle("BF_Toggle_Auto_Turn_on_Buso", {
	Text = "Auto Turn on Buso",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		Boud = Y;
	end,
});
task.spawn(function()
	while IdleWait(Boud, T) do
		pcall(function()
			if Boud then
				local Y = { "HasBuso", "Buso" };
				if not d.Character:FindFirstChild(Y[1]) then
					BFComm(Y[2]);
				end;
			end;
		end);
	end;
end);
UI.SelectedRaceAbility = "V3";
UI.AutoActivateSelectedRaceAbility = false;
function UI.ApplySelectedRaceAbility()
	_G.RaceClickAutov3 = UI.AutoActivateSelectedRaceAbility and UI.SelectedRaceAbility == "V3";
	_G.RaceClickAutov4 = UI.AutoActivateSelectedRaceAbility and UI.SelectedRaceAbility == "V4";
end;
CF:AddDropdown("BF_Dropdown_Selected_Race_Ability", {
	Text = "Race Ability",
	Tooltip = "Choose which race ability stage to activate",
	Values = { "V3", "V4" },
	Default = "V3",
	Callback = function(Y)
		UI.SelectedRaceAbility = Y;
		UI.ApplySelectedRaceAbility();
	end,
});
CF:AddToggle("BF_Toggle_Auto_Activate_Selected_Race_Ability", {
	Text = "Auto Activate Selected",
	Tooltip = "Automatically use the selected race ability",
	Default = false,
	Callback = function(Y)
		UI.AutoActivateSelectedRaceAbility = Y;
		UI.ApplySelectedRaceAbility();
	end,
});
task.spawn(function()
	while IdleWait(_G.RaceClickAutov3, .2) do
		pcall(function()
			if _G.RaceClickAutov3 then
				BFCommE("ActivateAbility");
				local deadline = os.clock() + 30;
				while _G.RaceClickAutov3 and not UI.Stopped and os.clock() < deadline do
					task.wait(.25);
				end;
			end;
		end);
	end;
end);
task.spawn(function()
	while IdleWait(_G.RaceClickAutov4, .2) do
		pcall(function()
			if _G.RaceClickAutov4 then
				local character = d.Character;
				local raceEnergy = character and character:FindFirstChild("RaceEnergy");
				local energy = raceEnergy and tonumber(raceEnergy.Value);
				if energy and energy >= 1 then
					Useskills("nil", "Y");
				end;
			end;
		end);
	end;
end);
CF:AddToggle("BF_Toggle_Auto_Turn_on_Spin_Position", {
	Text = "Auto Turn on Spin Position",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
			getgenv().BFRandomCFrame = Y;
	end,
});
CF:AddToggle("BF_Toggle_Turn_on_Bypass_Teleport", {
	Text = "Smart Teleport (Bypass TP)",
	Tooltip = "Use portals first, then one reset-assisted fallback for a long instant move",
	Default = false,
	Callback = function(Y)
		_G.Bypass = Y;
		if not Y then
			BFResetTeleportStop();
		end;
	end,
});
CF:AddToggle("BF_Toggle_Panic_Mode", {
	Text = "Panic Mode",
	Tooltip = "turn on for safe ur health if low",
	Default = false,
	Callback = function(Y)
		_G.Safemode = Y;
	end,
});
getgenv().BFMultiHit = getgenv().BFMultiHit ~= false;
getgenv().BFMultiHitRadius = math.clamp(tonumber(getgenv().BFMultiHitRadius) or 80, 30, 150);
CF:AddToggle("BF_Toggle_Multi_Hit_Mode", {
	Text = "Expanded Multi-Hit (Poor Executor)",
	Tooltip = "Increase the fallback attack radius while keeping player targets excluded",
	Default = true,
	Callback = function(Y)
		getgenv().BFMultiHit = Y == true;
	end,
});
CF:AddSlider("BF_Slider_Multi_Hit_Radius", {
	Text = "Multi-Hit Radius",
	Tooltip = "Enemy search radius used by the fallback attack sender",
	Min = 30,
	Max = 150,
	Default = 80,
	Rounding = 0,
	Callback = function(Y)
		getgenv().BFMultiHitRadius = math.clamp(tonumber(Y) or 80, 30, 150);
	end,
});
task.spawn(function()
	while IdleWait(_G.Safemode, T) do
		pcall(function()
			if _G.Safemode then
				local humanoid = BFHumanoid();
				local character = d.Character;
				local root = character and character:FindFirstChild("HumanoidRootPart");
				if not humanoid or not root or humanoid.MaxHealth <= 0 then
					return;
				end;
				local healthPercent = (humanoid.Health / humanoid.MaxHealth) * 100;
				if healthPercent < P then
					shouldTween = true;
					_tp(root.CFrame * CFrame.new(0, 500, 0));
				else
					shouldTween = false;
				end;
			end;
		end);
	end;
end);
CF:AddToggle("BF_Toggle_Anti_AFK", {
	Text = "Anti AFK",
	Tooltip = "",
	Default = true,
	Callback = function(Y)
		_G.AntiAFK = Y;
	end,
});
UI.Library:GiveSignal(d.Idled:Connect(function()
	if not _G.AntiAFK then
		return;
	end;
	n:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame);
	task.wait(1);
	n:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame);
end));
UI.SelectedVisualSuppressions = { ["Hit VFX"] = true };
UI.DisableSelectedVisuals = false;
function UI.ApplySelectedVisualSuppressions()
	_G.DistroyHit = UI.DisableSelectedVisuals and UI.SelectedVisualSuppressions["Hit VFX"] == true;
	RDeath = UI.DisableSelectedVisuals and UI.SelectedVisualSuppressions["Death and Respawn VFX"] == true;
	RemoveDamage = UI.DisableSelectedVisuals and UI.SelectedVisualSuppressions.Notifications == true;
end;
CF:AddDropdown("BF_Dropdown_Selected_Visual_Suppressions", {
	Text = "Visual Suppression",
	Tooltip = "Choose visual effects and notifications to disable",
	Values = { "Hit VFX", "Death and Respawn VFX", "Notifications" },
	Default = { "Hit VFX" },
	Multi = true,
	NoMode = true,
	Callback = function(Y)
		UI.SelectedVisualSuppressions = Y or {};
		UI.ApplySelectedVisualSuppressions();
	end,
});
CF:AddToggle("BF_Toggle_Disable_Selected_Visuals", {
	Text = "Disable Selected",
	Tooltip = "Suppress every selected visual effect",
	Default = false,
	Callback = function(Y)
		UI.DisableSelectedVisuals = Y;
		UI.ApplySelectedVisualSuppressions();
	end,
});
task.spawn(function()
	while IdleWait(_G.DistroyHit, T) do
	if _G.DistroyHit then
			pcall(function()
				local worldOrigin = workspace:FindFirstChild("_WorldOrigin");
				if not worldOrigin then
					return;
				end;
				local effects = {
						"SlashHit",
						"CurvedRing",
						"SwordSlash",
						"SlashTail",
					};
				for _, effect in pairs(worldOrigin:GetChildren()) do
					if table.find(effects, effect.Name) then
						effect:Destroy();
					end;
				end;
			end);
		end;
	end;
end);
task.spawn(function()
	while IdleWait(RDeath, T) do
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
task.spawn(function()
	while IdleWait(RemoveDamage, T) do
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
local vF = UI.Sections["Stats Upgrade"];
vF:AddSlider("BF_Slider_Stats_Value", {
	Text = "Stats Value",
	Tooltip = "Choose how many stat points to spend per upgrade",
	Min = 1,
	Max = 1000,
	Default = 10,
	Rounding = 1,
	Callback = function(Y)
		pSats = Y;
	end,
});
local selectedStats = { Melee = true, Defense = true };
local autoUpgradeSelectedStats = false;
local function ApplySelectedStats()
	_G.Auto_Melee = autoUpgradeSelectedStats and selectedStats.Melee == true;
	_G.Auto_Defense = autoUpgradeSelectedStats and selectedStats.Defense == true;
	_G.Auto_Sword = autoUpgradeSelectedStats and selectedStats.Sword == true;
	_G.Auto_Gun = autoUpgradeSelectedStats and selectedStats.Gun == true;
	_G.Auto_DevilFruit = autoUpgradeSelectedStats and selectedStats["Blox Fruit"] == true;
	_G.Auto_Blox = _G.Auto_DevilFruit;
end;
vF:AddDropdown("BF_Dropdown_Selected_Stats", {
	Text = "Stats",
	Tooltip = "Choose one or more stats to upgrade",
	Values = { "Melee", "Defense", "Sword", "Gun", "Blox Fruit" },
	Default = { "Melee", "Defense" },
	Multi = true,
	NoMode = true,
	Callback = function(Y)
		selectedStats = Y or {};
		ApplySelectedStats();
	end,
});
vF:AddToggle("BF_Toggle_Auto_Upgrade_Selected_Stats", {
	Text = "Auto Upgrade Selected",
	Tooltip = "Spend points across the selected stats",
	Default = false,
	Callback = function(Y)
		autoUpgradeSelectedStats = Y;
		ApplySelectedStats();
	end,
});
UI.StatUpgradeIndex = 1;
task.spawn(function()
	local order = { "Melee", "Defense", "Sword", "Gun", "Devil" };
	while IdleWait(autoUpgradeSelectedStats, .2) do
		if autoUpgradeSelectedStats then
			pcall(function()
				local selected = nil;
				for _ = 1, #order do
					local stat = order[UI.StatUpgradeIndex];
					UI.StatUpgradeIndex = UI.StatUpgradeIndex % #order + 1;
					local flag = stat == "Devil" and _G.Auto_DevilFruit or _G["Auto_" .. stat];
					if flag then
						selected = stat;
						break;
					end;
				end;
				if selected then
					statsSetings(selected, pSats);
				end;
			end);
		end;
	end;
end);
local mF = UI.Sections["Fighting Melee Styles"];
UI.StyleStatus = {};
UI.StyleStatusLabels = {};
UI.StyleDisplayNames = {
	Superhuman = "Superhuman",
	DeathStep = "Death Step",
	SharkmanKarate = "Sharkman Karate",
	ElectricClaw = "Electric Claw",
};
UI.StyleNextRequest = {};
UI.StyleNextTravel = {};
UI.StyleSpecs = {
	BlackLeg = { Name = "Black Leg", Command = "BuyBlackLeg", Currency = "Beli", Cost = 150000 },
	Electro = { Name = "Electro", Command = "BuyElectro", Currency = "Beli", Cost = 500000 },
	FishmanKarate = { Name = "Fishman Karate", Command = "BuyFishmanKarate", Currency = "Beli", Cost = 750000 },
	DragonClaw = { Name = "Dragon Claw", Command = "BlackbeardReward", Args = { "DragonClaw", "2" }, Currency = "Fragments", Cost = 1500 },
};
UI.SuperhumanStyles = {
	UI.StyleSpecs.BlackLeg,
	UI.StyleSpecs.Electro,
	UI.StyleSpecs.FishmanKarate,
	UI.StyleSpecs.DragonClaw,
};
function UI.StyleSlug(value)
	return tostring(value or "style"):lower():gsub(" ", "-");
end;
function UI.SetStyleStatus(key, status)
	status = tostring(status or "working");
	if status ~= UI.StyleStatus[key] then
		UI.StyleStatus[key] = status;
		local label = UI.StyleStatusLabels[key];
		if label then
			label:SetText((UI.StyleDisplayNames[key] or key) .. ": " .. status:gsub("%-", " "));
		end;
	end;
end;
function UI.StyleRequestReady(key, interval)
	local now = os.clock();
	if now < (UI.StyleNextRequest[key] or 0) then
		return false;
	end;
	UI.StyleNextRequest[key] = now + (interval or 2);
	return true;
end;
function UI.StyleTravelReady(key)
	local now = os.clock();
	if now < (UI.StyleNextTravel[key] or 0) then
		return false;
	end;
	UI.StyleNextTravel[key] = now + 3;
	return true;
end;
function UI.RequestStyle(spec)
	if spec.Args then
		return BFComm(spec.Command, unpack(spec.Args));
	end;
	return BFComm(spec.Command);
end;
function UI.StyleMasteryStep(owner, spec, masteryRequired)
	local slug = UI.StyleSlug(spec.Name);
	if not GetIn(spec.Name) then
		UI.ReleaseManagedOwner(owner);
		local balance = tonumber(BFDataValue(spec.Currency)) or 0;
		if balance < spec.Cost then
			return false, "need-" .. tostring(spec.Cost) .. "-" .. spec.Currency:lower();
		end;
		if UI.StyleRequestReady(owner, 2) then
			UI.RequestStyle(spec);
		end;
		return false, "buying-" .. slug;
	end;
	if BFItemMasteryLike(spec.Name) >= masteryRequired then
		UI.ReleaseManagedOwner(owner);
		return true, "ready-" .. slug;
	end;
	local tool = BFFindLocalItemLike(spec.Name);
	if not tool then
		UI.ReleaseManagedOwner(owner);
		if UI.StyleRequestReady(owner, 2) then
			UI.RequestStyle(spec);
		end;
		return false, "loading-" .. slug;
	end;
	UI.DriveManagedValue(owner, "BFCombatWeapon", tool.Name);
	UI.DriveManagedFlag(owner, "Level");
	return false, "mastering-" .. slug;
end;
function UI.ResetStyleWorker(key, active)
	UI.StyleNextRequest[key] = 0;
	UI.StyleNextTravel[key] = 0;
	if not active then
		UI.ReleaseManagedOwner(key);
		if UI.StyleStatus[key] ~= "complete" then
			UI.SetStyleStatus(key, "idle");
		end;
	end;
end;
function UI.StartStyleWorker(flagName, key, toggleId, step)
	task.spawn(function()
		while IdleWait(_G[flagName], .25) do
			if _G[flagName] then
				local ok, status = pcall(step, _G[flagName]);
				status = ok and tostring(status or "working") or "error";
				if not ok then
					UI.ReleaseManagedOwner(key);
				end;
				UI.SetStyleStatus(key, status);
				if status == "complete" then
					UI.DisableToggle(toggleId);
				end;
			end;
		end;
		UI.ReleaseManagedOwner(key);
	end);
end;
mF:AddToggle("BF_Toggle_Auto_Superhuman", {
	Text = "Auto Superhuman",
	Tooltip = "Buy and master the four base styles, then purchase Superhuman",
	Default = false,
	Callback = function(Y)
		_G.Auto_SuperHuman = Y;
		UI.ResetStyleWorker("Superhuman", Y);
	end,
});
UI.StyleStatusLabels.Superhuman = mF:AddLabel({ DoesWrap = true, Text = "Superhuman: idle" });
function UI.SuperhumanStep(active)
	if not active then
		UI.ReleaseManagedOwner("Superhuman");
		return "idle";
	end;
	if GetIn("Superhuman") then
		UI.ReleaseManagedOwner("Superhuman");
		return "complete";
	end;
	for _, spec in ipairs(UI.SuperhumanStyles) do
		local ready, status = UI.StyleMasteryStep("Superhuman", spec, 300);
		if not ready then
			return status;
		end;
	end;
	UI.ReleaseManagedOwner("Superhuman");
	if UI.StyleRequestReady("Superhuman", 2) then
		BFComm("BuySuperhuman");
	end;
	return "buying-superhuman";
end;
UI.StartStyleWorker("Auto_SuperHuman", "Superhuman", "BF_Toggle_Auto_Superhuman", UI.SuperhumanStep);
mF:AddToggle("BF_Toggle_Auto_DeathStep", {
	Text = "Auto DeathStep",
	Tooltip = "Master Black Leg, unlock the Ice Castle library, and buy Death Step",
	Default = false,
	Callback = function(Y)
		_G.AutoDeathStep = Y;
		UI.ResetStyleWorker("DeathStep", Y);
	end,
});
UI.StyleStatusLabels.DeathStep = mF:AddLabel({ DoesWrap = true, Text = "Death Step: idle" });
function UI.DeathStepStep(active)
	if not active then
		UI.ReleaseManagedOwner("DeathStep");
		return "idle";
	end;
	if GetIn("Death Step") then
		UI.ReleaseManagedOwner("DeathStep");
		return "complete";
	end;
	local ready, status = UI.StyleMasteryStep("DeathStep", UI.StyleSpecs.BlackLeg, 400);
	if not ready then
		return status;
	end;
	UI.ReleaseManagedOwner("DeathStep");
	if UI.StyleRequestReady("DeathStep", 2) then
		BFComm("BuyDeathStep");
	end;
	if not World2 then
		if UI.StyleTravelReady("DeathStep") then
			BFComm("TravelDressrosa");
		end;
		return "traveling-to-second-sea";
	end;
	local door = BFMapNode("IceCastle", "Hall", "LibraryDoor", "PhoeyuDoor");
	if not door then
		BFMoveNear(CFrame.new(6371.2001953125, 296.63433837891, -6841.1811523438), 40);
		return "moving-to-library";
	end;
	local key = localItem("Library Key");
	if door and door:IsA("BasePart") and door.Transparency < 1 then
		if key then
			EquipWeapon(key.Name);
			BFMoveNear(door, 8);
			return "unlocking-library";
		end;
		local enemy = GetConnectionEnemies("Awakened Ice Admiral");
		if enemy then
			f.Kill(enemy, active);
			return "farming-library-key";
		end;
		BFMoveNear(CFrame.new(5668.9780273438, 28.519989013672, -6483.3520507813), 40);
		return "waiting-for-ice-admiral";
	end;
	if key and door then
		EquipWeapon(key.Name);
		BFMoveNear(door, 8);
	end;
	return door and "buying-death-step" or "waiting-for-library";
end;
UI.StartStyleWorker("AutoDeathStep", "DeathStep", "BF_Toggle_Auto_DeathStep", UI.DeathStepStep);
mF:AddToggle("BF_Toggle_Auto_Sharkman_Karate", {
	Text = "Auto Sharkman Karate",
	Tooltip = "Master Fishman Karate, obtain the Water Key, and buy Sharkman Karate",
	Default = false,
	Callback = function(Y)
		_G.Auto_SharkMan_Karate = Y;
		UI.ResetStyleWorker("SharkmanKarate", Y);
	end,
});
UI.StyleStatusLabels.SharkmanKarate = mF:AddLabel({ DoesWrap = true, Text = "Sharkman Karate: idle" });
function UI.SharkmanKarateStep(active)
	if not active then
		UI.ReleaseManagedOwner("SharkmanKarate");
		return "idle";
	end;
	if GetIn("Sharkman Karate") then
		UI.ReleaseManagedOwner("SharkmanKarate");
		return "complete";
	end;
	local ready, status = UI.StyleMasteryStep("SharkmanKarate", UI.StyleSpecs.FishmanKarate, 400);
	if not ready then
		return status;
	end;
	UI.ReleaseManagedOwner("SharkmanKarate");
	if not World2 then
		if UI.StyleTravelReady("SharkmanKarate") then
			BFComm("TravelDressrosa");
		end;
		return "traveling-to-second-sea";
	end;
	local key = localItem("Water Key");
	if not key then
		local enemy = GetConnectionEnemies("Tide Keeper");
		if enemy then
			f.Kill(enemy, active);
			return "farming-water-key";
		end;
		BFMoveNear(CFrame.new(-3053.9814453125, 237.18954467773, -10145.0390625), 40);
		return "waiting-for-tide-keeper";
	end;
	EquipWeapon(key.Name);
	local npc, npcRoot = BFFindNpc("Daigrock");
	local target = npcRoot or BFFirstPart(npc) or CFrame.new(-2604.6958, 239.432526, -10315.1982, .0425701365, 0, -0.999093413, 0, 1, 0, .999093413, 0, .0425701365);
	if not BFMoveNear(target, 8) then
		return "moving-to-daigrock";
	end;
	if UI.StyleRequestReady("SharkmanKarate", 2) then
		BFComm("BuySharkmanKarate");
	end;
	return "buying-sharkman-karate";
end;
UI.StartStyleWorker("Auto_SharkMan_Karate", "SharkmanKarate", "BF_Toggle_Auto_Sharkman_Karate", UI.SharkmanKarateStep);
mF:AddToggle("BF_Toggle_Auto_ElectricClaw", {
	Text = "Auto ElectricClaw",
	Tooltip = "Master Electro, complete the Previous Hero route, and buy Electric Claw",
	Default = false,
	Callback = function(Y)
		_G.Auto_Electric_Claw = Y;
		UI.ResetStyleWorker("ElectricClaw", Y);
	end,
});
UI.StyleStatusLabels.ElectricClaw = mF:AddLabel({ DoesWrap = true, Text = "Electric Claw: idle" });
function UI.ElectricClawStep(active)
	if not active then
		UI.ReleaseManagedOwner("ElectricClaw");
		return "idle";
	end;
	if GetIn("Electric Claw") then
		UI.ReleaseManagedOwner("ElectricClaw");
		return "complete";
	end;
	local ready, status = UI.StyleMasteryStep("ElectricClaw", UI.StyleSpecs.Electro, 400);
	if not ready then
		return status;
	end;
	UI.ReleaseManagedOwner("ElectricClaw");
	if not World3 then
		if UI.StyleTravelReady("ElectricClaw") then
			if World2 then
				BFComm("TravelZou");
			else
				BFComm("TravelDressrosa");
			end;
		end;
		return "traveling-to-third-sea";
	end;
	local npc, npcRoot = BFFindNpc("Previous Hero");
	local target = npcRoot or BFFirstPart(npc) or CFrame.new(-12548, 337, -7481);
	if not BFMoveNear(target, 8) then
		return "moving-to-previous-hero";
	end;
	if UI.StyleRequestReady("ElectricClaw", 2) then
		BFComm("BuyElectricClaw", "Start");
		BFComm("BuyElectricClaw");
	end;
	return "buying-electric-claw";
end;
UI.StartStyleWorker("Auto_Electric_Claw", "ElectricClaw", "BF_Toggle_Auto_ElectricClaw", UI.ElectricClawStep);
mF:AddToggle("BF_Toggle_Auto_DragonTalon", {
	Text = "Auto DragonTalon",
	Tooltip = "Master Dragon Claw, obtain Fire Essence with permission, and buy Dragon Talon",
	Default = false,
	Callback = function(Y)
		_G.AutoDragonTalon = Y;
		if Y then
			UI.DragonTalonNextClawAt = 0;
			UI.DragonTalonNextRollAt = 0;
			UI.DragonTalonNextPurchaseAt = 0;
			UI.DragonTalonNextTravelAt = 0;
		else
			UI.ReleaseManagedOwner("DragonTalon");
			if UI.DragonTalonStatus ~= "complete" then
				UI.SetDragonTalonStatus("idle");
			end;
		end;
	end,
});
UI.DragonTalonStatus = "idle";
UI.DragonTalonStatusLabel = nil;
UI.DragonTalonNextClawAt = 0;
UI.DragonTalonNextRollAt = 0;
UI.DragonTalonNextPurchaseAt = 0;
UI.DragonTalonNextTravelAt = 0;
function UI.SetDragonTalonStatus(status)
	status = tostring(status or "working");
	if status ~= UI.DragonTalonStatus then
		UI.DragonTalonStatus = status;
		if UI.DragonTalonStatusLabel then
			UI.DragonTalonStatusLabel:SetText("Dragon Talon: " .. status:gsub("%-", " "));
		end;
	end;
end;
UI.DragonTalonStatusLabel = mF:AddLabel({ DoesWrap = true, Text = "Dragon Talon: idle" });
function UI.DragonTalonStep(active)
	if not active then
		return "idle";
	end;
	if GetIn("Dragon Talon") then
		UI.ReleaseManagedOwner("DragonTalon");
		return "complete";
	end;
	local now = os.clock();
	if not GetIn("Dragon Claw") then
		UI.ReleaseManagedOwner("DragonTalon");
		if now >= UI.DragonTalonNextClawAt then
			UI.DragonTalonNextClawAt = now + 2;
			BFComm("BlackbeardReward", "DragonClaw", "2");
		end;
		return "buying-dragon-claw";
	end;
	if BFItemMasteryLike("Dragon Claw") < 400 then
		local tool = BFFindLocalItemLike("Dragon Claw");
		if not tool then
			UI.ReleaseManagedOwner("DragonTalon");
			if now >= UI.DragonTalonNextClawAt then
				UI.DragonTalonNextClawAt = now + 2;
				BFComm("BlackbeardReward", "DragonClaw", "2");
			end;
			return "loading-dragon-claw";
		end;
		UI.DriveManagedValue("DragonTalon", "BFCombatWeapon", tool.Name);
		UI.DriveManagedFlag("DragonTalon", "Level");
		return "mastering-dragon-claw";
	end;
	if not World3 then
		UI.ReleaseManagedOwner("DragonTalon");
		if now >= UI.DragonTalonNextTravelAt then
			UI.DragonTalonNextTravelAt = now + 3;
			if World2 then
				BFComm("TravelZou");
			else
				BFComm("TravelDressrosa");
			end;
		end;
		return "traveling-to-third-sea";
	end;
	if not GetIn("Fire Essence") then
		if GetBones() < 50 then
			UI.ReleaseManagedValue("DragonTalon", "BFCombatWeapon");
			UI.DriveManagedFlag("DragonTalon", "AutoFarm_Bone");
			return "farming-bones";
		end;
		UI.ReleaseManagedOwner("DragonTalon");
		if not _G.BFAllowBoneSpending then
			return "awaiting-spend-permission";
		end;
		if now >= UI.DragonTalonNextRollAt then
			UI.DragonTalonNextRollAt = now + 1;
			BFComm("Bones", "Buy", 1, 1);
		end;
		return "rolling-fire-essence";
	end;
	UI.ReleaseManagedOwner("DragonTalon");
	if now >= UI.DragonTalonNextPurchaseAt then
		UI.DragonTalonNextPurchaseAt = now + 2;
		BFComm("BuyDragonTalon");
	end;
	return "buying-dragon-talon";
end;
task.spawn(function()
	while IdleWait(_G.AutoDragonTalon, .25) do
		if _G.AutoDragonTalon then
			local ok, status = pcall(UI.DragonTalonStep, _G.AutoDragonTalon);
			status = ok and tostring(status or "working") or "error";
			UI.SetDragonTalonStatus(status);
			if status == "complete" then
				UI.DisableToggle("BF_Toggle_Auto_DragonTalon");
			end;
		end;
	end;
	UI.ReleaseManagedOwner("DragonTalon");
end);
mF:AddToggle("BF_Toggle_Auto_Godhuman", {
	Text = "Auto Godhuman",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		_G.Auto_God_Human = Y;
		if Y then
			UI.GodhumanNextCheckAt = 0;
			UI.GodhumanNextTravelAt = 0;
			UI.GodhumanNextPurchaseAt = 0;
		elseif UI.GodhumanStatus ~= "complete" then
			UI.ReleaseManagedOwner("Godhuman");
			UI.SetGodhumanStatus("idle");
		end;
	end,
});
UI.GodhumanStatus = "idle";
UI.GodhumanCheck = nil;
UI.GodhumanNextCheckAt = 0;
UI.GodhumanNextTravelAt = 0;
UI.GodhumanNextPurchaseAt = 0;
UI.GodhumanRequirements = {
	{ Name = "Dragon Scale", Count = 10, World = 3 },
	{ Name = "Fish Tail", Count = 20, World = 3 },
	{ Name = "Mystic Droplet", Count = 10, World = 2 },
	{ Name = "Magma Ore", Count = 20, World = 2 },
};
function UI.SetGodhumanStatus(status)
	status = tostring(status or "working");
	if status ~= UI.GodhumanStatus then
		UI.GodhumanStatus = status;
		if UI.GodhumanStatusLabel then
			UI.GodhumanStatusLabel:SetText("Godhuman: " .. status:gsub("%-", " "));
		end;
	end;
end;
UI.GodhumanStatusLabel = mF:AddLabel({ DoesWrap = true, Text = "Godhuman: idle" });
function UI.GodhumanStep(active)
	if not active then
		UI.ReleaseManagedOwner("Godhuman");
		return "idle";
	end;
	if GetIn("Godhuman") then
		UI.ReleaseManagedOwner("Godhuman");
		return "complete";
	end;
	local now = os.clock();
	if now >= UI.GodhumanNextCheckAt then
		UI.GodhumanNextCheckAt = now + 2;
		UI.GodhumanCheck = BFComm("BuyGodhuman", true);
	end;
	local requirement = nil;
	for _, candidate in ipairs(UI.GodhumanRequirements) do
		if (tonumber(GetM(candidate.Name)) or 0) < candidate.Count then
			requirement = candidate;
			break;
		end;
	end;
	if requirement then
		local inRequiredWorld = requirement.World == 3 and World3 or requirement.World == 2 and World2;
		if inRequiredWorld then
			UI.DriveManagedValue("Godhuman", "SelectMaterial", requirement.Name);
			UI.DriveManagedFlag("Godhuman", "AutoMaterial");
			return "farming-" .. requirement.Name:lower():gsub(" ", "-");
		end;
		UI.ReleaseManagedOwner("Godhuman");
		if now >= UI.GodhumanNextTravelAt then
			UI.GodhumanNextTravelAt = now + 3;
			if requirement.World == 3 and World2 then
				BFComm("TravelZou");
			else
				BFComm("TravelDressrosa");
			end;
		end;
		return requirement.World == 3 and "traveling-to-third-sea" or "traveling-to-second-sea";
	end;
	UI.ReleaseManagedOwner("Godhuman");
	if UI.GodhumanCheck == 3 then
		return "waiting-for-style-requirements";
	end;
	if now >= UI.GodhumanNextPurchaseAt then
		UI.GodhumanNextPurchaseAt = now + 2;
		BFComm("BuyGodhuman");
	end;
	return "buying-godhuman";
end;
task.spawn(function()
	while IdleWait(_G.Auto_God_Human, .25) do
		if _G.Auto_God_Human then
			local ok, status = pcall(UI.GodhumanStep, _G.Auto_God_Human);
			status = ok and tostring(status or "working") or "error";
			if not ok then
				UI.ReleaseManagedOwner("Godhuman");
			end;
			UI.SetGodhumanStatus(status);
			if status == "complete" then
				UI.DisableToggle("BF_Toggle_Auto_Godhuman");
			end;
		end;
	end;
	UI.ReleaseManagedOwner("Godhuman");
end);
UI.SanguineStatus = "idle";
UI.SanguineStatusLabel = nil;
UI.SanguineNextRequestAt = 0;
UI.SanguineNextPurchaseAt = 0;
UI.SanguineNextTravelAt = 0;
UI.SanguineDarkArena = CFrame.new(3798.4575195313, 13.826690673828, -3399.806640625);
function UI.SetSanguineStatus(status)
	status = tostring(status or "working");
	if status ~= UI.SanguineStatus then
		UI.SanguineStatus = status;
		if UI.SanguineStatusLabel then
			UI.SanguineStatusLabel:SetText("Sanguine Art: " .. status:gsub("%-", " "));
		end;
	end;
end;
function UI.SanguineTravel(targetWorld, now)
	UI.ReleaseManagedOwner("Sanguine");
	if now >= UI.SanguineNextTravelAt then
		UI.SanguineNextTravelAt = now + 3;
		if targetWorld == 3 and World2 then
			BFComm("TravelZou");
		else
			BFComm("TravelDressrosa");
		end;
	end;
	return targetWorld == 3 and "traveling-to-third-sea" or "traveling-to-second-sea";
end;
mF:AddToggle("BF_Toggle_Auto_SanguineArt", {
	Text = "Auto Sanguine Art",
	Tooltip = "Farm each required material in order, travel between seas, then buy Sanguine Art",
	Default = false,
	Callback = function(Y)
		_G.snaguine = Y;
		if Y then
			UI.SanguineNextRequestAt = 0;
			UI.SanguineNextPurchaseAt = 0;
			UI.SanguineNextTravelAt = 0;
		elseif UI.SanguineStatus ~= "complete" then
			UI.ReleaseManagedOwner("Sanguine");
			UI.SetSanguineStatus("idle");
		end;
	end,
});
UI.SanguineStatusLabel = mF:AddLabel({ DoesWrap = true, Text = "Sanguine Art: idle" });
function UI.SanguineStep(active)
	if not active then
		UI.ReleaseManagedOwner("Sanguine");
		return "idle";
	end;
	if GetIn("Sanguine Art") then
		UI.ReleaseManagedOwner("Sanguine");
		return "complete";
	end;
	local now = os.clock();
	if now >= UI.SanguineNextRequestAt then
		UI.SanguineNextRequestAt = now + 2;
		BFComm("Sanguine Art");
	end;
	local heart = tonumber(GetM("Leviathan Heart")) or 0;
	local fangs = tonumber(GetM("Vampire Fang")) or 0;
	local wisps = tonumber(GetM("Demonic Wisp")) or 0;
	local darkFragments = tonumber(GetM("Dark Fragment")) or 0;
	if heart < 1 then
		if not World3 then
			return UI.SanguineTravel(3, now);
		end;
		UI.DriveManagedValue("Sanguine", "DangerSc", "Lv Infinite");
		UI.DriveManagedFlag("Sanguine", "SailBoats");
		return "hunting-leviathan-heart";
	end;
	if fangs < 20 then
		if not World2 then
			return UI.SanguineTravel(2, now);
		end;
		UI.DriveManagedValue("Sanguine", "SelectMaterial", "Vampire Fang");
		UI.DriveManagedFlag("Sanguine", "AutoMaterial");
		return "farming-vampire-fangs";
	end;
	if wisps < 20 then
		if not World3 then
			return UI.SanguineTravel(3, now);
		end;
		UI.DriveManagedValue("Sanguine", "SelectMaterial", "Demonic Wisp");
		UI.DriveManagedFlag("Sanguine", "AutoMaterial");
		return "farming-demonic-wisps";
	end;
	UI.ReleaseManagedOwner("Sanguine");
	if darkFragments < 1 then
		if not World2 then
			return UI.SanguineTravel(2, now);
		end;
		local enemy = GetConnectionEnemies("Darkbeard");
		if enemy then
			f.Kill(enemy, active);
			return "fighting-darkbeard";
		end;
		BFMoveNear(UI.SanguineDarkArena, 40);
		return "waiting-for-darkbeard";
	end;
	if now >= UI.SanguineNextPurchaseAt then
		UI.SanguineNextPurchaseAt = now + 2;
		BFComm("BuySanguineArt");
	end;
	return "buying-sanguine-art";
end;
task.spawn(function()
	while IdleWait(_G.snaguine, .25) do
		if _G.snaguine then
			local ok, status = pcall(UI.SanguineStep, _G.snaguine);
			status = ok and tostring(status or "working") or "error";
			if not ok then
				UI.ReleaseManagedOwner("Sanguine");
			end;
			UI.SetSanguineStatus(status);
			if status == "complete" then
				UI.DisableToggle("BF_Toggle_Auto_SanguineArt");
			end;
		end;
	end;
	UI.ReleaseManagedOwner("Sanguine");
end);
local yF = UI.Sections["Tushita + Yama"];
local bF = yF:AddLabel({ DoesWrap = true, Text = "Elites Process " });
task.spawn(function()
	while UI.LabelWait(5) do
		pcall(function()
			bF:SetText("Elite Progress: " .. BFComm("EliteHunter", "Progress"));
		end);
	end;
end);
UI.RegisterManagedFlag("FarmEliteHunt", false);
yF:AddToggle("BF_Toggle_Auto_Elite_Quest", {
	Text = "Auto Elite Quest",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		UI.SetManagedUserFlag("FarmEliteHunt", Y);
	end,
});
task.spawn(function()
	while IdleWait(_G.FarmEliteHunt, T) do
		pcall(function()
			if _G.FarmEliteHunt then
				if GuiShown("Quest") then
					if string.find(QuestText(), "Diablo") or string.find(QuestText(), "Urban") or string.find(QuestText(), "Deandre") then
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
								until not _G.FarmEliteHunt or not GuiShown("Quest") or not R.Parent or R.Humanoid.Health <= 0;
							end;
						end;
					end;
				else
					BFComm("EliteHunter");
				end;
			end;
		end);
	end;
end);
yF:AddToggle("BF_Toggle_Stop_when_got_God_s_Chalice", {
	Text = "Stop when got God\'s Chalice",
	Tooltip = "",
	Default = true,
	Callback = function(Y)
		_G.StopWhenChalice = Y;
		if not Y then
			UI.ReleaseManagedFlag("StopWhenChalice", "FarmEliteHunt");
		end;
	end,
});
task.spawn(function()
	while IdleWait(_G.StopWhenChalice, .2) do
		local shouldStop = false;
		if _G.StopWhenChalice then
			pcall(function()
				shouldStop = GetBP("God\'s Chalice") or GetBP("Sweet Chalice") or GetBP("Fist of Darkness");
			end);
		end;
		if shouldStop then
			UI.SuppressManagedFlag("StopWhenChalice", "FarmEliteHunt");
		else
			UI.ReleaseManagedFlag("StopWhenChalice", "FarmEliteHunt");
		end;
	end;
	UI.ReleaseManagedFlag("StopWhenChalice", "FarmEliteHunt");
end);
yF:AddToggle("BF_Toggle_Auto_Tushita_Sword", {
	Text = "Auto Tushita Sword",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		_G.Auto_Tushita = Y;
	end,
});
task.spawn(function()
	while IdleWait(_G.Auto_Tushita, T) do
		pcall(function()
			if _G.Auto_Tushita then
				if BFStopOwnedAcquisition("BF_Toggle_Auto_Tushita_Sword") then
					return;
				end;
				if BFMapNode("Turtle", "TushitaGate") then
					if not GetBP("Holy Torch") then
						_tp(CFrame.new(5148.03613, 162.352493, 910.548218));
						task.wait(.7);
					else
						EquipWeapon("Holy Torch");
						task.wait(1);
						for _, target in ipairs({
							CFrame.new(-10752, 417, -9366),
							CFrame.new(-11672, 334, -9474),
							CFrame.new(-12132, 521, -10655),
							CFrame.new(-13336, 486, -6985),
							CFrame.new(-13489, 332, -7925),
						}) do
							repeat
								task.wait();
							until not _G.Auto_Tushita or BFMoveNear(target, 10);
							if not _G.Auto_Tushita then
								break;
							end;
							task.wait(.7);
						end;
					end;
				else
					local Y = GetConnectionEnemies("Longma");
					if Y then
						repeat
							task.wait();
							f.Kill(Y, _G.Auto_Tushita);
						until not _G.Auto_Tushita or not Y.Parent or not f.Alive(Y);
					else
						local stored = Q:FindFirstChild("Longma");
						local storedRoot = BFFirstPart(stored);
						if storedRoot then
							_tp(storedRoot.CFrame * CFrame.new(0, 40, 0));
						end;
					end;
				end;
			end;
		end);
	end;
end);
yF:AddToggle("BF_Toggle_Auto_Yama_Sword", {
	Text = "Auto Yama Sword",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		_G.Auto_Yama = Y;
		if not Y then
			UI.ReleaseManagedFlag("AutoYama", "FarmEliteHunt");
		end;
	end,
});
task.spawn(function()
	while IdleWait(_G.Auto_Yama, T) do
		pcall(function()
			if _G.Auto_Yama then
				if BFStopOwnedAcquisition("BF_Toggle_Auto_Yama_Sword") then
					return;
				end;
				local progress = BFComm("EliteHunter", "Progress");
				if type(progress) == "number" and progress < 30 then
					UI.DriveManagedFlag("AutoYama", "FarmEliteHunt");
				elseif type(progress) == "number" and progress >= 30 then
					UI.ReleaseManagedFlag("AutoYama", "FarmEliteHunt");
					local map = workspace:FindFirstChild("Map");
					local waterfall = map and map:FindFirstChild("Waterfall");
					local katana = waterfall and waterfall:FindFirstChild("SealedKatana");
					local handle = katana and katana:FindFirstChild("Handle");
					local root = i and i:FindFirstChild("HumanoidRootPart");
					if handle and root then
						if (handle.Position - root.Position).Magnitude >= 20 then
							_tp(handle.CFrame);
						end;
						local Y = GetConnectionEnemies("Ghost");
						if Y then
							repeat
								task.wait();
								f.Kill(Y, _G.Auto_Yama);
							until not _G.Auto_Yama or not Y.Parent or not f.Alive(Y);
						end;
						local clickDetector = handle:FindFirstChildOfClass("ClickDetector");
						if clickDetector and type(fireclickdetector) == "function" and (handle.Position - root.Position).Magnitude < 20 then
							pcall(fireclickdetector, clickDetector);
						end;
					end;
				end;
			end;
		end);
	end;
	UI.ReleaseManagedFlag("AutoYama", "FarmEliteHunt");
end);
local cF = UI.Sections["Cursed Dual Katana"];
local HF = cF:AddLabel({ DoesWrap = true, Text = " Number Cursed dual katana quests Quest Numbers :" });
task.spawn(function()
	while UI.LabelWait(.2) do
		if QuestYama_1 == true then
			HF:SetText(" Quest Numbers : yama quest 1");
		elseif QuestYama_2 == true then
			HF:SetText(" Quest Numbers : yama quest 2");
		elseif QuestYama_3 == true then
			HF:SetText(" Quest Numbers : yama quest 3");
		elseif QuestTushita_1 == true then
			HF:SetText(" Quest Numbers : tushita quest 1");
		elseif QuestTushita_2 == true then
			HF:SetText(" Quest Numbers : tushita quest 2");
		elseif QuestTushita_3 == true then
			HF:SetText(" Quest Numbers: tushita quest 3");
		elseif GetWP("Cursed Dual Katana") then
			HF:SetText(" Quest Numbers: CDK done!!");
		end;
	end;
end);
cF:AddToggle("BF_Toggle_Auto_Get_CDK_Last_Quest", {
	Text = "Auto Get CDK [ Last Quest ]",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		_G.CDK = Y;
	end,
});
task.spawn(function()
	while IdleWait(_G.CDK, T) do
		pcall(function()
			if _G.CDK then
				if BFStopOwnedAcquisition("BF_Toggle_Auto_Get_CDK_Last_Quest") then
					return;
				end;
				BFComm("CDKQuest", "Progress", "Good");
				BFComm("CDKQuest", "Progress", "Evil");
				BFComm("CDKQuest", "StartTrial", "Boss");
				local Y = GetConnectionEnemies("Cursed Skeleton Boss");
				if Y then
					repeat
						task.wait();
						if localItem("Yama") then
							EquipWeapon("Yama");
						elseif localItem("Tushita") then
							EquipWeapon("Tushita");
						end;
						local root = Y:FindFirstChild("HumanoidRootPart");
						if not root then
							break;
						end;
						_tp(root.CFrame * CFrame.new(0, 20, 0));
					until not _G.CDK or not Y.Parent or not f.Alive(Y);
				else
					_tp(CFrame.new(-12318.193359375, 601.95184326172, -6538.662109375));
					task.wait(.5);
					local bossDoor = BFMapNode("Turtle", "Cursed", "BossDoor");
					if bossDoor and bossDoor:IsA("BasePart") then
						_tp(bossDoor.CFrame);
					end;
				end;
			end;
		end);
	end;
end);
cF:AddToggle("BF_Toggle_Auto_Yama_CDK", {
	Text = "Auto Yama CDK",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		_G.CDK_YM = Y;
		if Y then
			_G.T1Yama = false;
			_G.T2Yama = false;
			_G.T3Yama = false;
		end;
	end,
});
task.spawn(function()
	while IdleWait(_G.CDK_YM) do
		pcall(function()
			if _G.CDK_YM then
				if BFStopOwnedAcquisition("BF_Toggle_Auto_Yama_CDK") then
					return;
				end;
				if tostring(BFComm("CDKQuest", "OpenDoor")) ~= "opened" then
					BFComm("CDKQuest", "OpenDoor");
					BFComm("CDKQuest", "OpenDoor", true);
				else
					local finished, progressReady = BFCDKProgress("Finished");
					if not progressReady then
						return;
					end;
					if finished == nil then
						BFComm("CDKQuest", "StartTrial", "Evil");
					elseif finished == false then
						if tonumber(BFCDKProgress("Evil")) == -3 then
							QuestYama_1 = true;
							QuestYama_2 = false;
							QuestYama_3 = false;
							repeat
								task.wait();
								if not workspace.Enemies:FindFirstChild("Forest Pirate") then
									_tp(CFrame.new(-13223.521484375, 428.19381713867, -7766.0678710938));
								else
									local enemy = GetConnectionEnemies("Forest Pirate");
									local root = BFFirstPart(enemy);
									if root then
										_tp(root.CFrame);
									end;
								end;
							until tonumber(BFCDKProgress("Evil")) == 1 or not _G.CDK_YM;
						elseif tonumber(BFCDKProgress("Evil")) == -4 then
							QuestYama_1 = false;
							QuestYama_2 = true;
							QuestYama_3 = false;
							local questHaze = d:FindFirstChild("QuestHaze");
							local playerRoot = i and i:FindFirstChild("HumanoidRootPart");
							for _, haze in pairs(questHaze and questHaze:GetChildren() or {}) do
								for enemyName, spawn in pairs(e or {}) do
									if string.find(tostring(enemyName), haze.Name, 1, true) and (tonumber(haze.Value) or 0) > 0 then
										if playerRoot and (spawn.Position - playerRoot.Position).Magnitude <= 1000 and workspace.Enemies:FindFirstChild(enemyName) then
											for _, enemy in pairs(workspace.Enemies:GetChildren()) do
												if enemy:FindFirstChild("HazeESP") and f.Alive(enemy) then
													repeat
														task.wait();
														f.Kill(enemy, _G.CDK_YM);
													until not _G.CDK_YM or tonumber(BFCDKProgress("Evil")) == 2 or not enemy:FindFirstChild("HazeESP") or not f.Alive(enemy);
												end;
											end;
										else
											_tp(spawn);
										end;
									end;
								end;
							end;
						elseif tonumber(BFCDKProgress("Evil")) == -5 then
							QuestYama_1 = false;
							QuestYama_2 = false;
							QuestYama_3 = true;
							local hellDimension = BFMapNode("HellDimension");
							local hellSpawn = hellDimension and hellDimension:FindFirstChild("Spawn");
							local hellExit = hellDimension and hellDimension:FindFirstChild("Exit");
							local currentRoot = BFCharacterPart();
							if hellDimension and hellSpawn and hellSpawn:IsA("BasePart") and currentRoot then
								if (currentRoot.Position - hellSpawn.Position).Magnitude <= 1000 then
									for Y, d in pairs(hellExit and hellExit:GetChildren() or {}) do
										if tonumber(Y) == 2 then
											repeat
												task.wait();
												local root = BFCharacterPart();
												if root and hellExit:IsA("BasePart") then
													root.CFrame = hellExit.CFrame;
												end;
										until not _G.CDK_YM or tonumber(BFCDKProgress("Evil")) == 3;
										end;
									end;
									EquipWeapon(_G.SelectWeapon);
									if tonumber(BFCDKProgress("Evil")) ~= 3 then
										local torch1 = hellDimension:FindFirstChild("Torch1");
										local torch1Particles = torch1 and torch1:FindFirstChild("Particles");
										if torch1Particles and torch1Particles:IsA("BasePart") then
										repeat
											task.wait();
											repeat
												task.wait();
												_tp(torch1Particles.CFrame);
												local torchRoot = BFCharacterPart();
												for Y, d in pairs(hellDimension:GetDescendants()) do
													if d:IsA("ProximityPrompt") and type(fireproximityprompt) == "function" then
														pcall(fireproximityprompt, d);
													end;
												end;
											until not _G.CDK_YM or torchRoot and (torch1Particles.Position - torchRoot.Position).Magnitude < 5;
											task.wait(2);
											_G.T1Yama = true;
									until not _G.CDK_YM or _G.T1Yama or tonumber(BFCDKProgress("Evil")) == 3;
										end;
										local torch2 = hellDimension:FindFirstChild("Torch2");
										local torch2Particles = torch2 and torch2:FindFirstChild("Particles");
										if torch2Particles and torch2Particles:IsA("BasePart") then
										repeat
											task.wait();
											repeat
												task.wait();
												_tp(torch2Particles.CFrame);
												local torchRoot = BFCharacterPart();
												for Y, d in pairs(hellDimension:GetDescendants()) do
													if d:IsA("ProximityPrompt") and type(fireproximityprompt) == "function" then
														pcall(fireproximityprompt, d);
													end;
												end;
											until not _G.CDK_YM or torchRoot and (torch2Particles.Position - torchRoot.Position).Magnitude < 5;
											task.wait(2);
											_G.T2Yama = true;
									until _G.T2Yama or _G.CDK_YM == false or tonumber(BFCDKProgress("Evil")) == 3;
										end;
										local torch3 = hellDimension:FindFirstChild("Torch3");
										local torch3Particles = torch3 and torch3:FindFirstChild("Particles");
										if torch3Particles and torch3Particles:IsA("BasePart") then
										repeat
											task.wait();
											repeat
												task.wait();
												_tp(torch3Particles.CFrame);
												local torchRoot = BFCharacterPart();
												for Y, d in pairs(hellDimension:GetDescendants()) do
													if d:IsA("ProximityPrompt") and type(fireproximityprompt) == "function" then
														pcall(fireproximityprompt, d);
													end;
												end;
											until not _G.CDK_YM or torchRoot and (torch3Particles.Position - torchRoot.Position).Magnitude < 5;
											task.wait(2);
											_G.T3Yama = true;
									until _G.T3Yama or _G.CDK_YM == false or tonumber(BFCDKProgress("Evil")) == 3;
										end;
									end;
									for Y, d in pairs(M:GetChildren()) do
										local root = d:FindFirstChild("HumanoidRootPart");
										local humanoid = d:FindFirstChild("Humanoid");
										if root and humanoid and humanoid.Health > 0 and (root.Position - hellSpawn.Position).Magnitude <= 300 then
												repeat
													task.wait();
													f.Kill(d, _G.CDK_YM);
											until not _G.CDK_YM or not d.Parent or not f.Alive(d) or tonumber(BFCDKProgress("Evil")) == 3;
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
	while IdleWait(_G.CDK_YM) do
		pcall(function()
			if _G.CDK_YM then
				if BFStopOwnedAcquisition("BF_Toggle_Auto_Yama_CDK") then
					return;
				end;
				if tonumber(BFCDKProgress("Evil")) == -5 then
					local function InHellDimension()
						local spawn = BFMapNode("HellDimension", "Spawn");
						local root = i and i:FindFirstChild("HumanoidRootPart");
						return spawn and spawn:IsA("BasePart") and root and (root.Position - spawn.Position).Magnitude <= 1000 or false;
					end;
					if not InHellDimension() then
						local Y = GetConnectionEnemies("Soul Reaper");
						if Y then
							repeat
								task.wait();
								local root = BFFirstPart(Y);
								if not root then
									break;
								end;
								_tp(root.CFrame);
							until not _G.CDK_YM or not Y.Parent or not f.Alive(Y) or tonumber(BFCDKProgress("Evil")) == 3 or InHellDimension();
						elseif localItem("Hallow Essence") then
							local target = CFrame.new(-8932.322265625, 146.83154296875, 6062.55078125);
							repeat
								_tp(target);
								task.wait();
								local root = i and i:FindFirstChild("HumanoidRootPart");
							until not _G.CDK_YM or root and (target.Position - root.Position).Magnitude <= 8;
							if _G.CDK_YM then
								EquipWeapon("Hallow Essence");
							end;
						else
							local storedSoulReaper = Q:FindFirstChild("Soul Reaper");
							local storedRoot = f.Alive(storedSoulReaper) and BFFirstPart(storedSoulReaper) or nil;
							if storedRoot then
								_tp(storedRoot.CFrame);
							else
								local bones = tonumber(BFComm("Bones", "Check")) or 0;
								if bones < 50 and (not workspace.Enemies:FindFirstChild("Soul Reaper") and (not storedSoulReaper and not BFMapNode("HellDimension"))) then
									if M:FindFirstChild("Reborn Skeleton") or M:FindFirstChild("Living Zombie") or M:FindFirstChild("Demonic Soul") or M:FindFirstChild("Posessed Mummy") then
										for Y, d in pairs(M:GetChildren()) do
											if d.Name == "Reborn Skeleton" or d.Name == "Living Zombie" or d.Name == "Demonic Soul" or d.Name == "Posessed Mummy" then
												if d:FindFirstChild("HumanoidRootPart") and (d:FindFirstChild("Humanoid") and (d:FindFirstChild("Humanoid")).Health > 0) then
													repeat
														task.wait();
														f.Kill(d, _G.CDK_YM);
													until not _G.CDK_YM or not d.Parent or not f.Alive(d);
												end;
											end;
										end;
									else
										_tp(CFrame.new(-9515.2255859375, 164.00622558594, 5785.3833007812));
									end;
								elseif _G.BFAllowBoneSpending then
									BFComm("Bones", "Buy", 1, 1);
								end;
							end;
						end;
					end;
				end;
			end;
		end);
	end;
end);
cF:AddToggle("BF_Toggle_Auto_Tushita_CDK", {
	Text = "Auto Tushita CDK",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		_G.CDK_TS = Y;
		if Y then
			_G.DoneT1 = false;
			_G.DoneT2 = false;
			_G.DoneT3 = false;
		else
			UI.ReleaseManagedFlag("CDKTushita", "AutoRaidCastle");
		end;
	end,
});
task.spawn(function()
	while IdleWait(_G.CDK_TS) do
		pcall(function()
			if _G.CDK_TS then
				if BFStopOwnedAcquisition("BF_Toggle_Auto_Tushita_CDK") then
					return;
				end;
				if tostring(BFComm("CDKQuest", "OpenDoor")) ~= "opened" then
					task.wait(.7);
					BFComm("CDKQuest", "OpenDoor");
					task.wait(.3);
					BFComm("CDKQuest", "OpenDoor", true);
				else
					local finished, progressReady = BFCDKProgress("Finished");
					if not progressReady then
						return;
					end;
					if finished == nil then
						BFComm("CDKQuest", "StartTrial", "Good");
					elseif finished == false then
						if tonumber(BFCDKProgress("Good")) == -3 then
							QuestTushita_1 = true;
							QuestTushita_2 = false;
							QuestTushita_3 = false;
							for _, stop in ipairs({
								CFrame.new(-4602.5107421875, 16.446542739868, -2880.998046875),
								CFrame.new(4001.1853027344, 10.089399337769, -2654.86328125),
								CFrame.new(-9530.763671875, 7.2452087402344, -8375.5087890625),
							}) do
								repeat
									task.wait();
								until not _G.CDK_TS or BFMoveNear(stop, 3) or tonumber(BFCDKProgress("Good")) == 1;
								if not _G.CDK_TS then
									break;
								end;
								if f.Pos(stop, 10) then
									local npcs = workspace:FindFirstChild("NPCs");
									local dealer = npcs and npcs:FindFirstChild("Luxury Boat Dealer");
									if not dealer then
										break;
									end;
									task.wait(.7);
									BFComm("CDKQuest", "BoatQuest", dealer, "Check");
									task.wait(.5);
									BFComm("CDKQuest", "BoatQuest", dealer);
								end;
								task.wait(1);
							end;
						elseif tonumber(BFCDKProgress("Good")) == -4 then
							QuestTushita_1 = false;
							QuestTushita_2 = true;
							QuestTushita_3 = false;
							UI.DriveManagedFlag("CDKTushita", "AutoRaidCastle");
							repeat
								task.wait();
							until not _G.CDK_TS or tonumber(BFCDKProgress("Good")) == 2;
						elseif tonumber(BFCDKProgress("Good")) == -5 then
							QuestTushita_1 = false;
							QuestTushita_2 = false;
							QuestTushita_3 = true;
							local cakeQueen = GetConnectionEnemies("Cake Queen");
							local storedCakeQueen = Q:FindFirstChild("Cake Queen");
							local storedRoot = f.Alive(storedCakeQueen) and BFFirstPart(storedCakeQueen) or nil;
							if cakeQueen then
								repeat
									task.wait();
									f.Kill(cakeQueen, _G.CDK_TS);
								until not _G.CDK_TS or not cakeQueen.Parent or not f.Alive(cakeQueen) or tonumber(BFCDKProgress("Good")) == 3;
							elseif storedRoot then
								_tp(storedRoot.CFrame * CFrame.new(0, 30, 0));
							else
								local heavenlyDimension = BFMapNode("HeavenlyDimension");
								local heavenlySpawn = heavenlyDimension and heavenlyDimension:FindFirstChild("Spawn");
								local heavenlyExit = heavenlyDimension and heavenlyDimension:FindFirstChild("Exit");
								local character = game.Players.LocalPlayer.Character;
								local root = character and character:FindFirstChild("HumanoidRootPart");
								if heavenlyDimension and root and heavenlySpawn and heavenlySpawn:IsA("BasePart") and (root.Position - heavenlySpawn.Position).Magnitude <= 1000 then
									if heavenlyExit and heavenlyExit:IsA("BasePart") and #heavenlyExit:GetChildren() == 2 then
										repeat
											task.wait();
											character = game.Players.LocalPlayer.Character;
											root = character and character:FindFirstChild("HumanoidRootPart");
											if root then
												root.CFrame = heavenlyExit.CFrame;
											end;
									until not _G.CDK_TS or tonumber(BFCDKProgress("Good")) == 3;
									end;
									repeat
										task.wait();
										repeat
											task.wait();
											_tp(CFrame.new(-22529.6171875, 5275.7739257812, 3873.5712890625));
											for Y, d in pairs(heavenlyDimension:GetDescendants()) do
												if d:IsA("ProximityPrompt") and type(fireproximityprompt) == "function" then
													pcall(fireproximityprompt, d);
												end;
											end;
										until not _G.CDK_TS or f.Pos(CFrame.new(-22529.6171875, 5275.7739257812, 3873.5712890625), 5);
										task.wait(2);
										_G.DoneT1 = true;
									until not _G.CDK_TS or _G.DoneT1;
									repeat
										task.wait();
										repeat
											task.wait();
											_tp(CFrame.new(-22637.291015625, 5281.365234375, 3749.2885742188));
											for Y, d in pairs(heavenlyDimension:GetDescendants()) do
												if d:IsA("ProximityPrompt") and type(fireproximityprompt) == "function" then
													pcall(fireproximityprompt, d);
												end;
											end;
										until not _G.CDK_TS or f.Pos(CFrame.new(-22637.291015625, 5281.365234375, 3749.2885742188), 5);
										task.wait(2);
										_G.DoneT2 = true;
									until _G.DoneT2 or _G.CDK_TS == false;
									repeat
										task.wait();
										repeat
											task.wait();
											_tp(CFrame.new(-22791.14453125, 5277.1655273438, 3764.5700683594));
											for Y, d in pairs(heavenlyDimension:GetDescendants()) do
												if d:IsA("ProximityPrompt") and type(fireproximityprompt) == "function" then
													pcall(fireproximityprompt, d);
												end;
											end;
										until not _G.CDK_TS or f.Pos(CFrame.new(-22791.14453125, 5277.1655273438, 3764.5700683594), 5);
										task.wait(2);
										_G.DoneT3 = true;
									until _G.DoneT3 or _G.CDK_TS == false;
									local trialCenter = (CFrame.new(-22695.7012, 5270.93652, 3814.42847, .11794927, 3.32185834e-08, .99301964, -8.73070718e-08, 1, -2.30819008e-08, -0.99301964, -8.3975138e-08, .11794927)).Position;
									for Y, d in pairs(M:GetChildren()) do
										local root = d:FindFirstChild("HumanoidRootPart");
										local humanoid = d:FindFirstChild("Humanoid");
										if root and humanoid and humanoid.Health > 0 and (root.Position - trialCenter).Magnitude <= 300 then
												repeat
													task.wait();
													f.Kill(d, _G.CDK_TS);
												until not _G.CDK_TS or not d.Parent or not f.Alive(d);
										end;
									end;
								end;
							end;
						end;
					end;
				end;
			end;
		end);
		UI.ReleaseManagedFlag("CDKTushita", "AutoRaidCastle");
	end;
	UI.ReleaseManagedFlag("CDKTushita", "AutoRaidCastle");
end);
local SF = UI.Sections["True Triple Katana Sword"];
SF:AddButton({ Text = "Buy Legendary Sword", Func = function()
		BFComm("LegendarySwordDealer", "1");
		BFComm("LegendarySwordDealer", "2");
		BFComm("LegendarySwordDealer", "3");
	end });
SF:AddButton({ Text = "Buy True Triple Katana Sword", Func = function()
		BFComm("MysteriousMan", "2");
	end });
SF:AddToggle("BF_Toggle_Tween_to_Legendary_Sword_Dealer", {
	Text = "Tween to Legendary Sword Dealer",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		_G.Tp_LgS = Y;
	end,
});
task.spawn(function()
	while IdleWait(_G.Tp_LgS, T) do
		if _G.Tp_LgS then
			pcall(function()
				local root;
				if type(BFFindNpcLike) == "function" then
					root = select(2, BFFindNpcLike("Legendary Sword Dealer"));
				end;
				if root and root:IsA("BasePart") then
					_tp(root.CFrame);
				end;
			end);
		end;
	end;
end);
local oF = UI.Sections["Pole / God Enel"];
oF:AddToggle("BF_Toggle_Auto_Pole_V1", {
	Text = "Auto Pole V1",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		UI.SetManagedUserFlag("AutoPole", Y);
	end,
});
task.spawn(function()
	while IdleWait(_G.AutoPole, T) do
		if _G.AutoPole then
			pcall(function()
				if BFStopOwnedAcquisition("BF_Toggle_Auto_Pole_V1") then
					return;
				end;
				local Y = GetConnectionEnemies("Thunder God");
				if Y then
					repeat
						task.wait();
						f.Kill(Y, _G.AutoPole);
					until not _G.AutoPole or not Y.Parent or not f.Alive(Y);
				else
					_tp(CFrame.new(-7994.984375, 5761.025390625, -2088.6479492188));
				end;
			end);
		end;
	end;
end);
UI.PoleV2Status = "idle";
UI.PoleV2StatusLabel = nil;
UI.PoleV2NextChipAt = 0;
UI.PoleV2NextPurchaseAt = 0;
UI.PoleV2NextTravelAt = 0;
function UI.SetPoleV2Status(status)
	status = tostring(status or "working");
	if status ~= UI.PoleV2Status then
		UI.PoleV2Status = status;
		if UI.PoleV2StatusLabel then
			UI.PoleV2StatusLabel:SetText("Pole V2: " .. status:gsub("%-", " "));
		end;
	end;
end;
function UI.PoleV2Travel(command, status, now)
	UI.ReleaseManagedOwner("PoleV2");
	if now >= UI.PoleV2NextTravelAt then
		UI.PoleV2NextTravelAt = now + 3;
		BFComm(command);
	end;
	return status;
end;
oF:AddToggle("BF_Toggle_Auto_Pole_V2_Beta", {
	Text = "Auto Pole V2",
	Tooltip = "Acquire and master Pole V1, awaken Rumble through raids, then unlock Pole V2",
	Default = false,
	Callback = function(Y)
		_G.AutoPoleV2 = Y;
		if Y then
			UI.PoleV2NextChipAt = 0;
			UI.PoleV2NextPurchaseAt = 0;
			UI.PoleV2NextTravelAt = 0;
		elseif UI.PoleV2Status ~= "complete" then
			UI.ReleaseManagedOwner("PoleV2");
			UI.SetPoleV2Status("idle");
		end;
	end,
});
UI.PoleV2StatusLabel = oF:AddLabel({ DoesWrap = true, Text = "Pole V2: idle" });
function UI.PoleV2Step(active)
	if not active then
		UI.ReleaseManagedOwner("PoleV2");
		return "idle";
	end;
	if BFHasItemNamed("Pole (2nd Form)") then
		UI.ReleaseManagedOwner("PoleV2");
		return "complete";
	end;
	local now = os.clock();
	local poleOne = BFFindLocalItemLike("Pole (1st Form)");
	if not poleOne then
		UI.ReleaseManagedOwner("PoleV2");
		if not World1 then
			return UI.PoleV2Travel("TravelMain", "traveling-to-first-sea", now);
		end;
		UI.DriveManagedFlag("PoleV2", "AutoPole");
		return "acquiring-pole-v1";
	end;
	local mastery = BFItemMasteryLike("Pole (1st Form)");
	if mastery < 180 then
		UI.ReleaseManagedOwner("PoleV2");
		UI.DriveManagedValue("PoleV2", "BFCombatWeapon", poleOne.Name);
		UI.DriveManagedFlag("PoleV2", "Level");
		return "mastering-pole-v1";
	end;
	local rumble = BFFindLocalItemLike("Rumble");
	if not rumble then
		UI.ReleaseManagedOwner("PoleV2");
		return "rumble-fruit-required";
	end;
	local moves = rumble:FindFirstChild("AwakenedMoves");
	local fullyAwakened = moves
		and moves:FindFirstChild("Z")
		and moves:FindFirstChild("X")
		and moves:FindFirstChild("C")
		and moves:FindFirstChild("V")
		and moves:FindFirstChild("F");
	if not fullyAwakened then
		UI.ReleaseManagedOwner("PoleV2");
		if World1 then
			return UI.PoleV2Travel("TravelDressrosa", "traveling-to-second-sea", now);
		end;
		UI.DriveManagedValue("PoleV2", "SelectChip", "Rumble");
		UI.DriveManagedFlag("PoleV2", "Auto_StartRaid");
		UI.DriveManagedFlag("PoleV2", "Raiding");
		UI.DriveManagedFlag("PoleV2", "Auto_Awakener");
		if not GetBP("Special Microchip") and now >= UI.PoleV2NextChipAt then
			UI.PoleV2NextChipAt = now + 3;
			BFComm("RaidsNpc", "Select", "Rumble");
		end;
		return GuiShown("TopHUDList", "RaidTimer") and "completing-rumble-raid" or "preparing-rumble-raid";
	end;
	UI.ReleaseManagedOwner("PoleV2");
	local fragments = tonumber(BFDataValue("Fragments")) or 0;
	if fragments < 5000 then
		return "5000-fragments-required";
	end;
	if now >= UI.PoleV2NextPurchaseAt then
		UI.PoleV2NextPurchaseAt = now + 2;
		BFComm("Thunder God", "Talk");
		BFComm("Thunder God", "Sure");
	end;
	return "unlocking-pole-v2";
end;
task.spawn(function()
	while IdleWait(_G.AutoPoleV2, .25) do
		if _G.AutoPoleV2 then
			local ok, status = pcall(UI.PoleV2Step, _G.AutoPoleV2);
			status = ok and tostring(status or "working") or "error";
			if not ok then
				UI.ReleaseManagedOwner("PoleV2");
			end;
			UI.SetPoleV2Status(status);
			if status == "complete" then
				UI.DisableToggle("BF_Toggle_Auto_Pole_V2_Beta");
			end;
		end;
	end;
	UI.ReleaseManagedOwner("PoleV2");
end);
local ZF = UI.Sections["Items Law/Order Sword"];
ZF:AddToggle("BF_Toggle_Auto_Law_Sword", {
	Text = "Auto Law Sword",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		_G.AutoLawKak = Y;
	end,
});
task.spawn(function()
	while IdleWait(_G.AutoLawKak, T) do
		if _G.AutoLawKak then
			pcall(function()
				if BFStopOwnedAcquisition("BF_Toggle_Auto_Law_Sword") then
					return;
				end;
				local Y = GetConnectionEnemies("Order");
				if Y then
					repeat
						task.wait();
						f.Kill(Y, _G.AutoLawKak);
					until _G.AutoLawKak == false or not Y.Parent or not f.Alive(Y);
				else
					_tp(CFrame.new(-6217.2021484375, 28.047645568848, -5053.1357421875));
				end;
			end);
		end;
	end;
end);
ZF:AddButton({ Text = "Buy Microchip Law", Func = function()
		BFComm("BlackbeardReward", "Microchip", "2");
	end });
ZF:AddButton({ Text = "Start Law Raids", Func = function()
		local detector = BFMapNode("CircleIsland", "RaidSummon", "Button", "Main", "ClickDetector");
		if detector and type(fireclickdetector) == "function" then
			pcall(fireclickdetector, detector);
		end;
	end });
local TF = UI.Sections["East Blue Misc"];
TF:AddToggle("BF_Toggle_Auto_Saw_Sword", {
	Text = "Auto Saw Sword",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		_G.AutoSaw = Y;
	end,
});
task.spawn(function()
	while IdleWait(_G.AutoSaw, .2) do
		pcall(function()
			if _G.AutoSaw then
				if BFStopOwnedAcquisition("BF_Toggle_Auto_Saw_Sword") then
					return;
				end;
				local Y = GetConnectionEnemies("The Saw");
				if Y then
					repeat
						task.wait();
						f.Kill(Y, _G.AutoSaw);
					until _G.AutoSaw == false or not Y.Parent or not f.Alive(Y);
				else
					_tp(CFrame.new(-784.89715576172, 72.427383422852, 1603.5822753906));
				end;
			end;
		end);
	end;
end);
TF:AddToggle("BF_Toggle_Auto_Saber_Sword", {
	Text = "Auto Saber Sword",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		_G.AutoSaber = Y;
	end,
});
task.spawn(function()
	while IdleWait(_G.AutoSaber, .2) do
		pcall(function()
			if _G.AutoSaber then
				if BFStopOwnedAcquisition("BF_Toggle_Auto_Saber_Sword") then
					return;
				end;
				if (tonumber(BFDataValue("Level")) or 0) < 200 or GetIn("Saber") then
					return;
				end;
				local finalPart = BFMapNode("Jungle", "Final", "Part");
				local plateDoor = BFMapNode("Jungle", "QuestPlates", "Door");
				if not finalPart or not plateDoor then
					return;
				end;
				if finalPart.Transparency == 0 then
					if plateDoor.Transparency == 0 then
						local plateStart = CFrame.new(-1612.55884, 36.9774132, 148.719543, .37091279, 3.0717151e-09, -0.928667724, 3.97099491e-08, 1, 1.91679348e-08, .928667724, -4.39869794e-08, .37091279);
						if BFMoveNear(plateStart, 100) then
							for index = 1, 5 do
								local button = BFMapNode("Jungle", "QuestPlates", "Plate" .. index, "Button");
								if not _G.AutoSaber or not button or not button:IsA("BasePart") then
									break;
								end;
								_tp(button.CFrame);
								task.wait(.5);
							end;
						end;
					else
						local burnPart = BFMapNode("Desert", "Burn", "Part");
						local burnFire = BFMapNode("Desert", "Burn", "Fire");
						if not burnPart then
							return;
						end;
						if burnPart.Transparency == 0 then
							if localItem("Torch") then
								EquipWeapon("Torch");
								local torch = d.Character and d.Character:FindFirstChild("Torch");
								local handle = torch and torch:FindFirstChild("Handle");
								if handle and burnFire and type(firetouchinterest) == "function" then
									pcall(firetouchinterest, handle, burnFire, 0);
									pcall(firetouchinterest, handle, burnFire, 1);
								end;
								_tp(CFrame.new(1114.61475, 5.04679728, 4350.22803, -0.648466587, -1.28799094e-09, .761243105, -5.70652914e-10, 1, 1.20584542e-09, -0.761243105, 3.47544882e-10, -0.648466587));
							else
								_tp(CFrame.new(-1610.00757, 11.5049858, 164.001587, .984807551, -0.167722285, -0.0449818149, .17364943, .951244235, .254912198, 3.42372805e-05, -0.258850515, .965917408));
							end;
						else
							if BFComm("ProQuestProgress", "SickMan") ~= 0 then
								BFComm("ProQuestProgress", "GetCup");
								task.wait(.5);
								EquipWeapon("Cup");
								task.wait(.5);
								BFComm("ProQuestProgress", "FillCup", d.Character.Cup);
								task.wait(T);
								BFComm("ProQuestProgress", "SickMan");
							else
								if BFComm("ProQuestProgress", "RichSon") == nil then
									BFComm("ProQuestProgress", "RichSon");
								elseif BFComm("ProQuestProgress", "RichSon") == 0 then
									if workspace.Enemies:FindFirstChild("Mob Leader") or Q:FindFirstChild("Mob Leader") then
										_tp(CFrame.new(-2967.59521, -4.91089821, 5328.70703, .342208564, -0.0227849055, .939347804, .0251603816, .999569714, .0150796166, -0.939287126, .0184739735, .342634559));
										for Y, d in pairs(workspace.Enemies:GetChildren()) do
											if d.Name == "Mob Leader" and f.Alive(d) then
												repeat
													task.wait();
													f.Kill(d, _G.AutoSaber);
										until _G.AutoSaber == false or not d.Parent or not f.Alive(d);
											end;
										end;
									end;
								elseif BFComm("ProQuestProgress", "RichSon") == 1 then
									BFComm("ProQuestProgress", "RichSon");
									EquipWeapon("Relic");
									_tp(CFrame.new(-1404.91504, 29.9773273, 3.80598116, .876514494, 5.66906877e-09, .481375456, 2.53851997e-08, 1, -5.79995607e-08, -0.481375456, 6.30572643e-08, .876514494));
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
								until _G.AutoSaber == false or not d.Parent or not f.Alive(d);
								if not f.Alive(d) then
									BFComm("ProQuestProgress", "PlaceRelic");
								end;
							end;
						end;
					else
						_tp(CFrame.new(-1401.85046, 29.9773273, 8.81916237, .85820812, 8.76083845e-08, .513301849, -8.55007443e-08, 1, -2.77243419e-08, -0.513301849, -2.00944328e-08, .85820812));
					end;
				end;
			end;
		end);
	end;
end);
TF:AddToggle("BF_Toggle_Auto_Cybrog", {
	Text = "Auto Cybrog",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		_G.AutoColShad = Y;
	end,
});
task.spawn(function()
	while IdleWait(_G.AutoColShad, .2) do
		if _G.AutoColShad then
			pcall(function()
				if BFStopOwnedAcquisition("BF_Toggle_Auto_Cybrog") then
					return;
				end;
				local Y = GetConnectionEnemies("Cyborg");
				if Y then
					repeat
						task.wait();
						f.Kill(Y, _G.AutoColShad);
					until _G.AutoColShad == false or not Y.Parent or not f.Alive(Y);
				else
					_tp(CFrame.new(6094.0249023438, 73.770050048828, 3825.7348632813));
				end;
			end);
		end;
	end;
end);
UI.UsoapStatus = "idle";
UI.UsoapStatusLabel = nil;
function UI.SetUsoapStatus(status)
	status = tostring(status or "working");
	if status ~= UI.UsoapStatus then
		UI.UsoapStatus = status;
		if UI.UsoapStatusLabel then
			UI.UsoapStatusLabel:SetText("Usopp's Hat: " .. status:gsub("%-", " "));
		end;
	end;
end;
TF:AddToggle("BF_Toggle_Auto_Usoap_s_Hat", {
	Text = "Auto Usoap\'s Hat",
	Tooltip = "Attack the nearest live player within range until Usopp's Hat is owned",
	Default = false,
	Callback = function(Y)
		_G.AutoGetUsoap = Y;
		if not Y and UI.UsoapStatus ~= "complete" then
			UI.SetUsoapStatus("idle");
		end;
	end,
});
UI.UsoapStatusLabel = TF:AddLabel({ DoesWrap = true, Text = "Usopp's Hat: " .. UI.UsoapStatus:gsub("%-", " ") });
task.spawn(function()
	while IdleWait(_G.AutoGetUsoap, .1) do
		local ok = pcall(function()
			if _G.AutoGetUsoap then
				if BFStopOwnedAcquisition("BF_Toggle_Auto_Usoap_s_Hat") then
					UI.SetUsoapStatus("complete");
					return;
				end;
				local characters = workspace:FindFirstChild("Characters");
				local ownRoot = BFCharacterPart();
				if not characters or not ownRoot then
					UI.SetUsoapStatus("waiting-for-characters");
					return;
				end;
				local target;
				local nearest = 230;
				for _, character in ipairs(characters:GetChildren()) do
					local targetRoot = character:FindFirstChild("HumanoidRootPart");
					if character.Name ~= d.Name and targetRoot and f.Alive(character) then
						local distance = (ownRoot.Position - targetRoot.Position).Magnitude;
						if distance <= nearest then
							nearest = distance;
							target = character;
						end;
					end;
				end;
				if not target then
					UI.SetUsoapStatus("waiting-for-player");
					return;
				end;
				UI.SetUsoapStatus("attacking");
				repeat
					task.wait(.1);
					local targetRoot = target:FindFirstChild("HumanoidRootPart");
					if not targetRoot then
						break;
					end;
					EquipWeapon(EnsureWeapon());
					MousePos = targetRoot.Position;
					_tp(targetRoot.CFrame * CFrame.new(0, 0, 15));
					BFTouchAttack();
					ExtendSimulationRadius();
				until not _G.AutoGetUsoap or not target.Parent or not f.Alive(target);
			end;
		end);
		if not ok then
			UI.SetUsoapStatus("error");
		end;
	end;
end);
TF:AddToggle("BF_Toggle_Auto_Bisento_V2", {
	Text = "Auto Bisento V2",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		_G.Greybeard = Y;
	end,
});
task.spawn(function()
	while IdleWait(_G.Greybeard, T) do
		if _G.Greybeard then
			pcall(function()
				if not GetWP("Bisento") then
					BFComm("BuyItem", "Bisento");
				elseif GetWP("Bisento") then
					BFComm("LoadItem", "Bisento");
					local Y = GetConnectionEnemies("Greybeard");
					if Y then
						repeat
							task.wait();
							f.Kill(Y, _G.Greybeard);
						until _G.Greybeard == false or not Y.Parent or Y.Humanoid.Health <= 0;
					else
						_tp(CFrame.new(-5023.3833007812, 28.652032852173, 4332.3818359375));
					end;
				end;
			end);
		end;
	end;
end);
TF:AddToggle("BF_Toggle_Auto_Warden_Sword", {
	Text = "Auto Warden Sword",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		_G.WardenBoss = Y;
	end,
});
task.spawn(function()
	while IdleWait(_G.WardenBoss, .1) do
		if _G.WardenBoss then
			pcall(function()
				if BFStopOwnedAcquisition("BF_Toggle_Auto_Warden_Sword") then
					return;
				end;
				local Y = GetConnectionEnemies("Chief Warden");
				if Y then
					repeat
						task.wait();
						f.Kill(Y, _G.WardenBoss);
					until _G.WardenBoss == false or not Y.Parent or not f.Alive(Y);
				else
					_tp(CFrame.new(5206.92578, .997753382, 814.976746, .342041343, -0.00062915677, .939684749, .00191645394, .999998152, -2.80422337e-05, -0.939682961, .00181045406, .342041939));
				end;
			end);
		end;
	end;
end);
TF:AddToggle("BF_Toggle_Auto_Marine_Coat", {
	Text = "Auto Marine Coat",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		_G.MarinesCoat = Y;
	end,
});
task.spawn(function()
	while IdleWait(_G.MarinesCoat, .1) do
		if _G.MarinesCoat then
			pcall(function()
				if BFStopOwnedAcquisition("BF_Toggle_Auto_Marine_Coat") then
					return;
				end;
				local Y = GetConnectionEnemies("Vice Admiral");
				if Y then
					repeat
						task.wait();
						f.Kill(Y, _G.MarinesCoat);
					until _G.MarinesCoat == false or not Y.Parent or not f.Alive(Y);
				else
					_tp(CFrame.new(-5006.5454101563, 88.032081604004, 4353.162109375));
				end;
			end);
		end;
	end;
end);
TF:AddToggle("BF_Toggle_Auto_Swan_Coat", {
	Text = "Auto Swan Coat",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		_G.SwanCoat = Y;
	end,
});
task.spawn(function()
	while IdleWait(_G.SwanCoat, .1) do
		if _G.SwanCoat then
			pcall(function()
				if BFStopOwnedAcquisition("BF_Toggle_Auto_Swan_Coat") then
					return;
				end;
				local Y = GetConnectionEnemies("Swan");
				if Y then
					repeat
						task.wait();
						f.Kill(Y, _G.SwanCoat);
					until _G.SwanCoat == false or not Y.Parent or not f.Alive(Y);
				else
					_tp(CFrame.new(5325.09619, 7.03906584, 719.570679, -0.309060812, 0, .951042235, 0, 1, 0, -0.951042235, 0, -0.309060812));
				end;
			end);
		end;
	end;
end);
local kF = UI.Sections["Rengoku Sword"];
kF:AddToggle("BF_Toggle_Auto_Rengoku_Sword", {
	Text = "Auto Rengoku Sword",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		_G.IceBossRen = Y;
	end,
});
task.spawn(function()
	while IdleWait(_G.IceBossRen, .1) do
		pcall(function()
			if _G.IceBossRen then
				if BFStopOwnedAcquisition("BF_Toggle_Auto_Rengoku_Sword") then
					return;
				end;
				local Y = GetConnectionEnemies("Awakened Ice Admiral");
				if Y then
					repeat
						task.wait();
						f.Kill(Y, _G.IceBossRen);
					until _G.IceBossRen == false or not Y.Parent or not f.Alive(Y);
				else
					_tp(CFrame.new(5668.9780273438, 28.519989013672, -6483.3520507813));
				end;
			end;
		end);
	end;
end);
kF:AddToggle("BF_Toggle_Auto_Key_Rengoku", {
	Text = "Auto Key Rengoku",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		_G.KeysRen = Y;
	end,
});
task.spawn(function()
	while IdleWait(_G.KeysRen, .1) do
		pcall(function()
			if _G.KeysRen then
				if localItem(G[3]) then
					EquipWeapon(G[3]);
					task.wait(.1);
					_tp(CFrame.new(6571.1201171875, 299.23028564453, -6967.841796875));
				else
					local Y = GetConnectionEnemies(G);
					if Y then
						repeat
							task.wait();
							f.Kill(Y, _G.KeysRen);
						until localItem(G[3]) or _G.KeysRen == false or not Y.Parent or not f.Alive(Y);
					else
						_tp(CFrame.new(5439.716796875, 84.420944213867, -6715.1635742188));
					end;
				end;
			end;
		end);
	end;
end);
kF:AddToggle("BF_Toggle_Auto_Dragon_Trident", {
	Text = "Auto Dragon Trident",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		_G.AutoTridentW2 = Y;
	end,
});
task.spawn(function()
	while IdleWait(_G.AutoTridentW2, .1) do
		pcall(function()
			if _G.AutoTridentW2 then
				if BFStopOwnedAcquisition("BF_Toggle_Auto_Dragon_Trident") then
					return;
				end;
				local Y = GetConnectionEnemies("Tide Keeper");
				if Y then
					repeat
						task.wait();
						f.Kill(Y, _G.AutoTridentW2);
					until _G.AutoTridentW2 == false or not Y.Parent or not f.Alive(Y);
				else
					_tp(CFrame.new(-3795.6423339844, 105.88877105713, -11421.307617188));
				end;
			end;
		end);
	end;
end);
kF:AddToggle("BF_Toggle_Auto_Long_Sword", {
	Text = "Auto Long Sword",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		_G.LongsWord = Y;
	end,
});
task.spawn(function()
	while IdleWait(_G.LongsWord, .1) do
		pcall(function()
			if _G.LongsWord then
				if BFStopOwnedAcquisition("BF_Toggle_Auto_Long_Sword") then
					return;
				end;
				local Y = GetConnectionEnemies("Diamond");
				if Y then
					repeat
						task.wait();
						f.Kill(Y, _G.LongsWord);
					until _G.LongsWord == false or not Y.Parent or not f.Alive(Y);
				else
					_tp(CFrame.new(-1576.7166748047, 198.59265136719, 13.724286079407));
				end;
			end;
		end);
	end;
end);
kF:AddToggle("BF_Toggle_Auto_Black_Spikey", {
	Text = "Auto Black Spikey",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		_G.BlackSpikey = Y;
	end,
});
task.spawn(function()
	while IdleWait(_G.BlackSpikey, .1) do
		if _G.BlackSpikey then
			pcall(function()
				local Y = GetConnectionEnemies("Jeremy");
				if Y then
					repeat
						task.wait();
						f.Kill(Y, _G.BlackSpikey);
					until _G.BlackSpikey == false or not Y.Parent or Y.Humanoid.Health <= 0;
				else
					_tp(CFrame.new(2006.9261474609, 448.95666503906, 853.98284912109));
				end;
			end);
		end;
	end;
end);

_G.DarkBladev3 = false;
UI.DarkBladeV3Status = "idle";
UI.DarkBladeV3StatusLabel = nil;
UI.DarkBladeV3NextLoadAt = 0;
UI.DarkBladeV3NextClickAt = 0;
UI.DarkBladeV3Altar = CFrame.new(3677.08203125, 62.751937866211, -3144.8332519531);
UI.DarkBladeV3Button = CFrame.new(-5719.3637695312, 48.505905151367, -782.97595214844);
function UI.SetDarkBladeV3Status(status)
	status = tostring(status or "working");
	if status ~= UI.DarkBladeV3Status then
		UI.DarkBladeV3Status = status;
		if UI.DarkBladeV3StatusLabel then
			UI.DarkBladeV3StatusLabel:SetText("Dark Blade V3: " .. status:gsub("%-", " "));
		end;
	end;
end;
kF:AddToggle("BF_Toggle_Auto_Dark_Blade_V3", {
	Text = "Auto Dark Blade V3",
	Tooltip = "Requires Dark Blade in the Second Sea and follows the imported Fist of Darkness route",
	Default = false,
	Callback = function(Y)
		_G.DarkBladev3 = Y;
		UI.DarkBladeV3NextLoadAt = 0;
		UI.DarkBladeV3NextClickAt = 0;
		if not Y then
			UI.ReleaseManagedOwner("DarkBladeV3");
			UI.SetDarkBladeV3Status("idle");
		end;
	end,
});
UI.DarkBladeV3StatusLabel = kF:AddLabel({ DoesWrap = true, Text = "Dark Blade V3: idle" });
function UI.DarkBladeV3Step(active)
	if not active then
		UI.ReleaseManagedOwner("DarkBladeV3");
		return "idle";
	end;
	if not World2 then
		UI.ReleaseManagedOwner("DarkBladeV3");
		return "second-sea-required";
	end;
	local darkBlade = GetBP("Dark Blade");
	if not darkBlade and not BFHasItemNamed("Dark Blade") then
		UI.ReleaseManagedOwner("DarkBladeV3");
		return "dark-blade-required";
	end;
	local now = os.clock();
	if not darkBlade and now >= UI.DarkBladeV3NextLoadAt then
		UI.DarkBladeV3NextLoadAt = now + 2;
		BFComm("LoadItem", "Dark Blade");
	end;
	local fist = GetBP("Fist of Darkness");
	if not fist then
		UI.DriveManagedFlag("DarkBladeV3", "AutoFarmChest");
		return "farming-fist-of-darkness";
	end;
	UI.ReleaseManagedOwner("DarkBladeV3");
	local darkbeard = M:FindFirstChild("Darkbeard");
	if not f.Alive(darkbeard) then
		if not BFMoveNear(UI.DarkBladeV3Altar, 8) then
			return "moving-to-dark-arena";
		end;
		return "waiting-for-darkbeard";
	end;
	if not BFMoveNear(UI.DarkBladeV3Button, 8) then
		return "moving-to-grave-button";
	end;
	local detector = BFMapNode("GraveIsland", "Mountain", "Rocks", "Button", "ClickDetector");
	if not detector then
		return "waiting-for-grave-button";
	end;
	if type(fireclickdetector) ~= "function" then
		return "click-detector-unsupported";
	end;
	if now >= UI.DarkBladeV3NextClickAt then
		UI.DarkBladeV3NextClickAt = now + 2;
		fireclickdetector(detector);
	end;
	return "activating-grave-button";
end;
task.spawn(function()
	while IdleWait(_G.DarkBladev3, .25) do
		local ok, status = pcall(UI.DarkBladeV3Step, _G.DarkBladev3);
		if not ok then
			UI.ReleaseManagedOwner("DarkBladeV3");
			status = "error";
		end;
		UI.SetDarkBladeV3Status(status);
	end;
	UI.ReleaseManagedOwner("DarkBladeV3");
end);
kF:AddToggle("BF_Toggle_Auto_Midnight_Blade", {
	Text = "Auto Midnight Blade",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		_G.AutoEcBoss = Y;
	end,
});
BFMidnightBladeNextPurchase = 0;
task.spawn(function()
	while IdleWait(_G.AutoEcBoss, T) do
		pcall(function()
			if _G.AutoEcBoss then
				if BFStopOwnedAcquisition("BF_Toggle_Auto_Midnight_Blade") then
					return;
				end;
				if GetM("Ectoplasm") >= 99 then
					local now = os.clock();
					if now >= BFMidnightBladeNextPurchase then
						BFMidnightBladeNextPurchase = now + 2;
						BFComm("Ectoplasm", "Buy", 3);
					end;
				elseif GetM("Ectoplasm") <= 99 then
					local Y = GetConnectionEnemies("Cursed Captain");
					if Y then
						repeat
							task.wait();
							f.Kill(Y, _G.AutoEcBoss);
						until not _G.AutoEcBoss or not Y.Parent or not f.Alive(Y);
					else
						BFComm("requestEntrance", Vector3.new(923.21252441406, 126.9760055542, 32852.83203125));
						task.wait(.5);
						_tp(CFrame.new(916.928589, 181.092773, 33422));
					end;
				end;
			end;
		end);
	end;
end);
_G.Auto_Def_DarkCoat = false;
UI.DarkbeardStatus = "idle";
UI.DarkbeardStatusLabel = nil;
function UI.SetDarkbeardStatus(status)
	status = tostring(status or "working");
	if status ~= UI.DarkbeardStatus then
		UI.DarkbeardStatus = status;
		if UI.DarkbeardStatusLabel then
			UI.DarkbeardStatusLabel:SetText("Darkbeard: " .. status:gsub("%-", " "));
		end;
	end;
end;
kF:AddToggle("BF_Toggle_Auto_Darkbeard", {
	Text = "Auto Darkbeard",
	Tooltip = "Farm a Fist of Darkness, summon Darkbeard, and fight him in the Second Sea",
	Default = false,
	Callback = function(Y)
		_G.Auto_Def_DarkCoat = Y;
		if not Y then
			UI.ReleaseManagedOwner("Darkbeard");
			UI.SetDarkbeardStatus("idle");
		end;
	end,
});
UI.DarkbeardStatusLabel = kF:AddLabel({ DoesWrap = true, Text = "Darkbeard: idle" });
function UI.DarkbeardStep(active)
	if not active then
		UI.ReleaseManagedOwner("Darkbeard");
		return "idle";
	end;
	if not World2 then
		UI.ReleaseManagedOwner("Darkbeard");
		return "second-sea-required";
	end;
	local fist = GetBP("Fist of Darkness");
	local liveDarkbeard = M:FindFirstChild("Darkbeard");
	if fist and not f.Alive(liveDarkbeard) then
		UI.ReleaseManagedOwner("Darkbeard");
		if not BFMoveNear(UI.DarkBladeV3Altar, 8) then
			return "moving-to-dark-arena";
		end;
		return "waiting-for-darkbeard";
	end;
	local target = GetConnectionEnemies("Darkbeard");
	if target and f.Alive(target) then
		UI.ReleaseManagedOwner("Darkbeard");
		f.Kill(target, active);
		return "fighting-darkbeard";
	end;
	UI.DriveManagedFlag("Darkbeard", "AutoFarmChest");
	return "farming-fist-of-darkness";
end;
task.spawn(function()
	while IdleWait(_G.Auto_Def_DarkCoat, .25) do
		local ok, status = pcall(UI.DarkbeardStep, _G.Auto_Def_DarkCoat);
		if not ok then
			UI.ReleaseManagedOwner("Darkbeard");
			status = "error";
		end;
		UI.SetDarkbeardStatus(status);
	end;
	UI.ReleaseManagedOwner("Darkbeard");
end);
kF:AddToggle("BF_Toggle_Auto_Unlocked_DonSwan", {
	Text = "Auto Unlocked DonSwan",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		_G.Auto_DonAcces = Y;
	end,
});
task.spawn(function()
	while IdleWait(_G.Auto_DonAcces, .1) do
		if _G.Auto_DonAcces then
			pcall(function()
				local unlockables = BFComm("GetUnlockables");
				if type(unlockables) ~= "table" then
					return;
				end;
				if unlockables.FlamingoAccess ~= nil then
					UI.DisableToggle("BF_Toggle_Auto_Unlocked_DonSwan");
					return;
				end;
				local data = d:FindFirstChild("Data");
				local level = data and data:FindFirstChild("Level");
				if not level or level.Value < 1500 then
					return;
				end;
				local prices = {};
				local fruits = BFComm("GetFruits");
				if type(fruits) == "table" then
					for _, fruit in pairs(fruits) do
						if type(fruit) == "table" and fruit.Name then
							prices[fruit.Name] = tonumber(fruit.Price) or 0;
						end;
					end;
				end;
				local inventory = BFStoredFruits();
				if type(inventory) ~= "table" then
					return;
				end;
				local selectedFruit;
				for _, fruit in pairs(inventory) do
					local name = type(fruit) == "table" and fruit.Name;
					if name and (prices[name] or 0) >= 1000000 then
						selectedFruit = name;
						break;
					end;
				end;
				if not selectedFruit then
					return;
				end;
				local loadedFruit = BFFindFruitTool(selectedFruit);
				if not loadedFruit then
					BFComm("LoadFruit", selectedFruit);
					return;
				end;
				BFComm("TalkTrevor", "1");
				BFComm("TalkTrevor", "2");
				BFComm("TalkTrevor", "3");
				task.wait(.5);
				unlockables = BFComm("GetUnlockables");
				if type(unlockables) == "table" and unlockables.FlamingoAccess ~= nil then
					UI.DisableToggle("BF_Toggle_Auto_Unlocked_DonSwan");
				end;
			end);
		end;
	end;
end);
kF:AddToggle("BF_Toggle_Auto_Swan_Glasses", {
	Text = "Auto Swan Glasses",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		_G.Auto_SwanGG = Y;
	end,
});
task.spawn(function()
	while IdleWait(_G.Auto_SwanGG, .2) do
		if _G.Auto_SwanGG then
			pcall(function()
				if BFStopOwnedAcquisition("BF_Toggle_Auto_Swan_Glasses") then
					return;
				end;
				local Y = GetConnectionEnemies("Don Swan");
				if Y then
					repeat
						task.wait();
						f.Kill(Y, _G.Auto_SwanGG);
					until _G.Auto_SwanGG == false or not Y.Parent or not f.Alive(Y);
				else
					_tp(CFrame.new(2286.2004394531, 15.177839279175, 863.8388671875));
				end;
			end);
		end;
	end;
end);
local LF = UI.Sections["Canvander + Twin Hooks + Big Mom"];
LF:AddToggle("BF_Toggle_Auto_Bigmom", {
	Text = "Auto Big Mom",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		_G.AutoBigmom = Y;
	end,
});
task.spawn(function()
	while IdleWait(_G.AutoBigmom, T) do
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
LF:AddToggle("BF_Toggle_Auto_Canvendish_Sword", {
	Text = "Auto Canvander Sword",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		_G.Auto_Cavender = Y;
	end,
});
task.spawn(function()
	while IdleWait(_G.Auto_Cavender, T) do
		pcall(function()
			if _G.Auto_Cavender then
				if BFStopOwnedAcquisition("BF_Toggle_Auto_Canvendish_Sword") then
					return;
				end;
				local Y = GetConnectionEnemies("Beautiful Pirate");
				if Y then
					repeat
						task.wait();
						f.Kill(Y, _G.Auto_Cavender);
					until not _G.Auto_Cavender or not Y.Parent or not f.Alive(Y);
				else
					_tp(CFrame.new(5283.6094, 22.5622, -110.7829));
				end;
			end;
		end);
	end;
end);
LF:AddToggle("BF_Toggle_Auto_Twin_Hooks", {
	Text = "Auto Twin Hooks",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		_G.TwinHook = Y;
	end,
});
task.spawn(function()
	while IdleWait(_G.TwinHook, T) do
		pcall(function()
			if _G.TwinHook then
				if BFStopOwnedAcquisition("BF_Toggle_Auto_Twin_Hooks") then
					return;
				end;
				local Y = GetConnectionEnemies("Captain Elephant");
				if Y then
					repeat
						task.wait();
						f.Kill(Y, _G.TwinHook);
					until not _G.TwinHook or not Y.Parent or not f.Alive(Y);
				else
					BFComm("requestEntrance", Vector3.new(-12471.1699, 374.9402, -7551.6777));
					task.wait(.2);
					_tp(CFrame.new(-13376.7578, 433.2869, -8071.3926));
				end;
			end;
		end);
	end;
end);
LF:AddToggle("BF_Toggle_Auto_Serpent_Bow", {
	Text = "Auto Serpent Bow",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		_G.AutoSerpentBow = Y;
	end,
});
task.spawn(function()
	while IdleWait(_G.AutoSerpentBow, T) do
		if _G.AutoSerpentBow then
			pcall(function()
				if BFStopOwnedAcquisition("BF_Toggle_Auto_Serpent_Bow") then
					return;
				end;
				local Y = GetConnectionEnemies("Hydra Leader");
				if Y then
					repeat
						task.wait();
						f.Kill(Y, _G.AutoSerpentBow);
					until not _G.AutoSerpentBow or not Y.Parent or not f.Alive(Y);
				else
					_tp(CFrame.new(5821.898, 1019.0951, -73.7192));
				end;
			end);
		end;
	end;
end);
LF:AddToggle("BF_Toggle_Auto_Lei_Accessory", {
	Text = "Auto Lei Accessory",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		_G.AutoKilo = Y;
	end,
});
task.spawn(function()
	while IdleWait(_G.AutoKilo, .2) do
		if _G.AutoKilo then
			pcall(function()
				if BFStopOwnedAcquisition("BF_Toggle_Auto_Lei_Accessory") then
					return;
				end;
				local Y = GetConnectionEnemies("Kilo Admiral");
				if Y then
					repeat
						task.wait();
						f.Kill(Y, _G.AutoKilo);
					until not _G.AutoKilo or not Y.Parent or not f.Alive(Y);
				else
					_tp(CFrame.new(2764.2234, 432.4615, -7144.458));
				end;
			end);
		end;
	end;
end);
local PF = UI.Sections["Sea Event / Setting Sail"];
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
local qF = PF:AddLabel({ DoesWrap = true, Text = " Spy Status " });
task.spawn(function()
	while UI.LabelWait(5) do
		pcall(function()
			local Y = string.match(BFComm("InfoLeviathan", "1"), "%d+");
			if Y then
				qF:SetText(" Spy Leviathan  : " .. tostring(Y));
				if tostring(Y) == 5 then
					qF:SetText(" Spy Leviathan : Already Done!!");
				end;
			end;
		end);
	end;
end);
PF:AddButton({ Text = "Buy Fragments with Spy", Func = function()
		BFComm("InfoLeviathan", "2");
	end });
local VF = PF:AddLabel({ DoesWrap = true, Text = " Frozen Dimension Status " });
task.spawn(function()
	while UI.LabelWait(2) do
		pcall(function()
			if BFWorldLocation("Frozen Dimension") then
				VF:SetText(" Frozen Dimension : True");
			else
				VF:SetText(" Frozen Dimension : False");
			end;
		end);
	end;
end);
PF:AddToggle("BF_Toggle_Auto_Teleport_Frozen_Dimension", {
	Text = "Auto Teleport Frozen Dimension",
	Tooltip = "turn on for teleport to frozen dimension and start the leviathan gate",
	Default = false,
	Callback = function(Y)
		_G.FrozenTP = Y;
	end,
});
task.spawn(function()
	while IdleWait(_G.FrozenTP, .1) do
		if _G.FrozenTP then
			pcall(function()
				local gate = BFMapNode("LeviathanGate");
				if gate and gate:IsA("BasePart") then
					_tp(gate.CFrame);
					BFComm("OpenLeviathanGate");
				end;
			end);
		end;
	end;
end);
UI.BoatPurchaseAt = 0;
BFRequestSelectedBoat = function()
	local selected = _G.SelectedBoat;
	local now = os.clock();
	if not selected or now - UI.BoatPurchaseAt < 5 then
		return false;
	end;
	UI.BoatPurchaseAt = now;
	BFComm("BuyBoat", selected);
	return true;
end;
BFBoatSeat = function(boat)
	local seat = boat and boat:FindFirstChild("VehicleSeat", true);
	return seat and seat:IsA("BasePart") and seat or nil;
end;
PF:AddToggle("BF_Toggle_Auto_Drive_To_Hydra_Island", {
	Text = "Auto Drive To Hydra Island",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		_G.SailBoat_Hydra = Y;
	end,
});
task.spawn(function()
	while IdleWait(_G.SailBoat_Hydra) do
		if _G.SailBoat_Hydra then
			pcall(function()
				local Y = CheckBoat();
				local humanoid = BFHumanoid();
				if not humanoid then
					return;
				end;
				if not Y then
					local Y = CFrame.new(-16927.451, 9.086, 433.864);
					TeleportToTarget(Y);
					local character = d.Character;
					local root = character and character:FindFirstChild("HumanoidRootPart");
					if root and (Y.Position - root.Position).Magnitude <= 10 then
						BFRequestSelectedBoat();
					end;
				elseif Y then
					if humanoid.Sit == false then
						local seat = BFBoatSeat(Y);
						if seat then
							_tp(seat.CFrame * CFrame.new(0, 1, 0));
						end;
					else
						repeat
							task.wait();
							if CheckEnemiesBoat() or CheckPirateGrandBrigade() or CheckTerrorShark() then
								_tp(CFrame.new(5433, 150, 290));
							else
								_tp(CFrame.new(5433, 35, 290));
							end;
						until _G.SailBoat_Hydra == false or not humanoid.Parent or humanoid.Sit == false;
						if humanoid.Parent then
							humanoid.Sit = false;
						end;
					end;
				end;
			end);
		end;
	end;
end);
PF:AddDropdown("BF_Dropdown_Choose_Boats", {
	Text = "Choose Boats",
	Tooltip = "",
	Values = jF,
	Default = "Guardian",
	Multi = false,
	Callback = function(Y)
		_G.SelectedBoat = Y;
	end,
});
PF:AddButton({ Text = "Buy Boats", Func = function()
		BFComm("BuyBoat", _G.SelectedBoat);
	end });
PF:AddDropdown("BF_Dropdown_Choose_Sea_Level", {
	Text = "Choose Sea Level",
	Tooltip = "",
	Values = GF,
	Default = "Lv 1",
	Multi = false,
	Callback = function(Y)
		UI.SetManagedUserValue("DangerSc", Y);
	end,
});
PF:AddToggle("BF_Toggle_Auto_Sail_Boat", {
	Text = "Auto Sail Boat",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		UI.SetManagedUserFlag("SailBoats", Y);
	end,
});
task.spawn(function()
	while IdleWait(_G.SailBoats) do
		if _G.SailBoats then
			pcall(function()
				local Y = CheckBoat();
				local humanoid = BFHumanoid();
				if not humanoid then
					return;
				end;
				if not Y and (not (CheckShark() and _G.Shark or CheckTerrorShark() and _G.TerrorShark or CheckFishCrew() and _G.MobCrew or CheckPiranha() and _G.Piranha) and (not (CheckEnemiesBoat() and _G.FishBoat) and (not (CheckSeaBeast() and _G.SeaBeast1) and (not (_G.PGB and CheckPirateGrandBrigade()) and (not (_G.HCM and CheckHauntedCrew()) and not (_G.Leviathan1 and CheckLeviathan())))))) then
					local Y = CFrame.new(-16927.451, 9.086, 433.864);
					TeleportToTarget(Y);
					local character = d.Character;
					local root = character and character:FindFirstChild("HumanoidRootPart");
					if root and (Y.Position - root.Position).Magnitude <= 10 then
						BFRequestSelectedBoat();
					end;
				elseif Y and (not (CheckShark() and _G.Shark or CheckTerrorShark() and _G.TerrorShark or CheckFishCrew() and _G.MobCrew or CheckPiranha() and _G.Piranha) and (not (CheckEnemiesBoat() and _G.FishBoat) and (not (CheckSeaBeast() and _G.SeaBeast1) and (not (_G.PGB and CheckPirateGrandBrigade()) and (not (_G.HCM and CheckHauntedCrew()) and not (_G.Leviathan1 and CheckLeviathan())))))) then
					if humanoid.Sit == false then
						local seat = BFBoatSeat(Y);
						if seat then
							_tp(seat.CFrame * CFrame.new(0, 1, 0));
						end;
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
						until _G.SailBoats == false or CheckShark() and _G.Shark or CheckTerrorShark() and _G.TerrorShark or CheckFishCrew() and _G.MobCrew or CheckPiranha() and _G.Piranha or CheckSeaBeast() and _G.SeaBeast1 or CheckEnemiesBoat() and _G.FishBoat or _G.Leviathan1 and CheckLeviathan() or _G.HCM and CheckHauntedCrew() or _G.PGB and CheckPirateGrandBrigade() or not humanoid.Parent or humanoid.Sit == false;
						if humanoid.Parent then
							humanoid.Sit = false;
						end;
					end;
				end;
			end);
		end;
	end;
end);
UI.BoatCollisionOriginal = setmetatable({}, { __mode = "k" });
function UI.RestoreBoatCollisions()
	for part, original in pairs(UI.BoatCollisionOriginal) do
		if part.Parent then
			part.CanCollide = original == 1;
		end;
		UI.BoatCollisionOriginal[part] = nil;
	end;
end;
task.spawn(function()
	while IdleWait(_G.SailBoats or _G.Prehis_Find or _G.FindMirage or _G.SailBoat_Hydra or _G.AutofindKitIs, .2) do
		pcall(function()
			local active = _G.SailBoats or _G.Prehis_Find or _G.FindMirage or _G.SailBoat_Hydra or _G.AutofindKitIs;
			if not active then
				UI.RestoreBoatCollisions();
				return;
			end;
			local boats = workspace:FindFirstChild("Boats");
			if not boats then
				return;
			end;
			for _, boat in ipairs(boats:GetChildren()) do
				for _, part in ipairs(boat:GetDescendants()) do
					if part:IsA("BasePart") then
						if UI.BoatCollisionOriginal[part] == nil then
							UI.BoatCollisionOriginal[part] = part.CanCollide and 1 or 0;
						end;
						part.CanCollide = false;
					end;
				end;
			end;
		end);
	end;
	UI.RestoreBoatCollisions();
end);
local tF = UI.Sections["Entity Sea Event"];
local selectedSeaTargets = {
	Shark = true,
	Piranha = true,
	["Terror Shark"] = true,
	["Fish Crew Member"] = true,
	["Haunted Crew Member"] = true,
	["Pirate Grand Brigade"] = true,
	["Fish Boat"] = true,
	["Sea Beast"] = true,
	Leviathan = true,
};
local autoAttackSelectedSeaTargets = false;
local function ApplySelectedSeaTargets()
	UI.SetManagedUserFlag("Shark", autoAttackSelectedSeaTargets and selectedSeaTargets.Shark == true);
	UI.SetManagedUserFlag("Piranha", autoAttackSelectedSeaTargets and selectedSeaTargets.Piranha == true);
	UI.SetManagedUserFlag("TerrorShark", autoAttackSelectedSeaTargets and selectedSeaTargets["Terror Shark"] == true);
	UI.SetManagedUserFlag("MobCrew", autoAttackSelectedSeaTargets and selectedSeaTargets["Fish Crew Member"] == true);
	UI.SetManagedUserFlag("HCM", autoAttackSelectedSeaTargets and selectedSeaTargets["Haunted Crew Member"] == true);
	UI.SetManagedUserFlag("PGB", autoAttackSelectedSeaTargets and selectedSeaTargets["Pirate Grand Brigade"] == true);
	UI.SetManagedUserFlag("FishBoat", autoAttackSelectedSeaTargets and selectedSeaTargets["Fish Boat"] == true);
	UI.SetManagedUserFlag("SeaBeast1", autoAttackSelectedSeaTargets and selectedSeaTargets["Sea Beast"] == true);
	UI.SetManagedUserFlag("Leviathan1", autoAttackSelectedSeaTargets and selectedSeaTargets.Leviathan == true);
end;
tF:AddDropdown("BF_Dropdown_Selected_Sea_Targets", {
	Text = "Sea Targets",
	Tooltip = "Choose which sea-event enemies to attack",
	Values = { "Shark", "Piranha", "Terror Shark", "Fish Crew Member", "Haunted Crew Member", "Pirate Grand Brigade", "Fish Boat", "Sea Beast", "Leviathan" },
	Default = { "Shark", "Piranha", "Terror Shark", "Fish Crew Member", "Haunted Crew Member", "Pirate Grand Brigade", "Fish Boat", "Sea Beast", "Leviathan" },
	Multi = true,
	NoMode = true,
	Callback = function(Y)
		selectedSeaTargets = Y or {};
		ApplySelectedSeaTargets();
	end,
});
tF:AddToggle("BF_Toggle_Auto_Attack_Selected_Sea_Targets", {
	Text = "Auto Attack Selected",
	Tooltip = "Attack every selected sea-event target",
	Default = false,
	Callback = function(Y)
		autoAttackSelectedSeaTargets = Y;
		ApplySelectedSeaTargets();
	end,
});
task.spawn(function()
	while IdleWait(_G.Shark) do
		pcall(function()
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
				local beasts = workspace:FindFirstChild("SeaBeasts");
				if beasts and beasts:FindFirstChild("SeaBeast1") then
					for _, beast in ipairs(beasts:GetChildren()) do
						local health = beast:FindFirstChild("Health");
						if beast:FindFirstChild("HumanoidRootPart") and health and health.Value > 0 then
							repeat
								task.wait();
								BFAttackSeaBeastStep(beast, _G.SeaBeast1);
							until not _G.SeaBeast1 or not beast.Parent or not beast:FindFirstChild("HumanoidRootPart") or not health.Parent or health.Value <= 0;
						end;
					end;
				end;
			end;
			if _G.Leviathan1 then
				local beasts = workspace:FindFirstChild("SeaBeasts");
				if beasts and beasts:FindFirstChild("Leviathan") then
					for Y, R in pairs(beasts:GetChildren()) do
						local targetRoot = R:FindFirstChild("HumanoidRootPart");
						local segment = R:FindFirstChild("Leviathan Segment");
						local health = R:FindFirstChild("Health");
						if targetRoot and segment and health and health.Value > 0 then
							repeat
								task.wait();
								targetRoot = R:FindFirstChild("HumanoidRootPart");
								segment = R:FindFirstChild("Leviathan Segment");
								if not targetRoot or not segment then
									break;
								end;
								local plane = BFMapNode("WaterBase-Plane");
								local waterY = plane and plane.Position.Y or targetRoot.Position.Y;
								_tp(CFrame.new(targetRoot.Position.X, waterY + 200, targetRoot.Position.Z));
								if d:DistanceFromCharacter(targetRoot.Position) <= 500 then
									MousePos = segment.Position;
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
							until _G.Leviathan1 == false or not R.Parent or not health.Parent or health.Value <= 0;
						end;
					end;
				end;
			end;
			if _G.FishBoat then
				if CheckEnemiesBoat() then
					for _, R in pairs(workspace.Enemies:GetChildren()) do
						local health = R:FindFirstChild("Health");
						local seat = R:FindFirstChild("VehicleSeat");
						local engine = BFFirstPart(R:FindFirstChild("Engine"));
						if R.Name == "FishBoat" and health and health:IsA("ValueBase") and health.Value > 0 and seat and engine then
							repeat
								task.wait();
								_tp(engine.CFrame * CFrame.new(0, -50, -25));
								if d:DistanceFromCharacter(engine.Position) <= 150 then
									AitSeaSkill_Custom = engine.CFrame;
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
							until _G.FishBoat == false or not R.Parent or not seat.Parent or not engine.Parent or not health.Parent or health.Value <= 0;
						end;
					end;
				end;
			end;
			if _G.PGB then
				if CheckPirateGrandBrigade() then
					for _, R in pairs(workspace.Enemies:GetChildren()) do
						local health = R:FindFirstChild("Health");
						local seat = R:FindFirstChild("VehicleSeat");
						local engine = BFFirstPart(R:FindFirstChild("Engine"));
						local offset = R.Name == "PirateBrigade" and CFrame.new(0, -30, -10) or R.Name == "PirateGrandBrigade" and CFrame.new(0, -50, -50) or nil;
						if offset and health and health:IsA("ValueBase") and health.Value > 0 and seat and engine then
							repeat
								task.wait();
								_tp(engine.CFrame * offset);
								if d:DistanceFromCharacter(engine.Position) <= 150 then
									AitSeaSkill_Custom = engine.CFrame;
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
							until _G.PGB == false or not R.Parent or not seat.Parent or not engine.Parent or not health.Parent or health.Value <= 0;
						end;
					end;
				end;
			end;
		end);
	end;
end);
local XF = UI.Sections["Kitsune Island / Event"];
local hF = XF:AddLabel({ DoesWrap = true, Text = " Kitsune Island Status " });
task.spawn(function()
	while UI.LabelWait(2) do
		if BFMapNode("KitsuneIsland") or BFWorldLocation("Kitsune Island") then
			hF:SetText(" Kitsune Island : True");
		else
			hF:SetText(" Kitsune Island : False");
		end;
	end;
end);
XF:AddToggle("BF_Toggle_Auto_Find_Kitsune_Island", {
	Text = "Auto Find Kitsune Island",
	Tooltip = "turn on for finding & tween kitsune island",
	Default = false,
	Callback = function(Y)
		_G.AutofindKitIs = Y;
	end,
});
task.spawn(function()
	while IdleWait(_G.AutofindKitIs) do
		if _G.AutofindKitIs then
			pcall(function()
				local humanoid = BFHumanoid();
				if not humanoid then
					return;
				end;
				if not BFWorldLocation("Kitsune Island", true) then
					local Y = CheckBoat();
					if not Y then
						local Y = CFrame.new(-16927.451, 9.086, 433.864);
						TeleportToTarget(Y);
						if f.Pos(Y, 10) then
							BFRequestSelectedBoat();
						end;
					else
						if humanoid.Sit == false then
							local seat = BFBoatSeat(Y);
							if seat then
								_tp(seat.CFrame * CFrame.new(0, 1, 0));
							end;
						else
							local Y = CFrame.new(-10000000, 31, 37016.25);
							repeat
								task.wait();
								if CheckEnemiesBoat() or CheckTerrorShark() or CheckPirateGrandBrigade() then
									_tp(CFrame.new(-10000000, 150, 37016.25));
								else
									_tp(CFrame.new(-10000000, 31, 37016.25));
								end;
							until not _G.AutofindKitIs or f.Pos(Y, 10) or BFWorldLocation("Kitsune Island") or not humanoid.Parent or humanoid.Sit == false;
							if humanoid.Parent then
								humanoid.Sit = false;
							end;
						end;
					end;
				else
					local location = BFWorldLocation("Kitsune Island");
					if location and location:IsA("BasePart") then
						_tp(location.CFrame * CFrame.new(0, 500, 0));
					end;
				end;
			end);
		end;
	end;
end);
XF:AddToggle("BF_Toggle_Auto_Teleport_to_Shrine_Actived", {
	Text = "Auto Teleport to Shrine Actived",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		_G.tweenShrine = Y;
	end,
});
task.spawn(function()
	while IdleWait(_G.tweenShrine, .1) do
		if _G.tweenShrine then
			pcall(function()
				local Y = BFMapNode("KitsuneIsland") or BFWorldLocation("Kitsune Island");
				if not Y then
					return;
				end;
				local d = Y:FindFirstChild("ShrineActive");
				if d then
					for d, R in next, d:GetDescendants() do
						if R:IsA("BasePart") and R.Name:find("NeonShrinePart") then
							NetFire("RE/TouchKitsuneStatue");
							repeat
								task.wait();
								_tp(R.CFrame * CFrame.new(0, 2, 0));
							until _G.tweenShrine == false or not Y;
						end;
					end;
				else
					local location = BFWorldLocation("Kitsune Island");
					if location and location:IsA("BasePart") then
						_tp(location.CFrame * CFrame.new(0, 500, 0));
					end;
				end;
			end);
		end;
	end;
end);
UI.AzureCollectStatus = "idle";
UI.AzureTradeStatus = "idle";
UI.AzureCollectStatusLabel = nil;
UI.AzureTradeStatusLabel = nil;
UI.AzureTradeNextAt = 0;
function UI.SetAzureCollectStatus(status)
	status = tostring(status or "working");
	if status ~= UI.AzureCollectStatus then
		UI.AzureCollectStatus = status;
		if UI.AzureCollectStatusLabel then
			UI.AzureCollectStatusLabel:SetText("Azure collect: " .. status:gsub("%-", " "));
		end;
	end;
end;
function UI.SetAzureTradeStatus(status)
	status = tostring(status or "working");
	if status ~= UI.AzureTradeStatus then
		UI.AzureTradeStatus = status;
		if UI.AzureTradeStatusLabel then
			UI.AzureTradeStatusLabel:SetText("Azure trade: " .. status:gsub("%-", " "));
		end;
	end;
end;
XF:AddToggle("BF_Toggle_Auto_Collect_Azure_Ember", {
	Text = "Auto Collect Azure Ember",
	Tooltip = "Collect spawned Azure Embers without trading them",
	Default = false,
	Callback = function(Y)
		_G.Collect_Ember = Y;
		if not Y then
			UI.SetAzureCollectStatus("idle");
		end;
	end,
});
UI.AzureCollectStatusLabel = XF:AddLabel({ DoesWrap = true, Text = "Azure collect: " .. UI.AzureCollectStatus:gsub("%-", " ") });
task.spawn(function()
	while IdleWait(_G.Collect_Ember, .2) do
		if _G.Collect_Ember then
			local ok = pcall(function()
				if not World3 then
					UI.SetAzureCollectStatus("wrong-world");
					return;
				end;
				local ember = FindNamed("EmberTemplate") or FindNamed("AttachedAzureEmber");
				local emberPart = ember and (ember:IsA("BasePart") and ember or ember:FindFirstChild("Part") or BFFirstPart(ember));
				if emberPart and emberPart:IsA("BasePart") then
					UI.SetAzureCollectStatus("collecting");
					BFMoveNear(emberPart.CFrame, 3);
				else
					local location = BFWorldLocation("Kitsune Island");
					if location and location:IsA("BasePart") then
						UI.SetAzureCollectStatus("waiting-for-ember");
						BFMoveNear(location.CFrame * CFrame.new(0, 500, 0), 50);
					else
						UI.SetAzureCollectStatus("waiting-for-kitsune-island");
					end;
				end;
			end);
			if not ok then
				UI.SetAzureCollectStatus("error");
			end;
		end;
	end;
end);
XF:AddToggle("BF_Toggle_Auto_Trade_Azure_Ember", {
	Text = "Auto Trade Azure Ember",
	Tooltip = "Repeatedly trade Azure Embers at the Kitsune shrine",
	Default = false,
	Callback = function(Y)
		_G.Trade_Ember = Y;
		if Y then
			UI.AzureTradeNextAt = 0;
		else
			UI.SetAzureTradeStatus("idle");
		end;
	end,
});
UI.AzureTradeStatusLabel = XF:AddLabel({ DoesWrap = true, Text = "Azure trade: " .. UI.AzureTradeStatus:gsub("%-", " ") });
task.spawn(function()
	while IdleWait(_G.Trade_Ember, .25) do
		if _G.Trade_Ember then
			local ok = pcall(function()
				if not World3 then
					UI.SetAzureTradeStatus("wrong-world");
					return;
				end;
				if not BFWorldLocation("Kitsune Island", true) then
					UI.SetAzureTradeStatus("waiting-for-kitsune-island");
					return;
				end;
				local now = os.clock();
				if now >= UI.AzureTradeNextAt then
					UI.AzureTradeNextAt = now + 2;
					UI.SetAzureTradeStatus("trading");
					NetInvoke("RF/KitsuneStatuePray");
				end;
			end);
			if not ok then
				UI.SetAzureTradeStatus("error");
			end;
		end;
	end;
end);
XF:AddButton({ Text = "Trade Items Azure", Func = function()
		NetInvoke("RF/KitsuneStatuePray");
	end });
XF:AddButton({ Text = "Talk with kitsune statue", Func = function()
		NetFire("RE/TouchKitsuneStatue");
	end });
local BF = UI.Sections["Mystic Island / Full Moon"];
FullMOOn = BF:AddLabel({ DoesWrap = true, Text = " FullMoon Status " });
Ismirage = BF:AddLabel({ DoesWrap = true, Text = " Mirage Island Status " });
BFFindGreatTreeTop = function()
	if type(BFFindNpc) == "function" then
		local _, forceRoot = BFFindNpc("Mysterious Force");
		if forceRoot and forceRoot:IsA("BasePart") then
			return forceRoot.CFrame * CFrame.new(0, 0, 4), "npc";
		end;
	end;
	local tree = workspace:FindFirstChild("Great Tree");
	if not tree then
		local map = workspace:FindFirstChild("Map");
		for _, object in ipairs(map and map:GetDescendants() or {}) do
			local key = BFNameKey(object.Name);
			if not object:IsA("BasePart") and string.find(key, "greattree", 1, true) then
				tree = object;
				break;
			end;
		end;
	end;
	local highestPart;
	local highestY = -math.huge;
	for _, object in ipairs(tree and tree:GetDescendants() or {}) do
		if object:IsA("BasePart") then
			local topY = object.Position.Y + object.Size.Y * .5;
			if topY > highestY then
				highestY = topY;
				highestPart = object;
			end;
		end;
	end;
	local location = BFWorldLocation("Great Tree", true);
	local probe = highestPart and Vector3.new(highestPart.Position.X, highestY, highestPart.Position.Z) or location and location.Position;
	if probe then
		local params = RaycastParams.new();
		params.FilterType = Enum.RaycastFilterType.Exclude;
		params.FilterDescendantsInstances = d.Character and { d.Character } or {};
		pcall(function()
			params.RespectCanCollide = true;
		end);
		local originY = math.max(probe.Y, highestY > -math.huge and highestY or probe.Y) + 600;
		local hit = workspace:Raycast(Vector3.new(probe.X, originY, probe.Z), Vector3.new(0, -1200, 0), params);
		if hit and (highestY == -math.huge or hit.Position.Y >= highestY - 50) then
			local character = d.Character;
			local humanoid = character and character:FindFirstChildOfClass("Humanoid");
			local root = character and character:FindFirstChild("HumanoidRootPart");
			local clearance = (humanoid and humanoid.HipHeight or 2) + (root and root.Size.Y * .5 or 1) + .5;
			return CFrame.new(hit.Position + Vector3.new(0, clearance, 0)), "surface";
		end;
	end;
	if highestPart then
		return CFrame.new(highestPart.Position.X, highestY + 8, highestPart.Position.Z), "visual-top";
	end;
	if location and location:IsA("BasePart") then
		return location.CFrame * CFrame.new(0, 6, 0), "location";
	end;
	return nil, "unavailable";
end;
getgenv().BFFindGreatTreeTop = BFFindGreatTreeTop;
BF:AddButton({
	Text = "Teleport Top of Great Tree",
	Func = function()
		task.spawn(function()
			local top = BFFindGreatTreeTop();
			if top then
				_tp(top);
			else
				UI.Library:Notify("Great Tree target is unavailable.", 4);
			end;
		end);
	end,
});
task.spawn(function()
	while UI.LabelWait(2) do
		if BFMapNode("MysticIsland") or BFWorldLocation("Mirage Island") then
			Ismirage:SetText(" Mirage Island : True");
		else
			Ismirage:SetText(" Mirage Island : False");
		end;
	end;
end);
task.spawn(function()
	moon8 = "http://www.roblox.com/asset/?id=9709150401";
	while UI.LabelWait(1) do
		pcall(function()
			moon7 = "http://www.roblox.com/asset/?id=9709150086";
			moon6 = "http://www.roblox.com/asset/?id=9709149680";
			moon5 = "http://www.roblox.com/asset/?id=9709149431";
			moon4 = "http://www.roblox.com/asset/?id=9709149052";
			moon3 = "http://www.roblox.com/asset/?id=9709143733";
			moon2 = "http://www.roblox.com/asset/?id=9709139597";
			moon1 = "http://www.roblox.com/asset/?id=9709135895";
			moon = Getmoon();
			if moon == moon1 then
				FullMOOn:SetText("Moon : 0 / 8");
			elseif moon == moon2 then
				FullMOOn:SetText("Moon : 1 / 8");
			elseif moon == moon3 then
				FullMOOn:SetText("Moon : 2 / 8");
			elseif moon == moon4 then
				FullMOOn:SetText("Moon : 3 / 8 [ Next Night ]");
			elseif moon == moon5 then
				FullMOOn:SetText("Moon : 4 / 8 [ Full Moon ]");
			elseif moon == moon6 then
				FullMOOn:SetText("Moon : 5 / 8 [ Last Night ]");
			elseif moon == moon7 then
				FullMOOn:SetText("Moon : 6 / 8");
			elseif moon == moon8 then
				FullMOOn:SetText("Moon : 7 / 8");
			end;
		end);
	end;
end);
BF:AddToggle("BF_Toggle_Auto_Find_Mirage_Island", {
	Text = "Auto Find Mirage Island",
	Tooltip = "turn on for finding & tween mirage island",
	Default = false,
	Callback = function(Y)
		_G.FindMirage = Y;
	end,
});
task.spawn(function()
	while IdleWait(_G.FindMirage) do
		if _G.FindMirage then
			pcall(function()
				local humanoid = BFHumanoid();
				if not humanoid then
					return;
				end;
				if not BFWorldLocation("Mirage Island", true) then
					local Y = CheckBoat();
					if not Y then
						local Y = CFrame.new(-16927.451, 9.086, 433.864);
						TeleportToTarget(Y);
						if f.Pos(Y, 10) then
							BFRequestSelectedBoat();
						end;
					else
						if humanoid.Sit == false then
							local seat = BFBoatSeat(Y);
							if seat then
								_tp(seat.CFrame * CFrame.new(0, 1, 0));
							end;
						else
							repeat
								task.wait();
								local Y = CFrame.new(-10000000, 31, 37016.25);
								if CheckEnemiesBoat() or CheckTerrorShark() or CheckPirateGrandBrigade() then
									_tp(CFrame.new(-10000000, 150, 37016.25));
								else
									_tp(CFrame.new(-10000000, 31, 37016.25));
								end;
							until not _G.FindMirage or f.Pos(Y, 10) or BFWorldLocation("Mirage Island") or not humanoid.Parent or humanoid.Sit == false;
							if humanoid.Parent then
								humanoid.Sit = false;
							end;
						end;
					end;
				else
					local center = BFMapNode("MysticIsland", "Center");
					if center and center:IsA("BasePart") then
						_tp(center.CFrame * CFrame.new(0, 300, 0));
					end;
				end;
			end);
		end;
	end;
end);
BF:AddToggle("BF_Toggle_Auto_Tween_To_Highest_Point", {
	Text = "Auto Tween To Highest Point",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		_G.HighestMirage = Y;
	end,
});
task.spawn(function()
	while IdleWait(_G.HighestMirage, T) do
		if _G.HighestMirage then
			pcall(function()
				if BFWorldLocation("Mirage Island", true) then
					local center = BFMapNode("MysticIsland", "Center");
					if center and center:IsA("BasePart") then
						_tp(center.CFrame * CFrame.new(0, 400, 0));
					end;
				end;
			end);
		end;
	end;
end);
BF:AddToggle("BF_Toggle_Auto_Collect_Gear", {
	Text = "Auto Collect Gear",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		_G.TPGEAR = Y;
	end,
});
task.spawn(function()
	while IdleWait(_G.TPGEAR, .1) do
		if _G.TPGEAR then
			pcall(function()
				local island = BFMapNode("MysticIsland");
				local character = d.Character;
				local root = character and character:FindFirstChild("HumanoidRootPart");
				if not island or not root then
					return;
				end;
				local closest, closestDistance;
				for _, part in ipairs(island:GetDescendants()) do
					if part:IsA("MeshPart") and part.Name == "Part" and part.Material == Enum.Material.Neon then
						local distance = (part.Position - root.Position).Magnitude;
						if not closestDistance or distance < closestDistance then
							closest = part;
							closestDistance = distance;
						end;
					end;
				end;
				if closest then
					_tp(closest.CFrame);
				end;
			end);
		end;
	end;
end);
UI.MirageTransparencyOriginal = setmetatable({}, { __mode = "k" });
function UI.RestoreMirageTransparency()
	for part, transparency in pairs(UI.MirageTransparencyOriginal) do
		if part.Parent then
			part.Transparency = transparency;
		end;
		UI.MirageTransparencyOriginal[part] = nil;
	end;
end;
BF:AddToggle("BF_Toggle_Change_Transparency_can_see", {
	Text = "Reveal Mirage Gear",
	Tooltip = "Hide island cover parts and reveal the neon gear",
	Default = false,
	Callback = function(Y)
		_G.can = Y;
		if not Y then
			UI.RestoreMirageTransparency();
		end;
	end,
});
task.spawn(function()
	while IdleWait(_G.can, T) do
		if _G.can then
			pcall(function()
				local island = BFMapNode("MysticIsland");
				if not island then
					return;
				end;
				for _, part in ipairs(island:GetDescendants()) do
					if part:IsA("BasePart") and part.Name == "Part" then
						if UI.MirageTransparencyOriginal[part] == nil then
							UI.MirageTransparencyOriginal[part] = part.Transparency;
						end;
						part.Transparency = part:IsA("MeshPart") and 0 or 1;
					end;
				end;
			end);
		end;
	end;
end);
BF:AddToggle("BF_Toggle_Auto_Tween_Advanced_Fruit_Dealer", {
	Text = "Auto Tween Advanced Fruit Dealer",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		_G.Addealer = Y;
	end,
});
task.spawn(function()
	while IdleWait(_G.Addealer) do
		if _G.Addealer then
			pcall(function()
				local npc, root;
				if type(BFFindNpc) == "function" then
					npc, root = BFFindNpc("Advanced Fruit Dealer");
				end;
				if npc and npc:IsDescendantOf(workspace) and root and root:IsA("BasePart") then
					_tp(root.CFrame);
				end;
			end);
		end;
	end;
end);
BF:AddToggle("BF_Toggle_Auto_Collect_Mirage_Chest", {
	Text = "Auto Collect Mirage Chest",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		_G.FarmChestM = Y;
	end,
});
task.spawn(function()
	while IdleWait(_G.FarmChestM, .2) do
		if _G.FarmChestM then
			pcall(function()
				local chests = BFMapNode("MysticIsland", "Chests");
				if chests and (chests:FindFirstChild("DiamondChest") or chests:FindFirstChild("FragChest")) then
					local Y = game:GetService("CollectionService");
					local d = game:GetService("Players");
					local R = d.LocalPlayer;
					local Q = R.Character;
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
local lF = UI.Sections["Skull Guitar / Misc"];
local pF = lF:AddLabel({ DoesWrap = true, Text = " Skull Guitar Quests " });
task.spawn(function()
	while UI.LabelWait(.2) do
		pcall(function()
			if Quest1 == true then
				pF:SetText(" Quest Number : Quest1");
			elseif Quest2 == true then
				pF:SetText(" Quest Number : Quest2");
			elseif Quest3 == true then
				pF:SetText(" Quest Number : Quest3");
			elseif Quest4 == true then
				pF:SetText(" Quest Number : Quest4");
			elseif GetWP("Skull Guitar") then
				pF:SetText(" Quest Number : Collect!!");
			else
				pF:SetText(" Quest Number : No Quest!!");
			end;
		end);
	end;
end);
lF:AddToggle("BF_Toggle_Auto_Skull_Guitar", {
	Text = "Auto Skull Guitar",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		_G.Auto_Soul_Guitar = Y;
	end,
});
task.spawn(function()
	while IdleWait(_G.Auto_Soul_Guitar) do
		if _G.Auto_Soul_Guitar then
			pcall(function()
				local Y = GetConnectionEnemies("Living Zombie");
				if Y then
					Y.HumanoidRootPart.CFrame = CFrame.new(-10138.397460938, 138.65246582031, 5902.8920898438);
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
	local segment = BFMapNode("Haunted Castle", "Tablet", "Segment" .. tostring(Y));
	local line = segment and segment:FindFirstChild("Line");
	return line and line.Rotation.Z or nil;
end;
function getRT(Y)
	local trophy = BFMapNode("Haunted Castle", "Trophies", "Quest", "Trophy" .. tostring(Y));
	local handle = trophy and trophy:FindFirstChild("Handle");
	return handle and handle.Rotation.Z or nil;
end;
FireTabletSegment = function(Y)
		local segment = BFMapNode("Haunted Castle", "Tablet", "Segment" .. tostring(Y));
		local detector = segment and segment:FindFirstChildOfClass("ClickDetector");
		if detector and type(fireclickdetector) == "function" then
			pcall(fireclickdetector, detector);
		end;
	end;
GetFirePlacard = function(Y, d)
		local side = BFMapNode("Haunted Castle", "Placard" .. tostring(Y), d);
		local indicator = side and side:FindFirstChild("Indicator");
		local detector = side and side:FindFirstChildOfClass("ClickDetector");
		if indicator and detector and type(fireclickdetector) == "function" and tostring(indicator.BrickColor) ~= "Pearl" then
			pcall(fireclickdetector, detector);
		end;
	end;
task.spawn(function()
	while IdleWait(_G.Auto_Soul_Guitar, T) do
		pcall(function()
			if _G.Auto_Soul_Guitar then
				if BFStopOwnedAcquisition("BF_Toggle_Auto_Skull_Guitar") then
					return;
				end;
				if World3 then
					local progress = BFComm("GuitarPuzzleProgress", "Check");
					if type(progress) ~= "table" then
						_tp(CFrame.new(-8655.0166015625, 141.31669616699, 6160.0224609375));
						BFComm("gravestoneEvent", 2);
						BFComm("gravestoneEvent", 2, true);
					elseif progress.Swamp == false then
						Quest1 = true;
						Quest2 = false;
						Quest3 = false;
						Quest4 = false;
						local Y = GetConnectionEnemies("Living Zombie");
						if Y then
							local swampWater = BFMapNode("Haunted Castle", "SwampWater");
							repeat
								task.wait();
								f.Kill(Y, _G.Auto_Soul_Guitar);
							until not _G.Auto_Soul_Guitar or not Y.Parent or not f.Alive(Y) or swampWater and swampWater.Color ~= Color3.fromRGB(117, 0, 0);
						else
							_tp(CFrame.new(-10170.727539062, 138.65246582031, 5934.2651367188));
						end;
					elseif progress.Gravestones == false then
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
					elseif progress.Ghost == false then
						BFComm("GuitarPuzzleProgress", "Ghost");
						BFComm("GuitarPuzzleProgress", "Ghost", true);
					elseif progress.Trophies == false then
						Quest1 = false;
						Quest2 = false;
						Quest3 = true;
						Quest4 = false;
						_tp(CFrame.new(-9532.8232421875, 6.471667766571, 6078.068359375));
						repeat
							task.wait();
							local Y = getRT(1);
							local d = getT(1);
							if Y and d then
								FireTabletSegment(1);
							end;
						until not _G.Auto_Soul_Guitar or Y == d;
						repeat
							task.wait();
							local Y = getRT(2);
							local d = getT(3);
							if Y and d then
								FireTabletSegment(3);
							end;
						until not _G.Auto_Soul_Guitar or Y == d;
						repeat
							task.wait();
							local Y = getRT(3);
							local d = getT(4);
							if Y and d then
								FireTabletSegment(4);
							end;
						until not _G.Auto_Soul_Guitar or Y == d;
						repeat
							task.wait();
							local Y = getRT(4);
							local d = getT(7);
							if Y and d then
								FireTabletSegment(7);
							end;
						until not _G.Auto_Soul_Guitar or Y == d;
						repeat
							task.wait();
							local Y = getRT(5);
							local d = getT(10);
							if Y and d then
								FireTabletSegment(10);
							end;
						until not _G.Auto_Soul_Guitar or Y == d;
						local tablet = BFMapNode("Haunted Castle", "Tablet");
						if tablet then
							local neutralSegments = { 2, 5, 6, 8, 9 };
							local aligned = false;
							repeat
								aligned = true;
								for _, index in ipairs(neutralSegments) do
									local segment = tablet:FindFirstChild("Segment" .. index);
									local line = segment and segment:FindFirstChild("Line");
									local detector = segment and segment:FindFirstChildOfClass("ClickDetector");
									if not line then
										aligned = false;
									elseif line.Rotation.Z ~= 0 then
										aligned = false;
										if detector and type(fireclickdetector) == "function" then
											pcall(fireclickdetector, detector);
										end;
									end;
								end;
								task.wait();
							until not _G.Auto_Soul_Guitar or aligned;
						end;
					elseif progress.Pipes == false then
						Quest1 = false;
						Quest2 = false;
						Quest3 = false;
						Quest4 = true;
						for _, pipe in ipairs({ { 3, 1 }, { 4, 3 }, { 6, 2 }, { 8, 1 }, { 10, 3 } }) do
							local part = BFMapNode("Haunted Castle", "Lab Puzzle", "ColorFloor", "Model", "Part" .. pipe[1]);
							local detector = part and part:FindFirstChildOfClass("ClickDetector");
							if part and part:IsA("BasePart") then
								_tp(part.CFrame);
							end;
							if detector and type(fireclickdetector) == "function" then
								for _ = 1, pipe[2] do
									pcall(fireclickdetector, detector);
								end;
							end;
						end;
					end;
				end;
			end;
		end);
	end;
end);
UI.SoulMaterialStatus = "idle";
UI.SoulMaterialStatusLabel = nil;
UI.SoulMaterialNextPurchaseAt = 0;
UI.SoulMaterialNextTravelAt = 0;
UI.SoulMaterialDarkArena = CFrame.new(3798.4575195313, 13.826690673828, -3399.806640625);
function UI.SetSoulMaterialStatus(status)
	status = tostring(status or "working");
	if status ~= UI.SoulMaterialStatus then
		UI.SoulMaterialStatus = status;
		if UI.SoulMaterialStatusLabel then
			UI.SoulMaterialStatusLabel:SetText("Skull Guitar materials: " .. status:gsub("%-", " "));
		end;
	end;
end;
function UI.SoulMaterialTravel(targetWorld, now)
	UI.ReleaseManagedOwner("SoulMaterial");
	if now >= UI.SoulMaterialNextTravelAt then
		UI.SoulMaterialNextTravelAt = now + 3;
		if targetWorld == 3 and World2 then
			BFComm("TravelZou");
		else
			BFComm("TravelDressrosa");
		end;
	end;
	return targetWorld == 3 and "traveling-to-third-sea" or "traveling-to-second-sea";
end;
lF:AddToggle("BF_Toggle_Auto_Farm_Material_Skull_Guitar", {
	Text = "Auto Farm Skull Guitar Materials",
	Tooltip = "Farm Ectoplasm, Dark Fragment, and Bones in sequence, then buy Skull Guitar",
	Default = false,
	Callback = function(Y)
		_G.AutoMatSoul = Y;
		if Y then
			UI.SoulMaterialNextPurchaseAt = 0;
			UI.SoulMaterialNextTravelAt = 0;
		elseif UI.SoulMaterialStatus ~= "complete" then
			UI.ReleaseManagedOwner("SoulMaterial");
			UI.SetSoulMaterialStatus("idle");
		end;
	end,
});
UI.SoulMaterialStatusLabel = lF:AddLabel({ DoesWrap = true, Text = "Skull Guitar materials: idle" });
function UI.SoulMaterialStep(active)
	if not active then
		UI.ReleaseManagedOwner("SoulMaterial");
		return "idle";
	end;
	if GetWP("Skull Guitar") then
		UI.ReleaseManagedOwner("SoulMaterial");
		return "complete";
	end;
	local now = os.clock();
	if (tonumber(GetM("Ectoplasm")) or 0) < 250 then
		if not World2 then
			return UI.SoulMaterialTravel(2, now);
		end;
		UI.DriveManagedValue("SoulMaterial", "SelectMaterial", "Ectoplasm");
		UI.DriveManagedFlag("SoulMaterial", "AutoMaterial");
		return "farming-ectoplasm";
	end;
	UI.ReleaseManagedOwner("SoulMaterial");
	if (tonumber(GetM("Dark Fragment")) or 0) < 1 then
		if not World2 then
			return UI.SoulMaterialTravel(2, now);
		end;
		local enemy = GetConnectionEnemies("Darkbeard");
		if enemy then
			f.Kill(enemy, active);
			return "fighting-darkbeard";
		end;
		BFMoveNear(UI.SoulMaterialDarkArena, 40);
		return "waiting-for-darkbeard";
	end;
	if (tonumber(GetBones()) or 0) < 500 then
		if not World3 then
			return UI.SoulMaterialTravel(3, now);
		end;
		UI.DriveManagedFlag("SoulMaterial", "AutoFarm_Bone");
		return "farming-bones";
	end;
	UI.ReleaseManagedOwner("SoulMaterial");
	if now >= UI.SoulMaterialNextPurchaseAt then
		UI.SoulMaterialNextPurchaseAt = now + 2;
		BFComm("soulGuitarBuy", true);
	end;
	return "buying-skull-guitar";
end;
task.spawn(function()
	while IdleWait(_G.AutoMatSoul, .25) do
		if _G.AutoMatSoul then
			local ok, status = pcall(UI.SoulMaterialStep, _G.AutoMatSoul);
			status = ok and tostring(status or "working") or "error";
			if not ok then
				UI.ReleaseManagedOwner("SoulMaterial");
			end;
			UI.SetSoulMaterialStatus(status);
			if status == "complete" then
				UI.DisableToggle("BF_Toggle_Auto_Farm_Material_Skull_Guitar");
			end;
		end;
	end;
	UI.ReleaseManagedOwner("SoulMaterial");
end);
lF:AddButton({ Text = "Talk With Stone", Func = function()
		BFComm("RaceV4Progress", "Begin");
		BFComm("RaceV4Progress", "Check");
		BFComm("RaceV4Progress", "Teleport");
		BFComm("RaceV4Progress", "Continue");
	end });
lF:AddToggle("BF_Toggle_Auto_Look_At_Moon", {
	Text = "Auto Look At Moon",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		LookM = Y;
	end,
});
function MoveCamtoMoon()
	local camera = workspace.CurrentCamera;
	local character = d.Character;
	local root = character and character:FindFirstChild("HumanoidRootPart");
	local direction = F:GetMoonDirection();
	if camera then
		camera.CFrame = CFrame.new(camera.CFrame.Position, direction + camera.CFrame.Position);
	end;
	if root then
		root.CFrame = CFrame.new(root.Position, direction + root.Position);
	end;
end;
task.spawn(function()
	while IdleWait(LookM) do
		if LookM then
			MoveCamtoMoon();
			task.wait(.1);
				BFCommE("ActivateAbility");
		end;
	end;
end);
local EF = UI.Sections["Trials Quests / Misc V4"];
local eF = EF:AddLabel({ DoesWrap = true, Text = " Tiers V4 Status " });
task.spawn(function()
	while UI.LabelWait(5) do
		local data = d:FindFirstChild("Data");
		local race = data and data:FindFirstChild("Race");
		local tier = race and race:FindFirstChild("C");
		eF:SetText(" Tiers - V4  : " .. tostring(tier and tier.Value or "Unavailable"));
	end;
end);
UI.LeverStatus = "idle";
UI.LeverStatusLabel = nil;
UI.LeverNextPromptAt = 0;
function UI.SetLeverStatus(status)
	status = tostring(status or "working");
	if status ~= UI.LeverStatus then
		UI.LeverStatus = status;
		if UI.LeverStatusLabel then
			UI.LeverStatusLabel:SetText("Temple lever: " .. status:gsub("%-", " "));
		end;
	end;
end;
EF:AddToggle("BF_Toggle_Auto_Pull_Lever", {
	Text = "Auto Pull Lever",
	Tooltip = "Activate the Temple of Time lever prompt",
	Default = false,
	Callback = function(Y)
		_G.Lver = Y;
		if Y then
			UI.LeverNextPromptAt = 0;
		else
			UI.SetLeverStatus("idle");
		end;
	end,
});
UI.LeverStatusLabel = EF:AddLabel({ DoesWrap = true, Text = "Temple lever: " .. UI.LeverStatus:gsub("%-", " ") });
task.spawn(function()
	while IdleWait(_G.Lver, .25) do
		if _G.Lver then
			local ok = pcall(function()
				if not World3 then
					UI.SetLeverStatus("wrong-world");
					return;
				end;
				if type(fireproximityprompt) ~= "function" then
					UI.SetLeverStatus("prompt-unsupported");
					return;
				end;
				local temple = BFMapNode("Temple of Time");
				if not temple then
					UI.SetLeverStatus("waiting-for-temple");
					return;
				end;
				local leverPrompt;
				local fallbackPrompt;
				for _, prompt in pairs(temple:GetDescendants()) do
					if prompt:IsA("ProximityPrompt") and prompt.Enabled then
						fallbackPrompt = fallbackPrompt or prompt;
						if string.find(string.lower(prompt:GetFullName()), "lever", 1, true) then
							leverPrompt = prompt;
							break;
						end;
					end;
				end;
				leverPrompt = leverPrompt or fallbackPrompt;
				if not leverPrompt then
					UI.SetLeverStatus("waiting-for-lever-prompt");
					return;
				end;
				local now = os.clock();
				if now >= UI.LeverNextPromptAt then
					UI.LeverNextPromptAt = now + 1;
					UI.SetLeverStatus("activating");
					pcall(fireproximityprompt, leverPrompt, math.huge);
				end;
			end);
			if not ok then
				UI.SetLeverStatus("error");
			end;
		end;
	end;
end);
EF:AddToggle("BF_Toggle_Auto_Train_V4", {
	Text = "Auto Train V4",
	Tooltip = "turn on for farm tier + auto upgrade your tier level",
	Default = false,
	Callback = function(Y)
		_G.AcientOne = Y;
	end,
});
BFRaceUpgradeNextAt = { Standard = 0, Draco = 0 };
task.spawn(function()
	while IdleWait(_G.AcientOne, T) do
		pcall(function()
			if _G.AcientOne then
				local Y = {
						"Reborn Skeleton",
						"Living Zombie",
						"Demonic Soul",
						"Posessed Mummy",
					};
				local character = d.Character;
				local raceEnergy = character and character:FindFirstChild("RaceEnergy");
				local raceTransformed = character and character:FindFirstChild("RaceTransformed");
				local energy = raceEnergy and tonumber(raceEnergy.Value);
				if energy and energy >= 1 then
					local now = os.clock();
					if now >= BFRaceUpgradeNextAt.Standard then
						BFRaceUpgradeNextAt.Standard = now + 2;
						Useskills("nil", "Y");
						BFComm("UpgradeRace", "Buy");
					end;
					_tp(CFrame.new(-8987.041015625, 215.86206054688, 5886.7104492188));
				elseif not raceTransformed or raceTransformed.Value == false then
					local target = GetConnectionEnemies(Y);
					if target then
						repeat
							task.wait();
							f.Kill(target, _G.AcientOne);
						until _G.AcientOne == false or not target.Parent or not f.Alive(target);
					else
						_tp(CFrame.new(-9495.6806640625, 453.58624267578, 5977.3486328125));
					end;
				end;
			end;
		end);
	end;
end);
BFTempleAnchor = function()
	if type(BFFindNpc) == "function" then
		local _, root = BFFindNpc("Ancient One");
		if root then
			return root;
		end;
		_, root = BFFindNpc("Mysterious Force3");
		if root then
			return root;
		end;
	end;
	local location = BFWorldLocation("Ancient Clock", true);
	if location and location:IsA("BasePart") then
		return location;
	end;
	local temple = BFMapNode("Temple of Time");
	return BFFirstPart(temple);
end;
BFIsInTemple = function()
	local root = BFCharacterPart();
	local anchor = BFTempleAnchor();
	return root ~= nil and anchor ~= nil and (root.Position - anchor.Position).Magnitude <= 2500;
end;
getgenv().BFIsInTemple = BFIsInTemple;
BFDirectTeleport = function(target)
	if typeof(target) ~= "CFrame" then
		return false;
	end;
	local root = BFCharacterPart();
	if not root then
		return false;
	end;
	BFCancelTween();
	if root.Anchored then
		root.Anchored = false;
	end;
	root.CFrame = target;
	return true;
end;
BFEnsureTempleMap = function()
	if not World3 then
		return nil;
	end;
	local map = workspace:FindFirstChild("Map");
	if not map then
		return nil;
	end;
	local existing = map:FindFirstChild("Temple of Time");
	if existing then
		if existing:GetAttribute("BFClientTemple") then
			UI.ClientTempleMap = existing;
		end;
		return existing;
	end;
	local mapStash = Q:FindFirstChild("MapStash");
	local template = mapStash and mapStash:FindFirstChild("Temple of Time");
	if not template then
		return nil;
	end;
	local ok, temple = pcall(template.Clone, template);
	if not ok or not temple then
		return nil;
	end;
	temple:SetAttribute("BFClientTemple", true);
	temple.Parent = map;
	UI.ClientTempleMap = temple;
	return temple;
end;
BFTemplePortalTarget = function(temple)
	temple = temple or BFEnsureTempleMap();
	if not temple then
		return nil;
	end;
	local spawn = temple:FindFirstChild("TeleportSpawn", true);
	if spawn and spawn:IsA("BasePart") then
		return spawn;
	end;
	return BFFirstPart(temple);
end;
function TpTemple()
	if not World3 then
		return false, "wrong-world";
	end;
	if BFIsInTemple() then
		return true, "already-inside";
	end;
	local temple = BFEnsureTempleMap();
	local portal = BFTemplePortalTarget(temple);
	if not temple or not portal then
		return false, "temple-map-unavailable";
	end;
	BFCancelTween();
	BFComm("requestEntrance", portal.Position);
	for _ = 1, 40 do
		task.wait(.1);
		if BFIsInTemple() then
			return true, "entered";
		end;
	end;
	BFDirectTeleport(portal.CFrame * CFrame.new(0, 4, 0));
	for _ = 1, 20 do
		task.wait(.1);
		if BFIsInTemple() then
			return true, "entered-fallback";
		end;
	end;
	return false, "teleport-unavailable";
end;
getgenv().BFTpTemple = TpTemple;
getgenv().BFEnsureTempleMap = BFEnsureTempleMap;
BFAncientClockTarget = function()
	local temple = BFEnsureTempleMap();
	if not temple then
		return nil;
	end;
	local promptContainer = temple:FindFirstChild("Prompt", true);
	local prompt = promptContainer and promptContainer:FindFirstChildWhichIsA("ProximityPrompt", true);
	local promptPart = prompt and prompt.Parent;
	if promptPart and promptPart:IsA("Attachment") then
		promptPart = promptPart.Parent;
	end;
	if promptPart and promptPart:IsA("BasePart") then
		local params = RaycastParams.new();
		params.FilterType = Enum.RaycastFilterType.Exclude;
		params.FilterDescendantsInstances = d.Character and { d.Character } or {};
		pcall(function()
			params.RespectCanCollide = true;
		end);
		local hit = workspace:Raycast(promptPart.Position + Vector3.new(0, 8, 0), Vector3.new(0, -40, 0), params);
		if hit then
			local character = d.Character;
			local humanoid = character and character:FindFirstChildOfClass("Humanoid");
			local root = character and character:FindFirstChild("HumanoidRootPart");
			local clearance = (humanoid and humanoid.HipHeight or 2) + (root and root.Size.Y * .5 or 1) + .5;
			local position = hit.Position + Vector3.new(0, clearance, 0);
			return CFrame.new(position, promptPart.Position), prompt;
		end;
		return promptPart.CFrame * CFrame.new(0, 4, 0), prompt;
	end;
	local clock = temple:FindFirstChild("Clock", true);
	if clock and clock:IsA("Model") then
		return clock:GetPivot(), nil;
	end;
	local target = BFWorldLocation("Ancient Clock", true);
	return target and target:IsA("BasePart") and target.CFrame or nil, nil;
end;
getgenv().BFAncientClockTarget = BFAncientClockTarget;
EF:AddButton({ Text = "Teleport to Temple of Time", Func = function()
	task.spawn(function()
		local ok, status = TpTemple();
		if not ok then
			UI.Library:Notify("Temple teleport: " .. tostring(status), 5);
		end;
	end);
end });
EF:AddButton({ Text = "Teleport to Ancient One", Func = function()
	task.spawn(function()
		local ok, status = TpTemple();
		if not ok then
			UI.Library:Notify("Temple teleport: " .. tostring(status), 5);
			return;
		end;
		local root;
		if type(BFFindNpc) == "function" then
			local _, foundRoot = BFFindNpc("Ancient One");
			root = foundRoot;
		end;
		if root then
			_tp(root.CFrame * CFrame.new(0, 0, 4), true);
		else
			UI.Library:Notify("Ancient One is not streamed yet.", 4);
		end;
	end);
end });
EF:AddButton({ Text = "Teleport to Ancient Clock", Func = function()
	task.spawn(function()
		local ok, status = TpTemple();
		if not ok then
			UI.Library:Notify("Temple teleport: " .. tostring(status), 5);
			return;
		end;
		local target = BFAncientClockTarget();
		if target then
			_tp(target, true);
		else
			UI.Library:Notify("Ancient Clock is not streamed yet.", 4);
		end;
	end);
end });
BFRaceDoorTarget = function()
	local data = d:FindFirstChild("Data");
	local raceValue = data and data:FindFirstChild("Race");
	local race = raceValue and tostring(raceValue.Value) or "";
	local map = workspace:FindFirstChild("Map");
	if race == "Draco" then
		local trial = map and map:FindFirstChild("DracoTrial");
		local teleportOut = trial and trial:FindFirstChild("TeleportOut", true);
		local trialDoor = trial and trial:FindFirstChild("TrialDoor");
		local door = trialDoor and trialDoor:FindFirstChild("Door1");
		local meshes = door and door:FindFirstChild("Meshes");
		local target = teleportOut or meshes and meshes:FindFirstChild("caveprops_Cylinder.042") or BFFirstPart(door or trialDoor);
		if target and target:IsA("BasePart") then
			return target;
		end;
		return nil;
	end;
	local mapStash = Q:FindFirstChild("MapStash");
	local temple = map and map:FindFirstChild("Temple of Time") or mapStash and mapStash:FindFirstChild("Temple of Time");
	local corridor = temple and temple:FindFirstChild(race .. "Corridor");
	if corridor then
		local entrance = corridor:FindFirstChild("Entrance", true);
		if entrance and entrance:IsA("BasePart") then
			return entrance;
		end;
		local door = corridor:FindFirstChild("Door");
		local best;
		for _, part in ipairs((door or corridor):GetDescendants()) do
			if part:IsA("BasePart") and part.Name == "trapezoid" and (not best or part.Position.Y < best.Position.Y) then
				best = part;
			end;
		end;
		return best or BFFirstPart(door or corridor);
	end;
	local spawn = temple and temple:FindFirstChild("TeleportSpawn", true);
	if spawn and spawn:IsA("BasePart") then
		return spawn;
	end;
	return BFFirstPart(temple);
end;
getgenv().BFRaceDoorTarget = BFRaceDoorTarget;
EF:AddToggle("BF_Toggle_Auto_Teleport_to_Race_Doors", {
	Text = "Auto Teleport to Race Doors",
	Tooltip = "Enter the Temple through RaceV4Progress, then tween to your race door",
	Default = false,
	Callback = function(Y)
		_G.TPDoor = Y;
		if not Y and UI.RaceDoorStatusLabel then
			UI.RaceDoorStatusLabel:SetText("Race door: idle");
		end;
	end,
});
UI.RaceDoorStatusLabel = EF:AddLabel({ DoesWrap = true, Text = "Race door: idle" });
task.spawn(function()
	while IdleWait(_G.TPDoor, .1) do
		local ok, status = pcall(function()
			if _G.TPDoor then
				local character = d.Character;
				local humanoid = character and character:FindFirstChildOfClass("Humanoid");
				local root = character and character:FindFirstChild("HumanoidRootPart");
				if not humanoid or humanoid.Health <= 0 or not root then
					return "waiting-for-character";
				end;
				local target = BFRaceDoorTarget();
				local race = tostring(BFDataValue("Race") or "");
				if race ~= "Draco" and not BFIsInTemple() then
					local entered, reason = TpTemple();
					return entered and "entered-temple" or reason;
				end;
				target = BFRaceDoorTarget();
				if not target or not target:IsA("BasePart") then
					return "waiting-for-race-door";
				end;
				root = BFCharacterPart();
				if root and (root.Position - target.Position).Magnitude <= 8 then
					return "at-race-door";
				end;
				_tp(target.CFrame, true);
				return "tweening-to-" .. string.lower(race) .. "-door";
			end;
			return "idle";
		end);
		status = ok and status or "error";
		if UI.RaceDoorStatusLabel then
			UI.RaceDoorStatusLabel:SetText("Race door: " .. tostring(status):gsub("%-", " "));
		end;
	end;
end);
EF:AddToggle("BF_Toggle_Auto_Complete_Trial_Race", {
	Text = "Auto Complete Trial Race",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		_G.Complete_Trials = Y;
	end,
});
GetSeaBeastTrial = function()
		if not BFMapNode("FishmanTrial") then
			return nil;
		end;
		local location = BFWorldLocation("Trial of Water");
		FishmanTrial = location or FishmanTrial and FishmanTrial.Parent and FishmanTrial or nil;
		if FishmanTrial and FishmanTrial:IsA("BasePart") then
			local beasts = workspace:FindFirstChild("SeaBeasts");
			for _, beast in next, beasts and beasts:GetChildren() or {} do
				local root = beast:FindFirstChild("HumanoidRootPart");
				local health = beast:FindFirstChild("Health");
				if root and health and health:IsA("ValueBase") and (root.Position - FishmanTrial.Position).Magnitude <= 1500 then
					if health.Value > 0 then
						return beast;
					end;
				end;
			end;
		end;
	end;
UI.TrialEnemyNames = { "Ancient Vampire", "Ancient Zombie" };
task.spawn(function()
	while IdleWait(_G.Complete_Trials, .1) do
		pcall(function()
			if not _G.Complete_Trials then
				return;
			end;
			local race = tostring(BFDataValue("Race") or "");
			if race == "Mink" then
				local ceiling = BFMapNode("MinkTrial", "Ceiling");
				if ceiling and ceiling:IsA("BasePart") then
					notween(ceiling.CFrame * CFrame.new(0, -20, 0));
				end;
			elseif race == "Fishman" then
				local beast = GetSeaBeastTrial();
				if beast then
					local health = beast:FindFirstChild("Health");
					repeat
						task.wait();
						local beastRoot = beast:FindFirstChild("HumanoidRootPart");
						local water = BFMapNode("WaterBase-Plane");
						if not beastRoot or not health or not health.Parent then
							break;
						end;
						_tp(CFrame.new(beastRoot.Position.X, water and water.Position.Y + 300 or beastRoot.Position.Y + 300, beastRoot.Position.Z));
						MousePos = beastRoot.Position;
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
					until not _G.Complete_Trials or not beast.Parent or health.Value <= 0;
				end;
			elseif race == "Cyborg" then
				local floor = BFMapNode("CyborgTrial", "Floor");
				if floor and floor:IsA("BasePart") then
					_tp(floor.CFrame * CFrame.new(0, 500, 0));
				end;
			elseif race == "Skypiea" then
				local finish = BFMapNode("SkyTrial", "Model", "FinishPart");
				if finish and finish:IsA("BasePart") then
					notween(finish.CFrame);
				end;
			elseif race == "Human" or race == "Ghoul" then
				local enemy = GetConnectionEnemies(UI.TrialEnemyNames);
				if enemy then
					repeat
						task.wait();
						f.Kill(enemy, _G.Complete_Trials);
					until not _G.Complete_Trials or not enemy.Parent or not f.Alive(enemy);
				end;
			end;
		end);
	end;
end);
UI.TrialPvpStatus = "idle";
UI.TrialPvpStatusLabel = nil;
function UI.SetTrialPvpStatus(status)
	status = tostring(status or "working");
	if status ~= UI.TrialPvpStatus then
		UI.TrialPvpStatus = status;
		if UI.TrialPvpStatusLabel then
			UI.TrialPvpStatusLabel:SetText("Trial PvP: " .. status:gsub("%-", " "));
		end;
	end;
end;
EF:AddToggle("BF_Toggle_Auto_Kill_Player_After_Trial", {
	Text = "Auto Kill Player After Trial",
	Tooltip = "turn on for kill player after the race trials",
	Default = false,
	Callback = function(Y)
		_G.Defeating = Y;
		if not Y then
			UI.SetTrialPvpStatus("idle");
		end;
	end,
});
UI.TrialPvpStatusLabel = EF:AddLabel({ DoesWrap = true, Text = "Trial PvP: " .. UI.TrialPvpStatus:gsub("%-", " ") });
task.spawn(function()
	while IdleWait(_G.Defeating, .1) do
		if _G.Defeating then
			local ok = pcall(function()
				local characters = workspace:FindFirstChild("Characters");
				local ownRoot = BFCharacterPart();
				if not characters or not ownRoot then
					UI.SetTrialPvpStatus("waiting-for-characters");
					return;
				end;
				local target;
				local nearest = 250;
				for _, character in ipairs(characters:GetChildren()) do
					local targetRoot = character:FindFirstChild("HumanoidRootPart");
					if character.Name ~= d.Name and targetRoot and f.Alive(character) then
						local distance = (ownRoot.Position - targetRoot.Position).Magnitude;
						if distance <= nearest then
							nearest = distance;
							target = character;
						end;
					end;
				end;
				if not target then
					UI.SetTrialPvpStatus("waiting-for-opponent");
					return;
				end;
				UI.SetTrialPvpStatus("attacking");
				repeat
					task.wait(.1);
					local targetRoot = target:FindFirstChild("HumanoidRootPart");
					if not targetRoot then
						break;
					end;
					EquipWeapon(EnsureWeapon());
					MousePos = targetRoot.Position;
					_tp(targetRoot.CFrame * CFrame.new(0, 0, 15));
					BFTouchAttack();
					ExtendSimulationRadius();
				until not _G.Defeating or not target.Parent or not f.Alive(target);
			end);
			if not ok then
				UI.SetTrialPvpStatus("error");
			end;
		end;
	end;
end);
local OF = UI.Sections["Dojo Quest & Draco Race"];
OF:AddToggle("BF_Toggle_Auto_Dojo_Trainer", {
	Text = "Auto Dojo Trainer",
	Tooltip = "Automate solo belt quests and pause with guidance for social steps",
	Default = false,
	Callback = function(Y)
		_G.Dojoo = Y;
		if Y then
			UI.DojoManualBelt = nil;
			UI.DojoNextRequestAt = 0;
			UI.DojoNextReadAt = 0;
			UI.DojoQuestCache = nil;
			UI.DojoQuestCacheAt = 0;
			UI.DojoClaimReady = false;
		end;
		if not Y then
			UI.ReleaseManagedOwner("Dojo");
			if UI.DojoStatus ~= "complete" then
				UI.SetDojoStatus("idle");
			end;
		end;
	end,
});
UI.DojoStatus = "idle";
UI.DojoNextRequestAt = 0;
UI.DojoNextReadAt = 0;
UI.DojoQuestCache = nil;
UI.DojoQuestCacheAt = 0;
UI.DojoClaimReady = false;
UI.DojoStatusLabel = OF:AddLabel({ DoesWrap = true, Text = "Dojo: idle" });
function UI.SetDojoStatus(status)
	status = tostring(status or "working");
	if status ~= UI.DojoStatus then
		UI.DojoStatus = status;
		UI.DojoStatusLabel:SetText("Dojo: " .. status:gsub("%-", " "));
	end;
end;
BFParseDojoQuest = function(response)
	local result = {
		Belt = nil,
		QuestName = nil,
		Goal = nil,
		Progress = nil,
		Completed = false,
		Timeout = false,
	};
	if type(response) ~= "table" then
		return result;
	end;
	local quest = type(response.Quest) == "table" and response.Quest or response;
	result.Belt = quest.BeltName or response.BeltName;
	result.QuestName = quest.QuestName or response.QuestName;
	result.Goal = tonumber(quest.Goal or response.Goal);
	result.Progress = tonumber(quest.Progress or response.Progress);
	result.Timeout = response.Timeout ~= nil and response.Timeout ~= false or quest.Timeout ~= nil and quest.Timeout ~= false;
	result.Completed = response.Completed ~= nil and response.Completed ~= false or quest.Completed ~= nil and quest.Completed ~= false;
	if result.Goal and result.Progress and result.Progress >= result.Goal then
		result.Completed = true;
	end;
	return result;
end;
BFReadDojoQuest = function()
	local now = os.clock();
	if now < UI.DojoNextReadAt then
		if UI.DojoQuestCache then
			return UI.DojoQuestCache, true;
		end;
		return BFParseDojoQuest(nil), true;
	end;
	UI.DojoNextReadAt = now + 1;
	local response = NetInvoke("RF/InteractDragonQuest", { NPC = "Dojo Trainer", Command = "RequestQuest" });
	local state = BFParseDojoQuest(response);
	if state.Belt or state.Completed or state.Timeout then
		UI.DojoQuestCache = state;
		UI.DojoQuestCacheAt = now;
		return state, false;
	end;
	if UI.DojoQuestCache and os.clock() - UI.DojoQuestCacheAt <= 15 then
		return UI.DojoQuestCache, true;
	end;
	return state, true;
end;
function printBeltName(response)
	return BFParseDojoQuest(response).Belt;
end;
DojoQuestBelt = function()
	local state, stale = BFReadDojoQuest();
	return state.Belt, state, stale;
end;
BFSetDojoProgressStatus = function(state, stale)
	local belt = string.lower(tostring(state.Belt or "unknown"));
	if state.Goal and state.Progress then
		UI.SetDojoStatus(string.format("belt-%s-progress-%d-of-%d", belt, state.Progress, state.Goal));
	elseif stale then
		UI.SetDojoStatus("belt-" .. belt .. "-waiting-for-progress");
	else
		UI.SetDojoStatus("belt-" .. belt);
	end;
end;
BFWaitDojoBelt = function(belt, step)
	repeat
		if step then
			step();
		end;
		task.wait(1);
		local state, stale = BFReadDojoQuest();
		if state.Completed and (not state.Belt or state.Belt == belt) then
			UI.DojoClaimReady = true;
			return "complete";
		end;
		if state.Belt and state.Belt ~= belt then
			return "changed";
		end;
		if state.Belt == belt then
			BFSetDojoProgressStatus(state, stale);
		elseif state.Timeout then
			UI.SetDojoStatus("quest-cooldown");
		else
			UI.SetDojoStatus("belt-" .. string.lower(tostring(belt)) .. "-waiting-for-response");
		end;
	until not _G.Dojoo;
	return "stopped";
end;
BFDojoTrainerCFrame = function()
	for _, container in ipairs({ workspace:FindFirstChild("NPCs"), Q:FindFirstChild("NPCs") }) do
		local npc = container and container:FindFirstChild("Dojo Trainer");
		local root = npc and (npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart or npc:FindFirstChildWhichIsA("BasePart", true));
		if root then
			return root.CFrame, "runtime";
		end;
	end;
	return CFrame.new(5865.0234375, 1208.3154296875, 871.15185546875), "fallback";
end;
getgenv().BFDojoTrainerCFrame = BFDojoTrainerCFrame;
task.spawn(function()
	while IdleWait(_G.Dojoo, .25) do
		if _G.Dojoo then
			local ok = pcall(function()
				if BFHasItemLike("dojo belt (black)") then
					UI.SetDojoStatus("complete");
					UI.DisableToggle("BF_Toggle_Auto_Dojo_Trainer");
					return;
				end;
				if UI.DojoClaimReady then
					UI.ReleaseManagedOwner("Dojo");
					local trainer = BFDojoTrainerCFrame();
					if not BFMoveNear(trainer, 10) then
						UI.SetDojoStatus("moving-to-trainer-to-claim");
						return;
					end;
					local now = os.clock();
					if now >= UI.DojoNextRequestAt then
						UI.DojoNextRequestAt = now + 3;
						UI.SetDojoStatus("claiming-completed-quest");
						NetInvoke("RF/InteractDragonQuest", { NPC = "Dojo Trainer", Command = "ClaimQuest" });
						UI.DojoClaimReady = false;
						UI.DojoQuestCache = nil;
						UI.DojoQuestCacheAt = 0;
						UI.DojoNextReadAt = 0;
					end;
					return;
				end;
				local state, stale = BFReadDojoQuest();
				if state.Completed then
					UI.DojoClaimReady = true;
					UI.ReleaseManagedOwner("Dojo");
					UI.SetDojoStatus("quest-complete-ready-to-claim");
					return;
				end;
				local belt = state.Belt;
				if not belt then
					UI.ReleaseManagedOwner("Dojo");
					if state.Timeout then
						UI.SetDojoStatus("quest-cooldown");
						return;
					end;
					local trainer = BFDojoTrainerCFrame();
					if not BFMoveNear(trainer, 10) then
						UI.SetDojoStatus("moving-to-trainer");
						return;
					end;
					local now = os.clock();
					if now >= UI.DojoNextRequestAt then
						UI.DojoNextRequestAt = now + 3;
						state, stale = BFReadDojoQuest();
						belt = state.Belt;
					end;
					if not belt then
						UI.SetDojoStatus(stale and "waiting-for-quest-response" or "waiting-or-cooldown");
						return;
					end;
				end;
				BFSetDojoProgressStatus(state, stale);
				if belt == "White" then
					local enemy = GetConnectionEnemies("Skull Slayer");
					if enemy then
						repeat
							task.wait();
							f.Kill(enemy, _G.Dojoo);
						until not _G.Dojoo or not enemy.Parent or not f.Alive(enemy);
					else
						BFMoveNear(CFrame.new(-16759.58984375, 71.283767700195, 1595.3399658203), 30);
					end;
				elseif belt == "Yellow" then
					UI.DriveManagedFlag("Dojo", "SeaBeast1");
					UI.DriveManagedFlag("Dojo", "TerrorShark");
					UI.DriveManagedFlag("Dojo", "Shark");
					UI.DriveManagedFlag("Dojo", "Piranha");
					UI.DriveManagedFlag("Dojo", "MobCrew");
					UI.DriveManagedFlag("Dojo", "FishBoat");
					UI.DriveManagedFlag("Dojo", "SailBoats");
					BFWaitDojoBelt(belt);
				elseif belt == "Green" then
					UI.DriveManagedFlag("Dojo", "SailBoats");
					BFWaitDojoBelt(belt);
				elseif belt == "Purple" then
					UI.DriveManagedFlag("Dojo", "FarmEliteHunt");
					BFWaitDojoBelt(belt);
				elseif belt == "Red" then
					UI.DriveManagedFlag("Dojo", "SailBoats");
					UI.DriveManagedFlag("Dojo", "FishBoat");
					BFWaitDojoBelt(belt);
				elseif belt == "Black" then
					BFWaitDojoBelt(belt, function()
						local island = BFMapNode("PrehistoricIsland");
						local worldOrigin = workspace:FindFirstChild("_WorldOrigin");
						local locations = worldOrigin and worldOrigin:FindFirstChild("Locations");
						if island or locations and locations:FindFirstChild("Prehistoric Island") then
							UI.DriveManagedFlag("Dojo", "Prehis_Find");
							local activation = island and island:FindFirstChild("ActivationPrompt", true);
							if activation and activation:FindFirstChildWhichIsA("ProximityPrompt", true) then
								UI.ReleaseManagedFlag("Dojo", "Prehis_Skills");
							else
								UI.DriveManagedFlag("Dojo", "Prehis_Skills");
								UI.ReleaseManagedFlag("Dojo", "Prehis_Find");
							end;
						else
							UI.DriveManagedFlag("Dojo", "Prehis_Find");
							UI.ReleaseManagedFlag("Dojo", "Prehis_Skills");
						end;
					end);
				elseif belt == "Orange" or belt == "Blue" then
					local status = belt == "Orange" and "manual-trade-required" or "manual-fruit-exchange-required";
					UI.SetDojoStatus(status);
					if UI.DojoManualBelt ~= belt then
						UI.DojoManualBelt = belt;
						local message = belt == "Orange" and "Orange belt needs a successful player trade." or "Blue belt needs a two-player fruit exchange.";
						UI.Library:Notify(message, 8);
					end;
				end;
			end);
			if not ok then
				UI.SetDojoStatus("error");
			end;
			UI.ReleaseManagedOwner("Dojo");
		end;
	end;
	UI.ReleaseManagedOwner("Dojo");
end);
UI.DragonHunterStatus = "idle";
UI.DragonHunterStatusLabel = nil;
UI.DragonHunterNextQuestAt = 0;
UI.DragonHunterQuestCache = { Active = false };
function UI.SetDragonHunterStatus(status)
	status = tostring(status or "working");
	if status ~= UI.DragonHunterStatus then
		UI.DragonHunterStatus = status;
		if UI.DragonHunterStatusLabel then
			UI.DragonHunterStatusLabel:SetText("Dragon Hunter: " .. status:gsub("%-", " "));
		end;
	end;
end;
OF:AddToggle("BF_Toggle_Auto_Dragon_Hunter", {
	Text = "Auto Dragon Hunter",
	Tooltip = "turn on for farm blaze ember + auto collect blaze ember",
	Default = false,
	Callback = function(Y)
		UI.SetManagedUserFlag("FarmBlazeEM", Y);
		if Y then
			UI.DragonHunterNextQuestAt = 0;
			UI.DragonHunterQuestCache = { Active = false };
		else
			UI.SetDragonHunterStatus("idle");
		end;
	end,
});
UI.DragonHunterStatusLabel = OF:AddLabel({ DoesWrap = true, Text = "Dragon Hunter: " .. UI.DragonHunterStatus:gsub("%-", " ") });
checkQuesta = function()
		local now = os.clock();
		local cached = UI.DragonHunterQuestCache;
		if now < UI.DragonHunterNextQuestAt then
			return cached.Active, cached.Target, cached.Amount, cached.Kind;
		end;
		UI.DragonHunterNextQuestAt = now + 2;
		NetInvoke("RF/DragonHunter", { Context = "RequestQuest" });
		local response = NetInvoke("RF/DragonHunter", { Context = "Check" });
		local text = type(response) == "table" and tostring(response.Text or "") or "";
		local active = text ~= "";
		local amount = tonumber(text:match("(%d+)"));
		local target;
		local kind;
		if string.find(text, "Defeat", 1, true) then
			kind = 1;
			for _, name in ipairs({ "Hydra Enforcer", "Venomous Assailant" }) do
				if string.find(text, name, 1, true) then
					target = name;
					break;
				end;
			end;
		elseif string.find(text, "Destroy", 1, true) then
			kind = 2;
			amount = amount or 10;
		end;
		UI.DragonHunterQuestCache = { Active = active, Target = target, Amount = amount, Kind = kind };
		return active, target, amount, kind;
	end;
BackTODoJo = function()
		local playerGui = d:FindFirstChildOfClass("PlayerGui");
		local notifications = playerGui and playerGui:FindFirstChild("Notifications");
		if not notifications then
			return false;
		end;
		for _, notification in pairs(notifications:GetChildren()) do
			if notification.Name == "NotificationTemplate" then
				if string.find(tostring(notification.Text), "Head back to the Dojo to complete more tasks", 1, true) then
					return true;
				end;
			end;
		end;
		return false;
	end;
task.spawn(function()
	while IdleWait(_G.FarmBlazeEM, .25) do
		if _G.FarmBlazeEM then
			local ok = pcall(function()
				if not World3 then
					UI.SetDragonHunterStatus("wrong-world");
					return;
				end;
				local questActive, targetName, _, kind = checkQuesta();
				local returnToDojo = BackTODoJo();
				if questActive and not returnToDojo then
					if kind == 1 and targetName then
						local enemy = GetConnectionEnemies(targetName);
						if enemy then
							UI.SetDragonHunterStatus("fighting-" .. string.lower(targetName):gsub(" ", "-"));
							repeat
								task.wait();
								f.Kill(enemy, _G.FarmBlazeEM);
							until not _G.FarmBlazeEM or not enemy.Parent or not f.Alive(enemy) or BackTODoJo();
						else
							UI.SetDragonHunterStatus("waiting-for-quest-enemy");
							BFMoveNear(CFrame.new(4620.6157226562, 1002.2954711914, 399.08688354492), 30);
						end;
					elseif kind == 2 then
						local island = BFMapNode("Waterfall", "IslandModel");
						local bamboo = island and island:FindFirstChild("Meshes/bambootree", true);
						if bamboo and bamboo:IsA("BasePart") then
							UI.SetDragonHunterStatus("destroying-bamboo");
							repeat
								task.wait(.1);
								BFMoveNear(bamboo.CFrame * CFrame.new(4, 0, 0), 8);
								local root = BFCharacterPart();
								if root and (bamboo.Position - root.Position).Magnitude <= 200 then
									MousePos = bamboo.Position;
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
							until not _G.FarmBlazeEM or BackTODoJo();
						else
							UI.SetDragonHunterStatus("waiting-for-bamboo");
						end;
					else
						UI.SetDragonHunterStatus("waiting-for-quest-state");
					end;
				else
					UI.SetDragonHunterStatus(returnToDojo and "returning-to-dragon-wizard" or "requesting-quest");
					BFMoveNear(CFrame.new(5813, 1208, 884), 10);
				end;
			end);
			if not ok then
				UI.SetDragonHunterStatus("error");
			end;
		end;
	end;
end);
task.spawn(function()
	while IdleWait(_G.FarmBlazeEM, .1) do
		if _G.FarmBlazeEM then
			pcall(function()
				local ember = FindNamed("EmberTemplate");
				local emberPart = ember and ember:FindFirstChild("Part");
				local root = i and i:FindFirstChild("HumanoidRootPart");
				if emberPart and root then
					root.CFrame = emberPart.CFrame;
				end;
			end);
		end;
	end;
end);
local fF = UI.Sections["Draco Trial"];
GetQuestDracoLevel = function()
		local Y = { [1] = { NPC = "Dragon Wizard", Command = "Upgrade" } };
		return NetInvoke("RF/InteractDragonQuest", unpack(Y));
	end;
UI.DracoUpgradeStatus = "idle";
UI.DracoUpgradeStatusLabel = nil;
UI.DracoUpgradeNextCheckAt = 0;
UI.DracoUpgradeResult = nil;
function UI.SetDracoUpgradeStatus(status)
	status = tostring(status or "working");
	if status ~= UI.DracoUpgradeStatus then
		UI.DracoUpgradeStatus = status;
		if UI.DracoUpgradeStatusLabel then
			UI.DracoUpgradeStatusLabel:SetText("Draco upgrade: " .. status:gsub("%-", " "));
		end;
	end;
end;
fF:AddToggle("BF_Toggle_Tween_To_Upgrade_Droco_Trial", {
	Text = "Tween To Upgrade Draco Trial",
	Tooltip = "Approach the Dragon Wizard and retry the current Draco upgrade step",
	Default = false,
	Callback = function(Y)
		_G.UPGDrago = Y;
		if Y then
			UI.DracoUpgradeNextCheckAt = 0;
			UI.DracoUpgradeResult = nil;
		else
			UI.SetDracoUpgradeStatus("idle");
		end;
	end,
});
UI.DracoUpgradeStatusLabel = fF:AddLabel({ DoesWrap = true, Text = "Draco upgrade: " .. UI.DracoUpgradeStatus:gsub("%-", " ") });
task.spawn(function()
	while IdleWait(_G.UPGDrago, .25) do
		if _G.UPGDrago then
			local ok = pcall(function()
				if not World3 then
					UI.SetDracoUpgradeStatus("wrong-world");
					return;
				end;
				local now = os.clock();
				if now >= UI.DracoUpgradeNextCheckAt then
					UI.DracoUpgradeNextCheckAt = now + 2;
					UI.DracoUpgradeResult = GetQuestDracoLevel();
				end;
				if UI.DracoUpgradeResult == nil then
					UI.SetDracoUpgradeStatus("waiting-for-response");
					return;
				end;
				if UI.DracoUpgradeResult ~= true then
					UI.SetDracoUpgradeStatus("requirements-not-met");
					return;
				end;
				local target = CFrame.new(5814.4272460938, 1208.3267822266, 884.57855224609);
				if BFMoveNear(target, 8) then
					UI.SetDracoUpgradeStatus("requesting-upgrade");
				else
					UI.SetDracoUpgradeStatus("moving-to-dragon-wizard");
				end;
			end);
			if not ok then
				UI.SetDracoUpgradeStatus("error");
			end;
		end;
	end;
end);
fF:AddToggle("BF_Toggle_Auto_Drago_V1", {
	Text = "Auto Draco (V1)",
	Tooltip = "turn on for auto quest1 auto prehistoric event + collect dragon eggs",
	Default = false,
	Callback = function(Y)
		_G.DragoV1 = Y;
		if not Y then
			UI.ReleaseManagedOwner("DracoV1");
		end;
	end,
});
task.spawn(function()
	while IdleWait(_G.DragoV1, T) do
		pcall(function()
			if _G.DragoV1 then
				if GetM("Dragon Egg") <= 0 then
					UI.DriveManagedFlag("DracoV1", "Prehis_Find");
					UI.DriveManagedFlag("DracoV1", "Prehis_Skills");
					UI.DriveManagedFlag("DracoV1", "Prehis_DE");
					repeat
						task.wait();
					until not _G.DragoV1 or GetM("Dragon Egg") >= 1;
				end;
			end;
		end);
		UI.ReleaseManagedOwner("DracoV1");
	end;
	UI.ReleaseManagedOwner("DracoV1");
end);
fF:AddToggle("BF_Toggle_Auto_Drago_V2", {
	Text = "Auto Draco (V2)",
	Tooltip = "turn on for auto kill Forest Pirate & Collect fireflower",
	Default = false,
	Callback = function(Y)
		_G.AutoFireFlowers = Y;
	end,
});
task.spawn(function()
	while IdleWait(_G.AutoFireFlowers, T) do
		if _G.AutoFireFlowers then
			pcall(function()
				local flowers = workspace:FindFirstChild("FireFlowers");
				local enemy = GetConnectionEnemies("Forest Pirate");
				if enemy and not flowers then
					repeat
						task.wait();
						f.Kill(enemy, _G.AutoFireFlowers);
						flowers = workspace:FindFirstChild("FireFlowers");
					until not _G.AutoFireFlowers or not enemy.Parent or not f.Alive(enemy) or flowers;
				elseif not flowers then
					_tp(CFrame.new(-13206.452148438, 425.89199829102, -7964.5537109375));
				end;
				flowers = workspace:FindFirstChild("FireFlowers");
				if flowers then
					local character = d.Character;
					local root = character and character:FindFirstChild("HumanoidRootPart");
					if not root then
						return;
					end;
					for _, flower in pairs(flowers:GetChildren()) do
						if flower:IsA("Model") and flower.PrimaryPart then
							local position = flower.PrimaryPart.Position;
							local distance = (position - root.Position).Magnitude;
							if distance <= 100 then
								K:SendKeyEvent(true, "E", false, game);
								task.wait(1.5);
								K:SendKeyEvent(false, "E", false, game);
							else
								_tp(CFrame.new(position));
							end;
						end;
					end;
				end;
			end);
		end;
	end;
end);
fF:AddToggle("BF_Toggle_Auto_Drago_V3", {
	Text = "Auto Draco (V3)",
	Tooltip = "turn on for sea event kill terror shark",
	Default = false,
	Callback = function(Y)
		_G.DragoV3 = Y;
		if not Y then
			UI.ReleaseManagedOwner("DracoV3");
		end;
	end,
});
task.spawn(function()
	while IdleWait(_G.DragoV3, T) do
		pcall(function()
			if _G.DragoV3 then
				UI.DriveManagedValue("DracoV3", "DangerSc", "Lv Infinite");
				UI.DriveManagedFlag("DracoV3", "SailBoats");
				UI.DriveManagedFlag("DracoV3", "TerrorShark");
				repeat
					task.wait();
				until not _G.DragoV3;
			end;
		end);
		UI.ReleaseManagedOwner("DracoV3");
	end;
	UI.ReleaseManagedOwner("DracoV3");
end);
fF:AddToggle("BF_Toggle_Auto_Relic_Drago_Trial_Beta", {
	Text = "Auto Relic Draco Trial [Beta]",
	Tooltip = "turn on for auto trial v4 you have to COLLECT RELIC by your self",
	Default = false,
	Callback = function(Y)
		_G.Relic123 = Y;
	end,
});
task.spawn(function()
	while IdleWait(_G.Relic123, T) do
		if _G.Relic123 then
			pcall(function()
				if BFMapNode("DracoTrial") then
					local remotes = Q:FindFirstChild("Remotes");
					local trialRemote = remotes and remotes:FindFirstChild("DracoTrial");
					if trialRemote then
						pcall(trialRemote.InvokeServer, trialRemote);
					end;
					task.wait(.5);
					local stops = {
						CFrame.new(-39934.9765625, 10685.359375, 22999.34375),
						CFrame.new(-40511.25390625, 9376.4013671875, 23458.37890625),
						CFrame.new(-39914.65625, 10685.384765625, 23000.177734375),
						CFrame.new(-40045.83203125, 9376.3984375, 22791.287109375),
						CFrame.new(-39908.5, 10685.405273438, 22990.04296875),
						CFrame.new(-39609.5, 9376.400390625, 23472.94335975),
					};
					for index, target in ipairs(stops) do
						repeat
							task.wait();
						until not _G.Relic123 or BFMoveNear(target, 8);
						if not _G.Relic123 then
							break;
						end;
						if index == 2 or index == 4 then
							task.wait(2.5);
						end;
					end;
				else
					local trialTeleport = BFMapNode("PrehistoricIsland", "TrialTeleport");
					if trialTeleport and trialTeleport:IsA("BasePart") then
						_tp(trialTeleport.CFrame);
					end;
				end;
			end);
		end;
	end;
end);
fF:AddToggle("BF_Toggle_Auto_Train_Drago_v4", {
	Text = "Auto Train Draco V4",
	Tooltip = "Turn on to train Draco race V4 and auto-upgrade its tier",
	Default = false,
	Callback = function(Y)
		_G.TrainDrago = Y;
	end,
});
task.spawn(function()
	while IdleWait(_G.TrainDrago, T) do
		pcall(function()
			if _G.TrainDrago then
				local character = d.Character;
				local raceEnergy = character and character:FindFirstChild("RaceEnergy");
				local transformed = character and character:FindFirstChild("RaceTransformed");
				if not character or not raceEnergy or not transformed then
					return;
				end;
				if raceEnergy.Value == 1 then
					local now = os.clock();
					if now >= BFRaceUpgradeNextAt.Draco then
						BFRaceUpgradeNextAt.Draco = now + 2;
						K:SendKeyEvent(true, "Y", false, game);
						task.wait(.1);
						K:SendKeyEvent(false, "Y", false, game);
						BFComm("UpgradeRace", "Buy", 2);
					end;
					_tp(CFrame.new(4620.6157226562, 1002.2954711914, 399.08688354492));
				elseif transformed.Value == false then
					local enemy = GetConnectionEnemies({ "Venomous Assailant", "Hydra Enforcer" });
					if enemy then
						repeat
							task.wait();
							f.Kill(enemy, _G.TrainDrago);
						until not _G.TrainDrago or not enemy.Parent or not f.Alive(enemy);
					else
						_tp(CFrame.new(4620.6157226562, 1002.2954711914, 399.08688354492));
					end;
				end;
			end;
		end);
	end;
end);
fF:AddToggle("BF_Toggle_Tween_to_Drago_Trials", {
	Text = "Tween to Draco Trials",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		_G.TpDrago_Prehis = Y;
	end,
});
task.spawn(function()
	while IdleWait(_G.TpDrago_Prehis, T) do
		if _G.TpDrago_Prehis then
			pcall(function()
				local trialTeleport = BFMapNode("PrehistoricIsland", "TrialTeleport");
				if trialTeleport and trialTeleport:IsA("BasePart") then
					_tp(trialTeleport.CFrame);
				end;
			end);
		end;
	end;
end);
UI.DracoRaceStatus = "idle";
UI.DracoRaceStatusLabel = nil;
UI.DracoRaceNextRequestAt = 0;
function UI.SetDracoRaceStatus(status)
	status = tostring(status or "working");
	if status ~= UI.DracoRaceStatus then
		UI.DracoRaceStatus = status;
		if UI.DracoRaceStatusLabel then
			UI.DracoRaceStatusLabel:SetText("Draco race: " .. status:gsub("%-", " "));
		end;
	end;
end;
fF:AddToggle("BF_Toggle_Swap_Drago_Race", {
	Text = "Swap Draco Race",
	Tooltip = "Change the current race to Draco and stop after replication confirms it",
	Default = false,
	Callback = function(Y)
		_G.BuyDrago = Y;
		if Y then
			UI.DracoRaceNextRequestAt = 0;
		elseif UI.DracoRaceStatus ~= "complete" then
			UI.SetDracoRaceStatus("idle");
		end;
	end,
});
UI.DracoRaceStatusLabel = fF:AddLabel({ DoesWrap = true, Text = "Draco race: " .. UI.DracoRaceStatus:gsub("%-", " ") });
task.spawn(function()
	while IdleWait(_G.BuyDrago, .25) do
		if _G.BuyDrago then
			local ok = pcall(function()
				if tostring(BFDataValue("Race") or "") == "Draco" then
					UI.SetDracoRaceStatus("complete");
					UI.DisableToggle("BF_Toggle_Swap_Drago_Race");
					return;
				end;
				if not World3 then
					UI.SetDracoRaceStatus("wrong-world");
					return;
				end;
				local target = CFrame.new(5814.4272460938, 1208.3267822266, 884.57855224609);
				if not BFMoveNear(target, 8) then
					UI.SetDracoRaceStatus("moving-to-dragon-wizard");
					return;
				end;
				local now = os.clock();
				if now >= UI.DracoRaceNextRequestAt then
					UI.DracoRaceNextRequestAt = now + 2;
					UI.SetDracoRaceStatus("requesting-race-change");
					NetInvoke("RF/InteractDragonQuest", { NPC = "Dragon Wizard", Command = "DragonRace" });
				end;
			end);
			if not ok then
				UI.SetDracoRaceStatus("error");
			end;
		end;
	end;
end);
fF:AddToggle("BF_Toggle_Upgrade_Dragon_Talon_With_Uzoth", {
	Text = "Upgrade Dragon Talon With Uzoth",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		_G.DT_Uzoth = Y;
	end,
});
BFUzothUpgradeNextAt = 0;
task.spawn(function()
	while IdleWait(_G.DT_Uzoth, T) do
		if _G.DT_Uzoth then
			pcall(function()
				local target = CFrame.new(5661.89014, 1211.31909, 864.836731, .811413169, -1.36805838e-08, -0.584473014, 4.75227395e-08, 1, 4.25682458e-08, .584473014, -6.23161966e-08, .811413169);
				local character = d.Character;
				local root = character and character:FindFirstChild("HumanoidRootPart");
				if not root then
					return;
				end;
				_tp(target);
				local now = os.clock();
				if (target.Position - root.Position).Magnitude <= 25 and now >= BFUzothUpgradeNextAt then
					BFUzothUpgradeNextAt = now + 2;
					NetInvoke("RF/InteractDragonQuest", { NPC = "Uzoth", Command = "Upgrade" });
				end;
			end);
		end;
	end;
end);
local sF = UI.Sections["Volcanic Magnet"];
sF:AddToggle("BF_Toggle_Auto_Craft_Volcanic_Magnet", {
	Text = "Auto Craft Volcanic Magnet",
	Tooltip = "turn on for auto farm material and craft volcanic magnet & stop when you have 1 volcanic magnet",
	Default = false,
	Callback = function(Y)
		_G.CraftVM = Y;
		if not Y then
			UI.ReleaseManagedOwner("CraftVM");
		end;
	end,
});
sF:AddButton({ Text = "Craft Volcanic Magnet", Func = function()
		BFComm("CraftItem", "Craft", "Volcanic Magnet");
	end });
BFVolcanicMagnetNextCraft = 0;
task.spawn(function()
	while IdleWait(_G.CraftVM, T) do
		pcall(function()
			if _G.CraftVM then
				if GetM("Volcanic Magnet") >= 1 then
					UI.DisableToggle("BF_Toggle_Auto_Craft_Volcanic_Magnet");
					return;
				else
					if GetM("Scrap Metal") >= 10 and GetM("Blaze Ember") >= 15 then
						local now = os.clock();
						if now >= BFVolcanicMagnetNextCraft then
							BFVolcanicMagnetNextCraft = now + 2;
							BFComm("CraftItem", "Craft", "Volcanic Magnet");
						end;
					elseif GetM("Scrap Metal") < 10 then
						local Y = GetConnectionEnemies("Forest Pirate");
						if Y then
							repeat
								task.wait();
								f.Kill(Y, _G.CraftVM);
							until not _G.CraftVM or not Y.Parent or not f.Alive(Y) or GetM("Scrap Metal") >= 10;
						else
							_tp(CFrame.new(-13206.452148438, 425.89199829102, -7964.5537109375));
						end;
					elseif GetM("Blaze Ember") < 15 then
						UI.DriveManagedFlag("CraftVM", "FarmBlazeEM");
						repeat
							task.wait();
						until not _G.CraftVM or GetM("Blaze Ember") >= 15;
					end;
				end;
			end;
		end);
		UI.ReleaseManagedOwner("CraftVM");
	end;
	UI.ReleaseManagedOwner("CraftVM");
end);
local xF = UI.Sections["Prehistoric Island"];
local JF = xF:AddLabel({ DoesWrap = true, Text = " Prehistoric Island Status " });
task.spawn(function()
	while UI.LabelWait(2) do
		local worldOrigin = workspace:FindFirstChild("_WorldOrigin");
		local locations = worldOrigin and worldOrigin:FindFirstChild("Locations");
		if BFMapNode("PrehistoricIsland") or locations and locations:FindFirstChild("Prehistoric Island") then
			JF:SetText(" Prehistoric Island : True");
		else
			JF:SetText(" Prehistoric Island : False");
		end;
	end;
end);
xF:AddToggle("BF_Toggle_Auto_Find_Prehistoric_Island", {
	Text = "Auto Find Prehistoric Island",
	Tooltip = "turn on for finding & tween & start prehistoric island",
	Default = false,
	Callback = function(Y)
		UI.SetManagedUserFlag("Prehis_Find", Y);
	end,
});
local Yq = nil;
task.spawn(function()
	while IdleWait(_G.Prehis_Find) do
		if _G.Prehis_Find then
			pcall(function()
				local character = d.Character;
				local humanoid = character and character:FindFirstChildOfClass("Humanoid");
				local root = character and character:FindFirstChild("HumanoidRootPart");
				local worldOrigin = workspace:FindFirstChild("_WorldOrigin");
				local locations = worldOrigin and worldOrigin:FindFirstChild("Locations");
				local location = locations and locations:FindFirstChild("Prehistoric Island", true);
				if not humanoid or not root then
					return;
				end;
				if not location then
					local boat = CheckBoat();
					if not boat then
						local dealer = CFrame.new(-16927.451, 9.086, 433.864);
						TeleportToTarget(dealer);
						if (dealer.Position - root.Position).Magnitude <= 10 then
							BFRequestSelectedBoat();
						end;
					else
						local seat = BFBoatSeat(boat);
						if not seat then
							return;
						end;
						if not humanoid.Sit then
							_tp(seat.CFrame * CFrame.new(0, 1, 0));
						else
							repeat
								task.wait();
								local target = CFrame.new(-10000000, 31, 37016.25);
								if CheckEnemiesBoat() or CheckTerrorShark() or CheckPirateGrandBrigade() then
									_tp(CFrame.new(-10000000, 150, 37016.25));
								else
									_tp(target);
								end;
								location = locations and locations:FindFirstChild("Prehistoric Island", true);
							until not _G.Prehis_Find or location or not humanoid.Sit;
							humanoid.Sit = false;
						end;
					end;
				else
					if location:IsA("BasePart") and (location.Position - root.Position).Magnitude >= 2000 then
						_tp(location.CFrame);
					end;
					local island = BFMapNode("PrehistoricIsland");
					local activation = island and island:FindFirstChild("ActivationPrompt", true);
					local prompt = activation and activation:FindFirstChildWhichIsA("ProximityPrompt", true);
					if activation and activation:IsA("BasePart") and prompt then
						if d:DistanceFromCharacter(activation.Position) <= 150 then
							if type(fireproximityprompt) == "function" then
								pcall(fireproximityprompt, prompt, math.huge);
							end;
							K:SendKeyEvent(true, "E", false, game);
							task.wait(1.5);
							K:SendKeyEvent(false, "E", false, game);
						end;
						_tp(activation.CFrame);
					end;
				end;
			end);
		end;
	end;
end);
xF:AddToggle("BF_Toggle_Auto_Patch_Prehistoric_Event", {
	Text = "Auto Patch Prehistoric Event",
	Tooltip = "turn on for auto patch volcano + kill aura lava golems + auto remove lava",
	Default = false,
	Callback = function(Y)
		UI.SetManagedUserFlag("Prehis_Skills", Y);
	end,
});
task.spawn(function()
	while IdleWait(_G.Prehis_Skills) do
		if _G.Prehis_Skills then
			pcall(function()
				local island = BFMapNode("PrehistoricIsland");
				if not island then
					return;
				end;
				local trial = island:FindFirstChild("TrialTeleport");
				for _, object in pairs(island:GetDescendants()) do
					if object:IsA("BasePart") and object.Name:lower():find("lava", 1, true) then
						object:Destroy();
					elseif object.Name == "TouchInterest" and not (trial and object:IsDescendantOf(trial)) then
						local parent = object.Parent;
						if parent then
							parent:Destroy();
						end;
					end;
				end;
				local interior = island:FindFirstChild("InteriorLava", true);
				if interior then
					interior:Destroy();
				end;
			end);
		end;
	end;
end);
task.spawn(function()
	while IdleWait(_G.Prehis_Skills) do
		pcall(function()
			if _G.Prehis_Skills then
				local enemy = GetConnectionEnemies("Lava Golem");
				if enemy then
						repeat
							task.wait();
							f.Kill(enemy, _G.Prehis_Skills);
							local humanoid = enemy:FindFirstChildOfClass("Humanoid");
							if humanoid then
								humanoid:ChangeState(15);
							end;
						until not _G.Prehis_Skills or not enemy.Parent or not f.Alive(enemy);
				end;
				local rocks = BFMapNode("PrehistoricIsland", "Core", "VolcanoRocks");
				if not rocks then
					return;
				end;
				for _, rock in pairs(rocks:GetChildren()) do
					local layer = rock:FindFirstChild("VFXLayer");
					local at0 = layer and layer:FindFirstChild("At0");
					local glow = at0 and at0:FindFirstChild("Glow");
					if layer and layer:IsA("BasePart") and glow and glow.Enabled then
							repeat
								task.wait();
								_tp(layer.CFrame);
								if glow.Enabled and d:DistanceFromCharacter(layer.Position) <= 150 then
									MousePos = layer.Position;
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
							until not _G.Prehis_Skills or not glow.Parent or not glow.Enabled;
					end;
				end;
			end;
		end);
	end;
end);
xF:AddToggle("BF_Toggle_Auto_Collect_Dino_Bones", {
	Text = "Auto Collect Dino Bones",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		UI.SetManagedUserFlag("Prehis_DB", Y);
	end,
});
task.spawn(function()
	while IdleWait(_G.Prehis_DB, T) do
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
xF:AddToggle("BF_Toggle_Auto_Collect_Dragon_Eggs", {
	Text = "Auto Collect Dragon Eggs",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		UI.SetManagedUserFlag("Prehis_DE", Y);
	end,
});
task.spawn(function()
	while IdleWait(_G.Prehis_DE, T) do
		pcall(function()
			if _G.Prehis_DE then
				local eggs = BFMapNode("PrehistoricIsland", "Core", "SpawnedDragonEggs");
				local egg = eggs and eggs:FindFirstChild("DragonEgg");
				local molten = egg and egg:FindFirstChild("Molten");
				local prompt = molten and molten:FindFirstChildWhichIsA("ProximityPrompt", true);
				if molten and molten:IsA("BasePart") and prompt then
					_tp(molten.CFrame);
					if type(fireproximityprompt) == "function" then
						pcall(fireproximityprompt, prompt, 30);
					end;
				end;
			end;
		end);
	end;
end);
xF:AddToggle("BF_Toggle_Auto_Reset_When_Complete_Volcano", {
	Text = "Auto Reset When Complete Volcano",
	Tooltip = "Reset When Complete Volcano not collect dino bones and else..",
	Default = false,
	Callback = function(Y)
		_G.ResetPH = Y;
		UI.VolcanoResetTrial = nil;
	end,
});
UI.VolcanoResetTrial = nil;
task.spawn(function()
	while IdleWait(_G.ResetPH, T) do
		pcall(function()
			if _G.ResetPH then
				local island = BFMapNode("PrehistoricIsland");
				local trial = island and island:FindFirstChild("TrialTeleport");
				local character = d.Character;
				local humanoid = character and character:FindFirstChildOfClass("Humanoid");
				if trial and trial:FindFirstChild("TouchInterest") and humanoid then
					if UI.VolcanoResetTrial ~= trial then
						UI.VolcanoResetTrial = trial;
						humanoid.Health = 0;
					end;
				else
					UI.VolcanoResetTrial = nil;
					if workspace:FindFirstChild("DinoBone") then
						for _, object in pairs(workspace:GetChildren()) do
							if object.Name == "DinoBone" then
								local part = BFFirstPart(object);
								if part then
									_tp(part.CFrame);
								end;
							end;
						end;
					end;
				end;
			end;
		end);
	end;
end);
local dq = UI.Sections["Dungeon Event / Raiding"];
local Rq = dq:AddLabel({ DoesWrap = true, Text = " Raiding Status " });
task.spawn(function()
	while UI.LabelWait(2) do
		pcall(function()
			if GuiShown("Timer") then
				Rq:SetText("Raid Status: Active");
			else
				Rq:SetText("Raid Status: Inactive");
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
dq:AddDropdown("BF_Dropdown_Select_Chip", {
	Text = "Select Chip",
	Tooltip = "",
	Values = j,
	Default = "Flame",
	Multi = false,
	Callback = function(Y)
		UI.SetManagedUserValue("SelectChip", Y);
	end,
});
dq:AddToggle("BF_Toggle_Auto_Select_Dungeon_Chip", {
	Text = "Auto Select Dungeon Chip",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		_G.AutoSelectDungeon = Y;
		if not Y then
			UI.ReleaseManagedValue("AutoSelectDungeon", "SelectChip");
		end;
	end,
});
task.spawn(function()
	while IdleWait(_G.AutoSelectDungeon, T) do
		if _G.AutoSelectDungeon then
			pcall(function()
				if GetBP("Flame-Flame") then
					UI.DriveManagedValue("AutoSelectDungeon", "SelectChip", "Flame");
				elseif GetBP("Ice-Ice") then
					UI.DriveManagedValue("AutoSelectDungeon", "SelectChip", "Ice");
				elseif GetBP("Quake-Quake") then
					UI.DriveManagedValue("AutoSelectDungeon", "SelectChip", "Quake");
				elseif GetBP("Light-Light") then
					UI.DriveManagedValue("AutoSelectDungeon", "SelectChip", "Light");
				elseif GetBP("Dark-Dark") then
					UI.DriveManagedValue("AutoSelectDungeon", "SelectChip", "Dark");
				elseif GetBP("String-String") then
					UI.DriveManagedValue("AutoSelectDungeon", "SelectChip", "String");
				elseif GetBP("Rumble-Rumble") then
					UI.DriveManagedValue("AutoSelectDungeon", "SelectChip", "Rumble");
				elseif GetBP("Magma-Magma") then
					UI.DriveManagedValue("AutoSelectDungeon", "SelectChip", "Magma");
				elseif GetBP("Human-Human: Buddha Fruit") then
					UI.DriveManagedValue("AutoSelectDungeon", "SelectChip", "Human: Buddha");
				elseif GetBP("Dough-Dough") then
					UI.DriveManagedValue("AutoSelectDungeon", "SelectChip", "Dough");
				elseif GetBP("Sand-Sand") then
					UI.DriveManagedValue("AutoSelectDungeon", "SelectChip", "Sand");
				elseif GetBP("Bird-Bird: Phoenix") then
					UI.DriveManagedValue("AutoSelectDungeon", "SelectChip", "Bird: Phoenix");
				else
					UI.DriveManagedValue("AutoSelectDungeon", "SelectChip", "Ice");
				end;
			end);
		end;
	end;
	UI.ReleaseManagedValue("AutoSelectDungeon", "SelectChip");
end);
UI.RaidChipState = {
	Phase = "idle",
	NextAt = 0,
	Deadline = 0,
	PendingFruit = nil,
	UsedFruit = false,
	Catalog = nil,
	CatalogAt = 0,
};
UI.RaidChipStatusLabel = dq:AddLabel({ DoesWrap = true, Text = "Raid chip: idle" });
function UI.SetRaidChipStatus(status)
	status = tostring(status or "working");
	UI.RaidChipStatusLabel:SetText("Raid chip: " .. status:gsub("%-", " "));
end;
BFRaidFruitCatalog = function()
	local state = UI.RaidChipState;
	if type(state.Catalog) == "table" and os.clock() - state.CatalogAt < 60 then
		return state.Catalog;
	end;
	local rows = BFComm("GetFruits");
	if type(rows) ~= "table" then
		return nil;
	end;
	local catalog = {};
	for _, fruit in pairs(rows) do
		local price = type(fruit) == "table" and tonumber(fruit.Price);
		local name = type(fruit) == "table" and fruit.Name;
		if type(name) == "string" and price then
			catalog[BFNameKey(name)] = { Name = name, Price = price };
		end;
	end;
	state.Catalog = catalog;
	state.CatalogAt = os.clock();
	return catalog;
end;
BFFindPhysicalRaidFruit = function(catalog)
	for _, container in ipairs({ d.Character, d:FindFirstChild("Backpack") }) do
		for _, tool in ipairs(container and container:GetChildren() or {}) do
			local eatRemote = tool:FindFirstChild("EatRemote", true);
			local source = eatRemote and eatRemote.Parent;
			local originalName = source and source:GetAttribute("OriginalName") or tool:GetAttribute("OriginalName") or tool.Name;
			local record = catalog and catalog[BFNameKey(originalName)];
			if eatRemote and record and record.Price >= 100000 and record.Price < 1000000 then
				return tool, record;
			end;
		end;
	end;
	return nil;
end;
BFFindStoredRaidFruit = function(catalog)
	local candidates = {};
	for _, record in pairs(catalog or {}) do
		if record.Price >= 100000 and record.Price < 1000000 and GetIn(record.Name) and not localItem(record.Name) then
			table.insert(candidates, record);
		end;
	end;
	table.sort(candidates, function(left, right)
		return left.Price < right.Price;
	end);
	return candidates[1];
end;
BFResetRaidChipState = function(active)
	local state = UI.RaidChipState;
	state.Phase = active and "beli" or "idle";
	state.NextAt = 0;
	state.Deadline = 0;
	state.PendingFruit = nil;
	state.UsedFruit = false;
	UI.SetRaidChipStatus(active and "ready" or "idle");
end;
dq:AddToggle("BF_Toggle_Auto_Buy_Dungeon_Chip", {
	Text = "Auto Buy Dungeon Chip",
	Tooltip = "Use Beli when ready; otherwise use at most one physical or stored fruit under 1M",
	Default = false,
	Callback = function(Y)
		_G.AutoBuyDungeonChip = Y;
		BFResetRaidChipState(Y);
	end,
});
task.spawn(function()
	while IdleWait(_G.AutoBuyDungeonChip, .25) do
		if _G.AutoBuyDungeonChip then
			local ok = pcall(function()
				local state = UI.RaidChipState;
				local now = os.clock();
				if GetBP("Special Microchip") then
					state.Phase = "owned";
					state.PendingFruit = nil;
					UI.SetRaidChipStatus("microchip-owned");
					return;
				end;
				if type(_G.SelectChip) ~= "string" or _G.SelectChip == "" then
					UI.SetRaidChipStatus("select-a-raid-first");
					return;
				end;
				if now < state.NextAt then
					return;
				end;
				local catalog = BFRaidFruitCatalog();
				if state.Phase == "loading-fruit" then
					local tool, record = BFFindPhysicalRaidFruit(catalog);
					if tool and record and record.Name == state.PendingFruit then
						if tool.Parent == d:FindFirstChild("Backpack") then
							EquipWeapon(tool.Name);
							task.wait(.2);
						end;
						state.Phase = "fruit-select";
						state.NextAt = os.clock() + .2;
						UI.SetRaidChipStatus("fruit-ready");
					elseif now >= state.Deadline then
						UI.SetRaidChipStatus("fruit-load-not-acknowledged");
						local toggle = UI.Library.Toggles.BF_Toggle_Auto_Buy_Dungeon_Chip;
						if toggle and toggle.Value then
							toggle:SetValue(false);
						end;
					end;
					return;
				end;
				if state.Phase == "awaiting-chip" then
					if now < state.Deadline then
						return;
					end;
					if state.UsedFruit then
						UI.SetRaidChipStatus("purchase-not-acknowledged");
						local toggle = UI.Library.Toggles.BF_Toggle_Auto_Buy_Dungeon_Chip;
						if toggle and toggle.Value then
							toggle:SetValue(false);
						end;
						return;
					end;
					local physicalTool, physicalRecord = BFFindPhysicalRaidFruit(catalog);
					if physicalTool and physicalRecord then
						state.PendingFruit = physicalRecord.Name;
						state.Phase = "fruit-select";
						state.NextAt = now;
						UI.SetRaidChipStatus("physical-fruit-ready");
						return;
					end;
					local candidate = BFFindStoredRaidFruit(catalog);
					if not candidate then
						state.Phase = "beli";
						state.NextAt = now + 30;
						UI.SetRaidChipStatus("waiting-for-beli-cooldown");
						return;
					end;
					state.PendingFruit = candidate.Name;
					state.Phase = "loading-fruit";
					state.Deadline = now + 8;
					state.NextAt = now + .25;
					UI.SetRaidChipStatus("loading-" .. candidate.Name);
					BFComm("LoadFruit", candidate.Name);
					return;
				end;
				local heldTool, heldRecord = BFFindPhysicalRaidFruit(catalog);
				if state.Phase == "fruit-select" then
					if not heldTool or not heldRecord or heldRecord.Name ~= state.PendingFruit then
						UI.SetRaidChipStatus("physical-fruit-missing");
						local toggle = UI.Library.Toggles.BF_Toggle_Auto_Buy_Dungeon_Chip;
						if toggle and toggle.Value then
							toggle:SetValue(false);
						end;
						return;
					end;
					if heldTool.Parent == d:FindFirstChild("Backpack") then
						EquipWeapon(heldTool.Name);
						task.wait(.2);
					end;
					if heldTool.Parent ~= d.Character then
						state.NextAt = os.clock() + .25;
						UI.SetRaidChipStatus("waiting-for-fruit-equip");
						return;
					end;
					state.UsedFruit = true;
				elseif state.Phase == "beli" then
					if heldTool and heldTool.Parent == d.Character then
						local humanoid = d.Character:FindFirstChildOfClass("Humanoid");
						if humanoid then
							pcall(humanoid.UnequipTools, humanoid);
							task.wait(.2);
						end;
					end;
					state.UsedFruit = false;
				else
					return;
				end;
				UI.SetRaidChipStatus(state.UsedFruit and "buying-with-fruit" or "buying-with-beli");
				local response = BFComm("RaidsNpc", "Select", _G.SelectChip);
				if response == 0 then
					UI.SetRaidChipStatus("level-requirement-not-met");
					state.Phase = "beli";
					state.NextAt = now + 60;
					return;
				end;
				state.Phase = "awaiting-chip";
				state.Deadline = os.clock() + 8;
				state.NextAt = os.clock() + .25;
			end);
			if not ok then
				UI.SetRaidChipStatus("error");
			end;
		end;
	end;
end);
local Qq = UI.Sections["Raiding Menu"];
UI.RaidStartStatus = "idle";
UI.RaidStartStatusLabel = nil;
UI.RaidStartNextEntranceAt = 0;
UI.RaidStartNextClickAt = 0;
function UI.SetRaidStartStatus(status)
	status = tostring(status or "working");
	if status ~= UI.RaidStartStatus then
		UI.RaidStartStatus = status;
		if UI.RaidStartStatusLabel then
			UI.RaidStartStatusLabel:SetText("Raid start: " .. status:gsub("%-", " "));
		end;
	end;
end;
Qq:AddToggle("BF_Toggle_Auto_Start_Raid", {
	Text = "Auto Start Raid",
	Tooltip = "Start the selected raid when a Special Microchip is available",
	Default = false,
	Callback = function(Y)
		UI.SetManagedUserFlag("Auto_StartRaid", Y);
		if _G.Auto_StartRaid then
			UI.RaidStartNextEntranceAt = 0;
			UI.RaidStartNextClickAt = 0;
		else
			UI.SetRaidStartStatus("idle");
		end;
	end,
});
UI.RaidStartStatusLabel = Qq:AddLabel({ DoesWrap = true, Text = "Raid start: " .. UI.RaidStartStatus:gsub("%-", " ") });
task.spawn(function()
	while IdleWait(_G.Auto_StartRaid, .25) do
		if _G.Auto_StartRaid then
			local ok = pcall(function()
				if GuiShown("TopHUDList", "RaidTimer") then
					UI.SetRaidStartStatus("raid-active");
					return;
				end;
				if not GetBP("Special Microchip") then
					UI.SetRaidStartStatus("waiting-for-microchip");
					return;
				end;
				if type(fireclickdetector) ~= "function" then
					UI.SetRaidStartStatus("click-detector-unsupported");
					return;
				end;
				local detector;
				if World2 then
					if not BFMoveNear(CFrame.new(-6438.73535, 250.645355, -4501.50684), 12) then
						UI.SetRaidStartStatus("moving-to-second-sea-summoner");
						return;
					end;
					detector = BFMapNode("CircleIsland", "RaidSummon2", "Button", "Main", "ClickDetector");
				elseif World3 then
					detector = BFMapNode("Boat Castle", "RaidSummon2", "Button", "Main", "ClickDetector");
					if not detector then
						UI.SetRaidStartStatus("loading-third-sea-summoner");
						local now = os.clock();
						if now >= UI.RaidStartNextEntranceAt then
							UI.RaidStartNextEntranceAt = now + 2;
							BFComm("requestEntrance", Vector3.new(-5097.93164, 316.447021, -3142.66602));
						end;
						return;
					end;
				else
					UI.SetRaidStartStatus("wrong-world");
					return;
				end;
				if not detector or not detector:IsA("ClickDetector") then
					UI.SetRaidStartStatus("waiting-for-summoner");
					return;
				end;
				UI.SetRaidStartStatus("ready");
				local now = os.clock();
				if now >= UI.RaidStartNextClickAt then
					UI.RaidStartNextClickAt = now + 1;
					UI.SetRaidStartStatus("starting");
					pcall(fireclickdetector, detector);
				end;
			end);
			if not ok then
				UI.SetRaidStartStatus("error");
			end;
		end;
	end;
end);
Qq:AddToggle("BF_Toggle_Teleport_To_Lab", {
	Text = "Teleport To Lab",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		_G.TpLab = Y;
	end,
});
task.spawn(function()
	while IdleWait(_G.TpLab, T) do
		if _G.TpLab then
			pcall(function()
				if World2 then
					_tp(CFrame.new(-6438.73535, 250.645355, -4501.50684));
				elseif World3 then
					_tp(CFrame.new(-5017.40869, 314.844055, -2823.0127, -0.925743818, 4.48217499e-08, -0.378151238, 4.55503146e-09, 1, 1.07377559e-07, .378151238, 9.7681621e-08, -0.925743818));
				end;
			end);
		end;
	end;
end);
UI.RaidCompleteStatus = "idle";
UI.RaidCompleteStatusLabel = nil;
function UI.SetRaidCompleteStatus(status)
	status = tostring(status or "working");
	if status ~= UI.RaidCompleteStatus then
		UI.RaidCompleteStatus = status;
		if UI.RaidCompleteStatusLabel then
			UI.RaidCompleteStatusLabel:SetText("Raid completion: " .. status:gsub("%-", " "));
		end;
	end;
end;
Qq:AddToggle("BF_Toggle_Auto_Complete_Raid_Safety", {
	Text = "Auto Complete Raid",
	Tooltip = "Attack one live raid enemy at a time and move through streamed raid islands",
	Default = false,
	Callback = function(Y)
		UI.SetManagedUserFlag("Raiding", Y);
		if not _G.Raiding then
			UI.ReleaseManagedOwner("RaidComplete");
			BFCancelTween();
			UI.SetRaidCompleteStatus("idle");
		end;
	end,
});
UI.RaidCompleteStatusLabel = Qq:AddLabel({ DoesWrap = true, Text = "Raid completion: idle" });
function UI.RaidCompleteStep(active)
	if not active then
		UI.ReleaseManagedOwner("RaidComplete");
		BFCancelTween();
		return "idle";
	end;
	if not GuiShown("TopHUDList", "RaidTimer") then
		UI.ReleaseManagedOwner("RaidComplete");
		BFCancelTween();
		return "waiting-for-raid";
	end;
	local character = d.Character;
	local humanoid = character and character:FindFirstChildOfClass("Humanoid");
	local root = character and character:FindFirstChild("HumanoidRootPart");
	if not humanoid or humanoid.Health <= 0 or not root then
		UI.ReleaseManagedOwner("RaidComplete");
		BFCancelTween();
		return "waiting-for-respawn";
	end;
	local enemy = BFFindNearestEnemy(root.Position);
	if enemy then
		UI.SuppressManagedFlag("RaidComplete", "NextIs");
		f.Kill(enemy, active);
		return "combat";
	end;
	UI.DriveManagedFlag("RaidComplete", "NextIs");
	return "moving-to-next-island";
end;
task.spawn(function()
	while IdleWait(_G.Raiding, .1) do
		if _G.Raiding then
			local ok, status = pcall(UI.RaidCompleteStep, _G.Raiding);
			status = ok and tostring(status or "working") or "error";
			if not ok then
				UI.ReleaseManagedOwner("RaidComplete");
			end;
			UI.SetRaidCompleteStatus(status);
		end;
	end;
	UI.ReleaseManagedOwner("RaidComplete");
end);
Qq:AddToggle("BF_Toggle_Kill_Aura", {
	Text = "Kill Aura",
	Tooltip = "Attack every live enemy within combat range",
	Default = false,
	Callback = function(Y)
		_G.KillH = Y;
		if not Y then
			BFAttackUntil = 0;
		end;
	end,
});
task.spawn(function()
	while IdleWait(_G.KillH, .1) do
		if _G.KillH then
			pcall(function()
				EquipWeapon(_G.BFCombatWeapon or EnsureWeapon());
				BFTouchAttack();
			end);
		end;
	end;
end);
Qq:AddToggle("BF_Toggle_Auto_Next_Island", {
	Text = "Auto Next Island",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		UI.SetManagedUserFlag("NextIs", Y);
	end,
});
UI.NextIslandTarget = nil;
UI.NextIslandRetargetAt = 0;
task.spawn(function()
	while IdleWait(_G.NextIs, T) do
		if _G.NextIs then
			pcall(function()
				if not GuiShown("TopHUDList", "RaidTimer") then
					UI.NextIslandTarget = nil;
					return;
				end;
				local character = d.Character;
				local root = character and character:FindFirstChild("HumanoidRootPart");
				if not root then
					return;
				end;
				local island, name = BFRaidNextIsland(root);
				if not island then
					UI.NextIslandTarget = nil;
					return;
				end;
				local target = island.CFrame * CFrame.new(0, 50, 100);
				if (root.Position - target.Position).Magnitude <= 25 then
					return;
				end;
				-- Re-issuing _tp on every tick cancelled and restarted the tween each time,
				-- so the character drifted instead of ever arriving. Only retarget when the
				-- chosen island changes, or after the previous tween has had time to run.
				local now = os.clock();
				if UI.NextIslandTarget ~= name or now >= UI.NextIslandRetargetAt then
					UI.NextIslandTarget = name;
					UI.NextIslandRetargetAt = now + 3;
					_tp(target);
				end;
			end);
		end;
	end;
	UI.NextIslandTarget = nil;
end);
UI.AwakenerNextAt = 0;
Qq:AddToggle("BF_Toggle_Auto_Awakening", {
	Text = "Auto Awakening",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		UI.SetManagedUserFlag("Auto_Awakener", Y);
		if _G.Auto_Awakener then
			UI.AwakenerNextAt = 0;
		end;
	end,
});
task.spawn(function()
	while IdleWait(_G.Auto_Awakener, .25) do
		pcall(function()
			local now = os.clock();
			if _G.Auto_Awakener and now >= UI.AwakenerNextAt then
				UI.AwakenerNextAt = now + 1;
				BFComm("Awakener", "Check");
				BFComm("Awakener", "Awaken");
			end;
		end);
	end;
end);
local rq = UI.Sections["Combat / Aimbot"];
__indexPlayer = rq:AddLabel({ DoesWrap = true, Text = "All Players On Server :" });
task.spawn(function()
	while UI.LabelWait(1) do
		local count = #A:GetPlayers();
		local suffix = count >= A.MaxPlayers and " [Max]" or "";
		__indexPlayer:SetText(string.format("Players: %d / %d%s", count, A.MaxPlayers, suffix));
	end;
end);
__AimBotTurn = rq:AddLabel({ DoesWrap = true, Text = "Aimbot Status :" });
local aq = { "AimBots Skill", "Auto Aimbots" };
Checking_AimStatus = function()
		local status = _G.AimMethod and "Skills" or "";
		if _G.AimCam then
			status = status == "" and "Camera" or status .. " | Camera";
		end;
		if _G.AimbotGun then
			status = status == "" and "Guns" or status .. " | Guns";
		end;
		return status;
	end;
task.spawn(function()
	while IdleWait(_G.AimMethod or _G.AimCam or _G.AimbotGun, .2) do
		pcall(function()
			local status = Checking_AimStatus();
			__AimBotTurn:SetText(status == "" and "Aimbot: Off" or "Aimbot: " .. status);
		end);
	end;
end);
	do
		local function BFAimPlayerNames()
			local names = {};
			for _, player in ipairs(A:GetPlayers()) do
				if player ~= g then
					table.insert(names, player.Name);
				end;
		end;
		table.sort(names);
		return names;
	end;
	local wq = BFAimPlayerNames();
	local aimPlayerDropdown = rq:AddDropdown("BF_Dropdown_Choose_Players", {
		Text = "Choose Players",
		Tooltip = "",
		Values = wq,
		Default = wq[1],
		Multi = false,
		Callback = function(Y)
			_G.PlayersList = Y;
		end,
	});
	local function BFRefreshAimPlayers()
		local names = BFAimPlayerNames();
		pcall(aimPlayerDropdown.SetValues, aimPlayerDropdown, names);
		if not table.find(names, _G.PlayersList) then
			if names[1] then
				aimPlayerDropdown:SetValue(names[1]);
			else
				_G.PlayersList = nil;
			end;
		end;
	end;
	UI.Library:GiveSignal(A.PlayerAdded:Connect(function()
		task.defer(BFRefreshAimPlayers);
	end));
	UI.Library:GiveSignal(A.PlayerRemoving:Connect(function()
		task.defer(BFRefreshAimPlayers);
	end));
end;
rq:AddToggle("BF_Toggle_Teleport_to_choose_players", {
	Text = "Teleport to choose players",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		_G.TpPly = Y;
	end,
});
task.spawn(function()
	while IdleWait(_G.TpPly, T) do
		if _G.TpPly then
			local target = A:FindFirstChild(_G.PlayersList or "");
			local character = target and target.Character;
			local root = character and character:FindFirstChild("HumanoidRootPart");
			if root then
				_tp(root.CFrame);
			end;
		end;
	end;
end);
UI.RestoreSpectateTarget = function()
	local camera = workspace.CurrentCamera;
	local state = UI.SpectateState;
	UI.SpectateState = nil;
	if not camera then
		return;
	end;
	if state then
		pcall(function()
			camera.CameraType = state.CameraType;
		end);
		if state.CameraSubject and state.CameraSubject.Parent then
			pcall(function()
				camera.CameraSubject = state.CameraSubject;
			end);
			return;
		end;
	end;
	local character = d.Character;
	local humanoid = character and character:FindFirstChildOfClass("Humanoid");
	if humanoid then
		pcall(function()
			camera.CameraType = Enum.CameraType.Custom;
			camera.CameraSubject = humanoid;
		end);
	end;
end;
UI.ApplySpectateTarget = function()
	local camera = workspace.CurrentCamera;
	local target = A:FindFirstChild(_G.PlayersList or "");
	local character = target and target.Character;
	local humanoid = character and character:FindFirstChildOfClass("Humanoid");
	if not camera or not humanoid then
		return false;
	end;
	if not UI.SpectateState then
		UI.SpectateState = {
			CameraType = camera.CameraType,
			CameraSubject = camera.CameraSubject,
		};
	end;
	pcall(function()
		camera.CameraType = Enum.CameraType.Custom;
		camera.CameraSubject = humanoid;
	end);
	return camera.CameraSubject == humanoid;
end;
SpectatePlys = false;
rq:AddToggle("BF_Toggle_Spectate_Choose_Players", {
	Text = "Spectate Choose Players",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		SpectatePlys = Y;
		if Y then
			UI.ApplySpectateTarget();
		else
			UI.RestoreSpectateTarget();
		end;
	end,
});
task.spawn(function()
	while IdleWait(SpectatePlys, .1) do
		if SpectatePlys then
			UI.ApplySpectateTarget();
		end;
	end;
end);
rq:AddDropdown("BF_Dropdown_Choose_Aim_Method", {
	Text = "Choose Aim Method",
	Tooltip = "",
	Values = aq,
	Default = "AimBots Skill",
	Multi = false,
	Callback = function(Y)
		ABmethod = Y;
	end,
});
ABmethod = ABmethod or "AimBots Skill";
rq:AddToggle("BF_Toggle_Aimbot_Method_Skills", {
	Text = "Aimbot Method Skills",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		_G.AimMethod = Y;
		if not Y and not _G.AimbotGun then
			UI.AimTargetPlayer = nil;
			UI.AimTargetPosition = nil;
		end;
	end,
});
BFAimTargetPlayer = function()
	if ABmethod == "AimBots Skill" then
		local selected = A:FindFirstChild(_G.PlayersList or "");
		if selected ~= d and (not _G.NoAimTeam or selected and selected.Team ~= d.Team) then
			return selected;
		end;
		return nil;
	end;
	local localRoot = BFCharacterPart();
	local nearestPlayer;
	local nearestDistance = math.huge;
	for _, player in ipairs(A:GetPlayers()) do
		local character = player.Character;
		local root = character and character:FindFirstChild("HumanoidRootPart");
		local humanoid = character and character:FindFirstChildOfClass("Humanoid");
		if localRoot and player ~= d and (not _G.NoAimTeam or player.Team ~= d.Team) and root and humanoid and humanoid.Health > 0 then
			local distance = (root.Position - localRoot.Position).Magnitude;
			if distance < nearestDistance then
				nearestDistance = distance;
				nearestPlayer = player;
			end;
		end;
	end;
	return nearestPlayer;
end;
getgenv().BFAimTargetPlayer = BFAimTargetPlayer;
task.spawn(function()
	while IdleWait(_G.AimMethod or _G.AimbotGun, .05) do
		if _G.AimMethod or _G.AimbotGun then
			pcall(function()
				local player = BFAimTargetPlayer();
				local character = player and player.Character;
				local humanoid = character and character:FindFirstChildOfClass("Humanoid");
				local root = character and character:FindFirstChild("HumanoidRootPart");
				if humanoid and humanoid.Health > 0 and root then
					UI.AimTargetPlayer = player;
					UI.AimTargetPosition = root.Position;
					MousePos = root.Position;
				else
					UI.AimTargetPlayer = nil;
					UI.AimTargetPosition = nil;
				end;
			end);
		else
			UI.AimTargetPlayer = nil;
			UI.AimTargetPosition = nil;
		end;
	end;
end);
rq:AddToggle("BF_Toggle_Aimbot_Guns", {
	Text = "Aimbot Guns",
	Tooltip = "Redirect supported gun shots to the selected aim target",
	Default = false,
	Callback = function(Y)
		_G.AimbotGun = Y;
		if not Y and not _G.AimMethod then
			UI.AimTargetPlayer = nil;
			UI.AimTargetPosition = nil;
		end;
	end,
});
rq:AddToggle("BF_Toggle_Aimbot_Camera_Closet_Players", {
	Text = "Aimbot Camera Closest Player",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		_G.AimCam = Y;
		if not Y then
			UI.AimCameraTarget = nil;
		end;
	end,
});
task.spawn(function()
	local function closestPlayer()
		local nearest = math.huge;
		local result;
		local localHead = i and i:FindFirstChild("Head");
		if not localHead then
			return nil;
		end;
		for _, player in ipairs(A:GetPlayers()) do
			local character = player.Character;
			local head = character and character:FindFirstChild("Head");
			local humanoid = character and character:FindFirstChildOfClass("Humanoid");
			if player ~= d and (not _G.NoAimTeam or player.Team ~= d.Team) and head and humanoid and humanoid.Health > 0 then
				local distance = (head.Position - localHead.Position).Magnitude;
				if distance < nearest then
					nearest = distance;
					result = player;
				end;
			end;
		end;
		return result;
	end;
	while IdleWait(_G.AimCam, T) do
		pcall(function()
			if _G.AimCam then
				local camera = workspace.CurrentCamera;
				local player = closestPlayer();
				local root = player and player.Character and player.Character:FindFirstChild("HumanoidRootPart");
				if root then
					UI.AimCameraTarget = player;
					camera.CFrame = CFrame.new(camera.CFrame.Position, root.Position);
				else
					UI.AimCameraTarget = nil;
				end;
			end;
		end);
	end;
end);
local Fq = UI.Sections["LocalPlayer Settings / Misc"];
local selectedInfiniteAbilities = { Energy = true };
local infiniteSelectedAbilities = false;
local function ApplySelectedInfiniteAbilities()
	InfAblities = infiniteSelectedAbilities and selectedInfiniteAbilities["Mink V3"] == true;
	infEnergy = infiniteSelectedAbilities and selectedInfiniteAbilities.Energy == true;
	_G.InfSoru = infiniteSelectedAbilities and selectedInfiniteAbilities.Soru == true;
	_G.InfiniteObRange = infiniteSelectedAbilities and selectedInfiniteAbilities["Observation Range"] == true;
	if not infEnergy then
		UI.InfiniteAbilityState.Energy = nil;
		UI.InfiniteAbilityState.EnergyValue = nil;
	end;
	if not InfAblities then
		UI.RestoreInfiniteAgility();
	end;
	if not _G.InfiniteObRange then
		UI.RestoreInfiniteObservation();
	end;
end;
Fq:AddDropdown("BF_Dropdown_Selected_Infinite_Abilities", {
	Text = "Infinite Abilities",
	Tooltip = "Choose one or more abilities to keep infinite",
	Values = { "Mink V3", "Energy", "Soru", "Observation Range" },
	Default = { "Energy" },
	Multi = true,
	NoMode = true,
	Callback = function(Y)
		selectedInfiniteAbilities = Y or {};
		ApplySelectedInfiniteAbilities();
	end,
});
Fq:AddToggle("BF_Toggle_Enable_Selected_Infinite_Abilities", {
	Text = "Enable Selected",
	Tooltip = "Enable every selected infinite ability",
	Default = false,
	Callback = function(Y)
		infiniteSelectedAbilities = Y;
		ApplySelectedInfiniteAbilities();
	end,
});
task.spawn(function()
	while IdleWait(infiniteSelectedAbilities, .1) do
		pcall(function()
			if not infiniteSelectedAbilities then
				return;
			end;
			if infEnergy then
				getInfinity_Ability("Energy", true);
			end;
			if _G.InfSoru then
				getInfinity_Ability("Soru", true);
			end;
			if _G.InfiniteObRange then
				getInfinity_Ability("Observation", true);
			end;
			if InfAblities then
				local character = d.Character;
				local root = character and character:FindFirstChild("HumanoidRootPart");
				if not root then
					return;
				end;
				local state = UI.InfiniteAbilityState;
				if state.Agility and state.Agility.Parent ~= root then
					UI.RestoreInfiniteAgility();
				end;
				if not root:FindFirstChild("Agility") then
					local agility = Q.FX.Agility:Clone();
					agility.Name = "Agility";
					agility.Parent = root;
					state.Agility = agility;
				end;
			end;
		end);
	end;
	UI.RestoreInfiniteAbilities();
end);
local Mq = UI.Sections["Settings Combat / Aimbot Settings"];
Mq:AddToggle("BF_Toggle_Ignore_Same_Teams", {
	Text = "Ignore Same Teams",
	Tooltip = "turn on for ignore not aimbot same team",
	Default = false,
	Callback = function(Y)
		_G.NoAimTeam = Y;
	end,
});
Mq:AddToggle("BF_Toggle_Accept_Allies", {
	Text = "Accept Allies",
	Tooltip = "turn on for auto accept ally",
	Default = false,
	Callback = function(Y)
		_G.AcceptAlly = Y;
	end,
});
task.spawn(function()
	while IdleWait(_G.AcceptAlly, T) do
		if _G.AcceptAlly then
			pcall(function()
				for Y, R in pairs(Y:GetChildren()) do
					if R.Name ~= d.Name and (R:FindFirstChild("Humanoid") and R:FindFirstChild("HumanoidRootPart")) then
						BFComm("AcceptAlly", R.Name);
					end;
				end;
			end);
		end;
	end;
end);
local Kq = UI.Sections["Esp Items / Entity / Island"];
function isnil(Y)
	return Y == nil;
end;
local function nq(Y)
	return math.floor(tonumber(Y) + .5);
end;
Number = math.random(1, 1000000);
EspPly = function()
		for _, player in next, game.Players:GetChildren() do
			pcall(function()
				local character = player.Character;
				local head = character and character:FindFirstChild("Head");
				if not head then
					return;
				end;
				local gui = head:FindFirstChild("NameEsp" .. Number);
				if not PlayerEsp then
					if gui then
						gui:Destroy();
					end;
					return;
				end;
				local ownCharacter = game.Players.LocalPlayer.Character;
				local ownHead = ownCharacter and ownCharacter:FindFirstChild("Head");
				if not ownHead then
					return;
				end;
				if not gui then
					gui = Instance.new("BillboardGui", head);
					gui.Name = "NameEsp" .. Number;
					gui.ExtentsOffset = Vector3.new(0, 1, 0);
					gui.Size = UDim2.new(1, 200, 1, 30);
					gui.Adornee = head;
					gui.AlwaysOnTop = true;
					local label = Instance.new("TextLabel", gui);
					label.Font = Enum.Font.Code;
					label.TextSize = 14;
					label.TextWrapped = true;
					label.Size = UDim2.new(1, 0, 1, 0);
					label.TextYAlignment = Enum.TextYAlignment.Top;
					label.BackgroundTransparency = 1;
					label.TextStrokeTransparency = .5;
					label.TextColor3 = player.Team == I and Color3.fromRGB(0, 0, 254) or Color3.fromRGB(255, 0, 0);
				end;
				local label = gui:FindFirstChildOfClass("TextLabel");
				local humanoid = character:FindFirstChildOfClass("Humanoid");
				local data = player:FindFirstChild("Data");
				local level = data and data:FindFirstChild("Level");
				if label then
					local distance = nq((ownHead.Position - head.Position).Magnitude / 3);
					local health = humanoid and humanoid.MaxHealth > 0 and nq((humanoid.Health * 100) / humanoid.MaxHealth) or 0;
					label.Text = tostring(level and level.Value or "?") .. " | " .. player.Name .. " | " .. distance .. " M\nHealth : " .. health .. "%";
				end;
			end);
		end;
	end;
LocationEsp = function()
		local locations = BFWorldLocations();
		if not locations then
			return;
		end;
		local ownPart = BFCharacterPart();
		for _, location in ipairs(locations:GetChildren()) do
			pcall(function()
				local target = BFFirstPart(location);
				local gui = target and target:FindFirstChild("NameEsp");
				if IslandESP and location.Name ~= "Sea" then
					if ownPart and target then
						local _, label = BFEnsureEspLabel(target, "NameEsp", Color3.fromRGB(98, 252, 252));
						if label then
							label.Text = location.Name .. ("   \n" .. (nq((ownPart.Position - target.Position).Magnitude / 3) .. " M"));
					end;
					end;
				elseif gui then
					gui:Destroy();
				end;
			end);
		end;
	end;
DevEsp = function()
		local ownPart = BFCharacterPart();
		local guiName = "NameEsp" .. Number;
		for _, object in ipairs(workspace:GetChildren()) do
			pcall(function()
				if not string.find(object.Name, "Fruit", 1, true) then
					return;
				end;
				local handle = object:FindFirstChild("Handle", true);
				if not handle or not handle:IsA("BasePart") then
					return;
				end;
				local gui = handle:FindFirstChild(guiName);
				if DevilFruitESP then
					if ownPart then
						local _, label = BFEnsureEspLabel(handle, guiName, Color3.fromRGB(255, 255, 255));
						if label then
							label.Text = "[" .. (object.Name .. ("]   \n" .. (nq((ownPart.Position - handle.Position).Magnitude / 3) .. " M")));
					end;
					end;
				elseif gui then
					gui:Destroy();
				end;
			end);
		end;
	end;
flowerEsp = function()
		local ownPart = BFCharacterPart();
		local guiName = "NameEsp" .. Number;
		for _, flower in ipairs(workspace:GetChildren()) do
			pcall(function()
				if flower.Name ~= "Flower1" and flower.Name ~= "Flower2" then
					return;
				end;
				local target = BFFirstPart(flower);
				if not target then
					return;
				end;
				local gui = target:FindFirstChild(guiName);
				if FlowerESP then
					if ownPart then
						local _, label = BFEnsureEspLabel(target, guiName, Color3.fromRGB(88, 214, 252));
						if label then
							local name = flower.Name == "Flower1" and "Blue Flower" or "Red Flower";
							label.Text = name .. (" \n" .. (nq((ownPart.Position - target.Position).Magnitude / 3) .. " M"));
						end;
					end;
				elseif gui then
					gui:Destroy();
				end;
			end);
		end;
	end;
EventIslandEsp = function()
		local locations = BFWorldLocations();
		if not locations then
			return;
		end;
		local ownPart = BFCharacterPart();
		for _, location in ipairs(locations:GetChildren()) do
			pcall(function()
				local target = BFFirstPart(location);
				local gui = target and target:FindFirstChild("EventNameEsp");
				local eventIsland = location.Name == "Mirage Island" or location.Name == "Prehistoric Island" or location.Name == "Kitsune Island";
				if EspEventIsland and eventIsland then
					if ownPart and target then
						local _, label = BFEnsureEspLabel(target, "EventNameEsp", Color3.fromRGB(80, 245, 245));
						if label then
							label.Text = location.Name .. ("   \n" .. (nq((ownPart.Position - target.Position).Magnitude / 3) .. " M"));
						end;
					end;
				elseif gui then
					gui:Destroy();
				end;
			end);
		end;
	end;
gearEsp = function()
		local map = workspace:FindFirstChild("Map");
		local island = map and map:FindFirstChild("MysticIsland");
		if not island then
			return;
		end;
		local ownPart = BFCharacterPart();
		for _, part in ipairs(island:GetDescendants()) do
			if part:IsA("BasePart") and part.Name == "Part" and part.Material == Enum.Material.Neon then
				local gui = part:FindFirstChild("NameEsp");
				if ESPGear and ownPart then
					local _, label = BFEnsureEspLabel(part, "NameEsp", Color3.fromRGB(80, 245, 245));
					if label then
						label.Text = "Gear" .. ("   \n" .. (nq((ownPart.Position - part.Position).Magnitude / 3) .. " M"));
					end;
				elseif gui then
					gui:Destroy();
				end;
			end;
		end;
	end;
AdvanFruitEsp = function()
		BFNpcEsp(advanEsp == true, "Adv", "Advanced Fruit Dealer", nil);
	end;
HakiClorEsp = function()
		BFNpcEsp(ColorEsp == true, "Gay", "Barista Cousin", nil);
	end;
LegenSword = function()
		BFNpcEsp(LegenS == true, "Lgd", nil, "Legendary Sword Dealer");
	end;
ChestEsp = function()
		local collection = game:GetService("CollectionService");
		local chests = collection:GetTagged("_ChestTagged");
		if not ChestESP then
			for _, chest in ipairs(chests) do
				local attachment = chest:FindFirstChild("ChestEspAttachment", true);
				if attachment then
					attachment:Destroy();
				end;
			end;
			return;
		end;
		local ownPart = BFCharacterPart();
		if not ownPart then
			return;
		end;
		local ownPosition = ownPart.Position;
		local selected = typeof(SelectedIsland) == "Instance" and SelectedIsland or nil;
		for _, chest in ipairs(chests) do
			pcall(function()
				local attachment = chest:FindFirstChild("ChestEspAttachment", true);
				if not chest.Parent or chest:GetAttribute("IsDisabled") or selected and not chest:IsDescendantOf(selected) then
					if attachment then
						attachment:Destroy();
					end;
					return;
				end;
				local host = BFFirstPart(chest);
				if not host then
					return;
				end;
				local distance = (host.Position - ownPosition).Magnitude;
				if _G.AutoFarmChest and distance <= 20 then
					if attachment then
						attachment:Destroy();
					end;
					return;
				end;
				if attachment and (not attachment:IsA("Attachment") or attachment.Parent ~= host) then
					attachment:Destroy();
					attachment = nil;
				end;
				if not attachment then
					attachment = Instance.new("Attachment");
					attachment.Name = "ChestEspAttachment";
					attachment.Position = Vector3.new(0, 3, 0);
					attachment.Parent = host;
				end;
				local gui = attachment:FindFirstChild("NameEsp");
				if gui and not gui:IsA("BillboardGui") then
					gui:Destroy();
					gui = nil;
				end;
				if not gui then
					gui = Instance.new("BillboardGui");
					gui.Name = "NameEsp";
					gui.Size = UDim2.new(0, 200, 0, 30);
					gui.Adornee = attachment;
					gui.ExtentsOffset = Vector3.new(0, 1, 0);
					gui.AlwaysOnTop = true;
					gui.Parent = attachment;
				end;
				local label = gui:FindFirstChild("TextLabel");
				if label and not label:IsA("TextLabel") then
					label:Destroy();
					label = nil;
				end;
				if not label then
					label = Instance.new("TextLabel");
					label.Name = "TextLabel";
					label.Font = Enum.Font.Code;
					label.TextSize = 14;
					label.TextWrapped = true;
					label.Size = UDim2.new(1, 0, 1, 0);
					label.TextYAlignment = Enum.TextYAlignment.Top;
					label.BackgroundTransparency = 1;
					label.TextStrokeTransparency = .5;
					label.TextColor3 = Color3.fromRGB(80, 245, 245);
					label.Parent = gui;
				end;
				label.Text = string.format("[%s] %d M", chest.Name:gsub("Label", ""), math.floor(distance / 3));
			end);
		end;
	end;
berriesEsp = function()
		local bushes = (game:GetService("CollectionService")):GetTagged("BerryBush");
		if not BerryEsp then
			for _, bush in ipairs(bushes) do
				BFClearBerryMarkers(bush, nil);
			end;
			BFClearBerryMarkers(workspace, nil);
			return;
		end;
		local ownPart = BFCharacterPart();
		if not ownPart then
			return;
		end;
		local selected;
		if BerryArray then
			selected = {};
			for _, berryName in ipairs(BerryArray) do
				selected[berryName] = true;
			end;
		end;
		for _, bush in ipairs(bushes) do
			pcall(BFUpdateBerryBush, bush, ownPart, selected);
		end;
	end;
UI.EspValues = { "Berries", "Players", "Chests", "Fruits", "Island Locations" };
if World2 then
	table.insert(UI.EspValues, "Flowers");
	table.insert(UI.EspValues, "Legendary Sword Dealer");
end;
if World2 or World3 then
	table.insert(UI.EspValues, "Aura Colour Dealers");
end;
if World3 then
	table.insert(UI.EspValues, "Mirage Gear");
	table.insert(UI.EspValues, "Sea Event Islands");
	table.insert(UI.EspValues, "Advanced Fruit Dealer");
end;
UI.SelectedEspTargets = { Players = true };
UI.EnableSelectedEsp = false;
function UI.ApplySelectedEspTargets()
	local previousBerryEsp = BerryEsp;
	local previousPlayerEsp = PlayerEsp;
	local previousChestEsp = ChestESP;
	local previousFruitEsp = DevilFruitESP;
	local previousIslandEsp = IslandESP;
	local previousFlowerEsp = FlowerESP;
	local previousLegendaryEsp = LegenS;
	local previousColourEsp = ColorEsp;
	local previousGearEsp = ESPGear;
	local previousEventEsp = EspEventIsland;
	local previousDealerEsp = advanEsp;
	BerryEsp = UI.EnableSelectedEsp and UI.SelectedEspTargets.Berries == true;
	PlayerEsp = UI.EnableSelectedEsp and UI.SelectedEspTargets.Players == true;
	ChestESP = UI.EnableSelectedEsp and UI.SelectedEspTargets.Chests == true;
	DevilFruitESP = UI.EnableSelectedEsp and UI.SelectedEspTargets.Fruits == true;
	IslandESP = UI.EnableSelectedEsp and UI.SelectedEspTargets["Island Locations"] == true;
	FlowerESP = UI.EnableSelectedEsp and UI.SelectedEspTargets.Flowers == true;
	LegenS = UI.EnableSelectedEsp and UI.SelectedEspTargets["Legendary Sword Dealer"] == true;
	ColorEsp = UI.EnableSelectedEsp and UI.SelectedEspTargets["Aura Colour Dealers"] == true;
	ESPGear = UI.EnableSelectedEsp and UI.SelectedEspTargets["Mirage Gear"] == true;
	EspEventIsland = UI.EnableSelectedEsp and UI.SelectedEspTargets["Sea Event Islands"] == true;
	advanEsp = UI.EnableSelectedEsp and UI.SelectedEspTargets["Advanced Fruit Dealer"] == true;
	if previousBerryEsp and not BerryEsp then pcall(berriesEsp); end;
	if previousPlayerEsp and not PlayerEsp then pcall(EspPly); end;
	if previousChestEsp and not ChestESP then pcall(ChestEsp); end;
	if previousFruitEsp and not DevilFruitESP then pcall(DevEsp); end;
	if previousIslandEsp and not IslandESP then pcall(LocationEsp); end;
	if previousFlowerEsp and not FlowerESP then pcall(flowerEsp); end;
	if previousLegendaryEsp and not LegenS then pcall(LegenSword); end;
	if previousColourEsp and not ColorEsp then pcall(HakiClorEsp); end;
	if previousGearEsp and not ESPGear then pcall(gearEsp); end;
	if previousEventEsp and not EspEventIsland then pcall(EventIslandEsp); end;
	if previousDealerEsp and not advanEsp then pcall(AdvanFruitEsp); end;
end;
Kq:AddDropdown("BF_Dropdown_Selected_ESP_Targets", {
	Text = "ESP Targets",
	Tooltip = "Choose one or more ESP overlays",
	Values = UI.EspValues,
	Default = { "Players" },
	Multi = true,
	NoMode = true,
	Callback = function(Y)
		UI.SelectedEspTargets = Y or {};
		UI.ApplySelectedEspTargets();
	end,
});
Kq:AddToggle("BF_Toggle_Enable_Selected_ESP", {
	Text = "Enable Selected",
	Tooltip = "Show every selected ESP overlay",
	Default = false,
	Callback = function(Y)
		UI.EnableSelectedEsp = Y;
		UI.ApplySelectedEspTargets();
	end,
});
task.spawn(function()
	while IdleWait(UI.EnableSelectedEsp, .2) do
		if UI.EnableSelectedEsp then
			if BerryEsp then pcall(berriesEsp); end;
			if PlayerEsp then pcall(EspPly); end;
			if ChestESP then pcall(ChestEsp); end;
			if DevilFruitESP then pcall(DevEsp); end;
			if IslandESP then pcall(LocationEsp); end;
			if FlowerESP then pcall(flowerEsp); end;
			if LegenS then pcall(LegenSword); end;
			if ColorEsp then pcall(HakiClorEsp); end;
			if ESPGear then pcall(gearEsp); end;
			if EspEventIsland then pcall(EventIslandEsp); end;
			if advanEsp then pcall(AdvanFruitEsp); end;
		end;
	end;
end);
local Iq = UI.Sections["Travel - Worlds"];
Iq:AddButton({ Text = "Travel East Blue (World 1)", Func = function()
		BFComm("TravelMain");
	end });
Iq:AddButton({ Text = "Travel Dressrosa (World 2)", Func = function()
		BFComm("TravelDressrosa");
	end });
Iq:AddButton({ Text = "Travel Zou (World 3)", Func = function()
		BFComm("TravelZou");
	end });
local Wq = UI.Sections["Travel - Island"];
Location = {};
for Y, d in pairs(BFWorldLocationChildren()) do
	table.insert(Location, d.Name);
end;
table.sort(Location);
Wq:AddDropdown("BF_Dropdown_Select_Travelling", {
	Text = "Select Travelling",
	Tooltip = "",
	Values = Location,
	Default = Location[1],
	Multi = false,
	Callback = function(Y)
		_G.Island = Y;
	end,
});
Wq:AddToggle("BF_Toggle_Auto_Travel", {
	Text = "Auto Travel",
	Tooltip = "Automatic teleport to pos island",
	Default = false,
	Callback = function(Y)
		_G.Teleport = Y;
		if Y then
			task.spawn(function()
				local locations = BFWorldLocations();
				for Y, d in pairs(locations and locations:GetChildren() or {}) do
					if d.Name == _G.Island then
						repeat
							task.wait();
						until not _G.Teleport or not d.Parent or BFMoveNear(d.CFrame * CFrame.new(0, 30, 0), 8);
					end;
				end;
			end);
		end;
	end,
});
local Nq = UI.Sections["Travel - Portal"];
if World1 then
	Location_Portal = { "Sky", "UnderWater" };
elseif World2 then
	Location_Portal = { "SwanRoom", "Cursed Ship" };
elseif World3 then
	Location_Portal = {
			"Castle On The Sea",
			"Mansion Cafe",
			"Hydra Teleport",
			"Beautiful Pirate Room",
			"Temple of Time",
		};
end;
Nq:AddDropdown("BF_Dropdown_Select_Portal", {
	Text = "Select Portal",
	Tooltip = "",
	Values = Location_Portal,
	Default = Location_Portal and Location_Portal[1],
	Multi = false,
	Callback = function(Y)
		_G.Island_PT = Y;
	end,
});
Nq:AddButton({ Text = "requestEntrance", Func = function()
		if _G.Island_PT == "Sky" then
			BFComm("requestEntrance", Vector3.new(-7894, 5547, -380));
		elseif _G.Island_PT == "UnderWater" then
			BFComm("requestEntrance", Vector3.new(61163, 11, 1819));
		elseif _G.Island_PT == "SwanRoom" then
			BFComm("requestEntrance", Vector3.new(2285, 15, 905));
		elseif _G.Island_PT == "Cursed Ship" then
			BFComm("requestEntrance", Vector3.new(923, 126, 32852));
		elseif _G.Island_PT == "Castle On The Sea" then
			BFComm("requestEntrance", Vector3.new(-5097.93164, 316.447021, -3142.66602));
		elseif _G.Island_PT == "Mansion Cafe" then
			BFComm("requestEntrance", Vector3.new(-12471.169921875, 374.94024658203, -7551.677734375));
		elseif _G.Island_PT == "Hydra Teleport" then
			BFComm("requestEntrance", Vector3.new(5643.4526367188, 1013.0858154297, -340.51025390625));
		elseif _G.Island_PT == "Beautiful Pirate Room" then
			BFComm("requestEntrance", Vector3.new(5314.5463867188, 22.562219619751, -127.06755065918));
		elseif _G.Island_PT == "Temple of Time" then
			BFComm("requestEntrance", Vector3.new(28310.0234, 14895.1123, 109.456741));
		end;
	end });
local Dq = UI.Sections["Travel - NPCs"];
BFNpcNames = {};
BFFindNpc = function(name)
		for _, container in ipairs({ workspace:FindFirstChild("NPCs"), Q:FindFirstChild("NPCs") }) do
			local npc = container and container:FindFirstChild(name);
			if npc then
				local root = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart or npc:FindFirstChildWhichIsA("BasePart", true);
				if root then
					return npc, root;
				end;
			end;
		end;
	end;
BFFindNpcLike = function(fragment)
		fragment = string.lower(tostring(fragment or ""));
		for _, container in ipairs({ workspace:FindFirstChild("NPCs"), Q:FindFirstChild("NPCs") }) do
			for _, npc in ipairs(container and container:GetChildren() or {}) do
				if string.find(string.lower(npc.Name), fragment, 1, true) then
					local root = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart or npc:FindFirstChildWhichIsA("BasePart", true);
					if root then
						return npc, root;
					end;
				end;
			end;
		end;
	end;
for _, container in ipairs({ workspace:FindFirstChild("NPCs"), Q:FindFirstChild("NPCs") }) do
	for _, npc in ipairs(container and container:GetChildren() or {}) do
		local name = tostring(npc.Name or "");
		if name:match("%S") and not BFNpcNames[name] then
			BFNpcNames[name] = true;
			table.insert(m, name);
	end;
end;
end;
table.sort(m);
Dq:AddDropdown("BF_Dropdown_Select_NPCs", {
	Text = "Select NPCs",
	Tooltip = "",
	Values = m,
	Default = m[1],
	Multi = false,
	Callback = function(Y)
		NPClist = Y;
	end,
});
Dq:AddToggle("BF_Toggle_Auto_Tween_to_NPCs", {
	Text = "Auto Tween to NPCs",
	Tooltip = "Automatic teleport to pos Npcs",
	Default = false,
	Callback = function(Y)
		_G.TPNpc = Y;
	end,
});
task.spawn(function()
	while IdleWait(_G.TPNpc, T) do
		if _G.TPNpc then
			pcall(function()
				local npc, root = BFFindNpc(NPClist);
				if npc and root then
					_tp(root.CFrame);
				end;
			end);
		end;
	end;
end);
local Aq = UI.Sections["Fruits Options"];
local uq = {};
local mirageStock = BFComm("GetFruits", true);
if type(mirageStock) == "table" then
	for _, fruit in pairs(mirageStock) do
		if fruit.OnSale == true and fruit.Name then
			table.insert(uq, fruit.Name);
		end;
	end;
end;
table.sort(uq);
local zq = {};
local basicStock = BFComm("GetFruits", false);
if type(basicStock) == "table" then
	for _, fruit in pairs(basicStock) do
		if fruit.OnSale == true and fruit.Name then
			table.insert(zq, fruit.Name);
		end;
	end;
end;
table.sort(zq);
Aq:AddDropdown("BF_Dropdown_Select_Fruit_Stock", {
	Text = "Select Fruit Stock",
	Tooltip = "",
	Values = zq,
	Default = zq[1],
	Multi = false,
	Callback = function(Y)
		_G.SelectFruit = Y;
	end,
});
Aq:AddButton({ Text = "Buy Basic Stock", Func = function()
		BFComm("PurchaseRawFruit", _G.SelectFruit);
	end });
Aq:AddDropdown("BF_Dropdown_Select_Mirage_Fruit", {
	Text = "Select Mirage Fruit",
	Tooltip = "",
	Values = uq,
	Default = uq[1],
	Multi = false,
	Callback = function(Y)
		SelectF_Adv = Y;
	end,
});
Aq:AddButton({ Text = "Buy Mirage Stock", Func = function()
		BFComm("PurchaseRawFruit", SelectF_Adv);
	end });
Aq:AddToggle("BF_Toggle_Auto_Random_Fruit", {
	Text = "Auto Random Fruit",
	Tooltip = "Automatic random devil fruit",
	Default = false,
	Callback = function(Y)
		_G.Random_Auto = Y;
	end,
});
task.spawn(function()
	while IdleWait(_G.Random_Auto, 1) do
		pcall(function()
			if _G.Random_Auto then
				BFComm("Cousin", "Buy");
			end;
		end);
	end;
end);
Aq:AddToggle("BF_Toggle_Auto_Drop_Fruit", {
	Text = "Auto Drop Fruit",
	Tooltip = "Automatic drop devil fruit",
	Default = false,
	Callback = function(Y)
		_G.DropFruit = Y;
	end,
});
task.spawn(function()
	while IdleWait(_G.DropFruit, .5) do
		if _G.DropFruit then
			pcall(function()
				DropFruits();
			end);
		end;
	end;
end);
Aq:AddToggle("BF_Toggle_Auto_Store_Fruit", {
	Text = "Auto Store Fruit",
	Tooltip = "Automatic store devil fruit",
	Default = false,
	Callback = function(Y)
		_G.StoreF = Y;
	end,
});
task.spawn(function()
	while IdleWait(_G.StoreF, .5) do
		if _G.StoreF then
			pcall(function()
				UpdStFruit();
			end);
		end;
	end;
end);
Aq:AddToggle("BF_Toggle_Auto_Tween_to_Fruit", {
	Text = "Auto Tween to Fruit",
	Tooltip = "Automatic tween to get devil fruit",
	Default = false,
	Callback = function(Y)
		_G.TwFruits = Y;
	end,
});
task.spawn(function()
	while IdleWait(_G.TwFruits, .2) do
		if _G.TwFruits then
			pcall(function()
				local handle = BFFindWorldFruit(true);
				if handle then
					_tp(handle.CFrame);
				end;
			end);
		end;
	end;
end);
Aq:AddToggle("BF_Toggle_Auto_Collect_Fruit", {
	Text = "Auto Collect Fruit",
	Tooltip = "Automatic bring devil fruit",
	Default = false,
	Callback = function(Y)
		_G.InstanceF = Y;
	end,
});
task.spawn(function()
	while IdleWait(_G.InstanceF, .2) do
		if _G.InstanceF then
			pcall(function()
				collectFruits(_G.InstanceF);
			end);
		end;
	end;
end);
local Uq = UI.Sections["Shop Options"];
Uq:AddButton({ Text = "Buy Buso", Func = function()
		BFComm("BuyHaki", "Buso");
	end });
Uq:AddButton({ Text = "Buy Geppo", Func = function()
		BFComm("BuyHaki", "Geppo");
	end });
Uq:AddButton({ Text = "Buy Soru", Func = function()
		BFComm("BuyHaki", "Soru");
	end });
Uq:AddButton({ Text = "Buy Ken", Func = function()
		BFComm("KenTalk", "Buy");
	end });
local Cq = UI.Sections["Fighting - Style"];
Cq:AddButton({ Text = "Buy Black Leg", Func = function()
		BFComm("BuyBlackLeg");
	end });
Cq:AddButton({ Text = "Buy Electro", Func = function()
		BFComm("BuyElectro");
	end });
Cq:AddButton({ Text = "Buy Fishman Karate", Func = function()
		BFComm("BuyFishmanKarate");
	end });
Cq:AddButton({ Text = "Buy DragonClaw", Func = function()
		BFComm("BlackbeardReward", "DragonClaw", "2");
	end });
Cq:AddButton({ Text = "Buy Superhuman", Func = function()
		BFComm("BuySuperhuman");
	end });
Cq:AddButton({ Text = "Buy Death Step", Func = function()
		BFComm("BuyDeathStep");
	end });
Cq:AddButton({ Text = "Buy Sharkman Karate", Func = function()
		BFComm("BuySharkmanKarate");
	end });
Cq:AddButton({ Text = "Buy ElectricClaw", Func = function()
		BFComm("BuyElectricClaw");
	end });
Cq:AddButton({ Text = "Buy DragonTalon", Func = function()
		BFComm("BuyDragonTalon");
	end });
Cq:AddButton({ Text = "Buy Godhuman", Func = function()
		BFComm("BuyGodhuman");
	end });
Cq:AddButton({ Text = "Buy SanguineArt", Func = function()
		BFComm("BuySanguineArt");
	end });
local vq = UI.Sections["Accessory"];
vq:AddButton({ Text = "Buy Tomoe Ring", Func = function()
		BFComm("BuyItem", "Tomoe Ring");
	end });
vq:AddButton({ Text = "Buy Black Cape", Func = function()
		BFComm("BuyItem", "Black Cape");
	end });
vq:AddButton({ Text = "Buy Swordsman Hat", Func = function()
		BFComm("BuyItem", "Swordsman Hat");
	end });
vq:AddButton({ Text = "Buy Bizarre Rifle", Func = function()
		BFComm("Ectoplasm", "Buy", 1);
	end });
vq:AddButton({ Text = "Buy Ghoul Mask", Func = function()
		BFComm("Ectoplasm", "Buy", 2);
	end });
local mq = UI.Sections["Accessory SeaEvent"];
mq:AddButton({ Text = "Craft Dragonheart", Func = function()
		BFComm("CraftItem", "Craft", "Dragonheart");
	end });
mq:AddButton({ Text = "Craft Dragonstorm", Func = function()
		BFComm("CraftItem", "Craft", "Dragonstorm");
	end });
mq:AddButton({ Text = "Craft DinoHood", Func = function()
		BFComm("CraftItem", "Craft", "DinoHood");
	end });
mq:AddButton({ Text = "Craft SharkTooth", Func = function()
		BFComm("CraftItem", "Craft", "SharkTooth");
	end });
mq:AddButton({ Text = "Craft TerrorJaw", Func = function()
		BFComm("CraftItem", "Craft", "TerrorJaw");
	end });
mq:AddButton({ Text = "Craft SharkAnchor", Func = function()
		BFComm("CraftItem", "Craft", "SharkAnchor");
	end });
mq:AddButton({ Text = "Craft LeviathanCrown", Func = function()
		BFComm("CraftItem", "Craft", "LeviathanCrown");
	end });
mq:AddButton({ Text = "Craft LeviathanShield", Func = function()
		BFComm("CraftItem", "Craft", "LeviathanShield");
	end });
mq:AddButton({ Text = "Craft LeviathanBoat", Func = function()
		BFComm("CraftItem", "Craft", "LeviathanBoat");
	end });
mq:AddButton({ Text = "Craft LegendaryScroll", Func = function()
		BFComm("CraftItem", "Craft", "LegendaryScroll");
	end });
mq:AddButton({ Text = "Craft MythicalScroll", Func = function()
		BFComm("CraftItem", "Craft", "MythicalScroll");
	end });
local yq = UI.Sections["Weapon World1"];
yq:AddButton({ Text = "Buy Cutlass", Func = function()
		BFComm("BuyItem", "Cutlass");
	end });
yq:AddButton({ Text = "Buy Katana", Func = function()
		BFComm("BuyItem", "Katana");
	end });
yq:AddButton({ Text = "Buy Iron Mace", Func = function()
		BFComm("BuyItem", "Iron Mace");
	end });
yq:AddButton({ Text = "Buy Duel Katana", Func = function()
		BFComm("BuyItem", "Duel Katana");
	end });
yq:AddButton({ Text = "Buy Triple Katana", Func = function()
		BFComm("BuyItem", "Triple Katana");
	end });
yq:AddButton({ Text = "Buy Pipe", Func = function()
		BFComm("BuyItem", "Pipe");
	end });
yq:AddButton({ Text = "Buy Dual-Headed Blade", Func = function()
		BFComm("BuyItem", "Dual-Headed Blade");
	end });
yq:AddButton({ Text = "Buy Bisento", Func = function()
		BFComm("BuyItem", "Bisento");
	end });
yq:AddButton({ Text = "Buy Soul Cane", Func = function()
		BFComm("BuyItem", "Soul Cane");
	end });
yq:AddButton({ Text = "Buy Slingshot", Func = function()
		BFComm("BuyItem", "Slingshot");
	end });
yq:AddButton({ Text = "Buy Musket", Func = function()
		BFComm("BuyItem", "Musket");
	end });
yq:AddButton({ Text = "Buy Dual Flintlock", Func = function()
		BFComm("BuyItem", "Dual Flintlock");
	end });
yq:AddButton({ Text = "Buy Flintlock", Func = function()
		BFComm("BuyItem", "Flintlock");
	end });
yq:AddButton({ Text = "Buy Refined Flintlock", Func = function()
		BFComm("BuyItem", "Refined Flintlock");
	end });
yq:AddButton({ Text = "Buy Cannon", Func = function()
		BFComm("BuyItem", "Cannon");
	end });
yq:AddButton({ Text = "Buy Kabucha", Func = function()
		BFComm("BlackbeardReward", "Slingshot", "2");
	end });
local bq = UI.Sections["Fragments shop"];
bq:AddButton({ Text = "Buy Refund Stats", Func = function()
		BFComm("BlackbeardReward", "Refund", "2");
	end });
bq:AddButton({ Text = "Buy Reroll Race", Func = function()
		BFComm("BlackbeardReward", "Reroll", "2");
	end });
bq:AddButton({ Text = "Buy Ghoul Race (2.5k)", Func = function()
		BFComm("Ectoplasm", " Change", 4);
	end });
bq:AddButton({ Text = "Buy Cyborg Race (2.5k)", Func = function()
		BFComm("CyborgTrainer", " Buy");
	end });
local cq = UI.Sections["Server - Function"];
cq:AddButton({ Text = "Rejoin Server", Func = function()
		(game:GetService("TeleportService")):Teleport(game.PlaceId, game.Players.LocalPlayer);
	end });
cq:AddButton({ Text = "Hop Server", Func = function()
		Hop();
	end });
cq:AddButton({ Text = "Hop to Lowest Players", Func = function()
		local Y = game:GetService("HttpService");
		local R = game:GetService("TeleportService");
		local Q = "https://games.roblox.com/v1/games/";
		local r = game.PlaceId;
		local a = Q .. (r .. "/servers/Public?sortOrder=Asc&limit=100");
		function ListServers(d)
			local R = game:HttpGet(a .. (d and "&cursor=" .. d or ""));
			return Y:JSONDecode(R);
		end;
		local w, F;
		repeat
			local Y = ListServers(F);
			w = Y.data[1];
			F = Y.nextPageCursor;
		until w;
		R:TeleportToPlaceInstance(r, w.id, d);
	end });
cq:AddButton({ Text = "Hop to Lowest Pings Server", Func = function()
		local Y = game:GetService("HttpService");
		local d = game:GetService("TeleportService");
		local R = game:GetService("Stats");
		local function Q(d, R)
			local Q = string.format("https://games.roblox.com/v1/games/%d/servers/Public?limit=%d", d, R);
			local r, a = pcall(function()
					return Y:JSONDecode(game:HttpGet(Q));
				end);
			if r and (a and a.data) then
				return a.data;
			end;
			return nil;
		end;
		local r = game.PlaceId;
		local a = 100;
		local w = Q(r, a);
		if not w then
			return;
		end;
		local F = w[1];
		for Y, d in pairs(w) do
			if d.ping < F.ping and d.maxPlayers > d.playing then
				F = d;
			end;
		end;
		local M = .5;
		task.wait(M);
		local K = 100;
		local n = R.Network.ServerStatsItem;
		local I = n["Data Ping"]:GetValueString();
		local W = tonumber(I:match("(%d+)"));
		if W >= K then
			d:TeleportToPlaceInstance(r, F.id);
		else

		end;
	end });
cq:AddInput("BF_Input_JobID", {
	Text = "JobID",
	Placeholder = "Type something...",
	Default = "",
	Numeric = false,
	Finished = true,
	Tooltip = "Join a specific Blox Fruits server instance",
	Callback = function(Y)
		_G.JobId = Y;
	end,
});
UI.Library:GiveSignal(d.OnTeleport:Connect(function(state)
	if state == Enum.TeleportState.Failed then
		local message = workspace:FindFirstChild("Message");
		if message then
			message:Destroy();
		end;
	end;
end));
cq:AddButton({ Text = "Teleport [Job ID]", Func = function()
		local browser = Q:FindFirstChild("__ServerBrowser");
		local jobId = tostring(_G.JobId or "");
		if browser and jobId ~= "" then
			pcall(browser.InvokeServer, browser, "teleport", jobId);
		end;
	end });
cq:AddButton({ Text = "Copy JobID", Func = function()
		if type(setclipboard) == "function" then
			setclipboard(tostring(game.JobId));
		end;
	end });
local Hq = UI.Sections["Player Gui / Others"];
Hq:AddButton({ Text = "Open Awakenings Expert", Func = function()
		SetGuiShown(true, "AwakeningToggler");
	end });
Hq:AddButton({ Text = "Open Title Selection", Func = function()
		BFComm("getTitles", true);
		SetGuiShown(true, "Titles");
	end });
UI.SetChatGuiDisabled = function(disabled)
	local starterGui = game:GetService("StarterGui");
	local textChatService = game:GetService("TextChatService");
	local coreGui = game:GetService("CoreGui");
	if disabled then
		if not UI.ChatGuiState then
			local state = {};
			local ok, enabled = pcall(function()
				return starterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Chat);
			end);
			if ok then
				state.CoreGuiChat = enabled;
			end;
			local function remember(name)
				local object = textChatService:FindFirstChild(name);
				if not object then
					pcall(function()
						object = textChatService[name];
					end);
				end;
				if object then
					local propertyOk, propertyValue = pcall(function()
						return object.Enabled;
					end);
					if propertyOk then
						state[name] = { Instance = object, Enabled = propertyValue };
					end;
				end;
			end;
			remember("ChatWindowConfiguration");
			remember("ChatInputBarConfiguration");
			remember("ChannelTabsConfiguration");
			local experienceChat = coreGui:FindFirstChild("ExperienceChat");
			if experienceChat and experienceChat:IsA("LayerCollector") then
				state.ExperienceChat = { Instance = experienceChat, Enabled = experienceChat.Enabled };
			end;
			UI.ChatGuiState = state;
		end;
		pcall(function()
			starterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false);
		end);
		for _, name in ipairs({ "ChatWindowConfiguration", "ChatInputBarConfiguration", "ChannelTabsConfiguration" }) do
			local entry = UI.ChatGuiState[name];
			if entry and entry.Instance and entry.Instance.Parent then
				pcall(function()
					entry.Instance.Enabled = false;
				end);
			end;
		end;
		local experienceChat = UI.ChatGuiState.ExperienceChat;
		if experienceChat and experienceChat.Instance and experienceChat.Instance.Parent then
			pcall(function()
				experienceChat.Instance.Enabled = false;
			end);
		end;
		return;
	end;
	local state = UI.ChatGuiState;
	UI.ChatGuiState = nil;
	if not state then
		return;
	end;
	if state.CoreGuiChat ~= nil then
		pcall(function()
			starterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, state.CoreGuiChat);
		end);
	end;
	for _, name in ipairs({ "ChatWindowConfiguration", "ChatInputBarConfiguration", "ChannelTabsConfiguration" }) do
		local entry = state[name];
		if entry and entry.Instance and entry.Instance.Parent then
			pcall(function()
				entry.Instance.Enabled = entry.Enabled;
			end);
		end;
	end;
	local experienceChat = state.ExperienceChat;
	if experienceChat and experienceChat.Instance and experienceChat.Instance.Parent then
		pcall(function()
			experienceChat.Instance.Enabled = experienceChat.Enabled;
		end);
	end;
end;
Hq:AddToggle("BF_Toggle_Disable_Chat_GUI", {
	Text = "Disable Chat GUI",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		_G.Rechat = Y;
		UI.SetChatGuiDisabled(Y);
	end,
});
Hq:AddToggle("BF_Toggle_Disable_Leader_Board_GUI", {
	Text = "Disable Leader Board GUI",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		ReLeader = Y;
		local starterGui = game:GetService("StarterGui");
		if ReLeader then
			if UI.PlayerListWasEnabled == nil then
				pcall(function()
					UI.PlayerListWasEnabled = starterGui:GetCoreGuiEnabled(Enum.CoreGuiType.PlayerList);
				end);
			end;
			starterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false);
		else
			starterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, UI.PlayerListWasEnabled ~= false);
			UI.PlayerListWasEnabled = nil;
		end;
	end,
});
Hq:AddButton({ Text = "Set Pirate Team", Func = function()
		Pirates();
	end });
Hq:AddButton({ Text = "Set Marine Team", Func = function()
		Marines();
	end });
Hq:AddToggle("BF_Toggle_Unlock_All_Portals", {
	Text = "Unlock All Portals",
	Tooltip = "unlocked portal for who doesn\'t defeat rip_indra",
	Default = false,
	Callback = function(Y)
		_G.PortalUnLock = Y;
		if Y and BFPortalState then
			BFPortalState.Targets = {};
			BFPortalState.ByKey = {};
			BFPortalState.Index = 1;
			BFPortalState.LastDiscovery = os.clock();
			BFPortalState.RequestedAt = 0;
			BFPortalState.RequestedKey = nil;
			BFPortalState.Current = nil;
		elseif type(BFCancelTween) == "function" then
			BFCancelTween();
		end;
	end,
});
BFPortalState = {
	Targets = {},
	ByKey = {},
	Index = 1,
	LastDiscovery = 0,
	RequestedAt = 0,
};
getgenv().BFPortalState = BFPortalState;
BFResolvePortalTargets = function()
	local now = os.clock();
	if now - BFPortalState.LastDiscovery < 1 then
		return BFPortalState.Targets;
	end;
	local map = workspace:FindFirstChild("Map");
	local discovered = {};
	local byKey = {};
	if map then
		for _, model in ipairs(map:GetDescendants()) do
			if model:IsA("Model") and string.match(model.Name, "^MapTeleport") then
				local hitbox = model:FindFirstChild("Hitbox", true);
				if hitbox and hitbox:IsA("BasePart") then
					local key = model:GetFullName();
					local record = {
						Key = key,
						Part = hitbox,
						Position = hitbox.Position,
					};
					byKey[key] = record;
					table.insert(discovered, record);
				end;
			end;
		end;
	end;
	table.sort(discovered, function(left, right)
		return left.Key < right.Key;
	end);
	BFPortalState.Targets = discovered;
	BFPortalState.ByKey = byKey;
	BFPortalState.LastDiscovery = now;
	return BFPortalState.Targets;
end;
getgenv().BFResolvePortalTargets = BFResolvePortalTargets;
UI.SmartTeleportState = {
	Busy = false,
	NextAt = 0,
	LastRoute = "direct",
};
BFSmartTeleport = function(target, root)
	if typeof(target) ~= "CFrame" or not root or not root.Parent then
		return false;
	end;
	local directDistance = (target.Position - root.Position).Magnitude;
	if directDistance <= 700 then
		return false;
	end;
	local state = UI.SmartTeleportState;
	local now = os.clock();
	if state.Busy or now < state.NextAt then
		return false;
	end;
	state.Busy = true;
	local ok, handled = pcall(function()
		local mapStash = Q:FindFirstChild("MapStash");
		local temple = mapStash and mapStash:FindFirstChild("Temple of Time");
		local templePart = BFFirstPart(temple);
		if World3 and templePart and (target.Position - templePart.Position).Magnitude <= 2500 and not BFIsInTemple() then
			local entered = TpTemple();
			if entered then
				local character = d.Character;
				local currentRoot = character and character:FindFirstChild("HumanoidRootPart");
				if currentRoot then
					BFCancelTween();
					currentRoot.CFrame = target;
					state.LastRoute = "temple";
					state.NextAt = os.clock() + 1;
					return true;
				end;
			end;
		end;
		local submergedLocation = BFWorldLocation("Submerged Island", true);
		local submergedPart = BFFirstPart(submergedLocation);
		local currentLocation = tostring(d:GetAttribute("CurrentLocation") or "");
		if World3 and submergedPart and (target.Position - submergedPart.Position).Magnitude <= 5000 and currentLocation ~= "Submerged Island" and currentLocation ~= "Sealed Cavern" then
			local _, submarineRoot = BFFindNpcLike("submarine");
			if submarineRoot then
				BFCancelTween();
				root.CFrame = submarineRoot.CFrame * CFrame.new(0, 0, 4);
				task.wait(.15);
				NetInvoke("RF/SubmarineWorkerSpeak", "TravelToSubmergedIsland");
				for _ = 1, 20 do
					task.wait(.1);
					currentLocation = tostring(d:GetAttribute("CurrentLocation") or "");
					if currentLocation == "Submerged Island" or currentLocation == "Sealed Cavern" then
						break;
					end;
				end;
				local character = d.Character;
				local currentRoot = character and character:FindFirstChild("HumanoidRootPart");
				if currentRoot then
					BFCancelTween();
					currentRoot.CFrame = target;
					state.LastRoute = "submarine";
					state.NextAt = os.clock() + 1;
					return true;
				end;
			end;
		end;
		local best;
		local bestTargetDistance = math.huge;
		for _, record in ipairs(BFResolvePortalTargets()) do
			local endpointDistance = (target.Position - record.Position).Magnitude;
			if endpointDistance < bestTargetDistance then
				best = record;
				bestTargetDistance = endpointDistance;
			end;
		end;
		if best and bestTargetDistance + 800 < directDistance then
			BFComm("requestEntrance", best.Position);
			task.wait(.4);
			local character = d.Character;
			local currentRoot = character and character:FindFirstChild("HumanoidRootPart");
			if currentRoot then
				BFCancelTween();
				currentRoot.CFrame = target;
				state.LastRoute = "map-portal";
				state.NextAt = os.clock() + 1;
				return true;
			end;
		end;
		return false;
	end);
	state.Busy = false;
	if not ok then
		state.LastRoute = "error";
		state.NextAt = os.clock() + 1;
		return false;
	end;
	return handled == true;
end;
getgenv().BFSmartTeleport = BFSmartTeleport;
BFPortalStep = function(active)
	if not active then
		return;
	end;
	local character = d.Character;
	local root = character and character:FindFirstChild("HumanoidRootPart");
	if not root then
		return;
	end;
	local targets = BFResolvePortalTargets();
	if #targets == 0 then
		return;
	end;
	if BFPortalState.Index > #targets then
		if os.clock() - BFPortalState.LastDiscovery < 3 then
			return;
		end;
		BFPortalState.Index = 1;
		BFPortalState.Current = nil;
		local toggle = UI.Library.Toggles.BF_Toggle_Unlock_All_Portals;
		if toggle and toggle.Value then
			toggle:SetValue(false);
		end;
		UI.Library:Notify("Portal route completed.", 4);
		return;
	end;
	local record = targets[BFPortalState.Index];
	local target = record.Part;
	if target and target.Parent then
		record.Position = target.Position;
	else
		target = nil;
	end;
	BFPortalState.Current = record.Key;
	local distance = (root.Position - record.Position).Magnitude;
	if distance > 8 then
		local now = os.clock();
		if BFPortalState.RequestedKey ~= record.Key or now - BFPortalState.RequestedAt >= 1.5 then
			BFPortalState.RequestedKey = record.Key;
			BFPortalState.RequestedAt = now;
			BFComm("requestEntrance", record.Position);
			task.wait(.4);
		end;
		character = d.Character;
		root = character and character:FindFirstChild("HumanoidRootPart");
		if root and (root.Position - record.Position).Magnitude > 8 then
			BFCancelTween();
			root.CFrame = CFrame.new(record.Position + Vector3.new(0, 3, 0));
		end;
		return;
	end;
	if target then
		if type(firetouchinterest) == "function" then
			pcall(firetouchinterest, root, target, 0);
			task.wait(.1);
			pcall(firetouchinterest, root, target, 1);
		end;
	end;
	BFPortalState.Index = BFPortalState.Index + 1;
	BFPortalState.RequestedAt = 0;
	BFPortalState.RequestedKey = nil;
	task.wait(.35);
end;
getgenv().BFPortalStep = BFPortalStep;
task.spawn(function()
	while IdleWait(_G.PortalUnLock, .2) do
		if _G.PortalUnLock then
			pcall(BFPortalStep, _G.PortalUnLock);
		end;
	end;
end);
local Sq = UI.Sections["Graphics / Haki Stats"];
UI.StopRTX = function()
	local state = UI.RTXState;
	if not state then
		return;
	end;
	UI.RTXState = nil;
	F.Ambient = state.Ambient;
	F.Brightness = state.Brightness;
	F.ColorShift_Top = state.ColorShiftTop;
	F.FogEnd = state.FogEnd;
	if state.Effect and state.Effect.Parent then
		state.Effect:Destroy();
	end;
	for light in pairs(state.Lights or {}) do
		if light.Parent then
			light:Destroy();
		end;
	end;
end;
HakiSt = {
		"State 0",
		"State 1",
		"State 2",
		"State 3",
		"State 4",
		"State 5",
	};
Sq:AddDropdown("BF_Dropdown_Select_Haki_States", {
	Text = "Select Haki States",
	Tooltip = "",
	Values = HakiSt,
	Default = "State 0",
	Multi = false,
	Callback = function(Y)
		_G.SelectStateHaki = Y;
	end,
});
Sq:AddButton({ Text = "ChangeBusoStage", Func = function()
		if _G.SelectStateHaki == "State 0" then
			BFComm("ChangeBusoStage", 0);
		elseif _G.SelectStateHaki == "State 1" then
			BFComm("ChangeBusoStage", 1);
		elseif _G.SelectStateHaki == "State 2" then
			BFComm("ChangeBusoStage", 2);
		elseif _G.SelectStateHaki == "State 3" then
			BFComm("ChangeBusoStage", 3);
		elseif _G.SelectStateHaki == "State 4" then
			BFComm("ChangeBusoStage", 4);
		elseif _G.SelectStateHaki == "State 5" then
			BFComm("ChangeBusoStage", 5);
		end;
	end });
Sq:AddToggle("BF_Toggle_Turn_on_RTX_Mode", {
	Text = "Turn on RTX Mode",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		_G.RTXMode = Y;
		if not Y then
			UI.StopRTX();
			return;
		end;
		UI.StopRTX();
		local state = {
			Ambient = F.Ambient,
			Brightness = F.Brightness,
			ColorShiftTop = F.ColorShift_Top,
			FogEnd = F.FogEnd,
			Lights = {},
		};
		local effect = Instance.new("ColorCorrectionEffect");
		effect.Name = "BF_RTX_ColorCorrection";
		effect.Parent = F;
		state.Effect = effect;
		UI.RTXState = state;
		task.spawn(function()
			while _G.RTXMode and UI.RTXState == state do
				task.wait();
				if not _G.RTXMode or UI.RTXState ~= state then
					break;
				end;
				F.Ambient = Color3.fromRGB(33, 33, 33);
				F.Brightness = .3;
				effect.Brightness = .176;
				effect.Contrast = .39;
				effect.TintColor = Color3.fromRGB(217, 145, 57);
				F.FogEnd = 999;
				local character = d.Character;
				local root = character and character:FindFirstChild("HumanoidRootPart");
				if root and not root:FindFirstChild("BF_RTX_PointLight") then
					local light = Instance.new("PointLight");
					light.Name = "BF_RTX_PointLight";
					light.Parent = root;
					light.Range = 15;
					light.Color = Color3.fromRGB(217, 145, 57);
					state.Lights[light] = true;
				end;
			end;
			if UI.RTXState == state then
				UI.StopRTX();
			end;
		end);
	end,
});
Sq:AddButton({ Text = "Turn on increase Boats", Func = function()
		local boats = workspace:FindFirstChild("Boats");
		if not boats then
			return;
		end;
		for _, boat in pairs(boats:GetDescendants()) do
			if table.find(jF, boat.Name) then
				local owner = boat:FindFirstChild("Owner");
				local seat = boat:FindFirstChild("VehicleSeat", true);
				if owner and owner:IsA("ValueBase") and tostring(owner.Value) == tostring(d.Name) and seat and seat:IsA("VehicleSeat") then
					seat.MaxSpeed = 350;
					seat.Torque = .2;
					seat.TurnSpeed = 5;
					seat.HeadsUpDisplay = true;
				end;
			end;
		end;
	end });
Sq:AddButton({ Text = "Remove Sky Fog", Func = function()
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
local oq = UI.Sections["Configure - God"];
oq:AddButton({ Text = "Rain Fruits (Client)", Func = function()
		local objects = game:GetObjects("rbxassetid://14759368201");
		local source = objects and objects[1];
		local character = d.Character;
		local primary = character and character.PrimaryPart;
		if not source or not primary then
			return;
		end;
		for _, fruitTool in pairs(source:GetChildren()) do
			fruitTool.Parent = workspace:FindFirstChild("Map") or workspace;
			fruitTool:MoveTo(primary.Position + Vector3.new(math.random(-50, 50), 100, math.random(-50, 50)));
			local fruit = fruitTool:FindFirstChild("Fruit");
			local controller = fruit and fruit:FindFirstChild("AnimationController");
			local idle = fruit and fruit:FindFirstChild("Idle");
			if controller and idle then
				pcall(function()
					controller:LoadAnimation(idle):Play();
				end);
			end;
			local handle = fruitTool:FindFirstChild("Handle");
			if handle then
				handle.Touched:Connect(function(hit)
					if hit.Parent == d.Character then
						local backpack = d:FindFirstChild("Backpack");
						if not backpack then
							return;
						end;
						fruitTool.Parent = backpack;
						local humanoid = BFHumanoid();
						if humanoid then
							humanoid:EquipTool(fruitTool);
						end;
					end;
				end);
			end;
		end;
	end });
oq:AddToggle("BF_Toggle_Turn_on_Full_Bright", { Text = "Turn on Full Bright", Default = false, Callback = function(Y)
		bright = Y;
		if Y then
			if not UI.FullBrightOriginal then
				UI.FullBrightOriginal = {
					Ambient = F.Ambient,
					ColorShiftBottom = F.ColorShift_Bottom,
					ColorShiftTop = F.ColorShift_Top,
				};
			end;
			F.Ambient = Color3.new(1, 1, 1);
			F.ColorShift_Bottom = Color3.new(1, 1, 1);
			F.ColorShift_Top = Color3.new(1, 1, 1);
		elseif UI.FullBrightOriginal then
			F.Ambient = UI.FullBrightOriginal.Ambient;
			F.ColorShift_Bottom = UI.FullBrightOriginal.ColorShiftBottom;
			F.ColorShift_Top = UI.FullBrightOriginal.ColorShiftTop;
			UI.FullBrightOriginal = nil;
		end;
	end });
Cheat_DayNight = { "Day", "Night" };
oq:AddDropdown("BF_Dropdown_Select_Time", {
	Text = "Select Time",
	Tooltip = "",
	Values = Cheat_DayNight,
	Default = "Day",
	Multi = false,
	Callback = function(Y)
		_G.SelectDN = Y;
	end,
});
oq:AddToggle("BF_Toggle_Turn_on_Time", {
	Text = "Turn on Time",
	Tooltip = "",
	Default = false,
	Callback = function(Y)
		_G.daylightN = Y;
		if Y and UI.TimeOriginal == nil then
			UI.TimeOriginal = F.ClockTime;
			if _G.SelectDN == "Day" then
				F.ClockTime = 12;
			elseif _G.SelectDN == "Night" then
				F.ClockTime = 0;
			end;
		elseif not Y and UI.TimeOriginal ~= nil then
			F.ClockTime = UI.TimeOriginal;
			UI.TimeOriginal = nil;
		end;
	end,
});
task.spawn(function()
	while IdleWait(_G.daylightN, .1) do
		if _G.daylightN then
			if _G.SelectDN == "Day" then
				F.ClockTime = 12;
			elseif _G.SelectDN == "Night" then
				F.ClockTime = 0;
			end;
		end;
	end;
end);
oq:AddToggle("BF_Toggle_Turn_on_Walk_on_Water", {
	Text = "Turn on Walk on Water",
	Tooltip = "walk on water",
	Default = false,
	Callback = function(Y)
		_G.WalkWater_Part = Y;
		local map = workspace:FindFirstChild("Map");
		local plane = map and map:FindFirstChild("WaterBase-Plane", true);
		if not plane then
			return;
		end;
		if _G.WalkWater_Part then
			UI.WaterPlaneOriginalSize = UI.WaterPlaneOriginalSize or plane.Size;
			plane.Size = Vector3.new(1000, 112, 1000);
		elseif UI.WaterPlaneOriginalSize then
			plane.Size = UI.WaterPlaneOriginalSize;
			UI.WaterPlaneOriginalSize = nil;
		end;
	end,
});
UI.IceWalkParts = setmetatable({}, { __mode = "k" });
function UI.ClearIceWalkParts()
	for part in pairs(UI.IceWalkParts) do
		if part.Parent then
			part:Destroy();
		end;
		UI.IceWalkParts[part] = nil;
	end;
end;
oq:AddToggle("BF_Toggle_Turn_on_Ice_Walk", {
	Text = "Turn on Ice Walk",
	Tooltip = "Ice walk just like walk on water but have ice effect",
	Default = false,
	Callback = function(Y)
		_G.WalkWater = Y;
		if not Y then
			UI.ClearIceWalkParts();
		end;
	end,
});
task.spawn(function()
	while IdleWait(_G.WalkWater, 0.1) do
		if _G.WalkWater then
			pcall(function()
				local character = d.Character;
				local foot = character and character:FindFirstChild("LeftFoot");
				if foot then
					local template = Q:FindFirstChild("IceSpikes4", true);
					if template and not template:IsA("BasePart") then
						template = template:FindFirstChildWhichIsA("BasePart", true);
					end;
					local Y = template and template:Clone() or Instance.new("Part");
					Y.Name = "BF_IceWalk";
					Y.Anchored = true;
					Y.CanCollide = true;
					Y.CanTouch = false;
					Y.CanQuery = false;
					Y.CastShadow = false;
					Y.Material = Enum.Material.Ice;
					Y.Transparency = .15;
					Y.Size = Vector3.new(3 + math.random(10, 12), 1.7, 3 + math.random(10, 12));
					Y.Color = Color3.fromRGB(128, 187, 219);
					Y.CFrame = CFrame.new(foot.Position.X, foot.Position.Y - foot.Size.Y * .5 - .85, foot.Position.Z) * CFrame.Angles((math.random() - .5) * .06, math.random() * 7, (math.random() - .5) * .07);
					Y.Parent = workspace;
					UI.IceWalkParts[Y] = true;
					local R = {};
					R.Size = Vector3.new(0, .3, 0);
					R.Transparency = 1;
					local r = w:Create(Y, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), R);
					r.Completed:Connect(function()
						UI.IceWalkParts[Y] = nil;
						if Y.Parent then
							Y:Destroy();
						end;
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
local function kq(Y, d, includePlayers)
	local enemies = M;
	if not enemies or not enemies.Parent then
		enemies = workspace:FindFirstChild("Enemies");
		M = enemies;
	end;
	local results = {};
	local origin = Y:GetPivot().Position;
	for _, enemy in ipairs(enemies and enemies:GetChildren() or {}) do
		local root = enemy:FindFirstChild("HumanoidRootPart");
		if root and Tq(enemy) then
			local distance = (root.Position - origin).Magnitude;
			if distance <= d then
				results[#results + 1] = enemy;
			end;
		end;
	end;
	if includePlayers == true then
		for _, player in ipairs(A:GetPlayers()) do
			local character = player ~= Zq and player.Character;
			if character then
				local root = character:FindFirstChild("HumanoidRootPart");
				if root and Tq(character) then
					local distance = (root.Position - origin).Magnitude;
					if distance <= d then
						results[#results + 1] = character;
					end;
				end;
			end;
		end;
	end;
	return results;
end;
UI.AttackHitPartNames = {
	"RightLowerArm",
	"RightUpperArm",
	"LeftLowerArm",
	"LeftUpperArm",
	"RightHand",
	"LeftHand",
};
UI.AttackRemoteCache = nil;
BFResolveAttackRemotes = function()
	local cache = UI.AttackRemoteCache;
	if cache and cache.RegisterAttack.Parent and cache.RegisterHit.Parent then
		return cache.RegisterAttack, cache.RegisterHit, cache.RemoteThread;
	end;
	local modules = Q:FindFirstChild("Modules");
	local net = modules and modules:FindFirstChild("Net");
	local registerAttack = net and net:FindFirstChild("RE/RegisterAttack");
	local registerHit = net and net:FindFirstChild("RE/RegisterHit");
	if not registerAttack or not registerHit then
		UI.AttackRemoteCache = nil;
		return nil;
	end;
	local remoteThread = false;
	local flags = modules:FindFirstChild("Flags");
	if flags then
		local ok, values = pcall(require, flags);
		if ok and type(values) == "table" then
			remoteThread = values.COMBAT_REMOTE_THREAD == true;
		end;
	end;
	cache = {
		RegisterAttack = registerAttack,
		RegisterHit = registerHit,
		RemoteThread = remoteThread,
	};
	UI.AttackRemoteCache = cache;
	return registerAttack, registerHit, remoteThread;
end;
local AttackSender = nil;
local AttackSenderSearchAt = 0;
local function ResolveAttackSender()
	if type(AttackSender) == "function" then
		return AttackSender;
	end;
	if type(getsenv) ~= "function" or os.clock() < AttackSenderSearchAt then
		return nil;
	end;
	AttackSenderSearchAt = os.clock() + 5;
	local playerScripts = d:FindFirstChild("PlayerScripts");
	if not playerScripts then
		return nil;
	end;
	for _, localScript in ipairs(playerScripts:GetDescendants()) do
		if localScript:IsA("LocalScript") then
			local ok, environment = pcall(getsenv, localScript);
			if ok and type(environment) == "table" then
				local environmentGlobal = rawget(environment, "_G");
				local sender = type(environmentGlobal) == "table" and rawget(environmentGlobal, "SendHitsToServer") or rawget(environment, "SendHitsToServer");
				if type(sender) == "function" then
					AttackSender = sender;
					return sender;
				end;
			end;
		end;
	end;
	return nil;
end;
function AttackNoCoolDown(includePlayers)
	local character = d.Character;
	if not character then
		return;
	end;
	local tool = character:FindFirstChildOfClass("Tool");
	if not tool then
		return;
	end;
	local hitRadius = getgenv().BFMultiHit ~= false and math.clamp(tonumber(getgenv().BFMultiHitRadius) or 80, 30, 150) or 60;
	local targets = kq(character, hitRadius, includePlayers);
	if #targets == 0 then
		return;
	end;
	local registerAttack, registerHit, remoteThread = BFResolveAttackRemotes();
	if not registerAttack or not registerHit then
		return;
	end;
	local hits = {};
	local primaryHit;
	local names = UI.AttackHitPartNames;
	for _, target in ipairs(targets) do
		if not target:GetAttribute("IsBoat") then
			local hitPart = target:FindFirstChild(names[math.random(#names)]) or target.PrimaryPart or target:FindFirstChild("HumanoidRootPart");
			if hitPart then
				hits[#hits + 1] = { target, hitPart };
				primaryHit = hitPart;
			end;
		end;
	end;
	if not primaryHit then
		return;
	end;
	pcall(registerAttack.FireServer, registerAttack, 0);
	local sent = false;
	if remoteThread then
		local sender = ResolveAttackSender();
		if sender then
			sent = pcall(sender, primaryHit, hits);
		end;
	end;
	if not sent then
		pcall(registerHit.FireServer, registerHit, primaryHit, hits);
	end;
	pcall(tool.Activate, tool);
end;
CameraShakerR = require(game.ReplicatedStorage.Util.CameraShaker);
CameraShakerR:Stop();
get_Monster = function()
		local selfCharacter = d.Character;
		local selfRoot = selfCharacter and selfCharacter:FindFirstChild("HumanoidRootPart");
		if not selfRoot then
			return false;
		end;
		for _, R in pairs(workspace.Enemies:GetChildren()) do
			local Q = R:FindFirstChild("UpperTorso") or R:FindFirstChild("Head");
			if Q and R:FindFirstChild("HumanoidRootPart", true) then
				if (Q.Position - selfRoot.Position).Magnitude <= 50 then
					return true, Q.Position;
				end;
			end;
		end;
		local beasts = workspace:FindFirstChild("SeaBeasts");
		if beasts then
			for _, beast in pairs(beasts:GetChildren()) do
				local beastRoot = beast:FindFirstChild("HumanoidRootPart");
				local beastHealth = beast:FindFirstChild("Health");
				if beastRoot and beastHealth and beastHealth.Value > 0 then
					return true, beastRoot.Position;
				end;
			end;
		end;
		for Y, d in pairs(workspace.Enemies:GetChildren()) do
			if d:FindFirstChild("Health") and (d.Health.Value > 0 and d:FindFirstChild("VehicleSeat")) then
				return true, d.Engine.Position;
			end;
		end;
	end;
Actived = function()
		local character = d.Character;
		local tool = character and character:FindFirstChildOfClass("Tool");
		if not tool then
			return;
		end;
		for _, connection in next, getconnections(tool.Activated) do
			if typeof(connection.Function) == "function" then
				getupvalues(connection.Function);
			end;
		end;
	end;

UI.NextAttackAt = 0;
UI.AttackInterval = .075;
UI.Library:GiveSignal(W.Heartbeat:Connect(function()
	if UI.Stopped then
		return;
	end;
	pcall(function()
		local now = os.clock();
		if not _G.Seriality and not _G.Level and now >= BFAttackUntil then
			return;
		end;
		if now < UI.NextAttackAt then
			return;
		end;
		UI.NextAttackAt = now + UI.AttackInterval;
		local includePlayers = _G.Defeating == true or _G.AutoEvoRace == true or _G.Complete_Trials == true;
		AttackNoCoolDown(includePlayers);
		local character = d.Character;
		local tool = character and character:FindFirstChildOfClass("Tool");
		if not tool then
			return;
		end;
		local R = get_Monster();
		if tool.ToolTip == "Blox Fruit" and R then
			local remote = tool:FindFirstChild("LeftClickRemote");
			if remote then
				Actived();
				remote:FireServer(Vector3.new(.01, -500, .01), 1, true);
				remote:FireServer(false);
			end;
		end;
	end);
end));
UI.ThemeManager:SetLibrary(UI.Library);
UI.SaveManager:SetLibrary(UI.Library);
UI.SaveManager:IgnoreThemeSettings();
UI.SaveManager:SetIgnoreIndexes({ "MenuKeybind", "BF_Toggle_Allow_Bone_Spending" });
UI.ThemeManager:SetFolder("LuminTheme");
UI.SaveManager:SetFolder("LuminHub");
UI.SaveManager:SetSubFolder("BloxFruits");
function UI.GroupboxProxy(tab)
	local proxy = {};
	function proxy:AddLeftGroupbox()
		return tab;
	end;
	function proxy:AddRightGroupbox()
		return tab;
	end;
	return proxy;
end;
function UI.Safe(name, builder)
	local ok, err = pcall(builder);
	if not ok then
		task.spawn(function()
			UI.Library:Notify("Failed to build " .. tostring(name) .. ": " .. tostring(err), 10);
		end);
	end;
	return ok;
end;
function UI.TabOf(key)
	return UI.Sections[key];
end;
UI.Safe("Player Mods", function()
	local tab = UI.TabOf("BF/PlayerMods");
	if tab then
		tab:AddInputWithButtons("BF_SpeedJump", {
			Text = "WalkSpeed and JumpPower",
			LeftInput = {
				Default = "16",
				Placeholder = "Speed",
				Numeric = true,
				Finished = true,
				Callback = function(value)
					local humanoid = i and i:FindFirstChildOfClass("Humanoid");
					if humanoid then
						humanoid.WalkSpeed = tonumber(value) or 16;
					end;
				end,
			},
			RightInput = {
				Default = "50",
				Placeholder = "Jump",
				Numeric = true,
				Finished = true,
				Callback = function(value)
					local humanoid = i and i:FindFirstChildOfClass("Humanoid");
					if humanoid then
						humanoid.JumpPower = tonumber(value) or 50;
					end;
				end,
			},
		});
		local noclip = false;
		tab:AddToggle("BF_Noclip", {
			Text = "Noclip",
			Default = false,
			Tooltip = "Walk through parts",
			Callback = function(state)
				noclip = state;
				UI.SetCharacterCollisionOwner("Noclip", state);
			end,
		});
		task.spawn(function()
			while IdleWait(noclip, .2) do
				if noclip then
					UI.SetCharacterCollisionOwner("Noclip", true);
					UI.ReassertCharacterCollisions();
				end;
			end;
			UI.SetCharacterCollisionOwner("Noclip", false);
		end);
		local infiniteJump = false;
		tab:AddToggle("BF_InfiniteJump", {
			Text = "Infinite Jump",
			Default = false,
			Tooltip = "Jump without touching ground",
			Callback = function(state)
				infiniteJump = state;
			end,
		});
		UI.Library:GiveSignal((game:GetService("UserInputService")).JumpRequest:Connect(function()
			if not infiniteJump then
				return;
			end;
			local humanoid = i and i:FindFirstChildOfClass("Humanoid");
			if humanoid then
				humanoid:ChangeState(Enum.HumanoidStateType.Jumping);
			end;
		end));
	end;
end);
UI.Safe("Optimize", function()
	local tab = UI.TabOf("BF/Optimize");
	if tab then
		local fpsBoostState = nil;
		local fpsBoostKnown = setmetatable({}, { __mode = "k" });
		local function suppressFpsObject(state, object)
			if state ~= fpsBoostState or state.Original[object] then
				return;
			end;
			if object:IsA("PostEffect") or object:IsA("ParticleEmitter") or object:IsA("Trail") or object:IsA("Smoke") or object:IsA("Fire") or object:IsA("Sparkles") then
				state.Original[object] = { Property = "Enabled", Value = object.Enabled };
				fpsBoostKnown[object] = true;
				object.Enabled = false;
			elseif object:IsA("Decal") then
				state.Original[object] = { Property = "Transparency", Value = object.Transparency };
				fpsBoostKnown[object] = true;
				object.Transparency = 1;
			end;
		end;
		local function stopFpsBoost()
			local state = fpsBoostState;
			if not state then
				return;
			end;
			fpsBoostState = nil;
			for _, connection in ipairs(state.Connections) do
				connection:Disconnect();
			end;
			if state.Terrain and state.Terrain.Parent then
				pcall(function()
					state.Terrain.WaterWaveSize = state.WaterWaveSize;
					state.Terrain.WaterWaveSpeed = state.WaterWaveSpeed;
					state.Terrain.WaterReflectance = state.WaterReflectance;
				end);
			end;
			pcall(function()
				F.GlobalShadows = state.GlobalShadows;
				F.FogEnd = state.FogEnd;
			end);
			for object, original in pairs(state.Original) do
				if object.Parent then
					pcall(function()
						object[original.Property] = original.Value;
					end);
				end;
			end;
		end;
		local function startFpsBoost()
			if fpsBoostState then
				return;
			end;
			local terrain = workspace:FindFirstChildOfClass("Terrain");
			local state = {
				Terrain = terrain,
				WaterWaveSize = terrain and terrain.WaterWaveSize,
				WaterWaveSpeed = terrain and terrain.WaterWaveSpeed,
				WaterReflectance = terrain and terrain.WaterReflectance,
				GlobalShadows = F.GlobalShadows,
				FogEnd = F.FogEnd,
				Original = setmetatable({}, { __mode = "k" }),
				Connections = {},
			};
			fpsBoostState = state;
			if terrain then
				pcall(function()
					terrain.WaterWaveSize = 0;
					terrain.WaterWaveSpeed = 0;
					terrain.WaterReflectance = 0;
				end);
			end;
			F.GlobalShadows = false;
			F.FogEnd = 9e9;
			for object in pairs(fpsBoostKnown) do
				pcall(suppressFpsObject, state, object);
			end;
			table.insert(state.Connections, workspace.DescendantAdded:Connect(function(object)
				pcall(suppressFpsObject, state, object);
			end));
			table.insert(state.Connections, F.DescendantAdded:Connect(function(object)
				pcall(suppressFpsObject, state, object);
			end));
			task.spawn(function()
				local objects = workspace:GetDescendants();
				for index, object in ipairs(objects) do
					if fpsBoostState ~= state then
						return;
					end;
					pcall(suppressFpsObject, state, object);
					if index % 300 == 0 then
						task.wait();
					end;
				end;
				for _, object in ipairs(F:GetDescendants()) do
					if fpsBoostState ~= state then
						return;
					end;
					pcall(suppressFpsObject, state, object);
				end;
			end);
		end;
		tab:AddToggle("BF_FpsBoost", {
			Text = "FPS Boost",
			Default = false,
			Tooltip = "Strip effects and shadows",
			Callback = function(state)
				if state then
					startFpsBoost();
					UI.Library:Notify("FPS boost enabled.", 3);
				else
					stopFpsBoost();
					UI.Library:Notify("FPS boost off. Visuals restored.", 3);
				end;
			end,
		});
		local lowGraphics = false;
		local lowGraphicsOriginal = nil;
		tab:AddToggle("BF_LowGraphics", {
			Text = "Low Graphics",
			Default = false,
			Tooltip = "Force the lowest quality level",
			Callback = function(state)
				lowGraphics = state;
				pcall(function()
					local rendering = settings().Rendering;
					if state and not lowGraphicsOriginal then
						lowGraphicsOriginal = {
							QualityLevel = rendering.QualityLevel,
							MeshPartDetailLevel = rendering.MeshPartDetailLevel,
						};
					elseif not state and lowGraphicsOriginal then
						rendering.QualityLevel = lowGraphicsOriginal.QualityLevel;
						rendering.MeshPartDetailLevel = lowGraphicsOriginal.MeshPartDetailLevel;
						lowGraphicsOriginal = nil;
					end;
				end);
			end,
		});
		task.spawn(function()
			while IdleWait(lowGraphics, 1) do
				if lowGraphics then
					pcall(function()
						local rendering = settings().Rendering;
						rendering.QualityLevel = Enum.QualityLevel.Level01;
						rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level00;
					end);
				end;
			end;
		end);
		tab:AddToggle("BF_BlackScreen", {
			Text = "Black Screen",
			Default = false,
			Tooltip = "Hide rendering behind a black overlay",
			Callback = function(state)
				local existing = UI.BlackScreen;
				if existing and not existing.Parent then
					existing = nil;
					UI.BlackScreen = nil;
				end;
				if state then
					if not existing then
						local screen = Instance.new("ScreenGui");
						screen.Name = "BF_BlackScreen";
						screen.ResetOnSpawn = false;
						screen.IgnoreGuiInset = true;
						screen.DisplayOrder = UI.Library.ScreenGui.DisplayOrder - 1;
						local frame = Instance.new("Frame");
						frame.BackgroundColor3 = Color3.new(0, 0, 0);
						frame.Size = UDim2.fromScale(1, 1);
						frame.BorderSizePixel = 0;
						frame.Parent = screen;
						local uiParent = UI.Library.ScreenGui and UI.Library.ScreenGui.Parent;
						screen.Parent = uiParent or game:GetService("CoreGui");
						UI.BlackScreen = screen;
						if type(protectgui) == "function" then
							pcall(protectgui, screen);
						end;
					end;
				elseif existing then
					existing:Destroy();
					UI.BlackScreen = nil;
				end;
			end,
		});
	end;
end);
UI.Safe("Server Tools", function()
	local tab = UI.TabOf("BF/ServerTools");
	if tab then
		local jobInput = tab:AddInput("BF_JobIdInput", {
			Text = "Job ID",
			Default = "",
			Placeholder = "Paste a job id",
			Finished = true,
			Tooltip = "Target server id",
		});
		tab:AddButton({
			Text = "Join Job ID",
			Tooltip = "Teleport to that server",
			Func = function()
				local target = tostring(jobInput.Value or "");
				if target == "" then
					UI.Library:Notify("Enter a job id first.", 3);
					return;
				end;
				pcall(function()
					a:TeleportToPlaceInstance(game.PlaceId, target, d);
				end);
			end,
		});
		tab:AddButton({
			Text = "Rejoin Server",
			Tooltip = "Rejoin the current server instance",
			Func = function()
				UI.Library:Notify("Rejoining...", 3);
				pcall(function()
					a:TeleportToPlaceInstance(game.PlaceId, game.JobId, d);
				end);
			end,
		});
		tab:AddButton({
			Text = "Server Hop",
			Tooltip = "Find another public server",
			Func = function()
				task.spawn(function()
					local ok, body = pcall(function()
						return game:HttpGet("https://games.roblox.com/v1/games/" .. tostring(game.PlaceId) .. "/servers/Public?sortOrder=Asc&limit=100");
					end);
					if not ok then
						UI.Library:Notify("Could not fetch the server list.", 4);
						return;
					end;
					local decoded;
					ok, decoded = pcall(function()
						return (game:GetService("HttpService")):JSONDecode(body);
					end);
					if not ok or type(decoded) ~= "table" or type(decoded.data) ~= "table" then
						UI.Library:Notify("Server list was unreadable.", 4);
						return;
					end;
					for _, server in ipairs(decoded.data) do
						if type(server) == "table" and server.id ~= game.JobId and tonumber(server.playing or 0) < tonumber(server.maxPlayers or 0) then
							pcall(function()
								a:TeleportToPlaceInstance(game.PlaceId, server.id, d);
							end);
							return;
						end;
					end;
					UI.Library:Notify("No other server had room.", 4);
				end);
			end,
		});
	end;
end);
UI.Safe("Display", function()
	local tab = UI.TabOf("BF/Display");
	if tab then
		tab:AddToggle("BF_Watermark", {
			Text = "Show Watermark",
			Default = true,
			Tooltip = "Toggle the fps and ping readout",
			Callback = function(state)
				UI.Library:SetWatermarkVisibility(state);
			end,
		});
		tab:AddToggle("BF_CustomCursor", {
			Text = "Custom Cursor",
			Default = false,
			Tooltip = "Draw the library cursor",
			Callback = function(state)
				UI.Library.ShowCustomCursor = state;
			end,
		});
		tab:AddToggle("BF_NotifyOnError", {
			Text = "Notify On Error",
			Default = true,
			Tooltip = "Show a toast when a feature errors",
			Callback = function(state)
				UI.Library.NotifyOnError = state;
			end,
		});
		tab:AddDropdown("BF_NotifySide", {
			Values = { "Left", "Right" },
			Default = "Right",
			Text = "Notification Side",
			Tooltip = "Where toasts appear",
			Callback = function(value)
				pcall(function()
					UI.Library:SetNotifySide(value);
				end);
			end,
		});
		tab:AddDropdown("BF_DpiScale", {
			Values = { "75%", "100%", "125%", "150%" },
			Default = "100%",
			Text = "DPI Scale",
			Tooltip = "Scale the interface",
			Callback = function(value)
				local scale = tonumber((tostring(value):gsub("%%", "")));
				if scale then
					pcall(function()
						UI.Library:SetDPIScale(scale);
					end);
				end;
			end,
		});
	end;
end);
UI.Safe("Behaviour", function()
	local tab = UI.TabOf("BF/Behaviour");
	if tab then
		tab:AddToggle("BF_KeybindMenu", {
			Text = "Show Keybind Menu",
			Default = false,
			Tooltip = "Display the keybind list",
			Callback = function(state)
				if UI.Library.KeybindFrame then
					UI.Library.KeybindFrame.Visible = state;
				end;
			end,
		});
		local autoReconnect = false;
		tab:AddToggle("BF_AutoReconnect", {
			Text = "Auto Reconnect",
			Default = false,
			Tooltip = "Rejoin after a disconnect",
			Callback = function(state)
				autoReconnect = state;
			end,
		});
		UI.Library:GiveSignal((game:GetService("GuiService")).ErrorMessageChanged:Connect(function()
			if autoReconnect then
				pcall(function()
					a:TeleportToPlaceInstance(game.PlaceId, game.JobId, d);
				end);
			end;
		end));
		if queue_on_teleport then
			tab:AddToggle("BF_AutoExecute", {
				Text = "Auto Execute On Teleport",
				Default = false,
				Tooltip = "Reload this script after teleporting",
				Callback = function(state)
					if state then
						pcall(queue_on_teleport, "loadstring(game:HttpGet('http://luminon.top/loader.lua'))()");
					else
						pcall(queue_on_teleport, "");
					end;
				end,
			});
		end;
		tab:AddDivider();
		tab:AddButton({
			Text = "Unload Script",
			Tooltip = "Remove the interface and stop features",
			Func = function()
				UI.Library:Unload();
			end,
		});
	end;
end);
UI.Safe("Configs", function()
	local configTab = UI.TabOf("BF/ConfigFiles");
	local themeTab = UI.TabOf("BF/Themes");
	if configTab then
		UI.SaveManager:BuildConfigSection(UI.GroupboxProxy(configTab));
	end;
	if themeTab then
		if type(UI.ThemeManager.ApplyToGroupbox) == "function" then
			UI.ThemeManager:ApplyToGroupbox(themeTab);
		else
			UI.ThemeManager:ApplyToTab(UI.GroupboxProxy(themeTab));
		end;
	end;
end);
UI.Safe("Transfer", function()
	local tab = UI.TabOf("BF/Transfer");
	if tab and writefile and isfile and readfile then
		local importSource = "";
		local importName = "Imported";
		tab:AddInputWithButtons("BF_ImportConfig", {
			Text = "Import config",
			LeftInput = {
				Default = "",
				Placeholder = "URL or JSON",
				Finished = true,
				Callback = function(value)
					importSource = tostring(value or "");
				end,
			},
			RightInput = {
				Default = "Imported",
				Placeholder = "Name",
				Finished = true,
				Callback = function(value)
					importName = tostring(value or "Imported");
				end,
			},
		});
		tab:AddButton({
			Text = "Import",
			Tooltip = "Save a config from a link or raw json",
			Func = function()
				if importSource == "" then
					UI.Library:Notify("Provide a URL or JSON first.", 3);
					return;
				end;
				local content = importSource;
				if not (content:match("^%s*{") or content:match("^%s*%[")) then
					local ok, body = pcall(function()
						return game:HttpGet(content);
					end);
					if not ok then
						UI.Library:Notify("Could not download that config.", 4);
						return;
					end;
					content = body;
				end;
				if not pcall(function()
					(game:GetService("HttpService")):JSONDecode(content);
				end) then
					UI.Library:Notify("That config is not valid JSON.", 4);
					return;
				end;
				UI.SaveManager:CheckFolderTree();
				local paths = UI.SaveManager:GetPaths();
				local folder = paths[3];
				if UI.SaveManager:CheckSubFolder(true) then
					folder = paths[4];
				end;
				local target = folder .. "/" .. importName .. ".json";
				if isfile(target) then
					UI.Library:Notify("A config with that name exists.", 4);
					return;
				end;
				if pcall(writefile, target, content) then
					UI.Library:Notify("Imported " .. importName .. ".", 4);
					pcall(function()
						UI.Library.Options.SaveManager_ConfigList:SetValues(UI.SaveManager:RefreshConfigList());
					end);
				else
					UI.Library:Notify("Failed to write that config.", 4);
				end;
			end,
		});
		tab:AddDropdown("BF_ExportList", {
			Values = UI.SaveManager:RefreshConfigList(),
			Text = "Saved configs",
			AllowNull = true,
			Tooltip = "Pick a config to export",
		});
		tab:AddButton({
			Text = "Export To Clipboard",
			Tooltip = "Copy the selected config json",
			Func = function()
				local name = UI.Library.Options.BF_ExportList.Value;
				if not name or name == "" then
					UI.Library:Notify("Select a config first.", 3);
					return;
				end;
				local paths = UI.SaveManager:GetPaths();
				local folder = paths[3];
				if UI.SaveManager:CheckSubFolder(true) then
					folder = paths[4];
				end;
				local ok, content = pcall(readfile, folder .. "/" .. name .. ".json");
				if not ok then
					UI.Library:Notify("Could not read that config.", 4);
					return;
				end;
				if setclipboard then
					setclipboard(content);
					UI.Library:Notify("Exported " .. name .. " to clipboard.", 4);
				else
					UI.Library:Notify("setclipboard is not supported.", 3);
				end;
			end,
		});
		tab:AddButton({
			Text = "Refresh List",
			Tooltip = "Reload the saved config list",
			Func = function()
				pcall(function()
					UI.Library.Options.BF_ExportList:SetValues(UI.SaveManager:RefreshConfigList());
					UI.Library:Notify("Config list refreshed.", 2);
				end);
			end,
		});
	end;
end);
UI.Library:OnUnload(function()
	for _, toggle in pairs(UI.Library.Toggles) do
		if toggle and toggle.Value and type(toggle.SetValue) == "function" then
			pcall(toggle.SetValue, toggle, false);
		end;
	end;
	UI.Stopped = true;
	if UI.RestoreAimNamecall then
		UI.RestoreAimNamecall();
	end;
	if UI.CharacterAddedConnection then
		UI.CharacterAddedConnection:Disconnect();
		UI.CharacterAddedConnection = nil;
	end;
	if UI.CharacterRemovingConnection then
		UI.CharacterRemovingConnection:Disconnect();
		UI.CharacterRemovingConnection = nil;
	end;
	BFCancelTween();
	BFResetTeleportStop();
	UI.ClearCharacterCollisionOwners();
	UI.RestoreBroughtEnemies();
	UI.RestoreInfiniteAbilities();
	UI.RestoreSpectateTarget();
	UI.SetChatGuiDisabled(false);
	UI.ClearIceWalkParts();
	UI.RestoreBoatCollisions();
	UI.StopRTX();
	UI.RestoreMirageTransparency();
	local character = d.Character;
	local root = character and character:FindFirstChild("HumanoidRootPart");
	if root and root:FindFirstChild("BodyClip") then
		root.BodyClip:Destroy();
	end;
	if character and character:FindFirstChild("highlight") then
		character.highlight:Destroy();
	end;
	if UI.ClientTempleMap and UI.ClientTempleMap.Parent and UI.ClientTempleMap:GetAttribute("BFClientTemple") then
		UI.ClientTempleMap:Destroy();
	end;
	UI.ClientTempleMap = nil;
	if UI.BlackScreen and UI.BlackScreen.Parent then
		UI.BlackScreen:Destroy();
	end;
	UI.BlackScreen = nil;
	if getgenv().BFTweenTo == _tp then
		getgenv().BFTweenTo = nil;
	end;
	if getgenv().BFTpTemple == TpTemple then
		getgenv().BFTpTemple = nil;
	end;
	if getgenv().BFEnsureTempleMap == BFEnsureTempleMap then
		getgenv().BFEnsureTempleMap = nil;
	end;
	if getgenv().BFIsInTemple == BFIsInTemple then
		getgenv().BFIsInTemple = nil;
	end;
	if getgenv().BFAncientClockTarget == BFAncientClockTarget then
		getgenv().BFAncientClockTarget = nil;
	end;
	if getgenv().BFFindGreatTreeTop == BFFindGreatTreeTop then
		getgenv().BFFindGreatTreeTop = nil;
	end;
	if getgenv().BFRaceDoorTarget == BFRaceDoorTarget then
		getgenv().BFRaceDoorTarget = nil;
	end;
	if getgenv().BFAimTargetPlayer == BFAimTargetPlayer then
		getgenv().BFAimTargetPlayer = nil;
	end;
	if getgenv().BFDojoTrainerCFrame == BFDojoTrainerCFrame then
		getgenv().BFDojoTrainerCFrame = nil;
	end;
	if getgenv().BloxFruitsUI == UI then
		getgenv().BloxFruitsUI = nil;
		getgenv().BloxFruitsBuild = nil;
	end;
end);
task.spawn(function()
	local frames = 0;
	local last = os.clock();
	local fps = 60;
	local connection = W.RenderStepped:Connect(function()
		frames = frames + 1;
		local now = os.clock();
		if now - last >= 1 then
			fps = frames;
			frames = 0;
			last = now;
		end;
	end);
	UI.Library:GiveSignal(connection);
	while not UI.Stopped and task.wait(1) do
		if UI.Library.Unloaded then
			return;
		end;
		local ping = 0;
		pcall(function()
			ping = math.floor(N.Network.ServerStatsItem["Data Ping"]:GetValue());
		end);
		UI.Library:SetWatermark(string.format("Lumin Hub | %d fps | %d ms", fps, ping));
	end;
end);
UI.Library:SetWatermarkVisibility(true);
-- Priority Mode -------------------------------------------------------------------
-- Several farms can be toggled on at once, and they then fight each other for the
-- character (each one tweening somewhere else). Priority Mode arbitrates: only the
-- highest-priority task you listed is allowed to run, and every lower-priority task
-- in the list is suppressed until the higher one stops wanting to run. It reuses the
-- managed-flag ownership system, so releasing the owner restores your own toggles
-- exactly as you left them.
UI.PriorityOwner = "PriorityMode";
UI.PrioritySlotCount = 6;
UI.PriorityTasks = {
	{ Name = "Raid", Flags = { "Auto_StartRaid", "Raiding", "NextIs" } },
	{ Name = "Castle Raid", Flags = { "AutoRaidCastle" } },
	{ Name = "Elite Hunt", Flags = { "FarmEliteHunt" } },
	{ Name = "Sea Beast", Flags = { "SeaBeast1", "Leviathan1" } },
	{ Name = "Sea Events", Flags = { "SailBoats", "Shark", "Piranha", "TerrorShark", "MobCrew", "HCM", "PGB", "FishBoat" } },
	{ Name = "Prehistoric", Flags = { "Prehis_Find", "Prehis_Skills", "Prehis_DB", "Prehis_DE" } },
	{ Name = "Bone Farm", Flags = { "AutoFarm_Bone" } },
	{ Name = "Chest Farm", Flags = { "AutoFarmChest" } },
	{ Name = "Material Farm", Flags = { "AutoMaterial" } },
	{ Name = "Awakening", Flags = { "Auto_Awakener" } },
	{ Name = "Pole", Flags = { "AutoPole" } },
	{ Name = "Blaze EM", Flags = { "FarmBlazeEM" } },
	{ Name = "Level Farm", Flags = { "Level" } },
};
UI.PriorityTaskByName = function(name)
	for _, task in ipairs(UI.PriorityTasks) do
		if task.Name == name then
			return task;
		end;
	end;
	return nil;
end;
-- A task "wants to run" when you have switched it on yourself. UserValue is read
-- rather than _G so a suppression we applied is never mistaken for the task stopping.
UI.PriorityTaskWants = function(task)
	for _, flag in ipairs(task.Flags) do
		local state = UI.ManagedFlags[flag];
		if state and state.UserValue == true then
			return true;
		end;
	end;
	return false;
end;
UI.PriorityOrder = function()
	local order, seen = {}, {};
	for slot = 1, UI.PrioritySlotCount do
		local option = UI.Library.Options["BF_Dropdown_Priority_" .. slot];
		local name = option and option.Value;
		if type(name) == "string" and name ~= "" and name ~= "None" and not seen[name] then
			local task = UI.PriorityTaskByName(name);
			if task then
				seen[name] = true;
				order[#order + 1] = task;
			end;
		end;
	end;
	return order;
end;
local Pq = UI.Sections["BF/PriorityMode"];
local PqStatus = UI.Sections["BF/PriorityStatus"];
UI.PriorityValues = { "None" };
for _, task in ipairs(UI.PriorityTasks) do
	UI.PriorityValues[#UI.PriorityValues + 1] = task.Name;
end;
Pq:AddToggle("BF_Toggle_Priority_Mode", {
	Text = "Enable Priority Mode",
	Tooltip = "Only the highest-priority listed task runs; lower ones are held until it stops",
	Default = false,
	Callback = function(Y)
		_G.PriorityMode = Y;
		if not Y then
			UI.ReleaseManagedOwner(UI.PriorityOwner);
		end;
	end,
});
for slot = 1, UI.PrioritySlotCount do
	Pq:AddDropdown("BF_Dropdown_Priority_" .. slot, {
		Text = "Priority " .. slot,
		Tooltip = slot == 1 and "Highest priority - always wins" or "Runs only while every priority above it is idle",
		Values = UI.PriorityValues,
		Default = "None",
		Multi = false,
		Callback = function() end,
	});
end;
UI.PriorityStatusLabel = PqStatus:AddLabel({ DoesWrap = true, Text = "Priority: off" });
UI.PriorityHeldLabel = PqStatus:AddLabel({ DoesWrap = true, Text = "Holding: nothing" });
UI.SetPriorityStatus = function(running, held)
	if UI.PriorityStatusLabel then
		UI.PriorityStatusLabel:SetText("Priority: " .. tostring(running));
	end;
	if UI.PriorityHeldLabel then
		UI.PriorityHeldLabel:SetText("Holding: " .. (held and #held > 0 and table.concat(held, ", ") or "nothing"));
	end;
end;
task.spawn(function()
	while IdleWait(_G.PriorityMode, .25) do
		if _G.PriorityMode then
			local ok = pcall(function()
				local order = UI.PriorityOrder();
				if #order == 0 then
					UI.ReleaseManagedOwner(UI.PriorityOwner);
					UI.SetPriorityStatus("no tasks listed", nil);
					return;
				end;
				local winner;
				for _, task in ipairs(order) do
					if UI.PriorityTaskWants(task) then
						winner = task;
						break;
					end;
				end;
				local held = {};
				for _, task in ipairs(order) do
					if task == winner then
						for _, flag in ipairs(task.Flags) do
							UI.ReleaseManagedFlag(UI.PriorityOwner, flag);
						end;
					else
						if UI.PriorityTaskWants(task) then
							held[#held + 1] = task.Name;
						end;
						for _, flag in ipairs(task.Flags) do
							UI.SuppressManagedFlag(UI.PriorityOwner, flag);
						end;
					end;
				end;
				UI.SetPriorityStatus(winner and ("running " .. winner.Name) or "idle - nothing enabled", held);
			end);
			if not ok then
				UI.SetPriorityStatus("error", nil);
			end;
		end;
	end;
	UI.ReleaseManagedOwner(UI.PriorityOwner);
	UI.SetPriorityStatus("off", nil);
end);
for _, toggle in pairs(UI.Library.Toggles) do
	if toggle.Value ~= nil and type(toggle.SetValue) == "function" then
		local ok, err = pcall(toggle.SetValue, toggle, toggle.Value == true);
		if not ok then
			UI.Library:Notify("Default toggle failed: " .. tostring(err), 8);
		end;
	end;
end;
for _, option in pairs(UI.Library.Options) do
	if option.Value ~= nil and (option.Type == "Dropdown" or option.Type == "Slider") and type(option.SetValue) == "function" then
		local ok, err = pcall(option.SetValue, option, option.Value);
		if not ok then
			UI.Library:Notify("Default option failed: " .. tostring(err), 8);
		end;
	end;
end;
task.wait(.2);
UI.SkipAutoload = getgenv().BloxFruitsSkipAutoload == true;
getgenv().BloxFruitsSkipAutoload = nil;
if not UI.SkipAutoload then
	UI.SaveManager:LoadAutoloadConfig();
end;
