--!strict

local Types = require(script.Parent.Types)
local Themes = require(script.Parent.Themes)
local MangoHaptics = require(script.Parent.MangoHaptics)
local resolve = Themes.resolve
local TweenService = game:GetService("TweenService")

local module = {}

function module.new(config: Types.MangoCheckboxConfig): Types.MangoCheckbox
	local theme = config.Theme

	-- Resolve config values
	local position = config.Position
	local anchorPoint = resolve(config.AnchorPoint, nil, Vector2.new(0, 0)) :: Vector2
	local initialState = resolve(config.InitialState, nil, false) :: boolean
	local labelText = config.Label

	-- Theme values
	local onColor = resolve(nil, theme and theme.CheckboxOnColor, Color3.fromRGB(0, 122, 255)) :: Color3
	local offColor = resolve(nil, theme and theme.CheckboxOffColor, Color3.fromRGB(200, 200, 205)) :: Color3
	local checkColor = resolve(nil, theme and theme.CheckboxCheckColor, Color3.fromRGB(255, 255, 255)) :: Color3
	local primaryText = resolve(nil, theme and theme.PrimaryTextColor, Color3.fromRGB(0, 0, 0)) :: Color3

	-- State
	local isChecked: boolean = initialState
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

	-- Container (horizontal layout)
	local container = Instance.new("Frame")
	container.Name = "MangoCheckbox"
	container.Size = UDim2.new(0, 0, 0, 24)
	container.AutomaticSize = Enum.AutomaticSize.X
	container.Position = position
	container.AnchorPoint = anchorPoint
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 8)
	layout.Parent = container

	-- CheckboxFrame (24x24)
	local checkboxFrame = Instance.new("Frame")
	checkboxFrame.Name = "CheckboxFrame"
	checkboxFrame.Size = UDim2.new(0, 24, 0, 24)
	checkboxFrame.BackgroundTransparency = 1
	checkboxFrame.BorderSizePixel = 0
	checkboxFrame.LayoutOrder = 1
	checkboxFrame.Parent = container

	-- UIStroke (border that changes color)
	local checkboxStroke = Instance.new("UIStroke")
	checkboxStroke.Name = "CheckboxStroke"
	checkboxStroke.Color = if isChecked then onColor else offColor
	checkboxStroke.Thickness = 1.5
	checkboxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	checkboxStroke.Parent = checkboxFrame

	local checkboxCorner = Instance.new("UICorner")
	checkboxCorner.CornerRadius = UDim.new(0, 6)
	checkboxCorner.Parent = checkboxFrame

	-- CheckFill (colored fill, uses UIScale for animation)
	local checkFill = Instance.new("Frame")
	checkFill.Name = "CheckFill"
	checkFill.Size = UDim2.new(1, 0, 1, 0)
	checkFill.BackgroundColor3 = onColor
	checkFill.BackgroundTransparency = 0
	checkFill.BorderSizePixel = 0
	checkFill.ZIndex = 1
	checkFill.Parent = checkboxFrame

	local checkFillCorner = Instance.new("UICorner")
	checkFillCorner.CornerRadius = UDim.new(0, 6)
	checkFillCorner.Parent = checkFill

	local checkFillScale = Instance.new("UIScale")
	checkFillScale.Scale = if isChecked then 1 else 0
	checkFillScale.Parent = checkFill

	-- Checkmark label
	local checkmarkLabel = Instance.new("TextLabel")
	checkmarkLabel.Name = "CheckmarkLabel"
	checkmarkLabel.Size = UDim2.new(1, 0, 1, 0)
	checkmarkLabel.BackgroundTransparency = 1
	checkmarkLabel.BorderSizePixel = 0
	checkmarkLabel.Font = Enum.Font.GothamBold
	checkmarkLabel.TextSize = 14
	checkmarkLabel.Text = "\226\156\147" -- checkmark ✓
	checkmarkLabel.TextColor3 = checkColor
	checkmarkLabel.TextTransparency = if isChecked then 0 else 1
	checkmarkLabel.TextXAlignment = Enum.TextXAlignment.Center
	checkmarkLabel.TextYAlignment = Enum.TextYAlignment.Center
	checkmarkLabel.ZIndex = 10
	checkmarkLabel.Parent = checkboxFrame

	-- HitArea
	local hitArea = Instance.new("TextButton")
	hitArea.Name = "HitArea"
	hitArea.Size = UDim2.new(1, 0, 1, 0)
	hitArea.BackgroundTransparency = 1
	hitArea.Text = ""
	hitArea.BorderSizePixel = 0
	hitArea.ZIndex = 100
	hitArea.AutoButtonColor = false
	hitArea.Parent = checkboxFrame

	-- Label text (optional)
	if labelText and labelText ~= "" then
		local label = Instance.new("TextLabel")
		label.Name = "LabelText"
		label.Size = UDim2.new(0, 0, 1, 0)
		label.AutomaticSize = Enum.AutomaticSize.X
		label.BackgroundTransparency = 1
		label.BorderSizePixel = 0
		label.Font = Enum.Font.GothamMedium
		label.TextSize = 14
		label.Text = labelText
		label.TextColor3 = primaryText
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextYAlignment = Enum.TextYAlignment.Center
		label.LayoutOrder = 2
		label.Parent = container
	end

	-- Animation
	local function animateToState(state: boolean)
		cancelAllTweens()

		local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		local colorInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

		-- Scale fill in/out
		local scaleTween = TweenService:Create(checkFillScale, tweenInfo, {
			Scale = if state then 1 else 0,
		})
		trackTween(scaleTween)
		scaleTween:Play()

		-- Stroke color
		local strokeTween = TweenService:Create(checkboxStroke, colorInfo, {
			Color = if state then onColor else offColor,
		})
		trackTween(strokeTween)
		strokeTween:Play()

		-- Checkmark transparency
		local checkTween = TweenService:Create(checkmarkLabel, colorInfo, {
			TextTransparency = if state then 0 else 1,
		})
		trackTween(checkTween)
		checkTween:Play()
	end

	-- Click handler
	local clickConn = hitArea.MouseButton1Click:Connect(function()
		isChecked = not isChecked
		MangoHaptics.light()
		animateToState(isChecked)
		if config.OnToggled then
			config.OnToggled(isChecked)
		end
	end)
	table.insert(connections, clickConn)

	-- Parent assignment
	if config.Parent then
		container.Parent = config.Parent
	end

	-- Return table
	local self: Types.MangoCheckbox = {
		Container = container,
		SetState = function(self: Types.MangoCheckbox, state: boolean)
			isChecked = state
			animateToState(isChecked)
		end,
		GetState = function(self: Types.MangoCheckbox): boolean
			return isChecked
		end,
		Destroy = function(self: Types.MangoCheckbox)
			cancelAllTweens()
			for _, conn in connections do
				conn:Disconnect()
			end
			table.clear(connections)
			container:Destroy()
		end,
	}

	return self
end

return module
