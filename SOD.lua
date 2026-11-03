-- ==============================================================================
-- TOXHUB - STEAL OR DIE MODULE (SOD.lua)
-- Game URL: https://www.roblox.com/games/119925538689885/Steal-Or-Die
-- PlaceId: 119925538689885
-- Raw URL: https://raw.githubusercontent.com/BG-0o/Scripts/refs/heads/main/SOD.lua
-- ==============================================================================

local SODPlaceId = 119925538689885

if game.PlaceId ~= SODPlaceId then
    return
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local PathfindingService = game:GetService("PathfindingService")

local Player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera or Workspace:FindFirstChildOfClass("Camera")
local Mouse = Player and Player:GetMouse()

local Settings = getgenv().Settings
local GamePage = getgenv().GamePage
local CreateToggle = getgenv().CreateToggle
local CreateToggleWithValue = getgenv().CreateToggleWithValue
local CreateButton = getgenv().CreateButton
local CreateDropdown = getgenv().CreateDropdown
local CreateToggleWithChoice = getgenv().CreateToggleWithChoice
local CustomNotify = getgenv().CustomNotify or function() end
local AutoSaveConfiguration = getgenv().AutoSaveConfiguration or function() end
local AddConnection = getgenv().AddConnection or function(c) return c end
local SyncToggleVisuals = getgenv().SyncToggleVisuals

if not Settings
or not GamePage
or not CreateToggle
or not CreateButton then
    return
end

getgenv().ToxSODGeneration = (tonumber(getgenv().ToxSODGeneration) or 0) + 1
local CurrentGeneration = getgenv().ToxSODGeneration

local SODModuleVersion = "2026-11-02-sod-v6"

if getgenv().ToxSODModuleLoadedJobId == game.JobId
and getgenv().ToxSODModuleVersion == SODModuleVersion
and getgenv().ToxSODModulePage == GamePage
and not getgenv().Destroyed then
    return
end

if getgenv().ToxSODCleanup then
    pcall(getgenv().ToxSODCleanup)
end

for _, child in ipairs(GamePage:GetChildren()) do
    if child:IsA("GuiObject") then
        child:Destroy()
    end
end

-- ==============================================================================
-- SETTINGS & PERSISTENCE (ALL DISABLED BY DEFAULT)
-- ==============================================================================

Settings.SODCollapsedSections = typeof(Settings.SODCollapsedSections) == "table"
    and Settings.SODCollapsedSections
    or {}

-- Visuals (All disabled by default)
Settings.SODItemESP = Settings.SODItemESP == true
Settings.SODItemESPStyle = tostring(Settings.SODItemESPStyle or "Name + Value")
Settings.SODExitESP = Settings.SODExitESP == true
Settings.SODMonsterESP = Settings.SODMonsterESP == true
Settings.SODMonsterWarn = Settings.SODMonsterWarn == true
Settings.SODMonsterWarnDistance = tonumber(Settings.SODMonsterWarnDistance) or 60
Settings.SODPlayerESP = Settings.SODPlayerESP == true
Settings.SODVentClosetESP = Settings.SODVentClosetESP == true
Settings.SODRarityFilter = tostring(Settings.SODRarityFilter or "All")
Settings.SODMinValueEnabled = Settings.SODMinValueEnabled == true
Settings.SODMinValue = tonumber(Settings.SODMinValue) or 250
Settings.SODESPTextSize = math.clamp(tonumber(Settings.SODESPTextSize) or 10, 8, 18)
Settings.SODESPMaxDistance = math.clamp(tonumber(Settings.SODESPMaxDistance) or 350, 100, 1000)
Settings.SODFullBright = Settings.SODFullBright == true

-- Looting & Autofarm (All disabled by default)
Settings.SODAutoFarm = Settings.SODAutoFarm == true
Settings.SODFarmSpeed = math.clamp(tonumber(Settings.SODFarmSpeed) or 40, 25, 55)
Settings.SODAutoEscape = Settings.SODAutoEscape == true
Settings.SODFarmDangerDist = tonumber(Settings.SODFarmDangerDist) or 50
Settings.SODInstantSteal = Settings.SODInstantSteal == true
Settings.SODAutoSteal = Settings.SODAutoSteal == true
Settings.SODAutoStealRange = tonumber(Settings.SODAutoStealRange) or 15
Settings.SODInstantVent = Settings.SODInstantVent == true

-- Survival & Combat (All disabled by default)
Settings.SODEntityKill = Settings.SODEntityKill == true
Settings.SODInfiniteStamina = Settings.SODInfiniteStamina == true

-- Teleports & Utilities (All disabled by default)
Settings.SODClickTP = Settings.SODClickTP == true
Settings.SODAutoVote = Settings.SODAutoVote == true
Settings.SODVoteMonster = tostring(Settings.SODVoteMonster or "AI")
Settings.SODVoteMapChoice1 = tostring(Settings.SODVoteMapChoice1 or "Office")
Settings.SODVoteMapChoice2 = tostring(Settings.SODVoteMapChoice2 or "Supermarket")
Settings.SODVoteMapChoice3 = tostring(Settings.SODVoteMapChoice3 or "Liminal Lucidity")
Settings.SODAntiAFK = Settings.SODAntiAFK == true

-- ==============================================================================
-- STATE VARIABLES
-- ==============================================================================

local SODConnections = {}
local SODCurrentSection = nil
local SODSections = {}

local ItemPrompts = {}        -- [prompt] = { Object, Part, Name, NameLower, Rarity, Value, Weight }
local ActiveMonsters = {}     -- [model] = { Model, Root, Name, Kind, IsPlayer }
local ExitObjects = {}        -- [instance] = { Part, Model, Label }
local VentObjects = {}        -- [instance] = { Part, Prompt }
local ClosetObjects = {}      -- [instance] = { Part, Model }
local DoorObjects = {}        -- [part] = { CanCollide, Transparency }

local ItemESPObjects = {}     -- [prompt] = { Highlight, Billboard, Label }
local ExitESPObjects = {}     -- [instance] = { Highlight, Billboard, Label }
local MonsterESPObjects = {}  -- [model] = { Highlight, Billboard, Label }
local PlayerESPObjects = {}   -- [player] = { Highlight, Billboard, Label }
local VentESPObjects = {}     -- [instance] = { Highlight, Billboard, Label }
local ClosetESPObjects = {}   -- [instance] = { Highlight, Billboard, Label }

local SafePlatformModel = nil
local WarnScreenGui = nil
local WarnFrame = nil
local WarnStroke = nil
local WarnText = nil

local CurrentFarmTween = nil
local AutoFarmRunning = false
local EntityKillRunning = false
local AntiAFKConnection = nil
local LastVoteCheck = 0
getgenv().ToxSODFarmGen = tonumber(getgenv().ToxSODFarmGen) or 0

local OrigHoldDurations = setmetatable({}, { __mode = "k" })
local OrigLightingProps = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    Ambient = Lighting.Ambient
}

local LastAuraCheck = 0
local LastESPInterval = 0
local LastStaminaCheck = 0
local LastDescendantSweep = 0
local ProximityPromptService = game:GetService("ProximityPromptService")
local VirtualInputManager = game:GetService("VirtualInputManager")

-- ==============================================================================
-- RARITIES & ITEM TAXONOMY
-- ==============================================================================

local RarityRank = {
    ["Common"] = 1,
    ["Uncommon"] = 2,
    ["Rare"] = 3,
    ["Epic"] = 4,
    ["Legendary"] = 5,
    ["Mythic"] = 6,
    ["Secret"] = 6
}

local KnownItemRaritiesSorted = {
    -- Mythic
    { "cursed idol", "Mythic" },
    { "alien artifact", "Mythic" },
    { "golden skull", "Mythic" },
    { "secret core", "Mythic" },
    { "dark matter", "Mythic" },
    { "pandora", "Mythic" },
    { "mythic", "Mythic" },
    { "secret", "Mythic" },
    { "cursed", "Mythic" },

    -- Legendary
    { "diamond case", "Legendary" },
    { "gold bullion", "Legendary" },
    { "briefcase of cash", "Legendary" },
    { "golden idol", "Legendary" },
    { "crown jewels", "Legendary" },
    { "holy relic", "Legendary" },
    { "ancient vase", "Legendary" },
    { "ancient relic", "Legendary" },
    { "secret prototype", "Legendary" },
    { "quantum laser", "Legendary" },
    { "plasma rifle", "Legendary" },
    { "gold bar", "Legendary" },
    { "gold ingot", "Legendary" },
    { "meteorite", "Legendary" },
    { "safe vault", "Legendary" },
    { "prototype", "Legendary" },
    { "bullion", "Legendary" },
    { "vault", "Legendary" },
    { "laser", "Legendary" },
    { "relic", "Legendary" },
    { "ingot", "Legendary" },
    { "gold", "Legendary" },
    { "legendary", "Legendary" },

    -- Epic (Pure Item Identity - regardless of random price!)
    { "plasma cutter", "Epic" },
    { "crystal skull", "Epic" },
    { "crystal ball", "Epic" },
    { "laser drill", "Epic" },
    { "golden statue", "Epic" },
    { "golden trophy", "Epic" },
    { "blue diamond", "Epic" },
    { "red diamond", "Epic" },
    { "server blade", "Epic" },
    { "ancient scepter", "Epic" },
    { "projector", "Epic" },
    { "microscope", "Epic" },
    { "telescope", "Epic" },
    { "generator", "Epic" },
    { "strongbox", "Epic" },
    { "briefcase", "Epic" },
    { "sapphire", "Epic" },
    { "emerald", "Epic" },
    { "diamond", "Epic" },
    { "chalice", "Epic" },
    { "scepter", "Epic" },
    { "crystal", "Epic" },
    { "server", "Epic" },
    { "statue", "Epic" },
    { "trophy", "Epic" },
    { "plasma", "Epic" },
    { "goblet", "Epic" },
    { "tiara", "Epic" },
    { "crown", "Epic" },
    { "safe", "Epic" },
    { "ruby", "Epic" },
    { "vase", "Epic" },
    { "urn", "Epic" },
    { "epic", "Epic" },

    -- Rare
    { "graphics card", "Rare" },
    { "gaming laptop", "Rare" },
    { "gaming pc", "Rare" },
    { "curved monitor", "Rare" },
    { "dslr camera", "Rare" },
    { "sound amplifier", "Rare" },
    { "vr headset", "Rare" },
    { "video card", "Rare" },
    { "playstation", "Rare" },
    { "nintendo", "Rare" },
    { "safe key", "Rare" },
    { "microwave", "Rare" },
    { "amplifier", "Rare" },
    { "computer", "Rare" },
    { "painting", "Rare" },
    { "notebook", "Rare" },
    { "monitor", "Rare" },
    { "console", "Rare" },
    { "artwork", "Rare" },
    { "macbook", "Rare" },
    { "desktop", "Rare" },
    { "laptop", "Rare" },
    { "camera", "Rare" },
    { "drone", "Rare" },
    { "art", "Rare" },
    { "gpu", "Rare" },
    { "rtx", "Rare" },
    { "ps5", "Rare" },
    { "xbox", "Rare" },
    { "pc", "Rare" },
    { "vr", "Rare" },
    { "rare", "Rare" },

    -- Uncommon
    { "gaming headset", "Uncommon" },
    { "wireless mouse", "Uncommon" },
    { "smartwatch", "Uncommon" },
    { "walkie talkie", "Uncommon" },
    { "electric kettle", "Uncommon" },
    { "coffee maker", "Uncommon" },
    { "headphones", "Uncommon" },
    { "power drill", "Uncommon" },
    { "thermostat", "Uncommon" },
    { "calculator", "Uncommon" },
    { "flashlight", "Uncommon" },
    { "hand drill", "Uncommon" },
    { "keyboard", "Uncommon" },
    { "earphones", "Uncommon" },
    { "speaker", "Uncommon" },
    { "earbuds", "Uncommon" },
    { "blender", "Uncommon" },
    { "charger", "Uncommon" },
    { "router", "Uncommon" },
    { "tablet", "Uncommon" },
    { "radio", "Uncommon" },
    { "watch", "Uncommon" },
    { "drill", "Uncommon" },
    { "rolex", "Uncommon" },
    { "modem", "Uncommon" },
    { "mouse", "Uncommon" },
    { "iron", "Uncommon" },
    { "ipad", "Uncommon" },
    { "uncommon", "Uncommon" },

    -- Common
    { "stack of cash", "Common" },
    { "loose change", "Common" },
    { "smartphone", "Common" },
    { "water bottle", "Common" },
    { "energy drink", "Common" },
    { "coffee mug", "Common" },
    { "wall clock", "Common" },
    { "desk clock", "Common" },
    { "soda can", "Common" },
    { "cellphone", "Common" },
    { "duct tape", "Common" },
    { "bandage", "Common" },
    { "battery", "Common" },
    { "toaster", "Common" },
    { "keycard", "Common" },
    { "wallet", "Common" },
    { "bottle", "Common" },
    { "plates", "Common" },
    { "change", "Common" },
    { "money", "Common" },
    { "coins", "Common" },
    { "plate", "Common" },
    { "paper", "Common" },
    { "phone", "Common" },
    { "clock", "Common" },
    { "bills", "Common" },
    { "coins", "Common" },
    { "coin", "Common" },
    { "cash", "Common" },
    { "bill", "Common" },
    { "book", "Common" },
    { "keys", "Common" },
    { "tape", "Common" },
    { "soap", "Common" },
    { "soda", "Common" },
    { "card", "Common" },
    { "mug", "Common" },
    { "cup", "Common" },
    { "pen", "Common" },
    { "key", "Common" },
    { "common", "Common" }
}

local function DetectRarityFromColor(color)
    if not color then return nil end
    local r, g, b = color.R * 255, color.G * 255, color.B * 255

    -- Purple / Magenta -> Epic
    if (r > 110 and b > 160 and g < 160) or (r > 140 and b > 190 and g < 180) then
        return "Epic"
    end
    -- Red -> Mythic
    if r > 190 and g < 90 and b < 90 then
        return "Mythic"
    end
    -- Gold / Orange / Yellow -> Legendary
    if (r > 200 and g > 130 and b < 90) or (r > 230 and g > 180 and b < 60) then
        return "Legendary"
    end
    -- Blue / Cyan -> Rare
    if (b > 170 and r < 130) or (b > 190 and g > 100 and r < 90) then
        return "Rare"
    end
    -- Green -> Uncommon
    if g > 150 and r < 140 and b < 140 then
        return "Uncommon"
    end
    return nil
end

local FilterMinRank = {
    ["All"] = 1,
    ["Common+"] = 1,
    ["Uncommon+"] = 2,
    ["Rare+"] = 3,
    ["Epic+"] = 4,
    ["Legendary+"] = 5,
    ["Mythic Only"] = 6
}

local RarityColors = {
    ["Common"] = Color3.fromRGB(220, 220, 230),
    ["Uncommon"] = Color3.fromRGB(70, 230, 110),
    ["Rare"] = Color3.fromRGB(50, 160, 255),
    ["Epic"] = Color3.fromRGB(180, 75, 255),
    ["Legendary"] = Color3.fromRGB(255, 190, 30),
    ["Mythic"] = Color3.fromRGB(255, 45, 85),
    ["Secret"] = Color3.fromRGB(255, 45, 85)
}

local GenericNames = {
    ["handle"] = true,
    ["part"] = true,
    ["main"] = true,
    ["root"] = true,
    ["primarypart"] = true,
    ["hitbox"] = true,
    ["meshpart"] = true,
    ["attachment"] = true,
    ["promptattachment"] = true,
    ["interaction"] = true,
    ["interact"] = true,
    ["proximityprompt"] = true,
}

local NonLootKeywords = {
    "door", "gate", "vent", "locker", "closet", "wardrobe", "hidespot",
    "exit", "escape", "extract", "evac", "button", "switch",
    "breaker", "fuse", "elevator", "barrier", "barricade"
}

