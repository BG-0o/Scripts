if game.PlaceId ~= 142823291 then
    return
end

local MM2ModuleVersion =
    "2026-09-11-changelog-reload-sections-1"

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
local AddConnection = getgenv().AddConnection or function(conn) return conn end
local CustomNotify = getgenv().CustomNotify or function() end
local AutoSaveConfiguration = getgenv().AutoSaveConfiguration or function() end
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

local function ClearToxTable(target)
    if typeof(target) ~= "table" then
        return
    end

    for key in pairs(target) do
        target[key] = nil
    end
end

if getgenv().ToxMM2ModuleLoadedJobId
    == game.JobId
and getgenv().ToxMM2ModuleVersion
    == MM2ModuleVersion
and getgenv().ToxMM2ModulePage
    == GamePage
and not getgenv().Destroyed then
    return
end

if getgenv().ToxMM2Cleanup then
    pcall(
        getgenv().ToxMM2Cleanup
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

Settings.MM2CollapsedSections =
    typeof(Settings.MM2CollapsedSections) == "table"
    and Settings.MM2CollapsedSections
    or {}

Settings.MM2SilentAimKey = Settings.MM2SilentAimKey or Enum.KeyCode.E
Settings.MM2SilentAimAutoV2 = Settings.MM2SilentAimAutoV2 == true or Settings.MM2SilentAimAuto == true
Settings.MM2SilentAimAuto = false
Settings.MM2KillAllKey = Settings.MM2KillAllKey or Enum.KeyCode.K
Settings.MM2KillAllAutoV2 = Settings.MM2KillAllAutoV2 == true or Settings.MM2KillAllAuto == true
Settings.MM2KillAllAuto = false
Settings.MM2ShootMurderKey = Settings.MM2ShootMurderKey or Enum.KeyCode.C
Settings.MM2ShootMurderAutoV2 = Settings.MM2ShootMurderAutoV2 == true or Settings.MM2ShootMurderAuto == true
Settings.MM2ShootMurderAuto = false
Settings.MM2GrabGunKey = Settings.MM2GrabGunKey or Enum.KeyCode.G
Settings.MM2GrabGunAutoV2 = Settings.MM2GrabGunAutoV2 == true or Settings.MM2GrabGunAuto == true
Settings.MM2GrabGunAuto = false
Settings.MM2GunESP = Settings.MM2GunESP == true
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
Settings.MM2TargetHistory = typeof(Settings.MM2TargetHistory) == "table" and Settings.MM2TargetHistory or {}
Settings.MM2TargetLock = false
Settings.MM2AutoClearTarget = true
Settings.MM2RoundTimer = Settings.MM2RoundTimer == true

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

local function IsSheriffAlive()
    for _, target in ipairs(Players:GetPlayers()) do
        if GetRole(target) == "Sheriff" then
            local humanoid = target.Character and target.Character:FindFirstChildOfClass("Humanoid")

            if humanoid and humanoid.Health > 0 then
                return true
            end
        end
    end

    return false
end

local function IsTargetAlive(target)
    local humanoid = target
        and target.Character
        and target.Character:FindFirstChildOfClass("Humanoid")

    return humanoid and humanoid.Health > 0
end

local function GetTargetStatusText(target)
    if not target
    or not target.Parent then
        return "Left"
    end

    if IsTargetAlive(target) then
        return "Alive"
    end

    return "Dead"
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

local function FindTargetByUserId(userId)
    userId = tonumber(userId)

    if not userId then
        return nil
    end

    for _, target in ipairs(Players:GetPlayers()) do
        if target.UserId == userId then
            return target
        end
    end

    return nil
end

local function CleanKnifeTargets()
    Settings.MM2AutoClearTarget = true
    Settings.MM2TargetLock = false

    for userId in pairs(KnifeTargetIds) do
        local target = FindTargetByUserId(userId)

        if not target
        or not IsTargetAlive(target) then
            KnifeTargetIds[userId] = nil
        end
    end
end

local function AddTargetToHistory(target)
    if not target
    or target == Player then
        return
    end

    Settings.MM2TargetHistory = typeof(Settings.MM2TargetHistory) == "table" and Settings.MM2TargetHistory or {}

    for index = #Settings.MM2TargetHistory, 1, -1 do
        local item = Settings.MM2TargetHistory[index]

        if typeof(item) == "table"
        and tonumber(item.UserId) == target.UserId then
            table.remove(Settings.MM2TargetHistory, index)
        end
    end

    table.insert(
        Settings.MM2TargetHistory,
        1,
        {
            UserId = target.UserId,
            Name = target.Name,
            DisplayName = target.DisplayName,
            Time = os.time()
        }
    )

    while #Settings.MM2TargetHistory > 10 do
        table.remove(Settings.MM2TargetHistory)
    end

    AutoSaveConfiguration()
end

local function CleanTargetHistory()
    Settings.MM2TargetHistory = typeof(Settings.MM2TargetHistory) == "table" and Settings.MM2TargetHistory or {}

    for index = #Settings.MM2TargetHistory, 1, -1 do
        local item = Settings.MM2TargetHistory[index]

        if typeof(item) ~= "table"
        or not tonumber(item.UserId) then
            table.remove(Settings.MM2TargetHistory, index)
        end
    end

    while #Settings.MM2TargetHistory > 10 do
        table.remove(Settings.MM2TargetHistory)
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

local function TouchKnifeTarget(
    knife,
    target,
    activateKnife
)
    if not knife
    or not target
    or not target.Character then
        return false
    end

    local targetHumanoid =
        target.Character:
            FindFirstChildOfClass(
                "Humanoid"
            )

    local targetRoot =
        target.Character:
            FindFirstChild(
                "HumanoidRootPart"
            )

    local targetHead =
        target.Character:
            FindFirstChild(
                "Head"
            )

    local handle =
        knife:
            FindFirstChild(
                "Handle"
            )

    if not targetHumanoid
    or targetHumanoid.Health <= 0
    or not handle then
        return false
    end

    local touched = false

    if activateKnife ~= false then
        pcall(function()
            knife:
                Activate()
        end)
    end

    if firetouchinterest then
        for _, part in ipairs({
            targetRoot,
            targetHead
        }) do
            if part then
                pcall(function()
                    firetouchinterest(
                        handle,
                        part,
                        0
                    )

                    firetouchinterest(
                        part,
                        handle,
                        0
                    )

                    firetouchinterest(
                        handle,
                        part,
                        1
                    )

                    firetouchinterest(
                        part,
                        handle,
                        1
                    )
                end)

                touched = true
            end
        end
    end

    if not touched
    and targetRoot then
        local _,
            humanoid,
            root =
            GetCharacterState()

        if humanoid
        and humanoid.Health > 0
        and root then
            local oldCFrame =
                root.CFrame

            local allow =
                getgenv().AllowToxTeleport

            if allow then
                allow(
                    0.4,
                    "MM2 Target Attack"
                )
            end

            root.CFrame =
                targetRoot.CFrame
                * CFrame.new(
                    0,
                    0,
                    1.5
                )

            if activateKnife ~= false then
                knife:
                    Activate()
            end

            task.wait(
                0.04
            )

            root.CFrame =
                oldCFrame

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
                target,
                true
            ) then
                attacked = true
            end

            task.wait(
                0.035
            )
        end
    end

    return attacked
        and not KnifeTargetAlive(
            target
        )
end

local function OneSlashTargets(
    knife,
    targets
)
    if not knife
    or not knife.Parent
    or typeof(targets)
        ~= "table" then
        return false
    end

    local handle =
        knife:
            FindFirstChild(
                "Handle"
            )

    if not handle
    or not firetouchinterest then
        return false
    end

    pcall(function()
        knife:
            Activate()
    end)

    local touchedAny = false

    for pass = 1, 4 do
        for _, target in ipairs(
            targets
        ) do
            if target
            and target.Parent == Players
            and not IsWhitelisted(
                target
            )
            and KnifeTargetAlive(
                target
            ) then
                if TouchKnifeTarget(
                    knife,
                    target,
                    false
                ) then
                    touchedAny = true
                end
            end
        end

        if pass < 4 then
            task.wait(
                0.012
            )
        end
    end

    return touchedAny
end

local function KillSingleTarget(
    target
)
    if ActionBusy
    or not target
    or target == Player
    or IsWhitelisted(
        target
    ) then
        return
    end

    local knife =
        FindNamedTool({
            "knife"
        })

    if not knife then
        CustomNotify(
            "Kill requires the Knife",
            Color3.fromRGB(
                255,
                100,
                100
            )
        )

        return
    end

    if not EquipTool(
        knife
    ) then
        CustomNotify(
            "Could not equip Knife",
            Color3.fromRGB(
                255,
                100,
                100
            )
        )

        return
    end

    ActionBusy = true

    task.spawn(function()
        OneSlashTargets(
            knife,
            {
                target
            }
        )

        task.wait(
            0.12
        )

        if KnifeTargetAlive(
            target
        ) then
            AttackKnifeTargetUntilDone(
                knife,
                target,
                2.5
            )
        end

        ActionBusy = false
    end)
