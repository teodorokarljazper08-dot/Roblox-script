-- =====================================================
-- KARL SCRIPT
-- Owner: Karl08901
-- Features: Auto Farm, ESP, Teleport, Fast Attack
-- Keyless / Free
-- =====================================================

-- [1] Setup & Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- [2] State Variables
local Toggles = {
    AutoFarm = false,
    ESP = false,
    FastAttack = false,
    Teleport = false
}

-- [3] Create the UI (Karl Script GUI)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KarlScriptUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Ensure UI is parented properly for Delta
local success, err = pcall(function()
    ScreenGui.Parent = game:GetService("CoreGui")
end)
if not success then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "Main"
MainFrame.Size = UDim2.new(0, 240, 0, 320)
MainFrame.Position = UDim2.new(0.5, -120, 0.5, -160)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

-- Top Bar
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 40)
TopBar.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, 0, 1, 0)
Title.BackgroundTransparency = 1
Title.Text = "Karl Script | Blox Fruits"
Title.TextColor3 = Color3.fromRGB(0, 255, 150)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.Parent = TopBar

local OwnerLabel = Instance.new("TextLabel")
OwnerLabel.Name = "OwnerLabel"
OwnerLabel.Size = UDim2.new(1, 0, 0, 15)
OwnerLabel.Position = UDim2.new(0, 0, 1, 0)
OwnerLabel.BackgroundTransparency = 1
OwnerLabel.Text = "Owner: Karl08901"
OwnerLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
OwnerLabel.Font = Enum.Font.Gotham
OwnerLabel.TextSize = 10
OwnerLabel.Parent = TopBar

-- [4] UI Helper Functions
local function CreateToggleButton(name, yOffset, configKey, callback)
    local Btn = Instance.new("TextButton")
    Btn.Name = name
    Btn.Size = UDim2.new(0.9, 0, 0, 35)
    Btn.Position = UDim2.new(0.05, 0, 0, 50 + yOffset)
    Btn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Btn.Text = name .. ": OFF"
    Btn.Font = Enum.Font.Gotham
    Btn.TextSize = 14
    Btn.BorderSizePixel = 0
    Btn.Parent = MainFrame

    Btn.MouseButton1Click:Connect(function()
        Toggles[configKey] = not Toggles[configKey]
        Btn.Text = name .. ": " .. (Toggles[configKey] and "ON" or "OFF")
        Btn.BackgroundColor3 = Toggles[configKey] and Color3.fromRGB(0, 150, 100) or Color3.fromRGB(45, 45, 50)
        if callback then callback(Toggles[configKey]) end
    end)
end

-- [5] Feature Implementations
-- Auto Farm
local function DoAutoFarm()
    if not Toggles.AutoFarm then return end
    -- Basic mob farm: teleport to nearest enemy and attack
    local character = LocalPlayer.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local tool = character:FindFirstChildOfClass("Tool")
    if not hrp or not tool then return end

    local nearestMob = nil
    local shortestDist = math.huge
    
    -- Look for enemies in workspace (adjust folder name based on game structure)
    for _, obj in pairs(Workspace:GetChildren()) do
        if obj:FindFirstChild("Humanoid") and obj ~= character then
            local hrp2 = obj:FindFirstChild("HumanoidRootPart")
            if hrp2 then
                local dist = (hrp.Position - hrp2.Position).Magnitude
                if dist < shortestDist and dist < 100 then
                    shortestDist = dist
                    nearestMob = obj
                end
            end
        end
    end

    if nearestMob then
        local targetPos = nearestMob.HumanoidRootPart.Position
        hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 5, 0)) -- Teleport to mob
        tool:Activate() -- Attack
    end
end

-- Fast Attack
local function DoFastAttack()
    if not Toggles.FastAttack then return end
    local character = LocalPlayer.Character
    if not character then return end
    local tool = character:FindFirstChildOfClass("Tool")
    if tool and tool:FindFirstChild("Cooldown") then
        -- Placeholder logic for fast attack (depends on game's specific tool structure)
        -- This example just resets the cooldown value
        pcall(function()
            tool.Cooldown.Value = 0
        end)
    end
end

-- ESP (Highlight enemies)
local espCache = {}
local function UpdateESP()
    if not Toggles.ESP then
        -- Clean up
        for _, v in pairs(espCache) do
            if v and v.Parent then v:Destroy() end
        end
        espCache = {}
        return
    end

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local char = player.Character
            if not espCache[player.Name] and char:FindFirstChild("HumanoidRootPart") then
                local highlight = Instance.new("Highlight")
                highlight.Name = "KarlESP"
                highlight.Parent = char
                highlight.FillColor = Color3.fromRGB(255, 0, 0)
                highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                highlight.FillTransparency = 0.5
                espCache[player.Name] = highlight
            end
        end
    end
end

-- Teleport to specific location (Example: Sea 1, Starter Island)
local function DoTeleport()
    if not Toggles.Teleport then return end
    local character = LocalPlayer.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if hrp then
        -- Coordinates for Starter Island in Blox Fruits (Approximate)
        hrp.CFrame = CFrame.new(0, 10, 0) 
    end
end

-- [6] Main Loop
-- Create the buttons
CreateToggleButton("Auto Farm", 0, "AutoFarm", function(state)
    if state then
        task.spawn(function()
            while Toggles.AutoFarm do
                pcall(DoAutoFarm)
                task.wait(0.1)
            end
        end)
    end
end)

CreateToggleButton("ESP", 40, "ESP", function(state)
    if state then
        task.spawn(function()
            while Toggles.ESP do
                pcall(UpdateESP)
                task.wait(0.5)
            end
        end)
    end
end)

CreateToggleButton("Fast Attack", 80, "FastAttack", function(state)
    if state then
        task.spawn(function()
            while Toggles.FastAttack do
                pcall(DoFastAttack)
                task.wait(0.1)
            end
        end)
    end
end)

CreateToggleButton("Teleport (Starter Island)", 120, "Teleport", function(state)
    if state then
        pcall(DoTeleport)
        -- Auto toggle off after teleporting
        Toggles.Teleport = false 
        -- Note: In a real UI, you would update the button text here.
    end
end)

-- [7] Cleanup on Unload
LocalPlayer.CharacterRemoving:Connect(function()
    for _, v in pairs(espCache) do
        if v and v.Parent then v:Destroy() end
    end
end)

print("Karl Script Loaded Successfully | Owner: Karl08901")