local WIDPlaceId = 109440000000000 + 485612336

if game.PlaceId ~= WIDPlaceId then
    return
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Settings = getgenv().Settings
local GamePage = getgenv().GamePage
local CreateToggle = getgenv().CreateToggle
local CreateToggleWithValue = getgenv().CreateToggleWithValue
local CreateButton = getgenv().CreateButton
local CreateDropdown = getgenv().CreateDropdown
local CreateInputWithButton = getgenv().CreateInputWithButton
local CustomNotify = getgenv().CustomNotify or function() end
local AutoSaveConfiguration = getgenv().AutoSaveConfiguration or function() end
local AddConnection = getgenv().AddConnection or function(c) return c end
local SyncToggleVisuals = getgenv().SyncToggleVisuals

if not Settings
or not GamePage
or not CreateToggle
or not CreateToggleWithValue
or not CreateButton then
    return
end

local WIDModuleVersion = "2026-10-30-wid-v1"

if getgenv().ToxWIDModuleLoadedJobId == game.JobId
and getgenv().ToxWIDModuleVersion == WIDModuleVersion
and getgenv().ToxWIDModulePage == GamePage
and not getgenv().Destroyed then
    return
end

if getgenv().ToxWIDCleanup then
    pcall(getgenv().ToxWIDCleanup)
end

for _, child in ipairs(GamePage:GetChildren()) do
    if child:IsA("GuiObject") then
        child:Destroy()
    end
end

Settings.WIDCollapsedSections = typeof(Settings.WIDCollapsedSections) == "table"
    and Settings.WIDCollapsedSections
    or {}

Settings.WIDAutoWin = Settings.WIDAutoWin == true
Settings.WIDSafePlatform = Settings.WIDSafePlatform == true
Settings.WIDPlatformHeight = tonumber(Settings.WIDPlatformHeight) or 350
Settings.WIDAntiVoid = Settings.WIDAntiVoid == true
Settings.WIDNoFallDamage = Settings.WIDNoFallDamage == true
Settings.WIDAntiFling = Settings.WIDAntiFling == true
Settings.WIDAntiHazards = Settings.WIDAntiHazards == true
Settings.WIDNotifyDisasters = Settings.WIDNotifyDisasters == true
Settings.WIDAntiAFK = Settings.WIDAntiAFK == true
Settings.WIDInfiniteJump = Settings.WIDInfiniteJump == true
Settings.WIDAutoSafeSpot = Settings.WIDAutoSafeSpot == true
Settings.WIDAnchorOnPlatform = Settings.WIDAnchorOnPlatform == true
Settings.WIDAirWalk = Settings.WIDAirWalk == true

local WIDConnections = {}
local WIDCurrentSection = nil
local WIDSections = {}
local SafePlatformModel = nil
local AirWalkPart = nil
local LastAnnouncedDisaster = ""

local function TrackConnection(connection)
    if connection then
        table.insert(WIDConnections, connection)
        AddConnection(connection)
    end
    return connection
end

local function SetShared(key, value)
    if getgenv().ToxSetSharedOption then
        getgenv().ToxSetSharedOption(key, value)
    else
        Settings[key] = value
        if SyncToggleVisuals then
            SyncToggleVisuals(key, value == true)
        end
    end
end

local function ApplySectionState(section)
    if typeof(section) ~= "table" then
        return
    end

    local collapsed = Settings.WIDCollapsedSections[section.Key] == true

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
    if WIDCurrentSection and object and object:IsA("GuiObject") then
        table.insert(WIDCurrentSection.Controls, object)
        ApplySectionState(WIDCurrentSection)
    end
    return object
end

local function WIDCreateToggle(...)
    return TrackControl(CreateToggle(...))
end

local function WIDCreateToggleWithValue(...)
    return TrackControl(CreateToggleWithValue(...))
end

local function WIDCreateButton(...)
    return TrackControl(CreateButton(...))
end

local function WIDCreateDropdown(...)
    return TrackControl(CreateDropdown(...))
end

local function WIDCreateInputWithButton(...)
    return TrackControl(CreateInputWithButton(...))
