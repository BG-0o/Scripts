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
local AddConnection = getgenv().AddConnection or function(connection)
    return connection
end

if not Settings
or not GamePage
or not CreateToggle
or not CreateToggleWithValue
or not CreateButton then
    return
end

local LBBModuleVersion = "2026-09-14-lbb-bases-blocks-fix-2"

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
local LBBConnections = {}
local PlayerBaseCache = setmetatable({}, {__mode = "k"})
local BaseRecordsCache = nil
local BaseRecordsCacheTime = 0

local BasePalette = {
    {Name = "YELLOW", Color = Color3.fromRGB(245, 205, 48)},
    {Name = "GREEN", Color = Color3.fromRGB(75, 151, 75)},
    {Name = "CYAN", Color = Color3.fromRGB(4, 175, 236)},
    {Name = "BLUE", Color = Color3.fromRGB(13, 105, 172)},
    {Name = "RED", Color = Color3.fromRGB(196, 40, 28)},
    {Name = "ORANGE", Color = Color3.fromRGB(218, 133, 65)},
    {Name = "PURPLE", Color = Color3.fromRGB(123, 47, 123)},
    {Name = "PINK", Color = Color3.fromRGB(255, 102, 204)}
}

local BasePaletteByName = {}

for _, entry in ipairs(BasePalette) do
    BasePaletteByName[entry.Name] = entry.Color
end

local function TrackConnection(connection)
    if connection then
        table.insert(LBBConnections, connection)
        AddConnection(connection)
    end

    return connection
end

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

local function NormalizeName(value)
    return string.lower(tostring(value or "")):gsub("[^%w]", "")
end

local function IsRemote(object)
    return object
        and (
            object:IsA("RemoteEvent")
            or object:IsA("RemoteFunction")
        )
end

local function FindRemoteExact(name, waitTime)
    local direct = ReplicatedStorage:FindFirstChild(name, true)

    if IsRemote(direct) then
        return direct
    end

    if waitTime
    and waitTime > 0 then
        local deadline = os.clock() + waitTime

        repeat
            for _, object in ipairs(ReplicatedStorage:GetDescendants()) do
                if IsRemote(object)
                and object.Name == name then
                    return object
                end
            end

            task.wait(0.1)
        until os.clock() >= deadline
    end

    local normalized = NormalizeName(name)

    for _, object in ipairs(ReplicatedStorage:GetDescendants()) do
        if IsRemote(object)
        and NormalizeName(object.Name) == normalized then
            return object
        end
    end

    return nil
end

local function FindRemoteByTokens(tokens)
    local best = nil
    local bestScore = 0

    for _, object in ipairs(ReplicatedStorage:GetDescendants()) do
        if IsRemote(object) then
            local blob = NormalizeName(object.Name)
            local score = 0
            local valid = true

            for _, token in ipairs(tokens) do
                local normalizedToken = NormalizeName(token)

                if normalizedToken ~= ""
                and string.find(blob, normalizedToken, 1, true) then
                    score += 12
                else
                    valid = false
                    break
                end
            end

            if valid then
                if string.find(blob, "spawn", 1, true) then
                    score += 8
                end

                if string.find(blob, "block", 1, true) then
                    score += 5
                end

                if score > bestScore then
                    best = object
                    bestScore = score
                end
            end
        end
    end

    return best
end

local function FireRemote(remote)
    if not IsRemote(remote) then
        return false
    end

    return pcall(function()
        if remote:IsA("RemoteEvent") then
            remote:FireServer()
        else
            remote:InvokeServer()
        end
    end)
end

local function TryRemoteCandidates(names, tokenGroups)
    for _, name in ipairs(names or {}) do
        local remote = FindRemoteExact(name, 1.5)

        if remote
        and FireRemote(remote) then
            return true
        end
    end

    for _, tokens in ipairs(tokenGroups or {}) do
        local remote = FindRemoteByTokens(tokens)

        if remote
        and FireRemote(remote) then
            return true
        end
    end

    return false
