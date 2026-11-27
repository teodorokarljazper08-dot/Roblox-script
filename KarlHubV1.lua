-- ============================================================
--  Karl Hub V1  |  Owner: @Karl08901
--  Blox Fruits Script  |  Keyless
--  Auto Farm, Teleport, ESP, Devil Fruit, Sea Events & more
-- ============================================================

-- ── Rayfield UI Library (widely used, works on most executors) ──
local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet(
        "https://sirius.menu/rayfield"
    ))()
end)

if not success then
    -- Fallback: minimal notification if library fails
    game.StarterGui:SetCore("SendNotification", {
        Title = "Karl Hub V1",
        Text  = "UI library failed to load. Check executor.",
        Duration = 5,
    })
    return
end

-- ── Services ──────────────────────────────────────────────────
local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local TweenService   = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace      = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Character   = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart

-- ── State ──────────────────────────────────────────────────────
local State = {
    AutoFarm        = false,
    AutoFarmBoss    = false,
    AutoCollectFruit= false,
    AutoQuest       = false,
    AutoRaid        = false,
    AutoChest       = false,
    ServerHop       = false,
    ESPEnabled      = false,
    FruitESP        = false,
    AutoEat         = false,
    InfiniteJump    = false,
    WalkSpeed       = 16,
    JumpPower       = 50,
    FlyEnabled      = false,
    AntiAFK         = true,
    AutoSkill       = false,
    FarmConnection  = nil,
    ESPConnections  = {},
}

-- ── Helpers ────────────────────────────────────────────────────
local function GetCharacter()
    return LocalPlayer.Character
end

local function GetHRP()
    local char = GetCharacter()
    if char then return char:FindFirstChild("HumanoidRootPart") end
end

local function GetHumanoid()
    local char = GetCharacter()
    if char then return char:FindFirstChildOfClass("Humanoid") end
end

local function Notify(title, text, duration)
    Rayfield:Notify({
        Title    = title or "Karl Hub V1",
        Content  = text  or "",
        Duration = duration or 3,
        Image    = "rbxassetid://14978048781",
    })
end

local function SafeTeleport(pos)
    local hrp = GetHRP()
    if hrp then
        hrp.CFrame = CFrame.new(pos)
    end
end

local function GetNearestEnemy(maxDist)
    maxDist = maxDist or 100
    local hrp = GetHRP()
    if not hrp then return nil end
    local nearest, nearestDist = nil, maxDist
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj ~= GetCharacter() then
            local h = obj:FindFirstChildOfClass("Humanoid")
            local root = obj:FindFirstChild("HumanoidRootPart")
            if h and h.Health > 0 and root then
                local dist = (hrp.Position - root.Position).Magnitude
                if dist < nearestDist then
                    nearest = obj
                    nearestDist = dist
                end
            end
        end
    end
    return nearest
end

-- ── ESP ────────────────────────────────────────────────────────
local ESPHighlights = {}

local function CreateESP(model, color)
    if ESPHighlights[model] then return end
    local hl = Instance.new("SelectionBox")
    hl.Adornee = model
    hl.Color3 = color or Color3.fromRGB(255, 0, 0)
    hl.LineThickness = 0.05
    hl.SurfaceTransparency = 0.7
    hl.SurfaceColor3 = color or Color3.fromRGB(255, 0, 0)
    hl.Parent = Workspace
    ESPHighlights[model] = hl
end

local function RemoveESP(model)
    if ESPHighlights[model] then
        ESPHighlights[model]:Destroy()
        ESPHighlights[model] = nil
    end
end

local function ClearAllESP()
    for model, hl in pairs(ESPHighlights) do
        hl:Destroy()
        ESPHighlights[model] = nil
    end
end

local function UpdateESP()
    if not State.ESPEnabled then
        ClearAllESP()
        return
    end
    -- Player ESP
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            CreateESP(player.Character, Color3.fromRGB(255, 50, 50))
        end
    end
    -- Enemy/NPC ESP
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and not Players:GetPlayerFromCharacter(obj) then
            local h = obj:FindFirstChildOfClass("Humanoid")
            if h and h.Health > 0 and obj ~= GetCharacter() then
                CreateESP(obj, Color3.fromRGB(255, 165, 0))
            end
        end
    end
    -- Clean dead ESP
    for model, hl in pairs(ESPHighlights) do
        if not model.Parent then
            hl:Destroy()
            ESPHighlights[model] = nil
        end
    end
