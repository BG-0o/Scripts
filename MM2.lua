if game.PlaceId ~= 142823291 then
    return
end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Settings = getgenv().Settings
local GamePage = getgenv().GamePage
local CreateToggle = getgenv().CreateToggle
local CreateToggleWithValue = getgenv().CreateToggleWithValue
local CreateButton = getgenv().CreateButton
local CreateDropdown = getgenv().CreateDropdown
local CreateKeybindButton = getgenv().CreateKeybindButton
local AddConnection = getgenv().AddConnection
local CustomNotify = getgenv().CustomNotify
local AutoSaveConfiguration = getgenv().AutoSaveConfiguration
local SyncToggleVisuals = getgenv().SyncToggleVisuals
local SyncValueVisuals = getgenv().SyncValueVisuals

if not Settings
or not GamePage
or not CreateToggle
or not CreateToggleWithValue
or not CreateButton
or not CreateDropdown
or not CreateKeybindButton then
    return
end

Settings.MM2KillAllKey = Settings.MM2KillAllKey or Enum.KeyCode.K
Settings.MM2ShootMurderKey = Settings.MM2ShootMurderKey or Enum.KeyCode.C
Settings.MM2GrabGunKey = Settings.MM2GrabGunKey or Enum.KeyCode.G
Settings.MM2FlingTarget = Settings.MM2FlingTarget or "Murderer"

local ActionBusy = false

local function SetShared(Key, Value)
    if getgenv().ToxSetSharedOption then
        getgenv().ToxSetSharedOption(Key, Value)
    else
        Settings[Key] = Value == true

        if SyncToggleVisuals then
            SyncToggleVisuals(Key, Value == true)
        end
    end
end

local function SetSharedTemporary(Key, Value)
    local oldApplying = getgenv().ToxApplyingGameState
    getgenv().ToxApplyingGameState = true
    SetShared(Key, Value)
    getgenv().ToxApplyingGameState = oldApplying
end

local function GetCharacterState()
    local character = Player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    return character, humanoid, root
end

local function FindNamedTool(names)
    local character = Player.Character
    local backpack = Player:FindFirstChildOfClass("Backpack")

    for _, container in ipairs({character, backpack}) do
        if container then
            for _, child in ipairs(container:GetChildren()) do
                if child:IsA("Tool") then
                    local lowerName = string.lower(child.Name)

                    for _, wanted in ipairs(names) do
                        if lowerName == wanted then
                            return child
                        end
                    end
                end
            end
        end
    end

    return nil
end

local function GetRole(target)
    if getgenv().ToxGetMM2Role then
        return getgenv().ToxGetMM2Role(target)
    end

    local backpack = target and target:FindFirstChildOfClass("Backpack")
    local character = target and target.Character

    for _, container in ipairs({character, backpack}) do
        if container then
            if container:FindFirstChild("Knife") then
                return "Murderer"
            end

            if container:FindFirstChild("Gun") or container:FindFirstChild("Revolver") then
                return "Sheriff"
            end
        end
    end

    return "Innocent"
end

local function GetPlayerByRole(role)
    for _, target in ipairs(Players:GetPlayers()) do
        if target ~= Player and GetRole(target) == role then
            local humanoid = target.Character and target.Character:FindFirstChildOfClass("Humanoid")

            if humanoid and humanoid.Health > 0 then
                return target
            end
        end
    end

    return nil
end

local function EquipTool(tool)
    if not tool then
        return false
    end

    local character, humanoid = GetCharacterState()

    if not character or not humanoid or humanoid.Health <= 0 then
        return false
    end

    if tool.Parent ~= character then
        pcall(function()
            humanoid:EquipTool(tool)
        end)
        task.wait()
    end

    return tool.Parent == character
end

local function TouchKnifeTarget(knife, target)
    if not knife or not target or not target.Character then
        return false
    end

    local targetHumanoid = target.Character:FindFirstChildOfClass("Humanoid")
    local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
    local targetHead = target.Character:FindFirstChild("Head")
    local handle = knife:FindFirstChild("Handle")

    if not targetHumanoid or targetHumanoid.Health <= 0 or not handle then
        return false
    end

    local touched = false

    if firetouchinterest then
        for _, part in ipairs({targetRoot, targetHead}) do
            if part then
                pcall(function()
                    knife:Activate()
                    firetouchinterest(part, handle, 0)
                    firetouchinterest(part, handle, 1)
                    firetouchinterest(handle, part, 0)
                    firetouchinterest(handle, part, 1)
                end)
                touched = true
            end
        end
    end

    if not touched and targetRoot then
        local _, humanoid, root = GetCharacterState()

        if humanoid and humanoid.Health > 0 and root then
            local oldCFrame = root.CFrame
            local allow = getgenv().AllowToxTeleport

            if allow then allow(0.4) end

            root.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 1.5)
            knife:Activate()
            task.wait(0.04)
            root.CFrame = oldCFrame
            touched = true
        end
    end

    return touched
