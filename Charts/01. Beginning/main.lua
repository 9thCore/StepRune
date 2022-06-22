
local receptors = Notes.GetReceptors()

for i=1,4 do

	local r = receptors[i]

	r:Show()
	r:SetPivot(48)
	r:Move(0,i/4)
	r:RotateY(90*i)

end

function Update()

	for i,r in ipairs(receptors) do

		r:RotateY(Time.dt*120, true)

	end

end