local env = getgenv()
if env.Destroyed or env.ToxUniversalLoaded then
    return
end
env.ToxUniversal = env.ToxUniversal or {}
local U = env.ToxUniversal
local Settings = env.Settings or {}
local VisualsPage = env.VisualsPage
local FlingPage = env.FlingPage
local ColorMap = env.ColorMap or {}
local CreateToggle = env.CreateToggle
local CreateToggleWithValue = env.CreateToggleWithValue
local CreateDropdown = env.CreateDropdown
local RegisterSharedToggle = env.RegisterSharedToggle
local SyncToggleVisuals = env.SyncToggleVisuals
local TrackUniversalControl = env.TrackUniversalControl
local BeginUniversalSection = env.BeginUniversalSection or function() end
local function AutoSaveConfiguration(...) if env.AutoSaveConfiguration then return env.AutoSaveConfiguration(...) end end
local function UpdateFullbright(...) if env.UpdateFullbright then return env.UpdateFullbright(...) end end
local GetCurrentESPMAX = env.GetCurrentESPMAX or U.GetCurrentESPMAX or function() return tonumber(Settings.EspMaxDistance) or 1000 end
local SetCurrentESPMAX = env.SetCurrentESPMAX or U.SetCurrentESPMAX or function(v) Settings.EspMaxDistance = tonumber(v) or 1000 end
local CaptureFOVDefault = U.CaptureFOVDefault or function() end
local RestoreFOVDefault = U.RestoreFOVDefault or function() end
BeginUniversalSection("ESP")
CreateToggle("ESP", VisualsPage, Settings.ESPEnabled, function(v)
    if getgenv().ToxSetSharedOption then
        getgenv().ToxSetSharedOption("ESPEnabled", v)
    else
        Settings.ESPEnabled = v
    end
    if not v then
        local clr = getgenv().ClearAllESPVisuals or getgenv().ClearAllToxESPVisuals
        if type(clr) == "function" then
            pcall(clr)
        end
    end
end, "ESPEnabled")
CreateToggle("Charms", VisualsPage, Settings.Chams, function(v)
    if getgenv().ToxSetSharedOption then
        getgenv().ToxSetSharedOption("Chams", v)
    else
        Settings.Chams = v
    end
end, "Chams")
function CreateToggleCycleOption(name, page, enabled, options, currentValue, toggleCallback, cycleCallback, syncKey)
    if getgenv().CreateToggleWithChoice then
        local ctrl = getgenv().CreateToggleWithChoice(name, page, options, enabled == true, currentValue or options[1], toggleCallback, cycleCallback, syncKey)
        local btn = (type(ctrl) == "table" and rawget(ctrl, "Button")) or ctrl
        local trackFn = getgenv().TrackUniversalControl or TrackUniversalControl
        if trackFn then trackFn(btn, page) end
        return btn
    end
    local th = getgenv().Theme or {}
    local accent = th.Accent or Color3.fromRGB(30, 95, 255)
    local panel = th.Panel or Color3.fromRGB(16, 16, 26)
    local element = th.Element or Color3.fromRGB(22, 22, 34)
    local outline = th.Outline or Color3.fromRGB(36, 36, 56)
    local box = Instance.new("Frame")
    box.Size = UDim2.new(1, -4, 0, 36)
    box.BackgroundColor3 = element
    box.BorderSizePixel = 0
    box.Parent = page
    local bCorner = Instance.new("UICorner") bCorner.CornerRadius = UDim.new(0, 6) bCorner.Parent = box
    local bStroke = Instance.new("UIStroke")
    bStroke.Color = outline
    bStroke.Thickness = 1
    bStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    bStroke.Parent = box
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -170, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = th.Text or Color3.fromRGB(255, 255, 255)
    label.TextSize = 12
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextTruncate = Enum.TextTruncate.AtEnd
    label.Parent = box
    local modeButton = Instance.new("TextButton")
    modeButton.Size = UDim2.new(0, 84, 0, 22)
    modeButton.Position = UDim2.new(1, -140, 0.5, -11)
    modeButton.BackgroundColor3 = panel
    modeButton.BorderSizePixel = 0
    modeButton.Text = tostring(currentValue or options[1])
    modeButton.TextColor3 = accent
    modeButton.TextSize = 11
    modeButton.Font = Enum.Font.GothamBold
    modeButton.Parent = box
    local mCorner = Instance.new("UICorner") mCorner.CornerRadius = UDim.new(0, 4) mCorner.Parent = modeButton
    local mStroke = Instance.new("UIStroke")
    mStroke.Color = outline
    mStroke.Thickness = 1
    mStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    mStroke.Parent = modeButton
    local toggleButton = Instance.new("TextButton")
    toggleButton.Size = UDim2.new(0, 38, 0, 20)
    toggleButton.Position = UDim2.new(1, -48, 0.5, -10)
    toggleButton.BackgroundColor3 = enabled and accent or panel
    toggleButton.BorderSizePixel = 0
    toggleButton.Text = ""
    toggleButton.AutoButtonColor = false
    toggleButton.Parent = box
    local tCorner = Instance.new("UICorner") tCorner.CornerRadius = UDim.new(1, 0) tCorner.Parent = toggleButton
    local tStroke = Instance.new("UIStroke")
    tStroke.Color = outline
    tStroke.Thickness = 1
    tStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    tStroke.Parent = toggleButton
    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 14, 0, 14)
    indicator.Position = enabled and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
    indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    indicator.BorderSizePixel = 0
    indicator.Parent = toggleButton
    local indicatorCorner = Instance.new("UICorner")
    indicatorCorner.CornerRadius = UDim.new(1, 0)
    indicatorCorner.Parent = indicator
    local state = enabled == true
    local function updateToggle()
        local curAccent = (getgenv().Theme and getgenv().Theme.Accent) or accent
        local curPanel = (getgenv().Theme and getgenv().Theme.Panel) or panel
        toggleButton.BackgroundColor3 = state and curAccent or curPanel
        indicator.Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
    end
    local registerFn = getgenv().RegisterSharedToggle or RegisterSharedToggle
    if syncKey and registerFn then
        registerFn(syncKey, {
            Button = box,
            SetVisual = function(value)
                state = value == true
                updateToggle()
            end
        })
    end
    toggleButton.MouseButton1Click:Connect(function()
        if getgenv().Destroyed then return end
        state = not state
        updateToggle()
        if toggleCallback then toggleCallback(state) end
        local syncFn = getgenv().SyncToggleVisuals or SyncToggleVisuals
        if syncKey and syncFn then syncFn(syncKey, state) end
        AutoSaveConfiguration()
    end)
    modeButton.MouseButton1Click:Connect(function()
        if getgenv().Destroyed then return end
        local index = 1
        for i, option in ipairs(options) do
            if tostring(option) == tostring(modeButton.Text) then index = i break end
        end
        index = index + 1
        if index > #options then index = 1 end
        modeButton.Text = tostring(options[index])
        if cycleCallback then cycleCallback(options[index]) end
        AutoSaveConfiguration()
    end)
    updateToggle()
    local trackFn = getgenv().TrackUniversalControl or TrackUniversalControl
    if trackFn then
        return trackFn(box, page)
    end
    return box