local NonMonsterKeywords = {
    "door", "gate", "room", "spawn", "barrier", "zone", "prop", "wall", "floor",
    "vent", "closet", "locker", "wardrobe", "hidespot", "elevator", "box", "crate"
}

local LootKeywords = {
    "phone", "wallet", "gold", "laptop", "safe", "bar", "watch", "key",
    "tablet", "camera", "painting", "statue", "jewelry", "console",
    "headphones", "cash", "ring", "drive", "usb", "bag", "purse",
    "loot", "item", "pickup", "diamond", "core", "relic", "skull", "idol",
    "gpu", "card", "coin", "money", "artifact", "trophy", "ingot"
}

local EstimatedValues = {
    ["mythic"] = 3500,
    ["secret"] = 5000,
    ["cursed"] = 4000,
    ["idol"] = 3000,
    ["gold bar"] = 1500,
    ["gold"] = 1200,
    ["legendary"] = 1800,
    ["vault"] = 2000,
    ["diamond case"] = 2200,
    ["diamond"] = 1200,
    ["relic"] = 1600,
    ["statue"] = 900,
    ["crown"] = 1000,
    ["safe"] = 750,
    ["gpu"] = 650,
    ["painting"] = 550,
    ["laptop"] = 500,
    ["console"] = 400,
    ["rare"] = 450,
    ["camera"] = 300,
    ["tablet"] = 280,
    ["uncommon"] = 250,
    ["watch"] = 220,
    ["ring"] = 200,
    ["headphones"] = 180,
    ["money"] = 150,
    ["cash"] = 150,
    ["phone"] = 150,
    ["wallet"] = 100,
    ["coin"] = 80,
    ["key"] = 50,
}

local function InferValue(nameLower)
    if not nameLower or nameLower == "" then return 100 end
    for word, val in pairs(EstimatedValues) do
        if string.find(nameLower, word, 1, true) then
            return val
        end
    end
    return 100
end

local MonsterKeywords = {
    "entity", "monster", "locust", "hollow", "hunter", "creature",
    "killer", "beast", "wendell", "rictus", "the locust"
}

-- ==============================================================================
-- HELPER UTILITIES
-- ==============================================================================

local function TrackConnection(connection)
    if connection then
        table.insert(SODConnections, connection)
        AddConnection(connection)
    end
    return connection
end

local function GetCharacterState()
    local character = Player and Player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    return character, humanoid, root
end

local function HasSubstring(text, list)
    if not text then return false end
    local lower = string.lower(text)
    for _, word in ipairs(list) do
        if string.find(lower, word, 1, true) then
            return true
        end
    end
    return false
end

local function ReadNumberAttr(obj, keys)
    if not obj then return nil end
    for _, k in ipairs(keys) do
        local val = obj:GetAttribute(k)
        if typeof(val) == "number" then
            return val
        elseif typeof(val) == "string" then
            local num = tonumber(string.match(val, "[%d%.]+"))
            if num then return num end
        end
        local child = obj:FindFirstChild(k)
        if child and (child:IsA("NumberValue") or child:IsA("IntValue")) then
            return child.Value
        elseif child and child:IsA("StringValue") then
            local num = tonumber(string.match(child.Value, "[%d%.]+"))
            if num then return num end
        end
    end
    return nil
end

local function ReadStringAttr(obj, keys)
    if not obj then return nil end
    for _, k in ipairs(keys) do
        local val = obj:GetAttribute(k)
        if typeof(val) == "string" and val ~= "" then
            return val
        end
        local child = obj:FindFirstChild(k)
        if child and child:IsA("StringValue") and child.Value ~= "" then
            return child.Value
        end
    end
    return nil
end

local function InferRarity(nameLower)
    if not nameLower or nameLower == "" then return "Common" end

    for _, entry in ipairs(KnownItemRaritiesSorted) do
        if string.find(nameLower, entry[1], 1, true) then
            return entry[2]
        end
    end

    return "Common"
end

local function GetItemHierarchy(prompt)
    local list = {}
    if not prompt then return list end
    table.insert(list, prompt)

    local curr = prompt.Parent
    while curr and curr ~= Workspace and curr ~= game do
        table.insert(list, curr)
        curr = curr.Parent
    end
    return list
end

local function ResolveItemData(prompt, instance, nameLower)
    local hierarchy = GetItemHierarchy(prompt)

    local rawRarity = nil
    local rawValue = nil
    local rawWeight = nil
    local guiColorRarity = nil
    local guiPrice = nil

    for _, obj in ipairs(hierarchy) do
        -- Rarity string / number
        if not rawRarity then
            for _, k in ipairs({ "Rarity", "rarity", "Tier", "tier", "ItemRarity", "Grade", "Quality" }) do
                local a = obj:GetAttribute(k)
                if typeof(a) == "string" and a ~= "" then
                    rawRarity = a
                    break
                elseif typeof(a) == "number" then
                    local tiers = { [1] = "Common", [2] = "Uncommon", [3] = "Rare", [4] = "Epic", [5] = "Legendary", [6] = "Mythic" }
                    if tiers[a] then
                        rawRarity = tiers[a]
                        break
                    end
                end
                local c = obj:FindFirstChild(k)
                if c and c:IsA("StringValue") and c.Value ~= "" then
                    rawRarity = c.Value
                    break
                end
            end
        end

        -- Value number
        if not rawValue then
            for _, k in ipairs({ "Value", "Price", "Worth", "Cash", "Amount", "CurrentValue" }) do
                local a = obj:GetAttribute(k)
                if typeof(a) == "number" and a > 0 then
                    rawValue = a
                    break
                elseif typeof(a) == "string" then
                    local n = tonumber(string.match(a, "[%d%.]+"))
                    if n and n > 0 then
                        rawValue = n
                        break
                    end
                end
                local c = obj:FindFirstChild(k)
                if c and (c:IsA("NumberValue") or c:IsA("IntValue")) and c.Value > 0 then
                    rawValue = c.Value
                    break
                end
            end
        end

        -- Weight number
        if not rawWeight then
            for _, k in ipairs({ "Weight", "Mass", "Kg", "KG", "CarryWeight", "ItemWeight" }) do
                local a = obj:GetAttribute(k)
                if typeof(a) == "number" and a > 0 then
                    rawWeight = a
                    break
                elseif typeof(a) == "string" then
                    local n = tonumber(string.match(a, "[%d%.]+"))
                    if n and n > 0 then
                        rawWeight = n
                        break
                    end
                end
            end
        end

        -- Inspect in-game BillboardGui / TextLabels for exact displayed rarity word, price, and weight!
        for _, child in ipairs(obj:GetChildren()) do
            if child:IsA("BillboardGui") and child.Name ~= "ToxSODItemTag" and child.Name ~= "ToxSOD_ItemBB" then
                for _, desc in ipairs(child:GetDescendants()) do
                    if desc:IsA("TextLabel") and desc.Text and desc.Text ~= "" then
                        local tUpper = string.upper(desc.Text)
                        -- 1. Exact Rarity Word directly from game UI text
                        if not guiColorRarity then
                            for _, rWord in ipairs({ "MYTHIC", "LEGENDARY", "EPIC", "RARE", "UNCOMMON", "COMMON" }) do
                                if string.find(tUpper, rWord, 1, true) then
                                    guiColorRarity = rWord:sub(1,1) .. rWord:sub(2):lower()
                                    break
                                end
                            end
                        end
                        -- 2. Exact Price from game UI text
                        if not guiPrice and string.find(desc.Text, "%$") then
                            local n = tonumber(string.match(desc.Text, "%$([%d%,%.]+)"))
                            if n and n > 0 then guiPrice = n end
                        end
                        -- 3. Exact Weight from game UI text
                        if not rawWeight and (string.find(desc.Text, "kg") or string.find(desc.Text, "KG")) then
                            local w = tonumber(string.match(desc.Text, "([%d%.]+)%s*[kK][gG]"))
                            if w and w > 0 then rawWeight = w end
                        end
                        -- 4. Color fallback
                        if not guiColorRarity and desc.TextColor3 then
                            local detected = DetectRarityFromColor(desc.TextColor3)
                            if detected then guiColorRarity = detected end
                        end
                    elseif desc:IsA("Frame") and not guiColorRarity then
                        local detected = DetectRarityFromColor(desc.BackgroundColor3)
                        if detected then guiColorRarity = detected end
                    end
                end
            end
        end
    end

    -- Live randomized price and weight from the game's displayed BillboardGui
    if guiPrice and guiPrice > 0 then
        rawValue = guiPrice
    end

    -- Visual color from the game's GUI is the direct indicator of the item's tier
    if guiColorRarity then
        rawRarity = guiColorRarity
    end

    -- If no attribute or GUI color found, identify what the item is by its name (NEVER by price!)
    if not rawRarity or rawRarity == "" then
        rawRarity = InferRarity(nameLower)
    end

    -- Normalize capitalization
    local norm = string.lower(tostring(rawRarity or "common"))
    if norm == "common" then rawRarity = "Common"
    elseif norm == "uncommon" then rawRarity = "Uncommon"
    elseif norm == "rare" then rawRarity = "Rare"
    elseif norm == "epic" then rawRarity = "Epic"
    elseif norm == "legendary" then rawRarity = "Legendary"
    elseif norm == "mythic" or norm == "secret" then rawRarity = "Mythic"
    else rawRarity = "Common" end

    if not rawValue or rawValue == 0 then
        rawValue = InferValue(nameLower)
    end

    return rawRarity, rawValue or 100, rawWeight or 0
end

local function FormatCurrency(num)
    if not num then return "$0" end
    local rounded = math.floor(tonumber(num) or 0)
    local s = tostring(rounded)
    local formatted = s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
    return "$" .. formatted
end

local function FormatWeight(w)
    if not w or w <= 0 then return "" end
    if w >= 10 then
        return string.format(" | %dkg", math.floor(w + 0.5))
    end
    local s = string.format("%.1f", w)
    if s:sub(-2) == ".0" then
        s = s:sub(1, -3)
    end
    return " | " .. s .. "kg"
end

local function GetItemModel(inst)
    if not inst then return nil end
    local curr = inst:IsA("ProximityPrompt") and inst.Parent or inst
    while curr and curr ~= Workspace and curr ~= game do
        if curr:IsA("Model") then
            local mLower = string.lower(curr.Name)
            if not curr:FindFirstChildOfClass("Humanoid")
               and mLower ~= "workspace" and mLower ~= "map" and mLower ~= "rooms" 
               and mLower ~= "props" and mLower ~= "items" and mLower ~= "loot" 
               and mLower ~= "folder" and mLower ~= "geometry" and mLower ~= "decor" 
               and mLower ~= "spawns" and mLower ~= "environment" and mLower ~= "camera" then
                return curr
            end
        end
        curr = curr.Parent
    end
    return nil
end

local function ResolveBasePart(inst)
    if not inst then return nil end
    if inst:IsA("BasePart") then return inst end
    if inst:IsA("Attachment") then
        local p = inst.Parent
        if p and p:IsA("BasePart") then return p end
        if p and p:IsA("Model") then
            return p.PrimaryPart or p:FindFirstChildWhichIsA("BasePart", true)
        end
    end
    if inst:IsA("ProximityPrompt") then
        local p = inst.Parent
        if not p then return nil end
        if p:IsA("BasePart") then return p end
        if p:IsA("Attachment") then
            local pp = p.Parent
            if pp and pp:IsA("BasePart") then return pp end
            if pp and pp:IsA("Model") then
                return pp.PrimaryPart or pp:FindFirstChildWhichIsA("BasePart", true)
            end
        end
        if p:IsA("Model") then
            return p.PrimaryPart or p:FindFirstChildWhichIsA("BasePart", true)
        end
        return p:FindFirstChildWhichIsA("BasePart", true)
    end
    if inst:IsA("Model") then
        if inst.PrimaryPart then return inst.PrimaryPart end
        local handle = inst:FindFirstChild("Handle") or inst:FindFirstChild("Main") or inst:FindFirstChild("Root") or inst:FindFirstChild("Hitbox")
        if handle and handle:IsA("BasePart") then return handle end
        return inst:FindFirstChildWhichIsA("BasePart", true)
    end
    if inst.Parent and inst.Parent ~= Workspace and inst.Parent:IsA("Model") then
        local p = inst.Parent
        if p.PrimaryPart then return p.PrimaryPart end
        local handle = p:FindFirstChild("Handle") or p:FindFirstChild("Main") or p:FindFirstChild("Root") or p:FindFirstChild("Hitbox")
        if handle and handle:IsA("BasePart") then return handle end
        return p:FindFirstChildWhichIsA("BasePart", true)
    end
    return inst:FindFirstChildWhichIsA("BasePart", true)
end

local function ResolveItemName(prompt, instance)
    if prompt and prompt.ObjectText and prompt.ObjectText ~= "" then
        local clean = string.gsub(prompt.ObjectText, "^%s*(.-)%s*$", "%1")
        if #clean > 0 and not GenericNames[string.lower(clean)] then
            return clean
        end
    end

    local base = instance
    if base and base:IsA("Attachment") and base.Parent then
        base = base.Parent
    end

    if base and base:IsA("BasePart") and base.Parent and base.Parent ~= Workspace then
        local bNameLower = string.lower(base.Name)
        if GenericNames[bNameLower] or base.Parent:IsA("Model") then
            return base.Parent.Name
        end
    end

    if base then
        return base.Name
    end

    return "Item"
end

local function GetGuiParent()
    local ok, h = pcall(function() return gethui and gethui() end)
    if ok and h then return h end
    return CoreGui
end

local function AllowToxTeleport(seconds, reason)
    if getgenv().AllowToxTeleport then
        getgenv().AllowToxTeleport(seconds or 1.5, reason or "SOD")
    end
end

local function TeleportTo(targetCF, label)
    local character, humanoid, root = GetCharacterState()
    if not humanoid or humanoid.Health <= 0 or not root then
        CustomNotify("Character unavailable", Color3.fromRGB(255, 100, 100), 2)
        return false
    end

    if typeof(targetCF) == "Vector3" then
        targetCF = CFrame.new(targetCF)
    end
    if typeof(targetCF) ~= "CFrame" then return false end

    AllowToxTeleport(2.5, "SOD " .. tostring(label or "Teleport"))
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero

    local destCF = targetCF + Vector3.new(0, 2.5, 0)
    if character then
        character:PivotTo(destCF)
    else
        root.CFrame = destCF
    end

    task.defer(function()
        if root and root.Parent then
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end
    end)

    CustomNotify("Teleported to " .. tostring(label or "Target"), Color3.fromRGB(100, 255, 100), 2)
    return true
end

-- ==============================================================================
-- COLLAPSIBLE SECTIONS & CONTROLS UI
-- ==============================================================================

local function ApplySectionState(section)
    if typeof(section) ~= "table" then return end
    local collapsed = Settings.SODCollapsedSections[section.Key] == true

    if section.Header and section.Header.Parent then
        section.Header.Text = collapsed
            and "  > " .. section.Name
            or "  v " .. section.Name
    end

    for _, object in ipairs(section.Controls) do
        if object and object.Parent and object:IsA("GuiObject") then
            object.Visible = not collapsed
        end
    end
end

local function TrackControl(object)
    if SODCurrentSection and object and object:IsA("GuiObject") then
        table.insert(SODCurrentSection.Controls, object)
        ApplySectionState(SODCurrentSection)
    end
    return object
end

local function SODCreateToggle(...)
    return TrackControl(CreateToggle(...))
end

local function SODCreateToggleWithValue(...)
    return TrackControl(CreateToggleWithValue(...))
end

local function SODCreateButton(...)
    return TrackControl(CreateButton(...))
end

local function SODCreateDropdown(...)
    if CreateDropdown then
        return TrackControl(CreateDropdown(...))
    end
    return nil
end

