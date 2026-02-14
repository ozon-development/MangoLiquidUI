--!strict

local Types = require(script.Parent.Types)
local MangoProtection = require(script.Parent.MangoProtection)

local module = {}

function module.new(config: Types.MangoLayoutConfig): Types.MangoLayout
	local padding = config.Padding or 8

	local container = Instance.new("Frame")
	container.Name = MangoProtection.randomName("Layout")
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0
	container.AutomaticSize = Enum.AutomaticSize.XY
	container.Size = UDim2.new(0, 0, 0, 0)

	-- UIPadding
	local uiPadding = Instance.new("UIPadding")
	uiPadding.PaddingTop = UDim.new(0, config.PaddingTop or 0)
	uiPadding.PaddingBottom = UDim.new(0, config.PaddingBottom or 0)
	uiPadding.PaddingLeft = UDim.new(0, config.PaddingLeft or 0)
	uiPadding.PaddingRight = UDim.new(0, config.PaddingRight or 0)
	uiPadding.Parent = container

	if config.Mode == "grid" then
		local grid = Instance.new("UIGridLayout")
		grid.CellSize = config.CellSize or UDim2.new(0, 100, 0, 100)
		grid.CellPadding = UDim2.new(0, padding, 0, padding)
		grid.SortOrder = Enum.SortOrder.LayoutOrder
		if config.HorizontalAlignment then
			grid.HorizontalAlignment = config.HorizontalAlignment
		end
		grid.Parent = container
	else
		local list = Instance.new("UIListLayout")
		list.FillDirection = if config.Mode == "hstack" then Enum.FillDirection.Horizontal else Enum.FillDirection.Vertical
		list.Padding = UDim.new(0, padding)
		list.SortOrder = Enum.SortOrder.LayoutOrder
		if config.HorizontalAlignment then
			list.HorizontalAlignment = config.HorizontalAlignment
		end
		if config.VerticalAlignment then
			list.VerticalAlignment = config.VerticalAlignment
		end
		list.Parent = container
	end

	if config.Parent then
		container.Parent = config.Parent
	end

	local layoutOrder = 0

	local self: Types.MangoLayout = {
		Container = container,
		AddChild = function(self: Types.MangoLayout, child: GuiObject)
			layoutOrder += 1
			child.LayoutOrder = layoutOrder
			child.Parent = container
		end,
		RemoveChild = function(self: Types.MangoLayout, child: GuiObject)
			if child.Parent == container then
				child.Parent = nil
			end
		end,
		Clear = function(self: Types.MangoLayout)
			for _, child in container:GetChildren() do
				if child:IsA("GuiObject") and not child:IsA("UIListLayout") and not child:IsA("UIGridLayout") and not child:IsA("UIPadding") then
					child:Destroy()
				end
			end
			layoutOrder = 0
		end,
		Destroy = function(self: Types.MangoLayout)
			container:Destroy()
		end,
	}

	return self
end

return module
