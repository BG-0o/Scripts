local env = getgenv()
if env.Destroyed then
    return
end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local Stats = game:GetService("Stats")

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()
local Settings = env.Settings or {}

local function MakeDraggable(...) if env.MakeDraggable then return env.MakeDraggable(...) end end
local function CustomNotify(...) if env.CustomNotify then return env.CustomNotify(...) end end
local function Notify(...) if env.Notify then return env.Notify(...) end end
local function PlayToxSound(...) if env.PlayToxSound then return env.PlayToxSound(...) end end
local function AutoSaveConfiguration(...) if env.AutoSaveConfiguration then return env.AutoSaveConfiguration(...) end end
local function ApplySavedGuiPosition(...) if env.ApplySavedGuiPosition then return env.ApplySavedGuiPosition(...) end end
local function TrackGuiPosition(...) if env.TrackGuiPosition then return env.TrackGuiPosition(...) end end
local function MakeResizable(...) if env.MakeResizable then return env.MakeResizable(...) end end

local GUIColorMap = env.GUIColorMap or {}
local LOGO_ID = env.LOGO_ID or "rbxassetid://120675082996894"
local MAIN_COLOR = env.MAIN_COLOR or Color3.fromRGB(0, 168, 255)

local isMinimized = false
local WatermarkFrame = nil
local WatermarkLabel = nil
local SetWeatherType = nil
local OpenColorPicker = nil

-- Rayfield Cyber Blue Palette: Luminous high-contrast neon blue on dark obsidian slate
local DefaultTheme = {
    Background = Color3.fromRGB(10, 13, 20),
    Panel = Color3.fromRGB(13, 17, 26),
    Element = Color3.fromRGB(19, 25, 38),
    Hover = Color3.fromRGB(27, 35, 54),
    Outline = Color3.fromRGB(30, 41, 59),
    Accent = Color3.fromRGB(0, 168, 255),
    Accent2 = Color3.fromRGB(56, 189, 248),
    Text = Color3.fromRGB(255, 255, 255),
    DimText = Color3.fromRGB(156, 170, 195),
    Risky = Color3.fromRGB(244, 63, 94)
}

if typeof(Settings.Theme) ~= "table" then
    Settings.Theme = {}
end

if Settings.CustomAccentActive ~= true then
    for key, val in pairs(DefaultTheme) do
        Settings.Theme[key] = val
    end
else
    for key, val in pairs(DefaultTheme) do
        if Settings.Theme[key] == nil then
            Settings.Theme[key] = val
        end
    end
end

if Settings.CustomAccentActive ~= true and env.MAIN_COLOR and typeof(env.MAIN_COLOR) == "Color3" then
    if Settings.Theme.Accent == Color3.fromRGB(9, 0, 136) then
        Settings.Theme.Accent = DefaultTheme.Accent
    end
end

local Theme = Settings.Theme
getgenv().Theme = Theme
MAIN_COLOR = Theme.Accent
getgenv().MAIN_COLOR = MAIN_COLOR

local ThemedObjects = {}
local TransparentObjects = {}
local RegisteredToggles = {}

local function RegisterThemedObject(instance, prop, colorKey)
    if not instance then return end
    table.insert(ThemedObjects, { Instance = instance, Prop = prop, Key = colorKey })
    pcall(function()
        instance[prop] = Theme[colorKey]
    end)
end

local function RegisterTransparentObject(instance, mode)
    if not instance then return end
    table.insert(TransparentObjects, { Instance = instance, Mode = mode or "Panel" })
end

getgenv().RegisterThemedObject = RegisterThemedObject
getgenv().RegisterTransparentObject = RegisterTransparentObject
getgenv().ToxRegisterTransparentObject = RegisterTransparentObject
getgenv().ThemedObjects = ThemedObjects
getgenv().RegisteredToggles = RegisteredToggles

getgenv().ToxGetRainbowColor = function(speedVal, phase)
    local spd = tonumber(speedVal) or tonumber(Settings.UIRainbowSpeed) or 35
    local rate = math.clamp(spd, 1, 100) / 140
    local hue = ((os.clock() * rate) + (tonumber(phase) or 0)) % 1
    return Color3.fromHSV(hue, 0.95, 1)
end

local function SyncAccentOnly(accentColor, accent2Color)
    if typeof(accentColor) ~= "Color3" then return end
    Theme.Accent = accentColor
    if typeof(accent2Color) == "Color3" then
        Theme.Accent2 = accent2Color
    end
    MAIN_COLOR = accentColor
    getgenv().MAIN_COLOR = accentColor

    for i = #ThemedObjects, 1, -1 do
        local entry = ThemedObjects[i]
        local inst = entry.Instance
        if inst and inst.Parent then
            if entry.Key == "Accent" or entry.Key == "Accent2" then
                pcall(function()
                    inst[entry.Prop] = Theme[entry.Key]
                end)
            end
        else
            table.remove(ThemedObjects, i)
        end
    end

    for i = #RegisteredToggles, 1, -1 do
        local toggleEntry = RegisteredToggles[i]
        if toggleEntry and toggleEntry.UpdateColor then
            pcall(toggleEntry.UpdateColor)
        else
            table.remove(RegisteredToggles, i)
        end
    end

    if env.ToxUserExpiryLabel and env.ToxUserExpiryLabel.Parent then
        env.ToxUserExpiryLabel.Text = "Lifetime"
    end
end

local function ApplyTheme()
    MAIN_COLOR = Theme.Accent
    getgenv().MAIN_COLOR = MAIN_COLOR

    for i = #ThemedObjects, 1, -1 do
        local entry = ThemedObjects[i]
        local inst = entry.Instance
        if inst and inst.Parent then
            pcall(function()
                inst[entry.Prop] = Theme[entry.Key]
            end)
        else
            table.remove(ThemedObjects, i)
        end
    end

    for i = #RegisteredToggles, 1, -1 do
        local toggleEntry = RegisteredToggles[i]
        if toggleEntry and toggleEntry.UpdateColor then
            pcall(toggleEntry.UpdateColor)
        else
            table.remove(RegisteredToggles, i)
        end
    end

    SyncAccentOnly(Theme.Accent, Theme.Accent2)
end

