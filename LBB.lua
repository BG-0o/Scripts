local LBBPlaceId = 662417684

if game.PlaceId ~= LBBPlaceId then
    return
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local Settings = getgenv().Settings
local GamePage = getgenv().GamePage
local CreateToggle = getgenv().CreateToggle
local CreateToggleWithValue = getgenv().CreateToggleWithValue
local CreateButton = getgenv().CreateButton
local CustomNotify = getgenv().CustomNotify or function() end
local AutoSaveConfiguration = getgenv().AutoSaveConfiguration or function() end
local SyncValueVisuals = getgenv().SyncValueVisuals

if not Settings
or not GamePage
or not CreateToggle
or not CreateToggleWithValue
or not CreateButton then
    return
end

local LBBModuleVersion = "2026-09-14-lbb-initial-1"

if getgenv().ToxLBBModuleLoadedJobId == game.JobId
and getgenv().ToxLBBModuleVersion == LBBModuleVersion
and getgenv().ToxLBBModulePage == GamePage
and not getgenv().Destroyed then
    return
end

if getgenv().ToxLBBCleanup then
    pcall(getgenv().ToxLBBCleanup)
end

for _, child in ipairs(GamePage:GetChildren()) do
    if child:IsA("GuiObject") then
        child:Destroy()
    end
end

Settings.LBBBaseESP = Settings.LBBBaseESP == true
Settings.LBBCollapsedSections =
    typeof(Settings.LBBCollapsedSections) == "table"
    and Settings.LBBCollapsedSections
    or {}

local LBBCurrentSection = nil
local LBBSections = {}
local LBBESPObjects = {}
local LBBESPGeneration = 0

local function SetShared(key, value)
    if getgenv().ToxSetSharedOption then
        getgenv().ToxSetSharedOption(key, value)
    else
        if key == "NormalFly" then
            Settings.NormalFly = value == true
            if value then
                Settings.SmoothFly = false
            end
        else
            Settings[key] = value == true
        end
    end
end

local function ApplyLBBSectionState(section)
    if typeof(section) ~= "table" then
        return
    end

    local collapsed = Settings.LBBCollapsedSections[section.Key] == true

    if section.Header and section.Header.Parent then
        section.Header.Text = collapsed
            and "  > " .. section.Name
            or "  v " .. section.Name
    end

    for _, object in ipairs(section.Controls) do
        if object
        and object.Parent
        and object:IsA("GuiObject") then
            object.Visible = not collapsed
        end
    end
end

local function TrackLBBControl(object)
    if LBBCurrentSection
    and object
    and object:IsA("GuiObject") then
        table.insert(LBBCurrentSection.Controls, object)
        ApplyLBBSectionState(LBBCurrentSection)
    end

    return object
end

local function LBBCreateToggle(...)
    return TrackLBBControl(CreateToggle(...))
end

local function LBBCreateToggleWithValue(...)
    return TrackLBBControl(CreateToggleWithValue(...))
end

local function LBBCreateButton(...)
    return TrackLBBControl(CreateButton(...))
end

local function CreateLBBSection(text)
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

    table.insert(LBBSections, section)
    LBBCurrentSection = section

    button.MouseButton1Click:Connect(function()
        Settings.LBBCollapsedSections[key] =
            not Settings.LBBCollapsedSections[key]

        ApplyLBBSectionState(section)
        AutoSaveConfiguration()
    end)

    ApplyLBBSectionState(section)
    return button
end

local function FindRemote(name)
    local exact = ReplicatedStorage:FindFirstChild(name, true)

    if exact
    and (
        exact:IsA("RemoteEvent")
        or exact:IsA("RemoteFunction")
    ) then
        return exact
    end

    local lowerName = string.lower(name)

    for _, object in ipairs(ReplicatedStorage:GetDescendants()) do
        if (
            object:IsA("RemoteEvent")
            or object:IsA("RemoteFunction")
        )
        and string.lower(object.Name) == lowerName then
            return object
        end
    end

    return nil
end

local function FireBlockRemote(remoteName, label)
    local remote = FindRemote(remoteName)

    if not remote then
        CustomNotify(
            tostring(label) .. " unavailable",
            Color3.fromRGB(255, 180, 70),
            4
        )
        return false
    end

    local ok = pcall(function()
        if remote:IsA("RemoteEvent") then
            remote:FireServer()
        else
            remote:InvokeServer()
        end
    end)

    if not ok then
        CustomNotify(
            tostring(label) .. " failed",
            Color3.fromRGB(255, 100, 100),
            4
        )
    end

    return ok
end

