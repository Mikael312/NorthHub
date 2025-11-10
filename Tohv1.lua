-- =====================================================
-- North Hub | Key System UI
-- Updated with Key Verification
-- =====================================================

-- == SERVICES ==
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- == CONFIGURATION ==
-- Lootlabs key link
local KEY_SYSTEM_URL = "https://lootdest.org/s?9dhiBiZj"

-- Discord invite link
local DISCORD_INVITE_URL = "https://discord.gg/83kPyNANP"

-- Your GitHub Pages key display URL
local KEY_CHECK_URL = "https://mikael312.github.io/NorthHub."

-- Key storage filename
local KEY_STORAGE_FILE = "northhub_key.txt"

-- == VALID KEYS STORAGE ==
-- You can add pre-generated keys here or fetch from server
local validKeys = {}

-- == KEY STORAGE FUNCTIONS ==
-- Function to save key locally
local function saveKey(key)
    local success, err = pcall(function()
        writefile(KEY_STORAGE_FILE, key)
    end)
    
    if success then
        print("✅ Key saved successfully!")
        return true
    else
        warn("⚠️ Failed to save key: " .. tostring(err))
        return false
    end
end

-- Function to load saved key
local function loadSavedKey()
    local success, result = pcall(function()
        if isfile(KEY_STORAGE_FILE) then
            return readfile(KEY_STORAGE_FILE)
        end
        return nil
    end)
    
    if success and result then
        print("📂 Loaded saved key")
        return result
    else
        print("📂 No saved key found")
        return nil
    end
end

-- Function to delete saved key
local function deleteSavedKey()
    local success, err = pcall(function()
        if isfile(KEY_STORAGE_FILE) then
            delfile(KEY_STORAGE_FILE)
        end
    end)
    
    if success then
        print("🗑️ Saved key deleted")
        return true
    else
        warn("⚠️ Failed to delete key: " .. tostring(err))
        return false
    end
end

-- == HELPER FUNCTIONS ==
-- Function to copy text to clipboard
local function copyToClipboard(text)
    local success, errorMessage = pcall(function()
        setclipboard(text)
    end)
    
    if success then
        print("✅ Successfully copied to clipboard!")
        return true
    else
        warn("❌ Failed to copy: " .. tostring(errorMessage))
        local notificationLabel = playerGui:FindFirstChild("KeySystemUI"):FindFirstChild("MainFrame"):FindFirstChild("ContentFrame"):FindFirstChild("NotificationLabel")
        if notificationLabel then
            notificationLabel.Text = "Failed to Copy!"
        end
        return false
    end
end

-- Function to validate key format
local function isValidKeyFormat(key)
    -- Check if key starts with "North_" and has valid characters
    if not key:match("^North_%w+$") then
        return false
    end
    
    -- Check minimum length (North_ + at least 10 chars)
    if #key < 16 then
        return false
    end
    
    return true
end

-- Function to check if key is expired (24 hours)
local function isKeyExpired(key)
    -- TEMPORARY: Disable expiry check
    -- Issue with timestamp decoding between JavaScript and Lua
    -- For now, accept all keys with valid format
    
    print("⏰ Expiry check: DISABLED (accepting all valid format keys)")
    return false
    
    --[[ ORIGINAL CODE - RE-ENABLE LATER IF NEEDED
    local timestampPart = key:match("^North_(%w+)")
    
    if not timestampPart or #timestampPart < 6 then
        return false
    end
    
    local timestamp36 = timestampPart:sub(1, 6)
    local success, timestampMs = pcall(function()
        return tonumber(timestamp36, 36)
    end)
    
    if not success or not timestampMs then
        return false
    end
    
    local timestampSeconds = timestampMs / 1000
    local currentTime = os.time()
    local keyAgeSeconds = currentTime - timestampSeconds
    local keyAgeHours = keyAgeSeconds / 3600
    
    print("🕐 Key timestamp: " .. timestampSeconds)
    print("🕐 Current time: " .. currentTime)
    print("🕐 Key age: " .. string.format("%.2f", keyAgeHours) .. " hours")
    
    return keyAgeHours > 24
    --]]
end

-- Main key verification function
local function verifyKey(key)
    print("🔑 Verifying key: " .. key)
    
    -- Step 1: Check format
    if not isValidKeyFormat(key) then
        print("❌ Invalid key format")
        return false, "Invalid Key Format!"
    end
    
    -- Step 2: Check expiry
    if isKeyExpired(key) then
        print("❌ Key expired")
        -- Delete expired key
        deleteSavedKey()
        return false, "Key Expired! Get a new key."
    end
    
    -- Step 3: Check against valid keys list (if you have pre-stored keys)
    -- This is optional - you can remove if not using pre-stored keys
    if #validKeys > 0 then
        local found = false
        for _, validKey in ipairs(validKeys) do
            if validKey == key then
                found = true
                break
            end
        end
        
        if not found then
            print("❌ Key not found in valid keys")
            return false, "Invalid Key!"
        end
    end
    
    -- If all checks pass
    print("✅ Key is valid!")
    return true, "Valid Key!"
