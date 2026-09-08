if game.PlaceId ~= 4522347649 then
    return
end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
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

local function Save()
    if AutoSaveConfiguration then
        AutoSaveConfiguration()
    end
end

local function IsVisibleObject(obj)
    if not obj then
        return false
    end

    local current = obj

    while current do
        if current:IsA("GuiObject") and not current.Visible then
            return false
        end

        if current:IsA("ScreenGui") and not current.Enabled then
            return false
        end

        current = current.Parent
    end

    return true
end

local function ObjectText(obj)
    if obj:IsA("TextBox")
    or obj:IsA("TextLabel")
    or obj:IsA("TextButton") then
        return string.lower(
            tostring(obj.Text or "")
                .. " "
                .. tostring(obj.PlaceholderText or "")
                .. " "
                .. tostring(obj.Name or "")
        )
    end

    return string.lower(tostring(obj.Name or ""))
end

local function FindCommandBar()
    local playerGui = Player:FindFirstChildOfClass("PlayerGui")

    if not playerGui then
        return nil, nil
    end

    local candidates = {}

    for _, obj in ipairs(playerGui:GetDescendants()) do
        if obj:IsA("TextBox") then
            local blob = ObjectText(obj)
            local parentBlob = obj.Parent and ObjectText(obj.Parent) or ""
            local score = 0

            if string.find(blob, "enter command", 1, true) then
                score = score + 100
            end

            if string.find(blob, "cmdbar2", 1, true)
            or string.find(parentBlob, "cmdbar2", 1, true) then
                score = score + 80
            elseif string.find(blob, "cmdbar1", 1, true)
            or string.find(parentBlob, "cmdbar1", 1, true) then
                score = score + 70
            elseif string.find(blob, "cmdbar", 1, true)
            or string.find(parentBlob, "cmdbar", 1, true) then
                score = score + 50
            end

            if score > 0 then
                table.insert(candidates, {
                    Box = obj,
                    Score = score
                })
            end
        end
    end

    table.sort(candidates, function(a, b)
        return a.Score > b.Score
    end)

    for _, candidate in ipairs(candidates) do
        local box = candidate.Box
        local searchRoot = box.Parent
        local executeButton = nil

        for _ = 1, 5 do
            if not searchRoot then
                break
            end

            for _, obj in ipairs(searchRoot:GetDescendants()) do
                if obj:IsA("TextButton")
                or obj:IsA("ImageButton") then
                    local blob = ObjectText(obj)

                    if string.find(blob, "execute", 1, true)
                    or string.find(blob, "run", 1, true) then
                        executeButton = obj
                        break
                    end
                end
            end

            if executeButton then
                break
            end

            searchRoot = searchRoot.Parent
        end

        if executeButton then
            return box, executeButton
        end
    end

    return nil, nil
end

local function TriggerButton(button)
    if not button or not button.Parent then
        return false
    end

    if firesignal then
        local ok = pcall(function()
            firesignal(button.MouseButton1Click)
        end)

        if ok then
            return true
        end

        ok = pcall(function()
            firesignal(button.Activated)
        end)

        if ok then
            return true
        end
    end

    local ok = pcall(function()
        button:Activate()
    end)

    if ok then
        return true
    end

    if IsVisibleObject(button) then
        return pcall(function()
            local center =
                button.AbsolutePosition
                + button.AbsoluteSize / 2

            VirtualInputManager:SendMouseButtonEvent(
                center.X,
                center.Y,
                0,
                true,
                game,
                0
            )

            task.wait(0.02)

            VirtualInputManager:SendMouseButtonEvent(
                center.X,
                center.Y,
                0,
                false,
                game,
                0
            )
        end)
    end

    return false
end

local function RunHDAdminCommand(command)
    local box, executeButton = FindCommandBar()

    if not box or not executeButton then
        return false
    end

    local oldText = box.Text
    box.Text = tostring(command or "")

    local fired = TriggerButton(executeButton)

    task.defer(function()
        task.wait(0.05)

        if box and box.Parent then
            box.Text = oldText
        end
    end)

    return fired
end

local function MakeCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 4)
    corner.Parent = parent
