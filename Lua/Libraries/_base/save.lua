local save = {}

local set = SetAlMightyGlobal
local get = GetAlMightyGlobal

save.diffname = 'STEPRUNE_SAVE_DIFFICULTY'
save.autoplayname = 'STEPRUNE_SAVE_AUTOPLAY'

function save.encoderank(level, diff)
	
	local s = 'STEPRUNE_SAVE_LEVELRANK:LEVEL=' .. tostring(level) .. ',DIFFICULTY=' .. tostring(diff)
	return s

end

function save.getrank(chart, diff)

	local str = save.encoderank(chart, diff)
	local rank = get(str)

	return rank

end

function save.getsave(difft)

	local t = {}

	t.diff = get(save.diffname)
	t.autoplay = get(save.autoplayname)

	return t

end

function save.var(name, val)
	set(name, val)
end

function save.saverank(level, diff, rank)

	local name = save.encoderank(level, diff)

	if rank == 'S' then -- if we have an S rank save it every time, cant get better than an S

		set(name, rank)

	else

		local existingrank = get(name) or 'Z' -- 'Z' string is bigger than every other rank

		if rank < existingrank then
			set(name, rank)
		end

	end

end

return save