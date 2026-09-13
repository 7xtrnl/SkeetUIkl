--[[
	══════════════════════════════════════════════════════════════════════════════
	  SKEETWARE SETTINGS MANAGER (Linoria-Style Modular Companion)
	  • SaveManager: Save, Load, Overwrite, Auto-Load, Delete & Refresh Configs
	  • ThemeManager: "FontColor", "MainColor", "AccentColor", "BackgroundColor", "OutlineColor"
	  • Native file operations: writefile, readfile, listfiles, isfolder, makefolder, delfile
	══════════════════════════════════════════════════════════════════════════════
--]]

local HttpService = game:GetService("HttpService")

local SettingsManager = {
	Folder = "SkeetwareConfigs",
	Library = nil,
	SaveManager = {},
	ThemeManager = {},
}

--============================================================================--
-- HELPER FILE SYSTEM WRAPPERS
--============================================================================--
local function checkFolder(folder)
	if typeof(isfolder) == "function" and typeof(makefolder) == "function" then
		if not isfolder(folder) then
			pcall(makefolder, folder)
		end
	end
end

local function safeWriteFile(path, data)
	if typeof(writefile) == "function" then
		pcall(writefile, path, data)
	end
end

local function safeReadFile(path)
	if typeof(readfile) == "function" and typeof(isfile) == "function" then
		if isfile(path) then
			local ok, content = pcall(readfile, path)
			if ok then return content end
		end
	elseif typeof(readfile) == "function" then
		local ok, content = pcall(readfile, path)
		if ok then return content end
	end
	return nil
end

local function safeDeleteFile(path)
	if typeof(delfile) == "function" then
		pcall(delfile, path)
	end
end

local function safeListFiles(folder)
	local files = {}
	if typeof(listfiles) == "function" then
		local ok, res = pcall(listfiles, folder)
		if ok and typeof(res) == "table" then
			for _, file in ipairs(res) do
				local name = file:match("([^/\\]+)%.json$")
				if name then
					table.insert(files, name)
				end
			end
		end
	end
	return files
end

-- Serialize & Deserialize helpers (Handling Color3, Enum, table)
local function encodeValue(val)
	if typeof(val) == "Color3" then
		return { __type = "Color3", r = val.R, g = val.G, b = val.B }
	elseif typeof(val) == "EnumItem" then
		return { __type = "EnumItem", enum = tostring(val.EnumType), name = val.Name }
	elseif typeof(val) == "table" then
		local copy = {}
		for k, v in pairs(val) do
			copy[k] = encodeValue(v)
		end
		return copy
	end
	return val
end

local function decodeValue(val)
	if typeof(val) == "table" and val.__type then
		if val.__type == "Color3" then
			return Color3.new(val.r, val.g, val.b)
		elseif val.__type == "EnumItem" then
			local enumType = Enum[val.enum]
			if enumType and enumType[val.name] then
				return enumType[val.name]
			end
		end
	elseif typeof(val) == "table" then
		local copy = {}
		for k, v in pairs(val) do
			copy[k] = decodeValue(v)
		end
		return copy
	end
	return val
end

--============================================================================--
-- SAVE MANAGER
--============================================================================--
local SaveManager = SettingsManager.SaveManager
SaveManager.AutoLoadConfig = nil

function SaveManager:SetLibrary(lib)
	SettingsManager.Library = lib
end

function SaveManager:SetFolder(folder)
	SettingsManager.Folder = folder
	checkFolder(folder)
end

function SaveManager:GetConfigList()
	return safeListFiles(SettingsManager.Folder)
end

function SaveManager:Save(configName)
	if not configName or configName:gsub(" ", "") == "" then
		if SettingsManager.Library then
			SettingsManager.Library:Notify({ Title = "Config Manager", Text = "Please enter a valid configuration name.", Duration = 3 })
		end
		return false
	end

	checkFolder(SettingsManager.Folder)
	local data = {}
	if SettingsManager.Library and SettingsManager.Library.Flags then
		for flag, val in pairs(SettingsManager.Library.Flags) do
			-- Exclude only built-in manager control flags; theme colors, the
			-- menu keybind and HUD positions all persist across sessions now
			if not flag:match("^__config_") then
				data[flag] = encodeValue(val)
			end
		end
	end

	local encoded = HttpService:JSONEncode(data)
	safeWriteFile(SettingsManager.Folder .. "/" .. configName .. ".json", encoded)

	if SettingsManager.Library then
		SettingsManager.Library:Notify({ Title = "Config Manager", Text = string.format("Successfully saved config '%s'.", configName), Duration = 3.5 })
	end
	return true
end

