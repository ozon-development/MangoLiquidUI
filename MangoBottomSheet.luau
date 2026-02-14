--!strict

local Types = require(script.Parent.Types)
local Themes = require(script.Parent.Themes)
local MangoGlassFrame = require(script.Parent.MangoGlassFrame)
local MangoProtection = require(script.Parent.MangoProtection)
local resolve = Themes.resolve
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local module = {}

function module.new(config: Types.MangoBottomSheetConfig): Types.MangoBottomSheet
	local theme = config.Theme
	local title = config.Title
	local contentSize = resolve(config.ContentSize, nil, UDim2.new(1, 0, 1, 0)) :: UDim2
	local snapPositions = resolve(config.SnapPositions, nil, {0.4, 0.8}) :: {number}
	local initialSnap = resolve(config.InitialSnap, nil, 1) :: number
	local dismissThreshold = resolve(config.DismissThreshold, nil, 0.15) :: number

	-- Theme values
	local sheetBgTransparency = resolve(nil, theme and theme.BottomSheetBackgroundTransparency, 0.15) :: number
	local handleColor = resolve(nil, theme and theme.BottomSheetHandleColor, Color3.fromRGB(200, 200, 205)) :: Color3
	local primaryTextColor = resolve(nil, theme and theme.PrimaryTextColor, Color3.fromRGB(0, 0, 0)) :: Color3
	local overlayTransparency = resolve(nil, theme and theme.DialogOverlayTransparency, 0.40) :: number

	-- State
	local isShowing = false
	local isDismissing = false
	local isDestroyed = false
	local isDragging = false
	local currentSnapIndex: number = math.clamp(initialSnap, 1, #snapPositions)
	local activeTweens: {Tween} = {}
	local connections: {RBXScriptConnection} = {}
	local dragOffset: number = 0

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
			DisplayOrder = 140,
		})
		screenGui = gui
		parentInstance = gui
	end

	-- Overlay (full screen, black, starts transparent)
	local overlay = Instance.new("Frame")
	overlay.Name = MangoProtection.randomName("Overlay")
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 1
	overlay.BorderSizePixel = 0
	overlay.ZIndex = 1
	overlay.Parent = parentInstance

	-- Overlay hit area for tap-to-dismiss
	local overlayHit = Instance.new("TextButton")
	overlayHit.Name = "OverlayHitArea"
	overlayHit.Size = UDim2.new(1, 0, 1, 0)
	overlayHit.BackgroundTransparency = 1
	overlayHit.Text = ""
	overlayHit.BorderSizePixel = 0
	overlayHit.ZIndex = 0
	overlayHit.AutoButtonColor = false
	overlayHit.Parent = overlay

	-- SheetContainer (anchored bottom, starts below screen)
	local sheetContainer = Instance.new("Frame")
	sheetContainer.Name = MangoProtection.randomName("Container")
	sheetContainer.AnchorPoint = Vector2.new(0.5, 1)
	sheetContainer.Size = UDim2.new(1, 0, 0.9, 0) -- max 90% of screen height
	sheetContainer.Position = UDim2.new(0.5, 0, 1, sheetContainer.AbsoluteSize.Y + 100)
	sheetContainer.BackgroundTransparency = 1
	sheetContainer.BorderSizePixel = 0
	sheetContainer.ClipsDescendants = false
	sheetContainer.ZIndex = 2
	sheetContainer.Parent = parentInstance

	-- Glass frame inside sheet (top corners only)
	local glassFrame = MangoGlassFrame.new({
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		CornerRadius = UDim.new(0, 16),
		BackgroundTransparency = sheetBgTransparency,
		Theme = theme,
		ShadowEnabled = true,
		ShadowLayerCount = 4,
		ShadowOffsetY = -4,
		ShadowSpread = 12,
		LightweightMode = true,
		Parent = sheetContainer,
	})

	-- Drag handle (40x5 pill, centered top)
	local dragHandle = Instance.new("Frame")
	dragHandle.Name = "DragHandle"
	dragHandle.Size = UDim2.new(0, 40, 0, 5)
	dragHandle.Position = UDim2.new(0.5, 0, 0, 8)
	dragHandle.AnchorPoint = Vector2.new(0.5, 0)
	dragHandle.BackgroundColor3 = handleColor
	dragHandle.BackgroundTransparency = 0.3
	dragHandle.BorderSizePixel = 0
	dragHandle.ZIndex = 20
	dragHandle.Parent = glassFrame.GlassSurface

	local handleCorner = Instance.new("UICorner")
	handleCorner.CornerRadius = UDim.new(0, 999)
	handleCorner.Parent = dragHandle

	-- DragHitArea (top 40px of sheet for drag input)
	local dragHitArea = Instance.new("TextButton")
	dragHitArea.Name = "DragHitArea"
	dragHitArea.Size = UDim2.new(1, 0, 0, 40)
	dragHitArea.Position = UDim2.new(0, 0, 0, 0)
	dragHitArea.BackgroundTransparency = 1
	dragHitArea.Text = ""
	dragHitArea.BorderSizePixel = 0
	dragHitArea.ZIndex = 15
	dragHitArea.AutoButtonColor = false
	dragHitArea.Parent = glassFrame.GlassSurface

	-- Title label (optional, below handle)
	local contentStartY = 20 -- below drag handle area
	if title and title ~= "" then
		local titleLabel = Instance.new("TextLabel")
		titleLabel.Name = "TitleLabel"
		titleLabel.Size = UDim2.new(1, -32, 0, 24)
		titleLabel.Position = UDim2.new(0, 16, 0, contentStartY)
		titleLabel.BackgroundTransparency = 1
		titleLabel.BorderSizePixel = 0
		titleLabel.Font = Enum.Font.GothamBold
		titleLabel.TextSize = 17
		titleLabel.TextColor3 = primaryTextColor
		titleLabel.TextXAlignment = Enum.TextXAlignment.Center
		titleLabel.TextYAlignment = Enum.TextYAlignment.Center
		titleLabel.Text = title
		titleLabel.ZIndex = 10
		titleLabel.Parent = glassFrame.GlassSurface
		contentStartY = contentStartY + 32
	end

	-- ContentFrame (user parents their content here)
	local contentFrame = Instance.new("Frame")
	contentFrame.Name = "ContentFrame"
	contentFrame.Size = UDim2.new(contentSize.X.Scale, contentSize.X.Offset, contentSize.Y.Scale, contentSize.Y.Offset - contentStartY)
	contentFrame.Position = UDim2.new(0, 0, 0, contentStartY)
	contentFrame.BackgroundTransparency = 1
	contentFrame.BorderSizePixel = 0
	contentFrame.ClipsDescendants = true
	contentFrame.ZIndex = 10
	contentFrame.Parent = glassFrame.GlassSurface

	-- Helper: compute Y position for a snap fraction
	-- snapFraction is the fraction of viewport height visible from bottom
	-- Position is relative to bottom of screen (AnchorPoint=0.5,1)
	local function getSnapPosition(snapFraction: number): UDim2
		return UDim2.new(0.5, 0, 1 - snapFraction, 0)
	end

	-- Helper: compute overlay transparency based on sheet position
	local function getOverlayTransparencyForFraction(fraction: number): number
		-- Scale overlay from fully transparent (0 visible) to target (max snap visible)
		local maxSnap = 0
		for _, snap in snapPositions do
			if snap > maxSnap then
				maxSnap = snap
			end
		end
		local ratio = math.clamp(fraction / maxSnap, 0, 1)
		return 1 - (1 - overlayTransparency) * ratio
	end

	-- Helper: find nearest snap position
	local function findNearestSnap(currentFraction: number): number
		local nearestIdx = 1
		local nearestDist = math.huge
		for i, snap in snapPositions do
			local dist = math.abs(currentFraction - snap)
			if dist < nearestDist then
				nearestDist = dist
				nearestIdx = i
			end
		end
		return nearestIdx
	end

	-- Helper: get current fraction from sheet position
	local function getCurrentFraction(): number
		return 1 - sheetContainer.Position.Y.Scale
	end

	-- Forward reference for dismiss
	local dismissFunc: (() -> ())? = nil

	-- Drag logic
	local dragInputBeganConn = dragHitArea.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if isDestroyed or isDismissing then return end
			isDragging = true
			cancelAllTweens()
			-- Calculate offset: distance from touch point to sheet top position
			local viewportHeight = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.Y or 1000
			local sheetTopY = sheetContainer.Position.Y.Scale * viewportHeight + sheetContainer.Position.Y.Offset
			dragOffset = input.Position.Y - sheetTopY
		end
	end)
	table.insert(connections, dragInputBeganConn)

	local inputChangedConn = UserInputService.InputChanged:Connect(function(input: InputObject)
		if not isDragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local viewportHeight = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.Y or 1000
			local newTopY = input.Position.Y - dragOffset
			local newScale = math.clamp(newTopY / viewportHeight, 0.05, 1.0)
			sheetContainer.Position = UDim2.new(0.5, 0, newScale, 0)

			-- Update overlay transparency based on visible fraction
			local visibleFraction = 1 - newScale
			overlay.BackgroundTransparency = getOverlayTransparencyForFraction(visibleFraction)
		end
	end)
	table.insert(connections, inputChangedConn)

	local inputEndedConn = UserInputService.InputEnded:Connect(function(input: InputObject)
		if not isDragging then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			isDragging = false

			local currentFraction = getCurrentFraction()

			-- Check dismiss threshold
			if currentFraction < dismissThreshold then
				if dismissFunc then
					dismissFunc()
				end
				return
			end

			-- Snap to nearest position
			local snapIdx = findNearestSnap(currentFraction)
			currentSnapIndex = snapIdx
			local targetFraction = snapPositions[snapIdx]

			cancelAllTweens()
			local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			local snapTween = TweenService:Create(sheetContainer, tweenInfo, {
				Position = getSnapPosition(targetFraction),
			})
			trackTween(snapTween)
			snapTween:Play()

			local overlayTween = TweenService:Create(overlay, tweenInfo, {
				BackgroundTransparency = getOverlayTransparencyForFraction(targetFraction),
			})
			trackTween(overlayTween)
			overlayTween:Play()

			if config.OnSnapChanged then
				config.OnSnapChanged(snapIdx)
			end
		end
	end)
	table.insert(connections, inputEndedConn)

	-- Overlay tap to dismiss
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
		isDragging = false

		cancelAllTweens()
		local tweenOut = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

		-- Fade overlay out
		local overlayTween = TweenService:Create(overlay, tweenOut, {
			BackgroundTransparency = 1,
		})
		trackTween(overlayTween)
		overlayTween:Play()

		-- Slide sheet below screen
		local slideTween = TweenService:Create(sheetContainer, tweenOut, {
			Position = UDim2.new(0.5, 0, 1, 100),
		})
		trackTween(slideTween)
		slideTween:Play()

		slideTween.Completed:Once(function()
			if not isDestroyed then
				isShowing = false
				isDismissing = false
				if config.OnDismissed then
					config.OnDismissed()
				end
			end
		end)
	end

	dismissFunc = doDismiss

	-- Return table
	local self: Types.MangoBottomSheet = {
		Container = sheetContainer,
		ContentFrame = contentFrame,
		Show = function(self: Types.MangoBottomSheet)
			if isShowing or isDestroyed then
				return
			end
			isShowing = true
			isDismissing = false

			-- Start offscreen
			sheetContainer.Position = UDim2.new(0.5, 0, 1, 100)
			overlay.BackgroundTransparency = 1

			cancelAllTweens()

			-- Fade overlay in
			local targetFraction = snapPositions[currentSnapIndex]
			local overlayInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			local overlayTween = TweenService:Create(overlay, overlayInfo, {
				BackgroundTransparency = getOverlayTransparencyForFraction(targetFraction),
			})
			trackTween(overlayTween)
			overlayTween:Play()

			-- Slide sheet up to snap position
			local slideInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			local slideTween = TweenService:Create(sheetContainer, slideInfo, {
				Position = getSnapPosition(targetFraction),
			})
			trackTween(slideTween)
			slideTween:Play()
		end,
		Dismiss = function(self: Types.MangoBottomSheet)
			doDismiss()
		end,
		SnapTo = function(self: Types.MangoBottomSheet, snapIndex: number)
			if isDestroyed or isDismissing or not isShowing then return end
			local clampedIndex = math.clamp(snapIndex, 1, #snapPositions)
			currentSnapIndex = clampedIndex
			local targetFraction = snapPositions[clampedIndex]

			cancelAllTweens()
			local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			local snapTween = TweenService:Create(sheetContainer, tweenInfo, {
				Position = getSnapPosition(targetFraction),
			})
			trackTween(snapTween)
			snapTween:Play()

			local overlayTween = TweenService:Create(overlay, tweenInfo, {
				BackgroundTransparency = getOverlayTransparencyForFraction(targetFraction),
			})
			trackTween(overlayTween)
			overlayTween:Play()

			if config.OnSnapChanged then
				config.OnSnapChanged(clampedIndex)
			end
		end,
		Destroy = function(self: Types.MangoBottomSheet)
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
