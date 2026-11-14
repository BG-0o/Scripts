local PiggyPlaceId = 4623386862

if game.PlaceId ~= PiggyPlaceId then
    return
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Player = Players.LocalPlayer
local Settings = getgenv().Settings
local GamePage = getgenv().GamePage
local CreateToggle = getgenv().CreateToggle
local CreateToggleWithSlider = getgenv().CreateToggleWithSlider
local CreateButton = getgenv().CreateButton
local CreateDropdown = getgenv().CreateDropdown
local CustomNotify = getgenv().CustomNotify or function() end
local AutoSaveConfiguration = getgenv().AutoSaveConfiguration or function() end
local AddConnection = getgenv().AddConnection or function(connection)
    return connection
end

if not Settings
or not GamePage
or not CreateToggle
or not CreateButton
or not CreateDropdown then
    return
end

local PIGGYModuleVersion = "2026-11-14-piggy-initial-1"

if getgenv().ToxPIGGYModuleLoadedJobId == game.JobId
and getgenv().ToxPIGGYModuleVersion == PIGGYModuleVersion
and getgenv().ToxPIGGYModulePage == GamePage
and not getgenv().Destroyed then
    return
end

if getgenv().ToxPIGGYCleanup then
    pcall(getgenv().ToxPIGGYCleanup)
end

for _, child in ipairs(GamePage:GetChildren()) do
    if child:IsA("GuiObject") then
        child:Destroy()
    end
end

Settings.PIGGYThreatESP = Settings.PIGGYThreatESP == true
Settings.PIGGYItemESP = Settings.PIGGYItemESP == true
Settings.PIGGYAlert = Settings.PIGGYAlert == true
Settings.PIGGYAlertRange = math.clamp(tonumber(Settings.PIGGYAlertRange) or 40, 10, 150)
Settings.PIGGYNoDarkness = Settings.PIGGYNoDarkness == true
Settings.PIGGYCollapsedSections = typeof(Settings.PIGGYCollapsedSections) == "table"
    and Settings.PIGGYCollapsedSections
    or {}

local PIGGYConnections = {}
local PIGGYCurrentSection = nil
local PIGGYSections = {}

local function TrackConnection(connection)
    if connection then
        table.insert(PIGGYConnections, connection)
        AddConnection(connection)
    end
    return connection
end

local function ApplySectionState(section)
    if typeof(section) ~= "table" then
        return
    end
    local collapsed = Settings.PIGGYCollapsedSections[section.Key] == true
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
    if PIGGYCurrentSection and typeof(object) == "Instance" and object:IsA("GuiObject") then
        table.insert(PIGGYCurrentSection.Controls, object)
        ApplySectionState(PIGGYCurrentSection)
    end
    return object
end

local function CreatePIGGYSection(text)
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
    local section = { Name = name, Key = key, Header = button, Controls = {} }
    table.insert(PIGGYSections, section)
    PIGGYCurrentSection = section
    TrackConnection(button.MouseButton1Click:Connect(function()
        Settings.PIGGYCollapsedSections[key] = not Settings.PIGGYCollapsedSections[key]
        ApplySectionState(section)
        AutoSaveConfiguration()
    end))
    ApplySectionState(section)
    return button
end

local function GetMyCharacter()
    local character = Player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    return character, humanoid, root
end

local function TeleportTo(cframe, label)
    local _, humanoid, root = GetMyCharacter()
    if not root or not humanoid or humanoid.Health <= 0 then
        CustomNotify("Character unavailable", Color3.fromRGB(255, 180, 70), 3)
        return false
    end
    if humanoid.SeatPart then
        humanoid.Sit = false
        task.wait(0.1)
    end
    if getgenv().ToxSafeTeleportToCFrame then
        return getgenv().ToxSafeTeleportToCFrame(cframe, false, "Piggy " .. tostring(label))
    end
    if getgenv().RecordToxTeleportReturn then
        getgenv().RecordToxTeleportReturn()
    end
    root.CFrame = cframe
    return true
end


local ThreatColor = Color3.fromRGB(255, 70, 90)
local ItemColor = Color3.fromRGB(255, 215, 80)
local ThreatWords = { "piggy", "enemy", "traitor", "infected" }

local VisualFolder = Instance.new("Folder")
VisualFolder.Name = "ToxPiggyVisuals"
pcall(function()
    VisualFolder.Parent = (gethui and gethui()) or game:GetService("CoreGui")
end)
if not VisualFolder.Parent then
    VisualFolder.Parent = Workspace
