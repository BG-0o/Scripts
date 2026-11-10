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

Settings.NDSCollapsedSections =
    typeof(Settings.NDSCollapsedSections) == "table"
    and Settings.NDSCollapsedSections
    or {}

local NDSCurrentSection = nil
local NDSSections = {}

local function ApplyNDSSectionState(section)
    if typeof(section) ~= "table" then
        return
    end

    local collapsed = Settings.NDSCollapsedSections[section.Key] == true

    if section.Header and section.Header.Parent then
        section.Header.Text = collapsed
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
        table.insert(NDSCurrentSection.Controls, object)
        ApplyNDSSectionState(NDSCurrentSection)
    end

    return object
end

local function NDSCreateToggle(...)
    return TrackNDSControl(CreateToggle(...))
end

local function NDSCreateToggleWithValue(...)
    return TrackNDSControl(CreateToggleWithValue(...))
end

local function NDSCreateButton(...)
    return TrackNDSControl(CreateButton(...))
end

local function CreateNDSSection(text)
    local name = tostring(text)
    local key = string.upper(name):gsub("%s+", "")
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

    table.insert(NDSSections, section)
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

local NDSModuleVersion =
    "2026-09-16-lighting-nds-extras-3"

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

local function AllowToxTeleport(seconds)
    if getgenv().AllowToxTeleport then
        getgenv().AllowToxTeleport(seconds or 1)
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

    AllowToxTeleport(1.5)
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    root.CFrame = cframe

    if Settings.NDSNoTP then
        NoTPAnchorCFrame = cframe
        NoTPLastObservedCFrame = cframe
    end

    CustomNotify("Teleported to " .. name, Color3.fromRGB(100, 255, 100))
end

local FindAppleByName

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

local function EquipAndGetHotbarTwo(force)
    local character, humanoid = GetCharacterState()

    if not character
    or not humanoid
    or humanoid.Health <= 0 then
        return nil
    end

    local equipped = character:FindFirstChildOfClass("Tool")

    if equipped then
        AutoWinTool = equipped
        AutoWinToolName = equipped.Name
        return equipped
    end

    local backpack = Player:FindFirstChildOfClass("Backpack")

    if AutoWinToolName then
        local cached =
            character:FindFirstChild(AutoWinToolName)
            or (backpack and backpack:FindFirstChild(AutoWinToolName))

        if cached and cached:IsA("Tool") then
            pcall(function()
                humanoid:EquipTool(cached)
            end)

            task.wait(0.04)

            equipped = character:FindFirstChildOfClass("Tool")
            if equipped then
                AutoWinTool = equipped
                AutoWinToolName = equipped.Name
                return equipped
            end
        end
    end

    if force or not AutoWinInitialEquipDone then
        AutoWinInitialEquipDone = true
        PressHotbarTwo()
        task.wait(0.06)

        equipped = character:FindFirstChildOfClass("Tool")

        if equipped then
            AutoWinTool = equipped
            AutoWinToolName = equipped.Name
            return equipped
        end
    end

    local apple = FindAppleByName and FindAppleByName()

    if apple and apple:IsA("Tool") then
        pcall(function()
            humanoid:EquipTool(apple)
        end)

        task.wait(0.04)

        equipped = character:FindFirstChildOfClass("Tool") or apple
        AutoWinTool = equipped
        AutoWinToolName = equipped.Name
        return equipped
    end

    return nil
end

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

    local hotbarTwo = EquipAndGetHotbarTwo(false)

    if hotbarTwo then
        AutoWinTool = hotbarTwo
        AutoWinToolName = hotbarTwo.Name
        return hotbarTwo
    end

    local namedApple = FindAppleByName()

    if namedApple then
        AutoWinTool = namedApple
        AutoWinToolName = namedApple.Name

        if character
        and namedApple.Parent ~= character then
            local humanoid =
                character:FindFirstChildOfClass("Humanoid")

            if humanoid then
                pcall(function()
                    humanoid:EquipTool(namedApple)
                end)
            end
        end

        return namedApple
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

    local equipped = character:FindFirstChildOfClass("Tool")

    if not equipped and tool and tool:IsA("Tool") then
        pcall(function()
            humanoid:EquipTool(tool)
        end)

        task.wait(0.04)
        equipped = character:FindFirstChildOfClass("Tool")
    end

    tool = equipped or tool

    if not tool
    or not tool.Parent then
        return false
    end

    AutoWinTool = tool
    AutoWinToolName = tool.Name

    pcall(function()
        tool:Activate()
    end)

    task.wait(0.04)

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

    if AutoWinPreviousNoclip ~= nil then
        SetShared("Noclip", AutoWinPreviousNoclip)
    end

    AutoWinPreviousNoclip = nil
    AutoWinTool = nil
    AutoWinToolName = nil
    AutoWinLastActivate = 0
    AutoWinLastEquip = 0
    AutoWinInitialEquipDone = false

    if returnToSpawn then
        local _, humanoid, root = GetCharacterState()

        if humanoid and humanoid.Health > 0 and root then
            AllowToxTeleport(1.5)
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            root.CFrame = SpawnCFrame

            if Settings.NDSNoTP then
                NoTPAnchorCFrame = SpawnCFrame
                NoTPLastObservedCFrame = SpawnCFrame
            end
        end
    end
