-- Controls the properties tab of UI

local module = {}

local Objects = script.Parent.Parent.Parent.Objects
local Presets = require(script.Parent:WaitForChild("Presets"))
local WidgetModule = require(script.Parent.Parent.WidgetModule)
local plugin = script:FindFirstAncestorWhichIsA("Plugin")

local HS = game:GetService("HttpService")

-- Divider value, properties are in meters, 1 stud is 0.28cm so we do property/D to determine it in studs 
local D = 0.28

local ItemTypes = {
	["Material"] = {"Plastic","SmoothPlastic","Neon","Wood","WoodPlanks","Marble","Slate","Concrete","Granite","Brick","Pebble","Cobblestone","CorrodedMetal","DiamondPlate","Foil","Metal","Grass","Sand","Fabric","Ice"},
	["Tie Texture"] = {"ConcreteTies","WoodenTies"},
}

local actions = {}

for key,T in Presets do
	actions[key] = {}
end


local theme = tostring(settings().Studio.Theme)
local checkboxBorderColor = Color3.new(1,1,1)
if theme == "Light" then
	checkboxBorderColor = Color3.new(0,0,0)
end


function module.start(canvas: CanvasGroup)

	local categories = canvas:WaitForChild("Categories")
	local properties = categories:WaitForChild("Properties")

	local ColorPickerModule = require(script.Parent.ColorPicker)
	local colorPicker = ColorPickerModule.new()

	local propertyFrames = {properties.Building,properties.Rail,properties.Road,properties.Barrier,properties["Generation Rules"]}
	

	local function setCheckbox(button: Instance ,value: boolean)
		local box = button.Box

		if value == false then
			box.UIStroke.Color = checkboxBorderColor
			box.BackgroundTransparency = 1
			box.Image.ImageTransparency = 1
		else
			box.UIStroke.Color = Color3.new(0)
			box.BackgroundTransparency = 0
			box.Image.ImageTransparency = 0
		end
	end


	local function enable(object: Instance,bool: boolean)
		if bool == true then
			object.Transparency = 0
		else
			object.Transparency = 1
		end
	end


	local function updateViewport(frame: Frame)

		local viewport = frame:FindFirstChild("ViewportFrame")
		
		if not viewport then
			return
		end

		local T = actions[frame.Name]

		if frame.Name == "Building" then

			for _,child in viewport.Building:GetChildren() do

				enable(child,T["Enabled"])

				local oldY = child.Position.Y
				child.Position = Vector3.new(child.Position.X,oldY-child.Size.X/2+(T["Deafult Height"]/D)/2,child.Position.Z)
				child.Size = Vector3.new(T["Deafult Height"]/D,child.Size.Y,child.Size.Z)

				child.Material = T["Material"]
				child.Color = T["Color"]

			end

		elseif frame.Name == "Road" then

			local m = viewport.Model 

			m.Road.Color = T["Road Color"]
			m.Road.Material = T["Road Material"]
			enable(m.Road,T["Road Enabled"])

			m.Sidewalk.Color = T["Sidewalk Color"]
			m.Sidewalk.Material = T["Sidewalk Material"]
			enable(m.Sidewalk,T["Sidewalk Enabled"])

			m.Rural.Color = T["Rural Road Color"]
			m.Rural.Material = T["Rural Road Material"]
			enable(m.Rural,T["Rural Road Enabled"])

		elseif frame.Name == "Rail" then

			local m = viewport.Model 

			local ballast = m.Ballast
			local dist = ballast.Size.Z
			local gauge = T["Rail Gauge"]/D

			local tieHeight = .1/D -- dont use in texture ties
			local tieWidth = .4/D -- google said that ties are 9 inches long but this looks better
			local tiesWidth = gauge*2

			ballast.Color = T["Ballast Color"]
			ballast.Material = T["Ballast Material"]
			ballast.Size = Vector3.new(T["Ballast Width"]/D,T["Ballast Height"]/D,dist)
			enable(ballast,T["Enabled"])

			local offset = gauge/2
			local railSize = Vector3.new(0.2/D,0.2/D, dist)


			if T["3D Ties"] == false then
				tieHeight = 0
			end


			for i = -offset,offset,offset*2 do

				local j = -i/offset
				local k = 1; if i > 0 then k = 2 end

				local rail = m.Rails:GetChildren()[k]
				local railCfrm = ballast.CFrame * CFrame.new(i+(j*-1*railSize.X/2),railSize.Y/2 + ballast.Size.Y/2 + tieHeight,0)
				rail.CFrame = railCfrm
				rail.Color = T["Rail Color"]
				rail.Material = T["Rail Material"]

				enable(rail,T["Enabled"])

				if T["Rail Mesh"] == true then
					if not rail:FindFirstChild("RealisticRail") then

						local mesh = Objects.Assets.Meshes.RealisticRail:Clone()
						mesh.Parent = rail
						mesh.Scale = railSize
						mesh.Offset = Vector3.new(0,0,0)

					end
				else
					if rail:FindFirstChild("RealisticRail") then
						rail:FindFirstChild("RealisticRail"):Destroy()
					end
				end

			end

			m.TieTexturePart.Size = Vector3.new(T["Ballast Width"]/D*0.6,.02,dist)
			m.TieTexturePart.Position = ballast.Position + Vector3.new(0,ballast.Size.Y/2,0)

			for _,child in m.TieTexturePart:GetChildren() do child:Destroy() end --removing the texture

			local texture = Objects.Assets.Textures[T["Tie Texture"]]:Clone()
			texture.Face = "Top"
			texture.StudsPerTileU = tiesWidth
			texture.StudsPerTileV = tiesWidth*.4
			texture.Parent = m.TieTexturePart

			if T["3D Ties"] then
				texture.Transparency = 1
			else
				texture.Transparency = 0
			end

			for _,tie: Part in m.Ties:GetChildren() do
				tie.Material = T["Tie Material"]
				tie.Color = T["Tie Color"]
				tie.Size = Vector3.new(tiesWidth,tieHeight,tieWidth)

				if T["3D Ties"] == false or T["Enabled"] == false then
					enable(tie,false)
				else
					enable(tie,true)
					tie.Position = Vector3.new(tie.Position.X,ballast.Position.Y + ballast.Size.Y/2 + tie.Size.Y/2,tie.Position.Z)
				end
			end

		elseif frame.Name == "Barrier" then

			local b = frame.ViewportFrame.Fence
			b.Color = T["Color"]
			b.Material = T["Material"]

			local oldY = b.Position.Y
			local h = T["Height"]
			b.Position = Vector3.new(b.Position.X,oldY-b.Size.Y/2+(h/D)/2,b.Position.Z)
			b.Size = Vector3.new(T["Width"]/D,h/D,b.Size.Z)

			enable(b,T["Enabled"])

		end

	end


	local function loadPreset(frame: Frame,T)

		local buttonFrame = frame.ButtonFrame

		for _,button in buttonFrame:GetChildren() do
			if not button:IsA("TextButton") then
				continue
			end 


			local action = button:GetAttribute("Action")

			actions[frame.Name][action] = T[action]


			if button.Name == "CheckBox" then
				setCheckbox(button,T[action])
			elseif button.Name == "ColorBox" then
				button.Box.BackgroundColor3 = T[action]
			elseif button.Name == "TextBox" then
				button.TextBox.Text = T[action]
			end

		end

		updateViewport(frame)
	end


	local function loadPresetMenu(frame: Frame,T)
		
		if not frame:FindFirstChild("PresetFrame") then
			return
		end
		
		for _,preset in T do
			local button = Instance.new("TextButton")
			button.Text = preset["Preset Name"]
			button.Size = UDim2.new(1,0,0,25)

			if theme == "Dark" then
				button.TextColor = BrickColor.new("Institutional white")
				button.BackgroundColor3 = Color3.fromRGB(48, 50, 58)
			else
				button.TextColor = BrickColor.new("Really black")
				button.BackgroundColor3 = Color3.fromRGB(239, 239, 239)
			end


			local uicorner = Instance.new("UICorner")
			uicorner.CornerRadius = UDim.new(0,8)
			uicorner.Parent = button

			button.MouseButton1Up:Connect(function()
				loadPreset(frame,preset)
			end)
			
			button.Parent = frame.PresetFrame
		end
	end


	local function getBlurFrame()
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


	local function getItemBox(frame: Frame,curElement: string?,action: string,array: any,buttonPx: number)

		local blurFrame = getBlurFrame()

		local itembox = canvas.Itemlist:Clone()
		if theme == "Light" then
			itembox.BackgroundColor3 = Color3.new(0.937255, 0.937255, 0.937255)
		end

		for i,element in array do
			local b = Instance.new("TextButton")
			b.Size = UDim2.new(1,0,0,buttonPx)
			b.BackgroundTransparency = 1
			b.TextColor = BrickColor.new(255,255,255)
			b.Text = element
			b.TextXAlignment = "Left"
			b.RichText = true
			b.ZIndex = 40
			b.Parent = itembox

			if theme == "Light" then
				b.TextColor = BrickColor.new(0,0,0)
			end

			if element == curElement then
				b.Text = "<font color='rgb(43, 177, 255)'>"..b.Text.."</font>"
			end

			b.MouseEnter:Connect(function()
				b.BackgroundTransparency = .7
			end)
			b.MouseLeave:Connect(function()
				b.BackgroundTransparency = 1
			end)

			b.MouseButton1Up:Connect(function()
				actions[frame.Name][action] = element

				updateViewport(frame)

				blurFrame:Destroy()
				itembox:Destroy()

			end)

		end

		local s = math.min(buttonPx*#array,canvas.AbsoluteSize.Y-130)

		itembox.Size = UDim2.new(0.8,0,0,s)
		itembox.CanvasSize = UDim2.new(0,0,0,buttonPx*#array)
		itembox.Position = UDim2.new(0.5,0,0.5,0)
		itembox.Visible = true
		itembox.ZIndex = 30
		itembox.Parent = canvas

		blurFrame.MouseButton1Up:Connect(function()
			blurFrame:Destroy()
			itembox:Destroy()
		end)

	end
	

	for _,frame in propertyFrames do

		local buttonFrame = frame.ButtonFrame
		local labelFrame = frame.LabelFrame
		local viewport = frame:FindFirstChild("ViewportFrame")
		
		loadPresetMenu(frame,Presets[frame.Name])
		loadPreset(frame,Presets[frame.Name][1])

		if viewport then
			
			viewport.Button.MouseButton1Up:Connect(function()

				local newport = viewport:Clone()
				newport.MaxImage:Destroy()
				newport.AnchorPoint = Vector2.new(0.5,0.5)
				newport.ZIndex = 30

				local s = canvas.AbsoluteSize.X
				newport.Size = UDim2.new(0,s*0.9,0,s*0.9)
				newport.Position = UDim2.new(0.5,0,0.5,0)
				newport.Parent = canvas

				local blurFrame = getBlurFrame()

				local function close()
					blurFrame:Destroy()
					newport:Destroy()
				end

				blurFrame.MouseButton1Up:Connect(close)
				newport.Button.MouseButton1Up:Connect(close)

			end)
		end


		for _,button in buttonFrame:GetChildren() do
			if not button:IsA("TextButton") then
				continue
			end 

			local action = button:GetAttribute("Action")


			if button.Name == "TextBox" then

				local textbox = button.TextBox

				textbox.Text = actions[frame.Name][action]

				textbox.FocusLost:Connect(function()
					if tonumber(textbox.Text) then
						actions[frame.Name][action] = textbox.Text
						updateViewport(frame)
					else
						textbox.Text = actions[frame.Name][action]
					end
				end)

			elseif button.Name == "CheckBox" then

				local box = button.Box

				setCheckbox(button,actions[frame.Name][action])

				button.MouseButton1Up:Connect(function()
					setCheckbox(button,not actions[frame.Name][action])

					actions[frame.Name][action] = not actions[frame.Name][action]

					updateViewport(frame)
				end)

			elseif button.Name == "ItemBox" then

				button.MouseButton1Up:Connect(function()
					local array = ItemTypes[button:GetAttribute("ItemType")]
					local curElement = actions[frame.Name][action]

					getItemBox(frame,curElement,action,array,30)

				end)

			elseif button.Name == "ColorBox" then

				button.Box.BackgroundColor3 = actions[frame.Name][action]

				button.MouseButton1Up:Connect(function()

					local blurframe = getBlurFrame()

					colorPicker:SetColor(actions[frame.Name][action])
					colorPicker:Start()
					local color: Color3 = colorPicker.Closed:Wait()
					button.Box.BackgroundColor3 = color
					actions[frame.Name][action] = color

					blurframe:Destroy()

					updateViewport(frame)
				end)

			end

		end

		
		updateViewport(frame)

	end


	--Saving & Loading
	local SaveLoadFrame = properties.SaveLoad

	local savebox = SaveLoadFrame.SaveBox
	local savebutton = SaveLoadFrame.SaveButton
	local loadbutton = SaveLoadFrame.LoadButton

	local PropertySaves = plugin:GetSetting("PropertySaves")
	if not PropertySaves or type(PropertySaves) ~= "string" then
		PropertySaves = {}
		plugin:SetSetting("PropertySaves", HS:JSONEncode({}))
	else
		PropertySaves = HS:JSONDecode(PropertySaves)
	end

	local function findInSaves(T)
		for i,H in PropertySaves do
			if T[1] == H[1] then
				return i
			end
		end
	end

	local function colorToT(color: Color3)
		return {color.R,color.G,color.B}
	end

	local function TToColor(T: {number})
		return Color3.new(T[1],T[2],T[3])
	end


	local function save(name: string)

		local function deepCopy(original)
			local copy = {}
			for k, v in pairs(original) do
				if type(v) == "table" then
					v = deepCopy(v)
				end
				copy[k] = v
			end
			return copy
		end

		local editedActions = deepCopy(actions)

		for key,T in editedActions do
			for k,v in T do
				if typeof(v) == "Color3" then
					T[k] = colorToT(v)
				end
			end
			editedActions[key] = T
		end


		local date = os.date()

		local T = {name, date, editedActions}
		

		local index = findInSaves(T)

		if index then

			WidgetModule.error("Save with the name '"..name.."' alredy exists!")

		else

			table.insert(PropertySaves,T)

		end

		plugin:SetSetting("PropertySaves",HS:JSONEncode(PropertySaves))



	end

	savebutton.MouseButton1Up:Connect(function()
		local name = tostring(savebox.Text)
		if not name or name == "" then
			WidgetModule.error("Name the Save")
			return
		end

		save(name)
	end)

	loadbutton.MouseButton1Up:Connect(function()

		PropertySaves = plugin:GetSetting("PropertySaves")
		PropertySaves = HS:JSONDecode(PropertySaves)

		--yes, its definitly not good to load and decode propertysaves everytime when loading, but i didnt get it to work the other way

		if #PropertySaves == 0 then
			WidgetModule.error("No property saves found!")
			return
		end

		local buttonPx = 30
		local array = PropertySaves

		local blurFrame = getBlurFrame()

		local itembox = canvas.Itemlist:Clone()
		if theme == "Light" then
			itembox.BackgroundColor3 = Color3.new(0.937255, 0.937255, 0.937255)
		end

		for i,element in array do
			local b = Instance.new("TextButton")
			b.Size = UDim2.new(1,0,0,buttonPx)
			b.BackgroundTransparency = 1
			b.TextColor = BrickColor.new(255,255,255)
			b.Text = "<b>"..array[i][1].."</b>".."\n"..array[i][2]
			b.TextXAlignment = "Left"
			b.RichText = true
			b.ZIndex = 40
			b.Parent = itembox
			b.RichText = true

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
				actions = array[i][3]

				for key,T in actions do
					for k,v in T do
						if type(v) == "table" and #v == 3 then
							T[k] = TToColor(v)
						end
					end
					actions[key] = T
				end

				for _,frame in propertyFrames do
					
					--older saves dont include generation rules
					if not actions[frame.Name] and frame.Name == "Generation Rules" then
						actions[frame.Name] = Presets[frame.Name][1]
						continue
					end
					loadPreset(frame,actions[frame.Name])

					updateViewport(frame)
				end

				blurFrame:Destroy()
				itembox:Destroy()

			end)

		end

		local s = math.min(buttonPx*#array,canvas.AbsoluteSize.Y-130)

		itembox.Size = UDim2.new(0.8,0,0,s)
		itembox.CanvasSize = UDim2.new(0,0,0,buttonPx*#array)
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

function module.getGenerationRules()
	return actions["Generation Rules"]
end

function module.getProperties()
	return actions
end

return module
