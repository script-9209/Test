-- COMPATIBILITY LAYER
local _LocalPlayer8 = game:GetService("Players").LocalPlayer
local _Character10 = _LocalPlayer8.Character or _LocalPlayer8.CharacterAdded:Wait()
local _call22 = _Character10:WaitForChild("Humanoid") -- Fixed missing Humanoid reference
-- Path Variables (from Luni010)
local pathActive = false
local lastFlatVel = Vector3.zero
local PATH_VELOCITY_SPEED = 59.2
local PATH_SECOND_SPEED   = 29.6
local PATH_BASE_STOP      = 1.35
local PATH_MIN_STOP       = 0.65
local PATH_NEXT_POINT_BIAS= 0.45
local PATH_SMOOTH_FACTOR  = 0.12

local stealPath1 = {
    {pos=Vector3.new(-470.6,-5.9,34.4)},{pos=Vector3.new(-484.2,-3.9,21.4)},
    {pos=Vector3.new(-475.6,-5.8,29.3)},{pos=Vector3.new(-473.4,-5.9,111)}
}
local stealPath2 = {
    {pos=Vector3.new(-474.7,-5.9,91.0)},{pos=Vector3.new(-483.4,-3.9,97.3)},
    {pos=Vector3.new(-474.7,-5.9,91.0)},{pos=Vector3.new(-476.1,-5.5,25.4)}
}

-- Movement Function (from Luni010)
local function pathMoveToPoint(hrp, current, nextPoint, speed)
    local conn
    conn = game:GetService("RunService").Heartbeat:Connect(function()
        if not pathActive then 
            conn:Disconnect()
            hrp.AssemblyLinearVelocity = Vector3.zero 
            return 
        end
        local pos = hrp.Position
        local target = Vector3.new(current.X, pos.Y, current.Z)
        local dir = target - pos
        local dist = dir.Magnitude
        local stopDist = math.clamp(PATH_BASE_STOP - dist*0.04, PATH_MIN_STOP, PATH_BASE_STOP)
        if dist <= stopDist then conn:Disconnect() hrp.AssemblyLinearVelocity = Vector3.zero return end
        local moveDir = dir.Unit
        if nextPoint then
            local nextDir = (Vector3.new(nextPoint.X, pos.Y, nextPoint.Z) - pos).Unit
            moveDir = (moveDir + nextDir * PATH_NEXT_POINT_BIAS).Unit
        end
        if lastFlatVel.Magnitude > 0.1 then
            moveDir = (moveDir*(1-PATH_SMOOTH_FACTOR) + lastFlatVel.Unit*PATH_SMOOTH_FACTOR).Unit
        end
        local vel = Vector3.new(moveDir.X*speed, hrp.AssemblyLinearVelocity.Y, moveDir.Z*speed)
        hrp.AssemblyLinearVelocity = vel
        lastFlatVel = Vector3.new(vel.X, 0, vel.Z)
    end)
    while pathActive and (Vector3.new(hrp.Position.X,0,hrp.Position.Z)-Vector3.new(current.X,0,current.Z)).Magnitude > PATH_BASE_STOP do
        task.wait()
    end
end

-- Running Path (from Luni010)
local function runStealPath(path)
    local hrp = (_LocalPlayer8.Character or _LocalPlayer8.CharacterAdded:Wait()):WaitForChild("HumanoidRootPart")
    for i, p in ipairs(path) do
        if not pathActive then return end
        local speed = i > 2 and PATH_SECOND_SPEED or PATH_VELOCITY_SPEED
        local nextP = path[i+1] and path[i+1].pos
        pathMoveToPoint(hrp, p.pos, nextP, speed)
        task.wait()
    end
end

-- Start and Stop Functions (from Luni010)
local function startStealPath(path)
    pathActive = true
    task.spawn(function() while pathActive do runStealPath(path) task.wait(0.1) end end)
end
local function stopStealPath()
    pathActive = false
    local hrp = _LocalPlayer8.Character and _LocalPlayer8.Character:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.AssemblyLinearVelocity = Vector3.zero end
end

