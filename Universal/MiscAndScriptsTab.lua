local env = getgenv()
if env.Destroyed or env.ToxUniversalLoaded then
    return
end
env.ToxUniversal = env.ToxUniversal or {}
local U = env.ToxUniversal
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Player = Players.LocalPlayer
local Settings = env.Settings or {}
local FlingPage = env.FlingPage
local ScriptsPage = env.ScriptsPage
local MusicGui = env.MusicGui
local WaypointsGui = env.WaypointsGui
local CreateToggle = env.CreateToggle
local CreateButton = env.CreateButton
local CreateInputWithTwoButtons = env.CreateInputWithTwoButtons
local CreateToggleCycleOption = U.CreateToggleCycleOption or env.CreateToggleCycleOption
local BeginUniversalSection = env.BeginUniversalSection or function() end
local function CustomNotify(...) if env.CustomNotify then return env.CustomNotify(...) end end
local function AddConnection(...) if env.AddConnection then return env.AddConnection(...) end end
local CaptureShiftLockDefaults = U.CaptureShiftLockDefaults or function() end
local RestoreShiftLockDefaults = U.RestoreShiftLockDefaults or function() end
local ExecuteFling = U.ExecuteFling or function() end
local ExecuteTeleport = U.ExecuteTeleport or function() end
BeginUniversalSection("Misc")
CreateToggle("Ctrl Click TP", FlingPage, Settings.CtrlClickTP, function(v)
    if getgenv().ToxSetSharedOption then getgenv().ToxSetSharedOption("CtrlClickTP", v) end
end, "CtrlClickTP")
local toggleWithSlider = CreateToggleWithSlider or (getgenv and getgenv().CreateToggleWithSlider)
if toggleWithSlider then
    local walkFlingControl = toggleWithSlider("Walk Fling", FlingPage, 1, 100, Settings.WalkFling, Settings.WalkFlingPower or 30, "%", function(v)
        if getgenv().ToxSetSharedOption then
            getgenv().ToxSetSharedOption("WalkFling", v)
        else
            Settings.WalkFling = v
        end
    end, function(val)
        Settings.WalkFlingPower = tonumber(val) or 30
        if getgenv().ToxOnSharedValueChanged then
            getgenv().ToxOnSharedValueChanged("WalkFling", val)
        end
    end, "WalkFling")
    if env.TrackUniversalControl then pcall(env.TrackUniversalControl, walkFlingControl, FlingPage) end
else
    CreateToggleWithValue("Walk Fling", FlingPage, Settings.WalkFling, Settings.WalkFlingPower or 30, function(v)
        if getgenv().ToxSetSharedOption then
            getgenv().ToxSetSharedOption("WalkFling", v)
        else
            Settings.WalkFling = v
        end
    end, function(val)
        Settings.WalkFlingPower = tonumber(val) or 30
        if getgenv().ToxOnSharedValueChanged then
            getgenv().ToxOnSharedValueChanged("WalkFling", val)
        end
    end, "WalkFling")
end
if toggleWithSlider then
    local control = toggleWithSlider("No Fall Damage", FlingPage, 0, 100, Settings.NoFallDamage, Settings.NoFallSpeed or 50, "%", function(v)
        if getgenv().ToxSetSharedOption then getgenv().ToxSetSharedOption("NoFallDamage", v) end
    end, function(val)
        Settings.NoFallSpeed = math.clamp(tonumber(val) or 50, 0, 100)
        if getgenv().SyncValueVisuals then
            getgenv().SyncValueVisuals("NoFallDamage", Settings.NoFallSpeed)
        end
    end, "NoFallDamage")
    if env.TrackUniversalControl then pcall(env.TrackUniversalControl, control, FlingPage) end
else
    CreateToggle("No Fall Damage", FlingPage, Settings.NoFallDamage, function(v)
        if getgenv().ToxSetSharedOption then getgenv().ToxSetSharedOption("NoFallDamage", v) end
    end, "NoFallDamage")
