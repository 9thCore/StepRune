local input = {}

local numtodir = {
	'left', 'down', 'up', 'right'
}

function input.getkey(dir)
	dir = numtodir[dir] or dir

	if dir == 'left' then
		return Input.GetKey('LeftArrow')
	elseif dir == 'right' then
		return Input.GetKey('RightArrow')
	elseif dir == 'up' then
		return Input.GetKey('UpArrow')
	elseif dir == 'down' then
		return Input.GetKey('DownArrow')
	end

	return 0

end

return input