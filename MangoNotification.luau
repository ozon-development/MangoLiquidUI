--!strict

local Types = require(script.Parent.Types)
local Themes = require(script.Parent.Themes)
local MangoGlassFrame = require(script.Parent.MangoGlassFrame)
local resolve = Themes.resolve
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local Players = game:GetService("Players")

local module = {}

function module.new(config: Types.MangoNotificationConfig): Types.MangoNotification
	local theme = config.Theme
	local title = config.Title
	local body = config.Body
	local icon = config.Icon
	local duration = resolve(config.Duration, nil, 5) :: number

	-- Theme-driven visual properties
	local primaryTextColor = resolve(nil, theme and theme.PrimaryTextColor, Color3.fromRGB(0, 0, 0)) :: Color3
	local secondaryTextColor = resolve(nil, theme and theme.SecondaryTextColor, Color3.fromRGB(60, 60, 70)) :: Color3

	-- Measure text to calculate height
	local titleFont = Enum.Font.GothamBold
	local bodyFont = Enum.Font.Gotham
	local titleSize = 15
	local bodySize = 13
	local contentWidth = 380 - 28 -- 14px padding on each side
	local hasIcon = icon ~= nil and icon ~= ""
	if hasIcon then
		contentWidth = contentWidth - 48 -- 36px icon + 12px gap
	end

	local titleBounds = TextService:GetTextSize(title, titleSize, titleFont, Vector2.new(contentWidth, 1000))
	local totalHeight = 28 + titleBounds.Y -- 14px top + 14px bottom padding

	local bodyBounds: Vector2? = nil
	if body and body ~= "" then
		bodyBounds = TextService:GetTextSize(body, bodySize, bodyFont, Vector2.new(contentWidth, 1000))
		totalHeight = totalHeight + 2 + (bodyBounds :: Vector2).Y -- 2px gap
	end

	-- Clamp height
	totalHeight = math.clamp(totalHeight, 64, 120)

	-- State
	local isShowing = false
	local isDismissing = false
	local isDestroyed = false
	local activeTweens: {Tween} = {}
	local connections: {RBXScriptConnection} = {}
	local dismissThread: thread? = nil
	local positionTweens: {Tween} = {}

	local function cancelAllTweens()
		for _, tween in activeTweens do
			tween:Cancel()
		end
		table.clear(activeTweens)
	end

	local function cancelPositionTweens()
		for _, tween in positionTweens do
			tween:Cancel()
		end
		table.clear(positionTweens)
	end

	local function trackTween(tween: Tween): Tween
		table.insert(activeTweens, tween)
		return tween
	end

	-- Determine parent: config.Parent or create a ScreenGui in PlayerGui
	local screenGui: ScreenGui? = nil
	local parentInstance: Instance
	if config.Parent then
		parentInstance = config.Parent
	else
		local player = Players.LocalPlayer
		local playerGui = player:WaitForChild("PlayerGui")
		local gui = Instance.new("ScreenGui")
		gui.Name = "MangoNotificationGui"
		gui.ResetOnSpawn = false
		gui.IgnoreGuiInset = true
		gui.DisplayOrder = 100
		gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		gui.Parent = playerGui
		screenGui = gui
		parentInstance = gui
	end

	-- NotificationContainer (starts offscreen above)
	local notifContainer = Instance.new("Frame")
	notifContainer.Name = "MangoNotification"
	notifContainer.Size = UDim2.new(0, 380, 0, totalHeight)
	notifContainer.AnchorPoint = Vector2.new(0.5, 0)
	notifContainer.Position = UDim2.new(0.5, 0, 0, -80)
	notifContainer.BackgroundTransparency = 1
	notifContainer.BorderSizePixel = 0
	notifContainer.Parent = parentInstance

	-- Glass frame inside
	local glassFrame = MangoGlassFrame.new({
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		CornerRadius = UDim.new(0, 20),
		Theme = theme,
		ShadowEnabled = true,
		ShadowLayerCount = 4,
		ShadowOffsetY = 4,
		ShadowSpread = 12,
		Parent = notifContainer,
	})

	-- Store target transparency for fade-in animation
	local targetBgTransparency = glassFrame.GlassSurface.BackgroundTransparency

	-- UIPadding on GlassSurface
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 14)
	padding.PaddingBottom = UDim.new(0, 14)
	padding.PaddingLeft = UDim.new(0, 14)
	padding.PaddingRight = UDim.new(0, 14)
	padding.Parent = glassFrame.GlassSurface

	-- UIListLayout (Horizontal, 12px gap)
	local hLayout = Instance.new("UIListLayout")
	hLayout.FillDirection = Enum.FillDirection.Horizontal
	hLayout.Padding = UDim.new(0, 12)
	hLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	hLayout.SortOrder = Enum.SortOrder.LayoutOrder
	hLayout.Parent = glassFrame.GlassSurface

	-- Icon (optional)
	if hasIcon then
		local iconFrame = Instance.new("ImageLabel")
		iconFrame.Name = "IconFrame"
		iconFrame.Size = UDim2.new(0, 36, 0, 36)
		iconFrame.Image = icon :: string
		iconFrame.BackgroundTransparency = 1
		iconFrame.BorderSizePixel = 0
		iconFrame.LayoutOrder = 1
		iconFrame.ZIndex = 10
		iconFrame.Parent = glassFrame.GlassSurface

		local iconCorner = Instance.new("UICorner")
		iconCorner.CornerRadius = UDim.new(0, 8)
		iconCorner.Parent = iconFrame
	end

	-- TextContainer
	local textContainer = Instance.new("Frame")
	textContainer.Name = "TextContainer"
	textContainer.Size = UDim2.new(1, if hasIcon then -48 else 0, 1, 0)
	textContainer.BackgroundTransparency = 1
	textContainer.BorderSizePixel = 0
	textContainer.LayoutOrder = 2
	textContainer.ZIndex = 10
	textContainer.Parent = glassFrame.GlassSurface

	-- Vertical layout inside TextContainer
	local vLayout = Instance.new("UIListLayout")
	vLayout.FillDirection = Enum.FillDirection.Vertical
	vLayout.Padding = UDim.new(0, 2)
	vLayout.SortOrder = Enum.SortOrder.LayoutOrder
	vLayout.Parent = textContainer

	-- TitleLabel
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Text = title
	titleLabel.Font = titleFont
	titleLabel.TextSize = titleSize
	titleLabel.TextColor3 = primaryTextColor
	titleLabel.BackgroundTransparency = 1
	titleLabel.Size = UDim2.new(1, 0, 0, titleBounds.Y)
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.TextYAlignment = Enum.TextYAlignment.Top
	titleLabel.TextWrapped = true
	titleLabel.BorderSizePixel = 0
	titleLabel.LayoutOrder = 1
	titleLabel.ZIndex = 10
	titleLabel.Parent = textContainer

	-- BodyLabel (optional)
	if body and body ~= "" and bodyBounds then
		local bodyLabel = Instance.new("TextLabel")
		bodyLabel.Name = "BodyLabel"
		bodyLabel.Text = body
		bodyLabel.Font = bodyFont
		bodyLabel.TextSize = bodySize
		bodyLabel.TextColor3 = secondaryTextColor
		bodyLabel.BackgroundTransparency = 1
		bodyLabel.Size = UDim2.new(1, 0, 0, (bodyBounds :: Vector2).Y)
		bodyLabel.TextXAlignment = Enum.TextXAlignment.Left
		bodyLabel.TextYAlignment = Enum.TextYAlignment.Top
		bodyLabel.TextWrapped = true
		bodyLabel.BorderSizePixel = 0
		bodyLabel.LayoutOrder = 2
		bodyLabel.ZIndex = 10
		bodyLabel.Parent = textContainer
	end

	-- Hit area for tap-to-dismiss (transparent TextButton for reliable input on transparent container)
	local dismissHitArea = Instance.new("TextButton")
	dismissHitArea.Name = "DismissHitArea"
	dismissHitArea.Size = UDim2.new(1, 0, 1, 0)
	dismissHitArea.BackgroundTransparency = 1
	dismissHitArea.BorderSizePixel = 0
	dismissHitArea.Text = ""
	dismissHitArea.AutoButtonColor = false
	dismissHitArea.ZIndex = 50
	dismissHitArea.Parent = notifContainer

	-- Tap to dismiss
	local tapConn = dismissHitArea.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			if isShowing and not isDismissing then
				-- Forward reference to dismiss — handled via self
				isDismissing = true
				-- Cancel auto-dismiss thread to prevent leaked task.delay
				if dismissThread then
					task.cancel(dismissThread)
					dismissThread = nil
				end
				cancelAllTweens()
				local tweenOut = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
				local slideTween = TweenService:Create(notifContainer, tweenOut, {
					Position = UDim2.new(0.5, 0, 0, -80),
				})
				trackTween(slideTween)
				slideTween:Play()
				slideTween.Completed:Connect(function()
					if not isDestroyed then
						if config.OnDismissed then
							config.OnDismissed()
						end
						-- Auto-destroy after dismiss
						isDestroyed = true
						for _, conn in connections do
							conn:Disconnect()
						end
						table.clear(connections)
						glassFrame:Destroy()
						notifContainer:Destroy()
						if screenGui then
							screenGui:Destroy()
						end
					end
				end)
			end
		end
	end)
	table.insert(connections, tapConn)

	-- Return table
	local self: Types.MangoNotification = {
		Container = notifContainer,
		Show = function(self: Types.MangoNotification)
			if isShowing or isDestroyed then
				return
			end
			isShowing = true

			-- Start with glass surface fully transparent for fade-in
			glassFrame.GlassSurface.BackgroundTransparency = 1

			-- Spring tween to visible position
			cancelAllTweens()
			local springInfo = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			local slideTween = TweenService:Create(notifContainer, springInfo, {
				Position = UDim2.new(0.5, 0, 0, 16),
			})
			trackTween(slideTween)
			slideTween:Play()

			-- Fade in glass surface
			local fadeInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			local fadeTween = TweenService:Create(glassFrame.GlassSurface, fadeInfo, {
				BackgroundTransparency = targetBgTransparency,
			})
			trackTween(fadeTween)
			fadeTween:Play()

			-- Auto-dismiss after duration (0 = no auto-dismiss)
			if duration > 0 then
				dismissThread = task.delay(duration, function()
					if not isDismissing and not isDestroyed and isShowing then
						self:Dismiss()
					end
				end)
			end
		end,
		Dismiss = function(self: Types.MangoNotification)
			if isDismissing or isDestroyed or not isShowing then
				return
			end
			isDismissing = true

			-- Cancel auto-dismiss thread
			if dismissThread then
				task.cancel(dismissThread)
				dismissThread = nil
			end

			cancelAllTweens()
			local tweenOut = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			local slideTween = TweenService:Create(notifContainer, tweenOut, {
				Position = UDim2.new(0.5, 0, 0, -80),
			})
			trackTween(slideTween)
			slideTween:Play()
			slideTween.Completed:Connect(function()
				if not isDestroyed then
					if config.OnDismissed then
						config.OnDismissed()
					end
					-- Auto-destroy after dismiss
					self:Destroy()
				end
			end)
		end,
		SetPosition = function(self: Types.MangoNotification, position: UDim2)
			if isDestroyed then
				return
			end
			cancelPositionTweens()
			local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			local posTween = TweenService:Create(notifContainer, tweenInfo, {
				Position = position,
			})
			table.insert(positionTweens, posTween)
			posTween:Play()
		end,
		GetHeight = function(self: Types.MangoNotification): number
			return totalHeight
		end,
		Destroy = function(self: Types.MangoNotification)
			if isDestroyed then
				return
			end
			isDestroyed = true

			-- Cancel auto-dismiss thread
			if dismissThread then
				task.cancel(dismissThread)
				dismissThread = nil
			end

			cancelAllTweens()
			cancelPositionTweens()
			for _, conn in connections do
				conn:Disconnect()
			end
			table.clear(connections)
			glassFrame:Destroy()
			notifContainer:Destroy()
			if screenGui then
				screenGui:Destroy()
			end
		end,
	}

	return self
end

return module
