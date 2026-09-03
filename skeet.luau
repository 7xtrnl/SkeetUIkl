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

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SkeetwareUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = getSafeGuiParent()

local Library = {
	Version   = "5.0.0",
	Open      = true,
	ToggleKey = Enum.KeyCode.Insert,
	Flags     = {},
	Registry  = {},
	ThemeSignals = {},
	KeybindList = nil,
	Watermark   = nil,
	ScreenGui   = screenGui,
	SoundsEnabled = true,
	SearchQuery = "",
	SearchableControls = {},

	Theme = {
		Accent1       = Color3.fromRGB(168, 219, 95),  -- Skeet Green
		Accent2       = Color3.fromRGB(94, 158, 219),  -- Skeet Cyan
		AccentDark    = Color3.fromRGB(105, 160, 50),
		MainTop       = Color3.fromRGB(28, 28, 32),
		MainBottom    = Color3.fromRGB(16, 16, 18),
		GroupTop      = Color3.fromRGB(24, 24, 27),
		GroupBottom   = Color3.fromRGB(17, 17, 19),
		ControlTop    = Color3.fromRGB(36, 36, 40),
		ControlBottom = Color3.fromRGB(24, 24, 26),
		ControlHover  = Color3.fromRGB(48, 48, 54),
		OuterBorder   = Color3.fromRGB(0, 0, 0),
		MidBorder     = Color3.fromRGB(48, 48, 54),
		Text          = Color3.fromRGB(230, 230, 235),
		TextDim       = Color3.fromRGB(155, 155, 165),
		TextDark      = Color3.fromRGB(95, 95, 105),
		Risky         = Color3.fromRGB(235, 75, 75),
		RiskyDark     = Color3.fromRGB(160, 40, 40),
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
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(180, 180, 180)),
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
		ClipsDescendants = true,
		Parent = parent,
	})

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

	-- Animated shimmer sweep that loops across the gradient bar
	local shimmer = New("Frame", {
		Size = UDim2.new(0.32, 0, 1, 0),
		Position = UDim2.fromScale(-0.32, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.62,
		BorderSizePixel = 0,
		ZIndex = 11,
		Parent = bar,
	})
	New("UIGradient", {
		Rotation = 0,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 0.28),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = shimmer,
	})
	task.spawn(function()
		while shimmer.Parent do
			shimmer.Position = UDim2.fromScale(-0.32, 0)
			task.wait(1.0)
			if not shimmer.Parent then break end
			Util.Tween(shimmer, 1.1, { Position = UDim2.fromScale(1.32, 0) }, Enum.EasingStyle.Sine)
			task.wait(2.4)
		end
	end)

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
	RunService.RenderStepped:Connect(function()
		fpsCount = fpsCount + 1
		if tick() - lastFpsUpdate >= 0.5 then
			local fps = math.floor(fpsCount / (tick() - lastFpsUpdate))
			local ping = math.floor((LocalPlayer and LocalPlayer:GetNetworkPing() or 0.015) * 1000)
			wmLabel.Text = string.format("%s | %s | %d fps | %d ms", title, LocalPlayer and LocalPlayer.DisplayName or "User", fps, ping)
			fpsCount = 0
			lastFpsUpdate = tick()
		end
	end)

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
	local title = cfg.Title or "Notification"
	local text  = cfg.Text or ""
	local dur   = cfg.Duration or 3.5

	local notifOuter, notifInner = Util.CreateHardBorder(notifHolder, UDim2.fromOffset(260, 0), nil, Library.Theme.MainTop, Library.Theme.MainBottom, true)
	notifOuter.ClipsDescendants = true
	Util.AddSkeetGradientBar(notifInner, 2)

	local titleLbl = New("TextLabel", {
		Size = UDim2.new(1, -16, 0, 18),
		Position = UDim2.fromOffset(8, 5),
		BackgroundTransparency = 1,
		Font = Library.Theme.FontBold,
		TextSize = Library.Theme.FontSize,
		TextColor3 = Library.Theme.Accent1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = title,
		Parent = notifInner,
	})
	Util.RegisterTheme(titleLbl, "TextColor3", "AccentColor")

	local textLbl = New("TextLabel", {
		Size = UDim2.new(1, -16, 0, 26),
		Position = UDim2.fromOffset(8, 22),
		BackgroundTransparency = 1,
		Font = Library.Theme.Font,
		TextSize = Library.Theme.FontSize - 1,
		TextColor3 = Library.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Text = text,
		Parent = notifInner,
	})
	Util.RegisterTheme(textLbl, "TextColor3", "FontColor")

	local timerBar = New("Frame", {
		Size = UDim2.new(1, 0, 0, 2),
		Position = UDim2.new(0, 0, 1, -2),
		BackgroundColor3 = Library.Theme.Accent1,
		BorderSizePixel = 0,
		Parent = notifInner,
	})
	Util.RegisterTheme(timerBar, "BackgroundColor3", "AccentColor")

	Util.Tween(notifOuter, 0.18, { Size = UDim2.fromOffset(260, 54) })
	Util.Tween(timerBar, dur, { Size = UDim2.new(0, 0, 0, 2) }, Enum.EasingStyle.Linear)

	task.delay(dur, function()
		local out = Util.Tween(notifOuter, 0.16, { Size = UDim2.fromOffset(260, 0) })
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

	-- Animated gradient background
	local animBg = New("Frame", {
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromOffset(0, 0),
		BackgroundColor3 = Color3.fromRGB(25, 25, 28),
		BorderSizePixel = 0,
		ZIndex = 1,
		Parent = winInner,
	})

	local bgGradient = New("UIGradient", {
		Rotation = 45,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 28, 32)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(32, 32, 36)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(28, 28, 32)),
		}),
		Parent = animBg,
	})

	-- Subtle animated shimmer
	local bgShimmer = New("Frame", {
		Size = UDim2.new(0.15, 0, 1, 0),
		Position = UDim2.fromScale(-0.15, 0),
		BackgroundColor3 = Color3.fromRGB(60, 60, 65),
		BackgroundTransparency = 0.9,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = animBg,
	})
	New("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 0.7),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = bgShimmer,
	})

	task.spawn(function()
		while bgShimmer.Parent do
			bgShimmer.Position = UDim2.fromScale(-0.15, 0)
			task.wait(3.0)
			if not bgShimmer.Parent then break end
			Util.Tween(bgShimmer, 2.5, { Position = UDim2.fromScale(1.15, 0) }, Enum.EasingStyle.Sine)
			task.wait(4.0)
		end
	end)

	Util.AddSkeetGradientBar(winInner, 3)

	-- Sidebar with Skeetware branding
	local sidebar = New("Frame", {
		Size = UDim2.new(0, 140, 1, -6),
		Position = UDim2.fromOffset(3, 3),
		BackgroundColor3 = Library.Theme.GroupTop,
		BorderSizePixel = 0,
		ZIndex = 10,
		Parent = winInner,
	})
	Util.RegisterTheme(sidebar, "BackgroundColor3", "MainColor")

	-- Branding section
	local brandingSection = New("Frame", {
		Size = UDim2.new(1, 0, 0, 60),
		Position = UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1,
		ZIndex = 11,
		Parent = sidebar,
	})

	New("ImageLabel", {
		Size = UDim2.fromOffset(32, 32),
		Position = UDim2.fromOffset(14, 14),
		BackgroundTransparency = 1,
		Image = Library.Icons.Shield,
		ImageColor3 = Library.Theme.Accent1,
		ZIndex = 12,
		Parent = brandingSection,
	})

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
		Size = UDim2.new(1, -150, 0, 30),
		Position = UDim2.fromOffset(147, 3),
		BackgroundTransparency = 1,
		ZIndex = 10,
		Parent = winInner,
	})

	local titleLabel = New("TextLabel", {
		Size = UDim2.new(1, -20, 1, 0),
		Position = UDim2.fromOffset(12, 0),
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

	New("Frame", {
		Size = UDim2.new(1, -150, 0, 1),
		Position = UDim2.fromOffset(147, 32),
		BackgroundColor3 = Library.Theme.MidBorder,
		BorderSizePixel = 0,
		ZIndex = 10,
		Parent = winInner,
	})

	local tabListFrame = New("Frame", {
		Size = UDim2.new(1, -170, 0, 28),
		Position = UDim2.fromOffset(147, 38),
		BackgroundTransparency = 1,
		ZIndex = 10,
		Parent = winInner,
	})

	do
		local dragging, dragStart, startPos
		titleBar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = true
				dragStart = input.Position
				startPos = winOuter.Position
			end
		end)
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

	UserInputService.InputBegan:Connect(function(input, gp)
		if not gp and input.KeyCode == Library.ToggleKey then
			Library.Open = not Library.Open
			if Library.Open then
				winOuter.Visible = true
				winOuter.Size = UDim2.fromOffset(winSize.X.Offset - 14, winSize.Y.Offset - 14)
				Util.Tween(winOuter, 0.18, { Size = winSize }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
				Util.PlaySound("open")
			else
				local t = Util.Tween(winOuter, 0.13, { Size = UDim2.fromOffset(winSize.X.Offset - 14, winSize.Y.Offset - 14) }, Enum.EasingStyle.Quart)
				t.Completed:Connect(function()
					winOuter.Visible = false
					winOuter.Size = winSize
				end)
				Util.PlaySound("close")
			end
		end
	end)



	-- Search Bar
	local searchBarOuter, searchBarInner = Util.CreateHardBorder(winInner, UDim2.new(1, -170, 0, 24), UDim2.fromOffset(147, 70), Library.Theme.ControlTop, Library.Theme.ControlBottom)
	searchBarOuter.ZIndex = 10
	searchBarOuter.Visible = false -- Hide search bar since tabs are now in sidebar

	local searchIcon = New("ImageLabel", {
		Size = UDim2.fromOffset(14, 14),
		Position = UDim2.fromOffset(8, 5),
		BackgroundTransparency = 1,
		Image = Library.Icons.Shield,
		ImageColor3 = Library.Theme.TextDim,
		ZIndex = 11,
		Parent = searchBarInner,
	})

	local searchInput = New("TextBox", {
		Size = UDim2.new(1, -32, 1, 0),
		Position = UDim2.fromOffset(24, 0),
		BackgroundTransparency = 1,
		Font = Library.Theme.Font,
		TextSize = Library.Theme.FontSize,
		TextColor3 = Library.Theme.Text,
		PlaceholderText = "Search settings...",
		PlaceholderColor3 = Library.Theme.TextDark,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		ZIndex = 11,
		Parent = searchBarInner,
	})

	searchInput:GetPropertyChangedSignal("Text"):Connect(function()
		Library.SearchQuery = string.lower(searchInput.Text)
		for _, control in ipairs(Library.SearchableControls) do
			if control.Row and control.SearchText then
				local matches = string.find(control.SearchText, Library.SearchQuery) ~= nil
				control.Row.Visible = matches or Library.SearchQuery == ""
			end
		end
	end)

	local contentHolder = New("Frame", {
		Size = UDim2.new(1, -170, 1, -40),
		Position = UDim2.fromOffset(147, 38),
		BackgroundTransparency = 1,
		ZIndex = 10,
		Parent = winInner,
	})
	New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = tabListFrame,
	})

	local contentHolder = New("Frame", {
		Size = UDim2.new(1, -24, 1, -78),
		Position = UDim2.fromOffset(12, 70),
		BackgroundTransparency = 1,
		ZIndex = 10,
		Parent = winInner,
	})

	local Window = { Tabs = {} }

	function Window:AddTab(tabName, iconAsset)
		local tabBtnOuter, tabBtnInner = Util.CreateHardBorder(sidebarTabList, UDim2.new(1, -8, 0, 32), nil, Library.Theme.ControlTop, Library.Theme.ControlBottom)

		local tabGlow = New("Frame", {
			Size = UDim2.new(1, 4, 1, 4),
			Position = UDim2.fromOffset(-2, -2),
			BackgroundColor3 = Library.Theme.Accent1,
			BackgroundTransparency = 0.95,
			BorderSizePixel = 0,
			ZIndex = tabBtnOuter.ZIndex - 1,
			Parent = tabBtnOuter,
		})
		tabGlow.Visible = false
		Util.RegisterTheme(tabGlow, "BackgroundColor3", "AccentColor")

		local hasIcon = (iconAsset ~= nil and typeof(iconAsset) == "string")

		if hasIcon then
			New("ImageLabel", {
				Size = UDim2.fromOffset(16, 16),
				Position = UDim2.new(0, 8, 0.5, -8),
				BackgroundTransparency = 1,
				Image = iconAsset,
				ImageColor3 = Library.Theme.TextDim,
				ZIndex = 12,
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
			ZIndex = 12,
			Parent = tabBtnInner,
		})

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

			local subBtnOuter, subBtnInner = Util.CreateHardBorder(self.SubTabBar, UDim2.fromOffset(75, 20), nil, Library.Theme.ControlTop, Library.Theme.ControlBottom)

			local subLabel = New("TextLabel", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Font = Library.Theme.FontBold,
				TextSize = Library.Theme.FontSize - 1,
				TextColor3 = Library.Theme.TextDim,
				Text = string.upper(subTabName or "SUBTAB"),
				Parent = subBtnInner,
			})

			local SubTab = {
				Btn = subBtnOuter,
				Inner = subBtnInner,
				Label = subLabel,
				Left = subLeftCol,
				Right = subRightCol,
			}

			local function selectSubTab()
				for _, other in ipairs(self.SubTabs) do
					other.Left.Visible = false
					other.Right.Visible = false
					Util.Tween(other.Label, 0.12, { TextColor3 = Library.Theme.TextDim })
					Util.Tween(other.Inner, 0.12, { BackgroundColor3 = Library.Theme.ControlTop })
				end
				SubTab.Left.Visible = true
				SubTab.Right.Visible = true
				Util.Tween(subLabel, 0.12, { TextColor3 = Library.Theme.Accent1 })
				Util.Tween(subBtnInner, 0.12, { BackgroundColor3 = Library.Theme.GroupTop })
			end

			subBtnInner.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
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
				other.Glow.Visible = false
				Util.Tween(other.Label, 0.15, { TextColor3 = Library.Theme.TextDim })
				Util.Tween(other.Inner, 0.15, { BackgroundColor3 = Library.Theme.ControlTop })
			end
			tabPage.Visible = true
			tabGlow.Visible = true
			Util.Tween(tabLabel, 0.15, { TextColor3 = Library.Theme.Text })
			Util.Tween(tabBtnInner, 0.15, { BackgroundColor3 = Library.Theme.GroupTop })
		end

		tabBtnInner.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				Util.PlaySound("click")
				selectTab()
			end
		end)

		tabBtnInner.MouseEnter:Connect(function()
			Util.PlaySound("hover")
		end)

		-- Tab hover tint for inactive tabs
		tabBtnInner.MouseEnter:Connect(function()
			if not tabPage.Visible then
				Util.Tween(tabBtnInner, 0.1, { BackgroundColor3 = Library.Theme.ControlHover })
			end
		end)
		tabBtnInner.MouseLeave:Connect(function()
			if not tabPage.Visible then
				Util.Tween(tabBtnInner, 0.1, { BackgroundColor3 = Library.Theme.ControlTop })
			end
		end)

		Tab.Btn = tabBtnOuter
		Tab.Inner = tabBtnInner
		Tab.Label = tabLabel
		Tab.Glow = tabGlow
		table.insert(Window.Tabs, Tab)

		if #Window.Tabs == 1 then selectTab() end

		-- Helper function to generate groupbox inside any column
		function Tab.CreateGroupbox(parentCol, gCfg)
			gCfg = gCfg or {}
			local gTitle = gCfg.Title or "Group"

			local gbOuter, gbInner = Util.CreateHardBorder(parentCol, UDim2.new(1, 0, 0, 0), nil, Library.Theme.GroupTop, Library.Theme.GroupBottom)
			gbOuter.AutomaticSize = Enum.AutomaticSize.Y

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
				return Colorpicker
			end

			-- KEYBIND
			local function createKeybindElement(parentHold, defaultKey, defaultMode, flag, elemName, onToggleVal)
				local currentKey = defaultKey or Enum.KeyCode.E
				local bindMode   = defaultMode or "Toggle"
				local listening  = false

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

				UserInputService.InputBegan:Connect(function(input, gp)
					if listening then
						if input.UserInputType == Enum.UserInputType.Keyboard then
							listening = false
							if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then
								currentKey = Enum.KeyCode.Unknown
							else
								currentKey = input.KeyCode
							end
							refreshBindState(onToggleVal and onToggleVal())
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
				end)

				UserInputService.InputEnded:Connect(function(input)
					if currentKey ~= Enum.KeyCode.Unknown and input.KeyCode == currentKey and bindMode == "Hold" then
						if onToggleVal then onToggleVal(false) end
						refreshBindState(false)
						if Library.KeybindList then
							Library.KeybindList:SetBind(elemName, currentKey.Name, bindMode, false)
						end
					end
				end)

				return bindBtnOuter
			end

			-- TOGGLE
			function Group:AddToggle(tCfg)
				tCfg = tCfg or {}
				local tText    = tCfg.Text or "Toggle"
				local state    = tCfg.Default or false
				local flag     = tCfg.Flag or tText
				local callback = tCfg.Callback or function() end

				local row = New("Frame", {
					Size = UDim2.new(1, 0, 0, 18),
					BackgroundTransparency = 1,
					Parent = elemList,
				})

				-- Register for search
				table.insert(Library.SearchableControls, {
					Row = row,
					SearchText = string.lower(tText),
					Type = "Toggle"
				})

				-- Subtle accent hover highlight behind the row
				local hoverBg = New("Frame", {
					Size = UDim2.new(1, 6, 1, 2),
					Position = UDim2.fromOffset(-3, -1),
					BackgroundColor3 = Library.Theme.Accent1,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ZIndex = 0,
					Parent = row,
				})
				Util.RegisterTheme(hoverBg, "BackgroundColor3", "AccentColor")

				local boxOuter, boxInner = Util.CreateHardBorder(row, UDim2.fromOffset(13, 13), UDim2.fromOffset(0, 2), Library.Theme.ControlTop, Library.Theme.ControlBottom)

				local fill = New("Frame", {
					Size = UDim2.fromScale(1, 1),
					BackgroundColor3 = Library.Theme.Accent1,
					BorderSizePixel = 0,
					BackgroundTransparency = state and 0 or 1,
					Parent = boxInner,
				})
				Util.RegisterTheme(fill, "BackgroundColor3", "AccentColor")

				-- Checkmark glyph that pops in when toggled on
				local checkMark = New("TextLabel", {
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Font = Library.Theme.FontBold,
					TextSize = 9,
					TextColor3 = Color3.fromRGB(14, 14, 17),
					Text = "✓",
					Visible = state,
					ZIndex = boxInner.ZIndex + 2,
					Parent = boxInner,
				})

				local label = New("TextLabel", {
					Size = UDim2.new(1, -20, 1, 0),
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
					Util.Tween(fill, 0.14, { BackgroundTransparency = val and 0 or 1 })
					checkMark.Visible = val
					Util.Tween(label, 0.14, { TextColor3 = val and Library.Theme.Text or Library.Theme.TextDim })
					Util.PlaySound("toggle")
					callback(val)
				end

				local clickBtn = New("TextButton", {
					Size = UDim2.new(1, -65, 1, 0),
					BackgroundTransparency = 1,
					Text = "",
					ZIndex = 2,
					Parent = row,
				})
				clickBtn.MouseEnter:Connect(function()
					Util.Tween(hoverBg, 0.12, { BackgroundTransparency = 0.91 })
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
			end

			-- SLIDER
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
					Size = UDim2.new(1, 0, 0, 30),
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
					Size = UDim2.new(0.7, 0, 0, 14),
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
					Size = UDim2.new(0.3, 0, 0, 14),
					Position = UDim2.new(0.7, 0, 0, 0),
					BackgroundTransparency = 1,
					Font = Library.Theme.Font,
					TextSize = Library.Theme.FontSize,
					TextColor3 = Library.Theme.TextDim,
					TextXAlignment = Enum.TextXAlignment.Right,
					Text = tostring(curVal) .. suffix,
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

				-- Slider thumb knob at the current fill edge
				local thumb = New("Frame", {
					Size = UDim2.fromOffset(3, 12),
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(pct, 0, 0.5, 0),
					BackgroundColor3 = Color3.fromRGB(235, 235, 240),
					BorderSizePixel = 0,
					ZIndex = trackInner.ZIndex + 2,
					Parent = trackInner,
				})

				local dragging = false
				local function updateSlider(xPos)
					local x = math.clamp((xPos - trackInner.AbsolutePosition.X) / trackInner.AbsoluteSize.X, 0, 1)
					local val = math.floor(min + ((max - min) * x))
					curVal = val
					Library.Flags[flag] = val
					valLabel.Text = tostring(val) .. suffix
					Util.Tween(fill, 0.05, { Size = UDim2.new(x, 0, 1, 0) })
					Util.Tween(thumb, 0.05, { Position = UDim2.new(x, 0, 0.5, 0) })
					cb(val)
				end

				local trackBtn = New("TextButton", {
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Text = "",
					Parent = trackOuter,
				})

				trackBtn.MouseButton1Down:Connect(function()
					dragging = true
					local mouse = UserInputService:GetMouseLocation()
					updateSlider(mouse.X)
				end)

				UserInputService.InputChanged:Connect(function(input)
					if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
						updateSlider(input.Position.X)
					end
				end)

				UserInputService.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
				end)

				local Slider = { Value = curVal }
				function Slider:Set(v)
					v = math.clamp(v, min, max)
					curVal = v
					local pctNew = (v - min) / (max - min)
					valLabel.Text = tostring(v) .. suffix
					Util.Tween(fill, 0.1, { Size = UDim2.new(pctNew, 0, 1, 0) })
					Util.Tween(thumb, 0.1, { Position = UDim2.new(pctNew, 0, 0.5, 0) })
					cb(v)
				end
				function Slider:Get() return curVal end
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
							local isSelected = isMulti and multiSelected[item] or (curVal == item)
							local itemBtn = New("TextButton", {
								Size = UDim2.new(1, 0, 0, 22),
								BackgroundTransparency = 1,
								BackgroundColor3 = Library.Theme.ControlHover,
								BorderSizePixel = 0,
								Font = Library.Theme.Font,
								TextSize = Library.Theme.FontSize,
								TextXAlignment = Enum.TextXAlignment.Left,
								Text = "  " .. tostring(item),
								TextColor3 = isSelected and Library.Theme.Accent1 or Library.Theme.TextDim,
								ZIndex = 9997,
								Parent = scroll,
							})

							itemBtn.MouseEnter:Connect(function()
								Util.Tween(itemBtn, 0.08, { BackgroundTransparency = 0 })
							end)
							itemBtn.MouseLeave:Connect(function()
								Util.Tween(itemBtn, 0.08, { BackgroundTransparency = 1 })
							end)

							itemBtn.MouseButton1Click:Connect(function()
								if isMulti then
									multiSelected[item] = not multiSelected[item]
									itemBtn.TextColor3 = multiSelected[item] and Library.Theme.Accent1 or Library.Theme.TextDim
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

					Util.Tween(pOuter, 0.15, { Size = UDim2.fromOffset(absSize.X, listH + 4) })
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

				return Dropdown
			end

			-- BUTTON
			function Group:AddButton(bCfg)
				bCfg = bCfg or {}
				local bText   = bCfg.Text or "Button"
				local isRisky = bCfg.Risky or false
				local cb      = bCfg.Callback or function() end

				local topCol = isRisky and Library.Theme.Risky or Library.Theme.ControlTop
				local botCol = isRisky and Library.Theme.RiskyDark or Library.Theme.ControlBottom

				local btnOuter, btnInner = Util.CreateHardBorder(elemList, UDim2.new(1, 0, 0, 22), nil, topCol, botCol)

				-- Register for search
				table.insert(Library.SearchableControls, {
					Row = btnOuter,
					SearchText = string.lower(bText),
					Type = "Button"
				})

				local btnLabel = New("TextLabel", {
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Font = Library.Theme.FontBold,
					TextSize = Library.Theme.FontSize,
					TextColor3 = Library.Theme.Text,
					Text = bText,
					Parent = btnInner,
				})
				Util.RegisterTheme(btnLabel, "TextColor3", "FontColor")

				local clickBtn = New("TextButton", {
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Text = "",
					Parent = btnOuter,
				})

				clickBtn.MouseEnter:Connect(function()
					Util.Tween(btnInner, 0.1, { BackgroundColor3 = isRisky and Library.Theme.Risky or Library.Theme.ControlHover })
				end)
				clickBtn.MouseLeave:Connect(function()
					Util.Tween(btnInner, 0.1, { BackgroundColor3 = topCol })
				end)
				clickBtn.MouseButton1Click:Connect(function()
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
						ZIndex = btnInner.ZIndex + 1,
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
					local sweep = Util.Tween(ripple, 0.32, { Size = UDim2.new(1.6, 0, 1, 0), BackgroundTransparency = 1 }, Enum.EasingStyle.Quad)
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

	local internalKey = colorType
	if colorType == "FontColor" or colorType == "Text" then
		internalKey = "FontColor"
		Library.Theme.Text = newColor
	elseif colorType == "MainColor" or colorType == "GroupTop" then
		internalKey = "MainColor"
		Library.Theme.GroupTop = newColor
	elseif colorType == "AccentColor" or colorType == "Accent1" then
		internalKey = "AccentColor"
		Library.Theme.Accent1 = newColor
	elseif colorType == "BackgroundColor" or colorType == "MainTop" then
		internalKey = "BackgroundColor"
		Library.Theme.MainTop = newColor
	elseif colorType == "OutlineColor" or colorType == "OuterBorder" then
		internalKey = "OutlineColor"
		Library.Theme.OuterBorder = newColor
	end

	-- Live-update all registered UI elements across the whole menu
	if Library.Registry[internalKey] then
		for _, item in ipairs(Library.Registry[internalKey]) do
			if item.Instance and item.Instance.Parent then
				pcall(function()
					item.Instance[item.Property] = newColor
				end)
			end
		end
	end

	if Library.ThemeSignals[internalKey] then
		for _, cb in ipairs(Library.ThemeSignals[internalKey]) do
			pcall(cb, newColor)
		end
	end
end

function Library:SetTheme(themeTable)
	for name, col in pairs(themeTable or {}) do
		Library:SetThemeColor(name, col)
	end
end

return Library
