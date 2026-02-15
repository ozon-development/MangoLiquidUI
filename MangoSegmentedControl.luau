--!strict

local Types = require(script.Parent.Types)
local Themes = require(script.Parent.Themes)
local resolve = Themes.resolve
local MangoProtection = require(script.Parent.MangoProtection)
local TweenService = game:GetService("TweenService")

local module = {}

function module.new(config: Types.MangoSegmentedControlConfig): Types.MangoSegmentedControl
	local theme = config.Theme
	local segments = resolve(config.Segments, nil, {"Tab 1", "Tab 2"}) :: {string}
	local segmentCount = #segments

	-- Resolve config values
	local segmentWidth = resolve(config.SegmentWidth, nil, 90) :: number
	local height = resolve(config.Height, nil, 36) :: number
	local initialIndex = resolve(config.InitialIndex, nil, 1) :: number
	local anchorPoint = resolve(config.AnchorPoint, nil, Vector2.new(0, 0)) :: Vector2
	local position = resolve(config.Position, nil, UDim2.new(0, 0, 0, 0)) :: UDim2

	-- Theme values
	local bgTransparency = resolve(nil, theme and theme.SegmentedBackgroundTransparency, 0.88) :: number
	local selectedTransparency = resolve(nil, theme and theme.SegmentedSelectedTransparency, 0.72) :: number
	local selectedColor = resolve(nil, theme and theme.SegmentedSelectedColor, Color3.fromRGB(255, 255, 255)) :: Color3
	local bgColor = resolve(nil, theme and theme.BackgroundColor3, Color3.fromRGB(255, 255, 255)) :: Color3
	local primaryText = resolve(nil, theme and theme.PrimaryTextColor, Color3.fromRGB(0, 0, 0)) :: Color3
	local secondaryText = resolve(nil, theme and theme.SecondaryTextColor, Color3.fromRGB(60, 60, 70)) :: Color3
	local strokeColor = resolve(nil, theme and theme.StrokeColor, Color3.fromRGB(255, 255, 255)) :: Color3
	local fresnelStart = resolve(nil, theme and theme.FresnelStartTransparency, 0.25) :: number
	local fresnelMid = resolve(nil, theme and theme.FresnelMidTransparency, 0.50) :: number
	local fresnelMidPoint = resolve(nil, theme and theme.FresnelMidPoint, 0.35) :: number
	local fresnelEnd = resolve(nil, theme and theme.FresnelEndTransparency, 0.95) :: number

	-- State
	local currentIndex: number = math.clamp(initialIndex, 1, segmentCount)
	local activeTweens: {Tween} = {}
	local connections: {RBXScriptConnection} = {}

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

	-- OuterWrapper (no ClipsDescendants, holds size/position, receives OuterSpecularFrame)
	local totalWidth = segmentWidth * segmentCount
	local outerWrapper = Instance.new("Frame")
	outerWrapper.Name = MangoProtection.randomName("SegControl")
	outerWrapper.Size = UDim2.new(0, totalWidth, 0, height)
	outerWrapper.Position = position
	outerWrapper.AnchorPoint = anchorPoint
	outerWrapper.BackgroundTransparency = 1
	outerWrapper.BorderSizePixel = 0

	-- Container (pill shape, clips descendants for sliding indicator)
	local container = Instance.new("Frame")
	container.Name = "InnerContainer"
	container.Size = UDim2.new(1, 0, 1, 0)
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0
	container.ClipsDescendants = true
	container.Parent = outerWrapper

	-- BackgroundGlass (glass tint background)
	local backgroundGlass = Instance.new("Frame")
	backgroundGlass.Name = "BackgroundGlass"
	backgroundGlass.Size = UDim2.new(1, 0, 1, 0)
	backgroundGlass.BackgroundColor3 = bgColor
	backgroundGlass.BackgroundTransparency = bgTransparency
	backgroundGlass.BorderSizePixel = 0
	backgroundGlass.ZIndex = 0
	backgroundGlass.Parent = container

	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(0, 999)
	bgCorner.Parent = backgroundGlass

	-- SelectedIndicator (sliding glass pill)
	local selectedIndicator = Instance.new("Frame")
	selectedIndicator.Name = "SelectedIndicator"
	selectedIndicator.Size = UDim2.new(0, segmentWidth, 1, -4)
	selectedIndicator.Position = UDim2.new(0, (currentIndex - 1) * segmentWidth + 2, 0.5, 0)
	selectedIndicator.AnchorPoint = Vector2.new(0, 0.5)
	selectedIndicator.BackgroundColor3 = selectedColor
	selectedIndicator.BackgroundTransparency = selectedTransparency
	selectedIndicator.BorderSizePixel = 0
	selectedIndicator.ZIndex = 1
	selectedIndicator.Parent = container

	local indicatorCorner = Instance.new("UICorner")
	indicatorCorner.CornerRadius = UDim.new(0, 999)
	indicatorCorner.Parent = selectedIndicator

	-- Indicator specular frame
	local indicatorSpecFrame = Instance.new("Frame")
	indicatorSpecFrame.Name = "SpecularFrame"
	indicatorSpecFrame.Size = UDim2.new(1, 0, 1, 0)
	indicatorSpecFrame.BackgroundTransparency = 1
	indicatorSpecFrame.BorderSizePixel = 0
	indicatorSpecFrame.ZIndex = 2
	indicatorSpecFrame.Parent = selectedIndicator

	local indicatorSpecCorner = Instance.new("UICorner")
	indicatorSpecCorner.CornerRadius = UDim.new(0, 999)
	indicatorSpecCorner.Parent = indicatorSpecFrame

	local indicatorSpecStroke = Instance.new("UIStroke")
	indicatorSpecStroke.Name = "SpecularStroke"
	indicatorSpecStroke.Color = strokeColor
	indicatorSpecStroke.Thickness = 1
	indicatorSpecStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	indicatorSpecStroke.Parent = indicatorSpecFrame

	local indicatorSpecGradient = Instance.new("UIGradient")
	indicatorSpecGradient.Name = "SpecularGradient"
	indicatorSpecGradient.Rotation = 90
	indicatorSpecGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, fresnelStart + 0.05),
		NumberSequenceKeypoint.new(fresnelMidPoint, fresnelMid + 0.05),
		NumberSequenceKeypoint.new(1, fresnelEnd),
	})
	indicatorSpecGradient.Parent = indicatorSpecStroke

	-- Segment buttons
	local segmentButtons: {TextButton} = {}
	local segmentLabels: {TextButton} = {} -- reuse for color tweening

	for i = 1, segmentCount do
		local btn = Instance.new("TextButton")
		btn.Name = "Segment" .. i
		btn.Size = UDim2.new(0, segmentWidth, 1, 0)
		btn.Position = UDim2.new(0, (i - 1) * segmentWidth, 0, 0)
		btn.BackgroundTransparency = 1
		btn.BorderSizePixel = 0
		btn.Text = segments[i]
		btn.Font = Enum.Font.GothamMedium
		btn.TextSize = 14
		btn.TextColor3 = if i == currentIndex then primaryText else secondaryText
		btn.ZIndex = 10
		btn.AutoButtonColor = false
		btn.Parent = container

		table.insert(segmentButtons, btn)
		table.insert(segmentLabels, btn)
	end

	-- Outer specular frame (rim on entire container)
	local outerSpecFrame = Instance.new("Frame")
	outerSpecFrame.Name = "OuterSpecularFrame"
	outerSpecFrame.Size = UDim2.new(1, 0, 1, 0)
	outerSpecFrame.BackgroundTransparency = 1
	outerSpecFrame.BorderSizePixel = 0
	outerSpecFrame.ZIndex = 11
	outerSpecFrame.Parent = outerWrapper

	local outerSpecCorner = Instance.new("UICorner")
	outerSpecCorner.CornerRadius = UDim.new(0, 999)
	outerSpecCorner.Parent = outerSpecFrame

	local outerSpecStroke = Instance.new("UIStroke")
	outerSpecStroke.Name = "OuterSpecularStroke"
	outerSpecStroke.Color = strokeColor
	outerSpecStroke.Thickness = 1
	outerSpecStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	outerSpecStroke.Parent = outerSpecFrame

	local outerSpecGradient = Instance.new("UIGradient")
	outerSpecGradient.Name = "OuterSpecularGradient"
	outerSpecGradient.Rotation = 90
	outerSpecGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, fresnelStart + 0.10),
		NumberSequenceKeypoint.new(fresnelMidPoint, fresnelMid + 0.10),
		NumberSequenceKeypoint.new(1, fresnelEnd),
	})
	outerSpecGradient.Parent = outerSpecStroke

	-- Selection logic
	local function selectIndex(index: number)
		if index < 1 or index > segmentCount then
			return
		end
		cancelAllTweens()
		currentIndex = index

		-- Slide indicator
		local slideInfo = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		local slideTween = TweenService:Create(selectedIndicator, slideInfo, {
			Position = UDim2.new(0, (index - 1) * segmentWidth + 2, 0.5, 0),
		})
		trackTween(slideTween)
		slideTween:Play()

		-- Update text colors
		local colorInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		for i, btn in segmentLabels do
			local targetColor = if i == index then primaryText else secondaryText
			local colorTween = TweenService:Create(btn, colorInfo, {
				TextColor3 = targetColor,
			})
			trackTween(colorTween)
			colorTween:Play()
		end
	end

	-- Wire click handlers
	for i, btn in segmentButtons do
		local conn = btn.MouseButton1Click:Connect(function()
			if currentIndex ~= i then
				selectIndex(i)
				if config.OnChanged then
					config.OnChanged(i)
				end
			end
		end)
		table.insert(connections, conn)
	end

	-- Parent assignment
	if config.Parent then
		outerWrapper.Parent = config.Parent
	end

	-- Return table
	local self: Types.MangoSegmentedControl = {
		Container = outerWrapper,
		SetIndex = function(self: Types.MangoSegmentedControl, index: number)
			selectIndex(index)
		end,
		GetIndex = function(self: Types.MangoSegmentedControl): number
			return currentIndex
		end,
		Destroy = function(self: Types.MangoSegmentedControl)
			cancelAllTweens()
			for _, conn in connections do
				conn:Disconnect()
			end
			table.clear(connections)
			outerWrapper:Destroy()
		end,
	}

	return self
end

return module
