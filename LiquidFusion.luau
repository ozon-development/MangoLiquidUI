--!strict

local TweenService = game:GetService("TweenService")

local Types = require(script.Parent.Types)
local Themes = require(script.Parent.Themes)
local resolve = Themes.resolve
local UserInputService = game:GetService("UserInputService")

local module = {}

local function makeSmoothTweenInfo(duration: number): TweenInfo
	return TweenInfo.new(
		duration,
		Enum.EasingStyle.Back,
		Enum.EasingDirection.Out,
		0,
		false,
		0
	)
end

function module.new(config: Types.LiquidFusionConfig): Types.LiquidFusionController
	local target: GuiObject = config.Target
	local bulgeScale: number = resolve(config.BulgeScale, nil, 1.025) :: number
	local bulgeDuration: number = resolve(config.BulgeDuration, nil, 0.25) :: number
	local restoreDuration: number = resolve(config.RestoreDuration, nil, 0.3) :: number
	local specularShiftOffset: UDim2 = resolve(config.SpecularShiftOffset, nil, UDim2.new(0.04, 0, 0.04, 0)) :: UDim2

	local useUIScale: boolean = if config.UseUIScale then true else false

	local connections: { RBXScriptConnection } = {}
	local activeTweens: { Tween } = {}
	local originalSize: UDim2? = nil
	local specularGradient: UIGradient? = nil
	local uiScaleInstance: UIScale? = nil
	local touchHitArea: TextButton? = nil

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

	local controller = {} :: Types.LiquidFusionController

	function controller.TweenProperty(self: Types.LiquidFusionController, property: string, targetValue: any, duration: number?): Tween
		local tweenDuration: number = duration or bulgeDuration
		local tweenInfo = makeSmoothTweenInfo(tweenDuration)
		local tween = TweenService:Create(target, tweenInfo, { [property] = targetValue })
		trackTween(tween)
		tween:Play()
		return tween
	end

	function controller.Connect(self: Types.LiquidFusionController)
		-- Disconnect any existing connections first
		controller:Disconnect()

		-- Capture original size at connect time
		originalSize = target.Size

		-- Search for the SpecularStroke's UIGradient for specular rim animation
		-- (Must use named search to avoid picking up InnerHighlight's gradient)
		local specularStroke = target:FindFirstChild("SpecularStroke", true)
		if specularStroke then
			specularGradient = specularStroke:FindFirstChild("SpecularGradient") :: UIGradient?
		end

		-- UIScale mode: create UIScale child and tween Scale instead of Size
		if useUIScale then
			local scale = Instance.new("UIScale")
			scale.Scale = 1
			scale.Parent = target
			uiScaleInstance = scale

			local enterConnection = target.MouseEnter:Connect(function()
				cancelAllTweens()
				local tweenInfo = makeSmoothTweenInfo(bulgeDuration)
				local scaleTween = TweenService:Create(scale, tweenInfo, { Scale = bulgeScale })
				trackTween(scaleTween)
				scaleTween:Play()
				local gradient = specularGradient
				if gradient then
					local gradientTween = TweenService:Create(gradient, tweenInfo, {
						Offset = Vector2.new(specularShiftOffset.X.Scale, specularShiftOffset.Y.Scale),
					})
					trackTween(gradientTween)
					gradientTween:Play()
				end
			end)

			local leaveConnection = target.MouseLeave:Connect(function()
				cancelAllTweens()
				local tweenInfo = makeSmoothTweenInfo(restoreDuration)
				local scaleTween = TweenService:Create(scale, tweenInfo, { Scale = 1 })
				trackTween(scaleTween)
				scaleTween:Play()
				local gradient = specularGradient
				if gradient then
					local gradientTween = TweenService:Create(gradient, tweenInfo, {
						Offset = Vector2.new(0, 0),
					})
					trackTween(gradientTween)
					gradientTween:Play()
				end
			end)

			table.insert(connections, enterConnection)
			table.insert(connections, leaveConnection)

			if UserInputService.TouchEnabled then
				-- Create transparent TextButton for reliable touch input on transparent targets
				local hitBtn = Instance.new("TextButton")
				hitBtn.Name = "FusionTouchHitArea"
				hitBtn.Size = UDim2.new(1, 0, 1, 0)
				hitBtn.BackgroundTransparency = 1
				hitBtn.BorderSizePixel = 0
				hitBtn.Text = ""
				hitBtn.AutoButtonColor = false
				hitBtn.ZIndex = 99
				hitBtn.Parent = target
				touchHitArea = hitBtn

				local touchBeginConn = hitBtn.InputBegan:Connect(function(input: InputObject)
					if input.UserInputType == Enum.UserInputType.Touch then
						cancelAllTweens()
						local tweenInfo = makeSmoothTweenInfo(bulgeDuration)
						local scaleTween = TweenService:Create(scale, tweenInfo, { Scale = bulgeScale })
						trackTween(scaleTween)
						scaleTween:Play()
						local gradient = specularGradient
						if gradient then
							local gradTween = TweenService:Create(gradient, tweenInfo, {
								Offset = Vector2.new(specularShiftOffset.X.Scale, specularShiftOffset.Y.Scale),
							})
							trackTween(gradTween)
							gradTween:Play()
						end
					end
				end)
				local touchEndConn = hitBtn.InputEnded:Connect(function(input: InputObject)
					if input.UserInputType == Enum.UserInputType.Touch then
						cancelAllTweens()
						local tweenInfo = makeSmoothTweenInfo(restoreDuration)
						local scaleTween = TweenService:Create(scale, tweenInfo, { Scale = 1 })
						trackTween(scaleTween)
						scaleTween:Play()
						local gradient = specularGradient
						if gradient then
							local gradTween = TweenService:Create(gradient, tweenInfo, {
								Offset = Vector2.new(0, 0),
							})
							trackTween(gradTween)
							gradTween:Play()
						end
					end
				end)
				table.insert(connections, touchBeginConn)
				table.insert(connections, touchEndConn)
			end
		else
			-- Default Size-based mode
			local origSize: UDim2 = originalSize :: UDim2
			local bulgeSize = UDim2.new(
				origSize.X.Scale * bulgeScale,
				math.floor(origSize.X.Offset * bulgeScale),
				origSize.Y.Scale * bulgeScale,
				math.floor(origSize.Y.Offset * bulgeScale)
			)

			local enterConnection = target.MouseEnter:Connect(function()
				cancelAllTweens()
				local tweenInfo = makeSmoothTweenInfo(bulgeDuration)
				local sizeTween = TweenService:Create(target, tweenInfo, { Size = bulgeSize })
				trackTween(sizeTween)
				sizeTween:Play()
				local gradient = specularGradient
				if gradient then
					local gradientTween = TweenService:Create(gradient, tweenInfo, {
						Offset = Vector2.new(specularShiftOffset.X.Scale, specularShiftOffset.Y.Scale),
					})
					trackTween(gradientTween)
					gradientTween:Play()
				end
			end)

			local leaveConnection = target.MouseLeave:Connect(function()
				cancelAllTweens()
				local tweenInfo = makeSmoothTweenInfo(restoreDuration)
				local sizeTween = TweenService:Create(target, tweenInfo, { Size = origSize })
				trackTween(sizeTween)
				sizeTween:Play()
				local gradient = specularGradient
				if gradient then
					local gradientTween = TweenService:Create(gradient, tweenInfo, {
						Offset = Vector2.new(0, 0),
					})
					trackTween(gradientTween)
					gradientTween:Play()
				end
			end)

			table.insert(connections, enterConnection)
			table.insert(connections, leaveConnection)

			if UserInputService.TouchEnabled then
				-- Create transparent TextButton for reliable touch input on transparent targets
				local hitBtn = Instance.new("TextButton")
				hitBtn.Name = "FusionTouchHitArea"
				hitBtn.Size = UDim2.new(1, 0, 1, 0)
				hitBtn.BackgroundTransparency = 1
				hitBtn.BorderSizePixel = 0
				hitBtn.Text = ""
				hitBtn.AutoButtonColor = false
				hitBtn.ZIndex = 99
				hitBtn.Parent = target
				touchHitArea = hitBtn

				local touchBeginConn = hitBtn.InputBegan:Connect(function(input: InputObject)
					if input.UserInputType == Enum.UserInputType.Touch then
						cancelAllTweens()
						local tweenInfo = makeSmoothTweenInfo(bulgeDuration)
						local sizeTween = TweenService:Create(target, tweenInfo, { Size = bulgeSize })
						trackTween(sizeTween)
						sizeTween:Play()
						local gradient = specularGradient
						if gradient then
							local gradTween = TweenService:Create(gradient, tweenInfo, {
								Offset = Vector2.new(specularShiftOffset.X.Scale, specularShiftOffset.Y.Scale),
							})
							trackTween(gradTween)
							gradTween:Play()
						end
					end
				end)
				local touchEndConn = hitBtn.InputEnded:Connect(function(input: InputObject)
					if input.UserInputType == Enum.UserInputType.Touch then
						cancelAllTweens()
						local tweenInfo = makeSmoothTweenInfo(restoreDuration)
						local sizeTween = TweenService:Create(target, tweenInfo, { Size = origSize })
						trackTween(sizeTween)
						sizeTween:Play()
						local gradient = specularGradient
						if gradient then
							local gradTween = TweenService:Create(gradient, tweenInfo, {
								Offset = Vector2.new(0, 0),
							})
							trackTween(gradTween)
							gradTween:Play()
						end
					end
				end)
				table.insert(connections, touchBeginConn)
				table.insert(connections, touchEndConn)
			end
		end
	end

	function controller.Disconnect(self: Types.LiquidFusionController)
		for _, connection in connections do
			connection:Disconnect()
		end
		table.clear(connections)
		cancelAllTweens()
	end

	function controller.Destroy(self: Types.LiquidFusionController)
		controller:Disconnect()
		originalSize = nil
		specularGradient = nil
		if uiScaleInstance then
			uiScaleInstance:Destroy()
			uiScaleInstance = nil
		end
		if touchHitArea then
			touchHitArea:Destroy()
			touchHitArea = nil
		end
	end

	return controller
end

return module
