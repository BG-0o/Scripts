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
local MAIN_COLOR = env.MAIN_COLOR
local isMinimized = false
local WatermarkFrame = nil
local WatermarkLabel = nil
local SetWeatherType = nil
local OpenColorPicker = nil
local DefaultTheme = {
    Background = Color3.fromRGB(12, 12, 18),
    Panel = Color3.fromRGB(16, 16, 26),
    Element = Color3.fromRGB(22, 22, 34),
    Hover = Color3.fromRGB(30, 30, 48),
    Outline = Color3.fromRGB(48, 48, 72),
    Accent = Color3.fromRGB(30, 95, 255),
    Accent2 = Color3.fromRGB(145, 45, 255),
    Text = Color3.fromRGB(255, 255, 255),
    DimText = Color3.fromRGB(165, 165, 185),
    Risky = Color3.fromRGB(255, 55, 65)
}
if typeof(Settings.Theme) ~= "table" then
    Settings.Theme = {}
end
local UIThemePresets
for key, val in pairs(DefaultTheme) do
    if Settings.Theme[key] == nil then
        Settings.Theme[key] = val
    end
end
if Settings.CustomAccentActive ~= true and env.MAIN_COLOR and typeof(env.MAIN_COLOR) == "Color3" then
    if Settings.Theme.Accent == DefaultTheme.Accent then
        Settings.Theme.Accent = env.MAIN_COLOR
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
    table.insert(ThemedObjects, {Instance = instance, Prop = prop, Key = colorKey})
    pcall(function()
        instance[prop] = Theme[colorKey]
    end)
