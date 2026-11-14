local FTFPlaceId = 893973440

if game.PlaceId ~= FTFPlaceId then
    return
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local PathfindingService = game:GetService("PathfindingService")

local Player = Players.LocalPlayer
local Settings = getgenv().Settings
local GamePage = getgenv().GamePage
local CreateToggle = getgenv().CreateToggle
local CreateToggleWithValue = getgenv().CreateToggleWithValue
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
or not CreateToggleWithValue
or not CreateButton
or not CreateDropdown then
    return
end

local FTFModuleVersion = "2026-09-14-ftf-initial-safe-1"

if getgenv().ToxFTFModuleLoadedJobId == game.JobId
and getgenv().ToxFTFModuleVersion == FTFModuleVersion
and getgenv().ToxFTFModulePage == GamePage
and not getgenv().Destroyed then
    return
end

if getgenv().ToxFTFCleanup then
    pcall(getgenv().ToxFTFCleanup)
end

for _, child in ipairs(GamePage:GetChildren()) do
    if child:IsA("GuiObject") then
        child:Destroy()
    end
end

Settings.FTFBeastVisuals = Settings.FTFBeastVisuals == true
Settings.FTFSurvivorVisuals = Settings.FTFSurvivorVisuals == true
Settings.FTFComputerChams = Settings.FTFComputerChams == true
Settings.FTFNoFog = Settings.FTFNoFog == true
Settings.FTFCrawlSpeed = Settings.FTFCrawlSpeed == true
Settings.FTFCrawlSpeedValue = tonumber(Settings.FTFCrawlSpeedValue) or 8
Settings.FTFNoRagdoll = Settings.FTFNoRagdoll == true
Settings.FTFAutoEscape = false   -- option removed
Settings.FTFNoHackFail = Settings.FTFNoHackFail == true
Settings.FTFNoFailMethod = tostring(Settings.FTFNoFailMethod or "Smart")
Settings.FTFUnlockCamera = Settings.FTFUnlockCamera == true
Settings.FTFRemoveJumpFatigue = Settings.FTFRemoveJumpFatigue == true
Settings.FTFEnableCrawling = Settings.FTFEnableCrawling == true
Settings.FTFNoHitStun = Settings.FTFNoHitStun == true
Settings.FTFHitAura = Settings.FTFHitAura == true
Settings.FTFNotifyUnragdolling = Settings.FTFNotifyUnragdolling == true
Settings.FTFNotifyPercent = math.clamp(tonumber(Settings.FTFNotifyPercent) or 80, 1, 100)
Settings.FTFCollapsedSections =
    typeof(Settings.FTFCollapsedSections) == "table"
    and Settings.FTFCollapsedSections
    or {}

local FTFConnections = {}
local FTFVisualFolder = Instance.new("Folder")
FTFVisualFolder.Name = "ToxFTFVisuals"
FTFVisualFolder.Parent = workspace

local FTFCurrentSection = nil
local FTFSections = {}
local CharacterRagdollStarted = nil
local BeastHitLast = 0
local LastVisualRefresh = 0
local LastComputerRefresh = 0
local LastFogApply = 0
local LastCrawlCheck = 0
local LastStatScan = 0
local CrawlingCached = false
local AutoEscapeGeneration = 0
local ComputerHighlights = setmetatable({}, {__mode = "k"})
local OriginalLighting = {
    FogStart = Lighting.FogStart,
    FogEnd = Lighting.FogEnd,
    FogColor = Lighting.FogColor
}

local function TrackConnection(connection)
    if connection then
        table.insert(FTFConnections, connection)
        AddConnection(connection)
    end
    return connection
end

local function ApplySectionState(section)
    if typeof(section) ~= "table" then
        return
    end

    local collapsed = Settings.FTFCollapsedSections[section.Key] == true

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
    if FTFCurrentSection
    and object
    and object:IsA("GuiObject") then
        table.insert(FTFCurrentSection.Controls, object)
        ApplySectionState(FTFCurrentSection)
    end
    return object
end

local function FTFCreateToggle(...)
    return TrackControl(CreateToggle(...))
end

