-- stuff needed since this is cyf
encountertext = "if you see this something went horribly wrong."
nextwaves = {}
wavetimer = math.huge
arenasize = {155, 130}
enemies = {}
enemypositions = {}
noscalerotationbug = true
-- unescape = true -- TODO at the end: uncomment this

local layers = require '_base/layers'
local statemanager = require '_base/states/manager'
local reader = require '_base/reader'
local conductor = require '_base/conductor'
local level = require '_base/level'
local ui = require '_base/ui'
local lockdown = require '_base/lockdown'
lockdown.populate()

CreateSprite('black', 'menu_cover') -- lowest so we dont really care enough about it to store it in a variable

math.randomseed(os.clock())

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