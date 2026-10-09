SkeetUIkl / Axiom UI — Roblox UI library documentation
Hard-edge modern UI library (Skeet-style) for Roblox scripts/executors.

Repo: https://github.com/7xtrnl/SkeetUIkl

Main files: ui.luau (library), settingsmanager.luau (configs + themes), example.lua (usage).

1. Loading the library
Lualocal Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/7xtrnl/SkeetUIkl/refs/heads/main/ui.luau"))()
local SettingsManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/7xtrnl/SkeetUIkl/refs/heads/main/settingsmanager.luau"))()

-- Optional global expose
if getgenv then
    getgenv().Axiom = Library
    getgenv().AxiomSettings = SettingsManager
end

-- Wire settings
SettingsManager.SaveManager:SetLibrary(Library)
SettingsManager.ThemeManager:SetLibrary(Library)
SettingsManager.SaveManager:SetFolder("YourConfigFolder")  -- e.g. "AxiomConfigs"
Default menu toggle key: INSERT (rebindable via Settings / keybind).

2. Core Library API

































































FunctionDescriptionLibrary:CreateWindow(cfg)Creates main window. Returns Window.Library:CreateWatermark(title?)Creates draggable watermark HUD.Library:CreateKeybindList()Creates draggable keybinds list HUD.Library:Notify(cfg)Shows notification.Library:SetTheme(themeTable)Applies full theme.Library:SetThemeColor(key, color)Live updates one theme color.Library:SetFontSize(size)Live rescales all text (10–20 recommended).Library:Unload()Destroys UI, disconnects everything.Library.OnUnload = function()Callback fired on unload.Library.FlagsTable of all flagged values.Library.FlagRegistryComponents that support :Set().Library.IconsPreloaded rbxassetid icons.Library.ToggleKeyCurrent menu key (Enum.KeyCode).Library.OpenCurrent open state.
CreateWindow config:
Lualocal Window = Library:CreateWindow({
    Title = "axiom | script",
    Size  = UDim2.fromOffset(720, 520),  -- optional
})
Notify config:
LuaLibrary:Notify({
    Title    = "Title",
    Text     = "Message",
    Duration = 3.5,
    Type     = "Info" | "Success" | "Warning",  -- optional
    Icon     = Library.Icons.Check,             -- optional
})

3. Window → Tabs → Groupboxes
Lualocal Tab = Window:AddTab("Combat", Library.Icons.Swords)  -- name, optional icon

-- Optional sub-tabs
local Sub = Tab:AddSubTab("Rage")

local Group = Tab:AddGroupbox({
    Title = "Aimbot",
    Side  = "left"  -- or "right"
})
Groupboxes support left/right columns automatically.

4. Controls (Group methods)
All controls support Flag (saved in configs) and Callback.
Toggle
Lualocal t = Group:AddToggle({
    Text     = "Enable Aimbot",
    Default  = false,
    Flag     = "aim_enabled",
    Callback = function(state) end,
    Description = "tooltip text",  -- optional
})
-- t:Set(true/false)   t:Get()
Slider
LuaGroup:AddSlider({
    Text     = "FOV",
    Min      = 10,
    Max      = 180,
    Default  = 90,
    Suffix   = "°",
    Flag     = "aim_fov",
    Callback = function(val) end,
})
-- Supports :Set(val) / :Get()
Dropdown (single / multi)
LuaGroup:AddDropdown({
    Text     = "Target Part",
    Options  = {"Head", "UpperTorso", "Torso"},  -- also List / Items / Values
    Default  = "Head",
    Multi    = false,  -- true for multi-select
    Flag     = "aim_part",
    Callback = function(val) end,  -- multi returns table
})
-- :Refresh(newList, keepSelection?)  :Set()  :Get()
Button
LuaGroup:AddButton({
    Text     = "Reset Character",
    Risky    = true,   -- red style
    Icon     = Library.Icons.Refresh,  -- optional
    Callback = function() end,
})
Textbox
LuaGroup:AddTextbox({
    Text        = "Config Name",
    Placeholder = "Enter name...",
    Default     = "",
    Flag        = "some_flag",
    Callback    = function(text) end,
})
Colorpicker
LuaGroup:AddColorpicker({
    Text     = "Accent",
    Default  = Color3.fromRGB(168, 219, 95),
    Flag     = "accent_color",
    Callback = function(col) end,
})
-- :Set(Color3)  :Get()
Keybind
LuaGroup:AddKeybind({          -- also AddKeybindPicker
    Text     = "Menu Key",
    Default  = Enum.KeyCode.Insert,  -- or table {Key = ..., Type = "Toggle"}
    Flag     = "menu_key",
    Callback = function(key, mode) end,  -- modes: Toggle / Hold / Always
})