function SaveManager:Load(configName)
	if not configName or configName:gsub(" ", "") == "" then
		if SettingsManager.Library then
			SettingsManager.Library:Notify({ Title = "Config Manager", Text = "Please select a config to load.", Duration = 3 })
		end
		return false
	end

	local raw = safeReadFile(SettingsManager.Folder .. "/" .. configName .. ".json")
	if not raw then
		if SettingsManager.Library then
			SettingsManager.Library:Notify({ Title = "Config Manager", Text = string.format("Config '%s' not found.", configName), Duration = 3 })
		end
		return false
	end

	local ok, decoded = pcall(function() return HttpService:JSONDecode(raw) end)
	if not ok or typeof(decoded) ~= "table" then
		if SettingsManager.Library then
			SettingsManager.Library:Notify({ Title = "Config Manager", Text = "Failed to decode config JSON data.", Duration = 3 })
		end
		return false
	end

	for flag, rawVal in pairs(decoded) do
		local val = decodeValue(rawVal)
		local lib = SettingsManager.Library
		if lib then
			local component = lib.FlagRegistry and lib.FlagRegistry[flag]
			if component and component.Set then
				-- Push the value through the component so UI state, visuals & callbacks update
				pcall(function()
					component:Set(val)
				end)
			elseif lib.Flags then
				lib.Flags[flag] = val
			end
		end
	end

	-- Restore draggable HUD positions saved from the previous session
	do
		local lib = SettingsManager.Library
		if lib then
			local fp = lib.Flags
			local wp = fp and fp["__wm_pos"]
			if lib.Watermark and typeof(wp) == "table" and wp.X and wp.Y then
				pcall(function() lib.Watermark.Position = UDim2.fromOffset(wp.X, wp.Y) end)
			end
			local kp = fp and fp["__kb_pos"]
			if lib.KeybindListFrame and typeof(kp) == "table" and kp.X and kp.Y then
				pcall(function() lib.KeybindListFrame.Position = UDim2.fromOffset(kp.X, kp.Y) end)
			end
		end
	end

	if SettingsManager.Library then
		SettingsManager.Library:Notify({ Title = "Config Manager", Text = string.format("Loaded config '%s'.", configName), Duration = 3.5 })
	end
	return true
end

function SaveManager:Delete(configName)
	if not configName or configName:gsub(" ", "") == "" then return false end
	safeDeleteFile(SettingsManager.Folder .. "/" .. configName .. ".json")
	if SettingsManager.Library then
		SettingsManager.Library:Notify({ Title = "Config Manager", Text = string.format("Deleted config '%s'.", configName), Duration = 3 })
	end
	return true
end

function SaveManager:BuildConfigSection(groupbox)
	local configList = self:GetConfigList()
	local selectedConfig = configList[1] or ""
	local newConfigName = ""

	local configDropdown = groupbox:AddDropdown({
		Text = "Config List",
		List = configList,
		Default = selectedConfig,
		Flag = "__config_dropdown",
		Callback = function(val)
			selectedConfig = val
		end,
	})

	local function refreshList()
		configList = self:GetConfigList()
		configDropdown:Refresh(configList, false)
		selectedConfig = configDropdown:Get()
	end

	groupbox:AddTextbox({
		Text = "Config Name",
		Placeholder = "Enter name...",
		Flag = "__config_name_input",
		Callback = function(txt)
			newConfigName = txt
		end,
	})

	groupbox:AddButton({
		Text = "Create / Save Config",
		Callback = function()
			local target = (newConfigName ~= "" and newConfigName) or selectedConfig
			if self:Save(target) then
				refreshList()
			end
		end,
		})

	groupbox:AddButton({
		Text = "Load Config",
		Callback = function()
			self:Load(selectedConfig)
		end,
		})

	groupbox:AddButton({
		Text = "Overwrite Selected Config",
		Callback = function()
			if selectedConfig and selectedConfig ~= "" then
				self:Save(selectedConfig)
			end
			end,
		})

	groupbox:AddButton({
		Text = "Delete Config",
		Risky = true,
		Callback = function()
			if selectedConfig and selectedConfig ~= "" then
				self:Delete(selectedConfig)
				refreshList()
			end
			end,
		})

	groupbox:AddButton({
		Text = "Refresh Config List",
		Callback = function()
			refreshList()
		end,
		})

	groupbox:AddToggle({
		Text = "Autoload Selected Config",
		Default = false,
		Flag = "__config_autoload",
		Callback = function(state)
			if state and selectedConfig ~= "" then
				safeWriteFile(SettingsManager.Folder .. "/autoload.txt", selectedConfig)
			else
				safeDeleteFile(SettingsManager.Folder .. "/autoload.txt")
			end
			end,
		})
end

function SaveManager:CheckAutoload()
	local autoloadConfig = safeReadFile(SettingsManager.Folder .. "/autoload.txt")
	if autoloadConfig and autoloadConfig ~= "" then
		task.spawn(function()
			task.wait(0.5)
			self:Load(autoloadConfig)
		end)
	end