getgenv().ApplyToxTheme = ApplyTheme

getgenv().SetToxCustomAccent = function(color, skipSave)
    if typeof(color) ~= "Color3" then return false end
    Settings.UIRainbow = false
    Settings.CustomAccentActive = true
    Settings.GUIColorName = "Custom"
    Theme.Accent = color
    local h, s, v = color:ToHSV()
    Theme.Accent2 = Color3.fromHSV((h + 0.08) % 1, math.clamp(s * 0.8, 0.2, 0.9), math.clamp(v * 1.1, 0.6, 1))
    ApplyTheme()
    if not skipSave and getgenv().AutoSaveConfiguration then
        getgenv().AutoSaveConfiguration()
    end
    return true
end

getgenv().SetToxGuiColor = function(colorName, skipSave)
    local selected = GUIColorMap[tostring(colorName)]
    if selected then
        Settings.UIRainbow = false
        Settings.CustomAccentActive = false
        Theme.Accent = selected
        Theme.Outline = Color3.fromRGB(
            math.clamp(math.floor(selected.R * 255 * 0.35), 24, 60),
            math.clamp(math.floor(selected.G * 255 * 0.35), 32, 70),
            math.clamp(math.floor(selected.B * 255 * 0.35), 45, 95)
        )
        ApplyTheme()
        Settings.GUIColorName = tostring(colorName)
        if not skipSave and getgenv().AutoSaveConfiguration then
            getgenv().AutoSaveConfiguration()
        end
        return true
    end
    return false
end

local UIThemePresets = {
    ["Dark Neon"] = {
        Background = Color3.fromRGB(10, 13, 20),
        Panel = Color3.fromRGB(13, 17, 26),
        Element = Color3.fromRGB(19, 25, 38),
        Hover = Color3.fromRGB(27, 35, 54),
        Outline = Color3.fromRGB(30, 41, 59),
        Text = Color3.fromRGB(255, 255, 255),
        DimText = Color3.fromRGB(156, 170, 195),
        Risky = Color3.fromRGB(244, 63, 94)
    },
    ["OLED Black"] = {
        Background = Color3.fromRGB(5, 6, 9),
        Panel = Color3.fromRGB(9, 11, 16),
        Element = Color3.fromRGB(14, 18, 25),
        Hover = Color3.fromRGB(20, 26, 36),
        Outline = Color3.fromRGB(25, 34, 48),
        Text = Color3.fromRGB(255, 255, 255),
        DimText = Color3.fromRGB(148, 163, 184),
        Risky = Color3.fromRGB(244, 63, 94)
    },
    ["Clean White"] = {
        Background = Color3.fromRGB(240, 244, 250),
        Panel = Color3.fromRGB(255, 255, 255),
        Element = Color3.fromRGB(228, 234, 245),
        Hover = Color3.fromRGB(214, 223, 238),
        Outline = Color3.fromRGB(190, 202, 220),
        Text = Color3.fromRGB(15, 23, 42),
        DimText = Color3.fromRGB(71, 85, 105),
        Risky = Color3.fromRGB(225, 29, 72)
    },
    ["Translucent Glass"] = {
        Background = Color3.fromRGB(10, 13, 20),
        Panel = Color3.fromRGB(15, 20, 31),
        Element = Color3.fromRGB(22, 29, 44),
        Hover = Color3.fromRGB(30, 40, 60),
        Outline = Color3.fromRGB(38, 52, 75),
        Text = Color3.fromRGB(255, 255, 255),
        DimText = Color3.fromRGB(160, 175, 200),
        Risky = Color3.fromRGB(244, 63, 94)
    },
    ["Midnight Purple"] = {
        Background = Color3.fromRGB(12, 10, 20),
        Panel = Color3.fromRGB(18, 14, 30),
        Element = Color3.fromRGB(26, 20, 42),
        Hover = Color3.fromRGB(36, 28, 58),
        Outline = Color3.fromRGB(48, 38, 76),
        Text = Color3.fromRGB(255, 255, 255),
        DimText = Color3.fromRGB(175, 160, 205),
        Risky = Color3.fromRGB(244, 63, 94)
    },
    ["Cyberpunk Cyan"] = {
        Background = Color3.fromRGB(8, 15, 20),
        Panel = Color3.fromRGB(11, 21, 28),
        Element = Color3.fromRGB(16, 30, 40),
        Hover = Color3.fromRGB(22, 42, 56),
        Outline = Color3.fromRGB(28, 56, 74),
        Text = Color3.fromRGB(255, 255, 255),
        DimText = Color3.fromRGB(148, 190, 205),
        Risky = Color3.fromRGB(244, 63, 94)
    }
}

getgenv().SetToxUITheme = function(themeName, skipSave)
    local preset = UIThemePresets[tostring(themeName)]
    if preset then
        for k, v in pairs(preset) do
            Theme[k] = v
        end
        Settings.ToxUITheme = tostring(themeName)
        if tostring(themeName) == "Translucent Glass" then
            if not Settings.ToxUITransparency or Settings.ToxUITransparency < 0.25 then
                Settings.ToxUITransparency = 0.35
            end
        elseif tostring(themeName) == "Clean White" and Settings.CustomAccentActive ~= true then
            Theme.Accent = Color3.fromRGB(2, 132, 199)
        end
        ApplyTheme()
        if getgenv().SetToxUITransparency then
            getgenv().SetToxUITransparency(Settings.ToxUITransparency or 0, true)
        end
        if not skipSave and getgenv().AutoSaveConfiguration then
            getgenv().AutoSaveConfiguration()
        end
        return true
    end
    return false
end

