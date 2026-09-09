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

if getgenv().Gui then pcall(function() getgenv().Gui:Destroy() end) end
if getgenv().NotifGui then pcall(function() getgenv().NotifGui:Destroy() end) end

local LOGO_ID = "rbxassetid://120675082996894"
local MAIN_COLOR = Color3.fromRGB(9, 0, 136) 

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
        Url = "https://raw.githubusercontent.com/BG-0o/Scripts/refs/heads/main/MM2.lua",
        Ready = true
    },
    [4522347649] = {
        ShortName = "ADMIN",
        Url = "https://raw.githubusercontent.com/BG-0o/Scripts/refs/heads/main/ADMIN.lua",
        Ready = true
    }
}

getgenv().CurrentGameModule = getgenv().GameModuleRegistry[game.PlaceId]
getgenv().ToxTeleportBypassUntil = 0
getgenv().AllowToxTeleport = function(seconds)
    getgenv().ToxTeleportBypassUntil = math.max(
        tonumber(getgenv().ToxTeleportBypassUntil) or 0,
        tick() + (tonumber(seconds) or 1)
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
	AutoExecute = false,
	GUIKeybind = Enum.KeyCode.LeftAlt,

	SpeedValue = 16,
	JumpValue = 50,
	FlySpeed = 10,

    FOVEnabled = false,
    FOVValue = 70,
    ForceShiftLock = false,
    ShiftLockKey = "Shift",

    Aimbot = false,
    AimbotSmoothness = 2,
    AimPart = "Head",
    AimWallCheck = false,
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
    TracerOrigin = "DOWN",
    EspMaxDistance = 1000,
    Chams = false,
	EspColorName = "White",
	EspColor = Color3.fromRGB(255, 255, 255),
    ESPTeamColors = false,

    MusicAutoPlay = false,
    MusicLoop = false,
    MusicVolume = 100,
    CurrentTrackIndex = 1,

    NDSAutoWin = false,
    NDSWaterFly = false,
    NDSWaterFlySpeed = 40,
    NDSNoTP = false,

    MM2RoleESP = false,
    MM2AutoFarm = false,
    MM2AutoFarmV2 = false,
    MM2AutoFarmSpeed = 5,
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
    ADMINKickTarget = ""
}

local PersistedSettingKeys = {}

for key in pairs(getgenv().Settings) do
    PersistedSettingKeys[key] = true
end

getgenv().SavedIDs = {}
getgenv().SavedJoinGames = {}
getgenv().SavedWaypoints = {}
getgenv().UIPositions = {}
getgenv().GameSharedSettings = {}
getgenv().GameSpecificSettings = {}
getgenv().BaseSharedSettings = {}
getgenv().Destroyed = false
getgenv().ScriptLoaded = false

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
local ConfigFilePath =
    FolderName
    .. "/config_"
    .. tostring(Player.UserId)
    .. ".json"

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
    ConfigFilePath

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
        for placeKey, state in pairs(data.GameSpecificSettings) do
            if typeof(state) == "table" then
                getgenv().GameSpecificSettings[tostring(placeKey)] =
                    state
            end
        end
    end

    if typeof(data.GameSettings) == "table" then
        for placeKey, state in pairs(data.GameSettings) do
            if typeof(state) == "table"
            and getgenv().GameSpecificSettings[tostring(placeKey)] == nil then
                getgenv().GameSpecificSettings[tostring(placeKey)] =
                    state
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

getgenv().AutoSaveConfiguration = function()
    if getgenv().Destroyed then
        return
    end

    EnsureFolder()

    if not writefile then
        return
    end

    getgenv().GameSpecificSettings =
        typeof(getgenv().GameSpecificSettings) == "table"
        and getgenv().GameSpecificSettings
        or {}

    if getgenv().CurrentGameModule then
        getgenv().GameSpecificSettings[
            tostring(game.PlaceId)
        ] = BuildCurrentGameSettingsSnapshot()
    end

    local guiKeyName = "NONE"

    if Settings.GUIKeybind
    and typeof(Settings.GUIKeybind) == "EnumItem" then
        guiKeyName = Settings.GUIKeybind.Name
    end

    local data = {
        ConfigVersion = 4,
        GlobalGUIKeybind = guiKeyName,
        Settings = BuildGlobalSettingsSnapshot(),
        GameSpecificSettings = SerializeConfigValue(
            getgenv().GameSpecificSettings
        ),
        SavedWaypoints = SerializeConfigValue(
            getgenv().SavedWaypoints
        ),
        UIPositions = SerializeConfigValue(
            getgenv().UIPositions
        )
    }

    pcall(function()
        writefile(
            ConfigFilePath,
            HttpService:JSONEncode(data)
        )
    end)

    SaveSharedMusicIDs()
    SaveSharedJoinGames()
end

local function LoadConfiguration()
    if not isfile
    or not readfile
    or not isfile(ConfigFilePath) then
        return
    end

    pcall(function()
        local raw = readfile(ConfigFilePath)

        if not raw or raw == "" then
            return
        end

        local data = HttpService:JSONDecode(raw)

        if typeof(data) ~= "table" then
            return
        end

        MigrateLegacyGameSettings(data)

        if typeof(data.Settings) == "table" then
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



        if data.SavedWaypoints ~= nil then
            local value = DeserializeConfigValue(
                data.SavedWaypoints
            )

            if typeof(value) == "table" then
                getgenv().SavedWaypoints = value
            end
        end

        if data.UIPositions ~= nil then
            local value = DeserializeConfigValue(
                data.UIPositions
            )

            if typeof(value) == "table" then
                getgenv().UIPositions = value
            end
        end
    end)
end

LoadConfiguration()
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

if env.__ToxAutoExecuteDestinationStarted then
    return
end

env.__ToxAutoExecuteDestinationStarted = true

task.wait(0.55)

local shouldExecute = true
local configWasRead = false

for _ = 1, 20 do
    local success = pcall(function()
        local Players =
            game:GetService("Players")

        local localPlayer =
            Players.LocalPlayer

        local configPath =
            "ToxV1_Data/config_"
            .. tostring(
                localPlayer
                and localPlayer.UserId
                or 0
            )
            .. ".json"

        if isfile
        and readfile
        and isfile(configPath) then
            local HttpService = game:GetService("HttpService")
            local raw = readfile(configPath)

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

if shouldExecute then
    local ok = pcall(function()
        loadstring(
            game:HttpGet(
                "https://raw.githubusercontent.com/BG-0o/Scripts/main/ToxHud.lua"
            )
        )()
    end)

    if not ok then
        env.__ToxAutoExecuteDestinationStarted = nil
    end
else
    env.__ToxAutoExecuteDestinationStarted = nil
end
]]

getgenv().ToxAutoExecuteQueued = false

getgenv().QueueToxAutoExecute = function()
    if getgenv().ToxAutoExecuteQueued then
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

AddConnection(Players.PlayerAdded:Connect(function(p)
    if ScriptLoaded then CustomNotify("(" .. p.Name .. ") joined", Color3.fromRGB(50, 255, 50), 3) end
end))

