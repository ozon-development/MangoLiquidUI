# MangoLiquidUI Documentation

**MangoLiquidUI** is a Roblox UI library written in `--!strict` Luau that replicates Apple's Liquid Glass design language. It features directional rim lighting, multi-layer soft shadows, camera-locked refraction proxies, mouse-driven parallax, smooth hover animations, and a complete Apple-style UI control library.

Designed as a drop-in ModuleScript package for Roblox experiences under the **Mango Development** brand.

---

## Table of Contents

- [Installation](#installation)
- [Quick Start](#quick-start)
- [Themes](#themes)
- [Short API Reference](#short-api-reference)
- [High-Level Window API](#high-level-window-api)
  - [MangoWindow](#mangowindow)
  - [Configuration Saving (Flags)](#configuration-saving-flags)
- [Core Systems](#core-systems)
  - [MangoGlassFrame](#mangoglassframe)
  - [RefractionProxy](#refractionproxy)
  - [LiquidFusion](#liquidfusion)
  - [MangoEnvironmentLight](#mangoenvironmentlight)
  - [MangoIntro](#mangointro)
- [Controls](#controls)
  - [MangoButton](#mangobutton)
  - [MangoToggle](#mangotoggle)
  - [MangoSlider](#mangoslider)
  - [MangoCheckbox](#mangocheckbox)
  - [MangoStepper](#mangostepper)
  - [MangoProgressBar](#mangoprogressbar)
  - [MangoSegmentedControl](#mangosegmentedcontrol)
  - [MangoColorPicker](#mangocolorpicker)
  - [MangoKeybind](#mangokeybind)
- [Text Input](#text-input)
  - [MangoTextField](#mangotextfield)
  - [MangoSearchBar](#mangosearchbar)
- [Navigation](#navigation)
  - [MangoDropdown](#mangodropdown)
  - [MangoTabBar](#mangotabbar)
  - [MangoContextMenu](#mangocontextmenu)
  - [MangoCarousel](#mangocarousel)
- [Overlays & Modals](#overlays--modals)
  - [MangoDialog](#mangodialog)
  - [MangoActionSheet](#mangoactionsheet)
  - [MangoNotification](#mangonotification)
  - [MangoNotificationStack](#mangonotificationstack)
  - [MangoToast](#mangotoast)
  - [MangoToastStack](#mangotoaststack)
  - [MangoTooltip](#mangotooltip)
  - [MangoBottomSheet](#mangobottomsheet)
- [Display](#display)
  - [MangoBillboardLabel](#mangobillboardlabel)
  - [MangoBadge](#mangobadge)
  - [MangoSkeleton](#mangoskeleton)
  - [MangoShimmer](#mangoshimmer)
- [Visual Enhancements](#visual-enhancements)
  - [MangoBlurProxy](#mangoblurproxy)
  - [MangoHaptics](#mangohaptics)
- [Layout & Utilities](#layout--utilities)
  - [MangoLayout](#mangolayout)
  - [MangoForm](#mangoform)
  - [MangoFocusManager](#mangofocusmanager)
  - [MangoBuilder](#mangobuilder)
  - [MangoSaveManager](#mangosavemanager)
- [Utility Functions](#utility-functions)
  - [gui()](#gui)
  - [transitionTheme()](#transitiontheme)
- [Theme Customization](#theme-customization)
- [Roblox Limitations](#roblox-limitations)

---

## Installation

### Method 1: ReplicatedStorage (Studio)

1. Place the `MangoLiquidUI` folder in `ReplicatedStorage` as a Folder of ModuleScripts.
2. Require from any LocalScript:

```lua
local ui = require(game.ReplicatedStorage.MangoLiquidUI)
```

### Method 2: Loadstring Bundle (GitHub)

```lua
local ui = loadstring(game:HttpGet("https://raw.githubusercontent.com/<user>/<repo>/main/MangoLiquidUI/dist/MangoLiquidUI.lua"))()
```

Rebuild the bundle after modifying source files:

```bash
./MangoLiquidUI/build.sh
```

---

## Quick Start

### Low-Level API (Component-by-Component)

```lua
local ui = require(game.ReplicatedStorage.MangoLiquidUI)
-- Intro animation auto-plays on require

-- Create a ScreenGui
local screen = ui.gui("MyUI")

-- Create a glass panel
local panel = ui.glass({
    Size = UDim2.new(0, 400, 0, 300),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    AnchorPoint = Vector2.new(0.5, 0.5),
    CornerRadius = UDim.new(0, 20),
    Theme = ui.Dark,
    Parent = screen,
})

-- Add a button inside the glass panel
local btn = ui.bttn({
    Text = "Click Me",
    Position = UDim2.new(0.5, 0, 0.5, 0),
    AnchorPoint = Vector2.new(0.5, 0.5),
    Theme = ui.Dark,
    OnActivated = function()
        print("Button pressed!")
    end,
    Parent = panel.GlassSurface, -- Content goes into GlassSurface
})

-- Skip the intro if needed
ui.intro.skip()
```

### High-Level Window API (Recommended)

```lua
local ui = require(game.ReplicatedStorage.MangoLiquidUI)

local Window = ui.window({
    Name = "My App",
    Theme = ui.Dark,
    LoadingTitle = "My App",
    LoadingSubtitle = "v1.0",
})

local Tab = Window:Tab("Home", "home-icon")

Tab:Button({Name = "Click Me", Callback = function()
    print("Clicked!")
end})

Tab:Toggle({Name = "Feature", Default = false, Callback = function(v)
    print("Toggled:", v)
end})

Tab:Slider({Name = "Speed", Range = {0, 100}, Increment = 1, Default = 50, Callback = function(v)
    print("Speed:", v)
end})
```

---

## Themes

MangoLiquidUI ships with 4 built-in themes:

| Theme | Description | Access |
|-------|-------------|--------|
| **Light** | Clean white glass, blue accents | `ui.Light` |
| **Dark** | Rich dark glass, blue accents | `ui.Dark` |
| **Mango** | Warm amber/orange-tinted glass | `ui.Mango` |
| **Mint** | Fresh mint/teal glass, green accents | `ui.Mint` |

Every component accepts an optional `Theme` field. Omitting it falls back to Light theme defaults.

```lua
local toggle = ui.tgl({
    Position = UDim2.new(0, 20, 0, 20),
    Theme = ui.Mango,
    Parent = screen,
})
```

### Custom Themes

Create custom themes by extending an existing theme with overrides:

```lua
local MyTheme = ui.Themes.custom(ui.Dark, {
    BackgroundColor3 = Color3.fromRGB(30, 20, 40),
    SliderFillColor = Color3.fromRGB(180, 50, 255),
    CheckboxOnColor = Color3.fromRGB(180, 50, 255),
    ToggleOnTrackColor = Color3.fromRGB(180, 50, 255),
    PrimaryTextColor = Color3.fromRGB(240, 240, 255),
})

local Window = ui.window({Name = "My App", Theme = MyTheme})
```

### Theme Cascade

Config values follow a three-tier cascade:

1. **Config field** (explicit value passed by you)
2. **Theme field** (from the ThemePreset table)
3. **Hardcoded default** (built into the component)

This uses the `resolve(configVal, themeVal, default)` helper (not Lua's `or` operator) to correctly handle `0` and `false` values.

---

## Short API Reference

All components have both a full constructor (`ui.MangoButton.new(config)`) and a short alias (`ui.bttn(config)`). Both return identical types.

| Short | Full Module | Creates |
|-------|------------|---------|
| `ui.window(c)` | `ui.MangoWindow.new(c)` | Window (high-level wrapper) |
| `ui.glass(c)` | `ui.MangoGlassFrame.new(c)` | Glass Frame |
| `ui.bttn(c)` | `ui.MangoButton.new(c)` | Button |
| `ui.sldr(c)` | `ui.MangoSlider.new(c)` | Slider |
| `ui.tgl(c)` | `ui.MangoToggle.new(c)` | Toggle |
| `ui.chk(c)` | `ui.MangoCheckbox.new(c)` | Checkbox |
| `ui.step(c)` | `ui.MangoStepper.new(c)` | Stepper |
| `ui.prog(c)` | `ui.MangoProgressBar.new(c)` | Progress Bar |
| `ui.seg(c)` | `ui.MangoSegmentedControl.new(c)` | Segmented Control |
| `ui.colr(c)` | `ui.MangoColorPicker.new(c)` | Color Picker |
| `ui.key(c)` | `ui.MangoKeybind.new(c)` | Keybind |
| `ui.drp(c)` | `ui.MangoDropdown.new(c)` | Dropdown |
| `ui.tab(c)` | `ui.MangoTabBar.new(c)` | Tab Bar |
| `ui.ctx(c)` | `ui.MangoContextMenu.new(c)` | Context Menu |
| `ui.carousel(c)` | `ui.MangoCarousel.new(c)` | Carousel |
| `ui.csel(c)` | `ui.MangoCarousel.new(c)` | Carousel (alias) |
| `ui.srch(c)` | `ui.MangoSearchBar.new(c)` | Search Bar |
| `ui.txt(c)` | `ui.MangoTextField.new(c)` | Text Field |
| `ui.dlg(c)` | `ui.MangoDialog.new(c)` | Dialog |
| `ui.act(c)` | `ui.MangoActionSheet.new(c)` | Action Sheet |
| `ui.notif(c)` | `ui.MangoNotification.new(c)` | Notification |
| `ui.nstack(c)` | `ui.MangoNotificationStack.new(c)` | Notification Stack |
| `ui.toast(c)` | `ui.MangoToast.new(c)` | Toast |
| `ui.tstack(c)` | `ui.MangoToast.newStack(c)` | Toast Stack |
| `ui.tip(c)` | `ui.MangoTooltip.new(c)` | Tooltip |
| `ui.bsheet(c)` | `ui.MangoBottomSheet.new(c)` | Bottom Sheet |
| `ui.bbl(c)` | `ui.MangoBillboardLabel.new(c)` | Billboard Label |
| `ui.bdg(c)` | `ui.MangoBadge.new(c)` | Badge |
| `ui.skel(c)` | `ui.MangoSkeleton.new(c)` | Skeleton |
| `ui.shimr(c)` | `ui.MangoShimmer.new(c)` | Shimmer |
| `ui.blur(c)` | `ui.MangoBlurProxy.new(c)` | Blur Proxy |
| `ui.refr(c)` | `ui.RefractionProxy.new(c)` | Refraction Proxy |
| `ui.fuse(c)` | `ui.LiquidFusion.new(c)` | Liquid Fusion |
| `ui.env(c)` | `ui.MangoEnvironmentLight.new(c)` | Environment Light |
| `ui.layout(c)` | `ui.MangoLayout.new(c)` | Layout |
| `ui.form(c)` | `ui.MangoForm.new(c)` | Form |
| `ui.focus(c)` | `ui.MangoFocusManager.new(c)` | Focus Manager |
| `ui.build(t)` | `ui.MangoBuilder.build(t)` | Builder Chain |

**Other shortcuts:**

| Access | Description |
|--------|-------------|
| `ui.Light` / `ui.Dark` / `ui.Mango` / `ui.Mint` | Theme presets |
| `ui.Themes.custom(base, overrides)` | Create custom theme |
| `ui.intro` | MangoIntro module (`play()`, `skip()`) |
| `ui.haptic` | MangoHaptics module (`setEnabled()`, `light()`, etc.) |
| `ui.gui(name?)` | Creates a configured ScreenGui |

---

## High-Level Window API

### MangoWindow

A Rayfield-style `Window -> Tab -> Element` wrapper that auto-handles layout, theming, dragging, and animations. This is the recommended way to build UI with MangoLiquidUI.

**Constructor:** `ui.window(config)` or `ui.MangoWindow.new(config)`

#### Window Config

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `Name` | `string?` | `"MangoUI"` | Window title |
| `Theme` | `ThemePreset?` | Light | Theme for all elements |
| `Size` | `UDim2?` | `(0, 400, 0, 500)` | Window size |
| `Position` | `UDim2?` | `(0.5, 0, 0.5, 0)` | Window position (centered) |
| `ToggleKey` | `string?` | `nil` | Keyboard shortcut to show/hide (e.g. `"RightShift"`) |
| `ShowButton` | `string?` | Window Name | Reopener pill text |
| `LoadingTitle` | `string?` | `"Mango"` | Custom intro title text |
| `LoadingSubtitle` | `string?` | `nil` | Custom intro subtitle text |
| `LoadingEnabled` | `boolean?` | `true` | Show intro animation |
| `ConfigurationSaving` | `table?` | `nil` | Auto-save configuration (see below) |

#### Window Methods

| Method | Description |
|--------|-------------|
| `Window:Tab(name, icon?)` | Create a new tab, returns `MangoWindowTab` |
| `Window:Show()` | Show window with materialize animation |
| `Window:Hide()` | Hide window, show reopener pill |
| `Window:IsVisible()` | Returns current visibility |
| `Window:Notify(config)` | Show a notification (uses MangoNotificationStack) |
| `Window:Dialog(config)` | Show a modal dialog |
| `Window:SaveConfig()` | Manually save all flagged values |
| `Window:LoadConfig()` | Manually load saved values |
| `Window:Destroy()` | Clean up everything |
| `Window.Flags` | `{[string]: any}` — live table of all flag values |

#### Tab Element Methods

Each tab returns a `MangoWindowTab` with these element methods. All interactive elements return a `MangoWindowElement`.

| Method | Row Height | Description |
|--------|-----------|-------------|
| `Tab:Button(config)` | 40px | Full-width button |
| `Tab:Toggle(config)` | 36px | Label left + toggle right |
| `Tab:Slider(config)` | 54px | Label+value top + slider below |
| `Tab:Dropdown(config)` | 40px | Label left + dropdown right |
| `Tab:Input(config)` | 56px | Label top + text field below |
| `Tab:Checkbox(config)` | 32px | Checkbox with label |
| `Tab:Stepper(config)` | 40px | Label left + stepper right |
| `Tab:Progress(config)` | 40px | Label top + progress bar below |
| `Tab:ColorPicker(config)` | 40px | Label left + color preview right (expands on click) |
| `Tab:Keybind(config)` | 36px | Label left + keybind pill right |
| `Tab:Label(text)` | 20px | Simple text label |
| `Tab:Paragraph(config)` | auto | Title + content (auto-height) |
| `Tab:Section(title)` | 30px | Bold section header + separator |
| `Tab:Separator()` | 9px | 1px horizontal line |

#### Element Config Fields

All element configs use friendly field names that are automatically mapped to underlying component configs:

| Field | Used By | Maps To |
|-------|---------|---------|
| `Name` | All | Text/Label on the element |
| `Default` | Toggle, Checkbox, Slider, Dropdown, Input, Stepper, ColorPicker, Keybind | Initial value |
| `Callback` | All interactive | OnActivated/OnToggled/OnChanged handler |
| `Range` | Slider, Stepper | `{min, max}` unpacked to Min/Max |
| `Increment` | Slider, Stepper | Step value |
| `Suffix` | Slider | Unit text after value (e.g. `"%"`) |
| `Options` | Dropdown | Items list |
| `Placeholder` | Input | Placeholder text |
| `Masked` | Input | Password mode (shows dots) |
| `Flag` | All interactive | Register in `Window.Flags` for persistence |
| `Visible` | All | `true`, `false`, or flag name (conditional visibility) |

#### MangoWindowElement (Unified Wrapper)

Every interactive element returns a `MangoWindowElement`:

| Field/Method | Description |
|-------|-------------|
| `.CurrentValue` | Current value of the element |
| `:Set(value)` | Update the value programmatically |
| `:Visible(bool)` | Show or hide the element row |
| `:Lock(reason?)` | Dim and disable the element (optional tooltip text) |
| `:Unlock()` | Restore the element |
| `:Destroy()` | Remove the element |

#### Auto-Behaviors

- **Auto-draggable** via title bar (mouse + touch)
- **Auto close button** — glass "✕" circle, hides window
- **Auto reopener pill** — glass pill at top-center, click to reopen
- **Auto-layout** — elements stack vertically, no Position/Size needed
- **Auto-theme** — set once on window, all children inherit
- **Auto-scrolling** — tab content scrolls when overflowing
- **Toggle keybind** — optional keyboard shortcut
- **Tab selector** — MangoSegmentedControl appears automatically with 2+ tabs

#### Example

```lua
local ui = require(game.ReplicatedStorage.MangoLiquidUI)

local Window = ui.window({
    Name = "My App",
    Theme = ui.Dark,
    ToggleKey = "RightShift",
    LoadingTitle = "My App",
    LoadingSubtitle = "v1.0",
})

local Home = Window:Tab("Home", "home-icon")

Home:Label("Welcome to My App!")
Home:Section("Controls")

Home:Button({Name = "Click Me", Callback = function()
    print("Clicked!")
end})

local toggle = Home:Toggle({
    Name = "Feature",
    Default = false,
    Callback = function(v) print("Toggle:", v) end,
})

Home:Slider({
    Name = "Speed",
    Range = {0, 100},
    Increment = 1,
    Suffix = "%",
    Default = 50,
    Callback = function(v) print("Speed:", v) end,
})

Home:Dropdown({
    Name = "Mode",
    Options = {"Easy", "Normal", "Hard"},
    Default = "Normal",
    Callback = function(v) print("Mode:", v) end,
})

Home:Input({
    Name = "Username",
    Placeholder = "Enter name...",
    Callback = function(t) print("Name:", t) end,
})

Home:ColorPicker({
    Name = "Accent",
    Default = Color3.new(1, 0, 0),
    Callback = function(c) print("Color:", c) end,
})

Home:Keybind({
    Name = "Sprint",
    Default = "LeftShift",
    Callback = function(key) print("Key:", key) end,
})

-- Unified element API
toggle:Set(true)
toggle:Lock("Not ready yet")
toggle:Unlock()
print(toggle.CurrentValue)

-- Window-level helpers
Window:Notify({Title = "Hello!", Body = "Welcome", Duration = 3})
Window:Dialog({Title = "Confirm?", Message = "Are you sure?"})
```

---

### Configuration Saving (Flags)

MangoWindow integrates with MangoSaveManager to persist user settings across sessions.

#### Setup

```lua
local Window = ui.window({
    Name = "My App",
    Theme = ui.Dark,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "MyApp",    -- folder name for save files
        FileName = "settings",   -- file name (without .json)
    },
})
```

#### Using Flags

Add a `Flag` field to any interactive element to auto-register it for persistence:

```lua
local Tab = Window:Tab("Settings")

Tab:Toggle({
    Name = "ESP",
    Default = false,
    Flag = "esp_enabled",
    Callback = function(v) end,
})

Tab:Slider({
    Name = "Speed",
    Range = {0, 100},
    Default = 50,
    Flag = "walk_speed",
    Callback = function(v) end,
})

-- Access flags globally
print(Window.Flags["esp_enabled"])  -- false
print(Window.Flags["walk_speed"])   -- 50
```

When `ConfigurationSaving.Enabled = true`:
- Values are **auto-saved** on every change (1s debounce)
- Values are **auto-loaded** on Window creation (overrides `Default` fields)
- Manual control: `Window:SaveConfig()` / `Window:LoadConfig()`

#### Dependency System (Conditional Visibility)

Elements can reference other flags for auto-show/hide:

```lua
Tab:Toggle({Name = "ESP", Default = false, Flag = "esp_toggle", Callback = function(v) end})

Tab:Slider({
    Name = "ESP Distance",
    Range = {0, 500},
    Default = 100,
    Flag = "esp_dist",
    Visible = "esp_toggle",  -- only visible when esp_toggle is truthy
    Callback = function(v) end,
})

Tab:ColorPicker({
    Name = "ESP Color",
    Default = Color3.new(1, 0, 0),
    Flag = "esp_color",
    Visible = "esp_toggle",  -- also depends on esp_toggle
    Callback = function(c) end,
})
```

---

## Core Systems

### MangoGlassFrame

The foundational glass material component. All glass-based components compose this internally.

**Constructor:** `ui.glass(config)` or `ui.MangoGlassFrame.new(config)`

#### Config

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `Size` | `UDim2` | *required* | Frame size |
| `Position` | `UDim2` | *required* | Frame position |
| `AnchorPoint` | `Vector2?` | `(0, 0)` | Anchor point |
| `CornerRadius` | `UDim?` | `UDim.new(0, 16)` | Corner rounding |
| `BackgroundColor3` | `Color3?` | theme / white | Glass surface color |
| `BackgroundTransparency` | `number?` | theme / `0.72` | Glass surface transparency |
| `NoiseOpacity` | `number?` | theme / `0.03` | Perlin noise texture opacity |
| `NoiseImageId` | `string?` | built-in | Custom noise texture |
| `FresnelStartTransparency` | `number?` | theme / `0.25` | Top edge specular transparency |
| `FresnelEndTransparency` | `number?` | theme / `0.95` | Bottom edge specular transparency |
| `FresnelMidTransparency` | `number?` | theme / `0.50` | Mid-point specular transparency |
| `FresnelMidPoint` | `number?` | theme / `0.35` | Position of mid keypoint (0-1) |
| `FresnelAngle` | `number?` | theme / `90` | Specular gradient rotation |
| `StrokeThickness` | `number?` | theme / `1.5` | Specular stroke width |
| `StrokeColor` | `Color3?` | theme / white | Specular stroke color |
| `InnerGlowTransparency` | `number?` | theme / `0.82` | Inner highlight transparency |
| `InnerGlowColor` | `Color3?` | theme / white | Inner highlight color |
| `InnerGlowHeight` | `number?` | theme / `0.12` | Inner highlight height (0-1 fraction) |
| `InnerEdgeColor` | `Color3?` | theme / white | Inner edge stroke color |
| `InnerEdgeTopTransparency` | `number?` | theme | Inner edge top transparency |
| `InnerEdgeMidTransparency` | `number?` | theme | Inner edge mid transparency |
| `InnerEdgeBottomTransparency` | `number?` | theme | Inner edge bottom transparency |
| `LensGroupColor3` | `Color3?` | theme | CanvasGroup saturation tint |
| `LensGroupTransparency` | `number?` | theme / `0.62` | Lens tint transparency |
| `ShadowColor` | `Color3?` | theme / black | Shadow color |
| `ShadowTransparency` | `number?` | theme / `0.80` | Shadow transparency (higher = subtler) |
| `ShadowSpread` | `number?` | theme / `20` | Outermost shadow spread in px |
| `ShadowOffsetX` | `number?` | theme / `0` | Horizontal shadow offset |
| `ShadowOffsetY` | `number?` | theme / `5` | Vertical shadow offset |
| `ShadowEnabled` | `boolean?` | `true` | Enable/disable shadow layers |
| `ShadowLayerCount` | `number?` | `5` | Number of shadow layers (max 12) |
| `LightweightMode` | `boolean?` | `false` | Skip CanvasGroups (for small elements) |
| `ParallaxEnabled` | `boolean?` | `false` | Enable mouse-driven parallax |
| `ParallaxIntensity` | `number?` | theme / `0.15` | Parallax strength |
| `Theme` | `ThemePreset?` | Light | Theme preset |
| `Parent` | `GuiObject?` | `nil` | Parent instance |

#### Returns

| Field | Type | Description |
|-------|------|-------------|
| `Container` | `Frame` | Outer transparent wrapper |
| `Frame` | `Frame` | Alias for Container |
| `GlassSurface` | `Frame` | **Parent your content here** |
| `ShadowLayers` | `{Frame}` | Array of shadow layer Frames |
| `LensGroup` | `CanvasGroup?` | nil in LightweightMode |
| `TextureGroup` | `CanvasGroup?` | nil in LightweightMode |
| `NoiseLabel` | `ImageLabel?` | nil in LightweightMode |
| `InnerHighlight` | `Frame?` | nil in LightweightMode |
| `InnerEdgeFrame` | `Frame` | Inner edge frame |
| `InnerEdgeStroke` | `UIStroke` | Inner edge stroke |
| `InnerEdgeGradient` | `UIGradient` | Inner edge gradient |
| `SpecularFrame` | `Frame` | Specular rim frame |
| `SpecularStroke` | `UIStroke` | Specular rim stroke |
| `SpecularGradient` | `UIGradient` | Specular rim gradient |
| `SetLightDirection(angle)` | method | Rotates all gradients |
| `SetParallaxEnabled(enabled)` | method | Toggle parallax at runtime |
| `Destroy()` | method | Cleanup |

#### Example

```lua
local panel = ui.glass({
    Size = UDim2.new(0, 500, 0, 400),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    AnchorPoint = Vector2.new(0.5, 0.5),
    CornerRadius = UDim.new(0, 24),
    Theme = ui.Dark,
    ParallaxEnabled = true,
    Parent = screen,
})

-- Add content to the glass surface
local label = Instance.new("TextLabel")
label.Text = "Hello Glass!"
label.Size = UDim2.new(1, 0, 0, 40)
label.BackgroundTransparency = 1
label.Parent = panel.GlassSurface -- Always parent to GlassSurface
```

---

### RefractionProxy

Optical simulation that places a Glass Part in front of the camera to create real 3D refraction behind UI elements.

**Constructor:** `ui.refr(config)` or `ui.RefractionProxy.new(config)`

#### Config

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `TargetGui` | `GuiObject` | *required* | UI element to track |
| `GlassTransparency` | `number?` | theme / `0.88` | Glass Part transparency |
| `GlassMaterial` | `Enum.Material?` | `Glass` | Part material |
| `GlassColor` | `Color3?` | theme | Glass tint color |
| `GlassReflectance` | `number?` | theme / `0.08` | Glass reflectance |
| `GlassThickness` | `number?` | `0.05` | Glass depth in studs |
| `OffsetDepth` | `number?` | `1.5` | Distance from camera |
| `Enabled` | `boolean?` | `true` | Initial enabled state |
| `ViewportMode` | `boolean?` | `false` | Full-screen single glass |
| `Theme` | `ThemePreset?` | Light | Theme preset |

#### Returns

| Field | Type | Description |
|-------|------|-------------|
| `GlassPart` | `Part` | The refraction Part |
| `Enabled` | `boolean` | Current state |
| `SetEnabled(enabled)` | method | Toggle refraction |
| `UpdateTarget(newGui)` | method | Change tracked element |
| `Destroy()` | method | Cleanup |

#### Static Methods

| Method | Description |
|--------|-------------|
| `RefractionProxy.resetDepthCounter()` | Reset Z-fighting counter (call before rebuilds) |

#### Example

```lua
local proxy = ui.refr({
    TargetGui = panel.Container,
    Theme = ui.Dark,
})

-- Later: toggle refraction
proxy:SetEnabled(false)
```

**Important:** Uses `ScreenPointToRay` (not `ViewportPointToRay`) because `IgnoreGuiInset=true` makes `AbsolutePosition` return screen coordinates.

---

### LiquidFusion

Animation system providing smooth hover/touch interactions with specular gradient shifts.

**Constructor:** `ui.fuse(config)` or `ui.LiquidFusion.new(config)`

#### Config

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `Target` | `GuiObject` | *required* | Element to animate |
| `BulgeScale` | `number?` | `1.025` | Hover scale factor |
| `BulgeDuration` | `number?` | `0.25` | Hover-in duration |
| `RestoreDuration` | `number?` | `0.3` | Hover-out duration |
| `SpecularShiftOffset` | `UDim2?` | `(0.04, 0, 0.04, 0)` | Specular gradient offset shift |
| `UseUIScale` | `boolean?` | `false` | Use UIScale instead of Size |

#### Returns

| Field | Type | Description |
|-------|------|-------------|
| `Connect()` | method | Start listening for hover events |
| `Disconnect()` | method | Stop listening |
| `TweenProperty(prop, target, duration?)` | method | Tween any property |
| `Destroy()` | method | Cleanup |

#### Example

```lua
local fusion = ui.fuse({
    Target = panel.Container,
    BulgeScale = 1.03,
    UseUIScale = true,
})
fusion:Connect()
```

---

### MangoEnvironmentLight

Dynamic environment lighting that projects sun/moon direction into gradient rotations and tints glass surfaces with ambient color.

**Constructor:** `ui.env(config)` or `ui.MangoEnvironmentLight.new(config)`

#### Config

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `UpdateAngleEveryFrame` | `boolean?` | `true` | Update gradient angle per frame |
| `TintUpdateInterval` | `number?` | `0.5` | Seconds between tint samples |
| `TintInfluence` | `number?` | `0.45` | Ambient color influence (0-1) |
| `Enabled` | `boolean?` | `true` | Initial enabled state |

#### Returns

| Field | Type | Description |
|-------|------|-------------|
| `Enable()` | method | Start lighting updates |
| `Disable()` | method | Stop lighting updates |
| `IsEnabled()` | method | Get current state |
| `GetSunAngle()` | method | Current sun angle in degrees |
| `GetEnvironmentTint()` | method | Current ambient tint Color3 |
| `RegisterGlassFrame(frame)` | method | Register a glass frame for tinting |
| `UnregisterGlassFrame(frame)` | method | Unregister a glass frame |
| `Destroy()` | method | Cleanup |

#### Example

```lua
local envLight = ui.env({
    TintInfluence = 0.45,
    Enabled = true,
})
envLight:RegisterGlassFrame(panel)
```

---

### MangoIntro

Auto-play intro animation with 4-layer 3D glass text, spotlight rotation, and shimmer sweep.

**Access:** `ui.intro`

#### Methods

| Method | Description |
|--------|-------------|
| `ui.intro.play(config?)` | Play the intro animation |
| `ui.intro.skip()` | Skip/cancel the intro immediately |

#### Config (optional)

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `Theme` | `ThemePreset?` | Mango | Theme for intro visuals |
| `Title` | `string?` | `"Mango"` | Custom title text for the 3D text layers |
| `Subtitle` | `string?` | `nil` | Subtitle text below the title (fades in after bounce) |
| `OnComplete` | `(() -> ())?` | `nil` | Callback when animation finishes |
| `Parent` | `Instance?` | PlayerGui | Parent for intro ScreenGui |

The intro auto-plays when the library is first `require()`d. Call `ui.intro.skip()` immediately after require to suppress it.

```lua
local ui = require(game.ReplicatedStorage.MangoLiquidUI)
ui.intro.skip() -- Skip if you don't want the intro

-- Or play with custom text
ui.intro.play({
    Title = "My App",
    Subtitle = "v1.0",
    Theme = ui.Dark,
})
```

---

## Controls

### MangoButton

Apple-style glass pill button with hover scale, press animation, opacity pulse, and directional specular.

**Constructor:** `ui.bttn(config)` or `ui.MangoButton.new(config)`

#### Config

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `Position` | `UDim2` | *required* | Button position |
| `Size` | `UDim2?` | auto from text | Button size (auto-sizes if omitted) |
| `AnchorPoint` | `Vector2?` | `(0, 0)` | Anchor point |
| `Text` | `string` | *required* | Button label |
| `TextSize` | `number?` | `16` | Font size |
| `BackgroundTransparency` | `number?` | theme / `0.65` | Glass opacity |
| `Theme` | `ThemePreset?` | Light | Theme preset |
| `OnActivated` | `(() -> ())?` | `nil` | Click callback |
| `Parent` | `GuiObject?` | `nil` | Parent instance |

#### Returns

| Field | Type | Description |
|-------|------|-------------|
| `Container` | `Frame` | Outer frame |
| `GlassSurface` | `Frame` | Inner glass surface |
| `TextLabel` | `TextLabel` | Button text label |
| `SetText(text)` | method | Update button text |
| `Destroy()` | method | Cleanup |

#### Example

```lua
local btn = ui.bttn({
    Text = "Save",
    Position = UDim2.new(0.5, 0, 0, 20),
    AnchorPoint = Vector2.new(0.5, 0),
    Theme = ui.Mango,
    OnActivated = function()
        print("Saved!")
    end,
    Parent = panel.GlassSurface,
})
```

---

### MangoToggle

Apple-style toggle switch with spring-animated knob and color-transitioning track.

**Constructor:** `ui.tgl(config)` or `ui.MangoToggle.new(config)`

#### Config

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `Position` | `UDim2` | *required* | Toggle position |
| `AnchorPoint` | `Vector2?` | `(0, 0)` | Anchor point |
| `Scale` | `number?` | `1` | Size multiplier |
| `Theme` | `ThemePreset?` | Light | Theme preset |
| `InitialState` | `boolean?` | `false` | Starting on/off state |
| `OnToggled` | `((state: boolean) -> ())?` | `nil` | State change callback |
| `Parent` | `GuiObject?` | `nil` | Parent instance |

#### Returns

| Field | Type | Description |
|-------|------|-------------|
| `Container` | `Frame` | Toggle frame (51x31 at scale=1) |
| `SetState(state)` | method | Programmatically set state |
| `GetState()` | method | Get current state |
| `Destroy()` | method | Cleanup |

#### Example

```lua
local toggle = ui.tgl({
    Position = UDim2.new(0, 20, 0, 20),
    Theme = ui.Dark,
    InitialState = true,
    OnToggled = function(isOn)
        print("Toggle:", isOn)
    end,
    Parent = panel.GlassSurface,
})
```

---

### MangoSlider

Apple-style slider with 6px glass track, colored fill, and a 28px thumb that grows to 34px on drag.

**Constructor:** `ui.sldr(config)` or `ui.MangoSlider.new(config)`

#### Config

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `Position` | `UDim2` | *required* | Slider position |
| `Size` | `UDim2?` | `(0, 200, 0, 36)` | Slider size |
| `AnchorPoint` | `Vector2?` | `(0, 0)` | Anchor point |
| `Theme` | `ThemePreset?` | Light | Theme preset |
| `InitialValue` | `number?` | min value | Starting value |
| `Min` | `number?` | `0` | Minimum value |
| `Max` | `number?` | `1` | Maximum value |
| `Step` | `number?` | `0` | Step increment (0 = continuous) |
| `OnChanged` | `((value: number) -> ())?` | `nil` | Value change callback |
| `Parent` | `GuiObject?` | `nil` | Parent instance |

#### Returns

| Field | Type | Description |
|-------|------|-------------|
| `Container` | `Frame` | Slider frame |
| `SetValue(value)` | method | Set value programmatically |
| `GetValue()` | method | Get current value |
| `Destroy()` | method | Cleanup |

#### Example

```lua
local slider = ui.sldr({
    Position = UDim2.new(0, 20, 0, 60),
    Size = UDim2.new(0, 250, 0, 36),
    Min = 0,
    Max = 100,
    Step = 1,
    InitialValue = 50,
    Theme = ui.Mango,
    OnChanged = function(value)
        print("Slider:", value)
    end,
    Parent = panel.GlassSurface,
})
```

---

### MangoCheckbox

Animated checkbox with UIScale fill animation and optional label.

**Constructor:** `ui.chk(config)` or `ui.MangoCheckbox.new(config)`

#### Config

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `Position` | `UDim2` | *required* | Checkbox position |
| `AnchorPoint` | `Vector2?` | `(0, 0)` | Anchor point |
| `Label` | `string?` | `nil` | Optional text label |
| `InitialState` | `boolean?` | `false` | Starting checked state |
| `Theme` | `ThemePreset?` | Light | Theme preset |
| `OnToggled` | `((state: boolean) -> ())?` | `nil` | State change callback |
| `Parent` | `GuiObject?` | `nil` | Parent instance |

#### Returns

| Field | Type | Description |
|-------|------|-------------|
| `Container` | `Frame` | Checkbox + label frame |
| `SetState(state)` | method | Set checked state |
| `GetState()` | method | Get checked state |
| `Destroy()` | method | Cleanup |

#### Example

```lua
local checkbox = ui.chk({
    Position = UDim2.new(0, 20, 0, 100),
    Label = "Enable notifications",
    InitialState = true,
    Theme = ui.Dark,
    OnToggled = function(checked)
        print("Checked:", checked)
    end,
    Parent = panel.GlassSurface,
})
```

---

### MangoStepper

Numeric +/- stepper input with glass pill shape and long-press repeat.

**Constructor:** `ui.step(config)` or `ui.MangoStepper.new(config)`

#### Config

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `Position` | `UDim2` | *required* | Stepper position |
| `AnchorPoint` | `Vector2?` | `(0, 0)` | Anchor point |
| `InitialValue` | `number?` | `0` | Starting value |
| `Min` | `number?` | `0` | Minimum value |
| `Max` | `number?` | `100` | Maximum value |
| `Step` | `number?` | `1` | Increment amount |
| `Theme` | `ThemePreset?` | Light | Theme preset |
| `OnChanged` | `((value: number) -> ())?` | `nil` | Value change callback |
| `Parent` | `GuiObject?` | `nil` | Parent instance |

#### Returns

| Field | Type | Description |
|-------|------|-------------|
| `Container` | `Frame` | Stepper frame (120x36) |
| `SetValue(value)` | method | Set value programmatically |
| `GetValue()` | method | Get current value |
| `Destroy()` | method | Cleanup |

#### Example

```lua
local stepper = ui.step({
    Position = UDim2.new(0, 20, 0, 140),
    Min = 1,
    Max = 10,
    Step = 1,
    InitialValue = 5,
    Theme = ui.Mint,
    OnChanged = function(value)
        print("Quantity:", value)
    end,
    Parent = panel.GlassSurface,
})
```

---

### MangoProgressBar

Glass capsule progress bar matching the slider track visual style.

**Constructor:** `ui.prog(config)` or `ui.MangoProgressBar.new(config)`

#### Config

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `Position` | `UDim2` | *required* | Bar position |
| `Size` | `UDim2?` | `(0, 200, 0, 20)` | Bar size |
| `AnchorPoint` | `Vector2?` | `(0, 0)` | Anchor point |
| `InitialValue` | `number?` | `0` | Starting value (0-1) |
| `Theme` | `ThemePreset?` | Light | Theme preset |
| `Parent` | `GuiObject?` | `nil` | Parent instance |

#### Returns

| Field | Type | Description |
|-------|------|-------------|
| `Container` | `Frame` | Progress bar frame |
| `SetValue(value)` | method | Set progress (0-1), animated |
| `GetValue()` | method | Get current value |
| `Destroy()` | method | Cleanup |

#### Example

```lua
local progress = ui.prog({
    Position = UDim2.new(0, 20, 0, 180),
    Size = UDim2.new(0, 300, 0, 20),
    InitialValue = 0.6,
    Theme = ui.Mango,
    Parent = panel.GlassSurface,
})

-- Animate to new value (0.3s Quad Out)
progress:SetValue(0.85)
```

---

### MangoSegmentedControl

Apple-style segmented control with sliding selected indicator.

**Constructor:** `ui.seg(config)` or `ui.MangoSegmentedControl.new(config)`

#### Config

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `Position` | `UDim2` | *required* | Control position |
| `AnchorPoint` | `Vector2?` | `(0, 0)` | Anchor point |
| `Segments` | `{string}` | *required* | Segment labels |
| `InitialIndex` | `number?` | `1` | Initially selected segment |
| `SegmentWidth` | `number?` | `90` | Width per segment in px |
| `Height` | `number?` | `36` | Control height in px |
| `Theme` | `ThemePreset?` | Light | Theme preset |
| `OnChanged` | `((index: number) -> ())?` | `nil` | Selection change callback |
| `Parent` | `GuiObject?` | `nil` | Parent instance |

#### Returns

| Field | Type | Description |
|-------|------|-------------|
| `Container` | `Frame` | Control frame |
| `SetIndex(index)` | method | Select segment |
| `GetIndex()` | method | Get selected index |
| `Destroy()` | method | Cleanup |

#### Example

```lua
local seg = ui.seg({
    Position = UDim2.new(0.5, 0, 0, 20),
    AnchorPoint = Vector2.new(0.5, 0),
    Segments = {"Daily", "Weekly", "Monthly"},
    InitialIndex = 1,
    Theme = ui.Dark,
    OnChanged = function(index)
        print("Selected segment:", index)
    end,
    Parent = panel.GlassSurface,
})
```

---

### MangoColorPicker

HSV color picker with glass-styled panel, saturation-brightness box, hue bar, and live hex preview.

**Constructor:** `ui.colr(config)` or `ui.MangoColorPicker.new(config)`

#### Config

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `Position` | `UDim2` | *required* | Picker position |
| `Size` | `UDim2?` | `(0, 260, 0, 200)` | Panel size |
| `AnchorPoint` | `Vector2?` | `(0, 0)` | Anchor point |
| `InitialColor` | `Color3?` | `Color3.fromRGB(255, 0, 0)` | Starting color |
| `Theme` | `ThemePreset?` | Light | Theme preset |
| `OnChanged` | `((color: Color3) -> ())?` | `nil` | Color change callback |
| `Parent` | `GuiObject?` | `nil` | Parent instance |

#### Returns

| Field | Type | Description |
|-------|------|-------------|
| `Container` | `Frame` | Picker frame |
| `GetColor()` | method | Get current Color3 |
| `SetColor(color)` | method | Set color programmatically |
| `Destroy()` | method | Cleanup |

#### Features

- Saturation-brightness box with overlaid gradients + draggable cursor
- Rainbow hue bar (7-point ColorSequence)
- Live color preview circle + hex label (e.g. `#FF0000`)
- Glass-styled via MangoGlassFrame (LightweightMode)
- Drag anywhere, updates live

#### Example

```lua
local picker = ui.colr({
    Position = UDim2.new(0, 10, 0, 50),
    InitialColor = Color3.fromRGB(255, 100, 50),
    Theme = ui.Dark,
    OnChanged = function(color)
        print("Color:", color)
    end,
    Parent = panel.GlassSurface,
})

-- Programmatic access
picker:SetColor(Color3.fromRGB(0, 255, 128))
print(picker:GetColor())
```

---

### MangoKeybind

Keybind capture input with a glass pill button. Click to listen, press any key to bind.

**Constructor:** `ui.key(config)` or `ui.MangoKeybind.new(config)`

#### Config

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `Position` | `UDim2` | *required* | Keybind position |
| `AnchorPoint` | `Vector2?` | `(0, 0)` | Anchor point |
| `Label` | `string?` | `nil` | Optional text label |
| `DefaultKey` | `string?` | `"None"` | Initial bound key name |
| `Theme` | `ThemePreset?` | Light | Theme preset |
| `OnKeyChanged` | `((keyName: string) -> ())?` | `nil` | Key change callback |
| `Parent` | `GuiObject?` | `nil` | Parent instance |

#### Returns

| Field | Type | Description |
|-------|------|-------------|
| `Container` | `Frame` | Keybind frame |
| `GetKey()` | method | Get current key name |
| `SetKey(keyName)` | method | Set key programmatically |
| `Destroy()` | method | Cleanup |

#### Features

- Glass pill button showing abbreviated key name (e.g. `LeftShift` -> `LShift`)
- **Click** to enter listening mode (shows `"..."` with pulse animation)
- **Press any key** to capture the binding
- **Escape** cancels listening
- **Click away** cancels listening
- Hover animation (1.02x scale, glass thickens)

#### Example

```lua
local keybind = ui.key({
    Position = UDim2.new(0, 10, 0, 50),
    Label = "Sprint Key",
    DefaultKey = "LeftShift",
    Theme = ui.Dark,
    OnKeyChanged = function(keyName)
        print("Bound to:", keyName)
    end,
    Parent = panel.GlassSurface,
})

keybind:SetKey("LeftControl")
print(keybind:GetKey()) -- "LeftControl"
```

---

## Text Input

### MangoTextField

Rounded rectangle text input with animated focus border. Supports password masking.

**Constructor:** `ui.txt(config)` or `ui.MangoTextField.new(config)`

#### Config

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `Position` | `UDim2` | *required* | Field position |
| `Size` | `UDim2?` | `(0, 280, 0, 40)` | Field size |
| `AnchorPoint` | `Vector2?` | `(0, 0)` | Anchor point |
| `Placeholder` | `string?` | `nil` | Placeholder text |
| `InitialText` | `string?` | `nil` | Initial input text |
| `Masked` | `boolean?` | `false` | Password mode (shows dots) |
| `Theme` | `ThemePreset?` | Light | Theme preset |
| `OnTextChanged` | `((text: string) -> ())?` | `nil` | Text change callback |
| `OnFocusLost` | `((text: string, enterPressed: boolean) -> ())?` | `nil` | Focus lost callback |
| `Parent` | `GuiObject?` | `nil` | Parent instance |

#### Returns

| Field | Type | Description |
|-------|------|-------------|
| `Container` | `Frame` | Field frame |
| `GetText()` | method | Get current text (real text, not masked) |
| `SetText(text)` | method | Set text programmatically |
| `Focus()` | method | Focus the input |
| `Destroy()` | method | Cleanup |

#### Masked Mode (Password)

When `Masked = true`:
- Text displays as dots (`●`)
- An eye toggle button (👁) appears on the right to show/hide the password
- `GetText()` always returns the real text, not dots
- `SetText()` works normally

```lua
local passwordField = ui.txt({
    Position = UDim2.new(0, 20, 0, 60),
    Placeholder = "Enter password...",
    Masked = true,
    Theme = ui.Dark,
    OnFocusLost = function(text, enterPressed)
        if enterPressed then
            login(text) -- receives real text, not dots
        end
    end,
    Parent = panel.GlassSurface,
})
```

**Note:** MangoTextField uses CornerRadius=10 (rounded rectangle), not pill shape.

---

### MangoSearchBar

Pill-shaped glass search bar with search icon, TextBox, and clear button.

**Constructor:** `ui.srch(config)` or `ui.MangoSearchBar.new(config)`

#### Config

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `Position` | `UDim2` | *required* | Bar position |
| `Size` | `UDim2?` | auto | Bar size |
| `AnchorPoint` | `Vector2?` | `(0, 0)` | Anchor point |
| `Placeholder` | `string?` | `nil` | Placeholder text |
| `Theme` | `ThemePreset?` | Light | Theme preset |
| `OnTextChanged` | `((text: string) -> ())?` | `nil` | Text change callback |
| `OnSubmit` | `((text: string) -> ())?` | `nil` | Enter key callback |
| `Parent` | `GuiObject?` | `nil` | Parent instance |

#### Returns

| Field | Type | Description |
|-------|------|-------------|
| `Container` | `Frame` | Search bar frame |
| `GetText()` | method | Get search text |
| `SetText(text)` | method | Set search text |
| `Focus()` | method | Focus the input |
| `Destroy()` | method | Cleanup |

#### Example

```lua
local search = ui.srch({
    Position = UDim2.new(0.5, 0, 0, 10),
    AnchorPoint = Vector2.new(0.5, 0),
    Placeholder = "Search...",
    Theme = ui.Dark,
    OnTextChanged = function(text)
        filterResults(text)
    end,
    Parent = panel.GlassSurface,
})
```

---

## Navigation

### MangoDropdown

Apple-style dropdown menu with glass trigger and panel. Supports single-select and multi-select modes.

**Constructor:** `ui.drp(config)` or `ui.MangoDropdown.new(config)`

#### Config

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `Position` | `UDim2` | *required* | Dropdown position |
| `Size` | `UDim2?` | `(0, 200, 0, 36)` | Trigger button size |
| `AnchorPoint` | `Vector2?` | `(0, 0)` | Anchor point |
| `Items` | `{string}` | *required* | List of options |
| `InitialIndex` | `number?` | `1` | Initially selected item (single-select) |
| `InitialItems` | `{string}?` | `nil` | Initially selected items (multi-select) |
| `MultiSelect` | `boolean?` | `false` | Enable multi-select mode |
| `Theme` | `ThemePreset?` | Light | Theme preset |
| `OnChanged` | `((index: number) -> ())?` | `nil` | Selection change callback (single-select) |
| `OnMultiChanged` | `(({string}) -> ())?` | `nil` | Selection change callback (multi-select) |
| `Parent` | `GuiObject?` | `nil` | Parent instance |

#### Returns

| Field | Type | Description |
|-------|------|-------------|
| `Container` | `Frame` | Dropdown frame |
| `SetSelectedIndex(index)` | method | Set selected item (single-select) |
| `GetSelectedIndex()` | method | Get selected index (single-select) |
| `GetSelectedItems()` | method | Get selected items as `{string}` (multi-select) |
| `SetItems(items)` | method | Replace all items |
| `Open()` | method | Open the panel |
| `Close()` | method | Close the panel |
| `Destroy()` | method | Cleanup |

#### Multi-Select Mode

When `MultiSelect = true`:
- Items show checkboxes instead of radio-style checkmarks
- Multiple items can be selected simultaneously
- Trigger button shows joined text ("Players, NPCs") or count ("3 selected")
- Panel stays open after each selection
- Use `OnMultiChanged` to get the `{string}` array of selected items

```lua
-- Single-select (default)
local dropdown = ui.drp({
    Position = UDim2.new(0, 20, 0, 20),
    Items = {"Option A", "Option B", "Option C"},
    InitialIndex = 1,
    Theme = ui.Mango,
    OnChanged = function(index)
        print("Selected:", index)
    end,
    Parent = panel.GlassSurface,
})

-- Multi-select
local multiDrop = ui.drp({
    Position = UDim2.new(0, 20, 0, 70),
    Items = {"Players", "NPCs", "Items"},
    MultiSelect = true,
    InitialItems = {"Players"},
    Theme = ui.Dark,
    OnMultiChanged = function(selected)
        print("Selected:", table.concat(selected, ", "))
    end,
    Parent = panel.GlassSurface,
})

-- Get selected items
local items = multiDrop:GetSelectedItems() -- {"Players"}
```

---

### MangoTabBar

Bottom tab bar with dot indicator and icon/label support.

**Constructor:** `ui.tab(config)` or `ui.MangoTabBar.new(config)`

#### Config

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `Tabs` | `{{Icon: string?, Label: string}}` | *required* | Tab definitions |
| `InitialIndex` | `number?` | `1` | Initially selected tab |
| `Theme` | `ThemePreset?` | Light | Theme preset |
| `OnChanged` | `((index: number) -> ())?` | `nil` | Tab change callback |
| `Parent` | `GuiObject?` | `nil` | Parent instance |

#### Returns

| Field | Type | Description |
|-------|------|-------------|
| `Container` | `Frame` | Tab bar frame (full-width, 54px tall) |
| `SetIndex(index)` | method | Select tab |
| `GetIndex()` | method | Get selected tab index |
| `Destroy()` | method | Cleanup |

#### Example

```lua
local tabBar = ui.tab({
    Tabs = {
        {Icon = "home-icon-id", Label = "Home"},
        {Label = "Search"},
        {Label = "Profile"},
    },
    InitialIndex = 1,
    Theme = ui.Dark,
    OnChanged = function(index)
        showTab(index)
    end,
    Parent = screen,
})
```

---

### MangoContextMenu

Right-click glass context menu. Triggers on MouseButton2 (right-click) and touch long-press.

**Constructor:** `ui.ctx(config)` or `ui.MangoContextMenu.new(config)`

#### Config

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `Target` | `GuiObject` | *required* | Element that triggers the menu |
| `Items` | `{MangoContextMenuItemConfig}` | *required* | Menu items |
| `Theme` | `ThemePreset?` | Light | Theme preset |
| `Parent` | `GuiObject?` | `nil` | Parent instance |

**MangoContextMenuItemConfig:**

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `Text` | `string` | *required* | Item label |
| `Icon` | `string?` | `nil` | Optional icon text |
| `Style` | `string?` | `"default"` | `"default"` or `"destructive"` |
| `Disabled` | `boolean?` | `false` | Gray out and prevent clicks |
| `OnActivated` | `(() -> ())?` | `nil` | Click callback |

#### Returns

| Field | Type | Description |
|-------|------|-------------|
| `Open(position?)` | method | Open at position (Vector2) |
| `Close()` | method | Close the menu |
| `SetItems(items)` | method | Replace all items |
| `Destroy()` | method | Cleanup |

#### Example

```lua
local ctx = ui.ctx({
    Target = someFrame,
    Items = {
        {Text = "Copy", OnActivated = function() copy() end},
        {Text = "Paste", OnActivated = function() paste() end},
        {Text = "Delete", Style = "destructive", OnActivated = function() delete() end},
    },
    Theme = ui.Dark,
})
```

---

### MangoCarousel

Apple Watch-style vertical carousel with paraboloid focus scaling, infinite loop wrapping, and smooth scrolling.

**Constructor:** `ui.carousel(config)` or `ui.csel(config)` or `ui.MangoCarousel.new(config)`

#### Config

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `Tabs` | `{MangoCarouselTabConfig}` | *required* | Carousel tab definitions |
| `Position` | `UDim2?` | `(0, 8, 1, -62)` | Carousel position |
| `Size` | `UDim2?` | auto from tab count | Carousel size |
| `AnchorPoint` | `Vector2?` | `(0, 1)` | Anchor point |
| `InitialIndex` | `number?` | `1` | Initially focused tab |
| `IconSize` | `number?` | `44` | Icon size in pixels |
| `Theme` | `ThemePreset?` | Light | Theme preset |
| `OnChanged` | `((index: number) -> ())?` | `nil` | Tab change callback |
| `Parent` | `GuiObject?` | `nil` | Parent instance |

**MangoCarouselTabConfig:**

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `Icon` | `string?` | `nil` | Icon emoji or text |
| `Label` | `string?` | `nil` | Tab label |
| `Color` | `Color3?` | default accent | Tab accent color |

#### Returns

| Field | Type | Description |
|-------|------|-------------|
| `Container` | `Frame` | Carousel frame |
| `SetIndex(index)` | method | Navigate to tab (animated) |
| `GetIndex()` | method | Get current tab index |
| `Destroy()` | method | Cleanup |

#### Features

- **Paraboloid focus**: Center icon 1.0x, adjacent 0.75x, far 0.50x
- **Infinite loop wrapping**: Scrolling past last wraps to first (and vice versa)
- **Variable scroll duration**: 0.22 + delta * 0.03s per scroll step
- **Mouse wheel + touch swipe** input support
- **Per-icon 7-layer styling**: shadow, glass bg, highlight, specular, emoji, active dot, hit area
- **Active dot animation**: UIScale 0 -> 1 (0.3s Back Out)
- Glass dock backdrop with fresnel rim and inner edge

#### Example

```lua
local carousel = ui.carousel({
    Tabs = {
        {Icon = "🏠", Label = "Home", Color = Color3.fromRGB(90, 135, 230)},
        {Icon = "⚙", Label = "Settings", Color = Color3.fromRGB(175, 100, 220)},
        {Icon = "🔥", Label = "Effects", Color = Color3.fromRGB(230, 140, 70)},
    },
    InitialIndex = 1,
    Theme = ui.Dark,
    OnChanged = function(index)
        switchTab(index)
    end,
    Parent = screen,
})

carousel:SetIndex(2) -- Navigate to Settings
```

---

## Overlays & Modals

### MangoDialog

Centered modal dialog with Apple-style button layouts.

**Constructor:** `ui.dlg(config)` or `ui.MangoDialog.new(config)`

#### Config

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `Title` | `string` | *required* | Dialog title |
| `Message` | `string?` | `nil` | Body message |
| `Buttons` | `{MangoDialogButtonConfig}?` | `[{Text="OK"}]` | Action buttons |
| `Theme` | `ThemePreset?` | Light | Theme preset |
| `OnDismissed` | `(() -> ())?` | `nil` | Dismiss callback |
| `Parent` | `Instance?` | PlayerGui | Parent instance |

**MangoDialogButtonConfig:**

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `Text` | `string` | *required* | Button label |
| `Style` | `string?` | `"default"` | `"default"`, `"cancel"` (bold), `"destructive"` (red) |
| `OnActivated` | `(() -> ())?` | `nil` | Click callback |

#### Returns

| Field | Type | Description |
|-------|------|-------------|
| `Show()` | method | Display the dialog |
| `Dismiss()` | method | Dismiss with animation |
| `Destroy()` | method | Cleanup |

#### Example

```lua
local dialog = ui.dlg({
    Title = "Delete Item?",
    Message = "This action cannot be undone.",
    Theme = ui.Dark,
    Buttons = {
        {Text = "Cancel", Style = "cancel"},
        {Text = "Delete", Style = "destructive", OnActivated = function()
            deleteItem()
        end},
    },
})
dialog:Show()
```

---

### MangoActionSheet

Bottom action sheet with separate cancel button.

**Constructor:** `ui.act(config)` or `ui.MangoActionSheet.new(config)`

#### Config

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `Title` | `string?` | `nil` | Sheet title |
| `Message` | `string?` | `nil` | Description text |
| `Actions` | `{MangoActionSheetActionConfig}` | *required* | Action buttons |
| `CancelText` | `string?` | `"Cancel"` | Cancel button text |
| `Theme` | `ThemePreset?` | Light | Theme preset |
| `OnDismissed` | `(() -> ())?` | `nil` | Dismiss callback |
| `Parent` | `Instance?` | PlayerGui | Parent instance |

**MangoActionSheetActionConfig:**

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `Text` | `string` | *required* | Action label |
| `Style` | `string?` | `"default"` | `"default"` or `"destructive"` |
| `OnActivated` | `(() -> ())?` | `nil` | Click callback |

#### Returns

| Field | Type | Description |
|-------|------|-------------|
| `Show()` | method | Slide up the sheet |
| `Dismiss()` | method | Slide away |
| `Destroy()` | method | Cleanup |

#### Example

```lua
local sheet = ui.act({
    Title = "Share Photo",
    Actions = {
        {Text = "Save to Gallery", OnActivated = function() save() end},
        {Text = "Copy Link", OnActivated = function() copyLink() end},
        {Text = "Delete", Style = "destructive", OnActivated = function() delete() end},
    },
    CancelText = "Cancel",
    Theme = ui.Mango,
})
sheet:Show()
```

---

### MangoNotification

Glass notification banner that slides in from the top. Supports notification types and action buttons.

**Constructor:** `ui.notif(config)` or `ui.MangoNotification.new(config)`

#### Config

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `Title` | `string` | *required* | Notification title |
| `Body` | `string?` | `nil` | Body text |
| `Icon` | `string?` | `nil` | Icon image asset ID |
| `Duration` | `number?` | `5` | Auto-dismiss seconds (0 = no auto-dismiss) |
| `Type` | `string?` | `nil` | `"success"`, `"warning"`, `"error"`, or `"info"` |
| `Actions` | `{MangoNotificationActionConfig}?` | `nil` | Action buttons |
| `Theme` | `ThemePreset?` | Light | Theme preset |
| `OnDismissed` | `(() -> ())?` | `nil` | Dismiss callback |
| `Parent` | `Instance?` | PlayerGui | Parent instance |

**MangoNotificationActionConfig:**

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `Text` | `string` | *required* | Button label |
| `Style` | `string?` | `"default"` | `"default"` or `"cancel"` (dimmer text) |
| `Callback` | `(() -> ())?` | `nil` | Click callback (auto-dismisses after) |

#### Notification Types

| Type | Icon | Accent Color |
|------|------|-------------|
| `"success"` | Checkmark circle | Green `(34, 197, 94)` |
| `"warning"` | Warning triangle | Amber `(245, 158, 11)` |
| `"error"` | X circle | Red `(239, 68, 68)` |
| `"info"` | Info circle | Blue `(59, 130, 246)` |

When `Type` is set:
- Auto-sets icon emoji if no explicit `Icon` is provided
- Adds a colored 3px accent stripe on the left edge

#### Returns

| Field | Type | Description |
|-------|------|-------------|
| `Container` | `Frame` | Notification frame |
| `Show()` | method | Slide in from top |
| `Dismiss()` | method | Slide out |
| `SetPosition(position)` | method | Move (for stacking) |
| `GetHeight()` | method | Get pixel height |
| `Destroy()` | method | Cleanup |

#### Examples

```lua
-- Basic notification
local notif = ui.notif({
    Title = "Achievement Unlocked",
    Body = "You completed the first level!",
    Duration = 4,
    Theme = ui.Mango,
})
notif:Show()

-- Typed notification with accent stripe
ui.notif({
    Title = "Success!",
    Body = "File saved successfully.",
    Duration = 3,
    Type = "success",
    Theme = ui.Dark,
}):Show()

-- Notification with action buttons
ui.notif({
    Title = "Update Available",
    Body = "v2.0 is ready to install.",
    Duration = 0,  -- persist until dismissed
    Type = "info",
    Actions = {
        {Text = "Update", Callback = function() doUpdate() end},
        {Text = "Later", Style = "cancel"},
    },
    Theme = ui.Dark,
}):Show()
```

---

### MangoNotificationStack

Manages multiple notifications with stacking layout.

**Constructor:** `ui.nstack(config)` or `ui.MangoNotificationStack.new(config)`

#### Config

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `MaxVisible` | `number?` | `3` | Maximum visible notifications |
| `StackGap` | `number?` | theme / `14` | Gap between notifications |
| `Theme` | `ThemePreset?` | Light | Theme preset |
| `Parent` | `Instance?` | PlayerGui | Parent instance |

#### Returns

| Field | Type | Description |
|-------|------|-------------|
| `Push(config)` | method | Create and show a notification |
| `DismissAll()` | method | Dismiss all visible |
| `GetCount()` | method | Current count |
| `Destroy()` | method | Cleanup all |

#### Example

```lua
local stack = ui.nstack({
    MaxVisible = 3,
    Theme = ui.Dark,
})

stack:Push({Title = "Message 1", Body = "Hello!"})
stack:Push({Title = "Error!", Body = "Something went wrong.", Type = "error"})
```

---

### MangoToast

Bottom-center toast notification. Simpler than MangoNotification — single-line pill that slides up.

**Constructor:** `ui.toast(config)` or `ui.MangoToast.new(config)`

#### Config

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `Text` | `string` | *required* | Toast message |
| `Icon` | `string?` | `nil` | Optional icon text |
| `Duration` | `number?` | `3` | Auto-dismiss seconds (0 = no auto-dismiss) |
| `Theme` | `ThemePreset?` | Light | Theme preset |
| `OnDismissed` | `(() -> ())?` | `nil` | Dismiss callback |
| `Parent` | `Instance?` | PlayerGui | Parent instance |

#### Returns

| Field | Type | Description |
|-------|------|-------------|
| `Container` | `Frame` | Toast frame |
| `Show()` | method | Slide up from bottom |
| `Dismiss()` | method | Slide down and out |
| `SetPosition(position)` | method | Move (for stacking) |
| `GetHeight()` | method | Get pixel height |
| `Destroy()` | method | Cleanup |

---

### MangoToastStack

Manages multiple toasts stacking upward from the bottom.

**Constructor:** `ui.tstack(config)` or `ui.MangoToast.newStack(config)`

#### Config

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `MaxVisible` | `number?` | `3` | Maximum visible toasts |
| `StackGap` | `number?` | `8` | Gap between toasts |
| `Theme` | `ThemePreset?` | Light | Theme preset |
| `Parent` | `Instance?` | PlayerGui | Parent instance |

#### Returns

| Field | Type | Description |
|-------|------|-------------|
| `Push(config)` | method | Create and show a toast |
| `DismissAll()` | method | Dismiss all |
| `GetCount()` | method | Current count |
| `Destroy()` | method | Cleanup |

#### Example

```lua
local toasts = ui.tstack({
    MaxVisible = 3,
    Theme = ui.Mango,
})

toasts:Push({Text = "Item saved!"})
toasts:Push({Text = "Settings updated", Duration = 2})
```

---

### MangoTooltip

Glass popover tooltip that appears on hover with auto-positioning.

**Constructor:** `ui.tip(config)` or `ui.MangoTooltip.new(config)`

#### Config

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `Target` | `GuiObject` | *required* | Element to attach tooltip to |
| `Text` | `string` | *required* | Tooltip text |
| `TextSize` | `number?` | `13` | Font size |
| `MaxWidth` | `number?` | `200` | Maximum tooltip width |
| `Delay` | `number?` | `0.5` | Seconds before showing |
| `Placement` | `string?` | `"auto"` | `"auto"`, `"top"`, `"bottom"`, `"left"`, `"right"` |
| `ArrowSize` | `number?` | `8` | Arrow indicator size |
| `Theme` | `ThemePreset?` | Light | Theme preset |
| `Parent` | `GuiObject?` | `nil` | Parent instance |

#### Returns

| Field | Type | Description |
|-------|------|-------------|
| `Show()` | method | Show tooltip immediately |
| `Hide()` | method | Hide tooltip |
| `SetText(text)` | method | Update text content |
| `Destroy()` | method | Cleanup |

#### Example

```lua
local tooltip = ui.tip({
    Target = someButton.Container,
    Text = "Click to save your progress",
    Delay = 0.3,
    Theme = ui.Dark,
})
```

---

### MangoBottomSheet

Draggable bottom sheet with snap positions, overlay, and dismiss threshold.

**Constructor:** `ui.bsheet(config)` or `ui.MangoBottomSheet.new(config)`

#### Config

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `Title` | `string?` | `nil` | Sheet title |
| `ContentSize` | `UDim2?` | `(1, 0, 1, 0)` | Content frame size |
| `SnapPositions` | `{number}?` | `{0.4, 0.8}` | Snap points (viewport height fractions) |
| `InitialSnap` | `number?` | `1` | Index into SnapPositions |
| `DismissThreshold` | `number?` | `0.15` | Fraction below which sheet dismisses |
| `Theme` | `ThemePreset?` | Light | Theme preset |
| `OnDismissed` | `(() -> ())?` | `nil` | Dismiss callback |
| `OnSnapChanged` | `((snapIndex: number) -> ())?` | `nil` | Snap position change callback |
| `Parent` | `Instance?` | PlayerGui | Parent instance |

#### Returns

| Field | Type | Description |
|-------|------|-------------|
| `Container` | `Frame` | Sheet container |
| `ContentFrame` | `Frame` | **Parent your content here** |
| `Show()` | method | Animate sheet into view |
| `Dismiss()` | method | Slide down and dismiss |
| `SnapTo(snapIndex)` | method | Snap to position |
| `Destroy()` | method | Cleanup |

#### Example

```lua
local sheet = ui.bsheet({
    Title = "Settings",
    SnapPositions = {0.4, 0.7},
    InitialSnap = 1,
    Theme = ui.Dark,
    OnDismissed = function()
        print("Sheet dismissed")
    end,
})
sheet:Show()

-- Add content to the sheet
local label = Instance.new("TextLabel")
label.Text = "Sheet content goes here"
label.Parent = sheet.ContentFrame
```

---

## Display

### MangoBillboardLabel

Overhead glass name tag using BillboardGui. Simplified hierarchy for performance.

**Constructor:** `ui.bbl(config)` or `ui.MangoBillboardLabel.new(config)`

#### Config

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `TargetPart` | `BasePart?` | `nil` | Part to attach to |
| `TargetCharacter` | `Model?` | `nil` | Character (auto-finds Head) |
| `Text` | `string` | *required* | Label text |
| `TextSize` | `number?` | `14` | Font size |
| `Theme` | `ThemePreset?` | Light | Theme preset |
| `MaxDistance` | `number?` | `50` | Max visible distance in studs |
| `StudsOffset` | `Vector3?` | `(0, 2.2, 0)` | Offset from part |
| `AlwaysOnTop` | `boolean?` | `false` | Render on top of 3D |
| `Parent` | `Instance?` | `nil` | Parent instance |

#### Returns

| Field | Type | Description |
|-------|------|-------------|
| `BillboardGui` | `BillboardGui` | The BillboardGui |
| `GlassSurface` | `Frame` | Glass surface frame |
| `TextLabel` | `TextLabel` | The text label |
| `SetText(text)` | method | Update label text |
| `Destroy()` | method | Cleanup |

#### Example

```lua
local label = ui.bbl({
    TargetCharacter = game.Players.LocalPlayer.Character,
    Text = "Player Name",
    Theme = ui.Mango,
    MaxDistance = 40,
})
```

---

### MangoBadge

Small glass pill badge for counts, tags, or status indicators.

**Constructor:** `ui.bdg(config)` or `ui.MangoBadge.new(config)`

#### Config

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `Position` | `UDim2` | *required* | Badge position |
| `AnchorPoint` | `Vector2?` | `(0, 0)` | Anchor point |
| `Text` | `string` | *required* | Badge text |
| `TextSize` | `number?` | `12` | Font size |
| `TextColor` | `Color3?` | theme / white | Text color |
| `BackgroundColor` | `Color3?` | theme / accent | Badge background |
| `BackgroundTransparency` | `number?` | theme / `0.15` | Badge opacity |
| `Theme` | `ThemePreset?` | Light | Theme preset |
| `Parent` | `GuiObject?` | `nil` | Parent instance |

#### Returns

| Field | Type | Description |
|-------|------|-------------|
| `Container` | `Frame` | Badge frame |
| `SetText(text)` | method | Update text (auto-resizes) |
| `Destroy()` | method | Cleanup |

#### Example

```lua
local badge = ui.bdg({
    Position = UDim2.new(1, -5, 0, -5),
    AnchorPoint = Vector2.new(1, 0),
    Text = "3",
    Theme = ui.Mango,
    Parent = someIcon,
})
```

---

### MangoSkeleton

Shimmer loading placeholder. A simple rounded frame with a continuous shimmer animation.

**Constructor:** `ui.skel(config)` or `ui.MangoSkeleton.new(config)`

#### Config

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `Size` | `UDim2` | *required* | Skeleton size |
| `Position` | `UDim2` | *required* | Skeleton position |
| `AnchorPoint` | `Vector2?` | `(0, 0)` | Anchor point |
| `CornerRadius` | `UDim?` | `UDim.new(0, 8)` | Corner rounding |
| `Theme` | `ThemePreset?` | Light | Theme preset |
| `Parent` | `GuiObject?` | `nil` | Parent instance |

#### Returns

| Field | Type | Description |
|-------|------|-------------|
| `Container` | `Frame` | Skeleton frame |
| `Destroy()` | method | Cleanup (stops shimmer) |

#### Example

```lua
local skel = ui.skel({
    Size = UDim2.new(1, 0, 0, 20),
    Position = UDim2.new(0, 0, 0, 0),
    Theme = ui.Dark,
    Parent = container,
})

-- When data loads, destroy skeleton
skel:Destroy()
```

---

### MangoShimmer

Reusable looping shimmer overlay. Creates a narrow-band light sweep that loops infinitely.

**Constructor:** `ui.shimr(config)` or `ui.MangoShimmer.new(config)`

#### Config

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `Target` | `GuiObject` | *required* | Element to overlay with shimmer |
| `ShimmerColor` | `Color3?` | theme / white | Shimmer light color |
| `ShimmerTransparency` | `number?` | theme / `0.85` | Shimmer overlay transparency |
| `ShimmerWidth` | `number?` | `0.08` | Width of the shimmer band (0-1) |
| `Duration` | `number?` | `1.2` | Sweep duration in seconds |
| `Enabled` | `boolean?` | `true` | Auto-enable on creation |
| `Theme` | `ThemePreset?` | Light | Theme preset |

#### Returns

| Field | Type | Description |
|-------|------|-------------|
| `Enable()` | method | Start shimmer animation |
| `Disable()` | method | Stop and hide shimmer |
| `IsEnabled()` | method | Get current state |
| `Destroy()` | method | Cleanup |

#### Example

```lua
local shimmer = ui.shimr({
    Target = someFrame,
    Duration = 1.5,
    Theme = ui.Mango,
})

shimmer:Disable()
shimmer:Enable()
```

---

## Visual Enhancements

### MangoBlurProxy

ViewportFrame-based blur approximation. Creates a low-resolution ViewportFrame that, when stretched to fill, produces natural pixel blur.

**Constructor:** `ui.blur(config)` or `ui.MangoBlurProxy.new(config)`

#### Config

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `TargetGui` | `GuiObject` | *required* | Element to blur behind |
| `BlurRadius` | `number?` | `8` | Blur amount (affects downscale) |
| `DownscaleFactor` | `number?` | `4` | Resolution reduction (higher = blurrier) |
| `UpdateInterval` | `number?` | `0.1` | Camera sync interval in seconds |
| `Enabled` | `boolean?` | `true` | Initial state |
| `Theme` | `ThemePreset?` | Light | Theme preset |
| `Parent` | `GuiObject?` | TargetGui | Parent instance |

#### Returns

| Field | Type | Description |
|-------|------|-------------|
| `Container` | `Frame` | Blur container frame |
| `SetEnabled(enabled)` | method | Toggle blur |
| `IsEnabled()` | method | Get current state |
| `Destroy()` | method | Cleanup |

#### Example

```lua
local blur = ui.blur({
    TargetGui = panel.GlassSurface,
    DownscaleFactor = 4,
    Theme = ui.Dark,
})
```

**Note:** This approximates blur since Roblox has no native UI blur. `BlurEffect` only works on the 3D workspace.

---

### MangoHaptics

Opt-in haptic feedback utility. Not a constructor — provides module-level functions.

**Access:** `ui.haptic` or `ui.MangoHaptics`

#### Functions

| Function | Description |
|----------|-------------|
| `ui.haptic.setEnabled(bool)` | Enable/disable haptic feedback globally |
| `ui.haptic.isEnabled()` | Check if haptics are enabled |
| `ui.haptic.trigger(intensity?)` | Trigger vibration (0-1, default 0.5) |
| `ui.haptic.light()` | Light feedback (0.2 intensity) |
| `ui.haptic.medium()` | Medium feedback (0.5 intensity) |
| `ui.haptic.heavy()` | Heavy feedback (0.8 intensity) |

Haptics are **disabled by default** (opt-in).

```lua
ui.haptic.setEnabled(true)
-- Now all button clicks, toggle flips, etc. will vibrate
```

---

## Layout & Utilities

### MangoLayout

Lightweight layout utility wrapper for vstack, hstack, and grid arrangements.

**Constructor:** `ui.layout(config)` or `ui.MangoLayout.new(config)`

#### Config

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `Mode` | `string` | *required* | `"vstack"`, `"hstack"`, or `"grid"` |
| `Padding` | `number?` | `8` | Gap between children |
| `CellSize` | `UDim2?` | `(0, 100, 0, 100)` | Grid cell size (grid mode only) |
| `HorizontalAlignment` | `Enum.HorizontalAlignment?` | Left | Horizontal alignment |
| `VerticalAlignment` | `Enum.VerticalAlignment?` | Top | Vertical alignment |
| `PaddingTop` | `number?` | `0` | Top padding |
| `PaddingBottom` | `number?` | `0` | Bottom padding |
| `PaddingLeft` | `number?` | `0` | Left padding |
| `PaddingRight` | `number?` | `0` | Right padding |
| `Parent` | `GuiObject?` | `nil` | Parent instance |

#### Returns

| Field | Type | Description |
|-------|------|-------------|
| `Container` | `Frame` | Layout container (AutomaticSize) |
| `AddChild(child)` | method | Add element to layout |
| `RemoveChild(child)` | method | Remove element |
| `Clear()` | method | Remove all children |
| `Destroy()` | method | Cleanup |

#### Example

```lua
local vstack = ui.layout({
    Mode = "vstack",
    Padding = 12,
    PaddingTop = 10,
    Parent = panel.GlassSurface,
})

vstack:AddChild(ui.bttn({Text = "Button 1", Position = UDim2.new(0,0,0,0)}).Container)
vstack:AddChild(ui.bttn({Text = "Button 2", Position = UDim2.new(0,0,0,0)}).Container)
```

---

### MangoForm

Validated form builder that creates form fields from configuration and handles validation.

**Constructor:** `ui.form(config)` or `ui.MangoForm.new(config)`

#### Config

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `Position` | `UDim2` | *required* | Form position |
| `Size` | `UDim2?` | `(0, 300, 0, 0)` | Form size (auto-height) |
| `AnchorPoint` | `Vector2?` | `(0, 0)` | Anchor point |
| `Fields` | `{MangoFormFieldConfig}` | *required* | Field definitions |
| `SubmitText` | `string?` | `"Submit"` | Submit button text |
| `Theme` | `ThemePreset?` | Light | Theme preset |
| `OnSubmit` | `((values: {[string]: any}) -> ())?` | `nil` | Submit callback |
| `Parent` | `GuiObject?` | `nil` | Parent instance |

**MangoFormFieldConfig:**

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `Name` | `string` | *required* | Field identifier (used in values table) |
| `Type` | `string` | *required* | `"text"`, `"checkbox"`, `"dropdown"`, `"slider"` |
| `Label` | `string?` | `nil` | Field label |
| `Required` | `boolean?` | `false` | Show red asterisk, validate non-empty |
| `Placeholder` | `string?` | `nil` | Text field placeholder |
| `Items` | `{string}?` | `nil` | Dropdown items |
| `Min` | `number?` | `nil` | Slider/stepper minimum |
| `Max` | `number?` | `nil` | Slider/stepper maximum |
| `InitialValue` | `any?` | `nil` | Initial field value |
| `Validate` | `((value: any) -> (boolean, string?))?` | `nil` | Custom validator |

#### Returns

| Field | Type | Description |
|-------|------|-------------|
| `Container` | `Frame` | Form container (auto-height) |
| `GetValues()` | method | Get all field values as `{[name]: value}` |
| `Validate()` | method | Run validation, returns `true` if all pass |
| `SetFieldValue(name, value)` | method | Set a specific field value |
| `Destroy()` | method | Cleanup |

#### Example

```lua
local form = ui.form({
    Position = UDim2.new(0, 20, 0, 20),
    Size = UDim2.new(0, 350, 0, 0),
    Theme = ui.Mango,
    Fields = {
        {Name = "username", Type = "text", Label = "Username", Required = true},
        {Name = "role", Type = "dropdown", Label = "Role", Items = {"Admin", "Viewer"}},
        {Name = "agree", Type = "checkbox", Label = "I agree", Required = true},
    },
    SubmitText = "Create Account",
    OnSubmit = function(values)
        print("Username:", values.username)
    end,
    Parent = panel.GlassSurface,
})
```

---

### MangoFocusManager

Keyboard navigation system for Tab, Shift+Tab, Enter, and Escape across form inputs.

**Constructor:** `ui.focus(config)` or `ui.MangoFocusManager.new(config)`

#### Config

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `Inputs` | `{GuiObject}` | *required* | Ordered list of focusable elements |
| `SubmitCallback` | `(() -> ())?` | `nil` | Called when Enter is pressed |
| `DismissCallback` | `(() -> ())?` | `nil` | Called when Escape is pressed |
| `Enabled` | `boolean?` | `true` | Initial enabled state |

#### Returns

| Field | Type | Description |
|-------|------|-------------|
| `Register(input)` | method | Add an input to the focus list |
| `Unregister(input)` | method | Remove an input |
| `FocusNext()` | method | Move focus forward |
| `FocusPrevious()` | method | Move focus backward |
| `FocusIndex(index)` | method | Focus specific input |
| `SetEnabled(enabled)` | method | Enable/disable focus management |
| `Destroy()` | method | Cleanup |

#### Example

```lua
local focusMgr = ui.focus({
    Inputs = {nameField.Container, emailField.Container},
    SubmitCallback = function() print("Submitted!") end,
})
focusMgr:FocusIndex(1)
```

---

### MangoBuilder

Declarative chainable API for building components.

**Constructor:** `ui.build(componentType)` — returns a chainable builder

#### Chainable Methods

| Method | Description |
|--------|-------------|
| `:text(str)` | Set Text field |
| `:theme(themePreset)` | Set Theme |
| `:pos(xScale, xOffset, yScale, yOffset)` | Set Position |
| `:anchor(x, y)` | Set AnchorPoint |
| `:size(xScale, xOffset, yScale, yOffset)` | Set Size |
| `:parent(guiObject)` | Set Parent |
| `:onClick(callback)` | Set OnActivated callback |
| `:onChange(callback)` | Set OnChanged/OnToggled/OnTextChanged |
| `:prop(key, value)` | Set any config property |
| `:create()` | Build and return the component |

#### Component Type Strings

`"button"`, `"slider"`, `"toggle"`, `"checkbox"`, `"dialog"`, `"actionsheet"`, `"dropdown"`, `"tabbar"`, `"search"`, `"textfield"`, `"progress"`, `"glass"`, `"notification"`, `"notifstack"`, `"segmented"`, `"billboard"`, `"badge"`, `"skeleton"`, `"stepper"`, `"tooltip"`, `"toast"`, `"contextmenu"`, `"bottomsheet"`, `"blur"`, `"form"`, `"focus"`, `"layout"`, `"shimmer"`, `"window"`, `"carousel"`, `"colorpicker"`, `"keybind"`, `"savemanager"`

#### Example

```lua
local btn = ui.build("button")
    :text("Save")
    :theme(ui.Dark)
    :pos(0.5, 0, 0.5, 0)
    :anchor(0.5, 0.5)
    :onClick(function() print("Saved!") end)
    :parent(screen)
    :create()
```

---

### MangoSaveManager

Low-level configuration persistence module used internally by MangoWindow. Uses executor filesystem functions (`writefile`/`readfile`) with graceful fallback.

**Constructor:** `ui.MangoSaveManager.new(config)`

**Note:** Most users should use MangoWindow's `ConfigurationSaving` feature instead of using MangoSaveManager directly.

#### Config

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `FolderName` | `string` | *required* | Folder name for save files |
| `FileName` | `string?` | `"config"` | File name (without .json) |

#### Returns

| Field | Type | Description |
|-------|------|-------------|
| `Save(data)` | method | Save `{[string]: any}` as JSON, returns `boolean` success |
| `Load()` | method | Load saved data, returns `{[string]: any}?` |
| `Delete()` | method | Delete the save file, returns `boolean` success |

All operations are pcall-wrapped and gracefully no-op when executor filesystem functions are unavailable (e.g. in legitimate Roblox Studio games).

#### Example

```lua
local save = ui.MangoSaveManager.new({
    FolderName = "MyApp",
    FileName = "settings",
})

save:Save({volume = 80, difficulty = "hard"})

local data = save:Load()
if data then
    print(data.volume) -- 80
end

save:Delete()
```

---

## Utility Functions

### gui()

Creates a properly configured ScreenGui.

```lua
local screen = ui.gui("MyScreenName")
```

Returns a `ScreenGui` with:
- `ResetOnSpawn = false`
- `IgnoreGuiInset = true`
- `ZIndexBehavior = Sibling`
- Parented to `PlayerGui`

---

### transitionTheme()

Smoothly transitions glass frames between themes by fading out, rebuilding, and fading in.

```lua
ui.transitionTheme(
    {panel1, panel2},  -- Array of MangoGlassFrame instances to destroy
    0.3,               -- Fade duration in seconds
    function()         -- Rebuild callback: create and return new frames
        local newPanel1 = ui.glass({... Theme = ui.Dark ...})
        local newPanel2 = ui.glass({... Theme = ui.Dark ...})
        return {newPanel1, newPanel2}
    end
)
```

This is necessary because `NumberSequence` (used by `UIGradient.Transparency`) cannot be tweened with TweenService.

---

## Theme Customization

### Themes.custom()

Create a custom theme by extending an existing one:

```lua
local MyTheme = ui.Themes.custom(ui.Dark, {
    BackgroundColor3 = Color3.fromRGB(30, 20, 40),
    SliderFillColor = Color3.fromRGB(180, 50, 255),
    CheckboxOnColor = Color3.fromRGB(180, 50, 255),
    ToggleOnTrackColor = Color3.fromRGB(180, 50, 255),
    PrimaryTextColor = Color3.fromRGB(240, 240, 255),
})

local Window = ui.window({Name = "My App", Theme = MyTheme})
```

`Themes.custom()` performs a shallow clone of the base theme and merges overrides. The result works identically to built-in themes.

### Full Theme Property Reference

See `Types.luau` for the complete `ThemePreset` type definition. Key property groups:

| Group | Properties |
|-------|-----------|
| Glass surface | `BackgroundColor3`, `BackgroundTransparency` |
| Lens | `LensGroupColor3`, `LensGroupTransparency` |
| Inner glow | `InnerGlowColor`, `InnerGlowTransparency`, `InnerGlowHeight` |
| Inner edge | `InnerEdgeColor`, `InnerEdgeTopTransparency`, `InnerEdgeMidTransparency`, `InnerEdgeBottomTransparency` |
| Fresnel/Specular | `StrokeColor`, `StrokeThickness`, `FresnelStartTransparency`, `FresnelEndTransparency`, `FresnelMidTransparency`, `FresnelMidPoint`, `FresnelAngle` |
| Shadow | `ShadowColor`, `ShadowTransparency`, `ShadowSpread`, `ShadowOffsetX`, `ShadowOffsetY` |
| Refraction | `GlassColor`, `GlassTransparency`, `GlassReflectance` |
| Text | `PrimaryTextColor`, `SecondaryTextColor` |
| Accent | `AccentColor` |
| Toggle | `ToggleOnTrackColor`, `ToggleOffTrackColor`, `ToggleKnobColor` |
| Slider | `SliderTrackColor`, `SliderFillColor`, `SliderThumbColor`, `SliderTrackTransparency`, `SliderFillTransparency` |
| Button | `ButtonPressScale`, `ButtonBackgroundTransparency` |
| Checkbox | `CheckboxOnColor`, `CheckboxOffColor`, `CheckboxCheckColor` |
| Segmented | `SegmentedBackgroundTransparency`, `SegmentedSelectedTransparency`, `SegmentedSelectedColor` |
| Dropdown | `DropdownBackgroundTransparency`, `DropdownItemHoverColor`, `DropdownItemHoverTransparency` |
| Tab bar | `TabBarBackgroundTransparency`, `TabBarSelectedColor`, `TabBarIconColor`, `TabBarIconSelectedColor` |
| Search bar | `SearchBarBackgroundTransparency`, `SearchBarPlaceholderColor` |
| Text field | `TextFieldBackgroundTransparency`, `TextFieldBorderColor`, `TextFieldFocusBorderColor` |
| Progress bar | `ProgressBarTrackTransparency`, `ProgressBarFillColor`, `ProgressBarFillTransparency` |
| Dialog | `DialogOverlayTransparency`, `DialogBackgroundTransparency` |
| Notification | `NotificationStackGap`, `NotificationMaxVisible` |
| Window | `WindowBackgroundTransparency`, `WindowTitleColor` |
| Color picker | `ColorPickerCursorColor` |
| Keybind | `KeybindPillTransparency`, `KeybindListeningColor` |
| Shimmer | `ShimmerColor`, `ShimmerTransparency` |
| Badge | `BadgeBackgroundColor`, `BadgeBackgroundTransparency`, `BadgeTextColor` |
| Tooltip | `TooltipBackgroundTransparency` |
| Stepper | `StepperBackgroundTransparency` |
| Skeleton | `SkeletonBackgroundColor`, `SkeletonBackgroundTransparency` |
| Toast | `ToastBackgroundTransparency` |
| Bottom sheet | `BottomSheetBackgroundTransparency`, `BottomSheetHandleColor` |
| Blur proxy | `BlurTintColor`, `BlurTintTransparency` |
| Form | `FormErrorColor` |
| Focus manager | `FocusRingColor` |
| Parallax | `ParallaxIntensity` |

---

## Roblox Limitations

| Limitation | Impact | Workaround |
|-----------|--------|------------|
| **No native UI blur** | `BlurEffect` only works on 3D workspace | MangoBlurProxy (ViewportFrame approximation) |
| **CanvasGroup performance** | 10+ CanvasGroups = FPS drops | `LightweightMode = true` for small elements |
| **NumberSequence not tweeneable** | UIGradient.Transparency can't be animated | `transitionTheme()` destroy+rebuild pattern |
| **InputBegan child blocking** | Only topmost element receives input | TextButton hit areas at ZIndex=100 |
| **Transparent Frame input** | `BackgroundTransparency=1` Frames don't receive input | Always use TextButton hit areas |

---

## Cleanup Pattern

Every component returns a `Destroy()` method. Always call it when removing UI:

```lua
local btn = ui.bttn({...})
-- Later:
btn:Destroy()
```

This cancels all tweens, disconnects all event connections, and destroys all instances.

---

## Content Parenting

When adding content to a MangoGlassFrame, always parent to `GlassSurface`, **not** `Container`:

```lua
local panel = ui.glass({...})

-- Correct:
label.Parent = panel.GlassSurface

-- Wrong:
label.Parent = panel.Container  -- Will render behind glass effects
```

---

*MangoLiquidUI is developed by Mango Development.*
