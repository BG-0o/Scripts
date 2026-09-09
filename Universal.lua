if getgenv().ToxUniversalLoaded then
    return
end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")
local SoundService = game:GetService("SoundService")
local TextChatService = game:GetService("TextChatService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local NDSPlaceId = 189707

if game.PlaceId ~= NDSPlaceId then
    local env = getgenv()

    if env.SetNDSNoTP then
        pcall(function()
            env.SetNDSNoTP(false, true)
        end)
    end

    if env.Settings then
        env.Settings.NDSNoTP = false
    end
end

Settings.WalkFling = Settings.WalkFling == true

local HumanoidDefaults = setmetatable({}, {__mode = "k"})
local NoclipDefaults = setmetatable({}, {__mode = "k"})
local AntiFlingDefaults = setmetatable({}, {__mode = "k"})
local HitboxDefaults = setmetatable({}, {__mode = "k"})

local FOVDefault = Camera.FieldOfView
local FOVCaptured = false
local ShiftLockDefaults = nil
local isShiftLockActive = false

local ToxChatGui = getgenv().ToxChatGui
local JoinGamesGui = getgenv().JoinGamesGui
local JoinGamesScroll = getgenv().JoinGamesScroll
local JoinGameIdBox = getgenv().JoinGameIdBox
local JoinGameAddButton = getgenv().JoinGameAddButton
local SavedJoinGames = getgenv().SavedJoinGames or {}
local CheckMusicIDsBtn = getgenv().CheckMusicIDsBtn
local SetMusicIDStatus = getgenv().SetMusicIDStatus

getgenv().MusicIDStatus = {}
local MusicIDStatus = getgenv().MusicIDStatus
local MusicCheckRunning = false
local MusicCheckGeneration = 0
local MusicInitialNoticeShown = false

local function GetSavedMusicIDs()
    local ids = {}
    local seen = {}

    for _, item in ipairs(SavedIDs or {}) do
        local id = nil

        if typeof(item) == "table" then
            id = tonumber(item.id)
        else
            id = tonumber(item)
        end

        if id and not seen[id] then
            seen[id] = true
            table.insert(ids, id)
        end
    end

    return ids
end

local function IsMusicIDActive(id)
    local success, info = pcall(function()
        return MarketplaceService:GetProductInfo(id, Enum.InfoType.Asset)
    end)

    if not success or typeof(info) ~= "table" then
        return false
    end

    if tonumber(info.AssetTypeId) ~= 3 then
        return false
    end

    local name = string.lower(tostring(info.Name or ""))

    if name == ""
    or string.find(name, "content deleted", 1, true)
    or string.find(name, "[deleted]", 1, true)
    or string.find(name, "[ content deleted ]", 1, true)
    or string.find(name, "deleted", 1, true) == 1 then
        return false
    end

    return true
end

local function ApplyMusicStatus(id, status)
    MusicIDStatus[tostring(id)] = status

    if SetMusicIDStatus then
        SetMusicIDStatus(id, status)
    end
end

local function CheckSavedMusicIDs(force)
    if MusicCheckRunning and not force then
        return
    end

    local ids = GetSavedMusicIDs()

    if #ids == 0 then
        if CheckMusicIDsBtn then
            CheckMusicIDsBtn.Text = "Check IDs"
        end
        return
    end

    MusicCheckGeneration = MusicCheckGeneration + 1
    local generation = MusicCheckGeneration
    MusicCheckRunning = true

    if CheckMusicIDsBtn then
        CheckMusicIDsBtn.Text = "Checking..."
        CheckMusicIDsBtn.TextColor3 = Color3.fromRGB(255, 215, 70)
        CheckMusicIDsBtn.Active = false
    end

    for _, id in ipairs(ids) do
        if force or MusicIDStatus[tostring(id)] == nil then
            ApplyMusicStatus(id, "checking")
        else
            ApplyMusicStatus(id, MusicIDStatus[tostring(id)])
        end
    end

    task.spawn(function()
        local activeCount = 0
        local unavailableCount = 0

        for _, id in ipairs(ids) do
            if generation ~= MusicCheckGeneration then
                return
            end

            local key = tostring(id)
            local status = MusicIDStatus[key]

            if force or status == nil or status == "checking" then
                status = IsMusicIDActive(id)
                ApplyMusicStatus(id, status)
                task.wait(0.12)
            end

            if status == true then
                activeCount = activeCount + 1
            elseif status == false then
                unavailableCount = unavailableCount + 1
            end
        end

        if generation ~= MusicCheckGeneration then
            return
        end

        MusicCheckRunning = false

        if CheckMusicIDsBtn and CheckMusicIDsBtn.Parent then
            CheckMusicIDsBtn.Text = "Check IDs"
            CheckMusicIDsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            CheckMusicIDsBtn.Active = true
        end

        if not MusicInitialNoticeShown then
            MusicInitialNoticeShown = true
            CustomNotify(
                "Music IDs: "
                    .. tostring(activeCount)
                    .. " active | "
                    .. tostring(unavailableCount)
                    .. " unavailable",
                unavailableCount > 0
                    and Color3.fromRGB(255, 180, 70)
                    or Color3.fromRGB(100, 255, 100)
            )
        end
    end)
end

if CheckMusicIDsBtn then
    CheckMusicIDsBtn.MouseButton1Click:Connect(function()
        CheckSavedMusicIDs(true)
    end)
end

if MusicGui then
    AddConnection(MusicGui:GetPropertyChangedSignal("Visible"):Connect(function()
        if MusicGui.Visible then
            task.defer(function()
                CheckSavedMusicIDs(false)
            end)
        end
    end))
end

task.delay(1, function()
    CheckSavedMusicIDs(true)
end)

local RequestFunction = nil

pcall(function()
    local env = getgenv()

    if syn and syn.request then
        RequestFunction = syn.request
    elseif http and http.request then
        RequestFunction = http.request
    elseif fluxus and fluxus.request then
        RequestFunction = fluxus.request
    elseif krnl and krnl.request then
        RequestFunction = krnl.request
    elseif env and env.request then
        RequestFunction = env.request
    elseif env and env.http_request then
        RequestFunction = env.http_request
    elseif http_request then
        RequestFunction = http_request
    elseif request then
        RequestFunction = request
    end
end)

getgenv().ToxRequestFunction = RequestFunction


local function GetHumanoidDefaults(hum)
    if not hum then return nil end

    if not HumanoidDefaults[hum] then
        HumanoidDefaults[hum] = {
            WalkSpeed = hum.WalkSpeed,
            UseJumpPower = hum.UseJumpPower,
            JumpPower = hum.JumpPower,
            JumpHeight = hum.JumpHeight
        }
    end

    return HumanoidDefaults[hum]
end

local function RestoreSpeed()
    local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
    local defaults = hum and HumanoidDefaults[hum]

    if hum and defaults then
        hum.WalkSpeed = defaults.WalkSpeed
    end
end

local function RestoreJump()
    local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
    local defaults = hum and HumanoidDefaults[hum]

    if hum and defaults then
        hum.UseJumpPower = defaults.UseJumpPower
        hum.JumpPower = defaults.JumpPower
        hum.JumpHeight = defaults.JumpHeight
    end
end

local function CaptureNoclipDefaults()
    if not Player.Character then return end

    for _, part in ipairs(Player.Character:GetDescendants()) do
        if part:IsA("BasePart") and NoclipDefaults[part] == nil then
            NoclipDefaults[part] = part.CanCollide
        end
    end
end

local function RestoreNoclipDefaults()
    for part, canCollide in pairs(NoclipDefaults) do
        if part and part.Parent then
            part.CanCollide = canCollide
        end
        NoclipDefaults[part] = nil
    end
end

local function RestoreAntiFlingDefaults()
    for part, canCollide in pairs(AntiFlingDefaults) do
        if part and part.Parent then
            part.CanCollide = canCollide
        end
        AntiFlingDefaults[part] = nil
    end
end

local function RestoreHitboxDefaults()
    for hrp, data in pairs(HitboxDefaults) do
        if hrp and hrp.Parent then
            hrp.Size = data.Size
            hrp.Transparency = data.Transparency
            hrp.CanCollide = data.CanCollide
        end
        HitboxDefaults[hrp] = nil
    end
end

local function CaptureFOVDefault()
    if not FOVCaptured then
        FOVDefault = Camera.FieldOfView
        FOVCaptured = true
    end
end

local function RestoreFOVDefault()
    if FOVCaptured then
        Camera.FieldOfView = FOVDefault
        FOVCaptured = false
    end
end

local function CaptureShiftLockDefaults()
    if not ShiftLockDefaults then
        ShiftLockDefaults = {
            DevEnableMouseLock = Player.DevEnableMouseLock,
            MouseBehavior = UserInputService.MouseBehavior
        }
    end
end

local function RestoreShiftLockDefaults()
    if ShiftLockDefaults then
        pcall(function()
            Player.DevEnableMouseLock = ShiftLockDefaults.DevEnableMouseLock
        end)

        pcall(function()
            UserInputService.MouseBehavior = ShiftLockDefaults.MouseBehavior
        end)

        ShiftLockDefaults = nil
    end

    isShiftLockActive = false
end

local SubGuiControls = {}

local function FindSubGuiTopBar(gui)
    if not gui then return nil end

    for _, child in ipairs(gui:GetChildren()) do
        if child:IsA("Frame") and child.Size.Y.Offset == 32 and child.Position.Y.Offset == 0 then
            return child
        end
    end

    return nil
end

local function SetSubGuiContentVisible(data, visible)
    local gui = data.Gui
    local topBar = data.TopBar

    if visible then
        for child, wasVisible in pairs(data.ChildVisibility) do
            if child and child.Parent == gui and child:IsA("GuiObject") then
                child.Visible = wasVisible
            end
        end

        data.ChildVisibility = {}
    else
        data.ChildVisibility = {}

        for _, child in ipairs(gui:GetChildren()) do
            if child:IsA("GuiObject") and child ~= topBar then
                data.ChildVisibility[child] = child.Visible
                child.Visible = false
            end
        end
    end
end

local function SetSubGuiMinimized(data, minimized)
    if not data or not data.Gui then
        return
    end

    local gui = data.Gui

    if minimized then
        if not data.Minimized and (gui.Size.Y.Offset > 32 or gui.Size.Y.Scale ~= 0) then
            data.ExpandedSize = gui.Size
        end

        gui.ClipsDescendants = true
        SetSubGuiContentVisible(data, false)
        gui.Size = UDim2.new(data.ExpandedSize.X.Scale, data.ExpandedSize.X.Offset, 0, 32)
        data.Button.Text = "+"
        data.Minimized = true
    else
        gui.Size = data.ExpandedSize
        SetSubGuiContentVisible(data, true)
        data.Button.Text = "-"
        data.Minimized = false
    end
end

local function RegisterSubGuiMinimize(gui, buttonOffset)
    if not gui then return nil end

    local topBar = FindSubGuiTopBar(gui)
    if not topBar then return nil end

    for _, child in ipairs(topBar:GetChildren()) do
        if child:IsA("TextButton") and (child.Text == "-" or child.Text == "+") then
            child:Destroy()
        end
    end

    for _, child in ipairs(topBar:GetChildren()) do
        if child:IsA("TextLabel") then
            child.Size = UDim2.new(1, math.min(child.Size.X.Offset, -70), child.Size.Y.Scale, child.Size.Y.Offset)
            break
        end
    end

    local button = Instance.new("TextButton")
    button.Name = "ToxSubGuiMinimize"
    button.Size = UDim2.new(0, 24, 0, 22)
    button.Position = UDim2.new(1, buttonOffset, 0.5, -11)
    button.BackgroundColor3 = Color3.fromRGB(22, 22, 35)
    button.BorderSizePixel = 0
    button.Text = "-"
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 14
    button.AutoButtonColor = false
    button.Parent = topBar

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = button

    local data = {
        Gui = gui,
        TopBar = topBar,
        ExpandedSize = gui.Size,
        Button = button,
        Minimized = false,
        ChildVisibility = {}
    }

    SubGuiControls[gui] = data

    button.MouseButton1Click:Connect(function()
        SetSubGuiMinimized(data, not data.Minimized)
    end)

    return data
end

RegisterSubGuiMinimize(ChatLogGui, -88)
RegisterSubGuiMinimize(MusicGui, -52)
RegisterSubGuiMinimize(WaypointsGui, -52)
RegisterSubGuiMinimize(ToxChatGui, -52)
RegisterSubGuiMinimize(JoinGamesGui, -52)

getgenv().ToxLinkedSubGuis = getgenv().ToxLinkedSubGuis or {}

getgenv().RegisterToxSubGuiMinimize = function(gui, buttonOffset)
    if not gui then
        return nil
    end

    local existing = SubGuiControls[gui]

    if existing then
        return existing
    end

    return RegisterSubGuiMinimize(gui, buttonOffset or -52)
end

getgenv().RegisterToxLinkedSubGui = function(key, gui)
    if not key or not gui then
        return
    end

    getgenv().ToxLinkedSubGuis[tostring(key)] = gui
end

for _, page in pairs(Pages) do
    for _, child in ipairs(page:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextButton") then
            child:Destroy()
        end
    end
end

local JoinTargetCache = nil
local JoinLookupGeneration = 0

local JoinTargetBox = nil
local JoinPlayingLabel = nil
local JoinPlayerButton = nil
local JoinGamesButton = nil

local function CleanJoinTarget(text)
    text = tostring(text or "")
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    text = text:gsub("^@", "")
    return text
end

local function ResolveJoinUserId(text)
    local cleaned = CleanJoinTarget(text)

    if cleaned == "" then
        return nil, "Enter nick or ID"
    end

    local numeric = tonumber(cleaned)

    if numeric and numeric > 0 then
        return math.floor(numeric)
    end

    local ok, userId = pcall(function()
        return Players:GetUserIdFromNameAsync(cleaned)
    end)

    if ok and tonumber(userId) then
        return tonumber(userId)
    end

    return nil, "User not found"
end

local function PresenceRequestOnce(userId)
    local requestData = {
        Url = "https://presence.roblox.com/v1/presence/users",
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json"
        },
        Body = HttpService:JSONEncode({userIds = {userId}})
    }

    local ok = false
    local response = nil

    if RequestFunction then
        ok, response = pcall(function()
            return RequestFunction(requestData)
        end)

        if not ok or typeof(response) ~= "table" then
            requestData.URL = requestData.Url
            requestData.Url = nil

            ok, response = pcall(function()
                return RequestFunction(requestData)
            end)
        end
    end

    local body = nil

    if ok and typeof(response) == "table" then
        body = response.Body or response.body
    end

    if typeof(body) ~= "string" or body == "" then
        local postOk, postBody = pcall(function()
            return HttpService:PostAsync(
                "https://presence.roblox.com/v1/presence/users",
                HttpService:JSONEncode({userIds = {userId}}),
                Enum.HttpContentType.ApplicationJson
            )
        end)

        if postOk and typeof(postBody) == "string" then
            body = postBody
        end
    end

    if typeof(body) ~= "string" or body == "" then
        return nil
    end

    local decodedOk, decoded = pcall(function()
        return HttpService:JSONDecode(body)
    end)

    if not decodedOk or typeof(decoded) ~= "table" then
        return nil
    end

    local presence = decoded.userPresences and decoded.userPresences[1]

    if typeof(presence) ~= "table" then
        return nil
    end

    return presence
end

local function PresenceRequest(userId)
    local bestPresence = nil
    local bestScore = -1

    for attempt = 1, 4 do
        local presence = PresenceRequestOnce(userId)

        if presence then
            local presenceType = tonumber(presence.userPresenceType) or 0
            local placeId = tonumber(presence.placeId)
                or tonumber(presence.rootPlaceId)
            local gameId = presence.gameId and tostring(presence.gameId) or nil

            local score = presenceType

            if presenceType == 2 then
                score = score + 10
            end

            if placeId then
                score = score + 20
            end

            if gameId and gameId ~= "" then
                score = score + 40
            end

            if score > bestScore then
                bestScore = score
                bestPresence = presence
            end

            if presenceType == 2
            and placeId
            and gameId
            and gameId ~= "" then
                break
            end
        end

        if attempt < 4 then
            task.wait(0.3)
        end
    end

    if not bestPresence then
        return nil, "Presence unavailable"
    end

    return bestPresence
end

local function UpdateJoinStatus(text, notifyFailure)
    JoinLookupGeneration = JoinLookupGeneration + 1
    local generation = JoinLookupGeneration

    if JoinPlayingLabel then
        JoinPlayingLabel.Text = "Checking..."
        JoinPlayingLabel.TextColor3 = Color3.fromRGB(255, 215, 70)
    end

    local userId, resolveError = ResolveJoinUserId(text)

    if not userId then
        JoinTargetCache = nil

        if JoinPlayingLabel then
            JoinPlayingLabel.Text = resolveError or "User not found"
            JoinPlayingLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        end

        if notifyFailure then
            CustomNotify(resolveError or "User not found", Color3.fromRGB(255, 100, 100))
        end

        return nil
    end

    local sameServerPlayer = Players:GetPlayerByUserId(userId)

    if sameServerPlayer then
        JoinTargetCache = {
            UserId = userId,
            SameServer = true,
            PlaceId = game.PlaceId,
            GameId = game.JobId,
            LastLocation = "This server"
        }

        if generation == JoinLookupGeneration and JoinPlayingLabel then
            JoinPlayingLabel.Text = "Playing: this server"
            JoinPlayingLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        end

        return JoinTargetCache
    end

    local presence, presenceError = PresenceRequest(userId)

    if generation ~= JoinLookupGeneration then
        return nil
    end

    if not presence then
        JoinTargetCache = nil

        if JoinPlayingLabel then
            JoinPlayingLabel.Text = presenceError or "Presence unavailable"
            JoinPlayingLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        end

        if notifyFailure then
            CustomNotify(presenceError or "Presence unavailable", Color3.fromRGB(255, 100, 100))
        end

        return nil
    end

    local presenceType = tonumber(presence.userPresenceType) or 0
    local lastLocation = tostring(presence.lastLocation or "")
    local placeId = tonumber(presence.placeId)
        or tonumber(presence.rootPlaceId)
    local gameId = presence.gameId and tostring(presence.gameId) or nil

    JoinTargetCache = {
        UserId = userId,
        PresenceType = presenceType,
        PlaceId = placeId,
        GameId = gameId,
        LastLocation = lastLocation
    }

    if JoinPlayingLabel then
        if presenceType == 2 then
            JoinPlayingLabel.Text = "Playing: " .. (lastLocation ~= "" and lastLocation or "Roblox")
            JoinPlayingLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        elseif presenceType == 0 then
            JoinPlayingLabel.Text = "Offline"
            JoinPlayingLabel.TextColor3 = Color3.fromRGB(170, 170, 185)
        else
            JoinPlayingLabel.Text = "Online, not in game"
            JoinPlayingLabel.TextColor3 = Color3.fromRGB(255, 215, 70)
        end
    end

    return JoinTargetCache
end

local function RequestJson(url)
    local body = nil

    if RequestFunction then
        local ok, response = pcall(function()
            return RequestFunction({
                Url = url,
                Method = "GET"
            })
        end)

        if ok and typeof(response) == "table" then
            body = response.Body or response.body
        end
    end

    if typeof(body) ~= "string" or body == "" then
        local ok, result = pcall(function()
            return game:HttpGet(url)
        end)

        if ok and typeof(result) == "string" then
            body = result
        end
    end

    if typeof(body) ~= "string" or body == "" then
        return nil
    end

    local ok, decoded = pcall(function()
        return HttpService:JSONDecode(body)
    end)

    if ok and typeof(decoded) == "table" then
        return decoded
    end

    return nil
end

local function GetPopulatedPublicServer(placeId)
    local cursor = nil
    local bestServer = nil
    local bestPlaying = -1

    for _ = 1, 3 do
        local url = "https://games.roblox.com/v1/games/"
            .. tostring(placeId)
            .. "/servers/Public?sortOrder=Desc&excludeFullGames=true&limit=100"

        if cursor and cursor ~= "" then
            url = url .. "&cursor=" .. HttpService:UrlEncode(cursor)
        end

        local decoded = RequestJson(url)

        if not decoded or typeof(decoded.data) ~= "table" then
            break
        end

        for _, server in ipairs(decoded.data) do
            local serverId = tostring(server.id or "")
            local playing = tonumber(server.playing) or 0
            local maxPlayers = tonumber(server.maxPlayers) or 0

            if serverId ~= ""
            and serverId ~= game.JobId
            and playing > 0
            and (maxPlayers <= 0 or playing < maxPlayers)
            and playing > bestPlaying then
                bestPlaying = playing
                bestServer = server
            end
        end

        cursor = decoded.nextPageCursor

        if not cursor or cursor == "" then
            break
        end
    end

    return bestServer
end

local ReturnButtonCleanupPayload = [[
local CoreGui = game:GetService("CoreGui")

local function hideReturnObject(obj)
    if not obj then
        return
    end

    local text = nil

    if obj:IsA("TextLabel")
    or obj:IsA("TextButton") then
        text = tostring(obj.Text or "")
    end

    if not text or text == "" then
        return
    end

    local lower = string.lower(text)

    if not string.find(lower, "return to", 1, true)
    and not string.find(lower, "voltar para", 1, true) then
        return
    end

    local current = obj

    for _ = 1, 6 do
        if not current then
            break
        end

        if current:IsA("GuiObject") then
            pcall(function()
                current.Visible = false
            end)
        end

        if current:IsA("TextButton")
        or current:IsA("ImageButton") then
            break
        end

        current = current.Parent
    end
end

local function scan()
    for _, obj in ipairs(CoreGui:GetDescendants()) do
        hideReturnObject(obj)
    end
end

task.spawn(function()
    task.wait(1)
    scan()

    CoreGui.DescendantAdded:Connect(function(obj)
        task.defer(function()
            hideReturnObject(obj)

            if obj:IsA("TextLabel")
            or obj:IsA("TextButton") then
                pcall(function()
                    obj:GetPropertyChangedSignal("Text"):Connect(function()
                        hideReturnObject(obj)
                    end)
                end)
            end
        end)
    end)

    for _ = 1, 30 do
        task.wait(1)
        scan()
    end
end)
]]

local function QueueReturnButtonCleanup()
    local queueFunction = nil
    local env = getgenv()

    if env and type(env.queue_on_teleport) == "function" then
        queueFunction = env.queue_on_teleport
    elseif type(queue_on_teleport) == "function" then
        queueFunction = queue_on_teleport
    elseif syn and type(syn.queue_on_teleport) == "function" then
        queueFunction = syn.queue_on_teleport
    elseif fluxus and type(fluxus.queue_on_teleport) == "function" then
        queueFunction = fluxus.queue_on_teleport
    end

    if not queueFunction then
        return false
    end

    return pcall(function()
        queueFunction(ReturnButtonCleanupPayload)
    end)
end

local function JoinPublicGame(placeId)
    placeId = tonumber(placeId)

    if getgenv().AutoSaveConfiguration then
        pcall(getgenv().AutoSaveConfiguration)
    end

    if Settings.AutoExecute and getgenv().QueueToxAutoExecute then
        pcall(getgenv().QueueToxAutoExecute)
    end

    QueueReturnButtonCleanup()
    task.wait(0.12)

    if not placeId or placeId <= 0 then
        CustomNotify("Invalid Place ID", Color3.fromRGB(255, 100, 100))
        return false
    end

    local server = GetPopulatedPublicServer(placeId)

    if server and server.id then
        CustomNotify(
            "Joining public server • "
                .. tostring(server.playing or 0)
                .. "/"
                .. tostring(server.maxPlayers or "?"),
            Color3.fromRGB(100, 255, 100)
        )

        local ok = pcall(function()
            TeleportService:TeleportToPlaceInstance(
                placeId,
                tostring(server.id),
                Player
            )
        end)

        return ok
    end

    CustomNotify(
        "No populated server found, using normal matchmaking",
        Color3.fromRGB(255, 215, 70)
    )

    return pcall(function()
        TeleportService:Teleport(placeId, Player)
    end)
end

local function JoinTargetPlayer()
    if not JoinTargetBox then
        return
    end

    if getgenv().AutoSaveConfiguration then
        pcall(getgenv().AutoSaveConfiguration)
    end

    if Settings.AutoExecute and getgenv().QueueToxAutoExecute then
        pcall(getgenv().QueueToxAutoExecute)
    end

    QueueReturnButtonCleanup()
    task.wait(0.12)

    local target = UpdateJoinStatus(JoinTargetBox.Text, true)

    if not target then
        return
    end

    if target.SameServer then
        CustomNotify("Player is already in this server", Color3.fromRGB(255, 215, 70))
        return
    end

    if target.PresenceType ~= 2 then
        CustomNotify("Player is not in a game", Color3.fromRGB(255, 180, 70))
        return
    end

    if target.PlaceId and target.GameId and target.GameId ~= "" then
        local fallbackConnection = nil
        local fallbackUsed = false

        fallbackConnection = TeleportService.TeleportInitFailed:Connect(function(player)
            if player ~= Player or fallbackUsed then
                return
            end

            fallbackUsed = true

            if fallbackConnection then
                fallbackConnection:Disconnect()
            end

            CustomNotify(
                "Exact server blocked; joining a public server in the same game",
                Color3.fromRGB(255, 180, 70)
            )

            task.spawn(function()
                JoinPublicGame(target.PlaceId)
            end)
        end)

        task.delay(8, function()
            if fallbackConnection then
                fallbackConnection:Disconnect()
            end
        end)

        local ok = pcall(function()
            TeleportService:TeleportToPlaceInstance(
                target.PlaceId,
                target.GameId,
                Player
            )
        end)

        if not ok then
            if fallbackConnection then
                fallbackConnection:Disconnect()
            end

            JoinPublicGame(target.PlaceId)
        end

        return
    end

    if target.PlaceId then
        CustomNotify(
            "Roblox hides the exact server; joining the same game instead",
            Color3.fromRGB(255, 180, 70)
        )

        JoinPublicGame(target.PlaceId)
        return
    end

    CustomNotify(
        "Roblox did not expose this player's PlaceId/JobId",
        Color3.fromRGB(255, 100, 100)
    )
end

local function CreateJoinInterface()
    if not JoinPage then
        return
    end

    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -5, 0, 108)
    card.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
    card.BorderSizePixel = 0
    card.Parent = JoinPage

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 4)
    cardCorner.Parent = card

    JoinTargetBox = Instance.new("TextBox")
    JoinTargetBox.Size = UDim2.new(0.52, -8, 0, 30)
    JoinTargetBox.Position = UDim2.new(0, 8, 0, 8)
    JoinTargetBox.BackgroundColor3 = Color3.fromRGB(27, 27, 39)
    JoinTargetBox.BorderSizePixel = 0
    JoinTargetBox.PlaceholderText = "Nick / ID"
    JoinTargetBox.Text = ""
    JoinTargetBox.TextColor3 = Color3.fromRGB(245, 245, 245)
    JoinTargetBox.PlaceholderColor3 = Color3.fromRGB(130, 130, 150)
    JoinTargetBox.Font = Enum.Font.Gotham
    JoinTargetBox.TextSize = 12
    JoinTargetBox.ClearTextOnFocus = false
    JoinTargetBox.Parent = card

    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 4)
    inputCorner.Parent = JoinTargetBox

    JoinPlayingLabel = Instance.new("TextLabel")
    JoinPlayingLabel.Size = UDim2.new(0.48, -12, 0, 30)
    JoinPlayingLabel.Position = UDim2.new(0.52, 4, 0, 8)
    JoinPlayingLabel.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
    JoinPlayingLabel.BorderSizePixel = 0
    JoinPlayingLabel.Text = "Playing: --"
    JoinPlayingLabel.TextColor3 = Color3.fromRGB(170, 170, 185)
    JoinPlayingLabel.Font = Enum.Font.Gotham
    JoinPlayingLabel.TextSize = 10
    JoinPlayingLabel.TextXAlignment = Enum.TextXAlignment.Center
    JoinPlayingLabel.TextTruncate = Enum.TextTruncate.AtEnd
    JoinPlayingLabel.Parent = card

    local playingCorner = Instance.new("UICorner")
    playingCorner.CornerRadius = UDim.new(0, 4)
    playingCorner.Parent = JoinPlayingLabel

    JoinPlayerButton = Instance.new("TextButton")
    JoinPlayerButton.Size = UDim2.new(1, -16, 0, 28)
    JoinPlayerButton.Position = UDim2.new(0, 8, 0, 44)
    JoinPlayerButton.BackgroundColor3 = MAIN_COLOR
    JoinPlayerButton.BorderSizePixel = 0
    JoinPlayerButton.Text = "JOIN"
    JoinPlayerButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    JoinPlayerButton.Font = Enum.Font.GothamBold
    JoinPlayerButton.TextSize = 12
    JoinPlayerButton.Parent = card

    local joinCorner = Instance.new("UICorner")
    joinCorner.CornerRadius = UDim.new(0, 4)
    joinCorner.Parent = JoinPlayerButton

    JoinGamesButton = Instance.new("TextButton")
    JoinGamesButton.Size = UDim2.new(1, -16, 0, 24)
    JoinGamesButton.Position = UDim2.new(0, 8, 0, 78)
    JoinGamesButton.BackgroundColor3 = Color3.fromRGB(24, 24, 36)
    JoinGamesButton.BorderSizePixel = 0
    JoinGamesButton.Text = "Quick Games"
    JoinGamesButton.TextColor3 = Color3.fromRGB(240, 240, 240)
    JoinGamesButton.Font = Enum.Font.GothamBold
    JoinGamesButton.TextSize = 11
    JoinGamesButton.Parent = card

    local gamesCorner = Instance.new("UICorner")
    gamesCorner.CornerRadius = UDim.new(0, 4)
    gamesCorner.Parent = JoinGamesButton

    JoinTargetBox.FocusLost:Connect(function()
        if CleanJoinTarget(JoinTargetBox.Text) ~= "" then
            task.spawn(function()
                UpdateJoinStatus(JoinTargetBox.Text, false)
            end)
        end
    end)

    JoinPlayerButton.MouseButton1Click:Connect(function()
        task.spawn(JoinTargetPlayer)
    end)

    JoinGamesButton.MouseButton1Click:Connect(function()
        if JoinGamesGui then
            JoinGamesGui.Visible = not JoinGamesGui.Visible
        end
    end)
