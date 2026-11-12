local env = getgenv()
if env.Destroyed then return end
local UI = env.ToxUI or {}
env.ToxUI = UI

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Player = Players.LocalPlayer
local Settings = env.Settings or {}
local Theme = env.Theme or UI.Theme or {}
local LOGO_ID = env.LOGO_ID or "rbxassetid://120675082996894"

local RegisterThemedObject = env.RegisterThemedObject or UI.RegisterThemedObject or function() end
local ApplyTheme = env.ApplyToxTheme or UI.ApplyTheme or function() end
local MakeDraggable = function(...) if env.MakeDraggable then return env.MakeDraggable(...) end end
local CustomNotify = function(...) if env.CustomNotify then return env.CustomNotify(...) end end
local AutoSaveConfiguration = function(...) if env.AutoSaveConfiguration then return env.AutoSaveConfiguration(...) end end

local Gui = UI.Gui or env.Gui
local Main = UI.Main or env.Main
local DimmerFrame = UI.DimmerFrame or env.DimmerFrame
local PagesContainer = UI.PagesContainer
local SidebarScroll = UI.SidebarScroll or env.Tabs
local SearchTextBox = UI.SearchTextBox
local SearchResultsScroll = UI.SearchResultsScroll
local CurrentTabTitle = UI.CurrentTabTitle
local WeatherContainer = UI.WeatherContainer
local ScreenWeatherGui = UI.ScreenWeatherGui
local isSidebarCollapsed = UI.IsSidebarCollapsed and UI.IsSidebarCollapsed() or (Settings.CollapseSidebar == true)
local WatermarkFrame = nil
local WatermarkLabel = nil
local SetWeatherType = nil
local OpenColorPicker = nil
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
    if type(Page) == "string" and typeof(Title) == "Instance" then
        Page, Title = Title, Page
    end
    if typeof(Page) ~= "Instance" then
        return nil
    end
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
    Card.BackgroundTransparency = 0.2
    Card.BorderSizePixel = 0
    Card.LayoutOrder = currentOrder
    Card.ZIndex = 7
    Card.Parent = Page
    RegisterThemedObject(Card, "BackgroundColor3", "Panel")
    local CardCorner = Instance.new("UICorner")
    CardCorner.CornerRadius = UDim.new(0, 10)
    CardCorner.Parent = Card
    local CardStroke = Instance.new("UIStroke")
    CardStroke.Color = Theme.Outline
    CardStroke.Thickness = 1
    CardStroke.Transparency = 0.55
    CardStroke.Parent = Card
    RegisterThemedObject(CardStroke, "Color", "Outline")
    local CardLayout = Instance.new("UIListLayout")
    CardLayout.SortOrder = Enum.SortOrder.LayoutOrder
    CardLayout.Padding = UDim.new(0, 0)
    CardLayout.Parent = Card
    local Header = Instance.new("Frame")
    Header.Name = "Header"
    Header.LayoutOrder = 1
    Header.Size = UDim2.new(1, 0, 0, 34)
    Header.BackgroundTransparency = 1
    Header.ZIndex = 8
    Header.Parent = Card
    local AccentBar = Instance.new("Frame")
    AccentBar.Name = "AccentBar"
    AccentBar.Size = UDim2.new(0, 3, 0, 14)
    AccentBar.Position = UDim2.new(0, 12, 0.5, -7)
    AccentBar.BackgroundColor3 = Theme.Accent
    AccentBar.BorderSizePixel = 0
    AccentBar.ZIndex = 9
    AccentBar.Parent = Header
    local BarCorner = Instance.new("UICorner") BarCorner.CornerRadius = UDim.new(0, 2) BarCorner.Parent = AccentBar
    RegisterThemedObject(AccentBar, "BackgroundColor3", "Accent")
    local IconLabel = Instance.new("TextLabel")
    IconLabel.Name = "Icon"
    IconLabel.Size = UDim2.new(0, 20, 1, 0)
    IconLabel.Position = UDim2.new(0, 20, 0, 0)
    IconLabel.BackgroundTransparency = 1
    IconLabel.Text = Icon or ""
    IconLabel.TextColor3 = Theme.Accent
    IconLabel.Font = Enum.Font.GothamBold
    IconLabel.TextSize = 13
    IconLabel.ZIndex = 9
    IconLabel.Parent = Header
    RegisterThemedObject(IconLabel, "TextColor3", "Accent")
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Name = "Title"
    TitleLabel.Size = UDim2.new(1, -50, 1, 0)
    TitleLabel.Position = UDim2.new(0, (Icon and Icon ~= "") and 44 or 24, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = Title
    TitleLabel.TextColor3 = Theme.Text
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextSize = 13
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.ZIndex = 9
    TitleLabel.Parent = Header
    RegisterThemedObject(TitleLabel, "TextColor3", "Text")

    local Content = Instance.new("Frame")
    Content.Name = "Content"
    Content.LayoutOrder = 2
    Content.Size = UDim2.new(1, 0, 0, 0)
    Content.AutomaticSize = Enum.AutomaticSize.Y
    Content.BackgroundTransparency = 1
    Content.ZIndex = 8
    Content.Parent = Card
    local ContentLayout = Instance.new("UIListLayout")
    ContentLayout.Padding = UDim.new(0, 6)
    ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ContentLayout.Parent = Content
    local ContentPadding = Instance.new("UIPadding")
    ContentPadding.PaddingLeft = UDim.new(0, 10)
    ContentPadding.PaddingRight = UDim.new(0, 10)
    ContentPadding.PaddingBottom = UDim.new(0, 12)
    ContentPadding.Parent = Content

    table.insert(CardRegistry, Card)
    return Card
end
getgenv().CreateCard = CreateCard
local ActivePageCards = {}
local function ClearActivePageCard(Page)
    if Page then
        ActivePageCards[Page] = nil
    end
end
getgenv().ClearActivePageCard = ClearActivePageCard
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
        if activeCard and activeCard.Parent and activeCard:FindFirstChild("Content") then
            return activeCard.Content
        end
    end
    return Page
end
getgenv().ResolveElementParent = ResolveElementParent
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
local HomePage = CreatePage("HOME")
local function GetOrDetectGameModule()
    if getgenv().CurrentGameModule and getgenv().CurrentGameModule.Ready then
        return getgenv().CurrentGameModule
    end
    if getgenv().ResolveCurrentGameModule then
        local detected = getgenv().ResolveCurrentGameModule()
        if detected then
            getgenv().CurrentGameModule = detected
            return detected
        end
    end
    local reg = getgenv().GameModuleRegistry or {}
    local pStr = tostring(game.PlaceId or "")
    local gStr = tostring(game.GameId or "")
    for k, v in pairs(reg) do
        local kStr = tostring(k)
        if (pStr ~= "" and pStr ~= "0" and kStr == pStr) or (gStr ~= "" and gStr ~= "0" and kStr == gStr) then
            getgenv().CurrentGameModule = v
            return v
        end
    end
    return nil
end
local DetectedGameModule = GetOrDetectGameModule()
local GamePage = nil
if DetectedGameModule and DetectedGameModule.Ready then
    GamePage = CreatePage(DetectedGameModule.ShortName or "Game")
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
    BtnCorner.CornerRadius = UDim.new(0, 8)
    BtnCorner.Parent = Button
    local BtnStroke = Instance.new("UIStroke")
    BtnStroke.Color = Theme.Accent
    BtnStroke.Thickness = 1
    BtnStroke.Transparency = 1
    BtnStroke.Parent = Button
    local IndicatorBar = Instance.new("Frame")
    IndicatorBar.Name = "IndicatorBar"
    IndicatorBar.Size = UDim2.new(0, 3, 0.6, 0)
    IndicatorBar.Position = UDim2.new(0, 2, 0.2, 0)
    IndicatorBar.BackgroundColor3 = Theme.Accent
    IndicatorBar.BorderSizePixel = 0
    IndicatorBar.Visible = false
    IndicatorBar.ZIndex = 13
    IndicatorBar.Parent = Button
    local IndCorner = Instance.new("UICorner") IndCorner.CornerRadius = UDim.new(0, 2) IndCorner.Parent = IndicatorBar
    RegisterThemedObject(IndicatorBar, "BackgroundColor3", "Accent")
    local IconLabel = Instance.new("TextLabel")
    IconLabel.Name = "ButtonIcon"
    IconLabel.Size = UDim2.new(0, 20, 0, 20)
    local _col = (UI.IsSidebarCollapsed and UI.IsSidebarCollapsed()) or (Settings.CollapseSidebar == true); IconLabel.Position = UDim2.new(0, _col and 12 or 10, 0.5, -10)
    IconLabel.BackgroundTransparency = 1
    IconLabel.Text = iconText or "🔹"
    IconLabel.TextColor3 = Theme.DimText
    IconLabel.Font = Enum.Font.GothamBold
    IconLabel.TextSize = 13
    IconLabel.ZIndex = 13
    IconLabel.Parent = Button
    RegisterThemedObject(IconLabel, "TextColor3", "DimText")
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
    TextLabel.Visible = not ((UI.IsSidebarCollapsed and UI.IsSidebarCollapsed()) or (Settings.CollapseSidebar == true))
    TextLabel.ZIndex = 13
    TextLabel.Parent = Button
    RegisterThemedObject(TextLabel, "TextColor3", "DimText")
    local function SetActive(active)
        IndicatorBar.Visible = active
        if active then
            TweenService:Create(Button, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundTransparency = 0,
                BackgroundColor3 = Theme.Element
            }):Play()
            BtnStroke.Transparency = 0.65
            BtnStroke.Color = Theme.Accent
            IconLabel.TextColor3 = Theme.Accent
            TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            TextLabel.Font = Enum.Font.GothamBold
        else
            TweenService:Create(Button, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundTransparency = 1,
                BackgroundColor3 = Theme.Hover
            }):Play()
            BtnStroke.Transparency = 1
            IconLabel.TextColor3 = Theme.DimText
            TextLabel.TextColor3 = Theme.DimText
            TextLabel.Font = Enum.Font.GothamMedium
        end
    end
    Button.MouseEnter:Connect(function()
        if CurrentActivePage ~= page then
            TweenService:Create(Button, TweenInfo.new(0.15), {
                BackgroundTransparency = 0.5,
                BackgroundColor3 = Theme.Hover
            }):Play()
            TextLabel.TextColor3 = Color3.fromRGB(240, 245, 255)
        end
    end)
    Button.MouseLeave:Connect(function()
        if CurrentActivePage ~= page then
            TweenService:Create(Button, TweenInfo.new(0.15), {
                BackgroundTransparency = 1
            }):Play()
            TextLabel.TextColor3 = Theme.DimText
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
CreateSidebarNavButton("Home", "🏠", HomePage, 1)
local function CreateOrGetGameNavButton(targetModule, targetPage)
    if not targetModule or not targetPage then return end
    local gameLabel = targetModule.ShortName or "Game"
    return CreateSidebarNavButton(gameLabel, "🎮", targetPage, 2)
end

if GamePage and DetectedGameModule then
    CreateOrGetGameNavButton(DetectedGameModule, GamePage)
end

getgenv().ToxPageNamesByPage = getgenv().ToxPageNamesByPage or {}
getgenv().EnsureGameTabCreated = function(moduleData)
    moduleData = moduleData or GetOrDetectGameModule()
    if not moduleData or not moduleData.Ready then return nil end
    getgenv().CurrentGameModule = moduleData
    getgenv().ToxPageNamesByPage = getgenv().ToxPageNamesByPage or {}
    
    local page = getgenv().GamePage
    if not page then
        local shortName = moduleData.ShortName or "Game"
        page = CreatePage(shortName)
        getgenv().GamePage = page
        getgenv().ToxPageNamesByPage[page] = shortName
    end
    if page and not SidebarNavButtons[page] then
        CreateOrGetGameNavButton(moduleData, page)
    end
    if getgenv().UpdateHomePinnedGameOption then
        pcall(getgenv().UpdateHomePinnedGameOption, moduleData)
    end
    return getgenv().GamePage
end

task.spawn(function()
    for _ = 1, 30 do
        if getgenv().Destroyed then break end
        local mod = GetOrDetectGameModule()
        if mod and mod.Ready then
            local p = getgenv().GamePage
            if not p or not SidebarNavButtons[p] then
                pcall(function()
                    getgenv().EnsureGameTabCreated(mod)
                end)
            end
            break
        end
        task.wait(0.25)
    end
end)
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
local function ToxOpenPage(targetPage)
    if not targetPage then return end
    if getgenv().CloseToxDropdownOverlay then
        pcall(getgenv().CloseToxDropdownOverlay)
    end
    for _, p in pairs(Pages) do
        p.Visible = false
    end
    targetPage.Visible = true
    CurrentActivePage = targetPage
    getgenv().CurrentPage = targetPage
    local pageTitle = getgenv().ToxPageNamesByPage[targetPage] or targetPage.Name
    CurrentTabTitle.Text = pageTitle
    if env.ToxGameTagText and env.ToxGameTagText.Parent then
        if targetPage == GamePage and DetectedGameModule then
            env.ToxGameTagText.Text = DetectedGameModule.ShortName or "Game"
        elseif DetectedGameModule and DetectedGameModule.Ready then
            env.ToxGameTagText.Text = DetectedGameModule.ShortName or "Game"
        else
            env.ToxGameTagText.Text = pageTitle
        end
    end
    for page, navData in pairs(SidebarNavButtons) do
        navData.SetActive(page == targetPage)
    end
    if getgenv().ToxChatGui and getgenv().ToxChatGui.Parent then
        getgenv().ToxChatGui.Visible = (targetPage == ChatPage)
    end
    if getgenv().ToxControlGui and getgenv().ToxControlGui.Parent then
        getgenv().ToxControlGui.Visible = (targetPage == ControlPage)
    end
    if targetPage == JoinPage and getgenv().RefreshQuickJoinGames then
        pcall(getgenv().RefreshQuickJoinGames)
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
local MobileToggleBtn = Instance.new("ImageButton")
MobileToggleBtn.Name = "ToxMobileToggle"
MobileToggleBtn.Size = UDim2.new(0, 46, 0, 46)
MobileToggleBtn.Position = UDim2.new(1, -60, 0.5, -23)
MobileToggleBtn.BackgroundColor3 = Theme.Panel
MobileToggleBtn.BorderSizePixel = 0
MobileToggleBtn.Image = (Settings.CustomIconUrl and Settings.CustomIconUrl ~= "") and Settings.CustomIconUrl or LOGO_ID
MobileToggleBtn.Visible = false
MobileToggleBtn.ZIndex = 999999
MobileToggleBtn.Parent = Gui
local MobileCorner = Instance.new("UICorner") MobileCorner.CornerRadius = UDim.new(1, 0) MobileCorner.Parent = MobileToggleBtn
local MobileStroke = Instance.new("UIStroke") MobileStroke.Color = Theme.Accent MobileStroke.Thickness = 1 MobileStroke.Transparency = 0.2 MobileStroke.Parent = MobileToggleBtn
RegisterThemedObject(MobileToggleBtn, "BackgroundColor3", "Panel")
RegisterThemedObject(MobileStroke, "Color", "Accent")
MakeDraggable(MobileToggleBtn, MobileToggleBtn)
if getgenv().ApplySavedGuiPosition then getgenv().ApplySavedGuiPosition("MobileToggle", MobileToggleBtn) end
if getgenv().TrackGuiPosition then getgenv().TrackGuiPosition("MobileToggle", MobileToggleBtn) end
task.spawn(function()
    while not getgenv().Destroyed and not getgenv().ScriptLoaded do
        task.wait(0.05)
    end
    if not getgenv().Destroyed and MobileToggleBtn and MobileToggleBtn.Parent then
        MobileToggleBtn.Visible = Settings.MobileToggle ~= false
    end
end)
MobileToggleBtn.MouseButton1Click:Connect(function()
    if getgenv().Destroyed or not getgenv().ScriptLoaded then return end
    if getgenv().ToggleToxGui then
        getgenv().ToggleToxGui()
    else
        Main.Visible = not Main.Visible
        if DimmerFrame then
            DimmerFrame.Visible = (Settings.DimBackground == true and Main.Visible)
        end
    end
end)
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
WatermarkLabel.Text = "<b>ToxHud</b> 1.0.0  |  FPS: 60  |  Ping: 50ms"
WatermarkLabel.TextColor3 = Theme.Text
WatermarkLabel.Font = Enum.Font.GothamMedium
WatermarkLabel.TextSize = 10
WatermarkLabel.TextXAlignment = Enum.TextXAlignment.Left
WatermarkLabel.Parent = WatermarkFrame
RegisterThemedObject(WatermarkLabel, "TextColor3", "Text")
MakeDraggable(WatermarkFrame, WatermarkFrame)
if getgenv().ApplySavedGuiPosition then getgenv().ApplySavedGuiPosition("Watermark", WatermarkFrame) end
if getgenv().TrackGuiPosition then getgenv().TrackGuiPosition("Watermark", WatermarkFrame) end
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
do
    local ColorPickerModal = Instance.new("Frame")
    ColorPickerModal.Name = "ToxColorPickerModal"
    ColorPickerModal.Size = UDim2.new(0, 322, 0, 376)
    ColorPickerModal.Position = UDim2.new(0.5, -161, 0.5, -188)
    ColorPickerModal.BackgroundColor3 = Theme.Panel
    ColorPickerModal.BorderSizePixel = 0
    ColorPickerModal.Visible = false
    ColorPickerModal.ZIndex = 2000
    ColorPickerModal.Parent = Gui
    RegisterThemedObject(ColorPickerModal, "BackgroundColor3", "Panel")
    local CPModalCorner = Instance.new("UICorner") CPModalCorner.CornerRadius = UDim.new(0, 10) CPModalCorner.Parent = ColorPickerModal
    local CPModalStroke = Instance.new("UIStroke") CPModalStroke.Color = Theme.Accent CPModalStroke.Thickness = 1 CPModalStroke.Transparency = 0.25 CPModalStroke.Parent = ColorPickerModal
    RegisterThemedObject(CPModalStroke, "Color", "Accent")
    MakeDraggable(ColorPickerModal, ColorPickerModal)

    local CPTitle = Instance.new("TextLabel")
    CPTitle.Size = UDim2.new(1, -50, 0, 34)
    CPTitle.Position = UDim2.new(0, 14, 0, 2)
    CPTitle.BackgroundTransparency = 1
    CPTitle.Text = "Color Picker (HSV)"
    CPTitle.TextColor3 = Theme.Text
    CPTitle.Font = Enum.Font.GothamBold
    CPTitle.TextSize = 13
    CPTitle.TextXAlignment = Enum.TextXAlignment.Left
    CPTitle.ZIndex = 2001
    CPTitle.Parent = ColorPickerModal
    RegisterThemedObject(CPTitle, "TextColor3", "Text")

    local CPClose = Instance.new("TextButton")
    CPClose.Size = UDim2.new(0, 24, 0, 24)
    CPClose.Position = UDim2.new(1, -32, 0, 6)
    CPClose.BackgroundColor3 = Theme.Element
    CPClose.BorderSizePixel = 0
    CPClose.Text = "✕"
    CPClose.TextColor3 = Theme.DimText
    CPClose.Font = Enum.Font.GothamBold
    CPClose.TextSize = 12
    CPClose.ZIndex = 2001
    CPClose.Parent = ColorPickerModal
    local CPCloseCorner = Instance.new("UICorner") CPCloseCorner.CornerRadius = UDim.new(0, 5) CPCloseCorner.Parent = CPClose
    RegisterThemedObject(CPClose, "BackgroundColor3", "Element")
    RegisterThemedObject(CPClose, "TextColor3", "DimText")
    CPClose.MouseButton1Click:Connect(function()
        ColorPickerModal.Visible = false
    end)

    -- 2D Saturation / Value square
    local SVBox = Instance.new("TextButton")
    SVBox.Name = "SVBox"
    SVBox.Size = UDim2.new(0, 260, 0, 180)
    SVBox.Position = UDim2.new(0, 14, 0, 40)
    SVBox.BackgroundColor3 = Color3.fromHSV(0.6, 1, 1)
    SVBox.BorderSizePixel = 0
    SVBox.Text = ""
    SVBox.AutoButtonColor = false
    SVBox.ClipsDescendants = true
    SVBox.ZIndex = 2002
    SVBox.Parent = ColorPickerModal
    local svCorner = Instance.new("UICorner") svCorner.CornerRadius = UDim.new(0, 6) svCorner.Parent = SVBox
    local svStroke = Instance.new("UIStroke") svStroke.Color = Theme.Outline svStroke.Thickness = 1 svStroke.Transparency = 0.35 svStroke.Parent = SVBox

    local SatLayer = Instance.new("Frame")
    SatLayer.Size = UDim2.new(1, 0, 1, 0)
    SatLayer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    SatLayer.BorderSizePixel = 0
    SatLayer.ZIndex = 2003
    SatLayer.Parent = SVBox
    local satCorner = Instance.new("UICorner") satCorner.CornerRadius = UDim.new(0, 6) satCorner.Parent = SatLayer
    local satGrad = Instance.new("UIGradient")
    satGrad.Rotation = 0
    satGrad.Transparency = NumberSequence.new(0, 1)
    satGrad.Parent = SatLayer

    local ValLayer = Instance.new("Frame")
    ValLayer.Size = UDim2.new(1, 0, 1, 0)
    ValLayer.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    ValLayer.BorderSizePixel = 0
    ValLayer.ZIndex = 2004
    ValLayer.Parent = SVBox
    local valCorner = Instance.new("UICorner") valCorner.CornerRadius = UDim.new(0, 6) valCorner.Parent = ValLayer
    local valGrad = Instance.new("UIGradient")
    valGrad.Rotation = 90
    valGrad.Transparency = NumberSequence.new(1, 0)
    valGrad.Parent = ValLayer

    local SVKnob = Instance.new("Frame")
    SVKnob.Size = UDim2.new(0, 14, 0, 14)
    SVKnob.AnchorPoint = Vector2.new(0.5, 0.5)
    SVKnob.Position = UDim2.new(1, 0, 0, 0)
    SVKnob.BackgroundTransparency = 1
    SVKnob.ZIndex = 2006
    SVKnob.Parent = SVBox
    local svkOuter = Instance.new("UIStroke") svkOuter.Color = Color3.fromRGB(255, 255, 255) svkOuter.Thickness = 2 svkOuter.Parent = SVKnob
    local svkCorner = Instance.new("UICorner") svkCorner.CornerRadius = UDim.new(1, 0) svkCorner.Parent = SVKnob
    local svkDot = Instance.new("Frame")
    svkDot.Size = UDim2.new(1, -4, 1, -4)
    svkDot.AnchorPoint = Vector2.new(0.5, 0.5)
    svkDot.Position = UDim2.new(0.5, 0, 0.5, 0)
    svkDot.BackgroundTransparency = 1
    svkDot.ZIndex = 2007
    svkDot.Parent = SVKnob
    local svkdCorner = Instance.new("UICorner") svkdCorner.CornerRadius = UDim.new(1, 0) svkdCorner.Parent = svkDot
    local svkdStroke = Instance.new("UIStroke") svkdStroke.Color = Color3.fromRGB(15, 15, 20) svkdStroke.Thickness = 1.5 svkdStroke.Parent = svkDot

    -- Vertical full-spectrum Hue bar
    local HueBar = Instance.new("TextButton")
    HueBar.Name = "HueBar"
    HueBar.Size = UDim2.new(0, 24, 0, 180)
    HueBar.Position = UDim2.new(0, 284, 0, 40)
    HueBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    HueBar.BorderSizePixel = 0
    HueBar.Text = ""
    HueBar.AutoButtonColor = false
    HueBar.ZIndex = 2002
    HueBar.Parent = ColorPickerModal
    local hueCorner = Instance.new("UICorner") hueCorner.CornerRadius = UDim.new(0, 6) hueCorner.Parent = HueBar
    local hueStroke = Instance.new("UIStroke") hueStroke.Color = Theme.Outline hueStroke.Thickness = 1 hueStroke.Transparency = 0.35 hueStroke.Parent = HueBar
    local hueGrad = Instance.new("UIGradient")
    hueGrad.Rotation = 90
    hueGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.000, Color3.fromRGB(255, 0, 0)),
        ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255, 255, 0)),
        ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0, 255, 0)),
        ColorSequenceKeypoint.new(0.500, Color3.fromRGB(0, 255, 255)),
        ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0, 0, 255)),
        ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255, 0, 255)),
        ColorSequenceKeypoint.new(1.000, Color3.fromRGB(255, 0, 0))
    })
    hueGrad.Parent = HueBar

    local HueKnob = Instance.new("Frame")
    HueKnob.Size = UDim2.new(0, 16, 0, 16)
    HueKnob.AnchorPoint = Vector2.new(0.5, 0.5)
    HueKnob.Position = UDim2.new(0.5, 0, 0.6, 0)
    HueKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    HueKnob.BorderSizePixel = 0
    HueKnob.ZIndex = 2006
    HueKnob.Parent = HueBar
    local hkCorner = Instance.new("UICorner") hkCorner.CornerRadius = UDim.new(1, 0) hkCorner.Parent = HueKnob
    local hkStroke = Instance.new("UIStroke") hkStroke.Color = Color3.fromRGB(20, 20, 26) hkStroke.Thickness = 1.5 hkStroke.Parent = HueKnob

    -- Preview + Hex + RGB readout row
    local CPPreview = Instance.new("Frame")
    CPPreview.Size = UDim2.new(0, 52, 0, 30)
    CPPreview.Position = UDim2.new(0, 14, 0, 232)
    CPPreview.BackgroundColor3 = Theme.Accent
    CPPreview.BorderSizePixel = 0
    CPPreview.ZIndex = 2002
    CPPreview.Parent = ColorPickerModal
    local prevCorner = Instance.new("UICorner") prevCorner.CornerRadius = UDim.new(0, 6) prevCorner.Parent = CPPreview
    local prevStroke = Instance.new("UIStroke") prevStroke.Color = Theme.Outline prevStroke.Thickness = 1 prevStroke.Transparency = 0.3 prevStroke.Parent = CPPreview

    local HexBox = Instance.new("TextBox")
    HexBox.Size = UDim2.new(0, 92, 0, 30)
    HexBox.Position = UDim2.new(0, 74, 0, 232)
    HexBox.BackgroundColor3 = Theme.Element
    HexBox.BorderSizePixel = 0
    HexBox.Text = "#1E5FFF"
    HexBox.TextColor3 = Theme.Text
    HexBox.Font = Enum.Font.Code
    HexBox.TextSize = 12
    HexBox.ClearTextOnFocus = false
    HexBox.ZIndex = 2002
    HexBox.Parent = ColorPickerModal
    local hxCorner = Instance.new("UICorner") hxCorner.CornerRadius = UDim.new(0, 6) hxCorner.Parent = HexBox
    local hxStroke = Instance.new("UIStroke") hxStroke.Color = Theme.Outline hxStroke.Thickness = 1 hxStroke.Transparency = 0.3 hxStroke.Parent = HexBox
    RegisterThemedObject(HexBox, "BackgroundColor3", "Element")
    RegisterThemedObject(HexBox, "TextColor3", "Text")

    local RGBLabel = Instance.new("TextLabel")
    RGBLabel.Size = UDim2.new(0, 136, 0, 30)
    RGBLabel.Position = UDim2.new(0, 172, 0, 232)
    RGBLabel.BackgroundColor3 = Theme.Element
    RGBLabel.BorderSizePixel = 0
    RGBLabel.Text = "RGB: 30, 95, 255"
    RGBLabel.TextColor3 = Theme.DimText
    RGBLabel.Font = Enum.Font.GothamMedium
    RGBLabel.TextSize = 11
    RGBLabel.ZIndex = 2002
    RGBLabel.Parent = ColorPickerModal
    local rgbCorner = Instance.new("UICorner") rgbCorner.CornerRadius = UDim.new(0, 6) rgbCorner.Parent = RGBLabel
    RegisterThemedObject(RGBLabel, "BackgroundColor3", "Element")
    RegisterThemedObject(RGBLabel, "TextColor3", "DimText")

    -- Quick Swatches
    local PresetsContainer = Instance.new("Frame")
    PresetsContainer.Size = UDim2.new(1, -28, 0, 26)
    PresetsContainer.Position = UDim2.new(0, 14, 0, 274)
    PresetsContainer.BackgroundTransparency = 1
    PresetsContainer.ZIndex = 2002
    PresetsContainer.Parent = ColorPickerModal
    local PresetsLayout = Instance.new("UIListLayout")
    PresetsLayout.FillDirection = Enum.FillDirection.Horizontal
    PresetsLayout.Padding = UDim.new(0, 6)
    PresetsLayout.Parent = PresetsContainer

    local CPApplyBtn = Instance.new("TextButton")
    CPApplyBtn.Size = UDim2.new(1, -28, 0, 34)
    CPApplyBtn.Position = UDim2.new(0, 14, 0, 326)
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

    local curH, curS, curV = 0.6, 0.88, 1
    local ActiveEditingColorKey = nil
    local ActiveSwatchFrame = nil
    local ActiveCustomCallback = nil

    local function PushColorChange(isFinal)
        local col = Color3.fromHSV(curH, curS, curV)
        CPPreview.BackgroundColor3 = col
        SVBox.BackgroundColor3 = Color3.fromHSV(curH, 1, 1)
        SVKnob.Position = UDim2.new(curS, 0, 1 - curV, 0)
        HueKnob.Position = UDim2.new(0.5, 0, curH, 0)
        HueKnob.BackgroundColor3 = Color3.fromHSV(curH, 1, 1)
        local r = math.clamp(math.floor(col.R * 255 + 0.5), 0, 255)
        local g = math.clamp(math.floor(col.G * 255 + 0.5), 0, 255)
        local b = math.clamp(math.floor(col.B * 255 + 0.5), 0, 255)
        HexBox.Text = string.format("#%02X%02X%02X", r, g, b)
        RGBLabel.Text = string.format("RGB: %d, %d, %d", r, g, b)
        if ActiveCustomCallback then
            pcall(ActiveCustomCallback, col, isFinal)
        elseif ActiveEditingColorKey then
            if ActiveEditingColorKey == "Accent" then
                if getgenv().SetToxCustomAccent then
                    getgenv().SetToxCustomAccent(col, not isFinal)
                else
                    Theme.Accent = col
                    Settings.CustomAccentActive = true
                    ApplyTheme()
                end
            else
                Theme[ActiveEditingColorKey] = col
                Settings.Theme = Theme
                ApplyTheme()
                if isFinal and getgenv().AutoSaveConfiguration then
                    getgenv().AutoSaveConfiguration()
                end
            end
            if ActiveSwatchFrame then
                ActiveSwatchFrame.BackgroundColor3 = col
            end
        end
    end

    local function SetFromColor3(col, isFinal)
        if typeof(col) ~= "Color3" then return end
        local h, s, v = col:ToHSV()
        curH = h
        curS = s
        curV = v
        PushColorChange(isFinal)
    end

    local function bindDrag2D(btn, onXY, onEnd)
        btn.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                local function calc(px, py)
                    local sz = btn.AbsoluteSize
                    local ps = btn.AbsolutePosition
                    local rx = math.clamp((px - ps.X) / math.max(sz.X, 1), 0, 1)
                    local ry = math.clamp((py - ps.Y) / math.max(sz.Y, 1), 0, 1)
                    onXY(rx, ry)
                end
                calc(inp.Position.X, inp.Position.Y)
                local mc, ec
                mc = UserInputService.InputChanged:Connect(function(c)
                    if c.UserInputType == Enum.UserInputType.MouseMovement or c.UserInputType == Enum.UserInputType.Touch then
                        calc(c.Position.X, c.Position.Y)
                    end
                end)
                ec = UserInputService.InputEnded:Connect(function(e)
                    if e.UserInputType == Enum.UserInputType.MouseButton1 or e.UserInputType == Enum.UserInputType.Touch then
                        if mc then pcall(function() mc:Disconnect() end) end
                        if ec then pcall(function() ec:Disconnect() end) end
                        if onEnd then onEnd() end
                    end
                end)
            end
        end)
    end

    bindDrag2D(SVBox, function(rx, ry)
        curS = rx
        curV = 1 - ry
        PushColorChange(false)
    end, function()
        PushColorChange(true)
    end)

    bindDrag2D(HueBar, function(_, ry)
        curH = ry
        PushColorChange(false)
    end, function()
        PushColorChange(true)
    end)

    HexBox.FocusLost:Connect(function()
        local raw = tostring(HexBox.Text or ""):gsub("#", ""):gsub("%s+", "")
        if #raw == 6 then
            local r = tonumber(raw:sub(1, 2), 16)
            local g = tonumber(raw:sub(3, 4), 16)
            local b = tonumber(raw:sub(5, 6), 16)
            if r and g and b then
                SetFromColor3(Color3.fromRGB(r, g, b), true)
                return
            end
        end
        PushColorChange(false)
    end)

    local Presets = {
        Color3.fromRGB(255, 55, 65),
        Color3.fromRGB(255, 145, 35),
        Color3.fromRGB(255, 220, 40),
        Color3.fromRGB(35, 210, 115),
        Color3.fromRGB(0, 215, 240),
        Color3.fromRGB(30, 95, 255),
        Color3.fromRGB(165, 65, 255),
        Color3.fromRGB(255, 255, 255)
    }
    for _, pCol in ipairs(Presets) do
        local pBtn = Instance.new("TextButton")
        pBtn.Size = UDim2.new(0, 30, 0, 24)
        pBtn.BackgroundColor3 = pCol
        pBtn.BorderSizePixel = 0
        pBtn.Text = ""
        pBtn.ZIndex = 2003
        pBtn.Parent = PresetsContainer
        local pCorner = Instance.new("UICorner") pCorner.CornerRadius = UDim.new(0, 4) pCorner.Parent = pBtn
        local pStroke = Instance.new("UIStroke") pStroke.Color = Theme.Outline pStroke.Thickness = 1 pStroke.Transparency = 0.4 pStroke.Parent = pBtn
        pBtn.MouseButton1Click:Connect(function()
            SetFromColor3(pCol, true)
        end)
    end

    CPApplyBtn.MouseButton1Click:Connect(function()
        PushColorChange(true)
        ColorPickerModal.Visible = false
    end)

    OpenColorPicker = function(colorKeyOrSpec, swatchFrame)
        ColorPickerModal.BackgroundTransparency = math.clamp((tonumber(Settings.ToxUITransparency) or 0) * 0.72, 0, 0.75)
        if typeof(colorKeyOrSpec) == "table" then
            ActiveEditingColorKey = nil
            ActiveSwatchFrame = swatchFrame
            ActiveCustomCallback = colorKeyOrSpec.OnChanged
            CPTitle.Text = tostring(colorKeyOrSpec.Title or "Color Picker (HSV)")
            SetFromColor3(colorKeyOrSpec.InitialColor or Color3.fromRGB(255, 255, 255), false)
        else
            ActiveCustomCallback = nil
            ActiveEditingColorKey = colorKeyOrSpec
            ActiveSwatchFrame = swatchFrame
            CPTitle.Text = "Color: " .. tostring(colorKeyOrSpec)
            SetFromColor3(Theme[colorKeyOrSpec] or Color3.fromRGB(255, 255, 255), false)
        end
        ColorPickerModal.Visible = true
    end
