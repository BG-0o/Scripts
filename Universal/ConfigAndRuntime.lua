local env = getgenv()
if env.Destroyed or env.ToxUniversalLoaded then
    return
end
env.ToxUniversal = env.ToxUniversal or {}
local U = env.ToxUniversal
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local StatsService = game:GetService("Stats")
local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Settings = env.Settings or {}
local ConfigPage = env.ConfigPage or env.SettingsPage
local Gui = env.Gui
local Main = env.Main
local Tabs = env.Tabs
local NotifGui = env.NotifGui
local ChatLogGui = env.ChatLogGui
local MusicGui = env.MusicGui
local WaypointsGui = env.WaypointsGui
local JoinGamesGui = env.JoinGamesGui
local FOVCircle = env.FOVCircle
local CrosshairH = env.CrosshairH
local CrosshairV = env.CrosshairV
local MAIN_COLOR = env.MAIN_COLOR or Color3.fromRGB(0, 170, 255)
local LOGO_ID = env.LOGO_ID or "rbxassetid://120675082996894"
local ToxUpdateVersion = U.ToxUpdateVersion or "2026-10-19-kick-autoreexec-persist-v10"
local NDSPlaceId = U.NDSPlaceId or 189707

local CreateToggle = env.CreateToggle
local CreateDropdown = env.CreateDropdown
local CreateButton = env.CreateButton
local CreateConfirmButton = env.CreateConfirmButton
local CreateKeybindButton = env.CreateKeybindButton
local function CustomNotify(...) if env.CustomNotify then return env.CustomNotify(...) end end
local function AutoSaveConfiguration(...) if env.AutoSaveConfiguration then return env.AutoSaveConfiguration(...) end end
local function AddConnection(...) if env.AddConnection then return env.AddConnection(...) end end
local function MakeDraggable(...) if env.MakeDraggable then return env.MakeDraggable(...) end end
local function UpdateAirWalk(...) if env.UpdateAirWalk then return env.UpdateAirWalk(...) end end
local function UpdateFullbright(...) if env.UpdateFullbright then return env.UpdateFullbright(...) end end
do
    local SetFPSBooster = U.SetFPSBooster or function() end
if getgenv().CreateSection then getgenv().CreateSection(ConfigPage, "Security & Automation", "🛡️") end
CreateToggle("Chat Logs", ConfigPage, Settings.ChatLogs, function(v)
    Settings.ChatLogs = v
    ChatLogGui.Visible = v == true
end, "ChatLogs")
CreateToggle(
    "Kick Bypass",
    ConfigPage,
    Settings.AntiKick,
    function(v)
        Settings.AntiKick =
            v == true
        AutoSaveConfiguration()
        if Settings.AntiKick then
            CustomNotify(
                "Kick Bypass Enabled • auto rejoin on disconnect",
                Color3.fromRGB(
                    100,
                    255,
                    130
                ),
                4
            )
        end
    end,
    "AntiKick"
)
CreateToggle("Anti AFK", ConfigPage, Settings.AntiAFK, function(v)
    Settings.AntiAFK = v == true
end, "AntiAFK")
CreateToggle("Auto Execute", ConfigPage, Settings.AutoExecute, function(v)
    Settings.AutoExecute = v == true
    if Settings.AutoExecute then
        local queueFunction = getgenv().QueueToxAutoExecute
        if queueFunction and queueFunction() then
            CustomNotify(
                "Auto Execute Enabled",
                Color3.fromRGB(100, 255, 100)
            )
        else
            CustomNotify(
                "Auto Execute is not supported by this executor",
                Color3.fromRGB(255, 180, 70)
            )
        end
    else
        CustomNotify(
            "Auto Execute Disabled",
            Color3.fromRGB(255, 180, 70)
        )
    end
    if getgenv().AutoSaveConfiguration then
        pcall(getgenv().AutoSaveConfiguration)
    end
end, "AutoExecute")
CreateToggle(
    "FPS Booster",
    ConfigPage,
    Settings.FPSBooster,
    function(v)
        SetFPSBooster(
            v
        )
        AutoSaveConfiguration()
    end,
    "FPSBooster"
)
end
do
local ServerInfoFrame = nil
local ServerInfoText = nil
local ServerInfoFrameCount = 0
local ServerInfoLastClock = os.clock()
local ServerInfoFPS = 0
local ServerInfoRegionCache = nil
local ServerInfoRegionCacheTime = 0
local ServerInfoCountryCache = nil
local ServerInfoCountryChecked = false
local ServerInfoModes = {
    "FPS",
    "FPS/Ping",
    "FPS/Ping/Players",
    "Server"
}
RunService.RenderStepped:Connect(function()
    ServerInfoFrameCount = ServerInfoFrameCount + 1
    local now = os.clock()
    if now - ServerInfoLastClock >= 0.5 then
        ServerInfoFPS = math.floor((ServerInfoFrameCount / (now - ServerInfoLastClock)) + 0.5)
        ServerInfoFrameCount = 0
        ServerInfoLastClock = now
    end
end)
local function GetServerPingText()
    local ok, value = pcall(function()
        local network = StatsService and StatsService:FindFirstChild("Network")
        local serverStats = network and network:FindFirstChild("ServerStatsItem")
        local ping = serverStats and serverStats:FindFirstChild("Data Ping")
        if ping and ping.GetValueString then
            return ping:GetValueString()
        end
        return "N/A"
    end)
    if ok and value then
        return tostring(value)
    end
    return "N/A"
end
local function GetServerPingNumber()
    local text = GetServerPingText()
    local number = tonumber(tostring(text):match("([%d%.]+)"))
    return number
end
local function GetShortServerId(value)
    value = tostring(value or "")
    if value == "" then
        return "N/A"
    end
    if #value <= 18 then
        return value
    end
    return string.sub(value, 1, 8) .. "..." .. string.sub(value, -6)
end
local function GetLocalCountryCode()
    if ServerInfoCountryChecked then
        return ServerInfoCountryCache or ""
    end
    ServerInfoCountryChecked = true
    local ok, code = pcall(function()
        local localization = game:GetService("LocalizationService")
        return localization:GetCountryRegionForPlayerAsync(Player)
    end)
    if ok and code and code ~= "" then
        ServerInfoCountryCache = tostring(code)
        return ServerInfoCountryCache
    end
    ServerInfoCountryCache = ""
    return ""
end
local function GetServerRegionText()
    if ServerInfoRegionCache
    and os.clock() - ServerInfoRegionCacheTime < 8 then
        return ServerInfoRegionCache
    end
    local ok, value = pcall(function()
        for _, object in ipairs(StatsService:GetDescendants()) do
            local lower = string.lower(tostring(object.Name or ""))
            if string.find(lower, "region", 1, true)
            or string.find(lower, "location", 1, true)
            or string.find(lower, "country", 1, true) then
                if object.GetValueString then
                    local text = object:GetValueString()
                    if text and text ~= "" then
                        return text
                    end
                end
                if object:IsA("StringValue") and object.Value ~= "" then
                    return object.Value
                end
            end
        end
        return nil
    end)
    if ok and value and tostring(value) ~= "" then
        ServerInfoRegionCache = tostring(value)
        ServerInfoRegionCacheTime = os.clock()
        return ServerInfoRegionCache
    end
    local country = GetLocalCountryCode()
    local ping = GetServerPingNumber()
    local result = nil
    if country == "BR" then
        if ping and ping <= 95 then
            result = "São Paulo / BR"
        elseif ping and ping <= 180 then
            result = "US / NA"
        end
    elseif country == "US" then
        if ping and ping <= 120 then
            result = "US"
        end
    elseif country ~= "" then
        if ping and ping <= 120 then
            result = country
        end
    end
    ServerInfoRegionCache = result or (country ~= "" and country .. " / Unknown" or "Unknown")
    ServerInfoRegionCacheTime = os.clock()
    return ServerInfoRegionCache
end
local function BuildServerJoinText()
    return tostring(game.JobId ~= "" and game.JobId or "N/A")
end
local function CopyServerJoinId()
    local text = BuildServerJoinText()
    local copied = false
    if setclipboard then
        pcall(function()
            setclipboard(text)
            copied = true
        end)
    elseif toclipboard then
        pcall(function()
            toclipboard(text)
            copied = true
        end)
    elseif Clipboard and Clipboard.set then
        pcall(function()
            Clipboard.set(text)
            copied = true
        end)
    end
    if copied then
        CustomNotify(
            "JoinId copied",
            Color3.fromRGB(100, 255, 130),
            3
        )
    else
        CustomNotify(
            "Clipboard not supported",
            Color3.fromRGB(255, 180, 70),
            3
        )
    end
end
local function NormalizeServerInfoMode(value)
    value = tostring(value or "")
    for _, mode in ipairs(ServerInfoModes) do
        if value == mode then
            return mode
        end
    end
    return "FPS/Ping/Players"
