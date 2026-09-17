local BABFTPlaceId = 537413528

if game.PlaceId ~= BABFTPlaceId then
    return
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")

local Player = Players.LocalPlayer
local Settings = getgenv().Settings
local GamePage = getgenv().GamePage
local CreateToggle = getgenv().CreateToggle
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

local BABFTModuleVersion = "2026-09-17-unbox-shutdown-v4"

if getgenv().ToxBABFTModuleLoadedJobId == game.JobId
and getgenv().ToxBABFTModuleVersion == BABFTModuleVersion
and getgenv().ToxBABFTModulePage == GamePage
and not getgenv().Destroyed then
    return
end

if getgenv().ToxBABFTCleanup then
    pcall(getgenv().ToxBABFTCleanup)
end

for _, child in ipairs(GamePage:GetChildren()) do
    if child:IsA("GuiObject") then
        child:Destroy()
    end
end

Settings.BABFTAutofarm = Settings.BABFTAutofarm == true
Settings.BABFTAutofarmDelay = math.clamp(tonumber(Settings.BABFTAutofarmDelay) or 1, 0.2, 10)
Settings.BABFTAutoUnbox = Settings.BABFTAutoUnbox == true
Settings.BABFTUnboxCrate = tostring(Settings.BABFTUnboxCrate or "Common")
Settings.BABFTAutoSafeWater = Settings.BABFTAutoSafeWater == true
Settings.BABFTCollapsedSections = typeof(Settings.BABFTCollapsedSections) == "table"
    and Settings.BABFTCollapsedSections
    or {}

local ValidCrates = {
    Common = true,
    Uncommon = true,
    Rare = true,
    Epic = true,
    Legendary = true
}

if not ValidCrates[Settings.BABFTUnboxCrate] then
    Settings.BABFTUnboxCrate = "Common"
end

local BABFTConnections = {}
local BABFTCurrentSection = nil
local BABFTSections = {}
local AutofarmGeneration = 0
local AutoUnboxGeneration = 0
local ShutdownServerGeneration = 0
local ShutdownServerEnabled = false
local ShutdownOverlay = nil
local SafetyPlatform = nil
local FarmPlatform = nil
local StatusLabel = nil
local LastStatus = "Idle"

local function TrackConnection(connection)
    if connection then
        table.insert(BABFTConnections, connection)
        AddConnection(connection)
    end
    return connection
end

local function ApplySectionState(section)
    if typeof(section) ~= "table" then
        return
    end

    local collapsed = Settings.BABFTCollapsedSections[section.Key] == true

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
    if BABFTCurrentSection and object and object:IsA("GuiObject") then
        table.insert(BABFTCurrentSection.Controls, object)
        ApplySectionState(BABFTCurrentSection)
    end
    return object
end

local function BABFTCreateToggle(...)
    return TrackControl(CreateToggle(...))
end

local function BABFTCreateButton(...)
    return TrackControl(CreateButton(...))
end

local function BABFTCreateDropdown(...)
    return TrackControl(CreateDropdown(...))
end

local function CreateBABFTSection(text)
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

    table.insert(BABFTSections, section)
    BABFTCurrentSection = section

    TrackConnection(button.MouseButton1Click:Connect(function()
        Settings.BABFTCollapsedSections[key] = not Settings.BABFTCollapsedSections[key]
        ApplySectionState(section)
        AutoSaveConfiguration()
    end))

    ApplySectionState(section)
    return button
end

local function CreateNumberRow(name, defaultValue, callback)
    local box = Instance.new("Frame")
    box.Size = UDim2.new(1, -5, 0, 39)
    box.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
    box.BorderSizePixel = 0
    box.Parent = GamePage

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -90, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(240, 240, 240)
    label.TextSize = 13
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = box

    local input = Instance.new("TextBox")
    input.Size = UDim2.new(0, 55, 0, 25)
    input.Position = UDim2.new(1, -67, 0.5, -12)
    input.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
    input.BorderSizePixel = 0
    input.Text = tostring(defaultValue)
    input.TextColor3 = Color3.fromRGB(255, 255, 255)
    input.TextSize = 12
    input.Font = Enum.Font.Gotham
    input.ClearTextOnFocus = false
    input.Parent = box

    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 4)
    inputCorner.Parent = input

    TrackConnection(input.FocusLost:Connect(function()
        local value = tonumber(input.Text)

        if not value then
            input.Text = tostring(Settings.BABFTAutofarmDelay)
            return
        end

        value = callback(value)
        input.Text = tostring(value)
        AutoSaveConfiguration()
    end))

    if getgenv().RegisterToxSearchControl then
        getgenv().RegisterToxSearchControl(name, GamePage, box)
    end

    return TrackControl(box)
