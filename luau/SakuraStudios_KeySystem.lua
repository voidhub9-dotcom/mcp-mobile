-- Sakura Studios key system UI
-- Reskinned/rebranded from an uploaded GUI-only export (visual tree only -
-- no button logic or intro animation was present in the source, which is
-- normal for a GUI-copy tool since those only capture Instances/properties,
-- not the LocalScripts that drive them). This file adds back a real intro
-- sequence and real button behavior, and repaints the whole thing pink.
--
-- Two things you'll need to fill in yourself, marked TODO below:
--   1. Real key validation (VALID_KEY is a placeholder local string check -
--      swap it for whatever your actual key backend is).
--   2. Real destination links for Get Key / How To Get Key / Support -
--      left as safe no-ops since I don't have real URLs for your project
--      and won't invent ones.

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

-- Palette -------------------------------------------------------------------

local ICON = "rbxassetid://77119006317483"
local BANNER = "rbxassetid://106736100104036"
local PINK_BRIGHT = Color3.fromRGB(255, 92, 178)
local PINK_MID = Color3.fromRGB(219, 39, 119)
local PINK_DEEP = Color3.fromRGB(140, 20, 80)
local PINK_MUTED = Color3.fromRGB(70, 35, 55)
local PINK_STROKE = Color3.fromRGB(255, 20, 147)
local PINK_STROKE_LIGHT = Color3.fromRGB(255, 105, 180)
local DARK_BG = Color3.fromRGB(30, 30, 30)
local DARK_BG2 = Color3.fromRGB(24, 24, 24)

local VALID_KEY = "SAKURA-PLACEHOLDER-KEY" -- TODO: replace with your real key check

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SakuraStudios_KeySystem"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

-- Intro -----------------------------------------------------------------

local INTRO2 = Instance.new("CanvasGroup")
INTRO2.Name = "INTRO"
INTRO2.Size = UDim2.new(0.455271,0,0.461860,0)
INTRO2.Position = UDim2.new(0.500000,0,0.500000,0)
INTRO2.AnchorPoint = Vector2.new(0.500000,0.500000)
INTRO2.BackgroundColor3 = DARK_BG
INTRO2.BackgroundTransparency = 0.000000
INTRO2.BorderSizePixel = 0.000000
INTRO2.Visible = true
INTRO2.AutomaticSize = Enum.AutomaticSize.None
INTRO2.ClipsDescendants = true
INTRO2.LayoutOrder = 0.000000
INTRO2.GroupTransparency = 1.000000
INTRO2.GroupColor3 = Color3.fromRGB(255,255,255)
INTRO2.Parent = ScreenGui

-- Loader background: the same topographic texture the key panel uses, so
-- both screens read as one product instead of two different designs.
local IntroPattern = Instance.new("ImageLabel")
IntroPattern.Name = "Pattern"
IntroPattern.Size = UDim2.new(1.000000,0,1.000000,0)
IntroPattern.Position = UDim2.new(0.000000,0,0.000000,0)
IntroPattern.AnchorPoint = Vector2.new(0.000000,0.000000)
IntroPattern.BackgroundColor3 = Color3.fromRGB(255,255,255)
IntroPattern.BackgroundTransparency = 1.000000
IntroPattern.BorderSizePixel = 0.000000
IntroPattern.Image = "rbxassetid://2151741365"
IntroPattern.ImageColor3 = PINK_STROKE_LIGHT
IntroPattern.ImageTransparency = 0.700000
IntroPattern.ScaleType = Enum.ScaleType.Tile
IntroPattern.SliceCenter = Rect.new(0,256,0,256)
IntroPattern.Visible = true
IntroPattern.ZIndex = 0.000000
IntroPattern.Parent = INTRO2

-- The Sakura hub banner, shown WHOLE (Fit) and centred in the upper part of
-- the loader. It was previously a full-bleed Crop, which fills the panel but
-- slices the edges off - and since this banner is a wide wordmark, that was
-- cutting into the lettering on any screen that didn't happen to match its
-- aspect ratio. Fit guarantees the whole banner is always readable.
local Wallpaper3 = Instance.new("ImageLabel")
Wallpaper3.Name = "Banner"
Wallpaper3.Size = UDim2.new(0.900000,0,0.620000,0)
Wallpaper3.Position = UDim2.new(0.500000,0,0.350000,0)
Wallpaper3.AnchorPoint = Vector2.new(0.500000,0.500000)
Wallpaper3.BackgroundColor3 = Color3.fromRGB(255,255,255)
Wallpaper3.BackgroundTransparency = 1.000000
Wallpaper3.BorderSizePixel = 0.000000
Wallpaper3.Image = BANNER
Wallpaper3.ImageColor3 = Color3.fromRGB(255,255,255)
Wallpaper3.ImageTransparency = 0.000000
Wallpaper3.ScaleType = Enum.ScaleType.Fit
Wallpaper3.SliceCenter = Rect.new(0,0,0,0)
Wallpaper3.Visible = true
Wallpaper3.ZIndex = 1.000000
Wallpaper3.Parent = INTRO2

local TextHolder4 = Instance.new("Frame")
TextHolder4.Name = "TextHolder"
TextHolder4.Size = UDim2.new(1.000000,0,0.284847,0)
TextHolder4.Position = UDim2.new(0.000000,0,0.753631,0)
TextHolder4.AnchorPoint = Vector2.new(0.000000,0.000000)
TextHolder4.BackgroundColor3 = DARK_BG
TextHolder4.BackgroundTransparency = 0.000000
TextHolder4.BorderSizePixel = 0.000000
TextHolder4.Visible = true
TextHolder4.ZIndex = 1.000000
TextHolder4.AutomaticSize = Enum.AutomaticSize.None
TextHolder4.ClipsDescendants = false
TextHolder4.LayoutOrder = 0.000000
TextHolder4.Parent = INTRO2

local Status5 = Instance.new("TextLabel")
Status5.Name = "Status"
Status5.Size = UDim2.new(0.799930,0,0.464041,0)
Status5.Position = UDim2.new(0.120042,0,0.254529,0)
Status5.AnchorPoint = Vector2.new(0.000000,0.000000)
Status5.BackgroundColor3 = Color3.fromRGB(255,255,255)
Status5.BackgroundTransparency = 1.000000
Status5.BorderSizePixel = 0.000000
Status5.Visible = true
Status5.AutomaticSize = Enum.AutomaticSize.None
Status5.ClipsDescendants = false
Status5.LayoutOrder = 0.000000
Status5.Active = false
Status5.Selectable = false
Status5.SizeConstraint = Enum.SizeConstraint.RelativeXY
Status5.ZIndex = 2.000000
Status5.Rotation = 0.000000
Status5.Transparency = 1.000000
Status5.Text = "Preparing Sakura Studios for an amazing experience."
Status5.TextColor3 = Color3.fromRGB(255,255,255)
Status5.TextSize = 20.000000
Status5.Font = Enum.Font.GothamMedium
Status5.TextScaled = true
Status5.TextWrapped = true
Status5.RichText = false
Status5.LineHeight = 1.000000
Status5.MaxVisibleGraphemes = -1.000000
Status5.TextTransparency = 0.000000
Status5.TextStrokeColor3 = Color3.fromRGB(0,0,0)
Status5.TextStrokeTransparency = 1.000000
Status5.TextTruncate = Enum.TextTruncate.None
Status5.TextXAlignment = Enum.TextXAlignment.Center
Status5.TextYAlignment = Enum.TextYAlignment.Center
Status5.Parent = TextHolder4

local UITextSizeConstraint6 = Instance.new("UITextSizeConstraint")
UITextSizeConstraint6.MinTextSize = 1.000000
UITextSizeConstraint6.MaxTextSize = 20.000000
UITextSizeConstraint6.Parent = Status5

