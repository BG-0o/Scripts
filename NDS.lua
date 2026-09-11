local NDSPlaceId = 189707

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

    return
end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Settings = getgenv().Settings
local GamePage = getgenv().GamePage

local function ToxScriptReady()
    return getgenv().ScriptLoaded == true
    or ScriptLoaded == true
end
local CreateToggle = getgenv().CreateToggle
local CreateToggleWithValue = getgenv().CreateToggleWithValue
local CreateButton = getgenv().CreateButton
local AddConnection = getgenv().AddConnection
local CustomNotify = getgenv().CustomNotify
local AutoSaveConfiguration = getgenv().AutoSaveConfiguration
local SyncToggleVisuals = getgenv().SyncToggleVisuals
local SyncValueVisuals = getgenv().SyncValueVisuals

if not Settings
or not GamePage
or not CreateToggle
or not CreateToggleWithValue
or not CreateButton then
    return
end

local NDSModuleVersion =
    "2026-09-11-autowin-spawn-1"

if getgenv().ToxNDSModuleLoadedJobId
    == game.JobId
and getgenv().ToxNDSModuleVersion
    == NDSModuleVersion
and getgenv().ToxNDSModulePage
    == GamePage
and not getgenv().Destroyed then
    return
end

if getgenv().ToxNDSCleanup then
    pcall(
        getgenv().ToxNDSCleanup
    )
end

for _, child in ipairs(
    GamePage:
        GetChildren()
) do
    if child:IsA(
        "GuiObject"
    ) then
        child:
            Destroy()
    end
end

local configuredWaterFlySpeed = tonumber(Settings.NDSWaterFlySpeed)

if not configuredWaterFlySpeed or configuredWaterFlySpeed == 12 then
    configuredWaterFlySpeed = 40
end

Settings.NDSWaterFlySpeed = math.clamp(
    configuredWaterFlySpeed,
    5,
    250
)

Settings.NDSDisasterDetector = Settings.NDSDisasterDetector == true
Settings.NDSCollapsedSections =
    typeof(Settings.NDSCollapsedSections) == "table"
    and Settings.NDSCollapsedSections
    or {}

local AutoWinConnection = nil
local AutoWinLastActivate = 0
local AutoWinLastEquip = 0
local AutoWinTool = nil
local AutoWinToolName = nil
local AutoWinPreviousNoclip = nil
local AutoWinInitialEquipDone = false
local AutoWinCFrame = CFrame.new(-279.846, 166.742, 341.409)

local WaterFlyConnection = nil
local WaterFlyOldGravity = nil
local WaterFlyHumanoid = nil
local WaterFlyStateDefaults = {}

local NoFallGeneration = 0

local DisasterConnection = nil
local LastDisasterNotified = nil
local LastDisasterNotifyTime = 0
local LastDisasterScanTime = 0

local NoTPConnection = nil
local NoTPCharacterConnection = nil
local NoTPCorrectionConnection = nil
local NoTPAnchorCFrame = nil
local NoTPLastObservedCFrame = nil
local NoTPCorrectionCFrame = nil
local NoTPCorrectionUntil = 0
local NoTPCurrentCharacter = nil

local SpawnCFrame = CFrame.new(-278.442841, 179.499985, 344.097626)
local IslandCFrame = CFrame.new(-133.347427, 47.399998, 4.539609)

getgenv().NDSSafeSpawnCFrame = SpawnCFrame

local function GetCharacterState()
    local character = Player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    return character, humanoid, root
end

local function AllowToxTeleport(seconds, reason)
    if getgenv().AllowToxTeleport then
        getgenv().AllowToxTeleport(seconds or 1, reason or "NDS")
    end
end

local function SetShared(Key, Value)
    if getgenv().ToxSetSharedOption then
        getgenv().ToxSetSharedOption(Key, Value)
    else
        local settingKey = ({
            Noclip = "Noclip",
            NoFallDamage = "NoFallDamage",
            AntiVoid = "AntiVoid",
            AntiFling = "AntiFling",
            WalkFling = "WalkFling",
            CtrlClickTP = "CtrlClickTP",
            CarFly = "CarFly",
            SmoothFly = "SmoothFly",
            NormalFly = "NormalFly"
        })[Key]

        if settingKey then
            Settings[settingKey] = Value == true
        end

        if SyncToggleVisuals then
            SyncToggleVisuals(Key, Value == true)
        end
    end
end

local function TeleportTo(cframe, name)
    local _, humanoid, root = GetCharacterState()

    if not humanoid or humanoid.Health <= 0 or not root then
        CustomNotify("Character unavailable", Color3.fromRGB(255, 100, 100))
        return
    end

    if getgenv().RecordToxTeleportReturn then
        getgenv().RecordToxTeleportReturn()
    end

    AllowToxTeleport(1.5, "NDS " .. tostring(name or "TP"))
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    root.CFrame = cframe

    if Settings.NDSNoTP then
        NoTPAnchorCFrame = cframe
        NoTPLastObservedCFrame = cframe
    end

    CustomNotify("Teleported to " .. name, Color3.fromRGB(100, 255, 100))
