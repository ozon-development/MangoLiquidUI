--!strict

export type ThemePreset = {
	-- Glass surface
	BackgroundColor3: Color3,
	BackgroundTransparency: number,

	-- Lens (saturation tint via CanvasGroup)
	LensGroupColor3: Color3,
	LensGroupTransparency: number,

	-- Inner glow
	InnerGlowColor: Color3,
	InnerGlowTransparency: number,
	InnerGlowHeight: number, -- 0-1 fraction of parent height

	-- Inner edge highlight (full-perimeter inner shadow)
	InnerEdgeColor: Color3?,
	InnerEdgeTopTransparency: number?,
	InnerEdgeMidTransparency: number?,
	InnerEdgeBottomTransparency: number?,

	-- Fresnel rim (directional UIStroke)
	StrokeColor: Color3,
	StrokeThickness: number,
	FresnelStartTransparency: number, -- top edge
	FresnelEndTransparency: number, -- bottom edge
	FresnelMidTransparency: number, -- center keypoint transparency (brighter = lower)
	FresnelMidPoint: number, -- position of center keypoint (0-1, default 0.35)
	FresnelAngle: number, -- rotation in degrees (90 = top-lit)

	-- Shadow
	ShadowColor: Color3,
	ShadowTransparency: number, -- controls overall shadow intensity (higher = more subtle)
	ShadowSpread: number, -- px spread for outermost layer
	ShadowOffsetX: number, -- px horizontal offset
	ShadowOffsetY: number, -- px vertical offset

	-- Refraction proxy
	GlassColor: Color3,
	GlassTransparency: number,
	GlassReflectance: number,

	-- Noise
	NoiseOpacity: number,

	-- Text
	PrimaryTextColor: Color3,
	SecondaryTextColor: Color3,

	-- Toggle
	ToggleOnTrackColor: Color3?,
	ToggleOffTrackColor: Color3?,
	ToggleKnobColor: Color3?,

	-- Slider
	SliderTrackColor: Color3?,
	SliderFillColor: Color3?,
	SliderThumbColor: Color3?,

	-- Slider (glass track)
	SliderTrackTransparency: number?,
	SliderFillTransparency: number?,

	-- Button
	ButtonPressScale: number?,
	ButtonBackgroundTransparency: number?,

	-- Parallax
	ParallaxIntensity: number?,

	-- Notification stacking
	NotificationStackGap: number?,
	NotificationMaxVisible: number?,

	-- Segmented control
	SegmentedBackgroundTransparency: number?,
	SegmentedSelectedTransparency: number?,
	SegmentedSelectedColor: Color3?,

	-- Dropdown
	DropdownBackgroundTransparency: number?,
	DropdownItemHoverColor: Color3?,
	DropdownItemHoverTransparency: number?,

	-- Tab bar
	TabBarBackgroundTransparency: number?,
	TabBarSelectedColor: Color3?,
	TabBarIconColor: Color3?,
	TabBarIconSelectedColor: Color3?,

	-- Search bar
	SearchBarBackgroundTransparency: number?,
	SearchBarPlaceholderColor: Color3?,

	-- Text field
	TextFieldBackgroundTransparency: number?,
	TextFieldBorderColor: Color3?,
	TextFieldFocusBorderColor: Color3?,

	-- Checkbox
	CheckboxOnColor: Color3?,
	CheckboxOffColor: Color3?,
	CheckboxCheckColor: Color3?,

	-- Progress bar
	ProgressBarTrackTransparency: number?,
	ProgressBarFillColor: Color3?,
	ProgressBarFillTransparency: number?,

	-- Dialog
	DialogOverlayTransparency: number?,
	DialogBackgroundTransparency: number?,

	-- Shimmer
	ShimmerColor: Color3?,
	ShimmerTransparency: number?,

	-- Badge
	BadgeBackgroundColor: Color3?,
	BadgeBackgroundTransparency: number?,
	BadgeTextColor: Color3?,

	-- Tooltip
	TooltipBackgroundTransparency: number?,

	-- Stepper
	StepperBackgroundTransparency: number?,

	-- Skeleton
	SkeletonBackgroundColor: Color3?,
	SkeletonBackgroundTransparency: number?,

	-- Toast
	ToastBackgroundTransparency: number?,

	-- Bottom Sheet
	BottomSheetBackgroundTransparency: number?,
	BottomSheetHandleColor: Color3?,

	-- Blur Proxy
	BlurTintColor: Color3?,
	BlurTintTransparency: number?,

	-- Form
	FormErrorColor: Color3?,

	-- Focus Manager
	FocusRingColor: Color3?,

	-- Window
	WindowBackgroundTransparency: number?,
	WindowTitleColor: Color3?,

	-- Color Picker
	ColorPickerCursorColor: Color3?,

	-- Keybind
	KeybindPillTransparency: number?,
	KeybindListeningColor: Color3?,

	-- Accent color (used by many components)
	AccentColor: Color3?,
}

