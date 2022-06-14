-- stuff needed since this is cyf
encountertext = "if you see this something went horribly wrong."
nextwaves = {}
wavetimer = math.huge
arenasize = {155, 130}
enemies = {}
enemypositions = {}

-- cover, also pretty much base layer for the game and menu
CreateLayer('menu_cover', 'Top', false)
CreateLayer('game_cover', 'menu_cover', false)
CreateSprite('black', 'menu_cover') -- lowest so we dont care about it

local function loadbase(name)
	return require('_base/'..name)
end

local statemanager = loadbase 'states/manager'
local reader = loadbase 'reader'
local conductor = loadbase 'conductor'
local level = loadbase 'level'

-- initialize
function EncounterStarting()

	ChartPath = 'Charts'

	Audio.Stop()
	State 'NONE'

	statemanager.init()
	reader.init()
	level.init()
	conductor.reset()

	ChartPath = nil
	Misc = nil

	EncounterStarting = nil -- lmao
	-- cant re-initialize after the initialization :)
end

function Update()

	statemanager.update()
	conductor.update()
	level.update()

end