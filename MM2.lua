if game.PlaceId ~= 142823291 then
    return
end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local PathfindingService = game:GetService("PathfindingService")
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
Settings.MM2AutoPlay = Settings.MM2AutoPlay == true
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
local AutoFarmOriginalAnchored = false
local AutoFarmPrepared = false
local AutoPlayPatrolTarget = nil
local AutoPlayLastShot = 0

local function IsAliveCharacter()
    local character, humanoid, root = GetCharacterState()
    return character, humanoid, root, humanoid and humanoid.Health > 0 and root ~= nil
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

    local function addCandidate(obj)
        if not obj or not obj.Parent then
            return
        end

        local candidates = {}

        if obj:IsA("BasePart") then
            table.insert(candidates, obj)

            if obj.Parent and obj.Parent:IsA("Model") then
                local preferred = obj.Parent:FindFirstChild("Coin_Server")
                    or obj.Parent:FindFirstChild("Coin")
                    or obj.Parent:FindFirstChild("Handle")

                if preferred and preferred:IsA("BasePart") then
                    table.insert(candidates, 1, preferred)
                end
            end
        elseif obj:IsA("Model") then
            local preferred = obj:FindFirstChild("Coin_Server", true)
                or obj:FindFirstChild("Coin", true)
                or obj:FindFirstChild("Handle", true)
                or obj:FindFirstChildWhichIsA("BasePart", true)

            if preferred and preferred:IsA("BasePart") then
                table.insert(candidates, preferred)
            end
        end

        for _, coin in ipairs(candidates) do
            if IsCoinValid(coin) and not seen[coin] then
                local lower = string.lower(coin.Name)
                local parentLower = coin.Parent and string.lower(coin.Parent.Name) or ""

                if string.find(lower, "coin", 1, true)
                or string.find(parentLower, "coin", 1, true)
                or lower == "handle" then
                    seen[coin] = true
                    table.insert(coins, coin)
                    return
                end
            end
        end
    end

    for _, obj in ipairs(workspace:GetDescendants()) do
        local lower = string.lower(obj.Name)

        if string.find(lower, "coin", 1, true)
        or lower == "coincontainer"
        or lower == "coinarea" then
            if obj:IsA("BasePart") or obj:IsA("Model") then
                addCandidate(obj)
            else
                for _, child in ipairs(obj:GetDescendants()) do
                    if child:IsA("BasePart") or child:IsA("Model") then
                        local childLower = string.lower(child.Name)

                        if string.find(childLower, "coin", 1, true)
                        or childLower == "handle" then
                            addCandidate(child)
                        end
                    end
                end
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

local function StopAutoFarm(restore)
    if AutoFarmTween then
        pcall(function()
            AutoFarmTween:Cancel()
        end)
    end

    AutoFarmTween = nil

    if AutoFarmRoot and AutoFarmRoot.Parent then
        if restore and AutoFarmReturnCFrame then
            local allow = getgenv().AllowToxTeleport

            if allow then
                allow(0.8)
            end

            AutoFarmRoot.CFrame = AutoFarmReturnCFrame
        end

        AutoFarmRoot.AssemblyLinearVelocity = Vector3.zero
        AutoFarmRoot.AssemblyAngularVelocity = Vector3.zero
        AutoFarmRoot.Anchored = AutoFarmOriginalAnchored
    end

    if AutoFarmHumanoid and AutoFarmHumanoid.Parent and AutoFarmHumanoid.Health > 0 then
        AutoFarmHumanoid.PlatformStand = false
        AutoFarmHumanoid.Sit = false
        AutoFarmHumanoid.AutoRotate = true
    end

    AutoFarmRoot = nil
    AutoFarmHumanoid = nil
    AutoFarmReturnCFrame = nil
    AutoFarmPrepared = false
end

