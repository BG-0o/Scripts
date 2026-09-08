if game.PlaceId ~= 189707 then
    return
end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Settings = getgenv().Settings
local GamePage = getgenv().GamePage
local CreateToggle = getgenv().CreateToggle
local AddConnection = getgenv().AddConnection
local CustomNotify = getgenv().CustomNotify
local AutoSaveConfiguration = getgenv().AutoSaveConfiguration
local SyncToggleVisuals = getgenv().SyncToggleVisuals

if not Settings or not GamePage or not CreateToggle then
    return
end

local AutoWinConnection = nil
local AutoWinPlatform = nil
local AutoWinReturnCFrame = nil
local AutoWinSafeCFrame = nil

local WaterFlyConnection = nil
local WaterFlyVelocity = nil
local WaterFlyGyro = nil

local NoFallGeneration = 0

local NoTPConnection = nil
local NoTPLastCharacter = nil
local NoTPLastCFrame = nil

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

local function DestroyAutoWinPlatform()
    if AutoWinPlatform then
        AutoWinPlatform:Destroy()
        AutoWinPlatform = nil
    end
end

local function StopAutoWin(RestorePosition)
    if AutoWinConnection then
        AutoWinConnection:Disconnect()
        AutoWinConnection = nil
    end

    DestroyAutoWinPlatform()

    if RestorePosition and AutoWinReturnCFrame then
        local _, humanoid, root = GetCharacterState()

        if humanoid and humanoid.Health > 0 and root then
            AllowToxTeleport(1.5)
            root.CFrame = AutoWinReturnCFrame
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end
    end

    AutoWinSafeCFrame = nil
    AutoWinReturnCFrame = nil
end

local function StartAutoWin()
    StopAutoWin(false)

    local _, humanoid, root = GetCharacterState()

    if root then
        AutoWinReturnCFrame = root.CFrame
        AutoWinSafeCFrame = CFrame.new(root.Position.X, 2500, root.Position.Z)
    end

    AutoWinPlatform = Instance.new("Part")
    AutoWinPlatform.Name = "ToxNDSAutoWinPlatform"
    AutoWinPlatform.Size = Vector3.new(24, 1, 24)
    AutoWinPlatform.Anchored = true
    AutoWinPlatform.CanCollide = true
    AutoWinPlatform.Transparency = 1
    AutoWinPlatform.Parent = workspace

    AutoWinConnection = AddConnection(RunService.Heartbeat:Connect(function()
        if not Settings.NDSAutoWin then
            return
        end

        local _, currentHumanoid, currentRoot = GetCharacterState()

        if not currentHumanoid or currentHumanoid.Health <= 0 or not currentRoot then
            return
        end

        if not AutoWinSafeCFrame then
            AutoWinReturnCFrame = currentRoot.CFrame
            AutoWinSafeCFrame = CFrame.new(currentRoot.Position.X, 2500, currentRoot.Position.Z)
        end

        if AutoWinPlatform then
            AutoWinPlatform.CFrame = AutoWinSafeCFrame * CFrame.new(0, -3.5, 0)
        end

        if (currentRoot.Position - AutoWinSafeCFrame.Position).Magnitude > 8 then
            AllowToxTeleport(0.25)
            currentRoot.CFrame = AutoWinSafeCFrame
        end

        currentRoot.AssemblyLinearVelocity = Vector3.zero
        currentRoot.AssemblyAngularVelocity = Vector3.zero
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
        WaterFlyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        WaterFlyVelocity.P = 1250
        WaterFlyVelocity.Velocity = Vector3.zero
        WaterFlyVelocity.Parent = root
    end

    if not WaterFlyGyro or WaterFlyGyro.Parent ~= root then
        if WaterFlyGyro then WaterFlyGyro:Destroy() end

        WaterFlyGyro = Instance.new("BodyGyro")
        WaterFlyGyro.Name = "ToxNDSWaterFlyGyro"
        WaterFlyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        WaterFlyGyro.P = 4000
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

        local direction = Vector3.zero
        local look = Camera.CFrame.LookVector
        local right = Camera.CFrame.RightVector

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then direction += look end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then direction -= look end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then direction += right end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then direction -= right end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) or UserInputService:IsKeyDown(Enum.KeyCode.E) then direction += Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.Q) then direction -= Vector3.new(0, 1, 0) end

        local speed = math.max(45, (tonumber(Settings.FlySpeed) or 10) * 5)

        if direction.Magnitude > 0 then
            WaterFlyVelocity.Velocity = direction.Unit * speed
        else
            WaterFlyVelocity.Velocity = Vector3.zero
        end

        local flatLook = Vector3.new(look.X, 0, look.Z)

        if flatLook.Magnitude > 0.01 then
            WaterFlyGyro.CFrame = CFrame.lookAt(root.Position, root.Position + flatLook.Unit)
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

            if Settings.NDSWaterFly or Settings.NDSAutoWin then
                continue
            end

            local character, humanoid, root = GetCharacterState()

            if character and humanoid and humanoid.Health > 0 and root then
                local velocity = root.AssemblyLinearVelocity
                root.AssemblyLinearVelocity = Vector3.zero
                RunService.RenderStepped:Wait()

                if generation == NoFallGeneration
                and Settings.NoFallDamage
                and root
                and root.Parent
                and root:IsDescendantOf(character) then
                    root.AssemblyLinearVelocity = velocity
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

