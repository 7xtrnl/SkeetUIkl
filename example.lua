--[[
	══════════════════════════════════════════════════════════════════════════════
	  AXIOM UI — FULL FEATURE SHOWCASE / TEST SCRIPT
	  • Tests every component: toggles (+gear settings), sliders (+gear),
	    dropdowns (single & multi w/ gear), buttons (risky), colorpickers,
	    keybinds, textboxes, notifications, watermark & keybind list HUD
	  • Feature-Settings (gear icon) demo on aimbot, ESP & kill-aura
	  • Menu key: INSERT (rebindable in Settings tab)
	══════════════════════════════════════════════════════════════════════════════
--]]

-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

--══════════════════════════ LOAD LIBRARY + SETTINGS MANAGER ═══════════════════════════
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/7xtrnl/SkeetUIkl/refs/heads/main/ui.luau"))()
local SettingsManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/7xtrnl/SkeetUIkl/refs/heads/main/settingsmanager.luau"))()

if getgenv then
	getgenv().Axiom = Library
	getgenv().AxiomSettings = SettingsManager
end

SettingsManager.SaveManager:SetLibrary(Library)
SettingsManager.ThemeManager:SetLibrary(Library)
SettingsManager.SaveManager:SetFolder("AxiomConfigs")

--══════════════════════════ MAIN WINDOW ═══════════════════════════
local Window = Library:CreateWindow({
	Title = "axiom | feature test",
	Size = UDim2.fromOffset(720, 520),
})

local CombatTab  = Window:AddTab("Combat",  Library.Icons.Swords)
local VisualsTab = Window:AddTab("Visuals", Library.Icons.Eye)
local MiscTab    = Window:AddTab("Misc",    Library.Icons.Sliders)
local TestTab    = Window:AddTab("Components", Library.Icons.Layers)
local SettingsTab= Window:AddTab("Config",  Library.Icons.Palette)

--══════════════════════════ COMBAT — GEAR SETTINGS SHOWCASE ═══════════════════════════
local aimGroup = CombatTab:AddGroupbox({ Title = "Aimbot", Side = "left" })

-- Toggle WITH gear → deep-menu with nested sliders/dropdowns/toggles
aimGroup:AddToggle({
	Text = "Enable Aimbot",
	Default = false,
	Flag = "aim_enabled",
	GearTitle = "aimbot settings",
	Description = "click the gear icon for per-feature settings",
	Callback = function(state)
		Library:Notify({
			Title = "Aimbot",
			Text = state and "Enabled" or "Disabled",
			Duration = 2,
			Type = state and "Success" or "Info",
		})
	end,
	Settings = {
		{ Type = "Slider",   Text = "fov", Min = 10, Max = 180, Default = 90, Suffix = "°", Flag = "aim_fov" },
		{ Type = "Slider",   Text = "smoothing", Min = 1, Max = 20, Default = 5, Flag = "aim_smooth" },
		{ Type = "Dropdown", Text = "target part", Options = { "head", "torso", "arms", "legs" }, Default = "head", Flag = "aim_part" },
		{ Type = "Toggle",   Text = "team check", Default = true, Flag = "aim_teamcheck" },
		{ Type = "Toggle",   Text = "visible check", Default = true, Flag = "aim_vischeck" },
		{ Type = "Keybind",  Text = "aim hold key", Default = Enum.KeyCode.E, Mode = "Hold", Flag = "aim_key" },
		{ Type = "Button",   Text = "reset aimbot", Callback = function() print("aimbot reset") end },
	},
})

-- Slider WITH gear
aimGroup:AddSlider({
	Text = "Max Targets",
	Min = 1, Max = 12, Default = 3,
	Flag = "aim_maxtargets",
	GearTitle = "targeting rules",
	Description = "double-click the value to type a number",
	Settings = {
		{ Type = "Toggle", Text = "prioritize low hp", Default = true, Flag = "aim_lowhp" },
		{ Type = "Dropdown", Text = "sort mode", Options = { "distance", "health", "fov" }, Default = "distance", Flag = "aim_sort" },
	},
})

local weaponGroup = CombatTab:AddGroupbox({ Title = "Kill Aura", Side = "right" })

-- Multi-select dropdown WITH gear
weaponGroup:AddDropdown({
	Text = "Aura Filters",
	Multi = true,
	Options = { "players", "npcs", "animals", "vehicles", "bosses" },
	Flag = "aura_filters",
	GearTitle = "aura settings",
	Description = "multi-select dropdown with a gear deep-menu",
	Settings = {
		{ Type = "Slider", Text = "range", Min = 5, Max = 120, Default = 30, Suffix = " studs", Flag = "aura_range" },
		{ Type = "Slider", Text = "hits per second", Min = 1, Max = 20, Default = 6, Flag = "aura_rate" },
		{ Type = "Toggle", Text = "ignore downed", Default = false, Flag = "aura_ignore_downed" },
	},
})