local function PrepareAutoFarm()
    local character, humanoid, root, alive = IsAliveCharacter()

    if not alive then
        return false
    end

    if AutoFarmPrepared and AutoFarmRoot == root then
        return true
    end

    StopAutoFarm(false)

    AutoFarmRoot = root
    AutoFarmHumanoid = humanoid
    AutoFarmReturnCFrame = character:GetPivot()
    AutoFarmOriginalAnchored = root.Anchored
    AutoFarmPrepared = true

    humanoid.PlatformStand = false
    humanoid.Sit = false
    humanoid.AutoRotate = false

    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    root.Anchored = true

    local pivot = character:GetPivot()
    local underground = CFrame.new(
        pivot.Position.X,
        pivot.Position.Y - 9.5,
        pivot.Position.Z
    ) * pivot.Rotation

    character:PivotTo(underground)

    return true
end

local function TweenFarmCharacter(targetCFrame, duration, coin)
    local character = Player.Character

    if not character
    or not AutoFarmRoot
    or not AutoFarmRoot.Parent
    or character ~= AutoFarmRoot.Parent then
        return false
    end

    duration = math.max(duration, 0.03)

    local value = Instance.new("CFrameValue")
    value.Value = character:GetPivot()

    local connection = value:GetPropertyChangedSignal("Value"):Connect(function()
        if character
        and character.Parent
        and Settings.MM2AutoFarm
        and AutoFarmRoot
        and AutoFarmRoot.Parent then
            character:PivotTo(value.Value)
        end
    end)

    local tween = TweenService:Create(
        value,
        TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
        {Value = targetCFrame}
    )

    AutoFarmTween = tween
    tween:Play()

    while tween.PlaybackState == Enum.PlaybackState.Playing do
        if not Settings.MM2AutoFarm
        or not AutoFarmRoot
        or not AutoFarmRoot.Parent
        or not AutoFarmHumanoid
        or AutoFarmHumanoid.Health <= 0 then
            tween:Cancel()
            break
        end

        if coin and not IsCoinValid(coin) then
            tween:Cancel()
            break
        end

        task.wait(0.02)
    end

    local completed = tween.PlaybackState == Enum.PlaybackState.Completed

    connection:Disconnect()
    value:Destroy()
    AutoFarmTween = nil

    return completed
end

local function PulseFarmCoin(coin)
    if not IsCoinValid(coin) then
        return false
    end

    local character, humanoid, root, alive = IsAliveCharacter()

    if not alive then
        return false
    end

    local rotation = character:GetPivot().Rotation
    local underground = CFrame.new(
        coin.Position.X,
        coin.Position.Y - 9.5,
        coin.Position.Z
    ) * rotation

    for _ = 1, 3 do
        if not IsCoinValid(coin) then
            break
        end

        character:PivotTo(
            CFrame.new(
                coin.Position.X,
                coin.Position.Y + 1.7,
                coin.Position.Z
            ) * rotation
        )

        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero

        TouchCoin(coin)
        RunService.Heartbeat:Wait()
        TouchCoin(coin)
        task.wait(0.025)

        character:PivotTo(underground)
        RunService.Heartbeat:Wait()
    end

    return not IsCoinValid(coin)
end

local function AutoFarmCoin(coin)
    if not IsCoinValid(coin) or not PrepareAutoFarm() then
        return false
    end

    local character = Player.Character

    if not character then
        return false
    end

    local speed = math.clamp(
        tonumber(Settings.MM2AutoFarmSpeed) or 55,
        15,
        180
    )

    local current = character:GetPivot().Position
    local targetUnder = coin.Position - Vector3.new(0, 9.5, 0)
    local distance = (current - targetUnder).Magnitude

    local targetCFrame = CFrame.new(
        targetUnder.X,
        targetUnder.Y,
        targetUnder.Z
    ) * character:GetPivot().Rotation

    if not TweenFarmCharacter(targetCFrame, distance / speed, coin) then
        return false
    end

    if not IsCoinValid(coin) then
        return true
    end

    local otherDistance = GetOtherPlayerCoinPressure(coin)

    if otherDistance < 3.2 then
        MM2CoinBlacklist[coin] = os.clock() + 1.1
        return false
    end

    local collected = PulseFarmCoin(coin)

    if collected then
        MM2CoinBlacklist[coin] = os.clock() + 0.5
    else
        MM2CoinBlacklist[coin] = os.clock() + 1.6
    end

    return collected
end

