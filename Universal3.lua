local env = getgenv()

if type(env.ToxUniversal3Cleanup) == "function" then
    pcall(env.ToxUniversal3Cleanup)
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Player = Players.LocalPlayer
local Settings = env.Settings or {}
local RENDER_BIND = "ToxUniversal3Combat"
local instanceToken = {}

Settings.AimLock = Settings.AimLock == true
Settings.LockRadius = math.clamp(tonumber(Settings.LockRadius) or 110, 1, 2000)
Settings.AimTargets = tostring(Settings.AimTargets or "Players Only")
Settings.IgnoreFriends = Settings.IgnoreFriends == true
Settings.ProjectileSpeed = math.clamp(tonumber(Settings.ProjectileSpeed) or 200, 1, 5000)
Settings.ProjectileDrop = math.clamp(tonumber(Settings.ProjectileDrop) or 0, -1000, 1000)
Settings.RageMode = Settings.RageMode == true
Settings.RageDistance = math.clamp(tonumber(Settings.RageDistance) or 5, 1, 5000)
Settings.AntiAim = Settings.AntiAim == true
Settings.AntiAimType = tostring(Settings.AntiAimType or "Shift")
Settings.NormalizeAnimations = Settings.NormalizeAnimations == true
Settings.ForceJump = Settings.ForceJump == true
Settings.FixUnanchoredParts = Settings.FixUnanchoredParts == true
Settings.StartHidden = Settings.StartHidden == true
Settings.UnlockCursor = Settings.UnlockCursor == true

env.Settings = Settings
env.ToxUniversal3Token = instanceToken

local friendCache = {}
local npcCache = {}
local npcCacheTime = 0
local lockedTarget = nil
local antiAimDefaults = setmetatable({}, {__mode = "k"})
local animationDefaults = setmetatable({}, {__mode = "k"})
local forceJumpDefaults = setmetatable({}, {__mode = "k"})
local antiAimJitter = false
local antiAimJitterClock = 0
local antiAimSpinYaw = 0
local normalizeClock = 0
local connections = {}
local combatUIInstalled = false
local playerUIInstalled = false
local miscUIInstalled = false
local configUIInstalled = false
local cursorDefaults = nil
local fixClock = 0
local lastUniversalSection = nil

