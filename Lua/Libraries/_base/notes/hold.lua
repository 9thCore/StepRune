local notehold = {}

local conductor = require '_base/conductor'
local easing = require 'easing'
local input = require '_base/input'
local spritehelper = require 'spritehelper'

local holdgrace = 0.15

function notehold.spawn(iscopy, duration, receptor, distance, noteease, holdease, holdendbeat)

	local note = {}

	note.type = 'hold'
	note.created = false

	function note:create()

		self.created = true

		self.receptor = receptor
		self.realalpha = 0

		self.parent = CreateSprite('empty', 'game_notepart')
		self.parent.SetParent(receptor.parent)
		self.parent.x = 0
		self.parent.y = -distance

		self.holdparent = CreateSprite('_base/arrow/mask/'..receptor.visual.rotation, 'game_notepart')
		self.holdparent.SetParent(self.parent)
		self.holdparent.x = 0
		self.holdparent.y = 0
		self.holdparent.alpha = 0.001

		self.sprite = CreateSprite('_base/arrow/0', 'game_notepart')
		self.sprite.SetAnimation({'0', '1', '2', '3'}, 1/8, '_base/arrow')
		self.sprite.rotation = receptor.visual.rotation
		self.sprite.SetParent(self.parent)
		self.sprite.x = 0
		self.sprite.y = 0
		self.sprite.alpha = 0

		self.holdend = CreateSprite('_base/arrow/hold_end', 'game_notepart')
		self.holdend.SetPivot(0.5,1)
		self.holdend.SetParent(self.holdparent)
		self.holdend.x = 0
		self.holdend.y = 0

		self.holdbody = CreateSprite('_base/arrow/hold_body', 'game_notepart')
		self.holdbody.shader.Set('coreshaders', 'Tiler')
		self.holdbody.SetPivot(0.5,1)
		self.holdbody.SetParent(self.holdparent)
		self.holdbody.x = 0
		self.holdbody.y = 0

		if not iscopy then

			self.missed = false
			self.removed = false
			self.checkhit = true
			self.holding = false
			self.judgement = 'perfect'

			self.startsec = conductor.seconds
			self.endsec = conductor.seconds + duration

			self.holdendsec = conductor.beattosec(holdendbeat)
			self.startholdsec = self.endsec
			self.stopholdsec = self.endsec
			self.grace = holdgrace

			self.distance = distance

			do

				local duration = self.endsec - self.startsec
				local diff = self.holdendsec - self.endsec
				local bodylength = diff/duration*self.distance

				self.initialbodylength = bodylength
				self.initialtile = bodylength / self.holdbody.height

				self.holdbody.yscale = self.initialtile
				self.holdbody.shader.SetFloat('TilesY', self.initialtile)

				self.holdend.y = -bodylength

			end

			function self:update()

				-- moving the note
				local sofar = conductor.seconds - self.startsec
				local total = self.endsec - self.startsec

				if not self.holding then -- dont move if we're holding

					if not self.heldonce then
						self.parent.y = noteease(sofar, -self.distance, self.distance, total)
					else
						self:alphatransition(conductor.seconds - self.stopholdsec, 1, -1, 0.125)
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
							self:finishhold()
						end
					end
				end

				-- alpha
				if not self.dontdisappear then -- if we're currently disappearing dont do this!
					self:alphatransition(sofar, 0, 1, 0.125) -- appear

					-- make other notes appear too
					for _,n in ipairs(self.nt) do
						n:alphatransition(sofar, 0, 1, 0.125)
					end
				end

				self:setalpha(self.realalpha)

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

			function self:hit(oldjudgement)
				self.judgement = oldjudgement
				if not self.heldonce then -- cant start holding if we already held once prior!
					self.holding = true
					self.holdstartsec = conductor.seconds
					self.heldonce = true
					return true, nil -- we did hit it
				end
				return false, nil -- we didnt hit it
			end

			function self:setcolor(color)

				self.sprite.color = color

			end

			function self:finishhold()
				self.judge = self.judgement
				self:remove()
			end

		else

			function self:copy(note)

				spritehelper.copysprite(self.parent, note.parent, false, false)
				spritehelper.copysprite(self.holdparent, note.holdparent, false, false)

				spritehelper.copysprite(self.sprite, note.sprite, false, false)
				spritehelper.copysprite(self.holdbody, note.holdbody, false, false)
				spritehelper.copysprite(self.holdend, note.holdend, false, false)

				self.holdbody.shader.SetFloat('TilesY', note.holdbody.shader.GetFloat('TilesY'))

				self:setalpha(note.realalpha)

			end

		end

		function self:remove()
				
			self.sprite.Remove()
			self.holdbody.Remove()
			self.holdend.Remove()
			self.holdparent.Remove()
			self.parent.Remove()

			self.removed = true

			if self.nt then
				for _,n in ipairs(self.nt) do
					n:remove()
				end
			end

		end

		function self:alphatransition(t, start, change, d)

			if self.holding then return end

			local alpha = easing.linear(math.min(t,d), start, change, d)

			self:setalpha(alpha)

		end

		function self:setalpha(alpha)

			self.realalpha = alpha

			self.sprite.alpha = alpha * receptor.visual.alpha
			self.holdbody.alpha = alpha * receptor.visual.alpha
			self.holdend.alpha = alpha * receptor.visual.alpha

		end

	end

	return note

end

return notehold