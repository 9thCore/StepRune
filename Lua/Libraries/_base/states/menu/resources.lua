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

resources.textColorInactive = {1,1,1}
resources.textColorActive = {1,1,0.6}



function resources.settext(t)

	for idx=1,7 do

		local text = tostring(t[idx] or '')

		resources.text[idx][1].SetText(textprefix .. text)
		resources.text[idx][2] = text

	end

end

function resources.setcolor(idx, col)

	if idx < 1 or idx > #resources.text then return end

	resources.text[idx][1].color = col
	resources.text[idx][1].SetText(textprefix .. resources.text[idx][2])

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

	resources.setselect(new)

end

function resources.checkmove()

	if Input.Up == 1 then
		resources.trymove(-1)
	elseif Input.Down == 1 then
		resources.trymove(1)
	end

end

function resources.update()

	resources.checkmove()

	resources.heart.y = easing.linear(1/5, resources.heart.y, resources.heartTarget - resources.heart.y, 1)

end

return resources