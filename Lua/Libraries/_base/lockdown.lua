local lockdown = {}

-- creates new environment where functions and objects are locked down to prevent charts messing with the basegame

local _req = require

function lockdown.getenv() -- begin the lockdown process

	local env = {}

	function env.require(path)
		if path:find('_base') then return false end
		return _req(path)
	end

	return env

end

return lockdown