end
local function BuildServerInfoLines()
    local mode = NormalizeServerInfoMode(Settings.ToxServerInfoMode)
    local lines = {}
    local fullJobId = tostring(game.JobId ~= "" and game.JobId or "N/A")
    if mode == "Server" then
        table.insert(lines, "Region: " .. GetServerRegionText())
        table.insert(lines, "Players: " .. tostring(#Players:GetPlayers()) .. "/" .. tostring(Players.MaxPlayers))
        table.insert(lines, "PlaceId: " .. tostring(game.PlaceId))
        table.insert(lines, "JobId: " .. fullJobId)
        table.insert(lines, "JoinId: " .. fullJobId)
        return lines
    end
    table.insert(lines, "FPS: " .. tostring(ServerInfoFPS))
    if mode == "FPS/Ping"
    or mode == "FPS/Ping/Players" then
        table.insert(lines, "Ping: " .. GetServerPingText())
    end
    if mode == "FPS/Ping/Players" then
        table.insert(lines, "Players: " .. tostring(#Players:GetPlayers()) .. "/" .. tostring(Players.MaxPlayers))
        table.insert(lines, "Region: " .. GetServerRegionText())
        table.insert(lines, "PlaceId: " .. tostring(game.PlaceId))
        table.insert(lines, "JobId: " .. fullJobId)
        table.insert(lines, "JoinId: " .. fullJobId)
    end
    return lines
end
local function RefreshServerInfoSize()
    if not ServerInfoFrame then
        return
    end
    local mode = NormalizeServerInfoMode(Settings.ToxServerInfoMode)
    local lineCount = #BuildServerInfoLines()
    local width = 250
    if mode == "Server"
    or mode == "FPS/Ping/Players" then
        width = 430
    end
    local height = math.max(92, 40 + lineCount * 19)
    ServerInfoFrame.Size = UDim2.new(0, width, 0, height)
    if ServerInfoText then
        ServerInfoText.Size = UDim2.new(1, -16, 1, -34)
    end
end
local function ServerInfoModeButtonText(mode)
    if mode == "FPS" then
        return "FPS"
    end
    if mode == "FPS/Ping" then
        return "PING"
    end
    if mode == "Server" then
        return "SERVER"
    end
    return "ALL"
end
local function CreateServerInfoFrame()
    if ServerInfoFrame and ServerInfoFrame.Parent then
        return
    end
    local gui = getgenv().Gui
    if not gui then
        return
    end
    local uiTheme = env.Theme
    ServerInfoFrame = Instance.new("Frame")
    ServerInfoFrame.Name = "ToxServerInfoFrame"
    ServerInfoFrame.Size = UDim2.new(0, 430, 0, 174)
    ServerInfoFrame.Position = UDim2.new(1, -340, 0, 110)
    ServerInfoFrame.BackgroundColor3 = (uiTheme and uiTheme.Panel) or Color3.fromRGB(16, 16, 26)
    ServerInfoFrame.BackgroundTransparency = math.clamp(tonumber(Settings.ToxUITransparency) or 0, 0, 0.9)
    ServerInfoFrame.BorderSizePixel = 0
    ServerInfoFrame.Active = true
    ServerInfoFrame.Visible = false
    ServerInfoFrame.Parent = gui
    if env.RegisterThemedObject then
        env.RegisterThemedObject(ServerInfoFrame, "BackgroundColor3", "Panel")
    end
    if env.RegisterTransparentObject then
        env.RegisterTransparentObject(ServerInfoFrame, "Panel")
    end
    if getgenv().ApplySavedGuiPosition then
        getgenv().ApplySavedGuiPosition("ServerInfo", ServerInfoFrame)
    end
    if getgenv().TrackGuiPosition then
        getgenv().TrackGuiPosition("ServerInfo", ServerInfoFrame)
    end
    if getgenv().RegisterToxLinkedSubGui then
        getgenv().RegisterToxLinkedSubGui("ServerInfo", ServerInfoFrame)
    end
    if getgenv().RegisterToxSubGuiMinimize then
        getgenv().RegisterToxSubGuiMinimize(ServerInfoFrame, -52)
    end
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = ServerInfoFrame
    local stroke = Instance.new("UIStroke")
    stroke.Color = (uiTheme and uiTheme.Accent) or MAIN_COLOR
    stroke.Thickness = 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Transparency = 0.25
    stroke.Parent = ServerInfoFrame
    if env.RegisterThemedObject then
        env.RegisterThemedObject(stroke, "Color", "Accent")
    end
    local topBar = Instance.new("Frame")
    topBar.Size = UDim2.new(1, 0, 0, 26)
    topBar.BackgroundColor3 = (uiTheme and uiTheme.Accent) or MAIN_COLOR
    topBar.BackgroundTransparency = 0.15
    topBar.BorderSizePixel = 0
    topBar.Parent = ServerInfoFrame
    if env.RegisterThemedObject then
        env.RegisterThemedObject(topBar, "BackgroundColor3", "Accent")
    end
    local topBarCorner = Instance.new("UICorner")
    topBarCorner.CornerRadius = UDim.new(0, 8)
    topBarCorner.Parent = topBar
    if MakeDraggable then
        MakeDraggable(ServerInfoFrame, topBar)
    end
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -158, 1, 0)
    title.Position = UDim2.new(0, 8, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "SERVER INFO"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 11
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = topBar
    local modeButton = Instance.new("TextButton")
    modeButton.Size = UDim2.new(0, 60, 0, 18)
    modeButton.Position = UDim2.new(1, -148, 0.5, -9)
    modeButton.BackgroundColor3 = (uiTheme and uiTheme.Element) or Color3.fromRGB(24, 24, 34)
    modeButton.BorderSizePixel = 0
    modeButton.Text = ServerInfoModeButtonText(NormalizeServerInfoMode(Settings.ToxServerInfoMode))
    modeButton.TextColor3 = (uiTheme and uiTheme.Text) or Color3.fromRGB(230, 230, 240)
    modeButton.Font = Enum.Font.GothamBold
    modeButton.TextSize = 10
    modeButton.Parent = topBar
    if env.RegisterThemedObject then
        env.RegisterThemedObject(modeButton, "BackgroundColor3", "Element")
        env.RegisterThemedObject(modeButton, "TextColor3", "Text")
    end
    local modeCorner = Instance.new("UICorner")
    modeCorner.CornerRadius = UDim.new(0, 4)
    modeCorner.Parent = modeButton
    local copyButton = Instance.new("TextButton")
    copyButton.Size = UDim2.new(0, 58, 0, 18)
    copyButton.Position = UDim2.new(1, -84, 0.5, -9)
    copyButton.BackgroundColor3 = (uiTheme and uiTheme.Element) or Color3.fromRGB(24, 24, 34)
    copyButton.BorderSizePixel = 0
    copyButton.Text = "COPY"
    copyButton.TextColor3 = (uiTheme and uiTheme.Text) or Color3.fromRGB(230, 230, 240)
    copyButton.Font = Enum.Font.GothamBold
    copyButton.TextSize = 10
    copyButton.Parent = topBar
    if env.RegisterThemedObject then
        env.RegisterThemedObject(copyButton, "BackgroundColor3", "Element")
        env.RegisterThemedObject(copyButton, "TextColor3", "Text")
    end
    local copyCorner = Instance.new("UICorner")
    copyCorner.CornerRadius = UDim.new(0, 4)
    copyCorner.Parent = copyButton
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 22, 0, 18)
    closeButton.Position = UDim2.new(1, -25, 0.5, -9)
    closeButton.BackgroundColor3 = (uiTheme and uiTheme.Element) or Color3.fromRGB(24, 24, 34)
    closeButton.BorderSizePixel = 0
    closeButton.Text = "X"
    closeButton.TextColor3 = (uiTheme and uiTheme.Text) or Color3.fromRGB(230, 230, 240)
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 10
    closeButton.Parent = topBar
    if env.RegisterThemedObject then
        env.RegisterThemedObject(closeButton, "BackgroundColor3", "Element")
        env.RegisterThemedObject(closeButton, "TextColor3", "Text")
    end
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 4)
    closeCorner.Parent = closeButton
    ServerInfoText = Instance.new("TextLabel")
    ServerInfoText.Size = UDim2.new(1, -16, 1, -34)
    ServerInfoText.Position = UDim2.new(0, 8, 0, 31)
    ServerInfoText.BackgroundTransparency = 1
    ServerInfoText.Text = ""
    ServerInfoText.TextColor3 = (uiTheme and uiTheme.Text) or Color3.fromRGB(240, 240, 245)
    ServerInfoText.Font = Enum.Font.GothamMedium
    ServerInfoText.TextSize = 12
    ServerInfoText.TextWrapped = false
    ServerInfoText.TextTruncate = Enum.TextTruncate.None
    ServerInfoText.TextXAlignment = Enum.TextXAlignment.Left
    ServerInfoText.TextYAlignment = Enum.TextYAlignment.Top
    ServerInfoText.Parent = ServerInfoFrame
    if env.RegisterThemedObject then
        env.RegisterThemedObject(ServerInfoText, "TextColor3", "Text")
    end
    copyButton.MouseButton1Click:Connect(function()
        CopyServerJoinId()
    end)
    closeButton.MouseButton1Click:Connect(function()
        Settings.ToxServerInfoVisible = false
        ServerInfoFrame.Visible = false
        if getgenv().SyncToggleVisuals then
            getgenv().SyncToggleVisuals("ToxServerInfoVisible", false)
        end
        AutoSaveConfiguration()
    end)
    modeButton.MouseButton1Click:Connect(function()
        local mode = NormalizeServerInfoMode(Settings.ToxServerInfoMode)
        local index = 1
        for i, item in ipairs(ServerInfoModes) do
            if item == mode then
                index = i
                break
            end
        end
        index = index + 1
        if index > #ServerInfoModes then
            index = 1
        end
        Settings.ToxServerInfoMode = ServerInfoModes[index]
        modeButton.Text = ServerInfoModeButtonText(Settings.ToxServerInfoMode)
        RefreshServerInfoSize()
        AutoSaveConfiguration()
    end)
    task.spawn(function()
        while ServerInfoFrame and ServerInfoFrame.Parent and not getgenv().Destroyed do
            if ServerInfoFrame.Visible and ServerInfoText then
                local lines = BuildServerInfoLines()
                ServerInfoText.Text = table.concat(lines, "\n")
                RefreshServerInfoSize()
            end
            task.wait(0.5)
        end
    end)
end
local function SetServerInfoVisible(enabled)
    Settings.ToxServerInfoVisible = enabled == true
    CreateServerInfoFrame()
    if ServerInfoFrame then
        ServerInfoFrame.Visible = Settings.ToxServerInfoVisible
        RefreshServerInfoSize()
    end
end
getgenv().OpenToxServerInfo = function()
    SetServerInfoVisible(not Settings.ToxServerInfoVisible)
    if getgenv().SyncToggleVisuals then
        getgenv().SyncToggleVisuals("ToxServerInfoVisible", Settings.ToxServerInfoVisible)
    end
    AutoSaveConfiguration()
end
    U.SetServerInfoVisible = SetServerInfoVisible
end
do
    local SetRender3DEnabled = U.SetRender3DEnabled or function() end
    local SetRender3DColor = U.SetRender3DColor or function() end
if getgenv().CreateSection then getgenv().CreateSection(ConfigPage, "Rendering & Performance", "⚡") end
SetRender3DEnabled(true)
CreateToggle(
    "3D Rendering",
    ConfigPage,
    Settings.Render3DDisabled == true,
    function(v)
        local disabled = v == true
        Settings.Render3DDisabled = disabled
        Settings.No3DRender = disabled
        SetRender3DEnabled(
            not disabled
        )
        if getgenv().SyncToggleVisuals then
            pcall(getgenv().SyncToggleVisuals, "No3DRender", disabled)
        end
        AutoSaveConfiguration()
    end,
    "Render3DDisabled"
)
CreateDropdown(
    "3D Background",
    {
        "WHITE",
        "BLACK",
        "RED",
        "BLUE"
    },
    ConfigPage,
    Settings.Render3DColor,
    function(value)
        SetRender3DColor(
            value
        )
        AutoSaveConfiguration()
    end
)
end
do
if getgenv().CreateSection then getgenv().CreateSection(ConfigPage, "Interface & Keybinds", "⚙️") end
CreateDropdown(
    "GUI Color",
    {
        "Blue",
        "Cyan",
        "Purple",
        "Green",
        "Red",
        "Orange",
        "Pink",
        "Gold",
        "White"
    },
    ConfigPage,
    tostring(
        Settings.GUIColorName
        or "Blue"
    ),
    function(value)
        Settings.GUIColorName =
            value
        if getgenv().SetToxGuiColor then
            getgenv().SetToxGuiColor(
                value
            )
        end
    end
)
CreateDropdown(
    "UI Theme",
    {
        "Dark Neon",
        "OLED Black",
        "Clean White",
        "Translucent Glass",
        "Midnight Purple",
        "Cyberpunk Cyan"
    },
    ConfigPage,
    tostring(Settings.ToxUITheme or "Dark Neon"),
    function(value)
        Settings.ToxUITheme = value
        if getgenv().SetToxUITheme then
            getgenv().SetToxUITheme(value)
        end
        if getgenv().AutoSaveConfiguration then
            getgenv().AutoSaveConfiguration()
        end
    end
)
CreateButton("🎨 Custom Accent (Color Picker)", ConfigPage, function()
    local ui = getgenv().ToxUI
    local opener = (ui and ui.OpenColorPicker) or getgenv().OpenToxColorPicker
    if opener then
        opener("Accent")
    end
end)
CreateToggle("UI Rainbow (All Colors)", ConfigPage, Settings.UIRainbow == true, function(val)
    Settings.UIRainbow = val == true
    if not val and getgenv().ApplyToxTheme then
        getgenv().ApplyToxTheme()
    end
end, "UIRainbow")
if getgenv().CreateSlider then
    getgenv().CreateSlider("UI Rainbow Speed", ConfigPage, 1, 100, math.floor(tonumber(Settings.UIRainbowSpeed) or 35), "%", function(val)
        Settings.UIRainbowSpeed = val
    end, "UIRainbowSpeedPct")
    getgenv().CreateSlider("UI Transparency", ConfigPage, 0, 100, math.floor((tonumber(Settings.ToxUITransparency) or 0) * 100 + 0.5), "%", function(val, isDragging)
        if getgenv().SetToxUITransparency then
            getgenv().SetToxUITransparency(val / 100, isDragging == true)
        end
    end, "UITransparencyPct")
end
CreateKeybindButton("GUI Keybind", ConfigPage, Settings.GUIKeybind, function(key)
    Settings.GUIKeybind = key
    if getgenv().AutoSaveConfiguration then
        getgenv().AutoSaveConfiguration()
    end
end)
CreateKeybindButton("Panic Key", ConfigPage, Settings.PanicKey, function(key)
    Settings.PanicKey = key
    if getgenv().AutoSaveConfiguration then
        getgenv().AutoSaveConfiguration()
    end
end)
CreateToggle("Keybinds", ConfigPage, Settings.ShowToxBinds == true, function(value)
    if getgenv().SetShowToxBinds then
        getgenv().SetShowToxBinds(value == true)
    else
        Settings.ShowToxBinds = value == true
    end
    if getgenv().AutoSaveConfiguration then
        getgenv().AutoSaveConfiguration()
    end
end, "ShowToxBinds")
CreateToggle("Keybinds List", ConfigPage, Settings.KeybindsList, function(v)
    Settings.KeybindsList = v == true
    if getgenv().ToxKeybindsFrame then
        getgenv().ToxKeybindsFrame.Visible = Settings.KeybindsList
    end
end, "KeybindsList")
CreateToggle("Spectator List", ConfigPage, Settings.SpectatorList, function(v)
    Settings.SpectatorList = v == true
    if getgenv().ToxSpectatorsFrame then
        getgenv().ToxSpectatorsFrame.Visible = Settings.SpectatorList
    end
end, "SpectatorList")
CreateToggle("Start Hidden", ConfigPage, Settings.StartHidden, function(value)
    Settings.StartHidden = value == true
    if getgenv().AutoSaveConfiguration then
        getgenv().AutoSaveConfiguration()
    end
end, "StartHidden")
CreateToggle("Unlock Cursor", ConfigPage, Settings.UnlockCursor, function(value)
    Settings.UnlockCursor = value == true
    if getgenv().SetUnlockCursor then
        getgenv().SetUnlockCursor(value)
    end
    if getgenv().AutoSaveConfiguration then
        getgenv().AutoSaveConfiguration()
    end
end, "UnlockCursor")
end
do
if getgenv().CreateSection then getgenv().CreateSection(ConfigPage, "Game Configuration & Profiles", "\xf0\x9f\x92\xbe") end
local placeKeyStr = tostring(game.PlaceId)
local resolvedMod = getgenv().CurrentGameModule
if not resolvedMod and type(getgenv().ResolveCurrentGameModule) == "function" then
    local okMod, mod = pcall(getgenv().ResolveCurrentGameModule)
    if okMod and mod then
        resolvedMod = mod
    end
end
local gameName = (resolvedMod and resolvedMod.GameName and resolvedMod.ShortName and (resolvedMod.GameName .. " (" .. resolvedMod.ShortName .. ")"))
    or (resolvedMod and (resolvedMod.ShortName or resolvedMod.GameName))
    or ((game.GameId == 142823291 or game.PlaceId == 142823291) and "MM2")
    or (game.PlaceId == 189707 and "NDS")
    or (game.PlaceId == 537413528 and "BABFT")
    or (game.PlaceId == 109440485612336 and "WID")
    or (game.PlaceId == 4522347649 and "ADMIN")
    or (game.PlaceId == 662417684 and "LBB")
    or (game.PlaceId == 893973440 and "FTF")
    or (game.PlaceId == 155615604 and "PL")
    or (game.PlaceId == 70650894743738 and "BE")
    or (game.PlaceId == 119925538689885 and "SOD")
    or (game.PlaceId == 131479356121251 and "50 Player BINGO! (BINGO)")
    or (game.PlaceId == 137233438285284 and "Chicken Farm (CF)")
    or ("Place " .. placeKeyStr)
local function GetSaveStatusText()
    local hasSave = (getgenv().HasSavedConfigForCurrentPlace and getgenv().HasSavedConfigForCurrentPlace())
        or getgenv().ToxHasPlaceConfig == true
    return hasSave and "[Saved]" or "[Default / Unsaved]"
end
local saveStatusLabel = nil
saveStatusLabel = CreateButton("Game: " .. gameName .. " " .. GetSaveStatusText(), ConfigPage, function(btn)
    btn.Text = "Game: " .. gameName .. " " .. GetSaveStatusText()
end)
if not resolvedMod and string.sub(gameName, 1, 6) == "Place " then
    task.spawn(function()
        pcall(function()
            local info = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
            if info and info.Name and info.Name ~= "" then
                gameName = info.Name
                if saveStatusLabel and saveStatusLabel.Parent then
                    saveStatusLabel.Text = "Game: " .. gameName .. " " .. GetSaveStatusText()
                end
            end
        end)
    end)
end
CreateButton("\xf0\x9f\x92\xbe Save Game Config", ConfigPage, function(button)
    if getgenv().SavePlaceConfiguration then
        local ok = getgenv().SavePlaceConfiguration()
        if ok ~= false then
            button.Text = "\xe2\x9c\x93 Config Saved!"
            if saveStatusLabel then saveStatusLabel.Text = "Game: " .. gameName .. " [Saved]" end
            task.delay(2, function()
                button.Text = "\xf0\x9f\x92\xbe Save Game Config"
            end)
        else
            button.Text = "Save Failed"
            task.delay(2, function()
                button.Text = "\xf0\x9f\x92\xbe Save Game Config"
            end)
        end
    end
end)
CreateButton("\xf0\x9f\x94\x84 Load Game Config", ConfigPage, function(button)
    if getgenv().LoadPlaceConfiguration then
        local loaded = getgenv().LoadPlaceConfiguration()
        if loaded then
            button.Text = "\xe2\x9c\x93 Config Loaded!"
            if saveStatusLabel then saveStatusLabel.Text = "Game: " .. gameName .. " [Saved]" end
            task.delay(2, function()
                button.Text = "\xf0\x9f\x94\x84 Load Game Config"
            end)
        else
            button.Text = "No Save Found"
            task.delay(2, function()
                button.Text = "\xf0\x9f\x94\x84 Load Game Config"
            end)
        end
    end
end)
CreateConfirmButton("\xf0\x9f\x97\x91\xef\xb8\x8f Reset Game Config", ConfigPage, function()
    if getgenv().ResetPlaceConfiguration then
        getgenv().ResetPlaceConfiguration()
        if saveStatusLabel then saveStatusLabel.Text = "Game: " .. gameName .. " [Default / Unsaved]" end
    end
end)
CreateToggle("Auto-Save Game Config", ConfigPage, getgenv().ToxAutoSaveEnabled == true, function(val)
    getgenv().ToxAutoSaveEnabled = val == true
    if val and getgenv().AutoSaveConfiguration then
        getgenv().AutoSaveConfiguration(true)
        if saveStatusLabel then saveStatusLabel.Text = "Game: " .. gameName .. " [Saved]" end
    end
end, "ToxAutoSaveEnabled")
end
getgenv().SyncAllTogglesToUI = function()
    if getgenv().SyncToggleVisuals then
        for k, v in pairs(Settings) do
            if typeof(v) == "boolean" then
                pcall(getgenv().SyncToggleVisuals, k, v)
            end
        end
    end
end
do
    local SetServerInfoVisible = U.SetServerInfoVisible or function() end
    local ShowServerHopMenu = U.ShowServerHopMenu or function() end
if getgenv().CreateSection then getgenv().CreateSection(ConfigPage, "Server Operations", "🌐") end
CreateToggle("Server Info", ConfigPage, Settings.ToxServerInfoVisible, function(v)
    SetServerInfoVisible(v)
    AutoSaveConfiguration()
end, "ToxServerInfoVisible")
CreateButton("Server Hop", ConfigPage, function(button) ShowServerHopMenu(button) end)
CreateConfirmButton("Rejoin Server", ConfigPage, function()
    if getgenv().AllowToxTeleport then
        getgenv().AllowToxTeleport(15, "Rejoin")
    end
	if #Players:GetPlayers() <= 1 then TeleportService:Teleport(game.PlaceId, Player)
	else TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Player) end
end)
end
do
    local SetFPSBooster = U.SetFPSBooster or function() end
    local StopWalkFling = U.StopWalkFling or function() end
    local StopAntiVoid = U.StopAntiVoid or function() end
    local DestroyCarFlyMovers = U.DestroyCarFlyMovers or function() end
    local RestoreSpeed = U.RestoreSpeed or function() end
    local RestoreJump = U.RestoreJump or function() end
    local RestoreNoclipDefaults = U.RestoreNoclipDefaults or function() end
    local RestoreAntiFlingDefaults = U.RestoreAntiFlingDefaults or function() end
    local RestoreHitboxDefaults = U.RestoreHitboxDefaults or function() end
    local RestoreFOVDefault = U.RestoreFOVDefault or function() end
    local RestoreShiftLockDefaults = U.RestoreShiftLockDefaults or function() end
CreateConfirmButton("DESTROY", ConfigPage, function()
    if AutoSaveConfiguration then
        pcall(AutoSaveConfiguration)
    end
    U.LoopFlingInput = nil
    U.LoopFlingGeneration = (U.LoopFlingGeneration or 0) + 1
    if U.RenderBackdropGui and U.RenderBackdropGui.Parent then
        pcall(function()
            U.RenderBackdropGui:
                Destroy()
        end)
    end
    env.Destroyed = true
    getgenv().Destroyed = true
    env.ScriptLoaded = false
    getgenv().ScriptLoaded = false
    getgenv().ToxOptionsReady = false
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
    if getgenv().ToxBINGOCleanup then
        pcall(getgenv().ToxBINGOCleanup)
    end
    if getgenv().ToxCFCleanup then
        pcall(getgenv().ToxCFCleanup)
    end
    if getgenv().SetNDSWaterFly then
        pcall(function()
            getgenv().SetNDSWaterFly(false, true)
        end)
    end
    if getgenv().SetNDSNoTP then
        pcall(function()
            getgenv().SetNDSNoTP(false, true)
        end)
    end
    SetFPSBooster(
        false,
        true
    )
    for key, value in pairs(Settings) do
        if typeof(value) == "boolean" then
            Settings[key] = false
        end
    end
    Settings.Render3D = true
    Settings.LoopTPTarget = nil
    Settings.NDSAutoWin = false
    Settings.NDSWaterFly = false
    Settings.NDSNoTP = false
    Settings.MM2AutoFarm = false
    Settings.MM2RoleESP = false
    Settings.MM2KillAllAuto = false
    Settings.MM2ShootMurderAuto = false
    Settings.MM2GrabGunAuto = false
    local sharedKeys =
        getgenv().SharedPersistentKeys or {}
    local baseShared =
        getgenv().BaseSharedSettings or {}
    for key in pairs(sharedKeys) do
        if typeof(Settings[key]) == "boolean" then
            Settings[key] = false
        end
        if typeof(baseShared[key]) == "boolean" then
            baseShared[key] = false
        end
    end
    pcall(function()
        RunService:Set3dRenderingEnabled(true)
    end)
    Settings.Fullbright = false
    UpdateFullbright()
    Settings.AirWalk = false
    Settings.AirWalkPlatform = false
    pcall(function()
        local p = workspace:FindFirstChild("ToxAirPlatform")
        if p then p:Destroy() end
    end)
    UpdateAirWalk()
    Settings.Speed = false
    Settings.Jump = false
    Settings.Noclip = false
    Settings.AntiFling = false
    Settings.WalkFling = false
    StopWalkFling()
    StopAntiVoid()
    if getgenv().ToxSystemsCleanup then
        pcall(
            getgenv().ToxSystemsCleanup
        )
    end
    Settings.HitboxExpander = false
    Settings.FOVEnabled = false
    Settings.ForceShiftLock = false
    Settings.SmoothFly = false
    Settings.NormalFly = false
    Settings.FlyBypass = false
    Settings.CarFly = false
    if FlyBypassFloor then pcall(function() FlyBypassFloor:Destroy() end) FlyBypassFloor = nil end
    DestroyCarFlyMovers()
    Settings.ChatLogs = false
    Settings.MusicAutoPlay = false
    Settings.MusicLoop = false
    Settings.AutoExecute = false
    RestoreSpeed()
    RestoreJump()
    RestoreNoclipDefaults()
    RestoreAntiFlingDefaults()
    RestoreHitboxDefaults()
    RestoreFOVDefault()
    RestoreShiftLockDefaults()
    if U.SetShiftLockActive then U.SetShiftLockActive(false) end
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    if ChatLogGui then
        ChatLogGui.Visible = false
    end
    local Hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
    local Root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if Hum then
        Hum.PlatformStand = false
        Hum.Sit = false
        Hum.AutoRotate = true
    end
    if Root then
        Root.AssemblyLinearVelocity = Vector3.zero
        Root.AssemblyAngularVelocity = Vector3.zero
    end
    RunService.Heartbeat:Wait()
    RunService.Heartbeat:Wait()
    if getgenv().ActiveSound then
        pcall(function()
            getgenv().ActiveSound:Stop()
            getgenv().ActiveSound:Destroy()
        end)
        getgenv().ActiveSound = nil
    end
    local clr = getgenv().ClearAllESPVisuals or getgenv().ClearAllToxESPVisuals
    if type(clr) == "function" then
        pcall(clr)
    end
    if FOVCircle then
        pcall(function()
            FOVCircle:Remove()
        end)
    end
    if CrosshairH then
        pcall(function()
            CrosshairH:Remove()
        end)
    end
    if CrosshairV then
        pcall(function()
            CrosshairV:Remove()
        end)
    end
    for _, conn in ipairs(env.ScriptConnections or {}) do
        pcall(function()
            conn:Disconnect()
        end)
    end
    pcall(function()
        NotifGui:Destroy()
    end)
    pcall(function()
        Gui:Destroy()
    end)
end)
if getgenv().ClearActivePageCard then
    pcall(getgenv().ClearActivePageCard, ConfigPage)
end
end
do
    local CaptureShiftLockDefaults = U.CaptureShiftLockDefaults or function() end
    local CaptureFOVDefault = U.CaptureFOVDefault or function() end
    local GetHumanoidDefaults = U.GetHumanoidDefaults or function() end
    local StartWalkFling = U.StartWalkFling or function() end
    local EnsureCarFlyMovers = U.EnsureCarFlyMovers or function() return false end
    local DestroyCarFlyMovers = U.DestroyCarFlyMovers or function() end
    local GetCarFlyMoveVector = U.GetCarFlyMoveVector or function() return Vector3.zero end
    local GetClosestPlayerToMouse = U.GetClosestPlayerToMouse or function() return nil end
    local HumanoidDefaults = U.HumanoidDefaults or {}
    local NoclipDefaults = U.NoclipDefaults or {}
    local AntiFlingDefaults = U.AntiFlingDefaults or {}
    local HitboxDefaults = U.HitboxDefaults or {}
AddConnection(UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and Settings.ForceShiftLock then
        local key = Settings.ShiftLockKey
        local match = false
        if key == "Shift" and (input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift) then
            match = true
        elseif key == "Ctrl" and (input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl) then
            match = true
        end
        if match then
            U.SetShiftLockActive(not U.GetShiftLockActive())
            UserInputService.MouseBehavior = U.GetShiftLockActive() and Enum.MouseBehavior.LockCenter or Enum.MouseBehavior.Default
        end
    end
end))
AddConnection(UserInputService.JumpRequest:Connect(function()
    local Hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
    if env.ScriptLoaded and Settings.InfiniteJump and Hum and Hum.Health > 0 then
        Hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end))
