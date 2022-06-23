-- stores all the sprites and such to avoid re-creating them for every menu

local resources = {}

local easing = require 'easing'

CreateLayer('menu_bg', 'menu_cover', false)
CreateLayer('menu_ui', 'menu_bg', false)

resources.heart = CreateSprite('ut-heart', 'menu_ui')
resources.heart.Scale(1.5, 1.5)
resources.heart.color = {1,0,0}
resources.heart.MoveTo(40, 341)
resources.heartTarget = 301

resources.heartSelected = 1

resources.paget = CreateText('[instant]Page 1', {10,10}, 640, 'menu_ui')
resources.paget.Scale(1.5,1.5)
resources.paget.y = 480 - 10 - resources.paget.GetTextHeight() * resources.paget.yscale
resources.paget.progressmode = 'none'
resources.paget.HideBubble()
resources.paget.color = {1,1,1,0}

resources.page = 1
resources.pagecnt = 1

resources.text = {}
local textprefix = '[instant][effect:none]'

for i=1,7 do

	local text = CreateText(textprefix, {70, 370 - i*40}, 9999, 'menu_ui')
	text.color = {1,1,1}
	text.HideBubble()
	text.progressmode = 'none'
	text.Scale(2,2)

	resources.text[i] = {text, ''}

end

do

	resources.steprune = CreateSprite('_base/menu/name', 'menu_ui')
	resources.steprune.Scale(2,2)
	resources.steprune.y = 420
	resources.steprune.alpha = 1

	resources.fountain = {}

	resources.fountain.fills = {}
	for i=1,2 do
		resources.fountain.fills[i] = CreateSprite('_base/menu/fountain', 'menu_bg')
		resources.fountain.fills[i]['dir'] = ((-1)^i)*4
		resources.fountain.fills[i].Scale(4,4)
		resources.fountain.fills[i].alpha = 0.5
		resources.fountain.fills[i].x = resources.fountain.fills[i].x + resources.fountain.fills[i]['dir']*3
	end

	resources.fountain.edges = {}
	for i=1,6 do
		resources.fountain.edges[i] = CreateSprite('_base/menu/fountain_outline', 'menu_bg')
		resources.fountain.edges[i]['dir'] = 0
		if i ~= 2 and i ~= 5 then
			resources.fountain.edges[i]['dir'] = (-1)^i
		end
		resources.fountain.edges[i].Scale(4,4)
		resources.fountain.edges[i].xscale = ((i<4) and -4) or 4
		resources.fountain.edges[i].alpha = 1
		resources.fountain.edges[i].color = {1/4,1/4,1/4}
	end

	resources.fountain.blackfillers = {}
	for i=1,2 do
		resources.fountain.blackfillers[i] = CreateSprite('px', 'menu_bg')
		resources.fountain.blackfillers[i].Scale((640-107)/2,480)
		resources.fountain.blackfillers[i].color = {0,0,0}
		resources.fountain.blackfillers[i].x = 320 + ((i-1)*2-1)*(33.5+40)*4
	end

end

resources.textColorInactive = {1,1,1}
resources.textColorActive = {1,1,0.6}

function resources.updatepage()
	resources.paget.SetText('[instant]Page ' .. resources.page .. '/' .. resources.pagecnt .. '\nPress Q and E to change!')
end

function resources.fittext()

	for _,t in ipairs(resources.text) do
		local this = t[1]

		this.xscale = 2

		local w = this.GetTextWidth()
		local m = math.max(w*this.xscale/500, 1)

		this.xscale = this.xscale/m

	end

end

-- code yoinked from https://github.com/EmmanuelOga/columns/blob/master/utils/color.lua
local function hsvToRgb(h, s, v, a)
  local r, g, b

  local i = math.floor(h * 6);
  local f = h * 6 - i;
  local p = v * (1 - s);
  local q = v * (1 - f * s);
  local t = v * (1 - (1 - f) * s);

  i = i % 6

  if i == 0 then r, g, b = v, t, p
  elseif i == 1 then r, g, b = q, v, p
  elseif i == 2 then r, g, b = p, v, t
  elseif i == 3 then r, g, b = p, q, v
  elseif i == 4 then r, g, b = t, p, v
  elseif i == 5 then r, g, b = v, p, q
  end

  return r * 255, g * 255, b * 255, a * 255
end

function resources.settext(t)

	for idx=1,7 do

		local text = tostring(t[idx] or '')

		resources.text[idx][1].SetText(textprefix .. text)
		resources.text[idx][2] = text

	end

	resources.fittext()

end

function resources.settextwithsuffix(t)

	for idx=1,7 do

		if t[idx] then

			local text = tostring(t[idx][1] or '')

			local final = textprefix .. text .. (t[idx][2] or '')

			resources.text[idx][1].SetText(final)
			resources.text[idx][2] = text

		end

	end

	resources.fittext()

end

function resources.setcolor(idx, col)

	if idx < 1 or idx > #resources.text then return end

	resources.text[idx][1].color = col

end

function resources.setselect(select, instant)

	select = math.min(math.max(select, 1), #resources.text)

	resources.setcolor(resources.heartSelected, resources.textColorInactive)
	resources.heartTarget = 381 - select*40
	resources.heartSelected = select
	resources.setcolor(resources.heartSelected, resources.textColorActive)

	if instant then resources.heart.y = resources.heartTarget end

end

function resources.trymove(dir)

	if resources.heartSelected + dir < 1 or resources.heartSelected + dir > #resources.text then return end

	local new = resources.heartSelected + dir

	if #resources.text[new][2] < 1 then return end

	Audio.PlaySound 'menumove'
	resources.setselect(new)

end

function resources.checkmove()

	if Input.Up == 1 then
		resources.trymove(-1)
	elseif Input.Down == 1 then
		resources.trymove(1)
	end

end

function resources.update(dontmove)

	if not dontmove then resources.checkmove() end
	resources.heart.y = easing.linear(1/5, resources.heart.y, resources.heartTarget - resources.heart.y, 1)

	for _,f in ipairs(resources.fountain.fills) do

		local spd = f['dir']*Time.dt*2

		f.x = f.x - spd
		f.y = f.y + spd
		f['timer'] = (f['timer'] or 0) + 1

		if f.x > 320+120*4 then
			f.x = f.x - 120*4
		elseif f.x < 320-120*4 then
			f.x = f.x + 120*4
		end

		if f.y + 240 > 240+480*4 then
			f.y = f.y - 480*4
		elseif f.y - 240 < 240-480*4 then
			f.y = f.y + 480*4
		end

		local r, g, b = hsvToRgb(f['timer']/2/255, 1, ((math.sin(f['timer']/64)*40)+60)/255,1)
		f.color32 = {
			r/3,
			g/3,
			b/3
		}

	end

	resources.steprune.x = math.sin(Time.time/2)*6+500
	resources.steprune.y = math.sin(Time.time/3 + math.pi*0.56)*4+420
	resources.steprune.rotation = math.sin(Time.time/1.2 - math.pi*0.4)*2

	for _,e in ipairs(resources.fountain.edges) do

		e.x = 320 - 33.5*e.xscale - math.abs(math.sin(Time.time/2))*7*e['dir']

		e['y'] = (e['y'] or e.y) - Time.dt/2

		if e['y'] < 240 - 474 then
			e['y'] = e['y'] + 474
		end

		e.y = math.floor(e['y'])
	end

end

return resources