if game.PlaceId ~= 142823291 then
    return
end

local env = getgenv()
local loaderVersion = "2026-09-18-mm2-ui-restored-1"
local coreUrl = tostring(
    env.ToxMM2CoreURL
    or "https://raw.githubusercontent.com/BG-0o/Scripts/refs/heads/main/ModuleMM2.lua"
)

local function AddCacheBuster(url)
    local separator = string.find(url, "?", 1, true) and "&" or "?"
    return url
        .. separator
        .. "toxcache="
        .. tostring(os.time())
        .. "_"
        .. tostring(math.random(1000, 999999))
end

local function Notify(text, color, duration)
    if type(env.CustomNotify) == "function" then
        pcall(env.CustomNotify, text, color, duration)
    end
end

if env.ToxMM2LoaderJobId == game.JobId
and env.ToxMM2LoaderVersion == loaderVersion
and env.ToxMM2LoaderPage == env.GamePage
and env.ToxMM2CoreReady == true
and env.Destroyed ~= true then
    return
end

local fetchOk, source = pcall(function()
    return game:HttpGet(AddCacheBuster(coreUrl))
end)

if not fetchOk or type(source) ~= "string" or source == "" then
    Notify("MM2 core download failed", Color3.fromRGB(255, 100, 100), 6)
    error("[ToxHub MM2 Loader Download Error]: " .. tostring(source))
end

local chunk, compileError = loadstring(source)

if not chunk then
    Notify("MM2 core compile failed", Color3.fromRGB(255, 100, 100), 7)
    error("[ToxHub MM2 Loader Compile Error]: " .. tostring(compileError))
end

local runOk, runError = pcall(chunk)

if not runOk then
    Notify("MM2 core runtime failed", Color3.fromRGB(255, 100, 100), 7)
    error("[ToxHub MM2 Loader Runtime Error]: " .. tostring(runError))
end

if env.ToxMM2CoreReady ~= true then
    Notify("MM2 core did not initialize", Color3.fromRGB(255, 100, 100), 7)
    error("[ToxHub MM2 Loader Error]: core did not initialize")
end

-- MM2 UI layer restored after ModuleMM2 core initializes.
local function CreateMM2Section(
    text
)
    local label =
        Instance.new(
            "TextLabel"
        )

    label.Size =
        UDim2.new(
            1,
            -5,
            0,
            26
        )

    label.BackgroundColor3 =
        Color3.fromRGB(
            13,
            13,
            21
        )

    label.BorderSizePixel = 0
    label.Text =
        "  "
        .. tostring(
            text
        )

    label.TextColor3 =
        Color3.fromRGB(
            255,
            255,
            255
        )

    label.Font =
        Enum.Font.GothamBold

    label.TextSize = 11
    label.TextXAlignment =
        Enum.TextXAlignment.Left

    label.Parent =
        GamePage

    local corner =
        Instance.new("UICorner")

    corner.CornerRadius =
        UDim.new(
            0,
            5
        )

    corner.Parent =
        label

    return label
end

local AutoFarmHighSpeedWarningShown = false

local function WarnAutoFarmSpeed(
    speed
)
    speed =
        tonumber(speed)
        or 5

    if speed > 10
    and not AutoFarmHighSpeedWarningShown then
        AutoFarmHighSpeedWarningShown =
            true

        CustomNotify(
            "WARNING: Auto Farm speed above 10 may cause a kick or ban.",
            Color3.fromRGB(
                255,
                170,
                60
            ),
            7
        )
    elseif speed <= 10 then
        AutoFarmHighSpeedWarningShown =
            false
    end
end

CreateMM2Section(
    "FARM"
)

