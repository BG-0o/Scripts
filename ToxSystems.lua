if getgenv().ToxSystemsLoaded then
    return
end

if not getgenv().ToxUniversalLoaded then
    local notify = getgenv().CustomNotify

    if notify then
        notify(
            "Universal.lua must load before ToxSystems.lua",
            Color3.fromRGB(255, 100, 100),
            5
        )
    end

    return
end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local Player = Players.LocalPlayer
local Gui = getgenv().Gui
local FlingPage = getgenv().FlingPage
local MAIN_COLOR = getgenv().MAIN_COLOR
local CustomNotify = getgenv().CustomNotify
local AddConnection = getgenv().AddConnection
local CreateButton = getgenv().CreateButton

if not Player
or not Gui
or not FlingPage
or not CustomNotify
or not AddConnection
or not CreateButton then
    return
end

local API =
    getgenv().ToxChatAPI
    or {}

getgenv().ToxChatAPI = API
getgenv().ToxSystemsAPI = API
getgenv().ToxSystemsCleanup =
    getgenv().ToxSystemsCleanup
    or function()
    end

local function InitToxControl()
local TOX_OWNER_ID = 2245662672
local TOX_FRIEND_IDS = {
}

local TOX_PREMIUM_IDS = {
}

local TOX_ROLE_LEVELS = {
    Member = 1,
    Friend = 2,
    Premium = 3,
    Owner = 4
}

local function BuildToxRoleSet(list)
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

local ToxFriendSet =
    BuildToxRoleSet(
        TOX_FRIEND_IDS
    )

local ToxPremiumSet =
    BuildToxRoleSet(
        TOX_PREMIUM_IDS
    )

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

    if ToxPremiumSet[userId] then
        return "Premium", 3
    end

    if ToxFriendSet[userId] then
        return "Friend", 2
    end

    return "Member", 1
end

local function GetToxRoleByUserId(userId)
    local player =
        Players:GetPlayerByUserId(
            tonumber(userId) or 0
        )

    if not player then
        return "Member", 1, nil
    end

    local role, level =
        GetToxRole(player)

    return role, level, player
end

local function CanUseToxControl(player)
    local _, level = GetToxRole(player)

    return level
        >= TOX_ROLE_LEVELS.Friend
end

local function CanControlTarget(
    actor,
    target
)
    if not actor or not target then
        return false
    end

    local actorRole, actorLevel =
        GetToxRole(actor)
    local targetRole, targetLevel =
        GetToxRole(target)

    if target.UserId == TOX_OWNER_ID
    and actor.UserId ~= TOX_OWNER_ID then
        return false
    end

    if actorLevel < targetLevel then
        return false
    end

    return true, nil,
        actorRole,
        targetRole
end

getgenv().ToxRole =
    select(
        1,
        GetToxRole(Player)
    )

local ToxControlFrozen = false
local ToxControlBhop = false
local ToxControlBhopConnection = nil

local function SetToxControlBhop(enabled)
    ToxControlBhop =
        enabled == true

    if ToxControlBhopConnection then
        ToxControlBhopConnection:
            Disconnect()

        ToxControlBhopConnection = nil
    end

    if not ToxControlBhop then
        return
    end

    ToxControlBhopConnection =
        AddConnection(
            RunService.Heartbeat:
                Connect(function()
                    if not ToxControlBhop
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

                    if not humanoid
                    or humanoid.Health <= 0 then
                        return
                    end

                    if humanoid.FloorMaterial
                    ~= Enum.Material.Air then
                        humanoid.Jump = true
                    end
                end)
        )
end

