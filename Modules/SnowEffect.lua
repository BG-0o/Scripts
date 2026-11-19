local env = getgenv()
local Settings = env.Settings or {}
local RunService = game:GetService("RunService")

if env.ToxSnowCleanup then
    pcall(env.ToxSnowCleanup)
end

local Gui = env.Gui
local Main = env.Main
if not Gui or not Main then
    return
end

local VALID_MODES = { Off = true, Screen = true, UI = true, Both = true }
if not VALID_MODES[tostring(Settings.ToxSnowMode)] then
    Settings.ToxSnowMode = "Off"
end

local SCREEN_FLAKES = 70
local UI_FLAKES = 35
local MAX_STUCK = 140
local BUCKET = 5

local Overlay = Instance.new("ScreenGui")
Overlay.Name = "ToxSnow"
Overlay.ResetOnSpawn = false
Overlay.IgnoreGuiInset = Gui.IgnoreGuiInset
Overlay.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Overlay.DisplayOrder = (tonumber(Gui.DisplayOrder) or 0) - 1
Overlay.Enabled = false
Overlay.Parent = Gui.Parent

local UIClip = Instance.new("Frame")
UIClip.Name = "ToxSnowClip"
UIClip.BackgroundTransparency = 1
UIClip.Size = UDim2.new(1, 0, 1, 0)
UIClip.ClipsDescendants = true
UIClip.ZIndex = 1000
UIClip.Active = false
UIClip.Visible = false
UIClip.Parent = Main

local function NewFlakeFrame(parent)
    local f = Instance.new("Frame")
    f.BorderSizePixel = 0
    f.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    f.Active = false
    f.ZIndex = 1000
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(1, 0)
    c.Parent = f
    f.Parent = parent
    return f
end

local function Respawn(flake, width, height, fromTop)
    flake.X = math.random() * width
    flake.Y = fromTop and (-math.random() * 40) or (math.random() * height)
    flake.Size = math.random(2, 5)
    flake.VY = 25 + flake.Size * 12 + math.random() * 20
    flake.VX = 0
    flake.Phase = math.random() * math.pi * 2
    flake.Sway = 8 + math.random() * 18
    flake.Frame.Size = UDim2.fromOffset(flake.Size, flake.Size)
    flake.Frame.BackgroundTransparency = 0.05 + (5 - flake.Size) * 0.12
end

local ScreenFlakes = {}
local UIFlakes = {}
local Stuck = {}
local PileHeight = {}
local LooseFlakes = {}

for _ = 1, SCREEN_FLAKES do
    table.insert(ScreenFlakes, { Frame = NewFlakeFrame(Overlay) })
end
for _ = 1, UI_FLAKES do
    table.insert(UIFlakes, { Frame = NewFlakeFrame(UIClip) })
end

local function ScreenSize()
    local cam = workspace.CurrentCamera
    local v = cam and cam.ViewportSize or Vector2.new(1280, 720)
    return v.X, v.Y
end

local function ResetAll()
    local w, h = ScreenSize()
    for _, f in ipairs(ScreenFlakes) do
        Respawn(f, w, h, false)
    end
    local uw, uh = UIClip.AbsoluteSize.X, UIClip.AbsoluteSize.Y
    for _, f in ipairs(UIFlakes) do
        Respawn(f, math.max(uw, 1), math.max(uh, 1), false)
    end
end

local function ReleaseStuck(pushX)
    for _, s in ipairs(Stuck) do
        table.insert(LooseFlakes, {
            Frame = s.Frame,
            X = s.Frame.AbsolutePosition.X,
            Y = s.Frame.AbsolutePosition.Y,
            VX = (pushX or 0) * (0.3 + math.random() * 0.4) + (math.random() - 0.5) * 30,
            VY = math.random() * 20,
            Size = s.Size,
        })
    end
    table.clear(Stuck)
    table.clear(PileHeight)
end

local function ClearLoose()
    for _, l in ipairs(LooseFlakes) do
        pcall(function() l.Frame:Destroy() end)
    end
    table.clear(LooseFlakes)
end

local function StickFlake(flake, relX)
    if #Stuck >= MAX_STUCK then
        return false
    end
    local bucket = math.floor(relX / BUCKET)
    local height = PileHeight[bucket] or 0
    if height > 10 then
        return false
    end
    local frame = NewFlakeFrame(Overlay)
    frame.Size = UDim2.fromOffset(flake.Size, flake.Size)
    frame.BackgroundTransparency = flake.Frame.BackgroundTransparency
    table.insert(Stuck, { Frame = frame, RelX = relX, Lift = height + flake.Size * 0.6, Size = flake.Size })
    PileHeight[bucket] = height + flake.Size * 0.6
    return true
