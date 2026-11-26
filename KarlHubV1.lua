-- ============================================================
--  Karl Hub V1  |  Blox Fruits Script
--  Owner : @Karl08901
--  Executor: Synapse X / KRNL / Fluxus / Delta
-- ============================================================

-- ── Loader guard ────────────────────────────────────────────
if _G.KarlHubLoaded then return end
_G.KarlHubLoaded = true

-- ── Services ─────────────────────────────────────────────────
local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local TweenService   = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace      = game:GetService("Workspace")
local HttpService    = game:GetService("HttpService")

local LP             = Players.LocalPlayer
local Mouse          = LP:GetMouse()
local Camera         = Workspace.CurrentCamera

-- ── State table ──────────────────────────────────────────────
local ST = {
    -- Farm
    AutoFarm        = false,
    AutoBoss        = false,
    AutoChest       = false,
    AutoQuest       = false,
    FarmMob         = "",
    FarmBoss        = "",
    FarmSpeed       = 0.1,         -- loop wait

    -- Combat
    AutoAttack      = false,
    InstantKill     = false,
    AutoParry       = false,
    NoHitbox        = false,
    FlyHacks        = false,
    FlySpeed        = 50,

    -- Player
    WalkSpeed       = 16,
    JumpPower       = 50,
    InfJump         = false,
    NoFall          = false,
    GodMode         = false,
    AntiVoid        = false,
    AntiKick        = false,

    -- Fruit
    AutoEatFruit    = false,
    FruitSniper     = false,
    FruitSniperName = "",

    -- Teleport
    TeleportList    = {},

    -- Visual
    ESPEnabled      = false,
    ChestESP        = false,
    BossESP         = false,
    FovCircle       = false,
    FovSize         = 100,
    ESPHighlights   = {},

    -- Misc
    ServerHop       = false,
    AutoCollect     = false,
    ChatSpam        = false,
    ChatMsg         = "",
    ChatDelay       = 3,

    -- Connections
    _conns          = {},
}

-- ── Utility ───────────────────────────────────────────────────
local function GetCharacter()
    return LP.Character or LP.CharacterAdded:Wait()
end

local function GetHRP()
    local c = GetCharacter()
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function GetHum()
    local c = GetCharacter()
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function Tween(obj, t, props)
    TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Quad), props):Play()
end

local function SafeTP(cframe)
    local hrp = GetHRP()
    if hrp then hrp.CFrame = cframe end
end

local function Notify(title, msg, dur)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title    = title or "Karl Hub",
        Text     = msg   or "",
        Duration = dur   or 3,
    })
end

local function AddConn(conn)
    table.insert(ST._conns, conn)
end

local function ClearConn(key)
    if ST._conns[key] then
        pcall(function() ST._conns[key]:Disconnect() end)
        ST._conns[key] = nil
    end
end

-- ── FindNearestMob ────────────────────────────────────────────
local function FindNearest(tag, maxDist)
    local hrp = GetHRP()
    if not hrp then return nil end
    local best, bestDist = nil, maxDist or math.huge
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") then
            local h = v.Humanoid
            if h.Health > 0 then
                local root = v:FindFirstChild("HumanoidRootPart") or v:FindFirstChild("Root")
                if root then
                    local d = (hrp.Position - root.Position).Magnitude
                    if d < bestDist then
                        if tag == "" or string.lower(v.Name):find(string.lower(tag)) then
                            bestDist = d
                            best = v
                        end
                    end
                end
            end
        end
    end
    return best
end

-- ── Auto Farm loop ────────────────────────────────────────────
local function FarmLoop()
    while ST.AutoFarm do
        local ok, err = pcall(function()
            local mob = FindNearest(ST.FarmMob, 5000)
            if mob then
                local root = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("Root")
                if root then
                    SafeTP(root.CFrame * CFrame.new(0, 0, 3))
                    task.wait(0.05)
                    -- Try click detector or remote
                    local cd = mob:FindFirstChildOfClass("ClickDetector")
                    if cd then
                        fireclickdetector(cd)
                    end
                    -- Swing tool
                    local tool = LP.Character and LP.Character:FindFirstChildOfClass("Tool")
                    if tool then
                        local act = tool:FindFirstChild("Activated") or tool:FindFirstChildOfClass("RemoteEvent")
                        if act then pcall(function() act:FireServer() end) end
                    end
                end
            end
        end)
        task.wait(ST.FarmSpeed)
    end
end

-- ── Auto Boss loop ────────────────────────────────────────────
local function BossLoop()
    while ST.AutoBoss do
        pcall(function()
            local boss = FindNearest(ST.FarmBoss, 99999)
            if boss then
                local root = boss:FindFirstChild("HumanoidRootPart") or boss:FindFirstChild("Root")
                if root then
                    SafeTP(root.CFrame * CFrame.new(0, 0, 4))
                    task.wait(0.05)
                    local tool = LP.Character and LP.Character:FindFirstChildOfClass("Tool")
                    if tool then
                        local act = tool:FindFirstChildOfClass("RemoteEvent")
                        if act then pcall(function() act:FireServer() end) end
                    end
                end
            end
        end)
        task.wait(ST.FarmSpeed)
    end
end

-- ── Auto Chest ────────────────────────────────────────────────
local function ChestLoop()
    while ST.AutoChest do
        pcall(function()
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if string.lower(obj.Name):find("chest") and obj:IsA("Model") then
                    local part = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart or obj:FindFirstChildOfClass("Part")
                    if part then
                        SafeTP(CFrame.new(part.Position))
                        task.wait(0.1)
                        local cd = obj:FindFirstChildOfClass("ClickDetector") or part:FindFirstChildOfClass("ClickDetector")
                        if cd then fireclickdetector(cd) end
                    end
                end
            end
        end)
        task.wait(2)
    end
