--[[
	══════════════════════════════════════════════════════════════════════════════
	  SKEETWARE UI v6.0 — LOCAL LOADER WITH ANIMATED LOGO
	  • Loads UI library and settings manager from local files
	  • Features animated logo from SkeetUIkl GitHub repository
	  • Clean, practical script structure ready for customization
	  • Configs + Themes fully integrated
	  • Menu key: INSERT (rebindable in Settings)
	══════════════════════════════════════════════════════════════════════════════
--]]

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

--══════════════════════════════════════════════════════════════════════════════
-- LOCAL LOADER WITH ANIMATED LOGO SUPPORT
local Library = loadstring(readfile("ui.lua"))()
local SettingsManager = loadstring(readfile("settingsmanager.luau"))()

-- Expose globally
if getgenv then
	getgenv().Skeetware = Library
	getgenv().SkeetwareSettings = SettingsManager
end

--════════════════════════════ WIRE UP SETTINGS MANAGER ═══════════════════════
SettingsManager.SaveManager:SetLibrary(Library)
SettingsManager.ThemeManager:SetLibrary(Library)
SettingsManager.SaveManager:SetFolder("SkeetwareConfigs")

--══════════════════════════ MAIN WINDOW WITH ANIMATED LOGO ════════════════════════════
local Window = Library:CreateWindow({
	Title = "Skeetware | Script",
	Size = UDim2.fromOffset(720, 520),
})

-- The animated logo from GitHub is automatically loaded in the window header
-- Logo URL: https://github.com/7xtrnl/SkeetUIkl/raw/refs/heads/main/new.gif
-- Fallback icon is used if the animated logo fails to load

local CombatTab = Window:AddTab("Combat", Library.Icons.Swords)
local VisualsTab = Window:AddTab("Visuals", Library.Icons.Eye)
local MiscTab = Window:AddTab("Misc", Library.Icons.Settings)
local SettingsTab = Window:AddTab("Settings", Library.Icons.Palette)

--══════════════════════════ COMBAT TAB ═════════════════════════════
local aimGroup = CombatTab:AddGroupbox({ Title = "Aimbot", Side = "left" })
local weaponGroup = CombatTab:AddGroupbox({ Title = "Weapon", Side = "right" })

-- Aimbot settings
local aimEnabled = aimGroup:AddToggle({
	Text = "Enable Aimbot",
	Default = false,
	Flag = "aim_enabled",
	Callback = function(state)
		Library:Notify({
			Title = "Aimbot",
			Text = state and "Enabled" or "Disabled",
			Duration = 2,
			Type = state and "Success" or "Info",
		})
	end,
})

aimGroup:AddSlider({
	Text = "FOV",
	Min = 10,
	Max = 180,
	Default = 90,
	Suffix = "°",
	Flag = "aim_fov",
})

aimGroup:AddSlider({
	Text = "Smoothness",
	Min = 1,
	Max = 20,
	Default = 5,
	Suffix = "",
	Flag = "aim_smoothness",
})

aimGroup:AddDropdown({
	Text = "Target Part",
	Options = { "Head", "UpperTorso", "Torso", "HumanoidRootPart" },
	Default = "Head",
	Flag = "aim_part",
})

-- Weapon settings
weaponGroup:AddToggle({ Text = "No Recoil", Default = false, Flag = "weapon_norecoil" })
weaponGroup:AddToggle({ Text = "No Spread", Default = false, Flag = "weapon_nospread" })
weaponGroup:AddToggle({ Text = "Infinite Ammo", Default = false, Flag = "weapon_infammo" })
weaponGroup:AddSlider({ Text = "Fire Rate", Min = 0, Max = 100, Default = 0, Suffix = "%", Flag = "weapon_firerate" })

--══════════════════════════ VISUALS TAB ═════════════════════════════
local espGroup = VisualsTab:AddGroupbox({ Title = "ESP" })
local worldGroup = VisualsTab:AddGroupbox({ Title = "World", Side = "right" })

-- ESP settings
espGroup:AddToggle({ Text = "Enabled", Default = true, Flag = "esp_enabled" })
espGroup:AddToggle({ Text = "Box", Default = true, Flag = "esp_box" })
espGroup:AddToggle({ Text = "Name", Default = true, Flag = "esp_name" })
espGroup:AddToggle({ Text = "Health", Default = true, Flag = "esp_health" })
espGroup:AddToggle({ Text = "Distance", Default = true, Flag = "esp_distance" })
espGroup:AddToggle({ Text = "Tracers", Default = false, Flag = "esp_tracers" })
espGroup:AddSlider({ Text = "Max Distance", Min = 100, Max = 2000, Default = 1000, Suffix = " studs", Flag = "esp_maxdist" })

-- World settings
worldGroup:AddToggle({ Text = "Fullbright", Default = false, Flag = "world_fullbright" })
worldGroup:AddToggle({ Text = "No Fog", Default = false, Flag = "world_nofog" })
worldGroup:AddToggle({ Text = "Time Changer", Default = false, Flag = "world_time" })
worldGroup:AddSlider({ Text = "Time", Min = 0, Max = 24, Default = 12, Suffix = "h", Flag = "world_time_value" })

--══════════════════════════ MISC TAB ══════════════════════════════
local movementGroup = MiscTab:AddGroupbox({ Title = "Movement", Side = "left" })
local playerGroup = MiscTab:AddGroupbox({ Title = "Player", Side = "right" })

-- Movement settings
movementGroup:AddToggle({ Text = "Speed Hack", Default = false, Flag = "misc_speed" })
movementGroup:AddSlider({ Text = "Speed Multiplier", Min = 1, Max = 10, Default = 1, Suffix = "x", Flag = "misc_speed_value" })
movementGroup:AddToggle({ Text = "Jump Height", Default = false, Flag = "misc_jump" })
movementGroup:AddSlider({ Text = "Jump Power", Min = 50, Max = 200, Default = 50, Suffix = "", Flag = "misc_jump_value" })
movementGroup:AddToggle({ Text = "No Clip", Default = false, Flag = "misc_noclip" })

-- Player settings
playerGroup:AddToggle({ Text = "God Mode", Default = false, Flag = "misc_godmode" })
playerGroup:AddToggle({ Text = "Infinite Jump", Default = false, Flag = "misc_infjump" })
playerGroup:AddToggle({ Text = "Auto Jump", Default = false, Flag = "misc_autojump" })
playerGroup:AddButton({
	Text = "Reset Character",
	Callback = function()
		LocalPlayer.Character:Destroy()
	end,
})

--══════════════════════════ SETTINGS TAB ═════════════════════════════
local configGroup = SettingsTab:AddGroupbox({ Title = "Configs" })
local uiGroup = SettingsTab:AddGroupbox({ Title = "UI Settings", Side = "right" })

-- Config management
SettingsManager.SaveManager:BuildConfigSection(configGroup)

-- UI settings
SettingsManager.ThemeManager:BuildThemeSection(uiGroup)

--══════════════════════════ HUD & FINALIZE ═══════════════════════════
Library:CreateWatermark("Skeetware.cc | Animated Logo Loaded")

-- Cleanup on unload
Library.OnUnload = function()
	print("[Skeetware] Script unloaded successfully!")
end

-- Load saved config
SettingsManager.SaveManager:CheckAutoload()

Library:Notify({
	Title = "Skeetware",
	Text = "Script loaded with animated logo! Press INSERT to toggle menu.",
	Duration = 5,
	Type = "Success",
})
