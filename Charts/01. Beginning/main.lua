local g = Conductor.AddEventAtSecond(0.446, 0, DEBUG, 'woo 2')
Conductor.AddEventAtBeat(0.5, 0, function()
	g.Remove()
end)