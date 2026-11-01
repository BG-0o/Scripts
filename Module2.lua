-- ==============================================================================
-- TOXHUB REVOLUTION UI ENGINE (Module2.lua)
-- BigFroot v1.2.0 & WASOR Classic Inspired
-- ==============================================================================

local env = getgenv()
getgenv().ToxOptionsReady = true
getgenv().ScriptLoaded = true
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

-- Shared UI references
local WatermarkFrame = nil
local WatermarkLabel = nil
local SetWeatherType = nil
local OpenColorPicker = nil


-- ==============================================================================
-- TOXHUB REVOLUTION UI ENGINE (BigFroot / Wasor Classic Inspired)
-- ==============================================================================

local DefaultTheme = {
    Background = Color3.fromRGB(12, 12, 18),
    Panel = Color3.fromRGB(16, 16, 26),
    Element = Color3.fromRGB(22, 22, 34),
    Hover = Color3.fromRGB(30, 30, 48),
    Outline = Color3.fromRGB(36, 36, 56),
    Accent = Color3.fromRGB(30, 95, 255),       -- Electric Blue
    Accent2 = Color3.fromRGB(145, 45, 255),     -- Vibrant Purple
    Text = Color3.fromRGB(255, 255, 255),
    DimText = Color3.fromRGB(165, 165, 185),
    Risky = Color3.fromRGB(255, 55, 65)         -- Danger Red
}

if typeof(Settings.Theme) ~= "table" then
    Settings.Theme = {}
end

for key, val in pairs(DefaultTheme) do
    if Settings.Theme[key] == nil then
        Settings.Theme[key] = val
    end
end

local Theme = Settings.Theme
MAIN_COLOR = Theme.Accent
getgenv().MAIN_COLOR = MAIN_COLOR

local ThemedObjects = {}
local function RegisterThemedObject(instance, prop, colorKey)
    if not instance then return end
    table.insert(ThemedObjects, {Instance = instance, Prop = prop, Key = colorKey})
    pcall(function()
        instance[prop] = Theme[colorKey]
    end)
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
end

getgenv().ApplyToxTheme = ApplyTheme
getgenv().SetToxGuiColor = function(colorName)
    local selected = GUIColorMap[tostring(colorName)]
    if selected then
        Theme.Accent = selected
        Theme.Outline = Color3.fromRGB(
            math.clamp(math.floor(selected.R * 255 * 0.4), 22, 70),
            math.clamp(math.floor(selected.G * 255 * 0.4), 22, 70),
            math.clamp(math.floor(selected.B * 255 * 0.4), 28, 80)
        )
        ApplyTheme()
        Settings.GUIColorName = tostring(colorName)
        if getgenv().AutoSaveConfiguration then
            getgenv().AutoSaveConfiguration()
        end
        return true
    end
    return false
end

-- ScreenGui Parent Container
local ParentContainer = (gethui and gethui()) or game:GetService("CoreGui")
local Gui = Instance.new("ScreenGui")
Gui.Name = "ToxV1Gui"
Gui.ResetOnSpawn = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.DisplayOrder = 999999999
Gui.Parent = ParentContainer
getgenv().Gui = Gui

-- Viewport Dimmer Frame
local DimmerFrame = Instance.new("TextButton")
DimmerFrame.Name = "DimmerFrame"
DimmerFrame.Size = UDim2.new(1, 0, 1, 0)
DimmerFrame.Position = UDim2.new(0, 0, 0, 0)
DimmerFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
DimmerFrame.BackgroundTransparency = 0.55
DimmerFrame.BorderSizePixel = 0
DimmerFrame.Text = ""
DimmerFrame.AutoButtonColor = false
DimmerFrame.Visible = Settings.DimBackground == true
DimmerFrame.ZIndex = 1
DimmerFrame.Parent = Gui

-- Main Window
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
MainStroke.Thickness = 1.5
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

-- Custom Wallpaper
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

-- Weather Particles Container
local WeatherContainer = Instance.new("Frame")
WeatherContainer.Name = "WeatherContainer"
WeatherContainer.Size = UDim2.new(1, 0, 1, 0)
WeatherContainer.Position = UDim2.new(0, 0, 0, 0)
WeatherContainer.BackgroundTransparency = 1
WeatherContainer.ClipsDescendants = true
WeatherContainer.ZIndex = 4
WeatherContainer.Parent = Main

-- Fullscreen Weather ScreenGui (optional when WeatherArea == "Screen")
local ScreenWeatherGui = Instance.new("ScreenGui")
ScreenWeatherGui.Name = "ToxScreenWeather"
ScreenWeatherGui.ResetOnSpawn = false
ScreenWeatherGui.DisplayOrder = 999999990
ScreenWeatherGui.Parent = ParentContainer

-- Left Sidebar
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

do
local SidebarSplitter = Instance.new("TextButton")
SidebarSplitter.Name = "SidebarSplitter"
SidebarSplitter.Size = UDim2.new(0, 10, 1, 0)
SidebarSplitter.Position = UDim2.new(1, -5, 0, 0)
SidebarSplitter.BackgroundTransparency = 1
SidebarSplitter.BorderSizePixel = 0
SidebarSplitter.Text = ""
SidebarSplitter.AutoButtonColor = false
SidebarSplitter.ZIndex = 16
SidebarSplitter.Parent = Sidebar

local isDraggingSplitter = false
local splitterStartX = 0
local splitterStartWidth = 0

SidebarSplitter.Active = true
SidebarSplitter.MouseEnter:Connect(function()
    SidebarRightBorder.BackgroundColor3 = Theme.Accent
end)
SidebarSplitter.MouseLeave:Connect(function()
    if not isDraggingSplitter then
        SidebarRightBorder.BackgroundColor3 = Theme.Outline
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
                local newW = math.clamp(splitterStartWidth + delta, 110, 360)
                sidebarExpandedWidth = newW
                Settings.SidebarExpandedWidth = newW
                if not isSidebarCollapsed then
                    Sidebar.Size = UDim2.new(0, newW, 1, 0)
                    ContentArea.Position = UDim2.new(0, newW, 0, 0)
                    ContentArea.Size = UDim2.new(1, -newW, 1, 0)
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

-- Sidebar Header
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
HubTitle.Size = UDim2.new(1, -60, 0, 20)
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
HubVersion.Size = UDim2.new(1, -60, 0, 16)
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

-- Category Label "Main"
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

-- Nav Scroll Container
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

-- Sidebar Footer / Profile Card
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
UserNameLabel.Size = UDim2.new(1, -78, 0, 16)
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
UserExpiryLabel.Size = UDim2.new(1, -78, 0, 14)
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

local CollapseSidebarBtn = Instance.new("TextButton")
CollapseSidebarBtn.Name = "CollapseBtn"
CollapseSidebarBtn.Size = UDim2.new(0, 22, 0, 22)
CollapseSidebarBtn.Position = UDim2.new(1, -26, 0.5, -11)
CollapseSidebarBtn.BackgroundColor3 = Theme.Element
CollapseSidebarBtn.BorderSizePixel = 0
CollapseSidebarBtn.Text = isSidebarCollapsed and ">" or "<"
CollapseSidebarBtn.TextColor3 = Theme.DimText
CollapseSidebarBtn.Font = Enum.Font.GothamBold
CollapseSidebarBtn.TextSize = 11
CollapseSidebarBtn.ZIndex = 14
CollapseSidebarBtn.Parent = SidebarFooter
local CollapseBtnCorner = Instance.new("UICorner") CollapseBtnCorner.CornerRadius = UDim.new(0, 5) CollapseBtnCorner.Parent = CollapseSidebarBtn
RegisterThemedObject(CollapseSidebarBtn, "BackgroundColor3", "Element")
RegisterThemedObject(CollapseSidebarBtn, "TextColor3", "DimText")

-- Content Area
local ContentArea = Instance.new("Frame")
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

    HubTitle.Visible = not isSidebarCollapsed
    HubVersion.Visible = not isSidebarCollapsed
    CategoryLabel.Visible = not isSidebarCollapsed
    UserNameLabel.Visible = not isSidebarCollapsed
    UserExpiryLabel.Visible = not isSidebarCollapsed
    if isSidebarCollapsed then
        SidebarFooter.Position = UDim2.new(0, 0, 1, -78)
        SidebarFooter.Size = UDim2.new(1, 0, 0, 78)
        SidebarScroll.Size = UDim2.new(1, 0, 1, -(48 + 78))
        UserAvatar.Size = UDim2.new(0, 26, 0, 26)
        UserAvatar.Position = UDim2.new(0.5, -13, 0, 8)
        CollapseSidebarBtn.Size = UDim2.new(0, 24, 0, 22)
        CollapseSidebarBtn.Position = UDim2.new(0.5, -12, 0, 46)
        CollapseSidebarBtn.Text = ">"
    else
        SidebarFooter.Position = UDim2.new(0, 0, 1, -52)
        SidebarFooter.Size = UDim2.new(1, 0, 0, 52)
        SidebarScroll.Size = UDim2.new(1, 0, 1, -(48 + 52))
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

-- TopBar
local TopBar = Instance.new("Frame")
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

-- Search Pill on top right
local SearchPill = Instance.new("Frame")
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

-- Minimize & Close
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
local isMinimized = false
local MainExpandedSize = Main.Size

local function SetMinimized(minimized)
    isMinimized = (minimized == true)
    getgenv().ToxMainMinimized = isMinimized
    getgenv().Minimized = isMinimized

    local handle = Main:FindFirstChild("ToxResizeHandle") or ResizeHandle
    if isMinimized then
        if Main.Size.Y.Offset > 46 then
            MainExpandedSize = Main.Size
            getgenv().ToxMainExpandedSize = MainExpandedSize
        end
        if handle then handle.Visible = false end
        for _, ch in ipairs(Main:GetChildren()) do
            if ch.Name == "ToxResizeHandle" then ch.Visible = false end
        end
        Sidebar.Visible = false
        SidebarFooter.Visible = false
        PagesContainer.Visible = false
        SearchResultsScroll.Visible = false
        ContentArea.Position = UDim2.new(0, 0, 0, 0)
        ContentArea.Size = UDim2.new(1, 0, 1, 0)
        Main.ClipsDescendants = true
        Main.Size = UDim2.new(MainExpandedSize.X.Scale, MainExpandedSize.X.Offset, 0, 46)
        MinimizeBtn.Text = "+"
    else
        Main.Size = MainExpandedSize
        Sidebar.Visible = true
        SidebarFooter.Visible = true
        PagesContainer.Visible = true
        if handle then handle.Visible = true end
        for _, ch in ipairs(Main:GetChildren()) do
            if ch.Name == "ToxResizeHandle" then ch.Visible = true end
        end
        local targetW = isSidebarCollapsed and sidebarCollapsedWidth or sidebarExpandedWidth
        ContentArea.Position = UDim2.new(0, targetW, 0, 0)
        ContentArea.Size = UDim2.new(1, -targetW, 1, 0)
        MinimizeBtn.Text = "-"
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

-- Search Results Floating Dropdown
local SearchResultsScroll = Instance.new("ScrollingFrame")
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
local SearchResultsStroke = Instance.new("UIStroke") SearchResultsStroke.Color = Theme.Outline SearchResultsStroke.Thickness = 1.2 SearchResultsStroke.Parent = SearchResultsScroll
RegisterThemedObject(SearchResultsStroke, "Color", "Outline")

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

-- Pages Container
local PagesContainer = Instance.new("Frame")
PagesContainer.Name = "PagesContainer"
PagesContainer.Size = UDim2.new(1, 0, 1, -46)
PagesContainer.Position = UDim2.new(0, 0, 0, 46)
PagesContainer.BackgroundTransparency = 1
PagesContainer.ClipsDescendants = true
PagesContainer.ZIndex = 6
PagesContainer.Parent = ContentArea

-- Resize Handle
local ResizeHandle = Instance.new("TextButton")
ResizeHandle.Name = "ResizeHandle"
ResizeHandle.Size = UDim2.new(0, 20, 0, 20)
ResizeHandle.Position = UDim2.new(1, -20, 1, -20)
ResizeHandle.BackgroundTransparency = 1
ResizeHandle.BorderSizePixel = 0
ResizeHandle.Text = "◢"
ResizeHandle.TextColor3 = Theme.DimText
ResizeHandle.TextSize = 14
ResizeHandle.Font = Enum.Font.GothamBold
ResizeHandle.ZIndex = 100
ResizeHandle.Parent = Main
RegisterThemedObject(ResizeHandle, "TextColor3", "DimText")

if getgenv().MakeResizable then
    getgenv().MakeResizable(Main, "Main", Vector2.new(160, 90), Vector2.new(3840, 2160))
end


-- ==============================================================================
-- CARD ENGINE & REORDERING SYSTEM
-- ==============================================================================

local CardRegistry = {}
local CardLayoutOrder = typeof(Settings.CardLayoutOrder) == "table" and Settings.CardLayoutOrder or {}
Settings.CardLayoutOrder = CardLayoutOrder

local function GetCardOrder(cardKey, defaultOrder)
    if CardLayoutOrder[cardKey] ~= nil then
        return tonumber(CardLayoutOrder[cardKey]) or defaultOrder
    end
    return defaultOrder
end

local function CreateCard(Page, Title, Icon, DefaultOrder, CardKey)
    CardKey = CardKey or (tostring(Page.Name or "P") .. "_" .. tostring(Title):gsub("%s+", ""))
    DefaultOrder = DefaultOrder or (#Page:GetChildren() + 1)
    local currentOrder = GetCardOrder(CardKey, DefaultOrder)

    local Card = Instance.new("Frame")
    Card.Name = "Card_" .. tostring(Title):gsub("%s+", "")
    Card:SetAttribute("CardKey", CardKey)
    Card:SetAttribute("DefaultOrder", DefaultOrder)
    Card.Size = UDim2.new(1, -6, 0, 36)
    Card.AutomaticSize = Enum.AutomaticSize.Y
    Card.BackgroundColor3 = Theme.Panel
    Card.BorderSizePixel = 0
    Card.LayoutOrder = currentOrder
    Card.ZIndex = 7
    Card.Parent = Page
    RegisterThemedObject(Card, "BackgroundColor3", "Panel")

    local CardCorner = Instance.new("UICorner")
    CardCorner.CornerRadius = UDim.new(0, 8)
    CardCorner.Parent = Card

    local CardStroke = Instance.new("UIStroke")
    CardStroke.Color = Theme.Outline
    CardStroke.Thickness = 1.2
    CardStroke.Transparency = 0.2
    CardStroke.Parent = Card
    RegisterThemedObject(CardStroke, "Color", "Outline")

    local CardLayout = Instance.new("UIListLayout")
    CardLayout.SortOrder = Enum.SortOrder.LayoutOrder
    CardLayout.Padding = UDim.new(0, 0)
    CardLayout.Parent = Card

    -- Header (36px)
    local Header = Instance.new("Frame")
    Header.Name = "Header"
    Header.LayoutOrder = 1
    Header.Size = UDim2.new(1, 0, 0, 36)
    Header.BackgroundTransparency = 1
    Header.ZIndex = 8
    Header.Parent = Card

    local IconLabel = Instance.new("TextLabel")
    IconLabel.Name = "Icon"
    IconLabel.Size = UDim2.new(0, 24, 1, 0)
    IconLabel.Position = UDim2.new(0, 10, 0, 0)
    IconLabel.BackgroundTransparency = 1
    IconLabel.Text = Icon or "🔹"
    IconLabel.TextColor3 = Theme.Accent
    IconLabel.Font = Enum.Font.GothamBold
    IconLabel.TextSize = 13
    IconLabel.ZIndex = 9
    IconLabel.Parent = Header
    RegisterThemedObject(IconLabel, "TextColor3", "Accent")

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Name = "Title"
    TitleLabel.Size = UDim2.new(1, -120, 1, 0)
    TitleLabel.Position = UDim2.new(0, 36, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = Title
    TitleLabel.TextColor3 = Theme.Text
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextSize = 13
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.ZIndex = 9
    TitleLabel.Parent = Header
    RegisterThemedObject(TitleLabel, "TextColor3", "Text")

    -- Move/Reorder Button (+)
    local ReorderBtn = Instance.new("TextButton")
    ReorderBtn.Name = "ReorderBtn"
    ReorderBtn.Size = UDim2.new(0, 24, 0, 24)
    ReorderBtn.Position = UDim2.new(1, -58, 0.5, -12)
    ReorderBtn.BackgroundColor3 = Theme.Element
    ReorderBtn.BorderSizePixel = 0
    ReorderBtn.Text = "+"
    ReorderBtn.TextColor3 = Theme.DimText
    ReorderBtn.Font = Enum.Font.GothamBold
    ReorderBtn.TextSize = 15
    ReorderBtn.ZIndex = 9
    ReorderBtn.Parent = Header
    RegisterThemedObject(ReorderBtn, "BackgroundColor3", "Element")
    RegisterThemedObject(ReorderBtn, "TextColor3", "DimText")
    local ReorderCorner = Instance.new("UICorner") ReorderCorner.CornerRadius = UDim.new(0, 5) ReorderCorner.Parent = ReorderBtn

    -- Collapse Chevron (v / ^)
    local CollapseBtn = Instance.new("TextButton")
    CollapseBtn.Name = "CollapseBtn"
    CollapseBtn.Size = UDim2.new(0, 24, 0, 24)
    CollapseBtn.Position = UDim2.new(1, -30, 0.5, -12)
    CollapseBtn.BackgroundColor3 = Theme.Element
    CollapseBtn.BorderSizePixel = 0
    CollapseBtn.Text = "v"
    CollapseBtn.TextColor3 = Theme.DimText
    CollapseBtn.Font = Enum.Font.GothamBold
    CollapseBtn.TextSize = 11
    CollapseBtn.ZIndex = 9
    CollapseBtn.Parent = Header
    RegisterThemedObject(CollapseBtn, "BackgroundColor3", "Element")
    RegisterThemedObject(CollapseBtn, "TextColor3", "DimText")
    local CollapseCorner = Instance.new("UICorner") CollapseCorner.CornerRadius = UDim.new(0, 5) CollapseCorner.Parent = CollapseBtn

    -- Quick Arrow Buttons popup (▲ / ▼)
    local ArrowFrame = Instance.new("Frame")
    ArrowFrame.Name = "ArrowFrame"
    ArrowFrame.Size = UDim2.new(0, 52, 0, 24)
    ArrowFrame.Position = UDim2.new(1, -114, 0.5, -12)
    ArrowFrame.BackgroundTransparency = 1
    ArrowFrame.Visible = false
    ArrowFrame.ZIndex = 10
    ArrowFrame.Parent = Header

    local UpBtn = Instance.new("TextButton")
    UpBtn.Size = UDim2.new(0, 24, 0, 24)
    UpBtn.Position = UDim2.new(0, 0, 0, 0)
    UpBtn.BackgroundColor3 = Theme.Element
    UpBtn.BorderSizePixel = 0
    UpBtn.Text = "▲"
    UpBtn.TextColor3 = Theme.Accent
    UpBtn.Font = Enum.Font.GothamBold
    UpBtn.TextSize = 10
    UpBtn.ZIndex = 10
    UpBtn.Parent = ArrowFrame
    local UpCorner = Instance.new("UICorner") UpCorner.CornerRadius = UDim.new(0, 5) UpCorner.Parent = UpBtn
    RegisterThemedObject(UpBtn, "BackgroundColor3", "Element")
    RegisterThemedObject(UpBtn, "TextColor3", "Accent")

    local DownBtn = Instance.new("TextButton")
    DownBtn.Size = UDim2.new(0, 24, 0, 24)
    DownBtn.Position = UDim2.new(0, 28, 0, 0)
    DownBtn.BackgroundColor3 = Theme.Element
    DownBtn.BorderSizePixel = 0
    DownBtn.Text = "▼"
    DownBtn.TextColor3 = Theme.Accent
    DownBtn.Font = Enum.Font.GothamBold
    DownBtn.TextSize = 10
    DownBtn.ZIndex = 10
    DownBtn.Parent = ArrowFrame
    local DownCorner = Instance.new("UICorner") DownCorner.CornerRadius = UDim.new(0, 5) DownCorner.Parent = DownBtn
    RegisterThemedObject(DownBtn, "BackgroundColor3", "Element")
    RegisterThemedObject(DownBtn, "TextColor3", "Accent")

    -- Content container inside Card
    local Content = Instance.new("Frame")
    Content.Name = "Content"
    Content.LayoutOrder = 2
    Content.Size = UDim2.new(1, 0, 0, 0)
    Content.AutomaticSize = Enum.AutomaticSize.Y
    Content.BackgroundTransparency = 1
    Content.ZIndex = 8
    Content.Parent = Card

    local ContentLayout = Instance.new("UIListLayout")
    ContentLayout.Padding = UDim.new(0, 5)
    ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ContentLayout.Parent = Content

    local ContentPadding = Instance.new("UIPadding")
    ContentPadding.PaddingLeft = UDim.new(0, 8)
    ContentPadding.PaddingRight = UDim.new(0, 8)
    ContentPadding.PaddingBottom = UDim.new(0, 10)
    ContentPadding.Parent = Content

    -- Collapse Handler
    local isCollapsed = false
    CollapseBtn.MouseButton1Click:Connect(function()
        isCollapsed = not isCollapsed
        Content.Visible = not isCollapsed
        CollapseBtn.Text = isCollapsed and "^" or "v"
    end)

    -- Toggle quick arrows popup
    ReorderBtn.MouseButton1Click:Connect(function()
        ArrowFrame.Visible = not ArrowFrame.Visible
    end)

    -- Swap with sibling card
    local function SwapWithSibling(direction)
        local siblings = {}
        for _, child in ipairs(Page:GetChildren()) do
            if child:IsA("Frame") and child:GetAttribute("CardKey") then
                table.insert(siblings, child)
            end
        end
        table.sort(siblings, function(a, b) return a.LayoutOrder < b.LayoutOrder end)
        local myIndex = table.find(siblings, Card)
        if not myIndex then return end
        local targetIndex = myIndex + direction
        if targetIndex >= 1 and targetIndex <= #siblings then
            local other = siblings[targetIndex]
            local temp = Card.LayoutOrder
            Card.LayoutOrder = other.LayoutOrder
            other.LayoutOrder = temp
            CardLayoutOrder[Card:GetAttribute("CardKey")] = Card.LayoutOrder
            CardLayoutOrder[other:GetAttribute("CardKey")] = other.LayoutOrder
            Settings.CardLayoutOrder = CardLayoutOrder
            if getgenv().AutoSaveConfiguration then
                getgenv().AutoSaveConfiguration()
            end
        end
    end

    UpBtn.MouseButton1Click:Connect(function() SwapWithSibling(-1) end)
    DownBtn.MouseButton1Click:Connect(function() SwapWithSibling(1) end)

    -- Press & Drag to reorder
    ReorderBtn.InputBegan:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and Settings.DraggableCards ~= false then
            local isDraggingCard = true
            CardStroke.Color = Theme.Accent
            Card.BackgroundTransparency = 0.25

            local moveConn, endConn
            moveConn = UserInputService.InputChanged:Connect(function(change)
                if change.UserInputType == Enum.UserInputType.MouseMovement or change.UserInputType == Enum.UserInputType.Touch then
                    local mouseY = change.Position.Y
                    for _, sibling in ipairs(Page:GetChildren()) do
                        if sibling ~= Card and sibling:IsA("Frame") and sibling:GetAttribute("CardKey") then
                            local sibY = sibling.AbsolutePosition.Y
                            local sibH = sibling.AbsoluteSize.Y
                            if mouseY >= sibY and mouseY <= sibY + sibH then
                                if sibling.LayoutOrder ~= Card.LayoutOrder then
                                    local temp = Card.LayoutOrder
                                    Card.LayoutOrder = sibling.LayoutOrder
                                    sibling.LayoutOrder = temp
                                end
                                break
                            end
                        end
                    end
                end
            end)

            endConn = UserInputService.InputEnded:Connect(function(ended)
                if ended.UserInputType == Enum.UserInputType.MouseButton1 or ended.UserInputType == Enum.UserInputType.Touch then
                    isDraggingCard = false
                    CardStroke.Color = Theme.Outline
                    Card.BackgroundTransparency = 0
                    if moveConn then moveConn:Disconnect() end
                    if endConn then endConn:Disconnect() end
                    for _, child in ipairs(Page:GetChildren()) do
                        if child:IsA("Frame") and child:GetAttribute("CardKey") then
                            CardLayoutOrder[child:GetAttribute("CardKey")] = child.LayoutOrder
                        end
                    end
                    Settings.CardLayoutOrder = CardLayoutOrder
                    if getgenv().AutoSaveConfiguration then
                        getgenv().AutoSaveConfiguration()
                    end
                end
            end)
        end
    end)

    table.insert(CardRegistry, Card)
    return Card
end
getgenv().CreateCard = CreateCard

local ActivePageCards = {}

local function CreateSection(Page, Title, Icon)
    local card = CreateCard(Page, Title, Icon)
    if Page then
        ActivePageCards[Page] = card
    end
    return card
end
getgenv().CreateSection = CreateSection

local function ResolveElementParent(Page)
    if Page then
        local activeCard = ActivePageCards[Page]
        if activeCard and activeCard:FindFirstChild("Content") then
            return activeCard.Content
        end
    end
    return Page
end
getgenv().ResolveElementParent = ResolveElementParent

-- ==============================================================================
-- PAGES ENGINE
-- ==============================================================================

local Pages = {}
getgenv().Pages = Pages

local function CreatePage(Name, RawPage)
    local Page = Instance.new("ScrollingFrame")
    Page.Name = Name
    Page.Size = UDim2.new(1, -20, 1, -12)
    Page.Position = UDim2.new(0, 10, 0, 6)
    Page.BackgroundTransparency = 1
    Page.BorderSizePixel = 0
    Page.ScrollBarThickness = RawPage and 0 or 3
    Page.ScrollBarImageColor3 = Theme.Accent
    Page.CanvasSize = UDim2.new(0, 0, 0, 0)
    pcall(function() Page.AutomaticCanvasSize = RawPage and Enum.AutomaticSize.None or Enum.AutomaticSize.Y end)
    Page.ScrollingEnabled = not RawPage
    Page.Visible = false
    Page.ClipsDescendants = true
    Page.Parent = PagesContainer
    RegisterThemedObject(Page, "ScrollBarImageColor3", "Accent")

    local Layout = nil
    if not RawPage then
        Layout = Instance.new("UIListLayout")
        Layout.Padding = UDim.new(0, 8)
        Layout.SortOrder = Enum.SortOrder.LayoutOrder
        Layout.Parent = Page

        local Padding = Instance.new("UIPadding")
        Padding.PaddingTop = UDim.new(0, 4)
        Padding.PaddingBottom = UDim.new(0, 12)
        Padding.PaddingLeft = UDim.new(0, 2)
        Padding.PaddingRight = UDim.new(0, 2)
        Padding.Parent = Page

        Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Page.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y + 20)
        end)
    end

    Pages[Name] = Page
    return Page, Layout
