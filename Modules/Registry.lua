local LOGO_ID = "rbxassetid://120675082996894"
local MAIN_COLOR = Color3.fromRGB(0, 168, 255)
local GUIColorMap = {
    ["Blue"] = Color3.fromRGB(0, 168, 255),
    ["Cyan"] = Color3.fromRGB(6, 182, 212),
    ["Purple"] = Color3.fromRGB(168, 85, 247),
    ["Green"] = Color3.fromRGB(16, 185, 129),
    ["Red"] = Color3.fromRGB(244, 63, 94),
    ["Orange"] = Color3.fromRGB(249, 115, 22),
    ["Pink"] = Color3.fromRGB(236, 72, 153),
    ["Gold"] = Color3.fromRGB(234, 179, 8),
    ["White"] = Color3.fromRGB(241, 245, 249)
}
local ColorMap = {
	["White"] = Color3.fromRGB(255, 255, 255),
	["Red"] = Color3.fromRGB(255, 50, 50),
	["Green"] = Color3.fromRGB(50, 255, 50),
	["Blue"] = Color3.fromRGB(50, 150, 255),
	["Yellow"] = Color3.fromRGB(255, 255, 50),
	["Cyan"] = Color3.fromRGB(50, 255, 255),
	["Magenta"] = Color3.fromRGB(255, 50, 255),
	["Orange"] = Color3.fromRGB(255, 150, 50),
	["Purple"] = Color3.fromRGB(150, 50, 255),
    ["Lime"] = Color3.fromRGB(120, 255, 50),
    ["Pink"] = Color3.fromRGB(255, 105, 180),
    ["Gold"] = Color3.fromRGB(255, 215, 0)
}
getgenv().ColorMap = ColorMap
getgenv().GUIColorMap = GUIColorMap
getgenv().LOGO_ID = LOGO_ID
getgenv().MAIN_COLOR = MAIN_COLOR
local GameModuleRegistry = {
    [189707] = {
        ShortName = "NDS",
        GameName = "Natural Disaster Survival",
        Url = "https://raw.githubusercontent.com/BG-0o/Scripts/refs/heads/main/Games/NDS.lua",
        Ready = true
    },
    [142823291] = {
        ShortName = "MM2",
        GameName = "Murder Mystery 2",
        Url = "https://raw.githubusercontent.com/BG-0o/Scripts/refs/heads/main/Games/MM2.lua?toxv=2026-09-13-mm2-split-loader-config-fix",
        CoreUrl = "https://raw.githubusercontent.com/BG-0o/Scripts/refs/heads/main/Games/ModuleMM2.lua?toxv=2026-09-13-mm2-split-loader-config-fix",
        Ready = true
    },
    [4522347649] = {
        ShortName = "ADMIN",
        GameName = "Kohls Admin House",
        Url = "https://raw.githubusercontent.com/BG-0o/Scripts/refs/heads/main/Games/ADMIN.lua",
        Ready = true
    },
    [662417684] = {
        ShortName = "LBB",
        GameName = "Lucky Block Battleground",
        Url = "https://raw.githubusercontent.com/BG-0o/Scripts/refs/heads/main/Games/LBB.lua",
        Ready = true
    },
    [893973440] = {
        ShortName = "FTF",
        GameName = "Flee the Facility",
        Url = "https://raw.githubusercontent.com/BG-0o/Scripts/refs/heads/main/Games/FTF.lua",
        Ready = true
    },
    [155615604] = {
        ShortName = "PL",
        GameName = "Prison Life",
        Url = "https://raw.githubusercontent.com/BG-0o/Scripts/refs/heads/main/Games/PL.lua",
        Ready = true
    },
    [537413528] = {
        ShortName = "BABFT",
        GameName = "Build A Boat For Treasure",
        Url = "https://raw.githubusercontent.com/BG-0o/Scripts/refs/heads/main/Games/BABFT.lua",
        Ready = true
    },
    [119925538689885] = {
        ShortName = "SOD",
        GameName = "Steal Or Die",
        Url = "https://raw.githubusercontent.com/BG-0o/Scripts/refs/heads/main/Games/SOD.lua",
        Ready = true
    },
    [109440485612336] = {
        ShortName = "WID",
        GameName = "When In Disgrace",
        Url = "https://raw.githubusercontent.com/BG-0o/Scripts/refs/heads/main/Games/WID.lua",
        Ready = true
    },
    [70650894743738] = {
        ShortName = "BE",
        GameName = "Bug Evolution",
        Url = "https://raw.githubusercontent.com/BG-0o/Scripts/refs/heads/main/Games/BE.lua",
        Ready = true
    },
    [93660722909304] = {
        ShortName = "SBR",
        GameName = "Scary Baboon Reimagined",
        Url = "https://raw.githubusercontent.com/BG-0o/Scripts/refs/heads/main/Games/SBR.lua",
        Ready = true
    },
    [3823781113] = {
        ShortName = "SS",
        GameName = "Saber Simulator",
        Url = "https://raw.githubusercontent.com/BG-0o/Scripts/refs/heads/main/Games/SS.lua",
        Ready = true,
        PlaceIds = { 3823781113, 1307638097 }
    },
    [1307638097] = {
        ShortName = "SS",
        GameName = "Saber Simulator",
        Url = "https://raw.githubusercontent.com/BG-0o/Scripts/refs/heads/main/Games/SS.lua",
        Ready = true,
        IsAlias = true,
        PlaceIds = { 3823781113, 1307638097 }
    },
    [115681808123944] = {
        ShortName = "TAC",
        GameName = "Throw a Coin",
        Url = "https://raw.githubusercontent.com/BG-0o/Scripts/refs/heads/main/Games/TAC.lua",
        Ready = true,
        PlaceIds = { 115681808123944, 10131390815 }
    },
    [10131390815] = {
        ShortName = "TAC",
        GameName = "Throw a Coin",
        Url = "https://raw.githubusercontent.com/BG-0o/Scripts/refs/heads/main/Games/TAC.lua",
        Ready = true,
        IsAlias = true,
        PlaceIds = { 115681808123944, 10131390815 }
    },
    [133007106457547] = {
        ShortName = "ME",
        GameName = "+1 Muscle Evolution",
        Url = "https://raw.githubusercontent.com/BG-0o/Scripts/refs/heads/main/Games/ME.lua",
        Ready = true,
        PlaceIds = { 133007106457547, 10892211425 }
    },
    [10892211425] = {
        ShortName = "ME",
        GameName = "+1 Muscle Evolution",
        Url = "https://raw.githubusercontent.com/BG-0o/Scripts/refs/heads/main/Games/ME.lua",
        Ready = true,
        IsAlias = true,
        PlaceIds = { 133007106457547, 10892211425 }
    },
    [131479356121251] = {
        ShortName = "BINGO",
        GameName = "50 Player BINGO!",
        Url = "https://raw.githubusercontent.com/BG-0o/Scripts/refs/heads/main/Games/BINGO.lua",
        Ready = true
    },
    [137233438285284] = {
        ShortName = "CF",
        GameName = "Chicken Farm",
        Url = "https://raw.githubusercontent.com/BG-0o/Scripts/refs/heads/main/Games/CF.lua",
        Ready = true
    },
    [113290951185459] = {
        ShortName = "AD",
        GameName = "Anime Dice",
        Url = "https://raw.githubusercontent.com/BG-0o/Scripts/refs/heads/main/Games/AD.lua",
        Ready = true
    },
    [72858262610964] = {
        ShortName = "TSR",
        GameName = "Tap Simulator REBORN",
        Url = "https://raw.githubusercontent.com/BG-0o/Scripts/main/Games/TSR.lua",
        Ready = true,
        PlaceIds = { 72858262610964, 10629695169 }
    }
}