weaponGroup:AddToggle({ Text = "No Recoil",    Default = false, Flag = "weapon_norecoil" })
weaponGroup:AddToggle({ Text = "No Spread",    Default = false, Flag = "weapon_nospread" })
weaponGroup:AddSlider({ Text = "Fire Rate",    Min = 0, Max = 100, Default = 0, Suffix = "%", Flag = "weapon_firerate" })

--══════════════════════════ VISUALS — GEAR ON ESP TOGGLES ═══════════════════════════
local espGroup = VisualsTab:AddGroupbox({ Title = "ESP", Side = "left" })
local worldGroup = VisualsTab:AddGroupbox({ Title = "World", Side = "right" })

espGroup:AddToggle({
	Text = "Enabled",
	Default = true,
	Flag = "esp_enabled",
	GearTitle = "esp settings",
	Description = "gear opens shared esp settings",
	Settings = {
		{ Type = "Slider",   Text = "draw distance", Min = 100, Max = 2000, Default = 1000, Suffix = " studs", Flag = "esp_maxdist" },
		{ Type = "Dropdown", Text = "outline style", Options = { "hard edge", "soft", "neon" }, Default = "hard edge", Flag = "esp_style" },
		{ Type = "Toggle",   Text = "hide teammates", Default = false, Flag = "esp_hideteam" },
	},
})
espGroup:AddToggle({ Text = "Box",         Default = true,  Flag = "esp_box" })
espGroup:AddToggle({ Text = "Name",        Default = true,  Flag = "esp_name" })
espGroup:AddToggle({ Text = "Health",      Default = true,  Flag = "esp_health" })
espGroup:AddToggle({ Text = "Tracers",     Default = false, Flag = "esp_tracers" })

-- Toggle with inline colorpicker + keybind (both attach next to the toggle)
espGroup:AddToggle({
	Text = "Colorful Tracers",
	Flag = "esp_tracer_color",
	GearTitle = "tracer settings",
	Settings = {
		{ Type = "Dropdown", Text = "thickness", Options = { "thin", "normal", "thick" }, Default = "normal", Flag = "esp_tracer_thick" },
	},
}):AddColorpicker({ Text = "Tracer Color", Default = Color3.fromRGB(168, 219, 95), Flag = "esp_tracer_col" })

worldGroup:AddToggle({ Text = "Fullbright",   Default = false, Flag = "world_fullbright" })
worldGroup:AddToggle({ Text = "No Fog",        Default = false, Flag = "world_nofog" })
worldGroup:AddSlider({ Text = "Time",          Min = 0, Max = 24, Default = 12, Suffix = "h", Flag = "world_time_value", GearWidth = 180, Settings = {
	{ Type = "Toggle", Text = "smooth cycle", Default = false, Flag = "world_timesmooth" },
} })

--══════════════════════════ MISC ═══════════════════════════
local movementGroup = MiscTab:AddGroupbox({ Title = "Movement", Side = "left" })
local playerGroup   = MiscTab:AddGroupbox({ Title = "Player",  Side = "right" })

movementGroup:AddToggle({ Text = "Speed Hack",       Default = false, Flag = "misc_speed" })
movementGroup:AddSlider({ Text = "Speed Multiplier", Min = 1, Max = 10, Default = 1, Suffix = "x", Flag = "misc_speed_value" })
movementGroup:AddToggle({ Text = "Jump Height",      Default = false, Flag = "misc_jump" })
movementGroup:AddSlider({ Text = "Jump Power",       Min = 50, Max = 200, Default = 50, Flag = "misc_jump_value" })
movementGroup:AddToggle({ Text = "No Clip",          Default = false, Flag = "misc_noclip" })

playerGroup:AddToggle({ Text = "God Mode",      Default = false, Flag = "misc_godmode" })
playerGroup:AddToggle({ Text = "Infinite Jump", Default = false, Flag = "misc_infjump" })
playerGroup:AddButton({
	Text = "Reset Character",
	Risky = true,
	Callback = function()
		if LocalPlayer.Character then LocalPlayer.Character:Destroy() end
	end,
})

--══════════════════════════ COMPONENTS TAB — everything on one page ═══════════════════════════
local leftCol  = TestTab:AddGroupbox({ Title = "All Controls", Side = "left" })
local rightCol = TestTab:AddGroupbox({ Title = "Inputs",       Side = "right" })

