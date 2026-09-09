if game.PlaceId ~= 142823291 then
    return
end

local MM2ModuleVersion = "2026-09-08-silent-normal-shot-6"

if getgenv().ToxMM2ModuleLoadedJobId == game.JobId
and getgenv().ToxMM2ModuleVersion == MM2ModuleVersion
and not getgenv().Destroyed then
    return
end

if getgenv().ToxMM2ModuleLoadedJobId == game.JobId
and getgenv().ToxMM2Cleanup then
    pcall(getgenv().ToxMM2Cleanup)
end

getgenv().ToxMM2ModuleLoadedJobId = game.JobId
getgenv().ToxMM2ModuleVersion = MM2ModuleVersion

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
local MAIN_COLOR = getgenv().MAIN_COLOR or Color3.fromRGB(9, 0, 136)
local MakeDraggable = getgenv().MakeDraggable

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

Settings.MM2SilentAimKey = Settings.MM2SilentAimKey or Enum.KeyCode.E
Settings.MM2KillAllKey = Settings.MM2KillAllKey or Enum.KeyCode.K
Settings.MM2KillAllAutoV2 = Settings.MM2KillAllAutoV2 == true or Settings.MM2KillAllAuto == true
Settings.MM2KillAllAuto = false
Settings.MM2ShootMurderKey = Settings.MM2ShootMurderKey or Enum.KeyCode.C
Settings.MM2ShootMurderAutoV2 = Settings.MM2ShootMurderAutoV2 == true or Settings.MM2ShootMurderAuto == true
Settings.MM2ShootMurderAuto = false
Settings.MM2GrabGunKey = Settings.MM2GrabGunKey or Enum.KeyCode.G
Settings.MM2GrabGunAutoV2 = Settings.MM2GrabGunAutoV2 == true or Settings.MM2GrabGunAuto == true
Settings.MM2GrabGunAuto = false
Settings.MM2FlingTarget = Settings.MM2FlingTarget or "Murderer"

local ResumeAutoFarmAfterAntiKick =
    getgenv().__ToxAntiKickResume
    == true
    and getgenv().__ToxAntiKickResumeFarm
        == true

getgenv().__ToxAntiKickResume = nil
getgenv().__ToxAntiKickResumeFarm = nil

Settings.MM2AutoFarmV2 =
    ResumeAutoFarmAfterAntiKick

Settings.MM2AutoFarmResetOnFull =
    Settings.MM2AutoFarmResetOnFull == true

local configuredAutoFarmSpeed = tonumber(Settings.MM2AutoFarmSpeed)

if not configuredAutoFarmSpeed or configuredAutoFarmSpeed == 50 then
    configuredAutoFarmSpeed = 5
end

Settings.MM2AutoFarmSpeed = math.clamp(
    configuredAutoFarmSpeed,
    5,
    250
)
Settings.MM2Whitelist = typeof(Settings.MM2Whitelist) == "table" and Settings.MM2Whitelist or {}

local ActionBusy = false

if ResumeAutoFarmAfterAntiKick then
    task.delay(
        2,
        function()
            if not getgenv().Destroyed then
                CustomNotify(
                    "Anti Kick • Auto Farm resumed",
                    Color3.fromRGB(
                        100,
                        255,
                        130
                    ),
                    5
                )
            end
        end
    )
end

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

local KnifeTargetIds = {}
local PlayerSelectorFrame = nil
local PlayerSelectorScroll = nil
local PlayerSelectorTitle = nil
local PlayerSelectorInput = nil
local PlayerSelectorAction = nil
local PlayerSelectorMode = "targets"

local function IsWhitelisted(target)
    if not target then
        return false
    end

    for _, userId in ipairs(Settings.MM2Whitelist) do
        if tonumber(userId) == target.UserId then
            return true
        end
    end

    return false
end

local function SetWhitelisted(target, enabled)
    if not target or target == Player then
        return
    end

    local foundIndex = nil

    for index, userId in ipairs(Settings.MM2Whitelist) do
        if tonumber(userId) == target.UserId then
            foundIndex = index
            break
        end
    end

    if enabled and not foundIndex then
        table.insert(Settings.MM2Whitelist, target.UserId)
    elseif not enabled and foundIndex then
        table.remove(Settings.MM2Whitelist, foundIndex)
    end

    if enabled then
        KnifeTargetIds[target.UserId] = nil
    end

    AutoSaveConfiguration()
end

