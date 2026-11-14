do
    local env = getgenv()
    local current = env.__ToxHubBootLock
    local now = os.clock()
    if typeof(current) == "table"
    and current.Game == game
    and now - (tonumber(current.StartedAt) or now) < 15 then
        return
    end
    env.__ToxHubBootLock = {
        Game = game,
        StartedAt = now
    }
end
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")
local SoundService = game:GetService("SoundService")
local TextChatService = game:GetService("TextChatService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local ToxParentContainer = (gethui and gethui()) or game:GetService("CoreGui")
local function HasRunningToxHub()
    local gui = getgenv().Gui
    local notifGui = getgenv().NotifGui
    if typeof(gui) == "Instance"
    and gui.Parent then
        return true
    end
    if typeof(notifGui) == "Instance"
    and notifGui.Parent then
        return true
    end
    if getgenv().ToxHubActive == true
    and getgenv().Destroyed ~= true then
        return true
    end
    for _, object in ipairs(ToxParentContainer:GetChildren()) do
        if object.Name == "ToxV1Gui"
        or object.Name == "ToxNotifs" then
            return true
        end
    end
    return false
end
local function ShowReexecuteConfirm()
    if getgenv().ToxReexecuteConfirmOpen then
        return false
    end
    getgenv().ToxReexecuteConfirmOpen = true
    local confirmGui = Instance.new("ScreenGui")
    confirmGui.Name = "ToxReexecuteConfirm"
    confirmGui.ResetOnSpawn = false
    confirmGui.IgnoreGuiInset = true
    confirmGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    confirmGui.DisplayOrder = 2147483647
    confirmGui.Parent = ToxParentContainer
    local shadow = Instance.new("Frame")
    shadow.Size = UDim2.new(1, 0, 1, 0)
    shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadow.BackgroundTransparency = 0.35
    shadow.BorderSizePixel = 0
    shadow.Parent = confirmGui
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 380, 0, 190)
    frame.Position = UDim2.new(0.5, -190, 0.5, -95)
    frame.BackgroundColor3 = Color3.fromRGB(10, 10, 16)
    frame.BorderSizePixel = 0
    frame.Parent = confirmGui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0, 168, 255)
    stroke.Thickness = 2
    stroke.Parent = frame
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -30, 0, 42)
    title.Position = UDim2.new(0, 15, 0, 12)
    title.BackgroundTransparency = 1
    title.Text = "ToxHub is already running"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame
    local body = Instance.new("TextLabel")
    body.Size = UDim2.new(1, -30, 0, 58)
    body.Position = UDim2.new(0, 15, 0, 58)
    body.BackgroundTransparency = 1
    body.Text = "Do you want to execute ToxHub again? The current interface and active loops will be restarted."
    body.TextColor3 = Color3.fromRGB(220, 220, 230)
    body.Font = Enum.Font.Gotham
    body.TextSize = 13
    body.TextWrapped = true
    body.TextXAlignment = Enum.TextXAlignment.Left
    body.TextYAlignment = Enum.TextYAlignment.Top
    body.Parent = frame
    local execute = Instance.new("TextButton")
    execute.Size = UDim2.new(0.5, -22, 0, 38)
    execute.Position = UDim2.new(0, 15, 1, -53)
    execute.BackgroundColor3 = Color3.fromRGB(45, 170, 80)
    execute.BorderSizePixel = 0
    execute.Text = "EXECUTE AGAIN"
    execute.TextColor3 = Color3.fromRGB(255, 255, 255)
    execute.Font = Enum.Font.GothamBold
    execute.TextSize = 12
    execute.Parent = frame
    local executeCorner = Instance.new("UICorner")
    executeCorner.CornerRadius = UDim.new(0, 7)
    executeCorner.Parent = execute
    local cancel = Instance.new("TextButton")
    cancel.Size = UDim2.new(0.5, -22, 0, 38)
    cancel.Position = UDim2.new(0.5, 7, 1, -53)
    cancel.BackgroundColor3 = Color3.fromRGB(170, 50, 55)
    cancel.BorderSizePixel = 0
    cancel.Text = "CANCEL"
    cancel.TextColor3 = Color3.fromRGB(255, 255, 255)
    cancel.Font = Enum.Font.GothamBold
    cancel.TextSize = 12
    cancel.Parent = frame
    local cancelCorner = Instance.new("UICorner")
    cancelCorner.CornerRadius = UDim.new(0, 7)
    cancelCorner.Parent = cancel
    local result = nil
    execute.MouseButton1Click:Connect(function()
        result = true
    end)
    cancel.MouseButton1Click:Connect(function()
        result = false
    end)
    local started = os.clock()
    repeat
        task.wait(0.05)
    until result ~= nil
    or os.clock() - started > 60
    pcall(function()
        confirmGui:Destroy()
    end)
    getgenv().ToxReexecuteConfirmOpen = nil
    return result == true
