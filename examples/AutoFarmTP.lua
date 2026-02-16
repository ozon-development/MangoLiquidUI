--// AutoFarmTP — MangoLiquidUI Auto Farm with Corruption Teleport
--// Keeps the EXACT original Mango Teleport v3 corruption logic intact.
--// Only replaces the basic GUI with MangoWindow and adds spawn → corrupt → farm flow.
--//
--// CUSTOMIZE: Edit VEHICLES, SPAWN_REMOTE, and getFarmTargets() for your game.

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui    = game:GetService("CoreGui")
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
local function getFarmTargets()
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
--  CONFIG (from original Mango Teleport v3)
-- ═══════════════════════════════════════════════
local CFG = {
	HopDist      = 25,     -- studs per hop (matching original's VEH_FWD 25)
	PromptWait   = 0.10,   -- max wait for server seat confirm
	HopDelay     = 0,      -- no extra pause between hops when corrupted
	GroundClamp  = true,
	GroundOffset = 3,
	ArrivalDist  = 15,     -- close enough to target
	Corrupt      = true,   -- enable PlatformStand corruption
	CorruptCycles = 5,     -- prompt cycles to build corrupted state
}

-- ═══════════════════════════════════════════════
--  STATE (from original)
-- ═══════════════════════════════════════════════
local Picking    = false
local Hopping    = false
local HopCancel  = false
local Corrupted  = false
local StartWS    = Workspace.DistributedGameTime
local FrameNum   = 0
local LastRec    = 0
local LastPos    = nil
local Log        = {}
local Stats      = { Teleports = 0, TotalDist = 0, MaxJump = 0, Snapbacks = 0, Fails = 0, Chains = 0 }

-- Farm state
local farming = false

-- ═══════════════════════════════════════════════
--  HELPERS (from original, verbatim)
-- ═══════════════════════════════════════════════
local gc  = function() return LP.Character end
local hrp = function() local c = gc(); return c and c:FindFirstChild("HumanoidRootPart") end
local hum = function() local c = gc(); return c and c:FindFirstChildOfClass("Humanoid") end

local function ts()  return string.format("%.3f", Workspace.DistributedGameTime - StartWS) end
local function v3s(v) return v and string.format("%.1f,%.1f,%.1f", v.X, v.Y, v.Z) or "nil" end

local function log(s)
	FrameNum = FrameNum + 1
	local line = string.format("[%s] %s", ts(), s)
	if #Log < 50000 then table.insert(Log, line) end
end

local function getVehicle()
	local vf = workspace:FindFirstChild("Vehicles")
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
	-- First: try to find prompt that is a child/descendant of DriverSeat
	local driverSeat = getSeat(veh)
	if driverSeat then
		for _, d in ipairs(driverSeat:GetDescendants()) do
			if d:IsA("ProximityPrompt") then return d end
		end
		-- Check direct children
		for _, d in ipairs(driverSeat:GetChildren()) do
			if d:IsA("ProximityPrompt") then return d end
		end
	end
	-- Second: find prompt whose parent name contains "driver" (case insensitive)
	for _, d in ipairs(veh:GetDescendants()) do
		if d:IsA("ProximityPrompt") then
			local parentName = d.Parent and d.Parent.Name:lower() or ""
			if parentName:find("driver") then return d end
		end
	end
	-- Third: find prompt whose ActionText/ObjectText mentions "drive"
	for _, d in ipairs(veh:GetDescendants()) do
		if d:IsA("ProximityPrompt") then
			local action = (d.ActionText or ""):lower()
			local obj = (d.ObjectText or ""):lower()
			if action:find("driv") or obj:find("driv") then return d end
		end
	end
	-- Last resort: log all prompts and return first
	local allPrompts = {}
	for _, d in ipairs(veh:GetDescendants()) do
		if d:IsA("ProximityPrompt") then
			table.insert(allPrompts, d)
			log(string.format("PROMPT_FOUND: %s parent=%s action='%s' obj='%s'",
				d.Name, d.Parent and d.Parent.Name or "nil",
				d.ActionText or "", d.ObjectText or ""))
		end
	end
	return allPrompts[1]
end

local function groundY(pos)
	if not CFG.GroundClamp then return pos.Y end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local filter = {}
	local c = gc(); if c then table.insert(filter, c) end
	local v = getVehicle(); if v then table.insert(filter, v) end
	params.FilterDescendantsInstances = filter
	local ray = workspace:Raycast(Vector3.new(pos.X, pos.Y + 100, pos.Z), Vector3.new(0, -300, 0), params)
	if ray then return ray.Position.Y + CFG.GroundOffset end
	return pos.Y
end

-- ═══════════════════════════════════════════════
--  DEEP DIAGNOSTICS (from original, verbatim)
-- ═══════════════════════════════════════════════

-- Full vehicle state dump
local function dumpVehicle(tag)
	local veh = getVehicle()
	log(string.format("=== DUMP [%s] ===", tag))

	if not veh then
		log("  VEH: nil")
	else
		log(string.format("  VEH: %s children=%d", veh.Name, #veh:GetChildren()))
		local pivot = veh:GetPivot()
		log(string.format("  VEH_POS: %s", v3s(pivot.Position)))

		-- All seats
		for _, d in ipairs(veh:GetDescendants()) do
			if d:IsA("Seat") or d:IsA("VehicleSeat") then
				log(string.format("  SEAT: %s class=%s pos=%s anchored=%s",
					d.Name, d.ClassName, v3s(d.Position),
					tostring(d.Anchored)))
				local occ = d.Occupant
				log(string.format("    occupant=%s", occ and occ:GetFullName() or "nil"))
			end
		end

		-- All welds
		for _, d in ipairs(veh:GetDescendants()) do
			if d:IsA("Weld") or d:IsA("WeldConstraint") then
				local p0 = d:IsA("Weld") and d.Part0 or d:IsA("WeldConstraint") and d.Part0 or nil
				local p1 = d:IsA("Weld") and d.Part1 or d:IsA("WeldConstraint") and d.Part1 or nil
				log(string.format("  WELD: %s class=%s p0=%s p1=%s parent=%s",
					d.Name, d.ClassName,
					p0 and p0.Name or "nil",
					p1 and p1.Name or "nil",
					d.Parent and d.Parent.Name or "nil"))
			end
		end

		-- All ProximityPrompts
		for _, d in ipairs(veh:GetDescendants()) do
			if d:IsA("ProximityPrompt") then
				log(string.format("  PROMPT: %s parent=%s enabled=%s dist=%.0f",
					d.Name, d.Parent and d.Parent.Name or "nil",
					tostring(d.Enabled), d.MaxActivationDistance))
			end
		end

		-- All BaseParts with position
		local parts = {}
		for _, d in ipairs(veh:GetDescendants()) do
			if d:IsA("BasePart") then
				table.insert(parts, d)
			end
		end
		log(string.format("  PARTS: %d total", #parts))
		for i, p in ipairs(parts) do
			if i > 10 then log("    ... (truncated)"); break end
			local netOwner = "?"
			pcall(function()
				local no = p:GetNetworkOwner()
				netOwner = no and no.Name or "server"
			end)
			log(string.format("    %s pos=%s anch=%s net=%s",
				p.Name, v3s(p.Position), tostring(p.Anchored), netOwner))
		end
	end

	-- Humanoid state
	local h = hum()
	local r = hrp()
	if h then
		log(string.format("  HUM: sit=%s sp=%s ps=%s state=%s hp=%.0f",
			tostring(h.Sit),
			h.SeatPart and h.SeatPart.Name or "nil",
			tostring(h.PlatformStand),
			h:GetState().Name,
			h.Health))
		if h.SeatPart then
			log(string.format("  SEATPART_POS: %s (player at %s, dist=%.1f)",
				v3s(h.SeatPart.Position),
				r and v3s(r.Position) or "nil",
				r and (h.SeatPart.Position - r.Position).Magnitude or -1))
		end
	else
		log("  HUM: nil")
	end

	if r then
		log(string.format("  PLAYER_POS: %s vel=%s",
			v3s(r.Position), v3s(r.AssemblyLinearVelocity)))
	end

	-- Check for second vehicle
	local vf = workspace:FindFirstChild("Vehicles")
	if vf then
		local myVehs = 0
		for _, v in ipairs(vf:GetChildren()) do
			if v:GetAttribute("OwnerUserId") == LP.UserId then
				myVehs = myVehs + 1
			end
		end
		if myVehs > 1 then
			log(string.format("  WARNING: %d vehicles owned by player!", myVehs))
		end
	end

	log("=== END DUMP ===")
end

-- ═══════════════════════════════════════════════
--  CORRUPTION (from original, verbatim)
-- ═══════════════════════════════════════════════
local function isCorrupted()
	local h = hum()
	if not h then return false end
	-- Corrupted = not sitting but server still thinks we have a SeatPart
	return (not h.Sit) and (h.SeatPart ~= nil)
end

local function corrupt()
	if not CFG.Corrupt then Corrupted = true; return true end
	if isCorrupted() then Corrupted = true; log("ALREADY_CORRUPT"); return true end

	local veh = getVehicle()
	local h = hum()
	local r = hrp()
	if not veh or not h or not r then log("CORRUPT_FAIL: missing"); return false end

	local prompt = getPrompt(veh)
	if not prompt then log("CORRUPT_FAIL: no prompt"); return false end

	log("CORRUPT_START (Frame-Perfect Mode)")
	dumpVehicle("CORRUPT_START")

	-- Helper to wait exact frames
	local function waitFrames(n)
		for _=1, n do RunService.Heartbeat:Wait() end
	end

	for i = 1, CFG.CorruptCycles do
		r = hrp()
		h = hum()
		if not r or not h then break end

		-- FRAME 0: Pre-setup (Trap the state machine)
		pcall(function()
			h.PlatformStand = true
			h:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
			h:SetStateEnabled(Enum.HumanoidStateType.Running, false)
			h:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
			h:SetStateEnabled(Enum.HumanoidStateType.Landed, false)
		end)
		waitFrames(1)

		-- FRAME 1: Bring vehicle close
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
		waitFrames(2) -- Give physics a moment to wake up

		-- FRAME 2: Fire prompt
		pcall(function() fireproximityprompt(prompt) end)

		-- WAIT for Server Seat (This is the only variable timing part)
		local waited = 0
		local seated = false
		while waited < 0.5 do
			if h.SeatPart then seated = true; break end
			RunService.Heartbeat:Wait()
			waited = waited + 0.016
		end

		if not seated then
			log(string.format("CORRUPT_CYCLE %d/%d prompt_fail", i, CFG.CorruptCycles))
		elseif h.SeatPart.Name ~= "DriverSeat" then
			log(string.format("CORRUPT_CYCLE %d/%d wrong_seat=%s", i, CFG.CorruptCycles, h.SeatPart.Name))
			pcall(function() h.Sit = false end)
			waitFrames(5)
		else
			-- WE ARE SEATED. Now execute the critical sequence.
			-- Server sees us welded.

			-- FRAME 3: Move vehicle forward 25 studs (Player moves with it via SeatWeld)
			waitFrames(1) -- Ensure seatweld is solid

			r = hrp()
			if r then
				local fwd = r.CFrame.LookVector
				local fwdPos = r.Position + fwd * 25
				fwdPos = Vector3.new(fwdPos.X, groundY(fwdPos), fwdPos.Z)
				pcall(function()
					veh:PivotTo(CFrame.new(fwdPos) * CFrame.lookAt(Vector3.zero, fwd).Rotation)
				end)
			end
			waitFrames(1) -- Let the move register transparency-wise

			-- FRAME 4: THE DIRTY UNSEAT
			-- We set Sit=false, but because states are disabled (GettingUp/Running),
			-- the cleanup logic traps and leaves the SeatPart reference "orphaned".
			pcall(function() h.Sit = false end)
			waitFrames(1)

			-- FRAME 5: Anchor everything to freeze the glitch
			pcall(function()
				for _, p in ipairs(veh:GetDescendants()) do
					if p:IsA("BasePart") then
						p.Anchored = true
						p.AssemblyLinearVelocity = Vector3.zero
					end
				end
			end)
			waitFrames(1)

			-- Check result
			log(string.format("CORRUPT_CYCLE %d/%d sit=%s sp=%s ps=%s",
				i, CFG.CorruptCycles,
				tostring(h.Sit), h.SeatPart and h.SeatPart.Name or "nil",
				tostring(h.PlatformStand)))

			if isCorrupted() then
				log("CORRUPT_SUCCESS at cycle "..i)
				break
			end
		end

		-- Reset for next cycle if failed
		pcall(function()
			h.PlatformStand = true -- Keep PS on
			h:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false) -- Keep traps on
		end)
		waitFrames(2)
	end

	-- Final Check
	Corrupted = isCorrupted()

	if Corrupted then
		log("CORRUPT SUCCESS! Simulating 'E' to exit...")

		-- STRICTLY JUST THE E KEYPRESS AS REQUESTED
		pcall(function()
			local vim = game:GetService("VirtualInputManager")
			vim:SendKeyEvent(true, Enum.KeyCode.E, false, game)
			task.wait(0.05)
			vim:SendKeyEvent(false, Enum.KeyCode.E, false, game)
		end)
	else
		-- Failed, clean up
		pcall(function()
			h:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
			h:SetStateEnabled(Enum.HumanoidStateType.Running, true)
			h:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
			h:SetStateEnabled(Enum.HumanoidStateType.Landed, true)
		end)
		log("CORRUPT FAILED")
	end

	-- Ensure anchored
	pcall(function()
		for _, p in ipairs(veh:GetDescendants()) do
			if p:IsA("BasePart") then p.Anchored = true end
		end
	end)

	log(string.format("CORRUPT_DONE result=%s", tostring(Corrupted)))
	dumpVehicle("CORRUPT_DONE")

	return Corrupted
end

-- ═══════════════════════════════════════════════
--  SINGLE HOP (from original, verbatim)
-- ═══════════════════════════════════════════════
local function singleHop(target)
	local r = hrp()
	local h = hum()
	local veh = getVehicle()
	if not r or not h or not veh then return false, "no char/veh" end

	local prompt = getPrompt(veh)
	if not prompt then return false, "no prompt" end

	local startPos = r.Position

	-- Helper to wait exact frames
	local function waitFrames(n)
		for _=1, n do RunService.Heartbeat:Wait() end
	end

	-- Direction toward target
	local dir = (target - startPos)
	local flatDir = Vector3.new(dir.X, 0, dir.Z)
	if flatDir.Magnitude < 1 then return true, 0 end -- already there
	flatDir = flatDir.Unit

	-- Step 1: teleportVehicleToPlayer — bring vehicle close (matching original)
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
	waitFrames(1) -- 1 frame (vehicle is already nearby from last hop)

	-- Step 2: Ensure PlatformStand + disabled states
	if CFG.Corrupt then
		pcall(function()
			h.PlatformStand = true
			h:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
			h:SetStateEnabled(Enum.HumanoidStateType.Running, false)
			h:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
			h:SetStateEnabled(Enum.HumanoidStateType.Landed, false)
		end)
	end

	-- Step 3: doEnter — prompt (matching original promptWait=0.10)
	pcall(function() fireproximityprompt(prompt) end)
	local waited = 0
	local seated = false
	while waited < CFG.PromptWait do
		if h.SeatPart then seated = true; break end
		RunService.Heartbeat:Wait()
		waited = waited + 0.016
	end

	if not seated then
		-- One retry with vehicle closer
		r = hrp()
		if r then
			local nearPos2 = r.Position + flatDir * 3 + Vector3.new(0, 0.5, 0)
			pcall(function()
				for _, p in ipairs(veh:GetDescendants()) do
					if p:IsA("BasePart") then p.Anchored = true end
				end
				veh:PivotTo(CFrame.new(nearPos2) * CFrame.lookAt(Vector3.zero, flatDir).Rotation)
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

	if not seated then
		Stats.Fails = Stats.Fails + 1
		return false, "prompt fail"
	end

	-- Check seat
	if h.SeatPart.Name ~= "DriverSeat" then
		pcall(function() h.Sit = false end)
		waitFrames(1)
		Stats.Fails = Stats.Fails + 1
		return false, "wrong seat"
	end

	-- Step 4: teleportVehicleForward — move vehicle FORWARD by HopDist toward target
	r = hrp()
	if r then
		local remaining = (target - r.Position)
		local fdir = Vector3.new(remaining.X, 0, remaining.Z)
		if fdir.Magnitude > 1 then fdir = fdir.Unit else fdir = flatDir end

		local hopSize = math.min(CFG.HopDist, fdir.Magnitude > 0 and (Vector3.new(remaining.X,0,remaining.Z)).Magnitude or CFG.HopDist)
		local fwdPos = r.Position + fdir * hopSize
		fwdPos = Vector3.new(fwdPos.X, groundY(fwdPos), fwdPos.Z)

		pcall(function()
			veh:PivotTo(CFrame.new(fwdPos) * CFrame.lookAt(Vector3.zero, fdir).Rotation)
		end)

		-- Log seat vs vehicle position after teleport
		local seat = getSeat(veh)
		log(string.format("AFTER_VEH_TP: player=%s seat=%s veh=%s sit=%s sp=%s",
			v3s(r.Position),
			seat and v3s(seat.Position) or "nil",
			v3s(veh:GetPivot().Position),
			tostring(h.Sit),
			h.SeatPart and h.SeatPart.Name or "nil"))
	end
	waitFrames(1) -- 1 frame (matching original)

	-- Step 5: sitExit (matching original — always exit)
	pcall(function() h.Sit = false end)
	waitFrames(1) -- 1 frame

	-- Log state after unseat
	r = hrp()
	local seat2 = getSeat(veh)
	log(string.format("AFTER_EXIT: player=%s seat=%s veh=%s sit=%s sp=%s ps=%s",
		r and v3s(r.Position) or "nil",
		seat2 and v3s(seat2.Position) or "nil",
		v3s(veh:GetPivot().Position),
		tostring(h.Sit),
		h.SeatPart and h.SeatPart.Name or "nil",
		tostring(h.PlatformStand)))

	-- Re-enable PlatformStand + keep states disabled
	if CFG.Corrupt then
		pcall(function()
			h.PlatformStand = true
			h:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
			h:SetStateEnabled(Enum.HumanoidStateType.Running, false)
			h:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
			h:SetStateEnabled(Enum.HumanoidStateType.Landed, false)
		end)
	end

	-- Step 6: anchorVehicle (matching original)
	pcall(function()
		for _, p in ipairs(veh:GetDescendants()) do
			if p:IsA("BasePart") then
				p.Anchored = true
				p.AssemblyLinearVelocity = Vector3.zero
			end
		end
	end)
	waitFrames(1) -- 1 frame

	r = hrp()
	local endPos = r and r.Position or startPos
	local moved = (endPos - startPos).Magnitude

	Stats.Teleports = Stats.Teleports + 1
	Stats.TotalDist = Stats.TotalDist + moved
	if moved > Stats.MaxJump then Stats.MaxJump = moved end

	log(string.format("HOP %s→%s moved=%.0f", v3s(startPos), v3s(endPos), moved))

	-- Snapback check
	local expected = (target - startPos).Magnitude
	if moved < expected * 0.3 and expected > 15 then
		Stats.Snapbacks = Stats.Snapbacks + 1
		log(string.format("SNAPBACK expected=%.0f got=%.0f", expected, moved))
		return false, "snapback"
	end

	return true, moved
end

-- ═══════════════════════════════════════════════
--  CHAIN HOP (from original, verbatim)
-- ═══════════════════════════════════════════════
local function chainHop(target, onProgress)
	Hopping = true
	HopCancel = false
	Stats.Chains = Stats.Chains + 1

	local clampedY = groundY(target)
	local finalTarget = Vector3.new(target.X, clampedY, target.Z)

	log(string.format("CHAIN_START to=%s", v3s(finalTarget)))

	-- Corrupt first for max range
	if CFG.Corrupt then
		-- Re-verify corruption state (may have been lost between chains)
		if Corrupted and not isCorrupted() then
			log("CORRUPT_LOST — re-corrupting")
			dumpVehicle("CORRUPT_LOST")
			Corrupted = false
		end
		if Corrupted then
			local h = hum()
			log(string.format("CORRUPT_PERSISTS sit=%s sp=%s ps=%s",
				h and tostring(h.Sit) or "?",
				h and (h.SeatPart and h.SeatPart.Name or "nil") or "?",
				h and tostring(h.PlatformStand) or "?"))
			dumpVehicle("CORRUPT_PERSISTS")
		end
		if not Corrupted then
			local ok = corrupt()
			if not ok then
				log("CHAIN_WARN: corruption failed, using safe hop dist")
			end
		end
	end

	local hops = 0
	local maxHops = 200
	local retries = 0
	local maxRetries = 3
	local effectiveDist = Corrupted and CFG.HopDist or math.min(CFG.HopDist, 45)

	log(string.format("CHAIN_USING dist=%d corrupted=%s", effectiveDist, tostring(Corrupted)))

	while not HopCancel and hops < maxHops do
		local r = hrp()
		if not r then task.wait(0.5); continue end

		local pos = r.Position
		local flatPos = Vector3.new(pos.X, 0, pos.Z)
		local flatTarget = Vector3.new(finalTarget.X, 0, finalTarget.Z)
		local remaining = (flatTarget - flatPos).Magnitude

		if remaining < CFG.ArrivalDist then
			log(string.format("CHAIN_DONE hops=%d remaining=%.0f", hops, remaining))
			dumpVehicle("CHAIN_DONE")
			break
		end

		-- Keep PlatformStand + disabled states active during chain
		if CFG.Corrupt then
			local h = hum()
			if h then pcall(function()
				h.PlatformStand = true
				h:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
				h:SetStateEnabled(Enum.HumanoidStateType.Running, false)
				h:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
				h:SetStateEnabled(Enum.HumanoidStateType.Landed, false)
			end) end
		end

		-- Calculate next hop
		local dir = (flatTarget - flatPos).Unit
		local hopSize = math.min(effectiveDist, remaining)
		local nextPos = pos + dir * hopSize
		nextPos = Vector3.new(nextPos.X, groundY(nextPos), nextPos.Z)

		local ok, result = singleHop(nextPos)
		hops = hops + 1

		-- Dump state on first hop of chain
		if hops == 1 then
			dumpVehicle("FIRST_HOP")
		end

		if ok then
			retries = 0
			if onProgress then
				onProgress(hops, remaining, result)
			end
		else
			retries = retries + 1
			log(string.format("HOP_FAIL #%d reason=%s retries=%d", hops, tostring(result), retries))
			if retries == 1 then dumpVehicle("HOP_FAIL") end
			if retries >= maxRetries then
				log("CHAIN_ABORT too many fails")
				dumpVehicle("CHAIN_ABORT")
				break
			end
			task.wait(0.3) -- brief pause before retry
		end

		if CFG.HopDelay > 0 then
			local delay = Corrupted and math.min(CFG.HopDelay, 0.15) or math.max(CFG.HopDelay, 0.8)
			task.wait(delay)
		end
	end

	Hopping = false
	HopCancel = false

	-- DON'T re-enable states here — corruption must persist between chains
	return hops
end

-- ═══════════════════════════════════════════════
--  LOG EXPORT (from original)
-- ═══════════════════════════════════════════════
local function export()
	local out = {
		"=== MANGO TELEPORT v3 LOG ===",
		"Player: "..LP.Name.." ("..LP.UserId..")",
		"Game: "..game.PlaceId.." Job: "..game.JobId,
		"Date: "..os.date("%Y-%m-%d %H:%M:%S"),
		"",
		"=== STATS ===",
		"  Teleports: "..Stats.Teleports,
		"  Chains: "..Stats.Chains,
		"  Total Distance: "..string.format("%.0f", Stats.TotalDist),
		"  Max Single Jump: "..string.format("%.0f", Stats.MaxJump),
		"  Snapbacks: "..Stats.Snapbacks,
		"  Fails: "..Stats.Fails,
		"  Corrupted: "..tostring(Corrupted),
		"",
		"=== CONFIG ===",
	}
	for k, v in pairs(CFG) do table.insert(out, "  "..k..": "..tostring(v)) end
	table.insert(out, "")
	table.insert(out, "=== LOG ===")
	for _, l in ipairs(Log) do table.insert(out, l) end

	local txt = table.concat(out, "\n")
	local fn = string.format("mango_tp3_%s_%s.txt", LP.Name, os.date("%Y%m%d_%H%M%S"))
	pcall(function() if writefile then writefile(fn, txt); warn("[Mango] Exported: "..fn) end end)
	return fn
end

-- ═══════════════════════════════════════════════
--  BACKGROUND RECORDER (from original)
-- ═══════════════════════════════════════════════
RunService.Heartbeat:Connect(function()
	local now = tick()
	if now - LastRec < 0.2 then return end
	LastRec = now
	local r = hrp()
	if not r then return end
	local pos = r.Position
	if LastPos then
		local d = (pos - LastPos).Magnitude
		if d > 15 then
			log(string.format("MOVE pos=%s d=%.0f spd=%.0f/s", v3s(pos), d, d/0.2))
		end
	end
	LastPos = pos
end)

-- ═══════════════════════════════════════════════
--  VEHICLE SPAWNING (new — customize for your game)
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
--  FARM LOOP (new — spawn → corrupt → chain hop)
-- ═══════════════════════════════════════════════
local function startFarm(window)
	if farming then return end
	farming = true
	HopCancel = false

	task.spawn(function()
		-- Step 1: Spawn vehicle
		local vehName = window.Flags.SelectedVehicle or VEHICLES[1]
		window:Notify({ Title = "Spawning", Body = "Spawning " .. vehName .. "..." })
		log("FARM_START vehicle=" .. vehName)

		local spawned = spawnVehicle(vehName)
		if not spawned and not getVehicle() then
			window:Notify({ Title = "Error", Body = "Vehicle not found. Spawn it manually." })
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

		-- Step 2: Corrupt state (no cleanup — just corrupt and go)
		if window.Flags.CorruptionEnabled then
			CFG.Corrupt = true
			if Corrupted and not isCorrupted() then
				Corrupted = false
			end
			if not Corrupted then
				window:Notify({ Title = "Corrupting", Body = "Building corrupted state..." })
				local ok = corrupt()
				if not ok then
					window:Notify({ Title = "Warning", Body = "Corruption failed, hops may snap back." })
				else
					window:Notify({ Title = "Corrupted", Body = "State corrupted, no snapback." })
				end
			end
		else
			CFG.Corrupt = false
		end

		if not farming then return end

		-- Step 3: Farm loop — chain hop to each target, repeat
		window:Notify({ Title = "Farming", Body = "Auto farm started." })
		log("FARM_LOOP_START")

		while farming do
			local targets = getFarmTargets()
			if #targets == 0 then
				window:Notify({ Title = "Waiting", Body = "No targets found, retrying in 3s..." })
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

				chainHop(target, function(hops, remaining, moved)
					-- chainHop already handles re-corruption internally
				end)

				if farming then task.wait(0.5) end
			end

			if farming then task.wait(1) end
		end

		log("FARM_LOOP_END")
	end)
end

local function stopFarm()
	farming = false
	HopCancel = true
	-- Corruption persists — NOT cleaned up
	log("FARM_STOP")
end

-- ═══════════════════════════════════════════════
--  UI — MangoWindow (replaces original basic GUI)
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
		Corrupted = false
		Window:Notify({ Title = "Reset", Body = "Corruption cleared, will re-corrupt on next farm." })
	end,
})

Settings:Button({
	Name = "Export Logs",
	Callback = function()
		local fn = export()
		Window:Notify({ Title = "Exported", Body = fn })
	end,
})

-- Re-apply corruption on respawn
LP.CharacterAdded:Connect(function()
	task.wait(2)
	if farming and Window.Flags.CorruptionEnabled then
		Corrupted = false
		corrupt()
	end
end)

-- ═══════════════════════════════════════════════
--  INIT
-- ═══════════════════════════════════════════════
StartWS = Workspace.DistributedGameTime
log("INIT player="..LP.Name)
dumpVehicle("INIT")
Window:Show()
warn("[AutoFarmTP] Loaded — MangoLiquidUI + Mango Teleport v3")
