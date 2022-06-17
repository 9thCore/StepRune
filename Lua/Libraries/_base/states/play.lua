local play = {}
local newstate = nil

function play.init()

end

function play.update(setstate)

	if newstate then
		setstate(newstate)
		newstate = nil
	end
	
	-- resources.update() -- no need to update the resources stuff

end

function play.exit()

	Audio.PlaySound 'menuconfirm'
	newstate = 2

end

return play