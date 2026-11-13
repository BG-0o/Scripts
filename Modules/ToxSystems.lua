if getgenv().ToxSystemsLoaded then
    return
end

if not getgenv().ToxUniversalLoaded then
    local notify =
        getgenv().CustomNotify

    if notify then
        notify(
            "Universal.lua must load before ToxSystems.lua",
            Color3.fromRGB(
                255,
                100,
                100
            ),
            5
        )
    end

    return
end

local Players =
    game:GetService("Players")
local UserInputService =
    game:GetService("UserInputService")
local RunService =
    game:GetService("RunService")
local TextChatService =
    game:GetService("TextChatService")
local HttpService =
    game:GetService("HttpService")
local ReplicatedStorage =
    game:GetService("ReplicatedStorage")
local TeleportService =
    game:GetService("TeleportService")
local MarketplaceService =
    game:GetService("MarketplaceService")

local Player = Players.LocalPlayer
local Gui = getgenv().Gui
local ControlPage =
    getgenv().ControlPage
local MAIN_COLOR =
    getgenv().MAIN_COLOR
local CustomNotify =
    getgenv().CustomNotify
local AddConnection =
    getgenv().AddConnection
local Settings =
    getgenv().Settings or {}
local AutoSaveConfiguration =
    getgenv().AutoSaveConfiguration
local RequestFunction =
    getgenv().ToxRequestFunction

if not Player
or not Gui
or not ControlPage
or not CustomNotify
or not AddConnection then
    return
end

local TOX_OWNER_ID = 2245662672

local TOX_FRIEND_IDS = {
    2805909339,
    415081654,
    400345609
}

local TOX_PREMIUM_IDS = {
    37052741
}

local TOX_PREMIUM_ASSET_ID =
    70855495297491

local TOX_ROLE_LEVELS = {
    Member = 1,
    Friend = 2,
    Premium = 3,
    Owner = 4
}

local function BuildRoleSet(list)
    local set = {}

    for _, id in ipairs(list) do
        local numeric =
            tonumber(id)

        if numeric
        and numeric > 0 then
            set[
                math.floor(numeric)
            ] = true
        end
    end

    return set
end

local FriendSet =
    BuildRoleSet(
        TOX_FRIEND_IDS
    )

local PremiumSet =
    BuildRoleSet(
        TOX_PREMIUM_IDS
    )

local PremiumAssetCache = {}

local function OwnsToxPremium(
    player
)
    if not player then
        return false
    end

    local userId =
        tonumber(player.UserId)
        or 0

    if PremiumSet[userId] then
        return true
    end

    if PremiumAssetCache[userId]
    ~= nil then
        return PremiumAssetCache[
            userId
        ]
    end

    local owns = false

    pcall(function()
        owns =
            MarketplaceService:
                PlayerOwnsAsset(
                    player,
                    TOX_PREMIUM_ASSET_ID
                )
    end)

    PremiumAssetCache[userId] =
        owns == true

    return PremiumAssetCache[
        userId
    ]
end

local function GetToxRole(player)
    if not player then
        return "Member", 1
    end

    local userId =
        tonumber(player.UserId)
        or 0

    if userId == TOX_OWNER_ID then
        return "Owner", 4
    end

    if OwnsToxPremium(player) then
        return "Premium", 3
    end

    if FriendSet[userId] then
        return "Friend", 2
    end

    return "Member", 1
end

local function CanUseControl(player)
    local _, level =
        GetToxRole(player)

    return level >=
        TOX_ROLE_LEVELS.Friend
end

local function CanControlTarget(
    actor,
    target
)
    if not actor
    or not target then
        return false
    end

    local _, actorLevel =
        GetToxRole(actor)

    local _, targetLevel =
        GetToxRole(target)

    if target.UserId
        == TOX_OWNER_ID
    and actor.UserId
        ~= TOX_OWNER_ID then
        return false
    end

    return actorLevel
        >= targetLevel
end

getgenv().GetToxRole =
    GetToxRole

getgenv().GetToxRoleByUserId =
    function(userId)
        local target =
            Players:GetPlayerByUserId(
                tonumber(userId) or 0
            )

        if target then
            return GetToxRole(target)
        end

        local numeric =
            tonumber(userId) or 0

        if numeric == TOX_OWNER_ID then
            return "Owner", 4
        end

        if PremiumSet[numeric] then
            return "Premium", 3
        end

        if FriendSet[numeric] then
            return "Friend", 2
        end

        return "Member", 1
    end

getgenv().ToxRole =
    select(
        1,
        GetToxRole(Player)
    )

Settings.ToxControlMode =
    tostring(
        Settings.ToxControlMode
        or "HIDDEN"
    )

if Settings.ToxControlMode
~= "CHAT"
and Settings.ToxControlMode
~= "HIDDEN" then
    Settings.ToxControlMode =
        "HIDDEN"
end

local function Save()
    if AutoSaveConfiguration then
        pcall(
            AutoSaveConfiguration
        )
    end
end

local function Trim(text)
    return tostring(text or "")
        :gsub("[\r\n]+", " ")
        :match("^%s*(.-)%s*$")
        or ""
end

local function ResolvePlayer(text)
    local input =
        Trim(text)
            :gsub("^@", "")

    if input == "" then
        return nil
    end

    local lower =
        string.lower(input)
    local partial = nil

    for _, candidate in ipairs(
        Players:GetPlayers()
    ) do
        local name =
            string.lower(
                candidate.Name
            )

        local display =
            string.lower(
                candidate.DisplayName
            )

        if name == lower
        or display == lower then
            return candidate
        end

        if not partial
        and (
            string.find(
                name,
                lower,
                1,
                true
            ) == 1
            or string.find(
                display,
                lower,
                1,
                true
            ) == 1
        ) then
            partial = candidate
        end
    end

    return partial
end

local function SendRobloxChat(
    message
)
    message = Trim(message)

    if message == "" then
        return false
    end

    local sent = false

    pcall(function()
        local config =
            TextChatService:
                FindFirstChild(
                    "ChatInputBarConfiguration"
                )

        local channel =
            config
            and config.TargetTextChannel

        if channel then
            channel:SendAsync(
                message
            )

            sent = true
        end
    end)

    if not sent then
        local events =
            ReplicatedStorage:
                FindFirstChild(
                    "DefaultChatSystemChatEvents"
                )

        local say =
            events
            and events:
                FindFirstChild(
                    "SayMessageRequest"
                )

        if say
        and say:IsA("RemoteEvent") then
            pcall(function()
                say:FireServer(
                    message,
                    "All"
                )

                sent = true
            end)
        end
    end

    return sent
end

local AutoJumpEnabled = false
local AutoJumpConnection = nil
local FrozenByControl = false
local RecentCommands = {}

local function SetAutoJump(enabled)
    AutoJumpEnabled =
        enabled == true

    if AutoJumpConnection then
        AutoJumpConnection:
            Disconnect()

        AutoJumpConnection = nil
    end

    if not AutoJumpEnabled then
        return
    end

    AutoJumpConnection =
        AddConnection(
            RunService.Heartbeat:
                Connect(function()
                    if not AutoJumpEnabled
                    or getgenv().Destroyed
                    or not getgenv().ScriptLoaded then
                        return
                    end

                    local character =
                        Player.Character

                    local humanoid =
                        character
                        and character:
                            FindFirstChildOfClass(
                                "Humanoid"
                            )

                    if humanoid
                    and humanoid.Health > 0
                    and humanoid.FloorMaterial
                        ~= Enum.Material.Air then
                        humanoid.Jump = true
                    end
                end)
        )
end

local function NotifyReceived(
    actor,
    text
)
    CustomNotify(
        "Tox Control • @"
        .. actor.Name
        .. " "
        .. text,
        Color3.fromRGB(
            120,
            210,
            255
        ),
        4
    )
end

local function ExecuteCommand(
    actor,
    command,
    argument
)
    if not actor
    or not CanControlTarget(
        actor,
        Player
    ) then
        return false
    end

    command =
        string.lower(
            Trim(command)
        )

    argument =
        Trim(argument)

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

    if command == "reset" then
        NotifyReceived(
            actor,
            "used RESET"
        )

        task.delay(0.12, function()
            if humanoid then
                humanoid.Health = 0
            end

            if character
            and character.Parent then
                pcall(function()
                    character:
                        BreakJoints()
                end)
            end
        end)

        return true
    end

    if command == "freeze" then
        if root then
            FrozenByControl =
                not FrozenByControl

            root.Anchored =
                FrozenByControl

            NotifyReceived(
                actor,
                FrozenByControl
                and "enabled FREEZE"
                or "disabled FREEZE"
            )
        end

        return true
    end

    if command == "unfreeze" then
        FrozenByControl = false

        if root then
            root.Anchored = false
        end

        NotifyReceived(
            actor,
            "disabled FREEZE"
        )

        return true
    end

    if command == "bring" then
        local actorRoot =
            actor.Character
            and actor.Character:
                FindFirstChild(
                    "HumanoidRootPart"
                )

        if root
        and actorRoot then
            if getgenv().AllowToxTeleport then
                getgenv().AllowToxTeleport(
                    1.5
                )
            end

            root.CFrame =
                actorRoot.CFrame
                * CFrame.new(
                    0,
                    0,
                    -3
                )

            if getgenv().SetNDSNoTPAnchor then
                pcall(function()
                    getgenv().SetNDSNoTPAnchor(
                        root.CFrame,
                        true
                    )
                end)
            end

            NotifyReceived(
                actor,
                "used BRING"
            )
        end

        return true
    end

    if command == "jump" then
        SetAutoJump(
            not AutoJumpEnabled
        )

        NotifyReceived(
            actor,
            AutoJumpEnabled
            and "enabled JUMP"
            or "disabled JUMP"
        )

        return true
    end

    if command == "unjump" then
        SetAutoJump(false)

        NotifyReceived(
            actor,
            "disabled JUMP"
        )

        return true
    end

    if command == "chat" then
        if argument ~= "" then
            NotifyReceived(
                actor,
                "used CHAT"
            )

            return SendRobloxChat(
                argument
            )
        end

        return false
    end

    if command == "kick" then
        NotifyReceived(
            actor,
            "used KICK"
        )

        task.delay(0.15, function()
            Player:Kick(
                "Tox Control"
            )
        end)

        return true
    end

    if command == "rejoin" then
        NotifyReceived(
            actor,
            "used REJOIN"
        )

        task.delay(0.15, function()
            local ok =
                pcall(function()
                    TeleportService:
                        TeleportToPlaceInstance(
                            game.PlaceId,
                            game.JobId,
                            Player
                        )
                end)

            if not ok then
                pcall(function()
                    TeleportService:
                        Teleport(
                            game.PlaceId,
                            Player
                        )
                end)
            end
        end)

        return true
    end

    if command == "sit" then
        if humanoid then
            humanoid.Sit =
                not humanoid.Sit

            NotifyReceived(
                actor,
                humanoid.Sit
                and "enabled SIT"
                or "disabled SIT"
            )
        end

        return true
    end

    if command == "fling" then
        local target =
            ResolvePlayer(argument)

        if not target
        or not CanControlTarget(
            actor,
            target
        ) then
            return false
        end

        local fling =
            getgenv().ToxExecuteFling

        if not fling then
            return false
        end

        NotifyReceived(
            actor,
            "used FLING on @"
            .. target.Name
        )

        task.spawn(function()
            fling(
                target.Name
            )
        end)

        return true
    end

    return false
