local judgement = {}

local easing = require 'easing'

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