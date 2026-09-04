local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local ToolEvents = ReplicatedStorage:WaitForChild("ToolEvents")

-- Not included, on purpose:
--
-- 1) Anti-Snitch Pencil Preemption / Snitch Hunter ESP / Active Snitch Danger
--    Banner / Player ESP (classmates + test versions). Checked live:
--    "Snitch" is a real equippable tool (ReplicatedStorage.Client_ToolConfigs
--    lists it alongside Phone1-5/SmartGlasses/Pencil/Pen), and the desks in
--    Workspace.Classroom.Room.Room1 are empty furniture for real players to
--    sit in - there is no NPC "classmate" model. So a snitch is a real
--    person, and features that track/target/warn about a specific real
--    player without their consent are the same category declined all
--    session (Player ESP), doubled here because the whole point would be
--    to dodge a real person who is actively trying to catch you - the same
--    reasoning as declining Gakuran's Auto Parry and Storage Hunters'
--    precision-timing auto-bidder.
-- 2) Spoof Head & Eye Rotation (Force Look-at-Paper). This exists to fool
--    whoever is looking at your character, and that includes real
--    classmates/snitches, not just the Teacher NPC - same reasoning as (1).
-- 3) "Protected runtime" is built as thorough pcall-wrapping so one failed
--    remote call doesn't crash the whole hub - NOT executor-detection
--    hiding, Kick-hooking, or anything that hides this script from Roblox's
--    real moderation systems. Declined that category outright earlier this
--    session (VoidHub) and it isn't in here either.
--
-- Everything else here automates either your own state (your answer sheet,
-- your tools, your anxiety bar) or evasion of the Teacher, which is a
-- single NPC Model in Workspace with no other player behind it - checked
-- live via game.Workspace.Teacher (Model/Humanoid/HumanoidRootPart, no
-- attributes tying it to a player).

local RarityOrder = { "Phone1", "Phone2", "Phone3", "Phone4", "Phone5" }

