--!strict

local Types = require(script.Parent.Types)

local module = {}

--[[
	Resolves a config value with theme fallback and default.
	Needed because Luau's `or` operator treats `0` and `false` as falsy,
	so `config.X or theme.X or default` would skip valid zero/false values.
]]
function module.resolve(configVal: any?, themeVal: any?, default: any): any
	if configVal ~= nil then
		return configVal
	end
	if themeVal ~= nil then
		return themeVal
	end
	return default
end

module.Light = {
	-- Glass surface (Apple-level subtle transparency)
	BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	BackgroundTransparency = 0.85,

	-- Lens (saturation tint via CanvasGroup — lighter for subtlety)
	LensGroupColor3 = Color3.fromRGB(252, 252, 255),
	LensGroupTransparency = 0.62,

	-- Inner glow (thin highlight strip — Apple's 1px inset at 80%)
	InnerGlowColor = Color3.fromRGB(255, 255, 255),
	InnerGlowTransparency = 0.82,
	InnerGlowHeight = 0.12,

	-- Inner edge highlight (barely perceptible boundary)
	InnerEdgeColor = Color3.fromRGB(255, 255, 255),
	InnerEdgeTopTransparency = 0.45,
	InnerEdgeMidTransparency = 0.78,
	InnerEdgeBottomTransparency = 0.94,

	-- Fresnel rim (directional UIStroke) — paper-thin specular
	StrokeColor = Color3.fromRGB(255, 255, 255),
	StrokeThickness = 1.5,
	FresnelStartTransparency = 0.35,
	FresnelEndTransparency = 0.95,
	FresnelMidTransparency = 0.65,
	FresnelMidPoint = 0.40,
	FresnelAngle = 90,

	-- Shadow (Apple-spec: 8px offset, 24px spread)
	ShadowColor = Color3.fromRGB(0, 0, 0),
	ShadowTransparency = 0.80,
	ShadowSpread = 20,
	ShadowOffsetX = 0,
	ShadowOffsetY = 5,

	-- Refraction proxy (per-panel glass distortion — visible refraction, slightly inset)
	GlassColor = Color3.fromRGB(235, 240, 250),
	GlassTransparency = 0.88,
	GlassReflectance = 0.08,

	-- Noise
	NoiseOpacity = 0.03,

	-- Text
	PrimaryTextColor = Color3.fromRGB(0, 0, 0),
	SecondaryTextColor = Color3.fromRGB(60, 60, 70),

	-- Toggle
	ToggleOnTrackColor = Color3.fromRGB(52, 199, 89),
	ToggleOffTrackColor = Color3.fromRGB(200, 200, 200),
	ToggleKnobColor = Color3.fromRGB(255, 255, 255),

	-- Slider
	SliderTrackColor = Color3.fromRGB(210, 212, 218),
	SliderFillColor = Color3.fromRGB(0, 122, 255),
	SliderThumbColor = Color3.fromRGB(255, 255, 255),
	SliderTrackTransparency = 0.40,
	SliderFillTransparency = 0.40,

	-- Button (matches panel subtlety)
	ButtonPressScale = 0.97,
	ButtonBackgroundTransparency = 0.78,

	-- Parallax
	ParallaxIntensity = 0.15,

	-- Notification stacking
	NotificationStackGap = 14,
	NotificationMaxVisible = 3,

	-- Segmented control
	SegmentedBackgroundTransparency = 0.88,
	SegmentedSelectedTransparency = 0.72,
	SegmentedSelectedColor = Color3.fromRGB(255, 255, 255),

	-- Dropdown
	DropdownBackgroundTransparency = 0.82,
	DropdownItemHoverColor = Color3.fromRGB(0, 122, 255),
	DropdownItemHoverTransparency = 0.85,

	-- Tab bar
	TabBarBackgroundTransparency = 0.82,
	TabBarSelectedColor = Color3.fromRGB(0, 122, 255),
	TabBarIconColor = Color3.fromRGB(140, 140, 150),
	TabBarIconSelectedColor = Color3.fromRGB(0, 122, 255),

	-- Search bar
	SearchBarBackgroundTransparency = 0.88,
	SearchBarPlaceholderColor = Color3.fromRGB(142, 142, 147),

	-- Text field
	TextFieldBackgroundTransparency = 0.92,
	TextFieldBorderColor = Color3.fromRGB(200, 200, 205),
	TextFieldFocusBorderColor = Color3.fromRGB(0, 122, 255),

	-- Checkbox
	CheckboxOnColor = Color3.fromRGB(0, 122, 255),
	CheckboxOffColor = Color3.fromRGB(200, 200, 205),
	CheckboxCheckColor = Color3.fromRGB(255, 255, 255),

	-- Progress bar
	ProgressBarTrackTransparency = 0.85,
	ProgressBarFillColor = Color3.fromRGB(0, 122, 255),
	ProgressBarFillTransparency = 0.30,

	-- Dialog
	DialogOverlayTransparency = 0.40,
	DialogBackgroundTransparency = 0.78,

	-- Shimmer
	ShimmerColor = Color3.fromRGB(255, 255, 255),
	ShimmerTransparency = 0.85,

	-- Badge
	BadgeBackgroundColor = Color3.fromRGB(0, 122, 255),
	BadgeBackgroundTransparency = 0.15,
	BadgeTextColor = Color3.fromRGB(255, 255, 255),

	-- Tooltip
	TooltipBackgroundTransparency = 0.15,

	-- Stepper
	StepperBackgroundTransparency = 0.80,

	-- Skeleton
	SkeletonBackgroundColor = Color3.fromRGB(230, 230, 235),
	SkeletonBackgroundTransparency = 0.50,

	-- Toast
	ToastBackgroundTransparency = 0.20,

	-- Bottom Sheet
	BottomSheetBackgroundTransparency = 0.15,
	BottomSheetHandleColor = Color3.fromRGB(200, 200, 205),

	-- Blur Proxy
	BlurTintColor = Color3.fromRGB(255, 255, 255),
	BlurTintTransparency = 0.70,

	-- Form
	FormErrorColor = Color3.fromRGB(255, 59, 48),

	-- Focus Manager
	FocusRingColor = Color3.fromRGB(0, 122, 255),

	-- Window
	WindowBackgroundTransparency = 0.12,
	WindowTitleColor = Color3.fromRGB(0, 0, 0),

	-- Color Picker
	ColorPickerCursorColor = Color3.fromRGB(255, 255, 255),

	-- Keybind
	KeybindPillTransparency = 0.70,
	KeybindListeningColor = Color3.fromRGB(0, 122, 255),

	-- Accent
	AccentColor = Color3.fromRGB(0, 122, 255),
} :: Types.ThemePreset

module.Mango = {
	-- Glass surface (warm amber-tinted glass, Apple-level subtle)
	BackgroundColor3 = Color3.fromRGB(255, 235, 200),
	BackgroundTransparency = 0.84,

	-- Lens (warm saturation tint — lighter)
	LensGroupColor3 = Color3.fromRGB(255, 240, 210),
	LensGroupTransparency = 0.60,

	-- Inner glow (thin highlight strip — Apple's 1px inset at 80%)
	InnerGlowColor = Color3.fromRGB(255, 245, 220),
	InnerGlowTransparency = 0.82,
	InnerGlowHeight = 0.12,

	-- Inner edge highlight (barely perceptible)
	InnerEdgeColor = Color3.fromRGB(255, 250, 235),
	InnerEdgeTopTransparency = 0.42,
	InnerEdgeMidTransparency = 0.76,
	InnerEdgeBottomTransparency = 0.94,

	-- Fresnel rim — paper-thin
	StrokeColor = Color3.fromRGB(255, 245, 220),
	StrokeThickness = 1.5,
	FresnelStartTransparency = 0.32,
	FresnelEndTransparency = 0.94,
	FresnelMidTransparency = 0.62,
	FresnelMidPoint = 0.40,
	FresnelAngle = 90,

	-- Shadow (Apple-spec: deeper, wider)
	ShadowColor = Color3.fromRGB(80, 50, 20),
	ShadowTransparency = 0.80,
	ShadowSpread = 20,
	ShadowOffsetX = 0,
	ShadowOffsetY = 5,

	-- Refraction proxy (per-panel glass distortion — visible refraction, slightly inset)
	GlassColor = Color3.fromRGB(250, 240, 220),
	GlassTransparency = 0.875,
	GlassReflectance = 0.085,

	-- Noise
	NoiseOpacity = 0.03,

	-- Text
	PrimaryTextColor = Color3.fromRGB(60, 35, 10),
	SecondaryTextColor = Color3.fromRGB(120, 80, 40),

	-- Toggle
	ToggleOnTrackColor = Color3.fromRGB(255, 149, 0),
	ToggleOffTrackColor = Color3.fromRGB(210, 195, 175),
	ToggleKnobColor = Color3.fromRGB(255, 255, 255),

	-- Slider
	SliderTrackColor = Color3.fromRGB(230, 210, 185),
	SliderFillColor = Color3.fromRGB(255, 149, 0),
	SliderThumbColor = Color3.fromRGB(255, 255, 255),
	SliderTrackTransparency = 0.45,
	SliderFillTransparency = 0.38,

	-- Button
	ButtonPressScale = 0.97,
	ButtonBackgroundTransparency = 0.76,

	-- Parallax
	ParallaxIntensity = 0.15,

	-- Notification stacking
	NotificationStackGap = 14,
	NotificationMaxVisible = 3,

	-- Segmented control (orange accent)
	SegmentedBackgroundTransparency = 0.87,
	SegmentedSelectedTransparency = 0.70,
	SegmentedSelectedColor = Color3.fromRGB(255, 245, 220),

	-- Dropdown
	DropdownBackgroundTransparency = 0.80,
	DropdownItemHoverColor = Color3.fromRGB(255, 149, 0),
	DropdownItemHoverTransparency = 0.84,

	-- Tab bar
	TabBarBackgroundTransparency = 0.80,
	TabBarSelectedColor = Color3.fromRGB(255, 149, 0),
	TabBarIconColor = Color3.fromRGB(160, 130, 90),
	TabBarIconSelectedColor = Color3.fromRGB(255, 149, 0),

	-- Search bar
	SearchBarBackgroundTransparency = 0.87,
	SearchBarPlaceholderColor = Color3.fromRGB(160, 130, 90),

	-- Text field
	TextFieldBackgroundTransparency = 0.90,
	TextFieldBorderColor = Color3.fromRGB(210, 190, 165),
	TextFieldFocusBorderColor = Color3.fromRGB(255, 149, 0),

	-- Checkbox (orange accent)
	CheckboxOnColor = Color3.fromRGB(255, 149, 0),
	CheckboxOffColor = Color3.fromRGB(210, 195, 175),
	CheckboxCheckColor = Color3.fromRGB(255, 255, 255),

	-- Progress bar
	ProgressBarTrackTransparency = 0.84,
	ProgressBarFillColor = Color3.fromRGB(255, 149, 0),
	ProgressBarFillTransparency = 0.28,

	-- Dialog
	DialogOverlayTransparency = 0.42,
	DialogBackgroundTransparency = 0.76,

	-- Shimmer
	ShimmerColor = Color3.fromRGB(255, 240, 200),
	ShimmerTransparency = 0.85,

	-- Badge
	BadgeBackgroundColor = Color3.fromRGB(255, 149, 0),
	BadgeBackgroundTransparency = 0.15,
	BadgeTextColor = Color3.fromRGB(255, 255, 255),

	-- Tooltip
	TooltipBackgroundTransparency = 0.12,

	-- Stepper
	StepperBackgroundTransparency = 0.78,

	-- Skeleton
	SkeletonBackgroundColor = Color3.fromRGB(235, 220, 195),
	SkeletonBackgroundTransparency = 0.50,

	-- Toast
	ToastBackgroundTransparency = 0.18,

	-- Bottom Sheet
	BottomSheetBackgroundTransparency = 0.14,
	BottomSheetHandleColor = Color3.fromRGB(200, 180, 150),

	-- Blur Proxy
	BlurTintColor = Color3.fromRGB(255, 235, 200),
	BlurTintTransparency = 0.70,

	-- Form
	FormErrorColor = Color3.fromRGB(255, 59, 48),

	-- Focus Manager
	FocusRingColor = Color3.fromRGB(255, 149, 0),

	-- Window
	WindowBackgroundTransparency = 0.14,
	WindowTitleColor = Color3.fromRGB(60, 35, 10),

	-- Color Picker
	ColorPickerCursorColor = Color3.fromRGB(255, 255, 255),

	-- Keybind
	KeybindPillTransparency = 0.68,
	KeybindListeningColor = Color3.fromRGB(255, 149, 0),

	-- Accent
	AccentColor = Color3.fromRGB(255, 149, 0),
} :: Types.ThemePreset

module.Dark = {
	-- Glass surface (rich dark glass — Apple-level subtle)
	BackgroundColor3 = Color3.fromRGB(28, 30, 38),
	BackgroundTransparency = 0.82,

	-- Lens (saturation tint via CanvasGroup — lighter)
	LensGroupColor3 = Color3.fromRGB(190, 200, 220),
	LensGroupTransparency = 0.64,

	-- Inner glow (thin highlight strip — Apple's 1px inset at 80%)
	InnerGlowColor = Color3.fromRGB(255, 255, 255),
	InnerGlowTransparency = 0.82,
	InnerGlowHeight = 0.12,

	-- Inner edge highlight (barely perceptible)
	InnerEdgeColor = Color3.fromRGB(255, 255, 255),
	InnerEdgeTopTransparency = 0.40,
	InnerEdgeMidTransparency = 0.74,
	InnerEdgeBottomTransparency = 0.93,

	-- Fresnel rim (directional UIStroke) — paper-thin specular
	StrokeColor = Color3.fromRGB(255, 255, 255),
	StrokeThickness = 1.5,
	FresnelStartTransparency = 0.30,
	FresnelEndTransparency = 0.93,
	FresnelMidTransparency = 0.58,
	FresnelMidPoint = 0.40,
	FresnelAngle = 90,

	-- Shadow (Apple-spec: deeper, wider)
	ShadowColor = Color3.fromRGB(0, 0, 0),
	ShadowTransparency = 0.75,
	ShadowSpread = 22,
	ShadowOffsetX = 0,
	ShadowOffsetY = 5,

	-- Refraction proxy (per-panel glass distortion — visible refraction, slightly inset)
	GlassColor = Color3.fromRGB(50, 55, 70),
	GlassTransparency = 0.87,
	GlassReflectance = 0.09,

	-- Noise
	NoiseOpacity = 0.03,

	-- Text
	PrimaryTextColor = Color3.fromRGB(255, 255, 255),
	SecondaryTextColor = Color3.fromRGB(170, 170, 185),

	-- Toggle
	ToggleOnTrackColor = Color3.fromRGB(48, 209, 88),
	ToggleOffTrackColor = Color3.fromRGB(80, 80, 85),
	ToggleKnobColor = Color3.fromRGB(255, 255, 255),

	-- Slider
	SliderTrackColor = Color3.fromRGB(55, 55, 65),
	SliderFillColor = Color3.fromRGB(10, 132, 255),
	SliderThumbColor = Color3.fromRGB(255, 255, 255),
	SliderTrackTransparency = 0.38,
	SliderFillTransparency = 0.35,

	-- Button (matches panel subtlety)
	ButtonPressScale = 0.97,
	ButtonBackgroundTransparency = 0.75,

	-- Parallax
	ParallaxIntensity = 0.15,

	-- Notification stacking
	NotificationStackGap = 14,
	NotificationMaxVisible = 3,

	-- Segmented control (blue accent)
	SegmentedBackgroundTransparency = 0.85,
	SegmentedSelectedTransparency = 0.68,
	SegmentedSelectedColor = Color3.fromRGB(50, 55, 70),

	-- Dropdown
	DropdownBackgroundTransparency = 0.78,
	DropdownItemHoverColor = Color3.fromRGB(10, 132, 255),
	DropdownItemHoverTransparency = 0.82,

	-- Tab bar
	TabBarBackgroundTransparency = 0.78,
	TabBarSelectedColor = Color3.fromRGB(10, 132, 255),
	TabBarIconColor = Color3.fromRGB(120, 120, 135),
	TabBarIconSelectedColor = Color3.fromRGB(10, 132, 255),

	-- Search bar
	SearchBarBackgroundTransparency = 0.85,
	SearchBarPlaceholderColor = Color3.fromRGB(120, 120, 135),

	-- Text field
	TextFieldBackgroundTransparency = 0.88,
	TextFieldBorderColor = Color3.fromRGB(70, 70, 80),
	TextFieldFocusBorderColor = Color3.fromRGB(10, 132, 255),

	-- Checkbox (blue accent)
	CheckboxOnColor = Color3.fromRGB(10, 132, 255),
	CheckboxOffColor = Color3.fromRGB(80, 80, 85),
	CheckboxCheckColor = Color3.fromRGB(255, 255, 255),

	-- Progress bar
	ProgressBarTrackTransparency = 0.82,
	ProgressBarFillColor = Color3.fromRGB(10, 132, 255),
	ProgressBarFillTransparency = 0.25,

	-- Dialog
	DialogOverlayTransparency = 0.35,
	DialogBackgroundTransparency = 0.74,

	-- Shimmer
	ShimmerColor = Color3.fromRGB(255, 255, 255),
	ShimmerTransparency = 0.85,

	-- Badge
	BadgeBackgroundColor = Color3.fromRGB(10, 132, 255),
	BadgeBackgroundTransparency = 0.15,
	BadgeTextColor = Color3.fromRGB(255, 255, 255),

	-- Tooltip
	TooltipBackgroundTransparency = 0.15,

	-- Stepper
	StepperBackgroundTransparency = 0.76,

	-- Skeleton
	SkeletonBackgroundColor = Color3.fromRGB(45, 45, 55),
	SkeletonBackgroundTransparency = 0.50,

	-- Toast
	ToastBackgroundTransparency = 0.18,

	-- Bottom Sheet
	BottomSheetBackgroundTransparency = 0.12,
	BottomSheetHandleColor = Color3.fromRGB(80, 80, 90),

	-- Blur Proxy
	BlurTintColor = Color3.fromRGB(28, 30, 38),
	BlurTintTransparency = 0.70,

	-- Form
	FormErrorColor = Color3.fromRGB(255, 59, 48),

	-- Focus Manager
	FocusRingColor = Color3.fromRGB(10, 132, 255),

	-- Window
	WindowBackgroundTransparency = 0.15,
	WindowTitleColor = Color3.fromRGB(255, 255, 255),

	-- Color Picker
	ColorPickerCursorColor = Color3.fromRGB(255, 255, 255),

	-- Keybind
	KeybindPillTransparency = 0.72,
	KeybindListeningColor = Color3.fromRGB(10, 132, 255),

	-- Accent
	AccentColor = Color3.fromRGB(10, 132, 255),
} :: Types.ThemePreset

module.Mint = {
	-- Glass surface (cool mint-tinted glass)
	BackgroundColor3 = Color3.fromRGB(235, 252, 245),
	BackgroundTransparency = 0.86,

	-- Lens (mint saturation tint)
	LensGroupColor3 = Color3.fromRGB(220, 250, 240),
	LensGroupTransparency = 0.62,

	-- Inner glow (thin highlight strip — Apple's 1px inset at 80%)
	InnerGlowColor = Color3.fromRGB(240, 255, 248),
	InnerGlowTransparency = 0.82,
	InnerGlowHeight = 0.12,

	-- Inner edge highlight
	InnerEdgeColor = Color3.fromRGB(240, 255, 248),
	InnerEdgeTopTransparency = 0.44,
	InnerEdgeMidTransparency = 0.77,
	InnerEdgeBottomTransparency = 0.94,

	-- Fresnel rim
	StrokeColor = Color3.fromRGB(240, 255, 248),
	StrokeThickness = 1.5,
	FresnelStartTransparency = 0.34,
	FresnelEndTransparency = 0.95,
	FresnelMidTransparency = 0.64,
	FresnelMidPoint = 0.40,
	FresnelAngle = 90,

	-- Shadow (Apple-spec: deeper, wider)
	ShadowColor = Color3.fromRGB(20, 80, 60),
	ShadowTransparency = 0.82,
	ShadowSpread = 20,
	ShadowOffsetX = 0,
	ShadowOffsetY = 5,

	-- Refraction proxy
	GlassColor = Color3.fromRGB(230, 248, 240),
	GlassTransparency = 0.88,
	GlassReflectance = 0.08,

	-- Noise
	NoiseOpacity = 0.03,

	-- Text
	PrimaryTextColor = Color3.fromRGB(15, 55, 45),
	SecondaryTextColor = Color3.fromRGB(50, 100, 85),

	-- Toggle
	ToggleOnTrackColor = Color3.fromRGB(0, 199, 140),
	ToggleOffTrackColor = Color3.fromRGB(190, 210, 200),
	ToggleKnobColor = Color3.fromRGB(255, 255, 255),

	-- Slider
	SliderTrackColor = Color3.fromRGB(200, 225, 215),
	SliderFillColor = Color3.fromRGB(0, 199, 140),
	SliderThumbColor = Color3.fromRGB(255, 255, 255),
	SliderTrackTransparency = 0.42,
	SliderFillTransparency = 0.38,

	-- Button
	ButtonPressScale = 0.97,
	ButtonBackgroundTransparency = 0.78,

	-- Parallax
	ParallaxIntensity = 0.15,

	-- Notification stacking
	NotificationStackGap = 14,
	NotificationMaxVisible = 3,

	-- Segmented control (mint accent)
	SegmentedBackgroundTransparency = 0.88,
	SegmentedSelectedTransparency = 0.72,
	SegmentedSelectedColor = Color3.fromRGB(240, 255, 248),

	-- Dropdown
	DropdownBackgroundTransparency = 0.82,
	DropdownItemHoverColor = Color3.fromRGB(0, 199, 140),
	DropdownItemHoverTransparency = 0.85,

	-- Tab bar
	TabBarBackgroundTransparency = 0.82,
	TabBarSelectedColor = Color3.fromRGB(0, 199, 140),
	TabBarIconColor = Color3.fromRGB(100, 150, 130),
	TabBarIconSelectedColor = Color3.fromRGB(0, 199, 140),

	-- Search bar
	SearchBarBackgroundTransparency = 0.88,
	SearchBarPlaceholderColor = Color3.fromRGB(100, 150, 130),

	-- Text field
	TextFieldBackgroundTransparency = 0.92,
	TextFieldBorderColor = Color3.fromRGB(190, 215, 205),
	TextFieldFocusBorderColor = Color3.fromRGB(0, 199, 140),

	-- Checkbox (mint accent)
	CheckboxOnColor = Color3.fromRGB(0, 199, 140),
	CheckboxOffColor = Color3.fromRGB(190, 210, 200),
	CheckboxCheckColor = Color3.fromRGB(255, 255, 255),

	-- Progress bar
	ProgressBarTrackTransparency = 0.85,
	ProgressBarFillColor = Color3.fromRGB(0, 199, 140),
	ProgressBarFillTransparency = 0.30,

	-- Dialog
	DialogOverlayTransparency = 0.40,
	DialogBackgroundTransparency = 0.78,

	-- Shimmer
	ShimmerColor = Color3.fromRGB(240, 255, 248),
	ShimmerTransparency = 0.85,

	-- Badge
	BadgeBackgroundColor = Color3.fromRGB(0, 199, 140),
	BadgeBackgroundTransparency = 0.15,
	BadgeTextColor = Color3.fromRGB(255, 255, 255),

	-- Tooltip
	TooltipBackgroundTransparency = 0.15,

	-- Stepper
	StepperBackgroundTransparency = 0.80,

	-- Skeleton
	SkeletonBackgroundColor = Color3.fromRGB(220, 240, 232),
	SkeletonBackgroundTransparency = 0.50,

	-- Toast
	ToastBackgroundTransparency = 0.20,

	-- Bottom Sheet
	BottomSheetBackgroundTransparency = 0.15,
	BottomSheetHandleColor = Color3.fromRGB(180, 210, 200),

	-- Blur Proxy
	BlurTintColor = Color3.fromRGB(235, 252, 245),
	BlurTintTransparency = 0.70,

	-- Form
	FormErrorColor = Color3.fromRGB(255, 59, 48),

	-- Focus Manager
	FocusRingColor = Color3.fromRGB(0, 199, 140),

	-- Window
	WindowBackgroundTransparency = 0.13,
	WindowTitleColor = Color3.fromRGB(15, 55, 45),

	-- Color Picker
	ColorPickerCursorColor = Color3.fromRGB(255, 255, 255),

	-- Keybind
	KeybindPillTransparency = 0.70,
	KeybindListeningColor = Color3.fromRGB(0, 199, 140),

	-- Accent
	AccentColor = Color3.fromRGB(0, 199, 140),
} :: Types.ThemePreset

function module.custom(base: Types.ThemePreset, overrides: {[string]: any}): Types.ThemePreset
	local theme = table.clone(base)
	for key, value in overrides do
		(theme :: any)[key] = value
	end
	return theme
end

return module