end

local function CreateWIDSection(text)
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

    table.insert(WIDSections, section)
    WIDCurrentSection = section

    TrackConnection(button.MouseButton1Click:Connect(function()
        Settings.WIDCollapsedSections[key] = not Settings.WIDCollapsedSections[key]
        ApplySectionState(section)
        AutoSaveConfiguration()
    end))

    ApplySectionState(section)
    return button
end

local function GetCharacterState()
    local character = Player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    return character, humanoid, root
end

local function AllowToxTeleport(seconds, reason)
    if getgenv().AllowToxTeleport then
        getgenv().AllowToxTeleport(seconds or 1.5, reason or "WID")
    end
end

local function TeleportTo(cframe, label)
    local character, humanoid, root = GetCharacterState()

    if not humanoid or humanoid.Health <= 0 or not root then
        CustomNotify("Character unavailable", Color3.fromRGB(255, 100, 100), 3)
        return false
    end

    AllowToxTeleport(1.5, "WID " .. tostring(label or "Teleport"))
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

local function EnsureSafePlatform()
    if SafePlatformModel and SafePlatformModel.Parent then
        local floor = SafePlatformModel:FindFirstChild("PlatformFloor")
        if floor then
            return SafePlatformModel, floor
        end
    end

    if SafePlatformModel then
        pcall(function() SafePlatformModel:Destroy() end)
    end

    local model = Instance.new("Model")
    model.Name = "ToxWIDPlatform"
    model.Parent = Workspace

    local height = tonumber(Settings.WIDPlatformHeight) or 350
    local center = Vector3.new(0, height, 0)

    local character, _, root = GetCharacterState()
    if root then
        center = Vector3.new(root.Position.X, height, root.Position.Z)
    end

    local floor = Instance.new("Part")
    floor.Name = "PlatformFloor"
    floor.Size = Vector3.new(65, 4, 65)
    floor.CFrame = CFrame.new(center)
    floor.Anchored = true
    floor.CanCollide = true
    floor.Material = Enum.Material.SmoothPlastic
    floor.Color = Color3.fromRGB(25, 28, 36)
    floor.Parent = model

    local roof = Instance.new("Part")
    roof.Name = "PlatformRoof"
    roof.Size = Vector3.new(65, 3, 65)
    roof.CFrame = CFrame.new(center + Vector3.new(0, 18, 0))
    roof.Anchored = true
    roof.CanCollide = true
    roof.Material = Enum.Material.ForceField
    roof.Color = Color3.fromRGB(80, 150, 255)
    roof.Transparency = 0.5
    roof.Parent = model

    local wallOffsets = {
        {Vector3.new(0, 9, 32.5), Vector3.new(65, 18, 2)},
        {Vector3.new(0, 9, -32.5), Vector3.new(65, 18, 2)},
        {Vector3.new(32.5, 9, 0), Vector3.new(2, 18, 65)},
        {Vector3.new(-32.5, 9, 0), Vector3.new(2, 18, 65)}
    }

    for idx, wallData in ipairs(wallOffsets) do
        local wall = Instance.new("Part")
        wall.Name = "Wall_" .. tostring(idx)
        wall.Size = wallData[2]
        wall.CFrame = CFrame.new(center + wallData[1])
        wall.Anchored = true
        wall.CanCollide = true
        wall.Material = Enum.Material.ForceField
        wall.Color = Color3.fromRGB(80, 150, 255)
        wall.Transparency = 0.6
        wall.Parent = model
    end

    SafePlatformModel = model
    return model, floor
end

local function DestroySafePlatform()
    if SafePlatformModel then
        pcall(function()
            SafePlatformModel:Destroy()
        end)
        SafePlatformModel = nil
    end
end

local function TeleportToSafePlatform()
    local _, floor = EnsureSafePlatform()
    if floor then
        TeleportTo(floor.CFrame + Vector3.new(0, 5, 0), "Safe Sky Platform")
    end
end

