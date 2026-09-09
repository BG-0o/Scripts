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

local ToxChatTopic = "toxhub-global-9f4d1c7a8e2b6f305a71"
local ToxChatToken = "toxchat-v1-7cb3e59f1a"
local ToxChatLastID = nil
local ToxChatSeenIDs = {}
local ToxChatSeenNonces = {}
local ToxChatLastSend = 0
local ToxChatSenderState = {}

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


local function DecodeToxChatResponse(response)
    if typeof(response) ~= "string"
    or response == "" then
        return
    end

    for line in response:gmatch(
        "[^\r\n]+"
    ) do
        local okOuter, outer =
            pcall(function()
                return HttpService:
                    JSONDecode(line)
            end)

        if okOuter
        and typeof(outer) == "table"
        and outer.event == "message"
        and outer.id then
            ToxChatLastID = outer.id

            if not ToxChatSeenIDs[
                outer.id
            ] then
                ToxChatSeenIDs[
                    outer.id
                ] = true

                local okInner, payload =
                    pcall(function()
                        return HttpService:
                            JSONDecode(
                                tostring(
                                    outer.message
                                    or ""
                                )
                            )
                    end)

                if okInner
                and typeof(payload)
                    == "table"
                and payload.token
                    == ToxChatToken
                and typeof(
                    payload.message
                ) == "string"
                and tonumber(
                    payload.userId
                ) then
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

                        local displayName =
                            CleanToxChatDisplayName(
                                payload.displayName
                            )

                        local allowed =
                            ModerateToxChatMessage(
                                payload.message
                            )

                        local spam =
                            IsToxChatSpam(
                                payload.userId,
                                payload.message
                            )

                        if not spam then
                            if not allowed then
                                if AddToxChatMessage then
                                    AddToxChatMessage(
                                        displayName,
                                        "[message blocked]",
                                        true
                                    )
                                end
                            elseif AddToxChatMessage then
                                AddToxChatMessage(
                                    displayName,
                                    payload.message,
                                    false
                                )
                            end
                        end
                    end
                end
            end
        end
    end
end

local function GetToxChatResponse(
    url
)
    if RequestFunction then
        local ok, response =
            pcall(function()
                return RequestFunction({
                    Url = url,
                    Method = "GET",
                    Headers = {
                        ["Accept"] =
                            "application/x-ndjson",
                        ["Cache-Control"] =
                            "no-cache"
                    }
                })
            end)

        if ok
        and response then
            local statusCode =
                tonumber(
                    response.StatusCode
                    or response.Status
                    or 0
                ) or 0

            local body =
                response.Body
                or response.body

            local success =
                response.Success

            if success == nil then
                success =
                    response.success
            end

            if typeof(body)
                == "string"
            and (
                (
                    statusCode >= 200
                    and statusCode < 300
                )
                or success == true
            ) then
                return body
            end
        end
    end

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
        return response
    end

    return nil
end

local function PollToxChat()
    local since =
        ToxChatLastID
        and HttpService:
            UrlEncode(
                ToxChatLastID
            )
        or "30s"

    local url =
        "https://ntfy.sh/"
        .. ToxChatTopic
        .. "/json?poll=1&since="
        .. since
        .. "&_="
        .. tostring(
            math.floor(
                os.clock() * 1000
            )
        )

    local response =
        GetToxChatResponse(
            url
        )

    if response then
        DecodeToxChatResponse(
            response
        )

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

        return true
    end

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

    return false
end

local function PublishToxChatPayload(
    payload
)
    payload =
        tostring(payload or "")

    if payload == "" then
        return false
    end

    if RequestFunction then
        local ok, response =
            pcall(function()
                return RequestFunction({
                    Url =
                        "https://ntfy.sh/"
                        .. ToxChatTopic,
                    Method = "POST",
                    Headers = {
                        ["Content-Type"] =
                            "text/plain; charset=utf-8",
                        ["Cache"] =
                            "yes"
                    },
                    Body = payload
                })
            end)

        if ok
        and response then
            local statusCode =
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
                statusCode >= 200
                and statusCode < 300
            )
            or success == true then
                return true
            end
        end
    end

    local body =
        HttpService:
            JSONEncode({
                topic =
                    ToxChatTopic,
                title =
                    "ToxChat",
                message =
                    payload
            })

    local ok =
        pcall(function()
            HttpService:
                PostAsync(
                    "https://ntfy.sh",
                    body,
                    Enum.HttpContentType.ApplicationJson,
                    false
                )
        end)

    return ok
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


CreateButton("Tox Chat", FlingPage, function()
    if ToxChatGui then
        ToxChatGui.Visible =
            not ToxChatGui.Visible
    end
end)

getgenv().ToxChatLoaded = true
