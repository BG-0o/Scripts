-- ==============================================================================
-- TOXHUB COMBAT ENGINE (Universal/Combat.lua)
-- Standalone Universal Combat Module
-- URL: https://raw.githubusercontent.com/BG-0o/Scripts/refs/heads/main/Universal/Combat.lua
-- ==============================================================================

local env = getgenv()

if env.ToxCombatConnections then
    for _, c in ipairs(env.ToxCombatConnections) do
        pcall(function() c:Disconnect() end)
    end
end
env.ToxCombatConnections = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")

local Player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera or Workspace:FindFirstChildOfClass("Camera")
local Mouse = Player and Player:GetMouse()

local function IsLocalPlayer(p)
    if not p then return true end
    if p == Player or p == Players.LocalPlayer then return true end
    local lp = Players.LocalPlayer or Player
    if lp then
        if p.UserId and lp.UserId and p.UserId == lp.UserId then return true end
        if p.Name and lp.Name and p.Name == lp.Name then return true end
    end
    return false
end

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
Settings.UltraInstinct = Settings.UltraInstinct == true
Settings.UltraInstinctRange = tonumber(Settings.UltraInstinctRange) or 14
Settings.AntiSocial = Settings.AntiSocial == true
Settings.AntiSocialRange = tonumber(Settings.AntiSocialRange) or 20
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
    local uid = otherPlayer.UserId
    if not uid then return false end
    if friendCache[uid] ~= nil then
        return friendCache[uid]
    end
    friendCache[uid] = false
    task.spawn(function()
        local ok, res = pcall(function()
            return Player and Player:IsFriendsWith(uid)
        end)
        if ok and res ~= nil then
            friendCache[uid] = (res == true)
        end
    end)
    return false
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
    local filterList = {}
    local char = Player and Player.Character
    if char then table.insert(filterList, char) end
    if Camera then table.insert(filterList, Camera) end
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
            if not IsLocalPlayer(p) and p.Character then
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
        for _, obj in ipairs(Workspace:GetChildren()) do
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
-- MAGIC BULLET HOOK (CRASH-PROOF, NON-RECURSIVE, ZERO-LAG METAMETHOD HOOK)
-- ==============================================================================
local hookInstalled = false
local currentMagicTarget = nil

local function InstallMagicBulletHook()
    if hookInstalled then return end
    hookInstalled = true

    pcall(function()
        if typeof(hookmetamethod) ~= "function" then return end

        local oldNamecall

        local hookHandler = function(self, ...)
            local method = getnamecallmethod and getnamecallmethod()

            -- 1. Exploit caller check: NEVER hook internal script calls (prevents recursion)
            if typeof(checkcaller) == "function" and checkcaller() then
                if typeof(setnamecallmethod) == "function" and method then
                    setnamecallmethod(method)
                end
                return oldNamecall(self, ...)
            end

            -- 2. Intercept Raycasts only when Magic Bullet or Silent Aim is enabled and target is valid
            if (Settings.MagicBullet or Settings.SilentAim) and not env.Destroyed and currentMagicTarget and currentMagicTarget.Parent then
                local target = currentMagicTarget
                local targetChar = target.Parent
                local targetHum = targetChar and targetChar:FindFirstChildOfClass("Humanoid")

                if targetHum and targetHum.Health > 0 then
                    local char = Player and Player.Character
                    local tool = char and char:FindFirstChildOfClass("Tool")

                    -- Must have a tool equipped
                    if tool and Camera then
                        -- Caller filter: ignore camera, popper, control and movement scripts
                        local isSafeCaller = true
                        if typeof(getcallingscript) == "function" then
                            local caller = getcallingscript()
                            if caller then
                                local cName = tostring(caller.Name):lower()
                                if cName:find("camera") or cName:find("popper") or cName:find("control")
                                or cName:find("player") or cName:find("movement") or cName:find("animate") then
                                    isSafeCaller = false
                                end
                            end
                        end

                        if isSafeCaller then
                            if method == "Raycast" and self == Workspace then
                                local origin, dir = ...
                                if typeof(origin) == "Vector3" and typeof(dir) == "Vector3" and dir.Magnitude >= 1.5 then
                                    -- Ignore downward ground checks and backward camera checks
                                    local isDownward = dir.Unit.Y < -0.8
                                    local isBehindCamera = dir:Dot(Camera.CFrame.LookVector) < -0.3
                                    if not isDownward and not isBehindCamera then
                                        local newDir = (target.Position - origin).Unit * dir.Magnitude
                                        if typeof(setnamecallmethod) == "function" then
                                            setnamecallmethod(method)
                                        end
                                        return oldNamecall(self, origin, newDir, select(3, ...))
                                    end
                                end
                            elseif method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" then
                                local r = ...
                                if typeof(r) == "Ray" and r.Direction.Magnitude >= 1.5 then
                                    local isDownward = r.Direction.Unit.Y < -0.8
                                    if not isDownward then
                                        local newDir = (target.Position - r.Origin).Unit * r.Direction.Magnitude
                                        local newRay = Ray.new(r.Origin, newDir)
                                        if typeof(setnamecallmethod) == "function" then
                                            setnamecallmethod(method)
                                        end
                                        return oldNamecall(self, newRay, select(2, ...))
                                    end
                                end
                            end
                        end
                    end
                end
            end

            -- Default pass-through (never double call oldNamecall!)
            if typeof(setnamecallmethod) == "function" and method then
                setnamecallmethod(method)
            end
            return oldNamecall(self, ...)
        end

        if typeof(newcclosure) == "function" then
            oldNamecall = hookmetamethod(game, "__namecall", newcclosure(hookHandler))
        else
            oldNamecall = hookmetamethod(game, "__namecall", hookHandler)
        end
    end)
