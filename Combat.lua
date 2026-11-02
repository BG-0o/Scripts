-- ==============================================================================
-- TOXHUB COMBAT ENGINE (Combat.lua)
-- Standalone Universal Combat Module
-- URL: https://raw.githubusercontent.com/BG-0o/Scripts/refs/heads/main/Combat.lua
-- ==============================================================================

local env = getgenv()

if env.ToxCombatLoaded then
    return
end
env.ToxCombatLoaded = true

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")

local Player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera or Workspace:FindFirstChildOfClass("Camera")
local Mouse = Player and Player:GetMouse()

local Settings = env.Settings or {}
local CombatPage = env.CombatPage or env.UniversalPage

local RegisterThemedObject = env.RegisterThemedObject or function() end
local Theme = env.Theme or {
    Accent = Color3.fromRGB(30, 95, 255),
    Panel = Color3.fromRGB(16, 16, 26),
    Element = Color3.fromRGB(22, 22, 34),
    Outline = Color3.fromRGB(36, 36, 56),
    Text = Color3.fromRGB(255, 255, 255),
    DimText = Color3.fromRGB(165, 165, 185),
    Risky = Color3.fromRGB(255, 55, 65)
}

-- Ensure Default Settings
Settings.Aimbot = Settings.Aimbot == true
Settings.AimbotMode = string.upper(tostring(Settings.AimbotMode or "CAMERA"))
if Settings.AimbotMode ~= "CAMERA" and Settings.AimbotMode ~= "MOUSE" then
    Settings.AimbotMode = "CAMERA"
end
Settings.AimbotSmoothnessEnabled = Settings.AimbotSmoothnessEnabled == true
Settings.AimbotSmoothness = tonumber(Settings.AimbotSmoothness) or 2
Settings.AimPart = Settings.AimPart or "Head"
Settings.AimWallCheck = Settings.AimWallCheck == true
Settings.ShowFOV = Settings.ShowFOV == true
Settings.FOVRadius = tonumber(Settings.FOVRadius) or 120
Settings.SilentAim = Settings.SilentAim == true
Settings.MagicBullet = Settings.MagicBullet == true
Settings.MagicBulletFOV = tonumber(Settings.MagicBulletFOV) or 120
Settings.MagicBulletFOVEnabled = Settings.MagicBulletFOVEnabled == true
Settings.Triggerbot = Settings.Triggerbot == true
Settings.TriggerbotDelay = tonumber(Settings.TriggerbotDelay) or 0.12
Settings.Spinbot = Settings.Spinbot == true
Settings.SpinSpeed = tonumber(Settings.SpinSpeed) or 50
Settings.HitboxExpander = Settings.HitboxExpander == true
Settings.HitboxSize = tonumber(Settings.HitboxSize) or 10
Settings.HeadHitboxExpander = Settings.HeadHitboxExpander == true
Settings.HeadHitboxSize = tonumber(Settings.HeadHitboxSize) or 7
Settings.KillAura = Settings.KillAura == true
Settings.KillAuraRange = tonumber(Settings.KillAuraRange) or 15
Settings.AimbotBindEnabled = Settings.AimbotBindEnabled == true
Settings.AimbotKey = Settings.AimbotKey or Enum.KeyCode.E
Settings.AimbotUseLeftClick = Settings.AimbotUseLeftClick == true
Settings.AimbotUseGuiInset = Settings.AimbotUseGuiInset == true
Settings.AimbotBlatant = Settings.AimbotBlatant == true
Settings.AimLock = Settings.AimLock == true
Settings.LockRadius = tonumber(Settings.LockRadius) or 110
Settings.AimTargets = tostring(Settings.AimTargets or "Players Only")
Settings.IgnoreFriends = Settings.IgnoreFriends == true

local function AutoSaveConfiguration()
    if env.AutoSaveConfiguration then
        pcall(env.AutoSaveConfiguration)
    end
end

-- ==============================================================================
-- HITBOX RESTORATION TABLES
-- ==============================================================================
local HitboxDefaults = {}
local HeadHitboxDefaults = {}

