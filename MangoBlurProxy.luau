--!strict

local Types = require(script.Parent.Types)
local Themes = require(script.Parent.Themes)
local resolve = Themes.resolve
local RunService = game:GetService("RunService")

local module = {}

function module.new(config: Types.MangoBlurProxyConfig): Types.MangoBlurProxy
	local theme = config.Theme
	local downscale = resolve(config.DownscaleFactor, nil, 4) :: number
	local updateInterval = resolve(config.UpdateInterval, nil, 0.1) :: number
	local tintColor = resolve(nil, theme and theme.BlurTintColor, Color3.fromRGB(255, 255, 255)) :: Color3
	local tintTransparency = resolve(nil, theme and theme.BlurTintTransparency, 0.70) :: number

	local enabled = resolve(config.Enabled, nil, true) :: boolean
	local isDestroyed = false
	local lastUpdate = 0
	local renderConn: RBXScriptConnection? = nil

	-- Container matches target size
	local container = Instance.new("Frame")
	container.Name = "MangoBlurProxy"
	container.Size = UDim2.new(1, 0, 1, 0)
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0
	container.ZIndex = 0

	-- ViewportFrame at low resolution
	local viewport = Instance.new("ViewportFrame")
	viewport.Name = "BlurViewport"
	viewport.Size = UDim2.new(1, 0, 1, 0)
	viewport.BackgroundTransparency = 1
	viewport.BorderSizePixel = 0
	viewport.ZIndex = 0
	viewport.Ambient = Color3.fromRGB(200, 200, 200)
	viewport.LightColor = Color3.fromRGB(255, 255, 255)
	viewport.Parent = container

	-- WorldModel inside viewport
	local worldModel = Instance.new("WorldModel")
	worldModel.Parent = viewport

	-- ViewportFrame camera
	local camera = Instance.new("Camera")
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	-- Tint overlay
	local tintOverlay = Instance.new("Frame")
	tintOverlay.Name = "BlurTint"
	tintOverlay.Size = UDim2.new(1, 0, 1, 0)
	tintOverlay.BackgroundColor3 = tintColor
	tintOverlay.BackgroundTransparency = tintTransparency
	tintOverlay.BorderSizePixel = 0
	tintOverlay.ZIndex = 1
	tintOverlay.Parent = container

	local function updateCamera()
		local workspaceCamera = workspace.CurrentCamera
		if workspaceCamera then
			camera.CFrame = workspaceCamera.CFrame
			camera.FieldOfView = workspaceCamera.FieldOfView
		end
	end

	local function startUpdating()
		if renderConn then return end
		renderConn = RunService.RenderStepped:Connect(function()
			if isDestroyed or not enabled then return end
			local now = tick()
			if now - lastUpdate >= updateInterval then
				lastUpdate = now
				updateCamera()
			end
		end)
	end

	local function stopUpdating()
		if renderConn then
			renderConn:Disconnect()
			renderConn = nil
		end
	end

	-- Parent
	local parentTarget = config.Parent or config.TargetGui
	container.Parent = parentTarget

	if enabled then
		container.Visible = true
		startUpdating()
	else
		container.Visible = false
	end

	local self: Types.MangoBlurProxy = {
		Container = container,
		SetEnabled = function(self: Types.MangoBlurProxy, value: boolean)
			enabled = value
			container.Visible = value
			if value then
				startUpdating()
			else
				stopUpdating()
			end
		end,
		IsEnabled = function(self: Types.MangoBlurProxy): boolean
			return enabled
		end,
		Destroy = function(self: Types.MangoBlurProxy)
			isDestroyed = true
			stopUpdating()
			container:Destroy()
		end,
	}

	return self
end

return module