end

--============================================================================--
-- THEME MANAGER
--============================================================================--
local ThemeManager = SettingsManager.ThemeManager

ThemeManager.BuiltInThemes = {
	["Default Skeet"] = {
		FontColor       = Color3.fromRGB(230, 230, 235),
		MainColor       = Color3.fromRGB(24, 24, 27),
		AccentColor     = Color3.fromRGB(168, 219, 95),
		BackgroundColor = Color3.fromRGB(28, 28, 32),
		OutlineColor    = Color3.fromRGB(0, 0, 0),
	},
	["Skeet Light"] = {
		FontColor       = Color3.fromRGB(40, 40, 45),
		MainColor       = Color3.fromRGB(225, 225, 230),
		AccentColor     = Color3.fromRGB(30, 120, 210),
		BackgroundColor = Color3.fromRGB(244, 244, 248),
		OutlineColor    = Color3.fromRGB(120, 120, 130),
	},
	["Midnight Blue"] = {
		FontColor       = Color3.fromRGB(220, 230, 245),
		MainColor       = Color3.fromRGB(18, 22, 32),
		AccentColor     = Color3.fromRGB(64, 140, 255),
		BackgroundColor = Color3.fromRGB(14, 16, 24),
		OutlineColor    = Color3.fromRGB(5, 5, 10),
	},
	["Crimson Dark"] = {
		FontColor       = Color3.fromRGB(240, 230, 230),
		MainColor       = Color3.fromRGB(26, 20, 22),
		AccentColor     = Color3.fromRGB(235, 60, 80),
		BackgroundColor = Color3.fromRGB(20, 15, 16),
		OutlineColor    = Color3.fromRGB(10, 5, 5),
	},
	["Amethyst Violet"] = {
		FontColor       = Color3.fromRGB(240, 235, 245),
		MainColor       = Color3.fromRGB(25, 20, 30),
		AccentColor     = Color3.fromRGB(175, 95, 245),
		BackgroundColor = Color3.fromRGB(18, 14, 22),
		OutlineColor    = Color3.fromRGB(8, 5, 12),
	},
}

function ThemeManager:SetLibrary(lib)
	SettingsManager.Library = lib
end

function ThemeManager:ApplyTheme(themeData)
	if not SettingsManager.Library then return end
	SettingsManager.Library:SetTheme(themeData)
end

--============================================================================--
-- CUSTOM THEME PRESETS (save / load / delete own combinations)
--============================================================================--
local ThemePresetFolder = "SkeetwareThemes"

function ThemeManager:GetThemePresetFolder()
	return ThemePresetFolder
end

function ThemeManager:GetPresetList()
	local files = {}
	if typeof(listfiles) == "function" then
		checkFolder(ThemePresetFolder)
		local ok, res = pcall(listfiles, ThemePresetFolder)
		if ok and typeof(res) == "table" then
			for _, file in ipairs(res) do
				local name = file:match("([^/\\]+)%.theme%.json$")
				if name then table.insert(files, name) end
			end
		end
	end
	table.sort(files)
	return files
end

-- Serializes a theme table (Color3 values) into a compact JSON string
function ThemeManager:EncodeTheme(themeData)
	local out = {}
	for k, v in pairs(themeData or {}) do
		if typeof(v) == "Color3" then out[k] = encodeValue(v) end
	end
	local ok, json = pcall(function() return HttpService:JSONEncode(out) end)
	if ok then return json end
	return nil
end

-- Deserializes a theme JSON string back into { FontColor = Color3, ... }
function ThemeManager:DecodeTheme(json)
	if not json or json:gsub(" ", "") == "" then return nil end
	local ok, decoded = pcall(function() return HttpService:JSONDecode(json) end)
	if not ok or typeof(decoded) ~= "table" then return nil end
	local out = {}
	for k, v in pairs(decoded) do
		if k == "FontColor" or k == "MainColor" or k == "AccentColor" or k == "BackgroundColor" or k == "OutlineColor" then
			local col = decodeValue(v)
			if typeof(col) == "Color3" then out[k] = col end
		end
	end
	if next(out) then return out end
	return nil
end

function ThemeManager:SavePreset(name, themeData)
	if not name or name:gsub(" ", "") == "" then
		if SettingsManager.Library then
			SettingsManager.Library:Notify({ Title = "Theme Manager", Text = "Please enter a valid preset name.", Duration = 3 })
		end
		return false
	end
	local json = self:EncodeTheme(themeData)
	if not json then
		if SettingsManager.Library then
			SettingsManager.Library:Notify({ Title = "Theme Manager", Text = "Could not encode the current theme.", Duration = 3 })
		end
		return false
	end
	checkFolder(ThemePresetFolder)
	safeWriteFile(ThemePresetFolder .. "/" .. name .. ".theme.json", json)
	if SettingsManager.Library then
		SettingsManager.Library:Notify({ Title = "Theme Manager", Text = string.format("Saved theme preset '%s'.", name), Duration = 3 })
	end
	return true
