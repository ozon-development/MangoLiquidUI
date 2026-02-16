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
local MangoProtection = require(script.MangoProtection)

-- New modules
local MangoShimmer = require(script.MangoShimmer)
local MangoHaptics = require(script.MangoHaptics)
local MangoLayout = require(script.MangoLayout)
local MangoBadge = require(script.MangoBadge)
local MangoSkeleton = require(script.MangoSkeleton)
local MangoStepper = require(script.MangoStepper)
local MangoTooltip = require(script.MangoTooltip)
local MangoToast = require(script.MangoToast)
local MangoContextMenu = require(script.MangoContextMenu)
local MangoBottomSheet = require(script.MangoBottomSheet)
local MangoBlurProxy = require(script.MangoBlurProxy)
local MangoESP = require(script.MangoESP)
local MangoForm = require(script.MangoForm)
local MangoFocusManager = require(script.MangoFocusManager)
local MangoSaveManager = require(script.MangoSaveManager)
local MangoColorPicker = require(script.MangoColorPicker)
local MangoKeybind = require(script.MangoKeybind)
local MangoCarousel = require(script.MangoCarousel)
local MangoWindow = require(script.MangoWindow)
local MangoBuilder = require(script.MangoBuilder)

-- Existing type exports
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

-- New type exports
export type MangoShimmerConfig = Types.MangoShimmerConfig
export type MangoShimmer = Types.MangoShimmer
export type MangoLayoutConfig = Types.MangoLayoutConfig
export type MangoLayout = Types.MangoLayout
export type MangoBadgeConfig = Types.MangoBadgeConfig
export type MangoBadge = Types.MangoBadge
export type MangoSkeletonConfig = Types.MangoSkeletonConfig
export type MangoSkeleton = Types.MangoSkeleton
export type MangoStepperConfig = Types.MangoStepperConfig
export type MangoStepper = Types.MangoStepper
export type MangoTooltipConfig = Types.MangoTooltipConfig
export type MangoTooltip = Types.MangoTooltip
export type MangoToastConfig = Types.MangoToastConfig
export type MangoToast = Types.MangoToast
export type MangoToastStackConfig = Types.MangoToastStackConfig
export type MangoToastStack = Types.MangoToastStack
export type MangoContextMenuItemConfig = Types.MangoContextMenuItemConfig
export type MangoContextMenuConfig = Types.MangoContextMenuConfig
export type MangoContextMenu = Types.MangoContextMenu
export type MangoBottomSheetConfig = Types.MangoBottomSheetConfig
export type MangoBottomSheet = Types.MangoBottomSheet
export type MangoBlurProxyConfig = Types.MangoBlurProxyConfig
export type MangoBlurProxy = Types.MangoBlurProxy
export type MangoESPConfig = Types.MangoESPConfig
export type MangoESPAddConfig = Types.MangoESPAddConfig
export type MangoESPHandle = Types.MangoESPHandle
export type MangoESP = Types.MangoESP
export type MangoFormFieldConfig = Types.MangoFormFieldConfig
export type MangoFormConfig = Types.MangoFormConfig
export type MangoForm = Types.MangoForm
export type MangoFocusManagerConfig = Types.MangoFocusManagerConfig
export type MangoFocusManager = Types.MangoFocusManager
export type MangoColorPickerConfig = Types.MangoColorPickerConfig
export type MangoColorPicker = Types.MangoColorPicker
export type MangoKeybindConfig = Types.MangoKeybindConfig
export type MangoKeybind = Types.MangoKeybind
export type MangoCarouselConfig = Types.MangoCarouselConfig
export type MangoCarousel = Types.MangoCarousel
export type MangoCarouselTabConfig = Types.MangoCarouselTabConfig
export type MangoSaveManagerConfig = Types.MangoSaveManagerConfig
export type MangoSaveManager = Types.MangoSaveManager
export type MangoWindowConfig = Types.MangoWindowConfig
export type MangoWindow = Types.MangoWindow
export type MangoWindowTab = Types.MangoWindowTab
export type MangoWindowElement = Types.MangoWindowElement
export type MangoBuilder = Types.MangoBuilder
export type MangoProtectionConfig = Types.MangoProtectionConfig

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

	-- New full module names
	MangoShimmer = MangoShimmer,
	MangoHaptics = MangoHaptics,
	MangoLayout = MangoLayout,
	MangoBadge = MangoBadge,
	MangoSkeleton = MangoSkeleton,
	MangoStepper = MangoStepper,
	MangoTooltip = MangoTooltip,
	MangoToast = MangoToast,
	MangoContextMenu = MangoContextMenu,
	MangoBottomSheet = MangoBottomSheet,
	MangoBlurProxy = MangoBlurProxy,
	MangoESP = MangoESP,
	MangoForm = MangoForm,
	MangoFocusManager = MangoFocusManager,
	MangoSaveManager = MangoSaveManager,
	MangoColorPicker = MangoColorPicker,
	MangoKeybind = MangoKeybind,
	MangoCarousel = MangoCarousel,
	MangoWindow = MangoWindow,
	MangoBuilder = MangoBuilder,
	MangoProtection = MangoProtection,

	-- Theme shortcuts
	Light = Themes.Light,
	Dark = Themes.Dark,
	Mango = Themes.Mango,
	Mint = Themes.Mint,

	-- Intro module shortcut
	intro = MangoIntro,

	-- Haptics module shortcut
	haptic = MangoHaptics,
}