local function CreateToggleWithChoiceLocal(Name, Page, Options, DefaultToggle, DefaultChoice, CallbackToggle, CallbackChoice, SyncKey)
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, -5, 0, 39)
    Container.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
    Container.BorderSizePixel = 0
    Container.Parent = Page

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -165, 1, 0)
    Label.Position = UDim2.new(0, 12, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = Name
    Label.TextColor3 = Color3.fromRGB(240, 240, 240)
    Label.TextSize = 13
    Label.Font = Enum.Font.GothamMedium
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Container

    local ChoiceButton = Instance.new("TextButton")
    ChoiceButton.Size = UDim2.new(0, 95, 0, 25)
    ChoiceButton.Position = UDim2.new(1, -150, 0.5, -12)
    ChoiceButton.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
    ChoiceButton.BorderSizePixel = 0
    ChoiceButton.Text = tostring(DefaultChoice)
    ChoiceButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ChoiceButton.TextSize = 12
    ChoiceButton.Font = Enum.Font.GothamBold
    ChoiceButton.Parent = Container
    local ChoiceCorner = Instance.new("UICorner") ChoiceCorner.CornerRadius = UDim.new(0, 4) ChoiceCorner.Parent = ChoiceButton

    local CurrentIdx = 1
    for i, opt in ipairs(Options) do
        if opt == DefaultChoice then
            CurrentIdx = i
            break
        end
    end

    ChoiceButton.MouseButton1Click:Connect(function()
        if getgenv().Destroyed or getgenv().ToxOptionsReady == false then return end
        CurrentIdx = CurrentIdx + 1
        if CurrentIdx > #Options then CurrentIdx = 1 end
        ChoiceButton.Text = tostring(Options[CurrentIdx])
        if CallbackChoice then
            CallbackChoice(Options[CurrentIdx])
        end
        AutoSaveConfiguration()
    end)

    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Size = UDim2.new(0, 38, 0, 20)
    ToggleButton.Position = UDim2.new(1, -48, 0.5, -10)
    ToggleButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    ToggleButton.BorderSizePixel = 0
    ToggleButton.Text = ""
    ToggleButton.AutoButtonColor = false
    ToggleButton.Parent = Container
    local ToggleCorner = Instance.new("UICorner") ToggleCorner.CornerRadius = UDim.new(0, 4) ToggleCorner.Parent = ToggleButton

    local Indicator = Instance.new("Frame")
    Indicator.Size = UDim2.new(0, 14, 0, 14)
    Indicator.Position = UDim2.new(0, 3, 0.5, -7)
    Indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Indicator.BorderSizePixel = 0
    Indicator.Parent = ToggleButton
    local IndicatorCorner = Instance.new("UICorner") IndicatorCorner.CornerRadius = UDim.new(0, 3) IndicatorCorner.Parent = Indicator

    local Enabled = getgenv().ToxOptionsReady == false and false or (DefaultToggle == true)

    local function UpdateToggle()
        if Enabled then
            ToggleButton.BackgroundColor3 = Color3.fromRGB(50, 180, 70)
            Indicator.Position = UDim2.new(1, -17, 0.5, -7)
        else
            ToggleButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
            Indicator.Position = UDim2.new(0, 3, 0.5, -7)
        end
    end

    local Controller = {
        Button = Container,
        SetVisual = function(Value)
            Enabled = Value == true
            UpdateToggle()
        end,
        SetValue = function(Value)
            ChoiceButton.Text = tostring(Value)
            for i, opt in ipairs(Options) do
                if opt == Value then
                    CurrentIdx = i
                    break
                end
            end
        end
    }

    if getgenv().RegisterSharedToggle then
        getgenv().RegisterSharedToggle(SyncKey, Controller)
    end
    if getgenv().RegisterStartupToggleCallback then
        getgenv().RegisterStartupToggleCallback(SyncKey, CallbackToggle)
    end

    ToggleButton.MouseButton1Click:Connect(function()
        if getgenv().Destroyed or getgenv().ToxOptionsReady == false then return end
        Enabled = not Enabled
        UpdateToggle()
        if CallbackToggle then
            CallbackToggle(Enabled)
        end
        if SyncKey and getgenv().SyncToggleVisuals then
            getgenv().SyncToggleVisuals(SyncKey, Enabled)
        end
        if getgenv().ScriptLoaded then
            CustomNotify(Name .. (Enabled and " Enabled" or " Disabled"), Enabled and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100))
        end
        AutoSaveConfiguration()
    end)

    UpdateToggle()

    if getgenv().RegisterToxSearchControl then
        getgenv().RegisterToxSearchControl(Name, Page, Container)
    end

    return Container
end

local function SODCreateToggleWithChoice(...)
    local fn = CreateToggleWithChoice or CreateToggleWithChoiceLocal
    return TrackControl(fn(...))
end

local function CreateSODSection(text)
    local name = tostring(text)
    local key = string.gsub(name, "%s+", "")
    local button = Instance.new("TextButton")

    button.Size = UDim2.new(1, -5, 0, 26)
    button.BackgroundColor3 = Color3.fromRGB(13, 13, 21)
    button.BorderSizePixel = 0
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 11
    button.TextXAlignment = Enum.TextXAlignment.Left
    button.AutoButtonColor = false
    button.Parent = GamePage

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = button

    local section = {
        Name = name,
        Key = key,
        Header = button,
        Controls = {}
    }

    table.insert(SODSections, section)
    SODCurrentSection = section

    TrackConnection(button.MouseButton1Click:Connect(function()
        Settings.SODCollapsedSections[key] = not Settings.SODCollapsedSections[key]
        ApplySectionState(section)
        AutoSaveConfiguration()
    end))

    ApplySectionState(section)
    return button
end

-- ==============================================================================
-- SCREEN WARNING RADAR (MONSTER PROXIMITY)
-- ==============================================================================

local function EnsureWarningUI()
    if WarnScreenGui and WarnScreenGui.Parent then return end

    local gui = Instance.new("ScreenGui")
    gui.Name = "ToxSODWarnRadar"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true

    if not pcall(function() gui.Parent = GetGuiParent() end) then
        gui.Parent = Player:WaitForChild("PlayerGui")
    end

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    frame.Visible = false
    frame.Active = false
    frame.Parent = gui

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 30, 45)
    stroke.Thickness = 10
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Transparency = 0.7
    stroke.Parent = frame

    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(0, 400, 0, 30)
    text.Position = UDim2.new(0.5, -200, 0, 45)
    text.BackgroundTransparency = 1
    text.TextColor3 = Color3.fromRGB(255, 65, 75)
    text.TextStrokeTransparency = 0.2
    text.Font = Enum.Font.GothamBold
    text.TextSize = 16
    text.Text = ""
    text.Parent = frame

    WarnScreenGui = gui
    WarnFrame = frame
    WarnStroke = stroke
    WarnText = text
end

EnsureWarningUI()

local function UpdateMonsterWarning(closestDist, monsterLabel)
    if not WarnFrame or not WarnFrame.Parent then return end
    if not Settings.SODMonsterWarn then
        WarnFrame.Visible = false
        return
    end

    if closestDist and closestDist <= Settings.SODMonsterWarnDistance then
        WarnFrame.Visible = true
        WarnText.Text = string.format("MONSTER [%s]: %dm", string.upper(tostring(monsterLabel or "ENTITY")), math.floor(closestDist))
        local alpha = 1 - math.clamp(closestDist / Settings.SODMonsterWarnDistance, 0, 1)
        local pulse = (math.sin(os.clock() * (6 + 8 * alpha)) + 1) / 2
        WarnStroke.Transparency = 1 - (0.4 + 0.5 * alpha) * (0.5 + 0.5 * pulse)
    else
        WarnFrame.Visible = false
    end
end

-- ==============================================================================
-- LIGHTING & VISION MODIFIERS
-- ==============================================================================

local function ApplyFullBright()
    Lighting.Brightness = 2
    Lighting.ClockTime = 14
    Lighting.FogEnd = 1e6
    Lighting.GlobalShadows = false
    Lighting.OutdoorAmbient = Color3.fromRGB(160, 160, 160)
    Lighting.Ambient = Color3.fromRGB(145, 145, 145)

    for _, child in ipairs(Lighting:GetChildren()) do
        if child:IsA("Atmosphere") or child:IsA("ColorCorrectionEffect") or child:IsA("BlurEffect") then
            if child:GetAttribute("ToxDisabled") == nil then
                child:SetAttribute("ToxDisabled", child.Enabled)
                pcall(function() child.Enabled = false end)
            end
        end
    end
end

local function RestoreLighting()
    Lighting.Brightness = OrigLightingProps.Brightness or 1
    Lighting.ClockTime = OrigLightingProps.ClockTime or 12
    Lighting.FogEnd = OrigLightingProps.FogEnd or 1000
    Lighting.GlobalShadows = OrigLightingProps.GlobalShadows ~= false
    Lighting.OutdoorAmbient = OrigLightingProps.OutdoorAmbient or Color3.fromRGB(128, 128, 128)
    Lighting.Ambient = OrigLightingProps.Ambient or Color3.fromRGB(0, 0, 0)

    for _, child in ipairs(Lighting:GetChildren()) do
        if child:GetAttribute("ToxDisabled") ~= nil then
            pcall(function() child.Enabled = child:GetAttribute("ToxDisabled") end)
            child:SetAttribute("ToxDisabled", nil)
        end
    end
end

-- ==============================================================================
-- INTERACTION & PROXIMITY PROMPT ENGINE
-- ==============================================================================

local function SetInstantPrompt(prompt, enable)
    if not prompt then return end
    pcall(function()
        if enable then
            if OrigHoldDurations[prompt] == nil then
                OrigHoldDurations[prompt] = prompt.HoldDuration
            end
            if prompt.HoldDuration ~= 0 then
                prompt.HoldDuration = 0
            end
            prompt.RequiresLineOfSight = false
        elseif OrigHoldDurations[prompt] ~= nil then
            prompt.HoldDuration = OrigHoldDurations[prompt]
            OrigHoldDurations[prompt] = nil
        end
    end)
end

local function TriggerPrompt(prompt)
    if not prompt or not prompt.Parent then return false end
    pcall(function()
        prompt.HoldDuration = 0
    end)
    if fireproximityprompt then
        pcall(function()
            fireproximityprompt(prompt, 0, true)
        end)
        return true
    elseif prompt.InputHoldBegin and prompt.InputHoldEnd then
        pcall(function()
            prompt:InputHoldBegin()
            task.wait(0.01)
            prompt:InputHoldEnd()
        end)
        return true
    end
    return false
end

-- Global ProximityPromptService hook for instant vent and steal
pcall(function()
    TrackConnection(ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt, plr)
        if plr ~= Player then return end
        local act = prompt.ActionText and string.lower(prompt.ActionText) or ""
        local pName = prompt.Parent and string.lower(prompt.Parent.Name) or ""
        local isVent = VentObjects[prompt] or string.find(act, "unscrew") or string.find(pName, "vent")
        local isCloset = (prompt.Parent and ClosetObjects[prompt.Parent]) or string.find(act, "hide")

        if Settings.SODInstantVent and isVent then
            pcall(function()
                prompt.HoldDuration = 0
                if fireproximityprompt then
                    fireproximityprompt(prompt, 0, true)
                elseif prompt.InputHoldBegin and prompt.InputHoldEnd then
                    prompt:InputHoldBegin()
                    task.wait(0.01)
                    prompt:InputHoldEnd()
                end
            end)
        elseif Settings.SODInstantSteal and not isCloset then
            -- Triggers instant steal/collect on press
            pcall(function()
                prompt.HoldDuration = 0
                if fireproximityprompt then
                    fireproximityprompt(prompt, 0, true)
                elseif prompt.InputHoldBegin and prompt.InputHoldEnd then
                    prompt:InputHoldBegin()
                    task.wait(0.01)
                    prompt:InputHoldEnd()
                end
            end)
        end
    end))
end)

-- ==============================================================================
-- LOOT & OBJECT REGISTRATION
-- ==============================================================================

local function IsLootObject(prompt, instance, nameLower)
    if not prompt or not instance then return false end

    local action = prompt.ActionText and string.lower(prompt.ActionText) or ""
    if action ~= "" then
        if string.find(action, "door") or string.find(action, "unscrew") or string.find(action, "hide") then
            return false
        end
        if string.find(action, "steal")
        or string.find(action, "take")
        or string.find(action, "grab")
        or string.find(action, "loot")
        or string.find(action, "pick")
        or string.find(action, "search")
        or string.find(action, "collect")
        or string.find(action, "bag") then
            return true
        end
    end

    if nameLower and HasSubstring(nameLower, NonLootKeywords) then
        return false
    end

    if prompt.ObjectText and prompt.ObjectText ~= "" then
        local objLower = string.lower(prompt.ObjectText)
        if not HasSubstring(objLower, NonLootKeywords) then
            return true
        end
    end

    if instance:GetAttribute("Value") ~= nil
    or instance:GetAttribute("Price") ~= nil
    or instance:GetAttribute("Worth") ~= nil
    or instance:GetAttribute("Rarity") ~= nil then
        return true
    end

    if nameLower and HasSubstring(nameLower, LootKeywords) then
        return true
    end

    local parent = instance.Parent
    if parent and parent ~= Workspace then
        if parent:GetAttribute("Value") ~= nil or parent:GetAttribute("Rarity") ~= nil then
            return true
        end
        local pName = string.lower(parent.Name)
        if not HasSubstring(pName, NonLootKeywords) and HasSubstring(pName, LootKeywords) then
            return true
        end
    end

    if not HasSubstring(nameLower, NonLootKeywords) then
        return true
    end

    return false
end

local function IsDescendantOfAnyPlayer(inst)
    if not inst then return false end
    if Player.Character and inst:IsDescendantOf(Player.Character) then
        return true
    end
    local bp = Player:FindFirstChild("Backpack")
    if bp and inst:IsDescendantOf(bp) then
        return true
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Player then
            if plr.Character and inst:IsDescendantOf(plr.Character) then
                return true
            end
            local pbp = plr:FindFirstChild("Backpack")
            if pbp and inst:IsDescendantOf(pbp) then
                return true
            end
        end
    end
    return false
end

