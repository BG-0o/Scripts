if game.PlaceId ~= 142823291 then
    return
end

MM2ModuleVersion =
    "2026-09-13-mm2-split-loader-config-fix"

local Settings = getgenv().Settings
local GamePage = getgenv().GamePage
local CustomNotify = getgenv().CustomNotify or function() end

if getgenv().ToxMM2ModuleLoadedJobId
    == game.JobId
and getgenv().ToxMM2ModuleVersion
    == MM2ModuleVersion
and getgenv().ToxMM2ModulePage
    == GamePage
and not getgenv().Destroyed then
    return
end

getgenv().ToxMM2CoreReady = false
getgenv().ToxMM2CoreVersion = nil

local function AddMM2CacheBuster(url)
    url = tostring(url or "")

    if url == "" then
        return url
    end

    local separator = string.find(url, "?", 1, true) and "&" or "?"

    return url
        .. separator
        .. "toxv="
        .. MM2ModuleVersion
        .. "_"
        .. tostring(os.time())
        .. "_"
        .. tostring(math.random(1000, 999999))
end

local coreUrls = {}

if getgenv().ToxMM2CoreURL then
    table.insert(coreUrls, tostring(getgenv().ToxMM2CoreURL))
end

table.insert(coreUrls, "https://raw.githubusercontent.com/BG-0o/Scripts/refs/heads/main/ModuleMM2")
table.insert(coreUrls, "https://raw.githubusercontent.com/BG-0o/Scripts/refs/heads/main/ModuleMM2.lua")

local coreFunction = nil
local coreLoadError = nil
local loadedCoreUrl = nil

for _, url in ipairs(coreUrls) do
    local requestUrl = AddMM2CacheBuster(url)

    local coreOk, coreResult = pcall(function()
        return game:HttpGet(requestUrl)
    end)

    if coreOk
    and type(coreResult) == "string"
    and coreResult ~= "" then
        local compiled, compileError = loadstring(coreResult)

        if compiled then
            coreFunction = compiled
            loadedCoreUrl = url
            break
        else
            coreLoadError = compileError
        end
    else
        coreLoadError = coreResult
    end
end

if not coreFunction then
    CustomNotify(
        "MM2 core failed to compile/download",
        Color3.fromRGB(255, 90, 90),
        6
    )
    warn("[ToxHub MM2 Core Load Error]: " .. tostring(coreLoadError))
    return
end

local coreRunOk, coreRunError = pcall(coreFunction)

if not coreRunOk
or getgenv().ToxMM2CoreReady ~= true
or getgenv().ToxMM2CoreVersion ~= MM2ModuleVersion then
    CustomNotify(
        "MM2 core failed to load",
        Color3.fromRGB(255, 90, 90),
        6
    )
    warn("[ToxHub MM2 Core Error]: " .. tostring(coreRunError) .. " | " .. tostring(loadedCoreUrl))
    return
end

MM2CurrentSection = nil
MM2Sections = {}

function ApplyMM2SectionState(section)
    if typeof(section) ~= "table" then
        return
    end

    Settings.MM2CollapsedSections =
        typeof(Settings.MM2CollapsedSections) == "table"
        and Settings.MM2CollapsedSections
        or {}

    local collapsed =
        Settings.MM2CollapsedSections[section.Key] == true

    if section.Header
    and section.Header.Parent then
        section.Header.Text =
            collapsed
            and "  > " .. section.Name
            or "  v " .. section.Name
    end

    for _, object in ipairs(section.Controls) do
        if object
        and object.Parent
        and object:IsA("GuiObject") then
            object.Visible = not collapsed
        end
    end
end

function TrackMM2Control(object)
    if MM2CurrentSection
    and object
    and object:IsA("GuiObject") then
        table.insert(
            MM2CurrentSection.Controls,
            object
        )

        ApplyMM2SectionState(
            MM2CurrentSection
        )
    end

    return object
end

function MM2CreateToggle(...)
    return TrackMM2Control(
        CreateToggle(...)
    )
end

function MM2CreateToggleWithValue(...)
    return TrackMM2Control(
        CreateToggleWithValue(...)
    )
end

function MM2CreateButton(...)
    return TrackMM2Control(
        CreateButton(...)
    )
