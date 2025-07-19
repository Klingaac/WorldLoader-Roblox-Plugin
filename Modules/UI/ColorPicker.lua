--[[
?? Color Picker Module by Brambes230605
?? December 30th, 2023

?? More info and documentation: https://devforum.roblox.com/t/2772473

-- || Constructor || --
ColorPicker.new(): colorPicker
	Constructor for creating a new ColorPicker object.

--|| Events ||--
colorPicker.Opened
	Fires when the color picker is opened.
	
colorPicker.Closed
	Fires when the color picker is closed.
	Parameters:
		- selectedColor (Color3): The color selected when the color picker closed.
		- confirmed (boolean?): true when it was closed with the 'ok' button, false when it was closed with the 'cancel' button and nil when it was closed using the :Close() method
		
colorPicker.Changed
	Fires when the color selection changes.
	Parameters:
		- updatedColor (Color3): The updated color during color selection.

--|| Methods ||--
colorPicker:Start()
	Opens the color picker.
	
colorPicker:Cancel()
	Cancels the color selection and closes the color picker.
	
colorPicker:SetColor(color: Color3)
	Sets the color of the color picker.
	
colorPicker:GetColor(): Color3
	Returns the current color of the color picker
	
colorPicker:Destroy()
	Destroys the color picker.
]]

local MainUISource = script.Parent.Parent.Parent.Objects.UIObjects.ColorPickerMain
local Objects = script.Parent.Parent.Parent.Objects
local Values = Objects.Values

local UserInputService = game:GetService("UserInputService")

local OFFSET
local canvas
local mouse

local FrameAmount = 0


function updateColor(self, arg1, arg2, arg3)
	local hue, sat, val
	
	if typeof(arg1) == "Color3" then
		hue, sat, val = arg1:ToHSV()
		self.currentColor = arg1
	else
		hue, sat, val = arg1, arg2, arg3
		self.currentColor = Color3.fromHSV(hue, sat, val)
	end
	self.previewColor.BackgroundColor3 = self.currentColor
	
	local function updateTextBoxNumber(textBox, value, multiplier)
		local text
		if typeof(value) == "number" then
			text = math.round(value * multiplier)
		else
			text = value
		end
		textBox.Text = text
		textBox.PlaceholderText = text
	end
	
	updateTextBoxNumber(self.textBoxNumber.Hue, hue, 359)
	updateTextBoxNumber(self.textBoxNumber.Saturation, sat, 255)
	updateTextBoxNumber(self.textBoxNumber.Value, val, 255)
	
	local r, g, b = self.currentColor.R*255, self.currentColor.G*255, self.currentColor.B*255
	updateTextBoxNumber(self.textBoxNumber.Red, r, 1)
	updateTextBoxNumber(self.textBoxNumber.Green, g, 1)
	updateTextBoxNumber(self.textBoxNumber.Blue, b, 1)
	
	local hex = self.currentColor:ToHex()
	updateTextBoxNumber(self.textBoxNumber.HTML, hex, 1)
	
	self.valUiGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.new(0, 0, 0)),
		ColorSequenceKeypoint.new(1, Color3.fromHSV(hue, sat, 1))
	}
	
	self.blackWhiteCursor.Position = UDim2.fromScale(0, 1 - val)
	self.colorCursor.Position = UDim2.fromScale(1 - hue, 1 - sat)
	
	self._Changed:Fire(self.currentColor)
end

