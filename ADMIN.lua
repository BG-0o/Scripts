if game.PlaceId ~= 4522347649 then
    return
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
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

if Settings.ADMINCommandMode ~= "CHAT"
and Settings.ADMINCommandMode ~= "CMD" then
    Settings.ADMINCommandMode = "CMD"
end

local function Save()
    if AutoSaveConfiguration then
        AutoSaveConfiguration()
    end
end

local function Blob(obj)
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

local function AncestorBlob(obj, depth)
    local pieces = {}
    local current = obj

    for _ = 1, depth or 6 do
        if not current then
            break
        end

        table.insert(
            pieces,
            Blob(current)
        )

        current = current.Parent
    end

    return table.concat(
        pieces,
        " "
    )
end

local function FindExecuteButton(box)
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
                local blob = Blob(obj)

                if string.find(
                    blob,
                    "execute",
                    1,
                    true
                )
                or string.find(
                    blob,
                    "run",
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

local function CollectCommandBars()
    local roots = {}
    local playerGui =
        Player:FindFirstChildOfClass("PlayerGui")

    if playerGui then
        table.insert(roots, playerGui)
    end

    table.insert(roots, CoreGui)

    local found = {}
    local seen = {}

    for _, root in ipairs(roots) do
        for _, obj in ipairs(root:GetDescendants()) do
            if obj:IsA("TextBox") then
                local blob = Blob(obj)
                local fullBlob =
                    AncestorBlob(obj, 7)

                local score = 0
                local kind = 0

                if string.find(
                    fullBlob,
                    "cmdbar2",
                    1,
                    true
                ) then
                    score = score + 300
                    kind = 2
                elseif string.find(
                    fullBlob,
                    "cmdbar1",
                    1,
                    true
                ) then
                    score = score + 250
                    kind = 1
                elseif string.find(
                    fullBlob,
                    "cmdbar",
                    1,
                    true
                ) then
                    score = score + 150
                end

                if string.find(
                    blob,
                    "enter command",
                    1,
                    true
                ) then
                    score = score + 200
                end

                if string.find(
                    blob,
                    "command",
                    1,
                    true
                ) then
                    score = score + 40
                end

                if score > 0
                and not seen[obj] then
                    local executeButton =
                        FindExecuteButton(obj)

                    if executeButton then
                        seen[obj] = true

                        table.insert(found, {
                            Box = obj,
                            Button = executeButton,
                            Score = score,
                            Kind = kind
                        })
                    end
                end
            end
        end
    end

    table.sort(found, function(a, b)
        if a.Kind ~= b.Kind then
            return a.Kind > b.Kind
        end

        return a.Score > b.Score
    end)

    return found
end

local function FireConnectionList(signal)
    if not getconnections then
        return false
    end

    local ok, connections = pcall(function()
        return getconnections(signal)
    end)

    if not ok
    or typeof(connections) ~= "table" then
        return false
    end

    local fired = false

    for _, connection in ipairs(connections) do
        local fn = connection.Function

        if typeof(fn) == "function" then
            local callOk = pcall(fn)

            if callOk then
                fired = true
            end
        end
    end

    return fired
end

local function FireButton(button)
    if not button
    or not button.Parent then
        return false
    end

    if firesignal then
        local ok = pcall(function()
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

    if FireConnectionList(
        button.MouseButton1Click
    ) then
        return true
    end

    if FireConnectionList(
        button.Activated
    ) then
        return true
    end

    return false
end

local function FireTextBoxEnter(box)
    if not box
    or not box.Parent then
        return false
    end

    if firesignal then
        local ok = pcall(function()
            firesignal(
                box.FocusLost,
                true
            )
        end)

        if ok then
            return true
        end
    end

    if getconnections then
        local ok, connections = pcall(function()
            return getconnections(
                box.FocusLost
            )
        end)

        if ok
        and typeof(connections) == "table" then
            local fired = false

            for _, connection in ipairs(
                connections
            ) do
                local fn = connection.Function

                if typeof(fn) == "function" then
                    local callOk = pcall(
                        fn,
                        true
                    )

                    if callOk then
                        fired = true
                    end
                end
            end

            if fired then
                return true
            end
        end
    end

    return false
end

local function VirtualExecute(box, button)
    if not box
    or not button then
        return false
    end

    local visibleStates = {}
    local current = button

    for _ = 1, 7 do
        if not current then
            break
        end

        if current:IsA("GuiObject") then
            table.insert(
                visibleStates,
                {
                    Object = current,
                    Visible = current.Visible
                }
            )

            current.Visible = true
        elseif current:IsA("ScreenGui") then
            table.insert(
                visibleStates,
                {
                    Object = current,
                    Enabled = current.Enabled
                }
            )

            current.Enabled = true
        end

        current = current.Parent
    end

    local ok = pcall(function()
        local center =
            button.AbsolutePosition
            + button.AbsoluteSize / 2

        VirtualInputManager:
            SendMouseButtonEvent(
                center.X,
                center.Y,
                0,
                true,
                game,
                0
            )

        task.wait(0.02)

        VirtualInputManager:
            SendMouseButtonEvent(
                center.X,
                center.Y,
                0,
                false,
                game,
                0
            )
    end)

    for _, state in ipairs(visibleStates) do
        if state.Object
        and state.Object.Parent then
            if state.Visible ~= nil then
                state.Object.Visible =
                    state.Visible
            elseif state.Enabled ~= nil then
                state.Object.Enabled =
                    state.Enabled
            end
        end
    end

    return ok
end

local function ExecuteOnBar(candidate, command)
    local box = candidate.Box
    local button = candidate.Button

    if not box
    or not box.Parent
    or not button
    or not button.Parent then
        return false
    end

    local oldText = box.Text
    box.Text = command

    task.wait()

    local fired = FireButton(button)

    if not fired then
        fired = FireTextBoxEnter(box)
    end

    if not fired then
        fired = VirtualExecute(
            box,
            button
        )
    end

    task.delay(0.12, function()
        if box
        and box.Parent then
            box.Text = oldText
        end
    end)

    return fired
end

local CachedHDAdminSignals = nil
local CachedRequestCommand = nil
local CachedRetrieveData = nil

local function GetHDAdminSignals()
    if CachedHDAdminSignals
    and CachedHDAdminSignals.Parent then
        return CachedHDAdminSignals
    end

    local client =
        ReplicatedStorage:FindFirstChild(
            "HDAdminClient"
        )

    if not client then
        local ok, value = pcall(function()
            return ReplicatedStorage:
                WaitForChild(
                    "HDAdminClient",
                    3
                )
        end)

        if ok then
            client = value
        end
    end

    if not client then
        return nil
    end

    local signals =
        client:FindFirstChild(
            "Signals"
        )

    if not signals then
        local ok, value = pcall(function()
            return client:WaitForChild(
                "Signals",
                2
            )
        end)

        if ok then
            signals = value
        end
    end

    CachedHDAdminSignals = signals
    return signals
end

local function GetRequestCommand()
    if CachedRequestCommand
    and CachedRequestCommand.Parent
    and CachedRequestCommand:IsA(
        "RemoteFunction"
    ) then
        return CachedRequestCommand
    end

    local signals = GetHDAdminSignals()

    if not signals then
        return nil
    end

    local remote =
        signals:FindFirstChild(
            "RequestCommand"
        )

    if remote
    and remote:IsA("RemoteFunction") then
        CachedRequestCommand = remote
        return remote
    end

    return nil
end

local function GetRetrieveData()
    if CachedRetrieveData
    and CachedRetrieveData.Parent
    and CachedRetrieveData:IsA(
        "RemoteFunction"
    ) then
        return CachedRetrieveData
    end

    local signals = GetHDAdminSignals()

    if not signals then
        return nil
    end

    local remote =
        signals:FindFirstChild(
            "RetrieveData"
        )

    if remote
    and remote:IsA("RemoteFunction") then
        CachedRetrieveData = remote
        return remote
    end

    return nil
end

local function GetHDAdminPrefix()
    local fallback =
        tostring(
            Settings.ADMINPrefix or "."
        )

    local retrieve = GetRetrieveData()

    if not retrieve then
        return fallback
    end

    local ok, data = pcall(function()
        return retrieve:InvokeServer()
    end)

    if not ok
    or typeof(data) ~= "table" then
        return fallback
    end

    local pdata = data.pdata

    if typeof(pdata) == "table"
    and typeof(pdata.Prefix) == "string"
    and pdata.Prefix ~= "" then
        return pdata.Prefix
    end

    return fallback
end

local function SendCommandToChat(
    commandName,
    target
)
    local prefix =
        tostring(
            Settings.ADMINPrefix or "."
        )

    local message =
        prefix
        .. commandName
        .. " "
        .. target

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
        pcall(function()
            Players:Chat(message)
            sent = true
        end)
    end

    return sent
end

local function SendCommandDirect(
    commandName,
    target
)
    local request =
        GetRequestCommand()

    if not request then
        CachedHDAdminSignals = nil
        CachedRequestCommand = nil
        CachedRetrieveData = nil

        request =
            GetRequestCommand()
    end

    if not request then
        return false
    end

    local prefix =
        GetHDAdminPrefix()

    local command =
        prefix
        .. commandName
        .. " "
        .. target

    local ok = pcall(function()
        request:InvokeServer(command)
    end)

    return ok
end

local function RunHDAdminCommand(
    commandName,
    target
)
    commandName =
        string.lower(
            tostring(commandName or "")
        )

    target =
        tostring(target or "")

    if commandName == ""
    or target == "" then
        return false
    end

    if Settings.ADMINCommandMode == "CHAT" then
        return SendCommandToChat(
            commandName,
            target
        )
    end

    return SendCommandDirect(
        commandName,
        target
    )
end

local function MakeCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius =
        UDim.new(
            0,
            radius or 4
        )
    corner.Parent = parent
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
    label.Size = UDim2.new(0, 54, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = "Prefix"
    label.TextColor3 =
        Color3.fromRGB(240, 240, 240)
    label.TextSize = 13
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment =
        Enum.TextXAlignment.Left
    label.Parent = row

    local input = Instance.new("TextBox")
    input.Size = UDim2.new(0, 50, 0, 27)
    input.Position =
        UDim2.new(1, -174, 0.5, -13)
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
        if Settings.ADMINCommandMode == "CHAT" then
            chatButton.BackgroundColor3 =
                Color3.fromRGB(50, 180, 70)

            cmdButton.BackgroundColor3 =
                Color3.fromRGB(28, 28, 42)
        else
            chatButton.BackgroundColor3 =
                Color3.fromRGB(28, 28, 42)

            cmdButton.BackgroundColor3 =
                Color3.fromRGB(50, 180, 70)
        end
    end

    input.FocusLost:Connect(function()
        local value =
            tostring(input.Text or "")

        if value == "" then
            value = "."
            input.Text = value
        end

        Settings.ADMINPrefix = value
        Save()
    end)

    chatButton.MouseButton1Click:
        Connect(function()
            if Settings.ADMINCommandMode
            == "CHAT" then
                return
            end

            Settings.ADMINCommandMode =
                "CHAT"

            UpdateMode()
            Save()
        end)

    cmdButton.MouseButton1Click:
        Connect(function()
            if Settings.ADMINCommandMode
            == "CMD" then
                return
            end

            Settings.ADMINCommandMode =
                "CMD"

            UpdateMode()
            Save()
        end)

    UpdateMode()
end

local function CreateTargetCommandRow(
    labelText,
    targetSetting,
    allSetting,
    commandName,
    buttonText
)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -5, 0, 48)
    row.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
    row.BorderSizePixel = 0
    row.Parent = GamePage
    MakeCorner(row, 4)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 76, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(240, 240, 240)
    label.TextSize = 13
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local input = Instance.new("TextBox")
    input.Size = UDim2.new(0, 80, 0, 27)
    input.Position = UDim2.new(1, -204, 0.5, -13)
    input.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
    input.BorderSizePixel = 0
    input.Text =
        tostring(
            Settings[targetSetting]
            or ""
        )
    input.PlaceholderText = "Nick"
    input.TextColor3 = Color3.fromRGB(255, 255, 255)
    input.TextSize = 11
    input.Font = Enum.Font.Gotham
    input.ClearTextOnFocus = false
    input.Parent = row
    MakeCorner(input, 4)

    local allButton = nil

    if allSetting then
        allButton = Instance.new("TextButton")
        allButton.Size = UDim2.new(0, 46, 0, 27)
        allButton.Position = UDim2.new(1, -120, 0.5, -13)
        allButton.BorderSizePixel = 0
        allButton.Text = "ALL"
        allButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        allButton.TextSize = 11
        allButton.Font = Enum.Font.GothamBold
        allButton.AutoButtonColor = false
        allButton.Parent = row
        MakeCorner(allButton, 4)
    end

    local actionButton =
        Instance.new("TextButton")

    actionButton.Size = UDim2.new(0, 64, 0, 27)
    actionButton.Position = UDim2.new(1, -70, 0.5, -13)
    actionButton.BackgroundColor3 = MAIN_COLOR
    actionButton.BorderSizePixel = 0
    actionButton.Text = buttonText
    actionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    actionButton.TextSize = 10
    actionButton.Font = Enum.Font.GothamBold
    actionButton.Parent = row
    MakeCorner(actionButton, 4)

    local function UpdateAll()
        if not allButton then
            return
        end

        if Settings[allSetting] then
            allButton.BackgroundColor3 =
                Color3.fromRGB(
                    50,
                    180,
                    70
                )
        else
            allButton.BackgroundColor3 =
                Color3.fromRGB(
                    28,
                    28,
                    42
                )
        end
    end

    input.FocusLost:Connect(function()
        Settings[targetSetting] =
            tostring(
                input.Text or ""
            )

        Save()
    end)

    if allButton then
        allButton.MouseButton1Click:
            Connect(function()
                Settings[allSetting] =
                    not Settings[allSetting]

                UpdateAll()
                Save()
            end)
    end

    actionButton.MouseButton1Click:
        Connect(function()
            Settings[targetSetting] =
                tostring(
                    input.Text or ""
                )

            local target =
                Settings[targetSetting]

            if allSetting
            and Settings[allSetting] then
                target = "all"
            end

            if not target
            or target == "" then
                return
            end

            RunHDAdminCommand(
                commandName,
                target
            )

            Save()
        end)

    UpdateAll()
end

CreatePrefixRow()

CreateTargetCommandRow(
    "Kill",
    "ADMINKillTarget",
    "ADMINKillAll",
    "kill",
    "KILL"
)

CreateTargetCommandRow(
    "Rocket",
    "ADMINRocketTarget",
    "ADMINRocketAll",
    "rocket",
    "ROCKET"
)

CreateTargetCommandRow(
    "Kick",
    "ADMINKickTarget",
    nil,
    "kick",
    "KICK"
)
