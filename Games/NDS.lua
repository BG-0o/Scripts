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

local function NDSCreateToggleWithSlider(Name, Page, MinVal, MaxVal, DefaultToggle, DefaultVal, Suffix, CallbackToggle, CallbackValue, SyncKey)
    local fn = CreateToggleWithSlider or (getgenv and getgenv().CreateToggleWithSlider)
    if fn then
        return TrackNDSControl(fn(Name, Page, MinVal, MaxVal, DefaultToggle, DefaultVal, Suffix, CallbackToggle, CallbackValue, SyncKey))
    else
        -- typed-value control takes a different argument order
        return TrackNDSControl(CreateToggleWithValue(Name, Page, DefaultToggle, DefaultVal, CallbackToggle, CallbackValue, SyncKey))
    end
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

                    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                        vertical = speed
                    elseif (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) then
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

                -- Anti-fall damage protection: cap downward speed (strength = No Fall Damage %)
                local maxFall = getgenv().ToxGetNoFallMaxSpeed and getgenv().ToxGetNoFallMaxSpeed()
                    or (15 + math.clamp(tonumber(Settings.NoFallSpeed) or 50, 0, 100) * 0.85)
                if velocity.Y < -maxFall then
                    root.AssemblyLinearVelocity =
                        Vector3.new(
                            velocity.X,
                            -maxFall,
                            velocity.Z
                        )
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
            if getgenv().ToxIsToxTeleportAllowed and getgenv().ToxIsToxTeleportAllowed() then
                NoTPAnchorCFrame = currentRoot.CFrame
                NoTPLastObservedCFrame = currentRoot.CFrame
                NoTPCorrectionCFrame = nil
                NoTPCorrectionUntil = 0
                return
            end

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
local NDSCurrentDisaster = nil
local NDSCurrentMap = nil
local NDSLastDisasterNotify = ""
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
        if string.find(path, "antivirus", 1, true) then
            return false
        end
        for _, word in ipairs({ "virus", "infect", "germ", "bacteria", "disease", "plague", "contagio" }) do
            if string.find(path, word, 1, true) then
                return true
            end
        end
        return false
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

    -- The island (and its rocks) is NOT inside workspace.Structure (that is only the
    -- map building), so the old check skipped every island rock once a map loaded.
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character and object:IsDescendantOf(p.Character) then
            return false
        end
    end
    return true
end

-- Island Rocks: instead of forcing CanCollide on the rock meshes (their collision shape is
-- irregular, so standing on them made the character glitch/"teleport"), we raycast to the
-- rock surface under the feet and put a flat invisible support there. Same support is used
-- by "Walk on Water".
local NDSRockSet = setmetatable({}, { __mode = "k" })
local NDSRockList = {}
local NDSRockListDirty = true

local function NDSApplyRock(object)
    if not NDSIsIslandRock(object) or NDSRockSet[object] then
        return
    end

    NDSRockSet[object] = true
    NDSRockListDirty = true

    if NDSRockDefaults[object] == nil then
        NDSRockDefaults[object] = { CanQuery = object.CanQuery }
    end

    pcall(function()
        object.CanQuery = true   -- raycasts must see the rock
    end)
end

local function SetNDSIslandRocksCollidable(enabled)
    enabled = enabled == true
    Settings.NDSIslandRocksCollidable = enabled

    if enabled then
        for _, object in ipairs(workspace:GetDescendants()) do
            NDSApplyRock(object)
        end
        local count = 0
        for _ in pairs(NDSRockSet) do count += 1 end
        if CustomNotify and getgenv().ScriptLoaded then
            CustomNotify("Island Rocks • " .. count .. " rocks found", count > 0 and Color3.fromRGB(100, 200, 255) or Color3.fromRGB(255, 180, 70), 4)
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
                    if type(value) == "table" then
                        object.CanQuery = value.CanQuery
                    else
                        object.CanCollide = value   -- left by older versions
                    end
                end)
            end
        end

        for object in pairs(NDSRockSet) do
            NDSRockSet[object] = nil
        end
        NDSRockListDirty = true
    end
end

local function NDSIsWaterPart(part)
    if not part or not part:IsA("BasePart") then
        return false
    end
    if part.Material == Enum.Material.Water then
        return true
    end
    local lower = string.lower(part.Name)
    return string.find(lower, "water", 1, true) ~= nil
        or string.find(lower, "ocean", 1, true) ~= nil
end

-- Finds the sea level once per map. Works even if the water part ignores raycasts
-- (CanQuery off), which is why the old raycast-only version let you fall into the void.
local NDSWaterCache = { Map = false, Level = nil, Time = 0, Notified = false }