local function connectEvents(self)
	
	local function Update()
		local absoluteColorPos = self.colorButton.AbsolutePosition
		local absoluteColorSize = self.colorButton.AbsoluteSize
		self.min_x = absoluteColorPos.X
		self.max_x = absoluteColorPos.X + absoluteColorSize.X
		self.min_y = absoluteColorPos.Y + OFFSET
		self.max_y = absoluteColorPos.Y + absoluteColorSize.Y + OFFSET
	end

	self.colorButton:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
		Update()
	end)
	self.colorButton:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		Update()
	end)
	

	self.colorButton.MouseButton1Down:Connect(function()
		
		local colorButton = self.colorButton
		
		local p,r
		
		local MOUSE_DOWN = true
		
		local function onPressed()
			MOUSE_DOWN = true	
		end
		local function onReleased()
			MOUSE_DOWN = false
			if p then
				p:Disconnect()
			end
			if r then
				r:Disconnect()
			end
			
		end
		
		p = colorButton.InputBegan:Connect(onPressed)
		r = colorButton.InputEnded:Connect(onReleased)
		
		local firstIter = true
		
		while (MOUSE_DOWN or firstIter) and self.active do
			
			firstIter = false
			
			local mousePos = Values.MousePos.Value

			local percent_x = 1 - math.clamp((mousePos.X - self.min_x) / (self.max_x - self.min_x), 0, 1)
			local percent_y = 1 - math.clamp((mousePos.Y - self.min_y) / (self.max_y - self.min_y), 0, 1)
			
			self.hue = percent_x
			self.sat = percent_y
			
			updateColor(self, self.hue, self.sat, self.val)
			task.wait()
		end
	end)
	
	local function dragValue(colorButton)
		
		local MOUSE_DOWN = true
		
		local p,r
		
		local function onPressed()
			MOUSE_DOWN = true	
		end
		local function onReleased()
			MOUSE_DOWN = false
			if p then
				p:Disconnect()
			end
			if r then
				r:Disconnect()
			end

		end

		p = colorButton.InputBegan:Connect(onPressed)
		r = colorButton.InputEnded:Connect(onReleased)
		
		local firstIter = true
		
		while (MOUSE_DOWN or firstIter) and self.active do
			firstIter = false
			
			local mousePos = Values.MousePos.Value
			
			local percent = 1 - math.clamp((mousePos.Y - self.min_y) / (self.max_y - self.min_y), 0, 1)
			self.val = percent
			
			updateColor(self, self.hue, self.sat, self.val)
			task.wait()
		end
	end

	self.blackWhiteButton.MouseButton1Down:Connect(function()
		dragValue(self.blackWhiteButton)
	end)
	self.blackWhiteCursor.TextButton.MouseButton1Down:Connect(function()
		dragValue(self.blackWhiteCursor.TextButton)
	end)

	self.okButton.MouseButton1Click:Connect(function()
		self.frame.Visible = false
		self.active = false
		self._Closed:Fire(self.currentColor, true)
	end)
	
	self.cancelButton.MouseButton1Click:Connect(function()
		self.frame.Visible = false
		self.active = false
		updateColor(self, self.currentColor)
		self._Closed:Fire(self.currentColor, false)
	end)
	
	local function ProcessText(enterPressed, number)
		
		local newNumber = tonumber(number)
		
		if not newNumber then
			updateColor(self, self.currentColor)
			return
		end

		return newNumber
	end

	self.textBoxNumber.Red.FocusLost:Connect(function(enterPressed)
		local r = ProcessText(enterPressed, self.textBoxNumber.Red.Text)
		if not r then return end
		r = math.clamp(r, 0, 255)
		r /= 255
		local g, b = self.currentColor.G, self.currentColor.B
		updateColor(self, Color3.new(r, g, b))
	end)
	self.textBoxNumber.Green.FocusLost:Connect(function(enterPressed)
		local g = ProcessText(enterPressed, self.textBoxNumber.Green.Text)
		if not g then return end
		g = math.clamp(g, 0, 255)
		g /= 255
		local r, b = self.currentColor.R, self.currentColor.B
		updateColor(self, Color3.new(r, g, b))
	end)
	self.textBoxNumber.Blue.FocusLost:Connect(function(enterPressed)
		local b = ProcessText(enterPressed, self.textBoxNumber.Blue.Text)
		if not b then return end
		b = math.clamp(b, 0, 255)
		b /= 255
		local r, g = self.currentColor.R, self.currentColor.G
		updateColor(self, Color3.new(r, g, b))
	end)
	self.textBoxNumber.Hue.FocusLost:Connect(function(enterPressed)
		local hue = ProcessText(enterPressed, self.textBoxNumber.Hue.Text)
		if not hue then return end
		self.hue = math.clamp(hue, 0, 359) / 359
		updateColor(self, self.hue, self.sat, self.val)
	end)
	self.textBoxNumber.Saturation.FocusLost:Connect(function(enterPressed)
		local sat = ProcessText(enterPressed, self.textBoxNumber.Saturation.Text)
		if not sat then return end
		self.sat = math.clamp(sat, 0, 255) / 255
		updateColor(self, self.hue, self.sat, self.val)
	end)
	self.textBoxNumber.Value.FocusLost:Connect(function(enterPressed)
		local val = ProcessText(enterPressed, self.textBoxNumber.Value.Text)
		if not val then return end
		self.val = math.clamp(val, 0, 255) / 255
		updateColor(self, self.hue, self.sat, self.val)
	end)
	self.textBoxNumber.HTML.FocusLost:Connect(function()
		local success, result = pcall(function()
			return Color3.fromHex(self.textBoxNumber.HTML.Text)
		end)
		if success then
			updateColor(self, result)
		else
			updateColor(self, self.currentColor)
		end
	end)
