if game.PlaceId ~= 4522347649 then
    return
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")
local VirtualInputManager = game:GetService("VirtualInputManager")

local Player = Players.LocalPlayer
local Settings = getgenv().Settings
local GamePage = getgenv().GamePage
local AutoSaveConfiguration = getgenv().AutoSaveConfiguration
local MAIN_COLOR = getgenv().MAIN_COLOR or Color3.fromRGB(9, 0, 136)

if not Settings or not GamePage then
    return
end

Settings.ADMINPrefix = tostring(Settings.ADMINPrefix or ".")
Settings.ADMINKillTarget = tostring(Settings.ADMINKillTarget or "")
Settings.ADMINKillAll = Settings.ADMINKillAll == true
Settings.ADMINRocketTarget = tostring(Settings.ADMINRocketTarget or "")
Settings.ADMINRocketAll = Settings.ADMINRocketAll == true
Settings.ADMINKickTarget = tostring(Settings.ADMINKickTarget or "")
Settings.ADMINCommandMode = tostring(Settings.ADMINCommandMode or "CMD")
Settings.ADMINCustomCommand = tostring(Settings.ADMINCustomCommand or "")
Settings.ADMINCustomTarget = tostring(Settings.ADMINCustomTarget or "")
Settings.ADMINCustomAll = Settings.ADMINCustomAll == true
Settings.ADMINUncmdbarTarget = tostring(Settings.ADMINUncmdbarTarget or "")
Settings.ADMINUncmdbarAll = Settings.ADMINUncmdbarAll == true
Settings.ADMINMuteTarget = tostring(Settings.ADMINMuteTarget or "")
Settings.ADMINMuteAll = Settings.ADMINMuteAll == true
Settings.ADMINPoopTarget = tostring(Settings.ADMINPoopTarget or "")
Settings.ADMINPoopAll = Settings.ADMINPoopAll == true
Settings.ADMINPunishTarget = tostring(Settings.ADMINPunishTarget or "")
Settings.ADMINPunishAll = Settings.ADMINPunishAll == true
Settings.ADMINSuperFlingTarget = tostring(Settings.ADMINSuperFlingTarget or "")
Settings.ADMINSuperFlingAll = Settings.ADMINSuperFlingAll == true
Settings.ADMINKickAll = Settings.ADMINKickAll == true

if Settings.ADMINCommandMode ~= "CHAT"
and Settings.ADMINCommandMode ~= "CMD" then
    Settings.ADMINCommandMode = "CMD"
end

local function Save()
    if AutoSaveConfiguration then
        AutoSaveConfiguration()
    end
end

local function Trim(value)
    return tostring(value or "")
        :gsub("^%s+", "")
        :gsub("%s+$", "")
end

local function MakeCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius =
        UDim.new(0, radius or 4)
    corner.Parent = parent
end

local function GetGuiRoots()
    local roots = {}
    local playerGui =
        Player:FindFirstChildOfClass("PlayerGui")

    if playerGui then
        table.insert(roots, playerGui)
    end

    table.insert(roots, CoreGui)
    return roots
end

local function GetObjectText(obj)
    local pieces = {
        tostring(obj.Name or "")
    }

    if obj:IsA("TextBox")
    or obj:IsA("TextLabel")
    or obj:IsA("TextButton") then
        table.insert(
            pieces,
            tostring(obj.Text or "")
        )
    end

    if obj:IsA("TextBox") then
        table.insert(
            pieces,
            tostring(obj.PlaceholderText or "")
        )
    end

    return string.lower(
        table.concat(pieces, " ")
    )
end

local function GetAncestorText(obj, depth)
    local result = {}
    local current = obj

    for _ = 1, depth or 7 do
        if not current then
            break
        end

        table.insert(
            result,
            GetObjectText(current)
        )

        current = current.Parent
    end

    return table.concat(
        result,
        " "
    )
end