local function OpenLimitedBlock()
    local priority = {
        "SpawnHackerBlock",
        "SpawnLimitedBlock",
        "SpawnGlitchBlock",
        "SpawnLavaBlock"
    }

    for _, remoteName in ipairs(priority) do
        local remote = FindRemote(remoteName)

        if remote then
            local ok = pcall(function()
                if remote:IsA("RemoteEvent") then
                    remote:FireServer()
                else
                    remote:InvokeServer()
                end
            end)

            if ok then
                return true
            end
        end
    end

    local standard = {
        spawnluckyblock = true,
        spawnsuperblock = true,
        spawndiamondblock = true,
        spawnrainbowblock = true,
        spawngalaxyblock = true,
        spawnvoidblock = true
    }

    for _, object in ipairs(ReplicatedStorage:GetDescendants()) do
        if object:IsA("RemoteEvent")
        or object:IsA("RemoteFunction") then
            local lower = string.lower(object.Name)

            if string.find(lower, "spawn", 1, true)
            and string.find(lower, "block", 1, true)
            and not standard[lower] then
                local ok = pcall(function()
                    if object:IsA("RemoteEvent") then
                        object:FireServer()
                    else
                        object:InvokeServer()
                    end
                end)

                if ok then
                    return true
                end
            end
        end
    end

    CustomNotify(
        "Limited Block unavailable",
        Color3.fromRGB(255, 180, 70),
        4
    )

    return false
end

local function GetCharacterRoot()
    local character = Player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if not humanoid
    or humanoid.Health <= 0
    or not root then
        return nil
    end

    return root
end

local function TeleportTo(cframe, label)
    if typeof(cframe) ~= "CFrame" then
        CustomNotify(
            tostring(label) .. " location unavailable",
            Color3.fromRGB(255, 180, 70),
            4
        )
        return false
    end

    local root = GetCharacterRoot()

    if not root then
        return false
    end

    if getgenv().ToxSafeTeleportToCFrame then
        return getgenv().ToxSafeTeleportToCFrame(
            cframe,
            false,
            "LBB " .. tostring(label)
        )
    end

    if getgenv().RecordToxTeleportReturn then
        getgenv().RecordToxTeleportReturn()
    end

    if getgenv().AllowToxTeleport then
        getgenv().AllowToxTeleport(
            1.5,
            "LBB " .. tostring(label)
        )
    end

    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero

    if Player.Character then
        Player.Character:PivotTo(cframe)
    else
        root.CFrame = cframe
    end

    return true
end

local function GetSpawnLocations()
    local spawns = {}

    for _, object in ipairs(workspace:GetDescendants()) do
        if object:IsA("SpawnLocation") then
            table.insert(spawns, object)
        end
    end

    return spawns
end

local function GetSpawnCFrame(spawn)
    if not spawn
    or not spawn:IsA("BasePart") then
        return nil
    end

    return CFrame.new(
        spawn.Position
        + Vector3.new(
            0,
            math.max(3, spawn.Size.Y * 0.5 + 3),
            0
        )
    )
end

local function NormalizeBaseColorName(spawn)
    local raw = ""

    pcall(function()
        raw = tostring(spawn.TeamColor.Name or "")
    end)

    if raw == "" then
        raw = tostring(spawn.BrickColor.Name or "")
    end

    local lower = string.lower(raw)

    if string.find(lower, "yellow", 1, true)
    or string.find(lower, "yeller", 1, true) then
        return "YELLOW"
    elseif string.find(lower, "green", 1, true)
    or string.find(lower, "lime", 1, true) then
        return "GREEN"
    elseif string.find(lower, "cyan", 1, true)
    or string.find(lower, "toothpaste", 1, true)
    or string.find(lower, "aqua", 1, true) then
        return "CYAN"
    elseif string.find(lower, "blue", 1, true) then
        return "BLUE"
    elseif string.find(lower, "red", 1, true) then
        return "RED"
    elseif string.find(lower, "orange", 1, true) then
        return "ORANGE"
    elseif string.find(lower, "pink", 1, true)
    or string.find(lower, "magenta", 1, true) then
        return "PINK"
    elseif string.find(lower, "purple", 1, true)
    or string.find(lower, "violet", 1, true) then
        return "PURPLE"
    elseif string.find(lower, "white", 1, true) then
        return "WHITE"
    elseif string.find(lower, "black", 1, true) then
        return "BLACK"
    end

    if raw ~= "" then
        return string.upper(raw)
    end

    return "BASE"
end

local function GetPlayerBaseCFrame()
    local respawn = Player.RespawnLocation

    if respawn
    and respawn:IsA("SpawnLocation") then
        return GetSpawnCFrame(respawn)
    end

    local spawns = GetSpawnLocations()

    for _, spawn in ipairs(spawns) do
        local matches = false

        pcall(function()
            matches = spawn.TeamColor == Player.TeamColor
        end)

        if matches then
            return GetSpawnCFrame(spawn)
        end
    end

    return nil
end