end

local function PressHotbarTwo()
    pcall(function()
        VirtualInputManager:SendKeyEvent(
            true,
            Enum.KeyCode.Two,
            false,
            game
        )

        task.wait(0.04)

        VirtualInputManager:SendKeyEvent(
            false,
            Enum.KeyCode.Two,
            false,
            game
        )
    end)
end

local function EquipAndGetHotbarTwo()
    local character, humanoid = GetCharacterState()

    if not character
    or not humanoid
    or humanoid.Health <= 0 then
        return nil
    end

    local equipped = character:FindFirstChildOfClass("Tool")

    if equipped then
        return equipped
    end

    if AutoWinInitialEquipDone then
        return nil
    end

    AutoWinInitialEquipDone = true
    PressHotbarTwo()
    task.wait(0.08)

    return character:FindFirstChildOfClass("Tool")
end

local FindAppleByName

FindAppleByName = function()
    local character = Player.Character
    local backpack = Player:FindFirstChildOfClass("Backpack")

    for _, container in ipairs({character, backpack}) do
        if container then
            for _, child in ipairs(container:GetChildren()) do
                if child:IsA("Tool") then
                    local lowerName = string.lower(child.Name)

                    if string.find(lowerName, "apple", 1, true)
                    or string.find(lowerName, "maca", 1, true)
                    or string.find(lowerName, "maç", 1, true) then
                        return child
                    end
                end
            end
        end
    end

    return nil
end

local function FindAutoWinTool()
    local character = Player.Character
    local backpack = Player:FindFirstChildOfClass("Backpack")

    if AutoWinTool
    and AutoWinTool.Parent
    and AutoWinTool:IsA("Tool") then
        return AutoWinTool
    end

    local equipped = character
        and character:FindFirstChildOfClass("Tool")

    if equipped then
        AutoWinTool = equipped
        AutoWinToolName = equipped.Name
        return equipped
    end

    local hotbarTwo = EquipAndGetHotbarTwo()

    if hotbarTwo then
        AutoWinTool = hotbarTwo
        AutoWinToolName = hotbarTwo.Name
        return hotbarTwo
    end

    if AutoWinToolName then
        local cached =
            (character and character:FindFirstChild(AutoWinToolName))
            or (backpack and backpack:FindFirstChild(AutoWinToolName))

        if cached and cached:IsA("Tool") then
            AutoWinTool = cached
            return cached
        end
    end

    return nil
end

local function ClickAutoWinTool(tool)
    local character, humanoid = GetCharacterState()

    if not character
    or not humanoid
    or humanoid.Health <= 0 then
        return false
    end

    local equipped =
        character:FindFirstChildOfClass("Tool")

    if equipped then
        tool = equipped
        AutoWinTool = equipped
        AutoWinToolName = equipped.Name
    else
        return false
    end

    if not tool
    or not tool.Parent then
        return false
    end

    pcall(function()
        tool:Activate()
    end)

    pcall(function()
        local camera = workspace.CurrentCamera
        local x = camera
            and camera.ViewportSize.X * 0.5
            or 400
        local y = camera
            and camera.ViewportSize.Y * 0.5
            or 300

        VirtualInputManager:SendMouseButtonEvent(
            x,
            y,
            0,
            true,
            game,
            0
        )

        task.wait(0.035)

        VirtualInputManager:SendMouseButtonEvent(
            x,
            y,
            0,
            false,
            game,
            0
        )
    end)

    task.wait(0.025)

    pcall(function()
        tool:Activate()
    end)

    return true
end

local function StopAutoWin(returnToSpawn)
    if AutoWinConnection then
        AutoWinConnection:Disconnect()
        AutoWinConnection = nil
    end

    if returnToSpawn then
        local _, humanoid, root = GetCharacterState()

        if humanoid
        and humanoid.Health > 0
        and root then
            AllowToxTeleport(1.5, "NDS Auto Win OFF")
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            root.CFrame = SpawnCFrame

            if Settings.NDSNoTP then
                NoTPAnchorCFrame = SpawnCFrame
                NoTPLastObservedCFrame = SpawnCFrame
            end

            CustomNotify(
                "Auto Win OFF • Spawn",
                Color3.fromRGB(100, 255, 100)
            )
        end
    end

    if AutoWinPreviousNoclip ~= nil then
        SetShared("Noclip", AutoWinPreviousNoclip)
    end

    AutoWinPreviousNoclip = nil
    AutoWinTool = nil
    AutoWinToolName = nil
    AutoWinLastActivate = 0
    AutoWinLastEquip = 0
    AutoWinInitialEquipDone = false
end

