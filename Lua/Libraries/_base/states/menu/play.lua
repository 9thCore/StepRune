local play = {}

local resources = require '_base/states/menu/resources'
local reader = require '_base/reader'
local save = require '_base/save'
local level = require '_base/level'
local save = require '_base/save'

local totalcnt = 0
local page = 1
local pagecnt = 0

local function getlist(offset)

	local t = {{'Back', ''}}

	local folders = Misc.ListDir(ChartPath, true)

	totalcnt = #folders
	pagecnt = math.ceil(totalcnt / 6)

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

	if page + dir < 1 or page + dir > pagecnt then return end

	page = page + dir
	resources.settextwithsuffix(getlist((page-1)*6))

	while #resources.text[resources.heartSelected][2] < 1 do
		resources.setselect(resources.heartSelected-1)
	end

	Audio.PlaySound('menumove')

end

function play.init()

	resources.settextwithsuffix(getlist(0))
	resources.setselect(1, true)

end

function play.update(setstate)
	
	resources.update()

	if Input.Left == 1 then
		nextpage(-1)
	elseif Input.Right == 1 then
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
				error('error while reading\n\nUh oh, an error was encountered while trying to read this chart!\n\n- The chart could not be found! Are you sure it\'s still in the Charts folder?', -1)
			end

			local res, err = pcall(reader.load, path, setstate)

			if not res then
				NewAudio.PlayMusic('menu_music', 'danceofdog', true, 0.5)
				error('error while reading\n\nUh oh, an error was encountered while trying to read this chart!\n\n- ' .. err, -1)
			end

		end

	end

end

return play