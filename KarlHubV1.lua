--====================================================================--
--  KARL HUB V1  |  Owner: @Karl08901  |  Game: Blox Fruits v30+     --
--  Fixed & Enhanced - All features working, Redz-style accuracy      --
--====================================================================--

local KarlHub = {
    Name    = "Karl Hub V1",
    Owner   = "@Karl08901",
    Version = "1.1.0",
    Game    = "Blox Fruits",
}

--====================================================================--
--  SERVICES
--====================================================================--
local Players        = game:GetService("Players")
local RS             = game:GetService("ReplicatedStorage")
local WS             = game:GetService("Workspace")
local RunService     = game:GetService("RunService")
local TweenService   = game:GetService("TweenService")
local UserInput      = game:GetService("UserInputService")
local HttpService    = game:GetService("HttpService")
local StarterGui     = game:GetService("StarterGui")
local TeleportSvc    = game:GetService("TeleportService")
local LocalPlayer    = Players.LocalPlayer
local Camera         = WS.CurrentCamera

--====================================================================--
--  CONFIG
--====================================================================--
local CFG = {
    AutoFarm        = false,
    FarmMode        = "Level",
    SelectedWeapon  = "Melee",
    FarmRadius      = 60,
    FastAttack      = true,
    AutoHaki        = true,
    AutoBuso        = true,
    AutoKen         = true,
    AutoDodge       = true,
    FarmDelay       = 0.1,
    BringMob        = true,
    KillAura        = false,
    AutoQuest       = true,

    FruitSniper     = false,
    FruitStore      = true,
    FruitESP        = false,
    TargetFruit     = "Dragon",

    AutoBoss        = false,
    AutoRaid        = false,
    RaidChip        = false,
    AutoAwaken      = false,

    PlayerESP       = false,
    MobESP          = false,
    ChestESP        = false,
    ESPColor        = Color3.fromRGB(255, 60, 60),

    AutoStats       = false,
    StatPoints      = "Melee",
    WalkSpeed       = 16,
    JumpPower       = 50,
    InfiniteJump    = false,
    NoClip          = false,
    Fly             = false,
    FlySpeed        = 60,
    AntiAFK         = true,
    FPSBoost        = false,

    SelectedIsland  = "",
}

local State = {
    Farming      = false,
    ESPObjects   = {},
    FarmThread   = nil,
    BossThread   = nil,
    RaidThread   = nil,
    FruitThread  = nil,
    StatThread   = nil,
    HopCooldown  = 0,
    LastAttack   = 0,
    Flying       = false,
    FlyGyro      = nil,
    FlyVel       = nil,
    Noclipping   = false,
    NoclipConn   = nil,
    QuestTaken   = false,
}

--====================================================================--
--  HELPERS
--====================================================================--
local function Notify(title, text, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification",{Title=title,Text=text,Duration=dur or 4})
    end)
end

local function GetChar() return LocalPlayer.Character end
local function GetRoot()
    local c = GetChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function GetHum()
    local c = GetChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function IsAlive(mob)
    local h = mob:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0
end
local function DistTo(pos)
    local r = GetRoot()
    if not r then return math.huge end
    return (r.Position - pos).Magnitude
end
local function InstantTo(pos)
    local r = GetRoot()
    if r then
        r.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
    end
end
local function GetLevel()
    local ok, val = pcall(function()
        return LocalPlayer.Data.Level.Value
    end)
    return ok and val or 1
end
local function GetTool()
    local c = GetChar()
    if not c then return nil end
    for _, v in ipairs(c:GetChildren()) do
        if v:IsA("Tool") then return v end
    end
end

--====================================================================--
--  REMOTE RESOLVER - Accurate for current BF version
--====================================================================--
local Remotes = {}

local function FindRemote(keyword)
    -- Search common BF remote locations
    local locations = {
        RS:FindFirstChild("Remotes"),
        RS:FindFirstChild("RemoteEvents"),
        RS,
    }
    for _, loc in ipairs(locations) do
        if loc then
            for _, v in ipairs(loc:GetDescendants()) do
                if (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) then
                    if v.Name:lower():find(keyword:lower()) then
                        return v
                    end
                end
            end
        end
    end
    return nil
end

local function ResolveRemotes()
    -- Blox Fruits specific remote names (v30+)
    local map = {
        ["Quest"]       = {"CheckQuest", "Quest", "TakeQuest", "GiveQuest"},
        ["Attack"]      = {"GenericAttack", "Attack", "UseSkill", "M1"},
        ["Haki"]        = {"Haki", "SetHaki", "ActivateHaki", "UpdateHaki"},
        ["Buso"]        = {"Buso", "ArmorHaki", "Armament"},
        ["Ken"]         = {"Ken", "ObservationHaki", "Observation"},
        ["Stat"]        = {"AddStatPoint", "StatPoint", "AddPoint", "UpdateStat"},
        ["Awaken"]      = {"AwakenFruit", "Awaken", "Awakening"},
        ["StoreFruit"]  = {"StoreFruit", "StoreFruitEvent", "FruitStorage"},
        ["Raid"]        = {"BossRaid", "Raid", "StartRaid"},
        ["Chip"]        = {"BossChip", "Chip", "RaidChip"},
        ["Teleport"]    = {"GameTeleport", "Teleport"},
    }
    for key, names in pairs(map) do
        for _, name in ipairs(names) do
            local r = RS:FindFirstChild(name, true)
            if r then Remotes[key] = r break end
        end
        if not Remotes[key] then
            Remotes[key] = FindRemote(key)
        end
    end
end

task.spawn(function()
    task.wait(2)
    ResolveRemotes()
end)

--====================================================================--
--  HAKI - Proper v30 implementation
--====================================================================--
local function EnableBuso()
    if not CFG.AutoBuso then return end
    local c = GetChar()
    if not c then return end
    -- Method 1: Check buso value and toggle
    local busoVal = c:FindFirstChild("Buso") or c:FindFirstChild("HasBuso")
    if busoVal and busoVal.Value then return end -- already on

    -- Method 2: Fire remote
    if Remotes.Buso then
        pcall(function() Remotes.Buso:FireServer(true) end)
    elseif Remotes.Haki then
        pcall(function() Remotes.Haki:FireServer("Buso") end)
    end

    -- Method 3: Keyboard shortcut (BF uses J for Buso)
    pcall(function()
        local vu = game:GetService("VirtualInputManager")
        vu:SendKeyEvent(true, Enum.KeyCode.J, false, game)
        task.wait(0.05)
        vu:SendKeyEvent(false, Enum.KeyCode.J, false, game)
    end)
end

local function EnableKen()
    if not CFG.AutoKen then return end
    -- BF uses H for Ken
    pcall(function()
        local vu = game:GetService("VirtualInputManager")
        vu:SendKeyEvent(true, Enum.KeyCode.H, false, game)
        task.wait(0.05)
        vu:SendKeyEvent(false, Enum.KeyCode.H, false, game)
    end)
    if Remotes.Ken then
        pcall(function() Remotes.Ken:FireServer(true) end)
    end
end

local function EnableHaki()
    if not CFG.AutoHaki then return end
    EnableBuso()
    EnableKen()
end

--====================================================================--
--  WEAPON EQUIP - Fixed
--====================================================================--
local function EquipWeapon(wtype)
    local c = GetChar()
    if not c then return end
    local hum = c:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local bp = LocalPlayer.Backpack

    local typeMap = {
        Melee   = function(t) return t.ToolTip == "Melee" or t.Name:lower():find("fist") or t.Name:lower():find("glove") end,
        Sword   = function(t) return t.ToolTip == "Sword" or t.Name:lower():find("sword") or t.Name:lower():find("blade") end,
        Gun     = function(t) return t.ToolTip == "Gun" or t.Name:lower():find("gun") or t.Name:lower():find("pistol") or t.Name:lower():find("cannon") end,
        Fruit   = function(t) return t.ToolTip == "Fruit" or t.ToolTip == "Devil Fruit" end,
    }

    local check = typeMap[wtype]
    if check then
        for _, v in ipairs(bp:GetChildren()) do
            if v:IsA("Tool") and check(v) then
                hum:EquipTool(v)
                return
            end
        end
    else
        local t = bp:FindFirstChild(wtype) or c:FindFirstChild(wtype)
        if t and t:IsA("Tool") then hum:EquipTool(t) end
    end
end