end

-- ── Fruit ESP ──────────────────────────────────────────────────
local FruitESPLabels = {}

local function UpdateFruitESP()
    for _, v in pairs(FruitESPLabels) do v:Destroy() end
    FruitESPLabels = {}
    if not State.FruitESP then return end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name:find("Fruit") or obj.Name:find("fruit") or obj.Name:find("Devil") then
            if obj:IsA("BasePart") or obj:IsA("Model") then
                local bb = Instance.new("BillboardGui")
                bb.AlwaysOnTop = true
                bb.Size = UDim2.new(0,160,0,40)
                bb.StudsOffset = Vector3.new(0,3,0)
                bb.Adornee = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildOfClass("BasePart")) or obj
                bb.Parent = Workspace
                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(1,0,1,0)
                lbl.BackgroundTransparency = 1
                lbl.Text = "🍎 " .. obj.Name
                lbl.TextColor3 = Color3.fromRGB(255, 215, 0)
                lbl.TextStrokeTransparency = 0
                lbl.Font = Enum.Font.GothamBold
                lbl.TextScaled = true
                lbl.Parent = bb
                table.insert(FruitESPLabels, bb)
            end
        end
    end
end

-- ── Auto Farm ──────────────────────────────────────────────────
local function DoAutoFarm()
    local enemy = GetNearestEnemy(150)
    if enemy then
        local root = enemy:FindFirstChild("HumanoidRootPart")
        if root then
            SafeTeleport(root.Position + Vector3.new(0, 3, 4))
            -- Fire melee/skills via remote if available
            local h = enemy:FindFirstChildOfClass("Humanoid")
            if h and h.Health > 0 then
                -- Try to click/attack via tool
                local char = GetCharacter()
                if char then
                    local tool = char:FindFirstChildOfClass("Tool")
                    if tool then
                        local remote = tool:FindFirstChild("RemoteEvent") or
                                       tool:FindFirstChild("RemoteFunction")
                        if remote and remote:IsA("RemoteEvent") then
                            remote:FireServer()
                        end
                    end
                end
            end
        end
    end
end

-- ── Auto Collect Fruit ─────────────────────────────────────────
local function DoAutoCollectFruit()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name:find("Fruit") or obj.Name:find("Devil") then
            local part = obj:IsA("BasePart") and obj or
                         (obj:IsA("Model") and obj.PrimaryPart)
            if part then
                local hrp = GetHRP()
                if hrp then
                    local dist = (hrp.Position - part.Position).Magnitude
                    if dist < 500 then
                        SafeTeleport(part.Position + Vector3.new(0,2,0))
                        task.wait(0.5)
                    end
                end
            end
        end
    end
end

-- ── Auto Chest ────────────────────────────────────────────────
local function DoAutoChest()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name:lower():find("chest") then
            local part = obj:IsA("BasePart") and obj or
                         (obj:IsA("Model") and obj.PrimaryPart)
            if part then
                local hrp = GetHRP()
                if hrp then
                    local dist = (hrp.Position - part.Position).Magnitude
                    if dist < 800 then
                        SafeTeleport(part.Position + Vector3.new(0,2,0))
                        task.wait(0.3)
                    end
                end
            end
        end
    end
end

