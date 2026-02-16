--// AutoFarmTP — MangoLiquidUI Auto Farm with Corruption Teleport
--// Flow: Toggle Auto Farm → Spawn Vehicle → Corrupt State → Chain Hop
--// Works with loadstring(game:HttpGet(...))()
--//
--// CUSTOMIZE: Edit VEHICLES, SPAWN_REMOTE, and getFarmTargets() for your game.

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local Workspace  = game:GetService("Workspace")

local LP  = Players.LocalPlayer
local CAM = Workspace.CurrentCamera

-- ═══════════════════════════════════════════════
--  LOAD UI
-- ═══════════════════════════════════════════════
local ui
if getgenv and getgenv().MangoLiquidUI then
	ui = getgenv().MangoLiquidUI
else
	local ok, result = pcall(function()
		return loadstring(game:HttpGet(
			"https://raw.githubusercontent.com/ozon-development/MangoLiquidUI/master/dist/MangoLiquidUI.lua"
		))()
	end)
	if ok and result then
		ui = result
		if getgenv then getgenv().MangoLiquidUI = ui end
	else
		warn("AutoFarmTP: Failed to load MangoLiquidUI:", result)
		return
	end
end

ui.intro.skip()

-- ═══════════════════════════════════════════════
--  GAME CONFIG — Customize these for your game
-- ═══════════════════════════════════════════════

-- Vehicle names available in the game's spawn system
local VEHICLES = { "BMX", "ATV", "Dirtbike" }

-- Remote path for spawning vehicles: game.ReplicatedStorage.<SPAWN_REMOTE>
-- Set to nil to skip spawning (if vehicle already exists)
local SPAWN_REMOTE = "SpawnVehicle" -- or "Remotes/SpawnVehicle", etc.

-- Farm targets: return a list of Vector3 positions to loop through.
-- Override this function for your game's specific objectives.
local function getFarmTargets(): {Vector3}
	-- Example: static waypoints
	-- return { Vector3.new(100, 0, 200), Vector3.new(-50, 0, 300) }

	-- Example: find all parts named "Objective" or with CollectTag attribute
	local targets = {}
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj:IsA("BasePart") and (obj.Name == "Objective" or obj:GetAttribute("Collectible")) then
			table.insert(targets, obj.Position)
		end
	end
	return targets
end

-- ═══════════════════════════════════════════════
--  TELEPORT CONFIG
-- ═══════════════════════════════════════════════
local CFG = {
	HopDist       = 25,
	PromptWait    = 0.10,
	GroundClamp   = true,
	GroundOffset  = 3,
	ArrivalDist   = 15,
	CorruptCycles = 5,
}

-- ═══════════════════════════════════════════════
--  STATE
-- ═══════════════════════════════════════════════
local farming    = false
local corrupted  = false
local hopCancel  = false

-- ═══════════════════════════════════════════════
--  HELPERS
-- ═══════════════════════════════════════════════
local function gc()  return LP.Character end
local function hrp() local c = gc(); return c and c:FindFirstChild("HumanoidRootPart") end
local function hum() local c = gc(); return c and c:FindFirstChildOfClass("Humanoid") end

local function waitFrames(n)
	for _ = 1, n do RunService.Heartbeat:Wait() end
end

local function getVehicle()
	local vf = Workspace:FindFirstChild("Vehicles")
	if not vf then return nil end
	for _, v in ipairs(vf:GetChildren()) do
		if v:GetAttribute("OwnerUserId") == LP.UserId then return v end
	end
	return nil
end

local function getSeat(veh)
	if not veh then return nil end
	for _, d in ipairs(veh:GetDescendants()) do
		if d:IsA("VehicleSeat") and d.Name == "DriverSeat" then return d end
	end
	for _, d in ipairs(veh:GetDescendants()) do
		if d:IsA("VehicleSeat") or d:IsA("Seat") then return d end
	end
	return nil
end

local function getPrompt(veh)
	if not veh then return nil end
	local seat = getSeat(veh)
	if seat then
		for _, d in ipairs(seat:GetDescendants()) do
			if d:IsA("ProximityPrompt") then return d end
		end
		for _, d in ipairs(seat:GetChildren()) do
			if d:IsA("ProximityPrompt") then return d end
		end
	end
	for _, d in ipairs(veh:GetDescendants()) do
		if d:IsA("ProximityPrompt") then
			local pn = d.Parent and d.Parent.Name:lower() or ""
			if pn:find("driver") then return d end
		end
	end
	for _, d in ipairs(veh:GetDescendants()) do
		if d:IsA("ProximityPrompt") then return d end
	end
	return nil
