--!strict

--[[
	MangoLiquidUI Demo — Self-contained LocalScript
	Place in StarterPlayerScripts to see the full Liquid Glass system.
	Showcases: Glass panels, Apple slider, buttons, billboard labels,
	refraction proxy, liquid fusion hover, dynamic lighting, notifications,
	segmented control, checkbox, progress bar, search bar, text field,
	dropdown, tab bar, dialog, action sheet, parallax, and
	Light/Dark/Mango theme cycling with spotlight intro animation.
	No external dependencies — all logic is inlined.
]]

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local TextService = game:GetService("TextService")
local SoundService = game:GetService("SoundService")
local ContextActionService = game:GetService("ContextActionService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--------------------------------------------------------------------------------
-- Nil-safe resolve helper (Luau's `or` treats 0/false as falsy)
--------------------------------------------------------------------------------

local function resolve(configVal: any?, themeVal: any?, default: any): any
	if configVal ~= nil then return configVal end
	if themeVal ~= nil then return themeVal end
	return default
end

--------------------------------------------------------------------------------
-- Theme type & presets (values copied exactly from Themes.luau)
--------------------------------------------------------------------------------

type ThemePreset = {
	BackgroundColor3: Color3,
	BackgroundTransparency: number,
	LensGroupColor3: Color3,
	LensGroupTransparency: number,
	InnerGlowColor: Color3,
	InnerGlowTransparency: number,
	InnerGlowHeight: number,
	InnerEdgeColor: Color3,
	InnerEdgeTopTransparency: number,
	InnerEdgeMidTransparency: number,
	InnerEdgeBottomTransparency: number,
	StrokeColor: Color3,
	StrokeThickness: number,
	FresnelStartTransparency: number,
	FresnelEndTransparency: number,
	FresnelMidTransparency: number,
	FresnelMidPoint: number,
	FresnelAngle: number,
	ShadowColor: Color3,
	ShadowTransparency: number,
	ShadowSpread: number,
	ShadowOffsetX: number,
	ShadowOffsetY: number,
	GlassColor: Color3,
	GlassTransparency: number,
	GlassReflectance: number,
	NoiseOpacity: number,
	PrimaryTextColor: Color3,
	SecondaryTextColor: Color3,
	ToggleOnTrackColor: Color3,
	ToggleOffTrackColor: Color3,
	ToggleKnobColor: Color3,
	SliderTrackColor: Color3,
	SliderFillColor: Color3,
	SliderThumbColor: Color3,
	SliderTrackTransparency: number,
	SliderFillTransparency: number,
	ButtonPressScale: number,
	ButtonBackgroundTransparency: number,
	ParallaxIntensity: number,
	NotificationStackGap: number,
	NotificationMaxVisible: number,
	SegmentedBackgroundTransparency: number,
	SegmentedSelectedTransparency: number,
	SegmentedSelectedColor: Color3,
	DropdownBackgroundTransparency: number,
	DropdownItemHoverColor: Color3,
	DropdownItemHoverTransparency: number,
	TabBarBackgroundTransparency: number,
	TabBarSelectedColor: Color3,
	TabBarIconColor: Color3,
	TabBarIconSelectedColor: Color3,
	SearchBarBackgroundTransparency: number,
	SearchBarPlaceholderColor: Color3,
	TextFieldBackgroundTransparency: number,
	TextFieldBorderColor: Color3,
	TextFieldFocusBorderColor: Color3,
	CheckboxOnColor: Color3,
	CheckboxOffColor: Color3,
	CheckboxCheckColor: Color3,
	ProgressBarTrackTransparency: number,
	ProgressBarFillColor: Color3,
	ProgressBarFillTransparency: number,
	DialogOverlayTransparency: number,
	DialogBackgroundTransparency: number,
}

local LightTheme: ThemePreset = {
	BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	BackgroundTransparency = 0.85,
	LensGroupColor3 = Color3.fromRGB(252, 252, 255),
	LensGroupTransparency = 0.62,
	InnerGlowColor = Color3.fromRGB(255, 255, 255),
	InnerGlowTransparency = 0.82,
	InnerGlowHeight = 0.12,
	InnerEdgeColor = Color3.fromRGB(255, 255, 255),
	InnerEdgeTopTransparency = 0.45,
	InnerEdgeMidTransparency = 0.78,
	InnerEdgeBottomTransparency = 0.94,
	StrokeColor = Color3.fromRGB(255, 255, 255),
	StrokeThickness = 1.5,
	FresnelStartTransparency = 0.35,
	FresnelEndTransparency = 0.95,
	FresnelMidTransparency = 0.65,
	FresnelMidPoint = 0.30,
	FresnelAngle = 90,
	ShadowColor = Color3.fromRGB(0, 0, 0),
	ShadowTransparency = 0.80,
	ShadowSpread = 20,
	ShadowOffsetX = 0,
	ShadowOffsetY = 5,
	GlassColor = Color3.fromRGB(235, 240, 250),
	GlassTransparency = 0.88,
	GlassReflectance = 0.08,
	NoiseOpacity = 0.03,
	PrimaryTextColor = Color3.fromRGB(0, 0, 0),
	SecondaryTextColor = Color3.fromRGB(60, 60, 70),
	ToggleOnTrackColor = Color3.fromRGB(52, 199, 89),
	ToggleOffTrackColor = Color3.fromRGB(200, 200, 200),
	ToggleKnobColor = Color3.fromRGB(255, 255, 255),
	SliderTrackColor = Color3.fromRGB(210, 212, 218),
	SliderFillColor = Color3.fromRGB(0, 122, 255),
	SliderThumbColor = Color3.fromRGB(255, 255, 255),
	SliderTrackTransparency = 0.40,
	SliderFillTransparency = 0.40,
	ButtonPressScale = 0.97,
	ButtonBackgroundTransparency = 0.78,
	ParallaxIntensity = 0.15,
	NotificationStackGap = 14,
	NotificationMaxVisible = 3,
	SegmentedBackgroundTransparency = 0.88,
	SegmentedSelectedTransparency = 0.72,
	SegmentedSelectedColor = Color3.fromRGB(255, 255, 255),
	DropdownBackgroundTransparency = 0.82,
	DropdownItemHoverColor = Color3.fromRGB(0, 122, 255),
	DropdownItemHoverTransparency = 0.85,
	TabBarBackgroundTransparency = 0.82,
	TabBarSelectedColor = Color3.fromRGB(0, 122, 255),
	TabBarIconColor = Color3.fromRGB(140, 140, 150),
	TabBarIconSelectedColor = Color3.fromRGB(0, 122, 255),
	SearchBarBackgroundTransparency = 0.88,
	SearchBarPlaceholderColor = Color3.fromRGB(142, 142, 147),
	TextFieldBackgroundTransparency = 0.92,
	TextFieldBorderColor = Color3.fromRGB(200, 200, 205),
	TextFieldFocusBorderColor = Color3.fromRGB(0, 122, 255),
	CheckboxOnColor = Color3.fromRGB(0, 122, 255),
	CheckboxOffColor = Color3.fromRGB(200, 200, 205),
	CheckboxCheckColor = Color3.fromRGB(255, 255, 255),
	ProgressBarTrackTransparency = 0.85,
	ProgressBarFillColor = Color3.fromRGB(0, 122, 255),
	ProgressBarFillTransparency = 0.30,
	DialogOverlayTransparency = 0.40,
	DialogBackgroundTransparency = 0.78,
}

local DarkTheme: ThemePreset = {
	BackgroundColor3 = Color3.fromRGB(28, 30, 38),
	BackgroundTransparency = 0.82,
	LensGroupColor3 = Color3.fromRGB(190, 200, 220),
	LensGroupTransparency = 0.64,
	InnerGlowColor = Color3.fromRGB(255, 255, 255),
	InnerGlowTransparency = 0.82,
	InnerGlowHeight = 0.12,
	InnerEdgeColor = Color3.fromRGB(255, 255, 255),
	InnerEdgeTopTransparency = 0.40,
	InnerEdgeMidTransparency = 0.74,
	InnerEdgeBottomTransparency = 0.93,
	StrokeColor = Color3.fromRGB(255, 255, 255),
	StrokeThickness = 1.5,
	FresnelStartTransparency = 0.30,
	FresnelEndTransparency = 0.93,
	FresnelMidTransparency = 0.58,
	FresnelMidPoint = 0.30,
	FresnelAngle = 90,
	ShadowColor = Color3.fromRGB(0, 0, 0),
	ShadowTransparency = 0.75,
	ShadowSpread = 22,
	ShadowOffsetX = 0,
	ShadowOffsetY = 5,
	GlassColor = Color3.fromRGB(50, 55, 70),
	GlassTransparency = 0.87,
	GlassReflectance = 0.09,
	NoiseOpacity = 0.03,
	PrimaryTextColor = Color3.fromRGB(255, 255, 255),
	SecondaryTextColor = Color3.fromRGB(170, 170, 185),
	ToggleOnTrackColor = Color3.fromRGB(48, 209, 88),
	ToggleOffTrackColor = Color3.fromRGB(80, 80, 85),
	ToggleKnobColor = Color3.fromRGB(255, 255, 255),
	SliderTrackColor = Color3.fromRGB(55, 55, 65),
	SliderFillColor = Color3.fromRGB(10, 132, 255),
	SliderThumbColor = Color3.fromRGB(255, 255, 255),
	SliderTrackTransparency = 0.38,
	SliderFillTransparency = 0.35,
	ButtonPressScale = 0.97,
	ButtonBackgroundTransparency = 0.75,
	ParallaxIntensity = 0.15,
	NotificationStackGap = 14,
	NotificationMaxVisible = 3,
	SegmentedBackgroundTransparency = 0.85,
	SegmentedSelectedTransparency = 0.68,
	SegmentedSelectedColor = Color3.fromRGB(50, 55, 70),
	DropdownBackgroundTransparency = 0.78,
	DropdownItemHoverColor = Color3.fromRGB(10, 132, 255),
	DropdownItemHoverTransparency = 0.82,
	TabBarBackgroundTransparency = 0.78,
	TabBarSelectedColor = Color3.fromRGB(10, 132, 255),
	TabBarIconColor = Color3.fromRGB(120, 120, 135),
	TabBarIconSelectedColor = Color3.fromRGB(10, 132, 255),
	SearchBarBackgroundTransparency = 0.85,
	SearchBarPlaceholderColor = Color3.fromRGB(120, 120, 135),
	TextFieldBackgroundTransparency = 0.88,
	TextFieldBorderColor = Color3.fromRGB(70, 70, 80),
	TextFieldFocusBorderColor = Color3.fromRGB(10, 132, 255),
	CheckboxOnColor = Color3.fromRGB(10, 132, 255),
	CheckboxOffColor = Color3.fromRGB(80, 80, 85),
	CheckboxCheckColor = Color3.fromRGB(255, 255, 255),
	ProgressBarTrackTransparency = 0.82,
	ProgressBarFillColor = Color3.fromRGB(10, 132, 255),
	ProgressBarFillTransparency = 0.25,
	DialogOverlayTransparency = 0.35,
	DialogBackgroundTransparency = 0.74,
}

local MangoTheme: ThemePreset = {
	BackgroundColor3 = Color3.fromRGB(255, 235, 200),
	BackgroundTransparency = 0.84,
	LensGroupColor3 = Color3.fromRGB(255, 240, 210),
	LensGroupTransparency = 0.60,
	InnerGlowColor = Color3.fromRGB(255, 245, 220),
	InnerGlowTransparency = 0.82,
	InnerGlowHeight = 0.12,
	InnerEdgeColor = Color3.fromRGB(255, 250, 235),
	InnerEdgeTopTransparency = 0.42,
	InnerEdgeMidTransparency = 0.76,
	InnerEdgeBottomTransparency = 0.94,
	StrokeColor = Color3.fromRGB(255, 245, 220),
	StrokeThickness = 1.5,
	FresnelStartTransparency = 0.32,
	FresnelEndTransparency = 0.94,
	FresnelMidTransparency = 0.62,
	FresnelMidPoint = 0.30,
	FresnelAngle = 90,
	ShadowColor = Color3.fromRGB(80, 50, 20),
	ShadowTransparency = 0.80,
	ShadowSpread = 20,
	ShadowOffsetX = 0,
	ShadowOffsetY = 5,
	GlassColor = Color3.fromRGB(250, 240, 220),
	GlassTransparency = 0.875,
	GlassReflectance = 0.085,
	NoiseOpacity = 0.03,
	PrimaryTextColor = Color3.fromRGB(60, 35, 10),
	SecondaryTextColor = Color3.fromRGB(120, 80, 40),
	ToggleOnTrackColor = Color3.fromRGB(255, 149, 0),
	ToggleOffTrackColor = Color3.fromRGB(210, 195, 175),
	ToggleKnobColor = Color3.fromRGB(255, 255, 255),
	SliderTrackColor = Color3.fromRGB(230, 210, 185),
	SliderFillColor = Color3.fromRGB(255, 149, 0),
	SliderThumbColor = Color3.fromRGB(255, 255, 255),
	SliderTrackTransparency = 0.45,
	SliderFillTransparency = 0.38,
	ButtonPressScale = 0.97,
	ButtonBackgroundTransparency = 0.76,
	ParallaxIntensity = 0.15,
	NotificationStackGap = 14,
	NotificationMaxVisible = 3,
	SegmentedBackgroundTransparency = 0.87,
	SegmentedSelectedTransparency = 0.70,
	SegmentedSelectedColor = Color3.fromRGB(255, 245, 220),
	DropdownBackgroundTransparency = 0.80,
	DropdownItemHoverColor = Color3.fromRGB(255, 149, 0),
	DropdownItemHoverTransparency = 0.84,
	TabBarBackgroundTransparency = 0.80,
	TabBarSelectedColor = Color3.fromRGB(255, 149, 0),
	TabBarIconColor = Color3.fromRGB(160, 130, 90),
	TabBarIconSelectedColor = Color3.fromRGB(255, 149, 0),
	SearchBarBackgroundTransparency = 0.87,
	SearchBarPlaceholderColor = Color3.fromRGB(160, 130, 90),
	TextFieldBackgroundTransparency = 0.90,
	TextFieldBorderColor = Color3.fromRGB(210, 190, 165),
	TextFieldFocusBorderColor = Color3.fromRGB(255, 149, 0),
	CheckboxOnColor = Color3.fromRGB(255, 149, 0),
	CheckboxOffColor = Color3.fromRGB(210, 195, 175),
	CheckboxCheckColor = Color3.fromRGB(255, 255, 255),
	ProgressBarTrackTransparency = 0.84,
	ProgressBarFillColor = Color3.fromRGB(255, 149, 0),
	ProgressBarFillTransparency = 0.28,
	DialogOverlayTransparency = 0.42,
	DialogBackgroundTransparency = 0.76,
}

local MintTheme: ThemePreset = {
	BackgroundColor3 = Color3.fromRGB(235, 252, 245),
	BackgroundTransparency = 0.86,
	LensGroupColor3 = Color3.fromRGB(220, 250, 240),
	LensGroupTransparency = 0.62,
	InnerGlowColor = Color3.fromRGB(240, 255, 248),
	InnerGlowTransparency = 0.82,
	InnerGlowHeight = 0.12,
	InnerEdgeColor = Color3.fromRGB(240, 255, 248),
	InnerEdgeTopTransparency = 0.44,
	InnerEdgeMidTransparency = 0.77,
	InnerEdgeBottomTransparency = 0.94,
	StrokeColor = Color3.fromRGB(240, 255, 248),
	StrokeThickness = 1.5,
	FresnelStartTransparency = 0.34,
	FresnelEndTransparency = 0.95,
	FresnelMidTransparency = 0.64,
	FresnelMidPoint = 0.30,
	FresnelAngle = 90,
	ShadowColor = Color3.fromRGB(20, 80, 60),
	ShadowTransparency = 0.82,
	ShadowSpread = 20,
	ShadowOffsetX = 0,
	ShadowOffsetY = 5,
	GlassColor = Color3.fromRGB(230, 248, 240),
	GlassTransparency = 0.88,
	GlassReflectance = 0.08,
	NoiseOpacity = 0.03,
	PrimaryTextColor = Color3.fromRGB(15, 55, 45),
	SecondaryTextColor = Color3.fromRGB(50, 100, 85),
	ToggleOnTrackColor = Color3.fromRGB(0, 199, 140),
	ToggleOffTrackColor = Color3.fromRGB(190, 210, 200),
	ToggleKnobColor = Color3.fromRGB(255, 255, 255),
	SliderTrackColor = Color3.fromRGB(200, 225, 215),
	SliderFillColor = Color3.fromRGB(0, 199, 140),
	SliderThumbColor = Color3.fromRGB(255, 255, 255),
	SliderTrackTransparency = 0.42,
	SliderFillTransparency = 0.38,
	ButtonPressScale = 0.97,
	ButtonBackgroundTransparency = 0.78,
	ParallaxIntensity = 0.15,
	NotificationStackGap = 14,
	NotificationMaxVisible = 3,
	SegmentedBackgroundTransparency = 0.88,
	SegmentedSelectedTransparency = 0.72,
	SegmentedSelectedColor = Color3.fromRGB(240, 255, 248),
	DropdownBackgroundTransparency = 0.82,
	DropdownItemHoverColor = Color3.fromRGB(0, 199, 140),
	DropdownItemHoverTransparency = 0.85,
	TabBarBackgroundTransparency = 0.82,
	TabBarSelectedColor = Color3.fromRGB(0, 199, 140),
	TabBarIconColor = Color3.fromRGB(100, 150, 130),
	TabBarIconSelectedColor = Color3.fromRGB(0, 199, 140),
	SearchBarBackgroundTransparency = 0.88,
	SearchBarPlaceholderColor = Color3.fromRGB(100, 150, 130),
	TextFieldBackgroundTransparency = 0.92,
	TextFieldBorderColor = Color3.fromRGB(190, 215, 205),
	TextFieldFocusBorderColor = Color3.fromRGB(0, 199, 140),
	CheckboxOnColor = Color3.fromRGB(0, 199, 140),
	CheckboxOffColor = Color3.fromRGB(190, 210, 200),
	CheckboxCheckColor = Color3.fromRGB(255, 255, 255),
	ProgressBarTrackTransparency = 0.85,
	ProgressBarFillColor = Color3.fromRGB(0, 199, 140),
	ProgressBarFillTransparency = 0.30,
	DialogOverlayTransparency = 0.40,
	DialogBackgroundTransparency = 0.78,
}

-- Theme cycling order
local themeOrder: { { name: string, theme: ThemePreset } } = {
	{ name = "Light", theme = LightTheme },
	{ name = "Dark", theme = DarkTheme },
	{ name = "Mango", theme = MangoTheme },
	{ name = "Mint", theme = MintTheme },
}

--------------------------------------------------------------------------------
-- Inline Glass Frame constructor (inner edge highlight + 1px border)
--------------------------------------------------------------------------------

type GlassFrameConfig = {
	Size: UDim2,
	Position: UDim2,
	AnchorPoint: Vector2?,
	CornerRadius: UDim?,
	Parent: GuiObject?,
	Theme: ThemePreset?,
	ShadowEnabled: boolean?,
	ShadowLayerCount: number?,
	ShadowSpread: number?,
	ShadowOffsetY: number?,
	BackgroundTransparencyOverride: number?,
	LightweightMode: boolean?,
}

type GlassFrame = {
	Container: Frame,
	GlassSurface: Frame,
	ShadowLayers: { Frame },
	SpecularGradient: UIGradient?,
	InnerEdgeGradient: UIGradient?,
	HighlightGradient: UIGradient?,
	Destroy: () -> (),
}

local function createGlassFrame(config: GlassFrameConfig): GlassFrame
	local theme = config.Theme or LightTheme
	local cornerRadius = config.CornerRadius or UDim.new(0, 16)
	local shadowEnabled = resolve(config.ShadowEnabled, nil, true) :: boolean
	local shadowLayerCount = resolve(config.ShadowLayerCount, nil, 5) :: number
	local shadowSpread = resolve(config.ShadowSpread, nil, theme.ShadowSpread) :: number
	local shadowOffsetY = resolve(config.ShadowOffsetY, nil, theme.ShadowOffsetY) :: number
	local bgTransparency = resolve(config.BackgroundTransparencyOverride, nil, theme.BackgroundTransparency) :: number
	local lightweightMode = resolve(config.LightweightMode, nil, false) :: boolean

	-- Container
	local container = Instance.new("Frame")
	container.Name = "MangoGlassFrame"
	container.Size = config.Size
	container.Position = config.Position
	container.AnchorPoint = config.AnchorPoint or Vector2.new(0, 0)
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0

	-- N-layer graduated shadow (quadratic falloff)
	local layerCount = math.clamp(shadowLayerCount, 1, 12)
	local shadowLayers: { Frame } = {}

	for i = layerCount, 1, -1 do
		local t = i / layerCount
		local spread = math.ceil(shadowSpread * t)
		local layerAlpha = (1 - theme.ShadowTransparency)
			* ((layerCount - i + 1) / layerCount) ^ 2
			/ (layerCount / 3)
		local layerTransparency = math.clamp(1 - layerAlpha, 0, 1)
		local cornerRadiusOffset = math.ceil(8 * t)

		local shadowLayer = Instance.new("Frame")
		shadowLayer.Name = "ShadowLayer" .. i
		shadowLayer.AnchorPoint = Vector2.new(0.5, 0.5)
		shadowLayer.Position = UDim2.new(0.5, theme.ShadowOffsetX, 0.5, shadowOffsetY)
		shadowLayer.Size = UDim2.new(1, spread * 2, 1, spread * 2)
		shadowLayer.BackgroundColor3 = theme.ShadowColor
		shadowLayer.BackgroundTransparency = layerTransparency
		shadowLayer.BorderSizePixel = 0
		shadowLayer.ZIndex = 0
		shadowLayer.Visible = shadowEnabled
		shadowLayer.Parent = container

		local layerCorner = Instance.new("UICorner")
		layerCorner.CornerRadius = UDim.new(0, cornerRadius.Offset + cornerRadiusOffset)
		layerCorner.Parent = shadowLayer

		table.insert(shadowLayers, shadowLayer)
	end

	-- GlassSurface
	local glassSurface = Instance.new("Frame")
	glassSurface.Name = "GlassSurface"
	glassSurface.Size = UDim2.new(1, 0, 1, 0)
	glassSurface.BackgroundColor3 = theme.BackgroundColor3
	glassSurface.BackgroundTransparency = bgTransparency
	glassSurface.ClipsDescendants = true
	glassSurface.BorderSizePixel = 0
	glassSurface.ZIndex = 1
	glassSurface.Parent = container

	local glassSurfaceCorner = Instance.new("UICorner")
	glassSurfaceCorner.CornerRadius = cornerRadius
	glassSurfaceCorner.Parent = glassSurface

	local surfaceGradient = Instance.new("UIGradient")
	surfaceGradient.Name = "SurfaceGradient"
	surfaceGradient.Rotation = 135 -- Apple's diagonal gradient (top-left to bottom-right)
	surfaceGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(230, 230, 235)),
	})
	surfaceGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.92),
		NumberSequenceKeypoint.new(1, 0.96),
	})
	surfaceGradient.Parent = glassSurface

	local highlightGradientRef: UIGradient? = nil

	if not lightweightMode then
		-- LensGroup
		local lensGroup = Instance.new("CanvasGroup")
		lensGroup.Name = "LensGroup"
		lensGroup.Size = UDim2.new(1, 0, 1, 0)
		lensGroup.GroupColor3 = theme.LensGroupColor3
		lensGroup.GroupTransparency = theme.LensGroupTransparency
		lensGroup.BackgroundTransparency = 1
		lensGroup.BorderSizePixel = 0
		lensGroup.Parent = glassSurface

		local lensCorner = Instance.new("UICorner")
		lensCorner.CornerRadius = cornerRadius
		lensCorner.Parent = lensGroup

		-- TextureGroup
		local textureGroup = Instance.new("CanvasGroup")
		textureGroup.Name = "TextureGroup"
		textureGroup.Size = UDim2.new(1, 0, 1, 0)
		textureGroup.BackgroundTransparency = 1
		textureGroup.BorderSizePixel = 0
		textureGroup.Parent = lensGroup

		local textureCorner = Instance.new("UICorner")
		textureCorner.CornerRadius = cornerRadius
		textureCorner.Parent = textureGroup

		-- NoiseTile
		local noiseTile = Instance.new("ImageLabel")
		noiseTile.Name = "NoiseTile"
		noiseTile.Image = "rbxassetid://4531766211"
		noiseTile.ImageTransparency = 1 - theme.NoiseOpacity
		noiseTile.ScaleType = Enum.ScaleType.Tile
		noiseTile.TileSize = UDim2.new(0.125, 0, 0.125, 0)
		noiseTile.Size = UDim2.new(1, 0, 1, 0)
		noiseTile.BackgroundTransparency = 1
		noiseTile.BorderSizePixel = 0
		noiseTile.Parent = textureGroup

		local noiseCorner = Instance.new("UICorner")
		noiseCorner.CornerRadius = cornerRadius
		noiseCorner.Parent = noiseTile

		-- InnerHighlight
		local innerHighlight = Instance.new("Frame")
		innerHighlight.Name = "InnerHighlight"
		innerHighlight.Size = UDim2.new(1, 0, theme.InnerGlowHeight, 0)
		innerHighlight.Position = UDim2.new(0, 0, 0, 0)
		innerHighlight.BackgroundColor3 = theme.InnerGlowColor
		innerHighlight.BackgroundTransparency = theme.InnerGlowTransparency
		innerHighlight.BorderSizePixel = 0
		innerHighlight.ZIndex = 2
		innerHighlight.Parent = textureGroup

		local highlightCorner = Instance.new("UICorner")
		highlightCorner.CornerRadius = cornerRadius
		highlightCorner.Parent = innerHighlight

		local highlightGradient = Instance.new("UIGradient")
		highlightGradient.Name = "HighlightGradient"
		highlightGradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		})
		highlightGradient.Rotation = 90
		highlightGradient.Parent = innerHighlight
		highlightGradientRef = highlightGradient
	end

	-- Inner edge highlight (full-perimeter inner shadow)
	local innerEdgeFrame = Instance.new("Frame")
	innerEdgeFrame.Name = "InnerEdgeFrame"
	innerEdgeFrame.Size = UDim2.new(1, 0, 1, 0)
	innerEdgeFrame.BackgroundTransparency = 1
	innerEdgeFrame.BorderSizePixel = 0
	innerEdgeFrame.ZIndex = 3
	innerEdgeFrame.Parent = glassSurface

	local innerEdgeCorner = Instance.new("UICorner")
	innerEdgeCorner.CornerRadius = cornerRadius
	innerEdgeCorner.Parent = innerEdgeFrame

	local innerEdgeStroke = Instance.new("UIStroke")
	innerEdgeStroke.Name = "InnerEdgeStroke"
	innerEdgeStroke.Color = theme.InnerEdgeColor
	innerEdgeStroke.Thickness = 1
	innerEdgeStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	innerEdgeStroke.Parent = innerEdgeFrame

	local innerEdgeGradient = Instance.new("UIGradient")
	innerEdgeGradient.Name = "InnerEdgeGradient"
	innerEdgeGradient.Rotation = 90
	innerEdgeGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, theme.InnerEdgeTopTransparency),
		NumberSequenceKeypoint.new(0.5, theme.InnerEdgeMidTransparency),
		NumberSequenceKeypoint.new(1, theme.InnerEdgeBottomTransparency),
	})
	innerEdgeGradient.Parent = innerEdgeStroke

	-- SpecularFrame (outside clip boundary)
	local specularFrame = Instance.new("Frame")
	specularFrame.Name = "SpecularFrame"
	specularFrame.Size = UDim2.new(1, 0, 1, 0)
	specularFrame.BackgroundTransparency = 1
	specularFrame.BorderSizePixel = 0
	specularFrame.ZIndex = 2
	specularFrame.Parent = container

	local specularCorner = Instance.new("UICorner")
	specularCorner.CornerRadius = cornerRadius
	specularCorner.Parent = specularFrame

	local specularStroke = Instance.new("UIStroke")
	specularStroke.Name = "SpecularStroke"
	specularStroke.Color = theme.StrokeColor
	specularStroke.Thickness = theme.StrokeThickness
	specularStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	specularStroke.Parent = specularFrame

	local specularGradient = Instance.new("UIGradient")
	specularGradient.Name = "SpecularGradient"
	specularGradient.Rotation = theme.FresnelAngle
	specularGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, theme.FresnelStartTransparency),
		NumberSequenceKeypoint.new(theme.FresnelMidPoint, theme.FresnelMidTransparency),
		NumberSequenceKeypoint.new(1, theme.FresnelEndTransparency),
	})
	specularGradient.Parent = specularStroke

	if config.Parent then
		container.Parent = config.Parent
	end

	return {
		Container = container,
		GlassSurface = glassSurface,
		ShadowLayers = shadowLayers,
		SpecularGradient = specularGradient,
		InnerEdgeGradient = innerEdgeGradient,
		HighlightGradient = highlightGradientRef,
		Destroy = function()
			container:Destroy()
		end,
	}
