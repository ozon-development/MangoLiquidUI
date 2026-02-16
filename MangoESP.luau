--!strict

local Types = require(script.Parent.Types)
local Themes = require(script.Parent.Themes)
local MangoProtection = require(script.Parent.MangoProtection)
local resolve = Themes.resolve

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local module = {}

-- Lerp green -> yellow -> red based on health fraction
local function healthColor(fraction: number): Color3
	if fraction > 0.5 then
		-- green -> yellow
		local t = (fraction - 0.5) * 2
		return Color3.fromRGB(
			math.floor(255 * (1 - t)),
			255,
			math.floor(50 * (1 - t))
		)
	else
		-- yellow -> red
		local t = fraction * 2
		return Color3.fromRGB(
			255,
			math.floor(255 * t),
			0
		)
	end
end

-- 3-keypoint fresnel NumberSequence (bright top -> fade bottom)
local function fresnelTransparency(startT: number, midT: number, endT: number, midPoint: number): NumberSequence
	return NumberSequence.new({
		NumberSequenceKeypoint.new(0, startT),
		NumberSequenceKeypoint.new(midPoint, midT),
		NumberSequenceKeypoint.new(1, endT),
	})
end

-- Project character bounding box to 2D screen space
-- Returns nil if not visible
local function getCharacterScreenBounds(
	character: Model,
	camera: Camera,
	humanoidRootPart: BasePart
): (boolean?, number?, number?, number?, number?, number?)
	-- Get character height from humanoid or default
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local charHeight = 5.5 -- default R15 height in studs
	if humanoid then
		local hipHeight = humanoid.HipHeight
		charHeight = hipHeight * 2 + 1 -- approximate full height
		if charHeight < 3 then charHeight = 5.5 end
	end

	local rootPos = humanoidRootPart.Position
	local topPos = rootPos + Vector3.new(0, charHeight / 2 + 0.5, 0) -- head top
	local bottomPos = rootPos - Vector3.new(0, charHeight / 2, 0)   -- feet

	local topScreen, topVisible = camera:WorldToScreenPoint(topPos)
	local bottomScreen, bottomVisible = camera:WorldToScreenPoint(bottomPos)

	if not topVisible and not bottomVisible then
		return nil
	end

	-- Distance from camera
	local distance = topScreen.Z

	if distance < 1 then
		return nil
	end

	local screenTop = topScreen.Y
	local screenBottom = bottomScreen.Y
	local boxHeight = math.abs(screenBottom - screenTop)
	local boxWidth = boxHeight * 0.6 -- R15 aspect ratio

	local centerX = (topScreen.X + bottomScreen.X) / 2
	local centerY = (screenTop + screenBottom) / 2

	return true, centerX - boxWidth / 2, screenTop, boxWidth, boxHeight, distance
end

-- Project a single BasePart's bounding box to 2D screen space
local function getPartScreenBounds(
	part: BasePart,
	camera: Camera
): (boolean?, number?, number?, number?, number?, number?)
	local cf = part.CFrame
	local size = part.Size
	local halfSize = size / 2

	-- 8 corner offsets of the part's bounding box
	local corners = {
		cf * Vector3.new( halfSize.X,  halfSize.Y,  halfSize.Z),
		cf * Vector3.new( halfSize.X,  halfSize.Y, -halfSize.Z),
		cf * Vector3.new( halfSize.X, -halfSize.Y,  halfSize.Z),
		cf * Vector3.new( halfSize.X, -halfSize.Y, -halfSize.Z),
		cf * Vector3.new(-halfSize.X,  halfSize.Y,  halfSize.Z),
		cf * Vector3.new(-halfSize.X,  halfSize.Y, -halfSize.Z),
		cf * Vector3.new(-halfSize.X, -halfSize.Y,  halfSize.Z),
		cf * Vector3.new(-halfSize.X, -halfSize.Y, -halfSize.Z),
	}

	local minX, minY = math.huge, math.huge
	local maxX, maxY = -math.huge, -math.huge
	local anyVisible = false
	local dist = 0

	for _, corner in corners do
		local screenPos, onScreen = camera:WorldToScreenPoint(corner)
		if onScreen then anyVisible = true end
		if screenPos.X < minX then minX = screenPos.X end
		if screenPos.X > maxX then maxX = screenPos.X end
		if screenPos.Y < minY then minY = screenPos.Y end
		if screenPos.Y > maxY then maxY = screenPos.Y end
		dist = screenPos.Z
	end

	if not anyVisible or dist < 1 then
		return nil
	end

	local bw = maxX - minX
	local bh = maxY - minY
	-- Minimum visible size
	if bw < 4 then bw = 4 end
	if bh < 4 then bh = 4 end

	return true, minX, minY, bw, bh, dist
end

