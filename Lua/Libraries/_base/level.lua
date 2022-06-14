local level = {}

CreateLayer('game_receptor', 'game_cover', false)
CreateLayer('game_holdbody', 'game_receptor', false)
CreateLayer('game_notepart', 'game_holdbody', false)
CreateLayer('game_ui', 'game_notepart', false)

NewAudio.CreateChannel('game_music')

local conductor = require '_base/conductor'
local measures = require '_base/notes/measures'
local notemanager = require '_base/notes/manager'

level.gamecover = CreateSprite('black', 'game_cover')
level.gamecover.alpha = 0

local ChartPath

function level.init()

	notemanager.reset()
	ChartPath = _G['ChartPath']
end

function level.load(t)

	level.gamecover.alpha = 1

	measures.reset()
	conductor.reset()

	conductor.setbpms(t.bpms)
	
	for _,note in ipairs(t.notes) do
		measures.set(note.measure, note.measurelinecount)
		conductor.addevent(note.beat, 3, notemanager.spawn, note.type, note.lineinmeasure, 3, note.row, note.measure, 240, note.holdendbeat)
	end

	NewAudio.PlayMusic('game_music', '../' .. ChartPath .. '/' .. t.chartname .. '/music')
	NewAudio.Pause('game_music')

	conductor.addevent(0, t.songoffset, NewAudio.Unpause, 'game_music')

	conductor.sortevents()
	conductor.start()

	notemanager.init()

end

function level.update()

	if not conductor.playing then return end

	if ChartUpdate then ChartUpdate() end
	notemanager.update()
	if ChartLateUpdate then ChartLateUpdate() end

end

return level