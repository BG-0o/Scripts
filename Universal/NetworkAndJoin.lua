local env = getgenv()
if env.Destroyed or env.ToxUniversalLoaded then
    return
end
env.ToxUniversal = env.ToxUniversal or {}
local U = env.ToxUniversal
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local GuiService = game:GetService("GuiService")
local CoreGui = game:GetService("CoreGui")
local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Settings = env.Settings or {}
local MAIN_COLOR = env.MAIN_COLOR or Color3.fromRGB(0, 170, 255)
local MM2PlaceId = U.MM2PlaceId or 142823291
local RequestFunction = U.RequestFunction or env.ToxRequestFunction
local JoinGamesGui = env.JoinGamesGui
local JoinGamesScroll = env.JoinGamesScroll
local JoinGameIdBox = env.JoinGameIdBox
local JoinGameAddButton = env.JoinGameAddButton
local JoinPage = env.JoinPage
local SavedJoinGames = env.SavedJoinGames or {}
local function CustomNotify(...) if env.CustomNotify then return env.CustomNotify(...) end end
local function AutoSaveConfiguration(...) if env.AutoSaveConfiguration then return env.AutoSaveConfiguration(...) end end
local function AddConnection(...) if env.AddConnection then return env.AddConnection(...) end end
do
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
local ToxRelayHost =
    "https://tox-control-relay.1kobg-0o.workers.dev"
local function PresenceRelayRequestOnce(
    userId
)
    local url =
        ToxRelayHost
        .. "/roblox/presence?userId="
        .. tostring(userId)
        .. "&_="
        .. tostring(
            math.floor(
                os.clock() * 1000
            )
        )
    local body = nil
    if RequestFunction then
        local ok, response =
            pcall(function()
                return RequestFunction({
                    Url = url,
                    Method = "GET",
                    Headers = {
                        ["Accept"] =
                            "application/json",
                        ["Cache-Control"] =
                            "no-cache"
                    }
                })
            end)
        if ok
        and typeof(response)
            == "table" then
            local status =
                tonumber(
                    response.StatusCode
                    or response.Status
                    or 0
                ) or 0
            local success =
                response.Success
            if success == nil then
                success =
                    response.success
            end
            if (
                status >= 200
                and status < 300
            )
            or success == true then
                body =
                    response.Body
                    or response.body
            end
        end
    end
    if typeof(body)
        ~= "string"
    or body == "" then
        local ok, response =
            pcall(function()
                return game:HttpGet(
                    url,
                    true
                )
            end)
        if not ok then
            ok, response =
                pcall(function()
                    return game:HttpGet(
                        url
                    )
                end)
        end
        if ok
        and typeof(response)
            == "string" then
            body = response
        end
    end
    if typeof(body)
        ~= "string"
    or body == "" then
        return nil
    end
    local ok, decoded =
        pcall(function()
            return HttpService:
                JSONDecode(body)
        end)
    if ok
    and typeof(decoded)
        == "table"
    and decoded.ok == true
    and typeof(decoded.presence)
        == "table" then
        return decoded.presence
    end
    return nil
