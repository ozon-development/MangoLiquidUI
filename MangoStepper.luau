--!strict

local TweenService = game:GetService("TweenService")

local Types = require(script.Parent.Types)
local Themes = require(script.Parent.Themes)
local MangoGlassFrame = require(script.Parent.MangoGlassFrame)
local resolve = Themes.resolve
local MangoProtection = require(script.Parent.MangoProtection)

local module = {}

function module.new(config: Types.MangoStepperConfig): Types.MangoStepper
	local theme = config.Theme

	local initialValue = resolve(config.InitialValue, nil, 0) :: number
	local minValue = resolve(config.Min, nil, 0) :: number
	local maxValue = resolve(config.Max, nil, 100) :: number
	local stepSize = resolve(config.Step, nil, 1) :: number
	local bgTransparency = resolve(nil, theme and theme.StepperBackgroundTransparency, 0.80) :: number

	local currentValue = math.clamp(initialValue, minValue, maxValue)

	-- Create MangoGlassFrame (pill, LightweightMode)
	local glassFrame = MangoGlassFrame.new({
		Size = UDim2.new(0, 120, 0, 36),
		Position = resolve(config.Position, nil, UDim2.new(0, 0, 0, 0)) :: UDim2,
		AnchorPoint = resolve(config.AnchorPoint, nil, Vector2.new(0, 0)) :: Vector2,
		CornerRadius = UDim.new(0, 999),
		BackgroundTransparency = bgTransparency,
		Theme = theme,
		ShadowEnabled = resolve(config.ShadowEnabled, nil, true) :: boolean,
		ShadowLayerCount = 2,
		ShadowSpread = 4,
		ShadowOffsetY = 1,
		LightweightMode = true,
		Parent = config.Parent,
	})

	local textColor = resolve(nil, theme and theme.PrimaryTextColor, Color3.fromRGB(0, 0, 0)) :: Color3

	-- Left separator (1px line between minus and value)
	local leftSep = Instance.new("Frame")
	leftSep.Name = "LeftSeparator"
	leftSep.Size = UDim2.new(0, 1, 0.6, 0)
	leftSep.Position = UDim2.new(1 / 3, 0, 0.2, 0)
	leftSep.BackgroundColor3 = textColor
	leftSep.BackgroundTransparency = 0.75
	leftSep.BorderSizePixel = 0
	leftSep.ZIndex = 10
	leftSep.Parent = glassFrame.GlassSurface

	-- Right separator (1px line between value and plus)
	local rightSep = Instance.new("Frame")
	rightSep.Name = "RightSeparator"
	rightSep.Size = UDim2.new(0, 1, 0.6, 0)
	rightSep.Position = UDim2.new(2 / 3, 0, 0.2, 0)
	rightSep.BackgroundColor3 = textColor
	rightSep.BackgroundTransparency = 0.75
	rightSep.BorderSizePixel = 0
	rightSep.ZIndex = 10
	rightSep.Parent = glassFrame.GlassSurface

	-- Minus button (left third)
	local minusButton = Instance.new("TextButton")
	minusButton.Name = "MinusButton"
	minusButton.Size = UDim2.new(1 / 3, 0, 1, 0)
	minusButton.Position = UDim2.new(0, 0, 0, 0)
	minusButton.BackgroundTransparency = 1
	minusButton.Text = "-"
	minusButton.Font = Enum.Font.GothamBold
	minusButton.TextSize = 18
	minusButton.TextColor3 = textColor
	minusButton.BorderSizePixel = 0
	minusButton.ZIndex = 100
	minusButton.AutoButtonColor = false
	minusButton.Parent = glassFrame.GlassSurface

	-- UIScale for minus press animation
	local minusScale = Instance.new("UIScale")
	minusScale.Scale = 1
	minusScale.Parent = minusButton

	-- Value label (center third)
	local valueLabel = Instance.new("TextLabel")
	valueLabel.Name = "ValueLabel"
	valueLabel.Size = UDim2.new(1 / 3, 0, 1, 0)
	valueLabel.Position = UDim2.new(1 / 3, 0, 0, 0)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Text = tostring(currentValue)
	valueLabel.Font = Enum.Font.GothamMedium
	valueLabel.TextSize = 14
	valueLabel.TextColor3 = textColor
	valueLabel.TextXAlignment = Enum.TextXAlignment.Center
	valueLabel.TextYAlignment = Enum.TextYAlignment.Center
	valueLabel.BorderSizePixel = 0
	valueLabel.ZIndex = 10
	valueLabel.Parent = glassFrame.GlassSurface

	-- Plus button (right third)
	local plusButton = Instance.new("TextButton")
	plusButton.Name = "PlusButton"
	plusButton.Size = UDim2.new(1 / 3, 0, 1, 0)
	plusButton.Position = UDim2.new(2 / 3, 0, 0, 0)
	plusButton.BackgroundTransparency = 1
	plusButton.Text = "+"
	plusButton.Font = Enum.Font.GothamBold
	plusButton.TextSize = 18
	plusButton.TextColor3 = textColor
	plusButton.BorderSizePixel = 0
	plusButton.ZIndex = 100
	plusButton.AutoButtonColor = false
	plusButton.Parent = glassFrame.GlassSurface

	-- UIScale for plus press animation
	local plusScale = Instance.new("UIScale")
	plusScale.Scale = 1
	plusScale.Parent = plusButton

	-- State
	local connections: {RBXScriptConnection} = {}
	local activeTweens: {Tween} = {}
	local repeatThread: thread? = nil

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

	local function updateDisableStates()
		minusButton.TextTransparency = if currentValue <= minValue then 0.5 else 0
		plusButton.TextTransparency = if currentValue >= maxValue then 0.5 else 0
	end

	local function updateValue(newValue: number)
		newValue = math.clamp(newValue, minValue, maxValue)
		-- Snap to step increments
		newValue = math.round((newValue - minValue) / stepSize) * stepSize + minValue
		newValue = math.clamp(newValue, minValue, maxValue)
		if newValue == currentValue then
			return
		end
		currentValue = newValue
		valueLabel.Text = tostring(currentValue)
		updateDisableStates()
		if config.OnChanged then
			config.OnChanged(currentValue)
		end
	end

	local function playPressAnim(scale: UIScale)
		local downInfo = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local downTween = TweenService:Create(scale, downInfo, { Scale = 0.92 })
		trackTween(downTween)
		downTween:Play()
	end

	local function playReleaseAnim(scale: UIScale)
		local upInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local upTween = TweenService:Create(scale, upInfo, { Scale = 1 })
		trackTween(upTween)
		upTween:Play()
	end

	local function stopRepeat()
		if repeatThread then
			task.cancel(repeatThread)
			repeatThread = nil
		end
	end

	local function startRepeat(delta: number)
		stopRepeat()
		repeatThread = task.delay(0.5, function()
			while true do
				updateValue(currentValue + delta)
				task.wait(0.1)
			end
		end)
	end

	-- Initialize disable states
	updateDisableStates()

	-- Minus button input
	local minusDownConn = minusButton.MouseButton1Down:Connect(function()
		if currentValue <= minValue then
			return
		end
		playPressAnim(minusScale)
		updateValue(currentValue - stepSize)
		startRepeat(-stepSize)
	end)
	table.insert(connections, minusDownConn)

	local minusUpConn = minusButton.MouseButton1Up:Connect(function()
		stopRepeat()
		playReleaseAnim(minusScale)
	end)
	table.insert(connections, minusUpConn)

	local minusLeaveConn = minusButton.MouseLeave:Connect(function()
		stopRepeat()
		playReleaseAnim(minusScale)
	end)
	table.insert(connections, minusLeaveConn)

	-- Plus button input
	local plusDownConn = plusButton.MouseButton1Down:Connect(function()
		if currentValue >= maxValue then
			return
		end
		playPressAnim(plusScale)
		updateValue(currentValue + stepSize)
		startRepeat(stepSize)
	end)
	table.insert(connections, plusDownConn)

	local plusUpConn = plusButton.MouseButton1Up:Connect(function()
		stopRepeat()
		playReleaseAnim(plusScale)
	end)
	table.insert(connections, plusUpConn)

	local plusLeaveConn = plusButton.MouseLeave:Connect(function()
		stopRepeat()
		playReleaseAnim(plusScale)
	end)
	table.insert(connections, plusLeaveConn)

	-- Return typed table
	local self: Types.MangoStepper = {
		Container = glassFrame.Container,
		SetValue = function(self: Types.MangoStepper, value: number)
			updateValue(value)
		end,
		GetValue = function(self: Types.MangoStepper): number
			return currentValue
		end,
		Destroy = function(self: Types.MangoStepper)
			stopRepeat()
			cancelAllTweens()
			for _, conn in connections do
				conn:Disconnect()
			end
			table.clear(connections)
			glassFrame:Destroy()
		end,
	}

	return self
end

return module