end

--------------------------------------------------------------------------------
-- Inline Refraction Proxy (parents to CurrentCamera)
--------------------------------------------------------------------------------

type RefractionState = {
	GlassPart: Part,
	BindingName: string,
	Destroy: () -> (),
}

local refractionDepthCounter = 0
local DEPTH_STEP = 0.003

local function createRefractionProxy(targetGui: GuiObject, theme: ThemePreset): RefractionState
	local bindingName = "MangoRefraction_" .. HttpService:GenerateGUID(false)
	local offsetDepth = 1.5
	refractionDepthCounter += 1
	local adjustedDepth: number = offsetDepth + (refractionDepthCounter * DEPTH_STEP)

	local glassPart = Instance.new("Part")
	glassPart.Name = "MangoRefractionProxy"
	glassPart.Material = Enum.Material.Glass
	glassPart.Transparency = theme.GlassTransparency
	glassPart.Color = theme.GlassColor
	glassPart.Reflectance = theme.GlassReflectance
	glassPart.CanCollide = false
	glassPart.CanQuery = false
	glassPart.CanTouch = false
	glassPart.Anchored = true
	glassPart.CastShadow = false
	glassPart.TopSurface = Enum.SurfaceType.Smooth
	glassPart.BottomSurface = Enum.SurfaceType.Smooth
	local camera = Workspace.CurrentCamera or Workspace:WaitForChild("CurrentCamera")
	glassPart.Parent = camera

	RunService:BindToRenderStep(bindingName, Enum.RenderPriority.Camera.Value + 1, function()
		local cam = Workspace.CurrentCamera
		if not cam then return end

		local viewportSize: Vector2 = cam.ViewportSize
		if viewportSize.X == 0 or viewportSize.Y == 0 then return end

		local absSize: Vector2 = targetGui.AbsoluteSize
		local absPos: Vector2 = targetGui.AbsolutePosition

		-- With IgnoreGuiInset=true, AbsolutePosition is in screen coordinates
		-- where (0,0) = top-left of the entire screen. Camera.ViewportSize is also
		-- the full screen. Use ScreenPointToRay for robust world-space mapping
		-- that avoids all GUI inset ambiguity.
		local centerVpX: number = absPos.X + absSize.X * 0.5
		local centerVpY: number = absPos.Y + absSize.Y * 0.5

		-- Use ScreenPointToRay to get the exact world ray through the GUI center
		local centerRay: Ray = cam:ScreenPointToRay(centerVpX, centerVpY, 0)
		local camForward: Vector3 = cam.CFrame.LookVector
		-- Project along ray to adjustedDepth distance from camera along forward axis
		local t: number = adjustedDepth / camForward:Dot(centerRay.Direction)
		local worldCenter: Vector3 = cam.CFrame.Position + centerRay.Direction * t

		-- Compute part size from corner rays
		local topLeftRay: Ray = cam:ScreenPointToRay(absPos.X, absPos.Y, 0)
		local bottomRightRay: Ray = cam:ScreenPointToRay(absPos.X + absSize.X, absPos.Y + absSize.Y, 0)
		local tTL: number = adjustedDepth / camForward:Dot(topLeftRay.Direction)
		local tBR: number = adjustedDepth / camForward:Dot(bottomRightRay.Direction)
		local worldTL: Vector3 = cam.CFrame.Position + topLeftRay.Direction * tTL
		local worldBR: Vector3 = cam.CFrame.Position + bottomRightRay.Direction * tBR

		-- Measure size in camera-local space
		local localTL: Vector3 = cam.CFrame:PointToObjectSpace(worldTL)
		local localBR: Vector3 = cam.CFrame:PointToObjectSpace(worldBR)
		local partWidth: number = math.abs(localBR.X - localTL.X)
		local partHeight: number = math.abs(localBR.Y - localTL.Y)

		-- 0.05 studs thickness — visible refraction. Inset 3-5% so rectangular
		-- glass edges hide behind the rounded UI corners.
		glassPart.Size = Vector3.new(partWidth * 0.97, partHeight * 0.95, 0.05)

		-- Position part at world center, oriented with camera
		glassPart.CFrame = CFrame.new(worldCenter, worldCenter + cam.CFrame.LookVector)
	end)

	return {
		GlassPart = glassPart,
		BindingName = bindingName,
		Destroy = function()
			pcall(function()
				RunService:UnbindFromRenderStep(bindingName)
			end)
			glassPart:Destroy()
		end,
	}
end

-- Single viewport-wide refraction proxy (replaces per-panel proxies)
local viewportRefractionState: RefractionState? = nil

local function createViewportRefractionProxy(theme: ThemePreset): RefractionState
	local bindingName = "MangoViewportRefraction_" .. HttpService:GenerateGUID(false)
	local offsetDepth = 1.5

	local glassPart = Instance.new("Part")
	glassPart.Name = "MangoViewportRefractionProxy"
	glassPart.Material = Enum.Material.Glass
	glassPart.Transparency = theme.GlassTransparency
	glassPart.Color = theme.GlassColor
	glassPart.Reflectance = theme.GlassReflectance
	glassPart.CanCollide = false
	glassPart.CanQuery = false
	glassPart.CanTouch = false
	glassPart.Anchored = true
	glassPart.CastShadow = false
	glassPart.TopSurface = Enum.SurfaceType.Smooth
	glassPart.BottomSurface = Enum.SurfaceType.Smooth
	local camera = Workspace.CurrentCamera or Workspace:WaitForChild("CurrentCamera")
	glassPart.Parent = camera

	RunService:BindToRenderStep(bindingName, Enum.RenderPriority.Camera.Value + 1, function()
		local cam = Workspace.CurrentCamera
		if not cam then return end

		local viewportSize: Vector2 = cam.ViewportSize
		if viewportSize.X == 0 or viewportSize.Y == 0 then return end

		local fov: number = math.rad(cam.FieldOfView)
		local worldHeight: number = 2 * offsetDepth * math.tan(fov * 0.5)
		local aspectRatio: number = viewportSize.X / viewportSize.Y
		local worldWidth: number = worldHeight * aspectRatio

		glassPart.Size = Vector3.new(worldWidth, worldHeight, 0.05)
		glassPart.CFrame = cam.CFrame * CFrame.new(0, 0, -offsetDepth)
	end)

	return {
		GlassPart = glassPart,
		BindingName = bindingName,
		Destroy = function()
			pcall(function()
				RunService:UnbindFromRenderStep(bindingName)
			end)
			glassPart:Destroy()
		end,
	}
end

--------------------------------------------------------------------------------
-- Inline Liquid Fusion (smooth hover with Back easing + touch support)
--------------------------------------------------------------------------------

type FusionState = {
	Connections: { RBXScriptConnection },
	Destroy: () -> (),
}

local function makeSmoothTweenInfo(duration: number): TweenInfo
	return TweenInfo.new(duration, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, 0)
end

local function createLiquidFusion(target: GuiObject): FusionState
	local bulgeScale = 1.025
	local bulgeDuration = 0.25
	local restoreDuration = 0.3
	local specularShiftOffset = UDim2.new(0.05, 0, 0.05, 0)

	local connections: { RBXScriptConnection } = {}
	local activeTweens: { Tween } = {}

	local function cancelAllTweens()
		for _, tween in activeTweens do
			tween:Cancel()
		end
		table.clear(activeTweens)
	end

	local function trackTween(tween: Tween): Tween
		table.insert(activeTweens, tween)
		return tween
	end

	-- Use UIScale for hover (works correctly inside ClipsDescendants parents)
	local uiScale = Instance.new("UIScale")
	uiScale.Scale = 1
	uiScale.Parent = target

	local specularGradient: UIGradient? = nil
	local specularStroke = target:FindFirstChild("SpecularStroke", true)
	if specularStroke then
		specularGradient = specularStroke:FindFirstChild("SpecularGradient") :: UIGradient?
	end

	local enterConn = target.MouseEnter:Connect(function()
		cancelAllTweens()
		local tweenInfo = makeSmoothTweenInfo(bulgeDuration)
		local scaleTween = TweenService:Create(uiScale, tweenInfo, { Scale = bulgeScale })
		trackTween(scaleTween)
		scaleTween:Play()
		local gradient = specularGradient
		if gradient then
			local gradTween = TweenService:Create(gradient, tweenInfo, {
				Offset = Vector2.new(specularShiftOffset.X.Scale, specularShiftOffset.Y.Scale),
			})
			trackTween(gradTween)
			gradTween:Play()
		end
	end)

	local leaveConn = target.MouseLeave:Connect(function()
		cancelAllTweens()
		local tweenInfo = makeSmoothTweenInfo(restoreDuration)
		local scaleTween = TweenService:Create(uiScale, tweenInfo, { Scale = 1 })
		trackTween(scaleTween)
		scaleTween:Play()
		local gradient = specularGradient
		if gradient then
			local gradTween = TweenService:Create(gradient, tweenInfo, {
				Offset = Vector2.new(0, 0),
			})
			trackTween(gradTween)
			gradTween:Play()
		end
	end)

	table.insert(connections, enterConn)
	table.insert(connections, leaveConn)

	local fusionTouchHitArea: TextButton? = nil
	if UserInputService.TouchEnabled then
		-- Create transparent TextButton for reliable touch input on transparent targets
		local hitBtn = Instance.new("TextButton")
		hitBtn.Name = "FusionTouchHitArea"
		hitBtn.Size = UDim2.new(1, 0, 1, 0)
		hitBtn.BackgroundTransparency = 1
		hitBtn.BorderSizePixel = 0
		hitBtn.Text = ""
		hitBtn.AutoButtonColor = false
		hitBtn.ZIndex = 99
		hitBtn.Parent = target
		fusionTouchHitArea = hitBtn

		local touchBeginConn = hitBtn.InputBegan:Connect(function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.Touch then
				cancelAllTweens()
				local tweenInfo = makeSmoothTweenInfo(bulgeDuration)
				local scaleTween = TweenService:Create(uiScale, tweenInfo, { Scale = bulgeScale })
				trackTween(scaleTween)
				scaleTween:Play()
				local gradient = specularGradient
				if gradient then
					local gradTween = TweenService:Create(gradient, tweenInfo, {
						Offset = Vector2.new(specularShiftOffset.X.Scale, specularShiftOffset.Y.Scale),
					})
					trackTween(gradTween)
					gradTween:Play()
				end
			end
		end)
		local touchEndConn = hitBtn.InputEnded:Connect(function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.Touch then
				cancelAllTweens()
				local tweenInfo = makeSmoothTweenInfo(restoreDuration)
				local scaleTween = TweenService:Create(uiScale, tweenInfo, { Scale = 1 })
				trackTween(scaleTween)
				scaleTween:Play()
				local gradient = specularGradient
				if gradient then
					local gradTween = TweenService:Create(gradient, tweenInfo, {
						Offset = Vector2.new(0, 0),
					})
					trackTween(gradTween)
					gradTween:Play()
				end
			end
		end)
		table.insert(connections, touchBeginConn)
		table.insert(connections, touchEndConn)
	end

	return {
		Connections = connections,
		Destroy = function()
			for _, conn in connections do
				conn:Disconnect()
			end
			table.clear(connections)
			cancelAllTweens()
			uiScale:Destroy()
			if fusionTouchHitArea then
				fusionTouchHitArea:Destroy()
			end
		end,
	}
end

--------------------------------------------------------------------------------
-- Inline Slider constructor (Apple-style, redesigned)
--------------------------------------------------------------------------------

type SliderState = {
	Container: Frame,
	SetValue: (value: number) -> (),
	GetValue: () -> number,
	Destroy: () -> (),
}

local function createSlider(position: UDim2, size: UDim2, anchorPoint: Vector2, theme: ThemePreset, initialValue: number, onChanged: (number) -> (), parent: GuiObject): SliderState
	local currentValue = math.clamp(initialValue, 0, 1)
	local isDragging = false
	local connections: { RBXScriptConnection } = {}
	local activeTweens: { Tween } = {}

	local function cancelAll()
		for _, tw in activeTweens do tw:Cancel() end
		table.clear(activeTweens)
	end

	local function track(tw: Tween): Tween
		table.insert(activeTweens, tw)
		return tw
	end

	local container = Instance.new("Frame")
	container.Name = "MangoSlider"
	container.Size = size
	container.Position = position
	container.AnchorPoint = anchorPoint
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0

	-- Track shadows
	local trackShadow1 = Instance.new("Frame")
	trackShadow1.Name = "TrackShadow1"
	trackShadow1.AnchorPoint = Vector2.new(0.5, 0.5)
	trackShadow1.Position = UDim2.new(0.5, 0, 0.5, 1)
	trackShadow1.Size = UDim2.new(1, 6, 0, 14)
	trackShadow1.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	trackShadow1.BackgroundTransparency = 0.86
	trackShadow1.BorderSizePixel = 0
	trackShadow1.ZIndex = 0
	trackShadow1.Parent = container
	local ts1c = Instance.new("UICorner")
	ts1c.CornerRadius = UDim.new(0, 999)
	ts1c.Parent = trackShadow1

	local trackShadow2 = Instance.new("Frame")
	trackShadow2.Name = "TrackShadow2"
	trackShadow2.AnchorPoint = Vector2.new(0.5, 0.5)
	trackShadow2.Position = UDim2.new(0.5, 0, 0.5, 1)
	trackShadow2.Size = UDim2.new(1, 3, 0, 11)
	trackShadow2.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	trackShadow2.BackgroundTransparency = 0.82
	trackShadow2.BorderSizePixel = 0
	trackShadow2.ZIndex = 0
	trackShadow2.Parent = container
	local ts2c = Instance.new("UICorner")
	ts2c.CornerRadius = UDim.new(0, 999)
	ts2c.Parent = trackShadow2

	-- Track surface (8px tall)
	local trackSurface = Instance.new("Frame")
	trackSurface.Name = "TrackSurface"
	trackSurface.Size = UDim2.new(1, 0, 0, 6)
	trackSurface.Position = UDim2.new(0, 0, 0.5, 0)
	trackSurface.AnchorPoint = Vector2.new(0, 0.5)
	trackSurface.BackgroundColor3 = theme.SliderTrackColor
	trackSurface.BackgroundTransparency = theme.SliderTrackTransparency
	trackSurface.BorderSizePixel = 0
	trackSurface.ZIndex = 1
	trackSurface.ClipsDescendants = true
	trackSurface.Parent = container
	local trkC = Instance.new("UICorner")
	trkC.CornerRadius = UDim.new(0, 999)
	trkC.Parent = trackSurface

	-- Fill
	local fillFrame = Instance.new("Frame")
	fillFrame.Name = "FillFrame"
	fillFrame.Size = UDim2.new(currentValue, 0, 1, 0)
	fillFrame.BackgroundColor3 = theme.SliderFillColor
	fillFrame.BackgroundTransparency = theme.SliderFillTransparency
	fillFrame.BorderSizePixel = 0
	fillFrame.ZIndex = 1
	fillFrame.ClipsDescendants = true
	fillFrame.Parent = trackSurface
	local fillFrameCorner = Instance.new("UICorner")
	fillFrameCorner.CornerRadius = UDim.new(0, 999)
	fillFrameCorner.Parent = fillFrame
	-- FillHighlight
	local fillHighlight = Instance.new("Frame")
	fillHighlight.Name = "FillHighlight"
	fillHighlight.Size = UDim2.new(1, 0, 0.5, 0)
	fillHighlight.Position = UDim2.new(0, 0, 0, 0)
	fillHighlight.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	fillHighlight.BackgroundTransparency = 0.88
	fillHighlight.BorderSizePixel = 0
	fillHighlight.ZIndex = 2
	fillHighlight.Parent = fillFrame
	local fillHGrad = Instance.new("UIGradient")
	fillHGrad.Rotation = 90
	fillHGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	fillHGrad.Parent = fillHighlight

	-- Track specular
	local trkSpec = Instance.new("Frame")
	trkSpec.Size = UDim2.new(1, 0, 1, 0)
	trkSpec.BackgroundTransparency = 1
	trkSpec.BorderSizePixel = 0
	trkSpec.ZIndex = 2
	trkSpec.Parent = trackSurface
	local trkSpecC = Instance.new("UICorner")
	trkSpecC.CornerRadius = UDim.new(0, 999)
	trkSpecC.Parent = trkSpec
	local trkStroke = Instance.new("UIStroke")
	trkStroke.Color = theme.StrokeColor
	trkStroke.Thickness = 1
	trkStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	trkStroke.Parent = trkSpec
	local trkGrad = Instance.new("UIGradient")
	trkGrad.Rotation = 90
	trkGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, theme.FresnelStartTransparency),
		NumberSequenceKeypoint.new(theme.FresnelMidPoint, theme.FresnelMidTransparency),
		NumberSequenceKeypoint.new(1, theme.FresnelEndTransparency),
	})
	trkGrad.Parent = trkStroke

	-- Track inner edge
	local trkInnerEdge = Instance.new("Frame")
	trkInnerEdge.Name = "TrackInnerEdgeFrame"
	trkInnerEdge.Size = UDim2.new(1, 0, 1, 0)
	trkInnerEdge.BackgroundTransparency = 1
	trkInnerEdge.BorderSizePixel = 0
	trkInnerEdge.ZIndex = 3
	trkInnerEdge.Parent = trackSurface
	local trkIEC = Instance.new("UICorner")
	trkIEC.CornerRadius = UDim.new(0, 999)
	trkIEC.Parent = trkInnerEdge
	local trkIEStroke = Instance.new("UIStroke")
	trkIEStroke.Name = "TrackInnerEdgeStroke"
	trkIEStroke.Color = theme.InnerEdgeColor
	trkIEStroke.Thickness = 1
	trkIEStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	trkIEStroke.Parent = trkInnerEdge
	local trkIEGrad = Instance.new("UIGradient")
	trkIEGrad.Name = "TrackInnerEdgeGradient"
	trkIEGrad.Rotation = 90
	trkIEGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, theme.InnerEdgeTopTransparency + 0.20),
		NumberSequenceKeypoint.new(0.5, theme.InnerEdgeMidTransparency + 0.10),
		NumberSequenceKeypoint.new(1, theme.InnerEdgeBottomTransparency),
	})
	trkIEGrad.Parent = trkIEStroke

	-- Thumb container
	local thumbContainer = Instance.new("Frame")
	thumbContainer.Name = "ThumbContainer"
	thumbContainer.Size = UDim2.new(0, 28, 0, 28)
	thumbContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	thumbContainer.Position = UDim2.new(currentValue, 0, 0.5, 0)
	thumbContainer.BackgroundTransparency = 1
	thumbContainer.BorderSizePixel = 0
	thumbContainer.ZIndex = 3
	thumbContainer.Parent = container

	-- Thumb shadow
	local thumbShadow = Instance.new("Frame")
	thumbShadow.Name = "ThumbShadow"
	thumbShadow.AnchorPoint = Vector2.new(0.5, 0.5)
	thumbShadow.Position = UDim2.new(0.5, 0, 0.5, 1)
	thumbShadow.Size = UDim2.new(0, 30, 0, 30)
	thumbShadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	thumbShadow.BackgroundTransparency = 0.85
	thumbShadow.BorderSizePixel = 0
	thumbShadow.ZIndex = 0
	thumbShadow.Parent = thumbContainer
	local thsC = Instance.new("UICorner")
	thsC.CornerRadius = UDim.new(0, 999)
	thsC.Parent = thumbShadow

	-- Thumb surface
	local thumbSurface = Instance.new("Frame")
	thumbSurface.Name = "ThumbSurface"
	thumbSurface.AnchorPoint = Vector2.new(0.5, 0.5)
	thumbSurface.Position = UDim2.new(0.5, 0, 0.5, 0)
	thumbSurface.Size = UDim2.new(0, 28, 0, 28)
	thumbSurface.BackgroundColor3 = theme.SliderThumbColor
	thumbSurface.BorderSizePixel = 0
	thumbSurface.ZIndex = 1
	thumbSurface.Parent = thumbContainer
	local thSurfC = Instance.new("UICorner")
	thSurfC.CornerRadius = UDim.new(0, 999)
	thSurfC.Parent = thumbSurface

	local thumbStroke = Instance.new("UIStroke")
	thumbStroke.Color = Color3.fromRGB(200, 200, 205)
	thumbStroke.Thickness = 0.5
	thumbStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	thumbStroke.Transparency = 0.4
	thumbStroke.Parent = thumbSurface

	local function updateVisual()
		local fraction = currentValue
		-- Edge-snap: prevent sub-pixel rounding artifacts at 0% and 100%
		if fraction >= 0.995 then fraction = 1 end
		if fraction <= 0.005 then fraction = 0 end
		fillFrame.Size = UDim2.new(fraction, 0, 1, 0)
		thumbContainer.Position = UDim2.new(fraction, 0, 0.5, 0)
	end

	local function valueFromX(absX: number): number
		local trackLeft = container.AbsolutePosition.X
		local trackWidth = container.AbsoluteSize.X
		return math.clamp((absX - trackLeft) / trackWidth, 0, 1)
	end

	local function applyValue(newVal: number)
		local old = currentValue
		currentValue = newVal
		updateVisual()
		if old ~= newVal then
			onChanged(newVal)
		end
	end

	local function thumbGrow()
		cancelAll()
		local growInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		track(TweenService:Create(thumbSurface, growInfo, { Size = UDim2.new(0, 34, 0, 34) })):Play()
		track(TweenService:Create(thumbShadow, growInfo, { Size = UDim2.new(0, 38, 0, 38) })):Play()
	end

	local function thumbShrink()
		local shrinkInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		track(TweenService:Create(thumbSurface, shrinkInfo, { Size = UDim2.new(0, 28, 0, 28) })):Play()
		track(TweenService:Create(thumbShadow, shrinkInfo, { Size = UDim2.new(0, 30, 0, 30) })):Play()
	end

	-- TextButton hit areas
	local thumbHitArea = Instance.new("TextButton")
	thumbHitArea.Name = "ThumbHitArea"
	thumbHitArea.Size = UDim2.new(1, 0, 1, 0)
	thumbHitArea.BackgroundTransparency = 1
	thumbHitArea.Text = ""
	thumbHitArea.BorderSizePixel = 0
	thumbHitArea.ZIndex = 100
	thumbHitArea.AutoButtonColor = false
	thumbHitArea.Parent = thumbContainer

	local trackHitArea = Instance.new("TextButton")
	trackHitArea.Name = "TrackHitArea"
	trackHitArea.Size = UDim2.new(1, 0, 0, 16)
	trackHitArea.AnchorPoint = Vector2.new(0, 0.5)
	trackHitArea.Position = UDim2.new(0, 0, 0.5, 0)
	trackHitArea.BackgroundTransparency = 1
	trackHitArea.Text = ""
	trackHitArea.BorderSizePixel = 0
	trackHitArea.ZIndex = 50
	trackHitArea.AutoButtonColor = false
	trackHitArea.Parent = container

	table.insert(connections, thumbHitArea.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			isDragging = true
			thumbGrow()
		end
	end))

	table.insert(connections, trackHitArea.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			isDragging = true
			thumbGrow()
			applyValue(valueFromX(input.Position.X))
		end
	end))

	table.insert(connections, UserInputService.InputChanged:Connect(function(input: InputObject)
		if not isDragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			applyValue(valueFromX(input.Position.X))
		end
	end))

	table.insert(connections, UserInputService.InputEnded:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if isDragging then
				isDragging = false
				thumbShrink()
				local settleInfo = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
				track(TweenService:Create(thumbContainer, settleInfo, {
					Position = UDim2.new(currentValue, 0, 0.5, 0),
				})):Play()
			end
		end
	end))

	container.Parent = parent

	return {
		Container = container,
		SetValue = function(value: number)
			currentValue = math.clamp(value, 0, 1)
			updateVisual()
		end,
		GetValue = function(): number
			return currentValue
		end,
		Destroy = function()
			for _, conn in connections do conn:Disconnect() end
			table.clear(connections)
			cancelAll()
			container:Destroy()
		end,
	}
end

--------------------------------------------------------------------------------
-- Inline Button constructor (glass pill with spring press)
--------------------------------------------------------------------------------

type ButtonState = {
	Container: Frame,
	GlassSurface: Frame,
	Destroy: () -> (),
}