end

local function KillAll()
    if ActionBusy then
        return
    end

    local knife =
        FindNamedTool({
            "knife"
        })

    if not knife then
        CustomNotify(
            "Kill All requires the Knife",
            Color3.fromRGB(
                255,
                100,
                100
            )
        )

        return
    end

    if not EquipTool(
        knife
    ) then
        CustomNotify(
            "Could not equip Knife",
            Color3.fromRGB(
                255,
                100,
                100
            )
        )

        return
    end

    local targets = {}

    for _, target in ipairs(
        Players:
            GetPlayers()
    ) do
        if target ~= Player
        and not IsWhitelisted(
            target
        )
        and KnifeTargetAlive(
            target
        ) then
            table.insert(
                targets,
                target
            )
        end
    end

    if #targets == 0 then
        return
    end

    ActionBusy = true

    task.spawn(function()
        local oneSlash =
            OneSlashTargets(
                knife,
                targets
            )

        if not oneSlash then
            for _, target in ipairs(
                targets
            ) do
                if getgenv().Destroyed then
                    break
                end

                AttackKnifeTargetUntilDone(
                    knife,
                    target,
                    2.5
                )
            end
        else
            task.wait(
                0.2
            )

            for _, target in ipairs(
                targets
            ) do
                if getgenv().Destroyed then
                    break
                end

                if KnifeTargetAlive(
                    target
                )
                and knife.Enabled ~= false then
                    TouchKnifeTarget(
                        knife,
                        target,
                        false
                    )
                end
            end
        end

        ActionBusy = false
    end)
end

local function KillSelectedTargets()
    if ActionBusy then
        return
    end

    local knife =
        FindNamedTool({
            "knife"
        })

    if not knife then
        CustomNotify(
            "Kill Selected requires the Knife",
            Color3.fromRGB(
                255,
                100,
                100
            )
        )

        return
    end

    local targets =
        GetSelectedKnifeTargets()

    if #targets == 0 then
        CustomNotify(
            "No selected players available",
            Color3.fromRGB(
                255,
                180,
                70
            )
        )

        return
    end

    if not EquipTool(
        knife
    ) then
        CustomNotify(
            "Could not equip Knife",
            Color3.fromRGB(
                255,
                100,
                100
            )
        )

        return
    end

    ActionBusy = true

    task.spawn(function()
        local oneSlash =
            OneSlashTargets(
                knife,
                targets
            )

        if not oneSlash then
            for _, target in ipairs(
                targets
            ) do
                if getgenv().Destroyed then
                    break
                end

                AttackKnifeTargetUntilDone(
                    knife,
                    target,
                    2.5
                )
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

    CleanKnifeTargets()

    for _, child in ipairs(PlayerSelectorScroll:GetChildren()) do
        if child:IsA("Frame")
        or child.Name == "ToxTargetHistoryHeader" then
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

    CleanTargetHistory()

    local layoutOrder = 1

    if #Settings.MM2TargetHistory > 0 then
        local header = Instance.new("TextLabel")
        header.Name = "ToxTargetHistoryHeader"
        header.Size = UDim2.new(1, -4, 0, 22)
        header.BackgroundTransparency = 1
        header.Text = "Target History"
        header.TextColor3 = Color3.fromRGB(180, 180, 205)
        header.Font = Enum.Font.GothamBold
        header.TextSize = 10
        header.TextXAlignment = Enum.TextXAlignment.Left
        header.LayoutOrder = layoutOrder
        header.Parent = PlayerSelectorScroll

        local headerPadding = Instance.new("UIPadding")
        headerPadding.PaddingLeft = UDim.new(0, 8)
        headerPadding.Parent = header

        layoutOrder = layoutOrder + 1

        for index, item in ipairs(Settings.MM2TargetHistory) do
            if index > 4 then
                break
            end

            local userId = tonumber(item.UserId)
            local target = FindTargetByUserId(userId)
            local status = target and GetTargetStatusText(target) or "Left"
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, -4, 0, 36)
            row.BackgroundColor3 = Color3.fromRGB(15, 15, 24)
            row.BorderSizePixel = 0
            row.LayoutOrder = layoutOrder
            row.Parent = PlayerSelectorScroll

            layoutOrder = layoutOrder + 1

            local rowCorner = Instance.new("UICorner")
            rowCorner.CornerRadius = UDim.new(0, 4)
            rowCorner.Parent = row

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -132, 1, 0)
            label.Position = UDim2.new(0, 8, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = tostring(item.DisplayName or item.Name or userId) .. " • " .. status
            label.TextColor3 = status == "Alive" and Color3.fromRGB(120, 230, 145) or Color3.fromRGB(230, 145, 120)
            label.Font = Enum.Font.GothamMedium
            label.TextSize = 10
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.TextTruncate = Enum.TextTruncate.AtEnd
            label.Parent = row

            local selectButton = Instance.new("TextButton")
            selectButton.Size = UDim2.new(0, 58, 0, 24)
            selectButton.Position = UDim2.new(1, -124, 0.5, -12)
            selectButton.BorderSizePixel = 0
            selectButton.Text = target and "Select" or "Left"
            selectButton.BackgroundColor3 = target and Color3.fromRGB(55, 55, 75) or Color3.fromRGB(45, 45, 55)
            selectButton.TextColor3 = target and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(130, 130, 145)
            selectButton.Font = Enum.Font.GothamBold
            selectButton.TextSize = 9
            selectButton.Parent = row

            local selectCorner = Instance.new("UICorner")
            selectCorner.CornerRadius = UDim.new(0, 4)
            selectCorner.Parent = selectButton

            local killButton = Instance.new("TextButton")
            killButton.Size = UDim2.new(0, 54, 0, 24)
            killButton.Position = UDim2.new(1, -60, 0.5, -12)
            killButton.BorderSizePixel = 0
            killButton.Text = "Kill"
            killButton.BackgroundColor3 = target and Color3.fromRGB(155, 40, 48) or Color3.fromRGB(45, 45, 55)
            killButton.TextColor3 = target and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(130, 130, 145)
            killButton.Font = Enum.Font.GothamBold
            killButton.TextSize = 9
            killButton.Parent = row

            local killCorner = Instance.new("UICorner")
            killCorner.CornerRadius = UDim.new(0, 4)
            killCorner.Parent = killButton

            selectButton.MouseButton1Click:Connect(function()
                if not target or IsWhitelisted(target) then
                    return
                end

                KnifeTargetIds[target.UserId] = true
                AddTargetToHistory(target)
                RefreshPlayerSelector()
            end)

            killButton.MouseButton1Click:Connect(function()
                if not target or IsWhitelisted(target) then
                    return
                end

                AddTargetToHistory(target)
                KillSingleTarget(target)
            end)
        end
    end

    for index, target in ipairs(playerList) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -4, 0, 42)
        row.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
        row.BorderSizePixel = 0
        row.LayoutOrder = layoutOrder + index
        row.Parent = PlayerSelectorScroll

        local rowCorner = Instance.new("UICorner")
        rowCorner.CornerRadius = UDim.new(0, 4)
        rowCorner.Parent = row

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, -178, 0, 18)
        nameLabel.Position = UDim2.new(0, 8, 0, 4)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = target.DisplayName
        nameLabel.TextColor3 = Color3.fromRGB(245, 245, 245)
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 11
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        nameLabel.Parent = row

        local role = GetRole(target) or "Unknown"
        local status = GetTargetStatusText(target)

        local userLabel = Instance.new("TextLabel")
        userLabel.Size = UDim2.new(1, -178, 0, 15)
        userLabel.Position = UDim2.new(0, 8, 0, 22)
        userLabel.BackgroundTransparency = 1
        userLabel.Text = "@" .. target.Name .. " • " .. status .. " • " .. role
        userLabel.TextColor3 =
            status == "Alive"
            and Color3.fromRGB(120, 230, 145)
            or Color3.fromRGB(230, 145, 120)
        userLabel.Font = Enum.Font.Gotham
        userLabel.TextSize = 9
        userLabel.TextXAlignment = Enum.TextXAlignment.Left
        userLabel.TextTruncate = Enum.TextTruncate.AtEnd
        userLabel.Parent = row

        local whitelistButton = Instance.new("TextButton")
        whitelistButton.Size = UDim2.new(0, 58, 0, 26)
        whitelistButton.Position = UDim2.new(1, -174, 0.5, -13)
        whitelistButton.BorderSizePixel = 0
        whitelistButton.Font = Enum.Font.GothamBold
        whitelistButton.TextSize = 9
        whitelistButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        whitelistButton.Parent = row

        local whitelistCorner = Instance.new("UICorner")
        whitelistCorner.CornerRadius = UDim.new(0, 4)
        whitelistCorner.Parent = whitelistButton

        local selectButton = Instance.new("TextButton")
        selectButton.Size = UDim2.new(0, 54, 0, 26)
        selectButton.Position = UDim2.new(1, -112, 0.5, -13)
        selectButton.BorderSizePixel = 0
        selectButton.Font = Enum.Font.GothamBold
        selectButton.TextSize = 9
        selectButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        selectButton.Parent = row

        local selectCorner = Instance.new("UICorner")
        selectCorner.CornerRadius = UDim.new(0, 4)
        selectCorner.Parent = selectButton

        local killButton = Instance.new("TextButton")
        killButton.Size = UDim2.new(0, 48, 0, 26)
        killButton.Position = UDim2.new(1, -54, 0.5, -13)
        killButton.BorderSizePixel = 0
        killButton.Font = Enum.Font.GothamBold
        killButton.TextSize = 9
        killButton.Text = "Kill"
        killButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        killButton.Parent = row

        local killCorner = Instance.new("UICorner")
        killCorner.CornerRadius = UDim.new(0, 4)
        killCorner.Parent = killButton

        local whitelisted = IsWhitelisted(target)
        local selected = KnifeTargetIds[target.UserId] == true

        if whitelisted then
            whitelistButton.Text = "SAFE"
            whitelistButton.BackgroundColor3 = MAIN_COLOR
            selectButton.Text = "Select"
            selectButton.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
            selectButton.TextColor3 = Color3.fromRGB(130, 130, 145)
            killButton.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
            killButton.TextColor3 = Color3.fromRGB(130, 130, 145)
        else
            whitelistButton.Text = "Whitelist"
            whitelistButton.BackgroundColor3 = Color3.fromRGB(55, 55, 75)

            if selected then
                selectButton.Text = "Selected"
                selectButton.BackgroundColor3 = MAIN_COLOR
            else
                selectButton.Text = "Select"
                selectButton.BackgroundColor3 = Color3.fromRGB(55, 55, 75)
            end

            killButton.BackgroundColor3 = Color3.fromRGB(155, 40, 48)
        end

        whitelistButton.MouseButton1Click:Connect(function()
            SetWhitelisted(
                target,
                not IsWhitelisted(target)
            )

            RefreshPlayerSelector()
        end)

        selectButton.MouseButton1Click:Connect(function()
            if IsWhitelisted(target) then
                CustomNotify(
                    target.Name .. " is whitelisted",
                    Color3.fromRGB(255, 180, 70)
                )
                return
            end

            local newValue = not KnifeTargetIds[target.UserId]

            KnifeTargetIds[target.UserId] =
                newValue
                or nil

            if newValue then
                AddTargetToHistory(target)
            end

            RefreshPlayerSelector()
        end)

        killButton.MouseButton1Click:Connect(function()
            if IsWhitelisted(target) then
                CustomNotify(
                    target.Name .. " is whitelisted",
                    Color3.fromRGB(255, 180, 70)
                )
                return
            end

            AddTargetToHistory(target)
            KillSingleTarget(target)
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
    PlayerSelectorTitle.Text = "Target"
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

        if IsWhitelisted(target) then
            CustomNotify(
                target.Name .. " is whitelisted",
                Color3.fromRGB(255, 180, 70)
            )
            return
        end

        KnifeTargetIds[target.UserId] = true
        AddTargetToHistory(target)

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
        KillSelectedTargets()
    end)
