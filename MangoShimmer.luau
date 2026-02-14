--!strict

local TweenService = game:GetService("TweenService")

local Types = require(script.Parent.Types)
local Themes = require(script.Parent.Themes)
local resolve = Themes.resolve
local MangoProtection = require(script.Parent.MangoProtection)

local module = {}

function module.new(config: Types.MangoShimmerConfig): Types.MangoShimmer
	local theme = config.Theme or Themes.Light

	local shimmerColor: Color3 = resolve(config.ShimmerColor, theme.ShimmerColor, Color3.fromRGB(255, 255, 255))
	local shimmerTransparency: number = resolve(config.ShimmerTransparency, theme.ShimmerTransparency, 0.85)
	local shimmerWidth: number = resolve(config.ShimmerWidth, nil, 0.08)
	local duration: number = resolve(config.Duration, nil, 1.2)

	local enabled = false
	local isDestroyed = false
	local activeTween: Tween? = nil

	-- Create overlay Frame
	local overlay = Instance.new("Frame")
	overlay.Name = "ShimmerOverlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.Position = UDim2.new(0, 0, 0, 0)
	overlay.BackgroundColor3 = shimmerColor
	overlay.BackgroundTransparency = shimmerTransparency
	overlay.BorderSizePixel = 0
	overlay.ZIndex = 50
	overlay.Visible = false

	-- Match Target's UICorner if present
	local targetCorner = config.Target:FindFirstChildWhichIsA("UICorner")
	if targetCorner then
		local corner = Instance.new("UICorner")
		corner.CornerRadius = targetCorner.CornerRadius
		corner.Parent = overlay
	end

	-- Create narrow-band shimmer gradient
	local gradient = Instance.new("UIGradient")
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5 - shimmerWidth / 2, 1),
		NumberSequenceKeypoint.new(0.5, 0),
		NumberSequenceKeypoint.new(0.5 + shimmerWidth / 2, 1),
		NumberSequenceKeypoint.new(1, 1),
	})
	gradient.Offset = Vector2.new(-0.5, 0)
	gradient.Parent = overlay

	overlay.Parent = config.Target

	-- Shimmer controller
	local self = {} :: Types.MangoShimmer

	function self:Enable()
		if isDestroyed or enabled then
			return
		end
		enabled = true
		overlay.Visible = true
		gradient.Offset = Vector2.new(-0.5, 0)

		local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, false, 0)
		activeTween = TweenService:Create(gradient, tweenInfo, { Offset = Vector2.new(0.5, 0) })
		activeTween:Play()
	end

	function self:Disable()
		if isDestroyed or not enabled then
			return
		end
		enabled = false
		if activeTween then
			activeTween:Cancel()
			activeTween = nil
		end
		overlay.Visible = false
		gradient.Offset = Vector2.new(-0.5, 0)
	end

	function self:IsEnabled(): boolean
		return enabled
	end

	function self:Destroy()
		if isDestroyed then
			return
		end
		isDestroyed = true
		if activeTween then
			activeTween:Cancel()
			activeTween = nil
		end
		overlay:Destroy()
	end

	-- Auto-enable unless explicitly disabled
	if config.Enabled ~= false then
		self:Enable()
	end

	return self
end

return module
