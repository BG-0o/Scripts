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
    getgenv().ToxMM2ModuleLoadedJobId = nil
    getgenv().ToxMM2ModuleVersion = nil
    getgenv().ToxMM2ModulePage = nil
    getgenv().ToxMM2CoreReady = nil
    getgenv().ToxMM2CoreVersion = nil
    getgenv().ToxMM2LoaderJobId = nil
    getgenv().ToxMM2LoaderVersion = nil
    getgenv().ToxMM2LoaderPage = nil
    getgenv().ToxGameModuleLoadedUrl = nil
    getgenv().ToxGameModuleLoadedPage = nil
    getgenv().ToxGameModuleLoadingUrl = nil
    getgenv().ToxGameModuleLoadingPage = nil

    if getgenv().ToxUniversal2ExtraCleanup then
        pcall(getgenv().ToxUniversal2ExtraCleanup)
    end

    if getgenv().ToxUniversal2Cleanup then
        pcall(getgenv().ToxUniversal2Cleanup)
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

    if getgenv().ScriptConnections then
        for _, conn in ipairs(getgenv().ScriptConnections) do
            pcall(function()
                conn:Disconnect()
            end)
        end
    end

    task.wait(0.25)
end

if getgenv().Gui then pcall(function() getgenv().Gui:Destroy() end) end
if getgenv().NotifGui then pcall(function() getgenv().NotifGui:Destroy() end) end

local LOGO_ID = "rbxassetid://120675082996894"
local MAIN_COLOR = Color3.fromRGB(9, 0, 136)

local GUIColorMap = {
    ["Blue"] = Color3.fromRGB(9, 0, 136),
    ["Cyan"] = Color3.fromRGB(0, 120, 160),
    ["Purple"] = Color3.fromRGB(95, 35, 180),
    ["Green"] = Color3.fromRGB(25, 140, 80),
    ["Red"] = Color3.fromRGB(160, 35, 50),
    ["Orange"] = Color3.fromRGB(190, 90, 25),
    ["Pink"] = Color3.fromRGB(180, 55, 130),
    ["Gold"] = Color3.fromRGB(175, 130, 20),
    ["White"] = Color3.fromRGB(150, 150, 165)
}

local ColorMap = {
	["White"] = Color3.fromRGB(255, 255, 255),
	["Red"] = Color3.fromRGB(255, 50, 50),
	["Green"] = Color3.fromRGB(50, 255, 50),
	["Blue"] = Color3.fromRGB(50, 150, 255),
	["Yellow"] = Color3.fromRGB(255, 255, 50),
	["Cyan"] = Color3.fromRGB(50, 255, 255),
	["Magenta"] = Color3.fromRGB(255, 50, 255),
	["Orange"] = Color3.fromRGB(255, 150, 50),
	["Purple"] = Color3.fromRGB(150, 50, 255),
    ["Lime"] = Color3.fromRGB(120, 255, 50),
    ["Pink"] = Color3.fromRGB(255, 105, 180),
    ["Gold"] = Color3.fromRGB(255, 215, 0)
}

getgenv().ColorMap = ColorMap
getgenv().GUIColorMap = GUIColorMap
getgenv().LOGO_ID = LOGO_ID
getgenv().MAIN_COLOR = MAIN_COLOR

getgenv().GameModuleRegistry = {
    [189707] = {
        ShortName = "NDS",
        Url = "https://raw.githubusercontent.com/BG-0o/Scripts/refs/heads/main/NDS.lua",
        Ready = true
    },
    [142823291] = {
        ShortName = "MM2",
        Url = "https://raw.githubusercontent.com/BG-0o/Scripts/refs/heads/main/MM2.lua?toxv=2026-09-13-mm2-split-loader-config-fix",
        CoreUrl = "https://raw.githubusercontent.com/BG-0o/Scripts/refs/heads/main/ModuleMM2.lua?toxv=2026-09-13-mm2-split-loader-config-fix",
        Ready = true
    },
    [4522347649] = {
        ShortName = "ADMIN",
        Url = "https://raw.githubusercontent.com/BG-0o/Scripts/refs/heads/main/ADMIN.lua",
        Ready = true
    },
    [662417684] = {
        ShortName = "LBB",
        Url = "https://raw.githubusercontent.com/BG-0o/Scripts/refs/heads/main/LBB.lua",
        Ready = true
    },
    [893973440] = {
        ShortName = "FTF",
        Url = "https://raw.githubusercontent.com/BG-0o/Scripts/refs/heads/main/FTF.lua",
        Ready = true
    },
    [155615604] = {
        ShortName = "PL",
        Url = "https://raw.githubusercontent.com/BG-0o/Scripts/refs/heads/main/PL.lua",
        Ready = true
    },
    [537413528] = {
        ShortName = "BABFT",
        Url = "https://raw.githubusercontent.com/BG-0o/Scripts/refs/heads/main/BABFT.lua",
        Ready = true
    }
}

getgenv().CurrentGameModule = getgenv().GameModuleRegistry[game.PlaceId]
getgenv().ToxTeleportBypassUntil = 0
getgenv().ToxTeleportWhitelistUntil = 0
getgenv().ToxTeleportWhitelistReason = nil
getgenv().AllowToxTeleport = function(seconds, reason)
    local untilTime = tick() + (tonumber(seconds) or 1)

    getgenv().ToxTeleportBypassUntil = math.max(
        tonumber(getgenv().ToxTeleportBypassUntil) or 0,
        untilTime
    )

    getgenv().ToxTeleportWhitelistUntil = math.max(
        tonumber(getgenv().ToxTeleportWhitelistUntil) or 0,
        untilTime
    )

    getgenv().ToxTeleportWhitelistReason = tostring(reason or "ToxHub")
end

getgenv().ToxIsToxTeleportAllowed = function()
    return tick() < math.max(
        tonumber(getgenv().ToxTeleportBypassUntil) or 0,
        tonumber(getgenv().ToxTeleportWhitelistUntil) or 0
    )
end

getgenv().Settings = {
	Noclip = false,
	InfiniteJump = false,
	Speed = false,
	Jump = false,
	SmoothFly = false,
    NormalFly = false,
	NoFallDamage = false,
	AntiVoid = false,
	AntiFling = true,
	CtrlClickTP = false,
	AntiAFK = true,
	ChatLogs = false,
	Render3D = true,
    Render3DDisabled = false,
    Render3DColor = "BLACK",
    AntiKick = false,
    FPSBooster = false,
	AutoExecute = false,
	GUIKeybind = Enum.KeyCode.LeftAlt,
    GUIColorName = "Blue",
    GUIScales = {},
    GUISizes = {},

	SpeedValue = 16,
	JumpValue = 50,
	FlySpeed = 10,

    FOVEnabled = false,
    FOVValue = 70,
    NoclipCamera = false,
    Freecam = false,
    FreecamSpeed = 50,
    ForceShiftLock = false,
    ShiftLockKey = "Shift",
    MaxZoom = false,
    MaxZoomDistance = 400,

    Aimbot = false,
    AimbotMode = "CAMERA",
    AimbotBindEnabled = false,
    AimbotKey = Enum.KeyCode.E,
    AimbotUseLeftClick = false,
    AimbotUseGuiInset = false,
    AimbotBlatant = false,
    AimbotSmoothnessEnabled = false,
    AimbotSmoothness = 2,
    AimPart = "Head",
    AimWallCheck = false,
    AimLock = false,
    LockRadius = 110,
    AimTargets = "Players Only",
    IgnoreFriends = false,
    ShowFOV = false,
    FOVRadius = 120,
    SilentAim = false,
    Triggerbot = false,
    Spinbot = false,
    SpinSpeed = 50,
    HitboxExpander = false,
    HitboxSize = 10,
    KillAura = false,
    KillAuraRange = 15,

    Bhop = false,
    BhopInterval = 0.2,
    AirWalk = false,
    NormalizeAnimations = false,
    ForceJump = false,
    CarSpeed = false,
    CarSpeedValue = 100,
    CarFly = false,
    CarFlySpeed = 80,
    LoopTPTarget = nil,

    ESPEnabled = false,
    ESPNames = false,
    ESPNameMode = "Display",
    ESPDistance = false,
    ESPTracers = false,
    ESPBox = false,
    ESPHeadDot = false,
    Crosshair = false,
    MouseIconID = "",
    MouseIconSize = 150,
    Fullbright = false,
    AdjustLighting = false,
    LightingTechnology = "ShadowMap",
    LightingAmbientColorName = "White",
    LightingOutdoorAmbientColorName = "White",
    LightingClockTime = 14,
    LightingBrightness = 1,
    LightingShadowSoftness = 0.5,
    LightingDiffuseScale = 1,
    LightingSpecularScale = 1,
    LightingGlobalShadows = false,
    LightingFogColorName = "White",
    LightingFogStart = 0,
    LightingFogEnd = 100000,
    LightingSunRays = false,
    LightingSunRaysIntensity = 0.25,
    LightingSunRaysSpread = 1,
    LightingBloom = false,
    LightingBloomIntensity = 1,
    LightingBloomSize = 24,
    LightingBloomThreshold = 2,
    LightingColorCorrection = false,
    LightingColorBrightness = 0,
    LightingColorContrast = 0,
    LightingColorSaturation = 0,
    LightingBlur = false,
    LightingBlurSize = 0,
    LightingFixShadows = false,
    LightingRemoveAtmosphere = false,
    LightingRemoveSkyboxes = false,
    LightingRemoveGrading = false,
    TracerOrigin = "DOWN",
    EspMaxDistance = 1000,
    EspMaxDistanceByPlace = {},
    Chams = false,
	EspColorName = "White",
	EspColor = Color3.fromRGB(255, 255, 255),
    ESPTeamColors = false,
    ESPShowHealth = false,
    VisualRainbow = false,
    RainbowSpeed = 10,
    XRay = false,
    XRayTransparency = 0.7,
    FakeLag = false,
    LagChance = 70,
    FixUnanchoredParts = false,
    StartHidden = false,
    UnlockCursor = false,
    PanicKey = nil,

    MusicAutoPlay = false,
    MusicLoop = false,
    MusicVolume = 100,
    CurrentTrackIndex = 1,

    NDSAutoWin = false,
    NDSWaterFly = false,
    NDSWaterFlySpeed = 40,
    NDSNoTP = false,
    NDSNotifyDisasters = false,
    NDSMuteCheerSound = false,
    NDSRemoveMeteors = false,
    NDSRemoveVolcanicLava = false,
    NDSRemoveVirusParticles = false,
    NDSRemoveTsunamiWave = false,
    NDSRemoveBarbedWire = false,
    NDSIslandRocksCollidable = false,

    MM2RoleESP = false,
    MM2AutoFarm = false,
    MM2AutoFarmV2 = false,
    MM2AutoFarmSpeed = 5,
    MM2AutoFarmResetOnFull = false,
    MM2Whitelist = {},
    MM2SilentAimKey = Enum.KeyCode.E,
    MM2KillAllKey = Enum.KeyCode.K,
    MM2KillAllAuto = false,
    MM2KillAllAutoV2 = false,
    MM2ShootMurderKey = Enum.KeyCode.C,
    MM2ShootMurderAuto = false,
    MM2ShootMurderAutoV2 = false,
    MM2GrabGunKey = Enum.KeyCode.G,
    MM2GrabGunAuto = false,
    MM2GrabGunAutoV2 = false,
    MM2FlingTarget = "Murderer",

    ADMINPrefix = ".",
    ADMINKillTarget = "",
    ADMINKillAll = false,
    ADMINRocketTarget = "",
    ADMINRocketAll = false,
    ADMINKickTarget = "",

    ToxLastChangelogVersion = "",
    ToxServerInfoVisible = false,
    ToxServerInfoMode = "FPS/Ping/Players"
}

local PersistedSettingKeys = {}

for key in pairs(getgenv().Settings) do
    PersistedSettingKeys[key] = true
end

getgenv().SavedIDs = {}
getgenv().SavedJoinGames = {}
getgenv().SavedWaypoints = {}
getgenv().SavedWaypointsByPlace = {}
getgenv().UIPositions = {}
getgenv().GameSharedSettings = {}
getgenv().GameSpecificSettings = {}
getgenv().BaseSharedSettings = {}
getgenv().Destroyed = false
getgenv().ScriptLoaded = false
getgenv().ToxOptionsReady = nil
getgenv().ToxStartupBooleanState = {}
getgenv().ToxStartupToggleCallbacks = {}
getgenv().ToxStartupOptionsApplied = false
getgenv().ToxHubActive = true
getgenv().__ToxHubBootLock = nil
getgenv().ToxModule1SplitVersion = "2026-09-16-autoexecute-single-v8-1"
getgenv().ToxUniversalLoaded = nil
getgenv().ToxUniversal2Loaded = nil
getgenv().ToxUniversal2Version = nil
getgenv().ToxUniversal2ExtraLoaded = nil
getgenv().ToxChatLoaded = nil
getgenv().ToxSystemsLoaded = nil
getgenv().ToxMM2LoaderJobId = nil
getgenv().ToxMM2LoaderVersion = nil
getgenv().ToxMM2LoaderPage = nil
getgenv().ToxMM2CoreReady = nil
getgenv().ToxMM2CoreVersion = nil
getgenv().ToxControlGui = nil
getgenv().ToxGameModuleLoadedUrl = nil
getgenv().ToxGameModuleLoadedPage = nil
getgenv().ToxGameModuleLoadingUrl = nil
getgenv().ToxGameModuleLoadingPage = nil
Destroyed = false
ScriptLoaded = false

if getgenv().ScriptConnections then
    for _, conn in ipairs(getgenv().ScriptConnections) do
        pcall(function() conn:Disconnect() end)
    end
end
getgenv().ScriptConnections = {}

getgenv().OriginalLighting = {
    Ambient = Lighting.Ambient,
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows
}

getgenv().AddConnection = function(conn)
    table.insert(getgenv().ScriptConnections, conn)
    return conn
end

local FolderName = "ToxV1_Data"
local CurrentPlaceKey = tostring(game.PlaceId)
local LegacyUserConfigFilePath =
    FolderName
    .. "/config_"
    .. tostring(Player.UserId)
    .. ".json"

local ConfigFilePath =
    FolderName
    .. "/config_"
    .. tostring(Player.UserId)
    .. "_"
    .. CurrentPlaceKey
    .. ".json"

local PrimaryConfigFilePath =
    LegacyUserConfigFilePath

local ConfigBackupFilePath =
    FolderName
    .. "/config_"
    .. tostring(Player.UserId)
    .. "_backup.json"

local MusicIDsFilePath =
    FolderName
    .. "/music_ids.json"

local JoinGamesFilePath =
    FolderName
    .. "/saved_join_games.json"

local LegacyConfigFilePath =
    FolderName
    .. "/config.json"

getgenv().ToxConfigFilePath =
    PrimaryConfigFilePath

getgenv().ToxPlaceConfigFilePath =
    ConfigFilePath

getgenv().ToxConfigBackupFilePath =
    ConfigBackupFilePath

getgenv().ToxLegacyUserConfigFilePath =
    LegacyUserConfigFilePath

getgenv().ToxConfigPlaceId =
    game.PlaceId

getgenv().ToxMusicIDsFilePath =
    MusicIDsFilePath

getgenv().ToxJoinGamesFilePath =
    JoinGamesFilePath

local function EnsureFolder()
    if makefolder and isfolder then
        pcall(function()
            if not isfolder(FolderName) then makefolder(FolderName) end
        end)
    end
end

local SharedPersistentKeys = {
    Speed = true,
    SpeedValue = true,
    Noclip = true,
    CtrlClickTP = true,
    NoFallDamage = true,
    AntiVoid = true,
    AntiFling = true,
    CarFly = true,
    CarFlySpeed = true,
    Chams = true,
    ESPEnabled = true,
    ESPNames = true,
    ESPTeamColors = true
}

getgenv().SharedPersistentKeys = SharedPersistentKeys

local function PersistentSetting(Key)
    return Settings[Key]
end