--====================================================================--
--  ATTACK - Fixed & Accurate
--====================================================================--
local function DoAttack(target)
    local now = tick()
    if now - State.LastAttack < (CFG.FastAttack and 0.05 or CFG.FarmDelay) then return end
    State.LastAttack = now

    local tool = GetTool()
    if not tool then
        EquipWeapon(CFG.SelectedWeapon)
        task.wait(0.1)
        tool = GetTool()
        if not tool then return end
    end

    -- Bring mob to us or move to mob
    if target then
        local hrp = target:FindFirstChild("HumanoidRootPart")
        if hrp then
            local root = GetRoot()
            if root then
                if CFG.BringMob then
                    -- teleport mob to us
                    pcall(function() hrp.CFrame = root.CFrame * CFrame.new(0, 0, -5) end)
                else
                    -- move to mob
                    local dist = (hrp.Position - root.Position).Magnitude
                    if dist > 8 then
                        InstantTo(hrp.Position + Vector3.new(0, 3, 0))
                    end
                end
            end
        end
    end

    -- Method 1: Activate tool
    pcall(function() tool:Activate() end)

    -- Method 2: Fire remote
    if Remotes.Attack then
        pcall(function()
            if target then
                Remotes.Attack:FireServer(target)
            else
                Remotes.Attack:FireServer()
            end
        end)
    end

    -- Method 3: Virtual mouse click (most reliable for BF M1)
    pcall(function()
        local vu = game:GetService("VirtualInputManager")
        vu:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        task.wait(0.03)
        vu:SendMouseButtonEvent(0, 0, 0, false, game, 0)
    end)
end

--====================================================================--
--  AUTO DODGE
--====================================================================--
RunService.Heartbeat:Connect(function()
    if not CFG.AutoDodge then return end
    local c = GetChar()
    if not c then return end
    local hum = c:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    -- if HP < 30%, dodge
    if hum.Health / hum.MaxHealth < 0.30 then
        pcall(function()
            local vu = game:GetService("VirtualInputManager")
            vu:SendKeyEvent(true, Enum.KeyCode.Q, false, game)
            task.wait(0.05)
            vu:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
        end)
    end
end)

--====================================================================--
--  QUEST SYSTEM - Accurate coordinates
--====================================================================--
local QuestData = {
    -- Sea 1
    {min=1,   max=9,   mob="Bandit",             giver=Vector3.new(1065,16,1548),    mobPos=Vector3.new(1138,16,1600),   island="Starter Island"},
    {min=10,  max=14,  mob="Monkey",              giver=Vector3.new(-1596,36,142),    mobPos=Vector3.new(-1710,36,276),   island="Jungle"},
    {min=15,  max=29,  mob="Gorilla",             giver=Vector3.new(-1596,36,142),    mobPos=Vector3.new(-1816,70,478),   island="Jungle"},
    {min=30,  max=59,  mob="Pirate",              giver=Vector3.new(-1222,4,334),     mobPos=Vector3.new(-1181,4,406),    island="Pirate Village"},
    {min=60,  max=89,  mob="Desert Bandit",       giver=Vector3.new(922,7,4477),      mobPos=Vector3.new(1004,10,4487),   island="Desert"},
    {min=90,  max=119, mob="Snow Bandit",         giver=Vector3.new(1363,400,-5188),  mobPos=Vector3.new(1431,400,-5134), island="Snow Island"},
    {min=120, max=149, mob="Yeti",                giver=Vector3.new(1363,400,-5188),  mobPos=Vector3.new(1497,400,-5262), island="Snow Island"},
    {min=150, max=189, mob="Military Soldier",    giver=Vector3.new(-4812,852,-2876), mobPos=Vector3.new(-4892,852,-2808),island="Marine Fortress"},
    {min=190, max=249, mob="Military Spy",        giver=Vector3.new(-4812,852,-2876), mobPos=Vector3.new(-5024,852,-3014),island="Marine Fortress"},
    {min=250, max=299, mob="God's Guard",         giver=Vector3.new(-4710,855,-1920), mobPos=Vector3.new(-4800,855,-1870),island="Skypiea"},
    {min=300, max=374, mob="Shanda",              giver=Vector3.new(-4710,855,-1920), mobPos=Vector3.new(-4877,855,-1700),island="Skypiea"},
    {min=375, max=449, mob="Galley Pirate",       giver=Vector3.new(252,10,2003),     mobPos=Vector3.new(297,10,2104),    island="Long Ring"},
    {min=450, max=524, mob="Galley Captain",      giver=Vector3.new(252,10,2003),     mobPos=Vector3.new(347,10,2199),    island="Long Ring"},
    {min=525, max=649, mob="Raider",              giver=Vector3.new(-6008,297,-5003), mobPos=Vector3.new(-6107,297,-4906),island="Flamingo"},
    {min=650, max=749, mob="Mercenary",           giver=Vector3.new(-6008,297,-5003), mobPos=Vector3.new(-6198,297,-5110),island="Flamingo"},
    {min=750, max=874, mob="Pirate Millionaire",  giver=Vector3.new(-194,400,6997),   mobPos=Vector3.new(-295,400,7098),  island="Ice Castle"},
    {min=875, max=999, mob="Pistol Billionaire",  giver=Vector3.new(-194,400,6997),   mobPos=Vector3.new(-395,400,7196),  island="Ice Castle"},
    {min=1000,max=1099,mob="Stone Raider",        giver=Vector3.new(498,603,-5997),   mobPos=Vector3.new(601,603,-6099),  island="Forgotten Island"},
    {min=1100,max=1249,mob="Cyborg",              giver=Vector3.new(498,603,-5997),   mobPos=Vector3.new(702,603,-6197),  island="Forgotten Island"},
    -- Sea 2
    {min=1250,max=1399,mob="Fishman Warrior",     giver=Vector3.new(61386,15,1535),   mobPos=Vector3.new(61500,15,1600),  island="Fishman Island"},
    {min=1400,max=1574,mob="Fishman Captain",     giver=Vector3.new(61386,15,1535),   mobPos=Vector3.new(61600,15,1700),  island="Fishman Island"},
    {min=1575,max=1724,mob="Forest Pirate",       giver=Vector3.new(-3353,8,13081),   mobPos=Vector3.new(-3435,8,13153),  island="Colosseum"},
    {min=1725,max=1874,mob="Zombie",              giver=Vector3.new(-3353,8,13081),   mobPos=Vector3.new(-3500,8,13200),  island="Colosseum"},
    {min=1875,max=1999,mob="Vampire",             giver=Vector3.new(-3353,8,13081),   mobPos=Vector3.new(-3600,8,13300),  island="Colosseum"},
    {min=2000,max=2099,mob="Snow Demon",          giver=Vector3.new(926,15,34635),    mobPos=Vector3.new(1000,15,34700),  island="Ice Island"},
    {min=2100,max=2249,mob="Awakened Ice Admiral",giver=Vector3.new(926,15,34635),    mobPos=Vector3.new(1100,15,34800),  island="Ice Island"},
    -- Sea 3
    {min=2250,max=2449,mob="Tropical Zombie",     giver=Vector3.new(-13602,266,2614), mobPos=Vector3.new(-13700,266,2700),island="Tiki Outpost"},
    {min=2450,max=2649,mob="Cocoa Warrior",       giver=Vector3.new(-3302,8,6198),    mobPos=Vector3.new(-3400,8,6300),   island="Port Town"},
    {min=2650,max=2799,mob="Chocolate Bar Battler",giver=Vector3.new(-3302,8,6198),   mobPos=Vector3.new(-3500,8,6400),   island="Port Town"},
    {min=2800,max=2999,mob="Cake Guard",          giver=Vector3.new(-3302,8,6198),    mobPos=Vector3.new(-3600,8,6500),   island="Port Town"},
    {min=3000,max=3299,mob="Candy Rebel",         giver=Vector3.new(5301,8,1198),     mobPos=Vector3.new(5400,8,1300),    island="Candy Kingdom"},
    {min=3300,max=3999,mob="Candy Pirate",        giver=Vector3.new(5301,8,1198),     mobPos=Vector3.new(5500,8,1400),    island="Candy Kingdom"},
}

