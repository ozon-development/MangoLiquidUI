--!strict

local Types = require(script.Parent.Types)
local Themes = require(script.Parent.Themes)
local MangoShimmer = require(script.Parent.MangoShimmer)
local resolve = Themes.resolve
local MangoProtection = require(script.Parent.MangoProtection)

local module = {}

function module.new(config: Types.MangoSkeletonConfig): Types.MangoSkeleton
	local theme = config.Theme
	local bgColor = resolve(nil, theme and theme.SkeletonBackgroundColor, Color3.fromRGB(230, 230, 235)) :: Color3
	local bgTransparency = resolve(nil, theme and theme.SkeletonBackgroundTransparency, 0.50) :: number
	local cornerRadius = resolve(config.CornerRadius, nil, UDim.new(0, 8)) :: UDim

	local container = Instance.new("Frame")
	container.Name = MangoProtection.randomName("Skeleton")
	container.Size = config.Size
	container.Position = config.Position
	container.AnchorPoint = resolve(config.AnchorPoint, nil, Vector2.new(0, 0)) :: Vector2
	container.BackgroundColor3 = bgColor
	container.BackgroundTransparency = bgTransparency
	container.BorderSizePixel = 0

	local corner = Instance.new("UICorner")
	corner.CornerRadius = cornerRadius
	corner.Parent = container

	-- Apply shimmer overlay
	local shimmer = MangoShimmer.new({
		Target = container,
		Theme = theme,
		Enabled = true,
	})

	if config.Parent then
		container.Parent = config.Parent
	end

	local self: Types.MangoSkeleton = {
		Container = container,
		Destroy = function(self: Types.MangoSkeleton)
			shimmer:Destroy()
			container:Destroy()
		end,
	}

	return self
end

return module
