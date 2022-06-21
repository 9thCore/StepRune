local credits = {}

local resources = require '_base/states/menu/resources'

function credits.init()

end

function credits.update(setstate)

	if Input.GetKey('Escape') == 1 then
		Audio.PlaySound('menuconfirm')
		setstate(1)
		return
	end
	
	resources.update()

end

return credits