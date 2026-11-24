-- [ Karl Hub V1 Patcher ]
-- Rebrands Redz Hub V2 to Karl Hub V1 and swaps Discord to Telegram

local originalHttpGet = game.HttpGet
local originalHttpGetGlobal = getgenv().HttpGet

-- Helper function to do the text replacement
local function patchCode(source)
    if type(source) ~= "string" then return source end
    
    -- Replace Names
    source = source:gsub("Redz Hub V2", "Karl Hub V1")
    source = source:gsub("Redz Hub", "Karl Hub")
    source = source:gsub("Redz", "Karl")
    source = source:gsub("redz", "karl")
    source = source:gsub("REDZ", "KARL")
    
    -- Replace Discord links with your Telegram
    -- This looks for discord.gg/xxxxx and replaces it
    source = source:gsub("https?://discord%.gg/[%w%-]+", "https://t.me/Karl08901")
    source = source:gsub("discord%.gg/[%w%-]+", "t.me/Karl08901")
    source = source:gsub("Discord", "Telegram")
    
    return source
end

-- Hook game:HttpGet
game.HttpGet = function(self, url, ...)
    local source = originalHttpGet(self, url, ...)
    return patchCode(source)
end

-- Hook global HttpGet (used by some executors)
if originalHttpGetGlobal then
    getgenv().HttpGet = function(url, ...)
        local source = originalHttpGetGlobal(url, ...)
        return patchCode(source)
    end
end

-- Load the original script (it will now load with your patches applied)
local mainUrl = "https://raw.githubusercontent.com/tlredz/Scripts/refs/heads/main/main.luau"
local mainSource = originalHttpGet(game, mainUrl)

-- Patch the loader itself just in case
mainSource = patchCode(mainSource)

-- Execute
loadstring(mainSource)()
