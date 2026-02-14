--!strict

local Types = require(script.Parent.Types)

local HttpService = game:GetService("HttpService")

local module = {}

-- Check if executor file system functions are available
local function hasFileSystem(): boolean
	local success, _ = pcall(function()
		return type(writefile) == "function"
			and type(readfile) == "function"
			and type(isfolder) == "function"
			and type(makefolder) == "function"
			and type(isfile) == "function"
			and type(delfile) == "function"
	end)
	return success
end

local filesystemAvailable: boolean = hasFileSystem()

function module.new(config: Types.MangoSaveManagerConfig): Types.MangoSaveManager
	local folderName: string = config.FolderName
	local fileName: string = config.FileName or "config"
	local filePath: string = folderName .. "/" .. fileName .. ".json"

	local self = {} :: Types.MangoSaveManager

	function self.Save(_self: Types.MangoSaveManager, data: {[string]: any}): boolean
		if not filesystemAvailable then
			return false
		end

		local success = pcall(function()
			-- Create folder if it doesn't exist
			if not isfolder(folderName) then
				makefolder(folderName)
			end

			local encoded = HttpService:JSONEncode(data)
			writefile(filePath, encoded)
		end)

		return success
	end

	function self.Load(_self: Types.MangoSaveManager): {[string]: any}?
		if not filesystemAvailable then
			return nil
		end

		local success, result = pcall(function(): {[string]: any}?
			if not isfile(filePath) then
				return nil
			end

			local contents = readfile(filePath)
			local decoded = HttpService:JSONDecode(contents)
			return decoded :: {[string]: any}
		end)

		if success then
			return result
		end

		return nil
	end

	function self.Delete(_self: Types.MangoSaveManager): boolean
		if not filesystemAvailable then
			return false
		end

		local success = pcall(function()
			if isfile(filePath) then
				delfile(filePath)
			end
		end)

		return success
	end

	return self
end

return module