end

local function StartAutoWin()
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
        AllowToxTeleport(2)
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
            AllowToxTeleport(0.35)
            currentRoot.AssemblyLinearVelocity = Vector3.zero
            currentRoot.AssemblyAngularVelocity = Vector3.zero
            currentRoot.CFrame = AutoWinCFrame

            if Settings.NDSNoTP then
                NoTPAnchorCFrame = AutoWinCFrame
            end
        end

        local tool = FindAutoWinTool()

        if not tool then
            return
        end

        if tool.Parent ~= character then
            pcall(function()
                currentHumanoid:EquipTool(tool)
            end)

            task.wait(0.04)
            tool = character:FindFirstChildOfClass("Tool") or tool
        end

        if tool
        and tool.Parent
        and tick() - AutoWinLastActivate >= 0.85 then
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

            if getgenv().AllowToxTeleport then
                getgenv().AllowToxTeleport(
                    1.25
                )
            end

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

        if tick() < flingBypassUntil
        or tick() < teleportBypassUntil
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

        if tick() < bypassUntil then
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

getgenv().SetNDSNoTP = function(Value, Silent)
    local enabled =
        Value == true
        and game.PlaceId == NDSPlaceId

    Settings.NDSNoTP = enabled

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

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local NDSExtraConnections = {}
local NDSCheerDefaults = {}
local NDSHazardDefaults = {
    Meteors = {},
    VolcanicLava = {},
    VirusParticles = {},
    TsunamiWave = {},
    BarbedWire = {}
}
local NDSRockDefaults = {}
local NDSDisasterSeen = {}
local NDSDisasterStructure = nil
local NDSDisasterClock = 0

local NDSHazardSettingKeys = {
    Meteors = "NDSRemoveMeteors",
    VolcanicLava = "NDSRemoveVolcanicLava",
    VirusParticles = "NDSRemoveVirusParticles",
    TsunamiWave = "NDSRemoveTsunamiWave",
    BarbedWire = "NDSRemoveBarbedWire"
}

local NDSDisasterPatterns = {
    ["Acid Rain"] = {"acid rain", "acidrain"},
    ["Blizzard"] = {"blizzard"},
    ["Deadly Virus"] = {"deadly virus", "deadlyvirus"},
    ["Earthquake"] = {"earthquake"},
    ["Fire"] = {"fire disaster", "disaster fire"},
    ["Flash Flood"] = {"flash flood", "flashflood"},
    ["Meteor Shower"] = {"meteor shower", "meteorshower"},
    ["Sandstorm"] = {"sandstorm"},
    ["Thunderstorm"] = {"thunderstorm", "thunder storm"},
    ["Tornado"] = {"tornado"},
    ["Tsunami"] = {"tsunami"},
    ["Volcanic Eruption"] = {"volcanic eruption", "volcaniceruption"}
}