local function FindExecuteNear(box)
    local current = box.Parent

    for _ = 1, 7 do
        if not current then
            break
        end

        for _, obj in ipairs(
            current:GetDescendants()
        ) do
            if obj:IsA("TextButton")
            or obj:IsA("ImageButton") then
                local blob =
                    GetObjectText(obj)

                if string.find(
                    blob,
                    "execute",
                    1,
                    true
                ) then
                    return obj
                end
            end
        end

        current = current.Parent
    end

    return nil
end

local function FindCmdBar()
    local candidates = {}

    for _, root in ipairs(GetGuiRoots()) do
        for _, obj in ipairs(
            root:GetDescendants()
        ) do
            if obj:IsA("TextBox") then
                local selfText =
                    GetObjectText(obj)
                local ancestorText =
                    GetAncestorText(
                        obj,
                        8
                    )

                local score = 0

                if string.find(
                    ancestorText,
                    "cmdbar2",
                    1,
                    true
                ) then
                    score = score + 500
                elseif string.find(
                    ancestorText,
                    "cmdbar1",
                    1,
                    true
                ) then
                    score = score + 350
                elseif string.find(
                    ancestorText,
                    "cmdbar",
                    1,
                    true
                ) then
                    score = score + 200
                end

                if string.find(
                    selfText,
                    "enter command",
                    1,
                    true
                ) then
                    score = score + 300
                end

                if score > 0 then
                    local execute =
                        FindExecuteNear(obj)

                    if execute then
                        table.insert(
                            candidates,
                            {
                                Box = obj,
                                Execute = execute,
                                Score = score
                            }
                        )
                    end
                end
            end
        end
    end

    table.sort(
        candidates,
        function(a, b)
            return a.Score > b.Score
        end
    )

    return candidates[1]
end

local function FireConnections(
    signal,
    ...
)
    if not getconnections then
        return false
    end

    local ok, connections =
        pcall(function()
            return getconnections(signal)
        end)

    if not ok
    or typeof(connections) ~= "table" then
        return false
    end

    local fired = false
    local args = {...}

    for _, connection in ipairs(
        connections
    ) do
        local fn = connection.Function

        if typeof(fn) == "function" then
            local callOk = pcall(
                fn,
                table.unpack(args)
            )

            if callOk then
                fired = true
            end
        end
    end

    return fired
end

local function TriggerExecute(button)
    if not button
    or not button.Parent then
        return false
    end

    if firesignal then
        local ok = pcall(function()
            firesignal(
                button.MouseButton1Down
            )
        end)

        if ok then
            return true
        end

        ok = pcall(function()
            firesignal(
                button.MouseButton1Click
            )
        end)

        if ok then
            return true
        end

        ok = pcall(function()
            firesignal(
                button.Activated
            )
        end)

        if ok then
            return true
        end
    end

    if FireConnections(
        button.MouseButton1Down
    ) then
        return true
    end

    if FireConnections(
        button.MouseButton1Click
    ) then
        return true
    end

    if FireConnections(
        button.Activated
    ) then
        return true
    end

    return false
end

local CachedMain = nil
local CachedRequest = nil
local CachedRetrieve = nil

local function IsRemoteFunction(obj)
    return typeof(obj) == "Instance"
        and obj:IsA("RemoteFunction")
end

local function ResolveMain()
    if typeof(CachedMain) == "table" then
        return CachedMain
    end

    local possibilities = {}

    pcall(function()
        table.insert(
            possibilities,
            _G.HDAdminMain
        )
    end)

    pcall(function()
        table.insert(
            possibilities,
            getgenv().HDAdminMain
        )
    end)

    pcall(function()
        table.insert(
            possibilities,
            shared.HDAdminMain
        )
    end)

    for _, candidate in ipairs(
        possibilities
    ) do
        if typeof(candidate) == "table"
        and typeof(candidate.signals) == "table"
        and IsRemoteFunction(
            candidate.signals.RequestCommand
        ) then
            CachedMain = candidate
            return candidate
        end
    end

    if getgc then
        local ok, objects = pcall(
            getgc,
            true
        )

        if ok
        and typeof(objects) == "table" then
            for _, candidate in ipairs(
                objects
            ) do
                if typeof(candidate) == "table" then
                    local signals =
                        rawget(
                            candidate,
                            "signals"
                        )

                    if typeof(signals) == "table"
                    and IsRemoteFunction(
                        rawget(
                            signals,
                            "RequestCommand"
                        )
                    ) then
                        CachedMain = candidate
                        return candidate
                    end
                end
            end
        end
    end

    return nil