end
CreateToggle("Anti Void", FlingPage, Settings.AntiVoid, function(v)
    if getgenv().ToxSetSharedOption then getgenv().ToxSetSharedOption("AntiVoid", v) end
end, "AntiVoid")
CreateToggle("Anti Fling", FlingPage, Settings.AntiFling, function(v)
    if getgenv().ToxSetSharedOption then getgenv().ToxSetSharedOption("AntiFling", v) end
end, "AntiFling")
CreateToggle("Instant Proximity Prompts", FlingPage, Settings.InstantPrompts == true, function(v)
    Settings.InstantPrompts = v
    if v then
        for _, prompt in ipairs(workspace:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") then
                prompt.HoldDuration = 0
            end
        end
    end
end, "InstantPrompts")
AddConnection(workspace.DescendantAdded:Connect(function(desc)
    if Settings.InstantPrompts and not getgenv().Destroyed and desc:IsA("ProximityPrompt") then
        desc.HoldDuration = 0
    end
end))
CreateToggle("Tool Magnet", FlingPage, Settings.ToolMagnet == true, function(v)
    Settings.ToolMagnet = v
    if v then
        task.spawn(function()
            while Settings.ToolMagnet and not getgenv().Destroyed do
                local char = Player.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    for _, item in ipairs(workspace:GetChildren()) do
                        if item:IsA("BackpackItem") or item:IsA("Tool") then
                            local handle = item:FindFirstChild("Handle")
                            if handle then
                                handle.CFrame = hrp.CFrame
                            end
                        end
                    end
                end
                task.wait(0.5)
            end
        end)
    end
end, "ToolMagnet")
CreateToggleCycleOption(
    "Force Shift Lock",
    FlingPage,
    Settings.ForceShiftLock,
    {"Shift", "Ctrl"},
    Settings.ShiftLockKey or "Shift",
    function(v)
        if v then
            CaptureShiftLockDefaults()
        end
        Settings.ForceShiftLock = v == true
        if not Settings.ForceShiftLock then
            if U.SetShiftLockActive then U.SetShiftLockActive(false) end
            RestoreShiftLockDefaults()
        end
    end,
    function(v)
        Settings.ShiftLockKey = v == "Ctrl" and "Ctrl" or "Shift"
        if U.SetShiftLockActive then U.SetShiftLockActive(false) end
        if Settings.ForceShiftLock then
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        end
    end
)
U.LoopFlingInput = nil
U.LoopFlingGeneration = 0
local function ToggleLoopFling(
    text
)
    local cleaned =
        tostring(
            text
            or ""
        ):
            match(
                "^%s*(.-)%s*$"
            )
        or ""
    if cleaned == "" then
        U.LoopFlingInput = nil
        U.LoopFlingGeneration = (U.LoopFlingGeneration or 0) + 1
        CustomNotify(
            "Loop Fling Disabled",
            Color3.fromRGB(
                255,
                120,
                120
            )
        )
        return
    end
    local normalized =
        string.lower(
            cleaned
        )
    if U.LoopFlingInput
    and string.lower(
        U.LoopFlingInput
    ) == normalized then
        U.LoopFlingInput = nil
        U.LoopFlingGeneration = (U.LoopFlingGeneration or 0) + 1
        CustomNotify(
            "Loop Fling Disabled",
            Color3.fromRGB(
                255,
                120,
                120
            )
        )
        return
    end
    U.LoopFlingInput =
        cleaned
    U.LoopFlingGeneration = (U.LoopFlingGeneration or 0) + 1
    local generation =
        U.LoopFlingGeneration
    CustomNotify(
        "Loop Fling Enabled • "
        .. cleaned,
        Color3.fromRGB(
            100,
            255,
            130
        )
    )
    task.spawn(function()
        while U.LoopFlingInput
        and generation
            == U.LoopFlingGeneration
        and not getgenv().Destroyed do
            local activeInput =
                U.LoopFlingInput
            if not activeInput then
                break
            end
            local lower =
                string.lower(
                    activeInput
                )
            if lower ~= "all"
            and lower ~= "others" then
                local found = false
                for _, target in ipairs(
                    Players:
                        GetPlayers()
                ) do
                    if target ~= Player
                    and (
                        string.find(
                            string.lower(
                                target.Name
                            ),
                            lower,
                            1,
                            true
                        )
                        or string.find(
                            string.lower(
                                target.DisplayName
                            ),
                            lower,
                            1,
                            true
                        )
                    ) then
                        found = true
                        break
                    end
                end
                if not found then
                    U.LoopFlingInput = nil
                    CustomNotify(
                        "Loop Fling stopped • player left",
                        Color3.fromRGB(
                            255,
                            180,
                            70
                        )
                    )
                    break
                end
            end
            ExecuteFling(
                activeInput
            )
            task.wait(1.25)
        end
    end)
end
CreateInputWithTwoButtons(
    "Fling",
    FlingPage,
    "",
    "Fling",
    "Loop",
    function(text, mode)
        if mode == "LOOP" then
            ToggleLoopFling(
                text
            )
        else
            ExecuteFling(
                text
            )
        end
    end
)
CreateInputWithTwoButtons("Teleport", FlingPage, "", "TP", "Loop TP", function(text, mode) ExecuteTeleport(text, mode) end)

Settings.MagnetMode = Settings.MagnetMode or "Orbit"
Settings.MagnetShape = Settings.MagnetShape or "Orbit"
Settings.MagnetAttackStyle = Settings.MagnetAttackStyle or "Swarm"
Settings.PartMagnetRange = math.clamp(tonumber(Settings.PartMagnetRange) or 80, 5, 500)
Settings.MagnetRadius = math.clamp(tonumber(Settings.MagnetRadius) or 10, 2, 100)
if tonumber(Settings.MagnetSpin) == nil then
    Settings.MagnetSpin = (tonumber(Settings.MagnetSpeed) or 3) * 5
end
Settings.MagnetSpin = math.clamp(math.floor(tonumber(Settings.MagnetSpin) + 0.5), 0, 100)
Settings.MagnetHeight = tonumber(Settings.MagnetHeight) or 0
Settings.MagnetAttackDistance = tonumber(Settings.MagnetAttackDistance) or 3
Settings.MagnetPull = math.clamp(tonumber(Settings.MagnetPull) or 100, 5, 100)
Settings.MagnetMaxParts = tonumber(Settings.MagnetMaxParts) or 70
Settings.PartMagnet = false

local MagnetGui = nil
do
    local RunService = game:GetService("RunService")
    local Controlled = {}
    local controlledCount = 0
    local scanClock, radiusClock = 0, 0
    local nextIndex = 0
    local statusLabel = nil
    local magnetTargetBox = nil

    local TAU = math.pi * 2
    local GOLD = 2.399963
    local V3 = Vector3.new
    local sin, cos, floor, ceil, max, sqrt = math.sin, math.cos, math.floor, math.ceil, math.max, math.sqrt

    local function LocalPos(cf, x, y, z)
        return (cf * CFrame.new(x, y, z)).Position
    end

    local function SphereDir(i, n, rot)
        local y = 1 - (i - 0.5) / max(n, 1) * 2
        local r = sqrt(max(1 - y * y, 0))
        local theta = i * GOLD + rot
        return V3(cos(theta) * r, y, sin(theta) * r)
    end

    local SHAPE_ORDER = {
        "Orbit", "Ring", "Rings", "Wave",
        "Spiral", "Halo", "Tornado", "Blades",
        "Fountain", "Floor", "Galaxy", "Flower",
        "Infinity", "Torus", "Crown", "Pillars",
        "Comet", "Pulse", "Pyramid", "Cube",
        "Rain",
    }
    local SHAPES = {}

    SHAPES.Orbit = function(i, n, t, c, cf, R, S)
        local ring = i % 4
        local rr = R * 0.7 + ring * (R * 0.3)
        local a = i * GOLD + t * S * (0.4 - ring * 0.05)
        return c + V3(cos(a) * rr, ((i % 5) - 2) * 1.6, sin(a) * rr)
    end
    SHAPES.Ring = function(i, n, t, c, cf, R, S)
        local a = TAU * (i - 1) / n + t * S * 0.4
        return c + V3(cos(a) * R, 0, sin(a) * R)
    end
    SHAPES.Rings = function(i, n, t, c, cf, R, S)
        local k = (i - 1) % 3
        local j = floor((i - 1) / 3)
        local m = max(ceil(n / 3), 1)
        local dir = (k % 2 == 0) and 1 or -1
        local a = TAU * j / m + t * S * 0.4 * dir
        local rr = R * (0.45 + 0.3 * k)
        return c + V3(cos(a) * rr, (k - 1) * 1.5, sin(a) * rr)
    end
    SHAPES.Wave = function(i, n, t, c, cf, R, S)
        local a = TAU * (i - 1) / n + t * S * 0.3
        local y = sin(a * 4 + t * S * 1) * R * 0.25
        return c + V3(cos(a) * R, y, sin(a) * R)
    end
    SHAPES.Spiral = function(i, n, t, c, cf, R, S)
        local f = (i - 1) / max(n - 1, 1)
        local a = f * TAU * 3 + t * S * 0.4
        local rr = R * 0.6
        return c + V3(cos(a) * rr, f * R * 2 - 2, sin(a) * rr)
    end
    SHAPES.Halo = function(i, n, t, c, cf, R, S)
        local rr = max(R * 0.35, 2)
        local a = TAU * (i - 1) / n + t * S * 0.5
        return c + V3(cos(a) * rr, 5, sin(a) * rr)
    end
    SHAPES.Tornado = function(i, n, t, c, cf, R, S)
        local f = ((i - 1) / n + t * S * 0.03) % 1
        local rr = R * (0.15 + f * 0.85)
        local a = i * GOLD + t * S * (0.6 - f * 0.2)
        return c + V3(cos(a) * rr, f * R * 2.5 - 3, sin(a) * rr)
    end
    SHAPES.Blades = function(i, n, t, c, cf, R, S)
        local b = (i - 1) % 4
        local j = floor((i - 1) / 4)
        local m = max(ceil(n / 4), 1)
        local rr = (j + 1) / m * R
        local a = b * TAU / 4 + t * S * 0.6
        return c + V3(cos(a) * rr, 1, sin(a) * rr)
    end
    SHAPES.Fountain = function(i, n, t, c, cf, R, S)
        local ph = ((i * 0.618034) % 1 + t * S * 0.05) % 1
        local a = i * GOLD
        local rr = ph * R
        return c + V3(cos(a) * rr, ph * (1 - ph) * 4 * R * 0.9, sin(a) * rr)
    end
    SHAPES.Floor = function(i, n, t, c, cf, R, S)
        local cols = max(ceil(sqrt(n)), 1)
        local col = (i - 1) % cols
        local row = floor((i - 1) / cols)
        return LocalPos(cf, (col - (cols - 1) / 2) * 3, -3.6, (row - (cols - 1) / 2) * 3)
    end
    SHAPES.Galaxy = function(i, n, t, c, cf, R, S)
        local arm = (i - 1) % 3
        local j = floor((i - 1) / 3)
        local f = (j + 1) / max(ceil(n / 3), 1)
        local a = arm * TAU / 3 + f * 2.5 + t * S * 0.3
        return c + V3(cos(a) * f * R, 0.5, sin(a) * f * R)
    end
    SHAPES.Flower = function(i, n, t, c, cf, R, S)
        local th = math.pi * (i - 1) / n + t * S * 0.2
        local r = R * cos(5 * th)
        return c + V3(cos(th) * r, 1, sin(th) * r)
    end
    SHAPES.Infinity = function(i, n, t, c, cf, R, S)
        local s = TAU * (i - 1) / n + t * S * 0.4
        local d = 1 + sin(s) ^ 2
        return LocalPos(cf, R * cos(s) / d, 1, R * sin(s) * cos(s) / d)
    end
    SHAPES.Torus = function(i, n, t, c, cf, R, S)
        local major = R * 0.75
        local minor = max(R * 0.25, 1.5)
        local u = TAU * (i - 1) / n + t * S * 0.3
        local v = i * GOLD * 3 + t * S * 0.6
        local w = major + minor * cos(v)
        return c + V3(cos(u) * w, minor * sin(v) + 1, sin(u) * w)
    end
    SHAPES.Crown = function(i, n, t, c, cf, R, S)
        local a = TAU * (i - 1) / n + t * S * 0.4
        local tri = math.abs(((a * 8 / TAU) % 2) - 1)
        local rr = R * 0.6
        return c + V3(cos(a) * rr, 3 + tri * R * 0.4, sin(a) * rr)
    end
    SHAPES.Pillars = function(i, n, t, c, cf, R, S)
        local p = (i - 1) % 4
        local j = floor((i - 1) / 4)
        local m = max(ceil(n / 4) - 1, 1)
        local a = p * TAU / 4 + t * S * 0.3
        return c + V3(cos(a) * R, -2 + j / m * R * 1.5, sin(a) * R)
    end
    SHAPES.Comet = function(i, n, t, c, cf, R, S)
        local f = (i - 1) / max(n - 1, 1)
        local a = t * S * 0.6 - f * 2.2
        local spread = f * 1.5 * sin(i * 7)
        local rr = R + spread
        return c + V3(cos(a) * rr, 1 + sin(a * 2) * R * 0.2 + spread * 0.5, sin(a) * rr)
    end
    SHAPES.Pulse = function(i, n, t, c, cf, R, S)
        local radius = R * (0.55 + 0.35 * sin(t * S * 0.8))
        return c + V3(0, 2, 0) + SphereDir(i, n, t * S * 0.2) * radius
    end
    local PYR = {
        { V3(-1, 0, -1), V3(1, 0, -1) }, { V3(1, 0, -1), V3(1, 0, 1) },
        { V3(1, 0, 1), V3(-1, 0, 1) }, { V3(-1, 0, 1), V3(-1, 0, -1) },
        { V3(-1, 0, -1), V3(0, 1, 0) }, { V3(1, 0, -1), V3(0, 1, 0) },
        { V3(1, 0, 1), V3(0, 1, 0) }, { V3(-1, 0, 1), V3(0, 1, 0) },
    }
    SHAPES.Pyramid = function(i, n, t, c, cf, R, S)
        local e = PYR[(i - 1) % 8 + 1]
        local f = (floor((i - 1) / 8) + 0.5) / max(ceil(n / 8), 1)
        local p = e[1]:Lerp(e[2], f)
        local local3 = V3(p.X * R * 0.7, p.Y * R * 1.2 - 2, p.Z * R * 0.7)
        return c + CFrame.Angles(0, t * S * 0.3, 0):VectorToWorldSpace(local3)
    end
    local CUBE = {}
    for _, a in ipairs({ -1, 1 }) do
        for _, b in ipairs({ -1, 1 }) do
            CUBE[#CUBE + 1] = { V3(-1, a, b), V3(1, a, b) }
            CUBE[#CUBE + 1] = { V3(a, -1, b), V3(a, 1, b) }
            CUBE[#CUBE + 1] = { V3(a, b, -1), V3(a, b, 1) }
        end
    end
    SHAPES.Cube = function(i, n, t, c, cf, R, S)
        local e = CUBE[(i - 1) % 12 + 1]
        local f = (floor((i - 1) / 12) + 0.5) / max(ceil(n / 12), 1)
        local p = e[1]:Lerp(e[2], f) * (R * 0.6)
        local rot = CFrame.Angles(0, t * S * 0.3, 0) * CFrame.Angles(t * S * 0.15, 0, 0)
        return c + V3(0, R * 0.6 + 1, 0) + rot:VectorToWorldSpace(p)
    end
    SHAPES.Rain = function(i, n, t, c, cf, R, S)
        local ph = ((i * 0.618034) % 1 + t * S * 0.06) % 1
        local a = i * GOLD
        local rr = sqrt((i * 0.37) % 1) * R
        return c + V3(cos(a) * rr, R * 1.2 * (1 - ph) - 2, sin(a) * rr)
    end

    local ATTACK_ORDER = { "Swarm", "Cage", "Ring", "Head", "Feet", "Ram", "Tornado", "Inside", "Shape" }
    local ATTACK = {}

    ATTACK.Swarm = function(i, n, t, c, cf, D, S, R)
        local a = i * GOLD + t * S * 1.2
        local rr = D * 0.7 + (i % 3)
        return c + V3(cos(a) * rr, ((i % 5) - 2) * 0.9, sin(a) * rr)
    end
    ATTACK.Cage = function(i, n, t, c, cf, D, S, R)
        return c + SphereDir(i, n, t * S * 0.5) * (D + 1.5)
    end
    ATTACK.Ring = function(i, n, t, c, cf, D, S, R)
        local a = TAU * (i - 1) / n + t * S * 0.8
        local rr = D + 1
        return c + V3(cos(a) * rr, ((i % 3) - 1) * 0.8, sin(a) * rr)
    end
    ATTACK.Head = function(i, n, t, c, cf, D, S, R)
        local j = i - 1
        local a = j * GOLD + t * S * 0.8
        local rr = 1 + D * 0.2
        return c + V3(cos(a) * rr, 2.8 + (j % 10) * 0.7, sin(a) * rr)
    end
    ATTACK.Feet = function(i, n, t, c, cf, D, S, R)
        local a = TAU * (i - 1) / n + t * S * 0.7
        local rr = D * 0.6 + (i % 2)
        return c + V3(cos(a) * rr, -2.8, sin(a) * rr)
    end
    ATTACK.Ram = function(i, n, t, c, cf, D, S, R)
        local dir = SphereDir(i, n, 0)
        local ph = ((i * 0.618034) % 1 + t * max(S, 0.5) * 0.08) % 1
        return c + dir * ((D + 8) * (1 - 2 * ph))
    end
    ATTACK.Tornado = function(i, n, t, c, cf, D, S, R)
        local f = ((i - 1) / n + t * S * 0.04) % 1
        local rr = D * 0.3 + f * (D + 2)
        local a = i * GOLD + t * S * 1
        return c + V3(cos(a) * rr, f * 7 - 3, sin(a) * rr)
    end
    ATTACK.Inside = function(i, n, t, c, cf, D, S, R)
        return c + V3(sin(t * S * 2 + i) * 0.6, ((i % 5) - 2) * 0.6, cos(t * S * 2 + i * 1.3) * 0.6)
    end
    ATTACK.Shape = function(i, n, t, c, cf, D, S, R)
        local shape = SHAPES[Settings.MagnetShape] or SHAPES.Orbit
        return shape(i, n, t, c, cf, R, S)
    end

    if not SHAPES[Settings.MagnetShape] then Settings.MagnetShape = "Orbit" end
    if not ATTACK[Settings.MagnetAttackStyle] then Settings.MagnetAttackStyle = "Swarm" end
    if not SHAPES[Settings.MagnetMode]
    and Settings.MagnetMode ~= "Mouse"
    and Settings.MagnetMode ~= "Attack" then
        Settings.MagnetMode = Settings.MagnetShape
    end

    local function Release(part)
        local data = Controlled[part]
        if not data then return end
        Controlled[part] = nil
        controlledCount = math.max(controlledCount - 1, 0)
        pcall(function() data.Align:Destroy() end)
        pcall(function() data.Att:Destroy() end)
        if part.Parent and data.CanCollide ~= nil then
            pcall(function() part.CanCollide = data.CanCollide end)
        end
    end

    local function ReleaseAll()
        for part in pairs(Controlled) do
            Release(part)
        end
        controlledCount = 0
    end
    env.ToxReleasePartMagnet = ReleaseAll

    local function IsCharacterPart(part)
        local model = part:FindFirstAncestorOfClass("Model")
        while model do
            if model:FindFirstChildOfClass("Humanoid") then
                return true
            end
            model = model.Parent and model.Parent:FindFirstAncestorOfClass("Model")
        end
        return false
    end

    local function IsMagnetCandidate(part)
        if not part:IsA("BasePart") or part.Anchored or Controlled[part] then return false end
        if string.sub(part.Name, 1, 3) == "Tox" then return false end
        local ok, grounded = pcall(function() return part:IsGrounded() end)
        if not ok or grounded then return false end
        local size = part.Size
        if math.max(size.X, size.Y, size.Z) > 80 then return false end
        if IsCharacterPart(part) then return false end
        if part:FindFirstAncestorOfClass("Tool") then return false end
        return true
    end

    local function GetPull()
        return math.clamp(tonumber(Settings.MagnetPull) or 100, 5, 100)
    end

    local function Grab(part)
        local att = Instance.new("Attachment")
        att.Name = "ToxMagnetAttachment"
        att.Parent = part
        local align = Instance.new("AlignPosition")
        align.Name = "ToxMagnetAlign"
        align.Mode = Enum.PositionAlignmentMode.OneAttachment
        align.Attachment0 = att
        align.MaxForce = math.huge
        align.MaxVelocity = math.huge
        local pull = GetPull()
        align.Responsiveness = pull
        align.Parent = part
        nextIndex += 1
        Controlled[part] = { Att = att, Align = align, Index = nextIndex, CanCollide = part.CanCollide, Pull = pull }
        controlledCount += 1
        pcall(function() part.CanCollide = false end)
    end

    local function TryRaiseSimulationRadius()
        local setter = sethiddenproperty or set_hidden_property or sethiddenprop
        if setter then
            pcall(setter, Player, "SimulationRadius", 1e9)
            pcall(setter, Player, "MaximumSimulationRadius", 1e9)
        end
    end

    local function GetMagnetTarget()
        local text = string.lower(magnetTargetBox and magnetTargetBox.Text or "")
        if text == "" then return nil end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= Player and (string.find(string.lower(p.Name), text, 1, true)
            or string.find(string.lower(p.DisplayName), text, 1, true)) then
                local char = p.Character
                local tRoot = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if tRoot and hum and hum.Health > 0 then
                    return p, tRoot
                end
                return p, nil
            end
        end
        return nil
    end

    local MousePoint = nil
    local holdKind = nil
    local holdTouch = nil

    local function RaycastScreen(x, y, isViewport)
        local cam = workspace.CurrentCamera
        if not cam then return nil end
        local ray = isViewport and cam:ViewportPointToRay(x, y) or cam:ScreenPointToRay(x, y)
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        local exclude = {}
        if Player.Character then exclude[1] = Player.Character end
        for part in pairs(Controlled) do exclude[#exclude + 1] = part end
        params.FilterDescendantsInstances = exclude
        local hit = workspace:Raycast(ray.Origin, ray.Direction * 2000, params)
        return hit and hit.Position or (ray.Origin + ray.Direction * 120)
    end

    local function UpdateMousePointFromCursor()
        local loc = UserInputService:GetMouseLocation()
        local p = RaycastScreen(loc.X, loc.Y, true)
        if p then MousePoint = p end
    end

    local function MouseModeActive()
        return Settings.PartMagnet and Settings.MagnetMode == "Mouse"
    end

    AddConnection(UserInputService.InputBegan:Connect(function(input, processed)
        if processed or not MouseModeActive() then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            holdKind = "Mouse"
            UpdateMousePointFromCursor()
        elseif input.UserInputType == Enum.UserInputType.Touch then
            holdKind = "Touch"
            holdTouch = input
            local p = RaycastScreen(input.Position.X, input.Position.Y, false)
            if p then MousePoint = p end
        end
    end))
    AddConnection(UserInputService.InputChanged:Connect(function(input)
        if holdKind == "Touch" and input == holdTouch then
            local p = RaycastScreen(input.Position.X, input.Position.Y, false)
            if p then MousePoint = p end
        end
    end))
    AddConnection(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and holdKind == "Mouse" then
            holdKind = nil
        elseif input == holdTouch then
            holdKind = nil
            holdTouch = nil
        end
    end))

    local function FlatCFrame(position, look)
        local flat = V3(look.X, 0, look.Z)
        if flat.Magnitude < 1e-3 then flat = V3(0, 0, -1) end
        return CFrame.new(position, position + flat.Unit)
    end

    AddConnection(RunService.Heartbeat:Connect(function(delta)
        if env.Destroyed then return end
        if not Settings.PartMagnet then
            if controlledCount > 0 then ReleaseAll() end
            holdKind, holdTouch = nil, nil
            return
        end
        local character = Player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not root then return end

        radiusClock += delta
        if radiusClock >= 1 then
            radiusClock = 0
            TryRaiseSimulationRadius()
        end

        local range = math.clamp(tonumber(Settings.PartMagnetRange) or 80, 5, 500)
        local maxParts = math.clamp(math.floor(tonumber(Settings.MagnetMaxParts) or 70), 1, 300)

        local mode = tostring(Settings.MagnetMode or "Orbit")
        local shapeName = SHAPES[Settings.MagnetShape] and Settings.MagnetShape or "Orbit"
        local R = math.clamp(tonumber(Settings.MagnetRadius) or 10, 1, 100)
        local S = (tonumber(Settings.MagnetSpin) or 15) / 5
        local H = math.clamp(tonumber(Settings.MagnetHeight) or 0, -100, 100)
        local D = math.clamp(tonumber(Settings.MagnetAttackDistance) or 3, 0, 100)
        local t = os.clock()

        local center = root.Position + V3(0, H, 0)
        local cf = FlatCFrame(center, root.CFrame.LookVector)
        local shapeFn = SHAPES[shapeName]
        local attackFn = nil
        local status

        if mode == "Attack" then
            local target, tRoot = GetMagnetTarget()
            if tRoot then
                local vel = tRoot.AssemblyLinearVelocity
                if vel.Magnitude > 120 then vel = vel.Unit * 120 end
                center = tRoot.Position + vel * 0.08
                cf = FlatCFrame(center, tRoot.CFrame.LookVector)
                attackFn = ATTACK[Settings.MagnetAttackStyle] or ATTACK.Swarm
                status = "Attack • " .. target.DisplayName .. " • " .. tostring(Settings.MagnetAttackStyle)
            else
                status = "Attack • no target → " .. shapeName
            end
        elseif mode == "Mouse" then
            if holdKind == "Mouse" then
                UpdateMousePointFromCursor()
            end
            if MousePoint then
                center = MousePoint + V3(0, 3 + H, 0)
                cf = FlatCFrame(center, root.CFrame.LookVector)
            end
            status = "Mouse • " .. shapeName .. (MousePoint and "" or " • click to place")
        else
            status = shapeName
        end

        scanClock += delta
        if scanClock >= 0.4 then
            scanClock = 0
            for part in pairs(Controlled) do
                if not part.Parent or part.Anchored then
                    Release(part)
                end
            end
            if controlledCount > maxParts then
                for part in pairs(Controlled) do
                    if controlledCount <= maxParts then break end
                    Release(part)
                end
            end
            local params = OverlapParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances = { character }
            local ok, parts = pcall(function()
                return workspace:GetPartBoundsInRadius(root.Position, range, params)
            end)
            if ok and parts then
                for _, part in ipairs(parts) do
                    if controlledCount >= maxParts then break end
                    if IsMagnetCandidate(part) then
                        Grab(part)
                    end
                end
            end
            if statusLabel then
                statusLabel.Text = "ON • " .. controlledCount .. " parts • " .. status
            end
        end

        local pull = GetPull()
        local ordered = {}
        for part, data in pairs(Controlled) do
            ordered[#ordered + 1] = { part, data }
        end
        table.sort(ordered, function(x, y) return x[2].Index < y[2].Index end)
        local n = #ordered
        for i, entry in ipairs(ordered) do
            local part, data = entry[1], entry[2]
            if data.Pull ~= pull then
                data.Pull = pull
                pcall(function() data.Align.Responsiveness = pull end)
            end
            local ok, pos
            if attackFn then
                ok, pos = pcall(attackFn, i, n, t, center, cf, D, S, R)
            else
                ok, pos = pcall(shapeFn, i, n, t, center, cf, R, S)
            end
            if ok and typeof(pos) == "Vector3" then
                data.Align.Position = pos
            end
            pcall(function()
                part.AssemblyAngularVelocity = Vector3.new(0, 4, 0)
            end)
        end
    end))

    local Theme = env.Theme or {}
    local RegisterThemedObject = env.RegisterThemedObject or function() end
    local function Themed(obj, prop, key, fallback)
        obj[prop] = Theme[key] or fallback
        RegisterThemedObject(obj, prop, key)
    end
    local function Corner(obj, r)
        local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, r or 6) c.Parent = obj
    end
    local function Stroke(obj, key)
        local st = Instance.new("UIStroke") st.Thickness = 1 st.Transparency = 0.35
        st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        Themed(st, "Color", key or "Outline", Color3.fromRGB(60, 60, 80))
        st.Parent = obj
        return st
    end
    local function Label(text, size, pos, parent, dim)
        local l = Instance.new("TextLabel")
        l.Size = size l.Position = pos l.BackgroundTransparency = 1
        l.Font = dim and Enum.Font.Gotham or Enum.Font.GothamMedium
        l.TextSize = dim and 10 or 11 l.TextXAlignment = Enum.TextXAlignment.Left
        l.Text = text
        Themed(l, "TextColor3", dim and "DimText" or "Text", dim and Color3.fromRGB(160, 160, 180) or Color3.new(1, 1, 1))
        l.Parent = parent
        return l
    end
    local function Button(text, size, pos, parent)
        local b = Instance.new("TextButton")
        b.Size = size b.Position = pos b.BorderSizePixel = 0 b.AutoButtonColor = true
        b.Text = text b.Font = Enum.Font.GothamBold b.TextSize = 10
        b.BackgroundColor3 = Theme.Element or Color3.fromRGB(25, 30, 40)
        b.TextColor3 = Theme.Text or Color3.new(1, 1, 1)
        Corner(b, 4) Stroke(b) b.Parent = parent
        return b
    end
    local function Slider(text, y, minV, maxV, getValue, setValue, suffix, parent, step)
        step = step or 1
        Label(text, UDim2.new(0.6, 0, 0, 16), UDim2.new(0, 10, 0, y), parent)
        local valueBox = Instance.new("TextBox")
        valueBox.Size = UDim2.new(0, 70, 0, 16) valueBox.Position = UDim2.new(1, -80, 0, y)
        valueBox.BackgroundTransparency = 1 valueBox.Font = Enum.Font.GothamBold valueBox.TextSize = 11
        valueBox.TextXAlignment = Enum.TextXAlignment.Right valueBox.ClearTextOnFocus = true
        Themed(valueBox, "TextColor3", "Accent", Color3.fromRGB(30, 95, 255))
        valueBox.Parent = parent
        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(1, -20, 0, 6) bar.Position = UDim2.new(0, 10, 0, y + 20)
        bar.BorderSizePixel = 0
        Themed(bar, "BackgroundColor3", "Element", Color3.fromRGB(25, 30, 40))
        Corner(bar, 3) bar.Parent = parent
        local fill = Instance.new("Frame")
        fill.BorderSizePixel = 0 fill.Size = UDim2.new(0, 0, 1, 0)
        Themed(fill, "BackgroundColor3", "Accent", Color3.fromRGB(30, 95, 255))
        Corner(fill, 3) fill.Parent = bar
        local function Show(v)
            valueBox.Text = string.format("%g", v) .. suffix
            fill.Size = UDim2.new(math.clamp((v - minV) / (maxV - minV), 0, 1), 0, 1, 0)
        end
        local function Apply(v)
            v = math.floor((tonumber(v) or minV) / step + 0.5) * step
            v = math.clamp(v, minV, maxV)
            setValue(v)
            Show(v)
            if env.AutoSaveConfiguration then env.AutoSaveConfiguration() end
        end
        Show(getValue())
        local dragging = false
        local function FromInput(x)
            local rel = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
            Apply(minV + (maxV - minV) * rel)
        end
        bar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                FromInput(input.Position.X)
            end
        end)
        AddConnection(UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                FromInput(input.Position.X)
            end
        end))
        AddConnection(UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end))
        valueBox.FocusLost:Connect(function()
            local typed = tonumber((string.gsub(valueBox.Text, "[^%d%.%-]", "")))
            if typed then Apply(typed) else Show(getValue()) end
        end)
    end
    local function Grid(parent, y, count, cols)
        local rows = math.max(math.ceil(count / cols), 1)
        local holder = Instance.new("Frame")
        holder.BackgroundTransparency = 1
        holder.Size = UDim2.new(1, -20, 0, rows * 26)
        holder.Position = UDim2.new(0, 10, 0, y)
        holder.Parent = parent
        local layout = Instance.new("UIGridLayout")
        layout.CellSize = UDim2.new(1 / cols, -4, 0, 22)
        layout.CellPadding = UDim2.new(0, 4, 0, 4)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = holder
        return holder, y + rows * 26
    end

    local gui = Instance.new("Frame")
    gui.Name = "ToxMagnetFrame"
    gui.Size = UDim2.new(0, 330, 0, 430)
    gui.Position = UDim2.new(0.5, -165, 0.5, -215)
    gui.BorderSizePixel = 0
    gui.ClipsDescendants = true
    gui.Visible = false
    Themed(gui, "BackgroundColor3", "Panel", Color3.fromRGB(15, 18, 26))
    gui.Parent = env.Gui
    Corner(gui, 8)
    local gStroke = Stroke(gui, "Accent") gStroke.Transparency = 0.25
    if env.ApplySavedGuiPosition then pcall(env.ApplySavedGuiPosition, "ToxMagnet", gui) end
    if env.TrackGuiPosition then pcall(env.TrackGuiPosition, "ToxMagnet", gui) end

    local top = Instance.new("Frame")
    top.Size = UDim2.new(1, 0, 0, 32) top.BorderSizePixel = 0
    Themed(top, "BackgroundColor3", "Element", Color3.fromRGB(25, 30, 40))
    top.Parent = gui
    if env.ToxRoundTopBar then env.ToxRoundTopBar(top) end
    if env.MakeDraggable then pcall(env.MakeDraggable, gui, top) end
    local title = Label("Tox Magnet", UDim2.new(1, -40, 1, 0), UDim2.new(0, 10, 0, 0), top)
    title.Font = Enum.Font.GothamBold title.TextSize = 13
    local close = Button("X", UDim2.new(0, 22, 0, 20), UDim2.new(1, -26, 0.5, -10), top)
    close.MouseButton1Click:Connect(function() gui.Visible = false end)

    local body = Instance.new("ScrollingFrame")
    body.Name = "Body"
    body.Size = UDim2.new(1, 0, 1, -32)
    body.Position = UDim2.new(0, 0, 0, 32)
    body.BackgroundTransparency = 1
    body.BorderSizePixel = 0
    body.ScrollBarThickness = 4
    body.ScrollingDirection = Enum.ScrollingDirection.Y
    body.CanvasSize = UDim2.new(0, 0, 0, 0)
    Themed(body, "ScrollBarImageColor3", "Accent", Color3.fromRGB(30, 95, 255))
    body.Parent = gui

    local y = 8
    local power = Button("Magnet: OFF", UDim2.new(0.5, -14, 0, 28), UDim2.new(0, 10, 0, y), body)
    local release = Button("Release All", UDim2.new(0.5, -14, 0, 28), UDim2.new(0.5, 4, 0, y), body)
    local function PaintPower()
        power.Text = Settings.PartMagnet and "Magnet: ON" or "Magnet: OFF"
        power.BackgroundColor3 = Settings.PartMagnet and Color3.fromRGB(40, 150, 80) or (Theme.Element or Color3.fromRGB(25, 30, 40))
    end
    PaintPower()
    power.MouseButton1Click:Connect(function()
        Settings.PartMagnet = not Settings.PartMagnet
        if not Settings.PartMagnet then ReleaseAll() end
        PaintPower()
        if statusLabel and not Settings.PartMagnet then statusLabel.Text = "OFF" end
    end)
    release.MouseButton1Click:Connect(function()
        ReleaseAll()
        CustomNotify("Tox Magnet • released all parts", Color3.fromRGB(255, 200, 120))
    end)
    y += 34

    statusLabel = Label("OFF", UDim2.new(1, -20, 0, 14), UDim2.new(0, 10, 0, y), body, true)
    statusLabel.TextTruncate = Enum.TextTruncate.AtEnd
    y += 18

    Label("Mode / Shape", UDim2.new(1, -20, 0, 14), UDim2.new(0, 10, 0, y), body)
    y += 16
    local modeNames = {}
    for _, name in ipairs(SHAPE_ORDER) do modeNames[#modeNames + 1] = name end
    modeNames[#modeNames + 1] = "Mouse"
    modeNames[#modeNames + 1] = "Attack"
    local modeHolder
    modeHolder, y = Grid(body, y, #modeNames, 4)
    local modeButtons = {}
    local styleButtons = {}

    local function PaintModes()
        local accent = Theme.Accent or Color3.fromRGB(30, 95, 255)
        local element = Theme.Element or Color3.fromRGB(25, 30, 40)
        local special = Settings.MagnetMode == "Mouse" or Settings.MagnetMode == "Attack"
        for name, btn in pairs(modeButtons) do
            if Settings.MagnetMode == name then
                btn.BackgroundColor3 = accent
            elseif special and Settings.MagnetShape == name then
                btn.BackgroundColor3 = element:Lerp(accent, 0.45)
            else
                btn.BackgroundColor3 = element
            end
        end
        for name, btn in pairs(styleButtons) do
            btn.BackgroundColor3 = Settings.MagnetAttackStyle == name and accent or element
        end
    end

    local function SaveMagnet()
        if env.AutoSaveConfiguration then env.AutoSaveConfiguration() end
    end

    for index, name in ipairs(modeNames) do
        local b = Button(name, UDim2.new(), UDim2.new(), modeHolder)
        b.LayoutOrder = index
        modeButtons[name] = b
        b.MouseButton1Click:Connect(function()
            if name == "Mouse" or name == "Attack" then
                if Settings.MagnetMode == name then
                    Settings.MagnetMode = Settings.MagnetShape
                else
                    Settings.MagnetMode = name
                end
            else
                Settings.MagnetShape = name
                if Settings.MagnetMode ~= "Mouse" and Settings.MagnetMode ~= "Attack" then
                    Settings.MagnetMode = name
                end
            end
            PaintModes()
            SaveMagnet()
        end)
    end

    local hint = Label("Shape still applies in Mouse/Attack • click Mouse/Attack again to go back",
        UDim2.new(1, -20, 0, 24), UDim2.new(0, 10, 0, y), body, true)
    hint.TextWrapped = true
    y += 28

    Label("Attack style (how parts stay on the target)", UDim2.new(1, -20, 0, 14), UDim2.new(0, 10, 0, y), body)
    y += 16
    local styleHolder
    styleHolder, y = Grid(body, y, #ATTACK_ORDER, 3)
    for index, name in ipairs(ATTACK_ORDER) do
        local b = Button(name, UDim2.new(), UDim2.new(), styleHolder)
        b.LayoutOrder = index
        styleButtons[name] = b
        b.MouseButton1Click:Connect(function()
            Settings.MagnetAttackStyle = name
            Settings.MagnetMode = "Attack"
            PaintModes()
            SaveMagnet()
        end)
    end
    PaintModes()
    y += 6

    Label("Attack target", UDim2.new(0.4, 0, 0, 24), UDim2.new(0, 10, 0, y), body)
    magnetTargetBox = Instance.new("TextBox")
    magnetTargetBox.Size = UDim2.new(0.6, -20, 0, 24) magnetTargetBox.Position = UDim2.new(0.4, 10, 0, y)
    magnetTargetBox.BorderSizePixel = 0 magnetTargetBox.ClearTextOnFocus = false
    magnetTargetBox.PlaceholderText = "nick (or Select Player)"
    magnetTargetBox.Text = "" magnetTargetBox.Font = Enum.Font.Gotham magnetTargetBox.TextSize = 11
    Themed(magnetTargetBox, "BackgroundColor3", "Element", Color3.fromRGB(25, 30, 40))
    Themed(magnetTargetBox, "TextColor3", "Text", Color3.new(1, 1, 1))
    Corner(magnetTargetBox, 4) Stroke(magnetTargetBox) magnetTargetBox.Parent = body
    env.ToxNamedInputs = env.ToxNamedInputs or {}
    env.ToxNamedInputs["Magnet"] = magnetTargetBox
    y += 34

    local sliders = {
        { "Range (grab parts within)", 5, 500, "PartMagnetRange", " studs" },
        { "Formation size", 2, 100, "MagnetRadius", " studs" },
        { "Spin speed", 0, 100, "MagnetSpin", "" },
        { "Pull strength (how fast parts move)", 5, 100, "MagnetPull", "" },
        { "Height offset", -100, 100, "MagnetHeight", " studs" },
        { "Attack distance", 0, 100, "MagnetAttackDistance", " studs" },
        { "Max parts", 1, 300, "MagnetMaxParts", "" },
    }
    for _, s in ipairs(sliders) do
        local key = s[4]
        Slider(s[1], y, s[2], s[3], function() return Settings[key] end,
            function(v) Settings[key] = v end, s[5], body, s[6])
        y += 52
    end
    body.CanvasSize = UDim2.new(0, 0, 0, y + 6)

    if env.MakeResizable then pcall(env.MakeResizable, gui, "ToxMagnet", Vector2.new(260, 220), Vector2.new(900, 1400)) end
    MagnetGui = gui
    env.ToxMagnetGui = gui
    env.ToxSetPartMagnet = function(v)
        Settings.PartMagnet = v == true
        if not Settings.PartMagnet then ReleaseAll() end
        PaintPower()
    end

    task.spawn(function()
        local minimizeDone, mainHooked = false, false
        for _ = 1, 100 do
            if env.Destroyed then return end
            if not minimizeDone and env.RegisterToxSubGuiMinimize then
                pcall(env.RegisterToxSubGuiMinimize, gui, -52)
                minimizeDone = true
            end
            local main = env.Main
            if not mainHooked and main then
                mainHooked = true
                local reopenWithMain = false
                AddConnection(main:GetPropertyChangedSignal("Visible"):Connect(function()
                    if env.Destroyed then return end
                    if not main.Visible then
                        if gui.Visible then
                            reopenWithMain = true
                            gui.Visible = false
                        end
                    elseif reopenWithMain then
                        reopenWithMain = false
                        gui.Visible = true
                    end
                end))
            end
            if minimizeDone and mainHooked then return end
            task.wait(0.2)
        end
    end)
end

local AvatarItemsGui = nil
local AvatarItemsLoad = nil

local function FindPlayerByInput(text)
    text = string.lower(tostring(text or ""))
    if text == "" then return nil end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player and (string.find(string.lower(p.Name), text, 1, true)
        or string.find(string.lower(p.DisplayName), text, 1, true)) then
            return p
        end
    end
    return nil
end

local SpectateTarget = nil
local function StopSpectate(silent)
    SpectateTarget = nil
    local camera = workspace.CurrentCamera
    local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
    if camera and hum then
        camera.CameraSubject = hum
    end
    if not silent then
        CustomNotify("Spectate stopped", Color3.fromRGB(255, 120, 120))
    end
end

CreateInputWithTwoButtons("Spectate", FlingPage, "", "View", "Stop", function(text, mode)
    if mode ~= "TP" then
        StopSpectate()
        return
    end
    local target = FindPlayerByInput(text)
    local hum = target and target.Character and target.Character:FindFirstChildOfClass("Humanoid")
    if not hum then
        return CustomNotify("Player not found!", Color3.fromRGB(255, 100, 100))
    end
    SpectateTarget = target
    workspace.CurrentCamera.CameraSubject = hum
    CustomNotify("Spectating • " .. target.DisplayName, Color3.fromRGB(100, 200, 255))
end)

AddConnection(game:GetService("RunService").Heartbeat:Connect(function()
    if not SpectateTarget or env.Destroyed then return end
    if not SpectateTarget.Parent then
        StopSpectate(true)
        return CustomNotify("Spectate stopped • player left", Color3.fromRGB(255, 180, 70))
    end
    local hum = SpectateTarget.Character and SpectateTarget.Character:FindFirstChildOfClass("Humanoid")
    local camera = workspace.CurrentCamera
    if hum and camera and camera.CameraSubject ~= hum then
        camera.CameraSubject = hum
    end
end))

Settings.UpPlayerSpeed = tonumber(Settings.UpPlayerSpeed) or 30
Settings.UpPlayerHeight = tonumber(Settings.UpPlayerHeight) or 50
local UpPlayerGeneration = 0

local UpPlayerRunning = false
local UpPlayerMode = "up"

local function StopUpPlayer()
    UpPlayerGeneration = UpPlayerGeneration + 1
end

local function RunUpPlayer(target)
    local character = Player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local tRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    if not root or not humanoid or not tRoot then
        return CustomNotify("Up Player • player not available", Color3.fromRGB(255, 100, 100))
    end

    UpPlayerGeneration = UpPlayerGeneration + 1
    local generation = UpPlayerGeneration
    UpPlayerRunning = true
    UpPlayerMode = "up"
    local startCF = root.CFrame
    local RunService = game:GetService("RunService")

    local UNDER = 5.6
    local currentY = tRoot.Position.Y - UNDER
    local reachedTop = false

    CustomNotify("Up Player • " .. target.DisplayName .. " (Down to bring back)", Color3.fromRGB(100, 255, 160))

    local hadNoclip = Settings.Noclip
    Settings.Noclip = false
    local yaw = select(2, root.CFrame:ToOrientation())
    local baseY = currentY

    while generation == UpPlayerGeneration and not env.Destroyed do
        local dt = RunService.Heartbeat:Wait()
        if not root.Parent or humanoid.Health <= 0 or not target.Parent then
            break
        end
        tRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
        if not tRoot then
            break
        end
        if env.AllowToxTeleport then env.AllowToxTeleport(0.3, "Up Player") end

        local speed = math.max(tonumber(Settings.UpPlayerSpeed) or 30, 1)
        local wantedTop = math.max(baseY + math.max(tonumber(Settings.UpPlayerHeight) or 50, 1), currentY)
        if reachedTop and currentY < wantedTop - 0.05 then
            reachedTop = false
        end
        if UpPlayerMode == "down" then
            currentY = math.max(currentY - speed * dt, baseY)
            root.CFrame = CFrame.new(tRoot.Position.X, currentY, tRoot.Position.Z) * CFrame.Angles(0, yaw, 0)
            root.AssemblyLinearVelocity = Vector3.new(0, -speed, 0)
            root.AssemblyAngularVelocity = Vector3.zero
            if currentY <= baseY + 0.05 then
                break
            end
            continue
        end
        if not reachedTop then
            currentY = math.min(currentY + speed * dt, wantedTop)
            if currentY >= wantedTop - 0.05 then
                reachedTop = true
                CustomNotify("Up Player • holding in the air", Color3.fromRGB(100, 200, 255))
            end
        end

        root.CFrame = CFrame.new(tRoot.Position.X, currentY, tRoot.Position.Z) * CFrame.Angles(0, yaw, 0)
        root.AssemblyLinearVelocity = reachedTop and Vector3.zero or Vector3.new(0, speed, 0)
        root.AssemblyAngularVelocity = Vector3.zero
    end

    if generation == UpPlayerGeneration then
        UpPlayerRunning = false
        UpPlayerMode = "up"
    end
    Settings.Noclip = hadNoclip
    if root.Parent then
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        if Settings.UpPlayerReturn ~= false then
            if env.AllowToxTeleport then env.AllowToxTeleport(1, "Up Player return") end
            if env.ToxSafeTeleportToCFrame then
                pcall(env.ToxSafeTeleportToCFrame, startCF, false)
            else
                root.CFrame = startCF
            end
        end
    end
end

local UpPlayerBox = CreateInputWithTwoButtons("Up Player", FlingPage, "", "Up", "Down", function(text, mode)
    if mode ~= "TP" then
        if UpPlayerRunning then
            UpPlayerMode = "down"
            CustomNotify("Up Player • bringing down", Color3.fromRGB(255, 200, 120))
        else
            CustomNotify("Up Player is not running", Color3.fromRGB(255, 180, 70))
        end
        return
    end
    local target = FindPlayerByInput(text)
    if not target then
        return CustomNotify("Player not found!", Color3.fromRGB(255, 100, 100))
    end
    task.spawn(RunUpPlayer, target)
end)

if UpPlayerBox and UpPlayerBox:IsA("GuiObject") then
    local stopBtn = Instance.new("TextButton")
    stopBtn.Name = "ToxUpPlayerStop"
    stopBtn.Size = UDim2.new(0, 48, 0, 24)
    stopBtn.Position = UDim2.new(1, -242, 0.5, -12)
    stopBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 50)
    stopBtn.BorderSizePixel = 0
    stopBtn.Text = "Stop"
    stopBtn.TextColor3 = Color3.new(1, 1, 1)
    stopBtn.Font = Enum.Font.GothamBold
    stopBtn.TextSize = 11
    stopBtn.Parent = UpPlayerBox
    local sc = Instance.new("UICorner") sc.CornerRadius = UDim.new(0, 4) sc.Parent = stopBtn
    for _, child in ipairs(UpPlayerBox:GetChildren()) do
        if child:IsA("TextLabel") and child.Text == "Up Player" then
            child.Size = UDim2.new(1, -256, child.Size.Y.Scale, child.Size.Y.Offset)
        end
    end
    stopBtn.MouseButton1Click:Connect(function()
        if UpPlayerRunning then
            StopUpPlayer()
            CustomNotify("Up Player stopped", Color3.fromRGB(255, 120, 120))
        else
            CustomNotify("Up Player is not running", Color3.fromRGB(255, 180, 70))
        end
    end)
end

if type(env.CreateSlider) == "function" and UpPlayerBox and UpPlayerBox:IsA("GuiObject") then
    local ROW = 42
    local speedSlider = env.CreateSlider("Speed", FlingPage, 5, 200, Settings.UpPlayerSpeed, " studs/s", function(v)
        Settings.UpPlayerSpeed = tonumber(v) or 30
        if env.AutoSaveConfiguration then env.AutoSaveConfiguration() end
    end, "UpPlayerSpeed", true)
    local heightSlider = env.CreateSlider("Height", FlingPage, 5, 500, Settings.UpPlayerHeight, " studs", function(v)
        Settings.UpPlayerHeight = tonumber(v) or 50
        if env.AutoSaveConfiguration then env.AutoSaveConfiguration() end
    end, "UpPlayerHeight", true)

    for _, child in ipairs(UpPlayerBox:GetChildren()) do
        if child:IsA("GuiObject") then
            if child.Position.Y.Scale == 0.5 then
                child.Position = UDim2.new(child.Position.X.Scale, child.Position.X.Offset, 0, ROW / 2 + child.Position.Y.Offset)
            end
            if child.Size.Y.Scale == 1 then
                child.Size = UDim2.new(child.Size.X.Scale, child.Size.X.Offset, 0, ROW)
            end
        end
    end

    local y = ROW
    for _, slider in ipairs({ speedSlider, heightSlider }) do
        if slider and slider:IsA("GuiObject") then
            slider.Parent = UpPlayerBox
            slider.AnchorPoint = Vector2.new(0, 0)
            slider.Position = UDim2.new(0, 8, 0, y)
            slider.Size = UDim2.new(1, -16, 0, slider.Size.Y.Offset)
            y = y + slider.Size.Y.Offset + 6
        end
    end
    if Settings.UpPlayerReturn == nil then Settings.UpPlayerReturn = true end
    local createToggleRaw = (env.ToxUniversalRawCreators and env.ToxUniversalRawCreators.CreateToggle) or CreateToggle
    local returnToggle = createToggleRaw("Return to my spot after Down", FlingPage, Settings.UpPlayerReturn ~= false, function(v)
        Settings.UpPlayerReturn = v == true
        if env.AutoSaveConfiguration then env.AutoSaveConfiguration() end
    end, "UpPlayerReturn")
    if returnToggle and returnToggle:IsA("GuiObject") then
        returnToggle.Parent = UpPlayerBox
        returnToggle.AnchorPoint = Vector2.new(0, 0)
        returnToggle.Position = UDim2.new(0, 8, 0, y)
        returnToggle.Size = UDim2.new(1, -16, 0, returnToggle.Size.Y.Offset)
        y = y + returnToggle.Size.Y.Offset + 6
    end
    UpPlayerBox.Size = UDim2.new(UpPlayerBox.Size.X.Scale, UpPlayerBox.Size.X.Offset, 0, y + 2)
end

local function GetSelectKeyName()
    local key = Settings.SelectPlayerKey
    if typeof(key) == "EnumItem" then return key.Name end
    if type(key) == "string" and key ~= "" then return key end
    return "LeftAlt"
end

if type(env.CreateKeybindButton) == "function" then
    env.CreateKeybindButton("Select Player (Hold + Click)", FlingPage, GetSelectKeyName(), function(key)
        if typeof(key) == "EnumItem" then
            Settings.SelectPlayerKey = key.Name
        else
            Settings.SelectPlayerKey = nil
        end
        if env.AutoSaveConfiguration then env.AutoSaveConfiguration() end
    end)
end

local function GetPlayerUnderMouse()
    local mouse = Player:GetMouse()
    local target = mouse and mouse.Target
    while target and target ~= workspace do
        local p = Players:GetPlayerFromCharacter(target)
        if p then return p end
        target = target.Parent
    end
    local camera = workspace.CurrentCamera
    local loc = UserInputService:GetMouseLocation()
    local ray = camera:ViewportPointToRay(loc.X, loc.Y)
    local best, bestDist = nil, 6
    for _, p in ipairs(Players:GetPlayers()) do
        local r = p ~= Player and p.Character and p.Character:FindFirstChild("HumanoidRootPart")
        if r then
            local toPoint = r.Position - ray.Origin
            local along = toPoint:Dot(ray.Direction)
            if along > 0 then
                local dist = (toPoint - ray.Direction * along).Magnitude
                if dist < bestDist then
                    best, bestDist = p, dist
                end
            end
        end
    end
    return best
end

AddConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if env.Destroyed or input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    local keyName = GetSelectKeyName()
    local ok, keyCode = pcall(function() return Enum.KeyCode[keyName] end)
    if not ok or not keyCode or not UserInputService:IsKeyDown(keyCode) then return end
    local target = GetPlayerUnderMouse()
    if not target then
        return CustomNotify("No player under the mouse", Color3.fromRGB(255, 180, 70))
    end
    local boxes = env.ToxNamedInputs or {}
    if AvatarItemsGui and AvatarItemsGui.Visible and AvatarItemsLoad then
        task.spawn(AvatarItemsLoad, target.Name)
    end
    for _, name in ipairs({ "Fling", "Teleport", "Spectate", "Up Player", "Avatar Items", "Magnet" }) do
        local box = boxes[name]
        if box and box.Parent then
            box.Text = target.Name
        end
    end
    CustomNotify("Selected • " .. target.DisplayName .. " (@" .. target.Name .. ")", Color3.fromRGB(100, 200, 255))
end))

do
    local Theme = env.Theme or {}
    local RegisterThemedObject = env.RegisterThemedObject or function() end
    local MarketplaceService = game:GetService("MarketplaceService")
    local AssetNameCache = {}
    local AssetPriceCache = {}

    local function DescribePrice(productInfo)
        if type(productInfo) ~= "table" then
            return { Text = "?", Robux = nil }
        end
        local price = tonumber(productInfo.PriceInRobux)
        local limited = productInfo.IsLimited or productInfo.IsLimitedUnique
            or (productInfo.CollectiblesItemDetails ~= nil)
        if productInfo.IsForSale and price then
            if price == 0 then
                return { Text = "Free", Robux = 0 }
            end
            return { Text = (limited and "Limited R$ " or "R$ ") .. price, Robux = price }
        end
        if productInfo.IsPublicDomain then
            return { Text = "Free", Robux = 0 }
        end
        return { Text = limited and "Limited (resale)" or "Off sale", Robux = nil }
    end

    local function Themed(obj, prop, key, fallback)
        obj[prop] = Theme[key] or fallback
        RegisterThemedObject(obj, prop, key)
    end
    local function Corner(obj, r)
        local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, r or 6) c.Parent = obj
    end
    local function Stroke(obj, key)
        local st = Instance.new("UIStroke") st.Thickness = 1 st.Transparency = 0.35
        st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        Themed(st, "Color", key or "Outline", Color3.fromRGB(60, 60, 80))
        st.Parent = obj
        return st
    end
    local function Button(text, size, pos, parent)
        local b = Instance.new("TextButton")
        b.Size = size b.Position = pos b.BorderSizePixel = 0 b.AutoButtonColor = true
        b.Text = text b.Font = Enum.Font.GothamBold b.TextSize = 10
        Themed(b, "BackgroundColor3", "Element", Color3.fromRGB(25, 30, 40))
        Themed(b, "TextColor3", "Text", Color3.new(1, 1, 1))
        Corner(b, 4) Stroke(b) b.Parent = parent
        return b
    end
    local function CopyText(text)
        local fn = setclipboard or toclipboard or (Clipboard and Clipboard.set)
        if fn then
            pcall(fn, text)
            return true
        end
        return false
    end

    local gui = Instance.new("Frame")
    gui.Name = "ToxAvatarItemsFrame"
    gui.Size = UDim2.new(0, 380, 0, 380)
    gui.Position = UDim2.new(0.5, -190, 0.5, -190)
    gui.BorderSizePixel = 0
    gui.ClipsDescendants = true
    gui.Visible = false
    Themed(gui, "BackgroundColor3", "Panel", Color3.fromRGB(15, 18, 26))
    gui.Parent = env.Gui
    Corner(gui, 8)
    local gStroke = Stroke(gui, "Accent") gStroke.Transparency = 0.25
    if env.ApplySavedGuiPosition then pcall(env.ApplySavedGuiPosition, "AvatarItems", gui) end
    if env.TrackGuiPosition then pcall(env.TrackGuiPosition, "AvatarItems", gui) end

    local top = Instance.new("Frame")
    top.Size = UDim2.new(1, 0, 0, 32) top.BorderSizePixel = 0
    Themed(top, "BackgroundColor3", "Element", Color3.fromRGB(25, 30, 40))
    top.Parent = gui
    if env.ToxRoundTopBar then env.ToxRoundTopBar(top) end
    if env.MakeDraggable then pcall(env.MakeDraggable, gui, top) end
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -40, 1, 0) title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1 title.Text = "Tox Avatar Items"
    title.Font = Enum.Font.GothamBold title.TextSize = 13 title.TextXAlignment = Enum.TextXAlignment.Left
    Themed(title, "TextColor3", "Text", Color3.new(1, 1, 1))
    title.Parent = top
    local close = Button("X", UDim2.new(0, 22, 0, 20), UDim2.new(1, -26, 0.5, -10), top)
    close.MouseButton1Click:Connect(function() gui.Visible = false end)

    local nameBox = Instance.new("TextBox")
    nameBox.Size = UDim2.new(1, -150, 0, 26) nameBox.Position = UDim2.new(0, 8, 0, 40)
    nameBox.BorderSizePixel = 0 nameBox.ClearTextOnFocus = false
    nameBox.PlaceholderText = "Player nick (or Select Player)"
    nameBox.Text = "" nameBox.Font = Enum.Font.Gotham nameBox.TextSize = 11
    Themed(nameBox, "BackgroundColor3", "Element", Color3.fromRGB(25, 30, 40))
    Themed(nameBox, "TextColor3", "Text", Color3.new(1, 1, 1))
    Corner(nameBox, 4) Stroke(nameBox) nameBox.Parent = gui
    env.ToxNamedInputs = env.ToxNamedInputs or {}
    env.ToxNamedInputs["Avatar Items"] = nameBox

    local loadBtn = Button("Load", UDim2.new(0, 64, 0, 26), UDim2.new(1, -138, 0, 40), gui)
    local copyAllBtn = Button("Copy All", UDim2.new(0, 64, 0, 26), UDim2.new(1, -70, 0, 40), gui)

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, -16, 0, 16) status.Position = UDim2.new(0, 8, 0, 100)
    status.BackgroundTransparency = 1 status.Font = Enum.Font.Gotham status.TextSize = 10
    status.TextXAlignment = Enum.TextXAlignment.Left status.Text = "Type a nick and press Load"
    Themed(status, "TextColor3", "DimText", Color3.fromRGB(160, 160, 180))
    status.Parent = gui

    local list = Instance.new("ScrollingFrame")
    list.Size = UDim2.new(1, -16, 1, -126) list.Position = UDim2.new(0, 8, 0, 118)
    list.BackgroundTransparency = 1 list.BorderSizePixel = 0
    list.ScrollBarThickness = 4 list.CanvasSize = UDim2.new()
    list.AutomaticCanvasSize = Enum.AutomaticSize.Y
    list.Parent = gui
    local layout = Instance.new("UIListLayout") layout.Padding = UDim.new(0, 4)
    layout.SortOrder = Enum.SortOrder.LayoutOrder layout.Parent = list

    local currentIds = {}
    local loadToken = 0

    local itemSource = "Server"
    local serverTab = Button("Server (now)", UDim2.new(0.5, -12, 0, 24), UDim2.new(0, 8, 0, 72), gui)
    local robloxTab = Button("Roblox (profile)", UDim2.new(0.5, -12, 0, 24), UDim2.new(0.5, 4, 0, 72), gui)
    local function PaintTabs()
        for _, pair in ipairs({ { serverTab, "Server" }, { robloxTab, "Roblox" } }) do
            local active = itemSource == pair[2]
            pair[1].BackgroundColor3 = active and (Theme.Accent or Color3.fromRGB(30, 95, 255)) or (Theme.Element or Color3.fromRGB(25, 30, 40))
            pair[1].TextColor3 = active and Color3.new(1, 1, 1) or (Theme.DimText or Color3.fromRGB(160, 160, 180))
        end
    end
    PaintTabs()

    local ACCESSORY_FIELDS = {
        { "HatAccessory", "Hat" }, { "HairAccessory", "Hair" }, { "FaceAccessory", "Face Acc." },
        { "NeckAccessory", "Neck" }, { "ShouldersAccessory", "Shoulders" }, { "FrontAccessory", "Front" },
        { "BackAccessory", "Back" }, { "WaistAccessory", "Waist" },
    }
    local SINGLE_FIELDS = {
        { "Shirt", "Shirt" }, { "Pants", "Pants" }, { "GraphicTShirt", "T-Shirt" }, { "Face", "Face" },
        { "Head", "Head" }, { "Torso", "Torso" }, { "LeftArm", "Left Arm" }, { "RightArm", "Right Arm" },
        { "LeftLeg", "Left Leg" }, { "RightLeg", "Right Leg" },
        { "IdleAnimation", "Idle Anim" }, { "WalkAnimation", "Walk Anim" }, { "RunAnimation", "Run Anim" },
        { "JumpAnimation", "Jump Anim" }, { "FallAnimation", "Fall Anim" }, { "ClimbAnimation", "Climb Anim" },
        { "SwimAnimation", "Swim Anim" },
    }

    local function CollectItems(target, source)
        local items, seen = {}, {}
        local function add(id, kind)
            id = tonumber(id)
            if id and id > 0 and not seen[id] then
                seen[id] = true
                table.insert(items, { Id = id, Kind = kind })
            end
        end
        local desc = nil
        if source == "Roblox" then
            pcall(function() desc = Players:GetHumanoidDescriptionFromUserId(target.UserId) end)
        else
            local hum = target.Character and target.Character:FindFirstChildOfClass("Humanoid")
            if hum then pcall(function() desc = hum:GetAppliedDescription() end) end
        end
        if not desc then return items end
        for _, f in ipairs(ACCESSORY_FIELDS) do
            for id in string.gmatch(tostring(desc[f[1]] or ""), "%d+") do add(id, f[2]) end
        end
        pcall(function()
            for _, acc in ipairs(desc:GetAccessories(true)) do
                add(acc.AssetId, tostring(acc.AccessoryType.Name))
            end
        end)
        for _, f in ipairs(SINGLE_FIELDS) do
            local ok, value = pcall(function() return desc[f[1]] end)
            if ok then add(value, f[2]) end
        end
        return items
    end

    local function MakeRow(item, order, onPrice)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -6, 0, 46) row.BorderSizePixel = 0 row.LayoutOrder = order
        Themed(row, "BackgroundColor3", "Element", Color3.fromRGB(25, 30, 40))
        Corner(row, 6) row.Parent = list

        local thumb = Instance.new("ImageLabel")
        thumb.Size = UDim2.new(0, 38, 0, 38) thumb.Position = UDim2.new(0, 4, 0.5, -19)
        thumb.BackgroundTransparency = 1
        thumb.Image = "rbxthumb://type=Asset&id=" .. item.Id .. "&w=150&h=150"
        Corner(thumb, 4) thumb.Parent = row

        local name = Instance.new("TextLabel")
        name.Size = UDim2.new(1, -130, 0, 18) name.Position = UDim2.new(0, 48, 0, 5)
        name.BackgroundTransparency = 1 name.Font = Enum.Font.GothamMedium name.TextSize = 11
        name.TextXAlignment = Enum.TextXAlignment.Left name.TextTruncate = Enum.TextTruncate.AtEnd
        name.Text = AssetNameCache[item.Id] or "Loading..."
        Themed(name, "TextColor3", "Text", Color3.new(1, 1, 1))
        name.Parent = row

        local info = Instance.new("TextLabel")
        info.Size = UDim2.new(1, -130, 0, 14) info.Position = UDim2.new(0, 48, 0, 25)
        info.BackgroundTransparency = 1 info.Font = Enum.Font.Gotham info.TextSize = 10
        info.TextXAlignment = Enum.TextXAlignment.Left
        local function InfoText()
            local price = AssetPriceCache[item.Id]
            return item.Kind .. " • " .. item.Id .. " • " .. (price and price.Text or "...")
        end
        info.Text = InfoText()
        Themed(info, "TextColor3", "DimText", Color3.fromRGB(160, 160, 180))
        info.Parent = row

        local copy = Button("Copy ID", UDim2.new(0, 70, 0, 24), UDim2.new(1, -76, 0.5, -12), row)
        copy.MouseButton1Click:Connect(function()
            if CopyText(tostring(item.Id)) then
                CustomNotify("Copied ID " .. item.Id, Color3.fromRGB(100, 255, 130))
            else
                CustomNotify("Your executor can't copy to clipboard", Color3.fromRGB(255, 120, 120))
            end
        end)

        if AssetNameCache[item.Id] and AssetPriceCache[item.Id] then
            if onPrice then onPrice(AssetPriceCache[item.Id]) end
        else
            task.spawn(function()
                local ok, info2 = pcall(function()
                    return MarketplaceService:GetProductInfo(item.Id, Enum.InfoType.Asset)
                end)
                local label = (ok and info2 and info2.Name) or ("Asset " .. item.Id)
                AssetNameCache[item.Id] = label
                AssetPriceCache[item.Id] = DescribePrice(ok and info2 or nil)
                if name.Parent then name.Text = label end
                if info.Parent then info.Text = InfoText() end
                if onPrice then onPrice(AssetPriceCache[item.Id]) end
            end)
        end
    end

    AvatarItemsLoad = function(text)
        text = tostring(text or nameBox.Text)
        local target = FindPlayerByInput(text)
        if not target and string.lower(text) == string.lower(Player.Name) then
            target = Player
        end
        if not target then
            status.Text = "Player not found"
            return
        end
        nameBox.Text = target.Name
        loadToken = loadToken + 1
        local token = loadToken
        for _, child in ipairs(list:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end
        currentIds = {}
        local source = itemSource
        status.Text = "Loading " .. (source == "Roblox" and "Roblox avatar" or "server skin") .. " of " .. target.DisplayName .. "..."
        task.spawn(function()
            local items = CollectItems(target, source)
            if token ~= loadToken then return end
            local where = source == "Roblox" and "Roblox" or "Server"
            local baseText = (#items > 0)
                and (where .. " • " .. #items .. " items • " .. target.DisplayName)
                or (where .. " • no items found for " .. target.DisplayName)
            status.Text = baseText
            local total, priced, offSale = 0, 0, 0
            local function OnPrice(price)
                if token ~= loadToken then return end
                priced += 1
                if price and price.Robux then
                    total += price.Robux
                else
                    offSale += 1
                end
                status.Text = baseText .. " • Total R$ " .. total
                    .. (offSale > 0 and (" (+" .. offSale .. " off sale)") or "")
                    .. (priced < #items and " ..." or "")
            end
            for index, item in ipairs(items) do
                table.insert(currentIds, tostring(item.Id))
                MakeRow(item, index, OnPrice)
            end
        end)
    end

    loadBtn.MouseButton1Click:Connect(function() AvatarItemsLoad(nameBox.Text) end)
    serverTab.MouseButton1Click:Connect(function()
        itemSource = "Server"
        PaintTabs()
        if nameBox.Text ~= "" then AvatarItemsLoad(nameBox.Text) end
    end)
    robloxTab.MouseButton1Click:Connect(function()
        itemSource = "Roblox"
        PaintTabs()
        if nameBox.Text ~= "" then AvatarItemsLoad(nameBox.Text) end
    end)
    nameBox.FocusLost:Connect(function(enter) if enter then AvatarItemsLoad(nameBox.Text) end end)
    copyAllBtn.MouseButton1Click:Connect(function()
        if #currentIds == 0 then
            return CustomNotify("Load a player first", Color3.fromRGB(255, 180, 70))
        end
        if CopyText(table.concat(currentIds, "\n")) then
            CustomNotify("Copied " .. #currentIds .. " IDs", Color3.fromRGB(100, 255, 130))
        else
            CustomNotify("Your executor can't copy to clipboard", Color3.fromRGB(255, 120, 120))
        end
    end)

    if env.MakeResizable then pcall(env.MakeResizable, gui, "AvatarItems", Vector2.new(300, 240), Vector2.new(1000, 1400)) end
    AvatarItemsGui = gui
    env.ToxAvatarItemsGui = gui
    env.ToxAvatarItemsLoad = AvatarItemsLoad

    if env.ToxLinkedSubGuis then
        env.ToxLinkedSubGuis.AvatarItems = nil
    end
    task.spawn(function()
        local minimizeDone, mainHooked = false, false
        for _ = 1, 100 do
            if env.Destroyed then return end
            if not minimizeDone and env.RegisterToxSubGuiMinimize then
                pcall(env.RegisterToxSubGuiMinimize, gui, -52)
                minimizeDone = true
            end
            local main = env.Main
            if not mainHooked and main then
                mainHooked = true
                local reopenWithMain = false
                AddConnection(main:GetPropertyChangedSignal("Visible"):Connect(function()
                    if env.Destroyed then return end
                    if not main.Visible then
                        if gui.Visible then
                            reopenWithMain = true
                            gui.Visible = false
                        end
                    elseif reopenWithMain then
                        reopenWithMain = false
                        gui.Visible = true
                    end
                end))
            end
            if minimizeDone and mainHooked then return end
            task.wait(0.2)
        end
    end)
end
CreateButton("Tox Music Player", FlingPage, function() MusicGui.Visible = not MusicGui.Visible end)
CreateButton("Tox Waypoints", FlingPage, function() WaypointsGui.Visible = not WaypointsGui.Visible end)
CreateButton("Tox Avatar Items", FlingPage, function()
    if AvatarItemsGui then
        AvatarItemsGui.Visible = not AvatarItemsGui.Visible
    end
end)
do
    local SCRIPTS_BASE = "https://raw.githubusercontent.com/BG-0o/Scripts/refs/heads/main/Scripts/"
    local function RunCommunityScript(label, relFile)
        local ok, err = pcall(function()
            local cacheBuster = "?toxcache=" .. tostring(os.time()) .. "_" .. tostring(math.random(1000, 999999))
            local src = game:HttpGet(SCRIPTS_BASE .. relFile .. cacheBuster)
            local chunk, compErr = loadstring(src)
            if not chunk then
                error(tostring(compErr or "compile error"))
            end
            chunk()
        end)
        if not ok then
            CustomNotify("Failed to load " .. label .. ": " .. tostring(err), Color3.fromRGB(255, 95, 95), 4)
        end
    end

    if getgenv().CreateSection then getgenv().CreateSection(ScriptsPage, "Community Scripts", "📜") end
    CreateButton("BigFroot", ScriptsPage, function()
        RunCommunityScript("BigFroot", "BigFroot.lua")
    end)
    CreateButton("FE Emotes", ScriptsPage, function()
        RunCommunityScript("FE Emotes", "FEEmotes.lua")
    end)
    CreateButton("PShade", ScriptsPage, function()
        RunCommunityScript("PShade", "PShade.lua")
    end)
    CreateButton("Infinite Yield", ScriptsPage, function()
        RunCommunityScript("Infinite Yield", "InfiniteYield.lua")
    end)
    CreateButton("Bundle Edit", ScriptsPage, function()
        RunCommunityScript("Bundle Edit", "BundleEdit.lua")
    end)
    if getgenv().ClearActivePageCard then
        pcall(getgenv().ClearActivePageCard, ScriptsPage)
    end
end
task.spawn(function()
    if getgenv().ScriptsPage then
        local function RunSaveGame(decompile)
            local modeText = decompile and " (Decompiled Scripts)" or " (Standard)"
            CustomNotify("Starting Save Game" .. modeText .. "...", Color3.fromRGB(218, 170, 42))
            task.spawn(function()
                local ok, err = pcall(function()
                    local SaveInstance = saveinstance or (getgenv and getgenv().saveinstance)
                    if not SaveInstance then
                        SaveInstance = loadstring(game:HttpGet("https://raw.githubusercontent.com/luau/UniversalSynSaveInstance/main/saveinstance.lua"))()
                        if type(SaveInstance) == "table" and SaveInstance.Save then
                            SaveInstance = SaveInstance.Save
                        end
                    end
                    if type(SaveInstance) == "function" then
                        if decompile then
                            SaveInstance({Decompile = true, DecompileTimeout = 10})
                        else
                            SaveInstance()
                        end
                    else
                        error("saveinstance API not supported by executor")
                    end
                end)
                if ok then
                    CustomNotify("Save Game completed successfully!", Color3.fromRGB(50, 220, 90))
                else
                    CustomNotify("Save Game failed: " .. tostring(err), Color3.fromRGB(255, 80, 80))
                end
            end)
        end
        if getgenv().CreateSection then getgenv().CreateSection(getgenv().ScriptsPage, "Save Game & World", "💾") end
        CreateButton("Save Place (Standard)", getgenv().ScriptsPage, function() RunSaveGame(false) end)
        CreateButton("Save Place (Decompile Scripts)", getgenv().ScriptsPage, function() RunSaveGame(true) end)
        if getgenv().ClearActivePageCard then
            pcall(getgenv().ClearActivePageCard, getgenv().ScriptsPage)
        end
    end
end)
