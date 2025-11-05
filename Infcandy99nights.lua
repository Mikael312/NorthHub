-- North Hub | Infinite Candy ,-- Carnival Shooting Gallery Auto Complete Script dengan UI
-- Dibuat dengan GUI yang modern dan mudah digunakan

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Variabel utama
local isRunning = false
local heartbeatConnection
local targetParts = {}
local remoteEvent = ReplicatedStorage:FindFirstChild("RemoteEvents") 
    and ReplicatedStorage.RemoteEvents:FindFirstChild("CarnivalCompleteShootingGallery")

-- Fungsi untuk mengumpulkan semua BasePart
local function collectParts()
    targetParts = {}
    for _, obj in workspace:GetDescendants() do
        if obj:IsA("BasePart") then
            table.insert(targetParts, obj)
        end
    end
    return #targetParts
end

-- Buat ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CarnivalAutoGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Frame utama
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 350, 0, 250)
mainFrame.Position = UDim2.new(0.5, -175, 0.5, -125)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

-- Corner untuk frame
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = mainFrame

-- Header
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 50)
header.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
header.BorderSizePixel = 0
header.Parent = mainFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 12)
headerCorner.Parent = header

-- Fix corner di bagian bawah header
local headerFix = Instance.new("Frame")
headerFix.Size = UDim2.new(1, 0, 0, 12)
headerFix.Position = UDim2.new(0, 0, 1, -12)
headerFix.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
headerFix.BorderSizePixel = 0
headerFix.Parent = header

-- Title
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -100, 1, 0)
title.Position = UDim2.new(0, 15, 0, 0)
title.BackgroundTransparency = 1
title.Text = "North Hub | Infinite Candy"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 20
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseButton"
closeBtn.Size = UDim2.new(0, 35, 0, 35)
closeBtn.Position = UDim2.new(1, -45, 0.5, -17.5)
closeBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 18
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 0
closeBtn.Parent = header

local closeBtnCorner = Instance.new("UICorner")
closeBtnCorner.CornerRadius = UDim.new(0, 8)
closeBtnCorner.Parent = closeBtn

-- Content area
local content = Instance.new("Frame")
content.Name = "Content"
content.Size = UDim2.new(1, -30, 1, -80)
content.Position = UDim2.new(0, 15, 0, 60)
content.BackgroundTransparency = 1
content.Parent = mainFrame

-- Status label
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Size = UDim2.new(1, 0, 0, 25)
statusLabel.Position = UDim2.new(0, 0, 0, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: Stopped"
statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
statusLabel.TextSize = 16
statusLabel.Font = Enum.Font.GothamMedium
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = content

-- Parts count label
local partsLabel = Instance.new("TextLabel")
partsLabel.Name = "PartsLabel"
partsLabel.Size = UDim2.new(1, 0, 0, 25)
partsLabel.Position = UDim2.new(0, 0, 0, 30)
partsLabel.BackgroundTransparency = 1
partsLabel.Text = "Parts Found: 0"
partsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
partsLabel.TextSize = 14
partsLabel.Font = Enum.Font.Gotham
partsLabel.TextXAlignment = Enum.TextXAlignment.Left
partsLabel.Parent = content

-- Start/Stop button
local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "ToggleButton"
toggleBtn.Size = UDim2.new(1, 0, 0, 45)
toggleBtn.Position = UDim2.new(0, 0, 0, 70)
toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 100)
toggleBtn.Text = "Start"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.TextSize = 18
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.BorderSizePixel = 0
toggleBtn.Parent = content

local toggleBtnCorner = Instance.new("UICorner")
toggleBtnCorner.CornerRadius = UDim.new(0, 10)
toggleBtnCorner.Parent = toggleBtn

-- Refresh button
local refreshBtn = Instance.new("TextButton")
refreshBtn.Name = "RefreshButton"
refreshBtn.Size = UDim2.new(1, 0, 0, 35)
refreshBtn.Position = UDim2.new(0, 0, 0, 125)
refreshBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 200)
refreshBtn.Text = "Refresh Parts"
refreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
refreshBtn.TextSize = 14
refreshBtn.Font = Enum.Font.GothamBold
refreshBtn.BorderSizePixel = 0
refreshBtn.Parent = content

local refreshBtnCorner = Instance.new("UICorner")
refreshBtnCorner.CornerRadius = UDim.new(0, 8)
refreshBtnCorner.Parent = refreshBtn

-- Fungsi untuk membuat draggable
local dragging
local dragInput
local dragStart
local startPos

local function update(input)
    local delta = input.Position - dragStart
    mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

header.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

Players.LocalPlayer:GetMouse().Move:Connect(function()
    if dragging and dragInput then
        update(dragInput)
    end
end)

-- Fungsi toggle script
local function toggleScript()
    isRunning = not isRunning
    
    if isRunning then
        -- Update UI
        toggleBtn.Text = "Stop"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
        statusLabel.Text = "Status: Running"
        statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        
        -- Jalankan script
        if remoteEvent and #targetParts > 0 then
            heartbeatConnection = RunService.Heartbeat:Connect(function()
                pcall(function()
                    remoteEvent:FireServer(targetParts[math.random(#targetParts)])
                end)
            end)
        end
    else
        -- Update UI
        toggleBtn.Text = "Start"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 100)
        statusLabel.Text = "Status: Stopped"
        statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        
        -- Hentikan script
        if heartbeatConnection then
            heartbeatConnection:Disconnect()
            heartbeatConnection = nil
        end
    end
end

-- Fungsi refresh parts
local function refreshParts()
    local count = collectParts()
    partsLabel.Text = "Parts Found: " .. count
end

-- Button animations
local function animateButton(button)
    button.MouseButton1Down:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.1), {Size = button.Size - UDim2.new(0, 5, 0, 5)}):Play()
    end)
    
    button.MouseButton1Up:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.1), {Size = button.Size + UDim2.new(0, 5, 0, 5)}):Play()
    end)
end

animateButton(toggleBtn)
animateButton(refreshBtn)
animateButton(closeBtn)

-- Connect button events
toggleBtn.MouseButton1Click:Connect(toggleScript)
refreshBtn.MouseButton1Click:Connect(refreshParts)
closeBtn.MouseButton1Click:Connect(function()
    if heartbeatConnection then
        heartbeatConnection:Disconnect()
    end
    screenGui:Destroy()
end)

-- Initialize
refreshParts()
print("North Hub | Infinite Candy Script loaded successfully!")
print("Parts found: " .. #targetParts)