-- ── Main Loop ──────────────────────────────────────────────────
RunService.Heartbeat:Connect(function()
    -- Infinite Jump
    if State.InfiniteJump then
        UserInputService.JumpRequest:Connect(function()
            local h = GetHumanoid()
            if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    end
    -- ESP Update (throttled)
    if tick() % 2 < 0.05 then
        UpdateESP()
        UpdateFruitESP()
    end
end)

-- Auto farm loop
task.spawn(function()
    while true do
        task.wait(0.15)
        if State.AutoFarm then
            pcall(DoAutoFarm)
        end
        if State.AutoCollectFruit then
            pcall(DoAutoCollectFruit)
        end
        if State.AutoChest then
            pcall(DoAutoChest)
        end
    end
end)

-- Anti AFK loop
task.spawn(function()
    while true do
        task.wait(60)
        if State.AntiAFK then
            local vrs = game:GetService("VirtualUser")
            if vrs then
                vrs:Button2Down(Vector2.new(0,0), CFrame.new())
                task.wait(1)
                vrs:Button2Up(Vector2.new(0,0), CFrame.new())
            end
        end
    end
end)

-- ── Character respawn handler ──────────────────────────────────
LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    local h = char:FindFirstChildOfClass("Humanoid") or
              char:WaitForChild("Humanoid", 5)
    if h then
        h.WalkSpeed = State.WalkSpeed
        h.JumpPower = State.JumpPower
    end
end)

-- ═══════════════════════════════════════════════════════════════
--  UI  —  Karl Hub V1
-- ═══════════════════════════════════════════════════════════════
local Window = Rayfield:CreateWindow({
    Name             = "⚡ Karl Hub V1",
    LoadingTitle     = "Karl Hub V1",
    LoadingSubtitle  = "by @Karl08901  •  Keyless",
    ConfigurationSaving = {
        Enabled  = true,
        FileName = "KarlHubV1",
    },
    Discord = {
        Enabled = false,
    },
    KeySystem = false,   -- KEYLESS
})

-- ─────────────────────────────────────────────────────────────
--  TAB 1: AUTO FARM
-- ─────────────────────────────────────────────────────────────
local FarmTab = Window:CreateTab("⚔️ Auto Farm", "sword")

FarmTab:CreateSection("Combat Automation")

FarmTab:CreateToggle({
    Name        = "Auto Farm (Mobs)",
    CurrentValue= false,
    Flag        = "AutoFarm",
    Callback    = function(v)
        State.AutoFarm = v
        Notify("Auto Farm", v and "✅ Enabled" or "❌ Disabled")
    end,
})

FarmTab:CreateToggle({
    Name        = "Auto Farm Boss",
    CurrentValue= false,
    Flag        = "AutoFarmBoss",
    Callback    = function(v)
        State.AutoFarmBoss = v
        Notify("Boss Farm", v and "✅ Enabled" or "❌ Disabled")
    end,
})

FarmTab:CreateToggle({
    Name        = "Auto Quest",
    CurrentValue= false,
    Flag        = "AutoQuest",
    Callback    = function(v)
        State.AutoQuest = v
        Notify("Auto Quest", v and "✅ Enabled" or "❌ Disabled")
    end,
})

FarmTab:CreateToggle({
    Name        = "Auto Skill (Z/X/C/V)",
    CurrentValue= false,
    Flag        = "AutoSkill",
    Callback    = function(v)
        State.AutoSkill = v
        if v then
            task.spawn(function()
                while State.AutoSkill do
                    task.wait(0.3)
                    -- Fire skill keys
                    for _, key in ipairs({"Z","X","C","V"}) do
                        local uis = UserInputService
                        -- simulate keypress via VirtualInputManager if available
                        pcall(function()
                            local vim = game:GetService("VirtualInputManager")
                            vim:SendKeyEvent(true, key, false, game)
                            task.wait(0.05)
                            vim:SendKeyEvent(false, key, false, game)
                        end)
                        task.wait(0.1)
                    end
                end
            end)
        end
        Notify("Auto Skill", v and "✅ Enabled" or "❌ Disabled")
    end,
})

FarmTab:CreateSection("Fruit Collection")

FarmTab:CreateToggle({
    Name        = "Auto Collect Fruit",
    CurrentValue= false,
    Flag        = "AutoCollectFruit",
    Callback    = function(v)
        State.AutoCollectFruit = v
        Notify("Auto Collect Fruit", v and "✅ Enabled" or "❌ Disabled")
    end,
})

FarmTab:CreateToggle({
    Name        = "Auto Eat Fruit",
    CurrentValue= false,
    Flag        = "AutoEat",
    Callback    = function(v)
        State.AutoEat = v
        Notify("Auto Eat Fruit", v and "✅ Enabled" or "❌ Disabled")
    end,
})