end
local function PresenceRequestOnce(userId)
    local relayPresence =
        PresenceRelayRequestOnce(
            userId
        )
    if relayPresence then
        return relayPresence
    end
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
local StatsService = game:GetService("Stats")
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
    local card =
        Instance.new(
            "Frame"
        )
    card.Size =
        UDim2.new(
            1,
            -5,
            0,
            78
        )
    card.BackgroundColor3 =
        Color3.fromRGB(
            18,
            18,
            26
        )
    card.BorderSizePixel = 0
    card.LayoutOrder = 1
    card.Parent = JoinPage
    local cardCorner =
        Instance.new(
            "UICorner"
        )
    cardCorner.CornerRadius =
        UDim.new(
            0,
            4
        )
    cardCorner.Parent = card
    JoinTargetBox =
        Instance.new(
            "TextBox"
        )
    JoinTargetBox.Size =
        UDim2.new(
            0.52,
            -8,
            0,
            30
        )
    JoinTargetBox.Position =
        UDim2.new(
            0,
            8,
            0,
            8
        )
    JoinTargetBox.BackgroundColor3 =
        Color3.fromRGB(
            27,
            27,
            39
        )
    JoinTargetBox.BorderSizePixel = 0
    JoinTargetBox.PlaceholderText =
        "Nick / ID"
    JoinTargetBox.Text = ""
    JoinTargetBox.TextColor3 =
        Color3.fromRGB(
            245,
            245,
            245
        )
    JoinTargetBox.PlaceholderColor3 =
        Color3.fromRGB(
            130,
            130,
            150
        )
    JoinTargetBox.Font =
        Enum.Font.Gotham
    JoinTargetBox.TextSize = 12
    JoinTargetBox.ClearTextOnFocus = false
    JoinTargetBox.Parent = card
    local inputCorner =
        Instance.new(
            "UICorner"
        )
    inputCorner.CornerRadius =
        UDim.new(
            0,
            4
        )
    inputCorner.Parent =
        JoinTargetBox
    JoinPlayingLabel =
        Instance.new(
            "TextLabel"
        )
    JoinPlayingLabel.Size =
        UDim2.new(
            0.48,
            -12,
            0,
            30
        )
    JoinPlayingLabel.Position =
        UDim2.new(
            0.52,
            4,
            0,
            8
        )
    JoinPlayingLabel.BackgroundColor3 =
        Color3.fromRGB(
            22,
            22,
            32
        )
    JoinPlayingLabel.BorderSizePixel = 0
    JoinPlayingLabel.Text =
        "Playing: --"
    JoinPlayingLabel.TextColor3 =
        Color3.fromRGB(
            170,
            170,
            185
        )
    JoinPlayingLabel.Font =
        Enum.Font.Gotham
    JoinPlayingLabel.TextSize = 10
    JoinPlayingLabel.TextXAlignment =
        Enum.TextXAlignment.Center
    JoinPlayingLabel.TextTruncate =
        Enum.TextTruncate.AtEnd
    JoinPlayingLabel.Parent = card
    local playingCorner =
        Instance.new(
            "UICorner"
        )
    playingCorner.CornerRadius =
        UDim.new(
            0,
            4
        )
    playingCorner.Parent =
        JoinPlayingLabel
    JoinPlayerButton =
        Instance.new(
            "TextButton"
        )
    JoinPlayerButton.Size =
        UDim2.new(
            1,
            -16,
            0,
            28
        )
    JoinPlayerButton.Position =
        UDim2.new(
            0,
            8,
            0,
            44
        )
    JoinPlayerButton.BackgroundColor3 =
        MAIN_COLOR
    JoinPlayerButton.BorderSizePixel = 0
    JoinPlayerButton.Text = "JOIN"
    JoinPlayerButton.TextColor3 =
        Color3.fromRGB(
            255,
            255,
            255
        )
    JoinPlayerButton.Font =
        Enum.Font.GothamBold
    JoinPlayerButton.TextSize = 12
    JoinPlayerButton.Parent = card
    local joinCorner =
        Instance.new(
            "UICorner"
        )
    joinCorner.CornerRadius =
        UDim.new(
            0,
            4
        )
    joinCorner.Parent =
        JoinPlayerButton
    local quickGamesCard =
        Instance.new(
            "Frame"
        )
    quickGamesCard.Name =
        "InlineQuickGames"
    quickGamesCard.Size =
        UDim2.new(
            1,
            -5,
            0,
            420
        )
    quickGamesCard.BackgroundColor3 =
        Color3.fromRGB(
            18,
            18,
            26
        )
    quickGamesCard.BorderSizePixel = 0
    quickGamesCard.LayoutOrder = 2
    quickGamesCard.ClipsDescendants = true
    quickGamesCard.Parent = JoinPage
    local quickCorner =
        Instance.new(
            "UICorner"
        )
    quickCorner.CornerRadius =
        UDim.new(
            0,
            4
        )
    quickCorner.Parent =
        quickGamesCard
    local quickTitle =
        Instance.new(
            "TextLabel"
        )
    quickTitle.Size =
        UDim2.new(
            1,
            -16,
            0,
            24
        )
    quickTitle.Position =
        UDim2.new(
            0,
            8,
            0,
            5
        )
    quickTitle.BackgroundTransparency = 1
    quickTitle.Text = "Supported Games"
    quickTitle.TextColor3 =
        Color3.fromRGB(
            245,
            245,
            245
        )
    quickTitle.Font =
        Enum.Font.GothamBold
    quickTitle.TextSize = 11
    quickTitle.TextXAlignment =
        Enum.TextXAlignment.Left
    quickTitle.Parent =
        quickGamesCard
    local directScroll = Instance.new("ScrollingFrame")
    directScroll.Name = "JoinGamesScroll"
    directScroll.Size = UDim2.new(1, -16, 1, -38)
    directScroll.Position = UDim2.new(0, 8, 0, 32)
    directScroll.BackgroundTransparency = 1
    directScroll.BorderSizePixel = 0
    directScroll.ScrollBarThickness = 3
    directScroll.ScrollBarImageColor3 = Color3.fromRGB(30, 95, 255)
    directScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    directScroll.Parent = quickGamesCard
    getgenv().JoinGamesScroll = directScroll
    JoinGamesScroll = directScroll
    local directLayout = Instance.new("UIListLayout")
    directLayout.Padding = UDim.new(0, 6)
    directLayout.SortOrder = Enum.SortOrder.LayoutOrder
    directLayout.Parent = directScroll
    directLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        directScroll.CanvasSize = UDim2.new(0, 0, 0, directLayout.AbsoluteContentSize.Y + 14)
    end)
    if JoinGamesGui then
        pcall(function() JoinGamesGui:Destroy() end)
        getgenv().JoinGamesGui = nil
    end
    JoinGamesButton = nil
    JoinTargetBox.FocusLost:
        Connect(function()
            if CleanJoinTarget(
                JoinTargetBox.Text
            ) ~= "" then
                task.spawn(function()
                    UpdateJoinStatus(
                        JoinTargetBox.Text,
                        false
                    )
                end)
            end
        end)
    JoinPlayerButton.MouseButton1Click:
        Connect(function()
            task.spawn(
                JoinTargetPlayer
            )
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
local ResolveGameName = ResolvePlaceName
local SupportedToxGames = {
    { Name = "Murder Mystery 2", PlaceId = 142823291, Code = "MM2", Status = "online" },
    { Name = "Natural Disaster Survival", PlaceId = 189707, Code = "NDS", Status = "online" },
    { Name = "FREE ADMIN", PlaceId = 4522347649, Code = "ADMIN", Status = "online" },
    { Name = "Build A Boat For Treasure", PlaceId = 537413528, Code = "BABFT", Status = "online" },
    { Name = "Lucky Block Battleground", PlaceId = 662417684, Code = "LBB", Status = "online" },
    { Name = "Flee the Facility", PlaceId = 893973440, Code = "FTF", Status = "online" },
    { Name = "Prison Life", PlaceId = 155615604, Code = "PL", Status = "online" },
    { Name = "Steal Or Die", PlaceId = 119925538689885, Code = "SOD", Status = "online" },
    { Name = "Bug Evolution", PlaceId = 70650894743738, Code = "BE", Status = "online" },
    { Name = "When In Disgrace", PlaceId = 109440000000000 + 485612336, Code = "WID", Status = "online" },
    { Name = "Scary Baboon Reimagined", PlaceId = 93660722909304, Code = "SBR", Status = "online" },
    { Name = "Saber Simulator", PlaceId = 3823781113, Code = "SS", Status = "online" },
    { Name = "Throw a Coin", PlaceId = 115681808123944, Code = "TAC", Status = "online" },
    { Name = "+1 Muscle Evolution", PlaceId = 133007106457547, Code = "ME", Status = "online" },
    { Name = "50 Player BINGO!", PlaceId = 131479356121251, Code = "BINGO", Status = "online" },
    { Name = "Chicken Farm", PlaceId = 137233438285284, Code = "CF", Status = "online" },
    { Name = "Anime Dice", PlaceId = 113290951185459, Code = "AD", Status = "online" }
}
local function RefreshQuickJoinGames()
    local scroll = (getgenv and getgenv().JoinGamesScroll) or JoinGamesScroll
    if not scroll or not pcall(function() return scroll.Parent end) or scroll.Parent == nil then
        return
    end
    for _, child in ipairs(scroll:GetChildren()) do
        if child:IsA("Frame") then
            pcall(function() child:Destroy() end)
        end
    end
    local knownPlaceIds = {}
    for _, g in ipairs(SupportedToxGames) do
        knownPlaceIds[g.PlaceId] = true
    end
    if getgenv().GameModuleRegistry then
        for pId, data in pairs(getgenv().GameModuleRegistry) do
            local numId = tonumber(pId)
            if numId and not knownPlaceIds[numId] and not (data and data.IsAlias) then
                local resolvedName = (ResolvePlaceName and ResolvePlaceName(numId)) or ("Place " .. tostring(numId))
                table.insert(SupportedToxGames, {
                    Name = resolvedName,
                    PlaceId = numId,
                    Code = (data and data.ShortName) or "GAME",
                    Status = "online"
                })
                knownPlaceIds[numId] = true
            end
        end
    end
    local displayOrder = 1
    for _, gInfo in ipairs(SupportedToxGames) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -4, 0, 50)
        row.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
        row.BorderSizePixel = 0
        row.LayoutOrder = displayOrder
        displayOrder = displayOrder + 1
        pcall(function() row.Parent = scroll end)
        local rowCorner = Instance.new("UICorner")
        rowCorner.CornerRadius = UDim.new(0, 6)
        rowCorner.Parent = row
        local rowStroke = Instance.new("UIStroke")
        rowStroke.Color = Color3.fromRGB(36, 36, 56)
        rowStroke.Thickness = 1
        rowStroke.Parent = row
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, -95, 0, 20)
        nameLabel.Position = UDim2.new(0, 10, 0, 6)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = gInfo.Name
        nameLabel.TextColor3 = Color3.fromRGB(250, 250, 250)
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 12
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        nameLabel.Parent = row
        local idLabel = Instance.new("TextLabel")
        idLabel.Size = UDim2.new(1, -95, 0, 16)
        idLabel.Position = UDim2.new(0, 10, 0, 26)
        idLabel.BackgroundTransparency = 1
        idLabel.Text = "ID: " .. tostring(gInfo.PlaceId) .. "  •  Módulo: " .. tostring(gInfo.Code)
        idLabel.TextColor3 = Color3.fromRGB(150, 150, 175)
        idLabel.Font = Enum.Font.Gotham
        idLabel.TextSize = 10
        idLabel.TextXAlignment = Enum.TextXAlignment.Left
        idLabel.Parent = row
        local statusColor = Color3.fromRGB(50, 230, 100)
        local statusText = "ONLINE" 
        local statusDot = Instance.new("Frame")
        statusDot.Size = UDim2.new(0, 7, 0, 7)
        statusDot.Position = UDim2.new(1, -78, 0, 10)
        statusDot.BackgroundColor3 = statusColor
        statusDot.BorderSizePixel = 0
        statusDot.Parent = row
        local dotCorner = Instance.new("UICorner")
        dotCorner.CornerRadius = UDim.new(1, 0)
        dotCorner.Parent = statusDot
        local statusLbl = Instance.new("TextLabel")
        statusLbl.Size = UDim2.new(0, 65, 0, 14)
        statusLbl.Position = UDim2.new(1, -68, 0, 7)
        statusLbl.BackgroundTransparency = 1
        statusLbl.Text = statusText
        statusLbl.TextColor3 = statusColor
        statusLbl.Font = Enum.Font.GothamBold
        statusLbl.TextSize = 9
        statusLbl.TextXAlignment = Enum.TextXAlignment.Left
        statusLbl.Parent = row
        local joinBtn = Instance.new("TextButton")
        joinBtn.Size = UDim2.new(0, 64, 0, 22)
        joinBtn.Position = UDim2.new(1, -74, 1, -26)
        joinBtn.BackgroundColor3 = Color3.fromRGB(30, 95, 255)
        joinBtn.BorderSizePixel = 0
        joinBtn.Text = "Entrar ▶"
        joinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        joinBtn.Font = Enum.Font.GothamBold
        joinBtn.TextSize = 10
        joinBtn.Parent = row
        local jbCorner = Instance.new("UICorner")
        jbCorner.CornerRadius = UDim.new(0, 4)
        jbCorner.Parent = joinBtn
        local targetPlaceId = gInfo.PlaceId
        joinBtn.MouseButton1Click:Connect(function()
            task.spawn(function()
                if getgenv().AllowToxTeleport then
                    getgenv().AllowToxTeleport(15, "Quick Join")
                end
                JoinPublicGame(targetPlaceId)
            end)
        end)
    end
    for idx, info in ipairs(
        SavedJoinGames
    ) do
        local placeId =
            tonumber(
                info.id
                or info.PlaceId
            )
        local gameName =
            tostring(
                info.name
                or info.Name
                or (
                    "Place "
                    .. tostring(
                        placeId
                        or "?"
                    )
                )
            )
        local favorite =
            info.favorite == true
        local row =
            Instance.new(
                "Frame"
            )
        row.Size =
            UDim2.new(
                1,
                -4,
                0,
                74
            )
        row.BackgroundColor3 =
            Color3.fromRGB(
                18,
                18,
                28
            )
        row.BorderSizePixel = 0
        row.LayoutOrder = idx
        pcall(function()
            row.Parent = scroll
        end)
        local rowCorner =
            Instance.new(
                "UICorner"
            )
        rowCorner.CornerRadius =
            UDim.new(
                0,
                4
            )
        rowCorner.Parent = row
        local nameLabel =
            Instance.new(
                "TextLabel"
            )
        nameLabel.Size =
            UDim2.new(
                1,
                -16,
                0,
                22
            )
        nameLabel.Position =
            UDim2.new(
                0,
                8,
                0,
                3
            )
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text =
            (
                favorite
                and "★ "
                or ""
            )
            .. gameName
        nameLabel.TextColor3 =
            favorite
            and Color3.fromRGB(
                255,
                215,
                70
            )
            or Color3.fromRGB(
                245,
                245,
                245
            )
        nameLabel.Font =
            Enum.Font.GothamBold
        nameLabel.TextSize = 11
        nameLabel.TextXAlignment =
            Enum.TextXAlignment.Left
        nameLabel.TextTruncate =
            Enum.TextTruncate.AtEnd
        nameLabel.Parent = row
        local idLabel =
            Instance.new(
                "TextLabel"
            )
        idLabel.Size =
            UDim2.new(
                1,
                -16,
                0,
                15
            )
        idLabel.Position =
            UDim2.new(
                0,
                8,
                0,
                24
            )
        idLabel.BackgroundTransparency = 1
        idLabel.Text =
            "ID: "
            .. tostring(
                placeId
                or "?"
            )
        idLabel.TextColor3 =
            Color3.fromRGB(
                145,
                145,
                165
            )
        idLabel.Font =
            Enum.Font.Gotham
        idLabel.TextSize = 9
        idLabel.TextXAlignment =
            Enum.TextXAlignment.Left
        idLabel.Parent = row
        local function makeButton(
            text,
            xScale,
            widthScale
        )
            local button =
                Instance.new(
                    "TextButton"
                )
            button.Size =
                UDim2.new(
                    widthScale,
                    -3,
                    0,
                    24
                )
            button.Position =
                UDim2.new(
                    xScale,
                    2,
                    0,
                    44
                )
            button.BackgroundColor3 =
                Color3.fromRGB(
                    25,
                    25,
                    38
                )
            button.BorderSizePixel = 0
            button.Text = text
            button.TextColor3 =
                Color3.fromRGB(
                    240,
                    240,
                    240
                )
            button.Font =
                Enum.Font.GothamBold
            button.TextSize = 9
            button.Parent = row
            local corner =
                Instance.new(
                    "UICorner"
                )
            corner.CornerRadius =
                UDim.new(
                    0,
                    4
                )
            corner.Parent =
                button
            return button
        end
        local joinButton =
            makeButton(
                "Join",
                0,
                0.20
            )
        local upButton =
            makeButton(
                "Up",
                0.20,
                0.14
            )
        local downButton =
            makeButton(
                "Down",
                0.34,
                0.18
            )
        local favoriteButton =
            makeButton(
                "Fav",
                0.52,
                0.17
            )
        local removeButton =
            makeButton(
                "Remove",
                0.69,
                0.31
            )
        favoriteButton.TextColor3 =
            favorite
            and Color3.fromRGB(
                255,
                215,
                70
            )
            or Color3.fromRGB(
                210,
                210,
                220
            )
        joinButton.MouseButton1Click:
            Connect(function()
                if placeId then
                    task.spawn(function()
                        JoinPublicGame(
                            placeId
                        )
                    end)
                end
            end)
        upButton.MouseButton1Click:
            Connect(function()
                if idx > 1 then
                    SavedJoinGames[
                        idx
                    ],
                    SavedJoinGames[
                        idx - 1
                    ] =
                        SavedJoinGames[
                            idx - 1
                        ],
                        SavedJoinGames[
                            idx
                        ]
                    AutoSaveConfiguration()
                    RefreshQuickJoinGames()
                end
            end)
        downButton.MouseButton1Click:
            Connect(function()
                if idx
                    < #SavedJoinGames then
                    SavedJoinGames[
                        idx
                    ],
                    SavedJoinGames[
                        idx + 1
                    ] =
                        SavedJoinGames[
                            idx + 1
                        ],
                        SavedJoinGames[
                            idx
                        ]
                    AutoSaveConfiguration()
                    RefreshQuickJoinGames()
                end
            end)
        favoriteButton.MouseButton1Click:
            Connect(function()
                SavedJoinGames[
                    idx
                ].favorite =
                    not favorite
                AutoSaveConfiguration()
                RefreshQuickJoinGames()
            end)
        removeButton.MouseButton1Click:
            Connect(function()
                table.remove(
                    SavedJoinGames,
                    idx
                )
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
end
do
local AntiKickRejoining = false
local function ResolveAntiKickQueue()
    local env =
        getgenv()
    if env
    and type(
        env.queue_on_teleport
    ) == "function" then
        return env.queue_on_teleport
    end
    if type(queue_on_teleport)
        == "function" then
        return queue_on_teleport
    end
    if syn
    and type(
        syn.queue_on_teleport
    ) == "function" then
        return syn.queue_on_teleport
    end
    if fluxus
    and type(
        fluxus.queue_on_teleport
    ) == "function" then
        return fluxus.queue_on_teleport
    end
    return nil
end
local function QueueAntiKickResume()
    local queueFunction =
        ResolveAntiKickQueue()
    if not queueFunction then
        return false
    end
    local resumeFarm =
        game.PlaceId == MM2PlaceId
        and Settings.MM2AutoFarmV2
            == true
    local payload =
        "if not game:IsLoaded() then game.Loaded:Wait() end\n"
        .. "local env = getgenv()\n"
        .. "env.ToxAutoExecuteQueued = false\n"
        .. "env.ToxAutoExecuteQueuedGame = nil\n"
        .. "env.__ToxAntiKickResume = true\n"
        .. "env.__ToxAntiKickResumeFarm = "
        .. tostring(
            resumeFarm
        )
        .. "\n"
        .. "task.wait(0.6)\n"
        .. "local guardNow = tick()\n"
        .. "local previousGuardAt = tonumber(env.__ToxQueuedDestinationAt) or 0\n"
        .. "if env.__ToxQueuedDestinationGame == game and guardNow - previousGuardAt < 2 then return end\n"
        .. "env.__ToxQueuedDestinationGame = game\n"
        .. "env.__ToxQueuedDestinationAt = guardNow\n"
        .. "task.delay(2, function() if env.__ToxQueuedDestinationGame == game and env.__ToxQueuedDestinationAt == guardNow then env.__ToxQueuedDestinationGame = nil; env.__ToxQueuedDestinationAt = nil end end)\n"
        .. "local ok = pcall(function() loadstring(game:HttpGet("
        .. string.format(
            "%q",
            "https://raw.githubusercontent.com/BG-0o/Scripts/main/ToxHub.lua"
        )
        .. "))() end)\n"
        .. "if not ok and env.__ToxQueuedDestinationAt == guardNow then env.__ToxQueuedDestinationGame = nil; env.__ToxQueuedDestinationAt = nil end"
    return pcall(
        queueFunction,
        payload
    )
end
local function TryAntiKickRejoin(
    reason
)
    if not Settings.AntiKick
    or AntiKickRejoining
    or getgenv().Destroyed then
        return
    end
    local text =
        string.lower(
            tostring(
                reason
                or ""
            )
        )
    if text ~= ""
    and not (
        string.find(
            text,
            "kick",
            1,
            true
        )
        or string.find(
            text,
            "disconnect",
            1,
            true
        )
        or string.find(
            text,
            "connection",
            1,
            true
        )
        or string.find(
            text,
            "error code",
            1,
            true
        )
        or string.find(
            text,
            "invalid",
            1,
            true
        )
        or string.find(
            text,
            "position",
            1,
            true
        )
    ) then
        return
    end
    if getgenv().AutoSaveConfiguration then
        pcall(getgenv().AutoSaveConfiguration)
    end
    AntiKickRejoining = true
    QueueAntiKickResume()
    CustomNotify(
        "Anti Kick • Rejoining server...",
        Color3.fromRGB(
            100,
            190,
            255
        ),
        5
    )
    if getgenv().AllowToxTeleport then
        getgenv().AllowToxTeleport(
            8
        )
    end
    task.spawn(function()
        task.wait(0.15)
        local sameServer =
            pcall(function()
                if game.JobId
                and game.JobId ~= "" then
                    TeleportService:
                        TeleportToPlaceInstance(
                            game.PlaceId,
                            game.JobId,
                            Player
                        )
                else
                    error(
                        "no_job"
                    )
                end
            end)
        if not sameServer then
            pcall(function()
                TeleportService:
                    Teleport(
                        game.PlaceId,
                        Player
                    )
            end)
        else
            task.delay(
                2.5,
                function()
                    if AntiKickRejoining then
                        pcall(function()
                            TeleportService:
                                Teleport(
                                    game.PlaceId,
                                    Player
                                )
                        end)
                    end
                end
            )
        end
    end)
end
pcall(function()
    AddConnection(
        GuiService.
            ErrorMessageChanged:
            Connect(function(message)
                TryAntiKickRejoin(
                    message
                )
            end)
    )
end)
pcall(function()
    local promptGui =
        CoreGui:
            FindFirstChild(
                "RobloxPromptGui"
            )
    local promptOverlay =
        promptGui
        and promptGui:
            FindFirstChild(
                "promptOverlay"
            )
    if promptOverlay then
        AddConnection(
            promptOverlay.ChildAdded:
                Connect(function(child)
                    task.delay(
                        0.05,
                        function()
                            if not child
                            or not child.Parent then
                                return
                            end
                            local parts = {}
                            for _, item in ipairs(
                                child:
                                    GetDescendants()
                            ) do
                                if item:IsA(
                                    "TextLabel"
                                )
                                or item:IsA(
                                    "TextButton"
                                ) then
                                    table.insert(
                                        parts,
                                        tostring(
                                            item.Text
                                            or ""
                                        )
                                    )
                                end
                            end
                            TryAntiKickRejoin(
                                table.concat(
                                    parts,
                                    " "
                                )
                            )
                        end
                    )
                end)
        )
    end
end)
end
do
local ServerHopMenu = nil
local ServerHopOverlay = nil
local function CloseServerHopMenu()
    if ServerHopMenu then
        ServerHopMenu:Destroy()
        ServerHopMenu = nil
    end
    if ServerHopOverlay then
        ServerHopOverlay:Destroy()
        ServerHopOverlay = nil
    end
end
local function GetServerHopInfo(server, mode)
    if typeof(server) ~= "table" then
        return nil
    end
    local playing = tonumber(server.playing) or 0
    local maxPlayers = tonumber(server.maxPlayers) or 0
    local serverId = tostring(server.id or "")
    if serverId == ""
    or serverId == game.JobId
    or maxPlayers <= 0
    or playing <= 0
    or playing >= maxPlayers then
        return nil
    end
    if mode == "Low" then
        if playing >= 1
        and playing <= math.min(2, maxPlayers - 1) then
            return playing, true
        end
        return nil
    end
    if mode == "High" then
        local wanted = math.max(1, maxPlayers - 2)
        if maxPlayers == 12 then
            wanted = 10
        end
        if playing >= wanted
        and playing <= maxPlayers - 1 then
            return -playing, true
        end
        return nil
    end
    local target = maxPlayers * 0.5
    local low = math.max(1, math.floor(target - 1))
    local high = math.min(maxPlayers - 1, math.ceil(target + 1))
    if playing >= low
    and playing <= high then
        return math.abs(playing - target), true
    end
    return nil
end
local function FetchServerHopPage(cursor, order)
    local url =
        "https://games.roblox.com/v1/games/"
        .. tostring(game.PlaceId)
        .. "/servers/Public?sortOrder="
        .. order
        .. "&limit=100"
    if cursor and cursor ~= "" then
        url = url .. "&cursor=" .. cursor
    end
    local ok, result = pcall(function()
        return game:HttpGet(url)
    end)
    if not ok
    or not result then
        return nil
    end
    local decodeOk, data = pcall(function()
        return HttpService:JSONDecode(result)
    end)
    if decodeOk then
        return data
    end
    return nil
end
local function FindServerHopTarget(mode)
    mode = tostring(mode or "Low")
    if mode ~= "Low"
    and mode ~= "Medium"
    and mode ~= "High" then
        mode = "Low"
    end
    local order = mode == "High" and "Desc" or "Asc"
    local cursor = nil
    local selected = nil
    local selectedScore = nil
    local maxPages = mode == "Medium" and 18 or 10
    for _ = 1, maxPages do
        local data = FetchServerHopPage(cursor, order)
        if not data
        or typeof(data.data) ~= "table" then
            break
        end
        for _, server in ipairs(data.data) do
            local score = GetServerHopInfo(server, mode)
            if score
            and (
                not selectedScore
                or score < selectedScore
            ) then
                selected = server
                selectedScore = score
            end
        end
        if selected
        and mode == "High" then
            break
        end
        if selected
        and mode == "Low"
        and selectedScore == 1 then
            break
        end
        if selected
        and mode == "Medium"
        and selectedScore <= 0.5 then
            break
        end
        cursor = data.nextPageCursor
        if not cursor
        or cursor == "" then
            break
        end
    end
    return selected
end
local function ServerHop(mode)
    mode = tostring(mode or "Low")
    CustomNotify(
        "Searching " .. mode .. " server...",
        Color3.fromRGB(100, 180, 255),
        3
    )
    task.spawn(function()
        local server = FindServerHopTarget(mode)
        if server
        and server.id then
            CustomNotify(
                "Teleporting to "
                .. mode
                .. " server • "
                .. tostring(server.playing or "?")
                .. "/"
                .. tostring(server.maxPlayers or "?"),
                Color3.fromRGB(100, 255, 100),
                5
            )
            TeleportService:TeleportToPlaceInstance(
                game.PlaceId,
                tostring(server.id),
                Player
            )
            return
        end
        CustomNotify(
            "No " .. mode .. " server found",
            Color3.fromRGB(255, 100, 100),
            5
        )
    end)
end
local function AddServerHopOption(parent, text, y, mode)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -10, 0, 28)
    button.Position = UDim2.new(0, 5, 0, y)
    button.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = Color3.fromRGB(240, 240, 240)
    button.TextSize = 12
    button.Font = Enum.Font.GothamMedium
    button.ZIndex = 202
    button.Parent = parent
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = button
    button.MouseButton1Click:Connect(function()
        CloseServerHopMenu()
        ServerHop(mode)
    end)