end

local ColorPicker = {}
ColorPicker.__index = ColorPicker
local userGui

function ColorPicker.enable(newcanvas: CanvasGroup,newmouse: PluginMouse)
	
	canvas = newcanvas
	mouse = newmouse
	OFFSET = math.abs(canvas.AbsolutePosition.Y)
	
end

function ColorPicker.new()
	local self = setmetatable({}, ColorPicker)
	
	self.currentColor = Color3.new(1, 1, 1)
	self.active = false
	
	self._Opened = Instance.new("BindableEvent")
	self._Closed = Instance.new("BindableEvent")
	self._Changed = Instance.new("BindableEvent")
	
	self.Opened = self._Opened.Event
	self.Closed = self._Closed.Event
	self.Changed = self._Changed.Event
	
	self.hue, self.sat, self.val = self.currentColor:ToHSV()
	
	FrameAmount += 1
	
	self.frame = MainUISource:Clone()
	self.frame.Name = FrameAmount
	self.frame.Parent = canvas
	self.sliders = self.frame.Sliders
	self.numeric = self.frame.Numeric
	
	self.previewColor = self.numeric.Preview
	self.okButton = self.numeric.Ok
	self.cancelButton = self.numeric.Cancel
	self.textBoxNumber = self.numeric.TextBox
	self.colorButton = self.sliders.Color.Button
	self.colorCursor = self.sliders.Color.White.Cursor
	self.blackWhiteButton = self.sliders.Value.Button
	self.blackWhiteCursor = self.sliders.Value.Cursor
	self.valUiGradient = self.sliders.Value.UIGradient
	
	updateColor(self, self.currentColor)
	
	connectEvents(self)
	
	return self
end

function ColorPicker:SetColor(color: Color3)
	if not color then
		error("Argument 1 missing or nil", 2)
	elseif color and typeof(color) ~= "Color3" then
		error("Color3 expected got "..typeof(color), 2)
	elseif color then
		self.hue, self.sat, self.val = color:ToHSV() -- new color, need to reset hue, sat, val
		updateColor(self, self.hue, self.sat, self.val)
	end
end

function ColorPicker:GetColor(): Color3
	return self.currentColor
end

function ColorPicker:Start()
	if self.active then return end
	self.frame.Visible = true
	self.active = true
	self._Opened:Fire()
end

function ColorPicker:Cancel()
	if not self.active then return end
	self.frame.Visible = false
	self.active = false
	self._Closed:Fire(self.currentColor)
end

function ColorPicker:Destroy()
	self.active = false
	self._Changed:Destroy()
	self._Opened:Destroy()
	self._Closed:Destroy()
	self.frame:Destroy()
	setmetatable(self, nil)
	self = nil
end

return ColorPicker
