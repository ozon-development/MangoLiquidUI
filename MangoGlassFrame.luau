--!strict

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Types = require(script.Parent.Types)
local Themes = require(script.Parent.Themes)
local resolve = Themes.resolve
local MangoProtection = require(script.Parent.MangoProtection)

local module = {}

function module.new(config: Types.MangoGlassConfig): Types.MangoGlassFrame
	local theme = config.Theme

	-- Resolve all config values with nil-safe helper
	local size = config.Size
	local position = config.Position
	local anchorPoint = resolve(config.AnchorPoint, nil, Vector2.new(0, 0)) :: Vector2
	local cornerRadius = resolve(config.CornerRadius, nil, UDim.new(0, 16)) :: UDim
	local backgroundColor = resolve(config.BackgroundColor3, theme and theme.BackgroundColor3, Color3.fromRGB(255, 255, 255)) :: Color3
	local backgroundTransparency = resolve(config.BackgroundTransparency, theme and theme.BackgroundTransparency, 0.72) :: number
	local noiseImageId = resolve(config.NoiseImageId, nil, "rbxassetid://4531766211") :: string
	local noiseOpacity = resolve(config.NoiseOpacity, theme and theme.NoiseOpacity, 0.03) :: number
	local lensGroupColor3 = resolve(config.LensGroupColor3, theme and theme.LensGroupColor3, Color3.fromRGB(255, 254, 252)) :: Color3
	local lensGroupTransparency = resolve(config.LensGroupTransparency, theme and theme.LensGroupTransparency, 0.65) :: number
	local innerGlowColor = resolve(config.InnerGlowColor, theme and theme.InnerGlowColor, Color3.fromRGB(255, 255, 255)) :: Color3
	local innerGlowTransparency = resolve(config.InnerGlowTransparency, theme and theme.InnerGlowTransparency, 0.55) :: number
	local innerGlowHeight = resolve(config.InnerGlowHeight, theme and theme.InnerGlowHeight, 0.30) :: number
	local strokeColor = resolve(config.StrokeColor, theme and theme.StrokeColor, Color3.fromRGB(255, 255, 255)) :: Color3
	local strokeThickness = resolve(config.StrokeThickness, theme and theme.StrokeThickness, 1) :: number
	local fresnelStart = resolve(config.FresnelStartTransparency, theme and theme.FresnelStartTransparency, 0.25) :: number
	local fresnelEnd = resolve(config.FresnelEndTransparency, theme and theme.FresnelEndTransparency, 0.95) :: number
	local fresnelMid = resolve(config.FresnelMidTransparency, theme and theme.FresnelMidTransparency, 0.50) :: number
	local fresnelMidPoint = resolve(config.FresnelMidPoint, theme and theme.FresnelMidPoint, 0.35) :: number
	local fresnelAngle = resolve(config.FresnelAngle, theme and theme.FresnelAngle, 90) :: number
	local shadowColor = resolve(config.ShadowColor, theme and theme.ShadowColor, Color3.fromRGB(0, 0, 0)) :: Color3
	local shadowTransparency = resolve(config.ShadowTransparency, theme and theme.ShadowTransparency, 0.68) :: number
	local shadowSpread = resolve(config.ShadowSpread, theme and theme.ShadowSpread, 8) :: number
	local shadowOffsetY = resolve(config.ShadowOffsetY, theme and theme.ShadowOffsetY, 2) :: number
	local shadowOffsetX = resolve(config.ShadowOffsetX, theme and theme.ShadowOffsetX, 0) :: number
	local shadowEnabled = resolve(config.ShadowEnabled, nil, true) :: boolean
	local shadowLayerCount = resolve(config.ShadowLayerCount, nil, 5) :: number
	local lightweightMode = resolve(config.LightweightMode, nil, false) :: boolean
	local parallaxEnabled = resolve(config.ParallaxEnabled, nil, false) :: boolean
	local parallaxIntensity = resolve(config.ParallaxIntensity, theme and theme.ParallaxIntensity, 0.15) :: number

	-- Container (transparent wrapper, NO ClipsDescendants, NO UICorner)
	local container = Instance.new("Frame")
	container.Name = MangoProtection.randomName("GlassFrame")
	container.Size = size
	container.Position = position
	container.AnchorPoint = anchorPoint
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0

	-- N-layer graduated shadow (quadratic falloff eliminates banding)
	local layerCount = math.clamp(shadowLayerCount, 1, 12)
	local shadowLayers: {Frame} = {}

	-- Loop REVERSED: outermost added first (bottom), innermost added last (top, darkest)
	for i = layerCount, 1, -1 do
		local t = i / layerCount
		local spread = math.ceil(shadowSpread * t)
		local layerAlpha = (1 - shadowTransparency)
			* ((layerCount - i + 1) / layerCount) ^ 2
			/ (layerCount / 3)
		local layerTransparency = math.clamp(1 - layerAlpha, 0, 1)
		local cornerRadiusOffset = math.ceil(8 * t)

		local shadowLayer = Instance.new("Frame")
		shadowLayer.Name = "ShadowLayer" .. i
		shadowLayer.AnchorPoint = Vector2.new(0.5, 0.5)
		shadowLayer.Position = UDim2.new(0.5, shadowOffsetX, 0.5, shadowOffsetY)
		shadowLayer.Size = UDim2.new(1, spread * 2, 1, spread * 2)
		shadowLayer.BackgroundColor3 = shadowColor
		shadowLayer.BackgroundTransparency = layerTransparency
		shadowLayer.BorderSizePixel = 0
		shadowLayer.ZIndex = 0
		shadowLayer.Visible = shadowEnabled
		shadowLayer.Parent = container

		local layerCorner = Instance.new("UICorner")
		layerCorner.CornerRadius = UDim.new(0, cornerRadius.Offset + cornerRadiusOffset)
		layerCorner.Parent = shadowLayer

		table.insert(shadowLayers, shadowLayer)
	end

	-- GlassSurface (clipping inner frame)
	local glassSurface = Instance.new("Frame")
	glassSurface.Name = "GlassSurface"
	glassSurface.Size = UDim2.new(1, 0, 1, 0)
	glassSurface.BackgroundColor3 = backgroundColor
	glassSurface.BackgroundTransparency = backgroundTransparency
	glassSurface.ClipsDescendants = true
	glassSurface.BorderSizePixel = 0
	glassSurface.ZIndex = 1
	glassSurface.Parent = container

	local glassSurfaceCorner = Instance.new("UICorner")
	glassSurfaceCorner.CornerRadius = cornerRadius
	glassSurfaceCorner.Parent = glassSurface

	local surfaceGradient = Instance.new("UIGradient")
	surfaceGradient.Name = "SurfaceGradient"
	surfaceGradient.Rotation = 135 -- Apple's diagonal gradient (top-left to bottom-right)
	surfaceGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(230, 230, 235)),
	})
	surfaceGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.92),
		NumberSequenceKeypoint.new(1, 0.96),
	})
	surfaceGradient.Parent = glassSurface

	local lensGroup: CanvasGroup? = nil
	local textureGroup: CanvasGroup? = nil
	local noiseTile: ImageLabel? = nil
	local innerHighlight: Frame? = nil

	if not lightweightMode then
		-- LensGroup (saturation tint via CanvasGroup)
		local lg = Instance.new("CanvasGroup")
		lg.Name = "LensGroup"
		lg.Size = UDim2.new(1, 0, 1, 0)
		lg.GroupColor3 = lensGroupColor3
		lg.GroupTransparency = lensGroupTransparency
		lg.BackgroundTransparency = 1
		lg.BorderSizePixel = 0
		lg.Parent = glassSurface

		local lensCorner = Instance.new("UICorner")
		lensCorner.CornerRadius = cornerRadius
		lensCorner.Parent = lg

		-- TextureGroup (noise dithering layer)
		local tg = Instance.new("CanvasGroup")
		tg.Name = "TextureGroup"
		tg.Size = UDim2.new(1, 0, 1, 0)
		tg.BackgroundTransparency = 1
		tg.BorderSizePixel = 0
		tg.Parent = lg

		local textureCorner = Instance.new("UICorner")
		textureCorner.CornerRadius = cornerRadius
		textureCorner.Parent = tg

		-- NoiseTile (Perlin noise overlay)
		local nt = Instance.new("ImageLabel")
		nt.Name = "NoiseTile"
		nt.Image = noiseImageId
		nt.ImageTransparency = 1 - noiseOpacity
		nt.ScaleType = Enum.ScaleType.Tile
		nt.TileSize = UDim2.new(0.125, 0, 0.125, 0)
		nt.Size = UDim2.new(1, 0, 1, 0)
		nt.BackgroundTransparency = 1
		nt.BorderSizePixel = 0
		nt.Parent = tg

		local noiseCorner = Instance.new("UICorner")
		noiseCorner.CornerRadius = cornerRadius
		noiseCorner.Parent = nt

		-- InnerHighlight (subtle top-edge glow)
		local ih = Instance.new("Frame")
		ih.Name = "InnerHighlight"
		ih.Size = UDim2.new(1, 0, innerGlowHeight, 0)
		ih.Position = UDim2.new(0, 0, 0, 0)
		ih.BackgroundColor3 = innerGlowColor
		ih.BackgroundTransparency = innerGlowTransparency
		ih.BorderSizePixel = 0
		ih.ZIndex = 2
		ih.Parent = tg

		local highlightCorner = Instance.new("UICorner")
		highlightCorner.CornerRadius = cornerRadius
		highlightCorner.Parent = ih

		local highlightGradient = Instance.new("UIGradient")
		highlightGradient.Name = "HighlightGradient"
		highlightGradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		})
		highlightGradient.Rotation = 90
		highlightGradient.Parent = ih

		lensGroup = lg
		textureGroup = tg
		noiseTile = nt
		innerHighlight = ih
	end

	-- Inner edge highlight (full-perimeter inner shadow inside GlassSurface)
	local innerEdgeColor = resolve(config.InnerEdgeColor, theme and theme.InnerEdgeColor, Color3.fromRGB(255, 255, 255)) :: Color3
	local innerEdgeTop = resolve(config.InnerEdgeTopTransparency, theme and theme.InnerEdgeTopTransparency, 0.30) :: number
	local innerEdgeMid = resolve(config.InnerEdgeMidTransparency, theme and theme.InnerEdgeMidTransparency, 0.68) :: number
	local innerEdgeBottom = resolve(config.InnerEdgeBottomTransparency, theme and theme.InnerEdgeBottomTransparency, 0.90) :: number

	local innerEdgeFrame = Instance.new("Frame")
	innerEdgeFrame.Name = "InnerEdgeFrame"
	innerEdgeFrame.Size = UDim2.new(1, 0, 1, 0)
	innerEdgeFrame.BackgroundTransparency = 1
	innerEdgeFrame.BorderSizePixel = 0
	innerEdgeFrame.ZIndex = 3
	innerEdgeFrame.Parent = glassSurface

	local innerEdgeCorner = Instance.new("UICorner")
	innerEdgeCorner.CornerRadius = cornerRadius
	innerEdgeCorner.Parent = innerEdgeFrame

	local innerEdgeStroke = Instance.new("UIStroke")
	innerEdgeStroke.Name = "InnerEdgeStroke"
	innerEdgeStroke.Color = innerEdgeColor
	innerEdgeStroke.Thickness = 1
	innerEdgeStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	innerEdgeStroke.Parent = innerEdgeFrame

	local innerEdgeGradient = Instance.new("UIGradient")
	innerEdgeGradient.Name = "InnerEdgeGradient"
	innerEdgeGradient.Rotation = 90
	innerEdgeGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, innerEdgeTop),
		NumberSequenceKeypoint.new(0.5, innerEdgeMid),
		NumberSequenceKeypoint.new(1, innerEdgeBottom),
	})
	innerEdgeGradient.Parent = innerEdgeStroke

	-- SpecularFrame (CHILD OF CONTAINER, outside clip boundary)
	local specularFrame = Instance.new("Frame")
	specularFrame.Name = "SpecularFrame"
	specularFrame.Size = UDim2.new(1, 0, 1, 0)
	specularFrame.BackgroundTransparency = 1
	specularFrame.BorderSizePixel = 0
	specularFrame.ZIndex = 2
	specularFrame.Parent = container

	local specularCorner = Instance.new("UICorner")
	specularCorner.CornerRadius = cornerRadius
	specularCorner.Parent = specularFrame

	-- UIStroke (directional Fresnel rim)
	local specularStroke = Instance.new("UIStroke")
	specularStroke.Name = "SpecularStroke"
	specularStroke.Color = strokeColor
	specularStroke.Thickness = strokeThickness
	specularStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	specularStroke.Parent = specularFrame

	-- UIGradient (directional top-lit transparency)
	local specularGradient = Instance.new("UIGradient")
	specularGradient.Name = "SpecularGradient"
	specularGradient.Rotation = fresnelAngle
	specularGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, fresnelStart),
		NumberSequenceKeypoint.new(fresnelMidPoint, fresnelMid),
		NumberSequenceKeypoint.new(1, fresnelEnd),
	})
	specularGradient.Parent = specularStroke

	-- Parent assignment
	if config.Parent then
		container.Parent = config.Parent
	end
	MangoProtection.registerInstance(container)

	-- Parallax system
	local Workspace = game:GetService("Workspace")
	local parallaxBindingName = MangoProtection.randomBindingName("MangoParallax")
	local parallaxBound = false

	local function startParallax()
		if parallaxBound then
			return
		end
		parallaxBound = true
		RunService:BindToRenderStep(parallaxBindingName, Enum.RenderPriority.Camera.Value + 1, function()
			local camera = Workspace.CurrentCamera
			if not camera then
				return
			end
			local mousePos = UserInputService:GetMouseLocation()
			local viewportSize = camera.ViewportSize
			if viewportSize.X == 0 or viewportSize.Y == 0 then
				return
			end
			local nx = (mousePos.X / viewportSize.X - 0.5) * 2
			local ny = (mousePos.Y / viewportSize.Y - 0.5) * 2
			local intensity = parallaxIntensity

			specularGradient.Offset = Vector2.new(nx * 0.03 * intensity, ny * 0.03 * intensity)
			innerEdgeGradient.Offset = Vector2.new(nx * 0.02 * intensity, ny * 0.02 * intensity)

			if not lightweightMode and innerHighlight then
				local highlightGrad = (innerHighlight :: Frame):FindFirstChild("HighlightGradient")
				if highlightGrad and highlightGrad:IsA("UIGradient") then
					(highlightGrad :: UIGradient).Offset = Vector2.new(nx * 0.01 * intensity, ny * 0.005 * intensity)
				end
			end
		end)
	end

	local function stopParallax()
		if not parallaxBound then
			return
		end
		parallaxBound = false
		pcall(function()
			RunService:UnbindFromRenderStep(parallaxBindingName)
		end)
	end

	if parallaxEnabled then
		startParallax()
	end

	local self: Types.MangoGlassFrame = {
		Container = container,
		Frame = container,
		GlassSurface = glassSurface,
		ShadowLayers = shadowLayers,
		LensGroup = lensGroup,
		TextureGroup = textureGroup,
		NoiseLabel = noiseTile,
		InnerHighlight = innerHighlight,
		InnerEdgeFrame = innerEdgeFrame,
		InnerEdgeStroke = innerEdgeStroke,
		InnerEdgeGradient = innerEdgeGradient,
		SpecularFrame = specularFrame,
		SpecularStroke = specularStroke,
		SpecularGradient = specularGradient,
		SetLightDirection = function(self: Types.MangoGlassFrame, angle: number)
			self.SpecularGradient.Rotation = angle
			self.InnerEdgeGradient.Rotation = angle
			local highlight = self.InnerHighlight
			if highlight then
				local highlightGrad = highlight:FindFirstChild("HighlightGradient")
				if highlightGrad and highlightGrad:IsA("UIGradient") then
					(highlightGrad :: UIGradient).Rotation = angle
				end
			end
		end,
		SetParallaxEnabled = function(self: Types.MangoGlassFrame, newEnabled: boolean)
			parallaxEnabled = newEnabled
			if newEnabled then
				startParallax()
			else
				stopParallax()
			end
		end,
		Destroy = function(self: Types.MangoGlassFrame)
			stopParallax()
			self.Container:Destroy()
		end,
	}

	return self
end

return module