end

local function FindRemoteByName(name)
    for _, obj in ipairs(
        ReplicatedStorage:GetDescendants()
    ) do
        if obj:IsA("RemoteFunction")
        and string.lower(obj.Name)
            == string.lower(name) then
            return obj
        end
    end

    return nil
end

local function ResolveRequest()
    if IsRemoteFunction(CachedRequest)
    and CachedRequest.Parent then
        return CachedRequest
    end

    local main = ResolveMain()

    if main
    and typeof(main.signals) == "table"
    and IsRemoteFunction(
        main.signals.RequestCommand
    ) then
        CachedRequest =
            main.signals.RequestCommand
        return CachedRequest
    end

    local client =
        ReplicatedStorage:
            FindFirstChild("HDAdminClient")

    local signals =
        client
        and client:
            FindFirstChild("Signals")

    local direct =
        signals
        and signals:
            FindFirstChild("RequestCommand")

    if IsRemoteFunction(direct) then
        CachedRequest = direct
        return direct
    end

    CachedRequest =
        FindRemoteByName("RequestCommand")

    return CachedRequest
end

local function ResolveRetrieve()
    if IsRemoteFunction(CachedRetrieve)
    and CachedRetrieve.Parent then
        return CachedRetrieve
    end

    local main = ResolveMain()

    if main
    and typeof(main.signals) == "table"
    and IsRemoteFunction(
        main.signals.RetrieveData
    ) then
        CachedRetrieve =
            main.signals.RetrieveData
        return CachedRetrieve
    end

    CachedRetrieve =
        FindRemoteByName("RetrieveData")

    return CachedRetrieve
end

local function GetDirectPrefix()
    local main = ResolveMain()

    if main
    and typeof(main.pdata) == "table"
    and typeof(main.pdata.Prefix) == "string"
    and main.pdata.Prefix ~= "" then
        return main.pdata.Prefix
    end

    local retrieve =
        ResolveRetrieve()

    if retrieve then
        local ok, data = pcall(function()
            return retrieve:InvokeServer()
        end)

        if ok
        and typeof(data) == "table"
        and typeof(data.pdata) == "table"
        and typeof(
            data.pdata.Prefix
        ) == "string"
        and data.pdata.Prefix ~= "" then
            return data.pdata.Prefix
        end
    end

    return tostring(
        Settings.ADMINPrefix or "."
    )
end

local function BuildRawCommand(
    command,
    target
)
    command = Trim(command)
    target = Trim(target)

    if command == "" then
        return nil
    end

    local configuredPrefix =
        tostring(
            Settings.ADMINPrefix or "."
        )

    if configuredPrefix ~= ""
    and string.sub(
        command,
        1,
        #configuredPrefix
    ) == configuredPrefix then
        command = Trim(
            string.sub(
                command,
                #configuredPrefix + 1
            )
        )
    end

    if target ~= "" then
        return command
            .. " "
            .. target
    end

    return command
end

local function SendChatCommand(raw)
    local prefix =
        tostring(
            Settings.ADMINPrefix or "."
        )

    local message = raw

    if prefix ~= ""
    and string.sub(
        message,
        1,
        #prefix
    ) ~= prefix then
        message = prefix .. message
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

