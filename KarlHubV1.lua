--[[
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║          ██╗  ██╗ █████╗ ██████╗ ██╗                        ║
║          ██║ ██╔╝██╔══██╗██╔══██╗██║                        ║
║          █████╔╝ ███████║██████╔╝██║                        ║
║          ██╔═██╗ ██╔══██║██╔══██╗██║                        ║
║          ██║  ██╗██║  ██║██║  ██║███████╗                   ║
║          ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝                  ║
║                                                              ║
║            ██╗  ██╗██╗   ██╗██████╗     ██╗   ██╗ ██╗       ║
║            ██║  ██║██║   ██║██╔══██╗    ██║   ██║███║       ║
║            ███████║██║   ██║██████╔╝    ██║   ██║╚██║       ║
║            ██╔══██║██║   ██║██╔══██╗    ╚██╗ ██╔╝ ██║       ║
║            ██║  ██║╚██████╔╝██████╔╝     ╚████╔╝  ██║       ║
║            ╚═╝  ╚═╝ ╚═════╝ ╚═════╝       ╚═══╝   ╚═╝       ║
║                                                              ║
║                  [ Karl Hub V1 ]                            ║
║              Powered by @Karl08901                          ║
╚══════════════════════════════════════════════════════════════╝
]]

--// Don't execute twice
-- if getgenv()._KarlHubLoaded then warn("Karl Hub V1: Already loaded!") return end
-- getgenv()._KarlHubLoaded = true

--// ═══════════════════════════════════════
--//   KARL HUB V1 — CONFIG
--// ═══════════════════════════════════════
local KARL_HUB = {
    Name       = "Karl Hub V1",
    Version    = "1.0",
    Author     = "@Karl08901",
    ThemeColor = Color3.fromRGB(0, 200, 255),   -- neon cyan
    AccentColor= Color3.fromRGB(180, 0, 255),   -- neon purple
}

--// ═══════════════════════════════════════
--//   SAFE HTTP + LOAD UTILITY
--// ═══════════════════════════════════════
local function LoadURL(url, retries)
    retries = retries or 2

    local function safeHttpGet(u)
        local ok, res = pcall(function()
            return game:HttpGet(u)
        end)
        return ok and res or nil
    end

    local function safeLoad(str)
        if not str then return nil end
        local ok, fn = pcall(function()
            local loader = loadstring or load
            return loader(str)
        end)
        return ok and fn or nil
    end

    local source = safeHttpGet(url)
    local fn     = safeLoad(source)

    if fn then
        task.spawn(fn)
        return true
    end

    if retries > 0 then
        task.wait(0.25)
        return LoadURL(url, retries - 1)
    end

    warn("[Karl Hub V1] Failed to load: " .. tostring(url))
    return false
end

--// ═══════════════════════════════════════
--//   NOTIFICATION HELPER
--// ═══════════════════════════════════════
local function KarlNotify(title, text, duration)
    duration = duration or 5
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title    = "⚡ " .. title,
            Text     = text,
            Icon     = "rbxassetid://9709149431",
            Duration = duration
        })
    end)
end

--// ═══════════════════════════════════════
--//   LOADER CLASS
--// ═══════════════════════════════════════
local Loader = {}
Loader.__index = Loader

function Loader.new()
    return setmetatable({ Games = {} }, Loader)
end

function Loader:Add(name, gameIds, scriptUrls)
    self.Games[name] = { P = gameIds, S = scriptUrls }
end

function Loader:Get(gameId)
    for name, data in next, self.Games do
        if table.find(data.P, gameId) then
            return name, data.S
        end
    end
end

function Loader:Run(showNotif)
    local name, scripts = self:Get(game.GameId)

    if not scripts then
        warn("[Karl Hub V1] No game matched GameId: " .. tostring(game.GameId))
        KarlNotify("Karl Hub V1", "❌ Game not supported!", 5)
        return
    end

    getgenv().Game    = "BF"
    getgenv().KarlHub = KARL_HUB

    if showNotif then
        KarlNotify(
            "Karl Hub V1",
            "🚀 Loading " .. name .. "\n⏳ Please wait...",
            30
        )
    end

    -- Loading screen in console
    print("╔══════════════════════════════╗")
    print("║      KARL HUB V1  ⚡         ║")
    print("║   Loading: " .. name)
    print("║   By: @Karl08901             ║")
    print("╚══════════════════════════════╝")

    for _, url in ipairs(scripts) do
        local ok = LoadURL(url, 3)
        if not ok then
            warn("[Karl Hub V1] Could not load: " .. tostring(url))
        end
    end

    if showNotif then
        KarlNotify("Karl Hub V1", "✅ " .. name .. " loaded!", 5)
    end

    print("[Karl Hub V1] ✅ Done loading: " .. name)
end

--// ═══════════════════════════════════════
--//   GAME REGISTRY
--// ═══════════════════════════════════════
local L = Loader.new()

L:Add("Blox Fruits",
    { 994732206 },
    { "https://raw.githubusercontent.com/UserDevEthical/Loadstring/main/Loader.lua" }
)

L:Add("Grow A Garden",
    { 7436755782 },
    { "https://raw.githubusercontent.com/UserDevEthical/Loadstring/main/Loader.lua" }
)

L:Add("99 Nights in the Forest",
    { 7326934954 },
    { "https://raw.githubusercontent.com/UserDevEthical/Loadstring/main/Loader.lua" }
)

--// ═══════════════════════════════════════
--//   RUN
--// ═══════════════════════════════════════
L:Run(true) -- true = show notifications, false = silent
