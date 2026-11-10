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
local Mouse = Player:GetMouse()

local Settings = getgenv().Settings
local GamePage = getgenv().GamePage
local CreateToggle = getgenv().CreateToggle
local CreateToggleWithValue = getgenv().CreateToggleWithValue
local CreateButton = getgenv().CreateButton
local CreateDropdown = getgenv().CreateDropdown
local CreateToggleWithChoice = getgenv().CreateToggleWithChoice
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

getgenv().ToxWIDGeneration = (tonumber(getgenv().ToxWIDGeneration) or 0) + 1
local CurrentGeneration = getgenv().ToxWIDGeneration

local WIDModuleVersion = "2026-10-30-wid-v13"

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
Settings.WIDAutoWinMode = (Settings.WIDAutoWinMode == "Map" or Settings.WIDAutoWinMode == "Platform")
    and Settings.WIDAutoWinMode
    or "Platform"
Settings.WIDRelocateOnDamage = Settings.WIDRelocateOnDamage == true
Settings.WIDAntiDamage = Settings.WIDAntiDamage ~= false
Settings.WIDSafePlatform = Settings.WIDSafePlatform == true
Settings.WIDPlatformHeight = tonumber(Settings.WIDPlatformHeight) or 380
Settings.WIDAntiVoid = Settings.WIDAntiVoid ~= false
Settings.WIDNoFallDamage = Settings.WIDNoFallDamage ~= false
Settings.WIDAntiFling = Settings.WIDAntiFling == true
Settings.WIDAntiHazards = Settings.WIDAntiHazards ~= false
Settings.WIDNotifyDisasters = Settings.WIDNotifyDisasters == true
Settings.WIDAntiAFK = Settings.WIDAntiAFK == true
Settings.WIDInfiniteJump = Settings.WIDInfiniteJump == true
Settings.WIDAirWalk = Settings.WIDAirWalk == true
Settings.ClickTP = Settings.ClickTP == true
Settings.WIDPreventLobbyPull = Settings.WIDPreventLobbyPull ~= false

local WIDConnections = {}
local WIDCurrentSection = nil
local WIDSections = {}
local SafePlatformModel = nil
local AirWalkPart = nil
local AirWalkY = nil
local LastAnnouncedDisaster = ""
local LastRecordedHealth = 100
local LastDamageEvacTime = 0
local CurrentMapShelterIndex = 1
local LastSafetyState = "UNKNOWN"
local IsPlayerConfirmedSafe = false
local IsEvacuatedToMap = false
local RelocationGracePeriodUntil = 0
local RelocationBaseHealth = 100
local RoundTeleportDone = false
local LastSafeZoneNotification = 0

local hazardKeywords = {
    "lava", "acid", "kill", "damage", "fire", "meteor",
    "spike", "hazard", "tsunami", "toxic", "death", "debris",
    "falling", "rock", "magma", "beam", "laser"
}

pcall(function()
    if hookmetamethod and getnamecallmethod then
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if method == "FireServer" or method == "fireServer" then
                if Settings.WIDAntiDamage then
                    local name = string.lower(tostring(self.Name))
                    if string.find(name, "damage")
                    or string.find(name, "temp")
                    or string.find(name, "cold")
                    or string.find(name, "freeze")
                    or string.find(name, "heat")
                    or string.find(name, "burn")
                    or string.find(name, "hazard")
                    or string.find(name, "hurt")
                    or string.find(name, "takedamage")
                    or string.find(name, "dealdamage")
                    or string.find(name, "health")
                    or string.find(name, "hit") then
                        return nil
                    end
                end
            end
            return oldNamecall(self, ...)
        end))
    end
end)

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

    local Enabled = getgenv().ToxOptionsReady == false
        and false
        or (DefaultToggle == true)

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

local function WIDCreateToggleWithChoice(...)
    local fn = CreateToggleWithChoice or CreateToggleWithChoiceLocal
    return TrackControl(fn(...))
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

local function ClearAllWIDWorkspaceObjects()
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj.Name == "ToxWIDPlatform" or obj.Name == "ToxAirWalkPart" then
            pcall(function() obj:Destroy() end)
        end
    end
    SafePlatformModel = nil
    if AirWalkPart then
        pcall(function() AirWalkPart:Destroy() end)
        AirWalkPart = nil
    end
    AirWalkY = nil
end

ClearAllWIDWorkspaceObjects()

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

local function GetClickTPCFrame()
    local character, humanoid, root = GetCharacterState()
    if not root then
        return nil
    end

    local ray = Camera:ScreenPointToRay(Mouse.X, Mouse.Y)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local exclude = {character}
    if SafePlatformModel then table.insert(exclude, SafePlatformModel) end
    if AirWalkPart then table.insert(exclude, AirWalkPart) end
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
    if gameProcessed then
        return
    end

    if Settings.ClickTP and input.UserInputType == Enum.UserInputType.MouseButton1 then
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then
            local targetCF = GetClickTPCFrame()
            if targetCF then
                TeleportTo(targetCF, "Click TP")
            end
        end
    end
end))

local function FindLobbyCFrame()
    local lobby = Workspace:FindFirstChild("Lobby")
        or Workspace:FindFirstChild("Spawn")
        or Workspace:FindFirstChild("Hub")
        or Workspace:FindFirstChild("MainLobby")

    if lobby and lobby:IsA("Model") then
        return lobby:GetPivot() + Vector3.new(0, 6, 0)
    end

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("SpawnLocation") and string.find(string.lower(obj.Name), "lobby") then
            return obj.CFrame + Vector3.new(0, 5, 0)
        end
    end

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("SpawnLocation") then
            return obj.CFrame + Vector3.new(0, 5, 0)
        end
    end

    return CFrame.new(0, 200, 0)