local function FindCurrentPlayer(text)
    local clean = string.lower(
        tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", "")
    )

    if clean == "" then
        return nil
    end

    local numericId = tonumber(clean)

    for _, target in ipairs(Players:GetPlayers()) do
        if target ~= Player then
            if numericId and target.UserId == numericId then
                return target
            end

            if string.lower(target.Name) == clean
            or string.lower(target.DisplayName) == clean then
                return target
            end
        end
    end

    for _, target in ipairs(Players:GetPlayers()) do
        if target ~= Player then
            local name = string.lower(target.Name)
            local displayName = string.lower(target.DisplayName)

            if name:sub(1, #clean) == clean
            or displayName:sub(1, #clean) == clean then
                return target
            end
        end
    end

    return nil
end

local function CleanKnifeTargets()
    local present = {}

    for _, target in ipairs(Players:GetPlayers()) do
        present[target.UserId] = true
    end

    for userId in pairs(KnifeTargetIds) do
        if not present[userId] then
            KnifeTargetIds[userId] = nil
        end
    end
end

local function GetSelectedKnifeTargets()
    CleanKnifeTargets()

    local targets = {}

    for _, target in ipairs(Players:GetPlayers()) do
        if target ~= Player
        and KnifeTargetIds[target.UserId]
        and not IsWhitelisted(target) then
            local humanoid = target.Character and target.Character:FindFirstChildOfClass("Humanoid")

            if humanoid and humanoid.Health > 0 then
                table.insert(targets, target)
            end
        end
    end

    return targets
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

local function KnifeTargetAlive(
    target
)
    local humanoid =
        target
        and target.Character
        and target.Character:
            FindFirstChildOfClass(
                "Humanoid"
            )

    return humanoid
        and humanoid.Health > 0
end

local function AttackKnifeTargetUntilDone(
    knife,
    target,
    timeout
)
    timeout =
        tonumber(timeout)
        or 3.5

    local started =
        os.clock()

    local attacked = false

    while not getgenv().Destroyed
    and knife
    and knife.Parent
    and target
    and target.Parent == Players
    and KnifeTargetAlive(
        target
    )
    and os.clock() - started
        < timeout do
        if knife:IsA("Tool")
        and knife.Enabled == false then
            RunService.Heartbeat:
                Wait()
        else
            if TouchKnifeTarget(
                knife,
                target
            ) then
                attacked = true
            end

            task.wait(0.035)
        end
    end

    return attacked
        and not KnifeTargetAlive(
            target
        )
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
            if target ~= Player
            and not IsWhitelisted(target) then
                AttackKnifeTargetUntilDone(
                    knife,
                    target,
                    3.5
                )

                task.wait(0.015)
            end
        end

        ActionBusy = false
    end)
end

local function KillSelectedTargets()
    if ActionBusy then
        return
    end

    local knife = FindNamedTool({"knife"})

    if not knife then
        CustomNotify(
            "Kill Selected requires the Knife",
            Color3.fromRGB(255, 100, 100)
        )
        return
    end

    local targets = GetSelectedKnifeTargets()

    if #targets == 0 then
        CustomNotify(
            "No selected players available",
            Color3.fromRGB(255, 180, 70)
        )
        return
    end

    if not EquipTool(knife) then
        CustomNotify(
            "Could not equip Knife",
            Color3.fromRGB(255, 100, 100)
        )
        return
    end

    ActionBusy = true

    task.spawn(function()
        for _, target in ipairs(targets) do
            if getgenv().Destroyed then
                break
            end

            if target.Parent == Players
            and not IsWhitelisted(target) then
                AttackKnifeTargetUntilDone(
                    knife,
                    target,
                    3.5
                )

                task.wait(0.015)
            end
        end

        ActionBusy = false
    end)
end

local function UpdateSelectorActionText()
    if not PlayerSelectorAction then
        return
    end

    if PlayerSelectorMode == "targets" then
        local count = 0

        for _ in pairs(KnifeTargetIds) do
            count = count + 1
        end

        PlayerSelectorAction.Text = "Kill Selected (" .. tostring(count) .. ")"
    else
        PlayerSelectorAction.Text = "Close"
    end
end

local function RefreshPlayerSelector()
    if not PlayerSelectorScroll then
        return
    end

    if PlayerSelectorMode == "targets" then
        CleanKnifeTargets()
    end

    for _, child in ipairs(PlayerSelectorScroll:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    local playerList = {}

    for _, target in ipairs(Players:GetPlayers()) do
        if target ~= Player then
            table.insert(playerList, target)
        end
    end

    table.sort(playerList, function(a, b)
        return string.lower(a.Name) < string.lower(b.Name)
    end)

    for index, target in ipairs(playerList) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -4, 0, 36)
        row.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
        row.BorderSizePixel = 0
        row.LayoutOrder = index
        row.Parent = PlayerSelectorScroll

        local rowCorner = Instance.new("UICorner")
        rowCorner.CornerRadius = UDim.new(0, 4)
        rowCorner.Parent = row

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, -104, 0, 18)
        nameLabel.Position = UDim2.new(0, 8, 0, 3)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = target.DisplayName
        nameLabel.TextColor3 = Color3.fromRGB(245, 245, 245)
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 11
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        nameLabel.Parent = row

        local userLabel = Instance.new("TextLabel")
        userLabel.Size = UDim2.new(1, -104, 0, 14)
        userLabel.Position = UDim2.new(0, 8, 0, 19)
        userLabel.BackgroundTransparency = 1
        userLabel.Text = "@" .. target.Name
        userLabel.TextColor3 = Color3.fromRGB(140, 140, 160)
        userLabel.Font = Enum.Font.Gotham
        userLabel.TextSize = 9
        userLabel.TextXAlignment = Enum.TextXAlignment.Left
        userLabel.Parent = row

        local selectButton = Instance.new("TextButton")
        selectButton.Size = UDim2.new(0, 86, 0, 24)
        selectButton.Position = UDim2.new(1, -94, 0.5, -12)
        selectButton.BorderSizePixel = 0
        selectButton.Font = Enum.Font.GothamBold
        selectButton.TextSize = 10
        selectButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        selectButton.Parent = row

        local selectCorner = Instance.new("UICorner")
        selectCorner.CornerRadius = UDim.new(0, 4)
        selectCorner.Parent = selectButton

        local whitelisted = IsWhitelisted(target)

        if PlayerSelectorMode == "whitelist" then
            if whitelisted then
                selectButton.Text = "SAFE"
                selectButton.BackgroundColor3 = MAIN_COLOR
            else
                selectButton.Text = "Whitelist"
                selectButton.BackgroundColor3 = Color3.fromRGB(55, 55, 75)
            end
        else
            if whitelisted then
                selectButton.Text = "SAFE"
                selectButton.BackgroundColor3 = MAIN_COLOR
            elseif KnifeTargetIds[target.UserId] then
                selectButton.Text = "SELECTED"
                selectButton.BackgroundColor3 = MAIN_COLOR
            else
                selectButton.Text = "Select"
                selectButton.BackgroundColor3 = Color3.fromRGB(55, 55, 75)
            end
        end

        selectButton.MouseButton1Click:Connect(function()
            if PlayerSelectorMode == "whitelist" then
                SetWhitelisted(target, not IsWhitelisted(target))
            else
                if IsWhitelisted(target) then
                    CustomNotify(
                        target.Name .. " is whitelisted",
                        Color3.fromRGB(255, 180, 70)
                    )
                    return
                end

                KnifeTargetIds[target.UserId] =
                    not KnifeTargetIds[target.UserId] or nil
            end

            RefreshPlayerSelector()
        end)
    end

    UpdateSelectorActionText()
end