end

local function CreatePrefixRow()
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -5, 0, 42)
    row.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
    row.BorderSizePixel = 0
    row.Parent = GamePage
    MakeCorner(row, 4)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -110, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = "Prefix"
    label.TextColor3 = Color3.fromRGB(240, 240, 240)
    label.TextSize = 13
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local input = Instance.new("TextBox")
    input.Size = UDim2.new(0, 90, 0, 27)
    input.Position = UDim2.new(1, -102, 0.5, -13)
    input.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
    input.BorderSizePixel = 0
    input.Text = Settings.ADMINPrefix
    input.PlaceholderText = "."
    input.TextColor3 = Color3.fromRGB(255, 255, 255)
    input.TextSize = 12
    input.Font = Enum.Font.Gotham
    input.ClearTextOnFocus = false
    input.Parent = row
    MakeCorner(input, 4)

    input.FocusLost:Connect(function()
        local value = tostring(input.Text or "")

        if value == "" then
            value = "."
            input.Text = value
        end

        Settings.ADMINPrefix = value
        Save()
    end)
end

local function CreateKillRow()
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -5, 0, 52)
    row.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
    row.BorderSizePixel = 0
    row.Parent = GamePage
    MakeCorner(row, 4)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 118, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = "KILL (nick) all (kill)"
    label.TextColor3 = Color3.fromRGB(240, 240, 240)
    label.TextSize = 11
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextWrapped = true
    label.Parent = row

    local input = Instance.new("TextBox")
    input.Size = UDim2.new(0, 76, 0, 27)
    input.Position = UDim2.new(1, -196, 0.5, -13)
    input.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
    input.BorderSizePixel = 0
    input.Text = Settings.ADMINKillTarget
    input.PlaceholderText = "Nick"
    input.TextColor3 = Color3.fromRGB(255, 255, 255)
    input.TextSize = 11
    input.Font = Enum.Font.Gotham
    input.ClearTextOnFocus = false
    input.Parent = row
    MakeCorner(input, 4)

    local allButton = Instance.new("TextButton")
    allButton.Size = UDim2.new(0, 46, 0, 27)
    allButton.Position = UDim2.new(1, -116, 0.5, -13)
    allButton.BorderSizePixel = 0
    allButton.Text = "ALL"
    allButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    allButton.TextSize = 11
    allButton.Font = Enum.Font.GothamBold
    allButton.AutoButtonColor = false
    allButton.Parent = row
    MakeCorner(allButton, 4)

    local killButton = Instance.new("TextButton")
    killButton.Size = UDim2.new(0, 58, 0, 27)
    killButton.Position = UDim2.new(1, -66, 0.5, -13)
    killButton.BackgroundColor3 = MAIN_COLOR
    killButton.BorderSizePixel = 0
    killButton.Text = "KILL"
    killButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    killButton.TextSize = 11
    killButton.Font = Enum.Font.GothamBold
    killButton.Parent = row
    MakeCorner(killButton, 4)

    local function UpdateAll()
        if Settings.ADMINKillAll then
            allButton.BackgroundColor3 =
                Color3.fromRGB(50, 180, 70)
        else
            allButton.BackgroundColor3 =
                Color3.fromRGB(28, 28, 42)
        end
    end

    input.FocusLost:Connect(function()
        Settings.ADMINKillTarget =
            tostring(input.Text or "")

        Save()
    end)

    allButton.MouseButton1Click:Connect(function()
        Settings.ADMINKillAll =
            not Settings.ADMINKillAll

        UpdateAll()
        Save()
    end)

    killButton.MouseButton1Click:Connect(function()
        Settings.ADMINKillTarget =
            tostring(input.Text or "")

        local target

        if Settings.ADMINKillAll then
            target = "all"
        else
            target = Settings.ADMINKillTarget
        end

        if not target or target == "" then
            return
        end

        local prefix =
            tostring(Settings.ADMINPrefix or ".")

        RunHDAdminCommand(
            prefix .. "kill " .. target
        )

        Save()
    end)

    UpdateAll()
end

CreatePrefixRow()
CreateKillRow()
