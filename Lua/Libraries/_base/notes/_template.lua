local notenormal = {}

local conductor = require '_base/conductor'
local easing = require 'easing'
local spritehelper = require 'spritehelper'

function notenormal.spawn(iscopy, duration, receptor, distance, noteease, holdease)

	local note = {}

	note.type = ''
	note.created = false

	function note:create()

		self.created = true

		self.parent = CreateSprite('empty', 'game_notepart')
		self.parent.SetParent(receptor.parent)
		self.parent.x = 0
		self.parent.y = -distance

		self.sprite = CreateSprite('_base/arrow/0', 'game_notepart')
		self.sprite.SetAnimation({'0', '1', '2', '3'}, 1/8, '_base/arrow')
		self.sprite.rotation = receptor.visual.rotation
		self.sprite.SetParent(self.parent)
		self.sprite.x = 0
		self.sprite.y = 0
		self.sprite.alpha = 0

		if not iscopy then -- we dont actually need all the functions if this is just a sprite that copies the base!

			self.missed = false
			self.removed = false
			self.checkhit = true

			self.startsec = conductor.seconds
			self.endsec = conductor.seconds + duration

			self.distance = distance

			function self:update()

				-- moving the note
				local sofar = conductor.seconds - self.startsec
				local total = self.endsec - self.startsec

				self.parent.y = noteease(sofar, -self.distance, self.distance, total)

				-- appear
				self:alphatransition(sofar, 0, 1, 0.125)

			end

			function self:alphatransition(t, start, change, d)

				local alpha = easing.linear(math.min(t,d), start, change, d) * receptor.visual.alpha
				self.sprite.alpha = alpha

			end

			function self:hit(oldjudgement)
				self:remove()
				return true, oldjudgement
			end

			function self:setcolor(color)

				self.sprite.color = color

			end

		else

			function self:copy(note)

				spritehelper.copysprite(self.parent, note.parent, false, false)
				spritehelper.copysprite(self.sprite, note.sprite, false, false)

			end

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

	end

	return note

end

return notenormal