end
local function RegisterTransparentObject(instance, mode)
    if not instance then return end
    table.insert(TransparentObjects, {Instance = instance, Mode = mode or "Panel"})
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
        local r = math.clamp(math.floor(accentColor.R * 255 + 0.5), 0, 255)
        local g = math.clamp(math.floor(accentColor.G * 255 + 0.5), 0, 255)
        local b = math.clamp(math.floor(accentColor.B * 255 + 0.5), 0, 255)
        env.ToxUserExpiryLabel.Text = string.format('Expires: <font color="#%02x%02x%02x">lifetime</font>', r, g, b)
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
    Theme.Accent2 = Color3.fromHSV((h + 0.12) % 1, math.clamp(s, 0.35, 1), math.clamp(v, 0.45, 1))
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
            math.clamp(math.floor(selected.R * 255 * 0.4), 28, 76),
            math.clamp(math.floor(selected.G * 255 * 0.4), 28, 76),
            math.clamp(math.floor(selected.B * 255 * 0.4), 34, 86)
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
UIThemePresets = {
    ["Dark Neon"] = {
        Background = Color3.fromRGB(12, 12, 18),
        Panel = Color3.fromRGB(16, 16, 26),
        Element = Color3.fromRGB(22, 22, 34),
        Hover = Color3.fromRGB(30, 30, 48),
        Outline = Color3.fromRGB(36, 36, 56),
        Text = Color3.fromRGB(255, 255, 255),
        DimText = Color3.fromRGB(165, 165, 185),
        Risky = Color3.fromRGB(255, 55, 65)
    },
    ["OLED Black"] = {
        Background = Color3.fromRGB(4, 4, 6),
        Panel = Color3.fromRGB(10, 10, 14),
        Element = Color3.fromRGB(16, 16, 22),
        Hover = Color3.fromRGB(24, 24, 34),
        Outline = Color3.fromRGB(32, 32, 44),
        Text = Color3.fromRGB(255, 255, 255),
        DimText = Color3.fromRGB(150, 150, 170),
        Risky = Color3.fromRGB(255, 60, 70)
    },
    ["Clean White"] = {
        Background = Color3.fromRGB(240, 242, 248),
        Panel = Color3.fromRGB(255, 255, 255),
        Element = Color3.fromRGB(230, 234, 242),
        Hover = Color3.fromRGB(218, 222, 232),
        Outline = Color3.fromRGB(195, 200, 215),
        Text = Color3.fromRGB(20, 20, 30),
        DimText = Color3.fromRGB(95, 100, 115),
        Risky = Color3.fromRGB(220, 40, 50)
    },
    ["Translucent Glass"] = {
        Background = Color3.fromRGB(12, 12, 18),
        Panel = Color3.fromRGB(18, 18, 28),
        Element = Color3.fromRGB(24, 24, 36),
        Hover = Color3.fromRGB(34, 34, 50),
        Outline = Color3.fromRGB(45, 45, 68),
        Text = Color3.fromRGB(255, 255, 255),
        DimText = Color3.fromRGB(170, 170, 190),
        Risky = Color3.fromRGB(255, 55, 65)
    },
    ["Midnight Purple"] = {
        Background = Color3.fromRGB(14, 10, 22),
        Panel = Color3.fromRGB(20, 14, 32),
        Element = Color3.fromRGB(28, 20, 44),
        Hover = Color3.fromRGB(40, 28, 62),
        Outline = Color3.fromRGB(56, 38, 86),
        Text = Color3.fromRGB(255, 255, 255),
        DimText = Color3.fromRGB(175, 160, 200),
        Risky = Color3.fromRGB(255, 55, 65)
    },
    ["Cyberpunk Cyan"] = {
        Background = Color3.fromRGB(8, 14, 18),
        Panel = Color3.fromRGB(12, 20, 26),
        Element = Color3.fromRGB(18, 28, 36),
        Hover = Color3.fromRGB(24, 38, 50),
        Outline = Color3.fromRGB(32, 54, 70),
        Text = Color3.fromRGB(255, 255, 255),
        DimText = Color3.fromRGB(150, 185, 200),
        Risky = Color3.fromRGB(255, 55, 65)
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
            Theme.Accent = Color3.fromRGB(20, 100, 255)
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
    local strokeTransp = math.clamp(0.28 + val * 0.25, 0.2, 0.65)
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
local ParentContainer = (gethui and gethui()) or game:GetService("CoreGui")
local Gui = Instance.new("ScreenGui")
Gui.Name = "ToxV1Gui"
Gui.ResetOnSpawn = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.DisplayOrder = 999999999
Gui.Parent = ParentContainer
getgenv().Gui = Gui
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
local defaultInitSize = UDim2.new(0, 720, 0, 480)
local defaultInitPos = UDim2.new(0.5, -360, 0.5, -240)
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
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = Main
local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Theme.Accent
MainStroke.Thickness = 1
MainStroke.Transparency = 0.22
MainStroke.Parent = Main
RegisterThemedObject(MainStroke, "Color", "Accent")
local MainGradient = Instance.new("UIGradient")
MainGradient.Rotation = 90
MainGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(205, 205, 220))
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
local ContentArea = nil
local TopBar = nil
local SearchPill = nil
local SearchResultsScroll = nil
local PagesContainer = nil
local ResizeHandle = nil
local isSidebarCollapsed = Settings.CollapseSidebar == true
local sidebarExpandedWidth = tonumber(Settings.SidebarExpandedWidth) or 185
if sidebarExpandedWidth < 100 or sidebarExpandedWidth > 380 then sidebarExpandedWidth = 185 end
local sidebarCollapsedWidth = 56
local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, isSidebarCollapsed and sidebarCollapsedWidth or sidebarExpandedWidth, 1, 0)
Sidebar.Position = UDim2.new(0, 0, 0, 0)
Sidebar.BackgroundColor3 = Theme.Panel
Sidebar.BorderSizePixel = 0
Sidebar.ZIndex = 10
Sidebar.Parent = Main
RegisterThemedObject(Sidebar, "BackgroundColor3", "Panel")
local SidebarCorner = Instance.new("UICorner")
SidebarCorner.CornerRadius = UDim.new(0, 10)
SidebarCorner.Parent = Sidebar
local SidebarRightBorder = Instance.new("Frame")
SidebarRightBorder.Name = "RightBorder"
SidebarRightBorder.Size = UDim2.new(0, 1, 1, 0)
SidebarRightBorder.Position = UDim2.new(1, -1, 0, 0)
SidebarRightBorder.BackgroundColor3 = Theme.Outline
SidebarRightBorder.BorderSizePixel = 0
SidebarRightBorder.ZIndex = 11
SidebarRightBorder.Parent = Sidebar
RegisterThemedObject(SidebarRightBorder, "BackgroundColor3", "Outline")
local SidebarSplitter = Instance.new("TextButton")
SidebarSplitter.Name = "SidebarSplitter"
SidebarSplitter.Size = UDim2.new(0, 10, 1, 0)
SidebarSplitter.Position = UDim2.new(0, (isSidebarCollapsed and sidebarCollapsedWidth or sidebarExpandedWidth) - 5, 0, 0)
SidebarSplitter.BackgroundTransparency = 1
SidebarSplitter.BorderSizePixel = 0
SidebarSplitter.Text = ""
SidebarSplitter.AutoButtonColor = false
SidebarSplitter.ZIndex = 50
SidebarSplitter.Visible = not isSidebarCollapsed
SidebarSplitter.Parent = Main
do
local isDraggingSplitter = false
local splitterStartX = 0
local splitterStartWidth = 0
SidebarSplitter.Active = true
SidebarSplitter.MouseEnter:Connect(function()
    SidebarRightBorder.BackgroundColor3 = Theme.Accent
    SidebarRightBorder.Size = UDim2.new(0, 2, 1, 0)
end)
SidebarSplitter.MouseLeave:Connect(function()
    if not isDraggingSplitter then
        SidebarRightBorder.BackgroundColor3 = Theme.Outline
        SidebarRightBorder.Size = UDim2.new(0, 1, 1, 0)
    end
end)
SidebarSplitter.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDraggingSplitter = true
        splitterStartX = input.Position.X
        splitterStartWidth = Sidebar.AbsoluteSize.X
        SidebarRightBorder.BackgroundColor3 = Theme.Accent
        local moveConn, endConn
        moveConn = UserInputService.InputChanged:Connect(function(moveInput)
            if moveInput.UserInputType == Enum.UserInputType.MouseMovement or moveInput.UserInputType == Enum.UserInputType.Touch then
                local delta = moveInput.Position.X - splitterStartX
                local newW = math.clamp(splitterStartWidth + delta, 130, 320)
                sidebarExpandedWidth = newW
                Settings.SidebarExpandedWidth = newW
                if not isSidebarCollapsed then
                    Sidebar.Size = UDim2.new(0, newW, 1, 0)
                    SidebarSplitter.Position = UDim2.new(0, newW - 5, 0, 0)
                    if ContentArea then
                        ContentArea.Position = UDim2.new(0, newW, 0, 0)
                        ContentArea.Size = UDim2.new(1, -newW, 1, 0)
                    end
                end
            end
        end)
        endConn = UserInputService.InputEnded:Connect(function(endInput)
            if endInput.UserInputType == Enum.UserInputType.MouseButton1 or endInput.UserInputType == Enum.UserInputType.Touch then
                isDraggingSplitter = false
                SidebarRightBorder.BackgroundColor3 = Theme.Outline
                if moveConn then moveConn:Disconnect() end
                if endConn then endConn:Disconnect() end
                if getgenv().AutoSaveConfiguration then getgenv().AutoSaveConfiguration() end
            end
        end)
    end