end

function ThemeManager:LoadPreset(name)
	if not name or name:gsub(" ", "") == "" then return nil end
	local raw = safeReadFile(ThemePresetFolder .. "/" .. name .. ".theme.json")
	local themeData = self:DecodeTheme(raw)
	if themeData then
		self:ApplyTheme(themeData)
		return themeData
	end
	if SettingsManager.Library then
		SettingsManager.Library:Notify({ Title = "Theme Manager", Text = string.format("Could not load theme preset '%s'.", name), Duration = 3 })
	end
	return nil
end

function ThemeManager:DeletePreset(name)
	if not name or name:gsub(" ", "") == "" then return false end
	safeDeleteFile(ThemePresetFolder .. "/" .. name .. ".theme.json")
	if SettingsManager.Library then
		SettingsManager.Library:Notify({ Title = "Theme Manager", Text = string.format("Deleted theme preset '%s'.", name), Duration = 3 })
	end
	return true
end

--============================================================================--
-- THEME IMPORT / EXPORT (share via clipboard or pasted JSON / files)
--============================================================================--
function ThemeManager:ExportClipboard(themeData)
	local json = self:EncodeTheme(themeData)
	if not json then return false, nil end
	local copied = false
	if typeof(setclipboard) == "function" then
		copied = pcall(setclipboard, json)
	elseif typeof(toclipboard) == "function" then
		copied = pcall(toclipboard, json)
	end
	return copied, json
end

function ThemeManager:ImportClipboard()
	local text = nil
	if typeof(getclipboard) == "function" then
		local ok, res = pcall(getclipboard)
		if ok and typeof(res) == "string" and res ~= "" then text = res end
	end
	if not text then return nil end
	return self:DecodeTheme(text)
end

--============================================================================--
-- RANDOM THEME GENERATOR
--============================================================================--
function ThemeManager:GenerateRandomTheme()
	local hue = math.random()
	local accent = Color3.fromHSV(hue, 0.78, 0.95)
	-- Dark, hue-tinted surfaces derived from the same random hue
	local main     = Color3.fromHSV(hue, 0.22, 0.16)
	local bg       = Color3.fromHSV(hue, 0.28, 0.12)
	local outline  = Color3.fromRGB(0, 0, 0)
	local font     = Color3.fromRGB(236, 236, 240)
	return {
		FontColor       = font,
		MainColor       = main,
		AccentColor     = accent,
		BackgroundColor = bg,
		OutlineColor    = outline,
	}
end

