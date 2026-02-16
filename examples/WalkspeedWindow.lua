--// WalkspeedWindow — MangoLiquidUI example
--// Works with both loadstring(game:HttpGet(...))() and loadstring(readfile(...))()

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Load MangoLiquidUI (with fallback for readfile-loaded scripts)
local ui
if getgenv and getgenv().MangoLiquidUI then
	ui = getgenv().MangoLiquidUI
else
	local ok, result = pcall(function()
		return loadstring(game:HttpGet(
			"https://raw.githubusercontent.com/ozon-development/MangoLiquidUI/master/dist/MangoLiquidUI.lua"
		))()
	end)
	if ok and result then
		ui = result
		if getgenv then
			getgenv().MangoLiquidUI = ui
		end
	else
		warn("WalkspeedWindow: Failed to load MangoLiquidUI:", result)
		return
	end
end

ui.intro.skip()

-- Create window
local Window = ui.window({
	Name = "Walkspeed",
	Theme = ui.Dark,
	Size = UDim2.new(0, 300, 0, 260),
	ToggleKey = "RightShift",
	ShowButton = "Walkspeed",
})

local Main = Window:Tab("Main")

-- Toggle walkspeed on/off
Main:Toggle({
	Name = "Enabled",
	Default = false,
	Flag = "WalkspeedEnabled",
	Callback = function(enabled)
		local character = player.Character
		if not character then return end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid then return end
		if enabled then
			humanoid.WalkSpeed = Window.Flags.WalkspeedValue or 16
		else
			humanoid.WalkSpeed = 16
		end
	end,
})

-- Slider to set speed
Main:Slider({
	Name = "Speed",
	Range = {0, 200},
	Default = 16,
	Increment = 1,
	Suffix = " studs/s",
	Flag = "WalkspeedValue",
	Callback = function(value)
		if not Window.Flags.WalkspeedEnabled then return end
		local character = player.Character
		if not character then return end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid then return end
		humanoid.WalkSpeed = value
	end,
})

-- Re-apply on respawn
player.CharacterAdded:Connect(function(character)
	local humanoid = character:WaitForChild("Humanoid", 5)
	if not humanoid then return end
	if Window.Flags.WalkspeedEnabled then
		humanoid.WalkSpeed = Window.Flags.WalkspeedValue or 16
	end
end)

Window:Show()