env.SubGuisPreKeyHiddenState = {}
local function IsBadCtrlClickTeleportPart(part)
    if part and part:IsA("Terrain") then
        return false
    end
    if not part
    or not part:IsA("BasePart") then
        return true
    end
    local lower = string.lower(tostring(part.Name or "") .. " " .. tostring(part.Parent and part.Parent.Name or ""))
    if string.find(lower, "barrier", 1, true)
    or string.find(lower, "invisible", 1, true)
    or string.find(lower, "kill", 1, true)
    or string.find(lower, "void", 1, true)
    or string.find(lower, "death", 1, true) then
        return true
    end
    if part.Transparency >= 0.985
    and not part.CanCollide then
        return true
    end
    return false
end
local function GetCtrlClickTeleportOffset(root, humanoid, normal)
    local standHeight =
        math.max(
            2.5,
            (root.Size.Y * 0.5)
            + (humanoid and humanoid.HipHeight or 2)
            + 0.15
        )
    if normal.Y >= 0.55 then
        return Vector3.new(
            0,
            standHeight,
            0
        )
    end
    local sideClearance =
        math.max(
            root.Size.X,
            root.Size.Z
        ) * 0.5 + 0.65
    return normal.Unit * sideClearance
end
local function GetCtrlClickTeleportCFrame()
    local mouse = Player:GetMouse()
    local character = Player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not mouse or not root then
        return nil
    end

    local excluded = {}
    if character then table.insert(excluded, character) end
    if getgenv().Gui then table.insert(excluded, getgenv().Gui) end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = excluded
    params.IgnoreWater = false

    local camera = workspace.CurrentCamera or Camera
    if not camera then return nil end

    local ray = camera:ScreenPointToRay(mouse.X, mouse.Y)
    local result = nil
    for _ = 1, 12 do
        result = workspace:Raycast(ray.Origin, ray.Direction * 5000, params)
        if not result or not result.Instance then
            break
        end
        local hit = result.Instance
        local passThrough = hit:IsA("BasePart") and (not hit.CanCollide or IsBadCtrlClickTeleportPart(hit))
        if hit:IsA("Terrain") or not passThrough then
            break
        end
        table.insert(excluded, hit)
        params.FilterDescendantsInstances = excluded
        result = nil
    end

    if not result or not result.Instance or IsBadCtrlClickTeleportPart(result.Instance) then
        if mouse.Target and not IsBadCtrlClickTeleportPart(mouse.Target) and mouse.Hit then
            local standH = math.max(3, (humanoid and humanoid.HipHeight or 2) + 1.5)
            local _, yaw, _ = root.CFrame:ToOrientation()
            return CFrame.new(mouse.Hit.Position + Vector3.new(0, standH, 0)) * CFrame.Angles(0, yaw, 0)
        end
        return nil
    end

    local normal = result.Normal
    if normal.Magnitude <= 0 then
        normal = Vector3.new(0, 1, 0)
    end

    local targetPosition = result.Position + GetCtrlClickTeleportOffset(root, humanoid, normal)
    local _, yaw, _ = root.CFrame:ToOrientation()
    return CFrame.new(targetPosition) * CFrame.Angles(0, yaw, 0)