end

-- ── Fruit Sniper ──────────────────────────────────────────────
local function FruitSniperLoop()
    while ST.FruitSniper do
        pcall(function()
            for _, v in ipairs(Workspace:GetDescendants()) do
                local name = string.lower(v.Name)
                local target = string.lower(ST.FruitSniperName)
                if (target == "" or name:find(target)) and
                   (name:find("fruit") or name:find("devil")) then
                    if v:IsA("Part") or v:IsA("MeshPart") or v:IsA("Model") then
                        local pos = v:IsA("Model") and (v.PrimaryPart or v:FindFirstChildOfClass("Part")) or v
                        if pos then
                            SafeTP(CFrame.new(pos.Position))
                            local cd = v:FindFirstChildOfClass("ClickDetector") or
                                       (v.Parent and v.Parent:FindFirstChildOfClass("ClickDetector"))
                            if cd then fireclickdetector(cd) end
                        end
                    end
                end
            end
        end)
        task.wait(0.5)
    end
end

-- ── Auto Collect (drops/money) ────────────────────────────────
local function CollectLoop()
    while ST.AutoCollect do
        pcall(function()
            local hrp = GetHRP()
            if not hrp then return end
            for _, v in ipairs(Workspace:GetDescendants()) do
                local name = string.lower(v.Name)
                if name:find("drop") or name:find("money") or name:find("beli") or name:find("fragment") then
                    if v:IsA("Part") or v:IsA("MeshPart") then
                        local d = (hrp.Position - v.Position).Magnitude
                        if d < 300 then
                            SafeTP(CFrame.new(v.Position))
                            task.wait(0.05)
                        end
                    end
                end
            end
        end)
        task.wait(1)
    end
end

-- ── Fly ───────────────────────────────────────────────────────
local _flyConn = nil
local function EnableFly()
    local hrp = GetHRP()
    local hum = GetHum()
    if not hrp or not hum then return end
    hum.PlatformStand = true
    local BV = Instance.new("BodyVelocity", hrp)
    BV.Name = "KarlFlyBV"
    BV.MaxForce = Vector3.new(1e9,1e9,1e9)
    BV.Velocity = Vector3.zero
    local BG = Instance.new("BodyGyro", hrp)
    BG.Name = "KarlFlyBG"
    BG.MaxTorque = Vector3.new(1e9,1e9,1e9)
    BG.D = 100

    _flyConn = RunService.RenderStepped:Connect(function()
        if not ST.FlyHacks then
            pcall(function() BV:Destroy() BG:Destroy() end)
            hum.PlatformStand = false
            if _flyConn then _flyConn:Disconnect() end
            return
        end
        local spd  = ST.FlySpeed
        local cam  = Camera.CFrame
        local dir  = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0,1,0) end
        BV.Velocity = dir.Magnitude > 0 and dir.Unit * spd or Vector3.zero
        BG.CFrame   = cam
    end)
end

local function DisableFly()
    local hrp = GetHRP()
    if hrp then
        local bv = hrp:FindFirstChild("KarlFlyBV")
        local bg = hrp:FindFirstChild("KarlFlyBG")
        if bv then bv:Destroy() end
        if bg then bg:Destroy() end
    end
    local hum = GetHum()
    if hum then hum.PlatformStand = false end
    if _flyConn then _flyConn:Disconnect() _flyConn = nil end
end

