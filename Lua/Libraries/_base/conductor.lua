local conductor = {}

function conductor.sectobeat(sec, bpm)
	return sec*bpm/60
end

local function beatsecformula(beat,bpm)
	return beat/bpm*60
end

function conductor.beattosec(beat,t)
	local bpm, i = conductor.getbpm(beat)
	if i > 1 then
		local sec = conductor.bpms[i].second + beatsecformula(beat-conductor.bpms[i].beat,bpm)
		return sec
	else
		return beat/bpm*60
	end
end

function conductor.reset()
	conductor.events = {}
	conductor.bpms = {}
	conductor.measures = {}
	conductor.currentevent = 1
	conductor.currentbpm = 2 -- we set the starting bpm manually so we're checking from the 2nd onwards
	conductor.bpm = 120
	conductor.beat = 0
	conductor.seconds = 0
	conductor.playing = false
end

function conductor.setbpms(bpms)
	conductor.bpms = bpms or {{beat = 0, bpm = 120}}
	conductor.bpms[1].second = 0

	for i=2,#conductor.bpms do
		conductor.bpms[i].second = conductor.bpms[i-1].second + beatsecformula(conductor.bpms[i].beat - conductor.bpms[i-1].beat, conductor.bpms[i-1].bpm, true)
	end

	conductor.bpm = conductor.bpms[1].bpm

end

function conductor.start()

	local offset = math.max(4, -conductor.events[1].second + 1)
	conductor.beat = -conductor.sectobeat(offset, conductor.bpms[1].bpm)
	conductor.seconds = -offset

	conductor.playing = true

end

function conductor.stop()
	conductor.playing = false
end

function conductor.getbpm(beat)

	for i=#conductor.bpms,1,-1 do
		local b = conductor.bpms[i]
		if beat >= b.beat then
			return b.bpm, i
		end
	end

	-- the above should catch all cases, but just in case
	return conductor.bpms[1].bpm, 1

end

function conductor.addevent(beat, offset, func, ...)

	local second = conductor.beattosec(beat) - offset

	local t = {beat = beat, second = second, func = func, params = {}}
	local length = select('#', ...)

	for i=1,length do
		local p = select(i, ...)
		t.params[#t.params+1] = p
	end

	conductor.events[#conductor.events+1] = t

end

function conductor.sortevents()

	table.sort(conductor.events, function(a,b) return a.second < b.second end)

end

function conductor.update()

	if conductor.playing then

		conductor.beat = conductor.beat + conductor.sectobeat(Time.dt, conductor.bpm)
		conductor.seconds = conductor.seconds + Time.dt

		local thisevent = conductor.events[conductor.currentevent]

		if thisevent then -- make sure we didnt reach the end of the event table

			while conductor.seconds >= thisevent.second do

				thisevent.func(table.unpack(thisevent.params))
				conductor.currentevent = conductor.currentevent + 1

				thisevent = conductor.events[conductor.currentevent]
				if not thisevent then break end

			end

		end

		local thisbpm = conductor.bpms[conductor.currentbpm]

		if thisbpm then

			if conductor.seconds >= thisbpm.second then

				conductor.bpm = thisbpm.bpm
				conductor.currentbpm = conductor.currentbpm + 1

			end

		end

	end

end

return conductor