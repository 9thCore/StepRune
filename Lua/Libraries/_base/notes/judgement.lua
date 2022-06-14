local judgement = {}

local easing = require 'easing'

judgement.hitwindows = {
	{'_base/judgement/perfect', 0.1},
	{'_base/judgement/great', 0.2},
	{'_base/judgement/bad', 0.3},
	miss = '_base/judgement/miss'
}

judgement.judgetext = CreateSprite(judgement.hitwindows[1][1], 'game_ui')
judgement.judgetext.Scale(1/2, 1/2)
judgement.judgetext.alpha = 0
judgement.judgetext['timer'] = 0

function judgement.reset()

	judgement.judgetext.alpha = 0
	judgement.judgetext['timer'] = 9999

	judgement.judgetext.y = 80

end

function judgement.init()
	judgement.reset()
end

function judgement.inrange(sec)
	sec = math.abs(sec)
	for _,t in ipairs(judgement.hitwindows) do
		if sec < t[2] then
			return t[1]
		end
	end
	return false
end

function judgement.judge(spr)
	if judgement.hitwindows[spr] then spr = judgement.hitwindows[spr] end
	if type(spr) == 'table' then spr = spr[1] end
	
	judgement.judgetext.Set(spr)
	judgement.judgetext.alpha = 1
	judgement.judgetext.Scale(0.55,0.55)
	judgement.judgetext['timer'] = 0
end

function judgement.update()
	judgement.judgetext['timer'] = judgement.judgetext['timer'] + 1
	local timer = judgement.judgetext['timer']

	if timer < 10 then
		judgement.judgetext.xscale = easing.outSine(timer, 0.6, 0.5-0.55, 10)
		judgement.judgetext.yscale = judgement.judgetext.xscale
	elseif timer > 80 then
		judgement.judgetext.alpha = easing.inSine(math.min(timer-80, 30), 1, -1, 30)
	end
end

return judgement