end
CreateToggleCycleOption("Tracers", VisualsPage, Settings.ESPTracers, {"DOWN", "UP", "MOUSE"}, Settings.TracerOrigin or "DOWN", function(v)
    Settings.ESPTracers = v
    if not v then
        if getgenv().ToxClearTracers then
            getgenv().ToxClearTracers()
        end
    end
end, function(v)
    Settings.TracerOrigin = v
end, "ESPTracers")
CreateToggleCycleOption("Names", VisualsPage, Settings.ESPNames, {"Name", "Display", "Name + Display"}, Settings.ESPNameMode or "Display", function(v)
    if getgenv().ToxSetSharedOption then
        getgenv().ToxSetSharedOption("ESPNames", v)
    else
        Settings.ESPNames = v
    end
end, function(v)
    Settings.ESPNameMode = v
end, "ESPNames")
CreateToggle("Distance", VisualsPage, Settings.ESPDistance, function(v)
    Settings.ESPDistance = v
end)
CreateToggle("2D Box ESP", VisualsPage, Settings.ESPBox, function(v)
    Settings.ESPBox = v
end)
CreateToggle("Head Dot ESP", VisualsPage, Settings.ESPHeadDot, function(v)
    Settings.ESPHeadDot = v
end)
CreateToggle("Skeleton ESP", VisualsPage, Settings.ESPSkeleton, function(v)
    Settings.ESPSkeleton = v == true
    if not v then
        if getgenv().ToxClearSkeletons then
            getgenv().ToxClearSkeletons()
        end
    end
end, "ESPSkeleton")
CreateToggle("Target ESP", VisualsPage, Settings.TargetESP, function(v)
    Settings.TargetESP = v == true
end, "TargetESP")
CreateToggle("Spectator List", VisualsPage, Settings.SpectatorList, function(v)
    Settings.SpectatorList = v == true
    if getgenv().ToxSpectatorsFrame then
        getgenv().ToxSpectatorsFrame.Visible = Settings.SpectatorList
    end
end, "SpectatorList")
CreateToggle("Keybinds List", VisualsPage, Settings.KeybindsList, function(v)
    Settings.KeybindsList = v == true
    if getgenv().ToxKeybindsFrame then
        getgenv().ToxKeybindsFrame.Visible = Settings.KeybindsList
    end
end, "KeybindsList")
CreateToggle("Team Colors", VisualsPage, Settings.ESPTeamColors, function(v)
    if getgenv().ToxSetSharedOption then
        getgenv().ToxSetSharedOption("ESPTeamColors", v)
    else
        Settings.ESPTeamColors = v
    end
end, "ESPTeamColors")
CreateToggleWithValue("Camera FOV", VisualsPage, Settings.FOVEnabled, Settings.FOVValue, function(v)
    if v then
        CaptureFOVDefault()
    end
    Settings.FOVEnabled = v
    if not v then
        RestoreFOVDefault()
    end
end, function(val) Settings.FOVValue = val end)
CreateToggleWithValue("ESP Max Dist", VisualsPage, Settings.EspMaxDistEnabled == true, GetCurrentESPMAX(), function(v)
    Settings.EspMaxDistEnabled = v == true
end, function(val)
    SetCurrentESPMAX(val)
end, "EspMaxDistEnabled")
CreateDropdown("ESP Color", {"White", "Red", "Green", "Blue", "Yellow", "Cyan", "Magenta", "Orange", "Purple", "Lime", "Pink", "Gold"}, VisualsPage, Settings.EspColorName, function(v)
    Settings.EspColorName = v
    Settings.EspColor = ColorMap[v] or Color3.fromRGB(255, 255, 255)
end)
BeginUniversalSection("Lighting")
CreateToggle(
    "Fullbright",
    getgenv().LightingPage or FlingPage,
    Settings.Fullbright,
    function(v)
        if v == true
        and getgenv().ToxLighting
        and type(getgenv().ToxLighting.SetAdjust) == "function" then
            pcall(getgenv().ToxLighting.SetAdjust, false)
            Settings.AdjustLighting = false
            if getgenv().SyncToggleVisuals then
                pcall(getgenv().SyncToggleVisuals, "AdjustLighting", false)
            end
        end
        Settings.Fullbright = v == true
        UpdateFullbright()
    end,
    "Fullbright"
)
U.CreateToggleCycleOption = CreateToggleCycleOption
env.CreateToggleCycleOption = CreateToggleCycleOption
