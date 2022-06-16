local sprh = {}

function sprh.copysprite(a, b, copyimg, isanim)
	shaderprop = shaderprop or {}

	if copyimg then a.Set(b.spritename) end
	
	-- oh boy

	-- position, rotation, scale, layer
	a.x = b.x
	a.y = b.y
	a.z = b.z
	a.rotation = b.rotation
	a.xscale = b.xscale
	a.yscale = b.yscale
	a.layer = b.layer

	-- color
	a.color = b.color

	-- pivot, anchor
	a.xpivot = b.xpivot
	a.ypivot = b.ypivot

	-- animation
	if isanim then
		a.currentframe = b.currentframe
		a.currenttime = b.currenttime
		a.animationspeed = b.animationspeed
		a.animationpaused = b.animationpaused
		a.loopmode = b.loopmode
	end

end

return sprh