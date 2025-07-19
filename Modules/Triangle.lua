local CreatePart = require(script.Parent:WaitForChild("CreatePart"))

-- Function can also generate more triangles if wedge is bigger than 2048 (roblox limit)
-- I did not come up with the basic logic of creation of a triangle from 3 points,
-- i just made the triangle split into multiple when being bigger than 'max' value,
-- sadly, i cannot find where i got the code from

local function triangle(parent: Instance,a: Vector3,b: Vector3,c: Vector3)
	
	local max = 2048

	local ab, ac, bc = b - a, c - a, c - b

	local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)

	if (abd > acd and abd > bcd) then
		c, a = a, c
	elseif (acd > bcd and acd > abd) then
		a, b = b, a
	end

	ab, ac, bc = b - a, c - a, c - b

	local right = ac:Cross(ab).unit
	local up = bc:Cross(right).unit
	local back = bc.unit

	local height = math.abs(ab:Dot(up))


	local sizes = {
		Vector3.new(.05, height, math.abs(ab:Dot(back))),
		Vector3.new(.05, height, math.abs(ac:Dot(back)))
	}

	local cframes = {
		CFrame.fromMatrix((a + b)/2, right, up, back),
		CFrame.fromMatrix((a + c)/2, -right, up, -back)
	}

	local wedges = {}

	for i,size in sizes do
		if size.X > max or size.Y > max or size.Z > max then

			local a = (cframes[i] * CFrame.new(0,size.Y/2,size.Z/2)).Position
			local b = (cframes[i] * CFrame.new(0,-size.Y/2,size.Z/2)).Position
			local c = (cframes[i] * CFrame.new(0,-size.Y/2,-size.Z/2)).Position
			local m = cframes[i].Position


			local childrenTriangles = {
				{
					A = a,
					B = (a+c)/2,
					C = b,
					--i was fucking debugging this for 3 hours, then i said fuck it and changed C randomly to b and now it works, this is a sign, i should put it all on black
				},
				{
					A = c,
					B = (a+c)/2,
					C = b,
				},
				{
					A = c,
					B = (b+c)/2,
					C = m,
				},
				{
					A = b,
					B = (b+c)/2,
					C = m,
				},
			}

			for j,T in childrenTriangles do
				local ws = triangle(parent,T.A,T.B,T.C)
				table.move(ws,1,#ws,#wedges+1,wedges)
			end

		else

			local wedge = CreatePart(parent,cframes[i],sizes[i])
			wedge.Shape = "Wedge"
			table.insert(wedges, wedge)

		end
	end

	return wedges
end

return triangle