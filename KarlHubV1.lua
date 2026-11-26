--====================================================================--
--  KARL HUB V1  |  Owner: @Karl08901  |  Game: Blox Fruits            --
--  Single-file hub. No external deps. Execute with your loader.       --
--====================================================================--

local KarlHub = {
    Name    = "Karl Hub V1",
    Owner   = "@Karl08901",
    Version = "1.0.0",
    Game    = "Blox Fruits",
    Discord = "github.com/teodorokarljazper08-dot"
}

--====================================================================--
--  SERVICES / LOCALS                                                   --
--====================================================================--
local Players        = game:GetService("Players")
local RS             = game:GetService("ReplicatedStorage")
local WS             = game:GetService("Workspace")
local RunService     = game:GetService("RunService")
local TweenService   = game:GetService("TweenService")
local VirtualInput   = game:GetService("VirtualInputManager")
local UserInput      = game:GetService("UserInputService")
local HttpService    = game:GetService("HttpService")
local StarterGui     = game:GetService("StarterGui")
local LocalPlayer    = Players.LocalPlayer

local Camera         = WS.CurrentCamera
local Mouse          = LocalPlayer:GetMouse()

--====================================================================--
--  CONFIG / STATE                                                      --
--====================================================================--
local CFG = {
    -- Auto Farm
    AutoFarm        = false,
    FarmMode        = "Level",      -- Level / Mastery / Boss / Chest
    SelectedWeapon  = "Melee",
    FarmRadius      = 40,
    FastAttack      = true,
    AutoHaki        = true,
    AutoBuso        = true,
    AutoKen         = true,
    AutoDodge       = true,
    FarmDelay       = 0.1,
    BringMob        = true,
    KillAura        = false,

    -- Fruit / Sniper
    FruitSniper     = false,
    FruitStore      = true,
    FruitESP        = true,
    FruitList       = {"Dragon","Dough","Venom","Control","Spirit","Shadow","Rumble","Paw","Gravity","Phoenix"},

    -- Boss
    AutoBoss        = false,
    SelectedBoss    = "",
    BossList        = {},

    -- Raid
    AutoRaid        = false,
    RaidChip        = false,
    AutoAwaken      = false,

    -- ESP
    PlayerESP       = false,
    MobESP          = false,
    ChestESP        = false,
    FruitESP        = false,
    IslandESP       = false,
    ESPColor        = Color3.fromRGB(255, 60, 60),

    -- Misc
    AutoStats       = false,
    StatPoints      = "Melee",
    WalkSpeed       = 16,
    JumpPower       = 50,
    InfiniteJump    = false,
    NoClip          = false,
    Fly             = false,
    FlySpeed        = 60,
    AntiAFK         = true,
    ServerHop       = false,
    AutoRejoin      = true,
    FPSBoost        = false,
    WhiteScreen     = false,

    -- Teleports
    SelectedIsland  = "",
    IslandList      = {},
}

local State = {
    Farming      = false,
    CurrentTarget= nil,
    CurrentBoss  = nil,
    Raiding      = false,
    Flying       = false,
    Noclipping   = false,
    ESPObjects   = {},
    FruitObjects = {},
    Connections  = {},
    FarmThread   = nil,
    BossThread   = nil,
    RaidThread   = nil,
    FruitThread  = nil,
    StatThread   = nil,
    HopCooldown  = 0,
    LastAttack   = 0,
}

--====================================================================--
--  HELPERS                                                             --
--====================================================================--
local function Notify(title, text, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title, Text = text, Duration = dur or 4
        })
    end)
end

local function GetChar()
    return LocalPlayer.Character
end

local function GetRoot()
    local c = GetChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function GetHum()
    local c = GetChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function GetTool()
    local c = GetChar()
    if not c then return nil end
    for _, v in pairs(c:GetChildren()) do
        if v:IsA("Tool") then return v end
    end
    return nil
end

local function EquipWeapon(name)
    local c = GetChar()
    if not c then return end
    local bp = LocalPlayer.Backpack
    if name == "Melee" or name == "Sword" or name == "Gun" or name == "Fruit" then
        -- auto-pick best of that type
        local best, bestDmg = nil, -1
        for _, v in pairs(bp:GetChildren()) do
            if v:IsA("Tool") then
                local t = v.ToolTip
                if t == name then
                    local d = v:FindFirstChild("Damage") and v.Damage.Value or 0
                    if d > bestDmg then best, bestDmg = v, d end
                end
            end
        end
        if best then
            c.Humanoid:EquipTool(best)
        end
    else
        local t = bp:FindFirstChild(name)
        if t then c.Humanoid:EquipTool(t) end
    end
end

local function DistanceTo(pos)
    local r = GetRoot()
    if not r then return math.huge end
    return (r.Position - pos).Magnitude
end

local function TweenTo(pos, speed)
    local r = GetRoot()
    if not r then return end
    local dist = DistanceTo(pos)
    local time = dist / (speed or 250)
    local tween = TweenService:Create(r, TweenInfo.new(time, Enum.EasingStyle.Linear), {CFrame = CFrame.new(pos)})
    tween:Play()
    return tween
end

local function InstantTo(pos)
    local r = GetRoot()
    if r then r.CFrame = CFrame.new(pos) end
end

local function IsAlive(mob)
    local h = mob:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0
end

local function GetLevel()
    local lvl = LocalPlayer.Data:FindFirstChild("Level")
    return lvl and lvl.Value or 1
end

--====================================================================--
--  REMOTES (cached, resolved lazily)                                   --
--====================================================================--
local Remotes = {}
local function GetRemote(name)
    if Remotes[name] then return Remotes[name] end
    local r = RS:FindFirstChild(name, true) or RS.Remotes:FindFirstChild(name, true)
    Remotes[name] = r
    return r