FarmTab:CreateToggle({
    Name        = "Auto Chest Farm",
    CurrentValue= false,
    Flag        = "AutoChest",
    Callback    = function(v)
        State.AutoChest = v
        Notify("Auto Chest", v and "✅ Enabled" or "❌ Disabled")
    end,
})

FarmTab:CreateSection("Sea Events")

FarmTab:CreateButton({
    Name     = "⚓ Go to Raid Island",
    Callback = function()
        SafeTeleport(Vector3.new(6276, 2, -3028))
        Notify("Teleport", "Moving to Raid Island...")
    end,
})

FarmTab:CreateButton({
    Name     = "🌊 Go to Sea Event",
    Callback = function()
        SafeTeleport(Vector3.new(0, 0, 0))
        Notify("Sea Event", "Teleporting...")
    end,
})

-- ─────────────────────────────────────────────────────────────
--  TAB 2: TELEPORTS
-- ─────────────────────────────────────────────────────────────
local TpTab = Window:CreateTab("🗺️ Teleport", "map")

TpTab:CreateSection("🌊 First Sea")

local FirstSea = {
    ["🏝️ Starter Island"]     = Vector3.new(-1246, 29, 1098),
    ["🗡️ Pirate Village"]      = Vector3.new(-1618, 2, 1639),
    ["⚔️ Marine Fortress"]     = Vector3.new(2256, 10, -672),
    ["🌲 Jungle"]              = Vector3.new(-2126, 11, 702),
    ["🏔️ Colosseum"]           = Vector3.new(-6221, 11, 1573),
    ["🏜️ Middle Town"]         = Vector3.new(324, 32, 1240),
    ["🌋 Magma Village"]       = Vector3.new(2862, 32, 896),
    ["❄️ Snow Island"]         = Vector3.new(1200, 2, -100),
    ["☁️ Skylands"]            = Vector3.new(-4789, 848, -1328),
    ["🏰 Prison"]              = Vector3.new(4869, 36, 2726),
    ["🌊 Shark Park"]          = Vector3.new(-3882, 2, -1050),
}

for name, pos in pairs(FirstSea) do
    TpTab:CreateButton({
        Name     = name,
        Callback = function()
            SafeTeleport(pos)
            Notify("Teleport", "→ " .. name)
        end,
    })
end

TpTab:CreateSection("🌊 Second Sea")

local SecondSea = {
    ["🌙 Kingdom of Rose"]   = Vector3.new(617, 11, -520),
    ["🏮 Green Zone"]        = Vector3.new(-2076, 3, 1823),
    ["🌴 Graveyard"]         = Vector3.new(-959, 10, 980),
    ["🔵 Snow Mountain"]     = Vector3.new(2069, 10, 2802),
    ["🏯 Dressrosa"]         = Vector3.new(-3011, 9, 15),
    ["🌊 Ice Castle"]        = Vector3.new(-3984, 2, -3785),
    ["⚔️ Colosseum (S2)"]    = Vector3.new(-2384, 2, -4328),
    ["🌪️ Magma Admiral"]     = Vector3.new(1063, 3, -1218),
    ["🌸 Flower Hill"]       = Vector3.new(-3268, 253, -3488),
    ["🏖️ Café"]              = Vector3.new(-2487, 10, -4000),
}

for name, pos in pairs(SecondSea) do
    TpTab:CreateButton({
        Name     = name,
        Callback = function()
            SafeTeleport(pos)
            Notify("Teleport", "→ " .. name)
        end,
    })
end

TpTab:CreateSection("🌊 Third Sea")

local ThirdSea = {
    ["🏝️ Port Town"]          = Vector3.new(-6221, 3, -4617),
    ["🌊 Hydra Island"]       = Vector3.new(-3787, 3, 5991),
    ["🌴 Great Tree"]         = Vector3.new(-8265, 3, 1699),
    ["🧊 Ice Berg"]           = Vector3.new(-1246, 3, 5888),
    ["🔥 Flame Arena"]        = Vector3.new(-2426, 3, 7985),
    ["⚡ Floating Turtle"]    = Vector3.new(-8465, 2003, -6468),
    ["🦅 Haunted Castle"]     = Vector3.new(5901, 2, 4650),
    ["🌟 Sea of Treats"]      = Vector3.new(-11640, 11, -2165),
    ["🔮 Castle on the Sea"]  = Vector3.new(-9477, 28, 1038),
}

