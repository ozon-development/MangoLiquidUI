--!strict

local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local Types = require(script.Parent.Types)
local Themes = require(script.Parent.Themes)
local resolve = Themes.resolve
local MangoGlassFrame = require(script.Parent.MangoGlassFrame)
local MangoProtection = require(script.Parent.MangoProtection)

local module = {}

local isPlaying = false
local isDestroyed = false
local introGui: ScreenGui? = nil
local introSound: Sound? = nil

function module.skip()
	isDestroyed = true
	if introSound then
		introSound:Destroy()
		introSound = nil
	end
	if introGui then
		introGui:Destroy()
		introGui = nil
	end
	isPlaying = false
end

function module.play(config: Types.MangoIntroConfig?)
	if isPlaying then
		return
	end
	isPlaying = true
	isDestroyed = false

	local cfg = config or {} :: Types.MangoIntroConfig
	local theme = cfg.Theme or Themes.Mango
	local onComplete = cfg.OnComplete
	local titleText = resolve(cfg.Title, nil, "Mango") :: string
	local subtitleText = cfg.Subtitle
	local parentInstance = cfg.Parent

	local gui: ScreenGui
	if parentInstance then
		gui = Instance.new("ScreenGui")
		gui.Name = MangoProtection.randomName("Intro")
		gui.DisplayOrder = 200
		gui.ResetOnSpawn = false
		gui.IgnoreGuiInset = true
		gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		gui.Parent = parentInstance
	else
		gui = MangoProtection.createScreenGui({
			DisplayOrder = 200,
		})
	end
	introGui = gui

	-- Background overlay
	local overlay = Instance.new("Frame")
	overlay.Name = MangoProtection.randomName("Overlay")
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 1
	overlay.BorderSizePixel = 0
	overlay.ZIndex = 0
	overlay.Parent = gui

	-- Center container
	local centerContainer = Instance.new("Frame")
	centerContainer.Name = MangoProtection.randomName("Container")
	centerContainer.Size = UDim2.new(0, 220, 0, 90)
	centerContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
	centerContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	centerContainer.BackgroundTransparency = 1
	centerContainer.BorderSizePixel = 0
	centerContainer.ZIndex = 1
	centerContainer.Parent = gui

	-- Glass frame
	local introGlass = MangoGlassFrame.new({
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		CornerRadius = UDim.new(0, 20),
		Theme = theme,
		ShadowEnabled = true,
		ShadowLayerCount = 4,
		Parent = centerContainer,
	})

	-- 3D Text Layer 1: Back shadow (depth shadow, ZIndex=7)
	local backShadowText = Instance.new("TextLabel")
	backShadowText.Name = MangoProtection.randomName("BackShadow")
	backShadowText.Text = titleText
	backShadowText.Font = Enum.Font.GothamBold
	backShadowText.TextSize = 35
	backShadowText.TextColor3 = Color3.fromRGB(120, 70, 20)
	backShadowText.TextTransparency = 0.65
	backShadowText.TextStrokeTransparency = 1
	backShadowText.BackgroundTransparency = 1
	backShadowText.Size = UDim2.new(1, 0, 1, 0)
	backShadowText.Position = UDim2.new(0, 2, 0, 2)
	backShadowText.TextXAlignment = Enum.TextXAlignment.Center
	backShadowText.TextYAlignment = Enum.TextYAlignment.Center
	backShadowText.BorderSizePixel = 0
	backShadowText.ZIndex = 7
	backShadowText.Parent = introGlass.GlassSurface

	local backShadowScale = Instance.new("UIScale")
	backShadowScale.Scale = 0.01
	backShadowScale.Parent = backShadowText

	-- 3D Text Layer 2: Glass edge (refraction edge, ZIndex=8)
	local glassEdgeText = Instance.new("TextLabel")
	glassEdgeText.Name = MangoProtection.randomName("GlassEdge")
	glassEdgeText.Text = titleText
	glassEdgeText.Font = Enum.Font.GothamBold
	glassEdgeText.TextSize = 33
	glassEdgeText.TextColor3 = Color3.fromRGB(255, 230, 170)
	glassEdgeText.TextTransparency = 0.50
	glassEdgeText.TextStrokeTransparency = 1
	glassEdgeText.BackgroundTransparency = 1
	glassEdgeText.Size = UDim2.new(1, 0, 1, 0)
	glassEdgeText.Position = UDim2.new(0, 1, 0, 1)
	glassEdgeText.TextXAlignment = Enum.TextXAlignment.Center
	glassEdgeText.TextYAlignment = Enum.TextYAlignment.Center
	glassEdgeText.BorderSizePixel = 0
	glassEdgeText.ZIndex = 8
	glassEdgeText.Parent = introGlass.GlassSurface

	local glassEdgeGrad = Instance.new("UIGradient")
	glassEdgeGrad.Rotation = 90
	glassEdgeGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 240, 200)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 160, 80)),
	})
	glassEdgeGrad.Parent = glassEdgeText

	local glassEdgeScale = Instance.new("UIScale")
	glassEdgeScale.Scale = 0.01
	glassEdgeScale.Parent = glassEdgeText

	-- Glow layer (soft amber halo, ZIndex=9)
	local glowText = Instance.new("TextLabel")
	glowText.Name = MangoProtection.randomName("GlowText")
	glowText.Text = titleText
	glowText.Font = Enum.Font.GothamBold
	glowText.TextSize = 34
	glowText.TextColor3 = Color3.fromRGB(255, 200, 80)
	glowText.TextTransparency = 0.55
	glowText.TextStrokeTransparency = 1
	glowText.TextStrokeColor3 = Color3.fromRGB(255, 160, 40)
	glowText.BackgroundTransparency = 1
	glowText.Size = UDim2.new(1, 0, 1, 0)
	glowText.TextXAlignment = Enum.TextXAlignment.Center
	glowText.TextYAlignment = Enum.TextYAlignment.Center
	glowText.BorderSizePixel = 0
	glowText.ZIndex = 9
	glowText.Parent = introGlass.GlassSurface

	local glowScale = Instance.new("UIScale")
	glowScale.Scale = 0.01
	glowScale.Parent = glowText

	-- Main text (warm amber, ZIndex=10)
	local logoText = Instance.new("TextLabel")
	logoText.Name = MangoProtection.randomName("LogoText")
	logoText.Text = titleText
	logoText.Font = Enum.Font.GothamBold
	logoText.TextSize = 32
	logoText.TextColor3 = Color3.fromRGB(255, 200, 100)
	logoText.TextStrokeColor3 = Color3.fromRGB(255, 150, 30)
	logoText.TextStrokeTransparency = 0.7
	logoText.BackgroundTransparency = 1
	logoText.Size = UDim2.new(1, 0, 1, 0)
	logoText.TextXAlignment = Enum.TextXAlignment.Center
	logoText.TextYAlignment = Enum.TextYAlignment.Center
	logoText.BorderSizePixel = 0
	logoText.ZIndex = 10
	logoText.Parent = introGlass.GlassSurface

	local logoTextScale = Instance.new("UIScale")
	logoTextScale.Scale = 0.01
	logoTextScale.Parent = logoText

	-- Subtitle (optional, below title)
	local subtitleLabel: TextLabel? = nil
	if subtitleText and subtitleText ~= "" then
		subtitleLabel = Instance.new("TextLabel")
		subtitleLabel.Name = "SubtitleLabel"
		subtitleLabel.Text = subtitleText
		subtitleLabel.Font = Enum.Font.GothamMedium
		subtitleLabel.TextSize = 14
		subtitleLabel.TextColor3 = resolve(nil, theme and theme.SecondaryTextColor, Color3.fromRGB(120, 80, 40)) :: Color3
		subtitleLabel.TextTransparency = 1
		subtitleLabel.BackgroundTransparency = 1
		subtitleLabel.Size = UDim2.new(1, 0, 0, 20)
		subtitleLabel.Position = UDim2.new(0, 0, 0.65, 0)
		subtitleLabel.TextXAlignment = Enum.TextXAlignment.Center
		subtitleLabel.TextYAlignment = Enum.TextYAlignment.Center
		subtitleLabel.BorderSizePixel = 0
		subtitleLabel.ZIndex = 10
		subtitleLabel.Parent = introGlass.GlassSurface
	end

	-- UIScale for container scale animation
	local logoScale = Instance.new("UIScale")
	logoScale.Scale = 0.01
	logoScale.Parent = centerContainer

	-- SpotlightFrame1 (rotating beam)
	local spotlightFrame1 = Instance.new("Frame")
	spotlightFrame1.Name = "SpotlightFrame1"
	spotlightFrame1.Size = UDim2.new(1, 0, 1, 0)
	spotlightFrame1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	spotlightFrame1.BackgroundTransparency = 0.70
	spotlightFrame1.BorderSizePixel = 0
	spotlightFrame1.ZIndex = 5
	spotlightFrame1.Parent = centerContainer
	local sf1c = Instance.new("UICorner")
	sf1c.CornerRadius = UDim.new(0, 20)
	sf1c.Parent = spotlightFrame1

	local spotlightGradient = Instance.new("UIGradient")
	spotlightGradient.Name = "SpotlightGradient"
	spotlightGradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
	spotlightGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.35, 1),
		NumberSequenceKeypoint.new(0.45, 0.3),
		NumberSequenceKeypoint.new(0.55, 0.3),
		NumberSequenceKeypoint.new(0.65, 1),
		NumberSequenceKeypoint.new(1, 1),
	})
	spotlightGradient.Rotation = 0
	spotlightGradient.Parent = spotlightFrame1

	-- SpotlightFrame2 (diffusion crossfade)
	local spotlightFrame2 = Instance.new("Frame")
	spotlightFrame2.Name = "SpotlightFrame2"
	spotlightFrame2.Size = UDim2.new(1, 0, 1, 0)
	spotlightFrame2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	spotlightFrame2.BackgroundTransparency = 1
	spotlightFrame2.BorderSizePixel = 0
	spotlightFrame2.ZIndex = 5
	spotlightFrame2.Parent = centerContainer
	local sf2c = Instance.new("UICorner")
	sf2c.CornerRadius = UDim.new(0, 20)
	sf2c.Parent = spotlightFrame2

	local softGlowGradient = Instance.new("UIGradient")
	softGlowGradient.Name = "SoftGlowGradient"
	softGlowGradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
	softGlowGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 0.3),
	})
	softGlowGradient.Parent = spotlightFrame2

	-- Shimmer sweep frame
	local shimmerFrame = Instance.new("Frame")
	shimmerFrame.Name = "ShimmerFrame"
	shimmerFrame.Size = UDim2.new(1, 0, 1, 0)
	shimmerFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	shimmerFrame.BackgroundTransparency = 0.85
	shimmerFrame.BorderSizePixel = 0
	shimmerFrame.ZIndex = 6
	shimmerFrame.Parent = introGlass.GlassSurface
	local shimmerCorner = Instance.new("UICorner")
	shimmerCorner.CornerRadius = UDim.new(0, 20)
	shimmerCorner.Parent = shimmerFrame
	local shimmerGradient = Instance.new("UIGradient")
	shimmerGradient.Name = "ShimmerGradient"
	shimmerGradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
	shimmerGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.45, 1),
		NumberSequenceKeypoint.new(0.48, 0.2),
		NumberSequenceKeypoint.new(0.52, 0.2),
		NumberSequenceKeypoint.new(0.55, 1),
		NumberSequenceKeypoint.new(1, 1),
	})
	shimmerGradient.Offset = Vector2.new(-0.5, 0)
	shimmerGradient.Parent = shimmerFrame

	-- Play sound
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://129319699633218"
	sound.Volume = 0.8
	sound.Parent = SoundService
	sound:Play()
	introSound = sound

	-- 0.0s: Overlay fades to 0.55
	TweenService:Create(overlay, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0.55,
	}):Play()

	-- 0.0s: Container scale 0.01 -> 1.0
	TweenService:Create(logoScale, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()

	-- Staggered 3D text scale bounce
	TweenService:Create(backShadowScale, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	TweenService:Create(glassEdgeScale, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	TweenService:Create(glowScale, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()

	local mainOvershootTw = TweenService:Create(logoTextScale, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1.02 })
	mainOvershootTw:Play()
	mainOvershootTw.Completed:Connect(function()
		if isDestroyed then return end
		TweenService:Create(logoTextScale, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1.0 }):Play()
	end)

	-- Rotation wobble
	local rotateToInfo = TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	local rotateTo = TweenService:Create(centerContainer, rotateToInfo, { Rotation = 2 })
	rotateTo:Play()
	rotateTo.Completed:Connect(function()
		if isDestroyed then return end
		TweenService:Create(centerContainer, rotateToInfo, { Rotation = 0 }):Play()
	end)

	-- 0.1s: Spotlight rotation
	task.delay(0.1, function()
		if isDestroyed then return end
		local spotRotInfo = TweenInfo.new(2.0, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		TweenService:Create(spotlightGradient, spotRotInfo, { Rotation = 360 }):Play()

		local specGrad = introGlass.SpecularGradient
		if specGrad then
			TweenService:Create(specGrad, spotRotInfo, { Rotation = 360 }):Play()
		end
	end)

	-- 0.3s: Glow pulse
	task.delay(0.3, function()
		if isDestroyed then return end
		local glowPulseInfo = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 1, true)
		TweenService:Create(glowText, glowPulseInfo, { TextTransparency = 0.30 }):Play()
	end)

	-- Subtitle fade-in
	if subtitleLabel then
		task.delay(0.3, function()
			if isDestroyed then return end
			TweenService:Create(subtitleLabel :: TextLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				TextTransparency = 0.3,
			}):Play()
		end)
	end

	-- 0.5s: Shimmer sweep
	task.delay(0.5, function()
		if isDestroyed then return end
		local shimmerSweepInfo = TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		TweenService:Create(shimmerGradient, shimmerSweepInfo, { Offset = Vector2.new(0.5, 0) }):Play()
		task.delay(1.2, function()
			if isDestroyed then return end
			TweenService:Create(shimmerFrame, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play()
		end)
	end)

	-- 1.2s: Cross-fade spotlight
	task.delay(1.2, function()
		if isDestroyed then return end
		local fadeOutInfo = TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
		TweenService:Create(spotlightFrame1, fadeOutInfo, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(spotlightFrame2, fadeOutInfo, { BackgroundTransparency = 0.85 }):Play()
	end)

	-- 2.0s: Fade out everything
	task.delay(2.0, function()
		if isDestroyed then return end
		local fadeOutInfo = TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
		TweenService:Create(introGlass.GlassSurface, fadeOutInfo, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(logoText, fadeOutInfo, { TextTransparency = 1 }):Play()
		TweenService:Create(glowText, fadeOutInfo, { TextTransparency = 1 }):Play()
		TweenService:Create(backShadowText, fadeOutInfo, { TextTransparency = 1 }):Play()
		TweenService:Create(glassEdgeText, fadeOutInfo, { TextTransparency = 1 }):Play()
		TweenService:Create(overlay, fadeOutInfo, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(spotlightFrame2, fadeOutInfo, { BackgroundTransparency = 1 }):Play()
		if subtitleLabel then
			TweenService:Create(subtitleLabel :: TextLabel, fadeOutInfo, { TextTransparency = 1 }):Play()
		end
	end)

	-- 2.5s: Cleanup + callback
	task.delay(2.5, function()
		if isDestroyed then return end
		isDestroyed = true
		if introSound then
			introSound:Destroy()
			introSound = nil
		end
		if gui then
			gui:Destroy()
		end
		introGui = nil
		isPlaying = false
		if onComplete then
			onComplete()
		end
	end)
end

return module