local Gradient7 = Instance.new("Frame")
Gradient7.Name = "Gradient"
Gradient7.Size = UDim2.new(1.000000,0,1.000000,0)
Gradient7.Position = UDim2.new(0.000000,0,0.000000,0)
Gradient7.AnchorPoint = Vector2.new(0.000000,0.000000)
Gradient7.BackgroundColor3 = Color3.fromRGB(255,255,255)
Gradient7.BackgroundTransparency = 0.000000
Gradient7.BorderSizePixel = 0.000000
Gradient7.Visible = true
Gradient7.ZIndex = 1.000000
Gradient7.AutomaticSize = Enum.AutomaticSize.None
Gradient7.ClipsDescendants = false
Gradient7.LayoutOrder = 0.000000
Gradient7.Parent = TextHolder4

local UIGradient8 = Instance.new("UIGradient")
UIGradient8.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0.000000, PINK_BRIGHT),
	ColorSequenceKeypoint.new(0.466321, PINK_MID),
	ColorSequenceKeypoint.new(0.797927, PINK_MUTED),
	ColorSequenceKeypoint.new(1.000000, DARK_BG),
})
UIGradient8.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0.000000, 0.900000, 0.000000), NumberSequenceKeypoint.new(1.000000, 0.900000, 0.000000)})
UIGradient8.Rotation = -90.000000
UIGradient8.Offset = Vector2.new(0.000000,0.000000)
UIGradient8.Parent = Gradient7

local Pattern9 = Instance.new("ImageLabel")
Pattern9.Name = "Pattern"
Pattern9.Size = UDim2.new(1.000000,0,1.000000,0)
Pattern9.Position = UDim2.new(0.000066,0,0.001244,0)
Pattern9.AnchorPoint = Vector2.new(0.000000,0.000000)
Pattern9.BackgroundColor3 = Color3.fromRGB(255,255,255)
Pattern9.BackgroundTransparency = 1.000000
Pattern9.BorderSizePixel = 1.000000
Pattern9.Image = "rbxassetid://2151741365"
Pattern9.ImageColor3 = PINK_STROKE_LIGHT
Pattern9.ImageTransparency = 0.600000
Pattern9.ScaleType = Enum.ScaleType.Tile
Pattern9.SliceCenter = Rect.new(0,256,0,256)
Pattern9.Visible = true
Pattern9.ZIndex = 0.000000
Pattern9.Parent = Gradient7

-- Logo10/Main11 (the small circular flower badge) removed from the intro
-- screen per request - the banner above already carries the branding, so
-- it's not shown twice here. The flower still appears once, in the
-- GET_KEY panel below as Pfp38 (now cropped to a full circle).

local UIAspectRatioConstraint12 = Instance.new("UIAspectRatioConstraint")
UIAspectRatioConstraint12.AspectRatio = 2.083570
UIAspectRatioConstraint12.DominantAxis = Enum.DominantAxis.Width
UIAspectRatioConstraint12.Parent = INTRO2

local Loader13 = Instance.new("Frame")
Loader13.Name = "Loader"
Loader13.Size = UDim2.new(0.999948,0,0.028597,0)
Loader13.Position = UDim2.new(0.000000,0,0.751682,0)
Loader13.AnchorPoint = Vector2.new(0.000000,0.000000)
Loader13.BackgroundColor3 = Color3.fromRGB(16,16,16)
Loader13.BackgroundTransparency = 0.000000
Loader13.BorderSizePixel = 0.000000
Loader13.Visible = true
Loader13.ZIndex = 2.000000
Loader13.AutomaticSize = Enum.AutomaticSize.None
Loader13.ClipsDescendants = true
Loader13.LayoutOrder = 0.000000
Loader13.Parent = INTRO2

local Content14 = Instance.new("Frame")
Content14.Name = "Content"
Content14.Size = UDim2.new(0.000000,0,1.000000,0)
Content14.Position = UDim2.new(0.000000,0,0.000000,0)
Content14.AnchorPoint = Vector2.new(0.000000,0.000000)
Content14.BackgroundColor3 = PINK_BRIGHT
Content14.BackgroundTransparency = 0.000000
Content14.BorderSizePixel = 0.000000
Content14.Visible = true
Content14.ZIndex = 1.000000
Content14.AutomaticSize = Enum.AutomaticSize.None
Content14.ClipsDescendants = false
Content14.LayoutOrder = 0.000000
Content14.Parent = Loader13

local UIStroke15 = Instance.new("UIStroke")
UIStroke15.Color = Color3.fromRGB(0,0,0)
UIStroke15.Thickness = 1.000000
UIStroke15.Transparency = 0.500000
UIStroke15.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
UIStroke15.Parent = Content14

local ImageLabel16 = Instance.new("ImageLabel")
ImageLabel16.Name = "ImageLabel"
ImageLabel16.Size = UDim2.new(0.671884,0,15.120100,0)
ImageLabel16.Position = UDim2.new(1.000000,0,0.500000,0)
ImageLabel16.AnchorPoint = Vector2.new(0.500000,0.500000)
ImageLabel16.BackgroundColor3 = Color3.fromRGB(255,255,255)
ImageLabel16.BackgroundTransparency = 1.000000
ImageLabel16.BorderSizePixel = 0.000000
ImageLabel16.Image = "rbxassetid://16073652319"
ImageLabel16.ImageColor3 = PINK_BRIGHT
ImageLabel16.ImageTransparency = 0.000000
ImageLabel16.ScaleType = Enum.ScaleType.Stretch
ImageLabel16.SliceCenter = Rect.new(0,0,0,0)
ImageLabel16.Visible = true
ImageLabel16.ZIndex = 1.000000
ImageLabel16.Parent = Content14

local UIAspectRatioConstraint17 = Instance.new("UIAspectRatioConstraint")
UIAspectRatioConstraint17.AspectRatio = 1.498140
UIAspectRatioConstraint17.DominantAxis = Enum.DominantAxis.Width
UIAspectRatioConstraint17.Parent = ImageLabel16

local UICorner18 = Instance.new("UICorner")
UICorner18.CornerRadius = UDim.new(0.000000,30)
UICorner18.Parent = INTRO2

-- Key gate ----------------------------------------------------------------

local GET_KEY19 = Instance.new("CanvasGroup")
GET_KEY19.Name = "GET_KEY"
GET_KEY19.Size = UDim2.new(0.359117,0,0.665296,0)
GET_KEY19.Position = UDim2.new(0.500000,0,0.500000,0)
GET_KEY19.AnchorPoint = Vector2.new(0.500000,0.500000)
GET_KEY19.BackgroundColor3 = DARK_BG
GET_KEY19.BackgroundTransparency = 0.000000
GET_KEY19.BorderSizePixel = 0.000000
GET_KEY19.Visible = true
GET_KEY19.AutomaticSize = Enum.AutomaticSize.None
GET_KEY19.ClipsDescendants = true
GET_KEY19.LayoutOrder = 0.000000
GET_KEY19.GroupTransparency = 1.000000 -- starts hidden, revealed after the intro finishes
GET_KEY19.GroupColor3 = Color3.fromRGB(255,255,255)
GET_KEY19.Parent = ScreenGui

local UICorner20 = Instance.new("UICorner")
UICorner20.CornerRadius = UDim.new(0.075000,0)
UICorner20.Parent = GET_KEY19