end

local function ResolvePlaceName(placeId)
    local ok, info = pcall(function()
        return MarketplaceService:GetProductInfo(
            placeId,
            Enum.InfoType.Asset
        )
    end)

    if ok and typeof(info) == "table" then
        local name = tostring(info.Name or "")

        if name ~= "" then
            return name
        end
    end

    return "Place " .. tostring(placeId)
end

local function RefreshQuickJoinGames()
    if not JoinGamesScroll then
        return
    end

    for _, child in ipairs(JoinGamesScroll:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    for idx, info in ipairs(SavedJoinGames) do
        local placeId = tonumber(info.id or info.PlaceId)
        local gameName = tostring(info.name or info.Name or ("Place " .. tostring(placeId or "?")))
        local favorite = info.favorite == true

        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -4, 0, 48)
        row.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
        row.BorderSizePixel = 0
        row.LayoutOrder = idx
        row.Parent = JoinGamesScroll

        local rowCorner = Instance.new("UICorner")
        rowCorner.CornerRadius = UDim.new(0, 4)
        rowCorner.Parent = row

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0, 225, 0, 24)
        nameLabel.Position = UDim2.new(0, 8, 0, 3)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = (favorite and "★ " or "") .. gameName
        nameLabel.TextColor3 = favorite
            and Color3.fromRGB(255, 215, 70)
            or Color3.fromRGB(245, 245, 245)
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 11
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        nameLabel.Parent = row

        local idLabel = Instance.new("TextLabel")
        idLabel.Size = UDim2.new(0, 225, 0, 16)
        idLabel.Position = UDim2.new(0, 8, 0, 27)
        idLabel.BackgroundTransparency = 1
        idLabel.Text = "ID: " .. tostring(placeId or "?")
        idLabel.TextColor3 = Color3.fromRGB(145, 145, 165)
        idLabel.Font = Enum.Font.Gotham
        idLabel.TextSize = 9
        idLabel.TextXAlignment = Enum.TextXAlignment.Left
        idLabel.Parent = row

        local function makeButton(text, x, width)
            local button = Instance.new("TextButton")
            button.Size = UDim2.new(0, width, 0, 24)
            button.Position = UDim2.new(1, x, 0.5, -12)
            button.BackgroundColor3 = Color3.fromRGB(25, 25, 38)
            button.BorderSizePixel = 0
            button.Text = text
            button.TextColor3 = Color3.fromRGB(240, 240, 240)
            button.Font = Enum.Font.GothamBold
            button.TextSize = 9
            button.Parent = row

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 4)
            corner.Parent = button

            return button
        end

        local joinButton = makeButton("Join", -205, 42)
        local upButton = makeButton("Up", -159, 28)
        local downButton = makeButton("Down", -127, 38)
        local favoriteButton = makeButton("Fav", -85, 32)
        local removeButton = makeButton("Remove", -49, 45)

        favoriteButton.TextColor3 = favorite
            and Color3.fromRGB(255, 215, 70)
            or Color3.fromRGB(210, 210, 220)

        joinButton.MouseButton1Click:Connect(function()
            if placeId then
                task.spawn(function()
                    JoinPublicGame(placeId)
                end)
            end
        end)

        upButton.MouseButton1Click:Connect(function()
            if idx > 1 then
                SavedJoinGames[idx], SavedJoinGames[idx - 1] =
                    SavedJoinGames[idx - 1], SavedJoinGames[idx]

                AutoSaveConfiguration()
                RefreshQuickJoinGames()
            end
        end)

        downButton.MouseButton1Click:Connect(function()
            if idx < #SavedJoinGames then
                SavedJoinGames[idx], SavedJoinGames[idx + 1] =
                    SavedJoinGames[idx + 1], SavedJoinGames[idx]

                AutoSaveConfiguration()
                RefreshQuickJoinGames()
            end
        end)

        favoriteButton.MouseButton1Click:Connect(function()
            SavedJoinGames[idx].favorite = not favorite
            AutoSaveConfiguration()
            RefreshQuickJoinGames()
        end)

        removeButton.MouseButton1Click:Connect(function()
            table.remove(SavedJoinGames, idx)
            AutoSaveConfiguration()
            RefreshQuickJoinGames()
        end)
    end