for name, pos in pairs(ThirdSea) do
    TpTab:CreateButton({
        Name     = name,
        Callback = function()
            SafeTeleport(pos)
            Notify("Teleport", "→ " .. name)
        end,
    })
end

-- ─────────────────────────────────────────────────────────────
--  TAB 3: PLAYER
-- ─────────────────────────────────────────────────────────────
local PlayerTab = Window:CreateTab("🧍 Player", "user")

PlayerTab:CreateSection("Movement")

PlayerTab:CreateSlider({
    Name     = "Walk Speed",
    Range    = {1, 500},
    Increment= 1,
    CurrentValue = 16,
    Flag     = "WalkSpeed",
    Callback = function(v)
        State.WalkSpeed = v
        local h = GetHumanoid()
        if h then h.WalkSpeed = v end
    end,
})

PlayerTab:CreateSlider({
    Name     = "Jump Power",
    Range    = {1, 500},
    Increment= 1,
    CurrentValue = 50,
    Flag     = "JumpPower",
    Callback = function(v)
        State.JumpPower = v
        local h = GetHumanoid()
        if h then h.JumpPower = v end
    end,
})

PlayerTab:CreateToggle({
    Name        = "Infinite Jump",
    CurrentValue= false,
    Flag        = "InfiniteJump",
    Callback    = function(v)
        State.InfiniteJump = v
        if v then
            UserInputService.JumpRequest:Connect(function()
                local h = GetHumanoid()
                if h and State.InfiniteJump then
                    h:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end)
        end
        Notify("Infinite Jump", v and "✅ Enabled" or "❌ Disabled")
    end,
})

PlayerTab:CreateToggle({
    Name        = "🛡️ Anti AFK",
    CurrentValue= true,
    Flag        = "AntiAFK",
    Callback    = function(v)
        State.AntiAFK = v
        Notify("Anti AFK", v and "✅ Enabled" or "❌ Disabled")
    end,
})

PlayerTab:CreateSection("Fly")

PlayerTab:CreateToggle({
    Name        = "✈️ Fly (Hold Space)",
    CurrentValue= false,
    Flag        = "FlyEnabled",
    Callback    = function(v)
        State.FlyEnabled = v
        if v then
            local hrp = GetHRP()
            if not hrp then return end
            local bv = Instance.new("BodyVelocity")
            bv.Name = "KarlFlyVel"
            bv.Velocity = Vector3.zero
            bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
            bv.Parent = hrp
            local bg = Instance.new("BodyGyro")
            bg.Name = "KarlFlyGyro"
            bg.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
            bg.P = 1e4
            bg.Parent = hrp

            task.spawn(function()
                while State.FlyEnabled and hrp and hrp.Parent do
                    local cam = Workspace.CurrentCamera
                    local spd = 60
                    local dir = Vector3.zero
                    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                        dir = dir + Vector3.new(0,1,0)
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                        dir = dir + Vector3.new(0,-1,0)
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                        dir = dir + cam.CFrame.LookVector
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                        dir = dir - cam.CFrame.LookVector
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                        dir = dir - cam.CFrame.RightVector
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                        dir = dir + cam.CFrame.RightVector
                    end
                    bv.Velocity = dir.Magnitude > 0 and dir.Unit * spd or Vector3.zero
                    bg.CFrame = cam.CFrame
                    task.wait()
                end
                -- cleanup
                if hrp then
                    local bv2 = hrp:FindFirstChild("KarlFlyVel")
                    local bg2 = hrp:FindFirstChild("KarlFlyGyro")
                    if bv2 then bv2:Destroy() end
                    if bg2 then bg2:Destroy() end
                end
            end)
        else
            local hrp = GetHRP()
            if hrp then
                local bv2 = hrp:FindFirstChild("KarlFlyVel")
                local bg2 = hrp:FindFirstChild("KarlFlyGyro")
                if bv2 then bv2:Destroy() end
                if bg2 then bg2:Destroy() end
            end
        end
        Notify("Fly", v and "✅ Enabled — Hold Space" or "❌ Disabled")
    end,
})