local function RestoreHitboxDefaults()
    for part, data in pairs(HitboxDefaults) do
        if part and part.Parent then
            pcall(function()
                part.Size = data.Size
                part.Transparency = data.Transparency
                part.CanCollide = data.CanCollide
                part.Massless = data.Massless
                if data.CustomPhysicalProperties then
                    part.CustomPhysicalProperties = data.CustomPhysicalProperties
                end
            end)
        end
    end
    table.clear(HitboxDefaults)
end

local function RestoreHeadHitboxDefaults()
    for part, data in pairs(HeadHitboxDefaults) do
        if part and part.Parent then
            pcall(function()
                part.Size = data.Size
                part.Transparency = data.Transparency
                part.CanCollide = data.CanCollide
                part.Massless = data.Massless
                if data.CustomPhysicalProperties then
                    part.CustomPhysicalProperties = data.CustomPhysicalProperties
                end
            end)
        end
    end
    table.clear(HeadHitboxDefaults)
end

getgenv().RestoreHitboxDefaults = RestoreHitboxDefaults
getgenv().RestoreHeadHitboxDefaults = RestoreHeadHitboxDefaults

-- ==============================================================================
-- FOV CIRCLE DRAWING
-- ==============================================================================
local FOVCircle = nil
if Drawing then
    pcall(function()
        FOVCircle = Drawing.new("Circle")
        FOVCircle.Thickness = 1.5
        FOVCircle.NumSides = 64
        FOVCircle.Radius = Settings.FOVRadius or 120
        FOVCircle.Filled = false
        FOVCircle.Visible = false
        FOVCircle.Color = Theme.Accent or Color3.fromRGB(30, 95, 255)
    end)
end

-- ==============================================================================
-- TARGETING HELPERS
-- ==============================================================================
local lockedTarget = nil
local aimbotBindHeld = false
local friendCache = {}
local connections = {}

local function IsFriend(otherPlayer)
    if not otherPlayer or otherPlayer == Player then return false end
    if friendCache[otherPlayer.UserId] ~= nil then
        return friendCache[otherPlayer.UserId]
    end
    local ok, res = pcall(function()
        return Player:IsFriendsWith(otherPlayer.UserId)
    end)
    friendCache[otherPlayer.UserId] = ok and res == true
    return friendCache[otherPlayer.UserId]
end

local function GetTargetPart(character, partName)
    if not character then return nil end
    partName = partName or Settings.AimPart or "Head"

    if partName == "Head" then
        return character:FindFirstChild("Head")
    elseif partName == "Torso" then
        return character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso") or character:FindFirstChild("HumanoidRootPart")
    else
        return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("Head")
    end
end

local function IsPartVisible(targetPart)
    if not targetPart then return false end
    if not Camera then Camera = Workspace.CurrentCamera end
    if not Camera then return false end

    local origin = Camera.CFrame.Position
    local targetPos = targetPart.Position
    local dir = targetPos - origin

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local filterList = {Player.Character, Camera}
    params.FilterDescendantsInstances = filterList
    params.IgnoreWater = true

    local result = Workspace:Raycast(origin, dir, params)
    if not result then return true end
    if result.Instance and result.Instance:IsDescendantOf(targetPart.Parent) then
        return true
    end
    return false
end

local function GetMousePos()
    local loc = UserInputService:GetMouseLocation()
    if Settings.AimbotUseGuiInset then
        local inset = GuiService:GetGuiInset()
        return Vector2.new(loc.X, loc.Y - inset.Y)
    end
    return Vector2.new(loc.X, loc.Y)
end