CreateToggleWithValue("Auto Farm", GamePage, Settings.MM2AutoFarmV2, Settings.MM2AutoFarmSpeed, function(v)
    if v then
        Settings.MM2AutoFarmV2 = true
        ResetAutoFarmFullPause()
        AutoFarmBagKnown = false
        AutoFarmBagCoins = 0
        RefreshFarmBagState()

        WarnAutoFarmSpeed(
            Settings.MM2AutoFarmSpeed
        )
    else
        Settings.MM2AutoFarmV2 = false
        ResetAutoFarmFullPause()
        StopAutoFarm(true)

        local character = Player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local root = character and character:FindFirstChild("HumanoidRootPart")

        if humanoid and humanoid.Health > 0 then
            humanoid.PlatformStand = false
            humanoid.Sit = false
            humanoid.AutoRotate = true
        end

        if root then
            root.Anchored = false
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end

        EnableLocalControls()
    end

    AutoSaveConfiguration()
end, function(value)
    Settings.MM2AutoFarmSpeed =
        math.clamp(
            tonumber(value)
            or 5,
            5,
            250
        )

    WarnAutoFarmSpeed(
        Settings.MM2AutoFarmSpeed
    )

    AutoSaveConfiguration()
end, "MM2AutoFarmV2")

CreateToggle(
    "Reset On Full",
    GamePage,
    Settings.MM2AutoFarmResetOnFull,
    function(v)
        Settings.MM2AutoFarmResetOnFull =
            v == true

        if not Settings.MM2AutoFarmResetOnFull then
            AutoFarmResetTriggered = false
        end

        AutoSaveConfiguration()
    end,
    "MM2AutoFarmResetOnFull"
)

CreateMM2Section(
    "PLAYER"
)

CreateToggle("Role ESP", GamePage, Settings.MM2RoleESP, function(v)
    ApplyRoleESP(v)
end, "MM2RoleESP")

CreateToggle(
    "Gun ESP",
    GamePage,
    Settings.MM2GunESP,
    function(v)
        Settings.MM2GunESP =
            v == true

        if Settings.MM2GunESP then
            local gunDrop =
                FindGunDrop()

            if gunDrop then
                CreateGunESP(
                    gunDrop
                )
            end
        else
            ClearGunESP()
        end

        AutoSaveConfiguration()
    end,
    "MM2GunESP"
)

CreateToggleWithValue("Speed", GamePage, Settings.Speed, Settings.SpeedValue, function(v)
    SetShared("Speed", v)
end, function(value)
    Settings.SpeedValue = math.clamp(tonumber(value) or 16, 1, 250)

    if SyncValueVisuals then
        SyncValueVisuals("Speed", Settings.SpeedValue)
    end
end, "Speed")

CreateToggle("Noclip", GamePage, Settings.Noclip, function(v)
    SetShared("Noclip", v)
end, "Noclip")

CreateToggle("Anti Fling", GamePage, Settings.AntiFling, function(v)
    SetShared("AntiFling", v)
end, "AntiFling")

CreateMM2Section(
    "COMBAT"
)

MM2AutoRuntime = {
    KillAll = Settings.MM2KillAllAutoV2 == true,
    Shoot = Settings.MM2ShootMurderAutoV2 == true,
    GrabGun = Settings.MM2GrabGunAutoV2 == true
}

CreateKeybindButton("Silent Aim", GamePage, Settings.MM2SilentAimKey, function(key)
    Settings.MM2SilentAimKey = key
end)

CreateKeybindToggle("Kill All", GamePage, Settings.MM2KillAllKey, MM2AutoRuntime.KillAll, function(key)
    Settings.MM2KillAllKey = key
end, function(enabled)
    MM2AutoRuntime.KillAll = enabled == true
    Settings.MM2KillAllAutoV2 = MM2AutoRuntime.KillAll
end, "MM2KillAllAutoV2")

CreateKeybindToggle("Shoot Murderer", GamePage, Settings.MM2ShootMurderKey, MM2AutoRuntime.Shoot, function(key)
    Settings.MM2ShootMurderKey = key
end, function(enabled)
    MM2AutoRuntime.Shoot = enabled == true
    Settings.MM2ShootMurderAutoV2 = MM2AutoRuntime.Shoot

    if not MM2AutoRuntime.Shoot then
        ShootSafetySerial = ShootSafetySerial + 1
    end
end, "MM2ShootMurderAutoV2")