end

-- Hook installed on demand when Magic Bullet or Silent Aim is enabled
if Settings.MagicBullet or Settings.SilentAim then
    InstallMagicBulletHook()
end

-- ==============================================================================
-- ULTRA INSTINCT (Safe Circular Proximity Evasion)
-- ==============================================================================
local lastUltraInstinctTime = 0

local function GetSafeUltraInstinctCFrame(myHrp, threatHrp, range)
    local myPos = myHrp.Position
    local threatPos = threatHrp.Position

    local threatDiff = myPos - threatPos
    local flatThreatDir = Vector3.new(threatDiff.X, 0, threatDiff.Z)
    if flatThreatDir.Magnitude < 0.1 then
        flatThreatDir = myHrp.CFrame.LookVector
    else
        flatThreatDir = flatThreatDir.Unit
    end

    -- Angles relative to the direction AWAY from the threat (0 = exactly the opposite side
    -- of where the player came from). Only if that spot is blocked (wall/void/water) it
    -- tries slightly to the sides, widening step by step. Never towards the threat.
    local testAngles = {
        0,
        20, -20,
        40, -40,
        60, -60,
        80, -80,
        100, -100,
    }

    -- Multiple candidate distance steps: ensure it finds safe ground even near ledges or inside rooms
    local baseDist = math.clamp(range + 4, 10, 35)
    local testDistances = {
        baseDist,
        math.clamp(range, 8, 25),
        math.clamp(range * 0.7, 6, 18),
        math.clamp(range * 0.5, 5, 12)
    }

    local fallenY = Workspace.FallenPartsDestroyHeight or -500

    -- Ignore list: MUST include ALL player characters in the server so other players/hats/accessories never count as solid walls
    local ignoreList = { Camera }
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then
            table.insert(ignoreList, p.Character)
        end
    end

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = ignoreList
    rayParams.IgnoreWater = false

    -- Direction first, distance second: prefer "straight away" even if it has to be a shorter hop
    for _, deg in ipairs(testAngles) do
        for _, dist in ipairs(testDistances) do
            local rad = math.rad(deg)
            local cosA = math.cos(rad)
            local sinA = math.sin(rad)
            local dir = Vector3.new(
                flatThreatDir.X * cosA - flatThreatDir.Z * sinA,
                0,
                flatThreatDir.X * sinA + flatThreatDir.Z * cosA
            ).Unit

            local candPos = myPos + (dir * dist)

            -- 1. Horizontal obstacle check: only block if there's a real wall at chest/head level
            local chestOrigin = myPos + Vector3.new(0, 2.5, 0)
            local horizHit = Workspace:Raycast(chestOrigin, dir * dist, rayParams)
            local isWall = false
            if horizHit and horizHit.Instance and horizHit.Instance.CanCollide then
                -- Must be a high obstruction, not a tiny floor bump
                if horizHit.Position.Y > (myPos.Y + 1.2) then
                    isWall = true
                end
            end

            if not isWall then
                -- 2. Downward floor check: verify solid non-hazard floor
                local floorOrigin = candPos + Vector3.new(0, 5, 0)
                local floorHit = Workspace:Raycast(floorOrigin, Vector3.new(0, -45, 0), rayParams)

                if floorHit and floorHit.Instance then
                    local hitInst = floorHit.Instance
                    local isWater = false

                    if hitInst:IsA("Terrain") then
                        if floorHit.Material == Enum.Material.Water then
                            isWater = true
                        end
                    elseif string.find(string.lower(hitInst.Name), "water") then
                        isWater = true
                    end

                    if not isWater then
                        local pName = string.lower(hitInst.Name)
                        local isHazard = string.find(pName, "lava")
                            or string.find(pName, "acid")
                            or string.find(pName, "kill")
                            or string.find(pName, "damage")
                            or string.find(pName, "death")
                            or string.find(pName, "void")
                            or string.find(pName, "fire")

                        local isSolidFloor = false
                        if hitInst:IsA("Terrain") then
                            isSolidFloor = true
                        elseif hitInst:IsA("BasePart") then
                            if hitInst.CanCollide or hitInst.Transparency < 0.85 then
                                isSolidFloor = true
                            end
                        end

                        if not isHazard and isSolidFloor and floorHit.Position.Y > (fallenY + 25) then
                            -- Safe floor confirmed!
                            local safeY = floorHit.Position.Y + 3.2
                            local safeTargetPos = Vector3.new(candPos.X, safeY, candPos.Z)
                            local faceRot = CFrame.lookAt(safeTargetPos, Vector3.new(threatPos.X, safeTargetPos.Y, threatPos.Z))
                            return faceRot
                        end
                    end
                end
            end
        end
    end

    -- No safe spot found (surrounded by void or walls); abort teleport to prevent dying
    return nil