end

local function FindInteractivePart(tokens)
    local bestPart = nil
    local bestScore = 0

    for _, object in ipairs(workspace:GetDescendants()) do
        local part = nil

        if object:IsA("BasePart") then
            part = object
        elseif object:IsA("Model") then
            part = object.PrimaryPart
                or object:FindFirstChildWhichIsA("BasePart", true)
        end

        if part then
            local pieces = {}
            local current = object

            for _ = 1, 4 do
                if not current then
                    break
                end

                table.insert(pieces, NormalizeName(current.Name))
                current = current.Parent
            end

            local blob = table.concat(pieces, "")
            local valid = true
            local score = 0

            for _, token in ipairs(tokens) do
                local normalizedToken = NormalizeName(token)

                if normalizedToken ~= ""
                and string.find(blob, normalizedToken, 1, true) then
                    score += 10
                else
                    valid = false
                    break
                end
            end

            if valid then
                local click = object:FindFirstChildWhichIsA("ClickDetector", true)
                    or part:FindFirstChildWhichIsA("ClickDetector", true)
                local prompt = object:FindFirstChildWhichIsA("ProximityPrompt", true)
                    or part:FindFirstChildWhichIsA("ProximityPrompt", true)
                local touch = object:FindFirstChildWhichIsA("TouchTransmitter", true)
                    or part:FindFirstChildWhichIsA("TouchTransmitter", true)

                if click then
                    score += 15
                end

                if prompt then
                    score += 15
                end

                if touch then
                    score += 12
                end

                if score > bestScore then
                    bestScore = score
                    bestPart = {
                        Part = part,
                        Click = click,
                        Prompt = prompt,
                        Touch = touch
                    }
                end
            end
        end
    end

    return bestPart
end

local function TriggerWorldBlock(tokens)
    local target = FindInteractivePart(tokens)

    if not target
    or not target.Part then
        return false
    end

    if target.Click
    and fireclickdetector then
        local ok = pcall(function()
            fireclickdetector(target.Click)
        end)

        if ok then
            return true
        end
    end

    if target.Prompt
    and fireproximityprompt then
        local ok = pcall(function()
            fireproximityprompt(target.Prompt)
        end)

        if ok then
            return true
        end
    end

    if target.Touch
    and firetouchinterest then
        local character = Player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")

        if root then
            local ok = pcall(function()
                firetouchinterest(root, target.Part, 0)
                task.wait()
                firetouchinterest(root, target.Part, 1)
            end)

            if ok then
                return true
            end
        end
    end

    return false
end

local function OpenStandardBlock(remoteName, label)
    local ok = TryRemoteCandidates(
        {remoteName},
        {
            {string.gsub(remoteName, "^Spawn", ""):gsub("Block$", ""), "Block"}
        }
    )

    if not ok then
        CustomNotify(
            tostring(label) .. " unavailable",
            Color3.fromRGB(255, 180, 70),
            4
        )
    end

    return ok
end

local function OpenVoidBlock()
    local ok = TryRemoteCandidates(
        {
            "SpawnVoidBlock",
            "SpawnVoidLuckyBlock",
            "S*VoidBlock",
            "VoidBlock"
        },
        {
            {"Void", "Block"},
            {"Void", "Lucky"}
        }
    )

    if not ok then
        ok = TriggerWorldBlock({"Void", "Block"})
    end

    if not ok then
        ok = TriggerWorldBlock({"Void"})
    end

    if not ok then
        CustomNotify(
            "Void Block unavailable",
            Color3.fromRGB(255, 180, 70),
            4
        )
    end

    return ok
end