local function StopNoTP()
    if NoTPConnection then
        NoTPConnection:Disconnect()
        NoTPConnection = nil
    end

    NoTPLastCharacter = nil
    NoTPLastCFrame = nil
end

local function StartNoTP()
    StopNoTP()

    NoTPConnection = AddConnection(RunService.Heartbeat:Connect(function()
        if not Settings.NDSNoTP then
            return
        end

        local character, humanoid, root = GetCharacterState()

        if not character or not humanoid or humanoid.Health <= 0 or not root then
            NoTPLastCharacter = character
            NoTPLastCFrame = nil
            return
        end

        if NoTPLastCharacter ~= character then
            NoTPLastCharacter = character
            NoTPLastCFrame = root.CFrame
            return
        end

        local bypassUntil = tonumber(getgenv().ToxTeleportBypassUntil) or 0

        if tick() < bypassUntil then
            NoTPLastCFrame = root.CFrame
            return
        end

        if Settings.NDSAutoWin then
            NoTPLastCFrame = root.CFrame
            return
        end

        if not NoTPLastCFrame then
            NoTPLastCFrame = root.CFrame
            return
        end

        local distance = (root.Position - NoTPLastCFrame.Position).Magnitude

        if distance > 70 then
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            root.CFrame = NoTPLastCFrame
        else
            NoTPLastCFrame = root.CFrame
        end
    end))
end

CreateToggle("Auto Win", GamePage, Settings.NDSAutoWin, function(v)
    Settings.NDSAutoWin = v

    if v then
        StartAutoWin()
    else
        StopAutoWin(true)
    end
end, "NDSAutoWin")

CreateToggle("No Fall Damage", GamePage, Settings.NoFallDamage, function(v)
    SetShared("NoFallDamage", v)
end, "NoFallDamage")

CreateToggle("Water Fly", GamePage, Settings.NDSWaterFly, function(v)
    getgenv().SetNDSWaterFly(v, true)
end, "NDSWaterFly")

CreateToggle("Noclip", GamePage, Settings.Noclip, function(v)
    SetShared("Noclip", v)
end, "Noclip")

CreateToggle("Car Fly", GamePage, Settings.CarFly, function(v)
    SetShared("CarFly", v)
end, "CarFly")

CreateToggle("Anti Void", GamePage, Settings.AntiVoid, function(v)
    SetShared("AntiVoid", v)
end, "AntiVoid")

CreateToggle("Anti Fling", GamePage, Settings.AntiFling, function(v)
    SetShared("AntiFling", v)
end, "AntiFling")

CreateToggle("Ctrl Click TP", GamePage, Settings.CtrlClickTP, function(v)
    SetShared("CtrlClickTP", v)
end, "CtrlClickTP")

CreateToggle("No TP", GamePage, Settings.NDSNoTP, function(v)
    Settings.NDSNoTP = v

    if v then
        StartNoTP()
    else
        StopNoTP()
    end
end, "NDSNoTP")

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
    StartNoTP()
end
