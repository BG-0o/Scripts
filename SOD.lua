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

local SODModuleVersion = "2026-11-02-sod-v1"

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
-- SETTINGS & PERSISTENCE
-- ==============================================================================

Settings.SODCollapsedSections = typeof(Settings.SODCollapsedSections) == "table"
    and Settings.SODCollapsedSections
    or {}

-- Visuals / ESP
Settings.SODItemESP = Settings.SODItemESP ~= false
Settings.SODRarityFilter = tostring(Settings.SODRarityFilter or "All")
Settings.SODMinValueEnabled = Settings.SODMinValueEnabled == true
Settings.SODMinValue = tonumber(Settings.SODMinValue) or 250
Settings.SODItemDetails = Settings.SODItemDetails ~= false
Settings.SODMonsterESP = Settings.SODMonsterESP ~= false
Settings.SODMonsterWarn = Settings.SODMonsterWarn ~= false
Settings.SODMonsterWarnDistance = tonumber(Settings.SODMonsterWarnDistance) or 60
Settings.SODPlayerESP = Settings.SODPlayerESP == true
Settings.SODExitVentESP = Settings.SODExitVentESP ~= false
Settings.SODFullBright = Settings.SODFullBright == true

-- Auto-Steal & Actions
Settings.SODInstantSteal = Settings.SODInstantSteal ~= false
Settings.SODAutoStealAura = Settings.SODAutoStealAura == true
Settings.SODAutoStealRange = tonumber(Settings.SODAutoStealRange) or 15
Settings.SODInstantVent = Settings.SODInstantVent ~= false

-- Survival & Anti-Monster
Settings.SODInfiniteStamina = Settings.SODInfiniteStamina ~= false
Settings.SODAntiEncumbrance = Settings.SODAntiEncumbrance ~= false
Settings.SODCustomSpeed = tonumber(Settings.SODCustomSpeed) or 22
Settings.SODAutoEvacuate = Settings.SODAutoEvacuate == true
Settings.SODAutoEvacuateDistance = tonumber(Settings.SODAutoEvacuateDistance) or 28
Settings.SODDamageShield = Settings.SODDamageShield ~= false
Settings.SODSafePlatform = Settings.SODSafePlatform == true
Settings.SODPlatformHeight = tonumber(Settings.SODPlatformHeight) or 350
Settings.SODClickTP = Settings.SODClickTP == true

-- ==============================================================================
-- STATE VARIABLES
-- ==============================================================================

local SODConnections = {}
local SODCurrentSection = nil
local SODSections = {}

local ItemPrompts = {}        -- [prompt] = { Object, Part, Name, NameLower, Rarity, Value, Weight }
local ActiveMonsters = {}     -- [model] = { Model, Root, Name, Kind, IsPlayer }
local ExitObjects = {}        -- [instance] = { Part, Label }
local VentObjects = {}        -- [instance] = { Part, Prompt }
local ClosetObjects = {}      -- [instance] = { Part, Model }

local ItemESPObjects = {}     -- [prompt] = { Billboard, Label }
local MonsterESPObjects = {}  -- [model] = { Highlight, Billboard, Label }
local PlayerESPObjects = {}   -- [player] = { Highlight, Billboard, Label }
local ExitESPObjects = {}     -- [instance] = { Billboard, Label }
local VentESPObjects = {}     -- [instance] = { Billboard, Label }
local ClosetESPObjects = {}   -- [instance] = { Billboard, Label }

local SafePlatformModel = nil
local WarnScreenGui = nil
local WarnFrame = nil
local WarnStroke = nil
local WarnText = nil

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
    ["Common"] = Color3.fromRGB(220, 220, 230),      -- Silver/White
    ["Uncommon"] = Color3.fromRGB(70, 230, 110),     -- Green
    ["Rare"] = Color3.fromRGB(50, 160, 255),         -- Cyan/Blue
    ["Epic"] = Color3.fromRGB(180, 75, 255),         -- Purple
    ["Legendary"] = Color3.fromRGB(255, 190, 30),    -- Gold
    ["Mythic"] = Color3.fromRGB(255, 45, 85),        -- Crimson
    ["Secret"] = Color3.fromRGB(255, 45, 85)
}

local BlacklistKeywords = {
    "door", "vent", "locker", "closet", "button", "switch", "barricade",
    "exit", "gate", "wall", "floor", "light", "chair", "table", "desk",
    "bed", "shelf", "cabinet", "plant", "trash", "pipe", "stair", "sign",
    "handle", "hitbox", "attachment"
}

local LootKeywords = {
    "phone", "wallet", "gold", "laptop", "safe", "bar", "watch", "key",
    "tablet", "camera", "painting", "statue", "jewelry", "console",
    "headphones", "cash", "ring", "drive", "usb", "bag", "purse",
    "loot", "item", "pickup", "diamond", "core", "relic", "skull", "idol",
    "gpu", "card", "coin", "money", "artifact", "trophy", "ingot"
}

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