end

local function OpenPlayerSelector(mode)
    CreatePlayerSelector()

    if not PlayerSelectorFrame then
        return
    end

    local requestedMode = "targets"

    if PlayerSelectorFrame.Visible
    and PlayerSelectorMode == requestedMode then
        PlayerSelectorFrame.Visible = false
        return
    end

    PlayerSelectorMode = requestedMode
    PlayerSelectorTitle.Text = "Target"
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

local LastTargetAutoClear = 0

AddConnection(RunService.Heartbeat:Connect(function()
    if os.clock() - LastTargetAutoClear < 1 then
        return
    end

    LastTargetAutoClear = os.clock()

    local before = 0

    Settings.MM2AutoClearTarget = true
    Settings.MM2TargetLock = false

    for _ in pairs(KnifeTargetIds) do
        before = before + 1
    end

    CleanKnifeTargets()

    local after = 0

    for _ in pairs(KnifeTargetIds) do
        after = after + 1
    end

    if before ~= after
    and PlayerSelectorFrame
    and PlayerSelectorFrame.Visible then
        RefreshPlayerSelector()
    end
end))


local RoundTimerFrame = nil
local RoundTimerLabel = nil
local LastRoundTimerUpdate = 0

local function FormatRoundSeconds(value)
    local number = tonumber(value)

    if not number then
        return nil
    end

    number = math.max(0, math.floor(number + 0.5))

    if number > 9999 then
        return nil
    end

    local minutes = math.floor(number / 60)
    local seconds = number % 60

    return string.format("%d:%02d", minutes, seconds)
end

local function ReadTimerFromText(text, name)
    text = tostring(text or "")
    name = string.lower(tostring(name or ""))

    local direct = string.match(text, "^%s*(%d+:%d%d)%s*$")
    local inside = string.match(text, "(%d+:%d%d)")

    if direct then
        return direct
    end

    if inside then
        return inside
    end

    if string.find(name, "timer", 1, true)
    or string.find(name, "time", 1, true)
    or string.find(name, "round", 1, true)
    or string.find(string.lower(text), "time", 1, true)
    or string.find(string.lower(text), "round", 1, true)
    or string.find(string.lower(text), "intermission", 1, true) then
        local number = string.match(text, "(%d+)")
        return FormatRoundSeconds(number)
    end

    return nil
end

local function ScanRoundTimerContainer(container)
    if not container then
        return nil
    end

    local ownGui = getgenv().Gui

    for _, object in ipairs(container:GetDescendants()) do
        if not ownGui
        or not object:IsDescendantOf(ownGui) then
            if object:IsA("TextLabel")
            or object:IsA("TextButton")
            or object:IsA("TextBox") then
                local found = ReadTimerFromText(object.Text, object.Name)

                if found then
                    return found
                end
            elseif object:IsA("StringValue") then
                local found = ReadTimerFromText(object.Value, object.Name)

                if found then
                    return found
                end
            elseif object:IsA("IntValue")
            or object:IsA("NumberValue") then
                local lowerName = string.lower(object.Name)

                if string.find(lowerName, "timer", 1, true)
                or string.find(lowerName, "time", 1, true)
                or string.find(lowerName, "round", 1, true) then
                    local found = FormatRoundSeconds(object.Value)

                    if found then
                        return found
                    end
                end
            end
        end
    end

    return nil
end

local function FindMM2RoundTimerText()
    local playerGui = Player:FindFirstChildOfClass("PlayerGui")
    local mainGui = playerGui and playerGui:FindFirstChild("MainGUI")
    local gameGui = mainGui and mainGui:FindFirstChild("Game")

    local directContainers = {
        gameGui,
        mainGui,
        playerGui,
        ReplicatedStorage,
        workspace
    }

    for _, container in ipairs(directContainers) do
        local found = ScanRoundTimerContainer(container)

        if found then
            return found
        end
    end

    return "N/A"
end

local function CreateRoundTimerFrame()
    if RoundTimerFrame and RoundTimerFrame.Parent then
        return
    end

    local gui = getgenv().Gui

    if not gui then
        return
    end

    RoundTimerFrame = Instance.new("Frame")
    RoundTimerFrame.Name = "ToxMM2RoundTimerFrame"
    RoundTimerFrame.Size = UDim2.new(0, 150, 0, 38)
    RoundTimerFrame.Position = UDim2.new(0.5, -75, 0, 84)
    RoundTimerFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 16)
    RoundTimerFrame.BackgroundTransparency = 0.25
    RoundTimerFrame.BorderSizePixel = 0
    RoundTimerFrame.Active = true
    RoundTimerFrame.Visible = false
    RoundTimerFrame.Parent = gui

    if getgenv().RegisterToxLinkedSubGui then
        getgenv().RegisterToxLinkedSubGui("MM2RoundTimer", RoundTimerFrame)
    end

    if getgenv().RegisterToxSubGuiMinimize then
        getgenv().RegisterToxSubGuiMinimize(RoundTimerFrame, -52)
    end

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = RoundTimerFrame

    local stroke = Instance.new("UIStroke")
    stroke.Color = MAIN_COLOR
    stroke.Thickness = 1
    stroke.Transparency = 0.25
    stroke.Parent = RoundTimerFrame

    if MakeDraggable then
        MakeDraggable(RoundTimerFrame, RoundTimerFrame)
    end

    RoundTimerLabel = Instance.new("TextLabel")
    RoundTimerLabel.Size = UDim2.new(1, -12, 1, 0)
    RoundTimerLabel.Position = UDim2.new(0, 6, 0, 0)
    RoundTimerLabel.BackgroundTransparency = 1
    RoundTimerLabel.Text = "Round: N/A"
    RoundTimerLabel.TextColor3 = Color3.fromRGB(245, 245, 245)
    RoundTimerLabel.Font = Enum.Font.GothamBold
    RoundTimerLabel.TextSize = 12
    RoundTimerLabel.Parent = RoundTimerFrame
end