local function FTFCreateToggleWithValue(...)
    return TrackControl(CreateToggleWithValue(...))
end

local function FTFCreateButton(...)
    return TrackControl(CreateButton(...))
end

local function FTFCreateDropdown(...)
    return TrackControl(CreateDropdown(...))
end

local function CreateFTFSection(text)
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

    table.insert(FTFSections, section)
    FTFCurrentSection = section

    button.MouseButton1Click:Connect(function()
        Settings.FTFCollapsedSections[key] =
            not Settings.FTFCollapsedSections[key]
        ApplySectionState(section)
        AutoSaveConfiguration()
    end)

    ApplySectionState(section)
    return button
end

local function CreateDisabledRow(name)
    local button = FTFCreateButton(name .. " [Disabled]", GamePage, function()
        CustomNotify(
            name .. " is disabled",
            Color3.fromRGB(255, 180, 70),
            3
        )
    end)

    if button then
        button.AutoButtonColor = false
        button.TextColor3 = Color3.fromRGB(135, 135, 145)
        button.BackgroundColor3 = Color3.fromRGB(16, 16, 23)
    end

    return button
end

local function NormalizeName(value)
    return string.lower(tostring(value or "")):gsub("[^%w]", "")
end

local function GetTempStats(player)
    player = player or Player
    return player:FindFirstChild("TempPlayerStatsModule")
end

local function ReadBoolStat(player, names)
    local stats = GetTempStats(player)
    if not stats then
        return nil
    end

    for _, name in ipairs(names) do
        local object = stats:FindFirstChild(name, true)
        if object and object:IsA("BoolValue") then
            return object.Value, object
        end
    end

    return nil
end

local function IsBeast(player)
    local value = ReadBoolStat(player, {"IsBeast"})
    return value == true
end

local function IsAlivePlayer(player)
    local character = player and player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    return humanoid and humanoid.Health > 0 and root ~= nil
end

local function GetRemoteEvent()
    local direct = ReplicatedStorage:FindFirstChild("RemoteEvent")
    if direct and direct:IsA("RemoteEvent") then
        return direct
    end

    for _, object in ipairs(ReplicatedStorage:GetDescendants()) do
        if object:IsA("RemoteEvent")
        and NormalizeName(object.Name) == "remoteevent" then
            return object
        end
    end

    return nil
end