end

local function IsPlayerInLobby()
    local _, _, root = GetCharacterState()
    if not root then
        return false
    end

    local lobbyCF = FindLobbyCFrame()
    local dx = root.Position.X - lobbyCF.Position.X
    local dz = root.Position.Z - lobbyCF.Position.Z
    local distXZ = math.sqrt(dx * dx + dz * dz)

    return distXZ < 160
end

local function IsIntermission()
    local text = ""

    local rsStatus = ReplicatedStorage:FindFirstChild("Status")
        or ReplicatedStorage:FindFirstChild("RoundStatus")
        or ReplicatedStorage:FindFirstChild("GameState")
        or ReplicatedStorage:FindFirstChild("Round")
        or ReplicatedStorage:FindFirstChild("Disaster")

    if rsStatus and rsStatus:IsA("StringValue") then
        text = text .. " " .. string.lower(rsStatus.Value)
    end

    local playerGui = Player:FindFirstChildOfClass("PlayerGui")
    if playerGui then
        for _, label in ipairs(playerGui:GetDescendants()) do
            if label:IsA("TextLabel") and label.Visible then
                local t = string.lower(label.Text)
                if string.find(t, "intermission")
                or string.find(t, "waiting")
                or string.find(t, "next round")
                or string.find(t, "starting in")
                or string.find(t, "game starts")
                or string.find(t, "round over") then
                    return true
                end
            end
        end
    end

    if string.find(text, "intermission")
    or string.find(text, "waiting")
    or string.find(text, "starting in")
    or string.find(text, "round over") then
        return true
    end

    return false
end

local function GetGameSafetyStatus()
    local containers = {}
    local pg = Player:FindFirstChildOfClass("PlayerGui")
    if pg then table.insert(containers, pg) end
    if Player.Character then table.insert(containers, Player.Character) end
    if Camera then table.insert(containers, Camera) end

    for _, container in ipairs(containers) do
        for _, label in ipairs(container:GetDescendants()) do
            if label:IsA("TextLabel") and label.Visible then
                local text = label.Text
                if typeof(text) == "string" and #text >= 3 and #text <= 75 then
                    local low = string.lower(text)
                    -- Check for explicit SAFE indicator
                    if string.find(low, "against the wall")
                    or string.find(low, "stay against")
                    or string.find(low, "stay inside")
                    or string.find(low, "stay near")
                    or string.find(low, "stay safe")
                    or string.find(low, "safe")
                    or string.find(low, "warm")
                    or string.find(low, "comfort")
                    or string.find(low, "shelter") then
                        local col = label.TextColor3
                        -- Mint green / vibrant green check (e.g. R=110, G=240, B=165)
                        if col.G >= 0.55 and col.G > col.R and (col.G - col.R) >= 0.12 then
                            return "SAFE", label.Text
                        end
                    end

                    -- Check for explicit DANGER action instruction (must exclude general banners)
                    if (string.find(low, "find shelter")
                    or string.find(low, "seek shelter")
                    or string.find(low, "get inside")
                    or string.find(low, "find warmth")
                    or string.find(low, "too cold")
                    or string.find(low, "seek high ground")
                    or string.find(low, "evacuate")
                    or string.find(low, "seek cover"))
                    and not string.find(low, "disaster:")
                    and not string.find(low, "round:")
                    and not string.find(low, "intermission") then
                        local col = label.TextColor3
                        if col.R >= 0.65 and col.G <= 0.45 and (col.R - col.G) >= 0.20 then
                            return "DANGER", label.Text
                        end
                    end
                end
            end
        end
    end

    -- Also check BillboardGuis / SurfaceGuis anywhere in Workspace (floating hints in 3D world)
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("BillboardGui") or obj:IsA("SurfaceGui") then
            for _, label in ipairs(obj:GetDescendants()) do
                if label:IsA("TextLabel") and label.Visible then
                    local text = label.Text
                    if typeof(text) == "string" and #text >= 3 and #text <= 75 then
                        local low = string.lower(text)
                        if string.find(low, "against the wall")
                        or string.find(low, "stay against")
                        or string.find(low, "stay inside")
                        or string.find(low, "safe")
                        or string.find(low, "warm") then
                            local col = label.TextColor3
                            if col.G >= 0.55 and col.G > col.R and (col.G - col.R) >= 0.12 then
                                return "SAFE", label.Text
                            end
                        end
                    end
                end
            end
        end
    end

    return "UNKNOWN", nil
end

local function GetActiveMap()
    local names = {
        "Map", "Island", "GameMap", "ActiveMap", "CurrentMap",
        "LoadedMap", "RoundMap", "Structure", "Structures"
    }
    for _, name in ipairs(names) do
        local found = Workspace:FindFirstChild(name)
        if found and found:IsA("Model") and #found:GetDescendants() > 10 then
            return found
        end
    end

    local lobbyCF = FindLobbyCFrame()
    local bestModel = nil
    local maxParts = 0

    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Model")
        and obj.Name ~= "ToxWIDPlatform"
        and not string.find(string.lower(obj.Name), "lobby")
        and not string.find(string.lower(obj.Name), "spawn")
        and not Players:GetPlayerFromCharacter(obj) then
            local partCount = 0
            for _, descendant in ipairs(obj:GetDescendants()) do
                if descendant:IsA("BasePart") then
                    partCount = partCount + 1
                end
            end
            if partCount > maxParts then
                local pivot = obj:GetPivot()
                local distFromLobby = (pivot.Position - lobbyCF.Position).Magnitude
                if distFromLobby > 100 then
                    maxParts = partCount
                    bestModel = obj
                end
            end
        end
    end

    return bestModel or Workspace
