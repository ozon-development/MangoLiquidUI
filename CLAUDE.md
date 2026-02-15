# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**MangoLiquidUI** is a Roblox UI library written in `--!strict` Luau that replicates Apple's Liquid Glass design language — directional rim lighting, multi-layer soft shadows, camera-locked refraction proxies, mouse-driven parallax, smooth hover animations, and a complete Apple-style UI control library (toggle, slider, button, billboard label, notification stack, segmented control, dropdown, tab bar, search bar, text field, checkbox, progress bar, dialog, action sheet). It supports Light, Dark, Mango, and Mint themes. Designed as a drop-in ModuleScript package for Roblox experiences under the Mango Development brand.

## Architecture

The library lives in `MangoLiquidUI/` and follows Roblox's ModuleScript convention with an `init.luau` entry point.

### Instance Hierarchy (MangoGlassFrame)

```
Container (Frame, transparent, NO ClipsDescendants, NO UICorner)
  +-- ShadowLayer1..N (Frames, ZIndex=0, quadratic transparency falloff)
  +-- GlassSurface (Frame, ZIndex=1, ClipsDescendants=true)
  |     +-- UICorner
  |     +-- UIGradient (Name="SurfaceGradient", Rotation=135, diagonal lighter top-left / darker bottom-right)
  |     +-- LensGroup (CanvasGroup, saturation tint via GroupColor3)
  |     |     +-- UICorner
  |     |     +-- TextureGroup (CanvasGroup)
  |     |           +-- UICorner
  |     |           +-- NoiseTile (ImageLabel, 3% opacity Perlin noise, scale-relative tiling)
  |     |           +-- InnerHighlight (Frame, ~18% visible all themes, 12% height)
  |     |                 +-- UICorner
  |     |                 +-- UIGradient (Name="HighlightGradient")
  |     +-- InnerEdgeFrame (Frame, full size, transparent, ZIndex=3)
  |           +-- UICorner
  |           +-- UIStroke (Name="InnerEdgeStroke", 1px, Border mode, white)
  |                 +-- UIGradient (Name="InnerEdgeGradient", Rotation=90, 3-keypoint)
  +-- SpecularFrame (Frame, ZIndex=2, OUTSIDE clip boundary)
        +-- UICorner
        +-- UIStroke (Name="SpecularStroke", 1.5px via theme / 1px hardcoded fallback, directional)
              +-- UIGradient (Name="SpecularGradient", Rotation=90, 3-keypoint fresnel)
```

