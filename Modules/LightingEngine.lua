local RegisterThemedObject = getgenv().RegisterThemedObject or function() end
local Theme = getgenv().Theme or {
    Background = Color3.fromRGB(15, 16, 24),
    Panel = Color3.fromRGB(20, 22, 34),
    Element = Color3.fromRGB(28, 30, 46),
    Hover = Color3.fromRGB(36, 38, 58),
    Outline = Color3.fromRGB(35, 38, 58),
    Accent = Color3.fromRGB(45, 95, 255),
    Accent2 = Color3.fromRGB(130, 60, 255),
    Text = Color3.fromRGB(240, 240, 245),
    DimText = Color3.fromRGB(140, 145, 165),
    Risky = Color3.fromRGB(240, 65, 65)
}
getgenv().ToxModule2SplitVersion = "2026-09-16-lighting-controller-2"
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Player = Players.LocalPlayer
local env = getgenv()
if env.Destroyed then
    return
end
local Settings = env.Settings or {}
local Gui = env.Gui
local MAIN_COLOR = env.MAIN_COLOR or Color3.fromRGB(0, 170, 255)
local SavedWaypoints = env.SavedWaypoints or {}
local SavedIDs = env.SavedIDs or {}
local function MakeDraggable(...) if env.MakeDraggable then return env.MakeDraggable(...) end end
local function RoundTopBar(bar)
    if not bar or bar:FindFirstChild("ToxCornerFiller") then return end
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = bar
    local filler = Instance.new("Frame")
    filler.Name = "ToxCornerFiller"
    filler.BorderSizePixel = 0
    filler.Size = UDim2.new(1, 0, 0, 10)
    filler.Position = UDim2.new(0, 0, 1, -10)
    filler.BackgroundColor3 = bar.BackgroundColor3
    filler.ZIndex = 0
    filler.Parent = bar
    RegisterThemedObject(filler, "BackgroundColor3", "Element")
end
getgenv().ToxRoundTopBar = RoundTopBar
local function CustomNotify(...) if env.CustomNotify then return env.CustomNotify(...) end end
local function AutoSaveConfiguration(...) if env.AutoSaveConfiguration then return env.AutoSaveConfiguration(...) end end
local function AddConnection(...) if env.AddConnection then return env.AddConnection(...) end end
local function ApplySavedGuiPosition(...) if env.ApplySavedGuiPosition then return env.ApplySavedGuiPosition(...) end end
local function TrackGuiPosition(...) if env.TrackGuiPosition then return env.TrackGuiPosition(...) end end
for _, key in ipairs({"ChatLogGui", "WaypointsGui", "MusicGui"}) do
    local object = env[key]
    if typeof(object) == "Instance" and object.Parent then
        pcall(function() object:Destroy() end)
    end
    env[key] = nil
end
do
local ChatLogGui = Instance.new("Frame")
ChatLogGui.Name = "ChatLogFrame"
ChatLogGui.Size = UDim2.new(0, 360, 0, 240)
ChatLogGui.Position = UDim2.new(0.5, 180, 0.5, -120)
ChatLogGui.BackgroundColor3 = Theme.Panel
ChatLogGui.BorderSizePixel = 0
ChatLogGui.ClipsDescendants = true
ChatLogGui.Visible = false
ChatLogGui.Parent = Gui
getgenv().ChatLogGui = ChatLogGui
ApplySavedGuiPosition("ChatLogs", ChatLogGui)
TrackGuiPosition("ChatLogs", ChatLogGui)
local ChatLogCorner = Instance.new("UICorner") ChatLogCorner.CornerRadius = UDim.new(0, 8) ChatLogCorner.Parent = ChatLogGui
local ChatLogStroke = Instance.new("UIStroke") ChatLogStroke.Color = Theme.Accent ChatLogStroke.Thickness = 1 ChatLogStroke.Transparency = 0.25 ChatLogStroke.Parent = ChatLogGui
RegisterThemedObject(ChatLogStroke, "Color", "Accent")
RegisterThemedObject(ChatLogGui, "BackgroundColor3", "Panel")
local ChatLogTopBar = Instance.new("Frame")
ChatLogTopBar.Size = UDim2.new(1, 0, 0, 32)
ChatLogTopBar.BackgroundColor3 = Theme.Element
RegisterThemedObject(ChatLogTopBar, "BackgroundColor3", "Element")
ChatLogTopBar.BorderSizePixel = 0
ChatLogTopBar.Parent = ChatLogGui
RoundTopBar(ChatLogTopBar)
local ChatLogTopBorder = Instance.new("Frame")
ChatLogTopBorder.Size = UDim2.new(1, 0, 0, 1)
ChatLogTopBorder.Position = UDim2.new(0, 0, 1, -1)
ChatLogTopBorder.BackgroundColor3 = Theme.Outline
ChatLogTopBorder.BorderSizePixel = 0
ChatLogTopBorder.Parent = ChatLogTopBar
RegisterThemedObject(ChatLogTopBorder, "BackgroundColor3", "Outline")
MakeDraggable(ChatLogGui, ChatLogTopBar)
local ChatLogTitle = Instance.new("TextLabel")
ChatLogTitle.Size = UDim2.new(1, -110, 1, 0)
ChatLogTitle.Position = UDim2.new(0, 10, 0, 0)
ChatLogTitle.BackgroundTransparency = 1
ChatLogTitle.Text = "Chat Logs"
ChatLogTitle.TextColor3 = Theme.Text
RegisterThemedObject(ChatLogTitle, "TextColor3", "Text")
ChatLogTitle.Font = Enum.Font.GothamBold
ChatLogTitle.TextSize = 13
ChatLogTitle.TextXAlignment = Enum.TextXAlignment.Left
ChatLogTitle.Parent = ChatLogTopBar
local ChatLogMinBtn = Instance.new("TextButton")
ChatLogMinBtn.Size = UDim2.new(0, 24, 0, 22)
ChatLogMinBtn.Position = UDim2.new(1, -88, 0.5, -11)
ChatLogMinBtn.BackgroundColor3 = Theme.Panel
RegisterThemedObject(ChatLogMinBtn, "BackgroundColor3", "Panel")
ChatLogMinBtn.BorderSizePixel = 0
ChatLogMinBtn.Text = "-"
ChatLogMinBtn.TextColor3 = Theme.Text
RegisterThemedObject(ChatLogMinBtn, "TextColor3", "Text")
ChatLogMinBtn.Font = Enum.Font.GothamBold
ChatLogMinBtn.TextSize = 14
ChatLogMinBtn.Parent = ChatLogTopBar
local ChatLogMinCorner = Instance.new("UICorner") ChatLogMinCorner.CornerRadius = UDim.new(0, 4) ChatLogMinCorner.Parent = ChatLogMinBtn
local ClearBtn = Instance.new("TextButton")
ClearBtn.Size = UDim2.new(0, 52, 0, 22)
ClearBtn.Position = UDim2.new(1, -60, 0.5, -11)
ClearBtn.BackgroundColor3 = Theme.Panel
RegisterThemedObject(ClearBtn, "BackgroundColor3", "Panel")
ClearBtn.BorderSizePixel = 0
ClearBtn.Text = "Clear"
ClearBtn.TextColor3 = Theme.Text
RegisterThemedObject(ClearBtn, "TextColor3", "Text")
ClearBtn.Font = Enum.Font.GothamBold
ClearBtn.TextSize = 11
ClearBtn.Parent = ChatLogTopBar
local ClearCorner = Instance.new("UICorner") ClearCorner.CornerRadius = UDim.new(0, 4) ClearCorner.Parent = ClearBtn
local ChatLogScroll = Instance.new("ScrollingFrame")
ChatLogScroll.Size = UDim2.new(1, -12, 1, -42)
ChatLogScroll.Position = UDim2.new(0, 6, 0, 36)
ChatLogScroll.BackgroundTransparency = 1
ChatLogScroll.BorderSizePixel = 0
ChatLogScroll.ScrollBarThickness = 4
ChatLogScroll.ScrollBarImageColor3 = MAIN_COLOR
RegisterThemedObject(ChatLogScroll, "ScrollBarImageColor3", "Accent")
ChatLogScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
ChatLogScroll.Parent = ChatLogGui
local ChatLogLayout = Instance.new("UIListLayout")
ChatLogLayout.SortOrder = Enum.SortOrder.LayoutOrder
ChatLogLayout.Padding = UDim.new(0, 4)
ChatLogLayout.Parent = ChatLogScroll
ChatLogLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ChatLogScroll.CanvasSize = UDim2.new(0, 0, 0, ChatLogLayout.AbsoluteContentSize.Y + 10)
    ChatLogScroll.CanvasPosition = Vector2.new(0, ChatLogScroll.CanvasSize.Y.Offset)
end)
local function AddChatLog(sender, text)
    local timeStr = os.date("[%H:%M:%S] ")
    local msgLabel = Instance.new("TextLabel")
    msgLabel.Size = UDim2.new(1, 0, 0, 18)
    msgLabel.BackgroundTransparency = 1
    msgLabel.Text = timeStr .. "[" .. sender .. "]: " .. text
    msgLabel.TextColor3 = Theme.Text
    RegisterThemedObject(msgLabel, "TextColor3", "Text")
    msgLabel.Font = Enum.Font.Gotham
    msgLabel.TextSize = 12
    msgLabel.TextXAlignment = Enum.TextXAlignment.Left
    msgLabel.TextWrapped = true
    msgLabel.Parent = ChatLogScroll
end
ClearBtn.MouseButton1Click:Connect(function()
    for _, child in ipairs(ChatLogScroll:GetChildren()) do
        if child:IsA("TextLabel") then child:Destroy() end
    end
end)
pcall(function()
    AddConnection(TextChatService.MessageReceived:Connect(function(msg)
        if msg.TextSource then AddChatLog(msg.TextSource.Name, msg.Text) end
    end))
end)
local ChatLogMinState = false
ChatLogMinBtn.MouseButton1Click:Connect(function()
    ChatLogMinState = not ChatLogMinState
    ChatLogScroll.Visible = not ChatLogMinState
    ChatLogGui.Size = ChatLogMinState and UDim2.new(0, 360, 0, 32) or UDim2.new(0, 360, 0, 240)
    ChatLogMinBtn.Text = ChatLogMinState and "+" or "-"
end)
end
do
local WaypointsGui = Instance.new("Frame")
WaypointsGui.Name = "ToxWaypointsFrame"
WaypointsGui.Size = UDim2.new(0, 360, 0, 320)
WaypointsGui.Position = UDim2.new(0.5, -180, 0.5, -160)
WaypointsGui.BackgroundColor3 = Theme.Panel
WaypointsGui.BorderSizePixel = 0
WaypointsGui.ClipsDescendants = true
WaypointsGui.Visible = false
WaypointsGui.Parent = Gui
getgenv().WaypointsGui = WaypointsGui
ApplySavedGuiPosition("Waypoints", WaypointsGui)
TrackGuiPosition("Waypoints", WaypointsGui)
local WayCorner = Instance.new("UICorner") WayCorner.CornerRadius = UDim.new(0, 8) WayCorner.Parent = WaypointsGui
local WayStroke = Instance.new("UIStroke") WayStroke.Color = Theme.Accent WayStroke.Thickness = 1 WayStroke.Transparency = 0.25 WayStroke.Parent = WaypointsGui
RegisterThemedObject(WayStroke, "Color", "Accent")
RegisterThemedObject(WaypointsGui, "BackgroundColor3", "Panel")
local WayTopBar = Instance.new("Frame")
WayTopBar.Size = UDim2.new(1, 0, 0, 32)
WayTopBar.BackgroundColor3 = Theme.Element
RegisterThemedObject(WayTopBar, "BackgroundColor3", "Element")
WayTopBar.BorderSizePixel = 0
WayTopBar.Parent = WaypointsGui
RoundTopBar(WayTopBar)
local WayTopBorder = Instance.new("Frame")
WayTopBorder.Size = UDim2.new(1, 0, 0, 1)
WayTopBorder.Position = UDim2.new(0, 0, 1, -1)
WayTopBorder.BackgroundColor3 = Theme.Outline
WayTopBorder.BorderSizePixel = 0
WayTopBorder.Parent = WayTopBar
RegisterThemedObject(WayTopBorder, "BackgroundColor3", "Outline")
MakeDraggable(WaypointsGui, WayTopBar)
local WayTitle = Instance.new("TextLabel")
WayTitle.Size = UDim2.new(1, -40, 1, 0)
WayTitle.Position = UDim2.new(0, 10, 0, 0)
WayTitle.BackgroundTransparency = 1
WayTitle.Text = "Tox Waypoints"
WayTitle.TextColor3 = Theme.Text
RegisterThemedObject(WayTitle, "TextColor3", "Text")
WayTitle.Font = Enum.Font.GothamBold
WayTitle.TextSize = 13
WayTitle.TextXAlignment = Enum.TextXAlignment.Left
WayTitle.Parent = WayTopBar
local WayCloseBtn = Instance.new("TextButton")
WayCloseBtn.Size = UDim2.new(0, 22, 0, 20)
WayCloseBtn.Position = UDim2.new(1, -26, 0.5, -10)
WayCloseBtn.BackgroundColor3 = Theme.Panel
RegisterThemedObject(WayCloseBtn, "BackgroundColor3", "Panel")
WayCloseBtn.BorderSizePixel = 0
WayCloseBtn.Text = "X"
WayCloseBtn.TextColor3 = Theme.DimText
RegisterThemedObject(WayCloseBtn, "TextColor3", "DimText")
WayCloseBtn.Font = Enum.Font.GothamBold
WayCloseBtn.TextSize = 11
WayCloseBtn.Parent = WayTopBar
local WayCloseCorner = Instance.new("UICorner") WayCloseCorner.CornerRadius = UDim.new(0, 4) WayCloseCorner.Parent = WayCloseBtn
local WayContent = Instance.new("Frame")
WayContent.Size = UDim2.new(1, -16, 1, -40)
WayContent.Position = UDim2.new(0, 8, 0, 36)
WayContent.BackgroundTransparency = 1
WayContent.Parent = WaypointsGui
local function CreateDarkBtn(text, pos, size, parent)
    local b = Instance.new("TextButton")
    b.Size = size
    b.Position = pos
    b.BackgroundColor3 = Theme.Element
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = Theme.Text
    b.Font = Enum.Font.GothamBold
    b.TextSize = 10
    b.Parent = parent
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 4) c.Parent = b
    local bs = Instance.new("UIStroke") bs.Color = Theme.Outline bs.Thickness = 1 bs.Transparency = 0.35 bs.Parent = b
    RegisterThemedObject(b, "BackgroundColor3", "Element")
    RegisterThemedObject(b, "TextColor3", "Text")
    RegisterThemedObject(bs, "Color", "Outline")
    return b