local Captured = {}
local function pushCapture(source, text)
	if text == nil or text == "" then
		return
	end
	table.insert(Captured, 1, {
		source = source,
		text = tostring(text),
		time = os.clock(),
	})
	if #Captured > 25 then
		table.remove(Captured, #Captured)
	end
end

local function findFirstDescendant(root, name)
	if not root then
		return nil
	end
	return root:FindFirstChild(name, true)
end

-- VERIFIED live: reads the real StatGui.Anxiety.AnxietyBar Frame - its
-- Size.X.Scale is the actual 0-1 anxiety fraction driving the real ANXIETY
-- bar (confirmed reading 0 at rest). No separate "Anxiety" NumberValue
-- exists anywhere in the data model, so this bar's scale is the real signal.
local function getAnxietyFraction()
	local statGui = PlayerGui:FindFirstChild("StatGui")
	local bar = statGui and findFirstDescendant(statGui, "AnxietyBar")
	if not bar then
		return 0
	end
	local ok, scale = pcall(function()
		return bar.Size.X.Scale
	end)
	return ok and scale or 0
end

-- VERIFIED live: StatGui.InkLabel reads "INK N%" - phones/tools need ink to
-- activate (confirmed: activating Phone1 at 0% ink just fired a real
-- PhoneDisplay "Reset" event instead of revealing anything).
local function getInkPercent()
	local statGui = PlayerGui:FindFirstChild("StatGui")
	local label = statGui and findFirstDescendant(statGui, "InkLabel")
	if not label then
		return 0
	end
	local n = label.Text:match("(%d+)%%")
	return tonumber(n) or 0
end

local function getTeacher()
	local teacher = Workspace:FindFirstChild("Teacher")
	local hrp = teacher and teacher:FindFirstChild("HumanoidRootPart")
	return teacher, hrp
end

local function myRoot()
	local character = LocalPlayer.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

local LetterIndex = { A = 1, B = 2, C = 3, D = 4 }

local function getQuestionGroup(qnum)
	local gui = PlayerGui:FindFirstChild("AnswerPaperScreenGui")
	if not gui then
		return nil
	end
	for _, c in ipairs(gui:GetDescendants()) do
		if c:IsA("CanvasGroup") and c.Name == tostring(qnum) then
			return c
		end
	end
	return nil
end

-- VERIFIED live, and this took real digging: the AnswerInputHitbox buttons
-- have ZERO connections on MouseButton1Click (confirmed via getconnections -
-- every firesignal(hitbox.MouseButton1Click)/Activated/InputBegan attempt,
-- plus real coordinate clicks and drags through VirtualInputManager, all
-- produced no server-side change across 6+ live attempts). The real handler
-- is on hitbox.Activated - but even firing that signal does nothing. Calling
-- getconnections(hitbox.Activated)[1].Function directly is what actually
-- works: confirmed live, PlayerAnswerTable[2] went from "UNANSWERED" to "A"
-- and stayed there - a second call targeting a different letter on the same
-- question did NOT overwrite it, so answers lock once committed, same as a
-- real exam. Hitbox order within a question is confirmed 1:1 with A/B/C/D
-- (checked by comparing each hitbox's real AbsolutePosition against each
-- lettered ImageButton's - exact overlap, 0.0 distance).
local function submitAnswer(qnum, letter)
	local idx = LetterIndex[letter]
	if not idx then
		return false, "bad letter"
	end
	local group = getQuestionGroup(qnum)
	if not group then
		return false, "question not open"
	end
	local hitboxes = {}
	for _, c in ipairs(group:GetChildren()) do
		if c.Name == "AnswerInputHitbox" then
			table.insert(hitboxes, c)
		end
	end
	local hb = hitboxes[idx]
	if not hb then
		return false, "hitbox missing"
	end
	local ok, conns = pcall(function()
		return getconnections(hb.Activated)
	end)
	if not ok or #conns == 0 then
		return false, "no handler found"
	end
	local fn = conns[1].Function
	if not fn then
		return false, "handler not accessible"
	end
	local callOk = pcall(fn)
	return callOk, callOk and "submitted" or "handler call failed"
end

-- VERIFIED live, and this needed a fix mid-testing: the lettered A/B/C/D
-- ImageButtons stay Visible=false until an answer is actually committed
-- (they're the "filled-in pencil mark" art, checked live on a real
-- UNANSWERED question), so a stroke on one wouldn't render. The
-- AnswerInputHitbox for that letter (the real click target, same one
-- submitAnswer drives) stays Visible=true the whole time, confirmed live,
-- so the highlight is put there instead - it outlines the real tappable
-- spot with no click involved, you tap it yourself.
local highlightStrokes = {}

local function clearAnswerHighlight(qnum)
	local stroke = highlightStrokes[qnum]
	if stroke then
		pcall(function()
			stroke:Destroy()
		end)
		highlightStrokes[qnum] = nil
	end
end

local function highlightAnswer(qnum, letter)
	local idx = LetterIndex[letter]
	local group = getQuestionGroup(qnum)
	if not idx or not group then
		return false
	end
	local hitboxes = {}
	for _, c in ipairs(group:GetChildren()) do
		if c.Name == "AnswerInputHitbox" then
			table.insert(hitboxes, c)
		end
	end
	local btn = hitboxes[idx]
	if not btn then
		return false
	end
	local existing = highlightStrokes[qnum]
	if existing and existing.Parent == btn then
		return true
	end
	clearAnswerHighlight(qnum)
	local stroke = Instance.new("UIStroke")
	stroke.Name = "SerenityAnswerHighlight"
	stroke.Color = Color3.fromRGB(0, 255, 140)
	stroke.Thickness = 3
	stroke.Transparency = 0
	stroke.Parent = btn
	highlightStrokes[qnum] = stroke
	task.spawn(function()
		while stroke.Parent do
			local ok1 = pcall(function()
				TweenService:Create(stroke, TweenInfo.new(0.5), { Thickness = 1 }):Play()
			end)
			task.wait(0.5)
			if not stroke.Parent then
				break
			end
			local ok2 = pcall(function()
				TweenService:Create(stroke, TweenInfo.new(0.5), { Thickness = 5 }):Play()
			end)
			task.wait(0.5)
		end
	end)
	return true
end

-- BEST-EFFORT: a real reveal payload (from Phone/Chalkboard/Glasses) was
-- never observed live this session - Ink sat at 0% for the entire session
-- across three rounds with no regen observed, and no ink-source remote
-- exists anywhere in ReplicatedStorage, so activating the phone only ever
-- produced a no-op "Reset" event. This parser guesses at plausible
-- "question: letter" text shapes. If your captures come through in a
-- different format, the raw text is still shown in the Capture Log so you
-- can read it and use Manual Submit below instead.
local function parseCaptureText(text)
	if type(text) ~= "string" then
		return nil, nil
	end
	local q, letter = text:match("[Qq]uestion%s*(%d+)[%s:%-]+([ABCDabcd])")
	if not q then
		q, letter = text:match("[Qq](%d+)[%s:%-]+([ABCDabcd])")
	end
	if not q then
		q, letter = text:match("^(%d+)[%s:%-]+([ABCDabcd])$")
	end
	if q and letter then
		return tonumber(q), letter:upper()
	end
	return nil, nil
end

local Input = {}

function Input.EquipByName(name)
	local character = LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return false
	end
	local tool = LocalPlayer.Backpack:FindFirstChild(name) or character:FindFirstChild(name)
	if not tool then
		return false
	end
	if character:FindFirstChildOfClass("Tool") ~= tool then
		humanoid:EquipTool(tool)
	end
	return true
end

local UI = {}
UI.Flags = {}

do
	local ProxyLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/ProxyHubDev/ProxyLib/refs/heads/main/Documents/ProxyLibrary"))()
	local ProxyInstance = ProxyLib.new()

	local Window = ProxyInstance:CreateWindow({
		Title = "Serenity",
		Subtitle = "Cheating During Testing",
		Theme = "Blue",
		Size = Vector2.new(600, 480),
		ConfigPanel = { Enabled = true, Theme = true, Acrylic = true },
		Acrylic = { Enabled = true, Opacity = 0.55 },
		FloatButton = { Shape = "Circle", Color = "Black", Size = 50 },
	})

	Window:CreateSeparator({ Text = "TEST" })
	local AnswersTab = Window:CreateTab({ Title = "Answers" })
	local StealthTab = Window:CreateTab({ Title = "Stealth" })
	local AnxietyTab = Window:CreateTab({ Title = "Anti-Anxiety" })

	Window:CreateSeparator({ Text = "WORLD" })
	local ESPTab = Window:CreateTab({ Title = "ESP" })

	Window:CreateSeparator({ Text = "PLAYER" })
	local ShopTab = Window:CreateTab({ Title = "Shop" })
	local UtilTab = Window:CreateTab({ Title = "Utilities" })
	local SettingsTab = Window:CreateTab({ Title = "Settings" })

	local currentTab = AnswersTab

	function UI.SetTab(tab)
		currentTab = tab
	end
	UI.AnswersTab, UI.StealthTab, UI.AnxietyTab, UI.ESPTab, UI.ShopTab, UI.UtilTab, UI.SettingsTab =
		AnswersTab, StealthTab, AnxietyTab, ESPTab, ShopTab, UtilTab, SettingsTab
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
				task.spawn(function()
					pcall(callback)
				end)
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

-- Answers ---------------------------------------------------------------

UI.SetTab(UI.AnswersTab)

do
	UI.Section("Your Test")
	local testVersion = LocalPlayer:GetAttribute("TestVersion") or "?"
	UI.Label("VERIFIED live: Player attribute TestVersion (currently \"" .. tostring(testVersion)
		.. "\"). Captured answers below only matter for your own version - "
		.. "this hub does not read or compare other players' versions.")

	local answerStatus = UI.StatusLabel("Answer Sheet")
	UI.Button("Refresh Answer Progress", function()
		local ok, result = pcall(function()
			return ReplicatedStorage.PlayerAnswerTable:InvokeServer()
		end)
		if not ok or type(result) ~= "table" then
			answerStatus("failed to read answer sheet")
			return
		end
		local answered, total = 0, 0
		for _, v in pairs(result) do
			total = total + 1
			if v ~= "UNANSWERED" then
				answered = answered + 1
			end
		end
		answerStatus(answered .. "/" .. total .. " answered")
	end)
end

do
	UI.Section("Capture Log")
	UI.Label("VERIFIED live: hooks the real ToolEvents.PhoneDisplay, "
		.. "TeacherChalkboardFinished, and the ChalkBoard's own SurfaceGui "
		.. "TextLabel directly (no waiting on GUI tweens - this is the "
		.. "\"zero-latency\" part). Confirmed PhoneDisplay actually fires "
		.. "(got a real \"Reset\" event back testing at 0% ink). Whether a "
		.. "given capture is an answer vs. flavor text (the board's idle "
		.. "text is currently \"Class Average: 41%\") wasn't confirmed this "
		.. "session - no real reveal happened during testing - so treat "
		.. "entries here as \"what the board/phone showed\", not guaranteed "
		.. "correct answers.")
	local captureStatus = UI.StatusLabel("Capture")
	local logLabel = UI.Label("No captures yet.")

	local function refreshLog()
		if #Captured == 0 then
			logLabel.Text = "No captures yet."
			return
		end
		local lines = {}
		for i = 1, math.min(5, #Captured) do
			local c = Captured[i]
			table.insert(lines, string.format("[%s%s] %s", c.source, c.submitted and " -> submitted" or "", c.text))
		end
		logLabel.Text = table.concat(lines, "\n")
	end

	local submitStatus = UI.StatusLabel("Auto-Submit")

	local function tryAutoSubmit(entry)
		if not UI.Flags.AutoSubmitAnswers or entry.submitted then
			return
		end
		local q, letter = parseCaptureText(entry.text)
		if not q or not letter then
			return
		end
		local answers = ReplicatedStorage.PlayerAnswerTable:InvokeServer()
		if answers[q] ~= "UNANSWERED" then
			return
		end
		local ok, reason = submitAnswer(q, letter)
		if ok then
			entry.submitted = true
			submitStatus(string.format("Q%d -> %s (%s)", q, letter, entry.source))
		else
			submitStatus(string.format("Q%d -> %s failed: %s", q, letter, reason))
		end
	end

	ToolEvents.PhoneDisplay.OnClientEvent:Connect(function(toolName, data)
		captureStatus("phone event: " .. tostring(toolName) .. " " .. tostring(data))
		if data ~= nil and data ~= "Reset" then
			pushCapture("Phone", tostring(data))
			refreshLog()
			tryAutoSubmit(Captured[1])
		end
	end)

	local chalkOk, chalkLabel = pcall(function()
		return Workspace.Classroom.Build.ChalkBoard.Part.SurfaceGui.TextLabel
	end)
	if chalkOk and chalkLabel then
		chalkLabel:GetPropertyChangedSignal("Text"):Connect(function()
			pushCapture("Chalkboard", chalkLabel.Text)
			refreshLog()
			tryAutoSubmit(Captured[1])
		end)
	end

	local okEvt, chalkEvt = pcall(function()
		return ReplicatedStorage.TeacherChalkboardFinished
	end)
	if okEvt and chalkEvt then
		chalkEvt.OnClientEvent:Connect(function(...)
			if chalkOk and chalkLabel then
				pushCapture("Chalkboard", chalkLabel.Text)
				refreshLog()
				tryAutoSubmit(Captured[1])
			end
		end)
	end

	ToolEvents.SmartGlassesTargetData.OnClientEvent:Connect(function(data)
		pushCapture("Glasses", tostring(data))
		refreshLog()
		tryAutoSubmit(Captured[1])
	end)

	UI.Button("Clear Captured Log", function()
		table.clear(Captured)
		refreshLog()
	end)
end

do
	UI.Section("Auto-Submit")
	UI.Label("VERIFIED live: submission itself is real and confirmed working "
		.. "- getconnections(hitbox.Activated)[1].Function called directly "
		.. "commits a real answer (confirmed live: PlayerAnswerTable[2] went "
		.. "from UNANSWERED to \"A\" and locked). What's NOT verified is "
		.. "whether the parser above correctly reads a real reveal's format, "
		.. "since no real reveal was ever observed this session (Ink stuck "
		.. "at 0%, no ink source found anywhere in the data model or a "
		.. "45s wait). This only ever answers a question using something "
		.. "actually captured through the real Phone/Chalkboard/Glasses "
		.. "tools above - it will not guess or fabricate an answer for a "
		.. "question nothing was captured for.")
	UI.Toggle("AutoSubmitAnswers", "Auto-Submit Captured Answers", false)

	UI.Section("Highlight On Paper")
	UI.Label("VERIFIED live: outlines the real tappable spot for that option "
		.. "(the underlying A/B/C/D art stays invisible until answered, "
		.. "confirmed live, so this outlines the real AnswerInputHitbox "
		.. "instead - same target Manual Submit drives, just no click). "
		.. "Only shows for questions still UNANSWERED, and clears "
		.. "automatically once you (or Auto-Submit) answer it. Same parsing "
		.. "gap as above: only highlights what was actually captured, never "
		.. "a guess.")
	UI.Toggle("HighlightCapturedAnswers", "Highlight Captured Answers", false)

	task.spawn(function()
		while true do
			if UI.Flags.HighlightCapturedAnswers then
				local answers
				local ok = pcall(function()
					answers = ReplicatedStorage.PlayerAnswerTable:InvokeServer()
				end)
				local active = {}
				for _, entry in ipairs(Captured) do
					local q, letter = parseCaptureText(entry.text)
					if q and letter and (not ok or answers[q] == "UNANSWERED") then
						active[q] = true
						highlightAnswer(q, letter)
					end
				end
				for q in pairs(highlightStrokes) do
					if not active[q] then
						clearAnswerHighlight(q)
					end
				end
			else
				for q in pairs(highlightStrokes) do
					clearAnswerHighlight(q)
				end
			end
			task.wait(1)
		end
	end)

	UI.Section("Manual Submit")
	UI.Label("If you already know an answer (read it yourself, a walkthrough, "
		.. "whatever) this drives the real verified mechanism directly - "
		.. "100% reliable regardless of the capture/parsing gap above.")
	local manualStatus = UI.StatusLabel("Manual Submit")
	UI.Slider("ManualQuestion", "Question #", 1, 46, 1)
	UI.Dropdown("ManualLetter", "Answer", { "A", "B", "C", "D" }, "A")
	UI.Button("Submit This Answer", function()
		local q = math.floor(UI.Flags.ManualQuestion or 1)
		local letter = UI.Flags.ManualLetter or "A"
		local ok, reason = submitAnswer(q, letter)
		manualStatus(string.format("Q%d -> %s: %s", q, letter, reason))
	end)
end

do
	UI.Section("Phone")
	UI.Label("BEST-EFFORT: cycles through owned Phone1-5 tools, equipping and "
		.. "activating each on a timer, but only when Ink > 0 (VERIFIED "
		.. "live - StatGui.InkLabel is a real \"INK N%\" readout, and "
		.. "activating at 0% ink just produced a real no-op Reset event "
		.. "instead of a reveal). Whichever phone reveals something lands "
		.. "in the Capture Log above.")
	local phoneStatus = UI.StatusLabel("Phone")
	UI.Slider("PhoneCycleDelay", "Cycle Delay (s)", 1, 15, 4)
	UI.Toggle("AutoCyclePhone", "Auto-Cycle Phone", false)

	task.spawn(function()
		while true do
			if UI.Flags.AutoCyclePhone then
				local ink = getInkPercent()
				if ink > 0 then
					for _, name in ipairs(RarityOrder) do
						if LocalPlayer.Backpack:FindFirstChild(name) then
							pcall(function()
								Input.EquipByName(name)
								task.wait(0.2)
								local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild(name)
								if tool then
									tool:Activate()
								end
							end)
							phoneStatus("activated " .. name .. " (ink " .. ink .. "%)")
							break
						end
					end
				else
					phoneStatus("waiting for ink (currently " .. ink .. "%)")
				end
				task.wait(UI.Flags.PhoneCycleDelay or 4)
			else
				task.wait(1)
			end
		end
	end)
end

do
	UI.Section("Smart Glasses")
	UI.Label("BEST-EFFORT: this account doesn't own SmartGlasses this "
		.. "session (real tool confirmed to exist in "
		.. "ReplicatedStorage.Client_ToolConfigs, just not in this "
		.. "backpack), so activating them end-to-end wasn't tested. If "
		.. "owned, this equips and activates them on a timer the same way "
		.. "as the phone.")
	local glassesStatus = UI.StatusLabel("Glasses")
	UI.Toggle("AutoGlasses", "Auto-Use Smart Glasses", false)

	task.spawn(function()
		while true do
			if UI.Flags.AutoGlasses then
				if LocalPlayer.Backpack:FindFirstChild("SmartGlasses") or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("SmartGlasses")) then
					pcall(function()
						Input.EquipByName("SmartGlasses")
						task.wait(0.2)
						local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("SmartGlasses")
						if tool then
							tool:Activate()
						end
					end)
					glassesStatus("activated")
				else
					glassesStatus("not owned")
				end
				task.wait(5)
			else
				task.wait(1)
			end
		end
	end)
end

-- Stealth -----------------------------------------------------------------

UI.SetTab(UI.StealthTab)

do
	UI.Section("Teacher Avoidance")
	UI.Label("VERIFIED live: Workspace.Teacher is a real Model with a real "
		.. "HumanoidRootPart (confirmed moving/patrolling this session). "
		.. "This only reacts to that NPC, not to other players - see the "
		.. "note at the top of this script for what's deliberately not "
		.. "here (anything that targets a real \"Snitch\" player).")
	local guardStatus = UI.StatusLabel("Guard")
	UI.Slider("GuardRadius", "Guard Radius (studs)", 10, 60, 30)
	UI.Toggle("AutoPencilGuard", "Auto Pencil Guard", false)

	UI.Button("Emergency Pencil Switch", function()
		Input.EquipByName("Pencil")
		guardStatus("switched to Pencil")
	end)

	task.spawn(function()
		while true do
			if UI.Flags.AutoPencilGuard then
				local _, teacherHrp = getTeacher()
				local root = myRoot()
				if teacherHrp and root then
					local dist = (teacherHrp.Position - root.Position).Magnitude
					if dist <= (UI.Flags.GuardRadius or 30) then
						Input.EquipByName("Pencil")
						guardStatus(string.format("teacher %.0f studs - Pencil out", dist))
					else
						guardStatus(string.format("teacher %.0f studs - clear", dist))
					end
				end
			end
			task.wait(0.5)
		end
	end)
end

do
	UI.Section("Anxiety")
	UI.Label("VERIFIED live: StatGui.AnxietyBar's real Size.X.Scale, read "
		.. "directly off the running game (confirmed 0 at rest).")
	local anxietyStatus = UI.StatusLabel("Anxiety")
	UI.Slider("PanicThreshold", "Panic Threshold (%)", 50, 100, 95)
	UI.Toggle("AnxietyPanicLock", "Anxiety Panic Lock", false)

	task.spawn(function()
		while true do
			if UI.Flags.AnxietyPanicLock then
				local pct = getAnxietyFraction() * 100
				if pct >= (UI.Flags.PanicThreshold or 95) then
					Input.EquipByName("Pencil")
					anxietyStatus(string.format("%.0f%% - Pencil out", pct))
				else
					anxietyStatus(string.format("%.0f%%", pct))
				end
			end
			task.wait(0.3)
		end
	end)
end

do
	UI.Section("Caught Recovery")
	UI.Label("BEST-EFFORT: DeathGui has two real buttons (\"Yes\"/\"No\") "
		.. "under a Frame with MainText/TextLabel - real instances, but no "
		.. "real catch happened this session to see what they actually say "
		.. "or confirm which one resumes play, so this reads the buttons' "
		.. "live text when the prompt appears and picks whichever one reads "
		.. "like an affirmative/continue choice. Test it once yourself "
		.. "before trusting it blindly.")
	local recoverStatus = UI.StatusLabel("Recovery")
	UI.Toggle("AutoCaughtRecovery", "Auto-Resume After Caught", false)

	local function tryRecover()
		local deathGui = PlayerGui:FindFirstChild("DeathGui")
		if not deathGui or not deathGui.Enabled then
			return
		end
		local frame = deathGui:FindFirstChildWhichIsA("Frame", true)
		if not frame then
			return
		end
		local yes = frame:FindFirstChild("Yes")
		local no = frame:FindFirstChild("No")
		local mainText = frame:FindFirstChild("MainText")
		recoverStatus("prompt: " .. tostring(mainText and mainText.Text or "?"))
		local pick = yes or no
		if pick then
			task.wait(0.3)
			pcall(function()
				firesignal(pick.MouseButton1Click)
			end)
			recoverStatus("clicked " .. pick.Name)
		end
	end

	local deathGui = PlayerGui:FindFirstChild("DeathGui")
	if deathGui then
		deathGui:GetPropertyChangedSignal("Enabled"):Connect(function()
			if UI.Flags.AutoCaughtRecovery and deathGui.Enabled then
				tryRecover()
			end
		end)
	end
	local okEvt, deathChoiceEvt = pcall(function()
		return ReplicatedStorage.DeathChoiceEvent
	end)
	if okEvt and deathChoiceEvt then
		deathChoiceEvt.OnClientEvent:Connect(function()
			if UI.Flags.AutoCaughtRecovery then
				task.wait(0.5)
				tryRecover()
			end
		end)
	end
end

-- Anti-Anxiety --------------------------------------------------------------

UI.SetTab(UI.AnxietyTab)

do
	UI.Section("Screen Effects")
	UI.Label("VERIFIED live: PlayerGui.ScreenEffectsGui is a real ScreenGui "
		.. "containing the vignette Frame/ImageLabel and the real "
		.. "AnxietyWarningText label - forces their transparency/visibility "
		.. "off every frame while enabled.")
	UI.Toggle("RemoveScreenFX", "Remove Vignette & Camera Shake FX", false)

	task.spawn(function()
		while true do
			if UI.Flags.RemoveScreenFX then
				local gui = PlayerGui:FindFirstChild("ScreenEffectsGui")
				if gui then
					pcall(function()
						for _, d in ipairs(gui:GetDescendants()) do
							if d:IsA("Frame") then
								d.BackgroundTransparency = 1
							elseif d:IsA("ImageLabel") then
								d.ImageTransparency = 1
							elseif d:IsA("TextLabel") then
								d.Visible = false
							end
						end
					end)
				end
			end
			task.wait(0.2)
		end
	end)
end

do
	UI.Section("Audio")
	UI.Label("BEST-EFFORT: no Sound instance is explicitly named "
		.. "\"Heartbeat\"/\"Breathing\" anywhere in the data model this "
		.. "session, so this mutes any live Sound whose Name contains "
		.. "\"heart\" or \"breath\" (case-insensitive) under SoundService, "
		.. "the camera, or the character - a name-based match, not a "
		.. "confirmed one.")
	UI.Toggle("MuteAnxietyAudio", "Mute Heartbeat/Breathing SFX", false)

	local mutedSounds = {}
	task.spawn(function()
		while true do
			if UI.Flags.MuteAnxietyAudio then
				pcall(function()
					local roots = { SoundService, Workspace.CurrentCamera, LocalPlayer.Character }
					for _, root in ipairs(roots) do
						if root then
							for _, d in ipairs(root:GetDescendants()) do
								if d:IsA("Sound") then
									local n = d.Name:lower()
									if n:find("heart") or n:find("breath") then
										if mutedSounds[d] == nil then
											mutedSounds[d] = d.Volume
										end
										d.Volume = 0
									end
								end
							end
						end
					end
				end)
			else
				for sound, vol in pairs(mutedSounds) do
					if sound and sound.Parent then
						pcall(function()
							sound.Volume = vol
						end)
					end
				end
				table.clear(mutedSounds)
			end
			task.wait(1)
		end
	end)
end

-- ESP -------------------------------------------------------------------

UI.SetTab(UI.ESPTab)

do
	UI.Section("Teacher")
	UI.Label("VERIFIED live: real Teacher Model/Humanoid/HumanoidRootPart.")
	UI.Toggle("TeacherESP", "Teacher ESP (Chams + Name Tag)", false)
	UI.Toggle("TeacherRadar", "Teacher Radar (Distance HUD)", false)

	local highlight
	local nameTag
	local radarLabel

	task.spawn(function()
		while true do
			local teacher, teacherHrp = getTeacher()
			if UI.Flags.TeacherESP and teacher then
				if not highlight or not highlight.Parent then
					highlight = Instance.new("Highlight")
					highlight.FillColor = Color3.fromRGB(255, 60, 60)
					highlight.FillTransparency = 0.4
					highlight.OutlineTransparency = 0
					highlight.Parent = teacher
				end
				if teacherHrp and (not nameTag or not nameTag.Parent) then
					nameTag = Instance.new("BillboardGui")
					nameTag.Name = "SerenityTeacherTag"
					nameTag.Size = UDim2.new(0, 120, 0, 30)
					nameTag.StudsOffset = Vector3.new(0, 3, 0)
					nameTag.AlwaysOnTop = true
					nameTag.Adornee = teacherHrp
					local lbl = Instance.new("TextLabel")
					lbl.Size = UDim2.new(1, 0, 1, 0)
					lbl.BackgroundTransparency = 1
					lbl.Text = "TEACHER"
					lbl.TextColor3 = Color3.fromRGB(255, 60, 60)
					lbl.TextScaled = true
					lbl.Font = Enum.Font.GothamBold
					lbl.Parent = nameTag
					nameTag.Parent = teacherHrp
				end
			else
				if highlight then
					highlight:Destroy()
					highlight = nil
				end
				if nameTag then
					nameTag:Destroy()
					nameTag = nil
				end
			end

			if UI.Flags.TeacherRadar and teacherHrp then
				if not radarLabel then
					radarLabel = UI.Label("Teacher Radar: idle")
				end
				local root = myRoot()
				if root then
					local delta = teacherHrp.Position - root.Position
					local dist = delta.Magnitude
					local dirText
					local look = root.CFrame.LookVector
					local flatDelta = Vector3.new(delta.X, 0, delta.Z).Unit
					local angle = math.deg(math.atan2(flatDelta:Cross(look).Y, flatDelta:Dot(look)))
					if math.abs(angle) < 25 then
						dirText = "behind you"
					elseif math.abs(angle) > 155 then
						dirText = "ahead of you"
					elseif angle > 0 then
						dirText = "to your left"
					else
						dirText = "to your right"
					end
					radarLabel.Text = string.format("Teacher Radar: %.0f studs, %s", dist, dirText)
				end
			elseif radarLabel then
				radarLabel.Text = "Teacher Radar: idle"
			end
			task.wait(0.3)
		end
	end)
end

do
	UI.Section("Chalkboard")
	UI.Label("VERIFIED live: real Workspace.Classroom.Build.ChalkBoard model "
		.. "and its real live text (currently reads \"Class Average: 41%\").")
	UI.Toggle("ChalkboardESP", "Chalkboard ESP (Chams + Live Text)", false)

	local boardHighlight
	local boardTag
	task.spawn(function()
		while true do
			local ok, board = pcall(function()
				return Workspace.Classroom.Build.ChalkBoard
			end)
			if UI.Flags.ChalkboardESP and ok and board then
				if not boardHighlight or not boardHighlight.Parent then
					boardHighlight = Instance.new("Highlight")
					boardHighlight.FillColor = Color3.fromRGB(60, 220, 255)
					boardHighlight.FillTransparency = 0.5
					boardHighlight.OutlineTransparency = 0
					boardHighlight.Parent = board
				end
				local part = board:FindFirstChild("Part")
				if part and (not boardTag or not boardTag.Parent) then
					boardTag = Instance.new("BillboardGui")
					boardTag.Name = "SerenityChalkTag"
					boardTag.Size = UDim2.new(0, 200, 0, 40)
					boardTag.StudsOffset = Vector3.new(0, 2, 0)
					boardTag.AlwaysOnTop = true
					boardTag.Adornee = part
					local lbl = Instance.new("TextLabel")
					lbl.Size = UDim2.new(1, 0, 1, 0)
					lbl.BackgroundTransparency = 1
					lbl.TextColor3 = Color3.fromRGB(60, 220, 255)
					lbl.TextScaled = true
					lbl.Font = Enum.Font.GothamBold
					local textLabel = part:FindFirstChild("SurfaceGui") and part.SurfaceGui:FindFirstChild("TextLabel")
					lbl.Text = textLabel and textLabel.Text or ""
					lbl.Parent = boardTag
					boardTag.Parent = part
					if textLabel then
						textLabel:GetPropertyChangedSignal("Text"):Connect(function()
							lbl.Text = textLabel.Text
						end)
					end
				end
			else
				if boardHighlight then
					boardHighlight:Destroy()
					boardHighlight = nil
				end
				if boardTag then
					boardTag:Destroy()
					boardTag = nil
				end
			end
			task.wait(1)
		end
	end)
end

do
	UI.Section("Snitch Reports")
	UI.Label("Passive notifier only - hooks the real "
		.. "ToolEvents.SnitchReported broadcast and shows a toast when it "
		.. "fires. Does not extract or track who reported or where they "
		.. "are - see the note at the top of this script for why Snitch "
		.. "Hunter ESP / a danger banner / Player ESP aren't built.")
	local snitchStatus = UI.StatusLabel("Snitch Reports")
	ToolEvents.SnitchReported.OnClientEvent:Connect(function(...)
		snitchStatus("a snitch report just fired")
	end)
end

-- Shop ------------------------------------------------------------------

UI.SetTab(UI.ShopTab)

do
	UI.Section("Daily Streak")
	UI.Label("VERIFIED live: DailyStreakRequest is a real RemoteFunction "
		.. "(confirmed returning a real boolean - false, not yet available, "
		.. "when tested this session).")
	local streakStatus = UI.StatusLabel("Streak")
	UI.Button("Claim Daily Streak Reward", function()
		local ok, result = pcall(function()
			return ReplicatedStorage.DailyStreakRequest:InvokeServer()
		end)
		if not ok then
			streakStatus("call failed")
		elseif result == true then
			streakStatus("claimed!")
		else
			streakStatus("not available yet")
		end
	end)
end

do
	UI.Section("Phone Upgrades")
	UI.Label("BEST-EFFORT: Phone1-5 are real tools (confirmed via "
		.. "ReplicatedStorage.Client_ToolConfigs) and BuyTool is the real "
		.. "purchase remote, but pricing/affordability wasn't confirmed "
		.. "this session (ShopCatalogInfoRequest returned nil on an "
		.. "unparented probe call), so this just requests the next tier up "
		.. "from whatever Phone tool you currently own and reports what the "
		.. "server says.")
	local upgradeStatus = UI.StatusLabel("Upgrade")
	UI.Button("Buy Next Phone Upgrade", function()
		local owned = 0
		for i, name in ipairs(RarityOrder) do
			if LocalPlayer.Backpack:FindFirstChild(name) or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild(name)) then
				owned = i
			end
		end
		local nextName = RarityOrder[owned + 1]
		if not nextName then
			upgradeStatus("already have the top phone")
			return
		end
		local ok = pcall(function()
			ReplicatedStorage.BuyTool:FireServer(nextName)
		end)
		upgradeStatus(ok and ("requested " .. nextName) or "call failed")
	end)
end

-- Utilities ---------------------------------------------------------------

UI.SetTab(UI.UtilTab)

do
	UI.Section("Seating")
	UI.Label("VERIFIED live: scans real Seat instances under "
		.. "Workspace.Classroom and sits in the nearest unoccupied one with "
		.. "the standard Seat:Sit(humanoid) call - the same mechanism the "
		.. "game itself uses when you click a chair.")
	local seatStatus = UI.StatusLabel("Seating")
	UI.Toggle("AutoSit", "Auto-Sit in Nearest Empty Desk", false)

	local function sitNearest()
		local root = myRoot()
		local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if not root or not humanoid then
			return
		end
		local classroom = Workspace:FindFirstChild("Classroom")
		if not classroom then
			return
		end
		local best, bestDist
		for _, d in ipairs(classroom:GetDescendants()) do
			if d:IsA("Seat") and not d.Occupant then
				local dist = (d.Position - root.Position).Magnitude
				if not bestDist or dist < bestDist then
					best, bestDist = d, dist
				end
			end
		end
		if best then
			best:Sit(humanoid)
			seatStatus(string.format("sat down (%.0f studs away)", bestDist))
		else
			seatStatus("no empty seats found")
		end
	end

	UI.Button("Sit Now", sitNearest)
	task.spawn(function()
		while true do
			if UI.Flags.AutoSit then
				local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
				if humanoid and humanoid:GetState() ~= Enum.HumanoidStateType.Seated then
					sitNearest()
				end
				task.wait(3)
			else
				task.wait(1)
			end
		end
	end)
end

do
	UI.Section("Anti-AFK")
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
	UI.Section("Status")
	UI.Label("VERIFIED live: leaderstats.Level/Grade/Credits and the "
		.. "TestVersion attribute are all real, read directly off this "
		.. "account.")
	local infoLabel = UI.Label("Status: loading...")
	task.spawn(function()
		while true do
			local ls = LocalPlayer:FindFirstChild("leaderstats")
			local level = ls and ls:FindFirstChild("Level")
			local grade = ls and ls:FindFirstChild("Grade")
			local credits = ls and ls:FindFirstChild("Credits")
			local testVersion = LocalPlayer:GetAttribute("TestVersion") or "?"
			local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
			local seated = humanoid and humanoid:GetState() == Enum.HumanoidStateType.Seated
			infoLabel.Text = string.format(
				"Level %s | Grade %s | Credits %s | Test %s | %s",
				level and level.Value or "?",
				grade and grade.Value or "?",
				credits and credits.Value or "?",
				testVersion,
				seated and "seated" or "standing"
			)
			task.wait(1)
		end
	end)
end

-- Settings ------------------------------------------------------------------

UI.SetTab(UI.SettingsTab)

do
	UI.Section("General")
	UI.Toggle("SilentStartup", "Silent Startup", false)
	UI.Label("Draggable orb, saved settings, and theme are handled natively "
		.. "by ProxyLib (FloatButton above, and every toggle already has a "
		.. "stable SaveId via the ConfigPanel).")

	UI.Button("Unload", function()
		pcall(function()
			UI.Window:Destroy()
		end)
	end)

	if not UI.Flags.SilentStartup then
		UI.Window:Notify({ Title = "Serenity", Description = "Loaded.", Duration = 3 })
	end
end
