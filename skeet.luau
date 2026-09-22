--[[
	══════════════════════════════════════════════════════════════════════════════
	  SKEETWARE UI LIBRARY v6.0
	  • Animated logo from GitHub repository
	  • Modern dark theme with gradient accents
	  • Custom window system with sidebar
	  • Integrated ESP and combat functionality
	══════════════════════════════════════════════════════════════════════════════
]]

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService       = game:GetService("GuiService")
local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")
local CoreGui          = game:GetService("CoreGui")
local HttpService      = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

-- Logo configuration - using the animated GIF from GitHub
local LogoConfig = {
	-- Direct URL to the animated logo
	LogoUrl = "https://github.com/7xtrnl/SkeetUIkl/raw/refs/heads/main/new.gif",
	-- Fallback static logo (in case GIF doesn't load)
	FallbackLogo = "rbxassetid://10734977012", -- Target icon as fallback
	LogoSize = UDim2.new(0, 120, 0, 40),
	LogoPosition = UDim2.new(0, 10, 0, 5),
}

-- Function to load and use the animated logo
local function loadAnimatedLogo(parent)
	local success, logo = pcall(function()
		-- Try to load the animated logo
		local logoImage = Instance.new("ImageLabel")
		logoImage.Name = "AnimatedLogo"
		logoImage.Size = LogoConfig.LogoSize
		logoImage.Position = LogoConfig.LogoPosition
		logoImage.BackgroundTransparency = 1
		logoImage.Image = LogoConfig.LogoUrl
		logoImage.ScaleType = Enum.ScaleType.Fit
		logoImage.Parent = parent
		return logoImage
	end)
	
	if success and logo then
		return logo
	else
		-- Fallback to static icon
		warn("Failed to load animated logo, using fallback")
		local fallback = Instance.new("ImageLabel")
		fallback.Name = "FallbackLogo"
		fallback.Size = LogoConfig.LogoSize
		fallback.Position = LogoConfig.LogoPosition
		fallback.BackgroundTransparency = 1
		fallback.Image = LogoConfig.FallbackLogo
		fallback.Parent = parent
		return fallback
	end
end

-- Get safe GUI parent
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

-- Clean up old GUI
local oldGui = getSafeGuiParent():FindFirstChild("SkeetwareUI")
if oldGui then oldGui:Destroy() end

-- Create main ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SkeetwareUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = getSafeGuiParent()

-- Main Library
local Library = {
	Version   = "6.0.0",
	Open      = true,
	ToggleKey = Enum.KeyCode.Insert,
	Flags     = {},
	Registry  = {},
	FlagRegistry = {},
	ThemeSignals = {},
	TextSizeRegistry = {},
	KeybindList = nil,
	Watermark   = nil,
	ScreenGui   = screenGui,
	SoundsEnabled = true,
	SearchQuery = "",
	SearchableControls = {},
	Connections = {},
	Unloaded = false,
	OnUnload = nil,
	Windows = {},
	Build      = "6.0.0",
	LogoUrl    = LogoConfig.LogoUrl,
	
	-- Theme colors
	Theme = {
		Accent1       = Color3.fromRGB(138, 43, 226),  -- Purple Accent
		Accent2       = Color3.fromRGB(186, 85, 211),  -- Light Purple
		AccentDark    = Color3.fromRGB(105, 42, 168),
		MainTop       = Color3.fromRGB(12, 12, 14),      -- Dark main
		MainBottom    = Color3.fromRGB(8, 8, 10),       -- Even darker
		GroupTop      = Color3.fromRGB(19, 19, 21),     -- Dark groups
		GroupBottom   = Color3.fromRGB(14, 14, 16),     -- Dark group bottom
		ControlTop    = Color3.fromRGB(39, 39, 45),     -- Dark controls
		ControlBottom = Color3.fromRGB(56, 56, 62),     -- Control bottom
		ControlHover  = Color3.fromRGB(61, 61, 71),     -- Hover state
		OuterBorder   = Color3.fromRGB(3, 3, 3),        -- Near-black border
		MidBorder     = Color3.fromRGB(51, 51, 51),     -- Mid border
		Text          = Color3.fromRGB(208, 207, 227),  -- Light purple-tinted text
		TextDim       = Color3.fromRGB(134, 134, 134),  -- Dimmed text
		TextDark      = Color3.fromRGB(85, 85, 85),      -- Dark text
		Risky         = Color3.fromRGB(245, 85, 85),     -- Risk color
		RiskyDark     = Color3.fromRGB(180, 50, 50),     -- Dark risk
		Font          = Enum.Font.GothamMedium,
		FontBold      = Enum.Font.GothamBold,
		FontSize      = 12,
	},
	
	-- Animation timings
	Animation = {
		Tab       = { Time = 0.7,  Style = Enum.EasingStyle.Exponential, Dir = Enum.EasingDirection.Out },
		Panel     = { Time = 0.3,  Style = Enum.EasingStyle.Quint,       Dir = Enum.EasingDirection.Out },
		Notif     = { Time = 0.85, Style = Enum.EasingStyle.Exponential, Dir = Enum.EasingDirection.Out },
		Hover     = { Time = 0.12, Style = Enum.EasingStyle.Quart,       Dir = Enum.EasingDirection.Out },
		Color     = { Time = 0.55, Style = Enum.EasingStyle.Exponential, Dir = Enum.EasingDirection.Out },
	},
	
	-- Icons
	Icons = {
		Target    = "rbxassetid://10734977012",
		Crosshair = "rbxassetid://10709818534",
		Eye       = "rbxassetid://10723346959",
		Users     = "rbxassetid://10747373426",
		User      = "rbxassetid://10747373176",
		Shield    = "rbxassetid://140699768238308",
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
	},
}

-- Utility functions
local Util = {}

function Util.Create(class, props, children)
	local inst = Instance.new(class)
	for k, v in pairs(props or {}) do
		if k ~= "Parent" then
			inst[k] = v
		end
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
	Util.RegisterTheme(outer, "BackgroundColor3", "OuterBorder")

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
		Util.RegisterTheme(inner, "BackgroundColor3", "MainTop")
	else
		Util.RegisterTheme(inner, "BackgroundColor3", "GroupTop")
	end

	return outer, inner
end

-- Window creation with logo support
function Library:CreateWindow(config)
	local window = {
		Tabs = {},
		ActiveTab = nil,
		Config = config or {},
	}
	
	-- Create main window container
	local mainWindow = New("Frame", {
		Name = "MainWindow",
		Size = config.Size or UDim2.fromOffset(720, 520),
		Position = UDim2.fromScale(0.5, 0.5) - UDim2.fromOffset((config.Size or UDim2.fromOffset(720, 520)).X.Offset / 2, (config.Size or UDim2.fromOffset(720, 520)).Y.Offset / 2),
		BackgroundColor3 = Library.Theme.MainTop,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = screenGui,
	})
	
	local outer, inner = Util.CreateHardBorder(mainWindow, nil, nil, Library.Theme.MainTop, Library.Theme.MainBottom, true)
	
	-- Window header with logo
	local header = New("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 50),
		Position = UDim2.fromOffset(0, 0),
		BackgroundColor3 = Library.Theme.MainTop,
		BorderSizePixel = 0,
		Parent = inner,
	})
	
	-- Load animated logo in header
	local logo = loadAnimatedLogo(header)
	
	-- Window title
	local title = New("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, -140, 1, 0),
		Position = UDim2.fromOffset(130, 0),
		BackgroundTransparency = 1,
		Text = config.Title or "Skeetware",
		TextColor3 = Library.Theme.Text,
		Font = Library.Theme.FontBold,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = header,
	})
	Util.RegisterTheme(title, "TextColor3", "Text")
	
	-- Close button
	local closeBtn = New("TextButton", {
		Name = "CloseButton",
		Size = UDim2.fromOffset(30, 30),
		Position = UDim2.new(1, -35, 0, 10),
		BackgroundTransparency = 1,
		Text = "✕",
		TextColor3 = Library.Theme.Text,
		Font = Library.Theme.FontBold,
		TextSize = 18,
		Parent = header,
	})
	Util.RegisterTheme(closeBtn, "TextColor3", "Text")
	
	-- Tab container
	local tabContainer = New("Frame", {
		Name = "TabContainer",
		Size = UDim2.new(1, 0, 0, 40),
		Position = UDim2.fromOffset(0, 50),
		BackgroundColor3 = Library.Theme.GroupTop,
		BorderSizePixel = 0,
		Parent = inner,
	})
	
	-- Content area
	local contentArea = New("Frame", {
		Name = "ContentArea",
		Size = UDim2.new(1, 0, 1, -90),
		Position = UDim2.fromOffset(0, 90),
		BackgroundColor3 = Library.Theme.MainBottom,
		BorderSizePixel = 0,
		Parent = inner,
	})
	
	window.Frame = mainWindow
	window.Header = header
	window.TabContainer = tabContainer
	window.ContentArea = contentArea
	window.Logo = logo
	
	table.insert(Library.Windows, window)
	
	-- Add tab method
	function window:AddTab(name, icon)
		local tab = {
			Name = name,
			Icon = icon,
			Content = nil,
			Active = false,
		}
		
		local tabBtn = New("TextButton", {
			Name = name .. "Tab",
			Size = UDim2.new(0, 100, 1, 0),
			Position = UDim2.fromOffset(#window.Tabs * 100, 0),
			BackgroundTransparency = 1,
			Text = name,
			TextColor3 = Library.Theme.TextDim,
			Font = Library.Theme.Font,
			TextSize = 13,
			Parent = tabContainer,
		})
		Util.RegisterTheme(tabBtn, "TextColor3", "TextDim")
		
		tab.Button = tabBtn
		table.insert(window.Tabs, tab)
		
		-- Create content frame
		local content = New("Frame", {
			Name = name .. "Content",
			Size = UDim2.fromScale(1, 1),
			Position = UDim2.fromOffset(0, 0),
			BackgroundTransparency = 1,
			Visible = false,
			Parent = contentArea,
		})
		tab.Content = content
		
		-- Tab click handler
		tabBtn.MouseButton1Click:Connect(function()
			window:SetActiveTab(tab)
		end)
		
		-- Set first tab as active
		if #window.Tabs == 1 then
			window:SetActiveTab(tab)
		end
		
		-- Add groupbox method to tab
		function tab:AddGroupbox(config)
			local group = {
				Controls = {},
			}
			
			local groupFrame = New("Frame", {
				Name = config.Title or "Group",
				Size = UDim2.new(0.5, -10, 1, -10),
				Position = UDim2.fromOffset(
					config.Side == "right" and contentArea.AbsoluteSize.X / 2 + 5 or 5,
					5
				),
				BackgroundColor3 = Library.Theme.GroupTop,
				BorderSizePixel = 0,
				Parent = content,
			})
			
			local groupOuter, groupInner = Util.CreateHardBorder(groupFrame, nil, nil, Library.Theme.GroupTop, Library.Theme.GroupBottom, false)
			
			local groupTitle = New("TextLabel", {
				Name = "GroupTitle",
				Size = UDim2.new(1, 0, 0, 25),
				Position = UDim2.fromOffset(0, 0),
				BackgroundTransparency = 1,
				Text = config.Title or "Group",
				TextColor3 = Library.Theme.Text,
				Font = Library.Theme.FontBold,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Center,
				Parent = groupInner,
			})
			Util.RegisterTheme(groupTitle, "TextColor3", "Text")
			
			group.Frame = groupFrame
			group.Inner = groupInner
			
			-- Add control methods
			function group:AddToggle(config)
				local toggle = {
					Config = config,
					State = config.Default or false,
				}
				
				local toggleFrame = New("Frame", {
					Name = config.Text or "Toggle",
					Size = UDim2.new(1, -10, 0, 25),
					Position = UDim2.fromOffset(5, #group.Controls * 30 + 30),
					BackgroundTransparency = 1,
					Parent = groupInner,
				})
				
				local toggleBtn = New("TextButton", {
					Name = "ToggleBtn",
					Size = UDim2.fromOffset(20, 20),
					Position = UDim2.fromOffset(0, 0),
					BackgroundColor3 = toggle.State and Library.Theme.Accent1 or Library.Theme.ControlTop,
					BorderSizePixel = 0,
					Text = "",
					Parent = toggleFrame,
				})
				Util.RegisterTheme(toggleBtn, "BackgroundColor3", "Accent1")
				
				local toggleLabel = New("TextLabel", {
					Name = "ToggleLabel",
					Size = UDim2.new(1, -25, 1, 0),
					Position = UDim2.fromOffset(25, 0),
					BackgroundTransparency = 1,
					Text = config.Text or "Toggle",
					TextColor3 = Library.Theme.Text,
					Font = Library.Theme.Font,
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = toggleFrame,
				})
				Util.RegisterTheme(toggleLabel, "TextColor3", "Text")
				
				function toggle:Set(state)
					toggle.State = state
					toggleBtn.BackgroundColor3 = state and Library.Theme.Accent1 or Library.Theme.ControlTop
					if config.Flag then
						Library.Flags[config.Flag] = state
					end
					if config.Callback then
						config.Callback(state)
					end
				end
				
				toggleBtn.MouseButton1Click:Connect(function()
					toggle:Set(not toggle.State)
				end)
				
				if config.Flag then
					Library.Flags[config.Flag] = toggle.State
					Util.RegisterFlag(config.Flag, toggle)
				end
				
				table.insert(group.Controls, toggle)
				return toggle
			end
			
			function group:AddSlider(config)
				local slider = {
					Config = config,
					Value = config.Default or config.Min,
				}
				
				local sliderFrame = New("Frame", {
					Name = config.Text or "Slider",
					Size = UDim2.new(1, -10, 0, 40),
					Position = UDim2.fromOffset(5, #group.Controls * 45 + 30),
					BackgroundTransparency = 1,
					Parent = groupInner,
				})
				
				local sliderLabel = New("TextLabel", {
					Name = "SliderLabel",
					Size = UDim2.new(1, 0, 0, 20),
					Position = UDim2.fromOffset(0, 0),
					BackgroundTransparency = 1,
					Text = (config.Text or "Slider") .. ": " .. slider.Value .. (config.Suffix or ""),
					TextColor3 = Library.Theme.Text,
					Font = Library.Theme.Font,
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = sliderFrame,
				})
				Util.RegisterTheme(sliderLabel, "TextColor3", "Text")
				
				local sliderBg = New("Frame", {
					Name = "SliderBg",
					Size = UDim2.new(1, 0, 0, 5),
					Position = UDim2.fromOffset(0, 25),
					BackgroundColor3 = Library.Theme.ControlTop,
					BorderSizePixel = 0,
					Parent = sliderFrame,
				})
				Util.RegisterTheme(sliderBg, "BackgroundColor3", "ControlTop")
				
				local sliderFill = New("Frame", {
					Name = "SliderFill",
					Size = UDim2.new((slider.Value - config.Min) / (config.Max - config.Min), 0, 1, 0),
					Position = UDim2.fromOffset(0, 0),
					BackgroundColor3 = Library.Theme.Accent1,
					BorderSizePixel = 0,
					Parent = sliderBg,
				})
				Util.RegisterTheme(sliderFill, "BackgroundColor3", "Accent1")
				
				function slider:Set(value)
					slider.Value = math.clamp(value, config.Min, config.Max)
					sliderFill.Size = UDim2.new((slider.Value - config.Min) / (config.Max - config.Min), 0, 1, 0)
					sliderLabel.Text = (config.Text or "Slider") .. ": " .. slider.Value .. (config.Suffix or "")
					if config.Flag then
						Library.Flags[config.Flag] = slider.Value
					end
					if config.Callback then
						config.Callback(slider.Value)
					end
				end
				
				sliderBg.MouseButton1Down:Connect(function()
					local input = UserInputService.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseMovement then
							local relative = (input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X
							slider:Set(config.Min + relative * (config.Max - config.Min))
						end
					end)
					
					local release = UserInputService.InputEnded:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							input:Disconnect()
							release:Disconnect()
						end
					end)
				end)
				
				if config.Flag then
					Library.Flags[config.Flag] = slider.Value
					Util.RegisterFlag(config.Flag, slider)
				end
				
				table.insert(group.Controls, slider)
				return slider
			end
			
			return group
		end
		
		return tab
	end
	
	function window:SetActiveTab(tab)
		for _, t in ipairs(window.Tabs) do
			t.Active = (t == tab)
			t.Content.Visible = t.Active
			t.Button.TextColor3 = t.Active and Library.Theme.Text or Library.Theme.TextDim
		end
		window.ActiveTab = tab
	end
	
	-- Make window draggable
	local dragging = false
	local dragStart = nil
	local startPos = nil
	
	header.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = mainWindow.Position
		end
	end)
	
	header.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)
	
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			mainWindow.Position = startPos + UDim2.fromOffset(delta.X, delta.Y)
		end
	end)
	
	-- Close button functionality
	closeBtn.MouseButton1Click:Connect(function()
		Library.Open = not Library.Open
		mainWindow.Visible = Library.Open
	end)
	
	return window
