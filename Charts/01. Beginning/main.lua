
local receptors = Notes.GetReceptors()

for i=1,4 do

	local r = receptors[i]

	r.left.ScaleDistance(0.5)
	r.up.ScaleDistance(-1)

end

function Update()

	for i,r in ipairs(receptors) do

		r.RotateZ(1, true, true)

	end

end