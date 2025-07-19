-- Library for Bezier curves (splines), line intersects and segment intersects
-- By Klingac

local module = {}

function module.lerp(a: Vector3,b: Vector3,t: number)
	return a + (b-a) * t
end

function module.CFramesAngle(cfrm1: CFrame,cfrm2: CFrame)
	local ab = cfrm1.Position - (cfrm1 * CFrame.new(0,0,-1)).Position
	local bc = cfrm2.Position - (cfrm2 * CFrame.new(0,0,-1)).Position

	local dot = ab:Dot(bc)
	local len = ab.Magnitude*bc.Magnitude

	local angle = math.deg(math.acos(dot/len))

	return 180 - angle
end

function module.CFrameCFrameIntersect(cframe1: CFrame,cframe2: CFrame) -- It is acctually a plane/plane intersect
	local pos1a = cframe1.Position
	local pos1b = (cframe1 * CFrame.new(0,0,-1)).Position

	local pos2a = cframe2.Position
	local pos2b = (cframe2 * CFrame.new(0,0,-1)).Position

	local x1 = pos1a.X
	local z1 = pos1a.Z
	local x2 = pos1b.X
	local z2 = pos1b.Z
	local x3 = pos2a.X
	local z3 = pos2a.Z
	local x4 = pos2b.X
	local z4 = pos2b.Z

	local Px = ((x1*z2-z1*x2)*(x3-x4)-(x1-x2)*(x3*z4-z3*x4)) / ((x1-x2)*(z3-z4)-(z1-z2)*(x3-x4))
	local Pz = ((x1*z2-z1*x2)*(z3-z4)-(z1-z2)*(x3*z4-z3*x4)) / ((x1-x2)*(z3-z4)-(z1-z2)*(x3-x4))

	return Vector3.new(Px,cframe1.Position.Y,Pz)
end

local function transalateToXY(vector: Vector3)
	return Vector3.new(vector.X,vector.Z,vector.Y)
end

function module.CFrameCFrameIntersect3D(cframe1: CFrame, cframe2: CFrame)
	local point1 = module.CFrameCFrameIntersect(cframe1,cframe2)
	cframe2 = CFrame.lookAt(point1,point1+Vector3.new(0,1,0))
	
	if math.abs(cframe1.Position.Y-(cframe1 * CFrame.new(0,0,-1)).Position.Y) < 0.05 then
		return point1
	end

	-- Switch y and z axis
	local pos1a = transalateToXY(cframe1.Position)
	local pos1b = transalateToXY((cframe1 * CFrame.new(0,0,-1)).Position)

	local pos2a = transalateToXY(cframe2.Position)
	local pos2b = transalateToXY((cframe2 * CFrame.new(0,0,-1)).Position)

	local x1 = pos1a.X
	local z1 = pos1a.Z
	local x2 = pos1b.X
	local z2 = pos1b.Z
	local x3 = pos2a.X
	local z3 = pos2a.Z
	local x4 = pos2b.X
	local z4 = pos2b.Z

	-- Only pz needed
	local Pz = ((x1*z2-z1*x2)*(z3-z4)-(z1-z2)*(x3*z4-z3*x4)) / ((x1-x2)*(z3-z4)-(z1-z2)*(x3-x4))

	local v = Vector3.new(point1.X,Pz,point1.Z)
	
	return v
end


function module.segmentSegmentIntersect(A: Vector3,B: Vector3,C: Vector3,D: Vector3)

	local function calculateOffsets(A: Vector3, B: Vector3, C: Vector3, D: Vector3)
		local top = (D.Z - C.Z) * (A.X - C.X) - (D.X - C.X) * (A.Z - C.Z)
		local bottom = (D.X - C.X) * (B.Z - A.Z) - (D.Z - C.Z) * (B.X - A.X)
		if bottom ~= 0 then
			local offset = top / bottom
			if offset >= 0 and offset <= 1 then
				return offset
			end
			return nil
		end
	end

	local t = calculateOffsets(A, B, C, D)
	local u = calculateOffsets(C, D, A, B)
	
	if t and u then
		return Vector3.new(module.lerp(A.X, B.X, t),(A.Y+B.Y+C.Y+D.Y)/4,module.lerp(A.Z, B.Z, t))
	end
end

function module.curveMid(pos1: Vector3, pos2: Vector3, pos3: Vector3)
	return module.lerp(module.lerp(pos1, pos3, 0.5), module.lerp(pos3, pos2, 0.5), 0.5)
end

function module.bezierBezierIntersect(path1: {Vector3},path2: {Vector3})

	local point1,point2,point3,point4

	for i = 2,#path1,1 do
		point1 = path1[i-1]
		point2 = path1[i]
		for j = 2,#path2,1 do
			point3 = path2[j-1]
			point4 = path2[j]

			local int = module.segmentSegmentIntersect(point1,point2,point3,point4)
			if int then return int,point1,point2,point3,point4 end
		end
	end

end

function module.quadraticLerp(a: Vector3,b: Vector3,c: Vector3,iters: number?)
	local Path = {}

	if not iters then
		iters = math.clamp(math.round((a - c).Magnitude / 2.5),7,math.huge)
	end

	for i = 0, iters, 1 do
		local t = i/iters

		local l1 = module.lerp(a, b, t)				
		local l2 = module.lerp(b, c, t)

		local point = module.lerp(l1, l2, t)

		table.insert(Path,point)

	end

	return Path
end

function module.doubleQuadraticLerp(a: Vector3,b: Vector3,c: Vector3,iters: number?)
	if not iters then
		iters = math.clamp(math.round((a - c).Magnitude / 2.5),7,math.huge)
	end
	if iters % 2 ~= 0 then iters += 1 end
	
	local mid = module.lerp(module.lerp(a,b,0.5),module.lerp(b,c,0.5),0.5)
	
	local A = a
	local B = module.CFrameCFrameIntersect(CFrame.lookAt(a,b), CFrame.new(mid) * CFrame.lookAt(a,c).Rotation)
	local C = mid
	local D = module.CFrameCFrameIntersect(CFrame.lookAt(c,b), CFrame.new(mid) * CFrame.lookAt(a,c).Rotation)
	local E = c
	
	local path = module.quadraticLerp(A,B,C,iters/2)
	local path2 = module.quadraticLerp(C,D,E,iters/2)
	table.move(path2,2,#path2,#path+1,path)
	
	return path
end

function module.cubicLerp(a: Vector3,b: Vector3,c: Vector3,d: Vector3,iters: number?)
	local Path = {}

	if not iters then
		iters = math.clamp(math.round((a - d).Magnitude / 2.5),7,math.huge)
	end

	for i = 0, iters, 1 do
		local t = i/iters

		local l1 = module.lerp(a, b, t)				
		local l2 = module.lerp(b, c, t)
		local l3 = module.lerp(c, d, t)

		local start = module.lerp(l1, l2, t)
		local finish = module.lerp(l2, l3, t)

		local cubic = module.lerp(start, finish, t)

		table.insert(Path,cubic)

	end

	return Path
end


return module
