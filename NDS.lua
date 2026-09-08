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

if not Settings or not GamePage or not CreateToggle or not CreateToggleWithValue or not CreateButton then
    return
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
local AutoWinCFrame = CFrame.new(-279.846, 166.742, 341.409)

local WaterFlyConnection = nil
local WaterFlyVelocity = nil
local WaterFlyGyro = nil

local NoFallGeneration = 0

local NoTPConnection = nil
local NoTPCharacterConnection = nil
local NoTPAnchorCFrame = nil
local NoTPCurrentCharacter = nil

local SpawnCFrame = CFrame.new(-278.442841, 179.499985, 344.097626)
local IslandCFrame = CFrame.new(-133.347427, 47.399998, 4.539609)

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

    PressHotbarTwo()
    task.wait(0.06)

    local equipped = character:FindFirstChildOfClass("Tool")

    if equipped then
        return equipped
    end

    local apple = FindAppleByName and FindAppleByName()

    if apple and apple:IsA("Tool") then
        pcall(function()
            humanoid:EquipTool(apple)
        end)

        task.wait(0.04)

        return character:FindFirstChildOfClass("Tool")
            or apple
    end

    return nil
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

    if tick() - AutoWinLastEquip >= 0.45 then
        AutoWinLastEquip = tick()
        PressHotbarTwo()
        task.wait(0.055)
    end

    local equipped =
        character:FindFirstChildOfClass("Tool")

    if equipped then
        tool = equipped
        AutoWinTool = equipped
        AutoWinToolName = equipped.Name
    elseif tool and tool:IsA("Tool") then
        pcall(function()
            humanoid:EquipTool(tool)
        end)

        task.wait(0.04)
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

local function StopAutoWin()
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
            PressHotbarTwo()
            task.wait(0.05)
            tool = FindAutoWinTool() or tool

            if tool.Parent ~= character then
                pcall(function()
                    currentHumanoid:EquipTool(tool)
                end)
            end
        end

        if tool
        and tool.Parent
        and tick() - AutoWinLastActivate >= 0.85 then
            AutoWinLastActivate = tick()
            ClickAutoWinTool(tool)
        end
    end))
end

local function DestroyWaterFlyMovers()
    if WaterFlyVelocity then
        WaterFlyVelocity:Destroy()
        WaterFlyVelocity = nil
    end

    if WaterFlyGyro then
        WaterFlyGyro:Destroy()
        WaterFlyGyro = nil
    end
end

local function StopWaterFly()
    if WaterFlyConnection then
        WaterFlyConnection:Disconnect()
        WaterFlyConnection = nil
    end

    DestroyWaterFlyMovers()

    local _, humanoid = GetCharacterState()

    if humanoid and humanoid.Health > 0 then
        pcall(function()
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end)
    end
end

local function EnsureWaterFlyMovers(root)
    if not WaterFlyVelocity or WaterFlyVelocity.Parent ~= root then
        if WaterFlyVelocity then WaterFlyVelocity:Destroy() end

        WaterFlyVelocity = Instance.new("BodyVelocity")
        WaterFlyVelocity.Name = "ToxNDSWaterFlyVelocity"
        WaterFlyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        WaterFlyVelocity.P = 2500
        WaterFlyVelocity.Velocity = Vector3.zero
        WaterFlyVelocity.Parent = root
    end

    if not WaterFlyGyro or WaterFlyGyro.Parent ~= root then
        if WaterFlyGyro then WaterFlyGyro:Destroy() end

        WaterFlyGyro = Instance.new("BodyGyro")
        WaterFlyGyro.Name = "ToxNDSWaterFlyGyro"
        WaterFlyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        WaterFlyGyro.P = 3500
        WaterFlyGyro.D = 350
        WaterFlyGyro.CFrame = root.CFrame
        WaterFlyGyro.Parent = root
    end
end

local function StartWaterFly()
    StopWaterFly()

    SetShared("SmoothFly", false)
    SetShared("NormalFly", false)

    WaterFlyConnection = AddConnection(RunService.RenderStepped:Connect(function()
        if not Settings.NDSWaterFly then
            return
        end

        local _, humanoid, root = GetCharacterState()

        if not humanoid or humanoid.Health <= 0 or not root then
            DestroyWaterFlyMovers()
            return
        end

        EnsureWaterFlyMovers(root)

        pcall(function()
            humanoid.Sit = false
            humanoid:ChangeState(Enum.HumanoidStateType.Swimming)
        end)

        local look = Camera.CFrame.LookVector
        local right = Camera.CFrame.RightVector
        local flatLook = Vector3.new(look.X, 0, look.Z)
        local flatRight = Vector3.new(right.X, 0, right.Z)
        local direction = Vector3.zero

        if flatLook.Magnitude > 0 then flatLook = flatLook.Unit end
        if flatRight.Magnitude > 0 then flatRight = flatRight.Unit end

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then direction += flatLook end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then direction -= flatLook end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then direction += flatRight end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then direction -= flatRight end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) or UserInputService:IsKeyDown(Enum.KeyCode.E) then direction += Vector3.new(0, 0.65, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.Q) then direction -= Vector3.new(0, 0.65, 0) end

        local speed = math.clamp(
            tonumber(Settings.NDSWaterFlySpeed) or 40,
            5,
            250
        )

        if direction.Magnitude > 0 then
            WaterFlyVelocity.Velocity = direction.Unit * speed
        else
            WaterFlyVelocity.Velocity = Vector3.zero
        end

        if flatLook.Magnitude > 0.01 then
            WaterFlyGyro.CFrame = CFrame.lookAt(root.Position, root.Position + flatLook)
        end
    end))
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
        and Settings.NoFallDamage
        and not getgenv().Destroyed do
            RunService.Heartbeat:Wait()

            if Settings.NDSWaterFly then
                continue
            end

            local character, humanoid, root = GetCharacterState()

            if character and humanoid and humanoid.Health > 0 and root then
                local velocity = root.AssemblyLinearVelocity

                if velocity.Y < -60 then
                    root.AssemblyLinearVelocity = Vector3.new(velocity.X, -45, velocity.Z)
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