CreateKeybindToggle("Grab Gun", GamePage, Settings.MM2GrabGunKey, MM2AutoRuntime.GrabGun, function(key)
    Settings.MM2GrabGunKey = key
end, function(enabled)
    MM2AutoRuntime.GrabGun = enabled == true
    Settings.MM2GrabGunAutoV2 = MM2AutoRuntime.GrabGun
end, "MM2GrabGunAutoV2")

CreateMM2Section(
    "TARGETING"
)

CreateDropdown("Fling Target", {"Murderer", "Sheriff"}, GamePage, Settings.MM2FlingTarget, function(value)
    Settings.MM2FlingTarget = value
    AutoSaveConfiguration()
end)

CreateButton("Fling", GamePage, FlingSelectedRole)

CreateButton("Knife Targets", GamePage, function()
    OpenPlayerSelector("targets")
end)

CreateButton("Whitelist", GamePage, function()
    OpenPlayerSelector("whitelist")
end)

local function GetMM2ActiveMapRoot()
    local normal =
        workspace:
            FindFirstChild(
                "Normal"
            )

    if normal then
        return normal
    end

    local best = nil
    local bestCount = 0

    for _, candidate in ipairs(
        workspace:
            GetChildren()
    ) do
        if candidate:IsA(
            "Model"
        )
        and not Players:
            GetPlayerFromCharacter(
                candidate
            ) then
            local lower =
                string.lower(
                    candidate.Name
                )

            if not string.find(
                lower,
                "lobby",
                1,
                true
            ) then
                local count = 0

                for _, object in ipairs(
                    candidate:
                        GetDescendants()
                ) do
                    if object:IsA(
                        "BasePart"
                    ) then
                        count += 1
                    end
                end

                if count > bestCount then
                    best = candidate
                    bestCount = count
                end
            end
        end
    end

    return best
end

local function GetPartTopCFrame(
    part
)
    if not part
    or not part:IsA(
        "BasePart"
    ) then
        return nil
    end

    return
        CFrame.new(
            part.Position
            + Vector3.new(
                0,
                part.Size.Y * 0.5
                    + 4,
                0
            )
        )
end

local function FindNamedSpawnIn(
    root
)
    if not root then
        return nil
    end

    local preferred = nil

    for _, object in ipairs(
        root:
            GetDescendants()
    ) do
        if object:IsA(
            "SpawnLocation"
        ) then
            return
                GetPartTopCFrame(
                    object
                )
        end

        if object:IsA(
            "BasePart"
        ) then
            local lower =
                string.lower(
                    object.Name
                )

            if string.find(
                lower,
                "spawn",
                1,
                true
            )
            or string.find(
                lower,
                "start",
                1,
                true
            ) then
                preferred =
                    preferred
                    or object
            end
        end
    end

    return
        GetPartTopCFrame(
            preferred
        )
end

local function GetRootBounds(
    root
)
    if not root then
        return nil
    end

    if root:IsA(
        "Model"
    ) then
        local ok,
            cframe,
            size =
            pcall(function()
                return
                    root:
                        GetBoundingBox()
            end)

        if ok then
            return
                cframe,
                size
        end
    end

    local minimum = nil
    local maximum = nil

    for _, object in ipairs(
        root:
            GetDescendants()
    ) do
        if object:IsA(
            "BasePart"
        ) then
            local half =
                object.Size * 0.5

            local low =
                object.Position
                - half

            local high =
                object.Position
                + half

            minimum =
                minimum
                and Vector3.new(
                    math.min(
                        minimum.X,
                        low.X
                    ),
                    math.min(
                        minimum.Y,
                        low.Y
                    ),
                    math.min(
                        minimum.Z,
                        low.Z
                    )
                )
                or low

            maximum =
                maximum
                and Vector3.new(
                    math.max(
                        maximum.X,
                        high.X
                    ),
                    math.max(
                        maximum.Y,
                        high.Y
                    ),
                    math.max(
                        maximum.Z,
                        high.Z
                    )
                )
                or high
        end
    end

    if minimum
    and maximum then
        local size =
            maximum
            - minimum

        local center =
            minimum
            + size * 0.5

        return
            CFrame.new(
                center
            ),
            size
    end

    return nil
