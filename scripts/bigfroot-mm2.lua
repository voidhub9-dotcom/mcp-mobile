-- Bigfroot | Murder Mystery 2
-- BigFroot UI (blush.lua) conversion of VoidHub MM2 v1.1
local Library = loadstring(game:HttpGet("https://gitlab.com/hanniii1/test/-/raw/main/boom.lua?ref_type=heads"))()
Library:SetFolder("Bigfroot/mm2", "BF Hub")

local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting          = game:GetService("Lighting")
local HttpService       = game:GetService("HttpService")
local TeleportService   = game:GetService("TeleportService")
local CoreGui           = game:GetService("CoreGui")
local Camera            = workspace.CurrentCamera
local LocalPlayer       = Players.LocalPlayer

local WHITE    = Color3.new(1, 1, 1)
local hasFTI   = firetouchinterest and true or false
local hasHookMM = hookmetamethod and true or false

local function safeParent()
    if gethui then return gethui() end
    return CoreGui
end

-- ─── FLAGS ───────────────────────────────────────────────────────────────────
local F = {
    espEnabled   = false, espBox       = true,  espTracer    = false,
    espName      = true,  espDist      = true,  espHealth    = true,
    espHighlight = true,  espSkeleton  = false, espRoleColor = true,
    coinEsp      = false, dropEsp      = false,

    wallbang     = false, autoShoot    = false, blatantShoot = false,
    silentAim    = false, triggerBot   = false, camLock      = false,
    autoGun      = false, autoDetect   = false, knifeReach   = false,
    autoEquip    = false, killAura     = false, autoKill     = false,
    knifeSilent  = false,

    walkOn       = false, jumpOn       = false, infJump      = false,
    noclip       = false, fly          = false, spin         = false,
    antiFling    = false, ghostMode    = false, playerScale  = false,
    rainbowChar  = false, bigHead      = false, rainbowTrail = false,
    forceField   = false, floatMode    = false, lowGrav      = false,
    freecam      = false,

    farmCoins    = false,
    nametagOn    = false, autoDance    = false,
    antiVoid     = false, antiAfk      = true,  alarm        = false,
    autoEvade    = false, antiKill     = false,  fullbright   = false,
    noFog        = false, headSit      = false,
}

local CFG = {
    walkSpeed    = 16,  jumpPower    = 50,   flySpeed     = 50,
    spinSpeed    = 10,  killRadius   = 18,   knifeRadius  = 12,
    reachSize    = 10,  farmSpeed    = 16,   bagCap       = 50,
    alarmDist    = 40,  evadeDist    = 20,
    evadeSpeed   = 25,  antiKillDist = 15,   scaleSize    = 2,
    fov          = 70,  maxZoom      = 128,  gravity      = 50,
    espMaxDist   = 2000, aimFov      = 120,  aimPart      = "Head", freecamSpeed = 1,
    trailColor   = Color3.fromRGB(120, 80, 255),
    nametagText  = "Bigfroot",
    danceSel     = "Dance 1",
    cMurd        = Color3.fromRGB(255, 60,  60),
    cSher        = Color3.fromRGB(60,  140, 255),
    cHero        = Color3.fromRGB(255, 220, 60),
    cInno        = Color3.fromRGB(60,  220, 60),
}

local CONN = {}
local function trackConn(name, conn)
    if CONN[name] then pcall(function() CONN[name]:Disconnect() end) end
    CONN[name] = conn
    return conn
end

-- ─── REMOTES ─────────────────────────────────────────────────────────────────
local REFS = {}
do
    local R = ReplicatedStorage:FindFirstChild("Remotes")
    REFS.Gameplay  = R and R:FindFirstChild("Gameplay")
    REFS.Extras    = R and R:FindFirstChild("Extras")
    REFS.GetPD     = REFS.Gameplay and REFS.Gameplay:FindFirstChild("GetCurrentPlayerData")
    REFS.PDChanged = REFS.Gameplay and REFS.Gameplay:FindFirstChild("PlayerDataChanged")
    local we = ReplicatedStorage:FindFirstChild("WeaponEvents")
    REFS.GunBeam   = we and we:FindFirstChild("GunBeam")
    if not REFS.GetPD   then REFS.GetPD   = ReplicatedStorage:FindFirstChild("GetPlayerData", true) end
    if not REFS.GunBeam then REFS.GunBeam = ReplicatedStorage:FindFirstChild("GunBeam", true) end
    REFS.CoinCollected = REFS.Gameplay and REFS.Gameplay:FindFirstChild("CoinCollected")
    REFS.RoundStart    = REFS.Gameplay and REFS.Gameplay:FindFirstChild("RoundStart")
    REFS.RoundEndFade  = REFS.Gameplay and REFS.Gameplay:FindFirstChild("RoundEndFade")
end

local PD = {}
local pdPending = false
local function refreshPD()
    if not REFS.GetPD or pdPending then return end
    pdPending = true
    task.spawn(function()
        local ok, data = pcall(function() return REFS.GetPD:InvokeServer() end)
        if ok and type(data) == "table" then PD = data end
        pdPending = false
    end)
end
if REFS.PDChanged then trackConn("pdChanged", REFS.PDChanged.OnClientEvent:Connect(refreshPD)) end
refreshPD()

-- ─── HELPERS ─────────────────────────────────────────────────────────────────
local function char()  return LocalPlayer.Character end
local function hum()   local c = LocalPlayer.Character; return c and c:FindFirstChildOfClass("Humanoid") end
local function hrp()   local c = LocalPlayer.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function alive() local h = hum(); return h ~= nil and h.Health > 0 end