-- ORIGINAL SCRIPT START
local _call5 = game:GetService('RunService')
local _call7 = game:GetService('Stats')

_Character10:WaitForChild('HumanoidRootPart')
_Character10:WaitForChild('Humanoid')
_LocalPlayer8.CharacterAdded:Connect(function(_18)
    _18:WaitForChild('HumanoidRootPart')
    _18:WaitForChild('Humanoid')
    _call22 = _18:WaitForChild('Humanoid') -- Update reference on respawn
end)

-- Remove old UI if exists
if game:GetService('CoreGui'):FindFirstChild('LUNIDual_V3') then
    game:GetService('CoreGui'):FindFirstChild('LUNIDual_V3'):Destroy()
end

local _call32 = Instance.new('ScreenGui', game:GetService('CoreGui'))
_call32.Name = 'LUNIDual_V3'
_call32.ResetOnSpawn = false

local _call34 = Instance.new('Frame', _call32)
_call34.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
_call34.Position = UDim2.new(0.5, -92, 0.5, -130)
_call34.Size = UDim2.new(0, 184, 0, 260)
_call34.Active = true
_call34.Draggable = true

local _call42 = Instance.new('UICorner', _call34)
_call42.CornerRadius = UDim.new(0, 12)

local _call46 = Instance.new('UIGradient', _call34)
_call46.Color = ColorSequence.new({
    [1] = ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
    [2] = ColorSequenceKeypoint.new(0.5, Color3.fromRGB(160, 32, 240)),
    [3] = ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
})

local _call62 = Instance.new('Frame', _call34)
_call62.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
_call62.Position = UDim2.new(0, 3, 0, 3)
_call62.Size = UDim2.new(1, -6, 1, -6)

local _call70 = Instance.new('UICorner', _call62)
_call70.CornerRadius = UDim.new(0, 10)

local _call74 = Instance.new('TextLabel', _call62)
_call74.Text = '06.xd AUTO PLAY DUAL'
_call74.Position = UDim2.new(0, 0, 0, 5)
_call74.Size = UDim2.new(1, 0, 0, 25)
_call74.TextColor3 = Color3.fromRGB(255, 255, 255)
_call74.Font = Enum.Font.GothamBold
_call74.TextSize = 14
_call74.BackgroundTransparency = 1

local _call84 = Instance.new('UIGradient', _call74)
_call84.Color = _call46.Color

local _call87 = Instance.new('TextLabel', _call62)
_call87.Position = UDim2.new(0, 0, 0, 30)
_call87.Size = UDim2.new(1, 0, 0, 15)
_call87.TextColor3 = Color3.fromRGB(200, 200, 200)
_call87.Font = Enum.Font.GothamMedium
_call87.TextSize = 10
_call87.BackgroundTransparency = 1

local _call109 = Instance.new('TextBox', _call62)
_call109.Size = UDim2.new(0.8, 0, 0, 25)
_call109.Position = UDim2.new(0.1, 0, 0.25, 0)
_call109.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
_call109.TextColor3 = Color3.fromRGB(255, 255, 255)
_call109.Font = Enum.Font.GothamSemibold
_call109.Text = '55.5'
Instance.new('UICorner', _call109).CornerRadius = UDim.new(0, 6)

local _call137 = Instance.new('TextBox', _call62)
_call137.Size = UDim2.new(0.8, 0, 0, 25)
_call137.Position = UDim2.new(0.1, 0, 0.43, 0)
_call137.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
_call137.TextColor3 = Color3.fromRGB(255, 255, 255)
_call137.Font = Enum.Font.GothamSemibold
_call137.Text = '29.9'
Instance.new('UICorner', _call137).CornerRadius = UDim.new(0, 6)

-- Buttons
local _call153 = Instance.new('TextButton', _call62)
_call153.Text = 'LEFT SIDE'
_call153.Position = UDim2.new(0.1, 0, 0.55, 0)
_call153.Size = UDim2.new(0.38, 0, 0, 30)
_call153.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
_call153.TextColor3 = Color3.fromRGB(255, 255, 255)
_call153.Font = Enum.Font.GothamBold
_call153.TextSize = 10
Instance.new('UICorner', _call153)