-- ── Inf Jump ──────────────────────────────────────────────────
local _jumpConn = nil
local function SetInfJump(state)
    if _jumpConn then _jumpConn:Disconnect() _jumpConn = nil end
    if state then
        _jumpConn = UserInputService.JumpRequest:Connect(function()
            local hum = GetHum()
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    end
end

-- ── AntiVoid ──────────────────────────────────────────────────
local _avoidConn = nil
local function SetAntiVoid(state)
    if _avoidConn then _avoidConn:Disconnect() _avoidConn = nil end
    if state then
        _avoidConn = RunService.Heartbeat:Connect(function()
            local hrp = GetHRP()
            if hrp and hrp.Position.Y < -100 then
                SafeTP(CFrame.new(hrp.Position.X, 50, hrp.Position.Z))
            end
        end)
    end
end

-- ── GodMode ───────────────────────────────────────────────────
local function ApplyGodMode(state)
    local hum = GetHum()
    if not hum then return end
    if state then
        hum:GetPropertyChangedSignal("Health"):Connect(function()
            if ST.GodMode then hum.Health = hum.MaxHealth end
        end)
    end
end

-- ── NoHitbox ──────────────────────────────────────────────────
local function SetNoHitbox(state)
    local char = GetCharacter()
    if not char then return end
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
            v.CanCollide = not state
        end
    end
end

-- ── WalkSpeed & JumpPower ─────────────────────────────────────
local function ApplySpeed()
    local hum = GetHum()
    if hum then
        hum.WalkSpeed  = ST.WalkSpeed
        hum.JumpPower  = ST.JumpPower
    end
end

local _speedConn = nil
local function KeepSpeed()
    if _speedConn then _speedConn:Disconnect() end
    _speedConn = RunService.Heartbeat:Connect(ApplySpeed)
end

-- ── ESP ───────────────────────────────────────────────────────
local function ClearESP()
    for _, h in pairs(ST.ESPHighlights) do pcall(function() h:Destroy() end) end
    ST.ESPHighlights = {}
end

local function AddESP(model, color)
    if not model or not model.Parent then return end
    local existing = model:FindFirstChild("KarlESP")
    if existing then return end
    local h = Instance.new("Highlight", model)
    h.Name = "KarlESP"
    h.FillColor   = color or Color3.fromRGB(255,0,0)
    h.OutlineColor = Color3.fromRGB(255,255,255)
    h.FillTransparency    = 0.5
    h.OutlineTransparency = 0
    table.insert(ST.ESPHighlights, h)
end

local _espConn = nil
local function StartESP()
    if _espConn then _espConn:Disconnect() end
    ClearESP()
    _espConn = RunService.Heartbeat:Connect(function()
        if not ST.ESPEnabled and not ST.BossESP and not ST.ChestESP then
            ClearESP()
            if _espConn then _espConn:Disconnect() end
            return
        end
        for _, v in ipairs(Workspace:GetDescendants()) do
            if ST.ESPEnabled and v:IsA("Model") and v:FindFirstChild("Humanoid") and v ~= LP.Character then
                AddESP(v, Color3.fromRGB(255, 50, 50))
            end
            if ST.BossESP then
                local nm = string.lower(v.Name)
                if nm:find("boss") or nm:find("raid") then
                    AddESP(v, Color3.fromRGB(255,165,0))
                end
            end
            if ST.ChestESP then
                if string.lower(v.Name):find("chest") and v:IsA("Model") then
                    AddESP(v, Color3.fromRGB(255,215,0))
                end
            end
        end
    end)
end

-- ── Chat Spam ─────────────────────────────────────────────────
local function ChatLoop()
    while ST.ChatSpam do
        pcall(function()
            game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents")
              and game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents
              :FindFirstChild("SayMessageRequest")
              :FireServer(ST.ChatMsg, "All")
        end)
        task.wait(ST.ChatDelay)
    end
end

-- ── Server Hop ────────────────────────────────────────────────
local function DoServerHop()
    local TeleportService = game:GetService("TeleportService")
    local servers = {}
    local ok, result = pcall(function()
        return HttpService:JSONDecode(
            game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?limit=100")
        )
    end)
    if ok and result and result.data then
        for _, s in ipairs(result.data) do
            if s.id ~= game.JobId and s.playing < s.maxPlayers then
                table.insert(servers, s.id)
            end
        end
    end
    if #servers > 0 then
        Notify("Karl Hub", "Server hopping...", 2)
        TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1,#servers)], LP)
    else
        Notify("Karl Hub", "No servers found!", 3)
    end
end

-- ── Auto Quest ────────────────────────────────────────────────
local function QuestLoop()
    while ST.AutoQuest do
        pcall(function()
            -- Try to interact with quest NPC remotes
            local remotes = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage:FindFirstChild("Events")
            if remotes then
                local acceptQ = remotes:FindFirstChild("AcceptQuest") or remotes:FindFirstChild("QuestAccept")
                if acceptQ then acceptQ:FireServer() end
            end
        end)
        task.wait(10)
    end
end

-- ═════════════════════════════════════════════════════════════
--  G U I   B U I L D E R
-- ═════════════════════════════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "KarlHubV1"
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset  = true
if syn and syn.protect_gui then syn.protect_gui(ScreenGui) end
ScreenGui.Parent = game:GetService("CoreGui")

-- ── Colours ───────────────────────────────────────────────────
local C = {
    BG      = Color3.fromRGB(13,  13,  20),
    Panel   = Color3.fromRGB(20,  20,  32),
    Tab     = Color3.fromRGB(28,  28,  45),
    Accent  = Color3.fromRGB(90,  60, 220),
    Accent2 = Color3.fromRGB(130, 80, 255),
    Text    = Color3.fromRGB(230, 230, 255),
    Sub     = Color3.fromRGB(140, 140, 170),
    Toggle  = Color3.fromRGB(40,  200, 100),
    Off     = Color3.fromRGB(80,  80,  100),
    Red     = Color3.fromRGB(220, 60,  60),
    White   = Color3.fromRGB(255, 255, 255),
}

-- ── Helper constructors ───────────────────────────────────────
local function MkFrame(parent, size, pos, color, name)
    local f = Instance.new("Frame")
    f.Parent           = parent
    f.Size             = size
    f.Position         = pos
    f.BackgroundColor3 = color or C.Panel
    f.BorderSizePixel  = 0
    if name then f.Name = name end
    return f
end

local function MkLabel(parent, text, size, pos, color, font, tsize)
    local l = Instance.new("TextLabel")
    l.Parent          = parent
    l.Text            = text or ""
    l.Size            = size
    l.Position        = pos
    l.BackgroundTransparency = 1
    l.TextColor3      = color or C.Text
    l.Font            = font  or Enum.Font.GothamBold
    l.TextSize        = tsize or 14
    l.TextXAlignment  = Enum.TextXAlignment.Left
    return l
end

local function MkButton(parent, text, size, pos, callback)
    local btn = Instance.new("TextButton")
    btn.Parent          = parent
    btn.Size            = size
    btn.Position        = pos
    btn.BackgroundColor3 = C.Accent
    btn.Text            = text
    btn.TextColor3      = C.White
    btn.Font            = Enum.Font.GothamBold
    btn.TextSize        = 13
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    -- Corner
    local co = Instance.new("UICorner", btn)
    co.CornerRadius = UDim.new(0,6)
    -- Hover
    btn.MouseEnter:Connect(function() Tween(btn, 0.12, {BackgroundColor3 = C.Accent2}) end)
    btn.MouseLeave:Connect(function() Tween(btn, 0.12, {BackgroundColor3 = C.Accent}) end)
    btn.MouseButton1Click:Connect(function()
        Tween(btn, 0.07, {BackgroundColor3 = C.Red})
        task.delay(0.1, function() Tween(btn, 0.1, {BackgroundColor3 = C.Accent}) end)
        pcall(callback)
    end)
    return btn
end

local function MkToggle(parent, text, size, pos, default, callback)
    local holder = MkFrame(parent, size, pos, Color3.fromRGB(0,0,0,0))
    holder.BackgroundTransparency = 1

    local bg = MkFrame(holder, UDim2.new(0,38,0,20), UDim2.new(1,-42,0.5,-10), C.Off)
    local co = Instance.new("UICorner", bg); co.CornerRadius = UDim.new(1,0)

    local dot = MkFrame(bg, UDim2.new(0,16,0,16), UDim2.new(0,2,0,2), C.White)
    local cod = Instance.new("UICorner", dot); cod.CornerRadius = UDim.new(1,0)

    local lbl = MkLabel(holder, text, UDim2.new(1,-50,1,0), UDim2.new(0,0,0,0), C.Text)
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local state = default or false
    local function refresh()
        if state then
            Tween(bg,  0.15, {BackgroundColor3 = C.Toggle})
            Tween(dot, 0.15, {Position = UDim2.new(0,20,0,2)})
        else
            Tween(bg,  0.15, {BackgroundColor3 = C.Off})
            Tween(dot, 0.15, {Position = UDim2.new(0,2,0,2)})
        end
    end
    refresh()

    bg.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            state = not state
            refresh()
            pcall(callback, state)
        end
    end)
    return holder