local function NDSScanWaterLevel()
    local best = nil
    local bestName = nil
    local myCharacter = Player.Character
    for _, object in ipairs(workspace:GetDescendants()) do
        if object:IsA("BasePart") and not (myCharacter and object:IsDescendantOf(myCharacter)) then
            local size = object.Size
            if math.max(size.X, size.Z) >= 150 then
                local lower = string.lower(object.Name)
                local named = string.find(lower, "water", 1, true) or string.find(lower, "ocean", 1, true)
                    or lower == "sea" or string.find(lower, "sea ", 1, true)
                if object.Material == Enum.Material.Water or named then
                    local top = object.Position.Y + size.Y / 2
                    if not best or top > best then
                        best = top
                        bestName = object:GetFullName()
                    end
                end
            end
        end
    end
    if best then
        return best, bestName
    end
    -- Fallback: the ocean is usually the biggest flat, non-collidable sheet in the game
    local bestArea = 0
    for _, object in ipairs(workspace:GetDescendants()) do
        if object:IsA("BasePart") and not object.CanCollide
        and not (myCharacter and object:IsDescendantOf(myCharacter)) then
            local size = object.Size
            local area = size.X * size.Z
            if math.min(size.X, size.Z) >= 400 and size.Y <= 60 and area > bestArea then
                bestArea = area
                best = object.Position.Y + size.Y / 2
                bestName = object:GetFullName() .. " [biggest sheet]"
            end
        end
    end
    return best, bestName
end

function NDSGetWaterLevel(position, character)
    local map = workspace:FindFirstChild("Structure")
    local now = os.clock()
    if NDSWaterCache.Map ~= map or (not NDSWaterCache.Level and now - NDSWaterCache.Time > 3) then
        if NDSWaterCache.Map ~= map then
            NDSWaterCache.Notified = false   -- tell the sea level again on a new map
        end
        NDSWaterCache.Map = map
        NDSWaterCache.Time = now
        local level, name = NDSScanWaterLevel()
        if not level then
            -- Terrain water: raycast straight down from high above, water not ignored
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances = { character, workspace.CurrentCamera, NDSSupportPart }
            params.IgnoreWater = false
            local hit = workspace:Raycast(position + Vector3.new(0, 400, 0), Vector3.new(0, -1200, 0), params)
            if hit and hit.Instance:IsA("Terrain") and hit.Material == Enum.Material.Water then
                level, name = hit.Position.Y, "Terrain water"
            end
        end
        NDSWaterCache.Level = level
        if not NDSWaterCache.Notified and CustomNotify then
            NDSWaterCache.Notified = true
            if level then
                CustomNotify(string.format("Walk on Water • sea level %.1f (%s)", level, tostring(name)), Color3.fromRGB(100, 200, 255), 4)
            else
                CustomNotify("Walk on Water • no water found on this map", Color3.fromRGB(255, 180, 70), 4)
            end
        end
    end
    return NDSWaterCache.Level
end

local NDSSupportPart = nil

local function NDSHideSupport(destroy)
    if NDSSupportPart then
        if destroy then
            pcall(function() NDSSupportPart:Destroy() end)
            NDSSupportPart = nil
        else
            -- just park it far away (destroying/recreating every frame made it flicker)
            NDSSupportPart.CFrame = CFrame.new(0, -10000, 0)
        end
    end
end

local function NDSGetSupport()
    if not NDSSupportPart or not NDSSupportPart.Parent then
        local part = Instance.new("Part")
        part.Name = "ToxNDSSupport"
        part.Size = Vector3.new(6, 0.5, 6)
        part.Anchored = true
        part.CanCollide = true
        part.CanQuery = false
        part.CanTouch = false
        part.Transparency = 1
        part.Parent = workspace
        NDSSupportPart = part
    end
    return NDSSupportPart
end

local NDSSupportWarned = false
local function NDSSupportStep(delta)
    local wantRocks = Settings.NDSIslandRocksCollidable == true
    local wantWater = Settings.NDSWaterWalk == true and not Settings.NDSWaterFly
    if not wantRocks and not wantWater then
        NDSHideSupport(true)
        return
    end

    local character, humanoid, root = GetCharacterState()
    if not character or not humanoid or humanoid.Health <= 0 or not root then
        NDSHideSupport()
        return
    end

    local standOffset = 3
    if humanoid.RigType == Enum.HumanoidRigType.R15 then
        standOffset = humanoid.HipHeight + root.Size.Y / 2
    end

    local velocity = root.AssemblyLinearVelocity
    local reach = standOffset + 2.5 + math.max(0, -velocity.Y) * math.max(tonumber(delta) or 0.016, 0.016) * 2
    local feetY = root.Position.Y - standOffset
    local bestY = nil

    if wantRocks then
        if NDSRockListDirty then
            table.clear(NDSRockList)
            for object in pairs(NDSRockSet) do
                if object.Parent then
                    table.insert(NDSRockList, object)
                end
            end
            NDSRockListDirty = false
        end
        if #NDSRockList > 0 then
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Include
            params.FilterDescendantsInstances = NDSRockList
            local hit = workspace:Raycast(root.Position, Vector3.new(0, -reach, 0), params)
            if hit and feetY >= hit.Position.Y - 1 then
                bestY = hit.Position.Y
            end
        end
    end

    if wantWater then
        local surfaceY = NDSGetWaterLevel(root.Position, character)
        if surfaceY then
            -- Stand a bit ABOVE the water (legs out of it -> no swimming jitter).
            -- The support follows you at water level everywhere, so it also catches you
            -- when you walk off the island (under the island it is just below the ground).
            local surfaceTop = surfaceY + 1
            if feetY >= surfaceTop - 0.6 then
                bestY = math.max(bestY or -math.huge, surfaceTop)
            elseif feetY >= surfaceY - 6 then
                -- sunk a little: float up smoothly instead of popping out
                root.AssemblyLinearVelocity = Vector3.new(velocity.X, math.max(velocity.Y, 24), velocity.Z)
            end
        end
    end

    if bestY then
        NDSGetSupport().CFrame = CFrame.new(root.Position.X, bestY - 0.25, root.Position.Z)
    else
        NDSHideSupport()
    end
