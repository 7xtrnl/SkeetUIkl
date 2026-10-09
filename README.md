```markdown
# SkeetUIkl / Axiom UI

Hard-edge modern Roblox UI library (Skeet-style) for scripts & executors.

**Repository:** [https://github.com/7xtrnl/SkeetUIkl](https://github.com/7xtrnl/SkeetUIkl)

| File | Description |
|------|-------------|
| `ui.luau` | Main UI library |
| `settingsmanager.luau` | Configs + Themes manager |
| `example.lua` | Full usage example |

---

## Loading

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/7xtrnl/SkeetUIkl/refs/heads/main/ui.luau"))()
local SettingsManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/7xtrnl/SkeetUIkl/refs/heads/main/settingsmanager.luau"))()

-- Optional global expose
if getgenv then
    getgenv().Axiom = Library
    getgenv().AxiomSettings = SettingsManager
end

-- Wire settings manager
SettingsManager.SaveManager:SetLibrary(Library)
SettingsManager.ThemeManager:SetLibrary(Library)
SettingsManager.SaveManager:SetFolder("AxiomConfigs")
```

**Default menu toggle key:** `INSERT` (rebindable)

---

## Core Library API

| Function | Description |
|----------|-------------|
| `Library:CreateWindow(cfg)` | Creates main window → returns `Window` |
| `Library:CreateWatermark(title?)` | Creates draggable watermark HUD |
| `Library:CreateKeybindList()` | Creates draggable keybinds list HUD |
| `Library:Notify(cfg)` | Shows a notification |
| `Library:SetTheme(themeTable)` | Applies a full theme |
| `Library:SetThemeColor(key, color)` | Live-updates one theme color |
| `Library:SetFontSize(size)` | Live-rescales all text (recommended 10–20) |
| `Library:Unload()` | Destroys UI & disconnects everything |
| `Library.OnUnload = function()` | Callback fired on unload |
| `Library.Flags` | Table of all flagged values |
| `Library.FlagRegistry` | Components that support `:Set()` |
| `Library.Icons` | Preloaded rbxassetid icons |
| `Library.ToggleKey` | Current menu key (`Enum.KeyCode`) |
| `Library.Open` | Current open state |

### CreateWindow

```lua
local Window = Library:CreateWindow({
    Title = "axiom | script",
    Size  = UDim2.fromOffset(720, 520), -- optional
})
```

### Notify

```lua
Library:Notify({
    Title    = "Title",
    Text     = "Message",
    Duration = 3.5,
    Type     = "Info",          -- "Info" | "Success" | "Warning"
    Icon     = Library.Icons.Check, -- optional
})
```

---

## Window → Tabs → Groupboxes

```lua
local Tab = Window:AddTab("Combat", Library.Icons.Swords) -- name, optional icon

-- Optional sub-tabs
local Sub = Tab:AddSubTab("Rage")

local Group = Tab:AddGroupbox({
    Title = "Aimbot",
    Side  = "left", -- or "right"
})
```

Groupboxes automatically support left/right columns.

---

## Controls

All controls support `Flag` (persisted in configs) and `Callback`.

### Toggle

```lua
local t = Group:AddToggle({
    Text        = "Enable Aimbot",
    Default     = false,
    Flag        = "aim_enabled",
    Callback    = function(state) end,
    Description = "tooltip text", -- optional
})
-- t:Set(true/false)  |  t:Get()
```

### Slider

```lua
Group:AddSlider({
    Text     = "FOV",
    Min      = 10,
    Max      = 180,
    Default  = 90,
    Suffix   = "°",
    Flag     = "aim_fov",
    Callback = function(val) end,
})
-- :Set(val)  |  :Get()
```

### Dropdown (Single / Multi)

```lua
Group:AddDropdown({
    Text     = "Target Part",
    Options  = {"Head", "UpperTorso", "Torso"}, -- also accepts List / Items / Values
    Default  = "Head",
    Multi    = false, -- true for multi-select
    Flag     = "aim_part",
    Callback = function(val) end, -- multi returns table
})
-- :Refresh(newList, keepSelection?)  |  :Set()  |  :Get()
```

### Button

```lua
Group:AddButton({
    Text     = "Reset Character",
    Risky    = true,                  -- red styling
    Icon     = Library.Icons.Refresh, -- optional
    Callback = function() end,
})
```

### Textbox

