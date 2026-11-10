local env = getgenv()
if env.Destroyed or env.ToxUniversalLoaded then
    return
end
env.ToxUniversal = env.ToxUniversal or {}
local U = env.ToxUniversal
local CustomNotify = function(...) if env.CustomNotify then return env.CustomNotify(...) end end
local AutoSaveConfiguration = function(...) if env.AutoSaveConfiguration then return env.AutoSaveConfiguration(...) end end
local AddConnection = function(...) if env.AddConnection then return env.AddConnection(...) end end
local SavedIDs = env.SavedIDs or {}
local ChatLogGui = env.ChatLogGui
local MusicGui = env.MusicGui
local WaypointsGui = env.WaypointsGui
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
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local CoreGui = game:GetService("CoreGui")
local StatsService = game:GetService("Stats")
local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local function IsLocalPlayer(p)
    if not p then return true end
    if p == Player or p == Players.LocalPlayer then return true end
    local lp = Players.LocalPlayer or Player
    if lp then
        if p.UserId and lp.UserId and p.UserId == lp.UserId then return true end
        if p.Name and lp.Name and p.Name == lp.Name then return true end
    end
    return false
end
getgenv().Settings = getgenv().Settings or {}
local Settings = getgenv().Settings
local NDSPlaceId = 189707
local MM2PlaceId = 142823291
if game.PlaceId ~= NDSPlaceId then
    local env = getgenv()
    if env.SetNDSNoTP then
        pcall(function()
            env.SetNDSNoTP(false, true)
        end)
    end
    if env.Settings then
        env.Settings.NDSNoTP = false
    end
end
Settings.WalkFling = Settings.WalkFling == true
Settings.EspMaxDistanceByPlace =
    typeof(Settings.EspMaxDistanceByPlace) == "table"
    and Settings.EspMaxDistanceByPlace
    or {}
ToxUpdateVersion = "2026-10-19-kick-autoreexec-persist-v10"
function ClearToxTable(target)
    if typeof(target) ~= "table" then
        return
    end
    for key in pairs(target) do
        target[key] = nil
    end
end
Settings.ToxServerInfoVisible = Settings.ToxServerInfoVisible == true
Settings.ToxServerInfoMode = Settings.ToxServerInfoMode or "FPS/Ping/Players"
function GetCurrentPlaceKey()
    return tostring(game.PlaceId)
end
function GetCurrentESPMAX()
    local placeKey = GetCurrentPlaceKey()
    local saved = tonumber(
        Settings.EspMaxDistanceByPlace[placeKey]
    )
    if saved then
        return saved
    end
    return tonumber(Settings.EspMaxDistance) or 1000
end
function SetCurrentESPMAX(value)
    local number = math.clamp(
        math.floor((tonumber(value) or 1000) + 0.5),
        0,
        100000
    )
    Settings.EspMaxDistance = number
    Settings.EspMaxDistanceByPlace[GetCurrentPlaceKey()] = number
    if getgenv().AutoSaveConfiguration then
        getgenv().AutoSaveConfiguration()
    end
    return number
end
Settings.EspMaxDistance = GetCurrentESPMAX()
local HumanoidDefaults = setmetatable({}, {__mode = "k"})
local NoclipDefaults = setmetatable({}, {__mode = "k"})
local AntiFlingDefaults = setmetatable({}, {__mode = "k"})
local HitboxDefaults = setmetatable({}, {__mode = "k"})
local FOVDefault = Camera.FieldOfView
local FOVCaptured = false
local ShiftLockDefaults = nil
local isShiftLockActive = false
local Gui = (getgenv and getgenv().Gui) or Gui
local Main = (getgenv and getgenv().Main) or Main
local Tabs = (getgenv and getgenv().Tabs) or Tabs
local NotifGui = (getgenv and getgenv().NotifGui) or NotifGui
local DimmerFrame = (getgenv and getgenv().DimmerFrame) or DimmerFrame
local MAIN_COLOR = (getgenv and getgenv().MAIN_COLOR) or MAIN_COLOR or Color3.fromRGB(0, 170, 255)
local LOGO_ID = (getgenv and getgenv().LOGO_ID) or LOGO_ID or "rbxassetid://13837920158"
local ToxChatGui = getgenv().ToxChatGui
local JoinGamesGui = getgenv().JoinGamesGui
local JoinGamesScroll = getgenv().JoinGamesScroll
local JoinGameIdBox = getgenv().JoinGameIdBox
local JoinGameAddButton = getgenv().JoinGameAddButton
local SavedJoinGames = getgenv().SavedJoinGames or {}
local CheckMusicIDsBtn = getgenv().CheckMusicIDsBtn
local SetMusicIDStatus = getgenv().SetMusicIDStatus
do
getgenv().MusicIDStatus = {}
local MusicIDStatus = getgenv().MusicIDStatus
local MusicCheckRunning = false
local MusicCheckGeneration = 0
local MusicInitialNoticeShown = false
local function GetSavedMusicIDs()
    local ids = {}
    local seen = {}
    for _, item in ipairs(SavedIDs or {}) do
        local id = nil
        if typeof(item) == "table" then
            id = tonumber(item.id)
        else
            id = tonumber(item)
        end
        if id and not seen[id] then
            seen[id] = true
            table.insert(ids, id)
        end
    end
    return ids
