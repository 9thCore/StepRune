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
CreateSprite('black', 'menu_cover') -- lowest so we dont really care about it

local function loadbase(name)
	return require('_base/'..name)
end

local statemanager = loadbase 'states/manager'
local reader = loadbase 'reader'
local conductor = loadbase 'conductor'
local level = loadbase 'level'
local ui = loadbase 'ui'
local lockdown = loadbase 'lockdown'

local env

-- initialize
function EncounterStarting()

	ChartPath = 'Charts'

	Audio.Stop()
	State 'NONE'

	statemanager.init()
	level.init()
	conductor.reset()
	ui.reset()
	
	env = lockdown.getenv()

end

function Update()

	statemanager.update()
	conductor.update()
	level.update()

end

function OnHit() -- dont allow the player to take damage
end