local function CreatePlayerSelector()
    if PlayerSelectorFrame and PlayerSelectorFrame.Parent then
        return
    end

    local gui = getgenv().Gui

    if not gui then
        return
    end

    PlayerSelectorFrame = Instance.new("Frame")
    PlayerSelectorFrame.Name = "ToxMM2PlayerSelector"
    PlayerSelectorFrame.Size = UDim2.new(0, 350, 0, 300)
    PlayerSelectorFrame.Position = UDim2.new(0.5, -175, 0.5, -150)
    PlayerSelectorFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 16)
    PlayerSelectorFrame.BorderSizePixel = 0
    PlayerSelectorFrame.Visible = false
    PlayerSelectorFrame.Active = true
    PlayerSelectorFrame.ClipsDescendants = true
    PlayerSelectorFrame.Parent = gui

    if getgenv().RegisterToxLinkedSubGui then
        getgenv().RegisterToxLinkedSubGui(
            "MM2PlayerSelector",
            PlayerSelectorFrame
        )
    end

    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 8)
    frameCorner.Parent = PlayerSelectorFrame

    local frameStroke = Instance.new("UIStroke")
    frameStroke.Color = MAIN_COLOR
    frameStroke.Thickness = 2
    frameStroke.Parent = PlayerSelectorFrame

    local topBar = Instance.new("Frame")
    topBar.Size = UDim2.new(1, 0, 0, 32)
    topBar.BackgroundColor3 = MAIN_COLOR
    topBar.BorderSizePixel = 0
    topBar.Parent = PlayerSelectorFrame

    if getgenv().RegisterToxSubGuiMinimize then
        getgenv().RegisterToxSubGuiMinimize(
            PlayerSelectorFrame,
            -52
        )
    end

    if MakeDraggable then
        MakeDraggable(PlayerSelectorFrame, topBar)
    end

    PlayerSelectorTitle = Instance.new("TextLabel")
    PlayerSelectorTitle.Size = UDim2.new(1, -54, 1, 0)
    PlayerSelectorTitle.Position = UDim2.new(0, 10, 0, 0)
    PlayerSelectorTitle.BackgroundTransparency = 1
    PlayerSelectorTitle.Text = "Knife Targets"
    PlayerSelectorTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    PlayerSelectorTitle.Font = Enum.Font.GothamBold
    PlayerSelectorTitle.TextSize = 13
    PlayerSelectorTitle.TextXAlignment = Enum.TextXAlignment.Left
    PlayerSelectorTitle.Parent = topBar

    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 22, 0, 20)
    closeButton.Position = UDim2.new(1, -26, 0.5, -10)
    closeButton.BackgroundColor3 = Color3.fromRGB(24, 24, 34)
    closeButton.BorderSizePixel = 0
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.fromRGB(210, 210, 220)
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 11
    closeButton.Parent = topBar

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 4)
    closeCorner.Parent = closeButton

    PlayerSelectorInput = Instance.new("TextBox")
    PlayerSelectorInput.Size = UDim2.new(1, -108, 0, 30)
    PlayerSelectorInput.Position = UDim2.new(0, 8, 0, 40)
    PlayerSelectorInput.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
    PlayerSelectorInput.BorderSizePixel = 0
    PlayerSelectorInput.Text = ""
    PlayerSelectorInput.PlaceholderText = "Username / DisplayName / UserId"
    PlayerSelectorInput.TextColor3 = Color3.fromRGB(245, 245, 245)
    PlayerSelectorInput.PlaceholderColor3 = Color3.fromRGB(125, 125, 145)
    PlayerSelectorInput.Font = Enum.Font.Gotham
    PlayerSelectorInput.TextSize = 11
    PlayerSelectorInput.ClearTextOnFocus = false
    PlayerSelectorInput.Parent = PlayerSelectorFrame

    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 4)
    inputCorner.Parent = PlayerSelectorInput

    local addButton = Instance.new("TextButton")
    addButton.Size = UDim2.new(0, 92, 0, 30)
    addButton.Position = UDim2.new(1, -100, 0, 40)
    addButton.BackgroundColor3 = MAIN_COLOR
    addButton.BorderSizePixel = 0
    addButton.Text = "Add"
    addButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    addButton.Font = Enum.Font.GothamBold
    addButton.TextSize = 11
    addButton.Parent = PlayerSelectorFrame

    local addCorner = Instance.new("UICorner")
    addCorner.CornerRadius = UDim.new(0, 4)
    addCorner.Parent = addButton

    PlayerSelectorScroll = Instance.new("ScrollingFrame")
    PlayerSelectorScroll.Size = UDim2.new(1, -16, 1, -116)
    PlayerSelectorScroll.Position = UDim2.new(0, 8, 0, 78)
    PlayerSelectorScroll.BackgroundTransparency = 1
    PlayerSelectorScroll.BorderSizePixel = 0
    PlayerSelectorScroll.ScrollBarThickness = 3
    PlayerSelectorScroll.ScrollBarImageColor3 = MAIN_COLOR
    PlayerSelectorScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    PlayerSelectorScroll.Parent = PlayerSelectorFrame

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 5)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = PlayerSelectorScroll

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        PlayerSelectorScroll.CanvasSize =
            UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8)
    end)

    PlayerSelectorAction = Instance.new("TextButton")
    PlayerSelectorAction.Size = UDim2.new(1, -16, 0, 30)
    PlayerSelectorAction.Position = UDim2.new(0, 8, 1, -36)
    PlayerSelectorAction.BackgroundColor3 = MAIN_COLOR
    PlayerSelectorAction.BorderSizePixel = 0
    PlayerSelectorAction.Text = "Kill Selected (0)"
    PlayerSelectorAction.TextColor3 = Color3.fromRGB(255, 255, 255)
    PlayerSelectorAction.Font = Enum.Font.GothamBold
    PlayerSelectorAction.TextSize = 11
    PlayerSelectorAction.Parent = PlayerSelectorFrame

    local actionCorner = Instance.new("UICorner")
    actionCorner.CornerRadius = UDim.new(0, 4)
    actionCorner.Parent = PlayerSelectorAction

    closeButton.MouseButton1Click:Connect(function()
        PlayerSelectorFrame.Visible = false
    end)

    local function AddFromInput()
        local target = FindCurrentPlayer(PlayerSelectorInput.Text)

        if not target then
            CustomNotify(
                "Player not found in server",
                Color3.fromRGB(255, 180, 70)
            )
            return
        end

        if PlayerSelectorMode == "whitelist" then
            SetWhitelisted(target, true)
        else
            if IsWhitelisted(target) then
                CustomNotify(
                    target.Name .. " is whitelisted",
                    Color3.fromRGB(255, 180, 70)
                )
                return
            end

            KnifeTargetIds[target.UserId] = true
        end

        PlayerSelectorInput.Text = ""
        RefreshPlayerSelector()
    end

    addButton.MouseButton1Click:Connect(AddFromInput)

    PlayerSelectorInput.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            AddFromInput()
        end
    end)

    PlayerSelectorAction.MouseButton1Click:Connect(function()
        if PlayerSelectorMode == "targets" then
            KillSelectedTargets()
        else
            PlayerSelectorFrame.Visible = false
        end
    end)
