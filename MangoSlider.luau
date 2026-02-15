--!strict

local Types = require(script.Parent.Types)
local Themes = require(script.Parent.Themes)
local MangoHaptics = require(script.Parent.MangoHaptics)
local resolve = Themes.resolve
local MangoProtection = require(script.Parent.MangoProtection)
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local module = {}

local function makeSmoothTweenInfo(duration: number): TweenInfo
	return TweenInfo.new(
		duration,
		Enum.EasingStyle.Back,
		Enum.EasingDirection.Out,
		0,
		false,
		0
	)
end

function module.new(config: Types.MangoSliderConfig): Types.MangoSlider
	local theme = config.Theme

	-- Resolve all config values with nil-safe helper
	local size = resolve(config.Size, nil, UDim2.new(0, 200, 0, 36)) :: UDim2
	local position = resolve(config.Position, nil, UDim2.new(0, 0, 0, 0)) :: UDim2
	local anchorPoint = resolve(config.AnchorPoint, nil, Vector2.new(0, 0)) :: Vector2
	local minVal = resolve(config.Min, nil, 0) :: number
	local maxVal = resolve(config.Max, nil, 1) :: number
	local step = resolve(config.Step, nil, 0) :: number
	local initialValue = resolve(config.InitialValue, nil, minVal) :: number

	local trackColor = resolve(nil, theme and theme.SliderTrackColor, Color3.fromRGB(220, 220, 225)) :: Color3
	local trackTransparency = resolve(nil, theme and theme.SliderTrackTransparency, 0.50) :: number
	local fillColor = resolve(nil, theme and theme.SliderFillColor, Color3.fromRGB(0, 122, 255)) :: Color3
	local thumbColor = resolve(nil, theme and theme.SliderThumbColor, Color3.fromRGB(255, 255, 255)) :: Color3
	local strokeColor = resolve(nil, theme and theme.StrokeColor, Color3.fromRGB(255, 255, 255)) :: Color3
	local fresnelStart = resolve(nil, theme and theme.FresnelStartTransparency, 0.30) :: number
	local fresnelMid = resolve(nil, theme and theme.FresnelMidTransparency, 0.55) :: number
	local fresnelMidPoint = resolve(nil, theme and theme.FresnelMidPoint, 0.35) :: number
	local fresnelEnd = resolve(nil, theme and theme.FresnelEndTransparency, 0.95) :: number

	-- State
	local currentValue: number = math.clamp(initialValue, minVal, maxVal)
	local isDragging = false
	local isDestroyed = false
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

	-- ============================================================
	-- Instance Hierarchy
	-- ============================================================

	-- Container (transparent wrapper)
	local container = Instance.new("Frame")
	container.Name = MangoProtection.randomName("Slider")
	container.Size = size
	container.Position = position
	container.AnchorPoint = anchorPoint
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0

	-- Shadow visibility
	local shadowEnabled = resolve(config.ShadowEnabled, nil, true) :: boolean

	-- TrackShadow1 (outer, subtle shadow — fixed transparency)
	local trackShadow1 = Instance.new("Frame")
	trackShadow1.Name = "TrackShadow1"
	trackShadow1.AnchorPoint = Vector2.new(0.5, 0.5)
	trackShadow1.Position = UDim2.new(0.5, 0, 0.5, 1)
	trackShadow1.Size = UDim2.new(1, 6, 0, 14)
	trackShadow1.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	trackShadow1.BackgroundTransparency = 0.86
	trackShadow1.BorderSizePixel = 0
	trackShadow1.ZIndex = 0
	trackShadow1.Visible = shadowEnabled
	trackShadow1.Parent = container

	local trackShadow1Corner = Instance.new("UICorner")
	trackShadow1Corner.CornerRadius = UDim.new(0, 999)
	trackShadow1Corner.Parent = trackShadow1

	-- TrackShadow2 (inner, tighter shadow — fixed transparency)
	local trackShadow2 = Instance.new("Frame")
	trackShadow2.Name = "TrackShadow2"
	trackShadow2.AnchorPoint = Vector2.new(0, 0.5)
	trackShadow2.Position = UDim2.new(0, -1.5, 0.5, 0.5)
	trackShadow2.Size = UDim2.new(1, 3, 0, 11)
	trackShadow2.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	trackShadow2.BackgroundTransparency = 0.82
	trackShadow2.BorderSizePixel = 0
	trackShadow2.ZIndex = 0
	trackShadow2.Visible = shadowEnabled
	trackShadow2.Parent = container

	local trackShadow2Corner = Instance.new("UICorner")
	trackShadow2Corner.CornerRadius = UDim.new(0, 999)
	trackShadow2Corner.Parent = trackShadow2

	-- TrackSurface (6px tall glass-like pill, centered vertically)
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

	local trackSurfaceCorner = Instance.new("UICorner")
	trackSurfaceCorner.CornerRadius = UDim.new(0, 999)
	trackSurfaceCorner.Parent = trackSurface

	-- FillFrame (colored fill, anchored left, width = value fraction)
	local valueFraction = if (maxVal - minVal) > 0 then (currentValue - minVal) / (maxVal - minVal) else 0
	local fillFrame = Instance.new("Frame")
	fillFrame.Name = "FillFrame"
	fillFrame.Size = UDim2.new(valueFraction, 0, 1, 0)
	fillFrame.Position = UDim2.new(0, 0, 0, 0)
	fillFrame.AnchorPoint = Vector2.new(0, 0)
	fillFrame.BackgroundColor3 = fillColor
	local fillTransparency = resolve(nil, theme and theme.SliderFillTransparency, 0.40) :: number
	fillFrame.BackgroundTransparency = fillTransparency
	fillFrame.BorderSizePixel = 0
	fillFrame.ZIndex = 1
	fillFrame.ClipsDescendants = true
	fillFrame.Parent = trackSurface

	local fillFrameCorner = Instance.new("UICorner")
	fillFrameCorner.CornerRadius = UDim.new(0, 999)
	fillFrameCorner.Parent = fillFrame

	-- FillHighlight (glass capsule appearance for accent fill)
	local fillHighlight = Instance.new("Frame")
	fillHighlight.Name = "FillHighlight"
	fillHighlight.Size = UDim2.new(1, 0, 0.5, 0)
	fillHighlight.Position = UDim2.new(0, 0, 0, 0)
	fillHighlight.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	fillHighlight.BackgroundTransparency = 0.88
	fillHighlight.BorderSizePixel = 0
	fillHighlight.ZIndex = 2
	fillHighlight.Parent = fillFrame

	local fillHighlightGradient = Instance.new("UIGradient")
	fillHighlightGradient.Name = "FillHighlightGradient"
	fillHighlightGradient.Rotation = 90
	fillHighlightGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	fillHighlightGradient.Parent = fillHighlight

	-- TrackSpecularFrame (outside trackSurface to avoid ClipsDescendants clipping the Border-mode stroke)
	local trackSpecularFrame = Instance.new("Frame")
	trackSpecularFrame.Name = "TrackSpecularFrame"
	trackSpecularFrame.Size = UDim2.new(1, 0, 0, 6)
	trackSpecularFrame.Position = UDim2.new(0, 0, 0.5, 0)
	trackSpecularFrame.AnchorPoint = Vector2.new(0, 0.5)
	trackSpecularFrame.BackgroundTransparency = 1
	trackSpecularFrame.BorderSizePixel = 0
	trackSpecularFrame.ZIndex = 2
	trackSpecularFrame.Parent = container

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
	local innerEdgeColor = resolve(nil, theme and theme.InnerEdgeColor, Color3.fromRGB(255, 255, 255)) :: Color3
	local innerEdgeTop = resolve(nil, theme and theme.InnerEdgeTopTransparency, 0.35) :: number
	local innerEdgeMid = resolve(nil, theme and theme.InnerEdgeMidTransparency, 0.72) :: number
	local innerEdgeBottom = resolve(nil, theme and theme.InnerEdgeBottomTransparency, 0.92) :: number

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

	-- ThumbContainer (positioned by value)
	local thumbContainer = Instance.new("Frame")
	thumbContainer.Name = "ThumbContainer"
	thumbContainer.Size = UDim2.new(0, 28, 0, 28)
	thumbContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	thumbContainer.Position = UDim2.new(valueFraction, 0, 0.5, 0)
	thumbContainer.BackgroundTransparency = 1
	thumbContainer.BorderSizePixel = 0
	thumbContainer.ZIndex = 3
	thumbContainer.Parent = container

	-- ThumbShadow (outer, behind thumb — grows on drag)
	local thumbShadow = Instance.new("Frame")
	thumbShadow.Name = "ThumbShadow"
	thumbShadow.Size = UDim2.new(0, 30, 0, 30)
	thumbShadow.AnchorPoint = Vector2.new(0.5, 0.5)
	thumbShadow.Position = UDim2.new(0.5, 0, 0.5, 1)
	thumbShadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	thumbShadow.BackgroundTransparency = 0.85
	thumbShadow.BorderSizePixel = 0
	thumbShadow.ZIndex = 0
	thumbShadow.Parent = thumbContainer

	local thumbShadowCorner = Instance.new("UICorner")
	thumbShadowCorner.CornerRadius = UDim.new(0, 999)
	thumbShadowCorner.Parent = thumbShadow

	-- ThumbSurface (28x28 circle, white — grows on drag)
	local thumbSurface = Instance.new("Frame")
	thumbSurface.Name = "ThumbSurface"
	thumbSurface.Size = UDim2.new(0, 28, 0, 28)
	thumbSurface.AnchorPoint = Vector2.new(0.5, 0.5)
	thumbSurface.Position = UDim2.new(0.5, 0, 0.5, 0)
	thumbSurface.BackgroundColor3 = thumbColor
	thumbSurface.BackgroundTransparency = 0
	thumbSurface.BorderSizePixel = 0
	thumbSurface.ZIndex = 1
	thumbSurface.Parent = thumbContainer

	local thumbSurfaceCorner = Instance.new("UICorner")
	thumbSurfaceCorner.CornerRadius = UDim.new(0, 999)
	thumbSurfaceCorner.Parent = thumbSurface

	local thumbStroke = Instance.new("UIStroke")
	thumbStroke.Color = Color3.fromRGB(200, 200, 205)
	thumbStroke.Thickness = 0.5
	thumbStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	thumbStroke.Transparency = 0.4
	thumbStroke.Parent = thumbSurface

	-- ============================================================
	-- Drag Logic
	-- ============================================================

	-- Helper: compute value from absolute X position
	local function valueFromX(absX: number): number
		local trackLeft = container.AbsolutePosition.X
		local trackWidth = container.AbsoluteSize.X
		local fraction = math.clamp((absX - trackLeft) / trackWidth, 0, 1)
		local rawValue = minVal + fraction * (maxVal - minVal)
		if step > 0 then
			rawValue = math.round(rawValue / step) * step
		end
		return math.clamp(rawValue, minVal, maxVal)
	end

	-- Helper: update visual position from current value
	local function updateVisual()
		local fraction = if (maxVal - minVal) > 0 then (currentValue - minVal) / (maxVal - minVal) else 0
		-- Edge-snap: prevent sub-pixel rounding artifacts at 0% and 100%
		if fraction >= 0.995 then fraction = 1 end
		if fraction <= 0.005 then fraction = 0 end
		fillFrame.Size = UDim2.new(fraction, 0, 1, 0)
		thumbContainer.Position = UDim2.new(fraction, 0, 0.5, 0)
	end

	-- Helper: apply value and fire callback
	local function applyValue(newValue: number)
		local oldValue = currentValue
		currentValue = newValue
		updateVisual()
		if oldValue ~= newValue and config.OnChanged then
			config.OnChanged(newValue)
		end
	end

	-- Thumb grow on drag start
	local function growThumb()
		local growInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		trackTween(TweenService:Create(thumbSurface, growInfo, {
			Size = UDim2.new(0, 34, 0, 34),
		})):Play()
		trackTween(TweenService:Create(thumbShadow, growInfo, {
			Size = UDim2.new(0, 38, 0, 38),
			BackgroundTransparency = 0.72,
		})):Play()
	end

	-- Thumb shrink on drag end
	local function shrinkThumb()
		local shrinkInfo = makeSmoothTweenInfo(0.3)
		trackTween(TweenService:Create(thumbSurface, shrinkInfo, {
			Size = UDim2.new(0, 28, 0, 28),
		})):Play()
		trackTween(TweenService:Create(thumbShadow, shrinkInfo, {
			Size = UDim2.new(0, 30, 0, 30),
			BackgroundTransparency = 0.85,
		})):Play()
	end

	-- Transparent hit areas for reliable input (child elements block parent InputBegan)
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

	-- Start drag from thumb
	local thumbInputBeganConn = thumbHitArea.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			isDragging = true
			MangoHaptics.light()
			growThumb()
		end
	end)
	table.insert(connections, thumbInputBeganConn)

	-- Start drag from track (tap-to-seek)
	local trackInputBeganConn = trackHitArea.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			isDragging = true
			local newValue = valueFromX(input.Position.X)
			applyValue(newValue)
			growThumb()
		end
	end)
	table.insert(connections, trackInputBeganConn)

	-- Track drag globally via UserInputService.InputChanged
	local inputChangedConn = UserInputService.InputChanged:Connect(function(input: InputObject)
		if isDestroyed or not isDragging then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			local newValue = valueFromX(input.Position.X)
			applyValue(newValue)
		end
	end)
	table.insert(connections, inputChangedConn)

	-- End drag on UserInputService.InputEnded
	local inputEndedConn = UserInputService.InputEnded:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			if isDragging then
				isDragging = false

				-- Shrink thumb back and elastic settle
				shrinkThumb()
				local fraction = if (maxVal - minVal) > 0 then (currentValue - minVal) / (maxVal - minVal) else 0
				local settleInfo = makeSmoothTweenInfo(0.25)
				local settleTween = TweenService:Create(thumbContainer, settleInfo, {
					Position = UDim2.new(fraction, 0, 0.5, 0),
				})
				trackTween(settleTween)
				settleTween:Play()
			end
		end
	end)
	table.insert(connections, inputEndedConn)

	-- ============================================================
	-- Parent Assignment
	-- ============================================================

	if config.Parent then
		container.Parent = config.Parent
	end

	-- Set initial value and visual at construction time (no animation)
	updateVisual()

	-- ============================================================
	-- Return Table
	-- ============================================================

	local self: Types.MangoSlider = {
		Container = container,
		SetValue = function(self: Types.MangoSlider, value: number)
			currentValue = math.clamp(value, minVal, maxVal)
			updateVisual()
		end,
		GetValue = function(self: Types.MangoSlider): number
			return currentValue
		end,
		Destroy = function(self: Types.MangoSlider)
			if isDestroyed then return end
			isDestroyed = true
			isDragging = false
			for _, conn in connections do
				conn:Disconnect()
			end
			table.clear(connections)
			cancelAllTweens()
			container:Destroy()
		end,
	}

	return self
end

return module