end

TrackNDSExtraConnection(RunService.Heartbeat:Connect(function(delta)
    local ok, err = pcall(NDSSupportStep, delta)
    if not ok and not NDSSupportWarned then
        NDSSupportWarned = true
        warn("[ToxHub] Walk on Water / Island Rocks error: " .. tostring(err))
        if CustomNotify then
            CustomNotify("Walk on Water / Rocks error (see F9)", Color3.fromRGB(255, 100, 100), 5)
        end
    end
end))

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


-- ==============================================================================
-- MUTE GAME SOUNDS: every game Sound goes to volume 0 (disasters, wind, music, alarms...).
-- Voice chat is not a Sound instance, so it keeps working. ToxHub's own sounds are kept.
-- ==============================================================================
local NDSMutedSounds = setmetatable({}, { __mode = "k" })

local function NDSIsToxSound(sound)
    local gui = getgenv().Gui
    if gui and sound:IsDescendantOf(gui) then
        return true
    end
    local current = sound.Parent
    while current and current ~= game do
        if string.sub(tostring(current.Name), 1, 3) == "Tox" then
            return true
        end
        current = current.Parent
    end
    return false
end

local function NDSMuteSound(sound)
    if not Settings.NDSMuteGameSounds or not sound:IsA("Sound") or NDSMutedSounds[sound] then
        return
    end
    local ok, isTox = pcall(NDSIsToxSound, sound)
    if not ok or isTox then
        return
    end
    local entry = { Volume = sound.Volume }
    NDSMutedSounds[sound] = entry
    pcall(function() sound.Volume = 0 end)
    -- the game often resets Volume when it plays a sound again
    entry.Conn = sound:GetPropertyChangedSignal("Volume"):Connect(function()
        if Settings.NDSMuteGameSounds and sound.Volume ~= 0 then
            entry.Volume = sound.Volume
            sound.Volume = 0
        end
    end)
end

local function SetNDSMuteGameSounds(enabled)
    Settings.NDSMuteGameSounds = enabled == true
    if Settings.NDSMuteGameSounds then
        for _, object in ipairs(game:GetDescendants()) do
            pcall(NDSMuteSound, object)
        end
    else
        for sound, entry in pairs(NDSMutedSounds) do
            if entry.Conn then pcall(function() entry.Conn:Disconnect() end) end
            if sound and sound.Parent then
                pcall(function() sound.Volume = entry.Volume end)
            end
            NDSMutedSounds[sound] = nil
        end
    end
end

-- ==============================================================================
-- CLEAN SCREEN: removes weather/disaster screen effects (fog, atmosphere haze, blur,
-- color tint, clouds, wind/rain/snow/sand particles). Restores everything when off.
-- ==============================================================================
local NDSCleanDefaults = setmetatable({}, { __mode = "k" })
local NDSCleanLighting = nil
local NDS_WEATHER_WORDS = { "wind", "rain", "snow", "blizzard", "sand", "dust", "fog", "storm", "cloud", "hail", "acid", "mist", "haze" }

