local play = {}

local resources = require '_base/states/menu/resources'
local reader = require '_base/reader'
local save = require '_base/save'
local level = require '_base/level'
local save = require '_base/save'
local ui = require '_base/ui'

local totalcnt = 0

local function getlist(offset)

	local t = {{'Back', ''}}

	local folders = Misc.ListDir(ChartPath, true)

	totalcnt = #folders
	resources.pagecnt = math.max(math.ceil(totalcnt / 6), 1)

	for i=1,6 do

		local file = folders[i+offset]

		file = file or ''

		local rank = save.getrank(file, level.difficulty)
		if rank then
			local color, coloredrank = level.getrankcolor(rank)
			rank = coloredrank
		end

		t[#t+1] = {file, ' ' .. (rank or '')}

	end

	return t

end

local function nextpage(dir)

	if resources.page + dir < 1 or resources.page + dir > resources.pagecnt then return end

	resources.page = resources.page + dir
	resources.settextwithsuffix(getlist((resources.page-1)*6))

	while #resources.text[resources.heartSelected][2] < 1 do
		resources.setselect(resources.heartSelected-1)
	end

	resources.updatepage()

	Audio.PlaySound('menumove')

end

function play.init()

	resources.paget.alpha = 1

	ui.diff.alpha = 1
	if level.autoplay then ui.autoplay.alpha = 1 ui.autoplay.SetText('[instant]AUTOPLAY ON') end
	ui.updatediff()
	ui.setoffset(0,0)

	resources.settextwithsuffix(getlist(0))
	resources.setselect(1, true)

	resources.updatepage()

end

function play.update(setstate)

	if Input.GetKey('Escape') == 1 then
		Audio.PlaySound('menuconfirm')
		setstate(1)
		return
	end

	if Input.GetKey('Q') == 1 then
		nextpage(-1)
	elseif Input.GetKey('E') == 1 then
		nextpage(1)
	end

	if Input.Confirm == 1 then

		Audio.PlaySound 'menuconfirm'

		if resources.heartSelected == 1 then
			setstate(1)
		else

			local path = ChartPath .. '/' .. resources.text[resources.heartSelected][2]

			if not Misc.DirExists(path) then
				NewAudio.PlayMusic('menu_music', 'danceofdog', true, 0.5)
				error('error while loading\n\nUh oh, an error was encountered while loading this chart!\n\nThe chart could not be found! Are you sure it\'s still in the Charts folder?', -1)
			end

			local res, err = pcall(reader.load, path, setstate)

			if not res then

				NewAudio.PlayMusic('menu_music', 'danceofdog', true, 0.25)
				error('error while loading\n\nUh oh, an error was encountered while loading this chart!\n\nIf you\'re sure you did everything right, send this to 9thCore to investigate!\n\n' .. err, -1)

			end

		end

	end
	
	resources.update()

end

return play