local ui = {}

local easing = require 'easing'

function ui.init()

	ui.alpha = 1

	-- accuracy
	do

		ui.acc = CreateText('[instant]Acc: 100.00%', {0,0}, 640, 'game_ui')
		ui.acc.SetFont('monster')
		ui.acc.Scale(1.5,1.5)
		ui.acc.progressmode = 'none'
		ui.acc.HideBubble()
		ui.acc.color = {1,1,1,0}
		ui.acc.MoveToAbs(10,10)

	end


	-- hp
	do

		ui.hpbar = {}

		ui.hpbar.parent = CreateSprite('empty', 'game_ui')
		ui.hpbar.parent.MoveToAbs(10,480-10)

		ui.hpbar.frame = CreateSprite('_base/ui/hp-frame', 'game_ui')
		ui.hpbar.frame.SetPivot(0,1)
		ui.hpbar.frame.Scale(0.75,0.75)
		ui.hpbar.frame.SetParent(ui.hpbar.parent)
		ui.hpbar.frame.MoveTo(0,0)

		ui.hpbar.fill = CreateSprite('px', 'game_ui')
		ui.hpbar.fill.SetPivot(0,1)
		ui.hpbar.fill.SetParent(ui.hpbar.parent)
		ui.hpbar.fill.MoveTo(12,-3)

		ui.hpbar.startfill = 1
		ui.hpbar.filltarget = 1
		ui.hpbar.timespent = 1
		ui.hpbar.totaltime = 1/4

		function ui.hpbar.setalpha(alpha)
			ui.hpbar.frame.alpha = alpha
			ui.hpbar.fill.alpha = alpha
		end

		function ui.hpbar.fillinstant(progress)
			local f = ui.hpbar.frame.width-24
			ui.hpbar.fill.xscale = f*progress*ui.hpbar.frame.xscale

			local g = progress
			ui.hpbar.fill.color = {1-g, g, 0}
		end

		function ui.hpbar.getfill()
			local f = ui.hpbar.frame.width-24
			return ui.hpbar.fill.xscale/f/ui.hpbar.frame.xscale
		end

		function ui.hpbar.easefill(progress, time)
			ui.hpbar.startfill = ui.hpbar:getfill()
			ui.hpbar.filltarget = progress
			ui.hpbar.timespent = 0
			ui.hpbar.totaltime = time or ui.hpbar.totaltime
		end

		ui.hpbar.frame.SendToTop()

	end

	-- misses
	do

		ui.miss = CreateText('', {0,0}, 640, 'game_ui')
		ui.miss.SetFont('monster')
		ui.miss.Scale(1.5,1.5)
		ui.miss.progressmode = 'none'
		ui.miss.HideBubble()
		ui.miss.color = {1,1,1,0}
		ui.miss.MoveToAbs(10,10 + ui.acc.GetTextHeight()*ui.acc.yscale)

	end

	-- judgement
	do

		ui.judger = CreateSprite('empty', 'game_ui')
		ui.judger.Scale(0.5,0.5)
		ui.judger.y = 380
		ui.judger['timer'] = 0

	end

	-- combo
	do

		ui.combo = CreateText('[instant]0', {0,0}, 640, 'game_ui')
		ui.combo.SetFont('uidamagetransp')
		ui.combo.progressmode = 'none'
		ui.combo.HideBubble()
		ui.combo.Scale(0.75,0.75)
		ui.combo.color = {1,1,1,0}
		ui.combo['timer'] = 0

	end

	-- autoplay
	do

		ui.autoplay = CreateText('', {0,0}, 640, 'game_ui')
		ui.autoplay.SetFont('monster')
		ui.autoplay.progressmode = 'none'
		ui.autoplay.HideBubble()
		ui.autoplay.color = {1,1,1,0}

	end

	ui.reset()

end

function ui.load()

	ui.reset()
	ui.setalpha(1)

end