local function ExecuteThroughCmdBar(raw)
    local bar = FindCmdBar()

    if not bar
    or not bar.Box
    or not bar.Execute then
        return false
    end

    local box = bar.Box
    local previous = box.Text

    box.Text = raw

    task.wait()

    local fired =
        TriggerExecute(
            bar.Execute
        )

    task.delay(0.08, function()
        if box
        and box.Parent then
            box.Text = previous
        end
    end)

    return fired
end

local function ExecuteDirect(raw)
    local request =
        ResolveRequest()

    if not request then
        CachedMain = nil
        CachedRequest = nil
        CachedRetrieve = nil
        request = ResolveRequest()
    end

    if not request then
        return false
    end

    local prefix =
        GetDirectPrefix()

    local message = raw

    if prefix ~= ""
    and string.sub(
        message,
        1,
        #prefix
    ) ~= prefix then
        message = prefix .. message
    end

    local ok = pcall(function()
        request:InvokeServer(message)
    end)

    return ok
end

local function RunHDAdminCommand(
    command,
    target
)
    local raw =
        BuildRawCommand(
            command,
            target
        )

    if not raw then
        return false
    end

    if Settings.ADMINCommandMode
    == "CHAT" then
        return SendChatCommand(raw)
    end

    if ExecuteThroughCmdBar(raw) then
        return true
    end

    return ExecuteDirect(raw)
end

local LoopGeneration = {}

local function LoopKeys(id)
    return
        "ADMINLoop" .. id,
        "ADMINLoopSeconds" .. id
end

local function InitializeLoopState(id)
    local stateKey, secondsKey =
        LoopKeys(id)

    Settings[stateKey] =
        Settings[stateKey] == true

    Settings[secondsKey] =
        math.clamp(
            tonumber(
                Settings[secondsKey]
            ) or 1,
            0.1,
            3600
        )

    return stateKey, secondsKey
end

local function StopLoop(id)
    LoopGeneration[id] =
        (LoopGeneration[id] or 0) + 1
end

local function StartLoop(id, callback)
    local stateKey, secondsKey =
        InitializeLoopState(id)

    StopLoop(id)

    if not Settings[stateKey] then
        return
    end

    local generation =
        LoopGeneration[id]

    task.spawn(function()
        while not getgenv().Destroyed
        and Settings[stateKey]
        and LoopGeneration[id]
            == generation do
            pcall(callback)

            local seconds =
                math.clamp(
                    tonumber(
                        Settings[secondsKey]
                    ) or 1,
                    0.1,
                    3600
                )

            task.wait(seconds)
        end
    end)
end