end

local function KillAll()
    if ActionBusy then
        return
    end

    local knife = FindNamedTool({"knife"})

    if not knife then
        CustomNotify("Kill All requires the Knife", Color3.fromRGB(255, 100, 100))
        return
    end

    if not EquipTool(knife) then
        CustomNotify("Could not equip Knife", Color3.fromRGB(255, 100, 100))
        return
    end

    ActionBusy = true

    task.spawn(function()
        for _, target in ipairs(Players:GetPlayers()) do
            if target ~= Player then
                TouchKnifeTarget(knife, target)
                task.wait(0.025)
            end
        end

        ActionBusy = false
    end)
end

local function FindShootRemote(gun)
    if not gun then
        return nil, nil
    end

    local knifeLocal = gun:FindFirstChild("KnifeLocal", true)

    if knifeLocal then
        local createBeam = knifeLocal:FindFirstChild("CreateBeam", true)

        if createBeam then
            local remoteFunction = createBeam:FindFirstChild("RemoteFunction")
                or createBeam:FindFirstChildWhichIsA("RemoteFunction")

            if remoteFunction then
                return remoteFunction, "AH2"
            end
        end
    end

    local shootGun = gun:FindFirstChild("ShootGun", true)

    if shootGun and (shootGun:IsA("RemoteFunction") or shootGun:IsA("RemoteEvent")) then
        return shootGun, "AH2"
    end

    for _, obj in ipairs(gun:GetDescendants()) do
        if obj:IsA("RemoteFunction") or obj:IsA("RemoteEvent") then
            local objectName = string.lower(obj.Name)
            local parentName = obj.Parent and string.lower(obj.Parent.Name) or ""

            if objectName == "shootgun"
            or objectName == "remotefunction"
            or string.find(parentName, "createbeam", 1, true) then
                return obj, "AH2"
            end
        end
    end

    local replicated = ReplicatedStorage:FindFirstChild("ShootGun", true)

    if replicated and (replicated:IsA("RemoteFunction") or replicated:IsA("RemoteEvent")) then
        return replicated, "AH2"
    end

    return nil, nil
end

local function FireMM2Gun(remote, mode, targetPosition)
    if not remote then
        return false
    end

    local ok = pcall(function()
        if remote:IsA("RemoteFunction") then
            remote:InvokeServer(1, targetPosition, mode or "AH2")
        else
            remote:FireServer(1, targetPosition, mode or "AH2")
        end
    end)

    return ok
end

local function InstallShotRedirect(gun, getTargetPosition)
    if not getrawmetatable
    or not setreadonly
    or not newcclosure
    or not getnamecallmethod then
        return function() end, function() return false end
    end

    local mt = getrawmetatable(game)
    local oldNamecall = mt.__namecall
    local active = true
    local intercepted = false

    local function IsGunRemote(self, args, method)
        if method ~= "InvokeServer" and method ~= "FireServer" then
            return false
        end

        if typeof(self) ~= "Instance"
        or (not self:IsA("RemoteFunction") and not self:IsA("RemoteEvent")) then
            return false
        end

        if gun and self:IsDescendantOf(gun) then
            return true
        end

        local lowerName = string.lower(self.Name)

        if lowerName == "shootgun" then
            return true
        end

        local node = self.Parent

        for _ = 1, 6 do
            if not node then
                break
            end

            local nodeName = string.lower(node.Name)

            if nodeName == "knifelocal"
            or nodeName == "createbeam"
            or nodeName == "gun" then
                return true
            end

            node = node.Parent
        end

        if typeof(args[2]) == "Vector3" then
            local third = tostring(args[3] or "")

            if third == "AH2" or third == "AH" then
                return true
            end
        end

        return false
    end

    local ok = pcall(function()
        setreadonly(mt, false)

        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            local args = {...}

            if active and IsGunRemote(self, args, method) then
                local targetPosition = getTargetPosition()

                if targetPosition then
                    if typeof(args[2]) == "Vector3" then
                        args[2] = targetPosition
                    elseif typeof(args[1]) == "Vector3" then
                        args[1] = targetPosition
                    else
                        args[1] = 1
                        args[2] = targetPosition
                        args[3] = "AH2"
                    end

                    intercepted = true
                end

                return oldNamecall(self, unpack(args))
            end

            return oldNamecall(self, ...)
        end)

        setreadonly(mt, true)
    end)

    if not ok then
        pcall(function()
            setreadonly(mt, true)
        end)

        return function() end, function() return false end
    end

    local function cleanup()
        if not active then
            return
        end

        active = false

        pcall(function()
            setreadonly(mt, false)
            mt.__namecall = oldNamecall
            setreadonly(mt, true)
        end)
    end

    local function wasIntercepted()
        return intercepted
    end

    return cleanup, wasIntercepted