getgenv().SetToxUITransparency = function(transparency, skipSave)
    local val = math.clamp(tonumber(transparency) or 0, 0, 1)
    Settings.ToxUITransparency = val
    local elemTransp = math.clamp(val * 0.9, 0, 0.9)
    local strokeTransp = math.clamp(0.25 + val * 0.25, 0.2, 0.65)
    if env.Main then
        env.Main.BackgroundTransparency = val
    end
    for i = #ThemedObjects, 1, -1 do
        local entry = ThemedObjects[i]
        local inst = entry and entry.Instance
        if inst and inst.Parent then
            if entry.Prop == "BackgroundColor3" and inst:IsA("GuiObject") then
                if entry.Key == "Background" or entry.Key == "Panel" then
                    inst.BackgroundTransparency = val
                elseif entry.Key == "Element" then
                    inst.BackgroundTransparency = elemTransp
                end
            elseif inst:IsA("UIStroke") and entry.Key == "Outline" then
                inst.Transparency = strokeTransp
            end
        end
    end
    for i = #TransparentObjects, 1, -1 do
        local entry = TransparentObjects[i]
        local inst = entry and entry.Instance
        if inst and inst.Parent then
            pcall(function()
                if entry.Mode == "Background" or entry.Mode == "Panel" then
                    inst.BackgroundTransparency = val
                elseif entry.Mode == "Element" then
                    inst.BackgroundTransparency = elemTransp
                elseif entry.Mode == "Stroke" and inst:IsA("UIStroke") then
                    inst.Transparency = strokeTransp
                end
            end)
        else
            table.remove(TransparentObjects, i)
        end
    end
    if not skipSave and getgenv().AutoSaveConfiguration then
        getgenv().AutoSaveConfiguration()
    end
end

-- ScreenGui Parent Container
local ParentContainer = (gethui and gethui()) or game:GetService("CoreGui")
local Gui = Instance.new("ScreenGui")
Gui.Name = "ToxHudGui"
Gui.ResetOnSpawn = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.DisplayOrder = 999999999
Gui.Parent = ParentContainer
getgenv().Gui = Gui

-- Dimmer Background Overlay
local DimmerFrame = Instance.new("TextButton")
DimmerFrame.Name = "DimmerFrame"
DimmerFrame.Size = UDim2.new(1, 0, 1, 0)
DimmerFrame.Position = UDim2.new(0, 0, 0, 0)
DimmerFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
DimmerFrame.BackgroundTransparency = 0.55
DimmerFrame.BorderSizePixel = 0
DimmerFrame.Text = ""
DimmerFrame.AutoButtonColor = false
DimmerFrame.Visible = false
DimmerFrame.ZIndex = 1
DimmerFrame.Parent = Gui

-- Main Window (Rayfield proportions: 740 x 490)
local defaultInitSize = UDim2.new(0, 740, 0, 490)
local defaultInitPos = UDim2.new(0.5, -370, 0.5, -245)

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = defaultInitSize
Main.Position = defaultInitPos
Main.BackgroundColor3 = Theme.Background
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Visible = false
Main.ZIndex = 2
Main.Parent = Gui
getgenv().Main = Main
RegisterThemedObject(Main, "BackgroundColor3", "Background")

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Theme.Accent
MainStroke.Thickness = 1
MainStroke.Transparency = 0.35
MainStroke.Parent = Main
RegisterThemedObject(MainStroke, "Color", "Accent")

local MainGradient = Instance.new("UIGradient")
MainGradient.Rotation = 90
MainGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(210, 220, 240))
})
MainGradient.Enabled = Settings.WindowGradient ~= false
MainGradient.Parent = Main

local WallpaperImage = Instance.new("ImageLabel")
WallpaperImage.Name = "WallpaperImage"
WallpaperImage.Size = UDim2.new(1, 0, 1, 0)
WallpaperImage.Position = UDim2.new(0, 0, 0, 0)
WallpaperImage.BackgroundTransparency = 1
WallpaperImage.ScaleType = Enum.ScaleType.Crop
WallpaperImage.ImageTransparency = tonumber(Settings.WallpaperDim) or 0.25
WallpaperImage.ZIndex = 3
WallpaperImage.Parent = Main
if Settings.WallpaperUrl and Settings.WallpaperUrl ~= "" then
    WallpaperImage.Image = Settings.WallpaperUrl
end

local WeatherContainer = Instance.new("Frame")
WeatherContainer.Name = "WeatherContainer"
WeatherContainer.Size = UDim2.new(1, 0, 1, 0)
WeatherContainer.Position = UDim2.new(0, 0, 0, 0)
WeatherContainer.BackgroundTransparency = 1
WeatherContainer.ClipsDescendants = true
WeatherContainer.ZIndex = 4
WeatherContainer.Parent = Main

local ScreenWeatherGui = Instance.new("ScreenGui")
ScreenWeatherGui.Name = "ToxScreenWeather"
ScreenWeatherGui.ResetOnSpawn = false
ScreenWeatherGui.DisplayOrder = 999999990
ScreenWeatherGui.Parent = ParentContainer

----------------------------------------------------------------------
-- TOPBAR: Rayfield Header with User Profile at the Top
----------------------------------------------------------------------
local TopBarHeight = 52
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, TopBarHeight)
TopBar.Position = UDim2.new(0, 0, 0, 0)
TopBar.BackgroundColor3 = Theme.Panel
TopBar.BorderSizePixel = 0
TopBar.ZIndex = 30
TopBar.Parent = Main
RegisterThemedObject(TopBar, "BackgroundColor3", "Panel")

local TopBarBottomBorder = Instance.new("Frame")
TopBarBottomBorder.Name = "BottomBorder"
TopBarBottomBorder.Size = UDim2.new(1, 0, 0, 1)
TopBarBottomBorder.Position = UDim2.new(0, 0, 1, -1)
TopBarBottomBorder.BackgroundColor3 = Theme.Outline
TopBarBottomBorder.BorderSizePixel = 0
TopBarBottomBorder.ZIndex = 31
TopBarBottomBorder.Parent = TopBar
RegisterThemedObject(TopBarBottomBorder, "BackgroundColor3", "Outline")

-- Left Section: Brand Logo & Title
local HubLogo = Instance.new("ImageLabel")
HubLogo.Name = "HubLogo"
HubLogo.Size = UDim2.new(0, 30, 0, 30)
HubLogo.Position = UDim2.new(0, 12, 0.5, -15)
HubLogo.BackgroundColor3 = Theme.Element
HubLogo.BackgroundTransparency = 0
HubLogo.Image = (Settings.CustomIconUrl and Settings.CustomIconUrl ~= "") and Settings.CustomIconUrl or LOGO_ID
HubLogo.ZIndex = 32
HubLogo.Parent = TopBar
local HubLogoCorner = Instance.new("UICorner") HubLogoCorner.CornerRadius = UDim.new(0, 8) HubLogoCorner.Parent = HubLogo
local HubLogoStroke = Instance.new("UIStroke") HubLogoStroke.Color = Theme.Accent HubLogoStroke.Thickness = 1 HubLogoStroke.Transparency = 0.5 HubLogoStroke.Parent = HubLogo
RegisterThemedObject(HubLogoStroke, "Color", "Accent")

