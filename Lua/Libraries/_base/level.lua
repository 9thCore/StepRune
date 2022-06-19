local level = {}

CreateLayer('game_receptor', 'game_cover', false)
CreateLayer('game_notepart', 'game_receptor', false)
CreateLayer('game_ui', 'game_notepart', false)

NewAudio.CreateChannel('game_music')

local conductor = require '_base/conductor'
local measures = require '_base/notes/measures'
local notemanager = require '_base/notes/manager'
local loader = require '_base/loader'
local judgement = require '_base/notes/judgement'
local ui = require '_base/ui'
local easing = require 'easing'
local save = require '_base/save'
local playstate = require '_base/states/play'

notemanager.level = level
judgement.level = level
ui.level = level

level.gamecover = CreateSprite('black', 'game_cover')
level.gamecover.alpha = 0

level.overlay = CreateSprite('px', 'game_ui')
level.overlay.Scale(640,480)

level.gover = CreateSprite('_base/gover', 'game_ui')
level.gover.alpha = 0

level.finishtext = CreateText('[instant]Your rank is...', {0,0}, 640, 'game_ui')
level.finishtext.SetFont('monster')
level.finishtext.progressmode = 'none'
level.finishtext.color = {1,1,1}
level.finishtext.HideBubble()
level.finishtext.Scale(2,2)
level.finishtext.MoveTo(320-level.finishtext.GetTextWidth()*level.finishtext.xscale/2, 380)

level.rank = CreateText('[instant]S', {0,0}, 640, 'game_ui')
level.rank.SetFont('monster')
level.rank.progressmode = 'none'
level.rank.color = {1,1,1}
level.rank.HideBubble()
level.rank.Scale(16,16)
level.rank.MoveTo(320-level.rank.GetTextWidth()*level.rank.xscale/2, 240-level.rank.GetTextHeight()*level.rank.yscale/2)

level.belowrank = CreateText('[instant]Good job!', {0,0}, 640, 'game_ui')
level.belowrank.SetFont('monster')
level.belowrank.progressmode = 'none'
level.belowrank.color = {1,1,1}
level.belowrank.HideBubble()
level.belowrank.Scale(2,2)
level.belowrank.y = 80

level.lastbeat = 0

local STATE_PLAY = 0
local STATE_FINISH = 1
local STATE_BEFORERANK = 2
local STATE_FINISHRANK = 3
local STATE_DEATH = 4
local STATE_DEATHEXIT = 5

level.state = STATE_PLAY
level.statetimer = 0

level.savedrank = false
level.gottenrank = nil

level.hits = 0
level.misses = 0
level.total = 0
level.acc = 100
level.combo = 0
level.hp = 100

level.autoplay = false
level.mineexplos = false
level.useroffset = 0

level.difficulty = 'NORMAL' -- TODO: make this the difficulty you select in the options when that's implemented
level.difficulties = {
	{
		difficulty = 'VERY EASY',
		camel = 'Very Easy',
		hitwindows = {
			{'perfect', 0.5},
			{'great', 0.75},
			{'bad', 1}
		}
	},
	{
		difficulty = 'EASY',
		camel = 'Easy',
		hitwindows = {
			{'perfect', 0.2},
			{'great', 0.4},
			{'bad', 0.6}
		}
	},
	{
		difficulty = 'NORMAL',
		camel = 'Normal',
		hitwindows = {
			{'perfect', 0.1},
			{'great', 0.2},
			{'bad', 0.3}
		}
	},
	{
		difficulty = 'HARD',
		camel = 'Hard',
		hitwindows = {
			{'perfect', 0.075},
			{'great', 0.15},
			{'bad', 0.225}
		}
	}
}

level.chartname = ''

level.judgementproperties = {
	perfect = {hitweight = 1, miss = 0, heal = 4, combomult = 1/50},
	great = {hitweight = 1/3, miss = 0, heal = 2, combomult = 1/50},
	bad = {hitweight = 1/6, miss = 0, heal = -2, combomult = 1/50},
	miss = {hitweight = 0, miss = 1, heal = -4, combomult = 0}
}

level.hitwindows = { -- in a separate table so that we ensure we go through the hit windows in order: perfect > great > bad
	{'perfect', 0.1},
	{'great', 0.2},
	{'bad', 0.3}
}

level.grades = {
	{'S', 100, 'ffff00', 'shineselect', 'Outstanding performance!'}, -- grade, % accuracy needed, color, sound, text below grade
	{'A', 90, 'aaff00', 'coin', 'Really good play!'},
	{'B', 70, '2222ff', nil, 'Decent stepping.'},
	{'C', 40, 'ffaaff', 'awkward', 'Could\'ve been better.'},
	{'D', 0, 'ff7700', 'glassbreak', 'ouch'},
	{'F', 0, 'ff0000'} -- only given when you fail
}

function level.getrank()

	for _,g in ipairs(level.grades) do
		if level.acc >= g[2] then
			return g
		end
	end

end

function level.getrankcolor(rank)

	for _,g in ipairs(level.grades) do
		if g[1] == rank then
			return g[3], ('[color:' .. g[3] .. ']' .. rank)
		end
	end

end

