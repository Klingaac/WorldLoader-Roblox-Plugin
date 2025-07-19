-- This one is a mess, but hey, it (mostly) works!!!1!

local module = {}

-- Modules
local PolygonTriangulation = require(script.Parent:WaitForChild("PolygonTriangulation"))
local CreatePart = require(script.Parent:WaitForChild("CreatePart"))
local Bezier = require(script.Parent:WaitForChild("BezierModule"))
local Elevation = require(script.Parent:WaitForChild("Elevation"))
local Triangle = require(script.Parent:WaitForChild("Triangle"))

-- Other
local ignoreBoundary
local CS = game:GetService("CollectionService")
local terrain = game.Workspace.Terrain
local Objects = script.Parent.Parent.Objects
local Values = Objects.Values

-- Borders of chunk
local minX
local maxX
local minZ
local maxZ

-- For all mentions of the value of 'D' variable below:
-- Its a divider value, properties are in meters, 1 stud is 0.28cm so we do property/D to determine it in studs 

local function findMesh(p: Instance)
	for _,c in p:GetChildren() do
		if c:IsA("BlockMesh") or c:IsA("SpecialMesh") or c:IsA("Mesh") then
			return c
		end
	end
end

function module.smoothConnectFlat(parts: {Instance},GenerationRules: any?)
	
	local RO_SCALE
	if GenerationRules and GenerationRules["Ro-Scale"] then
		RO_SCALE = true
	end

	for i,part in parts do

		if not parts[i-1] then 
			continue
		end

		local prevPart = parts[i-1]

		local angle = Bezier.CFramesAngle(part.CFrame,prevPart.CFrame)

		if angle < 90.2 or 179.8 < angle then

			if 179.6 < angle then
				continue
			else

				-- We need to scale the part to the intersect and not further (i think, this is me 2 weeks later)

				local intersect = Bezier.CFrameCFrameIntersect3D(part.CFrame,prevPart.CFrame)

				if not intersect then continue end

				for j,p in {part,prevPart} do

					local dist = (p.Position-intersect).Magnitude
					local oldDist = p.Size.Z/2
					local diff = dist-oldDist

					local m = -1 if j == 2 then m = 1 end

					local offset = diff/2*m

					-- If the part has a mesh, we need to properly scale it
					local mesh = findMesh(p)

					if mesh then
						local scaleRatio = mesh.Scale.Z/p.Size.Z
						if mesh:IsA("BlockMesh") then
							mesh.Scale = Vector3.new(mesh.Scale.X,mesh.Scale.Y,1)
						else
							mesh.Scale = Vector3.new(mesh.Scale.X,mesh.Scale.Y,dist+oldDist)
						end

						p.Size = Vector3.new(p.Size.X,p.Size.Y,dist+oldDist)

					else
						p.Size = Vector3.new(p.Size.X,p.Size.Y,dist+oldDist)
					end

					p.CFrame = p.CFrame * CFrame.new(0,0,offset)

				end

			end

			continue
			
		end


		local cfrm1a = part.CFrame * CFrame.new(part.size.X/2,0,0)
		local cfrm1b = part.CFrame * CFrame.new(-part.size.X/2,0,0)
		
		local cfrm2a = prevPart.CFrame * CFrame.new(prevPart.size.X/2,0,0)
		local cfrm2b = prevPart.CFrame * CFrame.new(-prevPart.size.X/2,0,0)

		local intersectA = Bezier.CFrameCFrameIntersect3D(cfrm1a,cfrm2a)
		local intersectB = Bezier.CFrameCFrameIntersect3D(cfrm1b,cfrm2b)

		local sum = (cfrm1a.Position+cfrm1b.Position)/2


		local furtherIntersect = intersectA
		local closestIntersect = intersectB

		if (intersectB-sum).Magnitude > (intersectA-sum).Magnitude then
			furtherIntersect = intersectB
			closestIntersect = intersectA
		end

		-- If its nan or inf then i give up
		if furtherIntersect.X ~= furtherIntersect.X or furtherIntersect.X > 99999999 or furtherIntersect.X < -99999999 then
			continue
		end


		for j,T in {{part,cfrm1a,cfrm1b},{prevPart,cfrm2a,cfrm2b}} do
			local p = T[1]
			local cfrmA = T[2]
			local cfrmB = T[3]

			local closerPos = cfrmA.Position
			if (cfrmA.Position-furtherIntersect).Magnitude > (cfrmB.Position-furtherIntersect).Magnitude then
				closerPos = cfrmB.Position
			end

			local dist = (closerPos-furtherIntersect).Magnitude
			local oldDist = p.Size.Z/2
			local diff = dist-oldDist

			local m = -1 if j == 2 then m = 1 end

			local offset = diff/2*m

			-- Again, we need to scale the mesh properly (if found)
			local mesh = findMesh(p)

			if mesh then
				
				if mesh:IsA("BlockMesh") then
					mesh.Scale = Vector3.new(mesh.Scale.X,mesh.Scale.Y,1)
				else
					mesh.Scale = Vector3.new(mesh.Scale.X,mesh.Scale.Y,dist+oldDist)
				end

				p.Size = Vector3.new(p.Size.X,p.Size.Y,dist+oldDist)

			else
				p.Size = Vector3.new(p.Size.X,p.Size.Y,dist+oldDist)
			end

			p.CFrame = p.CFrame * CFrame.new(0,0,offset)

		end
		
	end
	