-- NOTE: this slot is a wide 3.6:1 rectangle (0.481 x 0.134), not a square -
-- it was showing the round flower badge letterboxed with big empty gaps on
-- both sides. That shape is actually a much better fit for the wide
-- Sakura hub banner, so this now shows the banner here too (Crop, no
-- masking needed since it's already a plain rectangle) rather than
-- cropping a circular badge into a thin box. Say the word if you wanted
-- the flower kept here instead and the banner intro-only.
local Logo21 = Instance.new("ImageLabel")
Logo21.Name = "Logo"
Logo21.Size = UDim2.new(0.481145,0,0.133585,0)
Logo21.Position = UDim2.new(0.256362,0,0.070055,0)
Logo21.AnchorPoint = Vector2.new(0.000000,0.000000)
Logo21.BackgroundColor3 = Color3.fromRGB(255,255,255)
Logo21.BackgroundTransparency = 1.000000
Logo21.BorderSizePixel = 0.000000
Logo21.Image = BANNER
Logo21.ImageColor3 = Color3.fromRGB(255,255,255)
Logo21.ImageTransparency = 0.000000
-- Fit, not Crop: Crop fills the slot but slices the edges, which was eating
-- into the banner's lettering. Fit always shows the whole wordmark.
Logo21.ScaleType = Enum.ScaleType.Fit
Logo21.SliceCenter = Rect.new(0,0,0,0)
Logo21.Visible = true
Logo21.ZIndex = 2.000000
Logo21.Parent = GET_KEY19

local UIAspectRatioConstraint22 = Instance.new("UIAspectRatioConstraint")
UIAspectRatioConstraint22.AspectRatio = 1.140960
UIAspectRatioConstraint22.DominantAxis = Enum.DominantAxis.Width
UIAspectRatioConstraint22.Parent = GET_KEY19

local Get23 = Instance.new("TextButton")
Get23.Name = "Get"
Get23.Size = UDim2.new(0.510000,0,0.095000,0)
Get23.Position = UDim2.new(0.336000,0,0.453770,0)
Get23.AnchorPoint = Vector2.new(0.500000,0.500000)
Get23.BackgroundColor3 = PINK_MID
Get23.BackgroundTransparency = 0.000000
Get23.BorderSizePixel = 0.000000
Get23.Text = ""
Get23.TextColor3 = Color3.fromRGB(255,255,255)
Get23.TextSize = 20.000000
Get23.ZIndex = 2.000000
Get23.Font = Enum.Font.GothamBold
Get23.TextScaled = true
Get23.TextWrapped = true
Get23.RichText = false
Get23.Visible = true
Get23.AutoButtonColor = false
Get23.Parent = GET_KEY19

local Hover24 = Instance.new("ImageLabel")
Hover24.Name = "Hover"
Hover24.Size = UDim2.new(1.055000,0,1.450000,0)
Hover24.Position = UDim2.new(0.500000,0,0.500000,0)
Hover24.AnchorPoint = Vector2.new(0.500000,0.500000)
Hover24.BackgroundColor3 = Color3.fromRGB(255,255,255)
Hover24.BackgroundTransparency = 1.000000
Hover24.BorderSizePixel = 0.000000
Hover24.Image = "rbxassetid://16261022724"
Hover24.ImageColor3 = PINK_BRIGHT
Hover24.ImageTransparency = 1.000000
Hover24.ScaleType = Enum.ScaleType.Slice
Hover24.SliceCenter = Rect.new(205,197,828,828)
Hover24.Visible = true
Hover24.ZIndex = 1.000000
Hover24.Parent = Get23

local UICorner25 = Instance.new("UICorner")
UICorner25.CornerRadius = UDim.new(0.000000,7)
UICorner25.Parent = Get23

local UIStroke26 = Instance.new("UIStroke")
UIStroke26.Color = PINK_STROKE_LIGHT
UIStroke26.Thickness = 1.000000
UIStroke26.Transparency = 0.500000
UIStroke26.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIStroke26.Parent = Get23

local Title27 = Instance.new("TextLabel")
Title27.Name = "Title"
Title27.Size = UDim2.new(1.000000,0,0.546077,0)
Title27.Position = UDim2.new(0.500000,0,0.500000,0)
Title27.AnchorPoint = Vector2.new(0.500000,0.500000)
Title27.BackgroundColor3 = Color3.fromRGB(255,255,255)
Title27.BackgroundTransparency = 1.000000
Title27.BorderSizePixel = 0.000000
Title27.Visible = true
Title27.AutomaticSize = Enum.AutomaticSize.None
Title27.ClipsDescendants = false
Title27.LayoutOrder = 0.000000
Title27.Active = false
Title27.Selectable = false
Title27.SizeConstraint = Enum.SizeConstraint.RelativeXY
Title27.ZIndex = 1.000000
Title27.Rotation = 0.000000
Title27.Transparency = 1.000000
Title27.Text = "GET KEY"
Title27.TextColor3 = Color3.fromRGB(255,255,255)
Title27.TextSize = 8.000000
Title27.Font = Enum.Font.GothamBold
Title27.TextScaled = true
Title27.TextWrapped = true
Title27.RichText = false
Title27.LineHeight = 1.000000
Title27.MaxVisibleGraphemes = -1.000000
Title27.TextTransparency = 0.000000
Title27.TextStrokeColor3 = Color3.fromRGB(0,0,0)
Title27.TextStrokeTransparency = 1.000000
Title27.TextTruncate = Enum.TextTruncate.None
Title27.TextXAlignment = Enum.TextXAlignment.Center
Title27.TextYAlignment = Enum.TextYAlignment.Center
Title27.Parent = Get23

local Submit28 = Instance.new("TextButton")
Submit28.Name = "Submit"
Submit28.Size = UDim2.new(0.838618,0,0.095000,0)
Submit28.Position = UDim2.new(0.500630,0,0.578448,0)
Submit28.AnchorPoint = Vector2.new(0.500000,0.500000)
Submit28.BackgroundColor3 = PINK_MID
Submit28.BackgroundTransparency = 0.000000
Submit28.BorderSizePixel = 0.000000
Submit28.Text = ""
Submit28.TextColor3 = Color3.fromRGB(255,255,255)
Submit28.TextSize = 20.000000
Submit28.ZIndex = 2.000000
Submit28.Font = Enum.Font.GothamBold
Submit28.TextScaled = true
Submit28.TextWrapped = true
Submit28.RichText = false
Submit28.Visible = true
Submit28.AutoButtonColor = false
Submit28.Parent = GET_KEY19

local Hover29 = Instance.new("ImageLabel")
Hover29.Name = "Hover"
Hover29.Size = UDim2.new(1.055000,0,1.450000,0)
Hover29.Position = UDim2.new(0.500000,0,0.500000,0)
Hover29.AnchorPoint = Vector2.new(0.500000,0.500000)
Hover29.BackgroundColor3 = Color3.fromRGB(255,255,255)
Hover29.BackgroundTransparency = 1.000000
Hover29.BorderSizePixel = 0.000000
Hover29.Image = "rbxassetid://16261022724"
Hover29.ImageColor3 = PINK_BRIGHT
Hover29.ImageTransparency = 1.000000
Hover29.ScaleType = Enum.ScaleType.Slice
Hover29.SliceCenter = Rect.new(205,197,828,828)
Hover29.Visible = true
Hover29.ZIndex = 1.000000
Hover29.Parent = Submit28

local UICorner30 = Instance.new("UICorner")
UICorner30.CornerRadius = UDim.new(0.000000,7)
UICorner30.Parent = Submit28

local UIStroke31 = Instance.new("UIStroke")
UIStroke31.Color = PINK_STROKE_LIGHT
UIStroke31.Thickness = 1.000000
UIStroke31.Transparency = 0.500000
UIStroke31.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIStroke31.Parent = Submit28

local Title32 = Instance.new("TextLabel")
Title32.Name = "Title"
Title32.Size = UDim2.new(1.000000,0,0.546000,0)
Title32.Position = UDim2.new(0.500000,0,0.480000,0)
Title32.AnchorPoint = Vector2.new(0.500000,0.500000)
Title32.BackgroundColor3 = Color3.fromRGB(255,255,255)
Title32.BackgroundTransparency = 1.000000
Title32.BorderSizePixel = 0.000000
Title32.Visible = true
Title32.AutomaticSize = Enum.AutomaticSize.None
Title32.ClipsDescendants = false
Title32.LayoutOrder = 0.000000
Title32.Active = false
Title32.Selectable = false
Title32.SizeConstraint = Enum.SizeConstraint.RelativeXY
Title32.ZIndex = 1.000000
Title32.Rotation = 0.000000
Title32.Transparency = 1.000000
Title32.Text = "SUBMIT KEY"
Title32.TextColor3 = Color3.fromRGB(255,255,255)
Title32.TextSize = 8.000000
Title32.Font = Enum.Font.GothamBold
Title32.TextScaled = true
Title32.TextWrapped = true
Title32.RichText = false
Title32.LineHeight = 1.000000
Title32.MaxVisibleGraphemes = -1.000000
Title32.TextTransparency = 0.000000
Title32.TextStrokeColor3 = Color3.fromRGB(0,0,0)
Title32.TextStrokeTransparency = 1.000000
Title32.TextTruncate = Enum.TextTruncate.None
Title32.TextXAlignment = Enum.TextXAlignment.Center
Title32.TextYAlignment = Enum.TextYAlignment.Center
Title32.Parent = Submit28

local Get233 = Instance.new("TextButton")
Get233.Name = "Get2"
Get233.Size = UDim2.new(0.312000,0,0.095000,0)
Get233.Position = UDim2.new(0.764000,0,0.453770,0)
Get233.AnchorPoint = Vector2.new(0.500000,0.500000)
Get233.BackgroundColor3 = PINK_MID
Get233.BackgroundTransparency = 0.000000
Get233.BorderSizePixel = 0.000000
Get233.Text = ""
Get233.TextColor3 = Color3.fromRGB(255,255,255)
Get233.TextSize = 20.000000
Get233.ZIndex = 2.000000
Get233.Font = Enum.Font.GothamBold
Get233.TextScaled = true
Get233.TextWrapped = true
Get233.RichText = false
Get233.Visible = true
Get233.AutoButtonColor = false
Get233.Parent = GET_KEY19

local Hover34 = Instance.new("ImageLabel")
Hover34.Name = "Hover"
Hover34.Size = UDim2.new(1.055000,0,1.450000,0)
Hover34.Position = UDim2.new(0.500000,0,0.500000,0)
Hover34.AnchorPoint = Vector2.new(0.500000,0.500000)
Hover34.BackgroundColor3 = Color3.fromRGB(255,255,255)
Hover34.BackgroundTransparency = 1.000000
Hover34.BorderSizePixel = 0.000000
Hover34.Image = "rbxassetid://16261022724"
Hover34.ImageColor3 = PINK_BRIGHT
Hover34.ImageTransparency = 1.000000
Hover34.ScaleType = Enum.ScaleType.Slice
Hover34.SliceCenter = Rect.new(205,197,828,828)
Hover34.Visible = true
Hover34.ZIndex = 1.000000
Hover34.Parent = Get233

local UICorner35 = Instance.new("UICorner")
UICorner35.CornerRadius = UDim.new(0.000000,7)
UICorner35.Parent = Get233

local UIStroke36 = Instance.new("UIStroke")
UIStroke36.Color = PINK_STROKE_LIGHT
UIStroke36.Thickness = 1.000000
UIStroke36.Transparency = 0.500000
UIStroke36.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIStroke36.Parent = Get233

local Title37 = Instance.new("TextLabel")
Title37.Name = "Title"
Title37.Size = UDim2.new(1.000000,0,0.546077,0)
Title37.Position = UDim2.new(0.500000,0,0.500000,0)
Title37.AnchorPoint = Vector2.new(0.500000,0.500000)
Title37.BackgroundColor3 = Color3.fromRGB(255,255,255)
Title37.BackgroundTransparency = 1.000000
Title37.BorderSizePixel = 0.000000
Title37.Visible = true
Title37.AutomaticSize = Enum.AutomaticSize.None
Title37.ClipsDescendants = false
Title37.LayoutOrder = 0.000000
Title37.Active = false
Title37.Selectable = false
Title37.SizeConstraint = Enum.SizeConstraint.RelativeXY
Title37.ZIndex = 1.000000
Title37.Rotation = 0.000000
Title37.Transparency = 1.000000
Title37.Text = "How To Get Key"
Title37.TextColor3 = Color3.fromRGB(255,255,255)
Title37.TextSize = 8.000000
Title37.Font = Enum.Font.GothamBold
Title37.TextScaled = true
Title37.TextWrapped = true
Title37.RichText = false
Title37.LineHeight = 1.000000
Title37.MaxVisibleGraphemes = -1.000000
Title37.TextTransparency = 0.000000
Title37.TextStrokeColor3 = Color3.fromRGB(0,0,0)
Title37.TextStrokeTransparency = 1.000000
Title37.TextTruncate = Enum.TextTruncate.None
Title37.TextXAlignment = Enum.TextXAlignment.Center
Title37.TextYAlignment = Enum.TextYAlignment.Center
Title37.Parent = Get233

-- VERIFIED: UICorner correctly masks an ImageLabel's own image content (not
-- just its background) when applied directly to it - confirmed live, and
-- it's exactly what the original file was already doing here at a small
-- 0.075 radius. Bumped to 0.5 (full circle) for the "trim it" fix. Note:
-- this crops the badge to a circle, but can't zoom past a margin baked
-- into the source image itself without either resizing this element (which
-- would shift it against its neighbors in this layout) or the image's real
-- pixel dimensions for ImageRectOffset/Size (which I don't have) - if a
-- thin dark ring is still visible around the flower after this, tell me
-- the image's actual pixel size and I can crop it properly.
local Pfp38 = Instance.new("ImageLabel")
Pfp38.Name = "Pfp"
Pfp38.Size = UDim2.new(0.229672,0,0.261163,0)
-- Centre anchor (was top-left) so the breathing-pulse animation added at the
-- bottom scales it in place instead of drifting it toward the corner.
Pfp38.Position = UDim2.new(0.195850,0,0.783432,0)
Pfp38.AnchorPoint = Vector2.new(0.500000,0.500000)
Pfp38.BackgroundColor3 = Color3.fromRGB(255,255,255)
Pfp38.BackgroundTransparency = 1.000000
Pfp38.BorderSizePixel = 0.000000
Pfp38.Image = ICON
Pfp38.ImageColor3 = Color3.fromRGB(255,255,255)
Pfp38.ImageTransparency = 0.000000
Pfp38.ScaleType = Enum.ScaleType.Fit
Pfp38.SliceCenter = Rect.new(0,0,0,0)
Pfp38.Visible = true
Pfp38.ZIndex = 2.000000
Pfp38.Parent = GET_KEY19

local UICorner39 = Instance.new("UICorner")
UICorner39.CornerRadius = UDim.new(0.500000,0)
UICorner39.Parent = Pfp38

local Support40 = Instance.new("TextButton")
Support40.Name = "Support"
Support40.Size = UDim2.new(0.581950,0,0.081186,0)
Support40.Position = UDim2.new(0.626422,0,0.765503,0)
Support40.AnchorPoint = Vector2.new(0.500000,0.500000)
Support40.BackgroundColor3 = PINK_STROKE
Support40.BackgroundTransparency = 1.000000
Support40.BorderSizePixel = 0.000000
Support40.Text = ""
Support40.TextColor3 = Color3.fromRGB(255,255,255)
Support40.TextSize = 20.000000
Support40.ZIndex = 2.000000
Support40.Font = Enum.Font.GothamBold
Support40.TextScaled = true
Support40.TextWrapped = true
Support40.RichText = false
Support40.Visible = true
Support40.AutoButtonColor = false
Support40.Parent = GET_KEY19

local UICorner41 = Instance.new("UICorner")
UICorner41.CornerRadius = UDim.new(0.000000,7)
UICorner41.Parent = Support40

local UIStroke42 = Instance.new("UIStroke")
UIStroke42.Color = PINK_STROKE_LIGHT
UIStroke42.Thickness = 1.250000
UIStroke42.Transparency = 0.250000
UIStroke42.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIStroke42.Parent = Support40

local Title43 = Instance.new("TextLabel")
Title43.Name = "Title"
Title43.Size = UDim2.new(1.000000,0,0.600000,0)
Title43.Position = UDim2.new(0.500000,0,0.500000,0)
Title43.AnchorPoint = Vector2.new(0.500000,0.500000)
Title43.BackgroundColor3 = Color3.fromRGB(255,255,255)
Title43.BackgroundTransparency = 1.000000
Title43.BorderSizePixel = 0.000000
Title43.Visible = true
Title43.AutomaticSize = Enum.AutomaticSize.None
Title43.ClipsDescendants = false
Title43.LayoutOrder = 0.000000
Title43.Active = false
Title43.Selectable = false
Title43.SizeConstraint = Enum.SizeConstraint.RelativeXY
Title43.ZIndex = 1.000000
Title43.Rotation = 0.000000
Title43.Transparency = 1.000000
Title43.Text = "SUPPORT US"
Title43.TextColor3 = PINK_STROKE
Title43.TextSize = 8.000000
Title43.Font = Enum.Font.GothamBold
Title43.TextScaled = true
Title43.TextWrapped = true
Title43.RichText = false
Title43.LineHeight = 1.000000
Title43.MaxVisibleGraphemes = -1.000000
Title43.TextTransparency = 0.000000
Title43.TextStrokeColor3 = Color3.fromRGB(0,0,0)
Title43.TextStrokeTransparency = 1.000000
Title43.TextTruncate = Enum.TextTruncate.None
Title43.TextXAlignment = Enum.TextXAlignment.Center
Title43.TextYAlignment = Enum.TextYAlignment.Center
Title43.Parent = Support40

local Credit44 = Instance.new("TextLabel")
Credit44.Name = "Credit"
Credit44.Size = UDim2.new(0.584491,0,0.053618,0)
Credit44.Position = UDim2.new(0.627693,0,0.679660,0)
Credit44.AnchorPoint = Vector2.new(0.500000,0.500000)
Credit44.BackgroundColor3 = Color3.fromRGB(255,255,255)
Credit44.BackgroundTransparency = 1.000000
Credit44.BorderSizePixel = 0.000000
Credit44.Visible = true
Credit44.AutomaticSize = Enum.AutomaticSize.None
Credit44.ClipsDescendants = false
Credit44.LayoutOrder = 0.000000
Credit44.Active = false
Credit44.Selectable = false
Credit44.SizeConstraint = Enum.SizeConstraint.RelativeXY
Credit44.ZIndex = 2.000000
Credit44.Rotation = 0.000000
Credit44.Transparency = 1.000000
-- TODO: swap in your real socials, e.g. <font color="#ff2d95">YT</font> @yourhandle | <font color="#ff69b4">DISCORD</font> discord.gg/yourinvite
Credit44.Text = "<font color=\"#ff2d95\">SAKURA STUDIOS</font>"
Credit44.TextColor3 = Color3.fromRGB(255,255,255)
Credit44.TextSize = 8.000000
Credit44.Font = Enum.Font.GothamMedium
Credit44.TextScaled = true
Credit44.TextWrapped = true
Credit44.RichText = true
Credit44.LineHeight = 1.000000
Credit44.MaxVisibleGraphemes = -1.000000
Credit44.TextTransparency = 0.000000
Credit44.TextStrokeColor3 = Color3.fromRGB(0,0,0)
Credit44.TextStrokeTransparency = 1.000000
Credit44.TextTruncate = Enum.TextTruncate.None
Credit44.TextXAlignment = Enum.TextXAlignment.Center
Credit44.TextYAlignment = Enum.TextYAlignment.Center
Credit44.Parent = GET_KEY19

local Close45 = Instance.new("TextButton")
Close45.Name = "Close"
Close45.Size = UDim2.new(0.582000,0,0.081000,0)
Close45.Position = UDim2.new(0.626422,0,0.871296,0)
Close45.AnchorPoint = Vector2.new(0.500000,0.500000)
Close45.BackgroundColor3 = PINK_STROKE
Close45.BackgroundTransparency = 1.000000
Close45.BorderSizePixel = 0.000000
Close45.Text = ""
Close45.TextColor3 = Color3.fromRGB(255,255,255)
Close45.TextSize = 20.000000
Close45.ZIndex = 2.000000
Close45.Font = Enum.Font.GothamBold
Close45.TextScaled = true
Close45.TextWrapped = true
Close45.RichText = false
Close45.Visible = true
Close45.AutoButtonColor = false
Close45.Parent = GET_KEY19

local Title46 = Instance.new("TextLabel")
Title46.Name = "Title"
Title46.Size = UDim2.new(1.000000,0,0.600000,0)
Title46.Position = UDim2.new(0.500000,0,0.500000,0)
Title46.AnchorPoint = Vector2.new(0.500000,0.500000)
Title46.BackgroundColor3 = Color3.fromRGB(255,255,255)
Title46.BackgroundTransparency = 1.000000
Title46.BorderSizePixel = 0.000000
Title46.Visible = true
Title46.AutomaticSize = Enum.AutomaticSize.None
Title46.ClipsDescendants = false
Title46.LayoutOrder = 0.000000
Title46.Active = false
Title46.Selectable = false
Title46.SizeConstraint = Enum.SizeConstraint.RelativeXY
Title46.ZIndex = 1.000000
Title46.Rotation = 0.000000
Title46.Transparency = 1.000000
Title46.Text = "CLOSE UI"
Title46.TextColor3 = PINK_STROKE
Title46.TextSize = 8.000000
Title46.Font = Enum.Font.GothamBold
Title46.TextScaled = true
Title46.TextWrapped = true
Title46.RichText = false
Title46.LineHeight = 1.000000
Title46.MaxVisibleGraphemes = -1.000000
Title46.TextTransparency = 0.000000
Title46.TextStrokeColor3 = Color3.fromRGB(0,0,0)
Title46.TextStrokeTransparency = 1.000000
Title46.TextTruncate = Enum.TextTruncate.None
Title46.TextXAlignment = Enum.TextXAlignment.Center
Title46.TextYAlignment = Enum.TextYAlignment.Center
Title46.Parent = Close45

local UIStroke47 = Instance.new("UIStroke")
UIStroke47.Color = PINK_STROKE_LIGHT
UIStroke47.Thickness = 1.250000
UIStroke47.Transparency = 0.250000
UIStroke47.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIStroke47.Parent = Close45

local UICorner48 = Instance.new("UICorner")
UICorner48.CornerRadius = UDim.new(0.000000,7)
UICorner48.Parent = Close45

-- Expanded key-entry card. Was a cramped single row (label taking the left
-- half, a tiny pill textbox squeezed on the right). Now it's a taller card
-- with the label on top and a full-width input underneath - far easier to
-- actually tap and type a key into on mobile.
local Frame49 = Instance.new("Frame")
Frame49.Name = "Frame"
Frame49.Size = UDim2.new(0.868000,0,0.162000,0)
Frame49.Position = UDim2.new(0.500630,0,0.300000,0)
Frame49.AnchorPoint = Vector2.new(0.500000,0.500000)
Frame49.BackgroundColor3 = DARK_BG2
Frame49.BackgroundTransparency = 0.000000
Frame49.BorderSizePixel = 0.000000
Frame49.Visible = true
Frame49.ZIndex = 2.000000
Frame49.AutomaticSize = Enum.AutomaticSize.None
Frame49.ClipsDescendants = false
Frame49.LayoutOrder = 0.000000
Frame49.Parent = GET_KEY19

local UIStroke50 = Instance.new("UIStroke")
UIStroke50.Color = Color3.fromRGB(255,255,255)
UIStroke50.Thickness = 2.000000
UIStroke50.Transparency = 0.500000
UIStroke50.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
UIStroke50.Parent = Frame49

local UIGradient51 = Instance.new("UIGradient")
UIGradient51.Color = ColorSequence.new({ColorSequenceKeypoint.new(0.000000, PINK_STROKE), ColorSequenceKeypoint.new(1.000000, PINK_STROKE)})
UIGradient51.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0.000000, 0.000000, 0.000000), NumberSequenceKeypoint.new(0.900000, 0.995000, 0.000000), NumberSequenceKeypoint.new(1.000000, 1.000000, 0.000000)})
UIGradient51.Rotation = -90.000000
UIGradient51.Offset = Vector2.new(0.000000,0.000000)
UIGradient51.Parent = UIStroke50