end

local function IsDuplicate(
    actor,
    message
)
    local key =
        tostring(actor.UserId)
        .. "|"
        .. string.lower(
            tostring(message or "")
        )

    local now = tick()
    local old =
        RecentCommands[key]

    RecentCommands[key] = now

    for oldKey, timeValue in pairs(
        RecentCommands
    ) do
        if now - timeValue > 3 then
            RecentCommands[
                oldKey
            ] = nil
        end
    end

    return old
        and now - old < 0.75
end

local function HandleChatCommand(
    actor,
    message
)
    if not actor
    or typeof(message)
        ~= "string"
    or IsDuplicate(
        actor,
        message
    ) then
        return false
    end

    local targetText,
        command,
        argument =
        message:match(
            "^%s*%.c%s+(%S+)%s+(%S+)%s*(.-)%s*$"
        )

    if not targetText
    or not command
    or not CanUseControl(actor) then
        return false
    end

    local target =
        ResolvePlayer(
            targetText
        )

    if not target then
        return true
    end

    command =
        string.lower(command)

    if target ~= Player then
        if actor == Player
        and CanControlTarget(
            actor,
            target
        ) then
            CustomNotify(
                "Tox Control • "
                .. string.upper(command)
                .. " -> @"
                .. target.Name,
                Color3.fromRGB(
                    100,
                    255,
                    130
                ),
                3
            )
        end

        return true
    end

    ExecuteCommand(
        actor,
        command,
        argument
    )

    return true
end

local function HookChatPlayer(player)
    AddConnection(
        player.Chatted:
            Connect(function(message)
                HandleChatCommand(
                    player,
                    message
                )
            end)
    )
end

for _, player in ipairs(
    Players:GetPlayers()
) do
    HookChatPlayer(player)
end

AddConnection(
    Players.PlayerAdded:
        Connect(
            HookChatPlayer
        )
)

AddConnection(
    TextChatService.MessageReceived:
        Connect(function(message)
            local source =
                message
                and message.TextSource

            if not source then
                return
            end

            local actor =
                Players:GetPlayerByUserId(
                    source.UserId
                )

            if actor then
                HandleChatCommand(
                    actor,
                    message.Text
                )
            end
        end)
)

local ToxControlRelayHost =
    "https://tox-control-relay.1kobg-0o.workers.dev"

local HiddenLastID = 0
local HiddenPendingAcks = {}
local HiddenSeenNonces = {}
local HiddenConnected = false
local HiddenFailureCount = 0

local function ReadControlRelayResponse(
    response
)
    if typeof(response)
        ~= "table" then
        return nil, false
    end

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

    local body =
        response.Body
        or response.body

    local ok =
        (
            status >= 200
            and status < 300
        )
        or success == true

    return body, ok
end

local function ControlRelayRequest(
    method,
    path,
    body
)
    if not RequestFunction then
        return nil, false
    end

    local headers = {
        ["Accept"] =
            "application/json",
        ["Cache-Control"] =
            "no-cache"
    }

    if body ~= nil then
        headers["Content-Type"] =
            "application/json"
    end

    local ok, response =
        pcall(function()
            return RequestFunction({
                Url =
                    ToxControlRelayHost
                    .. path,
                Method = method,
                Headers = headers,
                Body = body
            })
        end)

    if not ok then
        return nil, false
    end

    return ReadControlRelayResponse(
        response
    )
end

local ToxActiveUsers =
    getgenv().ToxActiveUsers
    or {}

getgenv().ToxActiveUsers =
    ToxActiveUsers

ToxActiveUsers[
    Player.UserId
] = tick()

local function IsToxUser(
    player
)
    if not player then
        return false
    end

    if player == Player then
        return true
    end

    local lastSeen =
        tonumber(
            ToxActiveUsers[
                player.UserId
            ]
        )

    return lastSeen ~= nil
        and tick() - lastSeen
            <= 40
end

getgenv().IsToxUser =
    IsToxUser

local function DecodeRelayJson(
    body
)
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
        == "table" then
        return decoded
    end

    return nil
end

local function UpdateToxActiveUsers()
    local heartbeatBody =
        HttpService:
            JSONEncode({
                userId =
                    Player.UserId,
                placeId =
                    game.PlaceId,
                jobId =
                    game.JobId
            })

    ControlRelayRequest(
        "POST",
        "/tox/heartbeat",
        heartbeatBody
    )

    local activeBody, activeOk =
        ControlRelayRequest(
            "GET",
            "/tox/active?placeId="
            .. tostring(
                game.PlaceId
            )
            .. "&jobId="
            .. HttpService:
                UrlEncode(
                    tostring(
                        game.JobId
                    )
                )
            .. "&_="
            .. tostring(
                math.floor(
                    os.clock() * 1000
                )
            )
        )

    if not activeOk then
        ToxActiveUsers[
            Player.UserId
        ] = tick()

        return
    end

    local decoded =
        DecodeRelayJson(
            activeBody
        )

    if not decoded
    or decoded.ok ~= true
    or typeof(decoded.users)
        ~= "table" then
        return
    end

    local now = tick()
    local fresh = {
        [Player.UserId] = now
    }

    for _, entry in ipairs(
        decoded.users
    ) do
        local userId =
            tonumber(
                entry.userId
            )

        if userId then
            fresh[userId] =
                now
        end
    end

    for userId in pairs(
        ToxActiveUsers
    ) do
        if not fresh[userId] then
            ToxActiveUsers[
                userId
            ] = nil
        end
    end

    for userId, seenAt in pairs(
        fresh
    ) do
        ToxActiveUsers[
            userId
        ] = seenAt
    end
end

task.spawn(function()
    while not getgenv().Destroyed do
        pcall(
            UpdateToxActiveUsers
        )

        task.wait(10)
    end
end)

----------------------------------------------------------------------
-- TOX NETWORK TELEMETRY & SUPABASE PRESENCE SYNC
----------------------------------------------------------------------
local SUPABASE_URL = "https://nlavwcbdqcmoqmojraeu.supabase.co"
local SUPABASE_KEY = "sb_publishable__HC4Z5_wV2Daf8o-mgt89Q_z_JH2cif"

local function GetCurrentExecutorName()
    if type(identifyexecutor) == "function" then
        local name = identifyexecutor()
        if name and name ~= "" then return tostring(name) end
    end
    if type(getexecutorname) == "function" then
        local name = getexecutorname()
        if name and name ~= "" then return tostring(name) end
    end
    return "Potassium"
end

local CurrentDetectedExecutor = GetCurrentExecutorName()
local CachedGameName = "Roblox Game"
task.spawn(function()
    pcall(function()
        local info = MarketplaceService:GetProductInfo(game.PlaceId)
        if info and info.Name then CachedGameName = info.Name end
    end)
end)

local function SyncSupabasePresence()
    local rf = RequestFunction or (getgenv and getgenv().ToxRequestFunction)
    if not rf then return false end

    local payload = HttpService:JSONEncode({
        user_id = Player.UserId,
        username = Player.Name,
        executor = "ToxHud | " .. tostring(CurrentDetectedExecutor),
        active_effect = "ToxHud",
        current_game = tostring(CachedGameName),
        place_id = game.PlaceId,
        job_id = tostring(game.JobId),
        updated_at = os.date("!%Y-%m-%dT%H:%M:%SZ")
    })

    local ok = pcall(function()
        rf({
            Url = SUPABASE_URL .. "/rest/v1/executor_sync?on_conflict=username",
            Method = "POST",
            Headers = {
                ["apikey"] = SUPABASE_KEY,
                ["Authorization"] = "Bearer " .. SUPABASE_KEY,
                ["Content-Type"] = "application/json",
                ["Prefer"] = "resolution=merge-duplicates"
            },
            Body = payload
        })
    end)
    return ok
end

local function IsToxHudUser(u)
    if not u then return false end
    if tostring(u.active_effect) == "ToxHud" then return true end
    local execLow = string.lower(tostring(u.executor or ""))
    if string.find(execLow, "toxhud", 1, true) then return true end
    return false
end

local function FetchSupabaseNetworkUsers()
    local rf = RequestFunction or (getgenv and getgenv().ToxRequestFunction)
    if not rf then return {} end

    local res = nil
    local ok = pcall(function()
        res = rf({
            Url = SUPABASE_URL .. "/rest/v1/executor_sync?select=user_id,username,executor,current_game,job_id,place_id,active_effect,updated_at&order=updated_at.desc&limit=150",
            Method = "GET",
            Headers = {
                ["apikey"] = SUPABASE_KEY,
                ["Authorization"] = "Bearer " .. SUPABASE_KEY,
                ["Accept"] = "application/json"
            }
        })
    end)

    if not ok or not res then return {} end
    local body, okBody = ReadControlRelayResponse(res)
    if not okBody or not body then return {} end
    local decoded = DecodeRelayJson(body)
    if type(decoded) == "table" then
        return decoded
    end
    return {}