local function StartAutoWin()
    if not ToxScriptReady() then
        return
    end

    if AutoWinConnection then
        AutoWinConnection:Disconnect()
        AutoWinConnection = nil
    end

    AutoWinTool = nil
    AutoWinToolName = nil
    AutoWinLastActivate = 0
    AutoWinLastEquip = 0
    AutoWinInitialEquipDone = false
    AutoWinPreviousNoclip = Settings.Noclip == true

    SetShared("Noclip", true)

    local _, humanoid, root = GetCharacterState()

    if humanoid and humanoid.Health > 0 and root then
        FindAutoWinTool()

        AllowToxTeleport(2, "NDS Auto Win")
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        root.CFrame = AutoWinCFrame

        if Settings.NDSNoTP then
            NoTPAnchorCFrame = AutoWinCFrame
        end
    end

    AutoWinConnection = AddConnection(RunService.Heartbeat:Connect(function()
        if not Settings.NDSAutoWin then
            return
        end

        local character, currentHumanoid, currentRoot = GetCharacterState()

        if not character or not currentHumanoid or currentHumanoid.Health <= 0 or not currentRoot then
            return
        end

        if not Settings.Noclip then
            SetShared("Noclip", true)
        end

        if (currentRoot.Position - AutoWinCFrame.Position).Magnitude > 5 then
            AllowToxTeleport(0.35, "NDS Auto Win Step")
            currentRoot.AssemblyLinearVelocity = Vector3.zero
            currentRoot.AssemblyAngularVelocity = Vector3.zero
            currentRoot.CFrame = AutoWinCFrame

            if Settings.NDSNoTP then
                NoTPAnchorCFrame = AutoWinCFrame
            end
        end

        local tool = character:FindFirstChildOfClass("Tool")

        if tool then
            AutoWinTool = tool
            AutoWinToolName = tool.Name
        else
            tool = AutoWinTool
        end

        if not tool
        or tool.Parent ~= character then
            return
        end

        if tick() - AutoWinLastActivate >= 0.85 then
            AutoWinLastActivate = tick()
            ClickAutoWinTool(tool)
        end
    end))
end

local function RestoreWaterFlyHumanoid()
    if WaterFlyHumanoid
    and WaterFlyHumanoid.Parent then
        for state, enabled in pairs(
            WaterFlyStateDefaults
        ) do
            pcall(function()
                WaterFlyHumanoid:
                    SetStateEnabled(
                        state,
                        enabled
                    )
            end)
        end

        pcall(function()
            WaterFlyHumanoid:
                ChangeState(
                    Enum.HumanoidStateType.GettingUp
                )
        end)
    end

    WaterFlyHumanoid = nil
    WaterFlyStateDefaults = {}
end

local function PrepareWaterFlyHumanoid(
    humanoid
)
    if WaterFlyHumanoid
        == humanoid then
        return
    end

    RestoreWaterFlyHumanoid()

    WaterFlyHumanoid =
        humanoid

    if not humanoid then
        return
    end

    for _, state in ipairs(
        Enum.HumanoidStateType:
            GetEnumItems()
    ) do
        if state
            ~= Enum.HumanoidStateType.None then
            local ok, enabled =
                pcall(function()
                    return humanoid:
                        GetStateEnabled(
                            state
                        )
                end)

            if ok then
                WaterFlyStateDefaults[
                    state
                ] = enabled
            end

            pcall(function()
                humanoid:
                    SetStateEnabled(
                        state,
                        false
                    )
            end)
        end
    end

    pcall(function()
        humanoid:
            ChangeState(
                Enum.HumanoidStateType.Swimming
            )
    end)
end

local function StopWaterFly()
    if WaterFlyConnection then
        WaterFlyConnection:
            Disconnect()

        WaterFlyConnection = nil
    end

    if WaterFlyOldGravity
        ~= nil then
        workspace.Gravity =
            WaterFlyOldGravity

        WaterFlyOldGravity = nil
    end

    RestoreWaterFlyHumanoid()
end

local function StartWaterFly()
    if not ToxScriptReady() then
        return
    end

    StopWaterFly()

    SetShared(
        "SmoothFly",
        false
    )

    SetShared(
        "NormalFly",
        false
    )

    WaterFlyOldGravity =
        workspace.Gravity

    workspace.Gravity = 0

    WaterFlyConnection =
        AddConnection(
            RunService.Heartbeat:
                Connect(function()
                    if not Settings.NDSWaterFly then
                        return
                    end

                    local _,
                        humanoid,
                        root =
                        GetCharacterState()

                    if not humanoid
                    or humanoid.Health <= 0
                    or not root then
                        return
                    end

                    PrepareWaterFlyHumanoid(
                        humanoid
                    )

                    pcall(function()
                        humanoid:
                            ChangeState(
                                Enum.HumanoidStateType.Swimming
                            )
                    end)

                    local speed =
                        math.clamp(
                            tonumber(
                                Settings.NDSWaterFlySpeed
                            ) or 40,
                            5,
                            250
                        )

                    local moveDirection =
                        humanoid.MoveDirection

                    local vertical = 0

                    if UserInputService:
                        IsKeyDown(
                            Enum.KeyCode.Space
                        )
                    or UserInputService:
                        IsKeyDown(
                            Enum.KeyCode.E
                        ) then
                        vertical = speed
                    elseif UserInputService:
                        IsKeyDown(
                            Enum.KeyCode.LeftShift
                        )
                    or UserInputService:
                        IsKeyDown(
                            Enum.KeyCode.Q
                        ) then
                        vertical = -speed
                    end

                    if moveDirection
                        ~= Vector3.zero
                    or vertical ~= 0 then
                        root.AssemblyLinearVelocity =
                            Vector3.new(
                                moveDirection.X
                                    * speed,
                                vertical,
                                moveDirection.Z
                                    * speed
                            )
                    else
                        root.AssemblyLinearVelocity =
                            Vector3.zero
                    end

                    root.AssemblyAngularVelocity =
                        Vector3.zero
                end)
        )