local function RegisterPrompt(prompt)
    if not prompt or not prompt.Parent then return end
    if ItemPrompts[prompt] or VentObjects[prompt] then return end

    -- NEVER register prompts that are on or inside any player character or backpack
    if IsDescendantOfAnyPlayer(prompt) or IsDescendantOfAnyPlayer(prompt.Parent) then
        return
    end

    local instance = prompt.Parent
    local part = ResolveBasePart(prompt) or ResolveBasePart(instance)
    if not part or IsDescendantOfAnyPlayer(part) then return end

    local name = ResolveItemName(prompt, instance)
    local nameLower = string.lower(name)

    -- Detect decorative signs/lights/plaques so they are never classified as exits or loot
    local isSignOrProp = string.find(nameLower, "sign") or string.find(nameLower, "plaque") or string.find(nameLower, "placa")
                      or string.find(nameLower, "light") or string.find(nameLower, "lamp") or string.find(nameLower, "poster")
                      or string.find(nameLower, "decal") or string.find(nameLower, "board") or string.find(nameLower, "frame")
                      or string.find(nameLower, "billboard") or string.find(nameLower, "texture")

    -- Vent
    if string.find(nameLower, "vent") or (prompt.ActionText and string.find(string.lower(prompt.ActionText), "unscrew")) then
        VentObjects[prompt] = {
            Part = part,
            Prompt = prompt,
            Name = name
        }
        if Settings.SODInstantVent then
            SetInstantPrompt(prompt, true)
        end
        TrackConnection(prompt:GetPropertyChangedSignal("HoldDuration"):Connect(function()
            if Settings.SODInstantVent and prompt.HoldDuration ~= 0 then
                prompt.HoldDuration = 0
            end
        end))
        return
    end

    -- Closet
    if string.find(nameLower, "closet") or string.find(nameLower, "locker") or string.find(nameLower, "wardrobe") or string.find(nameLower, "hidespot")
    or (prompt.ActionText and string.find(string.lower(prompt.ActionText), "hide")) then
        ClosetObjects[instance] = {
            Part = part,
            Model = instance:IsA("Model") and instance or instance.Parent,
            Name = name
        }
        return
    end

    -- Exit (Must NOT be a wall sign or light plaque)
    if not isSignOrProp and (
        (prompt.ActionText and (string.find(string.lower(prompt.ActionText), "escape") or string.find(string.lower(prompt.ActionText), "extract") or string.find(string.lower(prompt.ActionText), "leave") or string.find(string.lower(prompt.ActionText), "evac") or string.find(string.lower(prompt.ActionText), "drive")))
        or string.find(nameLower, "van") or string.find(nameLower, "truck")
        or (string.find(nameLower, "exit") and not string.find(nameLower, "sign"))
    ) then
        ExitObjects[instance] = {
            Part = part,
            Model = instance:IsA("Model") and instance or (instance.Parent:IsA("Model") and instance.Parent or part),
            Label = name
        }
        return
    end

    -- Loot
    if IsLootObject(prompt, instance, nameLower) then
        local rarity, val, weight = ResolveItemData(prompt, instance, nameLower)
        local itemModel = GetItemModel(prompt) or GetItemModel(instance) or (instance:IsA("Model") and instance or nil)

        ItemPrompts[prompt] = {
            Object = instance,
            Model = itemModel,
            Part = part,
            Name = name,
            NameLower = nameLower,
            Rarity = rarity,
            Value = val,
            Weight = weight
        }

        if Settings.SODInstantSteal then
            SetInstantPrompt(prompt, true)
        end

        TrackConnection(prompt:GetPropertyChangedSignal("HoldDuration"):Connect(function()
            if Settings.SODInstantSteal and prompt.HoldDuration ~= 0 then
                prompt.HoldDuration = 0
            end
        end))
    end
end

local function UnregisterPrompt(prompt)
    SetInstantPrompt(prompt, false)
    ItemPrompts[prompt] = nil
    VentObjects[prompt] = nil

    if ItemESPObjects[prompt] then
        pcall(function() ItemESPObjects[prompt].Billboard:Destroy() end)
        ItemESPObjects[prompt] = nil
    end
    if ItemChamsObjects[prompt] then
        pcall(function() ItemChamsObjects[prompt]:Destroy() end)
        ItemChamsObjects[prompt] = nil
    end
    if VentESPObjects[prompt] then
        pcall(function() VentESPObjects[prompt].Billboard:Destroy() end)
        VentESPObjects[prompt] = nil
    end
end

-- ==============================================================================
-- MONSTER & ENTITY REGISTRATION
-- ==============================================================================

local function IsMonsterEntity(model)
    if not model or not model:IsA("Model") then return false end
    if model == Player.Character then return false end

    local nameLower = string.lower(model.Name)

    -- CRITICAL FIX: Exclude doors, gates, rooms, spawns, props, barriers, etc.
    if HasSubstring(nameLower, NonMonsterKeywords) then
        return false
    end

    local plr = Players:GetPlayerFromCharacter(model)
    if plr then
        if plr:GetAttribute("IsEntity") == true then
            return true, plr.DisplayName or plr.Name, plr:GetAttribute("EntityKind") or "PLAYER_MONSTER"
        end
        local kind = plr:GetAttribute("EntityKind")
        if typeof(kind) == "string" and kind ~= "" then
            return true, plr.DisplayName or plr.Name, kind
        end
        return false
    end

    -- Real NPC monsters must have a Humanoid or AnimationController
    local hum = model:FindFirstChildOfClass("Humanoid")
    local anim = model:FindFirstChildOfClass("AnimationController")
    if not hum and not anim then
        if model:GetAttribute("IsEntity") ~= true and model:GetAttribute("EntityKind") == nil then
            return false
        end
    end

    if model:GetAttribute("IsEntity") == true then
        return true, model.Name, model:GetAttribute("EntityKind") or "ENTITY"
    end

    local charKind = model:GetAttribute("EntityKind")
    if typeof(charKind) == "string" and charKind ~= "" then
        return true, model.Name, charKind
    end

    if HasSubstring(nameLower, MonsterKeywords) then
        return true, model.Name, "ENTITY"
    end

    return false
end

local function RegisterMonster(model)
    if ActiveMonsters[model] then return end
    local isMon, name, kind = IsMonsterEntity(model)
    if not isMon then return end

    local root = model:FindFirstChild("HumanoidRootPart")
        or model.PrimaryPart
        or model:FindFirstChildWhichIsA("BasePart")

    if not root then return end

    ActiveMonsters[model] = {
        Model = model,
        Root = root,
        Name = name,
        Kind = kind or "ENTITY",
        IsPlayer = Players:GetPlayerFromCharacter(model) ~= nil
    }
end

local function UnregisterMonster(model)
    ActiveMonsters[model] = nil
    if MonsterESPObjects[model] then
        pcall(function()
            MonsterESPObjects[model].Highlight:Destroy()
            MonsterESPObjects[model].Billboard:Destroy()
        end)
        MonsterESPObjects[model] = nil
    end
end

-- ==============================================================================
-- WORKSPACE DISCOVERY & SCANNING
-- ==============================================================================

local function IsDoorPart(inst)
    if not inst or not inst:IsA("BasePart") then return false end
    local name = string.lower(inst.Name)
    local parentName = inst.Parent and string.lower(inst.Parent.Name) or ""

    if Player and Player.Character and inst:IsDescendantOf(Player.Character) then
        return false
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character and inst:IsDescendantOf(plr.Character) then
            return false
        end
    end

    if string.find(name, "door") or string.find(name, "gate") or string.find(name, "barricade")
    or string.find(parentName, "door") or string.find(parentName, "gate") or string.find(parentName, "barricade") then
        return true
    end
    return false
end

local function ApplyRemoveDoors(enable)
    if enable then
        for _, inst in ipairs(Workspace:GetDescendants()) do
            if IsDoorPart(inst) then
                if DoorObjects[inst] == nil then
                    DoorObjects[inst] = {
                        CanCollide = inst.CanCollide,
                        Transparency = inst.Transparency
                    }
                end
                pcall(function()
                    inst.CanCollide = false
                    if inst.Transparency < 0.45 then
                        inst.Transparency = 0.5
                    end
                end)
            end
        end
    else
        for inst, orig in pairs(DoorObjects) do
            if inst and inst.Parent then
                pcall(function()
                    inst.CanCollide = orig.CanCollide
                    inst.Transparency = orig.Transparency
                end)
            end
        end
        table.clear(DoorObjects)
    end
end

local function HandleDescendant(obj)
    if obj:IsA("ProximityPrompt") then
        RegisterPrompt(obj)
    elseif obj:IsA("BasePart") then
        if Settings.SODRemoveDoors and IsDoorPart(obj) then
            if DoorObjects[obj] == nil then
                DoorObjects[obj] = {
                    CanCollide = obj.CanCollide,
                    Transparency = obj.Transparency
                }
            end
            pcall(function()
                obj.CanCollide = false
                if obj.Transparency < 0.45 then
                    obj.Transparency = 0.5
                end
            end)
        end
    elseif obj:IsA("Model") then
        if IsMonsterEntity(obj) then
            RegisterMonster(obj)
        end
        local mName = string.lower(obj.Name)

        -- Exclude decorative signs, lights, plaques, posters, decals, frames, walls, and ceilings
        local isSignOrProp = string.find(mName, "sign") or string.find(mName, "plaque") or string.find(mName, "placa")
                          or string.find(mName, "light") or string.find(mName, "lamp") or string.find(mName, "poster")
                          or string.find(mName, "decal") or string.find(mName, "arrow") or string.find(mName, "board")
                          or string.find(mName, "frame") or string.find(mName, "billboard") or string.find(mName, "texture")
                          or string.find(mName, "mesh") or string.find(mName, "glass") or string.find(mName, "wall")
                          or string.find(mName, "ceiling")

        if string.find(mName, "closet") or string.find(mName, "locker") or string.find(mName, "wardrobe") or string.find(mName, "hidespot") then
            ClosetObjects[obj] = {
                Part = ResolveBasePart(obj),
                Model = obj,
                Name = obj.Name
            }
        elseif not isSignOrProp and (
            string.find(mName, "van") or string.find(mName, "truck")
            or string.find(mName, "escape") or string.find(mName, "extract") or string.find(mName, "evac")
            or (string.find(mName, "exit") and not isSignOrProp)
        ) then
            local p = ResolveBasePart(obj)
            local isRealExit = true
            -- A true exit zone or exit door/van has substantial size, not a thin plate
            if p and string.find(mName, "exit") and not (string.find(mName, "van") or string.find(mName, "truck") or string.find(mName, "zone")) then
                if (p.Size.X < 3 and p.Size.Z < 3) or (p.Size.Y < 1 and (p.Size.X < 3 or p.Size.Z < 3)) then
                    isRealExit = false
                end
            end
            if isRealExit then
                ExitObjects[obj] = {
                    Part = p,
                    Model = obj,
                    Label = obj.Name
                }
            end
        end
    end
end

TrackConnection(Workspace.DescendantAdded:Connect(function(d)
    pcall(HandleDescendant, d)
end))

TrackConnection(ProximityPromptService.PromptShown:Connect(function(prompt)
    if prompt and not ItemPrompts[prompt] and not VentObjects[prompt] then
        pcall(RegisterPrompt, prompt)
    end
    if prompt and Settings.SODInstantSteal then
        local act = prompt.ActionText and string.lower(prompt.ActionText) or ""
        local pName = prompt.Parent and string.lower(prompt.Parent.Name) or ""
        local isVent = string.find(act, "unscrew") or string.find(pName, "vent")
        local isCloset = string.find(act, "hide") or string.find(pName, "closet")
        if not isVent and not isCloset then
            pcall(function()
                prompt.HoldDuration = 0
                prompt.RequiresLineOfSight = false
            end)
        end
    end
    if prompt and Settings.SODInstantVent then
        local act = prompt.ActionText and string.lower(prompt.ActionText) or ""
        local pName = prompt.Parent and string.lower(prompt.Parent.Name) or ""
        if string.find(act, "unscrew") or string.find(pName, "vent") then
            pcall(function()
                prompt.HoldDuration = 0
                prompt.RequiresLineOfSight = false
            end)
        end
    end
end))

TrackConnection(Workspace.DescendantRemoving:Connect(function(d)
    if d:IsA("ProximityPrompt") then
        UnregisterPrompt(d)
    elseif d:IsA("Model") then
        UnregisterMonster(d)
        ClosetObjects[d] = nil
        ExitObjects[d] = nil
    end
end))

task.spawn(function()
    for _, d in ipairs(Workspace:GetDescendants()) do
        pcall(HandleDescendant, d)
    end
end)

-- ==============================================================================
-- ESP RENDERING & VISUAL ENGINE
-- ==============================================================================

local function MatchesRarityFilter(rarity, value)
    local rank = RarityRank[rarity] or 1
    local minRank = FilterMinRank[Settings.SODRarityFilter] or 1

    if rank < minRank then
        return false
    end

    if Settings.SODMinValueEnabled and value and value > 0 then
        if value < Settings.SODMinValue then
            return false
        end
    end

    return true
end

local function IsPartOfLocalPlayer(inst)
    if not inst then return false end
    local char = Player.Character
    if not char then return false end
    if inst == char or inst:IsDescendantOf(char) then return true end
    local root = char:FindFirstChild("HumanoidRootPart")
    if inst:IsA("BasePart") and root and inst.AssemblyRootPart == root.AssemblyRootPart then
        return true
    end
    return false
end

local function CreateOrUpdateHighlight(instance, color, name)
    if not instance or not instance.Parent then return nil end
    if IsPartOfLocalPlayer(instance) then return nil end
    local hlName = name or "ToxSOD_HL"
    local hl = instance:FindFirstChild(hlName)
    if not hl or not hl:IsA("Highlight") then
        hl = Instance.new("Highlight")
        hl.Name = hlName
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.FillTransparency = 0.38
        hl.OutlineTransparency = 0.08
        hl.Adornee = instance
        hl.Parent = instance
    else
        if hl.Adornee ~= instance then
            hl.Adornee = instance
        end
    end
    if hl.FillColor ~= color then
        hl.FillColor = color
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    end
    if not hl.Enabled then
        hl.Enabled = true
    end
    return hl
end

local function CreateOrUpdateBillboard(adornee, name, text, color, offset)
    if not adornee or not adornee.Parent or IsPartOfLocalPlayer(adornee) then return nil end
    local bb = adornee:FindFirstChild(name)
    local label = nil
    local textSize = tonumber(Settings.SODESPTextSize) or 10
    local maxDist = tonumber(Settings.SODESPMaxDistance) or 350

    if not bb or not bb:IsA("BillboardGui") then
        bb = Instance.new("BillboardGui")
        bb.Name = name
        bb.Size = UDim2.new(0, 160, 0, 28)
        bb.StudsOffset = offset or Vector3.new(0, 2.0, 0)
        bb.AlwaysOnTop = true
        bb.MaxDistance = maxDist
        bb.Adornee = adornee

        label = Instance.new("TextLabel")
        label.Name = "Label"
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.GothamBold
        label.TextSize = textSize
        label.TextStrokeTransparency = 0.2
        label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        label.Parent = bb
        bb.Parent = adornee
    else
        label = bb:FindFirstChild("Label")
    end

    if bb then
        if offset and bb.StudsOffset ~= offset then
            bb.StudsOffset = offset
        end
        if bb.MaxDistance ~= maxDist then
            bb.MaxDistance = maxDist
        end
    end

    if label then
        if label.TextSize ~= textSize then
            label.TextSize = textSize
        end
        if label.Text ~= text then
            label.Text = text
        end
        if label.TextColor3 ~= color then
            label.TextColor3 = color
        end
    end
    if not bb.Enabled then
        bb.Enabled = true
    end
    return bb, label
end