local function SetRoundTimerVisible(enabled)
    Settings.MM2RoundTimer = enabled == true
    CreateRoundTimerFrame()

    if RoundTimerFrame then
        RoundTimerFrame.Visible = Settings.MM2RoundTimer
    end
end

AddConnection(RunService.Heartbeat:Connect(function()
    if not Settings.MM2RoundTimer
    or os.clock() - LastRoundTimerUpdate < 0.5 then
        return
    end

    LastRoundTimerUpdate = os.clock()
    CreateRoundTimerFrame()

    if RoundTimerLabel then
        RoundTimerLabel.Text = "Round: " .. FindMM2RoundTimerText()
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

local TargetMotionHistory =
    setmetatable(
        {},
        {
            __mode = "k"
        }
    )

local function ClampVectorMagnitude(
    vector,
    maximum
)
    if typeof(vector)
        ~= "Vector3" then
        return Vector3.zero
    end

    local magnitude =
        vector.Magnitude

    if magnitude <= maximum
    or magnitude <= 0 then
        return vector
    end

    return
        vector.Unit
        * maximum
end

local function UpdateTargetMotion(
    target
)
    if not target
    or not target.Character then
        TargetMotionHistory[
            target
        ] = nil

        return
    end

    local root =
        target.Character:
            FindFirstChild(
                "HumanoidRootPart"
            )

    if not root then
        TargetMotionHistory[
            target
        ] = nil

        return
    end

    local now =
        os.clock()

    local position =
        root.Position

    local state =
        TargetMotionHistory[
            target
        ]

    if not state then
        TargetMotionHistory[
            target
        ] = {
            Position = position,
            Velocity =
                root.AssemblyLinearVelocity,
            Acceleration =
                Vector3.zero,
            Time = now
        }

        return
    end

    local deltaTime =
        now
        - (
            state.Time
            or now
        )

    if deltaTime < 0.012
    or deltaTime > 0.35 then
        state.Position =
            position

        state.Velocity =
            root.AssemblyLinearVelocity

        state.Acceleration =
            Vector3.zero

        state.Time = now

        return
    end

    local measuredVelocity =
        (
            position
            - state.Position
        )
        / deltaTime

    measuredVelocity =
        ClampVectorMagnitude(
            measuredVelocity,
            125
        )

    local previousVelocity =
        state.Velocity
        or measuredVelocity

    local smoothedVelocity =
        previousVelocity:
            Lerp(
                measuredVelocity,
                0.58
            )

    local measuredAcceleration =
        (
            smoothedVelocity
            - previousVelocity
        )
        / deltaTime

    state.Acceleration =
        ClampVectorMagnitude(
            (
                state.Acceleration
                or Vector3.zero
            ):
                Lerp(
                    measuredAcceleration,
                    0.35
                ),
            95
        )

    state.Velocity =
        smoothedVelocity

    state.Position =
        position

    state.Time = now
end

AddConnection(
    RunService.Heartbeat:
        Connect(function()
            for _, target in ipairs(
                Players:
                    GetPlayers()
            ) do
                if target ~= Player then
                    UpdateTargetMotion(
                        target
                    )
                end
            end
        end)
)

local function GetShotOrigin()
    local character =
        Player.Character

    if not character then
        return
            Camera.CFrame.Position
    end

    local originPart =
        character:
            FindFirstChild(
                "RightHand"
            )
        or character:
            FindFirstChild(
                "Right Arm"
            )
        or character:
            FindFirstChild(
                "UpperTorso"
            )
        or character:
            FindFirstChild(
                "Torso"
            )
        or character:
            FindFirstChild(
                "HumanoidRootPart"
            )

    return
        originPart
        and originPart.Position
        or Camera.CFrame.Position
end

local function GetPredictionPing()
    local ping =
        0.055

    pcall(function()
        local value =
            Player:
                GetNetworkPing()

        if typeof(value)
            == "number"
        and value > 0 then
            ping =
                value
        end
    end)

    return
        math.clamp(
            ping,
            0.02,
            0.22
        )
end

local function GetPredictedTargetPosition(
    target
)
    if not target
    or not target.Character then
        return nil
    end

    local character =
        target.Character

    local humanoid =
        character:
            FindFirstChildOfClass(
                "Humanoid"
            )

    local root =
        character:
            FindFirstChild(
                "HumanoidRootPart"
            )

    if not humanoid
    or humanoid.Health <= 0
    or not root then
        return nil
    end

    local torso =
        character:
            FindFirstChild(
                "UpperTorso"
            )
        or character:
            FindFirstChild(
                "Torso"
            )
        or root

    local basePosition =
        torso.Position

    local state =
        TargetMotionHistory[
            target
        ]

    local replicatedVelocity =
        root.AssemblyLinearVelocity

    local measuredVelocity =
        state
        and state.Velocity
        or replicatedVelocity

    local velocity =
        replicatedVelocity:
            Lerp(
                measuredVelocity,
                0.52
            )

    local horizontalVelocity =
        Vector3.new(
            velocity.X,
            0,
            velocity.Z
        )

    local moveDirection =
        humanoid.MoveDirection

    if moveDirection.Magnitude > 0.05 then
        local expectedHorizontal =
            moveDirection.Unit
            * math.max(
                tonumber(
                    humanoid.WalkSpeed
                ) or 16,
                10
            )

        if horizontalVelocity.Magnitude
            < 4 then
            horizontalVelocity =
                expectedHorizontal
        else
            horizontalVelocity =
                horizontalVelocity:
                    Lerp(
                        expectedHorizontal,
                        0.28
                    )
        end
    end

    horizontalVelocity =
        ClampVectorMagnitude(
            horizontalVelocity,
            42
        )

    local verticalVelocity =
        math.clamp(
            velocity.Y,
            -65,
            65
        )

    local origin =
        GetShotOrigin()

    local distance =
        (
            basePosition
            - origin
        ).Magnitude

    local ping =
        GetPredictionPing()

    local leadTime =
        0.035
        + (
            ping
            * 0.92
        )
        + (
            distance
            / 1850
        )

    leadTime =
        math.clamp(
            leadTime,
            0.045,
            0.26
        )

    local humanoidState =
        humanoid:
            GetState()

    local airborne =
        humanoid.FloorMaterial
            == Enum.Material.Air
        or humanoidState
            == Enum.HumanoidStateType.Jumping
        or humanoidState
            == Enum.HumanoidStateType.Freefall

    local verticalOffset =
        verticalVelocity
        * leadTime

    if airborne then
        verticalOffset -=
            0.5
            * workspace.Gravity
            * leadTime
            * leadTime
    else
        verticalOffset *=
            0.28
    end

    local acceleration =
        state
        and state.Acceleration
        or Vector3.zero

    acceleration =
        Vector3.new(
            math.clamp(
                acceleration.X,
                -55,
                55
            ),
            0,
            math.clamp(
                acceleration.Z,
                -55,
                55
            )
        )

    local horizontalLead =
        horizontalVelocity
        * leadTime

    horizontalLead +=
        acceleration
        * (
            0.5
            * leadTime
            * leadTime
        )

    horizontalLead =
        ClampVectorMagnitude(
            horizontalLead,
            12
        )

    local predicted =
        basePosition
        + horizontalLead
        + Vector3.new(
            0,
            math.clamp(
                verticalOffset,
                -8,
                8
            ),
            0
        )

    local rootDifference =
        predicted
        - root.Position

    if rootDifference.Magnitude
        > 16 then
        predicted =
            root.Position
            + rootDifference.Unit
            * 16
    end

    return predicted
end

local function GetGuidedTargetPart(
    target
)
    if not target
    or not target.Character then
        return nil
    end

    local character =
        target.Character

    local humanoid =
        character:
            FindFirstChildOfClass(
                "Humanoid"
            )

    if not humanoid
    or humanoid.Health <= 0 then
        return nil
    end

    return
        character:
            FindFirstChild(
                "Head"
            )
        or character:
            FindFirstChild(
                "UpperTorso"
            )
        or character:
            FindFirstChild(
                "Torso"
            )
        or character:
            FindFirstChild(
                "HumanoidRootPart"
            )
end

local function GetGuidedVelocity(
    target
)
    local character =
        target
        and target.Character

    local root =
        character
        and character:
            FindFirstChild(
                "HumanoidRootPart"
            )

    if not root then
        return Vector3.zero
    end

    local velocity =
        root.AssemblyLinearVelocity

    local history =
        TargetMotionHistory[
            target
        ]

    if history
    and typeof(
        history.Velocity
    ) == "Vector3" then
        velocity =
            velocity:
                Lerp(
                    history.Velocity,
                    0.35
                )
    end

    local horizontal =
        Vector3.new(
            velocity.X,
            0,
            velocity.Z
        )

    horizontal =
        ClampVectorMagnitude(
            horizontal,
            42
        )

    return
        Vector3.new(
            horizontal.X,
            math.clamp(
                velocity.Y,
                -55,
                55
            ),
            horizontal.Z
        )
end

local function GetGuidedLeadTime()
    local ping =
        GetPredictionPing()

    return
        math.clamp(
            0.028
            + ping * 0.78,
            0.035,
            0.125
        )
end

local function BuildGuidedTargetSamples(
    target
)
    local targetPart =
        GetGuidedTargetPart(
            target
        )

    if not targetPart
    or not targetPart.Parent then
        return {}
    end

    local basePosition =
        targetPart.Position

    local velocity =
        GetGuidedVelocity(
            target
        )

    local horizontalSpeed =
        Vector3.new(
            velocity.X,
            0,
            velocity.Z
        ).Magnitude

    if horizontalSpeed < 1.5
    and math.abs(
        velocity.Y
    ) < 2 then
        return {
            basePosition
        }
    end

    local lead =
        GetGuidedLeadTime()

    local times = {
        math.max(
            0.02,
            lead * 0.60
        ),
        lead,
        math.min(
            0.16,
            lead * 1.40
        )
    }

    local samples = {}

    table.insert(
        samples,
        basePosition
    )

    for _, timeValue in ipairs(
        times
    ) do
        local predicted =
            basePosition
            + velocity
                * timeValue

        if math.abs(
            velocity.Y
        ) > 2 then
            predicted +=
                Vector3.new(
                    0,
                    -0.5
                    * workspace.Gravity
                    * timeValue
                    * timeValue,
                    0
                )
        end

        table.insert(
            samples,
            predicted
        )
    end

    return samples
end

local function FireGuidedGunShot(
    gun,
    target
)
    if not gun
    or not gun.Parent
    or not target
    or not target.Parent then
        return false
    end

    local samples =
        BuildGuidedTargetSamples(
            target
        )

    if #samples == 0 then
        return false
    end

    local fired = false

    local shootRemote =
        gun:
            FindFirstChild(
                "Shoot"
            )
        or gun:
            FindFirstChild(
                "Shoot",
                true
            )

    local knifeLocal =
        gun:
            FindFirstChild(
                "KnifeLocal"
            )
        or gun:
            FindFirstChild(
                "KnifeLocal",
                true
            )

    local createBeam =
        knifeLocal
        and (
            knifeLocal:
                FindFirstChild(
                    "CreateBeam"
                )
            or knifeLocal:
                FindFirstChild(
                    "CreateBeam",
                    true
                )
        )

    local remoteFunction =
        createBeam
        and (
            createBeam:
                FindFirstChild(
                    "RemoteFunction"
                )
            or createBeam:
                FindFirstChildWhichIsA(
                    "RemoteFunction",
                    true
                )
        )

    local primaryPosition =
        samples[
            math.min(
                3,
                #samples
            )
        ]

    if shootRemote
    and shootRemote:IsA(
        "RemoteEvent"
    ) then
        local ok =
            pcall(function()
                shootRemote:
                    FireServer(
                        CFrame.new(
                            primaryPosition
                            + Vector3.new(
                                0,
                                0.5,
                                0
                            )
                        ),
                        CFrame.new(
                            primaryPosition
                        )
                    )
            end)

        if ok then
            fired = true
        end
    end

    if remoteFunction
    and remoteFunction:IsA(
        "RemoteFunction"
    ) then
        for _, position in ipairs(
            samples
        ) do
            pcall(function()
                remoteFunction:
                    InvokeServer(
                        1,
                        position,
                        "AH2"
                    )
            end)

            fired = true
        end
    end

    if shootRemote
    and shootRemote:IsA(
        "RemoteEvent"
    )
    and #samples > 1 then
        task.spawn(function()
            for index = 2, #samples do
                task.wait(
                    0.012
                )

                if getgenv().Destroyed
                or not gun
                or not gun.Parent
                or not target
                or not target.Parent then
                    break
                end

                local liveSamples =
                    BuildGuidedTargetSamples(
                        target
                    )

                local position =
                    liveSamples[
                        math.min(
                            index,
                            #liveSamples
                        )
                    ]

                if position then
                    pcall(function()
                        shootRemote:
                            FireServer(
                                CFrame.new(
                                    position
                                    + Vector3.new(
                                        0,
                                        0.5,
                                        0
                                    )
                                ),
                                CFrame.new(
                                    position
                                )
                            )
                    end)

                    if remoteFunction
                    and remoteFunction:IsA(
                        "RemoteFunction"
                    ) then
                        pcall(function()
                            remoteFunction:
                                InvokeServer(
                                    1,
                                    position,
                                    "AH2"
                                )
                        end)
                    end
                end
            end
        end)
    end

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

    local targetPart =
        GetGuidedTargetPart(
            murderer
        )

    if not targetPart then
        GuidedShotBusy = false

        if showNotify then
            CustomNotify(
                "Murderer target unavailable",
                Color3.fromRGB(
                    255,
                    100,
                    100
                )
            )
        end

        return false
    end

    local fired =
        FireGuidedGunShot(
            gun,
            murderer
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

    local targetPosition =
        GetPredictedTargetPosition(
            murderer
        )

    if not targetPosition then
        SilentAimBusy = false
        return false
    end

    local fired =
        FireNormalDirectionalShot(
            gun,
            targetPosition
        )

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

        SilentAimBusy = false
    end)

    return fired
end

local function FindGunDrop()
    local gunDrop =
        workspace:
            FindFirstChild(
                "GunDrop",
                true
            )

    if not gunDrop then
        return nil
    end

    if gunDrop:IsA(
        "BasePart"
    ) then
        return gunDrop
    end

    if gunDrop:IsA(
        "Model"
    ) then
        return
            gunDrop.PrimaryPart
            or gunDrop:
                FindFirstChildWhichIsA(
                    "BasePart",
                    true
                )
    end

    return gunDrop:
        FindFirstChildWhichIsA(
            "BasePart",
            true
        )
end

local GunESPHighlight = nil
local GunESPBillboard = nil
local GunESPAdornee = nil
local LastGunDrop = nil
local GunDropWasPresent = false

local function ClearGunESP()
    if GunESPHighlight then
        pcall(function()
            GunESPHighlight:
                Destroy()
        end)

        GunESPHighlight = nil
    end

    if GunESPBillboard then
        pcall(function()
            GunESPBillboard:
                Destroy()
        end)

        GunESPBillboard = nil
    end

    GunESPAdornee = nil
end

local function CreateGunESP(
    gunDrop
)
    if not Settings.MM2GunESP
    or not gunDrop
    or not gunDrop.Parent then
        ClearGunESP()
        return
    end

    if GunESPAdornee
        == gunDrop
    and GunESPHighlight
    and GunESPHighlight.Parent
    and GunESPBillboard
    and GunESPBillboard.Parent then
        return
    end

    ClearGunESP()

    GunESPAdornee =
        gunDrop

    GunESPHighlight =
        Instance.new(
            "Highlight"
        )

    GunESPHighlight.Name =
        "ToxGunESPHighlight"

    GunESPHighlight.Adornee =
        gunDrop

    GunESPHighlight.FillColor =
        Color3.fromRGB(
            255,
            215,
            60
        )

    GunESPHighlight.OutlineColor =
        Color3.fromRGB(
            255,
            255,
            255
        )

    GunESPHighlight.FillTransparency =
        0.35

    GunESPHighlight.OutlineTransparency =
        0

    GunESPHighlight.DepthMode =
        Enum.HighlightDepthMode.AlwaysOnTop

    GunESPHighlight.Parent =
        gunDrop

    GunESPBillboard =
        Instance.new(
            "BillboardGui"
        )

    GunESPBillboard.Name =
        "ToxGunESPBillboard"

    GunESPBillboard.Adornee =
        gunDrop

    GunESPBillboard.Size =
        UDim2.new(
            0,
            110,
            0,
            28
        )

    GunESPBillboard.StudsOffset =
        Vector3.new(
            0,
            2.1,
            0
        )

    GunESPBillboard.AlwaysOnTop =
        true

    GunESPBillboard.MaxDistance =
        100000

    GunESPBillboard.Parent =
        gunDrop

    local label =
        Instance.new(
            "TextLabel"
        )

    label.Size =
        UDim2.new(
            1,
            0,
            1,
            0
        )

    label.BackgroundTransparency =
        1

    label.Text =
        "GUN"

    label.TextColor3 =
        Color3.fromRGB(
            255,
            255,
            255
        )

    label.TextStrokeColor3 =
        Color3.fromRGB(
            0,
            0,
            0
        )

    label.TextStrokeTransparency =
        0

    label.Font =
        Enum.Font.GothamBold

    label.TextSize = 14
    label.Parent =
        GunESPBillboard
end

local function RefreshGunDropState()
    local gunDrop =
        FindGunDrop()

    if gunDrop
    and gunDrop.Parent then
        if not GunDropWasPresent
        or LastGunDrop
            ~= gunDrop then
            GunDropWasPresent =
                true

            LastGunDrop =
                gunDrop

            CustomNotify(
                "Gun Dropped!",
                Color3.fromRGB(
                    255,
                    215,
                    70
                ),
                5
            )
        end

        if Settings.MM2GunESP then
            CreateGunESP(
                gunDrop
            )
        elseif GunESPHighlight
        or GunESPBillboard then
            ClearGunESP()
        end
    else
        GunDropWasPresent =
            false

        LastGunDrop = nil

        if GunESPHighlight
        or GunESPBillboard then
            ClearGunESP()
        end
    end
end

task.spawn(function()
    while not getgenv().Destroyed
    and game.PlaceId
        == 142823291 do
        pcall(
            RefreshGunDropState
        )

        task.wait(
            0.12
        )
    end
end)

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
            allow(0.5, "MM2 Grab Gun")
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
                allow(0.4, "MM2 Grab Gun Return")
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
local AutoFarmCanTouchCache = {}
local AutoFarmHoldPosition = nil
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
    if not coin
    or not coin.Parent
    or not coin:IsA("BasePart")
    or coin:GetAttribute("Collected")
    or coin:GetAttribute("Delete") then
        return false
    end

    if coin.Transparency < 0.98 then
        return true
    end

    return coin:FindFirstChildWhichIsA("TouchTransmitter", true) ~= nil
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

function ToxMM2GetCoinTouchParts(coin)
    local parts = {}

    if coin
    and coin.Parent then
        if coin:IsA("BasePart") then
            table.insert(parts, coin)
        end

        local parent = coin.Parent

        if parent then
            for _, object in ipairs(parent:GetDescendants()) do
                if object:IsA("BasePart")
                and object ~= coin then
                    local lower = string.lower(tostring(object.Name or ""))

                    if object:FindFirstChildWhichIsA("TouchTransmitter", true)
                    or string.find(lower, "coin", 1, true)
                    or string.find(lower, "touch", 1, true)
                    or string.find(lower, "hit", 1, true) then
                        table.insert(parts, object)
                    end
                end
            end
        end
    end

    return parts
end

function ToxMM2GetCharacterTouchParts(character, root)
    local parts = {}

    if root then
        table.insert(parts, root)
    end

    if character then
        local names = {
            "UpperTorso",
            "LowerTorso",
            "Torso",
            "HumanoidRootPart",
            "LeftFoot",
            "RightFoot",
            "Left Leg",
            "Right Leg",
            "LeftLowerLeg",
            "RightLowerLeg"
        }

        for _, name in ipairs(names) do
            local part = character:FindFirstChild(name, true)

            if part
            and part:IsA("BasePart") then
                local exists = false

                for _, saved in ipairs(parts) do
                    if saved == part then
                        exists = true
                        break
                    end
                end

                if not exists then
                    table.insert(parts, part)
                end
            end
        end
    end

    return parts
end

local function SetFarmCollision(enabled)
    local character = Player.Character

    if not character then
        return
    end

    if not enabled then
        ClearToxTable(AutoFarmCollisionCache)
        ClearToxTable(AutoFarmCanTouchCache)

        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                AutoFarmCollisionCache[part] = part.CanCollide
                AutoFarmCanTouchCache[part] = part.CanTouch
                part.CanCollide = false
                part.CanTouch = true
            end
        end
    else
        for part, oldValue in pairs(AutoFarmCollisionCache) do
            if part and part.Parent then
                part.CanCollide = oldValue
            end
        end

        for part, oldValue in pairs(AutoFarmCanTouchCache) do
            if part and part.Parent then
                part.CanTouch = oldValue
            end
        end

        ClearToxTable(AutoFarmCollisionCache)
        ClearToxTable(AutoFarmCanTouchCache)
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

local function SetFarmPosition(position, hold)
    if not AutoFarmRoot
    or not AutoFarmRoot.Parent
    or not AutoFarmRotation then
        return false
    end

    local allow = getgenv().AllowToxTeleport

    if allow then
        allow(0.18, "MM2 Auto Farm")
    end

    if hold then
        AutoFarmHoldPosition = position
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
        allow(0.8, "MM2 Auto Farm Return")
    end

    root.Anchored = false
    character:PivotTo(AutoFarmReturnCFrame)
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
end

local function StopAutoFarm(restore)
    AutoFarmGeneration = AutoFarmGeneration + 1
    AutoFarmAtCoin = false
    AutoFarmHoldPosition = nil

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
    AutoFarmHoldPosition = nil
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

    local _, farmYaw, _ = root.CFrame:ToOrientation()
    AutoFarmRotation = CFrame.Angles(0, farmYaw, 0) * CFrame.Angles(math.rad(90), 0, 0)

    AutoFarmOriginalAnchored = root.Anchored
    AutoFarmOriginalAutoRotate = humanoid.AutoRotate
    AutoFarmOriginalPlatformStand = humanoid.PlatformStand
    AutoFarmOriginalSit = humanoid.Sit
    AutoFarmOriginalRagdoll = humanoid:GetStateEnabled(Enum.HumanoidStateType.Ragdoll)
    AutoFarmOriginalFallingDown = humanoid:GetStateEnabled(Enum.HumanoidStateType.FallingDown)
    AutoFarmPrepared = true
    AutoFarmAtCoin = false
    AutoFarmHoldPosition = nil
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

local AutoFarmUndergroundTravelOffset = 6.75
local AutoFarmUndergroundPickupOffset = 6.35
local AutoFarmCoinHoldTime = 1.25

local function GetCoinBasePosition(coin)
    if not coin
    or not coin:IsA("BasePart") then
        return nil
    end

    return coin.Position
end

local function GetCoinTravelPosition(coin)
    local position = GetCoinBasePosition(coin)

    if not position then
        return Vector3.zero
    end

    return position - Vector3.new(0, AutoFarmUndergroundTravelOffset, 0)
end

local function GetCoinPickupPosition(coin)
    local position = GetCoinBasePosition(coin)

    if not position then
        return Vector3.zero
    end

    return position - Vector3.new(0, AutoFarmUndergroundPickupOffset, 0)
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

        if not SetFarmPosition(startPosition + delta * alpha, true) then
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

    local coinParts = ToxMM2GetCoinTouchParts(coin)
    local characterParts = ToxMM2GetCharacterTouchParts(character, root)
    local touched = false

    if firetouchinterest then
        for _, coinPart in ipairs(coinParts) do
            if coinPart
            and coinPart.Parent then
                for _, bodyPart in ipairs(characterParts) do
                    if bodyPart
                    and bodyPart.Parent then
                        pcall(function()
                            firetouchinterest(bodyPart, coinPart, 0)
                            firetouchinterest(bodyPart, coinPart, 1)
                        end)

                        touched = true
                    end
                end
            end
        end
    end

    return touched
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
    local holdUntil = os.clock() + AutoFarmCoinHoldTime
    local pickupPosition = GetCoinPickupPosition(coin)
    local retouchAt = 0

    AutoFarmAtCoin = true
    SetFarmPosition(pickupPosition, true)
    RunService.Heartbeat:Wait()

    while Settings.MM2AutoFarmV2
    and generation == AutoFarmGeneration
    and not IsFarmBagFull()
    and IsCoinValid(coin)
    and AutoFarmRoot
    and AutoFarmRoot.Parent
    and os.clock() <= holdUntil do
        pickupPosition = GetCoinPickupPosition(coin)
        AutoFarmHoldPosition = pickupPosition

        if AutoFarmRotation then
            AutoFarmRoot.Anchored = false
            AutoFarmRoot.CFrame = CFrame.new(pickupPosition) * AutoFarmRotation
            AutoFarmRoot.AssemblyLinearVelocity = Vector3.zero
            AutoFarmRoot.AssemblyAngularVelocity = Vector3.zero
        end

        if os.clock() >= retouchAt then
            TouchCoin(coin)
            retouchAt = os.clock() + 0.08
        end

        if not IsCoinValid(coin)
        or AutoFarmCoinSerial ~= serialBefore
        or AutoFarmBagCoins > bagBefore then
            AutoFarmAtCoin = false
            AutoFarmHoldPosition = nil
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

        task.wait(0.025)
    end

    AutoFarmAtCoin = false
    AutoFarmHoldPosition = nil
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
        MM2CoinBlacklist[coin] = os.clock() + 0.12
    else
        MM2CoinBlacklist[coin] = os.clock() + 0.35
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

    if AutoFarmRotation then
        local position = AutoFarmHoldPosition or AutoFarmRoot.Position
        AutoFarmRoot.CFrame = CFrame.new(position) * AutoFarmRotation
    end

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
                    if AutoFarmPrepared
                    and AutoFarmRoot
                    and AutoFarmRoot.Parent then
                        SetFarmPosition(
                            AutoFarmRoot.Position
                        )
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

local MM2CurrentSection = nil
local MM2Sections = {}

local function ApplyMM2SectionState(section)
    if typeof(section) ~= "table" then
        return
    end

    Settings.MM2CollapsedSections =
        typeof(Settings.MM2CollapsedSections) == "table"
        and Settings.MM2CollapsedSections
        or {}

    local collapsed =
        Settings.MM2CollapsedSections[section.Key] == true

    if section.Header
    and section.Header.Parent then
        section.Header.Text =
            collapsed
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

local function TrackMM2Control(object)
    if MM2CurrentSection
    and object
    and object:IsA("GuiObject") then
        table.insert(
            MM2CurrentSection.Controls,
            object
        )

        ApplyMM2SectionState(
            MM2CurrentSection
        )
    end

    return object
end

local function MM2CreateToggle(...)
    return TrackMM2Control(
        CreateToggle(...)
    )
end

local function MM2CreateToggleWithValue(...)
    return TrackMM2Control(
        CreateToggleWithValue(...)
    )
end

local function MM2CreateButton(...)
    return TrackMM2Control(
        CreateButton(...)
    )
end

local function MM2CreateDropdown(...)
    return TrackMM2Control(
        CreateDropdown(...)
    )
end

local function MM2CreateKeybindToggle(...)
    return TrackMM2Control(
        CreateKeybindToggle(...)
    )
end

local function CreateMM2Section(
    text
)
    Settings.MM2CollapsedSections =
        typeof(Settings.MM2CollapsedSections) == "table"
        and Settings.MM2CollapsedSections
        or {}

    local name =
        tostring(
            text
        )

    local key =
        string.gsub(
            name,
            "%s+",
            ""
        )

    local button =
        Instance.new(
            "TextButton"
        )

    button.Size =
        UDim2.new(
            1,
            -5,
            0,
            26
        )

    button.BackgroundColor3 =
        Color3.fromRGB(
            13,
            13,
            21
        )

    button.BorderSizePixel = 0
    button.TextColor3 =
        Color3.fromRGB(
            255,
            255,
            255
        )

    button.Font =
        Enum.Font.GothamBold

    button.TextSize = 11
    button.TextXAlignment =
        Enum.TextXAlignment.Left

    button.AutoButtonColor = false
    button.Parent =
        GamePage

    local corner =
        Instance.new("UICorner")

    corner.CornerRadius =
        UDim.new(
            0,
            5
        )

    corner.Parent =
        button

    local section = {
        Name = name,
        Key = key,
        Header = button,
        Controls = {}
    }

    table.insert(
        MM2Sections,
        section
    )

    MM2CurrentSection =
        section

    button.MouseButton1Click:Connect(function()
        Settings.MM2CollapsedSections[key] =
            not Settings.MM2CollapsedSections[key]

        ApplyMM2SectionState(
            section
        )

        AutoSaveConfiguration()
    end)

    ApplyMM2SectionState(
        section
    )

    return button
end

AutoFarmHighSpeedWarningShown = false

function WarnAutoFarmSpeed(
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

MM2CreateToggleWithValue("Auto Farm", GamePage, Settings.MM2AutoFarmV2, Settings.MM2AutoFarmSpeed, function(v)
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

MM2CreateToggle(
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

MM2CreateToggle("Role ESP", GamePage, Settings.MM2RoleESP, function(v)
    ApplyRoleESP(v)
end, "MM2RoleESP")

MM2CreateToggle(
    "Gun ESP",
    GamePage,
    Settings.MM2GunESP,
    function(v)
        Settings.MM2GunESP =
            v == true

        if Settings.MM2GunESP then
            local gunDrop =
                FindGunDrop()

            if gunDrop then
                CreateGunESP(
                    gunDrop
                )
            end
        else
            ClearGunESP()
        end

        AutoSaveConfiguration()
    end,
    "MM2GunESP"
)

MM2CreateToggleWithValue("Speed", GamePage, Settings.Speed, Settings.SpeedValue, function(v)
    SetShared("Speed", v)
end, function(value)
    Settings.SpeedValue = math.clamp(tonumber(value) or 16, 1, 250)

    if SyncValueVisuals then
        SyncValueVisuals("Speed", Settings.SpeedValue)
    end
end, "Speed")

MM2CreateToggle("Noclip", GamePage, Settings.Noclip, function(v)
    SetShared("Noclip", v)
end, "Noclip")

MM2CreateToggle("Anti Fling", GamePage, Settings.AntiFling, function(v)
    SetShared("AntiFling", v)
end, "AntiFling")

CreateMM2Section(
    "COMBAT"
)

MM2AutoRuntime = {
    SilentAim = Settings.MM2SilentAimAutoV2 == true,
    KillAll = Settings.MM2KillAllAutoV2 == true,
    Shoot = Settings.MM2ShootMurderAutoV2 == true,
    GrabGun = Settings.MM2GrabGunAutoV2 == true
}

MM2CreateKeybindToggle("Silent Aim", GamePage, Settings.MM2SilentAimKey, MM2AutoRuntime.SilentAim, function(key)
    Settings.MM2SilentAimKey = key
end, function(enabled)
    MM2AutoRuntime.SilentAim = enabled == true
    Settings.MM2SilentAimAutoV2 = MM2AutoRuntime.SilentAim
end, "MM2SilentAimAutoV2")

MM2CreateKeybindToggle("Kill All", GamePage, Settings.MM2KillAllKey, MM2AutoRuntime.KillAll, function(key)
    Settings.MM2KillAllKey = key
end, function(enabled)
    MM2AutoRuntime.KillAll = enabled == true
    Settings.MM2KillAllAutoV2 = MM2AutoRuntime.KillAll
end, "MM2KillAllAutoV2")

MM2CreateKeybindToggle("Shoot Murderer", GamePage, Settings.MM2ShootMurderKey, MM2AutoRuntime.Shoot, function(key)
    Settings.MM2ShootMurderKey = key
end, function(enabled)
    MM2AutoRuntime.Shoot = enabled == true
    Settings.MM2ShootMurderAutoV2 = MM2AutoRuntime.Shoot

    if not MM2AutoRuntime.Shoot then
        ShootSafetySerial = ShootSafetySerial + 1
    end
end, "MM2ShootMurderAutoV2")

MM2CreateKeybindToggle("Grab Gun", GamePage, Settings.MM2GrabGunKey, MM2AutoRuntime.GrabGun, function(key)
    Settings.MM2GrabGunKey = key
end, function(enabled)
    MM2AutoRuntime.GrabGun = enabled == true
    Settings.MM2GrabGunAutoV2 = MM2AutoRuntime.GrabGun
end, "MM2GrabGunAutoV2")

CreateMM2Section(
    "TARGETING"
)

MM2CreateToggle("Round Timer", GamePage, Settings.MM2RoundTimer, function(v)
    SetRoundTimerVisible(v)
    AutoSaveConfiguration()
end, "MM2RoundTimer")

MM2CreateDropdown("Fling Target", {"Murderer", "Sheriff"}, GamePage, Settings.MM2FlingTarget, function(value)
    Settings.MM2FlingTarget = value
    AutoSaveConfiguration()
end)

MM2CreateButton("Fling", GamePage, FlingSelectedRole)

MM2CreateButton("Target", GamePage, function()
    OpenPlayerSelector("targets")
end)

function GetMM2ActiveMapRoot()
    local normal =
        workspace:
            FindFirstChild(
                "Normal"
            )

    if normal then
        return normal
    end

    local best = nil
    local bestCount = 0

    for _, candidate in ipairs(
        workspace:
            GetChildren()
    ) do
        if candidate:IsA(
            "Model"
        )
        and not Players:
            GetPlayerFromCharacter(
                candidate
            ) then
            local lower =
                string.lower(
                    candidate.Name
                )

            if not string.find(
                lower,
                "lobby",
                1,
                true
            ) then
                local count = 0

                for _, object in ipairs(
                    candidate:
                        GetDescendants()
                ) do
                    if object:IsA(
                        "BasePart"
                    ) then
                        count += 1
                    end
                end

                if count > bestCount then
                    best = candidate
                    bestCount = count
                end
            end
        end
    end

    return best
end

function GetPartTopCFrame(
    part
)
    if not part
    or not part:IsA(
        "BasePart"
    ) then
        return nil
    end

    return
        CFrame.new(
            part.Position
            + Vector3.new(
                0,
                part.Size.Y * 0.5
                    + 4,
                0
            )
        )
end

function FindNamedSpawnIn(
    root
)
    if not root then
        return nil
    end

    local preferred = nil

    for _, object in ipairs(
        root:
            GetDescendants()
    ) do
        if object:IsA(
            "SpawnLocation"
        ) then
            return
                GetPartTopCFrame(
                    object
                )
        end

        if object:IsA(
            "BasePart"
        ) then
            local lower =
                string.lower(
                    object.Name
                )

            if string.find(
                lower,
                "spawn",
                1,
                true
            )
            or string.find(
                lower,
                "start",
                1,
                true
            ) then
                preferred =
                    preferred
                    or object
            end
        end
    end

    return
        GetPartTopCFrame(
            preferred
        )
end

function GetRootBounds(
    root
)
    if not root then
        return nil
    end

    if root:IsA(
        "Model"
    ) then
        local ok,
            cframe,
            size =
            pcall(function()
                return
                    root:
                        GetBoundingBox()
            end)

        if ok then
            return
                cframe,
                size
        end
    end

    local minimum = nil
    local maximum = nil

    for _, object in ipairs(
        root:
            GetDescendants()
    ) do
        if object:IsA(
            "BasePart"
        ) then
            local half =
                object.Size * 0.5

            local low =
                object.Position
                - half

            local high =
                object.Position
                + half

            minimum =
                minimum
                and Vector3.new(
                    math.min(
                        minimum.X,
                        low.X
                    ),
                    math.min(
                        minimum.Y,
                        low.Y
                    ),
                    math.min(
                        minimum.Z,
                        low.Z
                    )
                )
                or low

            maximum =
                maximum
                and Vector3.new(
                    math.max(
                        maximum.X,
                        high.X
                    ),
                    math.max(
                        maximum.Y,
                        high.Y
                    ),
                    math.max(
                        maximum.Z,
                        high.Z
                    )
                )
                or high
        end
    end

    if minimum
    and maximum then
        local size =
            maximum
            - minimum

        local center =
            minimum
            + size * 0.5

        return
            CFrame.new(
                center
            ),
            size
    end

    return nil
end

function GetSafeMapCFrame()
    local mapRoot = GetMM2ActiveMapRoot()

    if not mapRoot then
        return nil
    end

    local named = FindNamedSpawnIn(mapRoot)

    if named then
        return named
    end

    local bounds, size = GetRootBounds(mapRoot)

    if not bounds or not size then
        return nil
    end

    local bestPart = nil
    local bestScore = math.huge
    local targetFloorY = bounds.Position.Y - size.Y * 0.30

    for _, object in ipairs(mapRoot:GetDescendants()) do
        if object:IsA("BasePart")
        and object.CanCollide
        and object.Transparency < 0.95
        and object.Size.X >= 5
        and object.Size.Z >= 5 then
            local lower = string.lower(object.Name)
            local topY = object.Position.Y + object.Size.Y * 0.5
            local flatDistance = Vector2.new(
                object.Position.X - bounds.Position.X,
                object.Position.Z - bounds.Position.Z
            ).Magnitude

            local score = flatDistance + math.abs(topY - targetFloorY) * 1.75

            if object.Size.X >= 12 or object.Size.Z >= 12 then
                score -= 25
            end

            if string.find(lower, "floor", 1, true)
            or string.find(lower, "ground", 1, true)
            or string.find(lower, "base", 1, true)
            or string.find(lower, "spawn", 1, true) then
                score -= 45
            end

            if string.find(lower, "roof", 1, true)
            or string.find(lower, "ceiling", 1, true)
            or string.find(lower, "wall", 1, true)
            or string.find(lower, "tree", 1, true)
            or string.find(lower, "decor", 1, true) then
                score += 120
            end

            if score < bestScore then
                bestScore = score
                bestPart = object
            end
        end
    end

    if bestPart then
        return CFrame.new(
            bestPart.Position.X,
            bestPart.Position.Y + bestPart.Size.Y * 0.5 + 4,
            bestPart.Position.Z
        )
    end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = {mapRoot}

    local result = workspace:Raycast(
        bounds.Position + Vector3.new(0, size.Y * 0.5 + 150, 0),
        Vector3.new(0, -(size.Y + 500), 0),
        params
    )

    if result then
        return CFrame.new(result.Position + Vector3.new(0, 4, 0))
    end

    return nil
end

function GetLobbySpawnCFrame()
    local mapRoot =
        GetMM2ActiveMapRoot()

    local lobby =
        workspace:
            FindFirstChild(
                "Lobby"
            )

    if lobby then
        local named =
            FindNamedSpawnIn(
                lobby
            )

        if named then
            return named
        end
    end

    for _, object in ipairs(
        workspace:
            GetDescendants()
    ) do
        if object:IsA(
            "SpawnLocation"
        )
        and (
            not mapRoot
            or not object:
                IsDescendantOf(
                    mapRoot
                )
        ) then
            return
                GetPartTopCFrame(
                    object
                )
        end
    end

    if lobby then
        local bounds,
            size =
            GetRootBounds(
                lobby
            )

        if bounds
        and size then
            local params =
                RaycastParams.new()

            params.FilterType =
                Enum.RaycastFilterType.Include

            params.FilterDescendantsInstances = {
                lobby
            }

            local result =
                workspace:
                    Raycast(
                        bounds.Position
                        + Vector3.new(
                            0,
                            size.Y * 0.5
                                + 100,
                            0
                        ),
                        Vector3.new(
                            0,
                            -(size.Y + 300),
                            0
                        ),
                        params
                    )

            if result then
                return
                    CFrame.new(
                        result.Position
                        + Vector3.new(
                            0,
                            4,
                            0
                        )
                    )
            end
        end
    end

    return nil
end

function TeleportMM2To(
    cframe,
    label
)
    if typeof(cframe)
        ~= "CFrame" then
        CustomNotify(
            label
            .. " location unavailable",
            Color3.fromRGB(
                255,
                180,
                70
            )
        )

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

    local root =
        character
        and character:
            FindFirstChild(
                "HumanoidRootPart"
            )

    if not root
    or not humanoid
    or humanoid.Health <= 0 then
        return
    end

    if getgenv().RecordToxTeleportReturn then
        getgenv().RecordToxTeleportReturn()
    end

    if getgenv().AllowToxTeleport then
        getgenv().AllowToxTeleport(
            1.5,
            "MM2 " .. tostring(label or "TP")
        )
    end

    root.AssemblyLinearVelocity =
        Vector3.zero

    root.AssemblyAngularVelocity =
        Vector3.zero

    root.CFrame =
        cframe

    CustomNotify(
        "Teleported to "
        .. label,
        Color3.fromRGB(
            100,
            255,
            130
        )
    )
end

CreateMM2Section(
    "TELEPORTS"
)

MM2CreateButton(
    "SPAWN",
    GamePage,
    function()
        TeleportMM2To(
            GetLobbySpawnCFrame(),
            "SPAWN"
        )
    end
)

MM2CreateButton(
    "MAP",
    GamePage,
    function()
        TeleportMM2To(
            GetSafeMapCFrame(),
            "MAP"
        )
    end
)


AutoKnifeLastAttempt = 0
AutoSilentAimLastAttempt = 0
AutoShootLastAttempt = 0
AutoGrabAttemptedDrops = setmetatable({}, {__mode = "k"})

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

        if MM2AutoRuntime.SilentAim
        and Settings.MM2SilentAimAutoV2
        and not Settings.MM2AutoFarmV2
        and gun
        and alive
        and not ActionBusy
        and not SilentAimBusy
        and gun.Enabled ~= false then
            local murderer =
                FindGuidedMurderer()

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
            and os.clock() - AutoSilentAimLastAttempt
                >= 0.08 then
                AutoSilentAimLastAttempt =
                    os.clock()

                task.spawn(
                    SilentAimShot
                )
            end
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
        and not IsSheriffAlive()
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


LastManualShootInput = 0

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
        if os.clock() - LastManualShootInput < 0.08 then
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
    Settings.MM2SilentAimAuto = false
    Settings.MM2SilentAimAutoV2 = false
    Settings.MM2KillAllAuto = false
    Settings.MM2KillAllAutoV2 = false
    Settings.MM2ShootMurderAuto = false
    Settings.MM2ShootMurderAutoV2 = false
    Settings.MM2GrabGunAuto = false
    Settings.MM2GrabGunAutoV2 = false

    MM2AutoRuntime.SilentAim = false
    MM2AutoRuntime.KillAll = false
    MM2AutoRuntime.Shoot = false
    MM2AutoRuntime.GrabGun = false
    ShootSafetySerial = ShootSafetySerial + 1
    GuidedShotBusy = false
    SilentAimBusy = false
    ActionBusy = false
    AutoSilentAimLastAttempt = 0
    AutoShootLastAttempt = 0
    ClearToxTable(KnifeTargetIds)

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

    ClearToxTable(KnifeTargetIds)

    if AutoFarmPrepared then
        StopAutoFarm(true)
    end

    ClearGunESP()

    if PlayerSelectorFrame then
        PlayerSelectorFrame.Visible = false
    end

    if RoundTimerFrame then
        RoundTimerFrame.Visible = false
    end

    if getgenv().ToxLinkedSubGuis then
        getgenv().ToxLinkedSubGuis.MM2PlayerSelector = nil
    end

    if getgenv().SyncToggleVisuals then
        getgenv().SyncToggleVisuals("MM2AutoFarmV2", false)
        getgenv().SyncToggleVisuals("MM2RoleESP", false)
        getgenv().SyncToggleVisuals("MM2GunESP", Settings.MM2GunESP)
        getgenv().SyncToggleVisuals("MM2SilentAimAutoV2", false)
        getgenv().SyncToggleVisuals("MM2KillAllAutoV2", false)
        getgenv().SyncToggleVisuals("MM2ShootMurderAutoV2", false)
        getgenv().SyncToggleVisuals("MM2GrabGunAutoV2", false)
    end
end

if Settings.MM2RoleESP then
    ApplyRoleESP(
        true
    )
end

if Settings.MM2RoundTimer then
    SetRoundTimerVisible(true)
end

getgenv().ToxMM2ModuleLoadedJobId =
    game.JobId

getgenv().ToxMM2ModuleVersion =
    MM2ModuleVersion

getgenv().ToxMM2ModulePage =
    GamePage