end

local function groundY(pos)
	if not CFG.GroundClamp then return pos.Y end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local filter = {}
	local c = gc(); if c then table.insert(filter, c) end
	local v = getVehicle(); if v then table.insert(filter, v) end
	params.FilterDescendantsInstances = filter
	local ray = Workspace:Raycast(Vector3.new(pos.X, pos.Y + 100, pos.Z), Vector3.new(0, -300, 0), params)
	if ray then return ray.Position.Y + CFG.GroundOffset end
	return pos.Y
end

-- ═══════════════════════════════════════════════
--  VEHICLE SPAWNING
-- ═══════════════════════════════════════════════
local function spawnVehicle(name)
	if getVehicle() then return true end

	if not SPAWN_REMOTE then return false end

	-- Walk the path (supports "Remotes/SpawnVehicle" style)
	local current = game:GetService("ReplicatedStorage")
	for segment in SPAWN_REMOTE:gmatch("[^/]+") do
		current = current:FindFirstChild(segment)
		if not current then
			warn("AutoFarmTP: Remote not found:", SPAWN_REMOTE)
			return false
		end
	end

	pcall(function()
		if current:IsA("RemoteEvent") then
			current:FireServer(name)
		elseif current:IsA("RemoteFunction") then
			current:InvokeServer(name)
		end
	end)

	-- Wait for vehicle to appear
	local waited = 0
	while waited < 5 do
		if getVehicle() then return true end
		task.wait(0.2)
		waited = waited + 0.2
	end
	return getVehicle() ~= nil
end

-- ═══════════════════════════════════════════════
--  CORRUPTION — PlatformStand state corruption
--  Sits in vehicle via prompt, disables humanoid
--  state transitions, then exits seat. Server still
--  sees SeatPart reference = no snapback on TP.
-- ═══════════════════════════════════════════════
local function isCorrupted()
	local h = hum()
	if not h then return false end
	return (not h.Sit) and (h.SeatPart ~= nil)
end

local function lockStates(h)
	pcall(function()
		h.PlatformStand = true
		h:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
		h:SetStateEnabled(Enum.HumanoidStateType.Running, false)
		h:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
		h:SetStateEnabled(Enum.HumanoidStateType.Landed, false)
	end)
end

local function corrupt()
	if isCorrupted() then corrupted = true; return true end

	local veh = getVehicle()
	local h = hum()
	local r = hrp()
	if not veh or not h or not r then return false end

	local prompt = getPrompt(veh)
	if not prompt then return false end

	for i = 1, CFG.CorruptCycles do
		r = hrp(); h = hum()
		if not r or not h then break end

		-- Lock humanoid state machine
		lockStates(h)
		waitFrames(1)

		-- Bring vehicle close
		local look = r.CFrame.LookVector
		local nearPos = r.Position + look * 5 + Vector3.new(0, 1, 0)
		pcall(function()
			for _, p in ipairs(veh:GetDescendants()) do
				if p:IsA("BasePart") then
					p.Anchored = true
					p.AssemblyLinearVelocity = Vector3.zero
				end
			end
			veh:PivotTo(CFrame.new(nearPos) * CFrame.lookAt(Vector3.zero, look).Rotation)
			for _, p in ipairs(veh:GetDescendants()) do
				if p:IsA("BasePart") then p.Anchored = false end
			end
		end)
		waitFrames(2)

		-- Fire proximity prompt
		pcall(function() fireproximityprompt(prompt) end)

		-- Wait for server seat confirmation
		local waited = 0
		local seated = false
		while waited < 0.5 do
			if h.SeatPart then seated = true; break end
			RunService.Heartbeat:Wait()
			waited = waited + 0.016
		end

		if not seated then continue end

		if h.SeatPart.Name ~= "DriverSeat" then
			pcall(function() h.Sit = false end)
			waitFrames(5)
			continue
		end

		-- Seated in DriverSeat — move vehicle forward then dirty unseat
		waitFrames(1)
		r = hrp()
		if r then
			local fwd = r.CFrame.LookVector
			local fwdPos = r.Position + fwd * 25
			fwdPos = Vector3.new(fwdPos.X, groundY(fwdPos), fwdPos.Z)
			pcall(function()
				veh:PivotTo(CFrame.new(fwdPos) * CFrame.lookAt(Vector3.zero, fwd).Rotation)
			end)
		end
		waitFrames(1)

		-- Dirty unseat: states are locked so SeatPart reference orphans
		pcall(function() h.Sit = false end)
		waitFrames(1)

		-- Anchor vehicle to freeze glitch
		pcall(function()
			for _, p in ipairs(veh:GetDescendants()) do
				if p:IsA("BasePart") then
					p.Anchored = true
					p.AssemblyLinearVelocity = Vector3.zero
				end
			end
		end)
		waitFrames(1)

		if isCorrupted() then break end

		lockStates(h)
		waitFrames(2)
	end

	corrupted = isCorrupted()

	if corrupted then
		-- Simulate E key to finalize exit without re-seating
		pcall(function()
			local vim = game:GetService("VirtualInputManager")
			vim:SendKeyEvent(true, Enum.KeyCode.E, false, game)
			task.wait(0.05)
			vim:SendKeyEvent(false, Enum.KeyCode.E, false, game)
		end)
	end

	-- Keep vehicle anchored
	pcall(function()
		local veh2 = getVehicle()
		if veh2 then
			for _, p in ipairs(veh2:GetDescendants()) do
				if p:IsA("BasePart") then p.Anchored = true end
			end
		end
	end)

	return corrupted