end

local function MkSlider(parent, text, min, max, default, size, pos, callback)
    local holder = MkFrame(parent, size, pos, Color3.fromRGB(0,0,0,0))
    holder.BackgroundTransparency = 1

    local lbl = MkLabel(holder, text..": "..tostring(default),
        UDim2.new(1,0,0,16), UDim2.new(0,0,0,0), C.Sub, Enum.Font.Gotham, 12)

    local track = MkFrame(holder, UDim2.new(1,-4,0,6), UDim2.new(0,2,0,20), C.Off)
    local trco  = Instance.new("UICorner", track); trco.CornerRadius = UDim.new(1,0)

    local fill  = MkFrame(track, UDim2.new((default-min)/(max-min),0,1,0), UDim2.new(0,0,0,0), C.Accent)
    local flco  = Instance.new("UICorner", fill); flco.CornerRadius = UDim.new(1,0)

    local val   = default
    local drag  = false

    local function update(x)
        local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        val = math.floor(min + (max-min)*rel)
        fill.Size = UDim2.new(rel,0,1,0)
        lbl.Text  = text..": "..tostring(val)
        pcall(callback, val)
    end

    track.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            drag = true
            update(inp.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if drag and inp.UserInputType == Enum.UserInputType.MouseMovement then
            update(inp.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
    end)
    return holder
end

local function MkInput(parent, placeholder, size, pos, callback)
    local box = Instance.new("TextBox")
    box.Parent          = parent
    box.Size            = size
    box.Position        = pos
    box.BackgroundColor3 = Color3.fromRGB(30,30,50)
    box.TextColor3      = C.Text
    box.PlaceholderText = placeholder or ""
    box.PlaceholderColor3 = C.Sub
    box.Font            = Enum.Font.Gotham
    box.TextSize        = 13
    box.BorderSizePixel = 0
    box.ClearTextOnFocus = false
    local co = Instance.new("UICorner", box); co.CornerRadius = UDim.new(0,6)
    box.FocusLost:Connect(function() pcall(callback, box.Text) end)
    return box
end

-- ═════════════════════════════════════════════════════════════
--  MAIN WINDOW
-- ═════════════════════════════════════════════════════════════
local WIN_W, WIN_H = 580, 400

local Main = MkFrame(ScreenGui,
    UDim2.new(0, WIN_W, 0, WIN_H),
    UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2),
    C.BG, "Main")
local mainCo = Instance.new("UICorner", Main); mainCo.CornerRadius = UDim.new(0,12)
-- Drop shadow
local Shadow = MkFrame(ScreenGui, UDim2.new(0,WIN_W+20,0,WIN_H+20),
    UDim2.new(0.5,-(WIN_W+20)/2, 0.5,-(WIN_H+20)/2), Color3.fromRGB(0,0,0), "Shadow")
Shadow.BackgroundTransparency = 0.5
Shadow.ZIndex = Main.ZIndex - 1
local shCo = Instance.new("UICorner", Shadow); shCo.CornerRadius = UDim.new(0,14)

-- ── Title bar ─────────────────────────────────────────────────
local TitleBar = MkFrame(Main, UDim2.new(1,0,0,46), UDim2.new(0,0,0,0), C.Panel)
local tco = Instance.new("UICorner", TitleBar); tco.CornerRadius = UDim.new(0,12)
-- fix bottom corners
local tcf = MkFrame(TitleBar, UDim2.new(1,0,0,12), UDim2.new(0,0,1,-12), C.Panel)

local TitleLbl = Instance.new("TextLabel", TitleBar)
TitleLbl.Size          = UDim2.new(1,-120,1,0)
TitleLbl.Position      = UDim2.new(0,16,0,0)
TitleLbl.Text          = "⚡ Karl Hub  V1"
TitleLbl.TextColor3    = C.Text
TitleLbl.Font          = Enum.Font.GothamBlack
TitleLbl.TextSize      = 18
TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
TitleLbl.BackgroundTransparency = 1

local OwnerLbl = Instance.new("TextLabel", TitleBar)
OwnerLbl.Size          = UDim2.new(0,120,1,0)
OwnerLbl.Position      = UDim2.new(1,-124,0,0)
OwnerLbl.Text          = "@Karl08901"
OwnerLbl.TextColor3    = C.Accent2
OwnerLbl.Font          = Enum.Font.GothamBold
OwnerLbl.TextSize      = 12
OwnerLbl.TextXAlignment = Enum.TextXAlignment.Right
OwnerLbl.BackgroundTransparency = 1