end

local isCtrlHeld = false
local lastCtrlTpTick = 0

AddConnection(UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
        isCtrlHeld = true
    end
end))

AddConnection(UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
        isCtrlHeld = false
    end
end))

local function IsMouseOverToxGui()
    local gui = getgenv().Gui
    if not gui or not gui.Parent then return false end
    local main = gui:FindFirstChild("MainFrame") or gui:FindFirstChild("Main") or gui:FindFirstChildWhichIsA("Frame")
    if not main or not main.Visible then return false end
    local mouseLoc = UserInputService:GetMouseLocation()
    local absPos = main.AbsolutePosition
    local absSize = main.AbsoluteSize
    if mouseLoc.X >= absPos.X and mouseLoc.X <= absPos.X + absSize.X
    and mouseLoc.Y >= absPos.Y and mouseLoc.Y <= absPos.Y + absSize.Y then
        return true
    end
    return false
end

local function ExecuteCtrlClickTeleport()
    if not Settings.CtrlClickTP then return end
    local ctrlActive = isCtrlHeld
        or UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
        or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
    if not ctrlActive then return end
    if IsMouseOverToxGui() then return end
    if tick() - lastCtrlTpTick < 0.2 then return end
    lastCtrlTpTick = tick()

    local root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local targetCFrame = GetCtrlClickTeleportCFrame()
    if not targetCFrame then return end

    if getgenv().AllowToxTeleport then
        getgenv().AllowToxTeleport(2, "Ctrl Click TP")
    end
    if getgenv().SetNDSNoTPAnchor then
        pcall(getgenv().SetNDSNoTPAnchor, targetCFrame, true)
    end
    if getgenv().ToxSafeTeleportToCFrame then
        getgenv().ToxSafeTeleportToCFrame(
            targetCFrame,
            false,
            "Ctrl Click TP"
        )
    else
        if getgenv().RecordToxTeleportReturn then
            getgenv().RecordToxTeleportReturn()
        end
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        if Player.Character then
            Player.Character:PivotTo(targetCFrame)
        else
            root.CFrame = targetCFrame
        end
    end
