local save = {}

local set = SetAlMightyGlobal
local get = GetAlMightyGlobal

save.diffname = 'STEPRUNE_SAVE_DIFFICULTY'
save.autoplayname = 'STEPRUNE_SAVE_AUTOPLAY'
save.boomname = 'STEPRUNE_SAVE_MINEGOBOOM'
save.offsetname = 'STEPRUNE_SAVE_OFFSET'
save.quittimename = 'STEPRUNE_SAVE_QUITTIME'

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
	t.boom = get(save.boomname)
	t.offset = get(save.offsetname)
	t.quittime = get(save.quittimename)

	return t

end

function save.var(name, val)
	set(name, val)
end

function save.saverank(level, diff, rank)

	local name = save.encoderank(level, diff)

	if get(name) == 'S' then return end -- don't save if we already have an S rank, can't get better than this!

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