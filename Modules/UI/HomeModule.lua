-- Controls home tab of gui, here the user input all basic data, downloads generation data
-- and generates

local module = {}

local maxHistory = 100

-- Modules
local modules = script.Parent.Parent
local Coordinates = require(modules.Coordinates)
local WidgetModule = require(modules.WidgetModule)
local GetData = require(modules.GetData)
local GenerateWorld = require(modules.GenerateWorld)

local theme = tostring(settings().Studio.Theme)
local Objects = script.Parent.Parent.Parent.Objects

local SE = game:GetService("Selection")
local plugin = script:FindFirstAncestorWhichIsA("Plugin")


local History = plugin:GetSetting("GenerationHistory")
if not History then
	History = {}
end


local function rN(num, numDecimalPlaces)
	return tonumber(string.format("%." .. (numDecimalPlaces or 0) .. "f", num))
end


local function splitLonLat(s: string)
	local comma = string.find(s,",")
	if not comma then return end

	local lat = tonumber(string.sub(s,1,comma-1))
	local lon = tonumber(string.sub(s,comma+1,string.len(s)))

	if not lon or not lat then
		return nil
	else
		return lat,lon
	end
end



local function Address(data)

	for _,e in data["elements"] do

		local t = e["tags"]

		if not t then
			continue
		end

		if t["addr:city"] and t["addr:country"] then

			local place = t["addr:suburb"] or t["addr:place"] or ""

			local address = t["addr:country"]..", "..t["addr:city"]..", "..place

			return address

		end

	end

	return "No Name"

end


local function findInHistory(T)
	for i,H in History do
		if T[3] == H[3] and T[4] == H[4] then --only comparing the scale and coords
			return i
		end
	end
end


local function saveToHistory(address: string, latLon: string, scale: number, elevationMode: string)

	local date = os.date()

	local T = {address, date, latLon, scale, elevationMode}

	local index = findInHistory(T)

	if index then

		local newHistory = {}

		for i,H in History do
			if i ~= index then
				table.insert(newHistory,H)
			end
		end

		table.insert(newHistory,T)
		History = newHistory

	else

		if #History >= maxHistory then

			local newHistory = {}

			for i = 2,#History do
				table.insert(newHistory,History[i])
			end

			table.insert(newHistory,T)
			History = newHistory

		else
			table.insert(History,T)
		end

	end

	plugin:SetSetting("GenerationHistory",History)

end


local function getBlurFrame(canvas: CanvasGroup)
	local blurFrame = Instance.new("TextButton")
	blurFrame.Text = ""
	blurFrame.BackgroundColor3 = Color3.new(0)
	blurFrame.Transparency = .3
	blurFrame.Size = UDim2.new(1,0,1,0)
	blurFrame.ZIndex = 20
	blurFrame.AutoButtonColor = false
	blurFrame.Parent = canvas
	return blurFrame
end