end

pcall(function()
    local mouse = Player:GetMouse()
    if mouse then
        AddConnection(mouse.Button1Down:Connect(function()
            ExecuteCtrlClickTeleport()
        end))
    end
end)

AddConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        ExecuteCtrlClickTeleport()
    end
    local isGuiKey = false
    if typeof(Settings.GUIKeybind) == "EnumItem" then
        isGuiKey = (input.KeyCode == Settings.GUIKeybind)
    elseif typeof(Settings.GUIKeybind) == "string" then
        isGuiKey = (input.KeyCode.Name == Settings.GUIKeybind)
    end
    if isGuiKey then
        if getgenv().ToggleToxGui then
            return
        end
        if Main.Visible then
            env.SubGuisPreKeyHiddenState.ChatLog = ChatLogGui.Visible
            env.SubGuisPreKeyHiddenState.Music = MusicGui.Visible
            env.SubGuisPreKeyHiddenState.Waypoints = WaypointsGui.Visible
            env.SubGuisPreKeyHiddenState.QuickJoin = JoinGamesGui and JoinGamesGui.Visible or false
            Main.Visible = false
            ChatLogGui.Visible = false
            MusicGui.Visible = false
            WaypointsGui.Visible = false
            if JoinGamesGui then JoinGamesGui.Visible = false end
            for key, gui in pairs(getgenv().ToxLinkedSubGuis or {}) do
                if gui and gui.Parent then
                    env.SubGuisPreKeyHiddenState["Extra_" .. tostring(key)] = gui.Visible
                    gui.Visible = false
                end
            end
        else
            Main.Visible = true
            if Tabs.Visible then
                if env.SubGuisPreKeyHiddenState.ChatLog ~= nil then
                    ChatLogGui.Visible = env.SubGuisPreKeyHiddenState.ChatLog
                end
                if env.SubGuisPreKeyHiddenState.Music ~= nil then
                    MusicGui.Visible = env.SubGuisPreKeyHiddenState.Music
                end
                if env.SubGuisPreKeyHiddenState.Waypoints ~= nil then
                    WaypointsGui.Visible = env.SubGuisPreKeyHiddenState.Waypoints
                end
                if JoinGamesGui and env.SubGuisPreKeyHiddenState.QuickJoin ~= nil then
                    JoinGamesGui.Visible = env.SubGuisPreKeyHiddenState.QuickJoin
                end
                for key, gui in pairs(getgenv().ToxLinkedSubGuis or {}) do
                    local saved = env.SubGuisPreKeyHiddenState["Extra_" .. tostring(key)]
                    if gui and gui.Parent and saved ~= nil then
                        gui.Visible = saved
                    end
                end
            else
                ChatLogGui.Visible = false
                MusicGui.Visible = false
                WaypointsGui.Visible = false
                    if JoinGamesGui then JoinGamesGui.Visible = false end
            end
        end
    end