local UICorner52 = Instance.new("UICorner")
UICorner52.CornerRadius = UDim.new(0.000000,7)
UICorner52.Parent = Frame49

local Title53 = Instance.new("TextLabel")
Title53.Name = "Title"
Title53.Size = UDim2.new(0.900000,0,0.300000,0)
Title53.Position = UDim2.new(0.500000,0,0.255000,0)
Title53.AnchorPoint = Vector2.new(0.500000,0.500000)
Title53.BackgroundColor3 = DARK_BG2
Title53.BackgroundTransparency = 1.000000
Title53.BorderSizePixel = 0.000000
Title53.Visible = true
Title53.AutomaticSize = Enum.AutomaticSize.None
Title53.ClipsDescendants = false
Title53.LayoutOrder = 0.000000
Title53.Active = false
Title53.Selectable = false
Title53.SizeConstraint = Enum.SizeConstraint.RelativeXY
Title53.ZIndex = 1.000000
Title53.Rotation = 0.000000
Title53.Transparency = 1.000000
Title53.Text = "ENTER KEY HERE"
Title53.TextColor3 = PINK_STROKE_LIGHT
Title53.TextSize = 8.000000
Title53.Font = Enum.Font.GothamMedium
Title53.TextScaled = true
Title53.TextWrapped = true
Title53.RichText = false
Title53.LineHeight = 1.000000
Title53.MaxVisibleGraphemes = -1.000000
Title53.TextTransparency = 0.000000
Title53.TextStrokeColor3 = Color3.fromRGB(0,0,0)
Title53.TextStrokeTransparency = 1.000000
Title53.TextTruncate = Enum.TextTruncate.None
Title53.TextXAlignment = Enum.TextXAlignment.Center
Title53.TextYAlignment = Enum.TextYAlignment.Center
Title53.Parent = Frame49

