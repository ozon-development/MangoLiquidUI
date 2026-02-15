--!strict

local Types = require(script.Parent.Types)
local Themes = require(script.Parent.Themes)
local MangoGlassFrame = require(script.Parent.MangoGlassFrame)
local resolve = Themes.resolve
local MangoProtection = require(script.Parent.MangoProtection)
local TweenService = game:GetService("TweenService")

local module = {}

function module.new(config: Types.MangoTabBarConfig): Types.MangoTabBar
	local theme = config.Theme
	local tabs = resolve(config.Tabs, nil, {{Label = "Tab"}}) :: {{Icon: string?, Label: string}}
	local tabCount = #tabs

	-- Resolve config values
	local initialIndex = resolve(config.InitialIndex, nil, 1) :: number

	-- Theme values
	local bgTransparency = resolve(nil, theme and theme.TabBarBackgroundTransparency, 0.82) :: number
	local selectedColor = resolve(nil, theme and theme.TabBarSelectedColor, Color3.fromRGB(0, 122, 255)) :: Color3
	local iconColor = resolve(nil, theme and theme.TabBarIconColor, Color3.fromRGB(140, 140, 150)) :: Color3
	local iconSelectedColor = resolve(nil, theme and theme.TabBarIconSelectedColor, Color3.fromRGB(0, 122, 255)) :: Color3
	local secondaryText = resolve(nil, theme and theme.SecondaryTextColor, Color3.fromRGB(60, 60, 70)) :: Color3

	-- State
	local currentIndex: number = math.clamp(initialIndex, 1, tabCount)
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

	-- Container (full width, 54px tall, anchored to bottom)
	local container = Instance.new("Frame")
	container.Name = MangoProtection.randomName("TabBar")
	container.Size = UDim2.new(1, 0, 0, 54)
	container.Position = UDim2.new(0, 0, 1, 0)
	container.AnchorPoint = Vector2.new(0, 1)
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0

	-- MangoGlassFrame (full tab bar background)
	local glassFrame = MangoGlassFrame.new({
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		CornerRadius = UDim.new(0, 0),
		BackgroundTransparency = bgTransparency,
		Theme = theme,
		ShadowEnabled = true,
		ShadowLayerCount = 2,
		ShadowSpread = 6,
		ShadowOffsetY = -2,
		LightweightMode = true,
		Parent = container,
	})

	-- Layout inside GlassSurface
	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tabLayout.Padding = UDim.new(0, 0)
	tabLayout.Parent = glassFrame.GlassSurface

	-- Tab items
	local tabFrames: {Frame} = {}
	local iconLabels: {TextLabel} = {}
	local textLabels: {TextLabel} = {}
	local dotFrames: {Frame} = {}

	for i = 1, tabCount do
		local tab = tabs[i]
		local hasIcon = tab.Icon ~= nil and tab.Icon ~= ""
		local isSelected = i == currentIndex

		local tabFrame = Instance.new("Frame")
		tabFrame.Name = "Tab" .. i
		tabFrame.Size = UDim2.new(1 / tabCount, 0, 1, 0)
		tabFrame.BackgroundTransparency = 1
		tabFrame.BorderSizePixel = 0
		tabFrame.LayoutOrder = i
		tabFrame.Parent = glassFrame.GlassSurface

		-- Icon (if provided)
		local iconLabel = Instance.new("TextLabel")
		iconLabel.Name = "IconLabel"
		iconLabel.Size = UDim2.new(1, 0, 0, 24)
		iconLabel.Position = UDim2.new(0, 0, 0, 4)
		iconLabel.BackgroundTransparency = 1
		iconLabel.BorderSizePixel = 0
		iconLabel.Font = Enum.Font.Gotham
		iconLabel.TextSize = 20
		iconLabel.Text = if hasIcon then (tab.Icon :: string) else ""
		iconLabel.TextColor3 = if isSelected then iconSelectedColor else iconColor
		iconLabel.TextXAlignment = Enum.TextXAlignment.Center
		iconLabel.TextYAlignment = Enum.TextYAlignment.Center
		iconLabel.Visible = hasIcon
		iconLabel.ZIndex = 5
		iconLabel.Parent = tabFrame

		-- Tab label
		local textLabel = Instance.new("TextLabel")
		textLabel.Name = "TabLabel"
		textLabel.Size = UDim2.new(1, 0, 0, 14)
		textLabel.Position = if hasIcon then UDim2.new(0, 0, 0, 28) else UDim2.new(0, 0, 0.5, -7)
		textLabel.BackgroundTransparency = 1
		textLabel.BorderSizePixel = 0
		textLabel.Font = Enum.Font.GothamMedium
		textLabel.TextSize = 11
		textLabel.Text = tab.Label
		textLabel.TextColor3 = if isSelected then selectedColor else secondaryText
		textLabel.TextXAlignment = Enum.TextXAlignment.Center
		textLabel.TextYAlignment = Enum.TextYAlignment.Center
		textLabel.ZIndex = 5
		textLabel.Parent = tabFrame

		-- Selected dot
		local dot = Instance.new("Frame")
		dot.Name = "SelectedDot"
		dot.Size = UDim2.new(0, 4, 0, 4)
		dot.AnchorPoint = Vector2.new(0.5, 0)
		dot.Position = if hasIcon then UDim2.new(0.5, 0, 0, 44) else UDim2.new(0.5, 0, 0, 38)
		dot.BackgroundColor3 = selectedColor
		dot.BackgroundTransparency = 0
		dot.BorderSizePixel = 0
		dot.Visible = isSelected
		dot.ZIndex = 5
		dot.Parent = tabFrame

		local dotCorner = Instance.new("UICorner")
		dotCorner.CornerRadius = UDim.new(0, 999)
		dotCorner.Parent = dot

		-- HitArea
		local hitArea = Instance.new("TextButton")
		hitArea.Name = "HitArea"
		hitArea.Size = UDim2.new(1, 0, 1, 0)
		hitArea.BackgroundTransparency = 1
		hitArea.Text = ""
		hitArea.BorderSizePixel = 0
		hitArea.ZIndex = 100
		hitArea.AutoButtonColor = false
		hitArea.Parent = tabFrame

		table.insert(tabFrames, tabFrame)
		table.insert(iconLabels, iconLabel)
		table.insert(textLabels, textLabel)
		table.insert(dotFrames, dot)
	end

	-- Selection logic
	local function selectIndex(index: number)
		if index < 1 or index > tabCount then
			return
		end
		cancelAllTweens()
		currentIndex = index

		local colorInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

		for i = 1, tabCount do
			local isSelected = i == index

			-- Animate icon color
			local iconTween = TweenService:Create(iconLabels[i], colorInfo, {
				TextColor3 = if isSelected then iconSelectedColor else iconColor,
			})
			trackTween(iconTween)
			iconTween:Play()

			-- Animate text color
			local textTween = TweenService:Create(textLabels[i], colorInfo, {
				TextColor3 = if isSelected then selectedColor else secondaryText,
			})
			trackTween(textTween)
			textTween:Play()

			-- Show/hide dot
			dotFrames[i].Visible = isSelected
		end
	end

	-- Wire click handlers
	for i = 1, tabCount do
		local hitArea = tabFrames[i]:FindFirstChild("HitArea") :: TextButton
		local conn = hitArea.MouseButton1Click:Connect(function()
			if currentIndex ~= i then
				selectIndex(i)
				if config.OnChanged then
					config.OnChanged(i)
				end
			end
		end)
		table.insert(connections, conn)
	end

	-- Parent assignment
	if config.Parent then
		container.Parent = config.Parent
	end

	-- Return table
	local self: Types.MangoTabBar = {
		Container = container,
		SetIndex = function(self: Types.MangoTabBar, index: number)
			selectIndex(index)
		end,
		GetIndex = function(self: Types.MangoTabBar): number
			return currentIndex
		end,
		Destroy = function(self: Types.MangoTabBar)
			cancelAllTweens()
			for _, conn in connections do
				conn:Disconnect()
			end
			table.clear(connections)
			glassFrame:Destroy()
			container:Destroy()
		end,
	}

	return self
end

return module
