--!strict

local Types = require(script.Parent.Types)
local Themes = require(script.Parent.Themes)
local MangoGlassFrame = require(script.Parent.MangoGlassFrame)
local resolve = Themes.resolve
local MangoProtection = require(script.Parent.MangoProtection)
local TweenService = game:GetService("TweenService")

local module = {}

function module.new(config: Types.MangoSearchBarConfig): Types.MangoSearchBar
	local theme = config.Theme

	-- Resolve config values
	local size = resolve(config.Size, nil, UDim2.new(0, 280, 0, 36)) :: UDim2
	local position = resolve(config.Position, nil, UDim2.new(0, 0, 0, 0)) :: UDim2
	local anchorPoint = resolve(config.AnchorPoint, nil, Vector2.new(0, 0)) :: Vector2
	local placeholder = resolve(config.Placeholder, nil, "Search") :: string

	-- Theme values
	local primaryText = resolve(nil, theme and theme.PrimaryTextColor, Color3.fromRGB(0, 0, 0)) :: Color3
	local placeholderColor = resolve(nil, theme and theme.SearchBarPlaceholderColor, Color3.fromRGB(142, 142, 147)) :: Color3
	local bgTransparency = resolve(nil, theme and theme.SearchBarBackgroundTransparency, 0.88) :: number

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

	-- Container via MangoGlassFrame (pill, LightweightMode)
	local glassFrame = MangoGlassFrame.new({
		Size = size,
		Position = position,
		AnchorPoint = anchorPoint,
		CornerRadius = UDim.new(0, 999),
		BackgroundTransparency = bgTransparency,
		Theme = theme,
		ShadowEnabled = true,
		ShadowLayerCount = 2,
		ShadowSpread = 4,
		ShadowOffsetY = 1,
		LightweightMode = true,
	})

	local container = glassFrame.Container
	local glassSurface = glassFrame.GlassSurface

	-- UIPadding inside GlassSurface
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.Parent = glassSurface

	-- Search icon (left side)
	local searchIcon = Instance.new("TextLabel")
	searchIcon.Name = "SearchIcon"
	searchIcon.Size = UDim2.new(0, 20, 0, 20)
	searchIcon.Position = UDim2.new(0, 0, 0.5, 0)
	searchIcon.AnchorPoint = Vector2.new(0, 0.5)
	searchIcon.BackgroundTransparency = 1
	searchIcon.BorderSizePixel = 0
	searchIcon.Font = Enum.Font.Gotham
	searchIcon.TextSize = 16
	searchIcon.Text = "\240\159\148\141" -- magnifying glass emoji
	searchIcon.TextColor3 = placeholderColor
	searchIcon.ZIndex = 10
	searchIcon.Parent = glassSurface

	-- InputBox (fills remaining width between icon and clear button)
	local inputBox = Instance.new("TextBox")
	inputBox.Name = "InputBox"
	inputBox.Size = UDim2.new(1, -48, 1, 0)
	inputBox.Position = UDim2.new(0, 24, 0, 0)
	inputBox.BackgroundTransparency = 1
	inputBox.BorderSizePixel = 0
	inputBox.Font = Enum.Font.GothamMedium
	inputBox.TextSize = 14
	inputBox.TextColor3 = primaryText
	inputBox.PlaceholderText = placeholder
	inputBox.PlaceholderColor3 = placeholderColor
	inputBox.Text = ""
	inputBox.ClearTextOnFocus = false
	inputBox.TextXAlignment = Enum.TextXAlignment.Left
	inputBox.ZIndex = 10
	inputBox.Parent = glassSurface

	-- Clear button (right side, visible when text is not empty)
	local clearFrame = Instance.new("Frame")
	clearFrame.Name = "ClearFrame"
	clearFrame.Size = UDim2.new(0, 20, 0, 20)
	clearFrame.Position = UDim2.new(1, -4, 0.5, 0)
	clearFrame.AnchorPoint = Vector2.new(1, 0.5)
	clearFrame.BackgroundTransparency = 1
	clearFrame.BorderSizePixel = 0
	clearFrame.Visible = false
	clearFrame.ZIndex = 10
	clearFrame.Parent = glassSurface

	local clearLabel = Instance.new("TextLabel")
	clearLabel.Name = "ClearLabel"
	clearLabel.Size = UDim2.new(1, 0, 1, 0)
	clearLabel.BackgroundTransparency = 1
	clearLabel.BorderSizePixel = 0
	clearLabel.Font = Enum.Font.GothamBold
	clearLabel.TextSize = 10
	clearLabel.Text = "X"
	clearLabel.TextColor3 = placeholderColor
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

	-- Focus animation
	local originalBgTransparency = glassSurface.BackgroundTransparency

	local focusedConn = inputBox.Focused:Connect(function()
		cancelAllTweens()
		local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local tween = TweenService:Create(glassSurface, tweenInfo, {
			BackgroundTransparency = math.clamp(originalBgTransparency - 0.05, 0, 1),
		})
		trackTween(tween)
		tween:Play()
	end)
	table.insert(connections, focusedConn)

	local focusLostConn = inputBox.FocusLost:Connect(function(enterPressed: boolean)
		cancelAllTweens()
		local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local tween = TweenService:Create(glassSurface, tweenInfo, {
			BackgroundTransparency = originalBgTransparency,
		})
		trackTween(tween)
		tween:Play()

		if config.OnSubmit then
			config.OnSubmit(inputBox.Text)
		end
	end)
	table.insert(connections, focusLostConn)

	-- Text changed: show/hide clear button, fire callback
	local textChangedConn = inputBox:GetPropertyChangedSignal("Text"):Connect(function()
		clearFrame.Visible = inputBox.Text ~= ""
		if config.OnTextChanged then
			config.OnTextChanged(inputBox.Text)
		end
	end)
	table.insert(connections, textChangedConn)

	-- Clear button click
	local clearConn = clearHitArea.MouseButton1Click:Connect(function()
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
	local self: Types.MangoSearchBar = {
		Container = container,
		GetText = function(self: Types.MangoSearchBar): string
			return inputBox.Text
		end,
		SetText = function(self: Types.MangoSearchBar, text: string)
			inputBox.Text = text
		end,
		Focus = function(self: Types.MangoSearchBar)
			inputBox:CaptureFocus()
		end,
		Destroy = function(self: Types.MangoSearchBar)
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
