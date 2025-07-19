-- Modules
local CreatePart = require(script.Parent:WaitForChild("CreatePart"))
local PolygonTriangulation = require(script.Parent:WaitForChild("PolygonTriangulation"))
local Bezier = require(script.Parent:WaitForChild("BezierModule"))

local RayTriangleIntersection = require(script.Parent:WaitForChild("RayTriangleIntersection"))
local SimpleOperations = require(script.Parent:WaitForChild("SimpleOperations"))
local Elevation = require(script.Parent:WaitForChild("Elevation"))

local Objects = script.Parent.Parent.Objects
local Values = Objects.Values

local CS = game:GetService("CollectionService")

local function createTrainTrack(cfrm: CFrame,dist: number,properties: any,GenerationRules: any)
	
	local AssetFolder = Objects.Assets
	
	local RO_SCALE = GenerationRules["Ro-Scale"]
	local RO_SCALE_TIES = GenerationRules["Ro-Scale Ties"]
	local RO_SCALE_BALLAST = GenerationRules["Ro-Scale Ballast"]
	
	if not RO_SCALE then
		RO_SCALE_BALLAST, RO_SCALE_TIES = false, false
	end
	
	-- Divider value, properties are in meters, 1 stud is 0.28cm so we do property/D to determine it in studs 
	local D = 0.28 / Values.Scale.Value

	local Track = Instance.new("Model")
	Track.Name = "Track"

	local gauge = properties.gauge / D

	local tiesWidth = gauge*2

	local ballastWidth = properties.ballast.width/D
	local ballastHeight = properties.ballast.height/D

	if RO_SCALE_BALLAST then
		ballastWidth = 2
		ballastHeight = .3
	end

	local ballast = AssetFolder.MeshParts[properties.ballast.meshpart]:Clone()
	ballast.Color = properties.ballast.color
	ballast.Material = properties.ballast.material
	ballast.Size = Vector3.new(ballastWidth,ballastHeight,dist)
	ballast.CFrame = cfrm * CFrame.new(0,ballast.Size.Y/2,0)
	ballast.Name = "Ballast"
	ballast.Parent = Track
	ballast.CanCollide = false


	Track.PrimaryPart = ballast

	--SHIT CODE WARNING: DIFFERENCE BETWEEM tiesWidth AND tieWidth

	local tieHeight = .1/D --dont use in texture ties
	local tieWidth = .4/D --google said that ties are 9 inches long but fuck that, this looks better
	

	if RO_SCALE_TIES then
		tieWidth = .2
		tieHeight = .1
		tiesWidth = 1.2
	end
	
	if properties.ties.ties3D == true then

		--for i = tieWidth+(dist%tieWidth/2),dist-(dist%tieWidth/2),tieWidth*2.5 do
		for i = tieWidth,dist,tieWidth*2.5 do
			local tie = CreatePart(Track,cfrm*CFrame.new(0,0,(dist/2)-i),Vector3.new(tiesWidth,tieHeight,tieWidth))
			tie.Position = Vector3.new(tie.Position.X,ballast.Position.Y+ballast.Size.Y/2+tie.Size.Y/2,tie.Position.Z)
			tie.Color = properties.ties.color
			tie.Material = properties.ties.material
			tie.Name = "Ties"
		end

	else

		local tieSize = Vector3.new(tiesWidth,.04,dist)

		local tie = CreatePart(Track,cfrm*CFrame.new(0,ballast.Size.Y-.019,0),tieSize)
		tie.Transparency = 1
		tie.Name = "Ties"

		local tiesTexture = AssetFolder.Textures[properties.ties.texture]:Clone()
		tiesTexture.Face = "Top"
		tiesTexture.Parent = tie
		tiesTexture.Transparency = properties.ties.transparency
		tiesTexture.StudsPerTileU = tiesWidth
		tiesTexture.StudsPerTileV = tiesWidth*.4

	end


	local railProps = properties.rails
	local offset = gauge/2
	local railSize = Vector3.new(0.2/D,0.2/D, dist)

	if RO_SCALE then
		
		offset = .3
		railSize = Vector3.new(.4,.3,dist)
		
		for i = -offset,offset,offset*2 do

			local j = -i/offset


			local railCfrm = ballast.CFrame * CFrame.new(i+(j*-1*railSize.X/2),railSize.Y/2 + ballast.Size.Y/2,0)
			
			local rail = CreatePart(Track,railCfrm,railSize,nil,railProps.material)
			rail.Name = "Rail"
			rail.Color = railProps.color
			rail.CanCollide = true
			
			if not properties.ties.ties3D then
				rail.Position += Vector3.new(0,-tieHeight,0)
			end


			if i == -offset then
				rail:SetAttribute("num",1) --determining if its the first or second rail
			else
				rail:SetAttribute("num",2)
			end


			local mesh = AssetFolder.Meshes[railProps.mesh]:Clone()

			mesh.Parent = rail

			if mesh:IsA("BlockMesh") then
				mesh.Scale = Vector3.new(mesh.Scale.X,mesh.Scale.Y,1)
				mesh.Offset = Vector3.new(mesh.Offset.X*-j,mesh.Offset.Y,mesh.Offset.Z)
			else
				mesh.Scale = Vector3.new(mesh.Scale.X,mesh.Scale.Y,dist)
				mesh.Offset = Vector3.new(mesh.Offset.X*j,mesh.Offset.Y,mesh.Offset.Z)
			end
			
		end

	else

		for i = -offset,offset,offset*2 do

			local j = -i/offset


			local railCfrm = ballast.CFrame * CFrame.new(i+(j*-1*railSize.X/2),railSize.Y/2 + ballast.Size.Y/2 + tieHeight,0)
			local rail = CreatePart(Track,railCfrm,railSize,railProps.color,railProps.material)
			rail.Name = "Rail"
			rail.CanCollide = true


			if i == -offset then
				rail:SetAttribute("num",1) --determining if its the first or second rail
			else
				rail:SetAttribute("num",2)
			end


			local mesh = AssetFolder.Meshes[railProps.mesh]:Clone()
			local meshOffset = Vector3.new(0,0,0)

			mesh.Parent = rail
			mesh.Scale = railSize
			mesh.Offset = meshOffset

			if mesh:IsA("BlockMesh") then
				mesh.Scale = Vector3.new(1,1,1)
			end

			--local mesh = game.ReplicatedStorage["OSM Assets"].Meshes[railProps.mesh]:Clone()
			--local meshOffset = Vector3.new(0,mesh.Offset.Y,mesh.Offset.Z)

			--mesh.Parent = rail
			--mesh.Scale = Vector3.new(mesh.Scale.X,mesh.Scale.Y, rail.Size.Z)
			--mesh.Offset = meshOffset

		end

	end


	if GenerationRules["Track Handles"] then
		local handleSize = Vector3.new(ballast.Size.X,ballast.Size.Y+railSize.Y,1/D)

		if GenerationRules["Ro-Scale"] then
			handleSize = Vector3.new(ballast.Size.X,railSize.Y,1)
		end

		for i = -dist/2,dist/2,dist do
			local handleCfrm = ballast.CFrame * CFrame.new(0,0,i-((i/(dist/2))*(handleSize.Z/2)))
			if i > 0 then
				handleCfrm = handleCfrm * CFrame.Angles(0,math.rad(180),0)
			end

			local handle = CreatePart(Track,handleCfrm,handleSize)
			handle.CanCollide = false
			handle.Transparency = 1
			handle.Name = "TrackHandle"
		end
	end

	return Track