export type MangoGlassConfig = {
	Size: UDim2,
	Position: UDim2,
	AnchorPoint: Vector2?,
	CornerRadius: UDim?,
	BackgroundColor3: Color3?,
	BackgroundTransparency: number?,
	NoiseOpacity: number?,
	NoiseImageId: string?,
	FresnelStartTransparency: number?,
	FresnelEndTransparency: number?,
	FresnelMidTransparency: number?,
	FresnelMidPoint: number?,
	FresnelAngle: number?,
	StrokeThickness: number?,
	StrokeColor: Color3?,
	InnerGlowTransparency: number?,
	InnerGlowColor: Color3?,
	InnerGlowHeight: number?,
	InnerEdgeColor: Color3?,
	InnerEdgeTopTransparency: number?,
	InnerEdgeMidTransparency: number?,
	InnerEdgeBottomTransparency: number?,
	LensGroupColor3: Color3?,
	LensGroupTransparency: number?,
	ShadowColor: Color3?,
	ShadowTransparency: number?,
	ShadowSpread: number?,
	ShadowOffsetX: number?,
	ShadowOffsetY: number?,
	ShadowEnabled: boolean?,
	ShadowLayerCount: number?, -- Number of shadow layers (default 6, max 12)
	LightweightMode: boolean?, -- Skip CanvasGroups for small elements like buttons
	ParallaxEnabled: boolean?,
	ParallaxIntensity: number?,
	Theme: ThemePreset?,
	Parent: GuiObject?,
}

export type RefractionProxyConfig = {
	TargetGui: GuiObject,
	GlassTransparency: number?,
	GlassMaterial: Enum.Material?,
	GlassColor: Color3?,
	GlassReflectance: number?,
	GlassThickness: number?,
	OffsetDepth: number?,
	Enabled: boolean?,
	ViewportMode: boolean?,
	Theme: ThemePreset?,
}

export type LiquidFusionConfig = {
	Target: GuiObject,
	BulgeScale: number?,
	BulgeDuration: number?,
	RestoreDuration: number?,
	SpecularShiftOffset: UDim2?,
	UseUIScale: boolean?,
}

export type MangoToggleConfig = {
	Position: UDim2,
	AnchorPoint: Vector2?,
	Scale: number?,
	Theme: ThemePreset?,
	InitialState: boolean?,
	OnToggled: ((state: boolean) -> ())?,
	Parent: GuiObject?,
}

export type MangoSliderConfig = {
	Position: UDim2,
	Size: UDim2?,
	AnchorPoint: Vector2?,
	Theme: ThemePreset?,
	InitialValue: number?,
	Min: number?,
	Max: number?,
	Step: number?,
	OnChanged: ((value: number) -> ())?,
	Parent: GuiObject?,
}

export type MangoButtonConfig = {
	Position: UDim2,
	Size: UDim2?,
	AnchorPoint: Vector2?,
	Text: string,
	TextSize: number?,
	BackgroundTransparency: number?,
	Theme: ThemePreset?,
	OnActivated: (() -> ())?,
	Parent: GuiObject?,
}

export type MangoBillboardLabelConfig = {
	TargetPart: BasePart?,
	TargetCharacter: Model?,
	Text: string,
	TextSize: number?,
	Theme: ThemePreset?,
	MaxDistance: number?,
	StudsOffset: Vector3?,
	AlwaysOnTop: boolean?,
	Parent: Instance?,
}

export type MangoGlassFrame = {
	Container: Frame,
	Frame: Frame, -- alias for Container (backward compat)
	GlassSurface: Frame,
	ShadowLayers: {Frame},
	LensGroup: CanvasGroup?, -- nil in LightweightMode
	TextureGroup: CanvasGroup?, -- nil in LightweightMode
	NoiseLabel: ImageLabel?, -- nil in LightweightMode
	InnerHighlight: Frame?, -- nil in LightweightMode
	InnerEdgeFrame: Frame,
	InnerEdgeStroke: UIStroke,
	InnerEdgeGradient: UIGradient,
	SpecularFrame: Frame,
	SpecularStroke: UIStroke,
	SpecularGradient: UIGradient,
	SetLightDirection: (self: MangoGlassFrame, angle: number) -> (),
	SetParallaxEnabled: (self: MangoGlassFrame, enabled: boolean) -> (),
	Destroy: (self: MangoGlassFrame) -> (),
}