end

getgenv().RefreshQuickJoinGames = RefreshQuickJoinGames

local function AddQuickJoinGame()
    if not JoinGameIdBox then
        return
    end

    local cleaned = tostring(JoinGameIdBox.Text or ""):match("%d+")
    local placeId = tonumber(cleaned)

    if not placeId or placeId <= 0 then
        CustomNotify("Invalid Place ID", Color3.fromRGB(255, 100, 100))
        return
    end

    for _, info in ipairs(SavedJoinGames) do
        if tonumber(info.id or info.PlaceId) == placeId then
            CustomNotify("Game already saved", Color3.fromRGB(255, 215, 70))
            return
        end
    end

    JoinGameAddButton.Text = "Adding..."

    task.spawn(function()
        local name = ResolvePlaceName(placeId)

        table.insert(SavedJoinGames, {
            id = placeId,
            name = name,
            favorite = false
        })

        AutoSaveConfiguration()
        RefreshQuickJoinGames()

        JoinGameIdBox.Text = ""
        JoinGameAddButton.Text = "Add Game"

        CustomNotify(
            "Saved: " .. name,
            Color3.fromRGB(100, 255, 100)
        )
    end)
end

if JoinGameAddButton then
    JoinGameAddButton.MouseButton1Click:Connect(AddQuickJoinGame)
end

if JoinGameIdBox then
    JoinGameIdBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            AddQuickJoinGame()
        end
    end)
end

CreateJoinInterface()
RefreshQuickJoinGames()

local function SkidFling(TargetPlayer)
    if not TargetPlayer or not TargetPlayer.Character then return end

    local Character = Player.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local RootPart = Humanoid and Humanoid.RootPart
    local TCharacter = TargetPlayer.Character
    local THumanoid = TCharacter and TCharacter:FindFirstChildOfClass("Humanoid")
    local TRootPart = THumanoid and THumanoid.RootPart
    local THead = TCharacter and TCharacter:FindFirstChild("Head")
    local Accessory = TCharacter and TCharacter:FindFirstChildOfClass("Accessory")
    local Handle = Accessory and Accessory:FindFirstChild("Handle")

    if not (Character and Humanoid and RootPart and TCharacter) then return end

    getgenv().OldPos = RootPart.CFrame
    if THumanoid and THumanoid.Sit then return end

    local oldCameraSubject = Camera.CameraSubject
    if THead then
        Camera.CameraSubject = THead
    elseif Handle then
        Camera.CameraSubject = Handle
    elseif THumanoid then
        Camera.CameraSubject = THumanoid
    end

    local targetBasePart = TRootPart or THead or Handle
    if not targetBasePart then
        Camera.CameraSubject = oldCameraSubject
        return
    end

    getgenv().FPDH = workspace.FallenPartsDestroyHeight

    getgenv().ToxFlingBypassUntil =
        math.max(
            tonumber(
                getgenv().ToxFlingBypassUntil
            ) or 0,
            tick() + 4
        )

    local FPos = function(BasePart, Pos, Ang)
        if not RootPart or not BasePart or not BasePart.Parent then return end
        RootPart.CFrame = CFrame.new(BasePart.Position) * Pos * Ang
        pcall(function()
            Character:SetPrimaryPartCFrame(CFrame.new(BasePart.Position) * Pos * Ang)
        end)
        RootPart.Velocity = Vector3.new(9e7, 9e8, 9e7)
        RootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
    end

    local SFBasePart = function(BasePart)
        local TimeToWait = 2
        local Time = tick()
        local Angle = 0

        repeat
            if not RootPart or not THumanoid or Humanoid.Health <= 0 then break end

            if BasePart.Velocity.Magnitude < 50 then
                Angle = Angle + 100

                FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(2.25, 1.5, -2.25) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(-2.25, -1.5, 2.25) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle), 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle), 0, 0))
                task.wait()
            else
                FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, -1.5, -THumanoid.WalkSpeed), CFrame.Angles(0, 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                task.wait()
                local targetVelocity = TRootPart and TRootPart.Velocity.Magnitude / 1.25 or 0
                FPos(BasePart, CFrame.new(0, 1.5, targetVelocity), CFrame.Angles(math.rad(90), 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, -1.5, -targetVelocity), CFrame.Angles(0, 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, 1.5, targetVelocity), CFrame.Angles(math.rad(90), 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(-90), 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                task.wait()
            end
        until BasePart.Velocity.Magnitude > 500
            or BasePart.Parent ~= TargetPlayer.Character
            or TargetPlayer.Parent ~= Players
            or THumanoid.Sit
            or Humanoid.Health <= 0
            or tick() > Time + TimeToWait
    end

    pcall(function()
        workspace.FallenPartsDestroyHeight = 0/0
    end)

    local BV = Instance.new("BodyVelocity")
    BV.Name = "EpixVel"
    BV.Parent = RootPart
    BV.Velocity = Vector3.new(9e8, 9e8, 9e8)
    BV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)

    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)

    if TRootPart and THead then
        if (TRootPart.Position - THead.Position).Magnitude > 5 then
            SFBasePart(THead)
        else
            SFBasePart(TRootPart)
        end
    elseif TRootPart then
        SFBasePart(TRootPart)
    elseif THead then
        SFBasePart(THead)
    elseif Handle then
        SFBasePart(Handle)
    end

    BV:Destroy()
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
    Camera.CameraSubject = Humanoid

    local OldPos = getgenv().OldPos or RootPart.CFrame
    repeat
        RootPart.CFrame = OldPos * CFrame.new(0, 0.5, 0)
        pcall(function()
            Character:SetPrimaryPartCFrame(OldPos * CFrame.new(0, 0.5, 0))
        end)
        Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)

        for _, x in ipairs(Character:GetChildren()) do
            if x:IsA("BasePart") then
                x.Velocity = Vector3.zero
                x.RotVelocity = Vector3.zero
            end
        end

        task.wait()
    until (RootPart.Position - OldPos.Position).Magnitude < 25

    pcall(function()
        workspace.FallenPartsDestroyHeight = getgenv().FPDH
    end)

    getgenv().ToxFlingBypassUntil =
        math.max(
            tonumber(
                getgenv().ToxFlingBypassUntil
            ) or 0,
            tick() + 0.25
        )

    if getgenv().SetNDSNoTPAnchor then
        pcall(function()
            getgenv().SetNDSNoTPAnchor(
                OldPos,
                true
            )
        end)
    end
end

getgenv().ToxFlingBypassUntil =
    tonumber(
        getgenv().ToxFlingBypassUntil
    ) or 0

getgenv().ToxFlingPlayer = SkidFling

local function ExecuteFling(TargetInput)
    if not TargetInput or TargetInput == "" then
        return CustomNotify("Enter username or 'all'", Color3.fromRGB(255, 100, 100))
    end

    local LowerInput = string.lower(TargetInput)

    if LowerInput == "all" or LowerInput == "others" then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= Player then
                task.spawn(function() SkidFling(p) end)
            end
        end
        return
    end

    local target = nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player and (string.find(string.lower(p.Name), LowerInput, 1, true) or string.find(string.lower(p.DisplayName), LowerInput, 1, true)) then
            target = p
            break
        end
    end

    if target then
        task.spawn(function() SkidFling(target) end)
    else
        CustomNotify("Player not found!", Color3.fromRGB(255, 100, 100))
    end
end

getgenv().ToxExecuteFling = ExecuteFling

local function ExecuteTeleport(TargetInput, mode)
    if not TargetInput or TargetInput == "" then 
        if mode == "LOOP" then Settings.LoopTPTarget = nil CustomNotify("Loop TP Disabled", Color3.fromRGB(255, 100, 100)) end
        return CustomNotify("Enter username", Color3.fromRGB(255, 100, 100)) 
    end
    local LowerInput = string.lower(TargetInput)
    local targetObj = nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player and (string.find(string.lower(p.Name), LowerInput) or string.find(string.lower(p.DisplayName), LowerInput)) then
            targetObj = p break
        end
    end

    if targetObj and targetObj.Character and targetObj.Character:FindFirstChild("HumanoidRootPart") then
        local tHrp = targetObj.Character.HumanoidRootPart
        local Root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if mode == "TP" then
            if Root then
                if getgenv().AllowToxTeleport then getgenv().AllowToxTeleport(1.25) end
                Root.CFrame = tHrp.CFrame * CFrame.new(0, 0, -3)
            end
            CustomNotify("Teleported to " .. targetObj.DisplayName, Color3.fromRGB(100, 255, 100))
        elseif mode == "LOOP" then
            if Settings.LoopTPTarget == targetObj then
                Settings.LoopTPTarget = nil
                CustomNotify("Loop TP Disabled", Color3.fromRGB(255, 100, 100))
            else
                Settings.LoopTPTarget = targetObj
                CustomNotify("Loop TP Enabled on " .. targetObj.DisplayName, Color3.fromRGB(100, 255, 100))
            end
        end
    else
        CustomNotify("Player not found!", Color3.fromRGB(255, 100, 100))
    end
end

local function ServerHop()
    pcall(function()
        local sfUrl = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/0?sortOrder=Asc&limit=100"
        local req = game:HttpGet(sfUrl)
        local data = HttpService:JSONDecode(req)
        if data and data.data then
            for _, s in ipairs(data.data) do
                if s.playing < s.maxPlayers and s.id ~= game.JobId then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, Player)
                    CustomNotify("Teleporting to server...", Color3.fromRGB(100, 255, 100))
                    return
                end
            end
        end
        CustomNotify("No suitable server found", Color3.fromRGB(255, 100, 100))
    end)
end

local function BoostFPS()
    pcall(function()
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") then
                v.Material = Enum.Material.SmoothPlastic
                v.Reflectance = 0
            elseif v:IsA("Decal") or v:IsA("Texture") then
                v:Destroy()
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
                v.Enabled = false
            end
        end
        CustomNotify("FPS Boosted!", Color3.fromRGB(100, 255, 100))
    end)
end

local LastSafeCFrame = nil
local AntiVoidConnection = nil
local AntiVoidCharacterConnection = nil
local AntiVoidLastSave = 0
local AntiVoidLastRescue = 0