local function AIWallHit(fromPosition, toPosition, extraIgnore)
    local direction = toPosition - fromPosition

    if direction.Magnitude < 0.2 then
        return false
    end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.IgnoreWater = true

    local ignore = {Player.Character}

    if extraIgnore then
        for _, item in ipairs(extraIgnore) do
            table.insert(ignore, item)
        end
    end

    params.FilterDescendantsInstances = ignore

    local result = workspace:Raycast(fromPosition, direction, params)

    if not result then
        return false
    end

    local hit = result.Instance

    if not hit or not hit.CanCollide or hit.Transparency >= 0.8 then
        return false
    end

    local model = hit:FindFirstAncestorOfClass("Model")

    if model and model:FindFirstChildOfClass("Humanoid") then
        return false
    end

    local lowerName = string.lower(hit.Name)

    if string.find(lowerName, "coin", 1, true)
    or string.find(lowerName, "gun", 1, true)
    or string.find(lowerName, "trigger", 1, true)
    or string.find(lowerName, "doorframe", 1, true) then
        return false
    end

    return true
end

local function AICorridorClear(startPosition, targetPosition, extraIgnore)
    local flat = Vector3.new(
        targetPosition.X - startPosition.X,
        0,
        targetPosition.Z - startPosition.Z
    )

    if flat.Magnitude < 0.5 then
        return true
    end

    local direction = flat.Unit
    local right = Vector3.new(-direction.Z, 0, direction.X) * 1.15

    for _, height in ipairs({0.8, 2.3}) do
        local from = startPosition + Vector3.new(0, height, 0)
        local to = Vector3.new(targetPosition.X, from.Y, targetPosition.Z)

        if AIWallHit(from, to, extraIgnore)
        or AIWallHit(from + right, to + right, extraIgnore)
        or AIWallHit(from - right, to - right, extraIgnore) then
            return false
        end
    end

    return true
end

local function AIHasLineOfSight(targetCharacter, targetPosition)
    local character, humanoid, root, alive = IsAliveCharacter()

    if not alive then
        return false
    end

    local head = character:FindFirstChild("Head")
    local origin = head and head.Position or root.Position + Vector3.new(0, 1.8, 0)

    return not AIWallHit(origin, targetPosition, targetCharacter and {targetCharacter} or nil)
end

local function AIGroundPoint(position)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {Player.Character}
    params.IgnoreWater = true

    local ray = workspace:Raycast(
        position + Vector3.new(0, 7, 0),
        Vector3.new(0, -28, 0),
        params
    )

    if ray then
        return ray.Position + Vector3.new(0, 1.5, 0)
    end

    return position
end

local function AIObstacleAction(root, direction)
    if direction.Magnitude < 0.1 then
        return false, false
    end

    local flat = Vector3.new(direction.X, 0, direction.Z)

    if flat.Magnitude < 0.1 then
        return false, false
    end

    flat = flat.Unit

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {Player.Character}
    params.IgnoreWater = true

    local low = workspace:Raycast(
        root.Position + Vector3.new(0, 0.2, 0),
        flat * 3.3,
        params
    )

    local high = workspace:Raycast(
        root.Position + Vector3.new(0, 2.7, 0),
        flat * 3.3,
        params
    )

    local ceiling = workspace:Raycast(
        root.Position + Vector3.new(0, 2.3, 0),
        Vector3.new(0, 3.5, 0),
        params
    )

    local lowBlocked = low and low.Instance and low.Instance.CanCollide
    local highBlocked = high and high.Instance and high.Instance.CanCollide

    if lowBlocked and not highBlocked and not ceiling then
        return false, true
    end

    if highBlocked then
        return true, false
    end

    return false, false
end

