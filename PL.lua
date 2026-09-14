local PLPlaceId = 155615604

if game.PlaceId ~= PLPlaceId then
    return
end

local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local Settings = getgenv().Settings
local GamePage = getgenv().GamePage
local CreateToggle = getgenv().CreateToggle
local CreateToggleWithValue = getgenv().CreateToggleWithValue
local CreateButton = getgenv().CreateButton
local CreateDropdown = getgenv().CreateDropdown
local CreateInputWithButton = getgenv().CreateInputWithButton
local CustomNotify = getgenv().CustomNotify or function() end
local AutoSaveConfiguration = getgenv().AutoSaveConfiguration or function() end
local AddConnection = getgenv().AddConnection or function(connection)
    return connection
end

if not Settings
or not GamePage
or not CreateToggle
or not CreateToggleWithValue
or not CreateButton
or not CreateDropdown
or not CreateInputWithButton then
    return
end

local PLModuleVersion = "2026-09-14-pl-initial-1"

if getgenv().ToxPLModuleLoadedJobId == game.JobId
and getgenv().ToxPLModuleVersion == PLModuleVersion
and getgenv().ToxPLModulePage == GamePage
and not getgenv().Destroyed then
    return
end

if getgenv().ToxPLCleanup then
    pcall(getgenv().ToxPLCleanup)
end

for _, child in ipairs(GamePage:GetChildren()) do
    if child:IsA("GuiObject") then
        child:Destroy()
    end
end

Settings.PLArrestMethod = tostring(Settings.PLArrestMethod or "REMOTE")
if Settings.PLArrestMethod ~= "REMOTE" and Settings.PLArrestMethod ~= "CLOSE" then
    Settings.PLArrestMethod = "REMOTE"
end

Settings.PLCollapsedSections = typeof(Settings.PLCollapsedSections) == "table"
    and Settings.PLCollapsedSections
    or {}

local PLConnections = {}
local PLCurrentSection = nil
local PLSections = {}

local function TrackConnection(connection)
    if connection then
        table.insert(PLConnections, connection)
        AddConnection(connection)
    end
    return connection
end

local function SetShared(key, value)
    if getgenv().ToxSetSharedOption then
        getgenv().ToxSetSharedOption(key, value)
    else
        Settings[key] = value
    end
end

local function ApplySectionState(section)
    if typeof(section) ~= "table" then
        return
    end

    local collapsed = Settings.PLCollapsedSections[section.Key] == true

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
    if PLCurrentSection and object and object:IsA("GuiObject") then
        table.insert(PLCurrentSection.Controls, object)
        ApplySectionState(PLCurrentSection)
    end
    return object
end

local function PLCreateToggle(...)
    return TrackControl(CreateToggle(...))
end

local function PLCreateToggleWithValue(...)
    return TrackControl(CreateToggleWithValue(...))
end

local function PLCreateButton(...)
    return TrackControl(CreateButton(...))
end

local function PLCreateDropdown(...)
    return TrackControl(CreateDropdown(...))
end

local function PLCreateInputWithButton(...)
    return TrackControl(CreateInputWithButton(...))
end

local function CreatePLSection(text)
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

    table.insert(PLSections, section)
    PLCurrentSection = section

    TrackConnection(button.MouseButton1Click:Connect(function()
        Settings.PLCollapsedSections[key] = not Settings.PLCollapsedSections[key]
        ApplySectionState(section)
        AutoSaveConfiguration()
    end))

    ApplySectionState(section)
    return button
end

local function GetCharacterRoot(player)
    player = player or Player
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if not humanoid or humanoid.Health <= 0 or not root then
        return nil
    end

    return root
end

local function TeleportTo(cframe, label)
    local root = GetCharacterRoot(Player)

    if not root then
        CustomNotify("Character unavailable", Color3.fromRGB(255, 180, 70), 3)
        return false
    end

    if getgenv().ToxSafeTeleportToCFrame then
        return getgenv().ToxSafeTeleportToCFrame(
            cframe,
            false,
            "PL " .. tostring(label)
        )
    end

    if getgenv().RecordToxTeleportReturn then
        getgenv().RecordToxTeleportReturn()
    end

    if getgenv().AllowToxTeleport then
        getgenv().AllowToxTeleport(1.5, "PL " .. tostring(label))
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

