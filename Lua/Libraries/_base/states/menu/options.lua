local options = {}

local resources = require '_base/states/menu/resources'
local level = require '_base/level'
local save = require '_base/save'

local diff = 'NORMAL'
local diffi = 1
local diffs

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
	diff = function()

		local base = 'Your desired difficulty. Higher difficulty gives a lower hit window for notes while a lower difficulty raises it.\n%s gives %.3fs for a [color:38BEFF]PERFECT[color], %.3fs for a [color:DBC517]GREAT[color] and %.3fs for a [color:FF3F44]BAD[color].\nNote that grades are different between difficulties.'
		local final = string.format(base, diff, diffs[diffi].hitwindows[1][2], diffs[diffi].hitwindows[2][2], diffs[diffi].hitwindows[3][2])

		explain.set(final)

	end,
	autoplay = function()

		local str = 'Whether the mod should play for you.\n[color:ff0000]You will not get a grade if you use this![color]\nAutoplay is currently %s.'
		local final = string.format(str, (level.autoplay and 'on') or 'off')

		explain.set(final)

	end

}

local settext
settext = {
	autoplay = function()

		local str = '[instant]Autoplay [' .. ((level.autoplay and 'ON') or 'OFF') .. ']'

		resources.text[3][1].SetText(str)
		resources.text[3][2] = str

	end,
	diff = function()

		local diffCamel = diffs[diffi].camel
		local full = '[instant]Difficulty [' .. diffCamel .. ']'

		resources.text[2][1].SetText(full)
		resources.text[2][2] = full

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

	grabdiffs()
	settext.diff()

	settext.autoplay()

	explainer.alpha = 1

end

function options.update(setstate)
		
	local lastpos = resources.heartSelected
	resources.update()

	if lastpos ~= resources.heartSelected then
		explain.set('')

		if resources.heartSelected == 2 then
			explain.diff()
		elseif resources.heartSelected == 3 then
			explain.autoplay()
		end
	end

	if Input.Confirm == 1 then

		if resources.heartSelected == 1 then -- Back

			exit(setstate)

		elseif resources.heartSelected == 2 then -- Difficulty

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

		elseif resources.heartSelected == 3 then

			level.autoplay = not level.autoplay

			settext.autoplay()
			explain.autoplay()

			save.var(save.autoplayname, level.autoplay)

			Audio.PlaySound('menuconfirm')

		end

	end

end

return options