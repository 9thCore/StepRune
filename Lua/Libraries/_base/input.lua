local input = {}

local numtodir = {
	'left', 'down', 'up', 'right'
}

function input.getkey(dir)
	dir = numtodir[dir] or dir

	if dir == 'left' then
		return Input.Left
	elseif dir == 'right' then
		return Input.Right
	elseif dir == 'up' then
		return Input.Up
	elseif dir == 'down' then
		return Input.Down
	end

	return 0

end

return input