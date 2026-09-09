if getgenv().ToxChatLoaded then
    return
end

if not getgenv().ToxUniversalLoaded then
    local notify =
        getgenv().CustomNotify

    if notify then
        notify(
            "Universal.lua must load before ToxChat.lua",
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
local HttpService =
    game:GetService("HttpService")

local Player =
    Players.LocalPlayer
local CustomNotify =
    getgenv().CustomNotify
local CreateButton =
    getgenv().CreateButton
local FlingPage =
    getgenv().FlingPage
local RequestFunction =
    getgenv().ToxRequestFunction

if not Player
or not CustomNotify
or not CreateButton
or not FlingPage then
    return
end

local ToxChatGui = getgenv().ToxChatGui
local ToxChatInput = getgenv().ToxChatInput
local ToxChatSendBtn = getgenv().ToxChatSendBtn
local ToxChatStatus = getgenv().ToxChatStatus
local AddToxChatMessage = getgenv().AddToxChatMessage

local ToxChatRelayHost =
    "https://tox-control-relay.1kobg-0o.workers.dev"

local ToxChatLastID = 0
local ToxChatSeenIDs = {}
local ToxChatSeenNonces = {}
local ToxChatLastSend = 0
local ToxChatSenderState = {}
local ToxChatConnectedNotified = false
local ToxChatFailureCount = 0
local ToxChatClearVersion = nil
local TOX_OWNER_ID = 2245662672
local ClearToxChatMessages =
    getgenv().ClearToxChatMessages

local BlockedChatWords = {
    estupro = true,
    estrupo = true,
    estuprador = true,
    estupradora = true,
    rape = true,
    rapist = true,
    pedofilia = true,
    pedofilo = true,
    pedofila = true,
    zoofilia = true
}

local BlockedCompactChatParts = {
    "estupro",
    "estrupo",
    "estuprador",
    "estupradora",
    "rape",
    "rapist",
    "pedofilia",
    "pedofilo",
    "pedofila",
    "zoofilia"
}

local BlockedChatPhrases = {
    "kill yourself",
    "go kill yourself",
    "vai se matar",
    "se mata"
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
    local raw =
        tostring(
            message or ""
        )

    if raw == "" then
        return false, "empty"
    end

    if #raw > 160 then
        return false, "too_long"
    end

    local normalized,
        spaced,
        compact =
        NormalizeChatForFilter(
            raw
        )

    local padded =
        " "
        .. spaced
        .. " "

    for word in spaced:gmatch(
        "[a-z0-9]+"
    ) do
        if BlockedChatWords[
            word
        ] then
            return false, "word"
        end
    end

    for _, phrase in ipairs(
        BlockedChatPhrases
    ) do
        if padded:find(
            " "
            .. phrase
            .. " ",
            1,
            true
        ) then
            return false, "phrase"
        end
    end

    local collapsedCompact =
        CollapseChatAllRepeats(
            compact
        )

    for _, part in ipairs(
        BlockedCompactChatParts
    ) do
        local collapsedPart =
            CollapseChatAllRepeats(
                part
            )

        if compact:find(
            part,
            1,
            true
        )
        or collapsedCompact:find(
            collapsedPart,
            1,
            true
        ) then
            return false, "obfuscated"
        end
    end

    if normalized:match(
        "%f[%a]e+[%W_]*s+[%W_]*t+[%W_]*u+[%W_]*p+[%W_]*r+[%W_]*o+%f[%A]"
    )
    or normalized:match(
        "%f[%a]e+[%W_]*s+[%W_]*t+[%W_]*r+[%W_]*u+[%W_]*p+[%W_]*o+%f[%A]"
    )
    or normalized:match(
        "%f[%a]r+[%W_]*a+[%W_]*p+[%W_]*e+%f[%A]"
    ) then
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


local function GetToxChatRole()
    local roleGetter =
        getgenv().GetToxRole

    if type(roleGetter)
        == "function" then
        local ok, role =
            pcall(
                roleGetter,
                Player
            )

        if ok
        and typeof(role)
            == "string"
        and role ~= "" then
            return role
        end
    end

    local role =
        tostring(
            getgenv().ToxRole
            or "Member"
        )

    if role == "" then
        role = "Member"
    end

    return role
end

local function GetToxChatDisplayName()
    return
        CleanToxChatDisplayName(
            Player.DisplayName
        )
        .. " • "
        .. GetToxChatRole()
end


local function ReadRelayResponse(
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

local function RelayRequest(
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
                    ToxChatRelayHost
                    .. path,
                Method = method,
                Headers = headers,
                Body = body
            })
        end)

    if not ok then
        return nil, false
    end

    return ReadRelayResponse(
        response
    )
end

local function DecodeToxChatResponse(
    response
)
    if typeof(response)
        ~= "string"
    or response == "" then
        return false
    end

    local ok, decoded =
        pcall(function()
            return HttpService:
                JSONDecode(response)
        end)

    if not ok
    or typeof(decoded)
        ~= "table"
    or decoded.ok ~= true
    or typeof(decoded.messages)
        ~= "table" then
        return false
    end

    local initialSync =
        ToxChatClearVersion
        == nil

    local clearVersion =
        tonumber(
            decoded.clearVersion
        ) or 0

    if ToxChatClearVersion
        == nil then
        ToxChatClearVersion =
            clearVersion
    elseif clearVersion
        ~= ToxChatClearVersion then
        ToxChatClearVersion =
            clearVersion

        if ClearToxChatMessages then
            ClearToxChatMessages()
        end

        CustomNotify(
            "Tox Chat cleared by Owner",
            Color3.fromRGB(
                120,
                180,
                255
            ),
            4
        )
    end

    for _, payload in ipairs(
        decoded.messages
    ) do
        local id =
            tonumber(
                payload.id
            ) or 0

        if id > ToxChatLastID then
            ToxChatLastID = id
        end

        if id > 0
        and not ToxChatSeenIDs[id] then
            ToxChatSeenIDs[id] = true

            local nonce =
                tostring(
                    payload.nonce
                    or ""
                )

            if nonce == ""
            or not ToxChatSeenNonces[
                nonce
            ] then
                if nonce ~= "" then
                    ToxChatSeenNonces[
                        nonce
                    ] = true
                end

                local userId =
                    tonumber(
                        payload.userId
                    )

                local message =
                    tostring(
                        payload.message
                        or ""
                    )

                if userId
                and message ~= "" then
                    local displayName =
                        CleanToxChatDisplayName(
                            payload.displayName
                            or payload.username
                        )

                    local allowed =
                        ModerateToxChatMessage(
                            message
                        )

                    local spam =
                        IsToxChatSpam(
                            userId,
                            message
                        )

                    if not spam then
                        if not allowed then
                            if AddToxChatMessage then
                                AddToxChatMessage(
                                    displayName,
                                    "[message blocked]",
                                    true,
                                    not initialSync
                                )
                            end
                        elseif AddToxChatMessage then
                            AddToxChatMessage(
                                displayName,
                                message,
                                false,
                                not initialSync
                            )
                        end
                    end
                end
            end
        end
    end

    return true
end

local function PollToxChat()
    local response, ok =
        RelayRequest(
            "GET",
            "/chat/poll?after="
            .. tostring(
                ToxChatLastID
            )
            .. "&limit=50&_="
            .. tostring(
                math.floor(
                    os.clock() * 1000
                )
            )
        )

    if ok
    and DecodeToxChatResponse(
        response
    ) then
        ToxChatFailureCount = 0

        if ToxChatStatus
        and ToxChatStatus.Parent then
            ToxChatStatus.Text =
                "Global chat • connected"

            ToxChatStatus.TextColor3 =
                Color3.fromRGB(
                    100,
                    255,
                    130
                )
        end

        if not ToxChatConnectedNotified then
            ToxChatConnectedNotified =
                true

            CustomNotify(
                "Tox Chat connected",
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

    ToxChatFailureCount += 1

    if ToxChatStatus
    and ToxChatStatus.Parent then
        ToxChatStatus.Text =
            "Global chat • reconnecting..."

        ToxChatStatus.TextColor3 =
            Color3.fromRGB(
                255,
                180,
                70
            )
    end

    if ToxChatFailureCount == 3 then
        CustomNotify(
            "Tox Chat relay unavailable",
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

local function ClearToxChatForEveryone()
    if Player.UserId
        ~= TOX_OWNER_ID then
        CustomNotify(
            "/clear is Owner only",
            Color3.fromRGB(
                255,
                120,
                120
            ),
            4
        )

        return false
    end

    local body =
        HttpService:
            JSONEncode({
                userId =
                    Player.UserId
            })

    local response, ok =
        RelayRequest(
            "POST",
            "/chat/clear",
            body
        )

    if not ok
    or typeof(response)
        ~= "string" then
        return false
    end

    local decodeOk, decoded =
        pcall(function()
            return HttpService:
                JSONDecode(response)
        end)

    if not decodeOk
    or typeof(decoded)
        ~= "table"
    or decoded.ok ~= true then
        return false
    end

    ToxChatClearVersion =
        tonumber(
            decoded.clearVersion
        )
        or ToxChatClearVersion
        or 0

    if ClearToxChatMessages then
        ClearToxChatMessages()
    end

    return true
end

local function PublishToxChatPayload(
    payload
)
    local body =
        HttpService:
            JSONEncode(payload)

    local response, ok =
        RelayRequest(
            "POST",
            "/chat/send",
            body
        )

    if not ok
    or typeof(response)
        ~= "string" then
        return false
    end

    local decodeOk, decoded =
        pcall(function()
            return HttpService:
                JSONDecode(response)
        end)

    return decodeOk
        and typeof(decoded)
            == "table"
        and decoded.ok == true
end

local function SendToxChatMessage()
    if not ToxChatInput then
        return
    end

    if tick() - ToxChatLastSend
        < 1.2 then
        CustomNotify(
            "Wait a moment before sending again",
            Color3.fromRGB(
                255,
                180,
                70
            )
        )

        return
    end

    local message =
        tostring(
            ToxChatInput.Text or ""
        )

    message =
        message:
            gsub(
                "[\r\n]+",
                " "
            ):
            match(
                "^%s*(.-)%s*$"
            )
        or ""

    if message == "" then
        return
    end

    if string.lower(message)
        == "/clear" then
        ToxChatLastSend = tick()

        task.spawn(function()
            local success =
                ClearToxChatForEveryone()

            if success then
                if ToxChatInput then
                    ToxChatInput.Text = ""
                end

                CustomNotify(
                    "Tox Chat cleared for everyone",
                    Color3.fromRGB(
                        120,
                        180,
                        255
                    ),
                    4
                )
            else
                CustomNotify(
                    "Tox Chat clear failed",
                    Color3.fromRGB(
                        255,
                        100,
                        100
                    ),
                    4
                )
            end
        end)

        return
    end

    if #message > 160 then
        message =
            string.sub(
                message,
                1,
                160
            )
    end

    if not ModerateToxChatMessage(
        message
    ) then
        CustomNotify(
            "Message blocked by Tox Chat filter",
            Color3.fromRGB(
                255,
                100,
                100
            )
        )

        return
    end

    if IsToxChatSpam(
        Player.UserId,
        message
    ) then
        CustomNotify(
            "Message blocked as spam",
            Color3.fromRGB(
                255,
                180,
                70
            )
        )

        return
    end

    ToxChatLastSend = tick()

    local nonce =
        HttpService:
            GenerateGUID(false)

    local payload = {
        nonce = nonce,
        displayName =
            GetToxChatDisplayName(),
        username =
            Player.Name,
        userId =
            Player.UserId,
        message = message,
        placeId =
            game.PlaceId,
        gameId =
            game.GameId,
        sentAt =
            os.time()
    }

    task.spawn(function()
        local success =
            PublishToxChatPayload(
                payload
            )

        if success then
            ToxChatSeenNonces[
                nonce
            ] = true

            if ToxChatInput
            and ToxChatInput.Text
                == message then
                ToxChatInput.Text = ""
            end

            if AddToxChatMessage then
                AddToxChatMessage(
                    GetToxChatDisplayName(),
                    message,
                    false,
                    true
                )
            end

            ToxChatFailureCount = 0
        else
            CustomNotify(
                "Tox Chat send failed",
                Color3.fromRGB(
                    255,
                    100,
                    100
                ),
                4
            )
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


CreateButton("Tox Chat", FlingPage, function()
    if ToxChatGui then
        ToxChatGui.Visible =
            not ToxChatGui.Visible
    end
end)

getgenv().ToxChatLoaded = true
