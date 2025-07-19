-- Gets Data from apis

-- Modules
local WidgetModule = require(script.Parent.WidgetModule)
local Coordinates = require(script.Parent.Coordinates)
local Triangle = require(script.Parent.Triangle)
local Elevation = require(script.Parent.Elevation)
local CreatePart = require(script.Parent.CreatePart)

-- Services
local HS = game:GetService("HttpService")


local function rN(num: number, numDecimalPlaces: number)
	return tonumber(string.format("%." .. (numDecimalPlaces or 0) .. "f", num))
end


local function getV3(result: any, offsetVector: Vector2, worldScale: number)
	
	local height = result["elevation"]
	local lat = result["location"]["lat"]
	local lon = result["location"]["lng"]

	if not height then
		height = 0
	end

	--convert meters to studs
	height = height * 3.57 * worldScale

	local v2 = Coordinates.toRobloxOffset(lat, lon, offsetVector.X, offsetVector.Y)
	local v3 = Vector3.new(v2.X,height,v2.Y)

	return v3
	
end


local function getOSM(coords: string)

	local url = "https://overpass-api.de/api/interpreter?data=[out:json][timeout:25];"..
		"(node("..coords..");way("..coords..");)->.a;out body;>;out skel qt;"..
		"(rel[!network](bw.a)("..coords.."););out body;"


	local startedHttp = os.clock()

	-- Make the HTTP GET request
	local success, response = pcall(function()
		return HS:GetAsync(url)
	end)

	if not success then
		return
	end

	-- Parse the JSON response
	local data = HS:JSONDecode(response)
	
	local responseSize = rN(string.len(tostring(response))/1000000,3).."MB"
	local responseTime = os.clock()-startedHttp

	return data["elements"], responseSize, responseTime
end


local function getElevation(corners1: {Vector2} ,corners2: {Vector2}, offsetVector: Vector2, loadingWidget: any, centerLat: number, centerLon: number, worldScale: number)
	
	if not workspace:FindFirstChild("World") then
		local world = Instance.new("Folder",workspace)
		world.Name = "World"
	end
	
	
	local startedHttp = os.clock()
	local totalJSONsize = 0
	local totalLocations = 0
	
	local totalChains = 0
	local usedChains = 0

	local elevation = {}

	local resolution = 0.0003
	
	-- The terrain api has a limit of 100 locations per request
	local limitPerUrl = 100
	
	-- The terrain api has a limit of 1 request per second
	local waitInterval = 1.1
	
	local rad_lat = math.rad(corners1[1].X)

	-- Calculate the scale factor using the Mercator projection formula
	-- further from the equator we get, the more stretched out cooridnates become, so we need to correct it
	local scale_factor = 1 / math.cos(rad_lat)
	
	local resLat = resolution
	local resLon = resolution * scale_factor

	-- Get a point in the middle of one of the parts that serves as an offset for all elevations
	local url = "https://api.opentopodata.org/v1/aster30m?locations="
	local centerUrl = url .. tostring(centerLat) .. "," .. tostring(centerLon)
	
	local success, response
	
	while true do
		
		success, response = pcall(function()
			return HS:GetAsync(centerUrl)
		end)
		
		if success then
			break
		else
			warn(response)
		end
		
		task.wait(waitInterval)
		
	end
	
	local centerResponseT = HS:JSONDecode(response)
	local centerV3 = getV3(centerResponseT["results"][1], offsetVector, worldScale)
	local elevationOffset = -centerV3.Y
	
	Elevation.setElevationOffset(elevationOffset+300)
	
	local neededData: {
		{
			longitudes: {number},
			latitudes: {number},
			longitudeChains: {string},
			latitudeChains: {string},
		}
	} = {}
	
	local Maps = {}

	for i = 1, #corners1 do
		
		neededData[i] = { 
			longitudes = {},
			latitudes = {},
			longitudeChains = {},
			latitudeChains = {}
		}
		
		local limit = 0
		local cur = 0
		
		local corner1 = corners1[i]
		local corner2 = corners2[i]
		
		local diffX = corner1.X - corner2.X
		local diffY = corner2.Y - corner1.Y
		
		local nStepsX = math.max(1, math.floor(diffX / resLat + 0.5))
		local stepX = diffX / nStepsX
		local nStepsY = math.max(1, math.floor(diffY / resLon + 0.5))
		local stepY = diffY / nStepsY
		
		for j = 0, nStepsX do
			for k = 0, nStepsY do
				local lat = corner2.X + stepX * j
				local lon = corner1.Y + stepY * k
				
				table.insert(neededData[i].latitudes,lat)
				table.insert(neededData[i].longitudes,lon)
				totalLocations += 1
			end
		end

		local t = {}
		totalChains += 1
		for j,lat in neededData[i].latitudes do
			if (j - 1) % limitPerUrl == 0 and j ~= 1 then
				
				limit += 1
				totalChains += 1
				
				table.insert(neededData[i].latitudeChains,t)
				t = {}
				
			end
			table.insert(t,lat)
		end
		
		table.insert(neededData[i].latitudeChains,t)

		local t = {}
		for j,lon in neededData[i].longitudes do
			if (j - 1) % limitPerUrl == 0 and j ~= 1 then
				table.insert(neededData[i].longitudeChains,t)
				t = {}
			end
			table.insert(t,lon)
		end
		
		table.insert(neededData[i].longitudeChains,t)

	end
	
	
	local balls = {}
	
	for i = 1, #corners1 do
		
		local Legend = {}
		local Map = {}
		
		for j = 1, #neededData[i].latitudeChains do
			
			local latitudes = neededData[i].latitudeChains[j]
			local longitudes = neededData[i].longitudeChains[j]
			
			-- Need to define the url every loop iteration so the old locations get recycled
			local url = "https://api.opentopodata.org/v1/aster30m?locations="

			local n = #latitudes
			for k = 1,n do
			
				local lon = longitudes[k]
				local lat = latitudes[k]

				url = url .. lat .. "," .. lon

				if k ~= n then
					url = url .. "|"
				end
			end

			url = url .. "&interpolation=cubic"


			local success, response
			local failures = 0

			while true do

				-- Make the HTTP GET request
				success, response = pcall(function()
					return HS:GetAsync(url)
				end)

				if success then
					usedChains += 1
					
					local secondsLeft = totalChains - usedChains * 1.1
					local timeLeft
					if secondsLeft > 59 then
						local minutes = math.round(secondsLeft / 60)
						if minutes == 1 then
							timeLeft = tostring(minutes) .. " minute"
						else
							timeLeft = tostring(minutes) .. " minutes"
						end
					else
						timeLeft = "Less than 1 minute"
					end

					loadingWidget:ChangeText("Street data loaded successfully! \n Downloading elevation data... \n "..tostring(usedChains).."/"..tostring(totalChains).. "\n Time left: "..timeLeft)
					break
				else
					failures += 1
					
					if failures > 30 then
						WidgetModule.error("Elevation data failed, try again later")
						return
					end
				end

				task.wait(waitInterval)

			end
			

			if success then

				totalJSONsize += string.len(response)

				response = HS:JSONDecode(response)

				for _,result in response["results"] do
					local height = result["elevation"]
					local lat = result["location"]["lat"]
					local lon = result["location"]["lng"]

					if not height then
						height = 0
					end

					-- Convert meters to studs
					height = height * 3.57 * worldScale

					local v2 = Coordinates.toRobloxOffset(lat, lon, offsetVector.X, offsetVector.Y)
					local v3 = Vector3.new(v2.X,height,v2.Y)


					if not Legend[tostring(lat)] then
						local newIndex = #Map + 1
						Legend[tostring(lat)] = newIndex
						Map[newIndex] = {}
					end
					local index = Legend[tostring(lat)]
					table.insert(Map[index],{
						["lat"] = lat,
						["lon"] = lon,
						["v3"] = v3
					})

					-- Visualization for debuging purposes
					local visualize = false
					
					if visualize then
						
						local part = Instance.new("Part")
						part.Shape = "Ball"
						part.Size = Vector3.new(20,20,20)
						part.Color = Color3.new(0.180392, 0.639216, 0.121569)
						part.Position = v3
						part.Anchored = true
						part.Parent = workspace.World

						table.insert(balls,part)
						
					end

				end
			end
			
		end
		
		table.insert(Maps, Map)
		
	end
	
	for _,part: Part in balls do
		part:Destroy()
	end
	
	local responseSize = rN(totalJSONsize/1000000,3).."MB"
	local responseTime = os.clock()-startedHttp
	

	return Maps, responseTime