end

task.spawn(function()
    while not getgenv().Destroyed do
        pcall(SyncSupabasePresence)
        task.wait(25)
    end
end)

local function ParseIsoTimestamp(iso)
    if type(iso) ~= "string" then return 0 end
    local y, m, d, h, min, s = iso:match("(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)")
    if not y then return 0 end
    local ok, t = pcall(os.time, {
        year = tonumber(y),
        month = tonumber(m),
        day = tonumber(d),
        hour = tonumber(h),
        min = tonumber(min),
        sec = tonumber(s)
    })
    return ok and t or 0
end

local function GetExecutorBadgeColor(execName)
    local low = string.lower(tostring(execName or ""))
    if string.find(low, "potassium") then
        return Color3.fromRGB(34, 197, 94)
    elseif string.find(low, "wave") then
        return Color3.fromRGB(59, 130, 246)
    elseif string.find(low, "solara") then
        return Color3.fromRGB(245, 158, 11)
    elseif string.find(low, "synapse") or string.find(low, "swift") then
        return Color3.fromRGB(249, 115, 22)
    elseif string.find(low, "delta") then
        return Color3.fromRGB(168, 85, 247)
    elseif string.find(low, "codex") then
        return Color3.fromRGB(236, 72, 153)
    elseif string.find(low, "celery") then
        return Color3.fromRGB(16, 185, 129)
    elseif string.find(low, "fluxus") then
        return Color3.fromRGB(6, 182, 212)
    end
    return Color3.fromRGB(0, 168, 255)
end

local ToxNetworkModalGui = nil