end
getgenv().CreatePage = CreatePage

-- Initialize Standard Pages
local HomePage = CreatePage("HOME")
local DetectedGameModule = getgenv().CurrentGameModule
local GamePage = nil
if DetectedGameModule and DetectedGameModule.Ready then
    GamePage = CreatePage(DetectedGameModule.ShortName)
end

local CombatPage = CreatePage("UNIVERSAL_COMBAT")
local PlayerPage = CreatePage("UNIVERSAL_PLAYER")
local VisualsPage = CreatePage("UNIVERSAL_ESP")
local LightingPage = CreatePage("UNIVERSAL_LIGHTING")
local FlingPage = CreatePage("UNIVERSAL_MISC")
local UniversalPage = CombatPage

local ScriptsPage = CreatePage("SCRIPTS")
local JoinPage = CreatePage("JOIN")
local ChatPage = CreatePage("CHAT", true)
local ControlPage = CreatePage("CONTROL", true)
local SettingsPage = CreatePage("SETTINGS")
local ConfigPage = SettingsPage
getgenv().ConfigPage = SettingsPage
getgenv().SettingsPage = SettingsPage

getgenv().HomePage = HomePage
getgenv().GamePage = GamePage
getgenv().UniversalPage = UniversalPage
getgenv().CombatPage = CombatPage
getgenv().PlayerPage = PlayerPage
getgenv().VisualsPage = VisualsPage
getgenv().LightingPage = LightingPage
getgenv().FlingPage = FlingPage
getgenv().ScriptsPage = ScriptsPage
getgenv().JoinPage = JoinPage
getgenv().ChatPage = ChatPage
getgenv().ControlPage = ControlPage
getgenv().ConfigPage = ConfigPage
getgenv().SettingsPage = SettingsPage

getgenv().UniversalSubPages = {
    [CombatPage] = "COMBAT",
    [PlayerPage] = "PLAYER",
    [VisualsPage] = "ESP",
    [LightingPage] = "LIGHTING",
    [FlingPage] = "MISC"
}

getgenv().UniversalTabs = Instance.new("Frame")
getgenv().UniversalTabs.Name = "DummyUniversalTabs"
getgenv().UniversalTabs.Visible = false
getgenv().UniversalTabs.Parent = Main
getgenv().UniversalTabLayout = Instance.new("UIListLayout")
getgenv().UniversalTabLayout.Parent = getgenv().UniversalTabs

-- Sidebar Tabs Builder
local SidebarNavButtons = {}
local CurrentActivePage = HomePage
getgenv().CurrentPage = HomePage

local function CreateSidebarNavButton(name, iconText, page, order)
    local Button = Instance.new("TextButton")
    Button.Name = "Nav_" .. tostring(name)
    Button.Size = UDim2.new(1, -6, 0, 36)
    Button.BackgroundColor3 = Theme.Hover
    Button.BackgroundTransparency = 1
    Button.BorderSizePixel = 0
    Button.Text = ""
    Button.AutoButtonColor = false
    Button.LayoutOrder = order or #SidebarScroll:GetChildren()
    Button.ZIndex = 12
    Button.Parent = SidebarScroll

    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 6)
    BtnCorner.Parent = Button

    -- Active indicator bar on far left
    local IndicatorBar = Instance.new("Frame")
    IndicatorBar.Name = "IndicatorBar"
    IndicatorBar.Size = UDim2.new(0, 3, 0.7, 0)
    IndicatorBar.Position = UDim2.new(0, 0, 0.15, 0)
    IndicatorBar.BackgroundColor3 = Theme.Accent
    IndicatorBar.BorderSizePixel = 0
    IndicatorBar.Visible = false
    IndicatorBar.ZIndex = 13
    IndicatorBar.Parent = Button
    local IndCorner = Instance.new("UICorner") IndCorner.CornerRadius = UDim.new(0, 2) IndCorner.Parent = IndicatorBar
    RegisterThemedObject(IndicatorBar, "BackgroundColor3", "Accent")

    -- Icon Label
    local IconLabel = Instance.new("TextLabel")
    IconLabel.Name = "ButtonIcon"
    IconLabel.Size = UDim2.new(0, 20, 0, 20)
    IconLabel.Position = UDim2.new(0, isSidebarCollapsed and 12 or 10, 0.5, -10)
    IconLabel.BackgroundTransparency = 1
    IconLabel.Text = iconText or "🔹"
    IconLabel.TextColor3 = Theme.DimText
    IconLabel.Font = Enum.Font.GothamBold
    IconLabel.TextSize = 13
    IconLabel.ZIndex = 13
    IconLabel.Parent = Button
    RegisterThemedObject(IconLabel, "TextColor3", "DimText")

    -- Label Text
    local TextLabel = Instance.new("TextLabel")
    TextLabel.Name = "ButtonLabel"
    TextLabel.Size = UDim2.new(1, -40, 1, 0)
    TextLabel.Position = UDim2.new(0, 36, 0, 0)
    TextLabel.BackgroundTransparency = 1
    TextLabel.Text = name
    TextLabel.TextColor3 = Theme.DimText
    TextLabel.Font = Enum.Font.GothamMedium
    TextLabel.TextSize = 12
    TextLabel.TextXAlignment = Enum.TextXAlignment.Left
    TextLabel.Visible = not isSidebarCollapsed
    TextLabel.ZIndex = 13
    TextLabel.Parent = Button
    RegisterThemedObject(TextLabel, "TextColor3", "DimText")

    local function SetActive(active)
        IndicatorBar.Visible = active
        Button.BackgroundTransparency = active and 0 or 1
        Button.BackgroundColor3 = active and Theme.Element or Theme.Hover
        IconLabel.TextColor3 = active and Theme.Accent or Theme.DimText
        TextLabel.TextColor3 = active and Theme.Text or Theme.DimText
        TextLabel.Font = active and Enum.Font.GothamBold or Enum.Font.GothamMedium
    end

    Button.MouseEnter:Connect(function()
        if CurrentActivePage ~= page then
            Button.BackgroundTransparency = 0.5
            Button.BackgroundColor3 = Theme.Element
        end
    end)

    Button.MouseLeave:Connect(function()
        if CurrentActivePage ~= page then
            Button.BackgroundTransparency = 1
        end
    end)

    Button.MouseButton1Click:Connect(function()
        if getgenv().Destroyed then return end
        if getgenv().ToxOpenPage then
            getgenv().ToxOpenPage(page)
        end
    end)

    SidebarNavButtons[page] = {
        Button = Button,
        SetActive = SetActive,
        Name = name
    }

    return Button
end

getgenv().CreateTab = function(Name, Page)
    return CreateSidebarNavButton(Name, "📌", Page)
end

-- Create Standard Sidebar Items
CreateSidebarNavButton("Home", "🏠", HomePage, 1)
if GamePage and DetectedGameModule then
    local gameLabel = DetectedGameModule.ShortName or "Game"
    CreateSidebarNavButton(gameLabel, "🎮", GamePage, 2)
end
CreateSidebarNavButton("Combat", "⚔️", CombatPage, 3)
CreateSidebarNavButton("Visuals", "👁️", VisualsPage, 4)
CreateSidebarNavButton("Player", "👤", PlayerPage, 5)
CreateSidebarNavButton("Lighting", "💡", LightingPage, 6)
CreateSidebarNavButton("Extras", "✨", FlingPage, 7)
CreateSidebarNavButton("Scripts", "📜", ScriptsPage, 8)
CreateSidebarNavButton("Join", "🌐", JoinPage, 9)
CreateSidebarNavButton("Chat", "💬", ChatPage, 10)
CreateSidebarNavButton("Control", "🛡️", ControlPage, 11)
CreateSidebarNavButton("Settings", "⚙️", SettingsPage, 12)

getgenv().UniversalTab = SidebarNavButtons[CombatPage] and SidebarNavButtons[CombatPage].Button
getgenv().CombatTab = getgenv().UniversalTab
getgenv().PlayerTab = SidebarNavButtons[PlayerPage] and SidebarNavButtons[PlayerPage].Button
getgenv().VisualsTab = SidebarNavButtons[VisualsPage] and SidebarNavButtons[VisualsPage].Button
getgenv().LightingTab = SidebarNavButtons[LightingPage] and SidebarNavButtons[LightingPage].Button
getgenv().FlingTab = SidebarNavButtons[FlingPage] and SidebarNavButtons[FlingPage].Button
getgenv().ScriptsTab = SidebarNavButtons[ScriptsPage] and SidebarNavButtons[ScriptsPage].Button
getgenv().JoinTab = SidebarNavButtons[JoinPage] and SidebarNavButtons[JoinPage].Button
getgenv().ChatTab = SidebarNavButtons[ChatPage] and SidebarNavButtons[ChatPage].Button
getgenv().ControlTab = SidebarNavButtons[ControlPage] and SidebarNavButtons[ControlPage].Button
getgenv().ConfigTab = SidebarNavButtons[SettingsPage] and SidebarNavButtons[SettingsPage].Button

getgenv().ToxPageNamesByPage = getgenv().ToxPageNamesByPage or {}
getgenv().ToxPageNamesByPage[HomePage] = "Home"
getgenv().ToxPageNamesByPage[CombatPage] = "Combat"
getgenv().ToxPageNamesByPage[PlayerPage] = "Player"
getgenv().ToxPageNamesByPage[VisualsPage] = "Visuals / ESP"
getgenv().ToxPageNamesByPage[LightingPage] = "Lighting"
getgenv().ToxPageNamesByPage[FlingPage] = "Extras"
getgenv().ToxPageNamesByPage[ScriptsPage] = "Scripts"
getgenv().ToxPageNamesByPage[JoinPage] = "Quick Join"
getgenv().ToxPageNamesByPage[ChatPage] = "Global Chat"
getgenv().ToxPageNamesByPage[ControlPage] = "Control Panel"
getgenv().ToxPageNamesByPage[SettingsPage] = "Settings"
if GamePage and DetectedGameModule then
    getgenv().ToxPageNamesByPage[GamePage] = DetectedGameModule.ShortName or "Game Features"
end

-- ToxOpenPage implementation
local function ToxOpenPage(targetPage)
    if not targetPage then return end

    for _, p in pairs(Pages) do
        p.Visible = false
    end

    targetPage.Visible = true
    CurrentActivePage = targetPage
    getgenv().CurrentPage = targetPage

    local pageTitle = getgenv().ToxPageNamesByPage[targetPage] or targetPage.Name
    CurrentTabTitle.Text = pageTitle

    for page, navData in pairs(SidebarNavButtons) do
        navData.SetActive(page == targetPage)
    end

    if getgenv().ToxChatGui and getgenv().ToxChatGui.Parent then
        getgenv().ToxChatGui.Visible = (targetPage == ChatPage)
    end

    if getgenv().ToxControlGui and getgenv().ToxControlGui.Parent then
        getgenv().ToxControlGui.Visible = (targetPage == ControlPage)
    end

    if getgenv().JoinGamesGui and getgenv().JoinGamesGui.Parent then
        getgenv().JoinGamesGui.Visible = (targetPage == JoinPage)
    end
end
getgenv().ToxOpenPage = ToxOpenPage


getgenv().ToxPageButtonsByPage = getgenv().ToxPageButtonsByPage or {}
getgenv().UniversalSubButtonsByPage = getgenv().UniversalSubButtonsByPage or {}
getgenv().LastUniversalSubPage = CombatPage
getgenv().CreateUniversalSubTabInternal = function(name, page)
    return CreateSidebarNavButton(name, "📌", page)
end
getgenv().ShowToxUpdateGui = function() end


-- ==============================================================================
-- SEARCH ENGINE, FLOATING MOBILE BUTTON, WATERMARK, WEATHER & COLOR PICKER
-- ==============================================================================

getgenv().ToxSearchControls = getgenv().ToxSearchControls or {}

local ToxSearchAliasMap = {
    tp = {"teleport", "ctrl click", "spawn", "map", "waypoint"},
    teleport = {"teleport", "ctrl click", "spawn", "map", "waypoint"},
    fps = {"fps booster", "performance", "restore"},
    perf = {"fps booster", "performance"},
    gun = {"gun esp", "grab gun", "shoot murderer"},
    arma = {"gun esp", "grab gun", "shoot murderer"},
    target = {"target", "murderer", "sheriff", "kill", "fling"},
    alvo = {"target", "murderer", "sheriff", "kill", "fling"},
    esp = {"esp", "chams", "tracers", "names", "distance", "box"},
    fly = {"fly", "air walk", "car fly"},
    noclip = {"noclip"},
    config = {"config", "keybind", "theme", "color", "wallpaper"},
    server = {"server hop", "rejoin", "players", "ping", "fps"}
}

getgenv().RegisterToxSearchControl = function(name, page, object, aliases)
    if typeof(name) ~= "string" or not page or not object then return end
    table.insert(getgenv().ToxSearchControls, {
        Name = name,
        Page = page,
        Object = object,
        Aliases = aliases or {}
    })
end

local function HighlightSearchResult(object)
    if not object or not object:IsA("GuiObject") then return end
    local oldColor = object.BackgroundColor3
    local oldStroke = object:FindFirstChildOfClass("UIStroke")
    local oldStrokeColor = oldStroke and oldStroke.Color

    object.BackgroundColor3 = Theme.Accent
    if oldStroke then oldStroke.Color = Color3.fromRGB(255, 255, 255) end

    task.delay(0.75, function()
        if object and object.Parent then
            object.BackgroundColor3 = oldColor
            if oldStroke and oldStroke.Parent then
                oldStroke.Color = oldStrokeColor or Theme.Outline
            end
        end
    end)
end

