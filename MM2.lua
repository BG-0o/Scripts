if game.PlaceId ~= 142823291 then
    return
end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")
local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Settings = getgenv().Settings
local GamePage = getgenv().GamePage
local CreateToggle = getgenv().CreateToggle
local CreateToggleWithValue = getgenv().CreateToggleWithValue
local CreateButton = getgenv().CreateButton
local CreateDropdown = getgenv().CreateDropdown
local CreateKeybindButton = getgenv().CreateKeybindButton
local CreateKeybindToggle = getgenv().CreateKeybindToggle
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
or not CreateKeybindButton
or not CreateKeybindToggle then
    return
end

Settings.MM2KillAllKey = Settings.MM2KillAllKey or Enum.KeyCode.K
Settings.MM2KillAllAuto = Settings.MM2KillAllAuto == true
Settings.MM2ShootMurderKey = Settings.MM2ShootMurderKey or Enum.KeyCode.C
Settings.MM2ShootMurderAuto = Settings.MM2ShootMurderAuto == true
Settings.MM2GrabGunKey = Settings.MM2GrabGunKey or Enum.KeyCode.G
Settings.MM2GrabGunAuto = Settings.MM2GrabGunAuto == true
Settings.MM2FlingTarget = Settings.MM2FlingTarget or "Murderer"

local ActionBusy = false

local function IsInsideToxGui(obj)
    local toxGui = getgenv().Gui

    if toxGui and obj then
        return obj == toxGui or obj:IsDescendantOf(toxGui)
    end

    return false
end

local function IsGuiVisible(obj)
    if not obj or not obj:IsA("GuiObject") then
        return false
    end

    local current = obj

    while current do
        if current:IsA("GuiObject") and not current.Visible then
            return false
        end

        if current:IsA("ScreenGui") and not current.Enabled then
            return false
        end

        current = current.Parent
    end

    return true
end

local function GuiBlob(obj)
    local parts = {tostring(obj.Name or "")}

    if obj:IsA("TextButton") or obj:IsA("TextLabel") or obj:IsA("TextBox") then
        table.insert(parts, tostring(obj.Text or ""))
    end

    if obj:IsA("TextBox") then
        table.insert(parts, tostring(obj.PlaceholderText or ""))
    end

    return string.lower(table.concat(parts, " "))
end

local function ClickGuiButton(button)
    if not button or not button.Parent then
        return false
    end

    if firesignal then
        local ok = pcall(function()
            firesignal(button.MouseButton1Click)
        end)

        if ok then
            return true
        end
    end

    return pcall(function()
        local center = button.AbsolutePosition + button.AbsoluteSize / 2

        VirtualInputManager:SendMouseButtonEvent(
            center.X,
            center.Y,
            0,
            true,
            game,
            0
        )

        task.wait(0.02)

        VirtualInputManager:SendMouseButtonEvent(
            center.X,
            center.Y,
            0,
            false,
            game,
            0
        )
    end)
end

local function FindMM2RadioTool()
    local character = Player.Character
    local backpack = Player:FindFirstChildOfClass("Backpack")

    for _, container in ipairs({character, backpack}) do
        if container then
            for _, child in ipairs(container:GetChildren()) do
                if child:IsA("Tool") then
                    local lower = string.lower(child.Name)

                    if string.find(lower, "radio", 1, true)
                    or string.find(lower, "boombox", 1, true)
                    or string.find(lower, "boom box", 1, true) then
                        return child
                    end
                end
            end
        end
    end

    return nil
end