end))
if Settings.WalkFling then
    StartWalkFling()
end
AddConnection(Player.Idled:Connect(function()
    if env.ScriptLoaded and Settings.AntiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end))
AddConnection(RunService.Stepped:Connect(function()
    if env.Destroyed then return end
    if not env.ScriptLoaded then
        if Settings.AntiFling then
            for _, p in ipairs(
                Players:GetPlayers()
            ) do
                if p ~= Player
                and p.Character then
                    for _, part in ipairs(
                        p.Character:GetChildren()
                    ) do
                        if part:IsA(
                            "BasePart"
                        ) then
                            if AntiFlingDefaults[part]
                            == nil then
                                AntiFlingDefaults[part] =
                                    part.CanCollide
                            end
                            part.CanCollide = false
                        end
                    end
                end
            end
        end
        return
    end
    if Settings.Noclip and Player.Character then
        for _, part in ipairs(Player.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                if NoclipDefaults[part] == nil then
                    NoclipDefaults[part] = part.CanCollide
                end
                part.CanCollide = false
            end
        end
    end
    if Settings.AntiFling then
        if Settings.WalkFling then
            local root =
                Player.Character
                and Player.Character:
                    FindFirstChild(
                        "HumanoidRootPart"
                    )
            if root
            and not (U.GetWalkFlingImpulseActive and U.GetWalkFlingImpulseActive())
            and root.AssemblyLinearVelocity.Magnitude
                > 350 then
                root.AssemblyLinearVelocity =
                    Vector3.zero
                root.AssemblyAngularVelocity =
                    Vector3.zero
            end
        else
            for _, p in ipairs(
                Players:GetPlayers()
            ) do
                if p ~= Player
                and p.Character then
                    for _, part in ipairs(
                        p.Character:GetChildren()
                    ) do
                        if part:IsA(
                            "BasePart"
                        ) then
                            if AntiFlingDefaults[part]
                            == nil then
                                AntiFlingDefaults[part] =
                                    part.CanCollide
                            end
                            part.CanCollide = false
                        end
                    end
                end
            end
        end
    end
    local Root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if Settings.NoFallDamage and Root then
        local velocity = Root.AssemblyLinearVelocity
        local maxFall = getgenv().ToxGetNoFallMaxSpeed and getgenv().ToxGetNoFallMaxSpeed()
            or (15 + math.clamp(tonumber(Settings.NoFallSpeed) or 50, 0, 100) * 0.85)
        if velocity.Y < -maxFall then
            Root.AssemblyLinearVelocity = Vector3.new(velocity.X, -maxFall, velocity.Z)
        end
    end
    UpdateAirWalk()
    if Settings.Fullbright then UpdateFullbright() end
end))
local FlyBV = nil
local FlyBG = nil
local FlyBypassFloor = nil
local FlyBypassY = nil
local FlyBypassCharacter = nil
local function DisableNormalFlyPhysics()
    local Hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
    if FlyBV then FlyBV:Destroy() FlyBV = nil end
    if FlyBG then FlyBG:Destroy() FlyBG = nil end
    if FlyBypassFloor then pcall(function() FlyBypassFloor:Destroy() end) FlyBypassFloor = nil end
    if Hum then Hum.PlatformStand = false end
end
AddConnection(RunService.RenderStepped:Connect(function(delta)
	if env.Destroyed or not env.ScriptLoaded then return end
    local Hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
    local Root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if Hum and Hum.Health > 0 then
        local defaults = GetHumanoidDefaults(Hum)
        if Settings.Speed then
            Hum.WalkSpeed = Settings.SpeedValue
        end
        if Settings.Jump then
            Hum.UseJumpPower = true
            Hum.JumpPower = Settings.JumpValue
        elseif defaults and HumanoidDefaults[Hum] == defaults then
            if Hum.UseJumpPower ~= defaults.UseJumpPower and not Settings.Jump then
                Hum.UseJumpPower = defaults.UseJumpPower
                Hum.JumpPower = defaults.JumpPower
                Hum.JumpHeight = defaults.JumpHeight
            end
        end
        if Settings.Bhop then
            local interval = math.max(0.05, tonumber(Settings.BhopInterval) or 0.2)
            getgenv().BhopTimer = (getgenv().BhopTimer or 0) + delta
            if getgenv().BhopTimer >= interval and (Hum.FloorMaterial ~= Enum.Material.Air or Hum:GetState() == Enum.HumanoidStateType.Landed) then
                getgenv().BhopTimer = 0
                Hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        else
            getgenv().BhopTimer = 0
        end
    end
    if Settings.FOVEnabled then
        CaptureFOVDefault()
        Camera.FieldOfView = Settings.FOVValue or (U.GetFOVDefault and U.GetFOVDefault() or 70)
    end
    if Settings.ForceShiftLock then
        CaptureShiftLockDefaults()
        Player.DevEnableMouseLock = true
        if U.GetShiftLockActive() and Root then
            Camera.CFrame = Camera.CFrame * CFrame.new(1.7, 0.5, 0)
            Root.CFrame = CFrame.new(Root.Position, Root.Position + Vector3.new(Camera.CFrame.LookVector.X, 0, Camera.CFrame.LookVector.Z))
        end
    end
    if Settings.LoopTPTarget and Settings.LoopTPTarget.Character and Settings.LoopTPTarget.Character:FindFirstChild("HumanoidRootPart") and Root then
        if getgenv().AllowToxTeleport then getgenv().AllowToxTeleport(0.2, "Loop TP") end
        Root.CFrame = Settings.LoopTPTarget.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -3)
    end
    local seat = Hum and Hum.SeatPart
    if seat and Settings.CarSpeed and not Settings.CarFly then
        seat.AssemblyLinearVelocity =
            seat.CFrame.LookVector * (Settings.CarSpeedValue or 100)
    end
    if Settings.CarFly
    and seat
    and Root then
        if EnsureCarFlyMovers(
            Root,
            seat
        ) then
            local flySpeed =
                math.clamp(
                    tonumber(
                        Settings.CarFlySpeed
                    ) or 80,
                    5,
                    300
                )
            local moveVector =
                GetCarFlyMoveVector()
            local velocity =
                Vector3.zero
            velocity = velocity + (Camera.CFrame.RightVector * (moveVector.X * flySpeed))
            velocity = velocity - (Camera.CFrame.LookVector * (moveVector.Z * flySpeed))
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                velocity = velocity + Vector3.new(0, flySpeed * 2, 0)
            end
            if (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) then
                velocity = velocity - Vector3.new(0, flySpeed * 2, 0)
            end
            if U.SetCarFlyTarget then
                U.SetCarFlyTarget(velocity, Camera.CFrame)
            end
            Root.AssemblyAngularVelocity =
                Vector3.zero
        end
    else
        DestroyCarFlyMovers()
    end
    if Settings.Spinbot and Root and not getgenv().ToxCombatLoaded then
        Root.CFrame = Root.CFrame * CFrame.Angles(0, math.rad(Settings.SpinSpeed or 50), 0)
    end
    local actualFlySpeed = (Settings.FlySpeed or 10) * 10
    if Settings.FlyBypass and Root and Hum and Hum.Health > 0 then
        if FlyBV then FlyBV:Destroy() FlyBV = nil end
        if FlyBG then FlyBG:Destroy() FlyBG = nil end
        Hum.PlatformStand = false
        pcall(function()
            Hum:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
        end)
        if not FlyBypassFloor or not FlyBypassFloor.Parent then
            FlyBypassFloor = Instance.new("Part")
            FlyBypassFloor.Name = "ToxBypassFloor"
            FlyBypassFloor.Size = Vector3.new(4, 0.5, 4)
            FlyBypassFloor.Transparency = 1
            FlyBypassFloor.CanCollide = true
            FlyBypassFloor.Anchored = true
            pcall(function() FlyBypassFloor.Parent = workspace end)
        end
        local standOffset
        if Hum.RigType == Enum.HumanoidRigType.R15 then
            standOffset = Hum.HipHeight + Root.Size.Y / 2
        else
            standOffset = Root.Size.Y / 2 + 2
        end
        if not FlyBypassY or FlyBypassCharacter ~= Root then
            FlyBypassY = Root.Position.Y
            FlyBypassCharacter = Root
        end

        if getgenv().AllowToxTeleport then
            getgenv().AllowToxTeleport(0.25, "Fly Bypass")
        end

        local moveDir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then moveDir = moveDir - Vector3.new(0, 1, 0) end

        if moveDir.Magnitude > 0 then
            moveDir = moveDir.Unit
            Root.CFrame = Root.CFrame + (moveDir * (actualFlySpeed * delta))
            Root.AssemblyLinearVelocity = moveDir * (actualFlySpeed * 0.2)
            FlyBypassY = Root.Position.Y
        else
            Root.AssemblyLinearVelocity = Vector3.zero
            local drift = FlyBypassY - Root.Position.Y
            if math.abs(drift) > 0.05 then
                Root.CFrame = Root.CFrame + Vector3.new(0, drift, 0)
            end
        end

        FlyBypassFloor.CFrame = CFrame.new(Root.Position.X, Root.Position.Y - standOffset - 0.25 - 0.05, Root.Position.Z)
        Root.AssemblyAngularVelocity = Vector3.zero
    else
        FlyBypassY = nil
        FlyBypassCharacter = nil
        if FlyBypassFloor then
            pcall(function() FlyBypassFloor:Destroy() end)
            FlyBypassFloor = nil
            if Hum and Hum.Health > 0 then
                pcall(function() Hum:ChangeState(Enum.HumanoidStateType.Freefall) end)
            end
        end
        if Settings.SmoothFly and Root and Hum and Hum.Health > 0 then
            DisableNormalFlyPhysics()
            Hum.PlatformStand = true
            Root.AssemblyLinearVelocity = Vector3.zero
            Root.AssemblyAngularVelocity = Vector3.zero
            local moveDir = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
            if (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) then moveDir = moveDir - Vector3.new(0, 1, 0) end
            if moveDir.Magnitude > 0 then
                moveDir = moveDir.Unit
                Root.CFrame = Root.CFrame + (moveDir * (actualFlySpeed * delta))
            end
        elseif Settings.NormalFly and Root and Hum and Hum.Health > 0 then
            if not FlyBV or FlyBV.Parent ~= Root then
                DisableNormalFlyPhysics()
                FlyBV = Instance.new("BodyVelocity")
                FlyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                FlyBV.Velocity = Vector3.zero
                FlyBV.Parent = Root
                FlyBG = Instance.new("BodyGyro")
                FlyBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
                FlyBG.CFrame = Root.CFrame
                FlyBG.Parent = Root
            end
            Hum.PlatformStand = true
            local dir = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
            if (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) then dir = dir - Vector3.new(0, 1, 0) end
            FlyBV.Velocity = dir * actualFlySpeed
            FlyBG.CFrame = Camera.CFrame
        else
            DisableNormalFlyPhysics()
        end
    end
    if FOVCircle then
        FOVCircle.Visible = Settings.Aimbot and Settings.ShowFOV
        FOVCircle.Radius = Settings.FOVRadius or 120
        FOVCircle.Position = UserInputService:GetMouseLocation()
    end
    if CrosshairH and CrosshairV then
        CrosshairH.Visible = false
        CrosshairV.Visible = false
    end
    if not getgenv().ToxCombatLoaded then
        if not getgenv().ToxUniversal2OwnsAimbot
        and Settings.Aimbot
        and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            local Target = GetClosestPlayerToMouse()
            if Target then
                local Smooth = Settings.AimbotSmoothness or 2
                Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, Target.Position), 1 / Smooth)
            end
        end
        if Settings.Triggerbot then
            local mousePos = UserInputService:GetMouseLocation()
            local ray = Camera:ViewportPointToRay(mousePos.X, mousePos.Y)
            local result = workspace:Raycast(ray.Origin, ray.Direction * 1000)
            if result and result.Instance then
                local targetModel = result.Instance:FindFirstAncestorOfClass("Model")
                local targetPlayer = targetModel and Players:GetPlayerFromCharacter(targetModel)
                if targetPlayer and targetPlayer ~= Player then
                    local tool = Player.Character and Player.Character:FindFirstChildOfClass("Tool")
                    if tool then tool:Activate() end
                end
            end
        end
    end
    if not getgenv().ToxCombatLoaded then
        if Settings.HitboxExpander then
            local hbSize = tonumber(Settings.HitboxSize) or 10
            local heightLimit = math.min(hbSize, 3.5)
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= Player and p.Character then
                    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        if not HitboxDefaults[hrp] then
                            HitboxDefaults[hrp] = {
                                Size = hrp.Size,
                                Transparency = hrp.Transparency,
                                CanCollide = hrp.CanCollide,
                                Massless = hrp.Massless,
                                CustomPhysicalProperties = hrp.CustomPhysicalProperties
                            }
                        end
                        hrp.Size = Vector3.new(hbSize, heightLimit, hbSize)
                        hrp.Transparency = 0.7
                        hrp.CanCollide = false
                        hrp.Massless = true
                        pcall(function()
                            hrp.CustomPhysicalProperties = PhysicalProperties.new(0.001, 0, 0, 0, 0)
                        end)
                    end
                end
            end
        end
        if Settings.KillAura and Root then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= Player and p.Character then
                    local tHrp = p.Character:FindFirstChild("HumanoidRootPart")
                    local tHum = p.Character:FindFirstChildOfClass("Humanoid")
                    if tHrp and tHum and tHum.Health > 0 then
                        if (Root.Position - tHrp.Position).Magnitude <= (Settings.KillAuraRange or 15) then
                            local tool = Player.Character and Player.Character:FindFirstChildOfClass("Tool")
                            if tool then tool:Activate() end
                        end
                    end
                end
            end
        end
    end