local function OpenLimitedBlock()
    local ok = TryRemoteCandidates(
        {
            "SpawnHackerBlock",
            "SpawnLimitedBlock",
            "SpawnHackerLuckyBlock",
            "HackerBlock"
        },
        {
            {"Hacker", "Block"},
            {"Limited", "Block"},
            {"Hacker", "Lucky"}
        }
    )

    if not ok then
        ok = TriggerWorldBlock({"Hacker", "Block"})
    end

    if not ok then
        ok = TriggerWorldBlock({"Hacker"})
    end

    if not ok then
        CustomNotify(
            "Limited Block unavailable",
            Color3.fromRGB(255, 180, 70),
            4
        )
    end

    return ok
end

local function GetCharacterRoot(player)
    player = player or Player

    local character = player.Character
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

    local root = GetCharacterRoot(Player)

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

local function ColorDistance(a, b)
    local dr = a.R - b.R
    local dg = a.G - b.G
    local db = a.B - b.B
    return math.sqrt(dr * dr + dg * dg + db * db)
end

local function ClosestBaseColor(color)
    if typeof(color) ~= "Color3" then
        return nil, math.huge
    end

    local h, s, v = color:ToHSV()

    if s < 0.22
    or v < 0.18 then
        return nil, math.huge
    end

    local bestName = nil
    local bestDistance = math.huge

    for _, entry in ipairs(BasePalette) do
        local distance = ColorDistance(color, entry.Color)

        if distance < bestDistance then
            bestName = entry.Name
            bestDistance = distance
        end
    end

    if bestDistance > 0.72 then
        return nil, bestDistance
    end

    return bestName, bestDistance
end

local function GetDirectColorName(value)
    if typeof(value) == "BrickColor" then
        value = value.Color
    end

    if typeof(value) == "Color3" then
        return ClosestBaseColor(value)
    end

    local text = string.upper(tostring(value or ""))

    for _, entry in ipairs(BasePalette) do
        if string.find(text, entry.Name, 1, true) then
            return entry.Name, 0
        end
    end

    return nil, math.huge
end

local function DetectBaseColorAround(position)
    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = Player.Character and {Player.Character} or {}

    local ok, parts = pcall(function()
        return workspace:GetPartBoundsInRadius(position, 62, params)
    end)

    if not ok
    or typeof(parts) ~= "table" then
        return nil
    end

    local scores = {}

    for _, part in ipairs(parts) do
        if part:IsA("BasePart")
        and part.Transparency < 0.9 then
            local name, distance = ClosestBaseColor(part.Color)

            if name then
                local area = math.max(
                    1,
                    math.min(
                        1400,
                        math.max(
                            part.Size.X * part.Size.Z,
                            part.Size.X * part.Size.Y,
                            part.Size.Z * part.Size.Y
                        )
                    )
                )

                local _, saturation, value = part.Color:ToHSV()
                local distanceWeight = math.max(0.2, 1 - distance)
                local materialWeight = part.Material == Enum.Material.Grass and 0.18 or 1
                local weight = area
                    * (0.35 + saturation)
                    * (0.35 + value)
                    * distanceWeight
                    * materialWeight

                scores[name] = (scores[name] or 0) + weight
            end
        end
    end

    local bestName = nil
    local bestScore = 0

    for name, score in pairs(scores) do
        if score > bestScore then
            bestName = name
            bestScore = score
        end
    end

    return bestName
end

local function DetectSpawnColor(spawn)
    local colorName = DetectBaseColorAround(spawn.Position)

    if colorName then
        return colorName
    end

    local ok, teamColor = pcall(function()
        return spawn.TeamColor
    end)

    if ok then
        colorName = GetDirectColorName(teamColor)

        if colorName then
            return colorName
        end
    end

    colorName = GetDirectColorName(spawn.Color)
    return colorName
end

