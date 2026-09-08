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

Settings.NDSWaterFlySpeed = tonumber(Settings.NDSWaterFlySpeed) or 12

local AutoWinConnection = nil
local AutoWinLastActivate = 0
local AutoWinTool = nil

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

local function FindAppleTool()
    local character = Player.Character
    local backpack = Player:FindFirstChildOfClass("Backpack")
    local candidates = {}
    local seen = {}

    local function scan(container)
        if not container then
            return
        end

        for _, child in ipairs(container:GetChildren()) do
            if child:IsA("Tool") and not seen[child] then
                seen[child] = true
                table.insert(candidates, child)

                local lowerName = string.lower(child.Name)

                if string.find(lowerName, "apple", 1, true)
                or string.find(lowerName, "maca", 1, true)
                or string.find(lowerName, "maç", 1, true)
                or string.find(lowerName, "heal", 1, true) then
                    return child
                end
            end
        end
    end

    local direct = scan(character)
    if direct then return direct end

    direct = scan(backpack)
    if direct then return direct end

    if AutoWinTool and AutoWinTool.Parent and AutoWinTool:IsA("Tool") then
        return AutoWinTool
    end

    if #candidates >= 2 then
        return candidates[2]
    end

    return candidates[1]
end

local function StopAutoWin()
    if AutoWinConnection then
        AutoWinConnection:Disconnect()
        AutoWinConnection = nil
    end

    AutoWinTool = nil
    AutoWinLastActivate = 0
end

local function StartAutoWin()
    StopAutoWin()

    AutoWinConnection = AddConnection(RunService.Heartbeat:Connect(function()
        if not Settings.NDSAutoWin then
            return
        end

        local character, humanoid = GetCharacterState()

        if not character or not humanoid or humanoid.Health <= 0 then
            return
        end

        local tool = FindAppleTool()

        if not tool then
            return
        end

        AutoWinTool = tool

        if tool.Parent ~= character then
            pcall(function()
                humanoid:EquipTool(tool)
            end)
        end

        if tool.Parent == character
        and humanoid.Health < humanoid.MaxHealth
        and tick() - AutoWinLastActivate >= 0.28 then
            AutoWinLastActivate = tick()

            pcall(function()
                tool:Activate()
            end)
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
        WaterFlyVelocity.MaxForce = Vector3.new(65000, 65000, 65000)
        WaterFlyVelocity.P = 650
        WaterFlyVelocity.Velocity = Vector3.zero
        WaterFlyVelocity.Parent = root
    end

    if not WaterFlyGyro or WaterFlyGyro.Parent ~= root then
        if WaterFlyGyro then WaterFlyGyro:Destroy() end

        WaterFlyGyro = Instance.new("BodyGyro")
        WaterFlyGyro.Name = "ToxNDSWaterFlyGyro"
        WaterFlyGyro.MaxTorque = Vector3.new(50000, 50000, 50000)
        WaterFlyGyro.P = 1500
        WaterFlyGyro.D = 250
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

        local speed = math.clamp(tonumber(Settings.NDSWaterFlySpeed) or 12, 3, 60)

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

                if velocity.Y < -38 then
                    root.AssemblyLinearVelocity = Vector3.new(velocity.X, -8, velocity.Z)
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
    if not Settings.NDSNoTP or not NoTPAnchorCFrame then
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

CreateToggle("Auto Win", GamePage, Settings.NDSAutoWin, function(v)
    Settings.NDSAutoWin = v

    if v then
        StartAutoWin()
    else
        StopAutoWin()
    end
end, "NDSAutoWin")

CreateButton("SPAWN", GamePage, function()
    TeleportTo(SpawnCFrame, "SPAWN")
end)

CreateButton("ISLAND", GamePage, function()
    TeleportTo(IslandCFrame, "ISLAND")
end)

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

CreateToggle("Noclip", GamePage, Settings.Noclip, function(v)
    SetShared("Noclip", v)
end, "Noclip")

CreateToggleWithValue("Water Fly", GamePage, Settings.NDSWaterFly, Settings.NDSWaterFlySpeed, function(v)
    getgenv().SetNDSWaterFly(v, true)
end, function(value)
    Settings.NDSWaterFlySpeed = math.clamp(tonumber(value) or 12, 3, 60)

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
    StartNoTP()
end