end
UI.CardRegistry = CardRegistry
UI.CardLayoutOrder = CardLayoutOrder
UI.ActivePageCards = ActivePageCards
UI.CreateCard = CreateCard
UI.ClearActivePageCard = ClearActivePageCard
UI.CreateSection = CreateSection
UI.ResolveElementParent = ResolveElementParent
UI.Pages = Pages
UI.CreatePage = CreatePage
UI.HomePage = HomePage
UI.GamePage = GamePage
UI.CombatPage = CombatPage
UI.PlayerPage = PlayerPage
UI.VisualsPage = VisualsPage
UI.LightingPage = LightingPage
UI.FlingPage = FlingPage
UI.ScriptsPage = ScriptsPage
UI.JoinPage = JoinPage
UI.ChatPage = ChatPage
UI.ControlPage = ControlPage
UI.SettingsPage = SettingsPage
UI.ConfigPage = ConfigPage
UI.UniversalPage = UniversalPage
UI.SidebarNavButtons = SidebarNavButtons
UI.ToxOpenPage = ToxOpenPage
UI.MobileToggleBtn = MobileToggleBtn
UI.WatermarkFrame = WatermarkFrame
UI.WatermarkLabel = WatermarkLabel
UI.ClearWeather = ClearWeather
UI.StartWeatherEngine = StartWeatherEngine
UI.OpenColorPicker = OpenColorPicker
if UI.UpdateWatermarkVisualRef then UI.UpdateWatermarkVisualRef(WatermarkFrame, WatermarkLabel) end
if UI.RegisterColorPickerOpener then UI.RegisterColorPickerOpener(OpenColorPicker) end