end
if HasRunningToxHub() then
    if not ShowReexecuteConfirm() then
        getgenv().__ToxHubBootLock = nil
        getgenv().__ToxHubReexecCancelled = true
        return
    end
    getgenv().__ToxHubReexecCancelled = nil
    getgenv().Destroyed = true
    getgenv().ScriptLoaded = false
    Destroyed = true
    ScriptLoaded = false
    getgenv().ToxOptionsReady = nil
    getgenv().ToxStartupBooleanState = nil
    getgenv().ToxStartupToggleCallbacks = nil
    getgenv().ToxStartupOptionsApplied = nil
    getgenv().ToxHubActive = false
    getgenv().ToxUniversalLoaded = nil
    getgenv().ToxCombatLoaded = nil
    getgenv().ToxChatLoaded = nil
    getgenv().ToxSystemsLoaded = nil
    getgenv().ToxControlGui = nil
    getgenv().ToxNDSModuleLoadedJobId = nil
    getgenv().ToxLBBModuleLoadedJobId = nil
    getgenv().ToxLBBModuleVersion = nil
    getgenv().ToxLBBModulePage = nil
    getgenv().ToxFTFModuleLoadedJobId = nil
    getgenv().ToxFTFModuleVersion = nil
    getgenv().ToxFTFModulePage = nil
    getgenv().ToxPLModuleLoadedJobId = nil
    getgenv().ToxPLModuleVersion = nil
    getgenv().ToxPLModulePage = nil
    getgenv().ToxBABFTModuleLoadedJobId = nil
    getgenv().ToxBABFTModuleVersion = nil
    getgenv().ToxBABFTModulePage = nil
    getgenv().ToxSODModuleLoadedJobId = nil
    getgenv().ToxSODModuleVersion = nil
    getgenv().ToxSODModulePage = nil
    getgenv().ToxMM2ModuleLoadedJobId = nil
    getgenv().ToxMM2ModuleVersion = nil
    getgenv().ToxMM2ModulePage = nil
    getgenv().ToxMM2CoreReady = nil
    getgenv().ToxMM2CoreVersion = nil
    getgenv().ToxMM2LoaderJobId = nil
    getgenv().ToxMM2LoaderVersion = nil
    getgenv().ToxMM2LoaderPage = nil
    getgenv().ToxBINGOModuleLoadedJobId = nil
    getgenv().ToxBINGOModuleVersion = nil
    getgenv().ToxBINGOModulePage = nil
    getgenv().ToxCFModuleLoadedJobId = nil
    getgenv().ToxCFModuleVersion = nil
    getgenv().ToxCFModulePage = nil
    getgenv().ToxGameModuleLoadedUrl = nil
    getgenv().ToxGameModuleLoadedPage = nil
    getgenv().ToxGameModuleLoadingUrl = nil
    getgenv().ToxGameModuleLoadingPage = nil
    if getgenv().ToxCombatCleanup then
        pcall(getgenv().ToxCombatCleanup)
    end
    if getgenv().ToxUniversal2ExtraCleanup then
        pcall(getgenv().ToxUniversal2ExtraCleanup)
    end
    if getgenv().ToxUniversal2Cleanup then
        pcall(getgenv().ToxUniversal2Cleanup)
    end
    if getgenv().ToxUniversal3Cleanup then
        pcall(getgenv().ToxUniversal3Cleanup)
    end
    if getgenv().ToxLightingCleanup then
        pcall(getgenv().ToxLightingCleanup)
    end
    if getgenv().ToxChatCleanup then
        pcall(getgenv().ToxChatCleanup)
    end
    if getgenv().ToxNDSCleanup then
        pcall(getgenv().ToxNDSCleanup)
    end
    if getgenv().ToxMM2Cleanup then
        pcall(getgenv().ToxMM2Cleanup)
    end
    if getgenv().UpdateFullbright and getgenv().Settings then
        pcall(function()
            getgenv().Settings.Fullbright = false
            getgenv().UpdateFullbright()
        end)
    end
    if getgenv().ToxSystemsCleanup then
        pcall(getgenv().ToxSystemsCleanup)
    end
    if getgenv().ToxADMINCleanup then
        pcall(getgenv().ToxADMINCleanup)
    end
    if getgenv().ToxLBBCleanup then
        pcall(getgenv().ToxLBBCleanup)
    end
    if getgenv().ToxFTFCleanup then
        pcall(getgenv().ToxFTFCleanup)
    end
    if getgenv().ToxPLCleanup then
        pcall(getgenv().ToxPLCleanup)
    end
    if getgenv().ToxBABFTCleanup then
        pcall(getgenv().ToxBABFTCleanup)
    end
    if getgenv().ToxSODCleanup then
        pcall(getgenv().ToxSODCleanup)
    end
    if getgenv().ToxBINGOCleanup then
        pcall(getgenv().ToxBINGOCleanup)
    end
    if getgenv().ToxCFCleanup then
        pcall(getgenv().ToxCFCleanup)
    end
    if getgenv().ScriptConnections then
        for _, conn in ipairs(getgenv().ScriptConnections) do
            pcall(function()
                conn:Disconnect()
            end)
        end
    end
    task.wait(0.15)