end
local function IsMusicIDActive(id)
    local success, info = pcall(function()
        return MarketplaceService:GetProductInfo(id, Enum.InfoType.Asset)
    end)
    if not success or typeof(info) ~= "table" then
        return false
    end
    if tonumber(info.AssetTypeId) ~= 3 then
        return false
    end
    local name = string.lower(tostring(info.Name or ""))
    if name == ""
    or string.find(name, "content deleted", 1, true)
    or string.find(name, "[deleted]", 1, true)
    or string.find(name, "[ content deleted ]", 1, true)
    or string.find(name, "deleted", 1, true) == 1 then
        return false
    end
    return true
end
local function ApplyMusicStatus(id, status)
    MusicIDStatus[tostring(id)] = status
    if SetMusicIDStatus then
        SetMusicIDStatus(id, status)
    end
end
local function CheckSavedMusicIDs(force)
    if MusicCheckRunning and not force then
        return
    end
    local ids = GetSavedMusicIDs()
    if #ids == 0 then
        if CheckMusicIDsBtn then
            CheckMusicIDsBtn.Text = "Check IDs"
        end
        return
    end
    MusicCheckGeneration = MusicCheckGeneration + 1
    local generation = MusicCheckGeneration
    MusicCheckRunning = true
    if CheckMusicIDsBtn then
        CheckMusicIDsBtn.Text = "Checking..."
        CheckMusicIDsBtn.TextColor3 = Color3.fromRGB(255, 215, 70)
        CheckMusicIDsBtn.Active = false
    end
    for _, id in ipairs(ids) do
        if force or MusicIDStatus[tostring(id)] == nil then
            ApplyMusicStatus(id, "checking")
        else
            ApplyMusicStatus(id, MusicIDStatus[tostring(id)])
        end
    end
    task.spawn(function()
        local activeCount = 0
        local unavailableCount = 0
        for _, id in ipairs(ids) do
            if generation ~= MusicCheckGeneration then
                return
            end
            local key = tostring(id)
            local status = MusicIDStatus[key]
            if force or status == nil or status == "checking" then
                status = IsMusicIDActive(id)
                ApplyMusicStatus(id, status)
                task.wait(0.12)
            end
            if status == true then
                activeCount = activeCount + 1
            elseif status == false then
                unavailableCount = unavailableCount + 1
            end
        end
        if generation ~= MusicCheckGeneration then
            return
        end
        MusicCheckRunning = false
        if CheckMusicIDsBtn and CheckMusicIDsBtn.Parent then
            CheckMusicIDsBtn.Text = "Check IDs"
            CheckMusicIDsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            CheckMusicIDsBtn.Active = true
        end
        if not MusicInitialNoticeShown then
            MusicInitialNoticeShown = true
            CustomNotify(
                "Music IDs: "
                    .. tostring(activeCount)
                    .. " active | "
                    .. tostring(unavailableCount)
                    .. " unavailable",
                unavailableCount > 0
                    and Color3.fromRGB(255, 180, 70)
                    or Color3.fromRGB(100, 255, 100)
            )
        end
    end)
