-- stuff needed since this is cyf
encountertext = "if you see this something went horribly wrong."
nextwaves = {}
wavetimer = math.huge
arenasize = {155, 130}
enemies = {}
enemypositions = {}
noscalerotationbug = true
-- unescape = true -- TODO at the end: uncomment this

-- cover, also pretty much base layer for the game and menu
CreateLayer('menu_cover', 'Top', false)
CreateLayer('game_cover', 'menu_cover', false)
CreateSprite('black', 'menu_cover') -- lowest so we dont really care enough about it to store it in a variable

local function loadbase(name)
	return require('_base/'..name)
end

local statemanager = loadbase 'states/manager'
local reader = loadbase 'reader'
local conductor = loadbase 'conductor'
local level = loadbase 'level'
local ui = loadbase 'ui'

-- initialize
function EncounterStarting()

	ChartPath = 'Charts'

	NewAudio.CreateChannel('menu_music')
	NewAudio.PlayMusic('menu_music', 'menu', true)
	NewAudio.SetVolume('menu_music', 0.3)

	Audio.Stop()
	State 'NONE'
	
	level.init()

	conductor.reset()
	ui.reset()
	
	statemanager.init()

end

function Update()

	statemanager.update()
	conductor.update()
	level.update()

end

function OnHit() -- dont allow the player to take damage
end