export type RefractionProxy = {
	GlassPart: Part,
	Enabled: boolean,
	SetEnabled: (self: RefractionProxy, enabled: boolean) -> (),
	UpdateTarget: (self: RefractionProxy, newGui: GuiObject) -> (),
	Destroy: (self: RefractionProxy) -> (),
}

export type LiquidFusionController = {
	Connect: (self: LiquidFusionController) -> (),
	Disconnect: (self: LiquidFusionController) -> (),
	TweenProperty: (self: LiquidFusionController, property: string, target: any, duration: number?) -> Tween,
	Destroy: (self: LiquidFusionController) -> (),
}

export type MangoToggle = {
	Container: Frame,
	SetState: (self: MangoToggle, state: boolean) -> (),
	GetState: (self: MangoToggle) -> boolean,
	Destroy: (self: MangoToggle) -> (),
}

export type MangoSlider = {
	Container: Frame,
	SetValue: (self: MangoSlider, value: number) -> (),
	GetValue: (self: MangoSlider) -> number,
	Destroy: (self: MangoSlider) -> (),
}

export type MangoButton = {
	Container: Frame,
	GlassSurface: Frame,
	TextLabel: TextLabel,
	SetText: (self: MangoButton, text: string) -> (),
	Destroy: (self: MangoButton) -> (),
}

export type MangoBillboardLabel = {
	BillboardGui: BillboardGui,
	GlassSurface: Frame,
	TextLabel: TextLabel,
	SetText: (self: MangoBillboardLabel, text: string) -> (),
	Destroy: (self: MangoBillboardLabel) -> (),
}

export type MangoNotificationConfig = {
	Title: string,
	Body: string?,
	Icon: string?,
	Duration: number?,
	Type: string?,
	Actions: {MangoNotificationActionConfig}?,
	Theme: ThemePreset?,
	OnDismissed: (() -> ())?,
	Parent: Instance?,
}

export type MangoNotification = {
	Container: Frame,
	Show: (self: MangoNotification) -> (),
	Dismiss: (self: MangoNotification) -> (),
	SetPosition: (self: MangoNotification, position: UDim2) -> (),
	GetHeight: (self: MangoNotification) -> number,
	Destroy: (self: MangoNotification) -> (),
}

export type MangoEnvironmentLightConfig = {
	UpdateAngleEveryFrame: boolean?, -- default true
	TintUpdateInterval: number?, -- seconds, default 0.5
	TintInfluence: number?, -- 0-1, default 0.22
	Enabled: boolean?, -- default true
}

export type MangoEnvironmentLight = {
	Enable: (self: MangoEnvironmentLight) -> (),
	Disable: (self: MangoEnvironmentLight) -> (),
	IsEnabled: (self: MangoEnvironmentLight) -> boolean,
	GetSunAngle: (self: MangoEnvironmentLight) -> number,
	GetEnvironmentTint: (self: MangoEnvironmentLight) -> Color3,
	RegisterGlassFrame: (self: MangoEnvironmentLight, frame: MangoGlassFrame) -> (),
	UnregisterGlassFrame: (self: MangoEnvironmentLight, frame: MangoGlassFrame) -> (),
	Destroy: (self: MangoEnvironmentLight) -> (),
}

-- Notification Stack
export type MangoNotificationStackConfig = {
	MaxVisible: number?,
	StackGap: number?,
	Theme: ThemePreset?,
	Parent: Instance?,
}

export type MangoNotificationStack = {
	Push: (self: MangoNotificationStack, config: MangoNotificationConfig) -> MangoNotification,
	DismissAll: (self: MangoNotificationStack) -> (),
	GetCount: (self: MangoNotificationStack) -> number,
	Destroy: (self: MangoNotificationStack) -> (),
}

-- Segmented Control
export type MangoSegmentedControlConfig = {
	Position: UDim2,
	AnchorPoint: Vector2?,
	Segments: {string},
	InitialIndex: number?,
	SegmentWidth: number?,
	Height: number?,
	Theme: ThemePreset?,
	OnChanged: ((index: number) -> ())?,
	Parent: GuiObject?,
}