local function GetClosestTarget(maxRadius, partName)
    if not Camera then Camera = Workspace.CurrentCamera end
    if not Camera then return nil end

    local mousePos = GetMousePos()
    local shortestDist = maxRadius or (Settings.FOVRadius or 120)
    local bestPart = nil

    local checkPlayers = Settings.AimTargets ~= "NPCs Only"
    local checkNPCs = Settings.AimTargets == "NPCs Only" or Settings.AimTargets == "Players + NPCs"

    if checkPlayers then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= Player and p.Character then
                if not (Settings.IgnoreFriends and IsFriend(p)) then
                    local char = p.Character
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then
                        local part = GetTargetPart(char, partName)
                        if part then
                            local sPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                            if onScreen and sPos.Z > 0 then
                                if not Settings.AimWallCheck or IsPartVisible(part) then
                                    local dist = (Vector2.new(sPos.X, sPos.Y) - mousePos).Magnitude
                                    if dist < shortestDist then
                                        shortestDist = dist
                                        bestPart = part
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    if checkNPCs then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and not Players:GetPlayerFromCharacter(obj) then
                local hum = obj:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    local part = GetTargetPart(obj, partName)
                    if part then
                        local sPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                        if onScreen and sPos.Z > 0 then
                            if not Settings.AimWallCheck or IsPartVisible(part) then
                                local dist = (Vector2.new(sPos.X, sPos.Y) - mousePos).Magnitude
                                if dist < shortestDist then
                                    shortestDist = dist
                                    bestPart = part
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return bestPart
end

getgenv().GetClosestCombatTarget = GetClosestTarget

-- ==============================================================================
-- MAGIC BULLET HOOK (Safeguarded against breaking character physics / ground checks)
-- ==============================================================================
local hookInstalled = false
local function InstallMagicBulletHook()
    if hookInstalled then return end
    hookInstalled = true

    pcall(function()
        if typeof(hookmetamethod) == "function" then
            local oldNamecall
            oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
                local method = getnamecallmethod()

                if Settings.MagicBullet and not env.Destroyed then
                    local char = Player.Character
                    local tool = char and char:FindFirstChildOfClass("Tool")
                    if tool and Camera then
                        local isSafeCaller = true
                        if typeof(getcallingscript) == "function" then
                            local caller = getcallingscript()
                            if caller then
                                local cName = tostring(caller.Name):lower()
                                if cName:find("camera") or cName:find("popper") or cName:find("control") or cName:find("movement") or cName:find("animate") or cName:find("foot") or cName:find("character") then
                                    isSafeCaller = false
                                end
                            end
                        end

                        if isSafeCaller then
                            local args = {...}
                            local fov = Settings.MagicBulletFOVEnabled and Settings.MagicBulletFOV or 200

                            if method == "Raycast" and self == Workspace then
                                local origin = args[1]
                                local dir = args[2]

                                if typeof(origin) == "Vector3" and typeof(dir) == "Vector3" and dir.Magnitude >= 15 then
                                    local isDownwardFloorCheck = dir.Unit.Y < -0.75
                                    local rootPos = (char.PrimaryPart and char.PrimaryPart.Position) or Camera.CFrame.Position
                                    local distFromChar = (origin - rootPos).Magnitude

                                    if not isDownwardFloorCheck and distFromChar <= 50 then
                                        local target = GetClosestTarget(fov)
                                        if target then
                                            local newDir = (target.Position - origin).Unit * dir.Magnitude
                                            args[2] = newDir
                                            return oldNamecall(self, unpack(args))
                                        end
                                    end
                                end
                            elseif method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist" then
                                local r = args[1]
                                if typeof(r) == "Ray" and r.Direction.Magnitude >= 15 then
                                    local isDownwardFloorCheck = r.Direction.Unit.Y < -0.75
                                    local rootPos = (char.PrimaryPart and char.PrimaryPart.Position) or Camera.CFrame.Position
                                    local distFromChar = (r.Origin - rootPos).Magnitude

                                    if not isDownwardFloorCheck and distFromChar <= 50 then
                                        local target = GetClosestTarget(fov)
                                        if target then
                                            local newDir = (target.Position - r.Origin).Unit * r.Direction.Magnitude
                                            args[1] = Ray.new(r.Origin, newDir)
                                            return oldNamecall(self, unpack(args))
                                        end
                                    end
                                end
                            end
                        end
                    end
                end

                return oldNamecall(self, ...)
            end)
        end
    end)
end

InstallMagicBulletHook()