local function OpenToxNetworkModal()
    local role, level = GetToxRole(Player)
    local canAccess = (level >= TOX_ROLE_LEVELS.Premium) or (Player.UserId == TOX_OWNER_ID)
    if not canAccess then
        CustomNotify("🔒 Access Restricted: Premium and Owner tiers only!", Color3.fromRGB(244, 63, 94), 4)
        return
    end

    if ToxNetworkModalGui and ToxNetworkModalGui.Parent then
        local frame = ToxNetworkModalGui:FindFirstChild("NetworkModalFrame")
        if frame then frame.Visible = not frame.Visible end
        return
    end

    local env = getgenv()
    local uiTheme = env and env.Theme
    local modalParent = (gethui and gethui()) or game:GetService("CoreGui") or (Player and Player:FindFirstChild("PlayerGui"))

    local modalGui = Instance.new("ScreenGui")
    modalGui.Name = "ToxNetworkModalGui"
    modalGui.ResetOnSpawn = false
    modalGui.DisplayOrder = 2147483640
    pcall(function() modalGui.Parent = modalParent end)
    ToxNetworkModalGui = modalGui

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "NetworkModalFrame"
    mainFrame.Size = UDim2.new(0, 620, 0, 480)
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.BackgroundColor3 = (uiTheme and uiTheme.Background) or Color3.fromRGB(10, 13, 20)
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = modalGui

    local mCorner = Instance.new("UICorner") mCorner.CornerRadius = UDim.new(0, 12) mCorner.Parent = mainFrame
    local mStroke = Instance.new("UIStroke") mStroke.Color = (uiTheme and uiTheme.Accent) or MAIN_COLOR mStroke.Thickness = 1.2 mStroke.Transparency = 0.3 mStroke.Parent = mainFrame

    local mHeader = Instance.new("Frame")
    mHeader.Size = UDim2.new(1, 0, 0, 50)
    mHeader.BackgroundColor3 = (uiTheme and uiTheme.Panel) or Color3.fromRGB(13, 17, 26)
    mHeader.BorderSizePixel = 0
    mHeader.Parent = mainFrame
    local hCorner = Instance.new("UICorner") hCorner.CornerRadius = UDim.new(0, 12) hCorner.Parent = mHeader
    local hMask = Instance.new("Frame") hMask.Size = UDim2.new(1, 0, 0, 12) hMask.Position = UDim2.new(0, 0, 1, -12) hMask.BackgroundColor3 = mHeader.BackgroundColor3 hMask.BorderSizePixel = 0 hMask.Parent = mHeader
    local hBorder = Instance.new("Frame") hBorder.Size = UDim2.new(1, 0, 0, 1) hBorder.Position = UDim2.new(0, 0, 1, -1) hBorder.BackgroundColor3 = (uiTheme and uiTheme.Outline) or Color3.fromRGB(30, 41, 59) hBorder.BorderSizePixel = 0 hBorder.Parent = mHeader

    local hLogo = Instance.new("ImageLabel")
    hLogo.Size = UDim2.new(0, 30, 0, 30)
    hLogo.Position = UDim2.new(0, 14, 0.5, -15)
    hLogo.BackgroundTransparency = 1
    hLogo.Image = (Settings and Settings.CustomIconUrl and Settings.CustomIconUrl ~= "") and Settings.CustomIconUrl or "rbxassetid://10723346959"
    hLogo.Parent = mHeader

    local hTitle = Instance.new("TextLabel")
    hTitle.Size = UDim2.new(0, 320, 0, 20)
    hTitle.Position = UDim2.new(0, 52, 0, 8)
    hTitle.BackgroundTransparency = 1
    hTitle.Text = "Network Users • Live Hub Presence"
    hTitle.TextColor3 = (uiTheme and uiTheme.Text) or Color3.fromRGB(255, 255, 255)
    hTitle.Font = Enum.Font.GothamBold
    hTitle.TextSize = 14
    hTitle.TextXAlignment = Enum.TextXAlignment.Left
    hTitle.Parent = mHeader

    local hSub = Instance.new("TextLabel")
    hSub.Size = UDim2.new(0, 320, 0, 16)
    hSub.Position = UDim2.new(0, 52, 0, 26)
    hSub.BackgroundTransparency = 1
    hSub.Text = "Active instances across ToxHud & WASOR network"
    hSub.TextColor3 = (uiTheme and uiTheme.DimText) or Color3.fromRGB(156, 170, 195)
    hSub.Font = Enum.Font.GothamMedium
    hSub.TextSize = 10
    hSub.TextXAlignment = Enum.TextXAlignment.Left
    hSub.Parent = mHeader

    local refreshBtn = Instance.new("TextButton")
    refreshBtn.Size = UDim2.new(0, 95, 0, 26)
    refreshBtn.Position = UDim2.new(1, -135, 0.5, -13)
    refreshBtn.BackgroundColor3 = (uiTheme and uiTheme.Element) or Color3.fromRGB(19, 25, 38)
    refreshBtn.BorderSizePixel = 0
    refreshBtn.Text = "🔄 Refresh"
    refreshBtn.TextColor3 = (uiTheme and uiTheme.Accent) or MAIN_COLOR
    refreshBtn.Font = Enum.Font.GothamBold
    refreshBtn.TextSize = 10
    refreshBtn.Parent = mHeader
    local rfCorner = Instance.new("UICorner") rfCorner.CornerRadius = UDim.new(0, 6) rfCorner.Parent = refreshBtn
    local rfStroke = Instance.new("UIStroke") rfStroke.Color = (uiTheme and uiTheme.Outline) or Color3.fromRGB(30, 41, 59) rfStroke.Thickness = 1 rfStroke.Parent = refreshBtn

    local mClose = Instance.new("TextButton")
    mClose.Size = UDim2.new(0, 26, 0, 26)
    mClose.Position = UDim2.new(1, -34, 0.5, -13)
    mClose.BackgroundColor3 = (uiTheme and uiTheme.Element) or Color3.fromRGB(19, 25, 38)
    mClose.BorderSizePixel = 0
    mClose.Text = "X"
    mClose.TextColor3 = Color3.fromRGB(244, 63, 94)
    mClose.Font = Enum.Font.GothamBold
    mClose.TextSize = 11
    mClose.Parent = mHeader
    local cCorner = Instance.new("UICorner") cCorner.CornerRadius = UDim.new(0, 6) cCorner.Parent = mClose

    MakeDraggable(mainFrame, mHeader)

    mClose.MouseButton1Click:Connect(function()
        mainFrame.Visible = false
    end)

    local filterBar = Instance.new("Frame")
    filterBar.Size = UDim2.new(1, -24, 0, 32)
    filterBar.Position = UDim2.new(0, 12, 0, 58)
    filterBar.BackgroundTransparency = 1
    filterBar.Parent = mainFrame

    local searchContainer = Instance.new("Frame")
    searchContainer.Size = UDim2.new(0.35, -4, 1, 0)
    searchContainer.Position = UDim2.new(0, 0, 0, 0)
    searchContainer.BackgroundColor3 = (uiTheme and uiTheme.Element) or Color3.fromRGB(19, 25, 38)
    searchContainer.BorderSizePixel = 0
    searchContainer.Parent = filterBar
    local scCorner = Instance.new("UICorner") scCorner.CornerRadius = UDim.new(0, 6) scCorner.Parent = searchContainer
    local scStroke = Instance.new("UIStroke") scStroke.Color = (uiTheme and uiTheme.Outline) or Color3.fromRGB(30, 41, 59) scStroke.Thickness = 1 scStroke.Parent = searchContainer

    local searchBox = Instance.new("TextBox")
    searchBox.Size = UDim2.new(1, -12, 1, 0)
    searchBox.Position = UDim2.new(0, 10, 0, 0)
    searchBox.BackgroundTransparency = 1
    searchBox.PlaceholderText = "🔍 Search player, game..."
    searchBox.PlaceholderColor3 = Color3.fromRGB(120, 135, 160)
    searchBox.Text = ""
    searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    searchBox.Font = Enum.Font.GothamMedium
    searchBox.TextSize = 11
    searchBox.TextXAlignment = Enum.TextXAlignment.Left
    searchBox.ClearTextOnFocus = false
    searchBox.Parent = searchContainer

    local tabAllBtn = Instance.new("TextButton")
    tabAllBtn.Size = UDim2.new(0.14, -3, 1, 0)
    tabAllBtn.Position = UDim2.new(0.35, 3, 0, 0)
    tabAllBtn.BackgroundColor3 = (uiTheme and uiTheme.Accent) or MAIN_COLOR
    tabAllBtn.BorderSizePixel = 0
    tabAllBtn.Text = "All (0)"
    tabAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    tabAllBtn.Font = Enum.Font.GothamBold
    tabAllBtn.TextSize = 10
    tabAllBtn.Parent = filterBar
    local taCorner = Instance.new("UICorner") taCorner.CornerRadius = UDim.new(0, 6) taCorner.Parent = tabAllBtn

    local tabToxHudBtn = Instance.new("TextButton")
    tabToxHudBtn.Size = UDim2.new(0.17, -3, 1, 0)
    tabToxHudBtn.Position = UDim2.new(0.49, 3, 0, 0)
    tabToxHudBtn.BackgroundColor3 = (uiTheme and uiTheme.Element) or Color3.fromRGB(19, 25, 38)
    tabToxHudBtn.BorderSizePixel = 0
    tabToxHudBtn.Text = "🛡️ ToxHud (0)"
    tabToxHudBtn.TextColor3 = Color3.fromRGB(56, 189, 248)
    tabToxHudBtn.Font = Enum.Font.GothamBold
    tabToxHudBtn.TextSize = 10
    tabToxHudBtn.Parent = filterBar
    local thCorner = Instance.new("UICorner") thCorner.CornerRadius = UDim.new(0, 6) thCorner.Parent = tabToxHudBtn

    local tabWasorBtn = Instance.new("TextButton")
    tabWasorBtn.Size = UDim2.new(0.17, -3, 1, 0)
    tabWasorBtn.Position = UDim2.new(0.66, 3, 0, 0)
    tabWasorBtn.BackgroundColor3 = (uiTheme and uiTheme.Element) or Color3.fromRGB(19, 25, 38)
    tabWasorBtn.BorderSizePixel = 0
    tabWasorBtn.Text = "⚡ WASOR (0)"
    tabWasorBtn.TextColor3 = Color3.fromRGB(216, 180, 254)
    tabWasorBtn.Font = Enum.Font.GothamBold
    tabWasorBtn.TextSize = 10
    tabWasorBtn.Parent = filterBar
    local twCorner = Instance.new("UICorner") twCorner.CornerRadius = UDim.new(0, 6) twCorner.Parent = tabWasorBtn

    local tabOnlineBtn = Instance.new("TextButton")
    tabOnlineBtn.Size = UDim2.new(0.17, -3, 1, 0)
    tabOnlineBtn.Position = UDim2.new(0.83, 3, 0, 0)
    tabOnlineBtn.BackgroundColor3 = (uiTheme and uiTheme.Element) or Color3.fromRGB(19, 25, 38)
    tabOnlineBtn.BorderSizePixel = 0
    tabOnlineBtn.Text = "🟢 Online (0)"
    tabOnlineBtn.TextColor3 = Color3.fromRGB(34, 197, 94)
    tabOnlineBtn.Font = Enum.Font.GothamBold
    tabOnlineBtn.TextSize = 10
    tabOnlineBtn.Parent = filterBar
    local toCorner = Instance.new("UICorner") toCorner.CornerRadius = UDim.new(0, 6) toCorner.Parent = tabOnlineBtn

    local listScroll = Instance.new("ScrollingFrame")
    listScroll.Size = UDim2.new(1, -24, 1, -100)
    listScroll.Position = UDim2.new(0, 12, 0, 96)
    listScroll.BackgroundTransparency = 1
    listScroll.BorderSizePixel = 0
    listScroll.ScrollBarThickness = 3
    listScroll.ScrollBarImageColor3 = (uiTheme and uiTheme.Outline) or Color3.fromRGB(30, 41, 59)
    listScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    listScroll.Parent = mainFrame

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 6)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = listScroll

    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        listScroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 12)
    end)

    local cachedUsers = {}
    local currentFilterMode = "ALL"

    local function RenderUsers()
        for _, child in ipairs(listScroll:GetChildren()) do
            if child:IsA("GuiObject") then child:Destroy() end
        end

        local q = string.lower(string.match(searchBox.Text or "", "^%s*(.-)%s*$") or "")
        local nowUtc = os.time(os.date("!*t"))
        local onlineCount = 0
        local toxCount = 0
        local wasorCount = 0
        local totalCount = #cachedUsers

        for _, u in ipairs(cachedUsers) do
            local ts = ParseIsoTimestamp(u.updated_at)
            local diff = nowUtc - ts
            local isOnline = (diff >= -30 and diff <= 95)
            if isOnline then onlineCount = onlineCount + 1 end
            if IsToxHudUser(u) then
                toxCount = toxCount + 1
            else
                wasorCount = wasorCount + 1
            end
        end

        tabAllBtn.Text = "All (" .. tostring(totalCount) .. ")"
        tabToxHudBtn.Text = "🛡️ ToxHud (" .. tostring(toxCount) .. ")"
        tabWasorBtn.Text = "⚡ WASOR (" .. tostring(wasorCount) .. ")"
        tabOnlineBtn.Text = "🟢 Online (" .. tostring(onlineCount) .. ")"

        for _, u in ipairs(cachedUsers) do
            local uname = tostring(u.username or "Unknown")
            local exec = tostring(u.executor or "Executor")
            local gameTitle = tostring(u.current_game or "Roblox Game")
            local ts = ParseIsoTimestamp(u.updated_at)
            local diff = nowUtc - ts
            local isOnline = (diff >= -30 and diff <= 95)
            local isTox = IsToxHudUser(u)

            if currentFilterMode == "TOXHUD" and not isTox then
                continue
            elseif currentFilterMode == "WASOR" and isTox then
                continue
            elseif currentFilterMode == "ONLINE" and not isOnline then
                continue
            end

            if q ~= "" then
                local matchName = string.find(string.lower(uname), q, 1, true)
                local matchExec = string.find(string.lower(exec), q, 1, true)
                local matchGame = string.find(string.lower(gameTitle), q, 1, true)
                local matchOrigin = (isTox and string.find("toxhud", q, 1, true)) or (not isTox and string.find("wasor", q, 1, true))
                if not matchName and not matchExec and not matchGame and not matchOrigin then
                    continue
                end
            end

            local cleanExec = string.gsub(exec, "^ToxHud%s*|%s*", "")
            if cleanExec == "" then cleanExec = "ToxHud" end

            local card = Instance.new("Frame")
            card.Size = UDim2.new(1, -6, 0, 64)
            card.BackgroundColor3 = (uiTheme and uiTheme.Element) or Color3.fromRGB(19, 25, 38)
            card.BorderSizePixel = 0
            card.Parent = listScroll
            local cardCorner = Instance.new("UICorner") cardCorner.CornerRadius = UDim.new(0, 8) cardCorner.Parent = card
            local cardStroke = Instance.new("UIStroke") cardStroke.Color = isOnline and Color3.fromRGB(34, 197, 94) or ((uiTheme and uiTheme.Outline) or Color3.fromRGB(30, 41, 59)) cardStroke.Thickness = 1 cardStroke.Transparency = isOnline and 0.4 or 0.7 cardStroke.Parent = card

            local avatar = Instance.new("ImageLabel")
            avatar.Size = UDim2.new(0, 44, 0, 44)
            avatar.Position = UDim2.new(0, 10, 0.5, -22)
            avatar.BackgroundColor3 = (uiTheme and uiTheme.Hover) or Color3.fromRGB(27, 35, 54)
            avatar.BorderSizePixel = 0
            avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(u.user_id or 1) .. "&w=100&h=100"
            avatar.Parent = card
            local aCorner = Instance.new("UICorner") aCorner.CornerRadius = UDim.new(0, 8) aCorner.Parent = avatar
            local aStroke = Instance.new("UIStroke") aStroke.Color = isOnline and Color3.fromRGB(34, 197, 94) or (uiTheme and uiTheme.Accent or MAIN_COLOR) aStroke.Thickness = 1 aStroke.Transparency = 0.5 aStroke.Parent = avatar

            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(0, 140, 0, 18)
            nameLabel.Position = UDim2.new(0, 62, 0, 10)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = "@" .. uname
            nameLabel.TextColor3 = (uiTheme and uiTheme.Text) or Color3.fromRGB(255, 255, 255)
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.TextSize = 12
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
            nameLabel.Parent = card

            local originBadge = Instance.new("Frame")
            originBadge.Size = UDim2.new(0, 75, 0, 18)
            originBadge.Position = UDim2.new(0, 208, 0, 10)
            originBadge.BackgroundColor3 = isTox and Color3.fromRGB(12, 32, 54) or Color3.fromRGB(36, 16, 52)
            originBadge.BorderSizePixel = 0
            originBadge.Parent = card
            local obCorner = Instance.new("UICorner") obCorner.CornerRadius = UDim.new(0, 4) obCorner.Parent = originBadge
            local obStroke = Instance.new("UIStroke")
            obStroke.Color = isTox and Color3.fromRGB(0, 168, 255) or Color3.fromRGB(168, 85, 247)
            obStroke.Thickness = 1
            obStroke.Transparency = 0.3
            obStroke.Parent = originBadge

            local obText = Instance.new("TextLabel")
            obText.Size = UDim2.new(1, 0, 1, 0)
            obText.BackgroundTransparency = 1
            obText.Text = isTox and "🛡️ ToxHud" or "⚡ WASOR"
            obText.TextColor3 = isTox and Color3.fromRGB(56, 189, 248) or Color3.fromRGB(216, 180, 254)
            obText.Font = Enum.Font.GothamBold
            obText.TextSize = 9
            obText.Parent = originBadge

            local execBadge = Instance.new("Frame")
            execBadge.Size = UDim2.new(0, 75, 0, 18)
            execBadge.Position = UDim2.new(0, 288, 0, 10)
            execBadge.BackgroundColor3 = Color3.fromRGB(15, 20, 30)
            execBadge.BorderSizePixel = 0
            execBadge.Parent = card
            local ebCorner = Instance.new("UICorner") ebCorner.CornerRadius = UDim.new(0, 4) ebCorner.Parent = execBadge
            local ebStroke = Instance.new("UIStroke") ebStroke.Color = GetExecutorBadgeColor(cleanExec) ebStroke.Thickness = 1 ebStroke.Transparency = 0.3 ebStroke.Parent = execBadge

            local ebText = Instance.new("TextLabel")
            ebText.Size = UDim2.new(1, 0, 1, 0)
            ebText.BackgroundTransparency = 1
            ebText.Text = cleanExec
            ebText.TextColor3 = GetExecutorBadgeColor(cleanExec)
            ebText.Font = Enum.Font.GothamBold
            ebText.TextSize = 9
            ebText.TextTruncate = Enum.TextTruncate.AtEnd
            ebText.Parent = execBadge

            local statusBadge = Instance.new("Frame")
            statusBadge.Size = UDim2.new(0, 72, 0, 18)
            statusBadge.Position = UDim2.new(0, 368, 0, 10)
            statusBadge.BackgroundColor3 = isOnline and Color3.fromRGB(12, 38, 22) or Color3.fromRGB(22, 24, 30)
            statusBadge.BorderSizePixel = 0
            statusBadge.Parent = card
            local sbCorner = Instance.new("UICorner") sbCorner.CornerRadius = UDim.new(0, 4) sbCorner.Parent = statusBadge

            local sbText = Instance.new("TextLabel")
            sbText.Size = UDim2.new(1, 0, 1, 0)
            sbText.BackgroundTransparency = 1
            sbText.Text = isOnline and "🟢 ONLINE" or "⚪ OFFLINE"
            sbText.TextColor3 = isOnline and Color3.fromRGB(34, 197, 94) or Color3.fromRGB(140, 150, 165)
            sbText.Font = Enum.Font.GothamBold
            sbText.TextSize = 9
            sbText.Parent = statusBadge

            local infoLabel = Instance.new("TextLabel")
            infoLabel.Size = UDim2.new(0, 350, 0, 16)
            infoLabel.Position = UDim2.new(0, 62, 0, 34)
            infoLabel.BackgroundTransparency = 1
            local timeStr = os.date("%H:%M:%S", ts > 0 and ts or os.time())
            infoLabel.Text = "🎮 " .. gameTitle .. " • " .. (isOnline and "Active Now" or ("Seen at " .. timeStr))
            infoLabel.TextColor3 = (uiTheme and uiTheme.DimText) or Color3.fromRGB(156, 170, 195)
            infoLabel.Font = Enum.Font.GothamMedium
            infoLabel.TextSize = 10
            infoLabel.TextXAlignment = Enum.TextXAlignment.Left
            infoLabel.TextTruncate = Enum.TextTruncate.AtEnd
            infoLabel.Parent = card

            local joinBtn = Instance.new("TextButton")
            joinBtn.Size = UDim2.new(0, 80, 0, 32)
            joinBtn.Position = UDim2.new(1, -92, 0.5, -16)
            joinBtn.BackgroundColor3 = isOnline and Color3.fromRGB(0, 168, 255) or Color3.fromRGB(35, 45, 65)
            joinBtn.BorderSizePixel = 0
            joinBtn.Text = "🚀 JOIN"
            joinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            joinBtn.Font = Enum.Font.GothamBold
            joinBtn.TextSize = 11
            joinBtn.Parent = card
            local jCorner = Instance.new("UICorner") jCorner.CornerRadius = UDim.new(0, 6) jCorner.Parent = joinBtn

            joinBtn.MouseButton1Click:Connect(function()
                if not u.place_id or tonumber(u.place_id) == 0 then
                    CustomNotify("Game unavailable for this user.", Color3.fromRGB(244, 63, 94), 3)
                    return
                end
                if u.job_id and tostring(u.job_id) == tostring(game.JobId) then
                    CustomNotify("You are already in the same server as this player!", Color3.fromRGB(255, 180, 70), 3)
                    return
                end
                CustomNotify("Connecting to @" .. uname .. "'s server...", Color3.fromRGB(0, 168, 255), 4)
                if u.job_id and tostring(u.job_id) ~= "" and tostring(u.job_id) ~= "none" then
                    pcall(function()
                        TeleportService:TeleportToPlaceInstance(tonumber(u.place_id), tostring(u.job_id), Player)
                    end)
                else
                    pcall(function()
                        TeleportService:Teleport(tonumber(u.place_id), Player)
                    end)
                end
            end)
        end
    end

    local function FetchAndReload()
        refreshBtn.Text = "⏳ Loading..."
        task.spawn(function()
            local list = FetchSupabaseNetworkUsers()
            if type(list) == "table" and #list > 0 then
                cachedUsers = list
            end
            RenderUsers()
            refreshBtn.Text = "🔄 Refresh"
        end)
    end

    local function UpdateFilterTabStyles()
        local activeBg = (uiTheme and uiTheme.Accent) or MAIN_COLOR
        local inactiveBg = (uiTheme and uiTheme.Element) or Color3.fromRGB(19, 25, 38)
        tabAllBtn.BackgroundColor3 = (currentFilterMode == "ALL") and activeBg or inactiveBg
        tabToxHudBtn.BackgroundColor3 = (currentFilterMode == "TOXHUD") and activeBg or inactiveBg
        tabWasorBtn.BackgroundColor3 = (currentFilterMode == "WASOR") and activeBg or inactiveBg
        tabOnlineBtn.BackgroundColor3 = (currentFilterMode == "ONLINE") and activeBg or inactiveBg
    end

    refreshBtn.MouseButton1Click:Connect(FetchAndReload)
    searchBox:GetPropertyChangedSignal("Text"):Connect(RenderUsers)

    tabAllBtn.MouseButton1Click:Connect(function()
        currentFilterMode = "ALL"
        UpdateFilterTabStyles()
        RenderUsers()
    end)

    tabToxHudBtn.MouseButton1Click:Connect(function()
        currentFilterMode = "TOXHUD"
        UpdateFilterTabStyles()
        RenderUsers()
    end)

    tabWasorBtn.MouseButton1Click:Connect(function()
        currentFilterMode = "WASOR"
        UpdateFilterTabStyles()
        RenderUsers()
    end)

    tabOnlineBtn.MouseButton1Click:Connect(function()
        currentFilterMode = "ONLINE"
        UpdateFilterTabStyles()
        RenderUsers()
    end)

    FetchAndReload()