local function UpdateItemESP(charRoot)
    local handledTargets = {}
    local style = Settings.SODItemESPStyle or "Name + Value"

    -- Active purge: Remove ANY Item Highlight or Item Billboard accidentally attached to the local player's character
    if Player.Character then
        for _, child in ipairs(Player.Character:GetDescendants()) do
            if child:IsA("Highlight") and child.Name == "ToxSOD_ItemHL" then
                pcall(function() child:Destroy() end)
            end
            if child:IsA("BillboardGui") and child.Name == "ToxSOD_ItemBB" then
                pcall(function() child:Destroy() end)
            end
        end
    end

    for prompt, data in pairs(ItemPrompts) do
        local part = data.Part
        local itemModel = data.Model or GetItemModel(prompt) or GetItemModel(part)
        local targetInst = itemModel or part

        local isInvalid = not prompt.Parent or not part or not part.Parent
            or IsDescendantOfAnyPlayer(prompt)
            or IsDescendantOfAnyPlayer(part)
            or (targetInst and IsDescendantOfAnyPlayer(targetInst))
            or (targetInst and targetInst:IsA("Model") and targetInst:FindFirstChildOfClass("Humanoid") ~= nil)

        if isInvalid then
            if ItemESPObjects[prompt] then
                pcall(function()
                    if ItemESPObjects[prompt].Highlight then ItemESPObjects[prompt].Highlight:Destroy() end
                    if ItemESPObjects[prompt].Billboard then ItemESPObjects[prompt].Billboard:Destroy() end
                end)
                ItemESPObjects[prompt] = nil
            end
            ItemPrompts[prompt] = nil
        else
            -- Prevent multiple ESP objects on the exact same item model/part
            if targetInst and handledTargets[targetInst] then
                if ItemESPObjects[prompt] then
                    if ItemESPObjects[prompt].Highlight then ItemESPObjects[prompt].Highlight.Enabled = false end
                    if ItemESPObjects[prompt].Billboard then ItemESPObjects[prompt].Billboard.Enabled = false end
                end
                continue
            end
            if targetInst then
                handledTargets[targetInst] = true
            end

            local show = Settings.SODItemESP and prompt.Enabled and MatchesRarityFilter(data.Rarity, data.Value)
            local dist = charRoot and (part.Position - charRoot.Position).Magnitude or 0
            local maxDist = tonumber(Settings.SODESPMaxDistance) or 350

            if show and dist <= maxDist then
                local rColor = RarityColors[data.Rarity] or Color3.fromRGB(220, 220, 220)

                -- 3D Chams on entire Model (all sub-parts of the item glow with chams)
                local hl = CreateOrUpdateHighlight(targetInst, rColor, "ToxSOD_ItemHL")

                local bb = nil
                local label = nil

                if style == "Chams Only" then
                    -- User requested Chams Only: hide any billboard text for total visual cleanliness
                    if ItemESPObjects[prompt] and ItemESPObjects[prompt].Billboard then
                        ItemESPObjects[prompt].Billboard.Enabled = false
                    end
                elseif style == "Value Only" then
                    -- User requested Value Only: compact price tag
                    local tagText = string.format("%s (%dm)", FormatCurrency(data.Value), math.floor(dist))
                    local offset = dist < 7 and Vector3.new(0, 2.8, 0) or Vector3.new(0, 1.8, 0)
                    bb, label = CreateOrUpdateBillboard(part, "ToxSOD_ItemBB", tagText, rColor, offset)
                else
                    -- Name + Value: full informative label
                    local tagText = string.format("[%s] %s\n%s (%dm)", string.upper(data.Rarity or "COMMON"), data.Name, FormatCurrency(data.Value), math.floor(dist))
                    local offset = dist < 7 and Vector3.new(0, 3.0, 0) or Vector3.new(0, 1.8, 0)
                    bb, label = CreateOrUpdateBillboard(part, "ToxSOD_ItemBB", tagText, rColor, offset)
                end

                ItemESPObjects[prompt] = { Highlight = hl, Billboard = bb, Label = label }
            else
                if ItemESPObjects[prompt] then
                    if ItemESPObjects[prompt].Highlight then ItemESPObjects[prompt].Highlight.Enabled = false end
                    if ItemESPObjects[prompt].Billboard then ItemESPObjects[prompt].Billboard.Enabled = false end
                end
            end
        end
    end
end

local function UpdateMonsterESP(charRoot)
    local closestDist = nil
    local closestMonsterName = "ENTITY"

    for model, data in pairs(ActiveMonsters) do
        if not model.Parent or not data.Root or not data.Root.Parent then
            if MonsterESPObjects[model] then
                pcall(function()
                    if MonsterESPObjects[model].Highlight then MonsterESPObjects[model].Highlight:Destroy() end
                    if MonsterESPObjects[model].Billboard then MonsterESPObjects[model].Billboard:Destroy() end
                end)
                MonsterESPObjects[model] = nil
            end
        else
            local dist = charRoot and (data.Root.Position - charRoot.Position).Magnitude or 9999
            if not closestDist or dist < closestDist then
                closestDist = dist
                closestMonsterName = data.Kind or data.Name
            end

            if Settings.SODMonsterESP then
                local red = Color3.fromRGB(255, 35, 45)
                local hl = CreateOrUpdateHighlight(model, red, "ToxSOD_MonsterHL")
                local tagText = string.format("%s (%dm)", data.Name or "Monster", math.floor(dist))
                local bb, label = CreateOrUpdateBillboard(data.Root, "ToxSOD_MonsterBB", tagText, red, Vector3.new(0, 3.2, 0))
                MonsterESPObjects[model] = { Highlight = hl, Billboard = bb, Label = label }
            else
                if MonsterESPObjects[model] then
                    if MonsterESPObjects[model].Highlight then MonsterESPObjects[model].Highlight.Enabled = false end
                    if MonsterESPObjects[model].Billboard then MonsterESPObjects[model].Billboard.Enabled = false end
                end
            end
        end
    end

    if WarnFrame then
        local warnDist = tonumber(Settings.SODMonsterWarnDistance) or 60
        if Settings.SODMonsterWarn and closestDist and closestDist <= warnDist then
            WarnFrame.Visible = true
            WarnText.Text = string.format("WARNING: %s IS %d STUDS AWAY!", string.upper(closestMonsterName), math.floor(closestDist))
        else
            WarnFrame.Visible = false
        end
    end

    return closestDist
end

local function UpdatePlayerESP(charRoot)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Player then
            local char = plr.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")

            -- If player is a monster, Monster ESP handles them with red highlight and tag
            local isMonster = (char and ActiveMonsters[char] ~= nil) or plr:GetAttribute("IsEntity") == true or plr:GetAttribute("EntityKind") ~= nil

            if char and hum and root and hum.Health > 0 and not isMonster then
                if Settings.SODPlayerESP then
                    local dist = charRoot and (root.Position - charRoot.Position).Magnitude or 0
                    local cyan = Color3.fromRGB(0, 195, 255)

                    local hl = CreateOrUpdateHighlight(char, cyan, "ToxSOD_PlayerHL")
                    local tagText = string.format("%s (%dm)", plr.DisplayName or plr.Name, math.floor(dist))
                    local bb, label = CreateOrUpdateBillboard(root, "ToxSOD_PlayerBB", tagText, cyan, Vector3.new(0, 3.0, 0))

                    PlayerESPObjects[plr] = { Highlight = hl, Billboard = bb, Label = label }
                else
                    if PlayerESPObjects[plr] then
                        if PlayerESPObjects[plr].Highlight then PlayerESPObjects[plr].Highlight.Enabled = false end
                        if PlayerESPObjects[plr].Billboard then PlayerESPObjects[plr].Billboard.Enabled = false end
                    end
                end
            else
                if PlayerESPObjects[plr] then
                    pcall(function()
                        if PlayerESPObjects[plr].Highlight then PlayerESPObjects[plr].Highlight:Destroy() end
                        if PlayerESPObjects[plr].Billboard then PlayerESPObjects[plr].Billboard:Destroy() end
                    end)
                    PlayerESPObjects[plr] = nil
                end
            end
        end
    end
end

local function UpdateExitESP(charRoot)
    for inst, data in pairs(ExitObjects) do
        local part = data.Part
        local labelLower = string.lower(data.Label or inst.Name or "")
        local isSign = string.find(labelLower, "sign") or string.find(labelLower, "plaque") or string.find(labelLower, "placa")
                    or string.find(labelLower, "light") or string.find(labelLower, "lamp") or string.find(labelLower, "poster")
                    or string.find(labelLower, "decal") or string.find(labelLower, "arrow")

        if not inst.Parent or not part or not part.Parent or isSign then
            if ExitESPObjects[inst] then
                pcall(function()
                    if ExitESPObjects[inst].Highlight then ExitESPObjects[inst].Highlight:Destroy() end
                    if ExitESPObjects[inst].Billboard then ExitESPObjects[inst].Billboard:Destroy() end
                end)
                ExitESPObjects[inst] = nil
            end
            if isSign then
                ExitObjects[inst] = nil
            end
        else
            if Settings.SODExitESP then
                local dist = charRoot and (part.Position - charRoot.Position).Magnitude or 0
                local targetModel = data.Model or (inst:IsA("Model") and inst or (part.Parent:IsA("Model") and part.Parent or part))
                local neonGreen = Color3.fromRGB(0, 255, 140)

                -- 3D Chams on the real exit model
                local hl = CreateOrUpdateHighlight(targetModel, neonGreen, "ToxSOD_ExitHL")

                -- Tag on the exit
                local bb, label = CreateOrUpdateBillboard(part, "ToxSOD_ExitBB", string.format("[EXIT] %s (%dm)", data.Label or "Extraction", math.floor(dist)), neonGreen, Vector3.new(0, 3.2, 0))

                ExitESPObjects[inst] = { Highlight = hl, Billboard = bb, Label = label }
            else
                if ExitESPObjects[inst] then
                    if ExitESPObjects[inst].Highlight then ExitESPObjects[inst].Highlight.Enabled = false end
                    if ExitESPObjects[inst].Billboard then ExitESPObjects[inst].Billboard.Enabled = false end
                end
            end
        end
    end
end

local function UpdateVentClosetESP(charRoot)
    -- Vents
    for prompt, data in pairs(VentObjects) do
        local part = data.Part
        if not prompt.Parent or not part or not part.Parent then
            if VentESPObjects[prompt] then
                pcall(function()
                    if VentESPObjects[prompt].Highlight then VentESPObjects[prompt].Highlight:Destroy() end
                    if VentESPObjects[prompt].Billboard then VentESPObjects[prompt].Billboard:Destroy() end
                end)
                VentESPObjects[prompt] = nil
            end
        else
            if Settings.SODVentClosetESP then
                local dist = charRoot and (part.Position - charRoot.Position).Magnitude or 0
                local orange = Color3.fromRGB(255, 170, 30)

                local hl = CreateOrUpdateHighlight(part, orange, "ToxSOD_VentHL")
                local bb, label = CreateOrUpdateBillboard(part, "ToxSOD_VentBB", string.format("[VENT] (%dm)", math.floor(dist)), orange, Vector3.new(0, 1.8, 0))
                VentESPObjects[prompt] = { Highlight = hl, Billboard = bb, Label = label }
            else
                if VentESPObjects[prompt] then
                    if VentESPObjects[prompt].Highlight then VentESPObjects[prompt].Highlight.Enabled = false end
                    if VentESPObjects[prompt].Billboard then VentESPObjects[prompt].Billboard.Enabled = false end
                end
            end
        end
    end

    -- Closets
    for inst, data in pairs(ClosetObjects) do
        local part = data.Part
        if not inst.Parent or not part or not part.Parent then
            if ClosetESPObjects[inst] then
                pcall(function()
                    if ClosetESPObjects[inst].Highlight then ClosetESPObjects[inst].Highlight:Destroy() end
                    if ClosetESPObjects[inst].Billboard then ClosetESPObjects[inst].Billboard:Destroy() end
                end)
                ClosetESPObjects[inst] = nil
            end
        else
            if Settings.SODVentClosetESP then
                local dist = charRoot and (part.Position - charRoot.Position).Magnitude or 0
                local purple = Color3.fromRGB(180, 70, 255)
                local targetModel = data.Model or part

                local hl = CreateOrUpdateHighlight(targetModel, purple, "ToxSOD_ClosetHL")
                local bb, label = CreateOrUpdateBillboard(part, "ToxSOD_ClosetBB", string.format("[CLOSET] (%dm)", math.floor(dist)), purple, Vector3.new(0, 2.5, 0))
                ClosetESPObjects[inst] = { Highlight = hl, Billboard = bb, Label = label }
            else
                if ClosetESPObjects[inst] then
                    if ClosetESPObjects[inst].Highlight then ClosetESPObjects[inst].Highlight.Enabled = false end
                    if ClosetESPObjects[inst].Billboard then ClosetESPObjects[inst].Billboard.Enabled = false end
                end
            end
        end
    end
end

local function RefillStamina()
    local char, hum = GetCharacterState()
    local targets = { Player }
    if char then table.insert(targets, char) end
    if hum then table.insert(targets, hum) end

    for _, target in ipairs(targets) do
        for k, v in pairs(target:GetAttributes()) do
            local kLower = string.lower(k)
            if typeof(v) == "number" and string.find(kLower, "stamina") and not string.find(kLower, "max") and not string.find(kLower, "regen") and not string.find(kLower, "cost") then
                local maxVal = target:GetAttribute("MaxStamina") or 100
                if v < maxVal then
                    target:SetAttribute(k, maxVal)
                end
            end
        end
        for _, child in ipairs(target:GetChildren()) do
            if (child:IsA("NumberValue") or child:IsA("IntValue")) and string.find(string.lower(child.Name), "stamina") and not string.find(string.lower(child.Name), "max") then
                local maxVal = 100
                local maxChild = target:FindFirstChild("MaxStamina")
                if maxChild and (maxChild:IsA("NumberValue") or maxChild:IsA("IntValue")) then
                    maxVal = maxChild.Value
                end
                if child.Value < maxVal then
                    child.Value = maxVal
                end
            end
        end
    end
end

local function EnforceSpeed()
    if not Settings.SODSpeedBoost then return end
    local _, hum = GetCharacterState()
    if hum and hum.Health > 0 then
        local target = tonumber(Settings.SODSpeedValue) or 22
        if hum.WalkSpeed < target then
            hum.WalkSpeed = target
        end
    end
end

local function AutoStealAura(charRoot)
    if not Settings.SODAutoSteal or not charRoot then return end
    local maxRange = tonumber(Settings.SODAutoStealRange) or 15

    for prompt, data in pairs(ItemPrompts) do
        if prompt.Parent and data.Part and data.Part.Parent then
            if MatchesRarityFilter(data.Rarity, data.Value) then
                local dist = (data.Part.Position - charRoot.Position).Magnitude
                if dist <= maxRange then
                    TriggerPrompt(prompt)
                end
            end
        end
    end
end



local function IsPlayerBagFull()
    local char = Player.Character
    local targets = { Player }
    if char then table.insert(targets, char) end
    for _, t in ipairs(targets) do
        local isFull = t:GetAttribute("BagFull") or t:GetAttribute("IsFull") or t:GetAttribute("InventoryFull")
        if isFull == true then return true end
        local currWeight = t:GetAttribute("Weight") or t:GetAttribute("CurrentWeight") or t:GetAttribute("CarryWeight")
        local maxWeight = t:GetAttribute("MaxWeight") or t:GetAttribute("BagCapacity") or t:GetAttribute("MaxCapacity")
        if currWeight and maxWeight and maxWeight > 0 and currWeight >= maxWeight then
            return true
        end
    end

    local pGui = Player:FindFirstChild("PlayerGui")
    if pGui then
        for _, gui in ipairs(pGui:GetChildren()) do
            if gui:IsA("ScreenGui") and gui.Enabled then
                for _, desc in ipairs(gui:GetDescendants()) do
                    if desc:IsA("TextLabel") and desc.Visible then
                        local txt = string.lower(desc.Text)
                        if string.find(txt, "bag full") or string.find(txt, "inventory full") or string.find(txt, "max capacity") then
                            return true
                        end
                        local curW, maxW = string.match(txt, "([%d%.]+)%s*/%s*([%d%.]+)")
                        if curW and maxW then
                            local cNum = tonumber(curW)
                            local mNum = tonumber(maxW)
                            if cNum and mNum and mNum > 0 and cNum >= mNum then
                                return true
                            end
                        end
                    end
                end
            end
        end
    end
    return false
end

