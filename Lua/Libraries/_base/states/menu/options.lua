local options = {}

local resources = require '_base/states/menu/resources'
local level = require '_base/level'
local save = require '_base/save'
local input = require '_base/input'

local diff = 'NORMAL'
local diffi = 1
local diffs

local numholdtime = 0

local explainer = CreateText('', {0,0}, 640, 'menu_ui')
explainer.progressmode = 'none'
explainer.HideBubble()
explainer.color = {1,1,1,0}

local optionstate = 0
-- 0: normal options
-- 1: rebinding

local keys = {
	'left', 'down', 'up', 'right'
}
local alreadybound = {}

local rebindkey = 1

local rebindoverlay = CreateSprite('px', 'menu_ui')
rebindoverlay.Scale(640,480)
rebindoverlay.color = {0,0,0,0}

local rebindprogress = CreateText('', {0,0}, 640, 'menu_ui')
rebindprogress.Scale(2,2)
rebindprogress.progressmode = 'none'
rebindprogress.HideBubble()
rebindprogress.color = {1,1,1,0}
rebindprogress.y = 420

local rebindwhatkey = CreateText('', {0,0}, 640, 'menu_ui')
rebindwhatkey.Scale(4,4)
rebindwhatkey.progressmode = 'none'
rebindwhatkey.HideBubble()
rebindwhatkey.color = {1,1,1,0}

local rebindstatus = CreateText('', {0,0}, 640, 'menu_ui')
rebindstatus.Scale(2,2)
rebindstatus.progressmode = 'none'
rebindstatus.HideBubble()
rebindstatus.y = 60
rebindstatus.color = {0,0,0,0}

local function explain(text)

	explainer.SetText('[instant]'..text)

	local w = explainer.GetTextWidth()
	local h = explainer.GetTextHeight()

	explainer.x = 320 - w/2
	explainer.y = h-8

end

local function settext(idx, str)
	str = '[instant]' .. str
	resources.text[idx][1].SetText(str)
	resources.text[idx][2] = str
end

local function stoprebind()

	optionstate = 0

	rebindoverlay.alpha = 0
	rebindprogress.alpha = 0
	rebindwhatkey.alpha = 0

	alreadybound = {}

end

local function nextrebindkey()

	rebindkey = rebindkey + 1
	local cnt = #keys

	if rebindkey > cnt then
		stoprebind()
	else

		local key = keys[rebindkey]

		rebindprogress.SetText('[instant]Progress: ' .. math.floor((rebindkey-1)/cnt*100) .. '%')
		rebindprogress.x = 320 - rebindprogress.GetTextWidth()*rebindprogress.xscale/2

		rebindwhatkey.SetText('[instant]Key: ' .. key:upper())
		rebindwhatkey.x = 320 - rebindwhatkey.GetTextWidth()*rebindwhatkey.xscale/2
		rebindwhatkey.y = 240 - rebindwhatkey.GetTextHeight()*rebindwhatkey.yscale/2

	end

end

local function rebindtext(col, str)

	rebindstatus.color = col

	rebindstatus.SetText('[instant]' .. str)

	rebindstatus.xscale = math.max(1, 640/rebindstatus.GetTextWidth())

	rebindstatus.x = 320 - rebindstatus.GetTextWidth()*rebindstatus.xscale/2
	rebindstatus.alpha = 1

end

local optiont = {
	{ -- rebind
		text = function(idx)
			settext(idx, 'Rebind Controls [' .. input.keys.left .. input.keys.down .. input.keys.up .. input.keys.right .. ']')
		end,
		interact = function()

			Audio.PlaySound 'menuconfirm'

			rebindoverlay.alpha = 0.75
			rebindprogress.alpha = 1
			rebindwhatkey.alpha = 1

			optionstate = 1
			rebindkey = 0
			nextrebindkey()

		end,
		explain = function()
			explain 'Press to reconfigure controls!'
		end,
		type = 'button'
	},
	{ -- offset
		text = function(idx)
			settext(idx, 'Offset <' .. level.useroffset .. '>')
		end,
		interact = function(change)

			Audio.PlaySound 'menumove'

			if Input.Cancel > 0 then
				change = change * 10
			end
			
			level.useroffset = level.useroffset + change

			save.var(save.offsetname, level.useroffset)

		end,
		explain = function()
			explain 'Additional offset to apply to the song, in ms.\nChange this if the notes and song don\'t seem to sync up.\nLower offset makes the song start later while higher offset makes the song start earlier.\nHold CANCEL to change by 10 instead of 1.'
		end,
		type = 'number'
	},
	{ -- difficulty
		text = function(idx)
			local diffname = diffs[diffi].name
			settext(idx, 'Difficulty <' .. diffname .. '>')
		end,
		interact = function(change)

			Audio.PlaySound 'menumove'

			diffi = diffi + change

			if diffi > #diffs then
				diffi = 1
			end
			if diffi < 1 then
				diffi = #diffs
			end

			diff = diffs[diffi].difficulty

			level.difficulty = diff
			level.hitwindows = diffs[diffi].hitwindows

			save.var(save.diffname, level.difficulty)

		end,
		explain = function()

			local base = 'Your desired difficulty. Higher difficulty gives a lower hit window for notes while a lower difficulty raises it.\n%s gives %.3fs for a [color:38BEFF]PERFECT[color], %.3fs for a [color:DBC517]GREAT[color] and %.3fs for a [color:FF3F44]BAD[color].\nNote that grades are different between difficulties.'
			local final = string.format(base, diff, diffs[diffi].hitwindows[1][2], diffs[diffi].hitwindows[2][2], diffs[diffi].hitwindows[3][2])

			explain(final)

		end,
		type = 'number'
	},
	{ -- autoplay
		text = function(idx)
			settext(idx, 'Autoplay <' .. ((level.autoplay and 'ON') or 'OFF') .. '>')
		end,
		interact = function(change)

			Audio.PlaySound 'menumove'

			level.autoplay = not level.autoplay

			save.var(save.autoplayname, level.autoplay)

		end,
		explain = function()

			explain 'Whether the mod should play for you.\n[color:ff0000]You will not get a grade if you use this![color]'

		end,
		type = 'number'
	},
	{ -- mine explosions
		text = function(idx)
			settext(idx, 'Mine explosions <' .. ((level.mineexplos and 'ON') or 'OFF') .. '>')
		end,
		interact = function(change)

			Audio.PlaySound 'menumove'

			level.mineexplos = not level.mineexplos

			save.var(save.boomname, level.mineexplos)

		end,
		explain = function()

			explain 'Whether an explosion should be created when a mine is hit.\nShould probably leave this off.'

		end,
		type = 'number'
	},
	{ -- quit time
		text = function(idx)
			settext(idx, 'Quit time <' .. level.quittime .. '>')
		end,
		interact = function(change)

			if Input.Cancel < 1 then
				change = change * 0.1
			end

			Audio.PlaySound 'menumove'

			level.quittime = level.quittime + change

			save.var(save.quittimename, level.quittime)

		end,
		explain = function()

			explain 'How long to hold ESCAPE while playing to exit, in seconds.\nHold CANCEL to change by 1 instead of 0.1.'

		end,
		type = 'number'
	}
}