end

local function HasThreatWord(text)
    text = string.lower(tostring(text))
    for _, word in ipairs(ThreatWords) do
        if string.find(text, word, 1, true) then
            return true
        end
    end
    return false
end

local function IsThreatPlayer(other)
    local character = other.Character
    if not character then
        return false
    end
    if other.Team and HasThreatWord(other.Team.Name) then
        return true
    end
    for _, child in ipairs(character:GetChildren()) do
        if HasThreatWord(child.Name) and not child:IsA("Accessory") then
            return true
        end
        if child:IsA("Tool") and (string.lower(child.Name) == "bat" or HasThreatWord(child.Name)) then
            return true
        end
    end
    return false
end

local function GetThreats()
    local threats = {}
    local characters = {}
    for _, other in ipairs(Players:GetPlayers()) do
        if other.Character then
            characters[other.Character] = true
            if other ~= Player and IsThreatPlayer(other) then
                table.insert(threats, { Model = other.Character, Name = other.DisplayName .. " (Piggy)" })
            end
        end
    end
    for _, humanoid in ipairs(Workspace:GetDescendants()) do
        if humanoid:IsA("Humanoid") then
            local model = humanoid.Parent
            if model and model:IsA("Model") and not characters[model] and humanoid.Health > 0 then
                table.insert(threats, { Model = model, Name = model.Name .. " (Bot)" })
            end
        end
    end
    return threats
end

local function GetModelPart(model)
    if model:IsA("BasePart") then
        return model
    end
    return model:FindFirstChild("HumanoidRootPart")
        or (model:IsA("Model") and model.PrimaryPart)
        or model:FindFirstChildWhichIsA("BasePart", true)
end

local Tags = {}
local function SetTag(key, adornee, text, color, withHighlight)
    local tag = Tags[key]
    if not tag or not tag.Billboard.Parent then
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "Tag"
        billboard.AlwaysOnTop = true
        billboard.Size = UDim2.new(0, 160, 0, 22)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.Parent = VisualFolder
        local label = Instance.new("TextLabel")
        label.BackgroundTransparency = 1
        label.Size = UDim2.new(1, 0, 1, 0)
        label.Font = Enum.Font.GothamBold
        label.TextSize = 13
        label.TextStrokeTransparency = 0.4
        label.Parent = billboard
        tag = { Billboard = billboard, Label = label }
        Tags[key] = tag
    end
    tag.Billboard.Adornee = adornee
    tag.Label.Text = text
    tag.Label.TextColor3 = color
    if withHighlight then
        if not tag.Highlight or not tag.Highlight.Parent then
            local highlight = Instance.new("Highlight")
            highlight.FillTransparency = 0.6
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.Parent = VisualFolder
            tag.Highlight = highlight
        end
        tag.Highlight.Adornee = withHighlight
        tag.Highlight.FillColor = color
        tag.Highlight.OutlineColor = color
    end
    tag.Seen = true
end