local function DestroyVisualsByPrefix(prefix)
    for _, object in ipairs(FTFVisualFolder:GetChildren()) do
        if string.sub(object.Name, 1, #prefix) == prefix then
            object:Destroy()
        end
    end
end

local function EnsurePlayerHighlight(player, prefix, color)
    if player == Player or not player.Character then
        return
    end

    local name = prefix .. tostring(player.UserId)
    local existing = FTFVisualFolder:FindFirstChild(name)

    if existing and existing:IsA("Highlight") then
        existing.Adornee = player.Character
        existing.FillColor = color
        existing.OutlineColor = color
        return existing
    end

    if existing then
        existing:Destroy()
    end

    local highlight = Instance.new("Highlight")
    highlight.Name = name
    highlight.Adornee = player.Character
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillColor = color
    highlight.OutlineColor = color
    highlight.FillTransparency = 0.68
    highlight.OutlineTransparency = 0.05
    highlight.Parent = FTFVisualFolder
    return highlight
end

local function RefreshPlayerVisuals()
    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= Player and other.Character then
            if IsBeast(other) then
                if Settings.FTFBeastVisuals then
                    EnsurePlayerHighlight(
                        other,
                        "Beast_",
                        Color3.fromRGB(235, 65, 75)
                    )
                else
                    local old = FTFVisualFolder:FindFirstChild("Beast_" .. tostring(other.UserId))
                    if old then old:Destroy() end
                end

                local oldSurvivor = FTFVisualFolder:FindFirstChild("Survivor_" .. tostring(other.UserId))
                if oldSurvivor then oldSurvivor:Destroy() end
            else
                if Settings.FTFSurvivorVisuals then
                    EnsurePlayerHighlight(
                        other,
                        "Survivor_",
                        Color3.fromRGB(75, 220, 115)
                    )
                else
                    local old = FTFVisualFolder:FindFirstChild("Survivor_" .. tostring(other.UserId))
                    if old then old:Destroy() end
                end

                local oldBeast = FTFVisualFolder:FindFirstChild("Beast_" .. tostring(other.UserId))
                if oldBeast then oldBeast:Destroy() end
            end
        end
    end
end

local function GetCurrentMap()
    local currentMap = ReplicatedStorage:FindFirstChild("CurrentMap")

    if currentMap and currentMap:IsA("StringValue") and currentMap.Value ~= "" then
        return workspace:FindFirstChild(currentMap.Value)
    end

    for _, object in ipairs(workspace:GetChildren()) do
        if object:IsA("Model") then
            for _, child in ipairs(object:GetChildren()) do
                if child.Name == "ComputerTable" then
                    return object
                end
            end
        end
    end

    return workspace
end

local function GetComputerColor(computer)
    local screen = computer:FindFirstChild("Screen", true)
    if screen and screen:IsA("BasePart") then
        return screen.Color
    end
    return Color3.fromRGB(70, 170, 255)
end

local function RefreshComputerChams()
    if not Settings.FTFComputerChams then
        for computer, highlight in pairs(ComputerHighlights) do
            if highlight then
                highlight:Destroy()
            end
            ComputerHighlights[computer] = nil
        end
        return
    end

    local map = GetCurrentMap()
    local found = {}

    for _, object in ipairs(map:GetDescendants()) do
        if object:IsA("Model") and object.Name == "ComputerTable" then
            found[object] = true
            local highlight = ComputerHighlights[object]

            if not highlight or not highlight.Parent then
                highlight = Instance.new("Highlight")
                highlight.Name = "Computer_Cham"
                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                highlight.FillTransparency = 0.62
                highlight.OutlineTransparency = 0.05
                highlight.Parent = FTFVisualFolder
                ComputerHighlights[object] = highlight
            end

            highlight.Adornee = object
            local color = GetComputerColor(object)
            highlight.FillColor = color
            highlight.OutlineColor = color
        end
    end

    for computer, highlight in pairs(ComputerHighlights) do
        if not found[computer] or not computer.Parent then
            if highlight then
                highlight:Destroy()
            end
            ComputerHighlights[computer] = nil
        end
    end
end

-- FTF maps use an Atmosphere: while one exists, Lighting.FogStart/FogEnd do nothing,
-- that's why No Fog seemed broken. Thin the Atmosphere too (restored when turned off).
local AtmosphereDefaults = setmetatable({}, { __mode = "k" })
local function ApplyNoFog(enabled)
    if enabled then
        Lighting.FogStart = 1000000
        Lighting.FogEnd = 10000000
        for _, object in ipairs(Lighting:GetChildren()) do
            if object:IsA("Atmosphere") then
                if not AtmosphereDefaults[object] then
                    AtmosphereDefaults[object] = { Density = object.Density, Haze = object.Haze, Offset = object.Offset }
                end
                object.Density = 0
                object.Haze = 0
                object.Offset = 0
            end
        end
    else
        Lighting.FogStart = OriginalLighting.FogStart
        Lighting.FogEnd = OriginalLighting.FogEnd
        Lighting.FogColor = OriginalLighting.FogColor
        for object, saved in pairs(AtmosphereDefaults) do
            if object.Parent then
                pcall(function()
                    object.Density = saved.Density
                    object.Haze = saved.Haze
                    object.Offset = saved.Offset
                end)
            end
            AtmosphereDefaults[object] = nil
        end
    end
end

local function IsLikelyCrawling()
    local stats = GetTempStats(Player)

    if stats then
        for _, object in ipairs(stats:GetDescendants()) do
            if object:IsA("BoolValue") then
                local name = NormalizeName(object.Name)
                if name ~= "disablecrawl"
                and string.find(name, "crawl", 1, true)
                and object.Value == true then
                    return true
                end
            end
        end
    end

    local character = Player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if humanoid then
        -- (the old "WalkSpeed <= 9" guess also matched the speed WE set, so you stayed
        -- slow after standing up; only the hip height is used now)
        if humanoid.HipHeight < 1.15 then
            return true
        end
    end

    return false
end

local function RecoverFromRagdoll(forceFast)
    local character = Player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if not humanoid or humanoid.Health <= 0 then
        return
    end

    humanoid.PlatformStand = false
    humanoid.Sit = false

    pcall(function()
        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    end)

    local stats = GetTempStats(Player)
    if stats then
        for _, object in ipairs(stats:GetDescendants()) do
            if object:IsA("BoolValue") then
                local name = NormalizeName(object.Name)
                if (name == "ragdoll" or name == "ragdolled" or string.find(name, "ragdoll", 1, true))
                and object.Value == true then
                    pcall(function()
                        object.Value = false
                    end)
                end
            elseif object:IsA("NumberValue") then
                local name = NormalizeName(object.Name)
                if string.find(name, "ragdoll", 1, true)
                and (string.find(name, "time", 1, true) or string.find(name, "timer", 1, true)) then
                    pcall(function()
                        object.Value = forceFast and 0 or math.min(object.Value, 0.15)
                    end)
                end
            end
        end
    end
end

local function IsRagdollState(humanoid)
    if not humanoid then
        return false
    end

    local state = humanoid:GetState()
    return humanoid.PlatformStand
        or state == Enum.HumanoidStateType.Physics
        or state == Enum.HumanoidStateType.FallingDown
        or state == Enum.HumanoidStateType.Ragdoll
        or state == Enum.HumanoidStateType.PlatformStanding
end

local function SetEnableCrawling()
    if not Settings.FTFEnableCrawling or not IsBeast(Player) then
        return
    end

    local stats = GetTempStats(Player)
    local disableCrawl = stats and stats:FindFirstChild("DisableCrawl", true)

    if disableCrawl and disableCrawl:IsA("BoolValue") then
        pcall(function()
            disableCrawl.Value = false
        end)
    end
end

local function RemoveJumpFatigue()
    if not Settings.FTFRemoveJumpFatigue or not IsBeast(Player) then
        return
    end

    local containers = {GetTempStats(Player), Player.Character}

    for _, container in ipairs(containers) do
        if container then
            for _, object in ipairs(container:GetDescendants()) do
                local name = NormalizeName(object.Name)

                if string.find(name, "jump", 1, true)
                and (
                    string.find(name, "fatigue", 1, true)
                    or string.find(name, "cooldown", 1, true)
                ) then
                    if object:IsA("BoolValue") then
                        pcall(function() object.Value = false end)
                    elseif object:IsA("NumberValue") or object:IsA("IntValue") then
                        pcall(function() object.Value = 0 end)
                    end
                end
            end
        end
    end
end

local function ApplyUnlockedCamera()
    if not Settings.FTFUnlockCamera then
        return
    end

    local character = Player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if humanoid then
        workspace.CurrentCamera.CameraSubject = humanoid
        workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
    end

    Player.CameraMode = Enum.CameraMode.Classic
    Player.CameraMinZoomDistance = 0.5
    Player.CameraMaxZoomDistance = 500
end

local function GetClosestSurvivor(maxDistance)
    local character = Player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if not root then
        return nil, math.huge
    end

    local best = nil
    local bestDistance = tonumber(maxDistance) or 8

    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= Player
        and not IsBeast(other)
        and IsAlivePlayer(other) then
            local otherRoot = other.Character:FindFirstChild("HumanoidRootPart")
            local distance = (root.Position - otherRoot.Position).Magnitude

            if distance <= bestDistance then
                best = other
                bestDistance = distance
            end
        end
    end

    return best, bestDistance
end

local function RunHitAura()
    if not Settings.FTFHitAura or not IsBeast(Player) then
        return
    end

    if os.clock() - BeastHitLast < 0.34 then
        return
    end

    local target = GetClosestSurvivor(8)
    if not target then
        return
    end

    local remote = GetRemoteEvent()
    if not remote then
        return
    end

    BeastHitLast = os.clock()
    pcall(function()
        remote:FireServer("Input", "Action", true)
    end)
end

local function ApplyNoHitStun()
    if not Settings.FTFNoHitStun or not IsBeast(Player) then
        return
    end

    local character = Player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if humanoid and IsRagdollState(humanoid) then
        task.delay(0.12, function()
            if Settings.FTFNoHitStun and IsBeast(Player) then
                RecoverFromRagdoll(true)
            end
        end)
    end

    local stats = GetTempStats(Player)
    if stats then
        for _, object in ipairs(stats:GetDescendants()) do
            local name = NormalizeName(object.Name)
            if string.find(name, "stun", 1, true) then
                if object:IsA("BoolValue") and object.Value then
                    pcall(function() object.Value = false end)
                elseif (object:IsA("NumberValue") or object:IsA("IntValue")) and object.Value > 0 then
                    pcall(function() object.Value = 0 end)
                end
            end
        end
    end
end

local function GetComputersLeft()
    local value = ReplicatedStorage:FindFirstChild("ComputersLeft")
    if value and (value:IsA("IntValue") or value:IsA("NumberValue")) then
        return tonumber(value.Value)
    end
    return nil
end

local function FindNearestExitTarget()
    local character = Player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then
        return nil
    end

    local best = nil
    local bestDistance = math.huge

    for _, object in ipairs(workspace:GetDescendants()) do
        if object:IsA("BasePart") then
            local name = NormalizeName(object.Name)
            local parentName = NormalizeName(object.Parent and object.Parent.Name or "")

            if name == "exitarea"
            or name == "exittrigger"
            or string.find(parentName, "exitdoor", 1, true) then
                local distance = (root.Position - object.Position).Magnitude
                if distance < bestDistance then
                    best = object
                    bestDistance = distance
                end
            end
        end
    end

    return best
end

local function WalkToPosition(position, generation)
    local character = Player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if not humanoid or not root or typeof(position) ~= "Vector3" then
        return false
    end

    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        WaypointSpacing = 4
    })

    local ok = pcall(function()
        path:ComputeAsync(root.Position, position)
    end)

    if not ok or path.Status ~= Enum.PathStatus.Success then
        humanoid:MoveTo(position)
        humanoid.MoveToFinished:Wait()
        return Settings.FTFAutoEscape and generation == AutoEscapeGeneration
    end

    for _, waypoint in ipairs(path:GetWaypoints()) do
        if not Settings.FTFAutoEscape or generation ~= AutoEscapeGeneration then
            humanoid:Move(Vector3.zero)
            return false
        end

        if waypoint.Action == Enum.PathWaypointAction.Jump then
            humanoid.Jump = true
        end

        humanoid:MoveTo(waypoint.Position)
        local reached = humanoid.MoveToFinished:Wait()
        if not reached then
            return false
        end
    end

    return true