end
if CheckMusicIDsBtn then
    CheckMusicIDsBtn.MouseButton1Click:Connect(function()
        CheckSavedMusicIDs(true)
    end)
end
if MusicGui then
    AddConnection(MusicGui:GetPropertyChangedSignal("Visible"):Connect(function()
        if MusicGui.Visible then
            task.defer(function()
                CheckSavedMusicIDs(false)
            end)
        end
    end))
end
task.delay(1, function()
    CheckSavedMusicIDs(true)
end)
end
local RequestFunction = nil
pcall(function()
    local env = getgenv()
    if syn and syn.request then
        RequestFunction = syn.request
    elseif http and http.request then
        RequestFunction = http.request
    elseif fluxus and fluxus.request then
        RequestFunction = fluxus.request
    elseif krnl and krnl.request then
        RequestFunction = krnl.request
    elseif env and env.request then
        RequestFunction = env.request
    elseif env and env.http_request then
        RequestFunction = env.http_request
    elseif http_request then
        RequestFunction = http_request
    elseif request then
        RequestFunction = request
    end
end)
getgenv().ToxRequestFunction = RequestFunction
local function GetHumanoidDefaults(hum)
    if not hum then return nil end
    if not HumanoidDefaults[hum] then
        HumanoidDefaults[hum] = {
            WalkSpeed = hum.WalkSpeed,
            UseJumpPower = hum.UseJumpPower,
            JumpPower = hum.JumpPower,
            JumpHeight = hum.JumpHeight
        }
    end
    return HumanoidDefaults[hum]
end
local function RestoreSpeed()
    local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
    local defaults = hum and HumanoidDefaults[hum]
    if hum and defaults then
        hum.WalkSpeed = defaults.WalkSpeed
    end
end
local function RestoreJump()
    local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
    local defaults = hum and HumanoidDefaults[hum]
    if hum and defaults then
        hum.UseJumpPower = defaults.UseJumpPower
        hum.JumpPower = defaults.JumpPower
        hum.JumpHeight = defaults.JumpHeight
    end
end
local function CaptureNoclipDefaults()
    if not Player.Character then return end
    for _, part in ipairs(Player.Character:GetDescendants()) do
        if part:IsA("BasePart") and NoclipDefaults[part] == nil then
            NoclipDefaults[part] = part.CanCollide
        end
    end
end
local function RestoreNoclipDefaults()
    for part, canCollide in pairs(NoclipDefaults) do
        if part and part.Parent then
            part.CanCollide = canCollide
        end
        NoclipDefaults[part] = nil
    end
end
local function RestoreAntiFlingDefaults()
    for part, canCollide in pairs(AntiFlingDefaults) do
        if part and part.Parent then
            part.CanCollide = canCollide
        end
        AntiFlingDefaults[part] = nil
    end
end
local function RestoreHitboxDefaults()
    for hrp, data in pairs(HitboxDefaults) do
        if hrp and hrp.Parent then
            pcall(function()
                hrp.Size = data.Size
                hrp.Transparency = data.Transparency
                hrp.CanCollide = data.CanCollide
                hrp.Massless = data.Massless
                if data.CustomPhysicalProperties then
                    hrp.CustomPhysicalProperties = data.CustomPhysicalProperties
                end
            end)
        end
        HitboxDefaults[hrp] = nil
    end
end
local function CaptureFOVDefault()
    if not FOVCaptured then
        FOVDefault = Camera.FieldOfView
        FOVCaptured = true
    end
end
local function RestoreFOVDefault()
    if FOVCaptured then
        Camera.FieldOfView = FOVDefault
        FOVCaptured = false
    end
end
local function CaptureShiftLockDefaults()
    if not ShiftLockDefaults then
        ShiftLockDefaults = {
            DevEnableMouseLock = Player.DevEnableMouseLock,
            MouseBehavior = UserInputService.MouseBehavior
        }
    end
end
local function RestoreShiftLockDefaults()
    if ShiftLockDefaults then
        pcall(function()
            Player.DevEnableMouseLock = ShiftLockDefaults.DevEnableMouseLock
        end)
        pcall(function()
            UserInputService.MouseBehavior = ShiftLockDefaults.MouseBehavior
        end)
        ShiftLockDefaults = nil
    end
    isShiftLockActive = false
