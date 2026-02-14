--!strict

local Types = require(script.Parent.Types)
local Themes = require(script.Parent.Themes)
local MangoGlassFrame = require(script.Parent.MangoGlassFrame)
local MangoProtection = require(script.Parent.MangoProtection)
local resolve = Themes.resolve
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")

local module = {}

function module.new(config: Types.MangoToastConfig): Types.MangoToast
	local theme = config.Theme
	local text = config.Text
	local icon = config.Icon
	local duration = resolve(config.Duration, nil, 3) :: number

	-- Theme-driven properties
	local bgTransparency = resolve(nil, theme and theme.ToastBackgroundTransparency, 0.20) :: number
	local textColor = resolve(nil, theme and theme.PrimaryTextColor, Color3.fromRGB(0, 0, 0)) :: Color3

	-- Measure text
	local font = Enum.Font.GothamMedium
	local fontSize = 14
	local hasIcon = icon ~= nil and icon ~= ""
	local iconSpace = if hasIcon then 28 else 0 -- 20px icon + 8px gap
	local textBounds = TextService:GetTextSize(text, fontSize, font, Vector2.new(400, 48))
	local toastWidth = math.clamp(textBounds.X + 32 + iconSpace, 80, 400) -- 16px padding each side
	local toastHeight = math.clamp(textBounds.Y + 20, 36, 48) -- 10px padding top/bottom, clamp 36-48

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

	-- Determine parent
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

	-- Toast container (anchored bottom-center, starts offscreen below)
	local toastContainer = Instance.new("Frame")
	toastContainer.Name = MangoProtection.randomName("Toast")
	toastContainer.Size = UDim2.new(0, toastWidth, 0, toastHeight)
	toastContainer.AnchorPoint = Vector2.new(0.5, 1)
	toastContainer.Position = UDim2.new(0.5, 0, 1, 60) -- offscreen below
	toastContainer.BackgroundTransparency = 1
	toastContainer.BorderSizePixel = 0
	toastContainer.Parent = parentInstance

	-- Glass frame (pill shape)
	local glassFrame = MangoGlassFrame.new({
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		CornerRadius = UDim.new(0, 999),
		BackgroundTransparency = bgTransparency,
		Theme = theme,
		ShadowEnabled = true,
		ShadowLayerCount = 2,
		ShadowSpread = 6,
		ShadowOffsetY = 2,
		LightweightMode = true,
		Parent = toastContainer,
	})

	-- Store target transparency for fade-in
	local targetBgTransparency = glassFrame.GlassSurface.BackgroundTransparency

	-- UIPadding on GlassSurface
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 16)
	padding.PaddingRight = UDim.new(0, 16)
	padding.PaddingTop = UDim.new(0, 0)
	padding.PaddingBottom = UDim.new(0, 0)
	padding.Parent = glassFrame.GlassSurface

	-- Horizontal layout
	local hLayout = Instance.new("UIListLayout")
	hLayout.FillDirection = Enum.FillDirection.Horizontal
	hLayout.Padding = UDim.new(0, 8)
	hLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	hLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	hLayout.SortOrder = Enum.SortOrder.LayoutOrder
	hLayout.Parent = glassFrame.GlassSurface

	-- Icon (optional)
	if hasIcon then
		local iconLabel = Instance.new("TextLabel")
		iconLabel.Name = "IconLabel"
		iconLabel.Text = icon :: string
		iconLabel.Font = Enum.Font.GothamBold
		iconLabel.TextSize = 16
		iconLabel.TextColor3 = textColor
		iconLabel.BackgroundTransparency = 1
		iconLabel.BorderSizePixel = 0
		iconLabel.Size = UDim2.new(0, 20, 0, 20)
		iconLabel.LayoutOrder = 1
		iconLabel.ZIndex = 10
		iconLabel.Parent = glassFrame.GlassSurface
	end

	-- Text label
	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "ToastText"
	textLabel.Text = text
	textLabel.Font = font
	textLabel.TextSize = fontSize
	textLabel.TextColor3 = textColor
	textLabel.BackgroundTransparency = 1
	textLabel.BorderSizePixel = 0
	textLabel.Size = UDim2.new(0, textBounds.X, 1, 0)
	textLabel.TextXAlignment = Enum.TextXAlignment.Center
	textLabel.TextYAlignment = Enum.TextYAlignment.Center
	textLabel.LayoutOrder = 2
	textLabel.ZIndex = 10
	textLabel.Parent = glassFrame.GlassSurface

	-- DismissHitArea (tap-to-dismiss)
	local dismissHitArea = Instance.new("TextButton")
	dismissHitArea.Name = "DismissHitArea"
	dismissHitArea.Size = UDim2.new(1, 0, 1, 0)
	dismissHitArea.BackgroundTransparency = 1
	dismissHitArea.BorderSizePixel = 0
	dismissHitArea.Text = ""
	dismissHitArea.AutoButtonColor = false
	dismissHitArea.ZIndex = 50
	dismissHitArea.Parent = toastContainer

	-- Forward-declared dismiss for tap handler
	local dismiss: () -> ()

	-- Tap to dismiss
	local tapConn = dismissHitArea.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			if isShowing and not isDismissing then
				dismiss()
			end
		end
	end)
	table.insert(connections, tapConn)

	-- Dismiss implementation
	dismiss = function()
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
		local slideTween = TweenService:Create(toastContainer, tweenOut, {
			Position = UDim2.new(0.5, 0, 1, 60),
		})
		trackTween(slideTween)
		slideTween:Play()
		slideTween.Completed:Connect(function()
			if not isDestroyed then
				isDestroyed = true
				if config.OnDismissed then
					config.OnDismissed()
				end
				-- Auto-destroy after dismiss
				for _, conn in connections do
					conn:Disconnect()
				end
				table.clear(connections)
				glassFrame:Destroy()
				toastContainer:Destroy()
				if screenGui then
					screenGui:Destroy()
				end
			end
		end)
	end

	-- Return table
	local self: Types.MangoToast = {
		Container = toastContainer,
		Show = function(self: Types.MangoToast)
			if isShowing or isDestroyed then
				return
			end
			isShowing = true

			-- Start with glass surface fully transparent for fade-in
			glassFrame.GlassSurface.BackgroundTransparency = 1

			-- Slide up into view
			cancelAllTweens()
			local springInfo = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			local slideTween = TweenService:Create(toastContainer, springInfo, {
				Position = UDim2.new(0.5, 0, 1, -16),
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
					dismissThread = nil
					if not isDismissing and not isDestroyed and isShowing then
						dismiss()
					end
				end)
			end
		end,
		Dismiss = function(self: Types.MangoToast)
			dismiss()
		end,
		SetPosition = function(self: Types.MangoToast, position: UDim2)
			if isDestroyed then
				return
			end
			cancelPositionTweens()
			local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			local posTween = TweenService:Create(toastContainer, tweenInfo, {
				Position = position,
			})
			table.insert(positionTweens, posTween)
			posTween:Play()
		end,
		GetHeight = function(self: Types.MangoToast): number
			return toastHeight
		end,
		Destroy = function(self: Types.MangoToast)
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
			toastContainer:Destroy()
			if screenGui then
				screenGui:Destroy()
			end
		end,
	}

	return self
end

function module.newStack(config: Types.MangoToastStackConfig): Types.MangoToastStack
	local theme = config.Theme

	local maxVisible = resolve(config.MaxVisible, nil, 3) :: number
	local stackGap = resolve(config.StackGap, nil, 8) :: number

	-- State
	local isDestroyed = false
	local activeToasts: {Types.MangoToast} = {}

	-- Determine parent container
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

	-- Compute Y offset from bottom for a toast at the given index (1-based)
	-- Stacks upward: index 1 is closest to bottom
	local function computeYForIndex(index: number): number
		local y = -16 -- base offset from bottom edge
		for i = 1, index - 1 do
			local toast = activeToasts[i]
			if toast then
				y = y - toast:GetHeight() - stackGap
			end
		end
		return y
	end

	-- Reflow all active toasts to fill gaps
	local function reflowToasts()
		for i, toast in activeToasts do
			local y = computeYForIndex(i)
			toast:SetPosition(UDim2.new(0.5, 0, 1, y))
		end
	end

	-- Remove a toast from the active array and reflow
	local function removeFromArray(toast: Types.MangoToast)
		local idx: number? = nil
		for i, t in activeToasts do
			if t == toast then
				idx = i
				break
			end
		end
		if idx then
			table.remove(activeToasts, idx)
			reflowToasts()
		end
	end

	local self: Types.MangoToastStack = {
		Push = function(self: Types.MangoToastStack, toastConfig: Types.MangoToastConfig): Types.MangoToast
			if isDestroyed then
				error("Cannot push to a destroyed MangoToastStack")
			end

			-- Auto-dismiss oldest if at max capacity
			if #activeToasts >= maxVisible then
				local oldest = activeToasts[1]
				if oldest then
					oldest:Dismiss()
				end
			end

			-- Wrap the OnDismissed callback
			local originalOnDismissed = toastConfig.OnDismissed

			local stackToastConfig: Types.MangoToastConfig = {
				Text = toastConfig.Text,
				Icon = toastConfig.Icon,
				Duration = toastConfig.Duration,
				Theme = toastConfig.Theme or theme,
				Parent = parentInstance,
				OnDismissed = nil,
			}

			-- Forward reference for dismiss callback
			local toastRef: Types.MangoToast? = nil

			stackToastConfig.OnDismissed = function()
				if toastRef then
					removeFromArray(toastRef :: Types.MangoToast)
				end
				if originalOnDismissed then
					originalOnDismissed()
				end
			end

			local toast = module.new(stackToastConfig)
			toastRef = toast

			-- Position and show
			table.insert(activeToasts, toast)
			local y = computeYForIndex(#activeToasts)
			toast.Container.Position = UDim2.new(0.5, 0, 1, 60) -- start offscreen below
			toast:Show()
			toast:SetPosition(UDim2.new(0.5, 0, 1, y))

			return toast
		end,
		DismissAll = function(self: Types.MangoToastStack)
			local copy = table.clone(activeToasts)
			for _, toast in copy do
				toast:Dismiss()
			end
		end,
		GetCount = function(self: Types.MangoToastStack): number
			return #activeToasts
		end,
		Destroy = function(self: Types.MangoToastStack)
			if isDestroyed then
				return
			end
			isDestroyed = true

			local copy = table.clone(activeToasts)
			for _, toast in copy do
				toast:Destroy()
			end
			table.clear(activeToasts)

			if screenGui then
				screenGui:Destroy()
			end
		end,
	}

	return self
end

return module