local HubTitle = Instance.new("TextLabel")
HubTitle.Name = "HubTitle"
HubTitle.Size = UDim2.new(0, 70, 0, 20)
HubTitle.Position = UDim2.new(0, 48, 0, 9)
HubTitle.BackgroundTransparency = 1
HubTitle.Text = "ToxHud"
HubTitle.TextColor3 = Theme.Text
HubTitle.Font = Enum.Font.GothamBold
HubTitle.TextSize = 15
HubTitle.TextXAlignment = Enum.TextXAlignment.Left
HubTitle.ZIndex = 32
HubTitle.Parent = TopBar
RegisterThemedObject(HubTitle, "TextColor3", "Text")

local HubVersion = Instance.new("TextLabel")
HubVersion.Name = "HubVersion"
HubVersion.Size = UDim2.new(0, 70, 0, 14)
HubVersion.Position = UDim2.new(0, 48, 0, 28)
HubVersion.BackgroundTransparency = 1
HubVersion.Text = "1.0.0"
HubVersion.TextColor3 = Theme.Accent
HubVersion.Font = Enum.Font.GothamMedium
HubVersion.TextSize = 10
HubVersion.TextXAlignment = Enum.TextXAlignment.Left
HubVersion.ZIndex = 32
HubVersion.Parent = TopBar
RegisterThemedObject(HubVersion, "TextColor3", "Accent")

-- Current Game Tag Badge
local GameTagPill = Instance.new("Frame")
GameTagPill.Name = "GameTagPill"
GameTagPill.Size = UDim2.new(0, 105, 0, 22)
GameTagPill.Position = UDim2.new(0, 126, 0.5, -11)
GameTagPill.BackgroundColor3 = Theme.Element
GameTagPill.BorderSizePixel = 0
GameTagPill.ZIndex = 32
GameTagPill.Parent = TopBar
RegisterThemedObject(GameTagPill, "BackgroundColor3", "Element")
local GameTagCorner = Instance.new("UICorner") GameTagCorner.CornerRadius = UDim.new(0, 6) GameTagCorner.Parent = GameTagPill
local GameTagStroke = Instance.new("UIStroke") GameTagStroke.Color = Theme.Accent GameTagStroke.Thickness = 1 GameTagStroke.Transparency = 0.6 GameTagStroke.Parent = GameTagPill
RegisterThemedObject(GameTagStroke, "Color", "Accent")

local GameTagText = Instance.new("TextLabel")
GameTagText.Name = "GameTagText"
GameTagText.Size = UDim2.new(1, -8, 1, 0)
GameTagText.Position = UDim2.new(0, 4, 0, 0)
GameTagText.BackgroundTransparency = 1
GameTagText.Text = "Universal"
GameTagText.TextColor3 = Theme.Accent
GameTagText.Font = Enum.Font.GothamBold
GameTagText.TextSize = 11
GameTagText.TextTruncate = Enum.TextTruncate.AtEnd
GameTagText.ZIndex = 33
GameTagText.Parent = GameTagPill
RegisterThemedObject(GameTagText, "TextColor3", "Accent")
env.ToxGameTagText = GameTagText

-- Center/Right: USER PROFILE CAPSULE AT THE TOP
local UserCapsule = Instance.new("Frame")
UserCapsule.Name = "UserCapsule"
UserCapsule.Size = UDim2.new(0, 230, 0, 36)
UserCapsule.Position = UDim2.new(1, -430, 0.5, -18)
UserCapsule.BackgroundColor3 = Theme.Element
UserCapsule.BorderSizePixel = 0
UserCapsule.ZIndex = 32
UserCapsule.Parent = TopBar
RegisterThemedObject(UserCapsule, "BackgroundColor3", "Element")
local UserCapCorner = Instance.new("UICorner") UserCapCorner.CornerRadius = UDim.new(0, 8) UserCapCorner.Parent = UserCapsule
local UserCapStroke = Instance.new("UIStroke") UserCapStroke.Color = Theme.Outline UserCapStroke.Thickness = 1 UserCapStroke.Transparency = 0.5 UserCapStroke.Parent = UserCapsule
RegisterThemedObject(UserCapStroke, "Color", "Outline")

local UserAvatar = Instance.new("ImageLabel")
UserAvatar.Name = "UserAvatar"
UserAvatar.Size = UDim2.new(0, 26, 0, 26)
UserAvatar.Position = UDim2.new(0, 6, 0.5, -13)
UserAvatar.BackgroundColor3 = Theme.Hover
UserAvatar.BackgroundTransparency = 0
UserAvatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(Player.UserId) .. "&w=100&h=100"
UserAvatar.ZIndex = 33
UserAvatar.Parent = UserCapsule
local AvatarCorner = Instance.new("UICorner") AvatarCorner.CornerRadius = UDim.new(1, 0) AvatarCorner.Parent = UserAvatar
local AvatarStroke = Instance.new("UIStroke") AvatarStroke.Color = Theme.Accent AvatarStroke.Thickness = 1 AvatarStroke.Transparency = 0.5 AvatarStroke.Parent = UserAvatar
RegisterThemedObject(AvatarStroke, "Color", "Accent")

local UserNameLabel = Instance.new("TextLabel")
UserNameLabel.Name = "UserName"
UserNameLabel.Size = UDim2.new(1, -125, 0, 16)
UserNameLabel.Position = UDim2.new(0, 38, 0, 2)
UserNameLabel.BackgroundTransparency = 1
UserNameLabel.Text = Player.DisplayName or Player.Name
UserNameLabel.TextColor3 = Theme.Text
UserNameLabel.Font = Enum.Font.GothamBold
UserNameLabel.TextSize = 11
UserNameLabel.TextXAlignment = Enum.TextXAlignment.Left
UserNameLabel.TextTruncate = Enum.TextTruncate.AtEnd
UserNameLabel.ZIndex = 33
UserNameLabel.Parent = UserCapsule
RegisterThemedObject(UserNameLabel, "TextColor3", "Text")