-- Cap the label/input text so TextScaled can't blow it up in the taller card.
local KeyTitleTextSize = Instance.new("UITextSizeConstraint")
KeyTitleTextSize.MinTextSize = 1
KeyTitleTextSize.MaxTextSize = 15
KeyTitleTextSize.Parent = Title53

local Textbox54 = Instance.new("TextBox")
Textbox54.Name = "Textbox"
Textbox54.Size = UDim2.new(0.900000,0,0.420000,0)
Textbox54.Position = UDim2.new(0.500000,0,0.680000,0)
Textbox54.AnchorPoint = Vector2.new(0.500000,0.500000)
Textbox54.BackgroundColor3 = Color3.fromRGB(16,16,16)
Textbox54.BackgroundTransparency = 0.000000
Textbox54.BorderSizePixel = 0.000000
Textbox54.Text = ""
Textbox54.TextColor3 = Color3.fromRGB(255,255,255)
Textbox54.TextSize = 8.000000
Textbox54.Font = Enum.Font.Gotham
Textbox54.ZIndex = 1.000000
Textbox54.TextScaled = true
Textbox54.TextWrapped = true
Textbox54.RichText = false
Textbox54.Visible = true
Textbox54.ClearTextOnFocus = true
Textbox54.MultiLine = false
Textbox54.PlaceholderText = "Paste your key here"
Textbox54.PlaceholderColor3 = Color3.fromRGB(178,178,178)
Textbox54.CursorPosition = 1.000000
Textbox54.SelectionStart = -1.000000
Textbox54.ShowNativeInput = true
Textbox54.TextEditable = true
Textbox54.TextXAlignment = Enum.TextXAlignment.Center
Textbox54.TextYAlignment = Enum.TextYAlignment.Center
Textbox54.Parent = Frame49

