--!strict

local Types = require(script.Types)
local MangoGlassFrame = require(script.MangoGlassFrame)
local RefractionProxy = require(script.RefractionProxy)
local LiquidFusion = require(script.LiquidFusion)
local MangoToggle = require(script.MangoToggle)
local MangoSlider = require(script.MangoSlider)
local MangoButton = require(script.MangoButton)
local MangoBillboardLabel = require(script.MangoBillboardLabel)
local MangoNotification = require(script.MangoNotification)
local MangoNotificationStack = require(script.MangoNotificationStack)
local MangoSegmentedControl = require(script.MangoSegmentedControl)
local MangoDropdown = require(script.MangoDropdown)
local MangoTabBar = require(script.MangoTabBar)
local MangoSearchBar = require(script.MangoSearchBar)
local MangoTextField = require(script.MangoTextField)
local MangoCheckbox = require(script.MangoCheckbox)
local MangoProgressBar = require(script.MangoProgressBar)
local MangoDialog = require(script.MangoDialog)
local MangoActionSheet = require(script.MangoActionSheet)
local MangoEnvironmentLight = require(script.MangoEnvironmentLight)
local MangoIntro = require(script.MangoIntro)
local Themes = require(script.Themes)

export type ThemePreset = Types.ThemePreset
export type MangoGlassConfig = Types.MangoGlassConfig
export type RefractionProxyConfig = Types.RefractionProxyConfig
export type LiquidFusionConfig = Types.LiquidFusionConfig
export type MangoToggleConfig = Types.MangoToggleConfig
export type MangoSliderConfig = Types.MangoSliderConfig
export type MangoButtonConfig = Types.MangoButtonConfig
export type MangoBillboardLabelConfig = Types.MangoBillboardLabelConfig
export type MangoNotificationConfig = Types.MangoNotificationConfig
export type MangoGlassFrame = Types.MangoGlassFrame
export type RefractionProxy = Types.RefractionProxy
export type LiquidFusionController = Types.LiquidFusionController
export type MangoToggle = Types.MangoToggle
export type MangoSlider = Types.MangoSlider
export type MangoButton = Types.MangoButton
export type MangoBillboardLabel = Types.MangoBillboardLabel
export type MangoNotification = Types.MangoNotification
export type MangoEnvironmentLightConfig = Types.MangoEnvironmentLightConfig
export type MangoEnvironmentLight = Types.MangoEnvironmentLight
export type MangoNotificationStackConfig = Types.MangoNotificationStackConfig
export type MangoNotificationStack = Types.MangoNotificationStack
export type MangoSegmentedControlConfig = Types.MangoSegmentedControlConfig
export type MangoSegmentedControl = Types.MangoSegmentedControl
export type MangoDropdownConfig = Types.MangoDropdownConfig
export type MangoDropdown = Types.MangoDropdown
export type MangoTabBarConfig = Types.MangoTabBarConfig
export type MangoTabBar = Types.MangoTabBar
export type MangoSearchBarConfig = Types.MangoSearchBarConfig
export type MangoSearchBar = Types.MangoSearchBar
export type MangoTextFieldConfig = Types.MangoTextFieldConfig
export type MangoTextField = Types.MangoTextField
export type MangoCheckboxConfig = Types.MangoCheckboxConfig
export type MangoCheckbox = Types.MangoCheckbox
export type MangoProgressBarConfig = Types.MangoProgressBarConfig
export type MangoProgressBar = Types.MangoProgressBar
export type MangoDialogConfig = Types.MangoDialogConfig
export type MangoDialogButtonConfig = Types.MangoDialogButtonConfig
export type MangoDialog = Types.MangoDialog
export type MangoActionSheetConfig = Types.MangoActionSheetConfig
export type MangoActionSheetActionConfig = Types.MangoActionSheetActionConfig
export type MangoActionSheet = Types.MangoActionSheet
export type MangoIntroConfig = Types.MangoIntroConfig

local MangoLiquidUI = {
	-- Full module names (backward compat)
	MangoGlassFrame = MangoGlassFrame,
	RefractionProxy = RefractionProxy,
	LiquidFusion = LiquidFusion,
	MangoToggle = MangoToggle,
	MangoSlider = MangoSlider,
	MangoButton = MangoButton,
	MangoBillboardLabel = MangoBillboardLabel,
	MangoNotification = MangoNotification,
	MangoNotificationStack = MangoNotificationStack,
	MangoSegmentedControl = MangoSegmentedControl,
	MangoDropdown = MangoDropdown,
	MangoTabBar = MangoTabBar,
	MangoSearchBar = MangoSearchBar,
	MangoTextField = MangoTextField,
	MangoCheckbox = MangoCheckbox,
	MangoProgressBar = MangoProgressBar,
	MangoDialog = MangoDialog,
	MangoActionSheet = MangoActionSheet,
	MangoEnvironmentLight = MangoEnvironmentLight,
	MangoIntro = MangoIntro,
	Themes = Themes,

	-- Theme shortcuts
	Light = Themes.Light,
	Dark = Themes.Dark,
	Mango = Themes.Mango,
	Mint = Themes.Mint,

	-- Intro module shortcut
	intro = MangoIntro,
}