-- ==============================================================================
-- COMBAT MAIN LOOP (RenderStepped & Heartbeat)
-- ==============================================================================
local lastTriggerTime = 0
local spinAngle = 0

local combatConnection = RunService.RenderStepped:Connect(function(dt)
    if env.Destroyed then return end
    if not Camera then Camera = Workspace.CurrentCamera end
    if not Camera then return end

    local mousePos = GetMousePos()

    -- 1. FOV Circle Update
    if FOVCircle then
        if Settings.ShowFOV then
            FOVCircle.Position = mousePos
            FOVCircle.Radius = Settings.FOVRadius or 120
            FOVCircle.Color = Theme.Accent or Color3.fromRGB(30, 95, 255)
            FOVCircle.Visible = true
        else
            FOVCircle.Visible = false
        end
    end

    -- 2. Aimbot Logic
    local aimbotActive = false
    if Settings.Aimbot then
        if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            aimbotActive = true
        elseif Settings.AimbotUseLeftClick and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
            aimbotActive = true
        elseif Settings.AimbotBindEnabled and aimbotBindHeld then
            aimbotActive = true
        end
    end

    if aimbotActive then
        local targetPart = nil
        if Settings.AimLock and lockedTarget and lockedTarget.Parent and lockedTarget.Parent:FindFirstChildOfClass("Humanoid") and lockedTarget.Parent:FindFirstChildOfClass("Humanoid").Health > 0 then
            local sPos, onScreen = Camera:WorldToViewportPoint(lockedTarget.Position)
            if onScreen and (Vector2.new(sPos.X, sPos.Y) - mousePos).Magnitude <= (Settings.LockRadius or 110) then
                targetPart = lockedTarget
            end
        end

        if not targetPart then
            targetPart = GetClosestTarget(Settings.FOVRadius or 120)
            if Settings.AimLock then
                lockedTarget = targetPart
            end
        end

        if targetPart then
            if Settings.AimbotMode == "CAMERA" then
                local smooth = 1
                if not Settings.AimbotBlatant and Settings.AimbotSmoothnessEnabled then
                    smooth = math.max(1, tonumber(Settings.AimbotSmoothness) or 2)
                end
                local targetCFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)
                Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, 1 / smooth)
            elseif Settings.AimbotMode == "MOUSE" then
                local sPos = Camera:WorldToViewportPoint(targetPart.Position)
                local delta = Vector2.new(sPos.X, sPos.Y) - mousePos
                if typeof(mousemoverel) == "function" then
                    local smooth = (Settings.AimbotBlatant and 1) or (Settings.AimbotSmoothnessEnabled and (Settings.AimbotSmoothness or 2)) or 1
                    mousemoverel(delta.X / smooth, delta.Y / smooth)
                end
            end
        end
    else
        lockedTarget = nil
    end

    -- 3. Fixed Triggerbot
    if Settings.Triggerbot then
        local ray = Camera:ViewportPointToRay(mousePos.X, mousePos.Y)
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        local filterList = {Player.Character, Camera}
        params.FilterDescendantsInstances = filterList
        params.IgnoreWater = true

        local result = Workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
        if result and result.Instance then
            local model = result.Instance:FindFirstAncestorOfClass("Model")
            local targetPlayer = model and Players:GetPlayerFromCharacter(model)
            local isNPC = model and not targetPlayer and model:FindFirstChildOfClass("Humanoid")
            local isValidEnemy = false

            if targetPlayer and targetPlayer ~= Player then
                if not (Settings.IgnoreFriends and IsFriend(targetPlayer)) then
                    local hum = model:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then
                        isValidEnemy = true
                    end
                end
            elseif isNPC and (Settings.AimTargets == "NPCs Only" or Settings.AimTargets == "Players + NPCs") then
                local hum = model:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    isValidEnemy = true
                end
            end

            if isValidEnemy and (os.clock() - lastTriggerTime >= (Settings.TriggerbotDelay or 0.12)) then
                lastTriggerTime = os.clock()
                local tool = Player.Character and Player.Character:FindFirstChildOfClass("Tool")
                if tool then
                    tool:Activate()
                end
                if typeof(mouse1click) == "function" then
                    mouse1click()
                end
            end
        end
    end

    -- 4. Spinbot
    if Settings.Spinbot and Player.Character then
        local hrp = Player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local speed = tonumber(Settings.SpinSpeed) or 50
            spinAngle = (spinAngle + speed * dt * 10) % 360
            hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, math.rad(spinAngle), 0)
        end
    end

    -- 5. Normal Hitbox Expander (HumanoidRootPart / Torso)
    if Settings.HitboxExpander then
        local hbSize = tonumber(Settings.HitboxSize) or 10
        local heightLimit = math.min(hbSize, 3.5)
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= Player and p.Character then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    if not HitboxDefaults[hrp] then
                        HitboxDefaults[hrp] = {
                            Size = hrp.Size,
                            Transparency = hrp.Transparency,
                            CanCollide = hrp.CanCollide,
                            Massless = hrp.Massless,
                            CustomPhysicalProperties = hrp.CustomPhysicalProperties
                        }
                    end
                    hrp.Size = Vector3.new(hbSize, heightLimit, hbSize)
                    hrp.Transparency = 0.7
                    hrp.CanCollide = false
                    hrp.Massless = true
                    pcall(function()
                        hrp.CustomPhysicalProperties = PhysicalProperties.new(0.001, 0, 0, 0, 0)
                    end)
                end
            end
        end
    end

    -- 6. Head Hitbox Expander (Head specifically!)
    if Settings.HeadHitboxExpander then
        local headSize = tonumber(Settings.HeadHitboxSize) or 7
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= Player and p.Character then
                local head = p.Character:FindFirstChild("Head")
                if head then
                    if not HeadHitboxDefaults[head] then
                        HeadHitboxDefaults[head] = {
                            Size = head.Size,
                            Transparency = head.Transparency,
                            CanCollide = head.CanCollide,
                            Massless = head.Massless,
                            CustomPhysicalProperties = head.CustomPhysicalProperties
                        }
                    end
                    head.Size = Vector3.new(headSize, headSize, headSize)
                    head.Transparency = 0.5
                    head.CanCollide = false
                    head.Massless = true
                    pcall(function()
                        head.CustomPhysicalProperties = PhysicalProperties.new(0.001, 0, 0, 0, 0)
                    end)
                end
            end
        end
    end

    -- 7. Kill Aura
    if Settings.KillAura and Player.Character then
        local myHrp = Player.Character:FindFirstChild("HumanoidRootPart")
        if myHrp then
            local range = tonumber(Settings.KillAuraRange) or 15
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= Player and p.Character then
                    local tHrp = p.Character:FindFirstChild("HumanoidRootPart")
                    local tHum = p.Character:FindFirstChildOfClass("Humanoid")
                    if tHrp and tHum and tHum.Health > 0 then
                        if (myHrp.Position - tHrp.Position).Magnitude <= range then
                            local tool = Player.Character:FindFirstChildOfClass("Tool")
                            if tool then tool:Activate() end
                        end
                    end
                end
            end
        end
    end
