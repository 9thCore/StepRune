local notemine = {}

local conductor = require '_base/conductor'
local easing = require '_base/easing'

NewAudio.CreateChannel('boom')

function notemine.spawn(iscopy, duration, receptor, distance)

	local note = {}

	note.type = 'mine'
	note.created = false

	function note:create(noteease, holdease)

		self.created = true

		self.receptor = receptor

		self.rotoffset = 0
		self.xscale = 1
		self.yscale = 1

		self.x = 0
		self.y = 0

		self.parent = CreateSprite('empty', 'game_receptor')
		self.parent.SetParent(receptor.parent)
		self.parent.x = 0
		self.parent.y = -distance

		self.sprite = CreateSprite('_base/arrow/mine', 'game_receptor')
		self.sprite.rotation = receptor.visual.rotation
		self.sprite.SetParent(self.parent)
		self.sprite.x = 0
		self.sprite.y = 0
		self.sprite.alpha = 0

		if not iscopy then -- we dont actually need all the functions if this is just a sprite that copies the base!

			self.missed = false
			self.removed = false
			self.checkhit = true
			self.dontmiss = true

			self.startsec = conductor.seconds
			self.endsec = conductor.seconds + duration

			self.distance = distance

			function self:update()

				-- moving the note
				local sofar = conductor.seconds - self.startsec
				local total = self.endsec - self.startsec

				local dist = self.distance * receptor.wrap['distscale']
				self.parent.y = noteease(sofar, -dist, dist, total) + self.y
				self.parent.x = self.x

				self.sprite.rotation = conductor.seconds*90 + self.rotoffset

				for _,n in ipairs(self.nt) do
					n.sprite.rotation = self.sprite.rotation
				end

				-- appear
				self:alphatransition(sofar, 0, 1, 0.125)

				-- make other notes appear too
				for _,n in ipairs(self.nt) do
					n:alphatransition(sofar, 0, 1, 0.125)
				end

				self:fixscale()
				for _,n in ipairs(self.nt) do
					n:fixscale()
				end

			end

			function self:hit(oldjudgement)
				self:remove()
				return true, 'miss'
			end

			function self:autoplay()
				return false
			end

		else

			function self:copy(note)

				self.parent.x = note.parent.x - note.x + self.x
				self.parent.y = note.parent.y - note.y + self.y

			end

		end

		function self:scale(x, y, additive)
			self.xscale = x + ((additive and self.xscale) or 0)
			self.yscale = y + ((additive and self.yscale) or 0)
			self:fixscale()
		end

		function self:rotate() end

		function self:setcolor() end

		function self:remove()

			self.sprite.Remove()
			self.parent.Remove()

			if self.nt then
				for _,n in ipairs(self.nt) do
					n:remove()
				end
			end

			self.removed = true

		end

		function self:alphatransition(t, start, change, d)

			local alpha = easing.linear(math.min(t,d), start, change, d)
			self:setalpha(alpha)

			if self.nt then
				for _,n in ipairs(self.nt) do
					n:setalpha(alpha)
				end
			end

		end

		function self:fixscale()
			self.sprite.xscale = receptor.visual.xscale * self.xscale
			self.sprite.yscale = receptor.visual.yscale * self.yscale
		end

		function self:setalpha(alpha)

			self.sprite.alpha = alpha * receptor.visual.alpha

		end

	end

	return note

end

return notemine