local function FindRadioOpenButton()
    local playerGui = Player:FindFirstChildOfClass("PlayerGui")

    if not playerGui then
        return nil
    end

    local best = nil
    local bestScore = -1

    for _, obj in ipairs(playerGui:GetDescendants()) do
        if (obj:IsA("TextButton") or obj:IsA("ImageButton"))
        and IsGuiVisible(obj)
        and not IsInsideToxGui(obj) then
            local blob = GuiBlob(obj)
            local score = 0

            if blob == "radio" then
                score = score + 20
            end

            if string.find(blob, "radio", 1, true) then
                score = score + 10
            end

            if string.find(string.lower(obj.Name), "radio", 1, true) then
                score = score + 8
            end

            if score > bestScore then
                best = obj
                bestScore = score
            end
        end
    end

    if bestScore > 0 then
        return best
    end

    return nil
end

local function FindMySongsButton()
    local playerGui = Player:FindFirstChildOfClass("PlayerGui")

    if not playerGui then
        return nil
    end

    for _, obj in ipairs(playerGui:GetDescendants()) do
        if (obj:IsA("TextButton") or obj:IsA("ImageButton"))
        and IsGuiVisible(obj)
        and not IsInsideToxGui(obj) then
            local blob = GuiBlob(obj)

            if string.find(blob, "my songs", 1, true)
            or string.find(blob, "mysongs", 1, true) then
                return obj
            end
        end
    end

    return nil
end

local function FindRadioTextBox()
    local playerGui = Player:FindFirstChildOfClass("PlayerGui")

    if not playerGui then
        return nil
    end

    local best = nil
    local bestScore = -1

    for _, obj in ipairs(playerGui:GetDescendants()) do
        if obj:IsA("TextBox")
        and IsGuiVisible(obj)
        and not IsInsideToxGui(obj) then
            local blob = GuiBlob(obj)
            local score = 0

            if string.find(blob, "enter sound id", 1, true) then
                score = score + 50
            end

            if string.find(blob, "sound id", 1, true) then
                score = score + 30
            end

            if string.find(blob, "song id", 1, true) then
                score = score + 30
            end

            if string.find(blob, "audio id", 1, true) then
                score = score + 25
            end

            if string.find(blob, "radio", 1, true) then
                score = score + 15
            end

            if string.find(blob, "song", 1, true)
            or string.find(blob, "sound", 1, true)
            or string.find(blob, "music", 1, true) then
                score = score + 8
            end

            if string.find(string.lower(obj.Name), "id", 1, true) then
                score = score + 4
            end

            if score > bestScore then
                best = obj
                bestScore = score
            end
        end
    end

    if bestScore > 0 then
        return best
    end

    return nil
end

local function FindButtonNearTextBox(textBox, words)
    if not textBox then
        return nil
    end

    local current = textBox.Parent

    for _ = 1, 6 do
        if not current then
            break
        end

        for _, obj in ipairs(current:GetDescendants()) do
            if (obj:IsA("TextButton") or obj:IsA("ImageButton"))
            and IsGuiVisible(obj)
            and not IsInsideToxGui(obj) then
                local blob = GuiBlob(obj)

                for _, word in ipairs(words) do
                    if blob == word or string.find(blob, word, 1, true) then
                        return obj
                    end
                end
            end
        end

        current = current.Parent
    end

    return nil
end

local function OpenMM2RadioInterface()
    local textBox = FindRadioTextBox()

    if textBox then
        return textBox
    end

    local radioButton = FindRadioOpenButton()

    if radioButton then
        ClickGuiButton(radioButton)
        task.wait(0.15)
    else
        local tool = FindMM2RadioTool()

        if tool then
            local character = Player.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")

            if humanoid and tool.Parent ~= character then
                pcall(function()
                    humanoid:EquipTool(tool)
                end)

                task.wait(0.08)
            end

            pcall(function()
                tool:Activate()
            end)

            task.wait(0.15)
        end
    end

    textBox = FindRadioTextBox()

    if textBox then
        return textBox
    end

    local mySongs = FindMySongsButton()

    if mySongs then
        ClickGuiButton(mySongs)
        task.wait(0.12)
        textBox = FindRadioTextBox()
    end

    return textBox
end

