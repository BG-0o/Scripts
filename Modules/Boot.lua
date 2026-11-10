do
    local env = getgenv()
    local current = env.__ToxHubBootLock
    local now = os.clock()
    if typeof(current) == "table"
    and current.Game == game
    and now - (tonumber(current.StartedAt) or now) < 8 then
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
    stroke.Color = Color3.fromRGB(9, 0, 136)
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
        return
    end
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
    getgenv().ToxTACModuleLoadedJobId = nil
    getgenv().ToxTACModuleVersion = nil
    getgenv().ToxTACModulePage = nil
    getgenv().ToxSSModuleLoadedJobId = nil
    getgenv().ToxSSModuleVersion = nil
    getgenv().ToxSSModulePage = nil
    getgenv().ToxMEModuleLoadedJobId = nil
    getgenv().ToxMEModuleVersion = nil
    getgenv().ToxMEModulePage = nil
    getgenv().ToxBINGOModuleLoadedJobId = nil
    getgenv().ToxBINGOModuleVersion = nil
    getgenv().ToxBINGOModulePage = nil
    getgenv().ToxCFModuleLoadedJobId = nil
    getgenv().ToxCFModuleVersion = nil
    getgenv().ToxCFModulePage = nil
    getgenv().ToxADModuleLoadedJobId = nil
    getgenv().ToxADModuleVersion = nil
    getgenv().ToxADModulePage = nil
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
    if getgenv().ToxTACCleanup then
        pcall(getgenv().ToxTACCleanup)
    end
    if getgenv().ToxSSCleanup then
        pcall(getgenv().ToxSSCleanup)
    end
    if getgenv().ToxMECleanup then
        pcall(getgenv().ToxMECleanup)
    end
    if getgenv().ToxBINGOCleanup then
        pcall(getgenv().ToxBINGOCleanup)
    end
    if getgenv().ToxCFCleanup then
        pcall(getgenv().ToxCFCleanup)
    end
    if getgenv().ToxADCleanup then
        pcall(getgenv().ToxADCleanup)
    end
    if getgenv().ScriptConnections then
        for _, conn in ipairs(getgenv().ScriptConnections) do
            pcall(function()
                conn:Disconnect()
            end)
        end
    end
    task.wait(0.25)
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