end

local function StartAutoEscape()
    AutoEscapeGeneration += 1
    local generation = AutoEscapeGeneration

    if not Settings.FTFAutoEscape then
        return
    end

    task.spawn(function()
        while Settings.FTFAutoEscape
        and generation == AutoEscapeGeneration
        and game.PlaceId == FTFPlaceId do
            local computersLeft = GetComputersLeft()

            if computersLeft ~= nil and computersLeft <= 0 then
                local exitTarget = FindNearestExitTarget()

                if exitTarget then
                    WalkToPosition(exitTarget.Position, generation)

                    local remote = GetRemoteEvent()
                    local started = os.clock()

                    while Settings.FTFAutoEscape
                    and generation == AutoEscapeGeneration
                    and remote
                    and os.clock() - started < 12 do
                        local character = Player.Character
                        local root = character and character:FindFirstChild("HumanoidRootPart")
                        if not root then
                            break
                        end

                        if (root.Position - exitTarget.Position).Magnitude <= 14 then
                            pcall(function()
                                remote:FireServer("Input", "Action", true)
                            end)
                        else
                            break
                        end

                        task.wait(0.45)
                    end
                end
            end

            task.wait(0.75)
        end
    end)
end

local function InstallNoHackFailHook()
    if getgenv().ToxFTFNoHackHookInstalled then
        return
    end

    if not hookmetamethod or not getnamecallmethod or not newcclosure then
        return
    end

    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local args = {...}
        local method = getnamecallmethod()
        local liveSettings = getgenv().Settings

        if game.PlaceId == FTFPlaceId
        and liveSettings
        and liveSettings.FTFNoHackFail
        and method == "FireServer"
        and tostring(self.Name) == "RemoteEvent"
        and args[1] == "SetPlayerMinigameResult"
        and args[2] == false then
            local mode = tostring(liveSettings.FTFNoFailMethod or "Smart")

            if mode == "Legit" then
                local remote = self
                task.delay(math.random(5, 12) / 100, function()
                    local currentSettings = getgenv().Settings

                    if currentSettings
                    and currentSettings.FTFNoHackFail
                    and remote
                    and remote.Parent then
                        pcall(function()
                            remote:FireServer("SetPlayerMinigameResult", true)
                        end)
                    end
                end)
                return nil
            end

            args[2] = true
            return oldNamecall(self, table.unpack(args))
        end

        return oldNamecall(self, ...)
    end))

    getgenv().ToxFTFNoHackHookInstalled = true