-- Short-name constructors
function MangoLiquidUI.bttn(config: Types.MangoButtonConfig): Types.MangoButton return MangoButton.new(config) end
function MangoLiquidUI.sldr(config: Types.MangoSliderConfig): Types.MangoSlider return MangoSlider.new(config) end
function MangoLiquidUI.tgl(config: Types.MangoToggleConfig): Types.MangoToggle return MangoToggle.new(config) end
function MangoLiquidUI.chk(config: Types.MangoCheckboxConfig): Types.MangoCheckbox return MangoCheckbox.new(config) end
function MangoLiquidUI.dlg(config: Types.MangoDialogConfig): Types.MangoDialog return MangoDialog.new(config) end
function MangoLiquidUI.act(config: Types.MangoActionSheetConfig): Types.MangoActionSheet return MangoActionSheet.new(config) end
function MangoLiquidUI.drp(config: Types.MangoDropdownConfig): Types.MangoDropdown return MangoDropdown.new(config) end
function MangoLiquidUI.tab(config: Types.MangoTabBarConfig): Types.MangoTabBar return MangoTabBar.new(config) end
function MangoLiquidUI.srch(config: Types.MangoSearchBarConfig): Types.MangoSearchBar return MangoSearchBar.new(config) end
function MangoLiquidUI.txt(config: Types.MangoTextFieldConfig): Types.MangoTextField return MangoTextField.new(config) end
function MangoLiquidUI.prog(config: Types.MangoProgressBarConfig): Types.MangoProgressBar return MangoProgressBar.new(config) end
function MangoLiquidUI.glass(config: Types.MangoGlassConfig): Types.MangoGlassFrame return MangoGlassFrame.new(config) end
function MangoLiquidUI.notif(config: Types.MangoNotificationConfig): Types.MangoNotification return MangoNotification.new(config) end
function MangoLiquidUI.nstack(config: Types.MangoNotificationStackConfig): Types.MangoNotificationStack return MangoNotificationStack.new(config) end
function MangoLiquidUI.seg(config: Types.MangoSegmentedControlConfig): Types.MangoSegmentedControl return MangoSegmentedControl.new(config) end
function MangoLiquidUI.bbl(config: Types.MangoBillboardLabelConfig): Types.MangoBillboardLabel return MangoBillboardLabel.new(config) end
function MangoLiquidUI.env(config: Types.MangoEnvironmentLightConfig): Types.MangoEnvironmentLight return MangoEnvironmentLight.new(config) end
function MangoLiquidUI.refr(config: Types.RefractionProxyConfig): Types.RefractionProxy return RefractionProxy.new(config) end
function MangoLiquidUI.fuse(config: Types.LiquidFusionConfig): Types.LiquidFusionController return LiquidFusion.new(config) end

-- ScreenGui helper
function MangoLiquidUI.gui(name: string?): ScreenGui
	local player = game:GetService("Players").LocalPlayer
	local g = Instance.new("ScreenGui")
	g.Name = name or "MangoUI"
	g.ResetOnSpawn = false
	g.IgnoreGuiInset = true
	g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	g.Parent = player:WaitForChild("PlayerGui")
	return g
end

--[[
	Theme transition helper: fades out existing glass frames, calls rebuildCallback
	to create new ones with the new theme, then fades the new frames in.
	NumberSequence (UIGradient.Transparency) cannot be tweened, so this
	provides a smooth visual transition around the destroy+rebuild pattern.
]]
function MangoLiquidUI.transitionTheme(
	glassFrames: {Types.MangoGlassFrame},
	fadeDuration: number,
	rebuildCallback: () -> {Types.MangoGlassFrame}
): ()
	local TweenService = game:GetService("TweenService")
	local fadeInfo = TweenInfo.new(fadeDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local pending = #glassFrames
	if pending == 0 then
		rebuildCallback()
		return
	end
	for _, glass in glassFrames do
		for _, shadow in glass.ShadowLayers do
			shadow.Visible = false
		end
		local tween = TweenService:Create(glass.GlassSurface, fadeInfo, { BackgroundTransparency = 1 })
		tween.Completed:Connect(function()
			pending -= 1
			if pending <= 0 then
				local newFrames = rebuildCallback()
				local fadeInInfo = TweenInfo.new(fadeDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
				for _, newGlass in newFrames do
					local targetTransp = newGlass.GlassSurface.BackgroundTransparency
					newGlass.GlassSurface.BackgroundTransparency = 1
					TweenService:Create(newGlass.GlassSurface, fadeInInfo, { BackgroundTransparency = targetTransp }):Play()
				end
			end
		end)
		tween:Play()
	end
end

-- Auto-play intro on require
task.spawn(function()
	MangoIntro.play()
end)

return MangoLiquidUI
