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

local Player = Players.LocalPlayer
local Gui = getgenv().Gui
local FlingPage = getgenv().FlingPage
local MAIN_COLOR = getgenv().MAIN_COLOR
local CustomNotify = getgenv().CustomNotify
local AddConnection = getgenv().AddConnection
local CreateButton = getgenv().CreateButton
local ToxChatGui = getgenv().ToxChatGui
local ToxChatInput = getgenv().ToxChatInput
local ToxChatSendBtn = getgenv().ToxChatSendBtn
local ToxChatStatus = getgenv().ToxChatStatus
local AddToxChatMessage = getgenv().AddToxChatMessage

if not Player
or not Gui
or not FlingPage
or not CustomNotify
or not AddConnection
or not CreateButton then
    return
end

local ToxChatTopic = "toxhub-global-9f4d1c7a8e2b6f305a71"
local ToxChatToken = "toxchat-v1-7cb3e59f1a"
local ToxChatLastID = nil
local ToxChatSeenIDs = {}
local ToxChatSeenNonces = {}
local ToxChatLastSend = 0
local ToxChatSenderState = {}

local RequestFunction = getgenv().ToxRequestFunction

local BlockedChatWords = {
    caralho = true,
    porra = true,
    merda = true,
    puta = true,
    puto = true,
    putaria = true,
    buceta = true,
    boceta = true,
    xereca = true,
    piroca = true,
    punheta = true,
    siririca = true,
    foder = true,
    fode = true,
    foda = true,
    fodase = true,
    fdp = true,
    arrombado = true,
    arrombada = true,
    desgracado = true,
    desgracada = true,
    cuzao = true,
    viado = true,
    viadinho = true,
    bicha = true,
    vagabunda = true,
    vagabundo = true,
    prostituta = true,
    porno = true,
    pornografia = true,
    nude = true,
    nudes = true,
    sexo = true,
    estupro = true,
    estuprador = true,
    estupradora = true,
    fuck = true,
    fucking = true,
    fucker = true,
    motherfucker = true,
    shit = true,
    bullshit = true,
    bitch = true,
    asshole = true,
    dick = true,
    cock = true,
    pussy = true,
    cunt = true,
    whore = true,
    slut = true,
    porn = true,
    pornography = true,
    rape = true,
    rapist = true,
    nigger = true,
    nigga = true,
    faggot = true,
    retard = true,
    retarded = true,
    kys = true
}

local BlockedCompactChatParts = {
    "caralho",
    "buceta",
    "boceta",
    "xereca",
    "piroca",
    "punheta",
    "siririca",
    "arrombado",
    "arrombada",
    "desgracado",
    "desgracada",
    "vagabunda",
    "vagabundo",
    "prostituta",
    "pornografia",
    "estupro",
    "estuprador",
    "estupradora",
    "motherfucker",
    "asshole",
    "fucking",
    "bullshit",
    "pussy",
    "cunt",
    "whore",
    "pornography",
    "rapist",
    "nigger",
    "nigga",
    "faggot",
    "retarded",
    "onlyfans"
}

local BlockedChatPhrases = {
    "kill yourself",
    "go kill yourself",
    "go die",
    "se mata",
    "se matar",
    "vai se matar",
    "vou te matar",
    "vou matar voce",
    "manda nude",
    "manda nudes",
    "send nudes"
}

local function ReplaceChatAccents(text)
    local replacements = {
        ["á"] = "a",
        ["à"] = "a",
        ["â"] = "a",
        ["ã"] = "a",
        ["ä"] = "a",
        ["é"] = "e",
        ["è"] = "e",
        ["ê"] = "e",
        ["ë"] = "e",
        ["í"] = "i",
        ["ì"] = "i",
        ["î"] = "i",
        ["ï"] = "i",
        ["ó"] = "o",
        ["ò"] = "o",
        ["ô"] = "o",
        ["õ"] = "o",
        ["ö"] = "o",
        ["ú"] = "u",
        ["ù"] = "u",
        ["û"] = "u",
        ["ü"] = "u",
        ["ç"] = "c"
    }

    for from, to in pairs(replacements) do
        text = string.gsub(text, from, to)
    end

    return text
