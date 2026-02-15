--!strict

local Types = require(script.Parent.Types)
local Themes = require(script.Parent.Themes)
local MangoGlassFrame = require(script.Parent.MangoGlassFrame)
local MangoHaptics = require(script.Parent.MangoHaptics)
local resolve = Themes.resolve
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")

local module = {}

function module.new(config: Types.MangoButtonConfig): Types.MangoButton
	local theme = config.Theme

	-- Resolve config values with nil-safe helper
	local textSize = resolve(config.TextSize, nil, 16) :: number
	local font = Enum.Font.GothamBold
	local text = config.Text

	-- Button-specific opacity: more opaque than panels for readability
	local buttonTransparency = resolve(config.BackgroundTransparency, theme and theme.ButtonBackgroundTransparency, 0.65) :: number

	-- Auto-size: measure text and add padding if no explicit Size given
	local size: UDim2
	if config.Size then
		size = config.Size
	else
		local textBounds = TextService:GetTextSize(text, textSize, font, Vector2.new(1000, 1000))
		size = UDim2.new(0, textBounds.X + 28, 0, textBounds.Y + 20)
	end

	-- Create MangoGlassFrame with pill shape (CornerRadius = 999)
	-- Button-specific shadow: tighter spread + offset to avoid boxy look on small pills
	local glassFrame = MangoGlassFrame.new({
		Size = size,
		Position = config.Position,
		AnchorPoint = resolve(config.AnchorPoint, nil, Vector2.new(0, 0)) :: Vector2,
		CornerRadius = UDim.new(0, 999),
		BackgroundTransparency = buttonTransparency,
		Theme = config.Theme,
		ShadowEnabled = resolve(config.ShadowEnabled, nil, true) :: boolean,
		ShadowLayerCount = 2,
		ShadowSpread = 5,
		ShadowOffsetY = 1,
		LightweightMode = true,
		Parent = config.Parent,
	})

	-- UIScale on Container for press animation
	local uiScale = Instance.new("UIScale")
	uiScale.Scale = 1
	uiScale.Parent = glassFrame.Container

	-- Directional specular on buttons — softer fresnel for small pills, responds to light direction
	local fresnelStart = resolve(nil, theme and theme.FresnelStartTransparency, 0.25) :: number
	local fresnelMid = resolve(nil, theme and theme.FresnelMidTransparency, 0.50) :: number
	local fresnelMidPoint = resolve(nil, theme and theme.FresnelMidPoint, 0.35) :: number
	local fresnelEnd = resolve(nil, theme and theme.FresnelEndTransparency, 0.95) :: number
	glassFrame.SpecularGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, fresnelStart + 0.05),
		NumberSequenceKeypoint.new(fresnelMidPoint, fresnelMid + 0.05),
		NumberSequenceKeypoint.new(1, fresnelEnd),
	})

	-- TextLabel inside GlassSurface
	local textColor = resolve(nil, theme and theme.PrimaryTextColor, Color3.fromRGB(0, 0, 0)) :: Color3

	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "ButtonText"
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
	textLabel.Parent = glassFrame.GlassSurface

	-- Transparent TextButton hit area on top of all glass layers for reliable input
	local hitArea = Instance.new("TextButton")
	hitArea.Name = "HitArea"
	hitArea.Size = UDim2.new(1, 0, 1, 0)
	hitArea.BackgroundTransparency = 1
	hitArea.Text = ""
	hitArea.BorderSizePixel = 0
	hitArea.ZIndex = 100
	hitArea.AutoButtonColor = false
	hitArea.Parent = glassFrame.GlassSurface

	-- Press animation
	local pressScale = resolve(nil, theme and theme.ButtonPressScale, 0.97) :: number
	local originalBgTransparency = glassFrame.GlassSurface.BackgroundTransparency
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

	local connections: {RBXScriptConnection} = {}
	local isHovering = false

	-- Hover animation: subtle scale-up + specular gradient shift on mouse enter
	local hoverEnterConn = hitArea.MouseEnter:Connect(function()
		isHovering = true
		cancelAllTweens()
		local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		local scaleTween = TweenService:Create(uiScale, tweenInfo, { Scale = 1.02 })
		trackTween(scaleTween)
		scaleTween:Play()
		local gradientTween = TweenService:Create(glassFrame.SpecularGradient, tweenInfo, {
			Offset = Vector2.new(0.02, 0.02),
		})
		trackTween(gradientTween)
		gradientTween:Play()
	end)
	table.insert(connections, hoverEnterConn)

	local hoverLeaveConn = hitArea.MouseLeave:Connect(function()
		isHovering = false
		cancelAllTweens()
		local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		local scaleTween = TweenService:Create(uiScale, tweenInfo, { Scale = 1 })
		trackTween(scaleTween)
		scaleTween:Play()
		local gradientTween = TweenService:Create(glassFrame.SpecularGradient, tweenInfo, {
			Offset = Vector2.new(0, 0),
		})
		trackTween(gradientTween)
		gradientTween:Play()
	end)
	table.insert(connections, hoverLeaveConn)

	local pressConn = hitArea.MouseButton1Down:Connect(function()
		cancelAllTweens()
		local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local tween = TweenService:Create(uiScale, tweenInfo, { Scale = pressScale })
		trackTween(tween)
		tween:Play()
		-- Opacity pulse: glass becomes more opaque on press
		local opacityTween = TweenService:Create(glassFrame.GlassSurface, tweenInfo, {
			BackgroundTransparency = math.clamp(originalBgTransparency - 0.04, 0, 1),
		})
		trackTween(opacityTween)
		opacityTween:Play()
	end)
	table.insert(connections, pressConn)

	local releaseConn = hitArea.MouseButton1Up:Connect(function()
		cancelAllTweens()
		local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		-- Restore to hover scale if still hovering, otherwise back to 1.0
		local restoreScale = if isHovering then 1.02 else 1
		local tween = TweenService:Create(uiScale, tweenInfo, { Scale = restoreScale })
		trackTween(tween)
		tween:Play()
		-- Restore opacity
		local opacityTween = TweenService:Create(glassFrame.GlassSurface, tweenInfo, {
			BackgroundTransparency = originalBgTransparency,
		})
		trackTween(opacityTween)
		opacityTween:Play()
		-- Restore specular offset to hover state if still hovering
		local gradientOffset = if isHovering then Vector2.new(0.02, 0.02) else Vector2.new(0, 0)
		local gradientTween = TweenService:Create(glassFrame.SpecularGradient, tweenInfo, {
			Offset = gradientOffset,
		})
		trackTween(gradientTween)
		gradientTween:Play()
		MangoHaptics.light()
		if config.OnActivated then
			config.OnActivated()
		end
	end)
	table.insert(connections, releaseConn)

	-- Return typed table
	local self: Types.MangoButton = {
		Container = glassFrame.Container,
		GlassSurface = glassFrame.GlassSurface,
		TextLabel = textLabel,
		SetText = function(self: Types.MangoButton, newText: string)
			textLabel.Text = newText
		end,
		Destroy = function(self: Types.MangoButton)
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