local function CreateLoopControls(
    parent,
    id,
    callback
)
    local stateKey, secondsKey =
        InitializeLoopState(id)

    local loopButton =
        Instance.new("TextButton")

    loopButton.Size =
        UDim2.new(0, 46, 0, 20)
    loopButton.Position =
        UDim2.new(0, 86, 1, -23)
    loopButton.BorderSizePixel = 0
    loopButton.Text = "LOOP"
    loopButton.TextColor3 =
        Color3.fromRGB(
            255,
            255,
            255
        )
    loopButton.TextSize = 9
    loopButton.Font =
        Enum.Font.GothamBold
    loopButton.AutoButtonColor = false
    loopButton.Parent = parent
    MakeCorner(loopButton, 4)

    local secondsBox =
        Instance.new("TextBox")

    secondsBox.Size =
        UDim2.new(0, 48, 0, 20)
    secondsBox.Position =
        UDim2.new(0, 136, 1, -23)
    secondsBox.BackgroundColor3 =
        Color3.fromRGB(28, 28, 42)
    secondsBox.BorderSizePixel = 0
    secondsBox.Text =
        tostring(
            Settings[secondsKey]
        )
    secondsBox.PlaceholderText = "1"
    secondsBox.TextColor3 =
        Color3.fromRGB(
            255,
            255,
            255
        )
    secondsBox.TextSize = 10
    secondsBox.Font =
        Enum.Font.Gotham
    secondsBox.ClearTextOnFocus = false
    secondsBox.Parent = parent
    MakeCorner(secondsBox, 4)

    local secondsLabel =
        Instance.new("TextLabel")

    secondsLabel.Size =
        UDim2.new(0, 18, 0, 20)
    secondsLabel.Position =
        UDim2.new(0, 186, 1, -23)
    secondsLabel.BackgroundTransparency = 1
    secondsLabel.Text = "s"
    secondsLabel.TextColor3 =
        Color3.fromRGB(
            180,
            180,
            195
        )
    secondsLabel.TextSize = 10
    secondsLabel.Font =
        Enum.Font.Gotham
    secondsLabel.Parent = parent

    local function UpdateLoop()
        if Settings[stateKey] then
            loopButton.BackgroundColor3 =
                Color3.fromRGB(
                    50,
                    180,
                    70
                )
        else
            loopButton.BackgroundColor3 =
                Color3.fromRGB(
                    28,
                    28,
                    42
                )
        end
    end

    secondsBox.FocusLost:Connect(function()
        local value =
            tonumber(
                secondsBox.Text
            )

        if not value then
            value =
                Settings[secondsKey]
                or 1
        end

        value =
            math.clamp(
                value,
                0.1,
                3600
            )

        Settings[secondsKey] = value
        secondsBox.Text =
            tostring(value)

        Save()
    end)

    loopButton.MouseButton1Click:
        Connect(function()
            Settings[stateKey] =
                not Settings[stateKey]

            UpdateLoop()
            Save()

            if Settings[stateKey] then
                StartLoop(
                    id,
                    callback
                )
            else
                StopLoop(id)
            end
        end)

    UpdateLoop()

    if Settings[stateKey] then
        task.defer(function()
            StartLoop(
                id,
                callback
            )
        end)
    end
end

local function CreatePrefixRow()
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -5, 0, 42)
    row.BackgroundColor3 =
        Color3.fromRGB(18, 18, 26)
    row.BorderSizePixel = 0
    row.Parent = GamePage
    MakeCorner(row, 4)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 52, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = "Prefix"
    label.TextColor3 =
        Color3.fromRGB(240, 240, 240)
    label.TextSize = 13
    label.Font =
        Enum.Font.GothamMedium
    label.TextXAlignment =
        Enum.TextXAlignment.Left
    label.Parent = row

    local input = Instance.new("TextBox")
    input.Size = UDim2.new(0, 48, 0, 27)
    input.Position =
        UDim2.new(1, -172, 0.5, -13)
    input.BackgroundColor3 =
        Color3.fromRGB(28, 28, 42)
    input.BorderSizePixel = 0
    input.Text = Settings.ADMINPrefix
    input.PlaceholderText = "."
    input.TextColor3 =
        Color3.fromRGB(255, 255, 255)
    input.TextSize = 12
    input.Font = Enum.Font.Gotham
    input.ClearTextOnFocus = false
    input.Parent = row
    MakeCorner(input, 4)

    local chatButton =
        Instance.new("TextButton")
    chatButton.Size =
        UDim2.new(0, 54, 0, 27)
    chatButton.Position =
        UDim2.new(1, -120, 0.5, -13)
    chatButton.BorderSizePixel = 0
    chatButton.Text = "CHAT"
    chatButton.TextColor3 =
        Color3.fromRGB(255, 255, 255)
    chatButton.TextSize = 10
    chatButton.Font =
        Enum.Font.GothamBold
    chatButton.AutoButtonColor = false
    chatButton.Parent = row
    MakeCorner(chatButton, 4)

    local cmdButton =
        Instance.new("TextButton")
    cmdButton.Size =
        UDim2.new(0, 54, 0, 27)
    cmdButton.Position =
        UDim2.new(1, -62, 0.5, -13)
    cmdButton.BorderSizePixel = 0
    cmdButton.Text = "CMD"
    cmdButton.TextColor3 =
        Color3.fromRGB(255, 255, 255)
    cmdButton.TextSize = 10
    cmdButton.Font =
        Enum.Font.GothamBold
    cmdButton.AutoButtonColor = false
    cmdButton.Parent = row
    MakeCorner(cmdButton, 4)

    local function UpdateMode()
        if Settings.ADMINCommandMode
        == "CHAT" then
            chatButton.BackgroundColor3 =
                Color3.fromRGB(
                    50,
                    180,
                    70
                )
            cmdButton.BackgroundColor3 =
                Color3.fromRGB(
                    28,
                    28,
                    42
                )
        else
            chatButton.BackgroundColor3 =
                Color3.fromRGB(
                    28,
                    28,
                    42
                )
            cmdButton.BackgroundColor3 =
                Color3.fromRGB(
                    50,
                    180,
                    70
                )
        end
    end

    input.FocusLost:Connect(function()
        local value = Trim(input.Text)

        if value == "" then
            value = "."
            input.Text = value
        end

        Settings.ADMINPrefix = value
        Save()
    end)

    chatButton.MouseButton1Click:
        Connect(function()
            Settings.ADMINCommandMode =
                "CHAT"
            UpdateMode()
            Save()
        end)

    cmdButton.MouseButton1Click:
        Connect(function()
            Settings.ADMINCommandMode =
                "CMD"
            UpdateMode()
            Save()
        end)

    UpdateMode()