end

local function CollapseChatRepeats(text)
    local result = {}
    local previous = ""
    local count = 0

    for i = 1, #text do
        local char = string.sub(text, i, i)

        if char == previous then
            count = count + 1
        else
            previous = char
            count = 1
        end

        if count <= 2 then
            table.insert(result, char)
        end
    end

    return table.concat(result)
end

local function CollapseChatAllRepeats(text)
    local result = {}
    local previous = ""

    for i = 1, #text do
        local char = string.sub(text, i, i)

        if char ~= previous then
            table.insert(result, char)
            previous = char
        end
    end

    return table.concat(result)
end

local function NormalizeChatForFilter(message)
    local text = string.lower(tostring(message or ""))
    text = ReplaceChatAccents(text)
    text = text:gsub("@", "a")
    text = text:gsub("4", "a")
    text = text:gsub("3", "e")
    text = text:gsub("1", "i")
    text = text:gsub("!", "i")
    text = text:gsub("0", "o")
    text = text:gsub("5", "s")
    text = text:gsub("7", "t")
    text = text:gsub("%$", "s")
    text = CollapseChatRepeats(text)

    local spaced = text:gsub("[^a-z0-9]+", " ")
    spaced = spaced:gsub("%s+", " ")
    spaced = spaced:match("^%s*(.-)%s*$") or ""

    local compact = spaced:gsub("[^a-z0-9]", "")

    return text, spaced, compact
end

local function ModerateToxChatMessage(message)
    local raw = tostring(message or "")

    if raw == "" then
        return false, "empty"
    end

    if #raw > 160 then
        return false, "too_long"
    end

    local rawLower = string.lower(raw)

    if rawLower:find("http://", 1, true)
    or rawLower:find("https://", 1, true)
    or rawLower:find("www.", 1, true)
    or rawLower:find("discord.gg", 1, true)
    or rawLower:find("discord.com/invite", 1, true)
    or rawLower:find("t.me/", 1, true)
    or rawLower:find("bit.ly", 1, true)
    or rawLower:find("tinyurl", 1, true) then
        return false, "link"
    end

    if rawLower:match("[%w%._%%+%-]+@[%w%.%-]+%.[%a][%a]+") then
        return false, "contact"
    end

    if rawLower:match("%d+%.%d+%.%d+%.%d+") then
        return false, "ip"
    end

    local normalized, spaced, compact = NormalizeChatForFilter(raw)
    local padded = " " .. spaced .. " "

    for word in spaced:gmatch("[a-z0-9]+") do
        if BlockedChatWords[word] then
            return false, "word"
        end
    end

    for _, phrase in ipairs(BlockedChatPhrases) do
        if padded:find(" " .. phrase .. " ", 1, true) then
            return false, "phrase"
        end
    end

    local collapsedCompact = CollapseChatAllRepeats(compact)

    for _, part in ipairs(BlockedCompactChatParts) do
        if compact:find(part, 1, true)
        or collapsedCompact:find(CollapseChatAllRepeats(part), 1, true) then
            return false, "obfuscated"
        end
    end

    if normalized:match("%f[%a]p+[%W_]*u+[%W_]*t+[%W_]*a+%f[%A]")
    or normalized:match("%f[%a]p+[%W_]*o+[%W_]*r+[%W_]*r+[%W_]*a+%f[%A]")
    or normalized:match("%f[%a]m+[%W_]*e+[%W_]*r+[%W_]*d+[%W_]*a+%f[%A]")
    or normalized:match("%f[%a]f+[%W_]*o+[%W_]*d+[%W_]*a+%f[%A]")
    or normalized:match("%f[%a]f+[%W_]*d+[%W_]*p+%f[%A]")
    or normalized:match("%f[%a]f+[%W_]*u+[%W_]*c+[%W_]*k+%f[%A]")
    or normalized:match("%f[%a]s+[%W_]*h+[%W_]*i+[%W_]*t+%f[%A]") then
        return false, "obfuscated"
    end

    return true, nil