-- Mirror string keys into registry for robust executor type-matching
local stringKeyMirrors = {}
for k, v in pairs(GameModuleRegistry) do
    stringKeyMirrors[tostring(k)] = v
end
for k, v in pairs(stringKeyMirrors) do
    GameModuleRegistry[k] = v
end

getgenv().GameModuleRegistry = GameModuleRegistry

local function ResolveCurrentGameModule()
    local reg = getgenv().GameModuleRegistry or GameModuleRegistry or {}
    local pId = game.PlaceId
    local gId = game.GameId

    if pId and reg[pId] then return reg[pId] end
    if pId and reg[tostring(pId)] then return reg[tostring(pId)] end
    local pNum = tonumber(pId)
    if pNum and reg[pNum] then return reg[pNum] end

    if gId and gId ~= 0 then
        if reg[gId] then return reg[gId] end
        if reg[tostring(gId)] then return reg[tostring(gId)] end
        local gNum = tonumber(gId)
        if gNum and reg[gNum] then return reg[gNum] end
    end

    local pStr = tostring(pId or "")
    local gStr = tostring(gId or "")
    for k, v in pairs(reg) do
        local kStr = tostring(k)
        if (pStr ~= "" and pStr ~= "0" and kStr == pStr) or (gStr ~= "" and gStr ~= "0" and kStr == gStr) then
            return v
        end
        if type(v) == "table" and v.PlaceIds then
            for _, id in ipairs(v.PlaceIds) do
                local idStr = tostring(id)
                if idStr == pStr or (gStr ~= "" and gStr ~= "0" and idStr == gStr) then
                    return v
                end
            end
        end
    end
    return nil
end

getgenv().ResolveCurrentGameModule = ResolveCurrentGameModule
getgenv().DetectGameModule = ResolveCurrentGameModule
getgenv().CurrentGameModule = ResolveCurrentGameModule()
getgenv().ToxTeleportBypassUntil = 0
getgenv().ToxTeleportWhitelistUntil = 0
getgenv().ToxTeleportWhitelistReason = nil
getgenv().AllowToxTeleport = function(seconds, reason)
    local untilTime = tick() + (tonumber(seconds) or 1)
    getgenv().ToxTeleportBypassUntil = math.max(
        tonumber(getgenv().ToxTeleportBypassUntil) or 0,
        untilTime
    )
    getgenv().ToxTeleportWhitelistUntil = math.max(
        tonumber(getgenv().ToxTeleportWhitelistUntil) or 0,
        untilTime
    )
    getgenv().ToxTeleportWhitelistReason = tostring(reason or "ToxHub")
end
getgenv().ToxIsToxTeleportAllowed = function()
    return tick() < math.max(
        tonumber(getgenv().ToxTeleportBypassUntil) or 0,
        tonumber(getgenv().ToxTeleportWhitelistUntil) or 0
    )
end

local function ResolveGlobalRequest()
    local env = getgenv()
    if type(env.ToxRequestFunction) == "function" then return env.ToxRequestFunction end
    if type(env.request) == "function" then return env.request end
    if type(env.http_request) == "function" then return env.http_request end
    if type(syn) == "table" and type(syn.request) == "function" then return syn.request end
    if type(http) == "table" and type(http.request) == "function" then return http.request end
    if type(fluxus) == "table" and type(fluxus.request) == "function" then return fluxus.request end
    if type(krnl) == "table" and type(krnl.request) == "function" then return krnl.request end
    if type(http_request) == "function" then return http_request end
    if type(request) == "function" then return request end
    return nil
end
getgenv().ToxRequestFunction = ResolveGlobalRequest()