end

-- Common Blox Fruits remotes (names shift between updates, we scan)
local function ResolveRemotes()
    local candidates = {
        "CheckQuest", "Quest", "TakeQuest",
        "Attack", "UseSkill", "EquipWeapon",
        "Haki", "Buso", "Ken",
        "Awaken", "Awakening",
        "BuyFruit", "StoreFruit",
        "Raid", "StartRaid", "Chip",
        "StatPoint", "AddPoint",
        "Teleport", "TP"
    }
    for _, n in pairs(candidates) do
        Remotes[n] = RS:FindFirstChild(n, true)
    end
    -- deep scan for anything with "Remote" in name under ReplicatedStorage
    for _, v in pairs(RS:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            local ln = v.Name:lower()
            if ln:find("quest") and not Remotes.Quest then Remotes.Quest = v end
            if ln:find("attack") and not Remotes.Attack then Remotes.Attack = v end
            if ln:find("haki") and not Remotes.Haki then Remotes.Haki = v end
            if ln:find("stat") and not Remotes.Stat then Remotes.Stat = v end
            if ln:find("awaken") and not Remotes.Awaken then Remotes.Awaken = v end
        end
    end
end
ResolveRemotes()

--====================================================================--
--  HAKI / BUFFS                                                        --
--====================================================================--
local function EnableHaki()
    if not CFG.AutoHaki then return end
    local c = GetChar()
    if not c then return end
    -- Buso / Armament
    if CFG.AutoBuso then
        local buso = c:FindFirstChild("HasBuso")
        if not buso or buso.Value == false then
            pcall(function()
                if Remotes.Haki then Remotes.Haki:FireServer("Buso") end
            end)
        end
    end
    -- Ken / Observation
    if CFG.AutoKen then
        pcall(function()
            if Remotes.Haki then Remotes.Haki:FireServer("Ken") end
        end)
    end
end

--====================================================================--
--  QUEST / LEVEL LOGIC                                                 --
--====================================================================--
local QuestData = {
    -- [level bracket] = {mobName, questGiverPos, mobPos, island}
    {min=1,   max=9,   mob="Bandit",        giver=Vector3.new(1060, 16, 1547),   mobPos=Vector3.new(1140, 16, 1600),   island="Starter"},
    {min=10,  max=14,  mob="Monkey",         giver=Vector3.new(-1590, 36, 140),   mobPos=Vector3.new(-1600, 36, 150),   island="Jungle"},
    {min=15,  max=29,  mob="Gorilla",        giver=Vector3.new(-1590, 36, 140),   mobPos=Vector3.new(-1700, 50, 200),   island="Jungle"},
    {min=30,  max=59,  mob="Pirate",         giver=Vector3.new(-1230, 4, 330),    mobPos=Vector3.new(-1200, 4, 400),    island="Pirate Village"},
    {min=60,  max=89,  mob="Desert Bandit",  giver=Vector3.new(930, 7, 4480),     mobPos=Vector3.new(1000, 10, 4500),   island="Desert"},
    {min=90,  max=119, mob="Snow Bandit",    giver=Vector3.new(1360, 400, -5200), mobPos=Vector3.new(1400, 400, -5100), island="Snow Island"},
    {min=120, max=149, mob="Yeti",           giver=Vector3.new(1360, 400, -5200), mobPos=Vector3.new(1500, 400, -5300), island="Snow Island"},
    {min=150, max=189, mob="Military Soldier",giver=Vector3.new(-4800, 850, -2900),mobPos=Vector3.new(-4900, 850, -2800),island="Marine Fortress"},
    {min=190, max=249, mob="Military Spy",   giver=Vector3.new(-4800, 850, -2900),mobPos=Vector3.new(-5000, 850, -3000), island="Marine Fortress"},
    {min=250, max=299, mob="God's Guard",    giver=Vector3.new(-4700, 850, -1900),mobPos=Vector3.new(-4800, 850, -1800), island="Skypiea"},
    {min=300, max=374, mob="Shanda",         giver=Vector3.new(-4700, 850, -1900),mobPos=Vector3.new(-4900, 850, -1700), island="Skypiea"},
    {min=375, max=449, mob="Galley Pirate",  giver=Vector3.new(250, 10, 2000),    mobPos=Vector3.new(300, 10, 2100),    island="Long Ring"},
    {min=450, max=524, mob="Galley Captain", giver=Vector3.new(250, 10, 2000),    mobPos=Vector3.new(350, 10, 2200),    island="Long Ring"},
    {min=525, max=649, mob="Raider",         giver=Vector3.new(-6000, 300, -5000),mobPos=Vector3.new(-6100, 300, -4900),island="Flamingo"},
    {min=650, max=749, mob="Mercenary",      giver=Vector3.new(-6000, 300, -5000),mobPos=Vector3.new(-6200, 300, -5100),island="Flamingo"},
    {min=750, max=874, mob="Pirate Millionaire",giver=Vector3.new(-200, 400, 7000),mobPos=Vector3.new(-300, 400, 7100),  island="Ice Castle"},
    {min=875, max=999, mob="Pistol Billionaire",giver=Vector3.new(-200, 400, 7000),mobPos=Vector3.new(-400, 400, 7200),island="Ice Castle"},
    {min=1000,max=1124,mob="Stone Raider",   giver=Vector3.new(500, 600, -6000),  mobPos=Vector3.new(600, 600, -6100),  island="Forgotten Island"},
    {min=1125,max=1249,mob="Cyborg",         giver=Vector3.new(500, 600, -6000),  mobPos=Vector3.new(700, 600, -6200),  island="Forgotten Island"},
    {min=1250,max=1499,mob="Fishman Warrior",giver=Vector3.new(6000, 300, 2000),  mobPos=Vector3.new(6100, 300, 2100),  island="Fishman Island"},
    {min=1500,max=1749,mob="Fishman Captain",giver=Vector3.new(6000, 300, 2000), mobPos=Vector3.new(6200, 300, 2200),  island="Fishman Island"},
    {min=1750,max=1999,mob="Forest Pirate",  giver=Vector3.new(-5000, 400, 5000), mobPos=Vector3.new(-5100, 400, 5100), island="Green Zone"},
    {min=2000,max=2249,mob="Mythological Pirate",giver=Vector3.new(-5000, 400, 5000),mobPos=Vector3.new(-5200, 400, 5200),island="Green Zone"},
    {min=2250,max=2499,mob="Jungle Giant",   giver=Vector3.new(1000, 500, 8000),  mobPos=Vector3.new(1100, 500, 8100),  island="Jungle Island"},
    {min=2500,max=2749,mob="Sunflower",      giver=Vector3.new(1000, 500, 8000),  mobPos=Vector3.new(1200, 500, 8200),  island="Jungle Island"},
    {min=2750,max=2999,mob="Cocoa Warrior",  giver=Vector3.new(-8000, 400, -2000),mobPos=Vector3.new(-8100, 400, -1900),island="Chocolate Island"},
    {min=3000,max=3249,mob="Chocolate Bar Battler",giver=Vector3.new(-8000, 400, -2000),mobPos=Vector3.new(-8200, 400, -1800),island="Chocolate Island"},
    {min=3250,max=3499,mob="Sweet Thief",    giver=Vector3.new(9000, 400, 3000),  mobPos=Vector3.new(9100, 400, 3100),  island="Candy Island"},
    {min=3500,max=3749,mob="Candy Rebel",    giver=Vector3.new(9000, 400, 3000),  mobPos=Vector3.new(9200, 400, 3200),  island="Candy Island"},
    {min=3750,max=3999,mob="Candy Pirate",   giver=Vector3.new(9000, 400, 3000),  mobPos=Vector3.new(9300, 400, 3300),  island="Candy Island"},
    {min=4000,max=4249,mob="Snow Demon",     giver=Vector3.new(8000, 500, -8000), mobPos=Vector3.new(8100, 500, -7900), island="Snow Mountain"},
    {min=4250,max=4499,mob="Frost Guard",    giver=Vector3.new(8000, 500, -8000), mobPos=Vector3.new(8200, 500, -7800), island="Snow Mountain"},
    {min=4500,max=4749,mob="Awakened Ice Monster",giver=Vector3.new(8000,500,-8000),mobPos=Vector3.new(8300, 500, -7700),island="Snow Mountain"},
    {min=4750,max=4999,mob="Lava Creature",  giver=Vector3.new(-9000, 400, 9000), mobPos=Vector3.new(-9100, 400, 9100), island="Lava Island"},
    {min=5000,max=5249,mob="Lava Monster",   giver=Vector3.new(-9000, 400, 9000), mobPos=Vector3.new(-9200, 400, 9200), island="Lava Island"},
    {min=5250,max=5499,mob="Magma Golem",    giver=Vector3.new(-9000, 400, 9000), mobPos=Vector3.new(-9300, 400, 9300), island="Lava Island"},
    {min=5500,max=5749,mob="Thunder Warrior",giver=Vector3.new(10000, 600, 10000),mobPos=Vector3.new(10100, 600, 10100),island="Thunder Island"},
    {min=5750,max=5999,mob="Thunder God",    giver=Vector3.new(10000, 600, 10000),mobPos=Vector3.new(10200, 600, 10200),island="Thunder Island"},
    {min=6000,max=6249,mob="Sky Knight",     giver=Vector3.new(0, 1000, 0),     mobPos=Vector3.new(100, 1000, 100),   island="Sky Island"},
    {min=6250,max=6499,mob="Cloud Warrior",  giver=Vector3.new(0, 1000, 0),     mobPos=Vector3.new(200, 1000, 200),   island="Sky Island"},
    {min=6500,max=6749,mob="Angel",          giver=Vector3.new(0, 1000, 0),     mobPos=Vector3.new(300, 1000, 300),   island="Sky Island"},
    {min=6750,max=6999,mob="Demon",          giver=Vector3.new(0, -1000, 0),    mobPos=Vector3.new(100, -1000, 100),  island="Underworld"},
    {min=7000,max=7249,mob="Shadow Beast",   giver=Vector3.new(0, -1000, 0),    mobPos=Vector3.new(200, -1000, 200),  island="Underworld"},
    {min=7250,max=7499,mob="Dark Knight",    giver=Vector3.new(0, -1000, 0),    mobPos=Vector3.new(300, -1000, 300),  island="Underworld"},
    {min=7500,max=99999,mob="Sea Beast",     giver=Vector3.new(0, 0, 0),        mobPos=Vector3.new(0, 0, 0),          island="Sea"},
}

local function GetQuestForLevel()
    local lvl = GetLevel()
    for _, q in pairs(QuestData) do
        if lvl >= q.min and lvl <= q.max then
            return q
        end
    end
    return QuestData[#QuestData]
end

local function GetMobSpawn(mobName)
    local spawns = WS:FindFirstChild("MobSpawns")
    if not spawns then return nil end
    for _, v in pairs(spawns:GetChildren()) do
        if v.Name:lower():find(mobName:lower()) then
            return v
        end
    end
    -- fallback: scan Enemies
    local enemies = WS:FindFirstChild("Enemies")
    if enemies then
        for _, v in pairs(enemies:GetChildren()) do
            if v.Name:lower():find(mobName:lower()) then
                return v
            end
        end
    end
    return nil
end

--====================================================================--
--  ATTACK LOGIC                                                        --
--====================================================================--
local function DoAttack(target)
    if not CFG.FastAttack then return end
    local now = tick()
    if now - State.LastAttack < CFG.FarmDelay then return end
    State.LastAttack = now

    local tool = GetTool()
    if not tool then
        EquipWeapon(CFG.SelectedWeapon)
        return
    end

    -- Click / use tool
    pcall(function()
        tool:Activate()
    end)

    -- Fire remote attack if available
    if Remotes.Attack then
        pcall(function()
            Remotes.Attack:FireServer(target)
        end)
    end

    -- Virtual click fallback
    pcall(function()
        VirtualInput:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        VirtualInput:SendMouseButtonEvent(0, 0, 0, false, game, 0)
    end)
end

--====================================================================--
--  AUTO FARM CORE                                                      --
--====================================================================--
local function GetClosestMob(mobName, maxDist)
    local enemies = WS:FindFirstChild("Enemies")
    if not enemies then return nil end
    local closest, dist = nil, maxDist or math.huge
    local root = GetRoot()
    if not root then return nil end
    for _, v in pairs(enemies:GetChildren()) do
        if v.Name:lower():find(mobName:lower()) and IsAlive(v) then
            local hrp = v:FindFirstChild("HumanoidRootPart")
            if hrp then
                local d = (hrp.Position - root.Position).Magnitude
                if d < dist then
                    closest = v
                    dist = d
                end
            end
        end
    end
    return closest
end

local function GetClosestBoss()
    local enemies = WS:FindFirstChild("Enemies")
    if not enemies then return nil end
    local root = GetRoot()
    if not root then return nil end
    local closest, dist = nil, math.huge
    for _, v in pairs(enemies:GetChildren()) do
        local h = v:FindFirstChildOfClass("Humanoid")
        if h and h.Health > 0 and h.MaxHealth > 50000 then
            local hrp = v:FindFirstChild("HumanoidRootPart")
            if hrp then
                local d = (hrp.Position - root.Position).Magnitude
                if d < dist then
                    closest = v
                    dist = d
                end
            end
        end
    end
    return closest
end

local function FarmLoop()
    while CFG.AutoFarm do
        local ok, err = pcall(function()
            EnableHaki()

            local quest = GetQuestForLevel()
            local target = nil

            if CFG.FarmMode == "Boss" then
                target = GetClosestBoss()
                if target then
                    local hrp = target:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        if CFG.BringMob then
                            InstantTo(hrp.Position + Vector3.new(0, 8, 0))
                        else
                            TweenTo(hrp.Position + Vector3.new(0, 8, 0), 300)
                        end
                        DoAttack(target)
                    end
                end
            elseif CFG.FarmMode == "Mastery" then
                -- farm with fruit, low hp mobs
                EquipWeapon("Fruit")
                target = GetClosestMob("", CFG.FarmRadius)
                if target then
                    local hrp = target:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        InstantTo(hrp.Position + Vector3.new(0, 10, 0))
                        DoAttack(target)
                    end
                end
            else -- Level
                target = GetClosestMob(quest.mob, 200)
                if target then
                    local hrp = target:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        if CFG.BringMob then
                            -- bring mob to us
                            local root = GetRoot()
                            if root then
                                hrp.CFrame = root.CFrame * CFrame.new(0, 0, -5)
                            end
                        else
                            TweenTo(hrp.Position + Vector3.new(0, 8, 0), 300)
                        end
                        DoAttack(target)
                    end
                else
                    -- teleport to mob spawn
                    if quest.mobPos then
                        TweenTo(quest.mobPos, 300)
                    end
                end
            end

            -- kill aura
            if CFG.KillAura then
                local enemies = WS:FindFirstChild("Enemies")
                if enemies then
                    for _, v in pairs(enemies:GetChildren()) do
                        if IsAlive(v) then
                            local hrp = v:FindFirstChild("HumanoidRootPart")
                            local root = GetRoot()
                            if hrp and root and (hrp.Position - root.Position).Magnitude < 30 then
                                DoAttack(v)
                            end
                        end
                    end
                end
            end
        end)
        if not ok then
            warn("[KarlHub] Farm error: " .. tostring(err))
        end
        RunService.Heartbeat:Wait()
    end
    State.Farming = false
end

local function StartFarm()
    if State.FarmThread then return end
    State.Farming = true
    State.FarmThread = task.spawn(FarmLoop)
end

local function StopFarm()
    State.Farming = false
    State.FarmThread = nil
end

--====================================================================--
--  FRUIT SNIPER                                                        --
--======================================================================
local function ScanFruits()
    local found = {}
    for _, v in pairs(WS:GetDescendants()) do
        if v:IsA("Tool") and v.Name:find("Fruit") then
            table.insert(found, v)
        end
    end
    local fruits = WS:FindFirstChild("Fruits")
    if fruits then
        for _, v in pairs(fruits:GetChildren()) do
            table.insert(found, v)
        end
    end
    return found
end

local function FruitLoop()
    while CFG.FruitSniper do
        pcall(function()
            local fruits = ScanFruits()
            for _, fruit in pairs(fruits) do
                local handle = fruit:FindFirstChild("Handle") or fruit:FindFirstChildOfClass("Part")
                if handle then
                    local root = GetRoot()
                    if root then
                        local d = (handle.Position - root.Position).Magnitude
                        if d < 200 then
                            InstantTo(handle.Position)
                            if CFG.FruitStore then
                                pcall(function()
                                    if Remotes.StoreFruit then
                                        Remotes.StoreFruit:FireServer(fruit.Name)
                                    end
                                end)
                            end
                            Notify("Karl Hub", "Got fruit: " .. fruit.Name, 3)
                        end
                    end
                end
            end
        end)
        task.wait(0.5)
    end
end

local function StartFruitSniper()
    if State.FruitThread then return end
    State.FruitThread = task.spawn(FruitLoop)
end

local function StopFruitSniper()
    if State.FruitThread then
        task.cancel(State.FruitThread)
        State.FruitThread = nil
    end
end

--====================================================================--
--  RAID                                                                --
--====================================================================--
local function RaidLoop()
    while CFG.AutoRaid do
        pcall(function()
            -- buy chip if needed
            if CFG.RaidChip then
                pcall(function()
                    if Remotes.Raid then Remotes.Raid:FireServer("BuyChip") end
                end)
            end
            -- start raid
            pcall(function()
                if Remotes.Raid then Remotes.Raid:FireServer("StartRaid") end
            end)
            -- farm raid enemies
            local enemies = WS:FindFirstChild("Enemies")
            if enemies then
                for _, v in pairs(enemies:GetChildren()) do
                    if IsAlive(v) then
                        local hrp = v:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            InstantTo(hrp.Position + Vector3.new(0, 10, 0))
                            DoAttack(v)
                        end
                    end
                end
            end
            -- awaken
            if CFG.AutoAwaken then
                pcall(function()
                    if Remotes.Awaken then Remotes.Awaken:FireServer("Awaken") end
                end)
            end
        end)
        RunService.Heartbeat:Wait()
    end
end

local function StartRaid()
    if State.RaidThread then return end
    State.RaidThread = task.spawn(RaidLoop)
end

local function StopRaid()
    if State.RaidThread then
        task.cancel(State.RaidThread)
        State.RaidThread = nil
    end
end

--====================================================================--
--  AUTO STATS                                                          --
--====================================================================--
local function StatLoop()
    while CFG.AutoStats do
        pcall(function()
            if Remotes.Stat then
                Remotes.Stat:FireServer("AddPoint", CFG.StatPoints, 1)
            end
        end)
        task.wait(0.5)
    end
end

local function StartStats()
    if State.StatThread then return end
    State.StatThread = task.spawn(StatLoop)
end

local function StopStats()
    if State.StatThread then
        task.cancel(State.StatThread)
        State.StatThread = nil
    end
end

--====================================================================--
--  ESP                                                                 --
--====================================================================--
local function CreateESP(obj, color, text)
    if not obj then return end
    local hrp = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Handle") or obj:FindFirstChildOfClass("Part")
    if not hrp then return end

    local bill = Instance.new("BillboardGui")
    bill.Name = "KarlESP"
    bill.Adornee = hrp
    bill.Size = UDim2.new(0, 100, 0, 40)
    bill.StudsOffset = Vector3.new(0, 3, 0)
    bill.AlwaysOnTop = true

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = color or CFG.ESPColor
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.Text = text or obj.Name
    label.Parent = bill

    bill.Parent = hrp
    table.insert(State.ESPObjects, bill)
end

local function ClearESP()
    for _, v in pairs(State.ESPObjects) do
        pcall(function() v:Destroy() end)
    end
    State.ESPObjects = {}
end

local function UpdateESP()
    ClearESP()
    if CFG.PlayerESP then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                CreateESP(p.Character, Color3.fromRGB(60, 255, 60), p.Name .. " [" .. tostring(p.Data.Level.Value) .. "]")
            end
        end
    end
    if CFG.MobESP then
        local enemies = WS:FindFirstChild("Enemies")
        if enemies then
            for _, v in pairs(enemies:GetChildren()) do
                if IsAlive(v) then
                    CreateESP(v, Color3.fromRGB(255, 60, 60), v.Name)
                end
            end
        end
    end
    if CFG.FruitESP then
        for _, fruit in pairs(ScanFruits()) do
            CreateESP(fruit, Color3.fromRGB(255, 255, 60), fruit.Name)
        end
    end
    if CFG.ChestESP then
        for _, v in pairs(WS:GetDescendants()) do
            if v.Name:lower():find("chest") then
                CreateESP(v, Color3.fromRGB(255, 200, 60), v.Name)
            end
        end
    end
end

--====================================================================--
--  MOVEMENT / MISC                                                     --
--====================================================================--
local function ApplyMovement()
    local hum = GetHum()
    if hum then
        hum.WalkSpeed = CFG.WalkSpeed
        hum.JumpPower = CFG.JumpPower
    end
end

local function StartFly()
    if State.Flying then return end
    State.Flying = true
    local root = GetRoot()
    if not root then return end
    local bodyGyro = Instance.new("BodyGyro")
    bodyGyro.P = 9e4
    bodyGyro.maxTorque = Vector3.new(9e9, 9e9, 9e9)
    bodyGyro.CFrame = root.CFrame
    bodyGyro.Parent = root
    local bodyVel = Instance.new("BodyVelocity")
    bodyVel.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bodyVel.Velocity = Vector3.new(0, 0, 0)
    bodyVel.Parent = root

    State.FlyGyro = bodyGyro
    State.FlyVel = bodyVel

    task.spawn(function()
        while State.Flying do
            local dir = Vector3.new(0, 0, 0)
            if UserInput:IsKeyDown(Enum.KeyCode.W) then dir = dir + Camera.CFrame.LookVector end
            if UserInput:IsKeyDown(Enum.KeyCode.S) then dir = dir - Camera.CFrame.LookVector end
            if UserInput:IsKeyDown(Enum.KeyCode.A) then dir = dir - Camera.CFrame.RightVector end
            if UserInput:IsKeyDown(Enum.KeyCode.D) then dir = dir + Camera.CFrame.RightVector end
            if UserInput:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
            if UserInput:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0, 1, 0) end
            bodyVel.Velocity = dir * CFG.FlySpeed
            bodyGyro.CFrame = Camera.CFrame
            RunService.Heartbeat:Wait()
        end
        bodyGyro:Destroy()
        bodyVel:Destroy()
    end)
end

local function StopFly()
    State.Flying = false
end

local function StartNoclip()
    if State.Noclipping then return end
    State.Noclipping = true
    State.NoclipConn = RunService.Stepped:Connect(function()
        local c = GetChar()
        if c then
            for _, v in pairs(c:GetDescendants()) do
                if v:IsA("BasePart") then
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
end

-- Anti AFK
LocalPlayer.Idled:Connect(function()
    if CFG.AntiAFK then
        VirtualInput:SendKeyEvent(true, Enum.KeyCode.W, false, game)
        task.wait(0.1)
        VirtualInput:SendKeyEvent(false, Enum.KeyCode.W, false, game)
    end
end)

-- FPS boost
local function ApplyFPSBoost()
    if CFG.FPSBoost then
        for _, v in pairs(WS:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") then
                v.Enabled = false
            end
            if v:IsA("Decal") or v:IsA("Texture") then
                v.Transparency = 1
            end
        end
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    end
end

-- White screen
local function ApplyWhiteScreen()
    local gui = LocalPlayer.PlayerGui:FindFirstChild("KarlWhiteScreen")
    if CFG.WhiteScreen then
        if not gui then
            gui = Instance.new("ScreenGui")
            gui.Name = "KarlWhiteScreen"
            gui.ResetOnSpawn = false
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 1, 0)
            frame.BackgroundColor3 = Color3.new(1, 1, 1)
            frame.BorderSizePixel = 0
            frame.Parent = gui
            gui.Parent = LocalPlayer.PlayerGui
        end
    else
        if gui then gui:Destroy() end
    end
end

--====================================================================--
--  SERVER HOP                                                          --
--====================================================================--
local function ServerHop()
    if tick() - State.HopCooldown < 10 then return end
    State.HopCooldown = tick()
    local servers = {}
    local req = game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
    local data = HttpService:JSONDecode(req)
    for _, v in pairs(data.data) do
        if v.playing < v.maxPlayers and v.id ~= game.JobId then
            table.insert(servers, v.id)
        end
    end
    if #servers > 0 then
        game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)], LocalPlayer)
    end