end

local function IsToxChatSpam(userId, message)
    local key = tostring(userId or "0")
    local now = tick()
    local state = ToxChatSenderState[key]

    if not state then
        state = {
            Times = {},
            LastMessage = "",
            LastMessageTime = 0
        }
        ToxChatSenderState[key] = state
    end

    local newTimes = {}

    for _, timeValue in ipairs(state.Times) do
        if now - timeValue <= 10 then
            table.insert(newTimes, timeValue)
        end
    end

    state.Times = newTimes

    local normalizedMessage = string.lower(tostring(message or ""))

    if state.LastMessage == normalizedMessage and now - state.LastMessageTime < 12 then
        return true
    end

    if #state.Times >= 5 then
        return true
    end

    table.insert(state.Times, now)
    state.LastMessage = normalizedMessage
    state.LastMessageTime = now

    return false
end

local function CleanToxChatDisplayName(displayName)
    local name = tostring(displayName or "Unknown")
    name = name:gsub("[\r\n<>]", "")
    name = name:match("^%s*(.-)%s*$") or "Unknown"

    if name == "" then
        name = "Unknown"
    end

    if #name > 40 then
        name = string.sub(name, 1, 40)
    end

    return name
end

local TOX_OWNER_ID = 2245662672
local TOX_ROLE_LEVELS = {
    Member = 1,
    Friend = 2,
    Premium = 3,
    Owner = 4
}

local function GetToxRole(player)
    if not player then
        return "Member", 1
    end

    if tonumber(player.UserId)
    == TOX_OWNER_ID then
        return "Owner", 4
    end

    if player.MembershipType
    == Enum.MembershipType.Premium then
        return "Premium", 3
    end

    local isFriend = false

    pcall(function()
        isFriend =
            player:IsFriendsWith(
                TOX_OWNER_ID
            )
    end)

    if isFriend then
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
        return false,
            "Player not found"
    end

    local actorRole, actorLevel =
        GetToxRole(actor)
    local targetRole, targetLevel =
        GetToxRole(target)

    if target.UserId == TOX_OWNER_ID
    and actor.UserId ~= TOX_OWNER_ID then
        return false,
            "Você não tem Aura para usar nada contra o dono."
    end

    if actorLevel < targetLevel then
        return false,
            "Você não tem Aura para usar isso contra "
            .. targetRole
            .. "."
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
    local allowed, reason =
        CanControlTarget(
            actor,
            Player
        )

    if not allowed then
        if reason then
            CustomNotify(
                reason,
                Color3.fromRGB(
                    255,
                    110,
                    110
                )
            )
        end

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
        if character then
            pcall(function()
                character:BreakJoints()
            end)

            if humanoid then
                humanoid.Health = 0
            end
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

    return false
end

local function HandleToxControlPayload(
    payload
)
    if typeof(payload) ~= "table"
    or payload.token ~= ToxChatToken
    or payload.kind ~= "toxcontrol"
    or tonumber(payload.targetUserId)
        ~= Player.UserId
    or tonumber(payload.placeId)
        ~= game.PlaceId
    or tostring(payload.jobId or "")
        ~= tostring(game.JobId) then
        return false
    end

    local actorUserId =
        tonumber(payload.actorUserId)

    if not actorUserId then
        return true
    end

    local actor =
        Players:GetPlayerByUserId(
            actorUserId
        )

    if not actor then
        return true
    end

    local nonce =
        tostring(
            payload.nonce or ""
        )

    if nonce ~= "" then
        if ToxChatSeenNonces[nonce] then
            return true
        end

        ToxChatSeenNonces[nonce] = true
    end

    ExecuteToxControlCommand(
        actor,
        payload.command,
        payload.argument
    )

    return true
end