getgenv().ToxPlayMM2Radio = function(id)
    local cleanID = tostring(id or ""):match("%d+")

    if not cleanID then
        CustomNotify("Invalid Radio ID", Color3.fromRGB(255, 100, 100))
        return
    end

    task.spawn(function()
        local textBox = OpenMM2RadioInterface()

        if not textBox then
            CustomNotify("MM2 Radio ID box not found", Color3.fromRGB(255, 180, 70))
            return
        end

        textBox.Text = cleanID

        pcall(function()
            textBox:CaptureFocus()
        end)

        task.wait(0.03)

        pcall(function()
            textBox:ReleaseFocus(true)
        end)

        task.wait(0.05)

        local playButton = FindButtonNearTextBox(textBox, {"play"})
        local addButton = FindButtonNearTextBox(textBox, {"add", "save"})

        if playButton and ClickGuiButton(playButton) then
            CustomNotify("MM2 Radio: " .. cleanID, Color3.fromRGB(100, 255, 100))
            return
        end

        if addButton and ClickGuiButton(addButton) then
            task.wait(0.15)

            textBox = FindRadioTextBox() or textBox
            playButton = FindButtonNearTextBox(textBox, {"play"})

            if playButton then
                ClickGuiButton(playButton)
            end

            CustomNotify("MM2 Radio ID added: " .. cleanID, Color3.fromRGB(100, 255, 100))
            return
        end

        CustomNotify("MM2 Radio Play button not found", Color3.fromRGB(255, 180, 70))
    end)
end

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

local function NormalGunClick()
    local viewport = Camera.ViewportSize
    local inset = GuiService:GetGuiInset()
    local x = viewport.X / 2
    local y = viewport.Y / 2 + inset.Y

    pcall(function()
        VirtualInputManager:SendMouseMoveEvent(x, y, game)
    end)

    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
        task.wait(0.02)
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
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

    ActionBusy = true

    task.spawn(function()
        if not EquipTool(gun) then
            ActionBusy = false
            CustomNotify("Could not equip Gun", Color3.fromRGB(255, 100, 100))
            return
        end

        task.wait(0.08)

        if not targetRoot.Parent or targetHumanoid.Health <= 0 then
            ActionBusy = false
            return
        end

        local oldCFrame = root.CFrame
        local oldLinearVelocity = root.AssemblyLinearVelocity
        local oldAngularVelocity = root.AssemblyAngularVelocity
        local oldAnchored = root.Anchored
        local oldAutoRotate = humanoid.AutoRotate
        local oldPlatformStand = humanoid.PlatformStand
        local oldSit = humanoid.Sit
        local oldCameraType = Camera.CameraType
        local oldCameraSubject = Camera.CameraSubject
        local oldCameraCFrame = Camera.CFrame
        local oldMousePosition = UserInputService:GetMouseLocation()
        local oldRagdollEnabled = humanoid:GetStateEnabled(Enum.HumanoidStateType.Ragdoll)
        local oldFallingDownEnabled = humanoid:GetStateEnabled(Enum.HumanoidStateType.FallingDown)
        local allow = getgenv().AllowToxTeleport

        if allow then
            allow(1)
        end

        pcall(function()
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        end)

        humanoid.PlatformStand = false
        humanoid.Sit = false
        humanoid.AutoRotate = false

        root.Anchored = true
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero

        local targetPosition = targetRoot.Position + Vector3.new(0, 1.1, 0)
        local shootPosition = targetRoot.Position + Vector3.new(0, 6.5, 0)

        root.CFrame = CFrame.lookAt(shootPosition, targetPosition)

        Camera.CameraType = Enum.CameraType.Scriptable
        Camera.CFrame = CFrame.lookAt(
            shootPosition + Vector3.new(0, 1.5, 0),
            targetPosition
        )

        RunService.RenderStepped:Wait()
        RunService.RenderStepped:Wait()

        pcall(function()
            gun:Activate()
        end)

        NormalGunClick()

        task.wait(0.06)

        pcall(function()
            VirtualInputManager:SendMouseMoveEvent(oldMousePosition.X, oldMousePosition.Y, game)
        end)

        Camera.CameraType = oldCameraType
        Camera.CameraSubject = oldCameraSubject
        Camera.CFrame = oldCameraCFrame

        if root and root.Parent then
            if allow then
                allow(0.8)
            end

            root.CFrame = oldCFrame
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            root.Anchored = oldAnchored
        end

        if humanoid and humanoid.Parent and humanoid.Health > 0 then
            humanoid.PlatformStand = oldPlatformStand
            humanoid.Sit = oldSit
            humanoid.AutoRotate = oldAutoRotate

            pcall(function()
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, oldRagdollEnabled)
                humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, oldFallingDownEnabled)
            end)

            if not oldPlatformStand and not oldSit then
                pcall(function()
                    humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                end)

                task.wait()

                pcall(function()
                    humanoid:ChangeState(Enum.HumanoidStateType.Running)
                end)
            end
        end

        if root and root.Parent and not oldAnchored then
            root.AssemblyLinearVelocity = Vector3.new(
                oldLinearVelocity.X,
                math.max(oldLinearVelocity.Y, 0),
                oldLinearVelocity.Z
            )
            root.AssemblyAngularVelocity = oldAngularVelocity
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