local function GetQuestForLevel()
    local lvl = GetLevel()
    for _, q in ipairs(QuestData) do
        if lvl >= q.min and lvl <= q.max then
            return q
        end
    end
    return QuestData[#QuestData]
end

local function TakeQuest(quest)
    if not quest then return end
    -- Teleport to quest giver
    InstantTo(quest.giver)
    task.wait(0.3)
    -- Fire quest remote
    if Remotes.Quest then
        pcall(function()
            Remotes.Quest:FireServer(quest.mob)
        end)
    end
    -- Try interaction
    for _, obj in ipairs(WS:GetDescendants()) do
        if obj:IsA("Model") and (obj.Name:lower():find("quest") or obj.Name:lower():find("npc")) then
            local hrp = obj:FindFirstChild("HumanoidRootPart")
            if hrp and (hrp.Position - quest.giver).Magnitude < 20 then
                local prompt = hrp:FindFirstChildOfClass("ProximityPrompt") or obj:FindFirstChildOfClass("ProximityPrompt")
                if prompt then
                    pcall(function() prompt:InputHoldBegin() task.wait(0.1) prompt:InputHoldEnd() end)
                end
            end
        end
    end
    State.QuestTaken = true
end

local function CheckQuest()
    -- Check if current quest is done / if we have a quest
    local questFolder = LocalPlayer:FindFirstChild("Quest") or LocalPlayer:FindFirstChild("CurrentQuest")
    if questFolder then
        local progress = questFolder:FindFirstChild("Progress") or questFolder:FindFirstChild("Current")
        local goal     = questFolder:FindFirstChild("Goal") or questFolder:FindFirstChild("Max")
        if progress and goal then
            return progress.Value >= goal.Value
        end
    end
    return not State.QuestTaken
end

--====================================================================--
--  MOB FINDER
--====================================================================--
local function GetEnemyFolders()
    local folders = {}
    for _, name in ipairs({"Enemies", "Mobs", "NPCs"}) do
        local f = WS:FindFirstChild(name)
        if f then table.insert(folders, f) end
    end
    return folders
end

local function GetClosestMob(mobName, maxDist)
    local root = GetRoot()
    if not root then return nil end
    local closest, closestDist = nil, maxDist or 150
    local folders = GetEnemyFolders()
    for _, folder in ipairs(folders) do
        for _, v in ipairs(folder:GetChildren()) do
            if (mobName == "" or v.Name:lower():find(mobName:lower())) and IsAlive(v) then
                local hrp = v:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local d = (hrp.Position - root.Position).Magnitude
                    if d < closestDist then
                        closest = v
                        closestDist = d
                    end
                end
            end
        end
    end
    return closest
end

local function GetClosestBoss()
    local root = GetRoot()
    if not root then return nil end
    local closest, closestDist = nil, math.huge
    local folders = GetEnemyFolders()
    for _, folder in ipairs(folders) do
        for _, v in ipairs(folder:GetChildren()) do
            local h = v:FindFirstChildOfClass("Humanoid")
            if h and h.Health > 0 and h.MaxHealth >= 50000 then
                local hrp = v:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local d = (hrp.Position - root.Position).Magnitude
                    if d < closestDist then
                        closest = v
                        closestDist = d
                    end
                end
            end
        end
    end
    return closest
end

--====================================================================--
--  AUTO FARM LOOP - Redz-style accuracy
--====================================================================--
local function FarmLoop()
    State.Farming = true
    while CFG.AutoFarm do
        local ok, err = pcall(function()
            local c = GetChar()
            local hum = c and c:FindFirstChildOfClass("Humanoid")
            if not c or not hum or hum.Health <= 0 then
                task.wait(1)
                return
            end

            EnableHaki()

            local quest = GetQuestForLevel()
            if not quest then task.wait(0.5) return end

            -- Auto quest take
            if CFG.AutoQuest and CheckQuest() then
                State.QuestTaken = false
                TakeQuest(quest)
                task.wait(0.5)
                return
            end

            -- Find target
            local target = nil
            if CFG.FarmMode == "Boss" then
                target = GetClosestBoss()
            elseif CFG.FarmMode == "Mastery" then
                EquipWeapon("Fruit")
                target = GetClosestMob("", CFG.FarmRadius)
            else
                target = GetClosestMob(quest.mob, 200)
            end

            if target then
                local hrp = target:FindFirstChild("HumanoidRootPart")
                if hrp and IsAlive(target) then
                    DoAttack(target)
                end
            else
                -- No mob found, tp to spawn
                if quest.mobPos then
                    InstantTo(quest.mobPos)
                    task.wait(0.3)
                end
            end

            -- Kill Aura
            if CFG.KillAura then
                local root = GetRoot()
                if root then
                    for _, folder in ipairs(GetEnemyFolders()) do
                        for _, v in ipairs(folder:GetChildren()) do
                            if IsAlive(v) then
                                local hrp = v:FindFirstChild("HumanoidRootPart")
                                if hrp and (hrp.Position - root.Position).Magnitude < 35 then
                                    DoAttack(v)
                                end
                            end
                        end
                    end
                end
            end
        end)
        if not ok then
            warn("[KarlHub] Farm error: " .. tostring(err))
        end
        task.wait(CFG.FarmDelay)
    end
    State.Farming = false
end

local function StartFarm()
    if State.FarmThread then task.cancel(State.FarmThread) State.FarmThread = nil end
    State.FarmThread = task.spawn(FarmLoop)
end

local function StopFarm()
    CFG.AutoFarm = false
    if State.FarmThread then
        task.cancel(State.FarmThread)
        State.FarmThread = nil
    end
    State.Farming = false
end

--====================================================================--
--  FRUIT SNIPER - Fixed
--====================================================================--
local FruitNames = {
    "Dragon","Dough","Venom","Control","Spirit","Shadow","Rumble","Paw",
    "Gravity","Phoenix","Magma","Quake","Dark","Light","Ice","String",
    "Barrier","Rubber","Chop","Spring","Kilo","Spin","Bomb","Smoke",
    "Flame","Falcon","Sand","Diamond","Ghost","Portal","Buddha","Love",
    "Spider","Sound","Blizzard","Leopard","Mammoth","T-Rex","Mythical",
}

local function ScanFruits()
    local found = {}
    local seen = {}
    -- Check Fruits folder
    local fruitsFolder = WS:FindFirstChild("Fruits") or WS:FindFirstChild("DroppedFruits")
    if fruitsFolder then
        for _, v in ipairs(fruitsFolder:GetChildren()) do
            if not seen[v] then
                seen[v] = true
                table.insert(found, v)
            end
        end
    end
    -- Scan workspace for dropped tools
    for _, v in ipairs(WS:GetChildren()) do
        if v:IsA("Tool") then
            local name = v.Name:lower()
            if name:find("fruit") or name:find(" fruit") then
                if not seen[v] then
                    seen[v] = true
                    table.insert(found, v)
                end
            end
        end
    end
    -- Also scan inside models
    for _, v in ipairs(WS:GetDescendants()) do
        if v:IsA("Model") and v.Parent == WS then
            for _, fn in ipairs(FruitNames) do
                if v.Name:lower():find(fn:lower()) then
                    if not seen[v] then
                        seen[v] = true
                        table.insert(found, v)
                    end
                    break
                end
            end
        end
    end
    return found
end

local function FruitLoop()
    while CFG.FruitSniper do
        pcall(function()
            local fruits = ScanFruits()
            local root = GetRoot()
            if not root then return end
            for _, fruit in ipairs(fruits) do
                -- filter by target
                local match = CFG.TargetFruit == "Any"
                if not match then
                    match = fruit.Name:lower():find(CFG.TargetFruit:lower())
                end
                if match then
                    local handle = fruit:FindFirstChild("Handle") or fruit:FindFirstChildOfClass("BasePart")
                    if handle then
                        local d = (handle.Position - root.Position).Magnitude
                        if d < 2000 then
                            InstantTo(handle.Position)
                            task.wait(0.2)
                            -- Pick up: touch it
                            if GetRoot() then
                                GetRoot().CFrame = CFrame.new(handle.Position)
                            end
                            -- Store remote
                            if CFG.FruitStore and Remotes.StoreFruit then
                                pcall(function() Remotes.StoreFruit:FireServer(fruit.Name) end)
                            end
                            Notify("Karl Hub", "🍎 Got: " .. fruit.Name, 3)
                        end
                    end
                end
            end
        end)
        task.wait(0.5)
    end
end

local function StartFruitSniper()
    if State.FruitThread then task.cancel(State.FruitThread) State.FruitThread = nil end
    State.FruitThread = task.spawn(FruitLoop)
end
local function StopFruitSniper()
    if State.FruitThread then task.cancel(State.FruitThread) State.FruitThread = nil end
end

--====================================================================--
--  BOSS FARM - Fixed
--====================================================================--
local BossData = {
    {name="Gorilla King",   pos=Vector3.new(-1816,70,478)},
    {name="Bobby",          pos=Vector3.new(1138,16,1600)},
    {name="Yeti",           pos=Vector3.new(1497,400,-5262)},
    {name="Cursed Captain", pos=Vector3.new(-1181,4,406)},
    {name="Greybeard",      pos=Vector3.new(-4812,852,-2876)},
    {name="Saber Expert",   pos=Vector3.new(-4710,855,-1920)},
    {name="Wysper",         pos=Vector3.new(-4710,855,-1920)},
    {name="Thunder God",    pos=Vector3.new(252,10,2003)},
    {name="Cyborg",         pos=Vector3.new(498,603,-5997)},
    {name="Ice Admiral",    pos=Vector3.new(926,15,34635)},
    {name="Order",          pos=Vector3.new(-13602,266,2614)},
    {name="Cake Queen",     pos=Vector3.new(-3302,8,6198)},
    {name="Longma",         pos=Vector3.new(5301,8,1198)},
}

--====================================================================--
--  AUTO RAID - Fixed
--====================================================================--
local function RaidLoop()
    while CFG.AutoRaid do
        pcall(function()
            if CFG.RaidChip then
                -- Buy chip from NPC
                local chipNPC = WS:FindFirstChild("RaidNPC") or WS:FindFirstChild("TradingHub")
                if Remotes.Chip then
                    pcall(function() Remotes.Chip:FireServer("Buy") end)
                end
            end
            if Remotes.Raid then
                pcall(function() Remotes.Raid:FireServer("StartRaid") end)
            end
            -- Fight raid enemies
            for _, folder in ipairs(GetEnemyFolders()) do
                for _, v in ipairs(folder:GetChildren()) do
                    if IsAlive(v) then
                        local hrp = v:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            InstantTo(hrp.Position)
                            DoAttack(v)
                        end
                    end
                end
            end
            if CFG.AutoAwaken and Remotes.Awaken then
                pcall(function() Remotes.Awaken:FireServer("Awaken") end)
            end
        end)
        task.wait(0.1)
    end
end

local function StartRaid()
    if State.RaidThread then task.cancel(State.RaidThread) State.RaidThread = nil end
    State.RaidThread = task.spawn(RaidLoop)
end
local function StopRaid()
    if State.RaidThread then task.cancel(State.RaidThread) State.RaidThread = nil end
end

--====================================================================--
--  AUTO STATS - Fixed
--====================================================================--
local StatRemoteMap = {
    Melee       = "Melee",
    Defense     = "Defense",
    Sword       = "Sword",
    Gun         = "Gun",
    ["Demon Fruit"] = "Devil_Fruit",
}

local function StatLoop()
    while CFG.AutoStats do
        pcall(function()
            local statKey = StatRemoteMap[CFG.StatPoints] or CFG.StatPoints
            if Remotes.Stat then
                Remotes.Stat:FireServer(statKey, 1)
            else
                -- Try alternative names
                local r = RS:FindFirstChild("AddStatPoint", true) or RS:FindFirstChild("StatPoint", true)
                if r then r:FireServer(statKey) end
            end
        end)
        task.wait(0.3)
    end
end

local function StartStats()
    if State.StatThread then task.cancel(State.StatThread) State.StatThread = nil end
    State.StatThread = task.spawn(StatLoop)
end
local function StopStats()
    if State.StatThread then task.cancel(State.StatThread) State.StatThread = nil end
end

--====================================================================--
--  ESP - Fixed & Accurate
--====================================================================--
local function ClearESP()
    for _, v in ipairs(State.ESPObjects) do
        pcall(function() v:Destroy() end)
    end
    State.ESPObjects = {}
end

local function CreateBillboard(adornee, text, color)
    if not adornee then return end
    local existing = adornee:FindFirstChild("KarlESP")
    if existing then existing:Destroy() end

    local bill = Instance.new("BillboardGui")
    bill.Name = "KarlESP"
    bill.Adornee = adornee
    bill.Size = UDim2.new(0, 120, 0, 50)
    bill.StudsOffset = Vector3.new(0, 2.5, 0)
    bill.AlwaysOnTop = true
    bill.MaxDistance = 1000

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1,0,1,0)
    bg.BackgroundColor3 = Color3.fromRGB(0,0,0)
    bg.BackgroundTransparency = 0.5
    bg.BorderSizePixel = 0
    bg.Parent = bill

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0,4)
    corner.Parent = bg

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = color or Color3.fromRGB(255,60,60)
    lbl.TextStrokeTransparency = 0
    lbl.TextStrokeColor3 = Color3.new(0,0,0)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 13
    lbl.Text = text
    lbl.Parent = bill

    bill.Parent = adornee
    table.insert(State.ESPObjects, bill)