end

local function TriggerGunShot(gun)
    pcall(function()
        gun:Activate()
    end)

    pcall(function()
        local mousePosition = UserInputService:GetMouseLocation()

        VirtualInputManager:SendMouseButtonEvent(
            mousePosition.X,
            mousePosition.Y,
            0,
            true,
            game,
            0
        )

        task.wait()

        VirtualInputManager:SendMouseButtonEvent(
            mousePosition.X,
            mousePosition.Y,
            0,
            false,
            game,
            0
        )
    end)
end

local function ShootMurderer()
    if ActionBusy then
        return
    end

    local gun = FindNamedTool({"gun", "revolver"})

    if not gun then
        CustomNotify("You need the Gun", Color3.fromRGB(255, 100, 100))
        return
    end

    local murderer = GetPlayerByRole("Murderer")

    if not murderer or not murderer.Character then
        CustomNotify("Murderer not found", Color3.fromRGB(255, 180, 70))
        return
    end

    local targetRoot = murderer.Character:FindFirstChild("HumanoidRootPart")
        or murderer.Character:FindFirstChild("UpperTorso")
        or murderer.Character:FindFirstChild("Torso")
        or murderer.Character:FindFirstChild("Head")

    local targetHumanoid = murderer.Character:FindFirstChildOfClass("Humanoid")

    if not targetRoot or not targetHumanoid or targetHumanoid.Health <= 0 then
        CustomNotify("Murderer target unavailable", Color3.fromRGB(255, 100, 100))
        return
    end

    local character, humanoid, root = GetCharacterState()

    if not character or not humanoid or humanoid.Health <= 0 or not root then
        return
    end

    local originalParent = gun.Parent
    local oldNoclip = Settings.Noclip == true

    ActionBusy = true

    task.spawn(function()
        if not EquipTool(gun) then
            ActionBusy = false
            CustomNotify("Could not equip Gun", Color3.fromRGB(255, 100, 100))
            return
        end

        local oldCFrame = root.CFrame
        local allow = getgenv().AllowToxTeleport

        SetSharedTemporary("Noclip", true)

        if allow then
            allow(1)
        end

        local function CurrentTargetPosition()
            if targetRoot and targetRoot.Parent and targetHumanoid.Health > 0 then
                return targetRoot.Position
            end

            return nil
        end

        local cleanupRedirect, wasIntercepted = InstallShotRedirect(gun, CurrentTargetPosition)

        local abovePosition = targetRoot.Position + Vector3.new(0, 4.5, 0)

        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        root.CFrame = CFrame.lookAt(abovePosition, targetRoot.Position)

        RunService.Heartbeat:Wait()

        TriggerGunShot(gun)

        task.wait(0.06)

        if not wasIntercepted() then
            local shootRemote, shootMode = FindShootRemote(gun)

            if shootRemote then
                FireMM2Gun(shootRemote, shootMode, targetRoot.Position)
            else
                TriggerGunShot(gun)
                task.wait(0.06)
            end
        end

        cleanupRedirect()

        if targetHumanoid.Health > 0 and targetRoot.Parent then
            local shootRemote, shootMode = FindShootRemote(gun)

            if shootRemote then
                FireMM2Gun(shootRemote, shootMode, targetRoot.Position)
            end
        end

        task.wait(0.025)

        if root and root.Parent then
            if allow then
                allow(0.6)
            end

            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            root.CFrame = oldCFrame
        end

        SetSharedTemporary("Noclip", oldNoclip)

        if originalParent and originalParent:IsA("Backpack") and gun and gun.Parent == character then
            pcall(function()
                gun.Parent = originalParent
            end)
        end

        ActionBusy = false
    end)