end

local function CreateCustomCommandRow()
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -5, 0, 70)
    row.BackgroundColor3 =
        Color3.fromRGB(18, 18, 26)
    row.BorderSizePixel = 0
    row.Parent = GamePage
    MakeCorner(row, 4)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 38, 0, 40)
    label.Position = UDim2.new(0, 8, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = "Cmd"
    label.TextColor3 =
        Color3.fromRGB(240, 240, 240)
    label.TextSize = 12
    label.Font =
        Enum.Font.GothamMedium
    label.Parent = row

    local commandBox =
        Instance.new("TextBox")
    commandBox.Size =
        UDim2.new(0, 70, 0, 25)
    commandBox.Position =
        UDim2.new(0, 48, 0, 8)
    commandBox.BackgroundColor3 =
        Color3.fromRGB(28, 28, 42)
    commandBox.BorderSizePixel = 0
    commandBox.Text =
        Settings.ADMINCustomCommand
    commandBox.PlaceholderText = "Command"
    commandBox.TextColor3 =
        Color3.fromRGB(255, 255, 255)
    commandBox.TextSize = 10
    commandBox.Font =
        Enum.Font.Gotham
    commandBox.ClearTextOnFocus = false
    commandBox.Parent = row
    MakeCorner(commandBox, 4)

    local targetBox =
        Instance.new("TextBox")
    targetBox.Size =
        UDim2.new(0, 68, 0, 25)
    targetBox.Position =
        UDim2.new(0, 122, 0, 8)
    targetBox.BackgroundColor3 =
        Color3.fromRGB(28, 28, 42)
    targetBox.BorderSizePixel = 0
    targetBox.Text =
        Settings.ADMINCustomTarget
    targetBox.PlaceholderText = "Nick"
    targetBox.TextColor3 =
        Color3.fromRGB(255, 255, 255)
    targetBox.TextSize = 10
    targetBox.Font =
        Enum.Font.Gotham
    targetBox.ClearTextOnFocus = false
    targetBox.Parent = row
    MakeCorner(targetBox, 4)

    local allButton =
        Instance.new("TextButton")
    allButton.Size =
        UDim2.new(0, 42, 0, 25)
    allButton.Position =
        UDim2.new(0, 194, 0, 8)
    allButton.BorderSizePixel = 0
    allButton.Text = "ALL"
    allButton.TextColor3 =
        Color3.fromRGB(255, 255, 255)
    allButton.TextSize = 10
    allButton.Font =
        Enum.Font.GothamBold
    allButton.AutoButtonColor = false
    allButton.Parent = row
    MakeCorner(allButton, 4)

    local useButton =
        Instance.new("TextButton")
    useButton.Size =
        UDim2.new(0, 48, 0, 25)
    useButton.Position =
        UDim2.new(1, -54, 0, 8)
    useButton.BackgroundColor3 =
        MAIN_COLOR
    useButton.BorderSizePixel = 0
    useButton.Text = "USE"
    useButton.TextColor3 =
        Color3.fromRGB(255, 255, 255)
    useButton.TextSize = 10
    useButton.Font =
        Enum.Font.GothamBold
    useButton.Parent = row
    MakeCorner(useButton, 4)

    local function UpdateAll()
        allButton.BackgroundColor3 =
            Settings.ADMINCustomAll
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

    local function SyncFields()
        Settings.ADMINCustomCommand =
            Trim(commandBox.Text)
        Settings.ADMINCustomTarget =
            Trim(targetBox.Text)
    end

    local function Execute()
        SyncFields()

        local target =
            Settings.ADMINCustomAll
            and "all"
            or Settings.ADMINCustomTarget

        return RunHDAdminCommand(
            Settings.ADMINCustomCommand,
            target
        )
    end

    commandBox.FocusLost:Connect(function()
        SyncFields()
        Save()
    end)

    targetBox.FocusLost:Connect(function()
        SyncFields()
        Save()
    end)

    allButton.MouseButton1Click:
        Connect(function()
            Settings.ADMINCustomAll =
                not Settings.ADMINCustomAll
            UpdateAll()
            Save()
        end)

    useButton.MouseButton1Click:
        Connect(function()
            Execute()
            Save()
        end)

    CreateLoopControls(
        row,
        "Custom",
        Execute
    )

    UpdateAll()
end

local function CreateCommandRow(
    id,
    labelText,
    commandName,
    targetSetting,
    allSetting
)
    Settings[targetSetting] =
        tostring(
            Settings[targetSetting]
            or ""
        )
    Settings[allSetting] =
        Settings[allSetting] == true

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -5, 0, 70)
    row.BackgroundColor3 =
        Color3.fromRGB(18, 18, 26)
    row.BorderSizePixel = 0
    row.Parent = GamePage
    MakeCorner(row, 4)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 80, 0, 38)
    label.Position = UDim2.new(0, 8, 0, 1)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 =
        Color3.fromRGB(240, 240, 240)
    label.TextSize =
        #labelText > 8 and 10 or 12
    label.Font =
        Enum.Font.GothamMedium
    label.TextXAlignment =
        Enum.TextXAlignment.Left
    label.Parent = row

    local targetBox =
        Instance.new("TextBox")
    targetBox.Size =
        UDim2.new(0, 78, 0, 25)
    targetBox.Position =
        UDim2.new(0, 86, 0, 8)
    targetBox.BackgroundColor3 =
        Color3.fromRGB(28, 28, 42)
    targetBox.BorderSizePixel = 0
    targetBox.Text =
        Settings[targetSetting]
    targetBox.PlaceholderText = "Nick"
    targetBox.TextColor3 =
        Color3.fromRGB(255, 255, 255)
    targetBox.TextSize = 10
    targetBox.Font =
        Enum.Font.Gotham
    targetBox.ClearTextOnFocus = false
    targetBox.Parent = row
    MakeCorner(targetBox, 4)

    local allButton =
        Instance.new("TextButton")
    allButton.Size =
        UDim2.new(0, 42, 0, 25)
    allButton.Position =
        UDim2.new(0, 168, 0, 8)
    allButton.BorderSizePixel = 0
    allButton.Text = "ALL"
    allButton.TextColor3 =
        Color3.fromRGB(255, 255, 255)
    allButton.TextSize = 10
    allButton.Font =
        Enum.Font.GothamBold
    allButton.AutoButtonColor = false
    allButton.Parent = row
    MakeCorner(allButton, 4)

    local useButton =
        Instance.new("TextButton")
    useButton.Size =
        UDim2.new(0, 48, 0, 25)
    useButton.Position =
        UDim2.new(1, -54, 0, 8)
    useButton.BackgroundColor3 =
        MAIN_COLOR
    useButton.BorderSizePixel = 0
    useButton.Text = "USE"
    useButton.TextColor3 =
        Color3.fromRGB(255, 255, 255)
    useButton.TextSize = 10
    useButton.Font =
        Enum.Font.GothamBold
    useButton.Parent = row
    MakeCorner(useButton, 4)

    local function UpdateAll()
        allButton.BackgroundColor3 =
            Settings[allSetting]
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

    local function Execute()
        Settings[targetSetting] =
            Trim(targetBox.Text)

        local target =
            Settings[allSetting]
            and "all"
            or Settings[targetSetting]

        if target == "" then
            return false
        end

        return RunHDAdminCommand(
            commandName,
            target
        )
    end

    targetBox.FocusLost:Connect(function()
        Settings[targetSetting] =
            Trim(targetBox.Text)
        Save()
    end)

    allButton.MouseButton1Click:
        Connect(function()
            Settings[allSetting] =
                not Settings[allSetting]
            UpdateAll()
            Save()
        end)

    useButton.MouseButton1Click:
        Connect(function()
            Execute()
            Save()
        end)

    CreateLoopControls(
        row,
        id,
        Execute
    )

    UpdateAll()
