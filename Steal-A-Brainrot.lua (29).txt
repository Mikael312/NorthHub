local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local StarterPlayer = game:GetService("StarterPlayer")
local CoreGui = game:GetService("CoreGui")
local GuiService = game:GetService("GuiService")
local TeleportService = game:GetService("TeleportService")

local player = Players.LocalPlayer
local LocalPlayer = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- Anti-ragdoll protection variables
local antiRagdollConnections = {}
local antiRagdollMonitoringConnections = {}
local MAX_VELOCITY = 100
local MAX_ANGULAR_VELOCITY = 100

-- Bypassed
local grappleHookConnection = nil

-- Variables to track steal count
local lastStealCount = 0
local isMonitoring = false

-- Platform variables
local platformEnabled = false
local currentPlatform = nil
local platformUpdateConnection = nil
local PLATFORM_OFFSET = 3.6
-- Variables for slow fall
local SLOW_FALL_SPEED = -0.45 
local originalGravity = nil
local bodyVelocity = nil
local elevationBodyVelocity = nil

-- Wall transparency variables
local wallTransparencyEnabled = false
local originalTransparencies = {}
local TRANSPARENCY_LEVEL = 0.6
local playerCollisionConnection = nil

-- Combo Float + Wall variables
local comboFloatEnabled = false
local comboCurrentPlatform = nil
local comboPlatformUpdateConnection = nil
local comboPlayerCollisionConnection = nil
local COMBO_PLATFORM_OFFSET = 3.7

-- Teleport to Highest Brainrot variables (replaced steal variables)
local teleportEnabled = false
local teleportGrappleConnection = nil
local lastClickTime = 0
local DOUBLE_CLICK_PREVENTION_TIME = 1.5
local highestBrainrotData = nil
local teleportOverlay = nil

-- Highest Value ESP variables
local highestValueESP = nil
local highestValueData = nil
local espUpdateConnection = nil

-- Target brainrot names for detection
local brainrotNames = {
    "Los Tralaleritos",
    "Guerriro Digitale",
    "Las Tralaleritas",
    "Job Job Job Sahur",
    "Las Vaquitas Saturnitas",
    "Graipuss Medussi",
    "Noo My Hotspot",
    "Sahur Combinasion",
    "Pot Hotspot",
    "Chicleteira Bicicleteira",
    "Los Nooo My Hotspotsitos",
    "La Grande Combinasion",
    "Los Combinasionas",
    "Nuclearo Dinossauro",
    "Karkerkar combinasion",
    "Los Hotspotsitos",
    "Tralaledon",
    "Esok Sekolah",
    "Ketupat Kepat",
    "Los Bros",
    "La Supreme Combinasion",
    "Ketchuru and Masturu",
    "Garama and Madundung",
    "Las Vaquitas Saturnitas",
    "Chicleteira Bicicleteira",
    "Spaghetti Tualetti",
    "Dragon Cannelloni",
    "Blackhole Goat",
    "Agarrini la Palini",
    "Los Spyderinis",
    "Fragola la la la",
    "Strawberry Elephant"
}

-- Create lookup table for faster checking
local brainrotLookup = {}
for _, name in pairs(brainrotNames) do
    brainrotLookup[name] = true
end

-- ESP variables
local plotDisplays = {}
local playerBaseName = LocalPlayer.DisplayName .. "'s Base"
local playerBaseTimeWarning = false
local alertGui = nil

local playerGui = player:WaitForChild("PlayerGui")

-- DECLARE UI ELEMENTS (moved to top)
local screenGui, mainFrame, titleBar, closeButton, floatButton, wallButton, teleportButton, creditLabel

-- Helper Functions (defined first)
local function addHoverEffect(button, hoverColor, originalColor)
    if not button then return end
    
    button.MouseEnter:Connect(function()
        if button == floatButton then
            if platformEnabled then
                button.BackgroundColor3 = Color3.fromRGB(50, 180, 80)
            else
                button.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            end
        elseif button == wallButton then
            if wallTransparencyEnabled then
                button.BackgroundColor3 = Color3.fromRGB(180, 80, 30)
            else
                button.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            end
        else
            button.BackgroundColor3 = hoverColor
        end
    end)
    
    button.MouseLeave:Connect(function()
        if button == floatButton then
            if platformEnabled then
                button.BackgroundColor3 = Color3.fromRGB(0, 150, 50)
            else
                button.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            end
        elseif button == wallButton then
            if wallTransparencyEnabled then
                button.BackgroundColor3 = Color3.fromRGB(150, 50, 0)
            else
                button.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            end
        else
            button.BackgroundColor3 = originalColor
        end
    end)
end

-- Character handling function (defined early)
local function onCharacterAdded(newCharacter)
    character = newCharacter
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")

    task.wait(0.5) -- Wait for character to fully load
    setupAntiRagdollProtection()
    
    -- Reset all velocity variables
    originalGravity = nil
    bodyVelocity = nil
    elevationBodyVelocity = nil

    if platformEnabled then
        task.wait(1)
        
        if currentPlatform then
            currentPlatform:Destroy()
        end
        
        currentPlatform = createPlatform()
        applySlowFall()
        updatePlatformPosition()
        
        task.wait(0.5)
    end
end

-- Create UI Elements
screenGui = Instance.new("ScreenGui")
screenGui.Name = "im"
screenGui.Parent = playerGui
screenGui.ResetOnSpawn = false

mainFrame = Instance.new("Frame")
mainFrame.Name = "the"
mainFrame.Size = UDim2.new(0, 280, 0, 150)
mainFrame.Position = UDim2.new(1, -290, 0, 140)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 8)
mainCorner.Parent = mainFrame

titleBar = Instance.new("Frame")
titleBar.Name = "best"
titleBar.Size = UDim2.new(1, 0, 0, 30)
titleBar.Position = UDim2.new(0, 0, 0, 0)
titleBar.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 8)
titleCorner.Parent = titleBar

local titleText = Instance.new("TextLabel")
titleText.Name = "ever"
titleText.Size = UDim2.new(1, -30, 1, 0)
titleText.Position = UDim2.new(0, 5, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "💰 Steal A Brainrot 💰"
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.TextScaled = true
titleText.Font = Enum.Font.GothamBold
titleText.Parent = titleBar

closeButton = Instance.new("TextButton")
closeButton.Name = "lol"
closeButton.Size = UDim2.new(0, 25, 0, 25)
closeButton.Position = UDim2.new(1, -27, 0, 2)
closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextScaled = true
closeButton.Font = Enum.Font.GothamBold
closeButton.BorderSizePixel = 0
closeButton.Parent = titleBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 4)
closeCorner.Parent = closeButton

floatButton = Instance.new("TextButton")
floatButton.Name = "can't"
floatButton.Size = UDim2.new(0, 130, 0, 35)
floatButton.Position = UDim2.new(0, 10, 0, 45)
floatButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
floatButton.Text = "🚹 FLOAT 🚹"
floatButton.TextColor3 = Color3.fromRGB(255, 255, 255)
floatButton.TextScaled = true
floatButton.Font = Enum.Font.GothamBold
floatButton.BorderSizePixel = 0
floatButton.Parent = mainFrame

local floatCorner = Instance.new("UICorner")
floatCorner.CornerRadius = UDim.new(0, 6)
floatCorner.Parent = floatButton

wallButton = Instance.new("TextButton")
wallButton.Name = "detect"
wallButton.Size = UDim2.new(0, 130, 0, 35)
wallButton.Position = UDim2.new(0, 150, 0, 45)
wallButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
wallButton.Text = "💰 FLOOR STEAL 💰"
wallButton.TextColor3 = Color3.fromRGB(255, 255, 255)
wallButton.TextScaled = true
wallButton.Font = Enum.Font.GothamBold
wallButton.BorderSizePixel = 0
wallButton.Parent = mainFrame

local wallCorner = Instance.new("UICorner")
wallCorner.CornerRadius = UDim.new(0, 6)
wallCorner.Parent = wallButton

-- TELEPORT TO HIGHEST BRAINROT BUTTON (renamed from stealButton)
teleportButton = Instance.new("TextButton")
teleportButton.Name = "💰"
teleportButton.Size = UDim2.new(1, -20, 0, 25)
teleportButton.Position = UDim2.new(0, 10, 0, 90)
teleportButton.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
teleportButton.Text = "🧠 TELEPORT TO HIGHEST BRAINROT 🧠"
teleportButton.TextColor3 = Color3.fromRGB(0, 0, 0)
teleportButton.TextScaled = true
teleportButton.Font = Enum.Font.GothamBold
teleportButton.BorderSizePixel = 0
teleportButton.Parent = mainFrame

local teleportCorner = Instance.new("UICorner")
teleportCorner.CornerRadius = UDim.new(0, 6)
teleportCorner.Parent = teleportButton