export type MangoSegmentedControl = {
	Container: Frame,
	SetIndex: (self: MangoSegmentedControl, index: number) -> (),
	GetIndex: (self: MangoSegmentedControl) -> number,
	Destroy: (self: MangoSegmentedControl) -> (),
}

-- Dropdown
export type MangoDropdownConfig = {
	Position: UDim2,
	Size: UDim2?,
	AnchorPoint: Vector2?,
	Items: {string},
	InitialIndex: number?,
	MultiSelect: boolean?,
	InitialItems: {string}?,
	Theme: ThemePreset?,
	OnChanged: ((index: number) -> ())?,
	OnMultiChanged: (({string}) -> ())?,
	Parent: GuiObject?,
}

export type MangoDropdown = {
	Container: Frame,
	SetSelectedIndex: (self: MangoDropdown, index: number) -> (),
	GetSelectedIndex: (self: MangoDropdown) -> number,
	GetSelectedItems: (self: MangoDropdown) -> {string},
	SetItems: (self: MangoDropdown, items: {string}) -> (),
	Open: (self: MangoDropdown) -> (),
	Close: (self: MangoDropdown) -> (),
	Destroy: (self: MangoDropdown) -> (),
}

-- Tab Bar
export type MangoTabBarConfig = {
	Tabs: {{Icon: string?, Label: string}},
	InitialIndex: number?,
	Theme: ThemePreset?,
	OnChanged: ((index: number) -> ())?,
	Parent: GuiObject?,
}

export type MangoTabBar = {
	Container: Frame,
	SetIndex: (self: MangoTabBar, index: number) -> (),
	GetIndex: (self: MangoTabBar) -> number,
	Destroy: (self: MangoTabBar) -> (),
}

-- Search Bar
export type MangoSearchBarConfig = {
	Position: UDim2,
	Size: UDim2?,
	AnchorPoint: Vector2?,
	Placeholder: string?,
	Theme: ThemePreset?,
	OnTextChanged: ((text: string) -> ())?,
	OnSubmit: ((text: string) -> ())?,
	Parent: GuiObject?,
}

export type MangoSearchBar = {
	Container: Frame,
	GetText: (self: MangoSearchBar) -> string,
	SetText: (self: MangoSearchBar, text: string) -> (),
	Focus: (self: MangoSearchBar) -> (),
	Destroy: (self: MangoSearchBar) -> (),
}

-- Text Field
export type MangoTextFieldConfig = {
	Position: UDim2,
	Size: UDim2?,
	AnchorPoint: Vector2?,
	Placeholder: string?,
	InitialText: string?,
	Masked: boolean?,
	Theme: ThemePreset?,
	OnTextChanged: ((text: string) -> ())?,
	OnFocusLost: ((text: string, enterPressed: boolean) -> ())?,
	Parent: GuiObject?,
}

export type MangoTextField = {
	Container: Frame,
	GetText: (self: MangoTextField) -> string,
	SetText: (self: MangoTextField, text: string) -> (),
	Focus: (self: MangoTextField) -> (),
	Destroy: (self: MangoTextField) -> (),
}

-- Checkbox
export type MangoCheckboxConfig = {
	Position: UDim2,
	AnchorPoint: Vector2?,
	Label: string?,
	InitialState: boolean?,
	Theme: ThemePreset?,
	OnToggled: ((state: boolean) -> ())?,
	Parent: GuiObject?,
}

export type MangoCheckbox = {
	Container: Frame,
	SetState: (self: MangoCheckbox, state: boolean) -> (),
	GetState: (self: MangoCheckbox) -> boolean,
	Destroy: (self: MangoCheckbox) -> (),
}

-- Progress Bar
export type MangoProgressBarConfig = {
	Position: UDim2,
	Size: UDim2?,
	AnchorPoint: Vector2?,
	InitialValue: number?,
	Theme: ThemePreset?,
	Parent: GuiObject?,
}

export type MangoProgressBar = {
	Container: Frame,
	SetValue: (self: MangoProgressBar, value: number) -> (),
	GetValue: (self: MangoProgressBar) -> number,
	Destroy: (self: MangoProgressBar) -> (),
}

-- Dialog
export type MangoDialogButtonConfig = {
	Text: string,
	Style: string?, -- "default" | "cancel" | "destructive"
	OnActivated: (() -> ())?,
}

export type MangoDialogConfig = {
	Title: string,
	Message: string?,
	Buttons: {MangoDialogButtonConfig}?,
	Theme: ThemePreset?,
	OnDismissed: (() -> ())?,
	Parent: Instance?,
}

