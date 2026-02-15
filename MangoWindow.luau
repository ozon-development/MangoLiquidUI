--!strict

local Types = require(script.Parent.Types)
local Themes = require(script.Parent.Themes)
local MangoGlassFrame = require(script.Parent.MangoGlassFrame)
local MangoToggle = require(script.Parent.MangoToggle)
local MangoSlider = require(script.Parent.MangoSlider)
local MangoButton = require(script.Parent.MangoButton)
local MangoCheckbox = require(script.Parent.MangoCheckbox)
local MangoProgressBar = require(script.Parent.MangoProgressBar)
local MangoDropdown = require(script.Parent.MangoDropdown)
local MangoTextField = require(script.Parent.MangoTextField)
local MangoStepper = require(script.Parent.MangoStepper)
local MangoSegmentedControl = require(script.Parent.MangoSegmentedControl)
local MangoNotificationStack = require(script.Parent.MangoNotificationStack)
local MangoDialog = require(script.Parent.MangoDialog)
local MangoColorPicker = require(script.Parent.MangoColorPicker)
local MangoKeybind = require(script.Parent.MangoKeybind)
local MangoSaveManager = require(script.Parent.MangoSaveManager)
local MangoIntro = require(script.Parent.MangoIntro)
local MangoCarousel = require(script.Parent.MangoCarousel)
local MangoProtection = require(script.Parent.MangoProtection)
local resolve = Themes.resolve

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local module = {}

-- Helper: create a MangoWindowElement wrapper
local function createWindowElement(config: {
	getValue: () -> any,
	setValue: (any) -> (),
	rowFrame: Frame,
	destroyInner: () -> (),
}): Types.MangoWindowElement
	local isLocked = false
	local lockOverlay: Frame? = nil
	local currentValue = config.getValue()

	local self: Types.MangoWindowElement = {
		CurrentValue = currentValue,
		Set = function(self: Types.MangoWindowElement, value: any)
			config.setValue(value)
			self.CurrentValue = config.getValue()
		end,
		Visible = function(self: Types.MangoWindowElement, visible: boolean)
			config.rowFrame.Visible = visible
		end,
		Lock = function(self: Types.MangoWindowElement, reason: string?)
			if isLocked then return end
			isLocked = true
			local overlay = Instance.new("Frame")
			overlay.Name = "LockOverlay"
			overlay.Size = UDim2.new(1, 0, 1, 0)
			overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			overlay.BackgroundTransparency = 0.85
			overlay.BorderSizePixel = 0
			overlay.ZIndex = 200
			overlay.Parent = config.rowFrame
			lockOverlay = overlay

			if reason then
				local label = Instance.new("TextLabel")
				label.Size = UDim2.new(1, 0, 1, 0)
				label.BackgroundTransparency = 1
				label.Font = Enum.Font.GothamMedium
				label.TextSize = 12
				label.Text = reason
				label.TextColor3 = Color3.fromRGB(200, 200, 200)
				label.ZIndex = 201
				label.Parent = overlay
			end
		end,
		Unlock = function(self: Types.MangoWindowElement)
			if not isLocked then return end
			isLocked = false
			if lockOverlay then
				lockOverlay:Destroy()
				lockOverlay = nil
			end
		end,
		Destroy = function(self: Types.MangoWindowElement)
			config.destroyInner()
			config.rowFrame:Destroy()
		end,
	}
	return self
end