local function AIWalkSegment(targetPosition, stopDistance, maxTime, continueCheck)
    local character, humanoid, root, alive = IsAliveCharacter()

    if not alive then
        return false
    end

    humanoid.PlatformStand = false
    humanoid.Sit = false
    humanoid.AutoRotate = true

    local startTime = os.clock()
    local lastProgressTime = os.clock()
    local lastPosition = root.Position
    local lastJump = 0
    local sidestepSign = 1

    while Settings.MM2AutoPlay
    and humanoid.Health > 0
    and root.Parent
    and os.clock() - startTime < maxTime do
        if continueCheck and not continueCheck() then
            break
        end

        local flat = Vector3.new(
            targetPosition.X - root.Position.X,
            0,
            targetPosition.Z - root.Position.Z
        )

        local distance = flat.Magnitude

        if distance <= stopDistance then
            humanoid:Move(Vector3.zero, false)
            return true
        end

        local direction = flat.Unit
        local wall, jumpable = AIObstacleAction(root, direction)

        if jumpable and os.clock() - lastJump > 0.75 then
            humanoid.Jump = true
            lastJump = os.clock()
        elseif wall then
            humanoid:Move(Vector3.zero, false)
            return false
        end

        humanoid:Move(direction, false)

        local moved = (root.Position - lastPosition).Magnitude

        if moved >= 0.4 then
            lastPosition = root.Position
            lastProgressTime = os.clock()
        else
            local stalled = os.clock() - lastProgressTime

            if stalled > 0.65 and stalled <= 1.15 then
                if os.clock() - lastJump > 0.75 then
                    humanoid.Jump = true
                    lastJump = os.clock()
                end
            elseif stalled > 1.15 and stalled <= 1.65 then
                sidestepSign = -sidestepSign
                local side = Vector3.new(-direction.Z, 0, direction.X) * sidestepSign
                humanoid:Move(side, false)
            elseif stalled > 1.65 then
                humanoid:Move(Vector3.zero, false)
                return false
            end
        end

        task.wait(0.04)
    end

    humanoid:Move(Vector3.zero, false)
    return false
end