end))
end
do
    local SubGuiControls = U.SubGuiControls or {}
    local SetSubGuiMinimized = U.SetSubGuiMinimized or function() end
    local StartAntiVoid = U.StartAntiVoid or function() end
    local SetFPSBooster = U.SetFPSBooster or function() end
    local SetServerInfoVisible = U.SetServerInfoVisible or function() end
local function ShowCenterLoadSequence()
    local blur = Instance.new("BlurEffect")
    blur.Size = 18
    blur.Parent = Lighting
    if not NotifGui or not pcall(function() return NotifGui.Parent end) or not NotifGui.Parent then
        NotifGui = (getgenv and getgenv().NotifGui) or (getgenv and getgenv().Gui) or (Player and Player:FindFirstChild("PlayerGui"))
    end
    if not Main or not pcall(function() return Main.Parent end) or not Main.Parent then
        Main = (getgenv and getgenv().Main) or (Gui and Gui:FindFirstChild("Main"))
    end
    local uiTheme = env.Theme
    local SplashFrame = Instance.new("Frame")
    SplashFrame.Size = UDim2.new(0, 360, 0, 110)
    SplashFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    SplashFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    SplashFrame.BackgroundColor3 = (uiTheme and uiTheme.Panel) or Color3.fromRGB(16, 16, 26)
    SplashFrame.BorderSizePixel = 0
    SplashFrame.ClipsDescendants = true
    pcall(function() SplashFrame.Parent = NotifGui end)
    local Corner = Instance.new("UICorner") Corner.CornerRadius = UDim.new(0, 10) Corner.Parent = SplashFrame
    local Stroke = Instance.new("UIStroke") Stroke.Color = (uiTheme and uiTheme.Accent) or MAIN_COLOR Stroke.Thickness = 1 Stroke.Transparency = 0.2 Stroke.Parent = SplashFrame
    local SplashLogo = Instance.new("ImageLabel")
    SplashLogo.Size = UDim2.new(0, 48, 0, 48)
    SplashLogo.Position = UDim2.new(0, 18, 0, 16)
    SplashLogo.BackgroundTransparency = 1
    SplashLogo.Image = LOGO_ID
    SplashLogo.Parent = SplashFrame
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -85, 0, 24)
    TitleLabel.Position = UDim2.new(0, 78, 0, 16)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = "ToxHub"
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextSize = 15
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = SplashFrame
    local isCachedUser = (getgenv().ToxHasPreviousExecution == true)
    local SubLabel = Instance.new("TextLabel")
    SubLabel.Size = UDim2.new(1, -85, 0, 20)
    SubLabel.Position = UDim2.new(0, 78, 0, 40)
    SubLabel.BackgroundTransparency = 1
    SubLabel.Text = isCachedUser and "Cache Instalado • Carregando..." or "Made by @BG_0o"
    SubLabel.TextColor3 = Color3.fromRGB(150, 150, 180)
    SubLabel.Font = Enum.Font.GothamMedium
    SubLabel.TextSize = 12
    SubLabel.TextXAlignment = Enum.TextXAlignment.Left
    SubLabel.Parent = SplashFrame
    local BarBackground = Instance.new("Frame")
    BarBackground.Size = UDim2.new(1, -36, 0, 8)
    BarBackground.Position = UDim2.new(0, 18, 1, -22)
    BarBackground.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
    BarBackground.BorderSizePixel = 0
    BarBackground.Parent = SplashFrame
    local BarCorner = Instance.new("UICorner") BarCorner.CornerRadius = UDim.new(0, 4) BarCorner.Parent = BarBackground
    local BarFill = Instance.new("Frame")
    BarFill.Size = UDim2.new(0, 0, 1, 0)
    BarFill.BackgroundColor3 = MAIN_COLOR
    BarFill.BorderSizePixel = 0
    BarFill.Parent = BarBackground
    local BarFillCorner = Instance.new("UICorner") BarFillCorner.CornerRadius = UDim.new(0, 4) BarFillCorner.Parent = BarFill
    local PercentLabel = Instance.new("TextLabel")
    PercentLabel.Size = UDim2.new(0, 40, 0, 18)
    PercentLabel.Position = UDim2.new(1, -58, 0, 16)
    PercentLabel.BackgroundTransparency = 1
    PercentLabel.Text = "0%"
    PercentLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    PercentLabel.Font = Enum.Font.GothamBold
    PercentLabel.TextSize = 12
    PercentLabel.TextXAlignment = Enum.TextXAlignment.Right
    PercentLabel.Parent = SplashFrame
    local duration = isCachedUser and 2.0 or 0.85
    local steps = isCachedUser and 35 or 20
    for i = 1, steps do
        if env.Destroyed or getgenv().Destroyed then
            if blur then blur:Destroy() end
            pcall(function() if SplashFrame and SplashFrame.Parent then SplashFrame:Destroy() end end)
            return
        end
        local p = (i / steps) * 0.92
        BarFill.Size = UDim2.new(p, 0, 1, 0)
        PercentLabel.Text = math.floor(p * 100) .. "%"
        task.wait(duration / steps)
    end
    local waitGameStart = os.clock()
    while not env.Destroyed and not getgenv().Destroyed and getgenv().ToxGameModuleLoadingUrl ~= nil and (os.clock() - waitGameStart) < 2.5 do
        BarFill.Size = UDim2.new(0.95, 0, 1, 0)
        PercentLabel.Text = "95%"
        task.wait(0.05)
    end
    BarFill.Size = UDim2.new(1, 0, 1, 0)
    PercentLabel.Text = "100%"
    TitleLabel.Text = "ToxHub Loaded Successfully"
    task.wait(0.1)
    if blur then blur:Destroy() end
    local fallTween = TweenService:Create(SplashFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
        Position = UDim2.new(0.5, 0, 1.3, 0),
        BackgroundTransparency = 1
    })
    local finished = false
    local function FinishLoading()
        if finished then
            return
        end
        finished = true
        pcall(function()
            if SplashFrame and SplashFrame.Parent then
                SplashFrame:Destroy()
            end
        end)
        env.ScriptLoaded = true
        getgenv().ScriptLoaded = true
        if not env.Destroyed and not getgenv().Destroyed then
            local finalPosition = (getgenv().GetSavedGuiPosition and getgenv().GetSavedGuiPosition("Main")) or UDim2.new(0.5, -360, 0.5, -240)
            local finalSize =
                (
                    getgenv().GetSavedGuiSize
                    and getgenv().GetSavedGuiSize(
                        "Main",
                        UDim2.new(0, 720, 0, 480)
                    )
                )
                or UDim2.new(0, 720, 0, 480)
            getgenv().ToxMainExpandedSize = finalSize
            Main:SetAttribute("ToxIgnorePosTrack", true)
            if getgenv().ApplyToxTheme then pcall(getgenv().ApplyToxTheme) end
            if getgenv().SetToxUITransparency then pcall(getgenv().SetToxUITransparency, Settings.ToxUITransparency or 0, true) end
            if not Settings.StartHidden then
                local dimmer = getgenv().DimmerFrame or (Gui and Gui:FindFirstChild("DimmerFrame"))
                if dimmer then
                    dimmer.Visible = (Settings.DimBackground == true)
                end
                Main.Size = UDim2.new(0, 0, 0, 0)
                Main.Position = finalPosition
                Main.Visible = true
                Main:TweenSizeAndPosition(
                    finalSize,
                    finalPosition,
                    Enum.EasingDirection.Out,
                    Enum.EasingStyle.Back,
                    0.45,
                    true
                )
            else
                Main.Size = finalSize
                Main.Position = finalPosition
                Main.Visible = false
            end
            task.delay(0.6, function()
                if Main and Main.Parent then
                    Main:SetAttribute("ToxIgnorePosTrack", nil)
                end
            end)
            CustomNotify("ToxHub Revolution Loaded Successfully!", Color3.fromRGB(100, 255, 100))
        end
    end
    fallTween.Completed:Connect(FinishLoading)
    fallTween:Play()
    task.delay(0.75, function()
        if not finished then
            FinishLoading()
        end
    end)