local function GetVoidThreshold()
    local fallen =
        tonumber(
            workspace.FallenPartsDestroyHeight
        ) or -500

    return math.max(
        fallen + 35,
        -250
    )
end

local function IsUsableSafeCFrame(cframe)
    if typeof(cframe) ~= "CFrame" then
        return false
    end

    return cframe.Position.Y
        > GetVoidThreshold() + 20
end

local function GetSpawnFallbackCFrame(root)
    local ndsSafe =
        getgenv().NDSSafeSpawnCFrame

    if game.PlaceId == 189707
    and IsUsableSafeCFrame(ndsSafe) then
        return ndsSafe
    end

    local spawn =
        workspace:
            FindFirstChildWhichIsA(
                "SpawnLocation",
                true
            )

    if spawn then
        return spawn.CFrame
            + Vector3.new(0, 4, 0)
    end

    if root then
        local origin =
            Vector3.new(
                root.Position.X,
                math.max(
                    root.Position.Y + 500,
                    500
                ),
                root.Position.Z
            )

        local result =
            workspace:Raycast(
                origin,
                Vector3.new(0, -2000, 0)
            )

        if result then
            return CFrame.new(
                result.Position
                + Vector3.new(0, 5, 0)
            )
        end
    end

    return nil
end

local function SetLastSafeCFrame(cframe)
    if IsUsableSafeCFrame(cframe) then
        LastSafeCFrame = cframe
        getgenv().ToxLastSafeCFrame =
            cframe
    end
end

getgenv().SetToxLastSafeCFrame =
    SetLastSafeCFrame

local function RescueFromVoid(
    character,
    humanoid,
    root
)
    if not character
    or not character.Parent
    or not humanoid
    or humanoid.Health <= 0
    or not root
    or not root.Parent then
        return false
    end

    if tick() - AntiVoidLastRescue < 0.8 then
        return false
    end

    AntiVoidLastRescue = tick()

    local safe =
        IsUsableSafeCFrame(LastSafeCFrame)
        and LastSafeCFrame
        or GetSpawnFallbackCFrame(root)

    if not safe then
        return false
    end

    local allow =
        getgenv().AllowToxTeleport

    if allow then
        allow(1.5)
    end

    if getgenv().SetNDSNoTPAnchor then
        pcall(function()
            getgenv().SetNDSNoTPAnchor(
                safe,
                true
            )
        end)
    end

    humanoid.Sit = false
    humanoid.PlatformStand = false

    root.AssemblyLinearVelocity =
        Vector3.zero
    root.AssemblyAngularVelocity =
        Vector3.zero
    root.CFrame = safe

    pcall(function()
        humanoid:ChangeState(
            Enum.HumanoidStateType.GettingUp
        )
    end)

    SetLastSafeCFrame(safe)
    return true
end

local function StopAntiVoid()
    if AntiVoidConnection then
        AntiVoidConnection:Disconnect()
        AntiVoidConnection = nil
    end

    if AntiVoidCharacterConnection then
        AntiVoidCharacterConnection:
            Disconnect()
        AntiVoidCharacterConnection = nil
    end
end

local function StartAntiVoid()
    StopAntiVoid()

    AntiVoidCharacterConnection =
        AddConnection(
            Player.CharacterAdded:
                Connect(function(character)
                    task.spawn(function()
                        local root =
                            character:
                                WaitForChild(
                                    "HumanoidRootPart",
                                    8
                                )
                        local humanoid =
                            character:
                                FindFirstChildOfClass(
                                    "Humanoid"
                                )

                        if not root
                        or not humanoid then
                            return
                        end

                        task.wait(0.45)

                        if not Settings.AntiVoid
                        or Destroyed then
                            return
                        end

                        if root.Position.Y
                        <= GetVoidThreshold() then
                            RescueFromVoid(
                                character,
                                humanoid,
                                root
                            )
                        end
                    end)
                end)
        )

    AntiVoidConnection =
        AddConnection(
            RunService.Heartbeat:
                Connect(function()
                    if Destroyed
                    or not ScriptLoaded
                    or not Settings.AntiVoid then
                        return
                    end

                    local character =
                        Player.Character
                    local root =
                        character
                        and character:
                            FindFirstChild(
                                "HumanoidRootPart"
                            )
                    local humanoid =
                        character
                        and character:
                            FindFirstChildOfClass(
                                "Humanoid"
                            )

                    if not root
                    or not humanoid
                    or humanoid.Health <= 0 then
                        return
                    end

                    local threshold =
                        GetVoidThreshold()

                    if humanoid.FloorMaterial
                    ~= Enum.Material.Air
                    and root.Position.Y
                        > threshold + 20
                    and root.AssemblyLinearVelocity.Y
                        > -25
                    and tick() - AntiVoidLastSave
                        >= 0.15 then
                        AntiVoidLastSave = tick()
                        SetLastSafeCFrame(
                            root.CFrame
                        )
                    end

                    if root.Position.Y
                    <= threshold then
                        RescueFromVoid(
                            character,
                            humanoid,
                            root
                        )
                    end
                end)
        )
end

local WalkFlingGeneration = 0
local WalkFlingCollisionDefaults =
    setmetatable({}, {__mode = "k"})
local WalkFlingImpulseActive = false
local WalkFlingRestoreVelocity = nil
getgenv().ToxWalkFlingImpulseActive = false

local function RestoreWalkFlingCollisions()
    local character = Player.Character

    for part, oldCanCollide in pairs(
        WalkFlingCollisionDefaults
    ) do
        if part
        and part.Parent
        and character
        and part:IsDescendantOf(character) then
            if Settings.Noclip then
                part.CanCollide = false
            else
                part.CanCollide =
                    oldCanCollide
            end
        end
    end

    table.clear(
        WalkFlingCollisionDefaults
    )
end

local function ApplyWalkFlingNoclip(
    character
)
    for _, part in ipairs(
        character:GetDescendants()
    ) do
        if part:IsA("BasePart") then
            if WalkFlingCollisionDefaults[part]
            == nil then
                WalkFlingCollisionDefaults[part] =
                    part.CanCollide
            end

            part.CanCollide = false
        end
    end
end

local function StopWalkFling()
    WalkFlingGeneration += 1

    local wasImpulseActive =
        WalkFlingImpulseActive

    WalkFlingImpulseActive = false
    getgenv().ToxWalkFlingImpulseActive = false

    local character =
        Player.Character
    local root =
        character
        and character:
            FindFirstChild(
                "HumanoidRootPart"
            )

    if wasImpulseActive
    and root
    and WalkFlingRestoreVelocity then
        root.Velocity =
            WalkFlingRestoreVelocity
        root.AssemblyLinearVelocity =
            WalkFlingRestoreVelocity
    end

    WalkFlingRestoreVelocity = nil

    if root
    and getgenv().SetNDSNoTPAnchor then
        pcall(function()
            getgenv().SetNDSNoTPAnchor(
                root.CFrame,
                true
            )
        end)
    end

    RestoreWalkFlingCollisions()
end

local function StartWalkFling()
    StopWalkFling()

    if not Settings.WalkFling
    or Destroyed then
        return
    end

    if Settings.AntiFling then
        RestoreAntiFlingDefaults()
    end

    local generation =
        WalkFlingGeneration

    task.spawn(function()
        local moveLift = 0.1

        while Settings.WalkFling
        and not Destroyed
        and ScriptLoaded
        and generation
            == WalkFlingGeneration do
            RunService.Heartbeat:Wait()

            local character =
                Player.Character
            local humanoid =
                character
                and character:
                    FindFirstChildOfClass(
                        "Humanoid"
                    )
            local root =
                character
                and character:
                    FindFirstChild(
                        "HumanoidRootPart"
                    )

            if not character
            or not character.Parent
            or not humanoid
            or humanoid.Health <= 0
            or not root
            or not root.Parent then
                task.wait()
                continue
            end

            ApplyWalkFlingNoclip(
                character
            )

            local velocity =
                root.Velocity

            WalkFlingRestoreVelocity =
                velocity

            WalkFlingImpulseActive = true
            getgenv().ToxWalkFlingImpulseActive = true

            local multiplier =
                game.PlaceId == NDSPlaceId
                and 900
                or 2500

            local verticalBoost =
                game.PlaceId == NDSPlaceId
                and 600
                or 1500

            root.Velocity =
                velocity * multiplier
                + Vector3.new(
                    0,
                    verticalBoost,
                    0
                )

            RunService.RenderStepped:Wait()

            if character.Parent
            and root.Parent then
                root.Velocity =
                    velocity
                root.AssemblyLinearVelocity =
                    velocity
            end

            WalkFlingImpulseActive = false
            getgenv().ToxWalkFlingImpulseActive = false
            WalkFlingRestoreVelocity = nil

            if generation
                ~= WalkFlingGeneration
            or not Settings.WalkFling then
                break
            end

            RunService.Stepped:Wait()

            if generation
                ~= WalkFlingGeneration
            or not Settings.WalkFling then
                break
            end

            if character.Parent
            and root.Parent then
                root.Velocity =
                    velocity
                    + Vector3.new(
                        0,
                        moveLift,
                        0
                    )

                moveLift =
                    moveLift * -1
            end
        end

        WalkFlingImpulseActive = false
        getgenv().ToxWalkFlingImpulseActive = false
        WalkFlingRestoreVelocity = nil

        if generation
        == WalkFlingGeneration then
            RestoreWalkFlingCollisions()
        end
    end)
end

getgenv().SetWalkFling = function(
    Value,
    Silent
)
    local enabled = Value == true
    Settings.WalkFling = enabled

    if enabled then
        StartWalkFling()
    else
        StopWalkFling()
    end

    if getgenv().SyncToggleVisuals then
        getgenv().SyncToggleVisuals(
            "WalkFling",
            enabled
        )
    end

    if not Silent
    and getgenv().AutoSaveConfiguration then
        getgenv().AutoSaveConfiguration()
    end
end

local SharedToggleSettingMap = {
    Speed = "Speed",
    Noclip = "Noclip",
    NoFallDamage = "NoFallDamage",
    AntiVoid = "AntiVoid",
    AntiFling = "AntiFling",
    WalkFling = "WalkFling",
    CtrlClickTP = "CtrlClickTP",
    CarFly = "CarFly",
    ESPEnabled = "ESPEnabled",
    Chams = "Chams",
    ESPNames = "ESPNames",
    ESPTeamColors = "ESPTeamColors",
    SmoothFly = "SmoothFly",
    NormalFly = "NormalFly"
}

local SharedValueSettingMap = {
    Speed = "SpeedValue",
    CarFly = "CarFlySpeed",
    SmoothFly = "FlySpeed",
    NormalFly = "FlySpeed"
}

local function GetGlobalSharedState()
    getgenv().BaseSharedSettings =
        getgenv().BaseSharedSettings or {}

    return getgenv().BaseSharedSettings
end

local function RecordSharedToggle(Key, Value)
    if getgenv().ToxApplyingGameState then
        return
    end

    local settingKey = SharedToggleSettingMap[Key]

    if not settingKey then
        return
    end

    local globalState = GetGlobalSharedState()
    globalState[settingKey] = Value == true
    Settings[settingKey] = Value == true
end

getgenv().ToxOnSharedValueChanged = function(Key, Value)
    if getgenv().ToxApplyingGameState then
        return
    end

    local settingKey = SharedValueSettingMap[Key]
    local number = tonumber(Value)

    if not settingKey or not number then
        return
    end

    local globalState = GetGlobalSharedState()
    globalState[settingKey] = number
    Settings[settingKey] = number
end

local CarFlyVelocity = nil
local CarFlyGyro = nil
local CarFlySeat = nil

local function DestroyCarFlyMovers()
    if CarFlyVelocity then
        pcall(function()
            CarFlyVelocity:Destroy()
        end)

        CarFlyVelocity = nil
    end

    if CarFlyGyro then
        pcall(function()
            CarFlyGyro:Destroy()
        end)

        CarFlyGyro = nil
    end

    CarFlySeat = nil
end

local function EnsureCarFlyMovers(seat)
    if not seat then
        DestroyCarFlyMovers()
        return false
    end

    if CarFlySeat ~= seat then
        DestroyCarFlyMovers()
        CarFlySeat = seat
    end

    if not CarFlyVelocity or CarFlyVelocity.Parent ~= seat then
        if CarFlyVelocity then
            CarFlyVelocity:Destroy()
        end

        CarFlyVelocity = Instance.new("BodyVelocity")
        CarFlyVelocity.Name = "ToxCarFlyVelocity"
        CarFlyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        CarFlyVelocity.P = 2500
        CarFlyVelocity.Velocity = Vector3.zero
        CarFlyVelocity.Parent = seat
    end

    if not CarFlyGyro or CarFlyGyro.Parent ~= seat then
        if CarFlyGyro then
            CarFlyGyro:Destroy()
        end

        CarFlyGyro = Instance.new("BodyGyro")
        CarFlyGyro.Name = "ToxCarFlyGyro"
        CarFlyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        CarFlyGyro.P = 5000
        CarFlyGyro.D = 450
        CarFlyGyro.CFrame = seat.CFrame
        CarFlyGyro.Parent = seat
    end

    return true
end

getgenv().ToxSetSharedOption = function(Key, Value)
    local enabled = Value == true

    RecordSharedToggle(Key, enabled)

    if Key == "Speed" then
        if enabled then
            local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
            GetHumanoidDefaults(hum)
        end

        Settings.Speed = enabled

        if not enabled then
            RestoreSpeed()
        end
    elseif Key == "Noclip" then
        if enabled then
            CaptureNoclipDefaults()
        end

        Settings.Noclip = enabled

        if not enabled then
            RestoreNoclipDefaults()
        end
    elseif Key == "NoFallDamage" then
        Settings.NoFallDamage = enabled

        if getgenv().SetNDSNoFall then
            getgenv().SetNDSNoFall(enabled, true)
        end
    elseif Key == "AntiVoid" then
        Settings.AntiVoid = enabled

        if enabled then
            StartAntiVoid()
        else
            StopAntiVoid()
        end
    elseif Key == "AntiFling" then
        Settings.AntiFling = enabled

        if not enabled then
            RestoreAntiFlingDefaults()
        end
    elseif Key == "WalkFling" then
        getgenv().SetWalkFling(
            enabled,
            true
        )
    elseif Key == "CtrlClickTP" then
        Settings.CtrlClickTP = enabled
    elseif Key == "CarFly" then
        Settings.CarFly = enabled

        if not enabled then
            DestroyCarFlyMovers()
        end
    elseif Key == "SmoothFly" then
        Settings.SmoothFly = enabled

        if enabled then
            Settings.NormalFly = false

            if getgenv().SyncToggleVisuals then
                getgenv().SyncToggleVisuals("NormalFly", false)
            end

            if getgenv().SetNDSWaterFly then
                getgenv().SetNDSWaterFly(false, true)
            end
        end
    elseif Key == "NormalFly" then
        Settings.NormalFly = enabled

        if enabled then
            Settings.SmoothFly = false

            if getgenv().SyncToggleVisuals then
                getgenv().SyncToggleVisuals("SmoothFly", false)
            end

            if getgenv().SetNDSWaterFly then
                getgenv().SetNDSWaterFly(false, true)
            end
        end
    else
        Settings[Key] = enabled
    end

    if getgenv().SyncToggleVisuals then
        getgenv().SyncToggleVisuals(Key, enabled)
    end