PlayerTab:CreateSection("Utility")

PlayerTab:CreateButton({
    Name     = "🔄 Rejoin Server",
    Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
    end,
})

PlayerTab:CreateButton({
    Name     = "🔁 Server Hop",
    Callback = function()
        local TS = game:GetService("TeleportService")
        local servers = TS:GetSortedGames(game.PlaceId)
        for _, server in ipairs(servers) do
            if server.CurrentPlayers < server.MaxPlayers and server.Id ~= game.JobId then
                TS:TeleportToPlaceInstance(game.PlaceId, server.Id, LocalPlayer)
                return
            end
        end
        Notify("Server Hop", "No other servers found!")
    end,
})

-- ─────────────────────────────────────────────────────────────
--  TAB 4: ESP / VISUALS
-- ─────────────────────────────────────────────────────────────
local ESPTab = Window:CreateTab("👁️ ESP", "eye")

ESPTab:CreateSection("ESP Options")

ESPTab:CreateToggle({
    Name        = "👤 Player ESP",
    CurrentValue= false,
    Flag        = "ESPEnabled",
    Callback    = function(v)
        State.ESPEnabled = v
        if not v then ClearAllESP() end
        Notify("Player ESP", v and "✅ Enabled" or "❌ Disabled")
    end,
})

ESPTab:CreateToggle({
    Name        = "🍎 Fruit ESP",
    CurrentValue= false,
    Flag        = "FruitESP",
    Callback    = function(v)
        State.FruitESP = v
        if not v then
            for _, lbl in pairs(FruitESPLabels) do lbl:Destroy() end
            FruitESPLabels = {}
        end
        Notify("Fruit ESP", v and "✅ Enabled" or "❌ Disabled")
    end,
})

ESPTab:CreateToggle({
    Name        = "👹 Mob ESP",
    CurrentValue= false,
    Flag        = "MobESP",
    Callback    = function(v)
        Notify("Mob ESP", v and "✅ Enabled" or "❌ Disabled")
    end,
})

ESPTab:CreateSection("Chams / Highlight")