-- Existing short-name constructors
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

-- New short-name constructors
function MangoLiquidUI.shimr(config: Types.MangoShimmerConfig): Types.MangoShimmer return MangoShimmer.new(config) end
function MangoLiquidUI.layout(config: Types.MangoLayoutConfig): Types.MangoLayout return MangoLayout.new(config) end
function MangoLiquidUI.bdg(config: Types.MangoBadgeConfig): Types.MangoBadge return MangoBadge.new(config) end
function MangoLiquidUI.skel(config: Types.MangoSkeletonConfig): Types.MangoSkeleton return MangoSkeleton.new(config) end
function MangoLiquidUI.step(config: Types.MangoStepperConfig): Types.MangoStepper return MangoStepper.new(config) end
function MangoLiquidUI.tip(config: Types.MangoTooltipConfig): Types.MangoTooltip return MangoTooltip.new(config) end
function MangoLiquidUI.toast(config: Types.MangoToastConfig): Types.MangoToast return MangoToast.new(config) end
function MangoLiquidUI.tstack(config: Types.MangoToastStackConfig): Types.MangoToastStack return MangoToast.newStack(config) end
function MangoLiquidUI.ctx(config: Types.MangoContextMenuConfig): Types.MangoContextMenu return MangoContextMenu.new(config) end
function MangoLiquidUI.bsheet(config: Types.MangoBottomSheetConfig): Types.MangoBottomSheet return MangoBottomSheet.new(config) end
function MangoLiquidUI.blur(config: Types.MangoBlurProxyConfig): Types.MangoBlurProxy return MangoBlurProxy.new(config) end
function MangoLiquidUI.esp(config: Types.MangoESPConfig): Types.MangoESP return MangoESP.new(config) end
function MangoLiquidUI.form(config: Types.MangoFormConfig): Types.MangoForm return MangoForm.new(config) end
function MangoLiquidUI.focus(config: Types.MangoFocusManagerConfig): Types.MangoFocusManager return MangoFocusManager.new(config) end
function MangoLiquidUI.colr(config: Types.MangoColorPickerConfig): Types.MangoColorPicker return MangoColorPicker.new(config) end
function MangoLiquidUI.key(config: Types.MangoKeybindConfig): Types.MangoKeybind return MangoKeybind.new(config) end
function MangoLiquidUI.carousel(config: Types.MangoCarouselConfig): Types.MangoCarousel return MangoCarousel.new(config) end
function MangoLiquidUI.csel(config: Types.MangoCarouselConfig): Types.MangoCarousel return MangoCarousel.new(config) end
function MangoLiquidUI.window(config: Types.MangoWindowConfig): Types.MangoWindow return MangoWindow.new(config) end
function MangoLiquidUI.build(componentType: string): Types.MangoBuilder return MangoBuilder.build(componentType) end
function MangoLiquidUI.protect(config: Types.MangoProtectionConfig) MangoProtection.configure(config) end
function MangoLiquidUI.isProtected(): boolean return MangoProtection.isProtected() end
function MangoLiquidUI.protectionLevel(): string return MangoProtection.getProtectionLevel() end

-- ScreenGui helper
function MangoLiquidUI.gui(name: string?): ScreenGui
	local gui = MangoProtection.createScreenGui({})
	if name and not MangoProtection.isProtected() then
		gui.Name = name
	end
	return gui
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