AddConnection(Players.PlayerRemoving:Connect(function(p)
    if ScriptLoaded then CustomNotify("(" .. p.Name .. ") left", Color3.fromRGB(255, 50, 50), 3) end
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

local function UpdateAirWalk()
    local Root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if Settings.AirWalk and Root then
        if not LockedAirWalkY then
            LockedAirWalkY = Root.Position.Y - 3.4
        end
        if not AirWalkPart or not AirWalkPart.Parent then
            AirWalkPart = Instance.new("Part")
            AirWalkPart.Name = "ToxAirWalk"
            AirWalkPart.Size = Vector3.new(8, 1, 8)
            AirWalkPart.Transparency = 1
            AirWalkPart.Anchored = true
            AirWalkPart.Parent = workspace
        end
        AirWalkPart.CFrame = CFrame.new(Root.Position.X, LockedAirWalkY, Root.Position.Z)
    else
        LockedAirWalkY = nil
        if AirWalkPart then AirWalkPart:Destroy() AirWalkPart = nil end
    end
end
getgenv().UpdateAirWalk = UpdateAirWalk

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

local function UpdateFullbright()
    if Settings.Fullbright then
        Lighting.Ambient = Color3.fromRGB(180, 180, 180)
        Lighting.Brightness = 1.2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
    else
        Lighting.Ambient = OriginalLighting.Ambient
        Lighting.Brightness = OriginalLighting.Brightness
        Lighting.ClockTime = OriginalLighting.ClockTime
        Lighting.FogEnd = OriginalLighting.FogEnd
        Lighting.GlobalShadows = OriginalLighting.GlobalShadows
    end
end
getgenv().UpdateFullbright = UpdateFullbright

local ParentContainer = (gethui and gethui()) or game:GetService("CoreGui")
local Gui = Instance.new("ScreenGui")
Gui.Name = "ToxV1Gui"
Gui.ResetOnSpawn = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.DisplayOrder = 999999999
Gui.Parent = ParentContainer
getgenv().Gui = Gui

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
Tabs.Position = UDim2.new(0, 5, 0, 44)
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

local Pages = {}
getgenv().Pages = Pages

getgenv().CreatePage = function(Name)
	local Page = Instance.new("ScrollingFrame")
	Page.Name = Name
	Page.Size = UDim2.new(1, -16, 1, -88)
	Page.Position = UDim2.new(0, 8, 0, 84)
	Page.BackgroundTransparency = 1
	Page.BorderSizePixel = 0
	Page.ScrollBarThickness = 4
	Page.ScrollBarImageColor3 = MAIN_COLOR
	Page.CanvasSize = UDim2.new(0, 0, 0, 0)
	Page.Visible = false
	Page.Parent = Main

	local Layout = Instance.new("UIListLayout")
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

	Pages[Name] = Page
	return Page, Layout
end

local DetectedGameModule = getgenv().CurrentGameModule
local GamePage = nil

if DetectedGameModule and DetectedGameModule.Ready then
    GamePage = CreatePage(DetectedGameModule.ShortName)
end

local CombatPage = CreatePage("COMBAT")
local PlayerPage = CreatePage("PLAYER")
local VisualsPage = CreatePage("VISUALS")
local FlingPage = CreatePage("MISC")
local ScriptsPage = CreatePage("SCRIPTS")
local JoinPage = CreatePage("JOIN")
local ConfigPage = CreatePage("CONFIG")

getgenv().GamePage = GamePage
getgenv().CombatPage = CombatPage
getgenv().PlayerPage = PlayerPage
getgenv().VisualsPage = VisualsPage
getgenv().FlingPage = FlingPage
getgenv().ScriptsPage = ScriptsPage
getgenv().JoinPage = JoinPage
getgenv().ConfigPage = ConfigPage

getgenv().CurrentPage = CombatPage

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

	local Corner = Instance.new("UICorner") Corner.CornerRadius = UDim.new(0, 4) Corner.Parent = Button

	Button.MouseButton1Click:Connect(function()
		if Destroyed then return end
		for _, OtherPage in pairs(Pages) do OtherPage.Visible = false end
		Page.Visible = true
		getgenv().CurrentPage = Page

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

local CombatTab = CreateTab("COMBAT", CombatPage)
local PlayerTab = CreateTab("PLAYER", PlayerPage)
local VisualsTab = CreateTab("VISUALS", VisualsPage)
local ScriptsTab = CreateTab("SCRIPTS", ScriptsPage)
local JoinTab = CreateTab("JOIN", JoinPage)
local FlingTab = CreateTab("MISC", FlingPage)
local ConfigTab = CreateTab("CONFIG", ConfigPage)

getgenv().GameTab = GameTab

CombatPage.Visible = true
CombatTab.BackgroundColor3 = MAIN_COLOR
CombatTab.TextColor3 = Color3.fromRGB(255, 255, 255)

local ChatLogGui = Instance.new("Frame")
ChatLogGui.Name = "ChatLogFrame"
ChatLogGui.Size = UDim2.new(0, 360, 0, 240)
ChatLogGui.Position = UDim2.new(0.5, 180, 0.5, -120)
ChatLogGui.BackgroundColor3 = Color3.fromRGB(10, 10, 16)
ChatLogGui.BorderSizePixel = 0
ChatLogGui.ClipsDescendants = true
ChatLogGui.Visible = false
ChatLogGui.Parent = Gui
getgenv().ChatLogGui = ChatLogGui

local ChatLogCorner = Instance.new("UICorner") ChatLogCorner.CornerRadius = UDim.new(0, 8) ChatLogCorner.Parent = ChatLogGui
local ChatLogStroke = Instance.new("UIStroke") ChatLogStroke.Color = MAIN_COLOR ChatLogStroke.Thickness = 2 ChatLogStroke.Parent = ChatLogGui

local ChatLogTopBar = Instance.new("Frame")
ChatLogTopBar.Size = UDim2.new(1, 0, 0, 32)
ChatLogTopBar.BackgroundColor3 = MAIN_COLOR
ChatLogTopBar.BorderSizePixel = 0
ChatLogTopBar.Parent = ChatLogGui

MakeDraggable(ChatLogGui, ChatLogTopBar)

local ChatLogTitle = Instance.new("TextLabel")
ChatLogTitle.Size = UDim2.new(1, -110, 1, 0)
ChatLogTitle.Position = UDim2.new(0, 10, 0, 0)
ChatLogTitle.BackgroundTransparency = 1
ChatLogTitle.Text = "Chat Logs"
ChatLogTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
ChatLogTitle.Font = Enum.Font.GothamBold
ChatLogTitle.TextSize = 13
ChatLogTitle.TextXAlignment = Enum.TextXAlignment.Left
ChatLogTitle.Parent = ChatLogTopBar

local ChatLogMinBtn = Instance.new("TextButton")
ChatLogMinBtn.Size = UDim2.new(0, 24, 0, 22)
ChatLogMinBtn.Position = UDim2.new(1, -88, 0.5, -11)
ChatLogMinBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 35)
ChatLogMinBtn.BorderSizePixel = 0
ChatLogMinBtn.Text = "-"
ChatLogMinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ChatLogMinBtn.Font = Enum.Font.GothamBold
ChatLogMinBtn.TextSize = 14
ChatLogMinBtn.Parent = ChatLogTopBar
local ChatLogMinCorner = Instance.new("UICorner") ChatLogMinCorner.CornerRadius = UDim.new(0, 4) ChatLogMinCorner.Parent = ChatLogMinBtn

local ClearBtn = Instance.new("TextButton")
ClearBtn.Size = UDim2.new(0, 52, 0, 22)
ClearBtn.Position = UDim2.new(1, -60, 0.5, -11)
ClearBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 35)
ClearBtn.BorderSizePixel = 0
ClearBtn.Text = "Clear"
ClearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ClearBtn.Font = Enum.Font.GothamBold
ClearBtn.TextSize = 11
ClearBtn.Parent = ChatLogTopBar
local ClearCorner = Instance.new("UICorner") ClearCorner.CornerRadius = UDim.new(0, 4) ClearCorner.Parent = ClearBtn

local ChatLogScroll = Instance.new("ScrollingFrame")
ChatLogScroll.Size = UDim2.new(1, -12, 1, -42)
ChatLogScroll.Position = UDim2.new(0, 6, 0, 36)
ChatLogScroll.BackgroundTransparency = 1
ChatLogScroll.BorderSizePixel = 0
ChatLogScroll.ScrollBarThickness = 4
ChatLogScroll.ScrollBarImageColor3 = MAIN_COLOR
ChatLogScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
ChatLogScroll.Parent = ChatLogGui

local ChatLogLayout = Instance.new("UIListLayout")
ChatLogLayout.SortOrder = Enum.SortOrder.LayoutOrder
ChatLogLayout.Padding = UDim.new(0, 4)
ChatLogLayout.Parent = ChatLogScroll

ChatLogLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ChatLogScroll.CanvasSize = UDim2.new(0, 0, 0, ChatLogLayout.AbsoluteContentSize.Y + 10)
    ChatLogScroll.CanvasPosition = Vector2.new(0, ChatLogScroll.CanvasSize.Y.Offset)
end)

