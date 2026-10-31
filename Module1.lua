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
    },
    [109440000000000 + 485612336] = {
        ShortName = "WID",
        Url = "https://raw.githubusercontent.com/BG-0o/Scripts/refs/heads/main/WID.lua",
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
getgenv().ToxModule1SplitVersion = "2026-10-19-kick-autoreexec-persist-v12"
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

local FolderName = "ToxHub"
local LegacyFolderName = "ToxV1_Data"
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
    ConfigFilePath

local ConfigBackupFilePath =
    FolderName
    .. "/config_"
    .. tostring(Player.UserId)
    .. "_"
    .. CurrentPlaceKey
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

local OldPlaceConfigFilePath =
    LegacyFolderName
    .. "/config_"
    .. tostring(Player.UserId)
    .. "_"
    .. CurrentPlaceKey
    .. ".json"

local OldMusicIDsFilePath =
    LegacyFolderName
    .. "/music_ids.json"

local OldJoinGamesFilePath =
    LegacyFolderName
    .. "/saved_join_games.json"

local OldLegacyConfigFilePath =
    LegacyFolderName
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
            if not isfolder(FolderName) then
                makefolder(FolderName)
            end
        end)
    end
end

local function MigrateLegacySaveFolder()
    EnsureFolder()

    if not isfolder
    or not isfolder(LegacyFolderName)
    or not listfiles
    or not readfile
    or not writefile then
        return
    end

    pcall(function()
        for _, sourcePath in ipairs(listfiles(LegacyFolderName)) do
            local normalized = tostring(sourcePath):gsub("\\", "/")
            local fileName = string.match(normalized, "([^/]+)$")

            if fileName and fileName ~= "" then
                local targetPath = FolderName .. "/" .. fileName
                local migrated = isfile and isfile(targetPath) or false

                if not migrated then
                    local readOK, raw = pcall(function()
                        return readfile(sourcePath)
                    end)

                    if readOK and raw ~= nil then
                        local writeOK = pcall(function()
                            writefile(targetPath, raw)
                        end)

                        migrated = writeOK
                            and (not isfile or isfile(targetPath))
                    end
                end

                if migrated and delfile then
                    pcall(function()
                        delfile(sourcePath)
                    end)
                end
            end
        end

        if delfolder and isfolder(LegacyFolderName) then
            local remaining = listfiles(LegacyFolderName)

            if typeof(remaining) == "table"
            and #remaining == 0 then
                pcall(function()
                    delfolder(LegacyFolderName)
                end)
            end
        end
    end)
end

MigrateLegacySaveFolder()

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
                OldMusicIDsFilePath
            )
    end

    if not saved then
        saved =
            DecodeSavedIDsFromFile(
                LegacyConfigFilePath
            )
    end

    if not saved then
        saved =
            DecodeSavedIDsFromFile(
                OldLegacyConfigFilePath
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
                OldJoinGamesFilePath
            )
    end

    if not saved then
        saved =
            DecodeSavedJoinGamesFromFile(
                LegacyConfigFilePath
            )
    end

    if not saved then
        saved =
            DecodeSavedJoinGamesFromFile(
                OldLegacyConfigFilePath
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
    if not getgenv().CurrentGameModule
    or not isfile then
        return nil, false
    end

    if isfile(ConfigFilePath) then
        local metadata = ReadConfigMetadata(ConfigFilePath)
        local version = metadata
            and tonumber(metadata.ConfigVersion)
            or 0

        return ConfigFilePath, version < 8
    end

    if isfile(OldPlaceConfigFilePath) then
        return OldPlaceConfigFilePath, true
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

    if not getgenv().CurrentGameModule then
        SaveSharedMusicIDs()
        SaveSharedJoinGames()
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
        ConfigVersion = 8,
        SavedAt = os.time(),
        UserId = Player.UserId,
        PlaceId = game.PlaceId,
        ConfigScope = "PLACE_ONLY",
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
    and isfile(ConfigFilePath) then
        pcall(function()
            oldPrimary = readfile(ConfigFilePath)
        end)
    end

    local primaryOK, primaryError =
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

    return primaryOK
end

local function LoadConfiguration()
    if not getgenv().CurrentGameModule
    or not readfile then
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

        if savedPlaceId
        and savedPlaceId ~= game.PlaceId then
            return
        end
        strictPlaceMigration =
            game.PlaceId == 189707
            and configVersion < 6

        MigrateLegacyGameSettings(data)

        if typeof(data.Settings) == "table"
        and configVersion >= 8
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

        if configVersion >= 8
        and data.GlobalGUIKeybind ~= nil then
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

        if configVersion >= 8
        and data.UIPositions ~= nil then
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

    Settings.Render3D = true
    Settings.Render3DDisabled = false
    getgenv().ToxUnsupportedGameDefaultsForced = true
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

-- O payload atual ja foi consumido; libera o Auto Execute para armar a proxima rodada.
env.ToxAutoExecuteQueued = false
env.ToxAutoExecuteQueuedGame = nil

task.wait(0.55)

local shouldExecute = false
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
            "ToxHub/config_"
            .. userId
            .. "_"
            .. tostring(game.PlaceId)
            .. ".json"

        local legacyConfigPath =
            "ToxV1_Data/config_"
            .. userId
            .. "_"
            .. tostring(game.PlaceId)
            .. ".json"

        local readPath = nil

        if isfile and isfile(configPath) then
            readPath = configPath
        elseif isfile and isfile(legacyConfigPath) then
            readPath = legacyConfigPath
        end

        if readfile
        and readPath then
            local HttpService =
                game:GetService("HttpService")
            local raw = readfile(readPath)

            if raw and raw ~= "" then
                local data =
                    HttpService:JSONDecode(raw)

                if data
                and tonumber(data.PlaceId) == game.PlaceId
                and data.Settings then
                    shouldExecute =
                        data.Settings.AutoExecute == true
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

local guardNow = tick()
local previousGuardAt = tonumber(env.__ToxQueuedDestinationAt) or 0

-- Bloqueia apenas payloads duplicados quase simultaneos, nao futuros kicks.
if env.__ToxQueuedDestinationGame == game
and guardNow - previousGuardAt < 2 then
    return
end

env.__ToxQueuedDestinationGame = game
env.__ToxQueuedDestinationAt = guardNow

task.delay(2, function()
    if env.__ToxQueuedDestinationGame == game
    and env.__ToxQueuedDestinationAt == guardNow then
        env.__ToxQueuedDestinationGame = nil
        env.__ToxQueuedDestinationAt = nil
    end
end)

local ok = pcall(function()
    loadstring(
        game:HttpGet(
            "https://raw.githubusercontent.com/BG-0o/Scripts/main/ToxHud.lua"
        )
    )()
end)

if not ok
and env.__ToxQueuedDestinationAt == guardNow then
    env.__ToxQueuedDestinationGame = nil
    env.__ToxQueuedDestinationAt = nil
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

        if UserInputService:IsKeyDown(Enum.KeyCode.E)
        or UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            vertical += 1
        end

        if UserInputService:IsKeyDown(Enum.KeyCode.Q)
        or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
        or UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            vertical -= 1
        end

        if vertical ~= 0 then
            LockedAirWalkY +=
                vertical
                * 28
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

if not getgenv().__ToxModule1AirWalkHooked then
    getgenv().__ToxModule1AirWalkHooked = true
    RunService.Heartbeat:Connect(function()
        if Settings.AirWalk then
            pcall(UpdateAirWalk)
        end
    end)
end

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