local KeyBoxTextSize = Instance.new("UITextSizeConstraint")
KeyBoxTextSize.MinTextSize = 1
KeyBoxTextSize.MaxTextSize = 18
KeyBoxTextSize.Parent = Textbox54

local UIStroke55 = Instance.new("UIStroke")
UIStroke55.Color = PINK_STROKE
UIStroke55.Thickness = 1.250000
UIStroke55.Transparency = 0.500000
UIStroke55.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIStroke55.Parent = Textbox54

local UIGradient56 = Instance.new("UIGradient")
UIGradient56.Color = ColorSequence.new({ColorSequenceKeypoint.new(0.000000, Color3.fromRGB(255,255,255)), ColorSequenceKeypoint.new(1.000000, Color3.fromRGB(255,255,255))})
UIGradient56.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0.000000, 0.000000, 0.000000), NumberSequenceKeypoint.new(0.900000, 0.995000, 0.000000), NumberSequenceKeypoint.new(1.000000, 1.000000, 0.000000)})
UIGradient56.Rotation = -90.000000
UIGradient56.Offset = Vector2.new(0.000000,0.000000)
UIGradient56.Parent = UIStroke55

local UICorner57 = Instance.new("UICorner")
UICorner57.CornerRadius = UDim.new(0.500000,0) -- full pill on the wider input
UICorner57.Parent = Textbox54

local Gradient58 = Instance.new("Frame")
Gradient58.Name = "Gradient"
Gradient58.Size = UDim2.new(1.000000,0,1.000000,0)
Gradient58.Position = UDim2.new(0.000000,0,0.000000,0)
Gradient58.AnchorPoint = Vector2.new(0.000000,0.000000)
Gradient58.BackgroundColor3 = Color3.fromRGB(255,255,255)
Gradient58.BackgroundTransparency = 1.000000
Gradient58.BorderSizePixel = 0.000000
Gradient58.Visible = true
Gradient58.ZIndex = 0.000000
Gradient58.AutomaticSize = Enum.AutomaticSize.None
Gradient58.ClipsDescendants = false
Gradient58.LayoutOrder = 0.000000
Gradient58.Parent = Frame49

local UIGradient59 = Instance.new("UIGradient")
UIGradient59.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0.000000, PINK_DEEP),
	ColorSequenceKeypoint.new(0.531952, PINK_MUTED),
	ColorSequenceKeypoint.new(1.000000, DARK_BG2),
})
UIGradient59.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0.000000, 0.000000, 0.000000), NumberSequenceKeypoint.new(1.000000, 0.000000, 0.000000)})
UIGradient59.Rotation = -90.000000
UIGradient59.Offset = Vector2.new(0.000000,0.000000)
UIGradient59.Parent = Gradient58