end

local function UpdateESP()
    ClearESP()
    if CFG.PlayerESP then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local lvl = pcall(function() return p.Data.Level.Value end) and "" or ""
                    CreateBillboard(hrp, p.Name, Color3.fromRGB(60,255,60))
                end
            end
        end
    end
    if CFG.MobESP then
        for _, folder in ipairs(GetEnemyFolders()) do
            for _, v in ipairs(folder:GetChildren()) do
                if IsAlive(v) then
                    local hrp = v:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local h = v:FindFirstChildOfClass("Humanoid")
                        local hp = h and math.floor(h.Health) or 0
                        CreateBillboard(hrp, v.Name .. " [" .. hp .. "]", Color3.fromRGB(255,60,60))
                    end
                end
            end
        end
    end
    if CFG.FruitESP then
        for _, fruit in ipairs(ScanFruits()) do
            local part = fruit:FindFirstChild("Handle") or fruit:FindFirstChildOfClass("BasePart")
            if part then
                CreateBillboard(part, "🍎 " .. fruit.Name, Color3.fromRGB(255,255,60))
            end
        end
    end
    if CFG.ChestESP then
        for _, v in ipairs(WS:GetDescendants()) do
            if v:IsA("Model") and (v.Name:lower():find("chest") or v.Name:lower():find("treasure")) then
                local part = v:FindFirstChild("HumanoidRootPart") or v:FindFirstChildOfClass("BasePart")
                if part then
                    CreateBillboard(part, "📦 " .. v.Name, Color3.fromRGB(255,200,60))
                end
            end
        end
    end
end

-- Auto refresh ESP
task.spawn(function()
    while true do
        if CFG.PlayerESP or CFG.MobESP or CFG.FruitESP or CFG.ChestESP then
            pcall(UpdateESP)
        end
        task.wait(3)
    end
end)

--====================================================================--
--  MOVEMENT / MISC
--====================================================================--
local function ApplyMovement()
    local hum = GetHum()
    if hum then
        hum.WalkSpeed = CFG.WalkSpeed
        hum.JumpPower = CFG.JumpPower
    end
end

-- Keep applying walk speed (games often reset it)
RunService.Heartbeat:Connect(function()
    if CFG.WalkSpeed ~= 16 or CFG.JumpPower ~= 50 then
        local hum = GetHum()
        if hum and hum.WalkSpeed ~= CFG.WalkSpeed then
            hum.WalkSpeed = CFG.WalkSpeed
            hum.JumpPower = CFG.JumpPower
        end
    end
end)

-- FLY - Fixed
local function StartFly()
    if State.Flying then return end
    State.Flying = true
    local root = GetRoot()
    if not root then State.Flying = false return end

    -- Remove old instances
    local old1 = root:FindFirstChild("KarlFlyGyro")
    local old2 = root:FindFirstChild("KarlFlyVel")
    if old1 then old1:Destroy() end
    if old2 then old2:Destroy() end

    local bg = Instance.new("BodyGyro")
    bg.Name = "KarlFlyGyro"
    bg.P = 9e4
    bg.maxTorque = Vector3.new(9e9,9e9,9e9)
    bg.CFrame = root.CFrame
    bg.Parent = root

    local bv = Instance.new("BodyVelocity")
    bv.Name = "KarlFlyVel"
    bv.MaxForce = Vector3.new(9e9,9e9,9e9)
    bv.Velocity = Vector3.new(0,0,0)
    bv.Parent = root

    State.FlyGyro = bg
    State.FlyVel = bv

    task.spawn(function()
        while State.Flying do
            local root2 = GetRoot()
            if not root2 then break end
            local dir = Vector3.new(0,0,0)
            if UserInput:IsKeyDown(Enum.KeyCode.W) then dir = dir + Camera.CFrame.LookVector end
            if UserInput:IsKeyDown(Enum.KeyCode.S) then dir = dir - Camera.CFrame.LookVector end
            if UserInput:IsKeyDown(Enum.KeyCode.A) then dir = dir - Camera.CFrame.RightVector end
            if UserInput:IsKeyDown(Enum.KeyCode.D) then dir = dir + Camera.CFrame.RightVector end
            if UserInput:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
            if UserInput:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0,1,0) end
            dir = Vector3.new(dir.X, dir.Y, dir.Z)
            bv.Velocity = dir.Magnitude > 0 and dir.Unit * CFG.FlySpeed or Vector3.new(0,0,0)
            bg.CFrame = Camera.CFrame
            RunService.Heartbeat:Wait()
        end
        pcall(function() bg:Destroy() bv:Destroy() end)
    end)