end

--operation types
local WayOperations = {
	["area"] = function(tags: any, model: Instance, properties: any, positions: {Vector3},corners: {Vector3},GenerationRules: any, Map: any)

		return SimpleOperations.area(tags,model,properties,positions,corners,GenerationRules)

	end,

	["way"] = function(tags: any, model: Instance, properties: any, positions: {Vector3},corners: {Vector3},GenerationRules: any, Map: any, elevationMode: string)

		return SimpleOperations.way(tags,model,properties,positions,corners,GenerationRules,Map,elevationMode)

	end,

	["area/way"] = function(tags: any, model: Instance, properties: any, positions: {Vector3},corners: {Vector3},GenerationRules: any, Map: any, elevationMode: string)

		if tags["area"] and tags["area"] == "yes" then

			return SimpleOperations.area(tags,model,properties,positions,corners,GenerationRules)

		else

			return SimpleOperations.way(tags,model,properties,positions,corners,GenerationRules,Map,elevationMode)

		end

	end,


	-- It looks pretty weird, used to have a way to cut off rails at borders of chunks but i removed that
	["rail"] = function(tags: any, model: Instance, properties: any, positions: {Vector3},corners: {Vector3},GenerationRules: any, Map: any, elevationMode: string)

		local newPositions = {}

		local firstPos,lastPos,firstPart
		

		for i,pos in positions do
			if not positions[i-1] then
				table.insert(newPositions,pos)
				continue
			end

			local A,B = pos,positions[i-1]
			local intersects = {}

			local function comp(a,b)
				if (a-pos).Magnitude < (b-pos).Magnitude then
					return a else return b
				end
			end

			table.sort(intersects,comp)
			for _,intersect in intersects do
				table.insert(newPositions,intersect)
			end

			table.insert(newPositions,pos)

		end

		positions = newPositions
		
		
		
		if elevationMode == "terrain" or elevationMode == "elevation" then

			local newPositions = {}

			for i,pos in positions do
				local newPos = Elevation.getOffsetPosition(pos, Map)
				if newPos then
					table.insert(newPositions,newPos)
				end
			end

			for i,pos in positions do
				if i == 1 then
					continue
				end

				local a = pos
				local b = positions[i-1]

				local dist = (a-b).Magnitude

			end

			positions = newPositions

			if #positions < 2 then
				return
			end

		end
		

		local parts = {}
		local partsPositions = {} --the smoothConnect module needs positions for angles between parts

		for i,pos in positions do
			if not positions[i-1] then
				firstPos = pos
				continue
			elseif i == #positions then
				lastPos = pos
			end


			local dist = (pos-positions[i-1]).Magnitude
			local cfrm = CFrame.new((positions[i-1]+pos)/2) * CFrame.lookAt(pos,positions[i-1]).Rotation

			local Track = createTrainTrack(cfrm,dist,properties,GenerationRules)

			Track.Parent = model
			table.insert(parts,Track)
			table.insert(partsPositions,positions[i-1])

		end

		if #parts > 1 then
			SimpleOperations.smoothRailConnect(parts,GenerationRules)
		end

		return parts

	end,

	["building"] = function(tags: any, model: Instance, properties: any, positions: {Vector3},corners: {Vector3},GenerationRules: any, Map: any, elevationMode: string)
		
		local scale = Values.Scale
		local D = 0.28
		local heightUnderground = 15 --studs

		local height = tags["building:levels"]

		if tags["building:levels"] and tonumber(tags["building:levels"]) then
			height = tonumber(tags["building:levels"]) * 3/D
		else
			height = 4/D --GenerationRules.deafultBuildingHeight /D
		end
		
		local totalHeight = height
		local addedHeight = height/2
		
		if elevationMode ~= "flat" then
			totalHeight = height + heightUnderground
			addedHeight = height/2 - heightUnderground/2
		end
		
		
		local mid = Vector3.new(0,0,0)
		for _,pos in positions do
			mid += pos
		end
		mid /= #positions
		
		
		if elevationMode ~= "flat" then
			mid = Elevation.getOffsetPosition(mid, Map)
		end
		
		if not mid then
			return {}
		end
		
		local buildingPositions = {}
		for i = 1,#positions-1 do
			local pos = positions[i]
			
			pos += Vector3.new(0,mid.Y + addedHeight,0)
			
			table.insert(buildingPositions, pos)
		end


		local triangles = PolygonTriangulation(buildingPositions)

		for _,t in triangles do
			t.Color = properties.color
			t.Material = properties.material
			t.Size = Vector3.new(totalHeight,t.Size.Y,t.Size.Z)
			t.Name = "BuildingPart"
			t:SetAttribute("OSM_type","building_part")
			t.Parent = model
		end

		model:SetAttribute("OSM_type","building")

		return triangles

	end,

}

return WayOperations