local function RebuildSearchResults()
    for _, child in ipairs(SearchResultsScroll:GetChildren()) do
        if child:IsA("GuiObject") then child:Destroy() end
    end

    local query = string.lower(tostring(SearchTextBox.Text or ""):gsub("^%s+", ""):gsub("%s+$", ""))
    if query == "" then
        SearchResultsScroll.Visible = false
        return
    end

    SearchResultsScroll.Visible = true
    local shown = 0

    for _, item in ipairs(getgenv().ToxSearchControls) do
        if item.Object and item.Object.Parent then
            local pageName = string.lower(getgenv().ToxPageNamesByPage[item.Page] or tostring(item.Page.Name or ""))
            local haystack = string.lower(tostring(item.Name or "") .. " " .. pageName)

            for _, alias in ipairs(item.Aliases) do
                haystack = haystack .. " " .. string.lower(tostring(alias))
            end

            local match = string.find(haystack, query, 1, true) ~= nil
            if not match and ToxSearchAliasMap[query] then
                for _, term in ipairs(ToxSearchAliasMap[query]) do
                    if string.find(haystack, term, 1, true) then match = true break end
                end
            end

            if match then
                shown = shown + 1
                if shown > 20 then break end

                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1, -4, 0, 28)
                btn.BackgroundColor3 = Theme.Element
                btn.BorderSizePixel = 0
                btn.Text = (getgenv().ToxPageNamesByPage[item.Page] or item.Page.Name) .. " • " .. item.Name
                btn.TextColor3 = Theme.Text
                btn.Font = Enum.Font.GothamMedium
                btn.TextSize = 10
                btn.TextXAlignment = Enum.TextXAlignment.Left
                btn.ZIndex = 51
                btn.Parent = SearchResultsScroll

                local bPadding = Instance.new("UIPadding") bPadding.PaddingLeft = UDim.new(0, 8) bPadding.Parent = btn
                local bCorner = Instance.new("UICorner") bCorner.CornerRadius = UDim.new(0, 4) bCorner.Parent = btn

                btn.MouseButton1Click:Connect(function()
                    SearchResultsScroll.Visible = false
                    getgenv().ToxOpenPage(item.Page)

                    task.defer(function()
                        if item.Page and item.Object and item.Object.Parent then
                            -- Expand parent card if collapsed
                            local parentCard = item.Object
                            while parentCard and parentCard.Parent ~= item.Page and parentCard.Parent ~= PagesContainer do
                                parentCard = parentCard.Parent
                            end
                            if parentCard and parentCard:FindFirstChild("Content") then
                                parentCard.Content.Visible = true
                                local colBtn = parentCard:FindFirstChild("Header") and parentCard.Header:FindFirstChild("CollapseBtn")
                                if colBtn then colBtn.Text = "v" end
                            end

                            local offset = item.Object.AbsolutePosition.Y - item.Page.AbsolutePosition.Y + item.Page.CanvasPosition.Y - 14
                            item.Page.CanvasPosition = Vector2.new(0, math.max(0, offset))
                            HighlightSearchResult(item.Object)
                        end
                    end)
                end)
            end
        end
    end

    if shown == 0 then
        local empty = Instance.new("TextLabel")
        empty.Size = UDim2.new(1, -4, 0, 28)
        empty.BackgroundTransparency = 1
        empty.Text = "No features found"
        empty.TextColor3 = Theme.DimText
        empty.Font = Enum.Font.Gotham
        empty.TextSize = 10
        empty.ZIndex = 51
        empty.Parent = SearchResultsScroll
    end
end

SearchTextBox:GetPropertyChangedSignal("Text"):Connect(RebuildSearchResults)
SearchTextBox.FocusLost:Connect(function()
    task.delay(0.2, function()
        if SearchTextBox and SearchTextBox.Text == "" and SearchResultsScroll then
            SearchResultsScroll.Visible = false
        end
    end)
end)

getgenv().OpenToxSearch = function()
    if SearchTextBox then
        SearchTextBox:CaptureFocus()
        RebuildSearchResults()
    end
end

-- ==============================================================================
-- FLOATING MOBILE TOGGLE BUTTON
-- ==============================================================================

local MobileToggleBtn = Instance.new("ImageButton")
MobileToggleBtn.Name = "ToxMobileToggle"
MobileToggleBtn.Size = UDim2.new(0, 46, 0, 46)
MobileToggleBtn.Position = UDim2.new(1, -60, 0.5, -23)
MobileToggleBtn.BackgroundColor3 = Theme.Panel
MobileToggleBtn.BorderSizePixel = 0
MobileToggleBtn.Image = LOGO_ID
MobileToggleBtn.Visible = Settings.MobileToggle ~= false
MobileToggleBtn.ZIndex = 999999
MobileToggleBtn.Parent = Gui

local MobileCorner = Instance.new("UICorner") MobileCorner.CornerRadius = UDim.new(1, 0) MobileCorner.Parent = MobileToggleBtn
local MobileStroke = Instance.new("UIStroke") MobileStroke.Color = Theme.Accent MobileStroke.Thickness = 2 MobileStroke.Parent = MobileToggleBtn
RegisterThemedObject(MobileToggleBtn, "BackgroundColor3", "Panel")
RegisterThemedObject(MobileStroke, "Color", "Accent")

MakeDraggable(MobileToggleBtn, MobileToggleBtn)

MobileToggleBtn.MouseButton1Click:Connect(function()
    if getgenv().ToggleToxGui then
        getgenv().ToggleToxGui()
    else
        Main.Visible = not Main.Visible
        if DimmerFrame then
            DimmerFrame.Visible = (Settings.DimBackground == true and Main.Visible)
        end
    end
end)

-- ==============================================================================
-- WATERMARK HUD
-- ==============================================================================

WatermarkFrame = Instance.new("Frame")
WatermarkFrame.Name = "ToxWatermark"
WatermarkFrame.Size = UDim2.new(0, 240, 0, 26)
WatermarkFrame.Position = UDim2.new(0, 20, 0, 16)
WatermarkFrame.BackgroundColor3 = Theme.Panel
WatermarkFrame.BorderSizePixel = 0
WatermarkFrame.Visible = Settings.Watermark == true
WatermarkFrame.ZIndex = 999990
WatermarkFrame.Parent = Gui

local WCorner = Instance.new("UICorner") WCorner.CornerRadius = UDim.new(0, 6) WCorner.Parent = WatermarkFrame
local WStroke = Instance.new("UIStroke") WStroke.Color = Theme.Outline WStroke.Thickness = 1 WStroke.Parent = WatermarkFrame
RegisterThemedObject(WatermarkFrame, "BackgroundColor3", "Panel")
RegisterThemedObject(WStroke, "Color", "Outline")

WatermarkLabel = Instance.new("TextLabel")
WatermarkLabel.Size = UDim2.new(1, -12, 1, 0)
WatermarkLabel.Position = UDim2.new(0, 8, 0, 0)
WatermarkLabel.BackgroundTransparency = 1
WatermarkLabel.RichText = true
WatermarkLabel.Text = "<b>ToxHub</b> v2.0  |  FPS: 60  |  Ping: 50ms"
WatermarkLabel.TextColor3 = Theme.Text
WatermarkLabel.Font = Enum.Font.GothamMedium
WatermarkLabel.TextSize = 10
WatermarkLabel.TextXAlignment = Enum.TextXAlignment.Left
WatermarkLabel.Parent = WatermarkFrame
RegisterThemedObject(WatermarkLabel, "TextColor3", "Text")

MakeDraggable(WatermarkFrame, WatermarkFrame)

-- ==============================================================================
-- WEATHER PARTICLE SYSTEM
-- ==============================================================================

local ActiveWeatherParticles = {}
local WeatherSpawnConnection = nil

local function ClearWeather()
    if WeatherSpawnConnection then
        WeatherSpawnConnection:Disconnect()
        WeatherSpawnConnection = nil
    end
    for _, p in ipairs(ActiveWeatherParticles) do
        if p and p.Parent then p:Destroy() end
    end
    ActiveWeatherParticles = {}
end

local function StartWeatherEngine()
    ClearWeather()
    local weatherStyle = tostring(Settings.Weather or "Off")
    if weatherStyle == "Off" then return end

    local targetParent = (Settings.WeatherArea == "Screen") and ScreenWeatherGui or WeatherContainer
    local amount = math.clamp(tonumber(Settings.WeatherAmount) or 100, 10, 100)
    local sizeScale = math.clamp((tonumber(Settings.WeatherSize) or 100) / 100, 0.3, 3)

    local spawnInterval = 0.35 / (amount / 40)
    local lastSpawn = 0

    WeatherSpawnConnection = RunService.RenderStepped:Connect(function(dt)
        lastSpawn = lastSpawn + dt
        if lastSpawn < spawnInterval then return end
        lastSpawn = 0

        local parentSize = targetParent.AbsoluteSize
        if parentSize.X < 50 or parentSize.Y < 50 then return end

        local particle = Instance.new("TextLabel")
        particle.BackgroundTransparency = 1
        particle.ZIndex = 5

        if weatherStyle == "Snow" then
            particle.Text = "❄"
            particle.TextColor3 = Color3.fromRGB(220, 240, 255)
            particle.TextSize = math.random(10, 18) * sizeScale
            particle.Size = UDim2.new(0, 20, 0, 20)
            particle.Position = UDim2.new(math.random(), 0, -0.05, 0)
            particle.Parent = targetParent

            task.spawn(function()
                local xSpeed = (math.random() - 0.5) * 35
                local ySpeed = math.random(40, 90)
                local curY = -0.05
                local curX = particle.Position.X.Scale
                while particle and particle.Parent and curY < 1.05 do
                    local step = task.wait(0.03)
                    curY = curY + (ySpeed / parentSize.Y) * step * 10
                    curX = curX + (xSpeed / parentSize.X) * step * 10
                    particle.Position = UDim2.new(curX, 0, curY, 0)
                end
                if particle and particle.Parent then particle:Destroy() end
            end)
        elseif weatherStyle == "Rain" then
            particle.Text = "/"
            particle.TextColor3 = Color3.fromRGB(160, 200, 255)
            particle.TextSize = math.random(14, 22) * sizeScale
            particle.Size = UDim2.new(0, 15, 0, 25)
            particle.Position = UDim2.new(math.random(), 0, -0.05, 0)
            particle.Parent = targetParent

            task.spawn(function()
                local curY = -0.05
                local curX = particle.Position.X.Scale
                while particle and particle.Parent and curY < 1.05 do
                    local step = task.wait(0.02)
                    curY = curY + (280 / parentSize.Y) * step * 10
                    curX = curX + (-80 / parentSize.X) * step * 10
                    particle.Position = UDim2.new(curX, 0, curY, 0)
                end
                if particle and particle.Parent then particle:Destroy() end
            end)
        elseif weatherStyle == "Stars" then
            particle.Text = "✦"
            particle.TextColor3 = Theme.Accent2
            particle.TextSize = math.random(8, 16) * sizeScale
            particle.Size = UDim2.new(0, 16, 0, 16)
            particle.Position = UDim2.new(math.random(), 0, 1.05, 0)
            particle.Parent = targetParent

            task.spawn(function()
                local curY = 1.05
                while particle and particle.Parent and curY > -0.05 do
                    local step = task.wait(0.03)
                    curY = curY - (40 / parentSize.Y) * step * 10
                    particle.Position = UDim2.new(particle.Position.X.Scale, 0, curY, 0)
                end
                if particle and particle.Parent then particle:Destroy() end
            end)
        end

        table.insert(ActiveWeatherParticles, particle)
        if #ActiveWeatherParticles > 60 then
            local old = table.remove(ActiveWeatherParticles, 1)
            if old and old.Parent then old:Destroy() end
        end
    end)
end

StartWeatherEngine()

-- ==============================================================================
do -- COLOR PICKER MODAL
-- INTERACTIVE COLOR PICKER MODAL
-- ==============================================================================

local ColorPickerModal = Instance.new("Frame")
ColorPickerModal.Name = "ToxColorPickerModal"
ColorPickerModal.Size = UDim2.new(0, 310, 0, 360)
ColorPickerModal.Position = UDim2.new(0.5, -155, 0.5, -180)
ColorPickerModal.BackgroundColor3 = Theme.Panel
ColorPickerModal.BorderSizePixel = 0
ColorPickerModal.Visible = false
ColorPickerModal.ZIndex = 2000
ColorPickerModal.Parent = Gui
RegisterThemedObject(ColorPickerModal, "BackgroundColor3", "Panel")

local CPModalCorner = Instance.new("UICorner") CPModalCorner.CornerRadius = UDim.new(0, 10) CPModalCorner.Parent = ColorPickerModal
local CPModalStroke = Instance.new("UIStroke") CPModalStroke.Color = Theme.Outline CPModalStroke.Thickness = 2 CPModalStroke.Parent = ColorPickerModal
RegisterThemedObject(CPModalStroke, "Color", "Outline")

MakeDraggable(ColorPickerModal, ColorPickerModal)

local CPTitle = Instance.new("TextLabel")
CPTitle.Size = UDim2.new(1, -50, 0, 36)
CPTitle.Position = UDim2.new(0, 14, 0, 0)
CPTitle.BackgroundTransparency = 1
CPTitle.Text = "Color Picker"
CPTitle.TextColor3 = Theme.Text
CPTitle.Font = Enum.Font.GothamBold
CPTitle.TextSize = 14
CPTitle.TextXAlignment = Enum.TextXAlignment.Left
CPTitle.ZIndex = 2001
CPTitle.Parent = ColorPickerModal
RegisterThemedObject(CPTitle, "TextColor3", "Text")

local CPClose = Instance.new("TextButton")
CPClose.Size = UDim2.new(0, 26, 0, 26)
CPClose.Position = UDim2.new(1, -34, 0, 6)
CPClose.BackgroundColor3 = Theme.Element
CPClose.BorderSizePixel = 0
CPClose.Text = "✕"
CPClose.TextColor3 = Theme.DimText
CPClose.Font = Enum.Font.GothamBold
CPClose.TextSize = 12
CPClose.ZIndex = 2001
CPClose.Parent = ColorPickerModal
local CPCloseCorner = Instance.new("UICorner") CPCloseCorner.CornerRadius = UDim.new(0, 5) CPCloseCorner.Parent = CPClose

CPClose.MouseButton1Click:Connect(function()
    ColorPickerModal.Visible = false
end)

-- Preview Box
local CPPreview = Instance.new("Frame")
CPPreview.Size = UDim2.new(1, -28, 0, 42)
CPPreview.Position = UDim2.new(0, 14, 0, 42)
CPPreview.BackgroundColor3 = Theme.Accent
CPPreview.BorderSizePixel = 0
CPPreview.ZIndex = 2001
CPPreview.Parent = ColorPickerModal
local CPPreviewCorner = Instance.new("UICorner") CPPreviewCorner.CornerRadius = UDim.new(0, 6) CPPreviewCorner.Parent = CPPreview