local function others()
    local t = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then t[#t+1] = p end
    end
    return t
end

local function hasTool(container, name)
    if not container then return false end
    for _, t in ipairs(container:GetChildren()) do
        if t.Name == name and t:IsA("Tool") then return true end
    end
    return false
end

local function myKnife()
    local c = LocalPlayer.Character
    if not c then return nil end
    return c:FindFirstChild("Knife", true)
        or (LocalPlayer.Backpack and LocalPlayer.Backpack:FindFirstChild("Knife", true))
end

local function myGun()
    local c = LocalPlayer.Character
    if not c then return nil end
    return c:FindFirstChild("Gun", true)
        or (LocalPlayer.Backpack and LocalPlayer.Backpack:FindFirstChild("Gun", true))
end

local function roleOf(plr)
    local c  = plr.Character
    local bp = plr:FindFirstChildOfClass("Backpack")
    if hasTool(c, "Knife") or hasTool(bp, "Knife") then return "Murderer" end
    if hasTool(c, "Gun")   or hasTool(bp, "Gun")   then
        if PD[plr.Name] and PD[plr.Name].Role == "Hero" then return "Hero" end
        return "Sheriff"
    end
    if PD[plr.Name] and PD[plr.Name].Role then
        local r = PD[plr.Name].Role
        if r == "Murderer" or r == "Sheriff" or r == "Hero" then return r end
    end
    return "Innocent"
end

local function roleColor(role)
    if role == "Murderer" then return CFG.cMurd
    elseif role == "Sheriff" then return CFG.cSher
    elseif role == "Hero"    then return CFG.cHero end
    return CFG.cInno
end

local function getMurderer()
    for _, p in ipairs(others()) do if roleOf(p) == "Murderer" then return p end end
end
local function getSheriff()
    for _, p in ipairs(others()) do if roleOf(p) == "Sheriff"  then return p end end
end

local function getActiveMap()
    local kw = {
        Bank="Bank", Bio="Biolaboratory", Factory="Factory", Hospital="Hospital",
        Hotel="Hotel", House="House", Mansion="Mansion", Mil="Military Base",
        Office="Office", Police="Police Station", Research="Research Center", Work="Workplace",
    }
    for _, obj in ipairs(workspace:GetChildren()) do
        for k, v in pairs(kw) do if obj.Name:find(k) then return obj, v end end
    end
end

local function coinContainer()
    for _, m in ipairs(workspace:GetChildren()) do
        local c = m:FindFirstChild("CoinContainer")
        if c then return c end
    end
end

local function getCoins()
    local cc = coinContainer()
    if not cc then return {} end
    local t = {}
    for _, d in ipairs(cc:GetChildren()) do
        if d:IsA("BasePart") and (d:GetAttribute("CoinID") == "Coin" or d.Name == "Coin_Server") then
            t[#t+1] = d
        end
    end
    return t
end

local function getGunDrops()
    local t = {}
    for _, m in ipairs(workspace:GetChildren()) do
        local gd = m:FindFirstChild("GunDrop")
        if gd then
            local part = gd:IsA("BasePart") and gd or gd:FindFirstChildWhichIsA("BasePart")
            if part then t[#t+1] = part end
        end
    end
    return t
end

local function notify(title, text, dur, ntype)
    pcall(function()
        Library:Notify({ Title = title, Description = text, Time = dur or 3, Type = ntype or "info" })
    end)
end

local DEFAULT_WALKSPEED = 16
local DEFAULT_JUMPPOWER  = 50

local function applyMovement()
    local h = hum()
    if not h then return end
    h.WalkSpeed = F.walkOn and CFG.walkSpeed or DEFAULT_WALKSPEED
    h.JumpPower = F.jumpOn and CFG.jumpPower or DEFAULT_JUMPPOWER
end

local function resetCamera()
    local c = LocalPlayer.Character
    if c and c:FindFirstChild("Humanoid") then Camera.CameraSubject = c.Humanoid end
end

local function tpTo(cf)
    local h = hrp()
    if h then h.CFrame = cf end
end

local function tpToPlayer(name)
    local p = Players:FindFirstChild(name)
    if not p or not p.Character then return end
    local tHRP = p.Character:FindFirstChild("HumanoidRootPart")
    if tHRP then tpTo(tHRP.CFrame) end
end

local antiFlingConns = {}
local function setupCollision(charObj)
    local function nc(p)
        if F.antiFling and p:IsA("BasePart") then p.CanCollide = false end
    end
    for _, p in ipairs(charObj:GetChildren()) do nc(p) end
    local ca = charObj.ChildAdded:Connect(nc)
    local st = RunService.Stepped:Connect(function()
        if F.antiFling and charObj:IsDescendantOf(workspace) then
            for _, p in ipairs(charObj:GetChildren()) do
                if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
            end
        end
    end)
    charObj.Destroying:Connect(function()
        pcall(function() ca:Disconnect() end)
        pcall(function() st:Disconnect() end)
    end)
end

local function trackPAF(p)
    if p == LocalPlayer then return end
    if antiFlingConns[p] then antiFlingConns[p]:Disconnect() end
    antiFlingConns[p] = p.CharacterAdded:Connect(setupCollision)
    if p.Character then setupCollision(p.Character) end
end
for _, p in ipairs(Players:GetPlayers()) do trackPAF(p) end
trackConn("paAdd", Players.PlayerAdded:Connect(trackPAF))
trackConn("paRem", Players.PlayerRemoving:Connect(function(p)
    if antiFlingConns[p] then antiFlingConns[p]:Disconnect(); antiFlingConns[p] = nil end
end))

-- ─── ESP ─────────────────────────────────────────────────────────────────────
local ESP = { objects = {}, coinHL = {}, dropHL = {} }
local DRAW_OK = (Drawing and typeof(Drawing.new) == "function") and true or false

local BONE_PAIRS = {
    {"Head","UpperTorso"}, {"UpperTorso","LowerTorso"},
    {"UpperTorso","LeftUpperArm"},  {"LeftUpperArm","LeftLowerArm"},  {"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"}, {"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
    {"LowerTorso","LeftUpperLeg"},  {"LeftUpperLeg","LeftLowerLeg"},  {"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"}, {"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
}

local function espClear(plr)
    local obj = ESP.objects[plr]
    if not obj then return end
    if obj.Box      then pcall(function() obj.Box:Remove()       end) end
    if obj.Tracer   then pcall(function() obj.Tracer:Remove()    end) end
    if obj.Name     then pcall(function() obj.Name:Remove()      end) end
    if obj.Health   then pcall(function() obj.Health:Remove()    end) end
    if obj.Bones    then for _, b in ipairs(obj.Bones) do pcall(function() b:Remove() end) end end
    if obj.Highlight then pcall(function() obj.Highlight:Destroy() end) end
    ESP.objects[plr] = nil
end

local function espClearAll()
    for plr in pairs(ESP.objects) do espClear(plr) end
    for _, hl in pairs(ESP.coinHL) do pcall(function() hl:Destroy() end) end
    for _, hl in pairs(ESP.dropHL) do pcall(function() hl:Destroy() end) end
    ESP.coinHL = {}; ESP.dropHL = {}
end

local function espCreate(plr)
    local obj = {}
    if DRAW_OK then
        local box = Drawing.new("Square")
        box.Visible = false; box.Filled = false; box.Color = WHITE; box.Thickness = 1.5
        obj.Box = box
        local tracer = Drawing.new("Line")
        tracer.Visible = false; tracer.Thickness = 1; tracer.Color = WHITE
        obj.Tracer = tracer
        local nameLabel = Drawing.new("Text")
        nameLabel.Visible = false; nameLabel.Center = true; nameLabel.Outline = true
        nameLabel.Size = 14; nameLabel.Color = WHITE
        obj.Name = nameLabel
        local healthLabel = Drawing.new("Text")
        healthLabel.Visible = false; healthLabel.Center = true; healthLabel.Outline = true
        healthLabel.Size = 12; healthLabel.Color = Color3.fromRGB(0, 255, 0)
        obj.Health = healthLabel
        local bones = {}
        for i = 1, #BONE_PAIRS do
            local b = Drawing.new("Line")
            b.Visible = false; b.Thickness = 1; b.Color = WHITE
            bones[i] = b
        end
        obj.Bones = bones
    end
    local hl = Instance.new("Highlight")
    hl.FillTransparency = 0.5; hl.OutlineTransparency = 0
    hl.Enabled = false; hl.Adornee = plr.Character; hl.Parent = safeParent()
    obj.Highlight = hl
    ESP.objects[plr] = obj
end

Players.PlayerRemoving:Connect(function(p) espClear(p) end)
for _, p in ipairs(Players:GetPlayers()) do
    p.CharacterRemoving:Connect(function() espClear(p) end)
end
trackConn("paAddESP", Players.PlayerAdded:Connect(function(p)
    p.CharacterRemoving:Connect(function() espClear(p) end)
end))

trackConn("espRender", RunService.RenderStepped:Connect(function()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        local c  = plr.Character
        local h  = c and c:FindFirstChild("HumanoidRootPart")
        if not F.espEnabled or not h then espClear(plr); continue end
        local myH = hrp()
        if myH then
            local dist = (myH.Position - h.Position).Magnitude
            if dist > CFG.espMaxDist then
                local obj = ESP.objects[plr]
                if obj then
                    if obj.Box    then obj.Box.Visible    = false end
                    if obj.Tracer then obj.Tracer.Visible = false end
                    if obj.Name   then obj.Name.Visible   = false end
                    if obj.Health then obj.Health.Visible = false end
                    if obj.Bones  then for _, b in ipairs(obj.Bones) do b.Visible = false end end
                    if obj.Highlight then obj.Highlight.Enabled = false end
                end
                continue
            end
        end
        if not ESP.objects[plr] then espCreate(plr) end
        local obj = ESP.objects[plr]
        if obj.Highlight and obj.Highlight.Adornee ~= c then
            pcall(function() obj.Highlight.Adornee = c end)
        end
        local role  = roleOf(plr)
        local color = F.espRoleColor and roleColor(role) or WHITE
        local pos, onScreen = Camera:WorldToViewportPoint(h.Position)
        local head  = c:FindFirstChild("Head")
        local topPos = Camera:WorldToViewportPoint((head and head.Position or h.Position) + Vector3.new(0, 0.7, 0))
        local botPos = Camera:WorldToViewportPoint(h.Position - Vector3.new(0, 3, 0))
        local height = math.abs(topPos.Y - botPos.Y)
        local width  = height * 0.55
        if obj.Box then
            obj.Box.Visible  = F.espBox and onScreen
            obj.Box.Color    = color
            obj.Box.Size     = Vector2.new(width, height)
            obj.Box.Position = Vector2.new(pos.X - width * 0.5, topPos.Y)
        end
        if obj.Tracer then
            obj.Tracer.Visible = F.espTracer and onScreen
            obj.Tracer.Color   = color
            obj.Tracer.From    = Vector2.new(Camera.ViewportSize.X * 0.5, Camera.ViewportSize.Y)
            obj.Tracer.To      = Vector2.new(pos.X, topPos.Y + height)
        end
        if obj.Name then
            obj.Name.Visible = F.espName and onScreen
            obj.Name.Color   = color
            local label = plr.Name .. " [" .. role .. "]"
            if F.espDist and myH then
                local d = math.floor((myH.Position - h.Position).Magnitude)
                label = label .. " (" .. d .. "m)"
            end
            obj.Name.Text     = label
            obj.Name.Position = Vector2.new(pos.X, topPos.Y - 16)
        end
        if obj.Health then
            local humanoid = c:FindFirstChildOfClass("Humanoid")
            obj.Health.Visible = F.espHealth and onScreen and humanoid ~= nil
            if humanoid then
                local hp  = math.floor(humanoid.Health)
                obj.Health.Text = tostring(hp) .. " HP"
                obj.Health.Position = Vector2.new(pos.X, botPos.Y + 2)
                local pct = humanoid.Health / (humanoid.MaxHealth > 0 and humanoid.MaxHealth or 100)
                obj.Health.Color = Color3.fromHSV(pct * 0.33, 1, 1)
            end
        end
        obj.Highlight.Enabled          = F.espHighlight
        obj.Highlight.FillColor        = color
        obj.Highlight.OutlineColor     = color
        obj.Highlight.FillTransparency = 0.5
        if obj.Bones then
            for i, pair in ipairs(BONE_PAIRS) do
                local b  = obj.Bones[i]
                local p1 = c:FindFirstChild(pair[1], true)
                local p2 = c:FindFirstChild(pair[2], true)
                if F.espSkeleton and onScreen and p1 and p2 then
                    local sp1, v1 = Camera:WorldToViewportPoint(p1.Position)
                    local sp2, v2 = Camera:WorldToViewportPoint(p2.Position)
                    if v1 and v2 then
                        b.Visible = true; b.Color = color
                        b.From = Vector2.new(sp1.X, sp1.Y)
                        b.To   = Vector2.new(sp2.X, sp2.Y)
                    else b.Visible = false end
                else b.Visible = false end
            end
        end
    end

    if F.coinEsp then
        for inst, hl in pairs(ESP.coinHL) do
            if not inst or not inst.Parent or not hl or not hl.Parent then
                pcall(function() if hl then hl:Destroy() end end); ESP.coinHL[inst] = nil
            end
        end
        for _, coin in ipairs(getCoins()) do
            if not ESP.coinHL[coin] or not ESP.coinHL[coin].Parent then
                local hl = Instance.new("Highlight")
                hl.FillColor = Color3.fromRGB(255, 200, 0); hl.OutlineColor = Color3.fromRGB(255, 200, 0)
                hl.FillTransparency = 0.3; hl.Adornee = coin; hl.Parent = safeParent()
                ESP.coinHL[coin] = hl
            end
        end
    else
        for _, hl in pairs(ESP.coinHL) do pcall(function() hl:Destroy() end) end
        ESP.coinHL = {}
    end

    if F.dropEsp then
        for inst, hl in pairs(ESP.dropHL) do
            if not inst or not inst.Parent or not hl or not hl.Parent then
                pcall(function() if hl then hl:Destroy() end end); ESP.dropHL[inst] = nil
            end
        end
        for _, drop in ipairs(getGunDrops()) do
            if not ESP.dropHL[drop] or not ESP.dropHL[drop].Parent then
                local hl = Instance.new("Highlight")
                hl.FillColor = Color3.fromRGB(100, 200, 255); hl.OutlineColor = Color3.fromRGB(100, 200, 255)
                hl.FillTransparency = 0.3; hl.Adornee = drop; hl.Parent = safeParent()
                ESP.dropHL[drop] = hl
            end
        end
    else
        for _, hl in pairs(ESP.dropHL) do pcall(function() hl:Destroy() end) end
        ESP.dropHL = {}
    end
end))

-- ─── COMBAT LOOPS ────────────────────────────────────────────────────────────
trackConn("killAura", RunService.Heartbeat:Connect(function()
    if not F.killAura then return end
    local knife = myKnife()
    if not (knife and knife:FindFirstChild("Events")) then return end
    local ht = knife.Events:FindFirstChild("HandleTouched")
    if not ht then return end
    local HRP = hrp()
    if not HRP then return end
    for _, p in ipairs(others()) do
        local c = p.Character
        if c then
            local tHRP = c:FindFirstChild("HumanoidRootPart")
            local h    = c:FindFirstChildOfClass("Humanoid")
            if tHRP and h and h.Health > 0 then
                if (HRP.Position - tHRP.Position).Magnitude <= CFG.killRadius then
                    pcall(function() ht:FireServer(tHRP) end)
                    local tor = c:FindFirstChild("UpperTorso") or c:FindFirstChild("Torso")
                    if tor then pcall(function() ht:FireServer(tor) end) end
                end
            end
        end
    end
end))

local autoKillBusy = false
trackConn("autoKill", RunService.Heartbeat:Connect(function()
    if not F.autoKill or autoKillBusy then return end
    local HRP   = hrp()
    local knife = myKnife()
    if not HRP or not knife then return end
    local ht = knife:FindFirstChild("Events") and knife.Events:FindFirstChild("HandleTouched")
    if not ht then return end
    autoKillBusy = true
    task.spawn(function()
        pcall(function()
            local saved = HRP.CFrame
            for _, p in ipairs(others()) do
                local c = p.Character
                if c and c:FindFirstChild("HumanoidRootPart") then
                    local tHRP = c.HumanoidRootPart
                    local h    = c:FindFirstChildOfClass("Humanoid")
                    if h and h.Health > 0 then
                        HRP.CFrame = tHRP.CFrame * CFrame.new(0, 0, 1.5)
                        pcall(function() ht:FireServer(tHRP) end)
                        task.wait(0.08)
                    end
                end
            end
            if HRP and HRP.Parent then HRP.CFrame = saved end
        end)
        autoKillBusy = false
    end)
end))

trackConn("knifeReach", RunService.Heartbeat:Connect(function()
    if not F.knifeReach then return end
    local knife = myKnife()
    if not (knife and knife:FindFirstChild("Events")) then return end
    local ht = knife.Events:FindFirstChild("HandleTouched")
    if not ht then return end
    local HRP = hrp()
    if not HRP then return end
    for _, p in ipairs(others()) do
        local c = p.Character
        if c then
            local tHRP = c:FindFirstChild("HumanoidRootPart")
            local h    = c:FindFirstChildOfClass("Humanoid")
            if tHRP and h and h.Health > 0 then
                if (HRP.Position - tHRP.Position).Magnitude <= CFG.knifeRadius then
                    pcall(function() ht:FireServer(tHRP) end)
                end
            end
        end
    end
end))

local function doWallbang()
    local HRP = hrp()
    local gun = myGun()
    if not HRP or not gun then return end
    local m = getMurderer()
    if not m or not m.Character then return end
    local mHRP = m.Character:FindFirstChild("HumanoidRootPart")
    if not mHRP then return end
    local sv = HRP.CFrame
    HRP.CFrame = CFrame.lookAt(HRP.Position, Vector3.new(mHRP.Position.X, HRP.Position.Y, mHRP.Position.Z))
    pcall(function() gun:Activate() end)
    if REFS.GunBeam then pcall(function() REFS.GunBeam:FireServer(CFrame.new(mHRP.Position)) end) end
    local shootRemote = gun:FindFirstChild("Shoot") or gun:FindFirstChild("ShootEvent")
    if shootRemote then pcall(function() shootRemote:FireServer(mHRP.CFrame, HRP.CFrame) end) end
    task.wait(0.05)
    HRP.CFrame = sv
end

trackConn("wallbang", UserInputService.InputBegan:Connect(function(input, gpe)
    if not F.wallbang or gpe then return end
    if input.UserInputType == Enum.UserInputType.Touch
    or input.UserInputType == Enum.UserInputType.MouseButton1 then
        doWallbang()
    end
end))

local shootCd = 0
trackConn("autoShoot", RunService.Heartbeat:Connect(function(dt)
    if not F.autoShoot then return end
    shootCd = shootCd - dt
    if shootCd > 0 then return end
    local m = getMurderer()
    if not m or not m.Character then return end
    local mHead = m.Character:FindFirstChild("Head") or m.Character:FindFirstChild("HumanoidRootPart")
    local mHum  = m.Character:FindFirstChildOfClass("Humanoid")
    if not (mHead and mHum and mHum.Health > 0) then return end
    local gun = myGun()
    if not gun then return end
    local HRP = hrp()
    if not HRP then return end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { LocalPlayer.Character }
    local result = workspace:Raycast(Camera.CFrame.Position, (mHead.Position - Camera.CFrame.Position).Unit * 1000, params)
    if result and result.Instance then
        local model = result.Instance:FindFirstAncestorOfClass("Model")
        if not (model and model == m.Character) then return end
    end
    shootCd = 0.35
    pcall(function() gun:Activate() end)
    if REFS.GunBeam then pcall(function() REFS.GunBeam:FireServer(CFrame.new(mHead.Position)) end) end
end))

local blatantCd   = 0
local blatantBusy = false
trackConn("blatantShoot", RunService.Heartbeat:Connect(function(dt)
    if not F.blatantShoot or blatantBusy then return end
    blatantCd = blatantCd - dt
    if blatantCd > 0 then return end
    local m = getMurderer()
    if not m or not m.Character then return end
    local mHRP = m.Character:FindFirstChild("HumanoidRootPart")
    local mHum = m.Character:FindFirstChildOfClass("Humanoid")
    if not (mHRP and mHum and mHum.Health > 0) then return end
    local gun = myGun()
    if not gun then return end
    local HRP = hrp()
    if not HRP then return end
    blatantCd = 0.5; blatantBusy = true
    task.spawn(function()
        local saved = HRP.CFrame
        pcall(function()
            HRP.Anchored = true
            HRP.CFrame   = CFrame.new(mHRP.Position + Vector3.new(0, 14, 0), mHRP.Position)
            task.wait(0.05)
            pcall(function() gun:Activate() end)
            if REFS.GunBeam then pcall(function() REFS.GunBeam:FireServer(CFrame.new(mHRP.Position)) end) end
            task.wait(0.05)
        end)
        if HRP and HRP.Parent then HRP.Anchored = false; HRP.CFrame = saved end
        blatantBusy = false
    end)
end))

local silentAimWS      = nil
local silentAimOrigMCF = nil
local silentAimOrigTP  = nil

local function restoreSilentAim()
    if silentAimWS and silentAimOrigMCF then
        pcall(function() silentAimWS.GetMouseTargetCFrame = silentAimOrigMCF end)
    end
    if silentAimWS and silentAimOrigTP then
        pcall(function() silentAimWS.GetTargetPosition = silentAimOrigTP end)
    end
    silentAimWS = nil; silentAimOrigMCF = nil; silentAimOrigTP = nil
end

do
    local WS_hooked = false
    trackConn("silentAimHook", RunService.Heartbeat:Connect(function()
        if not F.silentAim or WS_hooked then return end
        local csv   = ReplicatedStorage:FindFirstChild("ClientServices")
        local wsMod = csv and csv:FindFirstChild("WeaponService")
        if not wsMod then return end
        local ok, WS = pcall(require, wsMod)
        if not (ok and type(WS) == "table") then return end
        silentAimWS      = WS
        silentAimOrigMCF = WS.GetMouseTargetCFrame
        silentAimOrigTP  = WS.GetTargetPosition
        if silentAimOrigMCF then
            WS.GetMouseTargetCFrame = function(s, ...)
                local m = getMurderer()
                if F.silentAim and m and m.Character then
                    local h = m.Character:FindFirstChild("Head") or m.Character:FindFirstChild("HumanoidRootPart")
                    if h then return CFrame.new(h.Position) end
                end
                return silentAimOrigMCF(s, ...)
            end
        end
        if silentAimOrigTP then
            WS.GetTargetPosition = function(s, a, b)
                local m = getMurderer()
                if F.silentAim and m and m.Character then
                    local h = m.Character:FindFirstChild("Head") or m.Character:FindFirstChild("HumanoidRootPart")
                    if h then return CFrame.new(h.Position) end
                end
                return silentAimOrigTP(s, a, b)
            end
        end
        WS_hooked = true
    end))
end

if hasHookMM then
    pcall(function()
        local oldNC
        oldNC = hookmetamethod(game, "__namecall", function(self, ...)
            if F.knifeSilent and getnamecallmethod() == "FireServer" then
                if self.Name == "KnifeThrown" and self.Parent and self.Parent.Name == "Events" then
                    local target; local HRP = hrp(); local bd = math.huge
                    if HRP then
                        for _, p in ipairs(others()) do
                            local c = p.Character
                            if c then
                                local tHRP = c:FindFirstChild("HumanoidRootPart")
                                local h    = c:FindFirstChildOfClass("Humanoid")
                                if tHRP and h and h.Health > 0 then
                                    local d = (HRP.Position - tHRP.Position).Magnitude
                                    if d < bd then bd = d; target = tHRP end
                                end
                            end
                        end
                    end
                    if target then
                        local args = { ... }
                        for i = 1, #args do
                            if typeof(args[i]) == "CFrame"   then args[i] = CFrame.new(target.Position)
                            elseif typeof(args[i]) == "Vector3" then args[i] = target.Position end
                        end
                        return oldNC(self, table.unpack(args))
                    end
                end
            end
            return oldNC(self, ...)
        end)
    end)
end

local triggerCd = 0
trackConn("triggerBot", RunService.Heartbeat:Connect(function(dt)
    if not F.triggerBot then return end
    triggerCd = triggerCd - dt
    if triggerCd > 0 then return end
    local gun = myGun()
    if not gun then return end
    local mouseLoc = UserInputService:GetMouseLocation()
    for _, p in ipairs(others()) do
        local c = p.Character
        if c then
            local tHRP = c:FindFirstChild("HumanoidRootPart")
            local h    = c:FindFirstChildOfClass("Humanoid")
            if tHRP and h and h.Health > 0 and roleOf(p) == "Murderer" then
                local pos, onScreen = Camera:WorldToViewportPoint(tHRP.Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - mouseLoc).Magnitude
                    if dist < CFG.aimFov then
                        pcall(function() gun:Activate() end)
                        if REFS.GunBeam then pcall(function() REFS.GunBeam:FireServer(CFrame.new(tHRP.Position)) end) end
                        triggerCd = 0.3
                        break
                    end
                end
            end
        end
    end
end))

trackConn("camLock", RunService.RenderStepped:Connect(function()
    if not F.camLock then return end
    local m = getMurderer()
    if not m or not m.Character then return end
    local aimPart = m.Character:FindFirstChild(CFG.aimPart) or m.Character:FindFirstChild("HumanoidRootPart")
    if not aimPart then return end
    Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, aimPart.Position)
end))

trackConn("autoEquip", RunService.Heartbeat:Connect(function()
    if not F.autoEquip then return end
    local c  = LocalPlayer.Character
    local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
    if not c or not bp then return end
    local knife = bp:FindFirstChild("Knife")
    local gun   = bp:FindFirstChild("Gun")
    local h     = c:FindFirstChildOfClass("Humanoid")
    if not h then return end
    if knife then h:EquipTool(knife)
    elseif gun then h:EquipTool(gun) end
end))

local function grabGun()
    local HRP   = hrp()
    if not HRP then return end
    local drops = getGunDrops()
    if #drops == 0 then notify("No Gun Drop", "No dropped gun found on the map.", 3); return end
    local gunDrop = drops[1]
    if hasFTI then
        pcall(function()
            firetouchinterest(HRP, gunDrop, 0)
            task.wait(0.08)
            firetouchinterest(HRP, gunDrop, 1)
        end)
    else
        local saved = HRP.CFrame
        HRP.Anchored = true; HRP.CFrame = gunDrop.CFrame
        task.wait(0.12)
        local h2 = hrp()
        if h2 then h2.Anchored = false; h2.CFrame = saved end
    end
end

local autoGrabBusy = false
trackConn("autoGrab", RunService.Heartbeat:Connect(function()
    if not F.autoGun or autoGrabBusy then return end
    local drops = getGunDrops()
    if #drops == 0 then return end
    local HRP = hrp()
    if not HRP then return end
    if hasFTI then
        autoGrabBusy = true
        task.spawn(function()
            pcall(function()
                firetouchinterest(HRP, drops[1], 0)
                task.wait(0.08)
                firetouchinterest(HRP, drops[1], 1)
            end)
            autoGrabBusy = false
        end)
    end
end))

local lastDetect = nil
trackConn("autoDetect", RunService.Heartbeat:Connect(function()
    if not F.autoDetect then return end
    local m = getMurderer()
    if m and m ~= lastDetect then
        lastDetect = m
        notify("Murderer Detected", m.Name .. " is the murderer!", 4, "warning")
    elseif not m then lastDetect = nil end
end))

-- ─── FARM ─────────────────────────────────────────────────────────────────────
local farmNoclipConn = nil
local farmTween      = nil
local farmParts      = {}
local farmActive     = false
local bagFull        = false
local farmBusy       = false
local farmHoldConn   = nil
local farmRotated    = false

local function findNearestCoin(cc)
    if not cc then return nil, math.huge end
    local best, bestDist = nil, math.huge
    local myHrp = hrp()
    if not myHrp then return nil, math.huge end
    for _, coin in pairs(cc:GetChildren()) do
        if coin:IsA("BasePart") and (coin:GetAttribute("CoinID") == "Coin" or coin.Name == "Coin_Server")
        and coin:FindFirstChild("TouchInterest") and coin.Transparency == 1 then
            local d = (myHrp.Position - coin.Position).Magnitude
            if d < bestDist then bestDist = d; best = coin end
        end
    end
    return best, bestDist
end

local function farmStartNoclip()
    if farmNoclipConn then return end
    farmNoclipConn = RunService.Stepped:Connect(function()
        if F.farmCoins and LocalPlayer.Character then
            for _, p in pairs(LocalPlayer.Character:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
    end)
end

local function farmStopNoclip()
    if farmNoclipConn then farmNoclipConn:Disconnect(); farmNoclipConn = nil end
end

local function startFarming()
    if not char() or not hrp() then return end
    if LocalPlayer:GetAttribute("Alive") ~= true then return end
    local root = hrp(); local h = hum()
    farmParts = {}
    for _, p in pairs(char():GetDescendants()) do
        if p:IsA("BasePart") then farmParts[p] = { CanCollide = p.CanCollide, Massless = p.Massless } end
    end
    root.CFrame = root.CFrame - Vector3.new(0, 2.5, 0)
    root.CFrame = root.CFrame * CFrame.Angles(math.rad(90), 0, 0)
    if h then
        h.PlatformStand = true
        h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        h:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    end
    farmActive = true; farmRotated = true
end

local function stopFarming()
    farmActive = false
    if farmTween    then farmTween:Cancel(); farmTween = nil end
    if farmHoldConn then farmHoldConn:Disconnect(); farmHoldConn = nil end
    if farmNoclipConn then farmNoclipConn:Disconnect(); farmNoclipConn = nil end
    if char() and farmRotated then
        for p, orig in pairs(farmParts) do
            if p and p.Parent then p.CanCollide = orig.CanCollide; p.Massless = orig.Massless end
        end
        local root = hrp()
        if root then
            root.Velocity = Vector3.zero; root.RotVelocity = Vector3.zero
            root.CFrame = root.CFrame * CFrame.Angles(math.rad(-90), 0, 0)
            root.CFrame = root.CFrame + Vector3.new(0, 2.5, 0)
        end
        local h = hum()
        if h then
            h.PlatformStand = false
            h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
            h:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
        end
    end
    farmParts = {}; farmRotated = false
end

if REFS.CoinCollected then
    trackConn("coinCollected", REFS.CoinCollected.OnClientEvent:Connect(function(coinType, collected, total)
        if coinType == "Coin" then
            if tonumber(collected) == tonumber(total) then
                bagFull = true
                if farmActive then stopFarming() end
            else bagFull = false end
        end
    end))
end
if REFS.RoundStart    then trackConn("roundStart", REFS.RoundStart.OnClientEvent:Connect(function() bagFull = false end)) end
if REFS.RoundEndFade  then
    trackConn("roundEnd", REFS.RoundEndFade.OnClientEvent:Connect(function()
        bagFull = false
        if farmActive then stopFarming() end
    end))
end

trackConn("farmTouch", RunService.Heartbeat:Connect(function()
    if farmActive and char() and hrp() and LocalPlayer:GetAttribute("Alive") == true then
        local root = hrp(); local cc = coinContainer()
        if cc then
            for _, coin in pairs(cc:GetChildren()) do
                if coin:IsA("BasePart") and (coin:GetAttribute("CoinID") == "Coin" or coin.Name == "Coin_Server")
                and coin:FindFirstChild("TouchInterest") and coin.Transparency == 1 then
                    local d = (root.Position - coin.Position).Magnitude
                    if d <= 5 then
                        if hasFTI then firetouchinterest(root, coin, 0); firetouchinterest(root, coin, 1)
                        else root.CFrame = coin.CFrame end
                    end
                end
            end
        end
    end
end))

trackConn("farmGlide", RunService.Heartbeat:Connect(function()
    if farmBusy then return end
    if F.farmCoins and not bagFull and LocalPlayer:GetAttribute("Alive") == true and char() and hrp() then
        local cc = coinContainer()
        if cc then
            local coin, dist = findNearestCoin(cc)
            if coin and coin.Transparency == 1 and not bagFull then
                farmBusy = true
                if not farmActive then startFarming() end
                local root = hrp(); local h = hum()
                root.Velocity = Vector3.zero; root.RotVelocity = Vector3.zero
                local goal   = coin.Position - Vector3.new(0, 2.5, 0)
                local goalCF = CFrame.new(goal) * CFrame.Angles(math.rad(90), 0, 0)
                farmStartNoclip()
                local tweenInfo = TweenInfo.new(dist / CFG.farmSpeed, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
                farmTween = TweenService:Create(root, tweenInfo, { CFrame = goalCF })
                farmTween:Play()
                if farmHoldConn then farmHoldConn:Disconnect(); farmHoldConn = nil end
                farmHoldConn = RunService.Heartbeat:Connect(function()
                    if F.farmCoins and LocalPlayer:GetAttribute("Alive") == true and root and root.Parent then
                        root.Velocity = Vector3.zero; root.RotVelocity = Vector3.zero
                        if h then h.PlatformStand = true end
                    else
                        if farmHoldConn then farmHoldConn:Disconnect(); farmHoldConn = nil end
                    end
                end)
                task.spawn(function()
                    local deadline = tick() + math.max(dist / CFG.farmSpeed + 2, 4)
                    while coin and coin.Parent and coin:FindFirstChild("TouchInterest") and coin.Transparency == 1
                    and not bagFull and F.farmCoins and LocalPlayer:GetAttribute("Alive") == true and tick() < deadline do
                        RunService.Heartbeat:Wait()
                    end
                    if farmHoldConn then farmHoldConn:Disconnect(); farmHoldConn = nil end
                    if farmTween then farmTween:Cancel(); farmTween = nil end
                    if root and root.Parent then root.Velocity = Vector3.zero; root.RotVelocity = Vector3.zero end
                    farmBusy = false
                end)
            else if farmActive then stopFarming() end end
        else if farmActive then stopFarming() end end
    else if farmActive then stopFarming() end end
end))

-- ─── PLAYER LOOPS ─────────────────────────────────────────────────────────────
trackConn("noclip", RunService.Stepped:Connect(function()
    if not F.noclip then return end
    local c = LocalPlayer.Character
    if c then
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
        end
    end
end))

trackConn("infJump", UserInputService.JumpRequest:Connect(function()
    if not F.infJump then return end
    local h = hum()
    if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
end))

local flyBv, flyBg, flyRS
local FLY_STATES = {
    Enum.HumanoidStateType.Climbing, Enum.HumanoidStateType.FallingDown,
    Enum.HumanoidStateType.Flying,   Enum.HumanoidStateType.Freefall,
    Enum.HumanoidStateType.GettingUp,Enum.HumanoidStateType.Jumping,
    Enum.HumanoidStateType.Landed,   Enum.HumanoidStateType.Physics,
    Enum.HumanoidStateType.PlatformStanding, Enum.HumanoidStateType.Ragdoll,
    Enum.HumanoidStateType.Running,  Enum.HumanoidStateType.RunningNoPhysics,
    Enum.HumanoidStateType.Seated,   Enum.HumanoidStateType.StrafingNoPhysics,
    Enum.HumanoidStateType.Swimming,
}

local function startFly()
    local c = char(); local h = hum()
    local root = c and c:FindFirstChild("HumanoidRootPart")
    if not (c and h and root) then return end
    for _, s in ipairs(FLY_STATES) do pcall(function() h:SetStateEnabled(s, false) end) end
    pcall(function() h:ChangeState(Enum.HumanoidStateType.Swimming) end)
    h.PlatformStand = true
    flyBg = Instance.new("BodyGyro", root)
    flyBg.P = 9e4; flyBg.MaxTorque = Vector3.new(9e9, 9e9, 9e9); flyBg.CFrame = root.CFrame
    flyBv = Instance.new("BodyVelocity", root)
    flyBv.Velocity = Vector3.zero; flyBv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    flyRS = RunService.RenderStepped:Connect(function()
        if not F.fly or not c or not h or not h.Parent then return end
        flyBg.CFrame = Camera.CoordinateFrame
        local move = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W)           then move = move + Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S)           then move = move - Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A)           then move = move - Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D)           then move = move + Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space)       then move = move + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move = move - Vector3.new(0, 1, 0) end
        if move.Magnitude > 0 then move = move.Unit end
        flyBv.Velocity = move * CFG.flySpeed
    end)
end

local function stopFly()
    if flyRS then flyRS:Disconnect(); flyRS = nil end
    if flyBg then flyBg:Destroy(); flyBg = nil end
    if flyBv then flyBv:Destroy(); flyBv = nil end
    local h = hum()
    if h then
        for _, s in ipairs(FLY_STATES) do pcall(function() h:SetStateEnabled(s, true) end) end
        pcall(function() h:ChangeState(Enum.HumanoidStateType.RunningNoPhysics) end)
        h.PlatformStand = false
    end
end

trackConn("spin", RunService.RenderStepped:Connect(function()
    if not F.spin then return end
    local h = hrp()
    if h then h.CFrame = h.CFrame * CFrame.Angles(0, math.rad(CFG.spinSpeed), 0) end
end))

trackConn("ghostMode", RunService.Stepped:Connect(function()
    if not F.ghostMode then return end
    local c = LocalPlayer.Character
    if c then
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false; p.LocalTransparencyModifier = 0.5 end
        end
    end
end))

trackConn("rainbowChar", RunService.Heartbeat:Connect(function()
    if not F.rainbowChar then return end
    local c = LocalPlayer.Character
    if not c then return end
    local hue = (tick() * 120) % 360
    local col = Color3.fromHSV(hue / 360, 1, 1)
    for _, part in pairs(c:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then part.Color = col end
    end
end))

local origHeadSize = nil
local function setBigHead(on)
    local c    = LocalPlayer.Character
    local head = c and c:FindFirstChild("Head")
    if not head then return end
    if on then
        if not origHeadSize then origHeadSize = head.Size end
        head.Size = Vector3.new(3, 3, 3)
    else
        head.Size = origHeadSize or Vector3.new(2, 1, 1)
    end
end

local bigHeadApplied = false
trackConn("bigHead", RunService.Heartbeat:Connect(function()
    if not F.bigHead then bigHeadApplied = false; return end
    local c    = LocalPlayer.Character
    local head = c and c:FindFirstChild("Head")
    if not head then bigHeadApplied = false; return end
    if not bigHeadApplied or head.Size ~= Vector3.new(3, 3, 3) then
        setBigHead(true); bigHeadApplied = true
    end
end))

local trailAtt0, trailAtt1, trailObj
local function setTrail(on)
    local c   = LocalPlayer.Character
    local HRP = c and c:FindFirstChild("HumanoidRootPart")
    if not HRP then return end
    if trailObj  then pcall(function() trailObj:Destroy()  end); trailObj  = nil end
    if trailAtt0 then pcall(function() trailAtt0:Destroy() end); trailAtt0 = nil end
    if trailAtt1 then pcall(function() trailAtt1:Destroy() end); trailAtt1 = nil end
    if not on then return end
    trailAtt0 = Instance.new("Attachment", HRP); trailAtt0.Position = Vector3.new(0, -2, 0)
    trailAtt1 = Instance.new("Attachment", HRP); trailAtt1.Position = Vector3.new(0,  2, 0)
    trailObj = Instance.new("Trail", HRP)
    trailObj.Attachment0 = trailAtt0; trailObj.Attachment1 = trailAtt1
    trailObj.Lifetime = 1
    trailObj.Color = ColorSequence.new(CFG.trailColor, CFG.trailColor)
end

trackConn("trailColor", RunService.Heartbeat:Connect(function()
    if not F.rainbowTrail or not trailObj then return end
    local hue = (tick() * 120) % 360
    local col = Color3.fromHSV(hue / 360, 1, 1)
    trailObj.Color = ColorSequence.new(col, col)
end))

local function setForceField(on)
    local c = LocalPlayer.Character
    if not c then return end
    for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") then
            p.Material = on and Enum.Material.ForceField or Enum.Material.Plastic
        end
    end
end

local function setScale(val)
    local h = hum()
    if not h then return end
    local function getOrCreate(name)
        local v = h:FindFirstChild(name)
        if not v then v = Instance.new("NumberValue"); v.Name = name; v.Parent = h end
        return v
    end
    getOrCreate("BodyHeightScale").Value = val
    getOrCreate("BodyWidthScale").Value  = val
    getOrCreate("BodyDepthScale").Value  = val
end

local nametagGui
local function setNametag(on)
    if nametagGui then pcall(function() nametagGui:Destroy() end); nametagGui = nil end
    if not on then return end
    local c    = LocalPlayer.Character
    local head = c and c:FindFirstChild("Head")
    if not head then return end
    nametagGui = Instance.new("BillboardGui")
    nametagGui.Name = "BFNametag"; nametagGui.Size = UDim2.new(0, 200, 0, 30)
    nametagGui.StudsOffset = Vector3.new(0, 2.5, 0); nametagGui.AlwaysOnTop = true
    nametagGui.Adornee = head; nametagGui.Parent = safeParent()
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0); lbl.BackgroundTransparency = 1
    lbl.Text = CFG.nametagText; lbl.TextColor3 = CFG.trailColor
    lbl.TextScaled = true; lbl.Font = Enum.Font.GothamBold; lbl.Parent = nametagGui
end

local floatBv
local function setFloat(on)
    if floatBv then pcall(function() floatBv:Destroy() end); floatBv = nil end
    if not on then return end
    local c   = LocalPlayer.Character
    local HRP = c and c:FindFirstChild("HumanoidRootPart")
    if not HRP then return end
    floatBv = Instance.new("BodyVelocity", HRP)
    floatBv.Velocity = Vector3.zero; floatBv.MaxForce = Vector3.new(0, math.huge, 0)
end

local origGravity = workspace.Gravity
local function applyGravity()
    workspace.Gravity = F.lowGrav and CFG.gravity or origGravity
end

local function applyFOV()  Camera.FieldOfView = CFG.fov end
local function applyZoom() LocalPlayer.CameraMaxZoomDistance = CFG.maxZoom end

local freecamPart, freecamRS
local function startFreecam()
    if freecamPart then return end
    freecamPart = Instance.new("Part")
    freecamPart.Anchored = true; freecamPart.CanCollide = false
    freecamPart.Transparency = 1; freecamPart.Size = Vector3.new(1, 1, 1)
    freecamPart.CFrame = Camera.CFrame; freecamPart.Parent = workspace
    Camera.CameraType = Enum.CameraType.Scriptable
    freecamRS = RunService.RenderStepped:Connect(function()
        if not F.freecam then return end
        local speed = CFG.freecamSpeed * 2; local cf = Camera.CFrame; local move = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W)           then move = move + cf.LookVector  * speed end
        if UserInputService:IsKeyDown(Enum.KeyCode.S)           then move = move - cf.LookVector  * speed end
        if UserInputService:IsKeyDown(Enum.KeyCode.A)           then move = move - cf.RightVector * speed end
        if UserInputService:IsKeyDown(Enum.KeyCode.D)           then move = move + cf.RightVector * speed end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space)       then move = move + Vector3.new(0,  speed, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move = move - Vector3.new(0,  speed, 0) end
        freecamPart.CFrame = freecamPart.CFrame + move
        Camera.CFrame = freecamPart.CFrame
    end)
