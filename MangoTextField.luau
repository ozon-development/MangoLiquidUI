--!strict

local Types = require(script.Parent.Types)
local Themes = require(script.Parent.Themes)
local resolve = Themes.resolve
local MangoProtection = require(script.Parent.MangoProtection)
local TweenService = game:GetService("TweenService")

local module = {}

function module.new(config: Types.MangoTextFieldConfig): Types.MangoTextField
	local theme = config.Theme

	-- Resolve config values
	local size = resolve(config.Size, nil, UDim2.new(0, 280, 0, 40)) :: UDim2
	local position = resolve(config.Position, nil, UDim2.new(0, 0, 0, 0)) :: UDim2
	local anchorPoint = resolve(config.AnchorPoint, nil, Vector2.new(0, 0)) :: Vector2
	local placeholder = resolve(config.Placeholder, nil, "") :: string
	local initialText = resolve(config.InitialText, nil, "") :: string

	-- Theme values
	local primaryText = resolve(nil, theme and theme.PrimaryTextColor, Color3.fromRGB(0, 0, 0)) :: Color3
	local secondaryText = resolve(nil, theme and theme.SecondaryTextColor, Color3.fromRGB(60, 60, 70)) :: Color3
	local bgColor = resolve(nil, theme and theme.BackgroundColor3, Color3.fromRGB(255, 255, 255)) :: Color3
	local bgTransparency = resolve(nil, theme and theme.TextFieldBackgroundTransparency, 0.92) :: number
	local borderColor = resolve(nil, theme and theme.TextFieldBorderColor, Color3.fromRGB(200, 200, 205)) :: Color3
	local focusBorderColor = resolve(nil, theme and theme.TextFieldFocusBorderColor, Color3.fromRGB(0, 122, 255)) :: Color3
	local shadowColor = resolve(nil, theme and theme.ShadowColor, Color3.fromRGB(0, 0, 0)) :: Color3

	-- State
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

	-- Container
	local container = Instance.new("Frame")
	container.Name = MangoProtection.randomName("TextField")
	container.Size = size
	container.Position = position
	container.AnchorPoint = anchorPoint
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0

	-- Shadow visibility
	local shadowEnabled = resolve(config.ShadowEnabled, nil, true) :: boolean

	-- Shadow layer 1 (outer)
	local shadow1 = Instance.new("Frame")
	shadow1.Name = "ShadowLayer1"
	shadow1.AnchorPoint = Vector2.new(0.5, 0.5)
	shadow1.Position = UDim2.new(0.5, 0, 0.5, 1)
	shadow1.Size = UDim2.new(1, 8, 1, 8)
	shadow1.BackgroundColor3 = shadowColor
	shadow1.BackgroundTransparency = 0.92
	shadow1.BorderSizePixel = 0
	shadow1.ZIndex = 0
	shadow1.Visible = shadowEnabled
	shadow1.Parent = container

	local shadow1Corner = Instance.new("UICorner")
	shadow1Corner.CornerRadius = UDim.new(0, 12)
	shadow1Corner.Parent = shadow1

	-- Shadow layer 2 (inner)
	local shadow2 = Instance.new("Frame")
	shadow2.Name = "ShadowLayer2"
	shadow2.AnchorPoint = Vector2.new(0.5, 0.5)
	shadow2.Position = UDim2.new(0.5, 0, 0.5, 0.5)
	shadow2.Size = UDim2.new(1, 4, 1, 4)
	shadow2.BackgroundColor3 = shadowColor
	shadow2.BackgroundTransparency = 0.88
	shadow2.BorderSizePixel = 0
	shadow2.ZIndex = 0
	shadow2.Visible = shadowEnabled
	shadow2.Parent = container

	local shadow2Corner = Instance.new("UICorner")
	shadow2Corner.CornerRadius = UDim.new(0, 11)
	shadow2Corner.Parent = shadow2

	-- FieldFrame (rounded rectangle)
	local fieldFrame = Instance.new("Frame")
	fieldFrame.Name = "FieldFrame"
	fieldFrame.Size = UDim2.new(1, 0, 1, 0)
	fieldFrame.BackgroundColor3 = bgColor
	fieldFrame.BackgroundTransparency = bgTransparency
	fieldFrame.BorderSizePixel = 0
	fieldFrame.ZIndex = 1
	fieldFrame.ClipsDescendants = true
	fieldFrame.Parent = container

	local fieldCorner = Instance.new("UICorner")
	fieldCorner.CornerRadius = UDim.new(0, 10)
	fieldCorner.Parent = fieldFrame

	-- UIStroke (border)
	local fieldStroke = Instance.new("UIStroke")
	fieldStroke.Name = "FieldStroke"
	fieldStroke.Color = borderColor
	fieldStroke.Thickness = 1
	fieldStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	fieldStroke.Parent = fieldFrame

	-- UIPadding
	local fieldPadding = Instance.new("UIPadding")
	fieldPadding.PaddingLeft = UDim.new(0, 12)
	fieldPadding.PaddingRight = UDim.new(0, 12)
	fieldPadding.Parent = fieldFrame

	-- InputBox
	local inputBox = Instance.new("TextBox")
	inputBox.Name = "InputBox"
	inputBox.Size = UDim2.new(1, -20, 1, 0)
	inputBox.Position = UDim2.new(0, 0, 0, 0)
	inputBox.BackgroundTransparency = 1
	inputBox.BorderSizePixel = 0
	inputBox.Font = Enum.Font.GothamMedium
	inputBox.TextSize = 14
	inputBox.TextColor3 = primaryText
	inputBox.PlaceholderText = placeholder
	inputBox.PlaceholderColor3 = secondaryText
	inputBox.Text = initialText
	inputBox.ClearTextOnFocus = false
	inputBox.TextXAlignment = Enum.TextXAlignment.Left
	inputBox.ZIndex = 10
	inputBox.Parent = fieldFrame

	-- Masked mode (password field)
	local isMasked = resolve(config.Masked, nil, false) :: boolean
	local showingMask = isMasked
	local realText: string = initialText

	local eyeFrame: Frame? = nil
	local eyeLabel: TextLabel? = nil

	if isMasked then
		-- Adjust input box width to make room for eye button
		inputBox.Size = UDim2.new(1, -40, 1, 0)

		-- Eye toggle button
		eyeFrame = Instance.new("Frame")
		eyeFrame.Name = "EyeFrame"
		eyeFrame.Size = UDim2.new(0, 16, 0, 16)
		eyeFrame.Position = UDim2.new(1, -22, 0.5, 0)
		eyeFrame.AnchorPoint = Vector2.new(1, 0.5)
		eyeFrame.BackgroundTransparency = 1
		eyeFrame.BorderSizePixel = 0
		eyeFrame.ZIndex = 10
		eyeFrame.Parent = fieldFrame

		eyeLabel = Instance.new("TextLabel")
		eyeLabel.Name = "EyeLabel"
		eyeLabel.Size = UDim2.new(1, 0, 1, 0)
		eyeLabel.BackgroundTransparency = 1
		eyeLabel.BorderSizePixel = 0
		eyeLabel.Font = Enum.Font.Gotham
		eyeLabel.TextSize = 14
		eyeLabel.Text = "\240\159\145\129" -- eye emoji
		eyeLabel.TextColor3 = secondaryText
		eyeLabel.ZIndex = 10
		eyeLabel.Parent = eyeFrame

		local eyeHitArea = Instance.new("TextButton")
		eyeHitArea.Name = "EyeHitArea"
		eyeHitArea.Size = UDim2.new(1, 8, 1, 8)
		eyeHitArea.AnchorPoint = Vector2.new(0.5, 0.5)
		eyeHitArea.Position = UDim2.new(0.5, 0, 0.5, 0)
		eyeHitArea.BackgroundTransparency = 1
		eyeHitArea.Text = ""
		eyeHitArea.BorderSizePixel = 0
		eyeHitArea.ZIndex = 100
		eyeHitArea.AutoButtonColor = false
		eyeHitArea.Parent = eyeFrame

		-- Toggle mask on eye click
		local eyeConn = eyeHitArea.MouseButton1Click:Connect(function()
			showingMask = not showingMask
			if eyeLabel then
				eyeLabel.Text = if showingMask then "\240\159\145\129" else "\240\159\145\129\226\128\141\240\159\151\168"
			end
			-- Update display
			if showingMask then
				inputBox.Text = string.rep("\226\151\143", utf8.len(realText) or 0) -- bullet character
			else
				inputBox.Text = realText
			end
		end)
		table.insert(connections, eyeConn)

		-- Set initial masked display
		if initialText ~= "" then
			realText = initialText
			inputBox.Text = string.rep("\226\151\143", utf8.len(initialText) or 0)
		end
	end

	-- Clear button (right side, visible when text is not empty)
	local clearFrame = Instance.new("Frame")
	clearFrame.Name = "ClearFrame"
	clearFrame.Size = UDim2.new(0, 16, 0, 16)
	clearFrame.Position = UDim2.new(1, -4, 0.5, 0)
	clearFrame.AnchorPoint = Vector2.new(1, 0.5)
	clearFrame.BackgroundTransparency = 1
	clearFrame.BorderSizePixel = 0
	clearFrame.Visible = initialText ~= ""
	clearFrame.ZIndex = 10
	clearFrame.Parent = fieldFrame

	local clearLabel = Instance.new("TextLabel")
	clearLabel.Name = "ClearLabel"
	clearLabel.Size = UDim2.new(1, 0, 1, 0)
	clearLabel.BackgroundTransparency = 1
	clearLabel.BorderSizePixel = 0
	clearLabel.Font = Enum.Font.GothamBold
	clearLabel.TextSize = 10
	clearLabel.Text = "X"
	clearLabel.TextColor3 = secondaryText
	clearLabel.ZIndex = 10
	clearLabel.Parent = clearFrame

	local clearHitArea = Instance.new("TextButton")
	clearHitArea.Name = "HitArea"
	clearHitArea.Size = UDim2.new(1, 8, 1, 8)
	clearHitArea.AnchorPoint = Vector2.new(0.5, 0.5)
	clearHitArea.Position = UDim2.new(0.5, 0, 0.5, 0)
	clearHitArea.BackgroundTransparency = 1
	clearHitArea.Text = ""
	clearHitArea.BorderSizePixel = 0
	clearHitArea.ZIndex = 100
	clearHitArea.AutoButtonColor = false
	clearHitArea.Parent = clearFrame

	-- Focus: animate UIStroke color
	local focusedConn = inputBox.Focused:Connect(function()
		cancelAllTweens()
		local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local tween = TweenService:Create(fieldStroke, tweenInfo, {
			Color = focusBorderColor,
		})
		trackTween(tween)
		tween:Play()
	end)
	table.insert(connections, focusedConn)

	local focusLostConn = inputBox.FocusLost:Connect(function(enterPressed: boolean)
		cancelAllTweens()
		local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local tween = TweenService:Create(fieldStroke, tweenInfo, {
			Color = borderColor,
		})
		trackTween(tween)
		tween:Play()

		if config.OnFocusLost then
			local reportText = if isMasked then realText else inputBox.Text
			config.OnFocusLost(reportText, enterPressed)
		end
	end)
	table.insert(connections, focusLostConn)

	-- Text changed: show/hide clear button, fire callback
	local isUpdatingMask = false
	local textChangedConn = inputBox:GetPropertyChangedSignal("Text"):Connect(function()
		if isMasked and not isUpdatingMask then
			isUpdatingMask = true
			local currentDisplay = inputBox.Text
			local prevLen = utf8.len(realText) or 0
			local currentLen = utf8.len(currentDisplay) or 0

			if currentLen > prevLen then
				-- Characters were added — extract new chars from the end
				local newChars = string.sub(currentDisplay, utf8.offset(currentDisplay, prevLen + 1) or (#currentDisplay + 1))
				realText = realText .. newChars
			elseif currentLen < prevLen then
				-- Characters were deleted
				local keepLen = currentLen
				if keepLen <= 0 then
					realText = ""
				else
					local endPos = utf8.offset(realText, keepLen + 1)
					realText = string.sub(realText, 1, (endPos or (#realText + 1)) - 1)
				end
			end

			if showingMask then
				inputBox.Text = string.rep("\226\151\143", utf8.len(realText) or 0)
			end
			isUpdatingMask = false
		end

		local displayText = if isMasked then realText else inputBox.Text
		clearFrame.Visible = displayText ~= ""
		if config.OnTextChanged then
			config.OnTextChanged(displayText)
		end
	end)
	table.insert(connections, textChangedConn)

	-- Clear button click
	local clearConn = clearHitArea.MouseButton1Click:Connect(function()
		if isMasked then
			realText = ""
		end
		inputBox.Text = ""
		if config.OnTextChanged then
			config.OnTextChanged("")
		end
		inputBox:CaptureFocus()
	end)
	table.insert(connections, clearConn)

	-- Parent assignment
	if config.Parent then
		container.Parent = config.Parent
	end

	-- Return table
	local self: Types.MangoTextField = {
		Container = container,
		GetText = function(self: Types.MangoTextField): string
			if isMasked then
				return realText
			end
			return inputBox.Text
		end,
		SetText = function(self: Types.MangoTextField, text: string)
			if isMasked then
				realText = text
				if showingMask then
					inputBox.Text = string.rep("\226\151\143", utf8.len(text) or 0)
				else
					inputBox.Text = text
				end
			else
				inputBox.Text = text
			end
		end,
		Focus = function(self: Types.MangoTextField)
			inputBox:CaptureFocus()
		end,
		Destroy = function(self: Types.MangoTextField)
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