local function GetGameSettingOwner(Key)
    if typeof(Key) ~= "string" then
        return nil
    end

    for PlaceId, Info in pairs(getgenv().GameModuleRegistry or {}) do
        local Prefix = Info and tostring(Info.ShortName or "") or ""

        if Prefix ~= ""
        and string.sub(Key, 1, #Prefix) == Prefix then
            return tostring(PlaceId), Prefix
        end
    end

    return nil
end

local function IsCurrentGameSetting(Key)
    local OwnerPlaceId = GetGameSettingOwner(Key)

    return OwnerPlaceId ~= nil
        and OwnerPlaceId == tostring(game.PlaceId)
end

local function SerializeConfigValue(value, seen)
    local valueType = typeof(value)

    if value == nil then
        return {
            __toxType = "Nil"
        }
    end

    if valueType == "boolean"
    or valueType == "number"
    or valueType == "string" then
        return value
    end

    if valueType == "EnumItem" then
        local enumTypeName = tostring(value.EnumType):match("^Enum%.(.+)$")

        return {
            __toxType = "EnumItem",
            enumType = enumTypeName,
            name = value.Name
        }
    end

    if valueType == "Color3" then
        return {
            __toxType = "Color3",
            r = value.R,
            g = value.G,
            b = value.B
        }
    end

    if valueType == "Vector2" then
        return {
            __toxType = "Vector2",
            x = value.X,
            y = value.Y
        }
    end

    if valueType == "Vector3" then
        return {
            __toxType = "Vector3",
            x = value.X,
            y = value.Y,
            z = value.Z
        }
    end

    if valueType == "UDim" then
        return {
            __toxType = "UDim",
            scale = value.Scale,
            offset = value.Offset
        }
    end

    if valueType == "UDim2" then
        return {
            __toxType = "UDim2",
            xScale = value.X.Scale,
            xOffset = value.X.Offset,
            yScale = value.Y.Scale,
            yOffset = value.Y.Offset
        }
    end

    if valueType == "CFrame" then
        return {
            __toxType = "CFrame",
            components = {value:GetComponents()}
        }
    end

    if valueType == "Instance" then
        if value:IsA("Player") then
            return {
                __toxType = "Player",
                userId = value.UserId
            }
        end

        return {
            __toxType = "Unsupported"
        }
    end

    if valueType == "table" then
        seen = seen or {}

        if seen[value] then
            return {
                __toxType = "Cycle"
            }
        end

        seen[value] = true

        local result = {}

        for key, item in pairs(value) do
            local serializedKey = key

            if typeof(key) ~= "string"
            and typeof(key) ~= "number" then
                serializedKey = tostring(key)
            end

            result[serializedKey] = SerializeConfigValue(
                item,
                seen
            )
        end

        seen[value] = nil
        return result
    end

    return {
        __toxType = "Unsupported"
    }
end

local function DeserializeConfigValue(value)
    if typeof(value) ~= "table" then
        return value
    end

    local marker = rawget(value, "__toxType")

    if marker == "Nil" then
        return nil
    end

    if marker == "EnumItem" then
        local enumType = value.enumType and Enum[value.enumType]

        if enumType and value.name then
            local ok, enumItem = pcall(function()
                return enumType[value.name]
            end)

            if ok then
                return enumItem
            end
        end

        return nil
    end

    if marker == "Color3" then
        return Color3.new(
            tonumber(value.r) or 0,
            tonumber(value.g) or 0,
            tonumber(value.b) or 0
        )
    end

    if marker == "Vector2" then
        return Vector2.new(
            tonumber(value.x) or 0,
            tonumber(value.y) or 0
        )
    end

    if marker == "Vector3" then
        return Vector3.new(
            tonumber(value.x) or 0,
            tonumber(value.y) or 0,
            tonumber(value.z) or 0
        )
    end

    if marker == "UDim" then
        return UDim.new(
            tonumber(value.scale) or 0,
            tonumber(value.offset) or 0
        )
    end

    if marker == "UDim2" then
        return UDim2.new(
            tonumber(value.xScale) or 0,
            tonumber(value.xOffset) or 0,
            tonumber(value.yScale) or 0,
            tonumber(value.yOffset) or 0
        )
    end

    if marker == "CFrame" then
        local components = value.components

        if typeof(components) == "table"
        and #components >= 12 then
            return CFrame.new(table.unpack(components))
        end

        return CFrame.new()
    end

    if marker == "Player" then
        return Players:GetPlayerByUserId(
            tonumber(value.userId) or 0
        )
    end

    if marker == "Unsupported"
    or marker == "Cycle" then
        return nil
    end

    local result = {}

    for key, item in pairs(value) do
        result[key] = DeserializeConfigValue(item)
    end

    return result
end

local function DecodeSavedIDsFromFile(
    path
)
    if not isfile
    or not readfile
    or not path
    or not isfile(path) then
        return nil
    end

    local ok, value =
        pcall(function()
            local raw =
                readfile(path)

            if not raw
            or raw == "" then
                return nil
            end

            local data =
                HttpService:
                    JSONDecode(raw)

            if typeof(data)
                ~= "table" then
                return nil
            end

            local source =
                data.SavedIDs
                or data.IDs
                or data

            local decoded =
                DeserializeConfigValue(
                    source
                )

            if typeof(decoded)
                == "table"
            and next(decoded)
                ~= nil then
                return decoded
            end

            return nil
        end)

    if ok then
        return value
    end

    return nil
end

local function SaveSharedMusicIDs()
    EnsureFolder()

    if not writefile then
        return false
    end

    local data = {
        Version = 1,
        SavedIDs =
            SerializeConfigValue(
                getgenv().SavedIDs
                or {}
            )
    }

    return pcall(function()
        writefile(
            MusicIDsFilePath,
            HttpService:
                JSONEncode(data)
        )
    end)
end

local function LoadSharedMusicIDs()
    local saved =
        DecodeSavedIDsFromFile(
            MusicIDsFilePath
        )

    if not saved then
        saved =
            DecodeSavedIDsFromFile(
                LegacyConfigFilePath
            )
    end

    if not saved then
        saved =
            DecodeSavedIDsFromFile(
                ConfigFilePath
            )
    end

    if not saved
    and listfiles then
        pcall(function()
            local files =
                listfiles(
                    FolderName
                )

            for _, path in ipairs(
                files
            ) do
                local normalized =
                    tostring(path)
                        :gsub("\\", "/")

                if string.match(
                    normalized,
                    "/config_%d+%.json$"
                )
                or string.match(
                    normalized,
                    "/config_%d+_%d+%.json$"
                ) then
                    local candidate =
                        DecodeSavedIDsFromFile(
                            path
                        )

                    if candidate then
                        saved = candidate
                        break
                    end
                end
            end
        end)
    end

    if typeof(saved)
        == "table" then
        getgenv().SavedIDs =
            saved

        SaveSharedMusicIDs()
    end
end

getgenv().SaveToxMusicIDs =
    SaveSharedMusicIDs

local function DecodeSavedJoinGamesFromFile(
    path
)
    if not isfile
    or not readfile
    or not path
    or not isfile(path) then
        return nil
    end

    local ok, value =
        pcall(function()
            local raw =
                readfile(path)

            if not raw
            or raw == "" then
                return nil
            end

            local data =
                HttpService:
                    JSONDecode(raw)

            if typeof(data)
                ~= "table" then
                return nil
            end

            local source =
                data.SavedJoinGames
                or data.JoinGames
                or data.PlaceIDs

            if source == nil then
                return nil
            end

            local decoded =
                DeserializeConfigValue(
                    source
                )

            if typeof(decoded)
                == "table"
            and next(decoded)
                ~= nil then
                return decoded
            end

            return nil
        end)

    if ok then
        return value
    end

    return nil
end

local function SaveSharedJoinGames()
    EnsureFolder()

    if not writefile then
        return false
    end

    local data = {
        Version = 1,
        SavedJoinGames =
            SerializeConfigValue(
                getgenv().SavedJoinGames
                or {}
            )
    }

    return pcall(function()
        writefile(
            JoinGamesFilePath,
            HttpService:
                JSONEncode(data)
        )
    end)
end

local function LoadSharedJoinGames()
    local saved =
        DecodeSavedJoinGamesFromFile(
            JoinGamesFilePath
        )

    if not saved then
        saved =
            DecodeSavedJoinGamesFromFile(
                LegacyConfigFilePath
            )
    end

    if not saved then
        saved =
            DecodeSavedJoinGamesFromFile(
                ConfigFilePath
            )
    end

    if not saved
    and listfiles then
        pcall(function()
            local files =
                listfiles(
                    FolderName
                )

            for _, path in ipairs(
                files
            ) do
                local normalized =
                    tostring(path)
                        :gsub("\\", "/")

                if string.match(
                    normalized,
                    "/config_%d+%.json$"
                )
                or string.match(
                    normalized,
                    "/config_%d+_%d+%.json$"
                ) then
                    local candidate =
                        DecodeSavedJoinGamesFromFile(
                            path
                        )

                    if candidate then
                        saved = candidate
                        break
                    end
                end
            end
        end)
    end

    if typeof(saved)
        == "table" then
        getgenv().SavedJoinGames =
            saved

        SaveSharedJoinGames()
    end
end

getgenv().SaveToxJoinGames =
    SaveSharedJoinGames

local function BuildGlobalSettingsSnapshot()
    local snapshot = {}
    local keys = {}

    for key in pairs(PersistedSettingKeys) do
        keys[key] = true
    end

    for key in pairs(Settings) do
        keys[key] = true
    end

    for key in pairs(keys) do
        local ownerPlaceId = GetGameSettingOwner(key)

        if not ownerPlaceId then
            snapshot[key] = SerializeConfigValue(
                Settings[key]
            )
        end
    end

    snapshot.GUIKeybind = SerializeConfigValue(
        Settings.GUIKeybind
    )

    return snapshot
end

local function BuildCurrentGameSettingsSnapshot()
    local snapshot = {}

    for key in pairs(PersistedSettingKeys) do
        if IsCurrentGameSetting(key) then
            snapshot[key] = SerializeConfigValue(
                Settings[key]
            )
        end
    end

    for key in pairs(Settings) do
        if IsCurrentGameSetting(key) then
            snapshot[key] = SerializeConfigValue(
                Settings[key]
            )
        end
    end

    return snapshot
end

local function ApplyLoadedSetting(key, savedValue)
    local value

    if typeof(savedValue) == "table"
    and savedValue.__toxType then
        value = DeserializeConfigValue(savedValue)
    elseif key == "GUIKeybind"
    or key == "MM2SilentAimKey"
    or key == "MM2KillAllKey"
    or key == "MM2ShootMurderKey"
    or key == "MM2GrabGunKey" then
        if savedValue == "NONE"
        or savedValue == nil then
            value = nil
        else
            local ok, enumItem = pcall(function()
                return Enum.KeyCode[savedValue]
            end)

            if ok then
                value = enumItem
            end
        end
    else
        value = DeserializeConfigValue(savedValue)
    end

    if key == "EspColorName" then
        Settings.EspColorName = value
        Settings.EspColor =
            ColorMap[value]
            or Settings.EspColor
    elseif key == "EspColor"
    and typeof(value) == "Color3" then
        Settings.EspColor = value
    else
        Settings[key] = value
    end

    PersistedSettingKeys[key] = true
end

local function MigrateLegacyGameSettings(data)
    getgenv().GameSpecificSettings =
        typeof(getgenv().GameSpecificSettings) == "table"
        and getgenv().GameSpecificSettings
        or {}

    if typeof(data.GameSpecificSettings) == "table" then
        local decoded = DeserializeConfigValue(
            data.GameSpecificSettings
        )

        if typeof(decoded) == "table" then
            for placeKey, state in pairs(decoded) do
                if typeof(state) == "table" then
                    getgenv().GameSpecificSettings[tostring(placeKey)] =
                        state
                end
            end
        end
    end

    if typeof(data.GameSettings) == "table" then
        local decoded = DeserializeConfigValue(
            data.GameSettings
        )

        if typeof(decoded) == "table" then
            for placeKey, state in pairs(decoded) do
                local key = tostring(placeKey)

                if typeof(state) == "table"
                and getgenv().GameSpecificSettings[key] == nil then
                    getgenv().GameSpecificSettings[key] = state
                end
            end
        end
    end

    if typeof(data.Settings) == "table" then
        for key, savedValue in pairs(data.Settings) do
            local ownerPlaceId = GetGameSettingOwner(key)

            if ownerPlaceId then
                if typeof(
                    getgenv().GameSpecificSettings[ownerPlaceId]
                ) ~= "table" then
                    getgenv().GameSpecificSettings[ownerPlaceId] = {}
                end

                if getgenv().GameSpecificSettings[ownerPlaceId][key] == nil then
                    getgenv().GameSpecificSettings[ownerPlaceId][key] =
                        savedValue
                end
            end
        end
    end
end

local function ReadConfigMetadata(path)
    if not isfile
    or not readfile
    or not path
    or not isfile(path) then
        return nil
    end

    local ok, data = pcall(function()
        local raw = readfile(path)

        if not raw
        or raw == "" then
            return nil
        end

        local decoded = HttpService:JSONDecode(raw)

        if typeof(decoded) ~= "table" then
            return nil
        end

        return decoded
    end)

    if ok then
        return data
    end

    return nil
end

local function ResolveConfigReadPath()
    if not isfile then
        return nil, false
    end

    local primaryData =
        ReadConfigMetadata(
            PrimaryConfigFilePath
        )

    if primaryData
    and (tonumber(primaryData.ConfigVersion) or 0) >= 7 then
        return PrimaryConfigFilePath, false
    end

    if isfile(ConfigFilePath) then
        return ConfigFilePath, true
    end

    if primaryData then
        return PrimaryConfigFilePath, true
    end

    if isfile(LegacyConfigFilePath) then
        return LegacyConfigFilePath, true
    end

    return nil, false
end

getgenv().AutoSaveConfiguration = function()
    if getgenv().Destroyed then
        return false
    end

    if getgenv().ToxOptionsReady == false then
        return false
    end

    EnsureFolder()

    if not writefile then
        getgenv().ToxConfigLastSaveOK = false
        getgenv().ToxConfigLastSaveError = "writefile unavailable"
        return false
    end

    local placeKey = tostring(game.PlaceId)

    getgenv().GameSpecificSettings =
        typeof(getgenv().GameSpecificSettings) == "table"
        and getgenv().GameSpecificSettings
        or {}

    if getgenv().CurrentGameModule then
        getgenv().GameSpecificSettings[placeKey] =
            BuildCurrentGameSettingsSnapshot()
    end

    getgenv().SavedWaypointsByPlace =
        typeof(getgenv().SavedWaypointsByPlace) == "table"
        and getgenv().SavedWaypointsByPlace
        or {}

    getgenv().SavedWaypointsByPlace[placeKey] =
        getgenv().SavedWaypoints
        or {}

    local guiKeyName = "NONE"

    if Settings.GUIKeybind
    and typeof(Settings.GUIKeybind) == "EnumItem" then
        guiKeyName = Settings.GUIKeybind.Name
    end

    local data = {
        ConfigVersion = 7,
        SavedAt = os.time(),
        UserId = Player.UserId,
        PlaceId = game.PlaceId,
        ConfigScope = "USER_GLOBAL",
        GlobalGUIKeybind = guiKeyName,
        Settings = BuildGlobalSettingsSnapshot(),
        GameSpecificSettings = SerializeConfigValue(
            getgenv().GameSpecificSettings
        ),
        SavedWaypoints = SerializeConfigValue(
            getgenv().SavedWaypoints
        ),
        SavedWaypointsByPlace = SerializeConfigValue(
            getgenv().SavedWaypointsByPlace
        ),
        UIPositions = SerializeConfigValue(
            getgenv().UIPositions
        )
    }

    local encodeOK, encoded =
        pcall(function()
            return HttpService:JSONEncode(data)
        end)

    if not encodeOK
    or typeof(encoded) ~= "string"
    or encoded == "" then
        getgenv().ToxConfigLastSaveOK = false
        getgenv().ToxConfigLastSaveError =
            tostring(encoded or "JSON encode failed")
        return false
    end

    local oldPrimary = nil

    if readfile
    and isfile
    and isfile(PrimaryConfigFilePath) then
        pcall(function()
            oldPrimary = readfile(PrimaryConfigFilePath)
        end)
    end

    local primaryOK, primaryError =
        pcall(function()
            writefile(
                PrimaryConfigFilePath,
                encoded
            )
        end)

    local mirrorOK =
        pcall(function()
            writefile(
                ConfigFilePath,
                encoded
            )
        end)

    if primaryOK
    and oldPrimary
    and oldPrimary ~= ""
    and oldPrimary ~= encoded then
        pcall(function()
            writefile(
                ConfigBackupFilePath,
                oldPrimary
            )
        end)
    end

    getgenv().ToxConfigLastSaveOK =
        primaryOK == true

    getgenv().ToxConfigLastSaveError =
        primaryOK
        and nil
        or tostring(primaryError)

    getgenv().ToxConfigLastSavedAt =
        primaryOK
        and data.SavedAt
        or getgenv().ToxConfigLastSavedAt

    SaveSharedMusicIDs()
    SaveSharedJoinGames()

    return primaryOK or mirrorOK
end

local function LoadConfiguration()
    if not readfile then
        return
    end

    local sourcePath,
        migratedFromLegacy =
        ResolveConfigReadPath()

    if not sourcePath then
        return
    end

    getgenv().ToxConfigLoadedFrom = sourcePath

    local loaded = false
    local strictPlaceMigration = false

    pcall(function()
        local raw = readfile(sourcePath)

        if not raw or raw == "" then
            return
        end

        local data = HttpService:JSONDecode(raw)

        if typeof(data) ~= "table" then
            return
        end

        local configVersion = tonumber(data.ConfigVersion) or 0
        local savedPlaceId = tonumber(data.PlaceId)

        if configVersion < 7
        and savedPlaceId
        and savedPlaceId ~= game.PlaceId then
            return
        end
        strictPlaceMigration =
            game.PlaceId == 189707
            and configVersion < 6

        MigrateLegacyGameSettings(data)

        if typeof(data.Settings) == "table"
        and not strictPlaceMigration then
            for key, savedValue in pairs(data.Settings) do
                if not GetGameSettingOwner(key) then
                    ApplyLoadedSetting(
                        key,
                        savedValue
                    )
                end
            end
        end

        local currentGameState =
            getgenv().GameSpecificSettings[
                tostring(game.PlaceId)
            ]

        if typeof(currentGameState) == "table" then
            local decodedState =
                DeserializeConfigValue(
                    currentGameState
                )

            if typeof(decodedState) == "table" then
                for key, savedValue in pairs(decodedState) do
                    if IsCurrentGameSetting(key) then
                        if typeof(savedValue) == "EnumItem"
                        or typeof(savedValue) == "Color3"
                        or typeof(savedValue) == "CFrame"
                        or typeof(savedValue) == "Vector2"
                        or typeof(savedValue) == "Vector3"
                        or typeof(savedValue) == "UDim"
                        or typeof(savedValue) == "UDim2" then
                            Settings[key] = savedValue
                            PersistedSettingKeys[key] = true
                        else
                            ApplyLoadedSetting(
                                key,
                                savedValue
                            )
                        end
                    end
                end
            end
        end

        if data.GlobalGUIKeybind ~= nil then
            local keyName = tostring(
                data.GlobalGUIKeybind
            )

            if keyName == "NONE"
            or keyName == "" then
                Settings.GUIKeybind = nil
            else
                local ok, enumItem = pcall(function()
                    return Enum.KeyCode[keyName]
                end)

                if ok and enumItem then
                    Settings.GUIKeybind = enumItem
                end
            end
        end

        local currentPlaceKey = tostring(game.PlaceId)

        if data.SavedWaypointsByPlace ~= nil then
            local value = DeserializeConfigValue(
                data.SavedWaypointsByPlace
            )

            if typeof(value) == "table" then
                local currentValue = value[currentPlaceKey]

                if typeof(currentValue) == "table" then
                    getgenv().SavedWaypointsByPlace =
                        typeof(getgenv().SavedWaypointsByPlace) == "table"
                        and getgenv().SavedWaypointsByPlace
                        or {}

                    getgenv().SavedWaypointsByPlace[currentPlaceKey] =
                        currentValue
                elseif migratedFromLegacy then
                    getgenv().SavedWaypointsByPlace = value
                end
            end
        end

        if data.SavedWaypoints ~= nil then
            local value = DeserializeConfigValue(
                data.SavedWaypoints
            )

            if typeof(value) == "table" then
                getgenv().SavedWaypointsByPlace =
                    typeof(getgenv().SavedWaypointsByPlace) == "table"
                    and getgenv().SavedWaypointsByPlace
                    or {}

                if typeof(getgenv().SavedWaypointsByPlace[currentPlaceKey]) ~= "table" then
                    getgenv().SavedWaypointsByPlace[currentPlaceKey] = value
                end
            end
        end

        if typeof(getgenv().SavedWaypointsByPlace) == "table"
        and typeof(getgenv().SavedWaypointsByPlace[currentPlaceKey]) == "table" then
            getgenv().SavedWaypoints = getgenv().SavedWaypointsByPlace[currentPlaceKey]
        end

        if data.UIPositions ~= nil then
            local value = DeserializeConfigValue(
                data.UIPositions
            )

            if typeof(value) == "table" then
                getgenv().UIPositions = value
            end
        end

        loaded = true
    end)

    if loaded
    and (migratedFromLegacy or strictPlaceMigration) then
        getgenv().AutoSaveConfiguration()
    end
end

local function NormalizeStartupDefaultToggles()
    Settings.AntiAFK = true
    Settings.AntiFling = true
    Settings.Render3D = true
    Settings.Render3DDisabled = false
end

local function DisableUnsupportedGameActions()
    if getgenv().CurrentGameModule then
        return
    end

    for key, value in pairs(Settings) do
        if typeof(value) == "boolean" then
            Settings[key] = false
        end
    end

    Settings.AntiAFK = true
    Settings.AntiFling = true
    Settings.Render3D = true
    Settings.Render3DDisabled = false
end

local function StageOptionsUntilLoadScreen()
    local staged = {}

    for key, value in pairs(Settings) do
        if typeof(value) == "boolean" then
            staged[key] = value == true

            if key ~= "Render3D" then
                Settings[key] = false
            end
        end
    end

    getgenv().ToxStartupBooleanState = staged
    getgenv().ToxStartupToggleCallbacks = {}
    getgenv().ToxStartupOptionsApplied = false
    getgenv().ToxOptionsReady = false
end

LoadConfiguration()
NormalizeStartupDefaultToggles()
DisableUnsupportedGameActions()
StageOptionsUntilLoadScreen()

getgenv().SavedWaypointsByPlace =
    typeof(getgenv().SavedWaypointsByPlace) == "table"
    and getgenv().SavedWaypointsByPlace
    or {}

local CurrentWaypointPlaceKey = tostring(game.PlaceId)

if typeof(getgenv().SavedWaypointsByPlace[CurrentWaypointPlaceKey]) ~= "table" then
    getgenv().SavedWaypointsByPlace[CurrentWaypointPlaceKey] =
        typeof(getgenv().SavedWaypoints) == "table"
        and getgenv().SavedWaypoints
        or {}
end

getgenv().SavedWaypoints =
    getgenv().SavedWaypointsByPlace[CurrentWaypointPlaceKey]

getgenv().GetCurrentToxWaypoints = function()
    local placeKey = tostring(game.PlaceId)

    getgenv().SavedWaypointsByPlace =
        typeof(getgenv().SavedWaypointsByPlace) == "table"
        and getgenv().SavedWaypointsByPlace
        or {}

    if typeof(getgenv().SavedWaypointsByPlace[placeKey]) ~= "table" then
        getgenv().SavedWaypointsByPlace[placeKey] = {}
    end

    getgenv().SavedWaypoints = getgenv().SavedWaypointsByPlace[placeKey]

    return getgenv().SavedWaypoints
end

if typeof(Settings.GUIScales) ~= "table" then
    Settings.GUIScales = {}
end

if typeof(Settings.GUISizes) ~= "table" then
    Settings.GUISizes = {}
end

local LoadedGUIColor =
    GUIColorMap[
        tostring(
            Settings.GUIColorName
            or "Blue"
        )
    ]

if LoadedGUIColor then
    MAIN_COLOR = LoadedGUIColor
    getgenv().MAIN_COLOR = MAIN_COLOR
else
    Settings.GUIColorName = "Blue"
end

LoadSharedMusicIDs()
LoadSharedJoinGames()

local function ResolveQueueOnTeleport()
    local env = getgenv()

    if env and type(env.queue_on_teleport) == "function" then
        return env.queue_on_teleport
    end

    if type(queue_on_teleport) == "function" then
        return queue_on_teleport
    end

    if syn and type(syn.queue_on_teleport) == "function" then
        return syn.queue_on_teleport
    end

    if fluxus and type(fluxus.queue_on_teleport) == "function" then
        return fluxus.queue_on_teleport
    end

    return nil
end

local AutoExecutePayload = [[
if not game:IsLoaded() then
    game.Loaded:Wait()
end

local env = getgenv()

task.wait(0.55)

local shouldExecute = true
local configWasRead = false

for _ = 1, 20 do
    local success = pcall(function()
        local Players =
            game:GetService("Players")

        local localPlayer =
            Players.LocalPlayer

        local userId = tostring(
            localPlayer
            and localPlayer.UserId
            or 0
        )

        local configPath =
            "ToxV1_Data/config_"
            .. userId
            .. "_"
            .. tostring(game.PlaceId)
            .. ".json"

        local legacyUserPath =
            "ToxV1_Data/config_"
            .. userId
            .. ".json"

        local legacyPath =
            "ToxV1_Data/config.json"

        local readPath = nil

        if isfile then
            if isfile(legacyUserPath) then
                local useGlobal = false

                if readfile then
                    pcall(function()
                        local HttpService =
                            game:GetService("HttpService")
                        local globalRaw =
                            readfile(legacyUserPath)

                        if globalRaw
                        and globalRaw ~= "" then
                            local globalData =
                                HttpService:JSONDecode(globalRaw)

                            useGlobal =
                                typeof(globalData) == "table"
                                and (tonumber(globalData.ConfigVersion) or 0) >= 7
                        end
                    end)
                end

                if useGlobal then
                    readPath = legacyUserPath
                end
            end

            if not readPath
            and isfile(configPath) then
                readPath = configPath
            elseif not readPath
            and isfile(legacyUserPath) then
                readPath = legacyUserPath
            elseif not readPath
            and isfile(legacyPath) then
                readPath = legacyPath
            end
        end

        if readfile
        and readPath then
            local HttpService = game:GetService("HttpService")
            local raw = readfile(readPath)

            if raw and raw ~= "" then
                local data = HttpService:JSONDecode(raw)

                if data and data.Settings then
                    shouldExecute = data.Settings.AutoExecute == true
                    configWasRead = true
                end
            end
        end
    end)

    if success and configWasRead then
        break
    end

    task.wait(0.25)
end

if not shouldExecute then
    return
end

if env.__ToxQueuedDestinationGame == game then
    return
end

env.__ToxQueuedDestinationGame = game

local ok = pcall(function()
    loadstring(
        game:HttpGet(
            "https://raw.githubusercontent.com/BG-0o/Scripts/main/ToxHud.lua"
        )
    )()
end)

if not ok
and env.__ToxQueuedDestinationGame == game then
    env.__ToxQueuedDestinationGame = nil
end
]]

if getgenv().ToxAutoExecuteQueuedGame ~= game then
    getgenv().ToxAutoExecuteQueued = false
    getgenv().ToxAutoExecuteQueuedGame = game
end

getgenv().QueueToxAutoExecute = function()
    if getgenv().ToxAutoExecuteQueued
    and getgenv().ToxAutoExecuteQueuedGame == game then
        return true
    end

    local queueFunction = ResolveQueueOnTeleport()

    if not queueFunction then
        return false
    end

    local ok = pcall(function()
        queueFunction(AutoExecutePayload)
    end)

    if ok then
        getgenv().ToxAutoExecuteQueued = true
        getgenv().ToxAutoExecuteQueuedGame = game
    end

    return ok
end

if Settings.AutoExecute then
    getgenv().QueueToxAutoExecute()
end

for Key in pairs(SharedPersistentKeys) do
    getgenv().BaseSharedSettings[Key] = Settings[Key]
end

pcall(function()
    if cleardrawcache then
        cleardrawcache()
    elseif Drawing and Drawing.clear then
        Drawing.clear()
    end
end)

if getgenv().FOVCircle then pcall(function() getgenv().FOVCircle:Remove() end) end
local FOVCircle = (Drawing and Drawing.new) and Drawing.new("Circle") or nil
if FOVCircle then
    FOVCircle.Color = Color3.fromRGB(0, 200, 255)
    FOVCircle.Thickness = 1.5
    FOVCircle.NumSides = 60
    FOVCircle.Filled = false
    FOVCircle.Visible = false
end
getgenv().FOVCircle = FOVCircle

if getgenv().CrosshairH then pcall(function() getgenv().CrosshairH:Remove() end) end
if getgenv().CrosshairV then pcall(function() getgenv().CrosshairV:Remove() end) end
local CrosshairH = (Drawing and Drawing.new) and Drawing.new("Line") or nil
local CrosshairV = (Drawing and Drawing.new) and Drawing.new("Line") or nil
if CrosshairH and CrosshairV then
    CrosshairH.Color = Color3.fromRGB(0, 255, 100)
    CrosshairH.Thickness = 1.5
    CrosshairH.Visible = false
    CrosshairV.Color = Color3.fromRGB(0, 255, 100)
    CrosshairV.Thickness = 1.5
    CrosshairV.Visible = false
end
getgenv().CrosshairH = CrosshairH
getgenv().CrosshairV = CrosshairV

local NotifGui = Instance.new("ScreenGui")
NotifGui.Name = "ToxNotifs"
NotifGui.DisplayOrder = 999
NotifGui.Parent = (gethui and gethui()) or game:GetService("CoreGui")
getgenv().NotifGui = NotifGui

local NotifContainer = Instance.new("Frame")
NotifContainer.Size = UDim2.new(0, 240, 1, -40)
NotifContainer.Position = UDim2.new(1, -250, 0, 20)
NotifContainer.BackgroundTransparency = 1
NotifContainer.Parent = NotifGui

local NotifLayout = Instance.new("UIListLayout")
NotifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
NotifLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
NotifLayout.SortOrder = Enum.SortOrder.LayoutOrder
NotifLayout.Padding = UDim.new(0, 6)
NotifLayout.Parent = NotifContainer

getgenv().ToxLastNotificationText = getgenv().ToxLastNotificationText or nil
getgenv().ToxLastNotificationTime = getgenv().ToxLastNotificationTime or 0

getgenv().CustomNotify = function(text, color, customTime)
    local now = os.clock()
    local message = tostring(text or "")

    if getgenv().ToxLastNotificationText == message
    and now - getgenv().ToxLastNotificationTime < 1.5 then
        return
    end

    getgenv().ToxLastNotificationText = message
    getgenv().ToxLastNotificationTime = now
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 38)
    Frame.BackgroundColor3 = Color3.fromRGB(12, 12, 20)
    Frame.BorderSizePixel = 0
    Frame.ClipsDescendants = true
    Frame.Parent = NotifContainer
    
    local Corner = Instance.new("UICorner") Corner.CornerRadius = UDim.new(0, 6) Corner.Parent = Frame
    local Stroke = Instance.new("UIStroke") Stroke.Color = MAIN_COLOR Stroke.Thickness = 1.5 Stroke.Parent = Frame
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -16, 1, 0)
    Label.Position = UDim2.new(0, 10, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = color or Color3.fromRGB(240, 240, 240)
    Label.Font = Enum.Font.GothamMedium
    Label.TextSize = 13
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextTruncate = Enum.TextTruncate.AtEnd
    Label.Parent = Frame
    
    Frame.BackgroundTransparency = 1 Label.TextTransparency = 1 Stroke.Transparency = 1

    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    TweenService:Create(Frame, tweenInfo, {BackgroundTransparency = 0}):Play()
    TweenService:Create(Label, tweenInfo, {TextTransparency = 0}):Play()
    TweenService:Create(Stroke, tweenInfo, {Transparency = 0}):Play()

    task.delay(customTime or 3, function()
        if Frame and Frame.Parent then
            local tweenOut = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
            local t1 = TweenService:Create(Frame, tweenOut, {BackgroundTransparency = 1})
            local t2 = TweenService:Create(Label, tweenOut, {TextTransparency = 1})
            local t3 = TweenService:Create(Stroke, tweenOut, {Transparency = 1})
            t1:Play() t2:Play() t3:Play()
            t1.Completed:Connect(function() Frame:Destroy() end)
        end
    end)
end

local ToxChatPopupContainer =
    Instance.new("Frame")

ToxChatPopupContainer.Name =
    "ToxChatPopupContainer"

ToxChatPopupContainer.Size =
    UDim2.new(
        0,
        350,
        0.62,
        -30
    )

ToxChatPopupContainer.Position =
    UDim2.new(
        1,
        -365,
        0,
        18
    )

ToxChatPopupContainer.BackgroundTransparency = 1
ToxChatPopupContainer.Parent = NotifGui

local ToxChatPopupLayout =
    Instance.new("UIListLayout")

ToxChatPopupLayout.VerticalAlignment =
    Enum.VerticalAlignment.Top

ToxChatPopupLayout.HorizontalAlignment =
    Enum.HorizontalAlignment.Right

ToxChatPopupLayout.SortOrder =
    Enum.SortOrder.LayoutOrder

ToxChatPopupLayout.Padding =
    UDim.new(
        0,
        7
    )

ToxChatPopupLayout.Parent =
    ToxChatPopupContainer

getgenv().ShowToxChatPopup =
    function(
        displayName,
        message,
        blocked
    )
        if not ToxChatPopupContainer
        or not ToxChatPopupContainer.Parent then
            return
        end

        local frame =
            Instance.new("Frame")

        frame.Size =
            UDim2.new(
                1,
                0,
                0,
                66
            )

        frame.AutomaticSize =
            Enum.AutomaticSize.Y

        frame.BackgroundColor3 =
            Color3.fromRGB(
                12,
                12,
                20
            )

        frame.BorderSizePixel = 0
        frame.ClipsDescendants = true
        frame.Parent =
            ToxChatPopupContainer

        local corner =
            Instance.new("UICorner")

        corner.CornerRadius =
            UDim.new(
                0,
                7
            )

        corner.Parent = frame

        local stroke =
            Instance.new("UIStroke")

        stroke.Color = MAIN_COLOR
        stroke.Thickness = 2
        stroke.Parent = frame

        local title =
            Instance.new("TextLabel")

        title.Size =
            UDim2.new(
                1,
                -20,
                0,
                22
            )

        title.Position =
            UDim2.new(
                0,
                10,
                0,
                7
            )

        title.BackgroundTransparency = 1
        title.Text =
            "Tox Chat • "
            .. tostring(
                displayName
            )

        title.TextColor3 =
            blocked
            and Color3.fromRGB(
                255,
                120,
                120
            )
            or Color3.fromRGB(
                245,
                245,
                255
            )

        title.Font =
            Enum.Font.GothamBold

        title.TextSize = 14
        title.TextXAlignment =
            Enum.TextXAlignment.Left

        title.TextTruncate =
            Enum.TextTruncate.AtEnd

        title.Parent = frame

        local body =
            Instance.new("TextLabel")

        body.Size =
            UDim2.new(
                1,
                -20,
                0,
                0
            )

        body.Position =
            UDim2.new(
                0,
                10,
                0,
                31
            )

        body.AutomaticSize =
            Enum.AutomaticSize.Y

        body.BackgroundTransparency = 1
        body.Text =
            tostring(
                message
            )

        body.TextColor3 =
            blocked
            and Color3.fromRGB(
                255,
                145,
                145
            )
            or Color3.fromRGB(
                225,
                225,
                238
            )

        body.Font =
            Enum.Font.GothamMedium

        body.TextSize = 14
        body.TextWrapped = true
        body.TextXAlignment =
            Enum.TextXAlignment.Left

        body.TextYAlignment =
            Enum.TextYAlignment.Top

        body.Parent = frame

        local padding =
            Instance.new("UIPadding")

        padding.PaddingBottom =
            UDim.new(
                0,
                9
            )

        padding.Parent = frame

        frame.BackgroundTransparency = 1
        title.TextTransparency = 1
        body.TextTransparency = 1
        stroke.Transparency = 1

        local tweenInfo =
            TweenInfo.new(
                0.28,
                Enum.EasingStyle.Quart,
                Enum.EasingDirection.Out
            )

        TweenService:
            Create(
                frame,
                tweenInfo,
                {
                    BackgroundTransparency = 0
                }
            ):
            Play()

        TweenService:
            Create(
                title,
                tweenInfo,
                {
                    TextTransparency = 0
                }
            ):
            Play()

        TweenService:
            Create(
                body,
                tweenInfo,
                {
                    TextTransparency = 0
                }
            ):
            Play()

        TweenService:
            Create(
                stroke,
                tweenInfo,
                {
                    Transparency = 0
                }
            ):
            Play()

        task.delay(
            5,
            function()
                if not frame
                or not frame.Parent then
                    return
                end

                local tweenOut =
                    TweenInfo.new(
                        0.3,
                        Enum.EasingStyle.Quart,
                        Enum.EasingDirection.In
                    )

                local fade =
                    TweenService:
                        Create(
                            frame,
                            tweenOut,
                            {
                                BackgroundTransparency = 1
                            }
                        )

                TweenService:
                    Create(
                        title,
                        tweenOut,
                        {
                            TextTransparency = 1
                        }
                    ):
                    Play()

                TweenService:
                    Create(
                        body,
                        tweenOut,
                        {
                            TextTransparency = 1
                        }
                    ):
                    Play()

                TweenService:
                    Create(
                        stroke,
                        tweenOut,
                        {
                            Transparency = 1
                        }
                    ):
                    Play()

                fade:Play()

                fade.Completed:
                    Connect(function()
                        if frame
                        and frame.Parent then
                            frame:
                                Destroy()
                        end
                    end)
            end
        )
    end

AddConnection(Players.PlayerAdded:Connect(function(p)
    if getgenv().ScriptLoaded then CustomNotify("(" .. p.Name .. ") joined", Color3.fromRGB(50, 255, 50), 3) end
end))

AddConnection(Players.PlayerRemoving:Connect(function(p)
    if getgenv().ScriptLoaded then CustomNotify("(" .. p.Name .. ") left", Color3.fromRGB(255, 50, 50), 3) end
end))

getgenv().MakeDraggable = function(Frame, DragHandle)
    local Dragging, DragInput, DragStart, StartPos
    DragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Dragging = true DragStart = input.Position StartPos = Frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then Dragging = false end
            end)
        end
    end)
    DragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            DragInput = input
        end
    end)
    AddConnection(UserInputService.InputChanged:Connect(function(input)
        if input == DragInput and Dragging then
            local Delta = input.Position - DragStart
            Frame.Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + Delta.X, StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y)
        end
    end))
