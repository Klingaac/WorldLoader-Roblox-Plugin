-- Functions to get elevation on a specific coordinate

-- So i dont call the elevation api everytime i want to get elevation on a specific coordinate,
-- I create a sort of a mesh (a Map) from a grid of Vector3s, spaced a few studs apart (according to user scale value),
-- And then i check this mesh to get elevation on a specific position

local RayTriangleIntersection = require(script.Parent.RayTriangleIntersection)
local UIProperties = require(script.Parent:WaitForChild("UI").PropertiesModule)

local module = {}
local offset
local allMaps = {}

function module.getPosition(position: Vector3, Map: any)

	local ray_origin = position + Vector3.new(0, 10000, 0)
	local direction = Vector3.new(0,-10000,0)

	for a = 1,#Map - 1 do
		for b = 1,#Map[a] - 1 do

			local v1 = Map[a][b]["v3"]
			local v2 = Map[a+1][b]["v3"]
			local v3 = Map[a][b+1]["v3"]
			local v4 = Map[a+1][b+1]["v3"]

			local t1 = {v1,v2,v4}
			local t2 = {v1,v3,v4}

			for _,t in {t1,t2} do

				local intersection = RayTriangleIntersection(ray_origin,direction,t[1],t[2],t[3])

				if intersection then
					return intersection
				end

			end

		end
	end
	
end

function module.getOffsetPosition(position: Vector3, Map: any)
	
	local elevationMultiplier = UIProperties.getGenerationRules()["Elevation multiplier"]
	
	local intersection = module.getPosition(position,Map)
	
	if intersection then
		return Vector3.new(intersection.X, (intersection.Y + offset) * elevationMultiplier, intersection.Z)
	else
		-- If intersection between map and ray isnt found, sreach all other maps for it
		for _,Map2 in allMaps do
			task.wait()
			intersection = module.getPosition(position,Map2)
			if intersection then
				return Vector3.new(intersection.X, (intersection.Y + offset) * elevationMultiplier, intersection.Z)
			end
		end
		return nil
	end
	
end

function module.addMapToAllMaps(map: any)
	table.insert(allMaps, map)
end

function module.setElevationOffset(o: number)
	offset = o
end

function module.getElevationOffset(): number
	return offset
end

return module