end

getgenv().SetNDSWaterFly = function(Value, Silent)
    local enabled = Value == true
    Settings.NDSWaterFly = enabled

    if SyncToggleVisuals then
        SyncToggleVisuals("NDSWaterFly", enabled)
    end

    if enabled then
        StartWaterFly()
    else
        StopWaterFly()
    end

    if not Silent and AutoSaveConfiguration then
        AutoSaveConfiguration()
    end
end

local function StartNDSNoFall()
    if not ToxScriptReady() then
        return
    end

    NoFallGeneration += 1
    local generation = NoFallGeneration

    task.spawn(function()
        while game.PlaceId == 189707
        and generation == NoFallGeneration
        and (
            Settings.NoFallDamage
            or Settings.WalkFling
        )
        and not getgenv().Destroyed do
            RunService.Heartbeat:Wait()

            if Settings.NDSWaterFly then
                continue
            end

            local character, humanoid, root = GetCharacterState()

            if character and humanoid and humanoid.Health > 0 and root then
                local velocity = root.AssemblyLinearVelocity

                local walkPulse =
                    getgenv().ToxWalkFlingImpulseActive
                    == true

                if not walkPulse then
                    local minY =
                        Settings.WalkFling
                        and -24
                        or -45

                    local triggerY =
                        Settings.WalkFling
                        and -32
                        or -60

                    if velocity.Y < triggerY then
                        root.AssemblyLinearVelocity =
                            Vector3.new(
                                velocity.X,
                                minY,
                                velocity.Z
                            )
                    end

                    if Settings.WalkFling then
                        local horizontal =
                            Vector3.new(
                                velocity.X,
                                0,
                                velocity.Z
                            )

                        if horizontal.Magnitude > 110 then
                            horizontal =
                                horizontal.Unit * 110

                            root.AssemblyLinearVelocity =
                                Vector3.new(
                                    horizontal.X,
                                    root.AssemblyLinearVelocity.Y,
                                    horizontal.Z
                                )
                        end
                    end
                end
            end
        end
    end)
end

local function StopNDSNoFall()
    NoFallGeneration += 1
end

getgenv().SetNDSNoFall = function(Value, Silent)
    local enabled = Value == true
    Settings.NoFallDamage = enabled

    if SyncToggleVisuals then
        SyncToggleVisuals("NoFallDamage", enabled)
    end

    if enabled then
        StartNDSNoFall()
    else
        StopNDSNoFall()
    end

    if not Silent and AutoSaveConfiguration then
        AutoSaveConfiguration()
    end
end

local function IsNDSVoidPosition(position)
    local fallen =
        tonumber(
            workspace.FallenPartsDestroyHeight
        ) or -500

    local threshold =
        math.max(
            fallen + 35,
            -250
        )

    return position.Y <= threshold
end

local function GetNDSRespawnSafeCFrame()
    local lastSafe =
        getgenv().ToxLastSafeCFrame

    if typeof(lastSafe) == "CFrame"
    and not IsNDSVoidPosition(
        lastSafe.Position
    ) then
        return lastSafe
    end

    return SpawnCFrame
end

local function RestoreNoTPCharacter(
    character
)
    if game.PlaceId ~= NDSPlaceId
    or not Settings.NDSNoTP then
        return
    end

    task.spawn(function()
        local root =
            character:
                WaitForChild(
                    "HumanoidRootPart",
                    8
                )
        local humanoid =
            character:
                FindFirstChildOfClass(
                    "Humanoid"
                )

        if not root
        or not humanoid then
            return
        end

        task.wait(0.35)

        if not Settings.NDSNoTP
        or not character.Parent
        or humanoid.Health <= 0 then
            return
        end

        if IsNDSVoidPosition(
            root.Position
        ) then
            local safe =
                GetNDSRespawnSafeCFrame()

            AllowToxTeleport(
                1.25,
                "NDS Void Restore"
            )

            root.AssemblyLinearVelocity =
                Vector3.zero
            root.AssemblyAngularVelocity =
                Vector3.zero
            root.CFrame = safe

            NoTPAnchorCFrame = safe
            NoTPLastObservedCFrame = safe
            NoTPCorrectionCFrame = nil
            NoTPCorrectionUntil = 0

            if getgenv().SetToxLastSafeCFrame then
                getgenv().SetToxLastSafeCFrame(
                    safe
                )
            end
        else
            NoTPAnchorCFrame =
                root.CFrame
            NoTPLastObservedCFrame =
                root.CFrame
            NoTPCorrectionCFrame = nil
            NoTPCorrectionUntil = 0

            if getgenv().SetToxLastSafeCFrame then
                getgenv().SetToxLastSafeCFrame(
                    root.CFrame
                )
            end
        end

        NoTPCurrentCharacter =
            character
    end)