end

local function CreateStatusRow()
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -5, 0, 30)
    label.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
    label.BorderSizePixel = 0
    label.Text = "Status: Idle"
    label.TextColor3 = Color3.fromRGB(225, 225, 235)
    label.TextSize = 12
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextWrapped = true
    label.Parent = GamePage

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 12)
    padding.PaddingRight = UDim.new(0, 8)
    padding.Parent = label

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = label

    StatusLabel = label
    return TrackControl(label)
end

local function SetStatus(text)
    LastStatus = tostring(text or "Idle")

    if StatusLabel and StatusLabel.Parent then
        StatusLabel.Text = "Status: " .. LastStatus
    end
end

local function GetCharacterRoot()
    local character = Player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if not humanoid or humanoid.Health <= 0 or not root then
        return nil, nil, nil
    end

    return character, humanoid, root
end

local function AllowBABFTTeleport(reason)
    if getgenv().AllowToxTeleport then
        getgenv().AllowToxTeleport(2, "BABFT " .. tostring(reason or "Teleport"))
    end
end

local function MoveCharacter(cframe, reason)
    if typeof(cframe) ~= "CFrame" then
        return false
    end

    local character, _, root = GetCharacterRoot()

    if not character or not root then
        return false
    end

    AllowBABFTTeleport(reason)
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    character:PivotTo(cframe)
    return true
end

local function GetGoldValue()
    local leaderstats = Player:FindFirstChild("leaderstats")
    if not leaderstats then
        return nil
    end

    local gold = leaderstats:FindFirstChild("Gold")
        or leaderstats:FindFirstChild("gold")

    if gold and (gold:IsA("IntValue") or gold:IsA("NumberValue")) then
        return tonumber(gold.Value)
    end

    return nil
end

local function GetNormalStages()
    local boatStages = workspace:FindFirstChild("BoatStages")
    return boatStages and boatStages:FindFirstChild("NormalStages")
end

local function GetStageTarget(stage)
    if not stage then
        return nil
    end

    local target = stage:FindFirstChild("DarknessPart", true)

    if target and target:IsA("BasePart") then
        return target
    end

    local best = nil
    local bestArea = 0

    for _, object in ipairs(stage:GetDescendants()) do
        if object:IsA("BasePart") then
            local area = object.Size.X * object.Size.Z
            if area > bestArea then
                best = object
                bestArea = area
            end
        end
    end

    return best
end

local function GetOrderedStages()
    local normalStages = GetNormalStages()
    local stages = {}

    if not normalStages then
        return stages
    end

    for _, object in ipairs(normalStages:GetChildren()) do
        local number = tonumber(string.match(object.Name, "^CaveStage(%d+)$"))

        if number then
            table.insert(stages, {
                Number = number,
                Object = object
            })
        end
    end

    table.sort(stages, function(a, b)
        return a.Number < b.Number
    end)

    return stages
end

local function GetTreasureTrigger()
    local normalStages = GetNormalStages()
    local theEnd = normalStages and normalStages:FindFirstChild("TheEnd")
    local goldenChest = theEnd and theEnd:FindFirstChild("GoldenChest", true)

    if goldenChest then
        local trigger = goldenChest:FindFirstChild("Trigger", true)
            or goldenChest:FindFirstChild("Collider", true)

        if trigger and trigger:IsA("BasePart") then
            return trigger
        end

        if goldenChest:IsA("BasePart") then
            return goldenChest
        end
    end

    local worldChest = workspace:FindFirstChild("GoldenChest", true)

    if worldChest then
        local trigger = worldChest:FindFirstChild("Trigger", true)
            or worldChest:FindFirstChild("Collider", true)

        if trigger and trigger:IsA("BasePart") then
            return trigger
        end
    end

    return nil
end


local function DestroyFarmPlatform()
    if FarmPlatform and FarmPlatform.Parent then
        FarmPlatform:Destroy()
    end

    FarmPlatform = nil
end