local StatusBadge = Instance.new("Frame")
StatusBadge.Name = "StatusBadge"
StatusBadge.Size = UDim2.new(0, 52, 0, 14)
StatusBadge.Position = UDim2.new(0, 38, 0, 18)
StatusBadge.BackgroundColor3 = Color3.fromRGB(14, 28, 48)
StatusBadge.BorderSizePixel = 0
StatusBadge.ZIndex = 33
StatusBadge.Parent = UserCapsule
local sCorner = Instance.new("UICorner") sCorner.CornerRadius = UDim.new(0, 3) sCorner.Parent = StatusBadge
local sStroke = Instance.new("UIStroke") sStroke.Color = Theme.Accent sStroke.Thickness = 1 sStroke.Transparency = 0.5 sStroke.Parent = StatusBadge
RegisterThemedObject(sStroke, "Color", "Accent")

local UserExpiryLabel = Instance.new("TextLabel")
UserExpiryLabel.Name = "UserExpiry"
UserExpiryLabel.Size = UDim2.new(1, 0, 1, 0)
UserExpiryLabel.BackgroundTransparency = 1
UserExpiryLabel.Text = "Lifetime"
UserExpiryLabel.TextColor3 = Theme.Accent
UserExpiryLabel.Font = Enum.Font.GothamBold
UserExpiryLabel.TextSize = 9
UserExpiryLabel.ZIndex = 34
UserExpiryLabel.Parent = StatusBadge
RegisterThemedObject(UserExpiryLabel, "TextColor3", "Accent")
env.ToxUserExpiryLabel = UserExpiryLabel

-- Live FPS & Ping Display inside Capsule
local StatsContainer = Instance.new("Frame")
StatsContainer.Name = "StatsContainer"
StatsContainer.Size = UDim2.new(0, 78, 1, -8)
StatsContainer.Position = UDim2.new(1, -82, 0, 4)
StatsContainer.BackgroundTransparency = 1
StatsContainer.ZIndex = 33
StatsContainer.Parent = UserCapsule

local FPSLabel = Instance.new("TextLabel")
FPSLabel.Name = "FPSLabel"
FPSLabel.Size = UDim2.new(1, 0, 0, 14)
FPSLabel.Position = UDim2.new(0, 0, 0, 0)
FPSLabel.BackgroundTransparency = 1
FPSLabel.Font = Enum.Font.Code
FPSLabel.TextSize = 10
FPSLabel.TextColor3 = Color3.fromRGB(52, 211, 153)
FPSLabel.TextXAlignment = Enum.TextXAlignment.Right
FPSLabel.Text = "FPS: 60"
FPSLabel.ZIndex = 34
FPSLabel.Parent = StatsContainer

local PingLabel = Instance.new("TextLabel")
PingLabel.Name = "PingLabel"
PingLabel.Size = UDim2.new(1, 0, 0, 14)
PingLabel.Position = UDim2.new(0, 0, 0, 14)
PingLabel.BackgroundTransparency = 1
PingLabel.Font = Enum.Font.Code
PingLabel.TextSize = 10
PingLabel.TextColor3 = Theme.Accent2
PingLabel.TextXAlignment = Enum.TextXAlignment.Right
PingLabel.Text = "Ping: --"
PingLabel.ZIndex = 34
PingLabel.Parent = StatsContainer
RegisterThemedObject(PingLabel, "TextColor3", "Accent2")

-- Smooth Stats Updater
local liveFpsCount = 0
task.spawn(function()
    local lastTime = os.clock()
    while task.wait(0.5) do
        if env.Destroyed then break end
        if Main and Main.Visible then
            local now = os.clock()
            local dt = now - lastTime
            local fps = math.floor((liveFpsCount / math.max(dt, 0.001)) + 0.5)
            liveFpsCount = 0
            lastTime = now
            if FPSLabel and FPSLabel.Parent then
                FPSLabel.Text = "FPS: " .. tostring(fps)
                if fps >= 50 then
                    FPSLabel.TextColor3 = Color3.fromRGB(52, 211, 153)
                elseif fps >= 30 then
                    FPSLabel.TextColor3 = Color3.fromRGB(250, 204, 21)
                else
                    FPSLabel.TextColor3 = Color3.fromRGB(244, 63, 94)
                end
            end
            if PingLabel and PingLabel.Parent then
                local ping = 0
                pcall(function()
                    ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
                end)
                PingLabel.Text = "Ping: " .. tostring(ping) .. "ms"
            end
        end
    end
end)
RunService.RenderStepped:Connect(function()
    liveFpsCount = liveFpsCount + 1
end)

-- Search Pill on TopBar
local SearchPill = Instance.new("Frame")
SearchPill.Name = "SearchPill"
SearchPill.Size = UDim2.new(0, 110, 0, 28)
SearchPill.Position = UDim2.new(1, -190, 0.5, -14)
SearchPill.BackgroundColor3 = Theme.Element
SearchPill.BorderSizePixel = 0
SearchPill.ZIndex = 32
SearchPill.Parent = TopBar
RegisterThemedObject(SearchPill, "BackgroundColor3", "Element")
local SearchCorner = Instance.new("UICorner") SearchCorner.CornerRadius = UDim.new(0, 6) SearchCorner.Parent = SearchPill
local SearchStroke = Instance.new("UIStroke") SearchStroke.Color = Theme.Outline SearchStroke.Thickness = 1 SearchStroke.Parent = SearchPill
RegisterThemedObject(SearchStroke, "Color", "Outline")

local SearchIcon = Instance.new("TextLabel")
SearchIcon.Size = UDim2.new(0, 20, 1, 0)
SearchIcon.Position = UDim2.new(0, 4, 0, 0)
SearchIcon.BackgroundTransparency = 1
SearchIcon.Text = "Q"
SearchIcon.TextColor3 = Theme.DimText
SearchIcon.Font = Enum.Font.GothamBold
SearchIcon.TextSize = 11
SearchIcon.ZIndex = 33
SearchIcon.Parent = SearchPill
RegisterThemedObject(SearchIcon, "TextColor3", "DimText")