end

local function StopNoTP()
    if NoTPConnection then
        NoTPConnection:Disconnect()
        NoTPConnection = nil
    end

    if NoTPCharacterConnection then
        NoTPCharacterConnection:Disconnect()
        NoTPCharacterConnection = nil
    end

    if NoTPCorrectionConnection then
        NoTPCorrectionConnection:Disconnect()
        NoTPCorrectionConnection = nil
    end

    NoTPAnchorCFrame = nil
    NoTPLastObservedCFrame = nil
    NoTPCorrectionCFrame = nil
    NoTPCorrectionUntil = 0
    NoTPCurrentCharacter = nil
end

local function ApplyNoTPCorrection(
    humanoid,
    root
)
    if not root
    or typeof(NoTPCorrectionCFrame)
        ~= "CFrame" then
        return
    end

    local linearVelocity =
        root.AssemblyLinearVelocity

    local angularVelocity =
        root.AssemblyAngularVelocity

    pcall(function()
        if sethiddenproperty then
            sethiddenproperty(
                root,
                "NetworkIsSleeping",
                false
            )
        end
    end)

    root.CFrame =
        NoTPCorrectionCFrame

    root.AssemblyLinearVelocity =
        linearVelocity

    root.AssemblyAngularVelocity =
        angularVelocity
end

local function StartNoTP()
    if game.PlaceId ~= NDSPlaceId then
        Settings.NDSNoTP = false
        StopNoTP()
        return
    end

    if NoTPConnection then
        NoTPConnection:Disconnect()
        NoTPConnection = nil
    end

    if NoTPCharacterConnection then
        NoTPCharacterConnection:Disconnect()
        NoTPCharacterConnection = nil
    end

    if NoTPCorrectionConnection then
        NoTPCorrectionConnection:Disconnect()
        NoTPCorrectionConnection = nil
    end

    NoTPCorrectionCFrame = nil
    NoTPCorrectionUntil = 0

    local character, humanoid, root = GetCharacterState()

    if root
    and humanoid
    and humanoid.Health > 0 then
        NoTPAnchorCFrame =
            NoTPAnchorCFrame
            or root.CFrame
        NoTPLastObservedCFrame =
            root.CFrame
        NoTPCurrentCharacter =
            character
    end

    NoTPCharacterConnection = AddConnection(Player.CharacterAdded:Connect(function(newCharacter)
        NoTPCurrentCharacter = newCharacter
        NoTPCorrectionCFrame = nil
        NoTPCorrectionUntil = 0
        RestoreNoTPCharacter(newCharacter)
    end))

    NoTPCorrectionConnection = AddConnection(RunService.Stepped:Connect(function()
        if game.PlaceId ~= NDSPlaceId
        or not Settings.NDSNoTP
        or tick() >= NoTPCorrectionUntil
        or typeof(NoTPCorrectionCFrame) ~= "CFrame" then
            return
        end

        local currentCharacter, currentHumanoid, currentRoot = GetCharacterState()

        if not currentCharacter
        or not currentHumanoid
        or currentHumanoid.Health <= 0
        or not currentRoot then
            return
        end

        local flingBypassUntil =
            tonumber(
                getgenv().ToxFlingBypassUntil
            ) or 0

        local teleportBypassUntil =
            tonumber(
                getgenv().ToxTeleportBypassUntil
            ) or 0

        local toxTeleportAllowed =
            getgenv().ToxIsToxTeleportAllowed
            and getgenv().ToxIsToxTeleportAllowed()

        if tick() < flingBypassUntil
        or tick() < teleportBypassUntil
        or toxTeleportAllowed
        or (
            Settings.WalkFling
            and getgenv().ToxWalkFlingImpulseActive
                == true
        ) then
            NoTPCorrectionCFrame = nil
            NoTPCorrectionUntil = 0
            return
        end

        ApplyNoTPCorrection(
            currentHumanoid,
            currentRoot
        )

        NoTPLastObservedCFrame =
            NoTPCorrectionCFrame
    end))

    NoTPConnection = AddConnection(RunService.Heartbeat:Connect(function()
        if game.PlaceId ~= NDSPlaceId then
            Settings.NDSNoTP = false
            StopNoTP()
            return
        end

        if not Settings.NDSNoTP then
            return
        end

        local currentCharacter, currentHumanoid, currentRoot = GetCharacterState()

        if not currentCharacter or not currentRoot then
            return
        end

        if NoTPCurrentCharacter ~= currentCharacter then
            NoTPCurrentCharacter = currentCharacter
            RestoreNoTPCharacter(currentCharacter)
        end

        if not currentHumanoid or currentHumanoid.Health <= 0 then
            return
        end

        local flingBypassUntil =
            tonumber(
                getgenv().ToxFlingBypassUntil
            ) or 0

        if tick() < flingBypassUntil then
            NoTPCorrectionCFrame = nil
            NoTPCorrectionUntil = 0
            return
        end

        if Settings.WalkFling
        and getgenv().ToxWalkFlingImpulseActive
        == true then
            return
        end

        local bypassUntil =
            tonumber(
                getgenv().ToxTeleportBypassUntil
            ) or 0

        local toxTeleportAllowed =
            getgenv().ToxIsToxTeleportAllowed
            and getgenv().ToxIsToxTeleportAllowed()

        if tick() < bypassUntil
        or toxTeleportAllowed then
            NoTPCorrectionCFrame = nil
            NoTPCorrectionUntil = 0

            if not IsNDSVoidPosition(
                currentRoot.Position
            ) then
                NoTPAnchorCFrame =
                    currentRoot.CFrame
                NoTPLastObservedCFrame =
                    currentRoot.CFrame
            end

            return
        end

        if tick() < NoTPCorrectionUntil
        and typeof(NoTPCorrectionCFrame) == "CFrame" then
            local correctionDistance =
                (
                    currentRoot.Position
                    - NoTPCorrectionCFrame.Position
                ).Magnitude

            if correctionDistance > 5 then
                ApplyNoTPCorrection(
                    currentHumanoid,
                    currentRoot
                )

                NoTPLastObservedCFrame =
                    NoTPCorrectionCFrame

                return
            end

            NoTPCorrectionCFrame = nil
            NoTPCorrectionUntil = 0
        end

        if not NoTPAnchorCFrame then
            NoTPAnchorCFrame =
                currentRoot.CFrame
        end

        if not NoTPLastObservedCFrame then
            NoTPLastObservedCFrame =
                currentRoot.CFrame
        end

        local frameDistance =
            (
                currentRoot.Position
                - NoTPLastObservedCFrame.Position
            ).Magnitude

        local protectedDistance =
            (
                currentRoot.Position
                - NoTPAnchorCFrame.Position
            ).Magnitude

        if frameDistance > 8
        and protectedDistance > 8 then
            NoTPCorrectionCFrame =
                NoTPAnchorCFrame
            NoTPCorrectionUntil =
                tick() + 0.45

            ApplyNoTPCorrection(
                currentHumanoid,
                currentRoot
            )

            NoTPLastObservedCFrame =
                NoTPCorrectionCFrame

            return
        end

        if not IsNDSVoidPosition(
            currentRoot.Position
        ) then
            NoTPAnchorCFrame =
                currentRoot.CFrame
            NoTPLastObservedCFrame =
                currentRoot.CFrame
        end
    end))