end

local function SetupUnragdollNotifications(player)
    if player == Player then
        return
    end

    local function bindCharacter(character)
        local humanoid = character:FindFirstChildOfClass("Humanoid")
            or character:WaitForChild("Humanoid", 4)

        if not humanoid then
            return
        end

        local wasRagdolled = IsRagdollState(humanoid)

        TrackConnection(humanoid.StateChanged:Connect(function(_, newState)
            local nowRagdolled = humanoid.PlatformStand
                or newState == Enum.HumanoidStateType.Physics
                or newState == Enum.HumanoidStateType.FallingDown
                or newState == Enum.HumanoidStateType.Ragdoll
                or newState == Enum.HumanoidStateType.PlatformStanding

            if wasRagdolled and not nowRagdolled and Settings.FTFNotifyUnragdolling then
                CustomNotify(
                    player.DisplayName .. " is getting up",
                    Color3.fromRGB(255, 210, 90),
                    2.5
                )
            end

            wasRagdolled = nowRagdolled
        end))
    end

    if player.Character then
        task.spawn(bindCharacter, player.Character)
    end

    TrackConnection(player.CharacterAdded:Connect(bindCharacter))
end

-- Some executors don't support (or block) hookmetamethod: if it errors here, the whole
-- FTF page used to stop loading and show no options. Now it just skips No Hack Fail.
-- The hook catches EVERY method call of the game. On some executors that breaks the
-- game's own scripts (WaitForChild returns nil -> "Attempted to call require with
-- invalid argument(s)") and the FTF page. So it is only installed when No Hack Fail is ON.
if Settings.FTFNoHackFail then
    local okHook, hookErr = pcall(InstallNoHackFailHook)
    if not okHook then
        warn("[ToxHub FTF] No Hack Fail hook unavailable: " .. tostring(hookErr))
    end