local function GetCenterCFrame()
    local spawns = GetSpawnLocations()

    if #spawns >= 2 then
        local sum = Vector3.zero
        local highestY = -math.huge

        for _, spawn in ipairs(spawns) do
            sum += spawn.Position
            highestY = math.max(highestY, spawn.Position.Y)
        end

        local average = sum / #spawns
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = Player.Character and {Player.Character} or {}
        params.IgnoreWater = false

        local origin = Vector3.new(
            average.X,
            highestY + 300,
            average.Z
        )

        local result = workspace:Raycast(
            origin,
            Vector3.new(0, -700, 0),
            params
        )

        if result then
            return CFrame.new(
                result.Position
                + Vector3.new(0, 4, 0)
            )
        end
    end

    local centerBlocks = workspace:FindFirstChild("CenterBlocks")

    if centerBlocks then
        local bestPart = nil
        local bestArea = -1

        for _, object in ipairs(centerBlocks:GetDescendants()) do
            if object:IsA("BasePart")
            and object.CanCollide then
                local area = object.Size.X * object.Size.Z

                if area > bestArea then
                    bestArea = area
                    bestPart = object
                end
            end
        end

        if bestPart then
            return CFrame.new(
                bestPart.Position
                + Vector3.new(
                    0,
                    bestPart.Size.Y * 0.5 + 4,
                    0
                )
            )
        end
    end

    return nil
end

local function GetPlayerBaseColor(player)
    if not player then
        return Color3.fromRGB(255, 255, 255)
    end

    if player.Team then
        local ok, color = pcall(function()
            return player.Team.TeamColor.Color
        end)

        if ok and typeof(color) == "Color3" then
            return color
        end
    end

    if player.RespawnLocation then
        local ok, color = pcall(function()
            return player.RespawnLocation.TeamColor.Color
        end)

        if ok and typeof(color) == "Color3" then
            return color
        end
    end

    local ok, color = pcall(function()
        return player.TeamColor.Color
    end)

    if ok and typeof(color) == "Color3" then
        return color
    end

    return Color3.fromRGB(255, 255, 255)
end

local function ClearLBBESPPlayer(player)
    local data = LBBESPObjects[player]

    if not data then
        return
    end

    if data.Highlight
    and data.Highlight.Parent then
        pcall(function()
            data.Highlight:Destroy()
        end)
    end

    if data.Billboard
    and data.Billboard.Parent then
        pcall(function()
            data.Billboard:Destroy()
        end)
    end

    LBBESPObjects[player] = nil
end

local function ClearLBBESP()
    for player in pairs(LBBESPObjects) do
        ClearLBBESPPlayer(player)
    end
end

local function UpdateLBBESPPlayer(player)
    if player == Player then
        ClearLBBESPPlayer(player)
        return
    end

    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local head = character and character:FindFirstChild("Head")
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if not character
    or not humanoid
    or humanoid.Health <= 0
    or not root then
        ClearLBBESPPlayer(player)
        return
    end

    local color = GetPlayerBaseColor(player)
    local data = LBBESPObjects[player]

    if not data
    or data.Character ~= character then
        ClearLBBESPPlayer(player)

        local highlight = Instance.new("Highlight")
        highlight.Name = "ToxLBBESP"
        highlight.Adornee = character
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.FillTransparency = 0.72
        highlight.OutlineTransparency = 0
        highlight.Parent = character

        local billboard = Instance.new("BillboardGui")
        billboard.Name = "ToxLBBESPName"
        billboard.Size = UDim2.new(0, 180, 0, 28)
        billboard.StudsOffset = Vector3.new(0, 2.8, 0)
        billboard.AlwaysOnTop = true
        billboard.MaxDistance = 5000
        billboard.Adornee = head or root
        billboard.Parent = character

        local label = Instance.new("TextLabel")
        label.Name = "Label"
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = player.DisplayName
        label.TextSize = 13
        label.Font = Enum.Font.GothamBold
        label.TextStrokeTransparency = 0
        label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        label.Parent = billboard

        data = {
            Character = character,
            Highlight = highlight,
            Billboard = billboard,
            Label = label
        }

        LBBESPObjects[player] = data
    end

    if data.Highlight and data.Highlight.Parent then
        data.Highlight.FillColor = color
        data.Highlight.OutlineColor = color
    end

    if data.Label and data.Label.Parent then
        data.Label.Text = player.DisplayName
        data.Label.TextColor3 = color
    end
end

local function StartLBBESP()
    LBBESPGeneration += 1
    local generation = LBBESPGeneration

    task.spawn(function()
        while generation == LBBESPGeneration
        and Settings.LBBBaseESP
        and not getgenv().Destroyed do
            for _, player in ipairs(Players:GetPlayers()) do
                UpdateLBBESPPlayer(player)
            end

            for tracked in pairs(LBBESPObjects) do
                if not tracked.Parent then
                    ClearLBBESPPlayer(tracked)
                end
            end

            task.wait(0.2)
        end

        if generation == LBBESPGeneration then
            ClearLBBESP()
        end
    end)