end


function module.smoothRailConnect(tracks: {Instance},GenerationRules: any?)

	local rails1 = {}
	local rails2 = {}
	local ballasts = {}
	local ties = {}

	for _,track in tracks do
		for  _,child in track:GetChildren() do
			if child.Name == "Rail" then
				if child:GetAttribute("num") == 1 then
					table.insert(rails1,child)
				else
					table.insert(rails2,child)
				end
			elseif child.Name == "Ballast" then
				table.insert(ballasts,child)
			elseif child.Name == "Ties" then
				table.insert(ties,child)
			end
		end
	end

	local offsets = {}

	for i,tie in ties do
		local ballast = tie.Parent:FindFirstChild("Ballast") if not ballast then continue end
		offsets[tie] = tie.Position - ballast.Position
	end

	for _,T in {rails1,rails2,ballasts} do
		module.smoothConnectFlat(T,GenerationRules)
	end

	for i,tie in ties do
		local offset = offsets[tie]
		local ballast = tie.Parent:FindFirstChild("Ballast") if not ballast then continue end
		tie.Position = ballast.Position + offset
	end

end


function module.area(tags: any, model: Instance, properties: any, positions: {Vector3}, corners: {Vector3}, GenerationRules: any)

	local D = 0.28 / Values.Scale.Value

	local triangles = PolygonTriangulation(positions)

	if #triangles > 100 then
		task.wait()
	end

	local height = properties.height or .1
	height = height/D
	
	if tags["railway"] and tags["railway"] == "platform" then
		height *= GenerationRules["Train platform height multiplier"]
	end

	for _,t in triangles do
		t.Color = properties.color
		t.Material = properties.material
		t.Size = Vector3.new(height,t.Size.Y,t.Size.Z)
		t.Position += Vector3.new(0,t.Size.X/2,0)
		t.Parent = model
	end

	model.WorldPivot = CFrame.new(model.WorldPivot.X,0,model.WorldPivot.Z)

	return triangles

end


function module.way(tags: any,model: Instance, properties: any, positions: {Vector3}, corners: {any}, GenerationRules: any, Map: any, elevationMode: string)
	
	local scale = Values.Scale.Value
	local D = 0.28 / scale
	local parts = {}

	if #positions < 2 then return end

	local M = 1 --multiplier

	if tags["lanes"] then
		if tags["lanes"] == 1 then
			M = 1.2 -- One lane roads look very weird when their so thin so i added an extra 0.25
		else
			M *= tags["lanes"] /1.8 -- Divided by 2 cuz most roads untagged roas in the world already have 2 lanes
		end
	end
	

	if elevationMode == "terrain" or elevationMode == "elevation" then
		
		local newPositions = {}
		
		
		for i,pos in positions do
			
			if i == 1 then
				table.insert(newPositions,pos)
				continue
			end

			local a = pos
			local b = positions[i-1]

			local dist = (a-b).Magnitude

			local distMeters = dist * D
			if distMeters > 10 then
				local multiple = (distMeters - (distMeters % 10)) / 10

				for j = 1, multiple do
					local alpha = j / (multiple + 1)
					local newPosition = b:Lerp(a, alpha)
					table.insert(newPositions, newPosition)
				end

			end
			
			table.insert(newPositions,pos)

		end
		
		positions = newPositions
		newPositions = {}
		
		for i,pos in positions do
			local newPos = Elevation.getOffsetPosition(pos, Map)
			if newPos then
				table.insert(newPositions,newPos)
			end
		end
		
		positions = newPositions
		
		if #positions < 2 then
			return
		end
		
	end
	

	for i,pos1 in positions do
		local pos2 = positions[i-1]
		if not pos2 then
			continue
		end

		local dist = (pos1-pos2).Magnitude
		local size = Vector3.new(properties.width/D*M,properties.height/D,dist)
		local cfrm = CFrame.new((pos1+pos2)/2) * CFrame.lookAt(pos1,pos2).Rotation

		cfrm += Vector3.new(0,properties.height/D/2,0)

		local part = CreatePart(model,cfrm,size,properties.color,properties.material)
		table.insert(parts,part)

	end

	-- Makes it so the way parts ale nicely connected (like with archimedes plugin) and not clipping
	if elevationMode == "flat" then
		if #parts > 1 then
			module.smoothConnectFlat(parts)
		end
	end

	return parts

end

return module