end

local GuiSizeSaveTokens = {}

getgenv().GetSavedGuiSize =
    function(
        key,
        defaultSize
    )
        key =
            tostring(
                key
                or ""
            )

        Settings.GUISizes =
            typeof(Settings.GUISizes)
                == "table"
            and Settings.GUISizes
            or {}

        local saved =
            Settings.GUISizes[
                key
            ]

        if typeof(saved)
            == "table" then
            local width =
                tonumber(
                    saved.Width
                )

            local height =
                tonumber(
                    saved.Height
                )

            if width
            and height
            and width >= 200
            and height >= 100 then
                return
                    UDim2.new(
                        0,
                        math.floor(
                            width + 0.5
                        ),
                        0,
                        math.floor(
                            height + 0.5
                        )
                    )
            end
        end

        return defaultSize
    end

getgenv().MakeResizable =
    function(
        frame,
        key,
        minRatio,
        maxRatio
    )
        if not frame
        or not frame:IsA("GuiObject") then
            return nil
        end

        key =
            tostring(
                key
                or frame.Name
                or "GUI"
            )

        minRatio =
            math.clamp(
                tonumber(minRatio)
                or 0.85,
                0.75,
                1
            )

        maxRatio =
            math.clamp(
                tonumber(maxRatio)
                or 1.45,
                1,
                1.7
            )

        Settings.GUISizes =
            typeof(Settings.GUISizes)
                == "table"
            and Settings.GUISizes
            or {}

        local oldScale =
            frame:
                FindFirstChild(
                    "ToxGuiScale"
                )

        if oldScale then
            oldScale:
                Destroy()
        end

        local initialWidth =
            frame.Size.X.Offset

        local initialHeight =
            frame.Size.Y.Offset

        if initialWidth <= 0 then
            initialWidth = 330
        end

        if initialHeight <= 0 then
            initialHeight = 395
        end

        local minWidth =
            math.max(
                260,
                math.floor(
                    initialWidth
                    * minRatio
                )
            )

        local minHeight =
            math.max(
                220,
                math.floor(
                    initialHeight
                    * minRatio
                )
            )

        local maxWidth =
            math.max(
                minWidth,
                math.floor(
                    initialWidth
                    * maxRatio
                )
            )

        local maxHeight =
            math.max(
                minHeight,
                math.floor(
                    initialHeight
                    * maxRatio
                )
            )

        local saved =
            Settings.GUISizes[
                key
            ]

        if typeof(saved)
            == "table" then
            local width =
                tonumber(
                    saved.Width
                )

            local height =
                tonumber(
                    saved.Height
                )

            if width
            and height then
                frame.Size =
                    UDim2.new(
                        0,
                        math.clamp(
                            math.floor(
                                width + 0.5
                            ),
                            minWidth,
                            maxWidth
                        ),
                        0,
                        math.clamp(
                            math.floor(
                                height + 0.5
                            ),
                            minHeight,
                            maxHeight
                        )
                    )
            end
        end

        local oldHandle =
            frame:
                FindFirstChild(
                    "ToxResizeHandle"
                )

        if oldHandle then
            oldHandle:
                Destroy()
        end

        local handle =
            Instance.new(
                "TextButton"
            )

        handle.Name =
            "ToxResizeHandle"

        handle.Size =
            UDim2.new(
                0,
                20,
                0,
                20
            )

        handle.Position =
            UDim2.new(
                1,
                -20,
                1,
                -20
            )

        handle.BackgroundTransparency = 1
        handle.BorderSizePixel = 0
        handle.Text = "◢"

        handle.TextColor3 =
            Color3.fromRGB(
                175,
                175,
                195
            )

        handle.TextSize = 15
        handle.Font =
            Enum.Font.GothamBold

        handle.AutoButtonColor = false
        handle.Active = true
        handle.ZIndex = 100
        handle.Parent = frame

        local resizing = false
        local resizeInput = nil
        local dragStart = nil
        local startWidth = 0
        local startHeight = 0

        local function isFrameMinimized()
            if frame == getgenv().Main
            and getgenv().ToxMainMinimized == true then
                return true
            end

            if frame:FindFirstChild("ToxSubGuiMinimize")
            and frame.AbsoluteSize.Y <= 44 then
                return true
            end

            return false
        end

        local function saveSize()
            if isFrameMinimized() then
                return
            end

            local currentSize =
                frame.AbsoluteSize

            Settings.GUISizes[
                key
            ] = {
                Width =
                    math.floor(
                        currentSize.X
                        + 0.5
                    ),
                Height =
                    math.floor(
                        currentSize.Y
                        + 0.5
                    )
            }

            GuiSizeSaveTokens[
                key
            ] =
                (
                    GuiSizeSaveTokens[
                        key
                    ]
                    or 0
                )
                + 1

            local token =
                GuiSizeSaveTokens[
                    key
                ]

            task.delay(
                0.35,
                function()
                    if GuiSizeSaveTokens[
                        key
                    ] == token
                    and not Destroyed then
                        AutoSaveConfiguration()
                    end
                end
            )
        end

        handle.InputBegan:
            Connect(function(input)
                if input.UserInputType
                    ~= Enum.UserInputType.MouseButton1
                and input.UserInputType
                    ~= Enum.UserInputType.Touch then
                    return
                end

                if isFrameMinimized() then
                    resizing = false
                    return
                end

                resizing = true
                dragStart =
                    input.Position

                local currentSize =
                    frame.AbsoluteSize

                startWidth =
                    currentSize.X

                startHeight =
                    currentSize.Y

                input.Changed:
                    Connect(function()
                        if input.UserInputState
                            == Enum.UserInputState.End then
                            resizing = false
                            saveSize()
                        end
                    end)
            end)

        handle.InputChanged:
            Connect(function(input)
                if input.UserInputType
                    == Enum.UserInputType.MouseMovement
                or input.UserInputType
                    == Enum.UserInputType.Touch then
                    resizeInput =
                        input
                end
            end)

        AddConnection(
            UserInputService.InputChanged:
                Connect(function(input)
                    if not resizing
                    or input
                        ~= resizeInput
                    or not dragStart then
                        return
                    end

                    if isFrameMinimized() then
                        resizing = false
                        return
                    end

                    local delta =
                        input.Position
                        - dragStart

                    local viewport =
                        Camera.ViewportSize

                    local viewportMaxWidth =
                        math.max(
                            minWidth,
                            math.min(
                                maxWidth,
                                viewport.X
                                - 24
                            )
                        )

                    local viewportMaxHeight =
                        math.max(
                            minHeight,
                            math.min(
                                maxHeight,
                                viewport.Y
                                - 24
                            )
                        )

                    local newWidth =
                        math.clamp(
                            math.floor(
                                startWidth
                                + delta.X
                                + 0.5
                            ),
                            minWidth,
                            viewportMaxWidth
                        )

                    local newHeight =
                        math.clamp(
                            math.floor(
                                startHeight
                                + delta.Y
                                + 0.5
                            ),
                            minHeight,
                            viewportMaxHeight
                        )

                    frame.Size =
                        UDim2.new(
                            0,
                            newWidth,
                            0,
                            newHeight
                        )
                end)
        )

        return handle
    end