end
do
local SubGuiControls = {}
local function FindSubGuiTopBar(gui)
    if not gui then return nil end
    for _, child in ipairs(gui:GetChildren()) do
        if child:IsA("Frame") and child.Size.Y.Offset == 32 and child.Position.Y.Offset == 0 then
            return child
        end
    end
    return nil
end
local function SetSubGuiContentVisible(data, visible)
    local gui = data.Gui
    local topBar = data.TopBar
    if visible then
        for child, wasVisible in pairs(data.ChildVisibility) do
            if child and child.Parent == gui and child:IsA("GuiObject") then
                child.Visible = wasVisible
            end
        end
        data.ChildVisibility = {}
    else
        data.ChildVisibility = {}
        for _, child in ipairs(gui:GetChildren()) do
            if child:IsA("GuiObject") and child ~= topBar then
                data.ChildVisibility[child] = child.Visible
                child.Visible = false
            end
        end
    end
end
local function SetSubGuiMinimized(data, minimized)
    if not data or not data.Gui then
        return
    end
    local gui = data.Gui
    if minimized then
        if not data.Minimized and (gui.Size.Y.Offset > 32 or gui.Size.Y.Scale ~= 0) then
            data.ExpandedSize = gui.Size
        end
        gui.ClipsDescendants = true
        SetSubGuiContentVisible(data, false)
        gui.Size = UDim2.new(data.ExpandedSize.X.Scale, data.ExpandedSize.X.Offset, 0, 32)
        data.Button.Text = "+"
        data.Minimized = true
    else
        gui.Size = data.ExpandedSize
        SetSubGuiContentVisible(data, true)
        data.Button.Text = "-"
        data.Minimized = false
    end
end
local function RegisterSubGuiMinimize(gui, buttonOffset)
    if not gui then return nil end
    local topBar = FindSubGuiTopBar(gui)
    if not topBar then return nil end
    for _, child in ipairs(topBar:GetChildren()) do
        if child:IsA("TextButton") and (child.Text == "-" or child.Text == "+") then
            child:Destroy()
        end
    end
    for _, child in ipairs(topBar:GetChildren()) do
        if child:IsA("TextLabel") then
            child.Size = UDim2.new(1, math.min(child.Size.X.Offset, -70), child.Size.Y.Scale, child.Size.Y.Offset)
            break
        end
    end
    local button = Instance.new("TextButton")
    button.Name = "ToxSubGuiMinimize"
    button.Size = UDim2.new(0, 24, 0, 22)
    button.Position = UDim2.new(1, buttonOffset, 0.5, -11)
    button.BackgroundColor3 = Color3.fromRGB(22, 22, 35)
    button.BorderSizePixel = 0
    button.Text = "-"
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 14
    button.AutoButtonColor = false
    button.Parent = topBar
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = button
    local data = {
        Gui = gui,
        TopBar = topBar,
        ExpandedSize = gui.Size,
        Button = button,
        Minimized = false,
        ChildVisibility = {}
    }
    SubGuiControls[gui] = data
    button.MouseButton1Click:Connect(function()
        SetSubGuiMinimized(data, not data.Minimized)
    end)
    return data
end
RegisterSubGuiMinimize(ChatLogGui, -88)
RegisterSubGuiMinimize(MusicGui, -52)
RegisterSubGuiMinimize(WaypointsGui, -52)
if JoinGamesGui then
    JoinGamesGui.Visible = false
end
if getgenv().MakeResizable then
    getgenv().MakeResizable(Main, "Main", 0.88, 1.50)
    getgenv().MakeResizable(ChatLogGui, "ChatLogs", 0.85, 1.50)
    getgenv().MakeResizable(MusicGui, "Music", 0.85, 1.50)
    getgenv().MakeResizable(WaypointsGui, "Waypoints", 0.85, 1.50)
end
getgenv().ToxLinkedSubGuis = getgenv().ToxLinkedSubGuis or {}
getgenv().RegisterToxSubGuiMinimize = function(gui, buttonOffset)
    if not gui then
        return nil
    end
    local existing = SubGuiControls[gui]
    if existing then
        return existing
    end
    return RegisterSubGuiMinimize(gui, buttonOffset or -52)
