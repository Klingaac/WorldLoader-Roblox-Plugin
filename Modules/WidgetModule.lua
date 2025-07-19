-- Used to create loading/warning/error widgets
-- This code is a mess

local module = {}

local RS = game:GetService("RunService")
local plugin = script:FindFirstAncestorWhichIsA("Plugin")
local theme = tostring(settings().Studio.Theme)
local objects = script.Parent.Parent.Objects

-- Assets
local loadingWheelId = "http://www.roblox.com/asset/?id=100596139540826"
local SuccessTickId = "http://www.roblox.com/asset/?id=121953050880449"
local ErrorCrossId = "http://www.roblox.com/asset/?id=102505264519025"

-- Existing Widgets
local currentErrorWidget
local currentLoadingWidget
local currentWarningWidget


local Widget = {}
Widget.__index = Widget


function Widget.loading(widgetText: string)
	
	if currentLoadingWidget then
		currentLoadingWidget:Kill()
	end
	
	local self = setmetatable({},Widget)
	
	local canvas = objects.UIObjects.widget:Clone()
	
	if theme == "Light" then
		canvas.BackgroundColor3 = Color3.new(1, 1, 1)
		canvas.TextLabel.TextColor = BrickColor.new(0,0,0)
	end
	
	local widgetInfo = DockWidgetPluginGuiInfo.new(
		Enum.InitialDockState.Float,
		false,
		false,
		350,
		125,
		350,
		125
	)

	local interface = plugin:CreateDockWidgetPluginGui(
		"Loading",
		widgetInfo
	)
	
	
	interface:BindToClose(function()
		self:Kill()
	end)
	
	
	interface.Title = "Loading"
	interface.Name = "WorldLoader Loading"
	interface.Enabled = true
	
	canvas.TextLabel.Text = widgetText
	canvas.ImageLabel.Image = loadingWheelId
	canvas.ImageLabel.ImageColor3 = Color3.fromRGB(43, 177, 255)
	
	canvas.Parent = interface
	
	
	local wheelConnection = RS.Heartbeat:Connect(function(deltaTime)
		canvas.ImageLabel.Rotation += deltaTime * 300
	end)
	
	
	self.connections = {}
	table.insert(self.connections,wheelConnection)
	
	self.interface = interface
	self.widgetType = "loading"
	
	
	currentLoadingWidget = self
	
	return self
end

function Widget.error(widgetText: string)

	if currentErrorWidget then
		currentErrorWidget:Kill()
	end

	local self = setmetatable({},Widget)

	local canvas = objects.UIObjects.widget:Clone()

	if theme == "Light" then
		canvas.BackgroundColor3 = Color3.new(1, 1, 1)
		canvas.TextLabel.TextColor = BrickColor.new(0,0,0)
	end

	local widgetInfo = DockWidgetPluginGuiInfo.new(
		Enum.InitialDockState.Float,
		false,
		false,
		350,
		125,
		350,
		125
	)

	local interface = plugin:CreateDockWidgetPluginGui(
		"Error",
		widgetInfo
	)


	interface:BindToClose(function()
		self:Kill()
	end)


	interface.Title = "Error"
	interface.Name = "WorldLoader Error"
	interface.Enabled = true

	canvas.TextLabel.Text = widgetText
	canvas.ImageLabel.Image = ErrorCrossId
	canvas.ImageLabel.ImageColor3 = Color3.new(1,0,0)

	canvas.Parent = interface


	self.connections = {}
	self.interface = interface
	self.widgetType = "Error"


	currentErrorWidget = self

	return self

end

function Widget.warnToContinue(widgetText: string)
	
	if currentErrorWidget then
		currentErrorWidget:Kill()
	end

	local self = setmetatable({},Widget)

	local canvas = objects.UIObjects.warnWidget:Clone()

	if theme == "Light" then
		canvas.BackgroundColor3 = Color3.new(1, 1, 1)
		canvas.TextLabel.TextColor = BrickColor.new(0,0,0)
	end

	local widgetInfo = DockWidgetPluginGuiInfo.new(
		Enum.InitialDockState.Float,
		false,
		false,
		350,
		150,
		350,
		150
	)

	local interface = plugin:CreateDockWidgetPluginGui(
		"Error",
		widgetInfo
	)
	
	local event = Instance.new("BindableEvent",canvas)
	self.event = event.Event

	interface:BindToClose(function()
		event:Fire(false)
		self:Kill()
	end)


	interface.Title = "Error"
	interface.Name = "WorldLoader Error"
	interface.Enabled = true

	canvas.TextLabel.Text = widgetText
	canvas.ImageLabel.Image = ErrorCrossId
	canvas.ImageLabel.ImageColor3 = Color3.new(0.976471, 0.521569, 0.121569)

	canvas.Parent = interface
	
	
	local cancel = canvas.Cancel
	local continue = canvas.Continue
	
	cancel.MouseButton1Click:Connect(function()
		event:Fire(false)
		self:Kill()
	end)
	
	continue.MouseButton1Click:Connect(function()
		event:Fire(true)
		self:Kill()
	end)

	self.connections = {}
	self.interface = interface
	self.widgetType = "Error"


	currentErrorWidget = self

	return self, event.Event
	
end

function Widget:ChangeText(text: string)
	
	if not self.interface or not self.interface:FindFirstChild("widget") then
		return
	end
	
	local canvas = self.interface.widget
	canvas.TextLabel.Text = text
end

function Widget:Kill()

	if not self.interface then
		return
	end

	for _,connection in self.connections do
		connection:Disconnect()
	end

	self.interface.Enabled = false
	self.interface:Destroy()

	setmetatable(Widget, nil)

end


function Widget:FinishLoading(text: string)
	
	if not self.interface or not self.interface:FindFirstChild("widget") then
		return
	end
	
	for _,connection in self.connections do
		connection:Disconnect()
	end
	self.connections = {}
	
	local canvas = self.interface.widget
	
	canvas.ImageLabel.Image = SuccessTickId
	canvas.ImageLabel.Rotation = 0
	canvas.TextLabel.Text = text
	
end



return Widget