local GuiPositionSaveTokens = {}

getgenv().EncodeGuiPosition = function(position)
    return {
        XS = position.X.Scale,
        XO = position.X.Offset,
        YS = position.Y.Scale,
        YO = position.Y.Offset
    }
end

getgenv().DecodeGuiPosition = function(data)
    if typeof(data) ~= "table" then
        return nil
    end

    if typeof(data.XS) ~= "number"
    or typeof(data.XO) ~= "number"
    or typeof(data.YS) ~= "number"
    or typeof(data.YO) ~= "number" then
        return nil
    end

    return UDim2.new(data.XS, data.XO, data.YS, data.YO)
end

getgenv().GetSavedGuiPosition = function(key)
    return getgenv().DecodeGuiPosition(getgenv().UIPositions[key])
end

getgenv().ApplySavedGuiPosition = function(key, gui)
    if not gui then
        return nil
    end

    local saved = getgenv().GetSavedGuiPosition(key)

    if saved then
        gui.Position = saved
    end

    return saved or gui.Position
end

getgenv().TrackGuiPosition = function(key, gui)
    if not gui then
        return
    end

    AddConnection(gui:GetPropertyChangedSignal("Position"):Connect(function()
        getgenv().UIPositions[key] = getgenv().EncodeGuiPosition(gui.Position)
        GuiPositionSaveTokens[key] = (GuiPositionSaveTokens[key] or 0) + 1
        local token = GuiPositionSaveTokens[key]

        task.delay(0.25, function()
            if GuiPositionSaveTokens[key] == token and not Destroyed then
                AutoSaveConfiguration()
            end
        end)
    end))
end

local AirWalkPart = nil
local LockedAirWalkY = nil
local AirWalkLastUpdate = tick()

local function UpdateAirWalk()
    local now = tick()

    local deltaTime =
        math.clamp(
            now - AirWalkLastUpdate,
            0,
            0.08
        )

    AirWalkLastUpdate = now

    local Root =
        Player.Character
        and Player.Character:
            FindFirstChild(
                "HumanoidRootPart"
            )

    if Settings.AirWalk
    and Root then
        if not LockedAirWalkY then
            LockedAirWalkY =
                Root.Position.Y
                - 3.4
        end

        local vertical = 0

        if UserInputService:
            IsKeyDown(
                Enum.KeyCode.E
            ) then
            vertical += 1
        end

        if UserInputService:
            IsKeyDown(
                Enum.KeyCode.Q
            ) then
            vertical -= 1
        end

        if vertical ~= 0 then
            LockedAirWalkY +=
                vertical
                * 18
                * deltaTime
        end

        if not AirWalkPart
        or not AirWalkPart.Parent then
            AirWalkPart =
                Instance.new(
                    "Part"
                )

            AirWalkPart.Name =
                "ToxAirWalk"

            AirWalkPart.Size =
                Vector3.new(
                    8,
                    1,
                    8
                )

            AirWalkPart.Transparency = 1
            AirWalkPart.Anchored = true
            AirWalkPart.CanCollide = true
            AirWalkPart.Parent = workspace
        end

        AirWalkPart.CFrame =
            CFrame.new(
                Root.Position.X,
                LockedAirWalkY,
                Root.Position.Z
            )
    else
        LockedAirWalkY = nil

        if AirWalkPart then
            AirWalkPart:
                Destroy()

            AirWalkPart = nil
        end
    end
end

getgenv().UpdateAirWalk =
    UpdateAirWalk

local function UpdateMouseIcon()
    pcall(function()
        if Settings.Crosshair and Settings.MouseIconID ~= "" then
            local cleanID = tostring(Settings.MouseIconID):match("%d+")
            local sz = Settings.MouseIconSize or 150
            if cleanID then
                Player:GetMouse().Icon = "rbxthumb://type=Asset&id=" .. cleanID .. "&w=" .. tostring(sz) .. "&h=" .. tostring(sz)
            else
                Player:GetMouse().Icon = ""
            end
        else
            Player:GetMouse().Icon = ""
        end
    end)
end
getgenv().UpdateMouseIcon = UpdateMouseIcon

local function RestoreCollisions()
    if Player.Character then
        for _, part in ipairs(Player.Character:GetChildren()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.CanCollide = true
            end
        end
        local Hum = Player.Character:FindFirstChildOfClass("Humanoid")
        if Hum then
            Hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end
end
getgenv().RestoreCollisions = RestoreCollisions

local function ResetHitboxes()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.Size = Vector3.new(2, 2, 1)
                hrp.Transparency = 1
            end
        end
    end
end
getgenv().ResetHitboxes = ResetHitboxes

local FullbrightDefaults = nil
local FullbrightActive = false

local function CaptureFullbrightDefaults()
    return {
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        Brightness = Lighting.Brightness,
        ClockTime = Lighting.ClockTime,
        FogStart = Lighting.FogStart,
        FogEnd = Lighting.FogEnd,
        FogColor = Lighting.FogColor,
        GlobalShadows = Lighting.GlobalShadows,
        ExposureCompensation = Lighting.ExposureCompensation,
        ShadowSoftness = Lighting.ShadowSoftness,
        EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
        EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale
    }
end

local function RestoreFullbrightDefaults()
    local defaults = FullbrightDefaults
    FullbrightDefaults = nil
    FullbrightActive = false

    if not defaults then
        return
    end

    for property, value in pairs(defaults) do
        pcall(function()
            Lighting[property] = value
        end)
    end
end

local function UpdateFullbright()
    if Settings.Fullbright then
        if not FullbrightActive then
            FullbrightDefaults = CaptureFullbrightDefaults()
            FullbrightActive = true
        end

        pcall(function() Lighting.Ambient = Color3.fromRGB(180, 180, 180) end)
        pcall(function() Lighting.OutdoorAmbient = Color3.fromRGB(180, 180, 180) end)
        pcall(function() Lighting.Brightness = 1.2 end)
        pcall(function() Lighting.ClockTime = 14 end)
        pcall(function() Lighting.FogStart = 0 end)
        pcall(function() Lighting.FogEnd = 100000 end)
        pcall(function() Lighting.GlobalShadows = false end)
        pcall(function() Lighting.ExposureCompensation = 0 end)
    elseif FullbrightActive or FullbrightDefaults then
        RestoreFullbrightDefaults()
    end
end
getgenv().UpdateFullbright = UpdateFullbright
getgenv().RestoreFullbrightDefaults = RestoreFullbrightDefaults

local ParentContainer = (gethui and gethui()) or game:GetService("CoreGui")
local Gui = Instance.new("ScreenGui")
Gui.Name = "ToxV1Gui"
Gui.ResetOnSpawn = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.DisplayOrder = 999999999
Gui.Parent = ParentContainer
getgenv().Gui = Gui

getgenv().SetToxGuiColor =
    function(colorName)
        local selected =
            GUIColorMap[
                tostring(
                    colorName
                )
            ]

        if not selected then
            return false
        end

        local previous =
            MAIN_COLOR

        MAIN_COLOR =
            selected

        Settings.GUIColorName =
            tostring(
                colorName
            )

        getgenv().MAIN_COLOR =
            MAIN_COLOR

        local function apply(
            root
        )
            if not root then
                return
            end

            local objects = {
                root
            }

            for _, item in ipairs(
                root:
                    GetDescendants()
            ) do
                table.insert(
                    objects,
                    item
                )
            end

            for _, item in ipairs(
                objects
            ) do
                if item:IsA(
                    "UIStroke"
                )
                and item.Color
                    == previous then
                    item.Color =
                        MAIN_COLOR
                elseif item:IsA(
                    "GuiObject"
                )
                and item.BackgroundColor3
                    == previous then
                    item.BackgroundColor3 =
                        MAIN_COLOR
                end

                if item:IsA(
                    "ScrollingFrame"
                )
                and item.ScrollBarImageColor3
                    == previous then
                    item.ScrollBarImageColor3 =
                        MAIN_COLOR
                end
            end
        end

        apply(Gui)
        apply(NotifGui)

        return true
    end

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 0, 0, 0)
Main.Position = UDim2.new(0.5, 0, 0.5, 0)
Main.BackgroundColor3 = Color3.fromRGB(10, 10, 16)
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Visible = false
Main.Parent = Gui
getgenv().Main = Main

local MainCorner = Instance.new("UICorner") MainCorner.CornerRadius = UDim.new(0, 8) MainCorner.Parent = Main
local MainStroke = Instance.new("UIStroke") MainStroke.Color = MAIN_COLOR MainStroke.Thickness = 2 MainStroke.Parent = Main

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 38)
TopBar.BackgroundColor3 = MAIN_COLOR
TopBar.BorderSizePixel = 0
TopBar.Parent = Main

MakeDraggable(Main, TopBar)