Key architectural decisions:
- **Container wrapper**: Transparent Frame holds everything. Shadow extends beyond glass bounds, SpecularFrame renders UIStroke without clipping.
- **GlassSurface**: The clipping inner frame. User content (TextLabels, etc.) should be parented here.
- **SpecularFrame outside ClipsDescendants**: UIStroke renders fully on all edges.
- **Inner edge highlight**: UIStroke in `Border` mode inside `GlassSurface` (which has `ClipsDescendants=true`). The outer half of the border stroke is clipped, leaving only the inner half visible — simulating Apple's inner shadow effect. Uses a 3-keypoint gradient (top-bright to bottom-invisible).
- **N-layer graduated shadow**: Loop-generated (default 5) with quadratic falloff, spread=8px, Y-offset=2px. Reversed rendering order (outermost added first as bottom, innermost added last as top/darkest). Each layer has AnchorPoint(0.5, 0.5) for centered positioning. Supports both X and Y offset.
- **3-keypoint fresnel gradient**: Smooth top-bright to bottom-invisible fade matching Apple's specular rim behavior. 1.5px stroke, midpoint at 40% (top-lit Apple look).
- **Glass surface gradient**: GlassSurface has a UIGradient ("SurfaceGradient") with Rotation=135 (Apple's diagonal gradient, top-left to bottom-right), lighter (white) to slightly darker (230,230,235), mostly transparent (0.92→0.96). Creates Apple's subtle diagonal glass tonality.
- **Parallax system**: When `ParallaxEnabled = true`, mouse position is normalized to -1..1 and used to shift SpecularGradient, InnerEdgeGradient, and HighlightGradient offsets via RenderStepped, creating a subtle depth illusion.

### Instance Hierarchy (MangoToggle)

```
Container (Frame, 51x31 at scale=1)
  +-- TrackShadow1..2 (Frames, subtle 2-layer shadow)
  +-- TrackSurface (Frame, pill shape CornerRadius=999, color-animated)
  |     +-- UICorner
  |     +-- TrackSpecularFrame > UIStroke > UIGradient
  +-- KnobContainer (Frame, ZIndex=3, animated position)
  |     +-- KnobShadow (Frame, circular shadow)
  |     +-- KnobSurface (Frame, 27x27 circle, white)
  |           +-- UICorner (999)
  |           +-- KnobHighlight (Frame, inner glow) > UIGradient
  |           +-- KnobSpecularFrame > UIStroke > UIGradient
  +-- HitArea (TextButton, ZIndex=100, transparent, for reliable input)
```

### Instance Hierarchy (MangoSlider)

```
Container (Frame, default 200x36)
  +-- TrackShadow1..2 (updated transparencies: outer 0.86, inner 0.82)
  +-- TrackSurface (Frame, 6px tall glass pill, theme-driven transparency)
  |     +-- UICorner
  |     +-- FillFrame (Frame, colored fill, width=value%, UICorner=999, ClipsDescendants=true)
  |     |     +-- UICorner (CornerRadius=999, matches pill track)
  |     |     +-- FillHighlight (Frame, 50% height, white, 0.88 transp, UIGradient top→bottom, NO UICorner — parent clips)
  |     +-- TrackSpecularFrame > UIStroke > UIGradient (uses theme fresnel values)
  |     +-- TrackInnerEdgeFrame > UIStroke > UIGradient (inner edge recessed look)
  +-- TrackHitArea (TextButton, ZIndex=50, transparent, 16px tall, for tap-to-seek input)
  +-- ThumbContainer (Frame, ZIndex=3, X position = value)
        +-- ThumbHitArea (TextButton, ZIndex=100, transparent, for drag input)
        +-- ThumbShadow (30px circle, grows 30→38 on drag)
        +-- ThumbSurface (Frame, 28x28 white circle, grows 28→34 on drag)
              +-- UICorner
              +-- UIStroke (0.5px border, Color3(200,200,205), Transparency=0.4, subtle definition)
```

### Instance Hierarchy (MangoButton)

Composes `MangoGlassFrame` internally with `LightweightMode = true` — no CanvasGroups, no hierarchy duplication.

```
MangoGlassFrame.Container (pill shape, CornerRadius=999, ButtonBackgroundTransparency, LightweightMode)
  +-- [shadows, GlassSurface, InnerEdge, SpecularFrame only — no LensGroup/TextureGroup/NoiseTile/InnerHighlight]
  +-- UIScale (for press + hover animation: 0.97 press, 1.02 hover)
  +-- GlassSurface
        +-- ButtonText (TextLabel, GothamBold, ZIndex=10)
        +-- HitArea (TextButton, ZIndex=100, transparent, for reliable input + hover detection)
```

### Instance Hierarchy (MangoBillboardLabel)

Simplified glass hierarchy (no CanvasGroups for BillboardGui performance).

```
BillboardGui (attached to character Head or BasePart, MaxDistance=50)
  +-- Container (Frame, transparent)
        +-- ShadowLayer1..2
        +-- GlassSurface (Frame, pill, ClipsDescendants=true)
        |     +-- UICorner
        |     +-- InnerHighlight > UIGradient
        |     +-- InnerEdgeHighlight > UIStroke > UIGradient
        |     +-- LabelText (TextLabel, ZIndex=10)
        +-- SpecularFrame > UIStroke > UIGradient
```

### Instance Hierarchy (MangoNotification)

```
NotificationContainer (Frame, 380px wide, centered top, starts offscreen Y=-80)
  +-- MangoGlassFrame (CornerRadius=20, 4 shadow layers, ShadowOffsetY=4)
        +-- GlassSurface
              +-- UIPadding (14px all sides)
              +-- UIListLayout (Horizontal, 12px gap)
              +-- IconFrame (ImageLabel, 36x36, CornerRadius=8, optional)
              +-- TextContainer (Frame)
                    +-- UIListLayout (Vertical, 2px gap)
                    +-- TitleLabel (GothamBold, 15px, PrimaryTextColor)
                    +-- BodyLabel (Gotham, 13px, SecondaryTextColor, TextWrapped, optional)
```

### Instance Hierarchy (MangoSegmentedControl)

```
Container (Frame, pill, ClipsDescendants=true)
  +-- BackgroundGlass (Frame, SegmentedBackgroundTransparency, UICorner=999)
  +-- SelectedIndicator (Frame, slides horizontally, SegmentedSelectedColor, UICorner=999)
  |     +-- SpecularFrame > UIStroke > UIGradient (3-keypoint fresnel)
  +-- SegmentN (TextButton, equal width, ZIndex=10, GothamMedium 14px)
  +-- OuterSpecularFrame > UIStroke > UIGradient (outer rim)
```

### Instance Hierarchy (MangoDropdown)

```
Container
  +-- TriggerButton (MangoGlassFrame, LightweightMode, pill)
  |     +-- SelectedLabel + ChevronLabel + HitArea
  +-- DropdownPanel (Visible=false, ZIndex=50)
        +-- MangoGlassFrame (CornerRadius=12, 4 shadow layers)
              +-- ScrollingFrame (if >5 items)
              +-- UIListLayout Vertical
              +-- ItemN (Frame, 36px tall, HitArea + HoverHighlight)
```

### Instance Hierarchy (MangoTabBar)

```
Container (full-width, anchored bottom, 54px tall)
  +-- MangoGlassFrame (CornerRadius=0 top, ShadowOffsetY=-2, LightweightMode)
        +-- UIListLayout Horizontal equal spacing
        +-- TabN (Frame)
              +-- IconLabel (TextLabel, 24px) if icon provided
              +-- TabLabel (TextLabel, 10px, GothamMedium)
              +-- SelectedDot (Frame, 4x4 circle, visible when selected)
              +-- HitArea (TextButton, ZIndex=100)
```

### Instance Hierarchy (MangoSearchBar)

```
Container
  +-- MangoGlassFrame (pill, LightweightMode)
        +-- GlassSurface
              +-- UIPadding (horizontal)
              +-- SearchIcon (TextLabel "🔍")
              +-- InputBox (TextBox, GothamMedium 14px)
              +-- ClearButton (TextLabel "X", GothamBold 10, visible when text non-empty)
              +-- HitArea (for focus on click)
```

### Instance Hierarchy (MangoTextField)

```
Container (280x40 default, rounded rectangle NOT pill)
  +-- FieldShadow1 + FieldShadow2 (subtle shadows)
  +-- FieldFrame (CornerRadius=10)
        +-- UIStroke (1px border, animates color on focus)
        +-- InputBox (TextBox) + PlaceholderOverlay + ClearButton
```

### Instance Hierarchy (MangoCheckbox)

```
Container (horizontal UIListLayout, 8px gap)
  +-- CheckboxFrame (24×24, CornerRadius=6)
  |     +-- UIStroke (1.5px border, color animates)
  |     +-- CheckFill (UIScale 0→1 on toggle, 0.2s Back Out)
  |     +-- CheckmarkLabel ("✓", SourceSansBold, white, ZIndex=10)
  |     +-- HitArea (TextButton, ZIndex=100)
  +-- LabelText (optional, PrimaryTextColor, GothamMedium 14px)
```

### Instance Hierarchy (MangoProgressBar)

```
Container (200x20 default)
  +-- TrackShadow1 + TrackShadow2
  +-- TrackSurface (6px tall, pill, glass-like, ProgressBarTrackTransparency)
        +-- FillFrame (width=value%, ProgressBarFillColor, animated 0.3s Quad Out)
        |     +-- FillHighlight (50% height, white, UIGradient)
        +-- TrackSpecularFrame > UIStroke > UIGradient
        +-- TrackInnerEdge > UIStroke > UIGradient
```

### Instance Hierarchy (MangoDialog)

```
ScreenGui (DisplayOrder=150)
  +-- Overlay (full screen, black, DialogOverlayTransparency)
  +-- DialogContainer (centered, 270px wide)
        +-- MangoGlassFrame (CornerRadius=16, 4 shadow layers)
              +-- GlassSurface
                    +-- UIPadding
                    +-- TitleLabel (GothamBold 17px)
                    +-- MessageLabel (Gotham 14px, optional)
                    +-- Separator (1px line)
                    +-- ButtonN (44px tall, full-width, separated by 1px lines)
                          +-- styles: "default", "cancel" (bold), "destructive" (red)
```

### Instance Hierarchy (MangoActionSheet)

```
ScreenGui (DisplayOrder=150)
  +-- Overlay (full screen, black)
  +-- SheetContainer (anchored bottom, 8px margin)
        +-- ActionsGroup (MangoGlassFrame, CornerRadius=14)
        |     +-- Title + Message (optional) + Separator
        |     +-- ActionN (56px tall, full-width, separated by 1px lines)
        +-- CancelGroup (separate MangoGlassFrame, CornerRadius=14, 8px below)
              +-- CancelAction (GothamBold, 56px)
```

### Instance Hierarchy (MangoCarousel)

```
Container (Frame, transparent outer wrapper, pill shape)
  +-- DockGlass (MangoGlassFrame, 75% transparency, CornerRadius=pill, 3-layer shadows)
        +-- ClipFrame (Frame, ClipsDescendants=true, centered, 14px edge padding)
              +-- TrackFrame (Frame, holds all icons, animates Y position vertically)
                    +-- Icon_N (Frame, per-tab icon container, AnchorPoint=0.5,0)
                          +-- UIScale (paraboloid focus + hover animation target)
                          +-- IconShadow (Frame, accent-tinted, 78% transparent, 12px radius)
                          +-- IconBg (Frame, 20% accent fill, 10px squircle)
                          |     +-- UIGradient (IconBgGradient, Rotation=90, lighten top/darken bottom)
                          |     +-- IconHighlight (Frame, 35% height, white 70% transparent, inner glow)
                          |     |     +-- UIGradient (HighlightGradient, Rotation=90)
                          |     +-- SpecularFrame (Frame, ZIndex=3, fresnel rim)
                          |           +-- UICorner (10px)
                          |           +-- UIStroke (SpecularStroke, 1px, Border mode)
                          |                 +-- UIGradient (SpecularGradient, 3-keypoint fresnel)
                          +-- IconLabel (TextLabel, GothamBold 18px, emoji or text, white, text stroke)
                          +-- ActiveDot (Frame, 6x6 circle below icon, accent-colored, scales 0→1)
                          +-- HitArea (TextButton, ZIndex=100, transparent, for click/hover)
```

### Instance Hierarchy (MangoWindow)

```
ScreenGui (DisplayOrder=100, hidden parenting via MangoProtection)
  +-- WindowContainer (Frame, centered, animation target with UIScale)
        +-- GlassFrame (MangoGlassFrame, 12% transparency, CornerRadius=16, 4-layer shadows)
              +-- WindowContent (Frame, full size, ZIndex=10)
                    +-- UIPadding (14px all sides)
                    +-- TitleBar (Frame, 32px tall)
                    |     +-- TitleLabel (TextLabel, GothamBold 17px, left-aligned)
                    |     +-- CloseButton (Frame, 24x24 circle, 75% transparent)
                    |     |     +-- UICorner (999)
                    |     |     +-- UIStroke (0.5px gray, 50% transparent, Border mode)
                    |     |     +-- CloseLabel (TextLabel, "X", GothamBold 12px)
                    |     |     +-- CloseHitArea (TextButton, ZIndex=100, transparent, 8px expanded)
                    |     +-- DragHitArea (TextButton, excludes close button, for drag input)
                    +-- TabSelectorFrame (Frame, size=0 when carousel active, hidden)
                    +-- ContentArea (Frame, scrollable, ClipsDescendants=true, UIPadding 8px top/bottom)
                          +-- Tab_N (ScrollingFrame, per-tab content, AutomaticCanvasSize=Y)
                                +-- UIScale (scale animation target for tab switch)
                                +-- UIListLayout (Vertical, 10px gap)
                                +-- UIPadding (4px top/bottom)
                                +-- Row_Element (Frame per element)
  +-- CarouselDock (MangoCarousel, floating left of window, 12px gap, AnchorPoint=1,1)
  |     +-- Follows window on drag via updateDockPosition()
  |     +-- Show: slides up 30px (0.4s Back Out, 0.1s delay), Hide: immediate
  |     +-- Only created when tabs > 1, destroyed when tabs <= 1
  +-- ReopenerGlass (MangoGlassFrame, 70% transparency, pill shape, hidden initially)
        +-- ReopenerLabel (TextLabel, "ShowButton v", GothamMedium 13px)
        +-- ReopenerHitArea (TextButton, transparent, for reopen click)
  +-- NotificationStack (MangoNotificationStack, for in-window notifications)
```

### Module Roles

- **Types.luau** — Shared type definitions (`ThemePreset`, config tables, return types) consumed by all other modules. Edit this first when adding new configurable properties. Includes all component types: glass frame, toggle, slider, button, billboard label, notification, notification stack, segmented control, dropdown, tab bar, search bar, text field, checkbox, progress bar, dialog, action sheet, intro.
- **Themes.luau** — Light, Dark, Mango, and Mint `ThemePreset` tables with Apple-spec values, plus the canonical `resolve()` nil-safe helper function. All other modules import `resolve` from here. Mango is a warm amber/orange-tinted glass theme. Mint is a fresh mint/teal glass theme with cool green-tinted glass (BackgroundColor3 RGB(235,252,245), accent RGB(0,199,140), PrimaryText RGB(15,55,45), ShadowColor RGB(20,80,60), GlassColor RGB(230,248,240)). Tuned values: BackgroundTransparency 0.88/0.85/0.87/0.86, GlassTransparency 0.88/0.87/0.875/0.88 (per-panel refraction — visible distortion, thick glass), GlassReflectance 0.08/0.09/0.085/0.08, Apple-spec shadows (spread 20/22/20/20, offsetY 5, transparency 0.80/0.75/0.80/0.82 — based on Apple's `box-shadow: 0 8px 24px`), softened specular (FresnelStart 0.35/0.30/0.32/0.34, FresnelMid 0.65/0.58/0.62/0.64, StrokeThickness 1.5, MidPoint 0.40 — based on Apple's `border: 1px solid rgba(255,255,255,0.15)`), thin inner glow strip (transparency 0.82 all themes, height 0.12 — Apple's 1px inset highlight at 80%), boosted lens tint (LensGroupTransparency 0.62/0.64/0.60/0.62), NotificationStackGap=14.
- **MangoGlassFrame.luau** — Material compositing. Builds the Container + Shadow + GlassSurface + Lens + Texture + InnerEdge + Specular hierarchy. GlassSurface includes a SurfaceGradient (Rotation=135, Apple's diagonal gradient) for subtle glass tonality. Default 5 shadow layers. Supports `LightweightMode` which skips CanvasGroups. Supports `ParallaxEnabled` for mouse-driven specular/edge highlight offset shifting via RenderStepped. Exposes `SetLightDirection()` and `SetParallaxEnabled()`. Calls `MangoProtection.registerInstance(container)` after parenting to ensure all glass frames are automatically protected.
- **RefractionProxy.luau** — Optical simulation. Spawns a Glass Part parented to `Workspace.CurrentCamera`. Uses `ScreenPointToRay` (not ViewportPointToRay) to correctly map screen coordinates when `IgnoreGuiInset=true`. Theme-aware glass color/transparency/reflectance. Configurable `GlassThickness` (default 0.05 studs for visible refraction). Glass Part is inset by 3% width / 5% height so rectangular edges hide behind rounded UI corners. Supports `ViewportMode` for full-screen single Glass Part. DEPTH_STEP=0.003 for Z-fighting mitigation. Exports `resetDepthCounter()` for clean rebuilds. Default GlassTransparency=0.88, GlassReflectance=0.08 (visible distortion, tempered glass look).
- **LiquidFusion.luau** — Animation system. Smooth tween wrapper (`Enum.EasingStyle.Back`, `Out` direction) for hover animations (1.025x scale, 0.25s) and specular gradient offset shifts (0.04 offset). Supports `UseUIScale` mode and mobile/touch input.
- **MangoToggle.luau** — Apple-style toggle switch. Pill-shaped track with spring-animated knob (0.25s Back Out), color-transitioning track (0.2s Quad). Theme-aware.
- **MangoSlider.luau** — Apple-style slider. 6px glass-material track with colored fill and 28px clean white circular thumb that grows to 34px on drag. Thumb has subtle 0.5px gray border (UIStroke) for definition against any background. FillFrame has UICorner=999 and ClipsDescendants=true to match the pill track shape and prevent white corner artifacts. FillHighlight has no UICorner (parent fillFrame clips). Single outer shadow. Global drag tracking via UserInputService.InputChanged.
- **MangoButton.luau** — Apple-style glass pill button. Composes `MangoGlassFrame` with `LightweightMode = true`. Hover via UIScale (1.02, 0.2s Quad Out) with glass opacity thickening (-0.04), press via UIScale (0.97) with touch-point specular shift (Offset 0.06). Directional specular.
- **MangoBillboardLabel.luau** — Overhead glass name tag using `BillboardGui`. Simplified hierarchy (no CanvasGroups). 15% more opaque for readability. Auto-sizes from text.
- **MangoNotification.luau** — Glass notification banner. Slides in from top (0.4s Back Out). Auto-dismisses after configurable duration. Supports `SetPosition()` for stacking and `GetHeight()` for layout calculation.
- **MangoNotificationStack.luau** — Wraps multiple `MangoNotification` instances with stacking layout. `Push(config)` creates + positions below existing. Max 3 visible (configurable). Auto-dismisses oldest when exceeding max. Reflows remaining on dismiss (0.25s Back Out).
- **MangoSegmentedControl.luau** — Apple-style segmented control. Pill container with sliding selected indicator (0.25s Back Out). Equal-width segments, theme-driven colors.
- **MangoDropdown.luau** — Apple-style dropdown menu. Glass trigger button with chevron (`"v"` GothamMedium 10 — ASCII for Gotham compatibility). Item checkmarks use SourceSansBold for reliable Unicode rendering. Panel opens from 0.92 scale (0.2s Back Out), closes to 0.95 scale (0.1s Quad Out). Click outside closes. Max 5 visible items (scrollable).
- **MangoTabBar.luau** — Bottom tab bar (54px tall). Glass background with dot indicator that slides between tabs. Icon + label color transitions on selection (0.15s Quad Out).
- **MangoSearchBar.luau** — Pill glass search bar. Search icon + TextBox + clear button (`"X"` GothamBold 10 — ASCII for Gotham compatibility). Focus animation: glass becomes more opaque (-0.05 transparency).
- **MangoTextField.luau** — Rounded rectangle text input (CornerRadius=10). UIStroke border that animates color on focus (0.15s Quad Out). Clear button uses `"X"` GothamBold 10 (ASCII for Gotham compatibility). Not a pill shape.
- **MangoCheckbox.luau** — Animated checkbox with UIScale fill (0.5→1.0, 0.2s Back Out). Checkmark label uses `Enum.Font.SourceSansBold` (not GothamBold) for reliable ✓ Unicode rendering across all Roblox platforms. Optional label. UIStroke border color animates.
- **MangoProgressBar.luau** — Glass capsule progress bar (6px tall). Animated fill on SetValue (0.3s Quad Out). Matches slider track visual style.
- **MangoDialog.luau** — Centered modal dialog. Overlay fades in (0.2s), dialog scales 0.8→1.0 (0.25s Back Out). Apple alert button styles: default, cancel (bold), destructive (red). Overlay tap dismisses.
- **MangoActionSheet.luau** — Bottom action sheet. Slides up from bottom (0.3s Back Out). Separate cancel button in own glass group (8px below actions). Overlay tap dismisses.
- **MangoEnvironmentLight.luau** — Dynamic environment lighting. Projects sun/moon direction into camera-local space for gradient rotation. Samples ambient color for glass tint (default influence 0.45). Also tints SpecularStroke.Color at 35% intensity. Angle caching (skips updates < 0.1 degree change).
- **MangoIntro.luau** — Auto-play intro animation module. Extracted from demo's `playIntroAnimation()`. Uses `MangoGlassFrame.new()`, 4-layer 3D glass text with staggered scale bounce, spotlight rotation, shimmer sweep, 2.5s total timeline. Acquires PlayerGui dynamically. `isDestroyed` guards on all `task.delay` callbacks. Sound ref stored for cleanup on `skip()`. Exports `module.play(config?)` and `module.skip()`.
- **MangoProtection.luau** — Anti-detection security module. Provides 5 layers of defense: (1) Hidden parenting via `gethui()` → CoreGui → PlayerGui fallback chain, (2) Metamethod hooking (`__namecall`/`__index`) that filters protected instances from `GetChildren()`, `GetDescendants()`, `FindFirstChild()` calls by game scripts while allowing executor code full access via `checkcaller()`, (3) Instance identity obfuscation with GUID-based randomized names for all containers, ScreenGuis, RenderStep bindings, and refraction Parts, (4) Connection protection via `newcclosure()` wrapping, (5) Property spoofing returning `nil` parent for protected instances to non-executor callers. All executor-specific globals (`gethui`, `cloneref`, `hookmetamethod`, `newcclosure`, `checkcaller`, `getnamecallmethod`, `syn.protect_gui`) accessed via `pcall` for `--!strict` safety. Uses weak-keyed `protectedInstances` registry with automatic `DescendantAdded` listener. `registerInstance()` has a nil guard for safety. Gracefully falls back to standard Roblox Studio behavior when no executor features are available. Provides centralized `createScreenGui()` helper that replaces duplicated ScreenGui creation across 8+ modules. All protection is automatic and transparent — no API changes to existing modules.
- **MangoCarousel.luau** — Apple Watch-style vertical carousel dock. Paraboloid focus scaling (0.5x→1.0x) with accent-colored icons, animated active dots, mouse wheel / touch swipe navigation. ClipFrame uses 14px edge padding to prevent shadow and dot clipping. Hover (1.04x Back Out), press (0.92x Quad Out), scroll (variable duration based on wrap distance). Composes MangoGlassFrame for dock background.
- **MangoWindow.luau** — Feature-rich configuration UI window. Multi-tab support via floating MangoCarousel dock (replaces in-window MangoSegmentedControl), 12+ element types (sliders, toggles, dropdowns, color pickers, keybinds, etc.), automatic config saving/loading via MangoSaveManager, flag dependency visibility system. Carousel dock is a sibling of windowContainer at the ScreenGui level, positioned to the left of the window with a 12px gap, follows window on drag, shows/hides with window animations. ContentArea has UIPadding (8px top/bottom) inside ClipsDescendants=true for shadow breathing room. Show/hide animations (UIScale 0.95→1, Back Out). Draggable title bar, close button, reopener pill. Composes MangoGlassFrame, MangoCarousel, MangoNotificationStack, MangoDialog.
- **init.luau** — Re-exports all modules, Themes, type aliases, the `transitionTheme()` utility function, short-name constructor aliases (`bttn`, `sldr`, `tgl`, etc.), theme shortcuts (`Light`, `Dark`, `Mango`, `Mint`), `gui()` ScreenGui helper, `intro` module shortcut, and auto-plays `MangoIntro.play()` via `task.spawn` on require. Protection API: `protect()`, `isProtected()`, `protectionLevel()`. `gui()` helper uses `MangoProtection.createScreenGui()` for automatic hidden parenting.
- **MangoLiquidUI_Demo.client.luau** — Self-contained LocalScript demo. Single centered glass panel (680x500, resizable, draggable) with 4-tab content (Home, Showcase, Effects, Settings) navigated by Apple Watch-style MangoCarousel dock. Intro animation with 4-layer 3D glass text. All 4 themes, environment lighting, refraction, parallax. Uses LightweightMode for everything except the main panel (2 CanvasGroups total). Single RefractionProxy. Buttons use single custom drop shadows instead of multi-layer system.

### Key Design Patterns

#### Core Patterns (Library-Wide)
- **Constructor pattern**: Each module exposes `module.new(config)` returning a typed table with a `Destroy` cleanup method.
- **Nil-safe theme resolution**: `resolve(configVal, themeVal, default)` instead of `or` (which treats `0`/`false` as falsy). Defined in `Themes.luau`, imported everywhere.
- **Theme cascade**: `config.Field` → `theme.Field` → hardcoded default. Theme optional, falls back to Light.
- **Content parenting**: User content goes into `GlassSurface`, not `Container`.
- **Composition over duplication**: MangoButton, MangoNotification, MangoDropdown, MangoTabBar, MangoSearchBar, MangoDialog, MangoActionSheet all compose MangoGlassFrame internally.
- **LightweightMode**: Skips CanvasGroup creation for small elements (MangoButton, MangoTabBar, MangoSearchBar, notifications).
- **Concentric corner radius**: Child corner radius = parent radius minus padding (Apple's `containerConcentric` principle).
- **Sensible defaults**: All components work with minimal config — `Position` defaults to `(0,0,0,0)`, `Size` to reasonable dimensions, `Text`/`Title` to component name, array fields (`Segments`, `Items`, `Tabs`, `Actions`) to single-item defaults. Every component can be created with just `{ Parent = frame }`.

#### Animation & Input Patterns
- **Tween conflict prevention**: All animated components cancel in-flight tweens before starting new ones. MangoWindow tracks tab switch tweens, close button hover tweens, and `task.delay` threads for cancellation on destroy.
- **Apple-like easing**: Most animations use `Back Out` for overshoot. Buttons/tabs use `Quint Out` (matches Apple's SwiftUI spring). Carousel keeps `Back Out` for snap delight.
- **TextButton hit area pattern**: Transparent `TextButton` (ZIndex=100) for reliable input. CRITICAL: transparent Frames don't receive `InputBegan`/`InputEnded` without `Active=true` — always use TextButton hit areas.
- **Named gradient search**: LiquidFusion finds "SpecularStroke" by name recursively, then "SpecularGradient" child by name — avoids animating wrong gradients.
- **RenderStep cleanup**: Named `BindToRenderStep`/`UnbindFromRenderStep` with unique binding names to prevent leaks.
- **Button hover/press**: UIScale 1.02 on hover (Quint Out) with opacity thickening (-0.04), UIScale 0.97 on press with specular shift. Softened 3-keypoint fresnel (+0.05 offset).

#### Glass & Visual Patterns
- **Inner edge via ClipsDescendants**: UIStroke in `Border` mode inside a `ClipsDescendants=true` frame clips the outer half.
- **Slider edge-snap**: Snaps fraction to exact 0 or 1 within 0.005 threshold, preventing sub-pixel artifacts.
- **FillFrame pill shape**: UICorner=999 + ClipsDescendants=true on FillFrame prevents white corner artifacts. FillHighlight omits UICorner — parent clips.
- **Size-dependent glass thickness**: Larger elements use deeper shadows, smaller elements use shallower. Buttons use single custom drop shadows.
- **Z-fighting mitigation**: RefractionProxy depth counter offsets each proxy by 0.003 studs. `resetDepthCounter()` on theme cycling.
- **Parallax**: MangoGlassFrame shifts SpecularGradient, InnerEdgeGradient, HighlightGradient offsets based on normalized mouse position × ParallaxIntensity.
- **Environment lighting**: MangoEnvironmentLight tints GlassSurface (45%), SpecularStroke (35%), shadows (15%). Angle caching skips < 0.1° changes.
- **Carousel clip padding**: ClipFrame uses 14px edge padding to accommodate icon shadow overflow (4px beyond icon bounds) and active dots (6px + 3px offset below icon). Demo carouselContainer reduced by 12px with centered anchoring for matching breathing room.

#### Lifecycle & Safety Patterns
- **Theme toggle via destroy+rebuild**: NumberSequence can't be tweened — use `transitionTheme()` for smooth fade.
- **Dismiss ordering safety**: Set `isDestroyed = true` BEFORE calling `OnDismissed()` callbacks (MangoToast, MangoNotification) to prevent re-entrancy.
- **Carousel scroll lifecycle**: `cancelAllTweens()` BEFORE `scrollGen` increment. `Completed` callbacks guarded by `isDestroyed`.
- **Tab switch visibility ordering**: Set UIScale to 0.98 BEFORE `Visible=true` to prevent 1-frame pop.
- **Window contentArea padding**: UIPadding (8px) inside `ClipsDescendants=true` contentArea for shadow breathing room.
- **Self-cancelling task.delay**: Notification dismiss callbacks set `dismissThread = nil` before calling dismiss to avoid cancelling the running thread.
- **Notification hitArea parenting**: Parent to outer container, NOT GlassSurface (UIListLayout repositions children).
- **Dropdown click-blocker**: Full-screen transparent TextButton (ZIndex=49) blocks clicks outside. Panel reparented to ScreenGui on open, restored on close with `isDestroyed` guard.

#### Refraction Patterns
- **ScreenPointToRay (not ViewportPointToRay)**: `IgnoreGuiInset=true` makes AbsolutePosition return screen coordinates (0,0 = top of full screen). CRITICAL distinction.
- **Glass Part inset**: 3% width / 5% height inset so rectangular edges hide behind rounded UI corners.

#### Protection Patterns
- **Anti-detection**: All instance names randomized via `MangoProtection.randomName()`, all ScreenGuis via `createScreenGui()`, all RenderStep bindings via `randomBindingName()`. Falls back to standard behavior in Studio.
- **ScreenGui centralization**: All modules call `MangoProtection.createScreenGui({DisplayOrder = N})` instead of duplicating creation logic.
- **Auto-registration**: MangoGlassFrame calls `registerInstance(container)` after parenting for seamless protection coverage.

#### Font Compatibility
- **ASCII for Gotham**: Close/dismiss buttons use `"X"` (GothamBold), chevrons use `"v"` (GothamMedium). Gotham doesn't render ✕, ▼, ▾ reliably.
- **SourceSansBold for Unicode**: Checkmarks (✓) use `Enum.Font.SourceSansBold` which has full Unicode support (MangoCheckbox, MangoDropdown item checks).

### Return Type Fields

`MangoGlassFrame.new()` returns:
- `Container` / `Frame` (alias) — The transparent outer wrapper.
- `GlassSurface` — The clipping inner frame. Parent your content here.
- `ShadowLayers: {Frame}` — Array of all shadow layer Frames.
- `LensGroup?`, `TextureGroup?`, `NoiseLabel?`, `InnerHighlight?` — Internal compositing layers (nil in LightweightMode).
- `InnerEdgeFrame`, `InnerEdgeStroke`, `InnerEdgeGradient` — Inner edge highlight elements.
- `SpecularFrame`, `SpecularStroke`, `SpecularGradient` — Fresnel rim elements.
- `SetLightDirection(angle)` — Rotates SpecularGradient, InnerEdgeGradient, and HighlightGradient.
- `SetParallaxEnabled(enabled)` — Enables/disables mouse-driven parallax at runtime.
- `Destroy()` — Destroys Container, stops parallax, and all descendants.

`MangoToggle.new()` returns:
- `Container`, `SetState(state)`, `GetState()`, `Destroy()`.

`MangoSlider.new()` returns:
- `Container`, `SetValue(value)`, `GetValue()`, `Destroy()`.

`MangoButton.new()` returns:
- `Container`, `GlassSurface`, `TextLabel`, `SetText(text)`, `Destroy()`.

`MangoBillboardLabel.new()` returns:
- `BillboardGui`, `GlassSurface`, `TextLabel`, `SetText(text)`, `Destroy()`.

`MangoNotification.new()` returns:
- `Container`, `Show()`, `Dismiss()`, `SetPosition(position)`, `GetHeight()`, `Destroy()`.

`MangoNotificationStack.new()` returns:
- `Push(config)` — Creates + positions notification, returns it.
- `DismissAll()`, `GetCount()`, `Destroy()`.

`MangoSegmentedControl.new()` returns:
- `Container`, `SetIndex(index)`, `GetIndex()`, `Destroy()`.

`MangoDropdown.new()` returns:
- `Container`, `SetSelectedIndex(index)`, `GetSelectedIndex()`, `SetItems(items)`, `Open()`, `Close()`, `Destroy()`.

`MangoTabBar.new()` returns:
- `Container`, `SetIndex(index)`, `GetIndex()`, `Destroy()`.

`MangoSearchBar.new()` returns:
- `Container`, `GetText()`, `SetText(text)`, `Focus()`, `Destroy()`.

`MangoTextField.new()` returns:
- `Container`, `GetText()`, `SetText(text)`, `Focus()`, `Destroy()`.

`MangoCheckbox.new()` returns:
- `Container`, `SetState(state)`, `GetState()`, `Destroy()`.

`MangoProgressBar.new()` returns:
- `Container`, `SetValue(value)`, `GetValue()`, `Destroy()`.

`MangoDialog.new()` returns:
- `Show()`, `Dismiss()`, `Destroy()`.

`MangoActionSheet.new()` returns:
- `Show()`, `Dismiss()`, `Destroy()`.

`MangoEnvironmentLight.new()` returns:
- `Enable()`, `Disable()`, `IsEnabled()`, `GetSunAngle()`, `GetEnvironmentTint()`, `RegisterGlassFrame(frame)`, `UnregisterGlassFrame(frame)`, `Destroy()`.

`MangoProtection` module exports:
- `configure(config)` — Enable/disable protection globally.
- `getParent()` — Returns safest parent (gethui → CoreGui → PlayerGui).
- `protectGui(gui)` — Applies `syn.protect_gui()` + registers in protected set.
- `createScreenGui(config)` — Central ScreenGui creation with hidden parenting, name randomization, protection registration.
- `registerInstance(instance)` — Adds instance + all descendants to protected registry. Nil-safe (no-op if instance is nil).
- `randomName(prefix?)` — Returns GUID-based random name (or prefix when protection disabled).
- `randomBindingName(prefix?)` — Returns non-identifiable RenderStep binding name.
- `safeService(name)` — Returns `cloneref()`'d service reference when available.
- `wrapConnection(fn)` — Wraps callback in `newcclosure()` when available.
- `isProtected()` — Returns whether protection is active.
- `getProtectionLevel()` — Returns `"gethui"` | `"synprotect"` | `"coregui"` | `"none"`.
- `installHooks()` — Installs metamethod hooks (called automatically, idempotent).

`MangoCarousel.new()` returns:
- `Container` — Transparent outer wrapper Frame.
- `SetIndex(index)` — Scroll to tab by index.
- `GetIndex()` — Return current selected tab index.
- `Destroy()` — Cancel all tweens, disconnect all listeners, destroy container and dock glass.

`MangoWindow.new()` returns:
- `Flags: {[string]: any}` — Current flag values dictionary.
- `Tab(name, icon?)` — Create new tab, returns `MangoWindowTab` builder object.
- `Notify(config)` — Push notification to in-window stack.
- `Dialog(config)` — Show modal dialog.
- `Show()`, `Hide()`, `IsVisible()` — Window visibility control with animation.
- `SaveConfig()`, `LoadConfig()` — Manual config persistence.
- `Destroy()` — Cancel all tweens, disconnect listeners, destroy ScreenGui.

`MangoWindowTab` methods (returned by `Tab()`):
- `Button(cfg)`, `Toggle(cfg)`, `Slider(cfg)`, `Dropdown(cfg)`, `Input(cfg)`, `Checkbox(cfg)`, `Stepper(cfg)`, `Progress(cfg)`, `ColorPicker(cfg)`, `Keybind(cfg)` — Interactive elements, each returns `MangoWindowElement`.
- `Label(text)`, `Paragraph(cfg)`, `Section(title)`, `Separator()` — Layout/text elements, each returns `MangoWindowElement`.

`MangoWindowElement` interface:
- `CurrentValue: any` — Live flag value.
- `Set(value)` — Update element and flag.
- `Visible(visible)` — Show/hide row.
- `Lock(reason?)`, `Unlock()` — Overlay lock with optional reason label.
- `Destroy()` — Destroy element and row.

### Config Fields

`MangoGlassConfig` includes:
- `Size?` (default 200×100), `Position?` (default 0,0), `AnchorPoint?`, `CornerRadius?`, `BackgroundColor3?`, `BackgroundTransparency?`
- `NoiseOpacity?`, `NoiseImageId?`
- `FresnelStartTransparency?`, `FresnelEndTransparency?`, `FresnelMidTransparency?`, `FresnelMidPoint?`, `FresnelAngle?`
- `StrokeThickness?`, `StrokeColor?`
- `InnerGlowTransparency?`, `InnerGlowColor?`, `InnerGlowHeight?`
- `InnerEdgeColor?`, `InnerEdgeTopTransparency?`, `InnerEdgeMidTransparency?`, `InnerEdgeBottomTransparency?`
- `LensGroupColor3?`, `LensGroupTransparency?`
- `ShadowColor?`, `ShadowTransparency?`, `ShadowSpread?`, `ShadowOffsetX?`, `ShadowOffsetY?`, `ShadowEnabled?`, `ShadowLayerCount?`
- `LightweightMode?` — Skip CanvasGroups for small elements.
- `ParallaxEnabled?` — Enable mouse-driven parallax (default false).
- `ParallaxIntensity?` — Parallax strength (default 0.15).
- `Theme?`, `Parent?`

`RefractionProxyConfig`: `TargetGui, GlassTransparency?, GlassMaterial?, GlassColor?, GlassReflectance?, GlassThickness? (default 0.05), OffsetDepth?, Enabled?, ViewportMode? (default false), Theme?`

`LiquidFusionConfig`: `Target, BulgeScale?, BulgeDuration?, RestoreDuration?, SpecularShiftOffset? (default 0.04), UseUIScale?`

`MangoToggleConfig`: `Position? (default 0,0), AnchorPoint?, Scale?, Theme?, InitialState?, OnToggled?, Parent?`

`MangoSliderConfig`: `Position? (default 0,0), Size?, AnchorPoint?, Theme?, InitialValue?, Min?, Max?, Step?, OnChanged?, Parent?`

`MangoButtonConfig`: `Position? (default 0,0), Size?, AnchorPoint?, Text? (default "Button"), TextSize?, BackgroundTransparency?, Theme?, OnActivated?, Parent?`

`MangoBillboardLabelConfig`: `TargetPart?, TargetCharacter?, Text? (default "Label"), TextSize?, Theme?, MaxDistance?, StudsOffset?, AlwaysOnTop?, Parent?`

`MangoNotificationConfig`: `Title? (default "Notification"), Body?, Icon?, Duration? (default 5, 0=no auto-dismiss), Theme?, OnDismissed?, Parent?`

`MangoNotificationStackConfig`: `MaxVisible? (default 3), StackGap? (default 8, theme override 14), Theme?, Parent?`

`MangoSegmentedControlConfig`: `Position? (default 0,0), AnchorPoint?, Segments? (default {"Tab 1", "Tab 2"}), InitialIndex?, SegmentWidth? (default 90), Height? (default 36), Theme?, OnChanged?, Parent?`

`MangoDropdownConfig`: `Position? (default 0,0), Size?, AnchorPoint?, Items? (default {"Option 1"}), InitialIndex?, Theme?, OnChanged?, Parent?`

`MangoTabBarConfig`: `Tabs? (default {{Label = "Tab"}}), InitialIndex?, Theme?, OnChanged?, Parent?`

`MangoSearchBarConfig`: `Position? (default 0,0), Size?, AnchorPoint?, Placeholder?, Theme?, OnTextChanged?, OnSubmit?, Parent?`

`MangoTextFieldConfig`: `Position? (default 0,0), Size?, AnchorPoint?, Placeholder?, InitialText?, Theme?, OnTextChanged?, OnFocusLost?, Parent?`

`MangoCheckboxConfig`: `Position? (default 0,0), AnchorPoint?, Label?, InitialState?, Theme?, OnToggled?, Parent?`

`MangoProgressBarConfig`: `Position? (default 0,0), Size?, AnchorPoint?, InitialValue?, Theme?, Parent?`

`MangoDialogConfig`: `Title? (default "Dialog"), Message?, Buttons: {MangoDialogButtonConfig}?, Theme?, OnDismissed?, Parent?`
`MangoDialogButtonConfig`: `Text, Style? ("default"|"cancel"|"destructive"), OnActivated?`

`MangoActionSheetConfig`: `Title?, Message?, Actions? (default {{Text = "OK"}}), CancelText? (default "Cancel"), Theme?, OnDismissed?, Parent?`
`MangoActionSheetActionConfig`: `Text, Style? ("default"|"destructive"), OnActivated?`

`MangoEnvironmentLightConfig`: `UpdateAngleEveryFrame? (default true), TintUpdateInterval? (default 0.5s), TintInfluence? (0-1, default 0.45), Enabled? (default true)`

`MangoProtectionConfig`: `Enabled? (default true)`

`MangoCarouselConfig`: `Tabs: {MangoCarouselTabConfig}, Position? (default 0,0), Size?, AnchorPoint?, InitialIndex?, IconSize?, Orientation?, Theme?, OnChanged?, Parent?`
`MangoCarouselTabConfig`: `Icon: string, Label: string?, AccentColor: Color3?`

`MangoWindowConfig`: `Name: string, Theme?, Size?, Position?, ToggleKey?, ShowButton?, ConfigurationSaving: MangoWindowConfigSaving?, LoadingTitle?, LoadingSubtitle?, LoadingEnabled?`
`MangoWindowConfigSaving`: `Enabled: boolean, FolderName?, FileName?`

### Utilities

- `MangoLiquidUI.transitionTheme(glassFrames, fadeDuration, rebuildCallback)` — Smoothly fades out existing glass frames, calls the rebuild callback to create new ones with the new theme, then fades them in. Works around the NumberSequence tween limitation.
- `MangoLiquidUI.gui(name?)` — Creates a properly configured `ScreenGui` via `MangoProtection.createScreenGui()`. Parented to safest container (gethui → CoreGui → PlayerGui). Name only applied when protection is disabled. Returns the ScreenGui.
- `MangoLiquidUI.protect(config)` — Configure protection globally. `config.Enabled = false` disables all protection for debugging in Studio.
- `MangoLiquidUI.isProtected()` — Returns `true` if protection is active (executor features available and enabled).
- `MangoLiquidUI.protectionLevel()` — Returns the current protection level: `"gethui"`, `"synprotect"`, `"coregui"`, or `"none"`.

### Short API

The library exposes ultra-short constructor aliases alongside the full module names. Both styles return identical types. The intro animation auto-plays on `require()`.

```lua
-- Short API usage
local ui = require(game.ReplicatedStorage.MangoLiquidUI)  -- intro auto-plays
local g = ui.gui("MyUI")  -- ScreenGui helper
ui.bttn({ Text = "Go", Theme = ui.Dark, Parent = g })
ui.intro.skip()  -- skip intro if needed
```

| Short | Full Module | Constructor |
|-------|------------|-------------|
| `ui.bttn(config)` | `ui.MangoButton.new(config)` | Button |
| `ui.sldr(config)` | `ui.MangoSlider.new(config)` | Slider |
| `ui.tgl(config)` | `ui.MangoToggle.new(config)` | Toggle |
| `ui.chk(config)` | `ui.MangoCheckbox.new(config)` | Checkbox |
| `ui.dlg(config)` | `ui.MangoDialog.new(config)` | Dialog |
| `ui.act(config)` | `ui.MangoActionSheet.new(config)` | Action Sheet |
| `ui.drp(config)` | `ui.MangoDropdown.new(config)` | Dropdown |
| `ui.tab(config)` | `ui.MangoTabBar.new(config)` | Tab Bar |
| `ui.srch(config)` | `ui.MangoSearchBar.new(config)` | Search Bar |
| `ui.txt(config)` | `ui.MangoTextField.new(config)` | Text Field |
| `ui.prog(config)` | `ui.MangoProgressBar.new(config)` | Progress Bar |
| `ui.glass(config)` | `ui.MangoGlassFrame.new(config)` | Glass Frame |
| `ui.notif(config)` | `ui.MangoNotification.new(config)` | Notification |
| `ui.nstack(config)` | `ui.MangoNotificationStack.new(config)` | Notification Stack |
| `ui.seg(config)` | `ui.MangoSegmentedControl.new(config)` | Segmented Control |
| `ui.bbl(config)` | `ui.MangoBillboardLabel.new(config)` | Billboard Label |
| `ui.env(config)` | `ui.MangoEnvironmentLight.new(config)` | Environment Light |
| `ui.refr(config)` | `ui.RefractionProxy.new(config)` | Refraction Proxy |
| `ui.fuse(config)` | `ui.LiquidFusion.new(config)` | Liquid Fusion |
| `ui.carousel(config)` / `ui.csel(config)` | `ui.MangoCarousel.new(config)` | Carousel |
| `ui.window(config)` | `ui.MangoWindow.new(config)` | Window |
| `ui.protect(config)` | `ui.MangoProtection.configure(config)` | Configure protection |
| `ui.isProtected()` | `ui.MangoProtection.isProtected()` | Check protection status |
| `ui.protectionLevel()` | `ui.MangoProtection.getProtectionLevel()` | Get protection level |

**Theme shortcuts:** `ui.Light`, `ui.Dark`, `ui.Mango`, `ui.Mint` (equivalent to `ui.Themes.Light`, etc.)

**Intro control:** `ui.intro.play(config?)`, `ui.intro.skip()` — auto-plays on require, can be skipped immediately.

`MangoIntroConfig`: `Theme? (default Mango), OnComplete?, Parent?`

## Language & Conventions

- All files use `--!strict` Luau type mode.
- Services are always accessed via `game:GetService()`.
- Config defaults use the `resolve(configVal, themeVal, default)` nil-check pattern, NOT the `or` pattern.
- `resolve()` is defined canonically in `Themes.luau` and imported by all other modules — never redefined locally.
- Types are imported from the shared `Types.luau` module, not redefined locally.
- UIGradients are explicitly named ("HighlightGradient", "SpecularGradient", "InnerEdgeGradient") to enable reliable named search.

## Roblox Deployment

- Place the `MangoLiquidUI` folder in `ReplicatedStorage` as a Folder of ModuleScripts.
- Require via `require(game.ReplicatedStorage.MangoLiquidUI)` from any LocalScript.
- The demo file (`MangoLiquidUI_Demo.client.luau`) is self-contained — paste into a LocalScript in `StarterPlayerScripts` with no dependencies.

### Loadstring Bundle

For distribution via GitHub `loadstring`, use the pre-built bundle:

```lua
local ui = loadstring(game:HttpGet("https://raw.githubusercontent.com/<user>/<repo>/main/MangoLiquidUI/dist/MangoLiquidUI.lua"))()
-- Short API works in loadstring bundle too:
local g = ui.gui("MyUI")
ui.bttn({ Text = "Click", Theme = ui.Dark, Parent = g })
-- Full names still work:
local button = ui.MangoButton.new({ ... })
```

### Build System

The dist bundle is built by `./MangoLiquidUI/build.sh`. Run it after modifying any library source file:

```bash
cd MangoLiquidUI && bash build.sh
```

Output: `dist/MangoLiquidUI.lua` (~14,600+ lines).

**What the build does:**
1. Reads all `.luau` source files in dependency-safe order (38 modules)
2. Wraps each module in a `_modules["Name"] = function() ... end` closure
3. Replaces `require(script.Parent.X)` / `require(script.X)` with internal `_require("X")` lookups
4. Strips `--!strict` annotations
5. Appends a footer that wires up the library table, short aliases, theme shortcuts, `gui()` helper, `transitionTheme()`, protection aliases, and auto-play intro

**Module processing order** (dependency-safe — earlier modules have no deps on later ones):
`Types` → `MangoProtection` → `Themes` → `LiquidFusion` → `RefractionProxy` → `MangoGlassFrame` → `MangoShimmer` → `MangoHaptics` → `MangoLayout` → `MangoToggle` → `MangoSlider` → `MangoCheckbox` → `MangoProgressBar` → `MangoSegmentedControl` → `MangoSearchBar` → `MangoTextField` → `MangoEnvironmentLight` → `MangoButton` → `MangoNotification` → `MangoBadge` → `MangoSkeleton` → `MangoStepper` → `MangoTooltip` → `MangoToast` → `MangoDialog` → `MangoActionSheet` → `MangoDropdown` → `MangoContextMenu` → `MangoTabBar` → `MangoBillboardLabel` → `MangoNotificationStack` → `MangoBottomSheet` → `MangoBlurProxy` → `MangoForm` → `MangoFocusManager` → `MangoIntro` → `MangoSaveManager` → `MangoColorPicker` → `MangoKeybind` → `MangoCarousel` → `MangoWindow` → `MangoBuilder`

**Key detail:** `MangoProtection` is position 2 (after `Types`, before `Themes`) because nearly all other modules depend on it for `createScreenGui()`, `randomName()`, and `registerInstance()`. Adding a new module requires:
1. Creating the `.luau` source file
2. Adding the module name to the `MODULES` array in `build.sh` at the correct dependency position
3. Adding `_require()`, library table entry, and short alias in the `FOOTER` section of `build.sh`
4. Running `bash build.sh` to regenerate the dist bundle

## Roblox Limitations

- **No native UI blur** — `BlurEffect` only works on the 3D workspace, not `ScreenGui`. Apple's core frosted glass blur effect is impossible to replicate natively in Roblox UI.
- **CanvasGroup performance** — 10+ visible `CanvasGroup` instances can drop FPS significantly (~12 FPS). The library uses 2 CanvasGroups per panel (LensGroup + TextureGroup). MangoBillboardLabel intentionally omits CanvasGroups. MangoButton, MangoTabBar, MangoSearchBar use `LightweightMode = true` to skip CanvasGroups. Demo uses a single main panel (2 CanvasGroups) with all other elements (notifications, buttons, carousel icons) using LightweightMode, keeping total CanvasGroup count to 2.
- **NumberSequence not tweeneable** — `UIGradient.Transparency` uses `NumberSequence` which `TweenService` cannot interpolate. Theme switching must destroy and rebuild glass frames; use `transitionTheme()` for visual smoothness.
- **Gotham font Unicode gaps** — Roblox's Gotham font family does NOT reliably render Unicode symbols like ✕ (U+2715), ▼ (U+25BC), ▾ (U+25BE). These render as empty boxes or misaligned glyphs on many platforms. Use ASCII alternatives: `"X"` for close/dismiss buttons, `"v"` for dropdown chevrons. For checkmarks (✓), use `Enum.Font.SourceSansBold` which has full Unicode support. Never use Gotham/GothamBold/GothamMedium for Unicode symbols beyond basic Latin.
- **InputBegan child blocking** — `GuiObject.InputBegan` fires only on the topmost element at the cursor position. All interactive glass elements must use a transparent `TextButton` hit area at ZIndex=100 to reliably capture input.

## Type Checking

```
luau-lsp analyze MangoLiquidUI/
```