end
local function ShowServerHopMenu(button)
    CloseServerHopMenu()
    local gui = getgenv().Gui
    if not gui
    or not button then
        ServerHop("Low")
        return
    end
    ServerHopOverlay = Instance.new("TextButton")
    ServerHopOverlay.Name = "ToxServerHopOverlay"
    ServerHopOverlay.Size = UDim2.new(1, 0, 1, 0)
    ServerHopOverlay.Position = UDim2.new(0, 0, 0, 0)
    ServerHopOverlay.BackgroundTransparency = 1
    ServerHopOverlay.Text = ""
    ServerHopOverlay.AutoButtonColor = false
    ServerHopOverlay.ZIndex = 198
    ServerHopOverlay.Parent = gui
    local absolute = button.AbsolutePosition
    local size = button.AbsoluteSize
    local viewport = Camera and Camera.ViewportSize or Vector2.new(800, 600)
    local x = math.clamp(absolute.X, 8, math.max(8, viewport.X - 176))
    local y = math.clamp(absolute.Y + size.Y + 4, 8, math.max(8, viewport.Y - 110))
    ServerHopMenu = Instance.new("Frame")
    ServerHopMenu.Name = "ToxServerHopMenu"
    ServerHopMenu.Size = UDim2.new(0, 168, 0, 100)
    ServerHopMenu.Position = UDim2.new(0, x, 0, y)
    ServerHopMenu.BackgroundColor3 = Color3.fromRGB(10, 10, 16)
    ServerHopMenu.BorderSizePixel = 0
    ServerHopMenu.ZIndex = 200
    ServerHopMenu.Parent = gui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = ServerHopMenu
    local stroke = Instance.new("UIStroke")
    stroke.Color = MAIN_COLOR
    stroke.Thickness = 1
    stroke.Transparency = 0.15
    stroke.Parent = ServerHopMenu
    AddServerHopOption(ServerHopMenu, "Low", 6, "Low")
    AddServerHopOption(ServerHopMenu, "Medium", 36, "Medium")
    AddServerHopOption(ServerHopMenu, "High", 66, "High")
    ServerHopOverlay.MouseButton1Click:Connect(CloseServerHopMenu)
    ServerHopOverlay.MouseButton2Click:Connect(CloseServerHopMenu)
end
    U.CloseServerHopMenu = CloseServerHopMenu
    U.ServerHop = ServerHop
    U.ShowServerHopMenu = ShowServerHopMenu
end
