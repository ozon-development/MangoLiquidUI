local MangoUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/ozon-development/MangoLiquidUI/master/dist/MangoLiquidUI.lua"))()

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "WalkspeedUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player.PlayerGui

local theme = MangoUI.Themes.Dark

-- Glass panel background
local panel = MangoUI.MangoGlassFrame.new({
	Size = UDim2.new(0, 260, 0, 120),
	Position = UDim2.new(0, 20, 0.5, 0),
	AnchorPoint = Vector2.new(0, 0.5),
	CornerRadius = UDim.new(0, 16),
	Theme = theme,
	LightweightMode = true,
	Parent = gui,
})

-- Title
local title = Instance.new("TextLabel")
title.Text = "Walkspeed"
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextColor3 = theme.PrimaryTextColor
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, -32, 0, 24)
title.Position = UDim2.new(0, 16, 0, 14)
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 10
title.Parent = panel.GlassSurface

-- Value label
local valueLabel = Instance.new("TextLabel")
valueLabel.Text = "16"
valueLabel.Font = Enum.Font.GothamMedium
valueLabel.TextSize = 14
valueLabel.TextColor3 = theme.SecondaryTextColor
valueLabel.BackgroundTransparency = 1
valueLabel.Size = UDim2.new(0, 40, 0, 24)
valueLabel.Position = UDim2.new(1, -56, 0, 14)
valueLabel.TextXAlignment = Enum.TextXAlignment.Right
valueLabel.ZIndex = 10
valueLabel.Parent = panel.GlassSurface

-- Slider
local slider = MangoUI.MangoSlider.new({
	Position = UDim2.new(0.5, 0, 0, 60),
	Size = UDim2.new(1, -32, 0, 36),
	AnchorPoint = Vector2.new(0.5, 0),
	Theme = theme,
	InitialValue = 16,
	Min = 0,
	Max = 100,
	Step = 1,
	OnChanged = function(value)
		valueLabel.Text = tostring(math.floor(value))
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = value
			end
		end
	end,
	Parent = panel.GlassSurface,
})