leftCol:AddButton({
	Text = "Ping Notification",
	Callback = function()
		Library:Notify({ Title = "Components", Text = "button clicked! notification test.", Duration = 3, Type = "Info" })
	end,
})
leftCol:AddButton({
	Text = "Success Notification",
	Callback = function()
		Library:Notify({ Title = "Components", Text = "success type notification", Duration = 3, Type = "Success" })
	end,
})
leftCol:AddButton({
	Text = "Danger Notification",
	Risky = true,
	Callback = function()
		Library:Notify({ Title = "Components", Text = "danger type notification", Duration = 3, Type = "Warning" })
	end,
})

leftCol:AddColorpicker({
	Text = "Standalone Colorpicker",
	Default = Color3.fromRGB(94, 158, 219),
	Flag = "test_cp",
	Callback = function(col) print("color:", col) end,
})

leftCol:AddKeybind({
	Text = "Standalone Keybind",
	Default = Enum.KeyCode.T,
	Mode = "Toggle",
	Flag = "test_key",
	Callback = function() end,
})

leftCol:AddDropdown({
	Text = "Single Select",
	Options = { "option a", "option b", "option c", "option d" },
	Default = "option a",
	Flag = "test_single",
	Callback = function(v) print("picked:", v) end,
})

leftCol:AddDropdown({
	Text = "Multi Select",
	Multi = true,
	Options = { "alpha", "beta", "gamma", "delta" },
	Flag = "test_multi",
	Callback = function(t) print("multi:", t) end,
})

rightCol:AddTextbox({
	Text = "Text Input",
	Placeholder = "type here...",
	Flag = "test_text",
	Callback = function(txt) print("text:", txt) end,
})

rightCol:AddSlider({
	Text = "Plain Slider",
	Min = 0, Max = 100, Default = 50, Suffix = "%",
	Flag = "test_plain_slider",
})

rightCol:AddSlider({
	Text = "Slider With Gear",
	Min = 0, Max = 500, Default = 120, Suffix = " pts",
	Flag = "test_geared_slider",
	GearTitle = "advanced slider options",
	Settings = {
		{ Type = "Toggle", Text = "clamp to grid",     Default = false, Flag = "test_grid" },
		{ Type = "Slider", Text = "grid size",         Min = 1, Max = 50, Default = 10, Flag = "test_gridsize" },
		{ Type = "Dropdown", Text = "round direction", Options = { "down", "nearest", "up" }, Default = "nearest", Flag = "test_round" },
		{ Type = "Button", Text = "reset to default",  Callback = function() print("slider reset") end },
	},
})

rightCol:AddToggle({
	Text = "Toggle With Gear + Keybind",
	Flag = "test_geared_toggle",
	GearTitle = "deep settings",
	Default = false,
	Settings = {
		{ Type = "Dropdown", Text = "mode", Options = { "literals", "spectral", "hybrid" }, Default = "hybrid", Flag = "test_mode" },
		{ Type = "Button",   Text = "print all flags", Callback = function()
			for k, v in pairs(Library.Flags) do print(k, "=", tostring(v)) end
		end },
	},
}):AddKeybind({ Text = "Hold", Default = Enum.KeyCode.G, Mode = "Hold", Flag = "test_hold_key" })

--══════════════════════════ SETTINGS TAB (configs + themes) ═══════════════════════════
local configGroup = SettingsTab:AddGroupbox({ Title = "Configs" })
local uiGroup     = SettingsTab:AddGroupbox({ Title = "UI Settings", Side = "right" })

SettingsManager.SaveManager:BuildConfigSection(configGroup)
SettingsManager.ThemeManager:BuildThemeSection(uiGroup)

--══════════════════════════ HUD & FINALIZE ═══════════════════════════
Library:CreateWatermark("axiom | feature test")
Library:CreateKeybindList()

-- EXPERIMENTAL: ESP Preview widget (drag + lock + live flag binding)
-- Remove this block to disable it cleanly.
do
local EspPreview = Library:CreateEspPreview({ Title = "esp preview", Width = 220, Height = 260 })
local function refreshPreview()
EspPreview:Set({
Box = Library.Flags.esp_box,
Name = Library.Flags.esp_name,
Health = Library.Flags.esp_health,
Distance = Library.Flags.esp_distance,
Color = Library.Flags.esp_tracer_col or Library.Theme.Accent1,
ShowName = "springtrap",
ShowDist = "82m",
HealthValue = 0.72,
FillTransparency = 0.35,
})
end
local espToggleFlag = Library.FlagRegistry.esp_enabled
if espToggleFlag then
-- Refresh once now and after config autoload kicks in
refreshPreview()
task.spawn(function() task.wait(1) refreshPreview() end)
end
end

Library.OnUnload = function()
	print("[Axiom] feature-test unloaded!")
end

SettingsManager.SaveManager:CheckAutoload()

Library:Notify({
	Title = "axiom",
	Text = "feature test loaded! press insert to toggle menu. look for the gear icons.",
	Duration = 5,
	Type = "Success",
})