end

function MM2CreateDropdown(...)
    return TrackMM2Control(
        CreateDropdown(...)
    )
end

function MM2CreateKeybindToggle(...)
    return TrackMM2Control(
        CreateKeybindToggle(...)
    )
end

function CreateMM2Section(
    text
)
    Settings.MM2CollapsedSections =
        typeof(Settings.MM2CollapsedSections) == "table"
        and Settings.MM2CollapsedSections
        or {}

    local name =
        tostring(
            text
        )

    local key =
        string.gsub(
            name,
            "%s+",
            ""
        )

    local button =
        Instance.new(
            "TextButton"
        )

    button.Size =
        UDim2.new(
            1,
            -5,
            0,
            26
        )

    button.BackgroundColor3 =
        Color3.fromRGB(
            13,
            13,
            21
        )

    button.BorderSizePixel = 0
    button.TextColor3 =
        Color3.fromRGB(
            255,
            255,
            255
        )

    button.Font =
        Enum.Font.GothamBold

    button.TextSize = 11
    button.TextXAlignment =
        Enum.TextXAlignment.Left

    button.AutoButtonColor = false
    button.Parent =
        GamePage

    local corner =
        Instance.new("UICorner")

    corner.CornerRadius =
        UDim.new(
            0,
            5
        )

    corner.Parent =
        button

    local section = {
        Name = name,
        Key = key,
        Header = button,
        Controls = {}
    }

    table.insert(
        MM2Sections,
        section
    )

    MM2CurrentSection =
        section

    button.MouseButton1Click:Connect(function()
        Settings.MM2CollapsedSections[key] =
            not Settings.MM2CollapsedSections[key]

        ApplyMM2SectionState(
            section
        )

        AutoSaveConfiguration()
    end)

    ApplyMM2SectionState(
        section
    )

    return button
end

AutoFarmHighSpeedWarningShown = false

function WarnAutoFarmSpeed(
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

MM2CreateToggleWithValue("Auto Farm", GamePage, Settings.MM2AutoFarmV2, Settings.MM2AutoFarmSpeed, function(v)
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
            1,
            250
        )

    WarnAutoFarmSpeed(
        Settings.MM2AutoFarmSpeed
    )

    AutoSaveConfiguration()
end, "MM2AutoFarmV2")

MM2CreateToggle(
    "Auto Win",
    GamePage,
    Settings.MM2AutoWin,
    function(v)
        Settings.MM2AutoWin =
            v == true

        if not Settings.MM2AutoWin then
            getgenv().ToxMM2AutoWinGeneration = (getgenv().ToxMM2AutoWinGeneration or 0) + 1
            getgenv().ToxMM2AutoWinBusy = false
        end

        AutoSaveConfiguration()
    end,
    "MM2AutoWin"
)