local function DecodeToxChatResponse(response)
    if typeof(response) ~= "string" or response == "" then
        return
    end

    for line in response:gmatch("[^\r\n]+") do
        local okOuter, outer = pcall(function()
            return HttpService:JSONDecode(line)
        end)

        if okOuter and typeof(outer) == "table" and outer.event == "message" and outer.id then
            ToxChatLastID = outer.id

            if not ToxChatSeenIDs[outer.id] then
                ToxChatSeenIDs[outer.id] = true

                local okInner, payload = pcall(function()
                    return HttpService:JSONDecode(tostring(outer.message or ""))
                end)

                if okInner
                and typeof(payload) == "table"
                and HandleToxControlPayload(
                    payload
                ) then
                elseif okInner
                and typeof(payload) == "table"
                and payload.token == ToxChatToken
                and typeof(payload.message) == "string"
                and tonumber(payload.userId) then
                    local nonce = tostring(payload.nonce or "")

                    if nonce == "" or not ToxChatSeenNonces[nonce] then
                        if nonce ~= "" then
                            ToxChatSeenNonces[nonce] = true
                        end

                        local displayName = CleanToxChatDisplayName(payload.displayName)
                        local allowed = ModerateToxChatMessage(payload.message)
                        local spam = IsToxChatSpam(payload.userId, payload.message)

                        if not spam then
                            if not allowed then
                                if AddToxChatMessage then
                                    AddToxChatMessage(displayName, "[message blocked]", true)
                                end
                            else
                                if AddToxChatMessage then
                                    AddToxChatMessage(displayName, payload.message, false)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

local function PollToxChat()
    local since = ToxChatLastID and HttpService:UrlEncode(ToxChatLastID) or "5m"
    local url = "https://ntfy.sh/" .. ToxChatTopic .. "/json?poll=1&since=" .. since

    local ok, response = pcall(function()
        return game:HttpGet(url)
    end)

    if ok then
        DecodeToxChatResponse(response)

        if ToxChatStatus and ToxChatStatus.Parent then
            ToxChatStatus.Text = "Global chat • connected"
            ToxChatStatus.TextColor3 = Color3.fromRGB(100, 255, 130)
        end
    else
        if ToxChatStatus and ToxChatStatus.Parent then
            ToxChatStatus.Text = "Global chat • reconnecting..."
            ToxChatStatus.TextColor3 = Color3.fromRGB(255, 180, 70)
        end
    end
end

local function PublishToxChatPayload(payload)
    local body = HttpService:JSONEncode({
        topic = ToxChatTopic,
        title = "ToxChat",
        message = payload
    })

    if RequestFunction then
        local ok, response = pcall(function()
            return RequestFunction({
                Url = "https://ntfy.sh",
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = body
            })
        end)

        if ok and response then
            local statusCode = tonumber(response.StatusCode or response.Status or 0)

            if statusCode == 0 or (statusCode >= 200 and statusCode < 300) then
                return true
            end
        end
    end

    local ok = pcall(function()
        HttpService:PostAsync(
            "https://ntfy.sh",
            body,
            Enum.HttpContentType.ApplicationJson,
            false
        )
    end)

    return ok
end

local function PublishToxControlCommand(
    target,
    command,
    argument
)
    if not target then
        return false
    end

    local allowed, reason =
        CanControlTarget(
            Player,
            target
        )

    if not allowed then
        if reason then
            CustomNotify(
                reason,
                Color3.fromRGB(
                    255,
                    110,
                    110
                )
            )
        end

        return false
    end

    local payload =
        HttpService:JSONEncode({
            token = ToxChatToken,
            version = 1,
            kind = "toxcontrol",
            nonce =
                HttpService:
                    GenerateGUID(false),
            actorUserId =
                Player.UserId,
            actorName =
                Player.Name,
            targetUserId =
                target.UserId,
            command =
                tostring(command or ""),
            argument =
                tostring(argument or ""),
            placeId =
                game.PlaceId,
            jobId =
                game.JobId,
            sentAt =
                os.time()
        })

    return PublishToxChatPayload(
        payload
    )
end

