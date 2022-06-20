local conductor = {}

local wrappedevents = {}

local function secbeatformula(sec,bpm)
	return sec*bpm/60
end

local function beatsecformula(beat,bpm)
	return beat/bpm*60
end

function conductor.sectobeat(sec)
	local bpm, i = conductor.getbpmatsec(sec)
	if i > 1 then
		local beat = conductor.bpms[i].beat + secbeatformula(sec-conductor.bpms[i].second,bpm)
		return beat
	else
		return secbeatformula(sec,bpm)
	end
end

function conductor.beattosec(beat)
	local bpm, i = conductor.getbpmatbeat(beat)
	if i > 1 then
		local sec = conductor.bpms[i].second + beatsecformula(beat-conductor.bpms[i].beat,bpm)
		return sec
	else
		return beatsecformula(beat,bpm)
	end
end

function conductor.reset()
	conductor.events = {}
	wrappedevents = {}
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
	conductor.beat = -secbeatformula(offset, conductor.bpms[1].bpm)
	conductor.seconds = -offset

	conductor.playing = true

end

function conductor.stop()
	conductor.playing = false
end

function conductor.getbpmatbeat(beat)
	for i=#conductor.bpms,1,-1 do
		local b = conductor.bpms[i]
		if beat >= b.beat then
			return b.bpm, i
		end
	end

	-- the above should catch all cases, but just in case
	return conductor.bpms[1].bpm, 1
end

function conductor.getbpmatsec(sec)
	for i=#conductor.bpms,1,-1 do
		local b = conductor.bpms[i]
		if sec >= b.second then
			return b.bpm, i
		end
	end

	-- the above should catch all cases, but just in case
	return conductor.bpms[1].bpm, 1
end

local function newevent(beat, offset, func, ...)
	local second = conductor.beattosec(beat) - offset
	local t = {beat = beat, second = second, func = func, params = table.pack(...)}

	return t
end

function conductor.addevent(...)
	local t = newevent(...)
	conductor.events[#conductor.events+1] = t
	t.idx = #conductor.events
	return t
end

function conductor.insertevent(...)
	local t = newevent(...)

	if #conductor.events > 0 then

		for i,e in ipairs(conductor.events) do -- instead of sorting the events every time ( :] ) just insert the event where it should be
			if e.second >= t.second then
				t.idx = i
				table.insert(conductor.events, i, t)
				break
			end
		end

	else
		conductor.events[1] = t
	end

	return t
end

function conductor.sortevents()
	table.sort(conductor.events, function(a,b) return a.second < b.second end)
end

function conductor.update()

	if conductor.playing then

		conductor.beat = conductor.beat + secbeatformula(Time.dt, conductor.bpm)
		conductor.seconds = conductor.seconds + Time.dt

		local thisevent = conductor.events[conductor.currentevent]

		if thisevent then -- make sure we didnt reach the end of the event table

			while conductor.seconds >= thisevent.second do -- run every eligible event in the same frame

				thisevent.func(table.unpack(thisevent.params))
				conductor.currentevent = conductor.currentevent + 1

				thisevent = conductor.events[conductor.currentevent]
				if not thisevent then break end

			end

		end

		local thisbpm = conductor.bpms[conductor.currentbpm]

		if thisbpm then

			while conductor.seconds >= thisbpm.second do

				conductor.bpm = thisbpm.bpm
				conductor.currentbpm = conductor.currentbpm + 1

			end

		end

	end

end

local function wrapinsertevent(...)
	local t = conductor.insertevent(...)

	local w = {}
	setmetatable(w, {
		__index = function(t,k)
			if k == 'Remove' then
				return function()
					if conductor.currentevent > wrappedevents[w].idx then
						conductor.currentevent = conductor.currentevent - 1
					end
					table.remove(conductor.events, wrappedevents[w].idx)
					wrappedevents[w] = nil
					w = nil
				end
			else
				return wrappedevents[w][k]
			end
		end,
		__newindex = function()
		end,
		__metatable = false
	})

	wrappedevents[w] = t

	return w
end

function conductor.getobject()

	local obj = {}

	function obj.AddEventAtBeat(...)
		return wrapinsertevent(...)
	end

	function obj.AddEventAtSecond(s, ...)
		return wrapinsertevent(conductor.sectobeat(s), ...)
	end

	function obj.SecondsToBeat(...)
		return conductor.sectobeat(...)
	end

	function obj.BeatToSeconds(...)
		return conductor.beattosec(...)
	end

	return obj

end

return conductor