end)
end
local SidebarHeader = Instance.new("Frame")
SidebarHeader.Name = "Header"
SidebarHeader.Size = UDim2.new(1, 0, 0, 56)
SidebarHeader.BackgroundTransparency = 1
SidebarHeader.ZIndex = 11
SidebarHeader.Parent = Sidebar
local HubLogo = Instance.new("ImageLabel")
HubLogo.Name = "HubLogo"
HubLogo.Size = UDim2.new(0, 34, 0, 34)
HubLogo.Position = UDim2.new(0, isSidebarCollapsed and 11 or 12, 0.5, -17)
HubLogo.BackgroundColor3 = Theme.Element
HubLogo.BackgroundTransparency = 0
HubLogo.Image = (Settings.CustomIconUrl and Settings.CustomIconUrl ~= "") and Settings.CustomIconUrl or LOGO_ID
HubLogo.ZIndex = 12
HubLogo.Parent = SidebarHeader
local LogoCorner = Instance.new("UICorner") LogoCorner.CornerRadius = UDim.new(0, 8) LogoCorner.Parent = HubLogo
local HubTitle = Instance.new("TextLabel")
HubTitle.Name = "HubTitle"
HubTitle.Size = UDim2.new(1, -95, 0, 20)
HubTitle.Position = UDim2.new(0, 54, 0, 10)
HubTitle.BackgroundTransparency = 1
HubTitle.Text = "ToxHub"
HubTitle.TextColor3 = Theme.Text
HubTitle.Font = Enum.Font.GothamBold
HubTitle.TextSize = 15
HubTitle.TextXAlignment = Enum.TextXAlignment.Left
HubTitle.Visible = not isSidebarCollapsed
HubTitle.ZIndex = 12
HubTitle.Parent = SidebarHeader
RegisterThemedObject(HubTitle, "TextColor3", "Text")
local HubVersion = Instance.new("TextLabel")
HubVersion.Name = "HubVersion"
HubVersion.Size = UDim2.new(1, -95, 0, 16)
HubVersion.Position = UDim2.new(0, 54, 0, 30)
HubVersion.BackgroundTransparency = 1
HubVersion.Text = "v2.0 Revolution"
HubVersion.TextColor3 = Theme.DimText
HubVersion.Font = Enum.Font.Gotham
HubVersion.TextSize = 10
HubVersion.TextXAlignment = Enum.TextXAlignment.Left
HubVersion.Visible = not isSidebarCollapsed
HubVersion.ZIndex = 12
HubVersion.Parent = SidebarHeader
RegisterThemedObject(HubVersion, "TextColor3", "DimText")
local CollapseSidebarBtn = Instance.new("TextButton")
CollapseSidebarBtn.Name = "CollapseBtn"
CollapseSidebarBtn.Size = UDim2.new(0, 22, 0, 22)
CollapseSidebarBtn.Position = isSidebarCollapsed and UDim2.new(0.5, -11, 0, 60) or UDim2.new(1, -28, 0.5, -11)
CollapseSidebarBtn.BackgroundColor3 = Theme.Element
CollapseSidebarBtn.BorderSizePixel = 0
CollapseSidebarBtn.Text = isSidebarCollapsed and ">" or "<"
CollapseSidebarBtn.TextColor3 = Theme.DimText
CollapseSidebarBtn.Font = Enum.Font.GothamBold
CollapseSidebarBtn.TextSize = 11
CollapseSidebarBtn.ZIndex = 14
CollapseSidebarBtn.Parent = SidebarHeader
local CollapseBtnCorner = Instance.new("UICorner") CollapseBtnCorner.CornerRadius = UDim.new(0, 5) CollapseBtnCorner.Parent = CollapseSidebarBtn
RegisterThemedObject(CollapseSidebarBtn, "BackgroundColor3", "Element")
RegisterThemedObject(CollapseSidebarBtn, "TextColor3", "DimText")
local CategoryLabel = Instance.new("TextLabel")
CategoryLabel.Name = "CategoryLabel"
CategoryLabel.Size = UDim2.new(1, -24, 0, 16)
CategoryLabel.Position = UDim2.new(0, 14, 0, 60)
CategoryLabel.BackgroundTransparency = 1
CategoryLabel.Text = "MAIN"
CategoryLabel.TextColor3 = Theme.DimText
CategoryLabel.Font = Enum.Font.GothamBold
CategoryLabel.TextSize = 9
CategoryLabel.TextXAlignment = Enum.TextXAlignment.Left
CategoryLabel.Visible = not isSidebarCollapsed
CategoryLabel.ZIndex = 11
CategoryLabel.Parent = Sidebar
RegisterThemedObject(CategoryLabel, "TextColor3", "DimText")
local SidebarScroll = Instance.new("ScrollingFrame")
SidebarScroll.Name = "SidebarScroll"
SidebarScroll.Size = UDim2.new(1, 0, 1, -135)
SidebarScroll.Position = UDim2.new(0, 0, 0, 80)
SidebarScroll.BackgroundTransparency = 1
SidebarScroll.BorderSizePixel = 0
SidebarScroll.ScrollBarThickness = 0
SidebarScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
SidebarScroll.ZIndex = 11
SidebarScroll.Parent = Sidebar
getgenv().Tabs = SidebarScroll
local SidebarLayout = Instance.new("UIListLayout")
SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
SidebarLayout.Padding = UDim.new(0, 4)
SidebarLayout.Parent = SidebarScroll
local SidebarPadding = Instance.new("UIPadding")
SidebarPadding.PaddingLeft = UDim.new(0, 5)
SidebarPadding.PaddingRight = UDim.new(0, 5)
SidebarPadding.Parent = SidebarScroll
SidebarLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    SidebarScroll.CanvasSize = UDim2.new(0, 0, 0, SidebarLayout.AbsoluteContentSize.Y + 10)
end)
local SidebarFooter = Instance.new("Frame")
SidebarFooter.Name = "SidebarFooter"
SidebarFooter.Size = UDim2.new(1, 0, 0, 52)
SidebarFooter.Position = UDim2.new(0, 0, 1, -52)
SidebarFooter.BackgroundColor3 = Theme.Panel
SidebarFooter.BorderSizePixel = 0
SidebarFooter.ZIndex = 11
SidebarFooter.Parent = Sidebar
RegisterThemedObject(SidebarFooter, "BackgroundColor3", "Panel")
local FooterTopBorder = Instance.new("Frame")
FooterTopBorder.Name = "TopBorder"
FooterTopBorder.Size = UDim2.new(1, 0, 0, 1)
FooterTopBorder.Position = UDim2.new(0, 0, 0, 0)
FooterTopBorder.BackgroundColor3 = Theme.Outline
FooterTopBorder.BorderSizePixel = 0
FooterTopBorder.ZIndex = 12
FooterTopBorder.Parent = SidebarFooter
RegisterThemedObject(FooterTopBorder, "BackgroundColor3", "Outline")
local UserAvatar = Instance.new("ImageLabel")
UserAvatar.Name = "UserAvatar"
UserAvatar.Size = UDim2.new(0, 32, 0, 32)
UserAvatar.Position = UDim2.new(0, isSidebarCollapsed and 12 or 10, 0.5, -16)
UserAvatar.BackgroundColor3 = Theme.Element
UserAvatar.BackgroundTransparency = 0
UserAvatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(Player.UserId) .. "&w=100&h=100"
UserAvatar.ZIndex = 13
UserAvatar.Parent = SidebarFooter
local AvatarCorner = Instance.new("UICorner") AvatarCorner.CornerRadius = UDim.new(1, 0) AvatarCorner.Parent = UserAvatar
local UserNameLabel = Instance.new("TextLabel")
UserNameLabel.Name = "UserName"
UserNameLabel.Size = UDim2.new(1, -54, 0, 16)
UserNameLabel.Position = UDim2.new(0, 48, 0, 9)
UserNameLabel.BackgroundTransparency = 1
UserNameLabel.Text = Player.DisplayName or Player.Name
UserNameLabel.TextColor3 = Theme.Text
UserNameLabel.Font = Enum.Font.GothamBold
UserNameLabel.TextSize = 11
UserNameLabel.TextXAlignment = Enum.TextXAlignment.Left
UserNameLabel.TextTruncate = Enum.TextTruncate.AtEnd
UserNameLabel.Visible = not isSidebarCollapsed
UserNameLabel.ZIndex = 13
UserNameLabel.Parent = SidebarFooter
RegisterThemedObject(UserNameLabel, "TextColor3", "Text")
local UserExpiryLabel = Instance.new("TextLabel")
UserExpiryLabel.Name = "UserExpiry"
UserExpiryLabel.Size = UDim2.new(1, -54, 0, 14)
UserExpiryLabel.Position = UDim2.new(0, 48, 0, 27)
UserExpiryLabel.BackgroundTransparency = 1
UserExpiryLabel.RichText = true
UserExpiryLabel.Text = "Expires: <font color=\"#1e5fff\">lifetime</font>"
UserExpiryLabel.TextColor3 = Theme.DimText
UserExpiryLabel.Font = Enum.Font.Gotham
UserExpiryLabel.TextSize = 10
UserExpiryLabel.TextXAlignment = Enum.TextXAlignment.Left
UserExpiryLabel.Visible = not isSidebarCollapsed
UserExpiryLabel.ZIndex = 13
UserExpiryLabel.Parent = SidebarFooter
env.ToxUserExpiryLabel = UserExpiryLabel
ContentArea = Instance.new("Frame")
ContentArea.Name = "ContentArea"
ContentArea.Size = UDim2.new(1, -(isSidebarCollapsed and sidebarCollapsedWidth or sidebarExpandedWidth), 1, 0)
ContentArea.Position = UDim2.new(0, isSidebarCollapsed and sidebarCollapsedWidth or sidebarExpandedWidth, 0, 0)
ContentArea.BackgroundTransparency = 1
ContentArea.ZIndex = 5
ContentArea.Parent = Main
local function SetSidebarCollapsed(collapsed)
    if isMinimized or getgenv().ToxMainMinimized then return end
    isSidebarCollapsed = collapsed
    Settings.CollapseSidebar = isSidebarCollapsed
    local targetW = isSidebarCollapsed and sidebarCollapsedWidth or sidebarExpandedWidth
    TweenService:Create(Sidebar, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, targetW, 1, 0)
    }):Play()
    TweenService:Create(ContentArea, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, targetW, 0, 0),
        Size = UDim2.new(1, -targetW, 1, 0)
    }):Play()
    if SidebarSplitter then
        SidebarSplitter.Visible = not isSidebarCollapsed
        SidebarSplitter.Position = UDim2.new(0, targetW - 5, 0, 0)
    end
    HubTitle.Visible = not isSidebarCollapsed
    HubVersion.Visible = not isSidebarCollapsed
    CategoryLabel.Visible = not isSidebarCollapsed
    UserNameLabel.Visible = not isSidebarCollapsed
    UserExpiryLabel.Visible = not isSidebarCollapsed
    if isSidebarCollapsed then
        SidebarFooter.Position = UDim2.new(0, 0, 1, -52)
        SidebarFooter.Size = UDim2.new(1, 0, 0, 52)
        SidebarScroll.Size = UDim2.new(1, 0, 1, -(56 + 52 + 28))
        UserAvatar.Size = UDim2.new(0, 30, 0, 30)
        UserAvatar.Position = UDim2.new(0.5, -15, 0.5, -15)
        CollapseSidebarBtn.Size = UDim2.new(0, 22, 0, 22)
        CollapseSidebarBtn.Position = UDim2.new(0.5, -11, 0, 58)
        CollapseSidebarBtn.Text = ">"
    else
        SidebarFooter.Position = UDim2.new(0, 0, 1, -52)
        SidebarFooter.Size = UDim2.new(1, 0, 0, 52)
        SidebarScroll.Size = UDim2.new(1, 0, 1, -(56 + 52 + 10))
        UserAvatar.Size = UDim2.new(0, 32, 0, 32)
        UserAvatar.Position = UDim2.new(0, 10, 0.5, -16)
        CollapseSidebarBtn.Size = UDim2.new(0, 22, 0, 22)
        CollapseSidebarBtn.Position = UDim2.new(1, -28, 0.5, -11)
        CollapseSidebarBtn.Text = "<"
    end
    for _, btn in ipairs(SidebarScroll:GetChildren()) do
        if btn:IsA("TextButton") then
            local lbl = btn:FindFirstChild("ButtonLabel")
            if lbl then lbl.Visible = not isSidebarCollapsed end
            local icon = btn:FindFirstChild("ButtonIcon")
            if icon then
                icon.Position = isSidebarCollapsed and UDim2.new(0.5, -10, 0.5, -10) or UDim2.new(0, 12, 0.5, -10)
            end
        end
    end
    if getgenv().AutoSaveConfiguration then
        getgenv().AutoSaveConfiguration()
    end
