--!strict

local Types = require(script.Parent.Types)
local Themes = require(script.Parent.Themes)
local MangoGlassFrame = require(script.Parent.MangoGlassFrame)
local resolve = Themes.resolve
local MangoProtection = require(script.Parent.MangoProtection)
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local module = {}

function module.new(config: Types.MangoColorPickerConfig): Types.MangoColorPicker
	local theme = config.Theme

	-- Resolve all config values with nil-safe helper
	local size = resolve(config.Size, nil, UDim2.new(0, 260, 0, 200)) :: UDim2
	local position = resolve(config.Position, nil, UDim2.new(0, 0, 0, 0)) :: UDim2
	local anchorPoint = resolve(config.AnchorPoint, nil, Vector2.new(0, 0)) :: Vector2
	local initialColor = resolve(config.InitialColor, nil, Color3.fromRGB(255, 0, 0)) :: Color3
	local cursorColor = resolve(nil, theme and theme.ColorPickerCursorColor, Color3.fromRGB(255, 255, 255)) :: Color3
	local secondaryTextColor = resolve(nil, theme and theme.SecondaryTextColor, Color3.fromRGB(60, 60, 70)) :: Color3

	-- HSV state (0-1 each)
	local h: number, s: number, v: number = Color3.toHSV(initialColor)
	local isDraggingSB = false
	local isDraggingHue = false
	local connections: {RBXScriptConnection} = {}
	local activeTweens: {Tween} = {}

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

	local function currentColor(): Color3
		return Color3.fromHSV(h, s, v)
	end

	local function toHex(color: Color3): string
		local r = math.floor(color.R * 255 + 0.5)
		local g = math.floor(color.G * 255 + 0.5)
		local b = math.floor(color.B * 255 + 0.5)
		return string.format("#%02X%02X%02X", r, g, b)
	end

	-- ============================================================
	-- Instance Hierarchy
	-- ============================================================

	-- Container (transparent wrapper)
	local container = Instance.new("Frame")
	container.Name = MangoProtection.randomName("ColorPicker")
	container.Size = size
	container.Position = position
	container.AnchorPoint = anchorPoint
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0

	-- Glass background via MangoGlassFrame
	local glass = MangoGlassFrame.new({
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		CornerRadius = UDim.new(0, 12),
		LightweightMode = true,
		ShadowLayerCount = 2,
		Theme = theme,
		Parent = container,
	})

	-- UIPadding inside GlassSurface
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.Parent = glass.GlassSurface

	-- ============================================================
	-- Saturation-Brightness Box
	-- ============================================================

	local satBrightBox = Instance.new("Frame")
	satBrightBox.Name = "SatBrightBox"
	satBrightBox.Size = UDim2.new(1, 0, 0, 140)
	satBrightBox.Position = UDim2.new(0, 0, 0, 0)
	satBrightBox.BackgroundTransparency = 1
	satBrightBox.ClipsDescendants = true
	satBrightBox.BorderSizePixel = 0
	satBrightBox.ZIndex = 2
	satBrightBox.Parent = glass.GlassSurface

	local sbCorner = Instance.new("UICorner")
	sbCorner.CornerRadius = UDim.new(0, 6)
	sbCorner.Parent = satBrightBox

	-- HueBase: solid hue color background
	local hueBase = Instance.new("Frame")
	hueBase.Name = "HueBase"
	hueBase.Size = UDim2.new(1, 0, 1, 0)
	hueBase.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
	hueBase.BackgroundTransparency = 0
	hueBase.BorderSizePixel = 0
	hueBase.ZIndex = 2
	hueBase.Parent = satBrightBox

	-- SatOverlay: white gradient left-to-right (white -> transparent)
	local satOverlay = Instance.new("Frame")
	satOverlay.Name = "SatOverlay"
	satOverlay.Size = UDim2.new(1, 0, 1, 0)
	satOverlay.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	satOverlay.BackgroundTransparency = 0
	satOverlay.BorderSizePixel = 0
	satOverlay.ZIndex = 3
	satOverlay.Parent = satBrightBox

	local satGradient = Instance.new("UIGradient")
	satGradient.Name = "SatGradient"
	satGradient.Rotation = 0
	satGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	satGradient.Parent = satOverlay

	-- BrightOverlay: black gradient top-to-bottom (transparent -> black)
	local brightOverlay = Instance.new("Frame")
	brightOverlay.Name = "BrightOverlay"
	brightOverlay.Size = UDim2.new(1, 0, 1, 0)
	brightOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	brightOverlay.BackgroundTransparency = 0
	brightOverlay.BorderSizePixel = 0
	brightOverlay.ZIndex = 4
	brightOverlay.Parent = satBrightBox

	local brightGradient = Instance.new("UIGradient")
	brightGradient.Name = "BrightGradient"
	brightGradient.Rotation = 90
	brightGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0),
	})
	brightGradient.Parent = brightOverlay

	-- SB Cursor (12x12 circle with white stroke)
	local sbCursor = Instance.new("Frame")
	sbCursor.Name = "Cursor"
	sbCursor.Size = UDim2.new(0, 12, 0, 12)
	sbCursor.AnchorPoint = Vector2.new(0.5, 0.5)
	sbCursor.Position = UDim2.new(s, 0, 1 - v, 0)
	sbCursor.BackgroundColor3 = currentColor()
	sbCursor.BackgroundTransparency = 0
	sbCursor.BorderSizePixel = 0
	sbCursor.ZIndex = 15
	sbCursor.Parent = satBrightBox

	local sbCursorCorner = Instance.new("UICorner")
	sbCursorCorner.CornerRadius = UDim.new(0, 999)
	sbCursorCorner.Parent = sbCursor

	local sbCursorStroke = Instance.new("UIStroke")
	sbCursorStroke.Color = cursorColor
	sbCursorStroke.Thickness = 2
	sbCursorStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	sbCursorStroke.Parent = sbCursor

	-- SB HitArea
	local sbHitArea = Instance.new("TextButton")
	sbHitArea.Name = "SBHitArea"
	sbHitArea.Size = UDim2.new(1, 0, 1, 0)
	sbHitArea.BackgroundTransparency = 1
	sbHitArea.Text = ""
	sbHitArea.BorderSizePixel = 0
	sbHitArea.ZIndex = 100
	sbHitArea.AutoButtonColor = false
	sbHitArea.Parent = satBrightBox

	-- ============================================================
	-- Hue Bar
	-- ============================================================

	local hueBar = Instance.new("Frame")
	hueBar.Name = "HueBar"
	hueBar.Size = UDim2.new(1, 0, 0, 16)
	hueBar.Position = UDim2.new(0, 0, 0, 146)
	hueBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	hueBar.BackgroundTransparency = 0
	hueBar.BorderSizePixel = 0
	hueBar.ZIndex = 2
	hueBar.Parent = glass.GlassSurface

	local hueBarCorner = Instance.new("UICorner")
	hueBarCorner.CornerRadius = UDim.new(0, 8)
	hueBarCorner.Parent = hueBar

	-- Rainbow gradient (7-point HSV spectrum)
	local rainbowGradient = Instance.new("UIGradient")
	rainbowGradient.Name = "RainbowGradient"
	rainbowGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.000, Color3.fromHSV(0 / 6, 1, 1)),
		ColorSequenceKeypoint.new(0.167, Color3.fromHSV(1 / 6, 1, 1)),
		ColorSequenceKeypoint.new(0.333, Color3.fromHSV(2 / 6, 1, 1)),
		ColorSequenceKeypoint.new(0.500, Color3.fromHSV(3 / 6, 1, 1)),
		ColorSequenceKeypoint.new(0.667, Color3.fromHSV(4 / 6, 1, 1)),
		ColorSequenceKeypoint.new(0.833, Color3.fromHSV(5 / 6, 1, 1)),
		ColorSequenceKeypoint.new(1.000, Color3.fromHSV(6 / 6, 1, 1)),
	})
	rainbowGradient.Parent = hueBar

	-- Hue slider handle (12x16 rounded white pill)
	local hueSlider = Instance.new("Frame")
	hueSlider.Name = "HueSlider"
	hueSlider.Size = UDim2.new(0, 12, 0, 16)
	hueSlider.AnchorPoint = Vector2.new(0.5, 0.5)
	hueSlider.Position = UDim2.new(h, 0, 0.5, 0)
	hueSlider.BackgroundColor3 = cursorColor
	hueSlider.BackgroundTransparency = 0
	hueSlider.BorderSizePixel = 0
	hueSlider.ZIndex = 15
	hueSlider.Parent = hueBar

	local hueSliderCorner = Instance.new("UICorner")
	hueSliderCorner.CornerRadius = UDim.new(0, 6)
	hueSliderCorner.Parent = hueSlider

	local hueSliderStroke = Instance.new("UIStroke")
	hueSliderStroke.Color = Color3.fromRGB(200, 200, 205)
	hueSliderStroke.Thickness = 0.5
	hueSliderStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	hueSliderStroke.Transparency = 0.4
	hueSliderStroke.Parent = hueSlider

	-- Hue HitArea
	local hueHitArea = Instance.new("TextButton")
	hueHitArea.Name = "HueHitArea"
	hueHitArea.Size = UDim2.new(1, 0, 1, 0)
	hueHitArea.BackgroundTransparency = 1
	hueHitArea.Text = ""
	hueHitArea.BorderSizePixel = 0
	hueHitArea.ZIndex = 100
	hueHitArea.AutoButtonColor = false
	hueHitArea.Parent = hueBar

	-- ============================================================
	-- Preview Row
	-- ============================================================

	local previewRow = Instance.new("Frame")
	previewRow.Name = "PreviewRow"
	previewRow.Size = UDim2.new(1, 0, 0, 24)
	previewRow.Position = UDim2.new(0, 0, 0, 168)
	previewRow.BackgroundTransparency = 1
	previewRow.BorderSizePixel = 0
	previewRow.ZIndex = 2
	previewRow.Parent = glass.GlassSurface

	local previewLayout = Instance.new("UIListLayout")
	previewLayout.FillDirection = Enum.FillDirection.Horizontal
	previewLayout.SortOrder = Enum.SortOrder.LayoutOrder
	previewLayout.Padding = UDim.new(0, 8)
	previewLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	previewLayout.Parent = previewRow

	-- Color swatch circle
	local colorPreview = Instance.new("Frame")
	colorPreview.Name = "ColorPreview"
	colorPreview.Size = UDim2.new(0, 24, 0, 24)
	colorPreview.BackgroundColor3 = currentColor()
	colorPreview.BackgroundTransparency = 0
	colorPreview.BorderSizePixel = 0
	colorPreview.ZIndex = 2
	colorPreview.LayoutOrder = 1
	colorPreview.Parent = previewRow

	local previewCorner = Instance.new("UICorner")
	previewCorner.CornerRadius = UDim.new(0, 999)
	previewCorner.Parent = colorPreview

	local previewStroke = Instance.new("UIStroke")
	previewStroke.Color = Color3.fromRGB(200, 200, 205)
	previewStroke.Thickness = 0.5
	previewStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	previewStroke.Transparency = 0.4
	previewStroke.Parent = colorPreview

	-- Hex label
	local hexLabel = Instance.new("TextLabel")
	hexLabel.Name = "HexLabel"
	hexLabel.Size = UDim2.new(0, 80, 0, 24)
	hexLabel.BackgroundTransparency = 1
	hexLabel.BorderSizePixel = 0
	hexLabel.Font = Enum.Font.GothamMedium
	hexLabel.TextSize = 12
	hexLabel.TextColor3 = secondaryTextColor
	hexLabel.TextXAlignment = Enum.TextXAlignment.Left
	hexLabel.Text = toHex(currentColor())
	hexLabel.ZIndex = 2
	hexLabel.LayoutOrder = 2
	hexLabel.Parent = previewRow

	-- ============================================================
	-- Update Visuals
	-- ============================================================

	local function updateVisuals()
		local color = currentColor()
		-- SB box hue base
		hueBase.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
		-- SB cursor position and fill
		sbCursor.Position = UDim2.new(s, 0, 1 - v, 0)
		sbCursor.BackgroundColor3 = color
		-- Hue slider position
		hueSlider.Position = UDim2.new(h, 0, 0.5, 0)
		-- Preview swatch
		colorPreview.BackgroundColor3 = color
		-- Hex text
		hexLabel.Text = toHex(color)
	end

	-- ============================================================
	-- Drag Logic
	-- ============================================================

	-- SB box drag start
	local sbInputBeganConn = sbHitArea.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			isDraggingSB = true
			local boxPos = satBrightBox.AbsolutePosition
			local boxSize = satBrightBox.AbsoluteSize
			s = math.clamp((input.Position.X - boxPos.X) / boxSize.X, 0, 1)
			v = 1 - math.clamp((input.Position.Y - boxPos.Y) / boxSize.Y, 0, 1)
			updateVisuals()
			if config.OnChanged then
				config.OnChanged(currentColor())
			end
		end
	end)
	table.insert(connections, sbInputBeganConn)

	-- Hue bar drag start
	local hueInputBeganConn = hueHitArea.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			isDraggingHue = true
			local barPos = hueBar.AbsolutePosition
			local barWidth = hueBar.AbsoluteSize.X
			h = math.clamp((input.Position.X - barPos.X) / barWidth, 0, 1)
			updateVisuals()
			if config.OnChanged then
				config.OnChanged(currentColor())
			end
		end
	end)
	table.insert(connections, hueInputBeganConn)

	-- Global drag tracking via UserInputService.InputChanged
	local inputChangedConn = UserInputService.InputChanged:Connect(function(input: InputObject)
		if not isDraggingSB and not isDraggingHue then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			if isDraggingSB then
				local boxPos = satBrightBox.AbsolutePosition
				local boxSize = satBrightBox.AbsoluteSize
				s = math.clamp((input.Position.X - boxPos.X) / boxSize.X, 0, 1)
				v = 1 - math.clamp((input.Position.Y - boxPos.Y) / boxSize.Y, 0, 1)
			elseif isDraggingHue then
				local barPos = hueBar.AbsolutePosition
				local barWidth = hueBar.AbsoluteSize.X
				h = math.clamp((input.Position.X - barPos.X) / barWidth, 0, 1)
			end
			updateVisuals()
			if config.OnChanged then
				config.OnChanged(currentColor())
			end
		end
	end)
	table.insert(connections, inputChangedConn)

	-- End drag on UserInputService.InputEnded
	local inputEndedConn = UserInputService.InputEnded:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			isDraggingSB = false
			isDraggingHue = false
		end
	end)
	table.insert(connections, inputEndedConn)

	-- ============================================================
	-- Parent Assignment
	-- ============================================================

	if config.Parent then
		container.Parent = config.Parent
	end

	-- ============================================================
	-- Return Table
	-- ============================================================

	local self: Types.MangoColorPicker = {
		Container = container,
		GetColor = function(self: Types.MangoColorPicker): Color3
			return currentColor()
		end,
		SetColor = function(self: Types.MangoColorPicker, color: Color3)
			h, s, v = Color3.toHSV(color)
			updateVisuals()
		end,
		Destroy = function(self: Types.MangoColorPicker)
			for _, conn in connections do
				conn:Disconnect()
			end
			table.clear(connections)
			cancelAllTweens()
			glass:Destroy()
			container:Destroy()
		end,
	}

	return self
end

return module
