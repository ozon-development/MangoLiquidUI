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
    esp = "MangoESP",
}

function module.build(componentType: string): Types.MangoBuilder
    local moduleName = COMPONENT_MAP[componentType]
    if not moduleName then
        error("Unknown component type: " .. componentType)
    end

    local config: {[string]: any} = {}
    local componentModule: any = nil

    -- Lazy-load the component module
    -- Uses a lookup table of standard require() calls so build.sh can transform them
    local MODULE_LOADERS: {[string]: () -> any} = {
        MangoButton = function() return require(script.Parent.MangoButton) end,
        MangoSlider = function() return require(script.Parent.MangoSlider) end,
        MangoToggle = function() return require(script.Parent.MangoToggle) end,
        MangoCheckbox = function() return require(script.Parent.MangoCheckbox) end,
        MangoDialog = function() return require(script.Parent.MangoDialog) end,
        MangoActionSheet = function() return require(script.Parent.MangoActionSheet) end,
        MangoDropdown = function() return require(script.Parent.MangoDropdown) end,
        MangoTabBar = function() return require(script.Parent.MangoTabBar) end,
        MangoSearchBar = function() return require(script.Parent.MangoSearchBar) end,
        MangoTextField = function() return require(script.Parent.MangoTextField) end,
        MangoProgressBar = function() return require(script.Parent.MangoProgressBar) end,
        MangoGlassFrame = function() return require(script.Parent.MangoGlassFrame) end,
        MangoNotification = function() return require(script.Parent.MangoNotification) end,
        MangoNotificationStack = function() return require(script.Parent.MangoNotificationStack) end,
        MangoSegmentedControl = function() return require(script.Parent.MangoSegmentedControl) end,
        MangoBillboardLabel = function() return require(script.Parent.MangoBillboardLabel) end,
        MangoBadge = function() return require(script.Parent.MangoBadge) end,
        MangoSkeleton = function() return require(script.Parent.MangoSkeleton) end,
        MangoStepper = function() return require(script.Parent.MangoStepper) end,
        MangoTooltip = function() return require(script.Parent.MangoTooltip) end,
        MangoToast = function() return require(script.Parent.MangoToast) end,
        MangoContextMenu = function() return require(script.Parent.MangoContextMenu) end,
        MangoBottomSheet = function() return require(script.Parent.MangoBottomSheet) end,
        MangoBlurProxy = function() return require(script.Parent.MangoBlurProxy) end,
        MangoForm = function() return require(script.Parent.MangoForm) end,
        MangoFocusManager = function() return require(script.Parent.MangoFocusManager) end,
        MangoLayout = function() return require(script.Parent.MangoLayout) end,
        MangoShimmer = function() return require(script.Parent.MangoShimmer) end,
        MangoWindow = function() return require(script.Parent.MangoWindow) end,
        MangoCarousel = function() return require(script.Parent.MangoCarousel) end,
        MangoColorPicker = function() return require(script.Parent.MangoColorPicker) end,
        MangoKeybind = function() return require(script.Parent.MangoKeybind) end,
        MangoSaveManager = function() return require(script.Parent.MangoSaveManager) end,
        MangoESP = function() return require(script.Parent.MangoESP) end,
    }

    local function getModule(): any
        if componentModule then return componentModule end
        local loader = MODULE_LOADERS[moduleName]
        if not loader then
            error("No loader for module: " .. moduleName)
        end
        componentModule = loader()
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
