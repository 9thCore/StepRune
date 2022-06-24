local manager = {}

manager.allnotes = {} -- stores all the notes
manager.notes = {} -- stores notes currently on screen, gets sorted with the first arrows first and gets rid of them when they should be done
manager.receptors = {}
manager.realexplo = {}

local notetypes = {
	normal = require '_base/notes/normal',
	hold = require '_base/notes/hold',
	mine = require '_base/notes/mine'
}

local receptordirections = {
	'left', 'down', 'up', 'right'
}

local colors = require '_base/notes/colors'
local measures = require '_base/notes/measures'
local conductor = require '_base/conductor'
local input = require '_base/input'
local easing = require 'easing'

manager.noteease = easing.linear
manager.holdease = easing.linear

local function rotate(mat, ry, rz)

	-- https://rosettacode.org/wiki/Matrix_multiplication#Lua
	local function multiply( m1, m2 )
	    if #m1[1] ~= #m2 then       -- inner matrix-dimensions must agree
	        return nil      
	    end 
	 
	    local res = {}
	 
	    for i = 1, #m1 do
	        res[i] = {}
	        for j = 1, #m2[1] do
	            res[i][j] = 0
	            for k = 1, #m2 do
	                res[i][j] = res[i][j] + m1[i][k] * m2[k][j]
	            end
	        end
	    end
	 
	    return res
	end

	local rady = ry/180*math.pi
	local radz = rz/180*math.pi

	local sin = math.sin
	local cos = math.cos

	local yrot = {
		{cos(rady), 0, sin(rady), 0},
		{0, 1, 0, 0},
		{-sin(rady), 0, cos(rady), 0},
		{0, 0, 0, 1}
	}

	local zrot = {
		{cos(radz), sin(radz), 0, 0},
		{-sin(radz), cos(radz), 0, 0},
		{0, 0, 1, 0},
		{0, 0, 0, 1}
	}

	local rotmat = multiply(yrot, zrot)

	return multiply(mat, rotmat)

end

