--!strict

local Types = require(script.Parent.Types)
local Themes = require(script.Parent.Themes)
local MangoGlassFrame = require(script.Parent.MangoGlassFrame)
local MangoProtection = require(script.Parent.MangoProtection)
local resolve = Themes.resolve
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")

local module = {}

function module.new(config: Types.MangoDialogConfig): Types.MangoDialog
	local theme = config.Theme
	local title = resolve(config.Title, nil, "Dialog") :: string
	local message = config.Message
	local buttons = config.Buttons

	-- Theme-driven values
	local overlayTransparency = resolve(nil, theme and theme.DialogOverlayTransparency, 0.40) :: number
	local dialogBgTransparency = resolve(nil, theme and theme.DialogBackgroundTransparency, 0.78) :: number
	local primaryTextColor = resolve(nil, theme and theme.PrimaryTextColor, Color3.fromRGB(0, 0, 0)) :: Color3
	local secondaryTextColor = resolve(nil, theme and theme.SecondaryTextColor, Color3.fromRGB(60, 60, 70)) :: Color3

	-- If no buttons config, add a single OK button
	if not buttons or #buttons == 0 then
		buttons = {
			{ Text = "OK", Style = "cancel" },
		}
	end

	-- State
	local isShowing = false
	local isDismissing = false
	local isDestroyed = false
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

	-- Create ScreenGui
	local screenGui: ScreenGui? = nil
	local parentInstance: Instance
	if config.Parent then
		parentInstance = config.Parent
	else
		local gui = MangoProtection.createScreenGui({
			DisplayOrder = 150,
		})
		screenGui = gui
		parentInstance = gui
	end

	-- Overlay
	local overlay = Instance.new("Frame")
	overlay.Name = MangoProtection.randomName("Overlay")
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 1 -- starts fully transparent
	overlay.BorderSizePixel = 0
	overlay.ZIndex = 1
	overlay.Parent = parentInstance

	-- DialogContainer
	local dialogContainer = Instance.new("Frame")
	dialogContainer.Name = MangoProtection.randomName("Container")
	dialogContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	dialogContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
	dialogContainer.BackgroundTransparency = 1
	dialogContainer.BorderSizePixel = 0
	dialogContainer.ZIndex = 2
	dialogContainer.Parent = parentInstance

	-- UIScale for dialog animation
	local dialogScale = Instance.new("UIScale")
	dialogScale.Scale = 0.8
	dialogScale.Parent = dialogContainer

	-- Measure text to compute dialog height
	local contentWidth = 270 - 32 -- 16px padding each side
	local titleFont = Enum.Font.GothamBold
	local titleSize = 17
	local messageFont = Enum.Font.Gotham
	local messageSize = 14

	local titleBounds = TextService:GetTextSize(title, titleSize, titleFont, Vector2.new(contentWidth, 1000))
	local dialogContentHeight = 20 + titleBounds.Y -- 20px top padding

	local messageBounds: Vector2? = nil
	if message and message ~= "" then
		messageBounds = TextService:GetTextSize(message, messageSize, messageFont, Vector2.new(contentWidth, 1000))
		dialogContentHeight = dialogContentHeight + 4 + (messageBounds :: Vector2).Y
	end

	dialogContentHeight = dialogContentHeight + 16 -- bottom padding before separator

	-- Separator + buttons height
	local buttonCount = #(buttons :: {Types.MangoDialogButtonConfig})
	local buttonsHeight = 1 + (buttonCount * 44) + math.max(0, buttonCount - 1) -- 1px separator + buttons + inter-button separators
	local totalDialogHeight = dialogContentHeight + buttonsHeight

	dialogContainer.Size = UDim2.new(0, 270, 0, totalDialogHeight)

	-- Glass frame inside dialog
	local glassFrame = MangoGlassFrame.new({
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		CornerRadius = UDim.new(0, 16),
		Theme = theme,
		BackgroundTransparency = dialogBgTransparency,
		ShadowEnabled = true,
		ShadowLayerCount = 4,
		ShadowOffsetY = 4,
		ShadowSpread = 16,
		LightweightMode = true,
		Parent = dialogContainer,
	})

	-- Store target transparency for animation
	local targetGlassTransparency = glassFrame.GlassSurface.BackgroundTransparency

	-- UIPadding on GlassSurface for title/message area
	-- We use a content frame for the text area and separate the buttons
	local contentFrame = Instance.new("Frame")
	contentFrame.Name = "ContentFrame"
	contentFrame.Size = UDim2.new(1, 0, 0, dialogContentHeight)
	contentFrame.Position = UDim2.new(0, 0, 0, 0)
	contentFrame.BackgroundTransparency = 1
	contentFrame.BorderSizePixel = 0
	contentFrame.ZIndex = 10
	contentFrame.Parent = glassFrame.GlassSurface

	local contentPadding = Instance.new("UIPadding")
	contentPadding.PaddingTop = UDim.new(0, 20)
	contentPadding.PaddingLeft = UDim.new(0, 16)
	contentPadding.PaddingRight = UDim.new(0, 16)
	contentPadding.Parent = contentFrame

	local contentLayout = Instance.new("UIListLayout")
	contentLayout.FillDirection = Enum.FillDirection.Vertical
	contentLayout.Padding = UDim.new(0, 4)
	contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
	contentLayout.Parent = contentFrame

	-- TitleLabel
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Text = title
	titleLabel.Font = titleFont
	titleLabel.TextSize = titleSize
	titleLabel.TextColor3 = primaryTextColor
	titleLabel.BackgroundTransparency = 1
	titleLabel.Size = UDim2.new(1, 0, 0, titleBounds.Y)
	titleLabel.TextXAlignment = Enum.TextXAlignment.Center
	titleLabel.TextYAlignment = Enum.TextYAlignment.Center
	titleLabel.TextWrapped = true
	titleLabel.BorderSizePixel = 0
	titleLabel.LayoutOrder = 1
	titleLabel.ZIndex = 10
	titleLabel.Parent = contentFrame

	-- MessageLabel (optional)
	if message and message ~= "" and messageBounds then
		local messageLabel = Instance.new("TextLabel")
		messageLabel.Name = "MessageLabel"
		messageLabel.Text = message
		messageLabel.Font = messageFont
		messageLabel.TextSize = messageSize
		messageLabel.TextColor3 = secondaryTextColor
		messageLabel.BackgroundTransparency = 1
		messageLabel.Size = UDim2.new(1, 0, 0, (messageBounds :: Vector2).Y)
		messageLabel.TextXAlignment = Enum.TextXAlignment.Center
		messageLabel.TextYAlignment = Enum.TextYAlignment.Top
		messageLabel.TextWrapped = true
		messageLabel.BorderSizePixel = 0
		messageLabel.LayoutOrder = 2
		messageLabel.ZIndex = 10
		messageLabel.Parent = contentFrame
	end

	-- Separator between content and buttons
	local separator = Instance.new("Frame")
	separator.Name = "Separator"
	separator.Size = UDim2.new(1, 0, 0, 1)
	separator.Position = UDim2.new(0, 0, 0, dialogContentHeight)
	separator.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
	separator.BackgroundTransparency = 0.7
	separator.BorderSizePixel = 0
	separator.ZIndex = 10
	separator.Parent = glassFrame.GlassSurface

	-- Buttons container
	local buttonsContainer = Instance.new("Frame")
	buttonsContainer.Name = "ButtonsContainer"
	buttonsContainer.Size = UDim2.new(1, 0, 0, buttonsHeight - 1) -- minus the top separator
	buttonsContainer.Position = UDim2.new(0, 0, 0, dialogContentHeight + 1)
	buttonsContainer.BackgroundTransparency = 1
	buttonsContainer.BorderSizePixel = 0
	buttonsContainer.ZIndex = 10
	buttonsContainer.Parent = glassFrame.GlassSurface

	local buttonsLayout = Instance.new("UIListLayout")
	buttonsLayout.FillDirection = Enum.FillDirection.Vertical
	buttonsLayout.Padding = UDim.new(0, 0) -- separators are inline
	buttonsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	buttonsLayout.Parent = buttonsContainer

	-- Forward reference for dismiss
	local dismissFunc: (() -> ())? = nil

	-- Create each button
	for i, buttonConfig in buttons :: {Types.MangoDialogButtonConfig} do
		-- Inter-button separator (not before the first button)
		if i > 1 then
			local btnSep = Instance.new("Frame")
			btnSep.Name = "ButtonSeparator" .. i
			btnSep.Size = UDim2.new(1, 0, 0, 1)
			btnSep.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
			btnSep.BackgroundTransparency = 0.7
			btnSep.BorderSizePixel = 0
			btnSep.ZIndex = 10
			btnSep.LayoutOrder = (i - 1) * 2
			btnSep.Parent = buttonsContainer
		end

		local btnFrame = Instance.new("Frame")
		btnFrame.Name = "Button" .. i
		btnFrame.Size = UDim2.new(1, 0, 0, 44)
		btnFrame.BackgroundTransparency = 1
		btnFrame.BorderSizePixel = 0
		btnFrame.ZIndex = 10
		btnFrame.LayoutOrder = (i - 1) * 2 + 1
		btnFrame.Parent = buttonsContainer

		-- Determine style
		local style = buttonConfig.Style or "default"
		local btnTextColor: Color3
		local btnFont: Enum.Font
		if style == "destructive" then
			btnTextColor = Color3.fromRGB(255, 59, 48)
			btnFont = Enum.Font.Gotham
		elseif style == "cancel" then
			btnTextColor = primaryTextColor
			btnFont = Enum.Font.GothamBold
		else
			btnTextColor = primaryTextColor
			btnFont = Enum.Font.Gotham
		end

		local btnLabel = Instance.new("TextLabel")
		btnLabel.Name = "ButtonLabel"
		btnLabel.Text = buttonConfig.Text
		btnLabel.Font = btnFont
		btnLabel.TextSize = 17
		btnLabel.TextColor3 = btnTextColor
		btnLabel.BackgroundTransparency = 1
		btnLabel.Size = UDim2.new(1, 0, 1, 0)
		btnLabel.TextXAlignment = Enum.TextXAlignment.Center
		btnLabel.TextYAlignment = Enum.TextYAlignment.Center
		btnLabel.BorderSizePixel = 0
		btnLabel.ZIndex = 10
		btnLabel.Parent = btnFrame

		-- HitArea
		local hitArea = Instance.new("TextButton")
		hitArea.Name = "HitArea"
		hitArea.Size = UDim2.new(1, 0, 1, 0)
		hitArea.BackgroundTransparency = 1
		hitArea.Text = ""
		hitArea.BorderSizePixel = 0
		hitArea.ZIndex = 100
		hitArea.AutoButtonColor = false
		hitArea.Parent = btnFrame

		local conn = hitArea.Activated:Connect(function()
			if buttonConfig.OnActivated then
				buttonConfig.OnActivated()
			end
			if dismissFunc then
				dismissFunc()
			end
		end)
		table.insert(connections, conn)
	end

	-- Overlay tap to dismiss
	local overlayHit = Instance.new("TextButton")
	overlayHit.Name = "OverlayHitArea"
	overlayHit.Size = UDim2.new(1, 0, 1, 0)
	overlayHit.BackgroundTransparency = 1
	overlayHit.Text = ""
	overlayHit.BorderSizePixel = 0
	overlayHit.ZIndex = 0
	overlayHit.AutoButtonColor = false
	overlayHit.Parent = overlay

	local overlayConn = overlayHit.Activated:Connect(function()
		if dismissFunc then
			dismissFunc()
		end
	end)
	table.insert(connections, overlayConn)

	-- Dismiss implementation
	local function doDismiss()
		if isDismissing or isDestroyed or not isShowing then
			return
		end
		isDismissing = true

		cancelAllTweens()
		local tweenOut = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

		-- Fade overlay out
		local overlayTween = TweenService:Create(overlay, tweenOut, {
			BackgroundTransparency = 1,
		})
		trackTween(overlayTween)
		overlayTween:Play()

		-- Scale dialog down + fade glass
		local scaleTween = TweenService:Create(dialogScale, tweenOut, { Scale = 0.8 })
		trackTween(scaleTween)
		scaleTween:Play()

		local glassFadeTween = TweenService:Create(glassFrame.GlassSurface, tweenOut, {
			BackgroundTransparency = 1,
		})
		trackTween(glassFadeTween)
		glassFadeTween:Play()

		scaleTween.Completed:Once(function()
			if not isDestroyed then
				if config.OnDismissed then
					config.OnDismissed()
				end
				-- Auto-destroy
				isDestroyed = true
				cancelAllTweens()
				for _, conn in connections do
					conn:Disconnect()
				end
				table.clear(connections)
				glassFrame:Destroy()
				dialogContainer:Destroy()
				overlay:Destroy()
				if screenGui then
					screenGui:Destroy()
				end
			end
		end)
	end

	dismissFunc = doDismiss

	-- Return table
	local self: Types.MangoDialog = {
		Show = function(self: Types.MangoDialog)
			if isShowing or isDestroyed then
				return
			end
			isShowing = true

			-- Start with glass surface fully transparent
			glassFrame.GlassSurface.BackgroundTransparency = 1
			dialogScale.Scale = 0.8

			cancelAllTweens()

			-- Fade overlay in
			local overlayInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			local overlayTween = TweenService:Create(overlay, overlayInfo, {
				BackgroundTransparency = overlayTransparency,
			})
			trackTween(overlayTween)
			overlayTween:Play()

			-- Scale dialog in
			local scaleInfo = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			local scaleTween = TweenService:Create(dialogScale, scaleInfo, { Scale = 1 })
			trackTween(scaleTween)
			scaleTween:Play()

			-- Fade glass surface in
			local fadeInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			local glassFadeTween = TweenService:Create(glassFrame.GlassSurface, fadeInfo, {
				BackgroundTransparency = targetGlassTransparency,
			})
			trackTween(glassFadeTween)
			glassFadeTween:Play()
		end,
		Dismiss = function(self: Types.MangoDialog)
			doDismiss()
		end,
		Destroy = function(self: Types.MangoDialog)
			if isDestroyed then
				return
			end
			isDestroyed = true

			cancelAllTweens()
			for _, conn in connections do
				conn:Disconnect()
			end
			table.clear(connections)
			glassFrame:Destroy()
			dialogContainer:Destroy()
			overlay:Destroy()
			if screenGui then
				screenGui:Destroy()
			end
		end,
	}

	return self
end

return module
