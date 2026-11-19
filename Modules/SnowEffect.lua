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
if Settings.ToxThemeDecor == nil then
    Settings.ToxThemeDecor = true
end

local function rgb(r, g, b)
    return Color3.fromRGB(r, g, b)
end

local Seasons = {
    Christmas = {
        Kind = "dot", Pile = true, Direction = 1,
        Colors = { rgb(255, 255, 255) },
        Bulbs = { rgb(239, 68, 68), rgb(34, 197, 94), rgb(250, 204, 21), rgb(59, 130, 246) },
        Corner = "🎄",
        Extra = "Santa",
    },
    Halloween = {
        Kind = "emoji", Pile = false, Direction = 1,
        Emojis = { "🍂", "🍂", "🍁", "🦇", "👻" },
        Corner = "🎃",
        Extra = "Spider",
    },
    Easter = {
        Kind = "emoji", Pile = false, Direction = 1,
        Emojis = { "🌸", "🌸", "🌼", "🥚" },
        Corner = "🥚",
        Extra = "Bunny",
    },
    ["New Year"] = {
        Kind = "confetti", Pile = true, Direction = 1,
        Colors = { rgb(250, 204, 21), rgb(229, 231, 235), rgb(253, 224, 71), rgb(245, 158, 11) },
        Corner = "🎆",
        Extra = "Sparkles",
    },
    ["St. Patrick's"] = {
        Kind = "emoji", Pile = false, Direction = 1,
        Emojis = { "🍀", "🍀", "☘️", "💰" },
        Corner = "🍀",
        Extra = "Rainbow",
    },
    ["Valentine's"] = {
        Kind = "emoji", Pile = false, Direction = -1,
        Emojis = { "❤️", "💕", "💖", "💘" },
        Corner = "💘",
        Extra = nil,
    },
    Carnaval = {
        Kind = "confetti", Pile = true, Direction = 1,
        Colors = { rgb(236, 72, 153), rgb(250, 204, 21), rgb(34, 197, 94), rgb(59, 130, 246), rgb(168, 85, 247) },
        Corner = "🎭",
        Extra = nil,
    },
}
local DefaultSeason = { Kind = "dot", Pile = true, Direction = 1, Colors = { rgb(255, 255, 255) } }
env.ToxSeasonalThemes = Seasons

local SCREEN_FLAKES = 70
local UI_FLAKES = 35
local MAX_STUCK = 160
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

local DecorFolder = Instance.new("Frame")
DecorFolder.Name = "ToxThemeDecor"
DecorFolder.BackgroundTransparency = 1
DecorFolder.Size = UDim2.new(1, 0, 1, 0)
DecorFolder.ZIndex = 1001
DecorFolder.Active = false
DecorFolder.Visible = false
DecorFolder.Parent = Main

local Season = DefaultSeason

local function CurrentSeason()
    return Seasons[tostring(Settings.ToxUITheme)]
end