end

local lastMainPos = nil
local lastMainTime = os.clock()
local running = false
local Connection = nil

local function Step(dt)
    if env.Destroyed or not Main.Parent then
        if env.ToxSnowCleanup then
            pcall(env.ToxSnowCleanup)
        end
        return
    end
    dt = math.min(dt, 0.1)
    local mode = Settings.ToxSnowMode
    local mainVisible = Main.Visible and Main.Parent ~= nil
    local wantScreen = (mode == "Screen" or mode == "Both") and mainVisible
    local wantUI = (mode == "UI" or mode == "Both") and mainVisible
    Overlay.Enabled = wantScreen or #LooseFlakes > 0
    UIClip.Visible = wantUI
    local t = os.clock()

    local mainPos = Main.AbsolutePosition
    local mainSize = Main.AbsoluteSize
    local moved = Vector2.zero
    if lastMainPos then
        moved = mainPos - lastMainPos
    end
    lastMainPos = mainPos
    if (moved.Magnitude > 0.5 or not wantScreen) and #Stuck > 0 then
        ReleaseStuck(moved.X / math.max(dt, 1 / 240))
    end

    if wantScreen then
        local w, h = ScreenSize()
        local top = mainPos.Y
        local left, right = mainPos.X + 6, mainPos.X + mainSize.X - 6
        for _, f in ipairs(ScreenFlakes) do
            local prevY = f.Y
            f.Y += f.VY * dt
            local x = f.X + math.sin(t * 1.3 + f.Phase) * f.Sway
            if prevY + f.Size <= top and f.Y + f.Size >= top and x >= left and x <= right then
                StickFlake(f, x - mainPos.X)
                Respawn(f, w, h, true)
            elseif f.Y > h + 10 then
                Respawn(f, w, h, true)
            else
                f.Frame.Position = UDim2.fromOffset(x, f.Y)
            end
        end
        for _, s in ipairs(Stuck) do
            s.Frame.Position = UDim2.fromOffset(mainPos.X + s.RelX - s.Size / 2, mainPos.Y - s.Lift - s.Size * 0.4)
        end
    else
        for _, f in ipairs(ScreenFlakes) do
            f.Frame.Position = UDim2.fromOffset(-50, -50)
        end
    end

    if #LooseFlakes > 0 then
        local _, h = ScreenSize()
        for i = #LooseFlakes, 1, -1 do
            local l = LooseFlakes[i]
            l.VY += 220 * dt
            l.VX *= (1 - math.min(dt * 2, 0.5))
            l.X += l.VX * dt
            l.Y += l.VY * dt
            if l.Y > h + 10 then
                pcall(function() l.Frame:Destroy() end)
                table.remove(LooseFlakes, i)
            else
                l.Frame.Position = UDim2.fromOffset(l.X, l.Y)
            end
        end
    end

    if wantUI then
        local uw, uh = UIClip.AbsoluteSize.X, UIClip.AbsoluteSize.Y
        for _, f in ipairs(UIFlakes) do
            f.Y += f.VY * 0.6 * dt
            if f.Y > uh + 6 then
                Respawn(f, math.max(uw, 1), math.max(uh, 1), true)
            end
            local x = f.X + math.sin(t * 1.1 + f.Phase) * f.Sway
            f.Frame.Position = UDim2.fromOffset(x, f.Y)
        end
    end
end

local function SetRunning(on)
    if on and not running then
        running = true
        ResetAll()
        lastMainPos = nil
        Connection = RunService.RenderStepped:Connect(Step)
    elseif not on and running then
        running = false
        if Connection then
            Connection:Disconnect()
            Connection = nil
        end
        ReleaseStuck(0)
        ClearLoose()
        Overlay.Enabled = false
        UIClip.Visible = false
    end
end

env.SetToxSnowMode = function(mode, skipSave)
    mode = tostring(mode)
    if not VALID_MODES[mode] then
        mode = "Off"
    end
    Settings.ToxSnowMode = mode
    SetRunning(mode ~= "Off")
    if not skipSave and env.AutoSaveConfiguration then
        env.AutoSaveConfiguration()
    end
end

env.ToxSnowCleanup = function()
    SetRunning(false)
    pcall(function() Overlay:Destroy() end)
    pcall(function() UIClip:Destroy() end)
end

env.SetToxSnowMode(Settings.ToxSnowMode, true)