local LogoImage = Instance.new("ImageLabel")
LogoImage.Size = UDim2.new(0, 18, 0, 18)
LogoImage.Position = UDim2.new(0, 10, 0.5, -9)
LogoImage.BackgroundTransparency = 1
LogoImage.Image = LOGO_ID
LogoImage.Parent = TopBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -70, 1, 0)
Title.Position = UDim2.new(0, 34, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "ToxHub v1"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 15
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

local Minimize = Instance.new("TextButton")
Minimize.Size = UDim2.new(0, 34, 0, 26)
Minimize.Position = UDim2.new(1, -40, 0, 6)
Minimize.BackgroundColor3 = Color3.fromRGB(18, 18, 30)
Minimize.BorderSizePixel = 0
Minimize.Text = "-"
Minimize.TextColor3 = Color3.fromRGB(255, 255, 255)
Minimize.TextSize = 18
Minimize.Font = Enum.Font.GothamBold
Minimize.Parent = TopBar
local MinimizeCorner = Instance.new("UICorner") MinimizeCorner.CornerRadius = UDim.new(0, 4) MinimizeCorner.Parent = Minimize
getgenv().Minimize = Minimize

local Tabs = Instance.new("ScrollingFrame")
Tabs.Size = UDim2.new(1, -10, 0, 34)
Tabs.Position = UDim2.new(0, 5, 0, 82)
Tabs.BackgroundTransparency = 1
Tabs.BorderSizePixel = 0
Tabs.ScrollBarThickness = 2
Tabs.ScrollBarImageColor3 = MAIN_COLOR
Tabs.ScrollingDirection = Enum.ScrollingDirection.X
Tabs.CanvasSize = UDim2.new(0, 0, 0, 0)
Tabs.Parent = Main
getgenv().Tabs = Tabs

local TabLayout = Instance.new("UIListLayout")
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
TabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
TabLayout.Padding = UDim.new(0, 4)
TabLayout.Parent = Tabs

TabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	Tabs.CanvasSize = UDim2.new(0, TabLayout.AbsoluteContentSize.X + 5, 0, 0)
end)

getgenv().UniversalTabs = Instance.new("ScrollingFrame")
getgenv().UniversalTabs.Name = "UniversalSubTabs"
getgenv().UniversalTabs.Size = UDim2.new(1, -10, 0, 32)
getgenv().UniversalTabs.Position = UDim2.new(0, 5, 0, 118)
getgenv().UniversalTabs.BackgroundTransparency = 1
getgenv().UniversalTabs.BorderSizePixel = 0
getgenv().UniversalTabs.ScrollBarThickness = 2
getgenv().UniversalTabs.ScrollBarImageColor3 = MAIN_COLOR
getgenv().UniversalTabs.ScrollingDirection = Enum.ScrollingDirection.X
getgenv().UniversalTabs.CanvasSize = UDim2.new(0, 0, 0, 0)
getgenv().UniversalTabs.Visible = true
getgenv().UniversalTabs.Parent = Main

getgenv().UniversalTabLayout = Instance.new("UIListLayout")
getgenv().UniversalTabLayout.FillDirection = Enum.FillDirection.Horizontal
getgenv().UniversalTabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
getgenv().UniversalTabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
getgenv().UniversalTabLayout.Padding = UDim.new(0, 4)
getgenv().UniversalTabLayout.Parent = getgenv().UniversalTabs

getgenv().UniversalTabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    local tabs = getgenv().UniversalTabs
    local layout = getgenv().UniversalTabLayout
    if tabs and tabs.Parent and layout and layout.Parent then
        tabs.CanvasSize = UDim2.new(0, layout.AbsoluteContentSize.X + 5, 0, 0)
    end
end)

local Pages = {}
getgenv().Pages = Pages

getgenv().CreatePage = function(Name, RawPage)
	local Page = Instance.new("ScrollingFrame")
	Page.Name = Name
	Page.Size = UDim2.new(1, -16, 1, -126)
	Page.Position = UDim2.new(0, 8, 0, 122)
	Page.BackgroundTransparency = 1
	Page.BorderSizePixel = 0
	Page.ScrollBarThickness = RawPage and 0 or 4
	Page.ScrollBarImageColor3 = MAIN_COLOR
	Page.CanvasSize = UDim2.new(0, 0, 0, 0)
	Page.ScrollingEnabled = not RawPage
	Page.Visible = false
	Page.ClipsDescendants = true
	Page.Parent = Main

	local Layout = nil

	if not RawPage then
		Layout = Instance.new("UIListLayout")
		Layout.Padding = UDim.new(0, 6)
		Layout.SortOrder = Enum.SortOrder.LayoutOrder
		Layout.Parent = Page

		local Padding = Instance.new("UIPadding")
		Padding.PaddingTop = UDim.new(0, 3)
		Padding.PaddingBottom = UDim.new(0, 8)
		Padding.Parent = Page

		Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			Page.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y + 15)
		end)
	end

	Pages[Name] = Page
	return Page, Layout
end

local DetectedGameModule = getgenv().CurrentGameModule
local GamePage = nil

if DetectedGameModule and DetectedGameModule.Ready then
    GamePage = CreatePage(DetectedGameModule.ShortName)
end

local CombatPage = CreatePage("UNIVERSAL_COMBAT")
local PlayerPage = CreatePage("UNIVERSAL_PLAYER")
local VisualsPage = CreatePage("UNIVERSAL_ESP")
getgenv().LightingPage = CreatePage("UNIVERSAL_LIGHTING")
local FlingPage = CreatePage("UNIVERSAL_MISC")
local UniversalPage = CombatPage
local ScriptsPage = CreatePage("SCRIPTS")
local JoinPage = CreatePage("JOIN")
local ChatPage = CreatePage("CHAT", true)
local ControlPage = CreatePage("CONTROL", true)
local ConfigPage = CreatePage("CONFIG")

getgenv().UniversalSubPages = {
    [CombatPage] = "COMBAT",
    [PlayerPage] = "PLAYER",
    [VisualsPage] = "ESP",
    [getgenv().LightingPage] = "LIGHTING",
    [FlingPage] = "MISC"
}

for page in pairs(getgenv().UniversalSubPages) do
    page.Position = UDim2.new(0, 8, 0, 154)
    page.Size = UDim2.new(1, -16, 1, -158)
end

getgenv().GamePage = GamePage
getgenv().UniversalPage = UniversalPage
getgenv().CombatPage = CombatPage
getgenv().PlayerPage = PlayerPage
getgenv().VisualsPage = VisualsPage
getgenv().FlingPage = FlingPage
getgenv().ScriptsPage = ScriptsPage
getgenv().JoinPage = JoinPage
getgenv().ChatPage = ChatPage
getgenv().ControlPage = ControlPage
getgenv().ConfigPage = ConfigPage

getgenv().CurrentPage = UniversalPage

getgenv().CreateTab = function(Name, Page)
	local Button = Instance.new("TextButton")
	Button.Size = UDim2.new(0, 75, 0, 28)
	Button.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
	Button.BorderSizePixel = 0
	Button.Text = Name
	Button.TextColor3 = Color3.fromRGB(170, 170, 185)
	Button.TextSize = 11
	Button.Font = Enum.Font.GothamBold
	Button.AutoButtonColor = false
	Button.Parent = Tabs

    getgenv().ToxPageButtonsByPage = getgenv().ToxPageButtonsByPage or {}
    getgenv().ToxPageNamesByPage = getgenv().ToxPageNamesByPage or {}
    getgenv().ToxPageButtonsByPage[Page] = Button
    getgenv().ToxPageNamesByPage[Page] = Name

	local Corner = Instance.new("UICorner") Corner.CornerRadius = UDim.new(0, 4) Corner.Parent = Button

	Button.MouseButton1Click:Connect(function()
		if Destroyed then return end

        local targetPage = Page

        if Page == UniversalPage
        and getgenv().LastUniversalSubPage
        and getgenv().UniversalSubPages[getgenv().LastUniversalSubPage] then
            targetPage = getgenv().LastUniversalSubPage
        end

        if getgenv().ToxOpenPage then
            getgenv().ToxOpenPage(targetPage)
            return
        end

		for _, OtherPage in pairs(Pages) do OtherPage.Visible = false end
		targetPage.Visible = true
		getgenv().CurrentPage = targetPage

		for _, Object in ipairs(Tabs:GetChildren()) do
			if Object:IsA("TextButton") then
				Object.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
				Object.TextColor3 = Color3.fromRGB(170, 170, 185)
			end
		end

		Button.BackgroundColor3 = MAIN_COLOR
		Button.TextColor3 = Color3.fromRGB(255, 255, 255)
	end)

	return Button
end

local GameTab = nil

if GamePage and DetectedGameModule then
    GameTab = CreateTab(DetectedGameModule.ShortName, GamePage)
end

local UniversalTab = CreateTab("UNIVERSAL", UniversalPage)
local ScriptsTab = CreateTab("SCRIPTS", ScriptsPage)
local JoinTab = CreateTab("JOIN", JoinPage)
local ChatTab = CreateTab("CHAT", ChatPage)
local ControlTab = CreateTab("CONTROL", ControlPage)
local ConfigTab = CreateTab("CONFIG", ConfigPage)

getgenv().UniversalSubButtonsByPage = {}

getgenv().CreateUniversalSubTabInternal = function(name, page)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, name == "LIGHTING" and 82 or 75, 0, 27)
    button.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
    button.BorderSizePixel = 0
    button.Text = name
    button.TextColor3 = Color3.fromRGB(170, 170, 185)
    button.TextSize = 10
    button.Font = Enum.Font.GothamBold
    button.AutoButtonColor = false
    button.Parent = getgenv().UniversalTabs

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = button

    getgenv().UniversalSubButtonsByPage[page] = button

    button.MouseButton1Click:Connect(function()
        if Destroyed then
            return
        end

        if getgenv().ToxOpenPage then
            getgenv().ToxOpenPage(page)
        end
    end)

    return button
end

getgenv().CombatTab = getgenv().CreateUniversalSubTabInternal("COMBAT", CombatPage)
getgenv().PlayerTab = getgenv().CreateUniversalSubTabInternal("PLAYER", PlayerPage)
getgenv().VisualsTab = getgenv().CreateUniversalSubTabInternal("ESP", VisualsPage)
getgenv().LightingTab = getgenv().CreateUniversalSubTabInternal("LIGHTING", getgenv().LightingPage)
getgenv().FlingTab = getgenv().CreateUniversalSubTabInternal("MISC", FlingPage)
getgenv().CreateUniversalSubTabInternal = nil

getgenv().GameTab = GameTab
getgenv().UniversalTab = UniversalTab
getgenv().ChatTab = ChatTab
getgenv().ControlTab = ControlTab

UniversalPage.Visible = true
getgenv().UniversalTabs.Visible = true
UniversalTab.BackgroundColor3 = MAIN_COLOR
UniversalTab.TextColor3 = Color3.fromRGB(255, 255, 255)
getgenv().CombatTab.BackgroundColor3 = MAIN_COLOR
getgenv().CombatTab.TextColor3 = Color3.fromRGB(255, 255, 255)


getgenv().ToxPageButtonsByPage = getgenv().ToxPageButtonsByPage or {}
getgenv().ToxPageNamesByPage = getgenv().ToxPageNamesByPage or {}
getgenv().ToxPageNamesByPage[CombatPage] = "UNIVERSAL / COMBAT"
getgenv().ToxPageNamesByPage[PlayerPage] = "UNIVERSAL / PLAYER"
getgenv().ToxPageNamesByPage[VisualsPage] = "UNIVERSAL / ESP"
getgenv().ToxPageNamesByPage[getgenv().LightingPage] = "UNIVERSAL / LIGHTING"
getgenv().ToxPageNamesByPage[FlingPage] = "UNIVERSAL / MISC"
getgenv().ToxSearchControls = {}

local ToxSearchAliasMap = {
    tp = {"teleport", "ctrl click", "no tp", "spawn", "map", "island", "waypoint"},
    teleport = {"teleport", "ctrl click", "no tp", "spawn", "map", "island", "waypoint"},
    fps = {"fps booster", "performance", "restore", "texture"},
    perf = {"fps booster", "performance", "restore", "texture"},
    gun = {"gun esp", "grab gun", "shoot murderer"},
    arma = {"gun esp", "grab gun", "shoot murderer"},
    target = {"target", "murderer", "sheriff", "kill", "fling"},
    alvo = {"target", "murderer", "sheriff", "kill", "fling"},
    esp = {"esp", "chams", "tracers", "names", "distance"},
    trace = {"tracers", "tracer", "traces"},
    traces = {"tracers", "tracer", "traces"},
    tracer = {"tracers", "tracer", "traces"},
    name = {"names", "name type", "display"},
    names = {"names", "name type", "display"},
    nome = {"names", "name type", "display"},
    fly = {"fly", "air walk", "car fly", "water fly"},
    noclip = {"noclip", "clip"},
    config = {"config", "keybind", "gui", "search", "changelog", "server info"},
    server = {"server info", "players", "ping", "fps", "jobid", "placeid"},
    timer = {"round timer", "timer", "round"},
    history = {"target history", "target", "select", "kill"}
}
local function GetToxPageName(page)
    if not page then
        return ""
    end

    return getgenv().ToxPageNamesByPage[page]
        or tostring(page.Name or "")
end

getgenv().ToxOpenPage = function(page)
    if not page then
        return
    end

    for _, otherPage in pairs(Pages) do
        otherPage.Visible = false
    end

    page.Visible = true
    getgenv().CurrentPage = page

    local isUniversalSubPage = getgenv().UniversalSubPages and getgenv().UniversalSubPages[page] ~= nil
    getgenv().UniversalTabs.Visible = isUniversalSubPage

    for _, object in ipairs(Tabs:GetChildren()) do
        if object:IsA("TextButton") then
            object.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
            object.TextColor3 = Color3.fromRGB(170, 170, 185)
        end
    end

    for _, object in ipairs(getgenv().UniversalTabs:GetChildren()) do
        if object:IsA("TextButton") then
            object.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
            object.TextColor3 = Color3.fromRGB(170, 170, 185)
        end
    end

    local tabButton

    if isUniversalSubPage then
        getgenv().LastUniversalSubPage = page
        tabButton = UniversalTab

        local subButton = getgenv().UniversalSubButtonsByPage and getgenv().UniversalSubButtonsByPage[page]
        if subButton and subButton.Parent then
            subButton.BackgroundColor3 = MAIN_COLOR
            subButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
    else
        tabButton = getgenv().ToxPageButtonsByPage[page]
    end

    if tabButton and tabButton.Parent then
        tabButton.BackgroundColor3 = MAIN_COLOR
        tabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    end

    local toxChatGui = getgenv().ToxChatGui
    if toxChatGui and toxChatGui.Parent then
        toxChatGui.Visible = page == ChatPage
    end

    local toxControlGui = getgenv().ToxControlGui
    if toxControlGui and toxControlGui.Parent then
        toxControlGui.Visible = page == ControlPage
    end
end

getgenv().RegisterToxSearchControl = function(name, page, object, aliases)
    if typeof(name) ~= "string"
    or not page
    or not object then
        return
    end

    table.insert(
        getgenv().ToxSearchControls,
        {
            Name = name,
            Page = page,
            Object = object,
            Aliases = aliases or {}
        }
    )
end

local SearchInput = nil
local SearchScroll = nil
local SearchLayout = nil
local SearchIcon = nil

local function HighlightSearchResult(object)
    if not object
    or not object:IsA("GuiObject") then
        return
    end

    local oldColor = object.BackgroundColor3
    local oldTransparency = object.BackgroundTransparency

    object.BackgroundColor3 = MAIN_COLOR
    object.BackgroundTransparency = 0

    task.delay(0.65, function()
        if object and object.Parent then
            object.BackgroundColor3 = oldColor
            object.BackgroundTransparency = oldTransparency
        end
    end)
end

local function ControlMatchesSearch(item, query)
    local pageName = string.lower(GetToxPageName(item.Page))
    local haystack = string.lower(tostring(item.Name or "") .. " " .. pageName)

    for _, alias in ipairs(item.Aliases or {}) do
        haystack = haystack .. " " .. string.lower(tostring(alias))
    end

    if string.find(haystack, query, 1, true) then
        return true
    end

    local mapped = ToxSearchAliasMap[query]

    if mapped then
        for _, term in ipairs(mapped) do
            if string.find(haystack, term, 1, true) then
                return true
            end
        end
    end

    for alias, terms in pairs(ToxSearchAliasMap) do
        if string.find(alias, query, 1, true) then
            for _, term in ipairs(terms) do
                if string.find(haystack, term, 1, true) then
                    return true
                end
            end
        end
    end

    return false
end