local function GetBestExit()
    local _, _, root = GetCharacterState()
    local best = nil
    local minDist = 99999
    for _, data in pairs(ExitObjects) do
        if data.Part and data.Part.Parent then
            if root then
                local dist = (data.Part.Position - root.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    best = data
                end
            else
                best = data
                break
            end
        end
    end
    return best
end

local SODNavPath = PathfindingService:CreatePath({
    AgentRadius = 1.8,
    AgentHeight = 5.0,
    AgentCanJump = true,
    WaypointSpacing = 3.5,
    Costs = {
        Door = 1.0,
        Water = 100.0
    }
})

local function GetItemStandPosition(part)
    if not part or not part.Parent then return nil end
    local itemPos = part.Position
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    local exclude = {}
    if Player.Character then table.insert(exclude, Player.Character) end
    if SafePlatformModel then table.insert(exclude, SafePlatformModel) end
    rayParams.FilterDescendantsInstances = exclude

    local ray = Workspace:Raycast(itemPos + Vector3.new(0, 2, 0), Vector3.new(0, -35, 0), rayParams)
    local floorY = ray and ray.Position.Y or (itemPos.Y - 2.5)

    return Vector3.new(itemPos.X, floorY + 1.2, itemPos.Z)
end

local function NavigateAlongFloor(targetPos, myGen, checkAbort)
    local char, hum, root = GetCharacterState()
    if not char or not hum or hum.Health <= 0 or not root then return false end

    local startPos = root.Position
    local directDist = (Vector3.new(targetPos.X, startPos.Y, targetPos.Z) - startPos).Magnitude
    if directDist <= 4.0 then
        return true
    end

    -- 1. Standard Pathfinding (uses game navmesh, strictly respects all walls)
    local ok, _ = pcall(function()
        SODNavPath:ComputeAsync(startPos, targetPos)
    end)

    local waypoints = {}
    if ok and SODNavPath.Status == Enum.PathStatus.Success then
        waypoints = SODNavPath:GetWaypoints()
    end

    if #waypoints > 1 then
        for i = 2, #waypoints do
            if not Settings.SODAutoFarm and not Settings.SODAutoEscape then return false end
            if checkAbort and checkAbort() then return false end

            local wp = waypoints[i]
            local wpPos = wp.Position
            local charCur, humCur, rootCur = GetCharacterState()
            if not charCur or not humCur or humCur.Health <= 0 or not rootCur then return false end

            if wp.Action == Enum.PathWaypointAction.Jump then
                humCur.Jump = true
            end

            local wpDist = (Vector3.new(wpPos.X, rootCur.Position.Y, wpPos.Z) - rootCur.Position).Magnitude
            local maxWait = math.clamp(wpDist / 12, 0.3, 2.5)
            local t0 = os.clock()

            while (os.clock() - t0) < maxWait do
                local c, h, r = GetCharacterState()
                if not c or not h or h.Health <= 0 or not r then return false end
                if not Settings.SODAutoFarm and not Settings.SODAutoEscape then return false end
                if checkAbort and checkAbort() then return false end

                local flatDiff = (Vector3.new(wpPos.X, r.Position.Y, wpPos.Z) - r.Position)
                if flatDiff.Magnitude <= 2.2 then break end

                -- Physical walking with collision ON (NO noclip)
                h:MoveTo(wpPos)
                h:Move(flatDiff.Unit, false)

                RunService.Heartbeat:Wait()
            end
        end
        return true
    end

    -- 2. Fallback: Raycast-guided collision corridor walking (never penetrates walls)
    local t0 = os.clock()
    local maxWait = math.clamp(directDist / 10, 1.0, 5.0)

    while (os.clock() - t0) < maxWait do
        local c, h, r = GetCharacterState()
        if not c or not h or h.Health <= 0 or not r then return false end
        if not Settings.SODAutoFarm and not Settings.SODAutoEscape then return false end
        if checkAbort and checkAbort() then return false end

        local toTarget = (targetPos - r.Position)
        local flatTarget = Vector3.new(toTarget.X, 0, toTarget.Z)
        if flatTarget.Magnitude <= 4.0 then return true end

        local fwdUnit = flatTarget.Unit
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        rayParams.FilterDescendantsInstances = { c }

        local forwardRay = Workspace:Raycast(r.Position, fwdUnit * 4.0, rayParams)
        local steerUnit = fwdUnit

        if forwardRay then
            local angles = { 45, -45, 90, -90 }
            local bestScore = -999

            for _, ang in ipairs(angles) do
                local rad = math.rad(ang)
                local rotDir = Vector3.new(
                    fwdUnit.X * math.cos(rad) - fwdUnit.Z * math.sin(rad),
                    0,
                    fwdUnit.X * math.sin(rad) + fwdUnit.Z * math.cos(rad)
                ).Unit
                local sideRay = Workspace:Raycast(r.Position, rotDir * 4.0, rayParams)
                if not sideRay then
                    local score = rotDir:Dot(fwdUnit)
                    if score > bestScore then
                        bestScore = score
                        steerUnit = rotDir
                    end
                end
            end
            if forwardRay.Instance and forwardRay.Instance.CanCollide and math.random(1, 25) == 1 then
                h.Jump = true
            end
        end

        h:MoveTo(r.Position + steerUnit * 4.0)
        h:Move(steerUnit, false)

        RunService.Heartbeat:Wait()
    end

    return false
end

local function StopAutoFarm()
    Settings.SODAutoFarm = false
    local _, hum, root = GetCharacterState()
    if root then
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end
    if hum then
        hum:Move(Vector3.zero, false)
    end
    AutoFarmRunning = false
end

local function StartAutoFarmLoop()
    if AutoFarmRunning then return end
    AutoFarmRunning = true
    getgenv().ToxSODFarmGen = (tonumber(getgenv().ToxSODFarmGen) or 0) + 1
    local myGen = getgenv().ToxSODFarmGen

    task.spawn(function()
        while Settings.SODAutoFarm and getgenv().ToxSODFarmGen == myGen do
            task.wait(0.05)
            if not Settings.SODAutoFarm then break end

            local char, hum, root = GetCharacterState()
            if not char or not hum or hum.Health <= 0 or not root then
                task.wait(1)
                continue
            end

            -- 1. Pause on Danger
            local dangerDist = tonumber(Settings.SODFarmDangerDist) or 50
            local isDanger = false
            for _, mData in pairs(ActiveMonsters) do
                if mData.Root and mData.Root.Parent then
                    local d = (mData.Root.Position - root.Position).Magnitude
                    if d <= dangerDist then
                        isDanger = true
                        break
                    end
                end
            end
            if isDanger then
                hum:Move(Vector3.zero, false)
                task.wait(0.5)
                continue
            end

            -- 2. Select Best Loot Target
            local bestPrompt, bestData, bestScore = nil, nil, -999999
            for prompt, data in pairs(ItemPrompts) do
                if prompt.Parent and data.Part and data.Part.Parent then
                    if MatchesRarityFilter(data.Rarity, data.Value) then
                        local dist = (data.Part.Position - root.Position).Magnitude
                        local val = data.Value or 100
                        local score = (val * 2) - dist
                        if score > bestScore then
                            bestScore = score
                            bestPrompt = prompt
                            bestData = data
                        end
                    end
                end
            end

            if not bestData or not bestPrompt or not bestPrompt.Parent then
                task.wait(0.4)
                continue
            end

            -- 3. Walk along floor and corridors (NO noclip, follows walls and doorways)
            local targetFloor = GetItemStandPosition(bestData.Part) or bestData.Part.Position
            local function abortCondition()
                if not bestPrompt or not bestPrompt.Parent or not bestData.Part or not bestData.Part.Parent then
                    return true
                end
                for _, mData in pairs(ActiveMonsters) do
                    if mData.Root and mData.Root.Parent then
                        if (mData.Root.Position - root.Position).Magnitude <= dangerDist then
                            return true
                        end
                    end
                end
                return false
            end

            NavigateAlongFloor(targetFloor, myGen, abortCondition)

            -- 4. Trigger prompt if in range
            if bestPrompt and bestPrompt.Parent and bestData.Part and bestData.Part.Parent then
                local curDist = (bestData.Part.Position - root.Position).Magnitude
                if curDist <= (bestPrompt.MaxActivationDistance or 8) + 2.5 then
                    hum:Move(Vector3.zero, false)
                    TriggerPrompt(bestPrompt)
                    task.wait(0.18)
                end
            end
        end

        StopAutoFarm()
    end)
end

-- Dedicated Auto Escape Loop
local AutoEscapeRunning = false
local function StartAutoEscapeLoop()
    if AutoEscapeRunning then return end
    AutoEscapeRunning = true

    task.spawn(function()
        local myGen = getgenv().ToxSODGeneration
        while Settings.SODAutoEscape and getgenv().ToxSODGeneration == myGen do
            task.wait(0.3)
            if not Settings.SODAutoEscape then break end

            local char, hum, root = GetCharacterState()
            if not char or not hum or hum.Health <= 0 or not root then
                task.wait(1)
                continue
            end

            if IsPlayerBagFull() then
                local exit = GetBestExit()
                if exit and exit.Part and exit.Part.Parent then
                    local exitFloor = GetItemStandPosition(exit.Part) or exit.Part.Position
                    CustomNotify("Auto Escape: Walking to Extraction!", Color3.fromRGB(0, 255, 140), 2)
                    NavigateAlongFloor(exitFloor, myGen, nil)
                    task.wait(1)
                end
            end
        end
        AutoEscapeRunning = false
    end)
end

local function IsLocalPlayerMonster()
    local char = Player.Character
    if not char then return false end
    if ActiveMonsters[char] ~= nil then return true end
    local role = Player:GetAttribute("Role") or (char and char:GetAttribute("Role"))
    if role and (string.find(string.lower(tostring(role)), "monster") or string.find(string.lower(tostring(role)), "entity")) then
        return true
    end
    local cName = string.lower(char.Name)
    if string.find(cName, "monster") or string.find(cName, "entity") then
        return true
    end
    for _, t in ipairs(char:GetChildren()) do
        if t:IsA("Tool") and (string.find(string.lower(t.Name), "claw") or string.find(string.lower(t.Name), "attack") or string.find(string.lower(t.Name), "kill") or string.find(string.lower(t.Name), "weapon")) then
            return true
        end
    end
    return false
end

local AttackRemotesCache = nil
local function GetAttackRemotes()
    if AttackRemotesCache then return AttackRemotesCache end
    AttackRemotesCache = {}
    pcall(function()
        for _, inst in ipairs(ReplicatedStorage:GetDescendants()) do
            if inst:IsA("RemoteEvent") then
                local rLower = string.lower(inst.Name)
                if string.find(rLower, "attack") or string.find(rLower, "hit") or string.find(rLower, "damage") 
                   or string.find(rLower, "slash") or string.find(rLower, "kill") or string.find(rLower, "swing")
                   or string.find(rLower, "weapon") or string.find(rLower, "claw") then
                    table.insert(AttackRemotesCache, inst)
                end
            end
        end
    end)
    return AttackRemotesCache
end

local function StartEntityKillLoop()
    if EntityKillRunning then return end
    EntityKillRunning = true

    task.spawn(function()
        local myGen = getgenv().ToxSODGeneration
        while Settings.SODEntityKill and getgenv().ToxSODGeneration == myGen do
            task.wait(0.1)
            if not Settings.SODEntityKill then break end

            local char, hum, root = GetCharacterState()
            if not char or not hum or hum.Health <= 0 or not root then
                task.wait(0.5)
                continue
            end

            local isMon = IsLocalPlayerMonster()
            local bestTarget = nil
            local bestDist = 99999

            if isMon then
                -- Player is monster: target nearest survivor player
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= Player then
                        local pChar = plr.Character
                        local pHum = pChar and pChar:FindFirstChildOfClass("Humanoid")
                        local pRoot = pChar and pChar:FindFirstChild("HumanoidRootPart")
                        if pChar and pHum and pHum.Health > 0 and pRoot and not ActiveMonsters[pChar] then
                            local d = (pRoot.Position - root.Position).Magnitude
                            if d < bestDist then
                                bestDist = d
                                bestTarget = { Character = pChar, Humanoid = pHum, Root = pRoot, Name = plr.DisplayName or plr.Name }
                            end
                        end
                    end
                end
            else
                -- Player is survivor: target monster/entity
                for model, mData in pairs(ActiveMonsters) do
                    if model.Parent and mData.Root and mData.Root.Parent then
                        local mHum = model:FindFirstChildOfClass("Humanoid")
                        if not mHum or mHum.Health > 0 then
                            local d = (mData.Root.Position - root.Position).Magnitude
                            if d < bestDist then
                                bestDist = d
                                bestTarget = { Character = model, Humanoid = mHum, Root = mData.Root, Name = mData.Name or "Entity" }
                            end
                        end
                    end
                end
                -- Fallback: scan workspace for entity/monster models if not in ActiveMonsters
                if not bestTarget then
                    for _, m in ipairs(Workspace:GetChildren()) do
                        if m:IsA("Model") and m ~= char and not Players:GetPlayerFromCharacter(m) then
                            local mName = string.lower(m.Name)
                            if string.find(mName, "monster") or string.find(mName, "entity") or string.find(mName, "wendell") then
                                local mRoot = m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
                                local mHum = m:FindFirstChildOfClass("Humanoid")
                                if mRoot and (not mHum or mHum.Health > 0) then
                                    local d = (mRoot.Position - root.Position).Magnitude
                                    if d < bestDist then
                                        bestDist = d
                                        bestTarget = { Character = m, Humanoid = mHum, Root = mRoot, Name = m.Name }
                                    end
                                end
                            end
                        end
                    end
                end
            end

            if not bestTarget then
                task.wait(0.4)
                continue
            end

            local tRoot = bestTarget.Root
            local tHum = bestTarget.Humanoid

            if tRoot and tRoot.Parent then
                local dist = (tRoot.Position - root.Position).Magnitude

                -- Position smoothly behind/at target to guarantee hit
                if dist > 4 then
                    local lookDir = tRoot.CFrame.LookVector
                    local attackPos = tRoot.Position - (lookDir * 3.2) + Vector3.new(0, 0.5, 0)
                    root.CFrame = CFrame.new(attackPos, tRoot.Position)
                    root.AssemblyLinearVelocity = Vector3.zero
                    root.AssemblyAngularVelocity = Vector3.zero
                else
                    root.CFrame = CFrame.new(root.Position, Vector3.new(tRoot.Position.X, root.Position.Y, tRoot.Position.Z))
                end

                -- Equip tools from backpack
                pcall(function()
                    local backpack = Player:FindFirstChild("Backpack")
                    if backpack then
                        for _, tool in ipairs(backpack:GetChildren()) do
                            if tool:IsA("Tool") then
                                tool.Parent = char
                            end
                        end
                    end
                end)

                -- Activate weapon/tool
                pcall(function()
                    for _, tool in ipairs(char:GetChildren()) do
                        if tool:IsA("Tool") then
                            tool:Activate()
                        end
                    end
                end)

                -- Simulate physical mouse clicks via VirtualInputManager and VirtualUser
                pcall(function()
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                    task.wait(0.02)
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                end)
                pcall(function()
                    local vu = game:GetService("VirtualUser")
                    vu:CaptureController()
                    vu:Button1Down(Vector2.zero)
                    task.wait(0.02)
                    vu:Button1Up(Vector2.zero)
                end)

                -- Fire attack remotes
                pcall(function()
                    for _, rem in ipairs(GetAttackRemotes()) do
                        pcall(function()
                            rem:FireServer(bestTarget.Character)
                            if tHum then rem:FireServer(tHum) end
                            rem:FireServer(tRoot)
                        end)
                    end
                end)

                -- Trigger any attack/damage prompts
                pcall(function()
                    for _, prompt in ipairs(bestTarget.Character:GetDescendants()) do
                        if prompt:IsA("ProximityPrompt") then
                            TriggerPrompt(prompt)
                        end
                    end
                end)
            end
        end
        EntityKillRunning = false
    end)
end

local HasVotedThisIntermission = false
local AutoVoteAttempts = 0
local SODAvailableMaps = { "Office", "Supermarket", "Liminal Lucidity", "Facility", "American Dorm", "Random" }

local function IsGuiTrulyVisible(obj)
    if not obj or not obj:IsA("GuiObject") then return false end
    if not obj.Visible then return false end
    
    local size = obj.AbsoluteSize
    if size.X <= 4 or size.Y <= 4 then return false end
    
    -- Check screen viewport bounds
    local pos = obj.AbsolutePosition
    local cam = Workspace.CurrentCamera
    local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)
    if (pos.X + size.X) < 0 or (pos.Y + size.Y) < 0 then return false end
    if pos.X > vp.X or pos.Y > vp.Y then return false end
    
    -- Walk ancestors to ensure ScreenGui is enabled and all parent frames are visible
    local curr = obj.Parent
    while curr and curr ~= game do
        if curr:IsA("ScreenGui") then
            if not curr.Enabled then return false end
            break
        elseif curr:IsA("CanvasGroup") then
            if not curr.Visible or curr.GroupTransparency > 0.95 then return false end
        elseif curr:IsA("GuiObject") then
            if not curr.Visible then return false end
        end
        curr = curr.Parent
    end
    return true