end

local function GetSafeMapCFrame()
    local mapRoot =
        GetMM2ActiveMapRoot()

    if not mapRoot then
        return nil
    end

    local named =
        FindNamedSpawnIn(
            mapRoot
        )

    if named then
        return named
    end

    local bounds,
        size =
        GetRootBounds(
            mapRoot
        )

    if not bounds
    or not size then
        return nil
    end

    local params =
        RaycastParams.new()

    params.FilterType =
        Enum.RaycastFilterType.Include

    params.FilterDescendantsInstances = {
        mapRoot
    }

    local origin =
        bounds.Position
        + Vector3.new(
            0,
            size.Y * 0.5
                + 150,
            0
        )

    local result =
        workspace:
            Raycast(
                origin,
                Vector3.new(
                    0,
                    -(size.Y + 500),
                    0
                ),
                params
            )

    if result then
        return
            CFrame.new(
                result.Position
                + Vector3.new(
                    0,
                    4,
                    0
                )
            )
    end

    local bestPart = nil
    local bestScore = math.huge

    for _, object in ipairs(
        mapRoot:
            GetDescendants()
    ) do
        if object:IsA(
            "BasePart"
        )
        and object.CanCollide
        and object.Transparency < 0.95
        and object.Size.X >= 4
        and object.Size.Z >= 4 then
            local flatDistance =
                Vector2.new(
                    object.Position.X
                        - bounds.Position.X,
                    object.Position.Z
                        - bounds.Position.Z
                ).Magnitude

            local score =
                flatDistance
                - object.Size.X * 0.15
                - object.Size.Z * 0.15

            if score < bestScore then
                bestScore = score
                bestPart = object
            end
        end
    end

    return
        GetPartTopCFrame(
            bestPart
        )
end

local function GetLobbySpawnCFrame()
    local mapRoot =
        GetMM2ActiveMapRoot()

    local lobby =
        workspace:
            FindFirstChild(
                "Lobby"
            )

    if lobby then
        local named =
            FindNamedSpawnIn(
                lobby
            )

        if named then
            return named
        end
    end

    for _, object in ipairs(
        workspace:
            GetDescendants()
    ) do
        if object:IsA(
            "SpawnLocation"
        )
        and (
            not mapRoot
            or not object:
                IsDescendantOf(
                    mapRoot
                )
        ) then
            return
                GetPartTopCFrame(
                    object
                )
        end
    end

    if lobby then
        local bounds,
            size =
            GetRootBounds(
                lobby
            )

        if bounds
        and size then
            local params =
                RaycastParams.new()

            params.FilterType =
                Enum.RaycastFilterType.Include

            params.FilterDescendantsInstances = {
                lobby
            }

            local result =
                workspace:
                    Raycast(
                        bounds.Position
                        + Vector3.new(
                            0,
                            size.Y * 0.5
                                + 100,
                            0
                        ),
                        Vector3.new(
                            0,
                            -(size.Y + 300),
                            0
                        ),
                        params
                    )

            if result then
                return
                    CFrame.new(
                        result.Position
                        + Vector3.new(
                            0,
                            4,
                            0
                        )
                    )
            end
        end
    end

    return nil
end

