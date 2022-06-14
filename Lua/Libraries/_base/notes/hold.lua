local notehold = {}

local conductor = require '_base/conductor'
local easing = require 'easing'
local input = require '_base/input'

local holdgrace = 0.15

function notehold.spawn(duration, receptor, distance, noteease, holdease, holdendbeat)

	local note = {}

	note.parent = CreateSprite('empty', 'game_notepart')
	note.parent.SetParent(receptor.parent)
	note.parent.x = 0
	note.parent.y = -distance

	note.holdparent = CreateSprite('_base/arrow/mask/'..receptor.visual.rotation, 'game_notepart')
	note.holdparent.SetParent(note.parent)
	-- note.holdparent.Mask('invertedstencil') -- uncomment this when the bug related to masks and shaders is fixed!
	note.holdparent.x = 0
	note.holdparent.y = 0
	note.holdparent.alpha = 0.001

	note.sprite = CreateSprite('_base/arrow/0', 'game_notepart')
	note.sprite.SetAnimation({'0', '1', '2', '3'}, 1/8, '_base/arrow')
	note.sprite.rotation = receptor.visual.rotation
	note.sprite.SetParent(note.parent)
	note.sprite.x = 0
	note.sprite.y = 0
	note.sprite.alpha = 0

	note.holdend = CreateSprite('_base/arrow/hold_end', 'game_notepart')
	note.holdend.SetPivot(0.5,1)
	note.holdend.SetParent(note.holdparent)
	note.holdend.x = 0
	note.holdend.y = 0

	note.holdbody = CreateSprite('_base/arrow/hold_body', 'game_notepart')
	note.holdbody.shader.Set('coreshaders', 'Tiler')
	note.holdbody.SetPivot(0.5,1)
	note.holdbody.SetParent(note.holdparent)
	note.holdbody.x = 0
	note.holdbody.y = 0

	note.missed = false
	note.removed = false
	note.checkhit = true
	note.holding = false
	note.judgement = 'perfect'

	note.startsec = conductor.seconds
	note.endsec = conductor.seconds + duration

	note.holdendsec = conductor.beattosec(holdendbeat)
	note.startholdsec = note.endsec
	note.stopholdsec = note.endsec
	note.grace = holdgrace

	note.distance = distance

	do

		local duration = note.endsec - note.startsec
		local diff = note.holdendsec - note.endsec
		local bodylength = diff/duration*note.distance

		note.initialbodylength = bodylength
		note.initialtile = bodylength / note.holdbody.height

		note.holdbody.yscale = note.initialtile
		note.holdbody.shader.SetFloat('TilesY', note.initialtile)

		note.holdend.y = -bodylength

	end

	function note:update()

		-- moving the note
		local sofar = conductor.seconds - self.startsec
		local total = self.endsec - self.startsec

		if not note.holding then -- dont move if we're holding

			if not self.heldonce then
				self.parent.y = noteease(sofar, -self.distance, self.distance, total)
			else
				self:disappear(conductor.seconds - self.stopholdsec)
			end

		else
			self.dontmiss = true

			local stillholding = (input.getkey(self.row) > 0) -- if we're holding the button, we instantly know to set this to true

			if stillholding then

				self.grace = holdgrace -- still holding so reset the grace period

			elseif not stillholding then -- we aren't holding the button, lets check the grace period!

				self.grace = self.grace - Time.dt -- decrease the grace period

				if self.grace <= 0 then -- no more grace period!

					self.judge = 'miss'
					self.holding = false
					self.dontdisappear = true
					self.stopholdsec = conductor.seconds

				else

					stillholding = true -- we still have a grace period, still holding the note!

				end

			end

			if stillholding then
				if conductor.seconds >= self.holdendsec then -- we're done with the hold!
					self.judge = self.judgement
					self:remove()
				end
			end
		end

		-- alpha
		if not self.dontdisappear then -- if we're currently disappearing dont do this!
			local alpha = easing.linear(math.min(sofar, 0.125), 0, 1, 0.125)

			self.sprite.alpha = alpha
			self.holdend.alpha = alpha
			self.holdbody.alpha = alpha

		end

		if self.holding then

			self.parent.y = 0 -- snap to the receptor because it looks weird otherwise

			-- moving the hold end
			local duration = self.endsec - self.startsec
			local diff = self.holdendsec - self.holdstartsec
			local length = diff/duration*self.distance

			sofar = conductor.seconds - self.holdstartsec

			local bodylength = math.max(holdease(sofar, length, -length, diff), 0)

			self.holdend.y = -bodylength

			-- making the hold body
			self.holdbody.yscale = bodylength / self.holdbody.height

			local multiplier = self.initialbodylength / bodylength
			local tiley = self.initialtile / multiplier

			self.holdbody.shader.SetFloat('TilesY', tiley)

		end

	end

	function note:hit(oldjudgement)
		self.judgement = oldjudgement
		if not self.heldonce then -- cant start holding if we already held once!
			self.holding = true
			self.holdstartsec = conductor.seconds
			self.heldonce = true
			return true, nil -- we did hit it
		end
		return false, nil -- we didnt hit it
	end

	function note:remove()

		self.sprite.Remove()
		self.holdbody.Remove()
		self.holdend.Remove()
		self.holdparent.Remove()
		self.parent.Remove()

		self.removed = true

	end

	function note:disappear(sec)

		if self.holding then return end

		local alpha = easing.linear(sec, 1, -1, 0.125)

		self.sprite.alpha = alpha
		self.holdbody.alpha = alpha
		self.holdend.alpha = alpha

	end

	function note:setcolor(color)

		self.sprite.color = color

	end

	return note

end

return notehold