end

local function stopFreecam()
    if freecamRS   then freecamRS:Disconnect();   freecamRS   = nil end
    if freecamPart then freecamPart:Destroy();    freecamPart = nil end
    Camera.CameraType = Enum.CameraType.Custom
    resetCamera()
end

trackConn("antiVoid", RunService.Heartbeat:Connect(function()
    if not F.antiVoid then return end
    local HRP = hrp()
    if HRP and HRP.Position.Y < -80 then HRP.CFrame = CFrame.new(0, 50, 0) end
end))

local scriptRunning = true
task.spawn(function()
    while scriptRunning do
        task.wait(60)
        if F.antiAfk then
            local vui = game:GetService("VirtualUser")
            if vui then pcall(function()
                vui:Button2Down(Vector2.new(0,0), CFrame.new())
                task.wait(0.1)
                vui:Button2Up(Vector2.new(0,0), CFrame.new())
            end) end
        end
    end
end)

local lastAlarm = 0
trackConn("alarm", RunService.Heartbeat:Connect(function()
    if not F.alarm then return end
    local HRP = hrp()
    if not HRP then return end
    for _, p in ipairs(others()) do
        if roleOf(p) == "Murderer" and p.Character then
            local tHRP = p.Character:FindFirstChild("HumanoidRootPart")
            if tHRP and (HRP.Position - tHRP.Position).Magnitude <= CFG.alarmDist then
                if tick() - lastAlarm > 5 then
                    lastAlarm = tick()
                    notify("MURDERER NEAR!", p.Name .. " is close!", 3, "warning")
                end
            end
        end
    end
end))