local UICorner60 = Instance.new("UICorner")
UICorner60.CornerRadius = UDim.new(0.000000,10)
UICorner60.Parent = Gradient58

local Gradient61 = Instance.new("Frame")
Gradient61.Name = "Gradient"
Gradient61.Size = UDim2.new(1.000000,0,1.000000,0)
Gradient61.Position = UDim2.new(0.000000,0,0.000000,0)
Gradient61.AnchorPoint = Vector2.new(0.000000,0.000000)
Gradient61.BackgroundColor3 = Color3.fromRGB(255,255,255)
Gradient61.BackgroundTransparency = 0.000000
Gradient61.BorderSizePixel = 0.000000
Gradient61.Visible = true
Gradient61.ZIndex = 1.000000
Gradient61.AutomaticSize = Enum.AutomaticSize.None
Gradient61.ClipsDescendants = false
Gradient61.LayoutOrder = 0.000000
Gradient61.Parent = GET_KEY19

local UIGradient62 = Instance.new("UIGradient")
UIGradient62.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0.000000, PINK_BRIGHT),
	ColorSequenceKeypoint.new(0.468048, PINK_MUTED),
	ColorSequenceKeypoint.new(1.000000, DARK_BG),
})
UIGradient62.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0.000000, 0.900000, 0.000000), NumberSequenceKeypoint.new(1.000000, 0.900000, 0.000000)})
UIGradient62.Rotation = -90.000000
UIGradient62.Offset = Vector2.new(0.000000,0.000000)
UIGradient62.Parent = Gradient61

local Pattern63 = Instance.new("ImageLabel")
Pattern63.Name = "Pattern"
Pattern63.Size = UDim2.new(1.000000,0,1.000000,0)
Pattern63.Position = UDim2.new(0.000066,0,0.001244,0)
Pattern63.AnchorPoint = Vector2.new(0.000000,0.000000)
Pattern63.BackgroundColor3 = Color3.fromRGB(255,255,255)
Pattern63.BackgroundTransparency = 1.000000
Pattern63.BorderSizePixel = 1.000000
Pattern63.Image = "rbxassetid://2151741365"
Pattern63.ImageColor3 = PINK_STROKE_LIGHT
Pattern63.ImageTransparency = 0.600000
Pattern63.ScaleType = Enum.ScaleType.Tile
Pattern63.SliceCenter = Rect.new(0,256,0,256)
Pattern63.Visible = true
Pattern63.ZIndex = 0.000000
Pattern63.Parent = Gradient61

-- Behavior --------------------------------------------------------------
-- None of this existed in the uploaded file (it was a GUI-only export - no
-- LocalScript/animation/button logic came with it). Added below:

local function fadeGroup(group, target, duration)
	return TweenService:Create(group, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		GroupTransparency = target,
	})
end

local Camera = workspace.CurrentCamera

--========================= AUTO DPI =========================--
-- A UIScale per panel, recomputed from the viewport so the hub keeps a
-- comfortable on-screen size on phones, tablets and desktop, and re-adjusts
-- live if the window resizes or the device rotates. REF_HEIGHT is the
-- resolution it's tuned around: LOWER it to make the whole UI bigger, raise
-- it to make it smaller. The clamp stops it ever going tiny or oversized.
local REF_HEIGHT = 820
local DPI_MIN, DPI_MAX = 0.80, 1.35
local introScale = Instance.new("UIScale")
introScale.Parent = INTRO2
local keyScale = Instance.new("UIScale")
keyScale.Parent = GET_KEY19

local baseScale = 1
local function updateDPI()
	local vp = (Camera and Camera.ViewportSize) or Vector2.new(1280, 720)
	baseScale = (vp.Y > 0) and math.clamp(vp.Y / REF_HEIGHT, DPI_MIN, DPI_MAX) or 1
	introScale.Scale = baseScale
	keyScale.Scale = baseScale
end
updateDPI()
if Camera then
	Camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateDPI)
end

-- pop-in overshoot (Back easing) using the DPI scale as the target
local function popIn(scaleObj, dur)
	scaleObj.Scale = baseScale * 0.9
	TweenService:Create(scaleObj, TweenInfo.new(dur or 0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Scale = baseScale,
	}):Play()
end

--======================== LOOK-MAX ========================--

-- Glowing, breathing pink border on each panel, with the gradient slowly
-- rotating for a moving-light shimmer.
--
-- BUG FIX - "when loading it shows outlines of a UI before it's there":
-- that was this stroke, added in the last pass. A UIStroke on a CanvasGroup
-- is NOT hidden by GroupTransparency (it renders as a border decoration
-- outside the group's composite), so the key panel's pink outline sat on
-- screen through the whole loading screen. Fixed two ways: each panel now
-- starts Visible = false (Visible hides everything, decorations included)
-- and is only shown at reveal time, and the stroke starts fully transparent
-- and fades in with its panel, with the breathing loop gated behind an
-- `active` flag so it can't fight that fade.
local PanelGlow = {}

local function addPanelGlow(panel)
	local s = Instance.new("UIStroke")
	s.Color = PINK_STROKE
	s.Thickness = 2
	s.Transparency = 1
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = panel
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, PINK_STROKE_LIGHT),
		ColorSequenceKeypoint.new(0.5, PINK_STROKE),
		ColorSequenceKeypoint.new(1, PINK_MID),
	})
	g.Rotation = 90
	g.Parent = s

	local entry = { stroke = s, active = false }
	PanelGlow[panel] = entry

	task.spawn(function()
		while s.Parent do
			if entry.active then
				TweenService:Create(s, TweenInfo.new(1.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Thickness = 3.4, Transparency = 0 }):Play()
				task.wait(1.7)
				if s.Parent and entry.active then
					TweenService:Create(s, TweenInfo.new(1.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Thickness = 2, Transparency = 0.25 }):Play()
					task.wait(1.7)
				end
			else
				task.wait(0.15)
			end
		end
	end)
	task.spawn(function()
		while g.Parent do
			g.Rotation = 90
			TweenService:Create(g, TweenInfo.new(5, Enum.EasingStyle.Linear), { Rotation = 450 }):Play()
			task.wait(5)
		end
	end)
end
addPanelGlow(INTRO2)
addPanelGlow(GET_KEY19)

-- Nothing renders until its panel is explicitly shown - this is what stops
-- the outline leaking through the loading screen.
INTRO2.Visible = false
GET_KEY19.Visible = false

local function showPanel(panel, dur)
	panel.Visible = true
	local entry = PanelGlow[panel]
	if entry then
		entry.active = false
		entry.stroke.Transparency = 1
		TweenService:Create(entry.stroke, TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Transparency = 0.2 }):Play()
		task.delay(dur, function()
			entry.active = true
		end)
	end
	fadeGroup(panel, 0, dur):Play()
end

local function hidePanel(panel, dur)
	local entry = PanelGlow[panel]
	if entry then
		entry.active = false
		TweenService:Create(entry.stroke, TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Transparency = 1 }):Play()
	end
	local t = fadeGroup(panel, 1, dur)
	t:Play()
	return t
end

-- Glossy top-lit gradient on the three action buttons (bright pink up top,
-- deeper pink at the bottom - reads like a soft-lit button instead of a
-- flat fill).
local function glossify(btn)
	btn.BackgroundColor3 = PINK_BRIGHT
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(176, 176, 176)),
	})
	g.Rotation = 90
	g.Parent = btn
