--!strict

local Types = require(script.Parent.Types)

local module = {}

-- Component type to module name mapping
local COMPONENT_MAP: {[string]: string} = {
    button = "MangoButton",
    slider = "MangoSlider",
    toggle = "MangoToggle",
    checkbox = "MangoCheckbox",
    dialog = "MangoDialog",
    actionsheet = "MangoActionSheet",
    dropdown = "MangoDropdown",
    tabbar = "MangoTabBar",
    search = "MangoSearchBar",
    textfield = "MangoTextField",
    progress = "MangoProgressBar",
    glass = "MangoGlassFrame",
    notification = "MangoNotification",
    notifstack = "MangoNotificationStack",
    segmented = "MangoSegmentedControl",
    billboard = "MangoBillboardLabel",
    badge = "MangoBadge",
    skeleton = "MangoSkeleton",
    stepper = "MangoStepper",
    tooltip = "MangoTooltip",
    toast = "MangoToast",
    contextmenu = "MangoContextMenu",
    bottomsheet = "MangoBottomSheet",
    blur = "MangoBlurProxy",
    form = "MangoForm",
    focus = "MangoFocusManager",
    layout = "MangoLayout",
    shimmer = "MangoShimmer",
    window = "MangoWindow",
    carousel = "MangoCarousel",
    colorpicker = "MangoColorPicker",
    keybind = "MangoKeybind",
    savemanager = "MangoSaveManager",
}

function module.build(componentType: string): Types.MangoBuilder
    local moduleName = COMPONENT_MAP[componentType]
    if not moduleName then
        error("Unknown component type: " .. componentType)
    end

    local config: {[string]: any} = {}
    local componentModule: any = nil

    -- Lazy-load the component module
    local function getModule(): any
        if componentModule then return componentModule end
        componentModule = require(script.Parent:FindFirstChild(moduleName) :: ModuleScript)
        return componentModule
    end

    local self: Types.MangoBuilder
    self = {
        text = function(self: Types.MangoBuilder, text: string): Types.MangoBuilder
            config.Text = text
            return self
        end,
        theme = function(self: Types.MangoBuilder, theme: Types.ThemePreset): Types.MangoBuilder
            config.Theme = theme
            return self
        end,
        pos = function(self: Types.MangoBuilder, xScale: number, xOffset: number, yScale: number, yOffset: number): Types.MangoBuilder
            config.Position = UDim2.new(xScale, xOffset, yScale, yOffset)
            return self
        end,
        anchor = function(self: Types.MangoBuilder, x: number, y: number): Types.MangoBuilder
            config.AnchorPoint = Vector2.new(x, y)
            return self
        end,
        size = function(self: Types.MangoBuilder, xScale: number, xOffset: number, yScale: number, yOffset: number): Types.MangoBuilder
            config.Size = UDim2.new(xScale, xOffset, yScale, yOffset)
            return self
        end,
        parent = function(self: Types.MangoBuilder, parent: GuiObject): Types.MangoBuilder
            config.Parent = parent
            return self
        end,
        onClick = function(self: Types.MangoBuilder, callback: () -> ()): Types.MangoBuilder
            config.OnActivated = callback
            return self
        end,
        onChange = function(self: Types.MangoBuilder, callback: (value: any) -> ()): Types.MangoBuilder
            config.OnChanged = callback
            config.OnToggled = callback
            config.OnTextChanged = callback
            return self
        end,
        prop = function(self: Types.MangoBuilder, key: string, value: any): Types.MangoBuilder
            config[key] = value
            return self
        end,
        create = function(self: Types.MangoBuilder): any
            local mod = getModule()
            return mod.new(config)
        end,
    }

    return self
end

return module
