--!strict

local TweenService = game:GetService("TweenService")

local Types = require(script.Parent.Types)
local Themes = require(script.Parent.Themes)
local MangoHaptics = require(script.Parent.MangoHaptics)
local resolve = Themes.resolve

local module = {}

function module.new(config: Types.MangoToggleConfig): Types.MangoToggle
	local scale = resolve(config.Scale, nil, 1) :: number
	local theme = config.Theme
	local initialState = resolve(config.InitialState, nil, false) :: boolean

	-- Track colors
	local onTrackColor = resolve(nil, theme and theme.ToggleOnTrackColor, Color3.fromRGB(52, 199, 89)) :: Color3
	local offTrackColor = resolve(nil, theme and theme.ToggleOffTrackColor, Color3.fromRGB(200, 200, 200)) :: Color3
	local knobColor = resolve(nil, theme and theme.ToggleKnobColor, Color3.fromRGB(255, 255, 255)) :: Color3

	-- Stroke/fresnel from theme (matching glass)
	local strokeColor = resolve(nil, theme and theme.StrokeColor, Color3.fromRGB(255, 255, 255)) :: Color3
	local fresnelStart = resolve(nil, theme and theme.FresnelStartTransparency, 0.30) :: number
	local fresnelEnd = resolve(nil, theme and theme.FresnelEndTransparency, 0.95) :: number
	local fresnelMid = resolve(nil, theme and theme.FresnelMidTransparency, 0.55) :: number
	local fresnelMidPoint = resolve(nil, theme and theme.FresnelMidPoint, 0.35) :: number

	-- Dimensions (all scaled)
	local containerWidth = math.floor(51 * scale)
	local containerHeight = math.floor(31 * scale)
	local knobSize = math.floor(27 * scale)
	local knobShadowSize = math.floor(29 * scale)

	-- State
	local isOn: boolean = initialState
	local activeTweens: { Tween } = {}
	local inputConnection: RBXScriptConnection? = nil

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
	-- Container
	-- ============================================================
	local container = Instance.new("Frame")
	container.Name = "MangoToggle"
	container.Size = UDim2.new(0, containerWidth, 0, containerHeight)
	container.Position = config.Position
	container.AnchorPoint = resolve(config.AnchorPoint, nil, Vector2.new(0, 0)) :: Vector2
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0

	-- ============================================================
	-- TrackShadow1 (outer, subtle)
	-- ============================================================
	local trackShadow1 = Instance.new("Frame")
	trackShadow1.Name = "TrackShadow1"
	trackShadow1.AnchorPoint = Vector2.new(0.5, 0.5)
	trackShadow1.Position = UDim2.new(0.5, 0, 0.5, math.floor(1 * scale))
	trackShadow1.Size = UDim2.new(1, math.floor(4 * scale), 1, math.floor(4 * scale))
	trackShadow1.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	trackShadow1.BackgroundTransparency = 0.92
	trackShadow1.BorderSizePixel = 0
	trackShadow1.ZIndex = 0
	trackShadow1.Parent = container

	local trackShadow1Corner = Instance.new("UICorner")
	trackShadow1Corner.CornerRadius = UDim.new(0, 999)
	trackShadow1Corner.Parent = trackShadow1

	-- ============================================================
	-- TrackShadow2 (tighter)
	-- ============================================================
	local trackShadow2 = Instance.new("Frame")
	trackShadow2.Name = "TrackShadow2"
	trackShadow2.AnchorPoint = Vector2.new(0.5, 0.5)
	trackShadow2.Position = UDim2.new(0.5, 0, 0.5, math.floor(1 * scale))
	trackShadow2.Size = UDim2.new(1, math.floor(2 * scale), 1, math.floor(2 * scale))
	trackShadow2.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	trackShadow2.BackgroundTransparency = 0.84
	trackShadow2.BorderSizePixel = 0
	trackShadow2.ZIndex = 0
	trackShadow2.Parent = container

	local trackShadow2Corner = Instance.new("UICorner")
	trackShadow2Corner.CornerRadius = UDim.new(0, 999)
	trackShadow2Corner.Parent = trackShadow2

	-- ============================================================
	-- TrackSurface (pill shape)
	-- ============================================================
	local trackSurface = Instance.new("Frame")
	trackSurface.Name = "TrackSurface"
	trackSurface.Size = UDim2.new(1, 0, 1, 0)
	trackSurface.BackgroundColor3 = if isOn then onTrackColor else offTrackColor
	trackSurface.BackgroundTransparency = 0
	trackSurface.BorderSizePixel = 0
	trackSurface.ZIndex = 1
	trackSurface.Parent = container

	local trackSurfaceCorner = Instance.new("UICorner")
	trackSurfaceCorner.CornerRadius = UDim.new(0, 999)
	trackSurfaceCorner.Parent = trackSurface

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
	trackSpecularStroke.Thickness = math.floor(1 * scale)
	trackSpecularStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	trackSpecularStroke.Parent = trackSpecularFrame

	local trackSpecularGradient = Instance.new("UIGradient")
	trackSpecularGradient.Rotation = 90
	trackSpecularGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, fresnelStart),
		NumberSequenceKeypoint.new(fresnelMidPoint, fresnelMid),
		NumberSequenceKeypoint.new(1, fresnelEnd),
	})
	trackSpecularGradient.Parent = trackSpecularStroke

	-- ============================================================
	-- KnobContainer
	-- ============================================================
	local knobContainer = Instance.new("Frame")
	knobContainer.Name = "KnobContainer"
	knobContainer.Size = UDim2.new(0, knobSize, 0, knobSize)
	knobContainer.BackgroundTransparency = 1
	knobContainer.BorderSizePixel = 0
	knobContainer.ZIndex = 3
	knobContainer.Parent = container

	-- Set initial knob position (no animation)
	if isOn then
		knobContainer.AnchorPoint = Vector2.new(1, 0.5)
		knobContainer.Position = UDim2.new(1, -math.floor(2 * scale), 0.5, 0)
	else
		knobContainer.AnchorPoint = Vector2.new(0, 0.5)
		knobContainer.Position = UDim2.new(0, math.floor(2 * scale), 0.5, 0)
	end

	-- KnobShadow
	local knobShadow = Instance.new("Frame")
	knobShadow.Name = "KnobShadow"
	knobShadow.AnchorPoint = Vector2.new(0.5, 0.5)
	knobShadow.Position = UDim2.new(0.5, 0, 0.5, 0)
	knobShadow.Size = UDim2.new(0, knobShadowSize, 0, knobShadowSize)
	knobShadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	knobShadow.BackgroundTransparency = 0.85
	knobShadow.BorderSizePixel = 0
	knobShadow.ZIndex = 0
	knobShadow.Parent = knobContainer

	local knobShadowCorner = Instance.new("UICorner")
	knobShadowCorner.CornerRadius = UDim.new(0, 999)
	knobShadowCorner.Parent = knobShadow

	-- KnobSurface
	local knobSurface = Instance.new("Frame")
	knobSurface.Name = "KnobSurface"
	knobSurface.AnchorPoint = Vector2.new(0.5, 0.5)
	knobSurface.Position = UDim2.new(0.5, 0, 0.5, 0)
	knobSurface.Size = UDim2.new(0, knobSize, 0, knobSize)
	knobSurface.BackgroundColor3 = knobColor
	knobSurface.BackgroundTransparency = 0
	knobSurface.BorderSizePixel = 0
	knobSurface.ZIndex = 1
	knobSurface.Parent = knobContainer

	local knobSurfaceCorner = Instance.new("UICorner")
	knobSurfaceCorner.CornerRadius = UDim.new(0, 999)
	knobSurfaceCorner.Parent = knobSurface

	-- KnobHighlight (top inner glow)
	local knobHighlight = Instance.new("Frame")
	knobHighlight.Name = "KnobHighlight"
	knobHighlight.Size = UDim2.new(1, 0, 0.4, 0)
	knobHighlight.Position = UDim2.new(0, 0, 0, 0)
	knobHighlight.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	knobHighlight.BackgroundTransparency = 0.7
	knobHighlight.BorderSizePixel = 0
	knobHighlight.ZIndex = 2
	knobHighlight.Parent = knobSurface

	local knobHighlightCorner = Instance.new("UICorner")
	knobHighlightCorner.CornerRadius = UDim.new(0, 999)
	knobHighlightCorner.Parent = knobHighlight

	local knobHighlightGradient = Instance.new("UIGradient")
	knobHighlightGradient.Rotation = 90
	knobHighlightGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	knobHighlightGradient.Parent = knobHighlight

	-- KnobSpecularFrame
	local knobSpecularFrame = Instance.new("Frame")
	knobSpecularFrame.Name = "KnobSpecularFrame"
	knobSpecularFrame.Size = UDim2.new(1, 0, 1, 0)
	knobSpecularFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	knobSpecularFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	knobSpecularFrame.BackgroundTransparency = 1
	knobSpecularFrame.BorderSizePixel = 0
	knobSpecularFrame.ZIndex = 2
	knobSpecularFrame.Parent = knobSurface

	local knobSpecularCorner = Instance.new("UICorner")
	knobSpecularCorner.CornerRadius = UDim.new(0, 999)
	knobSpecularCorner.Parent = knobSpecularFrame

	local knobSpecularStroke = Instance.new("UIStroke")
	knobSpecularStroke.Color = strokeColor
	knobSpecularStroke.Thickness = math.floor(1 * scale)
	knobSpecularStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	knobSpecularStroke.Parent = knobSpecularFrame

	local knobSpecularGradient = Instance.new("UIGradient")
	knobSpecularGradient.Rotation = 90
	knobSpecularGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, fresnelStart + 0.1),
		NumberSequenceKeypoint.new(fresnelMidPoint, fresnelMid + 0.05),
		NumberSequenceKeypoint.new(1, fresnelEnd),
	})
	knobSpecularGradient.Parent = knobSpecularStroke

	-- ============================================================
	-- Animation
	-- ============================================================
	local function animateToState(state: boolean)
		cancelAllTweens()

		-- Knob position: 0.25s, Back, Out
		local knobTweenInfo = TweenInfo.new(
			0.25,
			Enum.EasingStyle.Back,
			Enum.EasingDirection.Out,
			0,
			false,
			0
		)

		-- Track color: 0.2s, Quad, Out
		local trackTweenInfo = TweenInfo.new(
			0.2,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out,
			0,
			false,
			0
		)

		if state then
			-- Animate knob to ON position
			local anchorTween = TweenService:Create(knobContainer, knobTweenInfo, {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -math.floor(2 * scale), 0.5, 0),
			})
			trackTween(anchorTween)
			anchorTween:Play()

			-- Animate track to ON color
			local colorTween = TweenService:Create(trackSurface, trackTweenInfo, {
				BackgroundColor3 = onTrackColor,
			})
			trackTween(colorTween)
			colorTween:Play()
		else
			-- Animate knob to OFF position
			local anchorTween = TweenService:Create(knobContainer, knobTweenInfo, {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, math.floor(2 * scale), 0.5, 0),
			})
			trackTween(anchorTween)
			anchorTween:Play()

			-- Animate track to OFF color
			local colorTween = TweenService:Create(trackSurface, trackTweenInfo, {
				BackgroundColor3 = offTrackColor,
			})
			trackTween(colorTween)
			colorTween:Play()
		end
	end

	-- ============================================================
	-- Hit Area (transparent TextButton for reliable input on transparent container)
	-- ============================================================
	local hitArea = Instance.new("TextButton")
	hitArea.Name = "HitArea"
	hitArea.Size = UDim2.new(1, 0, 1, 0)
	hitArea.BackgroundTransparency = 1
	hitArea.BorderSizePixel = 0
	hitArea.Text = ""
	hitArea.AutoButtonColor = false
	hitArea.ZIndex = 100
	hitArea.Parent = container

	-- ============================================================
	-- Input Handling
	-- ============================================================
	inputConnection = hitArea.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			isOn = not isOn
			MangoHaptics.light()
			animateToState(isOn)
			if config.OnToggled then
				config.OnToggled(isOn)
			end
		end
	end)

	-- ============================================================
	-- Parent assignment
	-- ============================================================
	if config.Parent then
		container.Parent = config.Parent
	end

	-- ============================================================
	-- Return table
	-- ============================================================
	local self: Types.MangoToggle = {
		Container = container,
		SetState = function(self: Types.MangoToggle, state: boolean)
			isOn = state
			animateToState(isOn)
		end,
		GetState = function(self: Types.MangoToggle): boolean
			return isOn
		end,
		Destroy = function(self: Types.MangoToggle)
			cancelAllTweens()
			if inputConnection then
				(inputConnection :: RBXScriptConnection):Disconnect()
				inputConnection = nil
			end
			container:Destroy()
		end,
	}

	return self
end

return module
