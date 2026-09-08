if game.PlaceId ~= 142823291 then
    return
end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
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
Settings.MM2AutoFarm = Settings.MM2AutoFarm == true
Settings.MM2AutoFarmSpeed = tonumber(Settings.MM2AutoFarmSpeed) or 55

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

    return nil
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

local function GetPredictedMurderPosition(targetRoot)
    local velocity = targetRoot.AssemblyLinearVelocity
    local ping = 0.08

    pcall(function()
        ping = math.clamp(Player:GetNetworkPing() + 0.055, 0.065, 0.16)
    end)

    local horizontal = Vector3.new(velocity.X, 0, velocity.Z) * ping
    local vertical = Vector3.new(0, velocity.Y * math.min(ping, 0.11), 0)

    if horizontal.Magnitude > 7 then
        horizontal = horizontal.Unit * 7
    end

    vertical = Vector3.new(0, math.clamp(vertical.Y, -4, 5), 0)

    return targetRoot.Position
        + Vector3.new(0, 1.15, 0)
        + horizontal
        + vertical
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

        task.wait(0.07)

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

        Camera.CameraType = Enum.CameraType.Scriptable

        for _ = 1, 4 do
            if not targetRoot.Parent or targetHumanoid.Health <= 0 then
                break
            end

            local aimPosition = GetPredictedMurderPosition(targetRoot)
            local targetVelocity = targetRoot.AssemblyLinearVelocity
            local followOffset = Vector3.new(
                targetVelocity.X * 0.035,
                0,
                targetVelocity.Z * 0.035
            )
            local shootPosition = targetRoot.Position + followOffset + Vector3.new(0, 5.2, 0)

            root.CFrame = CFrame.lookAt(shootPosition, aimPosition)
            Camera.CFrame = CFrame.lookAt(
                shootPosition + Vector3.new(0, 1.35, 0),
                aimPosition
            )

            RunService.RenderStepped:Wait()
        end

        if targetRoot.Parent and targetHumanoid.Health > 0 then
            local aimPosition = GetPredictedMurderPosition(targetRoot)
            local shootPosition = targetRoot.Position + Vector3.new(0, 5.2, 0)

            root.CFrame = CFrame.lookAt(shootPosition, aimPosition)
            Camera.CFrame = CFrame.lookAt(
                shootPosition + Vector3.new(0, 1.35, 0),
                aimPosition
            )

            pcall(function()
                gun:Activate()
            end)

            NormalGunClick()
        end

        task.wait(0.055)

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

local function GrabGun(silent, requestedDrop)
    if ActionBusy then
        return false
    end

    local _, humanoid, root = GetCharacterState()

    if not humanoid or humanoid.Health <= 0 or not root then
        return false
    end

    if GetRole(Player) ~= "Innocent" then
        if not silent then
            CustomNotify("Grab Gun is only for Innocent", Color3.fromRGB(255, 180, 70))
        end

        return false
    end

    local gunDrop = requestedDrop

    if not gunDrop or not gunDrop.Parent then
        gunDrop = FindGunDrop()
    end

    if not gunDrop then
        if not silent then
            CustomNotify("Dropped Gun not found", Color3.fromRGB(255, 180, 70))
        end

        return false
    end

    ActionBusy = true

    task.spawn(function()
        local oldCFrame = root.CFrame
        local allow = getgenv().AllowToxTeleport

        if allow then
            allow(0.5)
        end

        if gunDrop.Parent and root.Parent and humanoid.Health > 0 then
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            root.CFrame = gunDrop.CFrame * CFrame.new(0, 1.15, 0)

            if firetouchinterest then
                pcall(function()
                    firetouchinterest(root, gunDrop, 0)
                    firetouchinterest(root, gunDrop, 1)
                end)
            end

            task.wait(0.07)
        end

        if root and root.Parent and humanoid and humanoid.Health > 0 then
            if allow then
                allow(0.4)
            end

            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            root.CFrame = oldCFrame
        end

        ActionBusy = false
    end)

    return true
end