end
glossify(Get23)
glossify(Submit28)
glossify(Get233)

-- Soft pulsing glow ring behind the flower badge + a gentle breathing pulse
-- on the badge itself.
local pfpGlow = Instance.new("ImageLabel")
pfpGlow.Name = "PfpGlow"
pfpGlow.BackgroundTransparency = 1
pfpGlow.AnchorPoint = Vector2.new(0.5, 0.5)
pfpGlow.Position = UDim2.new(0.195850, 0, 0.783432, 0)
pfpGlow.Size = UDim2.new(0.229672 * 1.85, 0, 0.261163 * 1.85, 0)
pfpGlow.Image = "rbxassetid://16261022724"
pfpGlow.ImageColor3 = PINK_STROKE
pfpGlow.ImageTransparency = 0.45
pfpGlow.ScaleType = Enum.ScaleType.Fit
pfpGlow.ZIndex = 1
pfpGlow.Parent = GET_KEY19

local pfpScale = Instance.new("UIScale")
pfpScale.Parent = Pfp38
task.spawn(function()
	while pfpScale.Parent do
		TweenService:Create(pfpScale, TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Scale = 1.06 }):Play()
		TweenService:Create(pfpGlow, TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { ImageTransparency = 0.15 }):Play()
		task.wait(1.6)
		if not pfpScale.Parent then break end
		TweenService:Create(pfpScale, TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Scale = 1 }):Play()
		TweenService:Create(pfpGlow, TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { ImageTransparency = 0.5 }):Play()
		task.wait(1.6)
	end
end)

-- Tactile press feedback: dip + glow on press, spring back on release. Works
-- for touch (Roblox synthesizes MouseButton1Down/Up on GUI buttons for taps).
local function addButtonFeedback(btn, glow)
	local sc = Instance.new("UIScale")
	sc.Parent = btn
	local function down()
		TweenService:Create(sc, TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 0.93 }):Play()
		if glow then
			TweenService:Create(glow, TweenInfo.new(0.10), { ImageTransparency = 0.25 }):Play()
		end
	end
	local function up()
		TweenService:Create(sc, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		if glow then
			TweenService:Create(glow, TweenInfo.new(0.3), { ImageTransparency = 1 }):Play()
		end
	end
	btn.MouseButton1Down:Connect(down)
	btn.MouseButton1Up:Connect(up)
	btn.MouseLeave:Connect(up)
end
addButtonFeedback(Get23, Hover24)
addButtonFeedback(Submit28, Hover29)
addButtonFeedback(Get233, Hover34)
addButtonFeedback(Support40, nil)
addButtonFeedback(Close45, nil)

-- Drifting sakura in the background - soft pink orbs (uses the transparent
-- glow sprite tinted pink, so there's no black-square backing like the raw
-- flower icon would have). Sits behind both panels (ZIndex 0).
do
	local petalLayer = Instance.new("Frame")
	petalLayer.Name = "Petals"
	petalLayer.Size = UDim2.new(1, 0, 1, 0)
	petalLayer.BackgroundTransparency = 1
	petalLayer.ZIndex = 0
	petalLayer.Parent = ScreenGui

	local rand = Random.new()
	local function runPetal()
		local p = Instance.new("ImageLabel")
		p.BackgroundTransparency = 1
		p.Image = "rbxassetid://16261022724"
		p.ScaleType = Enum.ScaleType.Fit
		p.AnchorPoint = Vector2.new(0.5, 0.5)
		p.SizeConstraint = Enum.SizeConstraint.RelativeXX
		p.ImageColor3 = Color3.fromRGB(255, 175, 210)
		p.ZIndex = 0
		p.Parent = petalLayer
		while p.Parent do
			local sz = rand:NextNumber(0.018, 0.05)
			p.Size = UDim2.new(sz, 0, sz, 0)
			p.ImageTransparency = rand:NextNumber(0.4, 0.72)
			local startX = rand:NextNumber(0, 1)
			local drift = rand:NextNumber(-0.12, 0.12)
			local dur = rand:NextNumber(7, 12)
			p.Position = UDim2.new(startX, 0, -0.12, 0)
			p.Rotation = rand:NextNumber(0, 360)
			local move = TweenService:Create(p, TweenInfo.new(dur, Enum.EasingStyle.Linear), {
				Position = UDim2.new(startX + drift, 0, 1.15, 0),
				Rotation = p.Rotation + rand:NextNumber(120, 300),
			})
			move:Play()
			move.Completed:Wait()
		end
	end
	for _ = 1, 9 do
		task.spawn(function()
			task.wait(rand:NextNumber(0, 7))
			runPetal()
		end)
	end
end

-- Intro / reveal timeline -------------------------------------------------
task.spawn(function()
	-- fade + pop in the intro
	popIn(introScale, 0.6)
	showPanel(INTRO2, 0.6)
	task.wait(0.3)

	-- fill the loading bar while the status text updates
	-- BUG FIX: this used to Play() the tween, run a 3x0.6s = 1.8s message
	-- loop (matching the tween's own 1.8s duration) and then call
	-- fillTween.Completed:Wait() - but since both finished at essentially
	-- the same moment, the Completed event had usually already fired by
	-- the time execution reached that line, so :Wait() sat waiting for a
	-- second firing that was never coming, hanging forever on the last
	-- message ("Almost there..."), exactly what you saw. Fixed by driving
	-- the message timing directly off the tween's own duration instead of
	-- waiting on the signal at all.
	local FILL_DURATION = 1.8
	local messages = {
		"Preparing Sakura Studios for an amazing experience.",
		"Loading assets...",
		"Almost there...",
	}
	local fillTween = TweenService:Create(Content14, TweenInfo.new(FILL_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(1, 0, 1, 0),
	})
	fillTween:Play()
	local perMessage = FILL_DURATION / #messages
	for _, msg in ipairs(messages) do
		Status5.Text = msg
		task.wait(perMessage)
	end
	task.wait(0.2)

	-- fade the intro out, fade + pop the key gate in
	hidePanel(INTRO2, 0.5)
	task.wait(0.5)
	INTRO2.Visible = false
	popIn(keyScale, 0.55)
	showPanel(GET_KEY19, 0.5)
end)

Close45.Activated:Connect(function()
	local tween = hidePanel(GET_KEY19, 0.3)
	tween.Completed:Wait()
	ScreenGui:Destroy()
end)

Submit28.Activated:Connect(function()
	local entered = Textbox54.Text
	local flashColor = (entered == VALID_KEY) and Color3.fromRGB(80, 220, 140) or Color3.fromRGB(220, 60, 60)
	local originalColor = UIStroke55.Color
	UIStroke55.Color = flashColor
	task.delay(0.6, function()
		UIStroke55.Color = originalColor
	end)
	if entered == VALID_KEY then
		Title53.Text = "KEY ACCEPTED"
		-- TODO: unlock/launch your actual hub here
	else
		Title53.Text = "INVALID KEY"
		task.delay(1.2, function()
			Title53.Text = "ENTER KEY HERE"
		end)
	end
end)

-- TODO: point these at your real "get key" site / tutorial / support link.
-- Left as no-ops rather than guessed URLs.
Get23.Activated:Connect(function()
	Title27.Text = "LINK NOT SET"
	task.delay(1.2, function()
		Title27.Text = "GET KEY"
	end)
end)

Get233.Activated:Connect(function()
	Title37.Text = "LINK NOT SET"
	task.delay(1.2, function()
		Title37.Text = "How To Get Key"
	end)
end)

Support40.Activated:Connect(function()
	Title43.Text = "LINK NOT SET"
	task.delay(1.2, function()
		Title43.Text = "SUPPORT US"
	end)
end)
