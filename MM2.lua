if game.PlaceId ~= 142823291 then
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

    if not EquipTool(gun) then
        CustomNotify("Could not equip Gun", Color3.fromRGB(255, 100, 100))
        return
    end

    local knifeServer = gun:FindFirstChild("KnifeServer")
    local shootRemote = knifeServer and knifeServer:FindFirstChild("ShootGun")

    if not shootRemote then
        CustomNotify("Shoot remote unavailable", Color3.fromRGB(255, 100, 100))
        return
    end

    ActionBusy = true

    task.spawn(function()
        local oldCFrame = root.CFrame
        local allow = getgenv().AllowToxTeleport

        if allow then allow(0.6) end

        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        root.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 5)

        RunService.Heartbeat:Wait()

        local velocity = targetRoot.AssemblyLinearVelocity
        local targetPosition = targetRoot.Position + Vector3.new(velocity.X, 0, velocity.Z) * 0.035

        pcall(function()
            if shootRemote:IsA("RemoteFunction") then
                shootRemote:InvokeServer(0, targetPosition, "AH")
            elseif shootRemote:IsA("RemoteEvent") then
                shootRemote:FireServer(0, targetPosition, "AH")
            end
        end)

        task.wait(0.035)

        if root and root.Parent then
            if allow then allow(0.5) end
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            root.CFrame = oldCFrame
        end

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

local MM2ESPPrevious = nil

local function ApplyRoleESP(enabled)
    Settings.MM2RoleESP = enabled == true

    if enabled then
        if not MM2ESPPrevious then
            MM2ESPPrevious = {
                ESPEnabled = Settings.ESPEnabled == true,
                ESPNames = Settings.ESPNames == true,
                Chams = Settings.Chams == true,
                ESPTeamColors = Settings.ESPTeamColors == true
            }
        end

        SetSharedTemporary("ESPEnabled", true)
        SetSharedTemporary("ESPNames", true)
        SetSharedTemporary("Chams", true)
        SetSharedTemporary("ESPTeamColors", true)

        if getgenv().ToxRefreshMM2Roles then
            getgenv().ToxRefreshMM2Roles(true)
        end
    else
        if MM2ESPPrevious then
            SetSharedTemporary("ESPEnabled", MM2ESPPrevious.ESPEnabled)
            SetSharedTemporary("ESPNames", MM2ESPPrevious.ESPNames)
            SetSharedTemporary("Chams", MM2ESPPrevious.Chams)
            SetSharedTemporary("ESPTeamColors", MM2ESPPrevious.ESPTeamColors)
            MM2ESPPrevious = nil
        end
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
