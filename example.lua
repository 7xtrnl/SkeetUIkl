--[[
	══════════════════════════════════════════════════════════════════════════════
	  AXIOM UI v5.0 — EXECUTOR EXAMPLE / QUICKSTART
	  • Loads the UI library + settings manager straight from GitHub (up to date)
	  • Shows every component with the current API surface
	  • Configs (SaveManager) + Themes (ThemeManager) wired end to end
	  • Menu key: INSERT (rebindable in Settings → UI Settings → Menu Keybind)
	  Just run this whole file in your executor.
	══════════════════════════════════════════════════════════════════════════════
--]]

--══════════════════════════════ LOADER ═══════════════════════════════


local Library         = loadstring(game:HttpGet("https://raw.githubusercontent.com/7xtrnl/SkeetUIkl/refs/heads/main/skeet.luau"))()
local SettingsManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/7xtrnl/SkeetUIkl/refs/heads/main/settingsmanager.luau"))()

-- Expose globally so other scripts / the console can reach them
if getgenv then
	getgenv().Axiom         = Library
	getgenv().AxiomSettings = SettingsManager
	-- Legacy aliases (older scripts may still reference these)
	getgenv().Skeetware         = Library
	getgenv().SkeetwareSettings = SettingsManager
end

--══════════════════════ WIRE UP THE SETTINGS MANAGER ═══════════════════════
SettingsManager.SaveManager:SetLibrary(Library)
SettingsManager.ThemeManager:SetLibrary(Library)
SettingsManager.SaveManager:SetFolder("AxiomConfigs") -- config folder name

--══════════════════════════ WINDOW & TABS ════════════════════════════
local Window = Library:CreateWindow({
	Title = "axiom.cc | example",
	Size  = UDim2.fromOffset(720, 520),
})

local AimTab      = Window:AddTab("Aim",      Library.Icons.Crosshair)
local VisualsTab  = Window:AddTab("Visuals",  Library.Icons.Eye)
local SettingsTab = Window:AddTab("Settings", Library.Icons.Settings)

--═════════════════════════════ AIM TAB ═══════════════════════════════
local rageGroup = AimTab:AddGroupbox({ Title = "Ragebot", Side = "left"  })
local miscGroup = AimTab:AddGroupbox({ Title = "Misc",    Side = "right" })

-- Toggle with inline colorpicker + keybind (Hold mode via right-click menu)
local rageEnabled = rageGroup:AddToggle({
	Text     = "Enable Ragebot",
	Default  = false,
	Flag     = "rage_enabled",
	Callback = function(state)
		Library:Notify({
			Title    = "Ragebot",
			Text     = state and "Enabled" or "Disabled",
			Duration = 2,
			Type     = state and "Success" or "Info",
		})
	end,
})
rageEnabled:AddColorpicker({ Default = Color3.fromRGB(168, 219, 95), Flag = "rage_color" })
rageEnabled:AddKeybind({ Default = Enum.KeyCode.E, Mode = "Hold", Flag = "rage_key" })

-- Slider: drag, floating tooltip, click the value to type manually
rageGroup:AddSlider({
	Text     = "Field of View",
	Min      = 20,
	Max      = 360,
	Default  = 120,
	Suffix   = "°",
	Flag     = "rage_fov",
	Callback = function(value)
		-- use value here
	end,
})

-- Single-select dropdown
rageGroup:AddDropdown({
	Text     = "Target Part",
	Options  = { "Head", "UpperTorso", "Torso", "HumanoidRootPart" },
	Default  = "Head",
	Flag     = "rage_part",
	Callback = function(choice)
		-- use choice here
	end,
})

-- Multi-select dropdown (check icons, animated)
rageGroup:AddDropdown({
	Text     = "Hitboxes",
	Options  = { "Head", "Torso", "Arms", "Legs" },
	Multi    = true,
	Default  = { Head = true },
	Flag     = "rage_hitboxes",
	Callback = function(selected)
		-- selected = { Head = true, ... }
	end,
})

-- Textbox
miscGroup:AddTextbox({
	Text        = "Watermark Label",
	Placeholder = "type here...",
	Flag        = "misc_watermark_text",
	Callback    = function(text)
		-- use text here
	end,
})

-- Standalone keybind (click to capture, Esc/Backspace clears, right-click = mode)
miscGroup:AddKeybind({
	Text     = "Jump Bind",
	Default  = Enum.KeyCode.Space,
	Mode     = "Toggle",
	Flag     = "misc_jump",
	Callback = function(active)
		-- fires with true/false in Toggle mode
	end,
})