local function BuildBaseRecords()
    local spawns = GetSpawnLocations()
    local rawRecords = {}

    for _, spawn in ipairs(spawns) do
        local colorName = DetectSpawnColor(spawn)

        if colorName then
            table.insert(rawRecords, {
                Spawn = spawn,
                Position = spawn.Position,
                ColorName = colorName,
                Color = BasePaletteByName[colorName]
            })
        end
    end

    local deduped = {}

    for _, record in ipairs(rawRecords) do
        local existing = deduped[record.ColorName]

        if not existing then
            deduped[record.ColorName] = record
        else
            local existingNamed = string.find(
                string.lower(existing.Spawn.Name),
                string.lower(record.ColorName),
                1,
                true
            ) ~= nil

            local currentNamed = string.find(
                string.lower(record.Spawn.Name),
                string.lower(record.ColorName),
                1,
                true
            ) ~= nil

            if currentNamed and not existingNamed then
                deduped[record.ColorName] = record
            end
        end
    end

    local records = {}

    for _, entry in ipairs(BasePalette) do
        local record = deduped[entry.Name]

        if record then
            table.insert(records, record)
        end
    end

    if #records < 4 then
        records = {}
        local usedPositions = {}

        for _, spawn in ipairs(spawns) do
            local duplicate = false

            for _, position in ipairs(usedPositions) do
                if (spawn.Position - position).Magnitude < 45 then
                    duplicate = true
                    break
                end
            end

            if not duplicate then
                local colorName = DetectSpawnColor(spawn)

                if colorName then
                    table.insert(usedPositions, spawn.Position)
                    table.insert(records, {
                        Spawn = spawn,
                        Position = spawn.Position,
                        ColorName = colorName,
                        Color = BasePaletteByName[colorName]
                    })
                end
            end
        end
    end

    return records
end

local function GetBaseRecords(force)
    if not force
    and BaseRecordsCache
    and os.clock() - BaseRecordsCacheTime < 2.5 then
        return BaseRecordsCache
    end

    BaseRecordsCache = BuildBaseRecords()
    BaseRecordsCacheTime = os.clock()
    return BaseRecordsCache
end

local function WaitForBases(timeout)
    local deadline = os.clock() + (timeout or 8)
    local records = GetBaseRecords(true)

    while #records < 4
    and os.clock() < deadline do
        task.wait(0.35)
        records = GetBaseRecords(true)
    end

    return records
end

local function GetBaseCenterPosition(records)
    records = records or GetBaseRecords()

    if #records == 0 then
        return nil
    end

    local sum = Vector3.zero

    for _, record in ipairs(records) do
        sum += record.Position
    end

    return sum / #records
end

local function RaycastGroundAt(position, startY)
    if typeof(position) ~= "Vector3" then
        return nil
    end

    local excluded = {}

    if Player.Character then
        table.insert(excluded, Player.Character)
    end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = excluded
    params.IgnoreWater = false

    local originY = tonumber(startY) or position.Y + 180
    local origin = Vector3.new(position.X, originY, position.Z)

    for _ = 1, 8 do
        local result = workspace:Raycast(
            origin,
            Vector3.new(0, -900, 0),
            params
        )

        if not result then
            return nil
        end

        if result.Instance
        and result.Instance:IsA("BasePart")
        and result.Instance.CanCollide
        and result.Instance.Transparency < 0.95 then
            return result.Position
        end

        if result.Instance then
            table.insert(excluded, result.Instance)
            params.FilterDescendantsInstances = excluded
            origin = Vector3.new(position.X, originY, position.Z)
        else
            return nil
        end
    end

    return nil
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
            math.max(3.5, spawn.Size.Y * 0.5 + 3.5),
            0
        )
    )
end

local function GetBaseRecordByColor(colorName)
    colorName = string.upper(tostring(colorName or ""))

    for _, record in ipairs(GetBaseRecords()) do
        if record.ColorName == colorName then
            return record
        end
    end

    return nil
end

local function GetNearestBaseRecord(position, maxDistance)
    if typeof(position) ~= "Vector3" then
        return nil
    end

    local closest = nil
    local closestDistance = tonumber(maxDistance) or math.huge

    for _, record in ipairs(GetBaseRecords()) do
        local distance = (record.Position - position).Magnitude

        if distance < closestDistance then
            closest = record
            closestDistance = distance
        end
    end

    return closest