end
getgenv().GetSafeUltraInstinctCFrame = GetSafeUltraInstinctCFrame

-- Ground circle visual (shows the detection radius under the player)
local UICircleRing = nil
local UICircleFill = nil

local function GetUICircleParent()
    local ok, hui = pcall(function()
        return (typeof(gethui) == "function") and gethui() or nil
    end)
    if ok and hui then return hui end
    local okCore, core = pcall(function() return game:GetService("CoreGui") end)
    if okCore and core then return core end
    return Workspace.CurrentCamera or Camera
end

local function EnsureUltraInstinctCircle()
    if UICircleRing and UICircleRing.Parent and UICircleFill and UICircleFill.Parent then
        return true
    end
    local ok = pcall(function()
        local parent = GetUICircleParent()

        UICircleRing = Instance.new("CylinderHandleAdornment")
        UICircleRing.Name = "ToxUltraInstinctRing"
        UICircleRing.Height = 0.12
        UICircleRing.AlwaysOnTop = false
        UICircleRing.ZIndex = 1
        UICircleRing.Transparency = 0.15
        UICircleRing.Adornee = Workspace.Terrain
        UICircleRing.Visible = false
        UICircleRing.Parent = parent

        UICircleFill = Instance.new("CylinderHandleAdornment")
        UICircleFill.Name = "ToxUltraInstinctFill"
        UICircleFill.Height = 0.06
        UICircleFill.AlwaysOnTop = false
        UICircleFill.ZIndex = 0
        UICircleFill.Transparency = 0.82
        UICircleFill.Adornee = Workspace.Terrain
        UICircleFill.Visible = false
        UICircleFill.Parent = parent
    end)
    return ok and UICircleRing ~= nil
end

local function HideUltraInstinctCircle()
    if UICircleRing then pcall(function() UICircleRing.Visible = false end) end
    if UICircleFill then pcall(function() UICircleFill.Visible = false end) end
end

local function DestroyUltraInstinctCircle()
    if UICircleRing then pcall(function() UICircleRing:Destroy() end) end
    if UICircleFill then pcall(function() UICircleFill:Destroy() end) end
    UICircleRing, UICircleFill = nil, nil
