--!strict

local Types = require(script.Parent.Types)
local Themes = require(script.Parent.Themes)
local MangoGlassFrame = require(script.Parent.MangoGlassFrame)
local MangoProtection = require(script.Parent.MangoProtection)
local resolve = Themes.resolve
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")

local module = {}

function module.new(config: Types.MangoNotificationConfig): Types.MangoNotification
	local theme = config.Theme
	local title = resolve(config.Title, nil, "Notification") :: string
	local body = config.Body
	local icon = config.Icon
	local duration = resolve(config.Duration, nil, 5) :: number

	-- Theme-driven visual properties
	local primaryTextColor = resolve(nil, theme and theme.PrimaryTextColor, Color3.fromRGB(0, 0, 0)) :: Color3
	local secondaryTextColor = resolve(nil, theme and theme.SecondaryTextColor, Color3.fromRGB(60, 60, 70)) :: Color3

	-- Notification type styling
	local notifType = config.Type
	local typeColors: {[string]: Color3} = {
		success = Color3.fromRGB(34, 197, 94),
		warning = Color3.fromRGB(245, 158, 11),
		error = Color3.fromRGB(239, 68, 68),
		info = Color3.fromRGB(59, 130, 246),
	}
	local typeIcons: {[string]: string} = {
		success = "\226\156\147", -- checkmark
		warning = "\226\154\160", -- warning sign
		error = "\226\156\149", -- x mark
		info = "\226\132\185", -- info sign
	}

	-- Measure text to calculate height
	local titleFont = Enum.Font.GothamBold
	local bodyFont = Enum.Font.Gotham
	local titleSize = 15
	local bodySize = 13
	local contentWidth = 400 - 28 -- 14px padding on each side
	local hasIcon = icon ~= nil and icon ~= ""

	-- Auto-set icon from type if no explicit icon
	if notifType and typeIcons[notifType] and not hasIcon then
		icon = typeIcons[notifType]
		hasIcon = true
	end

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

	-- Account for action buttons height
	local actions = config.Actions
	if actions and #actions > 0 then
		totalHeight = totalHeight + 36
	end

	-- Clamp height
	totalHeight = math.clamp(totalHeight, 64, 160)

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
		local gui = MangoProtection.createScreenGui({
			DisplayOrder = 100,
		})
		screenGui = gui
		parentInstance = gui
	end

	-- NotificationContainer (starts offscreen above)
	local notifContainer = Instance.new("Frame")
	notifContainer.Name = MangoProtection.randomName("Notification")
	notifContainer.Size = UDim2.new(0, 400, 0, totalHeight)
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
		LightweightMode = true,
		Parent = notifContainer,
	})

	-- Store target transparency for fade-in animation
	local targetBgTransparency = glassFrame.GlassSurface.BackgroundTransparency

	-- Accent stripe for typed notifications
	if notifType and typeColors[notifType] then
		local accentStripe = Instance.new("Frame")
		accentStripe.Name = "AccentStripe"
		accentStripe.Size = UDim2.new(0, 3, 1, -8)
		accentStripe.Position = UDim2.new(0, 4, 0, 4)
		accentStripe.BackgroundColor3 = typeColors[notifType]
		accentStripe.BackgroundTransparency = 0.1
		accentStripe.BorderSizePixel = 0
		accentStripe.ZIndex = 15
		accentStripe.Parent = glassFrame.GlassSurface

		local stripeCorner = Instance.new("UICorner")
		stripeCorner.CornerRadius = UDim.new(0, 2)
		stripeCorner.Parent = accentStripe
	end

	-- ContentFrame (isolates UIListLayout from glass frame internals like InnerEdgeFrame)
	local contentFrame = Instance.new("Frame")
	contentFrame.Name = "ContentFrame"
	contentFrame.Size = UDim2.new(1, 0, 1, 0)
	contentFrame.BackgroundTransparency = 1
	contentFrame.BorderSizePixel = 0
	contentFrame.ZIndex = 10
	contentFrame.Parent = glassFrame.GlassSurface

	-- UIPadding on ContentFrame
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 14)
	padding.PaddingBottom = UDim.new(0, 14)
	padding.PaddingLeft = UDim.new(0, 14)
	padding.PaddingRight = UDim.new(0, 14)
	padding.Parent = contentFrame

	-- UIListLayout (Horizontal, 12px gap)
	local hLayout = Instance.new("UIListLayout")
	hLayout.FillDirection = Enum.FillDirection.Horizontal
	hLayout.Padding = UDim.new(0, 12)
	hLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	hLayout.SortOrder = Enum.SortOrder.LayoutOrder
	hLayout.Parent = contentFrame

	-- Icon (optional — supports both image IDs and text emoji from type icons)
	if hasIcon and icon then
		local isImageIcon = string.find(icon, "rbxassetid") ~= nil or string.find(icon, "rbxthumb") ~= nil
		if isImageIcon then
			local iconFrame = Instance.new("ImageLabel")
			iconFrame.Name = "IconFrame"
			iconFrame.Size = UDim2.new(0, 36, 0, 36)
			iconFrame.Image = icon
			iconFrame.BackgroundTransparency = 1
			iconFrame.BorderSizePixel = 0
			iconFrame.LayoutOrder = 1
			iconFrame.ZIndex = 10
			iconFrame.Parent = contentFrame

			local iconCorner = Instance.new("UICorner")
			iconCorner.CornerRadius = UDim.new(0, 8)
			iconCorner.Parent = iconFrame
		else
			-- Text-based icon (emoji from type or user-provided text)
			local iconContainer = Instance.new("Frame")
			iconContainer.Name = "IconFrame"
			iconContainer.Size = UDim2.new(0, 36, 0, 36)
			iconContainer.BackgroundColor3 = if notifType and typeColors[notifType] then typeColors[notifType] else Color3.fromRGB(200, 200, 200)
			iconContainer.BackgroundTransparency = 0.85
			iconContainer.BorderSizePixel = 0
			iconContainer.LayoutOrder = 1
			iconContainer.ZIndex = 10
			iconContainer.Parent = contentFrame

			local iconContainerCorner = Instance.new("UICorner")
			iconContainerCorner.CornerRadius = UDim.new(0, 8)
			iconContainerCorner.Parent = iconContainer

			local iconText = Instance.new("TextLabel")
			iconText.Name = "IconText"
			iconText.Size = UDim2.new(1, 0, 1, 0)
			iconText.BackgroundTransparency = 1
			iconText.BorderSizePixel = 0
			iconText.Font = Enum.Font.GothamBold
			iconText.TextSize = 18
			iconText.Text = icon
			iconText.TextColor3 = if notifType and typeColors[notifType] then typeColors[notifType] else primaryTextColor
			iconText.ZIndex = 10
			iconText.Parent = iconContainer
		end
	end

	-- TextContainer
	local textContainer = Instance.new("Frame")
	textContainer.Name = "TextContainer"
	textContainer.Size = UDim2.new(1, if hasIcon then -48 else 0, 1, 0)
	textContainer.BackgroundTransparency = 1
	textContainer.BorderSizePixel = 0
	textContainer.LayoutOrder = 2
	textContainer.ZIndex = 10
	textContainer.Parent = contentFrame

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

	-- Forward-declared dismiss function (shared by action buttons, tap-to-dismiss, and self.Dismiss)
	local doDismiss: (() -> ())? = nil
	local doDestroy: (() -> ())? = nil

	local function performDismiss()
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
		cancelPositionTweens()
		local tweenOut = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		local slideTween = TweenService:Create(notifContainer, tweenOut, {
			Position = UDim2.new(0.5, 0, 0, -80),
		})
		trackTween(slideTween)
		slideTween:Play()
		slideTween.Completed:Once(function()
			if not isDestroyed then
				-- Set isDestroyed BEFORE callback to prevent re-entrancy
				isDestroyed = true
				if config.OnDismissed then
					config.OnDismissed()
				end
				-- Clean up
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
			end
		end)
	end

	doDismiss = performDismiss

	-- Action buttons
	if actions and #actions > 0 then
		local actionsRow = Instance.new("Frame")
		actionsRow.Name = "ActionsRow"
		actionsRow.Size = UDim2.new(1, 0, 0, 28)
		actionsRow.BackgroundTransparency = 1
		actionsRow.BorderSizePixel = 0
		actionsRow.LayoutOrder = 3
		actionsRow.ZIndex = 10
		actionsRow.Parent = textContainer

		local actionsLayout = Instance.new("UIListLayout")
		actionsLayout.FillDirection = Enum.FillDirection.Horizontal
		actionsLayout.Padding = UDim.new(0, 8)
		actionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
		actionsLayout.Parent = actionsRow

		for i, action in actions do
			local actionBtn = Instance.new("TextButton")
			actionBtn.Name = "Action" .. i
			actionBtn.Size = UDim2.new(0, 70, 0, 28)
			actionBtn.BackgroundColor3 = if action.Style == "cancel" then Color3.fromRGB(200, 200, 205) else (notifType and typeColors[notifType] or Color3.fromRGB(0, 122, 255))
			actionBtn.BackgroundTransparency = 0.75
			actionBtn.BorderSizePixel = 0
			actionBtn.Font = if action.Style == "cancel" then Enum.Font.GothamMedium else Enum.Font.GothamBold
			actionBtn.TextSize = 12
			actionBtn.Text = action.Text
			actionBtn.TextColor3 = if action.Style == "cancel" then secondaryTextColor else primaryTextColor
			actionBtn.AutoButtonColor = false
			actionBtn.ZIndex = 10
			actionBtn.LayoutOrder = i
			actionBtn.Parent = actionsRow

			local btnCorner = Instance.new("UICorner")
			btnCorner.CornerRadius = UDim.new(0, 999)
			btnCorner.Parent = actionBtn

			local btnConn = actionBtn.MouseButton1Click:Connect(function()
				if action.Callback then
					action.Callback()
				end
				performDismiss()
			end)
			table.insert(connections, btnConn)
		end
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
			performDismiss()
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
						performDismiss()
					end
				end)
			end
		end,
		Dismiss = function(self: Types.MangoNotification)
			performDismiss()
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
