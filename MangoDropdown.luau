--!strict

local Types = require(script.Parent.Types)
local Themes = require(script.Parent.Themes)
local MangoGlassFrame = require(script.Parent.MangoGlassFrame)
local resolve = Themes.resolve
local MangoProtection = require(script.Parent.MangoProtection)
local TweenService = game:GetService("TweenService")

local module = {}

function module.new(config: Types.MangoDropdownConfig): Types.MangoDropdown
	local theme = config.Theme
	local items = table.clone(resolve(config.Items, nil, {"Option 1"}) :: {string})
	local itemCount = #items

	-- Resolve config values
	local size = resolve(config.Size, nil, UDim2.new(0, 200, 0, 36)) :: UDim2
	local position = resolve(config.Position, nil, UDim2.new(0, 0, 0, 0)) :: UDim2
	local anchorPoint = resolve(config.AnchorPoint, nil, Vector2.new(0, 0)) :: Vector2
	local initialIndex = resolve(config.InitialIndex, nil, 1) :: number

	-- Theme values
	local primaryText = resolve(nil, theme and theme.PrimaryTextColor, Color3.fromRGB(0, 0, 0)) :: Color3
	local secondaryText = resolve(nil, theme and theme.SecondaryTextColor, Color3.fromRGB(60, 60, 70)) :: Color3
	local dropdownBgTransparency = resolve(nil, theme and theme.DropdownBackgroundTransparency, 0.82) :: number
	local itemHoverColor = resolve(nil, theme and theme.DropdownItemHoverColor, Color3.fromRGB(0, 122, 255)) :: Color3
	local itemHoverTransparency = resolve(nil, theme and theme.DropdownItemHoverTransparency, 0.85) :: number

	-- Multi-select support
	local isMultiSelect = config.MultiSelect == true
	local selectedIndices: {[number]: boolean} = {}

	-- State
	local selectedIndex: number = math.clamp(initialIndex, 1, math.max(itemCount, 1))
	local isOpen = false
	local isDestroyed = false
	local activeTweens: {Tween} = {}
	local itemHoverTweens: {Tween} = {}
	local connections: {RBXScriptConnection} = {}
	local itemConnections: {RBXScriptConnection} = {}
	local clickBlocker: TextButton? = nil
	local positionTrackConn: RBXScriptConnection? = nil

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

	-- Initialize multi-select
	if isMultiSelect and config.InitialItems then
		for _, itemName in config.InitialItems do
			for i, name in items do
				if name == itemName then
					selectedIndices[i] = true
				end
			end
		end
	elseif isMultiSelect then
		selectedIndices[selectedIndex] = true
	end

	local function getMultiSelectDisplayText(): string
		local selected: {string} = {}
		for i, item in items do
			if selectedIndices[i] then
				table.insert(selected, item)
			end
		end
		if #selected == 0 then return "Select..." end
		if #selected <= 2 then return table.concat(selected, ", ") end
		return #selected .. " selected"
	end

	-- Forward declaration for closeDropdown (used by click-blocker before definition)
	local closeDropdown: () -> ()

	-- Container (transparent wrapper, holds trigger + panel)
	local container = Instance.new("Frame")
	container.Name = MangoProtection.randomName("Dropdown")
	container.Size = UDim2.new(size.X.Scale, size.X.Offset, size.Y.Scale, size.Y.Offset + 0)
	container.Position = position
	container.AnchorPoint = anchorPoint
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0
	container.ClipsDescendants = false

	local function findScreenGui(): ScreenGui?
		local current: Instance? = container
		while current do
			if current:IsA("ScreenGui") then
				return current :: ScreenGui
			end
			current = current.Parent
		end
		return nil
	end

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
			closeDropdown()
		end)
	end

	local function destroyClickBlocker()
		if clickBlocker then
			clickBlocker:Destroy()
			clickBlocker = nil
		end
	end

	-- Trigger button via MangoGlassFrame (LightweightMode)
	-- Use (1,0,1,0) so trigger fills the container — avoids double-scaling when
	-- config.Size uses Scale (e.g. inside MangoWindow rows).
	local triggerGlass = MangoGlassFrame.new({
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		CornerRadius = UDim.new(0, 999),
		BackgroundTransparency = dropdownBgTransparency,
		Theme = theme,
		ShadowEnabled = resolve(config.ShadowEnabled, nil, true) :: boolean,
		ShadowLayerCount = 2,
		ShadowSpread = 4,
		ShadowOffsetY = 1,
		LightweightMode = true,
		Parent = container,
	})

	-- SelectedLabel (left-aligned text)
	local selectedLabel = Instance.new("TextLabel")
	selectedLabel.Name = "SelectedLabel"
	selectedLabel.Size = UDim2.new(1, -40, 1, 0)
	selectedLabel.Position = UDim2.new(0, 14, 0, 0)
	selectedLabel.BackgroundTransparency = 1
	selectedLabel.BorderSizePixel = 0
	selectedLabel.Font = Enum.Font.GothamMedium
	selectedLabel.TextSize = 14
	selectedLabel.TextColor3 = primaryText
	selectedLabel.TextXAlignment = Enum.TextXAlignment.Left
	selectedLabel.TextTruncate = Enum.TextTruncate.AtEnd
	selectedLabel.Text = if isMultiSelect then getMultiSelectDisplayText() elseif itemCount > 0 then items[selectedIndex] else ""
	selectedLabel.ZIndex = 10
	selectedLabel.Parent = triggerGlass.GlassSurface

	-- Chevron (right side)
	local chevronLabel = Instance.new("TextLabel")
	chevronLabel.Name = "ChevronLabel"
	chevronLabel.Size = UDim2.new(0, 20, 1, 0)
	chevronLabel.Position = UDim2.new(1, -28, 0, 0)
	chevronLabel.BackgroundTransparency = 1
	chevronLabel.BorderSizePixel = 0
	chevronLabel.Font = Enum.Font.GothamMedium
	chevronLabel.TextSize = 10
	chevronLabel.TextColor3 = secondaryText
	chevronLabel.Text = "v"
	chevronLabel.ZIndex = 10
	chevronLabel.Parent = triggerGlass.GlassSurface

	-- HitArea on trigger
	local triggerHitArea = Instance.new("TextButton")
	triggerHitArea.Name = "HitArea"
	triggerHitArea.Size = UDim2.new(1, 0, 1, 0)
	triggerHitArea.BackgroundTransparency = 1
	triggerHitArea.Text = ""
	triggerHitArea.BorderSizePixel = 0
	triggerHitArea.ZIndex = 100
	triggerHitArea.AutoButtonColor = false
	triggerHitArea.Parent = triggerGlass.GlassSurface

	-- Dropdown panel (below trigger)
	local maxVisibleItems = 5
	local itemHeight = 36
	local panelItemCount = math.min(itemCount, maxVisibleItems)
	local panelHeight = panelItemCount * itemHeight + 8

	local panelGlass = MangoGlassFrame.new({
		Size = UDim2.new(1, 0, 0, panelHeight),
		Position = UDim2.new(0, 0, 0, size.Y.Offset + 4),
		CornerRadius = UDim.new(0, 12),
		BackgroundTransparency = dropdownBgTransparency - 0.05,
		Theme = theme,
		ShadowEnabled = true,
		ShadowLayerCount = 4,
		ShadowSpread = 6,
		ShadowOffsetY = 2,
		LightweightMode = true,
		Parent = container,
	})
	panelGlass.Container.Visible = false
	panelGlass.Container.ZIndex = 50

	-- UIScale for open animation
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
	scrollFrame.ScrollBarThickness = if itemCount > maxVisibleItems then 4 else 0
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, itemCount * itemHeight)
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

	-- Build item list
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

			local itemLabel = Instance.new("TextLabel")
			itemLabel.Name = "ItemLabel"
			itemLabel.Size = UDim2.new(1, -48, 1, 0)
			itemLabel.Position = UDim2.new(0, 12, 0, 0)
			itemLabel.BackgroundTransparency = 1
			itemLabel.BorderSizePixel = 0
			itemLabel.Font = Enum.Font.GothamMedium
			itemLabel.TextSize = 14
			itemLabel.TextColor3 = if i == selectedIndex then primaryText else secondaryText
			itemLabel.TextXAlignment = Enum.TextXAlignment.Left
			itemLabel.TextTruncate = Enum.TextTruncate.AtEnd
			itemLabel.Text = items[i]
			itemLabel.ZIndex = 10
			itemLabel.Parent = itemFrame

			local checkLabel = Instance.new("TextLabel")
			checkLabel.Name = "CheckLabel"
			checkLabel.Size = UDim2.new(0, 20, 1, 0)
			checkLabel.Position = UDim2.new(1, -28, 0, 0)
			checkLabel.BackgroundTransparency = 1
			checkLabel.BorderSizePixel = 0
			checkLabel.Font = Enum.Font.SourceSansBold
			checkLabel.TextSize = 14
			checkLabel.TextColor3 = primaryText
			if isMultiSelect then
				checkLabel.Text = if selectedIndices[i] then "\226\152\145" else "\226\152\144" -- checkbox style
			else
				checkLabel.Text = if i == selectedIndex then "\226\156\147" else "" -- checkmark
			end
			checkLabel.ZIndex = 10
			checkLabel.Parent = itemFrame

			if i < #items then
				local sep = Instance.new("Frame")
				sep.Name = "Separator"
				sep.Size = UDim2.new(1, -24, 0, 1)
				sep.Position = UDim2.new(0, 12, 1, 0)
				sep.BackgroundColor3 = resolve(nil, theme and theme.BackgroundColor3, Color3.fromRGB(230, 230, 235)) :: Color3
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

			-- Hover highlight (tweened — uses separate tween array to avoid cancelling panel tweens)
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

			-- Click
			local clickConn = itemHitArea.MouseButton1Click:Connect(function()
				if isMultiSelect then
					-- Toggle selection for this item
					selectedIndices[i] = not selectedIndices[i] or nil
					selectedLabel.Text = getMultiSelectDisplayText()
					-- Update all checkmarks for multi-select
					for j, f in itemFrames do
						local lbl = f:FindFirstChild("ItemLabel")
						if lbl and lbl:IsA("TextLabel") then
							lbl.TextColor3 = if selectedIndices[j] then primaryText else secondaryText
						end
						local chk = f:FindFirstChild("CheckLabel")
						if chk and chk:IsA("TextLabel") then
							chk.Text = if selectedIndices[j] then "\226\152\145" else "\226\152\144"
						end
					end
					-- Fire multi-select callback
					if config.OnMultiChanged then
						local selected: {string} = {}
						for si, item in items do
							if selectedIndices[si] then
								table.insert(selected, item)
							end
						end
						config.OnMultiChanged(selected)
					end
					-- Don't close dropdown in multi-select mode
				else
					selectedIndex = i
					selectedLabel.Text = items[i]
					-- Update all item label colors and checkmarks
					for j, f in itemFrames do
						local lbl = f:FindFirstChild("ItemLabel")
						if lbl and lbl:IsA("TextLabel") then
							lbl.TextColor3 = if j == i then primaryText else secondaryText
						end
						local chk = f:FindFirstChild("CheckLabel")
						if chk and chk:IsA("TextLabel") then
							chk.Text = if j == i then "\226\156\147" else ""
						end
					end
					closeDropdown()
					if config.OnChanged then
						config.OnChanged(i)
					end
				end
			end)
			table.insert(itemConnections, clickConn)

			table.insert(itemFrames, itemFrame)
		end

		-- Update scroll canvas size
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, #items * itemHeight)
		scrollFrame.ScrollBarThickness = if #items > maxVisibleItems then 4 else 0

		-- Update panel height
		local newPanelItemCount = math.min(#items, maxVisibleItems)
		local newPanelHeight = newPanelItemCount * itemHeight + 8
		panelGlass.Container.Size = UDim2.new(1, 0, 0, newPanelHeight)
	end

	-- Open/Close
	closeDropdown = function()
		if not isOpen then
			return
		end
		isOpen = false
		cancelAllTweens()
		cancelItemHoverTweens()
		destroyClickBlocker()

		-- Reset all item hover highlights
		for _, frame in itemFrames do
			frame.BackgroundTransparency = 1
		end

		-- Stop tracking trigger position
		if positionTrackConn then
			positionTrackConn:Disconnect()
			positionTrackConn = nil
		end

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
			-- Guard against stale handler from rapid open/close/open
			if isDestroyed or isOpen then return end
			panelGlass.Container.Visible = false
			-- Restore panel parent to container
			panelGlass.Container.Parent = container
			panelGlass.Container.Position = UDim2.new(0, 0, 0, size.Y.Offset + 4)
			panelGlass.Container.Size = UDim2.new(1, 0, 0, panelGlass.Container.Size.Y.Offset)
		end)
	end

	local function openDropdown()
		if isOpen then
			return
		end
		isOpen = true
		cancelAllTweens()
		createClickBlocker()

		-- Reparent panel to ScreenGui for proper Z layering
		local screenGui = findScreenGui()
		if screenGui then
			local triggerAbsPos = triggerGlass.Container.AbsolutePosition
			local triggerAbsSize = triggerGlass.Container.AbsoluteSize
			panelGlass.Container.Parent = screenGui
			panelGlass.Container.Position = UDim2.new(0, triggerAbsPos.X, 0, triggerAbsPos.Y + triggerAbsSize.Y + 4)
			panelGlass.Container.Size = UDim2.new(0, triggerAbsSize.X, 0, panelGlass.Container.Size.Y.Offset)

			-- Track trigger position changes so panel follows window drag/scroll
			if positionTrackConn then
				positionTrackConn:Disconnect()
				positionTrackConn = nil
			end
			positionTrackConn = triggerGlass.Container:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
				if not isOpen or isDestroyed then return end
				local newPos = triggerGlass.Container.AbsolutePosition
				local newSize = triggerGlass.Container.AbsoluteSize
				panelGlass.Container.Position = UDim2.new(0, newPos.X, 0, newPos.Y + newSize.Y + 4)
			end)
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

	-- Toggle on trigger click
	local triggerConn = triggerHitArea.MouseButton1Click:Connect(function()
		if isOpen then
			closeDropdown()
		else
			openDropdown()
		end
	end)
	table.insert(connections, triggerConn)

	-- Build initial items
	buildItems()

	-- Parent assignment
	if config.Parent then
		container.Parent = config.Parent
	end

	-- Return table
	local self: Types.MangoDropdown = {
		Container = container,
		SetSelectedIndex = function(self: Types.MangoDropdown, index: number)
			if index >= 1 and index <= #items then
				selectedIndex = index
				selectedLabel.Text = items[index]
			end
		end,
		GetSelectedIndex = function(self: Types.MangoDropdown): number
			return selectedIndex
		end,
		SetItems = function(self: Types.MangoDropdown, newItems: {string})
			if isOpen then
				closeDropdown()
			end
			items = table.clone(newItems)
			selectedIndex = math.clamp(selectedIndex, 1, math.max(#items, 1))
			if isMultiSelect then
				-- Clear selections that no longer exist
				local newIndices: {[number]: boolean} = {}
				for si, _ in selectedIndices do
					if si <= #items then
						newIndices[si] = true
					end
				end
				selectedIndices = newIndices
				selectedLabel.Text = getMultiSelectDisplayText()
			else
				selectedLabel.Text = if #items > 0 then items[selectedIndex] else ""
			end
			buildItems()
		end,
		GetSelectedItems = function(self: Types.MangoDropdown): {string}
			if not isMultiSelect then return {items[selectedIndex]} end
			local result: {string} = {}
			for i, item in items do
				if selectedIndices[i] then
					table.insert(result, item)
				end
			end
			return result
		end,
		Open = function(self: Types.MangoDropdown)
			openDropdown()
		end,
		Close = function(self: Types.MangoDropdown)
			closeDropdown()
		end,
		Destroy = function(self: Types.MangoDropdown)
			if isDestroyed then return end
			-- Close panel first to clean up ScreenGui-level elements
			if isOpen then
				isOpen = false
				destroyClickBlocker()
			end
			isDestroyed = true
			cancelAllTweens()
			cancelItemHoverTweens()
			clearItemConnections()
			if positionTrackConn then
				positionTrackConn:Disconnect()
				positionTrackConn = nil
			end
			for _, conn in connections do
				conn:Disconnect()
			end
			table.clear(connections)
			triggerGlass:Destroy()
			panelGlass:Destroy()
			container:Destroy()
		end,
	}

	return self
end

return module