local function RebuildSearchResults()
    if not SearchScroll then
        return
    end

    for _, child in ipairs(SearchScroll:GetChildren()) do
        if child:IsA("GuiObject") then
            child:Destroy()
        end
    end

    local query = string.lower(
        tostring(SearchInput and SearchInput.Text or "")
            :gsub("^%s+", "")
            :gsub("%s+$", "")
    )

    if query == "" then
        SearchScroll.Visible = false
        return
    end

    SearchScroll.Visible = true
    local shown = 0

    for _, item in ipairs(getgenv().ToxSearchControls or {}) do
        if item.Object
        and item.Object.Parent
        and ControlMatchesSearch(item, query) then
            shown = shown + 1

            if shown > 20 then
                break
            end

            local result = Instance.new("TextButton")
            result.Size = UDim2.new(1, -4, 0, 30)
            result.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
            result.BorderSizePixel = 0
            result.Text = GetToxPageName(item.Page) .. " • " .. item.Name
            result.TextColor3 = Color3.fromRGB(245, 245, 245)
            result.TextSize = 10
            result.Font = Enum.Font.GothamMedium
            result.TextXAlignment = Enum.TextXAlignment.Left
            result.ZIndex = 41
            result.Parent = SearchScroll

            local resultPadding = Instance.new("UIPadding")
            resultPadding.PaddingLeft = UDim.new(0, 7)
            resultPadding.Parent = result

            local resultCorner = Instance.new("UICorner")
            resultCorner.CornerRadius = UDim.new(0, 4)
            resultCorner.Parent = result

            result.MouseButton1Click:Connect(function()
                SearchScroll.Visible = false
                getgenv().ToxOpenPage(item.Page)

                task.defer(function()
                    if item.Page
                    and item.Object
                    and item.Object.Parent then
                        local offset =
                            item.Object.AbsolutePosition.Y
                            - item.Page.AbsolutePosition.Y
                            + item.Page.CanvasPosition.Y
                            - 12

                        item.Page.CanvasPosition = Vector2.new(
                            0,
                            math.max(0, offset)
                        )

                        HighlightSearchResult(item.Object)
                    end
                end)
            end)
        end
    end

    if shown == 0 then
        local empty = Instance.new("TextLabel")
        empty.Size = UDim2.new(1, -4, 0, 30)
        empty.BackgroundTransparency = 1
        empty.Text = "No options found"
        empty.TextColor3 = Color3.fromRGB(170, 170, 185)
        empty.TextSize = 10
        empty.Font = Enum.Font.Gotham
        empty.ZIndex = 41
        empty.Parent = SearchScroll
    end
end

local function CreateToxInlineSearch()
    if SearchInput and SearchInput.Parent then
        return
    end

    Tabs.Size = UDim2.new(1, -10, 0, 34)

    SearchInput = Instance.new("TextBox")
    SearchInput.Name = "ToxInlineSearch"
    SearchInput.Size = UDim2.new(1, -50, 0, 28)
    SearchInput.Position = UDim2.new(0, 42, 0, 46)
    SearchInput.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
    SearchInput.BorderSizePixel = 0
    SearchInput.Text = ""
    SearchInput.PlaceholderText = "Search"
    SearchInput.TextColor3 = Color3.fromRGB(245, 245, 245)
    SearchInput.PlaceholderColor3 = Color3.fromRGB(170, 170, 185)
    SearchInput.Font = Enum.Font.GothamMedium
    SearchInput.TextSize = 12
    SearchInput.ClearTextOnFocus = false
    SearchInput.ZIndex = 41
    SearchInput.Parent = Main

    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 4)
    inputCorner.Parent = SearchInput

    local inputPadding = Instance.new("UIPadding")
    inputPadding.PaddingLeft = UDim.new(0, 8)
    inputPadding.PaddingRight = UDim.new(0, 5)
    inputPadding.Parent = SearchInput

    SearchIcon = Instance.new("TextButton")
    SearchIcon.Name = "ToxInlineSearchIcon"
    SearchIcon.Size = UDim2.new(0, 28, 0, 28)
    SearchIcon.Position = UDim2.new(0, 8, 0, 46)
    SearchIcon.BackgroundColor3 = MAIN_COLOR
    SearchIcon.BorderSizePixel = 0
    SearchIcon.Text = "🔎"
    SearchIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
    SearchIcon.Font = Enum.Font.GothamBold
    SearchIcon.TextSize = 13
    SearchIcon.ZIndex = 41
    SearchIcon.Parent = Main

    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(0, 4)
    iconCorner.Parent = SearchIcon

    SearchScroll = Instance.new("ScrollingFrame")
    SearchScroll.Name = "ToxInlineSearchResults"
    SearchScroll.Size = UDim2.new(1, -16, 0, 170)
    SearchScroll.Position = UDim2.new(0, 8, 0, 78)
    SearchScroll.BackgroundColor3 = Color3.fromRGB(10, 10, 16)
    SearchScroll.BackgroundTransparency = 0.03
    SearchScroll.BorderSizePixel = 0
    SearchScroll.ScrollBarThickness = 3
    SearchScroll.ScrollBarImageColor3 = MAIN_COLOR
    SearchScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    SearchScroll.Visible = false
    SearchScroll.ZIndex = 40
    SearchScroll.ClipsDescendants = true
    SearchScroll.Parent = Main

    local scrollCorner = Instance.new("UICorner")
    scrollCorner.CornerRadius = UDim.new(0, 5)
    scrollCorner.Parent = SearchScroll

    local scrollStroke = Instance.new("UIStroke")
    scrollStroke.Color = MAIN_COLOR
    scrollStroke.Thickness = 1
    scrollStroke.Transparency = 0.25
    scrollStroke.Parent = SearchScroll

    SearchLayout = Instance.new("UIListLayout")
    SearchLayout.SortOrder = Enum.SortOrder.LayoutOrder
    SearchLayout.Padding = UDim.new(0, 5)
    SearchLayout.Parent = SearchScroll

    local scrollPadding = Instance.new("UIPadding")
    scrollPadding.PaddingTop = UDim.new(0, 5)
    scrollPadding.PaddingLeft = UDim.new(0, 4)
    scrollPadding.PaddingRight = UDim.new(0, 4)
    scrollPadding.Parent = SearchScroll

    SearchLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        SearchScroll.CanvasSize = UDim2.new(0, 0, 0, SearchLayout.AbsoluteContentSize.Y + 10)
    end)

    SearchInput:GetPropertyChangedSignal("Text"):Connect(RebuildSearchResults)

    SearchInput.FocusLost:Connect(function()
        task.delay(0.15, function()
            if SearchInput and SearchInput.Text == "" and SearchScroll then
                SearchScroll.Visible = false
            end
        end)
    end)

    SearchIcon.MouseButton1Click:Connect(function()
        SearchInput:CaptureFocus()
        RebuildSearchResults()
    end)
end

getgenv().OpenToxSearch = function()
    CreateToxInlineSearch()

    if SearchInput then
        SearchInput:CaptureFocus()
        RebuildSearchResults()
    end
end

CreateToxInlineSearch()

local function NormalizeToxChanges(changes)
    local categories = {
        ADDED = {},
        FIXED = {},
        CHANGED = {},
        REMOVED = {}
    }

    if typeof(changes) ~= "table" then
        return categories
    end

    local keyMap = {
        Added = "ADDED",
        ADDED = "ADDED",
        added = "ADDED",
        Fixed = "FIXED",
        FIXED = "FIXED",
        fixed = "FIXED",
        Changed = "CHANGED",
        CHANGED = "CHANGED",
        changed = "CHANGED",
        Removed = "REMOVED",
        REMOVED = "REMOVED",
        removed = "REMOVED"
    }

    local hasNamed = false

    for key, value in pairs(changes) do
        local mapped = keyMap[key]

        if mapped then
            hasNamed = true

            if typeof(value) == "table" then
                for _, item in ipairs(value) do
                    table.insert(categories[mapped], tostring(item))
                end
            elseif value ~= nil then
                table.insert(categories[mapped], tostring(value))
            end
        end
    end

    if not hasNamed then
        for _, item in ipairs(changes) do
            table.insert(categories.CHANGED, tostring(item))
        end
    end

    return categories
end

local function AddToxChangeText(parent, text, layoutOrder, isHeader)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -4, 0, isHeader and 26 or 34)
    label.BackgroundColor3 = isHeader and MAIN_COLOR or Color3.fromRGB(18, 18, 28)
    label.BorderSizePixel = 0
    label.Text = tostring(text)
    label.TextColor3 = Color3.fromRGB(245, 245, 245)
    label.Font = isHeader and Enum.Font.GothamBold or Enum.Font.Gotham
    label.TextSize = isHeader and 12 or 11
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.LayoutOrder = layoutOrder
    label.Parent = parent

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 8)
    padding.PaddingRight = UDim.new(0, 8)
    padding.Parent = label

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = label

    return label
end

getgenv().ShowToxUpdateGui = function(version, changes)
    version = tostring(version or "")

    if version == ""
    or Settings.ToxLastChangelogVersion == version then
        return
    end

    if not getgenv().ScriptLoaded then
        local queuedVersion = version
        local queuedChanges = changes

        task.spawn(function()
            local started = os.clock()

            repeat
                task.wait(0.05)
            until getgenv().Destroyed
            or getgenv().ScriptLoaded
            or os.clock() - started > 20

            if not getgenv().Destroyed
            and getgenv().ScriptLoaded
            and getgenv().ShowToxUpdateGui then
                getgenv().ShowToxUpdateGui(
                    queuedVersion,
                    queuedChanges
                )
            end
        end)

        return
    end

    local old = Gui:FindFirstChild("ToxUpdatedFrame")

    if old then
        old:Destroy()
    end

    local frame = Instance.new("Frame")
    frame.Name = "ToxUpdatedFrame"
    frame.Size = UDim2.new(0, 410, 0, 350)
    frame.Position = UDim2.new(0.5, -205, 0.5, -175)
    frame.BackgroundColor3 = Color3.fromRGB(10, 10, 16)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.ClipsDescendants = true
    frame.Parent = Gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = MAIN_COLOR
    stroke.Thickness = 2
    stroke.Parent = frame

    local topBar = Instance.new("Frame")
    topBar.Size = UDim2.new(1, 0, 0, 38)
    topBar.BackgroundColor3 = MAIN_COLOR
    topBar.BorderSizePixel = 0
    topBar.Parent = frame

    if MakeDraggable then
        MakeDraggable(frame, topBar)
    end

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "UPDATED"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = topBar

    local versionLabel = Instance.new("TextLabel")
    versionLabel.Size = UDim2.new(1, -20, 0, 24)
    versionLabel.Position = UDim2.new(0, 10, 0, 46)
    versionLabel.BackgroundTransparency = 1
    versionLabel.Text = "Version: " .. version
    versionLabel.TextColor3 = Color3.fromRGB(180, 180, 205)
    versionLabel.Font = Enum.Font.GothamMedium
    versionLabel.TextSize = 11
    versionLabel.TextXAlignment = Enum.TextXAlignment.Left
    versionLabel.Parent = frame

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -20, 1, -116)
    scroll.Position = UDim2.new(0, 10, 0, 74)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 3
    scroll.ScrollBarImageColor3 = MAIN_COLOR
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.Parent = frame

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 5)
    layout.Parent = scroll

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8)
    end)

    local categories = NormalizeToxChanges(changes)
    local order = 0
    local names = {"ADDED", "FIXED", "CHANGED", "REMOVED"}

    for _, category in ipairs(names) do
        local list = categories[category]

        if typeof(list) == "table"
        and #list > 0 then
            order += 1
            AddToxChangeText(scroll, category, order, true)

            for _, text in ipairs(list) do
                order += 1
                AddToxChangeText(scroll, "• " .. tostring(text), order, false)
            end
        end
    end

    if order == 0 then
        AddToxChangeText(scroll, "CHANGED", 1, true)
        AddToxChangeText(scroll, "• Update completed", 2, false)
    end

    local ok = Instance.new("TextButton")
    ok.Size = UDim2.new(1, -20, 0, 32)
    ok.Position = UDim2.new(0, 10, 1, -40)
    ok.BackgroundColor3 = MAIN_COLOR
    ok.BorderSizePixel = 0
    ok.Text = "OK"
    ok.TextColor3 = Color3.fromRGB(255, 255, 255)
    ok.Font = Enum.Font.GothamBold
    ok.TextSize = 12
    ok.Parent = frame

    local okCorner = Instance.new("UICorner")
    okCorner.CornerRadius = UDim.new(0, 5)
    okCorner.Parent = ok

    ok.MouseButton1Click:Connect(function()
        Settings.ToxLastChangelogVersion = version

        if getgenv().AutoSaveConfiguration then
            getgenv().AutoSaveConfiguration()
        end

        frame:Destroy()
    end)
end

getgenv().ShowToxUpdateGui = function() end

getgenv().ShowToxUpdateGui("2026-09-14-universal-reorg-4", {
    Added = {
        "Build A Boat For Treasure (BABFT)",
        "Prison Life (PL)",
        "Flee the Facility (FTF)"
    },
    Fixed = {
        "BABFT Autofarm no longer drops the player into the water between stages",
        "BABFT final chest now stops after 3 teleport attempts with 1 second between each",
        "Game settings remain separated and saved by Place ID",
        "All saved options now stay disabled until the loading screen fully finishes"
    },
    Changed = {
        "Combat, Player, Visuals and Misc are now organized inside the UNIVERSAL tab",
        "UNIVERSAL categories now use collapsible sections",
        "Updated game module registry and game-specific settings support"
    }
})

-- Chat Logs, Waypoints and Music are initialized by Module2.lua

ToxChatGui = Instance.new("Frame")
ToxChatGui.Name = "ToxChatFrame"
ToxChatGui.Size = UDim2.new(1, 0, 1, 0)
ToxChatGui.Position = UDim2.new(0, 0, 0, 0)
ToxChatGui.BackgroundColor3 = Color3.fromRGB(12, 12, 20)
ToxChatGui.BorderSizePixel = 0
ToxChatGui.ClipsDescendants = true
ToxChatGui.Visible = true
ToxChatGui.Parent = ChatPage
getgenv().ToxChatGui = ToxChatGui

ToxChatCorner = Instance.new("UICorner")
ToxChatCorner.CornerRadius = UDim.new(0, 8)
ToxChatCorner.Parent = ToxChatGui

ToxChatStroke = Instance.new("UIStroke")
ToxChatStroke.Color = MAIN_COLOR
ToxChatStroke.Thickness = 2
ToxChatStroke.Parent = ToxChatGui

ToxChatTopBar = Instance.new("Frame")
ToxChatTopBar.Size = UDim2.new(1, 0, 0, 32)
ToxChatTopBar.BackgroundColor3 = Color3.fromRGB(16, 16, 26)
ToxChatTopBar.BorderSizePixel = 0
ToxChatTopBar.Parent = ToxChatGui
getgenv().ToxChatTopBar = ToxChatTopBar

-- Embedded in the main CHAT page; no detached dragging.

ToxChatTitle = Instance.new("TextLabel")
ToxChatTitle.Size = UDim2.new(1, -70, 1, 0)
ToxChatTitle.Position = UDim2.new(0, 10, 0, 0)
ToxChatTitle.BackgroundTransparency = 1
ToxChatTitle.Text = "CHAT"
ToxChatTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
ToxChatTitle.Font = Enum.Font.GothamBold
ToxChatTitle.TextSize = 13
ToxChatTitle.TextXAlignment = Enum.TextXAlignment.Left
ToxChatTitle.Parent = ToxChatTopBar

ToxChatCloseBtn = Instance.new("TextButton")
ToxChatCloseBtn.Size = UDim2.new(0, 22, 0, 20)
ToxChatCloseBtn.Position = UDim2.new(1, -26, 0.5, -10)
ToxChatCloseBtn.BackgroundColor3 = Color3.fromRGB(24, 24, 34)
ToxChatCloseBtn.BorderSizePixel = 0
ToxChatCloseBtn.Text = "X"
ToxChatCloseBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
ToxChatCloseBtn.Font = Enum.Font.GothamBold
ToxChatCloseBtn.TextSize = 11
ToxChatCloseBtn.Parent = ToxChatTopBar
ToxChatCloseBtn.Visible = false

ToxChatCloseCorner = Instance.new("UICorner")
ToxChatCloseCorner.CornerRadius = UDim.new(0, 4)
ToxChatCloseCorner.Parent = ToxChatCloseBtn

ToxChatStatus = Instance.new("TextLabel")
ToxChatStatus.Size = UDim2.new(1, -16, 0, 18)
ToxChatStatus.Position = UDim2.new(0, 8, 0, 38)
ToxChatStatus.BackgroundTransparency = 1
ToxChatStatus.Text = "Global chat • all games"
ToxChatStatus.TextColor3 = Color3.fromRGB(145, 145, 170)
ToxChatStatus.Font = Enum.Font.Gotham
ToxChatStatus.TextSize = 10
ToxChatStatus.TextXAlignment = Enum.TextXAlignment.Left
ToxChatStatus.Parent = ToxChatGui
getgenv().ToxChatStatus = ToxChatStatus

ToxChatScroll = Instance.new("ScrollingFrame")
ToxChatScroll.Size = UDim2.new(1, -8, 1, -102)
ToxChatScroll.Position = UDim2.new(0, 4, 0, 58)
ToxChatScroll.BackgroundTransparency = 1
ToxChatScroll.BorderSizePixel = 0
ToxChatScroll.ScrollBarThickness = 4
ToxChatScroll.ScrollBarImageColor3 = MAIN_COLOR
ToxChatScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
ToxChatScroll.Parent = ToxChatGui
getgenv().ToxChatScroll = ToxChatScroll

ToxChatLayout = Instance.new("UIListLayout")
ToxChatLayout.Padding = UDim.new(0, 5)
ToxChatLayout.SortOrder = Enum.SortOrder.LayoutOrder
ToxChatLayout.Parent = ToxChatScroll

ToxChatLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ToxChatScroll.CanvasSize = UDim2.new(0, 0, 0, ToxChatLayout.AbsoluteContentSize.Y + 8)
    ToxChatScroll.CanvasPosition = Vector2.new(0, math.max(0, ToxChatLayout.AbsoluteContentSize.Y))
end)

ToxChatInput = Instance.new("TextBox")
ToxChatInput.Size = UDim2.new(1, -78, 0, 30)
ToxChatInput.Position = UDim2.new(0, 4, 1, -34)
ToxChatInput.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
ToxChatInput.BorderSizePixel = 0
ToxChatInput.PlaceholderText = "Message..."
ToxChatInput.PlaceholderColor3 = Color3.fromRGB(130, 130, 150)
ToxChatInput.Text = ""
ToxChatInput.TextColor3 = Color3.fromRGB(255, 255, 255)
ToxChatInput.Font = Enum.Font.Gotham
ToxChatInput.TextSize = 12
ToxChatInput.ClearTextOnFocus = false
ToxChatInput.Parent = ToxChatGui
getgenv().ToxChatInput = ToxChatInput