local function CreateCPSlider(name, yPos, maxVal, defaultVal)
    maxVal = tonumber(maxVal) or 255
    defaultVal = tonumber(defaultVal) or 0
    if maxVal <= 0 then maxVal = 255 end
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -28, 0, 40)
    container.Position = UDim2.new(0, 14, 0, yPos)
    container.BackgroundTransparency = 1
    container.ZIndex = 2001
    container.Parent = ColorPickerModal

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 40, 0, 18)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Theme.Text
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 2002
    label.Parent = container

    local valLabel = Instance.new("TextLabel")
    valLabel.Size = UDim2.new(0, 40, 0, 18)
    valLabel.Position = UDim2.new(1, -40, 0, 0)
    valLabel.BackgroundTransparency = 1
    valLabel.Text = tostring(math.floor(defaultVal))
    valLabel.TextColor3 = Theme.DimText
    valLabel.Font = Enum.Font.GothamBold
    valLabel.TextSize = 11
    valLabel.TextXAlignment = Enum.TextXAlignment.Right
    valLabel.ZIndex = 2002
    valLabel.Parent = container

    local bar = Instance.new("TextButton")
    bar.Size = UDim2.new(1, 0, 0, 12)
    bar.Position = UDim2.new(0, 0, 0, 22)
    bar.BackgroundColor3 = Theme.Element
    bar.BorderSizePixel = 0
    bar.Text = ""
    bar.AutoButtonColor = false
    bar.ZIndex = 2002
    bar.Parent = container
    local barCorner = Instance.new("UICorner") barCorner.CornerRadius = UDim.new(0, 4) barCorner.Parent = bar

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(defaultVal / maxVal, 0, 1, 0)
    fill.BackgroundColor3 = Theme.Accent
    fill.BorderSizePixel = 0
    fill.ZIndex = 2003
    fill.Parent = bar
    local fillCorner = Instance.new("UICorner") fillCorner.CornerRadius = UDim.new(0, 4) fillCorner.Parent = fill
    RegisterThemedObject(fill, "BackgroundColor3", "Accent")

    local curVal = defaultVal
    local isDragging = false

    local function Update(inputX)
        local rel = math.clamp((inputX - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        curVal = math.floor(rel * maxVal)
        valLabel.Text = tostring(curVal)
        fill.Size = UDim2.new(rel, 0, 1, 0)
    end

    bar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            Update(inp.Position.X)
            local moveConn, endConn
            moveConn = UserInputService.InputChanged:Connect(function(change)
                if change.UserInputType == Enum.UserInputType.MouseMovement or change.UserInputType == Enum.UserInputType.Touch then
                    Update(change.Position.X)
                end
            end)
            endConn = UserInputService.InputEnded:Connect(function(ended)
                if ended.UserInputType == Enum.UserInputType.MouseButton1 or ended.UserInputType == Enum.UserInputType.Touch then
                    isDragging = false
                    if moveConn then moveConn:Disconnect() end
                    if endConn then endConn:Disconnect() end
                end
            end)
        end
    end)

    return {
        GetValue = function() return curVal end,
        SetValue = function(v)
            curVal = math.clamp(math.floor(v), 0, maxVal)
            valLabel.Text = tostring(curVal)
            fill.Size = UDim2.new(curVal / maxVal, 0, 1, 0)
        end,
        OnChanged = function(cb)
            bar:GetPropertyChangedSignal("AbsolutePosition"):Connect(function() end)
        end
    }
end

local RSlider = CreateCPSlider("Red", 96, 255, 30)
local GSlider = CreateCPSlider("Green", 144, 255, 95)
local BSlider = CreateCPSlider("Blue", 192, 255, 255)

local PresetsContainer = Instance.new("Frame")
PresetsContainer.Size = UDim2.new(1, -28, 0, 30)
PresetsContainer.Position = UDim2.new(0, 14, 0, 246)
PresetsContainer.BackgroundTransparency = 1
PresetsContainer.ZIndex = 2001
PresetsContainer.Parent = ColorPickerModal

local PresetsLayout = Instance.new("UIListLayout")
PresetsLayout.FillDirection = Enum.FillDirection.Horizontal
PresetsLayout.Padding = UDim.new(0, 6)
PresetsLayout.Parent = PresetsContainer

local CPApplyBtn = Instance.new("TextButton")
CPApplyBtn.Size = UDim2.new(1, -28, 0, 34)
CPApplyBtn.Position = UDim2.new(0, 14, 0, 290)
CPApplyBtn.BackgroundColor3 = Theme.Accent
CPApplyBtn.BorderSizePixel = 0
CPApplyBtn.Text = "Apply Color"
CPApplyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CPApplyBtn.Font = Enum.Font.GothamBold
CPApplyBtn.TextSize = 12
CPApplyBtn.ZIndex = 2002
CPApplyBtn.Parent = ColorPickerModal
local CPApplyCorner = Instance.new("UICorner") CPApplyCorner.CornerRadius = UDim.new(0, 6) CPApplyCorner.Parent = CPApplyBtn
RegisterThemedObject(CPApplyBtn, "BackgroundColor3", "Accent")

local ActiveEditingColorKey = nil
local ActiveSwatchFrame = nil

OpenColorPicker = function(colorKey, swatchFrame)
    ActiveEditingColorKey = colorKey
    ActiveSwatchFrame = swatchFrame
    CPTitle.Text = "Color: " .. tostring(colorKey)

    local current = Theme[colorKey] or Color3.fromRGB(255, 255, 255)
    RSlider.SetValue(current.R * 255)
    GSlider.SetValue(current.G * 255)
    BSlider.SetValue(current.B * 255)
    CPPreview.BackgroundColor3 = current

    ColorPickerModal.Visible = true
end

local function UpdateModalPreview()
    local r = RSlider.GetValue() / 255
    local g = GSlider.GetValue() / 255
    local b = BSlider.GetValue() / 255
    CPPreview.BackgroundColor3 = Color3.new(r, g, b)
end

task.spawn(function()
    while not getgenv().Destroyed do
        if ColorPickerModal.Visible then
            UpdateModalPreview()
        end
        task.wait(0.08)
    end
end)

CPApplyBtn.MouseButton1Click:Connect(function()
    if ActiveEditingColorKey then
        local r = RSlider.GetValue() / 255
        local g = GSlider.GetValue() / 255
        local b = BSlider.GetValue() / 255
        local newCol = Color3.new(r, g, b)

        Theme[ActiveEditingColorKey] = newCol
        Settings.Theme = Theme
        if ActiveSwatchFrame then
            ActiveSwatchFrame.BackgroundColor3 = newCol
        end

        ApplyTheme()

        if getgenv().AutoSaveConfiguration then
            getgenv().AutoSaveConfiguration()
        end
    end
    ColorPickerModal.Visible = false
end)

local Presets = {
    Color3.fromRGB(30, 95, 255),
    Color3.fromRGB(145, 45, 255),
    Color3.fromRGB(25, 180, 100),
    Color3.fromRGB(255, 55, 65),
    Color3.fromRGB(255, 180, 20),
    Color3.fromRGB(0, 200, 230),
    Color3.fromRGB(255, 255, 255)
}

for _, pCol in ipairs(Presets) do
    local pBtn = Instance.new("TextButton")
    pBtn.Size = UDim2.new(0, 30, 0, 26)
    pBtn.BackgroundColor3 = pCol
    pBtn.BorderSizePixel = 0
    pBtn.Text = ""
    pBtn.ZIndex = 2002
    pBtn.Parent = PresetsContainer
    local pCorner = Instance.new("UICorner") pCorner.CornerRadius = UDim.new(0, 4) pCorner.Parent = pBtn

    pBtn.MouseButton1Click:Connect(function()
        RSlider.SetValue(pCol.R * 255)
        GSlider.SetValue(pCol.G * 255)
        BSlider.SetValue(pCol.B * 255)
        CPPreview.BackgroundColor3 = pCol
    end)
end

end



do -- HOME DASHBOARD, SETTINGS & TELEMETRY
-- ==============================================================================
-- HOME PAGE SETUP (BigFroot Style Dashboard)
-- ==============================================================================

local StartSessionTime = os.clock()

-- Card 1: Pinned (📌 Pinned)
local PinnedCard = CreateCard(HomePage, "Pinned", "📌", 1, "Home_Pinned")
local function AddPinnedCheckbox(name, defaultVal, isRisky, onToggled)
    local row = Instance.new("TextButton")
    row.Size = UDim2.new(1, 0, 0, 32)
    row.BackgroundColor3 = Theme.Element
    row.BorderSizePixel = 0
    row.Text = ""
    row.AutoButtonColor = false
    row.Parent = PinnedCard.Content
    local rCorner = Instance.new("UICorner") rCorner.CornerRadius = UDim.new(0, 5) rCorner.Parent = row
    RegisterThemedObject(row, "BackgroundColor3", "Element")

    local box = Instance.new("Frame")
    box.Size = UDim2.new(0, 18, 0, 18)
    box.Position = UDim2.new(0, 10, 0.5, -9)
    box.BackgroundColor3 = Theme.Panel
    box.BorderSizePixel = 0
    box.Parent = row
    local bCorner = Instance.new("UICorner") bCorner.CornerRadius = UDim.new(0, 4) bCorner.Parent = box
    local bStroke = Instance.new("UIStroke") bStroke.Color = Theme.Outline bStroke.Thickness = 1 bStroke.Parent = box
    RegisterThemedObject(box, "BackgroundColor3", "Panel")
    RegisterThemedObject(bStroke, "Color", "Outline")

    local check = Instance.new("TextLabel")
    check.Size = UDim2.new(1, 0, 1, 0)
    check.BackgroundTransparency = 1
    check.Text = defaultVal and "✓" or ""
    check.TextColor3 = Theme.Accent
    check.Font = Enum.Font.GothamBold
    check.TextSize = 13
    check.Parent = box
    RegisterThemedObject(check, "TextColor3", "Accent")

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -44, 1, 0)
    label.Position = UDim2.new(0, 38, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = isRisky and Theme.Risky or Theme.Text
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row
    if not isRisky then RegisterThemedObject(label, "TextColor3", "Text") else RegisterThemedObject(label, "TextColor3", "Risky") end

    local active = defaultVal == true
    local function SetState(val)
        active = val == true
        check.Text = active and "✓" or ""
    end

    row.MouseButton1Click:Connect(function()
        active = not active
        SetState(active)
        if onToggled then onToggled(active) end
        if getgenv().AutoSaveConfiguration then getgenv().AutoSaveConfiguration() end
    end)

    return SetState
end

-- Pinned items
AddPinnedCheckbox("Enable ESP", Settings.ESPEnabled, false, function(v)
    Settings.ESPEnabled = v
    if getgenv().SyncToggleVisuals then getgenv().SyncToggleVisuals("ESPEnabled", v) end
end)

AddPinnedCheckbox("Farm Coins", Settings.MM2AutoFarmV2, false, function(v)
    Settings.MM2AutoFarmV2 = v
    if getgenv().SyncToggleVisuals then getgenv().SyncToggleVisuals("MM2AutoFarmV2", v) end
end)

AddPinnedCheckbox("Kill Aura", Settings.KillAura, true, function(v)
    Settings.KillAura = v
    if getgenv().SyncToggleVisuals then getgenv().SyncToggleVisuals("KillAura", v) end
end)

AddPinnedCheckbox("Anti AFK", Settings.AntiAFK ~= false, false, function(v)
    Settings.AntiAFK = v
    if getgenv().SyncToggleVisuals then getgenv().SyncToggleVisuals("AntiAFK", v) end
end)

-- Card 2: Status (🕒 Status)
local StatusCard = CreateCard(HomePage, "Status", "🕒", 2, "Home_Status")
local StatusGrid = Instance.new("Frame")
StatusGrid.Size = UDim2.new(1, 0, 0, 96)
StatusGrid.BackgroundTransparency = 1
StatusGrid.Parent = StatusCard.Content

local StatUIGrid = Instance.new("UIGridLayout")
StatUIGrid.CellSize = UDim2.new(0.315, 0, 0, 44)
StatUIGrid.CellPadding = UDim2.new(0.027, 0, 0, 8)
StatUIGrid.Parent = StatusGrid

local function CreateStatusPill(initialVal, subText)
    local pill = Instance.new("Frame")
    pill.BackgroundColor3 = Theme.Element
    pill.BorderSizePixel = 0
    pill.Parent = StatusGrid
    local pCorner = Instance.new("UICorner") pCorner.CornerRadius = UDim.new(0, 6) pCorner.Parent = pill
    RegisterThemedObject(pill, "BackgroundColor3", "Element")

    local val = Instance.new("TextLabel")
    val.Size = UDim2.new(1, -6, 0, 22)
    val.Position = UDim2.new(0, 6, 0, 4)
    val.BackgroundTransparency = 1
    val.Text = initialVal
    val.TextColor3 = Theme.Text
    val.Font = Enum.Font.GothamBold
    val.TextSize = 13
    val.TextXAlignment = Enum.TextXAlignment.Left
    val.Parent = pill
    RegisterThemedObject(val, "TextColor3", "Text")

    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1, -6, 0, 16)
    sub.Position = UDim2.new(0, 6, 0, 24)
    sub.BackgroundTransparency = 1
    sub.Text = subText
    sub.TextColor3 = Theme.DimText
    sub.Font = Enum.Font.Gotham
    sub.TextSize = 10
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.Parent = pill
    RegisterThemedObject(sub, "TextColor3", "DimText")

    return function(newVal) val.Text = tostring(newVal) end
end

local UpdateSessionPill = CreateStatusPill("0m 0s", "session")
local UpdateFeaturesPill = CreateStatusPill("0", "features on")
local UpdateFPSPill = CreateStatusPill("60", "fps")
local UpdatePingPill = CreateStatusPill("50 ms", "ping")
local UpdatePlayersPill = CreateStatusPill(tostring(#Players:GetPlayers()) .. " / " .. tostring(Players.MaxPlayers), "players")
local UpdateKeyPill = CreateStatusPill("lifetime", "key time")

-- Card 3: Announcements (📢 Announcements)
local AnnounceCard = CreateCard(HomePage, "Announcements", "📢", 3, "Home_Announcements")
local AnnounceBox = Instance.new("Frame")
AnnounceBox.Size = UDim2.new(1, 0, 0, 0)
AnnounceBox.AutomaticSize = Enum.AutomaticSize.Y
AnnounceBox.BackgroundColor3 = Theme.Element
AnnounceBox.BorderSizePixel = 0
AnnounceBox.Parent = AnnounceCard.Content
local abCorner = Instance.new("UICorner") abCorner.CornerRadius = UDim.new(0, 6) abCorner.Parent = AnnounceBox
RegisterThemedObject(AnnounceBox, "BackgroundColor3", "Element")

local abPadding = Instance.new("UIPadding")
abPadding.PaddingTop = UDim.new(0, 8)
abPadding.PaddingBottom = UDim.new(0, 8)
abPadding.PaddingLeft = UDim.new(0, 10)
abPadding.PaddingRight = UDim.new(0, 10)
abPadding.Parent = AnnounceBox

local abLayout = Instance.new("UIListLayout")
abLayout.Padding = UDim.new(0, 4)
abLayout.Parent = AnnounceBox

local function AddAnnounceLine(text, isBold, color)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 0, isBold and 18 or 15)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = color or (isBold and Theme.Text or Theme.DimText)
    l.Font = isBold and Enum.Font.GothamBold or Enum.Font.Gotham
    l.TextSize = isBold and 12 or 11
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = AnnounceBox
    if not color then
        RegisterThemedObject(l, "TextColor3", isBold and "Text" or "DimText")
    end
end

AddAnnounceLine("v2.0 Revolution", true)
AddAnnounceLine("2026-10-31", false)
AddAnnounceLine("+ Revolutionary BigFroot/Wasor Card Layout", false)
AddAnnounceLine("+ Reorderable & Draggable Cards (+ handle)", false)
AddAnnounceLine("+ Live Status & Telemetry Dashboard", false)
AddAnnounceLine("+ Full Custom Color Theme Engine", false)
AddAnnounceLine("+ Particle Weather Effects & Custom Wallpaper", false)
AddAnnounceLine("+ Floating Mobile Button & Background Dimmer", false)
AddAnnounceLine("+ Preserved All ToxHub Scripts & Features 100%", false)

-- Card 4: Stats (📊 Stats)
local StatsCard = CreateCard(HomePage, "Stats", "📊", 4, "Home_Stats")
local StatsGrid = Instance.new("Frame")
StatsGrid.Size = UDim2.new(1, 0, 0, 88)
StatsGrid.BackgroundTransparency = 1
StatsGrid.Parent = StatsCard.Content

local StatGridLayout = Instance.new("UIGridLayout")
StatGridLayout.CellSize = UDim2.new(0.485, 0, 0, 40)
StatGridLayout.CellPadding = UDim2.new(0.03, 0, 0, 8)
StatGridLayout.Parent = StatsGrid

local function CreateStatCard(title, defaultVal)
    local f = Instance.new("Frame")
    f.BackgroundColor3 = Theme.Element
    f.BorderSizePixel = 0
    f.Parent = StatsGrid
    local fc = Instance.new("UICorner") fc.CornerRadius = UDim.new(0, 5) fc.Parent = f
    RegisterThemedObject(f, "BackgroundColor3", "Element")

    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1, -6, 0, 16)
    t.Position = UDim2.new(0, 6, 0, 4)
    t.BackgroundTransparency = 1
    t.Text = title
    t.TextColor3 = Theme.DimText
    t.Font = Enum.Font.Gotham
    t.TextSize = 10
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.Parent = f
    RegisterThemedObject(t, "TextColor3", "DimText")

    local v = Instance.new("TextLabel")
    v.Size = UDim2.new(1, -6, 0, 18)
    v.Position = UDim2.new(0, 6, 0, 18)
    v.BackgroundTransparency = 1
    v.Text = defaultVal
    v.TextColor3 = Theme.Text
    v.Font = Enum.Font.GothamBold
    v.TextSize = 11
    v.TextXAlignment = Enum.TextXAlignment.Left
    v.TextTruncate = Enum.TextTruncate.AtEnd
    v.Parent = f
    RegisterThemedObject(v, "TextColor3", "Text")

    return function(newVal) v.Text = tostring(newVal) end
end

local UpdateMurdererStat = CreateStatCard("Murderer", "None")
local UpdateSheriffStat = CreateStatCard("Sheriff", "None")
local UpdatePlayersStat = CreateStatCard("Players Alive", tostring(#Players:GetPlayers()))
local UpdateMapStat = CreateStatCard("Map / Server", tostring(game.PlaceId))

-- Card 5: Quick actions (⚡ Quick actions)
local QuickCard = CreateCard(HomePage, "Quick actions", "⚡", 5, "Home_QuickActions")
local QuickGrid = Instance.new("Frame")
QuickGrid.Size = UDim2.new(1, 0, 0, 72)
QuickGrid.BackgroundTransparency = 1
QuickGrid.Parent = QuickCard.Content

local QuickGridLayout = Instance.new("UIGridLayout")
QuickGridLayout.CellSize = UDim2.new(0.485, 0, 0, 32)
QuickGridLayout.CellPadding = UDim2.new(0.03, 0, 0, 8)
QuickGridLayout.Parent = QuickGrid

local function CreateQuickActionBtn(text, onClick)
    local btn = Instance.new("TextButton")
    btn.BackgroundColor3 = Theme.Element
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = Theme.Text
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 11
    btn.Parent = QuickGrid
    local bc = Instance.new("UICorner") bc.CornerRadius = UDim.new(0, 5) bc.Parent = btn
    RegisterThemedObject(btn, "BackgroundColor3", "Element")
    RegisterThemedObject(btn, "TextColor3", "Text")

    btn.MouseButton1Click:Connect(function()
        if getgenv().Destroyed then return end
        if onClick then onClick() end
    end)
    return btn
end

CreateQuickActionBtn("Copy Discord", function()
    pcall(function() setclipboard("https://discord.gg/toxhub") end)
    CustomNotify("Discord link copied to clipboard!", Theme.Accent, 3)
end)

CreateQuickActionBtn("Load last config", function()
    if LoadConfiguration then
        LoadConfiguration()
        CustomNotify("Configuration reloaded successfully!", Theme.Accent, 3)
    end
end)

CreateQuickActionBtn("Rejoin", function()
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Player)
end)

CreateQuickActionBtn("Server hop", function()
    CustomNotify("Finding server...", Theme.Accent, 2)
    task.spawn(function()
        local success, result = pcall(function()
            local url = "https://games.roblox.com/v1/games/" .. tostring(game.PlaceId) .. "/servers/Public?sortOrder=Asc&limit=100"
            return HttpService:JSONDecode(game:HttpGet(url))
        end)
        if success and result and result.data then
            for _, s in ipairs(result.data) do
                if s.playing and s.playing < s.maxPlayers and s.id ~= game.JobId then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, Player)
                    return
                end
            end
        end
        CustomNotify("No alternate server found", Color3.fromRGB(255, 100, 100), 3)
    end)
end)

CreateQuickActionBtn("Toggle watermark", function()
    Settings.Watermark = not Settings.Watermark
    WatermarkFrame.Visible = Settings.Watermark == true
    if getgenv().AutoSaveConfiguration then getgenv().AutoSaveConfiguration() end
end)

-- Card 6: Account (🔑 Account)
local AccountCard = CreateCard(HomePage, "Account", "🔑", 6, "Home_Account")
local AccRow = Instance.new("Frame")
AccRow.Size = UDim2.new(1, 0, 0, 34)
AccRow.BackgroundColor3 = Theme.Element
AccRow.BorderSizePixel = 0
AccRow.Parent = AccountCard.Content
local acCorner = Instance.new("UICorner") acCorner.CornerRadius = UDim.new(0, 5) acCorner.Parent = AccRow
RegisterThemedObject(AccRow, "BackgroundColor3", "Element")

local KeyStatusTitle = Instance.new("TextLabel")
KeyStatusTitle.Size = UDim2.new(0.5, -10, 1, 0)
KeyStatusTitle.Position = UDim2.new(0, 10, 0, 0)
KeyStatusTitle.BackgroundTransparency = 1
KeyStatusTitle.Text = "Key status"
KeyStatusTitle.TextColor3 = Theme.Text
KeyStatusTitle.Font = Enum.Font.GothamMedium
KeyStatusTitle.TextSize = 12
KeyStatusTitle.TextXAlignment = Enum.TextXAlignment.Left
KeyStatusTitle.Parent = AccRow
RegisterThemedObject(KeyStatusTitle, "TextColor3", "Text")

local KeyStatusVal = Instance.new("TextLabel")
KeyStatusVal.Size = UDim2.new(0.5, -10, 1, 0)
KeyStatusVal.Position = UDim2.new(0.5, 0, 0, 0)
KeyStatusVal.BackgroundTransparency = 1
KeyStatusVal.Text = "Premium"
KeyStatusVal.TextColor3 = Theme.Accent
KeyStatusVal.Font = Enum.Font.GothamBold
KeyStatusVal.TextSize = 12
KeyStatusVal.TextXAlignment = Enum.TextXAlignment.Right
KeyStatusVal.Parent = AccRow
RegisterThemedObject(KeyStatusVal, "TextColor3", "Accent")

local ReplaceKeyBtn = Instance.new("TextButton")
ReplaceKeyBtn.Size = UDim2.new(1, 0, 0, 32)
ReplaceKeyBtn.BackgroundColor3 = Theme.Element
ReplaceKeyBtn.BorderSizePixel = 0
ReplaceKeyBtn.Text = "Replace key"
ReplaceKeyBtn.TextColor3 = Theme.Text
ReplaceKeyBtn.Font = Enum.Font.GothamMedium
ReplaceKeyBtn.TextSize = 11
ReplaceKeyBtn.Parent = AccountCard.Content
local rkCorner = Instance.new("UICorner") rkCorner.CornerRadius = UDim.new(0, 5) rkCorner.Parent = ReplaceKeyBtn
RegisterThemedObject(ReplaceKeyBtn, "BackgroundColor3", "Element")
RegisterThemedObject(ReplaceKeyBtn, "TextColor3", "Text")

ReplaceKeyBtn.MouseButton1Click:Connect(function()
    CustomNotify("Key verified (Lifetime License)", Theme.Accent, 3)
end)

-- ==============================================================================
-- SETTINGS PAGE SETUP (Screenshot 2 Match)
-- ==============================================================================

-- Card 1: Menu
local MenuCard = CreateCard(SettingsPage, "Menu", "☰", 1, "Settings_Menu")

-- Keybind toggle button row
local KeybindRow = Instance.new("Frame")
KeybindRow.Size = UDim2.new(1, 0, 0, 36)
KeybindRow.BackgroundColor3 = Theme.Element
KeybindRow.BorderSizePixel = 0
KeybindRow.Parent = MenuCard.Content
local krCorner = Instance.new("UICorner") krCorner.CornerRadius = UDim.new(0, 5) krCorner.Parent = KeybindRow
RegisterThemedObject(KeybindRow, "BackgroundColor3", "Element")

local KeybindLabel = Instance.new("TextLabel")
KeybindLabel.Size = UDim2.new(1, -90, 1, 0)
KeybindLabel.Position = UDim2.new(0, 10, 0, 0)
KeybindLabel.BackgroundTransparency = 1
KeybindLabel.Text = "Toggle menu"
KeybindLabel.TextColor3 = Theme.Text
KeybindLabel.Font = Enum.Font.GothamMedium
KeybindLabel.TextSize = 12
KeybindLabel.TextXAlignment = Enum.TextXAlignment.Left
KeybindLabel.Parent = KeybindRow
RegisterThemedObject(KeybindLabel, "TextColor3", "Text")

