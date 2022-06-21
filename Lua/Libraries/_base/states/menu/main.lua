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

	if Input.GetKey('Escape') == 1 then
		Audio.PlaySound('menuconfirm')
		State 'DONE'
		return
	end

	if Input.Confirm == 1 then

		if resources.heartSelected < 5 then
			Audio.PlaySound('menuconfirm')
			setstate(resources.heartSelected)
		else
			State 'DONE'
		end

	end
	
	resources.update()

end

return menu