local function InferRarity(nameLower, value)
    if nameLower then
        if string.find(nameLower, "mythic") or string.find(nameLower, "secret") or string.find(nameLower, "cursed") or string.find(nameLower, "idol") then
            return "Mythic"
        elseif string.find(nameLower, "gold bar") or string.find(nameLower, "legendary") or string.find(nameLower, "vault") or string.find(nameLower, "diamond case") or string.find(nameLower, "relic") then
            return "Legendary"
        elseif string.find(nameLower, "epic") or string.find(nameLower, "safe") or string.find(nameLower, "diamond") or string.find(nameLower, "statue") or string.find(nameLower, "crown") then
            return "Epic"
        elseif string.find(nameLower, "rare") or string.find(nameLower, "laptop") or string.find(nameLower, "painting") or string.find(nameLower, "gpu") or string.find(nameLower, "console") then
            return "Rare"
        elseif string.find(nameLower, "uncommon") or string.find(nameLower, "tablet") or string.find(nameLower, "watch") or string.find(nameLower, "camera") or string.find(nameLower, "headphones") then
            return "Uncommon"
        end
    end

    if value then
        if value >= 2500 then
            return "Mythic"
        elseif value >= 1000 then
            return "Legendary"
        elseif value >= 600 then
            return "Epic"
        elseif value >= 300 then
            return "Rare"
        elseif value >= 100 then
            return "Uncommon"
        else
            return "Common"
        end
    end

    return "Common"
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

local function ResolveBasePart(instance)
    if not instance then return nil end
    if instance:IsA("BasePart") then return instance end
    if instance:IsA("Attachment") and instance.Parent and instance.Parent:IsA("BasePart") then
        return instance.Parent
    end
    if instance:IsA("Model") then
        return instance.PrimaryPart or instance:FindFirstChildWhichIsA("BasePart", true)
    end
    return instance:FindFirstChildWhichIsA("BasePart", true)
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

local function TeleportTo(cframe, label)
    local character, humanoid, root = GetCharacterState()
    if not humanoid or humanoid.Health <= 0 or not root then
        CustomNotify("Character unavailable", Color3.fromRGB(255, 100, 100), 2)
        return false
    end

    AllowToxTeleport(1.5, "SOD " .. tostring(label or "Teleport"))
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero

    if character then
        character:PivotTo(cframe)
    else
        root.CFrame = cframe
    end

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
    stroke.Thickness = 12
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Transparency = 0.7
    stroke.Parent = frame

    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(0, 420, 0, 32)
    text.Position = UDim2.new(0.5, -210, 0, 45)
    text.BackgroundTransparency = 1
    text.TextColor3 = Color3.fromRGB(255, 65, 75)
    text.TextStrokeTransparency = 0.2
    text.Font = Enum.Font.GothamBold
    text.TextSize = 17
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
        WarnText.Text = string.format("⚠️ MONSTER [%s] CLOSE: %dm ⚠️", string.upper(tostring(monsterLabel or "ENTITY")), math.floor(closestDist))
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

    -- Disable dark atmosphere / color adjustments if any exist
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
    pcall(function()
        if enable then
            if OrigHoldDurations[prompt] == nil then
                OrigHoldDurations[prompt] = prompt.HoldDuration
            end
            if prompt.HoldDuration ~= 0 then
                prompt.HoldDuration = 0
            end
        elseif OrigHoldDurations[prompt] ~= nil then
            prompt.HoldDuration = OrigHoldDurations[prompt]
            OrigHoldDurations[prompt] = nil
        end
    end)
end

local function TriggerPrompt(prompt)
    if not prompt or not prompt.Parent then return false end
    if fireproximityprompt then
        pcall(function()
            fireproximityprompt(prompt, 0, true)
        end)
        return true
    elseif prompt.InputHoldBegin and prompt.InputHoldEnd then
        pcall(function()
            prompt:InputHoldBegin()
            task.wait(prompt.HoldDuration or 0)
            prompt:InputHoldEnd()
        end)
        return true
    end
    return false
end

-- ==============================================================================
-- LOOT & OBJECT REGISTRATION
-- ==============================================================================

local function IsLootObject(instance, nameLower)
    if not instance then return false end
    if nameLower and HasSubstring(nameLower, BlacklistKeywords) then
        return false
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
        if not HasSubstring(pName, BlacklistKeywords) and HasSubstring(pName, LootKeywords) then
            return true
        end
    end

    return false
end