end

-- Toggle key functionality
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Library.ToggleKey then
		Library.Open = not Library.Open
		for _, window in ipairs(Library.Windows) do
			window.Frame.Visible = Library.Open
		end
	end
end)

-- Notification system
function Library:Notify(config)
	local notification = New("Frame", {
		Name = "Notification",
		Size = UDim2.fromOffset(300, 60),
		Position = UDim2.new(1, -320, 0, 20),
		BackgroundColor3 = Library.Theme.GroupTop,
		BorderSizePixel = 0,
		Parent = screenGui,
	})
	
	local notifOuter, notifInner = Util.CreateHardBorder(notification, nil, nil, Library.Theme.GroupTop, Library.Theme.GroupBottom, false)
	
	local notifTitle = New("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, 0, 0, 25),
		Position = UDim2.fromOffset(0, 5),
		BackgroundTransparency = 1,
		Text = config.Title or "Notification",
		TextColor3 = Library.Theme.Text,
		Font = Library.Theme.FontBold,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = notifInner,
	})
	
	local notifText = New("TextLabel", {
		Name = "Text",
		Size = UDim2.new(1, 0, 0, 20),
		Position = UDim2.fromOffset(0, 30),
		BackgroundTransparency = 1,
		Text = config.Text or "",
		TextColor3 = Library.Theme.TextDim,
		Font = Library.Theme.Font,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = notifInner,
	})
	
	-- Animate in
	notification.Position = UDim2.new(1, 320, 0, 20)
	Util.Tween(notification, 0.3, { Position = UDim2.new(1, -320, 0, 20) }, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	
	-- Auto remove
	task.delay(config.Duration or 3, function()
		Util.Tween(notification, 0.3, { Position = UDim2.new(1, 320, 0, 20) }, Enum.EasingStyle.Quart, Enum.EasingDirection.In):Destroy()
	end)
end

-- Watermark
function Library:CreateWatermark(text)
	local watermark = New("Frame", {
		Name = "Watermark",
		Size = UDim2.fromOffset(150, 25),
		Position = UDim2.new(0, 10, 0, 10),
		BackgroundColor3 = Library.Theme.GroupTop,
		BorderSizePixel = 0,
		Parent = screenGui,
	})
	
	local wmOuter, wmInner = Util.CreateHardBorder(watermark, nil, nil, Library.Theme.GroupTop, Library.Theme.GroupBottom, false)
	
	local wmText = New("TextLabel", {
		Name = "Text",
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1,
		Text = text or "Skeetware",
		TextColor3 = Library.Theme.Text,
		Font = Library.Theme.FontBold,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = wmInner,
	})
	
	Library.Watermark = watermark
	return watermark
end

-- Theme management
function Library:SetTheme(themeData)
	if typeof(themeData) ~= "table" then return end
	
	for key, value in pairs(themeData) do
		if Library.Theme[key] and typeof(value) == typeof(Library.Theme[key]) then
			Library.Theme[key] = value
		end
	end
	
	-- Update registered theme items
	for themeKey, items in pairs(Library.Registry) do
		if Library.Theme[themeKey] then
			for _, item in ipairs(items) do
				pcall(function()
					item.Instance[item.Property] = Library.Theme[themeKey]
				end)
			end
		end
	end
end

-- Unload function
function Library:Unload()
	Library.Unloaded = true
	for _, connection in ipairs(Library.Connections) do
		connection:Disconnect()
	end
	
	if Library.OnUnload then
		Library.OnUnload()
	end
	
	screenGui:Destroy()
end

return Library