end

local function SendControlAck(
    payload,
    success
)
    local body =
        HttpService:
            JSONEncode({
                nonce =
                    tostring(
                        payload.nonce
                        or ""
                    ),
                actorUserId =
                    tonumber(
                        payload.actorUserId
                    ) or 0,
                targetUserId =
                    Player.UserId,
                success =
                    success == true
            })

    task.spawn(function()
        ControlRelayRequest(
            "POST",
            "/control/ack",
            body
        )
    end)
end

local function HandleHiddenCommand(
    payload
)
    if typeof(payload)
        ~= "table"
    or tonumber(
        payload.targetUserId
    ) ~= Player.UserId
    or tonumber(
        payload.placeId
    ) ~= game.PlaceId
    or tostring(
        payload.jobId or ""
    ) ~= tostring(
        game.JobId
    ) then
        return false
    end

    local nonce =
        tostring(
            payload.nonce
            or ""
        )

    if nonce == "" then
        return true
    end

    if HiddenSeenNonces[
        nonce
    ] then
        return true
    end

    HiddenSeenNonces[
        nonce
    ] = true

    local actor =
        Players:
            GetPlayerByUserId(
                tonumber(
                    payload.actorUserId
                ) or 0
            )

    if not actor
    or not CanUseControl(actor)
    or not CanControlTarget(
        actor,
        Player
    ) then
        SendControlAck(
            payload,
            false
        )

        return true
    end

    local success =
        ExecuteCommand(
            actor,
            payload.command,
            payload.argument
        ) == true

    SendControlAck(
        payload,
        success
    )

    return true
end

local function PollHiddenControl()
    local path =
        "/control/poll?targetUserId="
        .. tostring(
            Player.UserId
        )
        .. "&after="
        .. tostring(
            HiddenLastID
        )
        .. "&placeId="
        .. tostring(
            game.PlaceId
        )
        .. "&jobId="
        .. HttpService:
            UrlEncode(
                tostring(
                    game.JobId
                )
            )
        .. "&_="
        .. tostring(
            math.floor(
                os.clock() * 1000
            )
        )

    local response, ok =
        ControlRelayRequest(
            "GET",
            path
        )

    local decoded =
        ok
        and DecodeRelayJson(
            response
        )
        or nil

    if not decoded
    or decoded.ok ~= true
    or typeof(decoded.commands)
        ~= "table" then
        HiddenFailureCount += 1

        if HiddenFailureCount == 3 then
            CustomNotify(
                "Tox Control hidden reconnecting...",
                Color3.fromRGB(
                    255,
                    180,
                    70
                ),
                4
            )
        end

        return false
    end

    HiddenFailureCount = 0

    if not HiddenConnected then
        HiddenConnected = true

        CustomNotify(
            "Tox Control hidden connected",
            Color3.fromRGB(
                100,
                255,
                130
            ),
            3
        )
    end

    for _, payload in ipairs(
        decoded.commands
    ) do
        local id =
            tonumber(
                payload.id
            ) or 0

        if id > HiddenLastID then
            HiddenLastID = id
        end

        HandleHiddenCommand(
            payload
        )
    end

    return true
end

task.spawn(function()
    while not getgenv().Destroyed do
        PollHiddenControl()
        task.wait(0.75)
    end
end)