end

-- ═══════════════════════════════════════════════
--  SINGLE HOP — one prompt cycle forward
-- ═══════════════════════════════════════════════
local function singleHop(target)
	local r = hrp()
	local h = hum()
	local veh = getVehicle()
	if not r or not h or not veh then return false end

	local prompt = getPrompt(veh)
	if not prompt then return false end

	local startPos = r.Position
	local dir = (target - startPos)
	local flatDir = Vector3.new(dir.X, 0, dir.Z)
	if flatDir.Magnitude < 1 then return true end
	flatDir = flatDir.Unit

	-- Bring vehicle close
	local nearPos = r.Position + flatDir * 5 + Vector3.new(0, 1, 0)
	pcall(function()
		for _, p in ipairs(veh:GetDescendants()) do
			if p:IsA("BasePart") then
				p.Anchored = true
				p.AssemblyLinearVelocity = Vector3.zero
			end
		end
		veh:PivotTo(CFrame.new(nearPos) * CFrame.lookAt(Vector3.zero, flatDir).Rotation)
		for _, p in ipairs(veh:GetDescendants()) do
			if p:IsA("BasePart") then
				p.Anchored = false
				p.AssemblyLinearVelocity = Vector3.zero
			end
		end
	end)
	waitFrames(1)

	-- Keep states locked
	lockStates(h)

	-- Fire prompt
	pcall(function() fireproximityprompt(prompt) end)
	local waited = 0
	local seated = false
	while waited < CFG.PromptWait do
		if h.SeatPart then seated = true; break end
		RunService.Heartbeat:Wait()
		waited = waited + 0.016
	end

	if not seated then
		-- Retry once closer
		r = hrp()
		if r then
			pcall(function()
				for _, p in ipairs(veh:GetDescendants()) do
					if p:IsA("BasePart") then p.Anchored = true end
				end
				veh:PivotTo(CFrame.new(r.Position + flatDir * 3 + Vector3.new(0, 0.5, 0))
					* CFrame.lookAt(Vector3.zero, flatDir).Rotation)
				for _, p in ipairs(veh:GetDescendants()) do
					if p:IsA("BasePart") then p.Anchored = false end
				end
			end)
			waitFrames(1)
			pcall(function() fireproximityprompt(prompt) end)
			waited = 0
			while waited < CFG.PromptWait do
				if h.SeatPart then seated = true; break end
				RunService.Heartbeat:Wait()
				waited = waited + 0.016
			end
		end
	end

	if not seated then return false end
	if h.SeatPart.Name ~= "DriverSeat" then
		pcall(function() h.Sit = false end)
		waitFrames(1)
		return false
	end

	-- Move vehicle forward toward target
	waitFrames(1)
	r = hrp()
	if r then
		local remaining = (target - r.Position)
		local fdir = Vector3.new(remaining.X, 0, remaining.Z)
		if fdir.Magnitude > 1 then fdir = fdir.Unit else fdir = flatDir end
		local hopSize = math.min(CFG.HopDist, Vector3.new(remaining.X, 0, remaining.Z).Magnitude)
		local fwdPos = r.Position + fdir * hopSize
		fwdPos = Vector3.new(fwdPos.X, groundY(fwdPos), fwdPos.Z)
		pcall(function()
			veh:PivotTo(CFrame.new(fwdPos) * CFrame.lookAt(Vector3.zero, fdir).Rotation)
		end)
	end
	waitFrames(1)

	-- Exit seat
	pcall(function() h.Sit = false end)
	waitFrames(1)

	-- Re-lock states
	lockStates(h)

	-- Anchor vehicle
	pcall(function()
		for _, p in ipairs(veh:GetDescendants()) do
			if p:IsA("BasePart") then
				p.Anchored = true
				p.AssemblyLinearVelocity = Vector3.zero
			end
		end
	end)
	waitFrames(1)

	return true