end

for _, other in ipairs(Players:GetPlayers()) do
    SetupUnragdollNotifications(other)
end

TrackConnection(Players.PlayerAdded:Connect(function(other)
    SetupUnragdollNotifications(other)
end))

TrackConnection(Players.PlayerRemoving:Connect(function(other)
    local beast = FTFVisualFolder:FindFirstChild("Beast_" .. tostring(other.UserId))
    local survivor = FTFVisualFolder:FindFirstChild("Survivor_" .. tostring(other.UserId))
    if beast then beast:Destroy() end
    if survivor then survivor:Destroy() end
end))

TrackConnection(RunService.Heartbeat:Connect(function()
    local now = os.clock()

    if now - LastVisualRefresh >= 0.20 then
        LastVisualRefresh = now
        RefreshPlayerVisuals()
    end

    if Settings.FTFComputerChams and now - LastComputerRefresh >= 1.5 then
        LastComputerRefresh = now
        RefreshComputerChams()
    end

    if Settings.FTFNoFog and now - LastFogApply >= 1 then
        LastFogApply = now
        ApplyNoFog(true)
    end

    local character = Player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if humanoid and Settings.FTFCrawlSpeed then
        if now - LastCrawlCheck >= 0.25 then
            LastCrawlCheck = now
            CrawlingCached = IsLikelyCrawling()
        end
        if CrawlingCached then
            humanoid.WalkSpeed = math.clamp(tonumber(Settings.FTFCrawlSpeedValue) or 8, 1, 30)
        end
    end

    if humanoid and Settings.FTFNoRagdoll then
        if IsRagdollState(humanoid) then
            CharacterRagdollStarted = CharacterRagdollStarted or os.clock()

            if os.clock() - CharacterRagdollStarted >= 0.45 then
                RecoverFromRagdoll(false)
            end
        else
            CharacterRagdollStarted = nil
        end
    else
        CharacterRagdollStarted = nil
    end

    -- these scan the player's stats/character: 4x per second is plenty (was every frame -> lag)
    if now - LastStatScan >= 0.25 then
        LastStatScan = now
        SetEnableCrawling()
        RemoveJumpFatigue()
        ApplyNoHitStun()
    end
    ApplyUnlockedCamera()
    RunHitAura()
end))