local function createButton(text: string, position: UDim2, anchorPoint: Vector2, theme: ThemePreset, onActivated: () -> (), parent: GuiObject): ButtonState
	local font = Enum.Font.GothamBold
	local textSizeVal = 14
	local textBounds = TextService:GetTextSize(text, textSizeVal, font, Vector2.new(1000, 1000))
	local btnSize = UDim2.new(0, textBounds.X + 28, 0, textBounds.Y + 20)

	local glass = createGlassFrame({
		Size = btnSize,
		Position = position,
		AnchorPoint = anchorPoint,
		CornerRadius = UDim.new(0, 999),
		Theme = theme,
		ShadowEnabled = false,
		Parent = parent,
		BackgroundTransparencyOverride = theme.ButtonBackgroundTransparency,
		LightweightMode = true,
	})

	-- Single clean drop shadow (Apple-style, barely-perceptible soft shadow)
	local btnShadow = Instance.new("Frame")
	btnShadow.Name = "ButtonShadow"
	btnShadow.AnchorPoint = Vector2.new(0.5, 0.5)
	btnShadow.Position = UDim2.new(0.5, 0, 0.5, 2)
	btnShadow.Size = UDim2.new(1, 10, 1, 6)
	btnShadow.BackgroundColor3 = theme.ShadowColor
	btnShadow.BackgroundTransparency = 0.92
	btnShadow.BorderSizePixel = 0
	btnShadow.ZIndex = 0
	btnShadow.Parent = glass.Container
	local btnShadowCorner = Instance.new("UICorner")
	btnShadowCorner.CornerRadius = UDim.new(0, 999)
	btnShadowCorner.Parent = btnShadow

	-- Directional specular on buttons
	local specFrame = glass.Container:FindFirstChild("SpecularFrame")
	if specFrame then
		local specStroke = specFrame:FindFirstChild("SpecularStroke")
		if specStroke then
			local specGrad = specStroke:FindFirstChild("SpecularGradient")
			if specGrad and specGrad:IsA("UIGradient") then
				(specGrad :: UIGradient).Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, theme.FresnelStartTransparency + 0.05),
					NumberSequenceKeypoint.new(theme.FresnelMidPoint, theme.FresnelMidTransparency + 0.05),
					NumberSequenceKeypoint.new(1, theme.FresnelEndTransparency),
				})
			end
		end
	end

	local uiScale = Instance.new("UIScale")
	uiScale.Scale = 1
	uiScale.Parent = glass.Container

	local label = Instance.new("TextLabel")
	label.Name = "ButtonText"
	label.Text = text
	label.Font = font
	label.TextSize = textSizeVal
	label.TextColor3 = theme.PrimaryTextColor
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 1, 0)
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.BorderSizePixel = 0
	label.ZIndex = 10
	label.Parent = glass.GlassSurface

	local pressScale = theme.ButtonPressScale
	local originalBgTransparency = glass.GlassSurface.BackgroundTransparency
	local activeTweens: { Tween } = {}
	local btnConnections: { RBXScriptConnection } = {}
	local isHovering = false

	local function cancelAll()
		for _, tw in activeTweens do tw:Cancel() end
		table.clear(activeTweens)
	end

	local function trackTw(tw: Tween): Tween
		table.insert(activeTweens, tw)
		return tw
	end

	-- Find specular gradient for hover offset shift
	local btnSpecGrad: UIGradient? = nil
	local btnSpecFrame = glass.Container:FindFirstChild("SpecularFrame")
	if btnSpecFrame then
		local btnSpecStroke = btnSpecFrame:FindFirstChild("SpecularStroke")
		if btnSpecStroke then
			local grad = btnSpecStroke:FindFirstChild("SpecularGradient")
			if grad and grad:IsA("UIGradient") then
				btnSpecGrad = grad :: UIGradient
			end
		end
	end

	-- Hover animation (1.04 scale, 0.3s, glass thickens)
	table.insert(btnConnections, glass.Container.MouseEnter:Connect(function()
		isHovering = true
		cancelAll()
		local hoverInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		trackTw(TweenService:Create(uiScale, hoverInfo, { Scale = 1.04 })):Play()
		trackTw(TweenService:Create(glass.GlassSurface, hoverInfo, {
			BackgroundTransparency = math.clamp(originalBgTransparency - 0.03, 0, 1),
		})):Play()
		if btnSpecGrad then
			trackTw(TweenService:Create(btnSpecGrad, hoverInfo, {
				Offset = Vector2.new(0.02, 0.02),
			})):Play()
		end
	end))

	table.insert(btnConnections, glass.Container.MouseLeave:Connect(function()
		isHovering = false
		cancelAll()
		local leaveInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		trackTw(TweenService:Create(uiScale, leaveInfo, { Scale = 1.0 })):Play()
		trackTw(TweenService:Create(glass.GlassSurface, leaveInfo, {
			BackgroundTransparency = originalBgTransparency,
		})):Play()
		if btnSpecGrad then
			trackTw(TweenService:Create(btnSpecGrad, leaveInfo, {
				Offset = Vector2.new(0, 0),
			})):Play()
		end
	end))

	-- TextButton hit area
	local hitArea = Instance.new("TextButton")
	hitArea.Name = "HitArea"
	hitArea.Size = UDim2.new(1, 0, 1, 0)
	hitArea.BackgroundTransparency = 1
	hitArea.Text = ""
	hitArea.BorderSizePixel = 0
	hitArea.ZIndex = 100
	hitArea.AutoButtonColor = false
	hitArea.Parent = glass.GlassSurface

	table.insert(btnConnections, hitArea.MouseButton1Down:Connect(function()
		cancelAll()
		local pressInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		trackTw(TweenService:Create(uiScale, pressInfo, { Scale = pressScale })):Play()
		trackTw(TweenService:Create(glass.GlassSurface, pressInfo, {
			BackgroundTransparency = math.clamp(originalBgTransparency - 0.04, 0, 1),
		})):Play()
		if btnSpecGrad then
			trackTw(TweenService:Create(btnSpecGrad, pressInfo, {
				Offset = Vector2.new(0.06, 0.06),
			})):Play()
		end
	end))

	table.insert(btnConnections, hitArea.MouseButton1Up:Connect(function()
		cancelAll()
		local releaseInfo = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		local releaseScale = if isHovering then 1.04 else 1.0
		local releaseBgTransparency = if isHovering then math.clamp(originalBgTransparency - 0.03, 0, 1) else originalBgTransparency
		trackTw(TweenService:Create(uiScale, releaseInfo, { Scale = releaseScale })):Play()
		trackTw(TweenService:Create(glass.GlassSurface, releaseInfo, {
			BackgroundTransparency = releaseBgTransparency,
		})):Play()
		if btnSpecGrad then
			trackTw(TweenService:Create(btnSpecGrad, releaseInfo, {
				Offset = if isHovering then Vector2.new(0.02, 0.02) else Vector2.new(0, 0),
			})):Play()
		end
		onActivated()
	end))

	return {
		Container = glass.Container,
		GlassSurface = glass.GlassSurface,
		Destroy = function()
			cancelAll()
			for _, conn in btnConnections do conn:Disconnect() end
			table.clear(btnConnections)
			glass.Destroy()
		end,
	}
end

--------------------------------------------------------------------------------
-- Inline BillboardLabel constructor (glass pill over head)
--------------------------------------------------------------------------------

type BillboardLabelState = {
	BillboardGui: BillboardGui,
	Destroy: () -> (),
}

local function createBillboardLabel(targetPart: BasePart, text: string, theme: ThemePreset): BillboardLabelState
	local font = Enum.Font.GothamMedium
	local textSizeVal = 14
	local textBounds = TextService:GetTextSize(text, textSizeVal, font, Vector2.new(500, 100))
	local w = textBounds.X + 28
	local h = textBounds.Y + 14

	local bbGui = Instance.new("BillboardGui")
	bbGui.Name = "MangoBillboardLabel"
	bbGui.Size = UDim2.new(0, w, 0, h)
	bbGui.MaxDistance = 50
	bbGui.StudsOffset = Vector3.new(0, 2.5, 0)
	bbGui.AlwaysOnTop = false
	bbGui.Active = false
	bbGui.ResetOnSpawn = false
	bbGui.Adornee = targetPart
	bbGui.Parent = targetPart

	local containerFrame = Instance.new("Frame")
	containerFrame.Size = UDim2.new(1, 0, 1, 0)
	containerFrame.BackgroundTransparency = 1
	containerFrame.BorderSizePixel = 0
	containerFrame.Parent = bbGui

	-- Softer shadow layers
	local s1 = Instance.new("Frame")
	s1.AnchorPoint = Vector2.new(0.5, 0.5)
	s1.Position = UDim2.new(0.5, 0, 0.5, 1)
	s1.Size = UDim2.new(1, 8, 1, 8)
	s1.BackgroundColor3 = theme.ShadowColor
	s1.BackgroundTransparency = 0.88
	s1.BorderSizePixel = 0
	s1.ZIndex = 0
	s1.Parent = containerFrame
	local s1c = Instance.new("UICorner")
	s1c.CornerRadius = UDim.new(0, 999)
	s1c.Parent = s1

	local s2 = Instance.new("Frame")
	s2.AnchorPoint = Vector2.new(0.5, 0.5)
	s2.Position = UDim2.new(0.5, 0, 0.5, 1.5)
	s2.Size = UDim2.new(1, 5, 1, 5)
	s2.BackgroundColor3 = theme.ShadowColor
	s2.BackgroundTransparency = 0.86
	s2.BorderSizePixel = 0
	s2.ZIndex = 0
	s2.Parent = containerFrame
	local s2c = Instance.new("UICorner")
	s2c.CornerRadius = UDim.new(0, 999)
	s2c.Parent = s2

	-- Glass surface (15% more opaque)
	local bgTransparency = math.clamp(theme.BackgroundTransparency - 0.15, 0, 1)
	local glass = Instance.new("Frame")
	glass.Name = "GlassSurface"
	glass.Size = UDim2.new(1, 0, 1, 0)
	glass.BackgroundColor3 = theme.BackgroundColor3
	glass.BackgroundTransparency = bgTransparency
	glass.ClipsDescendants = true
	glass.BorderSizePixel = 0
	glass.ZIndex = 1
	glass.Parent = containerFrame
	local gc = Instance.new("UICorner")
	gc.CornerRadius = UDim.new(0, 999)
	gc.Parent = glass

	-- Inner highlight
	local innerHL = Instance.new("Frame")
	innerHL.Name = "InnerHighlight"
	innerHL.Size = UDim2.new(1, 0, theme.InnerGlowHeight, 0)
	innerHL.Position = UDim2.new(0, 0, 0, 0)
	innerHL.BackgroundColor3 = theme.InnerGlowColor
	innerHL.BackgroundTransparency = theme.InnerGlowTransparency
	innerHL.BorderSizePixel = 0
	innerHL.ZIndex = 2
	innerHL.Parent = glass
	local innerHLC = Instance.new("UICorner")
	innerHLC.CornerRadius = UDim.new(0, 999)
	innerHLC.Parent = innerHL
	local innerHLGrad = Instance.new("UIGradient")
	innerHLGrad.Name = "HighlightGradient"
	innerHLGrad.Rotation = 90
	innerHLGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	innerHLGrad.Parent = innerHL

	-- Inner edge
	local ie = Instance.new("Frame")
	ie.Size = UDim2.new(1, 0, 1, 0)
	ie.BackgroundTransparency = 1
	ie.BorderSizePixel = 0
	ie.ZIndex = 3
	ie.Parent = glass
	local iec = Instance.new("UICorner")
	iec.CornerRadius = UDim.new(0, 999)
	iec.Parent = ie
	local ies = Instance.new("UIStroke")
	ies.Name = "InnerEdgeStroke"
	ies.Color = theme.InnerEdgeColor
	ies.Thickness = 1
	ies.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	ies.Parent = ie
	local ieg = Instance.new("UIGradient")
	ieg.Name = "InnerEdgeGradient"
	ieg.Rotation = 90
	ieg.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, math.clamp(theme.InnerEdgeTopTransparency + 0.05, 0, 1)),
		NumberSequenceKeypoint.new(0.5, math.clamp(theme.InnerEdgeMidTransparency + 0.03, 0, 1)),
		NumberSequenceKeypoint.new(1, theme.InnerEdgeBottomTransparency),
	})
	ieg.Parent = ies

	-- Text
	local lbl = Instance.new("TextLabel")
	lbl.Text = text
	lbl.Font = font
	lbl.TextSize = textSizeVal
	lbl.TextColor3 = theme.PrimaryTextColor
	lbl.BackgroundTransparency = 1
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.TextXAlignment = Enum.TextXAlignment.Center
	lbl.TextYAlignment = Enum.TextYAlignment.Center
	lbl.BorderSizePixel = 0
	lbl.ZIndex = 10
	lbl.Parent = glass

	-- Specular
	local sf = Instance.new("Frame")
	sf.Size = UDim2.new(1, 0, 1, 0)
	sf.BackgroundTransparency = 1
	sf.BorderSizePixel = 0
	sf.ZIndex = 2
	sf.Parent = containerFrame
	local sfc = Instance.new("UICorner")
	sfc.CornerRadius = UDim.new(0, 999)
	sfc.Parent = sf
	local ss = Instance.new("UIStroke")
	ss.Name = "SpecularStroke"
	ss.Color = theme.StrokeColor
	ss.Thickness = 1
	ss.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	ss.Parent = sf
	local sg = Instance.new("UIGradient")
	sg.Name = "SpecularGradient"
	sg.Rotation = 90
	sg.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, math.clamp(theme.FresnelStartTransparency + 0.03, 0, 1)),
		NumberSequenceKeypoint.new(theme.FresnelMidPoint, math.clamp(theme.FresnelMidTransparency + 0.02, 0, 1)),
		NumberSequenceKeypoint.new(1, theme.FresnelEndTransparency),
	})
	sg.Parent = ss

	return {
		BillboardGui = bbGui,
		Destroy = function()
			bbGui:Destroy()
		end,
	}
end

--------------------------------------------------------------------------------
-- Inline new component constructors (simplified for demo)
--------------------------------------------------------------------------------

-- Segmented Control
type SegmentedControlState = {
	Container: Frame,
	Destroy: () -> (),
}

local function createSegmentedControl(segments: {string}, position: UDim2, anchorPoint: Vector2, theme: ThemePreset, parent: GuiObject): SegmentedControlState
	local segWidth = 80
	local height = 32
	local totalWidth = segWidth * #segments + 4
	local selectedIndex = 1
	local connections: { RBXScriptConnection } = {}
	local activeTweens: { Tween } = {}

	local container = Instance.new("Frame")
	container.Name = "MangoSegmentedControl"
	container.Size = UDim2.new(0, totalWidth, 0, height)
	container.Position = position
	container.AnchorPoint = anchorPoint
	container.BackgroundColor3 = theme.BackgroundColor3
	container.BackgroundTransparency = theme.SegmentedBackgroundTransparency
	container.BorderSizePixel = 0
	container.Parent = parent
	local cc = Instance.new("UICorner")
	cc.CornerRadius = UDim.new(0, 8)
	cc.Parent = container

	-- Selected indicator
	local indicator = Instance.new("Frame")
	indicator.Name = "SelectedIndicator"
	indicator.Size = UDim2.new(0, segWidth - 4, 0, height - 6)
	indicator.Position = UDim2.new(0, 3, 0, 3)
	indicator.BackgroundColor3 = theme.SegmentedSelectedColor
	indicator.BackgroundTransparency = theme.SegmentedSelectedTransparency
	indicator.BorderSizePixel = 0
	indicator.ZIndex = 2
	indicator.Parent = container
	local ic = Instance.new("UICorner")
	ic.CornerRadius = UDim.new(0, 6)
	ic.Parent = indicator

	-- Segment labels
	for i, seg in segments do
		local btn = Instance.new("TextButton")
		btn.Name = "Segment" .. i
		btn.Size = UDim2.new(0, segWidth, 1, 0)
		btn.Position = UDim2.new(0, (i - 1) * segWidth + 2, 0, 0)
		btn.BackgroundTransparency = 1
		btn.Text = seg
		btn.Font = Enum.Font.GothamMedium
		btn.TextSize = 13
		btn.TextColor3 = if i == selectedIndex then theme.PrimaryTextColor else theme.SecondaryTextColor
		btn.BorderSizePixel = 0
		btn.ZIndex = 10
		btn.AutoButtonColor = false
		btn.Parent = container

		table.insert(connections, btn.MouseButton1Click:Connect(function()
			if selectedIndex == i then return end
			selectedIndex = i
			for _, tw in activeTweens do tw:Cancel() end
			table.clear(activeTweens)
			local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			local tw = TweenService:Create(indicator, tweenInfo, {
				Position = UDim2.new(0, (i - 1) * segWidth + 3, 0, 3),
			})
			table.insert(activeTweens, tw)
			tw:Play()
			-- Update text colors
			for _, child in container:GetChildren() do
				if child:IsA("TextButton") then
					local idx = tonumber(child.Name:match("%d+"))
					if idx then
						child.TextColor3 = if idx == i then theme.PrimaryTextColor else theme.SecondaryTextColor
					end
				end
			end
		end))
	end

	return {
		Container = container,
		Destroy = function()
			for _, conn in connections do conn:Disconnect() end
			table.clear(connections)
			for _, tw in activeTweens do tw:Cancel() end
			container:Destroy()
		end,
	}
end

-- Checkbox
type CheckboxState = {
	Container: Frame,
	Destroy: () -> (),
}

local function createCheckbox(labelText: string, position: UDim2, anchorPoint: Vector2, theme: ThemePreset, initialState: boolean, onToggled: (boolean) -> (), parent: GuiObject): CheckboxState
	local checked = initialState
	local connections: { RBXScriptConnection } = {}
	local activeTweens: { Tween } = {}

	local container = Instance.new("Frame")
	container.Name = "MangoCheckbox"
	container.Size = UDim2.new(0, 200, 0, 24)
	container.Position = position
	container.AnchorPoint = anchorPoint
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0
	container.Parent = parent

	-- Checkbox box
	local box = Instance.new("Frame")
	box.Name = "CheckboxBox"
	box.Size = UDim2.new(0, 22, 0, 22)
	box.Position = UDim2.new(0, 0, 0.5, 0)
	box.AnchorPoint = Vector2.new(0, 0.5)
	box.BackgroundColor3 = if checked then theme.CheckboxOnColor else theme.CheckboxOffColor
	box.BackgroundTransparency = 0.1
	box.BorderSizePixel = 0
	box.ZIndex = 1
	box.Parent = container
	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(0, 6)
	bc.Parent = box

	-- Checkmark
	local checkmark = Instance.new("TextLabel")
	checkmark.Name = "Checkmark"
	checkmark.Text = if checked then "✓" else ""
	checkmark.Font = Enum.Font.GothamBold
	checkmark.TextSize = 16
	checkmark.TextColor3 = theme.CheckboxCheckColor
	checkmark.BackgroundTransparency = 1
	checkmark.Size = UDim2.new(1, 0, 1, 0)
	checkmark.TextXAlignment = Enum.TextXAlignment.Center
	checkmark.TextYAlignment = Enum.TextYAlignment.Center
	checkmark.BorderSizePixel = 0
	checkmark.ZIndex = 10
	checkmark.Parent = box

	-- Label
	local lbl = Instance.new("TextLabel")
	lbl.Text = labelText
	lbl.Font = Enum.Font.Gotham
	lbl.TextSize = 14
	lbl.TextColor3 = theme.PrimaryTextColor
	lbl.BackgroundTransparency = 1
	lbl.Size = UDim2.new(1, -30, 1, 0)
	lbl.Position = UDim2.new(0, 30, 0, 0)
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.TextYAlignment = Enum.TextYAlignment.Center
	lbl.BorderSizePixel = 0
	lbl.ZIndex = 10
	lbl.Parent = container

	-- Hit area
	local hit = Instance.new("TextButton")
	hit.Size = UDim2.new(1, 0, 1, 0)
	hit.BackgroundTransparency = 1
	hit.Text = ""
	hit.ZIndex = 100
	hit.AutoButtonColor = false
	hit.Parent = container

	table.insert(connections, hit.MouseButton1Click:Connect(function()
		checked = not checked
		for _, tw in activeTweens do tw:Cancel() end
		table.clear(activeTweens)
		local info = TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		local tw = TweenService:Create(box, info, {
			BackgroundColor3 = if checked then theme.CheckboxOnColor else theme.CheckboxOffColor,
		})
		table.insert(activeTweens, tw)
		tw:Play()
		checkmark.Text = if checked then "✓" else ""
		onToggled(checked)
	end))

	return {
		Container = container,
		Destroy = function()
			for _, conn in connections do conn:Disconnect() end
			for _, tw in activeTweens do tw:Cancel() end
			container:Destroy()
		end,
	}
end

-- Progress Bar
type ProgressBarState = {
	Container: Frame,
	TrackSurface: Frame?,
	SetValue: (number) -> (),
	Destroy: () -> (),
}

local function createProgressBar(position: UDim2, size: UDim2, anchorPoint: Vector2, theme: ThemePreset, initialValue: number, parent: GuiObject): ProgressBarState
	local strokeColor = resolve(nil, theme.StrokeColor, Color3.fromRGB(255, 255, 255)) :: Color3
	local fresnelStart = resolve(nil, theme.FresnelStartTransparency, 0.30) :: number
	local fresnelMid = resolve(nil, theme.FresnelMidTransparency, 0.55) :: number
	local fresnelMidPoint = resolve(nil, theme.FresnelMidPoint, 0.35) :: number
	local fresnelEnd = resolve(nil, theme.FresnelEndTransparency, 0.95) :: number
	local innerEdgeColor = resolve(nil, theme.InnerEdgeColor, Color3.fromRGB(255, 255, 255)) :: Color3
	local innerEdgeTop = resolve(nil, theme.InnerEdgeTopTransparency, 0.35) :: number
	local innerEdgeMid = resolve(nil, theme.InnerEdgeMidTransparency, 0.72) :: number
	local innerEdgeBottom = resolve(nil, theme.InnerEdgeBottomTransparency, 0.92) :: number

	local container = Instance.new("Frame")
	container.Name = "MangoProgressBar"
	container.Size = size
	container.Position = position
	container.AnchorPoint = anchorPoint
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0
	container.Parent = parent

	-- TrackShadow1 (outer)
	local trackShadow1 = Instance.new("Frame")
	trackShadow1.Name = "TrackShadow1"
	trackShadow1.AnchorPoint = Vector2.new(0.5, 0.5)
	trackShadow1.Position = UDim2.new(0.5, 0, 0.5, 1)
	trackShadow1.Size = UDim2.new(1, 6, 0, 14)
	trackShadow1.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	trackShadow1.BackgroundTransparency = 0.86
	trackShadow1.BorderSizePixel = 0
	trackShadow1.ZIndex = 0
	trackShadow1.Parent = container
	local ts1c = Instance.new("UICorner")
	ts1c.CornerRadius = UDim.new(0, 999)
	ts1c.Parent = trackShadow1

	-- TrackShadow2 (inner)
	local trackShadow2 = Instance.new("Frame")
	trackShadow2.Name = "TrackShadow2"
	trackShadow2.AnchorPoint = Vector2.new(0, 0.5)
	trackShadow2.Position = UDim2.new(0, -1.5, 0.5, 0.5)
	trackShadow2.Size = UDim2.new(1, 3, 0, 11)
	trackShadow2.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	trackShadow2.BackgroundTransparency = 0.82
	trackShadow2.BorderSizePixel = 0
	trackShadow2.ZIndex = 0
	trackShadow2.Parent = container
	local ts2c = Instance.new("UICorner")
	ts2c.CornerRadius = UDim.new(0, 999)
	ts2c.Parent = trackShadow2

	-- TrackSurface (6px glass pill)
	local trackSurface = Instance.new("Frame")
	trackSurface.Name = "TrackSurface"
	trackSurface.Size = UDim2.new(1, 0, 0, 6)
	trackSurface.Position = UDim2.new(0, 0, 0.5, 0)
	trackSurface.AnchorPoint = Vector2.new(0, 0.5)
	trackSurface.BackgroundColor3 = theme.BackgroundColor3
	trackSurface.BackgroundTransparency = theme.ProgressBarTrackTransparency
	trackSurface.ClipsDescendants = true
	trackSurface.BorderSizePixel = 0
	trackSurface.ZIndex = 1
	trackSurface.Parent = container
	local tsc = Instance.new("UICorner")
	tsc.CornerRadius = UDim.new(0, 999)
	tsc.Parent = trackSurface

	-- Edge-snap helper
	local function snapFraction(v: number): number
		if v < 0.005 then return 0 end
		if v > 0.995 then return 1 end
		return v
	end

	-- FillFrame
	local clamped = snapFraction(math.clamp(initialValue, 0, 1))
	local fillFrame = Instance.new("Frame")
	fillFrame.Name = "FillFrame"
	fillFrame.Size = UDim2.new(clamped, 0, 1, 0)
	fillFrame.Position = UDim2.new(0, 0, 0, 0)
	fillFrame.AnchorPoint = Vector2.new(0, 0)
	fillFrame.BackgroundColor3 = theme.ProgressBarFillColor
	fillFrame.BackgroundTransparency = theme.ProgressBarFillTransparency
	fillFrame.BorderSizePixel = 0
	fillFrame.ZIndex = 1
	fillFrame.ClipsDescendants = true
	fillFrame.Parent = trackSurface
	local ffc = Instance.new("UICorner")
	ffc.CornerRadius = UDim.new(0, 999)
	ffc.Parent = fillFrame

	-- FillHighlight (50% height, white, top→bottom gradient)
	local fillHighlight = Instance.new("Frame")
	fillHighlight.Name = "FillHighlight"
	fillHighlight.Size = UDim2.new(1, 0, 0.5, 0)
	fillHighlight.Position = UDim2.new(0, 0, 0, 0)
	fillHighlight.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	fillHighlight.BackgroundTransparency = 0.88
	fillHighlight.BorderSizePixel = 0
	fillHighlight.ZIndex = 2
	fillHighlight.Parent = fillFrame
	local fhGrad = Instance.new("UIGradient")
	fhGrad.Rotation = 90
	fhGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	fhGrad.Parent = fillHighlight

	-- TrackSpecularFrame + UIStroke + UIGradient (3-keypoint fresnel)
	local trackSpecFrame = Instance.new("Frame")
	trackSpecFrame.Name = "TrackSpecularFrame"
	trackSpecFrame.Size = UDim2.new(1, 0, 1, 0)
	trackSpecFrame.BackgroundTransparency = 1
	trackSpecFrame.BorderSizePixel = 0
	trackSpecFrame.ZIndex = 2
	trackSpecFrame.Parent = trackSurface
	local tsCorner = Instance.new("UICorner")
	tsCorner.CornerRadius = UDim.new(0, 999)
	tsCorner.Parent = trackSpecFrame

	local trackSpecStroke = Instance.new("UIStroke")
	trackSpecStroke.Name = "SpecularStroke"
	trackSpecStroke.Color = strokeColor
	trackSpecStroke.Thickness = 1
	trackSpecStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	trackSpecStroke.Parent = trackSpecFrame

	local trackSpecGrad = Instance.new("UIGradient")
	trackSpecGrad.Name = "SpecularGradient"
	trackSpecGrad.Rotation = 90
	trackSpecGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, fresnelStart),
		NumberSequenceKeypoint.new(fresnelMidPoint, fresnelMid),
		NumberSequenceKeypoint.new(1, fresnelEnd),
	})
	trackSpecGrad.Parent = trackSpecStroke

	-- TrackInnerEdgeFrame + UIStroke + UIGradient (inner edge recessed look)
	local trackInnerEdge = Instance.new("Frame")
	trackInnerEdge.Name = "TrackInnerEdgeFrame"
	trackInnerEdge.Size = UDim2.new(1, 0, 1, 0)
	trackInnerEdge.BackgroundTransparency = 1
	trackInnerEdge.BorderSizePixel = 0
	trackInnerEdge.ZIndex = 3
	trackInnerEdge.Parent = trackSurface
	local tieCorner = Instance.new("UICorner")
	tieCorner.CornerRadius = UDim.new(0, 999)
	tieCorner.Parent = trackInnerEdge

	local trackInnerStroke = Instance.new("UIStroke")
	trackInnerStroke.Name = "InnerEdgeStroke"
	trackInnerStroke.Color = innerEdgeColor
	trackInnerStroke.Thickness = 1
	trackInnerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	trackInnerStroke.Parent = trackInnerEdge

	local trackInnerGrad = Instance.new("UIGradient")
	trackInnerGrad.Name = "InnerEdgeGradient"
	trackInnerGrad.Rotation = 90
	trackInnerGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, innerEdgeTop),
		NumberSequenceKeypoint.new(0.5, innerEdgeMid),
		NumberSequenceKeypoint.new(1, innerEdgeBottom),
	})
	trackInnerGrad.Parent = trackInnerStroke

	return {
		Container = container,
		TrackSurface = trackSurface,
		SetValue = function(value: number)
			local v = snapFraction(math.clamp(value, 0, 1))
			local info = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			TweenService:Create(fillFrame, info, { Size = UDim2.new(v, 0, 1, 0) }):Play()
		end,
		Destroy = function()
			container:Destroy()
		end,
	}
end

-- Search Bar
type SearchBarState = {
	Container: Frame,
	Destroy: () -> (),
}