end
if getgenv().ToxUI and getgenv().ToxUI.ScreenWeatherGui then
    pcall(function() getgenv().ToxUI.ScreenWeatherGui:Destroy() end)
    getgenv().ToxUI.ScreenWeatherGui = nil
end
if getgenv().ToxRenderBackdropGui then
    pcall(function() getgenv().ToxRenderBackdropGui:Destroy() end)
    getgenv().ToxRenderBackdropGui = nil
end
if getgenv().Gui then
    pcall(function() getgenv().Gui:Destroy() end)
    getgenv().Gui = nil
    getgenv().Main = nil
    getgenv().JoinGamesScroll = nil
    getgenv().JoinGamesGui = nil
    getgenv().JoinGameIdBox = nil
    getgenv().JoinGameAddButton = nil
    getgenv().ToxChatScroll = nil
end
if getgenv().NotifGui then
    pcall(function() getgenv().NotifGui:Destroy() end)
    getgenv().NotifGui = nil
end
getgenv().Destroyed = false
Destroyed = false
getgenv().__ToxHubReexecCancelled = nil

----------------------------------------------------------------------
-- TOXHUB KEY SYSTEM ("Tox-BetaUsers")
----------------------------------------------------------------------
local VALID_KEY = "Tox-BetaUsers"
local KEY_FILENAME = "ToxHub_Key.txt"
local DISCORD_URL = "https://discord.com/invite/A7tZ9VbVvM"

local LEGACY_KEY_FILENAME = "ToxHud_Key.txt"   -- old name, read so nobody has to type the key again

local function ReadSavedKey()
    if isfile and readfile and not isfile(KEY_FILENAME) and isfile(LEGACY_KEY_FILENAME) then
        local ok, raw = pcall(readfile, LEGACY_KEY_FILENAME)
        if ok and raw and writefile then
            pcall(writefile, KEY_FILENAME, raw)
        end
    end
    if isfile and readfile and isfile(KEY_FILENAME) then
        local ok, raw = pcall(readfile, KEY_FILENAME)
        if ok and raw then
            return string.match(raw, "^%s*(.-)%s*$") or ""
        end
    end
    return ""
end

local function SaveKey(key)
    if writefile then
        pcall(writefile, KEY_FILENAME, tostring(key))
    end
end