-- ===================== VISUALS =====================
CreateFTFSection("VISUALS")

FTFCreateToggle(
    "Beast Visuals",
    GamePage,
    Settings.FTFBeastVisuals,
    function(value)
        Settings.FTFBeastVisuals = value == true
        if not value then
            DestroyVisualsByPrefix("Beast_")
        end
        AutoSaveConfiguration()
    end,
    "FTFBeastVisuals"
)

FTFCreateToggle(
    "Survivor Visuals",
    GamePage,
    Settings.FTFSurvivorVisuals,
    function(value)
        Settings.FTFSurvivorVisuals = value == true
        if not value then
            DestroyVisualsByPrefix("Survivor_")
        end
        AutoSaveConfiguration()
    end,
    "FTFSurvivorVisuals"
)

FTFCreateToggle(
    "Computer Chams",
    GamePage,
    Settings.FTFComputerChams,
    function(value)
        Settings.FTFComputerChams = value == true
        RefreshComputerChams()
        AutoSaveConfiguration()
    end,
    "FTFComputerChams"
)

FTFCreateToggle(
    "No Fog",
    GamePage,
    Settings.FTFNoFog,
    function(value)
        Settings.FTFNoFog = value == true
        ApplyNoFog(value)
        AutoSaveConfiguration()
    end,
    "FTFNoFog"
)

FTFCreateToggle(
    "Unlock Camera",
    GamePage,
    Settings.FTFUnlockCamera,
    function(value)
        Settings.FTFUnlockCamera = value == true
        if value then
            ApplyUnlockedCamera()
        end
        AutoSaveConfiguration()
    end,
    "FTFUnlockCamera"
)

-- ===================== SURVIVOR =====================
CreateFTFSection("SURVIVOR")

local function OnCrawlSpeedToggle(value)
    Settings.FTFCrawlSpeed = value == true
    AutoSaveConfiguration()
end
local function OnCrawlSpeedValue(value)
    Settings.FTFCrawlSpeedValue = math.clamp(tonumber(value) or 8, 1, 30)
    AutoSaveConfiguration()
end
local createToggleWithSlider = getgenv().CreateToggleWithSlider
if type(createToggleWithSlider) == "function" then
    TrackControl(createToggleWithSlider("Crawl Speed", GamePage, 1, 30, Settings.FTFCrawlSpeed,
        Settings.FTFCrawlSpeedValue, "", OnCrawlSpeedToggle, OnCrawlSpeedValue, "FTFCrawlSpeed"))
else
    FTFCreateToggleWithValue("Crawl Speed", GamePage, Settings.FTFCrawlSpeed, Settings.FTFCrawlSpeedValue,
        OnCrawlSpeedToggle, OnCrawlSpeedValue, "FTFCrawlSpeed")
end

FTFCreateToggle(
    "No Ragdoll",
    GamePage,
    Settings.FTFNoRagdoll,
    function(value)
        Settings.FTFNoRagdoll = value == true
        CharacterRagdollStarted = nil
        AutoSaveConfiguration()
    end,
    "FTFNoRagdoll"
)