end
getgenv().CreateDarkBtn = CreateDarkBtn
local function CreateWayCoordInput(placeholder, position)
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0.21, 0, 0, 26)
    box.Position = position
    box.BackgroundColor3 = Theme.Element
    box.BorderSizePixel = 0
    box.PlaceholderText = placeholder
    box.Text = ""
    box.TextColor3 = Theme.Text
    box.PlaceholderColor3 = Theme.DimText
    box.Font = Enum.Font.Gotham
    box.TextSize = 10
    box.ClearTextOnFocus = false
    box.Parent = WayContent
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = box
    local bs = Instance.new("UIStroke") bs.Color = Theme.Outline bs.Thickness = 1 bs.Transparency = 0.35 bs.Parent = box
    RegisterThemedObject(box, "BackgroundColor3", "Element")
    RegisterThemedObject(box, "TextColor3", "Text")
    RegisterThemedObject(box, "PlaceholderColor3", "DimText")
    RegisterThemedObject(bs, "Color", "Outline")
    return box
end
local WayInputArea = Instance.new("Frame")
WayInputArea.Size = UDim2.new(1, 0, 0, 26)
WayInputArea.Position = UDim2.new(0, 0, 0, 0)
WayInputArea.BackgroundTransparency = 1
WayInputArea.Parent = WayContent
local WayNameInput = Instance.new("TextBox")
WayNameInput.Size = UDim2.new(0.70, 0, 1, 0)
WayNameInput.Position = UDim2.new(0, 0, 0, 0)
WayNameInput.BackgroundColor3 = Theme.Element
WayNameInput.PlaceholderText = "Waypoint Name"
WayNameInput.Text = ""
WayNameInput.TextColor3 = Theme.Text
WayNameInput.PlaceholderColor3 = Theme.DimText
RegisterThemedObject(WayNameInput, "BackgroundColor3", "Element")
RegisterThemedObject(WayNameInput, "TextColor3", "Text")
RegisterThemedObject(WayNameInput, "PlaceholderColor3", "DimText")
WayNameInput.Font = Enum.Font.Gotham
WayNameInput.TextSize = 11
WayNameInput.Parent = WayInputArea
local WayNameCorner = Instance.new("UICorner") WayNameCorner.CornerRadius = UDim.new(0, 4) WayNameCorner.Parent = WayNameInput
local CreateWayBtn = CreateDarkBtn("Current", UDim2.new(0.72, 0, 0, 0), UDim2.new(0.28, 0, 1, 0), WayInputArea)
local WayXInput = CreateWayCoordInput("X", UDim2.new(0, 0, 0, 32))
local WayYInput = CreateWayCoordInput("Y", UDim2.new(0.22, 0, 0, 32))
local WayZInput = CreateWayCoordInput("Z", UDim2.new(0.44, 0, 0, 32))
local CreateCoordsBtn = CreateDarkBtn("Add Coords", UDim2.new(0.67, 0, 0, 32), UDim2.new(0.33, 0, 0, 26), WayContent)
local CopyCurrentCoordsBtn = CreateDarkBtn("Copy Current Coordinates", UDim2.new(0, 0, 0, 64), UDim2.new(1, 0, 0, 24), WayContent)
local WayScroll = Instance.new("ScrollingFrame")
WayScroll.Size = UDim2.new(1, 0, 1, -96)
WayScroll.Position = UDim2.new(0, 0, 0, 94)
WayScroll.BackgroundTransparency = 1
WayScroll.BorderSizePixel = 0
WayScroll.ScrollBarThickness = 3
WayScroll.ScrollBarImageColor3 = Theme.Accent
RegisterThemedObject(WayScroll, "ScrollBarImageColor3", "Accent")
WayScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
WayScroll.Parent = WayContent
local WayLayout = Instance.new("UIListLayout")
WayLayout.SortOrder = Enum.SortOrder.LayoutOrder
WayLayout.Padding = UDim.new(0, 4)
WayLayout.Parent = WayScroll
WayLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    WayScroll.CanvasSize = UDim2.new(0, 0, 0, WayLayout.AbsoluteContentSize.Y + 5)
end)
local function FormatCoordinate(value)
    return string.format("%.3f", tonumber(value) or 0)
end
local function CopyCoordinates(x, y, z)
    local text = FormatCoordinate(x) .. ", " .. FormatCoordinate(y) .. ", " .. FormatCoordinate(z)
    if setclipboard then
        setclipboard(text)
        CustomNotify("Coordinates copied", Color3.fromRGB(100, 255, 100))
    else
        CustomNotify(text, Color3.fromRGB(255, 255, 100), 5)
    end
    return text
end
local function ClearWayInputs()
    WayNameInput.Text = ""
    WayXInput.Text = ""
    WayYInput.Text = ""
    WayZInput.Text = ""