local function createSearchBar(position: UDim2, size: UDim2, anchorPoint: Vector2, placeholder: string, theme: ThemePreset, parent: GuiObject): SearchBarState
	local connections: { RBXScriptConnection } = {}

	local container = Instance.new("Frame")
	container.Name = "MangoSearchBar"
	container.Size = size
	container.Position = position
	container.AnchorPoint = anchorPoint
	container.BackgroundColor3 = theme.BackgroundColor3
	container.BackgroundTransparency = theme.SearchBarBackgroundTransparency
	container.BorderSizePixel = 0
	container.Parent = parent
	local cc = Instance.new("UICorner")
	cc.CornerRadius = UDim.new(0, 10)
	cc.Parent = container

	-- Search icon
	local icon = Instance.new("TextLabel")
	icon.Name = "SearchIcon"
	icon.Text = "Q"
	icon.Font = Enum.Font.GothamBold
	icon.TextSize = 14
	icon.TextColor3 = theme.SearchBarPlaceholderColor
	icon.BackgroundTransparency = 1
	icon.Size = UDim2.new(0, 30, 1, 0)
	icon.Position = UDim2.new(0, 8, 0, 0)
	icon.TextXAlignment = Enum.TextXAlignment.Center
	icon.TextYAlignment = Enum.TextYAlignment.Center
	icon.BorderSizePixel = 0
	icon.ZIndex = 10
	icon.Parent = container

	-- Text box
	local textBox = Instance.new("TextBox")
	textBox.Name = "SearchInput"
	textBox.Size = UDim2.new(1, -44, 1, 0)
	textBox.Position = UDim2.new(0, 38, 0, 0)
	textBox.BackgroundTransparency = 1
	textBox.Text = ""
	textBox.PlaceholderText = placeholder
	textBox.PlaceholderColor3 = theme.SearchBarPlaceholderColor
	textBox.Font = Enum.Font.Gotham
	textBox.TextSize = 14
	textBox.TextColor3 = theme.PrimaryTextColor
	textBox.TextXAlignment = Enum.TextXAlignment.Left
	textBox.ClearTextOnFocus = false
	textBox.BorderSizePixel = 0
	textBox.ZIndex = 10
	textBox.Parent = container

	-- Border stroke
	local stroke = Instance.new("UIStroke")
	stroke.Color = theme.TextFieldBorderColor
	stroke.Thickness = 1
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = container

	table.insert(connections, textBox.Focused:Connect(function()
		TweenService:Create(stroke, TweenInfo.new(0.15), { Color = theme.TextFieldFocusBorderColor }):Play()
	end))
	table.insert(connections, textBox.FocusLost:Connect(function()
		TweenService:Create(stroke, TweenInfo.new(0.15), { Color = theme.TextFieldBorderColor }):Play()
	end))

	return {
		Container = container,
		Destroy = function()
			for _, conn in connections do conn:Disconnect() end
			container:Destroy()
		end,
	}
end

-- Text Field
type TextFieldState = {
	Container: Frame,
	Destroy: () -> (),
}

local function createTextField(position: UDim2, size: UDim2, anchorPoint: Vector2, placeholder: string, theme: ThemePreset, parent: GuiObject): TextFieldState
	local connections: { RBXScriptConnection } = {}

	local container = Instance.new("Frame")
	container.Name = "MangoTextField"
	container.Size = size
	container.Position = position
	container.AnchorPoint = anchorPoint
	container.BackgroundColor3 = theme.BackgroundColor3
	container.BackgroundTransparency = theme.TextFieldBackgroundTransparency
	container.BorderSizePixel = 0
	container.Parent = parent
	local cc = Instance.new("UICorner")
	cc.CornerRadius = UDim.new(0, 8)
	cc.Parent = container

	local textBox = Instance.new("TextBox")
	textBox.Name = "TextInput"
	textBox.Size = UDim2.new(1, -16, 1, 0)
	textBox.Position = UDim2.new(0, 8, 0, 0)
	textBox.BackgroundTransparency = 1
	textBox.Text = ""
	textBox.PlaceholderText = placeholder
	textBox.PlaceholderColor3 = theme.SearchBarPlaceholderColor
	textBox.Font = Enum.Font.Gotham
	textBox.TextSize = 14
	textBox.TextColor3 = theme.PrimaryTextColor
	textBox.TextXAlignment = Enum.TextXAlignment.Left
	textBox.ClearTextOnFocus = false
	textBox.BorderSizePixel = 0
	textBox.ZIndex = 10
	textBox.Parent = container

	local stroke = Instance.new("UIStroke")
	stroke.Color = theme.TextFieldBorderColor
	stroke.Thickness = 1
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = container

	table.insert(connections, textBox.Focused:Connect(function()
		TweenService:Create(stroke, TweenInfo.new(0.15), { Color = theme.TextFieldFocusBorderColor }):Play()
	end))
	table.insert(connections, textBox.FocusLost:Connect(function()
		TweenService:Create(stroke, TweenInfo.new(0.15), { Color = theme.TextFieldBorderColor }):Play()
	end))

	return {
		Container = container,
		Destroy = function()
			for _, conn in connections do conn:Disconnect() end
			container:Destroy()
		end,
	}
end

-- Dropdown
type DropdownState = {
	Container: Frame,
	Display: Frame?,
	Destroy: () -> (),
}

