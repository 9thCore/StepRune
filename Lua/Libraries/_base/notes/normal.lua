local notenormal = {}

local conductor = require '_base/conductor'
local easing = require 'easing'

function notenormal.spawn(duration, receptor, distance, noteease, holdease)

	local note = {}

	note.parent = CreateSprite('empty', 'game_notepart')
	note.parent.SetParent(receptor.parent)
	note.parent.x = 0
	note.parent.y = -distance

	note.sprite = CreateSprite('_base/arrow/0', 'game_notepart')
	note.sprite.SetAnimation({'0', '1', '2', '3'}, 1/8, '_base/arrow')
	note.sprite.rotation = receptor.visual.rotation
	note.sprite.SetParent(note.parent)
	note.sprite.x = 0
	note.sprite.y = 0
	note.sprite.alpha = 0

	note.missed = false
	note.removed = false
	note.checkhit = true

	note.startsec = conductor.seconds
	note.endsec = conductor.seconds + duration

	note.distance = distance

	function note:update(sec)

		-- moving the note
		local sofar = sec - self.startsec
		local total = self.endsec - self.startsec

		self.parent.y = noteease(sofar, -self.distance, self.distance, total)

		-- alpha
		self.sprite.alpha = easing.linear(math.min(sofar, 0.125), 0, 1, 0.125)

	end

	function note:disappear(sec)

		local alpha = easing.linear(sec - self.endsec, 1, -1, 0.125)

		self.sprite.alpha = alpha

	end

	function note:hit(oldjudgement)
		self:remove()
		return true, oldjudgement
	end

	function note:remove()

		self.sprite.Remove()
		self.removed = true

	end

	function note:setcolor(color)

		self.sprite.color = color

	end

	return note

end

return notenormal