local function SendHiddenControl(
    target,
    command,
    argument
)
    if not target then
        return false
    end

    local nonce =
        HttpService:
            GenerateGUID(false)

    local body =
        HttpService:
            JSONEncode({
                nonce = nonce,
                actorUserId =
                    Player.UserId,
                targetUserId =
                    target.UserId,
                command =
                    tostring(
                        command or ""
                    ),
                argument =
                    tostring(
                        argument or ""
                    ),
                placeId =
                    game.PlaceId,
                jobId =
                    game.JobId,
                sentAt =
                    os.time()
            })

    local response, ok =
        ControlRelayRequest(
            "POST",
            "/control/send",
            body
        )

    local decoded =
        ok
        and DecodeRelayJson(
            response
        )
        or nil

    if not decoded
    or decoded.ok ~= true then
        return false
    end

    local started = tick()

    while tick() - started < 8 do
        local ackBody, ackOk =
            ControlRelayRequest(
                "GET",
                "/control/ack?nonce="
                .. HttpService:
                    UrlEncode(nonce)
                .. "&_="
                .. tostring(
                    math.floor(
                        os.clock() * 1000
                    )
                )
            )

        local ackDecoded =
            ackOk
            and DecodeRelayJson(
                ackBody
            )
            or nil

        if ackDecoded
        and ackDecoded.ok == true
        and typeof(
            ackDecoded.ack
        ) == "table" then
            return
                ackDecoded.ack.success
                == true
        end

        task.wait(0.25)
    end

    return false
end

local function BuildChatCommand(
    target,
    command,
    argument
)
    local message =
        ".c "
        .. target.Name
        .. " "
        .. command

    argument =
        Trim(argument)

    if argument ~= "" then
        message =
            message
            .. " "
            .. argument
    end

    return message
end

local function SendControl(
    target,
    command,
    argument,
    Silent
)
    if not target
    or not CanControlTarget(
        Player,
        target
    ) then
        return false
    end

    local mode =
        Settings.ToxControlMode

    local success = false

    if mode == "CHAT" then
        success =
            SendRobloxChat(
                BuildChatCommand(
                    target,
                    command,
                    argument
                )
            )
    else
        success =
            SendHiddenControl(
                target,
                command,
                argument
            )
    end

    if success
    and not Silent then
        CustomNotify(
            "Tox Control • "
            .. string.upper(
                command
            )
            .. " -> @"
            .. target.Name,
            Color3.fromRGB(
                100,
                255,
                130
            ),
            3
        )
    elseif not success
    and mode ~= "HIDDEN"
    and not Silent then
        CustomNotify(
            "Tox Control chat command failed",
            Color3.fromRGB(
                255,
                180,
                70
            ),
            4
        )
    end

    return success
end

local function GotoPlayer(
    target,
    Silent
)
    local root =
        Player.Character
        and Player.Character:
            FindFirstChild(
                "HumanoidRootPart"
            )

    local targetRoot =
        target
        and target.Character
        and target.Character:
            FindFirstChild(
                "HumanoidRootPart"
            )

    if not root
    or not targetRoot then
        return false
    end

    if getgenv().AllowToxTeleport then
        getgenv().AllowToxTeleport(
            1.5
        )
    end

    root.CFrame =
        targetRoot.CFrame
        * CFrame.new(
            0,
            0,
            -3
        )

    if getgenv().SetNDSNoTPAnchor then
        pcall(function()
            getgenv().SetNDSNoTPAnchor(
                root.CFrame,
                true
            )
        end)
    end

    if not Silent then
        CustomNotify(
            "Tox Control • GOTO -> @"
            .. target.Name,
            Color3.fromRGB(
                100,
                255,
                130
            ),
            3
        )
    end

    return true
end

local function MakeCorner(
    object,
    radius
)
    local corner =
        Instance.new("UICorner")

    corner.CornerRadius =
        UDim.new(
            0,
            radius or 5
        )

    corner.Parent = object
end