end

getgenv().SetNDSNoTPAnchor = function(
    cframe,
    Silent
)
    if game.PlaceId ~= NDSPlaceId
    or typeof(cframe) ~= "CFrame" then
        return false
    end

    NoTPAnchorCFrame = cframe
    NoTPLastObservedCFrame = cframe
    NoTPCorrectionCFrame = nil
    NoTPCorrectionUntil = 0
    NoTPCurrentCharacter =
        Player.Character

    if getgenv().SetToxLastSafeCFrame then
        getgenv().SetToxLastSafeCFrame(
            cframe
        )
    end

    return true
end

local NDSDisasterNames = {
    "Acid Rain",
    "Blizzard",
    "Deadly Virus",
    "Earthquake",
    "Fire",
    "Flash Flood",
    "Meteor Shower",
    "Sandstorm",
    "Thunder Storm",
    "Tornado",
    "Tsunami",
    "Volcanic Eruption"
}

local function MatchNDSDisasterText(text)
    local lower =
        string.lower(
            tostring(text or "")
        )

    for _, name in ipairs(NDSDisasterNames) do
        local clean =
            string.lower(name)

        if string.find(
            lower,
            clean,
            1,
            true
        ) then
            return name
        end
    end

    if string.find(lower, "meteor", 1, true) then
        return "Meteor Shower"
    end

    if string.find(lower, "volcano", 1, true)
    or string.find(lower, "lava", 1, true) then
        return "Volcanic Eruption"
    end

    if string.find(lower, "tsunami", 1, true) then
        return "Tsunami"
    end

    if string.find(lower, "tornado", 1, true) then
        return "Tornado"
    end

    if string.find(lower, "sandstorm", 1, true)
    or string.find(lower, "sand storm", 1, true) then
        return "Sandstorm"
    end

    if string.find(lower, "blizzard", 1, true) then
        return "Blizzard"
    end

    if string.find(lower, "acid", 1, true) then
        return "Acid Rain"
    end

    if string.find(lower, "earthquake", 1, true) then
        return "Earthquake"
    end

    if string.find(lower, "flash flood", 1, true)
    or string.find(lower, "flood", 1, true) then
        return "Flash Flood"
    end

    if string.find(lower, "thunder", 1, true) then
        return "Thunder Storm"
    end

    if lower == "fire"
    or string.find(lower, "disaster fire", 1, true) then
        return "Fire"
    end

    if string.find(lower, "virus", 1, true) then
        return "Deadly Virus"
    end

    return nil
