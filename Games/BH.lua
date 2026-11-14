local BHPlaceId = 4924922222

if game.PlaceId ~= BHPlaceId then
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
local CreateToggleWithChoice = getgenv().CreateToggleWithChoice
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

local BHModuleVersion = "2026-11-14-bh-initial-1"

if getgenv().ToxBHModuleLoadedJobId == game.JobId
and getgenv().ToxBHModuleVersion == BHModuleVersion
and getgenv().ToxBHModulePage == GamePage
and not getgenv().Destroyed then
    return
end

if getgenv().ToxBHCleanup then
    pcall(getgenv().ToxBHCleanup)
end

for _, child in ipairs(GamePage:GetChildren()) do
    if child:IsA("GuiObject") then
        child:Destroy()
    end
end

Settings.BHAntiSit = Settings.BHAntiSit == true
Settings.BHAntiHouseBan = Settings.BHAntiHouseBan == true
Settings.BHMuteOthers = Settings.BHMuteOthers == true
Settings.BHRevealInvisible = Settings.BHRevealInvisible == true
Settings.BHHideVehicles = Settings.BHHideVehicles == true
Settings.BHLockTime = Settings.BHLockTime == true
Settings.BHLockTimeMode = tostring(Settings.BHLockTimeMode or "Day")
if Settings.BHLockTimeMode ~= "Day" and Settings.BHLockTimeMode ~= "Night" and Settings.BHLockTimeMode ~= "Sunset" then
    Settings.BHLockTimeMode = "Day"
end
Settings.BHCollapsedSections = typeof(Settings.BHCollapsedSections) == "table"
    and Settings.BHCollapsedSections
    or {}

local BHConnections = {}
local BHCurrentSection = nil
local BHSections = {}

local function TrackConnection(connection)
    if connection then
        table.insert(BHConnections, connection)
        AddConnection(connection)
    end
    return connection
end

local function ApplySectionState(section)
    if typeof(section) ~= "table" then
        return
    end
    local collapsed = Settings.BHCollapsedSections[section.Key] == true
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
    if BHCurrentSection and typeof(object) == "Instance" and object:IsA("GuiObject") then
        table.insert(BHCurrentSection.Controls, object)
        ApplySectionState(BHCurrentSection)
    end
    return object
end