end

local function CachePlayerBase(player, allowLoose)
    if not player then
        return nil
    end

    local respawn = player.RespawnLocation

    if respawn
    and respawn:IsA("BasePart") then
        local record = GetNearestBaseRecord(respawn.Position, 90)

        if record then
            PlayerBaseCache[player] = record.ColorName
            return record
        end
    end

    local attributes = player:GetAttributes()

    for key, value in pairs(attributes) do
        local lowerKey = string.lower(tostring(key))

        if string.find(lowerKey, "base", 1, true)
        or string.find(lowerKey, "team", 1, true)
        or string.find(lowerKey, "color", 1, true) then
            local colorName = GetDirectColorName(value)

            if colorName then
                local record = GetBaseRecordByColor(colorName)

                if record then
                    PlayerBaseCache[player] = record.ColorName
                    return record
                end
            end
        end
    end

    if player.Team then
        local colorName = GetDirectColorName(player.Team.TeamColor)

        if colorName then
            local record = GetBaseRecordByColor(colorName)

            if record then
                PlayerBaseCache[player] = record.ColorName
                return record
            end
        end
    end

    local root = GetCharacterRoot(player)

    if root then
        local record = GetNearestBaseRecord(
            root.Position,
            allowLoose and 170 or 105
        )

        if record then
            PlayerBaseCache[player] = record.ColorName
            return record
        end
    end

    return nil
end

local function GetPlayerBaseRecord(player)
    if not player then
        return nil
    end

    local cachedName = PlayerBaseCache[player]

    if cachedName then
        local cachedRecord = GetBaseRecordByColor(cachedName)

        if cachedRecord then
            return cachedRecord
        end
    end

    return CachePlayerBase(player, false)
end

local function GetPlayerBaseCFrame()
    local record = GetPlayerBaseRecord(Player)

    if not record then
        record = CachePlayerBase(Player, true)
    end

    if record
    and record.Spawn then
        return GetSpawnCFrame(record.Spawn)
    end

    local respawn = Player.RespawnLocation

    if respawn
    and respawn:IsA("BasePart") then
        return GetSpawnCFrame(respawn)
    end

    return nil
end

local function GetCenterCFrame()
    local records = GetBaseRecords(true)
    local center = GetBaseCenterPosition(records)

    if not center then
        return nil
    end

    local highestY = center.Y

    for _, record in ipairs(records) do
        highestY = math.max(highestY, record.Position.Y)
    end

    local ground = RaycastGroundAt(center, highestY + 350)

    if ground then
        return CFrame.new(ground + Vector3.new(0, 4, 0))
    end

    return CFrame.new(center + Vector3.new(0, 4, 0))
end

local function GetBaseFrontCFrame(record)
    if not record then
        return nil
    end

    local center = GetBaseCenterPosition(GetBaseRecords())

    if not center then
        return GetSpawnCFrame(record.Spawn)
    end

    local delta = Vector3.new(
        center.X - record.Position.X,
        0,
        center.Z - record.Position.Z
    )

    if delta.Magnitude < 1 then
        return GetSpawnCFrame(record.Spawn)
    end

    local distanceToCenter = delta.Magnitude
    local forwardDistance = math.clamp(distanceToCenter * 0.13, 14, 28)
    local target = record.Position + delta.Unit * forwardDistance
    local ground = RaycastGroundAt(
        target,
        math.max(center.Y, record.Position.Y) + 140
    )

    if ground then
        return CFrame.new(
            ground + Vector3.new(0, 4, 0),
            Vector3.new(center.X, ground.Y + 4, center.Z)
        )
    end

    return CFrame.new(
        target + Vector3.new(0, 4, 0),
        Vector3.new(center.X, target.Y + 4, center.Z)
    )
end

