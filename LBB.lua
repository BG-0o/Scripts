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

local LBBModuleVersion = "2026-09-14-lbb-respawn-esp-spawnfix-8"

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
    {Name = "YELLOW", Hue = 0.155, Color = Color3.fromRGB(255, 255, 0)},
    {Name = "GREEN", Hue = 0.333, Color = Color3.fromRGB(65, 210, 85)},
    {Name = "CYAN", Hue = 0.500, Color = Color3.fromRGB(45, 210, 235)},
    {Name = "BLUE", Hue = 0.620, Color = Color3.fromRGB(55, 105, 235)},
    {Name = "RED", Hue = 0.000, Color = Color3.fromRGB(235, 55, 55)},
    {Name = "ORANGE", Hue = 0.080, Color = Color3.fromRGB(240, 135, 45)},
    {Name = "PURPLE", Hue = 0.765, Color = Color3.fromRGB(150, 70, 220)},
    {Name = "PINK", Hue = 0.910, Color = Color3.fromRGB(245, 90, 175)}
}

local BasePaletteByName = {}

for _, entry in ipairs(BasePalette) do
    BasePaletteByName[entry.Name] = entry.Color
end

local BasePositionByName = {
    ORANGE = Vector3.new(-863.255, 207.687, -22.923),
    YELLOW = Vector3.new(-927.046, 207.687, -89.130),
    GREEN = Vector3.new(-1155.154, 207.701, -88.890),
    CYAN = Vector3.new(-1221.224, 207.359, -22.977),
    BLUE = Vector3.new(-1221.271, 207.274, 205.167),
    RED = Vector3.new(-1155.030, 207.263, 268.744),
    PURPLE = Vector3.new(-926.998, 207.276, 268.876),
    PINK = Vector3.new(-863.006, 207.359, 204.753)
}

local CenterPosition = Vector3.new(-1041.623, 207.451, 90.453)

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

local function FireRemote(remote, ...)
    if not IsRemote(remote) then
        return false
    end

    local args = {...}

    return pcall(function()
        if remote:IsA("RemoteEvent") then
            remote:FireServer(table.unpack(args))
        else
            remote:InvokeServer(table.unpack(args))
        end
    end)
end

local function RemoteSearchRoots()
    local roots = {ReplicatedStorage}

    pcall(function()
        local playerGui = Player:FindFirstChildOfClass("PlayerGui")

        if playerGui then
            table.insert(roots, playerGui)
        end
    end)

    return roots
end

local function FindRemoteExact(name, waitTime)
    local normalized = NormalizeName(name)
    local deadline = os.clock() + (tonumber(waitTime) or 0)

    repeat
        for _, root in ipairs(RemoteSearchRoots()) do
            local direct = root:FindFirstChild(name, true)

            if IsRemote(direct) then
                return direct
            end

            for _, object in ipairs(root:GetDescendants()) do
                if IsRemote(object)
                and NormalizeName(object.Name) == normalized then
                    return object
                end
            end
        end

        if os.clock() >= deadline then
            break
        end

        task.wait(0.08)
    until false

    if getnilinstances then
        local ok, list = pcall(getnilinstances)

        if ok
        and typeof(list) == "table" then
            for _, object in ipairs(list) do
                if IsRemote(object)
                and NormalizeName(object.Name) == normalized then
                    return object
                end
            end
        end
    end

    return nil
end

local function HasTokens(text, tokens)
    text = NormalizeName(text)

    for _, token in ipairs(tokens or {}) do
        local normalized = NormalizeName(token)

        if normalized ~= ""
        and not string.find(text, normalized, 1, true) then
            return false
        end
    end

    return true
end

local function FindRemoteByTokens(tokens)
    local best = nil
    local bestScore = -math.huge

    for _, root in ipairs(RemoteSearchRoots()) do
        for _, object in ipairs(root:GetDescendants()) do
            if IsRemote(object) then
                local blob = NormalizeName(object.Name)

                if HasTokens(blob, tokens) then
                    local score = 0

                    if string.find(blob, "spawn", 1, true) then
                        score += 15
                    end

                    if string.find(blob, "open", 1, true) then
                        score += 12
                    end

                    if string.find(blob, "give", 1, true) then
                        score += 8
                    end

                    if string.find(blob, "block", 1, true) then
                        score += 8
                    end

                    if root == ReplicatedStorage then
                        score += 5
                    end

                    if score > bestScore then
                        best = object
                        bestScore = score
                    end
                end
            end
        end
    end

    return best
end

local function ReadRemoteFromValue(value, seen, depth)
    if IsRemote(value) then
        return value
    end

    if typeof(value) ~= "table"
    or depth <= 0
    or seen[value] then
        return nil
    end

    seen[value] = true

    for key, item in pairs(value) do
        if IsRemote(item) then
            return item
        end

        if typeof(item) == "table" then
            local found = ReadRemoteFromValue(item, seen, depth - 1)

            if found then
                return found
            end
        end

        if IsRemote(key) then
            return key
        end
    end

    return nil
end

local function FunctionMentionsTokens(fn, tokens)
    local getter = nil

    pcall(function()
        getter = debug and debug.getconstants
    end)

    if not getter and getconstants then
        getter = getconstants
    end

    if not getter then
        return false
    end

    local ok, constants = pcall(getter, fn)

    if not ok
    or typeof(constants) ~= "table" then
        return false
    end

    local pieces = {}

    for _, value in pairs(constants) do
        if typeof(value) == "string" then
            table.insert(pieces, value)
        end
    end

    return HasTokens(table.concat(pieces, " "), tokens)
end

local function FindRemoteFromGC(tokens)
    if not getgc then
        return nil
    end

    local ok, objects = pcall(getgc, true)

    if not ok
    or typeof(objects) ~= "table" then
        return nil
    end

    local upvalueGetter = nil

    pcall(function()
        upvalueGetter = debug and debug.getupvalues
    end)

    if not upvalueGetter and getupvalues then
        upvalueGetter = getupvalues
    end

    for _, value in ipairs(objects) do
        if typeof(value) == "function"
        and FunctionMentionsTokens(value, tokens)
        and upvalueGetter then
            local upOk, upvalues = pcall(upvalueGetter, value)

            if upOk
            and typeof(upvalues) == "table" then
                for _, upvalue in pairs(upvalues) do
                    local remote = ReadRemoteFromValue(upvalue, {}, 3)

                    if remote then
                        return remote
                    end
                end
            end
        elseif typeof(value) == "table" then
            for key, item in pairs(value) do
                if typeof(key) == "string"
                and HasTokens(key, tokens)
                and IsRemote(item) then
                    return item
                end
            end
        end
    end

    return nil
end

local function TryRemoteCandidates(names, tokenGroups)
    for _, name in ipairs(names or {}) do
        local remote = FindRemoteExact(name, 0.7)

        if remote
        and FireRemote(remote) then
            return true
        end
    end

    for _, tokens in ipairs(tokenGroups or {}) do
        local remote = FindRemoteByTokens(tokens)
            or FindRemoteFromGC(tokens)

        if remote
        and FireRemote(remote) then
            return true
        end
    end

    return false
end

local function IsInsideToxGui(object)
    local gui = getgenv().Gui

    return gui
        and object
        and (
            object == gui
            or object:IsDescendantOf(gui)
        )
end