CreateKeybindToggle("Kill All", GamePage, Settings.MM2KillAllKey, Settings.MM2KillAllAuto, function(key)
    Settings.MM2KillAllKey = key
end, function(enabled)
    Settings.MM2KillAllAuto = enabled
end)

CreateKeybindToggle("Shoot Murderer", GamePage, Settings.MM2ShootMurderKey, Settings.MM2ShootMurderAuto, function(key)
    Settings.MM2ShootMurderKey = key
end, function(enabled)
    Settings.MM2ShootMurderAuto = enabled
end)

CreateKeybindToggle("Grab Gun", GamePage, Settings.MM2GrabGunKey, Settings.MM2GrabGunAuto, function(key)
    Settings.MM2GrabGunKey = key
end, function(enabled)
    Settings.MM2GrabGunAuto = enabled
end)

CreateDropdown("Fling Target", {"Murderer", "Sheriff"}, GamePage, Settings.MM2FlingTarget, function(value)
    Settings.MM2FlingTarget = value
    AutoSaveConfiguration()
end)

CreateButton("Fling", GamePage, FlingSelectedRole)

local AutoKnifeOwned = false
local AutoGunOwned = false
local AutoGrabDrop = nil
local AutoGrabLastAttempt = 0

task.spawn(function()
    while not getgenv().Destroyed and game.PlaceId == 142823291 do
        local knife = FindNamedTool({"knife"})
        local gun = FindNamedTool({"gun", "revolver"})

        if Settings.MM2KillAllAuto then
            if knife and not AutoKnifeOwned and not ActionBusy then
                AutoKnifeOwned = true
                task.spawn(KillAll)
            elseif not knife then
                AutoKnifeOwned = false
            end
        else
            AutoKnifeOwned = knife ~= nil
        end

        if Settings.MM2ShootMurderAuto then
            if gun and not AutoGunOwned and not ActionBusy then
                AutoGunOwned = true
                task.spawn(ShootMurderer)
            elseif not gun then
                AutoGunOwned = false
            end
        else
            AutoGunOwned = gun ~= nil
        end

        if Settings.MM2GrabGunAuto and not gun and not ActionBusy then
            local drop = FindGunDrop()

            if drop then
                local now = tick()

                if drop ~= AutoGrabDrop or now - AutoGrabLastAttempt >= 0.8 then
                    AutoGrabDrop = drop
                    AutoGrabLastAttempt = now
                    task.spawn(GrabGun)
                end
            else
                AutoGrabDrop = nil
            end
        else
            AutoGrabDrop = nil
        end

        task.wait(0.1)
    end
end)

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