ToxChatInputCorner = Instance.new("UICorner")
ToxChatInputCorner.CornerRadius = UDim.new(0, 4)
ToxChatInputCorner.Parent = ToxChatInput

ToxChatSendBtn = Instance.new("TextButton")
ToxChatSendBtn.Size = UDim2.new(0, 66, 0, 30)
ToxChatSendBtn.Position = UDim2.new(1, -70, 1, -34)
ToxChatSendBtn.BackgroundColor3 = MAIN_COLOR
ToxChatSendBtn.BorderSizePixel = 0
ToxChatSendBtn.Text = "Send"
ToxChatSendBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToxChatSendBtn.Font = Enum.Font.GothamBold
ToxChatSendBtn.TextSize = 12
ToxChatSendBtn.Parent = ToxChatGui
getgenv().ToxChatSendBtn = ToxChatSendBtn

ToxChatSendCorner = Instance.new("UICorner")
ToxChatSendCorner.CornerRadius = UDim.new(0, 4)
ToxChatSendCorner.Parent = ToxChatSendBtn

getgenv().AddToxChatMessage = function(displayName, message, blocked, showPopup)
    if not ToxChatScroll or not ToxChatScroll.Parent then
        return
    end

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -6, 0, 0)
    label.AutomaticSize = Enum.AutomaticSize.Y
    label.BackgroundColor3 = Color3.fromRGB(16, 16, 24)
    label.BackgroundTransparency = 0.15
    label.BorderSizePixel = 0
    label.Text = tostring(displayName) .. ": " .. tostring(message)
    label.TextColor3 = blocked and Color3.fromRGB(255, 120, 120) or Color3.fromRGB(235, 235, 245)
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Top
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.Parent = ToxChatScroll

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = label

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 8)
    padding.PaddingRight = UDim.new(0, 8)
    padding.PaddingTop = UDim.new(0, 6)
    padding.PaddingBottom = UDim.new(0, 6)
    padding.Parent = label

    local messageLabels = {}

    for _, child in ipairs(ToxChatScroll:GetChildren()) do
        if child:IsA("TextLabel") then
            table.insert(messageLabels, child)
        end
    end

    while #messageLabels > 100 do
        local oldest = table.remove(messageLabels, 1)

        if oldest and oldest.Parent then
            oldest:Destroy()
        end
    end

    if showPopup ~= false
    and getgenv().ShowToxChatPopup then
        getgenv().ShowToxChatPopup(
            displayName,
            message,
            blocked
        )
    end
end

getgenv().ClearToxChatMessages = function()
    for _, child in ipairs(ToxChatScroll:GetChildren()) do
        if child:IsA("TextLabel") then
            child:Destroy()
        end
    end
end

ToxChatCloseBtn.MouseButton1Click:Connect(function()
    if getgenv().ToxOpenPage and getgenv().UniversalPage then
        getgenv().ToxOpenPage(getgenv().UniversalPage)
    end
end)

JoinGamesGui = Instance.new("Frame")
JoinGamesGui.Name = "ToxQuickJoinFrame"
JoinGamesGui.Size = UDim2.new(0, 460, 0, 310)
JoinGamesGui.Position = UDim2.new(0.5, -230, 0.5, -155)
JoinGamesGui.BackgroundColor3 = Color3.fromRGB(10, 10, 16)
JoinGamesGui.BorderSizePixel = 0
JoinGamesGui.ClipsDescendants = true
JoinGamesGui.Visible = false
JoinGamesGui.Parent = Gui
getgenv().JoinGamesGui = JoinGamesGui

JoinGamesCorner = Instance.new("UICorner")
JoinGamesCorner.CornerRadius = UDim.new(0, 8)
JoinGamesCorner.Parent = JoinGamesGui

JoinGamesStroke = Instance.new("UIStroke")
JoinGamesStroke.Color = MAIN_COLOR
JoinGamesStroke.Thickness = 2
JoinGamesStroke.Parent = JoinGamesGui

JoinGamesTopBar = Instance.new("Frame")
JoinGamesTopBar.Size = UDim2.new(1, 0, 0, 32)
JoinGamesTopBar.BackgroundColor3 = MAIN_COLOR
JoinGamesTopBar.BorderSizePixel = 0
JoinGamesTopBar.Parent = JoinGamesGui

MakeDraggable(JoinGamesGui, JoinGamesTopBar)

JoinGamesTitle = Instance.new("TextLabel")
JoinGamesTitle.Size = UDim2.new(1, -70, 1, 0)
JoinGamesTitle.Position = UDim2.new(0, 10, 0, 0)
JoinGamesTitle.BackgroundTransparency = 1
JoinGamesTitle.Text = "Quick Games"
JoinGamesTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
JoinGamesTitle.Font = Enum.Font.GothamBold
JoinGamesTitle.TextSize = 13
JoinGamesTitle.TextXAlignment = Enum.TextXAlignment.Left
JoinGamesTitle.Parent = JoinGamesTopBar

JoinGamesCloseBtn = Instance.new("TextButton")
JoinGamesCloseBtn.Size = UDim2.new(0, 22, 0, 20)
JoinGamesCloseBtn.Position = UDim2.new(1, -26, 0.5, -10)
JoinGamesCloseBtn.BackgroundColor3 = Color3.fromRGB(24, 24, 34)
JoinGamesCloseBtn.BorderSizePixel = 0
JoinGamesCloseBtn.Text = "X"
JoinGamesCloseBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
JoinGamesCloseBtn.Font = Enum.Font.GothamBold
JoinGamesCloseBtn.TextSize = 11
JoinGamesCloseBtn.Parent = JoinGamesTopBar

JoinGamesCloseCorner = Instance.new("UICorner")
JoinGamesCloseCorner.CornerRadius = UDim.new(0, 4)
JoinGamesCloseCorner.Parent = JoinGamesCloseBtn

JoinGameAddArea = Instance.new("Frame")
JoinGameAddArea.Size = UDim2.new(1, -16, 0, 32)
JoinGameAddArea.Position = UDim2.new(0, 8, 0, 39)
JoinGameAddArea.BackgroundTransparency = 1
JoinGameAddArea.Parent = JoinGamesGui

JoinGameIdBox = Instance.new("TextBox")
JoinGameIdBox.Size = UDim2.new(1, -92, 1, 0)
JoinGameIdBox.Position = UDim2.new(0, 0, 0, 0)
JoinGameIdBox.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
JoinGameIdBox.BorderSizePixel = 0
JoinGameIdBox.PlaceholderText = "Place ID"
JoinGameIdBox.Text = ""
JoinGameIdBox.TextColor3 = Color3.fromRGB(245, 245, 245)
JoinGameIdBox.PlaceholderColor3 = Color3.fromRGB(130, 130, 150)
JoinGameIdBox.Font = Enum.Font.Gotham
JoinGameIdBox.TextSize = 12
JoinGameIdBox.ClearTextOnFocus = false
JoinGameIdBox.Parent = JoinGameAddArea
getgenv().JoinGameIdBox = JoinGameIdBox

JoinGameIdCorner = Instance.new("UICorner")
JoinGameIdCorner.CornerRadius = UDim.new(0, 4)
JoinGameIdCorner.Parent = JoinGameIdBox

JoinGameAddButton = Instance.new("TextButton")
JoinGameAddButton.Size = UDim2.new(0, 84, 1, 0)
JoinGameAddButton.Position = UDim2.new(1, -84, 0, 0)
JoinGameAddButton.BackgroundColor3 = MAIN_COLOR
JoinGameAddButton.BorderSizePixel = 0
JoinGameAddButton.Text = "Add Game"
JoinGameAddButton.TextColor3 = Color3.fromRGB(255, 255, 255)
JoinGameAddButton.Font = Enum.Font.GothamBold
JoinGameAddButton.TextSize = 11
JoinGameAddButton.Parent = JoinGameAddArea
getgenv().JoinGameAddButton = JoinGameAddButton

JoinGameAddCorner = Instance.new("UICorner")
JoinGameAddCorner.CornerRadius = UDim.new(0, 4)
JoinGameAddCorner.Parent = JoinGameAddButton

JoinGamesScroll = Instance.new("ScrollingFrame")
JoinGamesScroll.Size = UDim2.new(1, -16, 1, -84)
JoinGamesScroll.Position = UDim2.new(0, 8, 0, 78)
JoinGamesScroll.BackgroundTransparency = 1
JoinGamesScroll.BorderSizePixel = 0
JoinGamesScroll.ScrollBarThickness = 3
JoinGamesScroll.ScrollBarImageColor3 = MAIN_COLOR
JoinGamesScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
JoinGamesScroll.Parent = JoinGamesGui
getgenv().JoinGamesScroll = JoinGamesScroll

JoinGamesLayout = Instance.new("UIListLayout")
JoinGamesLayout.Padding = UDim.new(0, 6)
JoinGamesLayout.SortOrder = Enum.SortOrder.LayoutOrder
JoinGamesLayout.Parent = JoinGamesScroll

JoinGamesLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    JoinGamesScroll.CanvasSize = UDim2.new(0, 0, 0, JoinGamesLayout.AbsoluteContentSize.Y + 8)
end)

JoinGamesCloseBtn.MouseButton1Click:Connect(function()
    JoinGamesGui.Visible = false
end)

ApplySavedGuiPosition("Main", Main)
ApplySavedGuiPosition("QuickJoin", JoinGamesGui)

TrackGuiPosition("Main", Main)
TrackGuiPosition("QuickJoin", JoinGamesGui)

getgenv().SharedToggleControls = {}
getgenv().SharedValueControls = {}

getgenv().SyncToggleVisuals = function(Key, Value)
    if not Key then return end

    local controls = getgenv().SharedToggleControls[Key]
    if not controls then return end

    for index = #controls, 1, -1 do
        local controller = controls[index]
        local button = controller and controller.Button

        if not controller
        or not controller.SetVisual
        or not button
        or not button.Parent then
            table.remove(controls, index)
        else
            pcall(function()
                controller.SetVisual(Value)
            end)
        end
    end
end

function RegisterSharedToggle(Key, Controller)
    if not Key or not Controller then return end

    if not getgenv().SharedToggleControls[Key] then
        getgenv().SharedToggleControls[Key] = {}
    end

    table.insert(getgenv().SharedToggleControls[Key], Controller)
end

getgenv().RegisterSharedToggle = RegisterSharedToggle

local function RegisterStartupToggleCallback(Key, Callback)
    if getgenv().ToxOptionsReady ~= false
    or not Key
    or type(Callback) ~= "function" then
        return
    end

    local callbacks = getgenv().ToxStartupToggleCallbacks

    if typeof(callbacks) ~= "table" then
        callbacks = {}
        getgenv().ToxStartupToggleCallbacks = callbacks
    end

    if callbacks[Key] == nil then
        callbacks[Key] = Callback
    end
end

getgenv().RegisterStartupToggleCallback = RegisterStartupToggleCallback

getgenv().SyncValueVisuals = function(Key, Value)
    if not Key then return end

    local controls = getgenv().SharedValueControls[Key]

    if controls then
        for _, controller in ipairs(controls) do
            if controller and controller.SetValue then
                controller.SetValue(Value)
            end
        end
    end

    if getgenv().ToxOnSharedValueChanged then
        getgenv().ToxOnSharedValueChanged(Key, Value)
    end
end

function RegisterSharedValue(Key, Controller)
    if not Key or not Controller then return end

    if not getgenv().SharedValueControls[Key] then
        getgenv().SharedValueControls[Key] = {}
    end

    table.insert(getgenv().SharedValueControls[Key], Controller)
end

getgenv().CreateToggle = function(Name, Page, DefaultValue, Callback, SyncKey)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, -5, 0, 39)
    Button.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
    Button.BorderSizePixel = 0
    Button.Text = ""
    Button.AutoButtonColor = false
    Button.Parent = Page

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -65, 1, 0)
    Label.Position = UDim2.new(0, 12, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = Name
    Label.TextColor3 = Color3.fromRGB(240, 240, 240)
    Label.TextSize = 13
    Label.Font = Enum.Font.GothamMedium
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Button

    local Toggle = Instance.new("Frame")
    Toggle.Size = UDim2.new(0, 38, 0, 20)
    Toggle.Position = UDim2.new(1, -48, 0.5, -10)
    Toggle.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    Toggle.BorderSizePixel = 0
    Toggle.Parent = Button
    local ToggleCorner = Instance.new("UICorner") ToggleCorner.CornerRadius = UDim.new(0, 4) ToggleCorner.Parent = Toggle

    local Indicator = Instance.new("Frame")
    Indicator.Size = UDim2.new(0, 14, 0, 14)
    Indicator.Position = UDim2.new(0, 3, 0.5, -7)
    Indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Indicator.BorderSizePixel = 0
    Indicator.Parent = Toggle
    local IndicatorCorner = Instance.new("UICorner") IndicatorCorner.CornerRadius = UDim.new(0, 3) IndicatorCorner.Parent = Indicator

    local Enabled = getgenv().ToxOptionsReady == false
        and false
        or (DefaultValue == true)

    local function Update()
        if Enabled then
            Toggle.BackgroundColor3 = Color3.fromRGB(50, 180, 70)
            Indicator.Position = UDim2.new(1, -17, 0.5, -7)
        else
            Toggle.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
            Indicator.Position = UDim2.new(0, 3, 0.5, -7)
        end
    end

    local Controller = {
        Button = Button,
        SetVisual = function(Value)
            Enabled = Value == true
            Update()
        end
    }

    RegisterSharedToggle(SyncKey, Controller)
    RegisterStartupToggleCallback(SyncKey, Callback)

    Button.MouseButton1Click:Connect(function()
        if getgenv().Destroyed or getgenv().ToxOptionsReady == false then return end

        Enabled = not Enabled
        Update()
        Callback(Enabled)

        if SyncKey and getgenv().SyncToggleVisuals then
            getgenv().SyncToggleVisuals(SyncKey, Enabled)
        end

        if getgenv().ScriptLoaded then
            CustomNotify(Name .. (Enabled and " Enabled" or " Disabled"), Enabled and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100))
        end

        AutoSaveConfiguration()
    end)

    Update()

    if getgenv().RegisterToxSearchControl then
        getgenv().RegisterToxSearchControl(Name, Page, Button)
    end

    return Button
end

getgenv().CreateToggleWithValue = function(Name, Page, DefaultToggle, DefaultValue, CallbackToggle, CallbackValue, SyncKey)
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, -5, 0, 39)
    Container.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
    Container.BorderSizePixel = 0
    Container.Parent = Page

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -125, 1, 0)
    Label.Position = UDim2.new(0, 12, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = Name
    Label.TextColor3 = Color3.fromRGB(240, 240, 240)
    Label.TextSize = 13
    Label.Font = Enum.Font.GothamMedium
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Container

    local Input = Instance.new("TextBox")
    Input.Size = UDim2.new(0, 55, 0, 25)
    Input.Position = UDim2.new(1, -112, 0.5, -12)
    Input.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
    Input.BorderSizePixel = 0
    Input.Text = tostring(DefaultValue)
    Input.TextColor3 = Color3.fromRGB(255, 255, 255)
    Input.TextSize = 12
    Input.Font = Enum.Font.Gotham
    Input.ClearTextOnFocus = false
    Input.Parent = Container
    local InputCorner = Instance.new("UICorner") InputCorner.CornerRadius = UDim.new(0, 4) InputCorner.Parent = Input

    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Size = UDim2.new(0, 38, 0, 20)
    ToggleButton.Position = UDim2.new(1, -48, 0.5, -10)
    ToggleButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    ToggleButton.BorderSizePixel = 0
    ToggleButton.Text = ""
    ToggleButton.AutoButtonColor = false
    ToggleButton.Parent = Container
    local ToggleCorner = Instance.new("UICorner") ToggleCorner.CornerRadius = UDim.new(0, 4) ToggleCorner.Parent = ToggleButton

    local Indicator = Instance.new("Frame")
    Indicator.Size = UDim2.new(0, 14, 0, 14)
    Indicator.Position = UDim2.new(0, 3, 0.5, -7)
    Indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Indicator.BorderSizePixel = 0
    Indicator.Parent = ToggleButton
    local IndicatorCorner = Instance.new("UICorner") IndicatorCorner.CornerRadius = UDim.new(0, 3) IndicatorCorner.Parent = Indicator

    local Enabled = getgenv().ToxOptionsReady == false
        and false
        or (DefaultToggle == true)

    local function UpdateToggle()
        if Enabled then
            ToggleButton.BackgroundColor3 = Color3.fromRGB(50, 180, 70)
            Indicator.Position = UDim2.new(1, -17, 0.5, -7)
        else
            ToggleButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
            Indicator.Position = UDim2.new(0, 3, 0.5, -7)
        end
    end

    local Controller = {
        Button = Container,
        SetVisual = function(Value)
            Enabled = Value == true
            UpdateToggle()
        end,
        SetValue = function(Value)
            if tonumber(Value) then
                Input.Text = tostring(Value)
            end
        end
    }

    RegisterSharedToggle(SyncKey, Controller)
    RegisterSharedValue(SyncKey, Controller)
    RegisterStartupToggleCallback(SyncKey, CallbackToggle)

    ToggleButton.MouseButton1Click:Connect(function()
        if getgenv().Destroyed or getgenv().ToxOptionsReady == false then return end

        Enabled = not Enabled
        UpdateToggle()
        CallbackToggle(Enabled)

        if SyncKey and getgenv().SyncToggleVisuals then
            getgenv().SyncToggleVisuals(SyncKey, Enabled)
        end

        if getgenv().ScriptLoaded then
            CustomNotify(Name .. (Enabled and " Enabled" or " Disabled"), Enabled and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100))
        end

        AutoSaveConfiguration()
    end)

    Input.FocusLost:Connect(function()
        if getgenv().Destroyed or getgenv().ToxOptionsReady == false then return end

        local Number = tonumber(Input.Text)

        if Number then
            CallbackValue(Number)

            if SyncKey and getgenv().SyncValueVisuals then
                getgenv().SyncValueVisuals(SyncKey, Number)
            end

            AutoSaveConfiguration()
        else
            Input.Text = tostring(DefaultValue)
        end
    end)

    UpdateToggle()

    if getgenv().RegisterToxSearchControl then
        getgenv().RegisterToxSearchControl(Name, Page, Container)
    end

    return Container