export type MangoDialog = {
	Show: (self: MangoDialog) -> (),
	Dismiss: (self: MangoDialog) -> (),
	Destroy: (self: MangoDialog) -> (),
}

-- Action Sheet
export type MangoActionSheetActionConfig = {
	Text: string,
	Style: string?, -- "default" | "destructive"
	OnActivated: (() -> ())?,
}

export type MangoActionSheetConfig = {
	Title: string?,
	Message: string?,
	Actions: {MangoActionSheetActionConfig},
	CancelText: string?,
	Theme: ThemePreset?,
	OnDismissed: (() -> ())?,
	Parent: Instance?,
}

export type MangoActionSheet = {
	Show: (self: MangoActionSheet) -> (),
	Dismiss: (self: MangoActionSheet) -> (),
	Destroy: (self: MangoActionSheet) -> (),
}

-- Intro
export type MangoIntroConfig = {
	Theme: ThemePreset?,
	Title: string?,
	Subtitle: string?,
	OnComplete: (() -> ())?,
	Parent: Instance?,
}

-- Shimmer
export type MangoShimmerConfig = {
	Target: GuiObject,
	ShimmerColor: Color3?,
	ShimmerTransparency: number?,
	ShimmerWidth: number?,
	Duration: number?,
	Enabled: boolean?,
	Theme: ThemePreset?,
}

export type MangoShimmer = {
	Enable: (self: MangoShimmer) -> (),
	Disable: (self: MangoShimmer) -> (),
	IsEnabled: (self: MangoShimmer) -> boolean,
	Destroy: (self: MangoShimmer) -> (),
}

-- Layout
export type MangoLayoutConfig = {
	Mode: string, -- "vstack" | "hstack" | "grid"
	Padding: number?,
	CellSize: UDim2?,
	HorizontalAlignment: Enum.HorizontalAlignment?,
	VerticalAlignment: Enum.VerticalAlignment?,
	PaddingTop: number?,
	PaddingBottom: number?,
	PaddingLeft: number?,
	PaddingRight: number?,
	Parent: GuiObject?,
}

export type MangoLayout = {
	Container: Frame,
	AddChild: (self: MangoLayout, child: GuiObject) -> (),
	RemoveChild: (self: MangoLayout, child: GuiObject) -> (),
	Clear: (self: MangoLayout) -> (),
	Destroy: (self: MangoLayout) -> (),
}

-- Badge
export type MangoBadgeConfig = {
	Position: UDim2,
	AnchorPoint: Vector2?,
	Text: string,
	TextSize: number?,
	TextColor: Color3?,
	BackgroundColor: Color3?,
	BackgroundTransparency: number?,
	Theme: ThemePreset?,
	Parent: GuiObject?,
}

export type MangoBadge = {
	Container: Frame,
	SetText: (self: MangoBadge, text: string) -> (),
	Destroy: (self: MangoBadge) -> (),
}

-- Skeleton
export type MangoSkeletonConfig = {
	Size: UDim2,
	Position: UDim2,
	AnchorPoint: Vector2?,
	CornerRadius: UDim?,
	Theme: ThemePreset?,
	Parent: GuiObject?,
}

export type MangoSkeleton = {
	Container: Frame,
	Destroy: (self: MangoSkeleton) -> (),
}

-- Stepper
export type MangoStepperConfig = {
	Position: UDim2,
	AnchorPoint: Vector2?,
	InitialValue: number?,
	Min: number?,
	Max: number?,
	Step: number?,
	Theme: ThemePreset?,
	OnChanged: ((value: number) -> ())?,
	Parent: GuiObject?,
}

export type MangoStepper = {
	Container: Frame,
	SetValue: (self: MangoStepper, value: number) -> (),
	GetValue: (self: MangoStepper) -> number,
	Destroy: (self: MangoStepper) -> (),
}

-- Tooltip
export type MangoTooltipConfig = {
	Target: GuiObject,
	Text: string,
	TextSize: number?,
	MaxWidth: number?,
	Delay: number?,
	Placement: string?,
	ArrowSize: number?,
	Theme: ThemePreset?,
	Parent: GuiObject?,
}

export type MangoTooltip = {
	Show: (self: MangoTooltip) -> (),
	Hide: (self: MangoTooltip) -> (),
	SetText: (self: MangoTooltip, text: string) -> (),
	Destroy: (self: MangoTooltip) -> (),
}

-- Toast
export type MangoToastConfig = {
	Text: string,
	Icon: string?,
	Duration: number?,
	Theme: ThemePreset?,
	OnDismissed: (() -> ())?,
	Parent: Instance?,
}

