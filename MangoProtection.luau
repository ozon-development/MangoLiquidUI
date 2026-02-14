--!strict

--[[
	MangoProtection — Anti-detection security module for MangoLiquidUI

	Provides 5 layers of defense:
	1. Hidden parenting (gethui -> CoreGui -> PlayerGui fallback)
	2. Metamethod hooking (filters protected instances from game script calls)
	3. Instance identity obfuscation (randomized names)
	4. Connection protection (newcclosure wrapping)
	5. Property spoofing (protected instances return nil parent to game scripts)

	All executor-specific globals are accessed via pcall for --!strict safety.
	Gracefully falls back to standard Roblox Studio behavior when no executor features are available.
]]

local HttpService = game:GetService("HttpService")

local module = {}

-- Capability detection (runs once on require, all via pcall)
local _gethui: (() -> Instance)? = nil
local _cloneref: ((Instance) -> Instance)? = nil
local _hookmetamethod: ((Instance, string, any) -> any)? = nil
local _newcclosure: ((any) -> any)? = nil
local _checkcaller: (() -> boolean)? = nil
local _getnamecallmethod: (() -> string)? = nil
local _protectgui: ((Instance) -> ())? = nil

-- Detect executor capabilities safely
pcall(function()
	_gethui = (gethui :: any) :: (() -> Instance)
end)
pcall(function()
	_cloneref = (cloneref :: any) :: ((Instance) -> Instance)
end)
pcall(function()
	_hookmetamethod = (hookmetamethod :: any) :: ((Instance, string, any) -> any)
end)
pcall(function()
	_newcclosure = (newcclosure :: any) :: ((any) -> any)
end)
pcall(function()
	_checkcaller = (checkcaller :: any) :: (() -> boolean)
end)
pcall(function()
	_getnamecallmethod = (getnamecallmethod :: any) :: (() -> string)
end)
pcall(function()
	local syn_val = (syn :: any)
	if syn_val and syn_val.protect_gui then
		_protectgui = syn_val.protect_gui :: ((Instance) -> ())
	end
end)

-- Protected instance registry (weak-keyed table)
local protectedInstances: {[Instance]: boolean} = setmetatable({}, {__mode = "k"}) :: any

-- Global state
local protectionEnabled = true
local hooksInstalled = false

-- Determine protection level based on available capabilities
local protectionLevel: string = "none"
if _gethui then
	protectionLevel = "gethui"
elseif _protectgui then
	protectionLevel = "synprotect"
else
	local coreGuiOk = pcall(function()
		local _ = game:GetService("CoreGui")
	end)
	if coreGuiOk then
		protectionLevel = "coregui"
	end
end