local function GetGuiSearchText(object)
    local pieces = {}
    local current = object

    for _ = 1, 5 do
        if not current then
            break
        end

        table.insert(pieces, tostring(current.Name or ""))

        if current:IsA("TextButton")
        or current:IsA("TextLabel")
        or current:IsA("TextBox") then
            table.insert(pieces, tostring(current.Text or ""))
        end

        current = current.Parent
    end

    return table.concat(pieces, " ")
end

local function FireSignalConnections(signal)
    local fired = false

    if firesignal then
        local ok = pcall(function()
            firesignal(signal)
        end)

        if ok then
            fired = true
        end
    end

    if getconnections then
        local ok, connections = pcall(getconnections, signal)

        if ok
        and typeof(connections) == "table" then
            for _, connection in ipairs(connections) do
                local fn = connection.Function

                if typeof(fn) == "function" then
                    if pcall(fn) then
                        fired = true
                    end
                elseif connection.Fire then
                    if pcall(function()
                        connection:Fire()
                    end) then
                        fired = true
                    end
                end
            end
        end
    end

    return fired
end

local function TriggerGameGuiButton(tokenGroups)
    local playerGui = Player:FindFirstChildOfClass("PlayerGui")

    if not playerGui then
        return false
    end

    local candidates = {}

    for _, object in ipairs(playerGui:GetDescendants()) do
        if (object:IsA("TextButton") or object:IsA("ImageButton"))
        and not IsInsideToxGui(object) then
            local blob = GetGuiSearchText(object)

            for _, tokens in ipairs(tokenGroups or {}) do
                if HasTokens(blob, tokens) then
                    local score = 0

                    if object.Visible then
                        score += 10
                    end

                    if object.Active then
                        score += 5
                    end

                    if object:IsA("TextButton") then
                        score += 4
                    end

                    table.insert(candidates, {
                        Button = object,
                        Score = score
                    })
                    break
                end
            end
        end
    end

    table.sort(candidates, function(a, b)
        return a.Score > b.Score
    end)

    for _, entry in ipairs(candidates) do
        local button = entry.Button
        local fired = false

        pcall(function()
            fired = FireSignalConnections(button.Activated) or fired
        end)

        pcall(function()
            fired = FireSignalConnections(button.MouseButton1Click) or fired
        end)

        pcall(function()
            fired = FireSignalConnections(button.MouseButton1Down) or fired
        end)

        if fired then
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

                table.insert(pieces, tostring(current.Name or ""))
                current = current.Parent
            end

            local blob = table.concat(pieces, " ")

            if HasTokens(blob, tokens) then
                local click = object:FindFirstChildWhichIsA("ClickDetector", true)
                    or part:FindFirstChildWhichIsA("ClickDetector", true)
                local prompt = object:FindFirstChildWhichIsA("ProximityPrompt", true)
                    or part:FindFirstChildWhichIsA("ProximityPrompt", true)
                local touch = object:FindFirstChildWhichIsA("TouchTransmitter", true)
                    or part:FindFirstChildWhichIsA("TouchTransmitter", true)
                local score = 1

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
        if pcall(function()
            fireclickdetector(target.Click)
        end) then
            return true
        end
    end

    if target.Prompt
    and fireproximityprompt then
        if pcall(function()
            fireproximityprompt(target.Prompt)
        end) then
            return true
        end
    end

    if target.Touch
    and firetouchinterest then
        local character = Player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")

        if root
        and pcall(function()
            firetouchinterest(root, target.Part, 0)
            task.wait()
            firetouchinterest(root, target.Part, 1)
        end) then
            return true
        end
    end

    return false
end

local function TryGenericBlockRemote(blockNames)
    local remotes = {}

    for _, object in ipairs(ReplicatedStorage:GetDescendants()) do
        if IsRemote(object) then
            local lower = NormalizeName(object.Name)

            if string.find(lower, "block", 1, true)
            and (
                string.find(lower, "spawn", 1, true)
                or string.find(lower, "open", 1, true)
                or string.find(lower, "give", 1, true)
            ) then
                table.insert(remotes, object)
            end
        end
    end

    for _, remote in ipairs(remotes) do
        for _, name in ipairs(blockNames or {}) do
            local forms = {
                name,
                NormalizeName(name),
                string.gsub(name, "Block", ""),
                string.lower(string.gsub(name, "Block", ""))
            }

            for _, value in ipairs(forms) do
                FireRemote(remote, value)
            end
        end
    end

    return #remotes > 0
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

local function CountPlayerTools()
    local count = 0
    local character = Player.Character
    local backpack = Player:FindFirstChildOfClass("Backpack")

    for _, container in ipairs({character, backpack}) do
        if container then
            for _, object in ipairs(container:GetChildren()) do
                if object:IsA("Tool") then
                    count += 1
                end
            end
        end
    end

    return count
end

local function WaitForNewTool(before, timeout)
    local deadline = os.clock() + (tonumber(timeout) or 1.4)

    repeat
        if CountPlayerTools() > before then
            return true
        end

        task.wait(0.08)
    until os.clock() >= deadline

    return CountPlayerTools() > before
end

local function FireSpecialRemote(name, repeats)
    local remote = ReplicatedStorage:FindFirstChild(name)
        or FindRemoteExact(name, 0.35)

    if not IsRemote(remote) then
        return false
    end

    for _ = 1, math.max(1, tonumber(repeats) or 1) do
        FireRemote(remote)
        task.wait(0.06)
    end

    return true
end

local function GetInteractivePart(object)
    if not object then
        return nil
    end

    if object:IsA("BasePart") then
        return object
    end

    local parent = object.Parent

    if parent and parent:IsA("BasePart") then
        return parent
    end

    return object:FindFirstAncestorWhichIsA("BasePart")
end

