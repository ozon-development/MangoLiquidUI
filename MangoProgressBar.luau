--!strict

local Types = require(script.Parent.Types)
local Themes = require(script.Parent.Themes)
local resolve = Themes.resolve
local TweenService = game:GetService("TweenService")

local module = {}

function module.new(config: Types.MangoProgressBarConfig): Types.MangoProgressBar
	local theme = config.Theme

	-- Resolve config values
	local size = resolve(config.Size, nil, UDim2.new(0, 200, 0, 20)) :: UDim2
	local position = config.Position
	local anchorPoint = resolve(config.AnchorPoint, nil, Vector2.new(0, 0)) :: Vector2
	local initialValue = resolve(config.InitialValue, nil, 0) :: number

	-- Theme values
	local trackColor = resolve(nil, theme and theme.SliderTrackColor, Color3.fromRGB(220, 220, 225)) :: Color3
	local trackTransparency = resolve(nil, theme and theme.ProgressBarTrackTransparency, 0.85) :: number
	local fillColor = resolve(nil, theme and theme.ProgressBarFillColor, Color3.fromRGB(0, 122, 255)) :: Color3
	local fillTransparency = resolve(nil, theme and theme.ProgressBarFillTransparency, 0.30) :: number
	local strokeColor = resolve(nil, theme and theme.StrokeColor, Color3.fromRGB(255, 255, 255)) :: Color3
	local fresnelStart = resolve(nil, theme and theme.FresnelStartTransparency, 0.25) :: number
	local fresnelMid = resolve(nil, theme and theme.FresnelMidTransparency, 0.50) :: number
	local fresnelMidPoint = resolve(nil, theme and theme.FresnelMidPoint, 0.35) :: number
	local fresnelEnd = resolve(nil, theme and theme.FresnelEndTransparency, 0.95) :: number
	local innerEdgeColor = resolve(nil, theme and theme.InnerEdgeColor, Color3.fromRGB(255, 255, 255)) :: Color3
	local innerEdgeTop = resolve(nil, theme and theme.InnerEdgeTopTransparency, 0.35) :: number
	local innerEdgeMid = resolve(nil, theme and theme.InnerEdgeMidTransparency, 0.72) :: number
	local innerEdgeBottom = resolve(nil, theme and theme.InnerEdgeBottomTransparency, 0.92) :: number
	local shadowColor = resolve(nil, theme and theme.ShadowColor, Color3.fromRGB(0, 0, 0)) :: Color3

	-- State
	local currentValue: number = math.clamp(initialValue, 0, 1)
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

	-- Container
	local container = Instance.new("Frame")
	container.Name = "MangoProgressBar"
	container.Size = size
	container.Position = position
	container.AnchorPoint = anchorPoint
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0

	-- Shadow layer 1 (outer)
	local shadow1 = Instance.new("Frame")
	shadow1.Name = "ShadowLayer1"
	shadow1.AnchorPoint = Vector2.new(0.5, 0.5)
	shadow1.Position = UDim2.new(0.5, 0, 0.5, 1)
	shadow1.Size = UDim2.new(1, 8, 0, 12)
	shadow1.BackgroundColor3 = shadowColor
	shadow1.BackgroundTransparency = 0.88
	shadow1.BorderSizePixel = 0
	shadow1.ZIndex = 0
	shadow1.Parent = container

	local shadow1Corner = Instance.new("UICorner")
	shadow1Corner.CornerRadius = UDim.new(0, 999)
	shadow1Corner.Parent = shadow1

	-- Shadow layer 2 (inner)
	local shadow2 = Instance.new("Frame")
	shadow2.Name = "ShadowLayer2"
	shadow2.AnchorPoint = Vector2.new(0.5, 0.5)
	shadow2.Position = UDim2.new(0.5, 0, 0.5, 0.5)
	shadow2.Size = UDim2.new(1, 4, 0, 10)
	shadow2.BackgroundColor3 = shadowColor
	shadow2.BackgroundTransparency = 0.84
	shadow2.BorderSizePixel = 0
	shadow2.ZIndex = 0
	shadow2.Parent = container

	local shadow2Corner = Instance.new("UICorner")
	shadow2Corner.CornerRadius = UDim.new(0, 999)
	shadow2Corner.Parent = shadow2

	-- TrackSurface (6px tall pill, centered vertically)
	local trackSurface = Instance.new("Frame")
	trackSurface.Name = "TrackSurface"
	trackSurface.Size = UDim2.new(1, 0, 0, 6)
	trackSurface.Position = UDim2.new(0, 0, 0.5, 0)
	trackSurface.AnchorPoint = Vector2.new(0, 0.5)
	trackSurface.BackgroundColor3 = trackColor
	trackSurface.BackgroundTransparency = trackTransparency
	trackSurface.ClipsDescendants = true
	trackSurface.BorderSizePixel = 0
	trackSurface.ZIndex = 1
	trackSurface.Parent = container

	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(0, 999)
	trackCorner.Parent = trackSurface

	-- FillFrame (width = value fraction)
	local fillFrame = Instance.new("Frame")
	fillFrame.Name = "FillFrame"
	fillFrame.Size = UDim2.new(currentValue, 0, 1, 0)
	fillFrame.Position = UDim2.new(0, 0, 0, 0)
	fillFrame.AnchorPoint = Vector2.new(0, 0)
	fillFrame.BackgroundColor3 = fillColor
	fillFrame.BackgroundTransparency = fillTransparency
	fillFrame.BorderSizePixel = 0
	fillFrame.ZIndex = 1
	fillFrame.Parent = trackSurface

	-- FillHighlight (glass capsule appearance)
	local fillHighlight = Instance.new("Frame")
	fillHighlight.Name = "FillHighlight"
	fillHighlight.Size = UDim2.new(1, 0, 0.5, 0)
	fillHighlight.Position = UDim2.new(0, 0, 0, 0)
	fillHighlight.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	fillHighlight.BackgroundTransparency = 0.88
	fillHighlight.BorderSizePixel = 0
	fillHighlight.ZIndex = 2
	fillHighlight.Parent = fillFrame

	local fillHighlightCorner = Instance.new("UICorner")
	fillHighlightCorner.CornerRadius = UDim.new(1, 0)
	fillHighlightCorner.Parent = fillHighlight

	local fillHighlightGradient = Instance.new("UIGradient")
	fillHighlightGradient.Name = "FillHighlightGradient"
	fillHighlightGradient.Rotation = 90
	fillHighlightGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	fillHighlightGradient.Parent = fillHighlight

	-- TrackSpecularFrame (specular rim on track)
	local trackSpecularFrame = Instance.new("Frame")
	trackSpecularFrame.Name = "TrackSpecularFrame"
	trackSpecularFrame.Size = UDim2.new(1, 0, 1, 0)
	trackSpecularFrame.BackgroundTransparency = 1
	trackSpecularFrame.BorderSizePixel = 0
	trackSpecularFrame.ZIndex = 2
	trackSpecularFrame.Parent = trackSurface

	local trackSpecularCorner = Instance.new("UICorner")
	trackSpecularCorner.CornerRadius = UDim.new(0, 999)
	trackSpecularCorner.Parent = trackSpecularFrame

	local trackSpecularStroke = Instance.new("UIStroke")
	trackSpecularStroke.Name = "TrackSpecularStroke"
	trackSpecularStroke.Color = strokeColor
	trackSpecularStroke.Thickness = 1
	trackSpecularStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	trackSpecularStroke.Parent = trackSpecularFrame

	local trackSpecularGradient = Instance.new("UIGradient")
	trackSpecularGradient.Name = "TrackSpecularGradient"
	trackSpecularGradient.Rotation = 90
	trackSpecularGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, fresnelStart),
		NumberSequenceKeypoint.new(fresnelMidPoint, fresnelMid),
		NumberSequenceKeypoint.new(1, fresnelEnd),
	})
	trackSpecularGradient.Parent = trackSpecularStroke

	-- Track inner edge (recessed look via Border stroke inside ClipsDescendants)
	local trackInnerEdgeFrame = Instance.new("Frame")
	trackInnerEdgeFrame.Name = "TrackInnerEdgeFrame"
	trackInnerEdgeFrame.Size = UDim2.new(1, 0, 1, 0)
	trackInnerEdgeFrame.BackgroundTransparency = 1
	trackInnerEdgeFrame.BorderSizePixel = 0
	trackInnerEdgeFrame.ZIndex = 3
	trackInnerEdgeFrame.Parent = trackSurface

	local trackInnerEdgeCorner = Instance.new("UICorner")
	trackInnerEdgeCorner.CornerRadius = UDim.new(0, 999)
	trackInnerEdgeCorner.Parent = trackInnerEdgeFrame

	local trackInnerEdgeStroke = Instance.new("UIStroke")
	trackInnerEdgeStroke.Name = "TrackInnerEdgeStroke"
	trackInnerEdgeStroke.Color = innerEdgeColor
	trackInnerEdgeStroke.Thickness = 1
	trackInnerEdgeStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	trackInnerEdgeStroke.Parent = trackInnerEdgeFrame

	local trackInnerEdgeGradient = Instance.new("UIGradient")
	trackInnerEdgeGradient.Name = "TrackInnerEdgeGradient"
	trackInnerEdgeGradient.Rotation = 90
	trackInnerEdgeGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, innerEdgeTop + 0.20),
		NumberSequenceKeypoint.new(0.5, innerEdgeMid + 0.10),
		NumberSequenceKeypoint.new(1, innerEdgeBottom),
	})
	trackInnerEdgeGradient.Parent = trackInnerEdgeStroke

	-- Parent assignment
	if config.Parent then
		container.Parent = config.Parent
	end

	-- Return table
	local self: Types.MangoProgressBar = {
		Container = container,
		SetValue = function(self: Types.MangoProgressBar, value: number)
			local clamped = math.clamp(value, 0, 1)
			currentValue = clamped
			cancelAllTweens()
			local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			local tween = TweenService:Create(fillFrame, tweenInfo, {
				Size = UDim2.new(clamped, 0, 1, 0),
			})
			trackTween(tween)
			tween:Play()
		end,
		GetValue = function(self: Types.MangoProgressBar): number
			return currentValue
		end,
		Destroy = function(self: Types.MangoProgressBar)
			cancelAllTweens()
			container:Destroy()
		end,
	}

	return self
end

return module