local KeybindButton = Instance.new("TextButton")
KeybindButton.Size = UDim2.new(0, 75, 0, 24)
KeybindButton.Position = UDim2.new(1, -85, 0.5, -12)
KeybindButton.BackgroundColor3 = Theme.Panel
KeybindButton.BorderSizePixel = 0
KeybindButton.Text = (typeof(Settings.GUIKeybind) == "EnumItem" and Settings.GUIKeybind.Name) or tostring(Settings.GUIKeybind or "LeftAlt")
KeybindButton.TextColor3 = Theme.Accent
KeybindButton.Font = Enum.Font.GothamBold
KeybindButton.TextSize = 11
KeybindButton.Parent = KeybindRow
local kbCorner = Instance.new("UICorner") kbCorner.CornerRadius = UDim.new(0, 4) kbCorner.Parent = KeybindButton
local kbStroke = Instance.new("UIStroke") kbStroke.Color = Theme.Outline kbStroke.Thickness = 1 kbStroke.Parent = KeybindButton
RegisterThemedObject(KeybindButton, "BackgroundColor3", "Panel")
RegisterThemedObject(KeybindButton, "TextColor3", "Accent")
RegisterThemedObject(kbStroke, "Color", "Outline")

local isBindingKey = false
KeybindButton.MouseButton1Click:Connect(function()
    if isBindingKey then return end
    isBindingKey = true
    KeybindButton.Text = "..."
    local conn
    conn = UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard then
            conn:Disconnect()
            isBindingKey = false
            if input.KeyCode == Enum.KeyCode.Escape then
                Settings.GUIKeybind = Enum.KeyCode.LeftAlt
            else
                Settings.GUIKeybind = input.KeyCode
            end
            KeybindButton.Text = (typeof(Settings.GUIKeybind) == 'EnumItem' and Settings.GUIKeybind.Name) or tostring(Settings.GUIKeybind or 'LeftAlt')
            if getgenv().AutoSaveConfiguration then getgenv().AutoSaveConfiguration() end
        end
    end)
end)

-- Helpers for Settings rows
local function AddSettingsToggle(parent, name, defaultVal, callback)
    local row = Instance.new("TextButton")
    row.Size = UDim2.new(1, 0, 0, 34)
    row.BackgroundColor3 = Theme.Element
    row.BorderSizePixel = 0
    row.Text = ""
    row.AutoButtonColor = false
    row.Parent = parent
    local rCorner = Instance.new("UICorner") rCorner.CornerRadius = UDim.new(0, 5) rCorner.Parent = row
    RegisterThemedObject(row, "BackgroundColor3", "Element")

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -60, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Theme.Text
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row
    RegisterThemedObject(label, "TextColor3", "Text")

    local toggleBg = Instance.new("Frame")
    toggleBg.Size = UDim2.new(0, 36, 0, 18)
    toggleBg.Position = UDim2.new(1, -46, 0.5, -9)
    toggleBg.BackgroundColor3 = defaultVal and Theme.Accent or Theme.Panel
    toggleBg.BorderSizePixel = 0
    toggleBg.Parent = row
    local tCorner = Instance.new("UICorner") tCorner.CornerRadius = UDim.new(1, 0) tCorner.Parent = toggleBg
    local tStroke = Instance.new("UIStroke") tStroke.Color = Theme.Outline tStroke.Thickness = 1 tStroke.Parent = toggleBg
    RegisterThemedObject(tStroke, "Color", "Outline")

    local ball = Instance.new("Frame")
    ball.Size = UDim2.new(0, 14, 0, 14)
    ball.Position = defaultVal and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
    ball.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ball.BorderSizePixel = 0
    ball.Parent = toggleBg
    local bCorner = Instance.new("UICorner") bCorner.CornerRadius = UDim.new(1, 0) bCorner.Parent = ball

    local enabled = defaultVal == true
    local function UpdateVisual(val)
        enabled = val == true
        TweenService:Create(toggleBg, TweenInfo.new(0.2), {
            BackgroundColor3 = enabled and Theme.Accent or Theme.Panel
        }):Play()
        TweenService:Create(ball, TweenInfo.new(0.2), {
            Position = enabled and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
        }):Play()
    end

    row.MouseButton1Click:Connect(function()
        enabled = not enabled
        UpdateVisual(enabled)
        if callback then callback(enabled) end
        if getgenv().AutoSaveConfiguration then getgenv().AutoSaveConfiguration() end
    end)

    return UpdateVisual
end

AddSettingsToggle(MenuCard.Content, "Auto hide UI after execute", Settings.AutoCloseExecute, function(v)
    Settings.AutoCloseExecute = v
end)

AddSettingsToggle(MenuCard.Content, "Watermark", Settings.Watermark ~= false, function(v)
    Settings.Watermark = v
    WatermarkFrame.Visible = v
end)

AddSettingsToggle(MenuCard.Content, "Mobile toggle button", Settings.MobileToggle ~= false, function(v)
    Settings.MobileToggle = v
    MobileToggleBtn.Visible = v
end)

AddSettingsToggle(MenuCard.Content, "Dim background", Settings.DimBackground == true, function(v)
    Settings.DimBackground = v
    if DimmerFrame then
        DimmerFrame.Visible = (v and Main.Visible)
    end
end)

-- Card 2: Weather
local WeatherCard = CreateCard(SettingsPage, "Weather", "⛅", 2, "Settings_Weather")

local function AddSettingsDropdown(parent, name, options, defaultOption, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 36)
    row.BackgroundColor3 = Theme.Element
    row.BorderSizePixel = 0
    row.Parent = parent
    local rCorner = Instance.new("UICorner") rCorner.CornerRadius = UDim.new(0, 5) rCorner.Parent = row
    RegisterThemedObject(row, "BackgroundColor3", "Element")

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -110, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Theme.Text
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row
    RegisterThemedObject(label, "TextColor3", "Text")

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 95, 0, 24)
    btn.Position = UDim2.new(1, -105, 0.5, -12)
    btn.BackgroundColor3 = Theme.Panel
    btn.BorderSizePixel = 0
    btn.Text = tostring(defaultOption) .. "  ▼"
    btn.TextColor3 = Theme.Accent
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.Parent = row
    local bc = Instance.new("UICorner") bc.CornerRadius = UDim.new(0, 4) bc.Parent = btn
    local bs = Instance.new("UIStroke") bs.Color = Theme.Outline bs.Thickness = 1 bs.Parent = btn
    RegisterThemedObject(btn, "BackgroundColor3", "Panel")
    RegisterThemedObject(btn, "TextColor3", "Accent")
    RegisterThemedObject(bs, "Color", "Outline")

    local currentIdx = 1
    for i, opt in ipairs(options) do
        if opt == defaultOption then currentIdx = i break end
    end

    btn.MouseButton1Click:Connect(function()
        currentIdx = currentIdx + 1
        if currentIdx > #options then currentIdx = 1 end
        btn.Text = tostring(options[currentIdx]) .. "  ▼"
        if callback then callback(options[currentIdx]) end
        if getgenv().AutoSaveConfiguration then getgenv().AutoSaveConfiguration() end
    end)
end

AddSettingsDropdown(WeatherCard.Content, "Weather style", {"Off", "Snow", "Rain", "Stars"}, Settings.Weather or "Off", function(v)
    Settings.Weather = v
    StartWeatherEngine()
end)

AddSettingsDropdown(WeatherCard.Content, "Weather area", {"Inside UI", "Screen"}, Settings.WeatherArea or "Inside UI", function(v)
    Settings.WeatherArea = v
    StartWeatherEngine()
end)

local function AddSettingsSlider(parent, name, minVal, maxVal, defaultVal, suffix, callback)
    minVal = tonumber(minVal) or 0
    maxVal = tonumber(maxVal) or 100
    defaultVal = tonumber(defaultVal) or minVal
    if maxVal <= minVal then maxVal = minVal + 1 end
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 42)
    row.BackgroundColor3 = Theme.Element
    row.BorderSizePixel = 0
    row.Parent = parent
    local rCorner = Instance.new("UICorner") rCorner.CornerRadius = UDim.new(0, 5) rCorner.Parent = row
    RegisterThemedObject(row, "BackgroundColor3", "Element")

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -60, 0, 18)
    label.Position = UDim2.new(0, 10, 0, 4)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Theme.Text
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row
    RegisterThemedObject(label, "TextColor3", "Text")

    local valLabel = Instance.new("TextLabel")
    valLabel.Size = UDim2.new(0, 50, 0, 18)
    valLabel.Position = UDim2.new(1, -60, 0, 4)
    valLabel.BackgroundTransparency = 1
    valLabel.Text = tostring(defaultVal) .. (suffix or "")
    valLabel.TextColor3 = Theme.DimText
    valLabel.Font = Enum.Font.GothamBold
    valLabel.TextSize = 11
    valLabel.TextXAlignment = Enum.TextXAlignment.Right
    valLabel.Parent = row
    RegisterThemedObject(valLabel, "TextColor3", "DimText")

    local bar = Instance.new("TextButton")
    bar.Size = UDim2.new(1, -20, 0, 8)
    bar.Position = UDim2.new(0, 10, 0, 26)
    bar.BackgroundColor3 = Theme.Panel
    bar.BorderSizePixel = 0
    bar.Text = ""
    bar.AutoButtonColor = false
    bar.Parent = row
    local bc = Instance.new("UICorner") bc.CornerRadius = UDim.new(1, 0) bc.Parent = bar
    RegisterThemedObject(bar, "BackgroundColor3", "Panel")

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(math.clamp((defaultVal - minVal) / (maxVal - minVal), 0, 1), 0, 1, 0)
    fill.BackgroundColor3 = Theme.Accent
    fill.BorderSizePixel = 0
    fill.Parent = bar
    local fc = Instance.new("UICorner") fc.CornerRadius = UDim.new(1, 0) fc.Parent = fill
    RegisterThemedObject(fill, "BackgroundColor3", "Accent")

    local currentVal = defaultVal
    local function Update(inpX)
        local rel = math.clamp((inpX - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        currentVal = math.floor(minVal + rel * (maxVal - minVal))
        valLabel.Text = tostring(currentVal) .. (suffix or "")
        fill.Size = UDim2.new(rel, 0, 1, 0)
        if callback then callback(currentVal) end
    end

    bar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            Update(inp.Position.X)
            local moveConn, endConn
            moveConn = UserInputService.InputChanged:Connect(function(change)
                if change.UserInputType == Enum.UserInputType.MouseMovement or change.UserInputType == Enum.UserInputType.Touch then
                    Update(change.Position.X)
                end
            end)
            endConn = UserInputService.InputEnded:Connect(function(ended)
                if ended.UserInputType == Enum.UserInputType.MouseButton1 or ended.UserInputType == Enum.UserInputType.Touch then
                    if moveConn then moveConn:Disconnect() end
                    if endConn then endConn:Disconnect() end
                    if getgenv().AutoSaveConfiguration then getgenv().AutoSaveConfiguration() end
                end
            end)
        end
    end)
end

AddSettingsSlider(WeatherCard.Content, "Weather amount", 10, 100, Settings.WeatherAmount or 100, "%", function(v)
    Settings.WeatherAmount = v
    StartWeatherEngine()
end)

AddSettingsSlider(WeatherCard.Content, "Weather size", 30, 200, Settings.WeatherSize or 100, "%", function(v)
    Settings.WeatherSize = v
    StartWeatherEngine()
end)

-- Card 3: Layout Options
local LayoutCard = CreateCard(SettingsPage, "Layout", "📐", 3, "Settings_Layout")

AddSettingsToggle(LayoutCard.Content, "Draggable cards", Settings.DraggableCards ~= false, function(v)
    Settings.DraggableCards = v
end)

AddSettingsToggle(LayoutCard.Content, "Collapse sidebar", Settings.CollapseSidebar == true, function(v)
    SetSidebarCollapsed(v)
end)

local ResetLayoutBtn = Instance.new("TextButton")
ResetLayoutBtn.Size = UDim2.new(1, 0, 0, 32)
ResetLayoutBtn.BackgroundColor3 = Theme.Element
ResetLayoutBtn.BorderSizePixel = 0
ResetLayoutBtn.Text = "Reset card layout"
ResetLayoutBtn.TextColor3 = Theme.Text
ResetLayoutBtn.Font = Enum.Font.GothamMedium
ResetLayoutBtn.TextSize = 11
ResetLayoutBtn.Parent = LayoutCard.Content
local rlbCorner = Instance.new("UICorner") rlbCorner.CornerRadius = UDim.new(0, 5) rlbCorner.Parent = ResetLayoutBtn
RegisterThemedObject(ResetLayoutBtn, "BackgroundColor3", "Element")
RegisterThemedObject(ResetLayoutBtn, "TextColor3", "Text")

ResetLayoutBtn.MouseButton1Click:Connect(function()
    CardLayoutOrder = {}
    Settings.CardLayoutOrder = {}
    for _, card in ipairs(CardRegistry) do
        if card and card.Parent then
            local def = card:GetAttribute("DefaultOrder") or 1
            card.LayoutOrder = def
        end
    end
    if getgenv().AutoSaveConfiguration then getgenv().AutoSaveConfiguration() end
    CustomNotify("Card layout reset to defaults!", Theme.Accent, 3)
end)

AddSettingsToggle(LayoutCard.Content, "Auto scale to screen", Settings.AutoScaleScreen ~= false, function(v)
    Settings.AutoScaleScreen = v
end)

-- Card 4: Colors (Theme Customizer)
local ColorsCard = CreateCard(SettingsPage, "Colors", "🎨", 4, "Settings_Colors")

AddSettingsToggle(ColorsCard.Content, "Window gradient", Settings.WindowGradient ~= false, function(v)
    Settings.WindowGradient = v
    MainGradient.Enabled = v
end)

local function AddColorSwatchRow(name, colorKey)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 34)
    row.BackgroundColor3 = Theme.Element
    row.BorderSizePixel = 0
    row.Parent = ColorsCard.Content
    local rc = Instance.new("UICorner") rc.CornerRadius = UDim.new(0, 5) rc.Parent = row
    RegisterThemedObject(row, "BackgroundColor3", "Element")

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -60, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Theme.Text
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row
    RegisterThemedObject(label, "TextColor3", "Text")

    local swatch = Instance.new("TextButton")
    swatch.Size = UDim2.new(0, 36, 0, 20)
    swatch.Position = UDim2.new(1, -46, 0.5, -10)
    swatch.BackgroundColor3 = Theme[colorKey] or Color3.fromRGB(255, 255, 255)
    swatch.BorderSizePixel = 0
    swatch.Text = ""
    swatch.AutoButtonColor = false
    swatch.Parent = row
    local sc = Instance.new("UICorner") sc.CornerRadius = UDim.new(0, 4) sc.Parent = swatch
    local ss = Instance.new("UIStroke") ss.Color = Theme.Outline ss.Thickness = 1 ss.Parent = swatch
    RegisterThemedObject(ss, "Color", "Outline")

    swatch.MouseButton1Click:Connect(function()
        OpenColorPicker(colorKey, swatch)
    end)
end

AddColorSwatchRow("Background", "Background")
AddColorSwatchRow("Panel", "Panel")
AddColorSwatchRow("Element", "Element")
AddColorSwatchRow("Hover", "Hover")
AddColorSwatchRow("Outline", "Outline")
AddColorSwatchRow("Accent", "Accent")
AddColorSwatchRow("Accent 2", "Accent2")
AddColorSwatchRow("Text", "Text")
AddColorSwatchRow("DimText", "DimText")
AddColorSwatchRow("Risky", "Risky")

-- Card 5: Wallpaper
local WallpaperCard = CreateCard(SettingsPage, "Wallpaper", "🖼️", 5, "Settings_Wallpaper")

local WallUrlBox = Instance.new("TextBox")
WallUrlBox.Size = UDim2.new(1, 0, 0, 30)
WallUrlBox.BackgroundColor3 = Theme.Element
WallUrlBox.BorderSizePixel = 0
WallUrlBox.Text = Settings.WallpaperUrl or ""
WallUrlBox.PlaceholderText = "https://raw.githubusercontent.com/... or rbxassetid://..."
WallUrlBox.PlaceholderColor3 = Theme.DimText
WallUrlBox.TextColor3 = Theme.Text
WallUrlBox.Font = Enum.Font.Gotham
WallUrlBox.TextSize = 11
WallUrlBox.ClearTextOnFocus = false
WallUrlBox.Parent = WallpaperCard.Content
local wbCorner = Instance.new("UICorner") wbCorner.CornerRadius = UDim.new(0, 5) wbCorner.Parent = WallUrlBox
local wbPadding = Instance.new("UIPadding") wbPadding.PaddingLeft = UDim.new(0, 8) wbPadding.Parent = WallUrlBox
RegisterThemedObject(WallUrlBox, "BackgroundColor3", "Element")
RegisterThemedObject(WallUrlBox, "TextColor3", "Text")
RegisterThemedObject(WallUrlBox, "PlaceholderColor3", "DimText")

AddSettingsSlider(WallpaperCard.Content, "Wallpaper dim", 0, 100, math.floor((Settings.WallpaperDim or 0.25) * 100), "%", function(v)
    local dim = v / 100
    Settings.WallpaperDim = dim
    WallpaperImage.ImageTransparency = dim
end)

local WallBtnRow = Instance.new("Frame")
WallBtnRow.Size = UDim2.new(1, 0, 0, 30)
WallBtnRow.BackgroundTransparency = 1
WallBtnRow.Parent = WallpaperCard.Content

local ApplyWallBtn = Instance.new("TextButton")
ApplyWallBtn.Size = UDim2.new(0.65, -4, 1, 0)
ApplyWallBtn.BackgroundColor3 = Theme.Accent
ApplyWallBtn.BorderSizePixel = 0
ApplyWallBtn.Text = "Apply wallpaper"
ApplyWallBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ApplyWallBtn.Font = Enum.Font.GothamBold
ApplyWallBtn.TextSize = 11
ApplyWallBtn.Parent = WallBtnRow
local awCorner = Instance.new("UICorner") awCorner.CornerRadius = UDim.new(0, 5) awCorner.Parent = ApplyWallBtn
RegisterThemedObject(ApplyWallBtn, "BackgroundColor3", "Accent")

local ClearWallBtn = Instance.new("TextButton")
ClearWallBtn.Size = UDim2.new(0.35, -4, 1, 0)
ClearWallBtn.Position = UDim2.new(0.65, 4, 0, 0)
ClearWallBtn.BackgroundColor3 = Theme.Element
ClearWallBtn.BorderSizePixel = 0
ClearWallBtn.Text = "Clear"
ClearWallBtn.TextColor3 = Theme.Text
ClearWallBtn.Font = Enum.Font.GothamMedium
ClearWallBtn.TextSize = 11
ClearWallBtn.Parent = WallBtnRow
local cwCorner = Instance.new("UICorner") cwCorner.CornerRadius = UDim.new(0, 5) cwCorner.Parent = ClearWallBtn
RegisterThemedObject(ClearWallBtn, "BackgroundColor3", "Element")
RegisterThemedObject(ClearWallBtn, "TextColor3", "Text")

ApplyWallBtn.MouseButton1Click:Connect(function()
    local url = tostring(WallUrlBox.Text or "")
    Settings.WallpaperUrl = url
    WallpaperImage.Image = url
    if getgenv().AutoSaveConfiguration then getgenv().AutoSaveConfiguration() end
    CustomNotify("Wallpaper applied successfully!", Theme.Accent, 3)
end)

ClearWallBtn.MouseButton1Click:Connect(function()
    Settings.WallpaperUrl = ""
    WallUrlBox.Text = ""
    WallpaperImage.Image = ""
    if getgenv().AutoSaveConfiguration then getgenv().AutoSaveConfiguration() end
    CustomNotify("Wallpaper cleared", Theme.Accent, 2)
end)

-- Card 6: Icon
local IconCard = CreateCard(SettingsPage, "Icon", "⭐", 6, "Settings_Icon")
local IconUrlBox = Instance.new("TextBox")
IconUrlBox.Size = UDim2.new(1, 0, 0, 30)
IconUrlBox.BackgroundColor3 = Theme.Element
IconUrlBox.BorderSizePixel = 0
IconUrlBox.Text = Settings.CustomIconUrl or ""
IconUrlBox.PlaceholderText = "image url or rbxassetid://..."
IconUrlBox.PlaceholderColor3 = Theme.DimText
IconUrlBox.TextColor3 = Theme.Text
IconUrlBox.Font = Enum.Font.Gotham
IconUrlBox.TextSize = 11
IconUrlBox.ClearTextOnFocus = false
IconUrlBox.Parent = IconCard.Content
local ibCorner = Instance.new("UICorner") ibCorner.CornerRadius = UDim.new(0, 5) ibCorner.Parent = IconUrlBox
local ibPadding = Instance.new("UIPadding") ibPadding.PaddingLeft = UDim.new(0, 8) ibPadding.Parent = IconUrlBox
RegisterThemedObject(IconUrlBox, "BackgroundColor3", "Element")
RegisterThemedObject(IconUrlBox, "TextColor3", "Text")
RegisterThemedObject(IconUrlBox, "PlaceholderColor3", "DimText")