-- Project a Model's bounding box to 2D screen space
local function getModelScreenBounds(
	model: Model,
	camera: Camera
): (boolean?, number?, number?, number?, number?, number?)
	local cf, size = model:GetBoundingBox()
	local halfSize = size / 2

	local corners = {
		cf * Vector3.new( halfSize.X,  halfSize.Y,  halfSize.Z),
		cf * Vector3.new( halfSize.X,  halfSize.Y, -halfSize.Z),
		cf * Vector3.new( halfSize.X, -halfSize.Y,  halfSize.Z),
		cf * Vector3.new( halfSize.X, -halfSize.Y, -halfSize.Z),
		cf * Vector3.new(-halfSize.X,  halfSize.Y,  halfSize.Z),
		cf * Vector3.new(-halfSize.X,  halfSize.Y, -halfSize.Z),
		cf * Vector3.new(-halfSize.X, -halfSize.Y,  halfSize.Z),
		cf * Vector3.new(-halfSize.X, -halfSize.Y, -halfSize.Z),
	}

	local minX, minY = math.huge, math.huge
	local maxX, maxY = -math.huge, -math.huge
	local anyVisible = false
	local dist = 0

	for _, corner in corners do
		local screenPos, onScreen = camera:WorldToScreenPoint(corner)
		if onScreen then anyVisible = true end
		if screenPos.X < minX then minX = screenPos.X end
		if screenPos.X > maxX then maxX = screenPos.X end
		if screenPos.Y < minY then minY = screenPos.Y end
		if screenPos.Y > maxY then maxY = screenPos.Y end
		dist = screenPos.Z
	end

	if not anyVisible or dist < 1 then
		return nil
	end

	local bw = maxX - minX
	local bh = maxY - minY
	if bw < 4 then bw = 4 end
	if bh < 4 then bh = 4 end

	return true, minX, minY, bw, bh, dist
end

type ESPEntry = {
	container: Frame,
	boxFrame: Frame,
	boxStroke: UIStroke,
	boxCorner: UICorner,
	boxGradient: UIGradient,
	innerEdgeFrame: Frame,
	innerEdgeStroke: UIStroke,
	innerEdgeGradient: UIGradient,
	nameTag: Frame?,
	nameLabel: TextLabel?,
	nameStroke: UIStroke?,
	nameGradient: UIGradient?,
	nameCorner: UICorner?,
	healthContainer: Frame?,
	healthFill: Frame?,
	healthCorner: UICorner?,
	healthFillCorner: UICorner?,
	distanceLabel: TextLabel?,
	tracer: Frame?,
	tracerGradient: UIGradient?,
	-- Target info
	player: Player?,
	targetPart: BasePart?,
	targetModel: Model?,
	customText: string?,
	customColor: Color3?,
	isCustom: boolean,
}