local function AddConnection(connection)
    if connection then
        connections[#connections + 1] = connection
    end
    return connection
end

local function Save()
    if env.ToxOptionsReady == false then
        return
    end

    if type(env.AutoSaveConfiguration) == "function" then
        pcall(env.AutoSaveConfiguration)
    end
end

local function IsFriend(targetPlayer)
    if not Settings.IgnoreFriends
    or not targetPlayer
    or targetPlayer == Player then
        return false
    end

    local userId = tonumber(targetPlayer.UserId) or 0

    if friendCache[userId] ~= nil then
        return friendCache[userId] == true
    end

    local result = false
    pcall(function()
        result = Player:IsFriendsWith(userId) == true
    end)

    friendCache[userId] = result
    return result
end

local function GetModelAimPart(model)
    if not model then
        return nil
    end

    local wanted = tostring(Settings.AimPart or "Head")
    local part = model:FindFirstChild(wanted)

    if part and part:IsA("BasePart") then
        return part
    end

    part = model:FindFirstChild("Head")
        or model:FindFirstChild("HumanoidRootPart")
        or model:FindFirstChild("UpperTorso")
        or model:FindFirstChild("Torso")

    if part and part:IsA("BasePart") then
        return part
    end

    return nil
end

local function RefreshNPCCache()
    local now = tick()

    if now - npcCacheTime < 1 then
        return
    end

    npcCacheTime = now
    npcCache = {}

    local count = 0

    for _, object in ipairs(Workspace:GetDescendants()) do
        if object:IsA("Humanoid")
        and object.Health > 0 then
            local model = object.Parent

            if model
            and model:IsA("Model")
            and not Players:GetPlayerFromCharacter(model) then
                local part = GetModelAimPart(model)

                if part then
                    npcCache[#npcCache + 1] = model
                    count += 1

                    if count >= 200 then
                        break
                    end
                end
            end
        end
    end
end

local function IsVisible(target)
    if not Settings.AimWallCheck then
        return true
    end

    local camera = Workspace.CurrentCamera
    local part = target and target.Part
    local model = target and target.Model

    if not camera or not part then
        return false
    end

    local origin = camera.CFrame.Position
    local direction = part.Position - origin

    if direction.Magnitude <= 0.05 then
        return true
    end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.IgnoreWater = true
    params.FilterDescendantsInstances = Player.Character and {Player.Character} or {}

    local result = Workspace:Raycast(origin, direction, params)

    if not result then
        return true
    end

    return model ~= nil and result.Instance:IsDescendantOf(model)
end

local function TargetValid(target)
    if typeof(target) ~= "table"
    or not target.Part
    or not target.Part.Parent
    or not target.Humanoid
    or target.Humanoid.Health <= 0 then
        return false
    end

    if target.Player then
        if target.Player == Player
        or target.Player.Parent ~= Players
        or IsFriend(target.Player) then
            return false
        end
    end

    return IsVisible(target)
end

local function GetCandidates()
    local mode = tostring(Settings.AimTargets or "Players Only")
    local candidates = {}

    if mode ~= "NPCs Only" then
        for _, targetPlayer in ipairs(Players:GetPlayers()) do
            if targetPlayer ~= Player
            and targetPlayer.Character
            and not IsFriend(targetPlayer) then
                local humanoid = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
                local part = GetModelAimPart(targetPlayer.Character)

                if humanoid
                and humanoid.Health > 0
                and part then
                    candidates[#candidates + 1] = {
                        Part = part,
                        Humanoid = humanoid,
                        Player = targetPlayer,
                        Model = targetPlayer.Character
                    }
                end
            end
        end
    end

    if mode == "NPCs Only"
    or mode == "Players + NPCs" then
        RefreshNPCCache()

        for _, model in ipairs(npcCache) do
            local humanoid = model and model:FindFirstChildOfClass("Humanoid")
            local part = GetModelAimPart(model)

            if humanoid
            and humanoid.Health > 0
            and part then
                candidates[#candidates + 1] = {
                    Part = part,
                    Humanoid = humanoid,
                    Player = nil,
                    Model = model
                }
            end
        end
    end

    return candidates
end

local function GetMouseTarget()
    local camera = Workspace.CurrentCamera

    if not camera then
        return nil
    end

    local mousePosition = UserInputService:GetMouseLocation()
    local radius = math.max(1, tonumber(Settings.LockRadius) or 110)
    local best = nil
    local bestDistance = radius

    for _, target in ipairs(GetCandidates()) do
        if TargetValid(target) then
            local screen, onScreen = camera:WorldToViewportPoint(target.Part.Position)

            if onScreen and screen.Z > 0 then
                local distance = (
                    Vector2.new(screen.X, screen.Y)
                    - mousePosition
                ).Magnitude

                if distance < bestDistance then
                    bestDistance = distance
                    best = target
                end
            end
        end
    end

    return best
end

local function GetRageTarget(root)
    if not root then
        return nil
    end

    local range = math.max(1, tonumber(Settings.RageDistance) or 5)
    local best = nil
    local bestDistance = range

    for _, target in ipairs(GetCandidates()) do
        if TargetValid(target) then
            local distance = (root.Position - target.Part.Position).Magnitude

            if distance <= bestDistance then
                bestDistance = distance
                best = target
            end
        end
    end

    return best
end

local function PredictPosition(target)
    if not target or not target.Part then
        return nil
    end

    local camera = Workspace.CurrentCamera

    if not camera then
        return target.Part.Position
    end

    local position = target.Part.Position
    local speed = math.max(1, tonumber(Settings.ProjectileSpeed) or 200)
    local distance = (position - camera.CFrame.Position).Magnitude
    local travelTime = math.clamp(distance / speed, 0, 5)
    local velocity = target.Part.AssemblyLinearVelocity or Vector3.zero
    local drop = tonumber(Settings.ProjectileDrop) or 0

    return position
        + velocity * travelTime
        + Vector3.new(0, 0.5 * drop * travelTime * travelTime, 0)
end

local function RestoreAntiAim()
    for humanoid, autoRotate in pairs(antiAimDefaults) do
        if humanoid and humanoid.Parent then
            pcall(function()
                humanoid.AutoRotate = autoRotate
            end)
        end
    end

    antiAimDefaults = setmetatable({}, {__mode = "k"})
end

local function ApplyAntiAim(root, humanoid, delta)
    if not root
    or not humanoid
    or humanoid.Health <= 0 then
        return
    end

    if antiAimDefaults[humanoid] == nil then
        antiAimDefaults[humanoid] = humanoid.AutoRotate
    end

    humanoid.AutoRotate = false

    local mode = tostring(Settings.AntiAimType or "Shift")
    local camera = Workspace.CurrentCamera
    local look = camera and camera.CFrame.LookVector or root.CFrame.LookVector
    local horizontal = Vector3.new(-look.X, 0, -look.Z)

    if horizontal.Magnitude <= 0.001 then
        horizontal = Vector3.new(0, 0, 1)
    else
        horizontal = horizontal.Unit
    end

    if mode == "Spin" then
        antiAimSpinYaw = (
            antiAimSpinYaw
            + math.rad(540) * math.max(tonumber(delta) or 0, 0)
        ) % (math.pi * 2)

        root.CFrame = CFrame.new(root.Position)
            * CFrame.Angles(0, antiAimSpinYaw, 0)
        return
    end

    local frame = CFrame.lookAt(root.Position, root.Position + horizontal)

    if mode == "Jitter" then
        antiAimJitterClock += math.max(tonumber(delta) or 0, 0)

        if antiAimJitterClock >= 0.08 then
            antiAimJitterClock = 0
            antiAimJitter = not antiAimJitter
        end

        frame *= CFrame.Angles(
            0,
            math.rad(antiAimJitter and 42 or -42),
            0
        )
    end

    root.CFrame = frame
end

local function RestoreAnimations()
    for track, speed in pairs(animationDefaults) do
        pcall(function()
            if track and track.IsPlaying then
                track:AdjustSpeed(speed)
            end
        end)
    end

    animationDefaults = setmetatable({}, {__mode = "k"})
end

local function NormalizeAnimations()
    local character = Player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")

    if not animator then
        return
    end

    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
        if animationDefaults[track] == nil then
            animationDefaults[track] = tonumber(track.Speed) or 1
        end

        pcall(function()
            track:AdjustSpeed(1)
        end)
    end
end

local function CaptureForceJump(humanoid)
    if not humanoid
    or forceJumpDefaults[humanoid] then
        return
    end

    local jumpStateEnabled = true

    pcall(function()
        jumpStateEnabled = humanoid:GetStateEnabled(
            Enum.HumanoidStateType.Jumping
        )
    end)

    forceJumpDefaults[humanoid] = {
        UseJumpPower = humanoid.UseJumpPower,
        JumpPower = humanoid.JumpPower,
        JumpHeight = humanoid.JumpHeight,
        JumpStateEnabled = jumpStateEnabled
    }
end

local function ApplyForceJump(humanoid)
    if not humanoid
    or humanoid.Health <= 0 then
        return
    end

    CaptureForceJump(humanoid)

    pcall(function()
        humanoid:SetStateEnabled(
            Enum.HumanoidStateType.Jumping,
            true
        )
    end)

    if humanoid.UseJumpPower then
        humanoid.JumpPower = math.max(tonumber(humanoid.JumpPower) or 0, 50)
    else
        humanoid.JumpHeight = math.max(tonumber(humanoid.JumpHeight) or 0, 7.2)
    end
end

local function RestoreForceJump()
    for humanoid, defaults in pairs(forceJumpDefaults) do
        if humanoid and humanoid.Parent then
            pcall(function()
                humanoid.UseJumpPower = defaults.UseJumpPower
                humanoid.JumpPower = defaults.JumpPower
                humanoid.JumpHeight = defaults.JumpHeight
                humanoid:SetStateEnabled(
                    Enum.HumanoidStateType.Jumping,
                    defaults.JumpStateEnabled
                )
            end)
        end
    end

    forceJumpDefaults = setmetatable({}, {__mode = "k"})
end

local function IsCharacterPart(part)
    local model = part and part:FindFirstAncestorOfClass("Model")
    return model ~= nil and model:FindFirstChildOfClass("Humanoid") ~= nil
end

local function SetUnlockCursor(enabled)
    Settings.UnlockCursor = enabled == true

    if Settings.UnlockCursor then
        if not cursorDefaults then
            cursorDefaults = {
                MouseBehavior = UserInputService.MouseBehavior,
                MouseIconEnabled = UserInputService.MouseIconEnabled
            }
        end

        pcall(function()
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
            UserInputService.MouseIconEnabled = true
        end)
    elseif cursorDefaults then
        pcall(function()
            UserInputService.MouseBehavior = cursorDefaults.MouseBehavior
            UserInputService.MouseIconEnabled = cursorDefaults.MouseIconEnabled
        end)
        cursorDefaults = nil
    end
end

local function FixDangerousUnanchoredParts()
    local character = Player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if not root then
        return
    end

    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {character}

    local ok, parts = pcall(function()
        return Workspace:GetPartBoundsInRadius(root.Position, 45, params)
    end)

    if not ok or typeof(parts) ~= "table" then
        return
    end

    for _, part in ipairs(parts) do
        if part:IsA("BasePart")
        and not part.Anchored
        and not IsCharacterPart(part) then
            local linear = part.AssemblyLinearVelocity.Magnitude
            local angular = part.AssemblyAngularVelocity.Magnitude

            if linear > 120 or angular > 70 then
                pcall(function()
                    part.AssemblyLinearVelocity = Vector3.zero
                    part.AssemblyAngularVelocity = Vector3.zero
                end)
            end
        end
    end
end

local function PanicDisable()
    for key, value in pairs(Settings) do
        if typeof(value) == "boolean"
        and key ~= "StartHidden" then
            Settings[key] = false
            if type(env.SyncToggleVisuals) == "function" then
                pcall(env.SyncToggleVisuals, key, false)
            end
        end
    end

    Settings.Render3D = true
    SetUnlockCursor(false)

    if type(env.ToxSetXRay) == "function" then
        pcall(env.ToxSetXRay, false)
    end

    if type(env.ToxSetFakeLag) == "function" then
        pcall(env.ToxSetFakeLag, false)
    end

    if type(env.ToxResetPart2Visuals) == "function" then
        pcall(env.ToxResetPart2Visuals)
    end

    if type(env.ToxSetFreecam) == "function" then
        pcall(env.ToxSetFreecam, false)
    end

    if type(env.ToxSetNoclipCamera) == "function" then
        pcall(env.ToxSetNoclipCamera, false)
    end

    local main = env.Main
    if main then
        main.Visible = false
    end

    if type(env.CustomNotify) == "function" then
        env.CustomNotify(
            "PANIC • all toggles disabled",
            Color3.fromRGB(255, 120, 120),
            4
        )
    end
end

local function CreateNumberOption(name, page, defaultValue, minValue, maxValue, callback)
    if not page then
        return nil
    end

    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -5, 0, 39)
    container.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
    container.BorderSizePixel = 0
    container.Parent = page

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -90, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(240, 240, 240)
    label.TextSize = 13
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local input = Instance.new("TextBox")
    input.Size = UDim2.new(0, 72, 0, 25)
    input.Position = UDim2.new(1, -82, 0.5, -12)
    input.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
    input.BorderSizePixel = 0
    input.Text = tostring(defaultValue)
    input.TextColor3 = Color3.fromRGB(255, 255, 255)
    input.TextSize = 12
    input.Font = Enum.Font.Gotham
    input.ClearTextOnFocus = false
    input.Parent = container

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = input

    input.FocusLost:Connect(function()
        local value = tonumber(input.Text)

        if value == nil then
            input.Text = tostring(defaultValue)
            return
        end

        value = math.clamp(value, minValue, maxValue)
        input.Text = tostring(value)
        callback(value)
        Save()
    end)

    if type(env.TrackUniversalControl) == "function" then
        env.TrackUniversalControl(container, page)
    end

    if type(env.RegisterToxSearchControl) == "function" then
        env.RegisterToxSearchControl(name, page, container)
    end

    return container
end

local function InstallCombatUI()
    if combatUIInstalled then
        return
    end

    local page = env.CombatPage or env.UniversalPage
    local CreateToggle = env.CreateToggle
    local CreateDropdown = env.CreateDropdown

    if not page
    or type(CreateToggle) ~= "function"
    or type(CreateDropdown) ~= "function" then
        return
    end

    combatUIInstalled = true

    CreateToggle(
        "Aim Lock",
        page,
        Settings.AimLock,
        function(value)
            Settings.AimLock = value == true
            if not Settings.AimLock then
                lockedTarget = nil
            end
        end,
        "AimLock"
    )

    CreateNumberOption(
        "Lock Radius",
        page,
        Settings.LockRadius,
        1,
        2000,
        function(value)
            Settings.LockRadius = value
            lockedTarget = nil
        end
    )

    CreateDropdown(
        "Aim Targets",
        {"Players Only", "NPCs Only", "Players + NPCs"},
        page,
        Settings.AimTargets,
        function(value)
            Settings.AimTargets = tostring(value)
            lockedTarget = nil
        end
    )

    CreateToggle(
        "Ignore Friends",
        page,
        Settings.IgnoreFriends,
        function(value)
            Settings.IgnoreFriends = value == true
            friendCache = {}
            lockedTarget = nil
        end,
        "IgnoreFriends"
    )

    CreateNumberOption(
        "Projectile Speed",
        page,
        Settings.ProjectileSpeed,
        1,
        5000,
        function(value)
            Settings.ProjectileSpeed = value
        end
    )

    CreateNumberOption(
        "Projectile Drop",
        page,
        Settings.ProjectileDrop,
        -1000,
        1000,
        function(value)
            Settings.ProjectileDrop = value
        end
    )

    CreateToggle(
        "Rage Mode",
        page,
        Settings.RageMode,
        function(value)
            Settings.RageMode = value == true
            lockedTarget = nil
        end,
        "RageMode"
    )

    CreateNumberOption(
        "Rage Distance",
        page,
        Settings.RageDistance,
        1,
        5000,
        function(value)
            Settings.RageDistance = value
        end
    )

    CreateToggle(
        "Anti Aim",
        page,
        Settings.AntiAim,
        function(value)
            Settings.AntiAim = value == true
            if not Settings.AntiAim then
                RestoreAntiAim()
            end
        end,
        "AntiAim"
    )

    CreateDropdown(
        "Anti Aim Type",
        {"Shift", "Jitter", "Spin"},
        page,
        Settings.AntiAimType,
        function(value)
            Settings.AntiAimType = tostring(value)
        end
    )
end

local function InstallPlayerUI()
    if playerUIInstalled then
        return
    end

    local page = env.PlayerPage or env.UniversalPage
    local CreateToggle = env.CreateToggle

    if not page
    or type(CreateToggle) ~= "function" then
        return
    end

    playerUIInstalled = true

    CreateToggle(
        "Normalize Animations",
        page,
        Settings.NormalizeAnimations,
        function(value)
            Settings.NormalizeAnimations = value == true
            if not Settings.NormalizeAnimations then
                RestoreAnimations()
            end
        end,
        "NormalizeAnimations"
    )

    CreateToggle(
        "Force Jump",
        page,
        Settings.ForceJump,
        function(value)
            Settings.ForceJump = value == true
            if not Settings.ForceJump then
                RestoreForceJump()
            end
        end,
        "ForceJump"
    )
end

local function InstallMiscUI()
    if miscUIInstalled then
        return
    end

    local page = env.FlingPage or env.UniversalPage
    local CreateToggle = env.CreateToggle

    if not page or type(CreateToggle) ~= "function" then
        return
    end

    miscUIInstalled = true

    CreateToggle(
        "Fix Unanchored Parts",
        page,
        Settings.FixUnanchoredParts,
        function(value)
            Settings.FixUnanchoredParts = value == true
        end,
        "FixUnanchoredParts"
    )
end

local function InstallConfigUI()
    if configUIInstalled then
        return
    end

    local page = env.ConfigPage
    local CreateToggle = env.CreateToggle
    local CreateKeybindButton = env.CreateKeybindButton

    if not page
    or type(CreateToggle) ~= "function"
    or type(CreateKeybindButton) ~= "function" then
        return
    end

    configUIInstalled = true

    CreateKeybindButton(
        "Panic Key",
        page,
        Settings.PanicKey,
        function(key)
            Settings.PanicKey = key
            Save()
        end
    )

    CreateToggle(
        "Start Hidden",
        page,
        Settings.StartHidden,
        function(value)
            Settings.StartHidden = value == true
        end,
        "StartHidden"
    )

    CreateToggle(
        "Unlock Cursor",
        page,
        Settings.UnlockCursor,
        SetUnlockCursor,
        "UnlockCursor"
    )
end

local previousBeginUniversalSection = env.BeginUniversalSection or BeginUniversalSection

function BeginUniversalSection(name)
    local nextKey = string.upper(tostring(name or "")):gsub("%s+", "")

    if lastUniversalSection == "COMBAT" then
        InstallCombatUI()
    elseif lastUniversalSection == "PLAYER" then
        InstallPlayerUI()
    end

    local result = nil

    if type(previousBeginUniversalSection) == "function" then
        result = previousBeginUniversalSection(name)
    end

    if nextKey == "MISC" then
        InstallMiscUI()
    end

    lastUniversalSection = nextKey
    return result
end

env.BeginUniversalSection = BeginUniversalSection
env.ToxSetUnlockCursor = SetUnlockCursor

InstallConfigUI()

AddConnection(UserInputService.InputBegan:Connect(function(input, processed)
    if processed
    or env.Destroyed
    or not env.ScriptLoaded
    or not Settings.PanicKey
    or input.UserInputType ~= Enum.UserInputType.Keyboard
    or input.KeyCode ~= Settings.PanicKey
    or UserInputService:GetFocusedTextBox() then
        return
    end

    PanicDisable()
end))

AddConnection(UserInputService.JumpRequest:Connect(function()
    if not env.ScriptLoaded
    or env.Destroyed
    or not Settings.ForceJump then
        return
    end

    local character = Player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if humanoid and humanoid.Health > 0 then
        ApplyForceJump(humanoid)
        humanoid.Jump = true
        pcall(function()
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end)
    end
end))

pcall(function()
    RunService:UnbindFromRenderStep(RENDER_BIND)
end)

RunService:BindToRenderStep(
    RENDER_BIND,
    Enum.RenderPriority.Last.Value,
    function(delta)
        if env.ToxUniversal3Token ~= instanceToken
        or env.Destroyed then
            return
        end

        if not env.ScriptLoaded then
            return
        end

        local character = Player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local root = character and character:FindFirstChild("HumanoidRootPart")

        if Settings.UnlockCursor then
            pcall(function()
                UserInputService.MouseBehavior = Enum.MouseBehavior.Default
                UserInputService.MouseIconEnabled = true
            end)
        end

        fixClock += math.max(tonumber(delta) or 0, 0)
        if Settings.FixUnanchoredParts and fixClock >= 0.18 then
            fixClock = 0
            FixDangerousUnanchoredParts()
        elseif not Settings.FixUnanchoredParts then
            fixClock = 0
        end

        if Settings.AntiAim and root and humanoid then
            ApplyAntiAim(root, humanoid, delta)
        elseif next(antiAimDefaults) ~= nil then
            RestoreAntiAim()
        end

        if Settings.ForceJump and humanoid then
            ApplyForceJump(humanoid)
        elseif next(forceJumpDefaults) ~= nil then
            RestoreForceJump()
        end

        if Settings.NormalizeAnimations then
            normalizeClock += math.max(tonumber(delta) or 0, 0)

            if normalizeClock >= 0.25 then
                normalizeClock = 0
                NormalizeAnimations()
            end
        else
            normalizeClock = 0

            if next(animationDefaults) ~= nil then
                RestoreAnimations()
            end
        end

        local rageActive = Settings.RageMode == true
        local aimLockActive = Settings.AimLock == true
            and Settings.Aimbot == true
            and UserInputService:IsMouseButtonPressed(
                Enum.UserInputType.MouseButton2
            )

        if not rageActive and not aimLockActive then
            lockedTarget = nil
            return
        end

        local camera = Workspace.CurrentCamera

        if not camera or not root then
            lockedTarget = nil
            return
        end

        local target = lockedTarget

        if target and not TargetValid(target) then
            target = nil
        end

        if rageActive and target then
            local maxDistance = math.max(
                1,
                tonumber(Settings.RageDistance) or 5
            )

            if (root.Position - target.Part.Position).Magnitude > maxDistance then
                target = nil
            end
        end

        if not target then
            if rageActive then
                target = GetRageTarget(root)
            else
                target = GetMouseTarget()
            end
        end

        lockedTarget = target

        local aimPosition = PredictPosition(target)

        if not aimPosition then
            return
        end

        if rageActive then
            camera.CFrame = CFrame.new(camera.CFrame.Position, aimPosition)
        else
            local smooth = math.max(
                1,
                tonumber(Settings.AimbotSmoothness) or 2
            )

            camera.CFrame = camera.CFrame:Lerp(
                CFrame.new(camera.CFrame.Position, aimPosition),
                1 / smooth
            )
        end
    end
)

env.ToxUniversal3Cleanup = function()
    pcall(function()
        RunService:UnbindFromRenderStep(RENDER_BIND)
    end)

    for _, connection in ipairs(connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    connections = {}
    lockedTarget = nil
    RestoreAntiAim()
    RestoreAnimations()
    RestoreForceJump()
    SetUnlockCursor(false)

    if env.ToxUniversal3Token == instanceToken then
        env.ToxUniversal3Token = nil
    end
end

task.spawn(function()
    while env.ToxUniversal3Token == instanceToken
    and not env.Destroyed do
        task.wait(0.15)
    end

    if env.ToxUniversal3Token == instanceToken
    and env.Destroyed then
        env.ToxUniversal3Cleanup()
    end
end)

env.ToxUniversal3Loaded = true
env.ToxUniversal3Version = "2026-09-14-part1-plus-misc-config"
