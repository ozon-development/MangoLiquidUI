--!strict

local Types = require(script.Parent.Types)
local Themes = require(script.Parent.Themes)
local resolve = Themes.resolve
local UserInputService = game:GetService("UserInputService")

local module = {}

function module.new(config: Types.MangoFocusManagerConfig): Types.MangoFocusManager
    local inputs: {GuiObject} = {}
    for _, input in config.Inputs do
        table.insert(inputs, input)
    end

    local enabled = resolve(config.Enabled, nil, true) :: boolean
    local currentIndex = 0
    local connections: {RBXScriptConnection} = {}
    local focusRing: UIStroke? = nil
    local isDestroyed = false

    local function findTextBox(gui: GuiObject): TextBox?
        if gui:IsA("TextBox") then
            return gui :: TextBox
        end
        local found = gui:FindFirstChildWhichIsA("TextBox", true)
        if found then
            return found :: TextBox
        end
        return nil
    end

    local function clearFocusRing()
        if focusRing then
            focusRing:Destroy()
            focusRing = nil
        end
    end

    local function applyFocusRing(target: GuiObject)
        clearFocusRing()
        local ring = Instance.new("UIStroke")
        ring.Name = "FocusRing"
        ring.Color = Color3.fromRGB(0, 122, 255)
        ring.Thickness = 2
        ring.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        ring.Parent = target
        focusRing = ring
    end

    local function focusAtIndex(index: number)
        if index < 1 or index > #inputs then return end
        currentIndex = index
        local target = inputs[index]
        local textBox = findTextBox(target)
        if textBox then
            textBox:CaptureFocus()
        end
        applyFocusRing(target)
    end

    -- Keyboard listener
    local inputConn = UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
        if not enabled or isDestroyed or gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.Tab then
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift) then
                -- Shift+Tab = previous
                local newIndex = currentIndex - 1
                if newIndex < 1 then newIndex = #inputs end
                focusAtIndex(newIndex)
            else
                -- Tab = next
                local newIndex = currentIndex + 1
                if newIndex > #inputs then newIndex = 1 end
                focusAtIndex(newIndex)
            end
        elseif input.KeyCode == Enum.KeyCode.Return then
            if config.SubmitCallback then
                config.SubmitCallback()
            end
        elseif input.KeyCode == Enum.KeyCode.Escape then
            clearFocusRing()
            currentIndex = 0
            if config.DismissCallback then
                config.DismissCallback()
            end
        end
    end)
    table.insert(connections, inputConn)

    local self: Types.MangoFocusManager = {
        Register = function(self: Types.MangoFocusManager, input: GuiObject)
            table.insert(inputs, input)
        end,
        Unregister = function(self: Types.MangoFocusManager, input: GuiObject)
            for i, v in inputs do
                if v == input then
                    table.remove(inputs, i)
                    if currentIndex >= i then
                        currentIndex = math.max(0, currentIndex - 1)
                    end
                    break
                end
            end
        end,
        FocusNext = function(self: Types.MangoFocusManager)
            local newIndex = currentIndex + 1
            if newIndex > #inputs then newIndex = 1 end
            focusAtIndex(newIndex)
        end,
        FocusPrevious = function(self: Types.MangoFocusManager)
            local newIndex = currentIndex - 1
            if newIndex < 1 then newIndex = #inputs end
            focusAtIndex(newIndex)
        end,
        FocusIndex = function(self: Types.MangoFocusManager, index: number)
            focusAtIndex(index)
        end,
        SetEnabled = function(self: Types.MangoFocusManager, value: boolean)
            enabled = value
            if not value then
                clearFocusRing()
                currentIndex = 0
            end
        end,
        Destroy = function(self: Types.MangoFocusManager)
            isDestroyed = true
            clearFocusRing()
            for _, conn in connections do
                conn:Disconnect()
            end
            table.clear(connections)
            table.clear(inputs)
        end,
    }

    return self
end

return module