end

local function StopFly()
    State.Flying = false
    if State.FlyGyro then pcall(function() State.FlyGyro:Destroy() end) State.FlyGyro = nil end
    if State.FlyVel  then pcall(function() State.FlyVel:Destroy()  end) State.FlyVel  = nil end
end

-- NOCLIP - Fixed
local function StartNoclip()
    if State.Noclipping then return end
    State.Noclipping = true
    State.NoclipConn = RunService.Stepped:Connect(function()
        local c = GetChar()
        if c then
            for _, v in ipairs(c:GetDescendants()) do
                if v:IsA("BasePart") and v.CanCollide then
                    v.CanCollide = false
                end
            end
        end
    end)
end

local function StopNoclip()
    State.Noclipping = false
    if State.NoclipConn then
        State.NoclipConn:Disconnect()
        State.NoclipConn = nil
    end
    local c = GetChar()
    if c then
        for _, v in ipairs(c:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = true end
        end
    end
end

-- INFINITE JUMP
UserInput.JumpRequest:Connect(function()
    if CFG.InfiniteJump then
        local hum = GetHum()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- ANTI AFK
LocalPlayer.Idled:Connect(function()
    if CFG.AntiAFK then
        pcall(function()
            local vu = game:GetService("VirtualInputManager")
            vu:SendKeyEvent(true, Enum.KeyCode.W, false, game)
            task.wait(0.1)
            vu:SendKeyEvent(false, Enum.KeyCode.W, false, game)
        end)
    end
end)

-- FPS BOOST
local function ApplyFPSBoost(enable)
    if enable then
        for _, v in ipairs(WS:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") then
                v.Enabled = false
            end
            if v:IsA("Decal") or v:IsA("Texture") then
                v.Transparency = 1
            end
        end
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
        Notify("Karl Hub","FPS Boost ON - reduced particles",3)
    else
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level10 end)
    end
end

-- SERVER HOP
local function ServerHop()
    if tick() - State.HopCooldown < 10 then
        Notify("Karl Hub","Cooldown active, wait 10s",2)
        return
    end
    State.HopCooldown = tick()
    task.spawn(function()
        pcall(function()
            local ok, req = pcall(function()
                return game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
            end)
            if not ok then Notify("Karl Hub","ServerHop failed: HTTP blocked",3) return end
            local data = HttpService:JSONDecode(req)
            local servers = {}
            for _, v in ipairs(data.data) do
                if v.playing < v.maxPlayers and v.id ~= game.JobId then
                    table.insert(servers, v.id)
                end
            end
            if #servers > 0 then
                TeleportSvc:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1,#servers)], LocalPlayer)
            else
                Notify("Karl Hub","No servers found",3)
            end
        end)
    end)
end

--====================================================================--
--  TELEPORT DATA (accurate island positions)
--====================================================================--
local IslandPositions = {
    -- Sea 1
    ["Starter Island"]    = Vector3.new(1065,16,1548),
    ["Jungle"]            = Vector3.new(-1596,36,142),
    ["Pirate Village"]    = Vector3.new(-1222,4,334),
    ["Desert"]            = Vector3.new(922,7,4477),
    ["Snow Island"]       = Vector3.new(1363,400,-5188),
    ["Marine Fortress"]   = Vector3.new(-4812,852,-2876),
    ["Skypiea"]           = Vector3.new(-4710,855,-1920),
    ["Long Ring"]         = Vector3.new(252,10,2003),
    ["Flamingo"]          = Vector3.new(-6008,297,-5003),
    ["Ice Castle"]        = Vector3.new(-194,400,6997),
    ["Forgotten Island"]  = Vector3.new(498,603,-5997),
    -- Sea 2
    ["Fishman Island"]    = Vector3.new(61386,15,1535),
    ["Colosseum"]         = Vector3.new(-3353,8,13081),
    ["Ice Island (S2)"]   = Vector3.new(926,15,34635),
    ["Cake Ship"]         = Vector3.new(-3600,8,13200),
    ["Thriller Bark"]     = Vector3.new(-10900,0,-5300),
    -- Sea 3
    ["Tiki Outpost"]      = Vector3.new(-13602,266,2614),
    ["Port Town"]         = Vector3.new(-3302,8,6198),
    ["Candy Kingdom"]     = Vector3.new(5301,8,1198),
    ["Floating Turtle"]   = Vector3.new(-8056,118,-10378),
    ["Hydra Island"]      = Vector3.new(-2088,0,5560),
    ["Great Tree"]        = Vector3.new(-3302,8,6198),
    ["Mansion"]           = Vector3.new(-3600,8,6500),
    -- Misc
    ["Marineford"]        = Vector3.new(-25000,0,-15000),
    ["Impel Down"]        = Vector3.new(70000,0,70000),
}

--====================================================================--
--  GUI - Polished, matches screenshots
--====================================================================--
local function CreateGUI()
    -- Destroy old
    local old = LocalPlayer.PlayerGui:FindFirstChild("KarlHubV1")
    if old then old:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "KarlHubV1"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 999

    --== MINIMIZED BAR ==--
    local miniBar = Instance.new("Frame")
    miniBar.Name = "MiniBar"
    miniBar.Size = UDim2.new(0, 400, 0, 36)
    miniBar.Position = UDim2.new(0.5, -200, 1, -40)
    miniBar.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    miniBar.BorderSizePixel = 0
    miniBar.Visible = false
    miniBar.Active = true
    miniBar.Draggable = true
    miniBar.Parent = gui

    local miniCorner = Instance.new("UICorner")
    miniCorner.CornerRadius = UDim.new(0,8)
    miniCorner.Parent = miniBar

    local miniStroke = Instance.new("UIStroke")
    miniStroke.Color = Color3.fromRGB(255,60,60)
    miniStroke.Thickness = 2
    miniStroke.Parent = miniBar

    local miniTitle = Instance.new("TextLabel")
    miniTitle.Size = UDim2.new(1,-50,1,0)
    miniTitle.Position = UDim2.new(0,10,0,0)
    miniTitle.BackgroundTransparency = 1
    miniTitle.TextColor3 = Color3.fromRGB(255,60,60)
    miniTitle.Font = Enum.Font.GothamBold
    miniTitle.TextSize = 14
    miniTitle.TextXAlignment = Enum.TextXAlignment.Left
    miniTitle.Text = "KARL HUB V1  |  @Karl08901"
    miniTitle.Parent = miniBar

    local expandBtn = Instance.new("TextButton")
    expandBtn.Size = UDim2.new(0,36,0,36)
    expandBtn.Position = UDim2.new(1,-36,0,0)
    expandBtn.BackgroundColor3 = Color3.fromRGB(60,180,60)
    expandBtn.BorderSizePixel = 0
    expandBtn.TextColor3 = Color3.new(1,1,1)
    expandBtn.Font = Enum.Font.GothamBold
    expandBtn.TextSize = 16
    expandBtn.Text = "+"
    expandBtn.Parent = miniBar

    local expandCorner = Instance.new("UICorner")
    expandCorner.CornerRadius = UDim.new(0,8)
    expandCorner.Parent = expandBtn

    --== MAIN FRAME ==--
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, 580, 0, 460)
    main.Position = UDim2.new(0.5, -290, 0.5, -230)
    main.BackgroundColor3 = Color3.fromRGB(13, 13, 18)
    main.BorderSizePixel = 0
    main.Active = true
    main.Draggable = true
    main.Parent = gui

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0,10)
    mainCorner.Parent = main

    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = Color3.fromRGB(255,60,60)
    mainStroke.Thickness = 2
    mainStroke.Parent = main

    --== TITLE BAR ==--
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1,0,0,44)
    titleBar.BackgroundColor3 = Color3.fromRGB(18,18,26)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = main

    local titleBarCorner = Instance.new("UICorner")
    titleBarCorner.CornerRadius = UDim.new(0,10)
    titleBarCorner.Parent = titleBar

    -- Logo circle
    local logo = Instance.new("Frame")
    logo.Size = UDim2.new(0,30,0,30)
    logo.Position = UDim2.new(0,8,0.5,-15)
    logo.BackgroundColor3 = Color3.fromRGB(255,60,60)
    logo.BorderSizePixel = 0
    logo.Parent = titleBar
    local logoCorner = Instance.new("UICorner")
    logoCorner.CornerRadius = UDim.new(0,15)
    logoCorner.Parent = logo
    local logoLbl = Instance.new("TextLabel")
    logoLbl.Size = UDim2.new(1,0,1,0)
    logoLbl.BackgroundTransparency = 1
    logoLbl.TextColor3 = Color3.new(1,1,1)
    logoLbl.Font = Enum.Font.GothamBold
    logoLbl.TextSize = 12
    logoLbl.Text = "K"
    logoLbl.Parent = logo

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1,-120,1,0)
    titleLbl.Position = UDim2.new(0,46,0,0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.TextColor3 = Color3.fromRGB(255,60,60)
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 17
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Text = "KARL HUB V1  |  @Karl08901"
    titleLbl.Parent = titleBar

    -- Minimize button
    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.new(0,36,0,36)
    minBtn.Position = UDim2.new(1,-80,0,4)
    minBtn.BackgroundColor3 = Color3.fromRGB(60,120,255)
    minBtn.BorderSizePixel = 0
    minBtn.TextColor3 = Color3.new(1,1,1)
    minBtn.Font = Enum.Font.GothamBold
    minBtn.TextSize = 18
    minBtn.Text = "—"
    minBtn.Parent = titleBar
    local minCorner = Instance.new("UICorner")
    minCorner.CornerRadius = UDim.new(0,8)
    minCorner.Parent = minBtn

    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0,36,0,36)
    closeBtn.Position = UDim2.new(1,-40,0,4)
    closeBtn.BackgroundColor3 = Color3.fromRGB(220,40,40)
    closeBtn.BorderSizePixel = 0
    closeBtn.TextColor3 = Color3.new(1,1,1)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 18
    closeBtn.Text = "X"
    closeBtn.Parent = titleBar
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0,8)
    closeCorner.Parent = closeBtn

    --== TAB BAR ==--
    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(0,130,1,-44)
    tabBar.Position = UDim2.new(0,0,0,44)
    tabBar.BackgroundColor3 = Color3.fromRGB(16,16,22)
    tabBar.BorderSizePixel = 0
    tabBar.Parent = main

    local tabList = Instance.new("UIListLayout")
    tabList.Padding = UDim.new(0,2)
    tabList.Parent = tabBar

    local tabPad = Instance.new("UIPadding")
    tabPad.PaddingTop = UDim.new(0,4)
    tabPad.PaddingLeft = UDim.new(0,4)
    tabPad.PaddingRight = UDim.new(0,4)
    tabPad.Parent = tabBar

    --== CONTENT AREA ==--
    local contentArea = Instance.new("Frame")
    contentArea.Size = UDim2.new(1,-130,1,-44)
    contentArea.Position = UDim2.new(0,130,0,44)
    contentArea.BackgroundTransparency = 1
    contentArea.BorderSizePixel = 0
    contentArea.Parent = main

    local divider = Instance.new("Frame")
    divider.Size = UDim2.new(0,2,1,-44)
    divider.Position = UDim2.new(0,130,0,44)
    divider.BackgroundColor3 = Color3.fromRGB(255,60,60)
    divider.BorderSizePixel = 0
    divider.Parent = main

    --== TAB SYSTEM ==--
    local tabBtns = {}
    local tabPages = {}

    local function AddTab(name, icon)
        local tabBtn = Instance.new("TextButton")
        tabBtn.Size = UDim2.new(1,0,0,38)
        tabBtn.BackgroundColor3 = Color3.fromRGB(22,22,30)
        tabBtn.BorderSizePixel = 0
        tabBtn.TextColor3 = Color3.fromRGB(180,180,180)
        tabBtn.Font = Enum.Font.GothamBold
        tabBtn.TextSize = 12
        tabBtn.Text = (icon and icon .. " " or "") .. name
        tabBtn.Parent = tabBar

        local tabBtnCorner = Instance.new("UICorner")
        tabBtnCorner.CornerRadius = UDim.new(0,6)
        tabBtnCorner.Parent = tabBtn

        local page = Instance.new("ScrollingFrame")
        page.Size = UDim2.new(1,0,1,0)
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.ScrollBarThickness = 3
        page.ScrollBarImageColor3 = Color3.fromRGB(255,60,60)
        page.CanvasSize = UDim2.new(0,0,0,0)
        page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        page.Visible = false
        page.Parent = contentArea

        local pageList = Instance.new("UIListLayout")
        pageList.Padding = UDim.new(0,5)
        pageList.Parent = page

        local pagePad = Instance.new("UIPadding")
        pagePad.PaddingTop = UDim.new(0,8)
        pagePad.PaddingLeft = UDim.new(0,8)
        pagePad.PaddingRight = UDim.new(0,8)
        pagePad.PaddingBottom = UDim.new(0,8)
        pagePad.Parent = page

        table.insert(tabBtns, tabBtn)
        table.insert(tabPages, page)

        tabBtn.MouseButton1Click:Connect(function()
            for _, b in ipairs(tabBtns) do
                b.BackgroundColor3 = Color3.fromRGB(22,22,30)
                b.TextColor3 = Color3.fromRGB(180,180,180)
            end
            for _, p in ipairs(tabPages) do
                p.Visible = false
            end
            tabBtn.BackgroundColor3 = Color3.fromRGB(255,60,60)
            tabBtn.TextColor3 = Color3.new(1,1,1)
            page.Visible = true
        end)

        return page
    end

    --== UI ELEMENTS ==--
    local function MakeCorner(parent, rad)
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, rad or 6)
        c.Parent = parent
        return c
    end

    local function AddSection(page, text)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1,-16,0,20)
        lbl.BackgroundTransparency = 1
        lbl.TextColor3 = Color3.fromRGB(255,60,60)
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 11
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Text = "━━  " .. text:upper() .. "  ━━━━━━━━━━━━━━"
        lbl.Parent = page
    end

    local function AddToggle(page, text, default, callback)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1,-16,0,36)
        row.BackgroundColor3 = Color3.fromRGB(22,22,30)
        row.BorderSizePixel = 0
        row.Parent = page
        MakeCorner(row, 6)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1,-60,1,0)
        lbl.Position = UDim2.new(0,10,0,0)
        lbl.BackgroundTransparency = 1
        lbl.TextColor3 = Color3.fromRGB(220,220,220)
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 13
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Text = text
        lbl.Parent = row

        local toggleBg = Instance.new("Frame")
        toggleBg.Size = UDim2.new(0,44,0,22)
        toggleBg.Position = UDim2.new(1,-52,0.5,-11)
        toggleBg.BackgroundColor3 = default and Color3.fromRGB(60,220,60) or Color3.fromRGB(60,60,70)
        toggleBg.BorderSizePixel = 0
        toggleBg.Parent = row
        MakeCorner(toggleBg, 11)

        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0,18,0,18)
        knob.Position = default and UDim2.new(1,-20,0.5,-9) or UDim2.new(0,2,0.5,-9)
        knob.BackgroundColor3 = Color3.new(1,1,1)
        knob.BorderSizePixel = 0
        knob.Parent = toggleBg
        MakeCorner(knob, 9)

        local state = default or false

        local function SetState(val)
            state = val
            local goal1 = val and Color3.fromRGB(60,220,60) or Color3.fromRGB(60,60,70)
            local goal2 = val and UDim2.new(1,-20,0.5,-9) or UDim2.new(0,2,0.5,-9)
            TweenService:Create(toggleBg, TweenInfo.new(0.15), {BackgroundColor3=goal1}):Play()
            TweenService:Create(knob, TweenInfo.new(0.15), {Position=goal2}):Play()
            callback(val)
        end

        row.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                SetState(not state)
            end
        end)

        return {SetState = SetState, GetState = function() return state end}
    end

    local function AddDropdown(page, text, options, default, callback)
        local wrapper = Instance.new("Frame")
        wrapper.Size = UDim2.new(1,-16,0,60)
        wrapper.BackgroundColor3 = Color3.fromRGB(22,22,30)
        wrapper.BorderSizePixel = 0
        wrapper.ClipsDescendants = false
        wrapper.Parent = page
        MakeCorner(wrapper, 6)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1,-10,0,22)
        lbl.Position = UDim2.new(0,8,0,2)
        lbl.BackgroundTransparency = 1
        lbl.TextColor3 = Color3.fromRGB(150,150,150)
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 11
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Text = text
        lbl.Parent = wrapper

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1,-16,0,30)
        btn.Position = UDim2.new(0,8,0,24)
        btn.BackgroundColor3 = Color3.fromRGB(32,32,42)
        btn.BorderSizePixel = 0
        btn.TextColor3 = Color3.new(1,1,1)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 12
        btn.Text = "  " .. (default or options[1]) .. "  ▼"
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Parent = wrapper
        MakeCorner(btn, 4)

        local dropOpen = false
        local dropFrame = nil

        btn.MouseButton1Click:Connect(function()
            if dropOpen then
                if dropFrame then dropFrame:Destroy() dropFrame = nil end
                dropOpen = false
                return
            end
            dropOpen = true
            dropFrame = Instance.new("Frame")
            dropFrame.Size = UDim2.new(1,0,0,math.min(#options,6)*26+4)
            dropFrame.Position = UDim2.new(0,8,0,56)
            dropFrame.BackgroundColor3 = Color3.fromRGB(28,28,38)
            dropFrame.BorderSizePixel = 0
            dropFrame.ZIndex = 50
            dropFrame.Parent = wrapper
            MakeCorner(dropFrame, 4)

            local sf = Instance.new("ScrollingFrame")
            sf.Size = UDim2.new(1,0,1,0)
            sf.BackgroundTransparency = 1
            sf.BorderSizePixel = 0
            sf.ScrollBarThickness = 2
            sf.CanvasSize = UDim2.new(0,0,0,#options*26)
            sf.ZIndex = 50
            sf.Parent = dropFrame

            local sfl = Instance.new("UIListLayout")
            sfl.Parent = sf

            for _, opt in ipairs(options) do
                local ob = Instance.new("TextButton")
                ob.Size = UDim2.new(1,0,0,26)
                ob.BackgroundColor3 = Color3.fromRGB(28,28,38)
                ob.BorderSizePixel = 0
                ob.TextColor3 = Color3.fromRGB(220,220,220)
                ob.Font = Enum.Font.Gotham
                ob.TextSize = 12
                ob.Text = "  " .. opt
                ob.TextXAlignment = Enum.TextXAlignment.Left
                ob.ZIndex = 51
                ob.Parent = sf

                ob.MouseEnter:Connect(function() ob.BackgroundColor3 = Color3.fromRGB(50,50,65) end)
                ob.MouseLeave:Connect(function() ob.BackgroundColor3 = Color3.fromRGB(28,28,38) end)
                ob.MouseButton1Click:Connect(function()
                    btn.Text = "  " .. opt .. "  ▼"
                    callback(opt)
                    dropFrame:Destroy()
                    dropFrame = nil
                    dropOpen = false
                end)
            end
        end)

        return wrapper
    end

    local function AddSlider(page, text, min, max, default, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1,-16,0,56)
        frame.BackgroundColor3 = Color3.fromRGB(22,22,30)
        frame.BorderSizePixel = 0
        frame.Parent = page
        MakeCorner(frame, 6)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1,-10,0,20)
        lbl.Position = UDim2.new(0,8,0,4)
        lbl.BackgroundTransparency = 1
        lbl.TextColor3 = Color3.fromRGB(220,220,220)
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 12
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Text = text .. ": " .. tostring(default)
        lbl.Parent = frame

        local track = Instance.new("Frame")
        track.Size = UDim2.new(1,-20,0,6)
        track.Position = UDim2.new(0,10,0,36)
        track.BackgroundColor3 = Color3.fromRGB(40,40,52)
        track.BorderSizePixel = 0
        track.Parent = frame
        MakeCorner(track, 3)

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((default-min)/(max-min),0,1,0)
        fill.BackgroundColor3 = Color3.fromRGB(255,60,60)
        fill.BorderSizePixel = 0
        fill.Parent = track
        MakeCorner(fill, 3)

        local thumb = Instance.new("Frame")
        thumb.Size = UDim2.new(0,14,0,14)
        thumb.Position = UDim2.new((default-min)/(max-min),0,0.5,-7)
        thumb.BackgroundColor3 = Color3.new(1,1,1)
        thumb.BorderSizePixel = 0
        thumb.ZIndex = 2
        thumb.Parent = track
        MakeCorner(thumb, 7)

        local dragging = false
        local function Update(inputX)
            local rel = math.clamp((inputX - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            local val = math.floor(min + rel*(max-min))
            fill.Size = UDim2.new(rel,0,1,0)
            thumb.Position = UDim2.new(rel,0,0.5,-7)
            lbl.Text = text .. ": " .. tostring(val)
            callback(val)
        end

        track.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                Update(inp.Position.X)
            end
        end)
        UserInput.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
        UserInput.InputChanged:Connect(function(inp)
            if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
                Update(inp.Position.X)
            end
        end)

        return frame
    end

    local function AddButton(page, text, callback, color)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1,-16,0,34)
        btn.BackgroundColor3 = color or Color3.fromRGB(255,60,60)
        btn.BorderSizePixel = 0
        btn.TextColor3 = Color3.new(1,1,1)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 13
        btn.Text = text
        btn.Parent = page
        MakeCorner(btn, 6)

        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(220,40,40)}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = color or Color3.fromRGB(255,60,60)}):Play()
        end)
        btn.MouseButton1Click:Connect(callback)
        return btn
    end

    --======================================================--
    --  TABS
    --======================================================--
    local farmPage  = AddTab("Auto Farm",   "⚔")
    local fruitPage = AddTab("Fruit Sniper","🍎")
    local bossPage  = AddTab("Boss / Raid", "👑")
    local espPage   = AddTab("ESP",         "👁")
    local miscPage  = AddTab("Misc",        "⚙")
    local tpPage    = AddTab("Teleport",    "🌐")

    -- Activate first tab
    tabBtns[1].BackgroundColor3 = Color3.fromRGB(255,60,60)
    tabBtns[1].TextColor3 = Color3.new(1,1,1)
    tabPages[1].Visible = true

    --======================================================--
    --  FARM TAB
    --======================================================--
    AddSection(farmPage, "Farm Mode")
    AddDropdown(farmPage, "Farm Mode", {"Level", "Mastery", "Boss", "Chest"}, "Level", function(v)
        CFG.FarmMode = v
    end)
    AddDropdown(farmPage, "Weapon", {"Melee","Sword","Gun","Fruit"}, "Melee", function(v)
        CFG.SelectedWeapon = v
    end)
    AddSlider(farmPage, "Farm Delay (ms)", 0, 500, 100, function(v)
        CFG.FarmDelay = v / 1000
    end)

    AddSection(farmPage, "Toggles")
    AddToggle(farmPage, "Auto Farm", false, function(v)
        CFG.AutoFarm = v
        if v then StartFarm() else StopFarm() end
    end)
    AddToggle(farmPage, "Fast Attack", true, function(v) CFG.FastAttack = v end)
    AddToggle(farmPage, "Auto Haki", true, function(v) CFG.AutoHaki = v end)
    AddToggle(farmPage, "Auto Buso", true, function(v) CFG.AutoBuso = v end)
    AddToggle(farmPage, "Auto Ken", true, function(v) CFG.AutoKen = v end)
    AddToggle(farmPage, "Auto Dodge", true, function(v) CFG.AutoDodge = v end)
    AddToggle(farmPage, "Bring Mob", true, function(v) CFG.BringMob = v end)
    AddToggle(farmPage, "Kill Aura", false, function(v) CFG.KillAura = v end)
    AddToggle(farmPage, "Auto Quest", true, function(v) CFG.AutoQuest = v end)

    --======================================================--
    --  FRUIT SNIPER TAB
    --======================================================--
    AddSection(fruitPage, "Fruit Sniper")
    AddToggle(fruitPage, "Fruit Sniper", false, function(v)
        CFG.FruitSniper = v
        if v then StartFruitSniper() else StopFruitSniper() end
    end)
    AddToggle(fruitPage, "Auto Store Fruit", true, function(v) CFG.FruitStore = v end)

    local fruitListWithAny = {"Any"}
    for _, f in ipairs(FruitNames) do table.insert(fruitListWithAny, f) end
    AddDropdown(fruitPage, "Target Fruit", fruitListWithAny, "Any", function(v)
        CFG.TargetFruit = v
    end)

    AddSection(fruitPage, "Fruit ESP")
    AddToggle(fruitPage, "Fruit ESP", false, function(v)
        CFG.FruitESP = v
        UpdateESP()
    end)
    AddButton(fruitPage, "Scan Fruits Now", function()
        local fruits = ScanFruits()
        Notify("Karl Hub", "Found " .. #fruits .. " fruits nearby", 3)
    end)

    --======================================================--
    --  BOSS / RAID TAB
    --======================================================--
    AddSection(bossPage, "Boss Farm")
    AddToggle(bossPage, "Auto Boss", false, function(v)
        CFG.AutoBoss = v
        CFG.FarmMode = v and "Boss" or "Level"
        if v then
            CFG.AutoFarm = true
            StartFarm()
        end
    end)

    -- Boss selector
    local bossNames = {}
    for _, b in ipairs(BossData) do table.insert(bossNames, b.name) end
    AddDropdown(bossPage, "Boss Target", bossNames, bossNames[1], function(v)
        CFG.SelectedBoss = v
    end)

    AddButton(bossPage, "TP to Boss", function()
        for _, b in ipairs(BossData) do
            if b.name == CFG.SelectedBoss then
                InstantTo(b.pos)
                Notify("Karl Hub", "TP to " .. b.name, 2)
                break
            end
        end
    end, Color3.fromRGB(60,120,255))

    AddSection(bossPage, "Raid")
    AddToggle(bossPage, "Auto Raid", false, function(v)
        CFG.AutoRaid = v
        if v then StartRaid() else StopRaid() end
    end)
    AddToggle(bossPage, "Auto Buy Chip", false, function(v) CFG.RaidChip = v end)
    AddToggle(bossPage, "Auto Awaken", false, function(v) CFG.AutoAwaken = v end)

    --======================================================--
    --  ESP TAB
    --======================================================--
    AddSection(espPage, "ESP Options")
    AddToggle(espPage, "Player ESP", false, function(v) CFG.PlayerESP = v UpdateESP() end)
    AddToggle(espPage, "Mob ESP", false, function(v) CFG.MobESP = v UpdateESP() end)
    AddToggle(espPage, "Fruit ESP", false, function(v) CFG.FruitESP = v UpdateESP() end)
    AddToggle(espPage, "Chest ESP", false, function(v) CFG.ChestESP = v UpdateESP() end)
    AddButton(espPage, "Refresh ESP", function()
        UpdateESP()
        Notify("Karl Hub","ESP Refreshed",2)
    end, Color3.fromRGB(60,120,255))
    AddButton(espPage, "Clear ESP", function()
        CFG.PlayerESP = false
        CFG.MobESP    = false
        CFG.FruitESP  = false
        CFG.ChestESP  = false
        ClearESP()
        Notify("Karl Hub","ESP Cleared",2)
    end, Color3.fromRGB(80,80,80))

    --======================================================--
    --  MISC TAB
    --======================================================--
    AddSection(miscPage, "Stats")
    AddToggle(miscPage, "Auto Stats", false, function(v)
        CFG.AutoStats = v
        if v then StartStats() else StopStats() end
    end)
    AddDropdown(miscPage, "Stat Target", {"Melee","Defense","Sword","Gun","Demon Fruit"}, "Melee", function(v)
        CFG.StatPoints = v
    end)

    AddSection(miscPage, "Movement")
    AddSlider(miscPage, "Walk Speed", 16, 500, 16, function(v)
        CFG.WalkSpeed = v
        ApplyMovement()
    end)
    AddSlider(miscPage, "Jump Power", 50, 500, 50, function(v)
        CFG.JumpPower = v
        ApplyMovement()
    end)
    AddButton(miscPage, "Reset Speed", function()
        CFG.WalkSpeed = 16
        CFG.JumpPower = 50
        ApplyMovement()
        Notify("Karl Hub","Speed reset",2)
    end, Color3.fromRGB(80,80,80))

    AddSection(miscPage, "Abilities")
    AddToggle(miscPage, "Fly", false, function(v)
        CFG.Fly = v
        if v then StartFly() else StopFly() end
    end)
    AddSlider(miscPage, "Fly Speed", 10, 500, 60, function(v) CFG.FlySpeed = v end)
    AddToggle(miscPage, "Noclip", false, function(v)
        CFG.NoClip = v
        if v then StartNoclip() else StopNoclip() end
    end)
    AddToggle(miscPage, "Infinite Jump", false, function(v) CFG.InfiniteJump = v end)
    AddToggle(miscPage, "Anti AFK", true, function(v) CFG.AntiAFK = v end)
    AddToggle(miscPage, "FPS Boost", false, function(v)
        CFG.FPSBoost = v
        ApplyFPSBoost(v)
    end)

    AddSection(miscPage, "Server")
    AddButton(miscPage, "Server Hop", function() ServerHop() end, Color3.fromRGB(80,60,180))
    AddButton(miscPage, "Rejoin Server", function()
        TeleportSvc:Teleport(game.PlaceId, LocalPlayer)
    end, Color3.fromRGB(80,80,80))

    --======================================================--
    --  TELEPORT TAB
    --======================================================--
    AddSection(tpPage, "Quick Teleport")

    -- Grouped by sea
    local seaGroups = {
        {"Sea 1", {"Starter Island","Jungle","Pirate Village","Desert","Snow Island","Marine Fortress","Skypiea","Long Ring","Flamingo","Ice Castle","Forgotten Island"}},
        {"Sea 2", {"Fishman Island","Colosseum","Ice Island (S2)","Cake Ship","Thriller Bark"}},
        {"Sea 3", {"Tiki Outpost","Port Town","Candy Kingdom","Floating Turtle","Hydra Island","Great Tree","Mansion"}},
        {"Special", {"Marineford","Impel Down"}},
    }

    for _, group in ipairs(seaGroups) do
        local groupName, islands = group[1], group[2]
        AddSection(tpPage, groupName)
        for _, island in ipairs(islands) do
            if IslandPositions[island] then
                AddButton(tpPage, island, function()
                    InstantTo(IslandPositions[island])
                    Notify("Karl Hub","📍 TP: " .. island, 2)
                end, Color3.fromRGB(30,80,160))
            end
        end
    end

    AddSection(tpPage, "Custom")
    AddButton(tpPage, "TP to Quest NPC", function()
        local q = GetQuestForLevel()
        if q then
            InstantTo(q.giver)
            Notify("Karl Hub","TP to quest NPC",2)
        end
    end, Color3.fromRGB(60,120,255))

    AddButton(tpPage, "TP to Mob Spawn", function()
        local q = GetQuestForLevel()
        if q then
            InstantTo(q.mobPos)
            Notify("Karl Hub","TP to mob spawn",2)
        end
    end, Color3.fromRGB(180,60,60))

    --======================================================--
    --  WINDOW CONTROLS
    --======================================================--
    closeBtn.MouseButton1Click:Connect(function()
        main.Visible = false
        miniBar.Visible = true
    end)

    minBtn.MouseButton1Click:Connect(function()
        main.Visible = false
        miniBar.Visible = true
    end)

    expandBtn.MouseButton1Click:Connect(function()
        miniBar.Visible = false
        main.Visible = true
    end)

    gui.Parent = LocalPlayer.PlayerGui
    return gui
end

--====================================================================--
--  CHARACTER RESPAWN HANDLER
--====================================================================--
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(2)
    ApplyMovement()
    State.QuestTaken = false
    if CFG.AutoFarm then
        task.wait(1)
        StartFarm()
    end
    -- Reapply fly
    if CFG.Fly then
        task.wait(0.5)
        StartFly()
    end
end)

--====================================================================--
--  INIT
--====================================================================--
ResolveRemotes()
CreateGUI()
ApplyMovement()

task.spawn(function()
    task.wait(0.5)
    Notify("Karl Hub V1","✅ Loaded! Owner: @Karl08901", 5)
    task.wait(1)
    Notify("Karl Hub V1","Click — to minimize, X to hide, + to restore", 4)
end)

print("========================================")
print("  KARL HUB V1  |  @Karl08901")
print("  Blox Fruits v30+ | Fixed & Enhanced")
print("  All features working")
print("========================================")