local function FindPlayer(text)
    local query = string.lower(tostring(text or ""))
    query = string.gsub(query, "^%s+", "")
    query = string.gsub(query, "%s+$", "")

    if query == "" then
        return nil
    end

    local exact = nil
    local partial = nil

    for _, target in ipairs(Players:GetPlayers()) do
        if target ~= Player then
            local name = string.lower(target.Name)
            local displayName = string.lower(target.DisplayName)

            if name == query or displayName == query then
                exact = target
                break
            end

            if not partial
            and (
                string.sub(name, 1, #query) == query
                or string.sub(displayName, 1, #query) == query
            ) then
                partial = target
            end
        end
    end

    return exact or partial
end

local function GetArrestRemote()
    local remoteFolder = workspace:FindFirstChild("Remote")
    local remote = remoteFolder and remoteFolder:FindFirstChild("arrest")

    if remote and remote:IsA("RemoteFunction") then
        return remote
    end

    return nil
end

local function GetArrestPart(target)
    local character = target and target.Character
    if not character then
        return nil
    end

    return character:FindFirstChild("Head")
        or character:FindFirstChild("Torso")
        or character:FindFirstChild("HumanoidRootPart")
        or character:FindFirstChild("Left Leg")
        or character:FindFirstChildWhichIsA("BasePart")
end

local function ArrestTarget(target)
    if not target or target == Player then
        CustomNotify("Player not found", Color3.fromRGB(255, 100, 100), 3)
        return false
    end

    local remote = GetArrestRemote()
    local part = GetArrestPart(target)

    if not remote or not part then
        CustomNotify("Arrest remote unavailable", Color3.fromRGB(255, 100, 100), 3)
        return false
    end

    if Settings.PLArrestMethod == "CLOSE" then
        local myRoot = GetCharacterRoot(Player)
        local targetRoot = GetCharacterRoot(target)

        if not myRoot or not targetRoot then
            return false
        end

        if (myRoot.Position - targetRoot.Position).Magnitude > 16 then
            CustomNotify("Target is too far", Color3.fromRGB(255, 180, 70), 3)
            return false
        end
    end

    local ok = pcall(function()
        remote:InvokeServer(part)
    end)

    if ok then
        CustomNotify(
            "Arrest request: " .. target.Name,
            Color3.fromRGB(100, 255, 100),
            3
        )
    else
        CustomNotify("Arrest failed", Color3.fromRGB(255, 100, 100), 3)
    end

    return ok
end

CreatePLSection("PLAYER")

PLCreateToggleWithValue(
    "Speed",
    GamePage,
    Settings.Speed == true,
    tonumber(Settings.SpeedValue) or 16,
    function(value)
        SetShared("Speed", value == true)
    end,
    function(value)
        local newValue = math.clamp(tonumber(value) or 16, 1, 250)
        Settings.SpeedValue = newValue
        if getgenv().ToxSetSharedValue then
            getgenv().ToxSetSharedValue("Speed", newValue)
        end
    end,
    "Speed"
)

PLCreateToggleWithValue(
    "Jump",
    GamePage,
    Settings.Jump == true,
    tonumber(Settings.JumpValue) or 50,
    function(value)
        SetShared("Jump", value == true)
    end,
    function(value)
        local newValue = math.clamp(tonumber(value) or 50, 1, 300)
        Settings.JumpValue = newValue
        if getgenv().ToxSetSharedValue then
            getgenv().ToxSetSharedValue("Jump", newValue)
        end
    end,
    "Jump"
)

PLCreateToggle(
    "Noclip",
    GamePage,
    Settings.Noclip == true,
    function(value)
        SetShared("Noclip", value == true)
    end,
    "Noclip"
)

CreatePLSection("ARREST")

PLCreateDropdown(
    "Arrest Method",
    {"REMOTE", "CLOSE"},
    GamePage,
    Settings.PLArrestMethod,
    function(value)
        Settings.PLArrestMethod = tostring(value)
        AutoSaveConfiguration()
    end
)

PLCreateInputWithButton(
    "Arrest Player",
    GamePage,
    "",
    "ARREST",
    function(text)
        ArrestTarget(FindPlayer(text))
    end
)

CreatePLSection("TELEPORTS")

PLCreateButton("CRIM BASE", GamePage, function()
    TeleportTo(CFrame.new(-942, 94, 2055), "CRIM BASE")
end)

PLCreateButton("TOWER", GamePage, function()
    TeleportTo(CFrame.new(822, 131, 2588), "TOWER")
end)

PLCreateButton("ARMORY", GamePage, function()
    TeleportTo(CFrame.new(789, 100, 2260), "ARMORY")
end)

getgenv().ToxPLCleanup = function()
    for _, connection in ipairs(PLConnections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    table.clear(PLConnections)
end

getgenv().ToxPLModuleLoadedJobId = game.JobId
getgenv().ToxPLModuleVersion = PLModuleVersion
getgenv().ToxPLModulePage = GamePage
