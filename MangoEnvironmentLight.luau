--!strict

local Types = require(script.Parent.Types)
local Themes = require(script.Parent.Themes)
local resolve = Themes.resolve

local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local module = {}

type RegisteredFrame = {
	frame: Types.MangoGlassFrame,
	originalColor: Color3,
	originalSpecularColor: Color3?,
}

function module.new(config: Types.MangoEnvironmentLightConfig?): Types.MangoEnvironmentLight
	local cfg = config or {} :: Types.MangoEnvironmentLightConfig

	local updateAngleEveryFrame = resolve(cfg.UpdateAngleEveryFrame, nil, true) :: boolean
	local tintUpdateInterval = resolve(cfg.TintUpdateInterval, nil, 0.5) :: number
	local tintInfluence = resolve(cfg.TintInfluence, nil, 0.45) :: number
	local enabled = resolve(cfg.Enabled, nil, true) :: boolean

	local registeredFrames: {RegisteredFrame} = {}
	local renderStepName = "MangoEnvLight_" .. tostring(math.random(100000, 999999))
	local lastTintUpdate: number = 0
	local currentSunAngle: number = 90
	local currentTint: Color3 = Color3.new(1, 1, 1)
	local lastAppliedAngle: number = -999

	-- Compute the sun/moon direction projected into screen-space gradient angle
	local function computeSunAngle(): number
		local camera = Workspace.CurrentCamera
		if not camera then
			return 90
		end

		local sunDir = Lighting:GetSunDirection()
		-- If sun is below horizon, try moon
		if sunDir.Y < -0.1 then
			sunDir = Lighting:GetMoonDirection()
		end

		-- Project into camera local space
		local localDir = camera.CFrame:VectorToObjectSpace(sunDir)
		-- Convert to gradient rotation angle
		-- localDir.X = right, localDir.Y = up
		local angle = (math.deg(math.atan2(-localDir.Y, localDir.X)) + 90) % 360
		return angle
	end

	-- Sample ambient/outdoor lighting for glass tint
	local function computeEnvironmentTint(): Color3
		local outdoor = Lighting.OutdoorAmbient
		local ambient = Lighting.Ambient
		local colorShiftTop = Lighting.ColorShift_Top

		-- Weighted blend: OutdoorAmbient * 0.5 + Ambient * 0.2 + ColorShift_Top * 0.3
		local r = outdoor.R * 0.5 + ambient.R * 0.2 + colorShiftTop.R * 0.3
		local g = outdoor.G * 0.5 + ambient.G * 0.2 + colorShiftTop.G * 0.3
		local b = outdoor.B * 0.5 + ambient.B * 0.2 + colorShiftTop.B * 0.3

		return Color3.new(math.clamp(r, 0, 1), math.clamp(g, 0, 1), math.clamp(b, 0, 1))
	end

	-- Apply tint to registered frames
	local function applyTint(tint: Color3)
		for _, entry in registeredFrames do
			local original = entry.originalColor
			local tinted = original:Lerp(tint, tintInfluence)
			entry.frame.GlassSurface.BackgroundColor3 = tinted
			-- Tint specular stroke at half influence
			local origSpecular = entry.originalSpecularColor
			if origSpecular then
				entry.frame.SpecularStroke.Color = origSpecular:Lerp(tint, tintInfluence * 0.5)
			end
		end
	end

	-- Main update function bound to RenderStep
	local function onRenderStep(_dt: number)
		if not enabled then
			return
		end

		-- Update sun angle every frame (or skip if disabled)
		if updateAngleEveryFrame then
			currentSunAngle = computeSunAngle()

			-- Only apply if angle changed significantly (caching threshold)
			if math.abs(currentSunAngle - lastAppliedAngle) >= 0.1 then
				lastAppliedAngle = currentSunAngle
				-- Update all registered frames' gradient rotations
				for _, entry in registeredFrames do
					entry.frame:SetLightDirection(currentSunAngle)
				end
			end
		end

		-- Throttle tint updates
		local now = tick()
		if now - lastTintUpdate >= tintUpdateInterval then
			lastTintUpdate = now
			currentTint = computeEnvironmentTint()
			applyTint(currentTint)
		end
	end

	-- Start the render step binding
	local function startBinding()
		pcall(function()
			RunService:UnbindFromRenderStep(renderStepName)
		end)
		RunService:BindToRenderStep(renderStepName, Enum.RenderPriority.Camera.Value + 2, onRenderStep)
	end

	-- Stop the render step binding
	local function stopBinding()
		pcall(function()
			RunService:UnbindFromRenderStep(renderStepName)
		end)
	end

	if enabled then
		startBinding()
	end

	local self: Types.MangoEnvironmentLight = {
		Enable = function(self: Types.MangoEnvironmentLight)
			if not enabled then
				enabled = true
				startBinding()
			end
		end,
		Disable = function(self: Types.MangoEnvironmentLight)
			if enabled then
				enabled = false
				stopBinding()
				-- Restore original colors
				for _, entry in registeredFrames do
					entry.frame.GlassSurface.BackgroundColor3 = entry.originalColor
					if entry.originalSpecularColor then
						entry.frame.SpecularStroke.Color = entry.originalSpecularColor
					end
				end
			end
		end,
		IsEnabled = function(self: Types.MangoEnvironmentLight): boolean
			return enabled
		end,
		GetSunAngle = function(self: Types.MangoEnvironmentLight): number
			return currentSunAngle
		end,
		GetEnvironmentTint = function(self: Types.MangoEnvironmentLight): Color3
			return currentTint
		end,
		RegisterGlassFrame = function(self: Types.MangoEnvironmentLight, frame: Types.MangoGlassFrame)
			-- Check if already registered
			for _, entry in registeredFrames do
				if entry.frame == frame then
					return
				end
			end
			table.insert(registeredFrames, {
				frame = frame,
				originalColor = frame.GlassSurface.BackgroundColor3,
				originalSpecularColor = frame.SpecularStroke.Color,
			})
		end,
		UnregisterGlassFrame = function(self: Types.MangoEnvironmentLight, frame: Types.MangoGlassFrame)
			for i, entry in registeredFrames do
				if entry.frame == frame then
					-- Restore original colors
					entry.frame.GlassSurface.BackgroundColor3 = entry.originalColor
					if entry.originalSpecularColor then
						entry.frame.SpecularStroke.Color = entry.originalSpecularColor
					end
					table.remove(registeredFrames, i)
					return
				end
			end
		end,
		Destroy = function(self: Types.MangoEnvironmentLight)
			enabled = false
			stopBinding()
			-- Restore original colors
			for _, entry in registeredFrames do
				entry.frame.GlassSurface.BackgroundColor3 = entry.originalColor
				if entry.originalSpecularColor then
					entry.frame.SpecularStroke.Color = entry.originalSpecularColor
				end
			end
			table.clear(registeredFrames)
		end,
	}

	return self
end

return module