local function TrackNDSExtraConnection(connection)
    if connection then
        NDSExtraConnections[#NDSExtraConnections + 1] = connection
    end
    return connection
end

local function NDSLowerPath(object)
    local parts = {}
    local current = object
    local depth = 0

    while current and current ~= game and depth < 6 do
        parts[#parts + 1] = tostring(current.Name or "")
        current = current.Parent
        depth += 1
    end

    return string.lower(table.concat(parts, " "))
end

local function NDSMatchesHazard(feature, object)
    local path = NDSLowerPath(object)

    if feature == "Meteors" then
        return string.find(path, "meteor", 1, true) ~= nil
    elseif feature == "VolcanicLava" then
        return string.find(path, "lava", 1, true) ~= nil
    elseif feature == "VirusParticles" then
        return string.find(path, "virus", 1, true) ~= nil
    elseif feature == "TsunamiWave" then
        return string.find(path, "tsunami", 1, true) ~= nil
            or string.find(path, "tsunami wave", 1, true) ~= nil
    elseif feature == "BarbedWire" then
        return string.find(path, "barbed", 1, true) ~= nil
            or string.find(path, "barbedwire", 1, true) ~= nil
    end

    return false
end

local function NDSApplyHazardObject(feature, object)
    if not NDSMatchesHazard(feature, object) then
        return
    end

    local store = NDSHazardDefaults[feature]

    if feature == "VirusParticles"
    and object:IsA("BasePart") then
        return
    end

    if object:IsA("BasePart") then
        if store[object] == nil then
            store[object] = {
                Type = "Part",
                CanCollide = object.CanCollide,
                CanTouch = object.CanTouch,
                CanQuery = object.CanQuery,
                LocalTransparencyModifier = object.LocalTransparencyModifier
            }
        end

        pcall(function()
            object.CanCollide = false
            object.CanTouch = false
            object.CanQuery = false
            object.LocalTransparencyModifier = 1
        end)
        return
    end

    if object:IsA("ParticleEmitter")
    or object:IsA("Trail")
    or object:IsA("Beam")
    or object:IsA("Smoke")
    or object:IsA("Fire")
    or object:IsA("Sparkles") then
        if store[object] == nil then
            store[object] = {
                Type = "Effect",
                Enabled = object.Enabled
            }
        end

        pcall(function()
            object.Enabled = false
        end)
    end
end

local function NDSRestoreHazard(feature)
    local store = NDSHazardDefaults[feature]
    local copy = {}

    for object, snapshot in pairs(store) do
        copy[object] = snapshot
        store[object] = nil
    end

    for object, snapshot in pairs(copy) do
        if object and object.Parent then
            if snapshot.Type == "Part" then
                pcall(function()
                    object.CanCollide = snapshot.CanCollide
                    object.CanTouch = snapshot.CanTouch
                    object.CanQuery = snapshot.CanQuery
                    object.LocalTransparencyModifier = snapshot.LocalTransparencyModifier
                end)
            elseif snapshot.Type == "Effect" then
                pcall(function()
                    object.Enabled = snapshot.Enabled
                end)
            end
        end
    end
end

local function SetNDSHazard(feature, enabled)
    local settingKey = NDSHazardSettingKeys[feature]

    if not settingKey then
        return
    end

    enabled = enabled == true
    Settings[settingKey] = enabled

    if enabled then
        for _, object in ipairs(workspace:GetDescendants()) do
            NDSApplyHazardObject(feature, object)
        end
    else
        NDSRestoreHazard(feature)
    end
end

local function NDSIsIslandRock(object)
    if not object:IsA("BasePart") then
        return false
    end

    local path = NDSLowerPath(object)

    if not string.find(path, "rock", 1, true)
    and not string.find(path, "boulder", 1, true) then
        return false
    end

    local structure = workspace:FindFirstChild("Structure")
    return not structure or object:IsDescendantOf(structure)
end

local function NDSApplyRock(object)
    if not NDSIsIslandRock(object) then
        return
    end

    if NDSRockDefaults[object] == nil then
        NDSRockDefaults[object] = object.CanCollide
    end

    pcall(function()
        object.CanCollide = true
    end)
end

local function SetNDSIslandRocksCollidable(enabled)
    enabled = enabled == true
    Settings.NDSIslandRocksCollidable = enabled

    if enabled then
        for _, object in ipairs(workspace:GetDescendants()) do
            NDSApplyRock(object)
        end
    else
        local copy = {}

        for object, value in pairs(NDSRockDefaults) do
            copy[object] = value
            NDSRockDefaults[object] = nil
        end

        for object, value in pairs(copy) do
            if object and object.Parent then
                pcall(function()
                    object.CanCollide = value
                end)
            end
        end
    end
end

local function NDSIsCheerSound(object)
    if not object:IsA("Sound") then
        return false
    end

    local path = NDSLowerPath(object)
    return string.find(path, "cheer", 1, true) ~= nil
        or string.find(path, "applause", 1, true) ~= nil
        or string.find(path, "crowd", 1, true) ~= nil
end

local function NDSMuteCheerObject(object)
    if not NDSIsCheerSound(object) then
        return
    end

    if NDSCheerDefaults[object] == nil then
        NDSCheerDefaults[object] = object.Volume
    end

    pcall(function()
        object.Volume = 0
    end)
end

local function SetNDSMuteCheer(enabled)
    enabled = enabled == true
    Settings.NDSMuteCheerSound = enabled

    if enabled then
        for _, object in ipairs(game:GetDescendants()) do
            NDSMuteCheerObject(object)
        end
    else
        local copy = {}

        for object, volume in pairs(NDSCheerDefaults) do
            copy[object] = volume
            NDSCheerDefaults[object] = nil
        end

        for object, volume in pairs(copy) do
            if object and object.Parent then
                pcall(function()
                    object.Volume = volume
                end)
            end
        end
    end
end

local function NDSDetectDisaster(text)
    local lower = string.lower(tostring(text or ""))

    if lower == "" then
        return nil
    end

    if lower == "fire" then
        return "Fire"
    elseif lower == "virus" then
        return "Deadly Virus"
    end

    for disaster, patterns in pairs(NDSDisasterPatterns) do
        for _, pattern in ipairs(patterns) do
            if string.find(lower, pattern, 1, true) then
                return disaster
            end
        end
    end

    return nil
end

local function NDSNotifyDisaster(disaster)
    if not disaster or NDSDisasterSeen[disaster] then
        return
    end

    NDSDisasterSeen[disaster] = true

    if CustomNotify then
        CustomNotify(
            "Disaster: " .. tostring(disaster),
            Color3.fromRGB(255, 190, 80),
            6
        )
    end
end

local function NDSInspectDisasterObject(object)
    if not Settings.NDSNotifyDisasters or not object then
        return
    end

    if not workspace:FindFirstChild("Structure") then
        return
    end

    local toxGui = getgenv().Gui
    local notifGui = getgenv().NotifGui

    if typeof(toxGui) == "Instance"
    and (object == toxGui or object:IsDescendantOf(toxGui)) then
        return
    end

    if typeof(notifGui) == "Instance"
    and (object == notifGui or object:IsDescendantOf(notifGui)) then
        return
    end

    NDSNotifyDisaster(NDSDetectDisaster(object.Name))

    if object:IsA("StringValue") then
        NDSNotifyDisaster(NDSDetectDisaster(object.Value))
    elseif object:IsA("TextLabel")
    or object:IsA("TextButton")
    or object:IsA("TextBox") then
        NDSNotifyDisaster(NDSDetectDisaster(object.Text))
    end
end

local function NDSScanDisasters()
    if not Settings.NDSNotifyDisasters then
        return
    end

    local structure = workspace:FindFirstChild("Structure")

    if structure ~= NDSDisasterStructure then
        NDSDisasterStructure = structure
        NDSDisasterSeen = {}
    end

    if not structure then
        return
    end

    for _, root in ipairs({ReplicatedStorage, Lighting, Player:FindFirstChildOfClass("PlayerGui")}) do
        if root then
            NDSInspectDisasterObject(root)

            for _, object in ipairs(root:GetDescendants()) do
                NDSInspectDisasterObject(object)
            end
        end
    end

    for _, object in ipairs(workspace:GetChildren()) do
        NDSInspectDisasterObject(object)
    end
end

local function SetNDSNotifyDisasters(enabled)
    Settings.NDSNotifyDisasters = enabled == true
    NDSDisasterSeen = {}
    NDSDisasterStructure = workspace:FindFirstChild("Structure")
    NDSDisasterClock = 0

    if Settings.NDSNotifyDisasters then
        NDSScanDisasters()
    end
end

local function FindGreenBalloonTool()
    local backpack = Player:FindFirstChildOfClass("Backpack")
    local character = Player.Character

    for _, container in ipairs({backpack, character}) do
        if container then
            for _, object in ipairs(container:GetChildren()) do
                if object:IsA("Tool") then
                    local name = string.lower(object.Name)
                    if string.find(name, "green", 1, true)
                    and string.find(name, "balloon", 1, true) then
                        return object, true
                    end
                end
            end
        end
    end

    for _, root in ipairs({ReplicatedStorage, Lighting, workspace}) do
        for _, object in ipairs(root:GetDescendants()) do
            if object:IsA("Tool") then
                local name = string.lower(object.Name)
                if string.find(name, "green", 1, true)
                and string.find(name, "balloon", 1, true) then
                    return object, false
                end
            end
        end
    end

    return nil, false
end

local function GiveGreenBalloon()
    local backpack = Player:FindFirstChildOfClass("Backpack")
        or Player:WaitForChild("Backpack", 2)

    if not backpack then
        CustomNotify("Backpack unavailable", Color3.fromRGB(255, 100, 100))
        return
    end

    local source, owned = FindGreenBalloonTool()

    if not source then
        CustomNotify("Green Balloon source not found", Color3.fromRGB(255, 180, 70))
        return
    end

    if owned then
        if source.Parent == Player.Character then
            pcall(function()
                source.Parent = backpack
            end)
        end

        CustomNotify("Green Balloon already given", Color3.fromRGB(100, 255, 100))
        return
    end

    local ok, clone = pcall(function()
        return source:Clone()
    end)

    if not ok or not clone then
        CustomNotify("Could not give Green Balloon", Color3.fromRGB(255, 100, 100))
        return
    end

    clone.Parent = backpack
    CustomNotify("Green Balloon given", Color3.fromRGB(100, 255, 100))
end

local function InteractAll()
    local count = 0

    for _, object in ipairs(workspace:GetDescendants()) do
        if object:IsA("ProximityPrompt")
        and type(fireproximityprompt) == "function" then
            local ok = pcall(fireproximityprompt, object)
            if ok then
                count += 1
            end
        elseif object:IsA("ClickDetector")
        and type(fireclickdetector) == "function" then
            local ok = pcall(fireclickdetector, object)
            if ok then
                count += 1
            end
        end
    end

    if CustomNotify then
        CustomNotify(
            "Interacted: " .. tostring(count),
            count > 0 and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 180, 70),
            4
        )
    end
end

TrackNDSExtraConnection(workspace.DescendantAdded:Connect(function(object)
    for feature, settingKey in pairs(NDSHazardSettingKeys) do
        if Settings[settingKey] then
            task.defer(NDSApplyHazardObject, feature, object)
        end
    end

    if Settings.NDSIslandRocksCollidable then
        task.defer(NDSApplyRock, object)
    end

    if Settings.NDSMuteCheerSound then
        task.defer(NDSMuteCheerObject, object)
    end

    if Settings.NDSNotifyDisasters then
        task.defer(NDSInspectDisasterObject, object)
    end
end))

TrackNDSExtraConnection(ReplicatedStorage.DescendantAdded:Connect(function(object)
    if Settings.NDSNotifyDisasters then
        task.defer(NDSInspectDisasterObject, object)
    end
end))

TrackNDSExtraConnection(Lighting.DescendantAdded:Connect(function(object)
    if Settings.NDSNotifyDisasters then
        task.defer(NDSInspectDisasterObject, object)
    end
end))

TrackNDSExtraConnection(game.DescendantAdded:Connect(function(object)
    if Settings.NDSMuteCheerSound then
        task.defer(NDSMuteCheerObject, object)
    end
end))

TrackNDSExtraConnection(RunService.Heartbeat:Connect(function(delta)
    if not Settings.NDSNotifyDisasters then
        return
    end

    NDSDisasterClock += math.max(tonumber(delta) or 0, 0)

    if NDSDisasterClock >= 0.6 then
        NDSDisasterClock = 0
        NDSScanDisasters()
    end
end))


CreateNDSSection("PLAYER")

NDSCreateToggle("Auto Win", GamePage, Settings.NDSAutoWin, function(v)
    Settings.NDSAutoWin = v

    if v then
        StartAutoWin()
    else
        StopAutoWin(true)
    end
end, "NDSAutoWin")

NDSCreateToggle("No TP", GamePage, Settings.NDSNoTP, function(v)
    getgenv().SetNDSNoTP(v, true)
end, "NDSNoTP")

NDSCreateToggle("Noclip", GamePage, Settings.Noclip, function(v)
    SetShared("Noclip", v)
end, "Noclip")

NDSCreateToggle("No Fall Damage", GamePage, Settings.NoFallDamage, function(v)
    SetShared("NoFallDamage", v)
end, "NoFallDamage")

NDSCreateToggle("Anti Void", GamePage, Settings.AntiVoid, function(v)
    SetShared("AntiVoid", v)
end, "AntiVoid")

NDSCreateToggle("Anti Fling", GamePage, Settings.AntiFling, function(v)
    SetShared("AntiFling", v)
end, "AntiFling")

CreateNDSSection("MOVEMENT")

NDSCreateToggle("Walk Fling", GamePage, Settings.WalkFling, function(v)
    SetShared("WalkFling", v)

    if v then
        StartNDSNoFall()
    elseif not Settings.NoFallDamage then
        StopNDSNoFall()
    end
end, "WalkFling")

NDSCreateToggle("Ctrl Click TP", GamePage, Settings.CtrlClickTP, function(v)
    SetShared("CtrlClickTP", v)
end, "CtrlClickTP")

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

CreateNDSSection("DISASTERS")

NDSCreateToggle("Notify Disasters", GamePage, Settings.NDSNotifyDisasters, function(v)
    SetNDSNotifyDisasters(v)
end, "NDSNotifyDisasters")

CreateNDSSection("EXTRAS")

NDSCreateButton("Give Green Balloon", GamePage, function()
    GiveGreenBalloon()
end)

NDSCreateButton("Interact All", GamePage, function()
    InteractAll()
end)

NDSCreateToggle("Mute Cheer Sound", GamePage, Settings.NDSMuteCheerSound, function(v)
    SetNDSMuteCheer(v)
end, "NDSMuteCheerSound")

CreateNDSSection("ISLAND")

NDSCreateToggle("Remove Meteors", GamePage, Settings.NDSRemoveMeteors, function(v)
    SetNDSHazard("Meteors", v)
end, "NDSRemoveMeteors")

NDSCreateToggle("Remove Volcanic Lava", GamePage, Settings.NDSRemoveVolcanicLava, function(v)
    SetNDSHazard("VolcanicLava", v)
end, "NDSRemoveVolcanicLava")

NDSCreateToggle("Remove Virus Particles", GamePage, Settings.NDSRemoveVirusParticles, function(v)
    SetNDSHazard("VirusParticles", v)
end, "NDSRemoveVirusParticles")

NDSCreateToggle("Remove Tsunami Wave", GamePage, Settings.NDSRemoveTsunamiWave, function(v)
    SetNDSHazard("TsunamiWave", v)
end, "NDSRemoveTsunamiWave")

NDSCreateToggle("Remove Barbed Wire", GamePage, Settings.NDSRemoveBarbedWire, function(v)
    SetNDSHazard("BarbedWire", v)
end, "NDSRemoveBarbedWire")

NDSCreateToggle("Island Rocks Collidable", GamePage, Settings.NDSIslandRocksCollidable, function(v)
    SetNDSIslandRocksCollidable(v)
end, "NDSIslandRocksCollidable")

CreateNDSSection("TELEPORTS")

NDSCreateButton("SPAWN", GamePage, function()
    TeleportTo(SpawnCFrame, "SPAWN")
end)

NDSCreateButton("ISLAND", GamePage, function()
    TeleportTo(IslandCFrame, "ISLAND")
end)

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

if Settings.NDSNotifyDisasters then
    SetNDSNotifyDisasters(true)
end

if Settings.NDSMuteCheerSound then
    SetNDSMuteCheer(true)
end

for feature, settingKey in pairs(NDSHazardSettingKeys) do
    if Settings[settingKey] then
        SetNDSHazard(feature, true)
    end
end

if Settings.NDSIslandRocksCollidable then
    SetNDSIslandRocksCollidable(true)
end

getgenv().ToxNDSCleanup =
    function()
        pcall(function()
            StopAutoWin(false)
        end)

        pcall(
            StopNDSNoFall
        )

        pcall(
            StopWaterFly
        )

        pcall(
            StopNoTP
        )

        Settings.NDSNotifyDisasters = false

        pcall(function()
            SetNDSMuteCheer(false)
        end)

        for feature in pairs(NDSHazardSettingKeys) do
            pcall(function()
                SetNDSHazard(feature, false)
            end)
        end

        pcall(function()
            SetNDSIslandRocksCollidable(false)
        end)

        for _, connection in ipairs(NDSExtraConnections) do
            pcall(function()
                connection:Disconnect()
            end)
        end

        NDSExtraConnections = {}
    end

getgenv().ToxNDSModuleLoadedJobId =
    game.JobId

getgenv().ToxNDSModuleVersion =
    NDSModuleVersion

getgenv().ToxNDSModulePage =
    GamePage