export type MangoToast = {
	Container: Frame,
	Show: (self: MangoToast) -> (),
	Dismiss: (self: MangoToast) -> (),
	SetPosition: (self: MangoToast, position: UDim2) -> (),
	GetHeight: (self: MangoToast) -> number,
	Destroy: (self: MangoToast) -> (),
}

-- Toast Stack
export type MangoToastStackConfig = {
	MaxVisible: number?,
	StackGap: number?,
	Theme: ThemePreset?,
	Parent: Instance?,
}

export type MangoToastStack = {
	Push: (self: MangoToastStack, config: MangoToastConfig) -> MangoToast,
	DismissAll: (self: MangoToastStack) -> (),
	GetCount: (self: MangoToastStack) -> number,
	Destroy: (self: MangoToastStack) -> (),
}

-- Context Menu
export type MangoContextMenuItemConfig = {
	Text: string,
	Icon: string?,
	Style: string?,
	Disabled: boolean?,
	OnActivated: (() -> ())?,
}

export type MangoContextMenuConfig = {
	Target: GuiObject,
	Items: {MangoContextMenuItemConfig},
	Theme: ThemePreset?,
	Parent: GuiObject?,
}

export type MangoContextMenu = {
	Open: (self: MangoContextMenu, position: Vector2?) -> (),
	Close: (self: MangoContextMenu) -> (),
	SetItems: (self: MangoContextMenu, items: {MangoContextMenuItemConfig}) -> (),
	Destroy: (self: MangoContextMenu) -> (),
}

-- Bottom Sheet
export type MangoBottomSheetConfig = {
	Title: string?,
	ContentSize: UDim2?,
	SnapPositions: {number}?,
	InitialSnap: number?,
	DismissThreshold: number?,
	Theme: ThemePreset?,
	OnDismissed: (() -> ())?,
	OnSnapChanged: ((snapIndex: number) -> ())?,
	Parent: Instance?,
}

export type MangoBottomSheet = {
	Container: Frame,
	ContentFrame: Frame,
	Show: (self: MangoBottomSheet) -> (),
	Dismiss: (self: MangoBottomSheet) -> (),
	SnapTo: (self: MangoBottomSheet, snapIndex: number) -> (),
	Destroy: (self: MangoBottomSheet) -> (),
}

-- Blur Proxy
export type MangoBlurProxyConfig = {
	TargetGui: GuiObject,
	BlurRadius: number?,
	DownscaleFactor: number?,
	UpdateInterval: number?,
	Enabled: boolean?,
	Theme: ThemePreset?,
	Parent: GuiObject?,
}

export type MangoBlurProxy = {
	Container: Frame,
	SetEnabled: (self: MangoBlurProxy, enabled: boolean) -> (),
	IsEnabled: (self: MangoBlurProxy) -> boolean,
	Destroy: (self: MangoBlurProxy) -> (),
}

-- Form
export type MangoFormFieldConfig = {
	Name: string,
	Type: string, -- "text" | "checkbox" | "dropdown" | "slider"
	Label: string?,
	Required: boolean?,
	Placeholder: string?,
	Items: {string}?,
	Min: number?,
	Max: number?,
	InitialValue: any?,
	Validate: ((value: any) -> (boolean, string?))?,
}

export type MangoFormConfig = {
	Position: UDim2,
	Size: UDim2?,
	AnchorPoint: Vector2?,
	Fields: {MangoFormFieldConfig},
	SubmitText: string?,
	Theme: ThemePreset?,
	OnSubmit: ((values: {[string]: any}) -> ())?,
	Parent: GuiObject?,
}

export type MangoForm = {
	Container: Frame,
	GetValues: (self: MangoForm) -> {[string]: any},
	Validate: (self: MangoForm) -> boolean,
	SetFieldValue: (self: MangoForm, name: string, value: any) -> (),
	Destroy: (self: MangoForm) -> (),
}

-- Focus Manager
export type MangoFocusManagerConfig = {
	Inputs: {GuiObject},
	SubmitCallback: (() -> ())?,
	DismissCallback: (() -> ())?,
	Enabled: boolean?,
}

export type MangoFocusManager = {
	Register: (self: MangoFocusManager, input: GuiObject) -> (),
	Unregister: (self: MangoFocusManager, input: GuiObject) -> (),
	FocusNext: (self: MangoFocusManager) -> (),
	FocusPrevious: (self: MangoFocusManager) -> (),
	FocusIndex: (self: MangoFocusManager, index: number) -> (),
	SetEnabled: (self: MangoFocusManager, enabled: boolean) -> (),
	Destroy: (self: MangoFocusManager) -> (),
}

