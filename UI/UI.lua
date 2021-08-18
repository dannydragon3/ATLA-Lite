-- Old UI that I made using drawing api

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService('Players')

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character

local camera = workspace.CurrentCamera

local Mouse = LocalPlayer:GetMouse()

local UI = {}
local drawings = {}

UI.ObjectHandler = {}
UI.startOffSet = 0.5 * camera.ViewportSize.Y
UI.offset = 15

function UI:Draw(type, properties)
    local object = Drawing.new(type)
	local currentOffSet = 0

	if #self.ObjectHandler > 1 then
		currentOffSet = self.offset * (#self.ObjectHandler - 1)
		properties.Position += Vector2.new(0, currentOffSet)
	end
	
    for property, value in pairs(properties) do 
        object[property] = value
    end

	local newObject = setmetatable({
        _position = object.Position,
		_offset = currentOffSet,
        _drawing = object,
    }, drawings)

	table.insert(self.ObjectHandler, newObject)

    return newObject
end

UI:Draw("Text",{
	Text = ">",
	Size = 25,
	Color = Color3.fromRGB(255, 255,255),
	Position = Vector2.new(0,UI.startOffSet),
	Visible = true
});

function UI:CreateButton(name, CallBack)
	local button = UI:Draw("Text", {
		Text = name,
		Size = 24,
		Color = Color3.fromRGB(255,255,255),
		Position = Vector2.new(15, self.startOffSet),
		Visible = true
	});
	
	button.CallBack = CallBack
end

function UI:CreateToggleButton(name, CallBack)
	local button = UI:Draw("Text", {
		Text = name,
		Size = 24,
		Color = Color3.fromRGB(255,0,0),
		Position = Vector2.new(15, self.startOffSet),
		Visible = true
	});
	
	button.toggle = false
	button.CallBack = CallBack
	button.IsToggled = function()
	    return button.toggle
	end
	
	return button.IsToggled
end


function UI:CreateValueChanger(name, defaultValue)
	local ValueChanger = UI:Draw("Text", {
		Text = name .. ": " .. (defaultValue or 0),
		Size = 24,
		Color = Color3.fromRGB(255,255,255),
		Position = Vector2.new(15, self.startOffSet),
		Visible = true
	});
	
	ValueChanger.value = defaultValue or 0
	ValueChanger.GetValue = function()
	    return ValueChanger.value
	end

	return ValueChanger.GetValue
end

function UI:CreateListSelector(list)
    local formatedlist = {}

    for i,v in pairs(list) do
        table.insert(formatedlist, i) 
    end
    
	local ListSelector = UI:Draw("Text", {
		Text = tostring(formatedlist[1]) .. " (1/" .. #formatedlist .. ")",
		Size = 24,
		Color = Color3.fromRGB(255,255,255),
		Position = Vector2.new(15, self.startOffSet),
		Visible = true
	});
	
	ListSelector.list = formatedlist
	ListSelector.selected = 1
	ListSelector.GetSelected = function()
        return ListSelector.list[ListSelector.selected]
	end
	
	return ListSelector.GetSelected
end

function UI:FindInCertainPosition(position)
	for i, object in pairs(self.ObjectHandler) do
		if i == 1 then
			continue
		end

		local drawing = object._drawing

		if drawing.Position.Y == position.Y then
			return object
		end
	end
end

function UI:ArrowIndicator(enum)
	local Arrow = self.ObjectHandler[1]

    	local ArrowDrawing = Arrow._drawing
	local ArrowPosition = ArrowDrawing.Position

	local currentSelected = self:FindInCertainPosition(ArrowPosition)
	
	if enum == Enum.KeyCode.Up and self:FindInCertainPosition(ArrowPosition - Vector2.new(0, 15)) then
		ArrowDrawing.Position = ArrowPosition - Vector2.new(0, 15)
		Arrow._offset -= 15
	elseif enum == Enum.KeyCode.Down  and self:FindInCertainPosition(ArrowPosition + Vector2.new(0, 15)) then
		ArrowDrawing.Position = ArrowPosition + Vector2.new(0, 15)
		Arrow._offset += 15
	elseif enum == Enum.KeyCode.Return then 
		if currentSelected.toggle ~= nil then
			currentSelected.toggle = not currentSelected.toggle
			
			spawn(function()
			    currentSelected.CallBack(currentSelected.toggle)
			end)
			
			if currentSelected.toggle == false then 
				currentSelected._drawing.Color = Color3.fromRGB(255,0,0)
				return
			end
			
			currentSelected._drawing.Color = Color3.fromRGB(0,255,0)
		elseif currentSelected.CallBack ~= nil then
			currentSelected.CallBack()
			
			currentSelected._drawing.Color = Color3.fromRGB(0,255,0)
			
			task.wait(0.2)
			
			currentSelected._drawing.Color = Color3.fromRGB(255,255,255)
		end
	elseif enum == Enum.KeyCode.Left then
		if currentSelected.value ~= nil then
		    currentSelected._drawing.Text = currentSelected._drawing.Text:gsub(currentSelected.value, "" .. currentSelected.value - 1)
        	currentSelected.value -= 1
		elseif currentSelected.list ~= nil then
			local newIndex = currentSelected.selected - 1

			if currentSelected.list[newIndex] then
				local newText = currentSelected._drawing.Text:gsub(tostring(currentSelected.list[currentSelected.selected]), tostring(currentSelected.list[newIndex]))
			
				currentSelected._drawing.Text = newText:gsub(currentSelected.selected .. "/", newIndex .. "/")
				currentSelected.selected -= 1 
			end
		end
	elseif enum == Enum.KeyCode.Right then
		if currentSelected.value ~= nil then
		    currentSelected._drawing.Text = currentSelected._drawing.Text:gsub(currentSelected.value, "" .. currentSelected.value + 1)
            currentSelected.value += 1
		elseif currentSelected.list ~= nil then
			local newIndex = currentSelected.selected + 1
			
			if currentSelected.list[newIndex] then
				local newText = currentSelected._drawing.Text:gsub(tostring(currentSelected.list[currentSelected.selected]), tostring(currentSelected.list[newIndex]))
			
				currentSelected._drawing.Text = newText:gsub(currentSelected.selected .. "/", newIndex .. "/")
				currentSelected.selected += 1
			end
		end
	end
end

UserInputService.InputBegan:Connect(function(input)
    UI:ArrowIndicator(input.KeyCode)
end)

camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
    for _, object in ipairs(UI.ObjectHandler) do
        local drawing = object._drawing
	local position = object._position
	local offset = object._offset
		
	local newPosition = position.Y - (position.Y - camera.ViewportSize.Y / 2) + offset

	drawing.Position = Vector2.new(position.X, newPosition)
    end
end)

return UI