trackConn("autoEvade", RunService.Heartbeat:Connect(function()
    if not F.autoEvade then return end
    local HRP = hrp()
    if not HRP then return end
    local m = getMurderer()
    if not m or not m.Character then return end
    local mHRP = m.Character:FindFirstChild("HumanoidRootPart")
    if not mHRP then return end
    local dist = (HRP.Position - mHRP.Position).Magnitude
    if dist < CFG.evadeDist then
        local dir = Vector3.new((HRP.Position - mHRP.Position).X, 0, (HRP.Position - mHRP.Position).Z)
        if dir.Magnitude > 0 then dir = dir.Unit end
        HRP.CFrame = HRP.CFrame + dir * CFG.evadeSpeed * 0.05
    end
end))

trackConn("antiKill", RunService.Heartbeat:Connect(function()
    if not F.antiKill then return end
    local HRP = hrp()
    if not HRP then return end
    local m = getMurderer()
    if not m or not m.Character then return end
    local mHRP = m.Character:FindFirstChild("HumanoidRootPart")
    if not mHRP then return end
    if (HRP.Position - mHRP.Position).Magnitude < CFG.antiKillDist then
        local dir = Vector3.new((HRP.Position - mHRP.Position).X, 0, (HRP.Position - mHRP.Position).Z)
        if dir.Magnitude > 0 then dir = dir.Unit end
        HRP.CFrame = CFrame.new(HRP.Position + dir * 40 + Vector3.new(0, 5, 0))
    end
end))