local ApplyIconBtn = Instance.new("TextButton")
ApplyIconBtn.Size = UDim2.new(1, 0, 0, 30)
ApplyIconBtn.BackgroundColor3 = Theme.Element
ApplyIconBtn.BorderSizePixel = 0
ApplyIconBtn.Text = "Apply icon"
ApplyIconBtn.TextColor3 = Theme.Text
ApplyIconBtn.Font = Enum.Font.GothamMedium
ApplyIconBtn.TextSize = 11
ApplyIconBtn.Parent = IconCard.Content
local aibCorner = Instance.new("UICorner") aibCorner.CornerRadius = UDim.new(0, 5) aibCorner.Parent = ApplyIconBtn
RegisterThemedObject(ApplyIconBtn, "BackgroundColor3", "Element")
RegisterThemedObject(ApplyIconBtn, "TextColor3", "Text")

ApplyIconBtn.MouseButton1Click:Connect(function()
    local url = tostring(IconUrlBox.Text or "")
    if url ~= "" then
        Settings.CustomIconUrl = url
        HubLogo.Image = url
        MobileToggleBtn.Image = url
        if getgenv().AutoSaveConfiguration then getgenv().AutoSaveConfiguration() end
        CustomNotify("Custom icon applied!", Theme.Accent, 3)
    end
end)

-- ==============================================================================
-- TELEMETRY LOOP (Live FPS, Ping, Session Time, MM2 Roles)
-- ==============================================================================

task.spawn(function()
    local frameCount = 0
    local lastFpsTime = os.clock()
    local currentFps = 60

    RunService.RenderStepped:Connect(function()
        frameCount = frameCount + 1
        local now = os.clock()
        if now - lastFpsTime >= 0.5 then
            currentFps = math.floor(frameCount / (now - lastFpsTime) + 0.5)
            frameCount = 0
            lastFpsTime = now
        end
    end)

    while not getgenv().Destroyed do
        local elapsed = os.clock() - (StartSessionTime or os.clock())
        local mins = math.floor(elapsed / 60)
        local secs = math.floor(elapsed % 60)
        local timeStr = tostring(mins) .. "m " .. tostring(secs) .. "s"
        UpdateSessionPill(timeStr)

        -- Features On Count
        local activeFeatures = 0
        for k, v in pairs(Settings) do
            if v == true and k ~= "DraggableCards" and k ~= "AutoScaleScreen" and k ~= "WindowGradient" then
                activeFeatures = activeFeatures + 1
            end
        end
        UpdateFeaturesPill(tostring(activeFeatures))

        -- FPS
        UpdateFPSPill(tostring(currentFps))

        -- Ping
        local pingVal = 45
        pcall(function()
            local raw = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValueString()
            local num = tonumber(string.match(raw, "%d+"))
            if num then pingVal = num end
        end)
        UpdatePingPill(tostring(pingVal) .. " ms")

        -- Players
        local pCount = #Players:GetPlayers()
        local maxP = Players.MaxPlayers
        UpdatePlayersPill(tostring(pCount) .. " / " .. tostring(maxP))

        -- Watermark Update
        if WatermarkFrame and WatermarkFrame.Visible and WatermarkLabel then
            WatermarkLabel.Text = "<b>ToxHub</b> v2.0  |  FPS: " .. tostring(currentFps) .. "  |  Ping: " .. tostring(pingVal) .. "ms"
        end

        -- MM2 Stats check
        if game.PlaceId == 142823291 then
            pcall(function()
                local murd, sher = "None", "None"
                for _, p in ipairs(Players:GetPlayers()) do
                    local char = p.Character
                    local bp = p:FindFirstChild("Backpack")
                    if (char and char:FindFirstChild("Knife")) or (bp and bp:FindFirstChild("Knife")) then
                        murd = p.DisplayName
                    end
                    if (char and char:FindFirstChild("Gun")) or (bp and bp:FindFirstChild("Gun")) then
                        sher = p.DisplayName
                    end
                end
                UpdateMurdererStat(murd)
                UpdateSheriffStat(sher)
                UpdatePlayersStat(tostring(pCount))
            end)
        end

        task.wait(1)
    end
end)

do
local SubGuisPreKeyHiddenState = getgenv().SubGuisPreKeyHiddenState or {}
getgenv().SubGuisPreKeyHiddenState = SubGuisPreKeyHiddenState

local function ToggleToxGui(forceVisible)
    local targetVisible = forceVisible
    if targetVisible == nil then
        targetVisible = not Main.Visible
    end

    Main.Visible = targetVisible
    if DimmerFrame then
        DimmerFrame.Visible = (Settings.DimBackground == true and targetVisible)
    end

    if not targetVisible then
        if getgenv().ChatLogGui and getgenv().ChatLogGui.Parent then
            SubGuisPreKeyHiddenState.ChatLog = getgenv().ChatLogGui.Visible
            getgenv().ChatLogGui.Visible = false
        end
        if getgenv().MusicGui and getgenv().MusicGui.Parent then
            SubGuisPreKeyHiddenState.Music = getgenv().MusicGui.Visible
            getgenv().MusicGui.Visible = false
        end
        if getgenv().WaypointsGui and getgenv().WaypointsGui.Parent then
            SubGuisPreKeyHiddenState.Waypoints = getgenv().WaypointsGui.Visible
            getgenv().WaypointsGui.Visible = false
        end
        for key, gui in pairs(getgenv().ToxLinkedSubGuis or {}) do
            if gui and gui.Parent then
                SubGuisPreKeyHiddenState["Extra_" .. tostring(key)] = gui.Visible
                gui.Visible = false
            end
        end
    else
        if not getgenv().ToxMainMinimized then
            if SubGuisPreKeyHiddenState.ChatLog ~= nil and getgenv().ChatLogGui and getgenv().ChatLogGui.Parent then
                getgenv().ChatLogGui.Visible = SubGuisPreKeyHiddenState.ChatLog
            end
            if SubGuisPreKeyHiddenState.Music ~= nil and getgenv().MusicGui and getgenv().MusicGui.Parent then
                getgenv().MusicGui.Visible = SubGuisPreKeyHiddenState.Music
            end
            if SubGuisPreKeyHiddenState.Waypoints ~= nil and getgenv().WaypointsGui and getgenv().WaypointsGui.Parent then
                getgenv().WaypointsGui.Visible = SubGuisPreKeyHiddenState.Waypoints
            end
            for key, gui in pairs(getgenv().ToxLinkedSubGuis or {}) do
                if gui and gui.Parent and SubGuisPreKeyHiddenState["Extra_" .. tostring(key)] ~= nil then
                    gui.Visible = SubGuisPreKeyHiddenState["Extra_" .. tostring(key)]
                end
            end
        end
    end
end
getgenv().ToggleToxGui = ToggleToxGui

-- Keybind toggling Main window
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    local matchKey = false
    if typeof(Settings.GUIKeybind) == "EnumItem" then
        matchKey = (input.KeyCode == Settings.GUIKeybind)
    elseif typeof(Settings.GUIKeybind) == "string" then
        matchKey = (input.KeyCode.Name == Settings.GUIKeybind)
    end
    if matchKey then
        ToggleToxGui()
    end
end)
end

-- Default open Home Page
ToxOpenPage(HomePage)

end -- HOME DASHBOARD, SETTINGS & TELEMETRY



do -- EMBEDDED WIDGETS
-- EMBEDDED WIDGETS (CHAT & QUICK JOIN)
-- ==============================================================================

-- Embedded ToxChat in ChatPage
ToxChatGui = Instance.new("Frame")
ToxChatGui.Name = "ToxChatFrame"
ToxChatGui.Size = UDim2.new(1, 0, 1, 0)
ToxChatGui.Position = UDim2.new(0, 0, 0, 0)
ToxChatGui.BackgroundColor3 = Theme.Panel
ToxChatGui.BorderSizePixel = 0
ToxChatGui.ClipsDescendants = true
ToxChatGui.Visible = false
ToxChatGui.Parent = ChatPage
getgenv().ToxChatGui = ToxChatGui
RegisterThemedObject(ToxChatGui, "BackgroundColor3", "Panel")

local ToxChatCorner = Instance.new("UICorner") ToxChatCorner.CornerRadius = UDim.new(0, 8) ToxChatCorner.Parent = ToxChatGui
local ToxChatStroke = Instance.new("UIStroke") ToxChatStroke.Color = Theme.Outline ToxChatStroke.Thickness = 1.5 ToxChatStroke.Parent = ToxChatGui
RegisterThemedObject(ToxChatStroke, "Color", "Outline")

local ToxChatTopBar = Instance.new("Frame")
ToxChatTopBar.Size = UDim2.new(1, 0, 0, 32)
ToxChatTopBar.BackgroundColor3 = Theme.Element
ToxChatTopBar.BorderSizePixel = 0
ToxChatTopBar.Parent = ToxChatGui
getgenv().ToxChatTopBar = ToxChatTopBar
RegisterThemedObject(ToxChatTopBar, "BackgroundColor3", "Element")

local ToxChatTitle = Instance.new("TextLabel")
ToxChatTitle.Size = UDim2.new(1, -70, 1, 0)
ToxChatTitle.Position = UDim2.new(0, 10, 0, 0)
ToxChatTitle.BackgroundTransparency = 1
ToxChatTitle.Text = "ToxHub Global Chat"
ToxChatTitle.TextColor3 = Theme.Text
ToxChatTitle.Font = Enum.Font.GothamBold
ToxChatTitle.TextSize = 13
ToxChatTitle.TextXAlignment = Enum.TextXAlignment.Left
ToxChatTitle.Parent = ToxChatTopBar
RegisterThemedObject(ToxChatTitle, "TextColor3", "Text")

local ToxChatStatus = Instance.new("TextLabel")
ToxChatStatus.Size = UDim2.new(1, -16, 0, 18)
ToxChatStatus.Position = UDim2.new(0, 8, 0, 36)
ToxChatStatus.BackgroundTransparency = 1
ToxChatStatus.Text = "Global cross-server chatroom"
ToxChatStatus.TextColor3 = Theme.DimText
ToxChatStatus.Font = Enum.Font.Gotham
ToxChatStatus.TextSize = 10
ToxChatStatus.TextXAlignment = Enum.TextXAlignment.Left
ToxChatStatus.Parent = ToxChatGui
getgenv().ToxChatStatus = ToxChatStatus
RegisterThemedObject(ToxChatStatus, "TextColor3", "DimText")

local ToxChatScroll = Instance.new("ScrollingFrame")
ToxChatScroll.Size = UDim2.new(1, -8, 1, -94)
ToxChatScroll.Position = UDim2.new(0, 4, 0, 56)
ToxChatScroll.BackgroundTransparency = 1
ToxChatScroll.BorderSizePixel = 0
ToxChatScroll.ScrollBarThickness = 3
ToxChatScroll.ScrollBarImageColor3 = Theme.Accent
ToxChatScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
ToxChatScroll.Parent = ToxChatGui
getgenv().ToxChatScroll = ToxChatScroll
RegisterThemedObject(ToxChatScroll, "ScrollBarImageColor3", "Accent")

local ToxChatLayout = Instance.new("UIListLayout")
ToxChatLayout.Padding = UDim.new(0, 4)
ToxChatLayout.SortOrder = Enum.SortOrder.LayoutOrder
ToxChatLayout.Parent = ToxChatScroll

ToxChatLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ToxChatScroll.CanvasSize = UDim2.new(0, 0, 0, ToxChatLayout.AbsoluteContentSize.Y + 8)
    ToxChatScroll.CanvasPosition = Vector2.new(0, math.max(0, ToxChatLayout.AbsoluteContentSize.Y))
end)

local ToxChatInput = Instance.new("TextBox")
ToxChatInput.Size = UDim2.new(1, -78, 0, 30)
ToxChatInput.Position = UDim2.new(0, 4, 1, -34)
ToxChatInput.BackgroundColor3 = Theme.Element
ToxChatInput.BorderSizePixel = 0
ToxChatInput.PlaceholderText = "Type message..."
ToxChatInput.PlaceholderColor3 = Theme.DimText
ToxChatInput.Text = ""
ToxChatInput.TextColor3 = Theme.Text
ToxChatInput.Font = Enum.Font.Gotham
ToxChatInput.TextSize = 11
ToxChatInput.ClearTextOnFocus = false
ToxChatInput.Parent = ToxChatGui
getgenv().ToxChatInput = ToxChatInput
local tciCorner = Instance.new("UICorner") tciCorner.CornerRadius = UDim.new(0, 5) tciCorner.Parent = ToxChatInput
local tciPadding = Instance.new("UIPadding") tciPadding.PaddingLeft = UDim.new(0, 8) tciPadding.Parent = ToxChatInput
RegisterThemedObject(ToxChatInput, "BackgroundColor3", "Element")
RegisterThemedObject(ToxChatInput, "TextColor3", "Text")
RegisterThemedObject(ToxChatInput, "PlaceholderColor3", "DimText")

local ToxChatSendBtn = Instance.new("TextButton")
ToxChatSendBtn.Size = UDim2.new(0, 68, 0, 30)
ToxChatSendBtn.Position = UDim2.new(1, -72, 1, -34)
ToxChatSendBtn.BackgroundColor3 = Theme.Accent
ToxChatSendBtn.BorderSizePixel = 0
ToxChatSendBtn.Text = "Send"
ToxChatSendBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToxChatSendBtn.Font = Enum.Font.GothamBold
ToxChatSendBtn.TextSize = 12
ToxChatSendBtn.Parent = ToxChatGui
getgenv().ToxChatSendBtn = ToxChatSendBtn
local tcsCorner = Instance.new("UICorner") tcsCorner.CornerRadius = UDim.new(0, 5) tcsCorner.Parent = ToxChatSendBtn
RegisterThemedObject(ToxChatSendBtn, "BackgroundColor3", "Accent")

getgenv().AddToxChatMessage = function(displayName, message, blocked, showPopup)
    if not ToxChatScroll or not ToxChatScroll.Parent then return end

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -6, 0, 0)
    label.AutomaticSize = Enum.AutomaticSize.Y
    label.BackgroundColor3 = Theme.Element
    label.BackgroundTransparency = 0.2
    label.BorderSizePixel = 0
    label.Text = tostring(displayName) .. ": " .. tostring(message)
    label.TextColor3 = blocked and Theme.Risky or Theme.Text
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Top
    label.Font = Enum.Font.Gotham
    label.TextSize = 11
    label.Parent = ToxChatScroll

    local corner = Instance.new("UICorner") corner.CornerRadius = UDim.new(0, 4) corner.Parent = label
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 8)
    padding.PaddingRight = UDim.new(0, 8)
    padding.PaddingTop = UDim.new(0, 5)
    padding.PaddingBottom = UDim.new(0, 5)
    padding.Parent = label

    if showPopup ~= false and getgenv().ShowToxChatPopup then
        getgenv().ShowToxChatPopup(displayName, message, blocked)
    end
end

getgenv().ClearToxChatMessages = function()
    for _, child in ipairs(ToxChatScroll:GetChildren()) do
        if child:IsA("TextLabel") then child:Destroy() end
    end
end

-- Embedded Quick Join inside JoinPage
local JoinGamesGui = Instance.new("Frame")
JoinGamesGui.Name = "ToxQuickJoinFrame"
JoinGamesGui.Size = UDim2.new(1, 0, 1, 0)
JoinGamesGui.Position = UDim2.new(0, 0, 0, 0)
JoinGamesGui.BackgroundColor3 = Theme.Panel
JoinGamesGui.BorderSizePixel = 0
JoinGamesGui.ClipsDescendants = true
JoinGamesGui.Visible = true
JoinGamesGui.Parent = JoinPage
getgenv().JoinGamesGui = JoinGamesGui
RegisterThemedObject(JoinGamesGui, "BackgroundColor3", "Panel")

local JoinGamesCorner = Instance.new("UICorner") JoinGamesCorner.CornerRadius = UDim.new(0, 8) JoinGamesCorner.Parent = JoinGamesGui
local JoinGamesStroke = Instance.new("UIStroke") JoinGamesStroke.Color = Theme.Outline JoinGamesStroke.Thickness = 1.5 JoinGamesStroke.Parent = JoinGamesGui
RegisterThemedObject(JoinGamesStroke, "Color", "Outline")

local JoinGameAddArea = Instance.new("Frame")
JoinGameAddArea.Size = UDim2.new(1, -16, 0, 32)
JoinGameAddArea.Position = UDim2.new(0, 8, 0, 10)
JoinGameAddArea.BackgroundTransparency = 1
JoinGameAddArea.Parent = JoinGamesGui

local JoinGameIdBox = Instance.new("TextBox")
JoinGameIdBox.Size = UDim2.new(1, -95, 1, 0)
JoinGameIdBox.Position = UDim2.new(0, 0, 0, 0)
JoinGameIdBox.BackgroundColor3 = Theme.Element
JoinGameIdBox.BorderSizePixel = 0
JoinGameIdBox.PlaceholderText = "Enter Place ID..."
JoinGameIdBox.Text = ""
JoinGameIdBox.TextColor3 = Theme.Text
JoinGameIdBox.PlaceholderColor3 = Theme.DimText
JoinGameIdBox.Font = Enum.Font.Gotham
JoinGameIdBox.TextSize = 11
JoinGameIdBox.ClearTextOnFocus = false
JoinGameIdBox.Parent = JoinGameAddArea
local jgbCorner = Instance.new("UICorner") jgbCorner.CornerRadius = UDim.new(0, 5) jgbCorner.Parent = JoinGameIdBox
local jgbPad = Instance.new("UIPadding") jgbPad.PaddingLeft = UDim.new(0, 8) jgbPad.Parent = JoinGameIdBox
getgenv().JoinGameIdBox = JoinGameIdBox
RegisterThemedObject(JoinGameIdBox, "BackgroundColor3", "Element")
RegisterThemedObject(JoinGameIdBox, "TextColor3", "Text")
RegisterThemedObject(JoinGameIdBox, "PlaceholderColor3", "DimText")

local JoinGameAddButton = Instance.new("TextButton")
JoinGameAddButton.Size = UDim2.new(0, 88, 1, 0)
JoinGameAddButton.Position = UDim2.new(1, -88, 0, 0)
JoinGameAddButton.BackgroundColor3 = Theme.Accent
JoinGameAddButton.BorderSizePixel = 0
JoinGameAddButton.Text = "Add Game"
JoinGameAddButton.TextColor3 = Color3.fromRGB(255, 255, 255)
JoinGameAddButton.Font = Enum.Font.GothamBold
JoinGameAddButton.TextSize = 11
JoinGameAddButton.Parent = JoinGameAddArea
local jgabCorner = Instance.new("UICorner") jgabCorner.CornerRadius = UDim.new(0, 5) jgabCorner.Parent = JoinGameAddButton
getgenv().JoinGameAddButton = JoinGameAddButton
RegisterThemedObject(JoinGameAddButton, "BackgroundColor3", "Accent")

local JoinGamesScroll = Instance.new("ScrollingFrame")
JoinGamesScroll.Size = UDim2.new(1, -16, 1, -54)
JoinGamesScroll.Position = UDim2.new(0, 8, 0, 48)
JoinGamesScroll.BackgroundTransparency = 1
JoinGamesScroll.BorderSizePixel = 0
JoinGamesScroll.ScrollBarThickness = 3
JoinGamesScroll.ScrollBarImageColor3 = Theme.Accent
JoinGamesScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
JoinGamesScroll.Parent = JoinGamesGui
getgenv().JoinGamesScroll = JoinGamesScroll
RegisterThemedObject(JoinGamesScroll, "ScrollBarImageColor3", "Accent")

local JoinGamesLayout = Instance.new("UIListLayout")
JoinGamesLayout.Padding = UDim.new(0, 6)
JoinGamesLayout.SortOrder = Enum.SortOrder.LayoutOrder
JoinGamesLayout.Parent = JoinGamesScroll

JoinGamesLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    JoinGamesScroll.CanvasSize = UDim2.new(0, 0, 0, JoinGamesLayout.AbsoluteContentSize.Y + 8)
end)