end
task.spawn(function()
    local ok, err = pcall(ShowCenterLoadSequence)
    if not ok then
        warn("[ToxHub Loading Error]: " .. tostring(err))
        env.ScriptLoaded = true
        getgenv().ScriptLoaded = true
        if not Main or not Main.Parent then
            Main = (getgenv and getgenv().Main) or (Gui and Gui:FindFirstChild("Main"))
        end
        if Main and Main.Parent and not getgenv().Destroyed and not Settings.StartHidden then
            Main.Visible = true
        end
        if getgenv and getgenv().Main and getgenv().Main.Parent and not Settings.StartHidden then
            getgenv().Main.Visible = true
        end
    end
end)
local SubGuisPreMinimizedState = {}
local Minimize = getgenv().Minimize
local Minimized = false
getgenv().ToxMainMinimized = false
local MainExpandedSize =
    (
        getgenv().GetSavedGuiSize
        and getgenv().GetSavedGuiSize(
            "Main",
            UDim2.new(
                0,
                720,
                0,
                480
            )
        )
    )
    or UDim2.new(
        0,
        720,
        0,
        480
    )
local function CollapseSubGuiWithMain(key, gui)
    if not gui then return end
    local control = SubGuiControls[gui]
    SubGuisPreMinimizedState[key] = {
        Visible = gui.Visible,
        WasMinimized = control and control.Minimized or false
    }
    if gui.Visible and control and not control.Minimized then
        SetSubGuiMinimized(control, true)
    end
end
local function RestoreSubGuiAfterMain(key, gui)
    if not gui then return end
    local state = SubGuisPreMinimizedState[key]
    if not state then return end
    gui.Visible = state.Visible
    local control = SubGuiControls[gui]
    if control then
        SetSubGuiMinimized(control, state.WasMinimized)
    end
end
if Minimize and not getgenv().SetToxMinimized then
    Minimize.MouseButton1Click:Connect(function()
        Minimized = not Minimized
        getgenv().ToxMainMinimized = Minimized
        local resizeHandle = Main and Main:FindFirstChild("ToxResizeHandle")
        if resizeHandle then
            resizeHandle.Visible = not Minimized
            resizeHandle.Active = not Minimized
        end
        if Minimized then
            if Main.Size.Y.Offset > 44 then
                MainExpandedSize =
                    Main.Size
                getgenv().ToxMainExpandedSize = MainExpandedSize
            end
            Main.Size =
                UDim2.new(
                    MainExpandedSize.X.Scale,
                    MainExpandedSize.X.Offset,
                    0,
                    38
                )
        else
            local savedSize =
                (
                    getgenv().GetSavedGuiSize
                    and getgenv().GetSavedGuiSize(
                        "Main",
                        MainExpandedSize
                    )
                )
                or MainExpandedSize
            MainExpandedSize =
                savedSize
            getgenv().ToxMainExpandedSize = MainExpandedSize
            Main.Size =
                MainExpandedSize
        end
        Tabs.Visible = not Minimized
        if getgenv().CurrentPage then getgenv().CurrentPage.Visible = not Minimized end
        Minimize.Text = Minimized and "+" or "-"
        if Minimized then
            CollapseSubGuiWithMain("ChatLog", ChatLogGui)
            CollapseSubGuiWithMain("Music", MusicGui)
            CollapseSubGuiWithMain("Waypoints", WaypointsGui)
            for key, gui in pairs(getgenv().ToxLinkedSubGuis or {}) do
                CollapseSubGuiWithMain("Extra_" .. tostring(key), gui)
            end
        else
            RestoreSubGuiAfterMain("ChatLog", ChatLogGui)
            RestoreSubGuiAfterMain("Music", MusicGui)
            RestoreSubGuiAfterMain("Waypoints", WaypointsGui)
            for key, gui in pairs(getgenv().ToxLinkedSubGuis or {}) do
                RestoreSubGuiAfterMain("Extra_" .. tostring(key), gui)
            end
        end
    end)
end
local function ApplyUniversalSavedOptionsAfterLoad()
    if env.Destroyed
    or not env.ScriptLoaded then
        return
    end
    if Settings.AntiVoid then
        StartAntiVoid()
    end
    if Settings.FPSBooster then
        SetFPSBooster(
            true,
            true
        )
    end
    if Settings.ToxServerInfoVisible then
        SetServerInfoVisible(true)
    end
end
local function ShowUniversalUpdateAfterLoad()
    if getgenv().ShowToxUpdateGui then
        getgenv().ShowToxUpdateGui(
            ToxUpdateVersion,
            {
                ADDED = {},
                FIXED = {
                    "Server Info ALL mode now shows FPS, ping, players, region, PlaceId, JobId and JoinId.",
                    "Server Info size was increased to stop cutting long server ids."
                },
                CHANGED = {
                    "Server Info COPY now copies only the JoinId."
                },
                REMOVED = {}
            }
        )
    end
end
task.spawn(function()
    while not env.Destroyed
    and not env.ScriptLoaded do
        task.wait(0.05)
    end
    if env.Destroyed then
        return
    end
    ApplyUniversalSavedOptionsAfterLoad()
    task.wait(0.2)
    ShowUniversalUpdateAfterLoad()
end)
getgenv().ToxUniversalLoaded = true
end