local SearchTextBox = Instance.new("TextBox")
SearchTextBox.Name = "SearchTextBox"
SearchTextBox.Size = UDim2.new(1, -26, 1, 0)
SearchTextBox.Position = UDim2.new(0, 22, 0, 0)
SearchTextBox.BackgroundTransparency = 1
SearchTextBox.Text = ""
SearchTextBox.PlaceholderText = "Search..."
SearchTextBox.PlaceholderColor3 = Theme.DimText
SearchTextBox.TextColor3 = Theme.Text
SearchTextBox.Font = Enum.Font.Gotham
SearchTextBox.TextSize = 11
SearchTextBox.ClearTextOnFocus = false
SearchTextBox.ZIndex = 33
SearchTextBox.Parent = SearchPill
RegisterThemedObject(SearchTextBox, "TextColor3", "Text")
RegisterThemedObject(SearchTextBox, "PlaceholderColor3", "DimText")

-- Top Window Controls: Minimize (-) and Close (X)
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Name = "Minimize"
MinimizeBtn.Size = UDim2.new(0, 28, 0, 28)
MinimizeBtn.Position = UDim2.new(1, -70, 0.5, -14)
MinimizeBtn.BackgroundColor3 = Theme.Element
MinimizeBtn.BorderSizePixel = 0
MinimizeBtn.Text = "-"
MinimizeBtn.TextColor3 = Theme.Text
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextSize = 16
MinimizeBtn.ZIndex = 32
MinimizeBtn.Parent = TopBar
RegisterThemedObject(MinimizeBtn, "BackgroundColor3", "Element")
RegisterThemedObject(MinimizeBtn, "TextColor3", "Text")
local MinCorner = Instance.new("UICorner") MinCorner.CornerRadius = UDim.new(0, 6) MinCorner.Parent = MinimizeBtn
getgenv().Minimize = MinimizeBtn

local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -36, 0.5, -14)
CloseBtn.BackgroundColor3 = Theme.Element
CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Theme.DimText
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 12
CloseBtn.ZIndex = 32
CloseBtn.Parent = TopBar
RegisterThemedObject(CloseBtn, "BackgroundColor3", "Element")
RegisterThemedObject(CloseBtn, "TextColor3", "DimText")
local CloseCorner = Instance.new("UICorner") CloseCorner.CornerRadius = UDim.new(0, 6) CloseCorner.Parent = CloseBtn

CloseBtn.MouseEnter:Connect(function()
    CloseBtn.BackgroundColor3 = Theme.Risky
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
end)
CloseBtn.MouseLeave:Connect(function()
    CloseBtn.BackgroundColor3 = Theme.Element
    CloseBtn.TextColor3 = Theme.DimText
end)
CloseBtn.MouseButton1Click:Connect(function()
    if getgenv().ToggleToxGui then
        getgenv().ToggleToxGui(false)
    else
        Main.Visible = false
        if DimmerFrame then DimmerFrame.Visible = false end
    end
end)

-- Make entire TopBar draggable
MakeDraggable(Main, TopBar)

----------------------------------------------------------------------
-- BODY: Sidebar (Navigation) + Content Area
----------------------------------------------------------------------
local isSidebarCollapsed = Settings.CollapseSidebar == true
local sidebarExpandedWidth = 185
local sidebarCollapsedWidth = 54

local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, isSidebarCollapsed and sidebarCollapsedWidth or sidebarExpandedWidth, 1, -TopBarHeight)
Sidebar.Position = UDim2.new(0, 0, 0, TopBarHeight)
Sidebar.BackgroundColor3 = Theme.Panel
Sidebar.BorderSizePixel = 0
Sidebar.ZIndex = 10
Sidebar.Parent = Main
RegisterThemedObject(Sidebar, "BackgroundColor3", "Panel")

local SidebarRightBorder = Instance.new("Frame")
SidebarRightBorder.Name = "RightBorder"
SidebarRightBorder.Size = UDim2.new(0, 1, 1, 0)
SidebarRightBorder.Position = UDim2.new(1, -1, 0, 0)
SidebarRightBorder.BackgroundColor3 = Theme.Outline
SidebarRightBorder.BorderSizePixel = 0
SidebarRightBorder.ZIndex = 11
SidebarRightBorder.Parent = Sidebar
RegisterThemedObject(SidebarRightBorder, "BackgroundColor3", "Outline")

local CategoryLabel = Instance.new("TextLabel")
CategoryLabel.Name = "CategoryLabel"
CategoryLabel.Size = UDim2.new(1, -20, 0, 24)
CategoryLabel.Position = UDim2.new(0, 14, 0, 6)
CategoryLabel.BackgroundTransparency = 1
CategoryLabel.Text = "NAVIGATION"
CategoryLabel.TextColor3 = Theme.DimText
CategoryLabel.Font = Enum.Font.GothamBold
CategoryLabel.TextSize = 9
CategoryLabel.TextXAlignment = Enum.TextXAlignment.Left
CategoryLabel.Visible = not isSidebarCollapsed
CategoryLabel.ZIndex = 12
CategoryLabel.Parent = Sidebar
RegisterThemedObject(CategoryLabel, "TextColor3", "DimText")

local SidebarScroll = Instance.new("ScrollingFrame")
SidebarScroll.Name = "SidebarScroll"
SidebarScroll.Size = UDim2.new(1, 0, 1, -36)
SidebarScroll.Position = UDim2.new(0, 0, 0, 32)
SidebarScroll.BackgroundTransparency = 1
SidebarScroll.BorderSizePixel = 0
SidebarScroll.ScrollBarThickness = 2
SidebarScroll.ScrollBarImageColor3 = Theme.Outline
SidebarScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
SidebarScroll.ZIndex = 12
SidebarScroll.Parent = Sidebar
getgenv().Tabs = SidebarScroll

local SidebarLayout = Instance.new("UIListLayout")
SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
SidebarLayout.Padding = UDim.new(0, 4)
SidebarLayout.Parent = SidebarScroll