end

local function UpdateUltraInstinctCircle(character, myHrp, myHum, range, threatInside)
    if not EnsureUltraInstinctCircle() then return end

    -- Find the ground under the player (fallback: estimated foot height)
    local footY = myHrp.Position.Y - (myHrp.Size.Y / 2) - (myHum.HipHeight or 2)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { character, Camera }
    params.IgnoreWater = false
    local hit = Workspace:Raycast(myHrp.Position, Vector3.new(0, -12, 0), params)
    if hit then footY = hit.Position.Y end

    local center = Vector3.new(myHrp.Position.X, footY + 0.08, myHrp.Position.Z)
    -- Cylinder adornments extend along Z; rotate so they lie flat on the floor
    local cf = CFrame.new(center) * CFrame.Angles(math.rad(90), 0, 0)
    local color = threatInside and Color3.fromRGB(255, 60, 70) or (Theme.Accent or Color3.fromRGB(30, 95, 255))

    UICircleRing.CFrame = cf
    UICircleRing.Radius = range
    UICircleRing.InnerRadius = math.max(range - 0.35, 0)
    UICircleRing.Color3 = color
    UICircleRing.Visible = true

    UICircleFill.CFrame = cf
    UICircleFill.Radius = range
    UICircleFill.InnerRadius = 0
    UICircleFill.Color3 = color
    UICircleFill.Visible = true
end

local function UltraInstinctStep()
    local character = Player and Player.Character
    if not Settings.UltraInstinct or not character then
        HideUltraInstinctCircle()
        return
    end

    local myHrp = character:FindFirstChild("HumanoidRootPart")
    local myHum = character:FindFirstChildOfClass("Humanoid")
    if not myHrp or not myHum or myHum.Health <= 0 then
        HideUltraInstinctCircle()
        return
    end

    local detectRange = tonumber(Settings.UltraInstinctRange) or 14
    local closestThreat = nil
    local closestDist = detectRange

    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if not IsLocalPlayer(otherPlayer) and otherPlayer.Character then
            local otherHrp = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
            local otherHum = otherPlayer.Character:FindFirstChildOfClass("Humanoid")
            if otherHrp and otherHum and otherHum.Health > 0 then
                -- Flat (XZ) distance so it matches the circle drawn on the ground
                local diff = otherHrp.Position - myHrp.Position
                local dist = Vector3.new(diff.X, 0, diff.Z).Magnitude
                if dist <= closestDist and math.abs(diff.Y) <= detectRange then
                    closestDist = dist
                    closestThreat = otherHrp
                end
            end
        end
    end

    pcall(UpdateUltraInstinctCircle, character, myHrp, myHum, detectRange, closestThreat ~= nil)

    if not closestThreat then return end

    -- Shared cooldown so Combat + game modules (e.g. NDS) never double-teleport
    local lastTime = tonumber(getgenv().ToxLastUltraInstinctTime) or 0
    if os.clock() - math.max(lastTime, lastUltraInstinctTime) < 0.18 then return end

    local safeCFrame = GetSafeUltraInstinctCFrame(myHrp, closestThreat, detectRange)
    if not safeCFrame then return end

    lastUltraInstinctTime = os.clock()
    getgenv().ToxLastUltraInstinctTime = lastUltraInstinctTime

    if getgenv().AllowToxTeleport then
        getgenv().AllowToxTeleport(1.0, "Ultra Instinct")
    end
    if getgenv().SetNDSNoTPAnchor then
        pcall(getgenv().SetNDSNoTPAnchor, safeCFrame, true)
    end

    myHrp.AssemblyLinearVelocity = Vector3.zero
    myHrp.AssemblyAngularVelocity = Vector3.zero
    character:PivotTo(safeCFrame)

    pcall(function()
        local s = Instance.new("Sound")
        s.SoundId = "rbxassetid://3398620867"
        s.Volume = 0.5
        s.Parent = myHrp
        s:Play()
        game:GetService("Debris"):AddItem(s, 1)
    end)
end
getgenv().ToxUltraInstinctStep = UltraInstinctStep

