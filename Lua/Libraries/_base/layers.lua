local lib = {}

local baselayers = {
	'Bottom',
	'BelowUI',
	'BelowArena',
	'BasisNewest',
	'BelowPlayer',
	'BelowBullet',
	'Top',
	'menu_cover',
	'menu_bg',
	'menu_ui',
	'game_cover',
	'Background',
	'game_receptor',
	'AboveReceptors',
	'game_ui',
	'AboveUI'
}

lib.baselayers = {}

for i=1,#baselayers do
	lib.baselayers[baselayers[i]] = true
end

lib.layers = {}

function lib.SetLayer(sprite, layer)
	if type(layer) == 'table' then layer = layer.name end

	if lib.layers[layer] then
		sprite.SetParent(lib.layers[layer].spr)
	else
		sprite.layer = layer
	end

end

function lib.NewBaseLayer(layer, last, position)
	local l = {}

	l.name = layer

	l.below = last or position

	l.spr = CreateSprite('empty', position, -1)
	l.spr.MoveTo(0,0)

	lib.layers[layer] = l
end

function lib.NewLayer(layer, position, below)

	if lib.layers[layer] then return false end
	if not layer then return false end

	local l = {}

	l.name = layer

	l.spr = CreateSprite('empty', 'Top', -1)
	l.spr.MoveTo(0,0)

	local existing = lib.layers[position]

	if existing then -- our custom layer exists

		if below then -- place layer below position
			lib.SetLayer(l.spr, existing.below)
			l.below = lib.layers[existing.below] or existing.below
			existing.below = layer
		else -- place layer above position
			lib.SetLayer(l.spr, existing.name)
			l.below = existing
		end

	else -- it doesnt :( so error

		below = not not below
		error('CreateLayer: Tried to make a new layer ' .. ((below and 'below') or 'above') .. ' the layer "' .. tostring(position) .. '", but it didn\'t exist.', 3)

	end

	lib.layers[layer] = l

	return true

end

-- creating the base layers
for i=0,#baselayers-1 do
	lib.NewBaseLayer(baselayers[i+1], baselayers[i], 'Top')
end

-- wrapping
local _oldcs = CreateSprite
function CreateSprite(spr, layer, chnr, a)

	if type(layer) == 'number' then
		chnr = layer
		layer = 'BasisNewest'
	end

	local s = _oldcs(spr, 'Top')
	lib.SetLayer(s, layer)
	return s

end

local _oldct = CreateText
function CreateText(text, pos, maxwidth, layer, height)

	local t = _oldct(text, pos, maxwidth, 'Top', height)
	lib.SetLayer(t, layer)
	return t

end

return lib