end

local function ReadNDSAttributeDisaster(object)
    if not object then
        return nil
    end

    local names = {
        "Disaster",
        "CurrentDisaster",
        "ActiveDisaster",
        "DisasterName"
    }

    for _, attribute in ipairs(names) do
        local value = object:GetAttribute(attribute)

        if value then
            local matched = MatchNDSDisasterText(value)

            if matched then
                return matched
            end
        end
    end

    return nil
end

local function FindNDSDisaster()
    local gui = Player:FindFirstChildOfClass("PlayerGui")

    if gui then
        for _, object in ipairs(gui:GetDescendants()) do
            if object:IsA("TextLabel")
            or object:IsA("TextButton")
            or object:IsA("TextBox") then
                local matched = MatchNDSDisasterText(object.Text)

                if matched then
                    return matched
                end
            end
        end
    end

    for _, object in ipairs({workspace, game:GetService("ReplicatedStorage")}) do
        local matched = ReadNDSAttributeDisaster(object)

        if matched then
            return matched
        end
    end

    for _, object in ipairs(workspace:GetDescendants()) do
        local matched = MatchNDSDisasterText(object.Name)

        if matched then
            return matched
        end
    end

    return nil
end

local function StopNDSDisasterDetector()
    if DisasterConnection then
        DisasterConnection:Disconnect()
        DisasterConnection = nil
    end
end

local function StartNDSDisasterDetector()
    if not ToxScriptReady() then
        return
    end

    StopNDSDisasterDetector()

    DisasterConnection = AddConnection(RunService.Heartbeat:Connect(function()
        if not Settings.NDSDisasterDetector then
            return
        end

        if tick() - LastDisasterScanTime < 1 then
            return
        end

        LastDisasterScanTime = tick()

        local disaster = FindNDSDisaster()

        if disaster
        and (
            disaster ~= LastDisasterNotified
            or tick() - LastDisasterNotifyTime > 28
        ) then
            LastDisasterNotified = disaster
            LastDisasterNotifyTime = tick()

            CustomNotify(
                "Disaster: " .. disaster,
                Color3.fromRGB(
                    255,
                    190,
                    70
                ),
                5
            )
        elseif not disaster then
            LastDisasterNotified = nil
        end
    end))
end

getgenv().SetNDSDisasterDetector = function(Value, Silent)
    local enabled = Value == true
    Settings.NDSDisasterDetector = enabled

    if enabled then
        StartNDSDisasterDetector()
    else
        StopNDSDisasterDetector()
        LastDisasterNotified = nil
    end

    if SyncToggleVisuals then
        SyncToggleVisuals("NDSDisasterDetector", enabled)
    end

    if not Silent
    and AutoSaveConfiguration then
        AutoSaveConfiguration()
    end
end

getgenv().SetNDSNoTP = function(Value, Silent)
    local enabled =
        Value == true
        and game.PlaceId == NDSPlaceId

    Settings.NDSNoTP = enabled

    if enabled
    and not ToxScriptReady() then
        if SyncToggleVisuals then
            SyncToggleVisuals(
                "NDSNoTP",
                enabled
            )
        end

        if not Silent
        and AutoSaveConfiguration then
            AutoSaveConfiguration()
        end

        return
    end

    if enabled then
        StartNoTP()
    else
        StopNoTP()
    end

    if SyncToggleVisuals then
        SyncToggleVisuals(
            "NDSNoTP",
            enabled
        )
    end

    if not Silent
    and AutoSaveConfiguration then
        AutoSaveConfiguration()
    end
end

local NDSCurrentSection = nil
local NDSSections = {}

local function ApplyNDSSectionState(section)
    if typeof(section) ~= "table" then
        return
    end

    Settings.NDSCollapsedSections =
        typeof(Settings.NDSCollapsedSections) == "table"
        and Settings.NDSCollapsedSections
        or {}

    local collapsed =
        Settings.NDSCollapsedSections[section.Key] == true

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

local function TrackNDSControl(object)
    if NDSCurrentSection
    and object
    and object:IsA("GuiObject") then
        table.insert(
            NDSCurrentSection.Controls,
            object
        )

        ApplyNDSSectionState(
            NDSCurrentSection
        )
    end

    return object
end

local function NDSCreateToggle(...)
    return TrackNDSControl(
        CreateToggle(...)
    )
end

local function NDSCreateToggleWithValue(...)
    return TrackNDSControl(
        CreateToggleWithValue(...)
    )
end

local function NDSCreateButton(...)
    return TrackNDSControl(
        CreateButton(...)
    )
end

