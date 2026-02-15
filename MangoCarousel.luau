--!strict

local Types = require(script.Parent.Types)
local Themes = require(script.Parent.Themes)
local MangoGlassFrame = require(script.Parent.MangoGlassFrame)
local resolve = Themes.resolve
local MangoProtection = require(script.Parent.MangoProtection)
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local module = {}

-- Default accent colors for tabs (cycles if more tabs than colors)
local DEFAULT_COLORS: {Color3} = {
	Color3.fromRGB(90, 135, 230),  -- soft blue
	Color3.fromRGB(175, 100, 220), -- soft purple
	Color3.fromRGB(230, 140, 70),  -- warm orange
	Color3.fromRGB(80, 185, 140),  -- soft green
}

local function lightenColor(c: Color3, amount: number): Color3
	return Color3.new(math.min(c.R + amount, 1), math.min(c.G + amount, 1), math.min(c.B + amount, 1))
end

local function darkenColor(c: Color3, amount: number): Color3
	return Color3.new(math.max(c.R - amount, 0), math.max(c.G - amount, 0), math.max(c.B - amount, 0))
end

function module.new(config: Types.MangoCarouselConfig): Types.MangoCarousel
	local theme = config.Theme
	local tabs = config.Tabs
	local tabCount = #tabs

	-- Resolve config values
	local ICON_SIZE = resolve(config.IconSize, nil, 44) :: number
	local ICON_GAP = 10
	local ICON_STEP = ICON_SIZE + ICON_GAP
	local DOCK_WIDTH = ICON_SIZE + 20
	local VIEWPORT_HEIGHT = 3 * ICON_STEP + ICON_SIZE

	local initialIndex = resolve(config.InitialIndex, nil, 1) :: number
	local position = resolve(config.Position, nil, UDim2.new(0, 8, 1, -62)) :: UDim2
	local anchorPoint = resolve(config.AnchorPoint, nil, Vector2.new(0, 1)) :: Vector2
	local dockSize = resolve(config.Size, nil, UDim2.new(0, DOCK_WIDTH, 0, VIEWPORT_HEIGHT)) :: UDim2

	-- Theme values
	local strokeColor = resolve(nil, theme and theme.StrokeColor, Color3.fromRGB(255, 255, 255)) :: Color3
	local fresnelStart = resolve(nil, theme and theme.FresnelStartTransparency, 0.35) :: number
	local fresnelMid = resolve(nil, theme and theme.FresnelMidTransparency, 0.65) :: number
	local fresnelMidPoint = resolve(nil, theme and theme.FresnelMidPoint, 0.40) :: number
	local fresnelEnd = resolve(nil, theme and theme.FresnelEndTransparency, 0.95) :: number

	-- State
	local currentIndex: number = math.clamp(initialIndex, 1, tabCount)
	local scrollGen: number = 0
	local activeTweens: {Tween} = {}
	local connections: {RBXScriptConnection} = {}
	local isDestroyed = false
	local isTweening = false

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

	-- Get accent color for a tab index
	local function getTabColor(index: number): Color3
		local tabConfig = tabs[index]
		if tabConfig.Color then
			return tabConfig.Color
		end
		return DEFAULT_COLORS[((index - 1) % #DEFAULT_COLORS) + 1]
	end

	-- Compute the Y offset for the track to center a given tab index
	local function getIconCenterOffset(tabIdx: number): number
		local centerY = VIEWPORT_HEIGHT / 2
		local iconCenterY = (tabIdx - 1) * ICON_STEP + ICON_SIZE / 2
		return centerY - iconCenterY
	end

	-- ============================================================
	-- Instance Hierarchy
	-- ============================================================

	-- Container (transparent outer wrapper)
	local container = Instance.new("Frame")
	container.Name = MangoProtection.randomName("Carousel")
	container.Size = dockSize
	container.Position = position
	container.AnchorPoint = anchorPoint
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0

	-- DockGlass (MangoGlassFrame backdrop, pill shape)
	local dockGlass = MangoGlassFrame.new({
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		CornerRadius = UDim.new(0, math.floor(DOCK_WIDTH / 2)),
		BackgroundTransparency = 0.75,
		Theme = theme,
		ShadowEnabled = true,
		ShadowLayerCount = 3,
		ShadowSpread = 6,
		ShadowOffsetY = 2,
		LightweightMode = true,
		Parent = container,
	})

	-- ClipFrame (clips the scrolling track, inside GlassSurface)
	local edgePad = 14
	local clipFrame = Instance.new("Frame")
	clipFrame.Name = "ClipFrame"
	clipFrame.Size = UDim2.new(1, 0, 1, -edgePad * 2)
	clipFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	clipFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	clipFrame.BackgroundTransparency = 1
	clipFrame.BorderSizePixel = 0
	clipFrame.ClipsDescendants = true
	clipFrame.Parent = dockGlass.GlassSurface

	-- TrackFrame (holds all icons, moves vertically via tween)
	local trackFrame = Instance.new("Frame")
	trackFrame.Name = "TrackFrame"
	trackFrame.Size = UDim2.new(1, 0, 0, tabCount * ICON_STEP)
	trackFrame.Position = UDim2.new(0, 0, 0, getIconCenterOffset(currentIndex))
	trackFrame.BackgroundTransparency = 1
	trackFrame.BorderSizePixel = 0
	trackFrame.Parent = clipFrame

	-- Icon data arrays
	local iconFrames: {Frame} = {}
	local iconScales: {UIScale} = {}
	local iconDotScales: {UIScale} = {}
	local iconHoverStates: {boolean} = {}

	-- Build icon instances (no event wiring yet — forward-declared functions needed)
	for i = 1, tabCount do
		local tabConfig = tabs[i]
		local accent = getTabColor(i)
		local isSelected = i == currentIndex

		-- Icon_N frame
		local iconFrame = Instance.new("Frame")
		iconFrame.Name = "Icon_" .. i
		iconFrame.Size = UDim2.new(0, ICON_SIZE, 0, ICON_SIZE)
		iconFrame.AnchorPoint = Vector2.new(0.5, 0)
		iconFrame.Position = UDim2.new(0.5, 0, 0, (i - 1) * ICON_STEP)
		iconFrame.BackgroundTransparency = 1
		iconFrame.BorderSizePixel = 0
		iconFrame.Parent = trackFrame

		-- UIScale for paraboloid focus + hover
		local iconScale = Instance.new("UIScale")
		iconScale.Scale = 1
		iconScale.Parent = iconFrame

		-- IconShadow (accent-tinted drop shadow)
		local iconShadow = Instance.new("Frame")
		iconShadow.Name = "IconShadow"
		iconShadow.Size = UDim2.new(0, ICON_SIZE + 6, 0, ICON_SIZE + 6)
		iconShadow.AnchorPoint = Vector2.new(0.5, 0.5)
		iconShadow.Position = UDim2.new(0.5, 0, 0.5, 2)
		iconShadow.BackgroundColor3 = accent
		iconShadow.BackgroundTransparency = 0.84
		iconShadow.BorderSizePixel = 0
		iconShadow.ZIndex = 0
		iconShadow.Parent = iconFrame

		local shadowCorner = Instance.new("UICorner")
		shadowCorner.CornerRadius = UDim.new(0, 14)
		shadowCorner.Parent = iconShadow

		-- IconBg (squircle, gradient fill)
		local iconBg = Instance.new("Frame")
		iconBg.Name = "IconBg"
		iconBg.Size = UDim2.new(0, ICON_SIZE, 0, ICON_SIZE)
		iconBg.AnchorPoint = Vector2.new(0.5, 0.5)
		iconBg.Position = UDim2.new(0.5, 0, 0.5, 0)
		iconBg.BackgroundColor3 = accent
		iconBg.BackgroundTransparency = 0.40
		iconBg.BorderSizePixel = 0
		iconBg.ZIndex = 1
		iconBg.Parent = iconFrame

		local bgCorner = Instance.new("UICorner")
		bgCorner.CornerRadius = UDim.new(0, 12)
		bgCorner.Parent = iconBg

		-- Gradient fill (lighten top, darken bottom)
		local bgGradient = Instance.new("UIGradient")
		bgGradient.Name = "IconBgGradient"
		bgGradient.Rotation = 135
		bgGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, lightenColor(accent, 0.15)),
			ColorSequenceKeypoint.new(1, darkenColor(accent, 0.08)),
		})
		bgGradient.Parent = iconBg

		-- IconHighlight (white inner glow, 35% height)
		local iconHighlight = Instance.new("Frame")
		iconHighlight.Name = "IconHighlight"
		iconHighlight.Size = UDim2.new(1, 0, 0.35, 0)
		iconHighlight.Position = UDim2.new(0, 0, 0, 0)
		iconHighlight.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		iconHighlight.BackgroundTransparency = 0.78
		iconHighlight.BorderSizePixel = 0
		iconHighlight.ZIndex = 2
		iconHighlight.Parent = iconBg

		local highlightCorner = Instance.new("UICorner")
		highlightCorner.CornerRadius = UDim.new(0, 12)
		highlightCorner.Parent = iconHighlight

		local highlightGradient = Instance.new("UIGradient")
		highlightGradient.Name = "HighlightGradient"
		highlightGradient.Rotation = 90
		highlightGradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		})
		highlightGradient.Parent = iconHighlight

		-- Inner edge stroke (glass-like inner shadow via Border mode inside iconBg)
		local innerEdgeFrame = Instance.new("Frame")
		innerEdgeFrame.Name = "InnerEdgeFrame"
		innerEdgeFrame.Size = UDim2.new(1, 0, 1, 0)
		innerEdgeFrame.BackgroundTransparency = 1
		innerEdgeFrame.BorderSizePixel = 0
		innerEdgeFrame.ZIndex = 2
		innerEdgeFrame.Parent = iconBg

		local innerEdgeCorner = Instance.new("UICorner")
		innerEdgeCorner.CornerRadius = UDim.new(0, 12)
		innerEdgeCorner.Parent = innerEdgeFrame

		local innerEdgeStroke = Instance.new("UIStroke")
		innerEdgeStroke.Name = "InnerEdgeStroke"
		innerEdgeStroke.Color = Color3.fromRGB(255, 255, 255)
		innerEdgeStroke.Thickness = 1
		innerEdgeStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		innerEdgeStroke.Parent = innerEdgeFrame

		local innerEdgeGradient = Instance.new("UIGradient")
		innerEdgeGradient.Name = "InnerEdgeGradient"
		innerEdgeGradient.Rotation = 90
		innerEdgeGradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.55),
			NumberSequenceKeypoint.new(0.5, 0.82),
			NumberSequenceKeypoint.new(1, 0.95),
		})
		innerEdgeGradient.Parent = innerEdgeStroke

		-- Specular stroke on icon (fresnel rim)
		local specFrame = Instance.new("Frame")
		specFrame.Name = "SpecularFrame"
		specFrame.Size = UDim2.new(1, 0, 1, 0)
		specFrame.BackgroundTransparency = 1
		specFrame.BorderSizePixel = 0
		specFrame.ZIndex = 3
		specFrame.Parent = iconBg

		local specCorner = Instance.new("UICorner")
		specCorner.CornerRadius = UDim.new(0, 12)
		specCorner.Parent = specFrame

		local specStroke = Instance.new("UIStroke")
		specStroke.Name = "SpecularStroke"
		specStroke.Color = strokeColor
		specStroke.Thickness = 1
		specStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		specStroke.Parent = specFrame

		local specGradient = Instance.new("UIGradient")
		specGradient.Name = "SpecularGradient"
		specGradient.Rotation = 90
		specGradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, fresnelStart + 0.10),
			NumberSequenceKeypoint.new(fresnelMidPoint, fresnelMid + 0.05),
			NumberSequenceKeypoint.new(1, fresnelEnd),
		})
		specGradient.Parent = specStroke

		-- IconLabel (emoji or text)
		local iconLabel = Instance.new("TextLabel")
		iconLabel.Name = "IconLabel"
		iconLabel.Size = UDim2.new(1, 0, 1, 0)
		iconLabel.BackgroundTransparency = 1
		iconLabel.BorderSizePixel = 0
		iconLabel.Font = Enum.Font.GothamBold
		iconLabel.TextSize = 16
		-- Truncate label to first 2 chars when used as icon fallback (prevents text overflow in small icon)
		local iconText = tabConfig.Icon
		if not iconText or iconText == "" then
			local lbl = tabConfig.Label or ""
			iconText = string.sub(lbl, 1, 2)
		end
		iconLabel.Text = iconText
		iconLabel.TextScaled = true
		iconLabel.TextTruncate = Enum.TextTruncate.AtEnd
		iconLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		iconLabel.TextStrokeTransparency = 0.80
		iconLabel.TextXAlignment = Enum.TextXAlignment.Center
		iconLabel.TextYAlignment = Enum.TextYAlignment.Center
		iconLabel.ZIndex = 5
		iconLabel.Parent = iconFrame

		-- ActiveDot (6x6 circle below icon, accent-colored)
		local activeDot = Instance.new("Frame")
		activeDot.Name = "ActiveDot"
		activeDot.Size = UDim2.new(0, 6, 0, 6)
		activeDot.AnchorPoint = Vector2.new(0.5, 0)
		activeDot.Position = UDim2.new(0.5, 0, 1, 3)
		activeDot.BackgroundColor3 = accent
		activeDot.BackgroundTransparency = 0
		activeDot.BorderSizePixel = 0
		activeDot.ZIndex = 5
		activeDot.Parent = iconFrame

		local dotCorner = Instance.new("UICorner")
		dotCorner.CornerRadius = UDim.new(0, 999)
		dotCorner.Parent = activeDot

		local dotScale = Instance.new("UIScale")
		dotScale.Scale = if isSelected then 1 else 0
		dotScale.Parent = activeDot

		-- HitArea (TextButton for reliable input)
		local hitArea = Instance.new("TextButton")
		hitArea.Name = "HitArea"
		hitArea.Size = UDim2.new(1, 0, 1, 0)
		hitArea.BackgroundTransparency = 1
		hitArea.Text = ""
		hitArea.BorderSizePixel = 0
		hitArea.ZIndex = 100
		hitArea.AutoButtonColor = false
		hitArea.Parent = iconFrame

		-- Store references
		table.insert(iconFrames, iconFrame)
		table.insert(iconScales, iconScale)
		table.insert(iconDotScales, dotScale)
		table.insert(iconHoverStates, false)
	end

	-- ============================================================
	-- Active Dot Animation
	-- ============================================================

	local function updateDots(selectedIndex: number)
		local dotInInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		local dotOutInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		for i = 1, tabCount do
			local targetScale = if i == selectedIndex then 1 else 0
			local info = if i == selectedIndex then dotInInfo else dotOutInfo
			trackTween(TweenService:Create(iconDotScales[i], info, {
				Scale = targetScale,
			})):Play()
		end
	end

	-- ============================================================
	-- Paraboloid Focus
	-- ============================================================

	local function applyParaboloidFocus()
		if isDestroyed then return end
		local trackY = trackFrame.Position.Y.Offset
		local centerViewY = VIEWPORT_HEIGHT / 2

		local focusInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		for i = 1, tabCount do
			if not iconHoverStates[i] then
				local iconCenterY = trackY + (i - 1) * ICON_STEP + ICON_SIZE / 2
				local distance = math.abs(iconCenterY - centerViewY)
				local t = distance / ICON_STEP
				local focusScale = math.max(0.50, 1.0 - t * t)
				trackTween(TweenService:Create(iconScales[i], focusInfo, {
					Scale = focusScale,
				})):Play()
			end
		end
	end

	-- ============================================================
	-- Scroll Logic (Infinite Loop Wrapping)
	-- ============================================================

	local function scrollToIndex(newIndex: number)
		if isDestroyed then return end
		cancelAllTweens()
		scrollGen += 1
		local gen = scrollGen

		-- Wrap index with modular arithmetic
		newIndex = ((newIndex - 1) % tabCount) + 1
		local oldIndex = currentIndex
		currentIndex = newIndex

		-- Compute shortest wrap distance for variable duration
		local rawDelta = math.abs(newIndex - oldIndex)
		local scrollDelta = math.min(rawDelta, tabCount - rawDelta)
		local duration = 0.22 + scrollDelta * 0.03

		local targetY = getIconCenterOffset(newIndex)

		local scrollInfo = TweenInfo.new(duration, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		local scrollTween = TweenService:Create(trackFrame, scrollInfo, {
			Position = UDim2.new(0, 0, 0, targetY),
		})
		trackTween(scrollTween)
		isTweening = true
		scrollTween:Play()

		scrollTween.Completed:Connect(function()
			if isDestroyed then return end
			if gen == scrollGen then
				isTweening = false
			end
		end)

		updateDots(newIndex)

		if config.OnChanged then
			config.OnChanged(newIndex)
		end
	end

	-- ============================================================
	-- Wire Event Handlers (after all functions are defined)
	-- ============================================================

	for i = 1, tabCount do
		local iconFrame = iconFrames[i]
		local iconScale = iconScales[i]
		local hitArea = iconFrame:FindFirstChild("HitArea") :: TextButton

		-- Click handler
		local clickConn = hitArea.MouseButton1Click:Connect(function()
			if isDestroyed then return end
			if currentIndex ~= i then
				scrollToIndex(i)
			end
		end)
		table.insert(connections, clickConn)

		-- Hover feedback (1.04x, 0.2s Back Out)
		local hoverConn = hitArea.MouseEnter:Connect(function()
			if isDestroyed then return end
			iconHoverStates[i] = true
			local hoverInfo = TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			trackTween(TweenService:Create(iconScale, hoverInfo, { Scale = 1.04 })):Play()
		end)
		table.insert(connections, hoverConn)

		local leaveConn = hitArea.MouseLeave:Connect(function()
			if isDestroyed then return end
			iconHoverStates[i] = false
			applyParaboloidFocus()
		end)
		table.insert(connections, leaveConn)

		-- Press feedback (0.92x, 0.1s Quad Out)
		local pressConn = hitArea.MouseButton1Down:Connect(function()
			if isDestroyed then return end
			local pressInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			trackTween(TweenService:Create(iconScale, pressInfo, { Scale = 0.92 })):Play()
		end)
		table.insert(connections, pressConn)

		local releaseConn = hitArea.MouseButton1Up:Connect(function()
			if isDestroyed then return end
			if iconHoverStates[i] then
				local hoverInfo = TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
				trackTween(TweenService:Create(iconScale, hoverInfo, { Scale = 1.04 })):Play()
			else
				applyParaboloidFocus()
			end
		end)
		table.insert(connections, releaseConn)
	end

	-- ============================================================
	-- Mouse Wheel Input
	-- ============================================================

	local scrollConn = UserInputService.InputChanged:Connect(function(input: InputObject)
		if isDestroyed then return end
		if input.UserInputType ~= Enum.UserInputType.MouseWheel then return end

		-- Check if mouse is over dock bounds
		local mousePos = UserInputService:GetMouseLocation()
		local absPos = container.AbsolutePosition
		local absSize = container.AbsoluteSize
		if mousePos.X < absPos.X or mousePos.X > absPos.X + absSize.X then return end
		if mousePos.Y < absPos.Y or mousePos.Y > absPos.Y + absSize.Y then return end

		-- Scroll direction: negative Z = scroll down = next tab
		local direction = if input.Position.Z < 0 then 1 else -1
		scrollToIndex(currentIndex + direction)
	end)
	table.insert(connections, scrollConn)

	-- ============================================================
	-- Touch Swipe Support
	-- ============================================================

	local touchStartY: number? = nil

	local touchBeganConn = UserInputService.InputBegan:Connect(function(input: InputObject)
		if isDestroyed then return end
		if input.UserInputType ~= Enum.UserInputType.Touch then return end

		-- Check if touch is over dock bounds
		local absPos = container.AbsolutePosition
		local absSize = container.AbsoluteSize
		local touchX = input.Position.X
		local touchY = input.Position.Y
		if touchX < absPos.X or touchX > absPos.X + absSize.X then return end
		if touchY < absPos.Y or touchY > absPos.Y + absSize.Y then return end

		touchStartY = touchY
	end)
	table.insert(connections, touchBeganConn)

	local touchEndedConn = UserInputService.InputEnded:Connect(function(input: InputObject)
		if isDestroyed then return end
		if input.UserInputType ~= Enum.UserInputType.Touch then return end
		if touchStartY == nil then return end

		local deltaY = input.Position.Y - (touchStartY :: number)
		touchStartY = nil

		-- Y delta > 20px threshold for swipe detection
		if math.abs(deltaY) > 20 then
			local direction = if deltaY < 0 then 1 else -1
			scrollToIndex(currentIndex + direction)
		end
	end)
	table.insert(connections, touchEndedConn)

	-- ============================================================
	-- Per-Frame Focus Update (RenderStepped)
	-- ============================================================

	local renderConn = RunService.RenderStepped:Connect(function()
		if isDestroyed then return end
		if isTweening then
			applyParaboloidFocus()
		end
	end)
	table.insert(connections, renderConn)

	-- Apply initial state
	applyParaboloidFocus()
	updateDots(currentIndex)

	-- ============================================================
	-- Parent Assignment
	-- ============================================================

	if config.Parent then
		container.Parent = config.Parent
	end

	-- ============================================================
	-- Return Table
	-- ============================================================

	local self: Types.MangoCarousel = {
		Container = container,
		SetIndex = function(self: Types.MangoCarousel, index: number)
			scrollToIndex(index)
		end,
		GetIndex = function(self: Types.MangoCarousel): number
			return currentIndex
		end,
		Destroy = function(self: Types.MangoCarousel)
			isDestroyed = true
			cancelAllTweens()
			for _, conn in connections do
				conn:Disconnect()
			end
			table.clear(connections)
			dockGlass:Destroy()
			container:Destroy()
		end,
	}

	return self
end

return module