end

getgenv().CreateInputWithButton = function(Name, Page, DefaultText, ButtonText, Callback)
	local Box = Instance.new("Frame")
	Box.Size = UDim2.new(1, -5, 0, 48)
	Box.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
	Box.BorderSizePixel = 0
	Box.Parent = Page

	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(1, -170, 1, 0)
	Label.Position = UDim2.new(0, 12, 0, 0)
	Label.BackgroundTransparency = 1
	Label.Text = Name
	Label.TextColor3 = Color3.fromRGB(240, 240, 240)
	Label.TextSize = 13
	Label.Font = Enum.Font.GothamMedium
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Parent = Box

	local Input = Instance.new("TextBox")
	Input.Size = UDim2.new(0, 85, 0, 27)
	Input.Position = UDim2.new(1, -155, 0.5, -13)
	Input.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
	Input.BorderSizePixel = 0
	Input.Text = DefaultText or ""
	Input.PlaceholderText = "Username"
	Input.TextColor3 = Color3.fromRGB(255, 255, 255)
	Input.TextSize = 12
	Input.Font = Enum.Font.Gotham
	Input.ClearTextOnFocus = false
	Input.Parent = Box
	local InputCorner = Instance.new("UICorner") InputCorner.CornerRadius = UDim.new(0, 4) InputCorner.Parent = Input

	local Button = Instance.new("TextButton")
	Button.Size = UDim2.new(0, 60, 0, 27)
	Button.Position = UDim2.new(1, -65, 0.5, -13)
	Button.BackgroundColor3 = MAIN_COLOR
	Button.BorderSizePixel = 0
	Button.Text = ButtonText or "Set"
	Button.TextColor3 = Color3.fromRGB(255, 255, 255)
	Button.TextSize = 12
	Button.Font = Enum.Font.GothamBold
	Button.Parent = Box
	local ButtonCorner = Instance.new("UICorner") ButtonCorner.CornerRadius = UDim.new(0, 4) ButtonCorner.Parent = Button

	Button.MouseButton1Click:Connect(function()
		if getgenv().Destroyed or getgenv().ToxOptionsReady == false then return end
		Callback(Input.Text)
	end)

    if getgenv().RegisterToxSearchControl then
        getgenv().RegisterToxSearchControl(Name, Page, Box)
    end

	return Box
end

getgenv().CreateInputWithTwoButtons = function(Name, Page, DefaultText, Btn1Text, Btn2Text, Callback)
	local Box = Instance.new("Frame")
	Box.Size = UDim2.new(1, -5, 0, 48)
	Box.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
	Box.BorderSizePixel = 0
	Box.Parent = Page

	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(1, -210, 1, 0)
	Label.Position = UDim2.new(0, 12, 0, 0)
	Label.BackgroundTransparency = 1
	Label.Text = Name
	Label.TextColor3 = Color3.fromRGB(240, 240, 240)
	Label.TextSize = 13
	Label.Font = Enum.Font.GothamMedium
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Parent = Box

	local Input = Instance.new("TextBox")
	Input.Size = UDim2.new(0, 75, 0, 27)
	Input.Position = UDim2.new(1, -195, 0.5, -13)
	Input.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
	Input.BorderSizePixel = 0
	Input.Text = DefaultText or ""
	Input.PlaceholderText = "Username"
	Input.TextColor3 = Color3.fromRGB(255, 255, 255)
	Input.TextSize = 11
	Input.Font = Enum.Font.Gotham
	Input.ClearTextOnFocus = false
	Input.Parent = Box
	local InputCorner = Instance.new("UICorner") InputCorner.CornerRadius = UDim.new(0, 4) InputCorner.Parent = Input

	local Button1 = Instance.new("TextButton")
	Button1.Size = UDim2.new(0, 50, 0, 27)
	Button1.Position = UDim2.new(1, -115, 0.5, -13)
	Button1.BackgroundColor3 = MAIN_COLOR
	Button1.BorderSizePixel = 0
	Button1.Text = Btn1Text
	Button1.TextColor3 = Color3.fromRGB(255, 255, 255)
	Button1.TextSize = 11
	Button1.Font = Enum.Font.GothamBold
	Button1.Parent = Box
	local B1Corner = Instance.new("UICorner") B1Corner.CornerRadius = UDim.new(0, 4) B1Corner.Parent = Button1

	local Button2 = Instance.new("TextButton")
	Button2.Size = UDim2.new(0, 60, 0, 27)
	Button2.Position = UDim2.new(1, -62, 0.5, -13)
	Button2.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
	Button2.BorderSizePixel = 0
	Button2.Text = Btn2Text
	Button2.TextColor3 = Color3.fromRGB(255, 255, 255)
	Button2.TextSize = 11
	Button2.Font = Enum.Font.GothamBold
	Button2.Parent = Box
	local B2Corner = Instance.new("UICorner") B2Corner.CornerRadius = UDim.new(0, 4) B2Corner.Parent = Button2

	Button1.MouseButton1Click:Connect(function()
		if getgenv().Destroyed or getgenv().ToxOptionsReady == false then return end
		Callback(Input.Text, "TP")
	end)

    Button2.MouseButton1Click:Connect(function()
		if getgenv().Destroyed or getgenv().ToxOptionsReady == false then return end
		Callback(Input.Text, "LOOP")
	end)

    if getgenv().RegisterToxSearchControl then
        getgenv().RegisterToxSearchControl(Name, Page, Box)
    end

	return Box
end

getgenv().CreateDropdown = function(Name, Options, Page, DefaultOption, Callback)
	local Box = Instance.new("Frame")
	Box.Size = UDim2.new(1, -5, 0, 48)
	Box.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
	Box.BorderSizePixel = 0
	Box.Parent = Page

	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(1, -110, 1, 0)
	Label.Position = UDim2.new(0, 12, 0, 0)
	Label.BackgroundTransparency = 1
	Label.Text = Name
	Label.TextColor3 = Color3.fromRGB(240, 240, 240)
	Label.TextSize = 13
	Label.Font = Enum.Font.GothamMedium
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Parent = Box

	local Button = Instance.new("TextButton")
	Button.Size = UDim2.new(0, 95, 0, 27)
	Button.Position = UDim2.new(1, -107, 0.5, -13)
	Button.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
	Button.BorderSizePixel = 0
	Button.Text = DefaultOption
	Button.TextColor3 = Color3.fromRGB(255, 255, 255)
	Button.TextSize = 12
	Button.Font = Enum.Font.Gotham
	Button.Parent = Box

	local CurrentIdx = 1
	for i, opt in ipairs(Options) do if opt == DefaultOption then CurrentIdx = i end end

	Button.MouseButton1Click:Connect(function()
		if getgenv().Destroyed or getgenv().ToxOptionsReady == false then return end
		CurrentIdx = CurrentIdx + 1
		if CurrentIdx > #Options then CurrentIdx = 1 end
		Button.Text = Options[CurrentIdx]
		Callback(Options[CurrentIdx])
        AutoSaveConfiguration()
	end)

    if getgenv().RegisterToxSearchControl then
        getgenv().RegisterToxSearchControl(Name, Page, Box, Options)
    end

	return Box
end

getgenv().CreateButton = function(Name, Page, Callback)
	local Button = Instance.new("TextButton")
	Button.Size = UDim2.new(1, -5, 0, 39)
	Button.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
	Button.BorderSizePixel = 0
	Button.Text = Name
	Button.TextColor3 = Color3.fromRGB(240, 240, 240)
	Button.TextSize = 13
	Button.Font = Enum.Font.GothamMedium
	Button.Parent = Page
	local Corner = Instance.new("UICorner") Corner.CornerRadius = UDim.new(0, 4) Corner.Parent = Button

	Button.MouseButton1Click:Connect(function()
		if getgenv().Destroyed or getgenv().ToxOptionsReady == false then return end
		Callback(Button)
	end)

    if getgenv().RegisterToxSearchControl then
        getgenv().RegisterToxSearchControl(Name, Page, Button)
    end

	return Button
end

getgenv().CreateConfirmButton = function(Name, Page, Callback)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, -5, 0, 39)
    Button.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
    Button.BorderSizePixel = 0
    Button.Text = Name
    Button.TextColor3 = Color3.fromRGB(240, 240, 240)
    Button.TextSize = 13
    Button.Font = Enum.Font.GothamMedium
    Button.Parent = Page
    local Corner = Instance.new("UICorner") Corner.CornerRadius = UDim.new(0, 4) Corner.Parent = Button

    local Confirming = false

    Button.MouseButton1Click:Connect(function()
        if getgenv().Destroyed or getgenv().ToxOptionsReady == false then return end
        if not Confirming then
            Confirming = true
            Button.Text = "CONFIRM " .. string.upper(Name) .. "? (Click Again)"
            Button.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
            task.delay(3.5, function()
                if not getgenv().Destroyed and Confirming then
                    Confirming = false
                    Button.Text = Name
                    Button.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
                end
            end)
        else
            Confirming = false
            Button.Text = Name
            Button.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
            Callback(Button)
        end
    end)

    if getgenv().RegisterToxSearchControl then
        getgenv().RegisterToxSearchControl(Name, Page, Button)
    end

    return Button
end

getgenv().CreateKeybindButton = function(Name, Page, DefaultKey, Callback)
    local Box = Instance.new("Frame")
    Box.Size = UDim2.new(1, -5, 0, 48)
    Box.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
    Box.BorderSizePixel = 0
    Box.Parent = Page

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -110, 1, 0)
    Label.Position = UDim2.new(0, 12, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = Name
    Label.TextColor3 = Color3.fromRGB(240, 240, 240)
    Label.TextSize = 13
    Label.Font = Enum.Font.GothamMedium
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Box

    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(0, 95, 0, 27)
    Button.Position = UDim2.new(1, -107, 0.5, -13)
    Button.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
    Button.BorderSizePixel = 0
    Button.Text = DefaultKey and DefaultKey.Name or "NONE"
    Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    Button.TextSize = 12
    Button.Font = Enum.Font.Gotham
    Button.Parent = Box

    local Binding = false
    local CurrentKey = DefaultKey

    Button.MouseButton1Click:Connect(function()
        if getgenv().ToxOptionsReady == false or Binding then return end
        Binding = true
        Button.Text = "Press Key..."

        local conn
        conn = UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Keyboard then
                conn:Disconnect()
                Binding = false

                if input.KeyCode == Enum.KeyCode.Escape then
                    CurrentKey = nil
                    Button.Text = "NONE"
                else
                    CurrentKey = input.KeyCode
                    Button.Text = input.KeyCode.Name
                end

                Callback(CurrentKey)

                if getgenv().AutoSaveConfiguration then
                    getgenv().AutoSaveConfiguration()
                end
            elseif input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.MouseButton2 then
                conn:Disconnect()
                Binding = false
                CurrentKey = nil
                Button.Text = "NONE"
                Callback(nil)

                if getgenv().AutoSaveConfiguration then
                    getgenv().AutoSaveConfiguration()
                end
            end
        end)
    end)

    if getgenv().RegisterToxSearchControl then
        getgenv().RegisterToxSearchControl(Name, Page, Box)
    end

    return Box
end


getgenv().CreateKeybindToggle = function(Name, Page, DefaultKey, DefaultToggle, KeyCallback, ToggleCallback, SyncKey)
    local Box = Instance.new("Frame")
    Box.Size = UDim2.new(1, -5, 0, 48)
    Box.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
    Box.BorderSizePixel = 0
    Box.Parent = Page

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -178, 1, 0)
    Label.Position = UDim2.new(0, 12, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = Name
    Label.TextColor3 = Color3.fromRGB(240, 240, 240)
    Label.TextSize = 13
    Label.Font = Enum.Font.GothamMedium
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Box

    local KeyButton = Instance.new("TextButton")
    KeyButton.Size = UDim2.new(0, 62, 0, 27)
    KeyButton.Position = UDim2.new(1, -150, 0.5, -13)
    KeyButton.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
    KeyButton.BorderSizePixel = 0
    KeyButton.Text = DefaultKey and DefaultKey.Name or "NONE"
    KeyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    KeyButton.TextSize = 11
    KeyButton.Font = Enum.Font.Gotham
    KeyButton.Parent = Box

    local AutoLabel = Instance.new("TextLabel")
    AutoLabel.Size = UDim2.new(0, 38, 1, 0)
    AutoLabel.Position = UDim2.new(1, -84, 0, 0)
    AutoLabel.BackgroundTransparency = 1
    AutoLabel.Text = Name == "Silent Aim" and "" or "AUTO"
    AutoLabel.TextColor3 = Color3.fromRGB(175, 175, 190)
    AutoLabel.TextSize = 9
    AutoLabel.Font = Enum.Font.GothamBold
    AutoLabel.Parent = Box

    local Toggle = Instance.new("TextButton")
    Toggle.Size = UDim2.new(0, 38, 0, 20)
    Toggle.Position = UDim2.new(1, -42, 0.5, -10)
    Toggle.BorderSizePixel = 0
    Toggle.Text = ""
    Toggle.AutoButtonColor = false
    Toggle.Parent = Box

    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(0, 4)
    ToggleCorner.Parent = Toggle

    local Indicator = Instance.new("Frame")
    Indicator.Size = UDim2.new(0, 14, 0, 14)
    Indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Indicator.BorderSizePixel = 0
    Indicator.Parent = Toggle

    local IndicatorCorner = Instance.new("UICorner")
    IndicatorCorner.CornerRadius = UDim.new(0, 3)
    IndicatorCorner.Parent = Indicator

    local Binding = false
    local CurrentKey = DefaultKey
    local Enabled = getgenv().ToxOptionsReady == false
        and false
        or (DefaultToggle == true)

    local function UpdateToggle()
        if Enabled then
            Toggle.BackgroundColor3 = Color3.fromRGB(50, 180, 70)
            Indicator.Position = UDim2.new(1, -17, 0.5, -7)
        else
            Toggle.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
            Indicator.Position = UDim2.new(0, 3, 0.5, -7)
        end
    end

    local Controller = {
        Button = Box,
        SetVisual = function(Value)
            Enabled = Value == true
            UpdateToggle()
        end
    }

    RegisterSharedToggle(SyncKey, Controller)
    RegisterStartupToggleCallback(SyncKey, ToggleCallback)

    KeyButton.MouseButton1Click:Connect(function()
        if Destroyed or getgenv().ToxOptionsReady == false or Binding then return end

        Binding = true
        KeyButton.Text = "..."

        local conn
        conn = UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Keyboard then
                conn:Disconnect()
                Binding = false

                if input.KeyCode == Enum.KeyCode.Escape then
                    CurrentKey = nil
                    KeyButton.Text = "NONE"
                else
                    CurrentKey = input.KeyCode
                    KeyButton.Text = input.KeyCode.Name
                end

                KeyCallback(CurrentKey)
                AutoSaveConfiguration()
            elseif input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.MouseButton2 then
                conn:Disconnect()
                Binding = false
                CurrentKey = nil
                KeyButton.Text = "NONE"
                KeyCallback(nil)
                AutoSaveConfiguration()
            end
        end)
    end)

    Toggle.MouseButton1Click:Connect(function()
        if getgenv().Destroyed or getgenv().ToxOptionsReady == false then return end

        Enabled = not Enabled
        UpdateToggle()
        ToggleCallback(Enabled)

        if SyncKey and getgenv().SyncToggleVisuals then
            getgenv().SyncToggleVisuals(SyncKey, Enabled)
        end

        AutoSaveConfiguration()

        if getgenv().ScriptLoaded then
            CustomNotify(
                Name .. " Auto " .. (Enabled and "Enabled" or "Disabled"),
                Enabled
                    and Color3.fromRGB(100, 255, 100)
                    or Color3.fromRGB(255, 100, 100)
            )
        end
    end)

    UpdateToggle()

    if getgenv().RegisterToxSearchControl then
        getgenv().RegisterToxSearchControl(Name, Page, Box)
    end

    return Box
end

local function ApplyStagedOptionsAfterLoadScreen()
    if getgenv().ToxStartupOptionsApplied
    or getgenv().Destroyed
    or not getgenv().ScriptLoaded then
        return
    end

    local staged = getgenv().ToxStartupBooleanState
    local callbacks = getgenv().ToxStartupToggleCallbacks

    if typeof(staged) ~= "table" then
        staged = {}
    end

    for key, value in pairs(staged) do
        Settings[key] = value == true
    end

    getgenv().ToxStartupOptionsApplied = true
    getgenv().ToxOptionsReady = true

    if getgenv().SyncToggleVisuals then
        for key, value in pairs(staged) do
            pcall(function()
                getgenv().SyncToggleVisuals(key, value == true)
            end)
        end
    end

    if typeof(callbacks) == "table" then
        for key, value in pairs(staged) do
            if value == true
            and type(callbacks[key]) == "function" then
                pcall(callbacks[key], true)
            end
        end
    end

    getgenv().ToxStartupBooleanState = nil
    getgenv().ToxStartupToggleCallbacks = nil
end

task.spawn(function()
    while not getgenv().Destroyed
    and not getgenv().ScriptLoaded do
        task.wait(0.03)
    end

    if getgenv().Destroyed then
        return
    end

    ApplyStagedOptionsAfterLoadScreen()
end)