function ui.reset()

	ui.setalpha(0)
	ui.setoffset(0,0)
	
	ui.hpbar.fillinstant(1)
	ui.hpbar.fill.yscale = (ui.hpbar.frame.height-6)*ui.hpbar.frame.yscale

	ui.judger['timer'] = -math.huge
	ui.judger.alpha = 0

	ui.combo['timer'] = -math.huge
	ui.combo.alpha = 0

	ui.updatecombo()
	ui.updateacc()
	ui.updatemiss()

end

function ui.setoffset(x,y)

	ui.acc.x = 10 + x
	ui.acc.y = 10 + y

	ui.miss.x = 10 + x
	ui.miss.y = 10 + ui.acc.GetTextHeight()*ui.acc.yscale + y

	ui.hpbar.parent.x = 10 + x
	ui.hpbar.parent.y = 470 + y

	ui.judger.x = 320 + x
	ui.judger.y = 380 + y

	ui.combo.x = 320 - ui.combo.GetTextWidth()*ui.combo.xscale/2 + x
	ui.combo.y = 330 + y

	ui.autoplay.SetText('[instant]AUTOPLAY ON')
	ui.autoplay.x = 640 - ui.autoplay.GetTextWidth() - 8 + x
	ui.autoplay.y = 8 + y
	if not ui.level.autoplay then ui.autoplay.SetText('') end

end

function ui.updatecombo()

	ui.combo.x = ui.combo.x + ui.combo.GetTextWidth()*ui.combo.xscale/2
	ui.combo.SetText('[instant]'..ui.level.combo)
	ui.combo.x = ui.combo.x - ui.combo.GetTextWidth()*ui.combo.xscale/2 + 1 -- i have no idea why what im doing above is shifting the text by 1 pixel every time but

	ui.combo['timer'] = 0

end

function ui.updateacc()

	acc = tonumber(ui.level.acc) or 100
	ui.acc.SetText('[instant]Acc: '..string.format('%.2f', acc)..'%')

end

function ui.setalpha(alpha, force)

	ui.alpha = alpha

	ui.miss.alpha = alpha
	ui.acc.alpha = alpha
	ui.autoplay.alpha = alpha
	ui.hpbar.setalpha(alpha)

end

function ui.updatemiss()

	local miss = ui.level.misses

	local newstr = '[instant]' .. miss .. ' miss'

	if miss ~= 1 then newstr = newstr .. 'es' end -- plural form
	if miss == 0 then newstr = newstr .. '!' end

	ui.miss.SetText(newstr)

end

function ui.update()

	if ui.hpbar.timespent < ui.hpbar.totaltime then
		ui.hpbar.timespent = ui.hpbar.timespent + Time.dt
		local pr = easing.outQuad(ui.hpbar.timespent, ui.hpbar.startfill, ui.hpbar.filltarget-ui.hpbar.startfill, ui.hpbar.totaltime)
		ui.hpbar.fillinstant(pr)
	end

	ui.judger['timer'] = ui.judger['timer'] + Time.dt
	local timer = ui.judger['timer']

	ui.judger.alpha = ui.alpha
	if timer < 1/6 then
		ui.judger.xscale = easing.outSine(timer, 0.55, -0.05, 1/6)
		ui.judger.yscale = ui.judger.xscale
	elseif timer > 8/6 then
		ui.judger.alpha = easing.inSine(math.min(timer-8/6, 1/4), 1, -1, 1/4) * ui.alpha
	end

	if ui.level.combo < 10 then
		ui.combo.alpha = 0
	else
		ui.combo['timer'] = ui.combo['timer'] + Time.dt
		local timer = ui.combo['timer']
		ui.combo.alpha = ui.alpha
		if timer > 8/6 then
			ui.combo.alpha = easing.inSine(math.min(timer-8/6, 1/4), 1, -1, 1/4) * ui.alpha
		end
	end

end

return ui