--!strict

local Types = require(script.Parent.Types)
local Themes = require(script.Parent.Themes)
local MangoGlassFrame = require(script.Parent.MangoGlassFrame)
local resolve = Themes.resolve
local MangoProtection = require(script.Parent.MangoProtection)
local TextService = game:GetService("TextService")

local module = {}

function module.new(config: Types.MangoBadgeConfig): Types.MangoBadge
	local theme = config.Theme

	local textSize = resolve(config.TextSize, nil, 12) :: number
	local font = Enum.Font.GothamBold
	local text = resolve(config.Text, nil, "Badge") :: string
	local textColor = resolve(config.TextColor, theme and theme.BadgeTextColor, Color3.fromRGB(255, 255, 255)) :: Color3
	local bgColor = resolve(config.BackgroundColor, theme and theme.BadgeBackgroundColor, Color3.fromRGB(0, 122, 255)) :: Color3
	local bgTransparency = resolve(config.BackgroundTransparency, theme and theme.BadgeBackgroundTransparency, 0.15) :: number

	-- Measure text and add padding (16px horizontal + 8px vertical)
	local textBounds = TextService:GetTextSize(text, textSize, font, Vector2.new(1000, 1000))
	local badgeWidth = textBounds.X + 16
	local badgeHeight = textBounds.Y + 8

	-- Create MangoGlassFrame with pill shape, lightweight for small element
	local glassFrame = MangoGlassFrame.new({
		Size = UDim2.new(0, badgeWidth, 0, badgeHeight),
		Position = resolve(config.Position, nil, UDim2.new(0, 0, 0, 0)) :: UDim2,
		AnchorPoint = resolve(config.AnchorPoint, nil, Vector2.new(0, 0)) :: Vector2,
		CornerRadius = UDim.new(0, 999),
		BackgroundColor3 = bgColor,
		BackgroundTransparency = bgTransparency,
		ShadowEnabled = true,
		ShadowLayerCount = 1,
		ShadowSpread = 3,
		ShadowOffsetY = 1,
		LightweightMode = true,
		Theme = config.Theme,
		Parent = config.Parent,
	})

	-- TextLabel inside GlassSurface
	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "BadgeText"
	textLabel.Text = text
	textLabel.Font = font
	textLabel.TextSize = textSize
	textLabel.TextColor3 = textColor
	textLabel.BackgroundTransparency = 1
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.TextXAlignment = Enum.TextXAlignment.Center
	textLabel.TextYAlignment = Enum.TextYAlignment.Center
	textLabel.BorderSizePixel = 0
	textLabel.ZIndex = 10
	textLabel.Parent = glassFrame.GlassSurface

	local self: Types.MangoBadge = {
		Container = glassFrame.Container,
		SetText = function(self: Types.MangoBadge, newText: string)
			textLabel.Text = newText
			-- Re-measure and resize container
			local newBounds = TextService:GetTextSize(newText, textSize, font, Vector2.new(1000, 1000))
			local newWidth = newBounds.X + 16
			local newHeight = newBounds.Y + 8
			glassFrame.Container.Size = UDim2.new(0, newWidth, 0, newHeight)
			glassFrame.GlassSurface.Size = UDim2.new(1, 0, 1, 0)
		end,
		Destroy = function(self: Types.MangoBadge)
			glassFrame:Destroy()
		end,
	}

	return self
end

return module