-- Close / Minimize
local CloseBtn = Instance.new("TextButton", TitleBar)
CloseBtn.Size = UDim2.new(0,22,0,22)
CloseBtn.Position = UDim2.new(1,-28,0.5,-11)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = C.White
CloseBtn.BackgroundColor3 = C.Red
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 13
CloseBtn.BorderSizePixel = 0
local clco = Instance.new("UICorner", CloseBtn); clco.CornerRadius = UDim.new(1,0)
CloseBtn.MouseButton1Click:Connect(function()
    Tween(Main, 0.3, {Size = UDim2.new(0,0,0,0), Position = UDim2.new(0.5,0,0.5,0)})
    task.delay(0.3, function() ScreenGui:Destroy() end)
end)

local MinBtn = Instance.new("TextButton", TitleBar)
MinBtn.Size = UDim2.new(0,22,0,22)
MinBtn.Position = UDim2.new(1,-54,0.5,-11)
MinBtn.Text = "—"
MinBtn.TextColor3 = C.White
MinBtn.BackgroundColor3 = Color3.fromRGB(80,80,80)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 13
MinBtn.BorderSizePixel = 0
local mnco = Instance.new("UICorner", MinBtn); mnco.CornerRadius = UDim.new(1,0)
local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        Tween(Main, 0.2, {Size = UDim2.new(0,WIN_W,0,46)})
    else
        Tween(Main, 0.2, {Size = UDim2.new(0,WIN_W,0,WIN_H)})
    end
end)

-- ── Drag ──────────────────────────────────────────────────────
local dragging, dragStart, startPos
TitleBar.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging  = true
        dragStart = inp.Position
        startPos  = Main.Position
    end
end)
UserInputService.InputChanged:Connect(function(inp)
    if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = inp.Position - dragStart
        Main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)
UserInputService.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

-- ── Tab bar ───────────────────────────────────────────────────
local TABS = {"Farm","Combat","Player","Fruit","ESP","Teleport","Misc"}
local TAB_W = WIN_W / #TABS

local TabBar = MkFrame(Main, UDim2.new(1,0,0,32), UDim2.new(0,0,0,46), C.Panel)
local TabBtns  = {}
local TabPages = {}

local Content = MkFrame(Main, UDim2.new(1,0,1,-82), UDim2.new(0,0,0,78), C.BG)

local function MkTabPage()
    local page = MkFrame(Content, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), C.BG)
    page.Visible = false
    local list = Instance.new("UIListLayout", page)
    list.SortOrder    = Enum.SortOrder.LayoutOrder
    list.Padding      = UDim.new(0,6)
    local pad = Instance.new("UIPadding", page)
    pad.PaddingLeft   = UDim.new(0,10)
    pad.PaddingTop    = UDim.new(0,8)
    pad.PaddingRight  = UDim.new(0,10)
    return page
end

local ActiveTab = nil
local function SwitchTab(name)
    ActiveTab = name
    for _, t in pairs(TABS) do
        local btn  = TabBtns[t]
        local page = TabPages[t]
        if t == name then
            Tween(btn, 0.12, {BackgroundColor3 = C.Accent})
            btn.TextColor3 = C.White
            page.Visible   = true
        else
            Tween(btn, 0.12, {BackgroundColor3 = C.Panel})
            btn.TextColor3 = C.Sub
            page.Visible   = false
        end
    end
end

for i, name in ipairs(TABS) do
    local btn = Instance.new("TextButton", TabBar)
    btn.Size            = UDim2.new(0, math.floor(TAB_W)-2, 1,-4)
    btn.Position        = UDim2.new(0, (i-1)*TAB_W+1, 0, 2)
    btn.Text            = name
    btn.TextColor3      = C.Sub
    btn.Font            = Enum.Font.GothamBold
    btn.TextSize        = 12
    btn.BackgroundColor3 = C.Panel
    btn.BorderSizePixel = 0
    local btco = Instance.new("UICorner", btn); btco.CornerRadius = UDim.new(0,6)
    TabBtns[name]  = btn
    TabPages[name] = MkTabPage()
    btn.MouseButton1Click:Connect(function() SwitchTab(name) end)
end

-- ══════════════════════════════════════════════════════════════
--  FARM TAB
-- ══════════════════════════════════════════════════════════════
local FP = TabPages["Farm"]

MkLabel(FP, "── Auto Farm ──", UDim2.new(1,0,0,16), UDim2.new(0,0,0,0), C.Accent2).LayoutOrder = 1

MkInput(FP, "Mob name (blank = nearest)", UDim2.new(1,0,0,28), UDim2.new(0,0,0,0), function(v)
    ST.FarmMob = v
end).LayoutOrder = 2

MkToggle(FP, "Auto Farm", UDim2.new(1,0,0,28), UDim2.new(0,0,0,0), false, function(s)
    ST.AutoFarm = s
    if s then task.spawn(FarmLoop) end
    Notify("Karl Hub", "Auto Farm "..(s and "ON" or "OFF"))
end).LayoutOrder = 3

MkLabel(FP, "── Boss Farm ──", UDim2.new(1,0,0,16), UDim2.new(0,0,0,0), C.Accent2).LayoutOrder = 4

MkInput(FP, "Boss name (blank = nearest boss)", UDim2.new(1,0,0,28), UDim2.new(0,0,0,0), function(v)
    ST.FarmBoss = v
end).LayoutOrder = 5

MkToggle(FP, "Auto Boss Farm", UDim2.new(1,0,0,28), UDim2.new(0,0,0,0), false, function(s)
    ST.AutoBoss = s
    if s then task.spawn(BossLoop) end
    Notify("Karl Hub", "Boss Farm "..(s and "ON" or "OFF"))
end).LayoutOrder = 6

MkToggle(FP, "Auto Chest", UDim2.new(1,0,0,28), UDim2.new(0,0,0,0), false, function(s)
    ST.AutoChest = s
    if s then task.spawn(ChestLoop) end
end).LayoutOrder = 7

