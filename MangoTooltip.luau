--!strict

local Types = require(script.Parent.Types)
local Themes = require(script.Parent.Themes)
local MangoGlassFrame = require(script.Parent.MangoGlassFrame)
local resolve = Themes.resolve
local MangoProtection = require(script.Parent.MangoProtection)
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")

local module = {}

local function findScreenGui(instance: Instance): ScreenGui?
	local current: Instance? = instance
	while current do
		if current:IsA("ScreenGui") then
			return current :: ScreenGui
		end
		current = current.Parent
	end
	return nil
end

function module.new(config: Types.MangoTooltipConfig): Types.MangoTooltip
	local theme = config.Theme
	local target = config.Target
	local text = resolve(config.Text, nil, "Tooltip") :: string
	local textSize = resolve(config.TextSize, nil, 13) :: number
	local maxWidth = resolve(config.MaxWidth, nil, 200) :: number
	local delayTime = resolve(config.Delay, nil, 0.5) :: number
	local placement = resolve(config.Placement, nil, "auto") :: string
	local arrowSize = resolve(config.ArrowSize, nil, 8) :: number

	-- Theme-driven properties
	local bgTransparency = resolve(nil, theme and theme.TooltipBackgroundTransparency, 0.15) :: number
	local bgColor = resolve(nil, theme and theme.BackgroundColor3, Color3.fromRGB(255, 255, 255)) :: Color3
	local textColor = resolve(nil, theme and theme.PrimaryTextColor, Color3.fromRGB(0, 0, 0)) :: Color3

	-- Padding
	local paddingH = 16
	local paddingV = 12

	-- Measure text
	local font = Enum.Font.Gotham
	local textBounds = TextService:GetTextSize(text, textSize, font, Vector2.new(maxWidth - paddingH, 1000))
	local tooltipWidth = math.min(textBounds.X + paddingH, maxWidth)
	local tooltipHeight = textBounds.Y + paddingV

	-- State
	local isVisible = false
	local isDestroyed = false
	local activeTweens: {Tween} = {}
	local connections: {RBXScriptConnection} = {}
	local delayThread: thread? = nil
	local currentPlacement = "top"

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

	-- Determine parent
	local parentGui: GuiObject
	if config.Parent then
		parentGui = config.Parent
	else
		local screenGui = findScreenGui(target)
		if screenGui then
			parentGui = screenGui :: any
		else
			parentGui = target.Parent :: GuiObject
		end
	end

	-- Glass frame for tooltip body
	local glassFrame = MangoGlassFrame.new({
		Size = UDim2.new(0, tooltipWidth, 0, tooltipHeight),
		Position = UDim2.new(0, 0, 0, 0),
		CornerRadius = UDim.new(0, 8),
		BackgroundTransparency = bgTransparency,
		LightweightMode = true,
		ShadowEnabled = true,
		ShadowLayerCount = 2,
		ShadowSpread = 4,
		ShadowOffsetY = 2,
		Theme = theme,
		Parent = parentGui,
	})

	local container = glassFrame.Container
	container.Visible = false
	container.ZIndex = 200

	-- UIScale for animation
	local uiScale = Instance.new("UIScale")
	uiScale.Scale = 0.9
	uiScale.Parent = container

	-- TextLabel inside GlassSurface
	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "TooltipText"
	textLabel.Text = text
	textLabel.Font = font
	textLabel.TextSize = textSize
	textLabel.TextColor3 = textColor
	textLabel.TextWrapped = true
	textLabel.TextXAlignment = Enum.TextXAlignment.Center
	textLabel.TextYAlignment = Enum.TextYAlignment.Center
	textLabel.BackgroundTransparency = 1
	textLabel.BorderSizePixel = 0
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.ZIndex = 10
	textLabel.Parent = glassFrame.GlassSurface

	-- Arrow (45-degree rotated frame)
	local arrow = Instance.new("Frame")
	arrow.Name = "TooltipArrow"
	arrow.Size = UDim2.new(0, arrowSize, 0, arrowSize)
	arrow.Rotation = 45
	arrow.BackgroundColor3 = bgColor
	arrow.BackgroundTransparency = bgTransparency
	arrow.BorderSizePixel = 0
	arrow.ZIndex = 0
	arrow.Parent = container

	-- Helper to get viewport size
	local function getViewportSize(): Vector2
		local camera = game:GetService("Workspace").CurrentCamera
		if camera then
			return camera.ViewportSize
		end
		return Vector2.new(1920, 1080)
	end

	-- Position tooltip relative to target
	local function positionTooltip(desiredPlacement: string)
		local targetPos = target.AbsolutePosition
		local targetSize = target.AbsoluteSize
		local viewportSize = getViewportSize()
		local gap = arrowSize / 2 + 4

		local tx = targetPos.X + targetSize.X / 2
		local ty = targetPos.Y

		local tooltipX: number
		local tooltipY: number
		local arrowX: number
		local arrowY: number
		local finalPlacement = desiredPlacement

		if finalPlacement == "auto" then
			finalPlacement = "top"
		end

		-- Try the requested placement, fall back if offscreen
		local function tryPlacement(p: string): boolean
			if p == "top" then
				tooltipX = tx - tooltipWidth / 2
				tooltipY = targetPos.Y - tooltipHeight - gap
				arrowX = tooltipWidth / 2 - arrowSize / 2
				arrowY = tooltipHeight - arrowSize / 2
				return tooltipY >= 0
			elseif p == "bottom" then
				tooltipX = tx - tooltipWidth / 2
				tooltipY = targetPos.Y + targetSize.Y + gap
				arrowX = tooltipWidth / 2 - arrowSize / 2
				arrowY = -arrowSize / 2
				return tooltipY + tooltipHeight <= viewportSize.Y
			elseif p == "left" then
				tooltipX = targetPos.X - tooltipWidth - gap
				tooltipY = ty + targetSize.Y / 2 - tooltipHeight / 2
				arrowX = tooltipWidth - arrowSize / 2
				arrowY = tooltipHeight / 2 - arrowSize / 2
				return tooltipX >= 0
			elseif p == "right" then
				tooltipX = targetPos.X + targetSize.X + gap
				tooltipY = ty + targetSize.Y / 2 - tooltipHeight / 2
				arrowX = -arrowSize / 2
				arrowY = tooltipHeight / 2 - arrowSize / 2
				return tooltipX + tooltipWidth <= viewportSize.X
			end
			return false
		end

		if not tryPlacement(finalPlacement) then
			local fallbacks = {"top", "bottom", "left", "right"}
			local placed = false
			for _, fb in fallbacks do
				if fb ~= finalPlacement and tryPlacement(fb) then
					finalPlacement = fb
					placed = true
					break
				end
			end
			if not placed then
				tryPlacement("top")
				finalPlacement = "top"
			end
		end

		-- Clamp to viewport
		tooltipX = math.clamp(tooltipX, 4, viewportSize.X - tooltipWidth - 4)
		tooltipY = math.clamp(tooltipY, 4, viewportSize.Y - tooltipHeight - 4)

		container.Position = UDim2.new(0, tooltipX, 0, tooltipY)
		arrow.Position = UDim2.new(0, arrowX, 0, arrowY)
		currentPlacement = finalPlacement
	end

	-- Remeasure and resize
	local function remeasure()
		local bounds = TextService:GetTextSize(textLabel.Text, textSize, font, Vector2.new(maxWidth - paddingH, 1000))
		tooltipWidth = math.min(bounds.X + paddingH, maxWidth)
		tooltipHeight = bounds.Y + paddingV
		container.Size = UDim2.new(0, tooltipWidth, 0, tooltipHeight)
	end

	-- Connect hover events on target
	local enterConn = target.MouseEnter:Connect(function()
		if isDestroyed or isVisible then
			return
		end
		-- Start delay
		if delayThread then
			task.cancel(delayThread)
			delayThread = nil
		end
		delayThread = task.delay(delayTime, function()
			delayThread = nil
			if not isDestroyed and not isVisible then
				-- Show tooltip
				isVisible = true
				positionTooltip(placement)
				container.Visible = true
				uiScale.Scale = 0.9

				cancelAllTweens()
				local tweenIn = TweenService:Create(uiScale, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
					Scale = 1.0,
				})
				trackTween(tweenIn)
				tweenIn:Play()
			end
		end)
	end)
	table.insert(connections, enterConn)

	local leaveConn = target.MouseLeave:Connect(function()
		if isDestroyed then
			return
		end
		-- Cancel pending delay
		if delayThread then
			task.cancel(delayThread)
			delayThread = nil
		end
		if isVisible then
			isVisible = false
			cancelAllTweens()
			local tweenOut = TweenService:Create(uiScale, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Scale = 0.95,
			})
			trackTween(tweenOut)
			tweenOut:Play()
			tweenOut.Completed:Connect(function()
				if not isVisible and not isDestroyed then
					container.Visible = false
				end
			end)
		end
	end)
	table.insert(connections, leaveConn)

	-- Return table
	local self: Types.MangoTooltip = {
		Show = function(self: Types.MangoTooltip)
			if isDestroyed or isVisible then
				return
			end
			isVisible = true
			-- Cancel pending delay
			if delayThread then
				task.cancel(delayThread)
				delayThread = nil
			end
			positionTooltip(placement)
			container.Visible = true
			uiScale.Scale = 0.9

			cancelAllTweens()
			local tweenIn = TweenService:Create(uiScale, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Scale = 1.0,
			})
			trackTween(tweenIn)
			tweenIn:Play()
		end,
		Hide = function(self: Types.MangoTooltip)
			if isDestroyed or not isVisible then
				return
			end
			isVisible = false
			-- Cancel pending delay
			if delayThread then
				task.cancel(delayThread)
				delayThread = nil
			end

			cancelAllTweens()
			local tweenOut = TweenService:Create(uiScale, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Scale = 0.95,
			})
			trackTween(tweenOut)
			tweenOut:Play()
			tweenOut.Completed:Connect(function()
				if not isVisible and not isDestroyed then
					container.Visible = false
				end
			end)
		end,
		SetText = function(self: Types.MangoTooltip, newText: string)
			if isDestroyed then
				return
			end
			textLabel.Text = newText
			remeasure()
			if isVisible then
				positionTooltip(currentPlacement)
			end
		end,
		Destroy = function(self: Types.MangoTooltip)
			if isDestroyed then
				return
			end
			isDestroyed = true

			if delayThread then
				task.cancel(delayThread)
				delayThread = nil
			end

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
