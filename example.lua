--[[
	══════════════════════════════════════════════════════════════════════════════
	  SKEETWARE UI v5.0 — EXECUTOR EXAMPLE / QUICKSTART
	  • Loads the UI library + settings manager straight from GitHub (up to date)
	  • Shows every component with the current API surface
	  • Configs (SaveManager) + Themes (ThemeManager) wired end to end
	  • Theme extras: Light Mode toggle, Random Theme, presets, import/export
	  • Menu key: INSERT (rebindable in Settings → UI Settings → Menu Keybind)
	  Just run this whole file in your executor.
	══════════════════════════════════════════════════════════════════════════════
--]]

--══════════════════════════════ LOADER ═══════════════════════════════
local REPO = "https://raw.githubusercontent.com/7xtrnl/SkeetUIkl/main/"

-- Cache-busted loader: forces the executor to fetch the LATEST file from
-- GitHub every run (some executors cache HttpGet responses per session).
local function loadFromRepo(path)
	local url = ("%s%s?nocache=%d"):format(REPO, path, math.floor(tick() * 1000) % 1000000000)
	return loadstring(game:HttpGet(url))()
end

local Library         = loadFromRepo("skeet.luau")
local SettingsManager = loadFromRepo("settingsmanager.luau")

print(("[Skeetware] running build %s — theme tools enabled (Light Mode / Random / Presets / Import-Export)")
	:format(Library.Build or "UNKNOWN (old file cached!)"))

-- Expose globally so other scripts / the console can reach them
if getgenv then
	getgenv().Skeetware         = Library
	getgenv().SkeetwareSettings = SettingsManager
end

--══════════════════════ WIRE UP THE SETTINGS MANAGER ═══════════════════════
SettingsManager.SaveManager:SetLibrary(Library)
SettingsManager.ThemeManager:SetLibrary(Library)
SettingsManager.SaveManager:SetFolder("SkeetwareConfigs") -- config folder name

--══════════════════════════ WINDOW & TABS ════════════════════════════
local Window = Library:CreateWindow({
	Title = "skeetware.cc | example",
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
	Text        = "Enable Ragebot",
	Default     = false,
	Flag        = "rage_enabled",
	Description = "Master switch for the ragebot module. Press the bound key to toggle in-game.",
	Callback    = function(state)
		Library:Notify({
			Title    = "Ragebot",
			Text     = state and "Enabled" or "Disabled",
			Duration = 2,
			Type     = state and "Success" or "Info",
		})
	end,
})
rageEnabled:AddColorpicker({ Default = Color3.fromRGB(168, 219, 95), Flag = "rage_color" })
rageEnabled:AddKeybind({ Default = Enum.KeyCode.E, Mode = "Hold", Flag = "rage_key", Description = "Hold to toggle ragebot while the key is down." })

-- Slider: drag, floating tooltip, click the value to type manually
rageGroup:AddSlider({
	Text        = "Field of View",
	Min         = 20,
	Max         = 360,
	Default     = 120,
	Suffix      = "°",
	Flag        = "rage_fov",
	Description = "Maximum aim angle. Double-click the value to reset to 120°.",
	Callback    = function(value)
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
			print(("[skeetware] %s = %s"):format(tostring(flag), tostring(value)))
		end
	end,
})
miscGroup:AddButton({
	Text        = "Danger — Unload Menu",
	Risky       = true,
	Description = "Destroys the menu instantly. Settings → UI Settings → Unload Script does the same.",
	Callback    = function()
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

-- NOTE: Menu theming (accent, font, background, outline) is handled in the
-- Settings tab under UI Settings via ThemeManager:BuildThemeSection.
-- No menu-color pickers live in the Visuals tab anymore.

--══════════════════════════ SETTINGS TAB ═════════════════════════════
local configGroup = SettingsTab:AddGroupbox({ Title = "Configs" })
local uiGroup     = SettingsTab:AddGroupbox({ Title = "UI Settings", Side = "right" })

-- SaveManager: create/save, load, overwrite, delete, autoload toggle
SettingsManager.SaveManager:BuildConfigSection(configGroup)
-- ThemeManager: built-in presets, Light Mode toggle, Random Theme generator,
-- custom preset save/load/delete, clipboard + JSON import/export, plus the
-- Font/Main/Accent/Background/Outline pickers, menu keybind, Unload,
-- Copy Server ID / Copy Join Link / Rejoin buttons.
SettingsManager.ThemeManager:BuildThemeSection(uiGroup)

--══════════════════════════ HUD & FINALIZE ═══════════════════════════
Library:CreateWatermark("skeetware.cc") -- live fps/ping HUD, draggable
Library:CreateKeybindList()             -- draggable active-keybinds list

-- Runs when Library:Unload() is called (Settings → Unload Script, etc.)
Library.OnUnload = function()
	print("[skeetware] example unloaded — goodbye!")
end

-- Restore the autoloaded config AFTER the UI exists (values are pushed
-- through component :Set() so sliders/toggles/dropdowns visually update)
SettingsManager.SaveManager:CheckAutoload()

Library:Notify({
	Title    = "skeetware",
	Text     = ("Build %s loaded! Press Insert to toggle the menu."):format(Library.Build or "?"),
	Duration = 5,
	Type     = "Success",
})