local function RegisterPrompt(prompt)
    if ItemPrompts[prompt] then return end
    local instance = prompt.Parent
    if not instance then return end

    local name = instance.Name
    if instance:IsA("BasePart") and instance.Parent and instance.Parent ~= Workspace and instance.Parent:IsA("Model") then
        name = instance.Parent.Name
    end

    local nameLower = string.lower(name)

    -- Check if it is a Vent
    if string.find(nameLower, "vent") then
        VentObjects[prompt] = {
            Part = ResolveBasePart(instance),
            Prompt = prompt,
            Name = name
        }
        if Settings.SODInstantVent then
            SetInstantPrompt(prompt, true)
        end
        return
    end

    -- Check if it is a Closet / Locker
    if string.find(nameLower, "closet") or string.find(nameLower, "locker") or string.find(nameLower, "wardrobe") or string.find(nameLower, "hidespot") then
        ClosetObjects[instance] = {
            Part = ResolveBasePart(instance),
            Model = instance:IsA("Model") and instance or instance.Parent,
            Name = name
        }
        return
    end

    -- Check if it is an Exit / Gate
    if string.find(nameLower, "exit") or string.find(nameLower, "escape") or string.find(nameLower, "extract") or string.find(nameLower, "evac") then
        ExitObjects[instance] = {
            Part = ResolveBasePart(instance),
            Label = name
        }
        return
    end

    -- Check if it is Loot
    if IsLootObject(instance, nameLower) then
        local val = ReadNumberAttr(instance, { "Value", "Price", "Worth", "Cash", "Amount" })
            or ReadNumberAttr(instance.Parent, { "Value", "Price", "Worth", "Cash", "Amount" })

        local weight = ReadNumberAttr(instance, { "Weight", "Mass", "Kg", "KG", "CarryWeight", "ItemWeight" })
            or ReadNumberAttr(instance.Parent, { "Weight", "Mass", "Kg", "KG", "CarryWeight", "ItemWeight" })

        local rarity = ReadStringAttr(instance, { "Rarity", "ItemRarity", "Tier" })
            or ReadStringAttr(instance.Parent, { "Rarity", "ItemRarity", "Tier" })

        if not rarity or rarity == "" then
            rarity = InferRarity(nameLower, val)
        end

        ItemPrompts[prompt] = {
            Object = instance,
            Part = ResolveBasePart(prompt),
            Name = name,
            NameLower = nameLower,
            Rarity = rarity,
            Value = val or 0,
            Weight = weight or 0
        }

        if Settings.SODInstantSteal then
            SetInstantPrompt(prompt, true)
        end
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

    -- Check player attribute
    local plr = Players:GetPlayerFromCharacter(model)
    if plr then
        if plr:GetAttribute("IsEntity") == true then return true, plr.Name, plr:GetAttribute("EntityKind") or "PLAYER_MONSTER" end
        local kind = plr:GetAttribute("EntityKind")
        if typeof(kind) == "string" and kind ~= "" then return true, plr.Name, kind end
    end

    -- Check character attributes
    if model:GetAttribute("IsEntity") == true then
        return true, model.Name, model:GetAttribute("EntityKind") or "ENTITY"
    end
    local charKind = model:GetAttribute("EntityKind")
    if typeof(charKind) == "string" and charKind ~= "" then
        return true, model.Name, charKind
    end

    -- Check model name keywords
    local nameLower = string.lower(model.Name)
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

local function HandleDescendant(obj)
    if obj:IsA("ProximityPrompt") then
        RegisterPrompt(obj)
    elseif obj:IsA("Model") then
        if IsMonsterEntity(obj) then
            RegisterMonster(obj)
        end
        local mName = string.lower(obj.Name)
        if string.find(mName, "closet") or string.find(mName, "locker") or string.find(mName, "wardrobe") or string.find(mName, "hidespot") then
            ClosetObjects[obj] = {
                Part = ResolveBasePart(obj),
                Model = obj,
                Name = obj.Name
            }
        elseif string.find(mName, "exit") or string.find(mName, "escape") or string.find(mName, "extract") or string.find(mName, "evac") then
            ExitObjects[obj] = {
                Part = ResolveBasePart(obj),
                Label = obj.Name
            }
        end
    end
end