end

local function FindGunDrop()
    local gunDrop = workspace:FindFirstChild("GunDrop", true)

    if not gunDrop then
        return nil
    end

    if gunDrop:IsA("BasePart") then
        return gunDrop
    end

    if gunDrop:IsA("Model") then
        return gunDrop.PrimaryPart or gunDrop:FindFirstChildWhichIsA("BasePart", true)
    end

    return gunDrop:FindFirstChildWhichIsA("BasePart", true)
end

local function GrabGun()
    if ActionBusy then
        return
    end

    local gunDrop = FindGunDrop()

    if not gunDrop then
        CustomNotify("Dropped Gun not found", Color3.fromRGB(255, 180, 70))
        return
    end

    local _, humanoid, root = GetCharacterState()

    if not humanoid or humanoid.Health <= 0 or not root then
        return
    end

    ActionBusy = true

    task.spawn(function()
        local oldCFrame = root.CFrame
        local allow = getgenv().AllowToxTeleport

        if allow then allow(0.5) end

        for _ = 1, 3 do
            if not gunDrop.Parent or not root.Parent then
                break
            end

            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            root.CFrame = gunDrop.CFrame * CFrame.new(0, 1.2, 0)

            if firetouchinterest then
                pcall(function()
                    firetouchinterest(root, gunDrop, 0)
                    firetouchinterest(root, gunDrop, 1)
                end)
            end

            task.wait(0.035)
        end

        if root and root.Parent then
            if allow then allow(0.4) end
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            root.CFrame = oldCFrame
        end

        ActionBusy = false
    end)
end

local function ApplyRoleESP(enabled)
    Settings.MM2RoleESP = enabled == true

    if enabled and getgenv().ToxRefreshMM2Roles then
        getgenv().ToxRefreshMM2Roles(true)
    end

    if AutoSaveConfiguration then
        AutoSaveConfiguration()
    end
end

local function FlingSelectedRole()
    local role = Settings.MM2FlingTarget == "Sheriff" and "Sheriff" or "Murderer"
    local target = GetPlayerByRole(role)

    if not target then
        CustomNotify(role .. " not found", Color3.fromRGB(255, 180, 70))
        return
    end

    local fling = getgenv().ToxFlingPlayer

    if not fling then
        CustomNotify("Fling system unavailable", Color3.fromRGB(255, 100, 100))
        return
    end

    local restoreAntiFling = Settings.AntiFling == true

    task.spawn(function()
        if restoreAntiFling then
            SetSharedTemporary("AntiFling", false)
        end

        pcall(function()
            fling(target)
        end)

        if restoreAntiFling then
            SetSharedTemporary("AntiFling", true)
        end
    end)
end

CreateToggle("ESP", GamePage, Settings.MM2RoleESP, function(v)
    ApplyRoleESP(v)
end, "MM2RoleESP")

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

CreateKeybindButton("Kill All", GamePage, Settings.MM2KillAllKey, function(key)
    Settings.MM2KillAllKey = key
end)

CreateKeybindButton("Shoot Murderer", GamePage, Settings.MM2ShootMurderKey, function(key)
    Settings.MM2ShootMurderKey = key
end)

CreateKeybindButton("Grab Gun", GamePage, Settings.MM2GrabGunKey, function(key)
    Settings.MM2GrabGunKey = key
end)

CreateDropdown("Fling Target", {"Murderer", "Sheriff"}, GamePage, Settings.MM2FlingTarget, function(value)
    Settings.MM2FlingTarget = value
    AutoSaveConfiguration()
end)

CreateButton("Fling", GamePage, FlingSelectedRole)

AddConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed
    or UserInputService:GetFocusedTextBox()
    or input.UserInputType ~= Enum.UserInputType.Keyboard
    or getgenv().Destroyed then
        return
    end

    if Settings.MM2KillAllKey and input.KeyCode == Settings.MM2KillAllKey then
        KillAll()
        return
    end

    if Settings.MM2ShootMurderKey and input.KeyCode == Settings.MM2ShootMurderKey then
        ShootMurderer()
        return
    end

    if Settings.MM2GrabGunKey and input.KeyCode == Settings.MM2GrabGunKey then
        GrabGun()
    end
end))

if Settings.MM2RoleESP then
    ApplyRoleESP(true)
end