local function createDropdown(items: {string}, position: UDim2, size: UDim2, anchorPoint: Vector2, theme: ThemePreset, parent: GuiObject): DropdownState
	local selectedIndex = 1
	local isOpen = false
	local connections: { RBXScriptConnection } = {}
	local activeTweens: { Tween } = {}
	local clickBlocker: TextButton? = nil

	local container = Instance.new("Frame")
	container.Name = "MangoDropdown"
	container.Size = size
	container.Position = position
	container.AnchorPoint = anchorPoint
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0
	container.ZIndex = 20
	container.Parent = parent

	-- Selected display
	local display = Instance.new("Frame")
	display.Name = "Display"
	display.Size = UDim2.new(1, 0, 0, 36)
	display.BackgroundColor3 = theme.BackgroundColor3
	display.BackgroundTransparency = theme.DropdownBackgroundTransparency
	display.BorderSizePixel = 0
	display.ZIndex = 20
	display.Parent = container
	local dc = Instance.new("UICorner")
	dc.CornerRadius = UDim.new(0, 8)
	dc.Parent = display

	local displayLabel = Instance.new("TextLabel")
	displayLabel.Name = "DisplayLabel"
	displayLabel.Text = items[selectedIndex] or ""
	displayLabel.Font = Enum.Font.Gotham
	displayLabel.TextSize = 14
	displayLabel.TextColor3 = theme.PrimaryTextColor
	displayLabel.BackgroundTransparency = 1
	displayLabel.Size = UDim2.new(1, -36, 1, 0)
	displayLabel.Position = UDim2.new(0, 12, 0, 0)
	displayLabel.TextXAlignment = Enum.TextXAlignment.Left
	displayLabel.TextYAlignment = Enum.TextYAlignment.Center
	displayLabel.BorderSizePixel = 0
	displayLabel.ZIndex = 21
	displayLabel.Parent = display

	-- Arrow
	local arrow = Instance.new("TextLabel")
	arrow.Name = "Arrow"
	arrow.Text = "v"
	arrow.Font = Enum.Font.GothamBold
	arrow.TextSize = 12
	arrow.TextColor3 = theme.SecondaryTextColor
	arrow.BackgroundTransparency = 1
	arrow.Size = UDim2.new(0, 24, 1, 0)
	arrow.Position = UDim2.new(1, -28, 0, 0)
	arrow.TextXAlignment = Enum.TextXAlignment.Center
	arrow.TextYAlignment = Enum.TextYAlignment.Center
	arrow.BorderSizePixel = 0
	arrow.ZIndex = 21
	arrow.Parent = display

	-- Dropdown list
	local listFrame = Instance.new("Frame")
	listFrame.Name = "ListFrame"
	listFrame.Size = UDim2.new(1, 0, 0, #items * 32 + 4)
	listFrame.Position = UDim2.new(0, 0, 0, 38)
	listFrame.BackgroundColor3 = theme.BackgroundColor3
	listFrame.BackgroundTransparency = theme.DropdownBackgroundTransparency
	listFrame.BorderSizePixel = 0
	listFrame.Visible = false
	listFrame.ZIndex = 50
	listFrame.ClipsDescendants = true
	listFrame.Parent = container
	local lc = Instance.new("UICorner")
	lc.CornerRadius = UDim.new(0, 8)
	lc.Parent = listFrame

	-- Close dropdown + destroy click blocker
	local function closeDropdown()
		isOpen = false
		listFrame.Visible = false
		if clickBlocker then
			clickBlocker:Destroy()
			clickBlocker = nil
		end
	end

	-- Open dropdown + create click blocker
	local function openDropdown()
		-- Find the ScreenGui ancestor for the click blocker
		local screenGuiParent: Instance? = container
		while screenGuiParent and not screenGuiParent:IsA("ScreenGui") do
			screenGuiParent = screenGuiParent.Parent
		end
		if not screenGuiParent then return end

		isOpen = true
		listFrame.Visible = true

		-- Full-screen click blocker below the dropdown list
		local blocker = Instance.new("TextButton")
		blocker.Name = "DropdownClickBlocker"
		blocker.Size = UDim2.new(1, 0, 1, 0)
		blocker.BackgroundTransparency = 1
		blocker.Text = ""
		blocker.ZIndex = 49
		blocker.AutoButtonColor = false
		blocker.Parent = screenGuiParent
		clickBlocker = blocker

		blocker.MouseButton1Click:Connect(function()
			closeDropdown()
		end)
	end

	for i, item in items do
		local itemBtn = Instance.new("TextButton")
		itemBtn.Name = "Item" .. i
		itemBtn.Size = UDim2.new(1, -4, 0, 32)
		itemBtn.Position = UDim2.new(0, 2, 0, (i - 1) * 32 + 2)
		itemBtn.BackgroundTransparency = 1
		itemBtn.Text = item
		itemBtn.Font = Enum.Font.Gotham
		itemBtn.TextSize = 14
		itemBtn.TextColor3 = theme.PrimaryTextColor
		itemBtn.TextXAlignment = Enum.TextXAlignment.Left
		itemBtn.BorderSizePixel = 0
		itemBtn.ZIndex = 51
		itemBtn.AutoButtonColor = false
		itemBtn.Parent = listFrame
		local ipc = Instance.new("UIPadding")
		ipc.PaddingLeft = UDim.new(0, 12)
		ipc.Parent = itemBtn

		table.insert(connections, itemBtn.MouseEnter:Connect(function()
			itemBtn.BackgroundTransparency = theme.DropdownItemHoverTransparency
			itemBtn.BackgroundColor3 = theme.DropdownItemHoverColor
		end))
		table.insert(connections, itemBtn.MouseLeave:Connect(function()
			itemBtn.BackgroundTransparency = 1
		end))
		table.insert(connections, itemBtn.MouseButton1Click:Connect(function()
			selectedIndex = i
			displayLabel.Text = item
			closeDropdown()
		end))
	end

	-- Toggle hit
	local displayHit = Instance.new("TextButton")
	displayHit.Size = UDim2.new(1, 0, 1, 0)
	displayHit.BackgroundTransparency = 1
	displayHit.Text = ""
	displayHit.ZIndex = 100
	displayHit.AutoButtonColor = false
	displayHit.Parent = display

	table.insert(connections, displayHit.MouseButton1Click:Connect(function()
		if isOpen then
			closeDropdown()
		else
			openDropdown()
		end
	end))

	return {
		Container = container,
		Display = display,
		Destroy = function()
			closeDropdown()
			for _, conn in connections do conn:Disconnect() end
			for _, tw in activeTweens do tw:Cancel() end
			container:Destroy()
		end,
	}
end

-- Dialog
type DialogState = {
	Container: Frame,
	Show: () -> (),
	Dismiss: () -> (),
	Destroy: () -> (),
}

local function createDialog(title: string, message: string, buttons: {{text: string, style: string?, onActivated: (() -> ())?}}, theme: ThemePreset, parent: Instance): DialogState
	local connections: { RBXScriptConnection } = {}
	local activeTweens: { Tween } = {}
	local dismissed = false

	-- Overlay
	local overlay = Instance.new("Frame")
	overlay.Name = "DialogOverlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 1
	overlay.BorderSizePixel = 0
	overlay.ZIndex = 200
	overlay.Visible = false
	overlay.Parent = parent

	-- Dialog container
	local dialog = Instance.new("Frame")
	dialog.Name = "DialogBox"
	dialog.Size = UDim2.new(0, 300, 0, 0)
	dialog.Position = UDim2.new(0.5, 0, 0.5, 0)
	dialog.AnchorPoint = Vector2.new(0.5, 0.5)
	dialog.BackgroundColor3 = theme.BackgroundColor3
	dialog.BackgroundTransparency = theme.DialogBackgroundTransparency
	dialog.BorderSizePixel = 0
	dialog.ZIndex = 201
	dialog.AutomaticSize = Enum.AutomaticSize.Y
	dialog.Parent = overlay
	local dgc = Instance.new("UICorner")
	dgc.CornerRadius = UDim.new(0, 16)
	dgc.Parent = dialog

	local dialogScale = Instance.new("UIScale")
	dialogScale.Scale = 0.8
	dialogScale.Parent = dialog

	-- Content layout
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 8)
	layout.Parent = dialog

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 20)
	padding.PaddingBottom = UDim.new(0, 16)
	padding.PaddingLeft = UDim.new(0, 20)
	padding.PaddingRight = UDim.new(0, 20)
	padding.Parent = dialog

	-- Title
	local titleLbl = Instance.new("TextLabel")
	titleLbl.Name = "Title"
	titleLbl.Text = title
	titleLbl.Font = Enum.Font.GothamBold
	titleLbl.TextSize = 18
	titleLbl.TextColor3 = theme.PrimaryTextColor
	titleLbl.BackgroundTransparency = 1
	titleLbl.Size = UDim2.new(1, 0, 0, 24)
	titleLbl.TextXAlignment = Enum.TextXAlignment.Center
	titleLbl.BorderSizePixel = 0
	titleLbl.LayoutOrder = 1
	titleLbl.ZIndex = 202
	titleLbl.Parent = dialog

	-- Message
	local msgLbl = Instance.new("TextLabel")
	msgLbl.Name = "Message"
	msgLbl.Text = message
	msgLbl.Font = Enum.Font.Gotham
	msgLbl.TextSize = 14
	msgLbl.TextColor3 = theme.SecondaryTextColor
	msgLbl.BackgroundTransparency = 1
	msgLbl.Size = UDim2.new(1, 0, 0, 40)
	msgLbl.TextWrapped = true
	msgLbl.TextXAlignment = Enum.TextXAlignment.Center
	msgLbl.BorderSizePixel = 0
	msgLbl.LayoutOrder = 2
	msgLbl.ZIndex = 202
	msgLbl.Parent = dialog

	-- Separator
	local sep = Instance.new("Frame")
	sep.Size = UDim2.new(1, 0, 0, 1)
	sep.BackgroundColor3 = theme.TextFieldBorderColor
	sep.BackgroundTransparency = 0.5
	sep.BorderSizePixel = 0
	sep.LayoutOrder = 3
	sep.ZIndex = 202
	sep.Parent = dialog

	-- Buttons
	local btnRow = Instance.new("Frame")
	btnRow.Name = "ButtonRow"
	btnRow.Size = UDim2.new(1, 0, 0, 44)
	btnRow.BackgroundTransparency = 1
	btnRow.BorderSizePixel = 0
	btnRow.LayoutOrder = 4
	btnRow.ZIndex = 202
	btnRow.Parent = dialog

	local btnLayout = Instance.new("UIListLayout")
	btnLayout.FillDirection = Enum.FillDirection.Horizontal
	btnLayout.SortOrder = Enum.SortOrder.LayoutOrder
	btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	btnLayout.Padding = UDim.new(0, 1)
	btnLayout.Parent = btnRow

	local dismissFn: () -> ()

	for i, btnConfig in buttons do
		local btnFrame = Instance.new("TextButton")
		btnFrame.Name = "DialogBtn" .. i
		btnFrame.Size = UDim2.new(0, math.floor(260 / #buttons), 0, 44)
		btnFrame.BackgroundTransparency = 1
		btnFrame.Text = btnConfig.text
		btnFrame.Font = if btnConfig.style == "cancel" then Enum.Font.Gotham else Enum.Font.GothamBold
		btnFrame.TextSize = 16
		btnFrame.TextColor3 = if btnConfig.style == "destructive" then Color3.fromRGB(255, 59, 48) else theme.DropdownItemHoverColor
		btnFrame.BorderSizePixel = 0
		btnFrame.LayoutOrder = i
		btnFrame.ZIndex = 203
		btnFrame.AutoButtonColor = false
		btnFrame.Parent = btnRow

		table.insert(connections, btnFrame.MouseButton1Click:Connect(function()
			if btnConfig.onActivated then
				btnConfig.onActivated()
			end
			dismissFn()
		end))
	end

	local function show()
		dismissed = false
		overlay.Visible = true
		overlay.BackgroundTransparency = 1
		dialogScale.Scale = 0.8
		local fadeInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local tw1 = TweenService:Create(overlay, fadeInfo, { BackgroundTransparency = theme.DialogOverlayTransparency })
		table.insert(activeTweens, tw1)
		tw1:Play()
		local scaleInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		local tw2 = TweenService:Create(dialogScale, scaleInfo, { Scale = 1 })
		table.insert(activeTweens, tw2)
		tw2:Play()
	end

	dismissFn = function()
		if dismissed then return end
		dismissed = true
		local fadeInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		local tw1 = TweenService:Create(overlay, fadeInfo, { BackgroundTransparency = 1 })
		local tw2 = TweenService:Create(dialogScale, fadeInfo, { Scale = 0.8 })
		table.insert(activeTweens, tw1)
		table.insert(activeTweens, tw2)
		tw1:Play()
		tw2:Play()
		tw1.Completed:Connect(function()
			overlay.Visible = false
		end)
	end

	-- Tap overlay to dismiss
	local overlayHit = Instance.new("TextButton")
	overlayHit.Size = UDim2.new(1, 0, 1, 0)
	overlayHit.BackgroundTransparency = 1
	overlayHit.Text = ""
	overlayHit.ZIndex = 200
	overlayHit.AutoButtonColor = false
	overlayHit.Parent = overlay
	table.insert(connections, overlayHit.MouseButton1Click:Connect(function()
		dismissFn()
	end))

	return {
		Container = overlay,
		Show = show,
		Dismiss = dismissFn,
		Destroy = function()
			for _, conn in connections do conn:Disconnect() end
			for _, tw in activeTweens do tw:Cancel() end
			overlay:Destroy()
		end,
	}
end

-- Action Sheet
type ActionSheetState = {
	Container: Frame,
	Show: () -> (),
	Dismiss: () -> (),
	Destroy: () -> (),
}

local function createActionSheet(title: string, actions: {{text: string, style: string?, onActivated: (() -> ())?}}, cancelText: string, theme: ThemePreset, parent: Instance): ActionSheetState
	local connections: { RBXScriptConnection } = {}
	local activeTweens: { Tween } = {}
	local dismissed = false

	local overlay = Instance.new("Frame")
	overlay.Name = "ActionSheetOverlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 1
	overlay.BorderSizePixel = 0
	overlay.ZIndex = 200
	overlay.Visible = false
	overlay.Parent = parent

	local sheetHeight = (#actions + 1) * 48 + 60 + 16
	local sheet = Instance.new("Frame")
	sheet.Name = "ActionSheet"
	sheet.Size = UDim2.new(0, 340, 0, sheetHeight)
	sheet.Position = UDim2.new(0.5, 0, 1, sheetHeight)
	sheet.AnchorPoint = Vector2.new(0.5, 1)
	sheet.BackgroundColor3 = theme.BackgroundColor3
	sheet.BackgroundTransparency = theme.DialogBackgroundTransparency
	sheet.BorderSizePixel = 0
	sheet.ZIndex = 201
	sheet.Parent = overlay
	local sc = Instance.new("UICorner")
	sc.CornerRadius = UDim.new(0, 16)
	sc.Parent = sheet

	-- Title
	local titleLbl = Instance.new("TextLabel")
	titleLbl.Text = title
	titleLbl.Font = Enum.Font.GothamBold
	titleLbl.TextSize = 14
	titleLbl.TextColor3 = theme.SecondaryTextColor
	titleLbl.BackgroundTransparency = 1
	titleLbl.Size = UDim2.new(1, 0, 0, 40)
	titleLbl.TextXAlignment = Enum.TextXAlignment.Center
	titleLbl.TextYAlignment = Enum.TextYAlignment.Center
	titleLbl.BorderSizePixel = 0
	titleLbl.ZIndex = 202
	titleLbl.Parent = sheet

	local dismissFn: () -> ()

	-- Action buttons
	for i, action in actions do
		local sep = Instance.new("Frame")
		sep.Size = UDim2.new(1, -16, 0, 1)
		sep.Position = UDim2.new(0, 8, 0, 40 + (i - 1) * 48)
		sep.BackgroundColor3 = theme.TextFieldBorderColor
		sep.BackgroundTransparency = 0.5
		sep.BorderSizePixel = 0
		sep.ZIndex = 202
		sep.Parent = sheet

		local actionBtn = Instance.new("TextButton")
		actionBtn.Name = "Action" .. i
		actionBtn.Size = UDim2.new(1, 0, 0, 48)
		actionBtn.Position = UDim2.new(0, 0, 0, 40 + (i - 1) * 48)
		actionBtn.BackgroundTransparency = 1
		actionBtn.Text = action.text
		actionBtn.Font = Enum.Font.Gotham
		actionBtn.TextSize = 17
		actionBtn.TextColor3 = if action.style == "destructive" then Color3.fromRGB(255, 59, 48) else theme.DropdownItemHoverColor
		actionBtn.BorderSizePixel = 0
		actionBtn.ZIndex = 203
		actionBtn.AutoButtonColor = false
		actionBtn.Parent = sheet

		table.insert(connections, actionBtn.MouseButton1Click:Connect(function()
			if action.onActivated then
				action.onActivated()
			end
			dismissFn()
		end))
	end

	-- Cancel separator
	local cancelSep = Instance.new("Frame")
	cancelSep.Size = UDim2.new(1, 0, 0, 8)
	cancelSep.Position = UDim2.new(0, 0, 0, 40 + #actions * 48)
	cancelSep.BackgroundTransparency = 1
	cancelSep.BorderSizePixel = 0
	cancelSep.ZIndex = 202
	cancelSep.Parent = sheet

	-- Cancel button
	local cancelBtn = Instance.new("TextButton")
	cancelBtn.Name = "Cancel"
	cancelBtn.Size = UDim2.new(1, 0, 0, 48)
	cancelBtn.Position = UDim2.new(0, 0, 0, 48 + #actions * 48)
	cancelBtn.BackgroundTransparency = 1
	cancelBtn.Text = cancelText
	cancelBtn.Font = Enum.Font.GothamBold
	cancelBtn.TextSize = 17
	cancelBtn.TextColor3 = theme.DropdownItemHoverColor
	cancelBtn.BorderSizePixel = 0
	cancelBtn.ZIndex = 203
	cancelBtn.AutoButtonColor = false
	cancelBtn.Parent = sheet

	local function show()
		dismissed = false
		overlay.Visible = true
		overlay.BackgroundTransparency = 1
		sheet.Position = UDim2.new(0.5, 0, 1, sheetHeight)
		local fadeInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local tw1 = TweenService:Create(overlay, fadeInfo, { BackgroundTransparency = theme.DialogOverlayTransparency })
		table.insert(activeTweens, tw1)
		tw1:Play()
		local slideInfo = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		local tw2 = TweenService:Create(sheet, slideInfo, { Position = UDim2.new(0.5, 0, 1, -16) })
		table.insert(activeTweens, tw2)
		tw2:Play()
	end

	dismissFn = function()
		if dismissed then return end
		dismissed = true
		local fadeInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		local tw1 = TweenService:Create(overlay, fadeInfo, { BackgroundTransparency = 1 })
		local tw2 = TweenService:Create(sheet, fadeInfo, { Position = UDim2.new(0.5, 0, 1, sheetHeight) })
		table.insert(activeTweens, tw1)
		table.insert(activeTweens, tw2)
		tw1:Play()
		tw2:Play()
		tw1.Completed:Connect(function()
			overlay.Visible = false
		end)
	end

	table.insert(connections, cancelBtn.MouseButton1Click:Connect(function()
		dismissFn()
	end))

	-- Tap overlay to dismiss
	local overlayHit = Instance.new("TextButton")
	overlayHit.Size = UDim2.new(1, 0, 1, 0)
	overlayHit.BackgroundTransparency = 1
	overlayHit.Text = ""
	overlayHit.ZIndex = 200
	overlayHit.AutoButtonColor = false
	overlayHit.Parent = overlay
	table.insert(connections, overlayHit.MouseButton1Click:Connect(function()
		dismissFn()
	end))

	return {
		Container = overlay,
		Show = show,
		Dismiss = dismissFn,
		Destroy = function()
			for _, conn in connections do conn:Disconnect() end
			for _, tw in activeTweens do tw:Cancel() end
			overlay:Destroy()
		end,
	}
end


--------------------------------------------------------------------------------
-- Background Scene (colorful 3D Parts to showcase glass transparency)
--------------------------------------------------------------------------------

local backgroundParts: { Part } = {}

local function createBackgroundScene()
	local colors = {
		Color3.fromRGB(255, 100, 120),
		Color3.fromRGB(100, 180, 255),
		Color3.fromRGB(120, 255, 160),
		Color3.fromRGB(255, 200, 80),
		Color3.fromRGB(200, 120, 255),
		Color3.fromRGB(255, 150, 50),
	}

	local positions = {
		Vector3.new(0, 5, -20),
		Vector3.new(-12, 8, -25),
		Vector3.new(12, 3, -18),
		Vector3.new(-6, 12, -30),
		Vector3.new(8, 10, -22),
		Vector3.new(0, 0, -15),
	}

	local sizes = {
		Vector3.new(6, 6, 6),
		Vector3.new(4, 8, 4),
		Vector3.new(5, 5, 10),
		Vector3.new(8, 3, 3),
		Vector3.new(3, 10, 3),
		Vector3.new(10, 2, 6),
	}

	for i = 1, #colors do
		local part = Instance.new("Part")
		part.Name = "MangoScenePart_" .. i
		part.Size = sizes[i]
		part.Position = positions[i]
		part.Color = colors[i]
		part.Material = Enum.Material.Neon
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = false
		part.Parent = Workspace
		table.insert(backgroundParts, part)
	end
end

local function destroyBackgroundScene()
	for _, part in backgroundParts do
		part:Destroy()
	end
	table.clear(backgroundParts)
end

--------------------------------------------------------------------------------
-- Demo State
--------------------------------------------------------------------------------

local currentThemeIndex: number = 1
local currentTheme: ThemePreset = LightTheme

local screenGui: ScreenGui? = nil
local glassFrames: { GlassFrame } = {}
local refractionStates: { RefractionState } = {}
local fusionStates: { FusionState } = {}
local sliderState: SliderState? = nil
local buttonStates: { ButtonState } = {}
local billboardLabels: { BillboardLabelState } = {}
local labelsEnabled = false
local componentStates: { { Destroy: () -> () } } = {}
local panelConnections: { RBXScriptConnection } = {}
local panelScaleMap: { [Frame]: { panelScale: UIScale, activeScaleTween: Tween? } } = {}
local isResizing: boolean = false
local isThemeSwitching: boolean = false
local isUIVisible: boolean = true

-- Dynamic lighting state
local lightAngle: number = 90
local isSpinning: boolean = false
local spinConnection: RBXScriptConnection? = nil
local envLightEnabled: boolean = false
local envLightConnection: RBXScriptConnection? = nil

-- Environment lighting registration (tracks original colors for proper restore)
local envLightRegisteredFrames: {{glass: GlassFrame, originalBgColor: Color3, originalStrokeColor: Color3, originalShadowColor: Color3}} = {}

-- Tintable elements for env light (non-glass-frame elements with lower intensity)
local envLightTintableElements: {{element: GuiObject, property: string, originalColor: Color3, intensity: number}} = {}

-- Cached gradient references for updateAllGradientRotations (avoids GetDescendants every frame)
local cachedGradients: {UIGradient} = {}

-- Parallax state
local parallaxConnection: RBXScriptConnection? = nil

-- Notification stacking state
local notificationStack: { { container: Frame, glass: GlassFrame, dismissThread: thread? } } = {}
local notificationCounter: number = 0

-- Dialog/action sheet state
local dialogState: DialogState? = nil
local actionSheetState: ActionSheetState? = nil
local currentTab: number = 1
local tabContentFrames: { Frame } = {}
local carouselIcons: { {
	container: Frame,
	uiScale: UIScale,
	emojiLabel: TextLabel,
	glassBg: Frame,
	iconShadow: Frame,
	iconHighlight: Frame,
	iconStroke: UIStroke,
	activeDot: Frame,
	activeDotScale: UIScale,
	hoverTweens: {Tween},
	isHovering: boolean,
} } = {}
local carouselTrack: Frame? = nil
local carouselDockFrame: Frame? = nil
local carouselConnections: { RBXScriptConnection } = {}
local carouselTweens: { Tween } = {}

-- Carousel scroll state
local isCarouselScrolling: boolean = false
local carouselFocusConn: RBXScriptConnection? = nil
local carouselScrollGen: number = 0
local carouselRubberBandTweens: {Tween} = {}

local function destroyNotificationStack()
	for _, notif in notificationStack do
		if notif.dismissThread then
			task.cancel(notif.dismissThread)
		end
		notif.glass.Destroy()
	end
	table.clear(notificationStack)
end

local function destroyAllUI()
	destroyNotificationStack()

	-- Carousel/tab cleanup
	for _, conn in carouselConnections do conn:Disconnect() end
	table.clear(carouselConnections)
	for _, tw in carouselTweens do tw:Cancel() end
	table.clear(carouselTweens)
	for _, tw in carouselRubberBandTweens do tw:Cancel() end
	table.clear(carouselRubberBandTweens)
	isCarouselScrolling = false
	carouselScrollGen = 0
	if carouselFocusConn then
		carouselFocusConn:Disconnect()
		carouselFocusConn = nil
	end
	carouselDockFrame = nil -- dockGlass destroyed via gui:ClearAllChildren
	table.clear(tabContentFrames)
	for _, iconData in carouselIcons do
		for _, tw in iconData.hoverTweens do tw:Cancel() end
	end
	table.clear(carouselIcons)
	carouselTrack = nil
	currentTab = 1

	if parallaxConnection then
		parallaxConnection:Disconnect()
		parallaxConnection = nil
	end

	if spinConnection then
		spinConnection:Disconnect()
		spinConnection = nil
	end
	if envLightConnection then
		envLightConnection:Disconnect()
		envLightConnection = nil
	end

	for _, fusion in fusionStates do fusion.Destroy() end
	table.clear(fusionStates)

	for _, refraction in refractionStates do refraction.Destroy() end
	table.clear(refractionStates)
	refractionDepthCounter = 0

	if viewportRefractionState then
		viewportRefractionState.Destroy()
		viewportRefractionState = nil
	end

	table.clear(envLightRegisteredFrames)
	table.clear(envLightTintableElements)
	table.clear(cachedGradients)

	for _, glass in glassFrames do glass.Destroy() end
	table.clear(glassFrames)

	if sliderState then
		sliderState.Destroy()
		sliderState = nil
	end

	for _, btn in buttonStates do btn.Destroy() end
	table.clear(buttonStates)

	for _, lbl in billboardLabels do lbl.Destroy() end
	table.clear(billboardLabels)

	for _, comp in componentStates do comp.Destroy() end
	table.clear(componentStates)

	for _, conn in panelConnections do conn:Disconnect() end
	table.clear(panelConnections)
	table.clear(panelScaleMap)
	isResizing = false

	if dialogState then
		dialogState.Destroy()
		dialogState = nil
	end
	if actionSheetState then
		actionSheetState.Destroy()
		actionSheetState = nil
	end
	if screenGui then
		screenGui:Destroy()
		screenGui = nil
	end

	pcall(function() ContextActionService:UnbindAction("MangoBlockScroll") end)
end

local function destroyBillboardLabels()
	for _, lbl in billboardLabels do lbl.Destroy() end
	table.clear(billboardLabels)
	labelsEnabled = false
end

local function createBillboardLabels()
	destroyBillboardLabels()
	labelsEnabled = true
	for _, p in Players:GetPlayers() do
		local character = p.Character
		if character then
			local head = character:FindFirstChild("Head")
			if head and head:IsA("BasePart") then
				local lbl = createBillboardLabel(head, p.DisplayName, currentTheme)
				table.insert(billboardLabels, lbl)
			end
		end
	end
end

--------------------------------------------------------------------------------
-- Dynamic Lighting: update all gradient rotations in the screenGui
--------------------------------------------------------------------------------

local function rebuildGradientCache()
	table.clear(cachedGradients)
	local gui = screenGui
	if not gui then return end
	for _, desc in gui:GetDescendants() do
		if desc:IsA("UIGradient") then
			local name = desc.Name
			if name == "SpecularGradient" or name == "HighlightGradient" or name == "InnerEdgeGradient" then
				table.insert(cachedGradients, desc)
			end
		end
	end
end

local function updateAllGradientRotations(angle: number)
	for _, grad in cachedGradients do
		grad.Rotation = angle
	end
end

--------------------------------------------------------------------------------
-- Notification Stacking System
--------------------------------------------------------------------------------

local function repositionNotificationStack()
	local gui = screenGui
	if not gui then return end
	local theme = currentTheme
	local gap = theme.NotificationStackGap
	local yOffset = 16
	for i, notif in notificationStack do
		local targetPos = UDim2.new(0.5, 0, 0, yOffset)
		local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		TweenService:Create(notif.container, tweenInfo, { Position = targetPos }):Play()
		yOffset = yOffset + notif.container.AbsoluteSize.Y + gap
	end
end

local function dismissNotification(index: number)
	if index < 1 or index > #notificationStack then return end
	local notif = notificationStack[index]
	if notif.dismissThread then
		task.cancel(notif.dismissThread)
		notif.dismissThread = nil
	end
	table.remove(notificationStack, index)
	local slideOutInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	local tw = TweenService:Create(notif.container, slideOutInfo, {
		Position = UDim2.new(0.5, 0, 0, -80),
	})
	tw:Play()
	tw.Completed:Connect(function()
		notif.glass.Destroy()
	end)
	repositionNotificationStack()
end

local function pushNotification(gui: GuiObject, theme: ThemePreset)
	-- Enforce max visible
	local maxVisible = theme.NotificationMaxVisible
	while #notificationStack >= maxVisible do
		dismissNotification(1)
	end

	notificationCounter += 1
	local count = notificationCounter

	local notifGlass = createGlassFrame({
		Size = UDim2.new(0, 380, 0, 76),
		Position = UDim2.new(0.5, 0, 0, -80),
		AnchorPoint = Vector2.new(0.5, 0),
		CornerRadius = UDim.new(0, 20),
		Theme = theme,
		ShadowEnabled = true,
		ShadowLayerCount = 4,
		ShadowOffsetY = 4,
		LightweightMode = true,
		Parent = gui,
	})

	local notifContainer = notifGlass.Container
	notifContainer.ZIndex = 100

	local targetBgTransparency = notifGlass.GlassSurface.BackgroundTransparency
	notifGlass.GlassSurface.BackgroundTransparency = 1

	-- Content
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 14)
	padding.PaddingRight = UDim.new(0, 14)
	padding.PaddingTop = UDim.new(0, 14)
	padding.PaddingBottom = UDim.new(0, 14)
	padding.Parent = notifGlass.GlassSurface

	local hLayout = Instance.new("UIListLayout")
	hLayout.FillDirection = Enum.FillDirection.Horizontal
	hLayout.SortOrder = Enum.SortOrder.LayoutOrder
	hLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	hLayout.Padding = UDim.new(0, 10)
	hLayout.Parent = notifGlass.GlassSurface

	local iconFrame = Instance.new("Frame")
	iconFrame.Name = "IconFrame"
	iconFrame.Size = UDim2.new(0, 36, 0, 36)
	iconFrame.BackgroundColor3 = theme.SliderFillColor
	iconFrame.BackgroundTransparency = 0.3
	iconFrame.BorderSizePixel = 0
	iconFrame.LayoutOrder = 1
	iconFrame.ZIndex = 10
	iconFrame.Parent = notifGlass.GlassSurface
	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(0, 10)
	iconCorner.Parent = iconFrame

	local iconLbl = Instance.new("TextLabel")
	iconLbl.Text = "M"
	iconLbl.Font = Enum.Font.GothamBold
	iconLbl.TextSize = 18
	iconLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	iconLbl.BackgroundTransparency = 1
	iconLbl.Size = UDim2.new(1, 0, 1, 0)
	iconLbl.TextXAlignment = Enum.TextXAlignment.Center
	iconLbl.TextYAlignment = Enum.TextYAlignment.Center
	iconLbl.BorderSizePixel = 0
	iconLbl.ZIndex = 11
	iconLbl.Parent = iconFrame

	local textContainer = Instance.new("Frame")
	textContainer.Name = "TextContainer"
	textContainer.Size = UDim2.new(1, -46, 1, 0)
	textContainer.BackgroundTransparency = 1
	textContainer.BorderSizePixel = 0
	textContainer.LayoutOrder = 2
	textContainer.ZIndex = 10
	textContainer.Parent = notifGlass.GlassSurface

	local vLayout = Instance.new("UIListLayout")
	vLayout.FillDirection = Enum.FillDirection.Vertical
	vLayout.SortOrder = Enum.SortOrder.LayoutOrder
	vLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	vLayout.Padding = UDim.new(0, 2)
	vLayout.Parent = textContainer

	local titleLbl = Instance.new("TextLabel")
	titleLbl.Name = "NotifTitle"
	titleLbl.Text = "Mango Development"
	titleLbl.Font = Enum.Font.GothamBold
	titleLbl.TextSize = 14
	titleLbl.TextColor3 = theme.PrimaryTextColor
	titleLbl.BackgroundTransparency = 1
	titleLbl.Size = UDim2.new(1, 0, 0, 18)
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left
	titleLbl.TextYAlignment = Enum.TextYAlignment.Center
	titleLbl.BorderSizePixel = 0
	titleLbl.LayoutOrder = 1
	titleLbl.ZIndex = 11
	titleLbl.Parent = textContainer

	local bodyLbl = Instance.new("TextLabel")
	bodyLbl.Name = "NotifBody"
	bodyLbl.Text = "Notification #" .. count
	bodyLbl.Font = Enum.Font.Gotham
	bodyLbl.TextSize = 12
	bodyLbl.TextColor3 = theme.SecondaryTextColor
	bodyLbl.BackgroundTransparency = 1
	bodyLbl.Size = UDim2.new(1, 0, 0, 16)
	bodyLbl.TextXAlignment = Enum.TextXAlignment.Left
	bodyLbl.TextYAlignment = Enum.TextYAlignment.Center
	bodyLbl.BorderSizePixel = 0
	bodyLbl.LayoutOrder = 2
	bodyLbl.ZIndex = 11
	bodyLbl.Parent = textContainer

	-- Add to stack
	local entry = {
		container = notifContainer,
		glass = notifGlass,
		dismissThread = nil :: thread?,
	}
	table.insert(notificationStack, entry)

	-- Animate in
	repositionNotificationStack()
	local fadeInInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(notifGlass.GlassSurface, fadeInInfo, {
		BackgroundTransparency = targetBgTransparency,
	}):Play()

	-- Tap to dismiss (parent to Container, NOT GlassSurface — GlassSurface has UIListLayout)
	local hitArea = Instance.new("TextButton")
	hitArea.Name = "NotifHitArea"
	hitArea.Size = UDim2.new(1, 0, 1, 0)
	hitArea.BackgroundTransparency = 1
	hitArea.Text = ""
	hitArea.ZIndex = 101
	hitArea.AutoButtonColor = false
	hitArea.Parent = notifContainer
	hitArea.MouseButton1Click:Connect(function()
		local idx = table.find(notificationStack, entry)
		if idx then
			dismissNotification(idx)
		end
	end)

	-- Auto-dismiss after 5 seconds
	entry.dismissThread = task.delay(5, function()
		entry.dismissThread = nil -- clear before dismiss to avoid task.cancel on running thread
		local idx = table.find(notificationStack, entry)
		if idx then
			dismissNotification(idx)
		end
	end)
end

--------------------------------------------------------------------------------
-- Intro Animation — Spotlight Glass Box
--------------------------------------------------------------------------------

local function playIntroAnimation(onComplete: () -> ())
	local introGui = Instance.new("ScreenGui")
	introGui.Name = "MangoIntro"
	introGui.DisplayOrder = 200
	introGui.ResetOnSpawn = false
	introGui.IgnoreGuiInset = true
	introGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	introGui.Parent = playerGui

	-- Background overlay
	local overlay = Instance.new("Frame")
	overlay.Name = "IntroOverlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 1
	overlay.BorderSizePixel = 0
	overlay.ZIndex = 0
	overlay.Parent = introGui

	-- Center container
	local centerContainer = Instance.new("Frame")
	centerContainer.Name = "IntroCenterContainer"
	centerContainer.Size = UDim2.new(0, 220, 0, 90)
	centerContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
	centerContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	centerContainer.BackgroundTransparency = 1
	centerContainer.BorderSizePixel = 0
	centerContainer.ZIndex = 1
	centerContainer.Parent = introGui

	-- Glass frame (using Mango theme)
	local introGlass = createGlassFrame({
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		CornerRadius = UDim.new(0, 20),
		Theme = MangoTheme,
		ShadowEnabled = true,
		ShadowLayerCount = 4,
		Parent = centerContainer,
	})

	-- 3D Text Layer 1: Back shadow (depth shadow, ZIndex=7)
	local backShadowText = Instance.new("TextLabel")
	backShadowText.Name = "MangoBackShadow"
	backShadowText.Text = "Mango"
	backShadowText.Font = Enum.Font.GothamBold
	backShadowText.TextSize = 35
	backShadowText.TextColor3 = Color3.fromRGB(120, 70, 20)
	backShadowText.TextTransparency = 0.65
	backShadowText.TextStrokeTransparency = 1
	backShadowText.BackgroundTransparency = 1
	backShadowText.Size = UDim2.new(1, 0, 1, 0)
	backShadowText.Position = UDim2.new(0, 2, 0, 2)
	backShadowText.TextXAlignment = Enum.TextXAlignment.Center
	backShadowText.TextYAlignment = Enum.TextYAlignment.Center
	backShadowText.BorderSizePixel = 0
	backShadowText.ZIndex = 7
	backShadowText.Parent = introGlass.GlassSurface

	local backShadowScale = Instance.new("UIScale")
	backShadowScale.Scale = 0.01
	backShadowScale.Parent = backShadowText

	-- 3D Text Layer 2: Glass edge (refraction edge, ZIndex=8)
	local glassEdgeText = Instance.new("TextLabel")
	glassEdgeText.Name = "MangoGlassEdge"
	glassEdgeText.Text = "Mango"
	glassEdgeText.Font = Enum.Font.GothamBold
	glassEdgeText.TextSize = 33
	glassEdgeText.TextColor3 = Color3.fromRGB(255, 230, 170)
	glassEdgeText.TextTransparency = 0.50
	glassEdgeText.TextStrokeTransparency = 1
	glassEdgeText.BackgroundTransparency = 1
	glassEdgeText.Size = UDim2.new(1, 0, 1, 0)
	glassEdgeText.Position = UDim2.new(0, 1, 0, 1)
	glassEdgeText.TextXAlignment = Enum.TextXAlignment.Center
	glassEdgeText.TextYAlignment = Enum.TextYAlignment.Center
	glassEdgeText.BorderSizePixel = 0
	glassEdgeText.ZIndex = 8
	glassEdgeText.Parent = introGlass.GlassSurface

	-- Glass edge gradient (lighter top → darker bottom simulating refraction)
	local glassEdgeGrad = Instance.new("UIGradient")
	glassEdgeGrad.Rotation = 90
	glassEdgeGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 240, 200)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 160, 80)),
	})
	glassEdgeGrad.Parent = glassEdgeText

	local glassEdgeScale = Instance.new("UIScale")
	glassEdgeScale.Scale = 0.01
	glassEdgeScale.Parent = glassEdgeText

	-- "Mango" glow layer (soft amber halo behind main text, ZIndex=9)
	local glowText = Instance.new("TextLabel")
	glowText.Name = "MangoGlowText"
	glowText.Text = "Mango"
	glowText.Font = Enum.Font.GothamBold
	glowText.TextSize = 34
	glowText.TextColor3 = Color3.fromRGB(255, 200, 80)
	glowText.TextTransparency = 0.55
	glowText.TextStrokeTransparency = 1
	glowText.TextStrokeColor3 = Color3.fromRGB(255, 160, 40)
	glowText.BackgroundTransparency = 1
	glowText.Size = UDim2.new(1, 0, 1, 0)
	glowText.TextXAlignment = Enum.TextXAlignment.Center
	glowText.TextYAlignment = Enum.TextYAlignment.Center
	glowText.BorderSizePixel = 0
	glowText.ZIndex = 9
	glowText.Parent = introGlass.GlassSurface

	local glowScale = Instance.new("UIScale")
	glowScale.Scale = 0.01
	glowScale.Parent = glowText

	-- "Mango" main text (warm amber with subtle stroke, ZIndex=10)
	local logoText = Instance.new("TextLabel")
	logoText.Name = "MangoLogoText"
	logoText.Text = "Mango"
	logoText.Font = Enum.Font.GothamBold
	logoText.TextSize = 32
	logoText.TextColor3 = Color3.fromRGB(255, 200, 100)
	logoText.TextStrokeColor3 = Color3.fromRGB(255, 150, 30)
	logoText.TextStrokeTransparency = 0.7
	logoText.BackgroundTransparency = 1
	logoText.Size = UDim2.new(1, 0, 1, 0)
	logoText.TextXAlignment = Enum.TextXAlignment.Center
	logoText.TextYAlignment = Enum.TextYAlignment.Center
	logoText.BorderSizePixel = 0
	logoText.ZIndex = 10
	logoText.Parent = introGlass.GlassSurface

	local logoTextScale = Instance.new("UIScale")
	logoTextScale.Scale = 0.01
	logoTextScale.Parent = logoText

	-- UIScale for container (glass box) scale animation
	local logoScale = Instance.new("UIScale")
	logoScale.Scale = 0.01
	logoScale.Parent = centerContainer

	-- SpotlightFrame1 (rotating beam)
	local spotlightFrame1 = Instance.new("Frame")
	spotlightFrame1.Name = "SpotlightFrame1"
	spotlightFrame1.Size = UDim2.new(1, 0, 1, 0)
	spotlightFrame1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	spotlightFrame1.BackgroundTransparency = 0.70
	spotlightFrame1.BorderSizePixel = 0
	spotlightFrame1.ZIndex = 5
	spotlightFrame1.Parent = centerContainer
	local sf1c = Instance.new("UICorner")
	sf1c.CornerRadius = UDim.new(0, 20)
	sf1c.Parent = spotlightFrame1

	local spotlightGradient = Instance.new("UIGradient")
	spotlightGradient.Name = "SpotlightGradient"
	spotlightGradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
	spotlightGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.35, 1),
		NumberSequenceKeypoint.new(0.45, 0.3),
		NumberSequenceKeypoint.new(0.55, 0.3),
		NumberSequenceKeypoint.new(0.65, 1),
		NumberSequenceKeypoint.new(1, 1),
	})
	spotlightGradient.Rotation = 0
	spotlightGradient.Parent = spotlightFrame1

	-- SpotlightFrame2 (diffusion crossfade)
	local spotlightFrame2 = Instance.new("Frame")
	spotlightFrame2.Name = "SpotlightFrame2"
	spotlightFrame2.Size = UDim2.new(1, 0, 1, 0)
	spotlightFrame2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	spotlightFrame2.BackgroundTransparency = 1
	spotlightFrame2.BorderSizePixel = 0
	spotlightFrame2.ZIndex = 5
	spotlightFrame2.Parent = centerContainer
	local sf2c = Instance.new("UICorner")
	sf2c.CornerRadius = UDim.new(0, 20)
	sf2c.Parent = spotlightFrame2

	local softGlowGradient = Instance.new("UIGradient")
	softGlowGradient.Name = "SoftGlowGradient"
	softGlowGradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
	softGlowGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 0.3),
	})
	softGlowGradient.Parent = spotlightFrame2

	-- Shimmer sweep frame (narrow bright band across glass surface)
	local shimmerFrame = Instance.new("Frame")
	shimmerFrame.Name = "ShimmerFrame"
	shimmerFrame.Size = UDim2.new(1, 0, 1, 0)
	shimmerFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	shimmerFrame.BackgroundTransparency = 0.85
	shimmerFrame.BorderSizePixel = 0
	shimmerFrame.ZIndex = 6
	shimmerFrame.Parent = introGlass.GlassSurface
	local shimmerCorner = Instance.new("UICorner")
	shimmerCorner.CornerRadius = UDim.new(0, 20)
	shimmerCorner.Parent = shimmerFrame
	local shimmerGradient = Instance.new("UIGradient")
	shimmerGradient.Name = "ShimmerGradient"
	shimmerGradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
	shimmerGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.45, 1),
		NumberSequenceKeypoint.new(0.48, 0.2),
		NumberSequenceKeypoint.new(0.52, 0.2),
		NumberSequenceKeypoint.new(0.55, 1),
		NumberSequenceKeypoint.new(1, 1),
	})
	shimmerGradient.Offset = Vector2.new(-0.5, 0)
	shimmerGradient.Parent = shimmerFrame

	-- Play sound
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://129319699633218"
	sound.Volume = 0.8
	sound.Parent = SoundService
	sound:Play()

	-- 0.0s: Overlay fades to 0.55 (gentler dim)
	local overlayFadeIn = TweenService:Create(overlay, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0.55,
	})
	overlayFadeIn:Play()

	-- 0.0s: Container (glass box) scale 0.01→1.0 in 0.55s (Back Out)
	TweenService:Create(logoScale, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()

	-- Staggered 3D text scale bounce:
	-- Back shadow: 0.01→1.0 in 0.6s (Quad Out) — trailing depth
	TweenService:Create(backShadowScale, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	-- Glass edge: 0.01→1.0 in 0.55s (Back Out)
	TweenService:Create(glassEdgeScale, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	-- Glow: 0.01→1.0 in 0.5s (Back Out)
	TweenService:Create(glowScale, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	-- Main text: 0.01→1.02 in 0.5s (Back Out), then 1.02→1.0 in 0.1s (Quad Out) — overshoot bounce
	local mainOvershootTw = TweenService:Create(logoTextScale, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1.02 })
	mainOvershootTw:Play()
	mainOvershootTw.Completed:Connect(function()
		TweenService:Create(logoTextScale, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1.0 }):Play()
	end)

	-- 0.0s: Rotation wobble 0 -> 2 -> 0 (subtler, refined)
	local rotateToInfo = TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	local rotateTo = TweenService:Create(centerContainer, rotateToInfo, { Rotation = 2 })
	rotateTo:Play()
	rotateTo.Completed:Connect(function()
		TweenService:Create(centerContainer, rotateToInfo, { Rotation = 0 }):Play()
	end)

	-- 0.1s: Spotlight rotation 0 -> 360 (single graceful revolution)
	task.delay(0.1, function()
		local spotRotInfo = TweenInfo.new(2.0, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		TweenService:Create(spotlightGradient, spotRotInfo, { Rotation = 360 }):Play()

		-- Sync specular gradient
		local specGrad = introGlass.SpecularGradient
		if specGrad then
			TweenService:Create(specGrad, spotRotInfo, { Rotation = 360 }):Play()
		end
	end)

	-- 0.3s: Glow pulse animation (gentle breathing)
	task.delay(0.3, function()
		local glowPulseInfo = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 1, true)
		TweenService:Create(glowText, glowPulseInfo, { TextTransparency = 0.30 }):Play()
	end)

	-- 0.5s: Shimmer sweep across glass surface
	task.delay(0.5, function()
		local shimmerSweepInfo = TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		TweenService:Create(shimmerGradient, shimmerSweepInfo, { Offset = Vector2.new(0.5, 0) }):Play()
		-- Fade shimmer out after sweep
		task.delay(1.2, function()
			local shimmerFadeInfo = TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
			TweenService:Create(shimmerFrame, shimmerFadeInfo, { BackgroundTransparency = 1 }):Play()
		end)
	end)

	-- 1.2s: Cross-fade spotlight
	task.delay(1.2, function()
		local fadeOutInfo = TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
		TweenService:Create(spotlightFrame1, fadeOutInfo, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(spotlightFrame2, fadeOutInfo, { BackgroundTransparency = 0.85 }):Play()
	end)

	-- 2.0s: Fade out glass + all text layers + overlay (soft exit)
	task.delay(2.0, function()
		local fadeOutInfo = TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
		TweenService:Create(introGlass.GlassSurface, fadeOutInfo, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(logoText, fadeOutInfo, { TextTransparency = 1 }):Play()
		TweenService:Create(glowText, fadeOutInfo, { TextTransparency = 1 }):Play()
		TweenService:Create(backShadowText, fadeOutInfo, { TextTransparency = 1 }):Play()
		TweenService:Create(glassEdgeText, fadeOutInfo, { TextTransparency = 1 }):Play()
		TweenService:Create(overlay, fadeOutInfo, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(spotlightFrame2, fadeOutInfo, { BackgroundTransparency = 1 }):Play()
	end)

	-- 2.5s: Cleanup + callback
	task.delay(2.5, function()
		sound:Destroy()
		introGui:Destroy()
		onComplete()
	end)
end

--------------------------------------------------------------------------------
-- Build the UI
--------------------------------------------------------------------------------

local function buildUI()
	destroyAllUI()

	local theme = currentTheme
	local themeName = themeOrder[currentThemeIndex].name

	local gui = Instance.new("ScreenGui")
	gui.Name = "MangoLiquidUI_Demo"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui
	screenGui = gui

	-- Master container wraps all visible UI for show/hide
	local masterContainer = Instance.new("Frame")
	masterContainer.Name = "MasterContainer"
	masterContainer.Size = UDim2.fromScale(1, 1)
	masterContainer.BackgroundTransparency = 1
	masterContainer.BorderSizePixel = 0
	masterContainer.Parent = gui

	local masterScale = Instance.new("UIScale")
	masterScale.Scale = 1
	masterScale.Parent = masterContainer

	local uiParent: GuiObject = masterContainer

	local updateDockPosition: (() -> ())? = nil

	-- Helper: create panel + fusion + drag + scale
	local function makePanel(size: UDim2, position: UDim2, anchor: Vector2, radius: UDim, shadow: boolean?, layerCount: number?): GlassFrame
		local glass = createGlassFrame({
			Size = size,
			Position = position,
			AnchorPoint = anchor,
			CornerRadius = radius,
			Parent = uiParent,
			Theme = theme,
			ShadowEnabled = shadow,
			ShadowLayerCount = layerCount,
		})
		table.insert(glassFrames, glass)
		local refraction = createRefractionProxy(glass.Container, theme)
		table.insert(refractionStates, refraction)
		local fusion = createLiquidFusion(glass.Container)
		table.insert(fusionStates, fusion)

		-- Left-click drag via transparent TextButton at ZIndex=0 inside GlassSurface
		local dragging = false
		local dragStart: Vector3? = nil
		local startPos: UDim2? = nil

		local dragHitArea = Instance.new("TextButton")
		dragHitArea.Name = "DragHitArea"
		dragHitArea.Size = UDim2.fromScale(1, 1)
		dragHitArea.Position = UDim2.fromScale(0, 0)
		dragHitArea.BackgroundTransparency = 1
		dragHitArea.Text = ""
		dragHitArea.AutoButtonColor = false
		dragHitArea.ZIndex = 0
		dragHitArea.Parent = glass.GlassSurface

		table.insert(panelConnections, dragHitArea.InputBegan:Connect(function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = input.Position
				startPos = glass.Container.Position
			end
		end))

		table.insert(panelConnections, UserInputService.InputEnded:Connect(function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end))

		table.insert(panelConnections, UserInputService.InputChanged:Connect(function(input: InputObject)
			if dragging and not isResizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				if startPos and dragStart then
					local delta = input.Position - dragStart
					glass.Container.Position = UDim2.new(
						startPos.X.Scale, startPos.X.Offset + delta.X,
						startPos.Y.Scale, startPos.Y.Offset + delta.Y
					)
					if updateDockPosition then
						updateDockPosition()
					end
				end
			end
		end))

		-- Register for environment lighting
		table.insert(envLightRegisteredFrames, {
			glass = glass,
			originalBgColor = glass.GlassSurface.BackgroundColor3,
			originalStrokeColor = theme.StrokeColor,
			originalShadowColor = theme.ShadowColor,
		})

		return glass
	end

	-- Helper: add text label
	local function addLabel(parent: Frame, name: string, text: string, font: Enum.Font, textSize: number, color: Color3, size: UDim2, position: UDim2, xAlign: Enum.TextXAlignment?, wrapped: boolean?)
		local label = Instance.new("TextLabel")
		label.Name = name
		label.Text = text
		label.Font = font
		label.TextSize = textSize
		label.TextColor3 = color
		label.BackgroundTransparency = 1
		label.Size = size
		label.Position = position
		label.TextXAlignment = xAlign or Enum.TextXAlignment.Left
		label.TextYAlignment = Enum.TextYAlignment.Top
		label.TextWrapped = wrapped or false
		label.BorderSizePixel = 0
		label.ZIndex = 10
		label.Parent = parent
	end

	-- Helper: make a horizontal button row
	local function makeButtonRow(name: string, parent: GuiObject, position: UDim2): Frame
		local row = Instance.new("Frame")
		row.Name = name
		row.BackgroundTransparency = 1
		row.Size = UDim2.new(1, 0, 0, 50)
		row.Position = position
		row.BorderSizePixel = 0
		row.Parent = parent
		local layout = Instance.new("UIListLayout")
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.Padding = UDim.new(0, 10)
		layout.VerticalAlignment = Enum.VerticalAlignment.Center
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = row
		return row
	end

	-- Helper: make a separator line
	local function makeSeparator(parent: GuiObject, position: UDim2): Frame
		local sep = Instance.new("Frame")
		sep.Name = "Separator"
		sep.Size = UDim2.new(1, -48, 0, 1)
		sep.Position = position
		sep.AnchorPoint = Vector2.new(0, 0)
		sep.BackgroundColor3 = theme.TextFieldBorderColor
		sep.BackgroundTransparency = 0.5
		sep.BorderSizePixel = 0
		sep.ZIndex = 10
		sep.Parent = parent
		return sep
	end

	-- ================================================================
	-- Main Panel (single centered panel, 680x500)
	-- ================================================================
	local mainGlass = makePanel(UDim2.new(0, 680, 0, 500), UDim2.new(0.5, 0, 0.5, 0), Vector2.new(0.5, 0.5), UDim.new(0, 24))

	-- ContentRegion: top area for tab content
	local contentRegion = Instance.new("Frame")
	contentRegion.Name = "ContentRegion"
	contentRegion.Size = UDim2.new(1, 0, 1, -60)
	contentRegion.Position = UDim2.new(0, 0, 0, 0)
	contentRegion.BackgroundTransparency = 1
	contentRegion.BorderSizePixel = 0
	contentRegion.ClipsDescendants = true
	contentRegion.ZIndex = 5
	contentRegion.Parent = mainGlass.GlassSurface

	-- Resize handle constants
	local ORIGINAL_WIDTH = 680
	local ORIGINAL_HEIGHT = 500
	local MIN_WIDTH = 400
	local MIN_HEIGHT = 300
	local MAX_WIDTH = 1200
	local MAX_HEIGHT = 800

	-- Content scaling UIScale
	local contentScale = Instance.new("UIScale")
	contentScale.Scale = 1
	contentScale.Parent = contentRegion

	-- Resize handle at bottom-right corner
	local resizeHandle = Instance.new("TextButton")
	resizeHandle.Name = "ResizeHandle"
	resizeHandle.Size = UDim2.new(0, 20, 0, 20)
	resizeHandle.Position = UDim2.new(1, -20, 1, -20)
	resizeHandle.BackgroundTransparency = 1
	resizeHandle.Text = "\226\140\159"
	resizeHandle.TextColor3 = theme.SecondaryTextColor
	resizeHandle.TextTransparency = 0.5
	resizeHandle.TextSize = 16
	resizeHandle.Font = Enum.Font.GothamBold
	resizeHandle.ZIndex = 50
	resizeHandle.AutoButtonColor = false
	resizeHandle.Parent = mainGlass.Container

	-- Resize hover feedback
	table.insert(panelConnections, resizeHandle.MouseEnter:Connect(function()
		TweenService:Create(resizeHandle, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 0.2 }):Play()
	end))
	table.insert(panelConnections, resizeHandle.MouseLeave:Connect(function()
		if not isResizing then
			TweenService:Create(resizeHandle, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 0.5 }):Play()
		end
	end))

	-- Resize drag logic
	local resizeStart: Vector3? = nil
	local resizeStartSize: Vector2? = nil

	table.insert(panelConnections, resizeHandle.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			isResizing = true
			resizeStart = input.Position
			resizeStartSize = mainGlass.Container.AbsoluteSize
			resizeHandle.TextTransparency = 0.1
		end
	end))

	table.insert(panelConnections, UserInputService.InputEnded:Connect(function(input: InputObject)
		if isResizing and (input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch) then
			isResizing = false
			resizeHandle.TextTransparency = 0.5
		end
	end))

	table.insert(panelConnections, UserInputService.InputChanged:Connect(function(input: InputObject)
		if isResizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			if resizeStart and resizeStartSize then
				local delta = input.Position - resizeStart
				local newW = math.clamp(resizeStartSize.X + delta.X, MIN_WIDTH, MAX_WIDTH)
				local newH = math.clamp(resizeStartSize.Y + delta.Y, MIN_HEIGHT, MAX_HEIGHT)
				mainGlass.Container.Size = UDim2.new(0, newW, 0, newH)
				-- Scale content proportionally
				local scaleX = newW / ORIGINAL_WIDTH
				local scaleY = (newH - 60) / (ORIGINAL_HEIGHT - 60)
				contentScale.Scale = math.min(scaleX, scaleY)
				-- Update dock position to follow panel resize
				if updateDockPosition then
					updateDockPosition()
				end
			end
		end
	end))

	-- Exit button (✕) — top-right corner of panel
	local exitBtn = Instance.new("TextButton")
	exitBtn.Name = "ExitButton"
	exitBtn.Size = UDim2.new(0, 28, 0, 28)
	exitBtn.Position = UDim2.new(1, -36, 0, 8)
	exitBtn.BackgroundColor3 = theme.BackgroundColor3
	exitBtn.BackgroundTransparency = 0.6
	exitBtn.Text = "\226\156\149"
	exitBtn.TextColor3 = theme.SecondaryTextColor
	exitBtn.TextSize = 14
	exitBtn.Font = Enum.Font.GothamBold
	exitBtn.ZIndex = 100
	exitBtn.AutoButtonColor = false
	exitBtn.BorderSizePixel = 0
	exitBtn.Parent = mainGlass.GlassSurface

	local exitBtnCorner = Instance.new("UICorner")
	exitBtnCorner.CornerRadius = UDim.new(0, 14)
	exitBtnCorner.Parent = exitBtn

	table.insert(panelConnections, exitBtn.MouseEnter:Connect(function()
		TweenService:Create(exitBtn, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { BackgroundTransparency = 0.4 }):Play()
	end))
	table.insert(panelConnections, exitBtn.MouseLeave:Connect(function()
		TweenService:Create(exitBtn, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { BackgroundTransparency = 0.6 }):Play()
	end))

	-- BottomBar: 60px anchored at bottom
	local bottomBar = Instance.new("Frame")
	bottomBar.Name = "BottomBar"
	bottomBar.Size = UDim2.new(1, 0, 0, 60)
	bottomBar.Position = UDim2.new(0, 0, 1, -60)
	bottomBar.BackgroundColor3 = theme.BackgroundColor3
	bottomBar.BackgroundTransparency = 0.92
	bottomBar.BorderSizePixel = 0
	bottomBar.ZIndex = 10
	bottomBar.Parent = mainGlass.GlassSurface

	local barGradient = Instance.new("UIGradient")
	barGradient.Rotation = 90
	barGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.70),
		NumberSequenceKeypoint.new(0.1, 0.95),
		NumberSequenceKeypoint.new(1, 1),
	})
	barGradient.Parent = bottomBar

	-- Separator line at top of BottomBar
	local barSep = Instance.new("Frame")
	barSep.Name = "BarSeparator"
	barSep.Size = UDim2.new(1, 0, 0, 1)
	barSep.Position = UDim2.new(0, 0, 0, 0)
	barSep.BackgroundColor3 = theme.TextFieldBorderColor
	barSep.BackgroundTransparency = 0.5
	barSep.BorderSizePixel = 0
	barSep.ZIndex = 11
	barSep.Parent = bottomBar

	-- BrandBadge in BottomBar (right-aligned)
	local brandBadge = Instance.new("TextLabel")
	brandBadge.Name = "BrandBadge"
	brandBadge.Text = "Mango Development"
	brandBadge.Font = Enum.Font.GothamMedium
	brandBadge.TextSize = 11
	brandBadge.TextColor3 = theme.SecondaryTextColor
	brandBadge.BackgroundTransparency = 1
	brandBadge.Size = UDim2.new(0, 140, 1, 0)
	brandBadge.Position = UDim2.new(1, -160, 0, 0)
	brandBadge.TextXAlignment = Enum.TextXAlignment.Right
	brandBadge.TextYAlignment = Enum.TextYAlignment.Center
	brandBadge.BorderSizePixel = 0
	brandBadge.ZIndex = 11
	brandBadge.Parent = bottomBar

	-- ================================================================
	-- Tab Content Frames (4 tabs)
	-- ================================================================
	local tabNames = { "Home", "Showcase", "Effects", "Settings" }
	local tabEmojis = { "H", "S", "FX", "G" }

	for i = 1, 4 do
		local tabFrame: Frame
		if i == 4 then
			local sf = Instance.new("ScrollingFrame")
			sf.ScrollBarThickness = 4
			sf.ScrollBarImageColor3 = theme.SecondaryTextColor
			sf.ScrollBarImageTransparency = 0.5
			sf.CanvasSize = UDim2.new(0, 0, 0, 560)
			sf.ScrollingDirection = Enum.ScrollingDirection.Y
			sf.TopImage = ""
			sf.BottomImage = ""
			tabFrame = sf :: any
		else
			tabFrame = Instance.new("Frame")
		end
		tabFrame.Name = "TabContent_" .. tabNames[i]
		tabFrame.Size = UDim2.new(1, 0, 1, 0)
		tabFrame.BackgroundTransparency = 1
		tabFrame.BorderSizePixel = 0
		tabFrame.Visible = (i == currentTab)
		tabFrame.ZIndex = 5
		tabFrame.Parent = contentRegion

		local tabScale = Instance.new("UIScale")
		tabScale.Scale = 1
		tabScale.Parent = tabFrame

		-- Concentric corner radius: parent panel=24px, padding=14px → inner=10px
		local tabCorner = Instance.new("UICorner")
		tabCorner.CornerRadius = UDim.new(0, 10)
		tabCorner.Parent = tabFrame

		table.insert(tabContentFrames, tabFrame)
	end

	-- ================================================================
	-- Vertical Carousel Dock (Apple Watch style, discrete stepping, end stops)
	-- 4 real icons only, no buffer wrapping.
	-- ================================================================
	local ICON_SIZE = 44
	local ICON_GAP = 10
	local ICON_STEP = ICON_SIZE + ICON_GAP -- 54
	local ICON_COUNT = 4
	local DOCK_WIDTH = 64
	local VIEWPORT_HEIGHT = 3 * ICON_STEP + ICON_SIZE -- 206
	local VIEWPORT_CENTER = VIEWPORT_HEIGHT / 2
	local ICON_CORNER_RADIUS = 10
	local ICON_SHADOW_EXTRA = 4
	local ICON_SHADOW_OFFSET_Y = 2
	local ACTIVE_DOT_SIZE = 6
	local RUBBER_BAND_OVERSHOOT = 12

	-- Compute track Y offset to center a given tab (1-based) in viewport
	local function getIconCenterOffset(tabIdx: number): number
		local iconCenterY = (tabIdx - 1) * ICON_STEP + ICON_SIZE / 2
		return VIEWPORT_CENTER - iconCenterY
	end

	local dockGlass = createGlassFrame({
		Size = UDim2.new(0, DOCK_WIDTH, 0, VIEWPORT_HEIGHT),
		Position = UDim2.new(0.5, -352, 0.5, 250),
		AnchorPoint = Vector2.new(1, 1),
		CornerRadius = UDim.new(0, DOCK_WIDTH / 2),
		Parent = uiParent,
		Theme = theme,
		ShadowEnabled = true,
		ShadowLayerCount = 3,
		ShadowSpread = 6,
		ShadowOffsetY = 2,
		BackgroundTransparencyOverride = 0.75,
		LightweightMode = true,
	})
	table.insert(glassFrames, dockGlass)
	dockGlass.Container.ZIndex = 5
	carouselDockFrame = dockGlass.Container

	-- Dock gets the same environmental specular rim as the main panel
	-- (registered for env light tinting below — stroke rotates with sun/moon angle)

	table.insert(envLightRegisteredFrames, {
		glass = dockGlass,
		originalBgColor = dockGlass.GlassSurface.BackgroundColor3,
		originalStrokeColor = theme.StrokeColor,
		originalShadowColor = theme.ShadowColor,
	})

	-- Clipping container inside dock glass
	local carouselContainer = Instance.new("Frame")
	carouselContainer.Name = "CarouselContainer"
	carouselContainer.Size = UDim2.new(1, 0, 1, 0)
	carouselContainer.BackgroundTransparency = 1
	carouselContainer.BorderSizePixel = 0
	carouselContainer.ClipsDescendants = true
	carouselContainer.ZIndex = 10
	carouselContainer.Parent = dockGlass.GlassSurface

	-- Edge fades removed — Gaussian focus scaling already dims far icons sufficiently

	-- Vertical track (4 real icons, no buffers)
	local TRACK_TOTAL = ICON_COUNT * ICON_SIZE + (ICON_COUNT - 1) * ICON_GAP
	local track = Instance.new("Frame")
	track.Name = "CarouselTrack"
	track.Size = UDim2.new(1, 0, 0, TRACK_TOTAL)
	track.BackgroundTransparency = 1
	track.BorderSizePixel = 0
	track.ZIndex = 15
	track.Parent = carouselContainer
	carouselTrack = track

	local trackLayout = Instance.new("UIListLayout")
	trackLayout.FillDirection = Enum.FillDirection.Vertical
	trackLayout.Padding = UDim.new(0, ICON_GAP)
	trackLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	trackLayout.SortOrder = Enum.SortOrder.LayoutOrder
	trackLayout.Parent = track

	local function lightenColor(c: Color3, amount: number): Color3
		return c:Lerp(Color3.new(1, 1, 1), amount)
	end
	local function darkenColor(c: Color3, amount: number): Color3
		return c:Lerp(Color3.new(0, 0, 0), amount)
	end

	-- Apply per-icon fade/scale based on distance from viewport center (Gaussian falloff)
	local function applyCarouselFocus(overrideOffset: number?)
		local trackOffset = overrideOffset or track.Position.Y.Offset

		for i, iconData in carouselIcons do
			local iconCenterY = (i - 1) * ICON_STEP + ICON_SIZE / 2
			local iconViewportY = iconCenterY + trackOffset
			local distFromCenter = math.abs(iconViewportY - VIEWPORT_CENTER)
			local t = math.clamp(distFromCenter / ICON_STEP, 0, 3)

			-- Apple Watch paraboloid: center=1.00, steeper drop near center for authentic fisheye
			local focusScale = math.max(0.50, 1.0 - t * t)

			if not iconData.isHovering then
				iconData.uiScale.Scale = focusScale
			end

			iconData.emojiLabel.TextTransparency = math.clamp(t * t * 0.25, 0, 0.80)
			iconData.glassBg.BackgroundTransparency = math.clamp(0.20 + t * t * 0.22, 0.20, 0.88)
			iconData.iconShadow.BackgroundTransparency = math.clamp(0.78 + t * 0.15, 0.78, 0.98)
			iconData.iconStroke.Transparency = math.clamp(0.90 + t * 0.08, 0.90, 0.98)
			iconData.iconHighlight.BackgroundTransparency = math.clamp(0.92 + t * 0.06, 0.92, 0.98)

			iconData.activeDot.Visible = (i == currentTab)
		end
	end

	-- Switch tab content (with spring animation)
	local function switchTabContent(newTab: number)
		if newTab == currentTab then return end
		tabContentFrames[currentTab].Visible = false
		currentTab = newTab
		local newFrame = tabContentFrames[newTab]
		newFrame.Visible = true
		local tabScale = newFrame:FindFirstChildOfClass("UIScale")
		if tabScale then
			tabScale.Scale = 0.98
			TweenService:Create(tabScale, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Scale = 1.0 }):Play()
		end
	end

	local function animateActiveDot(oldTab: number, newTab: number)
		if oldTab >= 1 and oldTab <= #carouselIcons then
			local oldData = carouselIcons[oldTab]
			local tw = TweenService:Create(oldData.activeDotScale, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 0 })
			table.insert(carouselTweens, tw)
			tw:Play()
		end
		if newTab >= 1 and newTab <= #carouselIcons then
			local newData = carouselIcons[newTab]
			newData.activeDot.Visible = true
			newData.activeDotScale.Scale = 0
			local tw = TweenService:Create(newData.activeDotScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
			table.insert(carouselTweens, tw)
			tw:Play()
		end
	end

	-- Scroll to a specific tab (wrapping, interruptible, Apple-style snap)
	local function scrollToTab(targetTab: number)
		if targetTab < 1 then targetTab = ICON_COUNT end
		if targetTab > ICON_COUNT then targetTab = 1 end
		if targetTab == currentTab then return end

		for _, tw in carouselTweens do tw:Cancel() end
		table.clear(carouselTweens)
		for _, tw in carouselRubberBandTweens do tw:Cancel() end
		table.clear(carouselRubberBandTweens)
		if carouselFocusConn then
			carouselFocusConn:Disconnect()
			carouselFocusConn = nil
		end

		carouselScrollGen += 1
		local myGen = carouselScrollGen

		isCarouselScrolling = true
		local oldTab = currentTab
		animateActiveDot(oldTab, targetTab)
		switchTabContent(targetTab)

		-- Use shorter wrap distance for duration (4→1 = 1 step, not 3)
		local scrollDelta = math.abs(targetTab - oldTab)
		if scrollDelta > ICON_COUNT / 2 then
			scrollDelta = ICON_COUNT - scrollDelta
		end
		local scrollDuration = 0.22 + scrollDelta * 0.03
		local targetOffset = getIconCenterOffset(targetTab)
		local tw = TweenService:Create(track,
			TweenInfo.new(scrollDuration, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Position = UDim2.new(0, 0, 0, targetOffset) }
		)
		table.insert(carouselTweens, tw)
		tw:Play()

		carouselFocusConn = RunService.RenderStepped:Connect(function()
			applyCarouselFocus()
		end)

		tw.Completed:Connect(function()
			if myGen ~= carouselScrollGen then return end
			if carouselFocusConn then
				carouselFocusConn:Disconnect()
				carouselFocusConn = nil
			end
			applyCarouselFocus()
			isCarouselScrolling = false
		end)
	end

	local function rubberBandBounce(direction: number)
		for _, tw in carouselTweens do tw:Cancel() end
		table.clear(carouselTweens)
		for _, tw in carouselRubberBandTweens do tw:Cancel() end
		table.clear(carouselRubberBandTweens)
		if carouselFocusConn then
			carouselFocusConn:Disconnect()
			carouselFocusConn = nil
		end

		carouselScrollGen += 1
		local myGen = carouselScrollGen

		local currentOffset = track.Position.Y.Offset
		local overshootOffset = currentOffset + direction * RUBBER_BAND_OVERSHOOT

		-- Phase 1: overshoot
		local tw1 = TweenService:Create(track,
			TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Position = UDim2.new(0, 0, 0, overshootOffset) }
		)
		table.insert(carouselRubberBandTweens, tw1)

		carouselFocusConn = RunService.RenderStepped:Connect(function()
			applyCarouselFocus()
		end)

		tw1:Play()
		tw1.Completed:Connect(function()
			if myGen ~= carouselScrollGen then return end
			-- Phase 2: bounce back (Quad Out for clean deceleration, no overshoot)
			local tw2 = TweenService:Create(track,
				TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Position = UDim2.new(0, 0, 0, currentOffset) }
			)
			table.insert(carouselRubberBandTweens, tw2)
			tw2:Play()
			tw2.Completed:Connect(function()
				if myGen ~= carouselScrollGen then return end
				if carouselFocusConn then
					carouselFocusConn:Disconnect()
					carouselFocusConn = nil
				end
				applyCarouselFocus()
			end)
		end)
	end

	-- Per-tab accent colors: muted, Apple-style, theme-independent
	local tabAccentColors = {
		Color3.fromRGB(90, 135, 230),   -- H (Home): soft blue
		Color3.fromRGB(175, 100, 220),  -- S (Showcase): soft purple
		Color3.fromRGB(230, 140, 70),   -- FX (Effects): warm orange
		Color3.fromRGB(80, 185, 140),   -- G (Settings): soft green
	}

	-- Build 4 real icon cells (no buffers)
	for tabIdx = 1, ICON_COUNT do
		local accentColor = tabAccentColors[tabIdx]

		local cell = Instance.new("Frame")
		cell.Name = "IconCell_" .. tabIdx
		cell.Size = UDim2.new(0, ICON_SIZE, 0, ICON_SIZE)
		cell.BackgroundTransparency = 1
		cell.BorderSizePixel = 0
		cell.LayoutOrder = tabIdx - 1
		cell.ZIndex = 16
		cell.ClipsDescendants = false
		cell.Parent = track

		-- Drop shadow (accent-tinted)
		local shadowColor = darkenColor(accentColor, 0.50)
		local iconShadow = Instance.new("Frame")
		iconShadow.Name = "IconShadow"
		iconShadow.Size = UDim2.new(0, ICON_SIZE + ICON_SHADOW_EXTRA * 2, 0, ICON_SIZE + ICON_SHADOW_EXTRA * 2)
		iconShadow.AnchorPoint = Vector2.new(0.5, 0.5)
		iconShadow.Position = UDim2.new(0.5, 0, 0.5, ICON_SHADOW_OFFSET_Y)
		iconShadow.BackgroundColor3 = shadowColor
		iconShadow.BackgroundTransparency = 0.78
		iconShadow.BorderSizePixel = 0
		iconShadow.ZIndex = 15
		iconShadow.Parent = cell
		local shadowCorner = Instance.new("UICorner")
		shadowCorner.CornerRadius = UDim.new(0, ICON_CORNER_RADIUS + 2)
		shadowCorner.Parent = iconShadow

		-- Icon glass background (squircle + gradient)
		local iconGlass = Instance.new("Frame")
		iconGlass.Name = "IconGlass"
		iconGlass.Size = UDim2.new(1, 0, 1, 0)
		iconGlass.AnchorPoint = Vector2.new(0.5, 0.5)
		iconGlass.Position = UDim2.new(0.5, 0, 0.5, 0)
		iconGlass.BackgroundColor3 = accentColor
		iconGlass.BackgroundTransparency = 0.20
		iconGlass.BorderSizePixel = 0
		iconGlass.ZIndex = 16
		iconGlass.ClipsDescendants = true
		iconGlass.Parent = cell
		local iconCorner = Instance.new("UICorner")
		iconCorner.CornerRadius = UDim.new(0, ICON_CORNER_RADIUS)
		iconCorner.Parent = iconGlass

		-- Background gradient (lighter top -> darker bottom)
		local iconBgGradient = Instance.new("UIGradient")
		iconBgGradient.Rotation = 90
		iconBgGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, lightenColor(accentColor, 0.10)),
			ColorSequenceKeypoint.new(1, darkenColor(accentColor, 0.10)),
		})
		iconBgGradient.Parent = iconGlass

		-- Inner highlight (white, 45% height, top fade)
		local iconHighlight = Instance.new("Frame")
		iconHighlight.Name = "InnerHighlight"
		iconHighlight.Size = UDim2.new(1, 0, 0.35, 0)
		iconHighlight.Position = UDim2.new(0, 0, 0, 0)
		iconHighlight.BackgroundColor3 = Color3.new(1, 1, 1)
		iconHighlight.BackgroundTransparency = 1
		iconHighlight.BorderSizePixel = 0
		iconHighlight.ZIndex = 17
		iconHighlight.Parent = iconGlass
		local hlGrad = Instance.new("UIGradient")
		hlGrad.Name = "HighlightGradient"
		hlGrad.Rotation = 90
		hlGrad.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		})
		hlGrad.Parent = iconHighlight

		-- Fresnel specular stroke (3-keypoint)
		local iconStroke = Instance.new("UIStroke")
		iconStroke.Name = "SpecularStroke"
		iconStroke.Color = theme.StrokeColor
		iconStroke.Thickness = 1
		iconStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		iconStroke.Transparency = 1
		iconStroke.Parent = iconGlass
		local specGrad = Instance.new("UIGradient")
		specGrad.Name = "SpecularGradient"
		specGrad.Rotation = 90
		specGrad.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, math.min(theme.FresnelStartTransparency + 0.10, 1)),
			NumberSequenceKeypoint.new(theme.FresnelMidPoint, math.min(theme.FresnelMidTransparency + 0.10, 1)),
			NumberSequenceKeypoint.new(1, math.min(theme.FresnelEndTransparency + 0.05, 1)),
		})
		specGrad.Parent = iconStroke

		-- Icon emoji label
		local iconEmoji = Instance.new("TextLabel")
		iconEmoji.Name = "IconEmoji"
		iconEmoji.Text = tabEmojis[tabIdx]
		iconEmoji.Font = Enum.Font.GothamBold
		iconEmoji.TextSize = if tabEmojis[tabIdx] == "FX" then 14 else 18
		iconEmoji.TextColor3 = Color3.new(1, 1, 1)
		iconEmoji.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		iconEmoji.TextStrokeTransparency = 0.7
		iconEmoji.TextTransparency = 0
		iconEmoji.BackgroundTransparency = 1
		iconEmoji.Size = UDim2.new(1, 0, 1, 0)
		iconEmoji.TextXAlignment = Enum.TextXAlignment.Center
		iconEmoji.TextYAlignment = Enum.TextYAlignment.Center
		iconEmoji.BorderSizePixel = 0
		iconEmoji.ZIndex = 18
		iconEmoji.Parent = cell

		local iconScale = Instance.new("UIScale")
		iconScale.Scale = 1
		iconScale.Parent = cell

		-- Active tab indicator dot
		local activeDot = Instance.new("Frame")
		activeDot.Name = "ActiveDot"
		activeDot.Size = UDim2.new(0, ACTIVE_DOT_SIZE, 0, ACTIVE_DOT_SIZE)
		activeDot.AnchorPoint = Vector2.new(0.5, 0)
		activeDot.Position = UDim2.new(0.5, 0, 1, 3)
		activeDot.BackgroundColor3 = accentColor
		activeDot.BackgroundTransparency = 0
		activeDot.BorderSizePixel = 0
		activeDot.ZIndex = 18
		activeDot.Visible = (tabIdx == currentTab)
		activeDot.Parent = cell
		local dotCorner = Instance.new("UICorner")
		dotCorner.CornerRadius = UDim.new(1, 0)
		dotCorner.Parent = activeDot
		local activeDotScale = Instance.new("UIScale")
		activeDotScale.Scale = if tabIdx == currentTab then 1 else 0
		activeDotScale.Parent = activeDot

		-- Hit area with hover/press feedback
		local iconHit = Instance.new("TextButton")
		iconHit.Name = "IconHit"
		iconHit.Size = UDim2.new(1, 0, 1, 0)
		iconHit.BackgroundTransparency = 1
		iconHit.Text = ""
		iconHit.ZIndex = 100
		iconHit.AutoButtonColor = false
		iconHit.Parent = cell

		local hoverTweens: {Tween} = {}
		local isHoveringIcon = false

		local capturedTab = tabIdx
		table.insert(carouselConnections, iconHit.MouseEnter:Connect(function()
			isHoveringIcon = true
			carouselIcons[capturedTab].isHovering = true
			for _, tw in hoverTweens do tw:Cancel() end
			table.clear(hoverTweens)
			local scaleTw = TweenService:Create(iconScale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1.04 })
			table.insert(hoverTweens, scaleTw)
			scaleTw:Play()
		end))

		table.insert(carouselConnections, iconHit.MouseLeave:Connect(function()
			isHoveringIcon = false
			carouselIcons[capturedTab].isHovering = false
			for _, tw in hoverTweens do tw:Cancel() end
			table.clear(hoverTweens)
			-- Restore to focus-determined scale
			applyCarouselFocus()
		end))

		table.insert(carouselConnections, iconHit.MouseButton1Down:Connect(function()
			for _, tw in hoverTweens do tw:Cancel() end
			table.clear(hoverTweens)
			local pressTw = TweenService:Create(iconScale, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 0.92 })
			table.insert(hoverTweens, pressTw)
			pressTw:Play()
		end))

		table.insert(carouselConnections, iconHit.MouseButton1Up:Connect(function()
			for _, tw in hoverTweens do tw:Cancel() end
			table.clear(hoverTweens)
			local targetScale = if isHoveringIcon then 1.04 else 1.0
			local restoreTw = TweenService:Create(iconScale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = targetScale })
			table.insert(hoverTweens, restoreTw)
			restoreTw:Play()
		end))

		table.insert(carouselConnections, iconHit.MouseButton1Click:Connect(function()
			if capturedTab == currentTab then return end
			scrollToTab(capturedTab)
		end))

		table.insert(carouselIcons, {
			container = cell,
			uiScale = iconScale,
			emojiLabel = iconEmoji,
			glassBg = iconGlass,
			iconShadow = iconShadow,
			iconHighlight = iconHighlight,
			iconStroke = iconStroke,
			activeDot = activeDot,
			activeDotScale = activeDotScale,
			hoverTweens = hoverTweens,
			isHovering = false,
		})

		-- Register for env light tinting
		table.insert(envLightTintableElements, { element = iconGlass, property = "BackgroundColor3", originalColor = accentColor, intensity = 0.25 })
		table.insert(envLightTintableElements, { element = activeDot, property = "BackgroundColor3", originalColor = accentColor, intensity = 0.20 })
	end

	-- Initial position: center on current tab
	local initialOffset = getIconCenterOffset(currentTab)
	track.Position = UDim2.new(0, 0, 0, initialOffset)
	applyCarouselFocus(initialOffset)

	-- Dock follows main panel position
	updateDockPosition = function()
		if not mainGlass or not mainGlass.Container or not dockGlass then return end
		local containerPos = mainGlass.Container.AbsolutePosition
		local containerSize = mainGlass.Container.AbsoluteSize
		local dockX = containerPos.X - DOCK_WIDTH - 12
		local dockY = containerPos.Y + containerSize.Y
		dockGlass.Container.Position = UDim2.new(0, dockX, 0, dockY)
		dockGlass.Container.AnchorPoint = Vector2.new(0, 1)
	end

	-- Initial dock position + entrance animation
	task.defer(function()
		if updateDockPosition then
			updateDockPosition()
		end
		if dockGlass and dockGlass.Container then
			local finalDockPos = dockGlass.Container.Position
			dockGlass.Container.Position = UDim2.new(finalDockPos.X.Scale, finalDockPos.X.Offset, finalDockPos.Y.Scale, finalDockPos.Y.Offset + 30)
			task.delay(0.15, function()
				if dockGlass and dockGlass.Container then
					TweenService:Create(dockGlass.Container, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
						Position = finalDockPos
					}):Play()
				end
			end)
		end
	end)

	-- Carousel scroll handler: one scroll = one tab move
	local carouselScrollConn = UserInputService.InputChanged:Connect(function(input: InputObject, _gameProcessed: boolean)
		if input.UserInputType ~= Enum.UserInputType.MouseWheel then return end
		if not carouselDockFrame then return end
		local mousePos = UserInputService:GetMouseLocation()
		local dAbsPos = carouselDockFrame.AbsolutePosition
		local dAbsSize = carouselDockFrame.AbsoluteSize
		if mousePos.X >= dAbsPos.X and mousePos.X <= dAbsPos.X + dAbsSize.X
			and mousePos.Y >= dAbsPos.Y and mousePos.Y <= dAbsPos.Y + dAbsSize.Y then
			local direction = if input.Position.Z > 0 then -1 else 1
			local newTab = currentTab + direction
			-- Wrap around: scrolling past boundaries loops to the other end
			if newTab < 1 then
				newTab = ICON_COUNT
			elseif newTab > ICON_COUNT then
				newTab = 1
			end
			scrollToTab(newTab)
		end
	end)
	table.insert(carouselConnections, carouselScrollConn)

	-- Carousel touch swipe support (mobile)
	local touchStartY: number? = nil
	local SWIPE_THRESHOLD = 20

	local dockTouchBeganConn = UserInputService.InputBegan:Connect(function(input: InputObject, _gameProcessed: boolean)
		if input.UserInputType ~= Enum.UserInputType.Touch then return end
		if not carouselDockFrame then return end
		local pos = input.Position
		local dAbsPos = carouselDockFrame.AbsolutePosition
		local dAbsSize = carouselDockFrame.AbsoluteSize
		if pos.X >= dAbsPos.X and pos.X <= dAbsPos.X + dAbsSize.X
			and pos.Y >= dAbsPos.Y and pos.Y <= dAbsPos.Y + dAbsSize.Y then
			touchStartY = pos.Y
		end
	end)
	table.insert(carouselConnections, dockTouchBeganConn)

	local dockTouchEndedConn = UserInputService.InputEnded:Connect(function(input: InputObject)
		if input.UserInputType ~= Enum.UserInputType.Touch then return end
		if touchStartY == nil then return end
		local deltaY = input.Position.Y - touchStartY
		touchStartY = nil
		if math.abs(deltaY) >= SWIPE_THRESHOLD then
			local direction = if deltaY > 0 then 1 else -1
			local newTab = currentTab + direction
			if newTab < 1 then newTab = ICON_COUNT end
			if newTab > ICON_COUNT then newTab = 1 end
			scrollToTab(newTab)
		end
	end)
	table.insert(carouselConnections, dockTouchEndedConn)

	-- ================================================================
	-- TAB 1: Home — Hero Landing Page
	-- ================================================================
	local tab1 = tabContentFrames[1]
	local tab1Pad = Instance.new("UIPadding")
	tab1Pad.PaddingTop = UDim.new(0, 24)
	tab1Pad.PaddingLeft = UDim.new(0, 24)
	tab1Pad.PaddingRight = UDim.new(0, 24)
	tab1Pad.PaddingBottom = UDim.new(0, 16)
	tab1Pad.Parent = tab1

	addLabel(tab1, "HomeTitle", "Liquid Glass", Enum.Font.GothamMedium, 22, theme.PrimaryTextColor, UDim2.new(1, 0, 0, 28), UDim2.new(0, 0, 0, 0))
	addLabel(tab1, "HomeSubtitle", "Apple-inspired glassmorphism for Roblox", Enum.Font.Gotham, 15, theme.SecondaryTextColor, UDim2.new(1, 0, 0, 22), UDim2.new(0, 0, 0, 40), nil, true)
	addLabel(tab1, "HomeDesc", "Directional rim lighting, multi-layer soft shadows, camera-locked refraction, mouse-driven parallax, smooth hover animations, and a complete Apple-style UI control library.", Enum.Font.Gotham, 13, theme.SecondaryTextColor, UDim2.new(1, 0, 0, 50), UDim2.new(0, 0, 0, 68), nil, true)

	-- Feature row: 3 glass pill badges
	local featureRow = Instance.new("Frame")
	featureRow.Name = "FeatureRow"
	featureRow.Size = UDim2.new(1, 0, 0, 34)
	featureRow.Position = UDim2.new(0, 0, 0, 130)
	featureRow.BackgroundTransparency = 1
	featureRow.BorderSizePixel = 0
	featureRow.ZIndex = 10
	featureRow.Parent = tab1
	local featureLayout = Instance.new("UIListLayout")
	featureLayout.FillDirection = Enum.FillDirection.Horizontal
	featureLayout.Padding = UDim.new(0, 10)
	featureLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	featureLayout.SortOrder = Enum.SortOrder.LayoutOrder
	featureLayout.Parent = featureRow

	local featureLabels = { "Directional Rim", "Inner Glow", "Refraction" }
	for fi, featureText in featureLabels do
		local badge = createGlassFrame({
			Size = UDim2.new(0, 120, 0, 30),
			Position = UDim2.new(0, 0, 0, 0),
			CornerRadius = UDim.new(0, 999),
			Theme = theme,
			ShadowEnabled = false,
			LightweightMode = true,
			Parent = featureRow,
			BackgroundTransparencyOverride = theme.ButtonBackgroundTransparency + 0.05,
		})
		badge.Container.LayoutOrder = fi
		table.insert(glassFrames, badge)
		table.insert(envLightRegisteredFrames, {
			glass = badge,
			originalBgColor = badge.GlassSurface.BackgroundColor3,
			originalStrokeColor = theme.StrokeColor,
			originalShadowColor = theme.ShadowColor,
		})

		local badgeLbl = Instance.new("TextLabel")
		badgeLbl.Text = featureText
		badgeLbl.Font = Enum.Font.GothamMedium
		badgeLbl.TextSize = 11
		badgeLbl.TextColor3 = theme.PrimaryTextColor
		badgeLbl.BackgroundTransparency = 1
		badgeLbl.Size = UDim2.new(1, 0, 1, 0)
		badgeLbl.TextXAlignment = Enum.TextXAlignment.Center
		badgeLbl.TextYAlignment = Enum.TextYAlignment.Center
		badgeLbl.BorderSizePixel = 0
		badgeLbl.ZIndex = 10
		badgeLbl.Parent = badge.GlassSurface
	end

	-- Small glass demo panel at bottom of Home tab
	local demoGlass = createGlassFrame({
		Size = UDim2.new(1, 0, 0, 200),
		Position = UDim2.new(0, 0, 0, 180),
		CornerRadius = UDim.new(0, 16),
		Theme = theme,
		ShadowEnabled = false,
		LightweightMode = true,
		Parent = tab1,
	})
	table.insert(glassFrames, demoGlass)
	table.insert(envLightRegisteredFrames, {
		glass = demoGlass,
		originalBgColor = demoGlass.GlassSurface.BackgroundColor3,
		originalStrokeColor = theme.StrokeColor,
		originalShadowColor = theme.ShadowColor,
	})
	addLabel(demoGlass.GlassSurface, "DemoLabel", "Glass Demo Surface", Enum.Font.GothamBold, 18, theme.PrimaryTextColor, UDim2.new(1, -32, 0, 24), UDim2.new(0, 16, 0, 16))
	addLabel(demoGlass.GlassSurface, "DemoDesc", "Glass material with directional specular rim lighting and inner glow.", Enum.Font.Gotham, 13, theme.SecondaryTextColor, UDim2.new(1, -32, 0, 40), UDim2.new(0, 16, 0, 48), nil, true)

	-- ================================================================
	-- TAB 2: Showcase — Two-Column Layout
	-- ================================================================
	local tab2 = tabContentFrames[2]
	local tab2Pad = Instance.new("UIPadding")
	tab2Pad.PaddingTop = UDim.new(0, 20)
	tab2Pad.PaddingLeft = UDim.new(0, 20)
	tab2Pad.PaddingRight = UDim.new(0, 20)
	tab2Pad.PaddingBottom = UDim.new(0, 12)
	tab2Pad.Parent = tab2

	-- Left column
	local leftCol = Instance.new("Frame")
	leftCol.Name = "LeftColumn"
	leftCol.Size = UDim2.new(0.48, 0, 1, 0)
	leftCol.Position = UDim2.new(0, 0, 0, 0)
	leftCol.BackgroundTransparency = 1
	leftCol.BorderSizePixel = 0
	leftCol.ZIndex = 10
	leftCol.Parent = tab2

	addLabel(leftCol, "ControlsTitle", "Controls", Enum.Font.GothamMedium, 15, theme.PrimaryTextColor, UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, 0))

	-- Segmented control
	local seg = createSegmentedControl(
		{"All", "Active", "Done"},
		UDim2.new(0, 0, 0, 28),
		Vector2.new(0, 0),
		theme,
		leftCol
	)
	table.insert(componentStates, seg)

	-- Slider row
	addLabel(leftCol, "OpacityLabel", "Opacity", Enum.Font.Gotham, 13, theme.SecondaryTextColor, UDim2.new(1, 0, 0, 16), UDim2.new(0, 0, 0, 72))
	local opacitySlider = createSlider(
		UDim2.new(0, 0, 0, 96),
		UDim2.new(0, 280, 0, 36),
		Vector2.new(0, 0),
		theme,
		0.5,
		function(_value: number) end,
		leftCol
	)
	table.insert(componentStates, { Destroy = opacitySlider.Destroy })

	-- Checkbox
	local chk = createCheckbox(
		"Enable notifications",
		UDim2.new(0, 0, 0, 142),
		Vector2.new(0, 0),
		theme,
		true,
		function(_state: boolean) end,
		leftCol
	)
	table.insert(componentStates, chk)

	-- Progress bar
	addLabel(leftCol, "ProgressLabel", "Progress", Enum.Font.Gotham, 13, theme.SecondaryTextColor, UDim2.new(1, 0, 0, 16), UDim2.new(0, 0, 0, 178))
	local prog = createProgressBar(
		UDim2.new(0, 0, 0, 202),
		UDim2.new(0, 280, 0, 16),
		Vector2.new(0, 0),
		theme,
		0.65,
		leftCol
	)
	table.insert(componentStates, prog)

	-- Button row: Continue + Settings
	local leftBtnRow = makeButtonRow("LeftBtnRow", leftCol, UDim2.new(0, 0, 0, 224))
	local continueBtn = createButton("Continue", UDim2.new(0, 0, 0, 0), Vector2.new(0, 0), theme, function() end, leftBtnRow)
	table.insert(buttonStates, continueBtn)
	local settingsBtn = createButton("Settings", UDim2.new(0, 0, 0, 0), Vector2.new(0, 0), theme, function() end, leftBtnRow)
	table.insert(buttonStates, settingsBtn)

	-- Right column
	local rightCol = Instance.new("Frame")
	rightCol.Name = "RightColumn"
	rightCol.Size = UDim2.new(0.48, 0, 1, 0)
	rightCol.Position = UDim2.new(0.52, 0, 0, 0)
	rightCol.BackgroundTransparency = 1
	rightCol.BorderSizePixel = 0
	rightCol.ZIndex = 10
	rightCol.Parent = tab2

	addLabel(rightCol, "InputsTitle", "Inputs", Enum.Font.GothamMedium, 15, theme.PrimaryTextColor, UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, 0))

	-- Search bar
	local srch = createSearchBar(
		UDim2.new(0, 0, 0, 28),
		UDim2.new(0, 280, 0, 36),
		Vector2.new(0, 0),
		"Search items...",
		theme,
		rightCol
	)
	table.insert(componentStates, srch)

	-- Text field
	local tf = createTextField(
		UDim2.new(0, 0, 0, 74),
		UDim2.new(0, 280, 0, 36),
		Vector2.new(0, 0),
		"Enter name...",
		theme,
		rightCol
	)
	table.insert(componentStates, tf)

	-- Dropdown
	local dd = createDropdown(
		{"Option 1", "Option 2", "Option 3", "Option 4"},
		UDim2.new(0, 0, 0, 120),
		UDim2.new(0, 280, 0, 36),
		Vector2.new(0, 0),
		theme,
		rightCol
	)
	table.insert(componentStates, dd)

	-- Button row: Dialog + Action Sheet
	local rightBtnRow = makeButtonRow("RightBtnRow", rightCol, UDim2.new(0, 0, 0, 224))
	local dialogBtn = createButton("Dialog", UDim2.new(0, 0, 0, 0), Vector2.new(0, 0), theme, function()
		if dialogState then dialogState.Show() end
	end, rightBtnRow)
	table.insert(buttonStates, dialogBtn)
	local actionSheetBtn = createButton("Action Sheet", UDim2.new(0, 0, 0, 0), Vector2.new(0, 0), theme, function()
		if actionSheetState then actionSheetState.Show() end
	end, rightBtnRow)
	table.insert(buttonStates, actionSheetBtn)

	-- Register tintable elements for environment light (Showcase tab)
	-- Segmented control container
	table.insert(envLightTintableElements, { element = seg.Container, property = "BackgroundColor3", originalColor = seg.Container.BackgroundColor3, intensity = 0.25 })
	-- Slider track surfaces
	local opacityTrack = opacitySlider.Container:FindFirstChild("TrackSurface")
	if opacityTrack and opacityTrack:IsA("GuiObject") then
		table.insert(envLightTintableElements, { element = opacityTrack, property = "BackgroundColor3", originalColor = opacityTrack.BackgroundColor3, intensity = 0.20 })
	end
	-- Progress bar track surface
	if prog.TrackSurface then
		table.insert(envLightTintableElements, { element = prog.TrackSurface, property = "BackgroundColor3", originalColor = prog.TrackSurface.BackgroundColor3, intensity = 0.25 })
	end
	-- Search bar container
	table.insert(envLightTintableElements, { element = srch.Container, property = "BackgroundColor3", originalColor = srch.Container.BackgroundColor3, intensity = 0.20 })
	-- Text field container
	table.insert(envLightTintableElements, { element = tf.Container, property = "BackgroundColor3", originalColor = tf.Container.BackgroundColor3, intensity = 0.20 })
	-- Dropdown display
	if dd.Display then
		table.insert(envLightTintableElements, { element = dd.Display :: Frame, property = "BackgroundColor3", originalColor = (dd.Display :: Frame).BackgroundColor3, intensity = 0.25 })
	end

	-- ================================================================
	-- TAB 3: Effects — Lighting and Overlay Controls
	-- ================================================================
	local tab3 = tabContentFrames[3]
	local tab3Pad = Instance.new("UIPadding")
	tab3Pad.PaddingTop = UDim.new(0, 24)
	tab3Pad.PaddingLeft = UDim.new(0, 24)
	tab3Pad.PaddingRight = UDim.new(0, 24)
	tab3Pad.PaddingBottom = UDim.new(0, 12)
	tab3Pad.Parent = tab3

	-- Section: Lighting
	addLabel(tab3, "LightingTitle", "Lighting", Enum.Font.GothamMedium, 15, theme.PrimaryTextColor, UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, 0))
	addLabel(tab3, "LightDirLabel", "Light Direction", Enum.Font.Gotham, 13, theme.SecondaryTextColor, UDim2.new(1, 0, 0, 16), UDim2.new(0, 0, 0, 28))

	sliderState = createSlider(
		UDim2.new(0, 0, 0, 52),
		UDim2.new(1, 0, 0, 36),
		Vector2.new(0, 0),
		theme,
		lightAngle / 360,
		function(value: number)
			if not isSpinning then
				lightAngle = value * 360
				updateAllGradientRotations(lightAngle)
			end
		end,
		tab3
	)

	-- Register light direction slider track for env light tinting
	if sliderState then
		local ldTrack = sliderState.Container:FindFirstChild("TrackSurface")
		if ldTrack and ldTrack:IsA("GuiObject") then
			table.insert(envLightTintableElements, { element = ldTrack, property = "BackgroundColor3", originalColor = ldTrack.BackgroundColor3, intensity = 0.20 })
		end
	end

	local envLightLastTintUpdate: number = 0

	local function applyEnvLightTint(tint: Color3)
		for _, entry in envLightRegisteredFrames do
			entry.glass.GlassSurface.BackgroundColor3 = entry.originalBgColor:Lerp(tint, 0.45)
			for _, desc in entry.glass.Container:GetDescendants() do
				if desc:IsA("UIStroke") and (desc.Name == "SpecularStroke" or desc.Name == "InnerEdgeStroke") then
					desc.Color = entry.originalStrokeColor:Lerp(tint, 0.35)
				end
			end
			-- Ambient color spill into shadows (Apple: light scatters and bleeds into shadow)
			for _, shadowLayer in entry.glass.ShadowLayers do
				shadowLayer.BackgroundColor3 = entry.originalShadowColor:Lerp(tint, 0.15)
			end
		end
		for _, tintEntry in envLightTintableElements do
			(tintEntry.element :: any)[tintEntry.property] = tintEntry.originalColor:Lerp(tint, tintEntry.intensity)
		end
	end

	local function restoreEnvLightColors()
		for _, entry in envLightRegisteredFrames do
			entry.glass.GlassSurface.BackgroundColor3 = entry.originalBgColor
			for _, desc in entry.glass.Container:GetDescendants() do
				if desc:IsA("UIStroke") and (desc.Name == "SpecularStroke" or desc.Name == "InnerEdgeStroke") then
					desc.Color = entry.originalStrokeColor
				end
			end
			-- Restore shadow colors
			for _, shadowLayer in entry.glass.ShadowLayers do
				shadowLayer.BackgroundColor3 = entry.originalShadowColor
			end
		end
		for _, tintEntry in envLightTintableElements do
			(tintEntry.element :: any)[tintEntry.property] = tintEntry.originalColor
		end
	end

	local function envLightSampleTint(): Color3
		local outdoor = Lighting.OutdoorAmbient
		local ambient = Lighting.Ambient
		local colorShiftTop = Lighting.ColorShift_Top
		local r = outdoor.R * 0.5 + ambient.R * 0.2 + colorShiftTop.R * 0.3
		local g = outdoor.G * 0.5 + ambient.G * 0.2 + colorShiftTop.G * 0.3
		local b = outdoor.B * 0.5 + ambient.B * 0.2 + colorShiftTop.B * 0.3
		return Color3.new(math.clamp(r, 0, 1), math.clamp(g, 0, 1), math.clamp(b, 0, 1))
	end

	local lightBtnRow = makeButtonRow("LightBtnRow", tab3, UDim2.new(0, 0, 0, 96))
	local envBtn = createButton("Environment Light", UDim2.new(0, 0, 0, 0), Vector2.new(0, 0), theme, function()
		envLightEnabled = not envLightEnabled
		if envLightEnabled then
			if spinConnection then
				spinConnection:Disconnect()
				spinConnection = nil
			end
			isSpinning = false

			if envLightConnection then
				envLightConnection:Disconnect()
				envLightConnection = nil
			end
			envLightConnection = RunService.RenderStepped:Connect(function(_dt: number)
				local camera = Workspace.CurrentCamera
				if not camera then return end

				local sunDir = Lighting:GetSunDirection()
				if sunDir.Y < -0.1 then
					sunDir = Lighting:GetMoonDirection()
				end
				local localDir = camera.CFrame:VectorToObjectSpace(sunDir)
				local angle = (math.deg(math.atan2(-localDir.Y, localDir.X)) + 90) % 360
				lightAngle = angle
				updateAllGradientRotations(angle)
				if sliderState then
					sliderState.SetValue(angle / 360)
				end

				local now = tick()
				if now - envLightLastTintUpdate >= 0.5 then
					envLightLastTintUpdate = now
					applyEnvLightTint(envLightSampleTint())
				end
			end)
		else
			if envLightConnection then
				envLightConnection:Disconnect()
				envLightConnection = nil
			end
			restoreEnvLightColors()
		end
	end, lightBtnRow)
	table.insert(buttonStates, envBtn)

	local spinBtn = createButton("Spin Light", UDim2.new(0, 0, 0, 0), Vector2.new(0, 0), theme, function()
		isSpinning = not isSpinning
		if isSpinning then
			if envLightConnection then
				envLightConnection:Disconnect()
				envLightConnection = nil
			end
			envLightEnabled = false
			if spinConnection then
				spinConnection:Disconnect()
				spinConnection = nil
			end
			spinConnection = RunService.RenderStepped:Connect(function(dt: number)
				lightAngle = (lightAngle + 45 * dt) % 360
				updateAllGradientRotations(lightAngle)
				if sliderState then
					sliderState.SetValue(lightAngle / 360)
				end
			end)
		else
			if spinConnection then
				spinConnection:Disconnect()
				spinConnection = nil
			end
		end
	end, lightBtnRow)
	table.insert(buttonStates, spinBtn)

	-- Separator
	makeSeparator(tab3, UDim2.new(0, 0, 0, 152))

	-- Section: Parallax
	addLabel(tab3, "ParallaxTitle", "Parallax", Enum.Font.GothamMedium, 15, theme.PrimaryTextColor, UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, 164))
	addLabel(tab3, "ParallaxInfo", "Move your mouse to see specular shift", Enum.Font.Gotham, 13, theme.SecondaryTextColor, UDim2.new(1, 0, 0, 18), UDim2.new(0, 0, 0, 188), nil, true)

	-- Separator
	makeSeparator(tab3, UDim2.new(0, 0, 0, 218))

	-- Section: Overlays
	addLabel(tab3, "OverlaysTitle", "Overlays", Enum.Font.GothamMedium, 15, theme.PrimaryTextColor, UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, 230))

	local overlayBtnRow = makeButtonRow("OverlayBtnRow", tab3, UDim2.new(0, 0, 0, 258))
	local notifBtn = createButton("Notification", UDim2.new(0, 0, 0, 0), Vector2.new(0, 0), theme, function()
		pushNotification(uiParent, theme)
	end, overlayBtnRow)
	table.insert(buttonStates, notifBtn)

	local dialogBtn2 = createButton("Dialog", UDim2.new(0, 0, 0, 0), Vector2.new(0, 0), theme, function()
		if dialogState then dialogState.Show() end
	end, overlayBtnRow)
	table.insert(buttonStates, dialogBtn2)

	local actionBtn2 = createButton("Action Sheet", UDim2.new(0, 0, 0, 0), Vector2.new(0, 0), theme, function()
		if actionSheetState then actionSheetState.Show() end
	end, overlayBtnRow)
	table.insert(buttonStates, actionBtn2)

	-- Separator
	makeSeparator(tab3, UDim2.new(0, 0, 0, 314))

	-- Section: Billboard Labels
	addLabel(tab3, "LabelsTitle", "Billboard Labels", Enum.Font.GothamMedium, 15, theme.PrimaryTextColor, UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, 326))

	local labelsBtnRow = makeButtonRow("LabelsBtnRow", tab3, UDim2.new(0, 0, 0, 354))
	local labelsBtn = createButton(
		if labelsEnabled then "Disable Labels" else "Enable Labels",
		UDim2.new(0, 0, 0, 0),
		Vector2.new(0, 0),
		theme,
		function()
			if labelsEnabled then
				destroyBillboardLabels()
			else
				createBillboardLabels()
			end
		end,
		labelsBtnRow
	)
	table.insert(buttonStates, labelsBtn)

	-- ================================================================
	-- TAB 4: Settings — Theme and Parameter Controls
	-- ================================================================
	local tab4 = tabContentFrames[4]
	local tab4Pad = Instance.new("UIPadding")
	tab4Pad.PaddingTop = UDim.new(0, 24)
	tab4Pad.PaddingLeft = UDim.new(0, 24)
	tab4Pad.PaddingRight = UDim.new(0, 24)
	tab4Pad.PaddingBottom = UDim.new(0, 12)
	tab4Pad.Parent = tab4

	-- Section: Theme
	addLabel(tab4, "ThemeTitle", "Theme", Enum.Font.GothamMedium, 15, theme.PrimaryTextColor, UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, 0))

	-- Theme picker row
	local themePickerRow = Instance.new("Frame")
	themePickerRow.Name = "ThemePickerRow"
	themePickerRow.Size = UDim2.new(1, 0, 0, 38)
	themePickerRow.Position = UDim2.new(0, 0, 0, 28)
	themePickerRow.BackgroundTransparency = 1
	themePickerRow.BorderSizePixel = 0
	themePickerRow.ZIndex = 10
	themePickerRow.Parent = tab4
	local tpLayout = Instance.new("UIListLayout")
	tpLayout.FillDirection = Enum.FillDirection.Horizontal
	tpLayout.Padding = UDim.new(0, 12)
	tpLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	tpLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tpLayout.Parent = themePickerRow

	for ti, themeEntry in themeOrder do
		local isSelected = (ti == currentThemeIndex)
		local pillGlass = createGlassFrame({
			Size = UDim2.new(0, 110, 0, 34),
			Position = UDim2.new(0, 0, 0, 0),
			CornerRadius = UDim.new(0, 999),
			Theme = themeEntry.theme,
			ShadowEnabled = false,
			LightweightMode = true,
			Parent = themePickerRow,
			BackgroundTransparencyOverride = if isSelected then 0.30 else 0.55,
		})
		pillGlass.Container.LayoutOrder = ti
		table.insert(glassFrames, pillGlass)
		table.insert(envLightRegisteredFrames, {
			glass = pillGlass,
			originalBgColor = pillGlass.GlassSurface.BackgroundColor3,
			originalStrokeColor = themeEntry.theme.StrokeColor,
			originalShadowColor = themeEntry.theme.ShadowColor,
		})

		local pillLabel = Instance.new("TextLabel")
		pillLabel.Text = themeEntry.name
		pillLabel.Font = if isSelected then Enum.Font.GothamBold else Enum.Font.GothamMedium
		pillLabel.TextSize = 13
		pillLabel.TextColor3 = themeEntry.theme.PrimaryTextColor
		pillLabel.BackgroundTransparency = 1
		pillLabel.Size = UDim2.new(1, 0, 1, 0)
		pillLabel.TextXAlignment = Enum.TextXAlignment.Center
		pillLabel.TextYAlignment = Enum.TextYAlignment.Center
		pillLabel.BorderSizePixel = 0
		pillLabel.ZIndex = 10
		pillLabel.Parent = pillGlass.GlassSurface

		local pillHit = Instance.new("TextButton")
		pillHit.Size = UDim2.new(1, 0, 1, 0)
		pillHit.BackgroundTransparency = 1
		pillHit.Text = ""
		pillHit.ZIndex = 100
		pillHit.AutoButtonColor = false
		pillHit.Parent = pillGlass.GlassSurface

		table.insert(panelConnections, pillHit.MouseButton1Click:Connect(function()
			if ti == currentThemeIndex or isThemeSwitching then return end
			isThemeSwitching = true
			-- Materialization dismiss: shadow → surface → specular (Apple's optical integrity)
			local dismissInfo = TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			-- Phase 1: Shadows fade out first (element lifts off)
			for _, glass in glassFrames do
				for _, layer in glass.ShadowLayers do
					TweenService:Create(layer, dismissInfo, { BackgroundTransparency = 1 }):Play()
				end
			end
			-- Phase 2: Surface dissolves (0.04s delay)
			task.delay(0.04, function()
				for _, glass in glassFrames do
					TweenService:Create(glass.GlassSurface, TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play()
				end
			end)
			-- Phase 3: Rebuild after full sequence
			task.delay(0.15, function()
				currentThemeIndex = ti
				currentTheme = themeEntry.theme
				buildUI()
			end)
		end))
	end

	-- Separator
	makeSeparator(tab4, UDim2.new(0, 0, 0, 76))

	-- Section: Glass Parameters
	addLabel(tab4, "ParamsTitle", "Glass Parameters", Enum.Font.GothamMedium, 15, theme.PrimaryTextColor, UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, 88))

	-- Glass Opacity slider
	addLabel(tab4, "GlassOpLabel", "Glass Opacity", Enum.Font.Gotham, 13, theme.SecondaryTextColor, UDim2.new(0.5, 0, 0, 16), UDim2.new(0, 0, 0, 116))
	local glassOpSlider = createSlider(
		UDim2.new(0, 0, 0, 140),
		UDim2.new(0, 280, 0, 30),
		Vector2.new(0, 0),
		theme,
		(theme.BackgroundTransparency - 0.70) / 0.25,
		function(value: number)
			local newTransp = 0.70 + value * 0.25
			mainGlass.GlassSurface.BackgroundTransparency = newTransp
		end,
		tab4
	)
	table.insert(componentStates, { Destroy = glassOpSlider.Destroy })

	-- Shadow Spread slider
	addLabel(tab4, "ShadowSpLabel", "Shadow Spread", Enum.Font.Gotham, 13, theme.SecondaryTextColor, UDim2.new(0.5, 0, 0, 16), UDim2.new(0, 0, 0, 178))
	local shadowSpSlider = createSlider(
		UDim2.new(0, 0, 0, 202),
		UDim2.new(0, 280, 0, 30),
		Vector2.new(0, 0),
		theme,
		(theme.ShadowSpread - 4) / 26,
		function(value: number)
			local newSpread = 4 + value * 26
			for layerIdx, shadowLayer in mainGlass.ShadowLayers do
				local t = layerIdx / #mainGlass.ShadowLayers
				local layerSpread = math.ceil(newSpread * t)
				shadowLayer.Size = UDim2.new(1, layerSpread * 2, 1, layerSpread * 2)
			end
		end,
		tab4
	)
	table.insert(componentStates, { Destroy = shadowSpSlider.Destroy })

	-- Specular Intensity slider
	addLabel(tab4, "SpecIntLabel", "Specular Intensity", Enum.Font.Gotham, 13, theme.SecondaryTextColor, UDim2.new(0.5, 0, 0, 16), UDim2.new(0, 0, 0, 240))
	local specIntSlider = createSlider(
		UDim2.new(0, 0, 0, 264),
		UDim2.new(0, 280, 0, 30),
		Vector2.new(0, 0),
		theme,
		1 - (theme.FresnelStartTransparency - 0.05) / 0.45,
		function(value: number)
			local newFresnelStart = 0.05 + (1 - value) * 0.45
			if mainGlass.SpecularGradient then
				mainGlass.SpecularGradient.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, newFresnelStart),
					NumberSequenceKeypoint.new(theme.FresnelMidPoint, math.min(newFresnelStart + 0.25, 1)),
					NumberSequenceKeypoint.new(1, math.min(newFresnelStart + 0.70, 1)),
				})
			end
		end,
		tab4
	)
	table.insert(componentStates, { Destroy = specIntSlider.Destroy })

	-- Shadow Intensity slider
	addLabel(tab4, "ShadowIntLabel", "Shadow Intensity", Enum.Font.Gotham, 13, theme.SecondaryTextColor, UDim2.new(0.5, 0, 0, 16), UDim2.new(0, 0, 0, 302))
	local shadowIntSlider = createSlider(
		UDim2.new(0, 0, 0, 326),
		UDim2.new(0, 280, 0, 30),
		Vector2.new(0, 0),
		theme,
		0.5,
		function(value: number)
			local multiplier = value * 2
			for _, shadowLayer in mainGlass.ShadowLayers do
				local baseTrans = 1 - (1 - theme.ShadowTransparency) * multiplier
				shadowLayer.BackgroundTransparency = math.clamp(baseTrans, 0, 1)
			end
		end,
		tab4
	)
	table.insert(componentStates, { Destroy = shadowIntSlider.Destroy })

	-- Register settings tab slider tracks for env light tinting
	for _, settingsSlider in { glassOpSlider, shadowSpSlider, specIntSlider, shadowIntSlider } do
		local sTrack = settingsSlider.Container:FindFirstChild("TrackSurface")
		if sTrack and sTrack:IsA("GuiObject") then
			table.insert(envLightTintableElements, { element = sTrack, property = "BackgroundColor3", originalColor = sTrack.BackgroundColor3, intensity = 0.20 })
		end
	end

	-- Separator
	makeSeparator(tab4, UDim2.new(0, 0, 0, 368))

	-- Section: Features
	addLabel(tab4, "FeaturesTitle", "Features", Enum.Font.GothamMedium, 15, theme.PrimaryTextColor, UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, 380))

	local chkParallax = createCheckbox(
		"Enable Parallax",
		UDim2.new(0, 0, 0, 408),
		Vector2.new(0, 0),
		theme,
		true,
		function(state: boolean)
			if state then
				if not parallaxConnection then
					local specGrad = mainGlass.SpecularGradient
					local edgeGrad = mainGlass.InnerEdgeGradient
					local pIntensity = theme.ParallaxIntensity
					parallaxConnection = RunService.RenderStepped:Connect(function()
						local cam = Workspace.CurrentCamera
						if not cam then return end
						local mp = UserInputService:GetMouseLocation()
						local vp = cam.ViewportSize
						if vp.X == 0 or vp.Y == 0 then return end
						local nx = (mp.X / vp.X - 0.5) * 2
						local ny = (mp.Y / vp.Y - 0.5) * 2
						local ox = nx * pIntensity * 0.5
						local oy = ny * pIntensity * 0.5
						if specGrad then specGrad.Offset = Vector2.new(ox, oy) end
						if edgeGrad then edgeGrad.Offset = Vector2.new(ox * 0.5, oy * 0.5) end
					end)
				end
			else
				if parallaxConnection then
					parallaxConnection:Disconnect()
					parallaxConnection = nil
				end
				if mainGlass.SpecularGradient then mainGlass.SpecularGradient.Offset = Vector2.new(0, 0) end
				if mainGlass.InnerEdgeGradient then mainGlass.InnerEdgeGradient.Offset = Vector2.new(0, 0) end
			end
		end,
		tab4
	)
	table.insert(componentStates, chkParallax)

	local chkRefraction = createCheckbox(
		"Enable Refraction",
		UDim2.new(0, 0, 0, 440),
		Vector2.new(0, 0),
		theme,
		true,
		function(state: boolean)
			for _, refraction in refractionStates do
				if refraction.GlassPart then
					refraction.GlassPart.Transparency = if state then theme.GlassTransparency else 1
				end
			end
		end,
		tab4
	)
	table.insert(componentStates, chkRefraction)

	local chkEnvLight = createCheckbox(
		"Enable Environment Lighting",
		UDim2.new(0, 0, 0, 472),
		Vector2.new(0, 0),
		theme,
		false,
		function(state: boolean)
			if state then
				if not envLightConnection then
					envLightEnabled = true
					if spinConnection then
						spinConnection:Disconnect()
						spinConnection = nil
					end
					isSpinning = false
					envLightConnection = RunService.RenderStepped:Connect(function(_dt: number)
						local camera = Workspace.CurrentCamera
						if not camera then return end
						local sunDir = Lighting:GetSunDirection()
						if sunDir.Y < -0.1 then
							sunDir = Lighting:GetMoonDirection()
						end
						local localDir = camera.CFrame:VectorToObjectSpace(sunDir)
						local angle = (math.deg(math.atan2(-localDir.Y, localDir.X)) + 90) % 360
						lightAngle = angle
						updateAllGradientRotations(angle)
						if sliderState then
							sliderState.SetValue(angle / 360)
						end
						local now = tick()
						if now - envLightLastTintUpdate >= 0.5 then
							envLightLastTintUpdate = now
							applyEnvLightTint(envLightSampleTint())
						end
					end)
				end
			else
				envLightEnabled = false
				if envLightConnection then
					envLightConnection:Disconnect()
					envLightConnection = nil
				end
				restoreEnvLightColors()
			end
		end,
		tab4
	)
	table.insert(componentStates, chkEnvLight)

	local chkBillboards = createCheckbox(
		"Billboard Labels",
		UDim2.new(0, 0, 0, 504),
		Vector2.new(0, 0),
		theme,
		labelsEnabled,
		function(state: boolean)
			if state then
				createBillboardLabels()
			else
				destroyBillboardLabels()
			end
		end,
		tab4
	)
	table.insert(componentStates, chkBillboards)

	-- ================================================================
	-- Parallax on main panel
	-- ================================================================
	local mainSpecGrad = mainGlass.SpecularGradient
	local mainInnerEdgeGrad = mainGlass.InnerEdgeGradient
	local intensity = theme.ParallaxIntensity

	if parallaxConnection then
		parallaxConnection:Disconnect()
		parallaxConnection = nil
	end
	parallaxConnection = RunService.RenderStepped:Connect(function()
		local cam = Workspace.CurrentCamera
		if not cam then return end
		local mousePos = UserInputService:GetMouseLocation()
		local viewport = cam.ViewportSize
		if viewport.X == 0 or viewport.Y == 0 then return end
		local nx = (mousePos.X / viewport.X - 0.5) * 2
		local ny = (mousePos.Y / viewport.Y - 0.5) * 2
		local offsetX = nx * intensity * 0.5
		local offsetY = ny * intensity * 0.5
		if mainSpecGrad then
			mainSpecGrad.Offset = Vector2.new(offsetX, offsetY)
		end
		if mainInnerEdgeGrad then
			mainInnerEdgeGrad.Offset = Vector2.new(offsetX * 0.5, offsetY * 0.5)
		end
	end)

	-- ================================================================
	-- Dialog (created once, shown on button click)
	-- ================================================================
	dialogState = createDialog(
		"Glass Dialog",
		"This is a modal dialog with Apple-style glass transparency and spring animation.",
		{
			{ text = "Cancel", style = "cancel" },
			{ text = "OK", style = "default" },
		},
		theme,
		gui
	)

	-- ================================================================
	-- Action Sheet (created once, shown on button click)
	-- ================================================================
	actionSheetState = createActionSheet(
		"Choose an Action",
		{
			{ text = "Share", style = "default" },
			{ text = "Delete", style = "destructive" },
		},
		"Cancel",
		theme,
		gui
	)

	-- Re-create billboard labels if they were enabled
	if labelsEnabled then
		createBillboardLabels()
	end

	-- Apply current light angle to all gradients
	updateAllGradientRotations(lightAngle)

	-- Restore spinning if active
	if isSpinning and not spinConnection then
		spinConnection = RunService.RenderStepped:Connect(function(dt: number)
			lightAngle = (lightAngle + 45 * dt) % 360
			updateAllGradientRotations(lightAngle)
			if sliderState then
				sliderState.SetValue(lightAngle / 360)
			end
		end)
	end

	-- Restore environment lighting if it was active before theme switch
	if envLightEnabled and not envLightConnection then
		if spinConnection then
			spinConnection:Disconnect()
			spinConnection = nil
		end
		isSpinning = false

		envLightConnection = RunService.RenderStepped:Connect(function(_dt: number)
			local camera = Workspace.CurrentCamera
			if not camera then return end

			local sunDir = Lighting:GetSunDirection()
			if sunDir.Y < -0.1 then
				sunDir = Lighting:GetMoonDirection()
			end
			local localDir = camera.CFrame:VectorToObjectSpace(sunDir)
			local angle = (math.deg(math.atan2(-localDir.Y, localDir.X)) + 90) % 360
			lightAngle = angle
			updateAllGradientRotations(angle)
			if sliderState then
				sliderState.SetValue(angle / 360)
			end

			local now = tick()
			if now - envLightLastTintUpdate >= 0.5 then
				envLightLastTintUpdate = now
				applyEnvLightTint(envLightSampleTint())
			end
		end)
	end

	-- Block camera zoom + scroll-to-scale when mouse wheel is over a glass panel
	ContextActionService:BindActionAtPriority("MangoBlockScroll", function(_actionName, inputState, inputObject)
		-- Accept both Begin and Change for MouseWheel (behavior varies by Roblox version)
		if inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
			return Enum.ContextActionResult.Pass
		end
		if inputObject.UserInputType ~= Enum.UserInputType.MouseWheel then return Enum.ContextActionResult.Pass end
		local mousePos = UserInputService:GetMouseLocation()

		-- Sink scroll events over the carousel dock (prevent camera zoom; actual scroll handled by InputChanged)
		if carouselDockFrame then
			local dAbsPos = carouselDockFrame.AbsolutePosition
			local dAbsSize = carouselDockFrame.AbsoluteSize
			if mousePos.X >= dAbsPos.X and mousePos.X <= dAbsPos.X + dAbsSize.X
				and mousePos.Y >= dAbsPos.Y and mousePos.Y <= dAbsPos.Y + dAbsSize.Y then
				return Enum.ContextActionResult.Sink
			end
		end

		-- Pass scroll events to Settings tab ScrollingFrame when active
		if currentTab == 4 and mainGlass then
			local mainAbsPos = mainGlass.Container.AbsolutePosition
			local mainAbsSize = mainGlass.Container.AbsoluteSize
			if mousePos.X >= mainAbsPos.X and mousePos.X <= mainAbsPos.X + mainAbsSize.X
				and mousePos.Y >= mainAbsPos.Y and mousePos.Y <= mainAbsPos.Y + mainAbsSize.Y then
				return Enum.ContextActionResult.Pass
			end
		end

		-- Sink scroll events over glass panels (prevent camera zoom) but don't scale
		for _, entry in glassFrames do
			if entry.Container then
				local absPos = entry.Container.AbsolutePosition
				local absSize = entry.Container.AbsoluteSize
				if mousePos.X >= absPos.X and mousePos.X <= absPos.X + absSize.X
					and mousePos.Y >= absPos.Y and mousePos.Y <= absPos.Y + absSize.Y then
					return Enum.ContextActionResult.Sink
				end
			end
		end
		return Enum.ContextActionResult.Pass
	end, false, 3000, Enum.UserInputType.MouseWheel)

	rebuildGradientCache()

	-- ================================================================
	-- Reopener button (outside masterContainer, top-center of screen)
	-- ================================================================
	local reopener = Instance.new("Frame")
	reopener.Name = "ReopenerButton"
	reopener.Size = UDim2.new(0, 120, 0, 32)
	reopener.Position = UDim2.new(0.5, 0, 0, 8)
	reopener.AnchorPoint = Vector2.new(0.5, 0)
	reopener.BackgroundColor3 = theme.BackgroundColor3
	reopener.BackgroundTransparency = 0.3
	reopener.BorderSizePixel = 0
	reopener.ZIndex = 10
	reopener.Visible = not isUIVisible
	reopener.Parent = gui

	local reopenerCorner = Instance.new("UICorner")
	reopenerCorner.CornerRadius = UDim.new(0, 16)
	reopenerCorner.Parent = reopener

	local reopenerStroke = Instance.new("UIStroke")
	reopenerStroke.Color = theme.StrokeColor
	reopenerStroke.Transparency = 0.7
	reopenerStroke.Thickness = 1
	reopenerStroke.Parent = reopener

	local reopenerLabel = Instance.new("TextLabel")
	reopenerLabel.Text = "MangoUI \226\150\190"
	reopenerLabel.Font = Enum.Font.GothamMedium
	reopenerLabel.TextSize = 13
	reopenerLabel.TextColor3 = theme.PrimaryTextColor
	reopenerLabel.BackgroundTransparency = 1
	reopenerLabel.Size = UDim2.fromScale(1, 1)
	reopenerLabel.TextXAlignment = Enum.TextXAlignment.Center
	reopenerLabel.TextYAlignment = Enum.TextYAlignment.Center
	reopenerLabel.BorderSizePixel = 0
	reopenerLabel.ZIndex = 10
	reopenerLabel.Parent = reopener

	local reopenerHit = Instance.new("TextButton")
	reopenerHit.Size = UDim2.fromScale(1, 1)
	reopenerHit.BackgroundTransparency = 1
	reopenerHit.Text = ""
	reopenerHit.ZIndex = 100
	reopenerHit.AutoButtonColor = false
	reopenerHit.Parent = reopener

	-- Set masterContainer visibility based on state
	masterContainer.Visible = isUIVisible

	-- Exit button click handler
	table.insert(panelConnections, exitBtn.MouseButton1Click:Connect(function()
		if not isUIVisible then return end
		isUIVisible = false
		-- Materialization dismiss: shadow → surface → specular
		local dismissInfo = TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		for _, glass in glassFrames do
			for _, layer in glass.ShadowLayers do
				TweenService:Create(layer, dismissInfo, { BackgroundTransparency = 1 }):Play()
			end
		end
		task.delay(0.04, function()
			for _, glass in glassFrames do
				TweenService:Create(glass.GlassSurface, TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play()
			end
		end)
		TweenService:Create(masterScale, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 0.95 }):Play()
		task.delay(0.15, function()
			masterContainer.Visible = false
			-- Show reopener with slide-down
			reopener.Visible = true
			reopener.Position = UDim2.new(0.5, 0, 0, -40)
			TweenService:Create(reopener, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Position = UDim2.new(0.5, 0, 0, 8)
			}):Play()
		end)
	end))

	-- Reopener click handler
	table.insert(panelConnections, reopenerHit.MouseButton1Click:Connect(function()
		if isUIVisible then return end
		isUIVisible = true
		-- Hide reopener (slide up)
		TweenService:Create(reopener, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, 0, 0, -40)
		}):Play()
		task.delay(0.1, function()
			reopener.Visible = false
		end)
		-- Show masterContainer and animate in
		masterContainer.Visible = true
		masterScale.Scale = 0.95
		TweenService:Create(masterScale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		-- Materialize in: specular → surface → shadow
		for _, glass in glassFrames do
			local targetSurfaceTrans = glass.GlassSurface.BackgroundTransparency
			local targetShadowTrans: {number} = {}
			for i, layer in glass.ShadowLayers do
				targetShadowTrans[i] = layer.BackgroundTransparency
				layer.BackgroundTransparency = 1
			end
			glass.GlassSurface.BackgroundTransparency = 1
			task.delay(0.03, function()
				TweenService:Create(glass.GlassSurface, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = targetSurfaceTrans }):Play()
			end)
			for i, layer in glass.ShadowLayers do
				local t = targetShadowTrans[i]
				task.delay(0.08, function()
					TweenService:Create(layer, TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = t }):Play()
				end)
			end
		end
	end))

	-- ================================================================
	-- Viewport-responsive panel scaling
	-- ================================================================
	local function adaptToViewport()
		local cam = Workspace.CurrentCamera
		if not cam or not mainGlass then return end
		local vp = cam.ViewportSize
		if vp.X == 0 or vp.Y == 0 then return end
		local maxW = math.floor(vp.X * 0.85)
		local maxH = math.floor(vp.Y * 0.85)
		local panelW = math.clamp(math.min(ORIGINAL_WIDTH, maxW), MIN_WIDTH, MAX_WIDTH)
		local panelH = math.clamp(math.min(ORIGINAL_HEIGHT, maxH), MIN_HEIGHT, MAX_HEIGHT)
		mainGlass.Container.Size = UDim2.new(0, panelW, 0, panelH)
		contentScale.Scale = math.min(panelW / ORIGINAL_WIDTH, (panelH - 60) / (ORIGINAL_HEIGHT - 60))
		if updateDockPosition then updateDockPosition() end
	end

	local cam = Workspace.CurrentCamera
	if cam then
		table.insert(panelConnections, cam:GetPropertyChangedSignal("ViewportSize"):Connect(adaptToViewport))
		adaptToViewport()
	end

	-- Materialize in: specular → surface → shadow (Apple's materialization principle)
	-- On theme switch, glass properties animate in sequence rather than appearing uniformly
	if isThemeSwitching then
		for _, glass in glassFrames do
			-- Save target transparencies
			local targetSurfaceTrans = glass.GlassSurface.BackgroundTransparency
			local targetShadowTransparencies: {number} = {}
			for i, layer in glass.ShadowLayers do
				targetShadowTransparencies[i] = layer.BackgroundTransparency
				layer.BackgroundTransparency = 1
			end
			glass.GlassSurface.BackgroundTransparency = 1
			-- Phase 1: Specular rim appears first (already visible via UIGradient from buildUI)
			-- Phase 2: Surface materializes (0.03s delay, 0.08s duration)
			task.delay(0.03, function()
				TweenService:Create(glass.GlassSurface, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = targetSurfaceTrans }):Play()
			end)
			-- Phase 3: Shadows ground the element (0.08s delay, 0.07s duration)
			for i, layer in glass.ShadowLayers do
				local targetTrans = targetShadowTransparencies[i]
				task.delay(0.08, function()
					TweenService:Create(layer, TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = targetTrans }):Play()
				end)
			end
		end
	end

	isThemeSwitching = false
end

--------------------------------------------------------------------------------
-- Startup: Intro animation then build UI with fade-in
--------------------------------------------------------------------------------

createBackgroundScene()

playIntroAnimation(function()
	buildUI()

	-- Fade in the demo UI
	local gui = screenGui
	if gui then
		local fadeOverlay = Instance.new("Frame")
		fadeOverlay.Name = "FadeOverlay"
		fadeOverlay.Size = UDim2.new(1, 0, 1, 0)
		fadeOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		fadeOverlay.BackgroundTransparency = 0
		fadeOverlay.BorderSizePixel = 0
		fadeOverlay.ZIndex = 200
		fadeOverlay.Parent = gui

		local fadeInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local fadeTween = TweenService:Create(fadeOverlay, fadeInfo, { BackgroundTransparency = 1 })
		fadeTween:Play()
		fadeTween.Completed:Connect(function()
			fadeOverlay:Destroy()
		end)
	end
end)

player.AncestryChanged:Connect(function()
	if not player:IsDescendantOf(game) then
		destroyAllUI()
		destroyBackgroundScene()
	end
end)