-- Color Picker
export type MangoColorPickerConfig = {
	Position: UDim2,
	Size: UDim2?,
	AnchorPoint: Vector2?,
	InitialColor: Color3?,
	Theme: ThemePreset?,
	OnChanged: ((color: Color3) -> ())?,
	Parent: GuiObject?,
}

export type MangoColorPicker = {
	Container: Frame,
	GetColor: (self: MangoColorPicker) -> Color3,
	SetColor: (self: MangoColorPicker, color: Color3) -> (),
	Destroy: (self: MangoColorPicker) -> (),
}

-- Keybind
export type MangoKeybindConfig = {
	Position: UDim2,
	AnchorPoint: Vector2?,
	Label: string?,
	DefaultKey: string?,
	Theme: ThemePreset?,
	OnKeyChanged: ((keyName: string) -> ())?,
	Parent: GuiObject?,
}

export type MangoKeybind = {
	Container: Frame,
	GetKey: (self: MangoKeybind) -> string,
	SetKey: (self: MangoKeybind, keyName: string) -> (),
	Destroy: (self: MangoKeybind) -> (),
}

-- Carousel
export type MangoCarouselTabConfig = {
	Icon: string?,
	Label: string?,
	Color: Color3?,
}

export type MangoCarouselConfig = {
	Tabs: {MangoCarouselTabConfig},
	Position: UDim2?,
	Size: UDim2?,
	AnchorPoint: Vector2?,
	InitialIndex: number?,
	IconSize: number?,
	Orientation: string?,
	Theme: ThemePreset?,
	OnChanged: ((index: number) -> ())?,
	Parent: GuiObject?,
}

export type MangoCarousel = {
	Container: Frame,
	SetIndex: (self: MangoCarousel, index: number) -> (),
	GetIndex: (self: MangoCarousel) -> number,
	Destroy: (self: MangoCarousel) -> (),
}

-- Save Manager
export type MangoSaveManagerConfig = {
	FolderName: string,
	FileName: string?,
}

export type MangoSaveManager = {
	Save: (self: MangoSaveManager, data: {[string]: any}) -> boolean,
	Load: (self: MangoSaveManager) -> {[string]: any}?,
	Delete: (self: MangoSaveManager) -> boolean,
}

-- Notification Action Button
export type MangoNotificationActionConfig = {
	Text: string,
	Style: string?,
	Callback: (() -> ())?,
}

-- Window Element (unified wrapper for all interactive elements)
export type MangoWindowElement = {
	CurrentValue: any,
	Set: (self: MangoWindowElement, value: any) -> (),
	Visible: (self: MangoWindowElement, visible: boolean) -> (),
	Lock: (self: MangoWindowElement, reason: string?) -> (),
	Unlock: (self: MangoWindowElement) -> (),
	Destroy: (self: MangoWindowElement) -> (),
}

-- Window Tab
export type MangoWindowTab = {
	Button: (self: MangoWindowTab, config: MangoWindowButtonConfig) -> MangoWindowElement,
	Toggle: (self: MangoWindowTab, config: MangoWindowToggleConfig) -> MangoWindowElement,
	Slider: (self: MangoWindowTab, config: MangoWindowSliderConfig) -> MangoWindowElement,
	Dropdown: (self: MangoWindowTab, config: MangoWindowDropdownConfig) -> MangoWindowElement,
	Input: (self: MangoWindowTab, config: MangoWindowInputConfig) -> MangoWindowElement,
	Checkbox: (self: MangoWindowTab, config: MangoWindowCheckboxConfig) -> MangoWindowElement,
	Stepper: (self: MangoWindowTab, config: MangoWindowStepperConfig) -> MangoWindowElement,
	Progress: (self: MangoWindowTab, config: MangoWindowProgressConfig) -> MangoWindowElement,
	ColorPicker: (self: MangoWindowTab, config: MangoWindowColorPickerConfig) -> MangoWindowElement,
	Keybind: (self: MangoWindowTab, config: MangoWindowKeybindConfig) -> MangoWindowElement,
	Label: (self: MangoWindowTab, text: string) -> MangoWindowElement,
	Paragraph: (self: MangoWindowTab, config: MangoWindowParagraphConfig) -> MangoWindowElement,
	Section: (self: MangoWindowTab, title: string) -> MangoWindowElement,
	Separator: (self: MangoWindowTab) -> MangoWindowElement,
}

