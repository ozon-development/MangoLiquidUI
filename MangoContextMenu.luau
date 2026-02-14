--!strict

local Types = require(script.Parent.Types)
local Themes = require(script.Parent.Themes)
local MangoGlassFrame = require(script.Parent.MangoGlassFrame)
local resolve = Themes.resolve
local MangoProtection = require(script.Parent.MangoProtection)
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local module = {}

function module.new(config: Types.MangoContextMenuConfig): Types.MangoContextMenu
	local theme = config.Theme
	local items = table.clone(config.Items)
	local target = config.Target

	-- Theme values (reuse dropdown theme fields)
	local primaryText = resolve(nil, theme and theme.PrimaryTextColor, Color3.fromRGB(0, 0, 0)) :: Color3
	local secondaryText = resolve(nil, theme and theme.SecondaryTextColor, Color3.fromRGB(60, 60, 70)) :: Color3
	local dropdownBgTransparency = resolve(nil, theme and theme.DropdownBackgroundTransparency, 0.82) :: number
	local itemHoverColor = resolve(nil, theme and theme.DropdownItemHoverColor, Color3.fromRGB(0, 122, 255)) :: Color3
	local itemHoverTransparency = resolve(nil, theme and theme.DropdownItemHoverTransparency, 0.85) :: number
	local bgColor = resolve(nil, theme and theme.BackgroundColor3, Color3.fromRGB(230, 230, 235)) :: Color3

	-- State
	local isOpen = false
	local isDestroyed = false
	local activeTweens: {Tween} = {}
	local itemHoverTweens: {Tween} = {}
	local connections: {RBXScriptConnection} = {}
	local itemConnections: {RBXScriptConnection} = {}
	local clickBlocker: TextButton? = nil
	local longPressThread: thread? = nil

	local function cancelAllTweens()
		for _, tween in activeTweens do
			tween:Cancel()
		end
		table.clear(activeTweens)
	end

	local function cancelItemHoverTweens()
		for _, tween in itemHoverTweens do
			tween:Cancel()
		end
		table.clear(itemHoverTweens)
	end

	local function trackTween(tween: Tween): Tween
		table.insert(activeTweens, tween)
		return tween
	end

	local function trackItemHoverTween(tween: Tween): Tween
		table.insert(itemHoverTweens, tween)
		return tween
	end

	-- Forward declaration for closeMenu
	local closeMenu: () -> ()

	-- Find ScreenGui by walking ancestors
	local function findScreenGui(): ScreenGui?
		local current: Instance? = target
		while current do
			if current:IsA("ScreenGui") then
				return current :: ScreenGui
			end
			current = current.Parent
		end
		return nil
	end

	-- Click blocker management
	local function createClickBlocker()
		local screenGui = findScreenGui()
		if not screenGui then return end

		local blocker = Instance.new("TextButton")
		blocker.Name = MangoProtection.randomName("Blocker")
		blocker.Size = UDim2.new(1, 0, 1, 0)
		blocker.BackgroundTransparency = 1
		blocker.Text = ""
		blocker.ZIndex = 49
		blocker.AutoButtonColor = false
		blocker.Parent = screenGui
		clickBlocker = blocker

		blocker.MouseButton1Click:Connect(function()
			closeMenu()
		end)
	end

	local function destroyClickBlocker()
		if clickBlocker then
			clickBlocker:Destroy()
			clickBlocker = nil
		end
	end

	-- Panel glass frame
	local itemHeight = 36
	local maxVisibleItems = 8
	local panelItemCount = math.min(#items, maxVisibleItems)
	local panelHeight = panelItemCount * itemHeight + 8

	local panelGlass = MangoGlassFrame.new({
		Size = UDim2.new(0, 200, 0, panelHeight),
		Position = UDim2.new(0, 0, 0, 0),
		CornerRadius = UDim.new(0, 12),
		BackgroundTransparency = dropdownBgTransparency - 0.05,
		Theme = theme,
		ShadowEnabled = true,
		ShadowLayerCount = 4,
		ShadowSpread = 6,
		ShadowOffsetY = 2,
		LightweightMode = true,
	})
	panelGlass.Container.Visible = false
	panelGlass.Container.ZIndex = 50

	-- UIScale for open/close animation
	local panelUIScale = Instance.new("UIScale")
	panelUIScale.Scale = 0.92
	panelUIScale.Parent = panelGlass.Container

	-- ScrollingFrame inside panel GlassSurface
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "ScrollFrame"
	scrollFrame.Size = UDim2.new(1, 0, 1, 0)
	scrollFrame.Position = UDim2.new(0, 0, 0, 0)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = if #items > maxVisibleItems then 4 else 0
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, #items * itemHeight)
	scrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
	scrollFrame.ZIndex = 10
	scrollFrame.Parent = panelGlass.GlassSurface

	local scrollPadding = Instance.new("UIPadding")
	scrollPadding.PaddingTop = UDim.new(0, 4)
	scrollPadding.PaddingBottom = UDim.new(0, 4)
	scrollPadding.Parent = scrollFrame

	local scrollLayout = Instance.new("UIListLayout")
	scrollLayout.FillDirection = Enum.FillDirection.Vertical
	scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
	scrollLayout.Padding = UDim.new(0, 0)
	scrollLayout.Parent = scrollFrame

	-- Item frames storage
	local itemFrames: {Frame} = {}

	local function clearItemConnections()
		for _, conn in itemConnections do
			conn:Disconnect()
		end
		table.clear(itemConnections)
	end

	local function buildItems()
		-- Clear old items
		clearItemConnections()
		for _, frame in itemFrames do
			frame:Destroy()
		end
		table.clear(itemFrames)

		for i = 1, #items do
			local itemConfig = items[i]
			local itemFrame = Instance.new("Frame")
			itemFrame.Name = "Item" .. i
			itemFrame.Size = UDim2.new(1, 0, 0, itemHeight)
			itemFrame.BackgroundColor3 = itemHoverColor
			itemFrame.BackgroundTransparency = 1
			itemFrame.BorderSizePixel = 0
			itemFrame.LayoutOrder = i
			itemFrame.Parent = scrollFrame

			local itemCorner = Instance.new("UICorner")
			itemCorner.CornerRadius = UDim.new(0, 8)
			itemCorner.Parent = itemFrame

			-- Determine text offset based on icon presence
			local hasIcon = itemConfig.Icon ~= nil and itemConfig.Icon ~= ""
			local textOffsetX = if hasIcon then 36 else 12

			-- Optional icon label (left side)
			if hasIcon then
				local iconLabel = Instance.new("TextLabel")
				iconLabel.Name = "IconLabel"
				iconLabel.Size = UDim2.new(0, 20, 1, 0)
				iconLabel.Position = UDim2.new(0, 10, 0, 0)
				iconLabel.BackgroundTransparency = 1
				iconLabel.BorderSizePixel = 0
				iconLabel.Font = Enum.Font.Gotham
				iconLabel.TextSize = 16
				iconLabel.TextColor3 = primaryText
				iconLabel.Text = itemConfig.Icon :: string
				iconLabel.ZIndex = 10
				iconLabel.Parent = itemFrame
			end

			-- Determine text color based on style and disabled state
			local style = itemConfig.Style or "default"
			local isDisabled = itemConfig.Disabled == true
			local textColor: Color3
			if style == "destructive" then
				textColor = Color3.fromRGB(255, 59, 48)
			else
				textColor = primaryText
			end

			local itemLabel = Instance.new("TextLabel")
			itemLabel.Name = "ItemLabel"
			itemLabel.Size = UDim2.new(1, -(textOffsetX + 12), 1, 0)
			itemLabel.Position = UDim2.new(0, textOffsetX, 0, 0)
			itemLabel.BackgroundTransparency = 1
			itemLabel.BorderSizePixel = 0
			itemLabel.Font = Enum.Font.GothamMedium
			itemLabel.TextSize = 14
			itemLabel.TextColor3 = textColor
			itemLabel.TextTransparency = if isDisabled then 0.5 else 0
			itemLabel.TextXAlignment = Enum.TextXAlignment.Left
			itemLabel.TextTruncate = Enum.TextTruncate.AtEnd
			itemLabel.Text = itemConfig.Text
			itemLabel.ZIndex = 10
			itemLabel.Parent = itemFrame

			-- Separator between items
			if i < #items then
				local sep = Instance.new("Frame")
				sep.Name = "Separator"
				sep.Size = UDim2.new(1, -24, 0, 1)
				sep.Position = UDim2.new(0, 12, 1, 0)
				sep.BackgroundColor3 = bgColor
				sep.BackgroundTransparency = 0.80
				sep.BorderSizePixel = 0
				sep.ZIndex = 5
				sep.Parent = itemFrame
			end

			local itemHitArea = Instance.new("TextButton")
			itemHitArea.Name = "HitArea"
			itemHitArea.Size = UDim2.new(1, 0, 1, 0)
			itemHitArea.BackgroundTransparency = 1
			itemHitArea.Text = ""
			itemHitArea.BorderSizePixel = 0
			itemHitArea.ZIndex = 100
			itemHitArea.AutoButtonColor = false
			itemHitArea.Parent = itemFrame

			-- Hover highlight (skip for disabled items)
			if not isDisabled then
				local hoverEnter = itemHitArea.MouseEnter:Connect(function()
					cancelItemHoverTweens()
					local tw = TweenService:Create(itemFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						BackgroundTransparency = itemHoverTransparency,
					})
					trackItemHoverTween(tw)
					tw:Play()
				end)
				table.insert(itemConnections, hoverEnter)

				local hoverLeave = itemHitArea.MouseLeave:Connect(function()
					cancelItemHoverTweens()
					local tw = TweenService:Create(itemFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						BackgroundTransparency = 1,
					})
					trackItemHoverTween(tw)
					tw:Play()
				end)
				table.insert(itemConnections, hoverLeave)

				-- Click handler
				local clickConn = itemHitArea.MouseButton1Click:Connect(function()
					closeMenu()
					if itemConfig.OnActivated then
						itemConfig.OnActivated()
					end
				end)
				table.insert(itemConnections, clickConn)
			end

			table.insert(itemFrames, itemFrame)
		end

		-- Update scroll canvas size
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, #items * itemHeight)
		scrollFrame.ScrollBarThickness = if #items > maxVisibleItems then 4 else 0

		-- Update panel height
		local newPanelItemCount = math.min(#items, maxVisibleItems)
		local newPanelHeight = newPanelItemCount * itemHeight + 8
		panelGlass.Container.Size = UDim2.new(0, 200, 0, newPanelHeight)
	end

	-- Open/Close
	closeMenu = function()
		if not isOpen then
			return
		end
		isOpen = false
		cancelAllTweens()
		destroyClickBlocker()

		local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local scaleTween = TweenService:Create(panelUIScale, tweenInfo, { Scale = 0.95 })
		trackTween(scaleTween)
		scaleTween:Play()

		local fadeTween = TweenService:Create(panelGlass.GlassSurface, tweenInfo, {
			BackgroundTransparency = 1,
		})
		trackTween(fadeTween)
		fadeTween:Play()

		scaleTween.Completed:Once(function()
			if isDestroyed then return end
			panelGlass.Container.Visible = false
		end)
	end

	local function openMenu(position: Vector2?)
		if isOpen then
			closeMenu()
		end
		if isDestroyed then return end
		isOpen = true
		cancelAllTweens()
		createClickBlocker()

		-- Determine position
		local menuPos: Vector2
		if position then
			menuPos = position
		else
			local mouseLocation = UserInputService:GetMouseLocation()
			menuPos = mouseLocation
		end

		-- Reparent panel to ScreenGui for proper Z layering
		local screenGui = findScreenGui()
		if screenGui then
			panelGlass.Container.Parent = screenGui
			panelGlass.Container.Position = UDim2.new(0, menuPos.X, 0, menuPos.Y)
		end

		panelGlass.Container.Visible = true
		panelGlass.Container.ZIndex = 50
		panelUIScale.Scale = 0.92
		panelGlass.GlassSurface.BackgroundTransparency = 1

		local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		local scaleTween = TweenService:Create(panelUIScale, tweenInfo, { Scale = 1 })
		trackTween(scaleTween)
		scaleTween:Play()

		local fadeTween = TweenService:Create(panelGlass.GlassSurface, tweenInfo, {
			BackgroundTransparency = dropdownBgTransparency - 0.05,
		})
		trackTween(fadeTween)
		fadeTween:Play()
	end

	-- Bind right-click to target
	local targetHitArea: TextButton? = nil

	-- Check if target already has a TextButton child we can use, otherwise create one
	local existingHit = target:FindFirstChild("ContextMenuHitArea")
	if existingHit and existingHit:IsA("TextButton") then
		targetHitArea = existingHit :: TextButton
	else
		local hitArea = Instance.new("TextButton")
		hitArea.Name = "ContextMenuHitArea"
		hitArea.Size = UDim2.new(1, 0, 1, 0)
		hitArea.BackgroundTransparency = 1
		hitArea.Text = ""
		hitArea.BorderSizePixel = 0
		hitArea.ZIndex = 99
		hitArea.AutoButtonColor = false
		hitArea.Parent = target
		targetHitArea = hitArea
	end

	-- Right-click binding
	local rightClickConn = (targetHitArea :: TextButton).MouseButton2Click:Connect(function()
		local mouseLocation = UserInputService:GetMouseLocation()
		openMenu(mouseLocation)
	end)
	table.insert(connections, rightClickConn)

	-- Touch long-press binding (0.5s hold)
	local touchConn = (targetHitArea :: TextButton).InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.Touch then
			local touchPos = input.Position
			longPressThread = task.delay(0.5, function()
				longPressThread = nil
				openMenu(Vector2.new(touchPos.X, touchPos.Y))
			end)
		end
	end)
	table.insert(connections, touchConn)

	local touchEndConn = (targetHitArea :: TextButton).InputEnded:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.Touch then
			if longPressThread then
				task.cancel(longPressThread)
				longPressThread = nil
			end
		end
	end)
	table.insert(connections, touchEndConn)

	-- Build initial items
	buildItems()

	-- Parent assignment
	if config.Parent then
		panelGlass.Container.Parent = config.Parent
	end

	-- Return table
	local self: Types.MangoContextMenu = {
		Open = function(self: Types.MangoContextMenu, position: Vector2?)
			openMenu(position)
		end,
		Close = function(self: Types.MangoContextMenu)
			closeMenu()
		end,
		SetItems = function(self: Types.MangoContextMenu, newItems: {Types.MangoContextMenuItemConfig})
			items = table.clone(newItems)
			buildItems()
		end,
		Destroy = function(self: Types.MangoContextMenu)
			if isDestroyed then return end
			isDestroyed = true
			closeMenu()
			cancelAllTweens()
			cancelItemHoverTweens()
			clearItemConnections()
			destroyClickBlocker()
			for _, conn in connections do
				conn:Disconnect()
			end
			table.clear(connections)
			if longPressThread then
				task.cancel(longPressThread)
				longPressThread = nil
			end
			if targetHitArea and targetHitArea.Name == "ContextMenuHitArea" then
				targetHitArea:Destroy()
			end
			panelGlass:Destroy()
		end,
	}

	return self
end

return module