end

local function OpenPlayerSelector(mode)
    CreatePlayerSelector()

    if not PlayerSelectorFrame then
        return
    end

    local requestedMode = mode == "whitelist" and "whitelist" or "targets"

    if PlayerSelectorFrame.Visible
    and PlayerSelectorMode == requestedMode then
        PlayerSelectorFrame.Visible = false
        return
    end

    PlayerSelectorMode = requestedMode
    PlayerSelectorTitle.Text =
        PlayerSelectorMode == "whitelist" and "Whitelist" or "Knife Targets"
    PlayerSelectorInput.Text = ""
    PlayerSelectorFrame.Visible = true
    RefreshPlayerSelector()
end

AddConnection(Players.PlayerAdded:Connect(function()
    if PlayerSelectorFrame and PlayerSelectorFrame.Visible then
        task.defer(RefreshPlayerSelector)
    end
end))

AddConnection(Players.PlayerRemoving:Connect(function(target)
    KnifeTargetIds[target.UserId] = nil

    if PlayerSelectorFrame and PlayerSelectorFrame.Visible then
        task.defer(RefreshPlayerSelector)
    end
end))

task.spawn(function()
    while not getgenv().Destroyed and game.PlaceId == 142823291 do
        if PlayerSelectorFrame and PlayerSelectorFrame.Visible then
            RefreshPlayerSelector()
        end

        task.wait(0.75)
    end
end)

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

local ShootSafetySerial = 0
local GuidedShotBusy = false

local function IsMM2PlayerAlive(target)
    if not target or not target.Character then
        return false
    end

    local humanoid = target.Character:FindFirstChildOfClass("Humanoid")
    local root = target.Character:FindFirstChild("HumanoidRootPart")

    return humanoid
        and humanoid.Health > 0
        and root ~= nil
end

local function GetOrEquipGuidedGun()
    local character = Player.Character

    if not character then
        return nil
    end

    local gun = character:FindFirstChild("Gun")
        or character:FindFirstChild("Revolver")

    if gun and gun:IsA("Tool") then
        return gun
    end

    local backpack = Player:FindFirstChildOfClass("Backpack")

    if not backpack then
        return nil
    end

    gun = backpack:FindFirstChild("Gun")
        or backpack:FindFirstChild("Revolver")

    if not gun or not gun:IsA("Tool") then
        return nil
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")

    if not humanoid or humanoid.Health <= 0 then
        return nil
    end

    pcall(function()
        humanoid:EquipTool(gun)
    end)

    task.wait(0.1)

    return character:FindFirstChild("Gun")
        or character:FindFirstChild("Revolver")
        or gun
end

local function FindGuidedMurderer()
    for _, target in ipairs(Players:GetPlayers()) do
        if target ~= Player and IsMM2PlayerAlive(target) then
            local character = target.Character
            local backpack = target:FindFirstChildOfClass("Backpack")

            local hasKnife = character
                and character:FindFirstChild("Knife")

            if not hasKnife and backpack then
                hasKnife = backpack:FindFirstChild("Knife")
            end

            if hasKnife then
                return target
            end
        end
    end

    local roleTarget = GetPlayerByRole("Murderer")

    if roleTarget and IsMM2PlayerAlive(roleTarget) then
        return roleTarget
    end

    local getPlayerData = ReplicatedStorage:FindFirstChild(
        "GetPlayerData",
        true
    )

    if getPlayerData
    and getPlayerData:IsA("RemoteFunction") then
        local ok, data = pcall(function()
            return getPlayerData:InvokeServer()
        end)

        if ok and typeof(data) == "table" then
            for playerName, info in pairs(data) do
                if typeof(info) == "table"
                and info.Role == "Murderer"
                and not info.Dead then
                    local target = Players:FindFirstChild(
                        tostring(playerName)
                    )

                    if target and IsMM2PlayerAlive(target) then
                        return target
                    end
                end
            end
        end
    end

    return nil
end

local function FireGuidedGunShot(gun, targetPosition)
    local fired = false

    local shootRemote = gun:FindFirstChild("Shoot")
        or gun:FindFirstChild("Shoot", true)

    if shootRemote and shootRemote:IsA("RemoteEvent") then
        local ok = pcall(function()
            shootRemote:FireServer(
                CFrame.new(
                    targetPosition + Vector3.new(0, 0.5, 0)
                ),
                CFrame.new(targetPosition)
            )
        end)

        if ok then
            fired = true
        end
    end

    pcall(function()
        local knifeLocal = gun:FindFirstChild("KnifeLocal")
            or gun:FindFirstChild("KnifeLocal", true)

        local createBeam = knifeLocal and (
            knifeLocal:FindFirstChild("CreateBeam")
            or knifeLocal:FindFirstChild("CreateBeam", true)
        )

        local remoteFunction = createBeam and (
            createBeam:FindFirstChild("RemoteFunction")
            or createBeam:FindFirstChildWhichIsA(
                "RemoteFunction",
                true
            )
        )

        if remoteFunction
        and remoteFunction:IsA("RemoteFunction") then
            remoteFunction:InvokeServer(
                1,
                targetPosition,
                "AH2"
            )

            fired = true
        end
    end)

    return fired
end

