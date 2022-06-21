local options = {}

local resources = require '_base/states/menu/resources'
local level = require '_base/level'
local save = require '_base/save'

local diff = 'NORMAL'
local diffi = 1
local diffs

local numholdtime = 0

local explainer = CreateText('', {0,0}, 640, 'menu_ui')
explainer.progressmode = 'none'
explainer.HideBubble()
explainer.color = {1,1,1,0}

local explain
explain = {
	set = function(text)

		explainer.SetText('[instant]'..text)

		local w = explainer.GetTextWidth()
		local h = explainer.GetTextHeight()

		explainer.x = 320 - w/2
		explainer.y = h-8

	end,
	offset = function()

		local final = 'Additional offset to apply to the song, in ms.\nChange this if the notes and song don\'t seem to sync up.\nLower offset makes the song start later while higher offset makes the song start earlier.\nHold CANCEL to change by 10 instead of 1.'
		explain.set(final)

	end,
	diff = function()

		local base = 'Your desired difficulty. Higher difficulty gives a lower hit window for notes while a lower difficulty raises it.\n%s gives %.3fs for a [color:38BEFF]PERFECT[color], %.3fs for a [color:DBC517]GREAT[color] and %.3fs for a [color:FF3F44]BAD[color].\nNote that grades are different between difficulties.'
		local final = string.format(base, diff, diffs[diffi].hitwindows[1][2], diffs[diffi].hitwindows[2][2], diffs[diffi].hitwindows[3][2])

		explain.set(final)

	end,
	autoplay = function()

		local final = 'Whether the mod should play for you.\n[color:ff0000]You will not get a grade if you use this![color]'
		explain.set(final)

	end,
	mineexplo = function()

		local final = 'Whether an explosion should be created when a mine is hit.\nShould probably leave this off.'
		explain.set(final)

	end,
	quittime = function()

		local final = 'How long to hold ESCAPE while playing to exit, in seconds.\nHold CANCEL to change by 1 instead of 0.1.'
		explain.set(final)

	end

}

local settext
settext = {
	set = function(idx, str)
		resources.text[idx][1].SetText(str)
		resources.text[idx][2] = str
	end,
	offset = function()

		local str = '[instant]Offset <' .. tostring(level.useroffset) .. '>'
		settext.set(2, str)

	end,
	diff = function()

		local diffCamel = diffs[diffi].camel
		local full = '[instant]Difficulty [' .. diffCamel .. ']'
		settext.set(3, full)

	end,
	autoplay = function()

		local str = '[instant]Autoplay [' .. ((level.autoplay and 'ON') or 'OFF') .. ']'
		settext.set(4, str)

	end,
	mineexplo = function()

		local str = '[instant]Mine explosions [' .. ((level.mineexplos and 'ON') or 'OFF') .. ']'
		settext.set(5, str)

	end,
	quittime = function()

		local str = '[instant]Quit time <' .. level.quittime .. '>'
		settext.set(6, str)

	end

}

local function exit(ss)
	ss(1)
	Audio.PlaySound('menuconfirm')
	explainer.alpha = 0
end

local function grabdiffs()

	for i,d in ipairs(level.difficulties) do
		if d.difficulty == level.difficulty then
			diff = d.difficulty
			diffi = i
		end
	end

	diffs = level.difficulties

end

function options.init()

	resources.setselect(1)

	resources.settext{
		'Back'
	}

	settext.offset()

	grabdiffs()
	settext.diff()

	settext.autoplay()

	settext.mineexplo()

	settext.quittime()

	explainer.alpha = 1

end

function options.update(setstate)

	if Input.GetKey('Escape') == 1 then
		Audio.PlaySound('menuconfirm')
		setstate(1)
		return
	end
		
	local lastpos = resources.heartSelected
	resources.update()

	if lastpos ~= resources.heartSelected then
		explain.set('')

		if resources.heartSelected == 2 then
			explain.offset()
		elseif resources.heartSelected == 3 then
			explain.diff()
		elseif resources.heartSelected == 4 then
			explain.autoplay()
		elseif resources.heartSelected == 5 then
			explain.mineexplo()
		elseif resources.heartSelected == 6 then
			explain.quittime()
		end
	end

	if Input.Left > 0 or Input.Right > 0 then
		numholdtime = numholdtime + 1
	else
		numholdtime = 0
	end

	if Input.Confirm == 1 then

		if resources.heartSelected == 1 then -- Back

			exit(setstate)

		elseif resources.heartSelected == 3 then -- Difficulty

			diffi = diffi + 1
			if diffi > #diffs then
				diffi = 1
			end
			diff = diffs[diffi].difficulty

			settext.diff()

			level.difficulty = diff
			level.hitwindows = diffs[diffi].hitwindows

			save.var(save.diffname, diff)

			explain.diff()

			Audio.PlaySound('menuconfirm')

		elseif resources.heartSelected == 4 then -- Autoplay

			level.autoplay = not level.autoplay

			settext.autoplay()
			explain.autoplay()

			save.var(save.autoplayname, level.autoplay)

			Audio.PlaySound('menuconfirm')

		elseif resources.heartSelected == 5 then -- Mine explosions

			level.mineexplos = not level.mineexplos

			settext.mineexplo()
			explain.mineexplo()

			save.var(save.boomname, level.mineexplos)

			Audio.PlaySound('menuconfirm')

		end

	end

	if resources.heartSelected == 2 then

		local change = 1
		if Input.Cancel > 0 then
			change = 10
		end

		local pl = Input.Left == 1
		if (numholdtime > 15 and numholdtime % 5 == 0) and Input.Left > 0 then
			pl = true
		end

		local pr = Input.Right == 1
		if (numholdtime > 15 and numholdtime % 5 == 0) and Input.Right > 0 then
			pr = true
		end

		if pl then
			level.useroffset = level.useroffset - change
		elseif pr then
			level.useroffset = level.useroffset + change
		end

		if pl or pr then
			settext.offset()
			Audio.PlaySound('menumove')

			save.var(save.offsetname, level.useroffset)
		end

	elseif resources.heartSelected == 6 then

		local change = 0.1
		if Input.Cancel > 0 then
			change = 1
		end

		local pl = Input.Left == 1
		if (numholdtime > 15 and numholdtime % 5 == 0) and Input.Left > 0 then
			pl = true
		end

		local pr = Input.Right == 1
		if (numholdtime > 15 and numholdtime % 5 == 0) and Input.Right > 0 then
			pr = true
		end

		if pl then
			level.quittime = math.max(level.quittime - change, 0.1)
		elseif pr then
			level.quittime = math.min(level.quittime + change, 10)
		end

		if pl or pr then
			settext.quittime()
			Audio.PlaySound('menumove')

			save.var(save.quittimename, level.quittime)
		end

	end

end

return options