end

getgenv().ApplyCurrentGameSharedSettings = function()
    local globalState = GetGlobalSharedState()

    getgenv().ToxApplyingGameState = true

    for Key, settingKey in pairs(SharedValueSettingMap) do
        local value = globalState[settingKey]

        if value == nil then
            value = Settings[settingKey]
        end

        if value ~= nil then
            Settings[settingKey] = value
            globalState[settingKey] = value

            if getgenv().SyncValueVisuals then
                getgenv().SyncValueVisuals(
                    Key,
                    value
                )
            end
        end
    end

    for Key, settingKey in pairs(SharedToggleSettingMap) do
        local value = globalState[settingKey]

        if value == nil then
            value = Settings[settingKey]
        end

        if value ~= nil then
            globalState[settingKey] =
                value == true

            getgenv().ToxSetSharedOption(
                Key,
                value == true
            )
        end
    end

    getgenv().ToxApplyingGameState = false
end

local function IsPartVisible(part)
    if not Settings.AimWallCheck then return true end
    local origin = Camera.CFrame.Position
    local dir = part.Position - origin
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {Player.Character, part.Parent}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    local result = workspace:Raycast(origin, dir, raycastParams)
    return result == nil
end

local function GetClosestPlayerToMouse()
    local Closest = nil
    local ShortestDistance = Settings.FOVRadius or 120
    local MousePos = UserInputService:GetMouseLocation()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player and p.Character then
            local targetPart = p.Character:FindFirstChild(Settings.AimPart or "Head")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if targetPart and hum and hum.Health > 0 and IsPartVisible(targetPart) then
                local ScreenPos, OnScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if OnScreen then
                    local Dist = (Vector2.new(ScreenPos.X, ScreenPos.Y) - MousePos).Magnitude
                    if Dist < ShortestDistance then
                        ShortestDistance = Dist
                        Closest = targetPart
                    end
                end
            end
        end
    end
    return Closest
end

CreateToggle("Aimbot (Right Click)", CombatPage, Settings.Aimbot, function(v) Settings.Aimbot = v end)
CreateToggleWithValue("Aim Smoothness", CombatPage, true, Settings.AimbotSmoothness, function(v) end, function(val) Settings.AimbotSmoothness = val end)
CreateDropdown("Aim Part", {"Head", "HumanoidRootPart", "Torso"}, CombatPage, Settings.AimPart, function(v) Settings.AimPart = v end)
CreateToggle("Aim Wall Check", CombatPage, Settings.AimWallCheck, function(v) Settings.AimWallCheck = v end)
CreateToggleWithValue("Show FOV Circle", CombatPage, Settings.ShowFOV, Settings.FOVRadius, function(v) Settings.ShowFOV = v end, function(val) Settings.FOVRadius = val end)
CreateToggle("Silent Aim", CombatPage, Settings.SilentAim, function(v) Settings.SilentAim = v end)
CreateToggle("Triggerbot", CombatPage, Settings.Triggerbot, function(v) Settings.Triggerbot = v end)
CreateToggleWithValue("Spinbot", CombatPage, Settings.Spinbot, Settings.SpinSpeed, function(v) Settings.Spinbot = v end, function(val) Settings.SpinSpeed = val end)
CreateToggleWithValue("Hitbox Expander", CombatPage, Settings.HitboxExpander, Settings.HitboxSize, function(v) 
    Settings.HitboxExpander = v
    if not v then RestoreHitboxDefaults() end
end, function(val) Settings.HitboxSize = val end)
CreateToggleWithValue("Kill Aura", CombatPage, Settings.KillAura, Settings.KillAuraRange, function(v) Settings.KillAura = v end, function(val) Settings.KillAuraRange = val end)

CreateToggleWithValue("Speed", PlayerPage, Settings.Speed, Settings.SpeedValue, function(v)
    if getgenv().ToxSetSharedOption then
        getgenv().ToxSetSharedOption("Speed", v)
    end
end, function(val)
    Settings.SpeedValue = val
end, "Speed")

CreateToggleWithValue("Jump", PlayerPage, Settings.Jump, Settings.JumpValue, function(v)
    if v then
        local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
        GetHumanoidDefaults(hum)
    end

    Settings.Jump = v

    if not v then
        RestoreJump()
    end
end, function(val) Settings.JumpValue = val end)
CreateToggle("Air Walk (Platform)", PlayerPage, Settings.AirWalk, function(v) Settings.AirWalk = v UpdateAirWalk() end)
CreateToggleWithValue("Smooth Fly", PlayerPage, Settings.SmoothFly, Settings.FlySpeed, function(v)
    if getgenv().ToxSetSharedOption then
        getgenv().ToxSetSharedOption("SmoothFly", v)
    else
        Settings.SmoothFly = v
        if v then Settings.NormalFly = false end
    end
end, function(val) Settings.FlySpeed = val end, "SmoothFly")
CreateToggleWithValue("Normal Fly", PlayerPage, Settings.NormalFly, Settings.FlySpeed, function(v)
    if getgenv().ToxSetSharedOption then
        getgenv().ToxSetSharedOption("NormalFly", v)
    else
        Settings.NormalFly = v
        if v then Settings.SmoothFly = false end
    end
end, function(val) Settings.FlySpeed = val end, "NormalFly")
CreateToggle("Noclip", PlayerPage, Settings.Noclip, function(v)
    if getgenv().ToxSetSharedOption then
        getgenv().ToxSetSharedOption("Noclip", v)
    end
end, "Noclip")
CreateToggle("Infinite Jump", PlayerPage, Settings.InfiniteJump, function(v) Settings.InfiniteJump = v end)
CreateToggleWithValue("Bhop (Auto Jump)", PlayerPage, Settings.Bhop, Settings.BhopInterval, function(v) Settings.Bhop = v end, function(val) Settings.BhopInterval = math.max(0.05, val) end)
CreateToggleWithValue("Car Speed", PlayerPage, Settings.CarSpeed, Settings.CarSpeedValue, function(v) Settings.CarSpeed = v end, function(val) Settings.CarSpeedValue = val end)
CreateToggleWithValue("Car Fly", PlayerPage, Settings.CarFly, Settings.CarFlySpeed, function(v)
    if getgenv().ToxSetSharedOption then
        getgenv().ToxSetSharedOption("CarFly", v)
    else
        Settings.CarFly = v
    end
end, function(val) Settings.CarFlySpeed = val end, "CarFly")

CreateToggle("ESP", VisualsPage, Settings.ESPEnabled, function(v)
    if getgenv().ToxSetSharedOption then
        getgenv().ToxSetSharedOption("ESPEnabled", v)
    else
        Settings.ESPEnabled = v
    end
end, "ESPEnabled")
CreateToggle("Charms", VisualsPage, Settings.Chams, function(v)
    if getgenv().ToxSetSharedOption then
        getgenv().ToxSetSharedOption("Chams", v)
    else
        Settings.Chams = v
    end
end, "Chams")
CreateToggle("Names", VisualsPage, Settings.ESPNames, function(v)
    if getgenv().ToxSetSharedOption then
        getgenv().ToxSetSharedOption("ESPNames", v)
    else
        Settings.ESPNames = v
    end
end, "ESPNames")
CreateDropdown("Name Type", {"Name", "Display", "Name + Display"}, VisualsPage, Settings.ESPNameMode or "Display", function(v)
    Settings.ESPNameMode = v
end)
CreateToggle("Distance", VisualsPage, Settings.ESPDistance, function(v) Settings.ESPDistance = v end)
CreateToggle("2D Box ESP", VisualsPage, Settings.ESPBox, function(v) Settings.ESPBox = v end)
CreateToggle("Head Dot ESP", VisualsPage, Settings.ESPHeadDot, function(v) Settings.ESPHeadDot = v end)
CreateToggle("Tracers", VisualsPage, Settings.ESPTracers, function(v) Settings.ESPTracers = v end)
CreateToggle("Team Colors", VisualsPage, Settings.ESPTeamColors, function(v)
    if getgenv().ToxSetSharedOption then
        getgenv().ToxSetSharedOption("ESPTeamColors", v)
    else
        Settings.ESPTeamColors = v
    end
end, "ESPTeamColors")
CreateDropdown("Tracer Mode", {"DOWN", "UP", "MOUSE"}, VisualsPage, Settings.TracerOrigin, function(v) Settings.TracerOrigin = v end)
CreateToggleWithValue("Camera FOV", VisualsPage, Settings.FOVEnabled, Settings.FOVValue, function(v)
    if v then
        CaptureFOVDefault()
    end

    Settings.FOVEnabled = v

    if not v then
        RestoreFOVDefault()
    end
end, function(val) Settings.FOVValue = val end)

CreateToggleWithValue("ESP Max Dist", VisualsPage, true, Settings.EspMaxDistance, function(v) end, function(val) Settings.EspMaxDistance = val end)
CreateDropdown("ESP Color", {"White", "Red", "Green", "Blue", "Yellow", "Cyan", "Magenta", "Orange", "Purple", "Lime", "Pink", "Gold"}, VisualsPage, Settings.EspColorName, function(v)
    Settings.EspColorName = v
    Settings.EspColor = ColorMap[v] or Color3.fromRGB(255, 255, 255)
end)


if getgenv().ToxESPDrawings then
    for _, drawings in pairs(getgenv().ToxESPDrawings) do
        for _, drawing in pairs(drawings) do
            pcall(function() drawing:Remove() end)
        end
    end
end

if getgenv().ToxESPHighlights then
    for _, highlight in pairs(getgenv().ToxESPHighlights) do
        pcall(function() highlight:Destroy() end)
    end
end

if getgenv().ToxESPLabels then
    for _, label in pairs(getgenv().ToxESPLabels) do
        pcall(function() label:Destroy() end)
    end
end

local ESPDrawings = {}
local Highlights = {}
local ESPLabels = {}
local ESPCharacterRefs = {}
local LastESPSafetyRefresh = tick()

getgenv().ToxESPDrawings = ESPDrawings
getgenv().ToxESPHighlights = Highlights
getgenv().ToxESPLabels = ESPLabels

local MM2GameId = 66654135
local MM2PlaceId = 142823291
local MM2RoleCache = {}
local MM2DeadCache = {}
local MM2RoleCacheTime = 0
local MM2PlayerDataRemote = nil
local MM2HasAuthoritativeData = false

local RoleColors = {
    Murderer = Color3.fromRGB(255, 50, 50),
    Sheriff = Color3.fromRGB(50, 150, 255),
    Innocent = Color3.fromRGB(50, 255, 50),
    Hero = Color3.fromRGB(50, 255, 255)
}

local MM2UnknownColor = Color3.fromRGB(235, 235, 235)

local function NormalizeRoleName(value)
    if typeof(value) ~= "string" or value == "" then
        return nil
    end

    local role = string.lower(value)
    role = role:gsub("[%s_%-%.]", "")

    if role == "murder"
    or role == "murderer"
    or role == "murderers"
    or role == "killer" then
        return "Murderer"
    end

    if role == "sheriff"
    or role == "detective"
    or role == "cop"
    or role == "police" then
        return "Sheriff"
    end

    if role == "innocent"
    or role == "innocents"
    or role == "civilian"
    or role == "survivor" then
        return "Innocent"
    end

    if role == "hero" then
        return "Hero"
    end

    return nil
end

local function ResolveMM2Player(nameOrId)
    if typeof(nameOrId) == "string" then
        local byName = Players:FindFirstChild(nameOrId)

        if byName then
            return byName
        end

        local numeric = tonumber(nameOrId)

        if numeric then
            for _, p in ipairs(Players:GetPlayers()) do
                if p.UserId == numeric then
                    return p
                end
            end
        end
    elseif typeof(nameOrId) == "number" then
        for _, p in ipairs(Players:GetPlayers()) do
            if p.UserId == nameOrId then
                return p
            end
        end
    end

    return nil
end

local function LooksLikeMM2PlayerData(data)
    if typeof(data) ~= "table" then
        return false
    end

    local inspected = 0

    for key, info in pairs(data) do
        if ResolveMM2Player(key) then
            inspected = inspected + 1

            if typeof(info) == "table"
            and (
                info.Role ~= nil
                or info.Dead ~= nil
                or info.Killed ~= nil
                or info.Eliminated ~= nil
            ) then
                return true
            end
        end

        if inspected >= 3 then
            break
        end
    end

    return false
end

local function NormalizeMM2PlayerDataContainer(data)
    if typeof(data) ~= "table" then
        return nil
    end

    for _, key in ipairs({"Players", "PlayerData", "Data", "Roles"}) do
        if typeof(data[key]) == "table" and LooksLikeMM2PlayerData(data[key]) then
            return data[key]
        end
    end

    if LooksLikeMM2PlayerData(data) then
        return data
    end

    return nil
end

local function ApplyMM2PlayerData(data)
    local roleData = NormalizeMM2PlayerDataContainer(data)

    if not roleData then
        return false
    end

    local newRoles = {}
    local newDead = {}
    local foundCurrentPlayer = false

    for playerKey, info in pairs(roleData) do
        local target = ResolveMM2Player(playerKey)

        if target then
            foundCurrentPlayer = true

            if typeof(info) == "table" then
                local dead = info.Dead == true
                    or info.Killed == true
                    or info.Eliminated == true

                newDead[target] = dead

                if not dead then
                    local role = NormalizeRoleName(info.Role)

                    if role then
                        newRoles[target] = role
                    end
                end
            else
                local role = NormalizeRoleName(info)

                if role then
                    newRoles[target] = role
                    newDead[target] = false
                end
            end
        end
    end

    if foundCurrentPlayer then
        MM2RoleCache = newRoles
        MM2DeadCache = newDead
        MM2HasAuthoritativeData = true
        MM2RoleCacheTime = tick()
        return true
    end

    return false
end

local function ApplyMM2PlayerUpdate(playerKey, info)
    local target = ResolveMM2Player(playerKey)

    if not target or typeof(info) ~= "table" then
        return false
    end

    MM2HasAuthoritativeData = true
    MM2RoleCacheTime = tick()

    local dead = info.Dead == true
        or info.Killed == true
        or info.Eliminated == true

    MM2DeadCache[target] = dead

    if dead then
        MM2RoleCache[target] = nil
    else
        MM2RoleCache[target] = NormalizeRoleName(info.Role)
    end

    return true
end

