local manager = {}

local resources = require '_base/states/menu/resources'

local states = {
	'menu/main',
	'menu/play',
	'menu/options',
	'menu/credits',
	'play' -- not to be confused with the menu play, where you choose what level to load
}
local curstate = 1

local function setstate(newstate)
	resources.settext{}

	curstate = newstate
	states[curstate].init()

	if curstate < 5 then
		NewAudio.Unpause('menu_music')
	else
		NewAudio.Pause('menu_music')
	end

end

function manager.init()
	
	for k,v in ipairs(states) do

		states[k] = require('_base/states/'..v)

	end

	states[1].init() -- automatically initialize first state

end

function manager.update()

	states[curstate].update(setstate) -- pass the setstate function since we'll need to use it

end

return manager