end

local function CreateSimpleButton(
    name,
    callback
)
    local button =
        Instance.new("TextButton")
    button.Size =
        UDim2.new(1, -5, 0, 39)
    button.BackgroundColor3 =
        Color3.fromRGB(22, 22, 32)
    button.BorderSizePixel = 0
    button.Text = name
    button.TextColor3 =
        Color3.fromRGB(240, 240, 240)
    button.TextSize = 13
    button.Font =
        Enum.Font.GothamMedium
    button.Parent = GamePage
    MakeCorner(button, 4)

    button.MouseButton1Click:
        Connect(function()
            if not getgenv().Destroyed then
                callback()
            end
        end)

    return button
end

CreatePrefixRow()
CreateCustomCommandRow()

CreateCommandRow(
    "Uncmdbar",
    "Uncmdbar",
    "uncmdbar",
    "ADMINUncmdbarTarget",
    "ADMINUncmdbarAll"
)

CreateCommandRow(
    "Mute",
    "Mute",
    "mute",
    "ADMINMuteTarget",
    "ADMINMuteAll"
)

CreateCommandRow(
    "Rocket",
    "Rocket",
    "rocket",
    "ADMINRocketTarget",
    "ADMINRocketAll"
)

CreateCommandRow(
    "Poop",
    "Poop",
    "poop",
    "ADMINPoopTarget",
    "ADMINPoopAll"
)

CreateCommandRow(
    "Kill",
    "Kill",
    "kill",
    "ADMINKillTarget",
    "ADMINKillAll"
)

CreateCommandRow(
    "Punish",
    "Punish",
    "punish",
    "ADMINPunishTarget",
    "ADMINPunishAll"
)

CreateCommandRow(
    "SuperFling",
    "SuperFling",
    "superfling",
    "ADMINSuperFlingTarget",
    "ADMINSuperFlingAll"
)

CreateCommandRow(
    "Kick",
    "Kick",
    "kick",
    "ADMINKickTarget",
    "ADMINKickAll"
)

CreateSimpleButton(
    "Rejoin",
    function()
        if AutoSaveConfiguration then
            pcall(
                AutoSaveConfiguration
            )
        end

        task.wait(0.08)

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
    end
)

CreateSimpleButton(
    "Logs",
    function()
        RunHDAdminCommand(
            "logs",
            ""
        )
    end
)