local function ShootMurderer(showNotify)
    if GuidedShotBusy or getgenv().Destroyed then
        if showNotify then
            CustomNotify(
                "Shoot Murderer is busy",
                Color3.fromRGB(255, 180, 70)
            )
        end

        return false
    end

    GuidedShotBusy = true
    ShootSafetySerial = ShootSafetySerial + 1

    local gun = GetOrEquipGuidedGun()

    if not gun then
        GuidedShotBusy = false

        if showNotify then
            CustomNotify(
                "You need the Gun",
                Color3.fromRGB(255, 100, 100)
            )
        end

        return false
    end

    local murderer = FindGuidedMurderer()

    if not murderer or not murderer.Character then
        GuidedShotBusy = false

        if showNotify then
            CustomNotify(
                "Murderer not found",
                Color3.fromRGB(255, 180, 70)
            )
        end

        return false
    end

    local targetPart = murderer.Character:FindFirstChild("Head")
        or murderer.Character:FindFirstChild("HumanoidRootPart")

    if not targetPart then
        GuidedShotBusy = false

        if showNotify then
            CustomNotify(
                "Murderer target unavailable",
                Color3.fromRGB(255, 100, 100)
            )
        end

        return false
    end

    local fired = FireGuidedGunShot(
        gun,
        targetPart.Position
    )

    if showNotify then
        if fired then
            CustomNotify(
                "Shoot Murderer: " .. murderer.DisplayName,
                Color3.fromRGB(100, 255, 100)
            )
        else
            CustomNotify(
                "Shoot Murderer failed",
                Color3.fromRGB(255, 100, 100)
            )
        end
    end

    task.spawn(function()
        local started =
            os.clock()

        repeat
            RunService.Heartbeat:
                Wait()
        until getgenv().Destroyed
        or not gun
        or not gun.Parent
        or gun.Enabled ~= false
        or os.clock() - started
            >= 2.5

        GuidedShotBusy = false
    end)

    return fired
end

local SilentAimBusy = false

local function FireNormalDirectionalShot(gun, targetPosition)
    local character = Player.Character

    if not character then
        return false
    end

    local originPart = character:FindFirstChild("RightHand")
        or character:FindFirstChild("Right Arm")
        or character:FindFirstChild("UpperTorso")
        or character:FindFirstChild("Torso")
        or character:FindFirstChild("HumanoidRootPart")

    if not originPart then
        return false
    end

    local shootRemote = gun:FindFirstChild("Shoot")
        or gun:FindFirstChild("Shoot", true)

    if not shootRemote or not shootRemote:IsA("RemoteEvent") then
        return false
    end

    local originPosition = originPart.Position
    local direction = targetPosition - originPosition

    if direction.Magnitude <= 0.1 then
        return false
    end

    local originCFrame = CFrame.lookAt(
        originPosition,
        targetPosition
    )

    local targetCFrame = CFrame.lookAt(
        targetPosition,
        targetPosition + direction.Unit
    )

    local ok = pcall(function()
        shootRemote:FireServer(
            originCFrame,
            targetCFrame
        )
    end)

    return ok
end

local function SilentAimShot()
    if SilentAimBusy
    or GuidedShotBusy
    or getgenv().Destroyed then
        return false
    end

    SilentAimBusy = true

    local gun = GetOrEquipGuidedGun()

    if not gun then
        SilentAimBusy = false
        return false
    end

    local murderer = FindGuidedMurderer()

    if not murderer or not murderer.Character then
        SilentAimBusy = false
        return false
    end

    local targetPart = murderer.Character:FindFirstChild("Head")
        or murderer.Character:FindFirstChild("HumanoidRootPart")

    if not targetPart then
        SilentAimBusy = false
        return false
    end

    local fired = FireNormalDirectionalShot(
        gun,
        targetPart.Position
    )

    task.delay(0.18, function()
        SilentAimBusy = false
    end)

    return fired
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
local AutoFarmBagCoins = 0
local AutoFarmBagMax = 40
local AutoFarmBagKnown = false
local AutoFarmCoinSerial = 0
local AutoFarmCompleting = false
local AutoFarmAtCoin = false
local AutoFarmGeneration = 0
local AutoFarmSessionCollected = 0
local AutoFarmPausedFull = false
local AutoFarmResetTriggered = false
local AutoFarmPauseCharacter = nil
local AutoFarmPauseMap = nil

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
    local currentCoins,
        maxCoins =
        ReadCoinBagFromGui()

    if typeof(currentCoins)
        == "number" then
        AutoFarmBagCoins =
            currentCoins

        AutoFarmBagKnown = true
    end

    if typeof(maxCoins)
        == "number"
    and maxCoins > 0 then
        AutoFarmBagMax =
            maxCoins

        AutoFarmBagKnown = true
    end

    return
        AutoFarmBagCoins,
        AutoFarmBagMax,
        AutoFarmBagKnown
end

local function IsFarmBagFull()
    return AutoFarmBagKnown
        and AutoFarmBagMax > 0
        and AutoFarmBagCoins >= AutoFarmBagMax
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

local function EnableLocalControls()
    pcall(function()
        local playerScripts = Player:FindFirstChild("PlayerScripts")
        local playerModule = playerScripts and playerScripts:FindFirstChild("PlayerModule")

        if playerModule then
            local module = require(playerModule)
            local controls = module and module.GetControls and module:GetControls()

            if controls and controls.Enable then
                controls:Enable()
            end
        end
    end)
end

local function SetFarmPosition(position)
    if not AutoFarmRoot
    or not AutoFarmRoot.Parent
    or not AutoFarmRotation then
        return false
    end

    local allow = getgenv().AllowToxTeleport

    if allow then
        allow(0.18)
    end

    AutoFarmRoot.Anchored = false
    AutoFarmRoot.CFrame = CFrame.new(position) * AutoFarmRotation
    AutoFarmRoot.AssemblyLinearVelocity = Vector3.zero
    AutoFarmRoot.AssemblyAngularVelocity = Vector3.zero

    return true
end

local function RestoreAutoFarmPosition()
    if not AutoFarmReturnCFrame then
        return
    end

    local character = Player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if not character or not root then
        return
    end

    local allow = getgenv().AllowToxTeleport

    if allow then
        allow(0.8)
    end

    root.Anchored = false
    character:PivotTo(AutoFarmReturnCFrame)
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
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

    local character = Player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if root then
        root.Anchored = false
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end

    if restore then
        RestoreAutoFarmPosition()
        RunService.Heartbeat:Wait()
    end

    SetFarmCollision(true)

    character = Player.Character
    humanoid = character and character:FindFirstChildOfClass("Humanoid")
    root = character and character:FindFirstChild("HumanoidRootPart")

    if humanoid and humanoid.Health > 0 then
        humanoid.PlatformStand = false
        humanoid.Sit = false
        humanoid.AutoRotate = true

        pcall(function()
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end)

        RunService.Heartbeat:Wait()

        pcall(function()
            humanoid:ChangeState(Enum.HumanoidStateType.Running)
        end)
    end

    if root then
        root.Anchored = false
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end

    EnableLocalControls()

    AutoFarmRoot = nil
    AutoFarmHumanoid = nil
    AutoFarmReturnCFrame = nil
    AutoFarmRotation = nil
    AutoFarmPrepared = false

    if not AutoFarmPausedFull then
        AutoFarmSessionCollected = 0
    end