local function CreateNDSSection(text)
    Settings.NDSCollapsedSections =
        typeof(Settings.NDSCollapsedSections) == "table"
        and Settings.NDSCollapsedSections
        or {}

    local name = tostring(text)
    local key =
        string.gsub(
            name,
            "%s+",
            ""
        )

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -5, 0, 26)
    button.BackgroundColor3 = Color3.fromRGB(13, 13, 21)
    button.BorderSizePixel = 0
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 11
    button.TextXAlignment = Enum.TextXAlignment.Left
    button.AutoButtonColor = false
    button.Parent = GamePage

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = button

    local section = {
        Name = name,
        Key = key,
        Header = button,
        Controls = {}
    }

    table.insert(
        NDSSections,
        section
    )

    NDSCurrentSection = section

    button.MouseButton1Click:Connect(function()
        Settings.NDSCollapsedSections[key] =
            not Settings.NDSCollapsedSections[key]

        ApplyNDSSectionState(section)

        if AutoSaveConfiguration then
            AutoSaveConfiguration()
        end
    end)

    ApplyNDSSectionState(section)

    return button
end

CreateNDSSection("AUTO")

NDSCreateToggle("Auto Win", GamePage, Settings.NDSAutoWin, function(v)
    Settings.NDSAutoWin = v

    if v then
        StartAutoWin()
    else
        StopAutoWin(true)
    end
end, "NDSAutoWin")

NDSCreateToggle("Disaster Detector", GamePage, Settings.NDSDisasterDetector, function(v)
    getgenv().SetNDSDisasterDetector(v, true)
end, "NDSDisasterDetector")

CreateNDSSection("MOVEMENT")

NDSCreateToggle("Ctrl Click TP", GamePage, Settings.CtrlClickTP, function(v)
    SetShared("CtrlClickTP", v)
end, "CtrlClickTP")

NDSCreateToggle("No TP", GamePage, Settings.NDSNoTP, function(v)
    getgenv().SetNDSNoTP(v, true)
end, "NDSNoTP")

NDSCreateToggle("Noclip", GamePage, Settings.Noclip, function(v)
    SetShared("Noclip", v)
end, "Noclip")

NDSCreateToggleWithValue("Water Fly", GamePage, Settings.NDSWaterFly, Settings.NDSWaterFlySpeed, function(v)
    getgenv().SetNDSWaterFly(v, true)
end, function(value)
    Settings.NDSWaterFlySpeed = math.clamp(
        tonumber(value) or 40,
        5,
        250
    )

    if SyncValueVisuals then
        SyncValueVisuals("NDSWaterFly", Settings.NDSWaterFlySpeed)
    end
end, "NDSWaterFly")

NDSCreateToggleWithValue("Car Fly", GamePage, Settings.CarFly, Settings.CarFlySpeed, function(v)
    SetShared("CarFly", v)
end, function(value)
    Settings.CarFlySpeed = math.clamp(tonumber(value) or 80, 5, 300)

    if SyncValueVisuals then
        SyncValueVisuals("CarFly", Settings.CarFlySpeed)
    end
end, "CarFly")

CreateNDSSection("PROTECTION")

NDSCreateToggle("No Fall Damage", GamePage, Settings.NoFallDamage, function(v)
    SetShared("NoFallDamage", v)
end, "NoFallDamage")

NDSCreateToggle("Anti Void", GamePage, Settings.AntiVoid, function(v)
    SetShared("AntiVoid", v)
end, "AntiVoid")

NDSCreateToggle("Anti Fling", GamePage, Settings.AntiFling, function(v)
    SetShared("AntiFling", v)
end, "AntiFling")

NDSCreateToggle("Walk Fling", GamePage, Settings.WalkFling, function(v)
    SetShared("WalkFling", v)

    if v then
        StartNDSNoFall()
    elseif not Settings.NoFallDamage then
        StopNDSNoFall()
    end
end, "WalkFling")

CreateNDSSection("TELEPORTS")

NDSCreateButton("SPAWN", GamePage, function()
    TeleportTo(SpawnCFrame, "SPAWN")
end)

NDSCreateButton("ISLAND", GamePage, function()
    TeleportTo(IslandCFrame, "ISLAND")
end)

local function ApplyNDSSavedOptionsAfterLoad()
    if getgenv().Destroyed
    or not ToxScriptReady() then
        return
    end

    if Settings.NDSAutoWin then
        StartAutoWin()
    end

    if Settings.NoFallDamage
    or Settings.WalkFling then
        StartNDSNoFall()
    end

    if Settings.NDSWaterFly then
        StartWaterFly()
    end

    if Settings.NDSNoTP then
        getgenv().SetNDSNoTP(
            true,
            true
        )
    else
        StopNoTP()
    end

    if Settings.NDSDisasterDetector then
        StartNDSDisasterDetector()
    end
end

task.spawn(function()
    while not getgenv().Destroyed
    and not ToxScriptReady() do
        task.wait(0.05)
    end

    ApplyNDSSavedOptionsAfterLoad()
end)

getgenv().ToxNDSCleanup =
    function()
        pcall(
            StopAutoWin
        )

        pcall(
            StopNDSNoFall
        )

        pcall(
            StopWaterFly
        )

        pcall(
            StopNoTP
        )

        pcall(
            StopNDSDisasterDetector
        )
    end

getgenv().ToxNDSModuleLoadedJobId =
    game.JobId

getgenv().ToxNDSModuleVersion =
    NDSModuleVersion

getgenv().ToxNDSModulePage =
    GamePage