TrackConnection(Workspace.DescendantAdded:Connect(function(d)
    pcall(HandleDescendant, d)
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

    if Settings.SODMinValueEnabled and (value or 0) < Settings.SODMinValue then
        return false
    end

    return true
end

local function UpdateItemESP(charRoot)
    for prompt, data in pairs(ItemPrompts) do
        if not prompt.Parent or not data.Part or not data.Part.Parent then
            if ItemESPObjects[prompt] then
                pcall(function() ItemESPObjects[prompt].Billboard:Destroy() end)
                ItemESPObjects[prompt] = nil
            end
        else
            local show = Settings.SODItemESP and MatchesRarityFilter(data.Rarity, data.Value)
            local dist = charRoot and (data.Part.Position - charRoot.Position).Magnitude or 0

            if show and dist <= 1200 then
                local esp = ItemESPObjects[prompt]
                if not esp or not esp.Billboard.Parent then
                    local bb = Instance.new("BillboardGui")
                    bb.Name = "ToxSODItemTag"
                    bb.Size = UDim2.new(0, 180, 0, 36)
                    bb.StudsOffset = Vector3.new(0, 2, 0)
                    bb.AlwaysOnTop = true
                    bb.MaxDistance = 1200
                    bb.Adornee = data.Part

                    local label = Instance.new("TextLabel")
                    label.Size = UDim2.new(1, 0, 1, 0)
                    label.BackgroundTransparency = 1
                    label.TextSize = 11
                    label.Font = Enum.Font.GothamBold
                    label.TextStrokeTransparency = 0.2
                    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                    label.Parent = bb

                    bb.Parent = GetGuiParent()
                    esp = { Billboard = bb, Label = label }
                    ItemESPObjects[prompt] = esp
                end

                local rColor = RarityColors[data.Rarity] or Color3.fromRGB(255, 255, 255)
                esp.Label.TextColor3 = rColor

                if Settings.SODItemDetails then
                    esp.Label.Text = string.format("[%s] %s\n%s%s (%dm)",
                        string.upper(data.Rarity),
                        data.Name,
                        FormatCurrency(data.Value),
                        FormatWeight(data.Weight),
                        math.floor(dist)
                    )
                else
                    esp.Label.Text = string.format("[%s] %s (%dm)", string.upper(data.Rarity), data.Name, math.floor(dist))
                end
                esp.Billboard.Enabled = true
            else
                if ItemESPObjects[prompt] then
                    ItemESPObjects[prompt].Billboard.Enabled = false
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
                    MonsterESPObjects[model].Highlight:Destroy()
                    MonsterESPObjects[model].Billboard:Destroy()
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
                local esp = MonsterESPObjects[model]
                if not esp or not esp.Billboard.Parent then
                    local hl = Instance.new("Highlight")
                    hl.Name = "ToxSODMonsterHL"
                    hl.Adornee = model
                    hl.FillColor = Color3.fromRGB(255, 35, 45)
                    hl.FillTransparency = 0.65
                    hl.OutlineColor = Color3.fromRGB(255, 90, 90)
                    hl.OutlineTransparency = 0
                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    hl.Parent = GetGuiParent()

                    local bb = Instance.new("BillboardGui")
                    bb.Name = "ToxSODMonsterTag"
                    bb.Size = UDim2.new(0, 220, 0, 36)
                    bb.StudsOffset = Vector3.new(0, 3.5, 0)
                    bb.AlwaysOnTop = true
                    bb.MaxDistance = 2500
                    bb.Adornee = data.Root

                    local label = Instance.new("TextLabel")
                    label.Size = UDim2.new(1, 0, 1, 0)
                    label.BackgroundTransparency = 1
                    label.TextSize = 13
                    label.Font = Enum.Font.GothamBold
                    label.TextColor3 = Color3.fromRGB(255, 50, 60)
                    label.TextStrokeTransparency = 0.1
                    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                    label.Parent = bb

                    bb.Parent = GetGuiParent()
                    esp = { Highlight = hl, Billboard = bb, Label = label }
                    MonsterESPObjects[model] = esp
                end

                esp.Label.Text = string.format("☠️ [%s] %s\nDistance: %dm",
                    string.upper(tostring(data.Kind or "MONSTER")),
                    data.Name,
                    math.floor(dist)
                )
                esp.Billboard.Enabled = true
                esp.Highlight.Enabled = true
            else
                if MonsterESPObjects[model] then
                    MonsterESPObjects[model].Billboard.Enabled = false
                    MonsterESPObjects[model].Highlight.Enabled = false
                end
            end
        end
    end

    UpdateMonsterWarning(closestDist, closestMonsterName)
    return closestDist
end

local function UpdatePlayerESP(charRoot)
    if not Settings.SODPlayerESP then
        for plr, esp in pairs(PlayerESPObjects) do
            if esp.Billboard then esp.Billboard.Enabled = false end
            if esp.Highlight then esp.Highlight.Enabled = false end
        end
        return
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Player then
            local char = plr.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")

            if root and hum and hum.Health > 0 and not ActiveMonsters[char] then
                local dist = charRoot and (root.Position - charRoot.Position).Magnitude or 0
                local esp = PlayerESPObjects[plr]

                if not esp or not esp.Billboard.Parent then
                    local hl = Instance.new("Highlight")
                    hl.Name = "ToxSODPlayerHL"
                    hl.Adornee = char
                    hl.FillColor = Color3.fromRGB(50, 150, 255)
                    hl.FillTransparency = 0.75
                    hl.OutlineColor = Color3.fromRGB(80, 190, 255)
                    hl.OutlineTransparency = 0
                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    hl.Parent = GetGuiParent()

                    local bb = Instance.new("BillboardGui")
                    bb.Name = "ToxSODPlayerTag"
                    bb.Size = UDim2.new(0, 180, 0, 28)
                    bb.StudsOffset = Vector3.new(0, 2.8, 0)
                    bb.AlwaysOnTop = true
                    bb.MaxDistance = 1500
                    bb.Adornee = root

                    local label = Instance.new("TextLabel")
                    label.Size = UDim2.new(1, 0, 1, 0)
                    label.BackgroundTransparency = 1
                    label.TextSize = 12
                    label.Font = Enum.Font.GothamBold
                    label.TextColor3 = Color3.fromRGB(80, 185, 255)
                    label.TextStrokeTransparency = 0.2
                    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                    label.Parent = bb

                    bb.Parent = GetGuiParent()
                    esp = { Highlight = hl, Billboard = bb, Label = label }
                    PlayerESPObjects[plr] = esp
                end

                esp.Label.Text = string.format("👤 %s (%dm)", plr.DisplayName or plr.Name, math.floor(dist))
                esp.Billboard.Enabled = true
                esp.Highlight.Enabled = true
            else
                if PlayerESPObjects[plr] then
                    PlayerESPObjects[plr].Billboard.Enabled = false
                    PlayerESPObjects[plr].Highlight.Enabled = false
                end
            end
        end
    end
end

local function UpdateExitAndVentESP(charRoot)
    if not Settings.SODExitVentESP then
        for _, esp in pairs(ExitESPObjects) do if esp.Billboard then esp.Billboard.Enabled = false end end
        for _, esp in pairs(VentESPObjects) do if esp.Billboard then esp.Billboard.Enabled = false end end
        for _, esp in pairs(ClosetESPObjects) do if esp.Billboard then esp.Billboard.Enabled = false end end
        return
    end

    -- Exits
    for inst, data in pairs(ExitObjects) do
        if data.Part and data.Part.Parent then
            local dist = charRoot and (data.Part.Position - charRoot.Position).Magnitude or 0
            local esp = ExitESPObjects[inst]
            if not esp or not esp.Billboard.Parent then
                local bb = Instance.new("BillboardGui")
                bb.Name = "ToxSODExitTag"
                bb.Size = UDim2.new(0, 180, 0, 30)
                bb.StudsOffset = Vector3.new(0, 3, 0)
                bb.AlwaysOnTop = true
                bb.MaxDistance = 2500
                bb.Adornee = data.Part

                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(1, 0, 1, 0)
                label.BackgroundTransparency = 1
                label.TextSize = 12
                label.Font = Enum.Font.GothamBold
                label.TextColor3 = Color3.fromRGB(60, 255, 120)
                label.TextStrokeTransparency = 0.2
                label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                label.Parent = bb

                bb.Parent = GetGuiParent()
                esp = { Billboard = bb, Label = label }
                ExitESPObjects[inst] = esp
            end
            esp.Label.Text = string.format("🚪 [EXTRACTION / EXIT]\n%s (%dm)", data.Label or "Exit", math.floor(dist))
            esp.Billboard.Enabled = true
        end
    end

    -- Vents
    for prompt, data in pairs(VentObjects) do
        if data.Part and data.Part.Parent then
            local dist = charRoot and (data.Part.Position - charRoot.Position).Magnitude or 0
            local esp = VentESPObjects[prompt]
            if not esp or not esp.Billboard.Parent then
                local bb = Instance.new("BillboardGui")
                bb.Name = "ToxSODVentTag"
                bb.Size = UDim2.new(0, 140, 0, 26)
                bb.StudsOffset = Vector3.new(0, 2, 0)
                bb.AlwaysOnTop = true
                bb.MaxDistance = 600
                bb.Adornee = data.Part

                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(1, 0, 1, 0)
                label.BackgroundTransparency = 1
                label.TextSize = 11
                label.Font = Enum.Font.GothamBold
                label.TextColor3 = Color3.fromRGB(255, 205, 50)
                label.TextStrokeTransparency = 0.2
                label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                label.Parent = bb

                bb.Parent = GetGuiParent()
                esp = { Billboard = bb, Label = label }
                VentESPObjects[prompt] = esp
            end
            esp.Label.Text = string.format("🕳️ [VENT] (%dm)", math.floor(dist))
            esp.Billboard.Enabled = true
        end
    end

    -- Closets
    for inst, data in pairs(ClosetObjects) do
        if data.Part and data.Part.Parent then
            local dist = charRoot and (data.Part.Position - charRoot.Position).Magnitude or 0
            local esp = ClosetESPObjects[inst]
            if not esp or not esp.Billboard.Parent then
                local bb = Instance.new("BillboardGui")
                bb.Name = "ToxSODClosetTag"
                bb.Size = UDim2.new(0, 140, 0, 26)
                bb.StudsOffset = Vector3.new(0, 2.5, 0)
                bb.AlwaysOnTop = true
                bb.MaxDistance = 500
                bb.Adornee = data.Part

                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(1, 0, 1, 0)
                label.BackgroundTransparency = 1
                label.TextSize = 11
                label.Font = Enum.Font.GothamBold
                label.TextColor3 = Color3.fromRGB(130, 210, 255)
                label.TextStrokeTransparency = 0.2
                label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                label.Parent = bb

                bb.Parent = GetGuiParent()
                esp = { Billboard = bb, Label = label }
                ClosetESPObjects[inst] = esp
            end
            esp.Label.Text = string.format("📦 [CLOSET / HIDE] (%dm)", math.floor(dist))
            esp.Billboard.Enabled = true
        end
    end
end

-- ==============================================================================
-- SURVIVAL & AUTOMATION ENGINE
-- ==============================================================================

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
    if not Settings.SODAntiEncumbrance then return end
    local _, hum = GetCharacterState()
    if hum and hum.Health > 0 then
        local target = tonumber(Settings.SODCustomSpeed) or 22
        if hum.WalkSpeed < target then
            hum.WalkSpeed = target
        end
    end
end

local function AutoStealAura(charRoot)
    if not Settings.SODAutoStealAura or not charRoot then return end
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

local function CheckAutoEvacuate(closestDist)
    if not Settings.SODAutoEvacuate or not closestDist then return end
    if closestDist <= Settings.SODAutoEvacuateDistance then
        -- Find nearest closet or teleport up to sky platform
        local char, hum, root = GetCharacterState()
        if not root then return end

        local nearestCloset = nil
        local nearestClosetDist = 9999

        for _, cData in pairs(ClosetObjects) do
            if cData.Part and cData.Part.Parent then
                local cDist = (cData.Part.Position - root.Position).Magnitude
                if cDist < nearestClosetDist then
                    nearestClosetDist = cDist
                    nearestCloset = cData
                end
            end
        end

        if nearestCloset and nearestClosetDist <= 75 then
            TeleportTo(nearestCloset.Part.CFrame + Vector3.new(0, 3, 0), "Emergency Closet Hide")
        else
            -- Elevate player
            TeleportTo(root.CFrame + Vector3.new(0, 45, 0), "Emergency Evacuation")
        end
        CustomNotify("⚠️ AUTO EVACUATED: Monster within " .. math.floor(closestDist) .. "m!", Color3.fromRGB(255, 60, 60), 3)
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

    -- Enforce speed / anti-encumbrance
    if hum and hum.Health > 0 and Settings.SODAntiEncumbrance then
        local target = tonumber(Settings.SODCustomSpeed) or 22
        if hum.WalkSpeed < target then
            hum.WalkSpeed = target
        end
    end

    -- Stamina refill
    if now - LastStaminaCheck >= 0.25 then
        LastStaminaCheck = now
        if Settings.SODInfiniteStamina then
            pcall(RefillStamina)
        end
    end

    -- Auto-Steal Aura
    if now - LastAuraCheck >= 0.2 then
        LastAuraCheck = now
        if Settings.SODAutoStealAura and root then
            pcall(AutoStealAura, root)
        end
    end

    -- ESP & Monster Warning
    if now - LastESPInterval >= 0.15 then
        LastESPInterval = now
        local closestDist = UpdateMonsterESP(root)
        UpdateItemESP(root)
        UpdatePlayerESP(root)
        UpdateExitAndVentESP(root)

        if root and closestDist then
            CheckAutoEvacuate(closestDist)
        end
    end
end))