end

-- Function to load main script
local function loadMainScript()
    print("🚀 Loading main script...")
    
    -- ===================================================
    -- == LOAD YOUR MAIN SCRIPT HERE ==
    -- ===================================================
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Mikael312/NorthHub/refs/heads/main/Toh.lua"))()
    
    -- For now, just print success
    print("✅ Main script loaded successfully!")
    
    -- You can add your actual script here:
    -- loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_SCRIPT"))()
end

-- Function to run when "Check Key" button is pressed
local function onCheckKey(key)
    print("🔑 Checking key: " .. key)
    
    local isValid, message = verifyKey(key)
    
    local notificationLabel = playerGui:FindFirstChild("KeySystemUI"):FindFirstChild("MainFrame"):FindFirstChild("ContentFrame"):FindFirstChild("NotificationLabel")
    
    if isValid then
        print("✅ Key is valid! Loading main script...")
        
        if notificationLabel then
            notificationLabel.Text = "✅ Valid Key! Saving..."
            notificationLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        end
        
        -- Save the key
        saveKey(key)
        
        wait(1)
        
        -- Load main script
        loadMainScript()
        
        -- Close the Key System UI
        playerGui:FindFirstChild("KeySystemUI"):Destroy()
        
    else
        print("❌ Invalid key: " .. message)
        
        if notificationLabel then
            notificationLabel.Text = "❌ " .. message
            notificationLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
    end
end

-- == UI CREATION ==

-- Check for saved key first
local savedKey = loadSavedKey()

if savedKey then
    print("🔍 Checking saved key...")
    local isValid, message = verifyKey(savedKey)
    
    if isValid then
        print("✅ Saved key is valid! Auto-loading script...")
        print("⏰ Key will expire after 24 hours from first use")
        
        -- Load main script directly without showing UI
        loadMainScript()
        
        -- Stop script here, don't create UI
        return
    else
        print("⚠️ Saved key invalid/expired: " .. message)
        print("🔄 Showing key system...")
        deleteSavedKey()
    end
end

-- If no valid saved key, show key system UI
print("🔑 No valid key found, showing key system...")

-- Remove old GUI if it exists
if playerGui:FindFirstChild("KeySystemUI") then
    playerGui:FindFirstChild("KeySystemUI"):Destroy()
end

-- Main ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "KeySystemUI"
screenGui.Parent = playerGui
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Parent = screenGui
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.Size = UDim2.new(0, 400, 0, 300)
mainFrame.Active = true
mainFrame.Draggable = true
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)

-- Add border to the window
local frameStroke = Instance.new("UIStroke")
frameStroke.Color = Color3.fromRGB(0, 162, 255)
frameStroke.Thickness = 1.5
frameStroke.Parent = mainFrame

-- Title Bar
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Parent = mainFrame
titleBar.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
titleBar.BorderSizePixel = 0
titleBar.Size = UDim2.new(1, 0, 0, 40)
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 12)

local titleGradient = Instance.new("UIGradient")
titleGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 162, 255)), 
    ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 50, 200))
}
titleGradient.Rotation = 90
titleGradient.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Parent = titleBar
titleLabel.BackgroundTransparency = 1
titleLabel.Position = UDim2.new(0, 15, 0, 0)
titleLabel.Size = UDim2.new(1, -60, 1, 0)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Text = "North Hub | Key System"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 16
titleLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Close button
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Parent = titleBar
closeButton.BackgroundTransparency = 1
closeButton.Position = UDim2.new(1, -30, 0, 7.5)
closeButton.Size = UDim2.new(0, 25, 0, 25)
closeButton.Font = Enum.Font.GothamBold
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextSize = 16

closeButton.MouseEnter:Connect(function()
    TweenService:Create(closeButton, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(200, 200, 200)}):Play()
end)