function module.start(canvas: CanvasGroup)

	local categories = canvas:WaitForChild("Categories")
	local home = categories:WaitForChild("Home")

	local dataFrame = home:WaitForChild("DataFrame")
	local downgenframe = dataFrame:WaitForChild("DownloadGenerateFrame")
	local GenerateButton = downgenframe:WaitForChild("Generate")
	local DownloadButton = downgenframe:WaitForChild("Download")

	local scaleBox = dataFrame:WaitForChild("Scale")
	local LatLonBox = dataFrame:WaitForChild("LatLon")
	local HistoryButton = dataFrame:WaitForChild("History")
	local ElevationButton = dataFrame:WaitForChild("Elevation")
	local dataLabel = dataFrame:WaitForChild("DataLabel")

	local lat,lon = splitLonLat(LatLonBox.Text)
	local scale = tonumber(scaleBox.Text)
	local elevationMode = "flat" --flat/elevation/terrain

	LatLonBox.FocusLost:Connect(function()
		lat,lon = splitLonLat(LatLonBox.Text)
	end)

	scaleBox.FocusLost:Connect(function()
		scale = tonumber(scaleBox.Text)
	end)


	local datas = {}
	local baseSizes = {}
	local basePositions = {}
	local offsetVector


	DownloadButton.MouseButton1Click:Connect(function()

		if not scale then
			scale = 1
		end


		if not lat or not lon then
			WidgetModule.error("Latitude and/or Longtitude missing or in invalid format (ex.: 48.150, 17.117)")
			return
		end


		Coordinates.newScaler(scale,lat)
		offsetVector = Coordinates.toRoblox(lat,lon)

		datas = {}
		baseSizes = {}
		basePositions = {}

		local selected = SE:Get()

		local function warnUser(text: string)
			local widget, event: RBXScriptSignal = WidgetModule.warnToContinue(text)
			local wishToContinue = event:Wait()

			if wishToContinue then
				return true
			end
		end


		if #selected == 0 then
			WidgetModule.error("No parts selected!")
			return
		end


		local maxSelected = 10

		if #selected > maxSelected then
			local msg = "Too many parts selected, generating on many parts can lead to Studio crashing."..
				"It is recommended to generate on max. 10 parts at once. Do you wish to continue?"
			local cont = warnUser(msg)
			
			if not cont then 
				return
			end
		end


		for _,part in selected do
			if not part:IsA("BasePart") then
				WidgetModule.error("'".. part.Name .."' is not a part, only Parts must be selected!")
				return
			end
		end


		local sizeTooSmall = 100

		for _,part in selected do
			
			local cont = true
			
			if part.Size.X < sizeTooSmall or part.Size.Z < sizeTooSmall then
				cont = warnUser("Selected part '".. part.Name .."' may be too small. Do you wish to continue?")
			end
			
			if not cont then
				return
			end
			
			cont = true
			
			if part.Orientation ~= Vector3.new(0,0,0) then
				cont = warnUser("Selected part '".. part.Name .."' must have orientation 0,0,0. Its orientation will be corrected, but generation may happen outside of the part's boundaries. Do you wish to continue?")
			end

			if not cont then
				return
			end
		end

		local corners1 = {}
		local corners2 = {}

		for _,base in selected do

			if base.Orientation ~= Vector3.new(0,0,0) then
				base.CFrame = CFrame.new(base.Position)
			end

			local baseSize = base.Size
			local basePos = base.Position

			table.insert(baseSizes, baseSize)
			table.insert(basePositions, basePos)

			local corner1 = Coordinates.toLatLon(offsetVector.X+base.Position.X+base.Size.X/2,offsetVector.Y+base.Position.Z+base.Size.Z/2)
			local corner2 = Coordinates.toLatLon(offsetVector.X+base.Position.X-base.Size.X/2,offsetVector.Y+base.Position.Z-base.Size.Z/2)

			table.insert(corners1, corner1)
			table.insert(corners2, corner2)

		end

		local timeToLoad = 0
		local res = 0.003
		for i = 1, #corners1 do
			local c1 = corners1[i]
			local c2 = corners2[i]
			timeToLoad += (math.abs(c1.X - c2.X) / res) * (math.abs(c1.Y - c2.Y) / res) / 100 * 1.1
		end


		-- Gets needed elevation and street data
		datas = GetData(corners1 ,corners2, offsetVector, elevationMode, lat, lon, scale)

		if not datas then
			offsetVector = nil
			datas = {}
			return
		end	


		local adress

		-- Find adress
		for _,data in datas do
			adress = Address(data)
			if not adress or adress == "No Name" then
				continue
			else
				break
			end
		end


		saveToHistory(adress,lat..", "..lon,scale,elevationMode)
		Objects.Values.Scale.Value = scale
		dataLabel.Text = adress

	end)


	GenerateButton.MouseButton1Click:Connect(function()

		if #datas == 0 then
			WidgetModule.error("Download data first!")
			return
		end

		-- Nice lil loading widget
		local loadingWidget = WidgetModule.loading("Generating...")

		-- Generating
		local startedGenerating = os.clock()

		for i,data in datas do

			local baseSize = baseSizes[i]
			local basePos = basePositions[i]

			if elevationMode ~= "flat" and data["elevation"] == nil then
				WidgetModule.error("You switched your Elevation mode without downloading new data. Download data again!")
				return
			end

			local WayPropertiesModule = script.Parent.Parent.Parent.EditableModules:GetChildren()
			local IsWayPropertiesFunctioning = pcall(function() require(WayPropertiesModule[1]) end)

			if not IsWayPropertiesFunctioning then
				WidgetModule.error("Your custom module inside EditableModules hasn't been found or loaded correctly!")
			end


			local success, response = pcall(function()
				-- This is where the magic happens
				return GenerateWorld(data, offsetVector, baseSize, basePos, elevationMode, scale)
			end)

			if not success then
				local errorWidget = WidgetModule.error("An unexpected error occured! Screenshot the Output and send the picture here:".."\n https://discord.gg/NA8feHSMut")
				errorWidget.interface.widget.TextLabel.TextXAlignment = Enum.TextXAlignment.Left
				error(response)
			end

		end

		loadingWidget:FinishLoading("Generating successful! (".. rN(os.clock()-startedGenerating,3) ..")")

	end)


	HistoryButton.MouseButton1Click:Connect(function()

		local elevationModePairs = {
			["flat"] = "Flat",
			["elevation"] = "Elevation Only",
			["terrain"] = "terrain",
		}

		if #History == 0 then
			WidgetModule.error("History Empty")
			return
		end

		local blurFrame = getBlurFrame(canvas)

		local itembox = canvas.Itemlist:Clone()
		if theme == "Light" then
			itembox.BackgroundColor3 = Color3.fromRGB(243, 243, 243)
		end

		local height = 60


		for i = #History,1,-1 do
			local T = History[i]

			local b = Instance.new("TextButton")
			b.Size = UDim2.new(1,0,0,height)
			b.BackgroundTransparency = 1
			b.TextColor = BrickColor.new(255,255,255)
			b.TextXAlignment = "Left"
			b.ZIndex = 40
			b.Parent = itembox
			b.RichText = true

			if theme == "Light" then
				b.TextColor = BrickColor.new(0,0,0)
			end

			--as the elevation feature is new, not all profiles are gona have it
			local savedElevationMode = T[5]
			if not T[5] then
				T[5] = "flat"
			end

			b.Text = "<b>"..T[1].."</b>".."\n"..T[2].."\n".."Coordinates: "..T[3].."\n".."Scale: "..T[4]..", Elevation: "..elevationModePairs[T[5]]

			b.MouseEnter:Connect(function()
				b.BackgroundTransparency = .7
			end)
			b.MouseLeave:Connect(function()
				b.BackgroundTransparency = 1
			end)

			b.MouseButton1Up:Connect(function()
				LatLonBox.Text = T[3]
				scaleBox.Text = T[4]
				ElevationButton.Text = "Elevation: "..elevationModePairs[T[5]]

				lat,lon = splitLonLat(T[3])
				scale = T[4]
				elevationMode = T[5]

				blurFrame:Destroy()
				itembox:Destroy()
			end)
		end

		local s = math.min(#History*height,canvas.AbsoluteSize.Y-130)

		itembox.Size = UDim2.new(0.8,0,0,s)
		itembox.CanvasSize = UDim2.new(0,0,0,#History*height)
		itembox.Position = UDim2.new(0.5,0,0.5,0)
		itembox.Visible = true
		itembox.ZIndex = 30
		itembox.Parent = canvas

		blurFrame.MouseButton1Up:Connect(function()
			blurFrame:Destroy()
			itembox:Destroy()
		end)
	end)


	ElevationButton.MouseButton1Click:Connect(function()

		local blurFrame = getBlurFrame(canvas)

		local itembox = canvas.Itemlist:Clone()
		if theme == "Light" then
			itembox.BackgroundColor3 = Color3.fromRGB(243, 243, 243)
		end

		local height = 60

		local modes = {
			"flat",
			"elevation",
			"terrain",
		}

		local fullNames = {
			"Flat",
			"Elevation Only",
			"Terrain",
		}

		local Descriptions = {
			"<b>Flat</b> - original mode, no terrain, no elevation, can generate areas",
			"<b>Elevation only</b> - no terrain and areas, everything else spawns with correct elevation",
			"<b>Terrain</b> - uses Roblox terrain, roads also become terrain, only generates Buildings and rails",
		}

		for i = 1, 3 do
			local description = Descriptions[i]

			local b = Instance.new("TextButton")
			b.Size = UDim2.new(1,0,0,height)
			b.BackgroundTransparency = 1
			b.TextColor = BrickColor.new(255,255,255)
			b.TextXAlignment = "Left"
			b.ZIndex = 40
			b.Parent = itembox
			b.TextWrapped = true
			b.RichText = true

			b.Text = description

			if theme == "Light" then
				b.TextColor = BrickColor.new(0,0,0)
			end

			b.MouseEnter:Connect(function()
				b.BackgroundTransparency = .7
			end)
			b.MouseLeave:Connect(function()
				b.BackgroundTransparency = 1
			end)

			b.MouseButton1Up:Connect(function()
				elevationMode = modes[i]
				ElevationButton.Text = "Elevation: "..fullNames[i]

				blurFrame:Destroy()
				itembox:Destroy()
			end)

		end

		local s = math.min(3*height,canvas.AbsoluteSize.Y-130)

		itembox.Size = UDim2.new(0.8,0,0,s)
		itembox.CanvasSize = UDim2.new(0,0,0,3*height)
		itembox.Position = UDim2.new(0.5,0,0.5,0)
		itembox.Visible = true
		itembox.ZIndex = 30
		itembox.Parent = canvas

		blurFrame.MouseButton1Up:Connect(function()
			blurFrame:Destroy()
			itembox:Destroy()
		end)
	end)

end

return module
