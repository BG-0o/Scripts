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
local Surfaces = {}
local SurfaceLastPos = {}
local lastSurfaceScan = 0

local function RefreshSurfaces(w, h)
    local now = os.clock()
    if now - lastSurfaceScan < 0.5 then
        return
    end
    lastSurfaceScan = now
    table.clear(Surfaces)
    if Main.Visible then
        table.insert(Surfaces, Main)
    end
    for _, child in ipairs(Gui:GetChildren()) do
        if child ~= Main and child:IsA("Frame") and child.Visible then
            local size = child.AbsoluteSize
            if size.X >= 150 and size.Y >= 80
            and size.X < w * 0.9 and size.Y < h * 0.9
            and child.BackgroundTransparency < 0.99 then
                table.insert(Surfaces, child)
            end
        end
    end
end

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

local function ReleaseStuck(pushX, surface)
    for i = #Stuck, 1, -1 do
        local s = Stuck[i]
        if surface == nil or s.Surface == surface then
        table.remove(Stuck, i)
        table.insert(LooseFlakes, {
            Frame = s.Frame,
            X = s.Frame.AbsolutePosition.X,
            Y = s.Frame.AbsolutePosition.Y,
            VX = (pushX or 0) * (0.3 + math.random() * 0.4) + (math.random() - 0.5) * 30,
            VY = math.random() * 20,
            Size = s.Size,
        })
        end
    end
    if surface == nil then
        table.clear(PileHeight)
    else
        PileHeight[surface] = nil
    end
end

local function ClearLoose()
    for _, l in ipairs(LooseFlakes) do
        pcall(function() l.Frame:Destroy() end)
    end
    table.clear(LooseFlakes)
end

local function StickFlake(flake, relX, surface)
    if #Stuck >= MAX_STUCK then
        return false
    end
    local bucket = math.floor(relX / BUCKET)
    PileHeight[surface] = PileHeight[surface] or {}
    local piles = PileHeight[surface]
    local height = piles[bucket] or 0
    if height > 10 then
        return false
    end
    local frame = NewFlakeFrame(Overlay)
    frame.Size = UDim2.fromOffset(flake.Size, flake.Size)
    frame.BackgroundTransparency = flake.Frame.BackgroundTransparency
    table.insert(Stuck, { Frame = frame, RelX = relX, Lift = height + flake.Size * 0.6, Size = flake.Size, Surface = surface })
    piles[bucket] = height + flake.Size * 0.6
    return true
end

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

    local w, h = ScreenSize()
    if wantScreen then
        RefreshSurfaces(w, h)
    else
        table.clear(Surfaces)
    end
    local active = {}
    for _, surface in ipairs(Surfaces) do
        if surface.Parent and surface.Visible then
            active[surface] = true
        end
    end
    for surface, lastPos in pairs(SurfaceLastPos) do
        if not active[surface] then
            ReleaseStuck(0, surface)
            SurfaceLastPos[surface] = nil
        end
    end
    for surface in pairs(active) do
        local pos = surface.AbsolutePosition
        local last = SurfaceLastPos[surface]
        if last and (pos - last).Magnitude > 0.5 then
            ReleaseStuck((pos - last).X / math.max(dt, 1 / 240), surface)
        end
        SurfaceLastPos[surface] = pos
    end
    if not wantScreen and #Stuck > 0 then
        ReleaseStuck(0)
    end

    if wantScreen then
        for _, f in ipairs(ScreenFlakes) do
            local prevY = f.Y
            f.Y += f.VY * dt
            local x = f.X + math.sin(t * 1.3 + f.Phase) * f.Sway
            local landed = false
            for surface in pairs(active) do
                local pos, size = surface.AbsolutePosition, surface.AbsoluteSize
                local top = pos.Y
                if prevY + f.Size <= top and f.Y + f.Size >= top and x >= pos.X + 6 and x <= pos.X + size.X - 6 then
                    StickFlake(f, x - pos.X, surface)
                    landed = true
                    break
                end
            end
            if landed or f.Y > h + 10 then
                Respawn(f, w, h, true)
            else
                f.Frame.Position = UDim2.fromOffset(x, f.Y)
            end
        end
        for _, st in ipairs(Stuck) do
            local pos = st.Surface.AbsolutePosition
            st.Frame.Position = UDim2.fromOffset(pos.X + st.RelX - st.Size / 2, pos.Y - st.Lift - st.Size * 0.4)
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
        table.clear(SurfaceLastPos)
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
