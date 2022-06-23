local input = {}

local numtodir = {
	'left', 'down', 'up', 'right'
}

input.keys = {
	left = 'D',
	down = 'F',
	up = 'J',
	right = 'K'
}

local function keyorarrow(key, arrow)

	if Input.GetKey(key) > 0 then
		return Input.GetKey(key)
	else
		return Input.GetKey(arrow .. 'Arrow')
	end

end

function input.getkey(dir)
	dir = numtodir[dir] or dir
	dir = dir:lower()

	if dir == 'left' then
		return keyorarrow(input.keys.left, 'Left')
	elseif dir == 'right' then
		return keyorarrow(input.keys.right, 'Right')
	elseif dir == 'up' then
		return keyorarrow(input.keys.up, 'Up')
	elseif dir == 'down' then
		return keyorarrow(input.keys.down, 'Down')
	end

	return 0

end

return input