local function SendLocalChatMessage(message)
    message =
        tostring(message or "")
            :gsub("[\r\n]+", " ")
            :match("^%s*(.-)%s*$")
        or ""

    if message == "" then
        return false
    end

    if #message > 180 then
        message =
            string.sub(
                message,
                1,
                180
            )
    end

    local sent = false

    pcall(function()
        local inputConfig =
            TextChatService:
                FindFirstChild(
                    "ChatInputBarConfiguration"
                )

        local channel =
            inputConfig
            and inputConfig.TargetTextChannel

        if channel then
            channel:SendAsync(message)
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

local function ExecuteToxControlCommand(
    actor,
    command,
    argument
)
    local allowed =
        CanControlTarget(
            actor,
            Player
        )

    if not allowed then
        return false
    end

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

    command =
        string.lower(
            tostring(command or "")
        )

    if command == "reset" then
        if humanoid then
            pcall(function()
                humanoid.Health = 0
            end)

            pcall(function()
                humanoid:
                    ChangeState(
                        Enum.HumanoidStateType.Dead
                    )
            end)
        end

        if character then
            pcall(function()
                character:BreakJoints()
            end)
        end

        return true
    end

    if command == "freeze" then
        if root then
            ToxControlFrozen =
                not ToxControlFrozen

            root.Anchored =
                ToxControlFrozen
        end

        return true
    end

    if command == "bring" then
        local actorCharacter =
            actor.Character
        local actorRoot =
            actorCharacter
            and actorCharacter:
                FindFirstChild(
                    "HumanoidRootPart"
                )

        if root and actorRoot then
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
        end

        return true
    end

    if command == "bhop" then
        SetToxControlBhop(
            not ToxControlBhop
        )

        return true
    end

    if command == "chat" then
        return SendLocalChatMessage(
            argument
        )
    end

    if command == "kick" then
        pcall(function()
            Player:Kick(
                "Tox Control"
            )
        end)

        return true
    end

    if command == "rejoin" then
        task.spawn(function()
            local ok = pcall(function()
                TeleportService:
                    TeleportToPlaceInstance(
                        game.PlaceId,
                        game.JobId,
                        Player
                    )
            end)

            if not ok then
                pcall(function()
                    TeleportService:Teleport(
                        game.PlaceId,
                        Player
                    )
                end)
            end
        end)

        return true
    end

    if command == "jump" then
        if humanoid
        and humanoid.Health > 0 then
            humanoid.Jump = true

            pcall(function()
                humanoid:ChangeState(
                    Enum.HumanoidStateType.Jumping
                )
            end)
        end

        return true
    end

    if command == "sit" then
        if humanoid
        and humanoid.Health > 0 then
            humanoid.Sit =
                not humanoid.Sit
        end

        return true
    end

    if command == "unfreeze" then
        ToxControlFrozen = false

        if root then
            root.Anchored = false
        end

        return true
    end

    if command == "unbhop" then
        SetToxControlBhop(false)
        return true
    end

    return false
end

local ToxControlRecentMessages = {}

local function ResolveToxControlPlayer(textValue)
    local input =
        tostring(textValue or "")
            :gsub("^%s+", "")
            :gsub("%s+$", "")
            :gsub("^@", "")

    if input == "" then
        return nil
    end

    local lower =
        string.lower(input)
    local exact = nil
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
            exact = candidate
            break
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

    return exact or partial
end

local function SendToxControlChatCommand(
    target,
    command,
    argument
)
    if not target then
        return false
    end

    local targetText =
        target.Name

    local message =
        ".c "
        .. targetText
        .. " "
        .. tostring(command or "")

    local extra =
        tostring(argument or "")
            :gsub("[\r\n]+", " ")
            :match("^%s*(.-)%s*$")
        or ""

    if extra ~= "" then
        message =
            message
            .. " "
            .. extra
    end

    return SendLocalChatMessage(
        message
    )
end

local function IsDuplicateToxControlMessage(
    actor,
    message
)
    local key =
        tostring(
            actor.UserId
        )
        .. "|"
        .. string.lower(
            tostring(message or "")
        )

    local now = tick()
    local previous =
        ToxControlRecentMessages[key]

    ToxControlRecentMessages[key] = now

    for oldKey, timeValue in pairs(
        ToxControlRecentMessages
    ) do
        if now - timeValue > 3 then
            ToxControlRecentMessages[oldKey] =
                nil
        end
    end

    return previous
        and now - previous < 0.75
end

local function ExecuteLocalGoto(
    target
)
    local targetRoot =
        target
        and target.Character
        and target.Character:
            FindFirstChild(
                "HumanoidRootPart"
            )

    local root =
        Player.Character
        and Player.Character:
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

    return true
end

local function HandleToxControlChatCommand(
    actor,
    message
)
    if not actor
    or typeof(message) ~= "string"
    or IsDuplicateToxControlMessage(
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
    or not command then
        return false
    end

    if not CanUseToxControl(actor) then
        return true
    end

    local target =
        ResolveToxControlPlayer(
            targetText
        )

    if not target then
        return true
    end

    command =
        string.lower(command)

    if command == "goto" then
        if actor == Player then
            ExecuteLocalGoto(target)
        end

        return true
    end

    if target ~= Player then
        return true
    end

    if not CanControlTarget(
        actor,
        Player
    ) then
        return true
    end

    if command == "fling" then
        local flingTarget =
            ResolveToxControlPlayer(
                argument
            )

        if not flingTarget
        or not CanControlTarget(
            actor,
            flingTarget
        ) then
            return true
        end

        local executeFling =
            getgenv().ToxExecuteFling

        if executeFling then
            task.spawn(function()
                executeFling(
                    flingTarget.Name
                )
            end)
        end

        return true
    end

    ExecuteToxControlCommand(
        actor,
        command,
        argument
    )

    return true
end

local function HookToxControlPlayer(
    player
)
    if not player then
        return
    end

    AddConnection(
        player.Chatted:
            Connect(function(message)
                HandleToxControlChatCommand(
                    player,
                    message
                )
            end)
    )
end

for _, player in ipairs(
    Players:GetPlayers()
) do
    HookToxControlPlayer(player)
end

AddConnection(
    Players.PlayerAdded:
        Connect(
            HookToxControlPlayer
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
                HandleToxControlChatCommand(
                    actor,
                    message.Text
                )
            end
        end)
)

local function InitToxControlGui()
local ToxControlGui =
    Instance.new("Frame")
ToxControlGui.Name =
    "ToxControlFrame"
ToxControlGui.Size =
    UDim2.new(0, 360, 0, 390)
ToxControlGui.Position =
    UDim2.new(0.5, -180, 0.5, -195)
ToxControlGui.BackgroundColor3 =
    Color3.fromRGB(10, 10, 16)
ToxControlGui.BorderSizePixel = 0
ToxControlGui.ClipsDescendants = true
ToxControlGui.Visible = false
ToxControlGui.Parent = Gui

local ToxControlCorner =
    Instance.new("UICorner")
ToxControlCorner.CornerRadius =
    UDim.new(0, 8)
ToxControlCorner.Parent =
    ToxControlGui

local ToxControlStroke =
    Instance.new("UIStroke")
ToxControlStroke.Color = MAIN_COLOR
ToxControlStroke.Thickness = 2
ToxControlStroke.Parent =
    ToxControlGui

local ToxControlTopBar =
    Instance.new("Frame")
ToxControlTopBar.Size =
    UDim2.new(1, 0, 0, 32)
ToxControlTopBar.BackgroundColor3 =
    MAIN_COLOR
ToxControlTopBar.BorderSizePixel = 0
ToxControlTopBar.Parent =
    ToxControlGui

local ToxControlTitle =
    Instance.new("TextLabel")
ToxControlTitle.Size =
    UDim2.new(1, -80, 1, 0)
ToxControlTitle.Position =
    UDim2.new(0, 10, 0, 0)
ToxControlTitle.BackgroundTransparency = 1
ToxControlTitle.Text =
    "Tox Control"
ToxControlTitle.TextColor3 =
    Color3.fromRGB(255, 255, 255)
ToxControlTitle.Font =
    Enum.Font.GothamBold
ToxControlTitle.TextSize = 13
ToxControlTitle.TextXAlignment =
    Enum.TextXAlignment.Left
ToxControlTitle.Parent =
    ToxControlTopBar

local ToxControlClose =
    Instance.new("TextButton")
ToxControlClose.Size =
    UDim2.new(0, 28, 0, 24)
ToxControlClose.Position =
    UDim2.new(1, -34, 0, 4)
ToxControlClose.BackgroundColor3 =
    Color3.fromRGB(30, 30, 42)
ToxControlClose.BorderSizePixel = 0
ToxControlClose.Text = "X"
ToxControlClose.TextColor3 =
    Color3.fromRGB(255, 255, 255)
ToxControlClose.Font =
    Enum.Font.GothamBold
ToxControlClose.TextSize = 11
ToxControlClose.Parent =
    ToxControlTopBar

local ToxControlCloseCorner =
    Instance.new("UICorner")
ToxControlCloseCorner.CornerRadius =
    UDim.new(0, 4)
ToxControlCloseCorner.Parent =
    ToxControlClose

local ToxRoleName, ToxRoleLevel =
    GetToxRole(Player)

local ToxControlIdentity =
    Instance.new("TextLabel")
ToxControlIdentity.Size =
    UDim2.new(1, -20, 0, 24)
ToxControlIdentity.Position =
    UDim2.new(0, 10, 0, 40)
ToxControlIdentity.BackgroundTransparency = 1
ToxControlIdentity.Text =
    "@"
    .. Player.Name
    .. " • "
    .. ToxRoleName
ToxControlIdentity.TextColor3 =
    Color3.fromRGB(210, 210, 225)
ToxControlIdentity.Font =
    Enum.Font.GothamMedium
ToxControlIdentity.TextSize = 11
ToxControlIdentity.TextXAlignment =
    Enum.TextXAlignment.Left
ToxControlIdentity.Parent =
    ToxControlGui

local ToxControlTarget =
    Instance.new("TextBox")
ToxControlTarget.Size =
    UDim2.new(1, -20, 0, 30)
ToxControlTarget.Position =
    UDim2.new(0, 10, 0, 68)
ToxControlTarget.BackgroundColor3 =
    Color3.fromRGB(20, 20, 30)
ToxControlTarget.BorderSizePixel = 0
ToxControlTarget.Text = ""
ToxControlTarget.PlaceholderText =
    "Nick"
ToxControlTarget.TextColor3 =
    Color3.fromRGB(255, 255, 255)
ToxControlTarget.PlaceholderColor3 =
    Color3.fromRGB(130, 130, 145)
ToxControlTarget.Font =
    Enum.Font.Gotham
ToxControlTarget.TextSize = 11
ToxControlTarget.ClearTextOnFocus = false
ToxControlTarget.Parent =
    ToxControlGui

local ToxControlTargetCorner =
    Instance.new("UICorner")
ToxControlTargetCorner.CornerRadius =
    UDim.new(0, 5)
ToxControlTargetCorner.Parent =
    ToxControlTarget

local ToxControlTargetInfo =
    Instance.new("TextLabel")
ToxControlTargetInfo.Size =
    UDim2.new(1, -20, 0, 20)
ToxControlTargetInfo.Position =
    UDim2.new(0, 10, 0, 101)
ToxControlTargetInfo.BackgroundTransparency = 1
ToxControlTargetInfo.Text =
    "Target: none"
ToxControlTargetInfo.TextColor3 =
    Color3.fromRGB(160, 160, 175)
ToxControlTargetInfo.Font =
    Enum.Font.Gotham
ToxControlTargetInfo.TextSize = 10
ToxControlTargetInfo.TextXAlignment =
    Enum.TextXAlignment.Left
ToxControlTargetInfo.Parent =
    ToxControlGui

local ToxControlSelectedTarget = nil

local function ResolveToxControlTarget()
    local input =
        tostring(
            ToxControlTarget.Text or ""
        )
        :gsub("^%s+", "")
        :gsub("%s+$", "")
        :gsub("^@", "")

    if input == "" then
        ToxControlSelectedTarget = nil
        ToxControlTargetInfo.Text =
            "Target: none"

        return nil
    end

    local lower =
        string.lower(input)
    local found = nil

    for _, candidate in ipairs(
        Players:GetPlayers()
    ) do
        if candidate ~= Player then
            local name =
                string.lower(candidate.Name)
            local display =
                string.lower(
                    candidate.DisplayName
                )

            if name == lower
            or display == lower
            or string.find(
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
            ) == 1 then
                found = candidate
                break
            end
        end
    end

    ToxControlSelectedTarget = found

    if found then
        local role =
            select(
                1,
                GetToxRole(found)
            )

        ToxControlTargetInfo.Text =
            "Target: @"
            .. found.Name
            .. " • "
            .. role
    else
        ToxControlTargetInfo.Text =
            "Target: not found"
    end

    return found
end

ToxControlTarget.FocusLost:
    Connect(function()
        ResolveToxControlTarget()
    end)

local function MakeToxControlButton(
    textValue,
    x,
    y,
    width,
    callback
)
    local button =
        Instance.new("TextButton")

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
    button.Text = textValue
    button.TextColor3 =
        Color3.fromRGB(
            245,
            245,
            245
        )
    button.Font =
        Enum.Font.GothamMedium
    button.TextSize = 10
    button.Parent =
        ToxControlGui

    local corner =
        Instance.new("UICorner")
    corner.CornerRadius =
        UDim.new(0, 5)
    corner.Parent = button

    button.MouseButton1Click:
        Connect(callback)

    return button
end

local function GetControlTargetOrNotify()
    local target =
        ResolveToxControlTarget()

    if not target then
        CustomNotify(
            "Player not found",
            Color3.fromRGB(
                255,
                110,
                110
            )
        )

        return nil
    end

    local allowed =
        CanControlTarget(
            Player,
            target
        )

    if not allowed then
        return nil
    end

    return target
end

local function SendTargetControl(
    command,
    argument
)
    local target =
        GetControlTargetOrNotify()

    if not target then
        return
    end

    SendToxControlChatCommand(
        target,
        command,
        argument or ""
    )
end

MakeToxControlButton(
    "RESET",
    10,
    128,
    64,
    function()
        SendTargetControl(
            "reset"
        )
    end
)

MakeToxControlButton(
    "FREEZE",
    78,
    128,
    64,
    function()
        SendTargetControl(
            "freeze"
        )
    end
)

MakeToxControlButton(
    "BRING",
    146,
    128,
    64,
    function()
        SendTargetControl(
            "bring"
        )
    end
)

MakeToxControlButton(
    "GOTO",
    214,
    128,
    64,
    function()
        SendTargetControl(
            "goto"
        )
    end
)

MakeToxControlButton(
    "BHOP",
    282,
    128,
    68,
    function()
        SendTargetControl(
            "bhop"
        )
    end
)

MakeToxControlButton(
    "KICK",
    10,
    166,
    82,
    function()
        SendTargetControl(
            "kick"
        )
    end
)

MakeToxControlButton(
    "REJOIN",
    96,
    166,
    82,
    function()
        SendTargetControl(
            "rejoin"
        )
    end
)

MakeToxControlButton(
    "JUMP",
    182,
    166,
    82,
    function()
        SendTargetControl(
            "jump"
        )
    end
)

MakeToxControlButton(
    "SIT",
    268,
    166,
    82,
    function()
        SendTargetControl(
            "sit"
        )
    end
)

local ToxControlChat =
    Instance.new("TextBox")
ToxControlChat.Size =
    UDim2.new(1, -88, 0, 32)
ToxControlChat.Position =
    UDim2.new(0, 10, 0, 208)
ToxControlChat.BackgroundColor3 =
    Color3.fromRGB(20, 20, 30)
ToxControlChat.BorderSizePixel = 0
ToxControlChat.Text = ""
ToxControlChat.PlaceholderText =
    "Chat text"
ToxControlChat.TextColor3 =
    Color3.fromRGB(255, 255, 255)
ToxControlChat.PlaceholderColor3 =
    Color3.fromRGB(130, 130, 145)
ToxControlChat.Font =
    Enum.Font.Gotham
ToxControlChat.TextSize = 10
ToxControlChat.ClearTextOnFocus = false
ToxControlChat.Parent =
    ToxControlGui

local ToxControlChatCorner =
    Instance.new("UICorner")
ToxControlChatCorner.CornerRadius =
    UDim.new(0, 5)
ToxControlChatCorner.Parent =
    ToxControlChat

MakeToxControlButton(
    "SEND",
    286,
    208,
    64,
    function()
        local message =
            tostring(
                ToxControlChat.Text or ""
            )
            :gsub("[\r\n]+", " ")
            :match("^%s*(.-)%s*$")
            or ""

        if message == "" then
            CustomNotify(
                "Enter chat text",
                Color3.fromRGB(
                    255,
                    180,
                    70
                )
            )

            return
        end

        SendTargetControl(
            "chat",
            message
        )
    end
)

local ToxControlFlingTarget =
    Instance.new("TextBox")
ToxControlFlingTarget.Size =
    UDim2.new(1, -88, 0, 32)
ToxControlFlingTarget.Position =
    UDim2.new(0, 10, 0, 246)
ToxControlFlingTarget.BackgroundColor3 =
    Color3.fromRGB(20, 20, 30)
ToxControlFlingTarget.BorderSizePixel = 0
ToxControlFlingTarget.Text = ""
ToxControlFlingTarget.PlaceholderText =
    "Fling target"
ToxControlFlingTarget.TextColor3 =
    Color3.fromRGB(255, 255, 255)
ToxControlFlingTarget.PlaceholderColor3 =
    Color3.fromRGB(130, 130, 145)
ToxControlFlingTarget.Font =
    Enum.Font.Gotham
ToxControlFlingTarget.TextSize = 10
ToxControlFlingTarget.ClearTextOnFocus = false
ToxControlFlingTarget.Parent =
    ToxControlGui

local ToxControlFlingCorner =
    Instance.new("UICorner")
ToxControlFlingCorner.CornerRadius =
    UDim.new(0, 5)
ToxControlFlingCorner.Parent =
    ToxControlFlingTarget

MakeToxControlButton(
    "FLING",
    286,
    246,
    64,
    function()
        local targetText =
            tostring(
                ToxControlFlingTarget.Text
                or ""
            )
            :gsub("^%s+", "")
            :gsub("%s+$", "")

        if targetText == "" then
            return
        end

        SendTargetControl(
            "fling",
            targetText
        )
    end
)

local ToxControlHint =
    Instance.new("TextLabel")
ToxControlHint.Size =
    UDim2.new(1, -20, 0, 72)
ToxControlHint.Position =
    UDim2.new(0, 10, 0, 290)
ToxControlHint.BackgroundTransparency = 1
ToxControlHint.Text =
    ".c NICK reset / freeze / bring / goto / bhop\n"
    .. ".c NICK kick / rejoin / jump / sit\n"
    .. ".c NICK fling TARGET / chat TEXT"
ToxControlHint.TextColor3 =
    Color3.fromRGB(145, 145, 160)
ToxControlHint.Font =
    Enum.Font.Gotham
ToxControlHint.TextSize = 9
ToxControlHint.TextWrapped = true
ToxControlHint.TextXAlignment =
    Enum.TextXAlignment.Left
ToxControlHint.TextYAlignment =
    Enum.TextYAlignment.Top
ToxControlHint.Parent =
    ToxControlGui

local ToxControlDragging = false
local ToxControlDragStart = nil
local ToxControlStartPos = nil

ToxControlTopBar.InputBegan:
    Connect(function(input)
        if input.UserInputType
        == Enum.UserInputType.MouseButton1
        or input.UserInputType
        == Enum.UserInputType.Touch then
            ToxControlDragging = true
            ToxControlDragStart =
                input.Position
            ToxControlStartPos =
                ToxControlGui.Position
        end
    end)

UserInputService.InputChanged:
    Connect(function(input)
        if not ToxControlDragging
        or not ToxControlDragStart
        or not ToxControlStartPos then
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
            - ToxControlDragStart

        ToxControlGui.Position =
            UDim2.new(
                ToxControlStartPos.X.Scale,
                ToxControlStartPos.X.Offset
                    + delta.X,
                ToxControlStartPos.Y.Scale,
                ToxControlStartPos.Y.Offset
                    + delta.Y
            )
    end)

UserInputService.InputEnded:
    Connect(function(input)
        if input.UserInputType
        == Enum.UserInputType.MouseButton1
        or input.UserInputType
        == Enum.UserInputType.Touch then
            ToxControlDragging = false
        end
    end)

ToxControlClose.MouseButton1Click:
    Connect(function()
        ToxControlGui.Visible = false
    end)

if getgenv().RegisterToxLinkedSubGui then
    getgenv().RegisterToxLinkedSubGui(
        "ToxControl",
        ToxControlGui
    )
end

if getgenv().RegisterToxSubGuiMinimize then
    getgenv().RegisterToxSubGuiMinimize(
        ToxControlGui,
        -70
    )
end

CreateButton("Tox Control", FlingPage, function()
    if not CanUseToxControl(Player) then
        return
    end

    ToxControlGui.Visible =
        not ToxControlGui.Visible
end)

end

InitToxControlGui()

AddConnection(Player.CharacterAdded:Connect(function(character)
    ToxControlFrozen = false

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
end))



getgenv().ToxSystemsCleanup = function()
    SetToxControlBhop(false)

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

    ToxControlFrozen = false
end

API.ControlLoaded = true
end

local controlOk, controlErr =
    pcall(InitToxControl)

if not controlOk then
    CustomNotify(
        "Tox Control failed: "
        .. string.sub(
            tostring(controlErr),
            1,
            90
        ),
        Color3.fromRGB(
            255,
            100,
            100
        ),
        6
    )

    warn(
        "[ToxHub ToxControl Error]: "
        .. tostring(controlErr)
    )
end

getgenv().ToxSystemsLoaded =
    controlOk
