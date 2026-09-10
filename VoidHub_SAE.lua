-- VoidHub // Steal An Egg

local EXPECTED_GAME_ID = 10563114921
local VERSION = "1.2"
local VOIDHUB_UI_BASE_URL = "https://raw.githubusercontent.com/joustingmatch/ObsidianUltra/main/"
local CONFIG_FOLDER = "VoidHub/StealAnEgg"
local CONFIG_PATH = CONFIG_FOLDER .. "/config.json"
local FINDER_STATE_PATH = CONFIG_FOLDER .. "/egg-finder.json"
local PREDICTOR_STATE_PATH = CONFIG_FOLDER .. "/world-spawn-predictor.json"
local VOIDHUB_ICON = "rbxassetid://101833678008843"
local VOIDHUB_DISCORD = "discord.gg/getvoidhub"
local VOIDHUB_CREDIT = "von63rd"

local VOIDHUB_THEME = {
    BackgroundColor = Color3.fromRGB(10, 10, 10),
    MainColor = Color3.fromRGB(20, 20, 20),
    AccentColor = Color3.fromRGB(245, 245, 245),
    OutlineColor = Color3.fromRGB(48, 48, 48),
    FontColor = Color3.fromRGB(240, 240, 240),
    RedColor = Color3.fromRGB(200, 200, 200),
    BlueColor = Color3.fromRGB(220, 220, 220),
    DestructiveColor = Color3.fromRGB(170, 170, 170),
}

local function createVoidHubUi(Library, settings)
    local ui = {Library = Library, Settings = settings or {}, WindowObject = nil, binds = {}}

    local autoIdxCounts = {}
    local function nextAutoIdx(kind)
        autoIdxCounts[kind] = (autoIdxCounts[kind] or 0) + 1
        return "voidhub_" .. kind .. "_" .. autoIdxCounts[kind]
    end

    local function decimalsForStep(step)
        local rendered = tostring(tonumber(step) or 1)
        local decimal = string.find(rendered, ".", 1, true)
        return decimal and math.min(#rendered - decimal, 4) or 0
    end

    local function wrap(raw, callback, existing)
        local control = existing or {}
        control.Raw = raw
        control.Frame = raw
        control.Skip = tonumber(control.Skip) or 0
        function control:Set(value, silent)
            if silent then self.Skip += 1 end
            if self.Raw and self.Raw.SetValue then self.Raw:SetValue(value) end
            return self
        end
        function control:Get()
            return self.Raw and self.Raw.Value
        end
        function control:Dispatch(value)
            if self.Skip > 0 then
                self.Skip -= 1
                return
            end
            if callback then callback(value) end
        end
        return control
    end

    local Card = {}
    Card.__index = Card

    function Card:Toggle(options)
        options = options or {}
        local idx = options.Flag or nextAutoIdx("toggle")
        local control = wrap(nil, options.Callback)
        local raw = self.Raw:AddToggle(idx, {
            Text = options.Name or options.Text or "Toggle",
            Default = options.Default == true,
            Callback = function(value)
                control:Dispatch(value)
            end,
        })
        wrap(raw, options.Callback, control)
        return control
    end

    function Card:Slider(options)
        options = options or {}
        local idx = options.Flag or nextAutoIdx("slider")
        local control = wrap(nil, options.Callback)
        local raw = self.Raw:AddSlider(idx, {
            Text = options.Name or options.Text or "Value",
            Min = options.Min,
            Max = options.Max,
            Default = options.Default,
            Rounding = options.Decimals or decimalsForStep(options.Step or options.Increment),
            Suffix = options.Suffix,
            Callback = function(value)
                control:Dispatch(value)
            end,
        })
        wrap(raw, options.Callback, control)
        return control
    end

    function Card:Dropdown(options)
        options = options or {}
        local idx = options.Flag or nextAutoIdx("dropdown")
        local control = {Raw = nil, Frame = nil, Values = options.Options or {}, Value = options.Default, Skip = 0}

        local function valuesOrFallback(values)
            if type(values) == "table" and #values > 0 then return values end
            return {options.Empty or "No options"}
        end

        local raw = self.Raw:AddDropdown(idx, {
            Text = options.Name or options.Text or "Select",
            Values = valuesOrFallback(control.Values),
            Default = control.Value,
            Multi = options.Multi == true,
            Searchable = options.Searchable == true or #(options.Options or {}) > 12,
            SelectAllButtons = options.Multi == true,
            Callback = function(value)
                control.Value = value
                if control.Skip > 0 then
                    control.Skip -= 1
                elseif options.Callback then
                    options.Callback(value)
                end
            end,
        })
        control.Raw, control.Frame = raw, raw

        function control:Set(value, silent)
            self.Value = value
            if silent then self.Skip += 1 end
            if self.Raw then self.Raw:SetValue(value) end
            return self
        end
        function control:Get()
            return self.Raw and self.Raw.Value or self.Value
        end
        function control:Options(values)
            self.Values = valuesOrFallback(values)
            if self.Raw then self.Raw:SetValues(self.Values) end
            return self
        end

        return control
    end

    function Card:Button(options)
        options = options or {}
        local raw = self.Raw:AddButton({
            Text = options.Name or options.Text or "Action",
            Risky = options.Risky == true,
            Func = options.Callback,
        })
        return {Raw = raw, Frame = raw}
    end

    function Card:Input(options)
        options = options or {}
        local idx = options.Flag or nextAutoIdx("input")
        local control = wrap(nil, options.Callback)
        local raw = self.Raw:AddInput(idx, {
            Text = options.Name or options.Text or "Input",
            Default = options.Default,
            Placeholder = options.Placeholder,
            Callback = function(value)
                control:Dispatch(value)
            end,
        })
        wrap(raw, options.Callback, control)
        return control
    end

    function Card:Label(options)
        options = options or {}
        local text = tostring(options.Desc or options.Text or options.Name or "")
        local doesWrap = options.Wrap == true or options.DoesWrap == true or options.Desc ~= nil
        local raw = self.Raw:AddLabel({Text = text, DoesWrap = doesWrap})
        local control = {Raw = raw, Frame = raw, Value = text}
        function control:Set(nextValue)
            self.Value = tostring(nextValue)
            if self.Raw and self.Raw.SetText then self.Raw:SetText(self.Value) end
            return self
        end
        control.SetText = control.Set
        return control
    end

    function Card:Divider(options)
        options = options or {}
        local raw = self.Raw:AddDivider(options.Text and {Text = options.Text} or nil)
        return {Raw = raw, Frame = raw}
    end

    function Card:Color(options)
        options = options or {}
        local idx = options.Flag or nextAutoIdx("color")
        local default = typeof(options.Default) == "Color3" and options.Default or Color3.new(1, 1, 1)
        local labelRaw = self.Raw:AddLabel(options.Name or options.Text or "Color")
        local raw = labelRaw:AddColorPicker(idx, {
            Default = default,
            Title = options.Name,
            Callback = function(value)
                if options.Callback then options.Callback(value) end
            end,
        })
        local control = {Raw = raw, Frame = raw}
        function control:Get()
            return self.Raw and self.Raw.Value
        end
        function control:Set(value)
            if typeof(value) == "Color3" and self.Raw then self.Raw:SetValueRGB(value) end
            return self
        end
        return control
    end

    function Card:Keybind(options)
        options = options or {}
        local idx = options.Flag or nextAutoIdx("keybind")
        local labelRaw = self.Raw:AddLabel(options.Name or options.Text or "Keybind")
        local raw = labelRaw:AddKeyPicker(idx, {
            Text = options.Name or options.Text or "Keybind",
            Default = options.Default or options.Key,
            Mode = options.Mode or "Toggle",
            Callback = function(state)
                if options.OnPress then options.OnPress(state) end
            end,
            ChangedCallback = function(key, mode)
                if options.Callback then options.Callback(key, mode) end
            end,
        })
        local control = {Raw = raw, Frame = raw}
        function control:Set(value, ...)
            if self.Raw and type(self.Raw.SetValue) == "function" then
                self.Raw:SetValue(value, ...)
            end
            return self
        end
        function control:Get()
            return self.Raw and self.Raw.Value
        end
        return control
    end

    function Card:Set() return self end
    function Card:Expand() return self end

    local Tab = {}
    Tab.__index = Tab

    function Tab:Module(options)
        options = options or {}
        local raw = options.Column == 2
            and self.Raw:AddRightGroupbox(options.Name or "Module", options.Icon)
            or self.Raw:AddLeftGroupbox(options.Name or "Module", options.Icon)
        return setmetatable({
            Raw = raw,
            Frame = raw,
            Switch = nil,
            BindControl = nil,
        }, Card)
    end

    function Tab:SubTab(options)
        options = options or {}
        local name = options.Name or "Tab"
        local raw = self.Raw:AddSubTab({Name = name, Icon = options.Icon})
        return setmetatable({Raw = raw, Name = name}, Tab)
    end

    function Tab:AlignSubTabs(alignment)
        if self.Raw and self.Raw.SetSubTabAlignment then
            pcall(self.Raw.SetSubTabAlignment, self.Raw, alignment or "Left")
        end
        return self
    end

    function Tab:PlayerBanner(options)
        options = options or {}
        if not self.Raw or type(self.Raw.AddPlayerInfo) ~= "function" then
            return nil
        end
        local ok, banner = pcall(self.Raw.AddPlayerInfo, self.Raw, options.Idx or nextAutoIdx("player"), {
            Title = options.Title,
            Description = options.Description,
            ThumbnailType = options.ThumbnailType or "HeadShot",
            Height = options.Height or (Library.IsMobile and 66 or 82),
        })
        return ok and banner or nil
    end

    local Window = {}
    Window.__index = Window

    function Window:Tab(options)
        options = options or {}
        local name = options.Name or options.Title or "Tab"
        local raw = self.Raw:AddTab({
            Name = name,
            Icon = options.Icon or "hexagon",
            Description = options.Description,
        })
        return setmetatable({Raw = raw, Name = name}, Tab)
    end

    function Window:Select(tab)
        if tab and tab.Raw and tab.Raw.Show then
            pcall(tab.Raw.Show, tab.Raw)
        end
    end

    function Window:Footer(options)
        options = options or {}
        local segments = {}
        if options.Version then
            segments[#segments + 1] = tostring(options.Version)
        end
        if options.Credit then
            segments[#segments + 1] = "made by " .. tostring(options.Credit)
        end
        if options.Discord then
            local invite = tostring(options.Discord)
            segments[#segments + 1] = {
                Text = invite,
                Copyable = true,
                CopyText = "https://" .. invite:gsub("^https?://", ""),
            }
        end
        if self.Raw and self.Raw.SetFooter then
            self.Raw:SetFooter(segments)
        end
        return self
    end

    function ui:Window(options)
        options = options or {}

        for key, color in pairs(VOIDHUB_THEME) do
            Library.Scheme[key] = color
        end
        Library.CornerRadius = 12

        local mobile = Library.IsMobile == true
        local camera = workspace.CurrentCamera
        local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
        local raw = Library:CreateWindow({
            Title = options.Title or "VoidHub",
            Icon = options.Icon,
            Font = Enum.Font.GothamMedium,
            CornerRadius = 12,
            ToggleKeybind = self.Settings.Key or Enum.KeyCode.RightAlt,
            Size = options.Size
                or (mobile and UDim2.fromOffset(viewport.X - 64, viewport.Y - 64) or UDim2.fromOffset(940, 620)),
            NotifySide = "Right",
            ShowCustomCursor = not mobile,
            FuzzySearch = true,
            SearchValues = true,
            Minimizable = true,
            MinimizedWidth = 320,
            SidebarCompacted = mobile,
            SidebarCompactWidth = 56,
            MinSidebarWidth = mobile and 120 or 150,
            Animations = {
                ToggleWindow = true,
                TabSwitch = true,
                Groupbox = true,
                Dropdown = true,
                KeyPicker = true,
                SubTabUnderline = true,
            },
            TabTransitionTime = 0.2,
            TabSwipeOffset = 24,
            TabSwipeFrom = "right",
        })
        self.WindowObject = raw
        return setmetatable({Raw = raw}, Window)
    end

    function ui:IsMobile()
        return Library.IsMobile == true
    end

    function ui:Notify(options)
        options = options or {}
        return Library:Notify({
            Type = options.Type,
            Title = options.Title,
            Description = options.Text or options.Description,
            Time = options.Duration,
        })
    end

    function ui:Watermark(options)
        options = options or {}
        if type(Library.AddWatermark) ~= "function" then
            return self
        end
        local players = game:GetService("Players")
        local stats = game:GetService("Stats")
        local ok, watermark = pcall(Library.AddWatermark, Library, {
            {Player = players.LocalPlayer},
            {Icon = "flame", Text = options.Title or "VoidHub", Accent = true},
            {Icon = "cpu", Text = function()
                return (identifyexecutor and identifyexecutor()) or "Unknown"
            end},
            {Icon = "wifi", Text = function()
                local ping = 0
                pcall(function()
                    ping = math.floor(stats.Network.ServerStatsItem["Data Ping"]:GetValue() + 0.5)
                end)
                return string.format("%d ms", ping)
            end},
            {Icon = "clock", Text = function() return os.date("%H:%M") end},
        })
        if ok and type(watermark) == "table" then
            watermark.RefreshRate = 1
            self.WatermarkObject = watermark
        end
        return self
    end

    function ui:Unload()
        if Library and Library.Unload then Library:Unload() end
        self.WindowObject = nil
    end

    return ui
end

if not LPH_OBFUSCATED then
    LPH_ATTRIBUTES = function(...)
        return ...
    end
    VM = function(value)
        return value
    end
    NONE = "NONE"
end

assert(game.GameId == EXPECTED_GAME_ID, "VoidHub // Steal An Egg: wrong game")

local function coreGuiNameDisposition(name)
    local lowered = string.lower(tostring(name or ""))
    for _, token in ipairs({
        "dex",
        "dex explorer",
        "remote spy",
        "hydroxide",
        "dark dex",
        "simple spy",
        "owl hub",
        "rayfield",
        "infinite yield",
    }) do
        if string.find(lowered, token, 1, true) then
            return "rename", token
        end
    end
    return "allow", nil
end

local function installCoreGuiNameGuard(gameObject, environment, classifyName)
    local guardKey = "__VOIDHUB_CORE_GUI_NAME_GUARD"
    local previous = type(environment) == "table" and rawget(environment, guardKey) or nil
    if type(previous) == "table" and previous.Connection then
        pcall(previous.Connection.Disconnect, previous.Connection)
    end

    local serviceOk, coreGui = pcall(gameObject.GetService, gameObject, "CoreGui")
    if not serviceOk or not coreGui then
        return nil
    end

    local renameSequence = 0
    local function sanitize(child)
        local nameOk, name = pcall(function()
            return child.Name
        end)
        if not nameOk or classifyName(name) ~= "rename" then
            return
        end
        renameSequence += 1
        pcall(function()
            child.Name = "UIRuntime_" .. tostring(renameSequence)
        end)
    end

    local connection
    pcall(function()
        connection = coreGui.ChildAdded:Connect(sanitize)
    end)
    local childrenOk, children = pcall(coreGui.GetChildren, coreGui)
    if childrenOk then
        for _, child in ipairs(children) do
            sanitize(child)
        end
    end

    local guard = {Connection = connection, Sanitize = sanitize}
    if type(environment) == "table" then
        rawset(environment, guardKey, guard)
    end
    return guard
end

local CORE_GUI_NAME_GUARD = installCoreGuiNameGuard(
    game,
    (getgenv and getgenv()) or _G,
    coreGuiNameDisposition
)

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local G = (getgenv and getgenv()) or _G

local function pack(...)
    return {n = select("#", ...), ...}
end

local function unpackPack(values, first)
    return table.unpack(values, first or 1, values.n)
end

local function selectExecutorIdentity(...)
    for index = 1, select("#", ...) do
        local probe = select(index, ...)
        if type(probe) == "function" then
            local ok, name, version = pcall(probe)
            if ok then
                if type(name) == "string" and name ~= "" then
                    return type(version) == "string" and version ~= ""
                        and (name .. " " .. version)
                        or name
                end
                if type(version) == "string" and version ~= "" then
                    return version
                end
            end
        end
    end
    return "Unknown Executor"
end

local EXECUTOR_NAME = selectExecutorIdentity(identifyexecutor, getexecutorname, getexecutor)

local function shallowCopy(source)
    local result = {}
    for key, value in pairs(source or {}) do
        result[key] = value
    end
    return result
end

local function deepCopy(source, seen)
    if type(source) ~= "table" then
        return source
    end
    seen = seen or {}
    if seen[source] then
        return seen[source]
    end
    local result = {}
    seen[source] = result
    for key, value in pairs(source) do
        result[deepCopy(key, seen)] = deepCopy(value, seen)
    end
    return result
end

local function deepMerge(target, source)
    if type(source) ~= "table" then
        return target
    end
    for key, value in pairs(source) do
        if type(value) == "table" and type(target[key]) == "table" then
            deepMerge(target[key], value)
        else
            target[key] = deepCopy(value)
        end
    end
    return target
end

local function containsValue(values, expected)
    for _, value in pairs(values or {}) do
        if value == expected then
            return true
        end
    end
    return false
end

local function countTable(values)
    local count = 0
    for _ in pairs(values or {}) do
        count += 1
    end
    return count
end

local function snapshotCacheDecision(hasSnapshot, lastRefreshAt, now, maxAge)
    if hasSnapshot ~= true then
        return "refresh"
    end
    lastRefreshAt = tonumber(lastRefreshAt) or -math.huge
    now = tonumber(now) or 0
    maxAge = math.max(0, tonumber(maxAge) or 0)
    if maxAge <= 0 then
        return "refresh"
    end
    local age = now - lastRefreshAt
    if age >= 0 and age <= maxAge then
        return "cache"
    end
    return "refresh"
end

local function updateStatusRecord(existing, status, detail, at)
    local record = type(existing) == "table" and existing or {}
    record.Status = status
    record.Detail = detail
    record.At = at
    return record
end

local function shouldUpdateUiValue(previous, nextValue)
    return tostring(previous) ~= tostring(nextValue)
end

local function planMarkerReconciliation(existingByUid, candidates, limit)
    existingByUid = type(existingByUid) == "table" and existingByUid or {}
    candidates = type(candidates) == "table" and candidates or {}
    limit = math.max(0, math.floor(tonumber(limit) or 0))
    local plan = {Desired = {}, Keep = {}, Create = {}, Remove = {}}
    for index = 1, math.min(limit, #candidates) do
        local candidate = candidates[index]
        local uid = type(candidate) == "table" and candidate.Uid or nil
        uid = uid ~= nil and tostring(uid) or nil
        if uid and plan.Desired[uid] == nil then
            plan.Desired[uid] = candidate
            if existingByUid[uid] ~= nil then
                plan.Keep[#plan.Keep + 1] = uid
            else
                plan.Create[#plan.Create + 1] = uid
            end
        end
    end
    for uid in pairs(existingByUid) do
        uid = tostring(uid)
        if plan.Desired[uid] == nil then
            plan.Remove[#plan.Remove + 1] = uid
        end
    end
    table.sort(plan.Remove)
    return plan
end

local function safeString(value)
    local ok, result = pcall(tostring, value)
    return ok and result or "<unprintable>"
end

local function clampFinite(value, minimum, maximum, fallback)
    value = tonumber(value)
    if value == nil or value ~= value or value == math.huge or value == -math.huge then
        return fallback
    end
    if value < minimum then
        return minimum
    end
    if value > maximum then
        return maximum
    end
    return value
end

local function customStealSpeed(value)
    value = tonumber(value)
    if value == nil or value ~= value or value == math.huge or value == -math.huge or value <= 0 then
        return 0
    end
    return value
end

local function registeredRagdollForSpeed(speed)
    return customStealSpeed(speed) > 900
end

local function scoreEggCandidate(candidate, mode)
    local rarity = clampFinite(candidate and candidate.RarityNumber, 0, 100, 0)
    local earning = clampFinite(candidate and candidate.EarningRate, 0, 1e18, 0)
    local sellValue = clampFinite(candidate and candidate.SellValue, 0, 1e18, 0)
    local weightKg = clampFinite(candidate and candidate.WeightKg, 0, 1e12, 0)
    local assetScale = clampFinite(candidate and candidate.AssetScale, 0, 200, 0)
    local visualOdds = clampFinite(candidate and candidate.VisualOdds, 0.000001, 1e18, 1e18)
    local areaTier = clampFinite(candidate and candidate.AreaTier, 0, 100, 0)
    local mutationMultiplier = clampFinite(candidate and candidate.MutationMultiplier, 1, 1e9, 1)
    local mutationCount = clampFinite(candidate and candidate.MutationCount, 0, 100, 0)
    local distance = clampFinite(candidate and candidate.Distance, 0, 1e9, 1e9)
    local value = math.max(earning, sellValue) * mutationMultiplier
    local rarityBonus = rarity * 10000
    local oddsBonus = (1 / visualOdds) * 1000

    if mode == "Nearest" then
        return -distance
    elseif mode == "Heaviest Weight" then
        return weightKg * 1e12 + value * 1e3 + rarity
    elseif mode == "Largest Size" then
        return assetScale * 1e15 + weightKg * 1e6 + value
    elseif mode == "Highest Rarity" then
        return rarity * 1e12 + value * 1e4 + mutationCount * 100 + areaTier
    elseif mode == "Mutations" then
        return mutationCount * 1e15 + mutationMultiplier * 1e10 + value * 1e3 + rarity
    elseif mode == "Highest Area" then
        return areaTier * 1e12 + rarity * 1e8 + value
    end

    return value * 1e6 + rarityBonus + mutationCount * 5000 + areaTier * 100 + oddsBonus - distance * 0.01
end

local function chooseEggCandidate(candidates, mode)
    local best
    local bestScore = -math.huge
    for _, candidate in ipairs(candidates or {}) do
        local score = scoreEggCandidate(candidate, mode)
        local uid = tostring(candidate.Uid or "")
        local bestUid = best and tostring(best.Uid or "") or ""
        if score > bestScore or (score == bestScore and uid < bestUid) then
            best = candidate
            bestScore = score
        end
    end
    return best, bestScore
end

local function currentTransportCruiseSpeed(nativeWalkSpeed)
    return math.clamp((tonumber(nativeWalkSpeed) or 16) * 16, 96, 900)
end

local function currentCarryTransportCruiseSpeed(nativeWalkSpeed, carryMultiplier)
    local nativeSpeed = tonumber(nativeWalkSpeed) or 16
    local multiplier = tonumber(carryMultiplier)
    if multiplier == nil or multiplier ~= multiplier or multiplier == math.huge or multiplier == -math.huge then
        multiplier = 1
    end
    multiplier = math.clamp(multiplier, 0.1, 2)
    return math.clamp(nativeSpeed * 16 * multiplier, 96, 900)
end

local function carryStateDisposition(carryState, expectedUid)
    if type(carryState) ~= "table" then
        return "wait"
    end
    if carryState.IsCarrying == true then
        return tostring(carryState.Uid or "") == tostring(expectedUid or "") and "ready" or "fail"
    end
    return "fail"
end

local function minimumEggScaleForTier(tier)
    local thresholds = {
        ["Big+ (1.45x)"] = 1.45,
        ["Huge+ (1.9x)"] = 1.9,
        ["Giant+ (2.85x)"] = 2.85,
        ["Colossal+ (5.8x)"] = 5.8,
        ["Titanic+ (9.5x)"] = 9.5,
    }
    return thresholds[tostring(tier or "")] or 0
end

local function eggCandidateMatchesPolicy(candidate, policy)
    if type(candidate) ~= "table" then
        return false
    end
    policy = type(policy) == "table" and policy or {}
    local minimumWeight = math.max(0, tonumber(policy.MinimumWeightKg) or 0)
    if (tonumber(candidate.WeightKg) or 0) < minimumWeight then
        return false
    end
    if (tonumber(candidate.AssetScale) or 0) < minimumEggScaleForTier(policy.SizeTier) then
        return false
    end

    local mutationCount = tonumber(candidate.MutationCount) or 0
    local mutationRequirement = tostring(policy.MutationRequirement or "Any")
    if mutationRequirement == "Mutated Only" and mutationCount <= 0 then
        return false
    elseif mutationRequirement == "No Mutation" and mutationCount > 0 then
        return false
    end

    local selected = policy.SelectedCategories
    if type(selected) == "table" and next(selected) ~= nil then
        local category = tostring(candidate.Category or "")
        local found = selected[category] == true
        if not found then
            for _, value in pairs(selected) do
                if tostring(value) == category then
                    found = true
                    break
                end
            end
        end
        if not found then
            return false
        end
    end
    return true
end

local function buildPlacementOffset(index, columns, spacing)
    index = math.max(1, math.floor(tonumber(index) or 1))
    columns = math.max(1, math.floor(tonumber(columns) or 1))
    spacing = tonumber(spacing) or 6
    local zeroIndex = index - 1
    local column = zeroIndex % columns
    local row = math.floor(zeroIndex / columns)
    local x = (column - ((columns - 1) / 2)) * spacing
    local z = row * spacing
    return x, z
end

local function choosePlacementOffset(placedRecords, columns, spacing)
    columns = math.max(1, math.floor(tonumber(columns) or 1))
    spacing = math.max(0.1, tonumber(spacing) or 6)
    local occupied = {}
    for _, record in ipairs(placedRecords or {}) do
        local placement = type(record) == "table" and record.Placement or nil
        local localFrame = type(placement) == "table" and placement.LocalCFrame or nil
        local position
        if typeof(localFrame) == "CFrame" then
            position = localFrame.Position
        elseif type(localFrame) == "table"
            and tonumber(localFrame.X) and tonumber(localFrame.Z) then
            position = localFrame
        end
        if position then
            occupied[#occupied + 1] = {X = tonumber(position.X), Z = tonumber(position.Z)}
        end
    end
    local clearance = math.max(1, spacing * 0.45)
    local limit = math.max(columns * 4, #occupied + columns * 2 + 1)
    for index = 1, limit do
        local x, z = buildPlacementOffset(index, columns, spacing)
        local blocked = false
        for _, position in ipairs(occupied) do
            local dx = x - position.X
            local dz = z - position.Z
            if math.sqrt(dx * dx + dz * dz) < clearance then
                blocked = true
                break
            end
        end
        if not blocked then
            return x, z, index
        end
    end
    local fallbackIndex = #occupied + 1
    local x, z = buildPlacementOffset(fallbackIndex, columns, spacing)
    return x, z, fallbackIndex
end

local function chooseSellUids(items, policy)
    policy = policy or {}
    local maxRarity = tonumber(policy.MaxRarity) or 1
    local keepCount = math.max(0, math.floor(tonumber(policy.KeepCount) or 0))
    local protectMutations = policy.ProtectMutations ~= false
    local eligible = {}
    local total = #(items or {})
    local sellBudget = math.max(0, total - keepCount)

    for _, item in ipairs(items or {}) do
        local mutationCount = tonumber(item.MutationCount) or 0
        if item.Uid
            and item.IsFavorite ~= true
            and item.IsEquipped ~= true
            and item.InFuse ~= true
            and (tonumber(item.RarityNumber) or 0) <= maxRarity
            and (not protectMutations or mutationCount <= 0)
        then
            eligible[#eligible + 1] = item
        end
    end

    table.sort(eligible, function(left, right)
        local leftValue = tonumber(left.Value) or 0
        local rightValue = tonumber(right.Value) or 0
        if leftValue == rightValue then
            return tostring(left.Uid) < tostring(right.Uid)
        end
        return leftValue < rightValue
    end)

    local result = {}
    for index = 1, math.min(sellBudget, #eligible) do
        result[#result + 1] = eligible[index].Uid
    end
    return result
end

local function inventoryContainsUid(items, uid)
    for _, item in ipairs(items or {}) do
        if tostring(item.Uid or item.uid or "") == tostring(uid) then
            return true
        end
    end
    return false
end

local function chooseEggSellUids(eggs, mode, selectedTypes)
    local sellAll = mode == "All Eggs"
    local selected = {}
    for key, value in pairs(selectedTypes or {}) do
        if type(key) == "number" then
            selected[tostring(value)] = true
        elseif value == true then
            selected[tostring(key)] = true
        end
    end
    local result = {}
    for _, egg in ipairs(eggs or {}) do
        local uid = egg.Uid
        local category = egg.AssetCategory or egg.Category
        if uid
            and category
            and egg.Placement == nil
            and (sellAll or selected[tostring(category)] == true)
        then
            result[#result + 1] = tostring(uid)
        end
    end
    table.sort(result)
    return result
end

local function buildSellAssetPayload(uid)
    return {uid}
end

local function chooseFusePlan(items, policy, priceResolver)
    policy = type(policy) == "table" and policy or {}
    local strategy = tostring(policy.Strategy or "Lowest Value")
    local categoryMode = tostring(policy.CategoryMode or "All Categories")
    local selectedCategories = {}
    for key, value in pairs(type(policy.Categories) == "table" and policy.Categories or {}) do
        local category = type(key) == "number" and value or key
        local enabled = type(key) == "number" or value == true
        if enabled and category ~= nil then
            selectedCategories[tostring(category)] = true
        end
    end
    local minimumRarity = math.max(0, tonumber(policy.MinimumRarity) or 0)
    local maximumRarity = math.max(minimumRarity, tonumber(policy.MaximumRarity) or math.huge)
    local maximumWeight = math.max(0, tonumber(policy.MaximumWeightKg) or 0)
    local maximumScale = math.max(0, tonumber(policy.MaximumScale) or 0)
    local mutationPolicy = tostring(policy.MutationPolicy or "Protect")
    local keepPerCategory = math.max(0, math.floor(tonumber(policy.KeepPerCategory) or 0))
    local maximumPrice = math.max(0, tonumber(policy.MaximumPrice) or 0)

    local groups = {}
    for _, item in ipairs(items or {}) do
        local mutationCount = tonumber(item.MutationCount) or 0
        local category = item.Category and tostring(item.Category) or nil
        local rarity = tonumber(item.RarityNumber) or 0
        local weight = tonumber(item.WeightKg) or 0
        local scale = tonumber(item.Scale) or 0
        local categoryAllowed = category ~= nil
            and (categoryMode ~= "Selected Only" or selectedCategories[category] == true)
            and (categoryMode ~= "Exclude Selected" or selectedCategories[category] ~= true)
        local mutationAllowed = mutationPolicy == "Allow"
            or (mutationPolicy == "Mutated Only" and mutationCount > 0)
            or (mutationPolicy ~= "Mutated Only" and mutationCount <= 0)
        if item.Uid
            and categoryAllowed
            and item.CannotFuse ~= true
            and item.InFuse ~= true
            and (policy.AllowFavorites == true or item.IsFavorite ~= true)
            and (policy.AllowEquipped == true or item.IsEquipped ~= true)
            and rarity >= minimumRarity
            and rarity <= maximumRarity
            and (maximumWeight <= 0 or weight <= maximumWeight)
            and (maximumScale <= 0 or scale <= maximumScale)
            and mutationAllowed
        then
            groups[category] = groups[category] or {}
            groups[category][#groups[category] + 1] = item
        end
    end

    local best
    for category, group in pairs(groups) do
        if #group >= 3 + keepPerCategory then
            table.sort(group, function(left, right)
                local leftScore
                local rightScore
                if strategy == "Smallest Size" or strategy == "Largest Size" then
                    leftScore = tonumber(left.Scale) or 0
                    rightScore = tonumber(right.Scale) or 0
                else
                    leftScore = tonumber(left.Value) or 0
                    rightScore = tonumber(right.Value) or 0
                end
                if leftScore == rightScore then
                    return tostring(left.Uid) < tostring(right.Uid)
                end
                if strategy == "Largest Size" then
                    return leftScore > rightScore
                end
                return leftScore < rightScore
            end)
            local trio = {group[1], group[2], group[3]}
            local totalValue = (tonumber(group[1].Value) or 0)
                + (tonumber(group[2].Value) or 0)
                + (tonumber(group[3].Value) or 0)
            local averageScale = ((tonumber(group[1].Scale) or 0)
                + (tonumber(group[2].Scale) or 0)
                + (tonumber(group[3].Scale) or 0)) / 3
            local averageWeight = ((tonumber(group[1].WeightKg) or 0)
                + (tonumber(group[2].WeightKg) or 0)
                + (tonumber(group[3].WeightKg) or 0)) / 3
            local price
            if type(priceResolver) == "function" then
                local ok, resolved = pcall(priceResolver, trio)
                if ok and tonumber(resolved) then
                    price = math.max(0, tonumber(resolved))
                end
            end
            local candidate = {
                    Category = category,
                    Value = totalValue,
                    Price = price or 0,
                    AverageScale = averageScale,
                    AverageWeightKg = averageWeight,
                    Uids = {group[1].Uid, group[2].Uid, group[3].Uid},
                    Items = trio,
                }
            local candidateScore = strategy == "Lowest Value" and totalValue or averageScale
            local bestScore = best and (strategy == "Lowest Value" and best.Value or best.AverageScale) or nil
            local candidateWins = best == nil
                or (strategy == "Largest Size" and candidateScore > bestScore)
                or (strategy ~= "Largest Size" and candidateScore < bestScore)
                or (candidateScore == bestScore and category < best.Category)
            if (maximumPrice <= 0 or (price ~= nil and price <= maximumPrice)) and candidateWins then
                best = candidate
            end
        end
    end
    return best
end

local function nextBackoff(failures, baseDelay, maximumDelay)
    failures = math.max(0, math.floor(tonumber(failures) or 0))
    baseDelay = clampFinite(baseDelay, 0.01, 3600, 0.5)
    maximumDelay = clampFinite(maximumDelay, baseDelay, 3600, 30)
    return math.min(maximumDelay, baseDelay * (2 ^ failures))
end

local function classifyRemoteResponse(transportOk, serverOk, serverReason)
    if transportOk ~= true then
        return false, tostring(serverOk or "transport failed")
    end
    if serverOk == false then
        return false, tostring(serverReason or "server rejected request")
    end
    return true, nil
end

local function remoteClassMatches(actualClass, expectedClass)
    return type(actualClass) == "string"
        and type(expectedClass) == "string"
        and actualClass == expectedClass
        and (actualClass == "RemoteEvent" or actualClass == "RemoteFunction")
end

local function movementTransportDecision(mode, authenticatedSenderReady)
    if mode ~= "AuthenticatedOnly" then
        return false, "Unsafe character transport disabled"
    end
    if authenticatedSenderReady ~= true then
        return false, "Authenticated character transport not yet validated"
    end
    return true, nil
end

local function locomotionFallbackDecision(enabled, characterReady)
    if enabled ~= true then
        return false, "Locomotion fallback is disabled"
    end
    if characterReady ~= true then
        return false, "Character unavailable for locomotion transport"
    end
    return true, nil
end

local function floorGlideSpeed(nativeWalkSpeed, multiplier)
    local walkSpeed = clampFinite(nativeWalkSpeed, 4, 400, 16)
    local factor = clampFinite(multiplier, 0.5, 1.25, 1)
    return walkSpeed * factor
end

local function floorGlideStep(currentPosition, targetPosition, speed, deltaTime)
    local deltaX = targetPosition.X - currentPosition.X
    local deltaZ = targetPosition.Z - currentPosition.Z
    local distance = math.sqrt(deltaX * deltaX + deltaZ * deltaZ)
    if distance <= 0.001 then
        return nil, nil
    end
    local maxStep = math.max(0, speed) * math.max(0, deltaTime)
    if maxStep >= distance then
        return Vector3.new(deltaX, 0, deltaZ), distance
    end
    return Vector3.new(deltaX / distance * maxStep, 0, deltaZ / distance * maxStep), distance
end

local function integrityTransportDecision(
    stateBound,
    capabilityValid,
    threatLevel,
    kickQueued,
    heartbeatSequence,
    invalidHeartbeatCount,
    validationLocked,
    currentChallenge,
    tamperScore,
    coreGuiScore,
    speedEvidence,
    flightEvidence,
    teleportEvidence
)
    LPH_ATTRIBUTES(VM(NONE))
    if stateBound ~= true then
        return false, "Live character integrity state unavailable"
    end
    if capabilityValid ~= true then
        return false, "Integrity capability attestation failed"
    end
    if kickQueued == true then
        return false, "Integrity controller has queued a kick"
    end
    if (tonumber(heartbeatSequence) or 0) < 0 then
        return false, "Integrity heartbeat sequence is invalid"
    end
    if (tonumber(invalidHeartbeatCount) or 0) > 0 then
        return false, "Integrity heartbeat validation failed"
    end
    if (tonumber(tamperScore) or 0) > 0 then
        return false, "Integrity tamper score is not clean"
    end
    if (tonumber(coreGuiScore) or 0) > 0 then
        return false, "GUI integrity score is not clean"
    end
    if (tonumber(speedEvidence) or 0) > 0
        or (tonumber(flightEvidence) or 0) > 0
        or (tonumber(teleportEvidence) or 0) > 0 then
        return false, "Integrity movement evidence is not clean"
    end
    if threatLevel ~= "Trusted" and threatLevel ~= "Observing" then
        return false, "Integrity controller is not trusted (" .. tostring(threatLevel) .. ")"
    end
    if currentChallenge ~= nil then
        return false, "Integrity challenge is still pending"
    end
    if validationLocked == true then
        return false, "Integrity movement validation is locked"
    end
    return true, nil
end

local function integrityWaitDisposition(ready, reason)
    if ready == true then
        return "ready"
    end
    if reason == "Integrity movement validation is locked"
        or reason == "Integrity challenge is still pending"
        or reason == "Live character integrity state unavailable"
        or reason == "Character integrity is still settling"
        or reason == "Registered transport discovery is already running"
        or reason == "Character movement is rebinding"
        or reason == "Integrity changed during registered movement"
        or reason == "Integrity controller is not trusted (Correcting)" then
        return "retry"
    end
    return "fail"
end

local function returnWaitDisposition(atHome, ready, reason)
    if atHome == true then
        return "home"
    end
    return integrityWaitDisposition(ready, reason)
end

local function registeredImpulseProtocolKind(name, source, outerConstants, innerConstants)
    LPH_ATTRIBUTES(VM(NONE))
    if name ~= "BeginImpulse" or type(source) ~= "string" then
        return nil
    end
    source = string.gsub(source, "^[=@]", "")
    if source == "ReplicatedFirst.IntroLoader.F.RagdollMovement" then
        return "legacy"
    end
    if source ~= "ReplicatedFirst.UGI.ContentCatalog.Impact" then
        return nil
    end

    local function contains(constants, expected)
        LPH_ATTRIBUTES(VM(NONE))
        for _, value in pairs(constants or {}) do
            if value == expected then
                return true
            end
        end
        return false
    end

    if not contains(outerConstants, "Impulse")
        or not contains(innerConstants, "Invalid registered-movement mutation scope")
        or not contains(innerConstants, "ImpulseContext")
        or not contains(innerConstants, "MaxHorizontalDistance")
        or not contains(innerConstants, "MaxUpwardDistance") then
        return nil
    end
    return "ugi"
end

local function registeredRelocateProtocolKind(source, constants, upvalues)
    source = type(source) == "string" and string.gsub(source, "^[=@]", "") or ""
    if source ~= "ReplicatedFirst.UGI.ContentCatalog"
        or type(constants) ~= "table"
        or type(upvalues) ~= "table"
        or type(upvalues[6]) ~= "function"
        or type(upvalues[7]) ~= "table" then
        return false
    end
    local required = {
        ["SetWalkSpeed action requires one value"] = false,
        ["BeginImpulse action requires duration and three impulse components"] = false,
        ["Relocate action requires twelve CFrame components"] = false,
    }
    for _, value in pairs(constants) do
        if required[value] ~= nil then
            required[value] = true
        end
    end
    for _, present in pairs(required) do
        if not present then
            return false
        end
    end
    return true
end

local function consumeExperimentalRelocate(pendingComponents, originalPop, capability)
    if type(pendingComponents) == "table" and #pendingComponents == 12 then
        return "Relocate", pendingComponents, nil
    end
    local action, arguments = originalPop(capability)
    return action, arguments, nil
end

local function setForestGuardAttackPaused(component, enabled, restoreValue)
    if type(component) ~= "table"
        or rawget(component, "_areaId") ~= "Forest"
        or type(rawget(component, "_attackHandler")) ~= "function" then
        return false, nil
    end
    if enabled == true then
        local previous = rawget(component, "_attackResumeTime")
        rawset(component, "_attackResumeTime", math.huge)
        return true, previous
    end
    if type(restoreValue) ~= "number" then
        return false, nil
    end
    rawset(component, "_attackResumeTime", restoreValue)
    return true, restoreValue
end

local function godmodeRecoveryDecision(enabled, activeUid, areaId, isCarrying, ragdollHit, guardRetrieving, atHome, attempts)
    if enabled ~= true or type(activeUid) ~= "string" or activeUid == "" then
        return "ignore"
    end
    if isCarrying == true then
        return "track"
    end
    if areaId == "Forest" or atHome == true or (tonumber(attempts) or 0) >= 12 then
        return "clear"
    end
    return "regrab"
end

local function filterGodmodeRegisteredAction(action, arguments, suppressRagdoll)
    if suppressRagdoll == true and action == "BeginRagdoll" then
        return nil, nil, true
    end
    return action, arguments, false
end

local function selectValidatedCapability(candidates, guard)
    if type(guard) ~= "function" then
        return nil
    end
    for _, candidate in ipairs(candidates or {}) do
        if type(candidate) == "table" then
            local ok, result = pcall(guard, candidate)
            if ok and result ~= false then
                return candidate
            end
        end
    end
    return nil
end

local function playerControlIsolationAvailable(controls)
    return type(controls) == "table"
        and type(controls.Disable) == "function"
        and type(controls.Enable) == "function"
end

local function isControlModuleCandidate(candidate, humanoid)
    if type(candidate) ~= "table" or humanoid == nil or rawget(candidate, "humanoid") ~= humanoid then
        return false
    end
    local metatable = getmetatable(candidate)
    return type(metatable) == "table"
        and type(rawget(metatable, "Disable")) == "function"
        and type(rawget(metatable, "Enable")) == "function"
        and type(rawget(candidate, "controlsEnabled")) == "boolean"
end

local function characterRecoveryDecision(hasCharacter, health, anchored)
    if hasCharacter ~= true then
        return "wait"
    end
    health = tonumber(health)
    if health ~= nil and health <= 0 then
        return "reset"
    end
    if anchored == true then
        return "wait"
    end
    return "ready"
end

local function registeredImpulsePulseInterval(value)
    return math.max(0.1, math.min(0.25, tonumber(value) or 0.12))
end

local function classifyTreadmillEquip(transportOk, serverOk, serverReason)
    if transportOk ~= true then
        return false, tostring(serverOk or "Treadmill request failed")
    end
    if serverOk == true or tostring(serverReason) == "Already using treadmill" then
        return true, nil
    end
    return false, tostring(serverReason or "Treadmill request rejected")
end

local function classifyTreadmillUnequip(transportOk, serverOk, serverReason)
    if transportOk ~= true then
        return false, tostring(serverOk or "Treadmill release request failed")
    end
    if serverOk ~= false then
        return true, nil
    end
    local reason = tostring(serverReason or "Treadmill release rejected")
    local lowered = string.lower(reason)
    if string.find(lowered, "not using treadmill", 1, true)
        or string.find(lowered, "not on treadmill", 1, true)
        or string.find(lowered, "already unequipped", 1, true)
        or string.find(lowered, "not equipped", 1, true) then
        return true, nil
    end
    return false, reason
end

local function treadmillResumeDecision(transportOk, serverOk, serverReason)
    local accepted, reason = classifyTreadmillEquip(transportOk, serverOk, serverReason)
    if accepted then
        return "active", nil
    end
    if transportOk ~= true then
        return "failure", reason
    end
    local lowered = string.lower(tostring(reason or ""))
    if string.find(lowered, "treadmill", 1, true)
        and (string.find(lowered, "not at", 1, true) or string.find(lowered, "not on", 1, true))
    then
        return "approach", reason
    end
    return "failure", reason
end

local function treadmillReleaseDecision(treadmillActive, rootAnchored, distanceToStand)
    if treadmillActive == true then
        return "request"
    end
    distanceToStand = tonumber(distanceToStand)
    if rootAnchored == true and distanceToStand and distanceToStand <= 10 then
        return "recover"
    end
    return "skip"
end

local function movementTimeoutBudget(distance, cruiseSpeed, requestedTimeout, maximumTimeout)
    distance = math.max(0, tonumber(distance) or 0)
    cruiseSpeed = math.max(1, tonumber(cruiseSpeed) or 1)
    requestedTimeout = math.max(0.1, tonumber(requestedTimeout) or 1)
    maximumTimeout = math.max(requestedTimeout, tonumber(maximumTimeout) or 30)
    local distanceBudget = distance / cruiseSpeed * 1.75 + 0.75
    return math.min(maximumTimeout, math.max(requestedTimeout, distanceBudget))
end

local function movementApproachSpeed(distance, responseGain, cruiseSpeed)
    distance = math.max(0, tonumber(distance) or 0)
    responseGain = math.max(0.1, tonumber(responseGain) or 1)
    cruiseSpeed = math.max(1, tonumber(cruiseSpeed) or 1)
    local requestedSpeed = math.clamp(distance * responseGain, 12, cruiseSpeed)
    local brakingCap = math.max(24, distance * 8)
    return math.min(requestedSpeed, brakingCap)
end

local function groundAdhesionVerticalSpeed(clearance, currentVerticalSpeed)
    currentVerticalSpeed = tonumber(currentVerticalSpeed) or 0
    clearance = tonumber(clearance)
    if clearance == nil or clearance ~= clearance or clearance == math.huge or clearance == -math.huge then
        return math.min(currentVerticalSpeed, 0)
    end

    local target = 0
    if clearance > 4 then
        target = -math.clamp(10 + (clearance - 4) * 16, 10, 90)
    end
    if currentVerticalSpeed > 10 then
        target = math.min(target, -35)
    end
    return target
end

local function movementArrivalAccepted(finalDistance, arrivalRadius)
    finalDistance = tonumber(finalDistance)
    arrivalRadius = math.max(0, tonumber(arrivalRadius) or 0)
    return finalDistance ~= nil
        and finalDistance == finalDistance
        and finalDistance >= 0
        and finalDistance <= arrivalRadius + 3
end

local function refreshMovementDeadline(bestDistance, currentDistance, now, softDeadline, hardDeadline, progressThreshold, extensionSeconds)
    bestDistance = tonumber(bestDistance) or math.huge
    currentDistance = tonumber(currentDistance) or math.huge
    now = tonumber(now) or 0
    softDeadline = tonumber(softDeadline) or now
    hardDeadline = math.max(softDeadline, tonumber(hardDeadline) or softDeadline)
    progressThreshold = math.max(0, tonumber(progressThreshold) or 0)
    extensionSeconds = math.max(0, tonumber(extensionSeconds) or 0)
    if currentDistance <= bestDistance - progressThreshold then
        return currentDistance, math.min(hardDeadline, math.max(softDeadline, now + extensionSeconds)), true
    end
    return bestDistance, softDeadline, false
end

local function buildEggCarryPayload(uid, firstAreaSlotKey)
    return {
        Uid = uid,
        FirstAreaSlotKey = firstAreaSlotKey,
    }
end

local function buildEggPlacePayload(uid, localCFrame)
    return {
        Uid = uid,
        LocalCFrame = localCFrame,
    }
end

local function chooseTargetAreas(selectedAreas, knownAreas)
    local known = {}
    for _, area in ipairs(knownAreas or {}) do
        known[tostring(area)] = true
    end
    local selected = {}
    for key, value in pairs(selectedAreas or {}) do
        local area = type(key) == "number" and value or (value == true and key or nil)
        if area ~= nil then
            area = tostring(area)
            if known[area] then
                selected[area] = true
            end
        end
    end
    local result = {}
    for area in pairs(selected) do
        result[#result + 1] = area
    end
    table.sort(result)
    return result
end

local function buildTargetAreaSet(selectedAreas)
    local areaSet = {}
    for key, value in pairs(selectedAreas or {}) do
        local area = type(key) == "number" and value or (value == true and key or nil)
        if area ~= nil then
            areaSet[tostring(area)] = true
        end
    end
    return areaSet
end

local function chooseUnplacedEgg(eggs, placedSet)
    for _, egg in ipairs(eggs or {}) do
        local uid = egg and egg.Uid
        if uid and egg.Placement == nil and not (placedSet or {})[tostring(uid)] then
            return egg
        end
    end
    return nil
end

local function schedulerFeatureEnabled(featureEnabled)
    return featureEnabled == true
end

local function setFeatureSelection(features, featureKeys, enabledKeys)
    features = features or {}
    local enabled = {}
    for key, value in pairs(enabledKeys or {}) do
        if type(key) == "number" then
            enabled[tostring(value)] = true
        elseif value == true then
            enabled[tostring(key)] = true
        end
    end
    for _, key in ipairs(featureKeys or {}) do
        features[key] = enabled[key] == true
    end
    return features
end

local function syncControlBindings(bindings)
    local synchronized = 0
    for _, binding in pairs(bindings or {}) do
        local control = type(binding) == "table" and binding.Control or nil
        local read = type(binding) == "table" and binding.Read or nil
        local apply = type(binding) == "table" and binding.Apply or nil
        if control and type(control.Set) == "function" and type(read) == "function" then
            local readOk, value = pcall(read)
            if readOk then
                local setOk
                if type(apply) == "function" then
                    setOk = pcall(apply, control, value)
                else
                    setOk = pcall(control.Set, control, value, true)
                end
                if setOk then
                    synchronized += 1
                end
            end
        end
    end
    return synchronized
end

local function classifySchedulerOutcome(actionOk, callbackOk, callbackMessage)
    if actionOk ~= true then
        return "failure", tostring(callbackOk or "Action failed")
    end
    if callbackOk == true then
        return "success", tostring(callbackMessage or "Completed")
    end

    local reason = tostring(callbackMessage or callbackOk or "No work available")
    local expectedIdleReasons = {
        "No selected area is currently accessible",
        "No eligible live egg slots",
        "No target areas are selected",
        "No eligible live egg slots in the selected areas",
        "Egg inventory is empty",
        "No unplaced carried egg is available",
        "No placed egg is ready",
        "Sell policy found no eligible pets",
        "No egg types are selected",
        "No sellable eggs match the selected types",
        "No eligible same-category fusion trio",
        "No fusion trio matches the current policy",
        "No next treadmill configuration",
        "No next base upgrade configuration",
        "Not enough money for next base upgrade",
        "No offline income available",
        "No index reward available",
        "No index rewards available",
        "Group reward already claimed",
        "No free gift was ready",
        "No alternate public server found",
        "Hungry Monster event is not active",
        "Monster chest is not ready",
        "No parasite egg is currently available from Snow onward",
    }
    for _, idleReason in ipairs(expectedIdleReasons) do
        if reason == idleReason then
            return "idle", reason
        end
    end
    return "failure", reason
end

local function remoteCallDisposition(hasInFlightCall, completed, now, deadline)
    if hasInFlightCall == true then
        return "busy"
    end
    if completed == true then
        return "complete"
    end
    if (tonumber(now) or 0) >= (tonumber(deadline) or 0) then
        return "timeout"
    end
    return "wait"
end

local function resolveRecordUid(record, key)
    if type(record) ~= "table" then
        return nil
    end
    return record.Uid or record.uid or record._uid or (type(key) == "string" and key or nil)
end

local function collectPlacedEggRecords(source)
    local records = {}
    for key, record in pairs(source or {}) do
        if type(record) == "table" and record.Placement ~= nil then
            local uid = resolveRecordUid(record, key)
            if uid then
                local copy = {}
                for field, value in pairs(record) do
                    copy[field] = value
                end
                copy.Uid = uid
                records[#records + 1] = copy
            end
        end
    end
    return records
end

local function baseUpgradeDecision(balance, nextConfig)
    if type(nextConfig) ~= "table" then
        return false, "No next base upgrade configuration"
    end
    local cost = tonumber(nextConfig.Cost or nextConfig.Price or nextConfig.MoneyCost)
    if not cost then
        return false, "Base upgrade cost unavailable"
    end
    if (tonumber(balance) or 0) < cost then
        return false, "Not enough money for next base upgrade", cost
    end
    return true, nil, cost
end

local function fusionRevealDelay(passDurations, safetySeconds)
    local total = math.max(0, tonumber(safetySeconds) or 0)
    for _, duration in ipairs(passDurations or {}) do
        total += math.max(0, tonumber(duration) or 0)
    end
    return total
end

local function groupRewardClaimDecision(save)
    if type(save) == "table" and save.ClaimedGroupReward == true then
        return false, "Group reward already claimed"
    end
    return true, nil
end

local function worldSpawnForecast(dropTable, rollCount, slotCount)
    local entries = {}
    local totalWeight = 0
    for _, entry in pairs(type(dropTable) == "table" and dropTable or {}) do
        local category = type(entry) == "table" and entry[1] or nil
        local weight = type(entry) == "table" and tonumber(entry[2]) or nil
        if type(category) == "string"
            and category ~= ""
            and weight ~= nil
            and weight > 0
            and weight == weight
            and weight ~= math.huge then
            entries[#entries + 1] = {Category = category, Weight = weight}
            totalWeight += weight
        end
    end
    if totalWeight <= 0 then
        return {}
    end

    table.sort(entries, function(left, right)
        if left.Weight == right.Weight then
            return left.Category < right.Category
        end
        return left.Weight < right.Weight
    end)
    local rolls = math.max(1, tonumber(rollCount) or 1)
    local slots = math.max(1, math.floor(tonumber(slotCount) or 5))
    local cumulativeWeight = 0
    for _, entry in ipairs(entries) do
        local before = cumulativeWeight / totalWeight
        cumulativeWeight += entry.Weight
        local after = cumulativeWeight / totalWeight
        local afterChance = 1 - ((1 - after) ^ rolls)
        local beforeChance = 1 - ((1 - before) ^ rolls)
        entry.PerSlotChance = math.clamp(afterChance - beforeChance, 0, 1)
        entry.AnySlotChance = 1 - ((1 - entry.PerSlotChance) ^ slots)
    end
    table.sort(entries, function(left, right)
        if left.PerSlotChance == right.PerSlotChance then
            return left.Category < right.Category
        end
        return left.PerSlotChance > right.PerSlotChance
    end)
    return entries
end

local function migrateAutomationConfig(config, targetSchemaVersion)
    if type(config) ~= "table" then
        return config, false
    end
    local target = math.max(1, math.floor(tonumber(targetSchemaVersion) or 1))
    local previous = math.max(0, math.floor(tonumber(config.SchemaVersion) or 0))
    local removedDirectTransport = false
    if type(config.Egg) == "table" and config.Egg.TransportMethod ~= nil then
        config.Egg.TransportMethod = nil
        removedDirectTransport = true
    end
    if type(config.Movement) == "table" then
        if config.Movement.InstantReplicationSeconds ~= nil then
            config.Movement.InstantReplicationSeconds = nil
            removedDirectTransport = true
        end
        if config.Movement.InstantReturnReplicationSeconds ~= nil then
            config.Movement.InstantReturnReplicationSeconds = nil
            removedDirectTransport = true
        end
    end
    if previous >= target then
        return config, removedDirectTransport
    end

    if previous == 0 and config.MasterEnabled ~= true and type(config.Features) == "table" then
        for _, enabled in pairs(config.Features) do
            if enabled == true then
                config.MasterEnabled = true
                break
            end
        end
    end
    if previous < 4 and target >= 4 then
        config.Movement = type(config.Movement) == "table" and config.Movement or {}
        if config.Movement.ArrivalRadius == nil
            or (previous >= 3 and (tonumber(config.Movement.ArrivalRadius) or 0) >= 12) then
            config.Movement.ArrivalRadius = 6
        end
    end
    if previous < 6 and target >= 6 then
        config.Movement = type(config.Movement) == "table" and config.Movement or {}
        local maximumSpeed = currentTransportCruiseSpeed()
        config.Movement.CruiseSpeed = maximumSpeed
        config.Movement.ReturnCruiseSpeed = maximumSpeed
    end
    if previous < 7 and target >= 7 then
        config.Economy = type(config.Economy) == "table" and config.Economy or {}
        if config.Economy.FuseMutationPolicy == nil then
            config.Economy.FuseMutationPolicy = config.Economy.FuseProtectMutations == false
                and "Allow"
                or "Protect"
        end
    end
    if previous < 8 and target >= 8 then
        config.Utilities = type(config.Utilities) == "table" and config.Utilities or {}
        config.Utilities.AutoQueueOnTeleport = false
    end
    if previous < 9 and target >= 9 then
        config.Movement = type(config.Movement) == "table" and config.Movement or {}
        config.Movement.Transport = "AuthenticatedOnly"
    end
    if previous < 10 and target >= 10 then
        config.Movement = type(config.Movement) == "table" and config.Movement or {}
        local maximumSpeed = currentTransportCruiseSpeed()
        config.Movement.Transport = "AuthenticatedOnly"
        config.Movement.CruiseSpeed = maximumSpeed
        config.Movement.ReturnCruiseSpeed = maximumSpeed
        config.Movement.PulseInterval = 0.12
    end
    if previous < 11 and target >= 11 then
        config.Movement = type(config.Movement) == "table" and config.Movement or {}
        config.Movement.ResponseGain = 8
        config.Movement.PulseInterval = 0.1
    end
    if previous < 13 and target >= 13 then
        config.Egg = type(config.Egg) == "table" and config.Egg or {}
        config.Egg.CustomStealSpeed = customStealSpeed(config.Egg.CustomStealSpeed)
        config.Egg.StealSpeedMultiplier = nil
    end
    if previous < 14 and target >= 14 then
        config.Egg = type(config.Egg) == "table" and config.Egg or {}
        config.Egg.StealInterval = 0.05
    end
    if previous < 15 and target >= 15 then
        config.Features = type(config.Features) == "table" and config.Features or {}
        config.Utilities = type(config.Utilities) == "table" and config.Utilities or {}
        config.Features.server_hop = false
        config.Utilities.HopAfterSeconds = 0
    end
    if previous < 16 and target >= 16 then
        config.Features = type(config.Features) == "table" and config.Features or {}
        config.Monster = type(config.Monster) == "table" and config.Monster or {}
        config.Finder = type(config.Finder) == "table" and config.Finder or {}
        config.Features.hungry_monster = false
        config.Monster.MinimumRarity = tonumber(config.Monster.MinimumRarity) or 1
        config.Monster.TargetMode = config.Monster.TargetMode or "Highest Rarity"
        config.Finder.TargetCategory = tostring(config.Finder.TargetCategory or "")
    end
    if previous < 17 and target >= 17 then
        config.Predictor = type(config.Predictor) == "table" and config.Predictor or {}
        if config.Predictor.Enabled == nil then
            config.Predictor.Enabled = true
        end
        config.Predictor.SelectedArea = tostring(config.Predictor.SelectedArea or "All Areas")
        config.Predictor.ForecastCount = math.clamp(
            math.floor(tonumber(config.Predictor.ForecastCount) or 5),
            1,
            8
        )
        config.Predictor.ObservationInterval = math.clamp(
            tonumber(config.Predictor.ObservationInterval) or 0.75,
            0.25,
            5
        )
        if config.Predictor.NotifyCommitted == nil then
            config.Predictor.NotifyCommitted = true
        end
    end
    config.SchemaVersion = target
    return config, true
end

local AREA_ORDER = {
    Forest = 1,
    Lake = 2,
    Desert = 3,
    Jungle = 4,
    Snow = 5,
    Volcano = 6,
    ["Abyss Ocean"] = 7,
    Prehistoric = 8,
    Cosmic = 9,
    ["Cherry Blossom"] = 10,
    ["Titan Temple"] = 11,
}

local LEGACY_AREAS = {
    "Forest",
    "Lake",
    "Desert",
    "Jungle",
    "Snow",
    "Volcano",
    "Abyss Ocean",
    "Prehistoric",
    "Cosmic",
}

local PRE_TITAN_AREAS = {
    "Forest",
    "Lake",
    "Desert",
    "Jungle",
    "Snow",
    "Volcano",
    "Abyss Ocean",
    "Prehistoric",
    "Cosmic",
    "Cherry Blossom",
}

local ALL_AREAS = {
    "Forest",
    "Lake",
    "Desert",
    "Jungle",
    "Snow",
    "Volcano",
    "Abyss Ocean",
    "Prehistoric",
    "Cosmic",
    "Cherry Blossom",
    "Titan Temple",
}

local STATIC_AREAS = deepCopy(ALL_AREAS)

local function discoverAreaCatalog(directoryModule, snapshotRecords, fallbackAreas)
    local discovered = {}
    local fallbackRank = {}
    local function add(areaId)
        if type(areaId) == "string" and areaId ~= "" then
            discovered[areaId] = true
        end
    end

    for index, areaId in ipairs(fallbackAreas or {}) do
        areaId = tostring(areaId)
        fallbackRank[areaId] = index
        add(areaId)
    end

    local directory = type(directoryModule) == "table"
        and (rawget(directoryModule, "Directory") or rawget(directoryModule, "Areas"))
        or nil
    directory = type(directory) == "table" and directory or directoryModule
    if type(directory) == "table" then
        for key, config in pairs(directory) do
            if type(config) == "table" then
                add(rawget(config, "_id")
                    or rawget(config, "AreaId")
                    or rawget(config, "Id")
                    or rawget(config, "DisplayName")
                    or (type(key) == "string" and key or nil))
            end
        end
    end

    local records = type(snapshotRecords) == "table"
        and (snapshotRecords.Records or snapshotRecords.records or snapshotRecords)
        or {}
    for _, record in pairs(records) do
        if type(record) == "table" then
            add(rawget(record, "AreaId") or rawget(record, "AreaID"))
        end
    end

    local result = {}
    for areaId in pairs(discovered) do
        result[#result + 1] = areaId
    end
    table.sort(result, function(left, right)
        local leftRank = fallbackRank[left] or math.huge
        local rightRank = fallbackRank[right] or math.huge
        if leftRank ~= rightRank then
            return leftRank < rightRank
        end
        return left < right
    end)
    return result
end

local function reconcileAreaSelection(selectedAreas, previousCatalog, currentCatalog)
    local selectedSet = buildTargetAreaSet(selectedAreas)
    local suffixStarted = false
    local contiguousSuffix = false
    for _, areaId in ipairs(previousCatalog or {}) do
        if selectedSet[areaId] then
            suffixStarted = true
            contiguousSuffix = true
        elseif suffixStarted then
            contiguousSuffix = false
        end
    end
    local previousLast = previousCatalog and previousCatalog[#previousCatalog]
    local expandNewest = contiguousSuffix and previousLast ~= nil and selectedSet[previousLast] == true

    local result = {}
    local previousSet = buildTargetAreaSet(previousCatalog)
    for _, areaId in ipairs(currentCatalog or {}) do
        if selectedSet[areaId] or (expandNewest and not previousSet[areaId]) then
            result[#result + 1] = areaId
        end
    end
    return result
end

local FEATURE_KEYS = {
    "steal_best_egg",
    "place_eggs",
    "hatch_ready",
    "hungry_monster",
    "equip_best",
    "smart_sell",
    "auto_sell_eggs",
    "auto_fuse",
    "treadmill_train",
    "treadmill_upgrade",
    "base_upgrade",
    "rebirth",
    "offline_income",
    "group_reward",
    "index_rewards",
    "free_gifts",
    "rare_egg_esp",
}

local DEFAULT_CONFIG = {
    SchemaVersion = 17,
    MasterEnabled = false,
    Features = {
        steal_best_egg = false,
        place_eggs = false,
        hatch_ready = false,
        hungry_monster = false,
        equip_best = false,
        smart_sell = false,
        auto_sell_eggs = false,
        auto_fuse = false,
        treadmill_train = false,
        treadmill_upgrade = false,
        base_upgrade = false,
        rebirth = false,
        offline_income = false,
        group_reward = false,
        index_rewards = false,
        free_gifts = false,
        rare_egg_esp = false,
    },
    Egg = {
        TargetMode = "Best Value",
        SelectedAreas = deepCopy(ALL_AREAS),
        MinimumRarity = 1,
        MinimumWeightKg = 0,
        SizeTier = "Any Size",
        MutationRequirement = "Any",
        SelectedCategories = {},
        PlacementColumns = 3,
        PlacementSpacing = 6,
        CarryOffset = 3.25,
        CustomStealSpeed = 0,
        StealInterval = 0.05,
        PlaceInterval = 0.25,
        HatchInterval = 0.8,
        SnapshotMaxAge = 0.08,
        StealTimeoutSeconds = 10,
        StealArrivalRadius = 3,
    },
    Monster = {
        MinimumRarity = 1,
        TargetMode = "Highest Rarity",
        ActionInterval = 0.12,
    },
    Finder = {
        TargetCategory = "",
        ScanDelay = 2,
        MaximumVisitedServers = 250,
    },
    Predictor = {
        Enabled = true,
        SelectedArea = "All Areas",
        ForecastCount = 5,
        ObservationInterval = 0.75,
        NotifyCommitted = true,
        HistoryLimit = 600,
    },
    Economy = {
        SellMaxRarity = 2,
        KeepCount = 8,
        ProtectMutations = true,
        FuseStrategy = "Lowest Value",
        FuseCategoryMode = "All Categories",
        FuseCategories = {},
        FuseMinimumRarity = 1,
        FuseMaximumRarity = 9,
        FuseMaximumWeightKg = 0,
        FuseMaximumScale = 0,
        FuseMutationPolicy = "Protect",
        FuseKeepPerCategory = 0,
        FuseMaximumPrice = 0,
        FusionsPerCycle = 1,
        FuseAllowEquipped = false,
        FuseAllowFavorites = false,
        EggSellMode = "Selected Types",
        EggSellTypes = {},
        EggSellBatchSize = 20,
    },
    Movement = {
        Transport = "AuthenticatedOnly",
        LocomotionFallback = true,
        TransitWalkSpeedMultiplier = 1,
        GlideSpeedMultiplier = 1,
        SettleSeconds = 0,
        CruiseSpeed = 96,
        ResponseGain = 8,
        ReturnCruiseSpeed = 900,
        ReturnResponseGain = 12,
        ReturnGraceSeconds = 0,
        SafeCorridorMargin = 18,
        RouteLegTimeoutSeconds = 4,
        ArrivalRadius = 6,
        PulseInterval = 0.1,
        TransientAnchorGraceSeconds = 0.35,
        TimeoutSeconds = 14,
    },
    Visuals = {
        MinimumRarity = 4,
        MaxMarkers = 30,
        ShowDistance = true,
        NotifyRare = true,
    },
    Utilities = {
        AutoQueueOnTeleport = false,
        HopAfterSeconds = 0,
    },
    Codes = {},
    ConfigName = "steal-an-egg",
}

local function ensureConfigFolder()
    if type(makefolder) ~= "function" then
        return false
    end
    pcall(makefolder, "VoidHub")
    pcall(makefolder, CONFIG_FOLDER)
    return true
end

local BOOT_WITH_AUTOMATION_OFF = true

local function disarmAutomationState(config)
    if type(config) ~= "table" then
        return config
    end
    config.MasterEnabled = false
    if type(config.Features) == "table" then
        for key in pairs(config.Features) do
            config.Features[key] = false
        end
    end
    return config
end

local function loadPersistentConfig()
    local config = deepCopy(DEFAULT_CONFIG)
    if type(isfile) ~= "function" or type(readfile) ~= "function" then
        return config
    end
    local existsOk, exists = pcall(isfile, CONFIG_PATH)
    if not existsOk or not exists then
        return config
    end
    local readOk, encoded = pcall(readfile, CONFIG_PATH)
    if not readOk or type(encoded) ~= "string" then
        return config
    end
    local decodeOk, decoded = pcall(HttpService.JSONDecode, HttpService, encoded)
    if decodeOk and type(decoded) == "table" then
        local _, migrated = migrateAutomationConfig(decoded, DEFAULT_CONFIG.SchemaVersion)
        deepMerge(config, decoded)
        config.Egg.CustomStealSpeed = customStealSpeed(config.Egg.CustomStealSpeed)
        config.Movement.CruiseSpeed = currentTransportCruiseSpeed()
        config.Movement.ReturnCruiseSpeed = currentTransportCruiseSpeed()
        config.Movement.Transport = DEFAULT_CONFIG.Movement.Transport
        if BOOT_WITH_AUTOMATION_OFF then
            disarmAutomationState(config)
        end
        return config, migrated
    end
    return config, false
end

local Runtime = {}
Runtime.__index = Runtime

function Runtime.new()
    local loadedConfig, configMigrated = loadPersistentConfig()
    return setmetatable({
        Version = VERSION,
        ExecutorName = EXECUTOR_NAME,
        ExecutorCapabilities = {
            RuntimeGraph = type(getgc) == "function",
            DebugInfo = type(debug) == "table" and type(debug.info) == "function",
            DebugUpvalues = type(debug) == "table" and type(debug.getupvalues) == "function",
            FileSystem = type(readfile) == "function" and type(writefile) == "function",
            HttpRequest = type(request) == "function" or type(http_request) == "function",
        },
        Generation = HttpService:GenerateGUID(false),
        StartedAt = os.clock(),
        AutomationResumeAt = os.clock() + 10,
        Destroyed = false,
        Busy = false,
        BusyAction = "Idle",
        LastAction = "None",
        LastResult = "Ready",
        LastError = nil,
        Connections = {},
        Workers = {},
        ThreadTokens = {},
        Config = loadedConfig,
        ConfigMigrationPending = configMigrated == true,
        ConfigWriteGeneration = 0,
        CallMetrics = {},
        FeatureStatus = {},
        Session = {
            EggsStolen = 0,
            EggsPlaced = 0,
            EggsHatched = 0,
            EggsSold = 0,
            PetsSold = 0,
            Fusions = 0,
            RewardsClaimed = 0,
            MonsterFeeds = 0,
            MonsterChests = 0,
            FinderHops = 0,
            TreadmillActive = false,
        },
    }, Runtime)
end

function Runtime:track(connection)
    if connection then
        self.Connections[#self.Connections + 1] = connection
    end
    return connection
end

function Runtime:spawn(name, interval, callback)
    self:stop(name)
    local token = {Alive = true, Name = name}
    self.Workers[name] = token
    task.spawn(function()
        self.ThreadTokens[coroutine.running()] = token
        while token.Alive and not self.Destroyed do
            local ok, err = xpcall(callback, debug.traceback, token)
            if not ok then
                token.Failures = (token.Failures or 0) + 1
                token.Error = tostring(err)
                self.LastError = token.Error
            end
            task.wait(math.max(0.03, tonumber(interval) or 0.1))
        end
        self.ThreadTokens[coroutine.running()] = nil
    end)
    return token
end

function Runtime:stop(name)
    local token = self.Workers[name]
    if token then
        token.Alive = false
        self.Workers[name] = nil
    end
end

function Runtime:stopAll(reason)
    for name in pairs(shallowCopy(self.Workers)) do
        self:stop(name)
    end
    self.MasterStopReason = reason
end

function Runtime:isCurrent()
    return not self.Destroyed and G.__VOIDHUB_STEAL_AN_EGG_RUNTIME == self
end

function Runtime:setStatus(feature, status, detail)
    self.FeatureStatus[feature] = updateStatusRecord(self.FeatureStatus[feature], status, detail, os.clock())
end

function Runtime:runAction(name, callback)
    if self.Destroyed then
        return false, "Runtime destroyed"
    end
    if self.Busy then
        return false, "Busy: " .. tostring(self.BusyAction)
    end
    self.Busy = true
    self.BusyAction = name
    self.LastAction = name
    local results = pack(xpcall(callback, debug.traceback))
    self.Busy = false
    self.BusyAction = "Idle"
    if not results[1] then
        self.LastError = tostring(results[2])
        self.LastResult = self.LastError
        return false, results[2]
    end
    self.LastResult = tostring(results[2] == nil and "Completed" or results[2])
    return true, table.unpack(results, 2, results.n)
end

function Runtime:notify(title, description, duration)
    if self.Window and type(self.Window.Notify) == "function" then
        pcall(self.Window.Notify, self.Window, {
            Title = tostring(title or "VoidHub"),
            Text = tostring(description or ""),
            Duration = tonumber(duration) or 2.8,
        })
    end
end

function Runtime:saveConfigNow()
    if type(writefile) ~= "function" then
        return false, "Filesystem API unavailable"
    end
    ensureConfigFolder()
    local encodeOk, encoded = pcall(HttpService.JSONEncode, HttpService, self.Config)
    if not encodeOk then
        return false, encoded
    end
    local writeOk, writeError = pcall(writefile, CONFIG_PATH, encoded)
    return writeOk, writeError
end

function Runtime:queueConfigSave()
    self.ConfigWriteGeneration += 1
    local generation = self.ConfigWriteGeneration
    task.delay(0.5, function()
        if self:isCurrent() and generation == self.ConfigWriteGeneration then
            self:saveConfigNow()
        end
    end)
end

function Runtime:destroy(reason)
    if self.Destroyed then
        return
    end
    self.Destroyed = true
    local preserveAutomation = reason == "Re-executed" or reason == "Teleporting"
    if not preserveAutomation then
        self.Config.MasterEnabled = false
    end
    self:saveConfigNow()
    if self.WorldSpawnPredictor and type(self.WorldSpawnPredictor._saveNow) == "function" then
        pcall(self.WorldSpawnPredictor._saveNow, self.WorldSpawnPredictor)
    end
    self:stopAll(reason or "Destroyed")
    if self.Godmode then
        pcall(self.Godmode.disable, self.Godmode, reason or "Destroyed")
    end
    if self.ExperimentalFly then
        pcall(self.ExperimentalFly.disable, self.ExperimentalFly, reason or "Destroyed")
    end
    if self.Movement then
        pcall(self.Movement.restore, self.Movement)
    end
    if self.Visuals then
        pcall(self.Visuals.destroy, self.Visuals)
    end
    for _, connection in ipairs(self.Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    table.clear(self.Connections)
    if self.Window then
        pcall(self.Window.Unload, self.Window)
        self.Window = nil
    end
    if G.__VOIDHUB_STEAL_AN_EGG_RUNTIME == self then
        G.__VOIDHUB_STEAL_AN_EGG_RUNTIME = nil
    end
end

if G.__VOIDHUB_STEAL_AN_EGG_RUNTIME and type(G.__VOIDHUB_STEAL_AN_EGG_RUNTIME.destroy) == "function" then
    pcall(G.__VOIDHUB_STEAL_AN_EGG_RUNTIME.destroy, G.__VOIDHUB_STEAL_AN_EGG_RUNTIME, "Re-executed")
end

local runtime = Runtime.new()
G.__VOIDHUB_STEAL_AN_EGG_RUNTIME = runtime
runtime.Config.Features.server_hop = nil
runtime.Config.Utilities.HopAfterSeconds = 0
if runtime.ConfigMigrationPending then
    runtime:queueConfigSave()
end

local function ResolveNetworkContainer()
    local packages = ReplicatedStorage:FindFirstChild("Packages")
    local networking = packages and packages:FindFirstChild("Networking")
    if networking then
        return networking
    end
    return ReplicatedStorage:FindFirstChild("Network")
end

local ENDPOINTS = {
    EggSnapshot = {Name = "Eggs: RequestAreaEggSnapshot", ClassName = "RemoteFunction", Cooldown = 0.25},
    EggCarry = {Name = "Eggs: RequestAreaEggCarry", ClassName = "RemoteFunction", Cooldown = 0.2},
    EggDrop = {Name = "Eggs: RequestAreaEggDrop", ClassName = "RemoteFunction", Cooldown = 0.2},
    EggRuntimeSnapshot = {Name = "Eggs: RequestRuntimeSnapshot", ClassName = "RemoteFunction", Cooldown = 0.25},
    EggRecord = {Name = "Eggs: RequestEggRecord", ClassName = "RemoteFunction", Cooldown = 0.1},
    EggEquip = {Name = "Eggs: RequestEquipTool", ClassName = "RemoteFunction", Cooldown = 0.1},
    EggUnequip = {Name = "RF/EggWorld/AskDoffTool", ClassName = "RemoteFunction", Cooldown = 0.1},
    EggPlace = {Name = "Eggs: RequestPlaceEgg", ClassName = "RemoteFunction", Cooldown = 0.2},
    EggSkipGrowth = {Name = "Eggs: RequestSkipGrowth", ClassName = "RemoteFunction", Cooldown = 1},
    EggHatch = {Name = "Eggs: RequestHatchEgg", ClassName = "RemoteFunction", Cooldown = 0.1},
    EggCompleteHatch = {Name = "Eggs: RequestCompleteHatchEgg", ClassName = "RemoteFunction", Cooldown = 0.1},
    EquipBest = {Name = "Backpack: EquipBest", ClassName = "RemoteFunction", Cooldown = 1},
    SellAsset = {Name = "RE/PetSatchel/SellPet", ClassName = "RemoteEvent", Cooldown = 0.05},
    SellAll = {Name = "RE/PetSatchel/SellEveryPet", ClassName = "RemoteEvent", Cooldown = 0.5},
    SetFavorite = {Name = "RE/PetSatchel/WriteFavourite", ClassName = "RemoteEvent", Cooldown = 0.05},
    FuseInsert = {Name = "RF/Fusery/LoadPet", ClassName = "RemoteFunction", Cooldown = 0.1},
    FuseRemove = {Name = "RF/Fusery/EjectPet", ClassName = "RemoteFunction", Cooldown = 0.1},
    FuseStart = {Name = "RF/Fusery/BeginFuse", ClassName = "RemoteFunction", Cooldown = 0.25},
    FuseComplete = {Name = "RF/Fusery/FinishReveal", ClassName = "RemoteFunction", Cooldown = 0.25},
    TreadmillEquip = {Name = "RF/Treadmill/AskWearStill", ClassName = "RemoteFunction", Cooldown = 1},
    TreadmillUnequip = {Name = "RF/Treadmill/AskDoff", ClassName = "RemoteFunction", Cooldown = 1},
    TreadmillUpgrade = {Name = "RF/Treadmill/AskTierRaise", ClassName = "RemoteFunction", Cooldown = 1},
    BaseUpgrade = {Name = "RE/Homestead/AskBaseTierRaise", ClassName = "RemoteEvent", Cooldown = 1},
    RebirthRequest = {Name = "Rebirth: RequestRebirth", ClassName = "RemoteFunction", Cooldown = 2},
    RebirthCommit = {Name = "Rebirth: Commit", ClassName = "RemoteFunction", Cooldown = 2},
    OfflineSummary = {Name = "RF/AwayEarnings/FetchSummary", ClassName = "RemoteFunction", Cooldown = 2},
    OfflineRedeem = {Name = "RF/AwayEarnings/AskCollect", ClassName = "RemoteFunction", Cooldown = 3},
    GroupReward = {Name = "RF/GroupPerk/RedeemPerk", ClassName = "RemoteFunction", Cooldown = 5},
    IndexClaim = {Name = "RF/Codex/AskRedeem", ClassName = "RemoteFunction", Cooldown = 0.5},
    IndexClaimAll = {Name = "RF/Codex/AskRedeemAll", ClassName = "RemoteFunction", Cooldown = 2},
    IndexLimitedReward = {Name = "RF/Codex/AskRedeemLimitedEgg", ClassName = "RemoteFunction", Cooldown = 2},
    IndexEquipBat = {Name = "RF/Codex/AskWearFieldBat", ClassName = "RemoteFunction", Cooldown = 1},
    FreeGiftClaim = {Name = "FreeGifts: RequestClaim", ClassName = "RemoteFunction", Cooldown = 1},
    CodeClaim = {Name = "Codes: Claim", ClassName = "RemoteFunction", Cooldown = 1},
    CodeState = {Name = "Codes: Get Active Code State", ClassName = "RemoteFunction", Cooldown = 3},
    LobbyTeleport = {Name = "RE/Homestead/AskLobbyHop", ClassName = "RemoteEvent", Cooldown = 0.1},
}

local Resolver = {}
Resolver.__index = Resolver

function Resolver.new()
    return setmetatable({
        ModuleCache = {},
        InstanceCache = {},
    }, Resolver)
end

function Resolver:invalidate()
    table.clear(self.ModuleCache)
    table.clear(self.InstanceCache)
end

function Resolver:path(parts)
    local current = ReplicatedStorage
    for _, name in ipairs(parts) do
        current = current and current:FindFirstChild(name)
        if not current then
            return nil
        end
    end
    return current
end

function Resolver:find(name, className)
    local cached = self.InstanceCache[name]
    if cached and cached.Parent and (not className or cached.ClassName == className) then
        return cached
    end
    local instance = ReplicatedStorage:FindFirstChild(name, true)
    if instance and (not className or instance.ClassName == className) then
        self.InstanceCache[name] = instance
        return instance
    end
    return nil
end

function Resolver:requirePath(key, parts)
    if self.ModuleCache[key] ~= nil then
        return self.ModuleCache[key] or nil
    end
    local module = self:path(parts)
    if not module or not module:IsA("ModuleScript") then
        self.ModuleCache[key] = false
        return nil
    end
    local ok, value = pcall(require, module)
    self.ModuleCache[key] = ok and value or false
    return ok and value or nil
end

function Resolver:requireNamed(key, name)
    if self.ModuleCache[key] ~= nil then
        return self.ModuleCache[key] or nil
    end
    local module = self:find(name, "ModuleScript")
    if not module then
        self.ModuleCache[key] = false
        return nil
    end
    local ok, value = pcall(require, module)
    self.ModuleCache[key] = ok and value or false
    return ok and value or nil
end

local Broker = {}
Broker.__index = Broker

function Broker.new(owner)
    return setmetatable({
        Runtime = owner,
        Network = ResolveNetworkContainer(),
        Cache = {},
        LastCallAt = {},
        InFlight = {},
        DefaultTimeout = 5,
    }, Broker)
end

function Broker:_metric(key)
    local metric = self.Runtime.CallMetrics[key]
    if not metric then
        metric = {Calls = 0, Successes = 0, Failures = 0, Timeouts = 0, Busy = 0, Unavailable = 0, LastError = nil}
        self.Runtime.CallMetrics[key] = metric
    end
    return metric
end

function Broker:_resolve(key)
    local spec = ENDPOINTS[key]
    if not spec then
        return nil, "Unknown endpoint: " .. tostring(key)
    end
    local cached = self.Cache[key]
    if cached and cached.Parent and cached.ClassName == spec.ClassName then
        return cached, spec
    end
    self.Network = self.Network and self.Network.Parent and self.Network or ResolveNetworkContainer()
    local remote = self.Network and self.Network:FindFirstChild(spec.Name)
    if not remote then
        self.Cache[key] = nil
        return nil, "Unavailable: " .. spec.Name
    end
    if remote.ClassName ~= spec.ClassName then
        self.Cache[key] = nil
        return nil, string.format("Rejected %s (%s, expected %s)", spec.Name, remote.ClassName, spec.ClassName)
    end
    self.Cache[key] = remote
    return remote, spec
end

function Broker:available(key)
    local remote = self:_resolve(key)
    return remote ~= nil
end

function Broker:call(key, ...)
    local metric = self:_metric(key)
    local remote, specOrError = self:_resolve(key)
    if not remote then
        metric.Unavailable += 1
        metric.LastError = tostring(specOrError)
        return false, metric.LastError
    end
    local spec = specOrError
    local activeCall = self.InFlight[key]
    if remoteCallDisposition(activeCall ~= nil and activeCall.Done ~= true, false, 0, 1) == "busy" then
        metric.Busy += 1
        metric.LastError = "Remote call already in flight: " .. tostring(spec.Name)
        return false, metric.LastError
    end
    local now = os.clock()
    local elapsed = now - (self.LastCallAt[key] or -math.huge)
    local cooldown = tonumber(spec.Cooldown) or 0
    if elapsed < cooldown then
        task.wait(cooldown - elapsed)
    end
    if self.Runtime.Destroyed then
        return false, "Runtime destroyed"
    end

    self.LastCallAt[key] = os.clock()
    metric.Calls += 1
    local arguments = pack(...)
    local results
    if spec.ClassName == "RemoteFunction" then
        local callState = {Done = false, Results = nil}
        self.InFlight[key] = callState
        task.spawn(function()
            callState.Results = pack(pcall(remote.InvokeServer, remote, table.unpack(arguments, 1, arguments.n)))
            callState.Done = true
            if self.InFlight[key] == callState then
                self.InFlight[key] = nil
            end
        end)

        local timeout = clampFinite(spec.Timeout, 0.1, 30, self.DefaultTimeout)
        local deadline = os.clock() + timeout
        while not self.Runtime.Destroyed do
            local disposition = remoteCallDisposition(false, callState.Done, os.clock(), deadline)
            if disposition == "complete" then
                results = callState.Results
                break
            end
            if disposition == "timeout" then
                metric.Failures += 1
                metric.Timeouts += 1
                metric.LastError = string.format("Remote timeout after %.1fs: %s", timeout, tostring(spec.Name))
                metric.LastAt = os.clock()
                return false, metric.LastError
            end
            task.wait(0.02)
        end
        if not results then
            metric.Failures += 1
            metric.LastError = "Runtime destroyed while awaiting " .. tostring(spec.Name)
            metric.LastAt = os.clock()
            return false, metric.LastError
        end
    else
        results = pack(pcall(remote.FireServer, remote, table.unpack(arguments, 1, arguments.n)))
        if results[1] then
            results[2] = true
            results.n = math.max(results.n, 2)
        end
    end
    if results[1] then
        metric.Successes += 1
        metric.LastError = nil
    else
        metric.Failures += 1
        metric.LastError = tostring(results[2])
    end
    metric.LastAt = os.clock()
    return unpackPack(results)
end

function Broker:rescan()
    table.clear(self.Cache)
    self.Network = ReplicatedStorage:FindFirstChild("Network")
    local available = 0
    for key in pairs(ENDPOINTS) do
        if self:available(key) then
            available += 1
        end
    end
    return available, countTable(ENDPOINTS)
end

local resolver = Resolver.new()
local broker = Broker.new(runtime)
runtime.Resolver = resolver
runtime.Broker = broker

local State = {}
State.__index = State

function State.new(owner, networkResolver, networkBroker)
    local self = setmetatable({
        Runtime = owner,
        Resolver = networkResolver,
        Broker = networkBroker,
        Modules = {},
        LastAreaSnapshot = nil,
        LastRuntimeSnapshot = nil,
        LastAreaRefreshAt = -math.huge,
        LastRuntimeRefreshAt = -math.huge,
        LastCarryState = nil,
        CarryStateSequence = 0,
    }, State)
    self:loadModules()
    self:bindCarryState()
    return self
end

function State:loadModules()
    local modules = self.Modules
    modules.Remotes = self.Resolver:requirePath("SharedRemotes", {"Shared", "Remotes"})
    local legacyEggCmds = self.Resolver:requirePath("EggCmds", {"Library", "Client", "EggCmds"})
    local eggState = self.Resolver:requirePath("EggState", {"Client", "EggState"})
    modules.EggState = eggState
    if type(eggState) == "table" then
        modules.EggCmds = {
            GetAreaEggSnapshot = eggState.ReadFieldEggs
                or (type(legacyEggCmds) == "table" and legacyEggCmds.GetAreaEggSnapshot),
            RequestAreaEggSnapshot = eggState.SyncFieldEggs
                or (type(legacyEggCmds) == "table" and legacyEggCmds.RequestAreaEggSnapshot),
            AreaEggCarryStateChanged = eggState.CarryChanged
                or (type(legacyEggCmds) == "table" and legacyEggCmds.AreaEggCarryStateChanged),
            RequestCarryAreaEgg = eggState.CarryFieldEgg
                or (type(legacyEggCmds) == "table" and legacyEggCmds.RequestCarryAreaEgg),
            RequestDropHeldAreaEgg = eggState.DropFieldEgg
                or (type(legacyEggCmds) == "table" and legacyEggCmds.RequestDropHeldAreaEgg),
            IsLocalEggReady = eggState.IsReadyToHatch
                or (type(legacyEggCmds) == "table" and legacyEggCmds.IsLocalEggReady),
            RequestHatchEgg = eggState.BeginHatch
                or (type(legacyEggCmds) == "table" and legacyEggCmds.RequestHatchEgg),
            RequestCompleteHatchEgg = eggState.FinishHatch
                or (type(legacyEggCmds) == "table" and legacyEggCmds.RequestCompleteHatchEgg),
            RequestEquipTool = eggState.WearEggTool
                or (type(legacyEggCmds) == "table" and legacyEggCmds.RequestEquipTool),
            RequestPlaceEgg = eggState.PlantEgg
                or (type(legacyEggCmds) == "table" and legacyEggCmds.RequestPlaceEgg),
            GetRuntimeSnapshot = type(legacyEggCmds) == "table" and legacyEggCmds.GetRuntimeSnapshot or nil,
        }
    else
        modules.EggCmds = legacyEggCmds
    end
    modules.AssetCmds = self.Resolver:requirePath("AssetCmds", {"Library", "Client", "AssetCmds"})
    modules.InventoryCmds = self.Resolver:requirePath("InventoryCmds", {"Library", "Client", "InventoryCmds"})
    local legacyPlotCmds = self.Resolver:requirePath("PlotCmds", {"Library", "Client", "PlotCmds"})
    local plotState = self.Resolver:requirePath("PlotState", {"Client", "PlotState"})
    if type(plotState) == "table" then
        modules.PlotCmds = {
            GetPlotData = plotState.ResolvePlot
                or (type(legacyPlotCmds) == "table" and legacyPlotCmds.GetPlotData),
            GetRespawnPointCFrame = plotState.FindRespawnCFrame
                or (type(legacyPlotCmds) == "table" and legacyPlotCmds.GetRespawnPointCFrame),
            IsWorldPositionWithinLocalPlotBounds = plotState.ContainsLocalPoint
                or (type(legacyPlotCmds) == "table" and legacyPlotCmds.IsWorldPositionWithinLocalPlotBounds),
            GetSlotOwner = plotState.LookupOwner
                or (type(legacyPlotCmds) == "table" and legacyPlotCmds.GetSlotOwner),
            GetMySlot = plotState.ResolveLocalSlot
                or (type(legacyPlotCmds) == "table" and legacyPlotCmds.GetMySlot),
        }
    else
        modules.PlotCmds = legacyPlotCmds
    end
    modules.Save = self.Resolver:requirePath("Save", {"Library", "Client", "Save"})
        or self.Resolver:requirePath("SharedSave", {"Shared", "Save"})
    local legacySlotIdentity = self.Resolver:requirePath(
        "AreaEggSlotIdentity",
        {"Library", "Util", "AreaEggSlotIdentity"}
    )
    local currentSlotIdentity = self.Resolver:requirePath(
        "SharedAreaEggSlotIdentity",
        {"Shared", "Util", "AreaEggSlotIdentity"}
    )
    if type(currentSlotIdentity) == "table" then
        modules.AreaEggSlotIdentity = {
            IsFirstAreaUid = currentSlotIdentity.LooksLikeFirstAreaUid
                or currentSlotIdentity.IsFirstAreaUid
                or (type(legacySlotIdentity) == "table" and legacySlotIdentity.IsFirstAreaUid),
            BuildSlotKey = currentSlotIdentity.SlotKey
                or currentSlotIdentity.BuildSlotKey
                or (type(legacySlotIdentity) == "table" and legacySlotIdentity.BuildSlotKey),
        }
    else
        modules.AreaEggSlotIdentity = legacySlotIdentity
    end
    modules.Assets = self.Resolver:requirePath("DirectoryAssets", {"Directory", "Assets"})
        or self.Resolver:requirePath("DataAssets", {"Data", "Assets"})
    modules.Areas = self.Resolver:requirePath("DirectoryAreas", {"Directory", "Areas"})
        or self.Resolver:requirePath("DataAreas", {"Data", "Areas"})
    modules.Treadmills = self.Resolver:requirePath("DirectoryTreadmills", {"Directory", "Treadmills"})
        or self.Resolver:requirePath("DataTreadmills", {"Data", "Treadmills"})
    modules.Bases = self.Resolver:requirePath("DirectoryBases", {"Directory", "Bases"})
    modules.Rebirths = self.Resolver:requirePath("DirectoryRebirths", {"Directory", "Rebirths"})
    modules.FreeGifts = self.Resolver:requirePath("DirectoryFreeGifts", {"Directory", "FreeGifts"})
    modules.Constants = self.Resolver:requireNamed("Constants", "Constants")
    modules.Serialization = self.Resolver:requireNamed("AssetItemSerialization", "AssetItemSerialization")
    modules.Mutations = self.Resolver:requireNamed("Mutations", "Mutations")
    modules.EggItemUtil = self.Resolver:requirePath("EggItemUtil", {"Library", "Util", "EggItemUtil"})
    modules.AssetItemUtil = self.Resolver:requirePath("AssetItemUtil", {"Library", "Util", "AssetItemUtil"})
    modules.FuseKernelUtil = self.Resolver:requirePath("FuseKernelUtil", {"Library", "Util", "FuseKernelUtil"})
    modules.RebirthUtil = self.Resolver:requireNamed("RebirthUtil", "RebirthUtil")
    modules.TreadmillUtil = self.Resolver:requirePath("TreadmillUtil", {"Library", "Util", "TreadmillUtil"})
        or self.Resolver:requirePath("SharedTreadmillUtil", {"Shared", "Util", "TreadmillUtil"})
    modules.SpeedPowerProjection = self.Resolver:requirePath(
        "SpeedPowerProjection",
        {"Library", "Client", "SpeedPowerProjection"}
    )
    modules.RuntimeInstanceRegistry = self.Resolver:requirePath(
        "RuntimeInstanceRegistry",
        {"Library", "Modules", "RuntimeInstanceRegistry"}
    )
        or self.Resolver:requirePath(
            "CurrentRuntimeInstanceRegistry",
            {"Client", "Modules", "RuntimeInstanceRegistry"}
        )
    modules.MonsterParasite = self.Resolver:requirePath(
        "MonsterParasiteData",
        {"Data", "MonsterParasite"}
    )
    modules.MonsterParasiteEligibility = self.Resolver:requirePath(
        "MonsterParasiteEligibility",
        {"Shared", "Util", "MonsterParasiteEligibility"}
    )
end

function State:bindCarryState()
    local eggCmds = self.Modules.EggCmds
    local signal = type(eggCmds) == "table" and eggCmds.AreaEggCarryStateChanged or nil
    if type(signal) ~= "table" or type(signal.Connect) ~= "function" then
        return false
    end
    local connection = signal:Connect(function(carryState)
        self.CarryStateSequence += 1
        self.LastCarryState = type(carryState) == "table" and carryState or nil
    end)
    self.Runtime:track(connection)
    return true
end

function State:beginCarryAwait()
    self.LastCarryState = nil
    return self.CarryStateSequence
end

function State:waitForCarryState(expectedUid, afterSequence, timeoutSeconds)
    local deadline = os.clock() + clampFinite(timeoutSeconds, 0.1, 2, 1)
    repeat
        if self.CarryStateSequence > (tonumber(afterSequence) or 0) then
            local disposition = carryStateDisposition(self.LastCarryState, expectedUid)
            if disposition == "ready" then
                return true, self.LastCarryState
            elseif disposition == "fail" then
                return false, "Server did not replicate the requested carried egg"
            end
        end
        RunService.Heartbeat:Wait()
    until os.clock() >= deadline
    return false, "Timed out waiting for replicated egg carry state"
end

function State:callEggCommand(commandName, endpointKey, fallbackArguments, ...)
    local eggCmds = self.Modules.EggCmds
    local callback = type(eggCmds) == "table" and eggCmds[commandName] or nil
    if type(callback) == "function" then
        local results = pack(pcall(callback, ...))
        if results[1] ~= true then
            return false, results[2]
        end
        return true, table.unpack(results, 2, results.n)
    end
    return self.Broker:call(endpointKey, table.unpack(fallbackArguments or {}))
end

function State:callCurrentRemote(path, endpointKey, fallbackArguments, ...)
    local remote = self.Modules.Remotes
    for _, key in ipairs(path or {}) do
        remote = type(remote) == "table" and remote[key] or nil
        if remote == nil then
            break
        end
    end
    if typeof(remote) ~= "Instance" then
        return self.Broker:call(endpointKey, table.unpack(fallbackArguments or {}))
    end

    local arguments = pack(...)
    if remote:IsA("RemoteEvent") then
        local ok, reason = pcall(remote.FireServer, remote, table.unpack(arguments, 1, arguments.n))
        return ok, ok and true or reason
    elseif not remote:IsA("RemoteFunction") then
        return false, "Mapped endpoint is not a Roblox remote"
    end

    local call = {Done = false, Results = nil}
    task.spawn(function()
        call.Results = pack(pcall(remote.InvokeServer, remote, table.unpack(arguments, 1, arguments.n)))
        call.Done = true
    end)
    local deadline = os.clock() + 5
    while not call.Done and not self.Runtime.Destroyed and os.clock() < deadline do
        task.wait(0.02)
    end
    if not call.Done then
        return false, "Current remote call timed out"
    end
    return unpackPack(call.Results)
end

function State:getSave()
    local saveModule = self.Modules.Save
    if type(saveModule) ~= "table" then
        return {}
    end
    for _, name in ipairs({"Get", "GetSave", "GetData", "GetLocalSave"}) do
        local callback = saveModule[name]
        if type(callback) == "function" then
            local ok, value = pcall(callback)
            if ok and type(value) == "table" then
                return value
            end
        end
    end
    return {}
end

function State:getProjectedSpeedPower()
    local projection = self.Modules.SpeedPowerProjection
    if type(projection) == "table" and type(projection.GetSpeedPower) == "function" then
        local ok, value = pcall(projection.GetSpeedPower)
        if ok and tonumber(value) then
            return tonumber(value)
        end
    end
    return tonumber(self:getSave().SpeedPower) or 10
end

function State:getNativeWalkSpeed()
    local treadmillUtil = self.Modules.TreadmillUtil
    if type(treadmillUtil) == "table" and type(treadmillUtil.SpeedPowerToWalkSpeed) == "function" then
        local ok, value = pcall(treadmillUtil.SpeedPowerToWalkSpeed, self:getProjectedSpeedPower())
        if ok and tonumber(value) then
            return tonumber(value)
        end
    end
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    return tonumber(humanoid and humanoid.WalkSpeed) or 16
end

function State:getTransportCruiseSpeed()
    return currentTransportCruiseSpeed(self:getNativeWalkSpeed())
end

function State:getCarryTransportCruiseSpeed(carryState)
    local multiplier = type(carryState) == "table" and carryState.SpeedMultiplier or 1
    return currentCarryTransportCruiseSpeed(self:getNativeWalkSpeed(), multiplier)
end

function State:getTargetAreas(selectedAreas)
    return chooseTargetAreas(selectedAreas or ALL_AREAS, ALL_AREAS)
end

function State:requestDirectAreaSnapshot()
    local packages = ReplicatedStorage:FindFirstChild("Packages")
    local networking = packages and packages:FindFirstChild("Networking")
    local remote = networking and networking:FindFirstChild("RF/EggWorld/AskFieldEggSnapshot")
    if not remote or not remote:IsA("RemoteFunction") then
        return nil, "Current field snapshot remote is unavailable"
    end
    local ok, snapshot = pcall(remote.InvokeServer, remote)
    if not ok then
        return nil, tostring(snapshot)
    end
    if type(snapshot) ~= "table" or type(snapshot.Records) ~= "table" then
        return nil, "Current field snapshot response was malformed"
    end
    return snapshot, nil
end

function State:requestAreaSnapshot(maxAge)
    local now = os.clock()
    if snapshotCacheDecision(self.LastAreaSnapshot ~= nil, self.LastAreaRefreshAt, now, maxAge) == "cache" then
        return self.LastAreaSnapshot
    end
    local eggCmds = self.Modules.EggCmds
    if type(eggCmds) == "table" and type(eggCmds.GetAreaEggSnapshot) == "function" then
        local sync = eggCmds.RequestAreaEggSnapshot
        if type(sync) == "function" then
            pcall(sync)
        end
        local ok, snapshot = pcall(eggCmds.GetAreaEggSnapshot)
        if ok and type(snapshot) == "table" then
            local source = snapshot.Records or snapshot.records or snapshot
            local liveContainer = Workspace:FindFirstChild("AreaEggSlotsClient")
            local liveCount = liveContainer and #liveContainer:GetChildren() or 0
            if type(source) == "table" and (next(source) ~= nil or liveCount == 0) then
                self.LastAreaSnapshot = snapshot
                self.LastAreaRefreshAt = os.clock()
                return snapshot
            end
        end
    end
    local directSnapshot = self:requestDirectAreaSnapshot()
    if type(directSnapshot) == "table" then
        self.LastAreaSnapshot = directSnapshot
        self.LastAreaRefreshAt = os.clock()
        return directSnapshot
    end
    local transportOk, snapshot = self.Broker:call("EggSnapshot")
    if transportOk and type(snapshot) == "table" then
        self.LastAreaSnapshot = snapshot
        self.LastAreaRefreshAt = os.clock()
        return snapshot
    end
    return self.LastAreaSnapshot
end

function State:getLiveAreaEggModels()
    local container = Workspace:FindFirstChild("AreaEggSlotsClient")
    local models = {}
    if not container then
        return models
    end
    for _, model in ipairs(container:GetChildren()) do
        if model:IsA("Model") or model:IsA("BasePart") then
            models[tostring(model.Name)] = model
        end
    end
    return models
end

function State:getLiveEggCFrame(model)
    if typeof(model) ~= "Instance" or not model.Parent then
        return nil
    end
    if model:IsA("BasePart") then
        return model.CFrame
    end
    local part = model:FindFirstChild("Hitbox")
        or model:FindFirstChild("CustomBoundingBox")
        or model:FindFirstChildWhichIsA("BasePart", true)
    if part and part:IsA("BasePart") then
        return part.CFrame
    end
    if model:IsA("Model") then
        return model:GetPivot()
    end
    return nil
end

function State:getAreaRecords(refresh)
    local eggConfig = type(self.Runtime) == "table" and self.Runtime.Config and self.Runtime.Config.Egg or nil
    local maxAge = refresh and clampFinite(eggConfig and eggConfig.SnapshotMaxAge, 0, 2, 0.08) or nil
    local snapshot = refresh and self:requestAreaSnapshot(maxAge or 0.08) or self.LastAreaSnapshot
    if not snapshot then
        snapshot = self:requestAreaSnapshot(maxAge or 0.25)
    end
    if type(snapshot) ~= "table" then
        return {}
    end
    local source = snapshot.Records or snapshot.records or snapshot
    local records = {}
    for key, record in pairs(source) do
        local uid = resolveRecordUid(record, key)
        if uid then
            local copy = shallowCopy(record)
            copy.Uid = uid
            records[#records + 1] = copy
        end
    end
    return records
end

function State:requestRuntimeSnapshot(maxAge)
    local now = os.clock()
    if snapshotCacheDecision(self.LastRuntimeSnapshot ~= nil, self.LastRuntimeRefreshAt, now, maxAge) == "cache" then
        return self.LastRuntimeSnapshot
    end
    local transportOk, snapshot = self.Broker:call("EggRuntimeSnapshot")
    if transportOk and type(snapshot) == "table" then
        self.LastRuntimeSnapshot = snapshot
        self.LastRuntimeRefreshAt = os.clock()
        return snapshot
    end
    local eggCmds = self.Modules.EggCmds
    if type(eggCmds) == "table" and type(eggCmds.GetRuntimeSnapshot) == "function" then
        local ok, cached = pcall(eggCmds.GetRuntimeSnapshot)
        if ok and type(cached) == "table" then
            self.LastRuntimeSnapshot = cached
            self.LastRuntimeRefreshAt = os.clock()
            return cached
        end
    end
    return self.LastRuntimeSnapshot or {}
end

function State:assetConfig(category)
    local directory = self.Modules.Assets
    if type(directory) ~= "table" then
        return {}
    end
    local candidates = {directory.Directory, directory.Assets, directory}
    for _, container in ipairs(candidates) do
        if type(container) == "table" and type(container[category]) == "table" then
            return container[category]
        end
    end
    if type(directory.Get) == "function" then
        local ok, value = pcall(directory.Get, category)
        if ok and type(value) == "table" then
            return value
        end
    end
    return {}
end

function State:mutationInfo(record)
    local mutations = type(record.Mutations) == "table" and record.Mutations or {}
    local mutationCount = countTable(mutations)
    local multiplier = 1
    local module = self.Modules.Mutations
    if type(module) == "table" and type(module.GetTotalMutationsEarningMulti) == "function" then
        local ok, value = pcall(module.GetTotalMutationsEarningMulti, mutations)
        if ok and tonumber(value) then
            multiplier = math.max(1, tonumber(value))
        end
    else
        multiplier = 1 + mutationCount * 0.5
    end
    return mutationCount, multiplier
end

function State:eggCandidates(selectedAreas, minimumRarity, refresh)
    local areaSet = buildTargetAreaSet(selectedAreas or ALL_AREAS)
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local origin = root and root.Position or Vector3.zero
    local candidates = {}
    local liveModels = self:getLiveAreaEggModels()
    local hasLiveModels = next(liveModels) ~= nil
    local matchedLiveModels = {}
    local recordByUid = {}
    for _, record in ipairs(self:getAreaRecords(refresh)) do
        recordByUid[tostring(record.Uid)] = record
        local liveModel = liveModels[tostring(record.Uid)]
        local liveCFrame = self:getLiveEggCFrame(liveModel)
        local liveState = record.State == "Slot" or record.State == "Dropped"
        if liveState and areaSet[record.AreaId] and (not hasLiveModels or liveCFrame ~= nil) then
            if liveModel then
                matchedLiveModels[liveModel] = true
            end
            local config = self:assetConfig(record.AssetCategory)
            local rarityData = type(config.Rarity) == "table" and config.Rarity or {}
            local rarity = tonumber(rarityData.RarityNumber or config.RarityNumber) or 0
            if rarity >= (tonumber(minimumRarity) or 0) then
                local mutationCount, mutationMultiplier = self:mutationInfo(record)
                local assetScale = tonumber(record.AssetScale) or 0
                local weightKg = 0
                local sellValue = 0
                local eggItemUtil = self.Modules.EggItemUtil
                if type(eggItemUtil) == "table" then
                    if type(eggItemUtil.GetWeightKgForScale) == "function" then
                        local weightOk, value = pcall(eggItemUtil.GetWeightKgForScale, record.AssetCategory, assetScale)
                        if weightOk and tonumber(value) then
                            weightKg = math.max(0, tonumber(value))
                        end
                    end
                    if type(eggItemUtil.GetSellPrice) == "function" then
                        local valueOk, value = pcall(eggItemUtil.GetSellPrice, record)
                        if valueOk and tonumber(value) then
                            sellValue = math.max(0, tonumber(value))
                        end
                    end
                end
                local cframe = liveCFrame or record.BottomCFrame or record.BoundsCFrame
                local position = typeof(cframe) == "CFrame" and cframe.Position or origin
                candidates[#candidates + 1] = {
                    Uid = record.Uid,
                    Record = record,
                    Category = record.AssetCategory,
                    AreaId = record.AreaId,
                    NestId = record.NestId,
                    RarityNumber = rarity,
                    RarityName = rarityData.DisplayName or config.RarityName or "Unknown",
                    EarningRate = tonumber(config.EarningRate) or 0,
                    SellValue = sellValue,
                    WeightKg = weightKg,
                    AssetScale = assetScale,
                    VisualOdds = tonumber(config.VisualOdds) or 1e18,
                    AreaTier = AREA_ORDER[record.AreaId] or 0,
                    MutationCount = mutationCount,
                    MutationMultiplier = mutationMultiplier,
                    Distance = (position - origin).Magnitude,
                    Position = position,
                    LiveModel = liveModel,
                    LiveCFrame = liveCFrame,
                }
            end
        end
    end

    if hasLiveModels then
        for uid, liveModel in pairs(liveModels) do
            if not matchedLiveModels[liveModel] then
                local liveCFrame = self:getLiveEggCFrame(liveModel)
                local knownRecord = recordByUid[uid]
                local areaId = (knownRecord and knownRecord.AreaId)
                    or liveModel:GetAttribute("AreaId")
                    or liveModel:GetAttribute("AreaID")
                local category = (knownRecord and knownRecord.AssetCategory)
                    or liveModel:GetAttribute("AssetCategory")
                    or liveModel:GetAttribute("Category")
                if liveCFrame and ((areaId and areaSet[tostring(areaId)]) or not areaId) then
                    local record = shallowCopy(knownRecord)
                    record.Uid = uid
                    record.State = "Slot"
                    record.AreaId = areaId
                    record.NestId = record.NestId
                        or liveModel:GetAttribute("NestId")
                        or liveModel:GetAttribute("NestID")
                    record.AssetCategory = category
                    record.BottomCFrame = liveCFrame
                    candidates[#candidates + 1] = {
                        Uid = uid,
                        Record = record,
                        Category = category or "Visible Egg",
                        AreaId = areaId or "Visible",
                        NestId = record.NestId,
                        RarityNumber = 0,
                        RarityName = "Unknown",
                        EarningRate = 0,
                        SellValue = 0,
                        WeightKg = 0,
                        AssetScale = 0,
                        VisualOdds = 1e18,
                        AreaTier = AREA_ORDER[tostring(areaId)] or 0,
                        MutationCount = 0,
                        MutationMultiplier = 1,
                        Distance = (liveCFrame.Position - origin).Magnitude,
                        Position = liveCFrame.Position,
                        LiveModel = liveModel,
                        LiveCFrame = liveCFrame,
                        SnapshotMissing = true,
                    }
                end
            end
        end
    end
    return candidates
end

function State:buildSlotKey(record)
    if type(record) ~= "table" or type(record.Uid) ~= "string" then
        return nil
    end
    local identity = self.Modules.AreaEggSlotIdentity
    local firstAreaUid = string.find(record.Uid, "FirstAreaEgg_", 1, true) ~= nil
    if type(identity) == "table" and type(identity.IsFirstAreaUid) == "function" then
        local ok, value = pcall(identity.IsFirstAreaUid, record.Uid)
        firstAreaUid = ok and value == true
    end
    if not firstAreaUid then
        return nil
    end
    if type(identity) == "table" and type(identity.BuildSlotKey) == "function" then
        local ok, value = pcall(identity.BuildSlotKey, record.AreaId, record.NestId)
        if ok then
            return value
        end
    end
    if record.AreaId and record.NestId then
        return tostring(record.AreaId) .. ":" .. tostring(record.NestId)
    end
    return nil
end

function State:deserializeInventoryEntry(raw, key)
    local value = raw
    local serializer = self.Modules.Serialization
    if type(serializer) == "table" and type(serializer.Deserialize) == "function" then
        local ok, decoded = pcall(serializer.Deserialize, raw)
        if ok and type(decoded) == "table" then
            value = decoded
        end
    end
    if type(value) ~= "table" then
        value = {Value = value}
    else
        value = shallowCopy(value)
    end
    value.Uid = value.Uid or value.uid or value._uid or value.Id or (type(key) == "string" and key or nil)
    value.Category = value.Category or value.AssetCategory or value.Id or value.AssetId
    return value
end

function State:getInventory()
    local save = self:getSave()
    local source = type(save.Inventory) == "table" and save.Inventory or {}
    local equippedSet = {}
    for key, value in pairs(type(save.EquippedAssets) == "table" and save.EquippedAssets or {}) do
        local uid = type(value) == "table" and (value.Uid or value.uid) or value
        if type(key) == "string" and value == true then
            uid = key
        end
        if uid then
            equippedSet[tostring(uid)] = true
        end
    end

    local items = {}
    for key, raw in pairs(source) do
        local item = self:deserializeInventoryEntry(raw, key)
        if item.Uid then
            local config = self:assetConfig(item.Category)
            local rarityData = type(config.Rarity) == "table" and config.Rarity or {}
            local mutationCount, mutationMultiplier = self:mutationInfo(item)
            item.RarityNumber = tonumber(rarityData.RarityNumber or config.RarityNumber) or 0
            item.MutationCount = mutationCount
            item.MutationMultiplier = mutationMultiplier
            item.IsFavorite = item.IsFavorite == true or item.Favorite == true
            item.IsEquipped = equippedSet[tostring(item.Uid)] == true
            item.CannotFuse = item.CannotFuse == true or config.CannotFuse == true
            item.InFuse = item.InFuse == true
            item.Scale = tonumber(item.Scale) or 0
            item.WeightKg = math.max(0, tonumber(item.WeightKg) or 0)
            local assetItemUtil = self.Modules.AssetItemUtil
            if type(assetItemUtil) == "table" and type(assetItemUtil.GetVisualWeightKg) == "function" then
                local weightOk, weight = pcall(assetItemUtil.GetVisualWeightKg, item)
                if weightOk and tonumber(weight) then
                    item.WeightKg = math.max(0, tonumber(weight))
                end
            end
            item.Value = (tonumber(config.EarningRate) or 0) * mutationMultiplier
            items[#items + 1] = item
        end
    end
    return items
end

function State:getEggInventory()
    local save = self:getSave()
    local source = type(save.EggInventory) == "table" and save.EggInventory or {}
    local eggs = {}
    for key, raw in pairs(source) do
        local egg = type(raw) == "table" and shallowCopy(raw) or {Value = raw}
        egg.Uid = resolveRecordUid(egg, key)
        if egg.Uid then
            eggs[#eggs + 1] = egg
        end
    end
    table.sort(eggs, function(left, right)
        return tostring(left.Uid) < tostring(right.Uid)
    end)
    return eggs
end

function State:getPlacedEggRecords(refresh)
    local inventoryRecords = collectPlacedEggRecords(self:getEggInventory())
    if #inventoryRecords > 0 then
        return inventoryRecords
    end
    local snapshot = refresh and self:requestRuntimeSnapshot(0.15) or self.LastRuntimeSnapshot
    if not snapshot then
        snapshot = self:requestRuntimeSnapshot()
    end
    local source = {}
    if type(snapshot) == "table" then
        if type(snapshot.Records) == "table" then
            source = snapshot.Records
        elseif type(snapshot.records) == "table" then
            source = snapshot.records
        else
            for _, ownerSnapshot in pairs(snapshot) do
                if type(ownerSnapshot) == "table"
                    and tonumber(ownerSnapshot.OwnerUserId or ownerSnapshot.UserId) == LocalPlayer.UserId
                    and type(ownerSnapshot.Records or ownerSnapshot.records) == "table" then
                    source = ownerSnapshot.Records or ownerSnapshot.records
                    break
                end
            end
        end
    end
    return collectPlacedEggRecords(source)
end

function State:getPlotData()
    local plotCmds = self.Modules.PlotCmds
    if type(plotCmds) ~= "table" or type(plotCmds.GetPlotData) ~= "function" then
        return nil
    end
    for _, arguments in ipairs({{}, {LocalPlayer}}) do
        local ok, value = pcall(plotCmds.GetPlotData, table.unpack(arguments))
        if ok and (type(value) == "table" or typeof(value) == "Instance") then
            return value
        end
    end
    return nil
end

function State:getPlotModel()
    local plotData = self:getPlotData()
    if typeof(plotData) == "Instance" then
        return plotData
    elseif type(plotData) == "table" then
        for _, nested in pairs(plotData) do
            if typeof(nested) == "Instance" and nested:IsA("Model") then
                return nested
            end
        end
    end

    local plotCmds = self.Modules.PlotCmds
    local slot
    if type(plotCmds) == "table" and type(plotCmds.GetMySlot) == "function" then
        local ok, value = pcall(plotCmds.GetMySlot)
        if ok then
            slot = value
        end
    end
    local plotsRoot = Workspace:FindFirstChild("Plots", true)
    if plotsRoot then
        for _, model in ipairs(plotsRoot:GetChildren()) do
            if model:IsA("Model") then
                local ownerId = model:GetAttribute("OwnerUserId") or model:GetAttribute("UserId")
                if ownerId == LocalPlayer.UserId or (slot and string.find(model.Name, tostring(slot), 1, true)) then
                    return model
                end
            end
        end
    end
    return nil
end

function State:getPlotCenter()
    local plotData = self:getPlotData()
    local directCenter = type(plotData) == "table" and plotData.CenterPoint or nil
    if typeof(directCenter) == "Instance" and directCenter:IsA("BasePart") then
        return directCenter.CFrame, directCenter
    end
    local plot = self:getPlotModel()
    local center = plot and plot:FindFirstChild("CenterPoint", true)
    if center and center:IsA("BasePart") then
        return center.CFrame, center
    end
    local plotCmds = self.Modules.PlotCmds
    if type(plotCmds) == "table" and type(plotCmds.GetRespawnPointCFrame) == "function" then
        local ok, value = pcall(plotCmds.GetRespawnPointCFrame)
        if ok and typeof(value) == "CFrame" then
            return value, nil
        end
    end
    return nil, nil
end

function State:getPlacementLocalCFrames(spacing)
    spacing = math.max(3, tonumber(spacing) or 6)
    local plotData = self:getPlotData()
    local petArea = type(plotData) == "table" and plotData.PetArea or nil
    local center = type(plotData) == "table" and plotData.CenterPoint or nil
    if typeof(petArea) == "Instance" and petArea:IsA("BasePart")
        and typeof(center) == "Instance" and center:IsA("BasePart") then
        local frames = {}
        local halfX = math.max(0, petArea.Size.X * 0.5 - 5)
        local halfZ = math.max(0, petArea.Size.Z * 0.5 - 5)
        for x = -halfX, halfX, spacing do
            for z = -halfZ, halfZ, spacing do
                local world = petArea.CFrame:PointToWorldSpace(Vector3.new(x, 1, z))
                frames[#frames + 1] = center.CFrame:ToObjectSpace(CFrame.new(world))
            end
        end
        if #frames > 0 then
            return frames
        end
    end

    local centerCFrame = self:getPlotCenter()
    if typeof(centerCFrame) ~= "CFrame" then
        return {}
    end
    local columns = math.max(1, math.floor(tonumber(self.Runtime.Config.Egg.PlacementColumns) or 3))
    local frames = {}
    for index = 1, columns * 8 do
        local x, z = buildPlacementOffset(index, columns, spacing)
        frames[#frames + 1] = CFrame.new(x, 0, z)
    end
    return frames
end

function State:getPlotSpawnCFrame()
    local plotCmds = self.Modules.PlotCmds
    if type(plotCmds) == "table" and type(plotCmds.GetRespawnPointCFrame) == "function" then
        local ok, value = pcall(plotCmds.GetRespawnPointCFrame)
        if ok and typeof(value) == "CFrame" then
            return value
        end
    end
    local plot = self:getPlotModel()
    local spawnPoint = plot and plot:FindFirstChild("SpawnPoint", true)
    if spawnPoint and spawnPoint:IsA("BasePart") then
        return spawnPoint.CFrame
    end
    return self:getPlotCenter()
end

function State:getNextTreadmillConfig()
    local save = self:getSave()
    local nextLevel = (tonumber(save.TreadmillUpgradeLevel) or 0) + 1
    local directory = self.Modules.Treadmills
    if type(directory) ~= "table" then
        return nil
    end
    if type(directory.GetByUpgradeLevel) == "function" then
        local ok, value = pcall(directory.GetByUpgradeLevel, nextLevel)
        if ok and type(value) == "table" then
            return value
        end
    end
    for _, container in ipairs({directory.Directory, directory.TREADMILLS, directory}) do
        if type(container) == "table" then
            local value = container[nextLevel] or container[tostring(nextLevel)]
            if type(value) == "table" then
                return value
            end
        end
    end
    return nil
end

function State:getNextBaseConfig()
    local save = self:getSave()
    local nextLevel = (tonumber(save.BaseUpgradeLevel) or 0) + 1
    local directory = self.Modules.Bases
    if type(directory) ~= "table" then
        return nil
    end
    for _, container in ipairs({directory.BASES, directory.Directory, directory}) do
        if type(container) == "table" then
            local value = container[nextLevel] or container[tostring(nextLevel)]
            if type(value) == "table" then
                return value
            end
        end
    end
    return nil
end

function State:getTreadmillStandCFrame()
    local plotCmds = self.Modules.PlotCmds
    local registry = self.Modules.RuntimeInstanceRegistry
    if type(plotCmds) ~= "table" or type(plotCmds.GetMySlot) ~= "function" then
        return nil, "Local plot slot unavailable"
    end
    local slotOk, slot = pcall(plotCmds.GetMySlot)
    if not slotOk or slot == nil then
        return nil, "Local plot slot unavailable"
    end
    local model
    if type(registry) == "table" and type(registry.Get) == "function" then
        local getOk, value = pcall(registry.Get, "TreadmillPlotRender", tostring(slot))
        if getOk and typeof(value) == "Instance" then
            model = value
        end
    end
    if not model then
        local renders = Workspace:FindFirstChild("__ClientTreadmillRenders")
        model = renders and renders:FindFirstChild("TreadmillRender_" .. tostring(slot))
    end
    local treadmillRoot = model and model:FindFirstChild("Root", true)
    if not treadmillRoot or not treadmillRoot:IsA("BasePart") then
        return nil, "Local treadmill render unavailable"
    end
    return treadmillRoot.CFrame + Vector3.new(0, 3.2, 0)
end

function State:getTreadmillObstaclePositions()
    local positions = {}
    local seen = {}
    local function add(position)
        if typeof(position) ~= "Vector3" then
            return
        end
        local key = string.format("%.1f:%.1f", position.X, position.Z)
        if seen[key] then
            return
        end
        seen[key] = true
        positions[#positions + 1] = position
    end

    local standCFrame = self:getTreadmillStandCFrame()
    if typeof(standCFrame) == "CFrame" then
        add(standCFrame.Position)
    end

    local plots = Workspace:FindFirstChild("Plots", true)
    if plots then
        for _, descendant in ipairs(plots:GetDescendants()) do
            if descendant:IsA("BasePart") and descendant.Name == "TreadmillBottom" then
                add(descendant.Position)
            end
        end
    end
    return positions
end

function State:summary()
    local save = self:getSave()
    return {
        Money = save.Money or save.Coins or 0,
        SpeedPower = save.SpeedPower or 0,
        Rebirth = save.Rebirth or save.Rebirths or 0,
        BaseUpgradeLevel = save.BaseUpgradeLevel or 0,
        TreadmillUpgradeLevel = save.TreadmillUpgradeLevel or 0,
        EggInventory = #self:getEggInventory(),
        Inventory = #self:getInventory(),
        AreaEggs = #self:getAreaRecords(false),
    }
end

local state = State.new(runtime, resolver, broker)
runtime.State = state

local discoveredAreas = discoverAreaCatalog(state.Modules.Areas, nil, STATIC_AREAS)
table.clear(ALL_AREAS)
for index, areaId in ipairs(discoveredAreas) do
    ALL_AREAS[index] = areaId
    AREA_ORDER[areaId] = index
end

local originalAreaSet = buildTargetAreaSet(runtime.Config.Egg.SelectedAreas)
local selectedAreas = reconcileAreaSelection(
    runtime.Config.Egg.SelectedAreas,
    LEGACY_AREAS,
    PRE_TITAN_AREAS
)
selectedAreas = reconcileAreaSelection(selectedAreas, PRE_TITAN_AREAS, STATIC_AREAS)
selectedAreas = reconcileAreaSelection(selectedAreas, STATIC_AREAS, ALL_AREAS)
runtime.Config.Egg.SelectedAreas = selectedAreas
local updatedAreaSet = buildTargetAreaSet(selectedAreas)
local areaSelectionChanged = false
for areaId in pairs(originalAreaSet) do
    if not updatedAreaSet[areaId] then
        areaSelectionChanged = true
        break
    end
end
if not areaSelectionChanged then
    for areaId in pairs(updatedAreaSet) do
        if not originalAreaSet[areaId] then
            areaSelectionChanged = true
            break
        end
    end
end
if areaSelectionChanged then
    runtime:queueConfigSave()
end

local WorldSpawnPredictor = {}
WorldSpawnPredictor.__index = WorldSpawnPredictor

function WorldSpawnPredictor.new(owner, gameState, networkBroker)
    local self = setmetatable({
        Runtime = owner,
        State = gameState,
        Broker = networkBroker,
        Catalog = {},
        AreaCatalog = {},
        AreaSlotCounts = {},
        CategoryLookup = {},
        AreaLookup = {},
        CurrentSlots = nil,
        PendingSnapshot = nil,
        PendingModels = {},
        Learned = {
            SchemaVersion = 2,
            Observations = {},
            GlobalCounts = {},
            AreaCounts = {},
            Transitions = {},
            Cycles = {},
        },
        Container = nil,
        ContainerConnections = {},
        NextObserveAt = 0,
        NextForecastAt = 0,
        SaveGeneration = 0,
        ObservationBusy = false,
        DeepProbeBusy = false,
        LastReport = nil,
        LastText = "World spawn predictor is reading the replicated reset schedule.",
        LastCommittedSignature = nil,
        LastObservedAt = 0,
        LastCycleAt = nil,
        SessionObservationCount = 0,
        LastCountdown = nil,
        LastReveal = nil,
        LastSpawnBatch = nil,
        LastSignalError = nil,
        Luck = {
            ProductMultiplier = 1,
            AdminMultiplier = 1,
            EffectiveMultiplier = 1,
            UpdatedAt = -math.huge,
        },
    }, WorldSpawnPredictor)
    self.Cycle = gameState.Resolver:requirePath(
        "SharedAreaEggCycle",
        {"Shared", "Util", "AreaEggCycle"}
    )
    self.AssetLottery = gameState.Resolver:requirePath(
        "SharedAssetLottery",
        {"Shared", "Util", "AssetLottery"}
    )
    self.AdminBoosts = gameState.Resolver:requirePath(
        "SharedAdminBoosts",
        {"Shared", "Util", "AdminBoosts"}
    )
    self:_buildCatalog()
    self:_load()
    self:_bindContainer()
    self:_bindSignals()
    self:_refreshLuck(true)
    self:observePassive()
    return self
end

function WorldSpawnPredictor:_token(value)
    return string.lower(tostring(value or "")):gsub("[^%w]", "")
end

function WorldSpawnPredictor:_serverNow()
    local ok, value = pcall(Workspace.GetServerTimeNow, Workspace)
    if ok and tonumber(value) then
        return tonumber(value)
    end
    return os.time()
end

function WorldSpawnPredictor:_periodIndex(at)
    at = tonumber(at) or self:_serverNow()
    local cycle = self.Cycle
    if type(cycle) == "table" and type(cycle.PeriodIndexAt) == "function" then
        local ok, value = pcall(cycle.PeriodIndexAt, at)
        if ok and tonumber(value) then
            return math.floor(tonumber(value))
        end
    end
    return math.floor(at / 300)
end

function WorldSpawnPredictor:_setProductLuck(state)
    local multiplier = type(state) == "table" and tonumber(state.Multiplier) or nil
    if multiplier and multiplier == multiplier and multiplier >= 1 and multiplier < math.huge then
        self.Luck.ProductMultiplier = multiplier
    else
        self.Luck.ProductMultiplier = 1
    end
    self.Luck.EffectiveMultiplier = math.max(1, self.Luck.ProductMultiplier)
        * math.max(1, self.Luck.AdminMultiplier)
    self.Luck.UpdatedAt = os.clock()
    self.NextForecastAt = 0
end

function WorldSpawnPredictor:_readAdminLuck()
    local multiplier
    local adminBoosts = self.AdminBoosts
    if type(adminBoosts) == "table" and type(adminBoosts.ReadMultiplier) == "function" then
        local key = rawget(adminBoosts, "EGG_SPAWN_LUCK") or "EggSpawnLuck"
        local ok, value = pcall(adminBoosts.ReadMultiplier, key)
        if ok then multiplier = tonumber(value) end
    end
    if not multiplier then
        multiplier = tonumber(Workspace:GetAttribute("AdminBoost_EggSpawnLuck"))
    end
    if not multiplier or multiplier ~= multiplier or multiplier < 1 or multiplier == math.huge then
        multiplier = 1
    end
    self.Luck.AdminMultiplier = multiplier
    self.Luck.EffectiveMultiplier = math.max(1, self.Luck.ProductMultiplier)
        * math.max(1, self.Luck.AdminMultiplier)
    self.NextForecastAt = 0
    return multiplier
end

function WorldSpawnPredictor:_luckRemote(kind)
    local packages = ReplicatedStorage:FindFirstChild("Packages")
    local networking = packages and packages:FindFirstChild("Networking")
    return networking and networking:FindFirstChild(kind) or nil
end

function WorldSpawnPredictor:_refreshLuck(force)
    self:_readAdminLuck()
    if not force and os.clock() - (tonumber(self.Luck.UpdatedAt) or -math.huge) < 60 then
        return self.Luck
    end
    local remote = self:_luckRemote("RF/LuckWindow/FetchState")
    if remote and remote:IsA("RemoteFunction") then
        local ok, state = pcall(remote.InvokeServer, remote)
        if ok then
            self:_setProductLuck(state)
        else
            self.LastSignalError = "Server luck fetch: " .. tostring(state)
            self.Luck.UpdatedAt = os.clock()
        end
    else
        self.Luck.UpdatedAt = os.clock()
    end
    return self.Luck
end

function WorldSpawnPredictor:_captureSnapshot(snapshot, fromSignal)
    if type(snapshot) ~= "table" then
        return false
    end
    if fromSignal then
        self.PendingSnapshot = snapshot
    end
    local records = self:_recordMap(snapshot)
    local recordCount = 0
    local areas = {}
    local ordered = {}
    for _, record in pairs(records) do
        recordCount += 1
        ordered[#ordered + 1] = record
        if record.AreaId then
            areas[record.AreaId] = true
            local slotCount = tonumber(self.AreaSlotCounts[record.AreaId]) or 0
            local nestNumber = tonumber(tostring(record.NestId or ""):match("(%d+)$"))
            self.AreaSlotCounts[record.AreaId] = math.max(slotCount, nestNumber or 1)
        end
    end
    table.sort(ordered, function(left, right)
        if tostring(left.AreaId) ~= tostring(right.AreaId) then
            return tostring(left.AreaId) < tostring(right.AreaId)
        end
        return tostring(left.NestId) < tostring(right.NestId)
    end)
    local areaCount = countTable(areas)
    local serverAt = tonumber(snapshot.ServerTime) or self:_serverNow()
    local periodIndex = self:_periodIndex(serverAt)
    local fullWorld = recordCount >= math.max(20, #ALL_AREAS * 3)
        and areaCount >= math.max(2, #ALL_AREAS - 2)
    if fullWorld then
        local isNewPeriod = not self.LastSpawnBatch or self.LastSpawnBatch.PeriodIndex ~= periodIndex
        if not self.LastSpawnBatch or (fromSignal and isNewPeriod) then
            self.LastSpawnBatch = {
                PeriodIndex = periodIndex,
                ServerAt = serverAt,
                RecordCount = recordCount,
                AreaCount = areaCount,
                Records = ordered,
                FromSignal = fromSignal == true,
            }
            if isNewPeriod and fromSignal and self.Runtime.Config.Predictor.NotifyCommitted == true then
                self.Runtime:notify(
                    "World Spawn Confirmed",
                    string.format("Server committed %d eggs across %d areas", recordCount, areaCount),
                    7
                )
            end
        end
    end
    if fromSignal then
        self.NextObserveAt = 0
        self.NextForecastAt = 0
    end
    return true
end

function WorldSpawnPredictor:_captureReveal(payload)
    if type(payload) ~= "table" then
        return false
    end
    local field = self:_recordMap(self:_passiveSnapshot())
    local exact = {}
    for _, reveal in ipairs(type(payload.RareSpawns) == "table" and payload.RareSpawns or {}) do
        if type(reveal) == "table" then
            local uid = tostring(reveal.EggUid or "")
            local record = field[uid]
            exact[#exact + 1] = {
                Uid = uid,
                Category = record and record.Category or nil,
                AreaId = record and record.AreaId or nil,
                RarityId = reveal.RarityId,
                Message = reveal.Message,
            }
        end
    end
    self.LastReveal = {
        PeriodIndex = tonumber(payload.PeriodIndex),
        DayStartsAt = tonumber(payload.DayStartsAt),
        RareSpawns = exact,
        ReceivedAt = self:_serverNow(),
    }
    self.NextForecastAt = 0
    return true
end

function WorldSpawnPredictor:_bindSignals()
    local eggState = self.State.Modules.EggState
    if type(eggState) ~= "table" then
        return false
    end
    local function connect(signal, callback)
        if type(signal) ~= "table" or type(signal.Connect) ~= "function" then
            return false
        end
        local ok, connection = pcall(signal.Connect, signal, callback)
        if not ok then
            self.LastSignalError = tostring(connection)
            return false
        end
        self.Runtime:track(connection)
        return true
    end
    connect(rawget(eggState, "ResetCountdown"), function(payload)
        if type(payload) == "table" and tonumber(payload.DayStartsAt) then
            self.LastCountdown = {
                DayStartsAt = tonumber(payload.DayStartsAt),
                ReceivedAt = self:_serverNow(),
            }
            self.NextForecastAt = 0
        end
    end)
    connect(rawget(eggState, "FieldRefreshed"), function(snapshot)
        self:_captureSnapshot(snapshot, true)
    end)
    connect(rawget(eggState, "RarityRevealed"), function(payload)
        self:_captureReveal(payload)
    end)

    local luckEvent = self:_luckRemote("RE/LuckWindow/StateRefreshed")
    if luckEvent and luckEvent:IsA("RemoteEvent") then
        self.Runtime:track(luckEvent.OnClientEvent:Connect(function(state)
            self:_setProductLuck(state)
        end))
    end
    self.Runtime:track(Workspace:GetAttributeChangedSignal("AdminBoost_EggSpawnLuck"):Connect(function()
        self:_readAdminLuck()
    end))

    local fetchReveal = rawget(eggState, "FetchRarityShows")
    if type(fetchReveal) == "function" then
        task.spawn(function()
            local ok, ready, payload = pcall(fetchReveal)
            if ok and ready == true and type(payload) == "table" then
                self:_captureReveal(payload)
            end
        end)
    end
    return true
end

function WorldSpawnPredictor:_canonicalCategory(value)
    if type(value) ~= "string" then
        return nil
    end
    return self.CategoryLookup[self:_token(value)]
end

function WorldSpawnPredictor:_canonicalArea(value)
    if type(value) ~= "string" then
        return nil
    end
    return self.AreaLookup[self:_token(value)]
end

function WorldSpawnPredictor:_buildCatalog()
    table.clear(self.Catalog)
    table.clear(self.AreaCatalog)
    table.clear(self.AreaSlotCounts)
    table.clear(self.CategoryLookup)
    table.clear(self.AreaLookup)
    for _, areaId in ipairs(ALL_AREAS) do
        self.AreaLookup[self:_token(areaId)] = areaId
        self.AreaSlotCounts[areaId] = 5
    end

    local directory = self.State.Modules.Assets
    local source = type(directory) == "table"
        and (rawget(directory, "Directory") or rawget(directory, "Assets") or directory)
        or {}
    for key, config in pairs(source) do
        if type(config) == "table" then
            local category = rawget(config, "_id")
                or rawget(config, "AssetCategory")
                or rawget(config, "Category")
                or rawget(config, "Id")
                or (type(key) == "string" and key or nil)
            if type(category) == "string" and category ~= "" then
                local rarityData = type(rawget(config, "Rarity")) == "table" and rawget(config, "Rarity") or {}
                local rarity = tonumber(rawget(rarityData, "RarityNumber") or rawget(config, "RarityNumber")) or 0
                local entry = {
                    Category = category,
                    DisplayName = tostring(rawget(config, "DisplayName") or category),
                    Rarity = rarity,
                    VisualOdds = tonumber(rawget(config, "VisualOdds")),
                    AreaWeights = {},
                    Areas = {},
                }
                self.Catalog[category] = entry
                self.CategoryLookup[self:_token(category)] = category
            end
        end
    end

    local areasModule = self.State.Modules.Areas
    local areasSource = type(areasModule) == "table"
        and (rawget(areasModule, "Directory") or rawget(areasModule, "Areas") or areasModule)
        or {}
    for areaKey, areaConfig in pairs(areasSource) do
        if type(areaConfig) == "table" then
            local area = self:_canonicalArea(
                rawget(areaConfig, "_id")
                or rawget(areaConfig, "AreaId")
                or rawget(areaConfig, "DisplayName")
                or areaKey
            )
            local dropTable = rawget(areaConfig, "DropTable")
            if area and type(dropTable) == "table" then
                local areaCatalog = {Entries = {}, TotalWeight = 0}
                for _, row in ipairs(dropTable) do
                    local rawCategory = type(row) == "table" and (row[1] or row.Category or row.AssetCategory) or nil
                    local weight = type(row) == "table" and tonumber(row[2] or row.Weight or row.Chance) or nil
                    local category = self:_canonicalCategory(rawCategory)
                    if not category and type(rawCategory) == "string" and rawCategory ~= "" then
                        category = rawCategory
                        self.CategoryLookup[self:_token(category)] = category
                        self.Catalog[category] = {
                            Category = category,
                            DisplayName = category,
                            Rarity = 0,
                            VisualOdds = nil,
                            AreaWeights = {},
                            Areas = {},
                        }
                    end
                    if category and weight and weight > 0 then
                        local entry = self.Catalog[category]
                        entry.Areas[area] = true
                        entry.AreaWeights[area] = weight
                        areaCatalog.TotalWeight += weight
                        areaCatalog.Entries[#areaCatalog.Entries + 1] = {
                            Category = category,
                            Weight = weight,
                        }
                    end
                end
                if #areaCatalog.Entries > 0 and areaCatalog.TotalWeight > 0 then
                    self.AreaCatalog[area] = areaCatalog
                end
            end
        end
    end
end

function WorldSpawnPredictor:_sanitizeLearned(decoded)
    if type(decoded) ~= "table" then
        return false
    end
    self.Learned.SchemaVersion = 2
    self.Learned.Observations = type(decoded.Observations) == "table" and decoded.Observations or {}
    self.Learned.GlobalCounts = type(decoded.GlobalCounts) == "table" and decoded.GlobalCounts or {}
    self.Learned.AreaCounts = type(decoded.AreaCounts) == "table" and decoded.AreaCounts or {}
    self.Learned.Transitions = type(decoded.Transitions) == "table" and decoded.Transitions or {}
    self.Learned.Cycles = type(decoded.Cycles) == "table" and decoded.Cycles or {}
    local limit = math.clamp(
        math.floor(tonumber(self.Runtime.Config.Predictor.HistoryLimit) or 600),
        100,
        2000
    )
    while #self.Learned.Observations > limit do
        table.remove(self.Learned.Observations, 1)
    end
    while #self.Learned.Cycles > 120 do
        table.remove(self.Learned.Cycles, 1)
    end
    return true
end

function WorldSpawnPredictor:_load()
    if type(isfile) ~= "function" or type(readfile) ~= "function" then
        return false
    end
    local existsOk, exists = pcall(isfile, PREDICTOR_STATE_PATH)
    if not existsOk or not exists then
        return false
    end
    local readOk, body = pcall(readfile, PREDICTOR_STATE_PATH)
    if not readOk or type(body) ~= "string" then
        return false
    end
    local decodeOk, decoded = pcall(HttpService.JSONDecode, HttpService, body)
    return decodeOk and self:_sanitizeLearned(decoded) or false
end

function WorldSpawnPredictor:_saveNow()
    if type(writefile) ~= "function" then
        return false, "Executor file write API unavailable"
    end
    ensureConfigFolder()
    local encodeOk, body = pcall(HttpService.JSONEncode, HttpService, self.Learned)
    if not encodeOk then
        return false, tostring(body)
    end
    local writeOk, reason = pcall(writefile, PREDICTOR_STATE_PATH, body)
    if not writeOk then
        return false, tostring(reason)
    end
    return true, nil
end

function WorldSpawnPredictor:_queueSave()
    self.SaveGeneration += 1
    local generation = self.SaveGeneration
    task.delay(0.75, function()
        if self.Runtime:isCurrent() and generation == self.SaveGeneration then
            self:_saveNow()
        end
    end)
end

function WorldSpawnPredictor:resetHistory()
    self.Learned = {
        SchemaVersion = 2,
        Observations = {},
        GlobalCounts = {},
        AreaCounts = {},
        Transitions = {},
        Cycles = {},
    }
    self.CurrentSlots = nil
    self.LastCycleAt = nil
    self.SessionObservationCount = 0
    self.LastReport = nil
    self.LastText = "Prediction history cleared; learning a new server baseline."
    return self:_saveNow()
end

function WorldSpawnPredictor:_disconnectContainer()
    for _, connection in ipairs(self.ContainerConnections) do
        pcall(function() connection:Disconnect() end)
    end
    table.clear(self.ContainerConnections)
    self.Container = nil
end

function WorldSpawnPredictor:_bindContainer()
    local container = Workspace:FindFirstChild("AreaEggSlotsClient")
    if container == self.Container and container and container.Parent then
        return true
    end
    self:_disconnectContainer()
    if not container then
        return false
    end
    self.Container = container
    local added = container.ChildAdded:Connect(function(child)
        if child:IsA("Model") or child:IsA("BasePart") then
            self.PendingModels[tostring(child.Name)] = {
                At = self:_serverNow(),
                Model = child,
            }
            self.NextObserveAt = 0
        end
    end)
    local removed = container.ChildRemoved:Connect(function(child)
        local uid = tostring(child.Name)
        self.PendingModels[uid] = nil
        self.NextObserveAt = 0
    end)
    self.ContainerConnections = {added, removed}
    self.Runtime:track(added)
    self.Runtime:track(removed)
    return true
end

function WorldSpawnPredictor:_passiveSnapshot()
    local eggState = self.State.Modules.EggState
    local callback = type(eggState) == "table" and (
        rawget(eggState, "ReadFieldEggs")
        or rawget(eggState, "GetAreaEggSnapshot")
    ) or nil
    if type(callback) ~= "function" then
        local eggCmds = self.State.Modules.EggCmds
        callback = type(eggCmds) == "table" and rawget(eggCmds, "GetAreaEggSnapshot") or nil
    end
    if type(callback) == "function" then
        local ok, snapshot = pcall(callback)
        if ok and type(snapshot) == "table" then
            return snapshot
        end
    end
    return self.State.LastAreaSnapshot
end

function WorldSpawnPredictor:_recordMap(snapshot)
    local result = {}
    local source = type(snapshot) == "table" and (snapshot.Records or snapshot.records or snapshot) or {}
    for key, record in pairs(source) do
        if type(record) == "table" then
            local uid = resolveRecordUid(record, key)
            local stateName = tostring(rawget(record, "State") or "")
            if uid and (stateName == "Slot" or stateName == "Spawned" or stateName == "Available") then
                local category = self:_canonicalCategory(
                    rawget(record, "AssetCategory")
                    or rawget(record, "EggCategory")
                    or rawget(record, "Category")
                )
                local area = self:_canonicalArea(
                    rawget(record, "AreaId")
                    or rawget(record, "AreaID")
                    or rawget(record, "Area")
                    or rawget(record, "Biome")
                )
                local spawnToken = rawget(record, "SpawnSequence")
                    or rawget(record, "SpawnId")
                    or rawget(record, "SpawnedAt")
                    or rawget(record, "CreatedAt")
                    or ""
                result[tostring(uid)] = {
                    Uid = tostring(uid),
                    Category = category,
                    AreaId = area,
                    NestId = rawget(record, "NestId") or rawget(record, "NestID"),
                    Signature = table.concat({
                        tostring(category or ""),
                        tostring(area or ""),
                        tostring(rawget(record, "NestId") or rawget(record, "NestID") or ""),
                        tostring(spawnToken),
                    }, "|"),
                    Record = record,
                }
            end
        end
    end
    return result
end

function WorldSpawnPredictor:_modelRecord(uid, pending)
    local model = pending and pending.Model
    if typeof(model) ~= "Instance" or not model.Parent then
        return nil
    end
    local category = self:_canonicalCategory(
        model:GetAttribute("AssetCategory")
        or model:GetAttribute("EggCategory")
        or model:GetAttribute("Category")
    )
    local area = self:_canonicalArea(
        model:GetAttribute("AreaId")
        or model:GetAttribute("AreaID")
        or model:GetAttribute("Area")
        or model:GetAttribute("Biome")
    )
    if not category then
        return nil
    end
    return {
        Uid = tostring(uid),
        Category = category,
        AreaId = area,
        NestId = model:GetAttribute("NestId") or model:GetAttribute("NestID"),
        Signature = table.concat({category, tostring(area or ""), tostring(uid)}, "|"),
    }
end

function WorldSpawnPredictor:_addObservation(event, at)
    local category = event.Category
    if not category then
        return false
    end
    local area = event.AreaId or "Unknown"
    local observation = {
        Category = category,
        AreaId = area,
        NestId = event.NestId,
        At = os.time(),
        ServerAt = at,
        JobId = game.JobId,
        LuckMultiplier = tonumber(self.Luck.EffectiveMultiplier) or 1,
    }
    local history = self.Learned.Observations
    local previous = history[#history]
    history[#history + 1] = observation
    self.Learned.GlobalCounts[category] = math.max(
        0,
        tonumber(self.Learned.GlobalCounts[category]) or 0
    ) + 1
    local areaCounts = self.Learned.AreaCounts[area]
    if type(areaCounts) ~= "table" then
        areaCounts = {}
        self.Learned.AreaCounts[area] = areaCounts
    end
    areaCounts[category] = math.max(0, tonumber(areaCounts[category]) or 0) + 1

    if type(previous) == "table"
        and previous.JobId == game.JobId
        and tonumber(previous.ServerAt)
        and at - tonumber(previous.ServerAt) >= 0
        and at - tonumber(previous.ServerAt) <= 900 then
        local from = tostring(previous.Category or "")
        if from ~= "" then
            local transitions = self.Learned.Transitions[from]
            if type(transitions) ~= "table" then
                transitions = {}
                self.Learned.Transitions[from] = transitions
            end
            transitions[category] = math.max(0, tonumber(transitions[category]) or 0) + 1
        end
    end

    local limit = math.clamp(
        math.floor(tonumber(self.Runtime.Config.Predictor.HistoryLimit) or 600),
        100,
        2000
    )
    while #history > limit do
        table.remove(history, 1)
    end
    self.SessionObservationCount += 1
    return true
end

function WorldSpawnPredictor:_recordCycle(events, at)
    local rare = false
    for _, event in ipairs(events) do
        local entry = event.Category and self.Catalog[event.Category]
        if entry and (tonumber(entry.Rarity) or 0) >= 5 then
            rare = true
            break
        end
    end
    if #events < 2 and not rare then
        return false
    end
    if self.LastCycleAt and at - self.LastCycleAt < 15 then
        return false
    end
    self.LastCycleAt = at
    self.Learned.Cycles[#self.Learned.Cycles + 1] = {
        ServerAt = at,
        At = os.time(),
        JobId = game.JobId,
        PeriodIndex = self:_periodIndex(at),
        LuckMultiplier = tonumber(self.Luck.EffectiveMultiplier) or 1,
        Count = #events,
        Rare = rare,
    }
    while #self.Learned.Cycles > 120 do
        table.remove(self.Learned.Cycles, 1)
    end
    return true
end

function WorldSpawnPredictor:observePassive()
    if self.ObservationBusy or self.Runtime.Destroyed then
        return false
    end
    self.ObservationBusy = true
    local ok, changedOrError = xpcall(function()
        self:_bindContainer()
        local snapshot = self.PendingSnapshot or self:_passiveSnapshot()
        self.PendingSnapshot = nil
        self:_captureSnapshot(snapshot, false)
        local current = self:_recordMap(snapshot)
        for uid, pending in pairs(self.PendingModels) do
            if not current[uid] then
                local record = self:_modelRecord(uid, pending)
                if record then current[uid] = record end
            end
        end
        if self.CurrentSlots == nil then
            self.CurrentSlots = current
            table.clear(self.PendingModels)
            self.LastObservedAt = self:_serverNow()
            return false
        end

        local events = {}
        local at = self:_serverNow()
        for uid, record in pairs(current) do
            local previous = self.CurrentSlots[uid]
            if record.Category and (
                previous == nil
                or previous.Signature ~= record.Signature
            ) then
                events[#events + 1] = record
            end
        end
        self.CurrentSlots = current
        table.clear(self.PendingModels)
        self.LastObservedAt = at
        if #events == 0 then
            return false
        end
        table.sort(events, function(left, right)
            return tostring(left.Uid) < tostring(right.Uid)
        end)
        local learned = false
        for _, event in ipairs(events) do
            learned = self:_addObservation(event, at) or learned
        end
        self:_recordCycle(events, at)
        if learned then self:_queueSave() end
        return learned
    end, debug.traceback)
    self.ObservationBusy = false
    if not ok then
        self.Runtime.LastError = tostring(changedOrError)
        return false
    end
    return changedOrError == true
end

function WorldSpawnPredictor:_isForwardPath(path)
    local token = self:_token(path)
    for _, marker in ipairs({
        "next", "upcoming", "queued", "queue", "pending", "future",
        "committed", "preselected", "prerolled", "preview",
    }) do
        if string.find(token, marker, 1, true) then
            return true
        end
    end
    return false
end

function WorldSpawnPredictor:_timeFromField(key, value, now)
    local number = tonumber(value)
    if not number then
        return nil
    end
    local token = self:_token(key)
    if string.find(token, "remaining", 1, true)
        or string.find(token, "countdown", 1, true)
        or string.find(token, "delay", 1, true)
        or string.find(token, "eta", 1, true) then
        if number >= 0 and number <= 7200 then
            return now + number
        end
    end
    if number >= now - 60 and number <= now + 86400 then
        return number
    end
    if number >= os.time() - 60 and number <= os.time() + 86400 then
        return now + (number - os.time())
    end
    return nil
end

function WorldSpawnPredictor:_contextMetadata(container, now)
    local area
    local at
    if type(container) ~= "table" then
        return area, at
    end
    for key, value in pairs(container) do
        local token = self:_token(key)
        if type(value) == "string" and (
            string.find(token, "area", 1, true)
            or string.find(token, "biome", 1, true)
            or string.find(token, "zone", 1, true)
            or string.find(token, "world", 1, true)
        ) then
            area = area or self:_canonicalArea(value)
        elseif type(value) == "number" and (
            string.find(token, "time", 1, true)
            or string.find(token, "at", 1, true)
            or string.find(token, "eta", 1, true)
            or string.find(token, "remaining", 1, true)
            or string.find(token, "countdown", 1, true)
        ) then
            at = at or self:_timeFromField(key, value, now)
        end
    end
    return area, at
end

function WorldSpawnPredictor:_scanMetadataTable(sourceName, source, basePriority, results)
    if type(source) ~= "table" then
        return
    end
    local seen = {}
    local nodes = 0
    local now = self:_serverNow()
    local function walk(value, path, depth)
        if type(value) ~= "table" or seen[value] or depth > 7 or nodes >= 7000 then
            return
        end
        seen[value] = true
        nodes += 1
        for key, child in pairs(value) do
            local keyText = tostring(key)
            local childPath = path == "" and keyText or (path .. "." .. keyText)
            local forward = self:_isForwardPath(childPath)
            local keyToken = self:_token(keyText)
            local category = self:_canonicalCategory(child)
            local categoryField = string.find(keyToken, "category", 1, true)
                or string.find(keyToken, "asset", 1, true)
                or string.find(keyToken, "egg", 1, true)
                or string.find(keyToken, "pet", 1, true)
                or keyToken == "name"
                or keyToken == "type"
            if forward and category and categoryField then
                local area, at = self:_contextMetadata(value, now)
                local priority = basePriority
                local pathToken = self:_token(childPath)
                local hardCommitted = string.find(pathToken, "committed", 1, true)
                    or string.find(pathToken, "prerolled", 1, true)
                    or string.find(pathToken, "preselected", 1, true)
                if hardCommitted then
                    priority += 20
                elseif string.find(pathToken, "queued", 1, true)
                    or string.find(pathToken, "pending", 1, true) then
                    priority += 14
                elseif string.find(pathToken, "next", 1, true) then
                    priority += 10
                end
                results[#results + 1] = {
                    Category = category,
                    AreaId = area,
                    At = at,
                    Source = sourceName .. "." .. childPath,
                    Priority = priority,
                    HardCommitted = hardCommitted ~= nil,
                }
            end
            if type(child) == "table" then
                walk(child, childPath, depth + 1)
            end
            if nodes >= 7000 then break end
        end
    end
    walk(source, "", 0)
end

function WorldSpawnPredictor:_moduleUpvalueSources(sources)
    local environment = (getgenv and getgenv()) or _G
    local nativeDebug = rawget(environment, "__FLOW_NATIVE_DEBUG")
        or rawget(environment, "debug")
        or debug
    if type(nativeDebug) ~= "table" or type(nativeDebug.getupvalues) ~= "function" then
        return
    end
    local function inspect(name, module)
        if type(module) ~= "table" then return end
        local functions = 0
        for key, callback in pairs(module) do
            if type(callback) == "function" then
                functions += 1
                if functions > 48 then break end
                local ok, upvalues = pcall(nativeDebug.getupvalues, callback)
                if ok and type(upvalues) == "table" then
                    for index, value in ipairs(upvalues) do
                        if index > 48 then break end
                        if type(value) == "table" then
                            sources[#sources + 1] = {
                                Name = string.format("%s.%s.upvalue%d", name, tostring(key), index),
                                Value = value,
                                Priority = 82,
                            }
                        end
                    end
                end
            end
        end
    end
    inspect("EggState", self.State.Modules.EggState)
    inspect("EggCmds", self.State.Modules.EggCmds)
end

function WorldSpawnPredictor:_instanceMetadataSources(sources)
    local visited = 0
    for _, root in ipairs({ReplicatedStorage, Workspace, Lighting}) do
        local rootAttributes = root:GetAttributes()
        if next(rootAttributes) then
            sources[#sources + 1] = {
                Name = root.Name .. ".Attributes",
                Value = rootAttributes,
                Priority = 88,
            }
        end
        for _, instance in ipairs(root:GetDescendants()) do
            visited += 1
            if visited > 12000 then return end
            local nameToken = self:_token(instance.Name)
            local relevant = string.find(nameToken, "egg", 1, true)
                or string.find(nameToken, "spawn", 1, true)
                or string.find(nameToken, "rare", 1, true)
                or string.find(nameToken, "rotation", 1, true)
                or string.find(nameToken, "cycle", 1, true)
            if relevant then
                local values = instance:GetAttributes()
                if instance:IsA("ValueBase") then
                    values.Value = instance.Value
                end
                if next(values) then
                    sources[#sources + 1] = {
                        Name = instance:GetFullName(),
                        Value = {[instance.Name] = values},
                        Priority = 92,
                    }
                end
            end
        end
    end
end

function WorldSpawnPredictor:_metadataCandidates(deep)
    local sources = {}
    local passive = self:_passiveSnapshot()
    if type(passive) == "table" then
        sources[#sources + 1] = {Name = "FieldEggSnapshot", Value = passive, Priority = 90}
    end
    local runtimeSnapshot = self.State.LastRuntimeSnapshot
    if deep then
        local refreshed = self.State:requestRuntimeSnapshot(0)
        if type(refreshed) == "table" then runtimeSnapshot = refreshed end
    end
    if type(runtimeSnapshot) == "table" and next(runtimeSnapshot) then
        sources[#sources + 1] = {Name = "EggRuntimeSnapshot", Value = runtimeSnapshot, Priority = 100}
    end
    if type(self.State.Modules.EggState) == "table" then
        sources[#sources + 1] = {Name = "EggState", Value = self.State.Modules.EggState, Priority = 84}
    end
    if deep then
        self:_moduleUpvalueSources(sources)
        self:_instanceMetadataSources(sources)
    end

    local results = {}
    for _, source in ipairs(sources) do
        self:_scanMetadataTable(source.Name, source.Value, source.Priority, results)
    end
    table.sort(results, function(left, right)
        if left.Priority ~= right.Priority then
            return left.Priority > right.Priority
        end
        return tostring(left.Source) < tostring(right.Source)
    end)
    return results, #sources
end

function WorldSpawnPredictor:_cycleEstimate(committed)
    local now = self:_serverNow()
    if committed and tonumber(committed.At) and committed.At >= now - 1 then
        return committed.At, 0, "replicated next-spawn timestamp"
    end
    local countdownAt = self.LastCountdown and tonumber(self.LastCountdown.DayStartsAt) or nil
    if countdownAt and countdownAt >= now - 0.5 and countdownAt <= now + 30 then
        return countdownAt, 0, "EggState.ResetCountdown.DayStartsAt"
    end
    local cycle = self.Cycle
    if type(cycle) == "table" then
        if type(cycle.IsRunning) == "function" then
            local runningOk, running = pcall(cycle.IsRunning)
            if runningOk and running == false then
                return nil, nil, "replicated AreaEggCycle is paused"
            end
        end
        if type(cycle.NextResetTime) == "function" then
            local nextOk, nextAt = pcall(cycle.NextResetTime, now)
            nextAt = nextOk and tonumber(nextAt) or nil
            if nextAt and nextAt >= now - 0.5 and nextAt <= now + 900 then
                return nextAt, 0, "replicated AreaEggCycle (exact 300s anchor)"
            end
        end
    end
    local times = {}
    for _, cycleRecord in ipairs(self.Learned.Cycles) do
        if type(cycleRecord) == "table"
            and cycleRecord.JobId == game.JobId
            and tonumber(cycleRecord.ServerAt) then
            times[#times + 1] = tonumber(cycleRecord.ServerAt)
        end
    end
    table.sort(times)
    local intervals = {}
    for index = 2, #times do
        local interval = times[index] - times[index - 1]
        if interval >= 30 and interval <= 900 then
            intervals[#intervals + 1] = interval
        end
    end
    table.sort(intervals)
    if #times == 0 then
        return nil, nil, "waiting for a replicated reset"
    end
    local period = #intervals > 0 and intervals[math.ceil(#intervals / 2)] or 300
    local deviations = {}
    for _, interval in ipairs(intervals) do
        deviations[#deviations + 1] = math.abs(interval - period)
    end
    table.sort(deviations)
    local uncertainty = #deviations > 0 and deviations[math.ceil(#deviations / 2)] or 45
    local nextAt = times[#times] + period
    while nextAt < now - 1 do
        nextAt += period
    end
    return nextAt, math.max(2, uncertainty), #intervals > 0 and "learned server cycle" or "five-minute fallback after one observed reset"
end

function WorldSpawnPredictor:_areaProbabilities(area, luckMultiplier)
    local areaCatalog = self.AreaCatalog[area]
    if type(areaCatalog) ~= "table" or type(areaCatalog.Entries) ~= "table"
        or (tonumber(areaCatalog.TotalWeight) or 0) <= 0 then
        return {}, 0, 0
    end
    local dropTable = {}
    for _, row in ipairs(areaCatalog.Entries) do
        dropTable[#dropTable + 1] = {
            row.Category,
            math.max(0, tonumber(row.Weight) or 0),
        }
    end

    luckMultiplier = math.max(1, tonumber(luckMultiplier) or 1)
    local rollCount = luckMultiplier
    local lottery = self.AssetLottery
    if type(lottery) == "table" and type(lottery.RollCountFor) == "function" then
        local ok, value = pcall(lottery.RollCountFor, 0, luckMultiplier)
        if ok and tonumber(value) then
            rollCount = math.max(1, tonumber(value))
        end
    end

    local probabilities = {}
    for _, row in ipairs(worldSpawnForecast(dropTable, rollCount, 1)) do
        probabilities[row.Category] = row.PerSlotChance
    end

    local samples = 0
    for _, observation in ipairs(self.Learned.Observations) do
        if type(observation) == "table" and observation.AreaId == area then
            local observedLuck = math.max(1, tonumber(observation.LuckMultiplier) or 1)
            local ratio = observedLuck / luckMultiplier
            if ratio >= 0.95 and ratio <= 1.05 and probabilities[observation.Category] then
                samples += 1
            end
        end
    end
    return probabilities, samples, 0
end

function WorldSpawnPredictor:_rank(area, limit)
    area = area ~= "All Areas" and self:_canonicalArea(area) or nil
    limit = math.clamp(math.floor(tonumber(limit) or 5), 1, 8)
    local selectedAreas = {}
    if area then
        selectedAreas[1] = area
    else
        for _, areaId in ipairs(ALL_AREAS) do
            if self.AreaCatalog[areaId] then selectedAreas[#selectedAreas + 1] = areaId end
        end
    end
    local byCategory = {}
    local calibrationSamples = 0
    local strongestBlend = 0
    local luckMultiplier = math.max(1, tonumber(self.Luck.EffectiveMultiplier) or 1)
    for _, areaId in ipairs(selectedAreas) do
        local probabilities, samples, blend = self:_areaProbabilities(areaId, luckMultiplier)
        calibrationSamples += samples
        strongestBlend = math.max(strongestBlend, blend)
        local slots = math.max(1, math.floor(tonumber(self.AreaSlotCounts[areaId]) or 5))
        for category, perSlot in pairs(probabilities) do
            local candidate = byCategory[category]
            if not candidate then
                local catalogEntry = self.Catalog[category] or {}
                candidate = {
                    Category = category,
                    DisplayName = catalogEntry.DisplayName or category,
                    Rarity = tonumber(catalogEntry.Rarity) or 0,
                    AreaId = area and areaId or nil,
                    Areas = {},
                    NoneProbability = 1,
                    ExpectedCount = 0,
                    PerSlotProbability = area and perSlot or nil,
                    SlotCount = area and slots or nil,
                }
                byCategory[category] = candidate
            end
            candidate.Areas[areaId] = true
            candidate.NoneProbability *= (1 - math.clamp(perSlot, 0, 1)) ^ slots
            candidate.ExpectedCount += perSlot * slots
        end
    end
    local candidates = {}
    for _, candidate in pairs(byCategory) do
        candidate.AppearanceProbability = 1 - candidate.NoneProbability
        candidate.Probability = candidate.AppearanceProbability
        candidate.Score = candidate.AppearanceProbability
        candidates[#candidates + 1] = candidate
    end
    table.sort(candidates, function(left, right)
        if left.Score ~= right.Score then return left.Score > right.Score end
        return left.Category < right.Category
    end)
    local result = {}
    for index = 1, math.min(limit, #candidates) do
        result[#result + 1] = candidates[index]
    end
    return result, calibrationSamples, strongestBlend, #selectedAreas
end

function WorldSpawnPredictor:_formatDuration(seconds)
    if tonumber(seconds) == nil then return "unknown" end
    seconds = math.max(0, math.floor(tonumber(seconds) + 0.5))
    if seconds >= 3600 then
        return string.format("%dh %02dm", math.floor(seconds / 3600), math.floor(seconds % 3600 / 60))
    elseif seconds >= 60 then
        return string.format("%dm %02ds", math.floor(seconds / 60), seconds % 60)
    end
    return tostring(seconds) .. "s"
end

function WorldSpawnPredictor:refresh(deep)
    if self.DeepProbeBusy then
        return false, self.LastText
    end
    self.DeepProbeBusy = true
    self:observePassive()
    local ok, reportOrError, text = xpcall(function()
        self:_refreshLuck(deep == true)
        local metadata, sourceCount = self:_metadataCandidates(deep == true)
        local now = self:_serverNow()
        local committed
        for _, candidate in ipairs(metadata) do
            local candidateAt = tonumber(candidate.At)
            local timedFuture = candidateAt and candidateAt >= now - 1 and candidateAt <= now + 900
            if candidate.HardCommitted or timedFuture then
                committed = candidate
                break
            end
        end
        local configuredArea = tostring(self.Runtime.Config.Predictor.SelectedArea or "All Areas")
        if configuredArea ~= "All Areas" then
            configuredArea = self:_canonicalArea(configuredArea) or "All Areas"
        end
        local forecastArea = committed and committed.AreaId or configuredArea
        local ranked, samples, calibrationBlend, rankedAreaCount = self:_rank(
            forecastArea,
            self.Runtime.Config.Predictor.ForecastCount
        )
        local nextAt, uncertainty, timingSource = self:_cycleEstimate(committed)
        local lines = {}
        local confidence
        if committed then
            confidence = committed.HardCommitted and 99 or 95
            lines[#lines + 1] = "REPLICATED NEXT-SPAWN PREVIEW"
            lines[#lines + 1] = string.format(
                "%s%s",
                committed.Category,
                committed.AreaId and (" • " .. committed.AreaId) or ""
            )
            lines[#lines + 1] = string.format(
                "ETA %s%s • confidence %d%%",
                nextAt and self:_formatDuration(nextAt - now) or "not replicated",
                uncertainty and uncertainty > 0 and (" ±" .. self:_formatDuration(uncertainty)) or "",
                confidence
            )
            lines[#lines + 1] = "Evidence: " .. tostring(committed.Source)
        else
            confidence = nil
            lines[#lines + 1] = string.format(
                "FUTURE WORLD SPAWN FORECAST • %s",
                forecastArea == "All Areas" and "all areas" or forecastArea
            )
            lines[#lines + 1] = string.format(
                "Next reset in %s%s • %s",
                nextAt and self:_formatDuration(nextAt - now) or "unknown",
                uncertainty and uncertainty > 0 and (" ±" .. self:_formatDuration(uncertainty)) or "",
                tostring(timingSource)
            )
            if #ranked == 0 then
                lines[#lines + 1] = "No replicated Data.Areas drop table is available yet."
            else
                for index, candidate in ipairs(ranked) do
                    if forecastArea ~= "All Areas" then
                        lines[#lines + 1] = string.format(
                            "%d. %s • %.2f%%/slot • %.1f%% in %d slots",
                            index,
                            candidate.DisplayName or candidate.Category,
                            (tonumber(candidate.PerSlotProbability) or 0) * 100,
                            (tonumber(candidate.AppearanceProbability) or 0) * 100,
                            tonumber(candidate.SlotCount) or 5
                        )
                    else
                        local candidateAreas = {}
                        for _, areaId in ipairs(ALL_AREAS) do
                            if candidate.Areas[areaId] then candidateAreas[#candidateAreas + 1] = areaId end
                        end
                        lines[#lines + 1] = string.format(
                            "%d. %s%s • %.1f%% somewhere • E %.2f",
                            index,
                            candidate.DisplayName or candidate.Category,
                            #candidateAreas == 1 and (" [" .. candidateAreas[1] .. "]") or "",
                            (tonumber(candidate.AppearanceProbability) or 0) * 100,
                            tonumber(candidate.ExpectedCount) or 0
                        )
                    end
                end
            end
            local productLuck = math.max(1, tonumber(self.Luck.ProductMultiplier) or 1)
            local adminLuck = math.max(1, tonumber(self.Luck.AdminMultiplier) or 1)
            local effectiveLuck = math.max(1, tonumber(self.Luck.EffectiveMultiplier) or 1)
            if effectiveLuck > 1 then
                lines[#lines + 1] = string.format(
                    "Live luck %.2fx (server %.2fx × admin %.2fx) • exact AssetLottery model • %d matching samples",
                    effectiveLuck,
                    productLuck,
                    adminLuck,
                    tonumber(samples) or 0
                )
                lines[#lines + 1] = "Replicated weights and the live rarest-of-N roll transform are applied exactly."
            else
                lines[#lines + 1] = string.format(
                    "Live luck 1.00x • authoritative Data.Areas.DropTable • %d areas",
                    tonumber(rankedAreaCount) or 0
                )
            end
            lines[#lines + 1] = "Server RNG is private before commit; listed chances are not fake certainty."
        end

        local batch = self.LastSpawnBatch
        if type(batch) == "table" and type(batch.Records) == "table" then
            local exactCount = 0
            local noteworthy = {}
            for _, record in ipairs(batch.Records) do
                if configuredArea == "All Areas" or record.AreaId == configuredArea then
                    exactCount += 1
                    local entry = record.Category and self.Catalog[record.Category]
                    if entry and (tonumber(entry.Rarity) or 0) >= 8 then
                        noteworthy[#noteworthy + 1] = string.format(
                            "%s [%s]",
                            entry.DisplayName or record.Category,
                            tostring(record.AreaId or "?")
                        )
                    end
                end
            end
            table.sort(noteworthy)
            while #noteworthy > 4 do table.remove(noteworthy) end
            lines[#lines + 1] = string.format(
                "Latest exact reset #%s: %d matching eggs%s",
                tostring(batch.PeriodIndex or "?"),
                exactCount,
                #noteworthy > 0 and (" • top: " .. table.concat(noteworthy, ", ")) or ""
            )
        end
        local reveal = self.LastReveal
        if type(reveal) == "table" and type(reveal.RareSpawns) == "table" and #reveal.RareSpawns > 0 then
            local exactRare = {}
            for _, rare in ipairs(reveal.RareSpawns) do
                exactRare[#exactRare + 1] = rare.Category
                    and string.format("%s [%s]", rare.Category, tostring(rare.AreaId or "?"))
                    or tostring(rare.RarityId or rare.Uid)
            end
            lines[#lines + 1] = "Server reveal: " .. table.concat(exactRare, ", ")
        end
        local report = {
            Committed = committed,
            Ranked = ranked,
            NextAt = nextAt,
            Uncertainty = uncertainty,
            Confidence = confidence,
            MetadataSources = sourceCount,
            TimingSource = timingSource,
            Luck = shallowCopy(self.Luck),
            LastSpawnBatch = self.LastSpawnBatch,
            LastReveal = self.LastReveal,
            Deep = deep == true,
            UpdatedAt = now,
        }
        return report, table.concat(lines, "\n")
    end, debug.traceback)
    self.DeepProbeBusy = false
    if not ok then
        self.Runtime.LastError = tostring(reportOrError)
        return false, tostring(reportOrError)
    end
    self.LastReport = reportOrError
    self.LastText = text
    local committed = reportOrError.Committed
    if committed then
        local signature = table.concat({
            tostring(committed.Category),
            tostring(committed.AreaId or ""),
            tostring(committed.At or ""),
            tostring(committed.Source or ""),
        }, "|")
        if signature ~= self.LastCommittedSignature then
            self.LastCommittedSignature = signature
            if self.Runtime.Config.Predictor.NotifyCommitted == true then
                self.Runtime:notify(
                    "World Spawn Prediction",
                    string.format("Replicated next: %s%s", committed.Category, committed.AreaId and (" in " .. committed.AreaId) or ""),
                    8
                )
            end
        end
    end
    return true, text
end

function WorldSpawnPredictor:tick()
    self:_bindContainer()
    if self.Runtime.Config.Predictor.Enabled ~= true then
        return false
    end
    local now = os.clock()
    if now >= self.NextObserveAt then
        self.NextObserveAt = now + math.clamp(
            tonumber(self.Runtime.Config.Predictor.ObservationInterval) or 0.75,
            0.25,
            5
        )
        self:observePassive()
    end
    if now >= self.NextForecastAt then
        self.NextForecastAt = now + 2
        self:refresh(false)
    end
    return true
end

function WorldSpawnPredictor:start()
    self.Runtime:spawn("world-spawn-predictor", 0.2, function()
        self:tick()
    end)
end

local worldSpawnPredictor = WorldSpawnPredictor.new(runtime, state, broker)
runtime.WorldSpawnPredictor = worldSpawnPredictor
worldSpawnPredictor:start()

local CharacterTransport = {}
CharacterTransport.__index = CharacterTransport

local function isRegisteredMovementState(candidate, player, character, root, humanoid)
    if type(candidate) ~= "table"
        or rawget(candidate, "Player") ~= player
        or rawget(candidate, "Character") ~= character
        or rawget(candidate, "RootPart") ~= root
        or rawget(candidate, "Humanoid") ~= humanoid
        or type(rawget(candidate, "Evidence")) ~= "table" then
        return false
    end
    return type(rawget(candidate, "LastHeartbeatSequence")) == "number"
        or (
            type(rawget(candidate, "MovementMode")) == "string"
            and type(rawget(candidate, "SampleHistory")) == "table"
            and type(rawget(candidate, "HistoryCount")) == "number"
        )
end

local function discoverRegisteredTransportNative()
    LPH_ATTRIBUTES(VM(NONE))
    local environment = (getgenv and getgenv()) or _G
    local nativeGetgc = rawget(environment, "__FLOW_NATIVE_GETGC") or rawget(environment, "getgc") or getgc
    local nativeDebug = rawget(environment, "__FLOW_NATIVE_DEBUG") or rawget(environment, "debug") or debug
    if type(nativeGetgc) ~= "function"
        or type(nativeDebug) ~= "table"
        or type(nativeDebug.info) ~= "function"
        or type(nativeDebug.getupvalues) ~= "function" then
        return nil, "Executor debug introspection unavailable"
    end

    rawset(environment, "__FLOW_NATIVE_DISCOVERY_WORK", {
        State = nil,
        Capability = nil,
        Protocols = {},
    })
    local graphResult = {pcall(nativeGetgc, false)}
    local functions = graphResult[1] and type(graphResult[2]) == "table" and graphResult[2] or nil
    if not functions then
        rawset((getgenv and getgenv()) or _G, "__FLOW_NATIVE_DISCOVERY_WORK", nil)
        return nil, "Executor function graph unavailable"
    end

    for index, object in ipairs(functions) do
        if type(object) == "function" then
            local infoResult = {pcall(nativeDebug.info, object, "ns")}
            local infoOk = infoResult[1]
            local name = infoResult[2]
            local source = infoOk and string.gsub(tostring(infoResult[3]), "^[=@]", "") or ""
            local relevant = infoOk and (
                name == "BeginImpulse"
                or string.sub(source, 1, #"ReplicatedFirst.UGI.ContentCatalog")
                    == "ReplicatedFirst.UGI.ContentCatalog"
                or source == "ReplicatedFirst.IntroLoader.F.RagdollMovement"
            )
            if relevant then
                local work = rawget((getgenv and getgenv()) or _G, "__FLOW_NATIVE_DISCOVERY_WORK")
                work.CurrentName = name
                work.CurrentSource = source
                work.CurrentFunction = object

                local upvalueResult = {pcall(nativeDebug.getupvalues, object)}
                work = rawget((getgenv and getgenv()) or _G, "__FLOW_NATIVE_DISCOVERY_WORK")
                local upvalues = upvalueResult[1] and type(upvalueResult[2]) == "table" and upvalueResult[2] or {}
                local scanPlayer = game:GetService("Players").LocalPlayer
                local scanCharacter = scanPlayer and scanPlayer.Character
                local scanRoot = scanCharacter and scanCharacter:FindFirstChild("HumanoidRootPart")
                local scanHumanoid = scanCharacter and scanCharacter:FindFirstChildOfClass("Humanoid")
                for upvalueIndex, upvalue in ipairs(upvalues) do
                    if upvalueIndex > 64 then
                        break
                    end
                    if isRegisteredMovementState(
                        upvalue,
                        scanPlayer,
                        scanCharacter,
                        scanRoot,
                        scanHumanoid
                    ) then
                        work.State = upvalue
                    end
                end

                local constants = {}
                if type(nativeDebug.getconstants) == "function" then
                    local constantsResult = {pcall(nativeDebug.getconstants, object)}
                    constants = constantsResult[1]
                        and type(constantsResult[2]) == "table"
                        and constantsResult[2]
                        or {}
                end
                work = rawget((getgenv and getgenv()) or _G, "__FLOW_NATIVE_DISCOVERY_WORK")
                local currentSource = work.CurrentSource
                if not work.Capability and currentSource == "ReplicatedFirst.UGI.ContentCatalog" then
                    local hasAction = false
                    local hasGuard = false
                    local hasAssert = false
                    for _, value in pairs(constants) do
                        hasAction = hasAction or value == "SetWalkSpeed"
                        hasGuard = hasGuard or value == "SetWalkSpeed action requires one value"
                        hasAssert = hasAssert or value == "assert"
                    end
                    if hasAction and hasGuard and hasAssert then
                        local freshResult = {pcall(nativeDebug.getupvalues, work.CurrentFunction)}
                        work = rawget((getgenv and getgenv()) or _G, "__FLOW_NATIVE_DISCOVERY_WORK")
                        local fresh = freshResult[1] and type(freshResult[2]) == "table" and freshResult[2] or {}
                        local capability = fresh[7]
                        if type(capability) == "table" and next(capability) == nil then
                            work.Capability = capability
                        end
                    end
                elseif not work.Capability
                    and currentSource == "ReplicatedFirst.UGI.ContentCatalog.Playback" then
                    local required = {
                        CorrectionContext = false,
                        RecoveryLocked = false,
                        InvalidMovementSample = false,
                        ["Anti-cheat rejected a non-finite character movement sample"] = false,
                    }
                    for _, value in pairs(constants) do
                        if required[value] ~= nil then
                            required[value] = true
                        end
                    end
                    if required.CorrectionContext
                        and required.RecoveryLocked
                        and required.InvalidMovementSample
                        and required["Anti-cheat rejected a non-finite character movement sample"] then
                        local freshResult = {pcall(nativeDebug.getupvalues, work.CurrentFunction)}
                        work = rawget((getgenv and getgenv()) or _G, "__FLOW_NATIVE_DISCOVERY_WORK")
                        local fresh = freshResult[1] and type(freshResult[2]) == "table" and freshResult[2] or {}
                        local capability = fresh[2]
                        if type(capability) == "table" and next(capability) == nil then
                            work.Capability = capability
                        end
                    end
                end

                work = rawget((getgenv and getgenv()) or _G, "__FLOW_NATIVE_DISCOVERY_WORK")
                if work.CurrentName == "BeginImpulse" then
                    local freshResult = {pcall(nativeDebug.getupvalues, work.CurrentFunction)}
                    work = rawget((getgenv and getgenv()) or _G, "__FLOW_NATIVE_DISCOVERY_WORK")
                    local fresh = freshResult[1] and type(freshResult[2]) == "table" and freshResult[2] or {}
                    local hasImpulse = false
                    for _, value in pairs(constants) do
                        hasImpulse = hasImpulse or value == "Impulse"
                    end
                    local kind
                    if work.CurrentSource == "ReplicatedFirst.IntroLoader.F.RagdollMovement" then
                        kind = "legacy"
                        if not work.Capability and type(fresh[1]) == "function" then
                            local guardResult = {pcall(nativeDebug.getupvalues, fresh[1])}
                            work = rawget((getgenv and getgenv()) or _G, "__FLOW_NATIVE_DISCOVERY_WORK")
                            local guardUpvalues = guardResult[1]
                                and type(guardResult[2]) == "table"
                                and guardResult[2]
                                or {}
                            if type(guardUpvalues[2]) == "table" then
                                work.Capability = guardUpvalues[2]
                            end
                        end
                    elseif work.CurrentSource == "ReplicatedFirst.UGI.ContentCatalog.Impact"
                        and hasImpulse
                        and type(fresh[1]) == "function"
                        and type(fresh[2]) == "function" then
                        kind = "ugi"
                    end
                    if kind then
                        work.Protocols[#work.Protocols + 1] = {
                            BeginImpulse = work.CurrentFunction,
                            Guard = fresh[1],
                            Kind = kind,
                        }
                    end
                end
            end
        end
        if index % 500 == 0 then
            task.wait()
        end
    end

    local completed = rawget((getgenv and getgenv()) or _G, "__FLOW_NATIVE_DISCOVERY_WORK")
    rawset((getgenv and getgenv()) or _G, "__FLOW_NATIVE_DISCOVERY_WORK", nil)
    return completed, nil
end

local function discoverRegisteredTransportConnections()
    LPH_ATTRIBUTES(VM(NONE))
    local environment = (getgenv and getgenv()) or _G
    local nativeGetconnections = rawget(environment, "__FLOW_NATIVE_GETCONNECTIONS")
        or rawget(environment, "getconnections")
        or getconnections
    local nativeDebug = rawget(environment, "__FLOW_NATIVE_DEBUG") or rawget(environment, "debug") or debug
    if type(nativeGetconnections) ~= "function"
        or type(nativeDebug) ~= "table"
        or type(nativeDebug.info) ~= "function"
        or type(nativeDebug.getupvalues) ~= "function"
        or type(nativeDebug.getconstants) ~= "function" then
        return nil, "RunService connection introspection unavailable"
    end

    local queue = {}
    local seen = {}
    local function enqueue(value, depth)
        local valueType = type(value)
        if (valueType == "function" or valueType == "table")
            and not seen[value]
            and depth <= 10 then
            seen[value] = true
            queue[#queue + 1] = {Value = value, Depth = depth}
        end
    end

    local function addSignalRoots(signal)
        if signal == nil then
            return
        end
        local connectionsResult = {pcall(nativeGetconnections, signal)}
        local connections = connectionsResult[1]
            and type(connectionsResult[2]) == "table"
            and connectionsResult[2]
            or {}
        for _, connection in ipairs(connections) do
            local callbackResult = {pcall(function()
                return connection.Function or connection.Callback
            end)}
            local callback = callbackResult[1] and callbackResult[2] or nil
            if type(callback) == "function" then
                local infoResult = {pcall(nativeDebug.info, callback, "s")}
                local source = infoResult[1]
                    and string.gsub(tostring(infoResult[2]), "^[=@]", "")
                    or ""
                if string.sub(source, 1, #"ReplicatedFirst.UGI.ContentCatalog")
                    == "ReplicatedFirst.UGI.ContentCatalog" then
                    enqueue(callback, 0)
                end
            end
        end
    end

    addSignalRoots(RunService.PreSimulation)
    addSignalRoots(RunService.PostSimulation)
    if #queue == 0 then
        return nil, "ContentCatalog movement connections unavailable"
    end

    local player = game:GetService("Players").LocalPlayer
    local character = player and player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local state
    local capability
    local protocol

    local function inspectState(candidate)
        if state or type(candidate) ~= "table" then
            return
        end
        if isRegisteredMovementState(candidate, player, character, root, humanoid) then
            state = candidate
        end
    end

    local cursor = 1
    while cursor <= #queue and cursor <= 12000 do
        local item = queue[cursor]
        cursor += 1
        local candidate = item.Value
        local depth = item.Depth
        inspectState(candidate)

        if type(candidate) == "function" then
            local infoResult = {pcall(nativeDebug.info, candidate, "ns")}
            local name = infoResult[1] and infoResult[2] or ""
            local source = infoResult[1]
                and string.gsub(tostring(infoResult[3]), "^[=@]", "")
                or ""
            local upvalueResult = {pcall(nativeDebug.getupvalues, candidate)}
            local upvalues = upvalueResult[1]
                and type(upvalueResult[2]) == "table"
                and upvalueResult[2]
                or {}

            if not protocol
                and name == "BeginImpulse"
                and source == "ReplicatedFirst.UGI.ContentCatalog.Impact"
                and type(upvalues[1]) == "function" then
                protocol = {
                    BeginImpulse = candidate,
                    Guard = upvalues[1],
                    Kind = "ugi",
                }
            end

            if not capability and source == "ReplicatedFirst.UGI.ContentCatalog.Playback" then
                local constantsResult = {pcall(nativeDebug.getconstants, candidate)}
                local constants = constantsResult[1]
                    and type(constantsResult[2]) == "table"
                    and constantsResult[2]
                    or {}
                local required = {
                    CorrectionContext = false,
                    RecoveryLocked = false,
                    InvalidMovementSample = false,
                    ["Anti-cheat rejected a non-finite character movement sample"] = false,
                }
                for _, value in pairs(constants) do
                    if required[value] ~= nil then
                        required[value] = true
                    end
                end
                if required.CorrectionContext
                    and required.RecoveryLocked
                    and required.InvalidMovementSample
                    and required["Anti-cheat rejected a non-finite character movement sample"]
                    and type(upvalues[2]) == "table"
                    and next(upvalues[2]) == nil then
                    capability = upvalues[2]
                end
            end

            for upvalueIndex, upvalue in ipairs(upvalues) do
                if upvalueIndex > 64 then
                    break
                end
                inspectState(upvalue)
                enqueue(upvalue, depth + 1)
            end
        elseif depth < 10 then
            local visited = 0
            pcall(function()
                for key, value in next, candidate do
                    visited += 1
                    if visited > 256 then
                        break
                    end
                    inspectState(key)
                    inspectState(value)
                    enqueue(key, depth + 1)
                    enqueue(value, depth + 1)
                end
            end)
        end

        if state and capability and protocol then
            return {
                State = state,
                Capability = capability,
                Protocols = {protocol},
            }, nil
        end
        if cursor % 400 == 0 then
            task.wait()
        end
    end

    return {
        State = state,
        Capability = capability,
        Protocols = protocol and {protocol} or {},
    }, "Registered connection graph was incomplete"
end

local function discoverRegisteredStateFallback()
    LPH_ATTRIBUTES(VM(NONE))
    local environment = (getgenv and getgenv()) or _G
    local nativeGetgc = rawget(environment, "__FLOW_NATIVE_GETGC") or rawget(environment, "getgc") or getgc
    local nativeDebug = rawget(environment, "__FLOW_NATIVE_DEBUG") or rawget(environment, "debug") or debug
    if type(nativeGetgc) ~= "function"
        or type(nativeDebug) ~= "table"
        or type(nativeDebug.getupvalues) ~= "function" then
        return nil
    end

    local graphResult = {pcall(nativeGetgc, false)}
    local functions = graphResult[1] and type(graphResult[2]) == "table" and graphResult[2] or nil
    if not functions then
        return nil
    end

    local player = game:GetService("Players").LocalPlayer
    local character = player and player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    for index, object in ipairs(functions) do
        if type(object) == "function" then
            local upvalueResult = {pcall(nativeDebug.getupvalues, object)}
            local upvalues = upvalueResult[1]
                and type(upvalueResult[2]) == "table"
                and upvalueResult[2]
                or {}
            for upvalueIndex, candidate in ipairs(upvalues) do
                if upvalueIndex > 64 then
                    break
                end
                if isRegisteredMovementState(candidate, player, character, root, humanoid) then
                    return candidate
                end
            end
        end
        if index % 500 == 0 then
            task.wait()
        end
    end
    return nil
end

function CharacterTransport.new(owner)
    return setmetatable({
        Runtime = owner,
        AuthenticatedSender = nil,
        Integrity = nil,
        TransportMode = nil,
        KnownState = nil,
        ProtocolCache = nil,
        PlayerControls = nil,
        LastRefreshAt = 0,
        LastCharacter = nil,
        CharacterSeenAt = 0,
        DiscoveryInProgress = false,
        RegisteredRetryScheduled = false,
        RegisteredRetryGeneration = 0,
        IntegrityDiscoverySettlingSeconds = 0.2,
        IntegrityDiscoveryRetrySeconds = 0.35,
        IntegrityValidationGraceSeconds = 0.75,
        CharacterWatcherStarted = false,
        LastDiscoveryReason = "Authenticated character transport not yet validated",
        LastAttestedAt = nil,
        LastDistance = 0,
        LastPulseCount = 0,
        LastGroundCorrectionCount = 0,
        LastMaximumUpwardSpeed = 0,
        LastMaximumGroundClearance = 0,
        FloorGlideBypass = nil,
    }, CharacterTransport)
end

function CharacterTransport:_stateBound(integrity)
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local state = integrity and integrity.State
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    return type(state) == "table"
        and character ~= nil
        and root ~= nil
        and humanoid ~= nil
        and humanoid.Health > 0
        and root.Anchored ~= true
        and integrity.Character == character
        and integrity.Root == root
        and integrity.Humanoid == humanoid
        and rawget(state, "Player") == LocalPlayer
        and rawget(state, "Character") == character
        and rawget(state, "RootPart") == root
        and rawget(state, "Humanoid") == humanoid
end

function CharacterTransport:_invalidateCharacterBinding(character, reason)
    self:_cancelRegisteredRetry()
    self.LastCharacter = character
    self.CharacterSeenAt = os.clock()
    self.LastRefreshAt = 0
    self.AuthenticatedSender = nil
    self.Integrity = nil
    self.TransportMode = nil
    self.KnownState = nil
    self.ProtocolCache = nil
    self.PlayerControls = nil
    self.FloorGlideBypass = nil
    self.LastDiscoveryReason = reason or "Character changed; reacquiring registered movement"
end

function CharacterTransport:startCharacterWatcher()
    if self.CharacterWatcherStarted then
        return
    end
    self.CharacterWatcherStarted = true

    self.Runtime:track(LocalPlayer.CharacterAdded:Connect(function(character)
        self:_invalidateCharacterBinding(character)
        self.Runtime:setStatus("steal_best_egg", "Recovering", "Character changed; rebinding movement")
        task.spawn(function()
            local root = character:FindFirstChild("HumanoidRootPart")
                or character:WaitForChild("HumanoidRootPart", 5)
            local humanoid = character:FindFirstChildOfClass("Humanoid")
                or character:WaitForChild("Humanoid", 5)
            if self.Runtime.Destroyed or LocalPlayer.Character ~= character or not root or not humanoid then
                return
            end

            local deadline = os.clock() + 5
            local ready, readyReason
            repeat
                ready, readyReason = self:refresh(true)
                if ready and self.TransportMode == "registered" then
                    break
                end
                task.wait(0.05)
            until self.Runtime.Destroyed or LocalPlayer.Character ~= character or os.clock() >= deadline

            if ready and self.TransportMode == "registered" then
                self.Runtime.AutomationResumeAt = 0
                local scheduler = self.Runtime.Scheduler
                if scheduler and type(scheduler.reset) == "function" then
                    scheduler:reset("steal_best_egg")
                end
                self.Runtime:setStatus("steal_best_egg", "Looping", "Character rebound; auto-steal resumed")
            else
                self.Runtime:setStatus(
                    "steal_best_egg",
                    "Looping",
                    "Character rebind pending: " .. tostring(readyReason)
                )
            end
        end)
    end))
end

function CharacterTransport:_integrityStatus()
    local integrity = self.Integrity
    local state = integrity and integrity.State
    local evidence = state and rawget(state, "Evidence")
    return integrityTransportDecision(
        self:_stateBound(integrity),
        integrity and integrity.CapabilityValid == true,
        state and rawget(state, "ThreatLevel"),
        state and rawget(state, "KickQueued"),
        state and rawget(state, "LastHeartbeatSequence"),
        state and rawget(state, "InvalidHeartbeatCount"),
        state and rawget(state, "ValidationLocked"),
        state and rawget(state, "CurrentChallenge"),
        state and rawget(state, "TamperScore"),
        state and rawget(state, "CoreGuiScore"),
        type(evidence) == "table" and rawget(evidence, "Speed"),
        type(evidence) == "table" and rawget(evidence, "Flight"),
        type(evidence) == "table" and rawget(evidence, "Teleport")
    )
end

function CharacterTransport:_discoverIntegrity()
    local snapshot, discoveryReason = discoverRegisteredTransportNative()
    local function snapshotComplete(candidate)
        local discoveredProtocol = type(candidate) == "table"
            and type(candidate.Protocols) == "table"
            and candidate.Protocols[1]
            or nil
        return type(candidate) == "table"
            and type(candidate.State) == "table"
            and type(candidate.Capability) == "table"
            and type(discoveredProtocol) == "table"
            and type(discoveredProtocol.BeginImpulse) == "function"
            and type(discoveredProtocol.Guard) == "function"
    end
    if not snapshotComplete(snapshot) then
        local connectionSnapshot, connectionReason = discoverRegisteredTransportConnections()
        if snapshotComplete(connectionSnapshot) then
            snapshot = connectionSnapshot
            discoveryReason = nil
        else
            if type(snapshot) ~= "table" then
                snapshot = {}
            end
            if type(connectionSnapshot) == "table" then
                snapshot.State = connectionSnapshot.State or snapshot.State
                snapshot.Capability = connectionSnapshot.Capability or snapshot.Capability
                local connectionProtocols = connectionSnapshot.Protocols
                if type(connectionProtocols) == "table" and connectionProtocols[1] then
                    snapshot.Protocols = connectionProtocols
                end
            end
            discoveryReason = connectionReason or discoveryReason
        end
    end
    if type(snapshot) ~= "table" then
        return nil, discoveryReason or "Native registered transport discovery failed"
    end

    if type(snapshot.State) ~= "table" then
        snapshot.State = discoverRegisteredStateFallback()
    end

    self.KnownState = snapshot.State
    self.DiscoveredCapability = snapshot.Capability
    self.DiscoveredProtocols = type(snapshot.Protocols) == "table" and snapshot.Protocols or {}
    local state = self.KnownState
    local protocol = self.DiscoveredProtocols[1]
    local capability = self.DiscoveredCapability
    if type(state) ~= "table" then
        return nil, "Live registered-physics state unavailable"
    end
    if type(protocol) ~= "table"
        or type(protocol.BeginImpulse) ~= "function"
        or type(protocol.Guard) ~= "function" then
        return nil, "Live registered-physics protocol unavailable"
    end
    if type(capability) ~= "table" then
        return nil, "Registered integrity capability unavailable"
    end

    local beginRagdoll
    if protocol.Kind == "ugi" then
        local environment = (getgenv and getgenv()) or _G
        local nativeDebug = rawget(environment, "__FLOW_NATIVE_DEBUG")
            or rawget(environment, "debug")
            or debug
        local upvalueResult = type(nativeDebug) == "table"
            and type(nativeDebug.getupvalues) == "function"
            and {pcall(nativeDebug.getupvalues, protocol.BeginImpulse)}
            or {false}
        local upvalues = upvalueResult[1]
            and type(upvalueResult[2]) == "table"
            and upvalueResult[2]
            or {}
        local beginImpact = upvalues[2]
        local mutationScope = upvalues[3]
        if type(beginImpact) == "function" and mutationScope ~= nil then
            beginRagdoll = function(registeredCapability, registeredState, walkSpeed, duration, impulse, rootPart)
                protocol.Guard(registeredCapability)
                return beginImpact(
                    mutationScope,
                    registeredCapability,
                    registeredState,
                    walkSpeed,
                    "Ragdoll",
                    duration,
                    impulse,
                    rootPart
                )
            end
        end
    end
    if type(beginRagdoll) ~= "function" then
        return nil, "Registered ragdoll transport unavailable"
    end

    if rawget(state, "ValidationLocked") == true or rawget(state, "CurrentChallenge") ~= nil then
        local validationDeadline = os.clock() + self.IntegrityValidationGraceSeconds
        repeat
            RunService.Heartbeat:Wait()
        until (rawget(state, "ValidationLocked") ~= true and rawget(state, "CurrentChallenge") == nil)
            or os.clock() >= validationDeadline
    end
    local validationCharacter = LocalPlayer.Character
    local validationIntegrity = {
        State = state,
        Character = validationCharacter,
        Root = validationCharacter and validationCharacter:FindFirstChild("HumanoidRootPart"),
        Humanoid = validationCharacter and validationCharacter:FindFirstChildOfClass("Humanoid"),
    }
    local validationEvidence = rawget(state, "Evidence")
    local decisionOk, decisionReason = integrityTransportDecision(
        self:_stateBound(validationIntegrity),
        true,
        rawget(state, "ThreatLevel"),
        rawget(state, "KickQueued"),
        rawget(state, "LastHeartbeatSequence"),
        rawget(state, "InvalidHeartbeatCount"),
        rawget(state, "ValidationLocked"),
        rawget(state, "CurrentChallenge"),
        rawget(state, "TamperScore"),
        rawget(state, "CoreGuiScore"),
        type(validationEvidence) == "table" and rawget(validationEvidence, "Speed"),
        type(validationEvidence) == "table" and rawget(validationEvidence, "Flight"),
        type(validationEvidence) == "table" and rawget(validationEvidence, "Teleport")
    )
    if not decisionOk then
        return nil, decisionReason
    end

    self.ProtocolCache = {
        BeginImpulse = protocol.BeginImpulse,
        BeginRagdoll = beginRagdoll,
        Guard = protocol.Guard,
        Capability = capability,
        ProtocolKind = protocol.Kind,
    }
    local character = validationCharacter
    return {
        State = state,
        BeginImpulse = protocol.BeginImpulse,
        BeginRagdoll = beginRagdoll,
        Guard = protocol.Guard,
        Capability = capability,
        CapabilityValid = true,
        ProtocolKind = protocol.Kind,
        Character = character,
        Root = character and character:FindFirstChild("HumanoidRootPart"),
        Humanoid = character and character:FindFirstChildOfClass("Humanoid"),
    }, nil
end

function CharacterTransport:_cancelRegisteredRetry()
    self.RegisteredRetryGeneration += 1
    self.RegisteredRetryScheduled = false
end

function CharacterTransport:_scheduleRegisteredRetry()
    if self.RegisteredRetryScheduled
        or self.Runtime.Destroyed
        or self.TransportMode ~= "locomotion" then
        return
    end

    self.RegisteredRetryScheduled = true
    self.RegisteredRetryGeneration += 1
    local generation = self.RegisteredRetryGeneration
    local character = self.LastCharacter
    task.delay(self.IntegrityDiscoveryRetrySeconds, function()
        if generation ~= self.RegisteredRetryGeneration then
            return
        end
        self.RegisteredRetryScheduled = false
        if self.Runtime.Destroyed
            or self.TransportMode ~= "locomotion"
            or LocalPlayer.Character ~= character then
            return
        end
        self:refresh(true)
    end)
end

function CharacterTransport:refresh(force)
    local now = os.clock()
    local character = LocalPlayer.Character
    if character ~= self.LastCharacter then
        self:_invalidateCharacterBinding(character)
    end
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not character or not root or not humanoid or humanoid.Health <= 0 or root.Anchored then
        self.LastDiscoveryReason = "Character integrity is still settling"
        return false, self.LastDiscoveryReason
    end
    if now - self.CharacterSeenAt < self.IntegrityDiscoverySettlingSeconds then
        self.LastDiscoveryReason = "Character integrity is still settling"
        return false, self.LastDiscoveryReason
    end
    if force ~= true and now - self.LastRefreshAt < self.IntegrityDiscoveryRetrySeconds then
        return false, self.LastDiscoveryReason
    end
    if self.DiscoveryInProgress then
        if type(self.AuthenticatedSender) == "function" then
            return true, nil
        end
        return false, self.LastDiscoveryReason or "Registered transport discovery is already running"
    end

    local retainedLocomotion = self.TransportMode == "locomotion"
        and type(self.AuthenticatedSender) == "function"
    self.LastRefreshAt = now
    if not retainedLocomotion then
        self.AuthenticatedSender = nil
        self.Integrity = nil
        self.TransportMode = nil
    end

    self.DiscoveryInProgress = true
    local discovered = pack(pcall(function()
        return self:_discoverIntegrity()
    end))
    self.DiscoveryInProgress = false
    local integrity = discovered[1] and discovered[2] or nil
    local reason = discovered[1] and discovered[3] or safeString(discovered[2])
    if integrity then
        self:_cancelRegisteredRetry()
        self.Integrity = integrity
        self.TransportMode = "registered"
        self.AuthenticatedSender = function(targetCFrame, cancellation, options)
            return self:_sendRegistered(targetCFrame, cancellation, options)
        end
        self.LastDiscoveryReason = nil
        return true, nil
    end

    if retainedLocomotion then
        self.LastDiscoveryReason = tostring(reason)
        self:_scheduleRegisteredRetry()
        return true, nil
    end

    local fallbackConfigured = (self.Runtime.Config.Movement or {}).LocomotionFallback ~= false
    local fallbackOk = locomotionFallbackDecision(fallbackConfigured, root ~= nil and humanoid.Health > 0 and not root.Anchored)
    if fallbackOk then
        self.Integrity = nil
        self.ProtocolCache = nil
        self.TransportMode = "locomotion"
        self.AuthenticatedSender = function(targetCFrame, cancellation, options)
            return self:_sendLocomotion(targetCFrame, cancellation, options)
        end
        self.LastDiscoveryReason = tostring(reason)
        self:_scheduleRegisteredRetry()
        return true, nil
    end
    self.LastDiscoveryReason = tostring(reason)
    return false, self.LastDiscoveryReason
end

function CharacterTransport:status()
    local config = self.Runtime.Config.Movement or {}
    local senderReady = type(self.AuthenticatedSender) == "function"
    if self.TransportMode == "locomotion" and senderReady then
        self:refresh(false)
        senderReady = type(self.AuthenticatedSender) == "function"
    elseif not senderReady or not self:_stateBound(self.Integrity) then
        self:refresh(false)
        senderReady = type(self.AuthenticatedSender) == "function"
    end
    local policyOk, policyReason = movementTransportDecision(config.Transport, senderReady)
    if not policyOk then
        return false, self.LastDiscoveryReason or policyReason
    end
    if self.TransportMode == "locomotion" then
        return true, nil
    end
    return self:_integrityStatus()
end

function CharacterTransport:waitForIntegrityReady(timeoutSeconds, homePredicate)
    if self.TransportMode == "locomotion" and type(self.AuthenticatedSender) == "function" then
        if type(homePredicate) == "function" and homePredicate() == true then
            return true, "home"
        end
        local character = LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if character and root and humanoid and humanoid.Health > 0 and not root.Anchored then
            return true, "ready"
        end
        return false, "Character unavailable for locomotion transport"
    end
    local deadline = os.clock() + clampFinite(timeoutSeconds, 0.05, 1.5, 0.75)
    local reason = "Integrity movement validation is locked"
    repeat
        local ready
        ready, reason = self:_integrityStatus()
        local atHome = type(homePredicate) == "function" and homePredicate() == true
        local disposition = returnWaitDisposition(atHome, ready, reason)
        if disposition == "home" then
            return true, "home"
        elseif disposition == "ready" then
            return true, "ready"
        elseif disposition == "fail" then
            return false, reason
        end
        RunService.Heartbeat:Wait()
    until os.clock() >= deadline
    return false, reason
end

function CharacterTransport:awaitActionReady(timeoutSeconds)
    local deadline = os.clock() + clampFinite(timeoutSeconds, 0.05, 5, 1.5)
    local reason = "Character movement is rebinding"
    repeat
        local ready
        ready, reason = self:status()
        if ready then
            return true, nil
        end
        if integrityWaitDisposition(ready, reason) ~= "retry" then
            return false, reason
        end
        RunService.Heartbeat:Wait()
    until os.clock() >= deadline
    return false, reason
end

function CharacterTransport:waitForRegistered(timeoutSeconds)
    local deadline = os.clock() + clampFinite(timeoutSeconds, 0.25, 8, 4)
    local reason = "Registered speed bypass is still binding"
    repeat
        local ready
        ready, reason = self:refresh(true)
        if ready and self.TransportMode == "registered" and self:_stateBound(self.Integrity) then
            local integrityReady, integrityReason = self:_integrityStatus()
            if integrityReady then
                return true, nil
            end
            reason = integrityReason
        end
        RunService.Heartbeat:Wait()
    until self.Runtime.Destroyed or os.clock() >= deadline
    return false, "Registered speed bypass unavailable: " .. tostring(reason)
end

function CharacterTransport:withAuthorized(callback)
    local ready, reason = self:awaitActionReady(1.5)
    if not ready then
        return false, reason
    end
    local results = pack(xpcall(callback, debug.traceback))
    if not results[1] then
        return false, results[2]
    end
    return true, table.unpack(results, 2, results.n)
end

function CharacterTransport:getRoot()
    local character = LocalPlayer.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end

function CharacterTransport:_getControls()
    if type(self.PlayerControls) == "table" then
        return self.PlayerControls
    end
    local function recoverDestroyedPlayerModuleControls()
        if type(getgc) ~= "function" then
            return nil
        end
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local gcOk, objects = pcall(getgc, true)
        if not gcOk or type(objects) ~= "table" then
            return nil
        end
        for _, candidate in ipairs(objects) do
            if isControlModuleCandidate(candidate, humanoid) then
                return candidate
            end
        end
        return nil
    end

    local playerScripts = LocalPlayer:FindFirstChild("PlayerScripts")
    local playerModuleScript = playerScripts and playerScripts:FindFirstChild("PlayerModule")
    if not playerModuleScript then
        local recovered = recoverDestroyedPlayerModuleControls()
        if recovered then
            self.PlayerControls = recovered
            return recovered, nil
        end
        return nil, "Player controls unavailable"
    end
    local moduleOk, playerModule = pcall(require, playerModuleScript)
    if not moduleOk or type(playerModule) ~= "table" or type(playerModule.GetControls) ~= "function" then
        local recovered = recoverDestroyedPlayerModuleControls()
        if recovered then
            self.PlayerControls = recovered
            return recovered, nil
        end
        return nil, "Player control module unavailable"
    end
    local controlsOk, controls = pcall(playerModule.GetControls, playerModule)
    if not controlsOk or type(controls) ~= "table"
        or type(controls.Disable) ~= "function" or type(controls.Enable) ~= "function" then
        local recovered = recoverDestroyedPlayerModuleControls()
        if recovered then
            self.PlayerControls = recovered
            return recovered, nil
        end
        return nil, "Player control isolation unavailable"
    end
    self.PlayerControls = controls
    return controls, nil
end

function CharacterTransport:_boundaryParts()
    local objects = Workspace:FindFirstChild("__OBJECTS")
    local areas = objects and objects:FindFirstChild("Areas")
    return areas and areas:FindFirstChild("WallStartCollision"), areas and areas:FindFirstChild("SeparationLine")
end

function CharacterTransport:acquireBoundaryPass()
    local wall = self:_boundaryParts()
    local released = false
    local suppressed = {}
    local connections = {}

    local function suppress(part)
        if not part or suppressed[part] or not part:IsA("BasePart") then
            return
        end
        suppressed[part] = part.CanCollide
        if part.CanCollide then
            part.CanCollide = false
        end
        connections[#connections + 1] = part:GetPropertyChangedSignal("CanCollide"):Connect(function()
            if not released and part.Parent and part.CanCollide then
                part.CanCollide = false
            end
        end)
    end

    local function watch(container)
        if not container then
            return
        end
        for _, descendant in ipairs(container:GetDescendants()) do
            suppress(descendant)
        end
        if container.DescendantAdded then
            connections[#connections + 1] = container.DescendantAdded:Connect(suppress)
        end
    end

    suppress(wall)
    watch(Workspace:FindFirstChild("__DEBRIS"))
    watch(Workspace:FindFirstChild("AreaEggSlotsClient"))
    local stands = Workspace:FindFirstChild("Stands")
    watch(stands and stands:FindFirstChild("Models"))
    watch(Workspace:FindFirstChild("__ClientTreadmillRenders"))

    return function()
        if released then
            return
        end
        released = true
        for _, connection in ipairs(connections) do
            connection:Disconnect()
        end
        table.clear(connections)
        for part, originalCollision in pairs(suppressed) do
            if part.Parent then
                part.CanCollide = originalCollision
            end
        end
        table.clear(suppressed)
    end
end

function CharacterTransport:_horizontal(vector)
    return Vector3.new(vector.X, 0, vector.Z)
end

function CharacterTransport:_groundedVelocity(root, horizontalVelocity, raycastParams)
    local rayOrigin = root.Position + Vector3.new(0, 2, 0)
    local ground = Workspace:Raycast(rayOrigin, Vector3.new(0, -66, 0), raycastParams)
    local clearance = ground and (root.Position.Y - ground.Position.Y) or nil
    local verticalSpeed = groundAdhesionVerticalSpeed(clearance, root.AssemblyLinearVelocity.Y)
    return Vector3.new(horizontalVelocity.X, verticalSpeed, horizontalVelocity.Z), clearance
end

function CharacterTransport:_applyDesiredHorizontalVelocity(desiredVelocity, duration, movementKind, verticalVelocity)
    local integrityOk, integrityReason = self:_integrityStatus()
    if not integrityOk then
        return false, integrityReason
    end
    local integrity = self.Integrity
    local root = integrity.Root
    local currentVelocity = root.AssemblyLinearVelocity
    local deltaVelocity = self:_horizontal(desiredVelocity) - self:_horizontal(currentVelocity)
    if tonumber(verticalVelocity) then
        deltaVelocity += Vector3.new(0, verticalVelocity - currentVelocity.Y, 0)
    end
    local impulse = deltaVelocity * math.max(root.AssemblyMass, 0.001)
    local registrar = movementKind == "Ragdoll" and integrity.BeginRagdoll or integrity.BeginImpulse
    if type(registrar) ~= "function" then
        return false, "Registered movement registrar unavailable"
    end
    local beginOk, timestamp = pcall(
        registrar,
        integrity.Capability,
        integrity.State,
        integrity.Humanoid.WalkSpeed,
        clampFinite(duration, 0.35, 5, 0.8),
        impulse,
        root
    )
    if not beginOk or timestamp == nil then
        return false, beginOk and "Registered impulse was rejected" or safeString(timestamp)
    end
    local impulseOk, impulseError = pcall(root.ApplyImpulse, root, impulse)
    if not impulseOk then
        return false, safeString(impulseError)
    end
    self.LastAttestedAt = timestamp
    return true, timestamp
end

function CharacterTransport:_sendRegistered(targetCFrame, cancellation, options)
    if self.Runtime.Destroyed or (type(cancellation) == "function" and cancellation()) then
        return false, "Movement cancelled"
    end
    local integrityOk, integrityReason = self:awaitActionReady(1.5)
    if not integrityOk then
        return false, integrityReason
    end
    if self.TransportMode ~= "registered" or type(self.Integrity) ~= "table" then
        return false, self.LastDiscoveryReason or "Registered speed bypass unavailable"
    end

    local integrity = self.Integrity
    local root = integrity.Root
    local position = targetCFrame.Position
    if position.X ~= position.X or position.Y ~= position.Y or position.Z ~= position.Z
        or math.abs(position.X) > 1000000 or math.abs(position.Y) > 1000000 or math.abs(position.Z) > 1000000 then
        return false, "Target CFrame is not finite"
    end

    local controls = self:_getControls()
    local isolateControls = playerControlIsolationAvailable(controls)
    local movementConfig = self.Runtime.Config.Movement or {}
    options = type(options) == "table" and options or {}
    local state = self.Runtime.State
    local dynamicMaximum = state and state:getTransportCruiseSpeed() or currentTransportCruiseSpeed()
    local requestedCustomSpeed = options.AllowCustomSpeed == true
        and customStealSpeed(options.CruiseSpeed)
        or 0
    local cruiseSpeed = requestedCustomSpeed > 0
        and requestedCustomSpeed
        or clampFinite(options.CruiseSpeed, 96, dynamicMaximum, dynamicMaximum)
    local minimumApproachSpeed = options.MinimumApproachSpeed ~= nil
        and customStealSpeed(options.MinimumApproachSpeed)
        or 0
    local responseGain = clampFinite(options.ResponseGain or movementConfig.ResponseGain, 2, 20, 6)
    local arrivalRadius = clampFinite(options.ArrivalRadius or movementConfig.ArrivalRadius, 0.5, 12, 5)
    local pulseInterval = registeredImpulsePulseInterval(movementConfig.PulseInterval)
    local origin = root.Position
    local requestedTimeout = clampFinite(options.TimeoutSeconds or movementConfig.TimeoutSeconds, 1, 30, 14)
    local initialDistance = self:_horizontal(position - origin).Magnitude
    local timeoutSeconds = movementTimeoutBudget(initialDistance, cruiseSpeed, requestedTimeout, 30)
    local wall, gameplayLine = self:_boundaryParts()
    local crossesBoundary = gameplayLine ~= nil
        and gameplayLine.CFrame.LookVector:Dot(origin - gameplayLine.Position)
            * gameplayLine.CFrame.LookVector:Dot(position - gameplayLine.Position) < 0
    local originalWallCollision = wall and wall.CanCollide
    local controlsDisabled = false
    local useRagdoll = options.UseRagdoll == true
    local stayGrounded = options.StayGrounded ~= false
    local movementKind = useRagdoll and "Ragdoll" or "Impulse"
    local ragdollState = Enum.HumanoidStateType.Ragdoll
    local originalRagdollEnabled = useRagdoll and integrity.Humanoid:GetStateEnabled(ragdollState) or nil
    local ragdollPrepared = false
    local groundRaycastParams = RaycastParams.new()
    groundRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
    groundRaycastParams.IgnoreWater = false
    local groundExclusions = {integrity.Character}
    local debris = Workspace:FindFirstChild("__DEBRIS")
    local stands = Workspace:FindFirstChild("Stands")
    local treadmillRenders = Workspace:FindFirstChild("__ClientTreadmillRenders")
    if debris then groundExclusions[#groundExclusions + 1] = debris end
    if stands then groundExclusions[#groundExclusions + 1] = stands end
    if treadmillRenders then groundExclusions[#groundExclusions + 1] = treadmillRenders end
    groundRaycastParams.FilterDescendantsInstances = groundExclusions
    local releaseCollisionPass = self:acquireBoundaryPass()

    local results = pack(xpcall(function()
        if isolateControls then
            controls:Disable()
            controlsDisabled = true
        end
        if useRagdoll then
            integrity.Humanoid:SetStateEnabled(ragdollState, true)
            integrity.Humanoid:ChangeState(ragdollState)
            ragdollPrepared = true
        end
        RunService.Heartbeat:Wait()

        local startedAt = os.clock()
        local softDeadline = startedAt + timeoutSeconds
        local hardDeadline = startedAt + math.min(30, math.max(timeoutSeconds * 2, timeoutSeconds + 6))
        local bestDistance = initialDistance
        local lastPulseAt = -math.huge
        local pulseCount = 0
        local registrationInterval = cruiseSpeed >= 500 and math.min(pulseInterval, 0.05) or pulseInterval
        local groundCorrectionCount = 0
        local maximumUpwardSpeed = math.max(0, root.AssemblyLinearVelocity.Y)
        local maximumGroundClearance = 0
        local anchorGraceSeconds = clampFinite(
            options.TransientAnchorGraceSeconds or movementConfig.TransientAnchorGraceSeconds,
            0.1,
            2,
            0.35
        )
        while os.clock() < softDeadline and os.clock() < hardDeadline do
            if self.Runtime.Destroyed or (type(cancellation) == "function" and cancellation()) then
                return false, "Movement cancelled"
            end
            if not self:_stateBound(integrity) then
                if root.Anchored
                    and integrity.Character == LocalPlayer.Character
                    and integrity.Humanoid.Health > 0 then
                    local anchorDeadline = os.clock() + anchorGraceSeconds
                    repeat
                        RunService.Heartbeat:Wait()
                    until not root.Anchored
                        or integrity.Humanoid.Health <= 0
                        or os.clock() >= anchorDeadline
                end
            end
            if not self:_stateBound(integrity) then
                return false, "Character changed during movement"
            end
            local threatLevel = integrity.State.ThreatLevel
            if (threatLevel ~= "Trusted" and threatLevel ~= "Observing")
                or integrity.State.KickQueued == true then
                return false, "Integrity changed during registered movement"
            end
            if crossesBoundary and wall and wall.Parent then
                wall.CanCollide = false
            end

            local remaining = self:_horizontal(position - root.Position)
            local distance = remaining.Magnitude
            if distance <= arrivalRadius then
                break
            end
            local now = os.clock()
            bestDistance, softDeadline = refreshMovementDeadline(
                bestDistance,
                distance,
                now,
                softDeadline,
                hardDeadline,
                1,
                1.25
            )
            local direction = remaining.Unit
            local speed = movementApproachSpeed(distance, responseGain, cruiseSpeed)
            if minimumApproachSpeed > 0 then
                speed = math.max(speed, math.min(minimumApproachSpeed, cruiseSpeed))
            end
            local desiredVelocity = direction * speed
            local desiredVerticalVelocity
            if stayGrounded then
                local groundedVelocity, clearance = self:_groundedVelocity(root, desiredVelocity, groundRaycastParams)
                desiredVelocity = groundedVelocity
                desiredVerticalVelocity = groundedVelocity.Y
                maximumUpwardSpeed = math.max(maximumUpwardSpeed, root.AssemblyLinearVelocity.Y)
                if clearance then
                    maximumGroundClearance = math.max(maximumGroundClearance, clearance)
                end
                if desiredVerticalVelocity < 0 or root.AssemblyLinearVelocity.Y > 10 then
                    groundCorrectionCount += 1
                end
                root.AssemblyAngularVelocity = Vector3.zero
            end
            if now - lastPulseAt >= registrationInterval then
                if useRagdoll and integrity.Humanoid:GetState() ~= ragdollState then
                    integrity.Humanoid:ChangeState(ragdollState)
                end
                local applied, applyReason = self:_applyDesiredHorizontalVelocity(
                    desiredVelocity,
                    0.8,
                    movementKind,
                    desiredVerticalVelocity
                )
                if not applied then
                    return false, applyReason
                end
                pulseCount += 1
                lastPulseAt = now
            end
            RunService.Heartbeat:Wait()
        end

        local stopVelocity = Vector3.zero
        local stopVerticalVelocity
        if stayGrounded then
            local groundedStop = self:_groundedVelocity(root, Vector3.zero, groundRaycastParams)
            stopVelocity = groundedStop
            stopVerticalVelocity = groundedStop.Y
            root.AssemblyAngularVelocity = Vector3.zero
        end
        local stopped, stopReason = self:_applyDesiredHorizontalVelocity(
            stopVelocity,
            0.5,
            movementKind,
            stopVerticalVelocity
        )
        if not stopped then
            return false, stopReason
        end
        RunService.Heartbeat:Wait()
        RunService.Heartbeat:Wait()

        local finalDistance = self:_horizontal(position - root.Position).Magnitude
        self.LastDistance = (position - origin).Magnitude
        self.LastPulseCount = pulseCount
        self.LastGroundCorrectionCount = groundCorrectionCount
        self.LastMaximumUpwardSpeed = maximumUpwardSpeed
        self.LastMaximumGroundClearance = maximumGroundClearance
        if movementArrivalAccepted(finalDistance, arrivalRadius) then
            return true, string.format("Registered physics arrived within %.1f studs", finalDistance)
        end
        return false, string.format("Registered movement timed out %.1f studs away", finalDistance)
    end, debug.traceback))

    if wall and wall.Parent and originalWallCollision ~= nil then
        pcall(function()
            wall.CanCollide = originalWallCollision
        end)
    end
    pcall(releaseCollisionPass)
    if ragdollPrepared and integrity.Humanoid.Parent then
        pcall(integrity.Humanoid.ChangeState, integrity.Humanoid, Enum.HumanoidStateType.Running)
        pcall(integrity.Humanoid.SetStateEnabled, integrity.Humanoid, ragdollState, originalRagdollEnabled)
    end
    if controlsDisabled then
        pcall(function()
            controls:Enable()
        end)
    end
    if not results[1] then
        return false, safeString(results[2])
    end
    return results[2], results[3]
end

function CharacterTransport:_awaitMobile(character, root, humanoid)
    if not character or not root or not humanoid then
        return false
    end
    local downedDeadline = os.clock() + 6
    while os.clock() < downedDeadline do
        if character:GetAttribute("Downed") == true
            or humanoid:GetState() == Enum.HumanoidStateType.Ragdoll
            or humanoid:GetState() == Enum.HumanoidStateType.FallingDown then
            RunService.Heartbeat:Wait()
            character = LocalPlayer.Character
            root = self:getRoot()
            humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if not character or not root or not humanoid or humanoid.Health <= 0 then
                return false
            end
        else
            break
        end
    end
    local anchorDeadline = os.clock() + 1.25
    while root.Anchored and os.clock() < anchorDeadline do
        RunService.Heartbeat:Wait()
        if humanoid.Health <= 0 then
            return false
        end
    end
    return not root.Anchored and humanoid.Health > 0
end

function CharacterTransport:_discoverFloorGlideBypass()
    if type(getconnections) ~= "function"
        or type(debug) ~= "table"
        or type(debug.info) ~= "function"
        or type(debug.getconstants) ~= "function"
        or type(debug.getupvalues) ~= "function" then
        return nil, "Volt rollback-connection inspection unavailable"
    end

    local cached = self.FloorGlideBypass
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if type(cached) == "table"
        and cached.Connection ~= nil
        and cached.EnforcementConnection ~= nil
        and type(cached.State) == "table"
        and rawget(cached.State, "Player") == LocalPlayer
        and rawget(cached.State, "Character") == character
        and rawget(cached.State, "RootPart") == root
        and rawget(cached.State, "Humanoid") == humanoid then
        return cached, nil
    end

    local connectionsOk, connections = pcall(getconnections, RunService.PostSimulation)
    if not connectionsOk or type(connections) ~= "table" then
        return nil, "PostSimulation connections unavailable"
    end
    local surfaceConnection = nil
    local enforcementConnection = nil
    local surfaceState = nil
    for _, connection in ipairs(connections) do
        local fn = connection.Function
        if type(fn) == "function" then
            local infoOk, source = pcall(debug.info, fn, "s")
            source = infoOk and tostring(source) or ""
            if source == "ReplicatedFirst.UGI.ContentCatalog.Surface" then
                local constantsOk, constants = pcall(debug.getconstants, fn)
                local hasCorrectionContext = false
                if constantsOk and type(constants) == "table" then
                    for _, value in pairs(constants) do
                        if value == "CorrectionContext" then
                            hasCorrectionContext = true
                            break
                        end
                    end
                end
                local upvaluesOk, upvalues = pcall(debug.getupvalues, fn)
                local state = upvaluesOk and type(upvalues) == "table" and upvalues[1] or nil
                if hasCorrectionContext
                    and type(state) == "table"
                    and rawget(state, "Player") == LocalPlayer
                    and rawget(state, "Character") == character
                    and rawget(state, "RootPart") == root
                    and rawget(state, "Humanoid") == humanoid
                    and type(connection.Disable) == "function"
                    and type(connection.Enable) == "function" then
                    surfaceConnection = connection
                    surfaceState = state
                end
            elseif source == "ReplicatedFirst.UGI.ContentCatalog"
                and type(connection.Disable) == "function"
                and type(connection.Enable) == "function" then
                enforcementConnection = connection
            end
        end
    end
    if surfaceConnection and enforcementConnection and surfaceState then
        cached = {
            Connection = surfaceConnection,
            EnforcementConnection = enforcementConnection,
            State = surfaceState,
        }
        self.FloorGlideBypass = cached
        return cached, nil
    end
    return nil, "Live ContentCatalog movement enforcement set unavailable"
end

function CharacterTransport:_suspendMovementValidator()
    local bypass, reason = self:_discoverFloorGlideBypass()
    if not bypass then
        return nil, reason
    end
    local states = {}
    for _, connection in ipairs({bypass.Connection, bypass.EnforcementConnection}) do
        local state = {
            Connection = connection,
            WasEnabled = connection.Enabled ~= false,
        }
        states[#states + 1] = state
        if state.WasEnabled then
            local disabled, disableError = pcall(connection.Disable, connection)
            if not disabled then
                for _, previous in ipairs(states) do
                    if previous ~= state and previous.WasEnabled and previous.Connection.Enabled == false then
                        pcall(previous.Connection.Enable, previous.Connection)
                    end
                end
                return nil, safeString(disableError)
            end
        end
    end
    return {
        Bypass = bypass,
        ConnectionStates = states,
    }, nil
end

function CharacterTransport:_adoptMovementBaseline(bypass)
    local state = type(bypass) == "table" and bypass.State or nil
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if type(state) ~= "table" or not root or not humanoid then
        return false, "Movement baseline state unavailable"
    end

    local now = os.clock()
    local sample = type(state.LastSample) == "table" and table.clone(state.LastSample) or {}
    sample.Timestamp = now
    sample.CFrame = root.CFrame
    sample.Position = root.Position
    sample.WalkSpeed = humanoid.WalkSpeed
    sample.HumanoidState = humanoid:GetState()
    sample.LinearVelocity = root.AssemblyLinearVelocity
    sample.AngularVelocity = root.AssemblyAngularVelocity
    sample.IsSupported = true

    if type(state.SampleHistory) == "table" then
        table.clear(state.SampleHistory)
        state.SampleHistory[1] = sample
    end
    state.HistoryHead = 1
    state.HistoryCount = 1
    if type(state.SafeGroundCheckpoints) == "table" then
        table.clear(state.SafeGroundCheckpoints)
        state.SafeGroundCheckpoints[1] = sample
    end
    state.SafeGroundCheckpointHead = 1
    state.SafeGroundCheckpointCount = 1

    for _, key in ipairs({
        "LastObservedSample",
        "LastGameplayTrustedSample",
        "LastValidatedSample",
        "LastSample",
        "LastGoodSample",
        "LastValidatedGroundedSample",
        "LastConfirmedGroundSample",
    }) do
        state[key] = sample
    end

    state.CorrectionContext = nil
    state.ImpulseContext = nil
    state.PendingCommit = nil
    state.FirstSuspiciousAt = nil
    state.ValidationLocked = false
    state.ThreatLevel = "Trusted"
    state.MovementMode = "Grounded"
    state.IsSupportedNow = true
    state.LastSupportedAt = now
    state.SupportStartedAt = now
    state.UnsupportedStartedAt = nil
    state.HighestYSinceGround = root.Position.Y
    state.Evidence = {Speed = 0, Flight = 0, Teleport = 0}
    return true, nil
end

function CharacterTransport:_resumeMovementValidator(token)
    if type(token) ~= "table" or type(token.Bypass) ~= "table" then
        return
    end
    for _, state in ipairs(token.ConnectionStates or {}) do
        if state.WasEnabled and state.Connection.Enabled == false then
            pcall(state.Connection.Enable, state.Connection)
        end
    end
end

function CharacterTransport:_sendFloorGlide(targetCFrame, cancellation, options)
    if self.Runtime.Destroyed or (type(cancellation) == "function" and cancellation()) then
        return false, "Movement cancelled"
    end
    local character = LocalPlayer.Character
    local root = self:getRoot()
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not character or not root or not humanoid or humanoid.Health <= 0 then
        return false, "Character unavailable for floor-glide transport"
    end
    local position = targetCFrame.Position
    if position.X ~= position.X or position.Y ~= position.Y or position.Z ~= position.Z
        or math.abs(position.X) > 1000000 or math.abs(position.Y) > 1000000 or math.abs(position.Z) > 1000000 then
        return false, "Target CFrame is not finite"
    end

    local movementConfig = self.Runtime.Config.Movement or {}
    options = type(options) == "table" and options or {}
    local arrivalRadius = clampFinite(options.ArrivalRadius or movementConfig.ArrivalRadius, 2, 12, 5)
    local requestedTimeout = clampFinite(options.TimeoutSeconds or movementConfig.TimeoutSeconds, 1, 30, 14)
    local origin = root.Position
    local initialDistance = self:_horizontal(position - origin).Magnitude
    local requestedCustomSpeed = options.AllowCustomSpeed == true
        and customStealSpeed(options.WalkSpeed or options.CruiseSpeed)
        or 0
    local glideSpeed = requestedCustomSpeed > 0
        and requestedCustomSpeed
        or floorGlideSpeed(
            options.WalkSpeed or humanoid.WalkSpeed,
            options.GlideSpeedMultiplier or movementConfig.GlideSpeedMultiplier
        )
    local travelY = math.max(origin.Y, position.Y)
    local timeoutSeconds = movementTimeoutBudget(initialDistance, math.max(glideSpeed, 20), requestedTimeout, 30)
    local wall, gameplayLine = self:_boundaryParts()
    local lineX = gameplayLine and gameplayLine.Position.X
    local crossesBoundary = lineX ~= nil
        and (origin.X - lineX) * (position.X - lineX) < 0
    local originalWallCollision = wall and wall.CanCollide
    local validatorToken, validatorReason = self:_suspendMovementValidator()
    if not validatorToken then
        return false, "Speed bypass unavailable: " .. tostring(validatorReason)
    end
    local originalPlatformStand = humanoid.PlatformStand
    local originalAutoRotate = humanoid.AutoRotate
    local areas = Workspace:FindFirstChild("__OBJECTS")
    areas = areas and areas:FindFirstChild("Areas")
    local gameplayLane = areas and areas:FindFirstChild("GameplayZ")
    local laneY = gameplayLane and gameplayLane:IsA("BasePart")
        and (gameplayLane.Position.Y + 3)
        or math.min(origin.Y, position.Y)
    local groundExclusions = {character}
    local excludedGroundFolders = {
        Workspace:FindFirstChild("AreaEggSlotsClient"),
        Workspace:FindFirstChild("__DEBRIS"),
        Workspace:FindFirstChild("__ClientTreadmillRenders"),
    }
    if options.AllowStandGround ~= true then
        excludedGroundFolders[#excludedGroundFolders + 1] = Workspace:FindFirstChild("Stands")
    end
    for _, excluded in ipairs(excludedGroundFolders) do
        if excluded then
            groundExclusions[#groundExclusions + 1] = excluded
        end
    end
    local function groundedY(x, z, fallbackY, currentRoot, currentHumanoid)
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.IgnoreWater = false
        local ignored = table.clone(groundExclusions)
        local hip = currentHumanoid.HipHeight > 0 and currentHumanoid.HipHeight or 2
        local standOffset = hip + currentRoot.Size.Y * 0.5
        local currentY = tonumber(fallbackY) or currentRoot.Position.Y
        local originY = math.max(laneY, currentY) + 80
        local bestSupportedY
        local bestVerticalDelta = math.huge
        for _ = 1, 16 do
            params.FilterDescendantsInstances = ignored
            local hit = Workspace:Raycast(Vector3.new(x, originY, z), Vector3.new(0, -400, 0), params)
            if not hit then
                break
            end
            local instance = hit.Instance
            local collidable = instance:IsA("Terrain")
                or (instance:IsA("BasePart") and instance.CanCollide)
            local supportedY = hit.Position.Y + standOffset
            local verticalDelta = math.abs(supportedY - currentY)
            if collidable
                and hit.Normal.Y >= 0.55
                and verticalDelta <= 24
                and verticalDelta < bestVerticalDelta then
                bestSupportedY = supportedY
                bestVerticalDelta = verticalDelta
            end
            ignored[#ignored + 1] = instance
        end
        if bestSupportedY ~= nil then
            return bestSupportedY, true
        end
        return nil, false
    end
    pcall(function()
        humanoid.Sit = false
        humanoid.PlatformStand = true
        humanoid.AutoRotate = false
    end)

    local results = pack(xpcall(function()
        if crossesBoundary and wall and wall.Parent then
            wall.CanCollide = false
        end
        local startedAt = os.clock()
        local softDeadline = startedAt + timeoutSeconds
        local hardDeadline = startedAt + math.min(30, math.max(timeoutSeconds * 2, timeoutSeconds + 6))
        local lastSafeCFrame = root.CFrame
        while os.clock() < softDeadline and os.clock() < hardDeadline do
            local deltaTime = RunService.Heartbeat:Wait()
            if self.Runtime.Destroyed or (type(cancellation) == "function" and cancellation()) then
                return false, "Movement cancelled"
            end
            local currentRoot = self:getRoot()
            local currentHumanoid = character:FindFirstChildOfClass("Humanoid")
            if LocalPlayer.Character ~= character then
                return false, "Character model changed during movement"
            elseif not currentRoot then
                return false, "HumanoidRootPart disappeared during movement"
            elseif not currentHumanoid then
                return false, "Humanoid disappeared during movement"
            elseif currentHumanoid.Health <= 0 then
                return false, "Humanoid died during movement"
            end
            if currentRoot.Anchored then
                pcall(function()
                    currentRoot.Anchored = false
                end)
            end
            currentHumanoid.Sit = false
            currentHumanoid.PlatformStand = true
            currentHumanoid.AutoRotate = false
            local remaining = self:_horizontal(position - currentRoot.Position).Magnitude
            if remaining <= arrivalRadius then
                break
            end
            local step, distance = floorGlideStep(
                currentRoot.Position,
                position,
                glideSpeed,
                deltaTime
            )
            if distance ~= nil and distance <= arrivalRadius then
                break
            end
            if step and currentRoot.Parent then
                local nextPosition = currentRoot.Position + step
                local supportedY, hasSupport = groundedY(
                    nextPosition.X,
                    nextPosition.Z,
                    travelY,
                    currentRoot,
                    currentHumanoid
                )
                if not hasSupport then
                    character:PivotTo(lastSafeCFrame)
                    currentRoot.AssemblyLinearVelocity = Vector3.zero
                    currentRoot.AssemblyAngularVelocity = Vector3.zero
                    return false, "Ground support ended before target; movement stopped safely"
                end
                travelY = supportedY
                character:PivotTo(
                    CFrame.new(nextPosition.X, travelY, nextPosition.Z)
                        * currentRoot.CFrame.Rotation
                )
                currentRoot.AssemblyLinearVelocity = Vector3.zero
                currentRoot.AssemblyAngularVelocity = Vector3.zero
                lastSafeCFrame = currentRoot.CFrame
            end
            if crossesBoundary and wall and wall.Parent and wall.CanCollide then
                wall.CanCollide = false
            end
        end

        local finalRoot = self:getRoot()
        local finalDistance = finalRoot
            and self:_horizontal(position - finalRoot.Position).Magnitude
            or math.huge
        if movementArrivalAccepted(finalDistance, arrivalRadius) then
            return true, string.format("Rollback-bypassed glide arrived within %.1f studs", finalDistance)
        end
        return false, string.format("Speed bypass timed out %.1f studs away", finalDistance)
    end, debug.traceback))

    if wall and wall.Parent and originalWallCollision ~= nil then
        pcall(function()
            wall.CanCollide = originalWallCollision
        end)
    end
    if humanoid.Parent and LocalPlayer.Character == character then
        pcall(function()
            humanoid.PlatformStand = originalPlatformStand
            humanoid.AutoRotate = originalAutoRotate
            humanoid.Sit = false
            humanoid:ChangeState(Enum.HumanoidStateType.Running)
        end)
    end
    local baselineOk, baselineReason = self:_adoptMovementBaseline(validatorToken.Bypass)
    self:_resumeMovementValidator(validatorToken)
    if not results[1] then
        return false, safeString(results[2])
    end
    if not baselineOk then
        return false, "Speed bypass baseline failed: " .. tostring(baselineReason)
    end
    return results[2], results[3]
end

function CharacterTransport:_sendLocomotion(targetCFrame, cancellation, options)
    if self.Runtime.Destroyed or (type(cancellation) == "function" and cancellation()) then
        return false, "Movement cancelled"
    end
    local character = LocalPlayer.Character
    local root = self:getRoot()
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not character or not root or not humanoid or humanoid.Health <= 0 then
        return false, "Character unavailable for locomotion transport"
    end

    local position = targetCFrame.Position
    if position.X ~= position.X or position.Y ~= position.Y or position.Z ~= position.Z
        or math.abs(position.X) > 1000000 or math.abs(position.Y) > 1000000 or math.abs(position.Z) > 1000000 then
        return false, "Target CFrame is not finite"
    end

    local controls = self:_getControls()
    local isolateControls = playerControlIsolationAvailable(controls)
    local movementConfig = self.Runtime.Config.Movement or {}
    options = type(options) == "table" and options or {}
    local arrivalRadius = clampFinite(options.ArrivalRadius or movementConfig.ArrivalRadius, 2, 12, 5)
    local requestedTimeout = clampFinite(options.TimeoutSeconds or movementConfig.TimeoutSeconds, 1, 30, 14)
    local origin = root.Position
    local initialDistance = self:_horizontal(position - origin).Magnitude
    local timeoutSeconds = movementTimeoutBudget(initialDistance, 60, requestedTimeout, 30)
    local wall, gameplayLine = self:_boundaryParts()
    local lineX = gameplayLine and gameplayLine.Position.X
    local crossesBoundary = lineX ~= nil
        and (origin.X - lineX) * (position.X - lineX) < 0
    local originalWallCollision = wall and wall.CanCollide
    local originalWalkSpeed = humanoid.WalkSpeed
    local requestedCustomSpeed = options.AllowCustomSpeed == true
        and customStealSpeed(options.WalkSpeed or options.CruiseSpeed)
        or 0
    local transitWalkSpeed
    if requestedCustomSpeed > 0 then
        transitWalkSpeed = requestedCustomSpeed
    else
        local transitMultiplier = clampFinite(
            tonumber(movementConfig.TransitWalkSpeedMultiplier) or 1,
            1,
            8,
            1
        )
        transitWalkSpeed = math.min(originalWalkSpeed * transitMultiplier, 2000)
    end

    local results = pack(xpcall(function()
        if isolateControls then
            controls:Disable()
        end
        RunService.Heartbeat:Wait()
        if crossesBoundary and wall and wall.Parent then
            wall.CanCollide = false
        end
        if transitWalkSpeed ~= originalWalkSpeed then
            humanoid.WalkSpeed = transitWalkSpeed
        end
        humanoid:MoveTo(position)

        local startedAt = os.clock()
        local softDeadline = startedAt + timeoutSeconds
        local hardDeadline = startedAt + math.min(30, math.max(timeoutSeconds * 2, timeoutSeconds + 6))
        local bestDistance = initialDistance
        local lastProgressAt = startedAt
        while os.clock() < softDeadline and os.clock() < hardDeadline do
            if self.Runtime.Destroyed or (type(cancellation) == "function" and cancellation()) then
                return false, "Movement cancelled"
            end
            local currentRoot = self:getRoot()
            local currentHumanoid = character:FindFirstChildOfClass("Humanoid")
            if not currentRoot or not currentHumanoid or currentHumanoid.Health <= 0 then
                return false, "Character changed during movement"
            end
            local remaining = self:_horizontal(position - currentRoot.Position)
            local distance = remaining.Magnitude
            if distance <= arrivalRadius then
                break
            end
            local now = os.clock()
            if distance < bestDistance - 0.5 then
                bestDistance = distance
                lastProgressAt = now
            elseif now - lastProgressAt >= 0.35 then
                currentHumanoid:MoveTo(position)
                lastProgressAt = now
            end
            if crossesBoundary and wall and wall.Parent and wall.CanCollide then
                wall.CanCollide = false
            end
            RunService.Heartbeat:Wait()
        end

        local finalRoot = self:getRoot()
        local finalDistance = finalRoot
            and self:_horizontal(position - finalRoot.Position).Magnitude
            or math.huge
        pcall(humanoid.MoveTo, humanoid, finalRoot and finalRoot.Position or origin)
        self.LastDistance = (position - origin).Magnitude
        if movementArrivalAccepted(finalDistance, arrivalRadius) then
            return true, string.format("Locomotion arrived within %.1f studs", finalDistance)
        end
        return false, string.format("Locomotion timed out %.1f studs away", finalDistance)
    end, debug.traceback))

    if wall and wall.Parent and originalWallCollision ~= nil then
        pcall(function()
            wall.CanCollide = originalWallCollision
        end)
    end
    if originalWalkSpeed ~= nil and humanoid.Parent and humanoid.WalkSpeed ~= originalWalkSpeed then
        pcall(function()
            humanoid.WalkSpeed = originalWalkSpeed
        end)
    end
    if isolateControls then
        pcall(function()
            controls:Enable()
        end)
    end
    if not results[1] then
        return false, safeString(results[2])
    end
    return results[2], results[3]
end

function CharacterTransport:restore()
    local controls = self.PlayerControls
    if type(controls) == "table" and type(controls.Enable) == "function" then
        pcall(function()
            controls:Enable()
        end)
    end
end

function CharacterTransport:_sendTween()
    return false, "Tween transport is disabled"
end

function CharacterTransport:_sendNative()
    return false, "Native transport is disabled"
end

function CharacterTransport:moveTo(targetCFrame, cancellation, options)
    if typeof(targetCFrame) ~= "CFrame" then
        return false, "Target CFrame unavailable"
    end
    if self.Runtime.Destroyed or (type(cancellation) == "function" and cancellation()) then
        return false, "Movement cancelled"
    end
    options = type(options) == "table" and options or {}
    local transportMode = (self.Runtime.Config.Movement or {}).Transport
    if transportMode ~= "AuthenticatedOnly" then
        return false, "Only registered physics transport is enabled"
    end

    local actionDeadline = os.clock() + clampFinite(options.ActionReadyTimeoutSeconds, 1.5, 6, 5)
    local results
    local reason = "Integrity movement validation is locked"
    repeat
        local ready
        ready, reason = self:awaitActionReady(math.min(1.5, math.max(0.05, actionDeadline - os.clock())))
        if ready then
            results = pack(pcall(self.AuthenticatedSender, targetCFrame, cancellation, options))
            if not results[1] then
                return false, safeString(results[2])
            end
            if results[2] == true then
                break
            end
            reason = results[3]
        end
        if integrityWaitDisposition(false, reason) ~= "retry" or os.clock() >= actionDeadline then
            return false, reason
        end
        RunService.Heartbeat:Wait()
    until self.Runtime.Destroyed or (type(cancellation) == "function" and cancellation())

    if not results or results[2] ~= true then
        local cancelled = self.Runtime.Destroyed
            or (type(cancellation) == "function" and cancellation())
        return false, cancelled and "Movement cancelled" or reason
    end
    local settle = clampFinite(
        options.SettleSeconds ~= nil and options.SettleSeconds
            or (self.Runtime.Config.Movement or {}).SettleSeconds,
        0,
        0.5,
        0.04
    )
    if settle > 0 then
        task.wait(settle)
    end
    return true, results[3]
end

function CharacterTransport:moveRoute(targetCFrame, cancellation, options)
    if typeof(targetCFrame) ~= "CFrame" then
        return false, "Target CFrame unavailable"
    end
    local root = self:getRoot()
    if not root then
        return false, "Character unavailable"
    end
    local origin = root.Position
    local target = targetCFrame.Position
    local config = self.Runtime.Config.Movement or {}
    local legTimeout = clampFinite(config.RouteLegTimeoutSeconds, 1, 8, 4)
    local routeOptions = {}
    for key, value in pairs(type(options) == "table" and options or {}) do
        routeOptions[key] = value
    end
    routeOptions.TimeoutSeconds = math.min(
        tonumber(routeOptions.TimeoutSeconds) or legTimeout,
        legTimeout
    )
    routeOptions.SettleSeconds = 0
    local boundaryWall, gameplayLine = self:_boundaryParts()
    local crossesBoundary = gameplayLine ~= nil
        and (origin.X - gameplayLine.Position.X) * (target.X - gameplayLine.Position.X) < 0
    if routeOptions.DirectPath == true and not crossesBoundary then
        return self:moveTo(targetCFrame, cancellation, routeOptions)
    end

    local function treadmillDetour(startPosition, endPosition, ignored)
        local state = self.Runtime.State
        local obstacles = state and type(state.getTreadmillObstaclePositions) == "function"
            and state:getTreadmillObstaclePositions()
            or {}
        if #obstacles == 0 then
            local standCFrame = state and state:getTreadmillStandCFrame()
            if typeof(standCFrame) == "CFrame" then
                obstacles[1] = standCFrame.Position
            end
        end
        if #obstacles == 0 then
            return nil
        end
        local dx = endPosition.X - startPosition.X
        local dz = endPosition.Z - startPosition.Z
        local lengthSquared = dx * dx + dz * dz
        if lengthSquared <= 0.001 then
            return nil
        end
        local obstacle
        local obstacleKey
        local obstacleProjection = math.huge
        for _, candidate in ipairs(obstacles) do
            local key = string.format("%.1f:%.1f", candidate.X, candidate.Z)
            if not ignored[key] then
                local projection = ((candidate.X - startPosition.X) * dx + (candidate.Z - startPosition.Z) * dz)
                    / lengthSquared
                if projection > 0.01 and projection < 0.99 then
                    local closestX = startPosition.X + dx * projection
                    local closestZ = startPosition.Z + dz * projection
                    local clearanceX = candidate.X - closestX
                    local clearanceZ = candidate.Z - closestZ
                    local clearance = math.sqrt(clearanceX * clearanceX + clearanceZ * clearanceZ)
                    if clearance < 20 and projection < obstacleProjection then
                        obstacle = candidate
                        obstacleKey = key
                        obstacleProjection = projection
                    end
                end
            end
        end
        if not obstacle then
            return nil
        end
        local length = math.sqrt(lengthSquared)
        local perpendicularX = -dz / length
        local perpendicularZ = dx / length
        local first = Vector3.new(
            obstacle.X + perpendicularX * 30,
            startPosition.Y,
            obstacle.Z + perpendicularZ * 30
        )
        local second = Vector3.new(
            obstacle.X - perpendicularX * 30,
            startPosition.Y,
            obstacle.Z - perpendicularZ * 30
        )
        local plotCFrame = state:getPlotCenter()
        if typeof(plotCFrame) == "CFrame" then
            local plot = plotCFrame.Position
            local firstDistance = (first.X - plot.X) ^ 2 + (first.Z - plot.Z) ^ 2
            local secondDistance = (second.X - plot.X) ^ 2 + (second.Z - plot.Z) ^ 2
            if secondDistance < firstDistance then
                return second, obstacleKey
            end
        end
        return first, obstacleKey
    end

    local function moveLeg(position, force)
        local current = self:getRoot()
        if not current then
            return false, "Character unavailable"
        end
        local remaining = self:_horizontal(position - current.Position).Magnitude
        local arrival = clampFinite(config.ArrivalRadius, 2, 12, 6)
        if not force and remaining <= arrival then
            return true, "Route leg already reached"
        end
        local ignoredObstacles = {}
        for _ = 1, 6 do
            local detour, obstacleKey = treadmillDetour(current.Position, position, ignoredObstacles)
            if not detour then
                break
            end
            ignoredObstacles[obstacleKey] = true
            local diverted, divertReason = self:moveTo(CFrame.new(detour), cancellation, routeOptions)
            if not diverted then
                return false, divertReason
            end
            current = self:getRoot()
            if not current then
                return false, "Character unavailable after treadmill detour"
            end
        end
        return self:moveTo(CFrame.new(position), cancellation, routeOptions)
    end

    if not gameplayLine then
        return moveLeg(target, true)
    end

    local lineX = gameplayLine.Position.X
    local originSide = origin.X < lineX and -1 or 1
    local targetSide = target.X < lineX and -1 or 1
    if originSide == targetSide then
        return moveLeg(target, true)
    end

    local margin = clampFinite(config.SafeCorridorMargin, 10, 40, 18)
    local corridorX = lineX + targetSide * margin
    local plotCFrame = self.Runtime.State and self.Runtime.State:getPlotCenter()
    local homeSide = typeof(plotCFrame) == "CFrame"
        and (plotCFrame.Position.X < lineX and -1 or 1)
        or -1
    local homeCorridorX = lineX + homeSide * margin
    local outsideCorridorX = lineX - homeSide * margin
    local portalZ = boundaryWall and boundaryWall.Position.Z + 8 or gameplayLine.Position.Z
    if targetSide == homeSide then
        local approached, approachReason = moveLeg(Vector3.new(outsideCorridorX, target.Y, portalZ))
        if not approached then
            return false, approachReason
        end
        local crossed, crossReason = moveLeg(Vector3.new(homeCorridorX, target.Y, portalZ))
        if not crossed then
            return false, crossReason
        end
    else
        local approached, approachReason = moveLeg(Vector3.new(homeCorridorX, target.Y, portalZ))
        if not approached then
            return false, approachReason
        end
        local crossed, crossReason = moveLeg(Vector3.new(corridorX, target.Y, portalZ))
        if not crossed then
            return false, crossReason
        end
    end
    return moveLeg(target, true)
end

local movement = CharacterTransport.new(runtime)
runtime.Movement = movement
movement:startCharacterWatcher()

local ExperimentalFly = {}
ExperimentalFly.__index = ExperimentalFly

function ExperimentalFly.new(owner, transport)
    return setmetatable({
        Runtime = owner,
        Movement = transport,
        Input = game:GetService("UserInputService"),
        Enabled = false,
        Dispatcher = nil,
        OriginalPop = nil,
        WrappedPop = nil,
        Capability = nil,
        PendingComponents = nil,
        PendingOwner = nil,
        RagdollSuppressedUntil = 0,
        Consumers = {},
        Connection = nil,
        Speed = 72,
        VerticalSpeed = 54,
    }, ExperimentalFly)
end

function ExperimentalFly:_findDispatcher()
    if type(getgc) ~= "function"
        or type(debug) ~= "table"
        or type(debug.info) ~= "function"
        or type(debug.getconstants) ~= "function"
        or type(debug.getupvalues) ~= "function"
        or type(debug.setupvalue) ~= "function" then
        return nil, "Executor debug mutation support unavailable"
    end
    local ok, objects = pcall(getgc, false)
    if not ok or type(objects) ~= "table" then
        return nil, "Executor function graph unavailable"
    end
    for index, object in ipairs(objects) do
        if type(object) == "function" then
            local infoOk, source = pcall(debug.info, object, "s")
            source = infoOk and tostring(source) or ""
            if string.gsub(source, "^[=@]", "") == "ReplicatedFirst.UGI.ContentCatalog" then
                local constantsOk, constants = pcall(debug.getconstants, object)
                local upvaluesOk, upvalues = pcall(debug.getupvalues, object)
                if constantsOk and upvaluesOk
                    and registeredRelocateProtocolKind(source, constants, upvalues) then
                    return {
                        Dispatcher = object,
                        OriginalPop = upvalues[6],
                        Capability = upvalues[7],
                    }, nil
                end
            end
        end
        if index % 500 == 0 then
            task.wait()
        end
    end
    return nil, "Authenticated relocate dispatcher unavailable"
end

function ExperimentalFly:_restoreDispatcher()
    local dispatcher = self.Dispatcher
    local originalPop = self.OriginalPop
    local wrappedPop = self.WrappedPop
    self.PendingComponents = nil
    self.PendingOwner = nil
    self.RagdollSuppressedUntil = 0
    if type(dispatcher) == "function"
        and type(originalPop) == "function"
        and type(debug) == "table"
        and type(debug.getupvalues) == "function"
        and type(debug.setupvalue) == "function" then
        local ok, upvalues = pcall(debug.getupvalues, dispatcher)
        if ok and type(upvalues) == "table" and upvalues[6] == wrappedPop then
            pcall(debug.setupvalue, dispatcher, 6, originalPop)
        end
    end
    self.Dispatcher = nil
    self.OriginalPop = nil
    self.WrappedPop = nil
    self.Capability = nil
end

function ExperimentalFly:acquireRelay(owner)
    owner = tostring(owner or "unknown")
    if self.Consumers[owner] then
        return true, "Authenticated relocate relay already active"
    end
    if not self.Dispatcher then
        local protocol, protocolReason = self:_findDispatcher()
        if not protocol then
            return false, protocolReason
        end
        self.Dispatcher = protocol.Dispatcher
        self.OriginalPop = protocol.OriginalPop
        self.Capability = protocol.Capability
        self.WrappedPop = function(capability)
            local action, arguments, remaining = consumeExperimentalRelocate(
                self.PendingComponents,
                self.OriginalPop,
                capability
            )
            self.PendingComponents = remaining
            if remaining == nil then
                self.PendingOwner = nil
            end
            action, arguments = filterGodmodeRegisteredAction(
                action,
                arguments,
                self.RagdollSuppressedUntil > os.clock()
            )
            return action, arguments
        end
        local setOk, setError = pcall(debug.setupvalue, self.Dispatcher, 6, self.WrappedPop)
        if not setOk then
            self:_restoreDispatcher()
            return false, tostring(setError)
        end
        local upvaluesOk, upvalues = pcall(debug.getupvalues, self.Dispatcher)
        if not upvaluesOk or type(upvalues) ~= "table" or upvalues[6] ~= self.WrappedPop then
            self:_restoreDispatcher()
            return false, "Relocate action hook verification failed"
        end
    end
    self.Consumers[owner] = true
    return true, "Authenticated relocate relay active"
end

function ExperimentalFly:suppressRagdoll(seconds)
    self.RagdollSuppressedUntil = math.max(
        self.RagdollSuppressedUntil,
        os.clock() + math.clamp(tonumber(seconds) or 0.75, 0.1, 1.5)
    )
end

function ExperimentalFly:releaseRelay(owner)
    self.Consumers[tostring(owner or "unknown")] = nil
    if next(self.Consumers) == nil then
        self:_restoreDispatcher()
    end
end

function ExperimentalFly:queueRelocate(owner, targetCFrame)
    owner = tostring(owner or "unknown")
    if not self.Consumers[owner] or typeof(targetCFrame) ~= "CFrame" then
        return false
    end
    if self.PendingOwner == "godmode" and owner ~= "godmode" then
        return false
    end
    self.PendingComponents = {targetCFrame:GetComponents()}
    self.PendingOwner = owner
    return true
end

function ExperimentalFly:disable(reason)
    self.Enabled = false
    if self.Connection then
        self.Connection:Disconnect()
        self.Connection = nil
    end
    self:releaseRelay("manual_fly")
    if self.Runtime.Destroyed then
        table.clear(self.Consumers)
        self:_restoreDispatcher()
    end
    self.Runtime:setStatus("experimental_fly", "Disabled", reason or "Off")
    return true, reason or "Experimental Fly disabled"
end

function ExperimentalFly:_step(deltaTime)
    if not self.Enabled or self.Runtime.Destroyed or self.Runtime.Busy then
        return
    end
    local ready, reason = self.Movement:status()
    if not ready then
        self:disable(reason)
        return
    end
    local root = self.Movement:getRoot()
    local camera = workspace.CurrentCamera
    if not root or not camera then
        self:disable("Character or camera unavailable")
        return
    end

    local look = camera.CFrame.LookVector
    look = Vector3.new(look.X, 0, look.Z)
    look = look.Magnitude > 0.001 and look.Unit or Vector3.new(0, 0, -1)
    local right = camera.CFrame.RightVector
    right = Vector3.new(right.X, 0, right.Z)
    right = right.Magnitude > 0.001 and right.Unit or Vector3.new(1, 0, 0)
    local direction = Vector3.zero
    if self.Input:IsKeyDown(Enum.KeyCode.W) then direction += look end
    if self.Input:IsKeyDown(Enum.KeyCode.S) then direction -= look end
    if self.Input:IsKeyDown(Enum.KeyCode.D) then direction += right end
    if self.Input:IsKeyDown(Enum.KeyCode.A) then direction -= right end
    if direction.Magnitude > 1 then direction = direction.Unit end

    local vertical = 0
    if self.Input:IsKeyDown(Enum.KeyCode.Space) then vertical += 1 end
    if self.Input:IsKeyDown(Enum.KeyCode.LeftShift)
        or self.Input:IsKeyDown(Enum.KeyCode.RightShift) then
        vertical -= 1
    end
    if direction.Magnitude <= 0.001 and vertical == 0 then
        return
    end

    local dt = math.clamp(tonumber(deltaTime) or 0, 1 / 240, 1 / 20)
    local displacement = direction * self.Speed * dt
        + Vector3.new(0, vertical * self.VerticalSpeed * dt, 0)
    self:queueRelocate("manual_fly", root.CFrame + displacement)
end

function ExperimentalFly:enable()
    if self.Enabled then
        return true, "Experimental Fly already enabled"
    end
    local ready, reason = self.Movement:refresh(true)
    if not ready then
        return false, reason
    end
    local relayReady, relayReason = self:acquireRelay("manual_fly")
    if not relayReady then
        return false, relayReason
    end
    self.Enabled = true
    self.Connection = RunService.Heartbeat:Connect(function(deltaTime)
        self:_step(deltaTime)
    end)
    self.Runtime:setStatus("experimental_fly", "Running", "WASD + Space/Shift")
    return true, "Experimental Fly enabled"
end

function ExperimentalFly:setEnabled(enabled)
    if enabled == true then
        return self:enable()
    end
    return self:disable("Off")
end

local experimentalFly = ExperimentalFly.new(runtime, movement)
runtime.ExperimentalFly = experimentalFly

local Godmode = {}
Godmode.__index = Godmode

function Godmode.new(owner, gameState, networkBroker, relay, transport)
    return setmetatable({
        Runtime = owner,
        State = gameState,
        Broker = networkBroker,
        Relay = relay,
        Movement = transport,
        Enabled = false,
        Component = nil,
        RestoreDeadline = nil,
        AreaConnection = nil,
        CarryConnection = nil,
        RagdollConnection = nil,
        ActiveCarry = nil,
        RegrabAttempts = 0,
    }, Godmode)
end

function Godmode:_findForestComponent()
    if type(getgc) ~= "function" then
        return nil, "Executor object graph unavailable"
    end
    local ok, objects = pcall(getgc, true)
    if not ok or type(objects) ~= "table" then
        return nil, "Executor object graph unavailable"
    end
    for index, candidate in ipairs(objects) do
        if type(candidate) == "table"
            and rawget(candidate, "_areaId") == "Forest"
            and type(rawget(candidate, "_attackHandler")) == "function" then
            local guardModel = rawget(candidate, "_guardModel")
            local metatable = getmetatable(candidate)
            if typeof(guardModel) == "Instance"
                and guardModel:IsA("Model")
                and guardModel.Name == "Guard"
                and guardModel.Parent ~= nil
                and guardModel.Parent.Name == "Forest"
                and type(metatable) == "table"
                and rawget(metatable, "__class") == "GuardComponent" then
                return candidate, nil
            end
        end
        if index % 3000 == 0 then
            task.wait()
        end
    end
    return nil, "Live Forest guard component unavailable"
end

function Godmode:_restoreForestComponent()
    if self.Component then
        setForestGuardAttackPaused(self.Component, false, self.RestoreDeadline)
    end
    self.Component = nil
    self.RestoreDeadline = nil
end

function Godmode:_bindForestComponent()
    self:_restoreForestComponent()
    local component, reason = self:_findForestComponent()
    if not component then
        return false, reason
    end
    local changed, previous = setForestGuardAttackPaused(component, true)
    if not changed then
        return false, "Forest guard attack state could not be paused"
    end
    self.Component = component
    self.RestoreDeadline = previous
    return true, nil
end

function Godmode:_isHome()
    local root = self.Movement:getRoot()
    local plot = self.State:getPlotCenter()
    if not root or typeof(plot) ~= "CFrame" then
        return false
    end
    local offset = root.Position - plot.Position
    return Vector2.new(offset.X, offset.Z).Magnitude <= 35
end

function Godmode:_slotKey(uid)
    for _, record in ipairs(self.State:getAreaRecords(false)) do
        if record.Uid == uid then
            return self.State:buildSlotKey(record)
        end
    end
    return nil
end

function Godmode:_clearCarry()
    self.ActiveCarry = nil
    self.RegrabAttempts = 0
end

function Godmode:_recoverDropped(active)
    if not self.Enabled or self.Runtime.Destroyed or self.ActiveCarry ~= active then
        return
    end
    local action = godmodeRecoveryDecision(
        self.Enabled,
        active.Uid,
        active.AreaId,
        false,
        false,
        false,
        self:_isHome(),
        self.RegrabAttempts
    )
    if action ~= "regrab" then
        self:_clearCarry()
        return
    end
    self.RegrabAttempts += 1
    local currentRagdoll = tonumber(LocalPlayer:GetAttribute("RagdollEndTime")) or 0
    active.RagdollBaseline = currentRagdoll
    self.Relay:suppressRagdoll(0.9)
    local root = self.Movement:getRoot()
    if root then
        self.Relay:queueRelocate("godmode", root.CFrame)
        local velocity = root.AssemblyLinearVelocity
        root.AssemblyLinearVelocity = Vector3.new(0, velocity.Y, 0)
        root.AssemblyAngularVelocity = Vector3.zero
    end
    local transportOk, serverOk, serverReason = self.State:callEggCommand(
        "RequestCarryAreaEgg",
        "EggCarry",
        {buildEggCarryPayload(active.Uid, active.FirstAreaSlotKey)},
        active.Uid,
        active.FirstAreaSlotKey
    )
    local accepted, rejection = classifyRemoteResponse(transportOk, serverOk, serverReason)
    if accepted then
        self.Runtime:setStatus("godmode", "Recovered", "Boss hit cancelled; egg re-carried")
        return
    end
    self.Runtime:setStatus("godmode", "Recovery failed", tostring(rejection))
    self:_clearCarry()
end

function Godmode:_onCarryState(carryState)
    if not self.Enabled or type(carryState) ~= "table" then
        return
    end
    if carryState.IsCarrying == true and type(carryState.Uid) == "string" then
        if not self.ActiveCarry or self.ActiveCarry.Uid ~= carryState.Uid then
            self.ActiveCarry = {
                Uid = carryState.Uid,
                AreaId = carryState.AreaId,
                FirstAreaSlotKey = self:_slotKey(carryState.Uid),
                RagdollBaseline = tonumber(LocalPlayer:GetAttribute("RagdollEndTime")) or 0,
            }
            self.RegrabAttempts = 0
        end
        return
    end
    local active = self.ActiveCarry
    if active and active.AreaId ~= "Forest" then
        self.Relay:suppressRagdoll(0.9)
        task.spawn(self._recoverDropped, self, active)
    elseif active then
        self:_clearCarry()
    end
end

function Godmode:enable()
    if self.Enabled then
        return true, "Godmode already enabled"
    end
    local relayReady, relayReason = self.Relay:acquireRelay("godmode")
    if not relayReady then
        return false, relayReason
    end
    local bound, reason = self:_bindForestComponent()
    self.Enabled = true
    local guardAreas = workspace:FindFirstChild("__OBJECTS")
    guardAreas = guardAreas and guardAreas:FindFirstChild("Areas")
    guardAreas = guardAreas and guardAreas:FindFirstChild("GuardAreas")
    if guardAreas then
        self.AreaConnection = guardAreas.ChildAdded:Connect(function(area)
            if area.Name == "Forest" then
                task.delay(0.75, function()
                    if self.Enabled and not self.Runtime.Destroyed then
                        local rebound, reboundReason = self:_bindForestComponent()
                        self.Runtime:setStatus(
                            "godmode",
                            rebound and "Running" or "Unavailable",
                            rebound and "Forest chicken attack paused" or tostring(reboundReason)
                        )
                    end
                end)
            end
        end)
    end
    local eggCmds = self.State.Modules.EggCmds
    local carrySignal = type(eggCmds) == "table" and eggCmds.AreaEggCarryStateChanged or nil
    if type(carrySignal) ~= "table" or type(carrySignal.Connect) ~= "function" then
        if self.AreaConnection then
            self.AreaConnection:Disconnect()
            self.AreaConnection = nil
        end
        self:_restoreForestComponent()
        self.Relay:releaseRelay("godmode")
        self.Enabled = false
        return false, "Area egg carry signal unavailable"
    end
    self.CarryConnection = carrySignal:Connect(function(carryState)
        self:_onCarryState(carryState)
    end)
    self.RagdollConnection = LocalPlayer:GetAttributeChangedSignal("RagdollEndTime"):Connect(function()
        local active = self.ActiveCarry
        if self.Enabled and active and active.AreaId ~= "Forest" then
            local deadline = tonumber(LocalPlayer:GetAttribute("RagdollEndTime")) or 0
            if deadline > (tonumber(active.RagdollBaseline) or 0) then
                self.Relay:suppressRagdoll(0.9)
            end
        end
    end)
    self:_onCarryState(self.State.LastCarryState)
    self.Runtime:setStatus(
        "godmode",
        "Running",
        bound and "All bosses; Forest paused, server-hit recovery armed" or "All bosses; server-hit recovery armed"
    )
    return true, bound and "Godmode enabled for all bosses" or ("Godmode enabled; " .. tostring(reason))
end

function Godmode:disable(reason)
    self.Enabled = false
    if self.AreaConnection then
        self.AreaConnection:Disconnect()
        self.AreaConnection = nil
    end
    if self.CarryConnection then
        self.CarryConnection:Disconnect()
        self.CarryConnection = nil
    end
    if self.RagdollConnection then
        self.RagdollConnection:Disconnect()
        self.RagdollConnection = nil
    end
    self:_clearCarry()
    self:_restoreForestComponent()
    self.Relay:releaseRelay("godmode")
    self.Runtime:setStatus("godmode", "Disabled", reason or "Off")
    return true, reason or "Godmode disabled"
end

function Godmode:setEnabled(enabled)
    if enabled == true then
        return self:enable()
    end
    return self:disable("Off")
end

local godmode = Godmode.new(runtime, state, broker, experimentalFly, movement)
runtime.Godmode = godmode

local EggAutomation = {}
EggAutomation.__index = EggAutomation

function EggAutomation.new(owner, gameState, networkBroker, navigator)
    return setmetatable({
        Runtime = owner,
        State = gameState,
        Broker = networkBroker,
        Movement = navigator,
        LastTarget = nil,
        LastCarryReason = nil,
        TreadmillRecoveryInFlight = false,
        LastTreadmillReleaseOk = nil,
        LastTreadmillReleaseReason = nil,
        TreadmillAnchorConnection = nil,
        TreadmillWatchStarted = false,
        PlacementSlotIndex = 1,
        PlotFullUntil = 0,
    }, EggAutomation)
end

function EggAutomation:_recordByUid(uid, refresh)
    for _, record in ipairs(self.State:getAreaRecords(refresh)) do
        if record.Uid == uid then
            return record
        end
    end
    return nil
end

function EggAutomation:_targetCFrame(candidate)
    local record = candidate and candidate.Record
    if type(record) ~= "table" then
        return nil
    end
    local liveCFrame = self.State:getLiveEggCFrame(candidate.LiveModel)
    local cframe = liveCFrame or candidate.LiveCFrame or record.BottomCFrame or record.BoundsCFrame
    if typeof(cframe) ~= "CFrame" then
        return nil
    end
    local offset = clampFinite(self.Runtime.Config.Egg.CarryOffset, 1, 8, 3.25)
    return cframe + Vector3.new(0, offset, 0)
end

function EggAutomation:selectTarget(refresh)
    local config = self.Runtime.Config.Egg
    local targetAreas = self.State:getTargetAreas(config.SelectedAreas)
    local candidates = self.State:eggCandidates(targetAreas, config.MinimumRarity, refresh ~= false)
    if #candidates == 0 and next(self.State:getLiveAreaEggModels()) ~= nil then
        self.State.LastAreaRefreshAt = -math.huge
        candidates = self.State:eggCandidates(targetAreas, config.MinimumRarity, true)
    end
    local eligible = {}
    local visibleFallbacks = {}
    local save = self.State:getSave()
    local currentClaims = type(save.CurrentAreaEggClaims) == "table"
        and save.CurrentAreaEggClaims
        or {}
    local claimedSlots = type(currentClaims.Slots) == "table" and currentClaims.Slots or {}
    for _, candidate in ipairs(candidates) do
        local record = type(candidate.Record) == "table" and candidate.Record or {}
        local naturalSlotKey = candidate.AreaId and record.NestId
            and (tostring(candidate.AreaId) .. ":" .. tostring(record.NestId))
            or nil
        local alreadyClaimed = naturalSlotKey ~= nil and claimedSlots[naturalSlotKey] == true
        if alreadyClaimed then
            continue
        elseif candidate.SnapshotMissing == true then
            visibleFallbacks[#visibleFallbacks + 1] = candidate
        elseif eggCandidateMatchesPolicy(candidate, config) then
            eligible[#eligible + 1] = candidate
        end
    end
    if #eligible == 0 then
        eligible = visibleFallbacks
    end
    return chooseEggCandidate(eligible, config.TargetMode), #eligible, #targetAreas
end

function EggAutomation:_horizontalDistance(left, right)
    local delta = left - right
    return Vector3.new(delta.X, 0, delta.Z).Magnitude
end

function EggAutomation:_gatewayCFrame()
    local _, gameplayLine = self.Movement:_boundaryParts()
    if not gameplayLine then
        return nil
    end
    local offset = clampFinite(self.Runtime.Config.Egg.CarryOffset, 1, 8, 3.25)
    return CFrame.new(gameplayLine.Position + Vector3.new(0, offset, 0))
end

function EggAutomation:_moveCarriedLeg(targetCFrame, cancellation, options)
    options = type(options) == "table" and options or {}
    if options.UseRagdoll == true then
        local registeredMoved, registeredReason = self.Movement:moveTo(
            targetCFrame,
            cancellation,
            options
        )
        if registeredMoved then
            self.LastCarryTransport = "authenticated ragdoll transport"
            return true, registeredReason
        end
        if self.Runtime.Destroyed
            or (type(cancellation) == "function" and cancellation()) then
            return false, registeredReason
        end
    end

    local moved, reason = self.Movement:_sendFloorGlide(targetCFrame, cancellation, options)
    if moved then
        self.LastCarryTransport = "rollback-bypassed floor glide"
        return true, reason
    end
    if self.Runtime.Destroyed
        or (type(cancellation) == "function" and cancellation()) then
        return false, reason
    end
    local acceptNearRadius = tonumber(options.AcceptNearRadius)
    local nearRoot = self.Movement:getRoot()
    if acceptNearRadius and acceptNearRadius > 0 and nearRoot then
        local remaining = self:_horizontalDistance(nearRoot.Position, targetCFrame.Position)
        if remaining <= acceptNearRadius then
            self.LastCarryTransport = "rollback-bypassed floor glide"
            return true, string.format("Floor glide reached the safe lane within %.1f studs", remaining)
        end
    end
    self.LastCarryTransport = "floor glide stopped safely"
    return false, reason
end

function EggAutomation:_isHome(plotCFrame)
    local root = self.Movement:getRoot()
    if not root then
        return false
    end
    if self:_horizontalDistance(root.Position, plotCFrame.Position) <= 35 then
        return true
    end
    local _, gameplayLine = self.Movement:_boundaryParts()
    return gameplayLine ~= nil
        and (root.Position.X - gameplayLine.Position.X)
            * (plotCFrame.Position.X - gameplayLine.Position.X) > 0
end

function EggAutomation:_waitForHome(plotCFrame, timeoutSeconds)
    local deadline = os.clock() + (tonumber(timeoutSeconds) or 3)
    while os.clock() < deadline do
        if self:_isHome(plotCFrame) then
            return true
        end
        task.wait(0.02)
    end
    return self:_isHome(plotCFrame)
end

function EggAutomation:_waitForPlotProximity(plotCFrame, timeoutSeconds)
    local deadline = os.clock() + (tonumber(timeoutSeconds) or 3)
    while os.clock() < deadline do
        local root = self.Movement:getRoot()
        if root and self:_horizontalDistance(root.Position, plotCFrame.Position) <= 35 then
            return true
        end
        task.wait(0.08)
    end
    return false
end

function EggAutomation:_isTreadmillAnchor(root)
    if not root or not root.Parent or root.Anchored ~= true then
        return false
    end
    if self.Runtime.Session.TreadmillActive == true then
        return true
    end
    for _, obstacle in ipairs(self.State:getTreadmillObstaclePositions()) do
        if (root.Position - obstacle).Magnitude <= 14 then
            return true
        end
    end
    return false
end

function EggAutomation:_forceTreadmillMobility(root)
    root = root or self.Movement:getRoot()
    local humanoid = root and root.Parent and root.Parent:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid or humanoid.Health <= 0 then
        return false
    end
    pcall(function()
        root.Anchored = false
        humanoid.Sit = false
        humanoid.Jump = false
        humanoid:ChangeState(Enum.HumanoidStateType.Running)
        local velocity = root.AssemblyLinearVelocity
        root.AssemblyLinearVelocity = Vector3.new(velocity.X, math.min(velocity.Y, 0), velocity.Z)
        root.AssemblyAngularVelocity = Vector3.zero
    end)
    return root.Anchored ~= true
end

function EggAutomation:recoverTreadmillAnchor(root, force)
    root = root or self.Movement:getRoot()
    local features = self.Runtime.Config.Features or {}
    if force ~= true and features.steal_best_egg ~= true then
        return false, "Auto-steal treadmill watchdog is idle"
    end

    if force == true and self.TreadmillRecoveryInFlight then
        local deadline = os.clock() + 0.75
        repeat
            self:_forceTreadmillMobility(root)
            RunService.Heartbeat:Wait()
        until self.Runtime.Destroyed
            or not self.TreadmillRecoveryInFlight
            or os.clock() >= deadline
        if self.TreadmillRecoveryInFlight then
            return false, "Treadmill server release is still pending"
        end
        if self.LastTreadmillReleaseOk == true then
            return true, self.LastTreadmillReleaseReason or "Treadmill released"
        end
        return false, self.LastTreadmillReleaseReason or "Treadmill server release failed"
    end

    if not self:_isTreadmillAnchor(root) then
        return false, "Character is not treadmill-anchored"
    end

    self:_forceTreadmillMobility(root)
    self.TreadmillRecoveryInFlight = true
    self.LastTreadmillReleaseOk = nil
    self.LastTreadmillReleaseReason = "Treadmill server release pending"
    self.Runtime:setStatus("treadmill_train", "Releasing", "Clearing treadmill before Auto Steal")

    local function requestServerRelease()
        local callResults = pack(pcall(
            self.State.callCurrentRemote,
            self.State,
            {"Treadmill", "AskDoff"},
            "TreadmillUnequip",
            {}
        ))
        local released
        local releaseReason
        if callResults[1] then
            released, releaseReason = classifyTreadmillUnequip(
                callResults[2],
                callResults[3],
                callResults[4]
            )
        else
            released = false
            releaseReason = tostring(callResults[2])
        end

        local holdDeadline = os.clock() + 0.35
        repeat
            self:_forceTreadmillMobility(root)
            RunService.Heartbeat:Wait()
        until self.Runtime.Destroyed or not root or not root.Parent or os.clock() >= holdDeadline

        if released then
            self.Runtime.Session.TreadmillActive = false
            self.LastTreadmillReleaseReason = "Treadmill server release confirmed"
            self.Runtime:setStatus("treadmill_train", "Recovered", self.LastTreadmillReleaseReason)
        else
            self.LastTreadmillReleaseReason = "Treadmill release failed: " .. tostring(releaseReason)
            self.Runtime:setStatus("treadmill_train", "Blocked", self.LastTreadmillReleaseReason)
        end
        self.LastTreadmillReleaseOk = released
        self.TreadmillRecoveryInFlight = false
        return released, self.LastTreadmillReleaseReason
    end

    if force == true then
        return requestServerRelease()
    end
    task.spawn(requestServerRelease)
    return true, "Treadmill anchor released locally; server release pending"
end

function EggAutomation:startTreadmillAntiStuck()
    if self.TreadmillWatchStarted then
        return
    end
    self.TreadmillWatchStarted = true

    local function bindCharacter(character)
        if self.TreadmillAnchorConnection then
            self.TreadmillAnchorConnection:Disconnect()
            self.TreadmillAnchorConnection = nil
        end
        if not character then
            return
        end
        task.spawn(function()
            local root = character:FindFirstChild("HumanoidRootPart")
                or character:WaitForChild("HumanoidRootPart", 5)
            if self.Runtime.Destroyed or LocalPlayer.Character ~= character or not root then
                return
            end
            local connection = root:GetPropertyChangedSignal("Anchored"):Connect(function()
                if root.Anchored then
                    task.defer(function()
                        self:recoverTreadmillAnchor(root, false)
                    end)
                end
            end)
            self.TreadmillAnchorConnection = connection
            self.Runtime:track(connection)
            if root.Anchored then
                task.defer(function()
                    self:recoverTreadmillAnchor(root, false)
                end)
            end
        end)
    end

    self.Runtime:track(LocalPlayer.CharacterAdded:Connect(bindCharacter))
    bindCharacter(LocalPlayer.Character)
    self.Runtime:spawn("treadmill-anti-stuck", 0.03, function()
        self:recoverTreadmillAnchor(nil, false)
    end)
end

function EggAutomation:_releaseTreadmillIfNeeded(root)
    root = root or self.Movement:getRoot()
    if self.TreadmillRecoveryInFlight then
        local released, releaseReason = self:recoverTreadmillAnchor(root, true)
        return released, true, releaseReason
    end
    local humanoid = root and root.Parent and root.Parent:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health <= 0 then
        return true, false, "Dead character recovery pending"
    end
    if self:_isTreadmillAnchor(root) then
        local recovered, recoveryReason = self:recoverTreadmillAnchor(root, true)
        return recovered, true, recoveryReason
    end
    local distanceToStand = math.huge
    if root then
        for _, obstacle in ipairs(self.State:getTreadmillObstaclePositions()) do
            distanceToStand = math.min(distanceToStand, (root.Position - obstacle).Magnitude)
        end
    end
    local releaseAction = treadmillReleaseDecision(
        self.Runtime.Session.TreadmillActive,
        root and root.Anchored,
        distanceToStand
    )
    if releaseAction == "skip" then
        return true, false, "Treadmill release not needed"
    end

    if releaseAction == "recover" then
        local recovered, recoveryReason = self:recoverTreadmillAnchor(root, true)
        return recovered, true, recoveryReason
    end

    local unequipTransport, unequipServer, unequipReason = self.State:callCurrentRemote(
        {"Treadmill", "AskDoff"},
        "TreadmillUnequip",
        {}
    )
    local unequipped, unequipError = classifyTreadmillUnequip(
        unequipTransport,
        unequipServer,
        unequipReason
    )
    if not unequipped then
        return false, true, "Treadmill release failed: " .. tostring(unequipError)
    end
    self.Runtime.Session.TreadmillActive = false

    local deadline = os.clock() + 0.8
    while root and root.Parent and root.Anchored and os.clock() < deadline do
        task.wait(0.03)
    end
    if root and root.Parent and root.Anchored then
        self.Broker:call("LobbyTeleport")
        return false, true, "Treadmill released; waiting for lobby recovery"
    end
    return true, true, "Treadmill released"
end

function EggAutomation:_escapeAfterCarry(plotCFrame, carryState)
    local configuredSpeed = customStealSpeed((self.Runtime.Config.Egg or {}).CustomStealSpeed)
    local root = self.Movement:getRoot()
    if root and self:_horizontalDistance(root.Position, plotCFrame.Position) <= 30 then
        return true, "Already at plot"
    end
    local returnSpeed = configuredSpeed > 0
        and configuredSpeed
        or self.State:getCarryTransportCruiseSpeed(carryState)
    local gatewayCFrame = self:_gatewayCFrame()
    if not gatewayCFrame then
        return false, "Gameplay gateway unavailable"
    end
    local carriedUid = type(carryState) == "table" and carryState.Uid or nil
    local carriedSlotKey = type(carryState) == "table"
        and carryState.FirstAreaSlotKey
        or nil
    local carrySequence = self.State.CarryStateSequence
    local carryLost = false
    local carryRefreshAttempts = 0
    local function cancelIfCarryLost()
        if carriedUid == nil or self.State.CarryStateSequence <= carrySequence then
            return false
        end
        if carryStateDisposition(self.State.LastCarryState, carriedUid) == "ready" then
            return false
        end
        if self:_isHome(plotCFrame) then
            return false
        end

        if carriedSlotKey ~= nil and carryRefreshAttempts < 2 then
            carryRefreshAttempts += 1
            local refreshSequence = self.State:beginCarryAwait()
            local transportOk, serverOk, serverReason = self.State:callEggCommand(
                "RequestCarryAreaEgg",
                "EggCarry",
                {buildEggCarryPayload(carriedUid, carriedSlotKey)},
                carriedUid,
                carriedSlotKey
            )
            local refreshed, refreshReason = classifyRemoteResponse(
                transportOk,
                serverOk,
                serverReason
            )
            self.LastCarryRefreshAttempts = carryRefreshAttempts
            self.LastCarryRefreshReason = refreshed
                and "Carry reasserted during escape"
                or tostring(refreshReason)
            if refreshed then
                carrySequence = refreshSequence
                return false
            end
        end
        carryLost = true
        return true
    end

    root = self.Movement:getRoot()
    if not root then
        return false, "Character unavailable for center-lane escape"
    end

    local laneCenterZ = gatewayCFrame.Position.Z
    local centerLaneEntry = CFrame.new(
        root.Position.X,
        root.Position.Y,
        laneCenterZ
    )
    local sideSign = root.Position.X >= gatewayCFrame.Position.X and 1 or -1
    local margin = clampFinite(self.Runtime.Config.Movement.SafeCorridorMargin, 10, 40, 18)
    local centerGatewayApproach = CFrame.new(
        gatewayCFrame.Position.X + sideSign * margin,
        gatewayCFrame.Position.Y,
        laneCenterZ
    )
    local centerAlignSpeed = configuredSpeed > 0
        and configuredSpeed
        or math.max(returnSpeed, 2400)

    local centered, centerReason = self:_moveCarriedLeg(
        centerLaneEntry,
        cancelIfCarryLost,
        {
            CruiseSpeed = centerAlignSpeed,
            WalkSpeed = centerAlignSpeed,
            AllowCustomSpeed = true,
            UseRagdoll = false,
            StayGrounded = true,
            TimeoutSeconds = 1,
            ArrivalRadius = 2,
        }
    )
    if carryLost then
        return false, "Carry lost while entering the center lane"
    end
    if not centered then
        return false, "Center-lane entry failed: " .. tostring(centerReason)
    end

    local laneReached, laneReason = self:_moveCarriedLeg(
        centerGatewayApproach,
        cancelIfCarryLost,
        {
            CruiseSpeed = returnSpeed,
            WalkSpeed = returnSpeed,
            AllowCustomSpeed = true,
            UseRagdoll = false,
            StayGrounded = true,
            TimeoutSeconds = 8,
            ArrivalRadius = 12,
            AcceptNearRadius = 20,
        }
    )
    if carryLost then
        return false, "Carry lost along the center lane"
    end
    if not laneReached then
        return false, "Center-lane return failed: " .. tostring(laneReason)
    end

    local gatewayReached, gatewayReason = self:_moveCarriedLeg(
        gatewayCFrame,
        cancelIfCarryLost,
        {
        CruiseSpeed = returnSpeed,
        WalkSpeed = returnSpeed,
        AllowCustomSpeed = true,
        UseRagdoll = false,
        StayGrounded = true,
        TimeoutSeconds = 6,
        ArrivalRadius = 3,
    })
    if carryLost then
        return false, "Carry lost during escape"
    end
    if not gatewayReached then
        return false, "Gateway return failed: " .. tostring(gatewayReason)
    end
    local plotReached, plotReason = self:_moveCarriedLeg(
        plotCFrame + Vector3.new(0, 3.25, 0),
        cancelIfCarryLost,
        {
        CruiseSpeed = returnSpeed,
        WalkSpeed = returnSpeed,
        AllowCustomSpeed = true,
        UseRagdoll = false,
        StayGrounded = true,
        TimeoutSeconds = 6,
        ArrivalRadius = 12,
    })
    if carryLost then
        return false, "Carry lost during escape"
    end
    return plotReached, plotReason
end

function EggAutomation:_moveToTarget(targetCFrame, timeoutSeconds, arrivalRadius, areaId)
    local eggConfig = self.Runtime.Config.Egg or {}
    local configuredSpeed = customStealSpeed(eggConfig.CustomStealSpeed)
    local arrival = clampFinite(arrivalRadius or eggConfig.StealArrivalRadius, 0.5, 2, 2)
    local timeout = clampFinite(timeoutSeconds or eggConfig.StealTimeoutSeconds, 2, 30, 10)
    local cruise = configuredSpeed > 0
        and configuredSpeed
        or self.State:getTransportCruiseSpeed()

    local gatewayCFrame = self:_gatewayCFrame()
    if not gatewayCFrame then
        return false, "Gameplay gateway unavailable"
    end
    local gatewayReached, gatewayReason = self.Movement:moveTo(gatewayCFrame, nil, {
        CruiseSpeed = cruise,
        WalkSpeed = cruise,
        AllowCustomSpeed = true,
        UseRagdoll = registeredRagdollForSpeed(cruise),
        TimeoutSeconds = 6,
        ArrivalRadius = 3,
    })
    if not gatewayReached then
        return false, "Gateway exit failed: " .. tostring(gatewayReason)
    end
    local sideSign = targetCFrame.Position.X >= gatewayCFrame.Position.X and 1 or -1
    local margin = clampFinite(self.Runtime.Config.Movement.SafeCorridorMargin, 10, 40, 18)
    local laneCenterZ = gatewayCFrame.Position.Z
    local gameplayApproach = CFrame.new(
        gatewayCFrame.Position.X + sideSign * margin,
        gatewayCFrame.Position.Y,
        laneCenterZ
    )
    local entered, enterReason = self.Movement:moveTo(gameplayApproach, nil, {
        CruiseSpeed = cruise,
        WalkSpeed = cruise,
        AllowCustomSpeed = true,
        UseRagdoll = registeredRagdollForSpeed(cruise),
        StayGrounded = true,
        TimeoutSeconds = 2,
        ArrivalRadius = 2,
    })
    if not entered then
        return false, "Gameplay-side gateway entry failed: " .. tostring(enterReason)
    end

    local centerLaneTarget = CFrame.new(
        targetCFrame.Position.X,
        gatewayCFrame.Position.Y,
        laneCenterZ
    )
    local laneReached, laneReason = self.Movement:moveTo(centerLaneTarget, nil, {
        CruiseSpeed = cruise,
        WalkSpeed = cruise,
        AllowCustomSpeed = true,
        UseRagdoll = registeredRagdollForSpeed(cruise),
        StayGrounded = true,
        TimeoutSeconds = 8,
        ArrivalRadius = 3,
    })
    if not laneReached then
        return false, "Center-lane approach failed: " .. tostring(laneReason)
    end

    if type(areaId) == "string" and areaId ~= "" then
        task.wait(0.8)
    end

    local targetReached, targetReason = self.Movement:moveTo(targetCFrame, nil, {
        CruiseSpeed = cruise,
        WalkSpeed = cruise,
        AllowCustomSpeed = true,
        UseRagdoll = registeredRagdollForSpeed(cruise),
        StayGrounded = true,
        TimeoutSeconds = timeout,
        ArrivalRadius = arrival,
    })
    if targetReached then
        task.wait(0.02)
    end
    return targetReached, targetReason
end

function EggAutomation:_settleAtPickup(targetCFrame)
    local root = self.Movement:getRoot()
    if not root then
        return false, "Character unavailable at pickup"
    end

    local eggConfig = self.Runtime.Config.Egg or {}
    local configuredSpeed = customStealSpeed(eggConfig.CustomStealSpeed)
    local approachSpeed = configuredSpeed > 0 and math.min(configuredSpeed, 300) or 300
    local settled, settleReason = self.Movement:moveTo(targetCFrame, nil, {
        CruiseSpeed = approachSpeed,
        WalkSpeed = approachSpeed,
        AllowCustomSpeed = true,
        UseRagdoll = false,
        StayGrounded = true,
        TimeoutSeconds = 2,
        ArrivalRadius = 1.25,
    })
    if not settled then
        return false, "Pickup stabilization failed: " .. tostring(settleReason)
    end

    root = self.Movement:getRoot()
    if not root
        or self:_horizontalDistance(root.Position, targetCFrame.Position) > 3
        or math.abs(root.Position.Y - targetCFrame.Position.Y) > 10 then
        return false, "Character did not stabilize beside the egg"
    end
    root.AssemblyAngularVelocity = Vector3.zero
    return true, nil
end

function EggAutomation:_acquireConfirmedCarry(candidate, slotKey, targetCFrame, plotCFrame)
    local liveTarget = self:_targetCFrame(candidate) or targetCFrame
    if candidate.LiveModel and not candidate.LiveModel.Parent then
        self.LastPickupAttempts = 0
        self.LastPickupReason = "The live egg slot disappeared before pickup"
        return false, self.LastPickupReason
    end

    local settled, settleReason = self:_settleAtPickup(liveTarget)
    if not settled then
        self.LastPickupAttempts = 0
        self.LastPickupReason = settleReason
        return false, settleReason
    end

    local lastReason = "Egg pickup was rejected"
    for attempt = 1, 2 do
        local carrySequence = self.State:beginCarryAwait()
        local transportOk, serverOk, serverReason = self.State:callEggCommand(
            "RequestCarryAreaEgg",
            "EggCarry",
            {buildEggCarryPayload(candidate.Uid, slotKey)},
            candidate.Uid,
            slotKey
        )
        local accepted, rejection = classifyRemoteResponse(transportOk, serverOk, serverReason)
        if accepted then
            RunService.Heartbeat:Wait()
            local replicatedState = self.State.CarryStateSequence > carrySequence
                and self.State.LastCarryState
                or nil
            if replicatedState == nil
                or carryStateDisposition(replicatedState, candidate.Uid) == "ready" then
                self.LastPickupAttempts = attempt
                self.LastPickupReason = replicatedState
                    and "Replicated carry confirmed immediately"
                    or "Pickup accepted; confirming during escape"
                local carryState = replicatedState and table.clone(replicatedState) or {
                    IsCarrying = true,
                    Uid = candidate.Uid,
                    AreaId = candidate.AreaId,
                    FirstAreaSlotKey = slotKey,
                }
                carryState.FirstAreaSlotKey = carryState.FirstAreaSlotKey or slotKey
                self.LastReplicatedCarryState = carryState

                local returned, returnReason = self:_escapeAfterCarry(
                    plotCFrame,
                    carryState
                )
                return true, carryState, returned, returnReason
            end
            lastReason = "Boss interrupted the egg pickup"
        else
            lastReason = tostring(rejection)
        end

        if attempt == 1 then
            RunService.Heartbeat:Wait()
        end
    end
    self.LastPickupAttempts = 2
    self.LastPickupReason = lastReason
    return false, lastReason
end

function EggAutomation:stealOnce()
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local releaseOk, _, releaseReason = self:_releaseTreadmillIfNeeded(root)
    if not releaseOk then
        return false, releaseReason
    end
    local recovery = characterRecoveryDecision(character ~= nil and root ~= nil and humanoid ~= nil, humanoid and humanoid.Health, root and root.Anchored)
    if recovery == "reset" then
        return false, "Character died; waiting for Roblox respawn without rejoining"
    elseif recovery ~= "ready" then
        return false, "Character is still spawning"
    end

    local bypassReady, bypassReason = self.Movement:waitForRegistered(4)
    if not bypassReady then
        return false, bypassReason
    end

    self.State.LastAreaRefreshAt = -math.huge
    local candidate, candidateCount, targetAreaCount = self:selectTarget(true)
    if not candidate then
        if targetAreaCount == 0 then
            return false, "No target areas are selected"
        end
        return false, "No eligible live egg slots in the selected areas"
    end
    self.LastTarget = candidate
    local targetCFrame = self:_targetCFrame(candidate)
    if not targetCFrame then
        return false, "Selected egg has no replicated CFrame"
    end
    root = self.Movement:getRoot()
    if not root then
        return false, "Character unavailable"
    end
    local plotCFrame = self.State:getPlotCenter()
    if typeof(plotCFrame) ~= "CFrame" then
        return false, "Local plot center unavailable"
    end
    local slotKey = self.State:buildSlotKey(candidate.Record)
    if slotKey == nil and candidate.AreaId and candidate.Record and candidate.Record.NestId then
        slotKey = tostring(candidate.AreaId) .. ":" .. tostring(candidate.Record.NestId)
    end
    local inventoryCountBefore = #self.State:getEggInventory()
    if self.Runtime.Config.Features.treadmill_train == true then
        task.wait(0.2)
    end
    local function executeTransaction()
        local moved, moveReason = self:_moveToTarget(targetCFrame, 6, 1.5, candidate.AreaId)
        if not moved then
            return false, moveReason
        end

        local carryConfirmed, carryState, returned, returnReason = self:_acquireConfirmedCarry(
            candidate,
            slotKey,
            targetCFrame,
            plotCFrame
        )
        if not carryConfirmed then
            return false, "Egg pickup rejected: " .. tostring(carryState)
        end
        if not returned then
            return false, "Egg carried but immediate return failed: " .. tostring(returnReason)
        end

        local awardDeadline = os.clock() + 1
        repeat
            if #self.State:getEggInventory() > inventoryCountBefore then
                return true, string.format(
                    "Returned %s from %s",
                    tostring(candidate.Category),
                    tostring(candidate.AreaId)
                )
            end
            task.wait(0.05)
        until os.clock() >= awardDeadline

        return false, "Return completed but the egg was not awarded"
    end

    local results = pack(xpcall(executeTransaction, debug.traceback))
    local transactionOk = results[1] and results[2] == true
    local transactionReason = results[1] and results[3] or results[2]
    if not transactionOk then
        local recoveryOk, recoveryReason = self:_escapeAfterCarry(plotCFrame)
        if recoveryOk then
            transactionReason = tostring(transactionReason) .. " • returned to plot"
        else
            transactionReason = tostring(transactionReason)
                .. " • recovery failed: " .. tostring(recoveryReason)
        end
    end
    self.LastCarryReason = tostring(transactionReason)
    if transactionOk then
        self.Runtime.Session.EggsStolen += 1
        self.Runtime:setStatus("steal_best_egg", "Working", transactionReason)
        return true, transactionReason, candidateCount
    end
    self.Runtime:setStatus("steal_best_egg", "Rejected", transactionReason)
    return false, transactionReason
end

function EggAutomation:placeOnce()
    if os.clock() < (tonumber(self.PlotFullUntil) or 0) then
        return false, "Plot placement slots are cooling down"
    end
    local carryState = self.State.LastCarryState
    if type(carryState) == "table" and carryState.IsCarrying == true then
        return false, "Waiting for the carried egg to reach the plot"
    end
    local eggs = self.State:getEggInventory()
    if #eggs == 0 then
        return false, "Egg inventory is empty"
    end
    local placed = self.State:getPlacedEggRecords(true)
    local placedSet = {}
    for _, record in ipairs(placed) do
        placedSet[tostring(record.Uid)] = true
    end
    local unplaced = {}
    for _, egg in ipairs(eggs) do
        local uid = egg and egg.Uid
        if uid and egg.Placement == nil and not placedSet[tostring(uid)] then
            unplaced[#unplaced + 1] = egg
        end
    end
    if #unplaced == 0 then
        return false, "No unplaced carried egg is available"
    end

    local centerCFrame = self.State:getPlotCenter()
    if typeof(centerCFrame) ~= "CFrame" then
        return false, "Plot center unavailable"
    end
    local root = self.Movement:getRoot()
    local releaseOk, _, releaseReason = self:_releaseTreadmillIfNeeded(root)
    if not releaseOk then
        return false, releaseReason
    end
    root = self.Movement:getRoot()
    if not root then
        return false, "Character unavailable"
    end
    if self:_horizontalDistance(root.Position, centerCFrame.Position) > 35 then
        local returned, returnReason = self:_escapeAfterCarry(centerCFrame)
        if not returned then
            return false, returnReason
        end
    end
    local config = self.Runtime.Config.Egg
    local slots = self.State:getPlacementLocalCFrames(config.PlacementSpacing)
    if #slots == 0 then
        return false, "Plot has no usable placement slots"
    end

    local placedCount = 0
    local lastError
    local eggCmds = self.State.Modules.EggCmds
    local directPlacement = type(eggCmds) == "table" and type(eggCmds.RequestPlaceEgg) == "function"
    local slotAttemptLimit = directPlacement and #slots or math.min(#slots, 12)
    for _, target in ipairs(unplaced) do
        if self.Runtime.Destroyed then
            break
        end
        local equipTransport, equipServer, equipReason = self.State:callEggCommand(
            "RequestEquipTool",
            "EggEquip",
            {target.Uid},
            target.Uid
        )
        local equipped, equipError = classifyRemoteResponse(equipTransport, equipServer, equipReason)
        if not equipped then
            lastError = "Equip failed for " .. tostring(target.Uid) .. ": " .. tostring(equipError)
            continue
        end
        task.wait(0.04)

        local placedTarget = false
        for offset = 0, slotAttemptLimit - 1 do
            local index = ((self.PlacementSlotIndex + offset - 1) % #slots) + 1
            local localCFrame = slots[index]
            local placeTransport, placeServer, placeReason = self.State:callEggCommand(
                "RequestPlaceEgg",
                "EggPlace",
                {buildEggPlacePayload(target.Uid, localCFrame)},
                target.Uid,
                localCFrame
            )
            local accepted, rejection = classifyRemoteResponse(placeTransport, placeServer, placeReason)
            if accepted then
                self.PlacementSlotIndex = (index % #slots) + 1
                placedTarget = true
                placedCount += 1
                self.Runtime.Session.EggsPlaced += 1
                self.PlotFullUntil = 0
                task.wait(0.06)
                break
            end
            lastError = rejection
        end
        if not placedTarget then
            self.Broker:call("EggUnequip", target.Uid)
            self.PlotFullUntil = os.clock() + 2
            break
        end
    end

    if placedCount > 0 then
        local message = string.format("Placed %d egg%s", placedCount, placedCount == 1 and "" or "s")
        self.Runtime:setStatus("place_eggs", "Working", message)
        return true, message
    end
    return false, tostring(lastError or "No free plot placement slot accepted the egg")
end

function EggAutomation:hatchOnce()
    local eggCmds = self.State.Modules.EggCmds
    local readyCount = 0
    local hatchedCount = 0
    local lastError
    for _, record in ipairs(self.State:getPlacedEggRecords(true)) do
        local ready = record.Ready == true or record.IsReady == true
        if type(eggCmds) == "table" and type(eggCmds.IsLocalEggReady) == "function" then
            local ok, value = pcall(eggCmds.IsLocalEggReady, record.Uid)
            if ok and type(value) == "boolean" then
                ready = value == true
            else
                local recordOk, recordValue = pcall(eggCmds.IsLocalEggReady, record)
                if recordOk and type(recordValue) == "boolean" then
                    ready = recordValue == true
                end
            end
        end
        if ready then
            readyCount += 1
            local petCountBefore = #self.State:getInventory()
            local requestTransport, requestServer, requestReason = self.State:callEggCommand(
                "RequestHatchEgg",
                "EggHatch",
                {record.Uid},
                record.Uid
            )
            local requested, requestError = classifyRemoteResponse(requestTransport, requestServer, requestReason)
            if not requested then
                lastError = requestError
                continue
            end
            task.wait(0.03)
            local completeTransport, completeServer, completeReason = self.State:callEggCommand(
                "RequestCompleteHatchEgg",
                "EggCompleteHatch",
                {record.Uid},
                record.Uid
            )
            local completed, completeError = classifyRemoteResponse(completeTransport, completeServer, completeReason)
            if completed then
                local replicated = false
                local replicationDeadline = os.clock() + 1.25
                repeat
                    local stillPlaced = false
                    for _, current in ipairs(self.State:getPlacedEggRecords(true)) do
                        if tostring(current.Uid) == tostring(record.Uid) then
                            stillPlaced = true
                            break
                        end
                    end
                    if not stillPlaced or #self.State:getInventory() > petCountBefore then
                        replicated = true
                        break
                    end
                    task.wait(0.05)
                until os.clock() >= replicationDeadline
                if replicated then
                    hatchedCount += 1
                    self.Runtime.Session.EggsHatched += 1
                    task.wait(0.04)
                else
                    lastError = "Open request completed but the egg did not replicate as hatched"
                end
            else
                lastError = completeError
            end
        end
    end
    if hatchedCount > 0 then
        local message = string.format("Opened %d ready egg%s", hatchedCount, hatchedCount == 1 and "" or "s")
        self.Runtime:setStatus("hatch_ready", "Working", message)
        return true, message
    end
    if readyCount > 0 then
        return false, tostring(lastError or "Ready eggs were not accepted by the server")
    end
    return false, "No placed egg is ready"
end

function EggAutomation:petPredictions()
    local eggCmds = self.State.Modules.EggCmds
    local predictions = {}
    for _, record in ipairs(self.State:getPlacedEggRecords(true)) do
        local category = record.AssetCategory or record.Category or "Unknown pet"
        local assetConfig = self.State:assetConfig(category)
        local rarity = type(assetConfig.Rarity) == "table" and assetConfig.Rarity or {}
        local rarityName = rarity.DisplayName or rarity.Name or assetConfig.RarityName
            or ("Tier " .. tostring(tonumber(rarity.RarityNumber or assetConfig.RarityNumber) or "?"))
        local ready = record.Ready == true or record.IsReady == true
        if type(eggCmds) == "table" and type(eggCmds.IsLocalEggReady) == "function" then
            local ok, value = pcall(eggCmds.IsLocalEggReady, record.Uid)
            if ok and type(value) == "boolean" then
                ready = value
            end
        end
        local mutationCount = self.State:mutationInfo(record)
        local weight = tonumber(record.WeightKg or record.VisualWeightKg)
        local scale = tonumber(record.Scale or record.AssetScale)
        local sizeText = weight and weight > 0 and string.format("%.2f kg", weight)
            or (scale and scale > 0 and string.format("%.2fx", scale) or "size pending")
        predictions[#predictions + 1] = string.format(
            "%s → %s [%s] • %s • %s mutation%s",
            string.sub(tostring(record.Uid), 1, 8),
            tostring(category),
            tostring(rarityName),
            sizeText,
            tostring(mutationCount),
            mutationCount == 1 and "" or "s"
        ) .. (ready and " • READY" or " • growing")
    end
    table.sort(predictions)
    if #predictions == 0 then
        return false, "No growing eggs are placed"
    end
    while #predictions > 12 do
        table.remove(predictions)
    end
    return true, table.concat(predictions, "\n")
end

function EggAutomation:runFastPipelineOnce()
    local features = self.Runtime.Config.Features or {}
    local messages = {}

    if features.hatch_ready == true then
        local hatched, hatchReason = self:hatchOnce()
        if hatched then
            messages[#messages + 1] = hatchReason
        end
    end

    local stolen, stealReason = self:stealOnce()
    if not stolen then
        return false, stealReason
    end
    messages[#messages + 1] = stealReason

    if features.place_eggs == true then
        local placed, placeReason = self:placeOnce()
        if placed then
            messages[#messages + 1] = placeReason
        else
            self.Runtime:setStatus("place_eggs", "Waiting", tostring(placeReason))
        end
    end

    if features.hatch_ready == true then
        local hatched, hatchReason = self:hatchOnce()
        if hatched then
            messages[#messages + 1] = hatchReason
        end
    end

    return true, table.concat(messages, " • ")
end

function EggAutomation:equipBest()
    local transportOk, serverOk, serverReason = self.State:callCurrentRemote(
        {"Haul", "WearBest"},
        "EquipBest",
        {}
    )
    local accepted, rejection = classifyRemoteResponse(transportOk, serverOk, serverReason)
    if not accepted then
        return false, rejection
    end
    self.Runtime:setStatus("equip_best", "Working", "Best pets requested")
    return true, "Equipped best pets"
end

local MonsterAutomation = {}
MonsterAutomation.__index = MonsterAutomation

function MonsterAutomation.new(owner, gameState, navigator, eggs)
    return setmetatable({
        Runtime = owner,
        State = gameState,
        Movement = navigator,
        Eggs = eggs,
        PromptCache = {},
        PromptMissUntil = {},
        LastParasite = nil,
        LastCharge = nil,
        LastSnapshot = nil,
        LastSnapshotAt = -math.huge,
        LastImmediateReturnSeconds = nil,
        LastImmediateReturnReason = nil,
        LastFeedCorrectionUsed = false,
    }, MonsterAutomation)
end

function MonsterAutomation:_eventRoot()
    return Workspace:FindFirstChild("MonsterParasiteMonsters")
        or Workspace:FindFirstChild("MonsterEventMap")
end

function MonsterAutomation:_findPrompt(name, enabledOnly)
    enabledOnly = enabledOnly ~= false
    local cached = self.PromptCache[name]
    if cached and cached.Parent and cached:IsA("ProximityPrompt")
        and (not enabledOnly or cached.Enabled) then
        return cached
    end
    self.PromptCache[name] = nil
    if os.clock() < (self.PromptMissUntil[name] or 0) then
        return nil
    end
    local roots = {
        self:_eventRoot(),
        Workspace:FindFirstChild("MonsterParasiteMarkers"),
        Workspace,
    }
    for _, root in ipairs(roots) do
        local prompt = root and root:FindFirstChild(name, true)
        if prompt and prompt:IsA("ProximityPrompt")
            and (not enabledOnly or prompt.Enabled) then
            self.PromptCache[name] = prompt
            self.PromptMissUntil[name] = nil
            return prompt
        end
    end
    self.PromptMissUntil[name] = os.clock() + 0.5
    return nil
end

function MonsterAutomation:_invoke(name, ...)
    return self.State:callCurrentRemote(
        {"MonsterParasite", name},
        "MonsterParasite/" .. tostring(name),
        {...},
        ...
    )
end

function MonsterAutomation:_snapshot(force)
    if not force and type(self.LastSnapshot) == "table"
        and os.clock() - self.LastSnapshotAt <= 0.2 then
        return self.LastSnapshot
    end
    local transportOk, snapshot = self:_invoke("AskSnapshot")
    if transportOk and type(snapshot) == "table"
        and type(snapshot.State) == "table"
        and type(snapshot.Event) == "table" then
        self.LastSnapshot = snapshot
        self.LastSnapshotAt = os.clock()
        self.LastCharge = tonumber(snapshot.State.Charge) or self.LastCharge
        return snapshot
    end
    return self.LastSnapshot
end

function MonsterAutomation:_eventActive(force)
    local snapshot = self:_snapshot(force)
    return type(snapshot) == "table"
        and type(snapshot.Event) == "table"
        and snapshot.Event.Active == true
end

function MonsterAutomation:_promptPosition(prompt)
    if not prompt or not prompt.Parent then
        return nil
    end
    local holder = prompt.Parent
    local position
    if holder:IsA("Attachment") then
        position = holder.WorldPosition
    elseif holder:IsA("BasePart") then
        position = holder.Position
    else
        local part = holder:FindFirstAncestorWhichIsA("BasePart")
        position = part and part.Position or nil
    end
    if typeof(position) ~= "Vector3" then
        return nil
    end
    local root = self.Movement:getRoot()
    local away = root and (root.Position - position) or Vector3.new(1, 0, 0)
    away = Vector3.new(away.X, 0, away.Z)
    if away.Magnitude <= 1e-6 then
        away = Vector3.new(1, 0, 0)
    else
        away = away.Unit
    end
    return CFrame.new(position + away * 4 + Vector3.new(0, 2.5, 0))
end

function MonsterAutomation:_readCharge(force)
    local snapshot = self:_snapshot(force)
    local replicatedCharge = type(snapshot) == "table"
        and type(snapshot.State) == "table"
        and tonumber(snapshot.State.Charge)
        or nil
    if replicatedCharge ~= nil then
        self.LastCharge = replicatedCharge
        return replicatedCharge
    end
    local names = {
        Charge = true,
        MonsterCharge = true,
        ChargePercent = true,
        FeedPercent = true,
        Hunger = true,
        Progress = true,
    }
    local root = self:_eventRoot()
    if not root then
        return nil
    end
    local objects = {root}
    for _, descendant in ipairs(root:GetDescendants()) do
        objects[#objects + 1] = descendant
    end
    for _, object in ipairs(objects) do
        for attribute, value in pairs(object:GetAttributes()) do
            if names[attribute] and tonumber(value) then
                local number = tonumber(value)
                if number >= 0 and number <= 100 then
                    self.LastCharge = number
                    return number
                end
            end
        end
    end
    return self.LastCharge
end

function MonsterAutomation:_activatePrompt(prompt)
    if not prompt or not prompt.Parent or not prompt.Enabled then
        return false, "Monster prompt is unavailable"
    end
    if type(fireproximityprompt) == "function" then
        local ok, reason = pcall(fireproximityprompt, prompt, 0)
        if ok then
            return true
        end
        return false, tostring(reason)
    end
    local began, beginReason = pcall(prompt.InputHoldBegin, prompt)
    if not began then
        return false, tostring(beginReason)
    end
    task.wait(math.min(0.3, math.max(0, tonumber(prompt.HoldDuration) or 0)))
    local ended, endReason = pcall(prompt.InputHoldEnd, prompt)
    if ended then
        return true, nil
    end
    return false, tostring(endReason)
end

function MonsterAutomation:_isParasiteCandidate(candidate)
    if type(candidate) ~= "table" or type(candidate.Record) ~= "table" then
        return false
    end
    local record = candidate.Record
    if record.HasParasite == true or record.IsParasite == true then
        return true
    end
    local live = candidate.LiveModel
    return live ~= nil and (
        live:GetAttribute("HasParasite") == true
        or live:GetAttribute("IsParasite") == true
    )
end

function MonsterAutomation:selectParasite(refresh)
    local config = self.Runtime.Config.Monster or {}
    local parasiteAreas = {}
    for _, areaId in ipairs(self.State:getTargetAreas(ALL_AREAS)) do
        if (AREA_ORDER[areaId] or 0) >= (AREA_ORDER.Snow or 5) then
            parasiteAreas[#parasiteAreas + 1] = areaId
        end
    end
    local candidates = self.State:eggCandidates(
        parasiteAreas,
        tonumber(config.MinimumRarity) or 1,
        refresh ~= false
    )
    local parasites = {}
    for _, candidate in ipairs(candidates) do
        if self:_isParasiteCandidate(candidate) then
            parasites[#parasites + 1] = candidate
        end
    end
    return chooseEggCandidate(parasites, config.TargetMode or "Highest Rarity"), #parasites
end

function MonsterAutomation:_sameBoundarySide(left, right)
    local _, line = self.Movement:_boundaryParts()
    if not line then
        return true
    end
    local normal = line.CFrame.LookVector
    normal = Vector3.new(normal.X, 0, normal.Z)
    if normal.Magnitude <= 1e-6 then
        normal = Vector3.new(1, 0, 0)
    else
        normal = normal.Unit
    end
    local leftSide = (left - line.Position):Dot(normal)
    local rightSide = (right - line.Position):Dot(normal)
    return leftSide * rightSide > 0
end

function MonsterAutomation:_moveCarriedToPrompt(candidate, carryState, prompt)
    local destination = self:_promptPosition(prompt)
    if typeof(destination) ~= "CFrame" then
        return false, "Monster feed position unavailable"
    end
    local configSpeed = customStealSpeed((self.Runtime.Config.Egg or {}).CustomStealSpeed)
    local speed = configSpeed > 0 and configSpeed or self.State:getCarryTransportCruiseSpeed(carryState)
    local carriedUid = type(carryState) == "table" and carryState.Uid or candidate.Uid
    local carrySequence = self.State.CarryStateSequence
    local carryLost = false
    local function cancelled()
        if self.State.CarryStateSequence > carrySequence
            and carryStateDisposition(self.State.LastCarryState, carriedUid) ~= "ready" then
            carryLost = true
            return true
        end
        return false
    end
    local function leg(target, label, timeout, radius)
        if not target then
            return true
        end
        local legSpeed = speed
        if configSpeed <= 0 then
            local root = self.Movement:getRoot()
            if root then
                local distance = self.Eggs:_horizontalDistance(root.Position, target.Position)
                if distance > 1000 then
                    legSpeed = math.max(speed, 1050)
                end
            end
        end
        local moved, reason = self.Eggs:_moveCarriedLeg(target, cancelled, {
            CruiseSpeed = legSpeed,
            WalkSpeed = legSpeed,
            AllowCustomSpeed = true,
            UseRagdoll = configSpeed > 0 and registeredRagdollForSpeed(legSpeed),
            StayGrounded = true,
            AllowStandGround = true,
            TimeoutSeconds = timeout or 6,
            ArrivalRadius = radius or 4,
        })
        if carryLost then
            return false, "Parasite egg was dropped " .. label
        end
        if not moved then
            return false, label .. " failed: " .. tostring(reason)
        end
        return true
    end

    local nearbyRoot = self.Movement:getRoot()
    if nearbyRoot
        and self.Eggs:_horizontalDistance(nearbyRoot.Position, destination.Position) <= 30 then
        return leg(destination, "while settling at the Hungry Monster", 1.5, 1.5)
    end

    local gateway = self.Eggs:_gatewayCFrame()
    local root = self.Movement:getRoot()
    if not gateway or not root then
        return false, "Center lane unavailable while carrying the parasite egg"
    end

    local laneCenterZ = gateway.Position.Z
    local centerLaneEntry = CFrame.new(root.Position.X, root.Position.Y, laneCenterZ)
    local ok, reason = leg(centerLaneEntry, "while entering the center lane", 2, 3)
    if not ok then return false, reason end

    if not self:_sameBoundarySide(centerLaneEntry.Position, destination.Position) then
        local sideSign = centerLaneEntry.Position.X >= gateway.Position.X and 1 or -1
        local margin = clampFinite(self.Runtime.Config.Movement.SafeCorridorMargin, 10, 40, 18)
        local gatewayApproach = CFrame.new(
            gateway.Position.X + sideSign * margin,
            gateway.Position.Y,
            laneCenterZ
        )
        ok, reason = leg(gatewayApproach, "while approaching the middle gateway", 6, 3)
        if not ok then return false, reason end
        ok, reason = leg(gateway, "while crossing the middle gateway", 4, 3)
        if not ok then return false, reason end
    end

    local destinationLane = CFrame.new(
        destination.Position.X,
        destination.Position.Y,
        laneCenterZ
    )
    ok, reason = leg(destinationLane, "along the center lane", 8, 4)
    if not ok then return false, reason end
    return leg(destination, "while approaching the Hungry Monster", 3, 5)
end

function MonsterAutomation:claimChest()
    local snapshot = self:_snapshot(true)
    if not self:_eventActive(false) then
        return false, "Hungry Monster event is not active"
    end
    local state = type(snapshot) == "table" and snapshot.State or {}
    local pendingReward = type(state) == "table" and state.PendingReward or nil

    local function reveal(openingId)
        if openingId == nil then
            return false, "Monster chest response had no opening id"
        end
        local lastReason = "Monster chest reveal is still finishing"
        for attempt = 1, 6 do
            local transportOk, response = self:_invoke("AskChestRevealComplete", openingId)
            if transportOk and type(response) == "table" and response.Success == true then
                self.LastSnapshotAt = -math.huge
                self.Runtime.Session.MonsterChests += 1
                return true, "Claimed Hungry Monster chest"
            end
            if type(response) == "table" and response.Message then
                lastReason = tostring(response.Message)
            elseif not transportOk then
                lastReason = tostring(response)
            end
            if attempt < 6 then
                task.wait(0.25)
            end
        end
        return false, lastReason
    end

    if type(pendingReward) == "table" and pendingReward.OpeningId ~= nil then
        return reveal(pendingReward.OpeningId)
    end
    if (tonumber(type(state) == "table" and state.PendingChests) or 0) <= 0 then
        return false, "Monster chest is not ready"
    end

    self:_invoke("AskChestTake")
    local openingRequestId = HttpService:GenerateGUID(false)
    local claimResponse
    local lastReason = "Monster chest claim did not complete"
    for attempt = 1, 8 do
        local transportOk, response = self:_invoke("AskChestClaim", openingRequestId)
        if transportOk and type(response) == "table" then
            if response.Success == true then
                claimResponse = response
                break
            end
            lastReason = tostring(response.Message or lastReason)
        elseif not transportOk then
            lastReason = tostring(response)
        end
        if attempt < 8 then
            task.wait(0.25)
        end
    end
    if type(claimResponse) ~= "table" then
        return false, lastReason
    end
    local rewardName = type(claimResponse.Reward) == "table"
        and claimResponse.Reward.DisplayName
        or nil
    local revealed, revealReason = reveal(claimResponse.OpeningId or openingRequestId)
    if not revealed then
        return false, revealReason
    end
    return true, rewardName
        and ("Claimed Hungry Monster chest • " .. tostring(rewardName))
        or "Claimed Hungry Monster chest"
end

function MonsterAutomation:feedOnce()
    local snapshot = self:_snapshot(true)
    if not self:_eventActive(false) then
        return false, "Hungry Monster event is not active"
    end
    local eventState = type(snapshot) == "table" and snapshot.State or {}
    if (tonumber(type(eventState) == "table" and eventState.PendingChests) or 0) > 0
        or type(type(eventState) == "table" and eventState.PendingReward) == "table" then
        return self:claimChest()
    end
    local feedPrompt = self:_findPrompt("FeedPrompt", false)
    if not feedPrompt then
        return false, "Hungry Monster feed point is unavailable"
    end
    local feedDestination = self:_promptPosition(feedPrompt)
    if typeof(feedDestination) ~= "CFrame" then
        return false, "Hungry Monster feed position is unavailable"
    end

    local root = self.Movement:getRoot()
    local releaseOk, _, releaseReason = self.Eggs:_releaseTreadmillIfNeeded(root)
    if not releaseOk then
        return false, releaseReason
    end
    local bypassReady, bypassReason = self.Movement:waitForRegistered(4)
    if not bypassReady then
        return false, bypassReason
    end
    self.State.LastAreaRefreshAt = -math.huge
    local candidate, parasiteCount = self:selectParasite(true)
    if not candidate then
        return false, "No parasite egg is currently available from Snow onward"
    end
    self.LastParasite = candidate
    local target = self.Eggs:_targetCFrame(candidate)
    if not target then
        return false, "Parasite egg has no replicated position"
    end
    local moved, moveReason = self.Eggs:_moveToTarget(target, 6, 1.5, candidate.AreaId)
    if not moved then
        return false, "Parasite approach failed: " .. tostring(moveReason)
    end
    local slotKey = self.State:buildSlotKey(candidate.Record)
    local pickupStartedAt = os.clock()
    local carried, carryState, returned, returnReason = self.Eggs:_acquireConfirmedCarry(
        candidate,
        slotKey,
        target,
        feedDestination
    )
    if not carried then
        local alreadyCarrying = string.find(
            string.lower(tostring(carryState or "")),
            "already carrying",
            1,
            true
        ) ~= nil
        local existingCarry = alreadyCarrying and self.Eggs.LastReplicatedCarryState or nil
        if type(existingCarry) ~= "table" or existingCarry.IsCarrying ~= true then
            return false, "Parasite pickup failed: " .. tostring(carryState)
        end

        carryState = table.clone(existingCarry)
        carried = true
        returned, returnReason = self.Eggs:_escapeAfterCarry(feedDestination, carryState)
    end
    self.LastImmediateReturnSeconds = os.clock() - pickupStartedAt
    self.LastImmediateReturnReason = tostring(returnReason)
    if not returned then
        return false, "Parasite carried but immediate return failed: " .. tostring(returnReason)
    end

    self.LastFeedCorrectionUsed = true
    local reached, reachReason = self:_moveCarriedToPrompt(candidate, carryState, feedPrompt)
    if not reached then
        return false, reachReason
    end

    local settledRoot = self.Movement:getRoot()
    if settledRoot then
        settledRoot.AssemblyLinearVelocity = Vector3.zero
        settledRoot.AssemblyAngularVelocity = Vector3.zero
    end
    RunService.Heartbeat:Wait()

    local transportOk, response = self:_invoke("AskFeed")
    if not transportOk then
        return false, "Monster feed request failed: " .. tostring(response)
    end
    if type(response) ~= "table" or response.Success ~= true then
        return false, type(response) == "table"
            and tostring(response.Message or "Monster rejected the parasite egg")
            or "Monster returned an invalid feed response"
    end
    self.LastSnapshotAt = -math.huge
    self.LastCharge = tonumber(response.Charge) or self.LastCharge
    self.Runtime.Session.MonsterFeeds += 1
    local confirmedSnapshot = self:_snapshot(true)
    local displayedCharge = tonumber(response.Charge)
        or tonumber(type(confirmedSnapshot) == "table"
            and type(confirmedSnapshot.State) == "table"
            and confirmedSnapshot.State.Charge)
        or 0
    local message = string.format(
        "Fed %s to Hungry Monster • %s%% • %d parasite%s visible",
        tostring(candidate.Category),
        tostring(displayedCharge),
        parasiteCount,
        parasiteCount == 1 and "" or "s"
    )
    if (tonumber(response.PendingChests) or 0) > 0 then
        task.wait(0.15)
        local claimed, claimMessage = self:claimChest()
        if claimed then
            message ..= " • " .. tostring(claimMessage)
        end
    end
    return true, message
end

local PetAutomation = {}
PetAutomation.__index = PetAutomation

function PetAutomation.new(owner, gameState, networkBroker)
    return setmetatable({Runtime = owner, State = gameState, Broker = networkBroker}, PetAutomation)
end

function PetAutomation:sellOnce()
    local config = self.Runtime.Config.Economy
    local items = self.State:getInventory()
    local uids = chooseSellUids(items, {
        MaxRarity = config.SellMaxRarity,
        KeepCount = config.KeepCount,
        ProtectMutations = config.ProtectMutations,
    })
    if #uids == 0 then
        return false, "Sell policy found no eligible pets"
    end
    local requested = 0
    local batchSize = math.min(#uids, 20)
    for index = 1, batchSize do
        local uid = uids[index]
        local transportOk, serverOk, serverReason = self.State:callCurrentRemote(
            {"PetSatchel", "SellPet"},
            "SellAsset",
            {buildSellAssetPayload(uid)},
            uid
        )
        local accepted, rejection = classifyRemoteResponse(transportOk, serverOk, serverReason)
        if not accepted then
            self.Runtime.Session.PetsSold += requested
            return false, string.format("Sold %d/%d before failure: %s", requested, batchSize, tostring(rejection))
        end
        local verifyDeadline = os.clock() + 1
        while inventoryContainsUid(self.State:getInventory(), uid) and os.clock() < verifyDeadline do
            task.wait(0.05)
        end
        if inventoryContainsUid(self.State:getInventory(), uid) then
            self.Runtime.Session.PetsSold += requested
            return false, string.format("Sold %d/%d pets; server kept %s", requested, batchSize, tostring(uid))
        end
        requested += 1
    end
    self.Runtime.Session.PetsSold += requested
    self.Runtime:setStatus("smart_sell", "Working", string.format("%d protected-policy pets", requested))
    return true, string.format("Sold %d unprotected pets", requested)
end

function PetAutomation:sellEggsOnce()
    local config = self.Runtime.Config.Economy
    local eggs = self.State:getEggInventory()
    if #eggs == 0 then
        return false, "Egg inventory is empty"
    end
    local mode = config.EggSellMode == "All Eggs" and "All Eggs" or "Selected Types"
    local uids = chooseEggSellUids(eggs, mode, config.EggSellTypes)
    if #uids == 0 then
        if mode == "Selected Types" and countTable(config.EggSellTypes) == 0 then
            return false, "No egg types are selected"
        end
        return false, "No sellable eggs match the selected types"
    end
    local requested = 0
    local batchSize = math.min(#uids, math.floor(clampFinite(config.EggSellBatchSize, 1, 100, 20)))
    for index = 1, batchSize do
        local uid = uids[index]
        local equipTransport, equipServer, equipReason = self.State:callEggCommand(
            "RequestEquipTool",
            "EggEquip",
            {uid},
            uid
        )
        local equipped, equipError = classifyRemoteResponse(equipTransport, equipServer, equipReason)
        if not equipped then
            self.Runtime.Session.EggsSold += requested
            return false, string.format(
                "Sold %d/%d eggs before equip failure: %s",
                requested,
                batchSize,
                tostring(equipError)
            )
        end
        task.wait(0.08)
        local transportOk, serverOk, serverReason = self.State:callCurrentRemote(
            {"PetSatchel", "SellPet"},
            "SellAsset",
            {buildSellAssetPayload(uid)},
            uid
        )
        local accepted, rejection = classifyRemoteResponse(transportOk, serverOk, serverReason)
        if not accepted then
            self.Broker:call("EggUnequip", uid)
            self.Runtime.Session.EggsSold += requested
            return false, string.format(
                "Sold %d/%d eggs before failure: %s",
                requested,
                batchSize,
                tostring(rejection)
            )
        end

        local removed = false
        local verifyDeadline = os.clock() + 1
        repeat
            removed = not inventoryContainsUid(self.State:getEggInventory(), uid)
            if not removed then
                task.wait(0.05)
            end
        until removed or os.clock() >= verifyDeadline
        if not removed then
            self.Broker:call("EggUnequip", uid)
            self.Runtime.Session.EggsSold += requested
            return false, string.format(
                "Sold %d/%d eggs; server kept %s",
                requested,
                batchSize,
                tostring(uid)
            )
        end
        requested += 1
    end
    self.Runtime.Session.EggsSold += requested
    self.Runtime:setStatus("auto_sell_eggs", "Working", string.format("%d eggs via %s", requested, mode))
    return true, string.format("Sold %d eggs via %s", requested, mode)
end

function PetAutomation:_fusionPrice(items)
    local module = self.State.Modules.FuseKernelUtil
    local callback = type(module) == "table" and module.CalculateFusePrice or nil
    if type(callback) ~= "function" then
        return nil
    end
    local ok, value = pcall(callback, items)
    if ok and tonumber(value) then
        return math.max(0, tonumber(value))
    end
    return nil
end

function PetAutomation:selectFusePlan()
    local config = self.Runtime.Config.Economy
    return chooseFusePlan(self.State:getInventory(), {
        Strategy = config.FuseStrategy,
        CategoryMode = config.FuseCategoryMode,
        Categories = config.FuseCategories,
        MinimumRarity = config.FuseMinimumRarity,
        MaximumRarity = config.FuseMaximumRarity,
        MaximumWeightKg = config.FuseMaximumWeightKg,
        MaximumScale = config.FuseMaximumScale,
        MutationPolicy = config.FuseMutationPolicy,
        KeepPerCategory = config.FuseKeepPerCategory,
        MaximumPrice = config.FuseMaximumPrice,
        AllowEquipped = config.FuseAllowEquipped,
        AllowFavorites = config.FuseAllowFavorites,
    }, function(items)
        return self:_fusionPrice(items)
    end)
end

function PetAutomation:_restoreFavorites(uids)
    for _, uid in ipairs(uids or {}) do
        self.Broker:call("SetFavorite", uid, true)
    end
end

function PetAutomation:fuseOnce()
    local plan = self:selectFusePlan()
    if not plan then
        return false, "No fusion trio matches the current policy"
    end
    local preview = string.format(
        "%s • value %.1f • avg %.2fx / %.2fkg • cost %.0f",
        tostring(plan.Category),
        tonumber(plan.Value) or 0,
        tonumber(plan.AverageScale) or 0,
        tonumber(plan.AverageWeightKg) or 0,
        tonumber(plan.Price) or 0
    )
    self.Runtime:setStatus("auto_fuse", "Selected", preview)
    local inserted = {}
    local unfavorited = {}
    for index, uid in ipairs(plan.Uids) do
        local item = plan.Items and plan.Items[index]
        if item and item.IsFavorite == true then
            local favoriteTransport, favoriteServer, favoriteReason = self.Broker:call("SetFavorite", uid, false)
            local favoriteCleared, favoriteError = classifyRemoteResponse(favoriteTransport, favoriteServer, favoriteReason)
            if not favoriteCleared then
                self:_restoreFavorites(unfavorited)
                return false, "Could not temporarily unfavorite " .. tostring(uid) .. ": " .. tostring(favoriteError)
            end
            unfavorited[#unfavorited + 1] = uid
            task.wait(0.06)
        end
        local transportOk, serverOk, serverReason = self.Broker:call("FuseInsert", uid)
        local accepted, rejection = classifyRemoteResponse(transportOk, serverOk, serverReason)
        if not accepted then
            for _, cleanupUid in ipairs(inserted) do
                self.Broker:call("FuseRemove", cleanupUid)
            end
            self:_restoreFavorites(unfavorited)
            return false, rejection
        end
        inserted[#inserted + 1] = uid
    end
    local startTransport, startServer, startReason = self.Broker:call("FuseStart")
    local started, startError = classifyRemoteResponse(startTransport, startServer, startReason)
    if not started then
        for _, cleanupUid in ipairs(inserted) do
            self.Broker:call("FuseRemove", cleanupUid)
        end
        self:_restoreFavorites(unfavorited)
        return false, startError
    end
    task.wait(fusionRevealDelay({0.22, 0.18, 0.15}, 0.05))
    local completeTransport, completeServer, completeReason = self.Broker:call("FuseComplete")
    local completed, completeError = classifyRemoteResponse(completeTransport, completeServer, completeReason)
    if not completed then
        return false, completeError
    end
    self.Runtime.Session.Fusions += 1
    self.Runtime:setStatus("auto_fuse", "Working", preview)
    return true, "Fused trio: " .. preview
end

function PetAutomation:fuseCycle()
    local limit = math.floor(clampFinite(self.Runtime.Config.Economy.FusionsPerCycle, 1, 10, 1))
    local completed = 0
    local lastReason
    for _ = 1, limit do
        local ok, reason = self:fuseOnce()
        if not ok then
            lastReason = reason
            break
        end
        completed += 1
        task.wait(0.1)
    end
    if completed == 0 then
        return false, lastReason or "No fusion trio matches the current policy"
    end
    return true, string.format("Completed %d/%d fusion(s)%s", completed, limit, lastReason and ("; stopped: " .. tostring(lastReason)) or "")
end

local ProgressionAutomation = {}
ProgressionAutomation.__index = ProgressionAutomation

function ProgressionAutomation.new(owner, gameState, networkBroker, navigator)
    return setmetatable({
        Runtime = owner,
        State = gameState,
        Broker = networkBroker,
        Movement = navigator,
    }, ProgressionAutomation)
end

function ProgressionAutomation:train()
    if self.Runtime.Session.TreadmillActive == true then
        local resumeTransport, resumeServer, resumeReason = self.State:callCurrentRemote(
            {"Treadmill", "AskWearStill"},
            "TreadmillEquip",
            {}
        )
        local resumeAction, resumeError = treadmillResumeDecision(resumeTransport, resumeServer, resumeReason)
        if resumeAction == "active" then
            self.Runtime:setStatus("treadmill_train", "Working", "Static treadmill already active")
            return true, "Static treadmill training active"
        end
        self.Runtime.Session.TreadmillActive = false
        if resumeAction == "failure" then
            return false, resumeError
        end
    end
    local targetCFrame, targetReason = self.State:getTreadmillStandCFrame()
    if typeof(targetCFrame) ~= "CFrame" then
        return false, targetReason
    end
    local moved, moveReason = self.Movement:moveRoute(targetCFrame, nil, {
        TimeoutSeconds = 4,
        SettleSeconds = 0,
        ArrivalRadius = 5,
    })
    if not moved then
        return false, moveReason
    end
    local transportOk, serverOk, serverReason = self.State:callCurrentRemote(
        {"Treadmill", "AskWearStill"},
        "TreadmillEquip",
        {}
    )
    local accepted, rejection = classifyTreadmillEquip(transportOk, serverOk, serverReason)
    if not accepted then
        return false, rejection
    end
    self.Runtime.Session.TreadmillActive = true
    self.Runtime:setStatus("treadmill_train", "Working", "Static treadmill equipped")
    return true, "Static treadmill training active"
end

function ProgressionAutomation:stopTraining()
    local results = pack(self.State:callCurrentRemote(
        {"Treadmill", "AskDoff"},
        "TreadmillUnequip",
        {}
    ))
    local released = classifyTreadmillUnequip(results[1], results[2], results[3])
    if released then
        self.Runtime.Session.TreadmillActive = false
    end
    return unpackPack(results)
end

function ProgressionAutomation:upgradeTreadmill()
    local nextConfig = self.State:getNextTreadmillConfig()
    local configId = nextConfig and (nextConfig._id or nextConfig.Id or nextConfig.id)
    if not configId then
        return false, "No next treadmill configuration"
    end
    local transportOk, serverOk, serverReason = self.Broker:call("TreadmillUpgrade", configId)
    local accepted, rejection = classifyRemoteResponse(transportOk, serverOk, serverReason)
    if not accepted then
        return false, rejection
    end
    self.Runtime:setStatus("treadmill_upgrade", "Working", tostring(configId))
    return true, "Requested treadmill upgrade " .. tostring(configId)
end

function ProgressionAutomation:upgradeBase()
    local save = self.State:getSave()
    local nextConfig = self.State:getNextBaseConfig()
    local canUpgrade, decisionReason, cost = baseUpgradeDecision(save.Money or save.Coins, nextConfig)
    if not canUpgrade then
        return false, decisionReason
    end
    local transportOk, serverOk, serverReason = self.Broker:call("BaseUpgrade")
    local accepted, rejection = classifyRemoteResponse(transportOk, serverOk, serverReason)
    if not accepted then
        return false, rejection
    end
    self.Runtime:setStatus("base_upgrade", "Working", "Requested cost " .. tostring(cost))
    return true, "Requested next base upgrade"
end

function ProgressionAutomation:rebirth()
    if not self.Broker:available("RebirthRequest") then
        self.Runtime:setStatus("rebirth", "Unavailable", "Remote not present for this account")
        return false, "Rebirth endpoint unavailable"
    end
    local transportOk, serverOk, serverReason = self.Broker:call("RebirthRequest")
    local accepted, rejection = classifyRemoteResponse(transportOk, serverOk, serverReason)
    if not accepted then
        return false, rejection
    end
    if serverOk ~= nil and self.Broker:available("RebirthCommit") then
        local commitTransport, commitServer, commitReason = self.Broker:call("RebirthCommit", serverOk)
        local committed, commitError = classifyRemoteResponse(commitTransport, commitServer, commitReason)
        if not committed then
            return false, commitError
        end
    end
    self.Runtime:setStatus("rebirth", "Working", "Server accepted")
    return true, "Rebirth requested"
end

local RewardAutomation = {}
RewardAutomation.__index = RewardAutomation

function RewardAutomation.new(owner, gameState, networkBroker)
    return setmetatable({Runtime = owner, State = gameState, Broker = networkBroker}, RewardAutomation)
end

function RewardAutomation:offlineIncome()
    local summaryTransport, summary = self.Broker:call("OfflineSummary")
    if not summaryTransport then
        return false, summary
    end
    local amount = type(summary) == "table" and tonumber(summary.ClaimableAmount or summary.TotalAmount) or nil
    if amount and amount <= 0 then
        return false, "No offline income available"
    end
    local transportOk, serverOk, serverReason = self.Broker:call("OfflineRedeem")
    local accepted, rejection = classifyRemoteResponse(transportOk, serverOk, serverReason)
    if not accepted then
        return false, rejection
    end
    self.Runtime.Session.RewardsClaimed += 1
    self.Runtime:setStatus("offline_income", "Working", tostring(amount or "redeemed"))
    return true, "Redeemed offline income"
end

function RewardAutomation:groupReward()
    local claimable, claimReason = groupRewardClaimDecision(self.State:getSave())
    if not claimable then
        return false, claimReason
    end
    local constants = self.State.Modules.Constants
    local groupId = type(constants) == "table" and tonumber(constants.GROUP_ID or constants.GroupId)
    if not groupId then
        return false, "Game group ID unavailable"
    end
    local membershipOk, isMember = pcall(LocalPlayer.IsInGroupAsync, LocalPlayer, groupId)
    if not membershipOk or not isMember then
        return false, "Account is not in the game group"
    end
    local transportOk, serverOk, serverReason = self.Broker:call("GroupReward", true)
    local accepted, rejection = classifyRemoteResponse(transportOk, serverOk, serverReason)
    if not accepted then
        return false, rejection
    end
    self.Runtime.Session.RewardsClaimed += 1
    self.Runtime:setStatus("group_reward", "Working", "Claimed")
    return true, "Claimed group reward"
end

function RewardAutomation:indexRewards()
    local any = false
    local messages = {}
    local allTransport, allServer, allReason = self.Broker:call("IndexClaimAll")
    local allAccepted, allError = classifyRemoteResponse(allTransport, allServer, allReason)
    if allAccepted then
        any = true
        messages[#messages + 1] = "index"
    elseif allError then
        messages[#messages + 1] = allError
    end
    if self.Broker:available("IndexLimitedReward") then
        local limitedTransport, limitedServer, limitedReason = self.Broker:call("IndexLimitedReward")
        local limitedAccepted = classifyRemoteResponse(limitedTransport, limitedServer, limitedReason)
        if limitedAccepted then
            any = true
            messages[#messages + 1] = "limited egg"
        end
    end
    if any then
        self.Runtime.Session.RewardsClaimed += 1
        self.Runtime:setStatus("index_rewards", "Working", table.concat(messages, ", "))
        return true, "Claimed available " .. table.concat(messages, " + ") .. " rewards"
    end
    return false, messages[1] or "No index reward available"
end

function RewardAutomation:freeGifts()
    if not self.Broker:available("FreeGiftClaim") then
        self.Runtime:setStatus("free_gifts", "Unavailable", "Remote not present")
        return false, "Free-gift endpoint unavailable"
    end
    local claimed = 0
    for giftId = 1, 4 do
        local transportOk, serverOk, serverReason = self.Broker:call("FreeGiftClaim", giftId)
        local accepted = classifyRemoteResponse(transportOk, serverOk, serverReason)
        if accepted then
            claimed += 1
        end
    end
    if claimed > 0 then
        self.Runtime.Session.RewardsClaimed += claimed
        self.Runtime:setStatus("free_gifts", "Working", tostring(claimed))
        return true, string.format("Claimed %d free gifts", claimed)
    end
    return false, "No free gift was ready"
end

function RewardAutomation:redeemCode(code)
    code = tostring(code or "")
    if code == "" then
        return false, "Code is empty"
    end
    if not self.Broker:available("CodeClaim") then
        return false, "Code endpoint unavailable"
    end
    local transportOk, serverOk, serverReason = self.Broker:call("CodeClaim", code)
    local accepted, rejection = classifyRemoteResponse(transportOk, serverOk, serverReason)
    if not accepted then
        return false, rejection
    end
    return true, "Redeemed code " .. code
end

function RewardAutomation:redeemConfiguredCode()
    for _, code in ipairs(self.Runtime.Config.Codes or {}) do
        local ok, message = self:redeemCode(code)
        if ok then
            return true, message
        end
    end
    return false, "No configured code was accepted"
end

local eggAutomation = EggAutomation.new(runtime, state, broker, movement)
local monsterAutomation = MonsterAutomation.new(runtime, state, movement, eggAutomation)
local petAutomation = PetAutomation.new(runtime, state, broker)
local progressionAutomation = ProgressionAutomation.new(runtime, state, broker, movement)
local rewardAutomation = RewardAutomation.new(runtime, state, broker)
runtime.EggAutomation = eggAutomation
runtime.MonsterAutomation = monsterAutomation
runtime.PetAutomation = petAutomation
runtime.ProgressionAutomation = progressionAutomation
runtime.RewardAutomation = rewardAutomation
eggAutomation:startTreadmillAntiStuck()

local RARITY_MARKER_COLORS = {
    [1] = Color3.fromRGB(205, 210, 220),
    [2] = Color3.fromRGB(94, 214, 122),
    [3] = Color3.fromRGB(76, 158, 255),
    [4] = Color3.fromRGB(186, 97, 255),
    [5] = Color3.fromRGB(255, 184, 67),
    [6] = Color3.fromRGB(255, 84, 98),
    [7] = Color3.fromRGB(255, 95, 222),
    [8] = Color3.fromRGB(84, 235, 255),
    [9] = Color3.fromRGB(255, 238, 94),
}

local Visuals = {}
Visuals.__index = Visuals

function Visuals.new(owner, gameState)
    return setmetatable({
        Runtime = owner,
        State = gameState,
        Folder = nil,
        MarkersByUid = {},
        SeenRare = {},
        MarkerCount = 0,
    }, Visuals)
end

function Visuals:destroyMarkers()
    if self.Folder then
        pcall(self.Folder.Destroy, self.Folder)
        self.Folder = nil
    end
    table.clear(self.MarkersByUid)
    self.MarkerCount = 0
end

function Visuals:destroy()
    self:destroyMarkers()
    table.clear(self.SeenRare)
end

function Visuals:_color(rarity)
    return RARITY_MARKER_COLORS[math.floor(tonumber(rarity) or 1)] or Color3.fromRGB(255, 255, 255)
end

function Visuals:_updateMarker(marker, candidate)
    local part = type(marker) == "table" and marker.Part or nil
    local label = type(marker) == "table" and marker.Label or nil
    if not part or not part.Parent or not label or not label.Parent then
        return false
    end
    part.CFrame = CFrame.new(candidate.Position + Vector3.new(0, 3.5, 0))
    label.TextColor3 = self:_color(candidate.RarityNumber)
    local distanceText = self.Runtime.Config.Visuals.ShowDistance and string.format(" • %.0f studs", candidate.Distance) or ""
    local mutationText = candidate.MutationCount > 0 and string.format(" • %dx mutation", candidate.MutationCount) or ""
    label.Text = string.format(
        "%s [%s]\n%s%s%s",
        tostring(candidate.Category),
        tostring(candidate.RarityName),
        tostring(candidate.AreaId),
        distanceText,
        mutationText
    )
    return true
end

function Visuals:_createMarker(folder, candidate)
    local part = Instance.new("Part")
    part.Name = "EggMarker"
    part.Anchored = true
    part.Transparency = 1
    part.CanCollide = false
    part.CanTouch = false
    pcall(function()
        part.CanQuery = false
    end)
    part.Size = Vector3.new(0.2, 0.2, 0.2)
    part.Parent = folder

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "EggInfo"
    billboard.Adornee = part
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.fromOffset(210, 58)
    billboard.StudsOffset = Vector3.new(0, 1.5, 0)
    billboard.Parent = part

    local label = Instance.new("TextLabel")
    label.Name = "Info"
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1, 1)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.TextStrokeTransparency = 0.25
    label.TextWrapped = true
    label.Parent = billboard
    local marker = {Part = part, Label = label}
    self:_updateMarker(marker, candidate)
    return marker
end

function Visuals:refresh()
    if not schedulerFeatureEnabled(self.Runtime.Config.Features.rare_egg_esp) then
        self:destroyMarkers()
        return false, "Rare egg markers disabled"
    end
    local config = self.Runtime.Config.Visuals
    local candidates = self.State:eggCandidates(ALL_AREAS, config.MinimumRarity, true)
    table.sort(candidates, function(left, right)
        local leftScore = scoreEggCandidate(left, "Highest Rarity")
        local rightScore = scoreEggCandidate(right, "Highest Rarity")
        return leftScore > rightScore
    end)

    if not self.Folder or not self.Folder.Parent then
        local folder = Instance.new("Folder")
        folder.Name = "VoidHubStealEggMarkers"
        folder.Parent = Workspace
        self.Folder = folder
        table.clear(self.MarkersByUid)
    end
    for uid, marker in pairs(self.MarkersByUid) do
        if type(marker) ~= "table" or not marker.Part or not marker.Part.Parent then
            self.MarkersByUid[uid] = nil
        end
    end
    local limit = math.floor(clampFinite(config.MaxMarkers, 1, 100, 30))
    local plan = planMarkerReconciliation(self.MarkersByUid, candidates, limit)
    for _, uid in ipairs(plan.Remove) do
        local marker = self.MarkersByUid[uid]
        if marker and marker.Part then
            pcall(marker.Part.Destroy, marker.Part)
        end
        self.MarkersByUid[uid] = nil
    end
    for _, uid in ipairs(plan.Keep) do
        self:_updateMarker(self.MarkersByUid[uid], plan.Desired[uid])
    end
    for _, uid in ipairs(plan.Create) do
        self.MarkersByUid[uid] = self:_createMarker(self.Folder, plan.Desired[uid])
    end
    self.MarkerCount = countTable(self.MarkersByUid)
    for uid, candidate in pairs(plan.Desired) do
        if config.NotifyRare and not self.SeenRare[candidate.Uid] then
            self.SeenRare[candidate.Uid] = true
            self.Runtime:notify(
                "Rare egg found",
                string.format("%s [%s] in %s", candidate.Category, candidate.RarityName, candidate.AreaId),
                3.5
            )
        end
    end
    self.Runtime:setStatus("rare_egg_esp", "Working", string.format("%d markers", self.MarkerCount))
    return true, string.format("Rendered %d rare egg markers", self.MarkerCount)
end

local visuals = Visuals.new(runtime, state)
runtime.Visuals = visuals

local Utilities = {}
Utilities.__index = Utilities

function Utilities.new(owner, gameState, navigator)
    return setmetatable({Runtime = owner, State = gameState, Movement = navigator}, Utilities)
end

function Utilities:_queueFunction()
    local queueFn = queue_on_teleport
        or queueonteleport
        or queue_on_tp
        or (type(syn) == "table" and syn.queue_on_teleport)
        or (type(fluxus) == "table" and fluxus.queue_on_teleport)
    return queueFn
end

function Utilities:queueOnTeleport()
    local queueFn = self:_queueFunction()
    if type(queueFn) ~= "function" then
        return false, "Teleport queue API unavailable; executor auto-exec can still resume"
    end
    local payload = string.format([[
if not game:IsLoaded() then
    for _ = 1, 200 do
        if game:IsLoaded() then break end
        task.wait(0.1)
    end
end
if not game:IsLoaded() or game.GameId ~= %d then return end
]], EXPECTED_GAME_ID)
    local ok, err = pcall(queueFn, payload)
    return ok, ok and "Queued teleport resume wait" or tostring(err)
end

function Utilities:teleportHome()
    local target = self.State:getPlotCenter()
    if typeof(target) ~= "CFrame" then
        return false, "Plot center unavailable"
    end
    local wrapperOk, moved, reason = self.Movement:withAuthorized(function()
        return self.Movement:moveTo(target + Vector3.new(0, 3.25, 0))
    end)
    if not wrapperOk then
        return false, moved
    end
    return moved, reason
end

function Utilities:teleportToBestEgg()
    local candidate = self.Runtime.EggAutomation:selectTarget(true)
    if not candidate then
        return false, "No eligible egg target"
    end
    local target = self.Runtime.EggAutomation:_targetCFrame(candidate)
    local wrapperOk, moved, reason = self.Movement:withAuthorized(function()
        return self.Movement:moveTo(target)
    end)
    if not wrapperOk then
        return false, moved
    end
    return moved, reason
end

function Utilities:rejoin(userInitiated)
    if userInitiated ~= true then
        return false, "Automatic rejoin is disabled"
    end
    self.Runtime:saveConfigNow()
    if self.Runtime.Config.Utilities.AutoQueueOnTeleport then
        self:queueOnTeleport()
    end
    local ok, err = pcall(TeleportService.TeleportToPlaceInstance, TeleportService, game.PlaceId, game.JobId, LocalPlayer)
    return ok, ok and "Rejoining current server" or tostring(err)
end

function Utilities:_requestFunction()
    return request
        or http_request
        or (type(syn) == "table" and syn.request)
        or (type(http) == "table" and http.request)
end

function Utilities:_serverChoices(visitedJobs)
    local requestFn = self:_requestFunction()
    if type(requestFn) ~= "function" then
        return nil, "Executor HTTP request API unavailable"
    end
    local choices = {}
    local cursor = nil
    for _ = 1, 4 do
        local url = string.format(
            "https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&excludeFullGames=true&limit=100%s",
            game.PlaceId,
            cursor and ("&cursor=" .. HttpService:UrlEncode(cursor)) or ""
        )
        local requestOk, response = pcall(requestFn, {Url = url, Method = "GET"})
        if not requestOk or type(response) ~= "table" then
            return nil, tostring(response)
        end
        local body = response.Body or response.body
        local decodeOk, decoded = pcall(HttpService.JSONDecode, HttpService, body)
        if not decodeOk or type(decoded) ~= "table" then
            return nil, "Server list response could not be decoded"
        end
        for _, server in ipairs(type(decoded.data) == "table" and decoded.data or {}) do
            local id = tostring(server.id or "")
            if id ~= "" and id ~= game.JobId
                and not (visitedJobs or {})[id]
                and tonumber(server.playing) < tonumber(server.maxPlayers) then
                choices[#choices + 1] = {
                    Id = id,
                    Playing = tonumber(server.playing) or math.huge,
                }
            end
        end
        cursor = decoded.nextPageCursor
        if #choices > 0 or type(cursor) ~= "string" or cursor == "" then
            break
        end
    end
    table.sort(choices, function(left, right)
        if left.Playing ~= right.Playing then
            return left.Playing < right.Playing
        end
        return left.Id < right.Id
    end)
    return choices
end

function Utilities:serverHop(userInitiated, options)
    options = type(options) == "table" and options or {}
    local finder = self.Runtime.EggFinder
    local finderAuthorized = options.Finder == true
        and finder ~= nil
        and finder.StateData.Active == true
    if userInitiated ~= true and not finderAuthorized then
        return false, "Automatic server hop is disabled"
    end
    local choices, choiceReason = self:_serverChoices(options.VisitedJobs)
    if not choices then
        return false, choiceReason
    end
    if #choices == 0 then
        return false, "No alternate public server found"
    end
    self.Runtime:saveConfigNow()
    if finderAuthorized or self.Runtime.Config.Utilities.AutoQueueOnTeleport then
        local queued, queueReason = self:queueOnTeleport()
        if not queued then
            return false, "Server hop cancelled: " .. tostring(queueReason)
        end
    end
    local target = choices[1].Id
    if finderAuthorized then
        finder:beforeTeleport(target)
    end
    local teleportOk, teleportError = pcall(TeleportService.TeleportToPlaceInstance, TeleportService, game.PlaceId, target, LocalPlayer)
    if not teleportOk and finderAuthorized then
        finder:teleportFailed(teleportError)
    end
    return teleportOk, teleportOk and "Server hop requested" or tostring(teleportError)
end

local utilities = Utilities.new(runtime, state, movement)
runtime.Utilities = utilities

local EggFinder = {}
EggFinder.__index = EggFinder

function EggFinder.new(owner, gameState, sessionUtilities)
    local self = setmetatable({
        Runtime = owner,
        GameState = gameState,
        Utilities = sessionUtilities,
        StateData = {
            Active = false,
            TargetCategory = "",
            VisitedJobs = {},
            HopCount = 0,
            StartedAt = 0,
            LastHopAt = 0,
        },
        NextScanAt = 0,
        TeleportPending = false,
        LastFound = nil,
    }, EggFinder)
    self:_load()
    self.TeleportPending = false
    self:_markVisited(game.JobId)
    return self
end

function EggFinder:_load()
    if type(isfile) ~= "function" or type(readfile) ~= "function" then
        return false
    end
    local existsOk, exists = pcall(isfile, FINDER_STATE_PATH)
    if not existsOk or not exists then
        return false
    end
    local readOk, body = pcall(readfile, FINDER_STATE_PATH)
    if not readOk then
        return false
    end
    local decodeOk, decoded = pcall(HttpService.JSONDecode, HttpService, body)
    if not decodeOk or type(decoded) ~= "table" then
        return false
    end
    self.StateData.Active = decoded.Active == true
    self.StateData.TargetCategory = tostring(decoded.TargetCategory or "")
    self.StateData.VisitedJobs = type(decoded.VisitedJobs) == "table" and decoded.VisitedJobs or {}
    self.StateData.HopCount = math.max(0, math.floor(tonumber(decoded.HopCount) or 0))
    self.StateData.StartedAt = tonumber(decoded.StartedAt) or 0
    self.StateData.LastHopAt = tonumber(decoded.LastHopAt) or 0
    if self.StateData.TargetCategory ~= "" then
        self.Runtime.Config.Finder.TargetCategory = self.StateData.TargetCategory
    end
    return true
end

function EggFinder:_save()
    if type(writefile) ~= "function" then
        return false, "Executor file write API unavailable"
    end
    ensureConfigFolder()
    local encodeOk, body = pcall(HttpService.JSONEncode, HttpService, self.StateData)
    if not encodeOk then
        return false, tostring(body)
    end
    local writeOk, reason = pcall(writefile, FINDER_STATE_PATH, body)
    if writeOk then
        return true, nil
    end
    return false, tostring(reason)
end

function EggFinder:_markVisited(jobId)
    jobId = tostring(jobId or "")
    if jobId == "" then
        return
    end
    for _, existing in ipairs(self.StateData.VisitedJobs) do
        if existing == jobId then
            return
        end
    end
    self.StateData.VisitedJobs[#self.StateData.VisitedJobs + 1] = jobId
    local maximum = math.max(25, math.floor(tonumber(self.Runtime.Config.Finder.MaximumVisitedServers) or 250))
    while #self.StateData.VisitedJobs > maximum do
        table.remove(self.StateData.VisitedJobs, 1)
    end
end

function EggFinder:_visitedSet()
    local result = {}
    for _, jobId in ipairs(self.StateData.VisitedJobs) do
        result[tostring(jobId)] = true
    end
    return result
end

function EggFinder:start(targetCategory)
    local target = tostring(targetCategory or self.Runtime.Config.Finder.TargetCategory or "")
        :gsub("^%s+", "")
        :gsub("%s+$", "")
    if target == "" then
        return false, "Choose an egg type before starting Egg Finder"
    end
    for key in pairs(self.Runtime.Config.Features) do
        self.Runtime.Config.Features[key] = false
    end
    self.Runtime.Config.Finder.TargetCategory = target
    self.StateData = {
        Active = true,
        TargetCategory = target,
        VisitedJobs = {game.JobId},
        HopCount = 0,
        StartedAt = os.time(),
        LastHopAt = 0,
    }
    self.TeleportPending = false
    self.NextScanAt = 0
    local saved, saveReason = self:_save()
    if not saved then
        self.StateData.Active = false
        return false, "Egg Finder could not persist teleport state: " .. tostring(saveReason)
    end
    self.Runtime:queueConfigSave()
    self.Runtime:setStatus("egg_finder", "Scanning", "Searching this server for " .. target)
    return true, "Egg Finder started for " .. target
end

function EggFinder:stop(reason)
    local wasActive = self.StateData.Active == true
    self.StateData.Active = false
    self.TeleportPending = false
    self:_save()
    self.Runtime:setStatus("egg_finder", "Stopped", reason or "Stopped by user")
    return wasActive, reason or "Egg Finder stopped"
end

function EggFinder:beforeTeleport(targetJobId)
    self:_markVisited(game.JobId)
    self:_markVisited(targetJobId)
    self.StateData.HopCount = (tonumber(self.StateData.HopCount) or 0) + 1
    self.StateData.LastHopAt = os.time()
    self.TeleportPending = true
    self.Runtime.Session.FinderHops += 1
    self:_save()
    self.Runtime:setStatus(
        "egg_finder",
        "Hopping",
        string.format("Server %d • looking for %s", self.StateData.HopCount, self.StateData.TargetCategory)
    )
end

function EggFinder:teleportFailed(reason)
    self.TeleportPending = false
    self.NextScanAt = os.clock() + 2
    self.Runtime:setStatus("egg_finder", "Retrying", "Teleport failed: " .. tostring(reason))
end

function EggFinder:scan()
    local target = string.lower(tostring(self.StateData.TargetCategory or ""))
    if target == "" then
        return nil, 0
    end
    self.GameState.LastAreaRefreshAt = -math.huge
    local candidates = self.GameState:eggCandidates(ALL_AREAS, 0, true)
    for _, candidate in ipairs(candidates) do
        if string.lower(tostring(candidate.Category or "")) == target then
            return candidate, #candidates
        end
    end
    return nil, #candidates
end

function EggFinder:tick()
    if self.StateData.Active ~= true or self.TeleportPending or self.Runtime.Destroyed then
        return false
    end
    local now = os.clock()
    if now < self.NextScanAt then
        return false
    end
    self.NextScanAt = now + math.max(0.5, tonumber(self.Runtime.Config.Finder.ScanDelay) or 2)
    local found, visibleCount = self:scan()
    if found then
        self.LastFound = found
        local target = self.StateData.TargetCategory
        self.StateData.Active = false
        self:_save()
        local message = string.format(
            "Found %s in %s after %d server hop%s",
            tostring(found.Category),
            tostring(found.AreaId),
            tonumber(self.StateData.HopCount) or 0,
            tonumber(self.StateData.HopCount) == 1 and "" or "s"
        )
        self.Runtime:setStatus("egg_finder", "Found", message)
        self.Runtime:notify("Egg Finder", message, 8)
        return true
    end
    self.Runtime:setStatus(
        "egg_finder",
        "Scanning",
        string.format("%d eggs checked • %s not found", visibleCount, self.StateData.TargetCategory)
    )
    local hopped, hopReason = self.Utilities:serverHop(false, {
        Finder = true,
        VisitedJobs = self:_visitedSet(),
    })
    if not hopped then
        if tostring(hopReason) == "No alternate public server found" and #self.StateData.VisitedJobs > 1 then
            self.StateData.VisitedJobs = {game.JobId}
            self:_save()
            self.NextScanAt = os.clock() + 1
            return false
        end
        self.Runtime:setStatus("egg_finder", "Retrying", tostring(hopReason))
    end
    return hopped
end

local eggFinder = EggFinder.new(runtime, state, utilities)
runtime.EggFinder = eggFinder
runtime:track(TeleportService.TeleportInitFailed:Connect(function(player, _, errorMessage)
    if player == LocalPlayer and eggFinder.StateData.Active then
        eggFinder:teleportFailed(errorMessage)
    end
end))
runtime:spawn("egg-finder", 0.25, function()
    eggFinder:tick()
end)

local function schedulerSafetyDecision(now, resumeAt, characterReady, rootAnchored, lastActionAt, spacingSeconds)
    now = tonumber(now) or 0
    if now < (tonumber(resumeAt) or 0) then
        return false, "Startup quarantine"
    end
    if characterReady ~= true or rootAnchored == true then
        return false, "Character recovery"
    end
    if now - (tonumber(lastActionAt) or -math.huge) < (tonumber(spacingSeconds) or 0) then
        return false, "Action spacing"
    end
    return true, nil
end

local Scheduler = {}
Scheduler.__index = Scheduler

function Scheduler.new(owner)
    return setmetatable({
        Runtime = owner,
        Jobs = {},
        Running = false,
        Dispatching = false,
        LastActionFinishedAt = -math.huge,
        ActionSpacingSeconds = 0.15,
    }, Scheduler)
end

function Scheduler:register(name, featureKey, interval, callback, predicate, maxBackoff, continuous)
    self.Jobs[#self.Jobs + 1] = {
        Name = name,
        FeatureKey = featureKey,
        Interval = interval,
        Callback = callback,
        Predicate = predicate,
        MaxBackoff = maxBackoff,
        Continuous = continuous == true,
        NextAt = 0,
        Failures = 0,
        Runs = 0,
    }
end

function Scheduler:_enabled(job)
    local config = self.Runtime.Config
    local enabled = schedulerFeatureEnabled(config.Features[job.FeatureKey])
    if not enabled then
        return false
    end
    if type(job.Predicate) == "function" then
        local ok, value = pcall(job.Predicate)
        return ok and value == true
    end
    return true
end

function Scheduler:step(now)
    if self.Runtime.Destroyed or self.Runtime.Busy or self.Dispatching then
        return false
    end
    now = tonumber(now) or os.clock()
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local schedulerAllowed = schedulerSafetyDecision(
        now,
        self.Runtime.AutomationResumeAt,
        character ~= nil and root ~= nil and humanoid ~= nil and humanoid.Health > 0,
        root and root.Anchored,
        self.LastActionFinishedAt,
        self.ActionSpacingSeconds
    )
    if not schedulerAllowed then
        return false
    end
    for _, job in ipairs(self.Jobs) do
        if self:_enabled(job) and now >= job.NextAt then
            job.NextAt = now + job.Interval
            self.Dispatching = true
            task.spawn(function()
                local actionOk, callbackOk, callbackMessage = self.Runtime:runAction(job.Name, job.Callback)
                self.LastActionFinishedAt = os.clock()
                self.Dispatching = false
                local outcome, reason = classifySchedulerOutcome(actionOk, callbackOk, callbackMessage)
                job.Runs += 1
                if outcome == "success" then
                    job.Failures = 0
                    job.NextAt = os.clock() + job.Interval
                    self.Runtime:setStatus(job.FeatureKey, "Working", reason)
                elseif outcome == "idle" then
                    job.Failures = 0
                    job.NextAt = os.clock() + job.Interval
                    self.Runtime:setStatus(job.FeatureKey, "Waiting", reason)
                else
                    if job.Continuous then
                        job.Failures = 0
                        job.NextAt = os.clock() + job.Interval
                        self.Runtime:setStatus(job.FeatureKey, "Looping", reason)
                    else
                        job.Failures = math.min(8, job.Failures + 1)
                        local maximumBackoff = tonumber(job.MaxBackoff) or math.max(job.Interval, 60)
                        job.NextAt = os.clock() + nextBackoff(job.Failures, job.Interval, maximumBackoff)
                        self.Runtime:setStatus(job.FeatureKey, "Retrying", reason)
                    end
                end
            end)
            return true
        end
    end
    return false
end

function Scheduler:reset(featureKey)
    for _, job in ipairs(self.Jobs) do
        if not featureKey or job.FeatureKey == featureKey then
            job.NextAt = 0
            job.Failures = 0
        end
    end
end

function Scheduler:start()
    if self.Running then
        return
    end
    self.Running = true
    self.Runtime:spawn("main-scheduler", 0.05, function()
        self:step(os.clock())
    end)
end

local scheduler = Scheduler.new(runtime)
runtime.Scheduler = scheduler

scheduler:register("Fast egg pipeline", "steal_best_egg", 0.05, function()
    local eggConfig = runtime.Config.Egg or {}
    for _, job in ipairs(scheduler.Jobs) do
        if job.FeatureKey == "steal_best_egg" then
            job.Interval = clampFinite(eggConfig.StealInterval, 0.02, 2, 0.05)
        elseif job.FeatureKey == "place_eggs" then
            job.Interval = clampFinite(eggConfig.PlaceInterval, 0.1, 3, 0.25)
        elseif job.FeatureKey == "hatch_ready" then
            job.Interval = clampFinite(eggConfig.HatchInterval, 0.3, 5, 0.8)
        end
    end
    return eggAutomation:runFastPipelineOnce()
end, nil, 0.05, true)
scheduler:register("Place carried egg", "place_eggs", 0.25, function()
    return eggAutomation:placeOnce()
end, function()
    return runtime.Config.Features.steal_best_egg ~= true
end)
scheduler:register("Hatch ready egg", "hatch_ready", 0.8, function()
    return eggAutomation:hatchOnce()
end, function()
    return runtime.Config.Features.steal_best_egg ~= true
end)
scheduler:register("Equip best pets", "equip_best", 8, function()
    return eggAutomation:equipBest()
end)
scheduler:register("Smart sell pets", "smart_sell", 8, function()
    return petAutomation:sellOnce()
end)
scheduler:register("Sell selected eggs", "auto_sell_eggs", 3, function()
    return petAutomation:sellEggsOnce()
end)
scheduler:register("Fuse pets", "auto_fuse", 12, function()
    return petAutomation:fuseCycle()
end)
scheduler:register("Train speed", "treadmill_train", 3, function()
    return progressionAutomation:train()
end)
scheduler:register("Upgrade treadmill", "treadmill_upgrade", 6, function()
    return progressionAutomation:upgradeTreadmill()
end)
scheduler:register("Upgrade base", "base_upgrade", 6, function()
    return progressionAutomation:upgradeBase()
end)
scheduler:register("Claim group reward", "group_reward", 60, function()
    return rewardAutomation:groupReward()
end)
scheduler:register("Claim index rewards", "index_rewards", 30, function()
    return rewardAutomation:indexRewards()
end)
scheduler:register("Refresh rare egg markers", "rare_egg_esp", 2.5, function()
    return visuals:refresh()
end)

local function selectedAreasFromUi(values)
    return chooseTargetAreas(values, ALL_AREAS)
end

local function loadVoidHubLibrary()
    local url = VOIDHUB_UI_BASE_URL .. "Library.lua"
    local fetched, source = pcall(game.HttpGet, game, url)
    if not fetched then
        error("ObsidianUltra fetch failed: " .. tostring(source), 0)
    end
    local chunk, compileError = loadstring(source, "VoidHub UI")
    if not chunk then
        error("ObsidianUltra compile failed: " .. tostring(compileError), 0)
    end
    local initialized, Library = pcall(chunk)
    if not initialized or type(Library) ~= "table" then
        error("ObsidianUltra initialize failed: " .. tostring(Library), 0)
    end
    return Library
end

local LAST_LABEL_TEXT = setmetatable({}, {__mode = "k"})

local function setLabel(label, text)
    if not label then
        return
    end
    text = tostring(text)
    local previous = LAST_LABEL_TEXT[label]
    if previous ~= nil and not shouldUpdateUiValue(previous, text) then
        return
    end
    LAST_LABEL_TEXT[label] = text
    if typeof(label) == "Instance" then
        pcall(function()
            label.Text = text
        end)
        return
    end
    local setTextOk, setText = pcall(function()
        return label.SetText
    end)
    if setTextOk and type(setText) == "function" then
        pcall(setText, label, text)
        return
    end
    local setOk, set = pcall(function()
        return label.Set
    end)
    if setOk and type(set) == "function" then
        pcall(set, label, text)
    end
end

local function buildUi()
    local Library = loadVoidHubLibrary()
    local uiFlagPrefix = "steal_egg."
    local ui = createVoidHubUi(Library, {
        Key = Enum.KeyCode.RightAlt,
        Folder = CONFIG_FOLDER,
    })
    local win = ui:Window({
        Title = "VoidHub",
        Icon = VOIDHUB_ICON,
    })
    local Window = ui
    runtime.Window = ui
    win:Footer({
        Version = "v" .. VERSION,
        Credit = VOIDHUB_CREDIT,
        Discord = VOIDHUB_DISCORD,
    })
    ui:Watermark({Title = "VoidHub"})
    local uiBindings = {}
    runtime.UiBindings = uiBindings

    local function bindControl(id, control, read, apply)
        uiBindings[id] = {Control = control, Read = read, Apply = apply}
        return control
    end

    local function bindSliderControl(id, control, read)
        return bindControl(id, control, read, function(target, value)
            target:Set(value, true, true)
        end)
    end

    local function syncUiFromRuntimeConfig()
        local synchronized = syncControlBindings(uiBindings)
        runtime.LastUiSyncCount = synchronized
        return synchronized
    end
    runtime.SyncUiFromRuntimeConfig = syncUiFromRuntimeConfig

    local FLOW_TAB_ICONS = {
        ["Eggs"] = "egg",
        ["Events"] = "swords",
        ["Pets & Economy"] = "heart",
        ["Progression"] = "trending-up",
        ["Rewards"] = "star",
        ["Visuals"] = "eye",
        ["Utilities"] = "wand",
        ["Diagnostics"] = "info",
        ["Settings"] = "settings",
    }

    local FLOW_FEATURE_ICONS = {
        ["stealGroup"] = "rotate-cw",
        ["eggPolicyGroup"] = "sliders-horizontal",
        ["worldSpawnPredictorGroup"] = "sparkles",
        ["finderGroup"] = "radar",
        ["petAutomationGroup"] = "users",
        ["fusionPolicyGroup"] = "flask-conical",
        ["eggSellingGroup"] = "coins",
        ["economyPolicyGroup"] = "shield-check",
        ["trainingGroup"] = "dumbbell",
        ["progressionGroup"] = "trophy",
        ["rewardGroup"] = "gift",
        ["codesGroup"] = "ticket",
        ["visualGroup"] = "scan-eye",
        ["visualInfoGroup"] = "activity",
        ["travelGroup"] = "map-pin",
        ["flyGroup"] = "plane",
        ["godmodeGroup"] = "lock-keyhole",
        ["sessionGroup"] = "clock",
        ["endpointGroup"] = "link-2",
        ["transportGroup"] = "move-3d",
        ["liveGroup"] = "signal-high",
        ["movementGroup"] = "target",
        ["configGroup"] = "cog",
        ["dpiGroup"] = "monitor",
    }

    local FlowModule = {}
    FlowModule.__index = function(self, key)
        return FlowModule[key] or self.Card[key]
    end
    
    local function flowControl(control)
    return control
end

local function flowDescription(opts)
        opts = opts or {}
        opts.Desc = opts.Desc or opts.Description
        return opts
    end
    
    function FlowModule:Toggle(opts)
        return flowControl(self.Card:Toggle(flowDescription(opts)))
    end
    
    function FlowModule:Slider(opts)
        opts = flowDescription(opts)
        opts.Step = opts.Step or opts.Increment
        if opts.Decimals and opts.Decimals > 0 and not opts.Step then
            opts.Step = 10 ^ -opts.Decimals
        end
        return flowControl(self.Card:Slider(opts))
    end
    
    local function flowOptionKey(values)
        local out = {}
        for _, value in ipairs(values or {}) do
            out[#out + 1] = tostring(value)
        end
        return table.concat(out, "\0")
    end
    
    function FlowModule:Dropdown(opts)
        opts = flowDescription(opts)
        local provider = opts.OptionsProvider
        if not opts.Options and type(provider) == "function" then
            local ok, values = pcall(provider)
            opts.Options = ok and type(values) == "table" and values or {}
        end
        local control = flowControl(self.Card:Dropdown(opts))
        if type(provider) == "function" then
            local last = flowOptionKey(opts.Options)
            function control:Pull()
                local ok, values = pcall(provider)
                if not ok or type(values) ~= "table" then
                    return
                end
                local nextKey = flowOptionKey(values)
                if nextKey ~= last then
                    last = nextKey
                    self:Options(values)
                end
            end
            if opts.AutoRefresh then
                task.spawn(function()
                    while control.Frame and control.Frame.Parent do
                        task.wait(tonumber(opts.RefreshInterval) or 5)
                        control:Pull()
                    end
                end)
            end
        end
        return control
    end
    
    function FlowModule:Button(opts)
        return flowControl(self.Card:Button(flowDescription(opts)))
    end
    
    local function flowSetLabel(control, value)
        if not control then
            return
        end
        if type(control.SetText) == "function" then
            control:SetText(tostring(value))
        elseif control.Raw and type(control.Raw.SetText) == "function" then
            control.Raw:SetText(tostring(value))
        end
    end
    
    function FlowModule:Label(opts)
        if type(opts) == "string" then
            opts = {Text = opts}
        end
        opts = opts or {}
        local text = opts.Text or opts.Name or ""
        local control = self.Card:Label(opts.Wrap and {Desc = text} or {Name = text})
        local label = {Frame = control.Frame, Value = tostring(text)}
        function label:Set(value)
            self.Value = tostring(value)
            flowSetLabel(control, self.Value)
        end
        label.SetText = label.Set
        setmetatable(label, {
            __index = function(_, key)
                if key == "Text" then
                    return label.Value
                end
                return control[key]
            end,
            __newindex = function(target, key, value)
                if key == "Text" then
                    target:Set(value)
                else
                    rawset(target, key, value)
                end
            end,
        })
        return label
    end
    
    function FlowModule:Divider()
        return self.Card:Divider()
    end
    
    function FlowModule:Color(opts)
        return flowControl(self.Card:Color(flowDescription(opts)))
    end
    
    function FlowModule:Input(opts)
        opts = flowDescription(opts)
        opts.OnEnter = opts.OnEnter or (opts.EnterOnly and true or nil)
        return flowControl(self.Card:Input(opts))
    end
    
    function FlowModule:Keybind(opts)
        opts = flowDescription(opts)
        local pressed = opts.Callback
        local changed = opts.ChangedCallback
        opts.OnPress = pressed
        opts.Callback = changed
        local control = flowControl(self.Card:Keybind(opts))
        table.insert(ui.binds, {
            Name = opts.Name or self.Name or "Keybind",
            Icon = FLOW_FEATURE_ICONS[self.Key],
            Control = control,
        })
        return control
    end
    
    function FlowModule:Set(value)
        return self.Card:Set(value)
    end
    
    function FlowModule:Expand(value)
        return self.Card:Expand(value)
    end
    
    function FlowModule:Destroy()
        if self.Card and self.Card.Frame then
            self.Card.Frame:Destroy()
        end
    end
    
    local function flowModule(tab, key, opts)
        opts = opts or {}
        local card = tab:Module({
            Name = opts.Name or tostring(key),
            Icon = FLOW_FEATURE_ICONS[key],
            Column = opts.Column or (opts.Side == "Right" and 2 or 1),
            Default = true,
            Expanded = true,
        })
        if card.Switch and card.Switch.Frame then
            card.Switch.Frame.Visible = false
        end
        if card.BindControl and card.BindControl.Frame then
            card.BindControl.Frame.Visible = false
        end
        return setmetatable({
            Card = card,
            Frame = card.Frame,
            Name = opts.Name,
            Side = opts.Side,
            Key = key,
        }, FlowModule)
    end

    local NAVIGATION = {
        {Name = "Farming", Icon = "egg", Pages = {"Eggs", "Events"}},
        {Name = "Economy", Icon = "coins", Pages = {"Pets & Economy", "Progression", "Rewards"}},
        {Name = "Visuals", Icon = "eye", Pages = {"Visuals"}},
        {Name = "Utility", Icon = "wand", Pages = {"Utilities", "Diagnostics"}},
        {Name = "Settings", Icon = "settings", Pages = {"Settings"}},
    }

    local tabs = {}
    for index, entry in ipairs(NAVIGATION) do
        local tab = win:Tab({Name = entry.Name, Icon = entry.Icon, Description = entry.Description})
        if #entry.Pages == 1 then
            tabs[entry.Pages[1]] = tab
        else
            tab:AlignSubTabs("Left")
            for _, page in ipairs(entry.Pages) do
                tabs[page] = tab:SubTab({Name = page, Icon = FLOW_TAB_ICONS[page]})
            end
        end
        if index == 1 then
            win:Select(tab)
        end
    end

    local function group(tab, key, name, side)
        return flowModule(tab, key, {Name = name, Side = side or "Left"})
    end

    local function saveSetting(featureKey)
        runtime:queueConfigSave()
        scheduler:reset(featureKey)
    end

    local function cleanMessage(message)
        local text = tostring(message or "")
        if text == "" then
            return "Nothing to do"
        end
        if text:find("Unavailable") or text:find("endpoint") or text:find("expected")
            or text:find("attempt to") or text:find("%.lua") or text:find(":%d")
            or text:find("union") or text:match("%a+:%s*%a") then
            return "Not available in this game"
        end
        return text
    end

    local function runAsync(name, callback)
        task.spawn(function()
            local actionOk, resultOk, message = runtime:runAction(name, callback)
            if actionOk and resultOk then
                runtime:notify(name, message or "Completed")
            else
                runtime:notify(name, cleanMessage(actionOk and message or resultOk), 3.5)
            end
        end)
    end

    local function applyAutomationSelection(enabledFeatures, message)
        setFeatureSelection(runtime.Config.Features, FEATURE_KEYS, enabledFeatures)
        if not runtime.Config.Features.treadmill_train then
            progressionAutomation:stopTraining()
        end
        if not runtime.Config.Features.rare_egg_esp then
            visuals:destroyMarkers()
        end
        syncUiFromRuntimeConfig()
        runtime:queueConfigSave()
        scheduler:reset()
        runtime:notify("Automation", message)
    end

    local function addFeatureToggle(targetGroup, label, featureKey, afterChange)
        return bindControl("feature." .. featureKey, targetGroup:Toggle({
            Name = label,
            Flag = uiFlagPrefix .. featureKey,
            Default = runtime.Config.Features[featureKey] == true,
            Callback = function(value)
                local enabled = value == true
                runtime.Config.Features[featureKey] = enabled
                if type(afterChange) == "function" then
                    afterChange(enabled)
                end
                saveSetting(featureKey)
            end,
        }), function() return runtime.Config.Features[featureKey] == true end)
    end

    local stealGroup = group(tabs.Eggs, "stealGroup", "Auto Steal", "Left")
    addFeatureToggle(stealGroup, "Auto Steal Best Egg", "steal_best_egg")
    addFeatureToggle(stealGroup, "Auto Place Carried Eggs", "place_eggs")
    addFeatureToggle(stealGroup, "Auto Open Ready Eggs", "hatch_ready")
    local currentTargetLabel = stealGroup:Label({Text = "Target: scanning...", Wrap = true})
    local eggStatusLabel = stealGroup:Label({Text = "Steal status loading...", Wrap = true})
    local automationStateLabel = stealGroup:Label({Text = "Active toggles: 0", Wrap = true})
    local sessionLabel = stealGroup:Label({Text = "Session totals loading...", Wrap = true})
    stealGroup:Button({Name = "Steal Now", Callback = function() runAsync("Steal", function() return eggAutomation:stealOnce() end) end})
    stealGroup:Button({Name = "Place Now", Callback = function() runAsync("Place", function() return eggAutomation:placeOnce() end) end})
    stealGroup:Button({Name = "Open Eggs Now", Callback = function() runAsync("Open eggs", function() return eggAutomation:hatchOnce() end) end})
    stealGroup:Button({Name = "Equip Best Pets", Callback = function() runAsync("Equip best", function() return eggAutomation:equipBest() end) end})

    local worldPredictorGroup = group(tabs.Eggs, "worldSpawnPredictorGroup", "Future World Spawns", "Left")
    bindControl("predictor.enabled", worldPredictorGroup:Toggle({
        Name = "Enable Spawn Predictor",
        Flag = uiFlagPrefix .. "predictor_enabled",
        Default = runtime.Config.Predictor.Enabled == true,
        Callback = function(value)
            runtime.Config.Predictor.Enabled = value == true
            worldSpawnPredictor.NextForecastAt = 0
            runtime:queueConfigSave()
        end,
    }), function() return runtime.Config.Predictor.Enabled == true end)
    local predictorAreaOptions = {"All Areas"}
    for _, areaId in ipairs(ALL_AREAS) do predictorAreaOptions[#predictorAreaOptions + 1] = areaId end
    bindControl("predictor.area", worldPredictorGroup:Dropdown({
        Name = "Forecast Area",
        Flag = uiFlagPrefix .. "predictor_area",
        Options = predictorAreaOptions,
        Default = runtime.Config.Predictor.SelectedArea,
        Callback = function(value)
            value = tostring(value or "All Areas")
            runtime.Config.Predictor.SelectedArea = value == "All Areas"
                and value
                or (worldSpawnPredictor:_canonicalArea(value) or "All Areas")
            worldSpawnPredictor.NextForecastAt = 0
            runtime:queueConfigSave()
        end,
    }), function() return runtime.Config.Predictor.SelectedArea end)
    bindSliderControl("predictor.count", worldPredictorGroup:Slider({
        Name = "Forecast Results",
        Flag = uiFlagPrefix .. "predictor_count",
        Min = 1,
        Max = 8,
        Default = runtime.Config.Predictor.ForecastCount,
        Increment = 1,
        Callback = function(value)
            runtime.Config.Predictor.ForecastCount = math.clamp(math.floor(tonumber(value) or 5), 1, 8)
            worldSpawnPredictor.NextForecastAt = 0
            runtime:queueConfigSave()
        end,
    }), function() return runtime.Config.Predictor.ForecastCount end)
    bindControl("predictor.notify", worldPredictorGroup:Toggle({
        Name = "Notify On Server Commit",
        Flag = uiFlagPrefix .. "predictor_notify",
        Default = runtime.Config.Predictor.NotifyCommitted == true,
        Callback = function(value)
            runtime.Config.Predictor.NotifyCommitted = value == true
            runtime:queueConfigSave()
        end,
    }), function() return runtime.Config.Predictor.NotifyCommitted == true end)
    local worldPredictionLabel = worldPredictorGroup:Label({
        Text = worldSpawnPredictor.LastText,
        Wrap = true,
    })
    worldPredictorGroup:Button({Name = "Deep Probe & Predict", Callback = function()
        task.spawn(function()
            local refreshed, prediction = worldSpawnPredictor:refresh(true)
            setLabel(worldPredictionLabel, tostring(prediction))
            runtime:notify(
                "World Spawn Predictor",
                refreshed and "Replicated schedule, metadata, drop tables, and luck rescanned" or tostring(prediction),
                refreshed and 4 or 7
            )
        end)
    end})
    worldPredictorGroup:Button({Name = "Reset Calibration", Callback = function()
        local saved, reason = worldSpawnPredictor:resetHistory()
        worldSpawnPredictor:refresh(false)
        setLabel(worldPredictionLabel, worldSpawnPredictor.LastText)
        runtime:notify("World Spawn Predictor", saved and "Learned calibration cleared" or tostring(reason), 4)
    end})

    local eggTypeSet = {}
    for _, egg in ipairs(state:getEggInventory()) do
        local category = egg.AssetCategory or egg.Category
        if category then
            eggTypeSet[tostring(category)] = true
        end
    end
    local assetDirectory = state.Modules.Assets
    local assetSource = type(assetDirectory) == "table"
        and (assetDirectory.Directory or assetDirectory.Assets or assetDirectory)
        or {}
    for category, assetConfig in pairs(assetSource) do
        if type(category) == "string" and type(assetConfig) == "table" and assetConfig.Rarity ~= nil then
            eggTypeSet[category] = true
        end
    end
    local eggTypeOptions = {}
    for category in pairs(eggTypeSet) do
        eggTypeOptions[#eggTypeOptions + 1] = category
    end
    table.sort(eggTypeOptions)

    local eggPolicyGroup = group(tabs.Eggs, "eggPolicyGroup", "Target Policy", "Right")
    bindControl("egg.target_mode", eggPolicyGroup:Dropdown({
        Name = "Target Mode",
        Flag = uiFlagPrefix .. "target_mode",
        Options = {"Best Value", "Heaviest Weight", "Largest Size", "Highest Rarity", "Mutations", "Highest Area", "Nearest"},
        Default = runtime.Config.Egg.TargetMode,
        Callback = function(value) runtime.Config.Egg.TargetMode = value saveSetting("steal_best_egg") end,
    }), function() return runtime.Config.Egg.TargetMode end)
    bindControl("egg.custom_steal_speed", eggPolicyGroup:Input({
        Name = "Custom Steal Speed",
        Flag = uiFlagPrefix .. "steal_speed",
        Default = tostring(runtime.Config.Egg.CustomStealSpeed or 0),
        Placeholder = "Enter any speed (for example 500)",
        EnterOnly = true,
        Callback = function(value)
            runtime.Config.Egg.CustomStealSpeed = customStealSpeed(value)
            saveSetting("steal_best_egg")
        end,
    }), function() return tostring(runtime.Config.Egg.CustomStealSpeed or 0) end)
    bindSliderControl("egg.steal_interval", eggPolicyGroup:Slider({
        Name = "Steal Retry Interval",
        Flag = uiFlagPrefix .. "steal_interval",
        Min = 0.02,
        Max = 1.5,
        Default = runtime.Config.Egg.StealInterval or 0.05,
        Increment = 0.05,
        Callback = function(value)
            runtime.Config.Egg.StealInterval = value
            saveSetting("steal_best_egg")
            if runtime.Scheduler then
                runtime.Scheduler:reset("steal_best_egg")
            end
        end,
    }), function() return runtime.Config.Egg.StealInterval or 0.05 end)
    bindSliderControl("egg.place_interval", eggPolicyGroup:Slider({
        Name = "Place Interval",
        Flag = uiFlagPrefix .. "place_interval",
        Min = 0.1,
        Max = 2,
        Default = runtime.Config.Egg.PlaceInterval or 0.25,
        Increment = 0.05,
        Callback = function(value)
            runtime.Config.Egg.PlaceInterval = value
            saveSetting("place_eggs")
            if runtime.Scheduler then
                runtime.Scheduler:reset("place_eggs")
            end
        end,
    }), function() return runtime.Config.Egg.PlaceInterval or 0.25 end)
    bindSliderControl("egg.hatch_interval", eggPolicyGroup:Slider({
        Name = "Hatch Interval",
        Flag = uiFlagPrefix .. "hatch_interval",
        Min = 0.3,
        Max = 4,
        Default = runtime.Config.Egg.HatchInterval or 0.8,
        Increment = 0.1,
        Callback = function(value)
            runtime.Config.Egg.HatchInterval = value
            saveSetting("hatch_ready")
            if runtime.Scheduler then
                runtime.Scheduler:reset("hatch_ready")
            end
        end,
    }), function() return runtime.Config.Egg.HatchInterval or 0.8 end)
    bindSliderControl("egg.snapshot_age", eggPolicyGroup:Slider({
        Name = "Egg Snapshot Max Age",
        Flag = uiFlagPrefix .. "snapshot_age",
        Min = 0.02,
        Max = 0.5,
        Default = runtime.Config.Egg.SnapshotMaxAge or 0.08,
        Increment = 0.02,
        Callback = function(value)
            runtime.Config.Egg.SnapshotMaxAge = value
            saveSetting("steal_best_egg")
        end,
    }), function() return runtime.Config.Egg.SnapshotMaxAge or 0.08 end)
    eggPolicyGroup:Label({Text = "Fast loop • 0 = automatic speed", Wrap = true})
    bindControl("egg.areas", eggPolicyGroup:Dropdown({ Multi = true,
        Name = "Allowed Areas",
        Flag = uiFlagPrefix .. "areas",
        Options = ALL_AREAS,
        Default = buildTargetAreaSet(runtime.Config.Egg.SelectedAreas),
        Callback = function(values) runtime.Config.Egg.SelectedAreas = selectedAreasFromUi(values) saveSetting("steal_best_egg") end,
    }), function() return buildTargetAreaSet(runtime.Config.Egg.SelectedAreas) end)
    bindControl("egg.categories", eggPolicyGroup:Dropdown({ Multi = true,
        Name = "Allowed Egg Types (empty = all)",
        Flag = uiFlagPrefix .. "target_categories",
        Options = eggTypeOptions,
        Default = runtime.Config.Egg.SelectedCategories,
        Callback = function(values)
            runtime.Config.Egg.SelectedCategories = values or {}
            saveSetting("steal_best_egg")
        end,
    }), function() return runtime.Config.Egg.SelectedCategories end)
    bindControl("egg.size_tier", eggPolicyGroup:Dropdown({
        Name = "Minimum Egg Size",
        Flag = uiFlagPrefix .. "size_tier",
        Options = {"Any Size", "Big+ (1.45x)", "Huge+ (1.9x)", "Giant+ (2.85x)", "Colossal+ (5.8x)", "Titanic+ (9.5x)"},
        Default = runtime.Config.Egg.SizeTier,
        Callback = function(value)
            runtime.Config.Egg.SizeTier = value
            saveSetting("steal_best_egg")
        end,
    }), function() return runtime.Config.Egg.SizeTier end)
    bindControl("egg.mutation_requirement", eggPolicyGroup:Dropdown({
        Name = "Mutation Requirement",
        Flag = uiFlagPrefix .. "mutation_requirement",
        Options = {"Any", "Mutated Only", "No Mutation"},
        Default = runtime.Config.Egg.MutationRequirement,
        Callback = function(value)
            runtime.Config.Egg.MutationRequirement = value
            saveSetting("steal_best_egg")
        end,
    }), function() return runtime.Config.Egg.MutationRequirement end)
    bindControl("egg.minimum_weight", eggPolicyGroup:Input({
        Name = "Minimum Weight (Kg, 0 = any)",
        Flag = uiFlagPrefix .. "minimum_weight",
        Default = tostring(runtime.Config.Egg.MinimumWeightKg or 0),
        Placeholder = "0",
        EnterOnly = true,
        Callback = function(value)
            runtime.Config.Egg.MinimumWeightKg = math.max(0, tonumber(value) or 0)
            saveSetting("steal_best_egg")
        end,
    }), function() return tostring(runtime.Config.Egg.MinimumWeightKg or 0) end)
    bindSliderControl("egg.minimum_rarity", eggPolicyGroup:Slider({Name = "Min Rarity", Flag = uiFlagPrefix .. "min_rarity", Min = 1, Max = 9, Default = runtime.Config.Egg.MinimumRarity, Increment = 1, Callback = function(value)
        runtime.Config.Egg.MinimumRarity = value saveSetting("steal_best_egg")
    end}), function() return runtime.Config.Egg.MinimumRarity end)
    bindSliderControl("egg.placement_columns", eggPolicyGroup:Slider({Name = "Placement Columns", Flag = uiFlagPrefix .. "place_columns", Min = 1, Max = 6, Default = runtime.Config.Egg.PlacementColumns, Increment = 1, Callback = function(value)
        runtime.Config.Egg.PlacementColumns = value saveSetting("place_eggs")
    end}), function() return runtime.Config.Egg.PlacementColumns end)
    bindSliderControl("egg.placement_spacing", eggPolicyGroup:Slider({Name = "Placement Spacing", Flag = uiFlagPrefix .. "place_spacing", Min = 3, Max = 12, Default = runtime.Config.Egg.PlacementSpacing, Increment = 0.5, Callback = function(value)
        runtime.Config.Egg.PlacementSpacing = value saveSetting("place_eggs")
    end}), function() return runtime.Config.Egg.PlacementSpacing end)

    local finderGroup = group(tabs.Events, "finderGroup", "Cross-Server Egg Finder", "Right")
    local finderTarget = runtime.Config.Finder.TargetCategory or ""
    bindControl("finder.target", finderGroup:Input({
        Name = "Egg Type To Find",
        Flag = uiFlagPrefix .. "finder_target",
        Default = finderTarget,
        Placeholder = "Exact egg/pet category",
        EnterOnly = true,
        Callback = function(value)
            finderTarget = tostring(value or "")
            runtime.Config.Finder.TargetCategory = finderTarget
            runtime:queueConfigSave()
        end,
    }), function() return runtime.Config.Finder.TargetCategory or "" end)
    finderGroup:Button({Name = "Start Egg Finder", Callback = function()
        local ok, message = eggFinder:start(finderTarget)
        syncUiFromRuntimeConfig()
        runtime:notify("Egg Finder", tostring(message), ok and 4 or 6)
    end})
    finderGroup:Button({Name = "Scan This Server", Callback = function()
        local previousTarget = eggFinder.StateData.TargetCategory
        eggFinder.StateData.TargetCategory = finderTarget
        local found, count = eggFinder:scan()
        eggFinder.StateData.TargetCategory = previousTarget
        if found then
            runtime:notify("Egg Finder", string.format("Found %s in %s", found.Category, found.AreaId), 6)
        else
            runtime:notify("Egg Finder", string.format("Checked %d eggs; target not found", count), 4)
        end
    end})
    finderGroup:Button({Name = "Stop Egg Finder", Callback = function()
        local _, message = eggFinder:stop("Stopped by user")
        runtime:notify("Egg Finder", message)
    end})
    local finderStatusLabel = finderGroup:Label({Text = "Finder: inactive", Wrap = true})
    finderGroup:Label({Text = "Hops until the target category shows.", Wrap = true})

    local petAutomationGroup = group(tabs["Pets & Economy"], "petAutomationGroup", "Pet Automation", "Left")
    for _, entry in ipairs({
        {"Auto Equip Best", "equip_best"},
        {"Auto Sell Pets", "smart_sell"},
        {"Auto Fuse Pets", "auto_fuse"},
    }) do
        addFeatureToggle(petAutomationGroup, entry[1], entry[2])
    end
    petAutomationGroup:Button({Name = "Sell Pets Now", Callback = function() runAsync("Sell pets", function() return petAutomation:sellOnce() end) end})
    petAutomationGroup:Button({Name = "Fuse One Trio", Callback = function() runAsync("Fusion", function() return petAutomation:fuseOnce() end) end})
    petAutomationGroup:Button({Name = "Run Fusion Cycle", Callback = function() runAsync("Fusion cycle", function() return petAutomation:fuseCycle() end) end})

    local fusionPolicyGroup = group(tabs["Pets & Economy"], "fusionPolicyGroup", "Fusion Policy", "Left")
    bindControl("economy.fuse_strategy", fusionPolicyGroup:Dropdown({
        Name = "Fusion Strategy",
        Flag = uiFlagPrefix .. "fuse_strategy",
        Options = {"Lowest Value", "Smallest Size", "Largest Size"},
        Default = runtime.Config.Economy.FuseStrategy,
        Callback = function(value) runtime.Config.Economy.FuseStrategy = value saveSetting("auto_fuse") end,
    }), function() return runtime.Config.Economy.FuseStrategy end)
    bindControl("economy.fuse_category_mode", fusionPolicyGroup:Dropdown({
        Name = "Fusion Category Mode",
        Flag = uiFlagPrefix .. "fuse_category_mode",
        Options = {"All Categories", "Selected Only", "Exclude Selected"},
        Default = runtime.Config.Economy.FuseCategoryMode,
        Callback = function(value) runtime.Config.Economy.FuseCategoryMode = value saveSetting("auto_fuse") end,
    }), function() return runtime.Config.Economy.FuseCategoryMode end)
    bindControl("economy.fuse_categories", fusionPolicyGroup:Dropdown({ Multi = true,
        Name = "Fusion Pet Categories",
        Flag = uiFlagPrefix .. "fuse_categories",
        Options = eggTypeOptions,
        Default = runtime.Config.Economy.FuseCategories,
        Callback = function(values) runtime.Config.Economy.FuseCategories = values or {} saveSetting("auto_fuse") end,
    }), function() return runtime.Config.Economy.FuseCategories end)
    bindControl("economy.fuse_mutations", fusionPolicyGroup:Dropdown({
        Name = "Fusion Mutation Policy",
        Flag = uiFlagPrefix .. "fuse_mutations",
        Options = {"Protect", "Allow", "Mutated Only"},
        Default = runtime.Config.Economy.FuseMutationPolicy,
        Callback = function(value) runtime.Config.Economy.FuseMutationPolicy = value saveSetting("auto_fuse") end,
    }), function() return runtime.Config.Economy.FuseMutationPolicy end)
    bindSliderControl("economy.fuse_min_rarity", fusionPolicyGroup:Slider({
        Name = "Fusion Min Rarity", Flag = uiFlagPrefix .. "fuse_min_rarity", Min = 1, Max = 9,
        Default = runtime.Config.Economy.FuseMinimumRarity, Increment = 1,
        Callback = function(value) runtime.Config.Economy.FuseMinimumRarity = value saveSetting("auto_fuse") end,
    }), function() return runtime.Config.Economy.FuseMinimumRarity end)
    bindSliderControl("economy.fuse_max_rarity", fusionPolicyGroup:Slider({
        Name = "Fusion Max Rarity", Flag = uiFlagPrefix .. "fuse_max_rarity", Min = 1, Max = 9,
        Default = runtime.Config.Economy.FuseMaximumRarity, Increment = 1,
        Callback = function(value) runtime.Config.Economy.FuseMaximumRarity = value saveSetting("auto_fuse") end,
    }), function() return runtime.Config.Economy.FuseMaximumRarity end)
    bindSliderControl("economy.fuse_keep", fusionPolicyGroup:Slider({
        Name = "Keep Per Category", Flag = uiFlagPrefix .. "fuse_keep", Min = 0, Max = 20,
        Default = runtime.Config.Economy.FuseKeepPerCategory, Increment = 1,
        Callback = function(value) runtime.Config.Economy.FuseKeepPerCategory = value saveSetting("auto_fuse") end,
    }), function() return runtime.Config.Economy.FuseKeepPerCategory end)
    bindSliderControl("economy.fuse_cycle", fusionPolicyGroup:Slider({
        Name = "Fusions Per Cycle", Flag = uiFlagPrefix .. "fuse_cycle", Min = 1, Max = 10,
        Default = runtime.Config.Economy.FusionsPerCycle, Increment = 1,
        Callback = function(value) runtime.Config.Economy.FusionsPerCycle = value saveSetting("auto_fuse") end,
    }), function() return runtime.Config.Economy.FusionsPerCycle end)
    bindControl("economy.fuse_max_weight", fusionPolicyGroup:Input({
        Name = "Max Input Weight", Flag = uiFlagPrefix .. "fuse_max_weight",
        Default = tostring(runtime.Config.Economy.FuseMaximumWeightKg or 0), Placeholder = "0", EnterOnly = true,
        Callback = function(value) runtime.Config.Economy.FuseMaximumWeightKg = math.max(0, tonumber(value) or 0) saveSetting("auto_fuse") end,
    }), function() return tostring(runtime.Config.Economy.FuseMaximumWeightKg or 0) end)
    bindControl("economy.fuse_max_scale", fusionPolicyGroup:Input({
        Name = "Max Input Scale", Flag = uiFlagPrefix .. "fuse_max_scale",
        Default = tostring(runtime.Config.Economy.FuseMaximumScale or 0), Placeholder = "0", EnterOnly = true,
        Callback = function(value) runtime.Config.Economy.FuseMaximumScale = math.max(0, tonumber(value) or 0) saveSetting("auto_fuse") end,
    }), function() return tostring(runtime.Config.Economy.FuseMaximumScale or 0) end)
    bindControl("economy.fuse_max_price", fusionPolicyGroup:Input({
        Name = "Max Fusion Price", Flag = uiFlagPrefix .. "fuse_max_price",
        Default = tostring(runtime.Config.Economy.FuseMaximumPrice or 0), Placeholder = "0", EnterOnly = true,
        Callback = function(value) runtime.Config.Economy.FuseMaximumPrice = math.max(0, tonumber(value) or 0) saveSetting("auto_fuse") end,
    }), function() return tostring(runtime.Config.Economy.FuseMaximumPrice or 0) end)
    bindControl("economy.fuse_allow_equipped", fusionPolicyGroup:Toggle({
        Name = "Allow Equipped Pets", Flag = uiFlagPrefix .. "fuse_allow_equipped",
        Default = runtime.Config.Economy.FuseAllowEquipped,
        Callback = function(value) runtime.Config.Economy.FuseAllowEquipped = value == true saveSetting("auto_fuse") end,
    }), function() return runtime.Config.Economy.FuseAllowEquipped == true end)
    bindControl("economy.fuse_allow_favorites", fusionPolicyGroup:Toggle({
        Name = "Allow Favorite Pets", Flag = uiFlagPrefix .. "fuse_allow_favorites",
        Default = runtime.Config.Economy.FuseAllowFavorites,
        Callback = function(value) runtime.Config.Economy.FuseAllowFavorites = value == true saveSetting("auto_fuse") end,
    }), function() return runtime.Config.Economy.FuseAllowFavorites == true end)
    local fusionPreviewLabel = fusionPolicyGroup:Label({Text = "Next fusion: not previewed", Wrap = true})
    runtime.FusionPreviewLabel = fusionPreviewLabel
    fusionPolicyGroup:Button({Name = "Preview Next Fusion", Callback = function()
        local plan = petAutomation:selectFusePlan()
        if plan then
            setLabel(fusionPreviewLabel, string.format(
                "Next: %s • %s • value %.1f • avg %.2fx / %.2fkg • cost %.0f",
                table.concat(plan.Uids, ", "), tostring(plan.Category), tonumber(plan.Value) or 0,
                tonumber(plan.AverageScale) or 0, tonumber(plan.AverageWeightKg) or 0, tonumber(plan.Price) or 0
            ))
        else
            setLabel(fusionPreviewLabel, "Next fusion: no trio matches the current policy")
        end
    end})

    local eggSellingGroup = group(tabs["Pets & Economy"], "eggSellingGroup", "Egg Selling", "Right")
    addFeatureToggle(eggSellingGroup, "Auto Sell Eggs", "auto_sell_eggs")
    bindControl("economy.egg_sell_mode", eggSellingGroup:Dropdown({
        Name = "Egg Sell Mode",
        Flag = uiFlagPrefix .. "egg_sell_mode",
        Options = {"Selected Types", "All Eggs"},
        Default = runtime.Config.Economy.EggSellMode == "All Eggs" and "All Eggs" or "Selected Types",
        Callback = function(value)
            runtime.Config.Economy.EggSellMode = value == "All Eggs" and "All Eggs" or "Selected Types"
            saveSetting("auto_sell_eggs")
        end,
    }), function()
        return runtime.Config.Economy.EggSellMode == "All Eggs" and "All Eggs" or "Selected Types"
    end)
    bindControl("economy.egg_sell_types", eggSellingGroup:Dropdown({ Multi = true,
        Name = "Egg Types To Sell",
        Flag = uiFlagPrefix .. "egg_sell_types",
        Options = eggTypeOptions,
        Default = runtime.Config.Economy.EggSellTypes,
        Callback = function(values)
            runtime.Config.Economy.EggSellTypes = values or {}
            saveSetting("auto_sell_eggs")
        end,
    }), function() return runtime.Config.Economy.EggSellTypes end)
    bindSliderControl("economy.egg_sell_batch", eggSellingGroup:Slider({
        Name = "Eggs Per Sell Cycle",
        Flag = uiFlagPrefix .. "egg_sell_batch",
        Min = 1,
        Max = 100,
        Default = runtime.Config.Economy.EggSellBatchSize,
        Increment = 1,
        Callback = function(value)
            runtime.Config.Economy.EggSellBatchSize = value
            saveSetting("auto_sell_eggs")
        end,
    }), function() return runtime.Config.Economy.EggSellBatchSize end)
    eggSellingGroup:Button({Name = "Sell Eggs Now", Callback = function()
        runAsync("Sell eggs", function() return petAutomation:sellEggsOnce() end)
    end})
    eggSellingGroup:Label({Text = "All Eggs ignores the type list.", Wrap = true})

    local economyPolicyGroup = group(tabs["Pets & Economy"], "economyPolicyGroup", "Protection Policy", "Right")
    bindSliderControl("economy.sell_rarity", economyPolicyGroup:Slider({Name = "Sell Max Rarity", Flag = uiFlagPrefix .. "sell_rarity", Min = 1, Max = 9, Default = runtime.Config.Economy.SellMaxRarity, Increment = 1, Callback = function(value)
        runtime.Config.Economy.SellMaxRarity = value saveSetting("smart_sell")
    end}), function() return runtime.Config.Economy.SellMaxRarity end)
    bindSliderControl("economy.keep_count", economyPolicyGroup:Slider({Name = "Keep At Least", Flag = uiFlagPrefix .. "keep_count", Min = 0, Max = 100, Default = runtime.Config.Economy.KeepCount, Increment = 1, Callback = function(value)
        runtime.Config.Economy.KeepCount = value saveSetting("smart_sell")
    end}), function() return runtime.Config.Economy.KeepCount end)
    bindControl("economy.protect_sell_mutations", economyPolicyGroup:Toggle({Name = "Protect Mutations", Flag = uiFlagPrefix .. "sell_protect_mutations", Default = runtime.Config.Economy.ProtectMutations, Callback = function(value)
        runtime.Config.Economy.ProtectMutations = value == true saveSetting("smart_sell")
    end}), function() return runtime.Config.Economy.ProtectMutations == true end)
    economyPolicyGroup:Label({Text = "Fusion needs 3 pets of one category.", Wrap = true})

    local trainingGroup = group(tabs.Progression, "trainingGroup", "Speed & Treadmill", "Left")
    for _, entry in ipairs({
        {"Auto Static Treadmill", "treadmill_train"},
        {"Auto Treadmill Upgrade", "treadmill_upgrade"},
    }) do
        addFeatureToggle(trainingGroup, entry[1], entry[2])
    end
    trainingGroup:Button({Name = "Start Static Training", Callback = function() runAsync("Training", function() return progressionAutomation:train() end) end})
    trainingGroup:Button({Name = "Stop Static Training", Callback = function() progressionAutomation:stopTraining() end})
    trainingGroup:Button({Name = "Upgrade Treadmill Once", Callback = function() runAsync("Treadmill upgrade", function() return progressionAutomation:upgradeTreadmill() end) end})

    local progressionGroup = group(tabs.Progression, "progressionGroup", "Base & Rebirth", "Right")
    addFeatureToggle(progressionGroup, "Auto Base Upgrade", "base_upgrade")
    progressionGroup:Button({Name = "Upgrade Base Once", Callback = function() runAsync("Base upgrade", function() return progressionAutomation:upgradeBase() end) end})

    local rewardGroup = group(tabs.Rewards, "rewardGroup", "Automatic Claims", "Left")
    for _, entry in ipairs({
        {"Auto Group Reward", "group_reward"},
        {"Auto Index Rewards", "index_rewards"},
    }) do
        addFeatureToggle(rewardGroup, entry[1], entry[2])
    end
    rewardGroup:Button({Name = "Claim Index Rewards", Callback = function() runAsync("Index rewards", function() return rewardAutomation:indexRewards() end) end})

    local codesGroup = group(tabs.Rewards, "codesGroup", "Group & Limited", "Right")
    codesGroup:Button({Name = "Claim Group Reward", Callback = function() runAsync("Group reward", function() return rewardAutomation:groupReward() end) end})
    codesGroup:Button({Name = "Claim Limited Egg Reward", Callback = function()
        runAsync("Limited reward", function()
            local transportOk, serverOk, serverReason = broker:call("IndexLimitedReward")
            local accepted, rejection = classifyRemoteResponse(transportOk, serverOk, serverReason)
            return accepted, accepted and "Limited reward requested" or rejection
        end)
    end})

    local visualGroup = group(tabs.Visuals, "visualGroup", "Rare Egg ESP", "Left")
    addFeatureToggle(visualGroup, "Rare Egg ESP", "rare_egg_esp", function(enabled)
        if not enabled then visuals:destroyMarkers() end
    end)
    bindControl("visuals.notify_rare", visualGroup:Toggle({Name = "Rare Spawn Notifications", Flag = uiFlagPrefix .. "rare_notify", Default = runtime.Config.Visuals.NotifyRare, Callback = function(value)
        runtime.Config.Visuals.NotifyRare = value == true saveSetting("rare_egg_esp")
    end}), function() return runtime.Config.Visuals.NotifyRare == true end)
    bindControl("visuals.show_distance", visualGroup:Toggle({Name = "Show Distance", Flag = uiFlagPrefix .. "esp_distance", Default = runtime.Config.Visuals.ShowDistance, Callback = function(value)
        runtime.Config.Visuals.ShowDistance = value == true saveSetting("rare_egg_esp")
    end}), function() return runtime.Config.Visuals.ShowDistance == true end)
    bindSliderControl("visuals.minimum_rarity", visualGroup:Slider({Name = "ESP Min Rarity", Flag = uiFlagPrefix .. "esp_rarity", Min = 1, Max = 9, Default = runtime.Config.Visuals.MinimumRarity, Increment = 1, Callback = function(value)
        runtime.Config.Visuals.MinimumRarity = value saveSetting("rare_egg_esp")
    end}), function() return runtime.Config.Visuals.MinimumRarity end)
    bindSliderControl("visuals.max_markers", visualGroup:Slider({Name = "Maximum Markers", Flag = uiFlagPrefix .. "esp_limit", Min = 1, Max = 60, Default = runtime.Config.Visuals.MaxMarkers, Increment = 1, Callback = function(value)
        runtime.Config.Visuals.MaxMarkers = value saveSetting("rare_egg_esp")
    end}), function() return runtime.Config.Visuals.MaxMarkers end)
    visualGroup:Button({Name = "Refresh Markers", Callback = function() runAsync("Rare egg ESP", function() return visuals:refresh() end) end})

    local visualInfoGroup = group(tabs.Visuals, "visualInfoGroup", "Performance", "Right")
    visualInfoGroup:Label({Text = "Refresh rate: 2.5s", Wrap = true})
    local markerLabel = visualInfoGroup:Label({Text = "Markers: 0"})

    local travelGroup = group(tabs.Utilities, "travelGroup", "Registered Travel", "Left")
    travelGroup:Button({Name = "Go To Best Egg", Callback = function() runAsync("Best egg travel", function() return utilities:teleportToBestEgg() end) end})
    travelGroup:Button({Name = "Return To My Plot", Callback = function() runAsync("Return home", function() return utilities:teleportHome() end) end})
    travelGroup:Button({Name = "Request Lobby Teleport", Callback = function()
        local ok, value = broker:call("LobbyTeleport")
        runtime:notify("Lobby", ok and "Lobby teleport requested" or tostring(value))
    end})
    travelGroup:Label({Text = "Unlocks after protocol validation.", Wrap = true})

    local flyGroup = group(tabs.Utilities, "flyGroup", "Experimental Movement", "Left")
    local flyToggle
    flyToggle = bindControl("utilities.experimental_fly", flyGroup:Toggle({
        Name = "Experimental Fly",
        Flag = uiFlagPrefix .. "experimental_fly",
        Default = false,
        Callback = function(value)
            local enabled = value == true
            local ok, message = experimentalFly:setEnabled(enabled)
            runtime:notify("Experimental Fly", tostring(message), ok and 2.8 or 4)
            if enabled and not ok then
                task.defer(function()
                    if flyToggle then
                        flyToggle:Set(false, true, true)
                    end
                end)
            end
        end,
    }), function()
        return experimentalFly.Enabled == true
    end)
    flyGroup:Label({
        Text = "WASD move • Space up • Shift down",
        Wrap = true,
    })

    local godmodeGroup = group(tabs.Utilities, "godmodeGroup", "Boss Protection", "Right")
    local godmodeToggle
    godmodeToggle = bindControl("utilities.godmode", godmodeGroup:Toggle({
        Name = "Godmode",
        Flag = uiFlagPrefix .. "godmode",
        Default = false,
        Callback = function(value)
            local enabled = value == true
            local ok, message = godmode:setEnabled(enabled)
            runtime:notify("Godmode", tostring(message), ok and 2.8 or 4)
            if enabled and not ok then
                task.defer(function()
                    if godmodeToggle then
                        godmodeToggle:Set(false, true, true)
                    end
                end)
            end
        end,
    }), function()
        return godmode.Enabled == true
    end)
    godmodeGroup:Label({
        Text = "Keeps the carry through boss hits.",
        Wrap = true,
    })

    local sessionGroup = group(tabs.Utilities, "sessionGroup", "Session", "Right")
    bindControl("utilities.queue_resume", sessionGroup:Toggle({Name = "Resume On Teleport", Flag = uiFlagPrefix .. "queue_resume", Default = runtime.Config.Utilities.AutoQueueOnTeleport, Callback = function(value)
        runtime.Config.Utilities.AutoQueueOnTeleport = value == true saveSetting()
    end}), function() return runtime.Config.Utilities.AutoQueueOnTeleport == true end)
    sessionGroup:Button({Name = "Queue Resume Now", Callback = function() local ok, message = utilities:queueOnTeleport() runtime:notify("Teleport resume", message) end})
    sessionGroup:Button({Name = "Rejoin Server", Callback = function() utilities:rejoin(true) end})
    sessionGroup:Button({Name = "Hop Server", Callback = function() runAsync("Server hop", function() return utilities:serverHop(true) end) end})

    local endpointGroup = group(tabs.Diagnostics, "endpointGroup", "Endpoint Broker", "Left")
    local endpointLabel = endpointGroup:Label({Text = "Scanning exact remotes...", Wrap = true})
    endpointGroup:Button({Name = "Rescan Endpoints", Callback = function()
        local available, total = broker:rescan()
        setLabel(endpointLabel, string.format("Exact remotes: %d/%d available", available, total))
        runtime:notify("Broker", string.format("%d/%d endpoints", available, total))
    end})
    endpointGroup:Button({Name = "Clear Call Metrics", Callback = function() table.clear(runtime.CallMetrics) end})

    local transportGroup = group(tabs.Diagnostics, "transportGroup", "Character Transport", "Right")
    local transportLabel = transportGroup:Label({Text = "Checking registered-physics transport...", Wrap = true})
    transportGroup:Button({Name = "Refresh Transport Status", Callback = function()
        local ready, reason = movement:status()
        if not ready then
            setLabel(transportLabel, tostring(reason))
        elseif movement.TransportMode == "locomotion" then
            setLabel(transportLabel, "Locomotion active temporarily; registered physics is retrying automatically")
        else
            setLabel(transportLabel, "Registered-physics character transport ready")
        end
    end})

    local liveGroup = group(tabs.Diagnostics, "liveGroup", "Live Runtime", "Left")
    local executorCapabilities = runtime.ExecutorCapabilities
    liveGroup:Label({
        Text = string.format(
            "Executor: %s | getgc %s | debug %s | files %s | HTTP %s",
            tostring(runtime.ExecutorName),
            executorCapabilities.RuntimeGraph and "yes" or "no",
            executorCapabilities.DebugInfo and "yes" or "no",
            executorCapabilities.FileSystem and "yes" or "no",
            executorCapabilities.HttpRequest and "yes" or "no"
        ),
        Wrap = true,
    })
    local actionLabel = liveGroup:Label({Text = "Action: Idle"})
    local resultLabel = liveGroup:Label({Text = "Result: Ready", Wrap = true})
    local metricLabel = liveGroup:Label({Text = "Remote calls: 0", Wrap = true})
    liveGroup:Button({Name = "Refresh State", Callback = function()
        local summary = state:summary()
        runtime:notify("State", string.format("Eggs %d • Pets %d • Speed %s", summary.EggInventory, summary.Inventory, tostring(summary.SpeedPower)))
    end})

    local movementGroup = group(tabs.Settings, "movementGroup", "Character Transport", "Left")
    movementGroup:Label({Text = "Policy: AuthenticatedOnly", Wrap = true})

    local dpiGroup = group(tabs.Settings, "dpiGroup", "UI Scale", "Left")
    dpiGroup:Dropdown({
        Name = "DPI Scale",
        Flag = uiFlagPrefix .. "dpi_scale",
        Options = {"50%", "75%", "100%", "125%", "150%", "175%", "200%"},
        Default = "100%",
        Callback = function(value)
            local dpi = tonumber(tostring(value):gsub("%%", ""))
            if dpi and Library then
                if type(Library.SetDPIScale) == "function" then
                    pcall(Library.SetDPIScale, Library, dpi)
                elseif type(Library.SetScale) == "function" then
                    pcall(Library.SetScale, Library, dpi / 100)
                end
            end
        end,
    })
    dpiGroup:Label({Text = "Adjusts UI size. 100% is default.", Wrap = true})

    local configGroup = group(tabs.Settings, "configGroup", "Config & Lifecycle", "Right")
    configGroup:Button({Name = "Save Config", Callback = function()
        local ownOk, ownReason = runtime:saveConfigNow()
        runtime:notify("Config", ownOk and "Saved runtime settings" or tostring(ownReason))
    end})
    configGroup:Button({Name = "Load Saved Config", Callback = function()
        local loadedConfig, migrated = loadPersistentConfig()
        runtime.Config = loadedConfig
        local synchronized = syncUiFromRuntimeConfig()
        scheduler:reset()
        if not runtime.Config.Features.treadmill_train then
            progressionAutomation:stopTraining()
        end
        if not runtime.Config.Features.rare_egg_esp then
            visuals:destroyMarkers()
        end
        if migrated then
            runtime:queueConfigSave()
        end
        runtime:notify("Config", string.format("Loaded and applied %d controls", synchronized))
    end})
    configGroup:Button({Name = "Reset Backoff", Callback = function() scheduler:reset() runtime:notify("Scheduler", "All jobs ready") end})
    configGroup:Button({Name = "Unload VoidHub", Callback = function() runtime:destroy("User unload") end})
    configGroup:Label({Text = "VoidHub v" .. VERSION .. " • RightAlt toggles the window", Wrap = true})

    syncUiFromRuntimeConfig()
    local available, total = broker:rescan()
    setLabel(endpointLabel, string.format("Exact remotes: %d/%d available", available, total))
    local transportReady, transportReason = movement:status()
    if not transportReady then
        setLabel(transportLabel, tostring(transportReason))
    elseif movement.TransportMode == "locomotion" then
        setLabel(transportLabel, "Locomotion active temporarily; registered physics is retrying automatically")
    else
        setLabel(transportLabel, "Registered-physics character transport ready")
    end

    local function featureStatusLine(label, featureKey)
        if runtime.Config.Features[featureKey] ~= true then
            return label .. ": off"
        end
        local status = runtime.FeatureStatus[featureKey]
        if not status then
            return label .. ": ready"
        end
        return string.format("%s: %s — %s", label, tostring(status.Status), tostring(status.Detail or ""))
    end

    runtime:spawn("ui-status", 0.5, function()
        local totalCalls, failures, timeouts, busyCalls, unavailable = 0, 0, 0, 0, 0
        for _, metric in pairs(runtime.CallMetrics) do
            totalCalls += metric.Calls or 0
            failures += metric.Failures or 0
            timeouts += metric.Timeouts or 0
            busyCalls += metric.Busy or 0
            unavailable += metric.Unavailable or 0
        end
        local selectedCount = 0
        for _, key in ipairs(FEATURE_KEYS) do
            if runtime.Config.Features[key] == true then
                selectedCount += 1
            end
        end
        setLabel(actionLabel, "Action: " .. tostring(runtime.BusyAction))
        setLabel(resultLabel, "Result: " .. tostring(runtime.LastResult))
        setLabel(metricLabel, string.format("Remote calls: %d • failures: %d • timeouts: %d • busy: %d • unavailable: %d", totalCalls, failures, timeouts, busyCalls, unavailable))
        setLabel(markerLabel, string.format("Markers: %d", visuals.MarkerCount))
        setLabel(automationStateLabel, string.format(
            "Active feature toggles: %d • each runs independently",
            selectedCount
        ))
        local candidates = state:eggCandidates(nil, 0, false)
        if candidates and #candidates > 0 then
            local best = candidates[1]
            local name = best.AssetCategory or best.Category or "Unknown"
            local value = tonumber(best.Value) or 0
            setLabel(currentTargetLabel, string.format("Target: %s  |  %.0f/s", name, value))
        else
            setLabel(currentTargetLabel, "Target: no eggs found")
        end
        setLabel(eggStatusLabel, table.concat({
            string.format(
                "Eggs: %d visible • %d inventory",
                countTable(state:getLiveAreaEggModels()),
                #state:getEggInventory()
            ),
            featureStatusLine("Steal", "steal_best_egg"),
            featureStatusLine("Place", "place_eggs"),
            featureStatusLine("Hatch", "hatch_ready"),
        }, "\n"))
        setLabel(worldPredictionLabel, worldSpawnPredictor.LastText)
        local finderStatus = runtime.FeatureStatus.egg_finder
        setLabel(finderStatusLabel, string.format(
            "Finder: %s • target: %s • hops: %d%s",
            eggFinder.StateData.Active and "active" or "inactive",
            eggFinder.StateData.TargetCategory ~= "" and eggFinder.StateData.TargetCategory or "none",
            tonumber(eggFinder.StateData.HopCount) or 0,
            finderStatus and ("\n" .. tostring(finderStatus.Status) .. " — " .. tostring(finderStatus.Detail or "")) or ""
        ))
        setLabel(sessionLabel, string.format(
            "Stolen %d • placed %d • opened %d • finder hops %d\nEggs sold %d • pets sold %d • fused %d • rewards %d",
            runtime.Session.EggsStolen,
            runtime.Session.EggsPlaced,
            runtime.Session.EggsHatched,
            runtime.Session.FinderHops,
            runtime.Session.EggsSold,
            runtime.Session.PetsSold,
            runtime.Session.Fusions,
            runtime.Session.RewardsClaimed
        ))
    end)

    return Window
end

local uiOk, uiOrError = xpcall(buildUi, debug.traceback)
if not uiOk then
    runtime.LastError = tostring(uiOrError)
    warn("VoidHub UI failed: " .. tostring(uiOrError))
end

if runtime.Config.Utilities.AutoQueueOnTeleport then
    utilities:queueOnTeleport()
end

scheduler:start()
runtime:notify("VoidHub", "VoidHub Loaded")

return runtime
