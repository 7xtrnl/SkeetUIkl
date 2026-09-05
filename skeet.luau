--[[
	══════════════════════════════════════════════════════════════════════════════
	  SKEETWARE UI v5.0 — Pixel-Perfect Hard Edge Skeet Design Engine
	  • Pure Authentic Skeet Styling (Clean Bevels, Razor-Sharp Borders, No Fake Glow)
	  • 100% Native 2D Saturation/Value Palette & 7-Stop Hue Rainbow Bar
	  • Fully Dynamic Live Theme System (Fonts, Accents, Backgrounds, Outlines)
	  • Non-Clipping Floating Dropdowns (Single & Multi-Select with Auto-List Sizing)
	  • Pixel-Aligned Groupboxes with Clean Border-Breaking Header Badges
	  • High-Contrast Keybind Buttons with Right-Click Context Menu (Hold/Toggle/Always)
	  • Smooth Sliders, Responsive Textboxes & Polished Buttons
	  • Watermark & Real-Time Draggable Keybinds List HUD
	  • Notification System with Animated Header Timer
	══════════════════════════════════════════════════════════════════════════════
--]]

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService       = game:GetService("GuiService")
local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")
local CoreGui          = game:GetService("CoreGui")
local SoundService     = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer

local function getSafeGuiParent()
	local ok, res = pcall(function()
		if typeof(gethui) == "function" then
			return gethui()
		elseif (syn and syn.protect_gui) or (typeof(protect_gui) == "function") then
			local g = Instance.new("Folder")
			if syn and syn.protect_gui then syn.protect_gui(g) elseif protect_gui then protect_gui(g) end
			g.Parent = CoreGui
			return g
		else
			return CoreGui
		end
	end)
	if ok and res then return res end
	return LocalPlayer:WaitForChild("PlayerGui")
end

local oldGui = getSafeGuiParent():FindFirstChild("SkeetwareUI")
if oldGui then oldGui:Destroy() end

-- Clean up old blur effects
pcall(function()
	local lighting = game:GetService("Lighting")
	local oldBlur = lighting:FindFirstChild("SkeetwareBlur")
	if oldBlur then oldBlur:Destroy() end
end)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SkeetwareUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = getSafeGuiParent()

-- Blur overlay system
local blurEffect = nil
pcall(function()
	local lighting = game:GetService("Lighting")
	blurEffect = Instance.new("BlurEffect")
	blurEffect.Name = "SkeetwareBlur"
	blurEffect.Size = 0
	blurEffect.Parent = lighting
end)

local blurOverlay = Instance.new("Frame")
blurOverlay.Name = "BlurOverlay"
blurOverlay.Size = UDim2.fromScale(1, 1)
blurOverlay.Position = UDim2.fromScale(0, 0)
blurOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
blurOverlay.BackgroundTransparency = 1
blurOverlay.BorderSizePixel = 0
blurOverlay.ZIndex = 5
blurOverlay.Visible = false
blurOverlay.Parent = screenGui

-- Subtle vignette gradient on blur overlay for depth
local blurVignette = Instance.new("UIGradient")
blurVignette.Rotation = 0
blurVignette.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.15),
	NumberSequenceKeypoint.new(0.5, 0),
	NumberSequenceKeypoint.new(1, 0.15),
})
blurVignette.Parent = blurOverlay

local Library = {
	Version   = "5.0.0",
	Open      = true,
	ToggleKey = Enum.KeyCode.Insert,
	Flags     = {},
	Registry  = {},
	FlagRegistry = {},
	ThemeSignals = {},
	KeybindList = nil,
	Watermark   = nil,
	ScreenGui   = screenGui,
	SoundsEnabled = true,
	SearchQuery = "",
	SearchableControls = {},
	Connections = {},
	Unloaded = false,
	OnUnload = nil,

	Theme = {
		Accent1       = Color3.fromRGB(168, 219, 95),  -- Skeet Green
		Accent2       = Color3.fromRGB(94, 158, 219),  -- Skeet Cyan
		AccentDark    = Color3.fromRGB(105, 160, 50),
		MainTop       = Color3.fromRGB(32, 32, 38),
		MainBottom    = Color3.fromRGB(18, 18, 22),
		GroupTop      = Color3.fromRGB(28, 28, 34),
		GroupBottom   = Color3.fromRGB(20, 20, 24),
		ControlTop    = Color3.fromRGB(42, 42, 48),
		ControlBottom = Color3.fromRGB(28, 28, 32),
		ControlHover  = Color3.fromRGB(54, 54, 62),
		OuterBorder   = Color3.fromRGB(0, 0, 0),
		MidBorder     = Color3.fromRGB(58, 58, 68),
		Text          = Color3.fromRGB(240, 240, 248),
		TextDim       = Color3.fromRGB(165, 165, 180),
		TextDark      = Color3.fromRGB(105, 105, 120),
		Risky         = Color3.fromRGB(245, 85, 85),
		RiskyDark     = Color3.fromRGB(180, 50, 50),
		Font          = Enum.Font.GothamMedium,
		FontBold      = Enum.Font.GothamBold,
		FontSize      = 12,
	},

	Icons = {
		Target    = "rbxassetid://10734977012",
		Crosshair = "rbxassetid://10709818534",
		Eye       = "rbxassetid://10723346959",
		Users     = "rbxassetid://10747373426",
		User      = "rbxassetid://10747373176",
		Shield    = "rbxassetid://10734951847",
		Sliders   = "rbxassetid://10734963400",
		Settings  = "rbxassetid://10734950309",
		Palette   = "rbxassetid://10734910430",
		Save      = "rbxassetid://10734941499",
		Trash     = "rbxassetid://10747362241",
		Zap       = "rbxassetid://10723376114",
		Skull     = "rbxassetid://10734962068",
		Swords    = "rbxassetid://10734975692",
		Check     = "rbxassetid://10709790644",
		Chevron   = "rbxassetid://10709790948",
		Search    = "rbxassetid://10734943763",
		Info      = "rbxassetid://10723415903",
		Alert     = "rbxassetid://10734950020",
		Key       = "rbxassetid://10709791437",
		Edit      = "rbxassetid://10734944444",
		Copy      = "rbxassetid://10709790757",
		Refresh   = "rbxassetid://10734942548",
		Close     = "rbxassetid://10709791108",
		Layers    = "rbxassetid://10723387563",
		Folder    = "rbxassetid://10723387693",
	}
}

--============================================================================--
-- UTILITIES & THEME REGISTRY
--============================================================================--
local Util = {}

function Util.Create(class, props, children)
	local inst = Instance.new(class)
	for k, v in pairs(props or {}) do
		if k ~= "Parent" then inst[k] = v end
	end
	for _, child in ipairs(children or {}) do child.Parent = inst end
	if props and props.Parent then inst.Parent = props.Parent end
	return inst
end
local New = Util.Create

function Util.RegisterTheme(inst, propName, themeKey)
	if not Library.Registry[themeKey] then
		Library.Registry[themeKey] = {}
	end
	table.insert(Library.Registry[themeKey], { Instance = inst, Property = propName })
	return inst
end

-- Registers a component under its flag so SaveManager can push values back via :Set()
function Util.RegisterFlag(flag, component)
	if flag and component and component.Set then
		Library.FlagRegistry[flag] = component
	end
	return component
end

function Util.Tween(inst, dur, props, style, dir)
	local t = TweenService:Create(inst, TweenInfo.new(dur or 0.15, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

function Util.CreateHardBorder(parent, size, pos, bgTop, bgBottom, isMainWin)
	local outer = New("Frame", {
		Size = size or UDim2.fromScale(1, 1),
		Position = pos or UDim2.fromScale(0, 0),
		BackgroundColor3 = Library.Theme.OuterBorder,
		BorderSizePixel = 0,
		Parent = parent,
	})
	Util.RegisterTheme(outer, "BackgroundColor3", "OutlineColor")

	local mid = New("Frame", {
		Size = UDim2.new(1, -2, 1, -2),
		Position = UDim2.fromOffset(1, 1),
		BackgroundColor3 = Library.Theme.MidBorder,
		BorderSizePixel = 0,
		Parent = outer,
	})
	Util.RegisterTheme(mid, "BackgroundColor3", "MidBorder")

	local inner = New("Frame", {
		Size = UDim2.new(1, -2, 1, -2),
		Position = UDim2.fromOffset(1, 1),
		BackgroundColor3 = bgTop or (isMainWin and Library.Theme.MainTop or Library.Theme.GroupTop),
		BorderSizePixel = 0,
		ClipsDescendants = false,
		Parent = mid,
	})

	if isMainWin then
		Util.RegisterTheme(inner, "BackgroundColor3", "BackgroundColor")
	else
		Util.RegisterTheme(inner, "BackgroundColor3", "MainColor")
	end

	-- Subtle dark shading gradient that scales with dynamic theme colors
	local shade = New("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(0.15, Color3.fromRGB(240, 240, 240)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(215, 215, 215)),
			ColorSequenceKeypoint.new(0.85, Color3.fromRGB(195, 195, 195)),
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(175, 175, 175)),
		}),
		Parent = inner,
	})

	return outer, inner
end

function Util.AddSkeetGradientBar(parent, height)
	local bar = New("Frame", {
		Size = UDim2.new(1, 0, 0, height or 2),
		Position = UDim2.fromOffset(0, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		ZIndex = 10,
		ClipsDescendants = false,
		Parent = parent,
	})
	New("UICorner", { CornerRadius = UDim.new(0, height or 2), Parent = bar })

	local grad = New("UIGradient", {
		Rotation = 0,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.00, Color3.fromRGB(54, 163, 247)),
			ColorSequenceKeypoint.new(0.20, Color3.fromRGB(98, 216, 247)),
			ColorSequenceKeypoint.new(0.40, Color3.fromRGB(168, 219, 95)),
			ColorSequenceKeypoint.new(0.60, Color3.fromRGB(247, 184, 92)),
			ColorSequenceKeypoint.new(0.80, Color3.fromRGB(247, 104, 181)),
			ColorSequenceKeypoint.new(1.00, Color3.fromRGB(184, 119, 247)),
		}),
		Parent = bar,
	})
	New("UIGradient", {
		Rotation = 0,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.3),
			NumberSequenceKeypoint.new(0.5, 0),
			NumberSequenceKeypoint.new(1, 0.3),
		}),
		Parent = bar,
	})

	return bar
end

--============================================================================--
-- SOUND EFFECTS SYSTEM
--============================================================================--
local SoundCache = {}

function Util.PlaySound(soundType)
	if not Library.SoundsEnabled then return end

	local soundId = ""
	local volume = 0.3

	if soundType == "hover" then
		soundId = "rbxassetid://6895079853" -- Subtle hover sound
		volume = 0.15
	elseif soundType == "click" then
		soundId = "rbxassetid://6895080306" -- Click sound
		volume = 0.25
	elseif soundType == "toggle" then
		soundId = "rbxassetid://6895081020" -- Toggle sound
		volume = 0.2
	elseif soundType == "open" then
		soundId = "rbxassetid://6895081807" -- Menu open sound
		volume = 0.3
	elseif soundType == "close" then
		soundId = "rbxassetid://6895082448" -- Menu close sound
		volume = 0.3
	end

	if soundId == "" then return end

	local sound = SoundCache[soundType]
	if not sound then
		sound = Instance.new("Sound")
		sound.SoundId = soundId
		sound.Volume = volume
		sound.Parent = SoundService
		SoundCache[soundType] = sound
	end

	if not sound.IsPlaying then
		sound:Play()
	end
end

