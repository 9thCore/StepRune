local level = {}

CreateLayer('game_receptor', 'game_cover', false)
CreateLayer('game_ui', 'game_receptor', false)

NewAudio.CreateChannel('game_music')

local input = require '_base/input'
local conductor = require '_base/conductor'
local measures = require '_base/notes/measures'
local notemanager = require '_base/notes/manager'
local loader = require '_base/loader'
local judgement = require '_base/notes/judgement'
local ui = require '_base/ui'
local easing = require 'easing'
local save = require '_base/save'
local playstate = require '_base/states/play'
local lockdown = require '_base/lockdown'

lockdown.level = level
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

level.scrollspeed = 1

level.autoplay = false
level.mineexplos = false
level.useroffset = 0
level.quittime = 0.5

level.holdingtime = 0
level.quitting = CreateSprite('_base/quitting', 'game_ui')
level.quitting.SetPivot(0,1)
level.quitting.MoveTo(0,480)
level.quitting.alpha = 0

level.difficulty = 'NORMAL'
level.difficulties = {
	{
		difficulty = 'VERY EASY',
		name = 'Very Easy',
		hitwindows = {
			{'perfect', 0.5},
			{'great', 0.75},
			{'bad', 1}
		}
	},
	{
		difficulty = 'EASY',
		name = 'Easy',
		hitwindows = {
			{'perfect', 0.2},
			{'great', 0.4},
			{'bad', 0.6}
		}
	},
	{
		difficulty = 'NORMAL',
		name = 'Normal',
		hitwindows = {
			{'perfect', 0.1},
			{'great', 0.2},
			{'bad', 0.3}
		}
	},
	{
		difficulty = 'HARD',
		name = 'Hard',
		hitwindows = {
			{'perfect', 0.075},
			{'great', 0.15},
			{'bad', 0.225}
		}
	}
}

level.chartobjects = {} -- store objects created during the chart so we can remove them later
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

local ChartUpdate
local ChartLateUpdate

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
	level.quittime = savet.quittime or level.quittime

	local bindings = savet.bindings

	if bindings then
		input.keys.left = bindings.left or input.keys.left
		input.keys.right = bindings.right or input.keys.right
		input.keys.up = bindings.up or input.keys.up
		input.keys.down = bindings.down or input.keys.down
	end

end

function level.init()

	ui.init()

	level.reset()

	notemanager.reset()

	level.quitting.SendToTop()

	level.gover.SendToTop()
	level.overlay.SendToTop()

	level.rank.SendToTop()
	level.finishtext.SendToTop()
	level.belowrank.SendToTop()

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

	level.holdingtime = 0

	level.hits = 0
	level.misses = 0
	level.total = 0
	level.combo = 0

	level.hp = 100
	level.acc = 100

	level.scrollspeed = 1

	level.savedrank = false
	level.gottenrank = {'F'}

	ChartUpdate = nil
	ChartLateUpdate = nil

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
	ui.reset()

	level.quitting.alpha = 0

	level.gamecover.alpha = 0
	ui.setalpha(0)
	ui.update() -- update one last time

	notemanager.reset()
	conductor.reset()

	playstate.exit()

	for _,t in ipairs(level.chartobjects) do
		local v, vtype = t[1], t[2]
		if vtype == 'sprite' or vtype == 'bullet' then
			v.Remove()
		end
	end

	collectgarbage('collect') -- no idea if this actually does anything but :samuraisword:

end

function level.finish()

	if level.state == STATE_PLAY then

		level.state = STATE_FINISH
		level.overlay.color = {0,0,0}

	end

end

function level.getscrolltime()
	return (3 / level.scrollspeed)
end

function level.load(t)

	-- reset stuff
	level.reset()

	level.gamecover.alpha = 1
	level.gover.alpha = 0
	level.overlay.alpha = 0

	notemanager.reset()
	ui.load()
	measures.reset()
	conductor.reset()

	notemanager.init()


	level.chartname = t.chartname

	-- schedule events

	-- bpms
	conductor.setbpms(t.bpms)

	-- the song
	NewAudio.PlayMusic('game_music', '../' .. ChartPath .. '/' .. t.chartname .. '/main') -- load song when chart loads
	NewAudio.Pause('game_music')

	conductor.addevent(0, t.songoffset + level.useroffset/1000, NewAudio.Unpause, 'game_music') -- unpause it when needed
		
	-- notes
	for _,note in ipairs(t.notes) do
		measures.set(note.measure, note.measurelinecount)

		local dur = level.getscrolltime()
		local dist = 240

		local new, i = notemanager.new{note.type, dur, note.lineinmeasure, note.row, note.measure, dist, note.holdendbeat}

		conductor.addevent(note.beat, dur, notemanager.create, new, i)

		level.lastbeat = math.max(level.lastbeat, note.holdendbeat or note.beat)

	end

	-- finish
	conductor.addevent(level.lastbeat, -2, level.finish) -- negative offset because we want this to happen 2 seconds *later*!

	-- start conductor
	conductor.sortevents()
	conductor.start()


	-- try to load chart's lua file
	local luapath = ChartPath..'/'..t.chartname..'/main.lua'

	if Misc.FileExists(luapath) then

		local env = lockdown.getenv(level.chartobjects, {
			Update = {
				set = function(t)
					ChartUpdate = t.Update
				end,
				get = function()
					return ChartUpdate
				end
			},
			LateUpdate = {
				set = function(t)
					ChartLateUpdate = t.LateUpdate
				end,
				get = function()
					return ChartLateUpdate
				end
			}
		})

		local f = loadfile('../'..luapath, nil, env)
		f()

	end

end

function level.update()

	if not conductor.playing then return end

	if level.state == STATE_PLAY then

		if Input.GetKey('Escape') > 0 then

			level.holdingtime = level.holdingtime + Time.dt
			level.quitting.alpha = easing.linear(level.holdingtime, 0, 2, level.quittime)

			if level.holdingtime > level.quittime then

				level.exit()
				return

			end

		else

			level.holdingtime = 0
			level.quitting.alpha = 0

		end

	else

		level.holdingtime = 0
		level.quitting.alpha = 0

	end

	if level.state < STATE_DEATH then

		if type(ChartUpdate) == 'function' then ChartUpdate() end
		notemanager.update()
		ui.update()
		if type(ChartLateUpdate) == 'function' then ChartLateUpdate() end

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

function level.getobject()

	local obj = {}

	function obj.SetHP(newhp)
		level.hp = math.min(math.max(newhp, 1), 100)
		ui.hpbar.easefill(level.hp/100)
	end
	function obj.GetHP()
		return level.hp
	end

	function obj.GetHits()
		return level.hits
	end
	function obj.GetMisses()
		return level.misses
	end
	function obj.GetAcc()
		return level.acc
	end
	function obj.GetCombo()
		return level.combo
	end
	function obj.GetGrade()
		return level.getrank()
	end
	function obj.GetHitWindows()
		return { -- make a new table so as to avoid being able to overwrite the real one
			{'perfect', level.hitwindows[1][2]},
			{'great', level.hitwindows[2][2]},
			{'bad', level.hitwindows[3][2]}
		}
	end
	function obj.GetDifficulty()
		for _,d in ipairs(level.difficulties) do
			if d.difficulty == level.difficulty then
				return {
					difficulty = d.difficulty,
					name = d.name,
					hitwindows = {
						{'perfect', d.hitwindows[1][2]},
						{'great', d.hitwindows[2][2]},
						{'bad', d.hitwindows[3][2]}
					}
				}
			end
		end
	end
	function obj.SetScrollSpeed(val)
		level.scrollspeed = val
	end

	return obj

end

return level