end
CollapseSidebarBtn.MouseButton1Click:Connect(function()
    SetSidebarCollapsed(not isSidebarCollapsed)
end)
TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 46)
TopBar.Position = UDim2.new(0, 0, 0, 0)
TopBar.BackgroundTransparency = 1
TopBar.ZIndex = 20
TopBar.Parent = ContentArea
MakeDraggable(Main, TopBar)
MakeDraggable(Main, SidebarHeader)
local CurrentTabTitle = Instance.new("TextLabel")
CurrentTabTitle.Name = "CurrentTabTitle"
CurrentTabTitle.Size = UDim2.new(1, -260, 1, 0)
CurrentTabTitle.Position = UDim2.new(0, 16, 0, 0)
CurrentTabTitle.BackgroundTransparency = 1
CurrentTabTitle.Text = "Home"
CurrentTabTitle.TextColor3 = Theme.Text
CurrentTabTitle.Font = Enum.Font.GothamBold
CurrentTabTitle.TextSize = 16
CurrentTabTitle.TextXAlignment = Enum.TextXAlignment.Left
CurrentTabTitle.ZIndex = 21
CurrentTabTitle.Parent = TopBar
RegisterThemedObject(CurrentTabTitle, "TextColor3", "Text")
SearchPill = Instance.new("Frame")
SearchPill.Name = "SearchPill"
SearchPill.Size = UDim2.new(0, 160, 0, 28)
SearchPill.Position = UDim2.new(1, -236, 0.5, -14)
SearchPill.BackgroundColor3 = Theme.Element
SearchPill.BorderSizePixel = 0
SearchPill.ZIndex = 22
SearchPill.Parent = TopBar
RegisterThemedObject(SearchPill, "BackgroundColor3", "Element")
local SearchPillCorner = Instance.new("UICorner") SearchPillCorner.CornerRadius = UDim.new(0, 6) SearchPillCorner.Parent = SearchPill
local SearchPillStroke = Instance.new("UIStroke") SearchPillStroke.Color = Theme.Outline SearchPillStroke.Thickness = 1 SearchPillStroke.Parent = SearchPill
RegisterThemedObject(SearchPillStroke, "Color", "Outline")
local SearchIconLabel = Instance.new("TextLabel")
SearchIconLabel.Size = UDim2.new(0, 24, 1, 0)
SearchIconLabel.Position = UDim2.new(0, 4, 0, 0)
SearchIconLabel.BackgroundTransparency = 1
SearchIconLabel.Text = "🔍"
SearchIconLabel.TextColor3 = Theme.DimText
SearchIconLabel.Font = Enum.Font.Gotham
SearchIconLabel.TextSize = 11
SearchIconLabel.ZIndex = 23
SearchIconLabel.Parent = SearchPill
local SearchTextBox = Instance.new("TextBox")
SearchTextBox.Name = "SearchTextBox"
SearchTextBox.Size = UDim2.new(1, -28, 1, 0)
SearchTextBox.Position = UDim2.new(0, 26, 0, 0)
SearchTextBox.BackgroundTransparency = 1
SearchTextBox.Text = ""
SearchTextBox.PlaceholderText = "search_"
SearchTextBox.PlaceholderColor3 = Theme.DimText
SearchTextBox.TextColor3 = Theme.Text
SearchTextBox.Font = Enum.Font.Gotham
SearchTextBox.TextSize = 11
SearchTextBox.ClearTextOnFocus = false
SearchTextBox.ZIndex = 23
SearchTextBox.Parent = SearchPill
RegisterThemedObject(SearchTextBox, "TextColor3", "Text")
RegisterThemedObject(SearchTextBox, "PlaceholderColor3", "DimText")
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Name = "Minimize"
MinimizeBtn.Size = UDim2.new(0, 28, 0, 28)
MinimizeBtn.Position = UDim2.new(1, -66, 0.5, -14)
MinimizeBtn.BackgroundColor3 = Theme.Element
MinimizeBtn.BorderSizePixel = 0
MinimizeBtn.Text = "-"
MinimizeBtn.TextColor3 = Theme.Text
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextSize = 16
MinimizeBtn.ZIndex = 22
MinimizeBtn.Parent = TopBar
RegisterThemedObject(MinimizeBtn, "BackgroundColor3", "Element")
RegisterThemedObject(MinimizeBtn, "TextColor3", "Text")
local MinCorner = Instance.new("UICorner") MinCorner.CornerRadius = UDim.new(0, 6) MinCorner.Parent = MinimizeBtn
getgenv().Minimize = MinimizeBtn
do
isMinimized = false
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
        if Main and Main.Size.Y.Offset > 50 then
            MainExpandedSize = Main.Size
            getgenv().ToxMainExpandedSize = MainExpandedSize
        end
        if resizeHandle then resizeHandle.Visible = false end
        if SidebarSplitter then SidebarSplitter.Visible = false end
        if Sidebar then Sidebar.Visible = false end
        if SidebarFooter then SidebarFooter.Visible = false end
        if UserAvatar then UserAvatar.Visible = false end
        if SearchPill then SearchPill.Visible = false end
        if PagesContainer then PagesContainer.Visible = false end
        if SearchResultsScroll then SearchResultsScroll.Visible = false end
        if ContentArea then
            ContentArea.Position = UDim2.new(0, 0, 0, 0)
            ContentArea.Size = UDim2.new(1, 0, 1, 0)
        end
        savedPageTitle = (CurrentTabTitle and CurrentTabTitle.Text) or "Home"
        if CurrentTabTitle then CurrentTabTitle.Text = "ToxHub" end
        if Main then
            Main.ClipsDescendants = true
            local refSz = getgenv().ToxMainExpandedSize or MainExpandedSize
            local currentW = refSz and refSz.X.Offset or 680
            if currentW < 180 then currentW = 180 end
            Main.Size = UDim2.new(0, currentW, 0, 46)
        end
        if MinimizeBtn then MinimizeBtn.Text = "+" end
    else
        local refSz = getgenv().ToxMainExpandedSize or MainExpandedSize
        local currentW = refSz and refSz.X.Offset or 680
        local currentH = refSz and refSz.Y.Offset or 480
        if currentW < 180 then currentW = 680 end
        if currentH < 120 then currentH = 480 end
        if Main then
            Main.Size = UDim2.new(0, currentW, 0, currentH)
            Main.ClipsDescendants = true
            if resizeHandle then resizeHandle.Visible = true end
        end
        if Sidebar then
            Sidebar.Size = UDim2.new(0, targetW, 1, 0)
            Sidebar.Visible = true
        end
        if SidebarFooter then SidebarFooter.Visible = true end
        if UserAvatar then UserAvatar.Visible = true end
        if SidebarSplitter then
            SidebarSplitter.Visible = not isSidebarCollapsed
            SidebarSplitter.Position = UDim2.new(0, targetW - 5, 0, 0)
        end
        if ContentArea then
            ContentArea.Position = UDim2.new(0, targetW, 0, 0)
            ContentArea.Size = UDim2.new(1, -targetW, 1, 0)
        end
        if PagesContainer then PagesContainer.Visible = true end
        if SearchPill then SearchPill.Visible = true end
        if CurrentTabTitle then CurrentTabTitle.Text = savedPageTitle or "Home" end
        if MinimizeBtn then MinimizeBtn.Text = "-" end
    end