-- Window element config types
export type MangoWindowButtonConfig = {
	Name: string,
	Callback: (() -> ())?,
	Flag: string?,
	Visible: (boolean | string)?,
}

export type MangoWindowToggleConfig = {
	Name: string,
	Default: boolean?,
	Callback: ((value: boolean) -> ())?,
	Flag: string?,
	Visible: (boolean | string)?,
}

export type MangoWindowSliderConfig = {
	Name: string,
	Range: {number},
	Increment: number?,
	Suffix: string?,
	Default: number?,
	Callback: ((value: number) -> ())?,
	Flag: string?,
	Visible: (boolean | string)?,
}

export type MangoWindowDropdownConfig = {
	Name: string,
	Options: {string},
	Default: (string | {string})?,
	MultiSelect: boolean?,
	Callback: ((value: any) -> ())?,
	Flag: string?,
	Visible: (boolean | string)?,
}

export type MangoWindowInputConfig = {
	Name: string,
	Default: string?,
	Placeholder: string?,
	Masked: boolean?,
	Callback: ((text: string) -> ())?,
	Flag: string?,
	Visible: (boolean | string)?,
}

export type MangoWindowCheckboxConfig = {
	Name: string,
	Default: boolean?,
	Callback: ((value: boolean) -> ())?,
	Flag: string?,
	Visible: (boolean | string)?,
}

export type MangoWindowStepperConfig = {
	Name: string,
	Range: {number}?,
	Default: number?,
	Callback: ((value: number) -> ())?,
	Flag: string?,
	Visible: (boolean | string)?,
}

export type MangoWindowProgressConfig = {
	Name: string,
	Default: number?,
	Flag: string?,
	Visible: (boolean | string)?,
}

export type MangoWindowColorPickerConfig = {
	Name: string,
	Default: Color3?,
	Callback: ((color: Color3) -> ())?,
	Flag: string?,
	Visible: (boolean | string)?,
}

export type MangoWindowKeybindConfig = {
	Name: string,
	Default: string?,
	Callback: ((keyName: string) -> ())?,
	Flag: string?,
	Visible: (boolean | string)?,
}

export type MangoWindowParagraphConfig = {
	Title: string,
	Content: string,
	Visible: (boolean | string)?,
}

-- Window Configuration Saving
export type MangoWindowConfigSaving = {
	Enabled: boolean,
	FolderName: string?,
	FileName: string?,
}

-- Window
export type MangoWindowConfig = {
	Name: string,
	Theme: ThemePreset?,
	Size: UDim2?,
	Position: UDim2?,
	ToggleKey: string?,
	ShowButton: string?,
	ConfigurationSaving: MangoWindowConfigSaving?,
	LoadingTitle: string?,
	LoadingSubtitle: string?,
	LoadingEnabled: boolean?,
}

export type MangoWindow = {
	Flags: {[string]: any},
	Tab: (self: MangoWindow, name: string, icon: string?) -> MangoWindowTab,
	Notify: (self: MangoWindow, config: MangoNotificationConfig) -> (),
	Dialog: (self: MangoWindow, config: MangoDialogConfig) -> (),
	Show: (self: MangoWindow) -> (),
	Hide: (self: MangoWindow) -> (),
	IsVisible: (self: MangoWindow) -> boolean,
	SaveConfig: (self: MangoWindow) -> (),
	LoadConfig: (self: MangoWindow) -> (),
	Destroy: (self: MangoWindow) -> (),
}

-- Builder
export type MangoBuilder = {
	text: (self: MangoBuilder, text: string) -> MangoBuilder,
	theme: (self: MangoBuilder, theme: ThemePreset) -> MangoBuilder,
	pos: (self: MangoBuilder, xScale: number, xOffset: number, yScale: number, yOffset: number) -> MangoBuilder,
	anchor: (self: MangoBuilder, x: number, y: number) -> MangoBuilder,
	size: (self: MangoBuilder, xScale: number, xOffset: number, yScale: number, yOffset: number) -> MangoBuilder,
	parent: (self: MangoBuilder, parent: GuiObject) -> MangoBuilder,
	onClick: (self: MangoBuilder, callback: () -> ()) -> MangoBuilder,
	onChange: (self: MangoBuilder, callback: (value: any) -> ()) -> MangoBuilder,
	prop: (self: MangoBuilder, key: string, value: any) -> MangoBuilder,
	create: (self: MangoBuilder) -> any,
}

return nil