local function createESPEntry(
	parent: Instance,
	showBox: boolean,
	showName: boolean,
	showHealth: boolean,
	showDistance: boolean,
	showTracer: boolean,
	accentColor: Color3,
	textColor: Color3,
	fresnelStart: number,
	fresnelMid: number,
	fresnelEnd: number,
	fresnelMidPoint: number,
	strokeThickness: number
): ESPEntry
	-- Entry container
	local container = Instance.new("Frame")
	container.Name = MangoProtection.randomName("ESPEntry")
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0
	container.Size = UDim2.new(0, 100, 0, 100)
	container.Position = UDim2.new(0, 0, 0, 0)
	container.Visible = false
	container.Parent = parent

	-- Box frame (glass fill)
	local boxFrame = Instance.new("Frame")
	boxFrame.Name = MangoProtection.randomName("Box")
	boxFrame.BackgroundColor3 = accentColor
	boxFrame.BackgroundTransparency = 0.95
	boxFrame.BorderSizePixel = 0
	boxFrame.Size = UDim2.new(1, 0, 1, 0)
	boxFrame.Parent = container

	local boxCorner = Instance.new("UICorner")
	boxCorner.CornerRadius = UDim.new(0, 4)
	boxCorner.Parent = boxFrame

	-- Box outer stroke with fresnel gradient
	local boxStroke = Instance.new("UIStroke")
	boxStroke.Name = "BoxStroke"
	boxStroke.Thickness = strokeThickness
	boxStroke.Color = accentColor
	boxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	boxStroke.Parent = boxFrame

	local boxGradient = Instance.new("UIGradient")
	boxGradient.Name = "BoxGradient"
	boxGradient.Rotation = 90
	boxGradient.Transparency = fresnelTransparency(fresnelStart, fresnelMid, fresnelEnd, fresnelMidPoint)
	boxGradient.Parent = boxStroke

	-- Inner edge frame (recessed look)
	local innerEdgeFrame = Instance.new("Frame")
	innerEdgeFrame.Name = MangoProtection.randomName("InnerEdge")
	innerEdgeFrame.BackgroundTransparency = 1
	innerEdgeFrame.BorderSizePixel = 0
	innerEdgeFrame.Size = UDim2.new(1, 0, 1, 0)
	innerEdgeFrame.ZIndex = 2
	innerEdgeFrame.Parent = boxFrame

	local innerEdgeCorner = Instance.new("UICorner")
	innerEdgeCorner.CornerRadius = UDim.new(0, 4)
	innerEdgeCorner.Parent = innerEdgeFrame

	local innerEdgeStroke = Instance.new("UIStroke")
	innerEdgeStroke.Name = "InnerEdgeStroke"
	innerEdgeStroke.Thickness = 0.5
	innerEdgeStroke.Color = Color3.new(1, 1, 1)
	innerEdgeStroke.Transparency = 0.7
	innerEdgeStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	innerEdgeStroke.Parent = innerEdgeFrame

	local innerEdgeGradient = Instance.new("UIGradient")
	innerEdgeGradient.Name = "InnerEdgeGradient"
	innerEdgeGradient.Rotation = 90
	innerEdgeGradient.Transparency = fresnelTransparency(0.55, 0.82, 0.95, 0.5)
	innerEdgeGradient.Parent = innerEdgeStroke

	-- Name tag (pill above box)
	local nameTag: Frame? = nil
	local nameLabel: TextLabel? = nil
	local nameStroke: UIStroke? = nil
	local nameGradient: UIGradient? = nil
	local nameCorner: UICorner? = nil
	if showName then
		local nt = Instance.new("Frame")
		nt.Name = MangoProtection.randomName("NameTag")
		nt.BackgroundColor3 = accentColor
		nt.BackgroundTransparency = 0.82
		nt.BorderSizePixel = 0
		nt.Size = UDim2.new(0, 80, 0, 18)
		nt.Position = UDim2.new(0.5, 0, 0, -22)
		nt.AnchorPoint = Vector2.new(0.5, 0)
		nt.AutomaticSize = Enum.AutomaticSize.X
		nt.Parent = container
		nameTag = nt

		local nc = Instance.new("UICorner")
		nc.CornerRadius = UDim.new(0, 999)
		nc.Parent = nt
		nameCorner = nc

		local ns = Instance.new("UIStroke")
		ns.Name = "NameStroke"
		ns.Thickness = 0.75
		ns.Color = accentColor
		ns.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		ns.Parent = nt
		nameStroke = ns

		local ng = Instance.new("UIGradient")
		ng.Name = "NameGradient"
		ng.Rotation = 90
		ng.Transparency = fresnelTransparency(fresnelStart + 0.1, fresnelMid + 0.1, fresnelEnd, fresnelMidPoint)
		ng.Parent = ns
		nameGradient = ng

		local padding = Instance.new("UIPadding")
		padding.PaddingLeft = UDim.new(0, 8)
		padding.PaddingRight = UDim.new(0, 8)
		padding.Parent = nt

		local nl = Instance.new("TextLabel")
		nl.Name = MangoProtection.randomName("NameLabel")
		nl.BackgroundTransparency = 1
		nl.Size = UDim2.new(1, 0, 1, 0)
		nl.Font = Enum.Font.GothamMedium
		nl.TextSize = 11
		nl.TextColor3 = textColor
		nl.TextTruncate = Enum.TextTruncate.AtEnd
		nl.Text = ""
		nl.Parent = nt
		nameLabel = nl
	end

	-- Health bar (thin pill above box, below name)
	local healthContainer: Frame? = nil
	local healthFill: Frame? = nil
	local healthCorner: UICorner? = nil
	local healthFillCorner: UICorner? = nil
	if showHealth then
		local hc = Instance.new("Frame")
		hc.Name = MangoProtection.randomName("HealthBar")
		hc.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		hc.BackgroundTransparency = 0.5
		hc.BorderSizePixel = 0
		hc.Size = UDim2.new(1, 0, 0, 4)
		hc.Position = UDim2.new(0, 0, 0, -6)
		hc.Parent = container
		healthContainer = hc

		local hcc = Instance.new("UICorner")
		hcc.CornerRadius = UDim.new(0, 999)
		hcc.Parent = hc
		healthCorner = hcc

		local hf = Instance.new("Frame")
		hf.Name = MangoProtection.randomName("HealthFill")
		hf.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
		hf.BackgroundTransparency = 0
		hf.BorderSizePixel = 0
		hf.Size = UDim2.new(1, 0, 1, 0)
		hf.Parent = hc
		healthFill = hf

		local hfc = Instance.new("UICorner")
		hfc.CornerRadius = UDim.new(0, 999)
		hfc.Parent = hf
		healthFillCorner = hfc
	end

	-- Distance label (below box)
	local distanceLabel: TextLabel? = nil
	if showDistance then
		local dl = Instance.new("TextLabel")
		dl.Name = MangoProtection.randomName("DistLabel")
		dl.BackgroundTransparency = 1
		dl.Size = UDim2.new(1, 0, 0, 14)
		dl.Position = UDim2.new(0, 0, 1, 2)
		dl.Font = Enum.Font.GothamMedium
		dl.TextSize = 11
		dl.TextColor3 = textColor
		dl.TextStrokeTransparency = 0.7
		dl.TextStrokeColor3 = Color3.new(0, 0, 0)
		dl.Text = ""
		dl.Parent = container
		distanceLabel = dl
	end

	-- Tracer (1px line from screen bottom to target)
	local tracer: Frame? = nil
	local tracerGradient: UIGradient? = nil
	if showTracer then
		local tf = Instance.new("Frame")
		tf.Name = MangoProtection.randomName("Tracer")
		tf.BackgroundColor3 = accentColor
		tf.BackgroundTransparency = 0.3
		tf.BorderSizePixel = 0
		tf.Size = UDim2.new(0, 1, 0, 100)
		tf.AnchorPoint = Vector2.new(0.5, 1)
		tf.Visible = false
		-- Tracer is parented to the ScreenGui, not the entry container
		tf.Parent = parent
		tracer = tf

		local tg = Instance.new("UIGradient")
		tg.Name = "TracerGradient"
		tg.Rotation = 90
		tg.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.8),
			NumberSequenceKeypoint.new(1, 0),
		})
		tg.Parent = tf
		tracerGradient = tg
	end

	return {
		container = container,
		boxFrame = boxFrame,
		boxStroke = boxStroke,
		boxCorner = boxCorner,
		boxGradient = boxGradient,
		innerEdgeFrame = innerEdgeFrame,
		innerEdgeStroke = innerEdgeStroke,
		innerEdgeGradient = innerEdgeGradient,
		nameTag = nameTag,
		nameLabel = nameLabel,
		nameStroke = nameStroke,
		nameGradient = nameGradient,
		nameCorner = nameCorner,
		healthContainer = healthContainer,
		healthFill = healthFill,
		healthCorner = healthCorner,
		healthFillCorner = healthFillCorner,
		distanceLabel = distanceLabel,
		tracer = tracer,
		tracerGradient = tracerGradient,
		player = nil,
		targetPart = nil,
		targetModel = nil,
		customText = nil,
		customColor = nil,
		isCustom = false,
	} :: ESPEntry