end


local function getData(corners1: {Vector2}, corners2: {Vector2}, offsetVector: Vector2, elevationMode: string, centerLat: number, centerLon: number, worldScale: number)
	
	-- Initializing the loading widget
	local loadingWidget = WidgetModule.loading("Downloading street data...")
	local datas = {}
	
	local totalElevationResponseTime = 0
	local totalStreetResponseTime = 0
	
	for i = 1, #corners1 do
		
		local corner1 = corners1[i]
		local corner2 = corners2[i]
		
		local coords = tostring(rN(corner2.X,3))..","..tostring(rN(corner1.Y,3))..","..tostring(rN(corner1.X,3))..","..tostring(rN(corner2.Y,3))
		
		local elements, SresponseSize, SresponseTime = getOSM(coords)
		if elements then
			totalStreetResponseTime += SresponseTime
		end

		if not elements then
			loadingWidget:Kill()	
			WidgetModule.error("Failed to get Street data")
			return
		end
		
		datas[i] = {
			elements = elements
		}
		
	end
	
	-- Elevation data
	loadingWidget:ChangeText("Street data loaded successfully! \n Downloading elevation data...")

	if elevationMode ~= "flat" then

		local elevations, EresponseTime = getElevation(corners1, corners2, offsetVector, loadingWidget, centerLat, centerLon, worldScale)
		if elevations then
			totalElevationResponseTime += EresponseTime
		end

		if not elevations then
			loadingWidget:Kill()
			WidgetModule.error("Failed to get Elevation data")
			return
		end

		for i,el in elevations do
			datas[i].elevation = el
		end

	end
	
	if elevationMode == "flat" then
		loadingWidget:FinishLoading("Data loaded successfully! \n  Street Data: "..rN(totalStreetResponseTime,3).."s")
	else
		loadingWidget:FinishLoading("Data loaded successfully! \n  Street Data: "..rN(totalStreetResponseTime,3).."s \n Elevation Data: "..rN(totalElevationResponseTime,3).."s")
	end
	

	for _,data in datas do
		if data.elevation then
			Elevation.addMapToAllMaps(data.elevation)
		end
	end
	
	return datas
end

return getData


--[[
	
	--CURRENT overpass turbo prompt, KEEP IT HERE
	
	[out:json][timeout:25];
	(node({{bbox}});
	way({{bbox}});
	)->.a;
	out body;>;out skel qt;
	(rel[!network](bw.a)({{bbox}}););out body;
	
	
	--Old urls:
	
	local url = "https://overpass-api.de/api/interpreter?data=[out:json];(node("..coords..");way("..coords.."););out body;"
	local url = "https://overpass-api.de/api/interpreter?data=[out:json];(way("..coords.."););out body;"

]]