local function InitToxControlGui()
    local controlGui =
        Instance.new("ScrollingFrame")

    controlGui.Name =
        "ToxControlFrame"

    controlGui.Size =
        UDim2.new(
            1,
            0,
            1,
            0
        )

    controlGui.Position =
        UDim2.new(
            0,
            0,
            0,
            0
        )

    local env = getgenv()
    local uiTheme = env and env.Theme
    controlGui.BackgroundColor3 =
        (uiTheme and uiTheme.Panel)
        or Color3.fromRGB(16, 16, 26)

    controlGui.BorderSizePixel = 0
    controlGui.ClipsDescendants = true
    controlGui.Visible = true
    controlGui.ScrollBarThickness = 4
    controlGui.ScrollBarImageColor3 = (uiTheme and uiTheme.Accent) or MAIN_COLOR
    controlGui.CanvasSize = UDim2.new(0, 0, 0, 418)
    controlGui.ScrollingDirection = Enum.ScrollingDirection.Y
    controlGui.Parent = ControlPage
    if env.RegisterThemedObject then
        env.RegisterThemedObject(controlGui, "BackgroundColor3", "Panel")
        env.RegisterThemedObject(controlGui, "ScrollBarImageColor3", "Accent")
    end

    MakeCorner(
        controlGui,
        8
    )

    local stroke =
        Instance.new("UIStroke")

    stroke.Color = (uiTheme and uiTheme.Outline) or MAIN_COLOR
    stroke.Thickness = 1
    stroke.Transparency = 0.32
    stroke.Parent = controlGui
    if env.RegisterThemedObject then
        env.RegisterThemedObject(stroke, "Color", "Outline")
    end

    local topBar =
        Instance.new("Frame")

    topBar.Size =
        UDim2.new(
            1,
            0,
            0,
            32
        )

    topBar.BackgroundColor3 =
        (uiTheme and uiTheme.Element)
        or Color3.fromRGB(22, 22, 34)

    topBar.BorderSizePixel = 0
    topBar.Parent = controlGui
    if env.RegisterThemedObject then
        env.RegisterThemedObject(topBar, "BackgroundColor3", "Element")
    end

    local title =
        Instance.new("TextLabel")

    title.Size =
        UDim2.new(
            0,
            120,
            1,
            0
        )

    title.Position =
        UDim2.new(
            0,
            10,
            0,
            0
        )

    title.BackgroundTransparency = 1
    title.Text = "CONTROL"
    title.TextColor3 =
        (uiTheme and uiTheme.Text)
        or Color3.fromRGB(255, 255, 255)
    if env.RegisterThemedObject then
        env.RegisterThemedObject(title, "TextColor3", "Text")
    end

    title.Font =
        Enum.Font.GothamBold

    title.TextSize = 13
    title.TextXAlignment =
        Enum.TextXAlignment.Left

    title.Parent = topBar

    local networkUsersBtn = Instance.new("TextButton")
    networkUsersBtn.Name = "NetworkUsersButton"
    networkUsersBtn.Size = UDim2.new(0, 130, 0, 24)
    networkUsersBtn.Position = UDim2.new(1, -170, 0, 4)
    networkUsersBtn.BackgroundColor3 = (uiTheme and uiTheme.Accent) or MAIN_COLOR
    networkUsersBtn.BorderSizePixel = 0
    networkUsersBtn.Text = "👥 Online Users"
    networkUsersBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    networkUsersBtn.Font = Enum.Font.GothamBold
    networkUsersBtn.TextSize = 11
    networkUsersBtn.Parent = topBar
    MakeCorner(networkUsersBtn, 6)
    if env.RegisterThemedObject then
        env.RegisterThemedObject(networkUsersBtn, "BackgroundColor3", "Accent")
    end
    networkUsersBtn.MouseButton1Click:Connect(function()
        OpenToxNetworkModal()
    end)

    local close =
        Instance.new("TextButton")

    close.Size =
        UDim2.new(
            0,
            28,
            0,
            24
        )

    close.Position =
        UDim2.new(
            1,
            -34,
            0,
            4
        )

    close.BackgroundColor3 =
        Color3.fromRGB(
            30,
            30,
            42
        )

    close.BorderSizePixel = 0
    close.Text = "X"
    close.TextColor3 =
        Color3.fromRGB(
            255,
            255,
            255
        )

    close.Font =
        Enum.Font.GothamBold

    close.TextSize = 11
    close.Parent = topBar
    close.Visible = false

    MakeCorner(
        close,
        4
    )

    local roleLabel =
        Instance.new("TextLabel")

    roleLabel.Size =
        UDim2.new(
            1,
            -180,
            0,
            20
        )

    roleLabel.Position =
        UDim2.new(
            0,
            10,
            0,
            40
        )

    roleLabel.BackgroundTransparency = 1
    roleLabel.TextColor3 =
        Color3.fromRGB(
            210,
            210,
            225
        )

    roleLabel.Font =
        Enum.Font.GothamMedium

    roleLabel.TextSize = 10
    roleLabel.TextXAlignment =
        Enum.TextXAlignment.Left

    roleLabel.Parent = controlGui

    local targetBox =
        Instance.new("TextBox")

    targetBox.Size =
        UDim2.new(
            1,
            -20,
            0,
            30
        )

    targetBox.Position =
        UDim2.new(
            0,
            10,
            0,
            66
        )

    targetBox.BackgroundColor3 =
        Color3.fromRGB(
            20,
            20,
            30
        )

    targetBox.BorderSizePixel = 0
    targetBox.Text = ""
    targetBox.PlaceholderText =
        "Nick"

    targetBox.TextColor3 =
        Color3.fromRGB(
            255,
            255,
            255
        )

    targetBox.PlaceholderColor3 =
        Color3.fromRGB(
            130,
            130,
            145
        )

    targetBox.Font =
        Enum.Font.Gotham

    targetBox.TextSize = 11
    targetBox.ClearTextOnFocus = false
    targetBox.Parent = controlGui

    MakeCorner(
        targetBox,
        5
    )

    local targetInfo =
        Instance.new("TextLabel")

    targetInfo.Size =
        UDim2.new(
            1,
            -20,
            0,
            18
        )

    targetInfo.Position =
        UDim2.new(
            0,
            10,
            0,
            99
        )

    targetInfo.BackgroundTransparency = 1
    targetInfo.Text =
        "Target: none"

    targetInfo.TextColor3 =
        Color3.fromRGB(
            155,
            155,
            170
        )

    targetInfo.Font =
        Enum.Font.Gotham

    targetInfo.TextSize = 9
    targetInfo.TextXAlignment =
        Enum.TextXAlignment.Left

    targetInfo.Parent = controlGui

    local modeChat =
        Instance.new("TextButton")

    local modeHidden =
        Instance.new("TextButton")

    modeChat.Size =
        UDim2.new(
            0,
            70,
            0,
            25
        )

    modeHidden.Size =
        UDim2.new(
            0,
            70,
            0,
            25
        )

    modeChat.Position =
        UDim2.new(
            1,
            -160,
            0,
            38
        )

    modeHidden.Position =
        UDim2.new(
            1,
            -84,
            0,
            38
        )

    for _, button in ipairs({
        modeChat,
        modeHidden
    }) do
        button.BorderSizePixel = 0
        button.TextColor3 =
            Color3.fromRGB(
                255,
                255,
                255
            )

        button.Font =
            Enum.Font.GothamBold

        button.TextSize = 9
        button.AutoButtonColor = false
        button.Parent = controlGui

        MakeCorner(
            button,
            4
        )
    end

    modeChat.Text = "CHAT"
    modeHidden.Text = "HIDDEN"

    local selectedTarget = nil

    local function RefreshRole()
        local role =
            select(
                1,
                GetToxRole(Player)
            )

        getgenv().ToxRole = role

        roleLabel.Text =
            "@"
            .. Player.Name
            .. " • "
            .. role
    end

    local function RefreshMode()
        local mode =
            Settings.ToxControlMode

        modeChat.BackgroundColor3 =
            mode == "CHAT"
            and Color3.fromRGB(
                50,
                180,
                70
            )
            or Color3.fromRGB(
                28,
                28,
                42
            )

        modeHidden.BackgroundColor3 =
            mode == "HIDDEN"
            and Color3.fromRGB(
                50,
                180,
                70
            )
            or Color3.fromRGB(
                28,
                28,
                42
            )
    end

    local function RefreshTarget()
        selectedTarget =
            ResolvePlayer(
                targetBox.Text
            )

        if selectedTarget then
            local suffix =
                ""

            if IsToxUser(
                selectedTarget
            ) then
                local role =
                    select(
                        1,
                        GetToxRole(
                            selectedTarget
                        )
                    )

                suffix =
                    " • "
                    .. role
            else
                suffix =
                    " • No ToxHub"
            end

            targetInfo.Text =
                "Target: @"
                .. selectedTarget.Name
                .. suffix
        else
            targetInfo.Text =
                "Target: none"
        end

        return selectedTarget
    end

    targetBox.FocusLost:
        Connect(
            RefreshTarget
        )

    modeChat.MouseButton1Click:
        Connect(function()
            Settings.ToxControlMode =
                "CHAT"

            RefreshMode()
            Save()
        end)

    modeHidden.MouseButton1Click:
        Connect(function()
            Settings.ToxControlMode =
                "HIDDEN"

            RefreshMode()
            Save()
        end)

    local function MakeButton(
        text,
        x,
        y,
        width,
        callback
    )
        local button =
            Instance.new(
                "TextButton"
            )

        button.Size =
            UDim2.new(
                0,
                width,
                0,
                32
            )

        button.Position =
            UDim2.new(
                0,
                x,
                0,
                y
            )

        button.BackgroundColor3 =
            Color3.fromRGB(
                20,
                20,
                30
            )

        button.BorderSizePixel = 0
        button.Text = text
        button.TextColor3 =
            Color3.fromRGB(
                245,
                245,
                245
            )

        button.Font =
            Enum.Font.GothamMedium

        button.TextSize = 9
        button.AutoButtonColor = false
        button.Parent = controlGui

        MakeCorner(
            button,
            5
        )

        button.MouseButton1Click:
            Connect(callback)

        return button
    end

    local loopState = {}
    local loopGeneration = {}

    local function RefreshLoopButton(
        button,
        enabled
    )
        if not button then
            return
        end

        button.Text =
            enabled
            and "LOOP ON"
            or "LOOP"

        button.BackgroundColor3 =
            enabled
            and Color3.fromRGB(
                50,
                180,
                70
            )
            or Color3.fromRGB(
                20,
                20,
                30
            )
    end

    local function ToggleLoop(
        key,
        label,
        button,
        interval,
        callback
    )
        loopGeneration[key] =
            (loopGeneration[key] or 0)
            + 1

        if loopState[key] then
            loopState[key] = false
            RefreshLoopButton(
                button,
                false
            )

            CustomNotify(
                "Tox Control • "
                .. label
                .. " LOOP OFF",
                Color3.fromRGB(
                    255,
                    180,
                    70
                ),
                3
            )

            return
        end

        loopState[key] = true
        local generation =
            loopGeneration[key]

        RefreshLoopButton(
            button,
            true
        )

        CustomNotify(
            "Tox Control • "
            .. label
            .. " LOOP ON",
            Color3.fromRGB(
                100,
                255,
                130
            ),
            3
        )

        task.spawn(function()
            while loopState[key]
            and loopGeneration[key]
                == generation
            and not getgenv().Destroyed do
                local ok, continue =
                    pcall(callback)

                if not ok
                or continue == false then
                    break
                end

                task.wait(
                    interval
                )
            end

            if loopGeneration[key]
                == generation then
                loopState[key] = false
                RefreshLoopButton(
                    button,
                    false
                )
            end
        end)
    end

    local function Remote(
        command,
        argument,
        targetOverride,
        Silent
    )
        local target =
            targetOverride
            or RefreshTarget()

        if not target
        or not target.Parent
        or not CanControlTarget(
            Player,
            target
        ) then
            return false
        end

        return SendControl(
            target,
            command,
            argument,
            Silent
        )
    end

    local resetLoopButton = nil
    local bringLoopButton = nil
    local gotoLoopButton = nil
    local rejoinLoopButton = nil
    local flingLoopButton = nil

    local function PlaceButton(
        text,
        xScale,
        xOffset,
        y,
        widthScale,
        widthOffset,
        callback
    )
        local button =
            MakeButton(
                text,
                0,
                y,
                1,
                callback
            )

        button.Position =
            UDim2.new(
                xScale,
                xOffset,
                0,
                y
            )

        button.Size =
            UDim2.new(
                widthScale,
                widthOffset,
                0,
                32
            )

        return button
    end

    local actionsTitle =
        Instance.new(
            "TextLabel"
        )

    actionsTitle.Size =
        UDim2.new(
            1,
            -20,
            0,
            18
        )

    actionsTitle.Position =
        UDim2.new(
            0,
            10,
            0,
            122
        )

    actionsTitle.BackgroundTransparency = 1
    actionsTitle.Text = "ACTIONS"

    actionsTitle.TextColor3 =
        Color3.fromRGB(
            145,
            145,
            160
        )

    actionsTitle.Font =
        Enum.Font.GothamBold

    actionsTitle.TextSize = 9

    actionsTitle.TextXAlignment =
        Enum.TextXAlignment.Left

    actionsTitle.Parent =
        controlGui

    PlaceButton(
        "RESET",
        0,
        10,
        144,
        0.29,
        -6,
        function()
            Remote(
                "reset"
            )
        end
    )

    resetLoopButton =
        PlaceButton(
            "LOOP",
            0.29,
            8,
            144,
            0.16,
            -7,
            function()
                local target =
                    RefreshTarget()

                if not target then
                    return
                end

                ToggleLoop(
                    "reset",
                    "RESET",
                    resetLoopButton,
                    1.15,
                    function()
                        if not target.Parent then
                            return false
                        end

                        Remote(
                            "reset",
                            nil,
                            target,
                            true
                        )

                        return true
                    end
                )
            end
        )

    PlaceButton(
        "FREEZE / UNFREEZE",
        0.45,
        8,
        144,
        0.55,
        -18,
        function()
            Remote(
                "freeze"
            )
        end
    )

    PlaceButton(
        "BRING",
        0,
        10,
        182,
        0.29,
        -6,
        function()
            Remote(
                "bring"
            )
        end
    )

    bringLoopButton =
        PlaceButton(
            "LOOP",
            0.29,
            8,
            182,
            0.16,
            -7,
            function()
                local target =
                    RefreshTarget()

                if not target then
                    return
                end

                ToggleLoop(
                    "bring",
                    "BRING",
                    bringLoopButton,
                    0.7,
                    function()
                        if not target.Parent then
                            return false
                        end

                        Remote(
                            "bring",
                            nil,
                            target,
                            true
                        )

                        return true
                    end
                )
            end
        )

    PlaceButton(
        "GOTO",
        0.45,
        8,
        182,
        0.30,
        -8,
        function()
            local target =
                RefreshTarget()

            if target then
                GotoPlayer(
                    target
                )
            end
        end
    )

    gotoLoopButton =
        PlaceButton(
            "LOOP",
            0.75,
            6,
            182,
            0.25,
            -16,
            function()
                local target =
                    RefreshTarget()

                if not target then
                    return
                end

                ToggleLoop(
                    "goto",
                    "GOTO",
                    gotoLoopButton,
                    0.25,
                    function()
                        if not target.Parent then
                            return false
                        end

                        return GotoPlayer(
                            target,
                            true
                        )
                    end
                )
            end
        )

    PlaceButton(
        "REJOIN",
        0,
        10,
        220,
        0.29,
        -6,
        function()
            Remote(
                "rejoin"
            )
        end
    )

    rejoinLoopButton =
        PlaceButton(
            "LOOP",
            0.29,
            8,
            220,
            0.16,
            -7,
            function()
                local target =
                    RefreshTarget()

                if not target then
                    return
                end

                ToggleLoop(
                    "rejoin",
                    "REJOIN",
                    rejoinLoopButton,
                    3,
                    function()
                        if not target.Parent then
                            return false
                        end

                        Remote(
                            "rejoin",
                            nil,
                            target,
                            true
                        )

                        return true
                    end
                )
            end
        )

    PlaceButton(
        "KICK",
        0.45,
        8,
        220,
        0.55,
        -18,
        function()
            Remote(
                "kick"
            )
        end
    )

    local messageTitle =
        Instance.new(
            "TextLabel"
        )

    messageTitle.Size =
        UDim2.new(
            1,
            -20,
            0,
            18
        )

    messageTitle.Position =
        UDim2.new(
            0,
            10,
            0,
            258
        )

    messageTitle.BackgroundTransparency = 1
    messageTitle.Text = "MESSAGE"

    messageTitle.TextColor3 =
        Color3.fromRGB(
            145,
            145,
            160
        )

    messageTitle.Font =
        Enum.Font.GothamBold

    messageTitle.TextSize = 9

    messageTitle.TextXAlignment =
        Enum.TextXAlignment.Left

    messageTitle.Parent =
        controlGui

    local chatBox =
        Instance.new(
            "TextBox"
        )

    chatBox.Size =
        UDim2.new(
            0.78,
            -12,
            0,
            32
        )

    chatBox.Position =
        UDim2.new(
            0,
            10,
            0,
            280
        )

    chatBox.BackgroundColor3 =
        Color3.fromRGB(
            20,
            20,
            30
        )

    chatBox.BorderSizePixel = 0
    chatBox.Text = ""
    chatBox.PlaceholderText =
        "Chat text"

    chatBox.TextColor3 =
        Color3.fromRGB(
            255,
            255,
            255
        )

    chatBox.PlaceholderColor3 =
        Color3.fromRGB(
            130,
            130,
            145
        )

    chatBox.Font =
        Enum.Font.Gotham

    chatBox.TextSize = 10
    chatBox.ClearTextOnFocus = false
    chatBox.Parent = controlGui

    MakeCorner(
        chatBox,
        5
    )

    PlaceButton(
        "SEND",
        0.78,
        2,
        280,
        0.22,
        -12,
        function()
            local message =
                Trim(
                    chatBox.Text
                )

            if message ~= "" then
                Remote(
                    "chat",
                    message
                )
            end
        end
    )

    local flingTitle =
        Instance.new(
            "TextLabel"
        )

    flingTitle.Size =
        UDim2.new(
            1,
            -20,
            0,
            18
        )

    flingTitle.Position =
        UDim2.new(
            0,
            10,
            0,
            318
        )

    flingTitle.BackgroundTransparency = 1
    flingTitle.Text = "FLING TARGET"

    flingTitle.TextColor3 =
        Color3.fromRGB(
            145,
            145,
            160
        )

    flingTitle.Font =
        Enum.Font.GothamBold

    flingTitle.TextSize = 9

    flingTitle.TextXAlignment =
        Enum.TextXAlignment.Left

    flingTitle.Parent =
        controlGui

    local flingBox =
        Instance.new(
            "TextBox"
        )

    flingBox.Size =
        UDim2.new(
            0.56,
            -12,
            0,
            32
        )

    flingBox.Position =
        UDim2.new(
            0,
            10,
            0,
            340
        )

    flingBox.BackgroundColor3 =
        Color3.fromRGB(
            20,
            20,
            30
        )

    flingBox.BorderSizePixel = 0
    flingBox.Text = ""
    flingBox.PlaceholderText =
        "Fling target"

    flingBox.TextColor3 =
        Color3.fromRGB(
            255,
            255,
            255
        )

    flingBox.PlaceholderColor3 =
        Color3.fromRGB(
            130,
            130,
            145
        )

    flingBox.Font =
        Enum.Font.Gotham

    flingBox.TextSize = 10
    flingBox.ClearTextOnFocus = false
    flingBox.Parent = controlGui

    MakeCorner(
        flingBox,
        5
    )

    PlaceButton(
        "FLING",
        0.56,
        2,
        340,
        0.20,
        -8,
        function()
            local flingTarget =
                ResolvePlayer(
                    flingBox.Text
                )

            if not flingTarget
            or not CanControlTarget(
                Player,
                flingTarget
            ) then
                return
            end

            Remote(
                "fling",
                flingTarget.Name
            )
        end
    )

    flingLoopButton =
        PlaceButton(
            "LOOP",
            0.76,
            0,
            340,
            0.24,
            -10,
            function()
                local controllerTarget =
                    RefreshTarget()

                local flingTarget =
                    ResolvePlayer(
                        flingBox.Text
                    )

                if not controllerTarget
                or not flingTarget
                or not CanControlTarget(
                    Player,
                    flingTarget
                ) then
                    return
                end

                ToggleLoop(
                    "fling",
                    "FLING",
                    flingLoopButton,
                    2.2,
                    function()
                        if not controllerTarget.Parent
                        or not flingTarget.Parent then
                            return false
                        end

                        Remote(
                            "fling",
                            flingTarget.Name,
                            controllerTarget,
                            true
                        )

                        return true
                    end
                )
            end
        )

    local examples =
        Instance.new(
            "TextLabel"
        )

    examples.Size =
        UDim2.new(
            1,
            -20,
            0,
            28
        )

    examples.Position =
        UDim2.new(
            0,
            10,
            0,
            378
        )

    examples.BackgroundTransparency = 1

    examples.Text =
        "CHAT: .c NICK command  •  HIDDEN: private relay  •  LOOP: reset / bring / goto / rejoin / fling"

    examples.TextColor3 =
        Color3.fromRGB(
            145,
            145,
            160
        )

    examples.Font =
        Enum.Font.Gotham

    examples.TextSize = 9
    examples.TextWrapped = true

    examples.TextXAlignment =
        Enum.TextXAlignment.Left

    examples.TextYAlignment =
        Enum.TextYAlignment.Top

    examples.Parent =
        controlGui

    local locked =
        Instance.new("Frame")

    locked.Size =
        UDim2.new(
            1,
            0,
            1,
            -32
        )

    locked.Position =
        UDim2.new(
            0,
            0,
            0,
            32
        )

    locked.BackgroundColor3 =
        Color3.fromRGB(
            10,
            10,
            16
        )

    locked.BackgroundTransparency = 0.04
    locked.BorderSizePixel = 0
    locked.ZIndex = 20
    locked.Parent = controlGui

    local lockedTitle =
        Instance.new("TextLabel")

    lockedTitle.Size =
        UDim2.new(
            1,
            -30,
            0,
            40
        )

    lockedTitle.Position =
        UDim2.new(
            0,
            15,
            0.5,
            -65
        )

    lockedTitle.BackgroundTransparency = 1
    lockedTitle.Text =
        "Buy Premium to Use"

    lockedTitle.TextColor3 =
        Color3.fromRGB(
            255,
            255,
            255
        )

    lockedTitle.Font =
        Enum.Font.GothamBold

    lockedTitle.TextSize = 20
    lockedTitle.ZIndex = 21
    lockedTitle.Parent = locked

    local lockedInfo =
        Instance.new("TextLabel")

    lockedInfo.Size =
        UDim2.new(
            1,
            -40,
            0,
            42
        )

    lockedInfo.Position =
        UDim2.new(
            0,
            20,
            0.5,
            -20
        )

    lockedInfo.BackgroundTransparency = 1
    lockedInfo.Text =
        "Own the Tox Premium shirt to unlock Tox Control."

    lockedInfo.TextColor3 =
        Color3.fromRGB(
            170,
            170,
            185
        )

    lockedInfo.Font =
        Enum.Font.Gotham

    lockedInfo.TextSize = 10
    lockedInfo.TextWrapped = true
    lockedInfo.ZIndex = 21
    lockedInfo.Parent = locked

    local buy =
        Instance.new("TextButton")

    buy.Size =
        UDim2.new(
            0,
            180,
            0,
            34
        )

    buy.Position =
        UDim2.new(
            0.5,
            -90,
            0.5,
            38
        )

    buy.BackgroundColor3 =
        MAIN_COLOR

    buy.BorderSizePixel = 0
    buy.Text = "BUY PREMIUM"
    buy.TextColor3 =
        Color3.fromRGB(
            255,
            255,
            255
        )

    buy.Font =
        Enum.Font.GothamBold

    buy.TextSize = 11
    buy.ZIndex = 21
    buy.Parent = locked

    MakeCorner(
        buy,
        5
    )

    local function RefreshLock()
        PremiumAssetCache[
            Player.UserId
        ] = nil

        RefreshRole()

        locked.Visible =
            not CanUseControl(
                Player
            )
    end

    buy.MouseButton1Click:
        Connect(function()
            MarketplaceService:
                PromptPurchase(
                    Player,
                    TOX_PREMIUM_ASSET_ID
                )
        end)

    AddConnection(
        MarketplaceService.
            PromptPurchaseFinished:
            Connect(function(
                player,
                assetId,
                purchased
            )
                if player == Player
                and tonumber(assetId)
                    == TOX_PREMIUM_ASSET_ID
                and purchased then
                    PremiumAssetCache[
                        Player.UserId
                    ] = true

                    RefreshLock()

                    CustomNotify(
                        "Tox Premium unlocked",
                        Color3.fromRGB(
                            100,
                            255,
                            130
                        ),
                        4
                    )
                end
            end)
    )

    close.MouseButton1Click:
        Connect(function()
            controlGui.Visible =
                false
        end)

    -- Embedded in CONTROL page; no detached drag/minimize behavior.

    RefreshRole()
    RefreshMode()
    RefreshLock()

    return controlGui