end

local function SetLBBESP(enabled)
    Settings.LBBBaseESP = enabled == true
    LBBESPGeneration += 1

    if Settings.LBBBaseESP then
        StartLBBESP()
    else
        ClearLBBESP()
    end
end

CreateLBBSection("PLAYER")

LBBCreateToggleWithValue(
    "Speed",
    GamePage,
    Settings.Speed,
    Settings.SpeedValue,
    function(value)
        SetShared("Speed", value)
    end,
    function(value)
        Settings.SpeedValue = math.clamp(
            tonumber(value) or 16,
            1,
            250
        )

        if SyncValueVisuals then
            SyncValueVisuals("Speed", Settings.SpeedValue)
        end
    end,
    "Speed"
)

LBBCreateToggleWithValue(
    "Jump",
    GamePage,
    Settings.Jump,
    Settings.JumpValue,
    function(value)
        Settings.Jump = value == true
    end,
    function(value)
        Settings.JumpValue = math.clamp(
            tonumber(value) or 50,
            1,
            500
        )
    end,
    "Jump"
)

LBBCreateToggleWithValue(
    "Fly",
    GamePage,
    Settings.NormalFly,
    Settings.FlySpeed,
    function(value)
        SetShared("NormalFly", value)
    end,
    function(value)
        Settings.FlySpeed = math.clamp(
            tonumber(value) or 10,
            1,
            300
        )

        if SyncValueVisuals then
            SyncValueVisuals("NormalFly", Settings.FlySpeed)
        end
    end,
    "NormalFly"
)

LBBCreateToggle(
    "ESP Base Colors",
    GamePage,
    Settings.LBBBaseESP,
    function(value)
        SetLBBESP(value)
    end,
    "LBBBaseESP"
)

CreateLBBSection("LUCKY BLOCKS")

LBBCreateButton("Lucky Blocks (Open)", GamePage, function()
    FireBlockRemote("SpawnLuckyBlock", "Lucky Block")
end)

LBBCreateButton("Super Blocks (Open)", GamePage, function()
    FireBlockRemote("SpawnSuperBlock", "Super Block")
end)

LBBCreateButton("Diamond Blocks (Open)", GamePage, function()
    FireBlockRemote("SpawnDiamondBlock", "Diamond Block")
end)

LBBCreateButton("Rainbow Blocks (Open)", GamePage, function()
    FireBlockRemote("SpawnRainbowBlock", "Rainbow Block")
end)

LBBCreateButton("Galaxy Blocks (Open)", GamePage, function()
    FireBlockRemote("SpawnGalaxyBlock", "Galaxy Block")
end)

LBBCreateButton("Void Blocks (Open)", GamePage, function()
    FireBlockRemote("SpawnVoidBlock", "Void Block")
end)

LBBCreateButton("Limited Block (Open)", GamePage, function()
    OpenLimitedBlock()
end)

CreateLBBSection("TELEPORTS")

LBBCreateButton("CENTER", GamePage, function()
    TeleportTo(GetCenterCFrame(), "CENTER")
end)

LBBCreateButton("BASE", GamePage, function()
    TeleportTo(GetPlayerBaseCFrame(), "BASE")
end)

local baseButtons = {}

for _, spawn in ipairs(GetSpawnLocations()) do
    local name = NormalizeBaseColorName(spawn)

    if not baseButtons[name] then
        baseButtons[name] = spawn
    end
end

local orderedBaseNames = {
    "YELLOW",
    "GREEN",
    "CYAN",
    "BLUE",
    "RED",
    "ORANGE",
    "PURPLE",
    "PINK",
    "WHITE",
    "BLACK"
}

local createdBaseNames = {}

for _, name in ipairs(orderedBaseNames) do
    local spawn = baseButtons[name]

    if spawn then
        createdBaseNames[name] = true

        LBBCreateButton(name, GamePage, function()
            TeleportTo(GetSpawnCFrame(spawn), name)
        end)
    end
end

local extraNames = {}

for name in pairs(baseButtons) do
    if not createdBaseNames[name] then
        table.insert(extraNames, name)
    end
end

table.sort(extraNames)

for _, name in ipairs(extraNames) do
    local spawn = baseButtons[name]

    LBBCreateButton(name, GamePage, function()
        TeleportTo(GetSpawnCFrame(spawn), name)
    end)
end

getgenv().ToxLBBCleanup = function()
    LBBESPGeneration += 1
    ClearLBBESP()
end

if Settings.LBBBaseESP then
    StartLBBESP()
end

getgenv().ToxLBBModuleLoadedJobId = game.JobId
getgenv().ToxLBBModuleVersion = LBBModuleVersion
getgenv().ToxLBBModulePage = GamePage