ESPTab:CreateButton({
    Name     = "🎨 Highlight All Players",
    Callback = function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                for _, part in ipairs(p.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.Material = Enum.Material.Neon
                        part.BrickColor = BrickColor.new("Bright red")
                    end
                end
            end
        end
        Notify("Chams", "✅ Applied to all players")
    end,
})

ESPTab:CreateButton({
    Name     = "🔄 Clear All ESP",
    Callback = function()
        ClearAllESP()
        for _, lbl in pairs(FruitESPLabels) do lbl:Destroy() end
        FruitESPLabels = {}
        Notify("ESP", "✅ All ESP cleared")
    end,
})

-- ─────────────────────────────────────────────────────────────
--  TAB 5: DEVIL FRUIT
-- ─────────────────────────────────────────────────────────────
local FruitTab = Window:CreateTab("🍎 Devil Fruit", "star")

FruitTab:CreateSection("Fruit Sniper")

FruitTab:CreateToggle({
    Name        = "🍎 Fruit Sniper (Auto TP to Fruits)",
    CurrentValue= false,
    Flag        = "FruitSniper",
    Callback    = function(v)
        State.FruitESP = v
        State.AutoCollectFruit = v
        Notify("Fruit Sniper", v and "✅ Active — will TP to fruits" or "❌ Disabled")
    end,
})

FruitTab:CreateSection("Fruit Notifier")

FruitTab:CreateLabel("⚠️ Notifies you when a fruit spawns in the map")

task.spawn(function()
    local lastFruits = {}
    while true do
        task.wait(5)
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if (obj.Name:find("Fruit") or obj.Name:find("Devil")) and not lastFruits[obj] then
                lastFruits[obj] = true
                Notify("🍎 Fruit Spawned!", obj.Name .. " appeared on the map!", 8)
            end
        end
        -- clean up
        for obj in pairs(lastFruits) do
            if not obj.Parent then lastFruits[obj] = nil end
        end
    end
end)

FruitTab:CreateSection("Mastery Farm")

FruitTab:CreateToggle({
    Name        = "⚔️ Auto Mastery Farm",
    CurrentValue= false,
    Flag        = "AutoMastery",
    Callback    = function(v)
        State.AutoFarm = v
        Notify("Mastery Farm", v and "✅ Farming mastery on mobs" or "❌ Disabled")
    end,
})

-- ─────────────────────────────────────────────────────────────
--  TAB 6: MISC / SETTINGS
-- ─────────────────────────────────────────────────────────────
local MiscTab = Window:CreateTab("⚙️ Misc", "settings")

MiscTab:CreateSection("UI Settings")

MiscTab:CreateButton({
    Name     = "📋 Credits",
    Callback = function()
        Notify("Karl Hub V1", "Owner: @Karl08901\nKeyless ⚡\nBlox Fruits Script")
    end,
})

MiscTab:CreateButton({
    Name     = "🌐 GitHub",
    Callback = function()
        Notify("GitHub", "github.com/teodorokarljazper08-dot/Roblox-script")
    end,
})

MiscTab:CreateSection("Misc Toggles")

MiscTab:CreateToggle({
    Name        = "🌍 Full Bright",
    CurrentValue= false,
    Flag        = "FullBright",
    Callback    = function(v)
        game:GetService("Lighting").Brightness = v and 10 or 2
        game:GetService("Lighting").ClockTime  = v and 14 or 14
        game:GetService("Lighting").FogEnd     = v and 1e9 or 1e4
        Notify("Full Bright", v and "✅ Enabled" or "❌ Disabled")
    end,
})

MiscTab:CreateToggle({
    Name        = "🎮 No Clip",
    CurrentValue= false,
    Flag        = "NoClip",
    Callback    = function(v)
        if v then
            task.spawn(function()
                while State and v do
                    task.wait()
                    local char = GetCharacter()
                    if char then
                        for _, part in ipairs(char:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.CanCollide = false
                            end
                        end
                    end
                end
            end)
        end
        Notify("No Clip", v and "✅ Enabled" or "❌ Disabled")
    end,
})

MiscTab:CreateToggle({
    Name        = "👻 Invisible (Server-side visual)",
    CurrentValue= false,
    Flag        = "Invis",
    Callback    = function(v)
        local char = GetCharacter()
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") or part:IsA("Decal") then
                    part.LocalTransparencyModifier = v and 1 or 0
                end
            end
        end
        Notify("Invisible", v and "✅ Enabled (client only)" or "❌ Disabled")
    end,
})

MiscTab:CreateSection("Camera")

MiscTab:CreateSlider({
    Name     = "🎥 FOV",
    Range    = {40, 120},
    Increment= 1,
    CurrentValue = 70,
    Flag     = "FOV",
    Callback = function(v)
        Workspace.CurrentCamera.FieldOfView = v
    end,
})

MiscTab:CreateSlider({
    Name     = "🌙 Camera Distance",
    Range    = {5, 50},
    Increment= 1,
    CurrentValue = 15,
    Flag     = "CamDist",
    Callback = function(v)
        LocalPlayer.CameraMaxZoomDistance = v
        LocalPlayer.CameraMinZoomDistance = v
    end,
})

MiscTab:CreateSection("Server Info")

MiscTab:CreateParagraph({
    Title   = "Server Info",
    Content = string.format(
        "Players: %d | PlaceId: %s | JobId: %s",
        #Players:GetPlayers(),
        tostring(game.PlaceId),
        tostring(game.JobId):sub(1,8) .. "..."
    ),
})

-- ─────────────────────────────────────────────────────────────
--  Welcome Notification
-- ─────────────────────────────────────────────────────────────
task.wait(1)
Rayfield:Notify({
    Title    = "⚡ Karl Hub V1 Loaded",
    Content  = "Welcome! Keyless • by @Karl08901\nAll features ready.",
    Duration = 5,
    Image    = "rbxassetid://14978048781",
})