-- Buttons (plain + risky/red)
miscGroup:AddButton({
	Text = "Print All Flags",
	Callback = function()
		for flag, value in pairs(Library.Flags) do
			print(("[axiom] %s = %s"):format(tostring(flag), tostring(value)))
		end
	end,
})
miscGroup:AddButton({
	Text     = "Danger — Unload Menu",
	Risky    = true,
	Callback = function()
		Library:Unload()
	end,
})

--══════════════════════════ SUBTAB DEMO ══════════════════════════════
local antiAimSub = AimTab:AddSubTab("Anti-Aim")
local aaGroup = antiAimSub:AddGroupbox({ Title = "Anti-Aim" })
aaGroup:AddToggle({ Text = "Enable Anti-Aim", Default = false, Flag = "aa_enabled", Callback = function() end })
aaGroup:AddSlider({ Text = "Spin Speed", Min = 0, Max = 50, Default = 12, Flag = "aa_spin", Callback = function() end })

--══════════════════════════ VISUALS TAB ══════════════════════════════
local espGroup = VisualsTab:AddGroupbox({ Title = "ESP" })
espGroup:AddToggle({ Text = "Box ESP",  Default = true, Flag = "vis_box",  Callback = function() end })
espGroup:AddToggle({ Text = "Name ESP", Default = true, Flag = "vis_name", Callback = function() end })
espGroup:AddSlider({ Text = "Transparency", Min = 0, Max = 100, Default = 0, Suffix = "%", Flag = "vis_transparency", Callback = function() end })

-- Standalone colorpickers driving the live theme system
local themeGroup = VisualsTab:AddGroupbox({ Title = "Menu Colors", Side = "right" })
themeGroup:AddColorpicker({
	Text     = "Menu Accent",
	Default  = Library.Theme.Accent1,
	Flag     = "ui_accent",
	Callback = function(color)
		Library:SetThemeColor("AccentColor", color)
	end,
})
themeGroup:AddColorpicker({
	Text     = "Menu Font Color",
	Default  = Library.Theme.Text,
	Flag     = "ui_font_color",
	Callback = function(color)
		Library:SetThemeColor("FontColor", color)
	end,
})

--══════════════════════════ SETTINGS TAB ═════════════════════════════
local configGroup = SettingsTab:AddGroupbox({ Title = "Configs" })
local uiGroup     = SettingsTab:AddGroupbox({ Title = "UI Settings", Side = "right" })

-- SaveManager: create/save, load, overwrite, delete, autoload toggle
SettingsManager.SaveManager:BuildConfigSection(configGroup)
-- ThemeManager: presets, Font/Main/Accent/Background/Outline pickers,
-- menu keybind + Unload / Copy Server ID / Copy Join Link / Rejoin buttons
SettingsManager.ThemeManager:BuildThemeSection(uiGroup)

--══════════════════════════ HUD & FINALIZE ═══════════════════════════
Library:CreateWatermark("axiom.cc") -- live fps/ping HUD, auto-fitting, draggable
Library:CreateKeybindList()         -- draggable active-keybinds list
local Logger = Library:CreateLogger({ Title = "EVENTS LOG" }) -- draggable logger HUD with rainbow animated hue gradient

-- Toggle for Event Logger in UI Settings
uiGroup:AddToggle({
	Text = "Show Event Logger",
	Default = true,
	Flag = "ui_show_logger",
	Callback = function(state)
		Logger:SetVisible(state)
	end,
})

-- Log initial startup events
Library:Log("Axiom UI v6.1 loaded with Juanitahaxx & Scoot design bases", "SYSTEM")
Library:Log("Exact TahomaXP font (12px) initialized", "SYSTEM")
Library:Log("Rainbow animated hue gradient active on window & HUDs", "VISUALS")
Library:Log("Settings & Config Manager ready", "CONFIG")

-- Runs when Library:Unload() is called (Settings → Unload Script, etc.)
Library.OnUnload = function()
	print("[axiom] example unloaded — goodbye!")
end

-- Restore the autoloaded config AFTER the UI exists (values are pushed
-- through component :Set() so sliders/toggles/dropdowns visually update)
SettingsManager.SaveManager:CheckAutoload()

Library:Notify({
	Title    = "axiom",
	Text     = "Example loaded! Press Insert to toggle the menu.",
	Duration = 5,
	Type     = "Success",
})
    