local SidebarPadding = Instance.new("UIPadding")
SidebarPadding.PaddingLeft = UDim.new(0, 8)
SidebarPadding.PaddingRight = UDim.new(0, 8)
SidebarPadding.PaddingTop = UDim.new(0, 4)
SidebarPadding.PaddingBottom = UDim.new(0, 8)
SidebarPadding.Parent = SidebarScroll

SidebarLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    SidebarScroll.CanvasSize = UDim2.new(0, 0, 0, SidebarLayout.AbsoluteContentSize.Y + 16)
end)

----------------------------------------------------------------------
-- CONTENT AREA & PAGES CONTAINER
----------------------------------------------------------------------
local ContentArea = Instance.new("Frame")
ContentArea.Name = "ContentArea"
ContentArea.Size = UDim2.new(1, -(isSidebarCollapsed and sidebarCollapsedWidth or sidebarExpandedWidth), 1, -TopBarHeight)
ContentArea.Position = UDim2.new(0, isSidebarCollapsed and sidebarCollapsedWidth or sidebarExpandedWidth, 0, TopBarHeight)
ContentArea.BackgroundTransparency = 1
ContentArea.ZIndex = 5
ContentArea.Parent = Main

local ContentHeader = Instance.new("Frame")
ContentHeader.Name = "ContentHeader"
ContentHeader.Size = UDim2.new(1, 0, 0, 40)
ContentHeader.Position = UDim2.new(0, 0, 0, 0)
ContentHeader.BackgroundTransparency = 1
ContentHeader.ZIndex = 6
ContentHeader.Parent = ContentArea

local CurrentTabTitle = Instance.new("TextLabel")
CurrentTabTitle.Name = "CurrentTabTitle"
CurrentTabTitle.Size = UDim2.new(1, -24, 1, 0)
CurrentTabTitle.Position = UDim2.new(0, 16, 0, 0)
CurrentTabTitle.BackgroundTransparency = 1
CurrentTabTitle.Text = "Home"
CurrentTabTitle.TextColor3 = Theme.Text
CurrentTabTitle.Font = Enum.Font.GothamBold
CurrentTabTitle.TextSize = 15
CurrentTabTitle.TextXAlignment = Enum.TextXAlignment.Left
CurrentTabTitle.ZIndex = 7
CurrentTabTitle.Parent = ContentHeader
RegisterThemedObject(CurrentTabTitle, "TextColor3", "Text")

local PagesContainer = Instance.new("Frame")
PagesContainer.Name = "PagesContainer"
PagesContainer.Size = UDim2.new(1, 0, 1, -40)
PagesContainer.Position = UDim2.new(0, 0, 0, 40)
PagesContainer.BackgroundTransparency = 1
PagesContainer.ClipsDescendants = true
PagesContainer.ZIndex = 6
PagesContainer.Parent = ContentArea

-- Search Results Floating Scroll
local SearchResultsScroll = Instance.new("ScrollingFrame")
SearchResultsScroll.Name = "SearchResultsScroll"
SearchResultsScroll.Size = UDim2.new(0, 260, 0, 220)
SearchResultsScroll.Position = UDim2.new(1, -290, 0, TopBarHeight + 2)
SearchResultsScroll.BackgroundColor3 = Theme.Panel
SearchResultsScroll.BorderSizePixel = 0
SearchResultsScroll.ScrollBarThickness = 3
SearchResultsScroll.ScrollBarImageColor3 = Theme.Accent
SearchResultsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
SearchResultsScroll.Visible = false
SearchResultsScroll.ZIndex = 100
SearchResultsScroll.ClipsDescendants = true
SearchResultsScroll.Parent = Main
RegisterThemedObject(SearchResultsScroll, "BackgroundColor3", "Panel")
local SearchResultsCorner = Instance.new("UICorner") SearchResultsCorner.CornerRadius = UDim.new(0, 8) SearchResultsCorner.Parent = SearchResultsScroll
local SearchResultsStroke = Instance.new("UIStroke") SearchResultsStroke.Color = Theme.Accent SearchResultsStroke.Thickness = 1 SearchResultsStroke.Transparency = 0.4 SearchResultsStroke.Parent = SearchResultsScroll
RegisterThemedObject(SearchResultsStroke, "Color", "Accent")

local SearchResultsLayout = Instance.new("UIListLayout")
SearchResultsLayout.Padding = UDim.new(0, 4)
SearchResultsLayout.Parent = SearchResultsScroll
local SearchResultsPadding = Instance.new("UIPadding")
SearchResultsPadding.PaddingTop = UDim.new(0, 6)
SearchResultsPadding.PaddingBottom = UDim.new(0, 6)
SearchResultsPadding.PaddingLeft = UDim.new(0, 6)
SearchResultsPadding.PaddingRight = UDim.new(0, 6)
SearchResultsPadding.Parent = SearchResultsScroll
SearchResultsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    SearchResultsScroll.CanvasSize = UDim2.new(0, 0, 0, SearchResultsLayout.AbsoluteContentSize.Y + 12)
end)

----------------------------------------------------------------------
-- MINIMIZE & WINDOW LOGIC
----------------------------------------------------------------------
do
    local MainExpandedSize = Main.Size
    local savedPageTitle = "Home"

    local function SetMinimized(minimized)
        if getgenv().CloseToxDropdownOverlay then
            pcall(getgenv().CloseToxDropdownOverlay)
        end
        isMinimized = (minimized == true)
        getgenv().ToxMainMinimized = isMinimized
        getgenv().Minimized = isMinimized

        local targetW = isSidebarCollapsed and sidebarCollapsedWidth or sidebarExpandedWidth
        local resizeHandle = Main and (Main:FindFirstChild("ToxResizeHandle") or Main:FindFirstChild("ResizeHandle"))

        if isMinimized then
            if Main and Main.Size.Y.Offset > TopBarHeight then
                MainExpandedSize = Main.Size
                getgenv().ToxMainExpandedSize = MainExpandedSize
            end
            if resizeHandle then resizeHandle.Visible = false end
            if Sidebar then Sidebar.Visible = false end
            if ContentArea then ContentArea.Visible = false end
            if SearchResultsScroll then SearchResultsScroll.Visible = false end
            if UserCapsule then UserCapsule.Visible = false end
            if SearchPill then SearchPill.Visible = false end

            local currentW = (MainExpandedSize and MainExpandedSize.X.Offset) or 740
            if currentW < 240 then currentW = 240 end
            Main.Size = UDim2.new(0, currentW, 0, TopBarHeight)
            MinimizeBtn.Text = "+"
        else
            local refSz = getgenv().ToxMainExpandedSize or MainExpandedSize
            local currentW = math.max(refSz and refSz.X.Offset or 740, 400)
            local currentH = math.max(refSz and refSz.Y.Offset or 490, 300)

            Main.Size = UDim2.new(0, currentW, 0, currentH)
            if resizeHandle then resizeHandle.Visible = true end
            if Sidebar then
                Sidebar.Size = UDim2.new(0, targetW, 1, -TopBarHeight)
                Sidebar.Visible = true
            end
            if ContentArea then
                ContentArea.Position = UDim2.new(0, targetW, 0, TopBarHeight)
                ContentArea.Size = UDim2.new(1, -targetW, 1, -TopBarHeight)
                ContentArea.Visible = true
            end
            if UserCapsule then UserCapsule.Visible = true end
            if SearchPill then SearchPill.Visible = true end
            MinimizeBtn.Text = "-"
        end
    end

    getgenv().SetToxMinimized = SetMinimized
    MinimizeBtn.MouseButton1Click:Connect(function()
        SetMinimized(not isMinimized)
    end)