local function AIWalkTo(targetPosition, stopDistance, maxTime, continueCheck)
    local _, humanoid, root, alive = IsAliveCharacter()

    if not alive then
        return false
    end

    local groundedTarget = AIGroundPoint(targetPosition)

    if AICorridorClear(root.Position, groundedTarget) then
        return AIWalkSegment(
            groundedTarget,
            stopDistance or 2.2,
            maxTime or 4,
            continueCheck
        )
    end

    local path = PathfindingService:CreatePath({
        AgentRadius = 2.3,
        AgentHeight = 5,
        AgentCanJump = true,
        WaypointSpacing = 4.5
    })

    local success = pcall(function()
        path:ComputeAsync(
            AIGroundPoint(root.Position),
            groundedTarget
        )
    end)

    if not success or path.Status ~= Enum.PathStatus.Success then
        return false
    end

    local waypoints = path:GetWaypoints()

    if #waypoints < 2 then
        return false
    end

    local startTime = os.clock()
    local index = 2

    while index <= #waypoints
    and Settings.MM2AutoPlay
    and humanoid.Health > 0
    and os.clock() - startTime < (maxTime or 6) do
        if continueCheck and not continueCheck() then
            return false
        end

        local currentRoot = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")

        if not currentRoot then
            return false
        end

        local farthest = index

        for testIndex = math.min(#waypoints, index + 3), index, -1 do
            if AICorridorClear(currentRoot.Position, waypoints[testIndex].Position) then
                farthest = testIndex
                break
            end
        end

        index = farthest
        local waypoint = waypoints[index]

        if waypoint.Action == Enum.PathWaypointAction.Jump then
            humanoid.Jump = true
        end

        local reached = AIWalkSegment(
            waypoint.Position,
            index == #waypoints and (stopDistance or 2.2) or 2.4,
            2.2,
            continueCheck
        )

        if not reached and index < #waypoints then
            return false
        end

        index = index + 1
    end

    local finalRoot = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")

    return finalRoot
        and Vector3.new(
            finalRoot.Position.X - groundedTarget.X,
            0,
            finalRoot.Position.Z - groundedTarget.Z
        ).Magnitude <= (stopDistance or 2.2) + 1.5
end

local function GetClosestAliveTarget()
    local _, _, root, alive = IsAliveCharacter()

    if not alive then
        return nil
    end

    local best = nil
    local bestDistance = math.huge

    for _, target in ipairs(Players:GetPlayers()) do
        if target ~= Player and target.Character then
            local targetHumanoid = target.Character:FindFirstChildOfClass("Humanoid")
            local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")

            if targetHumanoid and targetHumanoid.Health > 0 and targetRoot then
                local distance = (root.Position - targetRoot.Position).Magnitude

                if distance < bestDistance then
                    bestDistance = distance
                    best = target
                end
            end
        end
    end

    return best, bestDistance
end

local function GetAIShotPosition(targetRoot)
    local _, _, root, alive = IsAliveCharacter()

    if not alive then
        return targetRoot.Position
    end

    local distance = (root.Position - targetRoot.Position).Magnitude
    local ping = 0.06

    pcall(function()
        ping = math.clamp(Player:GetNetworkPing(), 0.02, 0.18)
    end)

    local leadTime = math.clamp((distance / 280) + ping * 0.7, 0.035, 0.28)
    local velocity = targetRoot.AssemblyLinearVelocity
    local lead = velocity * leadTime

    lead = Vector3.new(
        math.clamp(lead.X, -12, 12),
        math.clamp(lead.Y, -6, 8),
        math.clamp(lead.Z, -12, 12)
    )

    return targetRoot.Position + Vector3.new(0, 1.1, 0) + lead
end

local function AIShootVisibleMurderer(murderer)
    if ActionBusy or os.clock() - AutoPlayLastShot < 0.85 then
        return false
    end

    local gun = FindNamedTool({"gun", "revolver"})
    local targetCharacter = murderer and murderer.Character
    local targetHumanoid = targetCharacter and targetCharacter:FindFirstChildOfClass("Humanoid")
    local targetRoot = targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart")

    if not gun
    or not targetHumanoid
    or targetHumanoid.Health <= 0
    or not targetRoot then
        return false
    end

    for _ = 1, 3 do
        if not AIHasLineOfSight(
            targetCharacter,
            targetRoot.Position + Vector3.new(0, 1.2, 0)
        ) then
            return false
        end

        RunService.RenderStepped:Wait()
    end

    ActionBusy = true
    AutoPlayLastShot = os.clock()

    local originalCamera = Camera.CFrame
    local originalParent = gun.Parent

    if not EquipTool(gun) then
        ActionBusy = false
        return false
    end

    for _ = 1, 4 do
        if not targetRoot.Parent
        or targetHumanoid.Health <= 0
        or not AIHasLineOfSight(
            targetCharacter,
            targetRoot.Position + Vector3.new(0, 1.2, 0)
        ) then
            ActionBusy = false
            return false
        end

        local aimPosition = GetAIShotPosition(targetRoot)

        Camera.CFrame = Camera.CFrame:Lerp(
            CFrame.lookAt(Camera.CFrame.Position, aimPosition),
            0.58
        )

        RunService.RenderStepped:Wait()
    end

    pcall(function()
        gun:Activate()
    end)

    NormalGunClick()
    task.wait(0.06)

    if Camera then
        Camera.CFrame = originalCamera
    end

    local character = Player.Character

    if originalParent
    and originalParent:IsA("Backpack")
    and gun
    and character
    and gun.Parent == character then
        pcall(function()
            gun.Parent = originalParent
        end)
    end

    ActionBusy = false
    return true
end

local function AIPickupGun(gunDrop)
    local character, humanoid, root, alive = IsAliveCharacter()

    if not alive or not gunDrop or not gunDrop.Parent then
        return false
    end

    local reached = AIWalkTo(
        gunDrop.Position,
        1.8,
        5,
        function()
            return Settings.MM2AutoPlay
                and gunDrop.Parent ~= nil
                and humanoid.Health > 0
                and not FindNamedTool({"gun", "revolver"})
        end
    )

    if reached or (root.Position - gunDrop.Position).Magnitude <= 4.5 then
        if firetouchinterest then
            pcall(function()
                firetouchinterest(root, gunDrop, 0)
                firetouchinterest(root, gunDrop, 1)
            end)

            local hand = character:FindFirstChild("RightHand")
                or character:FindFirstChild("Right Arm")

            if hand and hand:IsA("BasePart") then
                pcall(function()
                    firetouchinterest(hand, gunDrop, 0)
                    firetouchinterest(hand, gunDrop, 1)
                end)
            end
        end

        task.wait(0.08)
        return FindNamedTool({"gun", "revolver"}) ~= nil
    end

    return false
end

local function GetPatrolTarget()
    local _, _, root, alive = IsAliveCharacter()

    if not alive then
        return nil
    end

    if AutoPlayPatrolTarget
    and Vector3.new(
        root.Position.X - AutoPlayPatrolTarget.X,
        0,
        root.Position.Z - AutoPlayPatrolTarget.Z
    ).Magnitude > 5 then
        return AutoPlayPatrolTarget
    end

    local forward = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)

    if forward.Magnitude < 0.1 then
        forward = Vector3.new(0, 0, -1)
    else
        forward = forward.Unit
    end

    local directions = {
        forward,
        (CFrame.Angles(0, math.rad(45), 0):VectorToWorldSpace(forward)).Unit,
        (CFrame.Angles(0, math.rad(-45), 0):VectorToWorldSpace(forward)).Unit,
        (CFrame.Angles(0, math.rad(90), 0):VectorToWorldSpace(forward)).Unit,
        (CFrame.Angles(0, math.rad(-90), 0):VectorToWorldSpace(forward)).Unit
    }

    for _, direction in ipairs(directions) do
        local sample = root.Position + direction * 28
        local ground = AIGroundPoint(sample)

        if ground and AICorridorClear(root.Position, ground) then
            AutoPlayPatrolTarget = ground
            return ground
        end
    end

    AutoPlayPatrolTarget = nil
    return nil
