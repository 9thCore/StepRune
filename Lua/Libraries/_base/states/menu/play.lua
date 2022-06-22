local play = {}

local resources = require '_base/states/menu/resources'
local reader = require '_base/reader'
local save = require '_base/save'
local level = require '_base/level'
local save = require '_base/save'
local ui = require '_base/ui'

local totalcnt = 0
local page = 1
local pagecnt = 0

local paget = CreateText('[instant]Page 1', {10,10}, 640, 'game_ui')
paget.Scale(1.5,1.5)
paget.progressmode = 'none'
paget.HideBubble()
paget.color = {1,1,1,0}

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

local function updatepage()
	paget.SetText('[instant]Page '..page..'/'..pagecnt)
end

local function nextpage(dir)

	if page + dir < 1 or page + dir > pagecnt then return end

	page = page + dir
	resources.settextwithsuffix(getlist((page-1)*6))

	while #resources.text[resources.heartSelected][2] < 1 do
		resources.setselect(resources.heartSelected-1)
	end

	updatepage()

	Audio.PlaySound('menumove')

end

function play.init()

	paget.alpha = 1

	ui.diff.alpha = 1
	if level.autoplay then ui.autoplay.alpha = 1 ui.autoplay.SetText('[instant]AUTOPLAY ON') end
	ui.updatediff()
	ui.setoffset(0,0)

	resources.settextwithsuffix(getlist(0))
	resources.setselect(1, true)

	updatepage()

end

function play.update(setstate)

	if Input.GetKey('Escape') == 1 then
		Audio.PlaySound('menuconfirm')
		setstate(1)
		paget.alpha = 0
		return
	end

	if Input.Left == 1 then
		nextpage(-1)
	elseif Input.Right == 1 then
		nextpage(1)
	end

	if Input.Confirm == 1 then

		Audio.PlaySound 'menuconfirm'

		if resources.heartSelected == 1 then
			setstate(1)
			paget.alpha = 0
		else

			local path = ChartPath .. '/' .. resources.text[resources.heartSelected][2]

			if not Misc.DirExists(path) then
				NewAudio.PlayMusic('menu_music', 'danceofdog', true, 0.5)
				error('error while loading\n\nUh oh, an error was encountered while loading this chart!\n\nThe chart could not be found! Are you sure it\'s still in the Charts folder?', -1)
			end

			local res, err = pcall(reader.load, path, setstate)

			if not res then
				if err:find('_base') then
					NewAudio.PlayMusic('menu_music', 'danceofdog', true, 0.25)
					error('internal error!\n\nUh oh, an internal error was encountered while loading this chart!\n\nSend this to 9thCore to investigate!\n\n' .. err, -1)
				else
					NewAudio.PlayMusic('menu_music', 'danceofdog', true, 0.25)
					error('error while loading\n\nUh oh, an error was encountered while loading this chart!\n\n' .. err, -1)
				end
			else
				paget.alpha = 0
			end

		end

	end
	
	resources.update()

end

return play