local function exit(ss)

	ss(1)

	explainer.alpha = 0
	rebindstatus.alpha = 0

	stoprebind()

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

local function graboptions(offset)

	resources.settext{'Back'}

	for i=1,5 do
		local idx = i + offset
		local opt = optiont[idx]

		if not opt then return end

		opt.text(i+1)

	end

end

local function getoption(idx)
	if idx < 2 then return nil end
	return optiont[idx - 1 + (resources.page-1)*5]
end

local function turnpage(dir)

	local new = resources.page + dir

	if new < 1 or new > resources.pagecnt then return end

	resources.page = new
	resources.updatepage()

	graboptions((resources.page-1)*5)

	while #resources.text[resources.heartSelected][2] < 1 do
		resources.setselect(resources.heartSelected-1)
	end

	local opt = getoption(resources.heartSelected)
	if opt then
		opt.text(resources.heartSelected)
		opt.explain()
	end

	Audio.PlaySound 'menumove'

end

function options.init()

	resources.setselect(1)

	resources.settext{
		'Back'
	}

	grabdiffs()

	graboptions(0)

	resources.pagecnt = math.max(1, math.ceil(#optiont/5))

	resources.updatepage()

	explainer.alpha = 1
	resources.paget.alpha = 1

end

function options.update(setstate)

	rebindstatus.alpha = rebindstatus.alpha - Time.dt/2

	if optionstate == 0 then

		if Input.GetKey('Escape') == 1 or (Input.Confirm == 1 and resources.heartSelected == 1) then
			Audio.PlaySound 'menuconfirm'
			exit(setstate)
			return
		end

		if Input.GetKey('Q') == 1 then
			turnpage(-1)
		elseif Input.GetKey('E') == 1 then
			turnpage(1)
		end
		
		-- explainer
		local lastpos = resources.heartSelected
		resources.update()

		local opt = getoption(resources.heartSelected)

		if lastpos ~= resources.heartSelected then
			explain ''

			if opt then
				opt.explain()
			end

		end

		-- input
		if Input.Confirm == 1 then

			if opt then
				if opt.type == 'button' then
					opt.interact()
					opt.text(resources.heartSelected)
					opt.explain()
				end
			end

		end

		if Input.Left > 0 or Input.Right > 0 then
			numholdtime = numholdtime + 1
		else
			numholdtime = 0
		end

		if opt then
			if opt.type == 'number' then

				local pl = Input.Left == 1
				if (numholdtime > 15 and numholdtime % 5 == 0) and Input.Left > 0 then
					pl = true
				end

				local pr = Input.Right == 1
				if (numholdtime > 15 and numholdtime % 5 == 0) and Input.Right > 0 then
					pr = true
				end

				if pl then
					opt.interact(-1)
					opt.text(resources.heartSelected)
					opt.explain()
				elseif pr then
					opt.interact(1)
					opt.text(resources.heartSelected)
					opt.explain()
				end

			end

		end

	elseif optionstate == 1 then

		if Input.GetKey('Escape') == 1 then
			Audio.PlaySound 'menuconfirm'
			stoprebind()
			return
		end

		resources.update(true)

		local possiblekeys = {
			'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'
		}

		for _,k in ipairs(possiblekeys) do

			if Input.GetKey(k) == 1 then

				if alreadybound[k] then

					Audio.PlaySound 'cantselect'
					rebindtext({1,0,0}, 'Already bound the key \'' .. k ..'\' to \'' .. alreadybound[k] .. '\'!')

				else

					alreadybound[k] = keys[rebindkey]:upper()

					Audio.PlaySound('shineselect', 0.3)
					rebindtext({0,1,0}, 'Successfully bound the key \'' .. k ..'\' to \'' .. alreadybound[k] .. '\'!')

					save.var(save.bindname .. alreadybound[k], k)
					input.keys[alreadybound[k]:lower()] = k

					local opt = getoption(resources.heartSelected)
					if opt then
						opt.text(resources.heartSelected)
					end

					nextrebindkey()

				end

			end

		end

	end

end

return options