local function AddChatLog(sender, text)
    local timeStr = os.date("[%H:%M:%S] ")
    local msgLabel = Instance.new("TextLabel")
    msgLabel.Size = UDim2.new(1, 0, 0, 18)
    msgLabel.BackgroundTransparency = 1
    msgLabel.Text = timeStr .. "[" .. sender .. "]: " .. text
    msgLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    msgLabel.Font = Enum.Font.Gotham
    msgLabel.TextSize = 12
    msgLabel.TextXAlignment = Enum.TextXAlignment.Left
    msgLabel.TextWrapped = true
    msgLabel.Parent = ChatLogScroll
end

ClearBtn.MouseButton1Click:Connect(function()
    for _, child in ipairs(ChatLogScroll:GetChildren()) do
        if child:IsA("TextLabel") then child:Destroy() end
    end
end)

pcall(function()
    AddConnection(TextChatService.MessageReceived:Connect(function(msg)
        if msg.TextSource then AddChatLog(msg.TextSource.Name, msg.Text) end
    end))
end)

local ChatLogMinState = false
ChatLogMinBtn.MouseButton1Click:Connect(function()
    ChatLogMinState = not ChatLogMinState
    ChatLogScroll.Visible = not ChatLogMinState
    ChatLogGui.Size = ChatLogMinState and UDim2.new(0, 360, 0, 32) or UDim2.new(0, 360, 0, 240)
    ChatLogMinBtn.Text = ChatLogMinState and "+" or "-"
end)

local WaypointsGui = Instance.new("Frame")
WaypointsGui.Name = "ToxWaypointsFrame"
WaypointsGui.Size = UDim2.new(0, 360, 0, 320)
WaypointsGui.Position = UDim2.new(0.5, -180, 0.5, -160)
WaypointsGui.BackgroundColor3 = Color3.fromRGB(10, 10, 16)
WaypointsGui.BorderSizePixel = 0
WaypointsGui.ClipsDescendants = true
WaypointsGui.Visible = false
WaypointsGui.Parent = Gui
getgenv().WaypointsGui = WaypointsGui

local WayCorner = Instance.new("UICorner") WayCorner.CornerRadius = UDim.new(0, 8) WayCorner.Parent = WaypointsGui
local WayStroke = Instance.new("UIStroke") WayStroke.Color = MAIN_COLOR WayStroke.Thickness = 2 WayStroke.Parent = WaypointsGui

local WayTopBar = Instance.new("Frame")
WayTopBar.Size = UDim2.new(1, 0, 0, 32)
WayTopBar.BackgroundColor3 = MAIN_COLOR
WayTopBar.BorderSizePixel = 0
WayTopBar.Parent = WaypointsGui

MakeDraggable(WaypointsGui, WayTopBar)

local WayTitle = Instance.new("TextLabel")
WayTitle.Size = UDim2.new(1, -40, 1, 0)
WayTitle.Position = UDim2.new(0, 10, 0, 0)
WayTitle.BackgroundTransparency = 1
WayTitle.Text = "Tox Waypoints"
WayTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
WayTitle.Font = Enum.Font.GothamBold
WayTitle.TextSize = 13
WayTitle.TextXAlignment = Enum.TextXAlignment.Left
WayTitle.Parent = WayTopBar

local WayCloseBtn = Instance.new("TextButton")
WayCloseBtn.Size = UDim2.new(0, 22, 0, 20)
WayCloseBtn.Position = UDim2.new(1, -26, 0.5, -10)
WayCloseBtn.BackgroundColor3 = Color3.fromRGB(24, 24, 34)
WayCloseBtn.BorderSizePixel = 0
WayCloseBtn.Text = "X"
WayCloseBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
WayCloseBtn.Font = Enum.Font.GothamBold
WayCloseBtn.TextSize = 11
WayCloseBtn.Parent = WayTopBar
local WayCloseCorner = Instance.new("UICorner") WayCloseCorner.CornerRadius = UDim.new(0, 4) WayCloseCorner.Parent = WayCloseBtn

local WayContent = Instance.new("Frame")
WayContent.Size = UDim2.new(1, -16, 1, -40)
WayContent.Position = UDim2.new(0, 8, 0, 36)
WayContent.BackgroundTransparency = 1
WayContent.Parent = WaypointsGui

local function CreateDarkBtn(text, pos, size, parent)
    local b = Instance.new("TextButton")
    b.Size = size
    b.Position = pos
    b.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 10
    b.Parent = parent
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 4) c.Parent = b
    return b
end
getgenv().CreateDarkBtn = CreateDarkBtn

local function CreateWayCoordInput(placeholder, position)
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0.21, 0, 0, 26)
    box.Position = position
    box.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
    box.BorderSizePixel = 0
    box.PlaceholderText = placeholder
    box.Text = ""
    box.TextColor3 = Color3.fromRGB(240, 240, 240)
    box.Font = Enum.Font.Gotham
    box.TextSize = 10
    box.ClearTextOnFocus = false
    box.Parent = WayContent
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = box
    return box
end

local WayInputArea = Instance.new("Frame")
WayInputArea.Size = UDim2.new(1, 0, 0, 26)
WayInputArea.Position = UDim2.new(0, 0, 0, 0)
WayInputArea.BackgroundTransparency = 1
WayInputArea.Parent = WayContent

local WayNameInput = Instance.new("TextBox")
WayNameInput.Size = UDim2.new(0.70, 0, 1, 0)
WayNameInput.Position = UDim2.new(0, 0, 0, 0)
WayNameInput.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
WayNameInput.PlaceholderText = "Waypoint Name"
WayNameInput.Text = ""
WayNameInput.TextColor3 = Color3.fromRGB(240, 240, 240)
WayNameInput.Font = Enum.Font.Gotham
WayNameInput.TextSize = 11
WayNameInput.Parent = WayInputArea
local WayNameCorner = Instance.new("UICorner") WayNameCorner.CornerRadius = UDim.new(0, 4) WayNameCorner.Parent = WayNameInput

local CreateWayBtn = CreateDarkBtn("Current", UDim2.new(0.72, 0, 0, 0), UDim2.new(0.28, 0, 1, 0), WayInputArea)

local WayXInput = CreateWayCoordInput("X", UDim2.new(0, 0, 0, 32))
local WayYInput = CreateWayCoordInput("Y", UDim2.new(0.22, 0, 0, 32))
local WayZInput = CreateWayCoordInput("Z", UDim2.new(0.44, 0, 0, 32))
local CreateCoordsBtn = CreateDarkBtn("Add Coords", UDim2.new(0.67, 0, 0, 32), UDim2.new(0.33, 0, 0, 26), WayContent)
local CopyCurrentCoordsBtn = CreateDarkBtn("Copy Current Coordinates", UDim2.new(0, 0, 0, 64), UDim2.new(1, 0, 0, 24), WayContent)

local WayScroll = Instance.new("ScrollingFrame")
WayScroll.Size = UDim2.new(1, 0, 1, -96)
WayScroll.Position = UDim2.new(0, 0, 0, 94)
WayScroll.BackgroundTransparency = 1
WayScroll.BorderSizePixel = 0
WayScroll.ScrollBarThickness = 3
WayScroll.ScrollBarImageColor3 = MAIN_COLOR
WayScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
WayScroll.Parent = WayContent

local WayLayout = Instance.new("UIListLayout")
WayLayout.SortOrder = Enum.SortOrder.LayoutOrder
WayLayout.Padding = UDim.new(0, 4)
WayLayout.Parent = WayScroll

WayLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    WayScroll.CanvasSize = UDim2.new(0, 0, 0, WayLayout.AbsoluteContentSize.Y + 5)
end)

local function FormatCoordinate(value)
    return string.format("%.3f", tonumber(value) or 0)
end

local function CopyCoordinates(x, y, z)
    local text = FormatCoordinate(x) .. ", " .. FormatCoordinate(y) .. ", " .. FormatCoordinate(z)

    if setclipboard then
        setclipboard(text)
        CustomNotify("Coordinates copied", Color3.fromRGB(100, 255, 100))
    else
        CustomNotify(text, Color3.fromRGB(255, 255, 100), 5)
    end

    return text
