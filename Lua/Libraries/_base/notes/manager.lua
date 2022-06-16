local manager = {}

manager.allnotes = {} -- stores all the notes
manager.notes = {} -- stores notes currently on screen, gets sorted with the first arrows first and gets rid of them when they should be done
manager.receptors = {}
local lastid = 0

local notetypes = {
	normal = require '_base/notes/normal',
	hold = require '_base/notes/hold',
	mine = require '_base/notes/mine'
}

local rowtoreceptordir = {
	'left', 'down', 'up', 'right'
}

local colors = require '_base/notes/colors'
local measures = require '_base/notes/measures'
local conductor = require '_base/conductor'
local input = require '_base/input'
local easing = require 'easing'

manager.noteease = easing.linear
manager.holdease = easing.linear

function manager.new(t)

	local newnote = manager.spawn(table.unpack(t))

	newnote.count = #newnote

	manager.allnotes[#manager.allnotes+1] = newnote

	return newnote

end

function manager.getnote(idx)
	return manager.allnotes[idx]
end

function manager.create(note)

	note:create()

	local line = note.line
	if line then
		measures.addnote(note, line)
		manager.setnotecolor(note)
	else
		note:setcolor(colors.getinvalid()) -- automatically set to gray color if we dont have a line, such as when a note is created via the chart lua
	end

	for _,n in ipairs(note.nt) do
		n:create()
		n:copy(note)
	end

	manager.notes[#manager.notes+1] = note
end

function manager.spawn(type, line, duration, row, measure, distance, ...)

	local receptordir = rowtoreceptordir[row]
	local receptor = manager.receptors[1][receptordir] -- get first receptor, this will be the parent of the note we track and update

	local note = notetypes[type].spawn(false, duration, receptor, distance, manager.noteease, manager.holdease, ...)
	note.row = row
	note.measure = measure
	note.line = line
	note.nt = {}

	-- now spawn the other notes
	for i=2,#manager.receptors do

		local rcptrs = manager.receptors[i]
		local rcptr = rcptrs[receptordir]

		local _note = notetypes[type].spawn(true, duration, rcptr, distance, manager.noteease, manager.holdease, ...)

		-- add them to the table
		note.nt[#note.nt+1] = _note

	end

	return note

end

function manager.setnotecolor(note)

	local color = colors.getcolor(note)
	note:setcolor(color)

end

function manager.createreceptors()

	local receptors = {}

	receptors.realcolor = {1,1,1}

	receptors.center = CreateSprite('empty', 'game_receptor')
	receptors.center.y = 300

	local function newreceptor(xoffset,rot)
		local rcptr = {}

		rcptr.parent = CreateSprite('empty', 'game_receptor') -- the invisible sprite used to parent the arrows
		rcptr.parent.SetParent(receptors.center)
		rcptr.parent.x = xoffset
		rcptr.parent.y = 0

		rcptr.visual = CreateSprite('_base/arrow/0', 'game_receptor') -- the visible sprite used for showing where the receptor is
		rcptr.visual.SetAnimation({'0', '1', '2', '3'}, 1/8, '_base/arrow')
		rcptr.visual.SetParent(receptors.center)
		rcptr.visual.x = xoffset
		rcptr.visual.y = 0
		rcptr.visual.rotation = rot

		rcptr.explosion = CreateSprite('empty', 'game_receptor') -- the explosion after hitting a note
		rcptr.explosion.SetParent(rcptr.visual)
		rcptr.explosion.x = 0
		rcptr.explosion.y = 0
		rcptr.explosion.rotation = rot
		rcptr.explosion['startsec'] = -0.3
		rcptr.explosion['alphamult'] = 1

		rcptr.parent.SendToTop()

		return rcptr
	end

	receptors.left = newreceptor(-48, 270)
	receptors.down = newreceptor(-16, 0)
	receptors.up = newreceptor(16, 180)
	receptors.right = newreceptor(48, 90)

	function receptors:setalpha(val)

		for _,r in ipairs(rowtoreceptordir) do
			self[r].visual.alpha = val
			self[r].explosion['alphamult'] = val
		end

	end

	function receptors:hide()
		self:setalpha(0)
	end

	function receptors:show()
		self:setalpha(1)
	end

	function receptors:move(x,y)
		x = x or self.center.x
		y = y or self.center.y
		self.center.Move(x,y)
	end

	function receptors:moveto(x,y)
		x = x or self.center.x
		y = y or self.center.y
		self.center.MoveTo(x,y)
	end

	function receptors:movetoabs(x,y)
		x = x or self.center.x
		y = y or self.center.y
		self.center.MoveToAbs(x,y)
	end

	function receptors:setcolor(col, g, b)
		if type(col) ~= 'table' then col = {col, g, b} end
		if col[4] then self:setalpha(col[4]) end

		self.realcolor = col

	end

	return receptors

end

function manager.removereceptors(t)

	for _,dir in ipairs(rowtoreceptordir) do
		t[dir].visual.Remove()
		t[dir].parent.Remove()
		t[dir].explosion.Remove()
	end

	t.center.Remove()

end

function manager.reset()
	for _,r in ipairs(manager.receptors) do
		manager.removereceptors(r)
	end

	manager.notes = {}
	manager.receptors = {}
	lastid = 0
end

function manager.init()

	for i=1,4 do
		manager.receptors[i] = manager.createreceptors()
		manager.receptors[i].center.x = 320
		if i > 1 then manager.receptors[i]:hide() end
	end

end

function manager.exit()

	for _,r in ipairs(manager.receptors) do
		manager.removereceptors(r)
	end
	manager.reset()

end

function manager.explosion(idx, row, hit)

	hit = hit:gsub('_base/judgement/', '')

	if hit == 'miss' then hit = 'bad' end

	for _,receptors in ipairs(manager.receptors) do

		local receptor = receptors[row]

		receptor.explosion.Set('_base/arrow/hit_'..hit)
		receptor.explosion['startsec'] = conductor.seconds

	end

end

function manager.update()

	if not conductor.playing then return end

	-- darkening receptors
	for _,r in ipairs(manager.receptors) do
		for _,row in ipairs(rowtoreceptordir) do
			local receptor = r[row].visual

			local col = r.realcolor
			local r, g, b = col[1], col[2], col[3]

			receptor.color = ((input.getkey(row) > 0) and {r*0.5, g*0.5, b*0.5}) or {r, g, b}

		end
	end

	-- notes
	local hitonrow = {}
	local pendingdeletion = {}

	local queuedjudge = nil

	table.sort(manager.notes, function(a,b)
		if a.created and b.created then
			return math.abs(conductor.seconds - a.endsec) < math.abs(conductor.seconds - b.endsec) -- sort the notes so that the cloest to the receptors will be the first
		else
			return false
		end
	end)

	for i,n in ipairs(manager.notes) do

		if n.removed then

			pendingdeletion[#pendingdeletion+1] = i

		else

			n:update()		

			if n.judge then -- force a judgement if the note says we should
				queuedjudge = n.judge
				n.judge = nil
			end

			local badhitwindow = manager.level.hitwindows[3][2]

			if (conductor.seconds - n.endsec > badhitwindow) then -- note is missed since player can't hit it anymore, no need to check for input

				if not n.dontmiss then

					if not n.missed then
						n.missed = true
						manager.level.judge('miss')
					end

				end

				if not n.dontdisappear then
					n:alphatransition(conductor.seconds - badhitwindow - n.endsec, 1, -1, 0.125)
				end

				local removaltime = conductor.seconds - badhitwindow - n.endsec

				if n.type == 'hold' then
					removaltime = 0
					if not n.holding then
						removaltime = conductor.seconds - n.stopholdsec
					end
				end

				if removaltime >= 0.125 then
					pendingdeletion[#pendingdeletion+1] = i
				end

			else -- not missed yet, lets check for input

				if n.checkhit then -- sometimes we might want to not check the notes for a hit. if this is false or nil, we wont check for hit

					if not hitonrow[n.row] then

						local row = rowtoreceptordir[n.row]

						if input.getkey(row) == 1 then -- hit detection

							local diff = conductor.seconds - n.endsec
							local ishit = manager.level.inrange(diff)

							if ishit then

								local didhit, newjudgement = n:hit(ishit)

								if didhit then -- if we hit, we do all these stuff. if not, we dont do anything!

									if n.type ~= 'hold' then
										manager.level.judge(newjudgement)
										manager.explosion(n.row, row, newjudgement)
									else
										manager.explosion(n.row, row, ishit)
									end

									hitonrow[n.row] = true -- dont remove multiple arrows on the same row in the same frame

								end

							end

						end

					end

				end

			end

			if not n.removed then
				for _,_n in ipairs(n.nt) do
					_n:copy(n) -- make each note copy the base; this way we dont do and behaviour for each note but still update them
				end
			end

		end

	end

	-- removing the notes
	for i=#pendingdeletion,1,-1 do
		local n = manager.notes[pendingdeletion[i]]
		n:remove()
		table.remove(manager.notes, pendingdeletion[i])
	end

	if queuedjudge then
		manager.level.judge(queuedjudge)
	end

	-- explosions
	for _,receptors in ipairs(manager.receptors) do

		for ridx,row in ipairs(rowtoreceptordir) do

			local receptor = receptors[row]
			local explo = receptor.explosion

			-- are we holding a note right now?
			local holding = false
			for _,n in ipairs(manager.notes) do
				if n.holding and n.row == ridx then
					holding = true
					break
				end
			end

			if holding then -- yes? make the explo note change alpha quickly then

				explo.alpha = 0.5+(math.sin(conductor.seconds*20)+1)*0.25
				explo['startsec'] = conductor.seconds

			else -- no? alright, normal procedure then

				local progress = conductor.seconds - explo['startsec']
				explo.alpha = easing.linear(math.min(progress, 0.3), 1, -1, 0.3)

			end

			explo.alpha = explo.alpha * explo['alphamult']

		end

	end

end

return manager