5. Settings Manager (SaveManager + ThemeManager)
SaveManager
LuaSettingsManager.SaveManager:SetLibrary(Library)
SettingsManager.SaveManager:SetFolder("AxiomConfigs")

-- Build UI section
SettingsManager.SaveManager:BuildConfigSection(groupbox)

-- Manual API
SaveManager:Save("configName")
SaveManager:Load("configName")
SaveManager:Delete("configName")
SaveManager:GetConfigList()
SaveManager:CheckAutoload()   -- call after building UI
Configs are saved as .json in the folder. Flags (except __config_*) are automatically serialized (supports Color3, EnumItem, tables).
ThemeManager
LuaSettingsManager.ThemeManager:SetLibrary(Library)
SettingsManager.ThemeManager:BuildThemeSection(groupbox)

-- Built-in themes
ThemeManager.BuiltInThemes = {
    ["Default axiom"],
    ["axiom Light"],
    ["Midnight Blue"],
    ["Crimson Dark"],
    ["Amethyst Violet"],
}

ThemeManager:ApplyTheme(themeTable)
Public theme keys:

FontColor
MainColor
AccentColor
BackgroundColor
OutlineColor

Live updates via Library:SetThemeColor("AccentColor", Color3.new(...)).

6. Example structure (from repo)
Lualocal Window = Library:CreateWindow({ Title = "axiom | script", Size = UDim2.fromOffset(720, 520) })

local CombatTab   = Window:AddTab("Combat", Library.Icons.Swords)
local VisualsTab  = Window:AddTab("Visuals", Library.Icons.Eye)
local MiscTab     = Window:AddTab("Misc", Library.Icons.Settings)
local SettingsTab = Window:AddTab("Settings", Library.Icons.Palette)

local aimGroup = CombatTab:AddGroupbox({ Title = "Aimbot", Side = "left" })
aimGroup:AddToggle({ Text = "Enable Aimbot", Flag = "aim_enabled", ... })
aimGroup:AddSlider({ Text = "FOV", Min = 10, Max = 180, Default = 90, Flag = "aim_fov" })
-- etc.

-- Settings tab
local configGroup = SettingsTab:AddGroupbox({ Title = "Configs" })
SettingsManager.SaveManager:BuildConfigSection(configGroup)

local uiGroup = SettingsTab:AddGroupbox({ Title = "UI Settings", Side = "right" })
SettingsManager.ThemeManager:BuildThemeSection(uiGroup)

Library:CreateWatermark("axiom | script")
SettingsManager.SaveManager:CheckAutoload()

Library:Notify({
    Title = "axiom",
    Text  = "script loaded! press insert to toggle menu.",
    Duration = 5,
    Type = "Success",
})

7. Extra features

Animated logo — auto-loads from repo (logosheet.png / gif) in window header.
Search bar — built-in search across controls.
Hard-edge styling — no soft rounded corners, clean borders, gradient accents.
Custom Tahoma XP font — auto-downloaded when possible.
Blur + snow overlay when menu is open.
Particle bursts (CreateSuccessBurst / CreateWarningBurst).
Draggable watermark + keybind list (positions saved in config).
Risky buttons — red styling.
Tooltips via Description field on most controls.


8. Notes for executor/script usage

Requires common executor functions: writefile, readfile, listfiles, isfolder, makefolder, delfile, getcustomasset / getsynasset, gethui / protect_gui, setclipboard.
All text is forced lowercase for the pixel-perfect look.
Use unique Flag names so configs work correctly.
Call Library:Unload() or set Library.OnUnload for clean exit.
Menu key is rebindable through the Settings keybind section.