-- Cached service references (cloneref'd when available)
local serviceCache: {[string]: Instance} = {}

--[[
	Configure protection globally.
	config.Enabled: boolean? — enable/disable all protection features
]]
function module.configure(config: {Enabled: boolean?})
	if config.Enabled ~= nil then
		protectionEnabled = config.Enabled
	end
end

--[[
	Returns the safest parent container for ScreenGui instances.
	Fallback chain: gethui() -> CoreGui -> PlayerGui
]]
function module.getParent(): Instance
	if protectionEnabled then
		-- Try gethui first (completely hidden from game scripts)
		if _gethui then
			local ok, result = pcall(_gethui :: () -> Instance)
			if ok and result then
				return result
			end
		end

		-- Try CoreGui (less detectable than PlayerGui)
		if protectionLevel == "coregui" or protectionLevel == "synprotect" then
			local ok, coreGui = pcall(function()
				return game:GetService("CoreGui")
			end)
			if ok and coreGui then
				return coreGui
			end
		end
	end

	-- Fallback to PlayerGui (standard Roblox Studio)
	local Players = game:GetService("Players")
	local player = Players.LocalPlayer
	return player:WaitForChild("PlayerGui")
end

--[[
	Apply syn.protect_gui() and register instance in protected set.
]]
function module.protectGui(gui: Instance)
	if not protectionEnabled then return end

	-- Apply syn.protect_gui if available
	if _protectgui then
		pcall(_protectgui :: (Instance) -> (), gui)
	end

	-- Register in protected set
	module.registerInstance(gui)
end

--[[
	Central ScreenGui creation helper. Replaces all duplicated ScreenGui creation blocks.
	Handles hidden parenting, name randomization, protection registration.
]]
function module.createScreenGui(config: {DisplayOrder: number?, IgnoreGuiInset: boolean?}): ScreenGui
	-- Install hooks on first ScreenGui creation
	if not hooksInstalled then
		module.installHooks()
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = module.randomName()
	gui.DisplayOrder = config.DisplayOrder or 100
	gui.IgnoreGuiInset = if config.IgnoreGuiInset ~= nil then config.IgnoreGuiInset else true
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	-- Register for hook protection
	module.registerInstance(gui)

	-- Apply syn.protect_gui if available
	if _protectgui and protectionEnabled then
		pcall(_protectgui :: (Instance) -> (), gui)
	end

	-- Parent to safest container
	gui.Parent = module.getParent()
	return gui
end

--[[
	Register an instance and all its descendants for hook protection.
	Also listens for future descendants.
]]
function module.registerInstance(instance: Instance)
	if not protectionEnabled then return end

	protectedInstances[instance] = true

	-- Protect all existing descendants
	for _, desc in instance:GetDescendants() do
		protectedInstances[desc] = true
	end

	-- Protect future descendants
	instance.DescendantAdded:Connect(function(desc)
		protectedInstances[desc] = true
	end)
end

--[[
	Generate a random non-identifiable name.
	When protection is disabled, returns the prefix or "Instance".
]]
function module.randomName(prefix: string?): string
	if not protectionEnabled then
		return prefix or "Instance"
	end
	local guid = HttpService:GenerateGUID(false)
	return string.sub(guid, 1, 8)
end

--[[
	Generate a random RenderStep binding name.
	When protection is disabled, returns a "Mango"-prefixed name.
]]
function module.randomBindingName(prefix: string?): string
	if not protectionEnabled then
		return (prefix or "MangoBinding") .. "_" .. tostring(math.random(100000, 999999))
	end
	local guid = HttpService:GenerateGUID(false)
	return string.sub(guid, 1, 12)
end

--[[
	Returns a (possibly cloneref'd) service reference.
	Prevents detection via hooked GetService.
]]
function module.safeService(name: string): Instance
	local cached = serviceCache[name]
	if cached then return cached end

	local service = game:GetService(name)
	if _cloneref and protectionEnabled then
		local ok, cloned = pcall(_cloneref :: (Instance) -> Instance, service)
		if ok and cloned then
			serviceCache[name] = cloned
			return cloned
		end
	end

	serviceCache[name] = service
	return service
end

--[[
	Wrap a callback function in newcclosure if available.
	Prevents detection of hooked closures via getconnections().
]]
function module.wrapConnection(fn: any): any
	if _newcclosure and protectionEnabled then
		local ok, wrapped = pcall(_newcclosure :: (any) -> any, fn)
		if ok and wrapped then
			return wrapped
		end
	end
	return fn
end

--[[
	Returns whether protection is currently active.
]]
function module.isProtected(): boolean
	return protectionEnabled and protectionLevel ~= "none"
end

--[[
	Returns the current protection level string.
	"gethui" | "synprotect" | "coregui" | "none"
]]
function module.getProtectionLevel(): string
	if not protectionEnabled then return "none" end
	return protectionLevel
end

--[[
	Install metamethod hooks for active defense.
	Called once automatically on first createScreenGui(), or manually.
	Idempotent — safe to call multiple times.
]]
function module.installHooks()
	if hooksInstalled then return end
	if not _hookmetamethod then return end
	if not _getnamecallmethod then return end
	if not protectionEnabled then return end

	hooksInstalled = true

	local wrap: (any) -> any = (_newcclosure :: any) or function(f: any): any return f end

	-- __namecall hook: intercept GetChildren, GetDescendants, FindFirstChild, etc.
	local oldNamecall: any
	local ok1: boolean
	ok1, oldNamecall = pcall(_hookmetamethod :: (Instance, string, any) -> any, game, "__namecall", wrap(function(self: any, ...: any)
		local method = (_getnamecallmethod :: () -> string)()

		-- Executor code sees everything normally
		if _checkcaller and (_checkcaller :: () -> boolean)() then
			return oldNamecall(self, ...)
		end

		-- Filter results for game scripts
		if method == "GetChildren" or method == "GetDescendants" then
			local results = oldNamecall(self, ...)
			local filtered = {}
			for _, child in results do
				if not protectedInstances[child] then
					table.insert(filtered, child)
				end
			end
			return filtered
		elseif method == "FindFirstChild" or method == "FindFirstChildOfClass"
			or method == "FindFirstChildWhichIsA" then
			local result = oldNamecall(self, ...)
			if result and protectedInstances[result] then
				return nil
			end
			return result
		end

		return oldNamecall(self, ...)
	end))

	if not ok1 then
		hooksInstalled = false
		return
	end

	-- __index hook: intercept .Parent reads on protected instances
	local oldIndex: any
	local ok2: boolean
	ok2, oldIndex = pcall(_hookmetamethod :: (Instance, string, any) -> any, game, "__index", wrap(function(self: any, key: any)
		if _checkcaller and not (_checkcaller :: () -> boolean)() then
			if key == "Parent" and protectedInstances[self] then
				return nil -- game scripts see nil parent
			end
		end
		return oldIndex(self, key)
	end))

	if not ok2 then
		-- Namecall hook succeeded but index hook failed — still partially protected
		return
	end
end

return module