end

local function ClearWayInputs()
    WayNameInput.Text = ""
    WayXInput.Text = ""
    WayYInput.Text = ""
    WayZInput.Text = ""
end

local RefreshWaypointsUI

RefreshWaypointsUI = function()
    for _, child in ipairs(WayScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    for idx, wp in ipairs(SavedWaypoints) do
        local item = Instance.new("Frame")
        item.Size = UDim2.new(1, -4, 0, 28)
        item.BackgroundColor3 = Color3.fromRGB(16, 16, 24)
        item.BorderSizePixel = 0
        item.Parent = WayScroll
        local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 4) c.Parent = item

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.42, -4, 1, 0)
        lbl.Position = UDim2.new(0, 6, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = wp.name
        lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 11
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextTruncate = Enum.TextTruncate.AtEnd
        lbl.Parent = item

        local goBtn = CreateDarkBtn("GO", UDim2.new(0.43, 0, 0.5, -9), UDim2.new(0, 28, 0, 18), item)
        goBtn.MouseButton1Click:Connect(function()
            local Root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if Root and wp.x and wp.y and wp.z then
                if getgenv().AllowToxTeleport then getgenv().AllowToxTeleport(1.25) end
                Root.CFrame = CFrame.new(wp.x, wp.y, wp.z)
                CustomNotify("Teleported to " .. wp.name, Color3.fromRGB(100, 255, 100))
            end
        end)

        local upBtn = CreateDarkBtn("Up", UDim2.new(0.43, 31, 0.5, -9), UDim2.new(0, 22, 0, 18), item)
        upBtn.MouseButton1Click:Connect(function()
            if idx > 1 then
                SavedWaypoints[idx], SavedWaypoints[idx - 1] = SavedWaypoints[idx - 1], SavedWaypoints[idx]
                AutoSaveConfiguration()
                RefreshWaypointsUI()
            end
        end)

        local downBtn = CreateDarkBtn("Dn", UDim2.new(0.43, 56, 0.5, -9), UDim2.new(0, 24, 0, 18), item)
        downBtn.MouseButton1Click:Connect(function()
            if idx < #SavedWaypoints then
                SavedWaypoints[idx], SavedWaypoints[idx + 1] = SavedWaypoints[idx + 1], SavedWaypoints[idx]
                AutoSaveConfiguration()
                RefreshWaypointsUI()
            end
        end)

        local copyBtn = CreateDarkBtn("Copy", UDim2.new(0.43, 83, 0.5, -9), UDim2.new(0, 34, 0, 18), item)
        copyBtn.MouseButton1Click:Connect(function()
            CopyCoordinates(wp.x, wp.y, wp.z)
        end)

        local dBtn = CreateDarkBtn("X", UDim2.new(0.43, 120, 0.5, -9), UDim2.new(0, 18, 0, 18), item)
        dBtn.MouseButton1Click:Connect(function()
            table.remove(SavedWaypoints, idx)
            AutoSaveConfiguration()
            RefreshWaypointsUI()
        end)
    end
end

CreateWayBtn.MouseButton1Click:Connect(function()
    local Root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")

    if Root then
        local name = WayNameInput.Text ~= "" and WayNameInput.Text or ("Waypoint " .. (#SavedWaypoints + 1))
        local pos = Root.Position
        table.insert(SavedWaypoints, {name = name, x = pos.X, y = pos.Y, z = pos.Z})
        ClearWayInputs()
        AutoSaveConfiguration()
        RefreshWaypointsUI()
        CustomNotify("Waypoint Created!", Color3.fromRGB(100, 255, 100))
    end
end)

CreateCoordsBtn.MouseButton1Click:Connect(function()
    local x = tonumber(WayXInput.Text)
    local y = tonumber(WayYInput.Text)
    local z = tonumber(WayZInput.Text)

    if not x or not y or not z then
        CustomNotify("Invalid coordinates", Color3.fromRGB(255, 100, 100))
        return
    end

    local name = WayNameInput.Text ~= "" and WayNameInput.Text or ("Waypoint " .. (#SavedWaypoints + 1))
    table.insert(SavedWaypoints, {name = name, x = x, y = y, z = z})
    ClearWayInputs()
    AutoSaveConfiguration()
    RefreshWaypointsUI()
    CustomNotify("Waypoint added by coordinates", Color3.fromRGB(100, 255, 100))
end)

CopyCurrentCoordsBtn.MouseButton1Click:Connect(function()
    local Root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")

    if not Root then
        return
    end

    local pos = Root.Position
    WayXInput.Text = FormatCoordinate(pos.X)
    WayYInput.Text = FormatCoordinate(pos.Y)
    WayZInput.Text = FormatCoordinate(pos.Z)
    CopyCoordinates(pos.X, pos.Y, pos.Z)
end)

WayCloseBtn.MouseButton1Click:Connect(function() WaypointsGui.Visible = false end)
RefreshWaypointsUI()

local MusicGui = Instance.new("Frame")
MusicGui.Name = "ToxMusicPlayerFrame"
MusicGui.Size = UDim2.new(0, 370, 0, 310)
MusicGui.Position = UDim2.new(0.5, -185, 0.5, -155)
MusicGui.BackgroundColor3 = Color3.fromRGB(10, 10, 16)
MusicGui.BorderSizePixel = 0
MusicGui.ClipsDescendants = true
MusicGui.Visible = false
MusicGui.Parent = Gui
getgenv().MusicGui = MusicGui

local MusicCorner = Instance.new("UICorner") MusicCorner.CornerRadius = UDim.new(0, 8) MusicCorner.Parent = MusicGui
local MusicStroke = Instance.new("UIStroke") MusicStroke.Color = MAIN_COLOR MusicStroke.Thickness = 2 MusicStroke.Parent = MusicGui

local MusicTopBar = Instance.new("Frame")
MusicTopBar.Size = UDim2.new(1, 0, 0, 32)
MusicTopBar.BackgroundColor3 = MAIN_COLOR
MusicTopBar.BorderSizePixel = 0
MusicTopBar.Parent = MusicGui

MakeDraggable(MusicGui, MusicTopBar)

local MusicTitle = Instance.new("TextLabel")
MusicTitle.Size = UDim2.new(1, -40, 1, 0)
MusicTitle.Position = UDim2.new(0, 10, 0, 0)
MusicTitle.BackgroundTransparency = 1
MusicTitle.Text = "Tox Music Player"
MusicTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
MusicTitle.Font = Enum.Font.GothamBold
MusicTitle.TextSize = 13
MusicTitle.TextXAlignment = Enum.TextXAlignment.Left
MusicTitle.Parent = MusicTopBar

local MusicCloseBtn = Instance.new("TextButton")
MusicCloseBtn.Size = UDim2.new(0, 22, 0, 20)
MusicCloseBtn.Position = UDim2.new(1, -26, 0.5, -10)
MusicCloseBtn.BackgroundColor3 = Color3.fromRGB(24, 24, 34)
MusicCloseBtn.BorderSizePixel = 0
MusicCloseBtn.Text = "X"
MusicCloseBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
MusicCloseBtn.Font = Enum.Font.GothamBold
MusicCloseBtn.TextSize = 11
MusicCloseBtn.Parent = MusicTopBar
local MusicCloseCorner = Instance.new("UICorner") MusicCloseCorner.CornerRadius = UDim.new(0, 4) MusicCloseCorner.Parent = MusicCloseBtn

local MusicContent = Instance.new("Frame")
MusicContent.Size = UDim2.new(1, -16, 1, -40)
MusicContent.Position = UDim2.new(0, 8, 0, 36)
MusicContent.BackgroundTransparency = 1
MusicContent.Parent = MusicGui

local InputArea = Instance.new("Frame")
InputArea.Size = UDim2.new(1, 0, 0, 26)
InputArea.Position = UDim2.new(0, 0, 0, 0)
InputArea.BackgroundTransparency = 1
InputArea.Parent = MusicContent

local SoundInput = Instance.new("TextBox")
SoundInput.Size = UDim2.new(0.42, 0, 1, 0)
SoundInput.Position = UDim2.new(0, 0, 0, 0)
SoundInput.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
SoundInput.PlaceholderText = "ID"
SoundInput.Text = ""
SoundInput.TextColor3 = Color3.fromRGB(255, 255, 255)
SoundInput.Font = Enum.Font.Gotham
SoundInput.TextSize = 11
SoundInput.Parent = InputArea
local SoundInputCorner = Instance.new("UICorner") SoundInputCorner.CornerRadius = UDim.new(0, 4) SoundInputCorner.Parent = SoundInput

local SongNameInput = Instance.new("TextBox")
SongNameInput.Size = UDim2.new(0.42, 0, 1, 0)
SongNameInput.Position = UDim2.new(0.43, 0, 0, 0)
SongNameInput.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
SongNameInput.PlaceholderText = "Name"
SongNameInput.Text = ""
SongNameInput.TextColor3 = Color3.fromRGB(255, 255, 255)
SongNameInput.Font = Enum.Font.Gotham
SongNameInput.TextSize = 11
SongNameInput.Parent = InputArea
local SongNameCorner = Instance.new("UICorner") SongNameCorner.CornerRadius = UDim.new(0, 4) SongNameCorner.Parent = SongNameInput

local AddPlaylistBtn = CreateDarkBtn("Add", UDim2.new(0.86, 0, 0, 0), UDim2.new(0.14, 0, 1, 0), InputArea)

local ControlsBar = Instance.new("Frame")
ControlsBar.Size = UDim2.new(1, 0, 0, 24)
ControlsBar.Position = UDim2.new(0, 0, 0, 32)
ControlsBar.BackgroundTransparency = 1
ControlsBar.Parent = MusicContent

local PrevBtn = CreateDarkBtn("<<", UDim2.new(0, 0, 0, 0), UDim2.new(0.11, 0, 1, 0), ControlsBar)
local PlayBtn = CreateDarkBtn("Play", UDim2.new(0.12, 0, 0, 0), UDim2.new(0.14, 0, 1, 0), ControlsBar)
local PauseBtn = CreateDarkBtn("Pause", UDim2.new(0.27, 0, 0, 0), UDim2.new(0.14, 0, 1, 0), ControlsBar)
local StopBtn = CreateDarkBtn("Stop", UDim2.new(0.42, 0, 0, 0), UDim2.new(0.13, 0, 1, 0), ControlsBar)
local NextBtn = CreateDarkBtn(">>", UDim2.new(0.56, 0, 0, 0), UDim2.new(0.11, 0, 1, 0), ControlsBar)
local LoopToggleBtn = CreateDarkBtn("Loop", UDim2.new(0.68, 0, 0, 0), UDim2.new(0.15, 0, 1, 0), ControlsBar)
local AutoPlayToggleBtn = CreateDarkBtn("Auto", UDim2.new(0.84, 0, 0, 0), UDim2.new(0.16, 0, 1, 0), ControlsBar)

local VolumeArea = Instance.new("Frame")
VolumeArea.Size = UDim2.new(1, 0, 0, 22)
VolumeArea.Position = UDim2.new(0, 0, 0, 60)
VolumeArea.BackgroundTransparency = 1
VolumeArea.Parent = MusicContent

local VolLabel = Instance.new("TextLabel")
VolLabel.Size = UDim2.new(0.13, 0, 1, 0)
VolLabel.Position = UDim2.new(0, 0, 0, 0)
VolLabel.BackgroundTransparency = 1
VolLabel.Text = "Vol"
VolLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
VolLabel.Font = Enum.Font.GothamBold
VolLabel.TextSize = 10
VolLabel.TextXAlignment = Enum.TextXAlignment.Left
VolLabel.Parent = VolumeArea

local VolInput = Instance.new("TextBox")
VolInput.Size = UDim2.new(0.13, 0, 1, 0)
VolInput.Position = UDim2.new(0.13, 0, 0, 0)
VolInput.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
VolInput.BorderSizePixel = 0
VolInput.Text = tostring(Settings.MusicVolume)
VolInput.PlaceholderText = "0-100"
VolInput.TextColor3 = Color3.fromRGB(255, 255, 255)
VolInput.Font = Enum.Font.Gotham
VolInput.TextSize = 10
VolInput.ClearTextOnFocus = false
VolInput.Parent = VolumeArea
local VolInputCorner = Instance.new("UICorner")
VolInputCorner.CornerRadius = UDim.new(0, 4)
VolInputCorner.Parent = VolInput

local function ApplyMusicVolume(value)
    local number = math.clamp(
        math.floor((tonumber(value) or Settings.MusicVolume or 100) + 0.5),
        0,
        100
    )

    Settings.MusicVolume = number
    VolInput.Text = tostring(number)

    if getgenv().ActiveSound then
        getgenv().ActiveSound.Volume = number / 100
    end

    AutoSaveConfiguration()
end

VolInput.FocusLost:Connect(function()
    ApplyMusicVolume(VolInput.Text)
end)

local VolDownBtn = CreateDarkBtn("-", UDim2.new(0.27, 0, 0, 0), UDim2.new(0.07, 0, 1, 0), VolumeArea)
VolDownBtn.MouseButton1Click:Connect(function()
    ApplyMusicVolume((Settings.MusicVolume or 100) - 1)
end)

local VolUpBtn = CreateDarkBtn("+", UDim2.new(0.35, 0, 0, 0), UDim2.new(0.07, 0, 1, 0), VolumeArea)
VolUpBtn.MouseButton1Click:Connect(function()
    ApplyMusicVolume((Settings.MusicVolume or 100) + 1)
end)

local CheckMusicIDsBtn = CreateDarkBtn("Check IDs", UDim2.new(0.44, 0, 0, 0), UDim2.new(0.27, 0, 1, 0), VolumeArea)
getgenv().CheckMusicIDsBtn = CheckMusicIDsBtn

local MM2RadioBtn = nil
local AdminMusicBtn = nil

if game.PlaceId == 142823291 then
    MM2RadioBtn = CreateDarkBtn("Radio", UDim2.new(0.73, 0, 0, 0), UDim2.new(0.27, 0, 1, 0), VolumeArea)
elseif game.PlaceId == 4522347649 then
    AdminMusicBtn = CreateDarkBtn("Music", UDim2.new(0.73, 0, 0, 0), UDim2.new(0.27, 0, 1, 0), VolumeArea)
end

local PlaylistScroll = Instance.new("ScrollingFrame")
PlaylistScroll.Size = UDim2.new(1, 0, 1, -88)
PlaylistScroll.Position = UDim2.new(0, 0, 0, 86)
PlaylistScroll.BackgroundTransparency = 1
PlaylistScroll.BorderSizePixel = 0
PlaylistScroll.ScrollBarThickness = 3
PlaylistScroll.ScrollBarImageColor3 = MAIN_COLOR
PlaylistScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
PlaylistScroll.Parent = MusicContent

local PlaylistLayout = Instance.new("UIListLayout")
PlaylistLayout.SortOrder = Enum.SortOrder.LayoutOrder
PlaylistLayout.Padding = UDim.new(0, 3)
PlaylistLayout.Parent = PlaylistScroll

PlaylistLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    PlaylistScroll.CanvasSize = UDim2.new(0, 0, 0, PlaylistLayout.AbsoluteContentSize.Y + 5)
end)

getgenv().ActiveSound = nil

local function PlayMusicByID(id, name)
    if getgenv().ActiveSound then getgenv().ActiveSound:Destroy() end
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://" .. tostring(id)
    sound.Volume = Settings.MusicVolume / 100
    sound.Looped = Settings.MusicLoop
    sound.Parent = SoundService
    sound:Play()
    getgenv().ActiveSound = sound
    CustomNotify("Playing: " .. (name or id), Color3.fromRGB(100, 255, 100))

    if Settings.MusicAutoPlay then
        sound.Ended:Connect(function()
            if not Settings.MusicLoop and #SavedIDs > 0 then
                Settings.CurrentTrackIndex = Settings.CurrentTrackIndex + 1
                if Settings.CurrentTrackIndex > #SavedIDs then Settings.CurrentTrackIndex = 1 end
                local track = SavedIDs[Settings.CurrentTrackIndex]
                PlayMusicByID(track.id, track.name)
            end
        end)
    end
end

getgenv().MusicIDLabels = getgenv().MusicIDLabels or {}

getgenv().SetMusicIDStatus = function(id, status)
    local key = tostring(id)
    local label = getgenv().MusicIDLabels[key]

    if label and label.Parent then
        if status == true then
            label.TextColor3 = Color3.fromRGB(70, 255, 100)
        elseif status == false then
            label.TextColor3 = Color3.fromRGB(255, 70, 70)
        elseif status == "checking" then
            label.TextColor3 = Color3.fromRGB(255, 215, 70)
        else
            label.TextColor3 = Color3.fromRGB(200, 200, 220)
        end
    end
end

local RefreshMusicPlaylistUI

RefreshMusicPlaylistUI = function()
    getgenv().MusicIDLabels = {}

    for _, child in ipairs(PlaylistScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    for idx, itemData in ipairs(SavedIDs) do
        local trackName = itemData.name or ("Track " .. idx)
        local trackID = itemData.id

        local item = Instance.new("Frame")
        item.Size = UDim2.new(1, -4, 0, 26)
        item.BackgroundColor3 = Color3.fromRGB(16, 16, 24)
        item.BorderSizePixel = 0
        item.Parent = PlaylistScroll
        local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 4) c.Parent = item

        local idBox = Instance.new("TextLabel")
        idBox.Size = UDim2.new(0.24, -4, 1, 0)
        idBox.Position = UDim2.new(0, 4, 0, 0)
        idBox.BackgroundTransparency = 1
        idBox.Text = tostring(trackID)
        idBox.TextColor3 = Color3.fromRGB(200, 200, 220)
        idBox.Font = Enum.Font.Gotham
        idBox.TextSize = 10
        idBox.TextXAlignment = Enum.TextXAlignment.Left
        idBox.TextTruncate = Enum.TextTruncate.AtEnd
        idBox.Parent = item
        getgenv().MusicIDLabels[tostring(trackID)] = idBox

        if getgenv().MusicIDStatus then
            getgenv().SetMusicIDStatus(trackID, getgenv().MusicIDStatus[tostring(trackID)])
        end

        local nameBox = Instance.new("TextBox")
        nameBox.Size = UDim2.new(0.36, -4, 1, -4)
        nameBox.Position = UDim2.new(0.24, 2, 0, 2)
        nameBox.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
        nameBox.Text = trackName
        nameBox.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameBox.Font = Enum.Font.Gotham
        nameBox.TextSize = 10
        nameBox.ClearTextOnFocus = false
        nameBox.Parent = item
        local nbc = Instance.new("UICorner") nbc.CornerRadius = UDim.new(0, 3) nbc.Parent = nameBox

        nameBox.FocusLost:Connect(function()
            if nameBox.Text ~= "" then
                SavedIDs[idx].name = nameBox.Text
                AutoSaveConfiguration()
            end
        end)

        local pBtn = CreateDarkBtn("Play", UDim2.new(0.61, 0, 0.5, -9), UDim2.new(0, 28, 0, 18), item)
        pBtn.MouseButton1Click:Connect(function()
            Settings.CurrentTrackIndex = idx
            SoundInput.Text = tostring(trackID)
            SongNameInput.Text = nameBox.Text
            PlayMusicByID(trackID, nameBox.Text)
        end)

        local upBtn = CreateDarkBtn("Up", UDim2.new(0.61, 31, 0.5, -9), UDim2.new(0, 22, 0, 18), item)
        upBtn.MouseButton1Click:Connect(function()
            if idx > 1 then
                SavedIDs[idx], SavedIDs[idx - 1] = SavedIDs[idx - 1], SavedIDs[idx]
                AutoSaveConfiguration()
                RefreshMusicPlaylistUI()
            end
        end)

        local downBtn = CreateDarkBtn("Down", UDim2.new(0.61, 56, 0.5, -9), UDim2.new(0, 28, 0, 18), item)
        downBtn.MouseButton1Click:Connect(function()
            if idx < #SavedIDs then
                SavedIDs[idx], SavedIDs[idx + 1] = SavedIDs[idx + 1], SavedIDs[idx]
                AutoSaveConfiguration()
                RefreshMusicPlaylistUI()
            end
        end)

        local copyBtn = CreateDarkBtn("Copy", UDim2.new(0.61, 87, 0.5, -9), UDim2.new(0, 28, 0, 18), item)
        copyBtn.MouseButton1Click:Connect(function()
            if setclipboard then
                setclipboard(tostring(trackID))
                CustomNotify("Copied ID to clipboard", Color3.fromRGB(100, 255, 100))
            end
        end)

        local dBtn = CreateDarkBtn("X", UDim2.new(0.61, 118, 0.5, -9), UDim2.new(0, 18, 0, 18), item)
        dBtn.MouseButton1Click:Connect(function()
            table.remove(SavedIDs, idx)
            AutoSaveConfiguration()
            RefreshMusicPlaylistUI()
        end)
    end
end

getgenv().RefreshMusicPlaylistUI = RefreshMusicPlaylistUI
RefreshMusicPlaylistUI()

PlayBtn.MouseButton1Click:Connect(function()
    local id = tonumber(SoundInput.Text)
    local name = SongNameInput.Text ~= "" and SongNameInput.Text or ("Track " .. id)
    if id then PlayMusicByID(id, name) else CustomNotify("Invalid ID!", Color3.fromRGB(255, 100, 100)) end
end)

if MM2RadioBtn then
    MM2RadioBtn.MouseButton1Click:Connect(function()
        local id = tonumber(SoundInput.Text)

        if not id and SavedIDs[Settings.CurrentTrackIndex] then
            id = tonumber(SavedIDs[Settings.CurrentTrackIndex].id)
            if id then
                SoundInput.Text = tostring(id)
            end
        end

        if not id then
            CustomNotify("Select a song or enter an ID", Color3.fromRGB(255, 180, 70))
            return
        end

        if getgenv().ToxPlayMM2Radio then
            getgenv().ToxPlayMM2Radio(id)
        else
            CustomNotify("MM2 Radio is not ready", Color3.fromRGB(255, 180, 70))
        end
    end)
end

if AdminMusicBtn then
    AdminMusicBtn.MouseButton1Click:Connect(function()
        local id = tonumber(SoundInput.Text)

        if not id and SavedIDs[Settings.CurrentTrackIndex] then
            id = tonumber(SavedIDs[Settings.CurrentTrackIndex].id)

            if id then
                SoundInput.Text = tostring(id)
            end
        end

        if not id then
            CustomNotify("Select a song or enter an ID", Color3.fromRGB(255, 180, 70))
            return
        end

        if getgenv().ToxPlayAdminMusic then
            getgenv().ToxPlayAdminMusic(id)
        else
            CustomNotify("ADMIN Music is not ready", Color3.fromRGB(255, 180, 70))
        end
    end)
end

PauseBtn.MouseButton1Click:Connect(function()
    if getgenv().ActiveSound then
        if getgenv().ActiveSound.IsPlaying then getgenv().ActiveSound:Pause()
        else getgenv().ActiveSound:Resume() end
    end
end)

StopBtn.MouseButton1Click:Connect(function()
    if getgenv().ActiveSound then getgenv().ActiveSound:Stop() getgenv().ActiveSound:Destroy() getgenv().ActiveSound = nil end
end)

PrevBtn.MouseButton1Click:Connect(function()
    if #SavedIDs > 0 then
        Settings.CurrentTrackIndex = Settings.CurrentTrackIndex - 1
        if Settings.CurrentTrackIndex < 1 then Settings.CurrentTrackIndex = #SavedIDs end
        local track = SavedIDs[Settings.CurrentTrackIndex]
        SoundInput.Text = tostring(track.id)
        SongNameInput.Text = track.name
        PlayMusicByID(track.id, track.name)
    end
end)

NextBtn.MouseButton1Click:Connect(function()
    if #SavedIDs > 0 then
        Settings.CurrentTrackIndex = Settings.CurrentTrackIndex + 1
        if Settings.CurrentTrackIndex > #SavedIDs then Settings.CurrentTrackIndex = 1 end
        local track = SavedIDs[Settings.CurrentTrackIndex]
        SoundInput.Text = tostring(track.id)
        SongNameInput.Text = track.name
        PlayMusicByID(track.id, track.name)
    end
end)

LoopToggleBtn.MouseButton1Click:Connect(function()
    Settings.MusicLoop = not Settings.MusicLoop
    LoopToggleBtn.TextColor3 = Settings.MusicLoop and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(220, 220, 220)
    if getgenv().ActiveSound then getgenv().ActiveSound.Looped = Settings.MusicLoop end
    AutoSaveConfiguration()
end)

AutoPlayToggleBtn.MouseButton1Click:Connect(function()
    Settings.MusicAutoPlay = not Settings.MusicAutoPlay
    AutoPlayToggleBtn.TextColor3 = Settings.MusicAutoPlay and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(220, 220, 220)
    AutoSaveConfiguration()
end)

LoopToggleBtn.TextColor3 = Settings.MusicLoop and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(220, 220, 220)
AutoPlayToggleBtn.TextColor3 = Settings.MusicAutoPlay and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(220, 220, 220)

AddPlaylistBtn.MouseButton1Click:Connect(function()
    local id = tonumber(SoundInput.Text)
    local name = SongNameInput.Text ~= "" and SongNameInput.Text or ("Track " .. (id or 0))
    if id then
        table.insert(SavedIDs, {id = id, name = name})
        AutoSaveConfiguration()
        RefreshMusicPlaylistUI()
        CustomNotify("Added to Playlist!", Color3.fromRGB(100, 255, 100))
    else
        CustomNotify("Invalid ID!", Color3.fromRGB(255, 100, 100))
    end
end)

MusicCloseBtn.MouseButton1Click:Connect(function() MusicGui.Visible = false end)

local ToxChatGui = Instance.new("Frame")
ToxChatGui.Name = "ToxChatFrame"
ToxChatGui.Size = UDim2.new(0, 370, 0, 310)
ToxChatGui.Position = UDim2.new(0.5, -185, 0.5, -155)
ToxChatGui.BackgroundColor3 = Color3.fromRGB(10, 10, 16)
ToxChatGui.BorderSizePixel = 0
ToxChatGui.ClipsDescendants = true
ToxChatGui.Visible = false
ToxChatGui.Parent = Gui
getgenv().ToxChatGui = ToxChatGui

local ToxChatCorner = Instance.new("UICorner")
ToxChatCorner.CornerRadius = UDim.new(0, 8)
ToxChatCorner.Parent = ToxChatGui

local ToxChatStroke = Instance.new("UIStroke")
ToxChatStroke.Color = MAIN_COLOR
ToxChatStroke.Thickness = 2
ToxChatStroke.Parent = ToxChatGui

local ToxChatTopBar = Instance.new("Frame")
ToxChatTopBar.Size = UDim2.new(1, 0, 0, 32)
ToxChatTopBar.BackgroundColor3 = MAIN_COLOR
ToxChatTopBar.BorderSizePixel = 0
ToxChatTopBar.Parent = ToxChatGui
getgenv().ToxChatTopBar = ToxChatTopBar

MakeDraggable(ToxChatGui, ToxChatTopBar)

local ToxChatTitle = Instance.new("TextLabel")
ToxChatTitle.Size = UDim2.new(1, -70, 1, 0)
ToxChatTitle.Position = UDim2.new(0, 10, 0, 0)
ToxChatTitle.BackgroundTransparency = 1
ToxChatTitle.Text = "Tox Chat"
ToxChatTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
ToxChatTitle.Font = Enum.Font.GothamBold
ToxChatTitle.TextSize = 13
ToxChatTitle.TextXAlignment = Enum.TextXAlignment.Left
ToxChatTitle.Parent = ToxChatTopBar

local ToxChatCloseBtn = Instance.new("TextButton")
ToxChatCloseBtn.Size = UDim2.new(0, 22, 0, 20)
ToxChatCloseBtn.Position = UDim2.new(1, -26, 0.5, -10)
ToxChatCloseBtn.BackgroundColor3 = Color3.fromRGB(24, 24, 34)
ToxChatCloseBtn.BorderSizePixel = 0
ToxChatCloseBtn.Text = "X"
ToxChatCloseBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
ToxChatCloseBtn.Font = Enum.Font.GothamBold
ToxChatCloseBtn.TextSize = 11
ToxChatCloseBtn.Parent = ToxChatTopBar

local ToxChatCloseCorner = Instance.new("UICorner")
ToxChatCloseCorner.CornerRadius = UDim.new(0, 4)
ToxChatCloseCorner.Parent = ToxChatCloseBtn

local ToxChatStatus = Instance.new("TextLabel")
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

local ToxChatScroll = Instance.new("ScrollingFrame")
ToxChatScroll.Size = UDim2.new(1, -16, 1, -110)
ToxChatScroll.Position = UDim2.new(0, 8, 0, 60)
ToxChatScroll.BackgroundTransparency = 1
ToxChatScroll.BorderSizePixel = 0
ToxChatScroll.ScrollBarThickness = 4
ToxChatScroll.ScrollBarImageColor3 = MAIN_COLOR
ToxChatScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
ToxChatScroll.Parent = ToxChatGui
getgenv().ToxChatScroll = ToxChatScroll

local ToxChatLayout = Instance.new("UIListLayout")
ToxChatLayout.Padding = UDim.new(0, 5)
ToxChatLayout.SortOrder = Enum.SortOrder.LayoutOrder
ToxChatLayout.Parent = ToxChatScroll

ToxChatLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ToxChatScroll.CanvasSize = UDim2.new(0, 0, 0, ToxChatLayout.AbsoluteContentSize.Y + 8)
    ToxChatScroll.CanvasPosition = Vector2.new(0, math.max(0, ToxChatLayout.AbsoluteContentSize.Y))
end)

local ToxChatInput = Instance.new("TextBox")
ToxChatInput.Size = UDim2.new(1, -88, 0, 32)
ToxChatInput.Position = UDim2.new(0, 8, 1, -40)
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

local ToxChatInputCorner = Instance.new("UICorner")
ToxChatInputCorner.CornerRadius = UDim.new(0, 4)
ToxChatInputCorner.Parent = ToxChatInput

local ToxChatSendBtn = Instance.new("TextButton")
ToxChatSendBtn.Size = UDim2.new(0, 68, 0, 32)
ToxChatSendBtn.Position = UDim2.new(1, -76, 1, -40)
ToxChatSendBtn.BackgroundColor3 = MAIN_COLOR
ToxChatSendBtn.BorderSizePixel = 0
ToxChatSendBtn.Text = "Send"
ToxChatSendBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToxChatSendBtn.Font = Enum.Font.GothamBold
ToxChatSendBtn.TextSize = 12
ToxChatSendBtn.Parent = ToxChatGui
getgenv().ToxChatSendBtn = ToxChatSendBtn

local ToxChatSendCorner = Instance.new("UICorner")
ToxChatSendCorner.CornerRadius = UDim.new(0, 4)
ToxChatSendCorner.Parent = ToxChatSendBtn

getgenv().AddToxChatMessage = function(displayName, message, blocked)
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
end

getgenv().ClearToxChatMessages = function()
    for _, child in ipairs(ToxChatScroll:GetChildren()) do
        if child:IsA("TextLabel") then
            child:Destroy()
        end
    end
end

ToxChatCloseBtn.MouseButton1Click:Connect(function()
    ToxChatGui.Visible = false
end)

local JoinGamesGui = Instance.new("Frame")
JoinGamesGui.Name = "ToxQuickJoinFrame"
JoinGamesGui.Size = UDim2.new(0, 460, 0, 310)
JoinGamesGui.Position = UDim2.new(0.5, -230, 0.5, -155)
JoinGamesGui.BackgroundColor3 = Color3.fromRGB(10, 10, 16)
JoinGamesGui.BorderSizePixel = 0
JoinGamesGui.ClipsDescendants = true
JoinGamesGui.Visible = false
JoinGamesGui.Parent = Gui
getgenv().JoinGamesGui = JoinGamesGui

local JoinGamesCorner = Instance.new("UICorner")
JoinGamesCorner.CornerRadius = UDim.new(0, 8)
JoinGamesCorner.Parent = JoinGamesGui

local JoinGamesStroke = Instance.new("UIStroke")
JoinGamesStroke.Color = MAIN_COLOR
JoinGamesStroke.Thickness = 2
JoinGamesStroke.Parent = JoinGamesGui

local JoinGamesTopBar = Instance.new("Frame")
JoinGamesTopBar.Size = UDim2.new(1, 0, 0, 32)
JoinGamesTopBar.BackgroundColor3 = MAIN_COLOR
JoinGamesTopBar.BorderSizePixel = 0
JoinGamesTopBar.Parent = JoinGamesGui

MakeDraggable(JoinGamesGui, JoinGamesTopBar)

local JoinGamesTitle = Instance.new("TextLabel")
JoinGamesTitle.Size = UDim2.new(1, -70, 1, 0)
JoinGamesTitle.Position = UDim2.new(0, 10, 0, 0)
JoinGamesTitle.BackgroundTransparency = 1
JoinGamesTitle.Text = "Quick Games"
JoinGamesTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
JoinGamesTitle.Font = Enum.Font.GothamBold
JoinGamesTitle.TextSize = 13
JoinGamesTitle.TextXAlignment = Enum.TextXAlignment.Left
JoinGamesTitle.Parent = JoinGamesTopBar

local JoinGamesCloseBtn = Instance.new("TextButton")
JoinGamesCloseBtn.Size = UDim2.new(0, 22, 0, 20)
JoinGamesCloseBtn.Position = UDim2.new(1, -26, 0.5, -10)
JoinGamesCloseBtn.BackgroundColor3 = Color3.fromRGB(24, 24, 34)
JoinGamesCloseBtn.BorderSizePixel = 0
JoinGamesCloseBtn.Text = "X"
JoinGamesCloseBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
JoinGamesCloseBtn.Font = Enum.Font.GothamBold
JoinGamesCloseBtn.TextSize = 11
JoinGamesCloseBtn.Parent = JoinGamesTopBar

local JoinGamesCloseCorner = Instance.new("UICorner")
JoinGamesCloseCorner.CornerRadius = UDim.new(0, 4)
JoinGamesCloseCorner.Parent = JoinGamesCloseBtn

local JoinGameAddArea = Instance.new("Frame")
JoinGameAddArea.Size = UDim2.new(1, -16, 0, 32)
JoinGameAddArea.Position = UDim2.new(0, 8, 0, 39)
JoinGameAddArea.BackgroundTransparency = 1
JoinGameAddArea.Parent = JoinGamesGui

local JoinGameIdBox = Instance.new("TextBox")
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

local JoinGameIdCorner = Instance.new("UICorner")
JoinGameIdCorner.CornerRadius = UDim.new(0, 4)
JoinGameIdCorner.Parent = JoinGameIdBox

local JoinGameAddButton = Instance.new("TextButton")
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

local JoinGameAddCorner = Instance.new("UICorner")
JoinGameAddCorner.CornerRadius = UDim.new(0, 4)
JoinGameAddCorner.Parent = JoinGameAddButton

local JoinGamesScroll = Instance.new("ScrollingFrame")
JoinGamesScroll.Size = UDim2.new(1, -16, 1, -84)
JoinGamesScroll.Position = UDim2.new(0, 8, 0, 78)
JoinGamesScroll.BackgroundTransparency = 1
JoinGamesScroll.BorderSizePixel = 0
JoinGamesScroll.ScrollBarThickness = 3
JoinGamesScroll.ScrollBarImageColor3 = MAIN_COLOR
JoinGamesScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
JoinGamesScroll.Parent = JoinGamesGui
getgenv().JoinGamesScroll = JoinGamesScroll

local JoinGamesLayout = Instance.new("UIListLayout")
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
ApplySavedGuiPosition("ChatLog", ChatLogGui)
ApplySavedGuiPosition("Waypoints", WaypointsGui)
ApplySavedGuiPosition("Music", MusicGui)
ApplySavedGuiPosition("ToxChat", ToxChatGui)
ApplySavedGuiPosition("QuickJoin", JoinGamesGui)

TrackGuiPosition("Main", Main)
TrackGuiPosition("ChatLog", ChatLogGui)
TrackGuiPosition("Waypoints", WaypointsGui)
TrackGuiPosition("Music", MusicGui)
TrackGuiPosition("ToxChat", ToxChatGui)
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

local function RegisterSharedToggle(Key, Controller)
    if not Key or not Controller then return end

    if not getgenv().SharedToggleControls[Key] then
        getgenv().SharedToggleControls[Key] = {}
    end

    table.insert(getgenv().SharedToggleControls[Key], Controller)
end

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

local function RegisterSharedValue(Key, Controller)
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

    local Enabled = DefaultValue or false

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

    Button.MouseButton1Click:Connect(function()
        if Destroyed then return end

        Enabled = not Enabled
        Update()
        Callback(Enabled)

        if SyncKey and getgenv().SyncToggleVisuals then
            getgenv().SyncToggleVisuals(SyncKey, Enabled)
        end

        if ScriptLoaded then
            CustomNotify(Name .. (Enabled and " Enabled" or " Disabled"), Enabled and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100))
        end

        AutoSaveConfiguration()
    end)

    Update()
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

    local Enabled = DefaultToggle or false

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

    ToggleButton.MouseButton1Click:Connect(function()
        if Destroyed then return end

        Enabled = not Enabled
        UpdateToggle()
        CallbackToggle(Enabled)

        if SyncKey and getgenv().SyncToggleVisuals then
            getgenv().SyncToggleVisuals(SyncKey, Enabled)
        end

        if ScriptLoaded then
            CustomNotify(Name .. (Enabled and " Enabled" or " Disabled"), Enabled and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100))
        end

        AutoSaveConfiguration()
    end)

    Input.FocusLost:Connect(function()
        if Destroyed then return end

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
		if Destroyed then return end
		Callback(Input.Text)
	end)

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
		if Destroyed then return end
		Callback(Input.Text, "TP")
	end)

    Button2.MouseButton1Click:Connect(function()
		if Destroyed then return end
		Callback(Input.Text, "LOOP")
	end)

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
		if Destroyed then return end
		CurrentIdx = CurrentIdx + 1
		if CurrentIdx > #Options then CurrentIdx = 1 end
		Button.Text = Options[CurrentIdx]
		Callback(Options[CurrentIdx])
        AutoSaveConfiguration()
	end)

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
		if Destroyed then return end
		Callback(Button)
	end)

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
        if Destroyed then return end
        if not Confirming then
            Confirming = true
            Button.Text = "CONFIRM " .. string.upper(Name) .. "? (Click Again)"
            Button.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
            task.delay(3.5, function()
                if not Destroyed and Confirming then
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
        if Binding then return end
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
    AutoLabel.Text = "AUTO"
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
    local Enabled = DefaultToggle == true

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

    KeyButton.MouseButton1Click:Connect(function()
        if Destroyed or Binding then return end

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
        if Destroyed then return end

        Enabled = not Enabled
        UpdateToggle()
        ToggleCallback(Enabled)

        if SyncKey and getgenv().SyncToggleVisuals then
            getgenv().SyncToggleVisuals(SyncKey, Enabled)
        end

        AutoSaveConfiguration()

        if ScriptLoaded then
            CustomNotify(
                Name .. " Auto " .. (Enabled and "Enabled" or "Disabled"),
                Enabled
                    and Color3.fromRGB(100, 255, 100)
                    or Color3.fromRGB(255, 100, 100)
            )
        end
    end)

    UpdateToggle()
    return Box
end