end)

table.insert(connections, combatConnection)

-- Keybind Listener for Aimbot
local inputBegan = UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe or env.Destroyed then return end
    if Settings.AimbotBindEnabled and input.KeyCode == Settings.AimbotKey then
        aimbotBindHeld = true
    end
end)

local inputEnded = UserInputService.InputEnded:Connect(function(input, gpe)
    if env.Destroyed then return end
    if input.KeyCode == Settings.AimbotKey then
        aimbotBindHeld = false
    end
end)

table.insert(connections, inputBegan)
table.insert(connections, inputEnded)

-- ==============================================================================
-- COMBAT PAGE UI BUILDER
-- ==============================================================================
local function BuildCombatUI()
    if not CombatPage then
        CombatPage = env.CombatPage or env.UniversalPage
    end
    if not CombatPage then return end

    local CreateSection = env.CreateSection or function(p, t) return p end
    local CreateToggle = env.CreateToggle
    local CreateToggleWithValue = env.CreateToggleWithValue
    local CreateToggleWithChoice = env.CreateToggleWithChoice
    local CreateDropdown = env.CreateDropdown
    local CreateKeybindToggle = env.CreateKeybindToggle

    if type(CreateToggle) ~= "function" or type(CreateToggleWithValue) ~= "function" or type(CreateDropdown) ~= "function" then
        return
    end

    -- Card 1: Aimbot & Mira
    CreateSection(CombatPage, "Aimbot & Mira", "🎯")

    if type(CreateToggleWithChoice) == "function" then
        CreateToggleWithChoice("Aimbot", CombatPage, {"Camera", "Mouse"}, Settings.Aimbot, Settings.AimbotMode == "MOUSE" and "Mouse" or "Camera", function(v)
            Settings.Aimbot = v == true
            AutoSaveConfiguration()
        end, function(choice)
            Settings.AimbotMode = string.upper(tostring(choice or "Camera"))
            AutoSaveConfiguration()
        end, "Aimbot")
    else
        CreateToggle("Aimbot", CombatPage, Settings.Aimbot, function(v)
            Settings.Aimbot = v == true
            AutoSaveConfiguration()
        end, "Aimbot")
    end

    CreateToggleWithValue("Aim Smoothness", CombatPage, Settings.AimbotSmoothnessEnabled, Settings.AimbotSmoothness, function(v)
        Settings.AimbotSmoothnessEnabled = v == true
        AutoSaveConfiguration()
    end, function(val)
        Settings.AimbotSmoothness = tonumber(val) or 2
        AutoSaveConfiguration()
    end, "AimbotSmoothnessEnabled")

    CreateDropdown("Aim Part", {"Head", "HumanoidRootPart", "Torso"}, CombatPage, Settings.AimPart or "Head", function(v)
        Settings.AimPart = v
        AutoSaveConfiguration()
    end)

    CreateToggle("Aim Wall Check", CombatPage, Settings.AimWallCheck, function(v)
        Settings.AimWallCheck = v == true
        AutoSaveConfiguration()
    end, "AimWallCheck")

    CreateToggleWithValue("Show FOV Circle", CombatPage, Settings.ShowFOV, Settings.FOVRadius, function(v)
        Settings.ShowFOV = v == true
        AutoSaveConfiguration()
    end, function(val)
        Settings.FOVRadius = tonumber(val) or 120
        if FOVCircle then FOVCircle.Radius = Settings.FOVRadius end
        AutoSaveConfiguration()
    end, "ShowFOV")

    CreateToggleWithValue("Aim Lock", CombatPage, Settings.AimLock, Settings.LockRadius, function(v)
        Settings.AimLock = v == true
        if not v then lockedTarget = nil end
        AutoSaveConfiguration()
    end, function(val)
        Settings.LockRadius = tonumber(val) or 110
        AutoSaveConfiguration()
    end, "AimLock")

    CreateToggle("Blatant Aimbot", CombatPage, Settings.AimbotBlatant, function(v)
        Settings.AimbotBlatant = v == true
        AutoSaveConfiguration()
    end, "AimbotBlatant")

    if type(CreateKeybindToggle) == "function" then
        CreateKeybindToggle("Aimbot Bind", CombatPage, Settings.AimbotKey or Enum.KeyCode.E, Settings.AimbotBindEnabled, function(key)
            Settings.AimbotKey = key
            aimbotBindHeld = false
            AutoSaveConfiguration()
        end, function(v)
            Settings.AimbotBindEnabled = v == true
            if not v then aimbotBindHeld = false end
            AutoSaveConfiguration()
        end, "AimbotBindEnabled")
    end

    CreateToggle("Use Left Click", CombatPage, Settings.AimbotUseLeftClick, function(v)
        Settings.AimbotUseLeftClick = v == true
        AutoSaveConfiguration()
    end, "AimbotUseLeftClick")

    CreateToggle("Use Gui Inset", CombatPage, Settings.AimbotUseGuiInset, function(v)
        Settings.AimbotUseGuiInset = v == true
        AutoSaveConfiguration()
    end, "AimbotUseGuiInset")

    CreateDropdown("Aim Targets", {"Players Only", "NPCs Only", "Players + NPCs"}, CombatPage, Settings.AimTargets or "Players Only", function(v)
        Settings.AimTargets = tostring(v)
        lockedTarget = nil
        AutoSaveConfiguration()
    end)

    CreateToggle("Ignore Friends", CombatPage, Settings.IgnoreFriends, function(v)
        Settings.IgnoreFriends = v == true
        table.clear(friendCache)
        lockedTarget = nil
        AutoSaveConfiguration()
    end, "IgnoreFriends")

    -- Card 2: Assistência & Armas
    CreateSection(CombatPage, "Assistência & Armas", "⚡")

    CreateToggle("Silent Aim", CombatPage, Settings.SilentAim, function(v)
        Settings.SilentAim = v == true
        AutoSaveConfiguration()
    end, "SilentAim")

    CreateToggle("Magic Bullet", CombatPage, Settings.MagicBullet, function(v)
        Settings.MagicBullet = v == true
        AutoSaveConfiguration()
    end, "MagicBullet")

    CreateToggleWithValue("Magic Bullet FOV", CombatPage, Settings.MagicBulletFOVEnabled, Settings.MagicBulletFOV, function(v)
        Settings.MagicBulletFOVEnabled = v == true
        AutoSaveConfiguration()
    end, function(val)
        Settings.MagicBulletFOV = tonumber(val) or 120
        AutoSaveConfiguration()
    end, "MagicBulletFOV")

    CreateToggle("Triggerbot", CombatPage, Settings.Triggerbot, function(v)
        Settings.Triggerbot = v == true
        AutoSaveConfiguration()
    end, "Triggerbot")

    CreateToggleWithValue("Kill Aura", CombatPage, Settings.KillAura, Settings.KillAuraRange, function(v)
        Settings.KillAura = v == true
        AutoSaveConfiguration()
    end, function(val)
        Settings.KillAuraRange = tonumber(val) or 15
        AutoSaveConfiguration()
    end, "KillAura")

    CreateToggleWithValue("Spinbot", CombatPage, Settings.Spinbot, Settings.SpinSpeed, function(v)
        Settings.Spinbot = v == true
        AutoSaveConfiguration()
    end, function(val)
        Settings.SpinSpeed = tonumber(val) or 50
        AutoSaveConfiguration()
    end, "Spinbot")

    -- Card 3: Expansores de Hitbox
    CreateSection(CombatPage, "Expansores de Hitbox", "📦")

    CreateToggleWithValue("Hitbox Expander (Normal)", CombatPage, Settings.HitboxExpander, Settings.HitboxSize, function(v)
        Settings.HitboxExpander = v == true
        if not v then RestoreHitboxDefaults() end
        AutoSaveConfiguration()
    end, function(val)
        Settings.HitboxSize = tonumber(val) or 10
        AutoSaveConfiguration()
    end, "HitboxExpander")

    CreateToggleWithValue("Head Hitbox Expander", CombatPage, Settings.HeadHitboxExpander, Settings.HeadHitboxSize, function(v)
        Settings.HeadHitboxExpander = v == true
        if not v then RestoreHeadHitboxDefaults() end
        AutoSaveConfiguration()
    end, function(val)
        Settings.HeadHitboxSize = tonumber(val) or 7
        AutoSaveConfiguration()
    end, "HeadHitboxExpander")
end

BuildCombatUI()

-- Clean up on shutdown
local function CleanupCombat()
    for _, c in ipairs(connections) do
        pcall(function() c:Disconnect() end)
    end
    table.clear(connections)
    RestoreHitboxDefaults()
    RestoreHeadHitboxDefaults()
    if FOVCircle then
        pcall(function() FOVCircle:Remove() end)
    end
    env.ToxCombatLoaded = nil
end

getgenv().ToxCombatCleanup = CleanupCombat

