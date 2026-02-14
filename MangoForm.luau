--!strict

local Types = require(script.Parent.Types)
local Themes = require(script.Parent.Themes)
local resolve = Themes.resolve
local MangoTextField = require(script.Parent.MangoTextField)
local MangoCheckbox = require(script.Parent.MangoCheckbox)
local MangoDropdown = require(script.Parent.MangoDropdown)
local MangoSlider = require(script.Parent.MangoSlider)
local MangoButton = require(script.Parent.MangoButton)
local MangoProtection = require(script.Parent.MangoProtection)

local module = {}

type FieldEntry = {
	name: string,
	fieldType: string,
	component: any,
	errorLabel: TextLabel,
}

function module.new(config: Types.MangoFormConfig): Types.MangoForm
	local theme = config.Theme
	local submitText = resolve(config.SubmitText, nil, "Submit") :: string
	local primaryTextColor = resolve(nil, theme and theme.PrimaryTextColor, Color3.fromRGB(0, 0, 0)) :: Color3
	local errorColor = resolve(nil, theme and theme.FormErrorColor, Color3.fromRGB(255, 59, 48)) :: Color3

	local fields: {FieldEntry} = {}
	local components: {any} = {}
	local isDestroyed = false

	-- Container
	local container = Instance.new("Frame")
	container.Name = MangoProtection.randomName("Form")
	container.Size = config.Size or UDim2.new(0, 300, 0, 0)
	container.AutomaticSize = Enum.AutomaticSize.Y
	container.Position = config.Position
	container.AnchorPoint = config.AnchorPoint or Vector2.new(0, 0)
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.Padding = UDim.new(0, 12)
	layout.Parent = container

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 12)
	padding.PaddingBottom = UDim.new(0, 12)
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.Parent = container

	-- Build fields
	for i, fieldConfig in config.Fields do
		local fieldContainer = Instance.new("Frame")
		fieldContainer.Name = "Field_" .. fieldConfig.Name
		fieldContainer.Size = UDim2.new(1, 0, 0, 0)
		fieldContainer.AutomaticSize = Enum.AutomaticSize.Y
		fieldContainer.BackgroundTransparency = 1
		fieldContainer.BorderSizePixel = 0
		fieldContainer.LayoutOrder = i
		fieldContainer.Parent = container

		local fieldLayout = Instance.new("UIListLayout")
		fieldLayout.SortOrder = Enum.SortOrder.LayoutOrder
		fieldLayout.FillDirection = Enum.FillDirection.Vertical
		fieldLayout.Padding = UDim.new(0, 4)
		fieldLayout.Parent = fieldContainer

		-- Label
		if fieldConfig.Label then
			local label = Instance.new("TextLabel")
			label.Name = "FieldLabel"
			label.Size = UDim2.new(1, 0, 0, 18)
			label.BackgroundTransparency = 1
			label.BorderSizePixel = 0
			label.Font = Enum.Font.GothamMedium
			label.TextSize = 13
			label.TextColor3 = primaryTextColor
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.LayoutOrder = 1
			if fieldConfig.Required then
				label.Text = fieldConfig.Label .. " <font color=\"rgb(255,59,48)\">*</font>"
				label.RichText = true
			else
				label.Text = fieldConfig.Label
			end
			label.Parent = fieldContainer
		end

		-- Component wrapper (for consistent sizing)
		local componentWrapper = Instance.new("Frame")
		componentWrapper.Name = "ComponentWrapper"
		componentWrapper.Size = UDim2.new(1, 0, 0, 36)
		componentWrapper.BackgroundTransparency = 1
		componentWrapper.BorderSizePixel = 0
		componentWrapper.LayoutOrder = 2
		componentWrapper.Parent = fieldContainer

		local component: any = nil
		local fieldType = fieldConfig.Type

		if fieldType == "text" then
			component = MangoTextField.new({
				Position = UDim2.new(0, 0, 0, 0),
				Size = UDim2.new(1, 0, 0, 36),
				Placeholder = fieldConfig.Placeholder,
				InitialText = fieldConfig.InitialValue :: string?,
				Theme = theme,
				Parent = componentWrapper,
			})
		elseif fieldType == "checkbox" then
			componentWrapper.Size = UDim2.new(1, 0, 0, 24)
			component = MangoCheckbox.new({
				Position = UDim2.new(0, 0, 0, 0),
				Label = nil,
				InitialState = fieldConfig.InitialValue :: boolean?,
				Theme = theme,
				Parent = componentWrapper,
			})
		elseif fieldType == "dropdown" then
			component = MangoDropdown.new({
				Position = UDim2.new(0, 0, 0, 0),
				Size = UDim2.new(1, 0, 0, 36),
				Items = fieldConfig.Items or {},
				InitialIndex = fieldConfig.InitialValue :: number?,
				Theme = theme,
				Parent = componentWrapper,
			})
		elseif fieldType == "slider" then
			component = MangoSlider.new({
				Position = UDim2.new(0, 0, 0, 0),
				Size = UDim2.new(1, 0, 0, 36),
				Min = fieldConfig.Min,
				Max = fieldConfig.Max,
				InitialValue = fieldConfig.InitialValue :: number?,
				Theme = theme,
				Parent = componentWrapper,
			})
		end

		-- Error label
		local errorLabel = Instance.new("TextLabel")
		errorLabel.Name = "ErrorLabel"
		errorLabel.Size = UDim2.new(1, 0, 0, 14)
		errorLabel.BackgroundTransparency = 1
		errorLabel.BorderSizePixel = 0
		errorLabel.Font = Enum.Font.Gotham
		errorLabel.TextSize = 11
		errorLabel.TextColor3 = errorColor
		errorLabel.TextXAlignment = Enum.TextXAlignment.Left
		errorLabel.Text = ""
		errorLabel.Visible = false
		errorLabel.LayoutOrder = 3
		errorLabel.Parent = fieldContainer

		if component then
			table.insert(components, component)
			table.insert(fields, {
				name = fieldConfig.Name,
				fieldType = fieldType,
				component = component,
				errorLabel = errorLabel,
			})
		end
	end

	-- GetValues
	local function getValues(): {[string]: any}
		local values: {[string]: any} = {}
		for _, field in fields do
			if field.fieldType == "text" then
				values[field.name] = field.component:GetText()
			elseif field.fieldType == "checkbox" then
				values[field.name] = field.component:GetState()
			elseif field.fieldType == "dropdown" then
				values[field.name] = field.component:GetSelectedIndex()
			elseif field.fieldType == "slider" then
				values[field.name] = field.component:GetValue()
			end
		end
		return values
	end

	-- Validate
	local function validate(): boolean
		local allValid = true
		for i, field in fields do
			local fieldConfig = config.Fields[i]
			local valid = true
			local errorMsg = ""

			-- Required check
			if fieldConfig.Required then
				if field.fieldType == "text" then
					local text = field.component:GetText()
					if text == "" then
						valid = false
						errorMsg = "This field is required"
					end
				elseif field.fieldType == "checkbox" then
					if not field.component:GetState() then
						valid = false
						errorMsg = "This field is required"
					end
				end
			end

			-- Custom validation
			if valid and fieldConfig.Validate then
				local value: any
				if field.fieldType == "text" then
					value = field.component:GetText()
				elseif field.fieldType == "checkbox" then
					value = field.component:GetState()
				elseif field.fieldType == "dropdown" then
					value = field.component:GetSelectedIndex()
				elseif field.fieldType == "slider" then
					value = field.component:GetValue()
				end

				local ok, msg = fieldConfig.Validate(value)
				if not ok then
					valid = false
					errorMsg = msg or "Invalid value"
				end
			end

			field.errorLabel.Visible = not valid
			field.errorLabel.Text = errorMsg
			if not valid then
				allValid = false
			end
		end
		return allValid
	end

	-- Submit button
	local submitWrapper = Instance.new("Frame")
	submitWrapper.Name = "SubmitWrapper"
	submitWrapper.Size = UDim2.new(1, 0, 0, 40)
	submitWrapper.BackgroundTransparency = 1
	submitWrapper.BorderSizePixel = 0
	submitWrapper.LayoutOrder = #config.Fields + 1
	submitWrapper.Parent = container

	local submitButton = MangoButton.new({
		Text = submitText,
		Theme = theme,
		Position = UDim2.new(0.5, 0, 0, 0),
		AnchorPoint = Vector2.new(0.5, 0),
		Parent = submitWrapper,
		OnActivated = function()
			if isDestroyed then return end
			if validate() then
				if config.OnSubmit then
					config.OnSubmit(getValues())
				end
			end
		end,
	})
	table.insert(components, submitButton)

	-- Parent
	if config.Parent then
		container.Parent = config.Parent
	end

	local self: Types.MangoForm = {
		Container = container,
		GetValues = function(self: Types.MangoForm): {[string]: any}
			return getValues()
		end,
		Validate = function(self: Types.MangoForm): boolean
			return validate()
		end,
		SetFieldValue = function(self: Types.MangoForm, name: string, value: any)
			for _, field in fields do
				if field.name == name then
					if field.fieldType == "text" then
						field.component:SetText(value :: string)
					elseif field.fieldType == "checkbox" then
						field.component:SetState(value :: boolean)
					elseif field.fieldType == "dropdown" then
						field.component:SetSelectedIndex(value :: number)
					elseif field.fieldType == "slider" then
						field.component:SetValue(value :: number)
					end
					return
				end
			end
		end,
		Destroy = function(self: Types.MangoForm)
			isDestroyed = true
			for _, comp in components do
				comp:Destroy()
			end
			container:Destroy()
		end,
	}

	return self
end

return module