local function TriggerNearbySpecial(position, kind)
    if typeof(position) ~= "Vector3" then
        return false
    end

    local candidates = {}

    for _, object in ipairs(workspace:GetDescendants()) do
        if object:IsA("ClickDetector")
        or object:IsA("ProximityPrompt")
        or object:IsA("TouchTransmitter") then
            local part = GetInteractivePart(object)

            if part then
                local horizontal = Vector3.new(
                    part.Position.X - position.X,
                    0,
                    part.Position.Z - position.Z
                ).Magnitude

                if horizontal <= 115 then
                    local blob = NormalizeName(
                        tostring(part.Name)
                        .. " "
                        .. tostring(part.Parent and part.Parent.Name or "")
                    )
                    local _, saturation, value = part.Color:ToHSV()
                    local score = 120 - horizontal

                    if kind == "void" then
                        if string.find(blob, "void", 1, true) then
                            score += 500
                        end

                        if saturation < 0.16
                        and value > 0.68 then
                            score += 45
                        end
                    elseif kind == "hacker" then
                        if string.find(blob, "hacker", 1, true)
                        or string.find(blob, "limited", 1, true) then
                            score += 500
                        end

                        local hue = select(1, part.Color:ToHSV())

                        if value < 0.24 then
                            score += 30
                        elseif saturation > 0.45
                        and hue > 0.25
                        and hue < 0.45 then
                            score += 25
                        end
                    end

                    table.insert(candidates, {
                        Object = object,
                        Part = part,
                        Score = score
                    })
                end
            end
        end
    end

    table.sort(candidates, function(a, b)
        return a.Score > b.Score
    end)

    local character = Player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")

    for index = 1, math.min(10, #candidates) do
        local entry = candidates[index]
        local object = entry.Object

        if object:IsA("ClickDetector")
        and fireclickdetector then
            pcall(function()
                fireclickdetector(object)
            end)
        elseif object:IsA("ProximityPrompt")
        and fireproximityprompt then
            pcall(function()
                fireproximityprompt(object)
            end)
        elseif object:IsA("TouchTransmitter")
        and root
        and firetouchinterest then
            pcall(function()
                firetouchinterest(root, entry.Part, 0)
                task.wait(0.03)
                firetouchinterest(root, entry.Part, 1)
            end)
        end
    end

    return #candidates > 0
end

local function GetFunctionConstants(fn)
    local getter = nil

    pcall(function()
        getter = debug and debug.getconstants
    end)

    if not getter and getconstants then
        getter = getconstants
    end

    if not getter then
        return {}
    end

    local ok, constants = pcall(getter, fn)

    if ok and typeof(constants) == "table" then
        return constants
    end

    return {}
end

local function GetFunctionUpvalues(fn)
    local getter = nil

    pcall(function()
        getter = debug and debug.getupvalues
    end)

    if not getter and getupvalues then
        getter = getupvalues
    end

    if not getter then
        return {}
    end

    local ok, upvalues = pcall(getter, fn)

    if ok and typeof(upvalues) == "table" then
        return upvalues
    end

    return {}
end

local function CollectRemoteInstances(value, output, seen, depth)
    if IsRemote(value) then
        output[value] = true
        return
    end

    if typeof(value) ~= "table"
    or depth <= 0
    or seen[value] then
        return
    end

    seen[value] = true

    for key, item in pairs(value) do
        if IsRemote(key) then
            output[key] = true
        elseif typeof(key) == "table" then
            CollectRemoteInstances(key, output, seen, depth - 1)
        end

        if IsRemote(item) then
            output[item] = true
        elseif typeof(item) == "table" then
            CollectRemoteInstances(item, output, seen, depth - 1)
        end
    end
end

local function GetSpecialDefinition(kind)
    if kind == "void" then
        return {
            Tokens = {"void"},
            ButtonGroups = {
                {"Void", "Block"},
                {"Void"}
            },
            Names = {
                "SpawnVoidBlock",
                "SpawnVoidLuckyBlock",
                "S*VoidBlock",
                "SVoidBlock",
                "VoidBlock",
                "SpawnVoid"
            },
            Arguments = {
                "Void",
                "VoidBlock",
                "Void Block",
                "VoidLuckyBlock"
            }
        }
    end

    return {
        Tokens = {"hacker"},
        AlternateTokens = {"limited"},
        ButtonGroups = {
            {"Hacker", "Block"},
            {"Limited", "Block"},
            {"Hacker"},
            {"Limited"}
        },
        Names = {
            "SpawnHackerBlock",
            "SpawnLimitedBlock",
            "SpawnHackerLuckyBlock",
            "S*HackerBlock",
            "SHackerBlock",
            "HackerBlock",
            "LimitedBlock",
            "SpawnHacker",
            "SpawnLimited"
        },
        Arguments = {
            "Hacker",
            "HackerBlock",
            "Hacker Block",
            "Limited",
            "LimitedBlock",
            "Limited Block"
        }
    }
end

local function FunctionMatchesSpecial(fn, definition)
    local constants = GetFunctionConstants(fn)
    local pieces = {}

    for _, value in pairs(constants) do
        if typeof(value) == "string" then
            table.insert(pieces, value)
        end
    end

    local blob = NormalizeName(table.concat(pieces, " "))

    for _, token in ipairs(definition.Tokens or {}) do
        if string.find(blob, NormalizeName(token), 1, true) then
            return true, constants
        end
    end

    for _, token in ipairs(definition.AlternateTokens or {}) do
        if string.find(blob, NormalizeName(token), 1, true) then
            return true, constants
        end
    end

    return false, constants
end

local function AddSpecialCandidate(candidates, scores, remote, score)
    if not IsRemote(remote) then
        return
    end

    if not scores[remote] then
        table.insert(candidates, remote)
        scores[remote] = score or 0
    else
        scores[remote] = math.max(scores[remote], score or 0)
    end
end

local function CollectSpecialRemoteCandidates(kind)
    local definition = GetSpecialDefinition(kind)
    local candidates = {}
    local scores = {}

    for index, name in ipairs(definition.Names) do
        local remote = ReplicatedStorage:FindFirstChild(name, true)
            or FindRemoteExact(name, 0.15)

        AddSpecialCandidate(
            candidates,
            scores,
            remote,
            1000 - index
        )
    end

    for _, root in ipairs(RemoteSearchRoots()) do
        for _, object in ipairs(root:GetDescendants()) do
            if IsRemote(object) then
                local normalized = NormalizeName(object.Name)
                local score = 0

                for _, token in ipairs(definition.Tokens or {}) do
                    if string.find(normalized, NormalizeName(token), 1, true) then
                        score += 500
                    end
                end

                for _, token in ipairs(definition.AlternateTokens or {}) do
                    if string.find(normalized, NormalizeName(token), 1, true) then
                        score += 450
                    end
                end

                if string.find(normalized, "spawn", 1, true) then
                    score += 80
                end

                if string.find(normalized, "block", 1, true) then
                    score += 80
                end

                if string.sub(tostring(object.Name), 1, 2) == "S*" then
                    score += 45
                end

                if score > 0 then
                    AddSpecialCandidate(candidates, scores, object, score)
                end
            end
        end
    end

    local playerGui = Player:FindFirstChildOfClass("PlayerGui")

    if playerGui and getconnections then
        for _, object in ipairs(playerGui:GetDescendants()) do
            if (object:IsA("TextButton") or object:IsA("ImageButton"))
            and not IsInsideToxGui(object) then
                local blob = GetGuiSearchText(object)
                local matches = false

                for _, tokens in ipairs(definition.ButtonGroups) do
                    if HasTokens(blob, tokens) then
                        matches = true
                        break
                    end
                end

                if matches then
                    for _, signal in ipairs({
                        object.Activated,
                        object.MouseButton1Click,
                        object.MouseButton1Down
                    }) do
                        local ok, connections = pcall(getconnections, signal)

                        if ok and typeof(connections) == "table" then
                            for _, connection in ipairs(connections) do
                                local fn = connection.Function

                                if typeof(fn) == "function" then
                                    local remotes = {}
                                    CollectRemoteInstances(
                                        GetFunctionUpvalues(fn),
                                        remotes,
                                        {},
                                        4
                                    )

                                    for remote in pairs(remotes) do
                                        AddSpecialCandidate(
                                            candidates,
                                            scores,
                                            remote,
                                            900
                                        )
                                    end

                                    for _, constant in pairs(GetFunctionConstants(fn)) do
                                        if typeof(constant) == "string" then
                                            local remote = FindRemoteExact(constant, 0)

                                            if remote then
                                                AddSpecialCandidate(
                                                    candidates,
                                                    scores,
                                                    remote,
                                                    850
                                                )
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    if getgc then
        local ok, objects = pcall(getgc, true)

        if ok and typeof(objects) == "table" then
            for _, value in ipairs(objects) do
                if typeof(value) == "function" then
                    local matches, constants = FunctionMatchesSpecial(
                        value,
                        definition
                    )

                    if matches then
                        local remotes = {}
                        CollectRemoteInstances(
                            GetFunctionUpvalues(value),
                            remotes,
                            {},
                            4
                        )

                        for remote in pairs(remotes) do
                            AddSpecialCandidate(
                                candidates,
                                scores,
                                remote,
                                780
                            )
                        end

                        for _, constant in pairs(constants) do
                            if typeof(constant) == "string" then
                                local remote = FindRemoteExact(constant, 0)

                                if remote then
                                    AddSpecialCandidate(
                                        candidates,
                                        scores,
                                        remote,
                                        760
                                    )
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    if getnilinstances then
        local ok, objects = pcall(getnilinstances)

        if ok and typeof(objects) == "table" then
            for _, object in ipairs(objects) do
                if IsRemote(object) then
                    local normalized = NormalizeName(object.Name)
                    local score = 0

                    for _, token in ipairs(definition.Tokens or {}) do
                        if string.find(normalized, NormalizeName(token), 1, true) then
                            score += 400
                        end
                    end

                    for _, token in ipairs(definition.AlternateTokens or {}) do
                        if string.find(normalized, NormalizeName(token), 1, true) then
                            score += 380
                        end
                    end

                    if score > 0 then
                        AddSpecialCandidate(candidates, scores, object, score)
                    end
                end
            end
        end
    end

    table.sort(candidates, function(a, b)
        return (scores[a] or 0) > (scores[b] or 0)
    end)

    return candidates, definition
end

local function TrySpecialRemote(kind, before)
    local candidates, definition = CollectSpecialRemoteCandidates(kind)

    for _, remote in ipairs(candidates) do
        FireRemote(remote)
        task.wait(0.12)

        if CountPlayerTools() > before then
            return true
        end

        for _, argument in ipairs(definition.Arguments or {}) do
            FireRemote(remote, argument)
            task.wait(0.09)

            if CountPlayerTools() > before then
                return true
            end
        end
    end

    local genericNames = kind == "void"
        and {"VoidBlock", "Void"}
        or {"HackerBlock", "Hacker", "LimitedBlock", "Limited"}

    TryGenericBlockRemote(genericNames)
    return WaitForNewTool(before, 0.65)
end

local function FindPhysicalSpecialBlock(position, kind)
    if typeof(position) ~= "Vector3" then
        return nil
    end

    local best = nil
    local bestScore = -math.huge
    local maxHorizontal = kind == "void" and 105 or 95

    for _, part in ipairs(workspace:GetDescendants()) do
        if part:IsA("BasePart")
        and part.Parent
        and part.Transparency < 0.98 then
            local horizontal = Vector3.new(
                part.Position.X - position.X,
                0,
                part.Position.Z - position.Z
            ).Magnitude

            if horizontal <= maxHorizontal then
                local blob = NormalizeName(
                    tostring(part.Name)
                    .. " "
                    .. tostring(part.Parent and part.Parent.Name or "")
                    .. " "
                    .. tostring(part.Parent and part.Parent.Parent and part.Parent.Parent.Name or "")
                )
                local hue, saturation, value = part.Color:ToHSV()
                local score = 100 - horizontal

                if string.find(blob, "lucky", 1, true)
                or string.find(blob, "block", 1, true) then
                    score += 180
                end

                if kind == "void" then
                    if string.find(blob, "void", 1, true) then
                        score += 1000
                    end

                    if saturation <= 0.20 and value >= 0.72 then
                        score += 140
                    end

                    if value <= 0.20 then
                        score += 35
                    end
                else
                    if string.find(blob, "hacker", 1, true)
                    or string.find(blob, "limited", 1, true) then
                        score += 1000
                    end

                    if value <= 0.28 then
                        score += 95
                    end

                    if saturation >= 0.48
                    and hue >= 0.24
                    and hue <= 0.45 then
                        score += 85
                    end
                end

                local sizeMagnitude = part.Size.Magnitude

                if sizeMagnitude <= 30 then
                    score += 80
                elseif sizeMagnitude >= 90 then
                    score -= 160
                end

                if score > bestScore then
                    best = part
                    bestScore = score
                end
            end
        end
    end

    if bestScore < 70 then
        return nil
    end

    return best
end

local function InteractPhysicalSpecial(position, kind, before)
    local part = FindPhysicalSpecialBlock(position, kind)

    if not part then
        return false
    end

    local click = part:FindFirstChildWhichIsA("ClickDetector", true)
        or (part.Parent and part.Parent:FindFirstChildWhichIsA("ClickDetector", true))
    local prompt = part:FindFirstChildWhichIsA("ProximityPrompt", true)
        or (part.Parent and part.Parent:FindFirstChildWhichIsA("ProximityPrompt", true))

    if click and fireclickdetector then
        pcall(function()
            fireclickdetector(click)
        end)
    end

    if prompt and fireproximityprompt then
        pcall(function()
            fireproximityprompt(prompt)
        end)
    end

    local character = Player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if root then
        local oldCFrame = root.CFrame
        local oldLinear = root.AssemblyLinearVelocity
        local oldAngular = root.AssemblyAngularVelocity
        local distance = (root.Position - part.Position).Magnitude

        if getgenv().AllowToxTeleport then
            getgenv().AllowToxTeleport(1.2, "LBB Special Block")
        end

        if distance > 16 then
            root.CFrame = CFrame.new(
                part.Position + Vector3.new(0, math.max(3, part.Size.Y * 0.5 + 2), 0)
            )
            task.wait(0.08)
        end

        if firetouchinterest then
            pcall(function()
                firetouchinterest(root, part, 0)
                task.wait(0.05)
                firetouchinterest(root, part, 1)
            end)
        end

        task.wait(0.18)

        if distance > 16
        and root.Parent
        and character == Player.Character then
            root.CFrame = oldCFrame
            root.AssemblyLinearVelocity = oldLinear
            root.AssemblyAngularVelocity = oldAngular
        end
    end

    return WaitForNewTool(before, 0.8)
end

local function OpenExactLBBBlock(remoteNames, label)
    local before = CountPlayerTools()

    for _, remoteName in ipairs(remoteNames) do
        local remote = ReplicatedStorage:FindFirstChild(remoteName, true)
            or FindRemoteExact(remoteName, 0.25)

        if IsRemote(remote) then
            if FireRemote(remote) then
                if WaitForNewTool(before, 0.55) then
                    return true
                end
            end
        end
    end

    return false
end

local function OpenVoidBlock()
    local remote = ReplicatedStorage:FindFirstChild("SpawnVoidBlock")
        or ReplicatedStorage:FindFirstChild("SpawnVoidBlock", true)
        or FindRemoteExact("SpawnVoidBlock", 0.5)

    if IsRemote(remote) then
        return FireRemote(remote)
    end

    CustomNotify(
        "Void Block unavailable",
        Color3.fromRGB(255, 180, 70),
        4
    )

    return false
end

local function GetUnknownLimitedBlockRemotes()
    local known = {
        spawnluckyblock = true,
        spawnsuperblock = true,
        spawndiamondblock = true,
        spawnrainbowblock = true,
        spawngalaxyblock = true,
        spawnvoidblock = true
    }

    local candidates = {}

    for _, object in ipairs(ReplicatedStorage:GetDescendants()) do
        if IsRemote(object) then
            local normalized = NormalizeName(object.Name)

            if string.sub(normalized, 1, 5) == "spawn"
            and string.find(normalized, "block", 1, true)
            and not known[normalized] then
                local score = 0

                if string.find(normalized, "limited", 1, true) then
                    score += 1000
                end

                if string.find(normalized, "hacker", 1, true) then
                    score += 950
                end

                if string.find(normalized, "event", 1, true)
                or string.find(normalized, "special", 1, true) then
                    score += 500
                end

                table.insert(candidates, {
                    Remote = object,
                    Score = score
                })
            end
        end
    end

    table.sort(candidates, function(a, b)
        return a.Score > b.Score
    end)

    return candidates
end

local function OpenLimitedBlock()
    local remote = ReplicatedStorage:FindFirstChild("SpawnHackerBlock")
        or ReplicatedStorage:FindFirstChild("SpawnHackerBlock", true)
        or FindRemoteExact("SpawnHackerBlock", 0.5)

    if IsRemote(remote) then
        return FireRemote(remote)
    end

    local limited = ReplicatedStorage:FindFirstChild("SpawnLimitedBlock")
        or ReplicatedStorage:FindFirstChild("SpawnLimitedBlock", true)
        or FindRemoteExact("SpawnLimitedBlock", 0.35)

    if IsRemote(limited) then
        return FireRemote(limited)
    end

    CustomNotify(
        "Limited Block unavailable",
        Color3.fromRGB(255, 180, 70),
        4
    )

    return false
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

local function HueDistance(a, b)
    local distance = math.abs(a - b)
    return math.min(distance, 1 - distance)
end

local function ClosestBaseColor(color)
    if typeof(color) ~= "Color3" then
        return nil, math.huge
    end

    local hue, saturation, value = color:ToHSV()

    if saturation < 0.28
    or value < 0.16 then
        return nil, math.huge
    end

    local bestName = nil
    local bestDistance = math.huge

    for _, entry in ipairs(BasePalette) do
        local distance = HueDistance(hue, entry.Hue)

        if distance < bestDistance then
            bestName = entry.Name
            bestDistance = distance
        end
    end

    if bestDistance > 0.095 then
        return nil, bestDistance
    end

    return bestName, bestDistance
end

local function GetDirectColorName(value)
    local function FromText(text)
        text = NormalizeName(text)

        if text == "" then
            return nil
        end

        if string.find(text, "grey", 1, true)
        or string.find(text, "gray", 1, true)
        or string.find(text, "stone", 1, true)
        or string.find(text, "white", 1, true)
        or string.find(text, "black", 1, true) then
            return nil
        end

        local named = {
            {"newyeller", "YELLOW"},
            {"brightyellow", "YELLOW"},
            {"yellow", "YELLOW"},
            {"brightorange", "ORANGE"},
            {"orange", "ORANGE"},
            {"brightgreen", "GREEN"},
            {"limegreen", "GREEN"},
            {"lime", "GREEN"},
            {"green", "GREEN"},
            {"toothpaste", "CYAN"},
            {"lightblue", "CYAN"},
            {"aqua", "CYAN"},
            {"teal", "CYAN"},
            {"cyan", "CYAN"},
            {"brightblue", "BLUE"},
            {"darkblue", "BLUE"},
            {"royalblue", "BLUE"},
            {"blue", "BLUE"},
            {"brightred", "RED"},
            {"reallyred", "RED"},
            {"red", "RED"},
            {"royalpurple", "PURPLE"},
            {"brightviolet", "PURPLE"},
            {"purple", "PURPLE"},
            {"violet", "PURPLE"},
            {"hotpink", "PINK"},
            {"pink", "PINK"}
        }

        for _, entry in ipairs(named) do
            if string.find(text, entry[1], 1, true) then
                return entry[2]
            end
        end

        return nil
    end

    if typeof(value) == "BrickColor" then
        local byName = FromText(value.Name)

        if byName then
            return byName, 0
        end

        value = value.Color
    end

    if typeof(value) == "Color3" then
        local _, saturation, brightness = value:ToHSV()

        if saturation < 0.28
        or brightness < 0.18 then
            return nil, math.huge
        end

        return ClosestBaseColor(value)
    end

    local byText = FromText(value)

    if byText then
        return byText, 0
    end

    return nil, math.huge
end

local function GetObjectColorName(object)
    local current = object

    for _ = 1, 5 do
        if not current then
            break
        end

        local colorName = GetDirectColorName(current.Name)

        if colorName then
            return colorName
        end

        current = current.Parent
    end

    return nil
end

local function GetWorldParts()
    local parts = {}

    for _, object in ipairs(workspace:GetDescendants()) do
        if object:IsA("BasePart") then
            table.insert(parts, object)
        end
    end

    return parts
end

local function DetectBaseColorAround(position, parts, radius)
    if typeof(position) ~= "Vector3" then
        return nil, nil, 0
    end

    parts = parts or GetWorldParts()
    radius = tonumber(radius) or 125

    local scores = {}
    local strongestColor = {}
    local strongestWeight = {}

    for _, part in ipairs(parts) do
        if part.Parent
        and part.Transparency < 0.97 then
            local distance = (part.Position - position).Magnitude

            if distance <= radius then
                local colorName, hueDistance = ClosestBaseColor(part.Color)
                local namedColor = GetObjectColorName(part)

                if namedColor then
                    colorName = namedColor
                    hueDistance = 0
                end

                if colorName then
                    local size = part.Size
                    local horizontalArea = math.max(1, size.X * size.Z)
                    local sideArea = math.max(size.X * size.Y, size.Z * size.Y)
                    local area = math.min(5000, math.max(horizontalArea, sideArea * 0.45))
                    local _, saturation, value = part.Color:ToHSV()
                    local distanceWeight = 1 / (1 + distance / 24)
                    local materialWeight = part.Material == Enum.Material.Grass and 0.025 or 1
                    local transparencyWeight = math.max(0.08, 1 - part.Transparency)
                    local namedWeight = namedColor and 4.5 or 1
                    local spawnWeight = part:IsA("SpawnLocation") and 0.18 or 1
                    local weight = area
                        * distanceWeight
                        * materialWeight
                        * transparencyWeight
                        * namedWeight
                        * spawnWeight
                        * (0.35 + saturation)
                        * (0.35 + value)
                        * math.max(0.25, 1 - (hueDistance or 0))

                    scores[colorName] = (scores[colorName] or 0) + weight

                    if weight > (strongestWeight[colorName] or 0) then
                        strongestWeight[colorName] = weight
                        strongestColor[colorName] = part.Color
                    end
                end
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

    return bestName,
        bestName and strongestColor[bestName] or nil,
        bestScore
end

local function DetectSpawnColor(spawn, parts)
    local colorName, color, score = DetectBaseColorAround(
        spawn.Position,
        parts,
        135
    )

    if colorName then
        return colorName, color, score
    end

    local ok, teamColor = pcall(function()
        return spawn.TeamColor
    end)

    if ok then
        colorName = GetDirectColorName(teamColor)

        if colorName then
            return colorName, BasePaletteByName[colorName], 1
        end
    end

    colorName = GetDirectColorName(spawn.Color)

    if colorName then
        return colorName, spawn.Color, 0.5
    end

    return nil, nil, 0
end

local function BuildGeometryBaseRecords(parts)
    local candidates = {}

    for _, part in ipairs(parts) do
        if part.Parent
        and part.Anchored
        and part.CanCollide
        and part.Transparency < 0.9 then
            local colorName = GetObjectColorName(part)
            local hueName = ClosestBaseColor(part.Color)
            colorName = colorName or hueName

            if colorName then
                local size = part.Size
                local area = size.X * size.Z
                local _, saturation = part.Color:ToHSV()
                local nameBlob = NormalizeName(part.Name .. " " .. tostring(part.Parent and part.Parent.Name or ""))
                local score = area * math.max(0.2, saturation)

                if string.find(nameBlob, "base", 1, true)
                or string.find(nameBlob, "spawn", 1, true)
                or string.find(nameBlob, "team", 1, true) then
                    score *= 5
                end

                if part.Material == Enum.Material.Grass then
                    score *= 0.03
                end

                if area >= 180
                and score >= 80 then
                    table.insert(candidates, {
                        Part = part,
                        Position = part.Position,
                        ColorName = colorName,
                        Color = part.Color,
                        Score = score
                    })
                end
            end
        end
    end

    table.sort(candidates, function(a, b)
        return a.Score > b.Score
    end)

    local records = {}

    for _, candidate in ipairs(candidates) do
        local farEnough = true

        for _, record in ipairs(records) do
            if (record.Position - candidate.Position).Magnitude < 55 then
                farEnough = false
                break
            end
        end

        if farEnough then
            table.insert(records, {
                Spawn = nil,
                Anchor = candidate.Part,
                Position = candidate.Position,
                ColorName = candidate.ColorName,
                Color = candidate.Color,
                Score = candidate.Score
            })

            if #records >= 8 then
                break
            end
        end
    end

    return records
end

local function BuildBaseRecords()
    local spawns = GetSpawnLocations()
    local records = {}

    for _, entry in ipairs(BasePalette) do
        local position = BasePositionByName[entry.Name]
        local nearestSpawn = nil
        local nearestDistance = math.huge

        for _, spawn in ipairs(spawns) do
            local delta = Vector3.new(
                spawn.Position.X - position.X,
                0,
                spawn.Position.Z - position.Z
            )
            local distance = delta.Magnitude

            if distance < nearestDistance then
                nearestDistance = distance
                nearestSpawn = spawn
            end
        end

        if nearestDistance > 135 then
            nearestSpawn = nil
        end

        table.insert(records, {
            Spawn = nearestSpawn,
            Anchor = nearestSpawn,
            Position = position,
            ColorName = entry.Name,
            Color = entry.Color,
            Score = 100000 - math.min(nearestDistance, 99999)
        })
    end

    return records
end

local function GetBaseRecords(force)
    if not force
    and BaseRecordsCache
    and os.clock() - BaseRecordsCacheTime < 4 then
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

    for _ = 1, 10 do
        local result = workspace:Raycast(
            origin,
            Vector3.new(0, -1200, 0),
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
        else
            return nil
        end
    end

    return nil
end

local function GetPartTopCFrame(part)
    if not part
    or not part:IsA("BasePart") then
        return nil
    end

    local top = part.Position
        + part.CFrame.UpVector * (part.Size.Y * 0.5 + 4)

    return CFrame.new(top)
end

local function GetSpawnCFrame(spawn)
    if not spawn
    or not spawn:IsA("BasePart") then
        return nil
    end

    return GetPartTopCFrame(spawn)
end

local function GetRecordSpawnCFrame(record)
    if not record then
        return nil
    end

    if record.Spawn
    and record.Spawn.Parent then
        return GetSpawnCFrame(record.Spawn)
    end

    if record.Anchor
    and record.Anchor.Parent then
        return GetPartTopCFrame(record.Anchor)
    end

    local ground = RaycastGroundAt(record.Position, record.Position.Y + 180)

    if ground then
        return CFrame.new(ground + Vector3.new(0, 4, 0))
    end

    return CFrame.new(record.Position + Vector3.new(0, 4, 0))
end

local function GetBaseRecordByColor(colorName)
    colorName = string.upper(tostring(colorName or ""))
    local best = nil
    local bestScore = -math.huge

    for _, record in ipairs(GetBaseRecords()) do
        if record.ColorName == colorName
        and (record.Score or 0) > bestScore then
            best = record
            bestScore = record.Score or 0
        end
    end

    return best
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

    return closest, closestDistance
end

local function ValueMatchesPlayer(value, player)
    if value == player then
        return true
    end

    if typeof(value) == "string" then
        local lower = string.lower(value)
        return lower == string.lower(player.Name)
            or lower == string.lower(player.DisplayName)
            or lower == tostring(player.UserId)
    end

    if typeof(value) == "number" then
        return math.floor(value) == player.UserId
    end

    return false
end

local function ContainerMatchesPlayer(container, player)
    if not container
    or container == workspace then
        return false
    end

    for key, value in pairs(container:GetAttributes()) do
        local lowerKey = string.lower(tostring(key))

        if string.find(lowerKey, "owner", 1, true)
        or string.find(lowerKey, "player", 1, true)
        or string.find(lowerKey, "user", 1, true) then
            if ValueMatchesPlayer(value, player) then
                return true
            end
        end
    end

    local count = 0

    for _, object in ipairs(container:GetDescendants()) do
        count += 1

        if count > 180 then
            break
        end

        if object:IsA("ObjectValue") then
            if object.Value == player then
                return true
            end
        elseif object:IsA("StringValue")
        or object:IsA("IntValue")
        or object:IsA("NumberValue") then
            local lowerName = string.lower(object.Name)

            if ValueMatchesPlayer(object.Value, player) then
                if string.find(lowerName, "owner", 1, true)
                or string.find(lowerName, "player", 1, true)
                or string.find(lowerName, "user", 1, true)
                or string.find(lowerName, "name", 1, true)
                or string.find(lowerName, "base", 1, true) then
                    return true
                end
            end
        elseif object:IsA("TextLabel")
        or object:IsA("TextButton")
        or object:IsA("TextBox") then
            local text = tostring(object.Text or "")
            local lowerText = string.lower(text)

            if lowerText == string.lower(player.Name)
            or lowerText == string.lower(player.DisplayName)
            or string.find(lowerText, "@" .. string.lower(player.Name), 1, true) then
                return true
            end
        end
    end

    return false
end

local function FindTaggedBaseRecord(player)
    for _, record in ipairs(GetBaseRecords()) do
        local current = record.Spawn or record.Anchor

        for _ = 1, 4 do
            if not current
            or current == workspace then
                break
            end

            if ContainerMatchesPlayer(current, player) then
                return record
            end

            current = current.Parent
        end
    end

    return nil
end

local PlayerRespawnCFrameCache = setmetatable({}, {__mode = "k"})
local LocalSpawnCFrame = nil

local function GetBaseRecordFromPosition(position, maxDistance)
    if typeof(position) ~= "Vector3" then
        return nil
    end

    local record, distance = GetNearestBaseRecord(
        position,
        tonumber(maxDistance) or 145
    )

    if record
    and distance <= (tonumber(maxDistance) or 145) then
        return record
    end

    return nil
end

local function GetBaseRecordFromTeamColor(player)
    if not player then
        return nil
    end

    local values = {}

    pcall(function()
        table.insert(values, player.TeamColor)
    end)

    if player.Team then
        pcall(function()
            table.insert(values, player.Team.TeamColor)
        end)

        pcall(function()
            table.insert(values, player.Team.Color)
        end)
    end

    for _, value in ipairs(values) do
        local colorName = GetDirectColorName(value)

        if colorName then
            local record = GetBaseRecordByColor(colorName)

            if record then
                return record
            end
        end
    end

    return nil
end

local function GetBaseRecordFromTeamName(player)
    if not player
    or not player.Team then
        return nil
    end

    local colorName = GetDirectColorName(player.Team.Name)

    if colorName then
        return GetBaseRecordByColor(colorName)
    end

    return nil
end

local function GetBaseRecordFromSpawnTeamColor(player)
    if not player then
        return nil, nil
    end

    local playerTeamColor = nil

    pcall(function()
        playerTeamColor = player.TeamColor
    end)

    if typeof(playerTeamColor) ~= "BrickColor" then
        return nil, nil
    end

    local matches = {}

    for _, record in ipairs(GetBaseRecords()) do
        local spawn = record.Spawn

        if spawn
        and spawn.Parent
        and spawn:IsA("SpawnLocation") then
            local sameColor = false

            pcall(function()
                sameColor = spawn.TeamColor == playerTeamColor
            end)

            if sameColor then
                table.insert(matches, {
                    Record = record,
                    Spawn = spawn
                })
            end
        end
    end

    if #matches == 1 then
        return matches[1].Record, matches[1].Spawn
    end

    if #matches > 1 then
        local wantedName = nil

        if player.Team then
            wantedName = GetDirectColorName(player.Team.Name)
        end

        if not wantedName then
            wantedName = GetDirectColorName(playerTeamColor)
        end

        if wantedName then
            for _, match in ipairs(matches) do
                if match.Record.ColorName == wantedName then
                    return match.Record, match.Spawn
                end
            end
        end
    end

    return nil, nil
end

local function GetBaseRecordFromPlayerValues(player)
    if not player then
        return nil
    end

    local checked = 0

    for _, object in ipairs(player:GetDescendants()) do
        checked += 1

        if checked > 180 then
            break
        end

        local value = nil

        if object:IsA("StringValue")
        or object:IsA("Color3Value")
        or object:IsA("BrickColorValue") then
            value = object.Value
        end

        if value ~= nil then
            local blob = NormalizeName(object.Name)

            if string.find(blob, "base", 1, true)
            or string.find(blob, "team", 1, true)
            or string.find(blob, "color", 1, true)
            or string.find(blob, "spawn", 1, true) then
                local colorName = GetDirectColorName(value)

                if colorName then
                    local record = GetBaseRecordByColor(colorName)

                    if record then
                        return record
                    end
                end
            end
        end
    end

    return nil
end

local function GetBaseRecordFromAttributes(player)
    if not player then
        return nil
    end

    for key, value in pairs(player:GetAttributes()) do
        local lowerKey = string.lower(tostring(key))

        if string.find(lowerKey, "base", 1, true)
        or string.find(lowerKey, "team", 1, true)
        or string.find(lowerKey, "color", 1, true)
        or string.find(lowerKey, "spawn", 1, true) then
            local colorName = GetDirectColorName(value)

            if colorName then
                local record = GetBaseRecordByColor(colorName)

                if record then
                    return record
                end
            end
        end
    end

    return nil
end

local function CachePlayerBase(player, allowCurrentPosition)
    if not player then
        return nil
    end

    local respawn = nil

    pcall(function()
        respawn = player.RespawnLocation
    end)

    if respawn
    and respawn:IsA("BasePart") then
        local record = GetBaseRecordFromPosition(respawn.Position, 160)
        local spawnCFrame = GetSpawnCFrame(respawn)

        if typeof(spawnCFrame) == "CFrame" then
            PlayerRespawnCFrameCache[player] = spawnCFrame

            if player == Player then
                LocalSpawnCFrame = spawnCFrame
            end
        end

        if record then
            PlayerBaseCache[player] = record
            return record
        end
    end

    local spawnRecord, spawnLocation = GetBaseRecordFromSpawnTeamColor(player)

    if spawnRecord then
        PlayerBaseCache[player] = spawnRecord

        local spawnCFrame = GetSpawnCFrame(spawnLocation)

        if typeof(spawnCFrame) == "CFrame" then
            PlayerRespawnCFrameCache[player] = spawnCFrame

            if player == Player then
                LocalSpawnCFrame = spawnCFrame
            end
        end

        return spawnRecord
    end

    local teamRecord = GetBaseRecordFromTeamName(player)

    if teamRecord then
        PlayerBaseCache[player] = teamRecord
        return teamRecord
    end

    local teamColorRecord = GetBaseRecordFromTeamColor(player)

    if teamColorRecord then
        PlayerBaseCache[player] = teamColorRecord
        return teamColorRecord
    end

    local attributeRecord = GetBaseRecordFromAttributes(player)

    if attributeRecord then
        PlayerBaseCache[player] = attributeRecord
        return attributeRecord
    end

    local valueRecord = GetBaseRecordFromPlayerValues(player)

    if valueRecord then
        PlayerBaseCache[player] = valueRecord
        return valueRecord
    end

    local taggedRecord = FindTaggedBaseRecord(player)

    if taggedRecord then
        PlayerBaseCache[player] = taggedRecord
        return taggedRecord
    end

    local savedSpawn = PlayerRespawnCFrameCache[player]

    if typeof(savedSpawn) == "CFrame" then
        local record = GetBaseRecordFromPosition(savedSpawn.Position, 150)

        if record then
            PlayerBaseCache[player] = record
            return record
        end
    end

    local cached = PlayerBaseCache[player]

    if cached
    and cached.Position then
        return cached
    end

    if allowCurrentPosition then
        local root = GetCharacterRoot(player)
        local character = player.Character
        local forceField = character and character:FindFirstChildOfClass("ForceField")

        if root and forceField then
            local record = GetBaseRecordFromPosition(root.Position, 125)

            if record then
                PlayerBaseCache[player] = record
                PlayerRespawnCFrameCache[player] = root.CFrame

                if player == Player then
                    LocalSpawnCFrame = root.CFrame
                end

                return record
            end
        end
    end

    return nil
end

local function GetPlayerBaseRecord(player)
    if not player then
        return nil
    end

    return CachePlayerBase(player, false)
end

local function GetPlayerBaseCFrame()
    local respawn = nil

    pcall(function()
        respawn = Player.RespawnLocation
    end)

    if respawn
    and respawn:IsA("BasePart") then
        local cframe = GetSpawnCFrame(respawn)

        if typeof(cframe) == "CFrame" then
            PlayerRespawnCFrameCache[Player] = cframe
            LocalSpawnCFrame = cframe
            return cframe
        end
    end

    local spawnRecord, spawnLocation = GetBaseRecordFromSpawnTeamColor(Player)

    if spawnLocation then
        local cframe = GetSpawnCFrame(spawnLocation)

        if typeof(cframe) == "CFrame" then
            PlayerBaseCache[Player] = spawnRecord
            PlayerRespawnCFrameCache[Player] = cframe
            LocalSpawnCFrame = cframe
            return cframe
        end
    end

    local savedSpawn = PlayerRespawnCFrameCache[Player]

    if typeof(savedSpawn) == "CFrame" then
        return savedSpawn
    end

    if typeof(LocalSpawnCFrame) == "CFrame" then
        return LocalSpawnCFrame
    end

    local record = PlayerBaseCache[Player]
        or GetBaseRecordFromTeamName(Player)
        or GetBaseRecordFromTeamColor(Player)
        or GetBaseRecordFromAttributes(Player)
        or GetBaseRecordFromPlayerValues(Player)
        or FindTaggedBaseRecord(Player)

    if record then
        local spawn = record.Spawn

        if spawn
        and spawn.Parent
        and spawn:IsA("BasePart") then
            local cframe = GetSpawnCFrame(spawn)

            if typeof(cframe) == "CFrame" then
                PlayerBaseCache[Player] = record
                PlayerRespawnCFrameCache[Player] = cframe
                LocalSpawnCFrame = cframe
                return cframe
            end
        end
    end

    return nil
end

local function GetObjectTopPosition(object)
    if object:IsA("BasePart") then
        return object.Position
            + object.CFrame.UpVector * (object.Size.Y * 0.5),
            object.Size.X * object.Size.Z
    end

    if object:IsA("Model") then
        local ok, cframe, size = pcall(function()
            local cf, sz = object:GetBoundingBox()
            return cf, sz
        end)

        if ok
        and cframe
        and size then
            return cframe.Position
                + Vector3.new(0, size.Y * 0.5, 0),
                size.X * size.Z
        end
    end

    return nil, 0
end

local function FindCenterAnchor()
    local bestPosition = nil
    local bestScore = 0

    for _, object in ipairs(workspace:GetDescendants()) do
        if object:IsA("BasePart")
        or object:IsA("Model") then
            local name = NormalizeName(object.Name)
            local nameScore = 0

            if name == "center"
            or name == "middle"
            or name == "middlearea"
            or name == "centerarea" then
                nameScore = 1000
            elseif string.find(name, "center", 1, true)
            or string.find(name, "middle", 1, true) then
                nameScore = 600
            elseif string.find(name, "arena", 1, true)
            or string.find(name, "island", 1, true) then
                nameScore = 250
            end

            if nameScore > 0 then
                local position, area = GetObjectTopPosition(object)

                if position then
                    local score = nameScore + math.min(area, 100000) * 0.01

                    if score > bestScore then
                        bestScore = score
                        bestPosition = position
                    end
                end
            end
        end
    end

    if bestPosition then
        return bestPosition
    end

    return nil
end

local function GetCenterCFrame()
    return CFrame.new(CenterPosition)
end

local function GetBaseFrontCFrame(record)
    if not record
    or typeof(record.Position) ~= "Vector3" then
        return nil
    end

    return CFrame.new(
        record.Position,
        Vector3.new(
            CenterPosition.X,
            record.Position.Y,
            CenterPosition.Z
        )
    )
end

local function GetPlayerBaseColor(player)
    local record = GetPlayerBaseRecord(player)

    if not record then
        local spawnRecord = select(1, GetBaseRecordFromSpawnTeamColor(player))

        if spawnRecord then
            PlayerBaseCache[player] = spawnRecord
            record = spawnRecord
        end
    end

    if not record then
        local root = GetCharacterRoot(player)
        local character = player.Character
        local forceField = character and character:FindFirstChildOfClass("ForceField")

        if root and forceField then
            record = GetBaseRecordFromPosition(root.Position, 125)

            if record then
                PlayerBaseCache[player] = record
                PlayerRespawnCFrameCache[player] = root.CFrame
            end
        end
    end

    if record
    and record.ColorName
    and BasePaletteByName[record.ColorName] then
        return BasePaletteByName[record.ColorName], record.ColorName
    end

    local directName = nil

    if player.Team then
        directName = GetDirectColorName(player.Team.Name)
    end

    if not directName then
        local teamColor = nil

        pcall(function()
            teamColor = player.TeamColor
        end)

        directName = GetDirectColorName(teamColor)
    end

    if directName
    and BasePaletteByName[directName] then
        return BasePaletteByName[directName], directName
    end

    return nil, nil
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

    if not color then
        ClearLBBESPPlayer(player)
        return
    end

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

local function CaptureCharacterBase(player, character)
    task.spawn(function()
        local root = character
            and character:WaitForChild("HumanoidRootPart", 8)

        if not root
        or character ~= player.Character then
            return
        end

        task.wait(0.15)

        if not root.Parent
        or character ~= player.Character then
            return
        end

        PlayerRespawnCFrameCache[player] = root.CFrame

        if player == Player then
            LocalSpawnCFrame = root.CFrame
        end

        local record = GetBaseRecordFromPosition(root.Position, 150)
            or select(1, GetBaseRecordFromSpawnTeamColor(player))
            or GetBaseRecordFromTeamName(player)
            or GetBaseRecordFromTeamColor(player)
            or GetBaseRecordFromAttributes(player)
            or GetBaseRecordFromPlayerValues(player)

        if record then
            PlayerBaseCache[player] = record
        end
    end)
end

local function HookPlayerBaseTracking(player)
    if not player then
        return
    end

    local respawn = player.RespawnLocation

    if respawn
    and respawn:IsA("BasePart") then
        local respawnCFrame = GetSpawnCFrame(respawn)

        if respawnCFrame then
            PlayerRespawnCFrameCache[player] = respawnCFrame

            if player == Player then
                LocalSpawnCFrame = respawnCFrame
            end
        end
    end

    CachePlayerBase(player, false)

    if player.Character then
        local root = GetCharacterRoot(player)
        local forceField = player.Character:FindFirstChildOfClass("ForceField")

        if root
        and forceField then
            PlayerRespawnCFrameCache[player] = root.CFrame

            if player == Player then
                LocalSpawnCFrame = root.CFrame
            end

            local record = GetBaseRecordFromPosition(root.Position, 125)
                or select(1, GetBaseRecordFromSpawnTeamColor(player))

            if record then
                PlayerBaseCache[player] = record
            end
        elseif not PlayerBaseCache[player] then
            local record = select(1, GetBaseRecordFromSpawnTeamColor(player))
                or GetBaseRecordFromTeamName(player)
                or GetBaseRecordFromTeamColor(player)

            if record then
                PlayerBaseCache[player] = record
            end
        end
    end

    TrackConnection(player.CharacterAdded:Connect(function(character)
        CaptureCharacterBase(player, character)
    end))

    pcall(function()
        TrackConnection(player:GetPropertyChangedSignal("RespawnLocation"):Connect(function()
            local location = player.RespawnLocation

            if location
            and location:IsA("BasePart") then
                local cframe = GetSpawnCFrame(location)

                if cframe then
                    PlayerRespawnCFrameCache[player] = cframe

                    if player == Player then
                        LocalSpawnCFrame = cframe
                    end
                end
            end

            CachePlayerBase(player, false)
        end))
    end)

    pcall(function()
        TrackConnection(player:GetPropertyChangedSignal("Team"):Connect(function()
            PlayerBaseCache[player] = nil
            CachePlayerBase(player, false)
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
    PlayerRespawnCFrameCache[player] = nil
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

GetBaseRecords(true)

for _, entry in ipairs(BasePalette) do
    LBBCreateButton(entry.Name, GamePage, function()
        local record = GetBaseRecordByColor(entry.Name)
        TeleportTo(
            GetBaseFrontCFrame(record),
            entry.Name
        )
    end)
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