end

local function FindMapCenterCFrame()
    local map = GetActiveMap()

    if map and map:IsA("Model") and map ~= Workspace then
        local cf = map:GetPivot()
        if cf then
            return cf + Vector3.new(0, 8, 0)
        end
    end

    local spawns = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("SpawnLocation") and not string.find(string.lower(obj.Name), "lobby") then
            table.insert(spawns, obj)
        end
    end

    if #spawns > 0 then
        return spawns[1].CFrame + Vector3.new(0, 5, 0)
    end

    local _, _, root = GetCharacterState()
    if root and not IsPlayerInLobby() then
        return root.CFrame
    end

    local lobbyCF = FindLobbyCFrame()
    return lobbyCF * CFrame.new(0, -100, 450)
end

local function GetAllCandidateShelters()
    local map = GetActiveMap()
    local searchRoot = (map and map ~= Workspace) and map or Workspace
    local candidateRooms = {}
    local lobbyCF = FindLobbyCFrame()

    local excludeList = {Player.Character}
    if SafePlatformModel then
        table.insert(excludeList, SafePlatformModel)
    end

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = excludeList

    for _, part in ipairs(searchRoot:GetDescendants()) do
        if part:IsA("BasePart")
        and part.CanCollide
        and part.Size.X >= 3 and part.Size.Z >= 3
        and (not SafePlatformModel or not part:IsDescendantOf(SafePlatformModel))
        and not string.find(string.lower(part.Name), "platform") then
            local distLobby = (part.Position - lobbyCF.Position).Magnitude
            if distLobby > 100 and part.Position.Y > -30 and part.Position.Y < 180 then
                local standPos = Vector3.new(part.Position.X, part.Position.Y + (part.Size.Y / 2) + 3.2, part.Position.Z)
                local hitCeiling = Workspace:Raycast(standPos, Vector3.new(0, 35, 0), rayParams)

                if hitCeiling and hitCeiling.Instance and hitCeiling.Instance:IsA("BasePart") and hitCeiling.Instance.CanCollide then
                    local ceilingHeight = hitCeiling.Position.Y - standPos.Y
                    if ceilingHeight >= 5 and ceilingHeight <= 30 then
                        local score = 50
                        if ceilingHeight >= 7 and ceilingHeight <= 16 then
                            score = score + 30
                        end
                        if hitCeiling.Instance.Material ~= Enum.Material.Glass then
                            score = score + 20
                        end
                        if hitCeiling.Instance.Anchored then
                            score = score + 15
                        end

                        local wallCount = 0
                        local checkDirs = {
                            Vector3.new(18, 0, 0),
                            Vector3.new(-18, 0, 0),
                            Vector3.new(0, 0, 18),
                            Vector3.new(0, 0, -18)
                        }
                        for _, dir in ipairs(checkDirs) do
                            local hitWall = Workspace:Raycast(standPos, dir, rayParams)
                            if hitWall and hitWall.Instance and hitWall.Instance.CanCollide then
                                wallCount = wallCount + 1
                            end
                        end

                        if wallCount >= 2 then
                            score = score + (wallCount * 25)
                            table.insert(candidateRooms, {
                                CFrame = CFrame.new(standPos),
                                Score = score
                            })
                        end
                    end
                end
            end
        end
    end

    table.sort(candidateRooms, function(a, b)
        return a.Score > b.Score
    end)

    local list = {}
    for _, item in ipairs(candidateRooms) do
        local tooClose = false
        for _, existing in ipairs(list) do
            if (item.CFrame.Position - existing.Position).Magnitude < 15 then
                tooClose = true
                break
            end
        end
        if not tooClose then
            table.insert(list, item.CFrame)
            if #list >= 6 then
                break
            end
        end
    end

    if #list == 0 then
        for _, obj in ipairs(searchRoot:GetDescendants()) do
            if obj:IsA("Model") or obj:IsA("BasePart") then
                local name = string.lower(obj.Name)
                if string.find(name, "house")
                or string.find(name, "shelter")
                or string.find(name, "room")
                or string.find(name, "cabin")
                or string.find(name, "building") then
                    local cf = obj:IsA("Model") and obj:GetPivot() or obj.CFrame
                    local distLobby = (cf.Position - lobbyCF.Position).Magnitude
                    if distLobby > 100 and cf.Position.Y > -20 and cf.Position.Y < 150 then
                        table.insert(list, cf + Vector3.new(0, 3.5, 0))
                        if #list >= 4 then
                            break
                        end
                    end
                end
            end
        end
    end

    return list
end

local function FindInsideHouseCFrame()
    local shelters = GetAllCandidateShelters()
    if #shelters > 0 then
        return shelters[1]
    end
    return nil
end

local function FindHighestMapPart()
    local highestPart = nil
    local maxY = -math.huge
    local map = GetActiveMap()

    for _, part in ipairs(map:GetDescendants()) do
        if part:IsA("BasePart")
        and part.CanCollide
        and (not SafePlatformModel or not part:IsDescendantOf(SafePlatformModel))
        and part.Position.Y > maxY
        and part.Position.Y < 1500 then
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