end

local function FindVotingCards()
    local pGui = Player:FindFirstChild("PlayerGui")
    if not pGui then return false, {}, {} end

    local mapCards = {}
    local entityCards = {}
    local hasVotingHeader = false

    -- Search all active ScreenGuis in PlayerGui
    for _, gui in ipairs(pGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled then
            for _, desc in ipairs(gui:GetDescendants()) do
                if (desc:IsA("TextLabel") or desc:IsA("TextButton")) and desc.Text and desc.Text ~= "" and IsGuiTrulyVisible(desc) then
                    local rawText = desc.Text
                    local tUpper = string.upper(rawText)

                    -- Check if voting window title/subtitle is visible
                    if string.find(tUpper, "PICK THE MAP") or (tUpper == "VOTE" and desc.TextSize and desc.TextSize >= 14) then
                        hasVotingHeader = true
                    end

                    -- Helper to find the card container frame
                    local function ResolveCard(lbl)
                        local c = lbl
                        for _ = 1, 3 do
                            if c.Parent and c.Parent:IsA("GuiObject") then
                                local p = c.Parent
                                local pUpper = string.upper(p.Name)
                                if string.find(pUpper, "GRID") or string.find(pUpper, "LIST") or string.find(pUpper, "CONTAINER") or string.find(pUpper, "VOTE") or p.AbsoluteSize.X > 550 then
                                    break
                                end
                                c = p
                            else
                                break
                            end
                        end
                        return c
                    end

                    -- Map Cards:
                    if string.find(tUpper, "OFFICE") and not string.find(tUpper, "SKYSCRAPER") then
                        mapCards["office"] = { Label = desc, Card = ResolveCard(desc) }
                    elseif (string.find(tUpper, "SUPERMARKET") or string.find(tUpper, "DAYLIGHT FOODS")) and not string.find(tUpper, "LONG AISLES") then
                        mapCards["supermarket"] = { Label = desc, Card = ResolveCard(desc) }
                    elseif (string.find(tUpper, "LIMINAL") or string.find(tUpper, "LUCIDITY")) and not string.find(tUpper, "REMEMBER THEM") then
                        mapCards["liminal lucidity"] = { Label = desc, Card = ResolveCard(desc) }
                    elseif string.find(tUpper, "FACILITY") then
                        mapCards["facility"] = { Label = desc, Card = ResolveCard(desc) }
                    elseif string.find(tUpper, "AMERICAN DORM") or (string.find(tUpper, "DORM") and not string.find(tUpper, "BEDROOM")) then
                        mapCards["american dorm"] = { Label = desc, Card = ResolveCard(desc) }
                    end

                    -- Entity Cards:
                    if string.find(tUpper, "ENTITY:%s*AI") or tUpper == "ENTITY: AI" or (string.find(tUpper, "AI") and string.find(tUpper, "CONTROLLED")) then
                        entityCards["ai"] = { Label = desc, Card = ResolveCard(desc) }
                    elseif string.find(tUpper, "ENTITY:%s*PLAYER") or tUpper == "ENTITY: PLAYER" or (string.find(tUpper, "PLAYER") and string.find(tUpper, "BECOMES")) then
                        entityCards["player"] = { Label = desc, Card = ResolveCard(desc) }
                    end
                end
            end
        end
    end

    -- The voting window is genuinely active on screen if header is visible OR any map card is visible
    local isWindowOpen = hasVotingHeader or (next(mapCards) ~= nil)
    if not isWindowOpen then
        return false, {}, {}
    end

    return true, mapCards, entityCards
end

local function ClickTargetCard(entry)
    if not entry then return false end
    local label = entry.Label
    local card = entry.Card or label

    -- Collect all interactive objects in this card
    local clickables = {}
    if card and card:IsA("GuiObject") then
        table.insert(clickables, card)
        for _, desc in ipairs(card:GetDescendants()) do
            if desc:IsA("GuiButton") or desc:IsA("ImageLabel") or desc:IsA("TextLabel") or desc:IsA("Frame") then
                table.insert(clickables, desc)
            end
        end
    end
    if label and not table.find(clickables, label) then
        table.insert(clickables, label)
    end

    -- 1. Hardware mouse clicks via VirtualInputManager & VirtualUser at Card center and Label center
    local clickPoints = {}
    if card and card:IsA("GuiObject") and card.AbsoluteSize.X > 0 and card.AbsoluteSize.Y > 0 then
        table.insert(clickPoints, Vector2.new(
            card.AbsolutePosition.X + (card.AbsoluteSize.X / 2),
            card.AbsolutePosition.Y + (card.AbsoluteSize.Y / 2)
        ))
    end
    if label and label:IsA("GuiObject") and label.AbsoluteSize.X > 0 and label.AbsoluteSize.Y > 0 then
        table.insert(clickPoints, Vector2.new(
            label.AbsolutePosition.X + (label.AbsoluteSize.X / 2),
            label.AbsolutePosition.Y + (label.AbsoluteSize.Y / 2)
        ))
    end

    for _, pt in ipairs(clickPoints) do
        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(pt.X, pt.Y, 0, true, game, 0)
            task.wait(0.03)
            VirtualInputManager:SendMouseButtonEvent(pt.X, pt.Y, 0, false, game, 0)
        end)
        pcall(function()
            local vu = game:GetService("VirtualUser")
            vu:CaptureController()
            vu:Button1Down(pt)
            task.wait(0.03)
            vu:Button1Up(pt)
        end)
    end

    -- 2. Fire signals and getconnections on all clickable candidates
    for _, obj in ipairs(clickables) do
        if obj:IsA("GuiButton") then
            pcall(function()
                if firesignal then
                    firesignal(obj.MouseButton1Click)
                    firesignal(obj.Activated)
                    firesignal(obj.MouseButton1Down)
                    firesignal(obj.MouseButton1Up)
                end
                if getconnections then
                    for _, c in ipairs(getconnections(obj.MouseButton1Click)) do pcall(function() c:Fire() end) end
                    for _, c in ipairs(getconnections(obj.Activated)) do pcall(function() c:Fire() end) end
                    for _, c in ipairs(getconnections(obj.MouseButton1Down)) do pcall(function() c:Fire() end) end
                end
            end)
        elseif obj:IsA("GuiObject") then
            pcall(function()
                if getconnections then
                    for _, c in ipairs(getconnections(obj.InputBegan)) do
                        pcall(function()
                            c:Fire({
                                UserInputType = Enum.UserInputType.MouseButton1,
                                UserInputState = Enum.UserInputState.Begin,
                                Position = Vector3.new(clickPoints[1] and clickPoints[1].X or 0, clickPoints[1] and clickPoints[1].Y or 0, 0)
                            })
                        end)
                    end
                end
            end)
        end
    end

    return true
end

local function ProcessAutoVote()
    if not Settings.SODAutoVote then
        HasVotedThisIntermission = false
        AutoVoteAttempts = 0
        return
    end

    local isOpen, mapCards, entityCards = FindVotingCards()
    if not isOpen then
        -- Voting window is NOT visible on screen: reset state so next intermission triggers cleanly
        HasVotedThisIntermission = false
        AutoVoteAttempts = 0
        return
    end

    -- Window IS OPEN! Retry up to 3 times spaced 0.8s apart during the active intermission
    if AutoVoteAttempts >= 3 then
        return
    end

    local c1 = string.lower(Settings.SODVoteMapChoice1 or "Office")
    local c2 = string.lower(Settings.SODVoteMapChoice2 or "Supermarket")
    local c3 = string.lower(Settings.SODVoteMapChoice3 or "Liminal Lucidity")
    local userEntity = string.lower(Settings.SODVoteMonster or "AI")

    -- 1. Click Map Card by priority order
    local chosenEntry = nil
    local chosenMapName = nil

    for _, choice in ipairs({ c1, c2, c3 }) do
        if choice == "random" then
            for mName, entry in pairs(mapCards) do
                chosenEntry = entry
                chosenMapName = mName
                break
            end
        elseif mapCards[choice] then
            chosenEntry = mapCards[choice]
            chosenMapName = choice
            break
        end
    end

    if not chosenEntry then
        for mName, entry in pairs(mapCards) do
            chosenEntry = entry
            chosenMapName = mName
            break
        end
    end

    if chosenEntry then
        ClickTargetCard(chosenEntry)
    end

    task.wait(0.1)

    -- 2. Click Entity Card (AI or PLAYER)
    local targetEntity = "ai"
    if string.find(userEntity, "player") then
        targetEntity = "player"
    elseif string.find(userEntity, "random") then
        targetEntity = (math.random(1, 2) == 1) and "ai" or "player"
    else
        targetEntity = "ai"
    end

    local entityEntry = entityCards[targetEntity] or entityCards["ai"] or entityCards["player"]
    if entityEntry then
        ClickTargetCard(entityEntry)
    end

    -- 3. Also invoke voting RemoteEvents in ReplicatedStorage with exact Map & Entity strings
    pcall(function()
        for _, rem in ipairs(ReplicatedStorage:GetDescendants()) do
            if rem:IsA("RemoteEvent") then
                local rLower = string.lower(rem.Name)
                if string.find(rLower, "vote") or string.find(rLower, "map") or string.find(rLower, "entity") then
                    if chosenMapName then rem:FireServer(chosenMapName) end
                    rem:FireServer(targetEntity == "ai" and "AI" or "Player")
                end
            end
        end
    end)

    AutoVoteAttempts = AutoVoteAttempts + 1

    -- Notify only once on the first successful vote of the active intermission
    if not HasVotedThisIntermission then
        HasVotedThisIntermission = true
        local mapLabel = chosenMapName and string.upper(chosenMapName) or "MAP"
        local entLabel = targetEntity == "ai" and "AI" or "PLAYER"
        CustomNotify("Auto Voted: " .. mapLabel .. " | " .. entLabel, Color3.fromRGB(0, 255, 140), 3)
    end
end

local AutoVoteThread = nil
local function StartAutoVoteLoop()
    if AutoVoteThread then return end
    AutoVoteThread = task.spawn(function()
        while true do
            task.wait(0.5)
            if not Settings.SODAutoVote then
                HasVotedThisIntermission = false
                AutoVoteAttempts = 0
                break
            end
            pcall(ProcessAutoVote)
        end
        AutoVoteThread = nil
    end)
end

local function SetupAntiAFK(enable)
    if enable then
        if AntiAFKConnection then return end
        local vu = game:GetService("VirtualUser")
        AntiAFKConnection = Player.Idled:Connect(function()
            if Settings.SODAntiAFK then
                pcall(function()
                    vu:CaptureController()
                    vu:ClickButton2(Vector2.new(0, 0))
                end)
            end
        end)
        table.insert(SODConnections, AntiAFKConnection)
    else
        if AntiAFKConnection then
            pcall(function() AntiAFKConnection:Disconnect() end)
            AntiAFKConnection = nil
        end
    end
end

-- ==============================================================================
-- SAFE PLATFORM & UTILITIES
-- ==============================================================================

local function EnsureSafePlatform()
    if SafePlatformModel and SafePlatformModel.Parent then
        return SafePlatformModel
    end

    local model = Instance.new("Model")
    model.Name = "ToxSODPlatform"

    local height = tonumber(Settings.SODPlatformHeight) or 350
    local part = Instance.new("Part")
    part.Name = "Floor"
    part.Size = Vector3.new(45, 2, 45)
    part.CFrame = CFrame.new(0, height, 0)
    part.Anchored = true
    part.CanCollide = true
    part.Material = Enum.Material.ForceField
    part.Color = Color3.fromRGB(30, 95, 255)
    part.Parent = model

    for _, offset in ipairs({
        { Vector3.new(0, 3, 22.5), Vector3.new(45, 6, 1) },
        { Vector3.new(0, 3, -22.5), Vector3.new(45, 6, 1) },
        { Vector3.new(22.5, 3, 0), Vector3.new(1, 6, 45) },
        { Vector3.new(-22.5, 3, 0), Vector3.new(1, 6, 45) }
    }) do
        local rail = Instance.new("Part")
        rail.Size = offset[2]
        rail.CFrame = part.CFrame * CFrame.new(offset[1])
        rail.Anchored = true
        rail.CanCollide = true
        rail.Material = Enum.Material.Neon
        rail.Color = Color3.fromRGB(30, 95, 255)
        rail.Transparency = 0.5
        rail.Parent = model
    end

    model.Parent = Workspace
    SafePlatformModel = model
    return model
end

local function ClearSafePlatform()
    if SafePlatformModel then
        pcall(function() SafePlatformModel:Destroy() end)
        SafePlatformModel = nil
    end
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj.Name == "ToxSODPlatform" then
            pcall(function() obj:Destroy() end)
        end
    end
end

-- ==============================================================================
-- DAMAGE SHIELD (METAMETHOD HOOK)
-- ==============================================================================

pcall(function()
    if hookmetamethod and getnamecallmethod then
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if method == "FireServer" or method == "fireServer" then
                if Settings.SODDamageShield then
                    local name = string.lower(tostring(self.Name))
                    if string.find(name, "damage")
                    or string.find(name, "kill")
                    or string.find(name, "attack")
                    or string.find(name, "hurt")
                    or string.find(name, "hit")
                    or string.find(name, "bleed")
                    or string.find(name, "caught")
                    or string.find(name, "captured")
                    or string.find(name, "jumpscare")
                    or string.find(name, "takedamage") then
                        return nil
                    end
                end
            end
            return oldNamecall(self, ...)
        end))
    end
end)

-- ==============================================================================
-- CTRL + CLICK TELEPORT
-- ==============================================================================

local function GetClickTPCFrame()
    local char, _, root = GetCharacterState()
    if not root or not Mouse then return nil end

    local ray = Camera:ScreenPointToRay(Mouse.X, Mouse.Y)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local exclude = { char }
    if SafePlatformModel then table.insert(exclude, SafePlatformModel) end
    params.FilterDescendantsInstances = exclude

    local result = Workspace:Raycast(ray.Origin, ray.Direction * 3000, params)
    if result and result.Position then
        return CFrame.new(result.Position + Vector3.new(0, 3.5, 0))
    end
    if Mouse.Hit then
        return Mouse.Hit + Vector3.new(0, 3.5, 0)
    end
    return nil
end

TrackConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if Settings.SODClickTP and input.UserInputType == Enum.UserInputType.MouseButton1 then
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then
            local targetCF = GetClickTPCFrame()
            if targetCF then
                TeleportTo(targetCF, "Click TP")
            end
        end
    end
end))

-- ==============================================================================
-- MAIN TICK / HEARTBEAT LOOP
-- ==============================================================================

TrackConnection(RunService.Heartbeat:Connect(function(dt)
    local now = os.clock()
    local _, hum, root = GetCharacterState()

    if hum and hum.Health > 0 and Settings.SODSpeedBoost then
        local target = tonumber(Settings.SODSpeedValue) or 22
        if hum.WalkSpeed < target then
            hum.WalkSpeed = target
        end
    end

    if now - LastStaminaCheck >= 0.25 then
        LastStaminaCheck = now
        if Settings.SODInfiniteStamina then
            pcall(RefillStamina)
        end
    end

    if now - LastAuraCheck >= 0.2 then
        LastAuraCheck = now
        if Settings.SODAutoSteal and root then
            pcall(AutoStealAura, root)
        end
    end

    if now - LastDescendantSweep >= 3.5 then
        LastDescendantSweep = now
        for _, d in ipairs(Workspace:GetDescendants()) do
            if d:IsA("ProximityPrompt") and not ItemPrompts[d] and not VentObjects[d] then
                pcall(RegisterPrompt, d)
            end
        end
    end

    if now - LastESPInterval >= 0.15 then
        LastESPInterval = now
        local closestDist = UpdateMonsterESP(root)
        UpdateItemESP(root)
        UpdatePlayerESP(root)
        UpdateExitESP(root)
        UpdateVentClosetESP(root)

-- AutoVote handled in dedicated background loop (0 lag)


    end
end))