local function RestoreNoTPCharacter(character)
    if game.PlaceId ~= NDSPlaceId
    or not Settings.NDSNoTP
    or not NoTPAnchorCFrame then
        return
    end

    task.spawn(function()
        local root = character:WaitForChild("HumanoidRootPart", 8)
        local humanoid = character:FindFirstChildOfClass("Humanoid")

        if not root or not humanoid then
            return
        end

        for _ = 1, 6 do
            if not Settings.NDSNoTP or not character.Parent or humanoid.Health <= 0 then
                return
            end

            local bypassUntil = tonumber(getgenv().ToxTeleportBypassUntil) or 0

            if tick() >= bypassUntil and NoTPAnchorCFrame then
                local distance = (root.Position - NoTPAnchorCFrame.Position).Magnitude

                if distance > 20 then
                    root.AssemblyLinearVelocity = Vector3.zero
                    root.AssemblyAngularVelocity = Vector3.zero
                    root.CFrame = NoTPAnchorCFrame
                end
            end

            task.wait(0.25)
        end
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

    NoTPAnchorCFrame = nil
    NoTPCurrentCharacter = nil
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

    local character, humanoid, root = GetCharacterState()

    if root and humanoid and humanoid.Health > 0 and not NoTPAnchorCFrame then
        NoTPAnchorCFrame = root.CFrame
        NoTPCurrentCharacter = character
    end

    NoTPCharacterConnection = AddConnection(Player.CharacterAdded:Connect(function(newCharacter)
        NoTPCurrentCharacter = newCharacter
        RestoreNoTPCharacter(newCharacter)
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

        local bypassUntil = tonumber(getgenv().ToxTeleportBypassUntil) or 0

        if tick() < bypassUntil then
            NoTPAnchorCFrame = currentRoot.CFrame
            return
        end

        if not NoTPAnchorCFrame then
            NoTPAnchorCFrame = currentRoot.CFrame
            return
        end

        local distance = (currentRoot.Position - NoTPAnchorCFrame.Position).Magnitude

        if distance > 28 then
            currentRoot.AssemblyLinearVelocity = Vector3.zero
            currentRoot.AssemblyAngularVelocity = Vector3.zero
            currentRoot.CFrame = NoTPAnchorCFrame
        else
            NoTPAnchorCFrame = currentRoot.CFrame
        end
    end))
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

CreateButton("SPAWN", GamePage, function()
    TeleportTo(SpawnCFrame, "SPAWN")
end)

CreateButton("ISLAND", GamePage, function()
    TeleportTo(IslandCFrame, "ISLAND")
end)

CreateToggle("Auto Win", GamePage, Settings.NDSAutoWin, function(v)
    Settings.NDSAutoWin = v

    if v then
        StartAutoWin()
    else
        StopAutoWin()
    end
end, "NDSAutoWin")

CreateToggle("Ctrl Click TP", GamePage, Settings.CtrlClickTP, function(v)
    SetShared("CtrlClickTP", v)
end, "CtrlClickTP")

CreateToggle("No TP", GamePage, Settings.NDSNoTP, function(v)
    getgenv().SetNDSNoTP(v, true)
end, "NDSNoTP")

CreateToggle("Noclip", GamePage, Settings.Noclip, function(v)
    SetShared("Noclip", v)
end, "Noclip")

CreateToggleWithValue("Water Fly", GamePage, Settings.NDSWaterFly, Settings.NDSWaterFlySpeed, function(v)
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

CreateToggleWithValue("Car Fly", GamePage, Settings.CarFly, Settings.CarFlySpeed, function(v)
    SetShared("CarFly", v)
end, function(value)
    Settings.CarFlySpeed = math.clamp(tonumber(value) or 80, 5, 300)

    if SyncValueVisuals then
        SyncValueVisuals("CarFly", Settings.CarFlySpeed)
    end
end, "CarFly")

CreateToggle("No Fall Damage", GamePage, Settings.NoFallDamage, function(v)
    SetShared("NoFallDamage", v)
end, "NoFallDamage")

CreateToggle("Anti Void", GamePage, Settings.AntiVoid, function(v)
    SetShared("AntiVoid", v)
end, "AntiVoid")

CreateToggle("Anti Fling", GamePage, Settings.AntiFling, function(v)
    SetShared("AntiFling", v)
end, "AntiFling")

if Settings.NDSAutoWin then
    StartAutoWin()
end

if Settings.NoFallDamage then
    StartNDSNoFall()
end

if Settings.NDSWaterFly then
    StartWaterFly()
end

if Settings.NDSNoTP then
    getgenv().SetNDSNoTP(true, true)
else
    StopNoTP()
end