local function NewParticleFrame(parent)
    local kind = Season.Kind
    local f
    if kind == "emoji" then
        f = Instance.new("TextLabel")
        f.BackgroundTransparency = 1
        f.Font = Enum.Font.GothamBold
        f.TextScaled = true
        f.Text = Season.Emojis[math.random(1, #Season.Emojis)]
    else
        f = Instance.new("Frame")
        f.BorderSizePixel = 0
        local colors = Season.Colors or DefaultSeason.Colors
        f.BackgroundColor3 = colors[math.random(1, #colors)]
        if kind == "dot" then
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(1, 0)
            c.Parent = f
        end
    end
    f.Active = false
    f.ZIndex = 1000
    f.Parent = parent
    return f
end

local function Respawn(p, width, height, fromEdge)
    local kind = Season.Kind
    local dir = Season.Direction or 1
    p.X = math.random() * width
    if fromEdge then
        p.Y = dir > 0 and (-math.random() * 40) or (height + math.random() * 40)
    else
        p.Y = math.random() * height
    end
    if kind == "emoji" then
        p.Size = math.random(14, 22)
        p.VY = (30 + math.random() * 35) * dir
        p.Frame.Text = Season.Emojis[math.random(1, #Season.Emojis)]
        p.Frame.TextTransparency = 0.1 + math.random() * 0.25
        p.Spin = (math.random() - 0.5) * 120
    elseif kind == "confetti" then
        p.Size = math.random(3, 6)
        p.VY = (45 + math.random() * 45) * dir
        local colors = Season.Colors
        p.Frame.BackgroundColor3 = colors[math.random(1, #colors)]
        p.Frame.BackgroundTransparency = 0.05
        p.Spin = (math.random() - 0.5) * 540
    else
        p.Size = math.random(2, 5)
        p.VY = (25 + p.Size * 12 + math.random() * 20) * dir
        p.Frame.BackgroundTransparency = 0.05 + (5 - p.Size) * 0.12
        p.Spin = 0
    end
    p.Rot = math.random() * 360
    p.Phase = math.random() * math.pi * 2
    p.Sway = 8 + math.random() * 18
    if kind == "confetti" then
        p.Frame.Size = UDim2.fromOffset(p.Size, p.Size * 1.8)
    else
        p.Frame.Size = UDim2.fromOffset(p.Size, p.Size)
    end
end

local ScreenFlakes = {}
local UIFlakes = {}
local Stuck = {}
local PileHeight = {}
local LooseFlakes = {}
local Surfaces = {}
local SurfaceLastPos = {}
local lastSurfaceScan = 0

local function ScreenSize()
    local cam = workspace.CurrentCamera
    local v = cam and cam.ViewportSize or Vector2.new(1280, 720)
    return v.X, v.Y
end

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

local function ClearParticles()
    for _, list in ipairs({ ScreenFlakes, UIFlakes }) do
        for _, p in ipairs(list) do
            pcall(function() p.Frame:Destroy() end)
        end
        table.clear(list)
    end
end

local function BuildParticles()
    ClearParticles()
    local w, h = ScreenSize()
    for _ = 1, SCREEN_FLAKES do
        local p = { Frame = NewParticleFrame(Overlay) }
        Respawn(p, w, h, false)
        table.insert(ScreenFlakes, p)
    end
    local uw, uh = math.max(UIClip.AbsoluteSize.X, 1), math.max(UIClip.AbsoluteSize.Y, 1)
    for _ = 1, UI_FLAKES do
        local p = { Frame = NewParticleFrame(UIClip) }
        Respawn(p, uw, uh, false)
        table.insert(UIFlakes, p)
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

local function StickFlake(p, relX, surface)
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
    local frame = p.Frame:Clone()
    frame.Rotation = Season.Kind == "confetti" and (math.random(0, 1) * 90) or 0
    frame.Parent = Overlay
    local lift = height + p.Size * 0.6
    table.insert(Stuck, { Frame = frame, RelX = relX, Lift = lift, Size = p.Size, Surface = surface })
    piles[bucket] = lift
    return true
end

local Decor = {}
local function ClearDecor()
    for _, child in ipairs(DecorFolder:GetChildren()) do
        child:Destroy()
    end
    table.clear(Decor)
end

local function DecorLabel(text, size, position, rotation)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextScaled = true
    l.Font = Enum.Font.GothamBold
    l.Size = UDim2.fromOffset(size, size)
    l.Position = position
    l.Rotation = rotation or 0
    l.ZIndex = 1002
    l.Active = false
    l.Parent = DecorFolder
    return l
end

local function BuildDecor()
    ClearDecor()
    local season = CurrentSeason()
    if not season or Settings.ToxThemeDecor == false then
        DecorFolder.Visible = false
        return
    end
    DecorFolder.Visible = true

    if season.Bulbs then
        local wire = Instance.new("Frame")
        wire.BorderSizePixel = 0
        wire.BackgroundColor3 = rgb(30, 30, 30)
        wire.BackgroundTransparency = 0.6
        wire.Size = UDim2.new(1, -40, 0, 1)
        wire.Position = UDim2.new(0, 20, 0, -1)
        wire.ZIndex = 1001
        wire.Parent = DecorFolder
        Decor.Bulbs = {}
        local count = 12
        for i = 1, count do
            local bulb = Instance.new("Frame")
            bulb.BorderSizePixel = 0
            bulb.Size = UDim2.fromOffset(4, 6)
            bulb.AnchorPoint = Vector2.new(0.5, 0)
            bulb.Position = UDim2.new((i - 0.5) / count, 0, 0, (i % 2 == 0) and 2 or 0)
            bulb.BackgroundColor3 = season.Bulbs[(i - 1) % #season.Bulbs + 1]
            bulb.ZIndex = 1002
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(1, 0)
            c.Parent = bulb
            local glow = Instance.new("UIStroke")
            glow.Color = bulb.BackgroundColor3
            glow.Thickness = 1
            glow.Transparency = 0.5
            glow.Parent = bulb
            bulb.Parent = wire
            table.insert(Decor.Bulbs, { Frame = bulb, Glow = glow, Offset = i })
        end
    end

    if season.Corner then
        Decor.Corner = DecorLabel(season.Corner, 30, UDim2.new(0, -14, 0, -20), -18)
    end

    if season.Extra == "Santa" then
        Decor.Extra = DecorLabel("🎅", 30, UDim2.new(1, -18, 0, -22), 15)
    elseif season.Extra == "Spider" then
        local thread = Instance.new("Frame")
        thread.BorderSizePixel = 0
        thread.BackgroundColor3 = rgb(220, 220, 220)
        thread.BackgroundTransparency = 0.3
        thread.Size = UDim2.fromOffset(1, 40)
        thread.Position = UDim2.new(1, -60, 0, 0)
        thread.ZIndex = 1002
        thread.Parent = DecorFolder
        local spider = DecorLabel("🕷️", 22, UDim2.new(1, -71, 0, 36), 0)
        DecorLabel("🕸️", 34, UDim2.new(1, -26, 0, -8), 0)
        Decor.Thread = thread
        Decor.Spider = spider
    elseif season.Extra == "Bunny" then
        Decor.Bunny = DecorLabel("🐰", 32, UDim2.new(1, -60, 0, -26), 0)
    elseif season.Extra == "Sparkles" then
        Decor.Sparkles = {
            DecorLabel("✨", 20, UDim2.new(1, -30, 0, -16), 0),
            DecorLabel("🥂", 24, UDim2.new(1, -60, 0, -20), 10),
        }
    elseif season.Extra == "Rainbow" then
        local bar = Instance.new("Frame")
        bar.BorderSizePixel = 0
        bar.BackgroundColor3 = rgb(255, 255, 255)
        bar.Size = UDim2.new(1, -24, 0, 3)
        bar.Position = UDim2.new(0, 12, 0, 0)
        bar.ZIndex = 1002
        bar.Parent = DecorFolder
        local g = Instance.new("UIGradient")
        g.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, rgb(239, 68, 68)),
            ColorSequenceKeypoint.new(0.2, rgb(249, 115, 22)),
            ColorSequenceKeypoint.new(0.4, rgb(250, 204, 21)),
            ColorSequenceKeypoint.new(0.6, rgb(34, 197, 94)),
            ColorSequenceKeypoint.new(0.8, rgb(59, 130, 246)),
            ColorSequenceKeypoint.new(1, rgb(168, 85, 247)),
        })
        g.Parent = bar
        Decor.Rainbow = g
        Decor.Pot = DecorLabel("💰", 24, UDim2.new(1, -30, 0, -18), 0)
    end
end

local function AnimateDecor(t)
    if not DecorFolder.Visible then
        return
    end
    if Decor.Bulbs then
        for _, b in ipairs(Decor.Bulbs) do
            local on = math.sin(t * 1.2 + b.Offset * 1.7) > -0.2
            b.Frame.BackgroundTransparency = on and 0.15 or 0.55
            b.Glow.Transparency = on and 0.6 or 0.95
        end
    end
    if Decor.Corner then
        Decor.Corner.Rotation = -18 + math.sin(t * 1.5) * 6
    end
    if Decor.Spider and Decor.Thread then
        local len = 34 + math.sin(t * 0.9) * 16
        Decor.Thread.Size = UDim2.fromOffset(1, len)
        Decor.Spider.Position = UDim2.new(1, -71, 0, len - 4)
        Decor.Spider.Rotation = math.sin(t * 2) * 10
    end
    if Decor.Bunny then
        local hop = math.max(0, math.sin(t * 2.2)) * 8
        Decor.Bunny.Position = UDim2.new(1, -60, 0, -26 - hop)
    end
    if Decor.Sparkles then
        for i, s in ipairs(Decor.Sparkles) do
            s.TextTransparency = 0.5 + math.sin(t * 4 + i) * 0.5
        end
    end
    if Decor.Rainbow then
        Decor.Rainbow.Offset = Vector2.new(math.sin(t * 0.6) * 0.3, 0)
    end
    if Decor.Extra then
        Decor.Extra.Rotation = 15 + math.sin(t * 1.2) * 5
    end
end

local running = false
local Connection = nil
local DecorConnection = nil

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
    local canPile = Season.Pile == true and (Season.Direction or 1) > 0

    if wantScreen and canPile then
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
    for surface in pairs(SurfaceLastPos) do
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
        for _, p in ipairs(ScreenFlakes) do
            local prevY = p.Y
            p.Y += p.VY * dt
            p.Rot += p.Spin * dt
            local x = p.X + math.sin(t * 1.3 + p.Phase) * p.Sway
            local landed = false
            if canPile then
                for surface in pairs(active) do
                    local pos, size = surface.AbsolutePosition, surface.AbsoluteSize
                    local top = pos.Y
                    if prevY + p.Size <= top and p.Y + p.Size >= top and x >= pos.X + 6 and x <= pos.X + size.X - 6 then
                        StickFlake(p, x - pos.X, surface)
                        landed = true
                        break
                    end
                end
            end
            if landed or p.Y > h + 30 or p.Y < -60 then
                Respawn(p, w, h, true)
            else
                p.Frame.Position = UDim2.fromOffset(x, p.Y)
                p.Frame.Rotation = p.Rot
            end
        end
        for _, st in ipairs(Stuck) do
            local pos = st.Surface.AbsolutePosition
            st.Frame.Position = UDim2.fromOffset(pos.X + st.RelX - st.Size / 2, pos.Y - st.Lift - st.Size * 0.4)
        end
    else
        for _, p in ipairs(ScreenFlakes) do
            p.Frame.Position = UDim2.fromOffset(-80, -80)
        end
    end

    if #LooseFlakes > 0 then
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
        local uw, uh = math.max(UIClip.AbsoluteSize.X, 1), math.max(UIClip.AbsoluteSize.Y, 1)
        for _, p in ipairs(UIFlakes) do
            p.Y += p.VY * 0.6 * dt
            p.Rot += p.Spin * dt
            if p.Y > uh + 30 or p.Y < -40 then
                Respawn(p, uw, uh, true)
            end
            local x = p.X + math.sin(t * 1.1 + p.Phase) * p.Sway
            p.Frame.Position = UDim2.fromOffset(x, p.Y)
            p.Frame.Rotation = p.Rot
        end
    end
end

local function SetRunning(on)
    if on and not running then
        running = true
        table.clear(SurfaceLastPos)
        BuildParticles()
        Connection = RunService.RenderStepped:Connect(Step)
    elseif not on and running then
        running = false
        if Connection then
            Connection:Disconnect()
            Connection = nil
        end
        ReleaseStuck(0)
        ClearLoose()
        ClearParticles()
        Overlay.Enabled = false
        UIClip.Visible = false
    end
end

local function RefreshDecorLoop()
    local needs = DecorFolder.Visible
    if needs and not DecorConnection then
        DecorConnection = RunService.RenderStepped:Connect(function()
            if env.Destroyed or not Main.Parent then
                return
            end
            AnimateDecor(os.clock())
        end)
    elseif not needs and DecorConnection then
        DecorConnection:Disconnect()
        DecorConnection = nil
    end
end

env.ToxSeasonApply = function()
    Season = CurrentSeason() or DefaultSeason
    ReleaseStuck(0)
    ClearLoose()
    if running then
        BuildParticles()
    end
    BuildDecor()
    RefreshDecorLoop()
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

env.SetToxThemeDecor = function(enabled, skipSave)
    Settings.ToxThemeDecor = enabled == true
    BuildDecor()
    RefreshDecorLoop()
    if not skipSave and env.AutoSaveConfiguration then
        env.AutoSaveConfiguration()
    end
end

env.ToxSnowCleanup = function()
    SetRunning(false)
    if DecorConnection then
        DecorConnection:Disconnect()
        DecorConnection = nil
    end
    pcall(function() Overlay:Destroy() end)
    pcall(function() UIClip:Destroy() end)
    pcall(function() DecorFolder:Destroy() end)
end

Season = CurrentSeason() or DefaultSeason
BuildDecor()
RefreshDecorLoop()
env.SetToxSnowMode(Settings.ToxSnowMode, true)