ApplySavedGuiPosition("Main", Main)
TrackGuiPosition("Main", Main)

-- ==============================================================================

end

-- SHARED CONTROLS & CONTROL FACTORIES (CreateToggle, CreateButton, etc.)
-- ==============================================================================

getgenv().SharedToggleControls = {}
getgenv().SharedValueControls = {}

getgenv().SyncToggleVisuals = function(Key, Value)
    if not Key then return end
    local controls = getgenv().SharedToggleControls[Key]
    if not controls then return end

    for index = #controls, 1, -1 do
        local controller = controls[index]
        local button = controller and controller.Button
        if not controller or not controller.SetVisual or not button or not button.Parent then
            table.remove(controls, index)
        else
            pcall(function() controller.SetVisual(Value) end)
        end
    end
end

function RegisterSharedToggle(Key, Controller)
    if not Key or not Controller then return end
    if not getgenv().SharedToggleControls[Key] then
        getgenv().SharedToggleControls[Key] = {}
    end
    table.insert(getgenv().SharedToggleControls[Key], Controller)
end
getgenv().RegisterSharedToggle = RegisterSharedToggle

local function RegisterStartupToggleCallback(Key, Callback)
    if getgenv().ToxOptionsReady ~= false or not Key or type(Callback) ~= "function" then
        return
    end
    local callbacks = getgenv().ToxStartupToggleCallbacks
    if typeof(callbacks) ~= "table" then
        callbacks = {}
        getgenv().ToxStartupToggleCallbacks = callbacks
    end
    if callbacks[Key] == nil then
        callbacks[Key] = Callback
    end
end
getgenv().RegisterStartupToggleCallback = RegisterStartupToggleCallback

getgenv().SyncValueVisuals = function(Key, Value)
    if not Key then return end
    local controls = getgenv().SharedValueControls[Key]
    if controls then
        for _, controller in ipairs(controls) do
            if controller and controller.SetValue then
                controller.SetValue(Value)
            end
        end
    end
    if getgenv().ToxOnSharedValueChanged then
        getgenv().ToxOnSharedValueChanged(Key, Value)
    end
end

function RegisterSharedValue(Key, Controller)
    if not Key or not Controller then return end
    if not getgenv().SharedValueControls[Key] then
        getgenv().SharedValueControls[Key] = {}
    end
    table.insert(getgenv().SharedValueControls[Key], Controller)
end

local function IsFeatureRisky(name)
    local n = string.lower(tostring(name or ""))
    return string.find(n, "aura") ~= nil or string.find(n, "kill") ~= nil or string.find(n, "fling") ~= nil or string.find(n, "blatant") ~= nil
end

getgenv().CreateToggle = function(Name, Page, DefaultValue, Callback, SyncKey)
    local parentTarget = ResolveElementParent(Page)

    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, -4, 0, 36)
    Container.BackgroundColor3 = Theme.Element
    Container.BorderSizePixel = 0
    Container.Parent = parentTarget
    local cCorner = Instance.new("UICorner") cCorner.CornerRadius = UDim.new(0, 6) cCorner.Parent = Container
    local cStroke = Instance.new("UIStroke")
    cStroke.Color = Theme.Outline
    cStroke.Thickness = 1
    cStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    cStroke.Parent = Container
    RegisterThemedObject(Container, "BackgroundColor3", "Element")
    RegisterThemedObject(cStroke, "Color", "Outline")

    local ClickBtn = Instance.new("TextButton")
    ClickBtn.Size = UDim2.new(1, 0, 1, 0)
    ClickBtn.BackgroundTransparency = 1
    ClickBtn.Text = ""
    ClickBtn.Parent = Container

    local risky = IsFeatureRisky(Name)
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -65, 1, 0)
    Label.Position = UDim2.new(0, 12, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = Name
    Label.TextColor3 = risky and Theme.Risky or Theme.Text
    Label.TextSize = 12
    Label.Font = Enum.Font.GothamMedium
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextTruncate = Enum.TextTruncate.AtEnd
    Label.Parent = Container
    if not risky then
        RegisterThemedObject(Label, "TextColor3", "Text")
    else
        RegisterThemedObject(Label, "TextColor3", "Risky")
    end

    local ToggleBg = Instance.new("Frame")
    ToggleBg.Size = UDim2.new(0, 38, 0, 20)
    ToggleBg.Position = UDim2.new(1, -48, 0.5, -10)
    ToggleBg.BackgroundColor3 = DefaultValue and Theme.Accent or Theme.Panel
    ToggleBg.BorderSizePixel = 0
    ToggleBg.Parent = Container
    local tgCorner = Instance.new("UICorner") tgCorner.CornerRadius = UDim.new(1, 0) tgCorner.Parent = ToggleBg
    local tgStroke = Instance.new("UIStroke")
    tgStroke.Color = Theme.Outline
    tgStroke.Thickness = 1
    tgStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    tgStroke.Parent = ToggleBg
    RegisterThemedObject(tgStroke, "Color", "Outline")

    local Indicator = Instance.new("Frame")
    Indicator.Size = UDim2.new(0, 14, 0, 14)
    Indicator.Position = DefaultValue and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
    Indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Indicator.BorderSizePixel = 0
    Indicator.Parent = ToggleBg
    local indCorner = Instance.new("UICorner") indCorner.CornerRadius = UDim.new(1, 0) indCorner.Parent = Indicator

    local Enabled = (DefaultValue == true)

    local function Update()
        TweenService:Create(ToggleBg, TweenInfo.new(0.2), {
            BackgroundColor3 = Enabled and Theme.Accent or Theme.Panel
        }):Play()
        TweenService:Create(Indicator, TweenInfo.new(0.2), {
            Position = Enabled and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
        }):Play()
    end

    local Controller = {
        Button = Container,
        SetVisual = function(Value)
            Enabled = Value == true
            Update()
        end
    }

    RegisterSharedToggle(SyncKey, Controller)
    RegisterStartupToggleCallback(SyncKey, Callback)

    ClickBtn.MouseButton1Click:Connect(function()
        if getgenv().Destroyed then return end
        Enabled = not Enabled
        Update()
        Callback(Enabled)

        if SyncKey and getgenv().SyncToggleVisuals then
            getgenv().SyncToggleVisuals(SyncKey, Enabled)
        end

        if getgenv().ScriptLoaded then
            CustomNotify(Name .. (Enabled and " Enabled" or " Disabled"), Enabled and Color3.fromRGB(80, 255, 120) or Color3.fromRGB(255, 80, 90))
        end

        AutoSaveConfiguration()
    end)

    Update()

    if getgenv().RegisterToxSearchControl then
        getgenv().RegisterToxSearchControl(Name, Page, Container)
    end

    return Container
end

getgenv().CreateToggleWithValue = function(Name, Page, DefaultToggle, DefaultValue, CallbackToggle, CallbackValue, SyncKey)
    local parentTarget = ResolveElementParent(Page)

    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, -4, 0, 36)
    Container.BackgroundColor3 = Theme.Element
    Container.BorderSizePixel = 0
    Container.Parent = parentTarget
    local cCorner = Instance.new("UICorner") cCorner.CornerRadius = UDim.new(0, 6) cCorner.Parent = Container
    local cStroke = Instance.new("UIStroke") cStroke.Color = Theme.Outline cStroke.Thickness = 1 cStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border cStroke.Parent = Container
    RegisterThemedObject(Container, "BackgroundColor3", "Element")
    RegisterThemedObject(cStroke, "Color", "Outline")

    local risky = IsFeatureRisky(Name)
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -135, 1, 0)
    Label.Position = UDim2.new(0, 12, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = Name
    Label.TextColor3 = risky and Theme.Risky or Theme.Text
    Label.TextSize = 12
    Label.Font = Enum.Font.GothamMedium
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextTruncate = Enum.TextTruncate.AtEnd
    Label.Parent = Container
    if not risky then RegisterThemedObject(Label, "TextColor3", "Text") else RegisterThemedObject(Label, "TextColor3", "Risky") end

    local Input = Instance.new("TextBox")
    Input.Size = UDim2.new(0, 54, 0, 22)
    Input.Position = UDim2.new(1, -114, 0.5, -11)
    Input.BackgroundColor3 = Theme.Panel
    Input.BorderSizePixel = 0
    Input.Text = tostring(DefaultValue)
    Input.TextColor3 = Theme.Text
    Input.Font = Enum.Font.GothamBold
    Input.TextSize = 11
    Input.ClearTextOnFocus = false
    Input.Parent = Container
    local inCorner = Instance.new("UICorner") inCorner.CornerRadius = UDim.new(0, 4) inCorner.Parent = Input
    local inStroke = Instance.new("UIStroke") inStroke.Color = Theme.Outline inStroke.Thickness = 1 inStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border inStroke.Parent = Input
    RegisterThemedObject(Input, "BackgroundColor3", "Panel")
    RegisterThemedObject(Input, "TextColor3", "Text")
    RegisterThemedObject(inStroke, "Color", "Outline")

    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Size = UDim2.new(0, 38, 0, 20)
    ToggleButton.Position = UDim2.new(1, -48, 0.5, -10)
    ToggleButton.BackgroundColor3 = DefaultToggle and Theme.Accent or Theme.Panel
    ToggleButton.BorderSizePixel = 0
    ToggleButton.Text = ""
    ToggleButton.AutoButtonColor = false
    ToggleButton.Parent = Container
    local tgCorner = Instance.new("UICorner") tgCorner.CornerRadius = UDim.new(1, 0) tgCorner.Parent = ToggleButton
    local tgStroke = Instance.new("UIStroke") tgStroke.Color = Theme.Outline tgStroke.Thickness = 1 tgStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border tgStroke.Parent = ToggleButton
    RegisterThemedObject(tgStroke, "Color", "Outline")

    local Indicator = Instance.new("Frame")
    Indicator.Size = UDim2.new(0, 14, 0, 14)
    Indicator.Position = DefaultToggle and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
    Indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Indicator.BorderSizePixel = 0
    Indicator.Parent = ToggleButton
    local indCorner = Instance.new("UICorner") indCorner.CornerRadius = UDim.new(1, 0) indCorner.Parent = Indicator

    local Enabled = (DefaultToggle == true)

    local function UpdateToggle()
        TweenService:Create(ToggleButton, TweenInfo.new(0.2), {
            BackgroundColor3 = Enabled and Theme.Accent or Theme.Panel
        }):Play()
        TweenService:Create(Indicator, TweenInfo.new(0.2), {
            Position = Enabled and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
        }):Play()
    end

    local Controller = {
        Button = Container,
        SetVisual = function(Value)
            Enabled = Value == true
            UpdateToggle()
        end,
        SetValue = function(Value)
            if tonumber(Value) then Input.Text = tostring(Value) end
        end
    }

    RegisterSharedToggle(SyncKey, Controller)
    RegisterSharedValue(SyncKey, Controller)
    RegisterStartupToggleCallback(SyncKey, CallbackToggle)

    ToggleButton.MouseButton1Click:Connect(function()
        if getgenv().Destroyed  then return end
        Enabled = not Enabled
        UpdateToggle()
        CallbackToggle(Enabled)

        if SyncKey and getgenv().SyncToggleVisuals then
            getgenv().SyncToggleVisuals(SyncKey, Enabled)
        end

        if getgenv().ScriptLoaded then
            CustomNotify(Name .. (Enabled and " Enabled" or " Disabled"), Enabled and Color3.fromRGB(80, 255, 120) or Color3.fromRGB(255, 80, 90))
        end

        AutoSaveConfiguration()
    end)

    Input.FocusLost:Connect(function()
        if getgenv().Destroyed  then return end
        local num = tonumber(Input.Text)
        if num then
            CallbackValue(num)
            if SyncKey and getgenv().SyncValueVisuals then
                getgenv().SyncValueVisuals(SyncKey, num)
            end
            AutoSaveConfiguration()
        else
            Input.Text = tostring(DefaultValue)
        end
    end)

    UpdateToggle()

    if getgenv().RegisterToxSearchControl then
        getgenv().RegisterToxSearchControl(Name, Page, Container)
    end

    return Container
end

getgenv().CreateToggleWithChoice = function(Name, Page, Options, DefaultToggle, DefaultChoice, CallbackToggle, CallbackChoice, SyncKey)
    local parentTarget = ResolveElementParent(Page)

    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, -4, 0, 36)
    Container.BackgroundColor3 = Theme.Element
    Container.BorderSizePixel = 0
    Container.Parent = parentTarget
    local cCorner = Instance.new("UICorner") cCorner.CornerRadius = UDim.new(0, 6) cCorner.Parent = Container
    local cStroke = Instance.new("UIStroke") cStroke.Color = Theme.Outline cStroke.Thickness = 1 cStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border cStroke.Parent = Container
    RegisterThemedObject(Container, "BackgroundColor3", "Element")
    RegisterThemedObject(cStroke, "Color", "Outline")

    local risky = IsFeatureRisky(Name)
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -170, 1, 0)
    Label.Position = UDim2.new(0, 12, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = Name
    Label.TextColor3 = risky and Theme.Risky or Theme.Text
    Label.TextSize = 12
    Label.Font = Enum.Font.GothamMedium
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextTruncate = Enum.TextTruncate.AtEnd
    Label.Parent = Container
    if not risky then RegisterThemedObject(Label, "TextColor3", "Text") else RegisterThemedObject(Label, "TextColor3", "Risky") end

    local ChoiceBtn = Instance.new("TextButton")
    ChoiceBtn.Size = UDim2.new(0, 90, 0, 22)
    ChoiceBtn.Position = UDim2.new(1, -146, 0.5, -11)
    ChoiceBtn.BackgroundColor3 = Theme.Panel
    ChoiceBtn.BorderSizePixel = 0
    ChoiceBtn.Text = tostring(DefaultChoice)
    ChoiceBtn.TextColor3 = Theme.Accent
    ChoiceBtn.Font = Enum.Font.GothamBold
    ChoiceBtn.TextSize = 11
    ChoiceBtn.Parent = Container
    local cbCorner = Instance.new("UICorner") cbCorner.CornerRadius = UDim.new(0, 4) cbCorner.Parent = ChoiceBtn
    local cbStroke = Instance.new("UIStroke") cbStroke.Color = Theme.Outline cbStroke.Thickness = 1 cbStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border cbStroke.Parent = ChoiceBtn
    RegisterThemedObject(ChoiceBtn, "BackgroundColor3", "Panel")
    RegisterThemedObject(ChoiceBtn, "TextColor3", "Accent")
    RegisterThemedObject(cbStroke, "Color", "Outline")

    local CurrentIdx = 1
    for i, opt in ipairs(Options) do
        if opt == DefaultChoice then CurrentIdx = i break end
    end

    ChoiceBtn.MouseButton1Click:Connect(function()
        if getgenv().Destroyed  then return end
        CurrentIdx = CurrentIdx + 1
        if CurrentIdx > #Options then CurrentIdx = 1 end
        ChoiceBtn.Text = tostring(Options[CurrentIdx])
        if CallbackChoice then CallbackChoice(Options[CurrentIdx]) end
        AutoSaveConfiguration()
    end)

    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Size = UDim2.new(0, 38, 0, 20)
    ToggleButton.Position = UDim2.new(1, -48, 0.5, -10)
    ToggleButton.BackgroundColor3 = DefaultToggle and Theme.Accent or Theme.Panel
    ToggleButton.BorderSizePixel = 0
    ToggleButton.Text = ""
    ToggleButton.AutoButtonColor = false
    ToggleButton.Parent = Container
    local tgCorner = Instance.new("UICorner") tgCorner.CornerRadius = UDim.new(1, 0) tgCorner.Parent = ToggleButton
    local tgStroke = Instance.new("UIStroke") tgStroke.Color = Theme.Outline tgStroke.Thickness = 1 tgStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border tgStroke.Parent = ToggleButton
    RegisterThemedObject(tgStroke, "Color", "Outline")

    local Indicator = Instance.new("Frame")
    Indicator.Size = UDim2.new(0, 14, 0, 14)
    Indicator.Position = DefaultToggle and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
    Indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Indicator.BorderSizePixel = 0
    Indicator.Parent = ToggleButton
    local indCorner = Instance.new("UICorner") indCorner.CornerRadius = UDim.new(1, 0) indCorner.Parent = Indicator

    local Enabled = (DefaultToggle == true)

    local function UpdateToggle()
        TweenService:Create(ToggleButton, TweenInfo.new(0.2), {
            BackgroundColor3 = Enabled and Theme.Accent or Theme.Panel
        }):Play()
        TweenService:Create(Indicator, TweenInfo.new(0.2), {
            Position = Enabled and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
        }):Play()
    end

    local Controller = {
        Button = Container,
        SetVisual = function(Value)
            Enabled = Value == true
            UpdateToggle()
        end,
        SetValue = function(Value)
            ChoiceBtn.Text = tostring(Value)
            for i, opt in ipairs(Options) do
                if opt == Value then CurrentIdx = i break end
            end
        end
    }

    RegisterSharedToggle(SyncKey, Controller)
    RegisterStartupToggleCallback(SyncKey, CallbackToggle)

    ToggleButton.MouseButton1Click:Connect(function()
        if getgenv().Destroyed  then return end
        Enabled = not Enabled
        UpdateToggle()
        if CallbackToggle then CallbackToggle(Enabled) end

        if SyncKey and getgenv().SyncToggleVisuals then
            getgenv().SyncToggleVisuals(SyncKey, Enabled)
        end

        if getgenv().ScriptLoaded then
            CustomNotify(Name .. (Enabled and " Enabled" or " Disabled"), Enabled and Color3.fromRGB(80, 255, 120) or Color3.fromRGB(255, 80, 90))
        end

        AutoSaveConfiguration()
    end)

    UpdateToggle()

    if getgenv().RegisterToxSearchControl then
        getgenv().RegisterToxSearchControl(Name, Page, Container)
    end

    return Container
end

getgenv().CreateInputWithButton = function(Name, Page, DefaultText, ButtonText, Callback)
    local parentTarget = ResolveElementParent(Page)

    local Box = Instance.new("Frame")
    Box.Size = UDim2.new(1, -4, 0, 42)
    Box.BackgroundColor3 = Theme.Element
    Box.BorderSizePixel = 0
    Box.Parent = parentTarget
    local bCorner = Instance.new("UICorner") bCorner.CornerRadius = UDim.new(0, 6) bCorner.Parent = Box
    local bStroke = Instance.new("UIStroke") bStroke.Color = Theme.Outline bStroke.Thickness = 1 bStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border bStroke.Parent = Box
    RegisterThemedObject(Box, "BackgroundColor3", "Element")
    RegisterThemedObject(bStroke, "Color", "Outline")

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -165, 1, 0)
    Label.Position = UDim2.new(0, 12, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = Name
    Label.TextColor3 = Theme.Text
    Label.TextSize = 12
    Label.Font = Enum.Font.GothamMedium
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Box
    RegisterThemedObject(Label, "TextColor3", "Text")

    local Input = Instance.new("TextBox")
    Input.Size = UDim2.new(0, 85, 0, 24)
    Input.Position = UDim2.new(1, -150, 0.5, -12)
    Input.BackgroundColor3 = Theme.Panel
    Input.BorderSizePixel = 0
    Input.Text = DefaultText or ""
    Input.PlaceholderText = "Text..."
    Input.TextColor3 = Theme.Text
    Input.PlaceholderColor3 = Theme.DimText
    Input.TextSize = 11
    Input.Font = Enum.Font.Gotham
    Input.ClearTextOnFocus = false
    Input.Parent = Box
    local inCorner = Instance.new("UICorner") inCorner.CornerRadius = UDim.new(0, 4) inCorner.Parent = Input
    local inStroke = Instance.new("UIStroke") inStroke.Color = Theme.Outline inStroke.Thickness = 1 inStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border inStroke.Parent = Input
    RegisterThemedObject(Input, "BackgroundColor3", "Panel")
    RegisterThemedObject(Input, "TextColor3", "Text")
    RegisterThemedObject(inStroke, "Color", "Outline")

    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(0, 58, 0, 24)
    Button.Position = UDim2.new(1, -62, 0.5, -12)
    Button.BackgroundColor3 = Theme.Accent
    Button.BorderSizePixel = 0
    Button.Text = ButtonText or "Set"
    Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    Button.TextSize = 11
    Button.Font = Enum.Font.GothamBold
    Button.Parent = Box
    local btnCorner = Instance.new("UICorner") btnCorner.CornerRadius = UDim.new(0, 4) btnCorner.Parent = Button
    RegisterThemedObject(Button, "BackgroundColor3", "Accent")

    Button.MouseButton1Click:Connect(function()
        if getgenv().Destroyed  then return end
        Callback(Input.Text)
    end)

    if getgenv().RegisterToxSearchControl then
        getgenv().RegisterToxSearchControl(Name, Page, Box)
    end

    return Box
end

getgenv().CreateInputWithTwoButtons = function(Name, Page, DefaultText, Btn1Text, Btn2Text, Callback)
    local parentTarget = ResolveElementParent(Page)

    local Box = Instance.new("Frame")
    Box.Size = UDim2.new(1, -4, 0, 42)
    Box.BackgroundColor3 = Theme.Element
    Box.BorderSizePixel = 0
    Box.Parent = parentTarget
    local bCorner = Instance.new("UICorner") bCorner.CornerRadius = UDim.new(0, 6) bCorner.Parent = Box
    local bStroke = Instance.new("UIStroke") bStroke.Color = Theme.Outline bStroke.Thickness = 1 bStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border bStroke.Parent = Box
    RegisterThemedObject(Box, "BackgroundColor3", "Element")
    RegisterThemedObject(bStroke, "Color", "Outline")

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -200, 1, 0)
    Label.Position = UDim2.new(0, 12, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = Name
    Label.TextColor3 = Theme.Text
    Label.TextSize = 12
    Label.Font = Enum.Font.GothamMedium
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Box
    RegisterThemedObject(Label, "TextColor3", "Text")

    local Input = Instance.new("TextBox")
    Input.Size = UDim2.new(0, 75, 0, 24)
    Input.Position = UDim2.new(1, -188, 0.5, -12)
    Input.BackgroundColor3 = Theme.Panel
    Input.BorderSizePixel = 0
    Input.Text = DefaultText or ""
    Input.PlaceholderText = "Text..."
    Input.TextColor3 = Theme.Text
    Input.TextSize = 11
    Input.Font = Enum.Font.Gotham
    Input.ClearTextOnFocus = false
    Input.Parent = Box
    local inCorner = Instance.new("UICorner") inCorner.CornerRadius = UDim.new(0, 4) inCorner.Parent = Input
    local inStroke = Instance.new("UIStroke") inStroke.Color = Theme.Outline inStroke.Thickness = 1 inStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border inStroke.Parent = Input
    RegisterThemedObject(Input, "BackgroundColor3", "Panel")
    RegisterThemedObject(Input, "TextColor3", "Text")
    RegisterThemedObject(inStroke, "Color", "Outline")

    local Button1 = Instance.new("TextButton")
    Button1.Size = UDim2.new(0, 50, 0, 24)
    Button1.Position = UDim2.new(1, -110, 0.5, -12)
    Button1.BackgroundColor3 = Theme.Accent
    Button1.BorderSizePixel = 0
    Button1.Text = Btn1Text
    Button1.TextColor3 = Color3.fromRGB(255, 255, 255)
    Button1.TextSize = 11
    Button1.Font = Enum.Font.GothamBold
    Button1.Parent = Box
    local b1Corner = Instance.new("UICorner") b1Corner.CornerRadius = UDim.new(0, 4) b1Corner.Parent = Button1
    RegisterThemedObject(Button1, "BackgroundColor3", "Accent")

    local Button2 = Instance.new("TextButton")
    Button2.Size = UDim2.new(0, 56, 0, 24)
    Button2.Position = UDim2.new(1, -58, 0.5, -12)
    Button2.BackgroundColor3 = Theme.Panel
    Button2.BorderSizePixel = 0
    Button2.Text = Btn2Text
    Button2.TextColor3 = Theme.Text
    Button2.TextSize = 11
    Button2.Font = Enum.Font.GothamBold
    Button2.Parent = Box
    local b2Corner = Instance.new("UICorner") b2Corner.CornerRadius = UDim.new(0, 4) b2Corner.Parent = Button2
    local b2Stroke = Instance.new("UIStroke") b2Stroke.Color = Theme.Outline b2Stroke.Thickness = 1 b2Stroke.Parent = Button2
    RegisterThemedObject(Button2, "BackgroundColor3", "Panel")
    RegisterThemedObject(Button2, "TextColor3", "Text")
    RegisterThemedObject(b2Stroke, "Color", "Outline")

    Button1.MouseButton1Click:Connect(function()
        if getgenv().Destroyed  then return end
        Callback(Input.Text, "TP")
    end)

    Button2.MouseButton1Click:Connect(function()
        if getgenv().Destroyed  then return end
        Callback(Input.Text, "LOOP")
    end)

    if getgenv().RegisterToxSearchControl then
        getgenv().RegisterToxSearchControl(Name, Page, Box)
    end

    return Box
end

getgenv().CreateDropdown = function(Name, Options, Page, DefaultOption, Callback)
    local parentTarget = ResolveElementParent(Page)

    local Box = Instance.new("Frame")
    Box.Size = UDim2.new(1, -4, 0, 36)
    Box.BackgroundColor3 = Theme.Element
    Box.BorderSizePixel = 0
    Box.Parent = parentTarget
    local bCorner = Instance.new("UICorner") bCorner.CornerRadius = UDim.new(0, 6) bCorner.Parent = Box
    local bStroke = Instance.new("UIStroke") bStroke.Color = Theme.Outline bStroke.Thickness = 1 bStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border bStroke.Parent = Box
    RegisterThemedObject(Box, "BackgroundColor3", "Element")
    RegisterThemedObject(bStroke, "Color", "Outline")

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -115, 1, 0)
    Label.Position = UDim2.new(0, 12, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = Name
    Label.TextColor3 = Theme.Text
    Label.TextSize = 12
    Label.Font = Enum.Font.GothamMedium
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Box
    RegisterThemedObject(Label, "TextColor3", "Text")

    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(0, 95, 0, 24)
    Button.Position = UDim2.new(1, -105, 0.5, -12)
    Button.BackgroundColor3 = Theme.Panel
    Button.BorderSizePixel = 0
    Button.Text = tostring(DefaultOption) .. "  ▼"
    Button.TextColor3 = Theme.Accent
    Button.TextSize = 11
    Button.Font = Enum.Font.GothamBold
    Button.Parent = Box
    local btnCorner = Instance.new("UICorner") btnCorner.CornerRadius = UDim.new(0, 4) btnCorner.Parent = Button
    local btnStroke = Instance.new("UIStroke") btnStroke.Color = Theme.Outline btnStroke.Thickness = 1 btnStroke.Parent = Button
    RegisterThemedObject(Button, "BackgroundColor3", "Panel")
    RegisterThemedObject(Button, "TextColor3", "Accent")
    RegisterThemedObject(btnStroke, "Color", "Outline")

    local CurrentIdx = 1
    for i, opt in ipairs(Options) do
        if opt == DefaultOption then CurrentIdx = i break end
    end

    Button.MouseButton1Click:Connect(function()
        if getgenv().Destroyed  then return end
        CurrentIdx = CurrentIdx + 1
        if CurrentIdx > #Options then CurrentIdx = 1 end
        Button.Text = tostring(Options[CurrentIdx]) .. "  ▼"
        Callback(Options[CurrentIdx])
        AutoSaveConfiguration()
    end)

    if getgenv().RegisterToxSearchControl then
        getgenv().RegisterToxSearchControl(Name, Page, Box, Options)
    end

    return Box
end

getgenv().CreateButton = function(Name, Page, Callback)
    local parentTarget = ResolveElementParent(Page)

    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, -4, 0, 36)
    Button.BackgroundColor3 = Theme.Element
    Button.BorderSizePixel = 0
    Button.Text = Name
    Button.TextColor3 = Theme.Text
    Button.TextSize = 12
    Button.Font = Enum.Font.GothamMedium
    Button.Parent = parentTarget
    local Corner = Instance.new("UICorner") Corner.CornerRadius = UDim.new(0, 6) Corner.Parent = Button
    local Stroke = Instance.new("UIStroke") Stroke.Color = Theme.Outline Stroke.Thickness = 1 Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border Stroke.Parent = Button
    RegisterThemedObject(Button, "BackgroundColor3", "Element")
    RegisterThemedObject(Button, "TextColor3", "Text")
    RegisterThemedObject(Stroke, "Color", "Outline")

    Button.MouseButton1Click:Connect(function()
        if getgenv().Destroyed  then return end
        Callback(Button)
    end)

    if getgenv().RegisterToxSearchControl then
        getgenv().RegisterToxSearchControl(Name, Page, Button)
    end

    return Button