local fxFolder
local dodging = false

local function afterimage(cfStart, cfEnd, n)
    local c = LocalPlayer.Character
    if not c then return end
    if not (fxFolder and fxFolder.Parent) then
        fxFolder = Instance.new("Folder"); fxFolder.Name = "BF_FX"; fxFolder.Parent = workspace
    end
    for i = 1, n do
        local cf   = cfStart:Lerp(cfEnd, i / (n + 1))
        local clone; local ok = pcall(function() c.Archivable = true; clone = c:Clone() end)
        if ok and clone then
            for _, d in ipairs(clone:GetDescendants()) do
                if d:IsA("Humanoid") or d:IsA("Script") or d:IsA("LocalScript")
                or d:IsA("Tool")     or d:IsA("BillboardGui") then
                    pcall(function() d:Destroy() end)
                elseif d:IsA("BasePart") then
                    d.Anchored = true; d.CanCollide = false; d.CanQuery = false
                    d.Material = Enum.Material.Neon; d.Color = CFG.trailColor; d.Transparency = 0.5
                end
            end
            clone.Name = "BF_AfterImage"; clone.Parent = fxFolder
            pcall(function() clone:PivotTo(cf) end)
            task.spawn(function()
                for a = 0.5, 1, 0.08 do
                    for _, d in ipairs(clone:GetDescendants()) do
                        if d:IsA("BasePart") then d.Transparency = a end
                    end
                    task.wait(0.03)
                end
                pcall(function() clone:Destroy() end)
            end)
        end
    end
end

local function flashStep(dir)
    local HRP = hrp()
    if not HRP or dodging then return end
    if not dir or dir.Magnitude < 0.1 then dir = HRP.CFrame.RightVector end
    dir = Vector3.new(dir.X, 0, dir.Z)
    if dir.Magnitude < 0.1 then dir = HRP.CFrame.RightVector end
    dir = dir.Unit; dodging = true
    local startCF = HRP.CFrame
    local endCF   = startCF - startCF.Position + (startCF.Position + dir * 14)
    afterimage(startCF, endCF, 4)
    task.spawn(function()
        for i = 1, 10 do
            local h = hrp()
            if not h then break end
            pcall(function() h.CFrame = startCF:Lerp(endCF, i / 10); h.AssemblyLinearVelocity = Vector3.zero end)
            task.wait(0.013)
        end
        dodging = false
    end)
end

local function flashStepManual()
    local HRP = hrp(); local h = hum()
    if not (HRP and h) then return end
    local dir = h.MoveDirection
    if dir.Magnitude < 0.1 then dir = Camera.CFrame.LookVector end
    flashStep(dir)
end

trackConn("knifeWatch", workspace.DescendantAdded:Connect(function(d)
    if not F.autoEvade then return end
    if not d:IsA("BasePart") then return end
    if not string.find(string.lower(d.Name), "knife") then return end
    task.spawn(function()
        for _ = 1, 45 do
            if not F.autoEvade or dodging then return end
            local HRP = hrp()
            if not HRP or not d.Parent then return end
            local vel  = d.AssemblyLinearVelocity
            local toMe = HRP.Position - d.Position
            local dist = toMe.Magnitude
            if vel.Magnitude > 16 and dist < 26 and dist > 2 and vel.Unit:Dot(toMe.Unit) > 0.35 then
                flashStep(vel.Unit:Cross(Vector3.new(0, 1, 0)))
                return
            end
            task.wait(0.02)
        end
    end)
end))

-- ─── TROLL ────────────────────────────────────────────────────────────────────
local trollSelected = nil
local flingTargets  = { target = false, all = false, sheriff = false, murderer = false }
local flingRunning  = false
local flingOldPos   = nil
local flingFPDH     = workspace.FallenPartsDestroyHeight

local function anyFling()
    return flingTargets.target or flingTargets.all or flingTargets.sheriff or flingTargets.murderer
end
local function stopFling()
    flingTargets.target   = false; flingTargets.all      = false
    flingTargets.sheriff  = false; flingTargets.murderer = false
    flingRunning = false
end

local function skidFling(targetPlayer)
    local c  = LocalPlayer.Character
    local h  = c and c:FindFirstChildOfClass("Humanoid")
    local root = h and h.RootPart
    local tc   = targetPlayer.Character
    if not tc or not c or not h or not root then return end
    local th   = tc:FindFirstChildOfClass("Humanoid")
    local tr   = th and th.RootPart
    local thead  = tc:FindFirstChild("Head")
    local tacc   = tc:FindFirstChildOfClass("Accessory")
    local thnd   = tacc and tacc:FindFirstChild("Handle")
    if root.Velocity.Magnitude < 50 then flingOldPos = root.CFrame end
    if th and th.Sit then return end
    local sub = thead or thnd or th
    if sub then workspace.CurrentCamera.CameraSubject = sub end
    if not tc:FindFirstChildWhichIsA("BasePart") then return end
    local function FPos(bp, pos, ang)
        root.CFrame = CFrame.new(bp.Position) * pos * ang
        c:SetPrimaryPartCFrame(CFrame.new(bp.Position) * pos * ang)
        root.Velocity    = Vector3.new(9e7, 9e7 * 10, 9e7)
        root.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
    end
    local function SFB(bp)
        local t0 = tick(); local ang = 0
        repeat
            if root and th then
                if bp.Velocity.Magnitude < 50 then
                    ang = ang + 100; local d = th.MoveDirection
                    FPos(bp, CFrame.new(0, 1.5, 0) + d * bp.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(ang), 0, 0)); task.wait()
                    FPos(bp, CFrame.new(0,-1.5, 0) + d * bp.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(ang), 0, 0)); task.wait()
                    FPos(bp, CFrame.new(0, 1.5, 0) + d, CFrame.Angles(math.rad(ang), 0, 0)); task.wait()
                    FPos(bp, CFrame.new(0,-1.5, 0) + d, CFrame.Angles(math.rad(ang), 0, 0)); task.wait()
                else
                    local ws = th.WalkSpeed
                    FPos(bp, CFrame.new(0, 1.5,  ws), CFrame.Angles(math.rad(90), 0, 0)); task.wait()
                    FPos(bp, CFrame.new(0,-1.5, -ws), CFrame.Angles(0, 0, 0)); task.wait()
                    FPos(bp, CFrame.new(0,-1.5, 0),   CFrame.Angles(math.rad(90), 0, 0)); task.wait()
                    FPos(bp, CFrame.new(0,-1.5, 0),   CFrame.Angles(0, 0, 0)); task.wait()
                end
            end
        until tick() > t0 + 2 or not anyFling()
    end
    workspace.FallenPartsDestroyHeight = 0 / 0
    local bv = Instance.new("BodyVelocity", root)
    bv.Velocity = Vector3.zero; bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    h:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
    if tr then SFB(tr) elseif thead then SFB(thead) elseif thnd then SFB(thnd) end
    bv:Destroy()
    h:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
    workspace.CurrentCamera.CameraSubject = h
    if flingOldPos then
        repeat
            root.CFrame = flingOldPos * CFrame.new(0, 0.5, 0)
            c:SetPrimaryPartCFrame(flingOldPos * CFrame.new(0, 0.5, 0))
            h:ChangeState(Enum.HumanoidStateType.GettingUp)
            for _, p in ipairs(c:GetChildren()) do
                if p:IsA("BasePart") then p.Velocity = Vector3.zero; p.RotVelocity = Vector3.zero end
            end
            task.wait()
        until (root.Position - flingOldPos.p).Magnitude < 25
        workspace.FallenPartsDestroyHeight = flingFPDH
    end