--============================================================================--
-- WATERMARK HUD
--============================================================================--
function Library:CreateWatermark(customTitle)
	local title = customTitle or "skeetware.cc"
	local wmOuter, wmInner = Util.CreateHardBorder(screenGui, UDim2.fromOffset(300, 24), UDim2.fromOffset(20, 20), Library.Theme.MainTop, Library.Theme.MainBottom, true)
	wmOuter.ZIndex = 50
	Util.AddSkeetGradientBar(wmInner, 2)

	local wmIcon = New("ImageLabel", {
		Size = UDim2.fromOffset(13, 13),
		Position = UDim2.fromOffset(6, 5),
		BackgroundTransparency = 1,
		Image = Library.Icons.Shield,
		ImageColor3 = Library.Theme.Accent1,
		Parent = wmInner,
	})
	Util.RegisterTheme(wmIcon, "ImageColor3", "AccentColor")

	local wmLabel = New("TextLabel", {
		Size = UDim2.new(1, -26, 1, -2),
		Position = UDim2.fromOffset(24, 2),
		BackgroundTransparency = 1,
		Font = Library.Theme.Font,
		TextSize = Library.Theme.FontSize - 1,
		TextColor3 = Library.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = title .. " | 60 fps | 14 ms",
		Parent = wmInner,
	})
	Util.RegisterTheme(wmLabel, "TextColor3", "FontColor")

	local fpsCount = 0
	local lastFpsUpdate = tick()
	table.insert(Library.Connections, RunService.RenderStepped:Connect(function()
		if Library.Unloaded or not wmLabel.Parent then return end
		fpsCount = fpsCount + 1
		if tick() - lastFpsUpdate >= 0.5 then
			local fps = math.floor(fpsCount / (tick() - lastFpsUpdate))
			local ping = math.floor((LocalPlayer and LocalPlayer:GetNetworkPing() or 0.015) * 1000)
			wmLabel.Text = string.format("%s | %s | %d fps | %d ms", title, LocalPlayer and LocalPlayer.DisplayName or "User", fps, ping)
			fpsCount = 0
			lastFpsUpdate = tick()
		end
	end))

	Library.Watermark = wmOuter
	return wmOuter
end

--============================================================================--
-- KEYBINDS LIST HUD
--============================================================================--
function Library:CreateKeybindList()
	local kbOuter, kbInner = Util.CreateHardBorder(screenGui, UDim2.fromOffset(190, 26), UDim2.fromOffset(20, 56), Library.Theme.MainTop, Library.Theme.MainBottom, true)
	kbOuter.ZIndex = 50
	Util.AddSkeetGradientBar(kbInner, 2)

	local header = New("TextLabel", {
		Size = UDim2.new(1, 0, 0, 22),
		Position = UDim2.fromOffset(0, 2),
		BackgroundTransparency = 1,
		Font = Library.Theme.FontBold,
		TextSize = Library.Theme.FontSize,
		TextColor3 = Library.Theme.Text,
		Text = "Keybinds",
		Parent = kbInner,
	})
	Util.RegisterTheme(header, "TextColor3", "FontColor")

	local listContainer = New("Frame", {
		Size = UDim2.new(1, -12, 0, 0),
		Position = UDim2.fromOffset(6, 24),
		BackgroundTransparency = 1,
		Parent = kbInner,
	})
	New("UIListLayout", {
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = listContainer,
	})

	local binds = {}
	local function updateSize()
		local count = 0
		for _ in pairs(binds) do count = count + 1 end
		local h = count > 0 and (28 + (count * 18)) or 26
		Util.Tween(kbOuter, 0.15, { Size = UDim2.fromOffset(190, h) })
	end

	local KeybindHUD = {}
	function KeybindHUD:SetBind(name, key, mode, active)
		if binds[name] then
			if not active then
				binds[name]:Destroy()
				binds[name] = nil
				updateSize()
				return
			end
			local valLbl = binds[name]:FindFirstChild("Val")
			if valLbl then
				valLbl.Text = string.format("[%s] (%s)", key, mode)
			end
		else
			if not active then return end
			local row = New("Frame", {
				Size = UDim2.new(1, 0, 0, 16),
				BackgroundTransparency = 1,
				Parent = listContainer,
			})
			local nameLbl = New("TextLabel", {
				Size = UDim2.new(0.55, 0, 1, 0),
				BackgroundTransparency = 1,
				Font = Library.Theme.Font,
				TextSize = Library.Theme.FontSize - 1,
				TextColor3 = Library.Theme.TextDim,
				TextXAlignment = Enum.TextXAlignment.Left,
				Text = name,
				Parent = row,
			})
			local valLbl = New("TextLabel", {
				Name = "Val",
				Size = UDim2.new(0.45, 0, 1, 0),
				Position = UDim2.new(0.55, 0, 0, 0),
				BackgroundTransparency = 1,
				Font = Library.Theme.Font,
				TextSize = Library.Theme.FontSize - 1,
				TextColor3 = Library.Theme.Accent1,
				TextXAlignment = Enum.TextXAlignment.Right,
				Text = string.format("[%s] (%s)", key, mode),
				Parent = row,
			})
			Util.RegisterTheme(valLbl, "TextColor3", "AccentColor")

			binds[name] = row
			updateSize()
		end
	end

	local dragging, dragStart, startPos
	header.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = kbOuter.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			kbOuter.Position = UDim2.fromOffset(startPos.X.Offset + delta.X, startPos.Y.Offset + delta.Y)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end)

	Library.KeybindList = KeybindHUD
	return KeybindHUD
end

--============================================================================--
-- NOTIFICATIONS
--============================================================================--
local notifHolder = New("Frame", {
	Name = "NotifHolder",
	Size = UDim2.new(0, 260, 1, -40),
	Position = UDim2.new(1, -280, 0, 20),
	BackgroundTransparency = 1,
	ZIndex = 90,
	Parent = screenGui,
})
New("UIListLayout", {
	Padding = UDim.new(0, 8),
	VerticalAlignment = Enum.VerticalAlignment.Bottom,
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = notifHolder,
})