local MM2CoinCache = {}
local MM2CoinScanTime = 0
local MM2CoinBlacklist = setmetatable({}, {__mode = "k"})
local AutoFarmTween = nil
local AutoFarmRoot = nil
local AutoFarmHumanoid = nil
local AutoFarmReturnCFrame = nil
local AutoFarmRotation = nil
local AutoFarmOriginalAnchored = false
local AutoFarmOriginalAutoRotate = true
local AutoFarmOriginalPlatformStand = false
local AutoFarmOriginalSit = false
local AutoFarmOriginalRagdoll = true
local AutoFarmOriginalFallingDown = true
local AutoFarmCollisionCache = {}
local AutoFarmPrepared = false
local AutoFarmUndergroundY = nil
local AutoFarmOldFallenHeight = nil
local AutoFarmBagCoins = 0
local AutoFarmBagMax = 40
local AutoFarmBagKnown = false
local AutoFarmCoinSerial = 0
local AutoFarmCompleting = false
local AutoFarmAtCoin = false
local AutoFarmGeneration = 0
local AutoFarmSessionCollected = 0

local function IsAliveCharacter()
    local character, humanoid, root = GetCharacterState()
    return character, humanoid, root, humanoid and humanoid.Health > 0 and root ~= nil
end


local function ReadCoinBagFromGui()
    local playerGui = Player:FindFirstChildOfClass("PlayerGui")

    if not playerGui then
        return nil, nil
    end

    for _, obj in ipairs(playerGui:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
            local text = tostring(obj.Text or "")
            local current, maximum = text:match("(%d+)%s*/%s*(%d+)")

            if current and maximum then
                local blob = string.lower(tostring(obj.Name or ""))
                local parent = obj.Parent

                for _ = 1, 4 do
                    if not parent then
                        break
                    end

                    blob = blob .. " " .. string.lower(tostring(parent.Name or ""))
                    parent = parent.Parent
                end

                if string.find(blob, "coin", 1, true)
                or string.find(blob, "bag", 1, true)
                or string.find(blob, "inventory", 1, true) then
                    return tonumber(current), tonumber(maximum)
                end
            end
        end
    end

    return nil, nil
end

local function RefreshFarmBagState()
    local current, maximum = ReadCoinBagFromGui()

    if current and maximum and maximum > 0 then
        AutoFarmBagCoins = current
        AutoFarmBagMax = maximum
        AutoFarmBagKnown = true
    end

    return AutoFarmBagCoins, AutoFarmBagMax, AutoFarmBagKnown
end

local function IsFarmBagFull()
    local current, maximum, known = RefreshFarmBagState()
    return known and maximum > 0 and current >= maximum
end

local gameplayRemotes = ReplicatedStorage:FindFirstChild("Remotes")
gameplayRemotes = gameplayRemotes and gameplayRemotes:FindFirstChild("Gameplay")

local coinCollectedRemote = gameplayRemotes and gameplayRemotes:FindFirstChild("CoinCollected")
    or ReplicatedStorage:FindFirstChild("CoinCollected", true)

if coinCollectedRemote and coinCollectedRemote:IsA("RemoteEvent") then
    AddConnection(coinCollectedRemote.OnClientEvent:Connect(function(_, currentCoins, maxCoins)
        AutoFarmCoinSerial = AutoFarmCoinSerial + 1

        if typeof(currentCoins) == "number" then
            AutoFarmBagCoins = currentCoins
            AutoFarmBagKnown = true
        end

        if typeof(maxCoins) == "number" and maxCoins > 0 then
            AutoFarmBagMax = maxCoins
            AutoFarmBagKnown = true
        end
    end))
end

local function IsCoinValid(coin)
    return coin
        and coin.Parent
        and coin:IsA("BasePart")
        and not coin:GetAttribute("Collected")
        and not coin:GetAttribute("Delete")
        and coin.Transparency < 0.95
end

local function GetMM2Coins(force)
    local now = os.clock()

    if not force and now - MM2CoinScanTime < 0.25 then
        local valid = {}

        for _, coin in ipairs(MM2CoinCache) do
            if IsCoinValid(coin) then
                table.insert(valid, coin)
            end
        end

        MM2CoinCache = valid
        return valid
    end

    MM2CoinScanTime = now

    local coins = {}
    local seen = {}
    local scanRoot = workspace:FindFirstChild("Normal") or workspace
    local containers = {}

    for _, obj in ipairs(scanRoot:GetDescendants()) do
        local lower = string.lower(obj.Name)

        if lower == "coincontainer"
        or lower == "coins"
        or lower == "coinarea" then
            table.insert(containers, obj)
        end
    end

    local function hasCoinAncestor(obj)
        local current = obj

        for _ = 1, 4 do
            if not current or current == scanRoot then
                break
            end

            if string.find(string.lower(current.Name), "coin", 1, true) then
                return true
            end

            current = current.Parent
        end

        return false
    end

    local function addPart(part)
        if not part
        or not part:IsA("BasePart")
        or not IsCoinValid(part)
        or seen[part] then
            return
        end

        local model = part:FindFirstAncestorOfClass("Model")

        if model and model:FindFirstChildOfClass("Humanoid") then
            return
        end

        local lower = string.lower(part.Name)

        if string.find(lower, "coin", 1, true)
        or hasCoinAncestor(part) then
            seen[part] = true
            table.insert(coins, part)
        end
    end

    if #containers > 0 then
        for _, container in ipairs(containers) do
            for _, obj in ipairs(container:GetDescendants()) do
                if obj:IsA("BasePart") then
                    addPart(obj)
                end
            end
        end
    else
        for _, obj in ipairs(scanRoot:GetDescendants()) do
            if obj:IsA("BasePart")
            and string.find(string.lower(obj.Name), "coin", 1, true) then
                addPart(obj)
            end
        end
    end

    MM2CoinCache = coins
    return coins
end

local function GetOtherPlayerCoinPressure(coin)
    local bestDistance = math.huge
    local incoming = false

    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= Player and other.Character then
            local otherHumanoid = other.Character:FindFirstChildOfClass("Humanoid")
            local otherRoot = other.Character:FindFirstChild("HumanoidRootPart")

            if otherHumanoid and otherHumanoid.Health > 0 and otherRoot then
                local offset = coin.Position - otherRoot.Position
                local distance = offset.Magnitude

                if distance < bestDistance then
                    bestDistance = distance
                end

                if distance > 0.1 then
                    local horizontalVelocity = Vector3.new(
                        otherRoot.AssemblyLinearVelocity.X,
                        0,
                        otherRoot.AssemblyLinearVelocity.Z
                    )

                    if horizontalVelocity.Magnitude > 7 then
                        local direction = Vector3.new(offset.X, 0, offset.Z)

                        if direction.Magnitude > 0.1
                        and horizontalVelocity.Unit:Dot(direction.Unit) > 0.65 then
                            incoming = true
                        end
                    end
                end
            end
        end
    end

    return bestDistance, incoming
end

local function GetBestCoin(origin, competitionAware)
    local coins = GetMM2Coins(false)
    local bestCoin = nil
    local bestScore = math.huge
    local now = os.clock()

    for coin, expiry in pairs(MM2CoinBlacklist) do
        if not coin.Parent or now >= expiry then
            MM2CoinBlacklist[coin] = nil
        end
    end

    for _, coin in ipairs(coins) do
        if IsCoinValid(coin) and not MM2CoinBlacklist[coin] then
            local myDistance = (origin - coin.Position).Magnitude
            local score = myDistance

            local cluster = 0

            for _, otherCoin in ipairs(coins) do
                if otherCoin ~= coin
                and IsCoinValid(otherCoin)
                and (coin.Position - otherCoin.Position).Magnitude <= 22 then
                    cluster = cluster + 1
                end
            end

            score = score - math.min(cluster * 3.5, 18)

            if competitionAware then
                local otherDistance, incoming = GetOtherPlayerCoinPressure(coin)

                if otherDistance < myDistance then
                    score = score + 70 + math.min((myDistance - otherDistance) * 2, 60)
                end

                if otherDistance < 8 then
                    score = score + 110
                end

                if incoming and otherDistance < myDistance + 12 then
                    score = score + 75
                end
            end

            if score < bestScore then
                bestScore = score
                bestCoin = coin
            end
        end
    end

    return bestCoin
end

local function TouchCoin(coin)
    if not IsCoinValid(coin) then
        return false
    end

    local character, humanoid, root, alive = IsAliveCharacter()

    if not alive then
        return false
    end

    local touched = false

    if firetouchinterest then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                pcall(function()
                    firetouchinterest(part, coin, 0)
                    firetouchinterest(part, coin, 1)
                end)

                touched = true
            end
        end
    end

    return touched
end

local function GetStableUndergroundY(root)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {Player.Character}
    params.IgnoreWater = true

    local hit = workspace:Raycast(
        root.Position + Vector3.new(0, 3, 0),
        Vector3.new(0, -35, 0),
        params
    )

    if hit and hit.Position then
        return hit.Position.Y - 5.25
    end

    return root.Position.Y - 7
end

local function SetFarmCollision(enabled)
    local character = Player.Character

    if not character then
        return
    end

    if not enabled then
        table.clear(AutoFarmCollisionCache)

        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                AutoFarmCollisionCache[part] = part.CanCollide
                part.CanCollide = false
            end
        end
    else
        for part, oldValue in pairs(AutoFarmCollisionCache) do
            if part and part.Parent then
                part.CanCollide = oldValue
            end
        end

        table.clear(AutoFarmCollisionCache)
    end
end

local function SetFarmCFrame(x, z, y)
    local character = Player.Character

    if not character
    or not AutoFarmRoot
    or not AutoFarmRoot.Parent
    or not AutoFarmRotation then
        return false
    end

    local target = CFrame.new(
        x,
        y or AutoFarmUndergroundY,
        z
    ) * AutoFarmRotation

    character:PivotTo(target)

    AutoFarmRoot.AssemblyLinearVelocity = Vector3.zero
    AutoFarmRoot.AssemblyAngularVelocity = Vector3.zero

    return true
end

local function RestoreAutoFarmPosition()
    local character = Player.Character

    if not character
    or not character.Parent
    or not AutoFarmReturnCFrame
    or not AutoFarmRoot
    or not AutoFarmRoot.Parent then
        return
    end

    local allow = getgenv().AllowToxTeleport

    if allow then
        allow(1)
    end

    character:PivotTo(AutoFarmReturnCFrame)
    AutoFarmRoot.AssemblyLinearVelocity = Vector3.zero
    AutoFarmRoot.AssemblyAngularVelocity = Vector3.zero
end

local function StopAutoFarm(restore)
    AutoFarmGeneration = AutoFarmGeneration + 1
    AutoFarmAtCoin = false

    if AutoFarmTween then
        pcall(function()
            AutoFarmTween:Cancel()
        end)
    end

    AutoFarmTween = nil

    if AutoFarmRoot and AutoFarmRoot.Parent then
        AutoFarmRoot.Anchored = true
        AutoFarmRoot.AssemblyLinearVelocity = Vector3.zero
        AutoFarmRoot.AssemblyAngularVelocity = Vector3.zero
    end

    if restore then
        RestoreAutoFarmPosition()
        RunService.Heartbeat:Wait()
    end

    SetFarmCollision(true)

    if AutoFarmHumanoid and AutoFarmHumanoid.Parent and AutoFarmHumanoid.Health > 0 then
        AutoFarmHumanoid.PlatformStand = AutoFarmOriginalPlatformStand
        AutoFarmHumanoid.Sit = AutoFarmOriginalSit
        AutoFarmHumanoid.AutoRotate = AutoFarmOriginalAutoRotate

        pcall(function()
            AutoFarmHumanoid:SetStateEnabled(
                Enum.HumanoidStateType.Ragdoll,
                AutoFarmOriginalRagdoll
            )

            AutoFarmHumanoid:SetStateEnabled(
                Enum.HumanoidStateType.FallingDown,
                AutoFarmOriginalFallingDown
            )
        end)
    end

    if AutoFarmRoot and AutoFarmRoot.Parent then
        AutoFarmRoot.AssemblyLinearVelocity = Vector3.zero
        AutoFarmRoot.AssemblyAngularVelocity = Vector3.zero
        AutoFarmRoot.Anchored = AutoFarmOriginalAnchored
    end

    if AutoFarmHumanoid
    and AutoFarmHumanoid.Parent
    and AutoFarmHumanoid.Health > 0
    and not AutoFarmOriginalPlatformStand
    and not AutoFarmOriginalSit then
        pcall(function()
            AutoFarmHumanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end)

        task.wait()

        pcall(function()
            AutoFarmHumanoid:ChangeState(Enum.HumanoidStateType.Running)
        end)
    end

    if AutoFarmOldFallenHeight ~= nil then
        pcall(function()
            workspace.FallenPartsDestroyHeight = AutoFarmOldFallenHeight
        end)
    end

    AutoFarmRoot = nil
    AutoFarmHumanoid = nil
    AutoFarmReturnCFrame = nil
    AutoFarmRotation = nil
    AutoFarmPrepared = false
    AutoFarmUndergroundY = nil
    AutoFarmOldFallenHeight = nil
    AutoFarmSessionCollected = 0
end

local function CompleteAutoFarm()
    if AutoFarmCompleting then
        return
    end

    AutoFarmCompleting = true
    Settings.MM2AutoFarm = false
    StopAutoFarm(true)

    if SyncToggleVisuals then
        SyncToggleVisuals("MM2AutoFarm", false)
    end

    AutoSaveConfiguration()

    local current, maximum = RefreshFarmBagState()

    CustomNotify(
        "Auto Farm complete: " .. tostring(current) .. "/" .. tostring(maximum),
        Color3.fromRGB(100, 255, 100)
    )

    AutoFarmCompleting = false
end

local function PrepareAutoFarm()
    local character, humanoid, root, alive = IsAliveCharacter()

    if not alive then
        return false
    end

    if AutoFarmPrepared and AutoFarmRoot == root then
        return true
    end

    if AutoFarmPrepared then
        StopAutoFarm(false)
    end

    AutoFarmGeneration = AutoFarmGeneration + 1
    AutoFarmRoot = root
    AutoFarmHumanoid = humanoid
    AutoFarmReturnCFrame = character:GetPivot()
    AutoFarmRotation = root.CFrame.Rotation
    AutoFarmOriginalAnchored = root.Anchored
    AutoFarmOriginalAutoRotate = humanoid.AutoRotate
    AutoFarmOriginalPlatformStand = humanoid.PlatformStand
    AutoFarmOriginalSit = humanoid.Sit
    AutoFarmOriginalRagdoll = humanoid:GetStateEnabled(Enum.HumanoidStateType.Ragdoll)
    AutoFarmOriginalFallingDown = humanoid:GetStateEnabled(Enum.HumanoidStateType.FallingDown)
    AutoFarmPrepared = true
    AutoFarmAtCoin = false
    AutoFarmSessionCollected = 0
    AutoFarmUndergroundY = GetStableUndergroundY(root)

    pcall(function()
        AutoFarmOldFallenHeight = workspace.FallenPartsDestroyHeight
        workspace.FallenPartsDestroyHeight = math.min(
            AutoFarmOldFallenHeight,
            AutoFarmUndergroundY - 80
        )
    end)

    humanoid.PlatformStand = false
    humanoid.Sit = false
    humanoid.AutoRotate = false

    pcall(function()
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    end)

    SetFarmCollision(false)

    root.Anchored = true
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero

    SetFarmCFrame(
        root.Position.X,
        root.Position.Z,
        AutoFarmUndergroundY
    )

    return true
end

local function TweenFarmRoot(targetPosition, duration, coin)
    if not AutoFarmRoot
    or not AutoFarmRoot.Parent
    or not AutoFarmUndergroundY then
        return false
    end

    local generation = AutoFarmGeneration
    local startPosition = AutoFarmRoot.Position
    local startX = startPosition.X
    local startZ = startPosition.Z
    local deltaX = targetPosition.X - startX
    local deltaZ = targetPosition.Z - startZ
    local startTime = os.clock()
    duration = math.max(duration, 0.035)

    while Settings.MM2AutoFarm
    and AutoFarmPrepared
    and generation == AutoFarmGeneration
    and AutoFarmRoot
    and AutoFarmRoot.Parent
    and AutoFarmHumanoid
    and AutoFarmHumanoid.Health > 0 do
        if coin and not IsCoinValid(coin) then
            return false
        end

        if IsFarmBagFull() then
            return false
        end

        local alpha = math.clamp(
            (os.clock() - startTime) / duration,
            0,
            1
        )

        SetFarmCFrame(
            startX + deltaX * alpha,
            startZ + deltaZ * alpha,
            AutoFarmUndergroundY
        )

        if alpha >= 1 then
            return true
        end

        RunService.Heartbeat:Wait()
    end

    return false
end

local function TouchCoin(coin)
    if not IsCoinValid(coin) then
        return false
    end

    local character, humanoid, root, alive = IsAliveCharacter()

    if not alive then
        return false
    end

    if firetouchinterest then
        local parts = {
            root,
            character:FindFirstChild("UpperTorso"),
            character:FindFirstChild("Torso"),
            character:FindFirstChild("RightFoot"),
            character:FindFirstChild("LeftFoot"),
            character:FindFirstChild("Right Leg"),
            character:FindFirstChild("Left Leg")
        }

        for _, part in ipairs(parts) do
            if part and part:IsA("BasePart") then
                pcall(function()
                    firetouchinterest(part, coin, 0)
                    firetouchinterest(part, coin, 1)
                end)
            end
        end
    end

    return true
end

local function CollectFarmCoin(coin)
    if not IsCoinValid(coin)
    or not AutoFarmRoot
    or not AutoFarmRoot.Parent
    or not AutoFarmUndergroundY then
        return false
    end

    local generation = AutoFarmGeneration
    local serialBefore = AutoFarmCoinSerial
    local bagBefore = AutoFarmBagCoins
    local pickupY = coin.Position.Y - math.clamp(
        coin.Size.Y * 0.5 + 1.45,
        1.55,
        2.35
    )

    AutoFarmAtCoin = true

    for _ = 1, 3 do
        if not Settings.MM2AutoFarm
        or generation ~= AutoFarmGeneration
        or IsFarmBagFull()
        or not IsCoinValid(coin) then
            break
        end

        SetFarmCFrame(
            coin.Position.X,
            coin.Position.Z,
            pickupY
        )

        TouchCoin(coin)
        RunService.Heartbeat:Wait()
        TouchCoin(coin)
        task.wait(0.035)

        SetFarmCFrame(
            coin.Position.X,
            coin.Position.Z,
            AutoFarmUndergroundY
        )

        RunService.Heartbeat:Wait()

        if not IsCoinValid(coin)
        or AutoFarmCoinSerial ~= serialBefore
        or AutoFarmBagCoins > bagBefore then
            AutoFarmAtCoin = false
            AutoFarmSessionCollected = AutoFarmSessionCollected + 1

            if AutoFarmCoinSerial == serialBefore
            and AutoFarmBagCoins <= bagBefore
            and not AutoFarmBagKnown then
                AutoFarmBagCoins = math.min(
                    AutoFarmBagCoins + 1,
                    AutoFarmBagMax
                )
            end

            return true
        end
    end

    if AutoFarmRoot and AutoFarmRoot.Parent then
        SetFarmCFrame(
            coin.Position.X,
            coin.Position.Z,
            AutoFarmUndergroundY
        )
    end

    AutoFarmAtCoin = false
    return false
end

local function AutoFarmCoin(coin)
    if not IsCoinValid(coin) or not PrepareAutoFarm() then
        return false
    end

    if IsFarmBagFull()
    or (not AutoFarmBagKnown and AutoFarmSessionCollected >= AutoFarmBagMax) then
        CompleteAutoFarm()
        return true
    end

    local speed = math.clamp(
        tonumber(Settings.MM2AutoFarmSpeed) or 55,
        15,
        180
    )

    local horizontalDistance = Vector3.new(
        AutoFarmRoot.Position.X - coin.Position.X,
        0,
        AutoFarmRoot.Position.Z - coin.Position.Z
    ).Magnitude

    local arrived = TweenFarmRoot(
        coin.Position,
        horizontalDistance / speed,
        coin
    )

    if not Settings.MM2AutoFarm then
        return false
    end

    if IsFarmBagFull()
    or (not AutoFarmBagKnown and AutoFarmSessionCollected >= AutoFarmBagMax) then
        CompleteAutoFarm()
        return true
    end

    if not arrived then
        if IsCoinValid(coin) then
            MM2CoinBlacklist[coin] = os.clock() + 0.7
        end

        return false
    end

    local collected = CollectFarmCoin(coin)

    if collected then
        MM2CoinBlacklist[coin] = os.clock() + 0.2
    else
        MM2CoinBlacklist[coin] = os.clock() + 1.1
    end

    if IsFarmBagFull()
    or (not AutoFarmBagKnown and AutoFarmSessionCollected >= AutoFarmBagMax) then
        CompleteAutoFarm()
    end

    return collected
end

AddConnection(RunService.Heartbeat:Connect(function()
    if not Settings.MM2AutoFarm
    or not AutoFarmPrepared
    or AutoFarmAtCoin
    or not AutoFarmRoot
    or not AutoFarmRoot.Parent
    or not AutoFarmUndergroundY then
        return
    end

    local position = AutoFarmRoot.Position

    if math.abs(position.Y - AutoFarmUndergroundY) > 0.05 then
        SetFarmCFrame(
            position.X,
            position.Z,
            AutoFarmUndergroundY
        )
    else
        AutoFarmRoot.AssemblyLinearVelocity = Vector3.zero
        AutoFarmRoot.AssemblyAngularVelocity = Vector3.zero
    end
end))

task.spawn(function()
    while not getgenv().Destroyed and game.PlaceId == 142823291 do
        if Settings.MM2AutoFarm then
            local _, humanoid, root, alive = IsAliveCharacter()

            if not alive then
                if AutoFarmPrepared then
                    StopAutoFarm(false)
                end

                task.wait(0.15)
            elseif IsFarmBagFull()
            or (not AutoFarmBagKnown and AutoFarmSessionCollected >= AutoFarmBagMax) then
                CompleteAutoFarm()
                task.wait(0.15)
            elseif not ActionBusy then
                if PrepareAutoFarm() then
                    local coin = GetBestCoin(
                        Vector3.new(
                            root.Position.X,
                            AutoFarmUndergroundY or root.Position.Y,
                            root.Position.Z
                        ),
                        false
                    )

                    if coin then
                        AutoFarmCoin(coin)
                    else
                        task.wait(0.12)
                    end
                else
                    task.wait(0.12)
                end
            else
                task.wait(0.08)
            end
        else
            if AutoFarmPrepared then
                StopAutoFarm(true)
            end

            task.wait(0.1)
        end
    end
end)


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

CreateToggleWithValue("Auto Farm", GamePage, Settings.MM2AutoFarm, Settings.MM2AutoFarmSpeed, function(v)
    if v then
        Settings.MM2AutoFarm = true
        AutoFarmBagKnown = false
        AutoFarmSessionCollected = 0
        RefreshFarmBagState()
    else
        Settings.MM2AutoFarm = false
        StopAutoFarm(true)
    end

    AutoSaveConfiguration()
end, function(value)
    Settings.MM2AutoFarmSpeed = math.clamp(tonumber(value) or 55, 15, 180)
    AutoSaveConfiguration()
end, "MM2AutoFarm")

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
local AutoGrabAttemptedDrops = setmetatable({}, {__mode = "k"})

task.spawn(function()
    while not getgenv().Destroyed and game.PlaceId == 142823291 do
        local knife = FindNamedTool({"knife"})
        local gun = FindNamedTool({"gun", "revolver"})
        local character = Player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local alive = humanoid and humanoid.Health > 0
        local localRole = alive and GetRole(Player) or nil

        if Settings.MM2KillAllAuto and not Settings.MM2AutoFarm then
            if knife and not AutoKnifeOwned and alive and not ActionBusy then
                AutoKnifeOwned = true
                task.spawn(KillAll)
            elseif not knife then
                AutoKnifeOwned = false
            end
        else
            AutoKnifeOwned = knife ~= nil
        end

        if Settings.MM2ShootMurderAuto and not Settings.MM2AutoFarm then
            if gun and not AutoGunOwned and alive and not ActionBusy then
                AutoGunOwned = true
                task.spawn(ShootMurderer)
            elseif not gun then
                AutoGunOwned = false
            end
        else
            AutoGunOwned = gun ~= nil
        end

        if Settings.MM2GrabGunAuto
        and not Settings.MM2AutoFarm
        and alive
        and localRole == "Innocent"
        and not gun
        and not ActionBusy then
            local drop = FindGunDrop()

            if drop and not AutoGrabAttemptedDrops[drop] then
                AutoGrabAttemptedDrops[drop] = true
                task.spawn(function()
                    GrabGun(true, drop)
                end)
            end
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
