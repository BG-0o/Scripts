local env = getgenv()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local Player = Players.LocalPlayer
local GUIColorMap = env.GUIColorMap or {}
local ColorMap = env.ColorMap or {}
local MAIN_COLOR = env.MAIN_COLOR
getgenv().Settings = {
	Noclip = false,
	InfiniteJump = false,
	Speed = false,
	Jump = false,
	SmoothFly = false,
    NormalFly = false,
    FlyBypass = false,
	NoFallDamage = false,
	NoFallSpeed = 50,
	AntiVoid = false,
	AntiFling = true,
	WalkFling = false,
	WalkFlingPower = 30,
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
    MobileToggle = true,
    CollapseSidebar = false,
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
    MagicBullet = false,
    MagicBulletFOV = 120,
    MagicBulletFOVEnabled = false,
    Triggerbot = false,
    TriggerbotDelay = 0.12,
    Spinbot = false,
    SpinSpeed = 50,
    HitboxExpander = false,
    HitboxSize = 10,
    HeadHitboxExpander = false,
    HeadHitboxSize = 7,
    KillAura = false,
    KillAuraRange = 15,
    UltraInstinct = false,
    UltraInstinctRange = 14,
    AntiSocial = false,
    AntiSocialRange = 20,
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
    ESPSkeleton = false,
    TargetESP = false,
    TargetESPColor = Color3.fromRGB(255, 30, 30),
    SpectatorList = false,
    KeybindsList = false,
    ShowToxBinds = false,
    ToxBinds = {},
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
    MM2FlingCustomNick = "",
    MM2KillOnFull = false,
    MM2KillOnFullTarget = "Both",
    MM2SafeLobby = false,
    MM2AutoFarmMode = "Tween",
    MM2AutoFarmAvoidMurderer = true,
    MM2AutoFarmDepth = 3.2,
    MM2AutoFarmTeleportDelay = 1.2,
    MM2AutoVote = false,
    MM2VoteMap = "Priority (Best Coins)",
    MM2VoteInfinite = true,
    ToxUITheme = "Dark Neon",
    ToxUITransparency = 0,
    Theme = nil,
    CustomAccentActive = false,
    UIRainbow = false,
    UIRainbowSpeed = 35,
    SidebarExpandedWidth = 175,
    Watermark = true,
    DimBackground = false,
    AutoCloseExecute = false,
    WindowGradient = false,
    AutoScaleScreen = true,
    DraggableCards = true,
    CardLayoutOrder = {},
    Weather = "Off",
    WeatherArea = "Full",
    WeatherAmount = 100,
    WeatherSize = 100,
    WallpaperUrl = "",
    WallpaperDim = 0.25,
    CustomIconUrl = "",
    PinnedOrder = nil,
    ADMINPrefix = ".",
    ADMINKillTarget = "",
    ADMINKillAll = false,
    ADMINRocketTarget = "",
    ADMINRocketAll = false,
    ADMINKickTarget = "",
    ToxLastChangelogVersion = "",
    ToxServerInfoVisible = false,
    ToxServerInfoMode = "FPS/Ping/Players",
    EspMaxDistEnabled = false,
    No3DRender = false,
    AirWalkPlatform = false,
    ReturnByDeath = false,
    InstantPrompts = false,
    ToolMagnet = false,
    TACAutoFarm = false,
    SSAutoFarm = false,
    MEAutoFarm = false,
    BINGOAutoFarm = false,
    CFAutoFarm = false,
    ADAutoFarm = false
}
local UIPreferenceKeys = {
    ShowToxBinds = true,
    KeybindsList = true,
    Theme = true,
    ToxUITheme = true,
    ToxUITransparency = true,
    GUIColorName = true,
    CustomAccentActive = true,
    UIRainbow = true,
    UIRainbowSpeed = true,
    GUISizes = true,
    GUIScales = true,
    GUIKeybind = true,
    MobileToggle = true,
    CollapseSidebar = true,
    SidebarExpandedWidth = true,
    Watermark = true,
    DimBackground = true,
    AutoCloseExecute = true,
    WindowGradient = true,
    AutoScaleScreen = true,
    DraggableCards = true,
    CardLayoutOrder = true,
    Weather = true,
    WeatherArea = true,
    WeatherAmount = true,
    WeatherSize = true,
    WallpaperUrl = true,
    WallpaperDim = true,
    CustomIconUrl = true,
    MusicVolume = true,
    PinnedOrder = true,
    ToxServerInfoVisible = true,
    ToxServerInfoMode = true,
    AutoExecute = true
}
local PersistedSettingKeys = {}
for key in pairs(getgenv().Settings) do
    PersistedSettingKeys[key] = true