end

getgenv().CreateConfirmButton = function(Name, Page, Callback)
    local parentTarget = ResolveElementParent(Page)

    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, -4, 0, 36)
    Button.BackgroundColor3 = Theme.Element
    Button.BorderSizePixel = 0
    Button.Text = Name
    Button.TextColor3 = Theme.Text
    Button.TextSize = 12
    Button.Font = Enum.Font.GothamMedium
    Button.Parent = parentTarget
    local Corner = Instance.new("UICorner") Corner.CornerRadius = UDim.new(0, 6) Corner.Parent = Button
    local Stroke = Instance.new("UIStroke") Stroke.Color = Theme.Outline Stroke.Thickness = 1 Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border Stroke.Parent = Button
    RegisterThemedObject(Button, "BackgroundColor3", "Element")
    RegisterThemedObject(Button, "TextColor3", "Text")
    RegisterThemedObject(Stroke, "Color", "Outline")

    local Confirming = false

    Button.MouseButton1Click:Connect(function()
        if getgenv().Destroyed  then return end
        if not Confirming then
            Confirming = true
            Button.Text = "CONFIRM " .. string.upper(Name) .. "? (Click Again)"
            Button.BackgroundColor3 = Theme.Risky
            task.delay(3.5, function()
                if not getgenv().Destroyed and Confirming then
                    Confirming = false
                    Button.Text = Name
                    Button.BackgroundColor3 = Theme.Element
                end
            end)
        else
            Confirming = false
            Button.Text = Name
            Button.BackgroundColor3 = Theme.Element
            Callback(Button)
        end
    end)

    if getgenv().RegisterToxSearchControl then
        getgenv().RegisterToxSearchControl(Name, Page, Button)
    end

    return Button
end

getgenv().CreateKeybindButton = function(Name, Page, DefaultKey, Callback)
    local parentTarget = ResolveElementParent(Page)

    local Box = Instance.new("Frame")
    Box.Size = UDim2.new(1, -4, 0, 36)
    Box.BackgroundColor3 = Theme.Element
    Box.BorderSizePixel = 0
    Box.Parent = parentTarget
    local bCorner = Instance.new("UICorner") bCorner.CornerRadius = UDim.new(0, 6) bCorner.Parent = Box
    local bStroke = Instance.new("UIStroke") bStroke.Color = Theme.Outline bStroke.Thickness = 1 bStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border bStroke.Parent = Box
    RegisterThemedObject(Box, "BackgroundColor3", "Element")
    RegisterThemedObject(bStroke, "Color", "Outline")

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -110, 1, 0)
    Label.Position = UDim2.new(0, 12, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = Name
    Label.TextColor3 = Theme.Text
    Label.TextSize = 12
    Label.Font = Enum.Font.GothamMedium
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Box
    RegisterThemedObject(Label, "TextColor3", "Text")

    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(0, 85, 0, 24)
    Button.Position = UDim2.new(1, -95, 0.5, -12)
    Button.BackgroundColor3 = Theme.Panel
    Button.BorderSizePixel = 0
    local defaultKeyText = "NONE"
    if typeof(DefaultKey) == "EnumItem" or (type(DefaultKey) == "table" and DefaultKey.Name) then
        defaultKeyText = tostring(DefaultKey.Name)
    elseif type(DefaultKey) == "string" and DefaultKey ~= "" then
        defaultKeyText = DefaultKey
    end
    Button.Text = defaultKeyText
    Button.TextColor3 = Theme.Accent
    Button.TextSize = 11
    Button.Font = Enum.Font.GothamBold
    Button.Parent = Box
    local btnCorner = Instance.new("UICorner") btnCorner.CornerRadius = UDim.new(0, 4) btnCorner.Parent = Button
    local btnStroke = Instance.new("UIStroke") btnStroke.Color = Theme.Outline btnStroke.Thickness = 1 btnStroke.Parent = Button
    RegisterThemedObject(Button, "BackgroundColor3", "Panel")
    RegisterThemedObject(Button, "TextColor3", "Accent")
    RegisterThemedObject(btnStroke, "Color", "Outline")

    local Binding = false
    local CurrentKey = DefaultKey

    Button.MouseButton1Click:Connect(function()
        if getgenv().ToxOptionsReady == false or Binding then return end
        Binding = true
        Button.Text = "Press Key..."

        local conn
        conn = UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Keyboard then
                conn:Disconnect()
                Binding = false
                if input.KeyCode == Enum.KeyCode.Escape then
                    CurrentKey = nil
                    Button.Text = "NONE"
                else
                    CurrentKey = input.KeyCode
                    Button.Text = input.KeyCode.Name
                end
                Callback(CurrentKey)
                if getgenv().AutoSaveConfiguration then getgenv().AutoSaveConfiguration() end
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 then
                conn:Disconnect()
                Binding = false
                CurrentKey = nil
                Button.Text = "NONE"
                Callback(nil)
                if getgenv().AutoSaveConfiguration then getgenv().AutoSaveConfiguration() end
            end
        end)
    end)

    if getgenv().RegisterToxSearchControl then
        getgenv().RegisterToxSearchControl(Name, Page, Box)
    end

    return Box
end

getgenv().CreateKeybindToggle = function(Name, Page, DefaultKey, DefaultToggle, KeyCallback, ToggleCallback, SyncKey)
    local parentTarget = ResolveElementParent(Page)

    local Box = Instance.new("Frame")
    Box.Size = UDim2.new(1, -4, 0, 36)
    Box.BackgroundColor3 = Theme.Element
    Box.BorderSizePixel = 0
    Box.Parent = parentTarget
    local bCorner = Instance.new("UICorner") bCorner.CornerRadius = UDim.new(0, 6) bCorner.Parent = Box
    local bStroke = Instance.new("UIStroke") bStroke.Color = Theme.Outline bStroke.Thickness = 1 bStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border bStroke.Parent = Box
    RegisterThemedObject(Box, "BackgroundColor3", "Element")
    RegisterThemedObject(bStroke, "Color", "Outline")

    local risky = IsFeatureRisky(Name)
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -150, 1, 0)
    Label.Position = UDim2.new(0, 12, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = Name
    Label.TextColor3 = risky and Theme.Risky or Theme.Text
    Label.TextSize = 12
    Label.Font = Enum.Font.GothamMedium
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Box
    if not risky then RegisterThemedObject(Label, "TextColor3", "Text") else RegisterThemedObject(Label, "TextColor3", "Risky") end

    local KeyButton = Instance.new("TextButton")
    KeyButton.Size = UDim2.new(0, 60, 0, 22)
    KeyButton.Position = UDim2.new(1, -118, 0.5, -11)
    KeyButton.BackgroundColor3 = Theme.Panel
    KeyButton.BorderSizePixel = 0
    local defaultKeyText = "NONE"
    if typeof(DefaultKey) == "EnumItem" or (type(DefaultKey) == "table" and DefaultKey.Name) then
        defaultKeyText = tostring(DefaultKey.Name)
    elseif type(DefaultKey) == "string" and DefaultKey ~= "" then
        defaultKeyText = DefaultKey
    end
    KeyButton.Text = defaultKeyText
    KeyButton.TextColor3 = Theme.DimText
    KeyButton.TextSize = 10
    KeyButton.Font = Enum.Font.GothamBold
    KeyButton.Parent = Box
    local kbCorner = Instance.new("UICorner") kbCorner.CornerRadius = UDim.new(0, 4) kbCorner.Parent = KeyButton
    local kbStroke = Instance.new("UIStroke") kbStroke.Color = Theme.Outline kbStroke.Thickness = 1 kbStroke.Parent = KeyButton
    RegisterThemedObject(KeyButton, "BackgroundColor3", "Panel")
    RegisterThemedObject(KeyButton, "TextColor3", "DimText")
    RegisterThemedObject(kbStroke, "Color", "Outline")

    local Toggle = Instance.new("TextButton")
    Toggle.Size = UDim2.new(0, 38, 0, 20)
    Toggle.Position = UDim2.new(1, -48, 0.5, -10)
    Toggle.BackgroundColor3 = DefaultToggle and Theme.Accent or Theme.Panel
    Toggle.BorderSizePixel = 0
    Toggle.Text = ""
    Toggle.AutoButtonColor = false
    Toggle.Parent = Box
    local tgCorner = Instance.new("UICorner") tgCorner.CornerRadius = UDim.new(1, 0) tgCorner.Parent = Toggle
    local tgStroke = Instance.new("UIStroke") tgStroke.Color = Theme.Outline tgStroke.Thickness = 1 tgStroke.Parent = Toggle
    RegisterThemedObject(tgStroke, "Color", "Outline")

    local Indicator = Instance.new("Frame")
    Indicator.Size = UDim2.new(0, 14, 0, 14)
    Indicator.Position = DefaultToggle and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
    Indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Indicator.BorderSizePixel = 0
    Indicator.Parent = Toggle
    local indCorner = Instance.new("UICorner") indCorner.CornerRadius = UDim.new(1, 0) indCorner.Parent = Indicator

    local Binding = false
    local CurrentKey = DefaultKey
    local Enabled = (DefaultToggle == true)

    local function UpdateToggle()
        TweenService:Create(Toggle, TweenInfo.new(0.2), {
            BackgroundColor3 = Enabled and Theme.Accent or Theme.Panel
        }):Play()
        TweenService:Create(Indicator, TweenInfo.new(0.2), {
            Position = Enabled and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
        }):Play()
    end

    local Controller = {
        Button = Box,
        SetVisual = function(Value)
            Enabled = Value == true
            UpdateToggle()
        end
    }

    RegisterSharedToggle(SyncKey, Controller)
    RegisterStartupToggleCallback(SyncKey, ToggleCallback)

    KeyButton.MouseButton1Click:Connect(function()
        if Destroyed  or Binding then return end
        Binding = true
        KeyButton.Text = "..."
        local conn
        conn = UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Keyboard then
                conn:Disconnect()
                Binding = false
                if input.KeyCode == Enum.KeyCode.Escape then
                    CurrentKey = nil
                    KeyButton.Text = "NONE"
                else
                    CurrentKey = input.KeyCode
                    KeyButton.Text = input.KeyCode.Name
                end
                KeyCallback(CurrentKey)
                AutoSaveConfiguration()
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 then
                conn:Disconnect()
                Binding = false
                CurrentKey = nil
                KeyButton.Text = "NONE"
                KeyCallback(nil)
                AutoSaveConfiguration()
            end
        end)
    end)

    Toggle.MouseButton1Click:Connect(function()
        if getgenv().Destroyed  then return end
        Enabled = not Enabled
        UpdateToggle()
        ToggleCallback(Enabled)

        if SyncKey and getgenv().SyncToggleVisuals then
            getgenv().SyncToggleVisuals(SyncKey, Enabled)
        end

        AutoSaveConfiguration()
        if getgenv().ScriptLoaded then
            CustomNotify(Name .. " Auto " .. (Enabled and "Enabled" or "Disabled"), Enabled and Color3.fromRGB(80, 255, 120) or Color3.fromRGB(255, 80, 90))
        end
    end)

    UpdateToggle()

    if getgenv().RegisterToxSearchControl then
        getgenv().RegisterToxSearchControl(Name, Page, Box)
    end

    return Box
end



local function ApplyStagedOptionsAfterLoadScreen()
    local staged = getgenv().ToxStartupBooleanState
    local callbacks = getgenv().ToxStartupToggleCallbacks

    if type(staged) == "table" and type(callbacks) == "table" then
        for key, value in pairs(staged) do
            if value == true and type(callbacks[key]) == "function" then
                pcall(callbacks[key], true)
            end
        end
    end

    getgenv().ToxStartupBooleanState = nil
    getgenv().ToxStartupToggleCallbacks = nil
end

task.spawn(function()
    while not getgenv().Destroyed and not getgenv().ScriptLoaded do
        task.wait(0.03)
    end

    if getgenv().Destroyed then
        return
    end

    ApplyStagedOptionsAfterLoadScreen()
end)
