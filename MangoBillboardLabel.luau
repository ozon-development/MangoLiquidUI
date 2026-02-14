--!strict

local Types = require(script.Parent.Types)
local Themes = require(script.Parent.Themes)
local resolve = Themes.resolve
local TextService = game:GetService("TextService")

local module = {}

function module.new(config: Types.MangoBillboardLabelConfig): Types.MangoBillboardLabel
	-- Determine target part
	local targetPart: BasePart? = config.TargetPart
	if not targetPart and config.TargetCharacter then
		targetPart = config.TargetCharacter:FindFirstChild("Head") :: BasePart?
	end

	-- Resolve config values with nil-safe helper
	local theme = config.Theme
	local text = config.Text
	local textSize = resolve(config.TextSize, nil, 14) :: number
	local maxDistance = resolve(config.MaxDistance, nil, 50) :: number
	local studsOffset = resolve(config.StudsOffset, nil, Vector3.new(0, 2.2, 0)) :: Vector3
	local alwaysOnTop = resolve(config.AlwaysOnTop, nil, false) :: boolean

	-- Theme-driven visual properties
	local bgColor = resolve(nil, theme and theme.BackgroundColor3, Color3.fromRGB(255, 255, 255)) :: Color3
	local bgTransparency = resolve(nil, theme and theme.BackgroundTransparency, 0.78) :: number
	-- Override for billboard readability - more opaque than panels
	bgTransparency = math.max(0, bgTransparency - 0.15)
	local textColor = resolve(nil, theme and theme.PrimaryTextColor, Color3.fromRGB(0, 0, 0)) :: Color3
	local strokeColor = resolve(nil, theme and theme.StrokeColor, Color3.fromRGB(255, 255, 255)) :: Color3
	local shadowColor = resolve(nil, theme and theme.ShadowColor, Color3.fromRGB(0, 0, 0)) :: Color3
	local innerGlowColor = resolve(nil, theme and theme.InnerGlowColor, Color3.fromRGB(255, 255, 255)) :: Color3
	local innerGlowTransparency = resolve(nil, theme and theme.InnerGlowTransparency, 0.65) :: number
	local innerEdgeColor = resolve(nil, theme and theme.InnerEdgeColor, Color3.fromRGB(255, 255, 255)) :: Color3
	local innerEdgeTop = resolve(nil, theme and theme.InnerEdgeTopTransparency, 0.35) :: number
	local innerEdgeMid = resolve(nil, theme and theme.InnerEdgeMidTransparency, 0.72) :: number
	local innerEdgeBottom = resolve(nil, theme and theme.InnerEdgeBottomTransparency, 0.92) :: number
	local fresnelStart = resolve(nil, theme and theme.FresnelStartTransparency, 0.30) :: number
	local fresnelEnd = resolve(nil, theme and theme.FresnelEndTransparency, 0.95) :: number
	local fresnelMid = resolve(nil, theme and theme.FresnelMidTransparency, 0.55) :: number
	local fresnelMidPoint = resolve(nil, theme and theme.FresnelMidPoint, 0.35) :: number

	-- Auto-size based on text measurement
	local font = Enum.Font.GothamMedium
	local textBounds = TextService:GetTextSize(text, textSize, font, Vector2.new(500, 100))
	local containerWidth = textBounds.X + 28
	local containerHeight = textBounds.Y + 14

	-- BillboardGui
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Name = "MangoBillboardLabel"
	billboardGui.Size = UDim2.new(0, containerWidth, 0, containerHeight)
	billboardGui.MaxDistance = maxDistance
	billboardGui.StudsOffset = studsOffset
	billboardGui.AlwaysOnTop = alwaysOnTop
	billboardGui.Active = false
	billboardGui.ResetOnSpawn = false
	if targetPart then
		billboardGui.Adornee = targetPart
	end

	-- Container (transparent wrapper, full size)
	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.new(1, 0, 1, 0)
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0
	container.Parent = billboardGui

	-- ShadowLayer1 (outer, larger spread)
	local shadowLayer1 = Instance.new("Frame")
	shadowLayer1.Name = "ShadowLayer1"
	shadowLayer1.AnchorPoint = Vector2.new(0.5, 0.5)
	shadowLayer1.Position = UDim2.new(0.5, 0, 0.5, 1)
	shadowLayer1.Size = UDim2.new(1, 8, 1, 8)
	shadowLayer1.BackgroundColor3 = shadowColor
	shadowLayer1.BackgroundTransparency = 0.88
	shadowLayer1.BorderSizePixel = 0
	shadowLayer1.ZIndex = 0
	shadowLayer1.Parent = container

	local shadowCorner1 = Instance.new("UICorner")
	shadowCorner1.CornerRadius = UDim.new(0, 999)
	shadowCorner1.Parent = shadowLayer1

	-- ShadowLayer2 (inner, tighter spread)
	local shadowLayer2 = Instance.new("Frame")
	shadowLayer2.Name = "ShadowLayer2"
	shadowLayer2.AnchorPoint = Vector2.new(0.5, 0.5)
	shadowLayer2.Position = UDim2.new(0.5, 0, 0.5, 1.5)
	shadowLayer2.Size = UDim2.new(1, 5, 1, 5)
	shadowLayer2.BackgroundColor3 = shadowColor
	shadowLayer2.BackgroundTransparency = 0.86
	shadowLayer2.BorderSizePixel = 0
	shadowLayer2.ZIndex = 0
	shadowLayer2.Parent = container

	local shadowCorner2 = Instance.new("UICorner")
	shadowCorner2.CornerRadius = UDim.new(0, 999)
	shadowCorner2.Parent = shadowLayer2

	-- GlassSurface (pill shape, clipping inner frame)
	local glassSurface = Instance.new("Frame")
	glassSurface.Name = "GlassSurface"
	glassSurface.Size = UDim2.new(1, 0, 1, 0)
	glassSurface.BackgroundColor3 = bgColor
	glassSurface.BackgroundTransparency = bgTransparency
	glassSurface.ClipsDescendants = true
	glassSurface.BorderSizePixel = 0
	glassSurface.ZIndex = 1
	glassSurface.Parent = container

	local glassCorner = Instance.new("UICorner")
	glassCorner.CornerRadius = UDim.new(0, 999)
	glassCorner.Parent = glassSurface

	-- InnerHighlight (subtle top glow inside GlassSurface)
	local innerHighlight = Instance.new("Frame")
	innerHighlight.Name = "InnerHighlight"
	innerHighlight.Size = UDim2.new(1, 0, 0.4, 0)
	innerHighlight.Position = UDim2.new(0, 0, 0, 0)
	innerHighlight.BackgroundColor3 = innerGlowColor
	innerHighlight.BackgroundTransparency = innerGlowTransparency
	innerHighlight.BorderSizePixel = 0
	innerHighlight.ZIndex = 2
	innerHighlight.Parent = glassSurface

	local highlightCorner = Instance.new("UICorner")
	highlightCorner.CornerRadius = UDim.new(0, 999)
	highlightCorner.Parent = innerHighlight

	local highlightGradient = Instance.new("UIGradient")
	highlightGradient.Name = "HighlightGradient"
	highlightGradient.Rotation = 90
	highlightGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	highlightGradient.Parent = innerHighlight

	-- InnerEdgeHighlight (full-perimeter inner stroke inside GlassSurface)
	local innerEdgeFrame = Instance.new("Frame")
	innerEdgeFrame.Name = "InnerEdgeHighlight"
	innerEdgeFrame.Size = UDim2.new(1, 0, 1, 0)
	innerEdgeFrame.BackgroundTransparency = 1
	innerEdgeFrame.BorderSizePixel = 0
	innerEdgeFrame.ZIndex = 3
	innerEdgeFrame.Parent = glassSurface

	local innerEdgeCorner = Instance.new("UICorner")
	innerEdgeCorner.CornerRadius = UDim.new(0, 999)
	innerEdgeCorner.Parent = innerEdgeFrame

	local innerEdgeStroke = Instance.new("UIStroke")
	innerEdgeStroke.Name = "InnerEdgeStroke"
	innerEdgeStroke.Color = innerEdgeColor
	innerEdgeStroke.Thickness = 1
	innerEdgeStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	innerEdgeStroke.Parent = innerEdgeFrame

	local innerEdgeGradient = Instance.new("UIGradient")
	innerEdgeGradient.Name = "InnerEdgeGradient"
	innerEdgeGradient.Rotation = 90
	innerEdgeGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, math.min(1, innerEdgeTop + 0.05)),
		NumberSequenceKeypoint.new(0.5, math.min(1, innerEdgeMid + 0.03)),
		NumberSequenceKeypoint.new(1, innerEdgeBottom),
	})
	innerEdgeGradient.Parent = innerEdgeStroke

	-- LabelText (centered text inside GlassSurface)
	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "LabelText"
	textLabel.Text = text
	textLabel.Font = font
	textLabel.TextSize = textSize
	textLabel.TextColor3 = textColor
	textLabel.BackgroundTransparency = 1
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.TextXAlignment = Enum.TextXAlignment.Center
	textLabel.TextYAlignment = Enum.TextYAlignment.Center
	textLabel.BorderSizePixel = 0
	textLabel.ZIndex = 10
	textLabel.Parent = glassSurface

	-- SpecularFrame (outside clip boundary, child of Container)
	local specularFrame = Instance.new("Frame")
	specularFrame.Name = "SpecularFrame"
	specularFrame.Size = UDim2.new(1, 0, 1, 0)
	specularFrame.BackgroundTransparency = 1
	specularFrame.BorderSizePixel = 0
	specularFrame.ZIndex = 2
	specularFrame.Parent = container

	local specularCorner = Instance.new("UICorner")
	specularCorner.CornerRadius = UDim.new(0, 999)
	specularCorner.Parent = specularFrame

	local specularStroke = Instance.new("UIStroke")
	specularStroke.Name = "SpecularStroke"
	specularStroke.Color = strokeColor
	specularStroke.Thickness = 1
	specularStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	specularStroke.Parent = specularFrame

	local specularGradient = Instance.new("UIGradient")
	specularGradient.Name = "SpecularGradient"
	specularGradient.Rotation = 90
	specularGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, math.min(1, fresnelStart + 0.03)),
		NumberSequenceKeypoint.new(fresnelMidPoint, math.min(1, fresnelMid + 0.02)),
		NumberSequenceKeypoint.new(1, fresnelEnd),
	})
	specularGradient.Parent = specularStroke

	-- Parent assignment
	if config.Parent then
		billboardGui.Parent = config.Parent
	elseif targetPart then
		billboardGui.Parent = targetPart
	end

	-- Return typed table
	local self: Types.MangoBillboardLabel = {
		BillboardGui = billboardGui,
		GlassSurface = glassSurface,
		TextLabel = textLabel,
		SetText = function(self: Types.MangoBillboardLabel, newText: string)
			textLabel.Text = newText
			local newBounds = TextService:GetTextSize(newText, textSize, font, Vector2.new(500, 100))
			local newWidth = newBounds.X + 28
			local newHeight = newBounds.Y + 14
			billboardGui.Size = UDim2.new(0, newWidth, 0, newHeight)
		end,
		Destroy = function(self: Types.MangoBillboardLabel)
			billboardGui:Destroy()
		end,
	}

	return self
end

return module