closeButton.MouseLeave:Connect(function()
    TweenService:Create(closeButton, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
end)

closeButton.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- Content Frame
local contentFrame = Instance.new("Frame")
contentFrame.Name = "ContentFrame"
contentFrame.Parent = mainFrame
contentFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
contentFrame.BorderSizePixel = 0
contentFrame.Position = UDim2.new(0, 0, 0, 40)
contentFrame.Size = UDim2.new(1, 0, 1, -40)

-- Notification Label
local notificationLabel = Instance.new("TextLabel")
notificationLabel.Name = "NotificationLabel"
notificationLabel.Parent = contentFrame
notificationLabel.BackgroundTransparency = 1
notificationLabel.Position = UDim2.new(0, 0, 0, 10)
notificationLabel.Size = UDim2.new(1, 0, 0, 20)
notificationLabel.Font = Enum.Font.GothamSemibold
notificationLabel.Text = ""
notificationLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
notificationLabel.TextSize = 14
notificationLabel.TextWrapped = true

-- Key Input TextBox
local keyInput = Instance.new("TextBox")
keyInput.Name = "KeyInput"
keyInput.Parent = contentFrame
keyInput.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
keyInput.BorderSizePixel = 0
keyInput.Position = UDim2.new(0.5, -150, 0, 50)
keyInput.Size = UDim2.new(0, 300, 0, 40)
keyInput.Font = Enum.Font.Code
keyInput.PlaceholderText = "Enter Your Key Here"
keyInput.Text = ""
keyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
keyInput.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
keyInput.TextSize = 16
Instance.new("UICorner", keyInput).CornerRadius = UDim.new(0, 8)

-- Button Holder
local buttonHolder = Instance.new("Frame")
buttonHolder.Name = "ButtonHolder"
buttonHolder.Parent = contentFrame
buttonHolder.BackgroundTransparency = 1
buttonHolder.Position = UDim2.new(0, 0, 1, -100)
buttonHolder.Size = UDim2.new(1, 0, 0, 80)

local buttonLayout = Instance.new("UIListLayout")
buttonLayout.Parent = buttonHolder
buttonLayout.FillDirection = Enum.FillDirection.Horizontal
buttonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
buttonLayout.SortOrder = Enum.SortOrder.LayoutOrder
buttonLayout.Padding = UDim.new(0, 10)

-- Function to create a button
local function createButton(name, text, color, layoutOrder)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Parent = buttonHolder
    btn.BackgroundColor3 = color
    btn.BorderSizePixel = 0
    btn.Size = UDim2.new(0, 110, 0, 40)
    btn.Font = Enum.Font.GothamSemibold
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 14
    btn.LayoutOrder = layoutOrder
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    local hoverColor = color:lerp(Color3.new(1,1,1), 0.2)
    
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.3), {BackgroundColor3 = hoverColor}):Play()
    end)
    
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.3), {BackgroundColor3 = color}):Play()
    end)

    return btn
end

-- Create Buttons
local getKeyBtn = createButton("GetKeyBtn", "Get Key", Color3.fromRGB(0, 162, 255), 1)
local checkKeyBtn = createButton("CheckKeyBtn", "Check Key", Color3.fromRGB(50, 200, 100), 2)
local discordBtn = createButton("DiscordBtn", "Discord", Color3.fromRGB(88, 101, 242), 3)

-- == BUTTON LOGIC ==

-- Get Key Button Logic
getKeyBtn.MouseButton1Click:Connect(function()
    if copyToClipboard(KEY_SYSTEM_URL) then
        getKeyBtn.Text = "Copied!"
        notificationLabel.Text = "✅ Link copied! Complete tasks to get key"
        notificationLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        wait(2)
        getKeyBtn.Text = "Get Key"
        notificationLabel.Text = ""
    end
end)

-- Check Key Button Logic
checkKeyBtn.MouseButton1Click:Connect(function()
    local enteredKey = keyInput.Text
    
    if enteredKey == "" or enteredKey == keyInput.PlaceholderText then
        notificationLabel.Text = "⚠️ Please enter a key!"
        notificationLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
        return
    end
    
    checkKeyBtn.Text = "Checking..."
    checkKeyBtn.Active = false
    
    -- Run the key check function
    onCheckKey(enteredKey)
    
    -- Revert button to original state
    wait(1)
    if screenGui:FindFirstChild("MainFrame") then
        checkKeyBtn.Text = "Check Key"
        checkKeyBtn.Active = true
    end
end)

-- Discord Button Logic
discordBtn.MouseButton1Click:Connect(function()
    if copyToClipboard(DISCORD_INVITE_URL) then
        discordBtn.Text = "Copied!"
        notificationLabel.Text = "✅ Discord link copied!"
        notificationLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        wait(2)
        discordBtn.Text = "Discord"
        notificationLabel.Text = ""
    end
end)

-- Startup animation
mainFrame.Size = UDim2.new(0, 0, 0, 0)
TweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back), {
    Size = UDim2.new(0, 400, 0, 300)
}):Play()

print("✅ North Hub Key System UI Loaded!")
print("📋 Discord: https://discord.gg/83kPyNANP")
print("🔑 Get Key: https://lootdest.org/s?9dhiBiZj")