end

local function ResetAutoFarmFullPause()
    AutoFarmPausedFull = false
    AutoFarmResetTriggered = false
    AutoFarmPauseCharacter = nil
    AutoFarmPauseMap = nil
    AutoFarmSessionCollected = 0
end

local function CompleteAutoFarm()
    if AutoFarmCompleting
    or AutoFarmPausedFull then
        return
    end

    AutoFarmCompleting = true
    AutoFarmPausedFull = true
    AutoFarmPauseCharacter =
        Player.Character
    AutoFarmPauseMap =
        workspace:
            FindFirstChild(
                "Normal"
            )

    StopAutoFarm(true)

    if Settings.MM2AutoFarmResetOnFull
    and not AutoFarmResetTriggered then
        AutoFarmResetTriggered = true

        CustomNotify(
            "Bag full • resetting",
            Color3.fromRGB(
                255,
                180,
                70
            )
        )

        task.delay(
            0.15,
            function()
                if not Settings.MM2AutoFarmV2
                or not Settings.MM2AutoFarmResetOnFull then
                    return
                end

                local character =
                    Player.Character

                local humanoid =
                    character
                    and character:
                        FindFirstChildOfClass(
                            "Humanoid"
                        )

                if humanoid
                and humanoid.Health > 0 then
                    humanoid.Health = 0
                end
            end
        )
    else
        CustomNotify(
            "Bag full • Auto Farm paused",
            Color3.fromRGB(
                100,
                255,
                100
            )
        )
    end

    AutoFarmCompleting = false
end

local function PrepareAutoFarm()
    local character, humanoid, root, alive = IsAliveCharacter()

    if not alive then
        return false
    end

    if AutoFarmPrepared and AutoFarmRoot == root then
        root.Anchored = false
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

    humanoid.PlatformStand = true
    humanoid.Sit = false
    humanoid.AutoRotate = false

    pcall(function()
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    end)

    SetFarmCollision(false)

    root.Anchored = false
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero

    return true
end

local function GetCoinTravelPosition(coin)
    return coin.Position
end

local function GetCoinPickupPosition(coin)
    return coin.Position
end

local function TweenFarmRoot(targetPosition, duration, coin)
    if not AutoFarmRoot
    or not AutoFarmRoot.Parent then
        return false
    end

    local generation = AutoFarmGeneration
    local startPosition = AutoFarmRoot.Position
    local delta = targetPosition - startPosition
    local startTime = os.clock()
    duration = math.max(duration, 0.025)

    while Settings.MM2AutoFarmV2
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

        if not SetFarmPosition(startPosition + delta * alpha) then
            return false
        end

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
    or not AutoFarmRoot.Parent then
        return false
    end

    local generation = AutoFarmGeneration
    local serialBefore = AutoFarmCoinSerial
    local bagBefore = AutoFarmBagCoins
    local pickupPosition = GetCoinPickupPosition(coin)
    local travelPosition = GetCoinTravelPosition(coin)

    AutoFarmAtCoin = true

    for _ = 1, 3 do
        if not Settings.MM2AutoFarmV2
        or generation ~= AutoFarmGeneration
        or IsFarmBagFull()
        or not IsCoinValid(coin) then
            break
        end

        SetFarmPosition(pickupPosition)

        TouchCoin(coin)
        RunService.Heartbeat:Wait()
        TouchCoin(coin)
        task.wait(0.035)

        SetFarmPosition(travelPosition)
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
        SetFarmPosition(travelPosition)
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

    local speedValue = math.clamp(
        tonumber(Settings.MM2AutoFarmSpeed) or 5,
        5,
        250
    )

    local speed = speedValue * 4

    local travelPosition = GetCoinTravelPosition(coin)
    local distance = (AutoFarmRoot.Position - travelPosition).Magnitude

    local arrived = TweenFarmRoot(
        travelPosition,
        distance / speed,
        coin
    )

    if not Settings.MM2AutoFarmV2 then
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
    if not Settings.MM2AutoFarmV2
    or not AutoFarmPrepared
    or not AutoFarmRoot
    or not AutoFarmRoot.Parent then
        return
    end

    AutoFarmRoot.Anchored = false
    AutoFarmRoot.AssemblyLinearVelocity = Vector3.zero
    AutoFarmRoot.AssemblyAngularVelocity = Vector3.zero

    if AutoFarmHumanoid
    and AutoFarmHumanoid.Parent
    and AutoFarmHumanoid.Health > 0 then
        AutoFarmHumanoid.PlatformStand = true
        AutoFarmHumanoid.Sit = false
        AutoFarmHumanoid.AutoRotate = false
    end
end))