if Settings.SODFullBright then
    pcall(ApplyFullBright)
end

-- ==============================================================================
-- UI BUILDER - SECTION 1: VISUALS & ESP
-- ==============================================================================

CreateSODSection("VISUALS & ESP (LOOT & MONSTER)")

SODCreateToggle(
    "Item ESP",
    GamePage,
    Settings.SODItemESP,
    function(v)
        Settings.SODItemESP = v == true
        if not v then
            for _, esp in pairs(ItemESPObjects) do
                if esp.Billboard then esp.Billboard.Enabled = false end
            end
        end
        AutoSaveConfiguration()
    end,
    "SODItemESP"
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
    "Min Item Value ($)",
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

SODCreateToggle(
    "Show Weight & Distance",
    GamePage,
    Settings.SODItemDetails,
    function(v)
        Settings.SODItemDetails = v == true
        AutoSaveConfiguration()
    end,
    "SODItemDetails"
)

SODCreateToggle(
    "Monster / Entity ESP",
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

SODCreateToggleWithValue(
    "Monster Radar Alert",
    GamePage,
    Settings.SODMonsterWarn,
    Settings.SODMonsterWarnDistance or 60,
    function(v)
        Settings.SODMonsterWarn = v == true
        if not v and WarnFrame then
            WarnFrame.Visible = false
        end
        AutoSaveConfiguration()
    end,
    function(val)
        Settings.SODMonsterWarnDistance = math.clamp(tonumber(val) or 60, 20, 250)
        AutoSaveConfiguration()
    end,
    "SODMonsterWarn"
)

SODCreateToggle(
    "Player / Survivor ESP",
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
    "Exit & Vent ESP",
    GamePage,
    Settings.SODExitVentESP,
    function(v)
        Settings.SODExitVentESP = v == true
        if not v then
            for _, esp in pairs(ExitESPObjects) do if esp.Billboard then esp.Billboard.Enabled = false end end
            for _, esp in pairs(VentESPObjects) do if esp.Billboard then esp.Billboard.Enabled = false end end
            for _, esp in pairs(ClosetESPObjects) do if esp.Billboard then esp.Billboard.Enabled = false end end
        end
        AutoSaveConfiguration()
    end,
    "SODExitVentESP"
)

SODCreateToggle(
    "FullBright & Vision",
    GamePage,
    Settings.SODFullBright,
    function(v)
        Settings.SODFullBright = v == true
        if v then
            ApplyFullBright()
        else
            RestoreLighting()
        end
        AutoSaveConfiguration()
    end,
    "SODFullBright"
)

-- ==============================================================================
-- UI BUILDER - SECTION 2: AUTO-STEAL & FAST ACTIONS
-- ==============================================================================

CreateSODSection("AUTO-STEAL & LOOTING")

SODCreateToggle(
    "Instant Steal (0s Prompts)",
    GamePage,
    Settings.SODInstantSteal,
    function(v)
        Settings.SODInstantSteal = v == true
        for prompt, _ in pairs(ItemPrompts) do
            SetInstantPrompt(prompt, v)
        end
        AutoSaveConfiguration()
    end,
    "SODInstantSteal"
)

SODCreateToggleWithValue(
    "Auto Steal Aura",
    GamePage,
    Settings.SODAutoStealAura,
    Settings.SODAutoStealRange or 15,
    function(v)
        Settings.SODAutoStealAura = v == true
        AutoSaveConfiguration()
    end,
    function(val)
        Settings.SODAutoStealRange = math.clamp(tonumber(val) or 15, 5, 45)
        AutoSaveConfiguration()
    end,
    "SODAutoStealAura"
)

SODCreateToggle(
    "Instant Vent Unscrew",
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

SODCreateButton("Teleport to Highest Value Loot", GamePage, function()
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
        TeleportTo(bestData.Part.CFrame + Vector3.new(0, 3, 0), bestData.Name .. " (" .. FormatCurrency(bestData.Value) .. ")")
        task.wait(0.15)
        TriggerPrompt(bestPrompt)
    else
        CustomNotify("No loot found on map", Color3.fromRGB(255, 150, 50), 2)
    end
end)

SODCreateButton("Teleport to Nearest Filtered Loot", GamePage, function()
    local _, _, root = GetCharacterState()
    if not root then return end

    local nearestData = nil
    local nearestPrompt = nil
    local nearestDist = 99999

    for prompt, data in pairs(ItemPrompts) do
        if prompt.Parent and data.Part and data.Part.Parent then
            if MatchesRarityFilter(data.Rarity, data.Value) then
                local dist = (data.Part.Position - root.Position).Magnitude
                if dist < nearestDist then
                    nearestDist = dist
                    nearestData = data
                    nearestPrompt = prompt
                end
            end
        end
    end

    if nearestData and nearestData.Part then
        TeleportTo(nearestData.Part.CFrame + Vector3.new(0, 3, 0), nearestData.Name .. " [" .. tostring(nearestData.Rarity) .. "]")
        task.wait(0.15)
        TriggerPrompt(nearestPrompt)
    else
        CustomNotify("No matching loot nearby", Color3.fromRGB(255, 150, 50), 2)
    end
end)

-- ==============================================================================
-- UI BUILDER - SECTION 3: SURVIVAL & ANTI-MONSTER
-- ==============================================================================

CreateSODSection("SURVIVAL & ANTI-MONSTER")

SODCreateToggle(
    "Infinite Stamina",
    GamePage,
    Settings.SODInfiniteStamina,
    function(v)
        Settings.SODInfiniteStamina = v == true
        if v then
            pcall(RefillStamina)
        end
        AutoSaveConfiguration()
    end,
    "SODInfiniteStamina"
)

SODCreateToggleWithValue(
    "Anti-Encumbrance (Speed)",
    GamePage,
    Settings.SODAntiEncumbrance,
    Settings.SODCustomSpeed or 22,
    function(v)
        Settings.SODAntiEncumbrance = v == true
        if v then
            EnforceSpeed()
        end
        AutoSaveConfiguration()
    end,
    function(val)
        Settings.SODCustomSpeed = math.clamp(tonumber(val) or 22, 16, 50)
        EnforceSpeed()
        AutoSaveConfiguration()
    end,
    "SODAntiEncumbrance"
)

SODCreateToggleWithValue(
    "Auto Evacuate on Danger",
    GamePage,
    Settings.SODAutoEvacuate,
    Settings.SODAutoEvacuateDistance or 28,
    function(v)
        Settings.SODAutoEvacuate = v == true
        AutoSaveConfiguration()
    end,
    function(val)
        Settings.SODAutoEvacuateDistance = math.clamp(tonumber(val) or 28, 15, 60)
        AutoSaveConfiguration()
    end,
    "SODAutoEvacuate"
)

SODCreateToggle(
    "Damage Shield (Godmode Bypass)",
    GamePage,
    Settings.SODDamageShield,
    function(v)
        Settings.SODDamageShield = v == true
        local _, hum = GetCharacterState()
        if hum then
            pcall(function()
                hum:SetStateEnabled(Enum.HumanoidStateType.Dead, not v)
            end)
        end
        AutoSaveConfiguration()
    end,
    "SODDamageShield"
)

SODCreateToggleWithValue(
    "Safe Sky Platform",
    GamePage,
    Settings.SODSafePlatform,
    Settings.SODPlatformHeight or 350,
    function(v)
        Settings.SODSafePlatform = v == true
        if v then
            EnsureSafePlatform()
        else
            ClearSafePlatform()
        end
        AutoSaveConfiguration()
    end,
    function(val)
        Settings.SODPlatformHeight = math.clamp(tonumber(val) or 350, 150, 900)
        if SafePlatformModel and SafePlatformModel:FindFirstChild("Floor") then
            SafePlatformModel.Floor.CFrame = CFrame.new(0, Settings.SODPlatformHeight, 0)
        end
        AutoSaveConfiguration()
    end,
    "SODSafePlatform"
)

SODCreateButton("Teleport to Sky Platform", GamePage, function()
    local platform = EnsureSafePlatform()
    if platform and platform:FindFirstChild("Floor") then
        TeleportTo(platform.Floor.CFrame + Vector3.new(0, 4, 0), "Sky Platform")
    end
end)

-- ==============================================================================
-- UI BUILDER - SECTION 4: TELEPORTS & ESCAPE
-- ==============================================================================

CreateSODSection("TELEPORTS & ESCAPE")

SODCreateButton("Teleport to Extraction / Exit", GamePage, function()
    local bestExit = nil
    local _, _, root = GetCharacterState()

    for _, data in pairs(ExitObjects) do
        if data.Part and data.Part.Parent then
            bestExit = data
            break
        end
    end

    if bestExit and bestExit.Part then
        TeleportTo(bestExit.Part.CFrame + Vector3.new(0, 4, 0), "Exit Gate")
    else
        CustomNotify("Extraction point not detected yet", Color3.fromRGB(255, 150, 50), 2)
    end
end)

SODCreateButton("Teleport to Nearest Closet / Locker", GamePage, function()
    local _, _, root = GetCharacterState()
    if not root then return end

    local nearest = nil
    local minDist = 99999

    for _, data in pairs(ClosetObjects) do
        if data.Part and data.Part.Parent then
            local dist = (data.Part.Position - root.Position).Magnitude
            if dist < minDist then
                minDist = dist
                nearest = data
            end
        end
    end

    if nearest and nearest.Part then
        TeleportTo(nearest.Part.CFrame + Vector3.new(0, 3, 0), "Closet (" .. math.floor(minDist) .. "m)")
    else
        CustomNotify("No closet found nearby", Color3.fromRGB(255, 150, 50), 2)
    end
end)

SODCreateButton("Teleport to Nearest Vent", GamePage, function()
    local _, _, root = GetCharacterState()
    if not root then return end

    local nearest = nil
    local minDist = 99999

    for _, data in pairs(VentObjects) do
        if data.Part and data.Part.Parent then
            local dist = (data.Part.Position - root.Position).Magnitude
            if dist < minDist then
                minDist = dist
                nearest = data
            end
        end
    end

    if nearest and nearest.Part then
        TeleportTo(nearest.Part.CFrame + Vector3.new(0, 3, 0), "Vent (" .. math.floor(minDist) .. "m)")
    else
        CustomNotify("No vents found nearby", Color3.fromRGB(255, 150, 50), 2)
    end
end)

SODCreateToggle(
    "Ctrl + Click TP",
    GamePage,
    Settings.SODClickTP,
    function(v)
        Settings.SODClickTP = v == true
        AutoSaveConfiguration()
    end,
    "SODClickTP"
)

SODCreateButton("Teleport to Random Survivor", GamePage, function()
    local survivors = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Player then
            local char = plr.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root and hum and hum.Health > 0 and not ActiveMonsters[char] then
                table.insert(survivors, { Player = plr, Root = root })
            end
        end
    end

    if #survivors > 0 then
        local choice = survivors[math.random(1, #survivors)]
        TeleportTo(choice.Root.CFrame + Vector3.new(0, 3, 2), choice.Player.DisplayName or choice.Player.Name)
    else
        CustomNotify("No other survivors available", Color3.fromRGB(255, 150, 50), 2)
    end
end)

-- ==============================================================================
-- CLEANUP HANDLER
-- ==============================================================================

getgenv().ToxSODCleanup = function()
    getgenv().ToxSODGeneration = (tonumber(getgenv().ToxSODGeneration) or 0) + 1

    for _, conn in ipairs(SODConnections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(SODConnections)

    for _, esp in pairs(ItemESPObjects) do
        pcall(function() esp.Billboard:Destroy() end)
    end
    table.clear(ItemESPObjects)

    for _, esp in pairs(MonsterESPObjects) do
        pcall(function()
            esp.Highlight:Destroy()
            esp.Billboard:Destroy()
        end)
    end
    table.clear(MonsterESPObjects)

    for _, esp in pairs(PlayerESPObjects) do
        pcall(function()
            esp.Highlight:Destroy()
            esp.Billboard:Destroy()
        end)
    end
    table.clear(PlayerESPObjects)

    for _, esp in pairs(ExitESPObjects) do pcall(function() esp.Billboard:Destroy() end) end
    for _, esp in pairs(VentESPObjects) do pcall(function() esp.Billboard:Destroy() end) end
    for _, esp in pairs(ClosetESPObjects) do pcall(function() esp.Billboard:Destroy() end) end
    table.clear(ExitESPObjects)
    table.clear(VentESPObjects)
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
        root.Anchored = false
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