local function HasNamedTool(p, names)
    if not p then
        return false
    end

    local containers = {
        p:FindFirstChildOfClass("Backpack"),
        p.Character
    }

    for _, container in ipairs(containers) do
        if container then
            for _, child in ipairs(container:GetChildren()) do
                local childName = string.lower(child.Name)

                for _, wantedName in ipairs(names) do
                    if childName == wantedName then
                        return true
                    end
                end
            end
        end
    end

    return false
end

local function GetAttributeRole(p)
    if not p then
        return nil
    end

    local roleKeys = {
        "Role",
        "RoleName"
    }

    local containers = {
        p,
        p.Character
    }

    for _, container in ipairs(containers) do
        if container then
            for _, key in ipairs(roleKeys) do
                local ok, value = pcall(function()
                    return container:GetAttribute(key)
                end)

                if ok then
                    local normalized = NormalizeRoleName(value)

                    if normalized then
                        return normalized
                    end
                end

                local valueObject = container:FindFirstChild(key)

                if valueObject and valueObject:IsA("StringValue") then
                    local normalized = NormalizeRoleName(valueObject.Value)

                    if normalized then
                        return normalized
                    end
                end
            end
        end
    end

    return nil
end

local function BuildMM2FallbackRoles()
    local newCache = {}
    local detectedSpecialRole = false

    for _, p in ipairs(Players:GetPlayers()) do
        local attributeRole = GetAttributeRole(p)

        if attributeRole then
            newCache[p] = attributeRole

            if attributeRole == "Murderer"
            or attributeRole == "Sheriff"
            or attributeRole == "Hero" then
                detectedSpecialRole = true
            end
        elseif HasNamedTool(p, {"knife"}) then
            newCache[p] = "Murderer"
            detectedSpecialRole = true
        elseif HasNamedTool(p, {"gun", "revolver"}) then
            newCache[p] = "Sheriff"
            detectedSpecialRole = true
        end
    end

    if detectedSpecialRole then
        for _, p in ipairs(Players:GetPlayers()) do
            if not newCache[p] then
                local char = p.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")

                if hum and hum.Health > 0 then
                    newCache[p] = "Innocent"
                end
            end
        end

        MM2RoleCache = newCache
        MM2DeadCache = {}
        MM2RoleCacheTime = tick()
        return true
    end

    return false
end

local function RefreshMM2Roles(force)
    if game.GameId ~= MM2GameId and game.PlaceId ~= MM2PlaceId then
        return
    end

    local now = tick()

    if not force and now - MM2RoleCacheTime < 0.3 then
        return
    end

    MM2RoleCacheTime = now

    if not MM2PlayerDataRemote or not MM2PlayerDataRemote.Parent then
        MM2PlayerDataRemote = ReplicatedStorage:FindFirstChild("GetPlayerData", true)
    end

    if MM2PlayerDataRemote and MM2PlayerDataRemote:IsA("RemoteFunction") then
        local ok, data = pcall(function()
            return MM2PlayerDataRemote:InvokeServer()
        end)

        if ok then
            local applied = ApplyMM2PlayerData(data)

            if applied then
                return
            end

            MM2RoleCache = {}
            MM2DeadCache = {}
            MM2HasAuthoritativeData = false
        end
    end

    if not BuildMM2FallbackRoles() then
        MM2RoleCache = {}
        MM2DeadCache = {}
    end
end

getgenv().ToxRefreshMM2Roles = RefreshMM2Roles

getgenv().ToxGetMM2Role = function(p)
    if not p then
        return nil
    end

    if game.GameId == MM2GameId or game.PlaceId == MM2PlaceId then
        RefreshMM2Roles(false)

        if MM2DeadCache[p] then
            return nil
        end

        return MM2RoleCache[p]
    end

    return GetAttributeRole(p)
end

if game.GameId == MM2GameId or game.PlaceId == MM2PlaceId then
    local updatePlayerData = ReplicatedStorage:FindFirstChild("UpdatePlayerData", true)

    if updatePlayerData and updatePlayerData:IsA("RemoteEvent") then
        AddConnection(updatePlayerData.OnClientEvent:Connect(function(...)
            local args = {...}

            if #args >= 2 and ApplyMM2PlayerUpdate(args[1], args[2]) then
                return
            end

            for _, value in ipairs(args) do
                if ApplyMM2PlayerData(value) then
                    return
                end
            end

            task.defer(function()
                RefreshMM2Roles(true)
            end)
        end))
    end

    local roleSelect = ReplicatedStorage:FindFirstChild("RoleSelect", true)

    if roleSelect and roleSelect:IsA("RemoteEvent") then
        AddConnection(roleSelect.OnClientEvent:Connect(function(...)
            local args = {...}

            for _, value in ipairs(args) do
                local normalized = NormalizeRoleName(value)

                if normalized then
                    MM2RoleCache[Player] = normalized
                    MM2DeadCache[Player] = false
                    MM2RoleCacheTime = tick()
                    break
                end
            end

            task.delay(0.1, function()
                RefreshMM2Roles(true)
            end)
        end))
    end

    AddConnection(Players.PlayerRemoving:Connect(function(p)
        MM2RoleCache[p] = nil
        MM2DeadCache[p] = nil
    end))

    task.spawn(function()
        while not getgenv().Destroyed and game.PlaceId == MM2PlaceId do
            RefreshMM2Roles(true)
            task.wait(0.5)
        end
    end)
end

local function GetESPVisualInfo(p)
    local defaultColor = Settings.EspColor or Color3.fromRGB(255, 255, 255)
    local mm2RoleESPActive = (game.GameId == MM2GameId or game.PlaceId == MM2PlaceId)
        and Settings.MM2RoleESP == true

    if not Settings.ESPTeamColors and not mm2RoleESPActive then
        return defaultColor, nil
    end

    if game.GameId == MM2GameId or game.PlaceId == MM2PlaceId then
        local role = getgenv().ToxGetMM2Role and getgenv().ToxGetMM2Role(p) or nil

        if role then
            return RoleColors[role] or MM2UnknownColor, role
        end

        return MM2UnknownColor, nil
    end

    local attributeRole = GetAttributeRole(p)

    if attributeRole then
        return RoleColors[attributeRole] or defaultColor, attributeRole
    end

    if p and p.Team then
        local ok, teamColor = pcall(function()
            return p.TeamColor.Color
        end)

        if ok and typeof(teamColor) == "Color3" then
            return teamColor, p.Team.Name
        end
    end

    return defaultColor, nil
end

local function ClearESPForPlayer(p)
    if ESPDrawings[p] then
        for _, d in pairs(ESPDrawings[p]) do pcall(function() d:Remove() end) end
        ESPDrawings[p] = nil
    end

    if Highlights[p] then
        pcall(function() Highlights[p]:Destroy() end)
        Highlights[p] = nil
    end

    if ESPLabels[p] then
        pcall(function() ESPLabels[p]:Destroy() end)
        ESPLabels[p] = nil
    end

    ESPCharacterRefs[p] = nil
end

CreateToggle("Ctrl Click TP", FlingPage, Settings.CtrlClickTP, function(v)
    if getgenv().ToxSetSharedOption then getgenv().ToxSetSharedOption("CtrlClickTP", v) end
end, "CtrlClickTP")
CreateToggle("No Fall Damage", FlingPage, Settings.NoFallDamage, function(v)
    if getgenv().ToxSetSharedOption then getgenv().ToxSetSharedOption("NoFallDamage", v) end
end, "NoFallDamage")
CreateToggle("Anti Void", FlingPage, Settings.AntiVoid, function(v)
    if getgenv().ToxSetSharedOption then getgenv().ToxSetSharedOption("AntiVoid", v) end
end, "AntiVoid")
CreateToggle("Anti Fling", FlingPage, Settings.AntiFling, function(v)
    if getgenv().ToxSetSharedOption then getgenv().ToxSetSharedOption("AntiFling", v) end
end, "AntiFling")
CreateToggle("Fullbright", FlingPage, Settings.Fullbright, function(v) Settings.Fullbright = v UpdateFullbright() end)
CreateToggle("Force Shift Lock", FlingPage, Settings.ForceShiftLock, function(v)
    if v then
        CaptureShiftLockDefaults()
    end

    Settings.ForceShiftLock = v

    if not v then
        RestoreShiftLockDefaults()
    end
end)
CreateDropdown("Shift Lock Key", {"Shift", "Ctrl"}, FlingPage, Settings.ShiftLockKey, function(v) Settings.ShiftLockKey = v end)
CreateToggle("Walk Fling", FlingPage, Settings.WalkFling, function(v)
    if getgenv().ToxSetSharedOption then
        getgenv().ToxSetSharedOption(
            "WalkFling",
            v
        )
    end
end, "WalkFling")
CreateInputWithButton("Fling", FlingPage, "", "Fling", function(text) ExecuteFling(text) end)
CreateInputWithTwoButtons("Teleport", FlingPage, "", "TP", "Loop TP", function(text, mode) ExecuteTeleport(text, mode) end)
CreateButton("Tox Music Player", FlingPage, function() MusicGui.Visible = not MusicGui.Visible end)
CreateButton("Tox Waypoints", FlingPage, function() WaypointsGui.Visible = not WaypointsGui.Visible end)

CreateButton("BigFroot", ScriptsPage, function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/BG-0o/Scripts/refs/heads/main/BigFroot.lua"))()
end)

CreateButton("FE Emotes", ScriptsPage, function()
    loadstring(game:HttpGet(('https://raw.githubusercontent.com/VenezzaX/Usefulthings/refs/heads/main/FeEmotes.lua'),true))()
end)

CreateButton("PShade", ScriptsPage, function()
    loadstring(game:HttpGet('https://raw.githubusercontent.com/randomstring0/pshade-ultimate/refs/heads/main/src/cd.lua'))()
end)

CreateButton("Infinite Yield", ScriptsPage, function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
end)

CreateButton("Bundle Edit", ScriptsPage, function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/BG-0o/All/refs/heads/main/BundleEdit.lua"))()
end)

CreateToggle("Anti AFK", ConfigPage, Settings.AntiAFK, function(v) Settings.AntiAFK = v end)
CreateToggle("Chat Logs", ConfigPage, Settings.ChatLogs, function(v) Settings.ChatLogs = v ChatLogGui.Visible = v end)
CreateToggle("3D Rendering", ConfigPage, Settings.Render3D, function(v) 
    Settings.Render3D = v 
    pcall(function() RunService:Set3dRenderingEnabled(v) end)
end)
CreateToggle("Auto Execute", ConfigPage, Settings.AutoExecute, function(v)
    Settings.AutoExecute = v == true

    if Settings.AutoExecute then
        local queueFunction = getgenv().QueueToxAutoExecute

        if queueFunction and queueFunction() then
            CustomNotify(
                "Auto Execute Enabled",
                Color3.fromRGB(100, 255, 100)
            )
        else
            CustomNotify(
                "Auto Execute is not supported by this executor",
                Color3.fromRGB(255, 180, 70)
            )
        end
    else
        CustomNotify(
            "Auto Execute Disabled",
            Color3.fromRGB(255, 180, 70)
        )
    end
end)
CreateKeybindButton("GUI Keybind", ConfigPage, Settings.GUIKeybind, function(key)
    Settings.GUIKeybind = key

    if getgenv().AutoSaveConfiguration then
        getgenv().AutoSaveConfiguration()
    end
end)
CreateConfirmButton("FPS Booster", ConfigPage, function() BoostFPS() end)
CreateConfirmButton("Server Hop", ConfigPage, function() ServerHop() end)
CreateConfirmButton("Rejoin Server", ConfigPage, function()
	if #Players:GetPlayers() <= 1 then TeleportService:Teleport(game.PlaceId, Player)
	else TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Player) end
end)

CreateConfirmButton("DESTROY", ConfigPage, function()
    if AutoSaveConfiguration then
        pcall(AutoSaveConfiguration)
    end

    Destroyed = true
    getgenv().Destroyed = true
    ScriptLoaded = false
    getgenv().ScriptLoaded = false

    if getgenv().ToxMM2Cleanup then
        pcall(getgenv().ToxMM2Cleanup)
    end

    if getgenv().SetNDSWaterFly then
        pcall(function()
            getgenv().SetNDSWaterFly(false, true)
        end)
    end

    if getgenv().SetNDSNoTP then
        pcall(function()
            getgenv().SetNDSNoTP(false, true)
        end)
    end

    for key, value in pairs(Settings) do
        if typeof(value) == "boolean" then
            Settings[key] = false
        end
    end

    Settings.Render3D = true
    Settings.LoopTPTarget = nil
    Settings.NDSAutoWin = false
    Settings.NDSWaterFly = false
    Settings.NDSNoTP = false
    Settings.MM2AutoFarm = false
    Settings.MM2RoleESP = false
    Settings.MM2KillAllAuto = false
    Settings.MM2ShootMurderAuto = false
    Settings.MM2GrabGunAuto = false

    local sharedKeys =
        getgenv().SharedPersistentKeys or {}
    local baseShared =
        getgenv().BaseSharedSettings or {}

    for key in pairs(sharedKeys) do
        if typeof(Settings[key]) == "boolean" then
            Settings[key] = false
        end

        if typeof(baseShared[key]) == "boolean" then
            baseShared[key] = false
        end
    end

    pcall(function()
        RunService:Set3dRenderingEnabled(true)
    end)

    Settings.Fullbright = false
    UpdateFullbright()

    Settings.AirWalk = false
    UpdateAirWalk()

    Settings.Speed = false
    Settings.Jump = false
    Settings.Noclip = false
    Settings.AntiFling = false
    Settings.WalkFling = false
    StopWalkFling()
    StopAntiVoid()
    if getgenv().ToxSystemsCleanup then
        pcall(
            getgenv().ToxSystemsCleanup
        )
    end
    Settings.HitboxExpander = false
    Settings.FOVEnabled = false
    Settings.ForceShiftLock = false
    Settings.SmoothFly = false
    Settings.NormalFly = false
    Settings.CarFly = false
    DestroyCarFlyMovers()
    Settings.ChatLogs = false
    Settings.MusicAutoPlay = false
    Settings.MusicLoop = false
    Settings.AutoExecute = false

    RestoreSpeed()
    RestoreJump()
    RestoreNoclipDefaults()
    RestoreAntiFlingDefaults()
    RestoreHitboxDefaults()
    RestoreFOVDefault()
    RestoreShiftLockDefaults()

    isShiftLockActive = false
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default

    if ChatLogGui then
        ChatLogGui.Visible = false
    end

    local Hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
    local Root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")

    if Hum then
        Hum.PlatformStand = false
        Hum.Sit = false
        Hum.AutoRotate = true
    end

    if Root then
        Root.AssemblyLinearVelocity = Vector3.zero
        Root.AssemblyAngularVelocity = Vector3.zero
    end

    RunService.Heartbeat:Wait()
    RunService.Heartbeat:Wait()

    if getgenv().ActiveSound then
        pcall(function()
            getgenv().ActiveSound:Stop()
            getgenv().ActiveSound:Destroy()
        end)

        getgenv().ActiveSound = nil
    end

    for _, hl in pairs(Highlights) do
        pcall(function()
            hl:Destroy()
        end)
    end

    Highlights = {}

    for _, esp in pairs(ESPDrawings) do
        for _, drawing in pairs(esp) do
            pcall(function()
                drawing:Remove()
            end)
        end
    end

    ESPDrawings = {}

    if FOVCircle then
        pcall(function()
            FOVCircle:Remove()
        end)
    end

    if CrosshairH then
        pcall(function()
            CrosshairH:Remove()
        end)
    end

    if CrosshairV then
        pcall(function()
            CrosshairV:Remove()
        end)
    end

    for _, conn in ipairs(ScriptConnections) do
        pcall(function()
            conn:Disconnect()
        end)
    end

    pcall(function()
        NotifGui:Destroy()
    end)

    pcall(function()
        Gui:Destroy()
    end)
end)