end
getgenv().RegisterToxLinkedSubGui = function(key, gui)
    if not key or not gui then
        return
    end
    local normalizedKey =
        tostring(key)
    getgenv().ToxLinkedSubGuis[
        normalizedKey
    ] = gui
    if getgenv().MakeResizable then
        getgenv().MakeResizable(
            gui,
            "Linked_"
            .. normalizedKey,
            0.90,
            1.45
        )
    end
end
    U.SubGuiControls = SubGuiControls
    U.SetSubGuiMinimized = SetSubGuiMinimized
end
local ToxPages = getgenv().Pages
if typeof(ToxPages) == "table" then
    for _, page in pairs(ToxPages) do
        if page and page.GetChildren and page.Name ~= "HOME" and (not getgenv().GamePage or page ~= getgenv().GamePage) then
            for _, child in ipairs(page:GetChildren()) do
                if child:IsA("Frame") or child:IsA("TextButton") then
                    child:Destroy()
                end
            end
        end
    end
end
local function IsPartVisible(part)
    if not Settings.AimWallCheck then return true end
    local origin = Camera.CFrame.Position
    local dir = part.Position - origin
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {Player.Character, part.Parent}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    local result = workspace:Raycast(origin, dir, raycastParams)
    return result == nil
end
local function GetClosestPlayerToMouse()
    local Closest = nil
    local ShortestDistance = Settings.FOVRadius or 120
    local MousePos = UserInputService:GetMouseLocation()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player and p.Character then
            local targetPart = p.Character:FindFirstChild(Settings.AimPart or "Head")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if targetPart and hum and hum.Health > 0 and IsPartVisible(targetPart) then
                local ScreenPos, OnScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if OnScreen then
                    local Dist = (Vector2.new(ScreenPos.X, ScreenPos.Y) - MousePos).Magnitude
                    if Dist < ShortestDistance then
                        ShortestDistance = Dist
                        Closest = targetPart
                    end
                end
            end
        end
    end
    return Closest
end
env.ClearToxTable = ClearToxTable
env.GetCurrentPlaceKey = GetCurrentPlaceKey
env.GetCurrentESPMAX = GetCurrentESPMAX
env.SetCurrentESPMAX = SetCurrentESPMAX
env.RestoreHitboxDefaults = RestoreHitboxDefaults
U.ClearToxTable = ClearToxTable
U.GetCurrentPlaceKey = GetCurrentPlaceKey
U.GetCurrentESPMAX = GetCurrentESPMAX
U.SetCurrentESPMAX = SetCurrentESPMAX
U.IsLocalPlayer = IsLocalPlayer
U.Settings = Settings
U.NDSPlaceId = NDSPlaceId
U.MM2PlaceId = MM2PlaceId
U.ToxUpdateVersion = ToxUpdateVersion
U.HumanoidDefaults = HumanoidDefaults
U.NoclipDefaults = NoclipDefaults
U.AntiFlingDefaults = AntiFlingDefaults
U.HitboxDefaults = HitboxDefaults
U.GetFOVDefault = function() return FOVDefault end
U.SetFOVDefault = function(v) FOVDefault = v end
U.GetShiftLockActive = function() return isShiftLockActive end
U.SetShiftLockActive = function(v) isShiftLockActive = v == true end
U.GetHumanoidDefaults = GetHumanoidDefaults
U.RestoreSpeed = RestoreSpeed
U.RestoreJump = RestoreJump
U.CaptureNoclipDefaults = CaptureNoclipDefaults
U.RestoreNoclipDefaults = RestoreNoclipDefaults
U.RestoreAntiFlingDefaults = RestoreAntiFlingDefaults
U.RestoreHitboxDefaults = RestoreHitboxDefaults
U.CaptureFOVDefault = CaptureFOVDefault
U.RestoreFOVDefault = RestoreFOVDefault
U.CaptureShiftLockDefaults = CaptureShiftLockDefaults
U.RestoreShiftLockDefaults = RestoreShiftLockDefaults
U.IsPartVisible = IsPartVisible
U.GetClosestPlayerToMouse = GetClosestPlayerToMouse
U.RequestFunction = RequestFunction
env.ToxUniversal = U