task.spawn(function()
    while not getgenv().Destroyed and game.PlaceId == 142823291 do
        if Settings.MM2AutoFarmV2 then
            RefreshFarmBagState()

            local _,
                humanoid,
                root,
                alive =
                IsAliveCharacter()

            local fallbackFull =
                not AutoFarmBagKnown
                and AutoFarmSessionCollected
                    >= AutoFarmBagMax

            if AutoFarmPausedFull then
                local currentMap =
                    workspace:
                        FindFirstChild(
                            "Normal"
                        )

                local bagReset =
                    AutoFarmBagKnown
                    and not IsFarmBagFull()

                local roundChanged =
                    AutoFarmPauseMap
                    and currentMap
                    and currentMap
                        ~= AutoFarmPauseMap

                if bagReset
                or roundChanged then
                    ResetAutoFarmFullPause()
                    AutoFarmBagKnown = false
                    AutoFarmBagCoins = 0
                    RefreshFarmBagState()
                else
                    if AutoFarmPrepared then
                        StopAutoFarm(false)
                    end

                    task.wait(0.2)
                end
            elseif not alive then
                if AutoFarmPrepared then
                    StopAutoFarm(false)
                end

                task.wait(0.15)
            elseif IsFarmBagFull()
            or fallbackFull then
                CompleteAutoFarm()
                task.wait(0.2)
            elseif not ActionBusy then
                local coin = GetBestCoin(root.Position, false)

                if coin then
                    AutoFarmCoin(coin)
                else
                    if AutoFarmPrepared then
                        StopAutoFarm(false)
                    end

                    task.wait(0.12)
                end
            else
                task.wait(0.08)
            end
        else
            if AutoFarmPrepared then
                StopAutoFarm(true)
            else
                local character = Player.Character
                local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                local root = character and character:FindFirstChild("HumanoidRootPart")

                if humanoid and humanoid.Health > 0 then
                    humanoid.PlatformStand = false
                    humanoid.Sit = false
                    humanoid.AutoRotate = true
                end

                if root then
                    root.Anchored = false
                end
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

local function CreateMM2Section(
    text
)
    local label =
        Instance.new(
            "TextLabel"
        )

    label.Size =
        UDim2.new(
            1,
            -5,
            0,
            26
        )

    label.BackgroundColor3 =
        Color3.fromRGB(
            13,
            13,
            21
        )

    label.BorderSizePixel = 0
    label.Text =
        "  "
        .. tostring(
            text
        )

    label.TextColor3 =
        Color3.fromRGB(
            255,
            255,
            255
        )

    label.Font =
        Enum.Font.GothamBold

    label.TextSize = 11
    label.TextXAlignment =
        Enum.TextXAlignment.Left

    label.Parent =
        GamePage

    local corner =
        Instance.new("UICorner")

    corner.CornerRadius =
        UDim.new(
            0,
            5
        )

    corner.Parent =
        label

    return label
end

local AutoFarmHighSpeedWarningShown = false

local function WarnAutoFarmSpeed(
    speed
)
    speed =
        tonumber(speed)
        or 5

    if speed > 10
    and not AutoFarmHighSpeedWarningShown then
        AutoFarmHighSpeedWarningShown =
            true

        CustomNotify(
            "WARNING: Auto Farm speed above 10 may cause a kick or ban.",
            Color3.fromRGB(
                255,
                170,
                60
            ),
            7
        )
    elseif speed <= 10 then
        AutoFarmHighSpeedWarningShown =
            false
    end
end

CreateMM2Section(
    "FARM"
)

CreateToggleWithValue("Auto Farm", GamePage, Settings.MM2AutoFarmV2, Settings.MM2AutoFarmSpeed, function(v)
    if v then
        Settings.MM2AutoFarmV2 = true
        ResetAutoFarmFullPause()
        AutoFarmBagKnown = false
        AutoFarmBagCoins = 0
        RefreshFarmBagState()

        WarnAutoFarmSpeed(
            Settings.MM2AutoFarmSpeed
        )
    else
        Settings.MM2AutoFarmV2 = false
        ResetAutoFarmFullPause()
        StopAutoFarm(true)

        local character = Player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local root = character and character:FindFirstChild("HumanoidRootPart")

        if humanoid and humanoid.Health > 0 then
            humanoid.PlatformStand = false
            humanoid.Sit = false
            humanoid.AutoRotate = true
        end

        if root then
            root.Anchored = false
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end

        EnableLocalControls()
    end

    AutoSaveConfiguration()
end, function(value)
    Settings.MM2AutoFarmSpeed =
        math.clamp(
            tonumber(value)
            or 5,
            5,
            250
        )

    WarnAutoFarmSpeed(
        Settings.MM2AutoFarmSpeed
    )

    AutoSaveConfiguration()
end, "MM2AutoFarmV2")

CreateToggle(
    "Reset On Full",
    GamePage,
    Settings.MM2AutoFarmResetOnFull,
    function(v)
        Settings.MM2AutoFarmResetOnFull =
            v == true

        if not Settings.MM2AutoFarmResetOnFull then
            AutoFarmResetTriggered = false
        end

        AutoSaveConfiguration()
    end,
    "MM2AutoFarmResetOnFull"
)

CreateMM2Section(
    "PLAYER"
)

CreateToggle("Role ESP", GamePage, Settings.MM2RoleESP, function(v)
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

CreateMM2Section(
    "COMBAT"
)

local MM2AutoRuntime = {
    KillAll = Settings.MM2KillAllAutoV2 == true,
    Shoot = Settings.MM2ShootMurderAutoV2 == true,
    GrabGun = Settings.MM2GrabGunAutoV2 == true
}

CreateKeybindButton("Silent Aim", GamePage, Settings.MM2SilentAimKey, function(key)
    Settings.MM2SilentAimKey = key
end)

CreateKeybindToggle("Kill All", GamePage, Settings.MM2KillAllKey, MM2AutoRuntime.KillAll, function(key)
    Settings.MM2KillAllKey = key
end, function(enabled)
    MM2AutoRuntime.KillAll = enabled == true
    Settings.MM2KillAllAutoV2 = MM2AutoRuntime.KillAll
end, "MM2KillAllAutoV2")

CreateKeybindToggle("Shoot Murderer", GamePage, Settings.MM2ShootMurderKey, MM2AutoRuntime.Shoot, function(key)
    Settings.MM2ShootMurderKey = key
end, function(enabled)
    MM2AutoRuntime.Shoot = enabled == true
    Settings.MM2ShootMurderAutoV2 = MM2AutoRuntime.Shoot

    if not MM2AutoRuntime.Shoot then
        ShootSafetySerial = ShootSafetySerial + 1
    end
end, "MM2ShootMurderAutoV2")

CreateKeybindToggle("Grab Gun", GamePage, Settings.MM2GrabGunKey, MM2AutoRuntime.GrabGun, function(key)
    Settings.MM2GrabGunKey = key
end, function(enabled)
    MM2AutoRuntime.GrabGun = enabled == true
    Settings.MM2GrabGunAutoV2 = MM2AutoRuntime.GrabGun
end, "MM2GrabGunAutoV2")

CreateMM2Section(
    "TARGETING"
)

CreateDropdown("Fling Target", {"Murderer", "Sheriff"}, GamePage, Settings.MM2FlingTarget, function(value)
    Settings.MM2FlingTarget = value
    AutoSaveConfiguration()
end)

CreateButton("Fling", GamePage, FlingSelectedRole)

CreateButton("Knife Targets", GamePage, function()
    OpenPlayerSelector("targets")
end)

CreateButton("Whitelist", GamePage, function()
    OpenPlayerSelector("whitelist")
end)

local AutoKnifeLastAttempt = 0
local AutoShootLastAttempt = 0
local AutoGrabAttemptedDrops = setmetatable({}, {__mode = "k"})

task.spawn(function()
    while not getgenv().Destroyed and game.PlaceId == 142823291 do
        local knife = FindNamedTool({"knife"})
        local gun = FindNamedTool({"gun", "revolver"})
        local character = Player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local alive = humanoid and humanoid.Health > 0
        local localRole = alive and GetRole(Player) or nil

        if MM2AutoRuntime.KillAll
        and not Settings.MM2AutoFarmV2
        and knife
        and alive
        and not ActionBusy
        and knife.Enabled ~= false
        and os.clock() - AutoKnifeLastAttempt
            >= 0.05 then
            AutoKnifeLastAttempt =
                os.clock()

            task.spawn(
                KillAll
            )
        end

        if MM2AutoRuntime.Shoot
        and Settings.MM2ShootMurderAutoV2
        and not Settings.MM2AutoFarmV2
        and gun
        and alive
        and not ActionBusy
        and not GuidedShotBusy
        and gun.Enabled ~= false then
            local murderer =
                GetPlayerByRole(
                    "Murderer"
                )

            local murderHumanoid =
                murderer
                and murderer.Character
                and murderer.Character:
                    FindFirstChildOfClass(
                        "Humanoid"
                    )

            if murderer
            and murderHumanoid
            and murderHumanoid.Health > 0
            and os.clock() - AutoShootLastAttempt
                >= 0.04 then
                AutoShootLastAttempt =
                    os.clock()

                task.spawn(function()
                    ShootMurderer(
                        false
                    )
                end)
            end
        end

        if MM2AutoRuntime.GrabGun
        and Settings.MM2GrabGunAutoV2
        and not Settings.MM2AutoFarmV2
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


local LastManualShootInput = 0

AddConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed
    or UserInputService:GetFocusedTextBox()
    or input.UserInputType ~= Enum.UserInputType.Keyboard
    or getgenv().Destroyed then
        return
    end

    if Settings.MM2SilentAimKey
    and input.KeyCode == Settings.MM2SilentAimKey then
        task.defer(function()
            if not getgenv().Destroyed then
                SilentAimShot()
            end
        end)

        return
    end

    if Settings.MM2KillAllKey and input.KeyCode == Settings.MM2KillAllKey then
        KillAll()
        return
    end

    if Settings.MM2ShootMurderKey and input.KeyCode == Settings.MM2ShootMurderKey then
        if os.clock() - LastManualShootInput < 0.35 then
            return
        end

        LastManualShootInput = os.clock()

        MM2AutoRuntime.Shoot = false
        Settings.MM2ShootMurderAuto = false
        Settings.MM2ShootMurderAutoV2 = false
        ShootSafetySerial = ShootSafetySerial + 1

        if SyncToggleVisuals then
            SyncToggleVisuals("MM2ShootMurderAutoV2", false)
        end

        AutoSaveConfiguration()

        task.defer(function()
            if not getgenv().Destroyed then
                ShootMurderer(true)
            end
        end)

        return
    end

    if Settings.MM2GrabGunKey and input.KeyCode == Settings.MM2GrabGunKey then
        GrabGun()
    end
end))


getgenv().ToxMM2Cleanup = function()
    getgenv().ToxMM2ModuleLoadedJobId = nil
    Settings.MM2AutoFarm = false
    Settings.MM2AutoFarmV2 = false
    Settings.MM2RoleESP = false
    Settings.MM2KillAllAuto = false
    Settings.MM2KillAllAutoV2 = false
    Settings.MM2ShootMurderAuto = false
    Settings.MM2ShootMurderAutoV2 = false
    Settings.MM2GrabGunAuto = false
    Settings.MM2GrabGunAutoV2 = false

    MM2AutoRuntime.KillAll = false
    MM2AutoRuntime.Shoot = false
    MM2AutoRuntime.GrabGun = false
    ShootSafetySerial = ShootSafetySerial + 1
    GuidedShotBusy = false
    SilentAimBusy = false
    ActionBusy = false
    AutoShootLastAttempt = 0
    table.clear(KnifeTargetIds)

    if Camera then
        pcall(function()
            Camera.CameraType = Enum.CameraType.Custom

            local character = Player.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")

            if humanoid then
                Camera.CameraSubject = humanoid
            end
        end)
    end

    local cleanupCharacter = Player.Character
    local cleanupHumanoid = cleanupCharacter and cleanupCharacter:FindFirstChildOfClass("Humanoid")
    local cleanupRoot = cleanupCharacter and cleanupCharacter:FindFirstChild("HumanoidRootPart")

    if cleanupHumanoid then
        cleanupHumanoid.PlatformStand = false
        cleanupHumanoid.Sit = false
        cleanupHumanoid.AutoRotate = true
    end

    if cleanupRoot then
        cleanupRoot.Anchored = false
        cleanupRoot.AssemblyLinearVelocity = Vector3.zero
        cleanupRoot.AssemblyAngularVelocity = Vector3.zero
    end

    table.clear(KnifeTargetIds)

    if AutoFarmPrepared then
        StopAutoFarm(true)
    end

    if PlayerSelectorFrame then
        PlayerSelectorFrame.Visible = false
    end

    if getgenv().ToxLinkedSubGuis then
        getgenv().ToxLinkedSubGuis.MM2PlayerSelector = nil
    end

    if getgenv().SyncToggleVisuals then
        getgenv().SyncToggleVisuals("MM2AutoFarmV2", false)
        getgenv().SyncToggleVisuals("MM2RoleESP", false)
        getgenv().SyncToggleVisuals("MM2KillAllAutoV2", false)
        getgenv().SyncToggleVisuals("MM2ShootMurderAutoV2", false)
        getgenv().SyncToggleVisuals("MM2GrabGunAutoV2", false)
    end
end

if Settings.MM2RoleESP then
    ApplyRoleESP(true)
end