MM2CreateToggle(
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

MM2CreateToggle("Role ESP", GamePage, Settings.MM2RoleESP, function(v)
    ApplyRoleESP(v)
end, "MM2RoleESP")

MM2CreateToggle(
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

MM2CreateToggleWithValue("Speed", GamePage, Settings.Speed, Settings.SpeedValue, function(v)
    SetShared("Speed", v)
end, function(value)
    Settings.SpeedValue = math.clamp(tonumber(value) or 16, 1, 250)

    if SyncValueVisuals then
        SyncValueVisuals("Speed", Settings.SpeedValue)
    end
end, "Speed")

MM2CreateToggle("Noclip", GamePage, Settings.Noclip, function(v)
    SetShared("Noclip", v)
end, "Noclip")

MM2CreateToggle("Walk Fling", GamePage, Settings.WalkFling, function(v)
    SetShared("WalkFling", v)
end, "WalkFling")

MM2CreateToggle("Anti Fling", GamePage, Settings.AntiFling, function(v)
    SetShared("AntiFling", v)
end, "AntiFling")

CreateMM2Section(
    "COMBAT"
)

MM2AutoRuntime = {
    SilentAim = Settings.MM2SilentAimAutoV2 == true,
    KillAll = Settings.MM2KillAllAutoV2 == true,
    Shoot = Settings.MM2ShootMurderAutoV2 == true,
    GrabGun = Settings.MM2GrabGunAutoV2 == true
}

local function SyncMM2AutoRuntimeFromSettings(syncVisual)
    if not MM2AutoRuntime then
        return
    end

    Settings.MM2SilentAimAuto = false
    Settings.MM2KillAllAuto = false
    Settings.MM2ShootMurderAuto = false
    Settings.MM2GrabGunAuto = false
    Settings.MM2SilentAimAutoV2 = Settings.MM2SilentAimAutoV2 == true
    Settings.MM2KillAllAutoV2 = Settings.MM2KillAllAutoV2 == true
    Settings.MM2ShootMurderAutoV2 = Settings.MM2ShootMurderAutoV2 == true
    Settings.MM2GrabGunAutoV2 = Settings.MM2GrabGunAutoV2 == true
    MM2AutoRuntime.SilentAim = Settings.MM2SilentAimAutoV2
    MM2AutoRuntime.KillAll = Settings.MM2KillAllAutoV2
    MM2AutoRuntime.Shoot = Settings.MM2ShootMurderAutoV2
    MM2AutoRuntime.GrabGun = Settings.MM2GrabGunAutoV2

    if syncVisual
    and SyncToggleVisuals then
        SyncToggleVisuals("MM2SilentAimAutoV2", MM2AutoRuntime.SilentAim)
        SyncToggleVisuals("MM2KillAllAutoV2", MM2AutoRuntime.KillAll)
        SyncToggleVisuals("MM2ShootMurderAutoV2", MM2AutoRuntime.Shoot)
        SyncToggleVisuals("MM2GrabGunAutoV2", MM2AutoRuntime.GrabGun)
    end
end

SyncMM2AutoRuntimeFromSettings(true)

MM2CreateKeybindToggle("Silent Aim", GamePage, Settings.MM2SilentAimKey, MM2AutoRuntime.SilentAim, function(key)
    Settings.MM2SilentAimKey = key
end, function(enabled)
    MM2AutoRuntime.SilentAim = enabled == true
    Settings.MM2SilentAimAutoV2 = MM2AutoRuntime.SilentAim

    if not MM2AutoRuntime.SilentAim then
        SilentAimBusy = false
    end

    AutoSaveConfiguration()
end, "MM2SilentAimAutoV2")

MM2CreateKeybindToggle("Kill All", GamePage, Settings.MM2KillAllKey, MM2AutoRuntime.KillAll, function(key)
    Settings.MM2KillAllKey = key
end, function(enabled)
    MM2AutoRuntime.KillAll = enabled == true
    Settings.MM2KillAllAutoV2 = MM2AutoRuntime.KillAll
    AutoSaveConfiguration()
end, "MM2KillAllAutoV2")

MM2CreateKeybindToggle("Shoot Murderer", GamePage, Settings.MM2ShootMurderKey, MM2AutoRuntime.Shoot, function(key)
    Settings.MM2ShootMurderKey = key
end, function(enabled)
    if enabled then
        AutoShootGeneration = AutoShootGeneration + 1
        MM2AutoRuntime.Shoot = true
        Settings.MM2ShootMurderAutoV2 = true
        Settings.MM2ShootMurderAuto = false
        AutoShootLastAttempt = 0
        AutoSaveConfiguration()
    else
        CancelAutoShootMurderer(false)
    end
end, "MM2ShootMurderAutoV2")

MM2CreateKeybindToggle("Grab Gun", GamePage, Settings.MM2GrabGunKey, MM2AutoRuntime.GrabGun, function(key)
    Settings.MM2GrabGunKey = key
end, function(enabled)
    MM2AutoRuntime.GrabGun = enabled == true
    Settings.MM2GrabGunAutoV2 = MM2AutoRuntime.GrabGun
    AutoSaveConfiguration()
end, "MM2GrabGunAutoV2")

CreateMM2Section(
    "TARGETING"
)

MM2CreateDropdown("Fling Target", {"Murderer", "Sheriff"}, GamePage, Settings.MM2FlingTarget, function(value)
    Settings.MM2FlingTarget = value
    AutoSaveConfiguration()
end)

MM2CreateButton("Fling", GamePage, FlingSelectedRole)

MM2CreateButton("Target", GamePage, function()
    OpenPlayerSelector("targets")
end)

MM2CreateButton("TP Target", GamePage, function()
    local targets = GetSelectedKnifeTargets()
    local target = targets[1]

    if not target then
        CustomNotify("Select a target first", Color3.fromRGB(255, 180, 70))
        return
    end

    if not TeleportToTarget(target) then
        CustomNotify("Target TP failed", Color3.fromRGB(255, 100, 100))
    end
end)

function GetMM2ActiveMapRoot()
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

function GetPartTopCFrame(
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

function FindNamedSpawnIn(
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

function GetRootBounds(
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

function GetSafeMapCFrame()
    local mapRoot = GetMM2ActiveMapRoot()

    if not mapRoot then
        return nil
    end

    local named = FindNamedSpawnIn(mapRoot)

    if named then
        return named
    end

    local bounds, size = GetRootBounds(mapRoot)

    if not bounds or not size then
        return nil
    end

    local bestPart = nil
    local bestScore = math.huge
    local targetFloorY = bounds.Position.Y - size.Y * 0.30

    for _, object in ipairs(mapRoot:GetDescendants()) do
        if object:IsA("BasePart")
        and object.CanCollide
        and object.Transparency < 0.95
        and object.Size.X >= 5
        and object.Size.Z >= 5 then
            local lower = string.lower(object.Name)
            local topY = object.Position.Y + object.Size.Y * 0.5
            local flatDistance = Vector2.new(
                object.Position.X - bounds.Position.X,
                object.Position.Z - bounds.Position.Z
            ).Magnitude

            local score = flatDistance + math.abs(topY - targetFloorY) * 1.75

            if object.Size.X >= 12 or object.Size.Z >= 12 then
                score -= 25
            end

            if string.find(lower, "floor", 1, true)
            or string.find(lower, "ground", 1, true)
            or string.find(lower, "base", 1, true)
            or string.find(lower, "spawn", 1, true) then
                score -= 45
            end

            if string.find(lower, "roof", 1, true)
            or string.find(lower, "ceiling", 1, true)
            or string.find(lower, "wall", 1, true)
            or string.find(lower, "tree", 1, true)
            or string.find(lower, "decor", 1, true) then
                score += 120
            end

            if score < bestScore then
                bestScore = score
                bestPart = object
            end
        end
    end

    if bestPart then
        return CFrame.new(
            bestPart.Position.X,
            bestPart.Position.Y + bestPart.Size.Y * 0.5 + 4,
            bestPart.Position.Z
        )
    end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = {mapRoot}

    local result = workspace:Raycast(
        bounds.Position + Vector3.new(0, size.Y * 0.5 + 150, 0),
        Vector3.new(0, -(size.Y + 500), 0),
        params
    )

    if result then
        return CFrame.new(result.Position + Vector3.new(0, 4, 0))
    end

    return nil
end

function GetLobbySpawnCFrame()
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

function TeleportMM2To(
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

    if getgenv().RecordToxTeleportReturn then
        getgenv().RecordToxTeleportReturn()
    end

    if getgenv().AllowToxTeleport then
        getgenv().AllowToxTeleport(
            1.5,
            "MM2 " .. tostring(label or "TP")
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

MM2CreateButton(
    "SPAWN",
    GamePage,
    function()
        TeleportMM2To(
            GetLobbySpawnCFrame(),
            "SPAWN"
        )
    end
)

MM2CreateButton(
    "MAP",
    GamePage,
    function()
        TeleportMM2To(
            GetSafeMapCFrame(),
            "MAP"
        )
    end
)

local MM2LastRoleNoticeKey = nil

local function GetMM2RoleNoticeMapKey()
    local mapRoot = GetMM2ActiveMapRoot()

    if not mapRoot then
        return nil
    end

    local count = 0
    local sample = {}

    for _, object in ipairs(mapRoot:GetDescendants()) do
        if object:IsA("BasePart") then
            count += 1

            if #sample < 8 then
                table.insert(sample, object.Name)
            end
        end
    end

    return mapRoot.Name .. "|" .. tostring(count) .. "|" .. table.concat(sample, ",")
end

local function NotifyMM2LocalRole(role, mapKey)
    return
end


AutoKnifeLastAttempt = 0
AutoSilentAimLastAttempt = 0
AutoShootLastAttempt = 0
AutoGrabAttemptedDrops = setmetatable({}, {__mode = "k"})

task.spawn(function()
    while not getgenv().Destroyed and game.PlaceId == 142823291 do
        if not ToxScriptReady() then
            task.wait(0.1)
            continue
        end

        local knife = FindNamedTool({"knife"})
        local gun = FindNamedTool({"gun", "revolver"})
        local character = Player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local alive = humanoid and humanoid.Health > 0
        local localRole = alive and GetRole(Player) or nil

        SyncMM2AutoRuntimeFromSettings(false)

        if MM2AutoRuntime.KillAll
        and Settings.MM2KillAllAutoV2
        and not Settings.MM2AutoFarmV2
        and knife
        and alive
        and not KillAllBusy
        and os.clock() - AutoKnifeLastAttempt >= 0.03 then
            AutoKnifeLastAttempt = os.clock()

            task.spawn(function()
                KillAll(true)
            end)
        end

        if MM2AutoRuntime.Shoot
        and Settings.MM2ShootMurderAutoV2
        and not Settings.MM2AutoFarmV2
        and alive
        and not GuidedShotBusy
        and os.clock() - AutoShootLastAttempt >= 0.03 then
            local murderer = FindGuidedMurderer()
            local murderHumanoid = murderer
                and murderer.Character
                and murderer.Character:FindFirstChildOfClass("Humanoid")

            if murderer
            and murderHumanoid
            and murderHumanoid.Health > 0 then
                AutoShootLastAttempt = os.clock()

                local shootGeneration = AutoShootGeneration

                task.spawn(function()
                    if MM2AutoRuntime.Shoot
                    and Settings.MM2ShootMurderAutoV2
                    and shootGeneration == AutoShootGeneration
                    and not getgenv().Destroyed then
                        ShootMurderer(false)
                    end
                end)
            end
        end

        if MM2AutoRuntime.GrabGun
        and Settings.MM2GrabGunAutoV2
        and not Settings.MM2AutoFarmV2
        and alive
        and localRole ~= "Murderer"
        and localRole ~= "Sheriff"
        and not IsSheriffAlive()
        and not gun
        and not GrabGunBusy then
            local drop = FindGunDrop()

            if drop then
                local lastAttempt = AutoGrabAttemptedDrops[drop]

                if not lastAttempt or os.clock() - lastAttempt >= 0.08 then
                    AutoGrabAttemptedDrops[drop] = os.clock()
                    task.spawn(function()
                        GrabGun(true, drop)
                    end)
                end
            end
        end

        task.wait(0.05)
    end
end)


LastManualSilentAimInput = 0
LastManualShootInput = 0

AddConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed
    or UserInputService:GetFocusedTextBox()
    or input.UserInputType ~= Enum.UserInputType.Keyboard
    or getgenv().Destroyed
    or not ToxScriptReady() then
        return
    end

    if Settings.MM2SilentAimKey
    and input.KeyCode == Settings.MM2SilentAimKey then
        if not MM2AutoRuntime.SilentAim
        and not Settings.MM2SilentAimAutoV2 then
            return
        end

        if os.clock() - LastManualSilentAimInput < 0.05 then
            return
        end

        LastManualSilentAimInput = os.clock()

        task.defer(function()
            if not getgenv().Destroyed
            and MM2AutoRuntime.SilentAim
            and Settings.MM2SilentAimAutoV2 then
                SilentAimShot()
            end
        end)

        return
    end

    if Settings.MM2KillAllKey and input.KeyCode == Settings.MM2KillAllKey then
        KillAll(false)
        return
    end

    if Settings.MM2ShootMurderKey and input.KeyCode == Settings.MM2ShootMurderKey then
        if os.clock() - LastManualShootInput < 0.05 then
            return
        end

        LastManualShootInput = os.clock()

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
    local preservedMM2Settings = {
        MM2AutoFarm = Settings.MM2AutoFarm,
        MM2AutoFarmV2 = Settings.MM2AutoFarmV2,
        MM2AutoWin = Settings.MM2AutoWin,
        MM2RoleESP = Settings.MM2RoleESP,
        MM2SilentAimAuto = Settings.MM2SilentAimAuto,
        MM2SilentAimAutoV2 = Settings.MM2SilentAimAutoV2,
        MM2KillAllAuto = Settings.MM2KillAllAuto,
        MM2KillAllAutoV2 = Settings.MM2KillAllAutoV2,
        MM2ShootMurderAuto = Settings.MM2ShootMurderAuto,
        MM2ShootMurderAutoV2 = Settings.MM2ShootMurderAutoV2,
        MM2GrabGunAuto = Settings.MM2GrabGunAuto,
        MM2GrabGunAutoV2 = Settings.MM2GrabGunAutoV2
    }

    getgenv().ToxMM2ModuleLoadedJobId = nil
    Settings.MM2AutoFarm = false
    Settings.MM2AutoFarmV2 = false
    Settings.MM2AutoWin = false
    Settings.MM2RoleESP = false
    Settings.MM2SilentAimAuto = false
    Settings.MM2SilentAimAutoV2 = false
    Settings.MM2KillAllAuto = false
    Settings.MM2KillAllAutoV2 = false
    Settings.MM2ShootMurderAuto = false
    Settings.MM2ShootMurderAutoV2 = false
    Settings.MM2GrabGunAuto = false
    Settings.MM2GrabGunAutoV2 = false

    MM2AutoRuntime.SilentAim = false
    MM2AutoRuntime.KillAll = false
    MM2AutoRuntime.Shoot = false
    MM2AutoRuntime.GrabGun = false
    getgenv().ToxMM2AutoWinGeneration = (getgenv().ToxMM2AutoWinGeneration or 0) + 1
    getgenv().ToxMM2AutoWinBusy = false
    ShootSafetySerial = ShootSafetySerial + 1
    GuidedShotBusy = false
    SilentAimBusy = false
    KillAllBusy = false
    GrabGunBusy = false
    ActionBusy = false
    AutoSilentAimLastAttempt = 0
    AutoShootLastAttempt = 0
    ClearToxTable(KnifeTargetIds)

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

    ClearToxTable(KnifeTargetIds)

    if AutoFarmPrepared then
        StopAutoFarm(true)
    end

    ClearGunESP()

    if PlayerSelectorFrame then
        PlayerSelectorFrame.Visible = false
    end

    if RoundTimerFrame then
        RoundTimerFrame:Destroy()
        RoundTimerFrame = nil
        RoundTimerLabel = nil
    end

    if getgenv().ToxLinkedSubGuis then
        getgenv().ToxLinkedSubGuis.MM2PlayerSelector = nil
    end

    if getgenv().SyncToggleVisuals then
        getgenv().SyncToggleVisuals("MM2AutoFarmV2", false)
        getgenv().SyncToggleVisuals("MM2AutoWin", false)
        getgenv().SyncToggleVisuals("MM2RoleESP", false)
        getgenv().SyncToggleVisuals("MM2GunESP", Settings.MM2GunESP)
        getgenv().SyncToggleVisuals("MM2SilentAimAutoV2", false)
        getgenv().SyncToggleVisuals("MM2KillAllAutoV2", false)
        getgenv().SyncToggleVisuals("MM2ShootMurderAutoV2", false)
        getgenv().SyncToggleVisuals("MM2GrabGunAutoV2", false)
    end

    for key, value in pairs(preservedMM2Settings) do
        Settings[key] = value
    end
end

local function ApplyMM2SavedOptionsAfterLoad()
    if getgenv().Destroyed
    or not ToxScriptReady() then
        return
    end

    SyncMM2AutoRuntimeFromSettings(true)

    if Settings.MM2RoleESP then
        pcall(function()
            ApplyRoleESP(
                true
            )
        end)
    end

end

task.spawn(function()
    while not getgenv().Destroyed
    and not ToxScriptReady() do
        task.wait(0.05)
    end

    ApplyMM2SavedOptionsAfterLoad()
end)

getgenv().ToxMM2ModuleLoadedJobId =
    game.JobId

getgenv().ToxMM2ModuleVersion =
    MM2ModuleVersion

getgenv().ToxMM2ModulePage =
    GamePage
