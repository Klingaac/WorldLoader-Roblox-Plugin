-- OpenStreetMaps Loader, used for accurate 1:1 real world generation, but also Ro-scale
-- Started 5/oct/24
-- Last updated 27/nov/25
-- By Klingaac (@klingac on discord)


--		      |\      _,,,---,,_
--		ZZZzz /,`.-'`'    -.  ;-;;,_
--		     |,4-  ) )-,_. ,\ (  `'-'
--			'---''(_/--'  `-'\_)  


-- If you are looking for editing visuals of generated parts, look into WayProperties in EditableModules Folder

-- Api Data provides (all free of charge):
--	https://www.openstreetmap.org/copyright
--	https://api.opentopodata.org

-- Libraries / Atributions:
--	ColorPicker by Brambus230605: https://devforum.roblox.com/t/2772473
--	Kitty art by Felix Lee
--	Polygon triangulation code: https://2dengine.com/doc/polygons.html

------------------------------------------------------------------------------------------------

local ver = "1.3.3"

-- Plugin Setup
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Selection = game:GetService("Selection")

local toolbar = plugin:CreateToolbar("WorldLoader")
local toolbarButton = toolbar:CreateButton("Open",ver.." by Klingac","rbxassetid://78133964354631")

-- Plugin UI setup
local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float,
	false,
	false,
	360,
	450,
	300,
	400
)

local interface = plugin:CreateDockWidgetPluginGui(
	"WorldLoader",
	widgetInfo
)

interface.Title = "WorldLoader "..ver
interface.Name = "WorldLoader Core"

-- Modules
local Modules = script.Parent.Modules
local UI = require(Modules.UI.UIManager)

-- Plugin UI setup
UI.start(interface,toolbarButton,plugin:GetMouse())

plugin:Activate(false)
local mouse = plugin:GetMouse()

local widgetFocused = false

interface.WindowFocusReleased:Connect(function()
	widgetFocused = false
end)
interface.WindowFocused:Connect(function()
	widgetFocused = true
end)

local mousePosVal = script.Parent.Objects.Values.MousePos

-- Mouse position for ColorPicker
game:GetService("RunService").RenderStepped:Connect(function()
	if widgetFocused then
		local mouseWidgetPosition = interface:GetRelativeMousePosition()
		local viewportSize = workspace.CurrentCamera.ViewportSize
		local newMousePosition = mouseWidgetPosition
		
		mousePosVal.Value = Vector3.new(newMousePosition.X,newMousePosition.Y,0)
	end
end)