local savedKey = ReadSavedKey()
if string.lower(savedKey) == string.lower(VALID_KEY) then
    getgenv().ToxHasPreviousExecution = true
    getgenv().ToxKeyVerified = true
else
    getgenv().ToxHasPreviousExecution = false
    getgenv().ToxKeyVerified = false

    local keyGui = Instance.new("ScreenGui")
    keyGui.Name = "ToxKeySystemGui"
    keyGui.ResetOnSpawn = false
    keyGui.IgnoreGuiInset = true
    keyGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    keyGui.DisplayOrder = 2147483646
    pcall(function() keyGui.Parent = ToxParentContainer end)

    local blur = Instance.new("BlurEffect")
    blur.Size = 18
    pcall(function() blur.Parent = Lighting end)

    local backdrop = Instance.new("Frame")
    backdrop.Size = UDim2.new(1, 0, 1, 0)
    backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    backdrop.BackgroundTransparency = 0.45
    backdrop.BorderSizePixel = 0
    backdrop.Parent = keyGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 440, 0, 260)
    frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.BackgroundColor3 = Color3.fromRGB(13, 17, 26)
    frame.BorderSizePixel = 0
    frame.Parent = keyGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0, 168, 255)
    stroke.Thickness = 1.2
    stroke.Transparency = 0.35
    stroke.Parent = frame

    local headerLogo = Instance.new("ImageLabel")
    headerLogo.Size = UDim2.new(0, 36, 0, 36)
    headerLogo.Position = UDim2.new(0, 20, 0, 18)
    headerLogo.BackgroundTransparency = 1
    headerLogo.Image = "rbxassetid://10723346959"
    headerLogo.Parent = frame

    local headerTitle = Instance.new("TextLabel")
    headerTitle.Size = UDim2.new(0, 100, 0, 20)
    headerTitle.Position = UDim2.new(0, 64, 0, 16)
    headerTitle.BackgroundTransparency = 1
    headerTitle.Text = "ToxHub"
    headerTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    headerTitle.Font = Enum.Font.GothamBold
    headerTitle.TextSize = 16
    headerTitle.TextXAlignment = Enum.TextXAlignment.Left
    headerTitle.Parent = frame

    local betaBadge = Instance.new("Frame")
    betaBadge.Size = UDim2.new(0, 84, 0, 18)
    betaBadge.Position = UDim2.new(0, 150, 0, 17)
    betaBadge.BackgroundColor3 = Color3.fromRGB(14, 28, 48)
    betaBadge.BorderSizePixel = 0
    betaBadge.Parent = frame
    local bCorner = Instance.new("UICorner") bCorner.CornerRadius = UDim.new(0, 4) bCorner.Parent = betaBadge
    local bStroke = Instance.new("UIStroke") bStroke.Color = Color3.fromRGB(0, 168, 255) bStroke.Thickness = 1 bStroke.Transparency = 0.5 bStroke.Parent = betaBadge

    local bText = Instance.new("TextLabel")
    bText.Size = UDim2.new(1, 0, 1, 0)
    bText.BackgroundTransparency = 1
    bText.Text = "BETA ACCESS"
    bText.TextColor3 = Color3.fromRGB(0, 168, 255)
    bText.Font = Enum.Font.GothamBold
    bText.TextSize = 9
    bText.Parent = betaBadge

    local headerSub = Instance.new("TextLabel")
    headerSub.Size = UDim2.new(1, -80, 0, 16)
    headerSub.Position = UDim2.new(0, 64, 0, 36)
    headerSub.BackgroundTransparency = 1
    headerSub.Text = "Enter your access key to start the script"
    headerSub.TextColor3 = Color3.fromRGB(156, 170, 195)
    headerSub.Font = Enum.Font.GothamMedium
    headerSub.TextSize = 11
    headerSub.TextXAlignment = Enum.TextXAlignment.Left
    headerSub.Parent = frame

    local inputContainer = Instance.new("Frame")
    inputContainer.Size = UDim2.new(1, -40, 0, 42)
    inputContainer.Position = UDim2.new(0, 20, 0, 72)
    inputContainer.BackgroundColor3 = Color3.fromRGB(19, 25, 38)
    inputContainer.BorderSizePixel = 0
    inputContainer.Parent = frame
    local inCorner = Instance.new("UICorner") inCorner.CornerRadius = UDim.new(0, 8) inCorner.Parent = inputContainer
    local inStroke = Instance.new("UIStroke") inStroke.Color = Color3.fromRGB(30, 41, 59) inStroke.Thickness = 1 inStroke.Parent = inputContainer

    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(1, -20, 1, 0)
    textBox.Position = UDim2.new(0, 12, 0, 0)
    textBox.BackgroundTransparency = 1
    textBox.Text = ""
    textBox.PlaceholderText = "Paste your key here... (Tox-BetaUsers)"
    textBox.PlaceholderColor3 = Color3.fromRGB(110, 125, 150)
    textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    textBox.Font = Enum.Font.GothamMedium
    textBox.TextSize = 12
    textBox.TextXAlignment = Enum.TextXAlignment.Left
    textBox.ClearTextOnFocus = false
    textBox.Parent = inputContainer

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, -40, 0, 20)
    statusLabel.Position = UDim2.new(0, 20, 0, 122)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = ""
    statusLabel.TextColor3 = Color3.fromRGB(244, 63, 94)
    statusLabel.Font = Enum.Font.GothamBold
    statusLabel.TextSize = 11
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = frame

    local submitBtn = Instance.new("TextButton")
    submitBtn.Size = UDim2.new(0.55, -16, 0, 38)
    submitBtn.Position = UDim2.new(0, 20, 1, -54)
    submitBtn.BackgroundColor3 = Color3.fromRGB(0, 168, 255)
    submitBtn.BorderSizePixel = 0
    submitBtn.Text = "VALIDATE KEY"
    submitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    submitBtn.Font = Enum.Font.GothamBold
    submitBtn.TextSize = 12
    submitBtn.Parent = frame
    local sCorner = Instance.new("UICorner") sCorner.CornerRadius = UDim.new(0, 8) sCorner.Parent = submitBtn

    local getKeyBtn = Instance.new("TextButton")
    getKeyBtn.Size = UDim2.new(0.45, -20, 0, 38)
    getKeyBtn.Position = UDim2.new(0.55, 6, 1, -54)
    getKeyBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
    getKeyBtn.BorderSizePixel = 0
    getKeyBtn.Text = "GET KEY (DISCORD)"
    getKeyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    getKeyBtn.Font = Enum.Font.GothamBold
    getKeyBtn.TextSize = 11
    getKeyBtn.Parent = frame
    local gCorner = Instance.new("UICorner") gCorner.CornerRadius = UDim.new(0, 8) gCorner.Parent = getKeyBtn

    submitBtn.MouseButton1Click:Connect(function()
        local entered = string.match(textBox.Text or "", "^%s*(.-)%s*$") or ""
        if string.lower(entered) == string.lower(VALID_KEY) then
            statusLabel.TextColor3 = Color3.fromRGB(34, 197, 94)
            statusLabel.Text = "✅ Valid Key! Loading ToxHub..."
            SaveKey(VALID_KEY)
            task.wait(0.35)
            getgenv().ToxKeyVerified = true
            getgenv().ToxHasPreviousExecution = true
            pcall(function()
                if blur then blur:Destroy() end
                keyGui:Destroy()
            end)
        else
            statusLabel.TextColor3 = Color3.fromRGB(244, 63, 94)
            statusLabel.Text = "❌ Invalid Key! Get your key on Discord."
        end
    end)

    getKeyBtn.MouseButton1Click:Connect(function()
        pcall(function()
            if setclipboard then
                setclipboard(DISCORD_URL)
            elseif toclipboard then
                toclipboard(DISCORD_URL)
            end
        end)
        statusLabel.TextColor3 = Color3.fromRGB(56, 189, 248)
        statusLabel.Text = "📋 Discord link copied to clipboard!"
    end)

    repeat
        task.wait(0.1)
    until getgenv().ToxKeyVerified == true or getgenv().Destroyed == true

    if getgenv().Destroyed then
        pcall(function()
            if blur then blur:Destroy() end
            keyGui:Destroy()
        end)
        return
    end
end
