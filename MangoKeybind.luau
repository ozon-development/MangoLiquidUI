--!strict

local Types = require(script.Parent.Types)
local Themes = require(script.Parent.Themes)
local MangoGlassFrame = require(script.Parent.MangoGlassFrame)
local MangoHaptics = require(script.Parent.MangoHaptics)
local resolve = Themes.resolve
local MangoProtection = require(script.Parent.MangoProtection)
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local module = {}

local function abbreviateKey(keyName: string): string
	local abbrevMap: {[string]: string} = {
		LeftShift = "LShift", RightShift = "RShift",
		LeftControl = "LCtrl", RightControl = "RCtrl",
		LeftAlt = "LAlt", RightAlt = "RAlt",
		Backspace = "BkSp", Return = "Enter",
		Space = "Space", Tab = "Tab", Escape = "Esc",
	}
	return abbrevMap[keyName] or keyName
end

function module.new(config: Types.MangoKeybindConfig): Types.MangoKeybind
	local theme = config.Theme

	-- Resolve config values
	local position = resolve(config.Position, nil, UDim2.new(0, 0, 0, 0)) :: UDim2
	local anchorPoint = resolve(config.AnchorPoint, nil, Vector2.new(0, 0)) :: Vector2
	local labelText = config.Label
	local defaultKey = resolve(config.DefaultKey, nil, "None") :: string

	-- Theme values
	local primaryText = resolve(nil, theme and theme.PrimaryTextColor, Color3.fromRGB(0, 0, 0)) :: Color3
	local pillTransparency = resolve(nil, theme and theme.KeybindPillTransparency, 0.70) :: number
	local listeningColor = resolve(nil, theme and theme.KeybindListeningColor, Color3.fromRGB(0, 122, 255)) :: Color3

	-- State
	local currentKey: string = defaultKey
	local isListening: boolean = false
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

	-- Container (horizontal layout, auto-sized)
	local container = Instance.new("Frame")
	container.Name = MangoProtection.randomName("Keybind")
	container.Size = UDim2.new(0, 0, 0, 28)
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

	-- LabelText (optional)
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
		label.LayoutOrder = 1
		label.Parent = container
	end

	-- KeyButton (MangoGlassFrame, LightweightMode, pill)
	local glassFrame = MangoGlassFrame.new({
		Size = UDim2.new(0, 80, 0, 28),
		Position = UDim2.new(0, 0, 0, 0),
		CornerRadius = UDim.new(0, 999),
		BackgroundTransparency = pillTransparency,
		Theme = theme,
		ShadowEnabled = resolve(config.ShadowEnabled, nil, true) :: boolean,
		ShadowLayerCount = 2,
		ShadowSpread = 4,
		ShadowOffsetY = 1,
		LightweightMode = true,
	})
	glassFrame.Container.LayoutOrder = 2
	glassFrame.Container.Parent = container

	-- UIScale on Container for hover animation
	local uiScale = Instance.new("UIScale")
	uiScale.Scale = 1
	uiScale.Parent = glassFrame.Container

	-- KeyLabel inside GlassSurface
	local keyLabel = Instance.new("TextLabel")
	keyLabel.Name = "KeyLabel"
	keyLabel.Size = UDim2.new(1, 0, 1, 0)
	keyLabel.BackgroundTransparency = 1
	keyLabel.BorderSizePixel = 0
	keyLabel.Font = Enum.Font.GothamMedium
	keyLabel.TextSize = 13
	keyLabel.Text = abbreviateKey(currentKey)
	keyLabel.TextColor3 = primaryText
	keyLabel.TextXAlignment = Enum.TextXAlignment.Center
	keyLabel.TextYAlignment = Enum.TextYAlignment.Center
	keyLabel.ZIndex = 10
	keyLabel.Parent = glassFrame.GlassSurface

	-- HitArea
	local hitArea = Instance.new("TextButton")
	hitArea.Name = "HitArea"
	hitArea.Size = UDim2.new(1, 0, 1, 0)
	hitArea.BackgroundTransparency = 1
	hitArea.Text = ""
	hitArea.BorderSizePixel = 0
	hitArea.ZIndex = 100
	hitArea.AutoButtonColor = false
	hitArea.Parent = glassFrame.GlassSurface

	-- Store original glass transparency for restore
	local originalBgTransparency = glassFrame.GlassSurface.BackgroundTransparency

	-- Forward declare for mutual reference
	local exitListening: () -> ()

	local function enterListening()
		if isListening then
			return
		end
		isListening = true
		cancelAllTweens()
		MangoHaptics.light()

		-- Visual: show "..." and thicken glass
		keyLabel.Text = "..."
		keyLabel.TextColor3 = listeningColor

		local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local opacityTween = TweenService:Create(glassFrame.GlassSurface, tweenInfo, {
			BackgroundTransparency = math.clamp(originalBgTransparency - 0.08, 0, 1),
		})
		trackTween(opacityTween)
		opacityTween:Play()

		-- Listen for keyboard input
		local keyConn: RBXScriptConnection
		keyConn = UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
			if not isListening then
				return
			end
			if input.UserInputType == Enum.UserInputType.Keyboard then
				if input.KeyCode == Enum.KeyCode.Escape then
					-- Cancel: restore previous key
					exitListening()
				else
					-- Capture the new key
					currentKey = input.KeyCode.Name
					exitListening()
					if config.OnKeyChanged then
						config.OnKeyChanged(currentKey)
					end
				end
			end
		end)
		table.insert(connections, keyConn)

		-- Listen for mouse/touch click outside to cancel
		local outsideConn: RBXScriptConnection
		outsideConn = UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
			if not isListening then
				return
			end
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				-- Check if click is outside the key button
				local mousePos = input.Position
				local absPos = glassFrame.Container.AbsolutePosition
				local absSize = glassFrame.Container.AbsoluteSize
				if mousePos.X < absPos.X or mousePos.X > absPos.X + absSize.X
					or mousePos.Y < absPos.Y or mousePos.Y > absPos.Y + absSize.Y then
					exitListening()
				end
			end
		end)
		table.insert(connections, outsideConn)
	end

	exitListening = function()
		if not isListening then
			return
		end
		isListening = false
		cancelAllTweens()

		-- Restore visual
		keyLabel.Text = abbreviateKey(currentKey)
		keyLabel.TextColor3 = primaryText

		local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local opacityTween = TweenService:Create(glassFrame.GlassSurface, tweenInfo, {
			BackgroundTransparency = originalBgTransparency,
		})
		trackTween(opacityTween)
		opacityTween:Play()

		-- Disconnect the listening connections (last 2 added)
		-- Remove from end to avoid index shift
		if #connections >= 1 then
			connections[#connections]:Disconnect()
			table.remove(connections, #connections)
		end
		if #connections >= 1 then
			connections[#connections]:Disconnect()
			table.remove(connections, #connections)
		end
	end

	-- Click handler: enter listening mode
	local clickConn = hitArea.MouseButton1Click:Connect(function()
		if isListening then
			return
		end
		enterListening()
	end)
	table.insert(connections, clickConn)

	-- Hover animation: UIScale 1.02 on hover (0.2s Quad Out), 1.0 on leave
	local isHovering = false

	local hoverEnterConn = hitArea.MouseEnter:Connect(function()
		if isListening then
			return
		end
		isHovering = true
		cancelAllTweens()
		local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local scaleTween = TweenService:Create(uiScale, tweenInfo, { Scale = 1.02 })
		trackTween(scaleTween)
		scaleTween:Play()
	end)
	table.insert(connections, hoverEnterConn)

	local hoverLeaveConn = hitArea.MouseLeave:Connect(function()
		isHovering = false
		if isListening then
			return
		end
		cancelAllTweens()
		local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local scaleTween = TweenService:Create(uiScale, tweenInfo, { Scale = 1.0 })
		trackTween(scaleTween)
		scaleTween:Play()
	end)
	table.insert(connections, hoverLeaveConn)

	-- Parent assignment
	if config.Parent then
		container.Parent = config.Parent
	end

	-- Return table
	local self: Types.MangoKeybind = {
		Container = container,
		GetKey = function(self: Types.MangoKeybind): string
			return currentKey
		end,
		SetKey = function(self: Types.MangoKeybind, keyName: string)
			if isListening then
				exitListening()
			end
			currentKey = keyName
			keyLabel.Text = abbreviateKey(currentKey)
		end,
		Destroy = function(self: Types.MangoKeybind)
			isListening = false
			cancelAllTweens()
			for _, conn in connections do
				conn:Disconnect()
			end
			table.clear(connections)
			glassFrame:Destroy()
			container:Destroy()
		end,
	}

	return self
end

return module