end

local function flingLoop()
    if flingRunning then return end
    flingRunning = true
    task.spawn(function()
        while anyFling() do
            if flingTargets.target and trollSelected then
                local p = Players:FindFirstChild(trollSelected)
                if p and p.Character then skidFling(p) end
            end
            if flingTargets.all then
                for _, p in ipairs(others()) do
                    if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then skidFling(p); task.wait(0.1) end
                end
            end
            if flingTargets.sheriff then
                for _, p in ipairs(others()) do
                    if roleOf(p) == "Sheriff" and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then skidFling(p); task.wait(0.1) end
                end
            end
            if flingTargets.murderer then
                for _, p in ipairs(others()) do
                    if roleOf(p) == "Murderer" and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then skidFling(p); task.wait(0.1) end
                end
            end
            task.wait(0.3)
        end
        flingRunning = false
    end)
end

local DANCES    = { ["Dance 1"]="127118661424463", ["Dance 2"]="82682811348660", ["Dance 3"]="10714340543", ["Dance 4"]="15609995579" }
local danceTrack = nil

local function playDance()
    local h = hum()
    if not h then return end
    local anim   = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://" .. tostring(DANCES[CFG.danceSel] or DANCES["Dance 1"])
    local animator = h:FindFirstChildOfClass("Animator")
    if not animator then animator = Instance.new("Animator"); animator.Parent = h end
    pcall(function()
        if danceTrack then danceTrack:Stop() end
        danceTrack = animator:LoadAnimation(anim)
        danceTrack.Priority = Enum.AnimationPriority.Action
        danceTrack:Play()
    end)
end

local function stopDance()
    if danceTrack then pcall(function() danceTrack:Stop() end); danceTrack = nil end
end

trackConn("autoDance", RunService.Heartbeat:Connect(function()
    if not F.autoDance then return end
    if not danceTrack or not danceTrack.IsPlaying then playDance() end
end))

local function sendRolesInChat()
    local mn, sn = "?", "?"
    for _, p in ipairs(Players:GetPlayers()) do
        if roleOf(p) == "Murderer" then mn = p.Name end
        if roleOf(p) == "Sheriff"  then sn = p.Name end
    end
    local msg = "Murderer: " .. mn .. " | Sheriff: " .. sn
    local lc  = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
    if lc and lc:FindFirstChild("SayMessageRequest") then
        lc.SayMessageRequest:FireServer(msg, "All")
    else
        local tcs = game:GetService("TextChatService")
        if tcs then
            local ch = tcs:FindFirstChild("TextChannels") and tcs.TextChannels:FindFirstChild("RBXGeneral")
            if ch then pcall(function() ch:SendAsync(msg) end) end
        end
    end
end

-- ─── CHARADDED ────────────────────────────────────────────────────────────────
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.6)
    applyMovement(); applyFOV(); applyZoom(); applyGravity()
    if F.bigHead      then setBigHead(true) end
    if F.rainbowTrail then setTrail(true)   end
    if F.nametagOn    then setNametag(true)  end
    if F.forceField   then setForceField(true) end
    if F.playerScale  then setScale(CFG.scaleSize) end
    if F.floatMode    then setFloat(true)   end
end)

-- ─── SHOOT MODE HELPER ────────────────────────────────────────────────────────
local function setShootMode(mode)
    F.wallbang     = (mode == "Wallbang")
    F.autoShoot    = (mode == "Auto Shoot")
    F.blatantShoot = (mode == "Blatant")
    F.silentAim    = (mode == "Silent Aim")
    F.triggerBot   = (mode == "Trigger Bot")
    if mode ~= "Silent Aim" then restoreSilentAim() end
end

-- ════════════════════════════════════════════════════════════════════════════
--  WINDOW + UI
-- ════════════════════════════════════════════════════════════════════════════
local Window = Library:CreateWindow({
    Title       = "Bigfroot",
    Footer      = "Murder Mystery 2  |  b1",
    Folder      = "Bigfroot/mm2",
    Hub         = "BF Hub",
    Icon        = "skull",
    MenuKeybind = Enum.KeyCode.RightShift,
})

-- ─── HOME TAB ─────────────────────────────────────────────────────────────────
local Home = Window:AddHomeTab({
    Announcements = {
        { Title = "Bigfroot v1.1", Date = "2026-09-16", Text = "All features active. Press RightShift to toggle." },
    },
})

