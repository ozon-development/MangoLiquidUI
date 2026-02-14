--!strict

local HapticService = game:GetService("HapticService")

local module = {}

local enabled: boolean = false

function module.setEnabled(value: boolean)
	enabled = value
end

function module.isEnabled(): boolean
	return enabled
end

function module.trigger(intensity: number?)
	if not enabled then return end
	local motor = Enum.VibrationMotor.Large
	local power = intensity or 0.5
	pcall(function()
		HapticService:SetMotor(Enum.UserInputType.Gamepad1, motor, power)
	end)
	task.delay(0.05, function()
		pcall(function()
			HapticService:SetMotor(Enum.UserInputType.Gamepad1, motor, 0)
		end)
	end)
end

function module.light()
	module.trigger(0.2)
end

function module.medium()
	module.trigger(0.5)
end

function module.heavy()
	module.trigger(0.8)
end

return module