end

--====================================================================--
--  GUI                                                                 --
--====================================================================--
local function CreateGUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "KarlHubV1"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Main frame
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, 520, 0, 420)
    main.Position = UDim2.new(0.5, -260, 0.5, -210)
    main.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    main.BorderSizePixel = 0
    main.Active = true
    main.Draggable = true
    main.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = main

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 60, 60)
    stroke.Thickness = 2
    stroke.Parent = main

    -- Title bar
    local title = Instance.new("Frame")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    title.BorderSizePixel = 0
    title.Parent = main

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = title

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -50, 1, 0)
    titleLabel.Position = UDim2.new(0, 15, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3 = Color3.fromRGB(255, 60, 60)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 18
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Text = "KARL HUB V1  |  @Karl08901"
    titleLabel.Parent = title

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 40, 0, 40)
    closeBtn.Position = UDim2.new(1, -40, 0, 0)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
    closeBtn.BorderSizePixel = 0
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 18
    closeBtn.Text = "X"
    closeBtn.Parent = title

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeBtn

    -- Tab bar
    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(0, 120, 1, -40)
    tabBar.Position = UDim2.new(0, 0, 0, 40)
    tabBar.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    tabBar.BorderSizePixel = 0
    tabBar.Parent = main

    local tabList = Instance.new("UIListLayout")
    tabList.Padding = UDim.new(0, 2)
    tabList.Parent = tabBar

    local pages = Instance.new("Frame")
    pages.Size = UDim2.new(1, -120, 1, -40)
    pages.Position = UDim2.new(0, 120, 0, 40)
    pages.BackgroundTransparency = 1
    pages.Parent = main

    local tabs = {}
    local pagesList = {}

    local function AddTab(name)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 36)
        btn.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
        btn.BorderSizePixel = 0
        btn.TextColor3 = Color3.fromRGB(200, 200, 200)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 13
        btn.Text = name
        btn.Parent = tabBar

        local page = Instance.new("ScrollingFrame")
        page.Size = UDim2.new(1, 0, 1, 0)
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.ScrollBarThickness = 4
        page.Visible = false
        page.Parent = pages

        local list = Instance.new("UIListLayout")
        list.Padding = UDim.new(0, 4)
        list.Parent = page

        table.insert(tabs, btn)
        table.insert(pagesList, page)

        btn.MouseButton1Click:Connect(function()
            for _, b in pairs(tabs) do
                b.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
                b.TextColor3 = Color3.fromRGB(200, 200, 200)
            end
            for _, p in pairs(pagesList) do
                p.Visible = false
            end
            btn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
            btn.TextColor3 = Color3.new(1, 1, 1)
            page.Visible = true
        end)

        return page
    end

    local farmPage   = AddTab("Auto Farm")
    local fruitPage  = AddTab("Fruit Sniper")
    local bossPage   = AddTab("Boss / Raid")
    local espPage    = AddTab("ESP")
    local miscPage   = AddTab("Misc")
    local tpPage     = AddTab("Teleport")

    -- select first tab
    tabs[1].BackgroundColor3 = Color3.fromRGB(255, 60, 60)
    tabs[1].TextColor3 = Color3.new(1, 1, 1)
    pagesList[1].Visible = true

    --==== UI ELEMENT BUILDERS ====--
    local function AddToggle(page, text, default, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -10, 0, 32)
        btn.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
        btn.BorderSizePixel = 0
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 13
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Text = "  " .. text
        btn.Parent = page

        local state = default or false
        local indicator = Instance.new("Frame")
        indicator.Size = UDim2.new(0, 40, 0, 20)
        indicator.Position = UDim2.new(1, -50, 0.5, -10)
        indicator.BackgroundColor3 = state and Color3.fromRGB(60, 255, 60) or Color3.fromRGB(80, 80, 80)
        indicator.BorderSizePixel = 0
        indicator.Parent = btn

        local indCorner = Instance.new("UICorner")
        indCorner.CornerRadius = UDim.new(0, 10)
        indCorner.Parent = indicator

        btn.MouseButton1Click:Connect(function()
            state = not state
            indicator.BackgroundColor3 = state and Color3.fromRGB(60, 255, 60) or Color3.fromRGB(80, 80, 80)
            callback(state)
        end)

        return btn
    end

    local function AddDropdown(page, text, options, default, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, -10, 0, 56)
        frame.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
        frame.BorderSizePixel = 0
        frame.Parent = page

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 0, 20)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.fromRGB(180, 180, 180)
        label.Font = Enum.Font.Gotham
        label.TextSize = 12
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Text = "  " .. text
        label.Parent = frame

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -10, 0, 28)
        btn.Position = UDim2.new(0, 5, 0, 24)
        btn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        btn.BorderSizePixel = 0
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 12
        btn.Text = default or options[1]
        btn.Parent = frame

        local open = false
        local dropFrame = nil

        btn.MouseButton1Click:Connect(function()
            if open then
                if dropFrame then dropFrame:Destroy() dropFrame = nil end
                open = false
                return
            end
            open = true
            dropFrame = Instance.new("Frame")
            dropFrame.Size = UDim2.new(1, 0, 0, #options * 24)
            dropFrame.Position = UDim2.new(0, 0, 1, 2)
            dropFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
            dropFrame.BorderSizePixel = 0
            dropFrame.ZIndex = 10
            dropFrame.Parent = btn

            for i, opt in pairs(options) do
                local optBtn = Instance.new("TextButton")
                optBtn.Size = UDim2.new(1, 0, 0, 24)
                optBtn.Position = UDim2.new(0, 0, 0, (i-1)*24)
                optBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
                optBtn.BorderSizePixel = 0
                optBtn.TextColor3 = Color3.new(1, 1, 1)
                optBtn.Font = Enum.Font.Gotham
                optBtn.TextSize = 11
                optBtn.Text = opt
                optBtn.ZIndex = 11
                optBtn.Parent = dropFrame

                optBtn.MouseButton1Click:Connect(function()
                    btn.Text = opt
                    callback(opt)
                    dropFrame:Destroy()
                    dropFrame = nil
                    open = false
                end)
            end
        end)

        return frame
    end

    local function AddSlider(page, text, min, max, default, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, -10, 0, 56)
        frame.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
        frame.BorderSizePixel = 0
        frame.Parent = page

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 0, 20)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.fromRGB(180, 180, 180)
        label.Font = Enum.Font.Gotham
        label.TextSize = 12
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Text = "  " .. text .. ": " .. tostring(default)
        label.Parent = frame

        local slider = Instance.new("Frame")
        slider.Size = UDim2.new(1, -20, 0, 6)
        slider.Position = UDim2.new(0, 10, 0, 32)
        slider.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        slider.BorderSizePixel = 0
        slider.Parent = frame

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
        fill.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
        fill.BorderSizePixel = 0
        fill.Parent = slider

        local dragging = false
        local function Update(input)
            local rel = math.clamp((input.Position.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
            local val = math.floor(min + rel * (max - min))
            fill.Size = UDim2.new(rel, 0, 1, 0)
            label.Text = "  " .. text .. ": " .. tostring(val)
            callback(val)
        end

        slider.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
            end
        end)
        slider.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
        UserInput.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                Update(input)
            end
        end)

        return frame
    end

    local function AddButton(page, text, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -10, 0, 32)
        btn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
        btn.BorderSizePixel = 0
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 13
        btn.Text = text
        btn.Parent = page

        btn.MouseButton1Click:Connect(callback)
        return btn
    end

    --==== FARM TAB ====--
    AddToggle(farmPage, "Auto Farm", false, function(v)
        CFG.AutoFarm = v
        if v then StartFarm() else StopFarm() end
    end)

    AddDropdown(farmPage, "Farm Mode", {"Level", "Mastery", "Boss", "Chest"}, "Level", function(v)
        CFG.FarmMode = v
    end)

    AddDropdown(farmPage, "Weapon", {"Melee", "Sword", "Gun", "Fruit"}, "Melee", function(v)
        CFG.SelectedWeapon = v
    end)

    AddToggle(farmPage, "Fast Attack", true, function(v) CFG.FastAttack = v end)
    AddToggle(farmPage, "Auto Haki", true, function(v) CFG.AutoHaki = v end)
    AddToggle(farmPage, "Auto Buso", true, function(v) CFG.AutoBuso = v end)
    AddToggle(farmPage, "Auto Ken", true, function(v) CFG.AutoKen = v end)
    AddToggle(farmPage, "Bring Mob", true, function(v) CFG.BringMob = v end)
    AddToggle(farmPage, "Kill Aura", false, function(v) CFG.KillAura = v end)
    AddToggle(farmPage, "Auto Dodge", true, function(v) CFG.AutoDodge = v end)

    AddSlider(farmPage, "Farm Delay (ms)", 0, 500, 100, function(v)
        CFG.FarmDelay = v / 1000
    end)

    --==== FRUIT TAB ====--
    AddToggle(fruitPage, "Fruit Sniper", false, function(v)
        CFG.FruitSniper = v
        if v then StartFruitSniper() else StopFruitSniper() end
    end)
    AddToggle(fruitPage, "Auto Store Fruit", true, function(v) CFG.FruitStore = v end)
    AddToggle(fruitPage, "Fruit ESP", false, function(v) CFG.FruitESP = v UpdateESP() end)

    local fruitNames = {"Dragon","Dough","Venom","Control","Spirit","Shadow","Rumble","Paw","Gravity","Phoenix","Magma","Ice","Dark","Light","Quake","String","Barrier","Rubber","Chop","Spring","Kilo","Spin","Bomb","Smoke","Flame","Falcon","Sand","Diamond","Ghost","Portal","Buddha","Love","Spider","Sound"}
    AddDropdown(fruitPage, "Target Fruit", fruitNames, "Dragon", function(v)
        CFG.TargetFruit = v
    end)

    --==== BOSS / RAID TAB ====--
    AddToggle(bossPage, "Auto Boss", false, function(v)
        CFG.AutoBoss = v
        CFG.FarmMode = v and "Boss" or "Level"
        if v and not CFG.AutoFarm then
            CFG.AutoFarm = true
            StartFarm()
        end
    end)

    AddToggle(bossPage, "Auto Raid", false, function(v)
        CFG.AutoRaid = v
        if v then StartRaid() else StopRaid() end
    end)
    AddToggle(bossPage, "Auto Buy Chip", false, function(v) CFG.RaidChip = v end)
    AddToggle(bossPage, "Auto Awaken", false, function(v) CFG.AutoAwaken = v end)

    --==== ESP TAB ====--
    AddToggle(espPage, "Player ESP", false, function(v) CFG.PlayerESP = v UpdateESP() end)
    AddToggle(espPage, "Mob ESP", false, function(v) CFG.MobESP = v UpdateESP() end)
    AddToggle(espPage, "Fruit ESP", false, function(v) CFG.FruitESP = v UpdateESP() end)
    AddToggle(espPage, "Chest ESP", false, function(v) CFG.ChestESP = v UpdateESP() end)

    --==== MISC TAB ====--
    AddToggle(miscPage, "Auto Stats", false, function(v)
        CFG.AutoStats = v
        if v then StartStats() else StopStats() end
    end)
    AddDropdown(miscPage, "Stat", {"Melee", "Defense", "Sword", "Gun", "Demon Fruit"}, "Melee", function(v)
        CFG.StatPoints = v
    end)

    AddSlider(miscPage, "Walk Speed", 16, 500, 16, function(v)
        CFG.WalkSpeed = v
        ApplyMovement()
    end)
    AddSlider(miscPage, "Jump Power", 50, 500, 50, function(v)
        CFG.JumpPower = v
        ApplyMovement()
    end)

    AddToggle(miscPage, "Fly", false, function(v)
        CFG.Fly = v
        if v then StartFly() else StopFly() end
    end)
    AddSlider(miscPage, "Fly Speed", 30, 500, 60, function(v) CFG.FlySpeed = v end)

    AddToggle(miscPage, "Noclip", false, function(v)
        CFG.NoClip = v
        if v then StartNoclip() else StopNoclip() end
    end)
    AddToggle(miscPage, "Infinite Jump", false, function(v) CFG.InfiniteJump = v end)
    AddToggle(miscPage, "Anti AFK", true, function(v) CFG.AntiAFK = v end)
    AddToggle(miscPage, "FPS Boost", false, function(v) CFG.FPSBoost = v ApplyFPSBoost() end)
    AddToggle(miscPage, "White Screen", false, function(v) CFG.WhiteScreen = v ApplyWhiteScreen() end)
    AddToggle(miscPage, "Auto Rejoin", true, function(v) CFG.AutoRejoin = v end)

    AddButton(miscPage, "Server Hop", function() ServerHop() end)

    --==== TELEPORT TAB ====--
    local islands = {"Starter Island", "Jungle", "Pirate Village", "Desert", "Snow Island", "Marine Fortress", "Skypiea", "Long Ring", "Flamingo", "Ice Castle", "Forgotten Island", "Fishman Island", "Green Zone", "Jungle Island", "Chocolate Island", "Candy Island", "Snow Mountain", "Lava Island", "Thunder Island", "Sky Island", "Underworld"}
    for _, island in pairs(islands) do
        AddButton(tpPage, island, function()
            local q = nil
            for _, quest in pairs(QuestData) do
                if quest.island == island then
                    q = quest
                    break
                end
            end
            if q and q.giver then
                InstantTo(q.giver)
                Notify("Karl Hub", "Teleported to " .. island, 2)
            end
        end)
    end

    -- Close button
    closeBtn.MouseButton1Click:Connect(function()
        gui:Destroy()
    end)

    gui.Parent = LocalPlayer.PlayerGui
    return gui
end

--====================================================================--
--  INFINITE JUMP                                                       --
--====================================================================--
UserInput.JumpRequest:Connect(function()
    if CFG.InfiniteJump then
        local hum = GetHum()
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

--====================================================================--
--  REJOIN / RESPAWN HANDLER                                            --
--====================================================================--
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    ApplyMovement()
    if CFG.AutoFarm then
        StartFarm()
    end
end)

--====================================================================--
--  INIT                                                                --
--====================================================================--
CreateGUI()
ApplyMovement()
Notify("Karl Hub V1", "Loaded. Owner: @Karl08901", 5)
Notify("Karl Hub V1", "Press X on the UI to close", 4)

print("========================================")
print("  KARL HUB V1  |  @Karl08901")
print("  Blox Fruits script loaded successfully")
print("========================================")