end

local function GetRandomAutoPlayCoin(origin)
    local coins = GetMM2Coins(false)
    local candidates = {}
    local now = os.clock()

    for coin, expiry in pairs(MM2CoinBlacklist) do
        if not coin.Parent or now >= expiry then
            MM2CoinBlacklist[coin] = nil
        end
    end

    for _, coin in ipairs(coins) do
        if IsCoinValid(coin) and not MM2CoinBlacklist[coin] then
            local myDistance = (origin - coin.Position).Magnitude

            if myDistance <= 140 then
                local otherDistance, incoming = GetOtherPlayerCoinPressure(coin)
                local contested = otherDistance + 2 < myDistance
                    or (incoming and otherDistance < myDistance + 8)

                if not contested then
                    table.insert(candidates, coin)
                end
            end
        end
    end

    if #candidates == 0 then
        return nil
    end

    return candidates[math.random(1, #candidates)]
end

local function GetFleePoint(murdererRoot)
    local _, _, root, alive = IsAliveCharacter()

    if not alive or not murdererRoot then
        return nil
    end

    local away = Vector3.new(
        root.Position.X - murdererRoot.Position.X,
        0,
        root.Position.Z - murdererRoot.Position.Z
    )

    if away.Magnitude < 0.1 then
        away = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
    end

    if away.Magnitude < 0.1 then
        away = Vector3.new(0, 0, 1)
    end

    away = away.Unit

    local best = nil
    local bestScore = -math.huge

    for _, angle in ipairs({0, 30, -30, 55, -55, 85, -85}) do
        local direction = CFrame.Angles(
            0,
            math.rad(angle),
            0
        ):VectorToWorldSpace(away)

        local sample = root.Position + direction * 32
        local ground = AIGroundPoint(sample)
        local distanceFromMurderer = (
            Vector3.new(
                ground.X - murdererRoot.Position.X,
                0,
                ground.Z - murdererRoot.Position.Z
            )
        ).Magnitude

        local score = distanceFromMurderer

        if AICorridorClear(root.Position, ground) then
            score = score + 35
        end

        if score > bestScore then
            bestScore = score
            best = ground
        end
    end

    return best
end

local function AIFleeMurderer(murderer)
    local murdererCharacter = murderer and murderer.Character
    local murdererHumanoid = murdererCharacter and murdererCharacter:FindFirstChildOfClass("Humanoid")
    local murdererRoot = murdererCharacter and murdererCharacter:FindFirstChild("HumanoidRootPart")

    if not murdererHumanoid
    or murdererHumanoid.Health <= 0
    or not murdererRoot then
        return false
    end

    local fleePoint = GetFleePoint(murdererRoot)

    if not fleePoint then
        return false
    end

    return AIWalkTo(
        fleePoint,
        3,
        2.8,
        function()
            if not Settings.MM2AutoPlay
            or not murdererRoot.Parent
            or murdererHumanoid.Health <= 0 then
                return false
            end

            return true
        end
    )
end

local function AINaturalKnifeAttack(knife, target)
    if not knife or not target or not target.Character then
        return false
    end

    local targetHumanoid = target.Character:FindFirstChildOfClass("Humanoid")
    local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
    local _, humanoid, root, alive = IsAliveCharacter()

    if not alive
    or not targetHumanoid
    or targetHumanoid.Health <= 0
    or not targetRoot then
        return false
    end

    EquipTool(knife)

    local startTime = os.clock()
    local lastJump = 0
    local lastSwing = 0
    local lastProgress = os.clock()
    local lastPosition = root.Position

    while Settings.MM2AutoPlay
    and humanoid.Health > 0
    and targetHumanoid.Health > 0
    and targetRoot.Parent
    and os.clock() - startTime < 3.2 do
        local offset = targetRoot.Position - root.Position
        local horizontal = Vector3.new(offset.X, 0, offset.Z)
        local distance = horizontal.Magnitude

        if distance > 0.1 then
            local direction = horizontal.Unit
            local wall, jumpable = AIObstacleAction(root, direction)

            if wall then
                AIWalkTo(
                    targetRoot.Position,
                    5.2,
                    1.1,
                    function()
                        return Settings.MM2AutoPlay
                            and targetHumanoid.Health > 0
                            and targetRoot.Parent ~= nil
                    end
                )
            else
                humanoid:Move(direction, false)

                local targetState = targetHumanoid:GetState()
                local targetJumping = targetRoot.AssemblyLinearVelocity.Y > 4
                    or targetState == Enum.HumanoidStateType.Jumping
                    or targetState == Enum.HumanoidStateType.Freefall

                if (jumpable or targetJumping or offset.Y > 2.2)
                and os.clock() - lastJump > 0.65 then
                    humanoid.Jump = true
                    lastJump = os.clock()
                end
            end
        end

        if distance <= 5.3 and os.clock() - lastSwing > 0.28 then
            lastSwing = os.clock()

            pcall(function()
                knife:Activate()
            end)

            NormalGunClick()
        end

        if (root.Position - lastPosition).Magnitude > 0.45 then
            lastPosition = root.Position
            lastProgress = os.clock()
        elseif os.clock() - lastProgress > 1.2 then
            humanoid.Jump = true
            lastProgress = os.clock()
        end

        task.wait(0.045)
    end

    humanoid:Move(Vector3.zero, false)
    return targetHumanoid.Health <= 0
end

local function AutoPlayStep()
    local character, humanoid, root, alive = IsAliveCharacter()

    if not alive or ActionBusy then
        task.wait(0.08)
        return
    end

    local knife = FindNamedTool({"knife"})
    local gun = FindNamedTool({"gun", "revolver"})
    local role = GetRole(Player)
    local murderer = GetPlayerByRole("Murderer")
    local murdererCharacter = murderer and murderer.Character
    local murdererHumanoid = murdererCharacter and murdererCharacter:FindFirstChildOfClass("Humanoid")
    local murdererRoot = murdererCharacter and murdererCharacter:FindFirstChild("HumanoidRootPart")

    if knife or role == "Murderer" then
        local target = GetClosestAliveTarget()

        if target and knife then
            AINaturalKnifeAttack(knife, target)
            return
        end
    end

    if murderer
    and murdererHumanoid
    and murdererHumanoid.Health > 0
    and murdererRoot
    and murderer ~= Player then
        local murdererDistance = (root.Position - murdererRoot.Position).Magnitude
        local visible = AIHasLineOfSight(
            murdererCharacter,
            murdererRoot.Position + Vector3.new(0, 1.2, 0)
        )

        if gun and visible and murdererDistance <= 85 then
            AIShootVisibleMurderer(murderer)
            task.wait(0.1)
            return
        end

        if not knife
        and (
            (visible and murdererDistance <= 38)
            or murdererDistance <= 17
        ) then
            AIFleeMurderer(murderer)
            return
        end
    end

    if not gun
    and not knife
    and (role == "Innocent" or role == nil) then
        local gunDrop = FindGunDrop()

        if gunDrop and gunDrop.Parent then
            local safeToGrab = true

            if murdererRoot and murdererHumanoid and murdererHumanoid.Health > 0 then
                local murderToGun = (murdererRoot.Position - gunDrop.Position).Magnitude

                if murderToGun < 13 then
                    safeToGrab = false
                end
            end

            if safeToGrab then
                AIPickupGun(gunDrop)
                return
            end
        end
    end

    local coin = GetRandomAutoPlayCoin(root.Position)

    if coin then
        local reached = AIWalkTo(
            coin.Position,
            1.6,
            4.8,
            function()
                if not Settings.MM2AutoPlay or not IsCoinValid(coin) then
                    return false
                end

                if murdererRoot
                and murdererHumanoid
                and murdererHumanoid.Health > 0 then
                    local murderDistance = (
                        root.Position - murdererRoot.Position
                    ).Magnitude

                    if murderDistance <= 16 then
                        return false
                    end
                end

                return true
            end
        )

        if reached or (root.Position - coin.Position).Magnitude <= 4.2 then
            TouchCoin(coin)
            task.wait(0.06)
            MM2CoinBlacklist[coin] = os.clock() + 0.7
        else
            MM2CoinBlacklist[coin] = os.clock() + 4
        end

        return
    end

    local patrol = GetPatrolTarget()

    if patrol then
        AIWalkTo(
            patrol,
            3,
            4,
            function()
                return Settings.MM2AutoPlay
            end
        )
    else
        humanoid:Move(Vector3.zero, false)
        task.wait(0.15)
    end
end


task.spawn(function()
    while not getgenv().Destroyed and game.PlaceId == 142823291 do
        if Settings.MM2AutoFarm then
            local _, humanoid, root, alive = IsAliveCharacter()

            if alive and not ActionBusy then
                local coin = GetBestCoin(root.Position, true)

                if coin then
                    AutoFarmCoin(coin)
                else
                    task.wait(0.08)
                end
            else
                if AutoFarmPrepared and (not humanoid or humanoid.Health <= 0) then
                    StopAutoFarm(false)
                end

                task.wait(0.08)
            end
        else
            if AutoFarmPrepared then
                StopAutoFarm(true)
            end

            task.wait(0.08)
        end
    end
end)

task.spawn(function()
    while not getgenv().Destroyed and game.PlaceId == 142823291 do
        if Settings.MM2AutoPlay and not Settings.MM2AutoFarm then
            pcall(AutoPlayStep)
            task.wait(0.05)
        else
            local _, humanoid = GetCharacterState()

            if humanoid and humanoid.Health > 0 then
                humanoid:Move(Vector3.zero, false)
            end

            AutoPlayPatrolTarget = nil
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

CreateToggle("Auto Play", GamePage, Settings.MM2AutoPlay, function(v)
    Settings.MM2AutoPlay = v == true

    if v then
        Settings.MM2AutoFarm = false

        if SyncToggleVisuals then
            SyncToggleVisuals("MM2AutoFarm", false)
        end

        if AutoFarmPrepared then
            StopAutoFarm(true)
        end
    else
        local _, humanoid = GetCharacterState()

        if humanoid and humanoid.Health > 0 then
            humanoid:Move(Vector3.zero, false)
        end

        AutoPlayPatrolTarget = nil
    end

    AutoSaveConfiguration()
end, "MM2AutoPlay")

CreateToggleWithValue("Auto Farm", GamePage, Settings.MM2AutoFarm, Settings.MM2AutoFarmSpeed, function(v)
    Settings.MM2AutoFarm = v == true

    if v then
        Settings.MM2AutoPlay = false

        if SyncToggleVisuals then
            SyncToggleVisuals("MM2AutoPlay", false)
        end
    else
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

        if Settings.MM2KillAllAuto and not Settings.MM2AutoPlay and not Settings.MM2AutoFarm then
            if knife and not AutoKnifeOwned and alive and not ActionBusy then
                AutoKnifeOwned = true
                task.spawn(KillAll)
            elseif not knife then
                AutoKnifeOwned = false
            end
        else
            AutoKnifeOwned = knife ~= nil
        end

        if Settings.MM2ShootMurderAuto and not Settings.MM2AutoPlay and not Settings.MM2AutoFarm then
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
        and not Settings.MM2AutoPlay
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