AddConnection(UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and Settings.ForceShiftLock then
        local key = Settings.ShiftLockKey
        local match = false
        if key == "Shift" and (input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift) then
            match = true
        elseif key == "Ctrl" and (input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl) then
            match = true
        end
        if match then
            isShiftLockActive = not isShiftLockActive
            UserInputService.MouseBehavior = isShiftLockActive and Enum.MouseBehavior.LockCenter or Enum.MouseBehavior.Default
        end
    end
end))

AddConnection(UserInputService.JumpRequest:Connect(function()
    local Hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
    if ScriptLoaded and Settings.InfiniteJump and Hum and Hum.Health > 0 then
        Hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end))

local SubGuisPreKeyHiddenState = {}

AddConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and Settings.CtrlClickTP and input.UserInputType == Enum.UserInputType.MouseButton1 then
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then
            local mouse = Player:GetMouse()
            local Root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if mouse and mouse.Hit and Root then
                if getgenv().AllowToxTeleport then getgenv().AllowToxTeleport(1.25) end
                Root.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
            end
        end
    end

    if Settings.GUIKeybind and input.KeyCode == Settings.GUIKeybind then
        if Main.Visible then
            SubGuisPreKeyHiddenState.ChatLog = ChatLogGui.Visible
            SubGuisPreKeyHiddenState.Music = MusicGui.Visible
            SubGuisPreKeyHiddenState.Waypoints = WaypointsGui.Visible
            SubGuisPreKeyHiddenState.ToxChat = ToxChatGui.Visible
            SubGuisPreKeyHiddenState.QuickJoin = JoinGamesGui and JoinGamesGui.Visible or false

            Main.Visible = false
            ChatLogGui.Visible = false
            MusicGui.Visible = false
            WaypointsGui.Visible = false
            ToxChatGui.Visible = false
            if JoinGamesGui then JoinGamesGui.Visible = false end

            for key, gui in pairs(getgenv().ToxLinkedSubGuis or {}) do
                if gui and gui.Parent then
                    SubGuisPreKeyHiddenState["Extra_" .. tostring(key)] = gui.Visible
                    gui.Visible = false
                end
            end
        else
            Main.Visible = true

            if Tabs.Visible then
                if SubGuisPreKeyHiddenState.ChatLog ~= nil then
                    ChatLogGui.Visible = SubGuisPreKeyHiddenState.ChatLog
                end
                if SubGuisPreKeyHiddenState.Music ~= nil then
                    MusicGui.Visible = SubGuisPreKeyHiddenState.Music
                end
                if SubGuisPreKeyHiddenState.Waypoints ~= nil then
                    WaypointsGui.Visible = SubGuisPreKeyHiddenState.Waypoints
                end
                if SubGuisPreKeyHiddenState.ToxChat ~= nil then
                    ToxChatGui.Visible = SubGuisPreKeyHiddenState.ToxChat
                end
                if JoinGamesGui and SubGuisPreKeyHiddenState.QuickJoin ~= nil then
                    JoinGamesGui.Visible = SubGuisPreKeyHiddenState.QuickJoin
                end

                for key, gui in pairs(getgenv().ToxLinkedSubGuis or {}) do
                    local saved = SubGuisPreKeyHiddenState["Extra_" .. tostring(key)]

                    if gui and gui.Parent and saved ~= nil then
                        gui.Visible = saved
                    end
                end
            else
                ChatLogGui.Visible = false
                MusicGui.Visible = false
                WaypointsGui.Visible = false
                ToxChatGui.Visible = false
                if JoinGamesGui then JoinGamesGui.Visible = false end
            end
        end
    end
end))

if Settings.WalkFling then
    StartWalkFling()
end

AddConnection(Player.Idled:Connect(function()
    if ScriptLoaded and Settings.AntiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end))

AddConnection(RunService.Stepped:Connect(function()
    if Destroyed or not ScriptLoaded then return end

    if Settings.Noclip and Player.Character then
        for _, part in ipairs(Player.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                if NoclipDefaults[part] == nil then
                    NoclipDefaults[part] = part.CanCollide
                end
                part.CanCollide = false
            end
        end
    end

    if Settings.AntiFling then
        if Settings.WalkFling then
            local root =
                Player.Character
                and Player.Character:
                    FindFirstChild(
                        "HumanoidRootPart"
                    )

            if root
            and not WalkFlingImpulseActive
            and root.AssemblyLinearVelocity.Magnitude
                > 350 then
                root.AssemblyLinearVelocity =
                    Vector3.zero
                root.AssemblyAngularVelocity =
                    Vector3.zero
            end
        else
            for _, p in ipairs(
                Players:GetPlayers()
            ) do
                if p ~= Player
                and p.Character then
                    for _, part in ipairs(
                        p.Character:GetChildren()
                    ) do
                        if part:IsA(
                            "BasePart"
                        ) then
                            if AntiFlingDefaults[part]
                            == nil then
                                AntiFlingDefaults[part] =
                                    part.CanCollide
                            end

                            part.CanCollide = false
                        end
                    end
                end
            end
        end
    end

    local Root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if Settings.NoFallDamage and Root then
        local velocity = Root.AssemblyLinearVelocity
        local triggerVelocity = game.PlaceId == 189707 and -60 or -40
        local safeVelocity = game.PlaceId == 189707 and -45 or -35

        if velocity.Y < triggerVelocity then
            Root.AssemblyLinearVelocity = Vector3.new(velocity.X, safeVelocity, velocity.Z)
        end
    end

    UpdateAirWalk()
    if Settings.Fullbright then UpdateFullbright() end
end))

local FlyBV, FlyBG
local function DisableNormalFlyPhysics()
    local Hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
    if FlyBV then FlyBV:Destroy() FlyBV = nil end
    if FlyBG then FlyBG:Destroy() FlyBG = nil end
    if Hum then Hum.PlatformStand = false end
end

AddConnection(RunService.RenderStepped:Connect(function(delta)
	if Destroyed or not ScriptLoaded then return end

    local Hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
    local Root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")

    if Hum and Hum.Health > 0 then
        local defaults = GetHumanoidDefaults(Hum)

        if Settings.Speed then
            Hum.WalkSpeed = Settings.SpeedValue
        end

        if Settings.Jump then
            Hum.UseJumpPower = true
            Hum.JumpPower = Settings.JumpValue
        elseif defaults and HumanoidDefaults[Hum] == defaults then
            if Hum.UseJumpPower ~= defaults.UseJumpPower and not Settings.Jump then
                Hum.UseJumpPower = defaults.UseJumpPower
                Hum.JumpPower = defaults.JumpPower
                Hum.JumpHeight = defaults.JumpHeight
            end
        end

        if Settings.Bhop then
            local interval = math.max(0.05, tonumber(Settings.BhopInterval) or 0.2)
            getgenv().BhopTimer = (getgenv().BhopTimer or 0) + delta
            if getgenv().BhopTimer >= interval and (Hum.FloorMaterial ~= Enum.Material.Air or Hum:GetState() == Enum.HumanoidStateType.Landed) then
                getgenv().BhopTimer = 0
                Hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        else
            getgenv().BhopTimer = 0
        end
    end

    if Settings.FOVEnabled then
        CaptureFOVDefault()
        Camera.FieldOfView = Settings.FOVValue or FOVDefault
    end

    if Settings.ForceShiftLock then
        CaptureShiftLockDefaults()
        Player.DevEnableMouseLock = true
        if isShiftLockActive and Root then
            Camera.CFrame = Camera.CFrame * CFrame.new(1.7, 0.5, 0)
            Root.CFrame = CFrame.new(Root.Position, Root.Position + Vector3.new(Camera.CFrame.LookVector.X, 0, Camera.CFrame.LookVector.Z))
        end
    end

    if Settings.LoopTPTarget and Settings.LoopTPTarget.Character and Settings.LoopTPTarget.Character:FindFirstChild("HumanoidRootPart") and Root then
        if getgenv().AllowToxTeleport then getgenv().AllowToxTeleport(0.2) end
        Root.CFrame = Settings.LoopTPTarget.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -3)
    end

    local seat = Hum and Hum.SeatPart

    if seat and Settings.CarSpeed and not Settings.CarFly then
        seat.AssemblyLinearVelocity =
            seat.CFrame.LookVector * (Settings.CarSpeedValue or 100)
    end

    if Settings.CarFly and seat then
        if EnsureCarFlyMovers(seat) then
            local flySpeed = math.clamp(
                tonumber(Settings.CarFlySpeed) or 80,
                5,
                300
            )

            local look = Camera.CFrame.LookVector
            local right = Camera.CFrame.RightVector
            local flatLook = Vector3.new(look.X, 0, look.Z)
            local flatRight = Vector3.new(right.X, 0, right.Z)
            local direction = Vector3.zero

            if flatLook.Magnitude > 0.01 then
                flatLook = flatLook.Unit
            end

            if flatRight.Magnitude > 0.01 then
                flatRight = flatRight.Unit
            end

            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                direction = direction + flatLook
            end

            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                direction = direction - flatLook
            end

            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                direction = direction - flatRight
            end

            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                direction = direction + flatRight
            end

            if UserInputService:IsKeyDown(Enum.KeyCode.Space)
            or UserInputService:IsKeyDown(Enum.KeyCode.E) then
                direction = direction + Vector3.new(0, 1, 0)
            end

            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
            or UserInputService:IsKeyDown(Enum.KeyCode.Q) then
                direction = direction - Vector3.new(0, 1, 0)
            end

            if direction.Magnitude > 0 then
                CarFlyVelocity.Velocity = direction.Unit * flySpeed
            else
                CarFlyVelocity.Velocity = Vector3.zero
            end

            seat.AssemblyAngularVelocity = Vector3.zero

            if flatLook.Magnitude > 0.01 then
                CarFlyGyro.CFrame = CFrame.lookAt(
                    seat.Position,
                    seat.Position + flatLook
                )
            else
                CarFlyGyro.CFrame = seat.CFrame
            end
        end
    else
        DestroyCarFlyMovers()
    end

    if Settings.Spinbot and Root then
        Root.CFrame = Root.CFrame * CFrame.Angles(0, math.rad(Settings.SpinSpeed or 50), 0)
    end

    local actualFlySpeed = (Settings.FlySpeed or 10) * 10

    if Settings.SmoothFly and Root and Hum and Hum.Health > 0 then
        DisableNormalFlyPhysics()
        Hum.PlatformStand = true
        Root.AssemblyLinearVelocity = Vector3.zero
        Root.AssemblyAngularVelocity = Vector3.zero

        local moveDir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) or UserInputService:IsKeyDown(Enum.KeyCode.E) then moveDir = moveDir + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.Q) then moveDir = moveDir - Vector3.new(0, 1, 0) end

        if moveDir.Magnitude > 0 then
            moveDir = moveDir.Unit
            Root.CFrame = Root.CFrame + (moveDir * (actualFlySpeed * delta))
        end
    elseif Settings.NormalFly and Root and Hum and Hum.Health > 0 then
        if not FlyBV or FlyBV.Parent ~= Root then
            DisableNormalFlyPhysics()
            FlyBV = Instance.new("BodyVelocity")
            FlyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            FlyBV.Velocity = Vector3.zero
            FlyBV.Parent = Root

            FlyBG = Instance.new("BodyGyro")
            FlyBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            FlyBG.CFrame = Root.CFrame
            FlyBG.Parent = Root
        end

        Hum.PlatformStand = true
        local dir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) or UserInputService:IsKeyDown(Enum.KeyCode.E) then dir = dir + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.Q) then dir = dir - Vector3.new(0, 1, 0) end

        FlyBV.Velocity = dir * actualFlySpeed
        FlyBG.CFrame = Camera.CFrame
    else
        DisableNormalFlyPhysics()
    end

    if FOVCircle then
        FOVCircle.Visible = Settings.Aimbot and Settings.ShowFOV
        FOVCircle.Radius = Settings.FOVRadius or 120
        FOVCircle.Position = UserInputService:GetMouseLocation()
    end

    if CrosshairH and CrosshairV then
        CrosshairH.Visible = false
        CrosshairV.Visible = false
    end

    if Settings.Aimbot and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local Target = GetClosestPlayerToMouse()
        if Target then
            local Smooth = Settings.AimbotSmoothness or 2
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, Target.Position), 1 / Smooth)
        end
    end

    if Settings.Triggerbot then
        local mousePos = UserInputService:GetMouseLocation()
        local ray = Camera:ViewportPointToRay(mousePos.X, mousePos.Y)
        local result = workspace:Raycast(ray.Origin, ray.Direction * 1000)
        if result and result.Instance then
            local targetModel = result.Instance:FindFirstAncestorOfClass("Model")
            local targetPlayer = targetModel and Players:GetPlayerFromCharacter(targetModel)
            if targetPlayer and targetPlayer ~= Player then
                local tool = Player.Character and Player.Character:FindFirstChildOfClass("Tool")
                if tool then tool:Activate() end
            end
        end
    end

    local mm2RoleESPActive = (game.GameId == MM2GameId or game.PlaceId == MM2PlaceId)
        and Settings.MM2RoleESP == true
    local effectiveESPEnabled = Settings.ESPEnabled or mm2RoleESPActive
    local effectiveESPNames = Settings.ESPNames or mm2RoleESPActive
    local effectiveChams = Settings.Chams or mm2RoleESPActive
    local effectiveTeamColors = Settings.ESPTeamColors or mm2RoleESPActive

    local anyESPActive = effectiveESPEnabled and (effectiveESPNames
        or Settings.ESPDistance
        or Settings.ESPTracers
        or Settings.ESPBox
        or Settings.ESPHeadDot
        or effectiveChams)

    if anyESPActive and tick() - LastESPSafetyRefresh >= 6 then
        LastESPSafetyRefresh = tick()

        local refreshPlayers = {}

        for p in pairs(ESPDrawings) do
            table.insert(refreshPlayers, p)
        end

        for p in pairs(Highlights) do
            if not ESPDrawings[p] then
                table.insert(refreshPlayers, p)
            end
        end

        for p in pairs(ESPLabels) do
            if not ESPDrawings[p] and not Highlights[p] then
                table.insert(refreshPlayers, p)
            end
        end

        for _, p in ipairs(refreshPlayers) do
            ClearESPForPlayer(p)
        end
    end

    for p, _ in pairs(ESPDrawings) do
        if not p or not p.Parent or not Players:FindFirstChild(p.Name) then
            ClearESPForPlayer(p)
        end
    end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player then
            if p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChildOfClass("Humanoid") then
                local char = p.Character

                if ESPCharacterRefs[p] and ESPCharacterRefs[p] ~= char then
                    ClearESPForPlayer(p)
                end

                ESPCharacterRefs[p] = char

                local hrp = char.HumanoidRootPart
                local hum = char:FindFirstChildOfClass("Humanoid")
                local espColor, espRole = GetESPVisualInfo(p)

                if effectiveESPEnabled and effectiveChams then
                    local hl = Highlights[p]
                    if not hl or hl.Parent ~= char then
                        if hl then hl:Destroy() end
                        hl = Instance.new("Highlight")
                        hl.Name = "ToxChams"
                        hl.Adornee = char
                        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        hl.Parent = char
                        Highlights[p] = hl
                    end
                    hl.FillColor = espColor
                    hl.OutlineColor = espColor
                    hl.FillTransparency = 0.5
                else
                    if Highlights[p] then Highlights[p]:Destroy() Highlights[p] = nil end
                end

                local distFromMe = Root and (Root.Position - hrp.Position).Magnitude or 0
                local withinDist = (Settings.EspMaxDistance <= 0) or (distFromMe <= Settings.EspMaxDistance)

                if effectiveESPEnabled and (effectiveESPNames or Settings.ESPDistance) and hum.Health > 0 and withinDist then
                    local billboard = ESPLabels[p]

                    if not billboard or billboard.Parent ~= char then
                        if billboard then billboard:Destroy() end

                        billboard = Instance.new("BillboardGui")
                        billboard.Name = "ToxESPName"
                        billboard.Adornee = char:FindFirstChild("Head") or hrp
                        billboard.AlwaysOnTop = true
                        billboard.Size = UDim2.fromOffset(320, 44)
                        billboard.StudsOffset = Vector3.new(0, 3.2, 0)
                        billboard.MaxDistance = Settings.EspMaxDistance > 0 and Settings.EspMaxDistance or 100000
                        billboard.Parent = char

                        local label = Instance.new("TextLabel")
                        label.Name = "Label"
                        label.Size = UDim2.fromScale(1, 1)
                        label.BackgroundTransparency = 1
                        label.TextColor3 = espColor
                        label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                        label.TextStrokeTransparency = 0
                        label.TextSize = 13
                        label.Font = Enum.Font.Gotham
                        label.TextWrapped = true
                        label.TextXAlignment = Enum.TextXAlignment.Center
                        label.TextYAlignment = Enum.TextYAlignment.Center
                        label.Parent = billboard

                        ESPLabels[p] = billboard
                    end

                    local label = billboard:FindFirstChild("Label")
                    local lines = {}

                    if effectiveESPNames then
                        local mode = Settings.ESPNameMode or "Display"
                        local nameText

                        if mode == "Name" then
                            nameText = "@" .. p.Name
                        elseif mode == "Name + Display" then
                            nameText = p.DisplayName .. " (@" .. p.Name .. ")"
                        else
                            nameText = p.DisplayName
                        end

                        if effectiveTeamColors and espRole then
                            nameText = nameText .. " [" .. espRole .. "]"
                        end

                        table.insert(lines, nameText)
                    end

                    if Settings.ESPDistance then
                        table.insert(lines, "Dist: " .. math.floor(distFromMe) .. "m")
                    end

                    if label then
                        label.Text = table.concat(lines, "\n")
                        label.TextColor3 = espColor
                    end

                    billboard.Enabled = #lines > 0
                    billboard.MaxDistance = Settings.EspMaxDistance > 0 and Settings.EspMaxDistance or 100000
                elseif ESPLabels[p] then
                    ESPLabels[p]:Destroy()
                    ESPLabels[p] = nil
                end

                local hasDrawingESP = effectiveESPEnabled and (Settings.ESPTracers or Settings.ESPBox or Settings.ESPHeadDot)

                if hasDrawingESP and Drawing and hum.Health > 0 and withinDist then
                    local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)

                    if not ESPDrawings[p] then
                        ESPDrawings[p] = {
                            Line = Drawing.new("Line"),
                            Box = Drawing.new("Square"),
                            HeadDot = Drawing.new("Circle")
                        }
                    end

                    local lineDraw = ESPDrawings[p].Line
                    local boxDraw = ESPDrawings[p].Box
                    local headDraw = ESPDrawings[p].HeadDot

                    if onScreen then
                        if Settings.ESPTracers then
                            local startVector = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)

                            if Settings.TracerOrigin == "UP" then
                                startVector = Vector2.new(Camera.ViewportSize.X / 2, 0)
                            elseif Settings.TracerOrigin == "MOUSE" then
                                startVector = UserInputService:GetMouseLocation()
                            end

                            lineDraw.From = startVector
                            lineDraw.To = Vector2.new(pos.X, pos.Y)
                            lineDraw.Color = espColor
                            lineDraw.Thickness = 1
                            lineDraw.Visible = true
                        else
                            lineDraw.Visible = false
                        end

                        if Settings.ESPBox then
                            local boxHeight = math.clamp(1000 / pos.Z, 10, 300)
                            local boxWidth = boxHeight * 0.65
                            boxDraw.Size = Vector2.new(boxWidth, boxHeight)
                            boxDraw.Position = Vector2.new(pos.X - boxWidth / 2, pos.Y - boxHeight / 2)
                            boxDraw.Color = espColor
                            boxDraw.Thickness = 1.5
                            boxDraw.Filled = false
                            boxDraw.Visible = true
                        else
                            boxDraw.Visible = false
                        end

                        if Settings.ESPHeadDot then
                            local head = char:FindFirstChild("Head")

                            if head then
                                local hp, hon = Camera:WorldToViewportPoint(head.Position)
                                headDraw.Position = Vector2.new(hp.X, hp.Y)
                                headDraw.Radius = 4
                                headDraw.Filled = true
                                headDraw.Color = espColor
                                headDraw.Visible = hon
                            else
                                headDraw.Visible = false
                            end
                        else
                            headDraw.Visible = false
                        end
                    else
                        lineDraw.Visible = false
                        boxDraw.Visible = false
                        headDraw.Visible = false
                    end
                elseif ESPDrawings[p] then
                    for _, drawing in pairs(ESPDrawings[p]) do
                        drawing.Visible = false
                    end
                end
            else
                ClearESPForPlayer(p)
            end
        end
    end

    if Settings.HitboxExpander then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= Player and p.Character then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    if not HitboxDefaults[hrp] then
                        HitboxDefaults[hrp] = {
                            Size = hrp.Size,
                            Transparency = hrp.Transparency,
                            CanCollide = hrp.CanCollide
                        }
                    end

                    hrp.Size = Vector3.new(Settings.HitboxSize or 10, Settings.HitboxSize or 10, Settings.HitboxSize or 10)
                    hrp.Transparency = 0.7
                    hrp.CanCollide = false
                end
            end
        end
    end

    if Settings.KillAura and Root then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= Player and p.Character then
                local tHrp = p.Character:FindFirstChild("HumanoidRootPart")
                local tHum = p.Character:FindFirstChildOfClass("Humanoid")
                if tHrp and tHum and tHum.Health > 0 then
                    if (Root.Position - tHrp.Position).Magnitude <= (Settings.KillAuraRange or 15) then
                        local tool = Player.Character and Player.Character:FindFirstChildOfClass("Tool")
                        if tool then tool:Activate() end
                    end
                end
            end
        end
    end
