local manager = {}

manager.notes = {}
manager.receptors = {}
local lastid = 0

local notetypes = {
	normal = require '_base/notes/normal',
	hold = require '_base/notes/hold'
}

local rowtoreceptordir = {
	'left', 'down', 'up', 'right'
}

local colors = require '_base/notes/colors'
local measures = require '_base/notes/measures'
local conductor = require '_base/conductor'
local input = require '_base/input'
local judgement = require '_base/notes/judgement'
local easing = require 'easing'

manager.noteease = easing.linear
manager.holdease = easing.linear

function manager.spawn(type, line, duration, row, measure, distance, ...)

	for _,receptors in ipairs(manager.receptors) do

		local receptordir = rowtoreceptordir[row]
		local receptor = receptors[receptordir]

		local note = notetypes[type].spawn(duration, receptor, distance, manager.noteease, manager.holdease, ...)
		note.row = row
		note.measure = measure
		note.id = lastid

		if line then

			measures.addnote(note, line)
			manager.setnotecolor(note)

		else

			note:setcolor(colors.getinvalid()) -- automatically set to gray color if we dont have a line, such as when a note is created via the chart lua

		end

		manager.notes[#manager.notes + 1] = note

	end

	lastid = lastid + 1

end

function manager.setnotecolor(note)

	local color = colors.getcolor(note)
	note:setcolor(color)

end

function manager.createreceptors()

	local receptors = {}

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
		rcptr.explosion['startsec'] = 0.3

		rcptr.parent.SendToTop()

		return rcptr
	end

	receptors.left = newreceptor(-48, -90)
	receptors.down = newreceptor(-16, 0)
	receptors.up = newreceptor(16, 180)
	receptors.right = newreceptor(48, 90)

	return receptors

end

function manager.removereceptors(t)

	for _,dir in ipairs(rowtoreceptordir) do
		t[dir].visual.Remove()
		t[dir].parent.Remove()
	end

end

function manager.reset()
	manager.notes = {}
	manager.receptors = {}
	lastid = 0
end

function manager.init()
	manager.receptors[1] = manager.createreceptors()

	judgement.judgetext.SetParent(manager.receptors[1].center)
	judgement.init()
end

function manager.exit()

	manager.removereceptors(manager.receptors[1])
	manager.reset()

end

function manager.explosion(idx, row, hit)

	hit = hit:gsub('_base/judgement/', '')

	for _,receptors in ipairs(manager.receptors) do

		local receptor = receptors[row]

		receptor.explosion.Set('_base/arrow/hit_'..hit)
		receptor.explosion['startsec'] = conductor.seconds

	end

end

function manager.update()

	if not conductor.playing then return end

	judgement.update()

	-- darkening receptors
	for _,r in ipairs(manager.receptors) do
		for _,row in ipairs(rowtoreceptordir) do
			local receptor = r[row].visual
			receptor.color = ((input.getkey(row) > 0) and {0.5, 0.5, 0.5}) or {1, 1, 1}
		end
	end

	-- notes
	local hitonrow = {}
	local pendingdeletion = {}

	for i=1,#manager.notes do

		local n = manager.notes[i]

		if n.removed then

			pendingdeletion[#pendingdeletion+1] = i

		else

			n:update(conductor.seconds)

			if n.judge then -- force a judgement if the note has a judge key
				judgement.judge(n.judge)
				n.judge = nil
			end

			local badhitwindow = judgement.hitwindows[3][2]

			if (conductor.seconds - n.endsec > badhitwindow) then -- note is missed since player can't hit it anymore, no need to check for input

				if not n.dontmiss then

					if not n.missed then
						n.missed = true
						judgement.judge('miss')

						-- search for notes that hit at the same time, mark those as missed to not get multiple misses for one note
						for j=i+1,#manager.notes do
							local n2 = manager.notes[j]
							if n.id == n2.id then
								n2.missed = true
							end
						end
					end

				end

				if not n.dontdisappear then
					n:disappear(conductor.seconds - badhitwindow)
				end

				if n.sprite.alpha <= 0 then
					pendingdeletion[#pendingdeletion+1] = i
				end

			else -- not missed yet, lets check for input

				if n.checkhit then -- sometimes we might want to not check the notes for a hit. if this is false or nil, we wont check for hit

					if not hitonrow[n.row] then

						local row = rowtoreceptordir[n.row]

						if input.getkey(row) == 1 then -- hit detection

							local diff = conductor.seconds - n.endsec
							local ishit = judgement.inrange(diff)

							if ishit then

								local didhit, newjudgement = n:hit(ishit)

								if didhit then -- if we hit, we do all these stuff. if not, we dont do anything!

									if newjudgement then judgement.judge(newjudgement) end -- show judgement sprite if not a hold
									manager.explosion(n.row, row, ishit) -- explosion on receptor

									hitonrow[n.row] = true -- dont remove multiple arrows on the same row in the same frame
									

									-- also search for notes that are hit at the same time as this note and remove those as well
									-- used when we have multiple receptors

									for j=i+1,#manager.notes do
										local n2 = manager.notes[j]
										if n.id == n2.id then
											n2:hit()
										end
									end

								end

							end

						end

					end

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

	-- explosions
	for _,receptors in ipairs(manager.receptors) do

		for _,row in ipairs(rowtoreceptordir) do

			local receptor = receptors[row]
			local explo = receptor.explosion

			-- are we holding a note right now?
			local holding = false
			for _,n in ipairs(manager.notes) do
				if n.holding and rowtoreceptordir[n.row] == row then
					holding = true
					break
				end
			end

			if holding then -- yes? make the explo note change alpha quickly then

				explo.alpha = 0.5+(math.sin(conductor.seconds*20)+1)*0.25

			else -- no? alright, normal procedure then

				local progress = conductor.seconds - explo['startsec']
				explo.alpha = easing.linear(math.min(progress, 0.3), 1, -1, 0.3)

			end

		end

	end

end

return manager