local function ClearTags(prefix)
    for key, tag in pairs(Tags) do
        if not prefix or string.sub(key, 1, #prefix) == prefix then
            pcall(function() tag.Billboard:Destroy() end)
            if tag.Highlight then
                pcall(function() tag.Highlight:Destroy() end)
            end
            Tags[key] = nil
        end
    end
end

local function SweepUnseen(prefix)
    for key, tag in pairs(Tags) do
        if string.sub(key, 1, #prefix) == prefix then
            if tag.Seen then
                tag.Seen = false
            else
                pcall(function() tag.Billboard:Destroy() end)
                if tag.Highlight then
                    pcall(function() tag.Highlight:Destroy() end)
                end
                Tags[key] = nil
            end
        end
    end
end

local function RefreshThreatESP(threats)
    local _, _, root = GetMyCharacter()
    for _, threat in ipairs(threats) do
        local part = GetModelPart(threat.Model)
        if part then
            local distance = root and math.floor((root.Position - part.Position).Magnitude) or 0
            SetTag("T:" .. threat.Model:GetDebugId(), part, threat.Name .. " [" .. distance .. "m]", ThreatColor, threat.Model)
        end
    end
    SweepUnseen("T:")
end

local function IsItemCandidate(detector)
    local holder = detector.Parent
    if not holder then
        return nil
    end
    local model = holder:IsA("Model") and holder or holder:FindFirstAncestorWhichIsA("Model") or holder
    if model:FindFirstChildOfClass("Humanoid") then
        return nil
    end
    if model ~= holder and #model:GetDescendants() > 60 then
        model = holder
    end
    local name = string.lower(model.Name)
    if string.find(name, "door", 1, true) or string.find(name, "window", 1, true) or string.find(name, "vent", 1, true) then
        return nil
    end
    return model
end

local ItemCache = {}
local lastItemScan = 0
local function RefreshItemESP()
    local now = os.clock()
    if now - lastItemScan > 2 then
        lastItemScan = now
        table.clear(ItemCache)
        for _, d in ipairs(Workspace:GetDescendants()) do
            if d:IsA("ClickDetector") or (d:IsA("ProximityPrompt") and d.Enabled) then
                local model = IsItemCandidate(d)
                if model then
                    ItemCache[model] = true
                end
            end
        end
    end
    local _, _, root = GetMyCharacter()
    for model in pairs(ItemCache) do
        if model.Parent then
            local part = GetModelPart(model)
            if part then
                local distance = root and math.floor((root.Position - part.Position).Magnitude) or 0
                SetTag("I:" .. model:GetDebugId(), part, model.Name .. " [" .. distance .. "m]", ItemColor, nil)
            end
        end
    end
    SweepUnseen("I:")
end

local LightingBackup = nil
local AtmosphereBackup = {}
local function ApplyNoDarkness(enabled)
    if enabled then
        if not LightingBackup then
            LightingBackup = {
                Brightness = Lighting.Brightness,
                Ambient = Lighting.Ambient,
                OutdoorAmbient = Lighting.OutdoorAmbient,
                FogEnd = Lighting.FogEnd,
                FogStart = Lighting.FogStart,
                GlobalShadows = Lighting.GlobalShadows,
            }
        end
        Lighting.Brightness = 2
        Lighting.Ambient = Color3.fromRGB(170, 170, 170)
        Lighting.OutdoorAmbient = Color3.fromRGB(170, 170, 170)
        Lighting.FogStart = 0
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        for _, effect in ipairs(Lighting:GetChildren()) do
            if effect:IsA("Atmosphere") and AtmosphereBackup[effect] == nil then
                AtmosphereBackup[effect] = { Density = effect.Density, Haze = effect.Haze }
                effect.Density = 0
                effect.Haze = 0
            elseif (effect:IsA("ColorCorrectionEffect") or effect:IsA("BlurEffect")) and AtmosphereBackup[effect] == nil then
                AtmosphereBackup[effect] = { Enabled = effect.Enabled }
                effect.Enabled = false
            end
        end
    else
        if LightingBackup then
            for key, value in pairs(LightingBackup) do
                pcall(function() Lighting[key] = value end)
            end
            LightingBackup = nil
        end
        for effect, values in pairs(AtmosphereBackup) do
            if effect and effect.Parent then
                for key, value in pairs(values) do
                    pcall(function() effect[key] = value end)
                end
            end
        end
        table.clear(AtmosphereBackup)
    end
end

local alertInside = {}
local function RunAlert(threats)
    local _, _, root = GetMyCharacter()
    if not root then
        return
    end
    local range = Settings.PIGGYAlertRange
    local current = {}
    for _, threat in ipairs(threats) do
        local part = GetModelPart(threat.Model)
        if part then
            local distance = (root.Position - part.Position).Magnitude
            if distance <= range then
                current[threat.Model] = true
                if not alertInside[threat.Model] then
                    CustomNotify("! " .. threat.Name .. " close: " .. math.floor(distance) .. "m", ThreatColor, 3)
                end
            end
        end
    end
    alertInside = current
end

local function BuildScanReport()
    local lines = { "== ToxHub Piggy scan | PlaceId " .. tostring(game.PlaceId) .. " ==" }
    table.insert(lines, "-- Players (team / character children)")
    for _, other in ipairs(Players:GetPlayers()) do
        local names = {}
        if other.Character then
            for _, c in ipairs(other.Character:GetChildren()) do
                if not c:IsA("BasePart") and not c:IsA("Accessory") then
                    table.insert(names, c.ClassName .. ":" .. c.Name)
                end
            end
        end
        table.insert(lines, other.Name .. " | team=" .. tostring(other.Team and other.Team.Name) .. " | " .. table.concat(names, ", "))
    end
    table.insert(lines, "-- Clickable / prompt objects")
    local count = 0
    for _, d in ipairs(Workspace:GetDescendants()) do
        if (d:IsA("ClickDetector") or d:IsA("ProximityPrompt")) and count < 150 then
            count += 1
            table.insert(lines, d.ClassName .. "  " .. d:GetFullName())
        end
    end
    table.insert(lines, "-- Workspace children")
    for _, child in ipairs(Workspace:GetChildren()) do
        table.insert(lines, child.ClassName .. "  " .. child.Name)
    end
    table.insert(lines, "-- Remotes")
    for _, d in ipairs(ReplicatedStorage:GetDescendants()) do
        if d:IsA("RemoteEvent") or d:IsA("RemoteFunction") then
            table.insert(lines, d.ClassName .. "  " .. d:GetFullName())
        end
    end
    return table.concat(lines, "\n")
end

CreatePIGGYSection("ESP")

TrackControl(CreateToggle("Piggy / Bot ESP", GamePage, Settings.PIGGYThreatESP, function(value)
    Settings.PIGGYThreatESP = value == true
    if not Settings.PIGGYThreatESP then
        ClearTags("T:")
    end
    AutoSaveConfiguration()
end, "PIGGYThreatESP"))

TrackControl(CreateToggle("Item ESP", GamePage, Settings.PIGGYItemESP, function(value)
    Settings.PIGGYItemESP = value == true
    lastItemScan = 0
    if not Settings.PIGGYItemESP then
        ClearTags("I:")
    end
    AutoSaveConfiguration()
end, "PIGGYItemESP"))

CreatePIGGYSection("ALERTS")

local function OnAlert(value)
    Settings.PIGGYAlert = value == true
    alertInside = {}
    AutoSaveConfiguration()
end
local function OnAlertRange(value)
    Settings.PIGGYAlertRange = math.clamp(tonumber(value) or 40, 10, 150)
    AutoSaveConfiguration()
end
if type(CreateToggleWithSlider) == "function" then
    TrackControl(CreateToggleWithSlider("Piggy Nearby Alert", GamePage, 10, 150, Settings.PIGGYAlert, Settings.PIGGYAlertRange, " studs", OnAlert, OnAlertRange, "PIGGYAlert"))
else
    TrackControl(CreateToggle("Piggy Nearby Alert", GamePage, Settings.PIGGYAlert, OnAlert, "PIGGYAlert"))
end

CreatePIGGYSection("VISUAL")

TrackControl(CreateToggle("No Darkness / Fog", GamePage, Settings.PIGGYNoDarkness, function(value)
    Settings.PIGGYNoDarkness = value == true
    ApplyNoDarkness(Settings.PIGGYNoDarkness)
    AutoSaveConfiguration()
end, "PIGGYNoDarkness"))

CreatePIGGYSection("TOOLS")

TrackControl(CreateButton("Scan Game (copy to clipboard)", GamePage, function()
    local report = BuildScanReport()
    local copied = false
    if setclipboard then
        copied = pcall(setclipboard, report)
    end
    if copied then
        CustomNotify("Scan copied - paste it to the dev", Color3.fromRGB(120, 255, 160), 5)
    else
        print(report)
        CustomNotify("Clipboard unavailable - scan printed in F9", Color3.fromRGB(255, 180, 70), 5)
    end
end))

local lastTick = 0
TrackConnection(RunService.Heartbeat:Connect(function()
    if getgenv().Destroyed then
        return
    end
    local now = os.clock()
    if now - lastTick < 0.25 then
        return
    end
    lastTick = now
    local threats = nil
    if Settings.PIGGYThreatESP or Settings.PIGGYAlert then
        threats = GetThreats()
    end
    if Settings.PIGGYThreatESP then
        RefreshThreatESP(threats)
    end
    if Settings.PIGGYAlert then
        RunAlert(threats)
    end
    if Settings.PIGGYItemESP then
        RefreshItemESP()
    end
    if Settings.PIGGYNoDarkness then
        ApplyNoDarkness(true)
    end
end))

getgenv().ToxPIGGYCleanup = function()
    ApplyNoDarkness(false)
    ClearTags(nil)
    for _, connection in ipairs(PIGGYConnections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    table.clear(PIGGYConnections)
    pcall(function() VisualFolder:Destroy() end)
end

getgenv().ToxPIGGYModuleLoadedJobId = game.JobId
getgenv().ToxPIGGYModuleVersion = PIGGYModuleVersion
getgenv().ToxPIGGYModulePage = GamePage
