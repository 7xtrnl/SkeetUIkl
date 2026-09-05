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
			-- Exclude internal manager flags to prevent loops
			if not flag:match("^__config_") and not flag:match("^__theme_") then
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
		if SettingsManager.Library and SettingsManager.Library.Flags then
			SettingsManager.Library.Flags[flag] = val
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
	
	-- Menu KeybindPicker
	groupbox:AddKeybindPicker({
		Text = "Menu Keybind",
		Default = Enum.KeyCode.RightControl,
		Mode = "Toggle",
		Callback = function(active)
			if SettingsManager.Library and SettingsManager.Library.ToggleKey then
				SettingsManager.Library.ToggleKeyActive = active
			end
		end,
		Flag = "__menu_keybind",
	})
	
	-- Additional Action Buttons
	groupbox:AddButton({
		Text = "🧹 Unload Script",
		Risky = true,
		Callback = function()
			if SettingsManager.Library then
				Library.Unloaded = true
				Library:Notify({ Title = "Settings Manager", Text = "Script unloaded successfully!", Duration = 2 })
			end
		end,
	})
	
	groupbox:AddButton({
		Text = "↻ Rejoin Server",
		Callback = function()
			if SettingsManager.Library then
				SettingsManager.Library:Notify({ Title = "Settings Manager", Text = "Rejoining server...", Duration = 2 })
			end
			if getgenv then
				local genv = getgenv()
				if genv.syn and genv.syn.request then
					genv.syn.request({ Type = "RequestRebirth" })
				end
			end
			task.spawn(function()
				for i = 10, 1, -1 do
					if Library then Library:Notify({ Title = "Settings Manager", Text = string.format("Rejoining in %d seconds...", i), Duration = 1 }) end
					task.wait(1)
				end
				if getrenovate then getrenovate() elseif QueueOnTeleport then QueueOnTeleport() elseif syn then syn.queue_on_teleport("loadstring(game:HttpGet('https://your-repo/script.lua'))()") end
				game:Restart()
			end)
			end
		end,
	})
	
	groupbox:AddButton({
		Text = "🗂️ Open Settings Manager",
		Callback = function()
			if SettingsManager.Library then
				SettingsManager.Library:Notify({ Title = "Settings Manager", Text = "Settings manager opened!", Duration = 1 })
			end
			if SettingsManager.Library and SettingsManager.Library:CreateWindow then
				local sWindow = SettingsManager.Library:CreateWindow({ Title = "Skeetware Settings", Size = UDim2.fromOffset(520, 420) })
				local sTab = sWindow:AddTab("Settings", "⚙️")
				local sGroup = sTab:AddGroupbox("Settings")
					SaveManager:BuildConfigSection(sGroup)
					ThemeManager:BuildThemeSection(sGroup)
				end
		end,
		end,
	})
end

return SettingsManager