local function FindMapCenterCFrame()
    local map = Workspace:FindFirstChild("Map")
        or Workspace:FindFirstChild("Island")
        or Workspace:FindFirstChild("GameMap")
        or Workspace:FindFirstChild("ActiveMap")

    if map and map:IsA("Model") then
        local cf = map:GetPivot()
        if cf then
            return cf + Vector3.new(0, 8, 0)
        end
    end

    local spawns = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("SpawnLocation") then
            table.insert(spawns, obj)
        end
    end

    if #spawns > 0 then
        return spawns[1].CFrame + Vector3.new(0, 5, 0)
    end

    return CFrame.new(0, 50, 0)
end

local function FindLobbyCFrame()
    local lobby = Workspace:FindFirstChild("Lobby")
        or Workspace:FindFirstChild("Spawn")
        or Workspace:FindFirstChild("Hub")

    if lobby and lobby:IsA("Model") then
        return lobby:GetPivot() + Vector3.new(0, 6, 0)
    end

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("SpawnLocation") and string.find(string.lower(obj.Name), "lobby") then
            return obj.CFrame + Vector3.new(0, 5, 0)
        end
    end

    return CFrame.new(0, 200, 0)
end

local function FindHighestMapPart()
    local highestPart = nil
    local maxY = -math.huge

    for _, part in ipairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart")
        and part.CanCollide
        and not part:IsDescendantOf(SafePlatformModel or Workspace)
        and part.Position.Y > maxY
        and part.Position.Y < 2000 then
            local isChar = false
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Character and part:IsDescendantOf(p.Character) then
                    isChar = true
                    break
                end
            end

            if not isChar then
                maxY = part.Position.Y
                highestPart = part
            end
        end
    end

    if highestPart then
        return highestPart.CFrame + Vector3.new(0, highestPart.Size.Y / 2 + 5, 0)
    end

    return nil
end

