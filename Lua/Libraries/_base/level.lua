local level = {}

CreateLayer('game_receptor', 'game_cover', false)
CreateLayer('game_holdbody', 'game_receptor', false)
CreateLayer('game_notepart', 'game_holdbody', false)
CreateLayer('game_ui', 'game_notepart', false)

NewAudio.CreateChannel('game_music')

local conductor = require '_base/conductor'
local measures = require '_base/notes/measures'
local notemanager = require '_base/notes/manager'
local loader = require '_base/loader'
local judgement = require '_base/notes/judgement'
local ui = require '_base/ui'

notemanager.level = level
judgement.level = level

level.gamecover = CreateSprite('black', 'game_cover')
level.gamecover.alpha = 0

level.lastbeat = 0

level.hits = 0
level.misses = 0
level.total = 0
level.acc = 100
level.combo = 0
level.hp = 100

level.judgementproperties = {
	perfect = {hitweight = 1, miss = 0, heal = 4, combomult = 1/50},
	great = {hitweight = 1/3, miss = 0, heal = 2, combomult = 1/50},
	bad = {hitweight = 1/6, miss = 0, heal = -3, combomult = 1/50},
	miss = {hitweight = 0, miss = 1, heal = -6, combomult = 0}
}

level.hitwindows = { -- in a separate table so that we ensure we go through the windows in order: perfect > great > bad
	{'perfect', 0.1},
	{'great', 0.2},
	{'bad', 0.3}
}

function level.init()

	level.hits = 0
	level.misses = 0
	level.total = 0
	level.combo = 0

	level.hp = 100
	level.acc = 100

	ui.init()
	notemanager.reset()

end

function level.inrange(sec)
	sec = math.abs(sec)
	for _,t in ipairs(level.hitwindows) do
		if sec < t[2] then
			return t[1]
		end
	end
	return false
end

function level.judge(j)

	local spr = '_base/judgement/' .. j

	if type(spr) == 'table' then spr = spr[1] end
	
	ui.judgetext.Set(spr)
	ui.judgetext.alpha = 1
	ui.judgetext.Scale(0.55,0.55)
	ui.judgetext['timer'] = 0


	-- get how much to add to hits and misses based off the current judgement
	local hitcnt = level.judgementproperties[j].hitweight
	local misscnt = level.judgementproperties[j].miss

	-- update combo
	if misscnt > 0 then -- oops, missed! no more combo :crab:
		level.combo = 0
	else
		level.combo = level.combo + 1 -- more combo yippee
	end

	level.hits = level.hits + hitcnt
	level.misses = level.misses + misscnt
	level.total = level.total + 1

	-- update misses
	ui.updatemiss(level.misses)

	-- update accuracy
	if level.total > 0 then level.acc = level.hits/level.total*100
	else level.acc = 100
	end

	ui.updateacc(level.acc)


	-- update hp
	local healcnt = level.judgementproperties[j].heal
	local combomult = level.judgementproperties[j].combomult

	level.hp = level.hp + healcnt + level.combo*combomult
	level.hp = math.max(math.min(level.hp, 100), 0) -- clamp 0-100

	ui.hpbar.easefill(level.hp/100)

end

function level.finish()

	DEBUG('woo finished')

end

function level.load(t)

	level.gamecover.alpha = 1

	notemanager.reset()
	ui.load()
	measures.reset()
	conductor.reset()

	conductor.setbpms(t.bpms)

	notemanager.init()
	
	for _,note in ipairs(t.notes) do
		measures.set(note.measure, note.measurelinecount)

		local appeardur = 3
		local dist = 240

		local new = notemanager.new{note.type, note.lineinmeasure, appeardur, note.row, note.measure, dist, note.holdendbeat}

		conductor.addevent(note.beat, appeardur, notemanager.create, new)

		level.lastbeat = math.max(level.lastbeat, note.beat)

	end

	-- the song
	NewAudio.PlayMusic('game_music', '../' .. ChartPath .. '/' .. t.chartname .. '/music')
	NewAudio.Pause('game_music')

	conductor.addevent(0, t.songoffset, NewAudio.Unpause, 'game_music')

	-- finish
	conductor.addevent(level.lastbeat, -2000, level.finish) -- negative offset because we want this to happen 2 seconds *later*!

	conductor.sortevents()
	conductor.start()

end

function level.update()

	if not conductor.playing then return end

	if ChartUpdate then ChartUpdate() end
	notemanager.update()
	ui.update()
	if ChartLateUpdate then ChartLateUpdate() end

end

return level