local function NDSIsWeatherEffect(object)
    if not (object:IsA("ParticleEmitter") or object:IsA("Beam") or object:IsA("Trail")) then
        return false
    end
    local camera = workspace.CurrentCamera
    if camera and object:IsDescendantOf(camera) then
        return true   -- effects glued to the camera = screen effects
    end
    -- Weather emitters are often attached to YOUR character (sandstorm follows you).
    -- Inside a character only look at the names below the character model, so a player
    -- called "Sandra"/"Rainbow" doesn't count.
    local names = {}
    local current = object
    local depth = 0
    while current and current ~= game and depth < 8 do
        if current:IsA("Model") and Players:GetPlayerFromCharacter(current) then
            break
        end
        names[#names + 1] = string.lower(tostring(current.Name))
        current = current.Parent
        depth += 1
    end
    local path = table.concat(names, " ")
    for _, word in ipairs(NDS_WEATHER_WORDS) do
        if string.find(path, word, 1, true) then
            return true
        end
    end
    return false
end

local function NDSCleanSet(object, prop, value)
    local store = NDSCleanDefaults[object]
    if not store then
        store = {}
        NDSCleanDefaults[object] = store
    end
    if store[prop] == nil then
        store[prop] = object[prop]
    end
    if object[prop] ~= value then
        object[prop] = value
    end
end

local function NDSApplyCleanScreen()
    if not NDSCleanLighting then
        NDSCleanLighting = { FogEnd = Lighting.FogEnd, FogStart = Lighting.FogStart }
    end
    pcall(function()
        if Lighting.FogEnd < 100000 then Lighting.FogEnd = 100000 end
        if Lighting.FogStart < 100000 then Lighting.FogStart = 100000 end
    end)
    for _, object in ipairs(Lighting:GetChildren()) do
        if string.sub(object.Name, 1, 3) ~= "Tox" then
            pcall(function()
                if object:IsA("Atmosphere") then
                    -- thin the storm air but keep the normal sky look (not fullbright)
                    NDSCleanSet(object, "Density", math.min(object.Density, 0.3))
                    NDSCleanSet(object, "Haze", math.min(object.Haze, 1))
                    NDSCleanSet(object, "Glare", math.min(object.Glare, 1))
                elseif object:IsA("BlurEffect") or object:IsA("DepthOfFieldEffect") then
                    NDSCleanSet(object, "Enabled", false)
                elseif object:IsA("ColorCorrectionEffect") then
                    -- remove only strong disaster tints/darkening, keep the normal look
                    local tinted = object.TintColor.R < 0.9 or object.TintColor.G < 0.9 or object.TintColor.B < 0.9
                    if tinted or object.Brightness < -0.05 or object.Contrast > 0.3 then
                        NDSCleanSet(object, "Enabled", false)
                    end
                end
            end)
        end
    end
    pcall(function()
        local clouds = workspace.Terrain:FindFirstChildOfClass("Clouds")
        if clouds then NDSCleanSet(clouds, "Enabled", false) end
    end)
    -- every particle/beam/trail anywhere (map, disaster models, characters, camera)
    for _, object in ipairs(workspace:GetDescendants()) do
        if (object:IsA("ParticleEmitter") or object:IsA("Beam") or object:IsA("Trail"))
        and NDSIsWeatherEffect(object) then
            pcall(NDSCleanSet, object, "Enabled", false)
        end
    end

    -- Wind / sandstorm / rain "streak" walls: big non-collidable parts with scrolling
    -- textures around the map or glued to the camera. Hide the part and its textures.
    local characters = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then characters[#characters + 1] = p.Character end
    end
    local function IsCharacterPart(object)
        for _, character in ipairs(characters) do
            if object:IsDescendantOf(character) then return true end
        end
        return false
    end
    local function HideOverlayPart(part)
        pcall(NDSCleanSet, part, "LocalTransparencyModifier", 1)
        for _, child in ipairs(part:GetChildren()) do
            if child:IsA("Texture") or child:IsA("Decal") then
                pcall(NDSCleanSet, child, "Transparency", 1)
            elseif child:IsA("SurfaceGui") then
                pcall(NDSCleanSet, child, "Enabled", false)
            end
        end
    end
    local camera = workspace.CurrentCamera
    local scan = {}
    for _, child in ipairs(workspace:GetChildren()) do
        if child ~= workspace.Terrain and child:FindFirstChild("Humanoid") == nil then
            scan[#scan + 1] = child
        end
    end
    for _, top in ipairs(scan) do
        local list = top:IsA("BasePart") and { top } or {}
        if not top:IsA("BasePart") and top.Name ~= "Structure" then
            for _, d in ipairs(top:GetDescendants()) do
                if d:IsA("BasePart") then list[#list + 1] = d end
            end
        end
        for _, part in ipairs(list) do
            if not part.CanCollide and not IsCharacterPart(part) then
                local hasTexture = part:FindFirstChildWhichIsA("Texture") or part:FindFirstChildWhichIsA("Decal")
                local size = part.Size
                local huge = math.max(size.X, size.Y, size.Z) >= 150
                local path = NDSLowerPath(part)
                local weatherName = false
                for _, word in ipairs(NDS_WEATHER_WORDS) do
                    if string.find(path, word, 1, true) then weatherName = true break end
                end
                if (hasTexture and huge) or (weatherName and (hasTexture or part.Transparency < 1)) then
                    HideOverlayPart(part)
                end
            end
        end
    end
    if camera then
        for _, d in ipairs(camera:GetDescendants()) do
            if d:IsA("BasePart") then HideOverlayPart(d) end
        end
    end

    -- Screen overlays the game puts in the PlayerGui for weather (tint / dust images)
    local playerGui = Player:FindFirstChildOfClass("PlayerGui")
    if playerGui then
        for _, gui in ipairs(playerGui:GetChildren()) do
            if gui:IsA("ScreenGui") and string.sub(gui.Name, 1, 3) ~= "Tox" then
                local lower = string.lower(gui.Name)
                for _, word in ipairs(NDS_WEATHER_WORDS) do
                    if string.find(lower, word, 1, true) then
                        pcall(NDSCleanSet, gui, "Enabled", false)
                        break
                    end
                end
            end
        end
    end
end

local function SetNDSCleanScreen(enabled)
    Settings.NDSCleanScreen = enabled == true
    if Settings.NDSCleanScreen then
        NDSApplyCleanScreen()
    else
        for object, store in pairs(NDSCleanDefaults) do
            if object and object.Parent then
                for prop, value in pairs(store) do
                    pcall(function() object[prop] = value end)
                end
            end
            NDSCleanDefaults[object] = nil
        end
        if NDSCleanLighting then
            pcall(function()
                Lighting.FogEnd = NDSCleanLighting.FogEnd
                Lighting.FogStart = NDSCleanLighting.FogStart
            end)
            NDSCleanLighting = nil
        end
    end
end

do
    -- disasters change lighting/effects every round: re-apply twice a second
    local cleanClock = 0
    TrackNDSExtraConnection(RunService.Heartbeat:Connect(function(delta)
        if not Settings.NDSCleanScreen then
            return
        end
        cleanClock += math.max(tonumber(delta) or 0, 0)
        if cleanClock >= 1 then
            cleanClock = 0
            pcall(NDSApplyCleanScreen)
        end
    end))
end

local function NDSDetectDisaster(text)
    local raw = tostring(text or "")
    local lower = string.lower(raw):gsub("%s+", " "):match("^%s*(.-)%s*$")
    if not lower or #lower < 3 then
        return nil
    end

    -- Canonical name map (from SurvivalTag.Value)
    local canonical = {
        ["acid rain"] = "Acid Rain",
        ["blizzard"] = "Blizzard",
        ["deadly virus"] = "Deadly Virus",
        ["earthquake"] = "Earthquake",
        ["fire"] = "Fire",
        ["flash flood"] = "Flash Flood",
        ["meteor shower"] = "Meteor Shower",
        ["sandstorm"] = "Sandstorm",
        ["thunderstorm"] = "Thunderstorm",
        ["thunder storm"] = "Thunderstorm",
        ["tornado"] = "Tornado",
        ["tsunami"] = "Tsunami",
        ["volcanic eruption"] = "Volcanic Eruption"
    }

    if canonical[lower] then
        return canonical[lower]
    end

    -- Warning text pattern detection (from PlayerGui text labels and Status banner)
    if string.find(lower, "tsunami") or string.find(lower, "higher ground") or string.find(lower, "tidal wave") then
        return "Tsunami"
    elseif string.find(lower, "flash flood") or (string.find(lower, "flood") and not string.find(lower, "light")) then
        return "Flash Flood"
    elseif string.find(lower, "volcan") or string.find(lower, "eruption") or (string.find(lower, "lava") and not string.find(lower, "lamp")) then
        return "Volcanic Eruption"
    elseif string.find(lower, "meteor") then
        return "Meteor Shower"
    elseif string.find(lower, "tornado") or string.find(lower, "cyclone") or string.find(lower, "twister") then
        return "Tornado"
    elseif string.find(lower, "acid rain") or string.find(lower, "acidic") then
        return "Acid Rain"
    elseif string.find(lower, "deadly virus") or (string.find(lower, "virus") and not string.find(lower, "antivirus")) or string.find(lower, "infection") then
        return "Deadly Virus"
    elseif string.find(lower, "blizzard") or string.find(lower, "snow storm") or string.find(lower, "snowstorm") or string.find(lower, "freezing") then
        return "Blizzard"
    elseif string.find(lower, "sandstorm") or string.find(lower, "sand storm") then
        return "Sandstorm"
    elseif string.find(lower, "thunderstorm") or string.find(lower, "thunder storm") or string.find(lower, "lightning") then
        return "Thunderstorm"
    elseif string.find(lower, "earthquake") or string.find(lower, "tremor") then
        return "Earthquake"
    elseif string.find(lower, "fire disaster") or string.find(lower, "disaster fire") or (string.find(lower, "fire") and (string.find(lower, "spread") or string.find(lower, "flame") or string.find(lower, "extinguish") or string.find(lower, "burn"))) then
        return "Fire"
    end

    return nil
end

local function NDSNotifyDisaster(disaster, mapName)
    if not disaster then
        return
    end

    local key = tostring(disaster) .. "::" .. tostring(mapName or "")
    if NDSLastDisasterNotify == key then
        return
    end

    NDSCurrentDisaster = disaster
    if mapName and tostring(mapName) ~= "" and tostring(mapName) ~= "none" then
        NDSCurrentMap = tostring(mapName)
    end
    NDSLastDisasterNotify = key

    if CustomNotify then
        local msg = "Disaster: " .. tostring(disaster)
        if NDSCurrentMap and NDSCurrentMap ~= "" and NDSCurrentMap ~= "none" then
            msg = msg .. " • " .. tostring(NDSCurrentMap)
        end
        CustomNotify(
            msg,
            Color3.fromRGB(255, 190, 80),
            7
        )
    end
end

local function NDSScanDisasters()
    if not Settings.NDSNotifyDisasters then
        return
    end

    -- 1. Check LocalPlayer's SurvivalTag first (immediate RNG server selection upon round spawn)
    local myChar = Player.Character
    if myChar then
        local myTag = myChar:FindFirstChild("SurvivalTag")
        if myTag and myTag:IsA("StringValue") and myTag.Value ~= "" then
            local mapVal = myTag:FindFirstChild("MapName") and myTag.MapName.Value or NDSCurrentMap
            local detected = NDSDetectDisaster(myTag.Value)
            if detected then
                NDSNotifyDisaster(detected, mapVal)
                return
            end
        end
    end

    -- 2. Check PlayerGui.MainGui (Status label & official Disaster Warning banner)
    local pg = Player:FindFirstChildOfClass("PlayerGui")
    local mainGui = pg and pg:FindFirstChild("MainGui")
    if mainGui then
        local statusLabel = mainGui:FindFirstChild("Status")
        if statusLabel and statusLabel:IsA("TextLabel") and statusLabel.Visible then
            local text = tostring(statusLabel.Text or "")
            local lower = string.lower(text)
            if string.find(lower, "intermission") or string.find(lower, "waiting") or string.find(lower, "loading") then
                NDSCurrentDisaster = nil
                NDSCurrentMap = nil
                NDSLastDisasterNotify = ""
            else
                local detected = NDSDetectDisaster(text)
                if detected then
                    NDSNotifyDisaster(detected, NDSCurrentMap)
                    return
                end
            end
        end

        -- Check descendants of MainGui specifically (ignoring chat, ToxHub, foreign notifications)
        for _, obj in ipairs(mainGui:GetDescendants()) do
            if obj:IsA("TextLabel") and obj.Visible then
                local text = tostring(obj.Text or "")
                if #text > 4 then
                    local detected = NDSDetectDisaster(text)
                    if detected then
                        NDSNotifyDisaster(detected, NDSCurrentMap)
                        return
                    end
                end
            end
        end
    end

    -- 3. Spectator fallback: Only check players who are ALIVE and ON THE ISLAND (never AFK in lobby tower)
    local islandCenter = Vector3.new(-2, 45, 10)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Player and plr.Character then
            local char = plr.Character
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 and hrp.Position.Y < 120 and (hrp.Position - islandCenter).Magnitude < 400 then
                local tag = char:FindFirstChild("SurvivalTag")
                if tag and tag:IsA("StringValue") and tag.Value ~= "" then
                    local mapVal = tag:FindFirstChild("MapName") and tag.MapName.Value or NDSCurrentMap
                    local detected = NDSDetectDisaster(tag.Value)
                    if detected then
                        NDSNotifyDisaster(detected, mapVal)
                        return
                    end
                end
            end
        end
    end
end

local function HookCharacterForSurvivalTag(char)
    if not char then return end
    TrackNDSExtraConnection(char.ChildAdded:Connect(function(child)
        if child.Name == "SurvivalTag" and child:IsA("StringValue") then
            task.defer(function()
                local mapVal = child:FindFirstChild("MapName") and child.MapName.Value or NDSCurrentMap
                local detected = NDSDetectDisaster(child.Value)
                if detected then
                    NDSNotifyDisaster(detected, mapVal)
                end
            end)
            TrackNDSExtraConnection(child.Changed:Connect(function()
                local mapVal = child:FindFirstChild("MapName") and child.MapName.Value or NDSCurrentMap
                local detected = NDSDetectDisaster(child.Value)
                if detected then
                    NDSNotifyDisaster(detected, mapVal)
                end
            end))
        end
    end))
    TrackNDSExtraConnection(char.ChildRemoved:Connect(function(child)
        if child.Name == "SurvivalTag" then
            NDSCurrentDisaster = nil
            NDSCurrentMap = nil
            NDSLastDisasterNotify = ""
        end
    end))

    local existing = char:FindFirstChild("SurvivalTag")
    if existing and existing:IsA("StringValue") then
        local mapVal = existing:FindFirstChild("MapName") and existing.MapName.Value or NDSCurrentMap
        local detected = NDSDetectDisaster(existing.Value)
        if detected then
            NDSNotifyDisaster(detected, mapVal)
        end
    end
end

if Player.Character then
    HookCharacterForSurvivalTag(Player.Character)
end
TrackNDSExtraConnection(Player.CharacterAdded:Connect(HookCharacterForSurvivalTag))

local function HookNDSMainGui()
    local pg = Player:FindFirstChildOfClass("PlayerGui")
    if not pg then return end
    local mainGui = pg:FindFirstChild("MainGui")
    if not mainGui then return end

    local status = mainGui:FindFirstChild("Status")
    if status and status:IsA("TextLabel") then
        TrackNDSExtraConnection(status:GetPropertyChangedSignal("Text"):Connect(function()
            local text = tostring(status.Text or "")
            local lower = string.lower(text)
            if string.find(lower, "intermission") or string.find(lower, "waiting") or string.find(lower, "loading") then
                NDSCurrentDisaster = nil
                NDSCurrentMap = nil
                NDSLastDisasterNotify = ""
            else
                local detected = NDSDetectDisaster(text)
                if detected then
                    NDSNotifyDisaster(detected, NDSCurrentMap)
                end
            end
        end))
    end
end

task.defer(HookNDSMainGui)
local pgObj = Player:FindFirstChildOfClass("PlayerGui")
if pgObj then
    TrackNDSExtraConnection(pgObj.ChildAdded:Connect(function(child)
        if child.Name == "MainGui" then
            task.defer(HookNDSMainGui)
        end
    end))
end

local function SetNDSNotifyDisasters(enabled)
    Settings.NDSNotifyDisasters = enabled == true
    NDSCurrentDisaster = nil
    NDSCurrentMap = nil
    NDSLastDisasterNotify = ""
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

    -- Only the current round map (workspace.Structure). Scanning all of workspace also
    -- fired the lobby prompts/click detectors (shop menus, ad video, etc).
    local map = workspace:FindFirstChild("Structure")
    if not map then
        if CustomNotify then
            CustomNotify("No map loaded • wait for the round", Color3.fromRGB(255, 180, 70), 4)
        end
        return
    end

    for _, object in ipairs(map:GetDescendants()) do
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
end))

-- Virus effects are often created first and renamed/parented later, so DescendantAdded
-- misses them: rescan the likely places every 1.5s while the option is on.
do
    local virusClock = 0
    TrackNDSExtraConnection(RunService.Heartbeat:Connect(function(delta)
        if not Settings.NDSRemoveVirusParticles then
            return
        end
        virusClock += math.max(tonumber(delta) or 0, 0)
        if virusClock < 1.5 then
            return
        end
        virusClock = 0
        local roots = { workspace:FindFirstChild("Structure"), workspace.CurrentCamera }
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character then
                table.insert(roots, p.Character)
            end
        end
        for _, rootObj in ipairs(roots) do
            if rootObj then
                for _, object in ipairs(rootObj:GetDescendants()) do
                    NDSApplyHazardObject("VirusParticles", object)
                end
            end
        end
        for _, object in ipairs(workspace:GetChildren()) do
            NDSApplyHazardObject("VirusParticles", object)
            if object:IsA("Model") or object:IsA("Folder") then
                local lower = string.lower(object.Name)
                if string.find(lower, "virus", 1, true) or string.find(lower, "infect", 1, true) then
                    for _, d in ipairs(object:GetDescendants()) do
                        NDSApplyHazardObject("VirusParticles", d)
                    end
                end
            end
        end
    end))
end

TrackNDSExtraConnection(game.DescendantAdded:Connect(function(object)
    if Settings.NDSCleanScreen
    and (object:IsA("ParticleEmitter") or object:IsA("Beam") or object:IsA("Trail")) then
        task.defer(function()
            if Settings.NDSCleanScreen and object.Parent and NDSIsWeatherEffect(object) then
                pcall(NDSCleanSet, object, "Enabled", false)
            end
        end)
    end
    if Settings.NDSMuteGameSounds and object:IsA("Sound") then
        task.defer(function() pcall(NDSMuteSound, object) end)
    end
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

local lastNDSUITime = 0
TrackNDSExtraConnection(RunService.Heartbeat:Connect(function()
    if not Settings.UltraInstinct or not Player or not Player.Character then
        return
    end

    -- Combat module already runs Ultra Instinct (with the ground circle); avoid double teleports
    if getgenv().ToxCombatLoaded and type(getgenv().ToxUltraInstinctStep) == "function" then
        return
    end

    local myHrp = Player.Character:FindFirstChild("HumanoidRootPart")
    local myHum = Player.Character:FindFirstChildOfClass("Humanoid")
    local sharedLast = tonumber(getgenv().ToxLastUltraInstinctTime) or 0
    if not myHrp or not myHum or myHum.Health <= 0 or (os.clock() - math.max(lastNDSUITime, sharedLast) < 0.18) then
        return
    end

    local detectRange = tonumber(Settings.UltraInstinctRange) or 14
    local closestThreat = nil
    local closestDist = detectRange

    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= Player and otherPlayer.Character then
            local otherHrp = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
            local otherHum = otherPlayer.Character:FindFirstChildOfClass("Humanoid")
            if otherHrp and otherHum and otherHum.Health > 0 then
                local dist = (otherHrp.Position - myHrp.Position).Magnitude
                if dist <= closestDist then
                    closestDist = dist
                    closestThreat = otherHrp
                end
            end
        end
    end

    if closestThreat then
        local getSafeCF = getgenv().GetSafeUltraInstinctCFrame
        local safeCFrame = getSafeCF and getSafeCF(myHrp, closestThreat, detectRange)
        if safeCFrame then
            lastNDSUITime = os.clock()
            getgenv().ToxLastUltraInstinctTime = lastNDSUITime
            if getgenv().AllowToxTeleport then
                getgenv().AllowToxTeleport(1.0, "Ultra Instinct")
            end
            if getgenv().SetNDSNoTPAnchor then
                getgenv().SetNDSNoTPAnchor(safeCFrame, true)
            end

            myHrp.AssemblyLinearVelocity = Vector3.zero
            myHrp.AssemblyAngularVelocity = Vector3.zero
            Player.Character:PivotTo(safeCFrame)
            myHrp.CFrame = safeCFrame

            pcall(function()
                local s = Instance.new("Sound")
                s.SoundId = "rbxassetid://3398620867"
                s.Volume = 0.5
                s.Parent = myHrp
                s:Play()
                game:GetService("Debris"):AddItem(s, 1)
            end)
        end
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

-- % = how fast you can fall (0% = very slow float, 100% = almost normal fall)
NDSCreateToggleWithSlider("No Fall Damage", GamePage, 0, 100, Settings.NoFallDamage, Settings.NoFallSpeed or 50, "%", function(v)
    SetShared("NoFallDamage", v)
end, function(val)
    Settings.NoFallSpeed = math.clamp(tonumber(val) or 50, 0, 100)
    if getgenv().SyncValueVisuals then
        getgenv().SyncValueVisuals("NoFallDamage", Settings.NoFallSpeed)
    end
end, "NoFallDamage")

NDSCreateToggle("Anti Void", GamePage, Settings.AntiVoid, function(v)
    SetShared("AntiVoid", v)
end, "AntiVoid")

CreateNDSSection("MOVEMENT")

NDSCreateToggleWithSlider("Water Fly", GamePage, 5, 250, Settings.NDSWaterFly, Settings.NDSWaterFlySpeed, "", function(v)
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

NDSCreateToggle("Walk on Water", GamePage, Settings.NDSWaterWalk == true, function(v)
    -- Invisible flat support on the water surface under your feet (turn off to swim)
    Settings.NDSWaterWalk = v == true
end, "NDSWaterWalk")

NDSCreateToggleWithSlider("Fly Bypass", GamePage, 0, 100, Settings.FlyBypass, Settings.FlySpeed or 10, "", function(v)
    SetShared("FlyBypass", v)
end, function(value)
    Settings.FlySpeed = math.max(tonumber(value) or 10, 0)

    if SyncValueVisuals then
        SyncValueVisuals("FlyBypass", Settings.FlySpeed)
    end
end, "FlyBypass")

NDSCreateToggleWithSlider("Car Fly", GamePage, 5, 300, Settings.CarFly, Settings.CarFlySpeed, "", function(v)
    SetShared("CarFly", v)
end, function(value)
    Settings.CarFlySpeed = math.clamp(tonumber(value) or 80, 5, 300)

    if SyncValueVisuals then
        SyncValueVisuals("CarFly", Settings.CarFlySpeed)
    end
end, "CarFly")

NDSCreateToggle("Ctrl Click TP", GamePage, Settings.CtrlClickTP, function(v)
    SetShared("CtrlClickTP", v)
end, "CtrlClickTP")

CreateNDSSection("FLING")

NDSCreateToggleWithSlider("Walk Fling", GamePage, 1, 100, Settings.WalkFling, Settings.WalkFlingPower or 30, "%", function(v)
    SetShared("WalkFling", v)

    if v then
        StartNDSNoFall()
    elseif not Settings.NoFallDamage then
        StopNDSNoFall()
    end
end, function(val)
    Settings.WalkFlingPower = tonumber(val) or 30
    if getgenv().ToxOnSharedValueChanged then
        getgenv().ToxOnSharedValueChanged("WalkFling", val)
    end
end, "WalkFling")

NDSCreateToggle("Anti Fling", GamePage, Settings.AntiFling, function(v)
    SetShared("AntiFling", v)
end, "AntiFling")

NDSCreateToggleWithSlider("Ultra Instinct", GamePage, 5, 50, Settings.UltraInstinct, Settings.UltraInstinctRange or 14, " studs", function(v)
    SetShared("UltraInstinct", v)
end, function(val)
    Settings.UltraInstinctRange = tonumber(val) or 14
    if getgenv().ToxOnSharedValueChanged then
        getgenv().ToxOnSharedValueChanged("UltraInstinctRange", val)
    end
end, "UltraInstinct")

-- Walks away from nearby players (logic lives in Universal/Combat.lua)
NDSCreateToggleWithSlider("Anti Social", GamePage, 5, 60, Settings.AntiSocial == true, Settings.AntiSocialRange or 20, " studs", function(v)
    Settings.AntiSocial = v == true
    if SyncToggleVisuals then
        SyncToggleVisuals("AntiSocial", Settings.AntiSocial)
    end
    if AutoSaveConfiguration then
        AutoSaveConfiguration()
    end
end, function(val)
    Settings.AntiSocialRange = tonumber(val) or 20
    if SyncValueVisuals then
        SyncValueVisuals("AntiSocial", Settings.AntiSocialRange)
    end
end, "AntiSocial")

CreateNDSSection("DISASTERS")

NDSCreateToggle("Notify Disasters", GamePage, Settings.NDSNotifyDisasters, function(v)
    SetNDSNotifyDisasters(v)
end, "NDSNotifyDisasters")

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

CreateNDSSection("ISLAND")

NDSCreateToggle("Island Rocks Collidable", GamePage, Settings.NDSIslandRocksCollidable, function(v)
    SetNDSIslandRocksCollidable(v)
end, "NDSIslandRocksCollidable")

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

do
    local createButton = CreateButton or (getgenv and getgenv().CreateButton)
    if createButton then
        TrackNDSControl(createButton("Tox Magnet", GamePage, function()
            local magnet = getgenv().ToxMagnetGui
            if magnet then
                magnet.Visible = not magnet.Visible
            end
        end))
    end
end

NDSCreateToggle("Mute Game Sounds", GamePage, Settings.NDSMuteGameSounds == true, function(v)
    -- every game sound (disasters, wind, alarms...). Voice chat keeps working.
    SetNDSMuteGameSounds(v)
end, "NDSMuteGameSounds")

NDSCreateToggle("Clean Screen", GamePage, Settings.NDSCleanScreen == true, function(v)
    -- no fog / haze / blur / tint / clouds / wind-rain-snow-sand particles
    SetNDSCleanScreen(v)
end, "NDSCleanScreen")

CreateNDSSection("TELEPORTS")

NDSCreateButton("SPAWN", GamePage, function()
    TeleportTo(SpawnCFrame, "SPAWN")
end)

NDSCreateButton("ISLAND", GamePage, function()
    TeleportTo(IslandCFrame, "ISLAND")
end)

NDSCreateButton("Tower Safe Spot", GamePage, function()
    TeleportTo(CFrame.new(-262, 205, 313), "Tower Safe Spot")
end)

NDSCreateButton("Quick Rejoin (Instant Reset)", GamePage, function()
    local ts = game:GetService("TeleportService")
    if ts and game.PlaceId then
        if CustomNotify then
            CustomNotify("Reconectando ao servidor...", Color3.fromRGB(0, 168, 255), 3)
        end
        if game.JobId and game.JobId ~= "" then
            pcall(function()
                ts:TeleportToPlaceInstance(game.PlaceId, game.JobId, Player)
            end)
        else
            pcall(function()
                ts:Teleport(game.PlaceId, Player)
            end)
        end
    end
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

if Settings.NDSMuteGameSounds then
    SetNDSMuteGameSounds(true)
end

if Settings.NDSCleanScreen then
    SetNDSCleanScreen(true)
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

        pcall(function()
            SetNDSMuteGameSounds(false)
            SetNDSCleanScreen(false)
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
