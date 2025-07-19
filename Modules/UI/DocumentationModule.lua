local module = {}

local LINK = "https://devforum.roblox.com/t/worldloader-plugin-documentation/3187419?u=goodbadred"

function module.start(canvas: CanvasGroup)

	local categories = canvas:WaitForChild("Categories")
	local docFrame = categories:WaitForChild("Documentation")
	local linkbox = docFrame:WaitForChild("DocumentationLink")
	
	linkbox.Text = LINK

	linkbox.Focused:Connect(function()
		linkbox.Text = LINK
		linkbox.CursorPosition = #linkbox.Text + 1
		linkbox.SelectionStart = 1
	end)

	linkbox.FocusLost:Connect(function()
		linkbox.Text = LINK
	end)
	
end


return module