local function TeleportMM2To(
    cframe,
    label
)
    if typeof(cframe)
        ~= "CFrame" then
        CustomNotify(
            label
            .. " location unavailable",
            Color3.fromRGB(
                255,
                180,
                70
            )
        )

        return
    end

    local character =
        Player.Character

    local humanoid =
        character
        and character:
            FindFirstChildOfClass(
                "Humanoid"
            )

    local root =
        character
        and character:
            FindFirstChild(
                "HumanoidRootPart"
            )

    if not root
    or not humanoid
    or humanoid.Health <= 0 then
        return
    end

    if getgenv().AllowToxTeleport then
        getgenv().AllowToxTeleport(
            1.5
        )
    end

    root.AssemblyLinearVelocity =
        Vector3.zero

    root.AssemblyAngularVelocity =
        Vector3.zero

    root.CFrame =
        cframe

    CustomNotify(
        "Teleported to "
        .. label,
        Color3.fromRGB(
            100,
            255,
            130
        )
    )
end

CreateMM2Section(
    "TELEPORTS"
)

CreateButton(
    "SPAWN",
    GamePage,
    function()
        TeleportMM2To(
            GetLobbySpawnCFrame(),
            "SPAWN"
        )
    end
)

CreateButton(
    "MAP",
    GamePage,
    function()
        TeleportMM2To(
            GetSafeMapCFrame(),
            "MAP"
        )
    end
)


local AutoKnifeLastAttempt = 0
local AutoShootLastAttempt = 0
local AutoGrabAttemptedDrops = setmetatable({}, {__mode = "k"})

task.spawn(function()
    while not getgenv().Destroyed and game.PlaceId == 142823291 do
        local knife = FindNamedTool({"knife"})
        local gun = FindNamedTool({"gun", "revolver"})
        local character = Player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local alive = humanoid and humanoid.Health > 0
        local localRole = alive and GetRole(Player) or nil

        if MM2AutoRuntime.KillAll
        and not Settings.MM2AutoFarmV2
        and knife
        and alive
        and not ActionBusy
        and knife.Enabled ~= false
        and os.clock() - AutoKnifeLastAttempt
            >= 0.05 then
            AutoKnifeLastAttempt =
                os.clock()

            task.spawn(
                KillAll
            )
        end

        if MM2AutoRuntime.Shoot
        and Settings.MM2ShootMurderAutoV2
        and not Settings.MM2AutoFarmV2
        and gun
        and alive
        and not ActionBusy
        and not GuidedShotBusy
        and gun.Enabled ~= false then
            local murderer =
                GetPlayerByRole(
                    "Murderer"
                )

            local murderHumanoid =
                murderer
                and murderer.Character
                and murderer.Character:
                    FindFirstChildOfClass(
                        "Humanoid"
                    )

            if murderer
            and murderHumanoid
            and murderHumanoid.Health > 0
            and os.clock() - AutoShootLastAttempt
                >= 0.04 then
                AutoShootLastAttempt =
                    os.clock()

                task.spawn(function()
                    ShootMurderer(
                        false
                    )
                end)
            end
        end

        if MM2AutoRuntime.GrabGun
        and Settings.MM2GrabGunAutoV2
        and not Settings.MM2AutoFarmV2
        and alive
        and localRole == "Innocent"
        and not gun
        and not ActionBusy then
            local drop = FindGunDrop()

            if drop and not AutoGrabAttemptedDrops[drop] then
                AutoGrabAttemptedDrops[drop] = true
                task.spawn(function()
                    GrabGun(true, drop)
                end)
            end
        end

        task.wait(0.1)
    end
end)


local LastManualShootInput = 0

AddConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed
    or UserInputService:GetFocusedTextBox()
    or input.UserInputType ~= Enum.UserInputType.Keyboard
    or getgenv().Destroyed then
        return
    end

    if Settings.MM2SilentAimKey
    and input.KeyCode == Settings.MM2SilentAimKey then
        task.defer(function()
            if not getgenv().Destroyed then
                SilentAimShot()
            end
        end)

        return
    end

    if Settings.MM2KillAllKey and input.KeyCode == Settings.MM2KillAllKey then
        KillAll()
        return
    end

    if Settings.MM2ShootMurderKey and input.KeyCode == Settings.MM2ShootMurderKey then
        if os.clock() - LastManualShootInput < 0.08 then
            return
        end

        LastManualShootInput = os.clock()

        MM2AutoRuntime.Shoot = false
        Settings.MM2ShootMurderAuto = false
        Settings.MM2ShootMurderAutoV2 = false
        ShootSafetySerial = ShootSafetySerial + 1

        if SyncToggleVisuals then
            SyncToggleVisuals("MM2ShootMurderAutoV2", false)
        end

        AutoSaveConfiguration()

        task.defer(function()
            if not getgenv().Destroyed then
                ShootMurderer(true)
            end
        end)

        return
    end

    if Settings.MM2GrabGunKey and input.KeyCode == Settings.MM2GrabGunKey then
        GrabGun()
    end
