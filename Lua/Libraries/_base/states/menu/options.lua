local options = {}

local resources = require '_base/states/menu/resources'

function options.init()

end

function options.update(setstate)
	
	resources.update()

end

return options