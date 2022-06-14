local menu = {}

local resources = require '_base/states/menu/resources'

function menu.init()

	resources.settext{
		'',
		'Play',
		'Options',
		'Credits',
		'Exit'
	}

	resources.setselect(2, true)

end

function menu.update(setstate)
	
	resources.update()

	if Input.Confirm == 1 then

		if resources.heartSelected < 5 then
			Audio.PlaySound('menuconfirm')
			setstate(resources.heartSelected)
		else
			State 'DONE'
		end

	end

end

return menu