local lockdown = {}

-- creates new environment where functions and objects are locked down to prevent charts messing with the basegame
-- in a separate file to avoid clogging up level.lua with a long thing, its already clogged enough :[

local conductor = require '_base/conductor'

function lockdown.getenv(ot, st)

	local env = {}
	local specialvars = {} -- if a variable is found in here it gets returned instead of the real variable

	-- wrapped lua functions
	function specialvars.require(path)
		if path:find('_base') then return false end
		return _req(path)
	end

	function specialvars.SetAlMightyGlobal(name, val)
		if tostring(name):lower():find('steprune') then return end -- ;)
		SetAlMightyGlobal(name, val)
	end
	function specialvars.GetAlMightyGlobal(name)
		if tostring(name):lower():find('steprune') then return end -- ;)
		return GetAlMightyGlobal(name)
	end

	function specialvars.CreateProjectile(s,...)
		local v = CreateProjectile(s,...)
		ot[#ot+1] = {v, 'bullet'}
		return v

	end
	function specialvars.CreateProjectileAbs(s,...)
		local v = CreateProjectileAbs(s,...)
		ot[#ot+1] = {v, 'bullet'}
		return v
	end

	function specialvars.CreateSprite(s,...)
		local v = CreateSprite(s,...)
		ot[#ot+1] = {v, 'sprite'}
		return v

	end

	function specialvars.UnloadSprite(s)
		if s:lower():find('_base') then return end
		return UnloadSprite(s)
	end

	specialvars.Conductor = conductor.getobject()
	specialvars.Level = lockdown.level.getobject()

	specialvars.Misc = nil
	specialvars.UI = nil

	specialvars.Flee = nil
	specialvars.CreateLayer = nil
	specialvars.State = nil
	specialvars.CreateState = nil

	specialvars.debug = nil -- ;)

	setmetatable(env, {
		__index = function(t,k)
			if specialvars[k] then
				return specialvars[k]
			elseif st[k] then
				return st[k].get(t)
			elseif k == '_G' then
				return t -- ;)
			else
				return _G[k]
			end
		end,
		__newindex = function(t,k,v)
			rawset(t,k,v)
			if st[k] then
				st[k].set(t)
				rawset(t,k,nil) -- revert since we need to see if it gets set again (__newindex doesn't trigger for entries that already exist)
			end
		end,
		__metatable = {} -- ;)
	})

	return env

end

return lockdown