local _call167 = Instance.new('TextButton', _call62)
_call167.Text = 'RIGHT SIDE'
_call167.Position = UDim2.new(0.52, 0, 0.55, 0)
_call167.Size = UDim2.new(0.38, 0, 0, 30)
_call167.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
_call167.TextColor3 = Color3.fromRGB(255, 255, 255)
_call167.Font = Enum.Font.GothamBold
_call167.TextSize = 10
Instance.new('UICorner', _call167)

local _call181 = Instance.new('TextButton', _call62)
_call181.Text = 'STOP DUEL'
_call181.Position = UDim2.new(0.1, 0, 0.7, 0)
_call181.Size = UDim2.new(0.8, 0, 0, 35)
_call181.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
_call181.TextColor3 = Color3.fromRGB(255, 50, 50)
_call181.Font = Enum.Font.GothamBold
_call181.TextSize = 12
Instance.new('UICorner', _call181)

local _call195 = Instance.new('UIGradient', _call181)
_call195.Color = _call46.Color

-- Fix button clicks
_call181.MouseButton1Click:Connect(function()
    stopStealPath()       -- stop movement engine
    _call22.WalkSpeed = 16
end)

_call153.MouseButton1Click:Connect(function()
    stopStealPath()           -- stop any active path
    startStealPath(stealPath2) -- start left path (Luni010 left logic)
end)

_call167.MouseButton1Click:Connect(function()
    stopStealPath()           -- stop any active path
    startStealPath(stealPath1) -- start right path (Luni010 right logic)
end)

-- Fixed Heartbeat (removed intentional error)
_call5.Heartbeat:Connect(function()
    pcall(function()
        local fps = math.floor(1 / _call5.RenderStepped:Wait())
        local ping = math.floor(_call7.Network.ServerStatsItem['Data Ping']:GetValue())
        _call87.Text = 'FPS: ' .. fps .. ' | PING: ' .. ping
    end)
end)

-- Fixed Gradient Rotation Animation
task.spawn(function()
    local rot = 0
    while task.wait(0.02) do
        rot = (rot + 3) % 360
        _call46.Rotation = rot
        _call84.Rotation = rot
        _call195.Rotation = rot
    end
end)

-- Insta Grab Section
if game:GetService('CoreGui'):FindFirstChild('LUNI_INSTA_GRAB') then
    game:GetService('CoreGui').LUNI_INSTA_GRAB:Destroy()
end

local _call282 = Instance.new('ScreenGui', game:GetService('CoreGui'))
_call282.Name = 'LUNI_INSTA_GRAB'
_call282.ResetOnSpawn = false

local _call306 = Instance.new('Frame', _call282)
_call306.Size = UDim2.new(0, 150, 0, 35)
_call306.Position = UDim2.new(1, -160, 0, 15)
_call306.BackgroundColor3 = Color3.fromRGB(15, 10, 20)
_call306.Active = true
_call306.Draggable = true
Instance.new('UICorner', _call306).CornerRadius = UDim.new(0, 8)

local _call318 = Instance.new('UIStroke', _call306)
_call318.Thickness = 2
local _call320 = Instance.new('UIGradient', _call318)
_call320.Color = ColorSequence.new({
    [1] = ColorSequenceKeypoint.new(0, Color3.fromRGB(160, 32, 240)),
    [2] = ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
    [3] = ColorSequenceKeypoint.new(1, Color3.fromRGB(160, 32, 240)),
})

task.spawn(function()
    local rot = 0
    while task.wait(0.02) do
        rot = (rot + 4) % 360
        _call320.Rotation = rot
    end
end)

local _call341 = Instance.new('TextLabel', _call306)
_call341.Size = UDim2.new(1, 0, 1, 0)
_call341.BackgroundTransparency = 1
_call341.Text = 'INSTA GRAB LUNI'
_call341.TextColor3 = Color3.new(1, 1, 1)
_call341.Font = Enum.Font.GothamBold
_call341.TextSize = 10
