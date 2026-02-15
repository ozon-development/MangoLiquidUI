--!strict

local Types = require(script.Parent.Types)
local Themes = require(script.Parent.Themes)
local MangoGlassFrame = require(script.Parent.MangoGlassFrame)
local MangoProtection = require(script.Parent.MangoProtection)
local resolve = Themes.resolve
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")

local module = {}

function module.new(config: Types.MangoActionSheetConfig): Types.MangoActionSheet
	local theme = config.Theme
	local title = config.Title
	local message = config.Message
	local actions = resolve(config.Actions, nil, {{Text = "OK"}}) :: {Types.MangoActionSheetActionConfig}
	local cancelText = resolve(config.CancelText, nil, "Cancel") :: string

	-- Theme-driven values
	local overlayTransparency = resolve(nil, theme and theme.DialogOverlayTransparency, 0.40) :: number
	local primaryTextColor = resolve(nil, theme and theme.PrimaryTextColor, Color3.fromRGB(0, 0, 0)) :: Color3
	local secondaryTextColor = resolve(nil, theme and theme.SecondaryTextColor, Color3.fromRGB(60, 60, 70)) :: Color3
	local cancelButtonColor = resolve(nil, theme and theme.TabBarSelectedColor, primaryTextColor) :: Color3

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

	-- SheetContainer (anchored bottom center)
	local sheetContainer = Instance.new("Frame")
	sheetContainer.Name = MangoProtection.randomName("Container")
	sheetContainer.AnchorPoint = Vector2.new(0.5, 1)
	sheetContainer.Position = UDim2.new(0.5, 0, 1, 100) -- starts offscreen below
	sheetContainer.BackgroundTransparency = 1
	sheetContainer.BorderSizePixel = 0
	sheetContainer.ZIndex = 2
	sheetContainer.Parent = parentInstance

	-- Compute actions group height
	local hasHeader = (title and title ~= "") or (message and message ~= "")
	local headerHeight = 0
	local titleFont = Enum.Font.Gotham
	local titleSize = 13
	local messageFont = Enum.Font.Gotham
	local messageSize = 13
	-- Use a reasonable content width: min(400, estimate) - padding
	local sheetWidth = 400 -- will be constrained by UISizeConstraint
	local contentWidth = sheetWidth - 32 -- 16px padding each side

	local titleBounds: Vector2? = nil
	local messageBounds: Vector2? = nil

	if title and title ~= "" then
		titleBounds = TextService:GetTextSize(title, titleSize, titleFont, Vector2.new(contentWidth, 1000))
		headerHeight = headerHeight + 16 + (titleBounds :: Vector2).Y -- 16px top padding
	end

	if message and message ~= "" then
		messageBounds = TextService:GetTextSize(message, messageSize, messageFont, Vector2.new(contentWidth, 1000))
		local topGap = if headerHeight > 0 then 4 else 16
		headerHeight = headerHeight + topGap + (messageBounds :: Vector2).Y
	end

	if hasHeader then
		headerHeight = headerHeight + 12 -- bottom padding
		headerHeight = headerHeight + 1 -- separator
	end

	local actionCount = #actions
	local actionsAreaHeight = (actionCount * 56) + math.max(0, actionCount - 1) -- 56px per action + 1px separators
	local actionsGroupHeight = headerHeight + actionsAreaHeight

	-- Cancel group height
	local cancelGroupHeight = 56

	-- Total sheet height
	local totalSheetHeight = actionsGroupHeight + 8 + cancelGroupHeight

	-- Width: min(400, screen width - 16) — we use a UISizeConstraint to handle screen width
	sheetContainer.Size = UDim2.new(1, -16, 0, totalSheetHeight)

	local sizeConstraint = Instance.new("UISizeConstraint")
	sizeConstraint.MaxSize = Vector2.new(400, totalSheetHeight)
	sizeConstraint.Parent = sheetContainer

	-- Vertical layout for sheet container
	local sheetLayout = Instance.new("UIListLayout")
	sheetLayout.FillDirection = Enum.FillDirection.Vertical
	sheetLayout.Padding = UDim.new(0, 8)
	sheetLayout.SortOrder = Enum.SortOrder.LayoutOrder
	sheetLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	sheetLayout.Parent = sheetContainer

	-- Actions Group Glass Frame
	local actionsGroupContainer = Instance.new("Frame")
	actionsGroupContainer.Name = "ActionsGroupContainer"
	actionsGroupContainer.Size = UDim2.new(1, 0, 0, actionsGroupHeight)
	actionsGroupContainer.BackgroundTransparency = 1
	actionsGroupContainer.BorderSizePixel = 0
	actionsGroupContainer.LayoutOrder = 1
	actionsGroupContainer.Parent = sheetContainer

	local actionsGlass = MangoGlassFrame.new({
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		CornerRadius = UDim.new(0, 14),
		Theme = theme,
		ShadowEnabled = true,
		ShadowLayerCount = 3,
		ShadowOffsetY = 2,
		ShadowSpread = 8,
		LightweightMode = true,
		Parent = actionsGroupContainer,
	})

	-- Forward reference for dismiss
	local dismissFunc: (() -> ())? = nil

	-- Build header inside actions glass
	local currentY = 0

	if hasHeader then
		local headerFrame = Instance.new("Frame")
		headerFrame.Name = "HeaderFrame"
		headerFrame.Size = UDim2.new(1, 0, 0, headerHeight - 1) -- minus separator
		headerFrame.Position = UDim2.new(0, 0, 0, 0)
		headerFrame.BackgroundTransparency = 1
		headerFrame.BorderSizePixel = 0
		headerFrame.ZIndex = 10
		headerFrame.Parent = actionsGlass.GlassSurface

		local headerPadding = Instance.new("UIPadding")
		headerPadding.PaddingTop = UDim.new(0, 16)
		headerPadding.PaddingLeft = UDim.new(0, 16)
		headerPadding.PaddingRight = UDim.new(0, 16)
		headerPadding.Parent = headerFrame

		local headerLayout = Instance.new("UIListLayout")
		headerLayout.FillDirection = Enum.FillDirection.Vertical
		headerLayout.Padding = UDim.new(0, 4)
		headerLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		headerLayout.SortOrder = Enum.SortOrder.LayoutOrder
		headerLayout.Parent = headerFrame

		if title and title ~= "" and titleBounds then
			local titleLabel = Instance.new("TextLabel")
			titleLabel.Name = "TitleLabel"
			titleLabel.Text = title
			titleLabel.Font = titleFont
			titleLabel.TextSize = titleSize
			titleLabel.TextColor3 = secondaryTextColor
			titleLabel.BackgroundTransparency = 1
			titleLabel.Size = UDim2.new(1, 0, 0, (titleBounds :: Vector2).Y)
			titleLabel.TextXAlignment = Enum.TextXAlignment.Center
			titleLabel.TextYAlignment = Enum.TextYAlignment.Center
			titleLabel.TextWrapped = true
			titleLabel.BorderSizePixel = 0
			titleLabel.LayoutOrder = 1
			titleLabel.ZIndex = 10
			titleLabel.Parent = headerFrame
		end

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
			messageLabel.Parent = headerFrame
		end

		-- Separator after header
		local headerSep = Instance.new("Frame")
		headerSep.Name = "HeaderSeparator"
		headerSep.Size = UDim2.new(1, 0, 0, 1)
		headerSep.Position = UDim2.new(0, 0, 0, headerHeight - 1)
		headerSep.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
		headerSep.BackgroundTransparency = 0.7
		headerSep.BorderSizePixel = 0
		headerSep.ZIndex = 10
		headerSep.Parent = actionsGlass.GlassSurface

		currentY = headerHeight
	end

	-- Action items
	for i, actionConfig in actions do
		-- Inter-action separator (not before first if no header, or always between actions)
		if i > 1 then
			local actionSep = Instance.new("Frame")
			actionSep.Name = "ActionSeparator" .. i
			actionSep.Size = UDim2.new(1, 0, 0, 1)
			actionSep.Position = UDim2.new(0, 0, 0, currentY)
			actionSep.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
			actionSep.BackgroundTransparency = 0.7
			actionSep.BorderSizePixel = 0
			actionSep.ZIndex = 10
			actionSep.Parent = actionsGlass.GlassSurface
			currentY = currentY + 1
		end

		local actionFrame = Instance.new("Frame")
		actionFrame.Name = "Action" .. i
		actionFrame.Size = UDim2.new(1, 0, 0, 56)
		actionFrame.Position = UDim2.new(0, 0, 0, currentY)
		actionFrame.BackgroundTransparency = 1
		actionFrame.BorderSizePixel = 0
		actionFrame.ZIndex = 10
		actionFrame.Parent = actionsGlass.GlassSurface

		local style = actionConfig.Style or "default"
		local actionTextColor: Color3
		if style == "destructive" then
			actionTextColor = Color3.fromRGB(255, 59, 48)
		else
			actionTextColor = primaryTextColor
		end

		local actionLabel = Instance.new("TextLabel")
		actionLabel.Name = "ActionLabel"
		actionLabel.Text = actionConfig.Text
		actionLabel.Font = Enum.Font.Gotham
		actionLabel.TextSize = 20
		actionLabel.TextColor3 = actionTextColor
		actionLabel.BackgroundTransparency = 1
		actionLabel.Size = UDim2.new(1, 0, 1, 0)
		actionLabel.TextXAlignment = Enum.TextXAlignment.Center
		actionLabel.TextYAlignment = Enum.TextYAlignment.Center
		actionLabel.BorderSizePixel = 0
		actionLabel.ZIndex = 10
		actionLabel.Parent = actionFrame

		local hitArea = Instance.new("TextButton")
		hitArea.Name = "HitArea"
		hitArea.Size = UDim2.new(1, 0, 1, 0)
		hitArea.BackgroundTransparency = 1
		hitArea.Text = ""
		hitArea.BorderSizePixel = 0
		hitArea.ZIndex = 100
		hitArea.AutoButtonColor = false
		hitArea.Parent = actionFrame

		local conn = hitArea.Activated:Connect(function()
			if actionConfig.OnActivated then
				actionConfig.OnActivated()
			end
			if dismissFunc then
				dismissFunc()
			end
		end)
		table.insert(connections, conn)

		currentY = currentY + 56
	end

	-- Cancel Group
	local cancelGroupContainer = Instance.new("Frame")
	cancelGroupContainer.Name = "CancelGroupContainer"
	cancelGroupContainer.Size = UDim2.new(1, 0, 0, cancelGroupHeight)
	cancelGroupContainer.BackgroundTransparency = 1
	cancelGroupContainer.BorderSizePixel = 0
	cancelGroupContainer.LayoutOrder = 2
	cancelGroupContainer.Parent = sheetContainer

	local cancelGlass = MangoGlassFrame.new({
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		CornerRadius = UDim.new(0, 14),
		Theme = theme,
		ShadowEnabled = true,
		ShadowLayerCount = 2,
		ShadowOffsetY = 1,
		ShadowSpread = 4,
		LightweightMode = true,
		Parent = cancelGroupContainer,
	})

	local cancelLabel = Instance.new("TextLabel")
	cancelLabel.Name = "CancelLabel"
	cancelLabel.Text = cancelText
	cancelLabel.Font = Enum.Font.GothamBold
	cancelLabel.TextSize = 20
	cancelLabel.TextColor3 = cancelButtonColor
	cancelLabel.BackgroundTransparency = 1
	cancelLabel.Size = UDim2.new(1, 0, 1, 0)
	cancelLabel.TextXAlignment = Enum.TextXAlignment.Center
	cancelLabel.TextYAlignment = Enum.TextYAlignment.Center
	cancelLabel.BorderSizePixel = 0
	cancelLabel.ZIndex = 10
	cancelLabel.Parent = cancelGlass.GlassSurface

	local cancelHitArea = Instance.new("TextButton")
	cancelHitArea.Name = "HitArea"
	cancelHitArea.Size = UDim2.new(1, 0, 1, 0)
	cancelHitArea.BackgroundTransparency = 1
	cancelHitArea.Text = ""
	cancelHitArea.BorderSizePixel = 0
	cancelHitArea.ZIndex = 100
	cancelHitArea.AutoButtonColor = false
	cancelHitArea.Parent = cancelGlass.GlassSurface

	local cancelConn = cancelHitArea.Activated:Connect(function()
		if dismissFunc then
			dismissFunc()
		end
	end)
	table.insert(connections, cancelConn)

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
		local tweenOut = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

		-- Fade overlay out
		local overlayTween = TweenService:Create(overlay, tweenOut, {
			BackgroundTransparency = 1,
		})
		trackTween(overlayTween)
		overlayTween:Play()

		-- Slide sheet down
		local slideTween = TweenService:Create(sheetContainer, tweenOut, {
			Position = UDim2.new(0.5, 0, 1, 100),
		})
		trackTween(slideTween)
		slideTween:Play()

		slideTween.Completed:Once(function()
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
				actionsGlass:Destroy()
				cancelGlass:Destroy()
				sheetContainer:Destroy()
				overlay:Destroy()
				if screenGui then
					screenGui:Destroy()
				end
			end
		end)
	end

	dismissFunc = doDismiss

	-- Return table
	local self: Types.MangoActionSheet = {
		Show = function(self: Types.MangoActionSheet)
			if isShowing or isDestroyed then
				return
			end
			isShowing = true

			-- Start offscreen
			sheetContainer.Position = UDim2.new(0.5, 0, 1, 100)

			cancelAllTweens()

			-- Fade overlay in
			local overlayInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			local overlayTween = TweenService:Create(overlay, overlayInfo, {
				BackgroundTransparency = overlayTransparency,
			})
			trackTween(overlayTween)
			overlayTween:Play()

			-- Slide sheet up
			local slideInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			local slideTween = TweenService:Create(sheetContainer, slideInfo, {
				Position = UDim2.new(0.5, 0, 1, -8),
			})
			trackTween(slideTween)
			slideTween:Play()
		end,
		Dismiss = function(self: Types.MangoActionSheet)
			doDismiss()
		end,
		Destroy = function(self: Types.MangoActionSheet)
			if isDestroyed then
				return
			end
			isDestroyed = true

			cancelAllTweens()
			for _, conn in connections do
				conn:Disconnect()
			end
			table.clear(connections)
			actionsGlass:Destroy()
			cancelGlass:Destroy()
			sheetContainer:Destroy()
			overlay:Destroy()
			if screenGui then
				screenGui:Destroy()
			end
		end,
	}

	return self
end

return module