function manager.new(t)

	local newnote = manager.spawn(table.unpack(t))

	newnote.count = #newnote

	manager.allnotes[#manager.allnotes+1] = newnote

	return newnote, #manager.allnotes

end

function manager.getnote(idx)
	return manager.allnotes[idx]
end

function manager.create(note, i)

	note:create(manager.noteease, manager.holdease)

	for _,n in ipairs(note.nt) do
		n:create(manager.noteease, manager.holdease)
	end

	local line = note.line
	if line then
		measures.addnote(note, line)
		manager.setnotecolor(note)
	else
		note:SetColor(colors.getinvalid()) -- automatically set to gray color if we dont have a line, such as when a note is created via the chart lua
	end

	manager.notes[#manager.notes+1] = note
	manager.allnotes[i] = note

end

function manager.spawn(type, dur, line, row, measure, distance, ...)

	local receptordir = receptordirections[row]
	local receptor = manager.receptors[1][receptordir] -- get first receptor, this will be the parent of the note we track and update

	local note = notetypes[type].spawn(false, dur, receptor, distance, ...)
	note.row = row
	note.measure = measure
	note.line = line
	note.nt = {}

	-- now spawn the other notes
	for i=2,#manager.receptors do

		local rcptrs = manager.receptors[i]
		local rcptr = rcptrs[receptordir]

		local _note = notetypes[type].spawn(true, dur, rcptr, distance, ...)

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

	receptors.moved = false

	receptors.x = 320
	receptors.y = 300

	receptors.rotx = 0
	receptors.roty = 0
	receptors.rotz = 0

	receptors.distscale = 1
	receptors.xscale = 1
	receptors.yscale = 1

	receptors.pivot = 0

	receptors.color = {1,1,1}

	local function newreceptor(xoffset, rot)
		local rcptr = {}

		rcptr.parent = CreateSprite('empty', 'game_receptor') -- the invisible sprite used to parent the arrows
		rcptr.parent.x = receptors.x + xoffset
		rcptr.parent.y = receptors.y

		rcptr.visual = CreateSprite('_base/arrow/0', 'game_receptor') -- the visible sprite used for showing where the receptor is
		rcptr.visual.SetAnimation({'0', '1', '2', '3'}, 1/8, '_base/arrow')
		rcptr.visual.x = receptors.x + xoffset
		rcptr.visual.y = receptors.y
		rcptr.visual.rotation = rot

		rcptr.explosion = CreateSprite('_base/arrow/hit_perfect', 'game_receptor') -- the explosion after hitting a note
		rcptr.explosion.SetParent(rcptr.visual)
		rcptr.explosion.x = 0
		rcptr.explosion.y = 0
		rcptr.explosion.rotation = rot
		rcptr.explosion.alpha = 0
		rcptr.explosion['startsec'] = -10
		rcptr.explosion['alphamult'] = 1

		rcptr.xoffset = xoffset
		rcptr.z = 0
		rcptr.origrot = rot

		rcptr.object = receptors

		rcptr.parent.SendToTop()


		rcptr.wrap = {}
		-- making the wrapped version of the parent and visual sprites

		do

			local rv = rcptr.visual
			local rp = rcptr.parent

			rcptr.wrap['x'] = 0
			rcptr.wrap['y'] = 0

			rcptr.wrap['xscale'] = 1
			rcptr.wrap['yscale'] = 1

			rcptr.wrap['distscale'] = 1

			function rcptr.wrap.RotateVisual(rot, additive)
				rv.rotation = rot + ((additive and rv.rotation) or rcptr.origrot)
			end

			function rcptr.wrap.RotateParent(rot, additive)
				rp.rotation = rot + ((additive and rv.rotation) or 0)
			end

			function rcptr.wrap.Rotate(rot, additive)
				rcptr.wrap.RotateVisual(rot, additive)
				rcptr.wrap.RotateParent(rot, additive)
			end

			function rcptr.wrap.Scale(x, y, additive)

				rcptr.wrap['xscale'] = x + ((additive and rcptr.wrap['xscale']) or 0)
				rcptr.wrap['yscale'] = y + ((additive and rcptr.wrap['yscale']) or 0)

				receptors.moved = true

			end

			function rcptr.wrap.ScaleDistance(x, y, additive)

				rcptr.wrap['distscale'] = x + ((additive and rcptr.wrap['distscale']) or 0)

			end

			function rcptr.wrap.Move(x, y)
				rcptr.wrap['x'] = rcptr.wrap['x'] + x
				rcptr.wrap['y'] = rcptr.wrap['y'] + y

				receptors.moved = true

			end

			function rcptr.wrap.MoveTo(x, y)
				rcptr.wrap['x'] = x
				rcptr.wrap['y'] = y

				receptors.moved = true

			end

		end

		return rcptr

	end

	receptors.left = newreceptor(-48, 270)
	receptors.down = newreceptor(-16, 0)
	receptors.up = newreceptor(16, 180)
	receptors.right = newreceptor(48, 90)

	-- SETTERS --
	function receptors:SetAlpha(val)

		for _,r in ipairs(receptordirections) do
			self[r].visual.alpha = val
			self[r].explosion['alphamult'] = val
		end

	end

	function receptors:Hide()
		self:SetAlpha(0)
	end

	function receptors:Show()
		self:SetAlpha(1)
	end

	function receptors:SetColor(col, g, b, a)
		if type(col) ~= 'table' then col = {col, g, b, a} end
		if col[4] then self:SetAlpha(col[4]) end

		self.color = col

	end

	function receptors:Move(x,y)

		self.x = self.x + x
		self.y = self.y + y

		self.moved = true

	end

	function receptors:MoveTo(x,y)

		self.x = x
		self.y = y

		self.moved = true

	end

	function receptors:RotateZ(rot, all, additive)

		self.rotz = (rot + ((additive and self.rotz) or 0))%360

		if all then
			for _,r in ipairs(receptordirections) do
				self[r].wrap.RotateVisual(rot, additive)
				self[r].wrap.RotateParent(rot + ((additive and (360 - self[r].origrot + 360)) or 0), additive) -- :)
			end
		end

		self.moved = true

	end

	function receptors:RotateY(rot, additive)

		self.roty = (rot + ((additive and self.roty) or 0))%360
		self.moved = true

	end

	-- doesn't do anything yet haha, just for completeness sake
	function receptors:RotateX(rot, additive)

		self.rotx = (rot + ((additive and self.rotx) or 0))%360

	end

	function receptors:ScaleArrows(x, y, additive)

		for _,r in ipairs(receptordirections) do
			self[r].wrapvisual.Scale(x,y)
		end
		self.moved = true

	end

	function receptors:ScaleDistance(x, additive)

		self.distscale = x + ((additive and self.distscale) or 0)
		self.moved = true

	end

	function receptors:Scale(x, y, additive)

		self:ScaleArrows(x, y, additive)
		self:ScaleDistance(x, additive)

	end

	function receptors:SetPivot(x, additive)

		self.pivot = x + ((additive and self.pivot) or 0)
		self.moved = true

	end

	-- OTHER --
	function receptors:UpdateReceptorPos()

		-- apply transformations

		for i,r in ipairs(receptordirections) do

			local rec = self[r]

			local newx = rec.wrap['x']
			local newy = rec.wrap['y']

			local xscale = rec.wrap['xscale']
			local yscale = rec.wrap['yscale']

			local offset = rec.xoffset + self.pivot

			-- scale
			newx = newx + offset * self.distscale

			-- rotation
			local vec = {
				{newx, 0, 0, 1}
			}

			local mat = rotate(vec, self.roty, self.rotz)

			local x, y, z = mat[1][1], mat[1][2], mat[1][3]

			newx = x
			newy = newy + y + z/4*self.distscale

			rec.z = z

			xscale = xscale - z/(rec.visual.width*1.5)/6
			yscale = yscale - z/(rec.visual.height*1.5)/6

			-- finalising
			newx = newx + self.x
			newy = newy + self.y

			rec.parent.MoveTo(newx, newy)

			rec.visual.MoveTo(newx, newy)
			rec.visual.Scale(xscale, yscale)

			rec.explosion.Scale(xscale, yscale)

		end

	end

	return receptors

end

function manager.exploreal(x, y)

	local e = CreateSprite('empty', 'game_notepart')
	e.SetAnimation({'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15'}, 1/30, '_base/explosion')
	e.loopmode = 'ONESHOTEMPTY'
	e.MoveToAbs(x,y)

	manager.realexplo[#manager.realexplo+1] = e

end

function manager.removereceptors(t)

	for _,dir in ipairs(receptordirections) do
		t[dir].visual.Remove()
		t[dir].parent.Remove()
		t[dir].explosion.Remove()
	end

end

function manager.reset()
	for _,r in ipairs(manager.receptors) do
		manager.removereceptors(r)
	end

	for _,n in ipairs(manager.allnotes) do
		if n.created and not n.removed then
			n:remove()
		end
	end

	for _,e in ipairs(manager.realexplo) do
		e.Remove()
	end

	manager.notes = {}
	manager.allnotes = {}
	manager.receptors = {}
	manager.realexplo = {}

	manager.noteease = easing.linear
	manager.holdease = easing.linear
	
end

function manager.init()

	for i=1,4 do
		manager.receptors[i] = manager.createreceptors()
		manager.receptors[i]:MoveTo(320,300)
		if i > 1 then manager.receptors[i]:Hide() end
	end

end

function manager.exit()
	manager.reset()
end

function manager.explosion(row, hit)

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

	-- receptor stuff

	local sorter = {} -- table all the receptors get thrown in to change their order

	for _,r in ipairs(manager.receptors) do

		-- update their position
		if r.moved then -- only update if the chart actually moved them this frame
			r:UpdateReceptorPos()
			r.moved = false
		end

		for _,row in ipairs(receptordirections) do

			local receptor = r[row].visual

			local col = r.color
			local red, g, b = col[1], col[2], col[3]

			receptor.color = ((input.getkey(row) > 0) and {red*0.5, g*0.5, b*0.5}) or {red, g, b}

			sorter[#sorter+1] = r[row] -- add the receptors to a table

		end

	end

	-- sort said table
	table.sort(sorter, function(a,b)
		if math.abs(a.z - b.z) < 0.001 then -- practically same z coord
			return a.parent.y > b.parent.y
		end
		return a.z > b.z
	end)

	-- fix their render order
	for _,r in ipairs(sorter) do

		r.visual.SendToTop()
		r.parent.SendToTop()

	end


	-- notes
	local hitonrow = {}
	local pendingdeletion = {}

	local queuedjudge = {}

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

			if manager.level.autoplay then

				local ishit = n:autoplay()

				if ishit then
					manager.level.judge('perfect')
					manager.explosion(receptordirections[n.row], 'perfect')
				end

				if n.type == 'mine' then

					local badhitwindow = manager.level.hitwindows[3][2]
					if conductor.seconds - n.endsec > badhitwindow then
						n:alphatransition(conductor.seconds - badhitwindow - n.endsec, 1, -1, 0.125)

						local removaltime = conductor.seconds - badhitwindow - n.endsec

						if removaltime >= 0.125 then
							pendingdeletion[#pendingdeletion+1] = i
						end

					end

				end

			else

				if n.judge then -- force a judgement if the note says we should

					queuedjudge[#queuedjudge+1] = n.judge
					n.judge = nil

				end

				local badhitwindow = manager.level.hitwindows[3][2]

				if conductor.seconds - n.endsec > badhitwindow then -- note is missed since player can't hit it anymore, no need to check for input

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

							local row = receptordirections[n.row]

							if input.getkey(row) == 1 then -- hit detection

								local diff = conductor.seconds - n.endsec
								local ishit = manager.level.inrange(diff)

								if ishit then

									local didhit, newjudgement = n:hit(ishit)

									if didhit then -- if we hit, we do all these stuff. if not, we dont do anything!

										if n.type ~= 'hold' then
											manager.level.judge(newjudgement)
											manager.explosion(row, newjudgement)

											if n.type == 'mine' and manager.level.mineexplos then
												NewAudio.PlaySound('boom', 'boom', false, 0.5)
												manager.exploreal(n.receptor.visual.absx, n.receptor.visual.absy)
											end
										else
											manager.explosion(row, ishit)
										end

										hitonrow[n.row] = true -- dont remove multiple arrows on the same row in the same frame

									end

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

	for _,j in ipairs(queuedjudge) do
		manager.level.judge(j)
	end

	-- explosions
	for _,receptors in ipairs(manager.receptors) do

		for ridx,row in ipairs(receptordirections) do

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

	-- lmao
	for i=#manager.realexplo,1,-1 do
		local e = manager.realexplo[i]
		if e.spritename == 'blank' then
			e.Remove()
			table.remove(manager.realexplo,i)
		end
	end

end

function manager.wrapsinglereceptor(r)

	local t = {}

	setmetatable(t, {
		__index = function(t,k)
			if type(r.wrap[k]) == 'function' then
				return r.wrap[k]
			elseif k == 'x' then
				return r.wrap['x']
			elseif k == 'y' then
				return r.wrap['y']
			elseif k == 'rotation' then
				return r.visual.rotation
			elseif k == 'xscale' then
				return r.wrap['xscale']
			elseif k == 'yscale' then
				return r.wrap['yscale']
			elseif k == 'distscale' then
				return r.wrap['distscale']
			end
		end,
		__newindex = function(t,k,v)
			if k == 'x' then
				r.wrap.MoveTo(v, r.wrap['y'])
			elseif k == 'y' then
				r.wrap.MoveTo(r.wrap['x'], v)
			elseif k == 'rotation' then
				r.wrap.Rotate(v)
			elseif k == 'xscale' then
				r.wrap.Scale(v, r.wrap['yscale'])
			elseif k == 'yscale' then
				r.wrap.Scale(r.wrap['xscale'], v)
			elseif k == 'distscale' then
				r.wrap.ScaleDistance(v)
			end
		end,
		__metatable = false
	})

	return t

end

function manager.wrapreceptors(r)

	local t = {}

	local disallowed = {
		UpdateReceptorPos = true, moved = true
	}
	local aliases = {
		rotation = 'rotz'
	}

	-- the receptors themselves
	t.left = manager.wrapsinglereceptor(r.left)
	t.down = manager.wrapsinglereceptor(r.down)
	t.up = manager.wrapsinglereceptor(r.up)
	t.right = manager.wrapsinglereceptor(r.right)

	-- functions
	for fn,fc in pairs(r) do

		if not disallowed[fn] then

			if type(fc) == 'function' then
				t[fn] = function(...) -- . syntax, not :
					return fc(r,...)
				end
			end

		end

	end

	setmetatable(t, {
		__index = function(t,k)
			if not disallowed[k] then
				if aliases[k] then k = aliases[k] end
				return r[k]
			end
		end,
		__newindex = function(t,k,v)
			if disallowed[k] then return end -- no

			-- ._.
			if k == 'x' then -- position
				r:MoveTo(v, r.y)
			elseif k == 'y' then
				r:MoveTo(r.x, v)
			elseif k == 'distscale' then -- scale
				r:ScaleDistance(v)
			elseif k == 'xscale' then
				r:Scale(v, r.yscale)
			elseif k == 'yscale' then
				r:Scale(r.xscale, v)
			elseif k == 'rotx' then -- 3d rotation
				r:RotateX(v)
			elseif k == 'roty' then
				r:RotateY(v)
			elseif k == 'rotz' or k == 'rotation' then
				r:RotateZ(v)
			elseif k == 'color' then -- color
				r:SetColor(v)
			elseif k == 'alpha' then
				r:SetAlpha(v)
			elseif k == 'pivot' then -- pivot
				r:SetPivot(v)
			end
		end,
		__metatable = false
	})

	return t

end

function manager.getobject()

	local obj = {}

	function obj.GetNote(idx)
		return manager.getnote(idx) -- TODO: wrap this
	end

	function obj.GetReceptor(idx)
		if idx < 1 or idx > #manager.receptors then return end
		return manager.wrapreceptors(manager.receptors[idx])
	end

	function obj.GetReceptors()

		local t = {}

		for i,_ in ipairs(manager.receptors) do
			t[#t+1] = obj.GetReceptor(i)
		end

		return t

	end

	function obj.SetNoteEasing(func)
		manager.noteease = func
	end

	function obj.SetHoldEasing(func)
		manager.holdease = func
	end

	return obj

end

return manager