local function FindRandomSurvivor()
    local candidates = {}
    for _, target in ipairs(Players:GetPlayers()) do
        if target ~= Player and target.Character then
            local hum = target.Character:FindFirstChildOfClass("Humanoid")
            local root = target.Character:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and root then
                table.insert(candidates, target)
            end
        end
    end

    if #candidates > 0 then
        return candidates[math.random(1, #candidates)]
    end

    return nil
end

local function ScanAndNeutralizeHazards()
    local hazardKeywords = {
        "lava", "acid", "kill", "damage", "fire", "meteor",
        "spike", "hazard", "tsunami", "toxic", "death"
    }

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local name = string.lower(obj.Name)
            local isHazard = false

            for _, kw in ipairs(hazardKeywords) do
                if string.find(name, kw) then
                    isHazard = true
                    break
                end
            end

            if isHazard then
                pcall(function()
                    obj.CanTouch = false
                    for _, child in ipairs(obj:GetChildren()) do
                        if child:IsA("TouchTransmitter") then
                            child:Destroy()
                        end
                    end
                end)
            end
        end
    end
end

local function CheckDisasterNotice()
    local playerGui = Player:FindFirstChildOfClass("PlayerGui")
    if not playerGui then
        return
    end

    local textFound = nil

    for _, label in ipairs(playerGui:GetDescendants()) do
        if label:IsA("TextLabel") and label.Visible then
            local text = label.Text
            if typeof(text) == "string" and #text >= 3 and #text <= 70 then
                local low = string.lower(text)
                if string.find(low, "disaster")
                or string.find(low, "what if")
                or string.find(low, "incoming")
                or string.find(low, "survive")
                or string.find(low, "warning") then
                    textFound = text
                    break
                end
            end
        end
    end

    if not textFound then
        local rsDisaster = ReplicatedStorage:FindFirstChild("Disaster")
            or ReplicatedStorage:FindFirstChild("CurrentDisaster")
            or ReplicatedStorage:FindFirstChild("RoundStatus")
        if rsDisaster and rsDisaster:IsA("StringValue") and #rsDisaster.Value > 0 then
            textFound = rsDisaster.Value
        end
    end

    if textFound and textFound ~= LastAnnouncedDisaster then
        LastAnnouncedDisaster = textFound
        CustomNotify("Disaster: " .. textFound, Color3.fromRGB(255, 175, 40), 5)
    end
end

TrackConnection(RunService.Heartbeat:Connect(function()
    local character, humanoid, root = GetCharacterState()
    if not humanoid or humanoid.Health <= 0 or not root then
        return
    end

    if Settings.WIDAntiVoid and root.Position.Y < 15 then
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        local _, floor = EnsureSafePlatform()
        if floor then
            root.CFrame = floor.CFrame + Vector3.new(0, 5, 0)
        else
            root.CFrame = CFrame.new(root.Position.X, tonumber(Settings.WIDPlatformHeight) or 350, root.Position.Z)
        end
        CustomNotify("Void Rescue activated!", Color3.fromRGB(100, 255, 100), 2)
    end

    if Settings.WIDAntiFling then
        local angVel = root.AssemblyAngularVelocity
        if angVel.Magnitude > 75 then
            root.AssemblyAngularVelocity = Vector3.zero
        end

        local linVel = root.AssemblyLinearVelocity
        if linVel.Magnitude > 220 then
            root.AssemblyLinearVelocity = Vector3.new(
                math.clamp(linVel.X, -60, 60),
                math.clamp(linVel.Y, -80, 80),
                math.clamp(linVel.Z, -60, 60)
            )
        end
    end

    if Settings.WIDNoFallDamage and root.AssemblyLinearVelocity.Y < -55 then
        root.AssemblyLinearVelocity = Vector3.new(
            root.AssemblyLinearVelocity.X,
            -25,
            root.AssemblyLinearVelocity.Z
        )
    end

    if Settings.WIDAirWalk then
        if not AirWalkPart or not AirWalkPart.Parent then
            AirWalkPart = Instance.new("Part")
            AirWalkPart.Name = "ToxAirWalkPart"
            AirWalkPart.Size = Vector3.new(4, 1, 4)
            AirWalkPart.Transparency = 1
            AirWalkPart.Anchored = true
            AirWalkPart.CanCollide = true
            AirWalkPart.Parent = Workspace
        end
        AirWalkPart.CFrame = CFrame.new(root.Position.X, root.Position.Y - 3.2, root.Position.Z)
    else
        if AirWalkPart then
            pcall(function() AirWalkPart:Destroy() end)
            AirWalkPart = nil
        end
    end
end))

TrackConnection(RunService.Stepped:Connect(function()
    if Settings.Noclip then
        local character = Player.Character
        if character then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end
end))

TrackConnection(UserInputService.JumpRequest:Connect(function()
    if Settings.WIDInfiniteJump then
        local _, humanoid = GetCharacterState()
        if humanoid and humanoid.Health > 0 then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end))

TrackConnection(Player.Idled:Connect(function()
    if Settings.WIDAntiAFK then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.zero)
        end)
    end
end))

task.spawn(function()
    while true do
        task.wait(1)
        if getgenv().Destroyed then
            break
        end

        if Settings.WIDAutoWin or Settings.WIDAutoSafeSpot then
            local character, humanoid, root = GetCharacterState()
            if humanoid and humanoid.Health > 0 and root then
                local _, floor = EnsureSafePlatform()
                if floor then
                    local dist = (root.Position - floor.Position).Magnitude
                    if dist > 35 then
                        TeleportTo(floor.CFrame + Vector3.new(0, 5, 0), "Safe Platform")
                    end

                    if Settings.WIDAnchorOnPlatform then
                        root.Anchored = true
                    end
                end
            end
        else
            local _, _, root = GetCharacterState()
            if root and root.Anchored and not Settings.WIDAnchorOnPlatform then
                root.Anchored = false
            end
        end

        if Settings.WIDAntiHazards then
            pcall(ScanAndNeutralizeHazards)
        end

        if Settings.WIDNotifyDisasters then
            pcall(CheckDisasterNotice)
        end
    end
end)

CreateWIDSection("SURVIVAL & AUTO-FARM")

