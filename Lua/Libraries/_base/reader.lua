local reader = {}

local level = require '_base/level'
local conductor = require '_base/conductor'

local function err_FILENOTFOUND(file)
	error('Couldn\'t find ' .. file .. ' in the chart\'s folder! Are you sure it\'s there?', -1)
end

local function findbpmhere(line)
	local newline = line:gsub('#BPMS:', ''):gsub(',',''):gsub(';','')

	local pos = newline:find '='

	if pos then

		local beat = tonumber(newline:sub(1,pos-1))
		local bpm = tonumber(newline:sub(pos+1,-1))

		if beat and bpm then
			return beat,bpm
		end

	end
end

function reader.load(folder, setstate)

	local t = {} -- final table with all the notes and stuff
	t.notes = {}
	t.bpms = {}
	t.chartname = folder:gsub(ChartPath, ''):sub(2,-1)

	local chartname = folder .. '/main.sm'
	local scriptname = folder .. '/main.lua'
	local musicname = folder .. '/main.ogg'

	if not Misc.FileExists(musicname) then err_FILENOTFOUND('main.ogg') end
	if not Misc.FileExists(chartname) then err_FILENOTFOUND('main.sm') end

	local chart = Misc.OpenFile(chartname, 'r')

	local chartlines = chart.ReadLines()

	local seenslashesalready = false
	local reading = 0 -- 1 for bpm, 2 for notes
	local i = 0

	local measure = 1
	local lineinmeasure = 0

	local tempnotes = {}
	local holdheads = {}

	while i <= #chartlines do -- h

		i = i + 1

		local line = chartlines[i]

		if not line then break end -- ???????????????????????

		-- dumb solution because i only need the bpm changes, offset and notes from the chart
		if line:find '#BPMS' then
			-- getting the bpms

			reading = 1
			local beat,bpm = findbpmhere(line)
			if beat and bpm then
				t.bpms[#t.bpms+1] = {beat = beat, bpm = bpm}
			end

		elseif line:find '#NOTES' then
			-- getting the notes

			reading = 2
			i = i + 5

		elseif line:find '#OFFSET' then
			-- offset

			local newline = line:gsub('#OFFSET:', ''):gsub(';','')

			t.songoffset = -(tonumber(newline) or 0)

		elseif line:find '//' then
			-- only read the first chart :)

			if not seenslashesalready then
				seenslashesalready = true
			else
				break
			end

		elseif line:find '#' then -- crap we dont care about
			reading = 0 -- we arent reading anything anymore

		else -- lines such as the bpms or notes

			if reading == 1 then -- bpms

				local beat,bpm = findbpmhere(line)
				if beat and bpm then
					t.bpms[#t.bpms+1] = {beat = beat, bpm = bpm}
				end

			elseif reading == 2 then -- notes
				
				if #line > 3 then -- only take into account the lines that are 4 characters or more; in arrowvortex you can also make charts with >4 notes        so

					lineinmeasure = lineinmeasure + 1

					for j=1,4 do

						local c = line:sub(j,j)

						if c == '1' then -- normal note

							tempnotes[#tempnotes+1] = {type = 'normal', line = lineinmeasure, measure = measure, row = j}

						elseif c == '2' then -- hold note start

							local holdhead = {type = 'hold', line = lineinmeasure, measure = measure, row = j, head = true} -- store the head

							holdheads[j] = holdhead
							tempnotes[#tempnotes+1] = holdhead

						elseif c == '3' then -- hold end

							local holdhead = holdheads[j]

							if holdhead then
								tempnotes[#tempnotes+1] = {type = 'hold', line = lineinmeasure, measure = measure, row = j, head = false, holdhead = holdhead} -- the hold end
								holdheads[j] = nil
							end

						elseif c == 'M' then -- mine

							tempnotes[#tempnotes+1] = {type = 'mine', line = lineinmeasure, measure = measure, row = j}

						end

					end

				elseif line:find ',' or line:find ';' then -- we reached the end of the current measure

					for _,n in ipairs(tempnotes) do

						local magic = 4/lineinmeasure -- magic
						local beat = (n.measure - 1) * 4 + (n.line - 1) * magic -- magic

						if n.holdhead then

							local idx = n.holdhead.noteidx
							t.notes[idx].holdendbeat = beat

						else

							t.notes[#t.notes+1] = {
								type = n.type,
								lineinmeasure = n.line,
								measurelinecount = lineinmeasure,
								measure = measure,
								row = n.row,
								beat = beat,
								holdendbeat = n.holdendbeat -- for holds
							}
							n.noteidx = #t.notes

						end

					end

					tempnotes = {}

					measure = measure + 1
					lineinmeasure = 0

				end

			end

		end

	end

	table.sort(t.notes, function(a,b) return a.beat < b.beat end)

	level.load(t)

	setstate(5)

end

return reader