local function PlaceFarmPlatform(cframe)
    if typeof(cframe) ~= "CFrame" then
        return
    end

    if not FarmPlatform or not FarmPlatform.Parent then
        FarmPlatform = Instance.new("Part")
        FarmPlatform.Name = "ToxBABFTFarmPlatform"
        FarmPlatform.Size = Vector3.new(16, 1, 16)
        FarmPlatform.Anchored = true
        FarmPlatform.CanCollide = true
        FarmPlatform.CanTouch = false
        FarmPlatform.CanQuery = false
        FarmPlatform.Transparency = 1
        FarmPlatform.Parent = workspace
    end

    FarmPlatform.CFrame = CFrame.new(cframe.Position - Vector3.new(0, 4.15, 0))
end

local function DestroySafetyPlatform()
    if SafetyPlatform and SafetyPlatform.Parent then
        SafetyPlatform:Destroy()
    end

    SafetyPlatform = nil
end

local function UpdateSafetyPlatform()
    if not Settings.BABFTAutoSafeWater
    or not Settings.BABFTAutofarm then
        DestroySafetyPlatform()
        return
    end

    local _, _, root = GetCharacterRoot()

    if not root then
        DestroySafetyPlatform()
        return
    end

    if not SafetyPlatform or not SafetyPlatform.Parent then
        SafetyPlatform = Instance.new("Part")
        SafetyPlatform.Name = "ToxBABFTSafeWater"
        SafetyPlatform.Size = Vector3.new(12, 1, 12)
        SafetyPlatform.Anchored = true
        SafetyPlatform.CanCollide = true
        SafetyPlatform.CanTouch = false
        SafetyPlatform.CanQuery = false
        SafetyPlatform.Transparency = 1
        SafetyPlatform.Parent = workspace
    end

    SafetyPlatform.CFrame = CFrame.new(root.Position - Vector3.new(0, 4.2, 0))
end

local function WaitForCharacter(timeout)
    local deadline = os.clock() + (tonumber(timeout) or 12)

    repeat
        local character, humanoid, root = GetCharacterRoot()

        if character and humanoid and root then
            return character, humanoid, root
        end

        task.wait(0.1)
    until os.clock() >= deadline

    return nil, nil, nil
end