end

-- ═══════════════════════════════════════════════
--  CHAIN HOP — auto-path to a target position
-- ═══════════════════════════════════════════════
local function chainHop(target, onProgress)
	hopCancel = false
	local finalTarget = Vector3.new(target.X, groundY(target), target.Z)
	local hops = 0
	local retries = 0

	while not hopCancel and hops < 200 do
		local r = hrp()
		if not r then task.wait(0.5); continue end

		local flatPos = Vector3.new(r.Position.X, 0, r.Position.Z)
		local flatTarget = Vector3.new(finalTarget.X, 0, finalTarget.Z)
		local remaining = (flatTarget - flatPos).Magnitude

		if remaining < CFG.ArrivalDist then break end

		-- Keep states locked
		local h = hum()
		if h then lockStates(h) end

		-- Hop toward target
		local dir = (flatTarget - flatPos).Unit
		local hopSize = math.min(CFG.HopDist, remaining)
		local nextPos = r.Position + dir * hopSize
		nextPos = Vector3.new(nextPos.X, groundY(nextPos), nextPos.Z)

		local ok = singleHop(nextPos)
		hops = hops + 1

		if ok then
			retries = 0
			if onProgress then
				onProgress(hops, remaining)
			end
		else
			retries = retries + 1
			if retries >= 3 then break end
			task.wait(0.3)
		end
	end

	return hops
end

-- ═══════════════════════════════════════════════
--  FARM LOOP
-- ═══════════════════════════════════════════════
local function startFarm(window)
	if farming then return end
	farming = true
	hopCancel = false

	task.spawn(function()
		-- Step 1: Spawn vehicle
		local vehName = window.Flags.SelectedVehicle or VEHICLES[1]
		window:Notify({ Title = "Spawning", Body = "Spawning " .. vehName .. "..." })

		local spawned = spawnVehicle(vehName)
		if not spawned and not getVehicle() then
			window:Notify({ Title = "Error", Body = "Vehicle not found. Spawn it manually." })
			-- Wait for manual vehicle
			local waitTime = 0
			while not getVehicle() and waitTime < 15 and farming do
				task.wait(1)
				waitTime = waitTime + 1
			end
			if not getVehicle() then
				window:Notify({ Title = "Error", Body = "No vehicle found, stopping." })
				farming = false
				return
			end
		end

		-- Step 2: Corrupt state (if enabled)
		if window.Flags.CorruptionEnabled then
			if corrupted and not isCorrupted() then
				corrupted = false
			end
			if not corrupted then
				window:Notify({ Title = "Corrupting", Body = "Building corrupted state..." })
				local ok = corrupt()
				if not ok then
					window:Notify({ Title = "Warning", Body = "Corruption failed, hops may snap back." })
				else
					window:Notify({ Title = "Corrupted", Body = "State corrupted, no snapback." })
				end
			end
		end

		if not farming then return end

		-- Step 3: Farm loop
		window:Notify({ Title = "Farming", Body = "Auto farm started." })
		local loopCount = 0

		while farming do
			local targets = getFarmTargets()
			if #targets == 0 then
				window:Notify({ Title = "Waiting", Body = "No targets found, retrying..." })
				task.wait(3)
				continue
			end

			-- Sort by distance
			local r = hrp()
			if r then
				local pos = r.Position
				table.sort(targets, function(a, b)
					return (a - pos).Magnitude < (b - pos).Magnitude
				end)
			end

			for _, target in ipairs(targets) do
				if not farming then break end

				-- Re-check corruption between chains
				if window.Flags.CorruptionEnabled and corrupted and not isCorrupted() then
					window:Notify({ Title = "Re-corrupting", Body = "State lost, rebuilding..." })
					corrupted = false
					corrupt()
				end

				chainHop(target, function(hops, remaining)
					-- Progress callback (optional: update UI)
				end)

				loopCount = loopCount + 1

				-- Brief pause between targets
				if farming then task.wait(0.5) end
			end

			-- Loop back to start for continuous farming
			if farming then task.wait(1) end
		end
	end)
