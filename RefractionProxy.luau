--!strict

local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Types = require(script.Parent.Types)
local Themes = require(script.Parent.Themes)
local resolve = Themes.resolve

local module = {}
local proxyDepthCounter = 0
local DEPTH_STEP = 0.003

function module.resetDepthCounter()
	proxyDepthCounter = 0
end

function module.new(config: Types.RefractionProxyConfig): Types.RefractionProxy
	local theme = config.Theme

	local targetGui: GuiObject = config.TargetGui
	local glassTransparency: number = resolve(config.GlassTransparency, theme and theme.GlassTransparency, 0.91)
	local glassMaterial: Enum.Material = resolve(config.GlassMaterial, nil, Enum.Material.Glass)
	local glassColor: Color3 = resolve(config.GlassColor, theme and theme.GlassColor, Color3.fromRGB(235, 240, 250))
	local glassReflectance: number = resolve(config.GlassReflectance, theme and theme.GlassReflectance, 0.04)
	local offsetDepth: number = resolve(config.OffsetDepth, nil, 1.5)
	local glassThickness: number = resolve(config.GlassThickness, nil, 0.05)
	local enabled: boolean = resolve(config.Enabled, nil, true)
	local viewportMode: boolean = resolve(config.ViewportMode, nil, false)

	proxyDepthCounter += 1
	local adjustedDepth: number = offsetDepth + (proxyDepthCounter * DEPTH_STEP)

	local bindingName: string = "MangoRefraction_" .. HttpService:GenerateGUID(false)

	-- Create the Glass Part
	local glassPart = Instance.new("Part")
	glassPart.Name = "MangoRefractionProxy"
	glassPart.Material = glassMaterial
	glassPart.Transparency = glassTransparency
	glassPart.Color = glassColor
	glassPart.Reflectance = glassReflectance
	glassPart.CanCollide = false
	glassPart.CanQuery = false
	glassPart.CanTouch = false
	glassPart.Anchored = true
	glassPart.CastShadow = false
	glassPart.TopSurface = Enum.SurfaceType.Smooth
	glassPart.BottomSurface = Enum.SurfaceType.Smooth
	local Workspace = game:GetService("Workspace")
	local camera = Workspace.CurrentCamera or Workspace:WaitForChild("CurrentCamera")
	glassPart.Parent = camera

	local function updatePartTransform()
		local camera = game:GetService("Workspace").CurrentCamera
		if not camera then
			return
		end

		local viewportSize: Vector2 = camera.ViewportSize
		if viewportSize.X == 0 or viewportSize.Y == 0 then
			return
		end

		local cameraCF: CFrame = camera.CFrame

		if viewportMode then
			-- Full viewport coverage — single Glass Part covers entire screen
			local fov: number = math.rad(camera.FieldOfView)
			local worldHeight: number = 2 * adjustedDepth * math.tan(fov * 0.5)
			local aspectRatio: number = viewportSize.X / viewportSize.Y
			local worldWidth: number = worldHeight * aspectRatio
			glassPart.Size = Vector3.new(worldWidth, worldHeight, glassThickness)
			glassPart.CFrame = cameraCF * CFrame.new(0, 0, -adjustedDepth)
		else
			-- Per-GUI tracking mode using ScreenPointToRay for robust coordinate mapping.
			-- This avoids all GUI inset ambiguity: AbsolutePosition with IgnoreGuiInset=true
			-- is in full-screen coords, matching ScreenPointToRay's coordinate system.
			local absSize: Vector2 = targetGui.AbsoluteSize
			local absPos: Vector2 = targetGui.AbsolutePosition

			local centerVpX: number = absPos.X + absSize.X * 0.5
			local centerVpY: number = absPos.Y + absSize.Y * 0.5

			local centerRay: Ray = camera:ScreenPointToRay(centerVpX, centerVpY, 0)
			local camForward: Vector3 = cameraCF.LookVector
			local t: number = adjustedDepth / camForward:Dot(centerRay.Direction)
			local worldCenter: Vector3 = cameraCF.Position + centerRay.Direction * t

			local topLeftRay: Ray = camera:ScreenPointToRay(absPos.X, absPos.Y, 0)
			local bottomRightRay: Ray = camera:ScreenPointToRay(absPos.X + absSize.X, absPos.Y + absSize.Y, 0)
			local tTL: number = adjustedDepth / camForward:Dot(topLeftRay.Direction)
			local tBR: number = adjustedDepth / camForward:Dot(bottomRightRay.Direction)
			local worldTL: Vector3 = cameraCF.Position + topLeftRay.Direction * tTL
			local worldBR: Vector3 = cameraCF.Position + bottomRightRay.Direction * tBR

			local localTL: Vector3 = cameraCF:PointToObjectSpace(worldTL)
			local localBR: Vector3 = cameraCF:PointToObjectSpace(worldBR)
			local partWidth: number = math.abs(localBR.X - localTL.X)
			local partHeight: number = math.abs(localBR.Y - localTL.Y)

			-- Inset glass Part slightly so rectangular edges hide behind rounded UI corners
			glassPart.Size = Vector3.new(partWidth * 0.97, partHeight * 0.95, glassThickness)
			glassPart.CFrame = CFrame.new(worldCenter, worldCenter + cameraCF.LookVector)
		end
	end

	local function bindRenderStep()
		RunService:BindToRenderStep(
			bindingName,
			Enum.RenderPriority.Camera.Value + 1,
			updatePartTransform
		)
	end

	local function unbindRenderStep()
		RunService:UnbindFromRenderStep(bindingName)
	end

	-- Start tracking if enabled
	if enabled then
		bindRenderStep()
	else
		glassPart.Transparency = 1
	end

	local proxy = {} :: Types.RefractionProxy
	proxy.GlassPart = glassPart
	proxy.Enabled = enabled

	function proxy.SetEnabled(self: Types.RefractionProxy, newEnabled: boolean)
		if self.Enabled == newEnabled then
			return
		end
		self.Enabled = newEnabled
		if newEnabled then
			glassPart.Transparency = glassTransparency
			bindRenderStep()
		else
			unbindRenderStep()
			glassPart.Transparency = 1
		end
	end

	function proxy.UpdateTarget(self: Types.RefractionProxy, newGui: GuiObject)
		targetGui = newGui
	end

	function proxy.Destroy(self: Types.RefractionProxy)
		self.Enabled = false
		pcall(unbindRenderStep)
		glassPart:Destroy()
		self.GlassPart = nil :: any
	end

	return proxy
end

return module