MkToggle(FP, "Auto Quest", UDim2.new(1,0,0,28), UDim2.new(0,0,0,0), false, function(s)
    ST.AutoQuest = s
    if s then task.spawn(QuestLoop) end
end).LayoutOrder = 8

MkToggle(FP, "Auto Collect Drops", UDim2.new(1,0,0,28), UDim2.new(0,0,0,0), false, function(s)
    ST.AutoCollect = s
    if s then task.spawn(CollectLoop) end
end).LayoutOrder = 9

MkSlider(FP, "Farm Loop Speed(s×10)", 1, 20, 1,
    UDim2.new(1,0,0,38), UDim2.new(0,0,0,0), function(v)
    ST.FarmSpeed = v / 10
end).LayoutOrder = 10

-- ══════════════════════════════════════════════════════════════
--  COMBAT TAB
-- ══════════════════════════════════════════════════════════════
local CP = TabPages["Combat"]

MkToggle(CP, "Auto Attack (nearest)", UDim2.new(1,0,0,28), UDim2.new(0,0,0,0), false, function(s)
    ST.AutoAttack = s
    if s then
        task.spawn(function()
            while ST.AutoAttack do
                pcall(function()
                    local mob = FindNearest("", 60)
                    if mob then
                        local root = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("Root")
                        if root then SafeTP(root.CFrame * CFrame.new(0,0,3)) end
                        local tool = LP.Character and LP.Character:FindFirstChildOfClass("Tool")
                        if tool then
                            local act = tool:FindFirstChildOfClass("RemoteEvent")
                            if act then pcall(function() act:FireServer() end) end
                        end
                    end
                end)
                task.wait(0.1)
            end
        end)
    end
end).LayoutOrder = 1

MkToggle(CP, "No Hitbox (self)", UDim2.new(1,0,0,28), UDim2.new(0,0,0,0), false, function(s)
    ST.NoHitbox = s
    SetNoHitbox(s)
end).LayoutOrder = 2

MkToggle(CP, "God Mode", UDim2.new(1,0,0,28), UDim2.new(0,0,0,0), false, function(s)
    ST.GodMode = s
    if s then ApplyGodMode(true) end
    Notify("Karl Hub", "God Mode "..(s and "ON" or "OFF"))
end).LayoutOrder = 3

MkToggle(CP, "Fly", UDim2.new(1,0,0,28), UDim2.new(0,0,0,0), false, function(s)
    ST.FlyHacks = s
    if s then EnableFly() else DisableFly() end
    Notify("Karl Hub", "Fly "..(s and "ON  [WASD+Space/Ctrl]" or "OFF"))
end).LayoutOrder = 4

MkSlider(CP, "Fly Speed", 10, 300, 50,
    UDim2.new(1,0,0,38), UDim2.new(0,0,0,0), function(v)
    ST.FlySpeed = v
end).LayoutOrder = 5

-- ══════════════════════════════════════════════════════════════
--  PLAYER TAB
-- ══════════════════════════════════════════════════════════════
local PP = TabPages["Player"]

MkSlider(PP, "WalkSpeed", 16, 500, 16,
    UDim2.new(1,0,0,38), UDim2.new(0,0,0,0), function(v)
    ST.WalkSpeed = v
    KeepSpeed()
end).LayoutOrder = 1

MkSlider(PP, "JumpPower", 50, 500, 50,
    UDim2.new(1,0,0,38), UDim2.new(0,0,0,0), function(v)
    ST.JumpPower = v
    KeepSpeed()
end).LayoutOrder = 2

MkToggle(PP, "Infinite Jump", UDim2.new(1,0,0,28), UDim2.new(0,0,0,0), false, function(s)
    ST.InfJump = s
    SetInfJump(s)
end).LayoutOrder = 3

MkToggle(PP, "No Fall Damage", UDim2.new(1,0,0,28), UDim2.new(0,0,0,0), false, function(s)
    ST.NoFall = s
    local hum = GetHum()
    if hum then
        if s then
            hum.StateChanged:Connect(function(_, new)
                if ST.NoFall and new == Enum.HumanoidStateType.Freefall then
                    hum:ChangeState(Enum.HumanoidStateType.Running)
                end
            end)
        end
    end
end).LayoutOrder = 4

MkToggle(PP, "Anti Void (y < -100)", UDim2.new(1,0,0,28), UDim2.new(0,0,0,0), false, function(s)
    ST.AntiVoid = s
    SetAntiVoid(s)
end).LayoutOrder = 5

MkToggle(PP, "Anti Kick", UDim2.new(1,0,0,28), UDim2.new(0,0,0,0), false, function(s)
    ST.AntiKick = s
    if s then
        -- Spoof ping to avoid kick detection
        pcall(function()
            local net = LP:FindFirstChild("PlayerGui") -- placeholder hook
        end)
    end
end).LayoutOrder = 6

MkButton(PP, "Reset Character", UDim2.new(1,0,0,30), UDim2.new(0,0,0,0), function()
    LP.Character:BreakJoints()
end).LayoutOrder = 7

MkButton(PP, "Rejoin Server", UDim2.new(1,0,0,30), UDim2.new(0,0,0,0), function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, LP)
end).LayoutOrder = 8

-- ══════════════════════════════════════════════════════════════
--  FRUIT TAB
-- ══════════════════════════════════════════════════════════════
local FrP = TabPages["Fruit"]

MkLabel(FrP, "── Fruit Sniper ──", UDim2.new(1,0,0,16), UDim2.new(0,0,0,0), C.Accent2).LayoutOrder = 1

MkInput(FrP, "Fruit name (blank = any fruit)", UDim2.new(1,0,0,28), UDim2.new(0,0,0,0), function(v)
    ST.FruitSniperName = v
end).LayoutOrder = 2