local function CreateBHSection(text)
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
    table.insert(BHSections, section)
    BHCurrentSection = section
    TrackConnection(button.MouseButton1Click:Connect(function()
        Settings.BHCollapsedSections[key] = not Settings.BHCollapsedSections[key]
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
        return getgenv().ToxSafeTeleportToCFrame(cframe, false, "BH " .. tostring(label))
    end
    if getgenv().RecordToxTeleportReturn then
        getgenv().RecordToxTeleportReturn()
    end
    root.CFrame = cframe
    return true
end

local function IsOtherPlayersCharacter(instance)
    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= Player and other.Character and instance:IsDescendantOf(other.Character) then
            return true
        end
    end
    return false
end

local function IsMine(instance)
    local character = Player.Character
    return character ~= nil and instance:IsDescendantOf(character)
end

local SeatedWasEnabled = nil
local function ApplyAntiSit(enabled)
    local _, humanoid = GetMyCharacter()
    if not humanoid then
        return
    end
    if enabled then
        if SeatedWasEnabled == nil then
            SeatedWasEnabled = humanoid:GetStateEnabled(Enum.HumanoidStateType.Seated)
        end
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
        if humanoid.SeatPart then
            humanoid.Sit = false
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    elseif SeatedWasEnabled ~= nil then
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, SeatedWasEnabled ~= false)
        SeatedWasEnabled = nil
    end
end

local BanPartDefaults = {}
local function IsBanBarrier(part)
    local name = string.lower(part.Name)
    if string.find(name, "ban", 1, true) and not string.find(name, "banan", 1, true) and not string.find(name, "bank", 1, true) then
        return true
    end
    return false
end
local function ApplyAntiHouseBan(enabled)
    if enabled then
        for _, part in ipairs(Workspace:GetDescendants()) do
            if part:IsA("BasePart") and not BanPartDefaults[part] and IsBanBarrier(part) and not IsMine(part) then
                BanPartDefaults[part] = { CanCollide = part.CanCollide, CanTouch = part.CanTouch }
                pcall(function()
                    part.CanCollide = false
                    part.CanTouch = false
                end)
            end
        end
    else
        for part, defaults in pairs(BanPartDefaults) do
            if part and part.Parent then
                pcall(function()
                    part.CanCollide = defaults.CanCollide
                    part.CanTouch = defaults.CanTouch
                end)
            end
        end
        table.clear(BanPartDefaults)
    end
end

local function GetVehicleModel(instance)
    local current = instance
    local found = nil
    while current and current ~= Workspace do
        if current:IsA("Model") and current:FindFirstChildWhichIsA("VehicleSeat", true) then
            found = current
        end
        current = current.Parent
    end
    return found
end

local function IsMyVehicle(model)
    local _, humanoid = GetMyCharacter()
    local seat = humanoid and humanoid.SeatPart
    if seat and seat:IsDescendantOf(model) then
        return true
    end
    local lowerName = string.lower(model.Name)
    return string.find(lowerName, string.lower(Player.Name), 1, true) ~= nil
end

local MutedSounds = {}
local function ShouldMuteSound(sound)
    if IsMine(sound) then
        return false
    end
    if IsOtherPlayersCharacter(sound) then
        return true
    end
    local vehicle = GetVehicleModel(sound)
    if vehicle and not IsMyVehicle(vehicle) then
        return true
    end
    return false
end
local function ApplyMuteOthers(enabled)
    if enabled then
        for _, sound in ipairs(Workspace:GetDescendants()) do
            if sound:IsA("Sound") and MutedSounds[sound] == nil and ShouldMuteSound(sound) then
                MutedSounds[sound] = sound.Volume
                sound.Volume = 0
            end
        end
        for sound in pairs(MutedSounds) do
            if sound.Parent and sound.Volume ~= 0 then
                sound.Volume = 0
            end
        end
    else
        for sound, volume in pairs(MutedSounds) do
            if sound and sound.Parent then
                pcall(function()
                    sound.Volume = volume
                end)
            end
        end
        table.clear(MutedSounds)
    end
end

local RevealedParts = {}
local function ApplyRevealInvisible(enabled)
    if enabled then
        for _, other in ipairs(Players:GetPlayers()) do
            if other ~= Player and other.Character then
                for _, part in ipairs(other.Character:GetDescendants()) do
                    if (part:IsA("BasePart") or part:IsA("Decal"))
                    and part.Name ~= "HumanoidRootPart"
                    and part.Transparency >= 0.95
                    and RevealedParts[part] == nil then
                        local accessory = part:FindFirstAncestorWhichIsA("Accessory")
                        if part:IsA("Decal") or accessory == nil then
                            RevealedParts[part] = part.Transparency
                            part.Transparency = 0.5
                        end
                    end
                end
            end
        end
    else
        for part, value in pairs(RevealedParts) do
            if part and part.Parent then
                pcall(function()
                    part.Transparency = value
                end)
            end
        end
        table.clear(RevealedParts)
    end
end

local HiddenVehicleParts = {}
local function ApplyHideVehicles(enabled)
    if enabled then
        for _, seat in ipairs(Workspace:GetDescendants()) do
            if seat:IsA("VehicleSeat") then
                local model = GetVehicleModel(seat)
                if model and not IsMyVehicle(model) then
                    for _, part in ipairs(model:GetDescendants()) do
                        if part:IsA("BasePart") and HiddenVehicleParts[part] == nil then
                            HiddenVehicleParts[part] = part.LocalTransparencyModifier
                            part.LocalTransparencyModifier = 1
                        end
                    end
                end
            end
        end
    else
        for part, value in pairs(HiddenVehicleParts) do
            if part and part.Parent then
                pcall(function()
                    part.LocalTransparencyModifier = value
                end)
            end
        end
        table.clear(HiddenVehicleParts)
    end
end

local TimeByMode = { Day = 14, Sunset = 18, Night = 0 }
local LockTimeConnection = nil
local function ApplyLockTime(enabled)
    if LockTimeConnection then
        LockTimeConnection:Disconnect()
        LockTimeConnection = nil
    end
    if not enabled then
        return
    end
    local function apply()
        local target = TimeByMode[Settings.BHLockTimeMode] or 14
        if math.abs(Lighting.ClockTime - target) > 0.01 then
            Lighting.ClockTime = target
        end
    end
    apply()
    LockTimeConnection = TrackConnection(Lighting:GetPropertyChangedSignal("ClockTime"):Connect(apply))
end

local function CollectMapPlaces()
    local places = {}
    local seen = {}
    local characters = {}
    for _, other in ipairs(Players:GetPlayers()) do
        if other.Character then
            characters[other.Character] = true
        end
    end
    local function add(name, cframe)
        name = tostring(name)
        if name == "" or seen[name] then
            return
        end
        seen[name] = true
        table.insert(places, { Name = name, CFrame = cframe })
    end
    for _, spawn in ipairs(Workspace:GetDescendants()) do
        if spawn:IsA("SpawnLocation") then
            add("Spawn: " .. spawn.Name, spawn.CFrame + Vector3.new(0, 4, 0))
        end
    end
    for _, child in ipairs(Workspace:GetChildren()) do
        if (child:IsA("Model") or child:IsA("Folder"))
        and not characters[child]
        and not child:FindFirstChildOfClass("Humanoid")
        and not string.find(child.Name, "^Tox") then
            local ok, cf, size = pcall(function()
                if child:IsA("Model") then
                    local c, s = child:GetBoundingBox()
                    return c, s
                end
                local sum, count = Vector3.zero, 0
                local minY = math.huge
                for _, d in ipairs(child:GetDescendants()) do
                    if d:IsA("BasePart") then
                        sum += d.Position
                        count += 1
                        minY = math.min(minY, d.Position.Y)
                        if count >= 400 then break end
                    end
                end
                if count == 0 then return nil end
                local center = sum / count
                return CFrame.new(center.X, minY, center.Z), Vector3.new(40, 0, 40)
            end)
            if ok and cf and size and size.Magnitude > 8 then
                local top = cf.Position + Vector3.new(0, (child:IsA("Model") and size.Y / 2 or 0) + 4, 0)
                add(child.Name, CFrame.new(top))
            end
        end
    end
    table.sort(places, function(a, b)
        return a.Name < b.Name
    end)
    return places
end

local function BuildScanReport()
    local lines = {}
    local function push(text)
        table.insert(lines, text)
    end
    push("== ToxHub Brookhaven scan | PlaceId " .. tostring(game.PlaceId) .. " ==")
    push("-- Remotes (ReplicatedStorage)")
    local count = 0
    for _, d in ipairs(ReplicatedStorage:GetDescendants()) do
        if d:IsA("RemoteEvent") or d:IsA("RemoteFunction") or d:IsA("UnreliableRemoteEvent") then
            count += 1
            if count <= 300 then
                push(d.ClassName .. "  " .. d:GetFullName())
            end
        end
    end
    push("total remotes: " .. count)
    push("-- Workspace children")
    for _, child in ipairs(Workspace:GetChildren()) do
        push(child.ClassName .. "  " .. child.Name .. "  (" .. #child:GetChildren() .. " children)")
    end
    push("-- PlayerGui")
    local gui = Player:FindFirstChildOfClass("PlayerGui")
    if gui then
        for _, child in ipairs(gui:GetChildren()) do
            push(child.ClassName .. "  " .. child.Name)
        end
    end
    push("-- Character tools / backpack")
    local backpack = Player:FindFirstChildOfClass("Backpack")
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            push("Backpack  " .. tool.Name)
        end
    end
    return table.concat(lines, "\n")
end

CreateBHSection("PROTECTION")

TrackControl(CreateToggle("Anti Sit (cars can't grab you)", GamePage, Settings.BHAntiSit, function(value)
    Settings.BHAntiSit = value == true
    ApplyAntiSit(Settings.BHAntiSit)
    AutoSaveConfiguration()
end, "BHAntiSit"))

TrackControl(CreateToggle("Anti House Ban", GamePage, Settings.BHAntiHouseBan, function(value)
    Settings.BHAntiHouseBan = value == true
    ApplyAntiHouseBan(Settings.BHAntiHouseBan)
    if Settings.BHAntiHouseBan then
        local n = 0
        for _ in pairs(BanPartDefaults) do n += 1 end
        CustomNotify("Anti House Ban: " .. n .. " barrier(s) disabled", Color3.fromRGB(120, 200, 255), 4)
    end
    AutoSaveConfiguration()
end, "BHAntiHouseBan"))

CreateBHSection("AUDIO & VISUAL")

TrackControl(CreateToggle("Mute Other Players' Music", GamePage, Settings.BHMuteOthers, function(value)
    Settings.BHMuteOthers = value == true
    ApplyMuteOthers(Settings.BHMuteOthers)
    AutoSaveConfiguration()
end, "BHMuteOthers"))

TrackControl(CreateToggle("Reveal Invisible Players", GamePage, Settings.BHRevealInvisible, function(value)
    Settings.BHRevealInvisible = value == true
    ApplyRevealInvisible(Settings.BHRevealInvisible)
    AutoSaveConfiguration()
end, "BHRevealInvisible"))

TrackControl(CreateToggle("Hide Other Vehicles (less lag)", GamePage, Settings.BHHideVehicles, function(value)
    Settings.BHHideVehicles = value == true
    ApplyHideVehicles(Settings.BHHideVehicles)
    AutoSaveConfiguration()
end, "BHHideVehicles"))

if type(CreateToggleWithChoice) == "function" then
    TrackControl(CreateToggleWithChoice("Lock Time", GamePage, { "Day", "Sunset", "Night" }, Settings.BHLockTime, Settings.BHLockTimeMode, function(value)
        Settings.BHLockTime = value == true
        ApplyLockTime(Settings.BHLockTime)
        AutoSaveConfiguration()
    end, function(choice)
        Settings.BHLockTimeMode = tostring(choice)
        if Settings.BHLockTime then
            ApplyLockTime(true)
        end
        AutoSaveConfiguration()
    end, "BHLockTime"))
else
    TrackControl(CreateToggle("Lock Time (Day)", GamePage, Settings.BHLockTime, function(value)
        Settings.BHLockTime = value == true
        ApplyLockTime(Settings.BHLockTime)
        AutoSaveConfiguration()
    end, "BHLockTime"))
end

CreateBHSection("TELEPORTS")

local MapPlaces = {}
local SelectedPlace = "(press Refresh)"
local PlaceOptions = { "(press Refresh)" }
local PlaceDropdown = TrackControl(CreateDropdown("Map Place", PlaceOptions, GamePage, SelectedPlace, function(choice)
    SelectedPlace = tostring(choice)
end))

local function RebuildPlaceDropdown()
    MapPlaces = CollectMapPlaces()
    table.clear(PlaceOptions)
    for _, place in ipairs(MapPlaces) do
        table.insert(PlaceOptions, place.Name)
    end
    if #PlaceOptions == 0 then
        table.insert(PlaceOptions, "(none found)")
    end
    SelectedPlace = PlaceOptions[1]
    if typeof(PlaceDropdown) == "Instance" then
        for _, d in ipairs(PlaceDropdown:GetDescendants()) do
            if d:IsA("TextButton") then
                d.Text = tostring(SelectedPlace) .. "  v"
            end
        end
    end
end

TrackControl(CreateButton("Go To Selected Place", GamePage, function()
    for _, place in ipairs(MapPlaces) do
        if place.Name == SelectedPlace then
            TeleportTo(place.CFrame, place.Name)
            return
        end
    end
    CustomNotify("Pick a place first", Color3.fromRGB(255, 180, 70), 3)
end))

TrackControl(CreateButton("Refresh Places", GamePage, function()
    RebuildPlaceDropdown()
    CustomNotify(#MapPlaces .. " place(s) found", Color3.fromRGB(120, 200, 255), 3)
end))

TrackControl(CreateButton("Teleport To Spawn", GamePage, function()
    for _, spawn in ipairs(Workspace:GetDescendants()) do
        if spawn:IsA("SpawnLocation") then
            TeleportTo(spawn.CFrame + Vector3.new(0, 4, 0), "Spawn")
            return
        end
    end
    CustomNotify("No spawn found", Color3.fromRGB(255, 180, 70), 3)
end))

CreateBHSection("TOOLS")

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

task.defer(RebuildPlaceDropdown)

local lastTick = 0
TrackConnection(RunService.Heartbeat:Connect(function()
    if getgenv().Destroyed then
        return
    end
    local now = os.clock()
    if now - lastTick < 0.5 then
        return
    end
    lastTick = now
    if Settings.BHAntiSit then
        ApplyAntiSit(true)
    end
    if Settings.BHAntiHouseBan then
        ApplyAntiHouseBan(true)
    end
    if Settings.BHMuteOthers then
        ApplyMuteOthers(true)
    end
    if Settings.BHRevealInvisible then
        ApplyRevealInvisible(true)
    end
    if Settings.BHHideVehicles then
        ApplyHideVehicles(true)
    end
end))

TrackConnection(Player.CharacterAdded:Connect(function()
    SeatedWasEnabled = nil
    task.wait(0.5)
    if Settings.BHAntiSit then
        ApplyAntiSit(true)
    end
end))

if Settings.BHLockTime then
    ApplyLockTime(true)
end

getgenv().ToxBHCleanup = function()
    ApplyAntiSit(false)
    ApplyAntiHouseBan(false)
    ApplyMuteOthers(false)
    ApplyRevealInvisible(false)
    ApplyHideVehicles(false)
    ApplyLockTime(false)
    for _, connection in ipairs(BHConnections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    table.clear(BHConnections)
end

getgenv().ToxBHModuleLoadedJobId = game.JobId
getgenv().ToxBHModuleVersion = BHModuleVersion
getgenv().ToxBHModulePage = GamePage