local function FindOnTopOfHouseCFrame()
    local map = GetActiveMap()
    local searchRoot = (map and map ~= Workspace) and map or Workspace
    local candidateRoofs = {}
    local lobbyCF = FindLobbyCFrame()

    local excludeList = {Player.Character}
    if SafePlatformModel then
        table.insert(excludeList, SafePlatformModel)
    end

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = excludeList

    for _, part in ipairs(searchRoot:GetDescendants()) do
        if part:IsA("BasePart")
        and part.CanCollide
        and part.Size.X >= 5 and part.Size.Z >= 5
        and (not SafePlatformModel or not part:IsDescendantOf(SafePlatformModel))
        and not string.find(string.lower(part.Name), "platform") then
            local distLobby = (part.Position - lobbyCF.Position).Magnitude
            if distLobby > 110 and part.Position.Y >= 20 and part.Position.Y <= 220 then
                local topPos = Vector3.new(part.Position.X, part.Position.Y + (part.Size.Y / 2) + 3.5, part.Position.Z)
                local hitSky = Workspace:Raycast(topPos, Vector3.new(0, 40, 0), rayParams)

                if not hitSky then
                    local hitDown = Workspace:Raycast(part.Position - Vector3.new(0, part.Size.Y / 2, 0), Vector3.new(0, -25, 0), rayParams)
                    local score = part.Position.Y * 2
                    if hitDown and hitDown.Instance then
                        score = score + 40
                    end
                    if part.Anchored then
                        score = score + 20
                    end

                    table.insert(candidateRoofs, {
                        CFrame = CFrame.new(topPos),
                        Score = score
                    })
                end
            end
        end
    end

    if #candidateRoofs > 0 then
        table.sort(candidateRoofs, function(a, b)
            return a.Score > b.Score
        end)
        return candidateRoofs[1].CFrame
    end

    return FindHighestMapPart()
end

local function GetSafePlatformPosition(forceMap)
    local height = tonumber(Settings.WIDPlatformHeight) or 380
    local mapCF = FindMapCenterCFrame()

    if forceMap or IsPlayerInLobby() then
        return Vector3.new(mapCF.Position.X, height, mapCF.Position.Z)
    end

    local _, _, root = GetCharacterState()
    if root then
        return Vector3.new(root.Position.X, height, root.Position.Z)
    end

    return Vector3.new(mapCF.Position.X, height, mapCF.Position.Z)
end

local function EnsureSafePlatform(forceMap)
    if Settings.WIDAutoWinMode ~= "Platform" and not Settings.WIDSafePlatform then
        return nil, nil
    end

    local center = GetSafePlatformPosition(forceMap)

    if SafePlatformModel and SafePlatformModel.Parent then
        local floor = SafePlatformModel:FindFirstChild("PlatformFloor")
        if floor then
            local lobbyCF = FindLobbyCFrame()
            local dx = floor.Position.X - lobbyCF.Position.X
            local dz = floor.Position.Z - lobbyCF.Position.Z
            local distFromLobby = math.sqrt(dx * dx + dz * dz)
            local distToTarget = (floor.Position - center).Magnitude

            if distFromLobby >= 140 and distToTarget < 60 then
                return SafePlatformModel, floor
            end
        end
    end

    ClearAllWIDWorkspaceObjects()

    local model = Instance.new("Model")
    model.Name = "ToxWIDPlatform"
    model.Parent = Workspace

    local floor = Instance.new("Part")
    floor.Name = "PlatformFloor"
    floor.Size = Vector3.new(70, 4, 70)
    floor.CFrame = CFrame.new(center)
    floor.Anchored = true
    floor.CanCollide = true
    floor.Material = Enum.Material.SmoothPlastic
    floor.Color = Color3.fromRGB(25, 28, 36)
    floor.Parent = model

    local roof = Instance.new("Part")
    roof.Name = "PlatformRoof"
    roof.Size = Vector3.new(90, 4, 90)
    roof.CFrame = CFrame.new(center + Vector3.new(0, 20, 0))
    roof.Anchored = true
    roof.CanCollide = true
    roof.Material = Enum.Material.SmoothPlastic
    roof.Color = Color3.fromRGB(30, 34, 44)
    roof.Transparency = 0
    roof.Parent = model

    local wallOffsets = {
        {Vector3.new(0, 10, 35), Vector3.new(70, 20, 2)},
        {Vector3.new(0, 10, -35), Vector3.new(70, 20, 2)},
        {Vector3.new(35, 10, 0), Vector3.new(2, 20, 70)},
        {Vector3.new(-35, 10, 0), Vector3.new(2, 20, 70)}
    }

    for idx, wallData in ipairs(wallOffsets) do
        local wall = Instance.new("Part")
        wall.Name = "Wall_" .. tostring(idx)
        wall.Size = wallData[2]
        wall.CFrame = CFrame.new(center + wallData[1])
        wall.Anchored = true
        wall.CanCollide = true
        wall.Material = Enum.Material.SmoothPlastic
        wall.Color = Color3.fromRGB(40, 45, 58)
        wall.Transparency = 0.3
        wall.Parent = model
    end

    SafePlatformModel = model
    return model, floor
end

local function IsPlayerOnPlatform()
    local _, _, root = GetCharacterState()
    if not root then return false end
    local platformHeight = tonumber(Settings.WIDPlatformHeight) or 380
    return root.Position.Y > (platformHeight - 35)
end

local function TeleportToSafePlatform(forceMap)
    local _, floor = EnsureSafePlatform(forceMap ~= false)
    if floor then
        TeleportTo(floor.CFrame + Vector3.new(0, 5, 0), "Sky Platform")
    else
        TeleportTo(FindMapCenterCFrame(), "Map Center")
    end
end