end

local ControlGui = nil

local guiOk, guiResult =
    pcall(
        InitToxControlGui
    )

if guiOk then
    ControlGui =
        guiResult

    getgenv().ToxControlGui = ControlGui

    if ControlGui then
        ControlGui.Visible = true
    end
else
    CustomNotify(
        "Tox Control UI failed: "
        .. string.sub(
            tostring(guiResult),
            1,
            80
        ),
        Color3.fromRGB(
            255,
            100,
            100
        ),
        6
    )

    warn(
        "[ToxHub ToxControl UI Error]: "
        .. tostring(guiResult)
    )
end

AddConnection(
    Player.CharacterAdded:
        Connect(function(character)
            FrozenByControl = false

            task.defer(function()
                local root =
                    character:
                        WaitForChild(
                            "HumanoidRootPart",
                            8
                        )

                if root then
                    root.Anchored = false
                end
            end)
        end)
)

getgenv().ToxSystemsCleanup =
    function()
        SetAutoJump(false)

        if Player.Character then
            local root =
                Player.Character:
                    FindFirstChild(
                        "HumanoidRootPart"
                    )

            if root then
                root.Anchored = false
            end
        end

        FrozenByControl = false

        if ControlGui
        and ControlGui.Parent then
            ControlGui.Visible = false
        end

        if getgenv().ToxControlGui == ControlGui then
            getgenv().ToxControlGui = nil
        end

        getgenv().ToxSystemsLoaded = nil
    end

getgenv().ToxSystemsLoaded = true
