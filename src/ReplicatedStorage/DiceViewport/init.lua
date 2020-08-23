--[[
	@Author: Gavin "Mullets" Rosenthal
	@Desc: Viewport module to create proper viewports with sizing
--]]

--[[
	Variations of call:
	
	:Create(element,obj)
	:Create(element,obj,props)
	
	Returns:
	false or viewport
	
	props = {
		['Distance] = 1; -- distance of the camera to the port
		['FoV'] = 50; -- field of view
		['Angles] = CFrame.Angles(0,0,0)
		['Offset] = CFrame.new(0,0,0)
	}
--]]

--// logic
local Viewport = {}
Viewport.Cache = {}
Viewport.Types = {'Frame','ImageLabel','ImageButton','TextButton','TextLabel','TextBox'}

--// services
local Services = setmetatable({}, {__index = function(cache, serviceName)
    cache[serviceName] = game:GetService(serviceName)
    return cache[serviceName]
end})

--// functions
local function CreateFolder()
	local new = Instance.new('Folder')
	new.Name = 'DiceViewport'
	new.Parent = Services['ReplicatedStorage']
	return new
end

local function CreateViewport(port)
	local flag = false
	for index,type in pairs(Viewport.Types) do
		if port:IsA(type) then
			flag = true
			break
		end
	end
	if not flag then
		warn('[VIEWPORT]: Viewport element only takes frames, imageLabels, imageButton, textbuttons, textlabels or textboxs. You used:',port.ClassName)
		return false
	end
	local new = Instance.new('ViewportFrame')
	new.Size = UDim2.new(1, 0, 1, 0)
	new.Position = UDim2.new(0.5, 0, 0.5, 0)
	new.AnchorPoint = Vector2.new(0.5, 0.5)
	new.BackgroundTransparency = 1
	new.ImageColor3 = port.BackgroundColor3
	if port:IsA('ImageButton') or port:IsA('ImageLabel') then
		port.Image = ''
	end
	new.Parent = port
	port = new
	return port
end

local function CreateObject(clone)
	if not clone:IsA('Model') and not clone:IsA('BasePart') then
		warn('[VIEWPORT]: Viewport only takes models or baseparts. You used:',clone.ClassName)
		return false
	end
	local item = clone:Clone()
	if not item:IsA('Model') then
		local folder = CreateFolder()
		local new = Instance.new('Model')
		item.Parent = folder
		for index,part in pairs(folder:GetChildren()) do
			if part:IsA('BasePart') then
				part.Parent = new
				new.PrimaryPart = part
			end
		end
		item = new
		folder:Destroy()
	end
	return item
end

function Viewport:Stop(element)
	if Viewport.Cache[element] then
		for index,event in pairs(Viewport.Cache[element]['Events']) do
			event:Disconnect()
		end
		Viewport.Cache[element]['Events'] = {}
	end
end

function Viewport:Destroy(element)
	if Viewport.Cache[element] then
		Viewport.Cache[element]['Element']:Destroy()
		Viewport.Cache[element]['Model']:Destroy()
		for index,event in pairs(Viewport.Cache[element]['Events']) do
			event:Disconnect()
		end
		Viewport.Cache[element] = nil
	end
end

function Viewport:Spin(element)
	if Viewport.Cache[element] then
		Viewport:Stop(element)
		local camera = Viewport.Cache[element]['Camera']
		local model = Viewport.Cache[element]['Model']
		local angles = Viewport.Cache[element]['Properties']['Angles'] or CFrame.Angles(0,0,0)
		local offset = Viewport.Cache[element]['Properties']['Offset'] or CFrame.new(0,0,0)
		local dist = Viewport.Cache[element]['Properties']['Distance'] or 1
		local size = model:GetExtentsSize()
		local rate = 1/30
		local logged = 0
		local increment = 0
		local event
		event = Services['RunService'].Heartbeat:Connect(function(dt)
			logged = logged + dt
			while logged >= rate do
				logged = logged - rate
				local cframe = model.PrimaryPart.CFrame * CFrame.Angles(0, math.rad(increment), 0) * CFrame.new(0,0,size.Y * dist) * offset
				camera.CFrame = CFrame.new(cframe.Position,model.PrimaryPart.Position)
				increment = increment + 2
			end
		end)
		table.insert(Viewport.Cache[element]['Events'],event)
		return true
	end
	warn('[VIEWPORT]: Element supplied is not a valid viewport')
end

function Viewport:Create(element,obj,props)
	if not element then warn() return false end
	if not props then props = {} end
	if Viewport.Cache[element] then
		Viewport:Destroy(element)
	end
	local item = CreateObject(obj)
	local port = CreateViewport(element)
	if item and port then
		item.Parent = port
		local size = item:GetExtentsSize()
		local dist = props['Distance'] or 1
		local fov = props['FoV'] or 50
		local angles = props['Angles'] or CFrame.Angles(0,0,0)
		local offset = props['Offset'] or CFrame.new(0,0,0)
		local camera = Instance.new('Camera') do
			local cframe = item.PrimaryPart.CFrame * angles * CFrame.new(0,0,size.Y * dist) * offset
			camera.FieldOfView = fov
			camera.CameraType = Enum.CameraType.Scriptable
			camera.CFrame = cframe
			camera.Parent = port
		end
		port.CurrentCamera = camera
		Viewport.Cache[element] = {
			['Model'] = item;
			['Element'] = port;
			['Camera'] = camera;
			['Properties'] = props;
			['Events'] = {};
		}
		return port
	end
	warn('[VIEWPORT]: Failed to create viewport, missing item and/or port')
	return false
end

return Viewport