end))

local function ShowCenterLoadSequence()
    local blur = Instance.new("BlurEffect")
    blur.Size = 18
    blur.Parent = Lighting

    local SplashFrame = Instance.new("Frame")
    SplashFrame.Size = UDim2.new(0, 360, 0, 110)
    SplashFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    SplashFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    SplashFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 16)
    SplashFrame.BorderSizePixel = 0
    SplashFrame.ClipsDescendants = true
    SplashFrame.Parent = NotifGui

    local Corner = Instance.new("UICorner") Corner.CornerRadius = UDim.new(0, 10) Corner.Parent = SplashFrame
    local Stroke = Instance.new("UIStroke") Stroke.Color = MAIN_COLOR Stroke.Thickness = 2 Stroke.Parent = SplashFrame

    local SplashLogo = Instance.new("ImageLabel")
    SplashLogo.Size = UDim2.new(0, 48, 0, 48)
    SplashLogo.Position = UDim2.new(0, 18, 0, 16)
    SplashLogo.BackgroundTransparency = 1
    SplashLogo.Image = LOGO_ID
    SplashLogo.Parent = SplashFrame

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -85, 0, 24)
    TitleLabel.Position = UDim2.new(0, 78, 0, 16)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = "ToxHub"
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextSize = 15
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = SplashFrame

    local SubLabel = Instance.new("TextLabel")
    SubLabel.Size = UDim2.new(1, -85, 0, 20)
    SubLabel.Position = UDim2.new(0, 78, 0, 40)
    SubLabel.BackgroundTransparency = 1
    SubLabel.Text = "Made by @BG_0o"
    SubLabel.TextColor3 = Color3.fromRGB(150, 150, 180)
    SubLabel.Font = Enum.Font.GothamMedium
    SubLabel.TextSize = 12
    SubLabel.TextXAlignment = Enum.TextXAlignment.Left
    SubLabel.Parent = SplashFrame

    local BarBackground = Instance.new("Frame")
    BarBackground.Size = UDim2.new(1, -36, 0, 8)
    BarBackground.Position = UDim2.new(0, 18, 1, -22)
    BarBackground.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
    BarBackground.BorderSizePixel = 0
    BarBackground.Parent = SplashFrame

    local BarCorner = Instance.new("UICorner") BarCorner.CornerRadius = UDim.new(0, 4) BarCorner.Parent = BarBackground
    local BarFill = Instance.new("Frame")
    BarFill.Size = UDim2.new(0, 0, 1, 0)
    BarFill.BackgroundColor3 = MAIN_COLOR
    BarFill.BorderSizePixel = 0
    BarFill.Parent = BarBackground
    local BarFillCorner = Instance.new("UICorner") BarFillCorner.CornerRadius = UDim.new(0, 4) BarFillCorner.Parent = BarFill

    local PercentLabel = Instance.new("TextLabel")
    PercentLabel.Size = UDim2.new(0, 40, 0, 18)
    PercentLabel.Position = UDim2.new(1, -58, 0, 16)
    PercentLabel.BackgroundTransparency = 1
    PercentLabel.Text = "0%"
    PercentLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    PercentLabel.Font = Enum.Font.GothamBold
    PercentLabel.TextSize = 12
    PercentLabel.TextXAlignment = Enum.TextXAlignment.Right
    PercentLabel.Parent = SplashFrame

    local duration = 4.0
    local steps = 50
    for i = 1, steps do
        local p = i / steps
        BarFill.Size = UDim2.new(p, 0, 1, 0)
        PercentLabel.Text = math.floor(p * 100) .. "%"
        if i == steps then TitleLabel.Text = "ToxHub Loaded Successfully" end
        task.wait(duration / steps)
    end

    ScriptLoaded = true
    if blur then blur:Destroy() end

    local fallTween = TweenService:Create(SplashFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
        Position = UDim2.new(0.5, 0, 1.3, 0),
        BackgroundTransparency = 1
    })
    fallTween:Play()
    fallTween.Completed:Connect(function()
        SplashFrame:Destroy()
        if not Destroyed then
            local finalPosition = (getgenv().GetSavedGuiPosition and getgenv().GetSavedGuiPosition("Main")) or UDim2.new(0.5, -165, 0.5, -197)

            Main.Size = UDim2.new(0, 0, 0, 0)
            Main.Position = finalPosition
            Main.Visible = true

            Main:TweenSizeAndPosition(
                UDim2.new(0, 330, 0, 395),
                finalPosition,
                Enum.EasingDirection.Out,
                Enum.EasingStyle.Back,
                0.5,
                true
            )

            CustomNotify("ToxHub v1 Loaded Successfully!", Color3.fromRGB(100, 255, 100))
        end
    end)
end

task.spawn(ShowCenterLoadSequence)

local SubGuisPreMinimizedState = {}
local Minimize = getgenv().Minimize
local Minimized = false

local function CollapseSubGuiWithMain(key, gui)
    if not gui then return end

    local control = SubGuiControls[gui]

    SubGuisPreMinimizedState[key] = {
        Visible = gui.Visible,
        WasMinimized = control and control.Minimized or false
    }

    if gui.Visible and control and not control.Minimized then
        SetSubGuiMinimized(control, true)
    end
end

local function RestoreSubGuiAfterMain(key, gui)
    if not gui then return end

    local state = SubGuisPreMinimizedState[key]
    if not state then return end

    gui.Visible = state.Visible

    local control = SubGuiControls[gui]
    if control then
        SetSubGuiMinimized(control, state.WasMinimized)
    end
end

if Minimize then
    Minimize.MouseButton1Click:Connect(function()
        Minimized = not Minimized
        Main.Size = Minimized and UDim2.new(0, 330, 0, 38) or UDim2.new(0, 330, 0, 395)
        Tabs.Visible = not Minimized
        if getgenv().CurrentPage then getgenv().CurrentPage.Visible = not Minimized end
        Minimize.Text = Minimized and "+" or "-"

        if Minimized then
            CollapseSubGuiWithMain("ChatLog", ChatLogGui)
            CollapseSubGuiWithMain("Music", MusicGui)
            CollapseSubGuiWithMain("Waypoints", WaypointsGui)
            CollapseSubGuiWithMain("ToxChat", ToxChatGui)
            CollapseSubGuiWithMain("QuickJoin", JoinGamesGui)

            for key, gui in pairs(getgenv().ToxLinkedSubGuis or {}) do
                CollapseSubGuiWithMain("Extra_" .. tostring(key), gui)
            end
        else
            RestoreSubGuiAfterMain("ChatLog", ChatLogGui)
            RestoreSubGuiAfterMain("Music", MusicGui)
            RestoreSubGuiAfterMain("Waypoints", WaypointsGui)
            RestoreSubGuiAfterMain("ToxChat", ToxChatGui)
            RestoreSubGuiAfterMain("QuickJoin", JoinGamesGui)

            for key, gui in pairs(getgenv().ToxLinkedSubGuis or {}) do
                RestoreSubGuiAfterMain("Extra_" .. tostring(key), gui)
            end
        end
    end)
end

if Settings.AntiVoid then StartAntiVoid() end

getgenv().ToxUniversalLoaded = true