end
local RefreshWaypointsUI
RefreshWaypointsUI = function()
    if getgenv().GetCurrentToxWaypoints then
        getgenv().GetCurrentToxWaypoints()
    end
    for _, child in ipairs(WayScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    for idx, wp in ipairs(SavedWaypoints) do
        local item = Instance.new("Frame")
        item.Size = UDim2.new(1, -4, 0, 28)
        item.BackgroundColor3 = Theme.Element
        item.BorderSizePixel = 0
        item.Parent = WayScroll
        local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 4) c.Parent = item
        RegisterThemedObject(item, "BackgroundColor3", "Element")
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.42, -4, 1, 0)
        lbl.Position = UDim2.new(0, 6, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = wp.name
        lbl.TextColor3 = Theme.Text
        RegisterThemedObject(lbl, "TextColor3", "Text")
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 11
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextTruncate = Enum.TextTruncate.AtEnd
        lbl.Parent = item
        local goBtn = CreateDarkBtn("GO", UDim2.new(0.43, 0, 0.5, -9), UDim2.new(0, 28, 0, 18), item)
        goBtn.MouseButton1Click:Connect(function()
            local Root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if Root and wp.x and wp.y and wp.z then
                if getgenv().RecordToxTeleportReturn then
                    getgenv().RecordToxTeleportReturn()
                end
                if getgenv().AllowToxTeleport then
                    getgenv().AllowToxTeleport(1.25, "Waypoint")
                end
                Root.AssemblyLinearVelocity = Vector3.zero
                Root.AssemblyAngularVelocity = Vector3.zero
                Root.CFrame = CFrame.new(wp.x, wp.y, wp.z)
                CustomNotify("Teleported to " .. wp.name, Color3.fromRGB(100, 255, 100))
            end
        end)
        local upBtn = CreateDarkBtn("Up", UDim2.new(0.43, 31, 0.5, -9), UDim2.new(0, 22, 0, 18), item)
        upBtn.MouseButton1Click:Connect(function()
            if idx > 1 then
                SavedWaypoints[idx], SavedWaypoints[idx - 1] = SavedWaypoints[idx - 1], SavedWaypoints[idx]
                AutoSaveConfiguration()
                RefreshWaypointsUI()
            end
        end)
        local downBtn = CreateDarkBtn("Dn", UDim2.new(0.43, 56, 0.5, -9), UDim2.new(0, 24, 0, 18), item)
        downBtn.MouseButton1Click:Connect(function()
            if idx < #SavedWaypoints then
                SavedWaypoints[idx], SavedWaypoints[idx + 1] = SavedWaypoints[idx + 1], SavedWaypoints[idx]
                AutoSaveConfiguration()
                RefreshWaypointsUI()
            end
        end)
        local copyBtn = CreateDarkBtn("Copy", UDim2.new(0.43, 83, 0.5, -9), UDim2.new(0, 34, 0, 18), item)
        copyBtn.MouseButton1Click:Connect(function()
            CopyCoordinates(wp.x, wp.y, wp.z)
        end)
        local dBtn = CreateDarkBtn("X", UDim2.new(0.43, 120, 0.5, -9), UDim2.new(0, 18, 0, 18), item)
        dBtn.MouseButton1Click:Connect(function()
            table.remove(SavedWaypoints, idx)
            AutoSaveConfiguration()
            RefreshWaypointsUI()
        end)
    end
end
CreateWayBtn.MouseButton1Click:Connect(function()
    local Root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if Root then
        local name = WayNameInput.Text ~= "" and WayNameInput.Text or ("Waypoint " .. (#SavedWaypoints + 1))
        local pos = Root.Position
        table.insert(SavedWaypoints, {name = name, x = pos.X, y = pos.Y, z = pos.Z})
        ClearWayInputs()
        AutoSaveConfiguration()
        RefreshWaypointsUI()
        CustomNotify("Waypoint Created!", Color3.fromRGB(100, 255, 100))
    end
end)
CreateCoordsBtn.MouseButton1Click:Connect(function()
    local x = tonumber(WayXInput.Text)
    local y = tonumber(WayYInput.Text)
    local z = tonumber(WayZInput.Text)
    if not x or not y or not z then
        CustomNotify("Invalid coordinates", Color3.fromRGB(255, 100, 100))
        return
    end
    local name = WayNameInput.Text ~= "" and WayNameInput.Text or ("Waypoint " .. (#SavedWaypoints + 1))
    table.insert(SavedWaypoints, {name = name, x = x, y = y, z = z})
    ClearWayInputs()
    AutoSaveConfiguration()
    RefreshWaypointsUI()
    CustomNotify("Waypoint added by coordinates", Color3.fromRGB(100, 255, 100))
end)
CopyCurrentCoordsBtn.MouseButton1Click:Connect(function()
    local Root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if not Root then
        return
    end
    local pos = Root.Position
    WayXInput.Text = FormatCoordinate(pos.X)
    WayYInput.Text = FormatCoordinate(pos.Y)
    WayZInput.Text = FormatCoordinate(pos.Z)
    CopyCoordinates(pos.X, pos.Y, pos.Z)
end)
WayCloseBtn.MouseButton1Click:Connect(function() WaypointsGui.Visible = false end)
RefreshWaypointsUI()
end
do
    local CreateDarkBtn = env.CreateDarkBtn
local MusicGui = Instance.new("Frame")
MusicGui.Name = "ToxMusicPlayerFrame"
MusicGui.Size = UDim2.new(0, 370, 0, 310)
MusicGui.Position = UDim2.new(0.5, -185, 0.5, -155)
MusicGui.BackgroundColor3 = Theme.Panel
MusicGui.BorderSizePixel = 0
MusicGui.ClipsDescendants = true
MusicGui.Visible = false
MusicGui.Parent = Gui
getgenv().MusicGui = MusicGui
ApplySavedGuiPosition("Music", MusicGui)
TrackGuiPosition("Music", MusicGui)
local MusicCorner = Instance.new("UICorner") MusicCorner.CornerRadius = UDim.new(0, 8) MusicCorner.Parent = MusicGui
local MusicStroke = Instance.new("UIStroke") MusicStroke.Color = Theme.Accent MusicStroke.Thickness = 1 MusicStroke.Transparency = 0.25 MusicStroke.Parent = MusicGui
RegisterThemedObject(MusicStroke, "Color", "Accent")
RegisterThemedObject(MusicGui, "BackgroundColor3", "Panel")
local MusicTopBar = Instance.new("Frame")
MusicTopBar.Size = UDim2.new(1, 0, 0, 32)
MusicTopBar.BackgroundColor3 = Theme.Element
RegisterThemedObject(MusicTopBar, "BackgroundColor3", "Element")
MusicTopBar.BorderSizePixel = 0
MusicTopBar.Parent = MusicGui
RoundTopBar(MusicTopBar)
local MusicTopBorder = Instance.new("Frame")
MusicTopBorder.Size = UDim2.new(1, 0, 0, 1)
MusicTopBorder.Position = UDim2.new(0, 0, 1, -1)
MusicTopBorder.BackgroundColor3 = Theme.Outline
MusicTopBorder.BorderSizePixel = 0
MusicTopBorder.Parent = MusicTopBar
RegisterThemedObject(MusicTopBorder, "BackgroundColor3", "Outline")
MakeDraggable(MusicGui, MusicTopBar)
local MusicTitle = Instance.new("TextLabel")
MusicTitle.Size = UDim2.new(1, -40, 1, 0)
MusicTitle.Position = UDim2.new(0, 10, 0, 0)
MusicTitle.BackgroundTransparency = 1
MusicTitle.Text = "Tox Music Player"
MusicTitle.TextColor3 = Theme.Text
RegisterThemedObject(MusicTitle, "TextColor3", "Text")
MusicTitle.Font = Enum.Font.GothamBold
MusicTitle.TextSize = 13
MusicTitle.TextXAlignment = Enum.TextXAlignment.Left
MusicTitle.Parent = MusicTopBar
local MusicCloseBtn = Instance.new("TextButton")
MusicCloseBtn.Size = UDim2.new(0, 22, 0, 20)
MusicCloseBtn.Position = UDim2.new(1, -26, 0.5, -10)
MusicCloseBtn.BackgroundColor3 = Theme.Panel
RegisterThemedObject(MusicCloseBtn, "BackgroundColor3", "Panel")
MusicCloseBtn.BorderSizePixel = 0
MusicCloseBtn.Text = "X"
MusicCloseBtn.TextColor3 = Theme.DimText
RegisterThemedObject(MusicCloseBtn, "TextColor3", "DimText")
MusicCloseBtn.Font = Enum.Font.GothamBold
MusicCloseBtn.TextSize = 11
MusicCloseBtn.Parent = MusicTopBar
local MusicCloseCorner = Instance.new("UICorner") MusicCloseCorner.CornerRadius = UDim.new(0, 4) MusicCloseCorner.Parent = MusicCloseBtn
local MusicContent = Instance.new("Frame")
MusicContent.Size = UDim2.new(1, -16, 1, -40)
MusicContent.Position = UDim2.new(0, 8, 0, 36)
MusicContent.BackgroundTransparency = 1
MusicContent.Parent = MusicGui
local InputArea = Instance.new("Frame")
InputArea.Size = UDim2.new(1, 0, 0, 26)
InputArea.Position = UDim2.new(0, 0, 0, 0)
InputArea.BackgroundTransparency = 1
InputArea.Parent = MusicContent
local SoundInput = Instance.new("TextBox")
SoundInput.Size = UDim2.new(0.42, 0, 1, 0)
SoundInput.Position = UDim2.new(0, 0, 0, 0)
SoundInput.BackgroundColor3 = Theme.Element
SoundInput.PlaceholderText = "ID"
SoundInput.Text = ""
SoundInput.TextColor3 = Theme.Text
SoundInput.PlaceholderColor3 = Theme.DimText
RegisterThemedObject(SoundInput, "BackgroundColor3", "Element")
RegisterThemedObject(SoundInput, "TextColor3", "Text")
RegisterThemedObject(SoundInput, "PlaceholderColor3", "DimText")
SoundInput.Font = Enum.Font.Gotham
SoundInput.TextSize = 11
SoundInput.Parent = InputArea
local SoundInputCorner = Instance.new("UICorner") SoundInputCorner.CornerRadius = UDim.new(0, 4) SoundInputCorner.Parent = SoundInput
local SongNameInput = Instance.new("TextBox")
SongNameInput.Size = UDim2.new(0.42, 0, 1, 0)
SongNameInput.Position = UDim2.new(0.43, 0, 0, 0)
SongNameInput.BackgroundColor3 = Theme.Element
SongNameInput.PlaceholderText = "Name"
SongNameInput.Text = ""
SongNameInput.TextColor3 = Theme.Text
SongNameInput.PlaceholderColor3 = Theme.DimText
RegisterThemedObject(SongNameInput, "BackgroundColor3", "Element")
RegisterThemedObject(SongNameInput, "TextColor3", "Text")
RegisterThemedObject(SongNameInput, "PlaceholderColor3", "DimText")
SongNameInput.Font = Enum.Font.Gotham
SongNameInput.TextSize = 11
SongNameInput.Parent = InputArea
local SongNameCorner = Instance.new("UICorner") SongNameCorner.CornerRadius = UDim.new(0, 4) SongNameCorner.Parent = SongNameInput
local AddPlaylistBtn = CreateDarkBtn("Add", UDim2.new(0.86, 0, 0, 0), UDim2.new(0.14, 0, 1, 0), InputArea)
local ControlsBar = Instance.new("Frame")
ControlsBar.Size = UDim2.new(1, 0, 0, 24)
ControlsBar.Position = UDim2.new(0, 0, 0, 32)
ControlsBar.BackgroundTransparency = 1
ControlsBar.Parent = MusicContent
local PrevBtn = CreateDarkBtn("<<", UDim2.new(0, 0, 0, 0), UDim2.new(0.11, 0, 1, 0), ControlsBar)
local PlayBtn = CreateDarkBtn("Play", UDim2.new(0.12, 0, 0, 0), UDim2.new(0.14, 0, 1, 0), ControlsBar)
local PauseBtn = CreateDarkBtn("Pause", UDim2.new(0.27, 0, 0, 0), UDim2.new(0.14, 0, 1, 0), ControlsBar)
local StopBtn = CreateDarkBtn("Stop", UDim2.new(0.42, 0, 0, 0), UDim2.new(0.13, 0, 1, 0), ControlsBar)
local NextBtn = CreateDarkBtn(">>", UDim2.new(0.56, 0, 0, 0), UDim2.new(0.11, 0, 1, 0), ControlsBar)
local LoopToggleBtn = CreateDarkBtn("Loop", UDim2.new(0.68, 0, 0, 0), UDim2.new(0.15, 0, 1, 0), ControlsBar)
local AutoPlayToggleBtn = CreateDarkBtn("Auto", UDim2.new(0.84, 0, 0, 0), UDim2.new(0.16, 0, 1, 0), ControlsBar)
local VolumeArea = Instance.new("Frame")
VolumeArea.Size = UDim2.new(1, 0, 0, 24)
VolumeArea.Position = UDim2.new(0, 0, 0, 60)
VolumeArea.BackgroundTransparency = 1
VolumeArea.Parent = MusicContent
local initVol = math.clamp(math.floor((tonumber(Settings.MusicVolume) or 100) + 0.5), 0, 100)
Settings.MusicVolume = initVol
local VolLabel = Instance.new("TextLabel")
VolLabel.Size = UDim2.new(0.18, 0, 1, 0)
VolLabel.Position = UDim2.new(0, 0, 0, 0)
VolLabel.BackgroundTransparency = 1
VolLabel.Text = "Vol " .. tostring(initVol) .. "%"
VolLabel.TextColor3 = Theme.Text
RegisterThemedObject(VolLabel, "TextColor3", "Text")
VolLabel.Font = Enum.Font.GothamBold
VolLabel.TextSize = 10
VolLabel.TextXAlignment = Enum.TextXAlignment.Left
VolLabel.Parent = VolumeArea

local hasRightBtn = (game.PlaceId == 142823291 or game.PlaceId == 4522347649)
local VolTrack = Instance.new("TextButton")
VolTrack.Size = UDim2.new(hasRightBtn and 0.36 or 0.54, 0, 1, 0)
VolTrack.Position = UDim2.new(0.19, 0, 0, 0)
VolTrack.BackgroundTransparency = 1
VolTrack.BorderSizePixel = 0
VolTrack.Text = ""
VolTrack.AutoButtonColor = false
VolTrack.Parent = VolumeArea

local VolBar = Instance.new("Frame")
VolBar.Size = UDim2.new(1, 0, 0, 6)
VolBar.Position = UDim2.new(0, 0, 0.5, -3)
VolBar.BackgroundColor3 = Theme.Element
VolBar.BorderSizePixel = 0
VolBar.Parent = VolTrack
local vBarCorner = Instance.new("UICorner") vBarCorner.CornerRadius = UDim.new(1, 0) vBarCorner.Parent = VolBar
RegisterThemedObject(VolBar, "BackgroundColor3", "Element")

local volRel = initVol / 100
local VolFill = Instance.new("Frame")
VolFill.Size = UDim2.new(volRel, 0, 1, 0)
VolFill.BackgroundColor3 = Theme.Accent
VolFill.BorderSizePixel = 0
VolFill.Parent = VolBar
local vFillCorner = Instance.new("UICorner") vFillCorner.CornerRadius = UDim.new(1, 0) vFillCorner.Parent = VolFill
RegisterThemedObject(VolFill, "BackgroundColor3", "Accent")

local VolKnob = Instance.new("Frame")
VolKnob.Size = UDim2.new(0, 12, 0, 12)
VolKnob.AnchorPoint = Vector2.new(0.5, 0.5)
VolKnob.Position = UDim2.new(volRel, 0, 0.5, 0)
VolKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
VolKnob.BorderSizePixel = 0
VolKnob.ZIndex = VolBar.ZIndex + 2
VolKnob.Parent = VolTrack
local vKnobCorner = Instance.new("UICorner") vKnobCorner.CornerRadius = UDim.new(1, 0) vKnobCorner.Parent = VolKnob
local vKnobStroke = Instance.new("UIStroke") vKnobStroke.Color = Theme.Accent vKnobStroke.Thickness = 1.5 vKnobStroke.Parent = VolKnob
RegisterThemedObject(vKnobStroke, "Color", "Accent")

local function ApplyMusicVolume(value, skipSave)
    local number = math.clamp(
        math.floor((tonumber(value) or Settings.MusicVolume or 100) + 0.5),
        0,
        100
    )
    Settings.MusicVolume = number
    local r = number / 100
    VolLabel.Text = "Vol " .. tostring(number) .. "%"
    VolFill.Size = UDim2.new(r, 0, 1, 0)
    VolKnob.Position = UDim2.new(r, 0, 0.5, 0)
    if getgenv().ActiveSound then
        getgenv().ActiveSound.Volume = r
    end
    if not skipSave then
        AutoSaveConfiguration()
    end
end
VolTrack.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
        local function calc(px)
            local rel = math.clamp((px - VolTrack.AbsolutePosition.X) / math.max(VolTrack.AbsoluteSize.X, 1), 0, 1)
            ApplyMusicVolume(rel * 100, true)
        end
        TweenService:Create(VolKnob, TweenInfo.new(0.1), {Size = UDim2.new(0, 14, 0, 14)}):Play()
        calc(inp.Position.X)
        local mc, ec
        mc = UserInputService.InputChanged:Connect(function(c)
            if c.UserInputType == Enum.UserInputType.MouseMovement or c.UserInputType == Enum.UserInputType.Touch then
                calc(c.Position.X)
            end
        end)
        ec = UserInputService.InputEnded:Connect(function(e)
            if e.UserInputType == Enum.UserInputType.MouseButton1 or e.UserInputType == Enum.UserInputType.Touch then
                TweenService:Create(VolKnob, TweenInfo.new(0.1), {Size = UDim2.new(0, 12, 0, 12)}):Play()
                if mc then pcall(function() mc:Disconnect() end) end
                if ec then pcall(function() ec:Disconnect() end) end
                AutoSaveConfiguration()
            end
        end)
    end
end)
local CheckMusicIDsBtn = CreateDarkBtn("Check IDs", UDim2.new(hasRightBtn and 0.57 or 0.75, 0, 0, 0), UDim2.new(hasRightBtn and 0.21 or 0.25, 0, 1, 0), VolumeArea)
getgenv().CheckMusicIDsBtn = CheckMusicIDsBtn
local MM2RadioBtn = nil
local AdminMusicBtn = nil
if game.PlaceId == 142823291 then
    MM2RadioBtn = CreateDarkBtn("Radio", UDim2.new(0.79, 0, 0, 0), UDim2.new(0.21, 0, 1, 0), VolumeArea)
elseif game.PlaceId == 4522347649 then
    AdminMusicBtn = CreateDarkBtn("Music", UDim2.new(0.79, 0, 0, 0), UDim2.new(0.21, 0, 1, 0), VolumeArea)
end
local PlaylistScroll = Instance.new("ScrollingFrame")
PlaylistScroll.Size = UDim2.new(1, 0, 1, -88)
PlaylistScroll.Position = UDim2.new(0, 0, 0, 86)
PlaylistScroll.BackgroundTransparency = 1
PlaylistScroll.BorderSizePixel = 0
PlaylistScroll.ScrollBarThickness = 3
PlaylistScroll.ScrollBarImageColor3 = Theme.Accent
RegisterThemedObject(PlaylistScroll, "ScrollBarImageColor3", "Accent")
PlaylistScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
PlaylistScroll.Parent = MusicContent
local PlaylistLayout = Instance.new("UIListLayout")
PlaylistLayout.SortOrder = Enum.SortOrder.LayoutOrder
PlaylistLayout.Padding = UDim.new(0, 3)
PlaylistLayout.Parent = PlaylistScroll
PlaylistLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    PlaylistScroll.CanvasSize = UDim2.new(0, 0, 0, PlaylistLayout.AbsoluteContentSize.Y + 5)
end)
getgenv().ActiveSound = nil
local function PlayMusicByID(id, name)
    if getgenv().ActiveSound then getgenv().ActiveSound:Destroy() end
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://" .. tostring(id)
    sound.Volume = Settings.MusicVolume / 100
    sound.Looped = Settings.MusicLoop
    sound.Parent = SoundService
    sound:Play()
    getgenv().ActiveSound = sound
    CustomNotify("Playing: " .. (name or id), Color3.fromRGB(100, 255, 100))
    if Settings.MusicAutoPlay then
        sound.Ended:Connect(function()
            if not Settings.MusicLoop and #SavedIDs > 0 then
                Settings.CurrentTrackIndex = Settings.CurrentTrackIndex + 1
                if Settings.CurrentTrackIndex > #SavedIDs then Settings.CurrentTrackIndex = 1 end
                local track = SavedIDs[Settings.CurrentTrackIndex]
                PlayMusicByID(track.id, track.name)
            end
        end)
    end
end
getgenv().MusicIDLabels = getgenv().MusicIDLabels or {}
getgenv().SetMusicIDStatus = function(id, status)
    local key = tostring(id)
    local label = getgenv().MusicIDLabels[key]
    if label and label.Parent then
        if status == true then
            label.TextColor3 = Color3.fromRGB(70, 255, 100)
        elseif status == false then
            label.TextColor3 = Color3.fromRGB(255, 70, 70)
        elseif status == "checking" then
            label.TextColor3 = Color3.fromRGB(255, 215, 70)
        else
            label.TextColor3 = Color3.fromRGB(200, 200, 220)
        end
    end
end
local RefreshMusicPlaylistUI
RefreshMusicPlaylistUI = function()
    getgenv().MusicIDLabels = {}
    for _, child in ipairs(PlaylistScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    for idx, itemData in ipairs(SavedIDs) do
        local trackName = itemData.name or ("Track " .. idx)
        local trackID = itemData.id
        local item = Instance.new("Frame")
        item.Size = UDim2.new(1, -4, 0, 26)
        item.BackgroundColor3 = Theme.Element
        item.BorderSizePixel = 0
        item.Parent = PlaylistScroll
        local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 4) c.Parent = item
        RegisterThemedObject(item, "BackgroundColor3", "Element")
        local idBox = Instance.new("TextLabel")
        idBox.Size = UDim2.new(0.24, -4, 1, 0)
        idBox.Position = UDim2.new(0, 4, 0, 0)
        idBox.BackgroundTransparency = 1
        idBox.Text = tostring(trackID)
        idBox.TextColor3 = Color3.fromRGB(200, 200, 220)
        idBox.Font = Enum.Font.Gotham
        idBox.TextSize = 10
        idBox.TextXAlignment = Enum.TextXAlignment.Left
        idBox.TextTruncate = Enum.TextTruncate.AtEnd
        idBox.Parent = item
        getgenv().MusicIDLabels[tostring(trackID)] = idBox
        if getgenv().MusicIDStatus then
            getgenv().SetMusicIDStatus(trackID, getgenv().MusicIDStatus[tostring(trackID)])
        end
        local nameBox = Instance.new("TextBox")
        nameBox.Size = UDim2.new(0.36, -4, 1, -4)
        nameBox.Position = UDim2.new(0.24, 2, 0, 2)
        nameBox.BackgroundColor3 = Theme.Panel
        nameBox.Text = trackName
        nameBox.TextColor3 = Theme.Text
        RegisterThemedObject(nameBox, "BackgroundColor3", "Panel")
        RegisterThemedObject(nameBox, "TextColor3", "Text")
        nameBox.Font = Enum.Font.Gotham
        nameBox.TextSize = 10
        nameBox.ClearTextOnFocus = false
        nameBox.Parent = item
        local nbc = Instance.new("UICorner") nbc.CornerRadius = UDim.new(0, 3) nbc.Parent = nameBox
        nameBox.FocusLost:Connect(function()
            if nameBox.Text ~= "" then
                SavedIDs[idx].name = nameBox.Text
                AutoSaveConfiguration()
            end
        end)
        local pBtn = CreateDarkBtn("Play", UDim2.new(0.61, 0, 0.5, -9), UDim2.new(0, 28, 0, 18), item)
        pBtn.MouseButton1Click:Connect(function()
            Settings.CurrentTrackIndex = idx
            SoundInput.Text = tostring(trackID)
            SongNameInput.Text = nameBox.Text
            PlayMusicByID(trackID, nameBox.Text)
        end)
        local upBtn = CreateDarkBtn("Up", UDim2.new(0.61, 31, 0.5, -9), UDim2.new(0, 22, 0, 18), item)
        upBtn.MouseButton1Click:Connect(function()
            if idx > 1 then
                SavedIDs[idx], SavedIDs[idx - 1] = SavedIDs[idx - 1], SavedIDs[idx]
                AutoSaveConfiguration()
                RefreshMusicPlaylistUI()
            end
        end)
        local downBtn = CreateDarkBtn("Down", UDim2.new(0.61, 56, 0.5, -9), UDim2.new(0, 28, 0, 18), item)
        downBtn.MouseButton1Click:Connect(function()
            if idx < #SavedIDs then
                SavedIDs[idx], SavedIDs[idx + 1] = SavedIDs[idx + 1], SavedIDs[idx]
                AutoSaveConfiguration()
                RefreshMusicPlaylistUI()
            end
        end)
        local copyBtn = CreateDarkBtn("Copy", UDim2.new(0.61, 87, 0.5, -9), UDim2.new(0, 28, 0, 18), item)
        copyBtn.MouseButton1Click:Connect(function()
            if setclipboard then
                setclipboard(tostring(trackID))
                CustomNotify("Copied ID to clipboard", Color3.fromRGB(100, 255, 100))
            end
        end)
        local dBtn = CreateDarkBtn("X", UDim2.new(0.61, 118, 0.5, -9), UDim2.new(0, 18, 0, 18), item)
        dBtn.MouseButton1Click:Connect(function()
            table.remove(SavedIDs, idx)
            AutoSaveConfiguration()
            RefreshMusicPlaylistUI()
        end)
    end
end
getgenv().RefreshMusicPlaylistUI = RefreshMusicPlaylistUI
RefreshMusicPlaylistUI()
PlayBtn.MouseButton1Click:Connect(function()
    local id = tonumber(SoundInput.Text)
    local name = SongNameInput.Text ~= "" and SongNameInput.Text or ("Track " .. id)
    if id then PlayMusicByID(id, name) else CustomNotify("Invalid ID!", Color3.fromRGB(255, 100, 100)) end
end)
if MM2RadioBtn then
    MM2RadioBtn.MouseButton1Click:Connect(function()
        local id = tonumber(SoundInput.Text)
        if not id and SavedIDs[Settings.CurrentTrackIndex] then
            id = tonumber(SavedIDs[Settings.CurrentTrackIndex].id)
            if id then
                SoundInput.Text = tostring(id)
            end
        end
        if not id then
            CustomNotify("Select a song or enter an ID", Color3.fromRGB(255, 180, 70))
            return
        end
        if getgenv().ToxPlayMM2Radio then
            getgenv().ToxPlayMM2Radio(id)
        else
            CustomNotify("MM2 Radio is not ready", Color3.fromRGB(255, 180, 70))
        end
    end)
end
if AdminMusicBtn then
    AdminMusicBtn.MouseButton1Click:Connect(function()
        local id = tonumber(SoundInput.Text)
        if not id and SavedIDs[Settings.CurrentTrackIndex] then
            id = tonumber(SavedIDs[Settings.CurrentTrackIndex].id)
            if id then
                SoundInput.Text = tostring(id)
            end
        end
        if not id then
            CustomNotify("Select a song or enter an ID", Color3.fromRGB(255, 180, 70))
            return
        end
        if getgenv().ToxPlayAdminMusic then
            getgenv().ToxPlayAdminMusic(id)
        else
            CustomNotify("ADMIN Music is not ready", Color3.fromRGB(255, 180, 70))
        end
    end)
end
PauseBtn.MouseButton1Click:Connect(function()
    if getgenv().ActiveSound then
        if getgenv().ActiveSound.IsPlaying then getgenv().ActiveSound:Pause()
        else getgenv().ActiveSound:Resume() end
    end
end)
StopBtn.MouseButton1Click:Connect(function()
    if getgenv().ActiveSound then getgenv().ActiveSound:Stop() getgenv().ActiveSound:Destroy() getgenv().ActiveSound = nil end
end)
PrevBtn.MouseButton1Click:Connect(function()
    if #SavedIDs > 0 then
        Settings.CurrentTrackIndex = Settings.CurrentTrackIndex - 1
        if Settings.CurrentTrackIndex < 1 then Settings.CurrentTrackIndex = #SavedIDs end
        local track = SavedIDs[Settings.CurrentTrackIndex]
        SoundInput.Text = tostring(track.id)
        SongNameInput.Text = track.name
        PlayMusicByID(track.id, track.name)
    end
end)
NextBtn.MouseButton1Click:Connect(function()
    if #SavedIDs > 0 then
        Settings.CurrentTrackIndex = Settings.CurrentTrackIndex + 1
        if Settings.CurrentTrackIndex > #SavedIDs then Settings.CurrentTrackIndex = 1 end
        local track = SavedIDs[Settings.CurrentTrackIndex]
        SoundInput.Text = tostring(track.id)
        SongNameInput.Text = track.name
        PlayMusicByID(track.id, track.name)
    end
end)
LoopToggleBtn.MouseButton1Click:Connect(function()
    Settings.MusicLoop = not Settings.MusicLoop
    LoopToggleBtn.TextColor3 = Settings.MusicLoop and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(220, 220, 220)
    if getgenv().ActiveSound then getgenv().ActiveSound.Looped = Settings.MusicLoop end
    AutoSaveConfiguration()
end)
AutoPlayToggleBtn.MouseButton1Click:Connect(function()
    Settings.MusicAutoPlay = not Settings.MusicAutoPlay
    AutoPlayToggleBtn.TextColor3 = Settings.MusicAutoPlay and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(220, 220, 220)
    AutoSaveConfiguration()
end)
LoopToggleBtn.TextColor3 = Settings.MusicLoop and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(220, 220, 220)
AutoPlayToggleBtn.TextColor3 = Settings.MusicAutoPlay and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(220, 220, 220)
AddPlaylistBtn.MouseButton1Click:Connect(function()
    local id = tonumber(SoundInput.Text)
    local name = SongNameInput.Text ~= "" and SongNameInput.Text or ("Track " .. (id or 0))
    if id then
        table.insert(SavedIDs, {id = id, name = name})
        AutoSaveConfiguration()
        RefreshMusicPlaylistUI()
        CustomNotify("Added to Playlist!", Color3.fromRGB(100, 255, 100))
    else
        CustomNotify("Invalid ID!", Color3.fromRGB(255, 100, 100))
    end
end)
MusicCloseBtn.MouseButton1Click:Connect(function() MusicGui.Visible = false end)
if env.ApplySavedGuiPosition then
    pcall(env.ApplySavedGuiPosition, "ChatLog", env.ChatLogGui)
    pcall(env.ApplySavedGuiPosition, "Waypoints", env.WaypointsGui)
    pcall(env.ApplySavedGuiPosition, "Music", env.MusicGui)
end
if env.TrackGuiPosition then
    pcall(env.TrackGuiPosition, "ChatLog", env.ChatLogGui)
    pcall(env.TrackGuiPosition, "Waypoints", env.WaypointsGui)
    pcall(env.TrackGuiPosition, "Music", env.MusicGui)
end
end
do
if type(env.ToxLightingCleanup) == "function" then
    pcall(env.ToxLightingCleanup)
end
local LightingService = game:GetService("Lighting")
local LightingSettings = env.Settings or {}
local ToxLighting = {}
local ToxLightingState = {
    Main = nil,
    Effects = {},
    RemovedAtmosphere = {},
    RemovedSkyboxes = {},
    RemovedGrading = {},
    FixShadows = nil,
    ChildConnection = nil
}
local ToxLightingEffects = {
    SunRays = {
        Class = "SunRaysEffect",
        Name = "ToxSunRaysEffect",
        EnabledKey = "LightingSunRays",
        Properties = {
            Intensity = "LightingSunRaysIntensity",
            Spread = "LightingSunRaysSpread"
        }
    },
    Bloom = {
        Class = "BloomEffect",
        Name = "ToxBloomEffect",
        EnabledKey = "LightingBloom",
        Properties = {
            Intensity = "LightingBloomIntensity",
            Size = "LightingBloomSize",
            Threshold = "LightingBloomThreshold"
        }
    },
    ColorCorrection = {
        Class = "ColorCorrectionEffect",
        Name = "ToxColorCorrectionEffect",
        EnabledKey = "LightingColorCorrection",
        Properties = {
            Brightness = "LightingColorBrightness",
            Contrast = "LightingColorContrast",
            Saturation = "LightingColorSaturation"
        }
    },
    Blur = {
        Class = "BlurEffect",
        Name = "ToxBlurEffect",
        EnabledKey = "LightingBlur",
        Properties = {
            Size = "LightingBlurSize"
        }
    }
}
local function ToxLightingColor(name, fallback)
    local map = env.ColorMap
    local value = typeof(map) == "table" and map[tostring(name)] or nil
    return typeof(value) == "Color3" and value or fallback
end
local function ToxLightingTechnology(name)
    local wanted = tostring(name or "")
    for _, item in ipairs(Enum.Technology:GetEnumItems()) do
        if item.Name == wanted then
            return item
        end
    end
    return nil
end
local function ToxSetTechnology(value)
    local technology = typeof(value) == "EnumItem"
        and value
        or ToxLightingTechnology(value)
    if not technology then
        return false
    end
    local ok = pcall(function()
        LightingService.Technology = technology
    end)
    if not ok and type(sethiddenproperty) == "function" then
        ok = pcall(function()
            sethiddenproperty(LightingService, "Technology", technology)
        end)
    end
    return ok
end
local function ToxCaptureLightingMain()
    local snapshot = {
        Ambient = LightingService.Ambient,
        OutdoorAmbient = LightingService.OutdoorAmbient,
        ClockTime = LightingService.ClockTime,
        Brightness = LightingService.Brightness,
        ShadowSoftness = LightingService.ShadowSoftness,
        EnvironmentDiffuseScale = LightingService.EnvironmentDiffuseScale,
        EnvironmentSpecularScale = LightingService.EnvironmentSpecularScale,
        GlobalShadows = LightingService.GlobalShadows,
        FogColor = LightingService.FogColor,
        FogStart = LightingService.FogStart,
        FogEnd = LightingService.FogEnd
    }
    pcall(function()
        snapshot.Technology = LightingService.Technology
    end)
    return snapshot
end
local function ToxRestoreLightingMain()
    local snapshot = ToxLightingState.Main
    ToxLightingState.Main = nil
    if not snapshot then
        return
    end
    for property, value in pairs(snapshot) do
        if property == "Technology" then
            ToxSetTechnology(value)
        else
            pcall(function()
                LightingService[property] = value
            end)
        end
    end
end
local function ToxFindEffect(config)
    for _, object in ipairs(LightingService:GetChildren()) do
        if object:IsA(config.Class) then
            return object
        end
    end
    return nil
end
local function ToxCaptureEffect(key)
    local config = ToxLightingEffects[key]
    if not config then
        return nil
    end
    local state = ToxLightingState.Effects[key]
    if state
    and state.Instance
    and state.Instance.Parent then
        return state
    end
    local effect = ToxFindEffect(config)
    local created = false
    if not effect then
        effect = Instance.new(config.Class)
        effect.Name = config.Name
        effect.Parent = LightingService
        created = true
    end
    local snapshot = {
        Enabled = effect.Enabled
    }
    for property in pairs(config.Properties) do
        pcall(function()
            snapshot[property] = effect[property]
        end)
    end
    state = {
        Instance = effect,
        Created = created,
        Snapshot = snapshot
    }
    ToxLightingState.Effects[key] = state
    return state
end
local function ToxRestoreEffect(key)
    local state = ToxLightingState.Effects[key]
    ToxLightingState.Effects[key] = nil
    if not state or not state.Instance then
        return
    end
    if state.Created then
        pcall(function()
            state.Instance:Destroy()
        end)
        return
    end
    if not state.Instance.Parent then
        return
    end
    for property, value in pairs(state.Snapshot or {}) do
        pcall(function()
            state.Instance[property] = value
        end)
    end
end
local function ToxDetachLightingClass(className, store)
    for _, object in ipairs(LightingService:GetChildren()) do
        if object:IsA(className) and store[object] == nil then
            store[object] = object.Parent
            pcall(function()
                object.Parent = nil
            end)
        end
    end
end
local function ToxRestoreDetached(store)
    local copy = {}
    for object, parent in pairs(store) do
        copy[object] = parent
        store[object] = nil
    end
    for object, parent in pairs(copy) do
        if object and object.Parent == nil and parent then
            pcall(function()
                object.Parent = parent
            end)
        end
    end
end
local function ToxDisableGrading()
    for _, object in ipairs(LightingService:GetChildren()) do
        if object:IsA("ColorCorrectionEffect")
        and ToxLightingState.RemovedGrading[object] == nil then
            ToxLightingState.RemovedGrading[object] = object.Enabled
            pcall(function()
                object.Enabled = false
            end)
        end
    end
end
local function ToxRestoreGrading()
    local copy = {}
    for object, enabled in pairs(ToxLightingState.RemovedGrading) do
        copy[object] = enabled
        ToxLightingState.RemovedGrading[object] = nil
    end
    for object, enabled in pairs(copy) do
        if object and object.Parent then
            pcall(function()
                object.Enabled = enabled
            end)
        end
    end
end
function ToxLighting.RefreshMain()
    if not LightingSettings.AdjustLighting then
        return
    end
    pcall(function()
        LightingService.Ambient = ToxLightingColor(
            LightingSettings.LightingAmbientColorName,
            LightingService.Ambient
        )
    end)
    pcall(function()
        LightingService.OutdoorAmbient = ToxLightingColor(
            LightingSettings.LightingOutdoorAmbientColorName,
            LightingService.OutdoorAmbient
        )
    end)
    pcall(function()
        LightingService.ClockTime = math.clamp(
            tonumber(LightingSettings.LightingClockTime) or 14,
            0,
            24
        )
    end)
    pcall(function()
        LightingService.Brightness = math.clamp(
            tonumber(LightingSettings.LightingBrightness) or 1,
            0,
            10
        )
    end)
    pcall(function()
        LightingService.ShadowSoftness = math.clamp(
            tonumber(LightingSettings.LightingShadowSoftness) or 0.5,
            0,
            1
        )
    end)
    pcall(function()
        LightingService.EnvironmentDiffuseScale = math.clamp(
            tonumber(LightingSettings.LightingDiffuseScale) or 1,
            0,
            1
        )
    end)
    pcall(function()
        LightingService.EnvironmentSpecularScale = math.clamp(
            tonumber(LightingSettings.LightingSpecularScale) or 1,
            0,
            1
        )
    end)
    pcall(function()
        LightingService.GlobalShadows = LightingSettings.LightingGlobalShadows == true
    end)
    pcall(function()
        LightingService.FogColor = ToxLightingColor(
            LightingSettings.LightingFogColorName,
            LightingService.FogColor
        )
    end)
    pcall(function()
        LightingService.FogStart = math.clamp(
            tonumber(LightingSettings.LightingFogStart) or 0,
            0,
            1000000
        )
    end)
    pcall(function()
        LightingService.FogEnd = math.clamp(
            tonumber(LightingSettings.LightingFogEnd) or 100000,
            0,
            1000000
        )
    end)
    ToxSetTechnology(LightingSettings.LightingTechnology)
    if LightingSettings.LightingFixShadows then
        pcall(function()
            LightingService.GlobalShadows = false
            LightingService.ShadowSoftness = 0
        end)
    end
end
function ToxLighting.SetAdjust(enabled)
    enabled = enabled == true
    if enabled and LightingSettings.Fullbright then
        LightingSettings.Fullbright = false
        if type(env.UpdateFullbright) == "function" then
            pcall(env.UpdateFullbright)
        end
        if type(env.SyncToggleVisuals) == "function" then
            pcall(env.SyncToggleVisuals, "Fullbright", false)
        end
    end
    if enabled and type(ToxLighting.GetPreset) == "function" and ToxLighting.GetPreset() ~= "Off" then
        ToxLighting.ApplyPreset("Off")
    end
    local keepFixShadows = LightingSettings.LightingFixShadows == true
    LightingSettings.AdjustLighting = enabled
    if enabled then
        if not ToxLightingState.Main then
            ToxLightingState.Main = ToxCaptureLightingMain()
        end
        ToxLighting.RefreshMain()
    else
        if keepFixShadows and type(ToxLighting.SetFixShadows) == "function" then
            ToxLighting.SetFixShadows(false)
        end
        ToxRestoreLightingMain()
        if keepFixShadows and type(ToxLighting.SetFixShadows) == "function" then
            ToxLighting.SetFixShadows(true)
        end
    end
end
function ToxLighting.GetTechnology()
    local result = "Unknown"
    pcall(function()
        result = LightingService.Technology.Name
    end)
    return result
end
function ToxLighting.SetTechnology(name)
    LightingSettings.LightingTechnology = tostring(name or LightingSettings.LightingTechnology or "ShadowMap")
    if not LightingSettings.AdjustLighting then
        return true
    end
    return ToxSetTechnology(LightingSettings.LightingTechnology)
end
function ToxLighting.RefreshEffect(key)
    local config = ToxLightingEffects[key]
    if not config or LightingSettings[config.EnabledKey] ~= true then
        return
    end
    local state = ToxCaptureEffect(key)
    local effect = state and state.Instance
    if not effect then
        return
    end
    pcall(function()
        effect.Enabled = true
    end)
    for property, settingKey in pairs(config.Properties) do
        local value = tonumber(LightingSettings[settingKey])
        if value ~= nil then
            pcall(function()
                effect[property] = value
            end)
        end
    end
end
function ToxLighting.SetEffect(key, enabled)
    local config = ToxLightingEffects[key]
    if not config then
        return
    end
    enabled = enabled == true
    if key == "ColorCorrection"
    and enabled
    and LightingSettings.LightingRemoveGrading then
        ToxLighting.SetRemoveGrading(false)
        if type(env.SyncToggleVisuals) == "function" then
            pcall(env.SyncToggleVisuals, "LightingRemoveGrading", false)
        end
    end
    LightingSettings[config.EnabledKey] = enabled
    if enabled then
        ToxLighting.RefreshEffect(key)
    else
        ToxRestoreEffect(key)
    end
end
function ToxLighting.SetFixShadows(enabled)
    enabled = enabled == true
    LightingSettings.LightingFixShadows = enabled
    if enabled then
        if not ToxLightingState.FixShadows then
            ToxLightingState.FixShadows = {
                GlobalShadows = LightingService.GlobalShadows,
                ShadowSoftness = LightingService.ShadowSoftness
            }
        end
        pcall(function()
            LightingService.GlobalShadows = false
            LightingService.ShadowSoftness = 0
        end)
    else
        local snapshot = ToxLightingState.FixShadows
        ToxLightingState.FixShadows = nil
        if snapshot then
            pcall(function()
                LightingService.GlobalShadows = snapshot.GlobalShadows
                LightingService.ShadowSoftness = snapshot.ShadowSoftness
            end)
        end
        if LightingSettings.AdjustLighting then
            ToxLighting.RefreshMain()
        end
    end
end
function ToxLighting.SetRemoveAtmosphere(enabled)
    enabled = enabled == true
    LightingSettings.LightingRemoveAtmosphere = enabled
    if enabled then
        ToxDetachLightingClass("Atmosphere", ToxLightingState.RemovedAtmosphere)
    else
        ToxRestoreDetached(ToxLightingState.RemovedAtmosphere)
    end
end
function ToxLighting.SetRemoveSkyboxes(enabled)
    enabled = enabled == true
    LightingSettings.LightingRemoveSkyboxes = enabled
    if enabled then
        ToxDetachLightingClass("Sky", ToxLightingState.RemovedSkyboxes)
    else
        ToxRestoreDetached(ToxLightingState.RemovedSkyboxes)
    end
end
function ToxLighting.SetRemoveGrading(enabled)
    enabled = enabled == true
    if enabled and LightingSettings.LightingColorCorrection then
        ToxLighting.SetEffect("ColorCorrection", false)
        if type(env.SyncToggleVisuals) == "function" then
            pcall(env.SyncToggleVisuals, "LightingColorCorrection", false)
        end
    end
    LightingSettings.LightingRemoveGrading = enabled
    if enabled then
        ToxDisableGrading()
    else
        ToxRestoreGrading()
    end
end
local ToxPresetSkies = {
    Morning = {
        Bk = "rbxassetid://7879352266", Dn = "rbxassetid://7879347786", Ft = "rbxassetid://7879358161",
        Lf = "rbxassetid://7879393853", Rt = "rbxassetid://7879350066", Up = "rbxassetid://7879345023",
    },
    Midday = {
        Bk = "rbxassetid://11832250366", Dn = "rbxassetid://11832250656", Ft = "rbxassetid://11832250915",
        Lf = "rbxassetid://11832250090", Rt = "rbxassetid://11832249798", Up = "rbxassetid://11832257515",
    },
    Sunset = {
        Bk = "rbxassetid://225469345", Dn = "rbxassetid://225469349", Ft = "rbxassetid://225469359",
        Lf = "rbxassetid://225469364", Rt = "rbxassetid://225469372", Up = "rbxassetid://225469380",
    },
    Evening = {
        Bk = "rbxassetid://271042516", Dn = "rbxassetid://271077243", Ft = "rbxassetid://271042556",
        Lf = "rbxassetid://271042310", Rt = "rbxassetid://271042467", Up = "rbxassetid://271077958",
    },
}
local function RGB(r, g, b)
    return Color3.fromRGB(r, g, b)
end
local ToxLightingPresets = {
    Dawn = {
        Lighting = {
            ClockTime = 6, GeographicLatitude = 38, Brightness = 1.4, ExposureCompensation = 0,
            Ambient = RGB(54, 52, 66), OutdoorAmbient = RGB(112, 106, 126),
            ColorShift_Top = RGB(240, 190, 165), ColorShift_Bottom = RGB(90, 88, 120),
            EnvironmentDiffuseScale = 1, EnvironmentSpecularScale = 1, ShadowSoftness = 0.45, GlobalShadows = true,
        },
        Sky = { Faces = "Morning", StarCount = 700, SunAngularSize = 16, MoonAngularSize = 9 },
        Atmosphere = { Density = 0.38, Offset = 0.3, Color = RGB(205, 172, 170), Decay = RGB(96, 100, 138), Glare = 0.35, Haze = 1.8 },
        Clouds = { Cover = 0.55, Density = 0.55, Color = RGB(250, 214, 200) },
        Wind = Vector3.new(4, 0, 2),
        Bloom = { Intensity = 0.4, Size = 26, Threshold = 2 },
        ColorCorrection = { Brightness = 0, Contrast = 0.1, Saturation = 0.06, TintColor = RGB(255, 240, 234) },
        SunRays = { Intensity = 0.06, Spread = 0.7 },
        DepthOfField = { FarIntensity = 0.1, FocusDistance = 140, InFocusRadius = 140, NearIntensity = 0 },
        Water = { WaterColor = RGB(58, 80, 108), WaterReflectance = 1, WaterTransparency = 0.82, WaterWaveSize = 0.12, WaterWaveSpeed = 8 },
        Reflect = 0.25,
    },
    Morning = {
        Lighting = {
            ClockTime = 7.6, GeographicLatitude = 41, Brightness = 2, ExposureCompensation = -0.1,
            Ambient = RGB(62, 60, 64), OutdoorAmbient = RGB(132, 126, 122),
            ColorShift_Top = RGB(245, 225, 200), ColorShift_Bottom = RGB(110, 102, 96),
            EnvironmentDiffuseScale = 1, EnvironmentSpecularScale = 1, ShadowSoftness = 0.25, GlobalShadows = true,
        },
        Sky = { Faces = "Morning", StarCount = 0, SunAngularSize = 12 },
        Atmosphere = { Density = 0.3, Offset = 0.25, Color = RGB(204, 186, 166), Decay = RGB(104, 116, 134), Glare = 0.2, Haze = 1.3 },
        Clouds = { Cover = 0.52, Density = 0.45, Color = RGB(250, 244, 236) },
        Wind = Vector3.new(6, 0, 3),
        Bloom = { Intensity = 0.3, Size = 24, Threshold = 2.2 },
        ColorCorrection = { Brightness = 0, Contrast = 0.09, Saturation = 0.1, TintColor = RGB(255, 248, 238) },
        SunRays = { Intensity = 0.05, Spread = 0.6 },
        DepthOfField = { FarIntensity = 0.08, FocusDistance = 160, InFocusRadius = 160, NearIntensity = 0 },
        Water = { WaterColor = RGB(40, 96, 114), WaterReflectance = 1, WaterTransparency = 0.86, WaterWaveSize = 0.14, WaterWaveSpeed = 10 },
        Reflect = 0.2,
    },
    Midday = {
        Lighting = {
            ClockTime = 13.4, GeographicLatitude = 30, Brightness = 2.2, ExposureCompensation = -0.25,
            Ambient = RGB(70, 72, 80), OutdoorAmbient = RGB(140, 142, 150),
            ColorShift_Top = RGB(250, 248, 240), ColorShift_Bottom = RGB(104, 110, 120),
            EnvironmentDiffuseScale = 1, EnvironmentSpecularScale = 1, ShadowSoftness = 0.15, GlobalShadows = true,
        },
        Sky = { Faces = "Midday", StarCount = 0, SunAngularSize = 9 },
        Atmosphere = { Density = 0.27, Offset = 0.2, Color = RGB(194, 204, 218), Decay = RGB(92, 112, 144), Glare = 0, Haze = 0.8 },
        Clouds = { Cover = 0.62, Density = 0.5, Color = RGB(246, 248, 252) },
        Wind = Vector3.new(8, 0, 4),
        Bloom = { Intensity = 0.25, Size = 20, Threshold = 2.5 },
        ColorCorrection = { Brightness = -0.02, Contrast = 0.08, Saturation = 0.12, TintColor = RGB(255, 255, 252) },
        SunRays = { Intensity = 0.03, Spread = 0.4 },
        DepthOfField = { FarIntensity = 0.06, FocusDistance = 200, InFocusRadius = 200, NearIntensity = 0 },
        Water = { WaterColor = RGB(28, 108, 136), WaterReflectance = 1, WaterTransparency = 0.9, WaterWaveSize = 0.12, WaterWaveSpeed = 12 },
        Reflect = 0.15,
    },
    Sunset = {
        Lighting = {
            ClockTime = 17.6, GeographicLatitude = 41, Brightness = 1.8, ExposureCompensation = 0,
            Ambient = RGB(68, 52, 54), OutdoorAmbient = RGB(140, 110, 100),
            ColorShift_Top = RGB(240, 160, 110), ColorShift_Bottom = RGB(116, 76, 86),
            EnvironmentDiffuseScale = 1, EnvironmentSpecularScale = 1, ShadowSoftness = 0.3, GlobalShadows = true,
        },
        Sky = { Faces = "Sunset", StarCount = 0, SunAngularSize = 16 },
        Atmosphere = { Density = 0.34, Offset = 0.3, Color = RGB(240, 176, 134), Decay = RGB(118, 84, 106), Glare = 0.45, Haze = 1.8 },
        Clouds = { Cover = 0.58, Density = 0.55, Color = RGB(250, 184, 152) },
        Wind = Vector3.new(5, 0, 2),
        Bloom = { Intensity = 0.45, Size = 28, Threshold = 1.9 },
        ColorCorrection = { Brightness = 0, Contrast = 0.12, Saturation = 0.15, TintColor = RGB(255, 234, 214) },
        SunRays = { Intensity = 0.08, Spread = 0.85 },
        DepthOfField = { FarIntensity = 0.1, FocusDistance = 140, InFocusRadius = 140, NearIntensity = 0 },
        Water = { WaterColor = RGB(76, 68, 90), WaterReflectance = 1, WaterTransparency = 0.8, WaterWaveSize = 0.15, WaterWaveSpeed = 9 },
        Reflect = 0.3,
    },
    Evening = {
        Lighting = {
            ClockTime = 18.4, GeographicLatitude = 41, Brightness = 1.1, ExposureCompensation = 0.1,
            Ambient = RGB(50, 44, 62), OutdoorAmbient = RGB(98, 86, 114),
            ColorShift_Top = RGB(230, 130, 118), ColorShift_Bottom = RGB(72, 64, 110),
            EnvironmentDiffuseScale = 1, EnvironmentSpecularScale = 1, ShadowSoftness = 0.4, GlobalShadows = true,
        },
        Sky = { Faces = "Evening", StarCount = 1800, SunAngularSize = 16, MoonAngularSize = 10 },
        Atmosphere = { Density = 0.36, Offset = 0.26, Color = RGB(186, 136, 156), Decay = RGB(66, 58, 102), Glare = 0.3, Haze = 1.6 },
        Clouds = { Cover = 0.52, Density = 0.5, Color = RGB(204, 148, 168) },
        Wind = Vector3.new(4, 0, 2),
        Bloom = { Intensity = 0.5, Size = 30, Threshold = 1.7 },
        ColorCorrection = { Brightness = 0, Contrast = 0.13, Saturation = 0.08, TintColor = RGB(246, 230, 244) },
        SunRays = { Intensity = 0.06, Spread = 0.8 },
        DepthOfField = { FarIntensity = 0.1, FocusDistance = 120, InFocusRadius = 120, NearIntensity = 0 },
        Water = { WaterColor = RGB(50, 48, 80), WaterReflectance = 1, WaterTransparency = 0.8, WaterWaveSize = 0.15, WaterWaveSpeed = 8 },
        Reflect = 0.3,
    },
    Night = {
        Lighting = {
            ClockTime = 0.3, GeographicLatitude = 41, Brightness = 0.8, ExposureCompensation = 0.2,
            Ambient = RGB(32, 36, 54), OutdoorAmbient = RGB(58, 66, 100),
            ColorShift_Top = RGB(150, 172, 240), ColorShift_Bottom = RGB(38, 44, 82),
            EnvironmentDiffuseScale = 1, EnvironmentSpecularScale = 1, ShadowSoftness = 0.35, GlobalShadows = true,
        },
        Sky = { Faces = nil, StarCount = 6000, MoonAngularSize = 14 },
        Atmosphere = { Density = 0.32, Offset = 0.12, Color = RGB(64, 76, 116), Decay = RGB(22, 28, 52), Glare = 0.1, Haze = 0.7 },
        Clouds = { Cover = 0.4, Density = 0.35, Color = RGB(112, 124, 160) },
        Wind = Vector3.new(3, 0, 1),
        Bloom = { Intensity = 0.6, Size = 36, Threshold = 1.5 },
        ColorCorrection = { Brightness = 0, Contrast = 0.14, Saturation = -0.04, TintColor = RGB(214, 224, 255) },
        DepthOfField = { FarIntensity = 0.12, FocusDistance = 100, InFocusRadius = 100, NearIntensity = 0 },
        Water = { WaterColor = RGB(22, 32, 64), WaterReflectance = 1, WaterTransparency = 0.75, WaterWaveSize = 0.12, WaterWaveSpeed = 6 },
        Reflect = 0.35,
    },
    Overcast = {
        Lighting = {
            ClockTime = 14.5, GeographicLatitude = 41, Brightness = 1.1, ExposureCompensation = -0.05,
            Ambient = RGB(80, 84, 92), OutdoorAmbient = RGB(124, 130, 140),
            ColorShift_Top = RGB(205, 212, 222), ColorShift_Bottom = RGB(96, 102, 112),
            EnvironmentDiffuseScale = 1, EnvironmentSpecularScale = 0.9, ShadowSoftness = 0.8, GlobalShadows = true,
        },
        Sky = { Faces = "Midday", StarCount = 0, SunAngularSize = 7 },
        Atmosphere = { Density = 0.4, Offset = 0.18, Color = RGB(166, 174, 186), Decay = RGB(108, 116, 130), Glare = 0, Haze = 2.4 },
        Clouds = { Cover = 0.88, Density = 0.75, Color = RGB(190, 196, 206) },
        Wind = Vector3.new(12, 0, 6),
        Bloom = { Intensity = 0.2, Size = 22, Threshold = 2.6 },
        ColorCorrection = { Brightness = -0.01, Contrast = 0.1, Saturation = -0.1, TintColor = RGB(236, 242, 250) },
        DepthOfField = { FarIntensity = 0.14, FocusDistance = 100, InFocusRadius = 100, NearIntensity = 0 },
        Water = { WaterColor = RGB(54, 72, 82), WaterReflectance = 1, WaterTransparency = 0.78, WaterWaveSize = 0.2, WaterWaveSpeed = 14 },
        Reflect = 0.25,
    },
}
local ToxPresetOrder = { "Off", "Dawn", "Morning", "Midday", "Sunset", "Evening", "Night", "Overcast" }
local ToxPresetClasses = { "Sky", "Atmosphere", "BloomEffect", "ColorCorrectionEffect", "SunRaysEffect", "DepthOfFieldEffect" }
local ToxPresetFade = TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
local ToxPresetStart = {
    Atmosphere = { Density = 0, Offset = 0, Glare = 0, Haze = 0 },
    BloomEffect = { Intensity = 0, Size = 0 },
    ColorCorrectionEffect = { Brightness = 0, Contrast = 0, Saturation = 0, TintColor = RGB(255, 255, 255) },
    SunRaysEffect = { Intensity = 0 },
    DepthOfFieldEffect = { FarIntensity = 0, NearIntensity = 0 },
}
local ToxPresetState = {
    Active = nil,
    Lighting = nil,
    Water = nil,
    Wind = nil,
    Clouds = nil,
    CloudsCreated = false,
    Detached = {},
    Created = {},
    Connections = {},
    Tweens = {},
    Applying = false,
}
local function ToxPresetSet(object, props)
    for property, value in pairs(props) do
        pcall(function()
            object[property] = value
        end)
    end
end
local function ToxPresetTween(object, props, instant)
    if instant then
        ToxPresetSet(object, props)
        return
    end
    local tweenable, rest = {}, {}
    for property, value in pairs(props) do
        local kind = typeof(value)
        if kind == "number" or kind == "Color3" or kind == "Vector3" then
            tweenable[property] = value
        else
            rest[property] = value
        end
    end
    ToxPresetSet(object, rest)
    local ok, tween = pcall(function()
        return TweenService:Create(object, ToxPresetFade, tweenable)
    end)
    if ok and tween then
        table.insert(ToxPresetState.Tweens, tween)
        tween:Play()
    else
        ToxPresetSet(object, tweenable)
    end
end
local function ToxPresetStopTweens()
    for _, tween in ipairs(ToxPresetState.Tweens) do
        pcall(function()
            tween:Cancel()
        end)
    end
    table.clear(ToxPresetState.Tweens)
end
local function ToxPresetIsOwn(object)
    for _, created in ipairs(ToxPresetState.Created) do
        if created == object then
            return true
        end
    end
    return false
end
local function ToxPresetDetach(object)
    if ToxPresetIsOwn(object) or ToxPresetState.Detached[object] ~= nil then
        return
    end
    for _, className in ipairs(ToxPresetClasses) do
        if object:IsA(className) then
            ToxPresetState.Detached[object] = object.Parent
            pcall(function()
                object.Parent = nil
            end)
            return
        end
    end
end
local function ToxPresetDisconnect()
    for _, connection in ipairs(ToxPresetState.Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    table.clear(ToxPresetState.Connections)
end
local function ToxPresetRestore()
    ToxPresetDisconnect()
    ToxPresetStopTweens()
    for _, object in ipairs(ToxPresetState.Created) do
        pcall(function()
            object:Destroy()
        end)
    end
    table.clear(ToxPresetState.Created)
    ToxRestoreDetached(ToxPresetState.Detached)
    if ToxPresetState.Lighting then
        for property, value in pairs(ToxPresetState.Lighting) do
            if property == "Technology" then
                ToxSetTechnology(value)
            else
                pcall(function()
                    LightingService[property] = value
                end)
            end
        end
        ToxPresetState.Lighting = nil
    end
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if terrain and ToxPresetState.Water then
        ToxPresetSet(terrain, ToxPresetState.Water)
    end
    ToxPresetState.Water = nil
    if ToxPresetState.Clouds and ToxPresetState.Clouds.Instance and not ToxPresetState.CloudsCreated then
        ToxPresetSet(ToxPresetState.Clouds.Instance, ToxPresetState.Clouds.Snapshot)
    end
    ToxPresetState.Clouds = nil
    ToxPresetState.CloudsCreated = false
    if ToxPresetState.Wind then
        pcall(function()
            workspace.GlobalWind = ToxPresetState.Wind
        end)
        ToxPresetState.Wind = nil
    end
    ToxPresetState.Active = nil
    if type(ToxLighting.SetFloorOverride) == "function" then
        ToxLighting.SetFloorOverride(nil)
    end
    if type(ToxLighting.SetMirrorOverride) == "function" then
        ToxLighting.SetMirrorOverride(nil)
    end
end
local function ToxPresetClearForSwitch()
    ToxPresetDisconnect()
    ToxPresetStopTweens()
    for _, object in ipairs(ToxPresetState.Created) do
        pcall(function()
            object:Destroy()
        end)
    end
    table.clear(ToxPresetState.Created)
    if ToxPresetState.CloudsCreated then
        ToxPresetState.Clouds = nil
        ToxPresetState.CloudsCreated = false
    end
    ToxPresetState.Active = nil
end
local function ToxPresetCreate(className, name, props, instant)
    local object = Instance.new(className)
    object.Name = name
    local start = ToxPresetStart[className]
    if start and not instant then
        ToxPresetSet(object, props)
        ToxPresetSet(object, start)
    else
        ToxPresetSet(object, props)
    end
    table.insert(ToxPresetState.Created, object)
    object.Parent = LightingService
    if start and not instant then
        ToxPresetTween(object, props)
    end
    return object
end
local function ToxPresetApplyLighting(preset, instant)
    ToxPresetState.Applying = true
    ToxPresetTween(LightingService, preset.Lighting, instant)
    ToxSetTechnology("Future")
    task.delay(instant and 0 or ToxPresetFade.Time + 0.05, function()
        ToxPresetState.Applying = false
    end)
end
local function ToxPresetApplyClouds(preset, terrain, instant)
    if not terrain or not preset.Clouds then
        return
    end
    local existing = ToxPresetState.Clouds
    if existing and existing.Instance and existing.Instance.Parent and not ToxPresetState.CloudsCreated then
        ToxPresetTween(existing.Instance, preset.Clouds, instant)
        return
    end
    local clouds = terrain:FindFirstChildOfClass("Clouds")
    if clouds then
        local snapshot = {}
        for property in pairs(preset.Clouds) do
            pcall(function()
                snapshot[property] = clouds[property]
            end)
        end
        pcall(function()
            snapshot.Enabled = clouds.Enabled
        end)
        ToxPresetState.Clouds = { Instance = clouds, Snapshot = snapshot }
        ToxPresetState.CloudsCreated = false
        pcall(function()
            clouds.Enabled = true
        end)
    else
        local ok, created = pcall(function()
            local object = Instance.new("Clouds")
            object.Name = "ToxPresetClouds"
            object.Cover = 0
            object.Parent = terrain
            return object
        end)
        if not ok or not created then
            return
        end
        clouds = created
        table.insert(ToxPresetState.Created, clouds)
        ToxPresetState.Clouds = { Instance = clouds, Snapshot = {} }
        ToxPresetState.CloudsCreated = true
    end
    ToxPresetTween(clouds, preset.Clouds, instant)
end
function ToxLighting.GetPresetNames()
    return ToxPresetOrder
end
function ToxLighting.GetPreset()
    return ToxPresetState.Active or "Off"
end
function ToxLighting.ApplyPreset(name, instant)
    name = tostring(name or "Off")
    local preset = ToxLightingPresets[name]
    local switching = ToxPresetState.Active ~= nil and preset ~= nil
    if switching then
        ToxPresetClearForSwitch()
    elseif ToxPresetState.Active then
        ToxPresetRestore()
    end
    LightingSettings.LightingPreset = preset and name or "Off"
    if not preset then
        return
    end
    if LightingSettings.AdjustLighting then
        ToxLighting.SetAdjust(false)
        if type(env.SyncToggleVisuals) == "function" then
            pcall(env.SyncToggleVisuals, "AdjustLighting", false)
        end
    end
    if LightingSettings.Fullbright then
        LightingSettings.Fullbright = false
        if type(env.UpdateFullbright) == "function" then
            pcall(env.UpdateFullbright)
        end
        if type(env.SyncToggleVisuals) == "function" then
            pcall(env.SyncToggleVisuals, "Fullbright", false)
        end
    end
    local snapshot = ToxPresetState.Lighting or {}
    for property in pairs(preset.Lighting) do
        if snapshot[property] == nil then
            pcall(function()
                snapshot[property] = LightingService[property]
            end)
        end
    end
    if snapshot.Technology == nil then
        pcall(function()
            snapshot.Technology = LightingService.Technology
        end)
    end
    ToxPresetState.Lighting = snapshot
    for _, object in ipairs(LightingService:GetChildren()) do
        ToxPresetDetach(object)
    end
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if terrain and preset.Water then
        local water = ToxPresetState.Water or {}
        for property in pairs(preset.Water) do
            if water[property] == nil then
                pcall(function()
                    water[property] = terrain[property]
                end)
            end
        end
        ToxPresetState.Water = water
        ToxPresetTween(terrain, preset.Water, instant)
    end
    ToxPresetApplyClouds(preset, terrain, instant)
    if preset.Wind then
        pcall(function()
            if ToxPresetState.Wind == nil then
                ToxPresetState.Wind = workspace.GlobalWind
            end
            workspace.GlobalWind = preset.Wind
        end)
    end
    local skyProps = { CelestialBodiesShown = true, StarCount = preset.Sky.StarCount or 3000 }
    if preset.Sky.SunAngularSize then skyProps.SunAngularSize = preset.Sky.SunAngularSize end
    if preset.Sky.MoonAngularSize then skyProps.MoonAngularSize = preset.Sky.MoonAngularSize end
    local faces = preset.Sky.Faces and ToxPresetSkies[preset.Sky.Faces]
    if faces then
        skyProps.SkyboxBk = faces.Bk
        skyProps.SkyboxDn = faces.Dn
        skyProps.SkyboxFt = faces.Ft
        skyProps.SkyboxLf = faces.Lf
        skyProps.SkyboxRt = faces.Rt
        skyProps.SkyboxUp = faces.Up
    end
    ToxPresetCreate("Sky", "ToxPresetSky", skyProps, true)
    ToxPresetCreate("Atmosphere", "ToxPresetAtmosphere", preset.Atmosphere, instant)
    ToxPresetCreate("BloomEffect", "ToxPresetBloom", preset.Bloom, instant)
    ToxPresetCreate("ColorCorrectionEffect", "ToxPresetColor", preset.ColorCorrection, instant)
    if preset.SunRays then
        ToxPresetCreate("SunRaysEffect", "ToxPresetSunRays", preset.SunRays, instant)
    end
    if preset.DepthOfField then
        ToxPresetCreate("DepthOfFieldEffect", "ToxPresetDepth", preset.DepthOfField, instant)
    end
    ToxPresetApplyLighting(preset, instant)
    ToxPresetState.Active = name
    if type(ToxLighting.SetFloorOverride) == "function" then
        ToxLighting.SetFloorOverride(preset.Reflect)
    end
    if type(ToxLighting.SetMirrorOverride) == "function" then
        ToxLighting.SetMirrorOverride(preset.Reflect and (0.2 + preset.Reflect) or nil)
    end
    table.insert(ToxPresetState.Connections, LightingService.ChildAdded:Connect(function(object)
        task.defer(function()
            if ToxPresetState.Active then
                ToxPresetDetach(object)
            end
        end)
    end))
    local pending = false
    table.insert(ToxPresetState.Connections, LightingService.Changed:Connect(function(property)
        if ToxPresetState.Applying or pending or not ToxPresetState.Active then
            return
        end
        if preset.Lighting[property] == nil then
            return
        end
        pending = true
        task.delay(0.1, function()
            pending = false
            if ToxPresetState.Active == name and not ToxPresetState.Applying then
                ToxPresetApplyLighting(preset, true)
            end
        end)
    end))
end
local ToxFloorState = {
    Parts = setmetatable({}, { __mode = "k" }),
    Override = nil,
    Connection = nil,
}
local function ToxIsFloorPart(object)
    if not object:IsA("BasePart") or not object.Anchored or object.Transparency >= 0.9 then
        return false
    end
    if object:IsA("Terrain") or string.sub(object.Name, 1, 3) == "Tox" then
        return false
    end
    if object.Material == Enum.Material.Water or object.Material == Enum.Material.Glass then
        return false
    end
    local size = object.Size
    if math.min(size.X, size.Z) < 6 or size.Y > math.min(size.X, size.Z) * 0.5 then
        return false
    end
    local up = object.CFrame.UpVector
    if math.abs(up.Y) < 0.9 then
        return false
    end
    local model = object:FindFirstAncestorOfClass("Model")
    if model and model:FindFirstChildOfClass("Humanoid") then
        return false
    end
    return true
end
local function ToxFloorAmount()
    local amount = 0
    if LightingSettings.LightingFloorReflect then
        amount = math.clamp(tonumber(LightingSettings.LightingFloorReflectAmount) or 35, 0, 100) / 100
    end
    if ToxFloorState.Override then
        amount = math.max(amount, ToxFloorState.Override)
    end
    return amount
end
local function ToxFloorActive()
    return LightingSettings.LightingFloorReflect == true or ToxFloorState.Override ~= nil
end
local function ToxApplyFloor(object)
    if not ToxIsFloorPart(object) then
        return
    end
    if ToxFloorState.Parts[object] == nil then
        ToxFloorState.Parts[object] = object.Reflectance
    end
    pcall(function()
        object.Reflectance = math.max(ToxFloorState.Parts[object], ToxFloorAmount())
    end)
end
local function ToxFloorSync()
    if ToxFloorActive() then
        if not ToxFloorState.Connection then
            for _, object in ipairs(workspace:GetDescendants()) do
                ToxApplyFloor(object)
            end
            ToxFloorState.Connection = workspace.DescendantAdded:Connect(function(object)
                if object:IsA("BasePart") then
                    task.defer(ToxApplyFloor, object)
                end
            end)
        else
            local amount = ToxFloorAmount()
            for object, original in pairs(ToxFloorState.Parts) do
                if object and object.Parent then
                    pcall(function()
                        object.Reflectance = math.max(original, amount)
                    end)
                end
            end
        end
        return
    end
    if ToxFloorState.Connection then
        pcall(function()
            ToxFloorState.Connection:Disconnect()
        end)
        ToxFloorState.Connection = nil
    end
    for object, original in pairs(ToxFloorState.Parts) do
        if object and object.Parent then
            pcall(function()
                object.Reflectance = original
            end)
        end
        ToxFloorState.Parts[object] = nil
    end
end
function ToxLighting.SetFloorReflections(enabled)
    LightingSettings.LightingFloorReflect = enabled == true
    ToxFloorSync()
end
function ToxLighting.SetFloorOverride(amount)
    ToxFloorState.Override = tonumber(amount)
    ToxFloorSync()
end
function ToxLighting.RefreshFloorReflections()
    ToxFloorSync()
end
local RunService = game:GetService("RunService")
local ToxMirrorState = {
    Folder = nil,
    Rigs = {},
    Floors = setmetatable({}, { __mode = "k" }),
    Connection = nil,
    Override = nil,
    RayClock = 0,
}
local ToxMirrorFlip = CFrame.Angles(0, 0, math.pi)
local ToxMirrorKeep = { SpecialMesh = true, Decal = true, Texture = true, SurfaceAppearance = true, BlockMesh = true, CylinderMesh = true }
local function ToxMirrorStrength()
    local amount = 0
    if LightingSettings.LightingMirror then
        amount = math.clamp(tonumber(LightingSettings.LightingMirrorStrength) or 45, 0, 100) / 100
    end
    if ToxMirrorState.Override then
        amount = math.max(amount, ToxMirrorState.Override)
    end
    return amount
end
local function ToxMirrorActive()
    return LightingSettings.LightingMirror == true or ToxMirrorState.Override ~= nil
end
local function ToxMirrorFolder()
    local camera = workspace.CurrentCamera
    if not ToxMirrorState.Folder or not ToxMirrorState.Folder.Parent then
        local folder = Instance.new("Folder")
        folder.Name = "ToxMirrorReflections"
        folder.Parent = camera
        ToxMirrorState.Folder = folder
    elseif ToxMirrorState.Folder.Parent ~= camera and camera then
        ToxMirrorState.Folder.Parent = camera
    end
    return ToxMirrorState.Folder
end
local function ToxMirrorDropRig(character)
    local rig = ToxMirrorState.Rigs[character]
    ToxMirrorState.Rigs[character] = nil
    if rig then
        if rig.Watch then
            pcall(function()
                rig.Watch:Disconnect()
            end)
        end
        for _, clone in pairs(rig.Parts) do
            pcall(function()
                clone:Destroy()
            end)
        end
    end
end
local function ToxMirrorClonePart(source)
    local ok, clone = pcall(function()
        local archivable = source.Archivable
        source.Archivable = true
        local copy = source:Clone()
        source.Archivable = archivable
        return copy
    end)
    if not ok or not clone then
        return nil
    end
    for _, child in ipairs(clone:GetChildren()) do
        if not ToxMirrorKeep[child.ClassName] then
            child:Destroy()
        end
    end
    clone.Name = "ToxMirrorPart"
    clone.Anchored = true
    clone.CanCollide = false
    clone.CanQuery = false
    clone.CanTouch = false
    clone.CastShadow = false
    clone.Parent = ToxMirrorFolder()
    return clone
end
local function ToxMirrorBuildRig(character)
    local rig = { Parts = {}, FloorY = nil, FloorPart = nil }
    for _, object in ipairs(character:GetDescendants()) do
        if object:IsA("BasePart") and object.Name ~= "HumanoidRootPart" and object.Transparency < 1 then
            local clone = ToxMirrorClonePart(object)
            if clone then
                rig.Parts[object] = clone
            end
        end
    end
    rig.Watch = character.DescendantAdded:Connect(function(object)
        if object:IsA("BasePart") then
            rig.Dirty = true
        end
    end)
    ToxMirrorState.Rigs[character] = rig
    return rig
end
local ToxMirrorRayParams = RaycastParams.new()
ToxMirrorRayParams.FilterType = Enum.RaycastFilterType.Exclude
local function ToxMirrorFindFloor(root, exclude)
    ToxMirrorRayParams.FilterDescendantsInstances = exclude
    local hit = workspace:Raycast(root.Position, Vector3.new(0, -14, 0), ToxMirrorRayParams)
    if not hit or not hit.Instance or hit.Instance:IsA("Terrain") then
        return nil, nil
    end
    if hit.Normal.Y < 0.9 then
        return nil, nil
    end
    return hit.Position.Y, hit.Instance
end
local function ToxMirrorSetFloor(part, strength)
    if not part or not part:IsA("BasePart") then
        return
    end
    if ToxMirrorState.Floors[part] == nil then
        ToxMirrorState.Floors[part] = part.Transparency
    end
    local original = ToxMirrorState.Floors[part]
    pcall(function()
        part.Transparency = math.max(original, strength)
    end)
end
local function ToxMirrorRestoreFloors()
    for part, original in pairs(ToxMirrorState.Floors) do
        if part and part.Parent then
            pcall(function()
                part.Transparency = original
            end)
        end
        ToxMirrorState.Floors[part] = nil
    end
end
local function ToxMirrorStep(delta)
    local strength = ToxMirrorStrength()
    local camera = workspace.CurrentCamera
    if strength <= 0 or not camera then
        return
    end
    local players = game:GetService("Players")
    local alive = {}
    local exclude = { ToxMirrorFolder() }
    for _, player in ipairs(players:GetPlayers()) do
        if player.Character then
            table.insert(exclude, player.Character)
        end
    end
    ToxMirrorState.RayClock += delta
    local refreshFloors = ToxMirrorState.RayClock >= 0.15
    if refreshFloors then
        ToxMirrorState.RayClock = 0
    end
    local cameraPos = camera.CFrame.Position
    for _, player in ipairs(players:GetPlayers()) do
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if root and humanoid and humanoid.Health > 0 and (root.Position - cameraPos).Magnitude < 220 then
            alive[character] = true
            local rig = ToxMirrorState.Rigs[character]
            if rig and rig.Dirty then
                ToxMirrorDropRig(character)
                rig = nil
            end
            rig = rig or ToxMirrorBuildRig(character)
            if refreshFloors or not rig.FloorY then
                local floorY, floorPart = ToxMirrorFindFloor(root, exclude)
                rig.FloorY, rig.FloorPart = floorY, floorPart
                if floorPart then
                    ToxMirrorSetFloor(floorPart, strength)
                end
            end
            local floorY = rig.FloorY
            local height = floorY and (root.Position.Y - floorY) or math.huge
            local fade = math.clamp((height - 3) / 9, 0, 1)
            for source, clone in pairs(rig.Parts) do
                if source.Parent and floorY and fade < 1 then
                    local cf = source.CFrame
                    local p = cf.Position
                    clone.CFrame = CFrame.new(p.X, 2 * floorY - p.Y, p.Z) * ToxMirrorFlip * cf.Rotation
                    local base = math.max(source.Transparency, source.LocalTransparencyModifier)
                    clone.Transparency = math.max(base, 0.15 + fade * 0.85)
                else
                    clone.Transparency = 1
                end
            end
        end
    end
    for character in pairs(ToxMirrorState.Rigs) do
        if not alive[character] then
            ToxMirrorDropRig(character)
        end
    end
end
local function ToxMirrorSync()
    if ToxMirrorActive() then
        if not ToxMirrorState.Connection then
            ToxMirrorState.Connection = RunService.RenderStepped:Connect(function(delta)
                pcall(ToxMirrorStep, delta)
            end)
        end
        local strength = ToxMirrorStrength()
        for part in pairs(ToxMirrorState.Floors) do
            ToxMirrorSetFloor(part, strength)
        end
        return
    end
    if ToxMirrorState.Connection then
        pcall(function()
            ToxMirrorState.Connection:Disconnect()
        end)
        ToxMirrorState.Connection = nil
    end
    for character in pairs(ToxMirrorState.Rigs) do
        ToxMirrorDropRig(character)
    end
    if ToxMirrorState.Folder then
        pcall(function()
            ToxMirrorState.Folder:Destroy()
        end)
        ToxMirrorState.Folder = nil
    end
    ToxMirrorRestoreFloors()
end
function ToxLighting.SetMirrorReflections(enabled)
    LightingSettings.LightingMirror = enabled == true
    ToxMirrorSync()
end
function ToxLighting.SetMirrorOverride(amount)
    ToxMirrorState.Override = tonumber(amount)
    ToxMirrorSync()
end
function ToxLighting.RefreshMirrorReflections()
    ToxMirrorSync()
end
function ToxLighting.Reset(syncVisuals)
    ToxLighting.ApplyPreset("Off")
    ToxLighting.SetMirrorReflections(false)
    ToxLighting.SetFloorReflections(false)
    ToxLighting.SetFixShadows(false)
    ToxLighting.SetAdjust(false)
    ToxLighting.SetEffect("SunRays", false)
    ToxLighting.SetEffect("Bloom", false)
    ToxLighting.SetEffect("ColorCorrection", false)
    ToxLighting.SetEffect("Blur", false)
    ToxLighting.SetRemoveAtmosphere(false)
    ToxLighting.SetRemoveSkyboxes(false)
    ToxLighting.SetRemoveGrading(false)
    LightingSettings.AdjustLighting = false
    LightingSettings.LightingSunRays = false
    LightingSettings.LightingBloom = false
    LightingSettings.LightingColorCorrection = false
    LightingSettings.LightingBlur = false
    LightingSettings.LightingFixShadows = false
    LightingSettings.LightingRemoveAtmosphere = false
    LightingSettings.LightingRemoveSkyboxes = false
    LightingSettings.LightingRemoveGrading = false
    LightingSettings.LightingGlobalShadows = false
    if LightingSettings.Fullbright then
        LightingSettings.Fullbright = false
        if type(env.UpdateFullbright) == "function" then
            pcall(env.UpdateFullbright)
        end
    end
    if syncVisuals ~= false and type(env.SyncToggleVisuals) == "function" then
        for _, key in ipairs({
            "AdjustLighting",
            "LightingSunRays",
            "LightingBloom",
            "LightingColorCorrection",
            "LightingBlur",
            "LightingFixShadows",
            "LightingRemoveAtmosphere",
            "LightingRemoveSkyboxes",
            "LightingRemoveGrading",
            "LightingGlobalShadows",
            "LightingFloorReflect",
            "LightingMirror",
            "Fullbright"
        }) do
            pcall(env.SyncToggleVisuals, key, false)
        end
    end
end
ToxLightingState.ChildConnection = LightingService.ChildAdded:Connect(function(object)
    task.defer(function()
        if LightingSettings.LightingRemoveAtmosphere and object:IsA("Atmosphere") then
            if ToxLightingState.RemovedAtmosphere[object] == nil then
                ToxLightingState.RemovedAtmosphere[object] = LightingService
                pcall(function()
                    object.Parent = nil
                end)
            end
            return
        end
        if LightingSettings.LightingRemoveSkyboxes and object:IsA("Sky") then
            if ToxLightingState.RemovedSkyboxes[object] == nil then
                ToxLightingState.RemovedSkyboxes[object] = LightingService
                pcall(function()
                    object.Parent = nil
                end)
            end
            return
        end
        if LightingSettings.LightingRemoveGrading and object:IsA("ColorCorrectionEffect") then
            if ToxLightingState.RemovedGrading[object] == nil then
                ToxLightingState.RemovedGrading[object] = object.Enabled
                pcall(function()
                    object.Enabled = false
                end)
            end
        end
    end)
end)
env.ToxLighting = ToxLighting
env.ToxLightingCleanup = function()
    pcall(function()
        ToxLighting.Reset(false)
    end)
    if ToxLightingState.ChildConnection then
        pcall(function()
            ToxLightingState.ChildConnection:Disconnect()
        end)
        ToxLightingState.ChildConnection = nil
    end
    if env.ToxLighting == ToxLighting then
        env.ToxLighting = nil
    end
end
end