local function FindHeatSourceCFrame()
    local map = GetActiveMap()
    local searchRoot = (map and map ~= Workspace) and map or Workspace
    local lobbyCF = FindLobbyCFrame()
    local bestSource = nil
    local bestDist = math.huge
    local _, _, root = GetCharacterState()
    local playerPos = root and root.Position or lobbyCF.Position

    local heatNames = {
        "fire", "camp", "heat", "warm", "stove", "radiator",
        "furnace", "torch", "hearth", "bonfire", "lamp"
    }

    for _, obj in ipairs(searchRoot:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local name = string.lower(obj.Name)
            local isHeat = false
            for _, kw in ipairs(heatNames) do
                if string.find(name, kw) then
                    isHeat = true
                    break
                end
            end

            if not isHeat and obj:IsA("BasePart") then
                if obj:FindFirstChildOfClass("Fire")
                or obj:FindFirstChildOfClass("PointLight")
                or obj:FindFirstChildOfClass("SurfaceLight") then
                    local pName = obj.Parent and string.lower(obj.Parent.Name) or ""
                    for _, kw in ipairs(heatNames) do
                        if string.find(pName, kw) then
                            isHeat = true
                            break
                        end
                    end
                end
            end

            if isHeat then
                local cf = obj:IsA("Model") and obj:GetPivot() or obj.CFrame
                local distLobby = (cf.Position - lobbyCF.Position).Magnitude
                if distLobby > 80 and cf.Position.Y > -25 and cf.Position.Y < 180 then
                    local d = (cf.Position - playerPos).Magnitude
                    if d < bestDist then
                        bestDist = d
                        bestSource = cf
                    end
                end
            end
        end
    end

    if bestSource then
        return bestSource * CFrame.new(0, 3.5, 4)
    end
    return nil
end

local function GetBestMapSurvivalCFrame(reason)
    local dis = string.lower(LastAnnouncedDisaster or "")
    local reasonStr = string.lower(tostring(reason or ""))
    local isCold = string.find(dis, "cold")
        or string.find(dis, "blizzard")
        or string.find(dis, "freeze")
        or string.find(dis, "frost")
        or string.find(dis, "ice")
        or string.find(reasonStr, "cold")
        or string.find(reasonStr, "warm")

    if isCold then
        local heatCF = FindHeatSourceCFrame()
        if heatCF then
            return heatCF, "Campfire / Heat Source"
        end
    end

    local shelters = GetAllCandidateShelters()
    if #shelters >= CurrentMapShelterIndex then
        return shelters[CurrentMapShelterIndex], "Map Shelter " .. CurrentMapShelterIndex
    elseif #shelters > 0 then
        return shelters[1], "Map Shelter 1"
    end

    local roof = FindOnTopOfHouseCFrame()
    if roof then
        return roof, "High Ground"
    end

    return FindMapCenterCFrame(), "Map Center"
end

local function GetCurrentTargetCFrame()
    local mode = Settings.WIDAutoWinMode or "Platform"

    if mode == "Platform" and not IsEvacuatedToMap then
        local _, floor = EnsureSafePlatform(true)
        if floor then
            return floor.CFrame + Vector3.new(0, 5, 0), "Sky Platform"
        end
        return FindMapCenterCFrame(), "Map Center"
    else
        return GetBestMapSurvivalCFrame("AutoWin Target")
    end
end

local function HandleAutoWinRelocation(reason)
    if not Settings.WIDAutoWin or IsIntermission() then
        return
    end

    if IsPlayerOnPlatform() then
        IsEvacuatedToMap = true
    end

    local targetCF, spotLabel = GetBestMapSurvivalCFrame(reason)
    if targetCF then
        CurrentMapShelterIndex = CurrentMapShelterIndex + 1
        local shelters = GetAllCandidateShelters()
        if CurrentMapShelterIndex > math.max(#shelters, 1) then
            CurrentMapShelterIndex = 1
        end
        TeleportTo(targetCF, spotLabel)
    else
        TeleportTo(FindMapCenterCFrame(), "Map Center (" .. tostring(reason or "Safe") .. ")")
    end
end

local function NeutralizeDamageScripts()
    if not Settings.WIDAntiDamage then
        return
    end

    local char = Player.Character
    if char then
        for _, child in ipairs(char:GetChildren()) do
            if child:IsA("LocalScript") or child:IsA("Script") then
                local name = string.lower(child.Name)
                if string.find(name, "temp")
                or string.find(name, "cold")
                or string.find(name, "freeze")
                or string.find(name, "heat")
                or string.find(name, "burn")
                or string.find(name, "damage")
                or string.find(name, "ragdoll") then
                    pcall(function()
                        child.Disabled = true
                        child:Destroy()
                    end)
                end
            end
        end

        for _, child in ipairs(char:GetDescendants()) do
            if child:IsA("Fire") or (child:IsA("ParticleEmitter") and (string.find(string.lower(child.Name), "fire") or string.find(string.lower(child.Name), "burn"))) then
                pcall(function()
                    child.Enabled = false
                    child:Destroy()
                end)
            end
        end

        local ff = char:FindFirstChild("ToxDamageShield")
        if not ff then
            ff = Instance.new("ForceField")
            ff.Name = "ToxDamageShield"
            ff.Visible = false
            ff.Parent = char
        end
    end

    local pg = Player:FindFirstChildOfClass("PlayerGui")
    if pg then
        for _, desc in ipairs(pg:GetDescendants()) do
            if desc:IsA("LocalScript") then
                local name = string.lower(desc.Name)
                if string.find(name, "temp")
                or string.find(name, "cold")
                or string.find(name, "freeze")
                or string.find(name, "heat") then
                    pcall(function()
                        desc.Disabled = true
                    end)
                end
            end
        end
    end
end

local function BindCharacterHealth(character)
    if not character then
        return
    end

    local humanoid = character:WaitForChild("Humanoid", 5) or character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return
    end

    LastRecordedHealth = humanoid.Health

    TrackConnection(humanoid.HealthChanged:Connect(function(newHealth)
        if newHealth < LastRecordedHealth - 0.5 then
            LastRecordedHealth = newHealth

            if not Settings.WIDAutoWin or IsIntermission() then
                return
            end

            -- 1. If currently on Platform: IMMEDIATELY evacuate to map shelter!
            if IsPlayerOnPlatform() then
                IsEvacuatedToMap = true
                IsPlayerConfirmedSafe = false
                RelocationGracePeriodUntil = tick() + 6.0
                RelocationBaseHealth = newHealth
                LastDamageEvacTime = tick()
                local targetCF, spotLabel = GetBestMapSurvivalCFrame("Platform Damage")
                if targetCF then
                    CustomNotify("Damage on Platform! Evacuating to " .. spotLabel, Color3.fromRGB(255, 180, 50), 3)
                    TeleportTo(targetCF, spotLabel)
                end
                return
            end

            -- 2. Player is already on the map:
            -- If safety prompt is GREEN / SAFE: DO NOT relocate on lingering ticks!
            if IsPlayerConfirmedSafe then
                return
            end

            -- 3. In grace period (first 6 seconds after relocating):
            -- Allow warming up / fire extinguishing without teleporting in loop!
            if tick() < RelocationGracePeriodUntil then
                if (RelocationBaseHealth - newHealth) > 35 then
                    RelocationGracePeriodUntil = tick() + 6.0
                    RelocationBaseHealth = newHealth
                    LastDamageEvacTime = tick()
                    HandleAutoWinRelocation("Emergency Relocation")
                end
                return
            end

            -- 4. Grace period has expired and player is still losing health and not safe:
            if Settings.WIDRelocateOnDamage and (tick() - LastDamageEvacTime) > 3.0 then
                LastDamageEvacTime = tick()
                RelocationGracePeriodUntil = tick() + 6.0
                RelocationBaseHealth = newHealth
                HandleAutoWinRelocation("Continuous Damage")
            end
        else
            LastRecordedHealth = newHealth
        end
    end))
end

if Player.Character then
    BindCharacterHealth(Player.Character)
end

TrackConnection(Player.CharacterAdded:Connect(function(newChar)
    task.wait(0.5)
    BindCharacterHealth(newChar)
    CurrentMapShelterIndex = 1
    LastSafetyState = "UNKNOWN"
    IsPlayerConfirmedSafe = false
    IsEvacuatedToMap = false
    RelocationGracePeriodUntil = 0
    RelocationBaseHealth = 100
    RoundTeleportDone = false

    if Settings.WIDAutoWin and not IsIntermission() then
        task.wait(1)
        RoundTeleportDone = true
        local targetCF, label = GetCurrentTargetCFrame()
        if targetCF then
            TeleportTo(targetCF, label)
        end
    end
end))

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

local function NeutralizeSingleHazard(obj)
    if not obj or not obj.Parent then
        return
    end

    if obj:IsA("Explosion") then
        pcall(function()
            obj.BlastPressure = 0
            obj.BlastRadius = 0
            obj.DestroyJointRadiusPercent = 0
        end)
        return
    end

    if obj:IsA("BasePart") then
        local name = string.lower(obj.Name)
        for _, kw in ipairs(hazardKeywords) do
            if string.find(name, kw) then
                pcall(function()
                    obj.CanTouch = false
                    for _, child in ipairs(obj:GetChildren()) do
                        if child:IsA("TouchTransmitter") then
                            child:Destroy()
                        end
                    end
                end)
                break
            end
        end
    end
end

local function ScanAndNeutralizeHazards()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        NeutralizeSingleHazard(obj)
    end
end

TrackConnection(Workspace.DescendantAdded:Connect(function(obj)
    if Settings.WIDAntiHazards then
        NeutralizeSingleHazard(obj)
    end
end))

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

TrackConnection(RunService.Heartbeat:Connect(function(dt)
    local character, humanoid, root = GetCharacterState()
    if not humanoid or humanoid.Health <= 0 or not root then
        return
    end

    pcall(function()
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false)
    end)

    if Settings.WIDAntiVoid and root.Position.Y < 15 then
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        local targetCF, label = GetCurrentTargetCFrame()
        if targetCF then
            root.CFrame = targetCF
        else
            local mapCF = FindMapCenterCFrame()
            root.CFrame = CFrame.new(mapCF.Position.X, tonumber(Settings.WIDPlatformHeight) or 380, mapCF.Position.Z)
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
        if not AirWalkY then
            AirWalkY = root.Position.Y - 3.2
        end

        local vertSpeed = 30
        local movingUp = UserInputService:IsKeyDown(Enum.KeyCode.E) or UserInputService:IsKeyDown(Enum.KeyCode.Space)
        local movingDown = UserInputService:IsKeyDown(Enum.KeyCode.Q) or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)

        if movingUp and not movingDown then
            AirWalkY = AirWalkY + (vertSpeed * dt)
        elseif movingDown and not movingUp then
            AirWalkY = AirWalkY - (vertSpeed * dt)
        end

        if not AirWalkPart or not AirWalkPart.Parent then
            AirWalkPart = Instance.new("Part")
            AirWalkPart.Name = "ToxAirWalkPart"
            AirWalkPart.Size = Vector3.new(7, 1, 7)
            AirWalkPart.Transparency = 1
            AirWalkPart.Anchored = true
            AirWalkPart.CanCollide = true
            AirWalkPart.Material = Enum.Material.SmoothPlastic
            AirWalkPart.Parent = Workspace
        end

        AirWalkPart.CFrame = CFrame.new(root.Position.X, AirWalkY, root.Position.Z)
    else
        AirWalkY = nil
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
        if getgenv().Destroyed or CurrentGeneration ~= getgenv().ToxWIDGeneration then
            break
        end

        pcall(CheckDisasterNotice)
        pcall(NeutralizeDamageScripts)

        local character, humanoid, root = GetCharacterState()

        if humanoid and humanoid.Health > 0 and root then
            if IsIntermission() then
                RoundTeleportDone = false
                IsPlayerConfirmedSafe = false
                IsEvacuatedToMap = false
                RelocationGracePeriodUntil = 0
                LastSafetyState = "UNKNOWN"
                CurrentMapShelterIndex = 1
            else
                if Settings.WIDAutoWin then
                    local inLobby = IsPlayerInLobby()
                    local onPlatform = IsPlayerOnPlatform()
                    local safetyStatus, safetyPrompt = GetGameSafetyStatus()

                    if safetyStatus == "SAFE" then
                        IsPlayerConfirmedSafe = true
                        if LastSafetyState ~= "SAFE" and (tick() - LastSafeZoneNotification) > 5 then
                            LastSafeZoneNotification = tick()
                            CustomNotify("Safe Spot Confirmed: " .. tostring(safetyPrompt or "Protected"), Color3.fromRGB(100, 255, 100), 2)
                        end
                    elseif safetyStatus == "DANGER" then
                        IsPlayerConfirmedSafe = false
                    end
                    LastSafetyState = safetyStatus

                    if not RoundTeleportDone then
                        RoundTeleportDone = true
                        if Settings.WIDAutoWinMode == "Platform" and not IsEvacuatedToMap then
                            TeleportToSafePlatform(true)
                        else
                            local targetCF, spotLabel = GetBestMapSurvivalCFrame("Round Start")
                            if targetCF then
                                TeleportTo(targetCF, spotLabel)
                            end
                        end
                    elseif inLobby and Settings.WIDPreventLobbyPull then
                        if Settings.WIDAutoWinMode == "Platform" and not IsEvacuatedToMap then
                            TeleportToSafePlatform(true)
                        else
                            local targetCF, spotLabel = GetBestMapSurvivalCFrame("Anti Lobby Pull")
                            if targetCF then
                                TeleportTo(targetCF, spotLabel)
                            end
                        end
                    elseif onPlatform and not IsEvacuatedToMap then
                        local dis = string.lower(LastAnnouncedDisaster or "")
                        local hostileDisaster = string.find(dis, "cold")
                            or string.find(dis, "blizzard")
                            or string.find(dis, "freeze")
                            or string.find(dis, "frost")
                            or string.find(dis, "ice")
                            or string.find(dis, "fire")
                            or string.find(dis, "heat")
                            or string.find(dis, "wall")
                            or string.find(dis, "burn")

                        local dangerAlert = (safetyStatus == "DANGER")

                        if hostileDisaster or dangerAlert then
                            IsEvacuatedToMap = true
                            IsPlayerConfirmedSafe = false
                            RelocationGracePeriodUntil = tick() + 6.0
                            RelocationBaseHealth = humanoid.Health
                            local targetCF, spotLabel = GetBestMapSurvivalCFrame("Platform Evacuation (" .. (safetyPrompt or dis) .. ")")
                            if targetCF then
                                CustomNotify("Platform Unsafe -> Evacuating to " .. spotLabel, Color3.fromRGB(255, 180, 50), 3)
                                TeleportTo(targetCF, spotLabel)
                            end
                        end
                    end
                end
            end
        end

        if Settings.WIDAntiHazards then
            pcall(ScanAndNeutralizeHazards)
        end
    end
end)

CreateWIDSection("SURVIVAL & AUTO-FARM")

WIDCreateToggleWithChoice(
    "Auto Win",
    GamePage,
    {"Platform", "Map"},
    Settings.WIDAutoWin,
    Settings.WIDAutoWinMode or "Platform",
    function(v)
        Settings.WIDAutoWin = v == true
        if v then
            CurrentMapShelterIndex = 1
            IsPlayerConfirmedSafe = false
            IsEvacuatedToMap = false
            if not IsIntermission() then
                if Settings.WIDAutoWinMode == "Platform" then
                    TeleportToSafePlatform(true)
                else
                    local targetCF, spotLabel = GetBestMapSurvivalCFrame("Toggle Enabled")
                    if targetCF then
                        TeleportTo(targetCF, spotLabel)
                    end
                end
            end
            CustomNotify("Auto Win Enabled [" .. tostring(Settings.WIDAutoWinMode or "Platform") .. "]", Color3.fromRGB(100, 255, 100), 3)
        else
            if not Settings.WIDSafePlatform then
                ClearAllWIDWorkspaceObjects()
            end
            CustomNotify("Auto Win Disabled", Color3.fromRGB(255, 150, 50), 2)
        end
        AutoSaveConfiguration()
    end,
    function(option)
        Settings.WIDAutoWinMode = option
        CurrentMapShelterIndex = 1
        IsPlayerConfirmedSafe = false
        IsEvacuatedToMap = false
        if option == "Platform" then
            if Settings.WIDAutoWin and not IsIntermission() then
                TeleportToSafePlatform(true)
            end
        else
            if not Settings.WIDSafePlatform and SafePlatformModel then
                ClearAllWIDWorkspaceObjects()
            end
            if Settings.WIDAutoWin and not IsIntermission() then
                local targetCF, spotLabel = GetBestMapSurvivalCFrame("Mode Switch")
                if targetCF then
                    TeleportTo(targetCF, spotLabel)
                end
            end
        end
        CustomNotify("Auto Win Target: " .. tostring(option), Color3.fromRGB(100, 255, 100), 2)
        AutoSaveConfiguration()
    end,
    "WIDAutoWin"
)

WIDCreateToggle(
    "Relocate on Damage",
    GamePage,
    Settings.WIDRelocateOnDamage,
    function(v)
        Settings.WIDRelocateOnDamage = v == true
        AutoSaveConfiguration()
    end,
    "WIDRelocateOnDamage"
)

WIDCreateToggle(
    "Anti Hazard Damage",
    GamePage,
    Settings.WIDAntiDamage,
    function(v)
        Settings.WIDAntiDamage = v == true
        if v then
            pcall(NeutralizeDamageScripts)
            pcall(ScanAndNeutralizeHazards)
        end
        AutoSaveConfiguration()
    end,
    "WIDAntiDamage"
)

WIDCreateToggle(
    "Anti Lobby Pull",
    GamePage,
    Settings.WIDPreventLobbyPull,
    function(v)
        Settings.WIDPreventLobbyPull = v == true
        if v and IsPlayerInLobby() and not IsIntermission() then
            local targetCF, spotLabel = GetCurrentTargetCFrame()
            if targetCF then
                TeleportTo(targetCF, spotLabel)
            end
        end
        AutoSaveConfiguration()
    end,
    "WIDPreventLobbyPull"
)

WIDCreateToggle(
    "Anti AFK",
    GamePage,
    Settings.WIDAntiAFK,
    function(v)
        Settings.WIDAntiAFK = v == true
        AutoSaveConfiguration()
    end,
    "WIDAntiAFK"
)

CreateWIDSection("MAP SAFE LOCATIONS")

WIDCreateButton(
    "Teleport to Shelter",
    GamePage,
    function()
        local cf = FindInsideHouseCFrame()
        if cf then
            TeleportTo(cf, "Shelter")
        else
            CustomNotify("No shelter found on map", Color3.fromRGB(255, 100, 100), 2)
        end
    end
)

WIDCreateButton(
    "Teleport to High Ground",
    GamePage,
    function()
        local cf = FindOnTopOfHouseCFrame()
        if cf then
            TeleportTo(cf, "High Ground")
        else
            CustomNotify("High roof not found", Color3.fromRGB(255, 100, 100), 2)
        end
    end
)

WIDCreateButton(
    "Teleport to Map Center",
    GamePage,
    function()
        TeleportTo(FindMapCenterCFrame(), "Map Center")
    end
)

CreateWIDSection("SAFE SKY PLATFORM")

WIDCreateToggleWithValue(
    "Safe Sky Platform",
    GamePage,
    Settings.WIDSafePlatform,
    Settings.WIDPlatformHeight,
    function(v)
        Settings.WIDSafePlatform = v == true
        if v then
            EnsureSafePlatform(true)
        else
            ClearAllWIDWorkspaceObjects()
        end
        AutoSaveConfiguration()
    end,
    function(val)
        local newHeight = math.clamp(tonumber(val) or 380, 80, 1800)
        Settings.WIDPlatformHeight = newHeight
        if SafePlatformModel and SafePlatformModel.Parent then
            EnsureSafePlatform(true)
        end
        AutoSaveConfiguration()
    end,
    "WIDSafePlatform"
)

WIDCreateButton(
    "Teleport to Sky Platform",
    GamePage,
    function()
        TeleportToSafePlatform(true)
    end
)

WIDCreateButton(
    "Refresh Platform",
    GamePage,
    function()
        ClearAllWIDWorkspaceObjects()
        EnsureSafePlatform(true)
        TeleportToSafePlatform(true)
        CustomNotify("Platform Refreshed", Color3.fromRGB(100, 255, 100), 2)
    end
)

CreateWIDSection("PROTECTION & GODMODE")

WIDCreateToggle(
    "Anti Void",
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
    "Anti Fling",
    GamePage,
    Settings.WIDAntiFling,
    function(v)
        Settings.WIDAntiFling = v == true
        AutoSaveConfiguration()
    end,
    "WIDAntiFling"
)

WIDCreateToggle(
    "Anti Hazards",
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
    "Notify Disasters",
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
    "Air Walk (E Up / Q Down)",
    GamePage,
    Settings.WIDAirWalk,
    function(v)
        Settings.WIDAirWalk = v == true
        if not v then
            AirWalkY = nil
            if AirWalkPart then
                pcall(function() AirWalkPart:Destroy() end)
                AirWalkPart = nil
            end
        end
        AutoSaveConfiguration()
    end,
    "WIDAirWalk"
)

WIDCreateToggle(
    "Click TP",
    GamePage,
    Settings.ClickTP == true,
    function(v)
        SetShared("ClickTP", v == true)
        if v then
            CustomNotify("Hold Ctrl and Left Click to teleport", Color3.fromRGB(100, 255, 100), 3)
        end
    end,
    "ClickTP"
)

CreateWIDSection("TELEPORTS & UTILITY")

WIDCreateButton(
    "Teleport to Lobby",
    GamePage,
    function()
        TeleportTo(FindLobbyCFrame(), "Lobby")
    end
)

WIDCreateButton(
    "Teleport to Survivor",
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
    getgenv().ToxWIDGeneration = (tonumber(getgenv().ToxWIDGeneration) or 0) + 1

    for _, conn in ipairs(WIDConnections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(WIDConnections)

    ClearAllWIDWorkspaceObjects()

    local character, humanoid, root = GetCharacterState()
    if root then
        root.Anchored = false
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end

    if character then
        local ff = character:FindFirstChild("ToxDamageShield")
        if ff then
            pcall(function() ff:Destroy() end)
        end
    end

    if humanoid then
        pcall(function()
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, true)
        end)
    end
end

getgenv().ToxWIDModuleLoadedJobId = game.JobId
getgenv().ToxWIDModuleVersion = WIDModuleVersion
getgenv().ToxWIDModulePage = GamePage