Home:AddStat("Murderer", "?")
Home:AddStat("Sheriff",  "?")
Home:AddStat("Players",  tostring(#Players:GetPlayers()))

Home:Pin("EspEnabled")
Home:Pin("FarmCoins")
Home:Pin("AntiAfk")

task.spawn(function()
    while true do
        task.wait(2)
        local m = getMurderer()
        local s = getSheriff()
        Home:SetStat("Murderer", m and m.Name or "?")
        Home:SetStat("Sheriff",  s and s.Name or "?")
        Home:SetStat("Players",  tostring(#Players:GetPlayers()))
    end
end)

-- ─── COMBAT TAB ───────────────────────────────────────────────────────────────
local CombatTab  = Window:AddTab("Combat", "crosshair")
local MurderBox  = CombatTab:AddLeftGroupbox("Murderer")
local SheriffBox = CombatTab:AddRightGroupbox("Sheriff")

MurderBox:AddButton({
    Text     = "Kill All (TP Stab)",
    Risky    = true,
    Callback = function()
        local HRP   = hrp()
        local knife = myKnife()
        if not HRP or not knife then notify("Error", "Equip a knife first.", 3, "error"); return end
        local ht = knife:FindFirstChild("Events") and knife.Events:FindFirstChild("HandleTouched")
        if not ht then notify("Error", "No HandleTouched event found.", 3, "error"); return end
        local saved = HRP.CFrame; local killed = 0
        for _, p in ipairs(others()) do
            local c = p.Character
            if c and c:FindFirstChild("HumanoidRootPart") then
                local tHRP = c.HumanoidRootPart
                local h    = c:FindFirstChildOfClass("Humanoid")
                if h and h.Health > 0 and (HRP.Position - tHRP.Position).Magnitude <= 200 then
                    HRP.CFrame = tHRP.CFrame * CFrame.new(0, 0, 1.5)
                    pcall(function() ht:FireServer(tHRP) end)
                    killed = killed + 1; task.wait(0.06)
                end
            end
        end
        HRP.CFrame = saved
        notify("Kill All", "Fired on " .. killed .. " targets.", 3, "success")
    end,
})
MurderBox:AddToggle("AutoKill", { Text = "Auto Kill (TP loop)", Default = false }):OnChanged(function(v)
    F.autoKill = v
end)
MurderBox:AddToggle("KillAura", { Text = "Kill Aura", Default = false }):OnChanged(function(v)
    F.killAura = v
end)
MurderBox:AddSlider("KillRadius", { Text = "Aura Radius", Default = 18, Min = 5, Max = 80, Rounding = 0 }):OnChanged(function(v)
    CFG.killRadius = v
end)
MurderBox:AddDivider("Knife")
MurderBox:AddToggle("KnifeReach", { Text = "Knife Reach", Default = false }):OnChanged(function(v)
    F.knifeReach = v
end)
MurderBox:AddSlider("KnifeRadius", { Text = "Reach Radius", Default = 12, Min = 5, Max = 200, Rounding = 0 }):OnChanged(function(v)
    CFG.knifeRadius = v
end)
MurderBox:AddToggle("KnifeSilent", { Text = "Silent Throw Aim", Default = false }):OnChanged(function(v)
    F.knifeSilent = v
end)
MurderBox:AddToggle("AutoEquip", { Text = "Auto Equip Knife/Gun", Default = false }):OnChanged(function(v)
    F.autoEquip = v
end)

SheriffBox:AddDropdown("ShootMode", {
    Text    = "Shoot Mode",
    Values  = { "Off", "Auto Shoot", "Wallbang", "Blatant", "Silent Aim", "Trigger Bot" },
    Default = "Off",
}):OnChanged(function(v) setShootMode(v) end)

SheriffBox:AddSlider("AimFov", { Text = "Aim FOV", Default = 120, Min = 20, Max = 400, Rounding = 0 }):OnChanged(function(v)
    CFG.aimFov = v
end)
SheriffBox:AddDropdown("AimPart", {
    Text    = "Aim Part",
    Values  = { "Head", "HumanoidRootPart", "Torso" },
    Default = "Head",
}):OnChanged(function(v) CFG.aimPart = v end)

SheriffBox:AddToggle("CamLock", { Text = "Camera Lock", Default = false }):OnChanged(function(v)
    F.camLock = v
end)

SheriffBox:AddButton({
    Text     = "Shoot Murderer Now",
    Callback = function()
        local m = getMurderer()
        if not m or not m.Character then notify("Shoot", "No murderer found.", 3, "error"); return end
        local t   = m.Character:FindFirstChild("Head") or m.Character:FindFirstChild("HumanoidRootPart")
        local gun = myGun()
        if gun then pcall(function() gun:Activate() end) end
        if REFS.GunBeam and t then pcall(function() REFS.GunBeam:FireServer(CFrame.new(t.Position)) end) end
    end,
})
SheriffBox:AddDivider("Gun Pickup")
SheriffBox:AddButton({
    Text     = "Grab Dropped Gun",
    Callback = grabGun,
})
SheriffBox:AddToggle("AutoGun", { Text = "Auto Grab Gun", Default = false }):OnChanged(function(v)
    F.autoGun = v
end)
SheriffBox:AddDivider("Intel")
SheriffBox:AddToggle("AutoDetect", { Text = "Auto-Detect Murderer", Default = false }):OnChanged(function(v)
    F.autoDetect = v
end)
SheriffBox:AddButton({
    Text     = "Who's the Murderer?",
    Callback = function()
        local m = getMurderer()
        local s = getSheriff()
        notify("Roles", "Murderer: " .. (m and m.Name or "?") .. "\nSheriff: " .. (s and s.Name or "?"), 5)
    end,
})

-- ─── VISUALS TAB ──────────────────────────────────────────────────────────────
local VisualsTab = Window:AddTab("Visuals", "eye")
local EspBox     = VisualsTab:AddLeftGroupbox("Player ESP")
local WorldBox   = VisualsTab:AddRightGroupbox("World")

EspBox:AddToggle("EspEnabled", { Text = "Enable ESP", Default = false }):OnChanged(function(v)
    F.espEnabled = v
    if not v then espClearAll() end
end)
EspBox:AddToggle("EspBox",       { Text = "Box",              Default = true  }):OnChanged(function(v) F.espBox       = v end)
EspBox:AddToggle("EspTracer",    { Text = "Tracer",           Default = false }):OnChanged(function(v) F.espTracer    = v end)
EspBox:AddToggle("EspName",      { Text = "Name + Role",      Default = true  }):OnChanged(function(v) F.espName      = v end)
EspBox:AddToggle("EspDist",      { Text = "Distance",         Default = true  }):OnChanged(function(v) F.espDist      = v end)
EspBox:AddToggle("EspHealth",    { Text = "Health",           Default = true  }):OnChanged(function(v) F.espHealth    = v end)
EspBox:AddToggle("EspHighlight", { Text = "Highlight (Chams)",Default = true  }):OnChanged(function(v) F.espHighlight = v end)
EspBox:AddToggle("EspSkeleton",  { Text = "Skeleton",         Default = false }):OnChanged(function(v) F.espSkeleton  = v end)
EspBox:AddToggle("EspRoleColor", { Text = "Role Colors",      Default = true  }):OnChanged(function(v) F.espRoleColor = v end)
EspBox:AddSlider("EspMaxDist",   { Text = "Max Distance", Default = 2000, Min = 100, Max = 5000, Rounding = 0 }):OnChanged(function(v)
    CFG.espMaxDist = v
end)
EspBox:AddDivider("Role Colors")
EspBox:AddLabel({ Text = "Murderer" }):AddColorPicker("cMurd", { Default = CFG.cMurd, Title = "Murderer Color" }):OnChanged(function(c)
    CFG.cMurd = c
end)
EspBox:AddLabel({ Text = "Sheriff" }):AddColorPicker("cSher", { Default = CFG.cSher, Title = "Sheriff Color" }):OnChanged(function(c)
    CFG.cSher = c
end)
EspBox:AddLabel({ Text = "Hero" }):AddColorPicker("cHero", { Default = CFG.cHero, Title = "Hero Color" }):OnChanged(function(c)
    CFG.cHero = c
end)
EspBox:AddLabel({ Text = "Innocent" }):AddColorPicker("cInno", { Default = CFG.cInno, Title = "Innocent Color" }):OnChanged(function(c)
    CFG.cInno = c
end)

WorldBox:AddToggle("CoinEsp", { Text = "Coin ESP", Default = false }):OnChanged(function(v)
    F.coinEsp = v
    if not v then for _, hl in pairs(ESP.coinHL) do pcall(function() hl:Destroy() end) end; ESP.coinHL = {} end
end)
WorldBox:AddToggle("DropEsp", { Text = "Gun Drop ESP", Default = false }):OnChanged(function(v)
    F.dropEsp = v
    if not v then for _, hl in pairs(ESP.dropHL) do pcall(function() hl:Destroy() end) end; ESP.dropHL = {} end
end)
WorldBox:AddDivider("World")
WorldBox:AddToggle("Fullbright", { Text = "Fullbright", Default = false }):OnChanged(function(v)
    F.fullbright = v
    local amb = Lighting:FindFirstChild("BF_Amb")
    if v then
        if not amb then amb = Instance.new("ColorCorrectionEffect"); amb.Name = "BF_Amb"; amb.Parent = Lighting end
        amb.Brightness = 1; Lighting.Brightness = 2; Lighting.ClockTime = 14
    else
        if amb then amb:Destroy() end; Lighting.Brightness = 1
    end
end)
WorldBox:AddToggle("NoFog", { Text = "No Fog", Default = false }):OnChanged(function(v)
    F.noFog = v
    if v then
        Lighting:SetAttribute("BF_FogEnd", Lighting.FogEnd)
        Lighting:SetAttribute("BF_FogStart", Lighting.FogStart)
        Lighting.FogEnd = 100000; Lighting.FogStart = 100000
    else
        Lighting.FogEnd   = Lighting:GetAttribute("BF_FogEnd")   or 1000
        Lighting.FogStart = Lighting:GetAttribute("BF_FogStart") or 0
    end
end)

-- ─── PLAYER TAB ───────────────────────────────────────────────────────────────
local PlayerTab = Window:AddTab("Player", "user")
local MoveBox   = PlayerTab:AddLeftGroupbox("Movement")
local AppBox    = PlayerTab:AddRightGroupbox("Appearance")

MoveBox:AddToggle("WalkOn", { Text = "WalkSpeed", Default = false }):OnChanged(function(v)
    F.walkOn = v; applyMovement()
end)
MoveBox:AddSlider("WalkSpeed", { Text = "Walk Speed", Default = 16, Min = 16, Max = 200, Rounding = 0 }):OnChanged(function(v)
    CFG.walkSpeed = v; if F.walkOn then applyMovement() end
end)
MoveBox:AddToggle("JumpOn", { Text = "JumpPower", Default = false }):OnChanged(function(v)
    F.jumpOn = v; applyMovement()
end)
MoveBox:AddSlider("JumpPower", { Text = "Jump Power", Default = 50, Min = 50, Max = 400, Rounding = 0 }):OnChanged(function(v)
    CFG.jumpPower = v; if F.jumpOn then applyMovement() end
end)
MoveBox:AddToggle("InfJump", { Text = "Infinite Jump", Default = false }):OnChanged(function(v)
    F.infJump = v
end)
MoveBox:AddToggle("Fly", { Text = "Fly (WASD+Space/Ctrl)", Default = false }):OnChanged(function(v)
    F.fly = v; if v then startFly() else stopFly() end
end)
MoveBox:AddSlider("FlySpeed", { Text = "Fly Speed", Default = 50, Min = 10, Max = 300, Rounding = 0 }):OnChanged(function(v)
    CFG.flySpeed = v
end)
MoveBox:AddToggle("Noclip", { Text = "Noclip", Default = false }):OnChanged(function(v)
    F.noclip = v
    if not v then
        local c = LocalPlayer.Character
        if c then for _, p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = true end end end
    end
end)
MoveBox:AddToggle("Spin", { Text = "Spin", Default = false }):OnChanged(function(v) F.spin = v end)
MoveBox:AddSlider("SpinSpeed", { Text = "Spin Speed", Default = 10, Min = 1, Max = 100, Rounding = 0 }):OnChanged(function(v)
    CFG.spinSpeed = v
end)
MoveBox:AddToggle("AntiFling", { Text = "Anti-Fling", Default = false }):OnChanged(function(v) F.antiFling = v end)
MoveBox:AddToggle("FloatMode", { Text = "Float", Default = false }):OnChanged(function(v)
    F.floatMode = v; setFloat(v)
end)
MoveBox:AddDivider("Physics")
MoveBox:AddToggle("LowGrav", { Text = "Low Gravity", Default = false }):OnChanged(function(v)
    F.lowGrav = v; applyGravity()
end)
MoveBox:AddSlider("Gravity", { Text = "Gravity", Default = 50, Min = 5, Max = 196, Rounding = 0 }):OnChanged(function(v)
    CFG.gravity = v; if F.lowGrav then applyGravity() end
end)

AppBox:AddToggle("RainbowChar",  { Text = "Rainbow Body",         Default = false }):OnChanged(function(v) F.rainbowChar  = v end)
AppBox:AddToggle("BigHead",      { Text = "Big Head",             Default = false }):OnChanged(function(v)
    F.bigHead = v; if not v then setBigHead(false) end
end)
AppBox:AddToggle("RainbowTrail", { Text = "Rainbow Trail",        Default = false }):OnChanged(function(v)
    F.rainbowTrail = v; setTrail(v)
end):AddColorPicker("TrailColor", { Default = CFG.trailColor, Title = "Trail Color" }):OnChanged(function(c)
    CFG.trailColor = c
    if trailObj then trailObj.Color = ColorSequence.new(c, c) end
end)
AppBox:AddToggle("ForceField", { Text = "ForceField Material",   Default = false }):OnChanged(function(v)
    F.forceField = v; setForceField(v)
end)
AppBox:AddToggle("GhostMode",  { Text = "Ghost Mode",            Default = false }):OnChanged(function(v)
    F.ghostMode = v
    if not v then
        local c = LocalPlayer.Character
        if c then for _, p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.LocalTransparencyModifier = 0 end end end
    end
end)
AppBox:AddToggle("PlayerScale", { Text = "Player Scale",         Default = false }):OnChanged(function(v)
    F.playerScale = v; if v then setScale(CFG.scaleSize) else setScale(1) end
end)
AppBox:AddSlider("ScaleSize",   { Text = "Scale Size",  Default = 2,   Min = 1,  Max = 5,    Rounding = 1 }):OnChanged(function(v)
    CFG.scaleSize = v; if F.playerScale then setScale(v) end
end)
AppBox:AddDivider("Camera")
AppBox:AddSlider("FOV",         { Text = "FOV",         Default = 70,  Min = 40, Max = 120,  Rounding = 0 }):OnChanged(function(v)
    CFG.fov = v; applyFOV()
end)
AppBox:AddSlider("MaxZoom",     { Text = "Max Zoom",    Default = 128, Min = 10, Max = 2000, Rounding = 0 }):OnChanged(function(v)
    CFG.maxZoom = v; applyZoom()
end)
AppBox:AddToggle("Freecam",     { Text = "Freecam",              Default = false }):OnChanged(function(v)
    F.freecam = v; if v then startFreecam() else stopFreecam() end
end)
AppBox:AddSlider("FreecamSpeed",{ Text = "Freecam Speed", Default = 1, Min = 1, Max = 30, Rounding = 0 }):OnChanged(function(v)
    CFG.freecamSpeed = v
end)
AppBox:AddDivider("Nametag")
AppBox:AddInput("NametagText",  { Text = "Nametag Text", Default = "Bigfroot", Placeholder = "Bigfroot" }):OnChanged(function(v)
    CFG.nametagText = v ~= "" and v or "Bigfroot"
    if F.nametagOn and nametagGui then
        local lbl = nametagGui:FindFirstChildOfClass("TextLabel")
        if lbl then lbl.Text = CFG.nametagText end
    end
end)
AppBox:AddToggle("NametagOn",   { Text = "Show Nametag",         Default = false }):OnChanged(function(v)
    F.nametagOn = v; setNametag(v)
end)

-- ─── FARM TAB ─────────────────────────────────────────────────────────────────
local FarmTab = Window:AddTab("Farm", "coins")
local FarmBox = FarmTab:AddLeftGroupbox("Coin Farm")

FarmBox:AddToggle("FarmCoins", { Text = "Farm Coins", Default = false }):OnChanged(function(v)
    F.farmCoins = v
    if not v and farmActive then stopFarming() end
end)
FarmBox:AddSlider("GlideSpeed", { Text = "Glide Speed", Default = 16, Min = 16, Max = 220, Rounding = 0 }):OnChanged(function(v)
    CFG.farmSpeed = v
end)
FarmBox:AddLabel({ Text = "⚠ Speeds above default may get you kicked!", DoesWrap = true, RichText = false, Dim = true })
FarmBox:AddButton({ Text = "Start Farming", Callback = function()
    F.farmCoins = true; notify("Coins", "Coin farm started.", 2, "success")
end })
FarmBox:AddButton({ Text = "Stop Farming", Callback = function()
    F.farmCoins = false
    if farmActive then stopFarming() end
    notify("Coins", "Coin farm stopped.", 2)
end })

-- ─── UTILITY ──────────────────────────────────────────────────────────────────

-- Teleport tab
local TpTab  = Window:AddTab("Teleport", "map-pin")
local TpBox  = TpTab:AddLeftGroupbox("Players")
local TpBox2 = TpTab:AddRightGroupbox("Locations")

TpBox:AddDropdown("TpPlayer", {
    Text        = "Select Player",
    Values      = {},
    Default     = 1,
    SpecialType = "Player",
}):OnChanged(function(v) _G.BF_TpTarget = v end)

TpBox:AddButton({ Text = "TP to Player", Callback = function()
    if _G.BF_TpTarget then tpToPlayer(_G.BF_TpTarget) end
end })
TpBox:AddButton({ Text = "TP to Murderer", Callback = function()
    local m = getMurderer()
    if m then tpToPlayer(m.Name) else notify("TP", "No murderer found.", 3, "error") end
end })
TpBox:AddButton({ Text = "TP to Sheriff", Callback = function()
    local s = getSheriff()
    if s then tpToPlayer(s.Name) else notify("TP", "No sheriff found.", 3, "error") end
end })

TpBox2:AddButton({ Text = "TP to Map Spawn", Callback = function()
    local map = getActiveMap()
    if map and map:FindFirstChild("Spawns") then
        local s = map.Spawns:GetChildren()
        if #s > 0 then tpTo(s[1].CFrame + Vector3.new(0, 3, 0)) end
    else notify("Error", "No map found.", 3, "error") end
end })
TpBox2:AddButton({ Text = "TP to Lobby", Callback = function()
    local lb = workspace:FindFirstChild("RegularLobby")
    if lb then
        local bp = lb:FindFirstChildWhichIsA("BasePart")
        if bp then tpTo(bp.CFrame) end
    else notify("Error", "Lobby not found.", 3, "error") end
end })

TpBox2:AddDivider("Waypoints")
local WP           = {}
local waypointName = ""
local wpDropValues = {}
local wpDrop

TpBox2:AddInput("WpName", { Text = "Waypoint Name", Placeholder = "spot1", Default = "" }):OnChanged(function(v)
    waypointName = v
end)
TpBox2:AddButton({ Text = "Save Current Spot", Callback = function()
    local HRP = hrp()
    if not HRP then return end
    local n = (waypointName ~= "") and waypointName or ("wp" .. tostring(#wpDropValues + 1))
    WP[n] = HRP.CFrame
    wpDropValues[#wpDropValues+1] = n
    if wpDrop then wpDrop:SetValues(wpDropValues) end
    notify("Waypoint", "Saved '" .. n .. "'", 2)
end })
wpDrop = TpBox2:AddDropdown("WpSelect", { Text = "Saved Waypoints", Values = {}, Default = 1 })
TpBox2:AddButton({ Text = "TP to Waypoint", Callback = function()
    local sel = wpDrop and wpDrop:GetValue()
    if sel and WP[sel] then tpTo(WP[sel]) end
end })

-- Troll tab
local TrTab  = Window:AddTab("Troll", "swords")
local TrBox  = TrTab:AddLeftGroupbox("Fling")
local TrBox2 = TrTab:AddRightGroupbox("Misc")

TrBox:AddDropdown("FlingTarget", {
    Text        = "Target Player",
    Values      = {},
    Default     = 1,
    SpecialType = "Player",
}):OnChanged(function(v) trollSelected = v end)

TrBox:AddToggle("FlingT", { Text = "Fling Target",   Default = false }):OnChanged(function(v)
    flingTargets.target = v; if v then flingLoop() end
end)
TrBox:AddToggle("FlingA", { Text = "Fling All",       Default = false }):OnChanged(function(v)
    flingTargets.all = v; if v then flingLoop() end
end)
TrBox:AddToggle("FlingS", { Text = "Fling Sheriff",   Default = false }):OnChanged(function(v)
    flingTargets.sheriff = v; if v then flingLoop() end
end)
TrBox:AddToggle("FlingM", { Text = "Fling Murderer",  Default = false }):OnChanged(function(v)
    flingTargets.murderer = v; if v then flingLoop() end
end)
TrBox:AddButton({ Text = "Stop All Fling", Callback = function()
    stopFling(); notify("Fling", "All fling stopped.", 2)
end })

TrBox2:AddToggle("HeadSit", { Text = "Sit on Target's Head", Default = false }):OnChanged(function(v)
    F.headSit = v
    if v then
        task.spawn(function()
            while F.headSit do
                task.wait()
                local p = trollSelected and Players:FindFirstChild(trollSelected)
                if p then
                    local tc   = p.Character
                    local mc   = LocalPlayer.Character
                    local mhrp = mc and mc:FindFirstChild("HumanoidRootPart")
                    if tc and tc:FindFirstChild("Head") and mhrp then
                        mhrp.CFrame   = tc.Head.CFrame * CFrame.new(0, 1.5, 0)
                        mhrp.Velocity = Vector3.zero
                    end
                end
            end
        end)
    end
end)
TrBox2:AddDivider("Spectate")
TrBox2:AddToggle("SpecTarget", { Text = "Spectate Target",   Default = false }):OnChanged(function(v)
    if v then
        trackConn("specTarget", RunService.RenderStepped:Connect(function()
            local p = trollSelected and Players:FindFirstChild(trollSelected)
            if p and p.Character and p.Character:FindFirstChild("Humanoid") then
                Camera.CameraSubject = p.Character.Humanoid
            end
        end))
    else
        if CONN.specTarget then CONN.specTarget:Disconnect(); CONN.specTarget = nil end
        resetCamera()
    end
end)
TrBox2:AddToggle("SpecMurder", { Text = "Spectate Murderer", Default = false }):OnChanged(function(v)
    if v then
        trackConn("specMurder", RunService.RenderStepped:Connect(function()
            local m = getMurderer()
            if m and m.Character and m.Character:FindFirstChild("Humanoid") then
                Camera.CameraSubject = m.Character.Humanoid
            end
        end))
    else
        if CONN.specMurder then CONN.specMurder:Disconnect(); CONN.specMurder = nil end
        resetCamera()
    end
end)
TrBox2:AddDivider("Chat & Emotes")
TrBox2:AddButton({ Text = "Send Roles in Chat", Callback = sendRolesInChat })
TrBox2:AddDropdown("DanceSel", {
    Text    = "Dance",
    Values  = { "Dance 1", "Dance 2", "Dance 3", "Dance 4" },
    Default = "Dance 1",
}):OnChanged(function(v)
    CFG.danceSel = v
    if F.autoDance then stopDance(); playDance() end
end)
TrBox2:AddButton({ Text = "Play Dance", Callback = playDance })
TrBox2:AddToggle("AutoDance", { Text = "Auto Dance", Default = false }):OnChanged(function(v)
    F.autoDance = v; if not v then stopDance() end
end)

-- Defense tab
local DefTab  = Window:AddTab("Defense", "shield")
local SafeBox = DefTab:AddLeftGroupbox("Safety")
local EvBox   = DefTab:AddRightGroupbox("Evasion")

SafeBox:AddToggle("AntiVoid", { Text = "Anti Void",         Default = false }):OnChanged(function(v) F.antiVoid = v end)
SafeBox:AddToggle("AntiAfk",  { Text = "Anti AFK",          Default = true  }):OnChanged(function(v) F.antiAfk  = v end)
SafeBox:AddToggle("Alarm",    { Text = "Murderer Alarm",    Default = false }):OnChanged(function(v) F.alarm     = v end)
SafeBox:AddSlider("AlarmDist",{ Text = "Alarm Distance", Default = 40, Min = 10, Max = 100, Rounding = 0 }):OnChanged(function(v)
    CFG.alarmDist = v
end)

EvBox:AddToggle("AutoEvade",  { Text = "Auto Evade",        Default = false }):OnChanged(function(v) F.autoEvade = v end)
EvBox:AddSlider("EvadeDist",  { Text = "Evade Distance", Default = 20, Min = 5,  Max = 60,  Rounding = 0 }):OnChanged(function(v)
    CFG.evadeDist = v
end)
EvBox:AddSlider("EvadeSpeed", { Text = "Evade Speed",   Default = 25, Min = 5,  Max = 80,  Rounding = 0 }):OnChanged(function(v)
    CFG.evadeSpeed = v
end)
EvBox:AddToggle("AntiKill",   { Text = "Anti-Kill TP Away", Default = false }):OnChanged(function(v) F.antiKill = v end)
EvBox:AddSlider("AntiKillDist",{ Text = "Anti-Kill Dist", Default = 15, Min = 5, Max = 40, Rounding = 0 }):OnChanged(function(v)
    CFG.antiKillDist = v
end)
EvBox:AddButton({ Text = "Flash Step (dash)", Callback = flashStepManual })

-- Server tab
local SrvTab  = Window:AddTab("Server", "server")
local ConnBox = SrvTab:AddLeftGroupbox("Connection")
local PlrBox  = SrvTab:AddRightGroupbox("Players")

ConnBox:AddButton({ Text = "Rejoin Server", Callback = function()
    notify("Server", "Rejoining...", 2)
    pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end)
end })
ConnBox:AddButton({ Text = "Server Hop", Callback = function()
    notify("Server Hop", "Searching...", 2)
    task.spawn(function()
        local ok, res = pcall(function()
            return game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
        end)
        if not ok then notify("Server Hop", "HTTP failed.", 3, "error"); return end
        local data = HttpService:JSONDecode(res)
        for _, s in ipairs(data.data or {}) do
            if s.playing and s.maxPlayers and s.playing < s.maxPlayers and s.id ~= game.JobId then
                notify("Server Hop", "Joining " .. s.playing .. "/" .. s.maxPlayers, 3, "success")
                pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer) end)
                return
            end
        end
        notify("Server Hop", "No alternate server found.", 3)
    end)
end })
ConnBox:AddButton({ Text = "Copy JobId", Callback = function()
    if setclipboard or set_clipboard then
        (setclipboard or set_clipboard)(game.JobId)
        notify("Server", "JobId copied.", 2, "success")
    else notify("Server", "No clipboard function available.", 3, "error") end
end })

PlrBox:AddDropdown("ServerPlayer", {
    Text        = "Select Player",
    Values      = {},
    Default     = 1,
    SpecialType = "Player",
}):OnChanged(function(v) _G.BF_SrvTarget = v end)
PlrBox:AddButton({ Text = "View Role", Callback = function()
    local name = _G.BF_SrvTarget
    if name then
        local p = Players:FindFirstChild(name)
        if p then notify(name, "Role: " .. roleOf(p), 4) end
    end
end })
PlrBox:AddButton({ Text = "Copy UserId", Callback = function()
    local name = _G.BF_SrvTarget
    if name then
        local p = Players:FindFirstChild(name)
        if p and (setclipboard or set_clipboard) then
            (setclipboard or set_clipboard)(tostring(p.UserId))
            notify("Copied", p.Name .. " = " .. tostring(p.UserId), 3, "success")
        end
    end
end })
PlrBox:AddButton({ Text = "Detect Current Map", Callback = function()
    local _, name = getActiveMap()
    notify("Map Detection", name or "No map loaded yet.", 4)
end })
PlrBox:AddButton({ Text = "Refresh Player Data", Callback = function()
    refreshPD(); notify("Player Data", "Refreshing...", 2)
end })

-- Settings
Window:AddSettingsTab()

-- ─── UNLOAD ───────────────────────────────────────────────────────────────────
Library:OnUnload(function()
    scriptRunning  = false
    F.headSit      = false
    F.silentAim    = false
    restoreSilentAim()
    for _, c in pairs(CONN) do pcall(function() c:Disconnect() end) end
    espClearAll()
    stopFly()
    stopFreecam()
    stopFarming()
    local h = hum()
    if h then h.WalkSpeed = 16; h.JumpPower = 50; h.PlatformStand = false end
    local c = char()
    if c then
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = true; p.LocalTransparencyModifier = 0 end
        end
    end
    pcall(function() workspace.Gravity = origGravity end)
    pcall(function() Camera.FieldOfView = 70 end)
    pcall(function() Camera.CameraType = Enum.CameraType.Custom end)
    pcall(function() LocalPlayer.CameraMaxZoomDistance = 128 end)
    pcall(function() setTrail(false) end)
    pcall(function() setNametag(false) end)
    pcall(function() setFloat(false) end)
    pcall(function() setForceField(false) end)
    pcall(function() setBigHead(false) end)
    stopDance()
    stopFling()
    if getgenv then getgenv().Bigfroot = nil end
end)

if getgenv then
    getgenv().Bigfroot = { F = F, CFG = CFG, CONN = CONN, ESP = ESP, Window = Window, Library = Library }
end

Library:Notify({ Title = "Bigfroot", Description = "Murder Mystery 2 loaded. RightShift to toggle.", Time = 5, Type = "success" })
print("[Bigfroot] MM2 v1.1 loaded.")
