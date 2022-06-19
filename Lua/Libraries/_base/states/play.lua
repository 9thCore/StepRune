local play = {}
local _setstate

function play.init()

end

function play.update(setstate)

	_setstate = setstate
	
	-- resources.update() -- no need to update the resources stuff

end

function play.exit()

	Audio.PlaySound 'menuconfirm'
	_setstate(2)

end

return play