WIDCreateToggle(
    "Auto Win (Safe AFK Farm)",
    GamePage,
    Settings.WIDAutoWin,
    function(v)
        Settings.WIDAutoWin = v == true
        if v then
            EnsureSafePlatform()
            TeleportToSafePlatform()
            CustomNotify("Auto Win Enabled", Color3.fromRGB(100, 255, 100), 3)
        else
            local _, _, root = GetCharacterState()
            if root then
                root.Anchored = false
            end
        end
        AutoSaveConfiguration()
    end,
    "WIDAutoWin"
)

WIDCreateToggle(
    "Auto Safe Spot Lock",
    GamePage,
    Settings.WIDAutoSafeSpot,
    function(v)
        Settings.WIDAutoSafeSpot = v == true
        if v then
            TeleportToSafePlatform()
        else
            local _, _, root = GetCharacterState()
            if root then
                root.Anchored = false
            end
        end
        AutoSaveConfiguration()
    end,
    "WIDAutoSafeSpot"
)

WIDCreateToggle(
    "Anchor Root on Safe Platform",
    GamePage,
    Settings.WIDAnchorOnPlatform,
    function(v)
        Settings.WIDAnchorOnPlatform = v == true
        local _, _, root = GetCharacterState()
        if root and not v then
            root.Anchored = false
        end
        AutoSaveConfiguration()
    end,
    "WIDAnchorOnPlatform"
)

WIDCreateToggle(
    "Anti-AFK (20m Disconnect Saver)",
    GamePage,
    Settings.WIDAntiAFK,
    function(v)
        Settings.WIDAntiAFK = v == true
        AutoSaveConfiguration()
    end,
    "WIDAntiAFK"
)

CreateWIDSection("SAFE SKY PLATFORM")

WIDCreateToggleWithValue(
    "Spawn Safe Sky Platform",
    GamePage,
    Settings.WIDSafePlatform,
    Settings.WIDPlatformHeight,
    function(v)
        Settings.WIDSafePlatform = v == true
        if v then
            EnsureSafePlatform()
        else
            DestroySafePlatform()
        end
        AutoSaveConfiguration()
    end,
    function(val)
        local newHeight = math.clamp(tonumber(val) or 350, 80, 1800)
        Settings.WIDPlatformHeight = newHeight
        if SafePlatformModel and SafePlatformModel.Parent then
            EnsureSafePlatform()
        end
        AutoSaveConfiguration()
    end,
    "WIDSafePlatform"
)

WIDCreateButton(
    "Teleport to Safe Sky Platform",
    GamePage,
    function()
        TeleportToSafePlatform()
    end
)

WIDCreateButton(
    "Rebuild / Refresh Platform",
    GamePage,
    function()
        DestroySafePlatform()
        EnsureSafePlatform()
        TeleportToSafePlatform()
        CustomNotify("Platform Refreshed", Color3.fromRGB(100, 255, 100), 2)
    end
)

CreateWIDSection("PROTECTION & GODMODE")

WIDCreateToggle(
    "Anti Void (Bottom Fall Saver)",
    GamePage,
    Settings.WIDAntiVoid,
    function(v)
        Settings.WIDAntiVoid = v == true
        AutoSaveConfiguration()
    end,
    "WIDAntiVoid"
)

WIDCreateToggle(
    "No Fall Damage",
    GamePage,
    Settings.WIDNoFallDamage,
    function(v)
        Settings.WIDNoFallDamage = v == true
        AutoSaveConfiguration()
    end,
    "WIDNoFallDamage"
)

WIDCreateToggle(
    "Anti-Fling & Body Stabilizer",
    GamePage,
    Settings.WIDAntiFling,
    function(v)
        Settings.WIDAntiFling = v == true
        AutoSaveConfiguration()
    end,
    "WIDAntiFling"
)

WIDCreateToggle(
    "Disable Hazard Touch (Lava/Acid/Kill)",
    GamePage,
    Settings.WIDAntiHazards,
    function(v)
        Settings.WIDAntiHazards = v == true
        if v then
            pcall(ScanAndNeutralizeHazards)
        end
        AutoSaveConfiguration()
    end,
    "WIDAntiHazards"
)