local function OnNoHackFail(value)
    Settings.FTFNoHackFail = value == true
    if Settings.FTFNoHackFail then
        local okHook, hookErr = pcall(InstallNoHackFailHook)
        if not okHook then
            warn("[ToxHub FTF] No Hack Fail hook unavailable: " .. tostring(hookErr))
        end
    end
    AutoSaveConfiguration()
end
local function OnNoFailMethod(value)
    Settings.FTFNoFailMethod = tostring(value)
    AutoSaveConfiguration()
end
local createToggleWithChoice = getgenv().CreateToggleWithChoice
if type(createToggleWithChoice) == "function" then
    -- toggle + method (Smart / Legit) in the same option
    TrackControl(createToggleWithChoice("No Hack Fail", GamePage, {"Smart", "Legit"}, Settings.FTFNoHackFail,
        Settings.FTFNoFailMethod, OnNoHackFail, OnNoFailMethod, "FTFNoHackFail"))
else
    FTFCreateToggle("No Hack Fail", GamePage, Settings.FTFNoHackFail, OnNoHackFail, "FTFNoHackFail")
    FTFCreateDropdown("No Fail Method", {"Smart", "Legit"}, GamePage, Settings.FTFNoFailMethod, OnNoFailMethod)
end

-- ===================== BEAST =====================
CreateFTFSection("BEAST")

FTFCreateToggle(
    "Remove Jump Fatigue",
    GamePage,
    Settings.FTFRemoveJumpFatigue,
    function(value)
        Settings.FTFRemoveJumpFatigue = value == true
        AutoSaveConfiguration()
    end,
    "FTFRemoveJumpFatigue"
)

FTFCreateToggle(
    "Enable Crawling",
    GamePage,
    Settings.FTFEnableCrawling,
    function(value)
        Settings.FTFEnableCrawling = value == true
        SetEnableCrawling()
        AutoSaveConfiguration()
    end,
    "FTFEnableCrawling"
)

FTFCreateToggle(
    "No Hit Stun",
    GamePage,
    Settings.FTFNoHitStun,
    function(value)
        Settings.FTFNoHitStun = value == true
        AutoSaveConfiguration()
    end,
    "FTFNoHitStun"
)

FTFCreateToggle(
    "Hit Aura",
    GamePage,
    Settings.FTFHitAura,
    function(value)
        Settings.FTFHitAura = value == true
        AutoSaveConfiguration()
    end,
    "FTFHitAura"
)

-- ===================== ALERTS =====================
CreateFTFSection("ALERTS")

-- one option: toggle + the % (the old "Notify when % done" row had a switch that did nothing)
local function OnNotifyUnragdolling(value)
    Settings.FTFNotifyUnragdolling = value == true
    AutoSaveConfiguration()
end
local function OnNotifyPercent(value)
    Settings.FTFNotifyPercent = math.clamp(tonumber(value) or 80, 1, 100)
    AutoSaveConfiguration()
end
if type(createToggleWithSlider) == "function" then
    TrackControl(createToggleWithSlider("Notify Unragdolling", GamePage, 1, 100, Settings.FTFNotifyUnragdolling,
        Settings.FTFNotifyPercent, "%", OnNotifyUnragdolling, OnNotifyPercent, "FTFNotifyUnragdolling"))
else
    FTFCreateToggleWithValue("Notify Unragdolling", GamePage, Settings.FTFNotifyUnragdolling, Settings.FTFNotifyPercent,
        OnNotifyUnragdolling, OnNotifyPercent, "FTFNotifyUnragdolling")
end

ApplyNoFog(Settings.FTFNoFog)
RefreshPlayerVisuals()
RefreshComputerChams()


getgenv().ToxFTFCleanup = function()
    AutoEscapeGeneration += 1
    ApplyNoFog(false)

    for _, connection in ipairs(FTFConnections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    table.clear(FTFConnections)

    if FTFVisualFolder and FTFVisualFolder.Parent then
        FTFVisualFolder:Destroy()
    end
end

getgenv().ToxFTFModuleLoadedJobId = game.JobId
getgenv().ToxFTFModuleVersion = FTFModuleVersion
getgenv().ToxFTFModulePage = GamePage