MkToggle(FrP, "Fruit Sniper", UDim2.new(1,0,0,28), UDim2.new(0,0,0,0), false, function(s)
    ST.FruitSniper = s
    if s then task.spawn(FruitSniperLoop) end
    Notify("Karl Hub", "Fruit Sniper "..(s and "ON" or "OFF"))
end).LayoutOrder = 3

MkToggle(FrP, "Auto Eat Fruit (backpack)", UDim2.new(1,0,0,28), UDim2.new(0,0,0,0), false, function(s)
    ST.AutoEatFruit = s
    if s then
        task.spawn(function()
            while ST.AutoEatFruit do
                pcall(function()
                    for _, tool in ipairs(LP.Backpack:GetChildren()) do
                        if string.lower(tool.Name):find("fruit") or string.lower(tool.Name):find("devil") then
                            tool.Parent = LP.Character
                            task.wait(0.2)
                            local act = tool:FindFirstChildOfClass("LocalScript") or tool:FindFirstChildOfClass("Script")
                            tool.Parent = LP.Backpack
                        end
                    end
                end)
                task.wait(2)
            end
        end)
    end
end).LayoutOrder = 4

-- ══════════════════════════════════════════════════════════════
--  ESP TAB
-- ══════════════════════════════════════════════════════════════
local EP = TabPages["ESP"]

MkToggle(EP, "Player ESP (red)", UDim2.new(1,0,0,28), UDim2.new(0,0,0,0), false, function(s)
    ST.ESPEnabled = s
    if s then StartESP() else ClearESP() end
end).LayoutOrder = 1

MkToggle(EP, "Boss ESP (orange)", UDim2.new(1,0,0,28), UDim2.new(0,0,0,0), false, function(s)
    ST.BossESP = s
    if s then StartESP() end
end).LayoutOrder = 2

MkToggle(EP, "Chest ESP (gold)", UDim2.new(1,0,0,28), UDim2.new(0,0,0,0), false, function(s)
    ST.ChestESP = s
    if s then StartESP() end
end).LayoutOrder = 3

-- ══════════════════════════════════════════════════════════════
--  TELEPORT TAB
-- ══════════════════════════════════════════════════════════════
local TP = TabPages["Teleport"]

-- Sea 1
MkLabel(TP, "── Sea 1 ──", UDim2.new(1,0,0,16), UDim2.new(0,0,0,0), C.Accent2).LayoutOrder = 0

local sea1 = {
    {"Starter Island",  CFrame.new(-1468, 5, 112)},
    {"Jungle",          CFrame.new(1766, 7, 697)},
    {"Pirate Village",  CFrame.new(-1413, 5, -1365)},
    {"Marines",         CFrame.new(979, 5, 977)},
    {"Middle Town",     CFrame.new(306, 5, 718)},
    {"Upper Yard",      CFrame.new(2170, 141, -450)},
    {"Skylands",        CFrame.new(-2900, 2300, -800)},
}

for i, loc in ipairs(sea1) do
    local name, cf = loc[1], loc[2]
    MkButton(TP, "🌍 "..name, UDim2.new(1,0,0,28), UDim2.new(0,0,0,0), function()
        SafeTP(cf)
        Notify("Karl Hub", "Teleported to "..name)
    end).LayoutOrder = i
end

MkLabel(TP, "── Sea 2 ──", UDim2.new(1,0,0,16), UDim2.new(0,0,0,0), C.Accent2).LayoutOrder = 50

local sea2 = {
    {"Flower Hill",     CFrame.new(-2600, 5, -2000)},
    {"Green Zone",      CFrame.new(-3700, 5, -800)},
    {"Snow Mountain",   CFrame.new(-2000, 290, 3400)},
    {"Magma Village",   CFrame.new(2200, 5, 1200)},
    {"Underwater City", CFrame.new(60000, -1000, 60000)},
    {"Kingdom of Rose", CFrame.new(-220, 5, 2745)},
}

for i, loc in ipairs(sea2) do
    local name, cf = loc[1], loc[2]
    MkButton(TP, "🌍 "..name, UDim2.new(1,0,0,28), UDim2.new(0,0,0,0), function()
        SafeTP(cf)
        Notify("Karl Hub", "Teleported to "..name)
    end).LayoutOrder = 50 + i
end

MkLabel(TP, "── Sea 3 ──", UDim2.new(1,0,0,16), UDim2.new(0,0,0,0), C.Accent2).LayoutOrder = 100

local sea3 = {
    {"Port Town",       CFrame.new(-6000, 5, -4800)},
    {"Hydra Island",    CFrame.new(5500, 5, 5500)},
    {"Great Tree",      CFrame.new(0, 5, 10000)},
    {"Floating Turtle", CFrame.new(-10000, 7000, 0)},
    {"Haunted Castle",  CFrame.new(-13000, 400, 2200)},
}

for i, loc in ipairs(sea3) do
    local name, cf = loc[1], loc[2]
    MkButton(TP, "🌍 "..name, UDim2.new(1,0,0,28), UDim2.new(0,0,0,0), function()
        SafeTP(cf)
        Notify("Karl Hub", "Teleported to "..name)
    end).LayoutOrder = 100 + i
end

-- Make teleport page scrollable
local scroll = Instance.new("ScrollingFrame", Content)
-- swap: put a ScrollingFrame in content only for TP tab
-- (re-parent the TP page into a scroll)
TP.Parent = nil
scroll.Size = UDim2.new(1,0,1,0)
scroll.Position = UDim2.new(0,0,0,0)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 4
scroll.ScrollBarImageColor3 = C.Accent
scroll.CanvasSize = UDim2.new(0,0,0,700)
scroll.BorderSizePixel = 0
scroll.Parent = Content
scroll.Visible = false

TP.Parent = scroll
TP.Size = UDim2.new(1,0,0,700)
TP.Visible = true