WIDCreateToggle(
    "Notify Disasters & Warnings",
    GamePage,
    Settings.WIDNotifyDisasters,
    function(v)
        Settings.WIDNotifyDisasters = v == true
        AutoSaveConfiguration()
    end,
    "WIDNotifyDisasters"
)

CreateWIDSection("MOVEMENT & PLAYER")

WIDCreateToggleWithValue(
    "Speed",
    GamePage,
    Settings.Speed == true,
    tonumber(Settings.SpeedValue) or 16,
    function(v)
        SetShared("Speed", v == true)
    end,
    function(val)
        local newVal = math.clamp(tonumber(val) or 16, 1, 250)
        Settings.SpeedValue = newVal
        if getgenv().ToxSetSharedValue then
            getgenv().ToxSetSharedValue("Speed", newVal)
        end
    end,
    "Speed"
)

WIDCreateToggleWithValue(
    "Jump",
    GamePage,
    Settings.Jump == true,
    tonumber(Settings.JumpValue) or 50,
    function(v)
        SetShared("Jump", v == true)
    end,
    function(val)
        local newVal = math.clamp(tonumber(val) or 50, 1, 300)
        Settings.JumpValue = newVal
        if getgenv().ToxSetSharedValue then
            getgenv().ToxSetSharedValue("Jump", newVal)
        end
    end,
    "Jump"
)

WIDCreateToggle(
    "Noclip",
    GamePage,
    Settings.Noclip == true,
    function(v)
        SetShared("Noclip", v == true)
    end,
    "Noclip"
)

WIDCreateToggle(
    "Infinite Jump",
    GamePage,
    Settings.WIDInfiniteJump,
    function(v)
        Settings.WIDInfiniteJump = v == true
        AutoSaveConfiguration()
    end,
    "WIDInfiniteJump"
)

WIDCreateToggle(
    "Air Walk (Float on Air)",
    GamePage,
    Settings.WIDAirWalk,
    function(v)
        Settings.WIDAirWalk = v == true
        if not v and AirWalkPart then
            pcall(function() AirWalkPart:Destroy() end)
            AirWalkPart = nil
        end
        AutoSaveConfiguration()
    end,
    "WIDAirWalk"
)

CreateWIDSection("TELEPORTS & LOCATIONS")

WIDCreateButton(
    "Teleport to Lobby / Spawn",
    GamePage,
    function()
        TeleportTo(FindLobbyCFrame(), "Lobby")
    end
)

WIDCreateButton(
    "Teleport to Map Center",
    GamePage,
    function()
        TeleportTo(FindMapCenterCFrame(), "Map Center")
    end
)

WIDCreateButton(
    "Teleport to Highest Point on Map",
    GamePage,
    function()
        local cf = FindHighestMapPart()
        if cf then
            TeleportTo(cf, "Highest Point")
        else
            CustomNotify("High ground not found", Color3.fromRGB(255, 100, 100), 2)
        end
    end
)

WIDCreateButton(
    "Teleport to Random Survivor",
    GamePage,
    function()
        local survivor = FindRandomSurvivor()
        if survivor and survivor.Character then
            local root = survivor.Character:FindFirstChild("HumanoidRootPart")
            if root then
                TeleportTo(root.CFrame + Vector3.new(0, 3, 2), survivor.DisplayName)
            end
        else
            CustomNotify("No other survivors found", Color3.fromRGB(255, 150, 50), 2)
        end
    end
)

getgenv().ToxWIDCleanup = function()
    for _, conn in ipairs(WIDConnections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(WIDConnections)

    if SafePlatformModel then
        pcall(function() SafePlatformModel:Destroy() end)
        SafePlatformModel = nil
    end

    if AirWalkPart then
        pcall(function() AirWalkPart:Destroy() end)
        AirWalkPart = nil
    end

    local _, _, root = GetCharacterState()
    if root and root.Anchored and not Settings.WIDAnchorOnPlatform then
        root.Anchored = false
    end
end

getgenv().ToxWIDModuleLoadedJobId = game.JobId
getgenv().ToxWIDModuleVersion = WIDModuleVersion
getgenv().ToxWIDModulePage = GamePage
