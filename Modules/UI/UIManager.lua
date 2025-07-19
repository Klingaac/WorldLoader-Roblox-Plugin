-- Initialized UI
-- There are two CanvasGroups in Objects.UIObjects, one for light and dark mode
-- If you want to change a UI component, you need to do it in both CanvasGroups
-- God i wish i used some UI framework for this

local PropertiesM = require(script.Parent.PropertiesModule)
local HomeM = require(script.Parent.HomeModule)
local DocumentationM = require(script.Parent.DocumentationModule)
local ColorPicker = require(script.Parent.ColorPicker)

local module = {}
local Objects = script.Parent.Parent.Parent.Objects

function module.start(interface: any,toolbarButton: PluginToolbarButton,mouse: PluginMouse)
	
	local canvas
	local theme = tostring(settings().Studio.Theme)
	
	if theme == "Dark" then
		canvas = Objects.UIObjects.DarkCanvas:Clone()
	else
		canvas = Objects.UIObjects.LightCanvas:Clone()
	end
	
	ColorPicker.enable(canvas,mouse)
	PropertiesM.start(canvas)
	DocumentationM.start(canvas)
	HomeM.start(canvas)

	toolbarButton.Click:Connect(function()
		interface.Enabled = not interface.Enabled
	end)
	
	canvas.Size = UDim2.new(1,0,1,0)

	local menuframe = canvas:WaitForChild("MenuFrame")
	local homeB = menuframe:WaitForChild("Home")
	local propertiesB = menuframe:WaitForChild("Properties")
	local documentationB = menuframe:WaitForChild("Documentation")

	local categories = canvas:WaitForChild("Categories")
	local home = categories:WaitForChild("Home")
	local properties = categories:WaitForChild("Properties")
	local documentation = categories:WaitForChild("Documentation")

	local function invisAllMenus()
		for _,frame in {home,properties,documentation} do
			frame.Visible = false
		end
	end
	
	invisAllMenus()
	home.Visible = true

	homeB.MouseButton1Up:Connect(function()
		invisAllMenus()
		home.Visible = true
	end)

	propertiesB.MouseButton1Up:Connect(function()
		invisAllMenus()
		properties.Visible = true
	end)
	
	documentationB.MouseButton1Up:Connect(function()
		invisAllMenus()
		documentation.Visible = true
	end)
	
	canvas.Parent = interface
	
end

return module