end

local function stopFarm()
	farming = false
	hopCancel = true
	-- Note: corruption is NOT cleaned up — persists for next farm session
end

-- ═══════════════════════════════════════════════
--  UI — MangoWindow
-- ═══════════════════════════════════════════════
local Window = ui.window({
	Name = "Auto Farm",
	Theme = ui.Dark,
	Size = UDim2.new(0, 300, 0, 300),
	ToggleKey = "RightShift",
	ShowButton = "Farm",
})

local Main = Window:Tab("Main")

Main:Toggle({
	Name = "Auto Farm",
	Default = false,
	Flag = "AutoFarmEnabled",
	Callback = function(enabled)
		if enabled then
			startFarm(Window)
		else
			stopFarm()
		end
	end,
})

Main:Toggle({
	Name = "Corruption",
	Default = true,
	Flag = "CorruptionEnabled",
})

Main:Dropdown({
	Name = "Vehicle",
	Options = VEHICLES,
	Default = VEHICLES[1],
	Flag = "SelectedVehicle",
})

Main:Slider({
	Name = "Hop Distance",
	Range = {10, 100},
	Default = 25,
	Increment = 5,
	Suffix = " studs",
	Flag = "HopDist",
	Callback = function(value)
		CFG.HopDist = value
	end,
})

Main:Slider({
	Name = "Arrival Dist",
	Range = {5, 50},
	Default = 15,
	Increment = 5,
	Suffix = " studs",
	Flag = "ArrivalDist",
	Callback = function(value)
		CFG.ArrivalDist = value
	end,
})

local Settings = Window:Tab("Settings")

Settings:Toggle({
	Name = "Ground Clamp",
	Default = true,
	Flag = "GroundClamp",
	Callback = function(enabled)
		CFG.GroundClamp = enabled
	end,
})

Settings:Slider({
	Name = "Ground Offset",
	Range = {0, 10},
	Default = 3,
	Increment = 0.5,
	Suffix = " studs",
	Flag = "GroundOffset",
	Callback = function(value)
		CFG.GroundOffset = value
	end,
})

Settings:Slider({
	Name = "Corrupt Cycles",
	Range = {1, 10},
	Default = 5,
	Increment = 1,
	Flag = "CorruptCycles",
	Callback = function(value)
		CFG.CorruptCycles = value
	end,
})

Settings:Button({
	Name = "Force Re-corrupt",
	Callback = function()
		corrupted = false
		Window:Notify({ Title = "Reset", Body = "Corruption cleared, will re-corrupt on next farm." })
	end,
})

Settings:Button({
	Name = "Clean Up States",
	Callback = function()
		local h = hum()
		if h then
			pcall(function()
				h.PlatformStand = false
				h.Sit = false
				h:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
				h:SetStateEnabled(Enum.HumanoidStateType.Running, true)
				h:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
				h:SetStateEnabled(Enum.HumanoidStateType.Landed, true)
				h:ChangeState(Enum.HumanoidStateType.GettingUp)
			end)
		end
		corrupted = false
		Window:Notify({ Title = "Cleaned", Body = "Humanoid states restored." })
	end,
})

-- Re-apply corruption on respawn
LP.CharacterAdded:Connect(function()
	task.wait(2)
	if farming and Window.Flags.CorruptionEnabled then
		corrupted = false
		corrupt()
	end
end)

Window:Show()
