local notenormal = {}

local conductor = require '_base/conductor'
local easing = require 'easing'

function notenormal.spawn(iscopy, duration, receptor, distance, noteease, holdease)

	local note = {}

	note.type = 'normal'
	note.created = false

	function note:create()

		self.created = true

		self.receptor = receptor

		self.realalpha = 0
		self.rotoffset = 0
		self.scalex = 1
		self.scaley = 1

		self.parent = CreateSprite('empty', 'game_receptor')
		self.parent.SetParent(receptor.parent)
		self.parent.x = 0
		self.parent.y = -distance

		self.sprite = CreateSprite('_base/arrow/0', 'game_receptor')
		self.sprite.SetAnimation({'0', '1', '2', '3'}, 1/8, '_base/arrow')
		self.sprite.rotation = receptor.visual.rotation
		self.sprite.SetParent(self.parent)
		self.sprite.x = 0
		self.sprite.y = 0
		self.sprite.alpha = 0

		self.startsec = conductor.seconds
		self.endsec = conductor.seconds + duration

		if not iscopy then -- we dont actually need all the functions if this is just a sprite that copies the base!

			self.missed = false
			self.removed = false
			self.checkhit = true

			self.distance = distance

			function self:update()

				-- moving the note
				local sofar = conductor.seconds - self.startsec
				local total = self.endsec - self.startsec

				self.parent.y = noteease(sofar, -self.distance, self.distance, total)

				-- appear
				self:alphatransition(sofar, 0, 1, 0.125)

				-- make other notes appear too
				for _,n in ipairs(self.nt) do
					n:alphatransition(sofar, 0, 1, 0.125)
				end

				self:fixrot()
				self:fixscale()

				for _,n in ipairs(self.nt) do
					n:fixrot()
					n:fixscale()
				end

			end

			function self:hit(oldjudgement)
				self:remove()
				return true, oldjudgement
			end

			function self:autoplay()
				if conductor.seconds >= self.endsec then
					self:hit()
					return true
				end
				return false
			end

		else

			function self:copy(note)

				self.parent.x = note.parent.x
				self.parent.y = note.parent.y

			end

		end

		function self:rotate(rot, additive)
			additive = not not additive

			self.rotoffset = rot + ((additive and self.rotoffset) or 0)
			self:fixrot()
		end

		function self:fixrot()
			self.sprite.rotation = receptor.visual.rotation + self.rotoffset
		end

		function self:fixscale()

			self.sprite.xscale = receptor.visual.xscale * self.scalex
			self.sprite.yscale = receptor.visual.yscale * self.scaley

		end

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

		end

		function self:setcolor(color)

			self.sprite.color = color

			if self.nt then
				for _,n in ipairs(self.nt) do
					n:setcolor(color)
				end
			end

		end

		function self:setalpha(alpha)

			self.realalpha = alpha
			self.sprite.alpha = alpha * receptor.visual.alpha

			if self.nt then
				for _,n in ipairs(self.nt) do
					n:setalpha(alpha)
				end
			end

		end

	end

	return note

end

return notenormal