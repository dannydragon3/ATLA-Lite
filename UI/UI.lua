-- Yessir I wrote this back in 2019 working on a rewrite currently
-- Old UI that I made using drawing api
-- Added sub categories to the old version and am still working on the rewrite since this is bullcrap of a ui lib

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService('Players')

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character

local camera = workspace.CurrentCamera

local Mouse = LocalPlayer:GetMouse()

local UI = {}
local drawings = {}

UI.ObjectHandler = {}
UI.SubCategories = {}

UI._startOffSet = 0.5 * camera.ViewportSize.Y
UI._offset = 15

function UI:Draw(type, properties, categoryParent)
    local object = Drawing.new(type)
	local currentOffSet = 0
	local shouldIgnoreOffset = 0

	for _, category in pairs(self.SubCategories) do
		for _, object in pairs(category._drawings) do
			shouldIgnoreOffset += 1
		end
	end

	if categoryParent and #categoryParent._drawings > 0 then
		local textBounds = (categoryParent._drawings[1] and categoryParent._drawings[1]._drawing.TextBounds.X + 3) or 0
		currentOffSet = self._offset * (#categoryParent._drawings - 1)

		properties.Position = categoryParent._startOffSet + Vector2.new(textBounds, currentOffSet)
		properties.Visible = false

		currentOffSet += categoryParent._offset
	elseif #self.ObjectHandler > 1 and not categoryParent then
		currentOffSet = self._offset * ((#self.ObjectHandler - 1) - shouldIgnoreOffset)
		properties.Position += Vector2.new(0, currentOffSet)
	end
	
    for property, value in pairs(properties) do 
        object[property] = value
    end

	local newObject = setmetatable({
        _position = object.Position,
		_offset = currentOffSet,
        _drawing = object,
		subCategory = {
			hasSubCategory = false,
			_drawings = {}
		}
    }, drawings)

	function newObject.subCategory:CreateCategory()
		object.Text = object.Text .. " (+)"

		local arrow = UI:Draw("Text",{
			Text = ">",
			Size = 25,
			Color = Color3.fromRGB(255, 255,255),
			Position = Vector2.new(UI._offset + object.TextBounds.X + 3, object.Position.Y),
		}, self);

		self._offset = currentOffSet
		self._startOffSet = arrow._position

		arrow._offset = self._offset

		self.hasSubCategory = true

		function self:GetCategoryArrow()
			return arrow
		end

		function self:ToggleCurrentCategory(boolean)
			for i,v in pairs(self._drawings) do
				local object = UI.ObjectHandler[table.find(UI.ObjectHandler, v)]._drawing
				object.Visible = boolean
			end

			object.Text = object.Text:gsub((boolean and "+") or (not boolean and "-"), (boolean and "-") or (not boolean and "+"))
			arrow.Position = Vector2.new(UI._offset + object.TextBounds.X + 3, object.Position.Y)
		end

		table.insert(UI.SubCategories, self)

		return self
	end

	if categoryParent then
		table.insert(categoryParent._drawings, newObject)
	end 
	
	table.insert(self.ObjectHandler, newObject)

	if properties.Text == ">" and not self.currentArrow then
		newObject.enabled = true
		self.currentArrow = newObject
	elseif properties.Text == ">" then
		newObject.enabled = false
	end
	
    return newObject
end

UI:Draw("Text",{
	Text = ">",
	Size = 25,
	Color = Color3.fromRGB(255, 255,255),
	Position = Vector2.new(0,UI._startOffSet),
	Visible = true
})

function UI:CreateButton(name, CallBack, categoryParent)
	local button = UI:Draw("Text", {
		Text = name,
		Size = 24,
		Color = Color3.fromRGB(255,255,255),
		Position = Vector2.new(15, self._startOffSet),
		Visible = true
	}, categoryParent)
	
	button.CallBack = CallBack

	return button
end

function UI:CreateToggleButton(name, CallBack, categoryParent)
	local button = UI:Draw("Text", {
		Text = name,
		Size = 24,
		Color = Color3.fromRGB(255,0,0),
		Position = Vector2.new(15, self._startOffSet),
		Visible = true
	}, categoryParent)
	
	button.toggle = false
	button.CallBack = CallBack
	button.IsToggled = function()
	    return button.toggle
	end
	
	return button.IsToggled, button
end


function UI:CreateValueChanger(name, defaultValue, jumps, minimum, maximum, categoryParent)
	local ValueChanger = UI:Draw("Text", {
		Text = name .. ": " .. (defaultValue or 0),
		Size = 24,
		Color = Color3.fromRGB(255,255,255),
		Position = Vector2.new(15, self._startOffSet),
		Visible = true
	}, categoryParent)
	
	ValueChanger.jumps = jumps or 1

	ValueChanger.maximum = maximum or math.huge
	ValueChanger.minimum = minimum or 0

	ValueChanger.value = defaultValue or 0
	ValueChanger.GetValue = function()
	    return ValueChanger.value
	end

	return ValueChanger.GetValue
end

function UI:CreateListSelector(list, categoryParent)
    local formatedlist = {}

    for i,v in pairs(list) do
        table.insert(formatedlist, i) 
    end
    
	local ListSelector = UI:Draw("Text", {
		Text = tostring(formatedlist[1]) .. " (1/" .. #formatedlist .. ")",
		Size = 24,
		Color = Color3.fromRGB(255,255,255),
		Position = Vector2.new(15, self._startOffSet),
		Visible = true
	}, categoryParent)
	
	ListSelector.list = formatedlist
	ListSelector.selected = 1
	ListSelector.GetSelected = function()
        return ListSelector.list[ListSelector.selected]
	end
	
	return ListSelector.GetSelected
end

function UI:GetPreviousArrow()
	local currentArrow

	for i, object in pairs(self.ObjectHandler) do
		if object == self.currentArrow then
			for secondIndex, secondObject in pairs(self.ObjectHandler) do
				if secondIndex < i and secondObject._drawing.Text == ">" then
					currentArrow = secondObject
					break
				end
			end
		end
	end

	return currentArrow
end

function UI:GetCurrentCategory(arrow)
	local currentCategory

	for i,v in pairs(self.SubCategories) do
		if table.find(v._drawings, arrow) then
			currentCategory = v
			break
		end
	end

	return currentCategory
end

function UI:FindInCertainPosition(arrow, position)
	for i, object in pairs(self.ObjectHandler) do
		if i == 1 then
			continue
		end

		local drawing = object._drawing

		if (drawing.Position.Y == position.Y and ((position.X + arrow.TextBounds.X + 3) == drawing.Position.X) and arrow.Visible == true and drawing.Visible == true) then
			print("Passed")
			return object
		elseif drawing.Position.Y == position.Y and position.X == 0 and drawing.Position.X == self._offset then
			return object
		end
	end
end

local shouldStopValueAcceleration

function UI:ArrowIndicator(enum)
	local Arrow = self.currentArrow

    local ArrowDrawing = Arrow._drawing
	local ArrowPosition = ArrowDrawing.Position

	local currentSelected = self:FindInCertainPosition(ArrowDrawing, ArrowPosition)
	
	if enum == Enum.KeyCode.Up and self:FindInCertainPosition(ArrowDrawing, ArrowPosition - Vector2.new(0, 15)) then
		ArrowDrawing.Position = ArrowPosition - Vector2.new(0, 15)
		Arrow._offset -= 15
	elseif enum == Enum.KeyCode.Down  and self:FindInCertainPosition(ArrowDrawing, ArrowPosition + Vector2.new(0, 15)) then
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
			spawn(function()
				currentSelected.CallBack()
			end)

			currentSelected._drawing.Color = Color3.fromRGB(0,255,0)
			
			task.wait(0.2)
			
			currentSelected._drawing.Color = Color3.fromRGB(255,255,255)
		end
	elseif enum == Enum.KeyCode.Left then
		if currentSelected.value ~= nil and not (currentSelected.value - currentSelected.jumps < currentSelected.minimum) then
			shouldStopValueAcceleration = false

		    currentSelected._drawing.Text = currentSelected._drawing.Text:gsub(currentSelected.value, "" .. currentSelected.value - currentSelected.jumps)
        	currentSelected.value -= currentSelected.jumps

			acceleration = coroutine.create(function()
				task.wait(0.1)

				while (not shouldStopValueAcceleration) do
					if (currentSelected.value - currentSelected.jumps < currentSelected.minimum) then
						break
					end

					currentSelected._drawing.Text = currentSelected._drawing.Text:gsub(currentSelected.value, "" .. currentSelected.value - currentSelected.jumps)
					currentSelected.value -= currentSelected.jumps

					task.wait()
				end

				coroutine.yield()
			end)

			coroutine.resume(acceleration)
		elseif currentSelected.list ~= nil then
			local newIndex = currentSelected.selected - 1

			if currentSelected.list[newIndex] then
				local newText = currentSelected._drawing.Text:gsub(tostring(currentSelected.list[currentSelected.selected]), tostring(currentSelected.list[newIndex]))
			
				currentSelected._drawing.Text = newText:gsub(currentSelected.selected .. "/", newIndex .. "/")
				currentSelected.selected -= 1 
			end
		end
	elseif enum == Enum.KeyCode.Right then
		if currentSelected.subCategory and currentSelected.subCategory.hasSubCategory then
			self.currentArrow = currentSelected.subCategory:GetCategoryArrow()
			currentSelected.subCategory:ToggleCurrentCategory(true)
		elseif currentSelected.value ~= nil and not (currentSelected.value + currentSelected.jumps > currentSelected.maximum) then
			shouldStopValueAcceleration = false

		    currentSelected._drawing.Text = currentSelected._drawing.Text:gsub(currentSelected.value, "" .. currentSelected.value + currentSelected.jumps)
            currentSelected.value += currentSelected.jumps

			acceleration = coroutine.create(function()
				task.wait(0.1)

				while (not shouldStopValueAcceleration) do
					if (currentSelected.value + currentSelected.jumps > currentSelected.maximum) then
						break
					end

					currentSelected._drawing.Text = currentSelected._drawing.Text:gsub(currentSelected.value, "" .. currentSelected.value + currentSelected.jumps)
					currentSelected.value += currentSelected.jumps

					task.wait()
				end

				acceleration = nil
				coroutine.yield()
			end)

			coroutine.resume(acceleration)
		elseif currentSelected.list ~= nil then
			local newIndex = currentSelected.selected + 1
			
			if currentSelected.list[newIndex] then
				local newText = currentSelected._drawing.Text:gsub(tostring(currentSelected.list[currentSelected.selected]), tostring(currentSelected.list[newIndex]))
			
				currentSelected._drawing.Text = newText:gsub(currentSelected.selected .. "/", newIndex .. "/")
				currentSelected.selected += 1
			end
		end
	elseif enum == Enum.KeyCode.Backspace then
		local category = self:GetCurrentCategory(Arrow)

		if category then
			category:ToggleCurrentCategory(false)
			self.currentArrow = self:GetPreviousArrow() 
		end
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not gameProcessed then
    		UI:ArrowIndicator(input.KeyCode)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if not shouldStopValueAcceleration and input.KeyCode == Enum.KeyCode.Left or input.KeyCode == Enum.KeyCode.Right then
    		shouldStopValueAcceleration = true
	end
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

getgenv().UI = UI