end

local function SetSidebarCollapsed(collapsed)
    if isMinimized or getgenv().ToxMainMinimized then return end
    isSidebarCollapsed = collapsed
    Settings.CollapseSidebar = isSidebarCollapsed
    local targetW = isSidebarCollapsed and sidebarCollapsedWidth or sidebarExpandedWidth

    TweenService:Create(Sidebar, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, targetW, 1, -TopBarHeight)
    }):Play()
    TweenService:Create(ContentArea, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, targetW, 0, TopBarHeight),
        Size = UDim2.new(1, -targetW, 1, -TopBarHeight)
    }):Play()

    CategoryLabel.Visible = not isSidebarCollapsed
    for _, btn in ipairs(SidebarScroll:GetChildren()) do
        if btn:IsA("TextButton") then
            local lbl = btn:FindFirstChild("ButtonLabel")
            if lbl then lbl.Visible = not isSidebarCollapsed end
            local icon = btn:FindFirstChild("ButtonIcon")
            if icon then
                icon.Position = isSidebarCollapsed and UDim2.new(0.5, -10, 0.5, -10) or UDim2.new(0, 10, 0.5, -10)
            end
        end
    end
    if getgenv().AutoSaveConfiguration then
        getgenv().AutoSaveConfiguration()
    end
end

-- Make Window Resizable if supported
if getgenv().MakeResizable then
    getgenv().MakeResizable(Main, "Main", Vector2.new(380, 260), Vector2.new(8192, 8192))
end

-- Responsive TopBar capsule adjustment
local function updateResponsiveHeader()
    if not Main or not UserCapsule then return end
    local totalW = Main.AbsoluteSize.X
    if totalW < 600 then
        UserCapsule.Visible = false
        if GameTagPill then GameTagPill.Visible = false end
    elseif totalW < 720 then
        UserCapsule.Visible = true
        UserCapsule.Size = UDim2.new(0, 180, 0, 36)
        UserCapsule.Position = UDim2.new(1, -380, 0.5, -18)
        StatsContainer.Visible = false
        if GameTagPill then GameTagPill.Visible = false end
    else
        UserCapsule.Visible = true
        UserCapsule.Size = UDim2.new(0, 240, 0, 36)
        UserCapsule.Position = UDim2.new(1, -440, 0.5, -18)
        StatsContainer.Visible = true
        if GameTagPill then GameTagPill.Visible = true end
    end
end
Main:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateResponsiveHeader)
task.defer(updateResponsiveHeader)

-- Rainbow loop listener
local lastRainbowTick = 0
RunService.RenderStepped:Connect(function()
    if env.Destroyed then return end
    if Settings.UIRainbow == true then
        local now = os.clock()
        if now - lastRainbowTick >= 0.032 then
            lastRainbowTick = now
            local col = getgenv().ToxGetRainbowColor(Settings.UIRainbowSpeed or 35, 0)
            local col2 = getgenv().ToxGetRainbowColor(Settings.UIRainbowSpeed or 35, 0.12)
            SyncAccentOnly(col, col2)
        end
    end
end)

getgenv().ApplyToxTheme()
getgenv().SetToxUITransparency(Settings.ToxUITransparency or 0, true)

-- Register globals in UI table for subsequent modules
env.ToxUI = env.ToxUI or {}
local UI = env.ToxUI
UI.DefaultTheme = DefaultTheme
UI.Theme = Theme
UI.ThemedObjects = ThemedObjects
UI.RegisteredToggles = RegisteredToggles
UI.RegisterThemedObject = RegisterThemedObject
UI.ApplyTheme = ApplyTheme
UI.UIThemePresets = UIThemePresets
UI.ParentContainer = ParentContainer
UI.Gui = Gui
UI.DimmerFrame = DimmerFrame
UI.Main = Main
UI.MainGradient = MainGradient
UI.WallpaperImage = WallpaperImage
UI.WeatherContainer = WeatherContainer
UI.ScreenWeatherGui = ScreenWeatherGui
UI.Sidebar = Sidebar
UI.HubLogo = HubLogo
UI.SidebarScroll = SidebarScroll
UI.SetSidebarCollapsed = SetSidebarCollapsed
UI.IsSidebarCollapsed = function() return isSidebarCollapsed end
UI.ContentArea = ContentArea
UI.TopBar = TopBar
UI.CurrentTabTitle = CurrentTabTitle
UI.SearchPill = SearchPill
UI.SearchTextBox = SearchTextBox
UI.PagesContainer = PagesContainer
UI.UpdateWatermarkVisualRef = function(wf, wl)
    WatermarkFrame = wf
    WatermarkLabel = wl
end
UI.RegisterWeatherSetter = function(fn)
    SetWeatherType = fn
end
UI.RegisterColorPickerOpener = function(fn)
    OpenColorPicker = fn
end
UI.RegisterSearchScrollRef = function(sr)
    SearchResultsScroll = sr
end