-- ==============================================================================
-- ANTI SOCIAL: WALKS (no teleport) away from every player inside the range.
-- Runs right after the default control script so it overrides WASD while someone
-- is close; with nobody in range you move normally.
-- ==============================================================================
local ANTISOCIAL_BIND = "ToxAntiSocial"

local function AntiSocialStep()
    if env.Destroyed or not Settings.AntiSocial then
        return
    end
    local character = Player and Player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root or humanoid.Health <= 0 then
        return
    end

    local range = math.max(tonumber(Settings.AntiSocialRange) or 20, 1)
    local myPos = root.Position
    local away = Vector3.zero

    for _, other in ipairs(Players:GetPlayers()) do
        if not IsLocalPlayer(other) and other.Character
        and not (Settings.IgnoreFriends and IsFriend(other)) then
            local otherRoot = other.Character:FindFirstChild("HumanoidRootPart")
            local otherHum = other.Character:FindFirstChildOfClass("Humanoid")
            if otherRoot and otherHum and otherHum.Health > 0 then
                local diff = myPos - otherRoot.Position
                local flat = Vector3.new(diff.X, 0, diff.Z)
                local dist = flat.Magnitude
                if dist < range and math.abs(diff.Y) < range then
                    if dist < 0.05 then
                        flat = root.CFrame.LookVector
                        dist = 0.05
                    end
                    -- closer players push harder
                    away = away + flat.Unit * ((range - dist) / range + 0.1)
                end
            end
        end
    end

    if away.Magnitude <= 0.01 then
        return
    end

    -- Edge check: only walk where there is ground ahead (otherwise it walked into the void).
    -- Tries the ideal direction first, then turns gradually (never back towards players).
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { character, Camera }
    params.IgnoreWater = false

    local standOffset = 3
    if humanoid.RigType == Enum.HumanoidRigType.R15 then
        standOffset = humanoid.HipHeight + root.Size.Y / 2
    end
    local feetY = myPos.Y - standOffset
    local fallenY = Workspace.FallenPartsDestroyHeight or -500

    local function HasGround(dir)
        for _, ahead in ipairs({ 2.5, 5 }) do
            local origin = myPos + dir * ahead
            local hit = Workspace:Raycast(origin, Vector3.new(0, -(standOffset + 10), 0), params)
            if not hit then
                return false
            end
            -- deep water / drop of more than ~8 studs counts as unsafe
            if hit.Material == Enum.Material.Water or hit.Position.Y < feetY - 8 or hit.Position.Y < fallenY + 20 then
                return false
            end
        end
        return true
    end

    local base = Vector3.new(away.X, 0, away.Z).Unit
    local chosen = nil
    for _, deg in ipairs({ 0, 30, -30, 60, -60, 90, -90 }) do
        local dir = (CFrame.Angles(0, math.rad(deg), 0) * CFrame.new(base)).Position
        dir = Vector3.new(dir.X, 0, dir.Z)
        if dir.Magnitude > 0.01 then
            dir = dir.Unit
            if HasGround(dir) then
                chosen = dir
                break
            end
        end
    end

    pcall(function()
        if chosen then
            humanoid:Move(chosen, false)
        else
            humanoid:Move(Vector3.zero, false)   -- cornered at an edge: stay put
        end
    end)
end

pcall(function() RunService:UnbindFromRenderStep(ANTISOCIAL_BIND) end)
RunService:BindToRenderStep(ANTISOCIAL_BIND, Enum.RenderPriority.Input.Value + 1, function()
    pcall(AntiSocialStep)
end)

-- ==============================================================================
-- COMBAT MAIN LOOP (RenderStepped & Heartbeat)
-- ==============================================================================
local lastTriggerTime = 0
local lastKillAuraTime = 0
local KILL_AURA_INTERVAL = 0.12   -- max ~8 swings/s (was every frame, per player)
local spinAngle = 0

