local play = {}

local resources = require '_base/states/menu/resources'
local reader = require '_base/reader'
local Misc = Misc -- :)
local ChartPath = ChartPath -- temporarily set during the initialization so we're saving it for later use

local function getlist(offset)

	local t = {'Back'}

	local folders = Misc.ListDir(ChartPath, true)

	for i=1,7 do

		local file = folders[i+offset]

		if not file then break end

		t[#t+1] = file

	end

	return t

end

function play.init()

	resources.settext(getlist(0))

	resources.setselect(1, true)

end

function play.update(setstate)
	
	resources.update()

	if Input.Confirm == 1 then

		if resources.heartSelected == 1 then
			Audio.PlaySound('menuconfirm')
			setstate(1)
		else
			reader.load(ChartPath .. '/' .. resources.text[resources.heartSelected][2], setstate)
		end

	end

end

return play