local lockdown = {}

-- creates new environment where functions and objects are locked down to prevent charts messing with the basegame
-- in a separate file to avoid clogging up level.lua with a long thing, its already clogged enough :[

local easing = require 'easing'
local conductor = require '_base/conductor'
local notemanager = require '_base/notes/manager'

function lockdown.getenv(ot, st)

	local env = {}
	local specialvars = {} -- if a variable is found in here it gets returned instead of the real variable

	-- wrapped lua functions
	function specialvars.require(path)
		if path:find('_base') then return nil end -- ;)
		return _req(path)
	end

	function specialvars.SetAlMightyGlobal(name, val)
		if tostring(name):lower():find('steprune') then return end
		SetAlMightyGlobal(name, val)
	end
	function specialvars.GetAlMightyGlobal(name)
		if tostring(name):lower():find('steprune') then return end
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

	function specialvars.CreateText(...)
		local v = CreateSprite(...)
		ot[#ot+1] = {v, 'text'}
		return v

	end

	function specialvars.UnloadSprite(s)
		if s:lower():find('_base') then return end
		return UnloadSprite(s)
	end

	specialvars.Easing = {}
	setmetatable(specialvars.Easing, {
		__index = function(t,k)
			return easing[k]
		end,
		__metatable = false
	})
	function specialvars.Easing.Random()
		local t = {}
		for k,_ in pairs(easing) do
			t[#t+1] = k
		end
		return easing[t[math.random(1,#t)]]
	end

	specialvars.Conductor = conductor.getobject()
	specialvars.Level = lockdown.level.getobject()
	specialvars.Notes = notemanager.getobject()

	specialvars.Misc = 'nil'
	specialvars.UI = 'nil'

	specialvars.Flee = 'nil'
	specialvars.CreateLayer = 'nil'
	specialvars.State = 'nil'
	specialvars.CreateState = 'nil'

	specialvars.debug = 'nil' -- ;)
	specialvars.dofile = 'nil'
	specialvars.loadfile = 'nil'
	specialvars.loadstring = 'nil'
	specialvars.load = 'nil'

	specialvars.rawget = 'nil'
	specialvars.rawset = 'nil'

	specialvars.package = 'nil'

	setmetatable(env, {
		__index = function(t,k)
			if specialvars[k] ~= nil then
				if specialvars[k] == 'nil' then
					return nil
				else
					return specialvars[k]
				end
			elseif st[k] then
				return st[k].get(t)
			elseif k == '_G' then
				return nil -- ;)
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