local function RunAutofarmCycle(generation)
    local stages = GetOrderedStages()

    if #stages == 0 then
        SetStatus("Stages unavailable")
        task.wait(1)
        return false
    end

    local delay = math.clamp(tonumber(Settings.BABFTAutofarmDelay) or 1, 0.2, 10)

    for index, entry in ipairs(stages) do
        if generation ~= AutofarmGeneration or not Settings.BABFTAutofarm then
            return false
        end

        local _, _, root = WaitForCharacter(5)

        if not root then
            SetStatus("Waiting for character...")
            task.wait(0.5)
            return false
        end

        local target = GetStageTarget(entry.Object)

        if target then
            SetStatus("Stage " .. tostring(index) .. "/" .. tostring(#stages))
            local destination = target.CFrame + Vector3.new(0, 4, 0)
            PlaceFarmPlatform(destination)
            task.wait()
            MoveCharacter(destination, "Autofarm Stage")
            task.wait(delay)
        end
    end

    if generation ~= AutofarmGeneration or not Settings.BABFTAutofarm then
        return false
    end

    local trigger = GetTreasureTrigger()

    if not trigger then
        SetStatus("Treasure unavailable")
        task.wait(1)
        return false
    end

    local startingGold = GetGoldValue()
    local oldCharacter = Player.Character
    local collected = false

    SetStatus("Collecting treasure...")

    for attempt = 1, 3 do
        if generation ~= AutofarmGeneration or not Settings.BABFTAutofarm then
            return false
        end

        local character, humanoid, root = GetCharacterRoot()

        if character and humanoid and root then
            local destination = trigger.CFrame + Vector3.new(0, 1.5, 0)
            PlaceFarmPlatform(destination)
            task.wait()
            MoveCharacter(destination, "Autofarm Treasure")
            humanoid.Jump = true
        end

        local currentGold = GetGoldValue()

        if startingGold and currentGold and currentGold > startingGold then
            collected = true
            break
        end

        if oldCharacter and Player.Character ~= oldCharacter then
            collected = true
            break
        end

        if oldCharacter and not oldCharacter:FindFirstChildOfClass("Humanoid") then
            collected = true
            break
        end

        if attempt < 3 then
            task.wait(1)
        end
    end

    if not collected then
        local deadline = os.clock() + 12

        repeat
            if generation ~= AutofarmGeneration or not Settings.BABFTAutofarm then
                return false
            end

            local currentGold = GetGoldValue()

            if startingGold and currentGold and currentGold > startingGold then
                collected = true
                break
            end

            if oldCharacter and Player.Character ~= oldCharacter then
                collected = true
                break
            end

            if oldCharacter and not oldCharacter:FindFirstChildOfClass("Humanoid") then
                collected = true
                break
            end

            task.wait(0.15)
        until os.clock() >= deadline
    end

    if collected then
        SetStatus("Collected! Restarting...")
    else
        SetStatus("Restarting...")
    end

    WaitForCharacter(15)
    task.wait(delay)
    return true
end

local function StartAutofarm()
    AutofarmGeneration += 1
    local generation = AutofarmGeneration

    if not Settings.BABFTAutofarm then
        SetStatus("Idle")
        DestroySafetyPlatform()
        DestroyFarmPlatform()
        return
    end

    task.spawn(function()
        while Settings.BABFTAutofarm
        and generation == AutofarmGeneration
        and not getgenv().Destroyed do
            local ok = pcall(function()
                RunAutofarmCycle(generation)
            end)

            if not ok then
                SetStatus("Retrying...")
                task.wait(1)
            end
        end

        if generation == AutofarmGeneration then
            SetStatus("Idle")
            DestroyFarmPlatform()
        end
    end)
end

local function GetShopRemote(waitTime)
    local function FindIn(container)
        if not container then
            return nil
        end

        local direct = container:FindFirstChild("ItemBoughtFromShop")

        if direct
        and (direct:IsA("RemoteEvent") or direct:IsA("RemoteFunction")) then
            return direct
        end

        for _, object in ipairs(container:GetDescendants()) do
            if object.Name == "ItemBoughtFromShop"
            and (object:IsA("RemoteEvent") or object:IsA("RemoteFunction")) then
                return object
            end
        end

        return nil
    end

    local remote = FindIn(workspace)
        or FindIn(ReplicatedStorage)

    if remote or not waitTime or waitTime <= 0 then
        return remote
    end

    local deadline = tick() + waitTime

    repeat
        task.wait(0.1)
        remote = FindIn(workspace)
            or FindIn(ReplicatedStorage)
    until remote
        or tick() >= deadline
        or getgenv().Destroyed

    return remote
end

local function OpenSelectedCrate()
    local remote = GetShopRemote(2)

    if not remote then
        return false, "ItemBoughtFromShop not found"
    end

    local crate = tostring(Settings.BABFTUnboxCrate or "Common")

    if not ValidCrates[crate] then
        crate = "Common"
        Settings.BABFTUnboxCrate = crate
    end

    local chestName = crate .. " Chest"
    local ok, result = pcall(function()
        if remote:IsA("RemoteFunction") then
            return remote:InvokeServer(chestName)
        end

        remote:FireServer(chestName)
        return true
    end)

    return ok, result
end

local function StartAutoUnbox()
    AutoUnboxGeneration += 1
    local generation = AutoUnboxGeneration

    if not Settings.BABFTAutoUnbox then
        return
    end

    task.spawn(function()
        local failureNotified = false

        while Settings.BABFTAutoUnbox
        and generation == AutoUnboxGeneration
        and not getgenv().Destroyed do
            local ok, reason = OpenSelectedCrate()

            if not ok then
                if not failureNotified then
                    failureNotified = true
                    CustomNotify(
                        "Auto Unbox waiting for shop remote",
                        Color3.fromRGB(255, 180, 70)
                    )
                end
                task.wait(0.75)
            else
                failureNotified = false
                task.wait(0.65)
            end
        end
    end)
end

local function DestroyShutdownOverlay()
    if ShutdownOverlay and ShutdownOverlay.Parent then
        pcall(function()
            ShutdownOverlay:Destroy()
        end)
    end

    ShutdownOverlay = nil
end

local function FindTeamInsensitive(name)
    local wanted = string.lower(tostring(name or ""))

    for _, team in ipairs(game:GetService("Teams"):GetTeams()) do
        if string.lower(team.Name) == wanted then
            return team
        end
    end

    return nil
end

local function SetShutdownServer(enabled, silent)
    enabled = enabled == true
    ShutdownServerGeneration += 1
    local generation = ShutdownServerGeneration
    ShutdownServerEnabled = enabled

    if not enabled then
        DestroyShutdownOverlay()

        if getgenv().SyncToggleVisuals then
            pcall(function()
                getgenv().SyncToggleVisuals(
                    "BABFTShutdownServerSession",
                    false
                )
            end)
        end

        return
    end

    local remote = workspace:FindFirstChild("ChangeTeam")

    if not remote or not remote:IsA("RemoteEvent") then
        ShutdownServerEnabled = false

        if not silent then
            CustomNotify(
                "ChangeTeam remote not found",
                Color3.fromRGB(255, 100, 100)
            )
        end

        if getgenv().SyncToggleVisuals then
            pcall(function()
                getgenv().SyncToggleVisuals(
                    "BABFTShutdownServerSession",
                    false
                )
            end)
        end

        return
    end

    DestroyShutdownOverlay()

    local gui = Instance.new("ScreenGui")
    gui.Name = "ToxBABFTShutdownOverlay"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.Parent = Player:WaitForChild("PlayerGui")
    ShutdownOverlay = gui

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 250, 0, 50)
    label.Position = UDim2.new(0.5, 0, 0.5, 0)
    label.AnchorPoint = Vector2.new(0.5, 0.5)
    label.BackgroundTransparency = 1
    label.Text = "Shutdowning hold still..."
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextStrokeTransparency = 0
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = gui

    task.spawn(function()
        while ShutdownServerEnabled
        and generation == ShutdownServerGeneration
        and not getgenv().Destroyed
        and Player.Parent do
            if label.Parent then
                label.Visible = not label.Visible
            end
            task.wait(0.5)
        end
    end)

    task.spawn(function()
        local names = {
            "blue",
            "red",
            "magenta",
            "black",
            "white",
            "yellow"
        }

        while ShutdownServerEnabled
        and generation == ShutdownServerGeneration
        and not getgenv().Destroyed
        and Player.Parent do
            for _, name in ipairs(names) do
                if not ShutdownServerEnabled
                or generation ~= ShutdownServerGeneration
                or getgenv().Destroyed then
                    break
                end

                local team = FindTeamInsensitive(name)

                if team then
                    pcall(function()
                        remote:FireServer(team)
                    end)
                end

                task.wait(0.01)
            end
        end

        if generation == ShutdownServerGeneration then
            ShutdownServerEnabled = false
            DestroyShutdownOverlay()
        end
    end)
end

local ZoneDefinitions = {
    {
        Label = "WHITE ZONE",
        Names = {"WhiteZone", "White Zone"},
        Fallback = Vector3.new(-53.564, -9.9, -345.508)
    },
    {
        Label = "BLACK ZONE",
        Names = {"BlackZone", "Black Zone"},
        Fallback = Vector3.new(-328.944, -9.9, -72.122)
    },
    {
        Label = "RED ZONE",
        Names = {"Really redZone", "RedZone", "Red Zone"},
        Fallback = Vector3.new(221.835, -9.9, -68.705)
    },
    {
        Label = "YELLOW ZONE",
        Names = {"New YellerZone", "YellowZone", "Yellow Zone"},
        Fallback = Vector3.new(-328.942, -9.9, 643.877)
    },
    {
        Label = "GREEN ZONE",
        Names = {"CamoZone", "GreenZone", "Green Zone"},
        Fallback = Vector3.new(-328.967, -9.9, 285.891)
    },
    {
        Label = "BLUE ZONE",
        Names = {"Really blueZone", "BlueZone", "Blue Zone"},
        Fallback = Vector3.new(221.836, -9.9, 289.497)
    },
    {
        Label = "PURPLE ZONE",
        Names = {"MagentaZone", "PurpleZone", "Purple Zone"},
        Fallback = Vector3.new(221.835, -9.9, 647.695)
    }
}

local function GetLargestPart(object)
    if not object then
        return nil
    end

    if object:IsA("BasePart") then
        return object
    end

    local best = nil
    local bestScore = 0

    for _, descendant in ipairs(object:GetDescendants()) do
        if descendant:IsA("BasePart") then
            local score = descendant.Size.X * descendant.Size.Z

            if descendant:IsA("SpawnLocation") then
                score += 100000
            end

            if score > bestScore then
                best = descendant
                bestScore = score
            end
        end
    end

    return best
end

local function FindZoneObject(names)
    for _, name in ipairs(names) do
        local direct = workspace:FindFirstChild(name)

        if direct then
            return direct
        end
    end

    for _, object in ipairs(workspace:GetChildren()) do
        local normalized = string.lower(string.gsub(object.Name, "[^%w]", ""))

        for _, name in ipairs(names) do
            local wanted = string.lower(string.gsub(name, "[^%w]", ""))

            if normalized == wanted then
                return object
            end
        end
    end

    return nil
end

local function TeleportToZone(definition)
    local object = FindZoneObject(definition.Names)
    local part = GetLargestPart(object)
    local targetCFrame = nil

    if part then
        targetCFrame = part.CFrame + Vector3.new(0, math.max(4, part.Size.Y * 0.5 + 3), 0)
    else
        targetCFrame = CFrame.new(definition.Fallback + Vector3.new(0, 6, 0))
    end

    if getgenv().ToxSafeTeleportToCFrame then
        return getgenv().ToxSafeTeleportToCFrame(
            targetCFrame,
            false,
            "BABFT " .. definition.Label
        )
    end

    return MoveCharacter(targetCFrame, definition.Label)
end

TrackConnection(RunService.Heartbeat:Connect(function()
    UpdateSafetyPlatform()
end))

TrackConnection(GuiService.ErrorMessageChanged:Connect(function(message)
    if ShutdownServerEnabled
    and tostring(message or "") ~= "" then
        SetShutdownServer(false, true)
    end
end))

TrackConnection(Players.PlayerRemoving:Connect(function(leavingPlayer)
    if leavingPlayer == Player
    and ShutdownServerEnabled then
        SetShutdownServer(false, true)
    end
end))

CreateBABFTSection("AUTOFARM")

BABFTCreateToggle(
    "Autofarm",
    GamePage,
    Settings.BABFTAutofarm,
    function(value)
        Settings.BABFTAutofarm = value == true
        StartAutofarm()
        AutoSaveConfiguration()
    end,
    "BABFTAutofarm"
)

CreateNumberRow(
    "Autofarm Delay",
    Settings.BABFTAutofarmDelay,
    function(value)
        Settings.BABFTAutofarmDelay = math.clamp(tonumber(value) or 1, 0.2, 10)
        return Settings.BABFTAutofarmDelay
    end
)

BABFTCreateToggle(
    "Auto Unbox",
    GamePage,
    Settings.BABFTAutoUnbox,
    function(value)
        Settings.BABFTAutoUnbox = value == true
        StartAutoUnbox()
        AutoSaveConfiguration()
    end,
    "BABFTAutoUnbox"
)

BABFTCreateDropdown(
    "Unbox Crate",
    {"Common", "Uncommon", "Rare", "Epic", "Legendary"},
    GamePage,
    Settings.BABFTUnboxCrate,
    function(value)
        Settings.BABFTUnboxCrate = tostring(value)
        AutoSaveConfiguration()
    end
)

BABFTCreateToggle(
    "Auto Safe Water",
    GamePage,
    Settings.BABFTAutoSafeWater,
    function(value)
        Settings.BABFTAutoSafeWater = value == true

        if not value then
            DestroySafetyPlatform()
        end

        AutoSaveConfiguration()
    end,
    "BABFTAutoSafeWater"
)

CreateStatusRow()
SetStatus(Settings.BABFTAutofarm and "Starting..." or "Idle")

CreateBABFTSection("TELEPORTS")

for _, definition in ipairs(ZoneDefinitions) do
    BABFTCreateButton(definition.Label, GamePage, function()
        TeleportToZone(definition)
    end)
end

CreateBABFTSection("SERVER")

BABFTCreateToggle(
    "Shutdown Server",
    GamePage,
    false,
    function(value)
        SetShutdownServer(value == true, false)
    end,
    "BABFTShutdownServerSession"
)

if Settings.BABFTAutofarm then
    StartAutofarm()
end

if Settings.BABFTAutoUnbox then
    StartAutoUnbox()
end

getgenv().ToxBABFTCleanup = function()
    AutofarmGeneration += 1
    AutoUnboxGeneration += 1
    SetShutdownServer(false, true)
    DestroySafetyPlatform()
    DestroyFarmPlatform()

    for _, connection in ipairs(BABFTConnections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    table.clear(BABFTConnections)
end

getgenv().ToxBABFTModuleLoadedJobId = game.JobId
getgenv().ToxBABFTModuleVersion = BABFTModuleVersion
getgenv().ToxBABFTModulePage = GamePage