```lua
Group:AddTextbox({
    Text        = "Config Name",
    Placeholder = "Enter name...",
    Default     = "",
    Flag        = "some_flag",
    Callback    = function(text) end,
})
```

### Colorpicker

```lua
Group:AddColorpicker({
    Text     = "Accent",
    Default  = Color3.fromRGB(168, 219, 95),
    Flag     = "accent_color",
    Callback = function(col) end,
})
-- :Set(Color3)  |  :Get()
```

### Keybind

```lua
Group:AddKeybind({ -- alias: AddKeybindPicker
    Text     = "Menu Key",
    Default  = Enum.KeyCode.Insert, -- or {Key = ..., Type = "Toggle"}
    Flag     = "menu_key",
    Callback = function(key, mode) end, -- modes: Toggle / Hold / Always
})
```

---

## Settings Manager

### SaveManager

```lua
SettingsManager.SaveManager:SetLibrary(Library)
SettingsManager.SaveManager:SetFolder("AxiomConfigs")

-- Build UI section
SettingsManager.SaveManager:BuildConfigSection(groupbox)

-- Manual API
SaveManager:Save("configName")
SaveManager:Load("configName")
SaveManager:Delete("configName")
SaveManager:GetConfigList()
SaveManager:CheckAutoload() -- call after building UI
```

Configs are saved as `.json`. All flags (except `__config_*`) are automatically serialized (supports `Color3`, `EnumItem`, tables).

### ThemeManager

```lua
SettingsManager.ThemeManager:SetLibrary(Library)
SettingsManager.ThemeManager:BuildThemeSection(groupbox)

ThemeManager:ApplyTheme(themeTable)
```

**Built-in themes:**
- `Default axiom`
- `axiom Light`
- `Midnight Blue`
- `Crimson Dark`
- `Amethyst Violet`

**Public theme keys:**
- `FontColor`
- `MainColor`
- `AccentColor`
- `BackgroundColor`
- `OutlineColor`

Live update example:
```lua
Library:SetThemeColor("AccentColor", Color3.fromRGB(168, 219, 95))
```

---

## Full Example Structure

```lua
local Window = Library:CreateWindow({
    Title = "axiom | script",
    Size  = UDim2.fromOffset(720, 520),
})

local CombatTab   = Window:AddTab("Combat", Library.Icons.Swords)
local VisualsTab  = Window:AddTab("Visuals", Library.Icons.Eye)
local MiscTab     = Window:AddTab("Misc", Library.Icons.Settings)
local SettingsTab = Window:AddTab("Settings", Library.Icons.Palette)

local aimGroup = CombatTab:AddGroupbox({ Title = "Aimbot", Side = "left" })
aimGroup:AddToggle({ Text = "Enable Aimbot", Flag = "aim_enabled" })
aimGroup:AddSlider({ Text = "FOV", Min = 10, Max = 180, Default = 90, Flag = "aim_fov" })

-- Settings tab
local configGroup = SettingsTab:AddGroupbox({ Title = "Configs" })
SettingsManager.SaveManager:BuildConfigSection(configGroup)

local uiGroup = SettingsTab:AddGroupbox({ Title = "UI Settings", Side = "right" })
SettingsManager.ThemeManager:BuildThemeSection(uiGroup)

Library:CreateWatermark("axiom | script")
SettingsManager.SaveManager:CheckAutoload()

Library:Notify({
    Title    = "axiom",
    Text     = "script loaded! press insert to toggle menu.",
    Duration = 5,
    Type     = "Success",
})
```

---

## Extra Features

- Animated logo auto-loaded from repo (`logosheet.png` / gif) in window header
- Built-in search bar across controls
- Hard-edge styling (no soft rounded corners)
- Custom Tahoma XP font (auto-downloaded when possible)
- Blur + snow overlay while menu is open
- Particle bursts (`CreateSuccessBurst` / `CreateWarningBurst`)
- Draggable watermark + keybind list (positions saved in config)
- Risky buttons (red styling)
- Tooltips via `Description` field on most controls

---

## Executor Notes

Requires common executor functions:

- `writefile` / `readfile` / `listfiles`
- `isfolder` / `makefolder` / `delfile`
- `getcustomasset` or `getsynasset`
- `gethui` / `protect_gui`
- `setclipboard` / `toclipboard`

**Tips:**
- All text is forced lowercase for the pixel-perfect look
- Use unique `Flag` names so configs work correctly
- Call `Library:Unload()` or set `Library.OnUnload` for clean exit
- Menu key is rebindable through the Settings keybind section
```
