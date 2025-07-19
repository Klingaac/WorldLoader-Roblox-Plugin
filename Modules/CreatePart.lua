local function createPart(parent: Instance,cframe: CFrame|Vector3,size: Vector3?,color: Color3?,material: Enum.Material?)
	local part = Instance.new("Part")
	
	if typeof(cframe) == "CFrame" then
		part.CFrame = cframe
	else
		part.CFrame = CFrame.new(cframe)
	end
	
	if size then
		part.Size = size
	end
	
	if color then
		part.Color = color
	end
	
	if material then
		part.Material = material
	end
	
	part.CanCollide = false
	part.Anchored = true

	if size == Vector3.new(.1,.2,.1) then
		part.Name = "Debug"
	end
	
	part.Parent = parent

	return part
end

return createPart