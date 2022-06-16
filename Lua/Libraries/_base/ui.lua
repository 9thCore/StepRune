local ui = {}

local easing = require 'easing'

function ui.init()

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

		ui.judgetext = CreateSprite('empty', 'game_ui')
		ui.judgetext.Scale(0.5,0.5)
		ui.judgetext.y = 380
		ui.judgetext['timer'] = 0

	end

	-- useful functions
	function ui.setalpha(alpha)
		ui.miss.alpha = alpha
		ui.acc.alpha = alpha
		ui.hpbar.setalpha(alpha)
	end

	ui.reset()

end

function ui.load()

	ui.reset()

	ui.setalpha(1)

end

function ui.reset()

	ui.setalpha(0)

	ui.updateacc(100)
	ui.updatemiss(0)

	ui.hpbar.fillinstant(1)
	ui.hpbar.fill.yscale = (ui.hpbar.frame.height-6)*ui.hpbar.frame.yscale

end

function ui.updateacc(acc)

	acc = tonumber(acc) or 100
	ui.acc.SetText('[instant]Acc: '..string.format('%.2f', acc)..'%')

end

function ui.updatemiss(miss)

	miss = tonumber(miss) or 0

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

	ui.judgetext['timer'] = ui.judgetext['timer'] + 1
	local timer = ui.judgetext['timer']

	if timer < 10 then
		ui.judgetext.xscale = easing.outSine(timer, 0.6, 0.5-0.55, 10)
		ui.judgetext.yscale = ui.judgetext.xscale
	elseif timer > 80 then
		ui.judgetext.alpha = easing.inSine(math.min(timer-80, 30), 1, -1, 30)
	end

end

return ui