end
getgenv().SetToxMinimized = SetMinimized
MinimizeBtn.MouseButton1Click:Connect(function()
    SetMinimized(not isMinimized)
end)
end
local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -34, 0.5, -14)
CloseBtn.BackgroundColor3 = Theme.Element
CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Theme.DimText
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 13
CloseBtn.ZIndex = 22
CloseBtn.Parent = TopBar
RegisterThemedObject(CloseBtn, "BackgroundColor3", "Element")
RegisterThemedObject(CloseBtn, "TextColor3", "DimText")
local CloseCorner = Instance.new("UICorner") CloseCorner.CornerRadius = UDim.new(0, 6) CloseCorner.Parent = CloseBtn
CloseBtn.MouseButton1Click:Connect(function()
    if getgenv().ToggleToxGui then
        getgenv().ToggleToxGui(false)
    else
        Main.Visible = false
        if DimmerFrame then DimmerFrame.Visible = false end
    end
end)
SearchResultsScroll = Instance.new("ScrollingFrame")
SearchResultsScroll.Name = "SearchResultsScroll"
SearchResultsScroll.Size = UDim2.new(0, 260, 0, 200)
SearchResultsScroll.Position = UDim2.new(1, -290, 0, 44)
SearchResultsScroll.BackgroundColor3 = Theme.Panel
SearchResultsScroll.BorderSizePixel = 0
SearchResultsScroll.ScrollBarThickness = 3
SearchResultsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
SearchResultsScroll.Visible = false
SearchResultsScroll.ZIndex = 50
SearchResultsScroll.ClipsDescendants = true
SearchResultsScroll.Parent = TopBar
RegisterThemedObject(SearchResultsScroll, "BackgroundColor3", "Panel")
local SearchResultsCorner = Instance.new("UICorner") SearchResultsCorner.CornerRadius = UDim.new(0, 8) SearchResultsCorner.Parent = SearchResultsScroll
local SearchResultsStroke = Instance.new("UIStroke") SearchResultsStroke.Color = Theme.Outline SearchResultsStroke.Thickness = 1 SearchResultsStroke.Transparency = 0.25 SearchResultsStroke.Parent = SearchResultsScroll
RegisterThemedObject(SearchResultsStroke, "Color", "Outline")
RegisterTransparentObject(SearchResultsScroll, "Panel")
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
PagesContainer = Instance.new("Frame")
PagesContainer.Name = "PagesContainer"
PagesContainer.Size = UDim2.new(1, 0, 1, -46)
PagesContainer.Position = UDim2.new(0, 0, 0, 46)
PagesContainer.BackgroundTransparency = 1
PagesContainer.ClipsDescendants = true
PagesContainer.ZIndex = 6
PagesContainer.Parent = ContentArea
if getgenv().MakeResizable then
    getgenv().MakeResizable(Main, "Main", Vector2.new(180, 120), Vector2.new(8192, 8192))
