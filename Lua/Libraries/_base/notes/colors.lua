local colors = {}

local measures = require '_base/notes/measures'

local _COLORS = {
	{1/4, {206,81,81}}, -- 1/4th note, red
	{1/8, {76,84,178}}, -- 1/8th note, blue
	{1/12, {233,62,138}}, -- 1/12th note, pink
	{1/16, {195,196,103}}, -- 1/16th note, yellow
	{1/20, {142, 142, 142}}, -- 1/20th note, gray
	{1/24, {170,49,180}}, -- 1/24th note, purple
	{1/32, {212,141,42}}, -- 1/32nd note, orange
	{1/48, {113,211,244}}, -- 1/48th note, cyan
	{1/64, {92,165,92}}, -- 1/64th note, green
	INVALID = {142, 142, 142} -- gray
}

for _,t in ipairs(_COLORS) do -- 0-255 -> 0-1
	t[2][1] = t[2][1]/255
	t[2][2] = t[2][2]/255 -- bleh
	t[2][3] = t[2][3]/255
end
_COLORS.INVALID[1] = _COLORS.INVALID[1]/255
_COLORS.INVALID[2] = _COLORS.INVALID[2]/255 -- gh
_COLORS.INVALID[3] = _COLORS.INVALID[3]/255

function colors.get(idx)
	if _COLORS[idx] then return _COLORS[idx][2] end
	return _COLORS.INVALID
end

function colors.getinvalid()
	return _COLORS.INVALID
end

function colors.getcolor(note)

	local measure = note.measure
	local measurelinecount = measures.getmeasure(measure)

	local line = measures.noteinfo[note]-1

	if line then

		local l = line/measurelinecount

		for _,t in ipairs(_COLORS) do
			if l%t[1]<1/256 then
				return t[2]
			end
		end

	end

	return _COLORS.INVALID
end

return colors