local function GetPlayerBaseColor(player)
    local record = GetPlayerBaseRecord(player)

    if record
    and record.Color then
        return record.Color
    end

    local colorName = nil

    if player.Team then
        colorName = GetDirectColorName(player.Team.TeamColor)
    end

    if not colorName then
        colorName = GetDirectColorName(player.TeamColor)
    end

    return colorName
        and BasePaletteByName[colorName]
        or Color3.fromRGB(255, 255, 255)
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

    AutoSaveConfiguration()
end

local function HookPlayerBaseTracking(player)
    if not player then
        return
    end

    if player.Character then
        task.defer(function()
            task.wait(0.15)
            CachePlayerBase(player, false)
        end)
    end

    TrackConnection(player.CharacterAdded:Connect(function()
        task.delay(0.12, function()
            CachePlayerBase(player, false)
        end)

        task.delay(0.65, function()
            CachePlayerBase(player, false)
        end)
    end))

    pcall(function()
        TrackConnection(player:GetPropertyChangedSignal("RespawnLocation"):Connect(function()
            CachePlayerBase(player, true)
        end))
    end)
end

WaitForBases(8)

for _, player in ipairs(Players:GetPlayers()) do
    HookPlayerBaseTracking(player)
end

TrackConnection(Players.PlayerAdded:Connect(function(player)
    HookPlayerBaseTracking(player)
end))

TrackConnection(Players.PlayerRemoving:Connect(function(player)
    PlayerBaseCache[player] = nil
    ClearLBBESPPlayer(player)
end))

CachePlayerBase(Player, true)

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
        AutoSaveConfiguration()
    end,
    function(value)
        Settings.JumpValue = math.clamp(
            tonumber(value) or 50,
            1,
            500
        )
        AutoSaveConfiguration()
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

        AutoSaveConfiguration()
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
    OpenStandardBlock("SpawnLuckyBlock", "Lucky Block")
end)

LBBCreateButton("Super Blocks (Open)", GamePage, function()
    OpenStandardBlock("SpawnSuperBlock", "Super Block")
end)

LBBCreateButton("Diamond Blocks (Open)", GamePage, function()
    OpenStandardBlock("SpawnDiamondBlock", "Diamond Block")
end)

LBBCreateButton("Rainbow Blocks (Open)", GamePage, function()
    OpenStandardBlock("SpawnRainbowBlock", "Rainbow Block")
end)

LBBCreateButton("Galaxy Blocks (Open)", GamePage, function()
    OpenStandardBlock("SpawnGalaxyBlock", "Galaxy Block")
end)

LBBCreateButton("Void Blocks (Open)", GamePage, function()
    OpenVoidBlock()
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

local initialRecords = GetBaseRecords(true)
local createdColors = {}

for _, entry in ipairs(BasePalette) do
    local exists = false

    for _, record in ipairs(initialRecords) do
        if record.ColorName == entry.Name then
            exists = true
            break
        end
    end

    if exists then
        createdColors[entry.Name] = true

        LBBCreateButton(entry.Name, GamePage, function()
            local record = GetBaseRecordByColor(entry.Name)
            TeleportTo(
                GetBaseFrontCFrame(record),
                entry.Name
            )
        end)
    end
end

if next(createdColors) == nil then
    for _, entry in ipairs(BasePalette) do
        LBBCreateButton(entry.Name, GamePage, function()
            local record = GetBaseRecordByColor(entry.Name)
            TeleportTo(
                GetBaseFrontCFrame(record),
                entry.Name
            )
        end)
    end
end

getgenv().ToxLBBCleanup = function()
    LBBESPGeneration += 1
    ClearLBBESP()

    for _, connection in ipairs(LBBConnections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    table.clear(LBBConnections)
end

if Settings.LBBBaseESP then
    StartLBBESP()
end

getgenv().ToxLBBModuleLoadedJobId = game.JobId
getgenv().ToxLBBModuleVersion = LBBModuleVersion
getgenv().ToxLBBModulePage = GamePage