local combatConnection = RunService.RenderStepped:Connect(function(dt)
    if env.Destroyed or not env.ScriptLoaded then return end
    if not Camera then Camera = Workspace.CurrentCamera end
    if not Camera then return end

    -- Pre-cache Magic Bullet / Silent Aim target without running heavy Raycast inside __namecall!
    if Settings.MagicBullet or Settings.SilentAim then
        local mbFov = (Settings.MagicBullet and Settings.MagicBulletFOVEnabled and Settings.MagicBulletFOV)
            or (Settings.SilentAim and Settings.SilentAimFOVEnabled and Settings.SilentAimFOV)
            or 300
        currentMagicTarget = GetClosestTarget(mbFov)
    else
        currentMagicTarget = nil
    end

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
    local currentCombatTargetPart = nil
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
            currentCombatTargetPart = targetPart
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

    -- Update Global Target for Target ESP
    local activeTargetPart = currentCombatTargetPart or currentMagicTarget
    if not activeTargetPart and Settings.TargetESP then
        activeTargetPart = GetClosestTarget(Settings.FOVRadius or 120)
    end
    if activeTargetPart and activeTargetPart.Parent then
        getgenv().ToxCurrentTarget = activeTargetPart.Parent
    else
        getgenv().ToxCurrentTarget = nil
    end

    -- 3. Fixed Triggerbot
    if Settings.Triggerbot then
        local ray = Camera:ViewportPointToRay(mousePos.X, mousePos.Y)
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        local filterList = {}
        local char = Player and Player.Character
        if char then table.insert(filterList, char) end
        if Camera then table.insert(filterList, Camera) end
        params.FilterDescendantsInstances = filterList
        params.IgnoreWater = true

        local result = Workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
        if result and result.Instance then
            local model = result.Instance:FindFirstAncestorOfClass("Model")
            local targetPlayer = model and Players:GetPlayerFromCharacter(model)
            local isNPC = model and not targetPlayer and model:FindFirstChildOfClass("Humanoid")
            local isValidEnemy = false

            if targetPlayer and not IsLocalPlayer(targetPlayer) then
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
                local tool = Player and Player.Character and Player.Character:FindFirstChildOfClass("Tool")
                if tool then
                    pcall(function() tool:Activate() end)
                end
                if typeof(mouse1click) == "function" then
                    pcall(mouse1click)
                end
            end
        end
    end

    -- 4. Spinbot
    if Settings.Spinbot and Player and Player.Character then
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
            if not IsLocalPlayer(p) and p.Character then
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
            if not IsLocalPlayer(p) and p.Character then
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
    if Settings.KillAura and Player and Player.Character then
        local myHrp = Player.Character:FindFirstChild("HumanoidRootPart")
        if myHrp then
            local range = tonumber(Settings.KillAuraRange) or 15
            -- One swing per interval if ANY valid target is in range
            -- (before: tool:Activate() every frame for every player in range)
            if os.clock() - lastKillAuraTime >= KILL_AURA_INTERVAL then
                local hasTarget = false
                for _, p in ipairs(Players:GetPlayers()) do
                    if not IsLocalPlayer(p) and p.Character
                    and not (Settings.IgnoreFriends and IsFriend and IsFriend(p)) then
                        local tHrp = p.Character:FindFirstChild("HumanoidRootPart")
                        local tHum = p.Character:FindFirstChildOfClass("Humanoid")
                        if tHrp and tHum and tHum.Health > 0
                        and (myHrp.Position - tHrp.Position).Magnitude <= range then
                            hasTarget = true
                            break
                        end
                    end
                end
                if hasTarget then
                    local tool = Player.Character:FindFirstChildOfClass("Tool")
                    if tool then
                        lastKillAuraTime = os.clock()
                        pcall(function() tool:Activate() end)
                    end
                end
            end
        end
    end

    -- 8. Ultra Instinct (Safe Proximity Teleport Evasion + ground circle)
    local okUI, errUI = pcall(UltraInstinctStep)
    if not okUI and not env.ToxUIErrorWarned then
        env.ToxUIErrorWarned = true
        warn("[ToxHub] Ultra Instinct error: " .. tostring(errUI))
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
        CombatPage = env.CombatPage or env.UniversalPage or (env.Pages and env.Pages["UNIVERSAL_COMBAT"])
    end
    if not CombatPage then return end

    for _, child in ipairs(CombatPage:GetChildren()) do
        if child:IsA("GuiObject") then
            pcall(function() child:Destroy() end)
        end
    end

    local CreateSection = env.CreateSection or getgenv().CreateSection or function(p, t) return p end
    local CreateToggle = env.CreateToggle or getgenv().CreateToggle
    local CreateToggleWithValue = env.CreateToggleWithValue or getgenv().CreateToggleWithValue
    local CreateToggleWithChoice = env.CreateToggleWithChoice or getgenv().CreateToggleWithChoice
    local CreateToggleWithSlider = env.CreateToggleWithSlider or getgenv().CreateToggleWithSlider
    local CreateDropdown = env.CreateDropdown or getgenv().CreateDropdown
    local CreateKeybindToggle = env.CreateKeybindToggle or getgenv().CreateKeybindToggle

    if type(CreateToggle) ~= "function" or type(CreateToggleWithValue) ~= "function" or type(CreateDropdown) ~= "function" then
        return
    end

    -- Card 1: Aimbot & Aiming
    CreateSection(CombatPage, "Aimbot & Aiming", "🎯")

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

    if type(CreateToggleWithSlider) == "function" then
        CreateToggleWithSlider("Aim Smoothness", CombatPage, 1, 20, Settings.AimbotSmoothnessEnabled, Settings.AimbotSmoothness or 2, "x", function(v)
            Settings.AimbotSmoothnessEnabled = v == true
            AutoSaveConfiguration()
        end, function(val)
            Settings.AimbotSmoothness = tonumber(val) or 2
            AutoSaveConfiguration()
        end, "AimbotSmoothnessEnabled")
    else
        CreateToggleWithValue("Aim Smoothness", CombatPage, Settings.AimbotSmoothnessEnabled, Settings.AimbotSmoothness, function(v)
            Settings.AimbotSmoothnessEnabled = v == true
            AutoSaveConfiguration()
        end, function(val)
            Settings.AimbotSmoothness = tonumber(val) or 2
            AutoSaveConfiguration()
        end, "AimbotSmoothnessEnabled")
    end

    CreateDropdown("Aim Part", {"Head", "HumanoidRootPart", "Torso"}, CombatPage, Settings.AimPart or "Head", function(v)
        Settings.AimPart = v
        AutoSaveConfiguration()
    end)

    CreateToggle("Aim Wall Check", CombatPage, Settings.AimWallCheck, function(v)
        Settings.AimWallCheck = v == true
        AutoSaveConfiguration()
    end, "AimWallCheck")

    if type(CreateToggleWithSlider) == "function" then
        CreateToggleWithSlider("Show FOV Circle", CombatPage, 30, 400, Settings.ShowFOV, Settings.FOVRadius or 120, "px", function(v)
            Settings.ShowFOV = v == true
            AutoSaveConfiguration()
        end, function(val)
            Settings.FOVRadius = tonumber(val) or 120
            if FOVCircle then FOVCircle.Radius = Settings.FOVRadius end
            AutoSaveConfiguration()
        end, "ShowFOV")

        CreateToggleWithSlider("Aim Lock", CombatPage, 30, 300, Settings.AimLock, Settings.LockRadius or 110, "px", function(v)
            Settings.AimLock = v == true
            if not v then lockedTarget = nil end
            AutoSaveConfiguration()
        end, function(val)
            Settings.LockRadius = tonumber(val) or 110
            AutoSaveConfiguration()
        end, "AimLock")
    else
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
    end

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

    -- Card 2: Combat Assistance
    CreateSection(CombatPage, "Combat Assistance", "⚡")

    CreateToggle("Silent Aim", CombatPage, Settings.SilentAim, function(v)
        Settings.SilentAim = v == true
        AutoSaveConfiguration()
    end, "SilentAim")

    CreateToggle("Magic Bullet", CombatPage, Settings.MagicBullet, function(v)
        Settings.MagicBullet = v == true
        if v then
            InstallMagicBulletHook()
        end
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

    if type(CreateToggleWithSlider) == "function" then
        CreateToggleWithSlider("Kill Aura", CombatPage, 5, 30, Settings.KillAura, Settings.KillAuraRange or 15, " studs", function(v)
            Settings.KillAura = v == true
            AutoSaveConfiguration()
        end, function(val)
            Settings.KillAuraRange = tonumber(val) or 15
            AutoSaveConfiguration()
        end, "KillAura")

        CreateToggleWithSlider("Spinbot", CombatPage, 10, 100, Settings.Spinbot, Settings.SpinSpeed or 50, "°/s", function(v)
            Settings.Spinbot = v == true
            AutoSaveConfiguration()
        end, function(val)
            Settings.SpinSpeed = tonumber(val) or 50
            AutoSaveConfiguration()
        end, "Spinbot")
    else
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
    end

    -- Card 3: Hitbox Expanders
    CreateSection(CombatPage, "Hitbox Expanders", "📦")

    if type(CreateToggleWithSlider) == "function" then
        CreateToggleWithSlider("Hitbox Expander", CombatPage, 2, 40, Settings.HitboxExpander, Settings.HitboxSize or 10, " studs", function(v)
            Settings.HitboxExpander = v == true
            if not v then RestoreHitboxDefaults() end
            AutoSaveConfiguration()
        end, function(val)
            Settings.HitboxSize = tonumber(val) or 10
            AutoSaveConfiguration()
        end, "HitboxExpander")

        CreateToggleWithSlider("Head Hitbox Expander", CombatPage, 2, 25, Settings.HeadHitboxExpander, Settings.HeadHitboxSize or 7, " studs", function(v)
            Settings.HeadHitboxExpander = v == true
            if not v then RestoreHeadHitboxDefaults() end
            AutoSaveConfiguration()
        end, function(val)
            Settings.HeadHitboxSize = tonumber(val) or 7
            AutoSaveConfiguration()
        end, "HeadHitboxExpander")
    else
        CreateToggleWithValue("Hitbox Expander", CombatPage, Settings.HitboxExpander, Settings.HitboxSize, function(v)
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

    -- Card 4: Evasion & Defense
    CreateSection(CombatPage, "Evasion & Defense", "⚡")

    if type(CreateToggleWithSlider) == "function" then
        CreateToggleWithSlider("Ultra Instinct", CombatPage, 5, 50, Settings.UltraInstinct, Settings.UltraInstinctRange or 14, " studs", function(v)
            Settings.UltraInstinct = v == true
            if not Settings.UltraInstinct then HideUltraInstinctCircle() end
            AutoSaveConfiguration()
        end, function(val)
            Settings.UltraInstinctRange = tonumber(val) or 14
            AutoSaveConfiguration()
        end, "UltraInstinct")
    else
        CreateToggleWithValue("Ultra Instinct", CombatPage, Settings.UltraInstinct, Settings.UltraInstinctRange, function(v)
            Settings.UltraInstinct = v == true
            if not Settings.UltraInstinct then HideUltraInstinctCircle() end
            AutoSaveConfiguration()
        end, function(val)
            Settings.UltraInstinctRange = tonumber(val) or 14
            AutoSaveConfiguration()
        end, "UltraInstinct")
    end

    -- Anti Social: walk away from nearby players (below Ultra Instinct)
    local function OnAntiSocial(v)
        Settings.AntiSocial = v == true
        AutoSaveConfiguration()
    end
    local function OnAntiSocialRange(val)
        Settings.AntiSocialRange = tonumber(val) or 20
        if getgenv().SyncValueVisuals then
            getgenv().SyncValueVisuals("AntiSocial", Settings.AntiSocialRange)
        end
        AutoSaveConfiguration()
    end
    if type(CreateToggleWithSlider) == "function" then
        CreateToggleWithSlider("Anti Social", CombatPage, 5, 60, Settings.AntiSocial, Settings.AntiSocialRange or 20, " studs", OnAntiSocial, OnAntiSocialRange, "AntiSocial")
    else
        CreateToggleWithValue("Anti Social", CombatPage, Settings.AntiSocial, Settings.AntiSocialRange, OnAntiSocial, OnAntiSocialRange, "AntiSocial")
    end

    if type(env.ClearActivePageCard) == "function" then
        pcall(env.ClearActivePageCard, CombatPage)
    end
end

BuildCombatUI()
env.ToxCombatLoaded = true
getgenv().ToxCombatLoaded = true

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
    DestroyUltraInstinctCircle()
    pcall(function() RunService:UnbindFromRenderStep(ANTISOCIAL_BIND) end)
    env.ToxCombatLoaded = nil
end

getgenv().ToxCombatCleanup = CleanupCombat

