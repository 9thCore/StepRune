local manager = {}

local resources = require '_base/states/menu/resources'
local ui = require '_base/ui'

local states = {
	'menu/main',
	'menu/play',
	'menu/options',
	'menu/credits',
	'play' -- not to be confused with the play menu, where you choose what level to load
}
local curstate = 1
local justchanged = false
local queued = nil

local function setstate(newstate)

	if justchanged then
		queued = newstate
		return
	end

	justchanged = true

	if newstate ~= 5 then
		ui.setalpha(0)
	end

	resources.paget.alpha = 0
	resources.page = 1
	resources.pagecnt = 1

	resources.settext{}

	curstate = newstate
	states[newstate].init()

	if newstate < 5 then
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

	justchanged = false

	if queued then
		setstate(queued)
		queued = nil
	end

	states[curstate].update(setstate) -- pass the setstate function since we'll need to use it

end

return manager