function Library:Notify(cfg)
	local title    = cfg.Title or "Notification"
	local text     = cfg.Text or ""
	local dur      = cfg.Duration or 3.5
	local nType    = cfg.Type or "Info"
	local iconId   = cfg.Icon or (nType == "Success" and Library.Icons.Check or (nType == "Warning" and Library.Icons.Alert or Library.Icons.Info))

	local notifOuter, notifInner = Util.CreateHardBorder(notifHolder, UDim2.fromOffset(270, 56), nil, Library.Theme.MainTop, Library.Theme.MainBottom, true)
	notifOuter.ClipsDescendants = true
	notifOuter.Position = UDim2.fromOffset(60, 0)
	Util.AddSkeetGradientBar(notifInner, 2)

	local iconBadge = New("ImageLabel", {
		Size = UDim2.fromOffset(16, 16),
		Position = UDim2.fromOffset(8, 7),
		BackgroundTransparency = 1,
		Image = iconId,
		ImageColor3 = (nType == "Warning" or nType == "Error") and Library.Theme.Risky or Library.Theme.Accent1,
		Parent = notifInner,
	})
	if nType ~= "Warning" and nType ~= "Error" then
		Util.RegisterTheme(iconBadge, "ImageColor3", "AccentColor")
	end

	local titleLbl = New("TextLabel", {
		Size = UDim2.new(1, -34, 0, 16),
		Position = UDim2.fromOffset(28, 6),
		BackgroundTransparency = 1,
		Font = Library.Theme.FontBold,
		TextSize = Library.Theme.FontSize,
		TextColor3 = (nType == "Warning" or nType == "Error") and Library.Theme.Risky or Library.Theme.Accent1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = title,
		Parent = notifInner,
	})
	if nType ~= "Warning" and nType ~= "Error" then
		Util.RegisterTheme(titleLbl, "TextColor3", "AccentColor")
	end

	local textLbl = New("TextLabel", {
		Size = UDim2.new(1, -16, 0, 24),
		Position = UDim2.fromOffset(8, 24),
		BackgroundTransparency = 1,
		Font = Library.Theme.Font,
		TextSize = Library.Theme.FontSize - 1,
		TextColor3 = Library.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextWrapped = true,
		Text = text,
		Parent = notifInner,
	})
	Util.RegisterTheme(textLbl, "TextColor3", "FontColor")

	local timerBar = New("Frame", {
		Size = UDim2.new(1, 0, 0, 2),
		Position = UDim2.new(0, 0, 1, -2),
		BackgroundColor3 = (nType == "Warning" or nType == "Error") and Library.Theme.Risky or Library.Theme.Accent1,
		BorderSizePixel = 0,
		Parent = notifInner,
	})
	if nType ~= "Warning" and nType ~= "Error" then
		Util.RegisterTheme(timerBar, "BackgroundColor3", "AccentColor")
	end

	-- Slide-in animation
	Util.Tween(notifOuter, 0.22, { Position = UDim2.fromOffset(0, 0) }, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	Util.Tween(timerBar, dur, { Size = UDim2.new(0, 0, 0, 2) }, Enum.EasingStyle.Linear)

	task.delay(dur, function()
		local out = Util.Tween(notifOuter, 0.2, { Position = UDim2.fromOffset(120, 0) }, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
		out.Completed:Connect(function() notifOuter:Destroy() end)
	end)
end

--============================================================================--
-- CREATE MAIN WINDOW
--============================================================================--
function Library:CreateWindow(cfg)
	cfg = cfg or {}
	local title   = cfg.Title or "skeetware.cc"
	local winSize = cfg.Size or UDim2.fromOffset(720, 520)

	local winOuter, winInner = Util.CreateHardBorder(screenGui, winSize, UDim2.fromScale(0.5, 0.5), Library.Theme.MainTop, Library.Theme.MainBottom, true)
	winOuter.AnchorPoint = Vector2.new(0.5, 0.5)
	winOuter.ZIndex = 10

	-- Full-bleed ambient wash (no boxed overlay)
	local animBg = New("Frame", {
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromOffset(0, 0),
		BackgroundColor3 = Color3.fromRGB(22, 22, 26),
		BorderSizePixel = 0,
		ZIndex = 1,
		ClipsDescendants = true,
		Parent = winInner,
	})

	local bgGradient = New("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(30, 30, 36)),
			ColorSequenceKeypoint.new(0.45, Color3.fromRGB(22, 22, 26)),
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(14, 14, 17)),
		}),
		Parent = animBg,
	})

	Util.AddSkeetGradientBar(winInner, 3)
	local sidebar = New("Frame", {
		Size = UDim2.new(0, 140, 1, -6),
		Position = UDim2.fromOffset(3, 3),
		BackgroundColor3 = Library.Theme.GroupTop,
		BorderSizePixel = 0,
		ZIndex = 10,
		ClipsDescendants = true,
		Parent = winInner,
	})
	Util.RegisterTheme(sidebar, "BackgroundColor3", "MainColor")

	-- Black sidebar with a light vertical fade (no orbs / rounded blobs)
	New("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(32, 32, 36)),
			ColorSequenceKeypoint.new(0.35, Color3.fromRGB(24, 24, 28)),
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(16, 16, 18)),
		}),
		Parent = sidebar,
	})

	local sidebarFade = New("Frame", {
		Size = UDim2.new(1, 0, 0, 72),
		Position = UDim2.fromOffset(0, 0),
		BackgroundColor3 = Library.Theme.Accent1,
		BackgroundTransparency = 0.94,
		BorderSizePixel = 0,
		ZIndex = 10,
		Parent = sidebar,
	})
	Util.RegisterTheme(sidebarFade, "BackgroundColor3", "AccentColor")
	New("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = sidebarFade,
	})

	-- Sidebar right edge separator with gradient fade
	local sidebarEdge = New("Frame", {
		Size = UDim2.new(0, 1, 1, 0),
		Position = UDim2.new(1, -1, 0, 0),
		BackgroundColor3 = Library.Theme.MidBorder,
		BorderSizePixel = 0,
		ZIndex = 11,
		Parent = sidebar,
	})
	New("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.3),
			NumberSequenceKeypoint.new(0.5, 0),
			NumberSequenceKeypoint.new(1, 0.5),
		}),
		Parent = sidebarEdge,
	})

	-- Branding section
	local brandingSection = New("Frame", {
		Size = UDim2.new(1, 0, 0, 60),
		Position = UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1,
		ZIndex = 11,
		Parent = sidebar,
	})

	local brandIcon = New("ImageLabel", {
		Size = UDim2.fromOffset(32, 32),
		Position = UDim2.fromOffset(14, 14),
		BackgroundTransparency = 1,
		Image = Library.Icons.Shield,
		ImageColor3 = Library.Theme.Accent1,
		ZIndex = 12,
		Parent = brandingSection,
	})
	Util.RegisterTheme(brandIcon, "ImageColor3", "AccentColor")

	New("TextLabel", {
		Size = UDim2.new(1, -56, 0, 20),
		Position = UDim2.fromOffset(52, 20),
		BackgroundTransparency = 1,
		Font = Library.Theme.FontBold,
		TextSize = Library.Theme.FontSize + 2,
		TextColor3 = Library.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "SKEET",
		ZIndex = 12,
		Parent = brandingSection,
	})

	New("TextLabel", {
		Size = UDim2.new(1, -56, 0, 16),
		Position = UDim2.fromOffset(52, 40),
		BackgroundTransparency = 1,
		Font = Library.Theme.Font,
		TextSize = Library.Theme.FontSize - 1,
		TextColor3 = Library.Theme.TextDim,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "WARE.CC",
		ZIndex = 12,
		Parent = brandingSection,
	})

	-- Tab list in sidebar
	local sidebarTabList = New("Frame", {
		Size = UDim2.new(1, 0, 1, -70),
		Position = UDim2.fromOffset(0, 65),
		BackgroundTransparency = 1,
		ZIndex = 11,
		Parent = sidebar,
	})
	New("UIListLayout", {
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = sidebarTabList,
	})

	local titleBar = New("Frame", {
		Size = UDim2.new(1, -150, 0, 32),
		Position = UDim2.fromOffset(147, 3),
		BackgroundTransparency = 1,
		ZIndex = 10,
		Parent = winInner,
	})

	local titleLabel = New("TextLabel", {
		Size = UDim2.new(0.4, 0, 1, 0),
		Position = UDim2.fromOffset(10, 0),
		BackgroundTransparency = 1,
		Font = Library.Theme.FontBold,
		TextSize = Library.Theme.FontSize + 1,
		TextColor3 = Library.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = string.upper(title),
		ZIndex = 11,
		Parent = titleBar,
	})
	Util.RegisterTheme(titleLabel, "TextColor3", "FontColor")

	-- Integrated sleek search box on the right of title bar
	local searchOuter, searchInner = Util.CreateHardBorder(titleBar, UDim2.new(0, 175, 0, 22), UDim2.new(1, -185, 0.5, -11), Library.Theme.ControlTop, Library.Theme.ControlBottom)
	searchOuter.ZIndex = 11

	local searchIcon = New("ImageLabel", {
		Size = UDim2.fromOffset(12, 12),
		Position = UDim2.fromOffset(6, 5),
		BackgroundTransparency = 1,
		Image = Library.Icons.Search,
		ImageColor3 = Library.Theme.TextDim,
		ZIndex = 12,
		Parent = searchInner,
	})

	local searchInput = New("TextBox", {
		Size = UDim2.new(1, -26, 1, 0),
		Position = UDim2.fromOffset(22, 0),
		BackgroundTransparency = 1,
		Font = Library.Theme.Font,
		TextSize = Library.Theme.FontSize - 1,
		TextColor3 = Library.Theme.Text,
		PlaceholderText = "Search features...",
		PlaceholderColor3 = Library.Theme.TextDark,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		ZIndex = 12,
		Parent = searchInner,
	})

	searchInput:GetPropertyChangedSignal("Text"):Connect(function()
		Library.SearchQuery = string.lower(searchInput.Text)
		for _, control in ipairs(Library.SearchableControls) do
			if control.Row and control.SearchText then
				local matches = string.find(control.SearchText, Library.SearchQuery, 1, true) ~= nil
				control.Row.Visible = matches or Library.SearchQuery == ""
			end
		end
	end)

	New("Frame", {
		Size = UDim2.new(1, -147, 0, 1),
		Position = UDim2.fromOffset(147, 35),
		BackgroundColor3 = Library.Theme.MidBorder,
		BorderSizePixel = 0,
		ZIndex = 10,
		Parent = winInner,
	})

	-- Window dragging support from titleBar & branding
	do
		local dragging, dragStart, startPos
		local function startDrag(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = true
				dragStart = input.Position
				startPos = winOuter.Position
			end
		end
		titleBar.InputBegan:Connect(startDrag)
		brandingSection.InputBegan:Connect(startDrag)

		UserInputService.InputChanged:Connect(function(input)
			if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
				local delta = input.Position - dragStart
				winOuter.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
			end
		end)
		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
		end)
	end

	table.insert(Library.Connections, UserInputService.InputBegan:Connect(function(input, gp)
		if Library.Unloaded then return end
		if not gp and input.KeyCode == Library.ToggleKey then
			Library.Open = not Library.Open
			if Library.Open then
				-- Show blur overlay
				blurOverlay.Visible = true
				blurOverlay.BackgroundTransparency = 1
				Util.Tween(blurOverlay, 0.25, { BackgroundTransparency = 0.55 }, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
				if blurEffect then
					blurEffect.Size = 0
					Util.Tween(blurEffect, 0.3, { Size = 14 }, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
				end

				winOuter.Visible = true
				winOuter.Size = UDim2.fromOffset(winSize.X.Offset - 18, winSize.Y.Offset - 18)
				Util.Tween(winOuter, 0.2, { Size = winSize }, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
				Util.PlaySound("open")
			else
				-- Hide blur overlay
				Util.Tween(blurOverlay, 0.2, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
				if blurEffect then
					Util.Tween(blurEffect, 0.25, { Size = 0 }, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
				end

				local t = Util.Tween(winOuter, 0.15, { Size = UDim2.fromOffset(winSize.X.Offset - 18, winSize.Y.Offset - 18) }, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
				t.Completed:Connect(function()
					winOuter.Visible = false
					winOuter.Size = winSize
					blurOverlay.Visible = false
				end)
				Util.PlaySound("close")
			end
		end
	end))

	-- Single dedicated contentHolder strictly placed right of the sidebar
	local contentHolder = New("Frame", {
		Size = UDim2.new(1, -155, 1, -62),
		Position = UDim2.fromOffset(148, 38),
		BackgroundTransparency = 1,
		ClipsDescendants = false,
		ZIndex = 10,
		Parent = winInner,
	})

	-- Soft top wash so the content area isn't a hard rectangle of color
	local contentAccentGlow = New("Frame", {
		Size = UDim2.new(1, 0, 0, 90),
		Position = UDim2.fromOffset(0, 0),
		BackgroundColor3 = Library.Theme.Accent1,
		BackgroundTransparency = 0.97,
		BorderSizePixel = 0,
		ZIndex = 9,
		Parent = contentHolder,
	})
	Util.RegisterTheme(contentAccentGlow, "BackgroundColor3", "AccentColor")
	New("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.55, 0.55),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = contentAccentGlow,
	})

	-- Sleek authentic bottom footer status bar
	local footerBar = New("Frame", {
		Size = UDim2.new(1, -6, 0, 20),
		Position = UDim2.new(0, 3, 1, -23),
		BackgroundColor3 = Library.Theme.GroupBottom,
		BorderSizePixel = 0,
		ZIndex = 10,
		ClipsDescendants = true,
		Parent = winInner,
	})
	Util.RegisterTheme(footerBar, "BackgroundColor3", "BackgroundColor")

	-- Footer multi-tone gradient for depth
	New("UIGradient", {
		Rotation = 0,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(20, 20, 24)),
			ColorSequenceKeypoint.new(0.3, Color3.fromRGB(24, 24, 28)),
			ColorSequenceKeypoint.new(0.7, Color3.fromRGB(22, 22, 26)),
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(18, 18, 21)),
		}),
		Parent = footerBar,
	})

	-- Subtle accent line on footer left
	local footerAccentLine = New("Frame", {
		Size = UDim2.new(0.3, 0, 0, 1),
		Position = UDim2.fromOffset(0, 0),
		BackgroundColor3 = Library.Theme.Accent1,
		BackgroundTransparency = 0.8,
		BorderSizePixel = 0,
		ZIndex = 12,
		Parent = footerBar,
	})
	Util.RegisterTheme(footerAccentLine, "BackgroundColor3", "AccentColor")
	New("UIGradient", {
		Rotation = 0,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = footerAccentLine,
	})

	New("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.fromOffset(0, 0),
		BackgroundColor3 = Library.Theme.MidBorder,
		BorderSizePixel = 0,
		ZIndex = 11,
		Parent = footerBar,
	})

	local footerUser = New("TextLabel", {
		Size = UDim2.new(0.5, -10, 1, 0),
		Position = UDim2.fromOffset(10, 0),
		BackgroundTransparency = 1,
		Font = Library.Theme.Font,
		TextSize = Library.Theme.FontSize - 2,
		TextColor3 = Library.Theme.TextDim,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = string.format("skeetware | %s", LocalPlayer and LocalPlayer.DisplayName or "User"),
		ZIndex = 11,
		Parent = footerBar,
	})

	local footerStats = New("TextLabel", {
		Size = UDim2.new(0.5, -10, 1, 0),
		Position = UDim2.new(0.5, 0, 0, 0),
		BackgroundTransparency = 1,
		Font = Library.Theme.Font,
		TextSize = Library.Theme.FontSize - 2,
		TextColor3 = Library.Theme.TextDim,
		TextXAlignment = Enum.TextXAlignment.Right,
		Text = "60 fps | 14 ms | [INSERT]",
		ZIndex = 11,
		Parent = footerBar,
	})

	local fFpsCount = 0
	local fLastUpdate = tick()
	RunService.RenderStepped:Connect(function()
		fFpsCount = fFpsCount + 1
		if tick() - fLastUpdate >= 0.5 then
			local curFps = math.floor(fFpsCount / (tick() - fLastUpdate))
			local curPing = math.floor((LocalPlayer and LocalPlayer:GetNetworkPing() or 0.015) * 1000)
			footerStats.Text = string.format("%d fps | %d ms | [INSERT]", curFps, curPing)
			fFpsCount = 0
			fLastUpdate = tick()
		end
	end)

	local Window = { Tabs = {} }

	function Window:AddTab(tabName, iconAsset)
		local tabBtnOuter, tabBtnInner = Util.CreateHardBorder(sidebarTabList, UDim2.new(1, -8, 0, 32), nil, Library.Theme.ControlTop, Library.Theme.ControlBottom)

		local activePill = New("Frame", {
			Size = UDim2.new(0, 3, 0, 0),
			Position = UDim2.new(0, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = Library.Theme.Accent1,
			BorderSizePixel = 0,
			ZIndex = 14,
			Parent = tabBtnInner,
		})
		Util.RegisterTheme(activePill, "BackgroundColor3", "AccentColor")

		local hasIcon = (iconAsset ~= nil and typeof(iconAsset) == "string")
		local tabIcon = nil

		if hasIcon then
			tabIcon = New("ImageLabel", {
				Size = UDim2.fromOffset(16, 16),
				Position = UDim2.new(0, 8, 0.5, -8),
				BackgroundTransparency = 1,
				Image = iconAsset,
				ImageColor3 = Library.Theme.TextDim,
				ZIndex = 13,
				Parent = tabBtnInner,
			})
		end

		local tabLabel = New("TextLabel", {
			Size = UDim2.new(1, hasIcon and -32 or 0, 1, 0),
			Position = UDim2.fromOffset(hasIcon and 30 or 8, 0),
			BackgroundTransparency = 1,
			Font = Library.Theme.FontBold,
			TextSize = Library.Theme.FontSize,
			TextColor3 = Library.Theme.TextDim,
			Text = string.upper(tabName or "TAB"),
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 13,
			Parent = tabBtnInner,
		})
		Util.RegisterTheme(tabLabel, "TextColor3", "FontColor")

		local tabPage = New("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Visible = false,
			Parent = contentHolder,
		})

		local leftCol = New("ScrollingFrame", {
			Size = UDim2.new(0.5, -6, 1, 0),
			Position = UDim2.fromOffset(0, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = Library.Theme.Accent1,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			Selectable = false,
			ClipsDescendants = true,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Parent = tabPage,
		})
		Util.RegisterTheme(leftCol, "ScrollBarImageColor3", "AccentColor")
		New("UIListLayout", {
			Padding = UDim.new(0, 14),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = leftCol,
		})
		New("UIPadding", {
			PaddingTop = UDim.new(0, 10),
			PaddingBottom = UDim.new(0, 10),
			PaddingLeft = UDim.new(0, 2),
			PaddingRight = UDim.new(0, 4),
			Parent = leftCol,
		})

		local rightCol = New("ScrollingFrame", {
			Size = UDim2.new(0.5, -6, 1, 0),
			Position = UDim2.new(0.5, 6, 0, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = Library.Theme.Accent1,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			Selectable = false,
			ClipsDescendants = true,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Parent = tabPage,
		})
		Util.RegisterTheme(rightCol, "ScrollBarImageColor3", "AccentColor")
		New("UIListLayout", {
			Padding = UDim.new(0, 14),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = rightCol,
		})
		New("UIPadding", {
			PaddingTop = UDim.new(0, 10),
			PaddingBottom = UDim.new(0, 10),
			PaddingLeft = UDim.new(0, 2),
			PaddingRight = UDim.new(0, 4),
			Parent = rightCol,
		})

		local Tab = { Page = tabPage, Left = leftCol, Right = rightCol, SubTabs = {} }

		function Tab:AddSubTab(subTabName)
			if not self.SubTabBar then
				leftCol.Size = UDim2.new(0.5, -6, 1, -28)
				leftCol.Position = UDim2.fromOffset(0, 28)
				rightCol.Size = UDim2.new(0.5, -6, 1, -28)
				rightCol.Position = UDim2.new(0.5, 6, 0, 28)

				local subBar = New("Frame", {
					Size = UDim2.new(1, 0, 0, 22),
					Position = UDim2.fromOffset(0, 0),
					BackgroundTransparency = 1,
					Parent = tabPage,
				})
				New("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					Padding = UDim.new(0, 4),
					SortOrder = Enum.SortOrder.LayoutOrder,
					Parent = subBar,
				})
				self.SubTabBar = subBar
			end

			local subLeftCol = New("ScrollingFrame", {
				Size = UDim2.new(0.5, -6, 1, -28),
				Position = UDim2.fromOffset(0, 28),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ScrollBarThickness = 3,
				ScrollBarImageColor3 = Library.Theme.Accent1,
				ScrollingDirection = Enum.ScrollingDirection.Y,
				Selectable = false,
				ClipsDescendants = true,
				CanvasSize = UDim2.new(0, 0, 0, 0),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				Visible = false,
				Parent = tabPage,
			})
			Util.RegisterTheme(subLeftCol, "ScrollBarImageColor3", "AccentColor")
			New("UIListLayout", {
				Padding = UDim.new(0, 14),
				SortOrder = Enum.SortOrder.LayoutOrder,
				Parent = subLeftCol,
			})
			New("UIPadding", {
				PaddingTop = UDim.new(0, 10),
				PaddingBottom = UDim.new(0, 10),
				PaddingLeft = UDim.new(0, 2),
				PaddingRight = UDim.new(0, 4),
				Parent = subLeftCol,
			})

			local subRightCol = New("ScrollingFrame", {
				Size = UDim2.new(0.5, -6, 1, -28),
				Position = UDim2.new(0.5, 6, 0, 28),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ScrollBarThickness = 3,
				ScrollBarImageColor3 = Library.Theme.Accent1,
				ScrollingDirection = Enum.ScrollingDirection.Y,
				Selectable = false,
				ClipsDescendants = true,
				CanvasSize = UDim2.new(0, 0, 0, 0),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				Visible = false,
				Parent = tabPage,
			})
			Util.RegisterTheme(subRightCol, "ScrollBarImageColor3", "AccentColor")
			New("UIListLayout", {
				Padding = UDim.new(0, 14),
				SortOrder = Enum.SortOrder.LayoutOrder,
				Parent = subRightCol,
			})
			New("UIPadding", {
				PaddingTop = UDim.new(0, 10),
				PaddingBottom = UDim.new(0, 10),
				PaddingLeft = UDim.new(0, 2),
				PaddingRight = UDim.new(0, 4),
				Parent = subRightCol,
			})

			leftCol.Visible = false
			rightCol.Visible = false

			local subBtnOuter, subBtnInner = Util.CreateHardBorder(self.SubTabBar, UDim2.fromOffset(80, 22), nil, Library.Theme.ControlTop, Library.Theme.ControlBottom)

			local subLine = New("Frame", {
				Size = UDim2.new(1, 0, 0, 2),
				Position = UDim2.new(0, 0, 1, -2),
				BackgroundColor3 = Library.Theme.Accent1,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ZIndex = 14,
				Parent = subBtnInner,
			})
			Util.RegisterTheme(subLine, "BackgroundColor3", "AccentColor")

			local subLabel = New("TextLabel", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Font = Library.Theme.FontBold,
				TextSize = Library.Theme.FontSize - 1,
				TextColor3 = Library.Theme.TextDim,
				Text = string.upper(subTabName or "SUBTAB"),
				ZIndex = 13,
				Parent = subBtnInner,
			})

			local SubTab = {
				Btn = subBtnOuter,
				Inner = subBtnInner,
				Label = subLabel,
				Line = subLine,
				Left = subLeftCol,
				Right = subRightCol,
			}

			local function selectSubTab()
				for _, other in ipairs(self.SubTabs) do
					other.Left.Visible = false
					other.Right.Visible = false
					Util.Tween(other.Label, 0.12, { TextColor3 = Library.Theme.TextDim })
					Util.Tween(other.Line, 0.12, { BackgroundTransparency = 1 })
					Util.Tween(other.Inner, 0.12, { BackgroundColor3 = Library.Theme.ControlTop })
				end
				SubTab.Left.Position = UDim2.fromOffset(0, 32)
				SubTab.Right.Position = UDim2.new(0.5, 6, 0, 32)
				SubTab.Left.Visible = true
				SubTab.Right.Visible = true
				Util.Tween(subLabel, 0.14, { TextColor3 = Library.Theme.Accent1 })
				Util.Tween(subLine, 0.14, { BackgroundTransparency = 0 })
				Util.Tween(subBtnInner, 0.14, { BackgroundColor3 = Library.Theme.GroupTop })
				Util.Tween(SubTab.Left, 0.16, { Position = UDim2.fromOffset(0, 28) }, Enum.EasingStyle.Quart)
				Util.Tween(SubTab.Right, 0.16, { Position = UDim2.new(0.5, 6, 0, 28) }, Enum.EasingStyle.Quart)
			end

			subBtnInner.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					Util.PlaySound("click")
					selectSubTab()
				end
			end)

			table.insert(self.SubTabs, SubTab)
			if #self.SubTabs == 1 then
				selectSubTab()
			end

			function SubTab:AddGroupbox(gCfg)
				gCfg = gCfg or {}
				local side = (gCfg.Side and string.lower(gCfg.Side) == "right") and subRightCol or subLeftCol
				return Tab.CreateGroupbox(side, gCfg)
			end

			return SubTab
		end

		local function selectTab()
			for _, other in ipairs(Window.Tabs) do
				other.Page.Visible = false
				Util.Tween(other.Pill, 0.12, { Size = UDim2.new(0, 3, 0, 0) })
				Util.Tween(other.Label, 0.15, { TextColor3 = Library.Theme.TextDim })
				if other.Icon then Util.Tween(other.Icon, 0.15, { ImageColor3 = Library.Theme.TextDim }) end
				Util.Tween(other.Inner, 0.15, { BackgroundColor3 = Library.Theme.ControlTop })
			end
			tabPage.Position = UDim2.fromOffset(0, 6)
			tabPage.Visible = true
			Util.Tween(activePill, 0.18, { Size = UDim2.new(0, 3, 0.65, 0) }, Enum.EasingStyle.Quart)
			Util.Tween(tabLabel, 0.18, { TextColor3 = Library.Theme.Text })
			if tabIcon then Util.Tween(tabIcon, 0.18, { ImageColor3 = Library.Theme.Accent1 }) end
			Util.Tween(tabBtnInner, 0.18, { BackgroundColor3 = Library.Theme.GroupTop })
			Util.Tween(tabPage, 0.18, { Position = UDim2.fromOffset(0, 0) }, Enum.EasingStyle.Quart)
		end

		tabBtnInner.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				Util.PlaySound("click")
				selectTab()
			end
		end)

		tabBtnInner.MouseEnter:Connect(function()
			Util.PlaySound("hover")
			if not tabPage.Visible then
				Util.Tween(tabBtnInner, 0.1, { BackgroundColor3 = Library.Theme.ControlHover })
			end
		end)
		tabBtnInner.MouseLeave:Connect(function()
			if not tabPage.Visible then
				Util.Tween(tabBtnInner, 0.1, { BackgroundColor3 = Library.Theme.ControlTop })
			end
		end)

		Tab.Btn   = tabBtnOuter
		Tab.Inner = tabBtnInner
		Tab.Label = tabLabel
		Tab.Icon  = tabIcon
		Tab.Pill  = activePill
		table.insert(Window.Tabs, Tab)

		if #Window.Tabs == 1 then selectTab() end

		-- Helper function to generate groupbox inside any column
		function Tab.CreateGroupbox(parentCol, gCfg)
			gCfg = gCfg or {}
			local gTitle = gCfg.Title or "Group"

			local gbOuter, gbInner = Util.CreateHardBorder(parentCol, UDim2.new(1, 0, 0, 0), nil, Library.Theme.GroupTop, Library.Theme.GroupBottom)
			gbOuter.AutomaticSize = Enum.AutomaticSize.Y
			
			-- Add subtle rounded corners for modern aesthetic
			New("UICorner", { CornerRadius = UDim.new(0, 4), Parent = gbOuter })
			New("UICorner", { CornerRadius = UDim.new(0, 3), Parent = gbInner })
			
			-- Add subtle gradient overlay for depth
			local gbGradient = New("UIGradient", {
				Rotation = 135,
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 255, 255)),
					ColorSequenceKeypoint.new(0.5, Color3.fromRGB(240, 240, 245)),
					ColorSequenceKeypoint.new(1.0, Color3.fromRGB(220, 220, 230)),
				}),
				Parent = gbInner,
			})

			-- Clean Skeet-style header badge seamlessly breaking top border line
			local titleHold = New("Frame", {
				Size = UDim2.fromOffset(0, 15),
				AutomaticSize = Enum.AutomaticSize.X,
				Position = UDim2.fromOffset(10, -8),
				BackgroundColor3 = Library.Theme.MainTop,
				BorderSizePixel = 0,
				ZIndex = 8,
				Parent = gbOuter,
			})
			Util.RegisterTheme(titleHold, "BackgroundColor3", "BackgroundColor")
			New("UICorner", { CornerRadius = UDim.new(0, 3), Parent = titleHold })

			New("UIPadding", {
				PaddingLeft = UDim.new(0, 5),
				PaddingRight = UDim.new(0, 5),
				PaddingTop = UDim.new(0, 0),
				PaddingBottom = UDim.new(0, 0),
				Parent = titleHold,
			})

			local titleText = New("TextLabel", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Font = Library.Theme.FontBold,
				TextSize = Library.Theme.FontSize - 1,
				TextColor3 = Library.Theme.Text,
				Text = string.upper(gTitle),
				TextYAlignment = Enum.TextYAlignment.Center,
				ZIndex = 9,
				Parent = titleHold,
			})
			Util.RegisterTheme(titleText, "TextColor3", "FontColor")

			local elemList = New("Frame", {
				Size = UDim2.new(1, -16, 1, -16),
				Position = UDim2.fromOffset(8, 12),
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.Y,
				Parent = gbInner,
			})
			New("UIListLayout", {
				Padding = UDim.new(0, 6),
				SortOrder = Enum.SortOrder.LayoutOrder,
				Parent = elemList,
			})
			New("UIPadding", {
				PaddingBottom = UDim.new(0, 8),
				Parent = elemList,
			})

			local Group = {}

			-- COLORPICKER (100% NATIVE SV + HUE GRADIENTS)
			local function createColorPicker(parentHold, defaultCol, flag, callback)
				local curColor = defaultCol or Library.Theme.Accent1
				local curH, curS, curV = curColor:ToHSV()

				local cpOuter = New("TextButton", {
					Size = UDim2.fromOffset(28, 14),
					BackgroundColor3 = Library.Theme.OuterBorder,
					BorderSizePixel = 0,
					AutoButtonColor = false,
					Text = "",
					Parent = parentHold,
				})
				Util.RegisterTheme(cpOuter, "BackgroundColor3", "OutlineColor")

				local cpMid = New("Frame", {
					Size = UDim2.new(1, -2, 1, -2),
					Position = UDim2.fromOffset(1, 1),
					BackgroundColor3 = Library.Theme.MidBorder,
					BorderSizePixel = 0,
					Parent = cpOuter,
				})
				local cpPreview = New("Frame", {
					Size = UDim2.new(1, -2, 1, -2),
					Position = UDim2.fromOffset(1, 1),
					BackgroundColor3 = curColor,
					BorderSizePixel = 0,
					Parent = cpMid,
				})
				New("Frame", {
					Size = UDim2.new(1, 0, 0.5, 0),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.85,
					BorderSizePixel = 0,
					Parent = cpPreview,
				})

				local isOpen = false
				local popOuter = nil
				local blocker = nil
				local svBaseRef = nil
				local svPinRef = nil
				local huePinRef = nil
				local hexLabelRef = nil

				local function closePicker()
					if not isOpen then return end
					isOpen = false
					if blocker then blocker:Destroy() blocker = nil end
					if popOuter then popOuter:Destroy() popOuter = nil end
				end

				local function applyColor(newCol)
					curColor = newCol
					curH, curS, curV = newCol:ToHSV()
					cpPreview.BackgroundColor3 = newCol
					if svBaseRef then svBaseRef.BackgroundColor3 = Color3.fromHSV(curH, 1, 1) end
					if svPinRef then svPinRef.Position = UDim2.fromScale(curS, 1 - curV) end
					if huePinRef then huePinRef.Position = UDim2.fromScale(0, 1 - curH) end
					if hexLabelRef then hexLabelRef.Text = "#" .. newCol:ToHex():upper() end
					if flag then Library.Flags[flag] = newCol end
					callback(newCol)
				end

				local function openPicker()
					if isOpen then closePicker() return end
					isOpen = true

					blocker = New("TextButton", {
						Size = UDim2.fromScale(1, 1),
						BackgroundTransparency = 1,
						Text = "",
						ZIndex = 9990,
						Parent = screenGui,
					})
					blocker.MouseButton1Click:Connect(closePicker)

					local absPos = cpOuter.AbsolutePosition
					local pOuter, pInner = Util.CreateHardBorder(screenGui, UDim2.fromOffset(175, 148), UDim2.fromOffset(math.clamp(absPos.X - 145, 10, 1500), absPos.Y + 16), Library.Theme.MainTop, Library.Theme.MainBottom, true)
					pOuter.ZIndex = 9995
					Util.AddSkeetGradientBar(pInner, 2)
					popOuter = pOuter

					-- 1. NATIVE SV PALETTE (Layer 1: Base Hue Color)
					local svBorder = New("Frame", {
						Size = UDim2.fromOffset(130, 100),
						Position = UDim2.fromOffset(8, 8),
						BackgroundColor3 = Library.Theme.OuterBorder,
						BorderSizePixel = 0,
						ZIndex = 9996,
						Parent = pInner,
					})
					local svBase = New("Frame", {
						Size = UDim2.new(1, -2, 1, -2),
						Position = UDim2.fromOffset(1, 1),
						BackgroundColor3 = Color3.fromHSV(curH, 1, 1),
						BorderSizePixel = 0,
						ClipsDescendants = true,
						ZIndex = 9996,
						Parent = svBorder,
					})
					svBaseRef = svBase

					-- Layer 2: White to Transparent Horizontal Gradient (Saturation)
					local satLayer = New("Frame", {
						Size = UDim2.fromScale(1, 1),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BorderSizePixel = 0,
						ZIndex = 9997,
						Parent = svBase,
					})
					New("UIGradient", {
						Rotation = 0,
						Transparency = NumberSequence.new({
							NumberSequenceKeypoint.new(0, 0),
							NumberSequenceKeypoint.new(1, 1),
						}),
						Parent = satLayer,
					})

					-- Layer 3: Transparent to Black Vertical Gradient (Value)
					local valLayer = New("Frame", {
						Size = UDim2.fromScale(1, 1),
						BackgroundColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						ZIndex = 9998,
						Parent = svBase,
					})
					New("UIGradient", {
						Rotation = 90,
						Transparency = NumberSequence.new({
							NumberSequenceKeypoint.new(0, 1),
							NumberSequenceKeypoint.new(1, 0),
						}),
						Parent = valLayer,
					})

					-- SV Cursor Reticle
					local svPin = New("Frame", {
						Size = UDim2.fromOffset(5, 5),
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(curS, 1 - curV),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BorderSizePixel = 1,
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						ZIndex = 9999,
						Parent = svBase,
					})
					svPinRef = svPin

					-- 2. NATIVE HUE RAINBOW BAR
					local hueBorder = New("Frame", {
						Size = UDim2.fromOffset(16, 100),
						Position = UDim2.fromOffset(148, 8),
						BackgroundColor3 = Library.Theme.OuterBorder,
						BorderSizePixel = 0,
						ZIndex = 9996,
						Parent = pInner,
					})
					local hueBase = New("Frame", {
						Size = UDim2.new(1, -2, 1, -2),
						Position = UDim2.fromOffset(1, 1),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BorderSizePixel = 0,
						ZIndex = 9997,
						Parent = hueBorder,
					})
					New("UIGradient", {
						Rotation = 90,
						Color = ColorSequence.new({
							ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
							ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
							ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
							ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
							ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
							ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
							ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
						}),
						Parent = hueBase,
					})

					-- Hue Pin
					local huePin = New("Frame", {
						Size = UDim2.new(1, 0, 0, 3),
						AnchorPoint = Vector2.new(0, 0.5),
						Position = UDim2.fromScale(0, 1 - curH),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BorderSizePixel = 1,
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						ZIndex = 9999,
						Parent = hueBase,
					})
					huePinRef = huePin

					-- Hex Text
					local hexLabel = New("TextLabel", {
						Size = UDim2.new(1, -16, 0, 22),
						Position = UDim2.fromOffset(8, 116),
						BackgroundTransparency = 1,
						Font = Library.Theme.Font,
						TextSize = Library.Theme.FontSize - 1,
						TextColor3 = Library.Theme.TextDim,
						TextXAlignment = Enum.TextXAlignment.Left,
						Text = "#" .. curColor:ToHex():upper(),
						ZIndex = 9996,
						Parent = pInner,
					})
					hexLabelRef = hexLabel

					local draggingSV, draggingHue = false, false

					valLayer.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							draggingSV = true
							local mPos = input.Position
							curS = math.clamp((mPos.X - svBase.AbsolutePosition.X) / svBase.AbsoluteSize.X, 0, 1)
							curV = 1 - math.clamp((mPos.Y - svBase.AbsolutePosition.Y) / svBase.AbsoluteSize.Y, 0, 1)
							applyColor(Color3.fromHSV(curH, curS, curV))
						end
					end)

					hueBase.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							draggingHue = true
							local mPos = input.Position
							curH = 1 - math.clamp((mPos.Y - hueBase.AbsolutePosition.Y) / hueBase.AbsoluteSize.Y, 0, 1)
							applyColor(Color3.fromHSV(curH, curS, curV))
						end
					end)

					local moveConn = UserInputService.InputChanged:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseMovement then
							if draggingSV then
								local mPos = input.Position
								curS = math.clamp((mPos.X - svBase.AbsolutePosition.X) / svBase.AbsoluteSize.X, 0, 1)
								curV = 1 - math.clamp((mPos.Y - svBase.AbsolutePosition.Y) / svBase.AbsoluteSize.Y, 0, 1)
								applyColor(Color3.fromHSV(curH, curS, curV))
							elseif draggingHue then
								local mPos = input.Position
								curH = 1 - math.clamp((mPos.Y - hueBase.AbsolutePosition.Y) / hueBase.AbsoluteSize.Y, 0, 1)
								applyColor(Color3.fromHSV(curH, curS, curV))
							end
						end
					end)

					local endConn = UserInputService.InputEnded:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							draggingSV = false
							draggingHue = false
						end
					end)

					pOuter.AncestryChanged:Connect(function()
						if not pOuter.Parent then
							moveConn:Disconnect()
							endConn:Disconnect()
							svBaseRef = nil
							svPinRef = nil
							huePinRef = nil
							hexLabelRef = nil
						end
					end)
				end

				cpOuter.MouseButton1Click:Connect(openPicker)

				local Colorpicker = {
					Frame = cpOuter,
					Set = function(self, newColor)
						applyColor(newColor)
					end,
					Get = function(self)
						return curColor
					end
				}

				if flag then Library.Flags[flag] = curColor end
				Util.RegisterFlag(flag, Colorpicker)
				return Colorpicker
			end

			-- KEYBIND
			local function createKeybindElement(parentHold, defaultKey, defaultMode, flag, elemName, onToggleVal)
				local currentKey = defaultKey or Enum.KeyCode.E
				local bindMode   = defaultMode or "Toggle"
				local listening  = false
				Library.Flags[flag] = { Key = currentKey, Type = bindMode }

				local bindBtnOuter, bindBtnInner = Util.CreateHardBorder(parentHold, UDim2.fromOffset(48, 15), nil, Library.Theme.ControlTop, Library.Theme.ControlBottom)
				bindBtnOuter.ZIndex = 6

				local bindLabel = New("TextLabel", {
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Font = Library.Theme.FontBold,
					TextSize = Library.Theme.FontSize - 2,
					TextColor3 = Library.Theme.Text,
					Text = "[" .. (currentKey.Name or "NONE") .. "]",
					ZIndex = 7,
					Parent = bindBtnInner,
				})
				Util.RegisterTheme(bindLabel, "TextColor3", "FontColor")

				local clickArea = New("TextButton", {
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Text = "",
					ZIndex = 8,
					Parent = bindBtnOuter,
				})

				local function refreshBindState(isActive)
					if listening then
						bindLabel.Text = "[...]"
						bindLabel.TextColor3 = Library.Theme.Accent1
					elseif isActive then
						bindLabel.Text = "[" .. (currentKey.Name or "NONE") .. "]"
						bindLabel.TextColor3 = Library.Theme.Accent1
					else
						bindLabel.Text = "[" .. (currentKey.Name or "NONE") .. "]"
						bindLabel.TextColor3 = Library.Theme.Text
					end
				end

				clickArea.MouseButton1Click:Connect(function()
					listening = true
					refreshBindState(false)
				end)

				clickArea.MouseButton2Click:Connect(function()
					local blocker = New("TextButton", {
						Size = UDim2.fromScale(1, 1),
						BackgroundTransparency = 1,
						Text = "",
						ZIndex = 9990,
						Parent = screenGui,
					})
					local absPos = bindBtnOuter.AbsolutePosition
					local menuOuter, menuInner = Util.CreateHardBorder(screenGui, UDim2.fromOffset(80, 68), UDim2.fromOffset(absPos.X - 32, absPos.Y + 18), Library.Theme.MainTop, Library.Theme.MainBottom, true)
					menuOuter.ZIndex = 9995
					Util.AddSkeetGradientBar(menuInner, 1)

					local modes = {"Toggle", "Hold", "Always"}
					for i, modeName in ipairs(modes) do
						local mBtn = New("TextButton", {
							Size = UDim2.new(1, 0, 0, 20),
							Position = UDim2.fromOffset(0, (i-1)*22 + 2),
							BackgroundTransparency = 1,
							BackgroundColor3 = Library.Theme.ControlHover,
							BorderSizePixel = 0,
							Font = Library.Theme.Font,
							TextSize = Library.Theme.FontSize - 1,
							TextColor3 = (bindMode == modeName) and Library.Theme.Accent1 or Library.Theme.TextDim,
							Text = modeName,
							ZIndex = 9996,
							Parent = menuInner,
						})
						mBtn.MouseEnter:Connect(function() Util.Tween(mBtn, 0.08, { BackgroundTransparency = 0 }) end)
						mBtn.MouseLeave:Connect(function() Util.Tween(mBtn, 0.08, { BackgroundTransparency = 1 }) end)
						mBtn.MouseButton1Click:Connect(function()
							bindMode = modeName
							Library.Flags[flag] = { Key = currentKey, Type = bindMode }
							if Library.KeybindList and currentKey ~= Enum.KeyCode.Unknown then
								Library.KeybindList:SetBind(elemName, currentKey.Name, bindMode, true)
							end
							blocker:Destroy()
							menuOuter:Destroy()
						end)
					end

					blocker.MouseButton1Click:Connect(function()
						blocker:Destroy()
						menuOuter:Destroy()
					end)
				end)

				table.insert(Library.Connections, UserInputService.InputBegan:Connect(function(input, gp)
					if Library.Unloaded then return end
					if listening then
						if input.UserInputType == Enum.UserInputType.Keyboard then
							listening = false
							if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then
								currentKey = Enum.KeyCode.Unknown
							else
								currentKey = input.KeyCode
							end
							refreshBindState(onToggleVal and onToggleVal())
							Library.Flags[flag] = { Key = currentKey, Type = bindMode }
							if Library.KeybindList and currentKey ~= Enum.KeyCode.Unknown then
								Library.KeybindList:SetBind(elemName, currentKey.Name, bindMode, onToggleVal and onToggleVal())
							end
						end
					elseif not gp and currentKey ~= Enum.KeyCode.Unknown and input.KeyCode == currentKey then
						if bindMode == "Toggle" then
							local nxt = not (onToggleVal and onToggleVal())
							if onToggleVal then onToggleVal(nxt) end
							refreshBindState(nxt)
						elseif bindMode == "Hold" then
							if onToggleVal then onToggleVal(true) end
							refreshBindState(true)
						end
						if Library.KeybindList then
							Library.KeybindList:SetBind(elemName, currentKey.Name, bindMode, onToggleVal and onToggleVal())
						end
					end
				end))

				table.insert(Library.Connections, UserInputService.InputEnded:Connect(function(input)
					if Library.Unloaded then return end
					if currentKey ~= Enum.KeyCode.Unknown and input.KeyCode == currentKey and bindMode == "Hold" then
						if onToggleVal then onToggleVal(false) end
						refreshBindState(false)
						if Library.KeybindList then
							Library.KeybindList:SetBind(elemName, currentKey.Name, bindMode, false)
						end
					end
				end))

				-- Handle so SaveManager can restore keybind state from configs
				local KeybindHandle = {
					Set = function(_, data)
						if typeof(data) == "table" then
							if data.Key ~= nil then currentKey = data.Key end
							if data.Type ~= nil then bindMode = data.Type end
						elseif typeof(data) == "EnumItem" then
							currentKey = data
						end
						Library.Flags[flag] = { Key = currentKey, Type = bindMode }
						if Library.KeybindList and currentKey ~= Enum.KeyCode.Unknown then
							Library.KeybindList:SetBind(elemName, currentKey.Name, bindMode, onToggleVal and onToggleVal() or false)
						end
						refreshBindState(onToggleVal and onToggleVal() or false)
					end,
					Get = function()
						return { Key = currentKey, Type = bindMode }
					end,
				}
				Library.FlagRegistry[flag] = KeybindHandle

				return bindBtnOuter
			end

			-- TOGGLE (hard-edged checkbox)
			function Group:AddToggle(tCfg)
				tCfg = tCfg or {}
				local tText    = tCfg.Text or "Toggle"
				local state    = tCfg.Default or false
				local flag     = tCfg.Flag or tText
				local callback = tCfg.Callback or function() end

				local BOX = 14
				local offFill = Color3.fromRGB(28, 28, 32)

				local row = New("Frame", {
					Size = UDim2.new(1, 0, 0, 18),
					BackgroundTransparency = 1,
					Parent = elemList,
				})

				table.insert(Library.SearchableControls, {
					Row = row,
					SearchText = string.lower(tText),
					Type = "Toggle"
				})

				local hoverBg = New("Frame", {
					Size = UDim2.new(1, 4, 1, 2),
					Position = UDim2.fromOffset(-2, -1),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ZIndex = 0,
					Parent = row,
				})

				local boxOuter, boxInner = Util.CreateHardBorder(
					row,
					UDim2.fromOffset(BOX, BOX),
					UDim2.fromOffset(0, 2),
					state and Library.Theme.Accent1 or offFill,
					offFill
				)
				boxOuter.ZIndex = 2

				local checkFill = New("Frame", {
					Size = UDim2.new(1, -4, 1, -4),
					Position = UDim2.fromOffset(2, 2),
					BackgroundColor3 = Library.Theme.Accent1,
					BackgroundTransparency = state and 0 or 1,
					BorderSizePixel = 0,
					ZIndex = 3,
					Parent = boxInner,
				})
				Util.RegisterTheme(checkFill, "BackgroundColor3", "AccentColor")

				local label = New("TextLabel", {
					Size = UDim2.new(1, -22, 1, 0),
					Position = UDim2.fromOffset(20, 0),
					BackgroundTransparency = 1,
					Font = Library.Theme.Font,
					TextSize = Library.Theme.FontSize,
					TextColor3 = state and Library.Theme.Text or Library.Theme.TextDim,
					TextXAlignment = Enum.TextXAlignment.Left,
					Text = tText,
					Parent = row,
				})
				Util.RegisterTheme(label, "TextColor3", "FontColor")

				local inlineHold = New("Frame", {
					Size = UDim2.new(0, 0, 1, 0),
					Position = UDim2.new(1, 0, 0, 0),
					AnchorPoint = Vector2.new(1, 0),
					AutomaticSize = Enum.AutomaticSize.X,
					BackgroundTransparency = 1,
					ZIndex = 5,
					Parent = row,
				})
				New("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Right,
					Padding = UDim.new(0, 5),
					Parent = inlineHold,
				})

				local Toggle = { Value = state }

				local function setToggle(val)
					Toggle.Value = val
					Library.Flags[flag] = val

					if val then
						Util.Tween(boxInner, 0.1, { BackgroundColor3 = Library.Theme.Accent1 })
						Util.Tween(checkFill, 0.1, { BackgroundTransparency = 0 })
						Util.Tween(label, 0.1, { TextColor3 = Library.Theme.Text })
					else
						Util.Tween(boxInner, 0.1, { BackgroundColor3 = offFill })
						Util.Tween(checkFill, 0.1, { BackgroundTransparency = 1 })
						Util.Tween(label, 0.1, { TextColor3 = Library.Theme.TextDim })
					end

					Util.PlaySound("toggle")
					callback(val)
				end

				local clickBtn = New("TextButton", {
					Size = UDim2.new(1, -65, 1, 0),
					BackgroundTransparency = 1,
					Text = "",
					ZIndex = 6,
					Parent = row,
				})
				clickBtn.MouseEnter:Connect(function()
					Util.Tween(hoverBg, 0.12, { BackgroundTransparency = 0.94 })
					Util.PlaySound("hover")
				end)
				clickBtn.MouseLeave:Connect(function()
					Util.Tween(hoverBg, 0.12, { BackgroundTransparency = 1 })
				end)
				clickBtn.MouseButton1Click:Connect(function()
					Util.PlaySound("click")
					setToggle(not Toggle.Value)
				end)

				function Toggle:Set(val) setToggle(val) end
				function Toggle:Get() return Toggle.Value end

				function Toggle:AddColorpicker(cpCfg)
					cpCfg = cpCfg or {}
					local cp = createColorPicker(inlineHold, cpCfg.Default, cpCfg.Flag or (flag .. "_Color"), cpCfg.Callback or function() end)
					return Toggle, cp
				end

				function Toggle:AddKeybind(kbCfg)
					kbCfg = kbCfg or {}
					createKeybindElement(inlineHold, kbCfg.Default or Enum.KeyCode.E, kbCfg.Mode or "Toggle", kbCfg.Flag or (flag .. "_Bind"), tText, function(newVal)
						if newVal ~= nil then setToggle(newVal) end
						return Toggle.Value
					end)
					return Toggle
				end

				Library.Flags[flag] = state
				Util.RegisterFlag(flag, Toggle)
				return Toggle
			end

			-- STANDALONE COLORPICKER
			function Group:AddColorpicker(cpCfg)
				cpCfg = cpCfg or {}
				local row = New("Frame", {
					Size = UDim2.new(1, 0, 0, 18),
					BackgroundTransparency = 1,
					Parent = elemList,
				})
				local label = New("TextLabel", {
					Size = UDim2.new(1, -34, 1, 0),
					BackgroundTransparency = 1,
					Font = Library.Theme.Font,
					TextSize = Library.Theme.FontSize,
					TextColor3 = Library.Theme.Text,
					TextXAlignment = Enum.TextXAlignment.Left,
					Text = cpCfg.Text or "Colorpicker",
					Parent = row,
				})
				Util.RegisterTheme(label, "TextColor3", "FontColor")

				local pickerHold = New("Frame", {
					Size = UDim2.new(0, 28, 1, 0),
					Position = UDim2.new(1, -28, 0, 0),
					BackgroundTransparency = 1,
					Parent = row,
				})
				return createColorPicker(pickerHold, cpCfg.Default, cpCfg.Flag or cpCfg.Text, cpCfg.Callback or function() end)
			end

			-- STANDALONE KEYBIND
			function Group:AddKeybind(kbCfg)
				kbCfg = kbCfg or {}
				local kbText     = kbCfg.Text or "Keybind"
				local callback   = kbCfg.Callback or function() end
				local active     = false

				local row = New("Frame", {
					Size = UDim2.new(1, 0, 0, 18),
					BackgroundTransparency = 1,
					Parent = elemList,
				})
				local label = New("TextLabel", {
					Size = UDim2.new(1, -54, 1, 0),
					BackgroundTransparency = 1,
					Font = Library.Theme.Font,
					TextSize = Library.Theme.FontSize,
					TextColor3 = Library.Theme.Text,
					TextXAlignment = Enum.TextXAlignment.Left,
					Text = kbText,
					Parent = row,
				})
				Util.RegisterTheme(label, "TextColor3", "FontColor")

				local bindHold = New("Frame", {
					Size = UDim2.new(0, 48, 1, 0),
					Position = UDim2.new(1, -48, 0, 0),
					BackgroundTransparency = 1,
					Parent = row,
				})
				createKeybindElement(bindHold, kbCfg.Default or Enum.KeyCode.F, kbCfg.Mode or "Toggle", kbCfg.Flag or kbText, kbText, function(newVal)
					if newVal ~= nil then
						active = newVal
						callback(active)
					end
					return active
				end)

				-- Alias so external code (settings manager) can call :AddKeybindPicker
				Group.AddKeybindPicker = Group.AddKeybind
			end

			-- SLIDER (Smooth animations + Floating tooltip + Direct manual number input)
			function Group:AddSlider(sCfg)
				sCfg = sCfg or {}
				local sText  = sCfg.Text or "Slider"
				local min    = sCfg.Min or 0
				local max    = sCfg.Max or 100
				local curVal = sCfg.Default or min
				local suffix = sCfg.Suffix or ""
				local flag   = sCfg.Flag or sText
				local cb     = sCfg.Callback or function() end

				local row = New("Frame", {
					Size = UDim2.new(1, 0, 0, 32),
					BackgroundTransparency = 1,
					Parent = elemList,
				})

				-- Register for search
				table.insert(Library.SearchableControls, {
					Row = row,
					SearchText = string.lower(sText),
					Type = "Slider"
				})

				local label = New("TextLabel", {
					Size = UDim2.new(0.65, 0, 0, 14),
					BackgroundTransparency = 1,
					Font = Library.Theme.Font,
					TextSize = Library.Theme.FontSize,
					TextColor3 = Library.Theme.Text,
					TextXAlignment = Enum.TextXAlignment.Left,
					Text = sText,
					Parent = row,
				})
				Util.RegisterTheme(label, "TextColor3", "FontColor")

				local valLabel = New("TextLabel", {
					Size = UDim2.new(0.35, 0, 0, 14),
					Position = UDim2.new(0.65, 0, 0, 0),
					BackgroundTransparency = 1,
					Font = Library.Theme.Font,
					TextSize = Library.Theme.FontSize,
					TextColor3 = Library.Theme.TextDim,
					TextXAlignment = Enum.TextXAlignment.Right,
					Text = tostring(curVal) .. suffix,
					Parent = row,
				})

				-- Direct manual typing box on clicking valLabel
				local manualInput = New("TextBox", {
					Size = UDim2.new(0.35, 0, 0, 14),
					Position = UDim2.new(0.65, 0, 0, 0),
					BackgroundTransparency = 1,
					Font = Library.Theme.FontBold,
					TextSize = Library.Theme.FontSize,
					TextColor3 = Library.Theme.Accent1,
					TextXAlignment = Enum.TextXAlignment.Right,
					ClearTextOnFocus = true,
					Visible = false,
					Parent = row,
				})

				local trackOuter, trackInner = Util.CreateHardBorder(row, UDim2.new(1, 0, 0, 8), UDim2.fromOffset(0, 18), Library.Theme.ControlTop, Library.Theme.ControlBottom)

				local pct = math.clamp((curVal - min) / (max - min), 0, 1)
				local fill = New("Frame", {
					Size = UDim2.new(pct, 0, 1, 0),
					BackgroundColor3 = Library.Theme.Accent1,
					BorderSizePixel = 0,
					Parent = trackInner,
				})
				Util.RegisterTheme(fill, "BackgroundColor3", "AccentColor")

				New("UIGradient", {
					Rotation = 90,
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 255, 255)),
						ColorSequenceKeypoint.new(1.0, Color3.fromRGB(180, 180, 180)),
					}),
					Parent = fill,
				})

				-- Floating value tooltip badge
				local tooltip = New("Frame", {
					Size = UDim2.fromOffset(36, 16),
					AnchorPoint = Vector2.new(0.5, 1),
					Position = UDim2.new(pct, 0, 0, -3),
					BackgroundColor3 = Library.Theme.MainTop,
					BorderSizePixel = 1,
					BorderColor3 = Library.Theme.OuterBorder,
					BackgroundTransparency = 1,
					ZIndex = 25,
					Visible = false,
					Parent = trackInner,
				})
				local tooltipText = New("TextLabel", {
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Font = Library.Theme.FontBold,
					TextSize = Library.Theme.FontSize - 2,
					TextColor3 = Library.Theme.Accent1,
					Text = tostring(curVal),
					ZIndex = 26,
					Parent = tooltip,
				})
				Util.RegisterTheme(tooltipText, "TextColor3", "AccentColor")

				-- Slider thumb knob with smooth hover glow
				local thumb = New("Frame", {
					Size = UDim2.fromOffset(4, 12),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(pct, 0, 0.5, 0),
					BackgroundColor3 = Color3.fromRGB(240, 240, 245),
					BorderSizePixel = 1,
					BorderColor3 = Library.Theme.OuterBorder,
					ZIndex = trackInner.ZIndex + 3,
					Parent = trackInner,
				})

				local dragging = false
				local function updateSlider(xPos)
					local x = math.clamp((xPos - trackInner.AbsolutePosition.X) / trackInner.AbsoluteSize.X, 0, 1)
					local val = math.floor(min + ((max - min) * x))
					curVal = val
					Library.Flags[flag] = val
					valLabel.Text = tostring(val) .. suffix
					tooltipText.Text = tostring(val)
					Util.Tween(fill, 0.04, { Size = UDim2.new(x, 0, 1, 0) })
					Util.Tween(thumb, 0.04, { Position = UDim2.new(x, 0, 0.5, 0) })
					Util.Tween(tooltip, 0.04, { Position = UDim2.new(x, 0, 0, -3) })
					cb(val)
				end

				valLabel.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						valLabel.Visible = false
						manualInput.Visible = true
						manualInput.Text = tostring(curVal)
						manualInput:CaptureFocus()
					end
				end)

				manualInput.FocusLost:Connect(function()
					local num = tonumber(manualInput.Text)
					if num then
						num = math.clamp(math.floor(num), min, max)
						curVal = num
						Library.Flags[flag] = num
						local newPct = (num - min) / (max - min)
						valLabel.Text = tostring(num) .. suffix
						Util.Tween(fill, 0.12, { Size = UDim2.new(newPct, 0, 1, 0) })
						Util.Tween(thumb, 0.12, { Position = UDim2.new(newPct, 0, 0.5, 0) })
						cb(num)
					end
					manualInput.Visible = false
					valLabel.Visible = true
				end)

				local trackBtn = New("TextButton", {
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Text = "",
					Parent = trackOuter,
				})

				trackBtn.MouseEnter:Connect(function()
					Util.Tween(thumb, 0.12, { Size = UDim2.fromOffset(6, 14), BackgroundColor3 = Library.Theme.Accent1 })
					tooltip.Visible = true
					Util.Tween(tooltip, 0.12, { BackgroundTransparency = 0 })
					Util.PlaySound("hover")
				end)

				trackBtn.MouseLeave:Connect(function()
					if not dragging then
						Util.Tween(thumb, 0.12, { Size = UDim2.fromOffset(4, 12), BackgroundColor3 = Color3.fromRGB(240, 240, 245) })
						local out = Util.Tween(tooltip, 0.12, { BackgroundTransparency = 1 })
						out.Completed:Connect(function() if not dragging then tooltip.Visible = false end end)
					end
				end)

				trackBtn.MouseButton1Down:Connect(function()
					dragging = true
					Util.PlaySound("click")
					tooltip.Visible = true
					Util.Tween(tooltip, 0.1, { BackgroundTransparency = 0 })
					Util.Tween(thumb, 0.1, { Size = UDim2.fromOffset(6, 14), BackgroundColor3 = Library.Theme.Accent1 })
					local mouse = UserInputService:GetMouseLocation()
					updateSlider(mouse.X)
				end)

				UserInputService.InputChanged:Connect(function(input)
					if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
						updateSlider(input.Position.X)
					end
				end)

				UserInputService.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 and dragging then
						dragging = false
						Util.Tween(thumb, 0.12, { Size = UDim2.fromOffset(4, 12), BackgroundColor3 = Color3.fromRGB(240, 240, 245) })
						local out = Util.Tween(tooltip, 0.14, { BackgroundTransparency = 1 })
						out.Completed:Connect(function() if not dragging then tooltip.Visible = false end end)
					end
				end)

				local Slider = { Value = curVal }
				function Slider:Set(v)
					v = math.clamp(v, min, max)
					curVal = v
					local pctNew = (v - min) / (max - min)
					valLabel.Text = tostring(v) .. suffix
					tooltipText.Text = tostring(v)
					Util.Tween(fill, 0.1, { Size = UDim2.new(pctNew, 0, 1, 0) })
					Util.Tween(thumb, 0.1, { Position = UDim2.new(pctNew, 0, 0.5, 0) })
					Util.Tween(tooltip, 0.1, { Position = UDim2.new(pctNew, 0, 0, -3) })
					cb(v)
				end
				function Slider:Get() return curVal end
				Util.RegisterFlag(flag, Slider)
				return Slider
			end

			-- DROPDOWN (Supports Options, List, Items, Values)
			function Group:AddDropdown(dCfg)
				dCfg = dCfg or {}
				local dText  = dCfg.Text or "Dropdown"
				local list   = dCfg.Options or dCfg.List or dCfg.Items or dCfg.Values or {}
				local isMulti= dCfg.Multi or false
				local flag   = dCfg.Flag or dText
				local cb     = dCfg.Callback or function() end

				local multiSelected = {}
				local curVal = "None"

				if isMulti then
					if typeof(dCfg.Default) == "table" then
						for k, v in pairs(dCfg.Default) do
							if typeof(k) == "string" and v == true then
								multiSelected[k] = true
							elseif typeof(v) == "string" then
								multiSelected[v] = true
							end
						end
					end
				else
					curVal = dCfg.Default or list[1] or "None"
				end

				local row = New("Frame", {
					Size = UDim2.new(1, 0, 0, 38),
					BackgroundTransparency = 1,
					Parent = elemList,
				})

				-- Register for search
				table.insert(Library.SearchableControls, {
					Row = row,
					SearchText = string.lower(dText),
					Type = "Dropdown"
				})

				local label = New("TextLabel", {
					Size = UDim2.new(1, 0, 0, 14),
					BackgroundTransparency = 1,
					Font = Library.Theme.Font,
					TextSize = Library.Theme.FontSize,
					TextColor3 = Library.Theme.Text,
					TextXAlignment = Enum.TextXAlignment.Left,
					Text = dText,
					Parent = row,
				})
				Util.RegisterTheme(label, "TextColor3", "FontColor")

				local ddOuter, ddInner = Util.CreateHardBorder(row, UDim2.new(1, 0, 0, 20), UDim2.fromOffset(0, 16), Library.Theme.ControlTop, Library.Theme.ControlBottom)

				local function getDisplayString()
					if isMulti then
						local str = {}
						for _, item in ipairs(list) do
							if multiSelected[item] then table.insert(str, tostring(item)) end
						end
						return #str > 0 and table.concat(str, ", ") or "None"
					end
					return tostring(curVal or "None")
				end

				local currentLabel = New("TextLabel", {
					Size = UDim2.new(1, -24, 1, 0),
					Position = UDim2.fromOffset(8, 0),
					BackgroundTransparency = 1,
					Font = Library.Theme.Font,
					TextSize = Library.Theme.FontSize,
					TextColor3 = Library.Theme.TextDim,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
					Text = getDisplayString(),
					Parent = ddInner,
				})

				local arrow = New("ImageLabel", {
					Size = UDim2.fromOffset(12, 12),
					Position = UDim2.new(1, -16, 0.5, -6),
					BackgroundTransparency = 1,
					Image = Library.Icons.Chevron,
					ImageColor3 = Library.Theme.TextDim,
					Parent = ddInner,
				})

				local popOuter = nil
				local blocker  = nil
				local isOpen   = false

				local function closeDropdown()
					if not isOpen then return end
					isOpen = false
					Util.Tween(arrow, 0.14, { Rotation = 0, ImageColor3 = Library.Theme.TextDim })
					if blocker then blocker:Destroy() blocker = nil end
					if popOuter then
						local anim = Util.Tween(popOuter, 0.12, { Size = UDim2.fromOffset(popOuter.AbsoluteSize.X, 0) })
						anim.Completed:Connect(function()
							if popOuter then popOuter:Destroy() popOuter = nil end
						end)
					end
				end

				local function openDropdown()
					if isOpen then closeDropdown() return end
					isOpen = true
					Util.Tween(arrow, 0.14, { Rotation = 180, ImageColor3 = Library.Theme.Accent1 })

					blocker = New("TextButton", {
						Size = UDim2.fromScale(1, 1),
						BackgroundTransparency = 1,
						Text = "",
						ZIndex = 9990,
						Parent = screenGui,
					})
					blocker.MouseButton1Click:Connect(closeDropdown)

					local absPos  = ddOuter.AbsolutePosition
					local absSize = ddOuter.AbsoluteSize
					local listCount = math.max(#list, 1)
					local listH   = math.clamp(listCount * 22, 22, 134)

					local pOuter, pInner = Util.CreateHardBorder(screenGui, UDim2.fromOffset(absSize.X, 0), UDim2.fromOffset(absPos.X, absPos.Y + absSize.Y + 2), Library.Theme.MainTop, Library.Theme.MainBottom, true)
					pOuter.ClipsDescendants = true
					pOuter.ZIndex = 9995
					Util.AddSkeetGradientBar(pInner, 1)
					popOuter = pOuter

					local scroll = New("ScrollingFrame", {
						Size = UDim2.new(1, 0, 1, -2),
						Position = UDim2.fromOffset(0, 2),
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						ScrollBarThickness = 2,
						ScrollBarImageColor3 = Library.Theme.Accent1,
						CanvasSize = UDim2.new(0, 0, 0, #list * 22),
						AutomaticCanvasSize = Enum.AutomaticSize.None,
						ZIndex = 9996,
						Parent = pInner,
					})
					Util.RegisterTheme(scroll, "ScrollBarImageColor3", "AccentColor")
					New("UIListLayout", {
						SortOrder = Enum.SortOrder.LayoutOrder,
						Parent = scroll,
					})

					if #list == 0 then
						New("TextLabel", {
							Size = UDim2.new(1, 0, 0, 22),
							BackgroundTransparency = 1,
							Font = Library.Theme.Font,
							TextSize = Library.Theme.FontSize,
							TextColor3 = Library.Theme.TextDark,
							Text = "  None",
							ZIndex = 9997,
							Parent = scroll,
						})
					else
						for _, item in ipairs(list) do
							local isSelected = isMulti and (multiSelected[item] == true) or (curVal == item)
							local itemBtn = New("TextButton", {
								Size = UDim2.new(1, 0, 0, 22),
								BackgroundTransparency = 1,
								BackgroundColor3 = Library.Theme.ControlHover,
								BorderSizePixel = 0,
								Font = Library.Theme.Font,
								TextSize = Library.Theme.FontSize,
								TextXAlignment = Enum.TextXAlignment.Left,
								Text = "   " .. tostring(item),
								TextColor3 = isSelected and Library.Theme.Accent1 or Library.Theme.TextDim,
								ZIndex = 9997,
								Parent = scroll,
							})

							local itemCheck = nil
							if isMulti then
								itemCheck = New("ImageLabel", {
									Size = isSelected and UDim2.fromOffset(10, 10) or UDim2.fromOffset(0, 0),
									Position = UDim2.new(1, -16, 0.5, 0),
									AnchorPoint = Vector2.new(0.5, 0.5),
									BackgroundTransparency = 1,
									Image = Library.Icons.Check,
									ImageColor3 = Library.Theme.Accent1,
									ImageTransparency = isSelected and 0 or 1,
									ZIndex = 9998,
									Parent = itemBtn,
								})
								Util.RegisterTheme(itemCheck, "ImageColor3", "AccentColor")
							end

							itemBtn.MouseEnter:Connect(function()
								Util.Tween(itemBtn, 0.08, { BackgroundTransparency = 0 })
							end)
							itemBtn.MouseLeave:Connect(function()
								Util.Tween(itemBtn, 0.08, { BackgroundTransparency = 1 })
							end)

							itemBtn.MouseButton1Click:Connect(function()
								if isMulti then
									multiSelected[item] = not multiSelected[item]
									local sel = multiSelected[item]
									Util.Tween(itemBtn, 0.12, { TextColor3 = sel and Library.Theme.Accent1 or Library.Theme.TextDim })
									if itemCheck then
										if sel then
											itemCheck.ImageTransparency = 0
											itemCheck.Size = UDim2.fromOffset(4, 4)
											Util.Tween(itemCheck, 0.15, { Size = UDim2.fromOffset(10, 10) }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
										else
											Util.Tween(itemCheck, 0.1, { Size = UDim2.fromOffset(0, 0), ImageTransparency = 1 })
										end
									end
									currentLabel.Text = getDisplayString()
									Library.Flags[flag] = multiSelected
									cb(multiSelected)
								else
									curVal = item
									currentLabel.Text = tostring(item)
									Library.Flags[flag] = item
									cb(item)
									closeDropdown()
								end
							end)
						end
					end

					Util.Tween(pOuter, 0.16, { Size = UDim2.fromOffset(absSize.X, listH + 4) }, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
				end

				local clickBtn = New("TextButton", {
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Text = "",
					Parent = ddOuter,
				})
				clickBtn.MouseButton1Click:Connect(openDropdown)

				Library.Flags[flag] = isMulti and multiSelected or curVal

				local Dropdown = {}
				function Dropdown:Set(val)
					if isMulti then
						multiSelected = {}
						if typeof(val) == "table" then
							for k, v in pairs(val) do
								if typeof(k) == "string" and v == true then
									multiSelected[k] = true
								elseif typeof(v) == "string" then
									multiSelected[v] = true
								end
							end
						end
						currentLabel.Text = getDisplayString()
						Library.Flags[flag] = multiSelected
						cb(multiSelected)
					else
						curVal = val
						currentLabel.Text = tostring(val)
						Library.Flags[flag] = val
						cb(val)
					end
				end

				function Dropdown:Get()
					return isMulti and multiSelected or curVal
				end

				function Dropdown:Refresh(newList, retainSelection)
					list = newList or {}
					if not retainSelection then
						if isMulti then
							multiSelected = {}
						else
							curVal = list[1] or ""
						end
					end
					currentLabel.Text = getDisplayString()
					Library.Flags[flag] = isMulti and multiSelected or curVal
				end

				Util.RegisterFlag(flag, Dropdown)
				return Dropdown
			end

			-- BUTTON (Icon support + Press compression + Ripple sweep + Sound)
			function Group:AddButton(bCfg)
				bCfg = bCfg or {}
				local bText   = bCfg.Text or "Button"
				local isRisky = bCfg.Risky or false
				local iconId  = bCfg.Icon
				local cb      = bCfg.Callback or function() end

				local topCol = isRisky and Library.Theme.Risky or Library.Theme.ControlTop
				local botCol = isRisky and Library.Theme.RiskyDark or Library.Theme.ControlBottom

				local btnOuter, btnInner = Util.CreateHardBorder(elemList, UDim2.new(1, 0, 0, 24), nil, topCol, botCol)

				-- Register for search
				table.insert(Library.SearchableControls, {
					Row = btnOuter,
					SearchText = string.lower(bText),
					Type = "Button"
				})

				local hasIcon = (iconId ~= nil and typeof(iconId) == "string")
				if hasIcon then
					local bIcon = New("ImageLabel", {
						Size = UDim2.fromOffset(13, 13),
						Position = UDim2.new(0, 8, 0.5, -6),
						BackgroundTransparency = 1,
						Image = iconId,
						ImageColor3 = isRisky and Color3.fromRGB(255, 255, 255) or Library.Theme.Accent1,
						ZIndex = btnInner.ZIndex + 2,
						Parent = btnInner,
					})
					if not isRisky then
						Util.RegisterTheme(bIcon, "ImageColor3", "AccentColor")
					end
				end

				local btnLabel = New("TextLabel", {
					Size = UDim2.new(1, hasIcon and -24 or 0, 1, 0),
					Position = UDim2.fromOffset(hasIcon and 24 or 0, 0),
					BackgroundTransparency = 1,
					Font = Library.Theme.FontBold,
					TextSize = Library.Theme.FontSize,
					TextColor3 = Library.Theme.Text,
					Text = bText,
					ZIndex = btnInner.ZIndex + 2,
					Parent = btnInner,
				})
				Util.RegisterTheme(btnLabel, "TextColor3", "FontColor")

				local clickBtn = New("TextButton", {
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Text = "",
					ZIndex = btnInner.ZIndex + 4,
					Parent = btnOuter,
				})

				clickBtn.MouseEnter:Connect(function()
					Util.Tween(btnInner, 0.1, { BackgroundColor3 = isRisky and Library.Theme.Risky or Library.Theme.ControlHover })
					Util.PlaySound("hover")
				end)
				clickBtn.MouseLeave:Connect(function()
					Util.Tween(btnInner, 0.1, { BackgroundColor3 = topCol })
				end)
				clickBtn.MouseButton1Down:Connect(function()
					Util.Tween(btnInner, 0.06, { Size = UDim2.new(1, -4, 1, -2), Position = UDim2.fromOffset(2, 1) })
				end)
				clickBtn.MouseButton1Up:Connect(function()
					Util.Tween(btnInner, 0.1, { Size = UDim2.new(1, -2, 1, -2), Position = UDim2.fromOffset(1, 1) })
				end)
				clickBtn.MouseButton1Click:Connect(function()
					Util.PlaySound("click")
					-- Color flash
					Util.Tween(btnInner, 0.04, { BackgroundColor3 = Library.Theme.Accent1 })
					task.delay(0.08, function() Util.Tween(btnInner, 0.14, { BackgroundColor3 = topCol }) end)

					-- Ripple sweep left → right
					local ripple = New("Frame", {
						Size = UDim2.new(0, 0, 1, 0),
						Position = UDim2.fromScale(0, 0),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 0.5,
						BorderSizePixel = 0,
						ZIndex = btnInner.ZIndex + 3,
						Parent = btnInner,
					})
					New("UIGradient", {
						Rotation = 0,
						Transparency = NumberSequence.new({
							NumberSequenceKeypoint.new(0, 1),
							NumberSequenceKeypoint.new(0.45, 0.35),
							NumberSequenceKeypoint.new(1, 1),
						}),
						Parent = ripple,
					})
					local sweep = Util.Tween(ripple, 0.3, { Size = UDim2.new(1.6, 0, 1, 0), BackgroundTransparency = 1 }, Enum.EasingStyle.Quad)
					sweep.Completed:Connect(function() if ripple.Parent then ripple:Destroy() end end)
					cb()
				end)

				return btnOuter
			end

			-- TEXTBOX
			function Group:AddTextbox(tbCfg)
				tbCfg = tbCfg or {}
				local tbText = tbCfg.Text or "Input"
				local holder = tbCfg.Placeholder or "Type here..."
				local flag   = tbCfg.Flag or tbText
				local cb     = tbCfg.Callback or function() end

				local row = New("Frame", {
					Size = UDim2.new(1, 0, 0, 38),
					BackgroundTransparency = 1,
					Parent = elemList,
				})

				local label = New("TextLabel", {
					Size = UDim2.new(1, 0, 0, 14),
					BackgroundTransparency = 1,
					Font = Library.Theme.Font,
					TextSize = Library.Theme.FontSize,
					TextColor3 = Library.Theme.Text,
					TextXAlignment = Enum.TextXAlignment.Left,
					Text = tbText,
					Parent = row,
				})
				Util.RegisterTheme(label, "TextColor3", "FontColor")

				local boxOuter, boxInner = Util.CreateHardBorder(row, UDim2.new(1, 0, 0, 20), UDim2.fromOffset(0, 16), Library.Theme.ControlTop, Library.Theme.ControlBottom)

				local box = New("TextBox", {
					Size = UDim2.new(1, -12, 1, 0),
					Position = UDim2.fromOffset(6, 0),
					BackgroundTransparency = 1,
					Font = Library.Theme.Font,
					TextSize = Library.Theme.FontSize,
					TextColor3 = Library.Theme.Text,
					PlaceholderText = holder,
					PlaceholderColor3 = Library.Theme.TextDark,
					TextXAlignment = Enum.TextXAlignment.Left,
					ClearTextOnFocus = false,
					Parent = boxInner,
				})
				Util.RegisterTheme(box, "TextColor3", "FontColor")

				box.FocusLost:Connect(function()
					Library.Flags[flag] = box.Text
					cb(box.Text)
				end)

				return box
			end

			return Group
		end

		function Tab:AddGroupbox(gCfg)
			gCfg = gCfg or {}
			local side = (gCfg.Side and string.lower(gCfg.Side) == "right") and rightCol or leftCol
			return Tab.CreateGroupbox(side, gCfg)
		end

		return Tab
	end

	return Window
end

function Library:SetThemeColor(colorType, newColor)
	if not colorType or not newColor then return end

	-- Repaint helper: updates the Theme key, every registered instance & signal callbacks
	local function applyKey(key, col)
		Library.Theme[key] = col
		if Library.Registry[key] then
			for _, item in ipairs(Library.Registry[key]) do
				if item.Instance and item.Instance.Parent then
					pcall(function()
						item.Instance[item.Property] = col
					end)
				end
			end
		end
		if Library.ThemeSignals[key] then
			for _, cb in ipairs(Library.ThemeSignals[key]) do
				pcall(cb, col)
			end
		end
	end

	-- Multiplies a color (clamped) to derive matching shades
	local function shade(col, mul)
		return Color3.new(
			math.clamp(col.R * mul, 0, 1),
			math.clamp(col.G * mul, 0, 1),
			math.clamp(col.B * mul, 0, 1)
		)
	end

	-- Live-update all registered UI elements across the whole menu, deriving related tones
	if colorType == "FontColor" or colorType == "Text" then
		applyKey("FontColor", newColor)
		applyKey("TextDim", shade(newColor, 0.69))
		applyKey("TextDark", shade(newColor, 0.44))
	elseif colorType == "MainColor" or colorType == "GroupTop" then
		applyKey("MainColor", newColor)
		applyKey("GroupTop", newColor)
		applyKey("GroupBottom", shade(newColor, 0.71))
		applyKey("ControlTop", shade(newColor, 1.5))
		applyKey("ControlBottom", shade(newColor, 1.0))
		applyKey("ControlHover", shade(newColor, 1.93))
		applyKey("MidBorder", shade(newColor, 2.07))
	elseif colorType == "AccentColor" or colorType == "Accent1" then
		applyKey("AccentColor", newColor)
		applyKey("Accent1", newColor)
		applyKey("AccentDark", shade(newColor, 0.63))
	elseif colorType == "BackgroundColor" or colorType == "MainTop" then
		applyKey("BackgroundColor", newColor)
		applyKey("MainTop", newColor)
		applyKey("MainBottom", shade(newColor, 0.56))
	elseif colorType == "OutlineColor" or colorType == "OuterBorder" then
		applyKey("OutlineColor", newColor)
		applyKey("OuterBorder", newColor)
	end
end

function Library:SetTheme(themeTable)
	for name, col in pairs(themeTable or {}) do
		Library:SetThemeColor(name, col)
	end
end

function Library:Unload()
	if self.Unloaded then return end
	self.Unloaded = true
	self.Open = false

	if typeof(self.OnUnload) == "function" then
		pcall(self.OnUnload)
	end

	for _, conn in ipairs(self.Connections) do
		pcall(function()
			conn:Disconnect()
		end)
	end
	table.clear(self.Connections)

	if blurEffect then
		pcall(function()
			blurEffect:Destroy()
		end)
		blurEffect = nil
	end

	if screenGui then
		pcall(function()
			screenGui:Destroy()
		end)
	end
end

return Library