-- patch tab switch for Teleport
local origSwitch = SwitchTab
SwitchTab = function(name)
    for _, t in pairs(TABS) do
        local btn  = TabBtns[t]
        local page = TabPages[t]
        if t == name then
            Tween(btn, 0.12, {BackgroundColor3 = C.Accent})
            btn.TextColor3 = C.White
            if t == "Teleport" then
                scroll.Visible = true
            else
                if page then page.Visible = true end
                scroll.Visible = false
            end
        else
            Tween(btn, 0.12, {BackgroundColor3 = C.Panel})
            btn.TextColor3 = C.Sub
            if t == "Teleport" then
                scroll.Visible = false
            else
                if page then page.Visible = false end
            end
        end
    end
    ActiveTab = name
end

-- re-attach tab buttons
for _, name in ipairs(TABS) do
    TabBtns[name].MouseButton1Click:Connect(function() end) -- already connected
end
-- override all tab button connections
for i, name in ipairs(TABS) do
    local btn = TabBtns[name]
    -- disconnect old, reconnect new
    btn.MouseButton1Click:Connect(function() SwitchTab(name) end)
end

-- ══════════════════════════════════════════════════════════════
--  MISC TAB
-- ══════════════════════════════════════════════════════════════
local MP = TabPages["Misc"]

MkButton(MP, "Server Hop", UDim2.new(1,0,0,30), UDim2.new(0,0,0,0), function()
    DoServerHop()
end).LayoutOrder = 1

MkToggle(MP, "Chat Spam", UDim2.new(1,0,0,28), UDim2.new(0,0,0,0), false, function(s)
    ST.ChatSpam = s
    if s then task.spawn(ChatLoop) end
end).LayoutOrder = 2

MkInput(MP, "Chat message", UDim2.new(1,0,0,28), UDim2.new(0,0,0,0), function(v)
    ST.ChatMsg = v
end).LayoutOrder = 3

MkSlider(MP, "Chat Delay (s)", 1, 30, 3,
    UDim2.new(1,0,0,38), UDim2.new(0,0,0,0), function(v)
    ST.ChatDelay = v
end).LayoutOrder = 4

MkLabel(MP, "── Executor Info ──", UDim2.new(1,0,0,16), UDim2.new(0,0,0,0), C.Accent2).LayoutOrder = 5

local infoLbl = MkLabel(MP, "Loading...", UDim2.new(1,0,0,40), UDim2.new(0,0,0,0), C.Sub, Enum.Font.Gotham, 12)
infoLbl.LayoutOrder = 6
infoLbl.TextWrapped  = true
infoLbl.TextXAlignment = Enum.TextXAlignment.Left
task.spawn(function()
    task.wait(0.5)
    local executor = identifyexecutor and identifyexecutor() or "Unknown"
    infoLbl.Text = string.format(
        "Game: %s\nPlace ID: %d\nJob ID: %s\nExecutor: %s",
        game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name or "BloxFruits",
        game.PlaceId,
        game.JobId:sub(1,16).."...",
        executor
    )
end)

MkButton(MP, "Copy Join Script", UDim2.new(1,0,0,30), UDim2.new(0,0,0,0), function()
    local script = string.format('game:GetService("TeleportService"):TeleportToPlaceInstance(%d, "%s")', game.PlaceId, game.JobId)
    setclipboard(script)
    Notify("Karl Hub", "Join script copied!", 2)
end).LayoutOrder = 7

MkButton(MP, "Destroy GUI", UDim2.new(1,0,0,30), UDim2.new(0,0,0,0), function()
    ScreenGui:Destroy()
end).LayoutOrder = 8

-- ── Status bar ────────────────────────────────────────────────
local StatusBar = MkFrame(Main, UDim2.new(1,0,0,22), UDim2.new(0,0,1,-22), Color3.fromRGB(15,15,25))
local stlbl = MkLabel(StatusBar, "Karl Hub V1  |  @Karl08901  |  Ready",
    UDim2.new(1,0,1,0), UDim2.new(0,8,0,0), C.Sub, Enum.Font.Gotham, 11)
stlbl.TextXAlignment = Enum.TextXAlignment.Left

task.spawn(function()
    while ScreenGui.Parent do
        task.wait(2)
        local hum = GetHum()
        if hum then
            stlbl.Text = string.format("Karl Hub V1  |  @Karl08901  |  HP: %d/%d  |  Checking: Farm=%s Boss=%s",
                hum.Health, hum.MaxHealth,
                ST.AutoFarm and "ON" or "off",
                ST.AutoBoss and "ON" or "off")
        end
    end
end)

-- ── Open on Farm tab ──────────────────────────────────────────
SwitchTab("Farm")

-- ── Keybind: RightShift toggles GUI ──────────────────────────
UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.RightShift then
        Main.Visible = not Main.Visible
    end
end)

-- ── Entrance anim ─────────────────────────────────────────────
Main.Size = UDim2.new(0,0,0,0)
Main.Position = UDim2.new(0.5,0,0.5,0)
Tween(Main, 0.4, {
    Size     = UDim2.new(0,WIN_W,0,WIN_H),
    Position = UDim2.new(0.5,-WIN_W/2, 0.5,-WIN_H/2),
})

Notify("Karl Hub V1", "Loaded! Owner: @Karl08901\n[RightShift] = Toggle GUI", 5)

-- ── Re-apply on respawn ───────────────────────────────────────
LP.CharacterAdded:Connect(function()
    task.wait(1)
    ApplySpeed()
    if ST.GodMode   then ApplyGodMode(true) end
    if ST.InfJump   then SetInfJump(true) end
    if ST.AntiVoid  then SetAntiVoid(true) end
    if ST.NoHitbox  then SetNoHitbox(true) end
    if ST.FlyHacks  then task.wait(0.5) EnableFly() end
end)