function ThemeManager:BuildThemeSection(groupbox)
	local themeNames = {}
	for name in pairs(self.BuiltInThemes) do
		table.insert(themeNames, name)
	end
	table.sort(themeNames)

	local currentCustomTheme = {
		FontColor       = SettingsManager.Library.Theme.Text,
		MainColor       = SettingsManager.Library.Theme.GroupTop,
		AccentColor     = SettingsManager.Library.Theme.Accent1,
		BackgroundColor = SettingsManager.Library.Theme.MainTop,
		OutlineColor    = SettingsManager.Library.Theme.OuterBorder,
	}

	local pickers = {}
	local previewWindow = nil
	local newPresetName  = ""
	local selectedPreset = ""
	local importedJson   = ""

	-- Theme Preview Function
	local function showThemePreview(themeData)
		if not SettingsManager.Library then return end
		
		-- Close existing preview
		if previewWindow then
			if previewWindow.Root then previewWindow.Root:Destroy() end
			previewWindow = nil
		end
		
		local lib = SettingsManager.Library
		local screenGui = lib.ScreenGui
		
		-- Simple preview window (without complex border system for compatibility)
		local previewOuter = Instance.new("Frame")
		previewOuter.Size = UDim2.fromOffset(320, 280)
		previewOuter.Position = UDim2.fromOffset(0.5, -160, 0.5, -140)
		previewOuter.AnchorPoint = Vector2.new(0.5, 0.5)
		previewOuter.BackgroundColor3 = themeData.OutlineColor
		previewOuter.BorderSizePixel = 0
		previewOuter.ZIndex = 9995
		previewOuter.Parent = screenGui
		
		local previewInner = Instance.new("Frame")
		previewInner.Size = UDim2.new(1, -2, 1, -2)
		previewInner.Position = UDim2.fromOffset(1, 1)
		previewInner.BackgroundColor3 = themeData.BackgroundColor
		previewInner.BorderSizePixel = 0
		previewInner.Parent = previewOuter
		
		-- Simple gradient bar
		local gradientBar = Instance.new("Frame")
		gradientBar.Size = UDim2.new(1, 0, 0, 2)
		gradientBar.Position = UDim2.fromOffset(0, 0)
		gradientBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		gradientBar.BorderSizePixel = 0
		gradientBar.ZIndex = 10
		gradientBar.Parent = previewInner
		
		local gradient = Instance.new("UIGradient")
		gradient.Rotation = 0
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.00, Color3.fromRGB(54, 163, 247)),
			ColorSequenceKeypoint.new(0.20, Color3.fromRGB(98, 216, 247)),
			ColorSequenceKeypoint.new(0.40, Color3.fromRGB(168, 219, 95)),
			ColorSequenceKeypoint.new(0.60, Color3.fromRGB(247, 184, 92)),
			ColorSequenceKeypoint.new(0.80, Color3.fromRGB(247, 104, 181)),
			ColorSequenceKeypoint.new(1.00, Color3.fromRGB(184, 119, 247)),
		})
		gradient.Parent = gradientBar
		
		-- Preview title
		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(1, 0, 0, 24)
		title.Position = UDim2.fromOffset(0, 4)
		title.BackgroundTransparency = 1
		title.Font = lib.Theme.FontBold
		title.TextSize = lib.Theme.FontSize + 1
		title.TextColor3 = themeData.FontColor
		title.Text = "THEME PREVIEW"
		title.TextXAlignment = Enum.TextXAlignment.Center
		title.ZIndex = 10
		title.Parent = previewInner
		
		-- Preview content area
		local previewContent = Instance.new("Frame")
		previewContent.Size = UDim2.new(1, -16, 1, -36)
		previewContent.Position = UDim2.fromOffset(8, 28)
		previewContent.BackgroundTransparency = 1
		previewContent.Parent = previewInner
		
		-- Sample toggle
		local sampleToggle = Instance.new("Frame")
		sampleToggle.Size = UDim2.new(1, 0, 0, 20)
		sampleToggle.Position = UDim2.fromOffset(0, 0)
		sampleToggle.BackgroundTransparency = 1
		sampleToggle.Parent = previewContent
		
		local toggleBox = Instance.new("Frame")
		toggleBox.Size = UDim2.fromOffset(14, 14)
		toggleBox.Position = UDim2.fromOffset(0, 3)
		toggleBox.BackgroundColor3 = themeData.AccentColor
		toggleBox.BorderSizePixel = 0
		toggleBox.Parent = sampleToggle
		
		local toggleCorner = Instance.new("UICorner")
		toggleCorner.CornerRadius = UDim.new(0, 2)
		toggleCorner.Parent = toggleBox
		
		local toggleLabel = Instance.new("TextLabel")
		toggleLabel.Size = UDim2.new(1, -20, 1, 0)
		toggleLabel.Position = UDim2.fromOffset(20, 0)
		toggleLabel.BackgroundTransparency = 1
		toggleLabel.Font = lib.Theme.Font
		toggleLabel.TextSize = lib.Theme.FontSize
		toggleLabel.TextColor3 = themeData.FontColor
		toggleLabel.Text = "Sample Toggle"
		toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
		toggleLabel.Parent = sampleToggle
		
		-- Sample button
		local sampleButton = Instance.new("Frame")
		sampleButton.Size = UDim2.new(1, 0, 0, 24)
		sampleButton.Position = UDim2.fromOffset(0, 24)
		sampleButton.BackgroundColor3 = themeData.MainColor
		sampleButton.BorderSizePixel = 1
		sampleButton.BorderColor3 = themeData.OutlineColor
		sampleButton.Parent = previewContent
		
		local buttonLabel = Instance.new("TextLabel")
		buttonLabel.Size = UDim2.new(1, 0, 1, 0)
		buttonLabel.BackgroundTransparency = 1
		buttonLabel.Font = lib.Theme.FontBold
		buttonLabel.TextSize = lib.Theme.FontSize
		buttonLabel.TextColor3 = themeData.FontColor
		buttonLabel.Text = "Sample Button"
		buttonLabel.ZIndex = 2
		buttonLabel.Parent = sampleButton
		
		-- Close button
		local closeBtn = Instance.new("TextButton")
		closeBtn.Size = UDim2.fromOffset(24, 24)
		closeBtn.Position = UDim2.new(1, -28, 0, 4)
		closeBtn.BackgroundTransparency = 1
		closeBtn.Text = "✕"
		closeBtn.Font = lib.Theme.FontBold
		closeBtn.TextSize = lib.Theme.FontSize + 2
		closeBtn.TextColor3 = Color3.fromRGB(165, 165, 180)
		closeBtn.ZIndex = 15
		closeBtn.Parent = previewInner
		
		closeBtn.MouseButton1Click:Connect(function()
			if previewWindow and previewWindow.Root then
				previewWindow.Root:Destroy()
				previewWindow = nil
			end
		end)
		
		-- Apply button
		local applyBtn = Instance.new("TextButton")
		applyBtn.Size = UDim2.new(1, -16, 0, 24)
		applyBtn.Position = UDim2.fromOffset(8, -32)
		applyBtn.BackgroundColor3 = themeData.AccentColor
		applyBtn.BorderSizePixel = 1
		applyBtn.BorderColor3 = themeData.OutlineColor
		applyBtn.Text = "Apply Theme"
		applyBtn.Font = lib.Theme.FontBold
		applyBtn.TextSize = lib.Theme.FontSize
		applyBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
		applyBtn.ZIndex = 10
		applyBtn.Parent = previewInner
		
		local applyCorner = Instance.new("UICorner")
		applyCorner.CornerRadius = UDim.new(0, 4)
		applyCorner.Parent = applyBtn
		
		applyBtn.MouseButton1Click:Connect(function()
			self:ApplyTheme(themeData)
			for prop, col in pairs(themeData) do
				currentCustomTheme[prop] = col
				if pickers[prop] and pickers[prop].Set then
					pickers[prop]:Set(col)
				end
			end
			if previewWindow and previewWindow.Root then
				previewWindow.Root:Destroy()
				previewWindow = nil
			end
		end)
		
		previewWindow = { Root = previewOuter }
	end

	groupbox:AddDropdown({
		Text = "Theme Preset",
		List = themeNames,
		Default = "Default Skeet",
		Flag = "__theme_preset_dropdown",
		Callback = function(themeName)
			local preset = self.BuiltInThemes[themeName]
			if preset then
				self:ApplyTheme(preset)
				for prop, col in pairs(preset) do
					currentCustomTheme[prop] = col
					if pickers[prop] and pickers[prop].Set then
						pickers[prop]:Set(col)
					end
				end
			end
		end,
	})
	
	-- Add a button to preview current theme
	groupbox:AddButton({
		Text = "Preview Current Theme",
		Callback = function()
			showThemePreview(currentCustomTheme)
		end,
	})

	-- Dark / Light Mode quick switch between preset dark & light themes
	groupbox:AddToggle({
		Text = "Light Mode",
		Default = false,
		Flag = "__theme_lightmode",
		Callback = function(state)
			local preset = self.BuiltInThemes[state and "Skeet Light" or "Default Skeet"]
			if preset then
				self:ApplyTheme(preset)
				for prop, col in pairs(preset) do
					currentCustomTheme[prop] = col
					if pickers[prop] and pickers[prop].Set then
						pickers[prop]:Set(col)
					end
				end
				showThemePreview(preset)
			end
		end,
	})

	-- Random Theme Generator
	groupbox:AddButton({
		Text = "Generate Random Theme",
		Callback = function()
			local td = self:GenerateRandomTheme()
			if td then
				self:ApplyTheme(td)
				for prop, col in pairs(td) do
					currentCustomTheme[prop] = col
					if pickers[prop] and pickers[prop].Set then
						pickers[prop]:Set(col)
					end
				end
				showThemePreview(td)
			end
		end,
	})

	-- Custom Theme Presets (save your own theme combinations as named files)
	groupbox:AddTextbox({
		Text = "Preset Name",
		Placeholder = "Enter name...",
		Flag = "__theme_preset_name",
		Callback = function(txt)
			newPresetName = txt
		end,
	})

	local presetDropdown = groupbox:AddDropdown({
		Text = "My Presets",
		List = self:GetPresetList(),
		Default = selectedPreset,
		Flag = "__theme_preset_list",
		Callback = function(val)
			selectedPreset = val
		end,
	})

	local function refreshPresets()
		local lst = self:GetPresetList()
		presetDropdown:Refresh(lst, false)
		selectedPreset = presetDropdown:Get()
	end

	groupbox:AddButton({
		Text = "Save Current Theme",
		Callback = function()
			local target = (newPresetName ~= "" and newPresetName) or selectedPreset
			if self:SavePreset(target, currentCustomTheme) then
				refreshPresets()
			end
		end,
	})

	groupbox:AddButton({
		Text = "Load Preset",
		Callback = function()
			if selectedPreset and selectedPreset ~= "" then
				local td = self:LoadPreset(selectedPreset)
				if td then
					for prop, col in pairs(td) do
						currentCustomTheme[prop] = col
						if pickers[prop] and pickers[prop].Set then
							pickers[prop]:Set(col)
						end
					end
				end
			end
		end,
	})

	groupbox:AddButton({
		Text = "Delete Preset",
		Risky = true,
		Callback = function()
			if selectedPreset and selectedPreset ~= "" then
				self:DeletePreset(selectedPreset)
				refreshPresets()
			end
		end,
	})

	-- Theme Import / Export (share themes via clipboard or pasted JSON / files)
	groupbox:AddButton({
		Text = "Export Theme (Clipboard)",
		Callback = function()
			local ok, json = self:ExportClipboard(currentCustomTheme)
			if SettingsManager.Library then
				SettingsManager.Library:Notify({
					Title = "Theme Manager",
					Text = ok and "Theme JSON copied to clipboard!" or "Clipboard not supported by this executor.",
					Duration = 3,
					Type = ok and "Success" or "Warning",
				})
			end
		end,
	})

	groupbox:AddButton({
		Text = "Import Theme (Clipboard)",
		Callback = function()
			local td = self:ImportClipboard()
			if td then
				for prop, col in pairs(td) do
					currentCustomTheme[prop] = col
					if pickers[prop] and pickers[prop].Set then
						pickers[prop]:Set(col)
					end
				end
				showThemePreview(td)
				if SettingsManager.Library then
					SettingsManager.Library:Notify({ Title = "Theme Manager", Text = "Theme imported from clipboard!", Duration = 3, Type = "Success" })
				end
			elseif SettingsManager.Library then
				SettingsManager.Library:Notify({
					Title = "Theme Manager",
					Text = "No valid theme in clipboard. Export one first or paste JSON below.",
					Duration = 3,
					Type = "Warning",
				})
			end
		end,
	})

	groupbox:AddTextbox({
		Text = "Import Theme (Paste JSON)",
		Placeholder = "Paste exported theme JSON...",
		Flag = "__theme_import_json",
		Callback = function(txt)
			importedJson = txt
		end,
	})

	groupbox:AddButton({
		Text = "Apply Pasted Theme",
		Callback = function()
			local td = self:DecodeTheme(importedJson)
			if td then
				for prop, col in pairs(td) do
					currentCustomTheme[prop] = col
					if pickers[prop] and pickers[prop].Set then
						pickers[prop]:Set(col)
					end
				end
				showThemePreview(td)
				if SettingsManager.Library then
					SettingsManager.Library:Notify({ Title = "Theme Manager", Text = "Theme applied from JSON!", Duration = 3, Type = "Success" })
				end
			elseif SettingsManager.Library then
				SettingsManager.Library:Notify({ Title = "Theme Manager", Text = "Invalid theme JSON — cannot apply.", Duration = 3, Type = "Warning" })
			end
		end,
	})

	-- Five Customizable Theme Colorpickers:
	-- "FontColor", "MainColor", "AccentColor", "BackgroundColor", "OutlineColor"
	pickers["FontColor"] = groupbox:AddColorpicker({
		Text = "Font Color",
		Default = currentCustomTheme.FontColor,
		Flag = "__theme_FontColor",
		Callback = function(col)
			currentCustomTheme.FontColor = col
			SettingsManager.Library:SetThemeColor("FontColor", col)
		end,
	})

	pickers["MainColor"] = groupbox:AddColorpicker({
		Text = "Main Color",
		Default = currentCustomTheme.MainColor,
		Flag = "__theme_MainColor",
		Callback = function(col)
			currentCustomTheme.MainColor = col
			SettingsManager.Library:SetThemeColor("MainColor", col)
		end,
	})

	pickers["AccentColor"] = groupbox:AddColorpicker({
		Text = "Accent Color",
		Default = currentCustomTheme.AccentColor,
		Flag = "__theme_AccentColor",
		Callback = function(col)
			currentCustomTheme.AccentColor = col
			SettingsManager.Library:SetThemeColor("AccentColor", col)
		end,
	})

	pickers["BackgroundColor"] = groupbox:AddColorpicker({
		Text = "Background Color",
		Default = currentCustomTheme.BackgroundColor,
		Flag = "__theme_BackgroundColor",
		Callback = function(col)
			currentCustomTheme.BackgroundColor = col
			SettingsManager.Library:SetThemeColor("BackgroundColor", col)
		end,
	})

	pickers["OutlineColor"] = groupbox:AddColorpicker({
		Text = "Outline Color",
		Default = currentCustomTheme.OutlineColor,
		Flag = "__theme_OutlineColor",
		Callback = function(col)
			currentCustomTheme.OutlineColor = col
			SettingsManager.Library:SetThemeColor("OutlineColor", col)
		end,
	})

	-- Menu Keybind (rebinds the Library.ToggleKey used to open/close the menu)
	groupbox:AddKeybindPicker({
		Text = "Menu Keybind",
		Default = Enum.KeyCode.RightControl,
		Mode = "Toggle",
		Callback = function(active)
			local lib = SettingsManager.Library
			if not lib then return end
			if active then
				local bound = lib.Flags and lib.Flags["__menu_keybind"]
				if typeof(bound) == "table" and typeof(bound.Key) == "EnumItem" then
					lib.ToggleKey = bound.Key
				end
			end
		end,
		Flag = "__menu_keybind",
	})

	-- Additional Action Buttons
	groupbox:AddButton({
		Text = "Unload Script",
		Risky = true,
		Callback = function()
			local lib = SettingsManager.Library
			if lib then
				lib:Notify({ Title = "Settings Manager", Text = "Script unloaded successfully!", Duration = 2 })
				task.delay(0.6, function()
					if lib.Unload and not lib.Unloaded then
						lib:Unload()
					end
				end)
			end
		end,
	})

	groupbox:AddButton({
		Text = "Copy Server ID",
		Callback = function()
			local lib = SettingsManager.Library
			local jobId = game.JobId
			if jobId == nil or jobId == "" then
				if lib then
					lib:Notify({ Title = "Settings Manager", Text = "No server ID available (Studio or reserved server).", Duration = 3 })
				end
				return
			end
			local copied = false
			if typeof(setclipboard) == "function" then
				copied = pcall(setclipboard, jobId)
			elseif typeof(toclipboard) == "function" then
				copied = pcall(toclipboard, jobId)
			end
			if lib then
				lib:Notify({
					Title = "Settings Manager",
					Text = copied and ("Server ID copied: " .. jobId) or "Clipboard is not supported by this executor.",
					Duration = 3,
				})
			end
		end,
	})

	groupbox:AddButton({
		Text = "Copy Join Link",
		Callback = function()
			local lib = SettingsManager.Library
			local jobId = game.JobId
			if jobId == nil or jobId == "" then
				if lib then
					lib:Notify({ Title = "Settings Manager", Text = "No server ID available (Studio or reserved server).", Duration = 3 })
				end
				return
			end
			local joinLink = string.format("roblox://experiences/start?placeId=%d&gameInstanceId=%s", game.PlaceId, jobId)
			local copied = false
			if typeof(setclipboard) == "function" then
				copied = pcall(setclipboard, joinLink)
			elseif typeof(toclipboard) == "function" then
				copied = pcall(toclipboard, joinLink)
			end
			if lib then
				lib:Notify({
					Title = "Settings Manager",
					Text = copied and "Join link copied to clipboard!" or "Clipboard is not supported by this executor.",
					Duration = 3,
				})
			end
		end,
	})

	groupbox:AddButton({
		Text = "Rejoin Server",
		Callback = function()
			local lib = SettingsManager.Library
			if lib then
				lib:Notify({ Title = "Settings Manager", Text = "Rejoining server...", Duration = 2 })
			end
			task.spawn(function()
				for i = 3, 1, -1 do
					if lib then
						lib:Notify({ Title = "Settings Manager", Text = string.format("Rejoining in %d second(s)...", i), Duration = 1 })
					end
					task.wait(1)
				end
				local ok, err = pcall(function()
					game:GetService("TeleportService"):Teleport(game.PlaceId, game:GetService("Players").LocalPlayer)
				end)
				if not ok and lib then
					lib:Notify({ Title = "Settings Manager", Text = "Rejoin failed: " .. tostring(err), Duration = 3 })
				end
			end)
		end,
	})

	-- Open/Close Settings Manager (toggle button that flips its own text)
	local settingsWindow = nil
	local openCloseBtn = nil

	local function setSettingsBtnText(text)
		if openCloseBtn then
			local lbl = openCloseBtn:FindFirstChild("ButtonLabel", true)
			if lbl then lbl.Text = text end
		end
	end

	openCloseBtn = groupbox:AddButton({
		Text = "Open Settings Manager",
		Callback = function()
			local lib = SettingsManager.Library
			if not lib or not lib.CreateWindow then return end

			-- Already open → toggle it closed
			if settingsWindow and settingsWindow.Root then
				if settingsWindow.Root.Visible then
					settingsWindow.Root:Destroy()
					settingsWindow = nil
					SettingsManager._SettingsWindow = nil
					setSettingsBtnText("Open Settings Manager")
					if lib then
						lib:Notify({ Title = "Settings Manager", Text = "Settings manager closed.", Duration = 2 })
					end
					return
				else
					-- Hidden by the menu key (Insert) → just bring it back
					settingsWindow.Root.Visible = true
					setSettingsBtnText("Close Settings Manager")
					return
				end
			end

			if lib then
				lib:Notify({ Title = "Settings Manager", Text = "Settings manager opened!", Duration = 1 })
			end
			local sWindow = lib:CreateWindow({ Title = "Skeetware Settings", Size = UDim2.fromOffset(520, 420) })
			settingsWindow = sWindow
			SettingsManager._SettingsWindow = sWindow
			local sTab = sWindow:AddTab("Settings", lib.Icons and lib.Icons.Settings or nil)
			local sGroup = sTab:AddGroupbox({ Title = "Settings" })
			SaveManager:BuildConfigSection(sGroup)
			ThemeManager:BuildThemeSection(sGroup)
			setSettingsBtnText("Close Settings Manager")
		end,
	})
end

return SettingsManager