end))


getgenv().ToxMM2Cleanup = function()
    getgenv().ToxMM2ModuleLoadedJobId = nil
    Settings.MM2AutoFarm = false
    Settings.MM2AutoFarmV2 = false
    Settings.MM2RoleESP = false
    Settings.MM2KillAllAuto = false
    Settings.MM2KillAllAutoV2 = false
    Settings.MM2ShootMurderAuto = false
    Settings.MM2ShootMurderAutoV2 = false
    Settings.MM2GrabGunAuto = false
    Settings.MM2GrabGunAutoV2 = false

    MM2AutoRuntime.KillAll = false
    MM2AutoRuntime.Shoot = false
    MM2AutoRuntime.GrabGun = false
    ShootSafetySerial = ShootSafetySerial + 1
    GuidedShotBusy = false
    SilentAimBusy = false
    ActionBusy = false
    AutoShootLastAttempt = 0
    table.clear(KnifeTargetIds)

    if Camera then
        pcall(function()
            Camera.CameraType = Enum.CameraType.Custom

            local character = Player.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")

            if humanoid then
                Camera.CameraSubject = humanoid
            end
        end)
    end

    local cleanupCharacter = Player.Character
    local cleanupHumanoid = cleanupCharacter and cleanupCharacter:FindFirstChildOfClass("Humanoid")
    local cleanupRoot = cleanupCharacter and cleanupCharacter:FindFirstChild("HumanoidRootPart")

    if cleanupHumanoid then
        cleanupHumanoid.PlatformStand = false
        cleanupHumanoid.Sit = false
        cleanupHumanoid.AutoRotate = true
    end

    if cleanupRoot then
        cleanupRoot.Anchored = false
        cleanupRoot.AssemblyLinearVelocity = Vector3.zero
        cleanupRoot.AssemblyAngularVelocity = Vector3.zero
    end

    table.clear(KnifeTargetIds)

    if AutoFarmPrepared then
        StopAutoFarm(true)
    end

    ClearGunESP()

    if PlayerSelectorFrame then
        PlayerSelectorFrame.Visible = false
    end

    if getgenv().ToxLinkedSubGuis then
        getgenv().ToxLinkedSubGuis.MM2PlayerSelector = nil
    end

    if getgenv().SyncToggleVisuals then
        getgenv().SyncToggleVisuals("MM2AutoFarmV2", false)
        getgenv().SyncToggleVisuals("MM2RoleESP", false)
        getgenv().SyncToggleVisuals("MM2GunESP", Settings.MM2GunESP)
        getgenv().SyncToggleVisuals("MM2KillAllAutoV2", false)
        getgenv().SyncToggleVisuals("MM2ShootMurderAutoV2", false)
        getgenv().SyncToggleVisuals("MM2GrabGunAutoV2", false)
    end
end

if Settings.MM2RoleESP then
    ApplyRoleESP(
        true
    )
end

getgenv().ToxMM2ModuleLoadedJobId =
    game.JobId

getgenv().ToxMM2ModuleVersion =
    MM2ModuleVersion

getgenv().ToxMM2ModulePage =
    GamePage


env.ToxMM2LoaderJobId = game.JobId
env.ToxMM2LoaderVersion = loaderVersion
env.ToxMM2LoaderPage = env.GamePage