function module.new(config: Types.MangoWindowConfig): Types.MangoWindow
	local theme = config.Theme or Themes.Light
	local windowName = config.Name or "MangoUI"
	local windowSize = resolve(config.Size, nil, UDim2.new(0, 500, 0, 600)) :: UDim2
	local windowPos = resolve(config.Position, nil, UDim2.new(0.5, 0, 0.5, 0)) :: UDim2
	local toggleKeyName = config.ToggleKey
	local showButtonText = config.ShowButton or windowName
	local configSaving = config.ConfigurationSaving
	local loadingEnabled = resolve(config.LoadingEnabled, nil, true) :: boolean

	-- Theme values
	local primaryText = resolve(nil, theme.PrimaryTextColor, Color3.fromRGB(0, 0, 0)) :: Color3
	local secondaryText = resolve(nil, theme.SecondaryTextColor, Color3.fromRGB(60, 60, 70)) :: Color3
	local bgColor = resolve(nil, theme.BackgroundColor3, Color3.fromRGB(255, 255, 255)) :: Color3
	local accentColor = resolve(nil, theme.AccentColor, Color3.fromRGB(0, 122, 255)) :: Color3
	local windowBgTransp = resolve(nil, theme.WindowBackgroundTransparency, 0.12) :: number

	-- State
	local isVisible = true
	local isDestroyed = false
	local isDragging = false
	local activeTweens: {Tween} = {}
	local connections: {RBXScriptConnection} = {}
	local tabData: {{name: string, icon: string?, frame: ScrollingFrame, elements: {Types.MangoWindowElement}}} = {}
	local currentTabIndex = 1
	local flags: {[string]: any} = {}
	local flagElements: {[string]: Types.MangoWindowElement} = {}
	local flagDependents: {[string]: {Types.MangoWindowElement}} = {}
	local saveDebounceThread: thread? = nil
	local saveManager: Types.MangoSaveManager? = nil
	local innerDestroyables: {any} = {}
	local pendingDelays: {thread} = {}
	local carouselDock: Types.MangoCarousel? = nil
	local DOCK_GAP = 12

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

	-- Play intro if enabled
	if loadingEnabled then
		MangoIntro.play({
			Theme = theme,
			Title = config.LoadingTitle,
			Subtitle = config.LoadingSubtitle,
		})
	end

	-- Setup save manager
	if configSaving and configSaving.Enabled then
		local folderName = configSaving.FolderName or windowName
		local fileName = configSaving.FileName or "config"
		saveManager = MangoSaveManager.new({
			FolderName = folderName,
			FileName = fileName,
		})
	end

	-- Create ScreenGui
	local screenGui = MangoProtection.createScreenGui({
		DisplayOrder = 100,
	})

	-- Window container (animation target)
	local windowContainer = Instance.new("Frame")
	windowContainer.Name = MangoProtection.randomName("Container")
	windowContainer.Size = windowSize
	windowContainer.Position = windowPos
	windowContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	windowContainer.BackgroundTransparency = 1
	windowContainer.BorderSizePixel = 0
	windowContainer.Parent = screenGui

	local windowUIScale = Instance.new("UIScale")
	windowUIScale.Scale = 1
	windowUIScale.Parent = windowContainer

	-- Glass frame
	local glassFrame = MangoGlassFrame.new({
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		CornerRadius = UDim.new(0, 16),
		BackgroundTransparency = windowBgTransp,
		Theme = theme,
		ShadowEnabled = true,
		ShadowLayerCount = 4,
		ShadowSpread = 16,
		ShadowOffsetY = 4,
		Parent = windowContainer,
	})
	table.insert(innerDestroyables, glassFrame)

	-- Window content frame
	local windowContent = Instance.new("Frame")
	windowContent.Name = "WindowContent"
	windowContent.Size = UDim2.new(1, 0, 1, 0)
	windowContent.BackgroundTransparency = 1
	windowContent.BorderSizePixel = 0
	windowContent.ZIndex = 10
	windowContent.Parent = glassFrame.GlassSurface

	local contentPadding = Instance.new("UIPadding")
	contentPadding.PaddingTop = UDim.new(0, 14)
	contentPadding.PaddingBottom = UDim.new(0, 14)
	contentPadding.PaddingLeft = UDim.new(0, 14)
	contentPadding.PaddingRight = UDim.new(0, 14)
	contentPadding.Parent = windowContent

	-- Title bar (32px)
	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 32)
	titleBar.Position = UDim2.new(0, 0, 0, 0)
	titleBar.BackgroundTransparency = 1
	titleBar.BorderSizePixel = 0
	titleBar.ZIndex = 10
	titleBar.Parent = windowContent

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(1, -40, 1, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 17
	titleLabel.TextColor3 = primaryText
	titleLabel.Text = windowName
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.TextYAlignment = Enum.TextYAlignment.Center
	titleLabel.BorderSizePixel = 0
	titleLabel.ZIndex = 10
	titleLabel.Parent = titleBar

	-- Close button (24x24 glass circle)
	local closeFrame = Instance.new("Frame")
	closeFrame.Name = "CloseButton"
	closeFrame.Size = UDim2.new(0, 24, 0, 24)
	closeFrame.Position = UDim2.new(1, -8, 0.5, 0)
	closeFrame.AnchorPoint = Vector2.new(1, 0.5)
	closeFrame.BackgroundColor3 = bgColor
	closeFrame.BackgroundTransparency = 0.75
	closeFrame.BorderSizePixel = 0
	closeFrame.ZIndex = 15
	closeFrame.Parent = titleBar

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 999)
	closeCorner.Parent = closeFrame

	local closeStroke = Instance.new("UIStroke")
	closeStroke.Thickness = 0.75
	closeStroke.Color = Color3.fromRGB(200, 200, 205)
	closeStroke.Transparency = 0.5
	closeStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	closeStroke.Parent = closeFrame

	local closeLabel = Instance.new("TextLabel")
	closeLabel.Size = UDim2.new(1, 0, 1, 0)
	closeLabel.BackgroundTransparency = 1
	closeLabel.Font = Enum.Font.GothamBold
	closeLabel.TextSize = 13
	closeLabel.Text = "X"
	closeLabel.TextColor3 = secondaryText
	closeLabel.ZIndex = 15
	closeLabel.Parent = closeFrame

	local closeHitArea = Instance.new("TextButton")
	closeHitArea.Name = "CloseHitArea"
	closeHitArea.Size = UDim2.new(1, 8, 1, 8)
	closeHitArea.AnchorPoint = Vector2.new(0.5, 0.5)
	closeHitArea.Position = UDim2.new(0.5, 0, 0.5, 0)
	closeHitArea.BackgroundTransparency = 1
	closeHitArea.Text = ""
	closeHitArea.BorderSizePixel = 0
	closeHitArea.ZIndex = 100
	closeHitArea.AutoButtonColor = false
	closeHitArea.Parent = closeFrame

	-- Drag hit area (title bar area)
	local dragHitArea = Instance.new("TextButton")
	dragHitArea.Name = "DragHitArea"
	dragHitArea.Size = UDim2.new(1, -32, 1, 0)
	dragHitArea.BackgroundTransparency = 1
	dragHitArea.Text = ""
	dragHitArea.BorderSizePixel = 0
	dragHitArea.ZIndex = 5
	dragHitArea.AutoButtonColor = false
	dragHitArea.Parent = titleBar

	-- Tab selector area (placeholder, filled when tabs > 1)
	local tabSelectorFrame = Instance.new("Frame")
	tabSelectorFrame.Name = "TabSelectorFrame"
	tabSelectorFrame.Size = UDim2.new(1, 0, 0, 0)
	tabSelectorFrame.Position = UDim2.new(0, 0, 0, 36)
	tabSelectorFrame.BackgroundTransparency = 1
	tabSelectorFrame.BorderSizePixel = 0
	tabSelectorFrame.ZIndex = 10
	tabSelectorFrame.Parent = windowContent

	local segmentedControl: Types.MangoSegmentedControl? = nil

	-- Content area (below title bar + tab selector)
	local contentArea = Instance.new("Frame")
	contentArea.Name = "ContentArea"
	contentArea.Size = UDim2.new(1, 0, 1, -36)
	contentArea.Position = UDim2.new(0, 0, 0, 36)
	contentArea.BackgroundTransparency = 1
	contentArea.BorderSizePixel = 0
	contentArea.ZIndex = 10
	contentArea.ClipsDescendants = true
	contentArea.Parent = windowContent

	local contentPadding = Instance.new("UIPadding")
	contentPadding.PaddingTop = UDim.new(0, 8)
	contentPadding.PaddingBottom = UDim.new(0, 8)
	contentPadding.Parent = contentArea

	-- Reopener pill (hidden initially)
	local reopenerGlass = MangoGlassFrame.new({
		Size = UDim2.new(0, 140, 0, 30),
		Position = UDim2.new(0.5, 0, 0, -40),
		AnchorPoint = Vector2.new(0.5, 0),
		CornerRadius = UDim.new(0, 999),
		BackgroundTransparency = 0.70,
		Theme = theme,
		ShadowEnabled = true,
		ShadowLayerCount = 1,
		ShadowSpread = 4,
		ShadowOffsetY = 1,
		LightweightMode = true,
		Parent = screenGui,
	})
	table.insert(innerDestroyables, reopenerGlass)

	local reopenerLabel = Instance.new("TextLabel")
	reopenerLabel.Name = "ReopenerLabel"
	reopenerLabel.Size = UDim2.new(1, 0, 1, 0)
	reopenerLabel.BackgroundTransparency = 1
	reopenerLabel.Font = Enum.Font.GothamMedium
	reopenerLabel.TextSize = 13
	reopenerLabel.TextColor3 = primaryText
	reopenerLabel.Text = showButtonText .. " v"
	reopenerLabel.ZIndex = 10
	reopenerLabel.Parent = reopenerGlass.GlassSurface

	local reopenerHitArea = Instance.new("TextButton")
	reopenerHitArea.Name = "HitArea"
	reopenerHitArea.Size = UDim2.new(1, 0, 1, 0)
	reopenerHitArea.BackgroundTransparency = 1
	reopenerHitArea.Text = ""
	reopenerHitArea.BorderSizePixel = 0
	reopenerHitArea.ZIndex = 100
	reopenerHitArea.AutoButtonColor = false
	reopenerHitArea.Parent = reopenerGlass.GlassSurface

	-- Notification stack
	local notifStack = MangoNotificationStack.new({
		MaxVisible = 3,
		Theme = theme,
		Parent = screenGui,
	})
	table.insert(innerDestroyables, notifStack)

	-- === Carousel dock position ===
	local function updateDockPosition()
		if not carouselDock then return end
		local absPos = windowContainer.AbsolutePosition
		local absSize = windowContainer.AbsoluteSize
		carouselDock.Container.Position = UDim2.new(0, absPos.X - DOCK_GAP, 0, absPos.Y + absSize.Y)
	end

	-- === Drag system (delta-based: avoids coordinate system mismatches from GUI inset) ===
	local dragStartPos: UDim2 = UDim2.new()
	local dragStartMouse = Vector2.new(0, 0)

	local dragStartConn = dragHitArea.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			isDragging = true
			dragStartPos = windowContainer.Position
			dragStartMouse = Vector2.new(input.Position.X, input.Position.Y)
		end
	end)
	table.insert(connections, dragStartConn)

	local dragMoveConn = UserInputService.InputChanged:Connect(function(input: InputObject)
		if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = Vector2.new(input.Position.X - dragStartMouse.X, input.Position.Y - dragStartMouse.Y)
			windowContainer.Position = UDim2.new(
				dragStartPos.X.Scale, dragStartPos.X.Offset + delta.X,
				dragStartPos.Y.Scale, dragStartPos.Y.Offset + delta.Y
			)
			updateDockPosition()
		end
	end)
	table.insert(connections, dragMoveConn)

	local dragEndConn = UserInputService.InputEnded:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			isDragging = false
		end
	end)
	table.insert(connections, dragEndConn)

	-- === Close button hover ===
	local closeHoverTween: Tween? = nil
	local closeHoverConn = closeHitArea.MouseEnter:Connect(function()
		if closeHoverTween then closeHoverTween:Cancel() end
		closeHoverTween = TweenService:Create(closeFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 0.50,
		})
		trackTween(closeHoverTween)
		closeHoverTween:Play()
	end)
	table.insert(connections, closeHoverConn)

	local closeLeaveConn = closeHitArea.MouseLeave:Connect(function()
		if closeHoverTween then closeHoverTween:Cancel() end
		closeHoverTween = TweenService:Create(closeFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 0.75,
		})
		trackTween(closeHoverTween)
		closeHoverTween:Play()
	end)
	table.insert(connections, closeLeaveConn)

	-- === Flag dependency system ===
	local function evaluateDependencies(changedFlag: string)
		local dependents = flagDependents[changedFlag]
		if not dependents then return end
		local flagValue = flags[changedFlag]
		local isTruthy = flagValue and flagValue ~= false and flagValue ~= 0 and flagValue ~= ""
		for _, element in dependents do
			element:Visible(isTruthy)
		end
	end

	-- === Auto-save (debounced) ===
	local function triggerAutoSave()
		if not saveManager or not configSaving or not configSaving.Enabled then return end
		if saveDebounceThread then
			task.cancel(saveDebounceThread)
		end
		saveDebounceThread = task.delay(1, function()
			if isDestroyed then return end
			saveManager:Save(flags)
			saveDebounceThread = nil
		end)
	end

	local function registerFlag(flagName: string, element: Types.MangoWindowElement, initialValue: any)
		flags[flagName] = initialValue
		flagElements[flagName] = element
		element.CurrentValue = initialValue
	end

	local function updateFlag(flagName: string, value: any)
		flags[flagName] = value
		local el = flagElements[flagName]
		if el then
			el.CurrentValue = value
		end
		evaluateDependencies(flagName)
		triggerAutoSave()
	end

	local function registerDependency(element: Types.MangoWindowElement, visibleFlag: string)
		if not flagDependents[visibleFlag] then
			flagDependents[visibleFlag] = {}
		end
		table.insert(flagDependents[visibleFlag], element)
		-- Evaluate immediately
		local flagValue = flags[visibleFlag]
		local isTruthy = flagValue and flagValue ~= false and flagValue ~= 0 and flagValue ~= ""
		element:Visible(isTruthy)
	end

	-- === Tab switching ===
	local function switchToTab(index: number)
		if index == currentTabIndex then return end
		-- Hide current
		if tabData[currentTabIndex] then
			tabData[currentTabIndex].frame.Visible = false
		end
		currentTabIndex = index
		-- Sync carousel dock
		if carouselDock and carouselDock:GetIndex() ~= index then
			carouselDock:SetIndex(index)
		end
		-- Show new with spring animation
		local newTab = tabData[index]
		if newTab then
			local tabScale = newTab.frame:FindFirstChildOfClass("UIScale")
			if tabScale then
				tabScale.Scale = 0.98
			end
			newTab.frame.Visible = true
			if tabScale then
				local tabSwitchTween = TweenService:Create(tabScale, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
					Scale = 1,
				})
				trackTween(tabSwitchTween)
				tabSwitchTween:Play()
			end
		end
	end

	-- === Show / Hide animations ===
	local function showWindow()
		if isVisible then return end
		isVisible = true
		windowContainer.Visible = true
		for _, delayThread in pendingDelays do
			task.cancel(delayThread)
		end
		table.clear(pendingDelays)
		cancelAllTweens()

		-- Hide reopener
		local reopenerTween = TweenService:Create(reopenerGlass.Container, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, 0, 0, -40),
		})
		trackTween(reopenerTween)
		reopenerTween:Play()

		-- Materialize in
		windowUIScale.Scale = 0.95
		glassFrame.GlassSurface.BackgroundTransparency = 1

		local scaleTween = TweenService:Create(windowUIScale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Scale = 1,
		})
		trackTween(scaleTween)
		scaleTween:Play()

		local delayThread1 = task.delay(0.03, function()
			if isDestroyed then return end
			local surfaceTween = TweenService:Create(glassFrame.GlassSurface, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundTransparency = windowBgTransp,
			})
			trackTween(surfaceTween)
			surfaceTween:Play()
		end)
		table.insert(pendingDelays, delayThread1)

		local delayThread2 = task.delay(0.08, function()
			if isDestroyed then return end
			for _, shadow in glassFrame.ShadowLayers do
				shadow.Visible = true
			end
		end)
		table.insert(pendingDelays, delayThread2)

		-- Show carousel dock with entrance animation
		if carouselDock then
			carouselDock.Container.Visible = true
			local delayThread3 = task.delay(0.1, function()
				if isDestroyed or not carouselDock then return end
				updateDockPosition()
				local pos = carouselDock.Container.Position
				carouselDock.Container.Position = UDim2.new(pos.X.Scale, pos.X.Offset, pos.Y.Scale, pos.Y.Offset + 30)
				local dockTween = TweenService:Create(carouselDock.Container, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
					Position = pos,
				})
				trackTween(dockTween)
				dockTween:Play()
			end)
			table.insert(pendingDelays, delayThread3)
		end
	end

	local function hideWindow()
		if not isVisible then return end
		isVisible = false
		cancelAllTweens()

		-- Hide carousel dock
		if carouselDock then
			carouselDock.Container.Visible = false
		end

		-- Shadows fade first
		for _, shadow in glassFrame.ShadowLayers do
			shadow.Visible = false
		end

		-- Surface dissolves
		local hideDelay1 = task.delay(0.04, function()
			if isDestroyed then return end
			TweenService:Create(glassFrame.GlassSurface, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundTransparency = 1,
			}):Play()
		end)
		table.insert(pendingDelays, hideDelay1)

		-- Scale out
		local scaleTween = TweenService:Create(windowUIScale, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Scale = 0.95,
		})
		trackTween(scaleTween)
		scaleTween:Play()
		scaleTween.Completed:Once(function()
			if isDestroyed then return end
			windowContainer.Visible = false
		end)

		-- Show reopener
		local hideDelay2 = task.delay(0.1, function()
			if isDestroyed then return end
			local reopenerTween = TweenService:Create(reopenerGlass.Container, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Position = UDim2.new(0.5, 0, 0, 8),
			})
			trackTween(reopenerTween)
			reopenerTween:Play()
		end)
		table.insert(pendingDelays, hideDelay2)
	end

	-- Close button click
	local closeClickConn = closeHitArea.MouseButton1Click:Connect(function()
		hideWindow()
	end)
	table.insert(connections, closeClickConn)

	-- Reopener click
	local reopenerClickConn = reopenerHitArea.MouseButton1Click:Connect(function()
		showWindow()
	end)
	table.insert(connections, reopenerClickConn)

	-- Toggle keybind
	if toggleKeyName then
		local keyCode = (Enum.KeyCode :: any)[toggleKeyName]
		if keyCode then
			local toggleConn = UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
				if gameProcessed then return end
				if input.KeyCode == keyCode then
					if isVisible then
						hideWindow()
					else
						showWindow()
					end
				end
			end)
			table.insert(connections, toggleConn)
		end
	end

	-- === Helper: create element row ===
	local function createRow(parentFrame: ScrollingFrame, height: number, name: string?): Frame
		local row = Instance.new("Frame")
		row.Name = name or "Row"
		row.Size = UDim2.new(1, 0, 0, height)
		row.BackgroundTransparency = 1
		row.BorderSizePixel = 0
		row.ZIndex = 10
		row.Parent = parentFrame
		return row
	end

	-- Update tab navigation when tabs change (carousel dock for multi-tab)
	local function rebuildTabSelector()
		if segmentedControl then
			segmentedControl:Destroy()
			segmentedControl = nil
		end
		if carouselDock then
			carouselDock:Destroy()
			carouselDock = nil
		end

		if #tabData <= 1 then
			tabSelectorFrame.Size = UDim2.new(1, 0, 0, 0)
			contentArea.Size = UDim2.new(1, 0, 1, -36)
			contentArea.Position = UDim2.new(0, 0, 0, 36)
			return
		end

		-- Build carousel tab configs from tabData
		local carouselTabs: {Types.MangoCarouselTabConfig} = {}
		for _, t in tabData do
			-- Auto-generate icon from first letter of name when no icon provided
			local tabIcon = t.icon
			if not tabIcon or tabIcon == "" then
				tabIcon = string.sub(t.name, 1, 1):upper()
			end
			table.insert(carouselTabs, {
				Icon = tabIcon,
				Label = t.name,
			})
		end

		carouselDock = MangoCarousel.new({
			Tabs = carouselTabs,
			Theme = theme,
			InitialIndex = currentTabIndex,
			OnChanged = function(index: number)
				switchToTab(index)
			end,
			Parent = screenGui,
		})
		carouselDock.Container.AnchorPoint = Vector2.new(1, 1)
		carouselDock.Container.ZIndex = 5
		carouselDock.Container.Visible = false

		-- No segmented control inside window — carousel handles tab switching
		tabSelectorFrame.Size = UDim2.new(1, 0, 0, 0)
		contentArea.Size = UDim2.new(1, 0, 1, -36)
		contentArea.Position = UDim2.new(0, 0, 0, 36)

		-- Position carousel next to window and show
		task.defer(function()
			if isDestroyed or not carouselDock then return end
			updateDockPosition()
			if isVisible then
				carouselDock.Container.Visible = true
			end
		end)
	end

	-- === Window return table ===
	local self: Types.MangoWindow

	-- Tab constructor
	local function createTab(name: string, icon: string?): Types.MangoWindowTab
		-- ScrollingFrame for tab content
		local tabFrame = Instance.new("ScrollingFrame")
		tabFrame.Name = "Tab_" .. name
		tabFrame.Size = UDim2.new(1, 0, 1, 0)
		tabFrame.BackgroundTransparency = 1
		tabFrame.BorderSizePixel = 0
		tabFrame.ScrollBarThickness = 4
		tabFrame.ScrollingDirection = Enum.ScrollingDirection.Y
		tabFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
		tabFrame.ZIndex = 10
		tabFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
		tabFrame.Visible = #tabData == 0 -- First tab is visible
		tabFrame.Parent = contentArea

		local tabUIScale = Instance.new("UIScale")
		tabUIScale.Scale = 1
		tabUIScale.Parent = tabFrame

		local tabLayout = Instance.new("UIListLayout")
		tabLayout.FillDirection = Enum.FillDirection.Vertical
		tabLayout.Padding = UDim.new(0, 10)
		tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
		tabLayout.Parent = tabFrame

		local tabPadding = Instance.new("UIPadding")
		tabPadding.PaddingTop = UDim.new(0, 6)
		tabPadding.PaddingBottom = UDim.new(0, 6)
		tabPadding.PaddingLeft = UDim.new(0, 6)
		tabPadding.PaddingRight = UDim.new(0, 6)
		tabPadding.Parent = tabFrame

		local elements: {Types.MangoWindowElement} = {}
		local entry = {name = name, icon = icon, frame = tabFrame, elements = elements}
		table.insert(tabData, entry)

		rebuildTabSelector()

		-- Element layout order counter
		local layoutOrder = 0
		local function nextOrder(): number
			layoutOrder += 1
			return layoutOrder
		end

		-- Tab methods
		local tab: Types.MangoWindowTab = {
			Button = function(self: Types.MangoWindowTab, cfg: Types.MangoWindowButtonConfig): Types.MangoWindowElement
				local row = createRow(tabFrame, 42)
				row.LayoutOrder = nextOrder()

				local btn = MangoButton.new({
					Position = UDim2.new(0.5, 0, 0.5, 0),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Size = UDim2.new(1, -12, 0, 36),
					Text = cfg.Name,
					Theme = theme,
					ShadowEnabled = false,
					OnActivated = cfg.Callback,
					Parent = row,
				})
				table.insert(innerDestroyables, btn)

				local element = createWindowElement({
					getValue = function() return nil end,
					setValue = function(_val: any)
						if cfg.Callback then cfg.Callback() end
					end,
					rowFrame = row,
					destroyInner = function() btn:Destroy() end,
				})
				if cfg.Flag then registerFlag(cfg.Flag, element, true) end
				if type(cfg.Visible) == "string" then registerDependency(element, cfg.Visible :: string) end
				table.insert(elements, element)
				return element
			end,

			Toggle = function(self: Types.MangoWindowTab, cfg: Types.MangoWindowToggleConfig): Types.MangoWindowElement
				local row = createRow(tabFrame, 38)
				row.LayoutOrder = nextOrder()

				local nameLabel = Instance.new("TextLabel")
				nameLabel.Size = UDim2.new(1, -60, 1, 0)
				nameLabel.BackgroundTransparency = 1
				nameLabel.Font = Enum.Font.GothamMedium
				nameLabel.TextSize = 14
				nameLabel.TextColor3 = primaryText
				nameLabel.Text = cfg.Name
				nameLabel.TextXAlignment = Enum.TextXAlignment.Left
				nameLabel.ZIndex = 10
				nameLabel.Parent = row

				local defaultVal = resolve(cfg.Default, nil, false) :: boolean
				local toggle = MangoToggle.new({
					Position = UDim2.new(1, -55, 0.5, 0),
					AnchorPoint = Vector2.new(0, 0.5),
					Theme = theme,
					ShadowEnabled = false,
					InitialState = defaultVal,
					OnToggled = function(state: boolean)
						if cfg.Flag then updateFlag(cfg.Flag, state) end
						if cfg.Callback then cfg.Callback(state) end
					end,
					Parent = row,
				})
				table.insert(innerDestroyables, toggle)

				local element = createWindowElement({
					getValue = function() return toggle:GetState() end,
					setValue = function(val: any) toggle:SetState(val :: boolean) end,
					rowFrame = row,
					destroyInner = function() toggle:Destroy() end,
				})
				if cfg.Flag then registerFlag(cfg.Flag, element, defaultVal) end
				if type(cfg.Visible) == "string" then registerDependency(element, cfg.Visible :: string) end
				table.insert(elements, element)
				return element
			end,

			Slider = function(self: Types.MangoWindowTab, cfg: Types.MangoWindowSliderConfig): Types.MangoWindowElement
				local row = createRow(tabFrame, 56)
				row.LayoutOrder = nextOrder()

				local range = cfg.Range or {0, 100}
				local minVal = range[1] or 0
				local maxVal = range[2] or 100
				local defaultVal = resolve(cfg.Default, nil, minVal) :: number
				local suffix = cfg.Suffix or ""

				local valueLabel = Instance.new("TextLabel")
				valueLabel.Size = UDim2.new(1, 0, 0, 18)
				valueLabel.BackgroundTransparency = 1
				valueLabel.Font = Enum.Font.GothamMedium
				valueLabel.TextSize = 13
				valueLabel.TextColor3 = primaryText
				valueLabel.Text = cfg.Name .. ": " .. tostring(defaultVal) .. suffix
				valueLabel.TextXAlignment = Enum.TextXAlignment.Left
				valueLabel.ZIndex = 10
				valueLabel.Parent = row

				local slider = MangoSlider.new({
					Position = UDim2.new(0, 8, 0, 22),
					Size = UDim2.new(1, -16, 0, 32),
					Theme = theme,
					ShadowEnabled = false,
					InitialValue = defaultVal,
					Min = minVal,
					Max = maxVal,
					Step = cfg.Increment,
					OnChanged = function(value: number)
						valueLabel.Text = cfg.Name .. ": " .. tostring(value) .. suffix
						if cfg.Flag then updateFlag(cfg.Flag, value) end
						if cfg.Callback then cfg.Callback(value) end
					end,
					Parent = row,
				})
				table.insert(innerDestroyables, slider)

				local element = createWindowElement({
					getValue = function() return slider:GetValue() end,
					setValue = function(val: any)
						slider:SetValue(val :: number)
						valueLabel.Text = cfg.Name .. ": " .. tostring(val) .. suffix
					end,
					rowFrame = row,
					destroyInner = function() slider:Destroy() end,
				})
				if cfg.Flag then registerFlag(cfg.Flag, element, defaultVal) end
				if type(cfg.Visible) == "string" then registerDependency(element, cfg.Visible :: string) end
				table.insert(elements, element)
				return element
			end,

			Dropdown = function(self: Types.MangoWindowTab, cfg: Types.MangoWindowDropdownConfig): Types.MangoWindowElement
				local row = createRow(tabFrame, 42)
				row.LayoutOrder = nextOrder()

				local options = cfg.Options or {}
				local isMulti = cfg.MultiSelect == true

				-- Find initial index from Default
				local initIndex = 1
				local initItems: {string}? = nil
				if type(cfg.Default) == "string" then
					for i, opt in options do
						if opt == cfg.Default then
							initIndex = i
							break
						end
					end
				elseif type(cfg.Default) == "table" then
					initItems = cfg.Default :: {string}
				end

				local nameLabel = Instance.new("TextLabel")
				nameLabel.Size = UDim2.new(0.4, 0, 1, 0)
				nameLabel.BackgroundTransparency = 1
				nameLabel.Font = Enum.Font.GothamMedium
				nameLabel.TextSize = 14
				nameLabel.TextColor3 = primaryText
				nameLabel.Text = cfg.Name
				nameLabel.TextXAlignment = Enum.TextXAlignment.Left
				nameLabel.ZIndex = 10
				nameLabel.Parent = row

				local dropdown = MangoDropdown.new({
					Position = UDim2.new(0.42, 2, 0, 2),
					Size = UDim2.new(0.56, -4, 0, 36),
					ShadowEnabled = false,
					Items = options,
					InitialIndex = initIndex,
					MultiSelect = isMulti,
					InitialItems = initItems,
					Theme = theme,
					OnChanged = function(index: number)
						if not isMulti then
							local val = options[index]
							if cfg.Flag then updateFlag(cfg.Flag, val) end
							if cfg.Callback then cfg.Callback(val) end
						end
					end,
					OnMultiChanged = if isMulti then function(selected: {string})
						if cfg.Flag then updateFlag(cfg.Flag, selected) end
						if cfg.Callback then cfg.Callback(selected) end
					end else nil,
					Parent = row,
				})
				table.insert(innerDestroyables, dropdown)

				local defaultValue: any = if isMulti then (initItems or {}) else (options[initIndex] or "")
				local element = createWindowElement({
					getValue = function()
						if isMulti then
							return dropdown:GetSelectedItems()
						end
						local idx = dropdown:GetSelectedIndex()
						return options[idx] or ""
					end,
					setValue = function(val: any)
						if type(val) == "string" then
							for i, opt in options do
								if opt == val then
									dropdown:SetSelectedIndex(i)
									break
								end
							end
						end
					end,
					rowFrame = row,
					destroyInner = function() dropdown:Destroy() end,
				})
				if cfg.Flag then registerFlag(cfg.Flag, element, defaultValue) end
				if type(cfg.Visible) == "string" then registerDependency(element, cfg.Visible :: string) end
				table.insert(elements, element)
				return element
			end,

			Input = function(self: Types.MangoWindowTab, cfg: Types.MangoWindowInputConfig): Types.MangoWindowElement
				local row = createRow(tabFrame, 56)
				row.LayoutOrder = nextOrder()

				local nameLabel = Instance.new("TextLabel")
				nameLabel.Size = UDim2.new(1, 0, 0, 18)
				nameLabel.BackgroundTransparency = 1
				nameLabel.Font = Enum.Font.GothamMedium
				nameLabel.TextSize = 13
				nameLabel.TextColor3 = primaryText
				nameLabel.Text = cfg.Name
				nameLabel.TextXAlignment = Enum.TextXAlignment.Left
				nameLabel.ZIndex = 10
				nameLabel.Parent = row

				local defaultText = resolve(cfg.Default, nil, "") :: string
				local textField = MangoTextField.new({
					Position = UDim2.new(0, 4, 0, 20),
					Size = UDim2.new(1, -8, 0, 36),
					Placeholder = cfg.Placeholder,
					InitialText = defaultText,
					Masked = cfg.Masked,
					ShadowEnabled = false,
					Theme = theme,
					OnFocusLost = function(text: string, _enterPressed: boolean)
						if cfg.Flag then updateFlag(cfg.Flag, text) end
						if cfg.Callback then cfg.Callback(text) end
					end,
					Parent = row,
				})
				table.insert(innerDestroyables, textField)

				local element = createWindowElement({
					getValue = function() return textField:GetText() end,
					setValue = function(val: any) textField:SetText(val :: string) end,
					rowFrame = row,
					destroyInner = function() textField:Destroy() end,
				})
				if cfg.Flag then registerFlag(cfg.Flag, element, defaultText) end
				if type(cfg.Visible) == "string" then registerDependency(element, cfg.Visible :: string) end
				table.insert(elements, element)
				return element
			end,

			Checkbox = function(self: Types.MangoWindowTab, cfg: Types.MangoWindowCheckboxConfig): Types.MangoWindowElement
				local row = createRow(tabFrame, 36)
				row.LayoutOrder = nextOrder()

				local defaultVal = resolve(cfg.Default, nil, false) :: boolean
				local checkbox = MangoCheckbox.new({
					Position = UDim2.new(0, 0, 0, 0),
					Label = cfg.Name,
					InitialState = defaultVal,
					Theme = theme,
					OnToggled = function(state: boolean)
						if cfg.Flag then updateFlag(cfg.Flag, state) end
						if cfg.Callback then cfg.Callback(state) end
					end,
					Parent = row,
				})
				table.insert(innerDestroyables, checkbox)

				local element = createWindowElement({
					getValue = function() return checkbox:GetState() end,
					setValue = function(val: any) checkbox:SetState(val :: boolean) end,
					rowFrame = row,
					destroyInner = function() checkbox:Destroy() end,
				})
				if cfg.Flag then registerFlag(cfg.Flag, element, defaultVal) end
				if type(cfg.Visible) == "string" then registerDependency(element, cfg.Visible :: string) end
				table.insert(elements, element)
				return element
			end,

			Stepper = function(self: Types.MangoWindowTab, cfg: Types.MangoWindowStepperConfig): Types.MangoWindowElement
				local row = createRow(tabFrame, 42)
				row.LayoutOrder = nextOrder()

				local range = cfg.Range or {0, 100}
				local defaultVal = resolve(cfg.Default, nil, range[1] or 0) :: number

				local nameLabel = Instance.new("TextLabel")
				nameLabel.Size = UDim2.new(0.5, 0, 1, 0)
				nameLabel.BackgroundTransparency = 1
				nameLabel.Font = Enum.Font.GothamMedium
				nameLabel.TextSize = 14
				nameLabel.TextColor3 = primaryText
				nameLabel.Text = cfg.Name
				nameLabel.TextXAlignment = Enum.TextXAlignment.Left
				nameLabel.ZIndex = 10
				nameLabel.Parent = row

				local stepper = MangoStepper.new({
					Position = UDim2.new(1, -124, 0.5, 0),
					AnchorPoint = Vector2.new(0, 0.5),
					InitialValue = defaultVal,
					Min = range[1],
					Max = range[2],
					ShadowEnabled = false,
					Theme = theme,
					OnChanged = function(value: number)
						if cfg.Flag then updateFlag(cfg.Flag, value) end
						if cfg.Callback then cfg.Callback(value) end
					end,
					Parent = row,
				})
				table.insert(innerDestroyables, stepper)

				local element = createWindowElement({
					getValue = function() return stepper:GetValue() end,
					setValue = function(val: any) stepper:SetValue(val :: number) end,
					rowFrame = row,
					destroyInner = function() stepper:Destroy() end,
				})
				if cfg.Flag then registerFlag(cfg.Flag, element, defaultVal) end
				if type(cfg.Visible) == "string" then registerDependency(element, cfg.Visible :: string) end
				table.insert(elements, element)
				return element
			end,

			Progress = function(self: Types.MangoWindowTab, cfg: Types.MangoWindowProgressConfig): Types.MangoWindowElement
				local row = createRow(tabFrame, 42)
				row.LayoutOrder = nextOrder()

				local defaultVal = resolve(cfg.Default, nil, 0) :: number

				local nameLabel = Instance.new("TextLabel")
				nameLabel.Size = UDim2.new(1, 0, 0, 18)
				nameLabel.BackgroundTransparency = 1
				nameLabel.Font = Enum.Font.GothamMedium
				nameLabel.TextSize = 13
				nameLabel.TextColor3 = primaryText
				nameLabel.Text = cfg.Name
				nameLabel.TextXAlignment = Enum.TextXAlignment.Left
				nameLabel.ZIndex = 10
				nameLabel.Parent = row

				local progressBar = MangoProgressBar.new({
					Position = UDim2.new(0, 4, 0, 20),
					Size = UDim2.new(1, -8, 0, 20),
					InitialValue = defaultVal,
					ShadowEnabled = false,
					Theme = theme,
					Parent = row,
				})
				table.insert(innerDestroyables, progressBar)

				local element = createWindowElement({
					getValue = function() return progressBar:GetValue() end,
					setValue = function(val: any) progressBar:SetValue(val :: number) end,
					rowFrame = row,
					destroyInner = function() progressBar:Destroy() end,
				})
				if cfg.Flag then registerFlag(cfg.Flag, element, defaultVal) end
				if type(cfg.Visible) == "string" then registerDependency(element, cfg.Visible :: string) end
				table.insert(elements, element)
				return element
			end,

			ColorPicker = function(self: Types.MangoWindowTab, cfg: Types.MangoWindowColorPickerConfig): Types.MangoWindowElement
				local row = createRow(tabFrame, 40)
				row.LayoutOrder = nextOrder()

				local defaultColor = resolve(cfg.Default, nil, Color3.fromRGB(255, 0, 0)) :: Color3

				local nameLabel = Instance.new("TextLabel")
				nameLabel.Size = UDim2.new(1, -36, 1, 0)
				nameLabel.BackgroundTransparency = 1
				nameLabel.Font = Enum.Font.GothamMedium
				nameLabel.TextSize = 14
				nameLabel.TextColor3 = primaryText
				nameLabel.Text = cfg.Name
				nameLabel.TextXAlignment = Enum.TextXAlignment.Left
				nameLabel.ZIndex = 10
				nameLabel.Parent = row

				-- Color preview circle
				local preview = Instance.new("Frame")
				preview.Name = "ColorPreview"
				preview.Size = UDim2.new(0, 24, 0, 24)
				preview.Position = UDim2.new(1, -4, 0.5, 0)
				preview.AnchorPoint = Vector2.new(1, 0.5)
				preview.BackgroundColor3 = defaultColor
				preview.BorderSizePixel = 0
				preview.ZIndex = 10
				preview.Parent = row

				local previewCorner = Instance.new("UICorner")
				previewCorner.CornerRadius = UDim.new(0, 999)
				previewCorner.Parent = preview

				local previewStroke = Instance.new("UIStroke")
				previewStroke.Thickness = 1
				previewStroke.Color = Color3.fromRGB(200, 200, 205)
				previewStroke.Transparency = 0.5
				previewStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				previewStroke.Parent = preview

				-- Popup color picker (created on click, destroyed on close)
				local pickerInstance: Types.MangoColorPicker? = nil
				local previewHitArea = Instance.new("TextButton")
				previewHitArea.Name = "PreviewHitArea"
				previewHitArea.Size = UDim2.new(0, 32, 0, 32)
				previewHitArea.AnchorPoint = Vector2.new(1, 0.5)
				previewHitArea.Position = UDim2.new(1, 4, 0.5, 0)
				previewHitArea.BackgroundTransparency = 1
				previewHitArea.Text = ""
				previewHitArea.ZIndex = 100
				previewHitArea.AutoButtonColor = false
				previewHitArea.Parent = row

				local previewConn = previewHitArea.MouseButton1Click:Connect(function()
					if pickerInstance then
						pickerInstance:Destroy()
						pickerInstance = nil
						return
					end

					local absPos = preview.AbsolutePosition
					pickerInstance = MangoColorPicker.new({
						Position = UDim2.new(0, absPos.X - 240, 0, absPos.Y + 30),
						InitialColor = preview.BackgroundColor3,
						Theme = theme,
						OnChanged = function(color: Color3)
							preview.BackgroundColor3 = color
							if cfg.Flag then updateFlag(cfg.Flag, color) end
							if cfg.Callback then cfg.Callback(color) end
						end,
						Parent = screenGui,
					})
					table.insert(innerDestroyables, pickerInstance)
				end)
				table.insert(connections, previewConn)

				local element = createWindowElement({
					getValue = function() return preview.BackgroundColor3 end,
					setValue = function(val: any)
						local c = val :: Color3
						preview.BackgroundColor3 = c
						if pickerInstance then
							pickerInstance:SetColor(c)
						end
					end,
					rowFrame = row,
					destroyInner = function()
						if pickerInstance then
							pickerInstance:Destroy()
							pickerInstance = nil
						end
					end,
				})
				if cfg.Flag then registerFlag(cfg.Flag, element, defaultColor) end
				if type(cfg.Visible) == "string" then registerDependency(element, cfg.Visible :: string) end
				table.insert(elements, element)
				return element
			end,

			Keybind = function(self: Types.MangoWindowTab, cfg: Types.MangoWindowKeybindConfig): Types.MangoWindowElement
				local row = createRow(tabFrame, 42)
				row.LayoutOrder = nextOrder()

				local defaultKey = resolve(cfg.Default, nil, "None") :: string

				local nameLabel = Instance.new("TextLabel")
				nameLabel.Size = UDim2.new(1, -90, 1, 0)
				nameLabel.BackgroundTransparency = 1
				nameLabel.Font = Enum.Font.GothamMedium
				nameLabel.TextSize = 14
				nameLabel.TextColor3 = primaryText
				nameLabel.Text = cfg.Name
				nameLabel.TextXAlignment = Enum.TextXAlignment.Left
				nameLabel.ZIndex = 10
				nameLabel.Parent = row

				local keybind = MangoKeybind.new({
					Position = UDim2.new(1, -84, 0.5, 0),
					AnchorPoint = Vector2.new(0, 0.5),
					DefaultKey = defaultKey,
					ShadowEnabled = false,
					Theme = theme,
					OnKeyChanged = function(keyName: string)
						if cfg.Flag then updateFlag(cfg.Flag, keyName) end
						if cfg.Callback then cfg.Callback(keyName) end
					end,
					Parent = row,
				})
				table.insert(innerDestroyables, keybind)

				local element = createWindowElement({
					getValue = function() return keybind:GetKey() end,
					setValue = function(val: any) keybind:SetKey(val :: string) end,
					rowFrame = row,
					destroyInner = function() keybind:Destroy() end,
				})
				if cfg.Flag then registerFlag(cfg.Flag, element, defaultKey) end
				if type(cfg.Visible) == "string" then registerDependency(element, cfg.Visible :: string) end
				table.insert(elements, element)
				return element
			end,

			Label = function(self: Types.MangoWindowTab, text: string): Types.MangoWindowElement
				local row = createRow(tabFrame, 20)
				row.LayoutOrder = nextOrder()

				local label = Instance.new("TextLabel")
				label.Size = UDim2.new(1, 0, 1, 0)
				label.BackgroundTransparency = 1
				label.Font = Enum.Font.Gotham
				label.TextSize = 13
				label.TextColor3 = secondaryText
				label.Text = text
				label.TextXAlignment = Enum.TextXAlignment.Left
				label.ZIndex = 10
				label.Parent = row

				local element = createWindowElement({
					getValue = function() return label.Text end,
					setValue = function(val: any) label.Text = val :: string end,
					rowFrame = row,
					destroyInner = function() end,
				})
				table.insert(elements, element)
				return element
			end,

			Paragraph = function(self: Types.MangoWindowTab, cfg: Types.MangoWindowParagraphConfig): Types.MangoWindowElement
				local row = Instance.new("Frame")
				row.Name = "Paragraph"
				row.Size = UDim2.new(1, 0, 0, 0)
				row.AutomaticSize = Enum.AutomaticSize.Y
				row.BackgroundTransparency = 1
				row.BorderSizePixel = 0
				row.ZIndex = 10
				row.LayoutOrder = nextOrder()
				row.Parent = tabFrame

				local paraLayout = Instance.new("UIListLayout")
				paraLayout.FillDirection = Enum.FillDirection.Vertical
				paraLayout.Padding = UDim.new(0, 2)
				paraLayout.SortOrder = Enum.SortOrder.LayoutOrder
				paraLayout.Parent = row

				local titleLbl = Instance.new("TextLabel")
				titleLbl.Size = UDim2.new(1, 0, 0, 0)
				titleLbl.AutomaticSize = Enum.AutomaticSize.Y
				titleLbl.BackgroundTransparency = 1
				titleLbl.Font = Enum.Font.GothamBold
				titleLbl.TextSize = 14
				titleLbl.TextColor3 = primaryText
				titleLbl.Text = cfg.Title
				titleLbl.TextXAlignment = Enum.TextXAlignment.Left
				titleLbl.TextWrapped = true
				titleLbl.ZIndex = 10
				titleLbl.LayoutOrder = 1
				titleLbl.Parent = row

				local contentLbl = Instance.new("TextLabel")
				contentLbl.Size = UDim2.new(1, 0, 0, 0)
				contentLbl.AutomaticSize = Enum.AutomaticSize.Y
				contentLbl.BackgroundTransparency = 1
				contentLbl.Font = Enum.Font.Gotham
				contentLbl.TextSize = 13
				contentLbl.TextColor3 = secondaryText
				contentLbl.Text = cfg.Content
				contentLbl.TextXAlignment = Enum.TextXAlignment.Left
				contentLbl.TextWrapped = true
				contentLbl.ZIndex = 10
				contentLbl.LayoutOrder = 2
				contentLbl.Parent = row

				local element = createWindowElement({
					getValue = function() return cfg.Content end,
					setValue = function(val: any) contentLbl.Text = val :: string end,
					rowFrame = row,
					destroyInner = function() end,
				})
				if type(cfg.Visible) == "string" then registerDependency(element, cfg.Visible :: string) end
				table.insert(elements, element)
				return element
			end,

			Section = function(self: Types.MangoWindowTab, title: string): Types.MangoWindowElement
				local row = createRow(tabFrame, 36)
				row.LayoutOrder = nextOrder()

				local sectionLabel = Instance.new("TextLabel")
				sectionLabel.Size = UDim2.new(1, 0, 0, 22)
				sectionLabel.BackgroundTransparency = 1
				sectionLabel.Font = Enum.Font.GothamBold
				sectionLabel.TextSize = 15
				sectionLabel.TextColor3 = primaryText
				sectionLabel.Text = title
				sectionLabel.TextXAlignment = Enum.TextXAlignment.Left
				sectionLabel.ZIndex = 10
				sectionLabel.Parent = row

				local sep = Instance.new("Frame")
				sep.Size = UDim2.new(1, 0, 0, 1)
				sep.Position = UDim2.new(0, 0, 1, -1)
				sep.BackgroundColor3 = bgColor
				sep.BackgroundTransparency = 0.80
				sep.BorderSizePixel = 0
				sep.ZIndex = 10
				sep.Parent = row

				local element = createWindowElement({
					getValue = function() return title end,
					setValue = function(val: any) sectionLabel.Text = val :: string end,
					rowFrame = row,
					destroyInner = function() end,
				})
				table.insert(elements, element)
				return element
			end,

			Separator = function(self: Types.MangoWindowTab): Types.MangoWindowElement
				local row = createRow(tabFrame, 9)
				row.LayoutOrder = nextOrder()

				local sep = Instance.new("Frame")
				sep.Size = UDim2.new(1, 0, 0, 1)
				sep.Position = UDim2.new(0, 0, 0.5, 0)
				sep.AnchorPoint = Vector2.new(0, 0.5)
				sep.BackgroundColor3 = bgColor
				sep.BackgroundTransparency = 0.80
				sep.BorderSizePixel = 0
				sep.ZIndex = 10
				sep.Parent = row

				local element = createWindowElement({
					getValue = function() return nil end,
					setValue = function(_val: any) end,
					rowFrame = row,
					destroyInner = function() end,
				})
				table.insert(elements, element)
				return element
			end,
		}

		return tab
	end

	self = {
		Flags = flags,
		Tab = function(self: Types.MangoWindow, name: string, icon: string?): Types.MangoWindowTab
			return createTab(name, icon)
		end,
		Notify = function(self: Types.MangoWindow, cfg: Types.MangoNotificationConfig)
			local notif = notifStack:Push(cfg)
			notif:Show()
		end,
		Dialog = function(self: Types.MangoWindow, cfg: Types.MangoDialogConfig)
			local dialog = MangoDialog.new({
				Title = cfg.Title,
				Message = cfg.Message,
				Buttons = cfg.Buttons,
				Theme = theme,
				OnDismissed = cfg.OnDismissed,
				Parent = screenGui,
			})
			table.insert(innerDestroyables, dialog)
			dialog:Show()
		end,
		Show = function(self: Types.MangoWindow)
			showWindow()
		end,
		Hide = function(self: Types.MangoWindow)
			hideWindow()
		end,
		IsVisible = function(self: Types.MangoWindow): boolean
			return isVisible
		end,
		SaveConfig = function(self: Types.MangoWindow)
			if saveManager then
				-- Serialize Color3 values to table format
				local serialized: {[string]: any} = {}
				for key, value in flags do
					if typeof(value) == "Color3" then
						local c = value :: Color3
						serialized[key] = {_type = "Color3", R = c.R, G = c.G, B = c.B}
					else
						serialized[key] = value
					end
				end
				saveManager:Save(serialized)
			end
		end,
		LoadConfig = function(self: Types.MangoWindow)
			if not saveManager then return end
			local data = saveManager:Load()
			if not data then return end
			for key, value in data do
				-- Deserialize Color3
				if type(value) == "table" and (value :: any)._type == "Color3" then
					value = Color3.new((value :: any).R, (value :: any).G, (value :: any).B)
				end
				flags[key] = value
				local element = flagElements[key]
				if element then
					element:Set(value)
				end
				evaluateDependencies(key)
			end
		end,
		Destroy = function(self: Types.MangoWindow)
			if isDestroyed then return end
			isDestroyed = true

			if saveDebounceThread then
				task.cancel(saveDebounceThread)
				saveDebounceThread = nil
			end

			for _, delayThread in pendingDelays do
				task.cancel(delayThread)
			end
			table.clear(pendingDelays)

			if closeHoverTween then
				closeHoverTween:Cancel()
				closeHoverTween = nil
			end

			cancelAllTweens()
			for _, conn in connections do
				conn:Disconnect()
			end
			table.clear(connections)

			for _, destroyable in innerDestroyables do
				if typeof(destroyable) == "table" and (destroyable :: any).Destroy then
					(destroyable :: any):Destroy()
				end
			end
			table.clear(innerDestroyables)

			if carouselDock then
				carouselDock:Destroy()
				carouselDock = nil
			end

			notifStack:Destroy()
			glassFrame:Destroy()
			reopenerGlass:Destroy()
			screenGui:Destroy()
		end,
	}

	-- Auto-load saved config
	if saveManager then
		task.defer(function()
			if isDestroyed then return end
			self:LoadConfig()
		end)
	end

	return self
end

return module