if Settings.SODFullBright then
    pcall(ApplyFullBright)
end
if Settings.SODRemoveDoors then
    pcall(function() ApplyRemoveDoors(true) end)
end
if Settings.SODAutoFarm then
    pcall(StartAutoFarmLoop)
end
if Settings.SODEntityKill then
    pcall(StartEntityKillLoop)
end
if Settings.SODAntiAFK then
    pcall(function() SetupAntiAFK(true) end)
end
pcall(StartAutoVoteLoop)

-- ==============================================================================
-- UI BUILDER - SECTION 1: VISUALS
-- ==============================================================================

CreateSODSection("VISUALS")

SODCreateToggle(
    "Item ESP",
    GamePage,
    Settings.SODItemESP,
    function(v)
        Settings.SODItemESP = v == true
        if not v then
            for _, esp in pairs(ItemESPObjects) do
                if esp.Billboard then esp.Billboard.Enabled = false end
                if esp.Highlight then esp.Highlight.Enabled = false end
            end
        end
        AutoSaveConfiguration()
    end,
    "SODItemESP"
)

SODCreateDropdown(
    "Item ESP Style",
    { "Name + Value", "Value Only", "Chams Only" },
    GamePage,
    Settings.SODItemESPStyle or "Name + Value",
    function(choice)
        Settings.SODItemESPStyle = tostring(choice)
        AutoSaveConfiguration()
    end
)

SODCreateToggle(
    "Exit ESP",
    GamePage,
    Settings.SODExitESP,
    function(v)
        Settings.SODExitESP = v == true
        if not v then
            for _, esp in pairs(ExitESPObjects) do
                if esp.Billboard then esp.Billboard.Enabled = false end
                if esp.Highlight then esp.Highlight.Enabled = false end
            end
        end
        AutoSaveConfiguration()
    end,
    "SODExitESP"
)

SODCreateToggle(
    "Monster ESP",
    GamePage,
    Settings.SODMonsterESP,
    function(v)
        Settings.SODMonsterESP = v == true
        if not v then
            for _, esp in pairs(MonsterESPObjects) do
                if esp.Billboard then esp.Billboard.Enabled = false end
                if esp.Highlight then esp.Highlight.Enabled = false end
            end
        end
        AutoSaveConfiguration()
    end,
    "SODMonsterESP"
)

SODCreateToggle(
    "Player ESP",
    GamePage,
    Settings.SODPlayerESP,
    function(v)
        Settings.SODPlayerESP = v == true
        if not v then
            for _, esp in pairs(PlayerESPObjects) do
                if esp.Billboard then esp.Billboard.Enabled = false end
                if esp.Highlight then esp.Highlight.Enabled = false end
            end
        end
        AutoSaveConfiguration()
    end,
    "SODPlayerESP"
)

SODCreateToggle(
    "Vents & Closets ESP",
    GamePage,
    Settings.SODVentClosetESP,
    function(v)
        Settings.SODVentClosetESP = v == true
        if not v then
            for _, esp in pairs(VentESPObjects) do
                if esp.Billboard then esp.Billboard.Enabled = false end
                if esp.Highlight then esp.Highlight.Enabled = false end
            end
            for _, esp in pairs(ClosetESPObjects) do
                if esp.Billboard then esp.Billboard.Enabled = false end
                if esp.Highlight then esp.Highlight.Enabled = false end
            end
        end
        AutoSaveConfiguration()
    end,
    "SODVentClosetESP"
)

SODCreateDropdown(
    "Rarity Filter",
    { "All", "Common+", "Uncommon+", "Rare+", "Epic+", "Legendary+", "Mythic Only" },
    GamePage,
    Settings.SODRarityFilter or "All",
    function(choice)
        Settings.SODRarityFilter = tostring(choice)
        CustomNotify("Rarity Filter: " .. choice, Color3.fromRGB(100, 255, 150), 2)
        AutoSaveConfiguration()
    end
)

SODCreateToggleWithValue(
    "Min Item Value",
    GamePage,
    Settings.SODMinValueEnabled,
    Settings.SODMinValue or 250,
    function(v)
        Settings.SODMinValueEnabled = v == true
        AutoSaveConfiguration()
    end,
    function(val)
        Settings.SODMinValue = math.max(0, tonumber(val) or 0)
        AutoSaveConfiguration()
    end,
    "SODMinValueEnabled"
)

SODCreateToggleWithValue(
    "ESP Text Size",
    GamePage,
    true,
    Settings.SODESPTextSize or 10,
    function() end,
    function(val)
        Settings.SODESPTextSize = math.clamp(tonumber(val) or 10, 7, 18)
        AutoSaveConfiguration()
    end,
    "SODESPTextSize"
)

SODCreateToggle(
    "FullBright",
    GamePage,
    Settings.SODFullBright,
    function(v)
        Settings.SODFullBright = v == true
        if v then ApplyFullBright() else RestoreLighting() end
        AutoSaveConfiguration()
    end,
    "SODFullBright"
)

-- ==============================================================================
-- UI BUILDER - SECTION 2: LOOTING
-- ==============================================================================

CreateSODSection("LOOTING")

SODCreateToggle(
    "Auto Farm",
    GamePage,
    Settings.SODAutoFarm,
    function(v)
        Settings.SODAutoFarm = v == true
        if v then
            StartAutoFarmLoop()
        else
            StopAutoFarm()
        end
        AutoSaveConfiguration()
    end,
    "SODAutoFarm"
)

SODCreateToggleWithValue(
    "Farm Speed",
    GamePage,
    true,
    Settings.SODFarmSpeed or 40,
    function() end,
    function(val)
        Settings.SODFarmSpeed = math.clamp(tonumber(val) or 40, 25, 55)
        AutoSaveConfiguration()
    end,
    "SODFarmSpeed"
)

SODCreateToggle(
    "Auto Escape",
    GamePage,
    Settings.SODAutoEscape,
    function(v)
        Settings.SODAutoEscape = v == true
        if v then
            StartAutoEscapeLoop()
        end
        AutoSaveConfiguration()
    end,
    "SODAutoEscape"
)

SODCreateToggle(
    "Instant Steal",
    GamePage,
    Settings.SODInstantSteal,
    function(v)
        Settings.SODInstantSteal = v == true
        for prompt, _ in pairs(ItemPrompts) do
            SetInstantPrompt(prompt, v)
        end
        if v then
            for _, d in ipairs(Workspace:GetDescendants()) do
                if d:IsA("ProximityPrompt") then
                    local act = d.ActionText and string.lower(d.ActionText) or ""
                    local pName = d.Parent and string.lower(d.Parent.Name) or ""
                    if not string.find(act, "hide") and not string.find(pName, "closet") and not string.find(act, "unscrew") and not string.find(pName, "vent") then
                        pcall(function()
                            d.HoldDuration = 0
                            d.RequiresLineOfSight = false
                        end)
                    end
                end
            end
        end
        AutoSaveConfiguration()
    end,
    "SODInstantSteal"
)

SODCreateToggleWithValue(
    "Auto Steal Aura",
    GamePage,
    Settings.SODAutoSteal,
    Settings.SODAutoStealRange or 15,
    function(v)
        Settings.SODAutoSteal = v == true
        AutoSaveConfiguration()
    end,
    function(val)
        Settings.SODAutoStealRange = math.clamp(tonumber(val) or 15, 5, 45)
        AutoSaveConfiguration()
    end,
    "SODAutoSteal"
)

SODCreateToggle(
    "Instant Vent",
    GamePage,
    Settings.SODInstantVent,
    function(v)
        Settings.SODInstantVent = v == true
        for prompt, _ in pairs(VentObjects) do
            SetInstantPrompt(prompt, v)
        end
        AutoSaveConfiguration()
    end,
    "SODInstantVent"
)

SODCreateButton("TP to Best Loot", GamePage, function()
    local bestPrompt = nil
    local bestVal = -1
    local bestData = nil

    for prompt, data in pairs(ItemPrompts) do
        if prompt.Parent and data.Part and data.Part.Parent then
            if (data.Value or 0) > bestVal then
                bestVal = data.Value or 0
                bestPrompt = prompt
                bestData = data
            end
        end
    end

    if bestData and bestData.Part then
        TeleportTo(bestData.Part.CFrame + Vector3.new(0, 2.5, 0), bestData.Name .. " (" .. FormatCurrency(bestData.Value) .. ")")
        task.wait(0.15)
        TriggerPrompt(bestPrompt)
    else
        CustomNotify("No loot found on map", Color3.fromRGB(255, 150, 50), 2)
    end
end)

-- ==============================================================================
-- UI BUILDER - SECTION 3: SURVIVAL
-- ==============================================================================

CreateSODSection("SURVIVAL")

SODCreateToggle(
    "Auto Kill",
    GamePage,
    Settings.SODEntityKill,
    function(v)
        Settings.SODEntityKill = v == true
        if v then
            StartEntityKillLoop()
        end
        AutoSaveConfiguration()
    end,
    "SODEntityKill"
)

SODCreateToggle(
    "Infinite Stamina",
    GamePage,
    Settings.SODInfiniteStamina,
    function(v)
        Settings.SODInfiniteStamina = v == true
        if v then pcall(RefillStamina) end
        AutoSaveConfiguration()
    end,
    "SODInfiniteStamina"
)



-- ==============================================================================
-- UI BUILDER - SECTION 4: TELEPORTS & UTILITIES
-- ==============================================================================

CreateSODSection("TELEPORTS")

SODCreateButton("TP to Extraction", GamePage, function()
    local bestExit = GetBestExit()
    if bestExit and bestExit.Part then
        TeleportTo(bestExit.Part.CFrame + Vector3.new(0, 3, 0), "Exit")
    else
        CustomNotify("Extraction point not detected yet", Color3.fromRGB(255, 150, 50), 2)
    end
end)

SODCreateButton("TP to Nearest Hideout", GamePage, function()
    local _, _, root = GetCharacterState()
    if not root then return end
    local nearest, minDist, label = nil, 99999, "Hideout"

    for _, data in pairs(ClosetObjects) do
        if data.Part and data.Part.Parent then
            local dist = (data.Part.Position - root.Position).Magnitude
            if dist < minDist then
                minDist = dist
                nearest = data.Part
                label = "Closet"
            end
        end
    end
    for _, data in pairs(VentObjects) do
        if data.Part and data.Part.Parent then
            local dist = (data.Part.Position - root.Position).Magnitude
            if dist < minDist then
                minDist = dist
                nearest = data.Part
                label = "Vent"
            end
        end
    end

    if nearest then
        TeleportTo(nearest.CFrame + Vector3.new(0, 2.5, 0), label .. " (" .. math.floor(minDist) .. "m)")
    else
        CustomNotify("No hiding spot found nearby", Color3.fromRGB(255, 150, 50), 2)
    end
end)

SODCreateToggle(
    "Ctrl Click TP",
    GamePage,
    Settings.SODClickTP,
    function(v)
        Settings.SODClickTP = v == true
        AutoSaveConfiguration()
    end,
    "SODClickTP"
)

SODCreateToggle(
    "Auto Vote",
    GamePage,
    Settings.SODAutoVote,
    function(v)
        Settings.SODAutoVote = v == true
        if v then
            StartAutoVoteLoop()
        else
            HasVotedThisIntermission = false
            AutoVoteAttempts = 0
        end
        AutoSaveConfiguration()
    end,
    "SODAutoVote"
)

local MapChoicesList = { "Office", "Supermarket", "Liminal Lucidity", "Facility", "American Dorm", "Random" }

SODCreateDropdown(
    "Vote Monster",
    { "AI", "Player", "Random" },
    GamePage,
    Settings.SODVoteMonster or "AI",
    function(choice)
        Settings.SODVoteMonster = tostring(choice)
        AutoSaveConfiguration()
    end
)

SODCreateDropdown(
    "Map 1st Choice",
    MapChoicesList,
    GamePage,
    Settings.SODVoteMapChoice1 or "Office",
    function(choice)
        Settings.SODVoteMapChoice1 = tostring(choice)
        AutoSaveConfiguration()
    end
)

SODCreateDropdown(
    "Map 2nd Choice",
    MapChoicesList,
    GamePage,
    Settings.SODVoteMapChoice2 or "Supermarket",
    function(choice)
        Settings.SODVoteMapChoice2 = tostring(choice)
        AutoSaveConfiguration()
    end
)

SODCreateDropdown(
    "Map 3rd Choice",
    MapChoicesList,
    GamePage,
    Settings.SODVoteMapChoice3 or "Liminal Lucidity",
    function(choice)
        Settings.SODVoteMapChoice3 = tostring(choice)
        AutoSaveConfiguration()
    end
)

SODCreateToggle(
    "Anti AFK",
    GamePage,
    Settings.SODAntiAFK,
    function(v)
        Settings.SODAntiAFK = v == true
        SetupAntiAFK(v == true)
        AutoSaveConfiguration()
    end,
    "SODAntiAFK"
)

-- ==============================================================================
-- CLEANUP HANDLER
-- ==============================================================================

getgenv().ToxSODCleanup = function()
    getgenv().ToxSODGeneration = (tonumber(getgenv().ToxSODGeneration) or 0) + 1

    StopAutoFarm()
    SetupAntiAFK(false)

    for _, conn in ipairs(SODConnections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(SODConnections)

    for _, esp in pairs(ItemESPObjects) do
        pcall(function()
            if esp.Highlight then esp.Highlight:Destroy() end
            if esp.Billboard then esp.Billboard:Destroy() end
        end)
    end
    table.clear(ItemESPObjects)

    for _, esp in pairs(ExitESPObjects) do
        pcall(function()
            if esp.Highlight then esp.Highlight:Destroy() end
            if esp.Billboard then esp.Billboard:Destroy() end
        end)
    end
    table.clear(ExitESPObjects)

    for _, esp in pairs(MonsterESPObjects) do
        pcall(function()
            if esp.Highlight then esp.Highlight:Destroy() end
            if esp.Billboard then esp.Billboard:Destroy() end
        end)
    end
    table.clear(MonsterESPObjects)

    for _, esp in pairs(PlayerESPObjects) do
        pcall(function()
            if esp.Highlight then esp.Highlight:Destroy() end
            if esp.Billboard then esp.Billboard:Destroy() end
        end)
    end
    table.clear(PlayerESPObjects)

    for _, esp in pairs(VentESPObjects) do
        pcall(function()
            if esp.Highlight then esp.Highlight:Destroy() end
            if esp.Billboard then esp.Billboard:Destroy() end
        end)
    end
    table.clear(VentESPObjects)

    for _, esp in pairs(ClosetESPObjects) do
        pcall(function()
            if esp.Highlight then esp.Highlight:Destroy() end
            if esp.Billboard then esp.Billboard:Destroy() end
        end)
    end
    table.clear(ClosetESPObjects)

    for prompt, hold in pairs(OrigHoldDurations) do
        pcall(function() prompt.HoldDuration = hold end)
    end
    table.clear(OrigHoldDurations)

    pcall(RestoreLighting)
    ClearSafePlatform()

    if WarnScreenGui then
        pcall(function() WarnScreenGui:Destroy() end)
        WarnScreenGui = nil
    end

    local _, hum, root = GetCharacterState()
    if root then
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end
    if hum then
        pcall(function()
            hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
        end)
    end
end

getgenv().ToxSODModuleLoadedJobId = game.JobId
getgenv().ToxSODModuleVersion = SODModuleVersion
getgenv().ToxSODModulePage = GamePage
