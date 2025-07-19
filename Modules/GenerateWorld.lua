-- Responsible for managin generation of all parts

-- Modules
local Coordinates = require(script.Parent:WaitForChild("Coordinates"))
local WayOperations = require(script.Parent:WaitForChild("WayOperations"))
local SimpleOperations = require(script.Parent:WaitForChild("SimpleOperations"))
local CreatePart = require(script.Parent:WaitForChild("CreatePart"))
local WidgetModule = require(script.Parent:WaitForChild("WidgetModule"))
local UIProperties = require(script.Parent:WaitForChild("UI").PropertiesModule)
local Triangle = require(script.Parent:WaitForChild("Triangle"))
local Elevation = require(script.Parent:WaitForChild("Elevation"))

-- Services
local CS = game:GetService("CollectionService")


local function rN(num: number, numDecimalPlaces: number)
	return tonumber(string.format("%." .. (numDecimalPlaces or 0) .. "f", num))
end


local function GenerateWorld(data: any, offsetVector: Vector2, baseSize: Vector3, basePos: Vector3, elevationMode: string, worldScale: number)

	-- First we need to get GenerationRules and WayProperties
	local GenerationRules = UIProperties.getGenerationRules()
	local WayProperties
	
	local WP_module = script.Parent.Parent.EditableModules:GetChildren()[1]
	local WP = require(WP_module)
	
	local EP = UIProperties.getProperties()
	-- Here i just manually connect editedProperties to WayProperties
	-- Yeah there are probably better ways to do this

	-- Guildings
	for _,tag in {"building","building:part"} do
		local T = WP[tag]["nil"]
		T.disabled = not EP["Building"]["Enabled"]
		T.heightPerFloor = EP["Building"]["Height per floor"]
		T.deafultHeight = EP["Building"]["Deafult Height"]
		T.color = EP["Building"]["Color"]
		T.material = EP["Building"]["Material"]

		WP[tag]["nil"] = T
	end

	-- Roads
	for tag,T in WP["highway"] do

		if tag == "path" or tag == "pedestrian" or tag == "footway" then
			T.disabled = not EP["Road"]["Sidewalk Enabled"]
			T.color = EP["Road"]["Sidewalk Color"]
			T.material = EP["Road"]["Sidewalk Material"]
		elseif tag == "track" then
			T.disabled = not EP["Road"]["Rular Road Enabled"]
			T.color = EP["Road"]["Rular Road Color"]
			T.material = EP["Road"]["Rular Road Material"]
		else
			T.disabled = not EP["Road"]["Road Enabled"]
			T.color = EP["Road"]["Road Color"]
			T.material = EP["Road"]["Road Material"]
		end

		WP["highway"][tag] = T

	end

	-- Rails (pain)
	for _,tag in {"rail","light_rail","tram","disused"} do
		local T = WP["railway"][tag]
		if not T then T = {} end

		T.gauge = EP["Rail"]["Rail Gauge"]

		T.disabled = not EP["Rail"]["Enabled"]
		T.ballast.color = EP["Rail"]["Ballast Color"]
		T.ballast.material = EP["Rail"]["Ballast Material"]
		T.ballast.height = EP["Rail"]["Ballast Height"]
		T.ballast.width = EP["Rail"]["Ballast Width"]

		T.rails.color = EP["Rail"]["Rail Color"]
		T.rails.material = EP["Rail"]["Rail Material"]

		T.ties.ties3D = EP["Rail"]["3D Ties"]
		T.ties.texture = EP["Rail"]["Tie Texture"]
		T.ties.color = EP["Rail"]["Tie Color"]
		T.ties.material = EP["Rail"]["Tie Material"]

		if EP["Rail"]["Rail Mesh"] == true then
			T.rails.mesh = "RealisticRail" 
		else
			T.rails.mesh = "Rail"
		end

		WP["railway"][tag] = T

	end

	for _,tag in {"barrier"} do
		local T = WP[tag]["nil"]

		T.disabled = not EP["Barrier"]["Enabled"]
		T.color = EP["Barrier"]["Color"]
		T.material = EP["Barrier"]["Material"]
		T.height = EP["Barrier"]["Height"]
		T.width = EP["Barrier"]["Width"]

		WP[tag]["nil"] = T
	end

	WayProperties = WP

	-- Creating or repairing OSM folder
	local Corefolder = workspace:FindFirstChild("World")

	if not Corefolder then
		Corefolder = Instance.new("Folder",workspace)
		Corefolder.Name = "World"

		local invalid = Instance.new("Folder",Corefolder)
		invalid.Name = "Invalid"
	end


	local function findParentProperty(dict)
		for key, value in pairs(dict) do
			if type(value) == "table" then
				findParentProperty(value)
			elseif key == "parent" then

				local folder = Corefolder:FindFirstChild(value)
				if not folder then
					folder = Instance.new("Folder",Corefolder)
					folder.Name = value
				end

			end
		end
	end
	findParentProperty(WayProperties)
	
	
	local xOff = offsetVector.X
	local yOff = offsetVector.Y

	local nodes = {}
	local ways = {}
	local relations = {}

	local printableWays = {}

	for i,element in data["elements"] do

		if element["type"] == "node" then

			local lat = element["lat"]
			local lon = element["lon"]

			local id = element["id"]

			data["elements"][i]["v2"] = Coordinates.toRobloxOffset(lat,lon,xOff,yOff)
			nodes[id] = i

		elseif element["type"] == "way" then

			local id = element["id"]
			ways[id] = i

			table.insert(printableWays,element)

		elseif element["type"] == "relation" then

			local id = element["id"]
			relations[id] = i

		end

	end
	

	local Map = data["elevation"]
	local terrain = game.Workspace.Terrain
	local elevationOffset = Elevation.getElevationOffset()
	local elevationMultiplier = GenerationRules["Elevation multiplier"]

	local transform_to_terrain = true

	if elevationMode == "terrain" then

		for a = 1,#Map - 1 do

			task.wait()

			for b = 1,#Map[a] - 1 do
				
				-- When converting triangles to parts, there are visible lines along their edges, makes terrain look less seemless
				-- To fix this, I make them a bit bigger, forcing them to blend together with other triangles
				-- Also add the elevation offset - if someone were to generate mount everest, it will be generated from around the zero Y-level
				
				local v1 = (Map[a][b]["v3"] + Vector3.new(0,elevationOffset,0)) * Vector3.new(1,elevationMultiplier,1) + Vector3.new(worldScale,0,-worldScale)
				local v2 = (Map[a+1][b]["v3"] + Vector3.new(0,elevationOffset,0)) * Vector3.new(1,elevationMultiplier,1) + Vector3.new(worldScale,0,worldScale)
				local v3 = (Map[a][b+1]["v3"]  + Vector3.new(0,elevationOffset,0)) * Vector3.new(1,elevationMultiplier,1) + Vector3.new(-worldScale,0,-worldScale)
				local v4 = (Map[a+1][b+1]["v3"]  + Vector3.new(0,elevationOffset,0)) * Vector3.new(1,elevationMultiplier,1) + Vector3.new(-worldScale,0,worldScale)

				local tris1 = Triangle(workspace.World,v1,v2,v4)
				local tris2 = Triangle(workspace.World,v1,v3,v4)

				if transform_to_terrain then
					for i,Tt in {tris1,tris2} do
						for j,t in Tt do

							t.Color = Color3.new(0.141176, 0.266667, 0.101961)
							t.Material = Enum.Material.Grass
							t.Size = Vector3.new(4,t.Size.Y,t.Size.Z)
							t.Position -= Vector3.new(0,4,0)

							terrain:FillWedge(t.CFrame,t.Size,Enum.Material.Grass)

							t:Destroy()

						end
					end
				end

			end 
		end
	end


	local function getKey(tags: any?)

		if not tags then
			return
		end

		local tableOfProperties = WayProperties
		local properties
		local name

		while true do
			local keyFound

			for key,T in tableOfProperties do

				if tags[key] then

					keyFound = true

					if T[tags[key]] then
						if T[tags[key]].operation then
							properties = T[tags[key]]
							name = tags[key]
						else
							tableOfProperties = T[tags[key]]
						end
					else
						if T["nil"] then
							properties = T["nil"]
							name = "nil"
						else
							return
						end
					end

				end

				if properties then
					break
				end

			end

			if not keyFound then
				return
			end

			if properties then
				break
			end
		end

		return properties,name
	end


	local function GenerateWay(i: number,corners: {CFrame},properties: any)

		-- Variables
		local way = data["elements"][i]
		local wayId = way["id"]

		if not properties or properties["disabled"] then
			return
		end


		if elevationMode ~= "flat" and (properties.operation == "area" or properties.operation == "rail") then
			return
		end

		if properties.operation == "area" and GenerationRules["Areas"] == false then
			return
		end

		-- Checks if it alredy exists
		local addToExistingModel = false
		local duplicates = CS:GetTagged("OSM_id:"..wayId)
		for _,duplicate in duplicates do -- duplicate is always just one
			if duplicate:HasTag("WorldLoaderInProgress") then
				addToExistingModel = true
			else
				return
			end
		end

		-- Creates the model
		local positions = {}
		local model = Instance.new("Model")


		for _,nodeId in way["nodes"] do
			local j = nodes[nodeId]

			if not j then
				continue 
			end

			local v2 = data["elements"][j]["v2"]
			local v3 = Vector3.new(v2.X,0,v2.Y)
			table.insert(positions,v3)
		end


		local tags = way["tags"]
		
		-- WayOperations (with SimpleOperations) do all of the work of creating the visuals
		local parts = WayOperations[properties.operation](tags,model,properties,positions,corners,GenerationRules,data["elevation"],elevationMode)


		if elevationMode == "terrain" then
			if parts and #parts > 0 and properties.operation == "way" then

				for _,part in parts do
					if part:IsA("BasePart") and properties.operation == "way" then
						
						-- Sometimes fails because of invalid cframe or size
						pcall(function()
							terrain:FillBlock(part.CFrame,part.Size + Vector3.new(0,4,0),Enum.Material.Asphalt)
						end)
						
					end
				end

				model:Destroy()
				return true -- Returning something, if i dont return anything then task.wait() doesnt happen, leading to potential crashes

			end
		end


		if not parts or #parts == 0 then
			model:Destroy()
			return
		end

		local children = model:GetChildren()

		-- Sometimes parts spawn with very big negative height, we need to get rid of those
		for _,p in children do
			if p:IsA("BasePart") and p.Position.Y < -100000 then
				p:Destroy()
			end
		end

		if #children == 0 then
			model:Destroy()
			return
		end
		
		if addToExistingModel then --merge this model with model of same OSM way id ("OSM_id:"..number tag)
			
			local newParts = model:GetChildren()
			local originalParts = duplicates[1]:GetChildren()
			for _,newPart: Part in newParts do
				
				local partFound = false
				
				for _,originalPart: Part in originalParts do
					
					if newPart.CFrame:FuzzyEq(originalPart.CFrame, 0.01) then
						partFound = true
						break
					end
					
				end
				
				if partFound then
					newPart:Destroy()
				else
					newPart.Parent = duplicates[1]
				end
			end
			
			model:Destroy()
			return true
			
		else
			if properties.parent then
				model.Parent = Corefolder[properties.parent]
			end
			
			if not model.Parent then
				model.Parent = Corefolder.Invalid
			end
			
			if tags and tags["name"] then
				model.Name = tags.name
			end
		end

		-- OSM_id tag makes sure that everytime we are creating a new object, we can check if it already exists
		-- If it already exists, we check if it has WorldLoaderInPorgress, if yes, we merge those two objects,
		-- if no, the new object gets destroyed
		CS:AddTag(model,"OSM_id:"..wayId)
		CS:AddTag(model,"WorldLoaderInProgress")

		return true
		
	end
	
	
	local corners = {
		basePos + Vector3.new(baseSize.X/2,0,baseSize.Z/2),
		basePos + Vector3.new(baseSize.X/2,0,-baseSize.Z/2),
		basePos + Vector3.new(-baseSize.X/2,0,-baseSize.Z/2),
		basePos + Vector3.new(-baseSize.X/2,0,baseSize.Z/2)
	}

	local iter = 0

	for id,i in ways do

		local tags = data["elements"][i]["tags"]

		--gets the key
		local properties = getKey(tags)

		if not properties then
			continue
		end

		local notSkipped = GenerateWay(i,corners,properties)

		if notSkipped then
			iter += 1
			
			-- If safe mode then give then wait more often
			if iter % 10 == 0 or (GenerationRules["Safe mode"] and iter % 3 == 0) then
				task.wait()
			end
		end

	end
	
	for _,m in CS:GetTagged("WorldLoaderInProgress") do
		m:RemoveTag("WorldLoaderInProgress")
	end
	

	return true

end

return GenerateWorld