creditLabel = Instance.new("TextLabel")
creditLabel.Name = "😆"
creditLabel.Size = UDim2.new(1, -20, 0, 20)
creditLabel.Position = UDim2.new(0, 10, 0, 120)
creditLabel.BackgroundTransparency = 1
creditLabel.Text = "by PickleTalk"
creditLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
creditLabel.TextScaled = true
creditLabel.Font = Enum.Font.Gotham
creditLabel.TextXAlignment = Enum.TextXAlignment.Left
creditLabel.Parent = mainFrame

-- Dragging functionality
local dragging = false
local dragStart = nil
local startPos = nil

local function updateDrag(input)
    local delta = input.Position - dragStart
    mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

titleBar.InputBegan:Connect(function(input)
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

titleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        if dragging then
            updateDrag(input)
        end
    end
end)

-- Function to safely get character components for anti-ragdoll
local function getAntiRagdollComponents()
    local success, result = pcall(function()
        if not LocalPlayer.Character then
            return false
        end
        
        local char = LocalPlayer.Character
        local hum = char:FindFirstChild("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        
        return char and hum and root
    end)
    
    return success and result
end

-- Function to prevent ragdolling
local function preventRagdoll()
    if not (humanoid and humanoid.Parent) then
        return
    end
    
    pcall(function()
        -- Prevent PlatformStand (main ragdoll trigger)
        if humanoid.PlatformStand then
            humanoid.PlatformStand = false
        end
        
        -- Keep humanoid state normal
        if humanoid:GetState() == Enum.HumanoidStateType.Physics then
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
            humanoid:ChangeState(Enum.HumanoidStateType.Running)
        end
        
        -- Restore joint connections if broken
        for _, part in pairs(character:GetChildren()) do
            if part:IsA("BasePart") and part ~= rootPart then
                local joint = part:FindFirstChild("RootJoint") or 
                            part:FindFirstChild("Neck") or 
                            part:FindFirstChild("Right Shoulder") or 
                            part:FindFirstChild("Left Shoulder") or 
                            part:FindFirstChild("Right Hip") or 
                            part:FindFirstChild("Left Hip")
                
                if joint and joint:IsA("Motor6D") then
                    joint.Enabled = true
                end
            end
        end
    end)
end

-- Function to prevent excessive velocity (anti-fling)
local function preventFling()
    if not (rootPart and rootPart.Parent) then
        return
    end
    
    pcall(function()
        local velocity = rootPart.AssemblyLinearVelocity
        local angularVelocity = rootPart.AssemblyAngularVelocity
        
        -- Check linear velocity
        if velocity.Magnitude > MAX_VELOCITY then
            rootPart.AssemblyLinearVelocity = velocity.Unit * MAX_VELOCITY
        end
        
        -- Check angular velocity
        if angularVelocity.Magnitude > MAX_ANGULAR_VELOCITY then
            rootPart.AssemblyAngularVelocity = angularVelocity.Unit * MAX_ANGULAR_VELOCITY
        end
        
        -- Anchor briefly if velocity is extreme
        if velocity.Magnitude > MAX_VELOCITY * 3 then
            rootPart.Anchored = true
            wait(0.1)
            if rootPart and rootPart.Parent then
                rootPart.Anchored = false
            end
        end
    end)
end

-- Function to disable TouchInterest on SentryBullet objects
local function disableSentryBulletTouch(sentryBullet)
    pcall(function()
        if not sentryBullet or not sentryBullet.Parent then
            return
        end
        
        -- Method 1: Remove TouchInterest directly
        local touchInterest = sentryBullet:FindFirstChild("TouchInterest")
        if touchInterest then
            touchInterest:Destroy()
            print("🛡️ Disabled TouchInterest on:", sentryBullet.Name)
        end
        
        -- Method 2: Disable CanTouch property
        if sentryBullet:IsA("BasePart") then
            sentryBullet.CanTouch = false
        end
        
        -- Method 3: Make it non-collidable with player
        sentryBullet.CanCollide = false
        
        -- Method 4: Move to different collision group
        pcall(function()
            sentryBullet.CollisionGroup = "SentryBulletDisabled"
        end)
    end)
end

-- Function to monitor and disable new SentryBullet objects
local function monitorSentryBullets()
    -- Monitor existing SentryBullet objects
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name == "SentryBullet" and obj:IsA("BasePart") then
            disableSentryBulletTouch(obj)
        end
    end
    
    -- Monitor new SentryBullet objects being added
    local connection = Workspace.DescendantAdded:Connect(function(descendant)
        if descendant.Name == "SentryBullet" and descendant:IsA("BasePart") then
            wait() -- Small delay to ensure object is fully loaded
            disableSentryBulletTouch(descendant)
        end
    end)
    
    table.insert(antiRagdollMonitoringConnections, connection)
end

-- Function to setup anti-ragdoll protection for character
local function setupAntiRagdollProtection()
    if not getAntiRagdollComponents() then
        return false
    end
    
    print("🛡️ Setting up anti-ragdoll protection for:", character.Name)
    
    -- Clear previous connections
    for _, connection in pairs(antiRagdollConnections) do
        if connection and connection.Connected then
            connection:Disconnect()
        end
    end
    antiRagdollConnections = {}
    
    -- Anti-ragdoll protection - Monitor humanoid state changes
    local stateConnection = humanoid.StateChanged:Connect(function(oldState, newState)
        if newState == Enum.HumanoidStateType.Physics then
            preventRagdoll()
        end
    end)
    table.insert(antiRagdollConnections, stateConnection)
    
    -- Monitor PlatformStand changes
    local platformConnection = humanoid:GetPropertyChangedSignal("PlatformStand"):Connect(function()
        if humanoid.PlatformStand then
            preventRagdoll()
        end
    end)
    table.insert(antiRagdollConnections, platformConnection)
    
    -- Anti-fling protection
    local heartbeatConnection = RunService.Heartbeat:Connect(function()
        preventFling()
    end)
    table.insert(antiRagdollConnections, heartbeatConnection)
    
    -- Touched event override for SentryBullet (backup method)
    for _, part in pairs(character:GetChildren()) do
        if part:IsA("BasePart") then
            local touchConnection = part.Touched:Connect(function(hit)
                if hit.Name == "SentryBullet" then
                    -- Block the touch event by not allowing it to propagate
                    return
                end
            end)
            table.insert(antiRagdollConnections, touchConnection)
        end
    end
    
    print("🛡️ Anti-ragdoll protection setup complete")
    return true
end

-- Function to cleanup anti-ragdoll connections
local function cleanupAntiRagdoll()
    for _, connection in pairs(antiRagdollConnections) do
        if connection and connection.Connected then
            connection:Disconnect()
        end
    end
    antiRagdollConnections = {}
    
    for _, connection in pairs(antiRagdollMonitoringConnections) do
        if connection and connection.Connected then
            connection:Disconnect()
        end
    end
    antiRagdollMonitoringConnections = {}
end

-- Grapple Hook Functions (shared by all features)
local function equipGrappleHook()
    local backpack = player:FindFirstChild("Backpack")
    local character = player.Character
    
    if backpack and character then
        local grappleHook = backpack:FindFirstChild("Grapple Hook")
        if grappleHook and grappleHook:IsA("Tool") then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid:EquipTool(grappleHook)
            end
        end
    end
end

local function unEquipGrappleHook()
    local backpack = player:FindFirstChild("Backpack")
    local character = player.Character
    
    if backpack and character then
        local grappleHook = backpack:FindFirstChild("Grapple Hook")
        if grappleHook and grappleHook:IsA("Tool") then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid:UnequipTool(grappleHook)
            end
        end
    end
end

local function fireGrappleHook()
    local args = {0.08707536856333414}
    
    local success, error = pcall(function()
        ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Net"):WaitForChild("RE/UseItem"):FireServer(unpack(args))
    end)
    
    if not success then
        warn("Failed to fire grapple hook: " .. tostring(error))
    end
end

local function equipAndFireGrapple()
    fireGrappleHook()
    equipGrappleHook()
end

-- NEW QUANTUM CLONER FUNCTIONS
local function equipQuantumCloner()
    local backpack = player:FindFirstChild("Backpack")
    local character = player.Character
    
    if backpack and character then
        local quantumCloner = backpack:FindFirstChild("Quantum Cloner")
        if quantumCloner and quantumCloner:IsA("Tool") then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid:EquipTool(quantumCloner)
                print("✅ Equipped Quantum Cloner")
                return true
            end
        else
            warn("❌ Quantum Cloner not found in backpack")
            return false
        end
    end
    return false
end

local function fireQuantumCloner()
    local success, error = pcall(function()
        ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Net"):WaitForChild("RE/UseItem"):FireServer()
    end)
    
    if not success then
        warn("Failed to fire Quantum Cloner: " .. tostring(error))
    end
end

local function fireQuantumClonerTeleport()
    local success, error = pcall(function()
        ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Net"):WaitForChild("RE/QuantumCloner/OnTeleport"):FireServer()
    end)
    
    if not success then
        warn("Failed to fire Quantum Cloner teleport: " .. tostring(error))
    end
end

-- Function to safely get steal count from leaderstats
local function getStealCount()
    local success, result = pcall(function()
        -- Check if LocalPlayer exists
        if not LocalPlayer then
            return 0
        end
        
        -- Check if leaderstats exists
        local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
        if not leaderstats then
            warn("Leaderstats not found for LocalPlayer")
            return 0
        end
        
        -- Check if Steals stat exists
        local stealsObject = leaderstats:FindFirstChild("Steals")
        if not stealsObject then
            warn("Steals stat not found in leaderstats")
            return 0
        end
        
        -- Get the value - handle both IntValue/NumberValue and StringValue
        local stealValue
        if stealsObject:IsA("IntValue") or stealsObject:IsA("NumberValue") then
            stealValue = stealsObject.Value
        elseif stealsObject:IsA("StringValue") then
            stealValue = tonumber(stealsObject.Value) or 0
        else
            -- Fallback to Text property if it exists
            if stealsObject.Text then
                stealValue = tonumber(stealsObject.Text) or 0
            else
                stealValue = tonumber(tostring(stealsObject.Value)) or 0
            end
        end
        
        return stealValue
    end)
    
    if success then
        return result
    else
        warn("Error getting steal count: " .. tostring(result))
        return 0
    end
end

-- Function to kick the player
local function kickPlayer()
    local success, error = pcall(function()
        LocalPlayer:Kick("Steal Success!!!!!")
    end)
    
    if not success then
        warn("Failed to kick player: " .. tostring(error))
        -- Alternative method if kick fails
        game:Shutdown()
    end
end

-- Main monitoring function
local function monitorSteals()
    if isMonitoring then
        return -- Prevent multiple instances
    end
    
    isMonitoring = true
    print("Starting steal monitoring...")
    
    -- Initialize last steal count
    lastStealCount = getStealCount()
    print("Initial steal count: " .. tostring(lastStealCount))
    
    -- Create monitoring loop
    spawn(function()
        while isMonitoring do
            wait(0.1) -- Check every 0.1 seconds for responsiveness
            
            local currentStealCount = getStealCount()
            
            -- Check if steal count increased
            if currentStealCount > lastStealCount then
                print("Steal detected! Count increased from " .. 
                      tostring(lastStealCount) .. " to " .. tostring(currentStealCount))
                
                isMonitoring = false -- Stop monitoring
                wait(0.1) -- Small delay before kicking
                kickPlayer()
                break
            end
            
            lastStealCount = currentStealCount
        end
    end)
end

-- Function to stop monitoring
local function stopMonitoring()
    isMonitoring = false
    print("Steal monitoring stopped")
end

-- Wait for leaderstats to load before starting
local function waitForLeaderstats()
    print("Waiting for leaderstats to load...")
    
    -- Wait for LocalPlayer if not available
    if not LocalPlayer then
        Players.PlayerAdded:Wait()
        LocalPlayer = Players.LocalPlayer
    end
    
    -- Wait for leaderstats to exist
    local leaderstats = LocalPlayer:WaitForChild("leaderstats", 30)
    if not leaderstats then
        warn("Leaderstats failed to load within 30 seconds")
        return false
    end
    
    -- Wait for Steals stat to exist
    local stealsObject = leaderstats:WaitForChild("Steals", 10)
    if not stealsObject then
        warn("Steals stat failed to load within 10 seconds")
        return false
    end
    
    print("Leaderstats loaded successfully")
    return true
end

-- Main execution
print("=== Auto Leave on Steal Script ===")
print("Initializing...")

-- Enhanced parsePrice function that handles the price format correctly
local function parsePrice(priceText)
    if not priceText or priceText == "" or priceText == "N/A" then
        return 0
    end
    
    -- Remove common formatting and convert to uppercase for consistency
    local cleanPrice = priceText:gsub("[,$]", ""):upper()
    
    -- Extract the number part (including decimals)
    local number = tonumber(cleanPrice:match("%d*%.?%d+"))
    if not number then return 0 end
    
    -- Handle abbreviations (both uppercase and lowercase)
    if cleanPrice:find("T") then
        return number * 1000000000000  -- Trillion
    elseif cleanPrice:find("B") then
        return number * 1000000000     -- Billion
    elseif cleanPrice:find("M") then
        return number * 1000000        -- Million
    elseif cleanPrice:find("K") then
        return number * 1000           -- Thousand
    elseif cleanPrice:find("S") then
        return number                  -- Just the number (seconds/base)
    end
    
    return number
end

-- Fixed function to scan for highest value brainrot using the correct path structure
local function findHighestBrainrot()
    local plots = workspace:FindFirstChild("Plots")
    if not plots then 
        warn("⚠ Plots folder not found in workspace")
        return nil 
    end
    
    local highestBrainrot = nil
    local highestValue = 0
    
    print("🔍 Scanning for highest value brainrot using correct plot structure...")
    
    -- Use the same method as obfuscated.lua to iterate through plots
    for _, plot in pairs(plots:GetChildren()) do
        if plot:IsA("Model") or plot:IsA("Folder") then
            local plotName = plot.Name
            
            -- Check if this plot has AnimalPodiums
            local animalPodiums = plot:FindFirstChild("AnimalPodiums")
            if animalPodiums then
                print("📋 Checking plot: " .. plotName .. " for brainrots...")
                
                -- Check podiums 1-30 (ignore if number doesn't exist)
                for i = 1, 30 do
                    local podium = animalPodiums:FindFirstChild(tostring(i))
                    if podium then
                        local base = podium:FindFirstChild("Base")
                        if base then
                            local spawn = base:FindFirstChild("Spawn")
                            if spawn then
                                local attachment = spawn:FindFirstChild("Attachment")
                                if attachment then
                                    local animalOverhead = attachment:FindFirstChild("AnimalOverhead")
                                    if animalOverhead then
                                        local priceLabel = animalOverhead:FindFirstChild("Generation")
                                        if priceLabel and priceLabel.Text and priceLabel.Text ~= "" and priceLabel.Text ~= "N/A" then
                                            local priceValue = parsePrice(priceLabel.Text)
                                            
                                            print("💰 Found price on podium " .. i .. " in plot " .. plotName .. ": " .. priceLabel.Text .. " (parsed: " .. priceValue .. ")")
                                            
                                            -- Check if this price is higher than current highest
                                            if priceValue > highestValue then
                                                -- Check if the decorations part exists for teleportation
                                                local decorations = base:FindFirstChild("Decorations")
                                                if decorations then
                                                    local teleportPart = decorations:FindFirstChild("Part")
                                                    if teleportPart then
                                                        highestValue = priceValue
                                                        highestBrainrot = {
                                                            plot = plot,
                                                            plotName = plotName,
                                                            podiumNumber = i,
                                                            price = priceLabel.Text,
                                                            priceValue = priceValue,
                                                            teleportPart = teleportPart,
                                                            position = teleportPart.Position,
                                                            -- Get additional info if available
                                                            rarity = animalOverhead:FindFirstChild("Rarity") and animalOverhead.Rarity.Text or "Unknown",
                                                            mutation = animalOverhead:FindFirstChild("Mutation") and animalOverhead.Mutation.Text or "None"
                                                        }
                                                        print("💎 New highest brainrot found: " .. priceLabel.Text .. " (" .. priceValue .. ") in plot " .. plotName .. " podium " .. i)
                                                    else
                                                        warn("⚠ Teleport part not found in decorations for podium " .. i .. " in plot " .. plotName)
                                                    end
                                                else
                                                    warn("⚠ Decorations not found for podium " .. i .. " in plot " .. plotName)
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    if highestBrainrot then
        print("🏆 Highest value brainrot found:")
        print("   Plot: " .. highestBrainrot.plotName)
        print("   Podium: " .. highestBrainrot.podiumNumber)
        print("   Price: " .. highestBrainrot.price .. " (value: " .. highestBrainrot.priceValue .. ")")
        print("   Rarity: " .. highestBrainrot.rarity)
        print("   Mutation: " .. highestBrainrot.mutation)
        return highestBrainrot
    else
        warn("⚠ No brainrots with valid prices found")
        return nil
    end
end

-- Create ESP for highest value animal
local function createHighestValueESP(brainrotData)
    if not brainrotData or not brainrotData.teleportPart then return end
    
    -- Remove existing ESP
    if highestValueESP then
        if highestValueESP.highlight then highestValueESP.highlight:Destroy() end
        if highestValueESP.nameLabel then highestValueESP.nameLabel:Destroy() end
        if highestValueESP.tracer then 
            if highestValueESP.tracer.beam then highestValueESP.tracer.beam:Destroy() end
            if highestValueESP.tracer.attachment0 then highestValueESP.tracer.attachment0:Destroy() end
            if highestValueESP.tracer.attachment1 then highestValueESP.tracer.attachment1:Destroy() end
        end
        if highestValueESP.structureHighlight then highestValueESP.structureHighlight:Destroy() end
    end
    
    local espContainer = {}
    
    -- Create highlight for the animal area
    local highlight = Instance.new("Highlight")
    highlight.Parent = brainrotData.teleportPart
    highlight.FillColor = Color3.fromRGB(255, 215, 0) -- Gold color
    highlight.OutlineColor = Color3.fromRGB(255, 255, 0) -- Bright yellow
    highlight.FillTransparency = 0.7
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    espContainer.highlight = highlight
    
    -- Create name label with all data
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Parent = brainrotData.teleportPart
    billboardGui.Size = UDim2.new(0, 180, 0, 80)
    billboardGui.StudsOffset = Vector3.new(0, 8, 0)
    billboardGui.AlwaysOnTop = true
    
    local containerFrame = Instance.new("Frame")
    containerFrame.Parent = billboardGui
    containerFrame.Size = UDim2.new(1, 0, 1, 0)
    containerFrame.BackgroundTransparency = 1
    
    -- Mutation text (above animal name, super small)
    local mutationLabel = Instance.new("TextLabel")
    mutationLabel.Parent = containerFrame
    mutationLabel.Size = UDim2.new(1, 0, 0.15, 0)
    mutationLabel.Position = UDim2.new(0, 0, 0, 0)
    mutationLabel.BackgroundTransparency = 1
    mutationLabel.Text = brainrotData.mutation or ""
    mutationLabel.TextColor3 = Color3.new(1, 1, 1)
    mutationLabel.TextStrokeTransparency = 0
    mutationLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    mutationLabel.TextScaled = true
    mutationLabel.TextSize = 8
    mutationLabel.Font = Enum.Font.SourceSans
    
    -- Animal name label
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Parent = containerFrame
    nameLabel.Size = UDim2.new(1, 0, 0.4, 0)
    nameLabel.Position = UDim2.new(0, 0, 0.15, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = "HIGHEST VALUE BRAINROT"
    nameLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    nameLabel.TextScaled = true
    nameLabel.TextSize = 14
    nameLabel.Font = Enum.Font.SourceSansBold
    
    -- Price label
    local moneyLabel = Instance.new("TextLabel")
    moneyLabel.Parent = containerFrame
    moneyLabel.Size = UDim2.new(1, 0, 0.25, 0)
    moneyLabel.Position = UDim2.new(0, 0, 0.55, 0)
    moneyLabel.BackgroundTransparency = 1
    moneyLabel.Text = brainrotData.price or ""
    moneyLabel.TextColor3 = Color3.new(0, 1, 0)
    moneyLabel.TextStrokeTransparency = 0
    moneyLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    moneyLabel.TextScaled = true
    moneyLabel.TextSize = 10
    moneyLabel.Font = Enum.Font.SourceSans
    
    -- Rarity label
    local rarityLabel = Instance.new("TextLabel")
    rarityLabel.Parent = containerFrame
    rarityLabel.Size = UDim2.new(1, 0, 0.2, 0)
    rarityLabel.Position = UDim2.new(0, 0, 0.8, 0)
    rarityLabel.BackgroundTransparency = 1
    rarityLabel.Text = brainrotData.rarity or ""
    rarityLabel.TextScaled = true
    rarityLabel.TextSize = 8
    rarityLabel.Font = Enum.Font.SourceSans
    
    -- Special rarity colors
    if brainrotData.rarity == "Secret" then
        rarityLabel.TextColor3 = Color3.new(0, 0, 0)
        rarityLabel.TextStrokeTransparency = 0
        rarityLabel.TextStrokeColor3 = Color3.new(1, 1, 1)
    elseif brainrotData.rarity == "Brainrot God" then
        task.spawn(function()
            local hue = 0
            while rarityLabel and rarityLabel.Parent do
                hue = (hue + 0.01) % 1
                rarityLabel.TextColor3 = Color3.fromHSV(hue, 1, 1)
                task.wait(0.1)
            end
        end)
        rarityLabel.TextStrokeTransparency = 0
        rarityLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    else
        rarityLabel.TextColor3 = Color3.new(1, 1, 1)
        rarityLabel.TextStrokeTransparency = 0
        rarityLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    end
    
    espContainer.nameLabel = billboardGui
    
    -- Create tracer
    local camera = workspace.CurrentCamera
    if camera then
        local attachment0 = Instance.new("Attachment")
        attachment0.Parent = camera
        attachment0.Position = Vector3.new(0, 0, 0)
        
        local attachment1 = Instance.new("Attachment")
        attachment1.Parent = brainrotData.teleportPart
        
        local beam = Instance.new("Beam")
        beam.Parent = workspace
        beam.Attachment0 = attachment0
        beam.Attachment1 = attachment1
        beam.Width0 = 1
        beam.Width1 = 1
        beam.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0))
        beam.Transparency = NumberSequence.new(0.3)
        beam.FaceCamera = true
        
        espContainer.tracer = {beam = beam, attachment0 = attachment0, attachment1 = attachment1}
    end
    
    -- Highlight structure base home
    local structureBaseHome = brainrotData.plot:FindFirstChild("structure base home")
    if structureBaseHome then
        local structureHighlight = Instance.new("Highlight")
        structureHighlight.Parent = structureBaseHome
        structureHighlight.FillColor = Color3.fromRGB(255, 215, 0)
        structureHighlight.OutlineColor = Color3.fromRGB(255, 255, 0)
        structureHighlight.FillTransparency = 0.8
        structureHighlight.OutlineTransparency = 0.2
        structureHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        espContainer.structureHighlight = structureHighlight
    end
    
    highestValueESP = espContainer
    highestValueData = brainrotData
end

-- Update ESP for highest value animal
local function updateHighestValueESP()
    local newHighestBrainrot = findHighestBrainrot()
    
    -- Only update if we found a different highest value
    if newHighestBrainrot and (not highestValueData or 
        newHighestBrainrot.priceValue > highestValueData.priceValue or
        newHighestBrainrot.plotName ~= highestValueData.plotName or
        newHighestBrainrot.podiumNumber ~= highestValueData.podiumNumber) then
        
        createHighestValueESP(newHighestBrainrot)
        print("📍 Updated highest value ESP: " .. newHighestBrainrot.price .. " in " .. newHighestBrainrot.plotName)
    end
end

-- Remove highest value ESP
local function removeHighestValueESP()
    if highestValueESP then
        if highestValueESP.highlight then highestValueESP.highlight:Destroy() end
        if highestValueESP.nameLabel then highestValueESP.nameLabel:Destroy() end
        if highestValueESP.tracer then 
            if highestValueESP.tracer.beam then highestValueESP.tracer.beam:Destroy() end
            if highestValueESP.tracer.attachment0 then highestValueESP.tracer.attachment0:Destroy() end
            if highestValueESP.tracer.attachment1 then highestValueESP.tracer.attachment1:Destroy() end
        end
        if highestValueESP.structureHighlight then highestValueESP.structureHighlight:Destroy() end
        highestValueESP = nil
        highestValueData = nil
    end
end

-- Create teleport overlay UI
local function createTeleportOverlay()
    if teleportOverlay then
        teleportOverlay:Destroy()
    end
    
    teleportOverlay = Instance.new("ScreenGui")
    teleportOverlay.Name = "TeleportOverlay"
    teleportOverlay.Parent = playerGui
    teleportOverlay.ResetOnSpawn = false
    
    local overlayFrame = Instance.new("Frame")
    overlayFrame.Size = UDim2.new(1, 0, 1, 0)
    overlayFrame.Position = UDim2.new(0, 0, 0, 0)
    overlayFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlayFrame.BackgroundTransparency = 0.5
    overlayFrame.BorderSizePixel = 0
    overlayFrame.Parent = teleportOverlay
    
    local loadingFrame = Instance.new("Frame")
    loadingFrame.Size = UDim2.new(0, 400, 0, 200)
    loadingFrame.Position = UDim2.new(0.5, -200, 0.5, -100)
    loadingFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    loadingFrame.BorderSizePixel = 0
    loadingFrame.Parent = overlayFrame
    
    local loadingCorner = Instance.new("UICorner")
    loadingCorner.CornerRadius = UDim.new(0, 12)
    loadingCorner.Parent = loadingFrame
    
    local loadingTitle = Instance.new("TextLabel")
    loadingTitle.Size = UDim2.new(1, -20, 0, 50)
    loadingTitle.Position = UDim2.new(0, 10, 0, 10)
    loadingTitle.BackgroundTransparency = 1
    loadingTitle.Text = "🧠 TELEPORTING TO HIGHEST BRAINROT! 🧠"
    loadingTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
    loadingTitle.TextScaled = true
    loadingTitle.Font = Enum.Font.GothamBold
    loadingTitle.Parent = loadingFrame
    
    local loadingStatus = Instance.new("TextLabel")
    loadingStatus.Size = UDim2.new(1, -20, 0, 30)
    loadingStatus.Position = UDim2.new(0, 10, 0, 70)
    loadingStatus.BackgroundTransparency = 1
    loadingStatus.Text = "Scanning for highest value brainrot..."
    loadingStatus.TextColor3 = Color3.fromRGB(255, 255, 255)
    loadingStatus.TextScaled = true
    loadingStatus.Font = Enum.Font.Gotham
    loadingStatus.Parent = loadingFrame
    
    local loadingBar = Instance.new("Frame")
    loadingBar.Size = UDim2.new(0.8, 0, 0, 8)
    loadingBar.Position = UDim2.new(0.1, 0, 0, 120)
    loadingBar.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    loadingBar.BorderSizePixel = 0
    loadingBar.Parent = loadingFrame
    
    local loadingBarCorner = Instance.new("UICorner")
    loadingBarCorner.CornerRadius = UDim.new(0, 4)
    loadingBarCorner.Parent = loadingBar
    
    local loadingProgress = Instance.new("Frame")
    loadingProgress.Size = UDim2.new(0, 0, 1, 0)
    loadingProgress.Position = UDim2.new(0, 0, 0, 0)
    loadingProgress.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    loadingProgress.BorderSizePixel = 0
    loadingProgress.Parent = loadingBar
    
    local loadingProgressCorner = Instance.new("UICorner")
    loadingProgressCorner.CornerRadius = UDim.new(0, 4)
    loadingProgressCorner.Parent = loadingProgress
    
    local brainrotInfo = Instance.new("TextLabel")
    brainrotInfo.Size = UDim2.new(1, -20, 0, 40)
    brainrotInfo.Position = UDim2.new(0, 10, 0, 140)
    brainrotInfo.BackgroundTransparency = 1
    brainrotInfo.Text = ""
    brainrotInfo.TextColor3 = Color3.fromRGB(0, 255, 0)
    brainrotInfo.TextScaled = true
    brainrotInfo.Font = Enum.Font.GothamBold
    brainrotInfo.Parent = loadingFrame
    
    return {
        overlay = teleportOverlay,
        statusLabel = loadingStatus,
        progressBar = loadingProgress,
        brainrotInfo = brainrotInfo
    }
end

-- Remove teleport overlay
local function removeTeleportOverlay()
    if teleportOverlay then
        teleportOverlay:Destroy()
        teleportOverlay = nil
    end
end


-- Updated teleport function that uses the correct teleportation target
local function executeTeleportToHighestBrainrot()
    local currentTime = tick()
    
    -- Double click prevention
    if currentTime - lastClickTime < DOUBLE_CLICK_PREVENTION_TIME then
        print("⏳ Please wait " .. math.ceil(DOUBLE_CLICK_PREVENTION_TIME - (currentTime - lastClickTime)) .. " seconds")
        return
    end
    
    lastClickTime = currentTime
    
    if teleportEnabled then
        -- Cancel teleport process
        print("❌ Cancelling teleport process...")
        teleportEnabled = false
        teleportButton.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
        teleportButton.Text = "🧠 TELEPORT TO HIGHEST BRAINROT 🧠"
        removeTeleportOverlay()
        return
    end
    
    -- Start teleport process
    print("🧠 Starting teleport to highest brainrot process...")
    teleportEnabled = true
    teleportButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
    teleportButton.Text = "❌ CANCEL TELEPORT ❌"
    
    -- Create loading overlay
    local overlay = createTeleportOverlay()
    
    task.spawn(function()
        -- Step 1: Find highest brainrot
        overlay.statusLabel.Text = "🔍 Scanning for highest value brainrot..."
        TweenService:Create(overlay.progressBar, TweenInfo.new(0.5), {Size = UDim2.new(0.2, 0, 1, 0)}):Play()
        
        if not teleportEnabled then
            removeTeleportOverlay()
            return
        end
        
        highestBrainrotData = findHighestBrainrot()
        
        if not highestBrainrotData then
            overlay.statusLabel.Text = "❌ No brainrots found!"
            task.wait(2)
            teleportEnabled = false
            teleportButton.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
            teleportButton.Text = "🧠 TELEPORT TO HIGHEST BRAINROT 🧠"
            removeTeleportOverlay()
            return
        end
        
        -- Step 2: Display found brainrot info
        overlay.statusLabel.Text = "💎 Found highest brainrot!"
        overlay.brainrotInfo.Text = "Plot: " .. highestBrainrotData.plotName .. " | Slot: " .. highestBrainrotData.podiumNumber .. "\nPrice: " .. highestBrainrotData.price .. " | Rarity: " .. highestBrainrotData.rarity
        TweenService:Create(overlay.progressBar, TweenInfo.new(0.5), {Size = UDim2.new(0.4, 0, 1, 0)}):Play()
        task.wait(0.5)
            
        if not teleportEnabled then
            removeTeleportOverlay()
            return
        end

        TweenService:Create(overlay.progressBar, TweenInfo.new(0.5), {Size = UDim2.new(0.6, 0, 1, 0)}):Play()
        
        local equipped = equipQuantumCloner()
        if not equipped then
            overlay.statusLabel.Text = "❌ Quantum Cloner not found!"
            task.wait(2)
            teleportEnabled = false
            teleportButton.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
            teleportButton.Text = "🧠 TELEPORT TO HIGHEST BRAINROT 🧠"
            removeTeleportOverlay()
            return
        end
        
        if not teleportEnabled then
            removeTeleportOverlay()
            return
        end

        -- Step 4: Teleport to the correct position (Decorations Part)
        overlay.statusLabel.Text = "🌟 Teleporting to highest brainrot..."
        TweenService:Create(overlay.progressBar, TweenInfo.new(0.5), {Size = UDim2.new(0.9, 0, 1, 0)}):Play()
        
        if highestBrainrotData.teleportPart then
            local character = player.Character
            if character and character:FindFirstChild("HumanoidRootPart") then
                -- Teleport to the decorations part position with slight offset
                local targetPosition = highestBrainrotData.teleportPart.Position + Vector3.new(0, 5, 0)
                    for i = 1, 3 do
                    fireQuantumCloner()
                    task.wait(0.3314)
                    character.HumanoidRootPart.CFrame = CFrame.new(targetPosition)
                    task.wait(1.5)
                    fireQuantumClonerTeleport()
                    if not teleportEnabled then
                        removeTeleportOverlay()
                        return
                    end
                end
        
                if not teleportEnabled then
                    removeTeleportOverlay()
                    return
                end
                
                print("✅ Teleported to highest brainrot at: " .. tostring(targetPosition))
                print("   Plot: " .. highestBrainrotData.plotName .. " | Podium: " .. highestBrainrotData.podiumNumber)
            end
        else
            overlay.statusLabel.Text = "❌ Teleport position not found!"
            task.wait(2)
        end
        
        -- Step 6: Complete
        overlay.statusLabel.Text = "✅ Teleport completed!"
        TweenService:Create(overlay.progressBar, TweenInfo.new(0.3), {Size = UDim2.new(1, 0, 1, 0)}):Play()
        task.wait(1)
        
        -- Reset state
        teleportEnabled = false
        teleportButton.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
        teleportButton.Text = "🧠 TELEPORT TO HIGHEST BRAINROT 🧠"
        removeTeleportOverlay()
        
        print("✅ Teleport to highest brainrot completed!")
    end)
end

-- Add this NEW function for permanent player ESP (always-on green ESP)
local function createPermanentPlayerESP(player)
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    local humanoidRootPart = player.Character.HumanoidRootPart
    
    -- Remove existing permanent highlight
    local existingHighlight = humanoidRootPart:FindFirstChild("PermanentHighlight")
    if existingHighlight then
        existingHighlight:Destroy()
    end
    
    -- Create permanent highlight effect ONLY (no billboard)
    local highlight = Instance.new("Highlight")
    highlight.Name = "PermanentHighlight"
    highlight.Parent = humanoidRootPart
    highlight.FillColor = Color3.fromRGB(0, 255, 0)
    highlight.OutlineColor = Color3.fromRGB(0, 200, 0)
    highlight.FillTransparency = 0.6
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    
    print("✅ Created permanent HumanoidRootPart ESP for: " .. player.DisplayName)
end

-- Add this function to initialize permanent ESP for all existing players
local function initializePermanentESP()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            createPermanentPlayerESP(player)
        end
    end
end

-- Platform creation and management functions
local function createPlatform()
    local platform = Instance.new("Part")
    platform.Name = "😆"
    platform.Size = Vector3.new(8, 0.5, 8)
    platform.Material = Enum.Material.Neon
    platform.BrickColor = BrickColor.new("Bright blue")
    platform.Anchored = true
    platform.CanCollide = true
    platform.Shape = Enum.PartType.Block
    platform.TopSurface = Enum.SurfaceType.Smooth
    platform.BottomSurface = Enum.SurfaceType.Smooth
    platform.Parent = workspace
    platform.Transparency = 1
    
    local pointLight = Instance.new("PointLight")
    pointLight.Color = Color3.fromRGB(0, 162, 255)
    pointLight.Brightness = 1
    pointLight.Range = 10
    pointLight.Parent = platform
    
    return platform
end

local function updatePlatformPosition()
    if not platformEnabled or not currentPlatform or not player.Character then
        return
    end
    
    local character = player.Character
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    
    if humanoidRootPart then
        local playerPosition = humanoidRootPart.Position
        local platformPosition = Vector3.new(
            playerPosition.X, 
            playerPosition.Y - PLATFORM_OFFSET, 
            playerPosition.Z
        )
        currentPlatform.Position = platformPosition
    end
end

local function applySlowFall()
    -- This function now does nothing - just keeps the grapple hook functionality
    if not player.Character then return end
    
    local character = player.Character
    local humanoid = character:FindFirstChild("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not rootPart then return end
    
    -- Double tap detection variables
    local lastTapTime = 0
    local DOUBLE_TAP_DELAY = 0.3
    
    local function performJump()
        if humanoid then
            -- First equip and fire grapple hook
            equipAndFireGrapple()
            
            -- Small delay then jump
            task.spawn(function()
                task.wait(0.1)
                if platformEnabled and humanoid then
                    -- Force jump
                    humanoid.Jump = true
                    equipAndFireGrapple()
                    unEquipGrappleHook()
                end
            end)
        end
    end
    
    -- Handle jump input (space bar)
    UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
        if gameProcessedEvent then return end
        
        if input.KeyCode == Enum.KeyCode.Space and platformEnabled then
            local currentTime = tick()
            
            -- Check for double tap
            if currentTime - lastTapTime <= DOUBLE_TAP_DELAY then
                -- Double tap detected - perform enhanced jump with grapple
                performJump()
            end
            
            lastTapTime = currentTime
        end
    end)
end

local function removeSlowFall()
    if originalGravity and player.Character then
        local character = player.Character
        local humanoid = character:FindFirstChild("Humanoid")
        
        if humanoid then
            -- Reset to normal gravity behavior
            if bodyVelocity then
                bodyVelocity:Destroy()
                bodyVelocity = nil
            end
            if elevationBodyVelocity then
                elevationBodyVelocity:Destroy()
                elevationBodyVelocity = nil
            end
        end
    end
    originalGravity = nil
end

local function createComboPlatform()
    local platform = Instance.new("Part")
    platform.Name = "😆"
    platform.Size = Vector3.new(8, 1.5, 8)
    platform.Material = Enum.Material.Neon
    platform.BrickColor = BrickColor.new("Bright blue")
    platform.Anchored = true
    platform.CanCollide = true
    platform.Shape = Enum.PartType.Block
    platform.TopSurface = Enum.SurfaceType.Smooth
    platform.BottomSurface = Enum.SurfaceType.Smooth
    platform.Parent = workspace
    platform.Transparency = 1
    
    local pointLight = Instance.new("PointLight")
    pointLight.Color = Color3.fromRGB(0, 162, 255)
    pointLight.Brightness = 1
    pointLight.Range = 15
    pointLight.Parent = platform
    
    return platform
end

local function updateComboPlatformPosition()
    if not comboFloatEnabled or not comboCurrentPlatform or not player.Character then
        return
    end
    
    local character = player.Character
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    
    if humanoidRootPart then
        local playerPosition = humanoidRootPart.Position
        local platformPosition = Vector3.new(
            playerPosition.X, 
            playerPosition.Y - COMBO_PLATFORM_OFFSET, 
            playerPosition.Z
        )
        comboCurrentPlatform.Position = platformPosition
    end
end

-- Wall transparency functions
local function storeOriginalTransparencies()
    originalTransparencies = {}
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Parent ~= player.Character and obj.Name ~= "PlayerPlatform" and obj.Name ~= "ComboPlayerPlatform" then
            local name = obj.Name
            if name == "structure base home" then
                originalTransparencies[obj] = {
                    transparency = obj.Transparency,
                    canCollide = obj.CanCollide
                }
            end
        end
    end
    print("Stored transparency for " .. #originalTransparencies .. " parts")
end

local function makeWallsTransparent(transparent)
    local count = 0
    for obj, data in pairs(originalTransparencies) do
        if obj and obj.Parent and data then
            if transparent then
                obj.Transparency = TRANSPARENCY_LEVEL
                obj.CanCollide = false
                count = count + 1
            else
                obj.Transparency = data.transparency
                obj.CanCollide = data.canCollide
            end
        end
    end
    print((transparent and "Made transparent: " or "Restored: ") .. count .. " parts")
end

local function forcePlayerHeadCollision()
    if player.Character then
        local head = player.Character:FindFirstChild("Head")
        if head then
            head.CanCollide = true
        end
        -- Also ensure other body parts maintain collision
        local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
        if humanoidRootPart then
            humanoidRootPart.CanCollide = true
        end
        local torso = player.Character:FindFirstChild("Torso") or player.Character:FindFirstChild("UpperTorso")
        if torso then
            torso.CanCollide = true
        end
    end
end

-- Main toggle functions
local function enablePlatform()
    if platformEnabled then return end
    
    platformEnabled = true
    currentPlatform = createPlatform()
    
    -- Apply slow fall effect
    applySlowFall()
    
    platformUpdateConnection = RunService.Heartbeat:Connect(updatePlatformPosition)
    updatePlatformPosition()

    -- Start the continuous loop for both equipping and firing
    if not grappleHookConnection then
        grappleHookConnection = task.spawn(function()
            while platformEnabled do
                task.wait(2)
                equipAndFireGrapple()
                task.wait(0.1)
                unEquipGrappleHook()
            end
        end)
        print("- Continuously firing grapple hook RemoteEvent every 2 seconds")
    end
    
    floatButton.BackgroundColor3 = Color3.fromRGB(0, 150, 50)
    floatButton.Text = "🚹 FLOAT 🚹"
end

local function disablePlatform()
    if not platformEnabled then return end

    platformEnabled = false
    
    -- Remove platform update connection
    if platformUpdateConnection then
        platformUpdateConnection:Disconnect()
        platformUpdateConnection = nil
    end
    
    if currentPlatform then
        currentPlatform:Destroy()
        currentPlatform = nil
    end
    
    -- STOP GRAPPLE HOOK LOOP
    if grappleHookConnection then
        task.cancel(grappleHookConnection)
        grappleHookConnection = nil
        print("🎣 Grapple Hook fire loop stopped!")
        equipAndFireGrapple()
        task.wait(0.5)
        equipAndFireGrapple()
    end
    
    floatButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    floatButton.Text = "🚹 FLOAT 🚹"
end

local function enableWallTransparency()
    if wallTransparencyEnabled then return end
    
    print("Enabling wall transparency...")
    wallTransparencyEnabled = true
    comboFloatEnabled = true
    
    storeOriginalTransparencies()
    makeWallsTransparent(true)
    
    -- Create and manage platform
    comboCurrentPlatform = createComboPlatform()
    comboPlatformUpdateConnection = RunService.Heartbeat:Connect(updateComboPlatformPosition)
    updateComboPlatformPosition()
    
    -- Force player collision more aggressively
    comboPlayerCollisionConnection = RunService.Heartbeat:Connect(function()
        forcePlayerHeadCollision()
    end)
    
    -- Also set initial collision state
    forcePlayerHeadCollision()

    -- Start the continuous loop for both equipping and firing
    if not grappleHookConnection then
        grappleHookConnection = task.spawn(function()
            while wallTransparencyEnabled do
                task.wait(1.5)
                equipAndFireGrapple()
                task.wait(0.1)
                unEquipGrappleHook()
            end
        end)
        print("- Continuously firing grapple hook RemoteEvent every 1.5 seconds")
    end
    
    wallButton.BackgroundColor3 = Color3.fromRGB(150, 50, 0)
    wallButton.Text = "💰 FLOOR STEAL 💰"
end

local function disableWallTransparency()
    if not wallTransparencyEnabled then return end
    
    print("Disabling wall transparency...")
    wallTransparencyEnabled = false
    comboFloatEnabled = false
    
    makeWallsTransparent(false)
    originalTransparencies = {}
    
    -- Stop platform updates and remove platform
    if comboPlatformUpdateConnection then
        comboPlatformUpdateConnection:Disconnect()
        comboPlatformUpdateConnection = nil
    end
    
    if comboCurrentPlatform then
        comboCurrentPlatform:Destroy()
        comboCurrentPlatform = nil
    end
    
    -- Stop head collision enforcement
    if comboPlayerCollisionConnection then
        comboPlayerCollisionConnection:Disconnect()
        comboPlayerCollisionConnection = nil
    end
    
    -- STOP GRAPPLE HOOK LOOP
    if grappleHookConnection then
        task.cancel(grappleHookConnection)
        grappleHookConnection = nil
        print("🎣 Grapple Hook fire loop stopped!")
    end
    
    -- Restore normal player collision state
    if player.Character then
        local head = player.Character:FindFirstChild("Head")
        if head then
            head.CanCollide = false -- Default Roblox state for head
        end
    end
    
    wallButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    wallButton.Text = "💰 FLOOR STEAL 💰"
end

-- ESP Functions
local function createAlertGui()
    if alertGui then return end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    screenGui.Name = "😆"
    screenGui.ResetOnSpawn = false
    
    local frame = Instance.new("Frame")
    frame.Parent = screenGui
    frame.Size = UDim2.new(0, 300, 0, 80)
    frame.Position = UDim2.new(0.5, -150, 0.1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    frame.BorderSizePixel = 0
    
    local corner = Instance.new("UICorner")
    corner.Parent = frame
    corner.CornerRadius = UDim.new(0, 8)
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Parent = frame
    textLabel.Size = UDim2.new(1, -10, 1, -10)
    textLabel.Position = UDim2.new(0, 5, 0, 5)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = "⚠️ BASE TIME WARNING ⚠️"
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.TextScaled = true
    textLabel.TextStrokeTransparency = 0
    textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    textLabel.Font = Enum.Font.SourceSansBold
    
    local tween = TweenService:Create(
        frame,
        TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {BackgroundColor3 = Color3.fromRGB(150, 0, 0)}
    )
    tween:Play()
    
    alertGui = {
        screenGui = screenGui,
        textLabel = textLabel,
        tween = tween
    }
end

local function updateAlertGui(timeText)
    if not alertGui then return end
    alertGui.textLabel.Text = "⚠️ BASE UNLOCKING IN " .. timeText .. " ⚠️"
end

local function removeAlertGui()
    if alertGui then
        if alertGui.tween then
            alertGui.tween:Cancel()
        end
        alertGui.screenGui:Destroy()
        alertGui = nil
        playerBaseTimeWarning = false
    end
end

local function parseTimeToSeconds(timeText)
    if not timeText or timeText == "" then return nil end
    
    local minutes, seconds = timeText:match("(%d+):(%d+)")
    if minutes and seconds then
        return tonumber(minutes) * 60 + tonumber(seconds)
    end
    
    local secondsOnly = timeText:match("(%d+)s")
    if secondsOnly then
        return tonumber(secondsOnly)
    end
    
    local minutesOnly = timeText:match("(%d+)m")
    if minutesOnly then
        return tonumber(minutesOnly) * 60
    end
    
    return nil
end

function createPlayerESP(player, head)
    local existingGui = head:FindFirstChild("PlayerESP")
    if existingGui then
        existingGui:Destroy()
    end
    
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "😆"
    billboardGui.Parent = head
    billboardGui.Size = UDim2.new(0, 90, 0, 33)
    billboardGui.StudsOffset = Vector3.new(0, 2, 0)
    billboardGui.AlwaysOnTop = true
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Parent = billboardGui
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = player.DisplayName
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.TextScaled = true
    textLabel.TextStrokeTransparency = 0.3
    textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    textLabel.Font = Enum.Font.SourceSans
end

local function createPlayerDisplay(player)
    if player == LocalPlayer then return end
    
    local character = player.Character
    if not character then
        player.CharacterAdded:Connect(function(char)
            character = char
            task.wait(0.5)
            local head = character:FindFirstChild("Head")
            if head then
                createPlayerESP(player, head)
            end
        end)
        return
    end
    
    local head = character:FindFirstChild("Head")
    if head then
        createPlayerESP(player, head)
    else
        character.ChildAdded:Connect(function(child)
            if child.Name == "Head" then
                createPlayerESP(player, child)
            end
        end)
    end
end

local function createOrUpdatePlotDisplay(plot)
    if not plot or not plot.Parent then return end
    
    local plotName = plot.Name
    
    local plotSignText = ""
    local signPath = plot:FindFirstChild("PlotSign")
    if signPath and signPath:FindFirstChild("SurfaceGui") then
        local surfaceGui = signPath.SurfaceGui
        if surfaceGui:FindFirstChild("Frame") and surfaceGui.Frame:FindFirstChild("TextLabel") then
            plotSignText = surfaceGui.Frame.TextLabel.Text
        end
    end
    
    if plotSignText == "Empty Base" or plotSignText == "" or plotSignText == "Empty's Base" then
        if plotDisplays[plotName] and plotDisplays[plotName].gui then
            plotDisplays[plotName].gui:Destroy()
            plotDisplays[plotName] = nil
        end
        return
    end
    
    local plotTimeText = ""
    local purchasesPath = plot:FindFirstChild("Purchases")
    if purchasesPath and purchasesPath:FindFirstChild("PlotBlock") then
        local plotBlock = purchasesPath.PlotBlock
        if plotBlock:FindFirstChild("Main") and plotBlock.Main:FindFirstChild("BillboardGui") then
            local billboardGui = plotBlock.Main.BillboardGui
            if billboardGui:FindFirstChild("RemainingTime") then
                plotTimeText = billboardGui.RemainingTime.Text
            end
        end
    end
    
    if plotSignText == playerBaseName then
        local remainingSeconds = parseTimeToSeconds(plotTimeText)
        
        if remainingSeconds and remainingSeconds <= 10 and remainingSeconds > 0 then
            if not playerBaseTimeWarning then
                createAlertGui()
                playerBaseTimeWarning = true
            end
            updateAlertGui(plotTimeText)
        elseif remainingSeconds and remainingSeconds > 10 then
            if playerBaseTimeWarning then
                removeAlertGui()
            end
        elseif not remainingSeconds or remainingSeconds <= 0 then
            if playerBaseTimeWarning then
                removeAlertGui()
            end
        end
    end
    
    local displayPart = plot:FindFirstChild("PlotSign")
    if not displayPart then
        for _, child in pairs(plot:GetChildren()) do
            if child:IsA("Part") or child:IsA("MeshPart") then
                displayPart = child
                break
            end
        end
    end
    
    if not displayPart then return end
    
    if not plotDisplays[plotName] then
        local existingBillboard = displayPart:FindFirstChild("PlotESP")
        if existingBillboard then
            existingBillboard:Destroy()
        end
        
        local billboardGui = Instance.new("BillboardGui")
        billboardGui.Name = "😆"
        billboardGui.Parent = displayPart
        billboardGui.Size = UDim2.new(0, 150, 0, 60)
        billboardGui.StudsOffset = Vector3.new(0, 8, 0)
        billboardGui.AlwaysOnTop = true
        
        local frame = Instance.new("Frame")
        frame.Parent = billboardGui
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.BackgroundTransparency = 0.7
        frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        frame.BorderSizePixel = 0
        
        local corner = Instance.new("UICorner")
        corner.Parent = frame
        corner.CornerRadius = UDim.new(0, 4)
        
        local signLabel = Instance.new("TextLabel")
        signLabel.Parent = frame
        signLabel.Size = UDim2.new(1, -4, 0.6, 0)
        signLabel.Position = UDim2.new(0, 2, 0, 2)
        signLabel.BackgroundTransparency = 1
        signLabel.Text = plotSignText
        signLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        signLabel.TextScaled = true
        signLabel.TextStrokeTransparency = 0.3
        signLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        signLabel.Font = Enum.Font.SourceSansBold
        
        local timeLabel = Instance.new("TextLabel")
        timeLabel.Parent = frame
        timeLabel.Size = UDim2.new(1, -4, 0.4, 0)
        timeLabel.Position = UDim2.new(0, 2, 0.6, 0)
        timeLabel.BackgroundTransparency = 1
        timeLabel.Text = plotTimeText
        timeLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
        timeLabel.TextScaled = true
        timeLabel.TextStrokeTransparency = 0.3
        timeLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        timeLabel.Font = Enum.Font.SourceSans
        
        plotDisplays[plotName] = {
            gui = billboardGui,
            signLabel = signLabel,
            timeLabel = timeLabel,
            plot = plot
        }
    else
        if plotDisplays[plotName].signLabel then
            plotDisplays[plotName].signLabel.Text = plotSignText
        end
        if plotDisplays[plotName].timeLabel then
            plotDisplays[plotName].timeLabel.Text = plotTimeText
        end
    end
end

local function updateAllPlots()
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return end
    
    for _, plot in pairs(plots:GetChildren()) do
        if plot:IsA("Model") or plot:IsA("Folder") then
            pcall(function()
                createOrUpdatePlotDisplay(plot)
            end)
        end
    end
    
    for plotName, display in pairs(plotDisplays) do
        if not plots:FindFirstChild(plotName) then
            if display.gui then
                display.gui:Destroy()
            end
            plotDisplays[plotName] = nil
        end
    end
end

-- Jump delay removal functions
local jumpDelayConnections = {}

local function cleanupJumpDelayConnections(character)
    if jumpDelayConnections[character] then
        for _, connection in pairs(jumpDelayConnections[character]) do
            if connection and connection.Connected then
                connection:Disconnect()
            end
        end
        jumpDelayConnections[character] = nil
    end
end

local function setupNoJumpDelay(character)
    cleanupJumpDelayConnections(character)
    
    local humanoid = character:WaitForChild("Humanoid")
    if not humanoid then return end
    
    jumpDelayConnections[character] = {}

    local stateConnection = humanoid.StateChanged:Connect(function(oldState, newState)
        if newState == Enum.HumanoidStateType.Landed then
            task.spawn(function()
                task.wait()
                if humanoid and humanoid.Parent then
                    humanoid:ChangeState(Enum.HumanoidStateType.Running)
                end
            end)
        end
    end)
    
    jumpDelayConnections[character][#jumpDelayConnections[character] + 1] = stateConnection
    
    local cleanupConnection = character.AncestryChanged:Connect(function()
        if not character.Parent then
            cleanupJumpDelayConnections(character)
        end
    end)
    
    jumpDelayConnections[character][#jumpDelayConnections[character] + 1] = cleanupConnection
end

local function removeJumpDelay()
    if player.Character and player.Character.Parent then
        setupNoJumpDelay(player.Character)
    end
    
    local characterAddedConnection = player.CharacterAdded:Connect(function(character)
        task.wait(0.5)
        if character and character.Parent then
            setupNoJumpDelay(character)
        end
    end)
    
    local characterRemovingConnection = player.CharacterRemoving:Connect(function(character)
        cleanupJumpDelayConnections(character)
    end)
end

-- EVENT CONNECTIONS AND INITIALIZATION

-- Character respawn handling
player.CharacterRemoving:Connect(function()
    platformEnabled = false
    wallTransparencyEnabled = false
    comboFloatEnabled = false
    teleportEnabled = false
    
    if currentPlatform then currentPlatform:Destroy() end
    if comboCurrentPlatform then comboCurrentPlatform:Destroy() end
    if grappleHookConnection then task.cancel(grappleHookConnection) end
    if teleportGrappleConnection then task.cancel(teleportGrappleConnection) end
    if teleportOverlay then removeTeleportOverlay() end
    
    -- Reset button states
    floatButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    floatButton.Text = "🚹 FLOAT 🚹"
    wallButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    wallButton.Text = "💰 FLOOR STEAL 💰"
    teleportButton.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    teleportButton.Text = "🧠 TELEPORT TO HIGHEST BRAINROT 🧠"
end)

player.CharacterAdded:Connect(onCharacterAdded)

-- Initialize ESP
for _, playerObj in pairs(Players:GetPlayers()) do
    if playerObj ~= LocalPlayer then
        createPlayerDisplay(playerObj)
        playerObj.CharacterAdded:Connect(function()
            task.wait(0.5)
            createPlayerDisplay(playerObj)
        end)
    end
end

initializePermanentESP()

Players.PlayerAdded:Connect(function(newPlayer)
    newPlayer.CharacterAdded:Connect(function(character)
        task.wait(1) -- Wait for character to fully load
        createPermanentPlayerESP(newPlayer)
    end)
end)

-- Handle player respawning
for _, player in pairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        player.CharacterAdded:Connect(function(character)
            task.wait(1) -- Wait for character to fully load
            createPermanentPlayerESP(player)
        end)
    end
end

-- Clean up highlights when players leave
Players.PlayerRemoving:Connect(function(leavingPlayer)
    if leavingPlayer.Character then
        local head = leavingPlayer.Character:FindFirstChild("Head")
        local hrp = leavingPlayer.Character:FindFirstChild("HumanoidRootPart")
        
        if head then
            local permanentESP = head:FindFirstChild("PermanentESP")
            if permanentESP then permanentESP:Destroy() end
        end
        
        if hrp then
            local permanentHighlight = hrp:FindFirstChild("PermanentHighlight")
            if permanentHighlight then permanentHighlight:Destroy() end
            removeHighestValueESP()
        end
    end
end)

Players.PlayerAdded:Connect(function(playerObj)
    if playerObj ~= LocalPlayer then
        createPlayerDisplay(playerObj)
        playerObj.CharacterAdded:Connect(function()
            task.wait(0.5)
            createPlayerDisplay(playerObj)
        end)
    end
end)

updateAllPlots()

local plots = workspace:FindFirstChild("Plots")
if plots then
    plots.ChildAdded:Connect(function(child)
        if child:IsA("Model") or child:IsA("Folder") then
            task.wait(0.5)
            createOrUpdatePlotDisplay(child)
        end
    end)
end

if waitForLeaderstats() then
    monitorSteals()
    
    print("Script active! Player will be kicked when steal count increases.")
    print("Current steal count: " .. tostring(getStealCount()))
else
    warn("Failed to initialize - leaderstats or Steals stat not found")
end

-- Cleanup on player leaving (good practice)
Players.PlayerRemoving:Connect(function(player)
    if player == LocalPlayer then
        stopMonitoring()
    end
end)

task.spawn(function()
    while true do
        task.wait(0.5)
        pcall(updateAllPlots)
    end
end)

-- Initialize highest value ESP system
task.spawn(function()
    task.wait(1) -- Wait for game to load
    updateHighestValueESP()
    
    -- Update ESP every 15 seconds
    espUpdateConnection = task.spawn(function()
        while true do
            task.wait(20)
            updateHighestValueESP()
        end
    end)
end)

monitorSentryBullets()

if LocalPlayer.Character then
    task.wait(0.5)
    setupAntiRagdollProtection()
end

-- BUTTON EVENT CONNECTIONS
floatButton.MouseButton1Click:Connect(function()
    local originalSize = floatButton.Size
    local clickTween = TweenService:Create(floatButton, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Size = UDim2.new(0, 125, 0, 33)})
    local releaseTween = TweenService:Create(floatButton, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Size = originalSize})
    
    clickTween:Play()
    clickTween.Completed:Connect(function()
        releaseTween:Play()
    end)
    
    if platformEnabled then
        disablePlatform()
    else
        enablePlatform()
    end
end)

wallButton.MouseButton1Click:Connect(function()
    local originalSize = wallButton.Size
    local clickTween = TweenService:Create(wallButton, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Size = UDim2.new(0, 125, 0, 33)})
    local releaseTween = TweenService:Create(wallButton, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Size = originalSize})
    
    clickTween:Play()
    clickTween.Completed:Connect(function()
        releaseTween:Play()
    end)
    
    if wallTransparencyEnabled then
        disableWallTransparency()
    else
        enableWallTransparency()
    end
end)

-- TELEPORT TO HIGHEST BRAINROT BUTTON FUNCTIONALITY
teleportButton.MouseButton1Click:Connect(function()
    executeTeleportToHighestBrainrot()
end)

-- Button hover effects
teleportButton.MouseEnter:Connect(function()
    if not teleportEnabled then
        teleportButton.BackgroundColor3 = Color3.fromRGB(255, 235, 20)
    end
end)

teleportButton.MouseLeave:Connect(function()
    if not teleportEnabled then
        teleportButton.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    end
end)

closeButton.MouseButton1Click:Connect(function()
    if platformEnabled then
        disablePlatform()
    end
    if wallTransparencyEnabled then
        disableWallTransparency()
    end
    if alertGui then
        removeAlertGui()
    end
    if teleportOverlay then
        removeTeleportOverlay()
    end
    
    -- Clean up all connections and objects
    if currentPlatform then currentPlatform:Destroy() end
    if comboCurrentPlatform then comboCurrentPlatform:Destroy() end
    if platformUpdateConnection then platformUpdateConnection:Disconnect() end
    if comboPlatformUpdateConnection then comboPlatformUpdateConnection:Disconnect() end
    if playerCollisionConnection then playerCollisionConnection:Disconnect() end
    if grappleHookConnection then task.cancel(grappleHookConnection) end
    if teleportGrappleConnection then task.cancel(teleportGrappleConnection) end
    
    pcall(removeSlowFall) -- Use pcall in case function has issues
    
    screenGui:Destroy()
    
    print("❌ Script closed and cleaned up")
end)

-- Apply hover effects
addHoverEffect(closeButton, Color3.fromRGB(220, 70, 70), Color3.fromRGB(200, 50, 50))
addHoverEffect(floatButton, Color3.fromRGB(30, 30, 30), Color3.fromRGB(0, 0, 0))
addHoverEffect(wallButton, Color3.fromRGB(30, 30, 30), Color3.fromRGB(0, 0, 0))

-- CLEANUP CONNECTIONS
game:BindToClose(function()
    if wallTransparencyEnabled then
        disableWallTransparency()
    end
    if alertGui then
        removeAlertGui()
    end
    if teleportOverlay then
        removeTeleportOverlay()
    end
end)

Players.PlayerRemoving:Connect(function(playerObj)
    if playerObj == LocalPlayer then
        removeAlertGui()
        if teleportOverlay then
            removeTeleportOverlay()
        end
    end
end)

-- Initialize jump delay removal
removeJumpDelay()

print("✅ Steal A Brainrot script loaded successfully!")
print("🚹 Float Button - Creates invisible platform beneath player")
print("💰 Floor Steal Button - Makes walls transparent + platform")
print("🧠 Teleport Button - Finds and teleports to highest value animal")