end
do
    local function updateResponsiveTopBar()
        if not ContentArea or not TopBar then return end
        local w = ContentArea.AbsoluteSize.X
        if isMinimized then
            if CurrentTabTitle then
                CurrentTabTitle.Size = UDim2.new(1, -90, 1, 0)
            end
            return
        end
        if SearchPill then
            if w < 215 then
                SearchPill.Visible = false
                if CurrentTabTitle then
                    CurrentTabTitle.Size = UDim2.new(1, -86, 1, 0)
                end
            else
                SearchPill.Visible = true
                local pillW = math.clamp(math.floor(w - 205), 68, 160)
                SearchPill.Size = UDim2.new(0, pillW, 0, 28)
                SearchPill.Position = UDim2.new(1, -(pillW + 76), 0.5, -14)
                if CurrentTabTitle then
                    CurrentTabTitle.Size = UDim2.new(1, -(pillW + 96), 1, 0)
                end
            end
        end
    end
    ContentArea:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateResponsiveTopBar)
    task.defer(updateResponsiveTopBar)

    local lastRainbowTick = 0
    RunService.RenderStepped:Connect(function()
        if env.Destroyed then return end
        if Settings.UIRainbow == true then
            local now = os.clock()
            if now - lastRainbowTick >= 0.032 then
                lastRainbowTick = now
                local col = getgenv().ToxGetRainbowColor(Settings.UIRainbowSpeed or 35, 0)
                local col2 = getgenv().ToxGetRainbowColor(Settings.UIRainbowSpeed or 35, 0.14)
                SyncAccentOnly(col, col2)
            end
        end
    end)
end
getgenv().ApplyToxTheme()
getgenv().SetToxUITransparency(Settings.ToxUITransparency or 0, true)
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
UI.SidebarSplitter = SidebarSplitter
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