end

local function updateTracerLine(
	tracer: Frame,
	fromX: number,
	fromY: number,
	toX: number,
	toY: number
)
	local dx = toX - fromX
	local dy = toY - fromY
	local length = math.sqrt(dx * dx + dy * dy)
	local angle = math.atan2(dy, dx)

	tracer.Size = UDim2.new(0, 1, 0, math.floor(length))
	tracer.Position = UDim2.new(0, math.floor(fromX), 0, math.floor(fromY))
	tracer.Rotation = math.deg(angle) + 90
	tracer.AnchorPoint = Vector2.new(0.5, 1)
end

function module.new(config: Types.MangoESPConfig): Types.MangoESP
	local theme = config.Theme
	local localPlayer = Players.LocalPlayer

	-- Resolve config
	local showBox = resolve(config.Box, nil, true) :: boolean
	local showName = resolve(config.Name, nil, true) :: boolean
	local showHealth = resolve(config.Health, nil, true) :: boolean
	local showDistance = resolve(config.Distance, nil, true) :: boolean
	local showTracer = resolve(config.Tracer, nil, false) :: boolean
	local teamCheck = resolve(config.TeamCheck, nil, false) :: boolean
	local maxDistance = resolve(config.MaxDistance, nil, 2000) :: number
	local boxColor = resolve(config.BoxColor, theme and (theme :: Types.ThemePreset).AccentColor, Color3.fromRGB(255, 255, 255)) :: Color3
	local textColor = resolve(config.TextColor, theme and (theme :: Types.ThemePreset).PrimaryTextColor, Color3.fromRGB(255, 255, 255)) :: Color3
	local fresnelStart = resolve(nil, theme and (theme :: Types.ThemePreset).FresnelStartTransparency, 0.35) :: number
	local fresnelMid = resolve(nil, theme and (theme :: Types.ThemePreset).FresnelMidTransparency, 0.65) :: number
	local fresnelEnd = resolve(nil, theme and (theme :: Types.ThemePreset).FresnelEndTransparency, 0.92) :: number
	local fresnelMidPoint = resolve(nil, theme and (theme :: Types.ThemePreset).FresnelMidPoint, 0.40) :: number
	local strokeThickness = resolve(nil, theme and (theme :: Types.ThemePreset).StrokeThickness, 1.5) :: number

	-- State
	local isDestroyed = false
	local enabled = true
	local entries: {[Instance]: ESPEntry} = {} -- keyed by character or part
	local connections: {RBXScriptConnection} = {}
	local bindingName = MangoProtection.randomBindingName("ESPUpdate")

	-- Create ScreenGui
	local screenGui = MangoProtection.createScreenGui({
		DisplayOrder = 200,
		IgnoreGuiInset = true,
	})

	-- Helper to destroy a single entry
	local function destroyEntry(key: Instance)
		local entry = entries[key]
		if not entry then return end
		if entry.tracer then
			(entry.tracer :: Frame):Destroy()
		end
		entry.container:Destroy()
		entries[key] = nil
	end

	-- Helper to create entry for a player's character
	local function setupCharacter(player: Player, character: Model)
		if isDestroyed then return end
		if player == localPlayer then return end

		-- Team check
		if teamCheck and localPlayer and localPlayer.Team and player.Team == localPlayer.Team then
			return
		end

		-- Wait for HumanoidRootPart
		local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not rootPart then
			local waitConn: RBXScriptConnection? = nil
			waitConn = character.ChildAdded:Connect(function(child)
				if isDestroyed then
					if waitConn then (waitConn :: RBXScriptConnection):Disconnect() end
					return
				end
				if child.Name == "HumanoidRootPart" then
					if waitConn then (waitConn :: RBXScriptConnection):Disconnect() end
					setupCharacter(player, character)
				end
			end)
			table.insert(connections, waitConn :: RBXScriptConnection)
			return
		end

		-- Remove old entry if exists
		destroyEntry(character)

		local entry = createESPEntry(
			screenGui,
			showBox,
			showName,
			showHealth,
			showDistance,
			showTracer,
			boxColor,
			textColor,
			fresnelStart,
			fresnelMid,
			fresnelEnd,
			fresnelMidPoint,
			strokeThickness
		)
		entry.player = player
		entry.isCustom = false

		-- Set name
		if entry.nameLabel then
			(entry.nameLabel :: TextLabel).Text = player.DisplayName
		end

		entries[character] = entry
	end

	-- Helper to setup player lifecycle
	local function setupPlayer(player: Player)
		if isDestroyed then return end
		if player == localPlayer then return end

		if player.Character then
			setupCharacter(player, player.Character)
		end

		local conn = player.CharacterAdded:Connect(function(character)
			if isDestroyed then return end
			setupCharacter(player, character)
		end)
		table.insert(connections, conn)

		local removeConn = player.CharacterRemoving:Connect(function(character)
			if isDestroyed then return end
			destroyEntry(character)
		end)
		table.insert(connections, removeConn)
	end

	-- Initialize existing players
	for _, player in Players:GetPlayers() do
		setupPlayer(player)
	end

	local addedConn = Players.PlayerAdded:Connect(function(player)
		if isDestroyed then return end
		setupPlayer(player)
	end)
	table.insert(connections, addedConn)

	local removingConn = Players.PlayerRemoving:Connect(function(player)
		if isDestroyed then return end
		if player.Character then
			destroyEntry(player.Character)
		end
	end)
	table.insert(connections, removingConn)

	-- RenderStepped update loop
	local camera = Workspace.CurrentCamera
	local viewportSize = camera and camera.ViewportSize or Vector2.new(1920, 1080)

	RunService:BindToRenderStep(bindingName, Enum.RenderPriority.Camera.Value + 1, function()
		if isDestroyed or not enabled then
			-- Hide all entries
			for _, entry in entries do
				entry.container.Visible = false
				if entry.tracer then
					(entry.tracer :: Frame).Visible = false
				end
			end
			return
		end

		camera = Workspace.CurrentCamera
		if not camera then return end
		viewportSize = camera.ViewportSize

		local screenBottomX = viewportSize.X / 2
		local screenBottomY = viewportSize.Y

		for key, entry in entries do
			-- Find root part
			local rootPart: BasePart? = nil
			local character: Model? = nil

			if entry.isCustom then
				rootPart = entry.targetPart
			else
				character = key :: any
				if character then
					rootPart = (character :: Model):FindFirstChild("HumanoidRootPart") :: BasePart?
				end
			end

			if not rootPart or not (rootPart :: BasePart).Parent then
				entry.container.Visible = false
				if entry.tracer then
					(entry.tracer :: Frame).Visible = false
				end
				continue
			end

			-- For custom entries, use proper bounding box projection
			if entry.isCustom then
				local bounds: any = nil

				if entry.targetModel and (entry.targetModel :: Model).Parent then
					-- Model target: use full model bounding box
					bounds = getModelScreenBounds(entry.targetModel :: Model, camera)
				elseif rootPart then
					-- BasePart target: use part's actual size
					bounds = getPartScreenBounds(rootPart :: BasePart, camera)
				end

				if not bounds then
					entry.container.Visible = false
					if entry.tracer then
						(entry.tracer :: Frame).Visible = false
					end
					continue
				end

				local _, bx, by, bw, bh, dist = bounds :: any
				bx = bx :: number
				by = by :: number
				bw = bw :: number
				bh = bh :: number
				dist = dist :: number

				if dist > maxDistance then
					entry.container.Visible = false
					if entry.tracer then
						(entry.tracer :: Frame).Visible = false
					end
					continue
				end

				entry.container.Position = UDim2.new(0, math.floor(bx), 0, math.floor(by))
				entry.container.Size = UDim2.new(0, math.max(math.floor(bw), 4), 0, math.max(math.floor(bh), 4))
				entry.container.Visible = true
				entry.boxFrame.Visible = showBox

				-- Update color if custom
				if entry.customColor then
					entry.boxStroke.Color = entry.customColor :: Color3
					entry.boxFrame.BackgroundColor3 = entry.customColor :: Color3
				end

				-- Update custom text
				if entry.nameLabel and entry.customText then
					(entry.nameLabel :: TextLabel).Text = entry.customText :: string
				end

				-- No health for custom entries
				if entry.healthContainer then
					(entry.healthContainer :: Frame).Visible = false
				end

				-- Distance label
				if entry.distanceLabel then
					(entry.distanceLabel :: TextLabel).Text = string.format("[%d]", math.floor(dist))
				end

				-- Tracer
				if entry.tracer then
					local ctf = entry.tracer :: Frame
					if showTracer then
						local targetX = math.floor(bx + bw / 2)
						local targetY = math.floor(by + bh)
						updateTracerLine(
							ctf,
							screenBottomX,
							screenBottomY,
							targetX,
							targetY
						)
						ctf.Visible = true
						if entry.customColor then
							ctf.BackgroundColor3 = entry.customColor :: Color3
						end
					else
						ctf.Visible = false
					end
				end

				continue
			end

			-- Player character bounding box
			local result = getCharacterScreenBounds(character :: Model, camera, rootPart :: BasePart)
			if not result then
				entry.container.Visible = false
				if entry.tracer then
					(entry.tracer :: Frame).Visible = false
				end
				continue
			end

			local _, bx, by, bw, bh, dist = result :: any
			bx = bx :: number
			by = by :: number
			bw = bw :: number
			bh = bh :: number
			dist = dist :: number

			-- Max distance check
			if dist > maxDistance then
				entry.container.Visible = false
				if entry.tracer then
					(entry.tracer :: Frame).Visible = false
				end
				continue
			end

			-- Team check (runtime, teams can change)
			if teamCheck and localPlayer and entry.player then
				if localPlayer.Team and (entry.player :: Player).Team == localPlayer.Team then
					entry.container.Visible = false
					if entry.tracer then
						(entry.tracer :: Frame).Visible = false
					end
					continue
				end
			end

			-- Update container position/size
			entry.container.Position = UDim2.new(0, math.floor(bx), 0, math.floor(by))
			entry.container.Size = UDim2.new(0, math.max(math.floor(bw), 4), 0, math.max(math.floor(bh), 4))
			entry.container.Visible = true
			entry.boxFrame.Visible = showBox

			-- Health bar
			if entry.healthContainer and entry.healthFill then
				local humanoid = (character :: Model):FindFirstChildOfClass("Humanoid")
				if humanoid and humanoid.MaxHealth > 0 then
					local fraction = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
					local hfFrame = entry.healthFill :: Frame
					hfFrame.Size = UDim2.new(fraction, 0, 1, 0)
					hfFrame.BackgroundColor3 = healthColor(fraction)
					local hcFrame = entry.healthContainer :: Frame
					hcFrame.Visible = showHealth
				else
					(entry.healthContainer :: Frame).Visible = false
				end
			end

			-- Distance label
			if entry.distanceLabel then
				local dlLabel = entry.distanceLabel :: TextLabel
				if showDistance then
					dlLabel.Text = string.format("[%d]", math.floor(dist))
					dlLabel.Visible = true
				else
					dlLabel.Visible = false
				end
			end

			-- Tracer
			if entry.tracer then
				local ptf = entry.tracer :: Frame
				if showTracer then
					local targetX = math.floor(bx + bw / 2)
					local targetY = math.floor(by + bh)
					updateTracerLine(
						ptf,
						screenBottomX,
						screenBottomY,
						targetX,
						targetY
					)
					ptf.Visible = true
				else
					ptf.Visible = false
				end
			end
		end
	end)

	-- Build return object
	local self = {} :: Types.MangoESP

	function self.SetBox(_self: Types.MangoESP, value: boolean)
		if isDestroyed then return end
		showBox = value
	end

	function self.SetName(_self: Types.MangoESP, value: boolean)
		if isDestroyed then return end
		showName = value
		-- Show/hide existing name tags
		for _, entry in entries do
			if entry.nameTag then
				(entry.nameTag :: Frame).Visible = value
			end
		end
	end

	function self.SetHealth(_self: Types.MangoESP, value: boolean)
		if isDestroyed then return end
		showHealth = value
	end

	function self.SetDistance(_self: Types.MangoESP, value: boolean)
		if isDestroyed then return end
		showDistance = value
	end

	function self.SetTracer(_self: Types.MangoESP, value: boolean)
		if isDestroyed then return end
		showTracer = value
	end

	function self.SetMaxDistance(_self: Types.MangoESP, value: number)
		if isDestroyed then return end
		maxDistance = value
	end

	function self.SetTeamCheck(_self: Types.MangoESP, value: boolean)
		if isDestroyed then return end
		teamCheck = value
	end

	function self.AddBox(_self: Types.MangoESP, addConfig: Types.MangoESPAddConfig): Types.MangoESPHandle
		if isDestroyed then
			-- Return a no-op handle
			local noop = {} :: Types.MangoESPHandle
			function noop.SetColor(_: Types.MangoESPHandle, _color: Color3) end
			function noop.SetText(_: Types.MangoESPHandle, _text: string) end
			function noop.Destroy(_: Types.MangoESPHandle) end
			return noop
		end

		local target = addConfig.Target
		local entry = createESPEntry(
			screenGui,
			true,
			addConfig.Text ~= nil,
			false,
			showDistance,
			showTracer,
			resolve(addConfig.Color, nil, boxColor) :: Color3,
			textColor,
			fresnelStart,
			fresnelMid,
			fresnelEnd,
			fresnelMidPoint,
			strokeThickness
		)
		entry.isCustom = true
		entry.targetPart = target
		entry.customText = addConfig.Text
		entry.customColor = addConfig.Color

		if entry.nameLabel and addConfig.Text then
			(entry.nameLabel :: TextLabel).Text = addConfig.Text
		end

		entries[target] = entry

		local handle = {} :: Types.MangoESPHandle

		function handle.SetColor(_: Types.MangoESPHandle, color: Color3)
			if isDestroyed then return end
			entry.customColor = color
			entry.boxStroke.Color = color
			entry.boxFrame.BackgroundColor3 = color
			if entry.nameStroke then
				(entry.nameStroke :: UIStroke).Color = color
			end
		end

		function handle.SetText(_: Types.MangoESPHandle, text: string)
			if isDestroyed then return end
			entry.customText = text
			if entry.nameLabel then
				(entry.nameLabel :: TextLabel).Text = text
			end
		end

		function handle.Destroy(_: Types.MangoESPHandle)
			if isDestroyed then return end
			destroyEntry(target)
		end

		return handle
	end

	function self.AddText(_self: Types.MangoESP, addConfig: Types.MangoESPAddConfig): Types.MangoESPHandle
		-- AddText is like AddBox but without the box frame visible
		local target = addConfig.Target
		local entry = createESPEntry(
			screenGui,
			false,
			true,
			false,
			showDistance,
			false,
			resolve(addConfig.Color, nil, boxColor) :: Color3,
			textColor,
			fresnelStart,
			fresnelMid,
			fresnelEnd,
			fresnelMidPoint,
			strokeThickness
		)
		entry.isCustom = true
		entry.targetPart = target
		entry.customText = resolve(addConfig.Text, nil, "Text") :: string
		entry.customColor = addConfig.Color

		if entry.nameLabel then
			(entry.nameLabel :: TextLabel).Text = entry.customText :: string
		end

		entries[target] = entry

		local handle = {} :: Types.MangoESPHandle

		function handle.SetColor(_: Types.MangoESPHandle, color: Color3)
			if isDestroyed then return end
			entry.customColor = color
			if entry.nameStroke then
				(entry.nameStroke :: UIStroke).Color = color
			end
			if entry.nameTag then
				(entry.nameTag :: Frame).BackgroundColor3 = color
			end
		end

		function handle.SetText(_: Types.MangoESPHandle, text: string)
			if isDestroyed then return end
			entry.customText = text
			if entry.nameLabel then
				(entry.nameLabel :: TextLabel).Text = text
			end
		end

		function handle.Destroy(_: Types.MangoESPHandle)
			if isDestroyed then return end
			destroyEntry(target)
		end

		return handle
	end

	function self.AddModel(_self: Types.MangoESP, addConfig: Types.MangoESPAddModelConfig): Types.MangoESPHandle
		if isDestroyed then
			local noop = {} :: Types.MangoESPHandle
			function noop.SetColor(_: Types.MangoESPHandle, _color: Color3) end
			function noop.SetText(_: Types.MangoESPHandle, _text: string) end
			function noop.Destroy(_: Types.MangoESPHandle) end
			return noop
		end

		local targetModel = addConfig.Target
		-- Resolve a tracking part from the model
		local trackPart = targetModel.PrimaryPart
			or targetModel:FindFirstChildWhichIsA("BasePart") :: BasePart?
		if not trackPart then
			-- No part yet, wait for one
			local waitConn: RBXScriptConnection? = nil
			waitConn = targetModel.DescendantAdded:Connect(function(desc)
				if isDestroyed then
					if waitConn then (waitConn :: RBXScriptConnection):Disconnect() end
					return
				end
				if desc:IsA("BasePart") then
					if waitConn then (waitConn :: RBXScriptConnection):Disconnect() end
					-- Recursively call AddModel now that a part exists
					local h = self:AddModel(addConfig)
					-- The handle is already set up, nothing more to do
					_ = h
				end
			end)
			table.insert(connections, waitConn :: RBXScriptConnection)
			-- Return a handle that can still destroy
			local earlyHandle = {} :: Types.MangoESPHandle
			function earlyHandle.SetColor(_: Types.MangoESPHandle, _color: Color3) end
			function earlyHandle.SetText(_: Types.MangoESPHandle, _text: string) end
			function earlyHandle.Destroy(_: Types.MangoESPHandle)
				if waitConn then (waitConn :: RBXScriptConnection):Disconnect() end
				destroyEntry(targetModel)
			end
			return earlyHandle
		end

		local color = resolve(addConfig.Color, nil, boxColor) :: Color3
		local text = resolve(addConfig.Text, nil, targetModel.Name) :: string
		local showBoxForModel = resolve(addConfig.ShowBox, nil, true) :: boolean

		local entry = createESPEntry(
			screenGui,
			showBoxForModel,
			true,
			false,
			showDistance,
			showTracer,
			color,
			textColor,
			fresnelStart,
			fresnelMid,
			fresnelEnd,
			fresnelMidPoint,
			strokeThickness
		)
		entry.isCustom = true
		entry.targetPart = trackPart
		entry.targetModel = targetModel
		entry.customText = text
		entry.customColor = addConfig.Color

		if entry.nameLabel then
			(entry.nameLabel :: TextLabel).Text = text
		end

		entries[targetModel] = entry

		-- Auto-cleanup when model is destroyed
		local removingConn: RBXScriptConnection? = nil
		removingConn = targetModel.AncestryChanged:Connect(function(_, newParent)
			if isDestroyed then
				if removingConn then (removingConn :: RBXScriptConnection):Disconnect() end
				return
			end
			if not newParent then
				if removingConn then (removingConn :: RBXScriptConnection):Disconnect() end
				destroyEntry(targetModel)
			end
		end)
		table.insert(connections, removingConn :: RBXScriptConnection)

		local handle = {} :: Types.MangoESPHandle

		function handle.SetColor(_: Types.MangoESPHandle, newColor: Color3)
			if isDestroyed then return end
			entry.customColor = newColor
			entry.boxStroke.Color = newColor
			entry.boxFrame.BackgroundColor3 = newColor
			if entry.nameStroke then
				(entry.nameStroke :: UIStroke).Color = newColor
			end
		end

		function handle.SetText(_: Types.MangoESPHandle, newText: string)
			if isDestroyed then return end
			entry.customText = newText
			if entry.nameLabel then
				(entry.nameLabel :: TextLabel).Text = newText
			end
		end

		function handle.Destroy(_: Types.MangoESPHandle)
			if isDestroyed then return end
			if removingConn then (removingConn :: RBXScriptConnection):Disconnect() end
			destroyEntry(targetModel)
		end

		return handle
	end

	function self.Enable(_self: Types.MangoESP)
		if isDestroyed then return end
		enabled = true
	end

	function self.Disable(_self: Types.MangoESP)
		if isDestroyed then return end
		enabled = false
	end

	function self.Destroy(_self: Types.MangoESP)
		if isDestroyed then return end
		isDestroyed = true
		enabled = false

		-- Unbind render step
		pcall(function()
			RunService:UnbindFromRenderStep(bindingName)
		end)

		-- Disconnect all connections
		for _, conn in connections do
			conn:Disconnect()
		end
		connections = {}

		-- Destroy all entries
		for key, entry in entries do
			if entry.tracer then
				(entry.tracer :: Frame):Destroy()
			end
			entry.container:Destroy()
		end
		entries = {}

		-- Destroy screen gui
		screenGui:Destroy()
	end

	return self
end

return module
