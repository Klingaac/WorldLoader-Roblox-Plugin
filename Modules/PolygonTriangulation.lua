-- code from https://2dengine.com/doc/polygons.html

local TriangleModule = require(script.Parent:WaitForChild("Triangle"))

-- Finds twice the signed area of a polygon
function signedPolyArea(p: any)
	local s = 0
	local n = #p
	local a = p[n]
	for i = 1, n do
		local b = p[i]
		s = s + (b.x + a.x)*(b.y - a.y)
		a = b
	end
	return s
end

-- Finds the actual area of a polygon
function polyArea(p: any)
	local s = signedPolyArea(p)
	return math.abs(s/2)
end

-- Checks if the winding of a polygon is counter-clockwise
function isPolyCCW(p: any)
	return signedPolyArea(p) > 0
end

-- Reverses the vertex winding
function polyReverse(p: any)
	local n = #p
	for i = 1, math.floor(n/2) do
		local i2 = n - i + 1
		p[i], p[i2] = p[i2], p[i]
	end
end


-- Finds twice the signed area of a triangle
function signedTriArea(p1:{ x: number, y: number }, p2:{ x: number, y: number }, p3:{ x: number, y: number })
	return (p1.x - p3.x)*(p2.y - p3.y) - (p1.y - p3.y)*(p2.x - p3.x)
end

-- Checks if a point is inside a triangle
function pointInTri(p: any, p1: { x: number, y: number }, p2:{ x: number, y: number }, p3:{ x: number, y: number })
	local ox, oy = p.x, p.y
	local px1, py1 = p1.x - ox, p1.y - oy
	local px2, py2 = p2.x - ox, p2.y - oy
	local ab = px1*py2 - py1*px2
	local px3, py3 = p3.x - ox, p3.y - oy
	local bc = px2*py3 - py2*px3
	local sab = ab < 0
	if sab ~= (bc < 0) then
		return false
	end
	local ca = px3*py1 - py3*px1
	return sab == (ca < 0)
end

-- Checks if the vertex is an "ear" or "mouth"
local left, right = {}, {}
local function isEar(i0:{ x: number, y: number }, i1:{ x: number, y: number }, i2:{ x: number, y: number })
	if signedTriArea(i0, i1, i2) >= 0 then
		local j1 = right[i2]
		repeat
			local j0, j2 = left[j1], right[j1]
			if signedTriArea(j0, j1, j2) <= 0 then
				if pointInTri(j1, i0, i1, i2) then
					return false
				end
			end
			j1 = j2
		until j1 == i0
		return true
	end
	return false
end

-- Triangulates a counter-clockwise polygon
function triangulatePoly(p:any)
	if not isPolyCCW(p) then
		polyReverse(p)
	end
	for i = 1, #p do
		local v = p[i]
		left[v], right[v] = p[i - 1], p[i + 1]
	end
	local first, last = p[1], p[#p]
	left[first], right[last] = last, first
	local out = {}
	local nskip = 0
	local i1 = first
	while #p >= 3 and nskip <= #p do
		local i0, i2 = left[i1], right[i1]
		if #p > 3 and isEar(i0, i1, i2) then
			table.insert(out, { i0, i1, i2 })
			left[i2], right[i0] = i0, i2     
			left[i1], right[i1] = nil, nil
			nskip = 0
			i1 = i0
		else
			nskip = nskip + 1
			i1 = i2
		end
	end
	return out
end


local function TriangulateMain(positions: {Vector3})
	
	if #positions < 3 then
		--warn("positions table has "..#positions.." member/s")
		return {}
	end

	local p = {}
	local height = positions[1].Y

	for _,pos in positions do
		local T = {
			x=pos.X,
			y=pos.Z
		}
		table.insert(p,T)
	end

	local T = triangulatePoly(p)

	local triangles = {}
	local sumPos = Vector3.new(0,0,0)

	for _,t in T do
		local a = Vector3.new(t[1].x,height,t[1].y)
		local b = Vector3.new(t[2].x,height,t[2].y)
		local c = Vector3.new(t[3].x,height,t[3].y)
		local ts = TriangleModule(nil,a,b,c)
		for _,t2 in ts do
			table.insert(triangles,t2)
		end
	end
	
	return triangles

end

return TriangulateMain