end
for key in pairs(UIPreferenceKeys) do
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
local Settings = getgenv().Settings
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
local function AddConnection(conn)
    if not conn then return end
    table.insert(getgenv().ScriptConnections, conn)
    return conn
end
getgenv().AddConnection = AddConnection
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
local UIProfileFilePath =
    FolderName
    .. "/ui_profile_"
    .. tostring(Player.UserId)
    .. ".json"
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
    local gamePrefix = ""
    local curMod = getgenv().CurrentGameModule
    if curMod and curMod.ShortName then
        gamePrefix = tostring(curMod.ShortName)
    end
    local function isGameKey(k)
        if typeof(k) ~= "string" then return false end
        if IsCurrentGameSetting(k) then return true end
        if gamePrefix ~= "" and string.sub(k, 1, #gamePrefix) == gamePrefix then return true end
        if string.find(k, "AutoFarm") or string.find(k, "SafeLobby") or string.find(k, "KillOnFull")
        or string.find(k, "SilentAim") or string.find(k, "TrapESP") or string.find(k, "GunESP")
        or string.find(k, "Vote") then
            return true
        end
        return false
    end
    for key in pairs(PersistedSettingKeys) do
        if isGameKey(key) then
            snapshot[key] = SerializeConfigValue(
                Settings[key]
            )
        end
    end
    for key in pairs(Settings) do
        if isGameKey(key) then
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
        if value ~= "Custom" and ColorMap[value] then
            Settings.EspColor = ColorMap[value]
        end
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
local function HasSavedConfigForCurrentPlace()
    if not isfile or not readfile then return false, nil, false end
    local placePath, isLegacy = ResolveConfigReadPath()
    if placePath and isfile(placePath) then
        local metadata = ReadConfigMetadata(placePath)
        if metadata and (metadata.PlaceId == nil or tonumber(metadata.PlaceId) == game.PlaceId) then
            return true, placePath, isLegacy
        end
    end
    return false, nil, false
end
local function SaveSharedUIProfile(savedTimestamp)
    EnsureFolder()
    if not writefile then
        return false
    end
    local uiSettings = {}
    for key in pairs(UIPreferenceKeys) do
        if Settings[key] ~= nil then
            uiSettings[key] = SerializeConfigValue(Settings[key])
        end
    end
    local guiKeyName = "NONE"
    if Settings.GUIKeybind and typeof(Settings.GUIKeybind) == "EnumItem" then
        guiKeyName = Settings.GUIKeybind.Name
    end
    local payload = {
        Version = 1,
        SavedAt = tonumber(savedTimestamp) or os.time(),
        GlobalGUIKeybind = guiKeyName,
        UISettings = uiSettings,
        UIPositions = SerializeConfigValue(getgenv().UIPositions or {})
    }
    return pcall(function()
        writefile(UIProfileFilePath, HttpService:JSONEncode(payload))
    end)
end
local function LoadSharedUIProfile(placeSavedAt)
    if not isfile or not readfile or not isfile(UIProfileFilePath) then
        return false
    end
    local applied = false
    pcall(function()
        local raw = readfile(UIProfileFilePath)
        if not raw or raw == "" then
            return
        end
        local data = HttpService:JSONDecode(raw)
        if typeof(data) ~= "table" then
            return
        end
        local profileTime = tonumber(data.SavedAt) or 0
        if placeSavedAt and placeSavedAt > profileTime then
            return
        end
        if typeof(data.UISettings) == "table" then
            for key, savedValue in pairs(data.UISettings) do
                if UIPreferenceKeys[key] then
                    ApplyLoadedSetting(key, savedValue)
                end
            end
        end
        if data.GlobalGUIKeybind ~= nil then
            local keyName = tostring(data.GlobalGUIKeybind)
            if keyName == "NONE" or keyName == "" then
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
        if data.UIPositions ~= nil then
            local decodedPos = DeserializeConfigValue(data.UIPositions)
            if typeof(decodedPos) == "table" then
                getgenv().UIPositions = decodedPos
            end
        end
        applied = true
    end)
    return applied
end
getgenv().HasSavedConfigForCurrentPlace = HasSavedConfigForCurrentPlace

local saveDebounceTimer = nil

local function InternalSaveConfiguration()
    if getgenv().Destroyed then
        return false
    end
    if getgenv().ToxAutoSaveEnabled ~= true then
        return false
    end
    if not getgenv().CurrentGameModule then
        SaveSharedMusicIDs()
        SaveSharedJoinGames()
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
    SaveSharedUIProfile(data.SavedAt)
    return primaryOK
end

getgenv().AutoSaveConfiguration = function(force)
    if getgenv().Destroyed then
        return false
    end
    if not force and getgenv().ToxOptionsReady == false then
        return false
    end
    if not force and getgenv().ToxAutoSaveEnabled ~= true then
        return false
    end

    if force then
        if saveDebounceTimer then
            pcall(task.cancel, saveDebounceTimer)
            saveDebounceTimer = nil
        end
        return InternalSaveConfiguration()
    end

    if saveDebounceTimer then
        pcall(task.cancel, saveDebounceTimer)
    end
    saveDebounceTimer = task.delay(0.5, function()
        saveDebounceTimer = nil
        task.spawn(InternalSaveConfiguration)
    end)
    return true
end
local function LoadConfiguration()
    if not readfile then
        getgenv().ToxAutoSaveEnabled = true
        return
    end
    local hasSave, sourcePath, migratedFromLegacy = HasSavedConfigForCurrentPlace()
    if not hasSave or not sourcePath then
        getgenv().ToxHasPlaceConfig = false
        getgenv().ToxAutoSaveEnabled = true
        for key, value in pairs(Settings) do
            if typeof(value) == "boolean" and key ~= "Render3D" and not UIPreferenceKeys[key] then
                Settings[key] = false
            end
        end
        Settings.Render3D = true
        Settings.Render3DDisabled = false
        LoadSharedUIProfile(nil)
        return
    end
    getgenv().ToxHasPlaceConfig = true
    getgenv().ToxAutoSaveEnabled = true
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
        LoadSharedUIProfile(tonumber(data.SavedAt) or 0)
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
    if getgenv().CurrentGameModule or getgenv().ToxHasPlaceConfig then
        return
    end
    for key, value in pairs(Settings) do
        if typeof(value) == "boolean" and not UIPreferenceKeys[key] then
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
        end
    end
    getgenv().ToxStartupBooleanState = staged
    getgenv().ToxStartupToggleCallbacks = getgenv().ToxStartupToggleCallbacks or {}
    getgenv().ToxStartupOptionsApplied = false
    getgenv().ToxOptionsReady = true
end
getgenv().SavePlaceConfiguration = function()
    getgenv().ToxAutoSaveEnabled = true
    getgenv().ToxHasPlaceConfig = true
    return getgenv().AutoSaveConfiguration(true)
end
getgenv().LoadPlaceConfiguration = function()
    local hasSave = HasSavedConfigForCurrentPlace()
    if hasSave then
        LoadConfiguration()
        getgenv().ToxHasPlaceConfig = true
        getgenv().ToxAutoSaveEnabled = true
        if getgenv().SyncAllTogglesToUI then
            pcall(getgenv().SyncAllTogglesToUI)
        end
        return true
    end
    return false
end
getgenv().ResetPlaceConfiguration = function()
    if isfile and isfile(ConfigFilePath) then
        if typeof(delfile) == "function" then
            pcall(delfile, ConfigFilePath)
            if isfile(ConfigBackupFilePath) then pcall(delfile, ConfigBackupFilePath) end
        elseif typeof(writefile) == "function" then
            pcall(writefile, ConfigFilePath, "")
        end
    end
    getgenv().ToxHasPlaceConfig = false
    getgenv().ToxAutoSaveEnabled = false
    for key, val in pairs(Settings) do
        if typeof(val) == "boolean" and key ~= "Render3D" then
            Settings[key] = false
        end
    end
    Settings.Render3D = true
    Settings.Render3DDisabled = false
    Settings.WalkSpeed = 16
    Settings.JumpPower = 50
    Settings.HitboxSize = 10
    Settings.HeadHitboxSize = 7
    if getgenv().RestoreHitboxDefaults then pcall(getgenv().RestoreHitboxDefaults) end
    if getgenv().RestoreHeadHitboxDefaults then pcall(getgenv().RestoreHeadHitboxDefaults) end
    if getgenv().SyncAllTogglesToUI then
        pcall(getgenv().SyncAllTogglesToUI)
    end
    return true
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
Settings.ToxUITransparency = math.clamp(tonumber(Settings.ToxUITransparency) or 0, 0, 1)
local LoadedGUIColor =
    GUIColorMap[
        tostring(
            Settings.GUIColorName
            or "Blue"
        )
    ]
if Settings.CustomAccentActive == true
and typeof(Settings.Theme) == "table"
and typeof(Settings.Theme.Accent) == "Color3" then
    MAIN_COLOR = Settings.Theme.Accent
    getgenv().MAIN_COLOR = MAIN_COLOR
elseif LoadedGUIColor then
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
env.LoadConfiguration = LoadConfiguration
env.PersistedSettingKeys = PersistedSettingKeys
env.EnsureToxFolder = EnsureFolder