function level.readsave()

	-- grabbing the difficulties (modular just in case)
	local difft = {}
	for _,d in ipairs(level.difficulties) do
		difft[#difft+1] = d.difficulty
	end

	local savet = save.getsave(difft)

	level.difficulty = savet.diff or level.difficulty
	level.autoplay = savet.autoplay or level.autoplay
	level.mineexplos = savet.boom or level.mineexplos
	level.useroffset = savet.offset or level.useroffset

end

function level.init()

	level.reset()

	ui.init()
	notemanager.reset()

	level.gover.SendToTop()
	level.overlay.SendToTop()

	level.rank.SendToTop()
	level.finishtext.SendToTop()
	level.belowrank.SendToTop()

	-- these two should act the same

	--[[
	level.rank.layer = 'BelowPlayer'
	level.rank.layer = 'game_ui'

	level.finishtext.layer = 'BelowPlayer'
	level.finishtext.layer = 'game_ui'

	level.belowrank.layer = 'BelowPlayer'
	level.belowrank.layer = 'game_ui'
	]]

	level.readsave()

end

function level.reset()

	level.gover.alpha = 0
	
	level.overlay.alpha = 0

	level.finishtext.alpha = 0
	level.rank.alpha = 0
	level.belowrank.alpha = 0

	level.rank.SetText('')

	level.state = STATE_PLAY
	level.statetimer = 0

	level.hits = 0
	level.misses = 0
	level.total = 0
	level.combo = 0

	level.hp = 100
	level.acc = 100

	level.savedrank = false
	level.gottenrank = {'F'}

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
	
	ui.judger.Set(spr)
	ui.judger.alpha = ui.alpha
	ui.judger.Scale(0.55,0.55)
	ui.judger['timer'] = 0

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
	ui.updatemiss()

	-- update accuracy
	if level.total > 0 then level.acc = level.hits/level.total*100
	else level.acc = 100
	end

	ui.updateacc()

	-- update hp
	local healcnt = level.judgementproperties[j].heal
	local combomult = level.judgementproperties[j].combomult

	level.hp = level.hp + healcnt + level.combo*combomult
	level.hp = math.max(math.min(level.hp, 100), 0) -- clamp 0-100

	ui.hpbar.easefill(level.hp/100)

	-- update combo
	ui.updatecombo()

	if level.hp <= 0 then -- dead.

		level.state = STATE_DEATH
		level.statetimer = 0

	end

end

function level.exit()

	NewAudio.Stop('game_music')

	level.reset()

	level.gamecover.alpha = 0
	ui.setalpha(0)
	ui.update() -- update one last time

	notemanager.reset()
	conductor.reset()

	playstate.exit()

	-- TODO: remove sprites, bullets and text created during chart

end

function level.finish()

	if level.state == STATE_PLAY then

		level.state = STATE_FINISH
		level.overlay.color = {0,0,0}

	end

end

function level.load(t)

	level.reset()

	level.chartname = t.chartname

	level.gamecover.alpha = 1
	level.gover.alpha = 0
	level.overlay.alpha = 0

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

		local new, i = notemanager.new{note.type, note.lineinmeasure, appeardur, note.row, note.measure, dist, note.holdendbeat}

		conductor.addevent(note.beat, appeardur, notemanager.create, new, i)

		level.lastbeat = math.max(level.lastbeat, note.holdendbeat or note.beat)

	end

	-- the song
	NewAudio.PlayMusic('game_music', '../' .. ChartPath .. '/' .. t.chartname .. '/main')
	NewAudio.Pause('game_music')

	conductor.addevent(0, t.songoffset + level.useroffset/1000, NewAudio.Unpause, 'game_music')

	-- finish
	conductor.addevent(level.lastbeat, -2, level.finish) -- negative offset because we want this to happen 2 seconds *later*!

	conductor.sortevents()
	conductor.start()

end

function level.update()

	if not conductor.playing then return end

	if Input.GetKey('F1') == 1 then -- TODO: change this into holding Esc for time
		level.exit()
		return
	end

	if level.state < STATE_DEATH then

		if ChartUpdate then ChartUpdate() end
		notemanager.update()
		ui.update()
		if ChartLateUpdate then ChartLateUpdate() end

		if level.state >= STATE_FINISH and level.state < STATE_DEATH then

			if not level.savedrank then
				level.gottenrank = level.getrank()
				if not level.autoplay then save.saverank(level.chartname, level.difficulty, level.gottenrank[1]) end

				level.savedrank = true
			end

			level.statetimer = level.statetimer + Time.dt
			local timer = level.statetimer

			level.overlay.alpha = 0.6

			if timer < 0.5 then
				level.overlay.alpha = easing.inSine(math.min(timer, 0.5), 0, 0.6, 0.5)
			elseif timer > 2 and level.state == STATE_FINISH then

				level.finishtext.alpha = 1
				level.state = STATE_BEFORERANK

			elseif timer > 4 and level.state == STATE_BEFORERANK then
				level.state = STATE_FINISHRANK

				local rank = level.gottenrank

				if rank[4] then Audio.PlaySound(rank[4]) end

				local str = '[instant]'..'[color:'..rank[3]..']'..rank[1]
				level.rank.alpha = 1
				level.rank.SetText(str)

				str = '[instant]' .. (rank[5] or '')
				level.belowrank.alpha = 1
				level.belowrank.SetText(str)
				level.belowrank.x = 320-level.belowrank.GetTextWidth()*level.belowrank.xscale/2

			elseif timer > 7 and level.state == STATE_FINISHRANK then

				level.exit()

			end

		end

	else

		if not level.savedrank then

			if not level.autoplay then save.saverank(level.chartname, level.difficulty, 'F') end
			level.savedrank = true

		end

		level.statetimer = level.statetimer + Time.dt
		local timer = level.statetimer

		level.overlay.color = {0,0,0}
		level.overlay.alpha = easing.linear(math.max(timer-2, 0), 0, 1, 2)

		NewAudio.Stop('game_music')

		if timer > 1/16 and level.state == STATE_DEATH then

			Audio.PlaySound('heartbeatbreaker')
			level.state = STATE_DEATHEXIT
			level.gover.alpha = 1

		elseif timer > 4.5 and level.state == STATE_DEATHEXIT then

			level.exit()

		end

	end

end

return level