local function SendToxChatMessage()
    if not ToxChatInput then
        return
    end

    if tick() - ToxChatLastSend < 1.2 then
        CustomNotify("Wait a moment before sending again", Color3.fromRGB(255, 180, 70))
        return
    end

    local message = tostring(ToxChatInput.Text or "")
    message = message:gsub("[\r\n]+", " ")
    message = message:match("^%s*(.-)%s*$") or ""

    if #message > 160 then
        message = string.sub(message, 1, 160)
    end

    local allowed = ModerateToxChatMessage(message)

    if not allowed then
        CustomNotify("Message blocked by Tox Chat filter", Color3.fromRGB(255, 100, 100))
        return
    end

    if IsToxChatSpam(Player.UserId, message) then
        CustomNotify("Message blocked as spam", Color3.fromRGB(255, 180, 70))
        return
    end

    ToxChatLastSend = tick()

    local nonce = HttpService:GenerateGUID(false)
    local payload = HttpService:JSONEncode({
        token = ToxChatToken,
        version = 1,
        nonce = nonce,
        displayName = Player.DisplayName,
        username = Player.Name,
        userId = Player.UserId,
        message = message,
        placeId = game.PlaceId,
        gameId = game.GameId,
        sentAt = os.time()
    })

    ToxChatSeenNonces[nonce] = true
    ToxChatInput.Text = ""

    if AddToxChatMessage then
        AddToxChatMessage(Player.DisplayName, message, false)
    end

    task.spawn(function()
        local success = PublishToxChatPayload(payload)

        if not success then
            CustomNotify("Tox Chat connection failed", Color3.fromRGB(255, 100, 100))
        end
    end)
end

if ToxChatSendBtn then
    ToxChatSendBtn.MouseButton1Click:Connect(SendToxChatMessage)
end

if ToxChatInput then
    ToxChatInput.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            SendToxChatMessage()
        end
    end)
end

task.spawn(function()
    while not getgenv().Destroyed do
        PollToxChat()
        task.wait(1)
    end
end)

(function()
local ToxControlGui =
    Instance.new("Frame")
ToxControlGui.Name =
    "ToxControlFrame"
ToxControlGui.Size =
    UDim2.new(0, 360, 0, 300)
ToxControlGui.Position =
    UDim2.new(0.5, -180, 0.5, -150)
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

    local allowed, reason =
        CanControlTarget(
            Player,
            target
        )

    if not allowed then
        CustomNotify(
            reason
            or "Você não tem Aura.",
            Color3.fromRGB(
                255,
                110,
                110
            )
        )

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

    task.spawn(function()
        local success =
            PublishToxControlCommand(
                target,
                command,
                argument or ""
            )

        if not success then
            CustomNotify(
                "Tox Control connection failed",
                Color3.fromRGB(
                    255,
                    110,
                    110
                )
            )
        end
    end)
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
        local target =
            GetControlTargetOrNotify()

        if not target
        or not target.Character then
            return
        end

        local targetRoot =
            target.Character:
                FindFirstChild(
                    "HumanoidRootPart"
                )
        local root =
            Player.Character
            and Player.Character:
                FindFirstChild(
                    "HumanoidRootPart"
                )

        if root and targetRoot then
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
        end
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

local ToxControlChat =
    Instance.new("TextBox")
ToxControlChat.Size =
    UDim2.new(1, -88, 0, 32)
ToxControlChat.Position =
    UDim2.new(0, 10, 0, 170)
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
    170,
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

local ToxControlHint =
    Instance.new("TextLabel")
ToxControlHint.Size =
    UDim2.new(1, -20, 0, 72)
ToxControlHint.Position =
    UDim2.new(0, 10, 0, 214)
ToxControlHint.BackgroundTransparency = 1
ToxControlHint.Text =
    "Member < Friend < Premium < Owner\n"
    .. "Higher roles are protected from lower roles.\n"
    .. "Freeze and Bhop toggle when used again."
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
        CustomNotify(
            "Você não tem Aura para usar Tox Control.",
            Color3.fromRGB(
                255,
                110,
                110
            )
        )

        return
    end

    ToxControlGui.Visible =
        not ToxControlGui.Visible
end)

end)()


CreateButton("Tox Chat", FlingPage, function()
    if ToxChatGui then
        ToxChatGui.Visible =
            not ToxChatGui.Visible
    end
end)

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

getgenv().ToxSystemsLoaded = true
