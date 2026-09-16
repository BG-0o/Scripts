getgenv().ToxModule2SplitVersion = "2026-09-16-lighting-controller-2"
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local SoundService = game:GetService("SoundService")
local Player = Players.LocalPlayer
local env = getgenv()

if env.Destroyed then
    return
end

for _, key in ipairs({"ChatLogGui", "WaypointsGui", "MusicGui"}) do
    local object = env[key]
    if typeof(object) == "Instance" and object.Parent then
        pcall(function() object:Destroy() end)
    end
    env[key] = nil
end

local ChatLogGui = Instance.new("Frame")
ChatLogGui.Name = "ChatLogFrame"
ChatLogGui.Size = UDim2.new(0, 360, 0, 240)
ChatLogGui.Position = UDim2.new(0.5, 180, 0.5, -120)
ChatLogGui.BackgroundColor3 = Color3.fromRGB(10, 10, 16)
ChatLogGui.BorderSizePixel = 0
ChatLogGui.ClipsDescendants = true
ChatLogGui.Visible = false
ChatLogGui.Parent = Gui
getgenv().ChatLogGui = ChatLogGui

local ChatLogCorner = Instance.new("UICorner") ChatLogCorner.CornerRadius = UDim.new(0, 8) ChatLogCorner.Parent = ChatLogGui
local ChatLogStroke = Instance.new("UIStroke") ChatLogStroke.Color = MAIN_COLOR ChatLogStroke.Thickness = 2 ChatLogStroke.Parent = ChatLogGui

local ChatLogTopBar = Instance.new("Frame")
ChatLogTopBar.Size = UDim2.new(1, 0, 0, 32)
ChatLogTopBar.BackgroundColor3 = MAIN_COLOR
ChatLogTopBar.BorderSizePixel = 0
ChatLogTopBar.Parent = ChatLogGui

MakeDraggable(ChatLogGui, ChatLogTopBar)

local ChatLogTitle = Instance.new("TextLabel")
ChatLogTitle.Size = UDim2.new(1, -110, 1, 0)
ChatLogTitle.Position = UDim2.new(0, 10, 0, 0)
ChatLogTitle.BackgroundTransparency = 1
ChatLogTitle.Text = "Chat Logs"
ChatLogTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
ChatLogTitle.Font = Enum.Font.GothamBold
ChatLogTitle.TextSize = 13
ChatLogTitle.TextXAlignment = Enum.TextXAlignment.Left
ChatLogTitle.Parent = ChatLogTopBar

local ChatLogMinBtn = Instance.new("TextButton")
ChatLogMinBtn.Size = UDim2.new(0, 24, 0, 22)
ChatLogMinBtn.Position = UDim2.new(1, -88, 0.5, -11)
ChatLogMinBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 35)
ChatLogMinBtn.BorderSizePixel = 0
ChatLogMinBtn.Text = "-"
ChatLogMinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ChatLogMinBtn.Font = Enum.Font.GothamBold
ChatLogMinBtn.TextSize = 14
ChatLogMinBtn.Parent = ChatLogTopBar
local ChatLogMinCorner = Instance.new("UICorner") ChatLogMinCorner.CornerRadius = UDim.new(0, 4) ChatLogMinCorner.Parent = ChatLogMinBtn

local ClearBtn = Instance.new("TextButton")
ClearBtn.Size = UDim2.new(0, 52, 0, 22)
ClearBtn.Position = UDim2.new(1, -60, 0.5, -11)
ClearBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 35)
ClearBtn.BorderSizePixel = 0
ClearBtn.Text = "Clear"
ClearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
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
    msgLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
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

local WaypointsGui = Instance.new("Frame")
WaypointsGui.Name = "ToxWaypointsFrame"
WaypointsGui.Size = UDim2.new(0, 360, 0, 320)
WaypointsGui.Position = UDim2.new(0.5, -180, 0.5, -160)
WaypointsGui.BackgroundColor3 = Color3.fromRGB(10, 10, 16)
WaypointsGui.BorderSizePixel = 0
WaypointsGui.ClipsDescendants = true
WaypointsGui.Visible = false
WaypointsGui.Parent = Gui
getgenv().WaypointsGui = WaypointsGui

local WayCorner = Instance.new("UICorner") WayCorner.CornerRadius = UDim.new(0, 8) WayCorner.Parent = WaypointsGui
local WayStroke = Instance.new("UIStroke") WayStroke.Color = MAIN_COLOR WayStroke.Thickness = 2 WayStroke.Parent = WaypointsGui

local WayTopBar = Instance.new("Frame")
WayTopBar.Size = UDim2.new(1, 0, 0, 32)
WayTopBar.BackgroundColor3 = MAIN_COLOR
WayTopBar.BorderSizePixel = 0
WayTopBar.Parent = WaypointsGui

MakeDraggable(WaypointsGui, WayTopBar)

local WayTitle = Instance.new("TextLabel")
WayTitle.Size = UDim2.new(1, -40, 1, 0)
WayTitle.Position = UDim2.new(0, 10, 0, 0)
WayTitle.BackgroundTransparency = 1
WayTitle.Text = "Tox Waypoints"
WayTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
WayTitle.Font = Enum.Font.GothamBold
WayTitle.TextSize = 13
WayTitle.TextXAlignment = Enum.TextXAlignment.Left
WayTitle.Parent = WayTopBar

local WayCloseBtn = Instance.new("TextButton")
WayCloseBtn.Size = UDim2.new(0, 22, 0, 20)
WayCloseBtn.Position = UDim2.new(1, -26, 0.5, -10)
WayCloseBtn.BackgroundColor3 = Color3.fromRGB(24, 24, 34)
WayCloseBtn.BorderSizePixel = 0
WayCloseBtn.Text = "X"
WayCloseBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
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
    b.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 10
    b.Parent = parent
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 4) c.Parent = b
    return b
end
getgenv().CreateDarkBtn = CreateDarkBtn

local function CreateWayCoordInput(placeholder, position)
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0.21, 0, 0, 26)
    box.Position = position
    box.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
    box.BorderSizePixel = 0
    box.PlaceholderText = placeholder
    box.Text = ""
    box.TextColor3 = Color3.fromRGB(240, 240, 240)
    box.Font = Enum.Font.Gotham
    box.TextSize = 10
    box.ClearTextOnFocus = false
    box.Parent = WayContent
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = box
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
WayNameInput.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
WayNameInput.PlaceholderText = "Waypoint Name"
WayNameInput.Text = ""
WayNameInput.TextColor3 = Color3.fromRGB(240, 240, 240)
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
WayScroll.ScrollBarImageColor3 = MAIN_COLOR
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
        item.BackgroundColor3 = Color3.fromRGB(16, 16, 24)
        item.BorderSizePixel = 0
        item.Parent = WayScroll
        local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 4) c.Parent = item

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.42, -4, 1, 0)
        lbl.Position = UDim2.new(0, 6, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = wp.name
        lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
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

local MusicGui = Instance.new("Frame")
MusicGui.Name = "ToxMusicPlayerFrame"
MusicGui.Size = UDim2.new(0, 370, 0, 310)
MusicGui.Position = UDim2.new(0.5, -185, 0.5, -155)
MusicGui.BackgroundColor3 = Color3.fromRGB(10, 10, 16)
MusicGui.BorderSizePixel = 0
MusicGui.ClipsDescendants = true
MusicGui.Visible = false
MusicGui.Parent = Gui
getgenv().MusicGui = MusicGui

local MusicCorner = Instance.new("UICorner") MusicCorner.CornerRadius = UDim.new(0, 8) MusicCorner.Parent = MusicGui
local MusicStroke = Instance.new("UIStroke") MusicStroke.Color = MAIN_COLOR MusicStroke.Thickness = 2 MusicStroke.Parent = MusicGui

local MusicTopBar = Instance.new("Frame")
MusicTopBar.Size = UDim2.new(1, 0, 0, 32)
MusicTopBar.BackgroundColor3 = MAIN_COLOR
MusicTopBar.BorderSizePixel = 0
MusicTopBar.Parent = MusicGui

MakeDraggable(MusicGui, MusicTopBar)

local MusicTitle = Instance.new("TextLabel")
MusicTitle.Size = UDim2.new(1, -40, 1, 0)
MusicTitle.Position = UDim2.new(0, 10, 0, 0)
MusicTitle.BackgroundTransparency = 1
MusicTitle.Text = "Tox Music Player"
MusicTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
MusicTitle.Font = Enum.Font.GothamBold
MusicTitle.TextSize = 13
MusicTitle.TextXAlignment = Enum.TextXAlignment.Left
MusicTitle.Parent = MusicTopBar

local MusicCloseBtn = Instance.new("TextButton")
MusicCloseBtn.Size = UDim2.new(0, 22, 0, 20)
MusicCloseBtn.Position = UDim2.new(1, -26, 0.5, -10)
MusicCloseBtn.BackgroundColor3 = Color3.fromRGB(24, 24, 34)
MusicCloseBtn.BorderSizePixel = 0
MusicCloseBtn.Text = "X"
MusicCloseBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
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
SoundInput.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
SoundInput.PlaceholderText = "ID"
SoundInput.Text = ""
SoundInput.TextColor3 = Color3.fromRGB(255, 255, 255)
SoundInput.Font = Enum.Font.Gotham
SoundInput.TextSize = 11
SoundInput.Parent = InputArea
local SoundInputCorner = Instance.new("UICorner") SoundInputCorner.CornerRadius = UDim.new(0, 4) SoundInputCorner.Parent = SoundInput

local SongNameInput = Instance.new("TextBox")
SongNameInput.Size = UDim2.new(0.42, 0, 1, 0)
SongNameInput.Position = UDim2.new(0.43, 0, 0, 0)
SongNameInput.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
SongNameInput.PlaceholderText = "Name"
SongNameInput.Text = ""
SongNameInput.TextColor3 = Color3.fromRGB(255, 255, 255)
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
VolumeArea.Size = UDim2.new(1, 0, 0, 22)
VolumeArea.Position = UDim2.new(0, 0, 0, 60)
VolumeArea.BackgroundTransparency = 1
VolumeArea.Parent = MusicContent

local VolLabel = Instance.new("TextLabel")
VolLabel.Size = UDim2.new(0.13, 0, 1, 0)
VolLabel.Position = UDim2.new(0, 0, 0, 0)
VolLabel.BackgroundTransparency = 1
VolLabel.Text = "Vol"
VolLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
VolLabel.Font = Enum.Font.GothamBold
VolLabel.TextSize = 10
VolLabel.TextXAlignment = Enum.TextXAlignment.Left
VolLabel.Parent = VolumeArea

local VolInput = Instance.new("TextBox")
VolInput.Size = UDim2.new(0.13, 0, 1, 0)
VolInput.Position = UDim2.new(0.13, 0, 0, 0)
VolInput.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
VolInput.BorderSizePixel = 0
VolInput.Text = tostring(Settings.MusicVolume)
VolInput.PlaceholderText = "0-100"
VolInput.TextColor3 = Color3.fromRGB(255, 255, 255)
VolInput.Font = Enum.Font.Gotham
VolInput.TextSize = 10
VolInput.ClearTextOnFocus = false
VolInput.Parent = VolumeArea
local VolInputCorner = Instance.new("UICorner")
VolInputCorner.CornerRadius = UDim.new(0, 4)
VolInputCorner.Parent = VolInput

local function ApplyMusicVolume(value)
    local number = math.clamp(
        math.floor((tonumber(value) or Settings.MusicVolume or 100) + 0.5),
        0,
        100
    )

    Settings.MusicVolume = number
    VolInput.Text = tostring(number)

    if getgenv().ActiveSound then
        getgenv().ActiveSound.Volume = number / 100
    end

    AutoSaveConfiguration()
end

VolInput.FocusLost:Connect(function()
    ApplyMusicVolume(VolInput.Text)
end)

local VolDownBtn = CreateDarkBtn("-", UDim2.new(0.27, 0, 0, 0), UDim2.new(0.07, 0, 1, 0), VolumeArea)
VolDownBtn.MouseButton1Click:Connect(function()
    ApplyMusicVolume((Settings.MusicVolume or 100) - 1)
end)

local VolUpBtn = CreateDarkBtn("+", UDim2.new(0.35, 0, 0, 0), UDim2.new(0.07, 0, 1, 0), VolumeArea)
VolUpBtn.MouseButton1Click:Connect(function()
    ApplyMusicVolume((Settings.MusicVolume or 100) + 1)
end)

local CheckMusicIDsBtn = CreateDarkBtn("Check IDs", UDim2.new(0.44, 0, 0, 0), UDim2.new(0.27, 0, 1, 0), VolumeArea)
getgenv().CheckMusicIDsBtn = CheckMusicIDsBtn

local MM2RadioBtn = nil
local AdminMusicBtn = nil

if game.PlaceId == 142823291 then
    MM2RadioBtn = CreateDarkBtn("Radio", UDim2.new(0.73, 0, 0, 0), UDim2.new(0.27, 0, 1, 0), VolumeArea)
elseif game.PlaceId == 4522347649 then
    AdminMusicBtn = CreateDarkBtn("Music", UDim2.new(0.73, 0, 0, 0), UDim2.new(0.27, 0, 1, 0), VolumeArea)
end

local PlaylistScroll = Instance.new("ScrollingFrame")
PlaylistScroll.Size = UDim2.new(1, 0, 1, -88)
PlaylistScroll.Position = UDim2.new(0, 0, 0, 86)
PlaylistScroll.BackgroundTransparency = 1
PlaylistScroll.BorderSizePixel = 0
PlaylistScroll.ScrollBarThickness = 3
PlaylistScroll.ScrollBarImageColor3 = MAIN_COLOR
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
        item.BackgroundColor3 = Color3.fromRGB(16, 16, 24)
        item.BorderSizePixel = 0
        item.Parent = PlaylistScroll
        local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 4) c.Parent = item

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
        nameBox.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
        nameBox.Text = trackName
        nameBox.TextColor3 = Color3.fromRGB(255, 255, 255)
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

function ToxLighting.Reset(syncVisuals)
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


local UNIVERSAL_URL =
    "https://raw.githubusercontent.com/BG-0o/Scripts/refs/heads/main/Universal.lua"

local TOX_CHAT_URL =
    "https://raw.githubusercontent.com/BG-0o/Scripts/refs/heads/main/ToxChat.lua"

local TOX_SYSTEMS_URL =
    "https://raw.githubusercontent.com/BG-0o/Scripts/refs/heads/main/ToxSystems.lua"

local function AddToxCacheBuster(url)
    url = tostring(url or "")

    if url == "" then
        return url
    end

    local separator = string.find(url, "?", 1, true) and "&" or "?"

    return url
        .. separator
        .. "toxcache="
        .. tostring(os.time())
        .. "_"
        .. tostring(math.random(1000, 999999))
end

local function Notify(
    text,
    color,
    duration
)
    local notify =
        getgenv().CustomNotify

    if notify then
        notify(
            text,
            color,
            duration
        )
    end
end

local function LoadRemote(
    name,
    url
)
    local fetchOk, source =
        pcall(function()
            return game:HttpGet(AddToxCacheBuster(url))
        end)

    if not fetchOk then
        Notify(
            name .. " download failed",
            Color3.fromRGB(255, 100, 100),
            5
        )
        warn(
            "[ToxHub "
            .. name
            .. " Download Error]: "
            .. tostring(source)
        )
        return false
    end

    local chunk, compileErr =
        loadstring(source)

    if not chunk then
        local detail =
            tostring(
                compileErr
                or "compile error"
            )

        Notify(
            name
            .. " compile: "
            .. string.sub(
                detail,
                1,
                75
            ),
            Color3.fromRGB(255, 100, 100),
            7
        )
        warn(
            "[ToxHub "
            .. name
            .. " Compile Error]: "
            .. detail
        )
        return false
    end

    local runOk, runErr =
        pcall(chunk)

    if not runOk then
        local detail =
            tostring(runErr)

        Notify(
            name
            .. " runtime: "
            .. string.sub(
                detail,
                1,
                75
            ),
            Color3.fromRGB(255, 100, 100),
            7
        )
        warn(
            "[ToxHub "
            .. name
            .. " Runtime Error]: "
            .. detail
        )
        return false
    end

    return true
end

if not getgenv().ToxUniversalLoaded then
    if not LoadRemote(
        "Universal.lua",
        UNIVERSAL_URL
    ) then
        return
    end
end

if not getgenv().ToxChatLoaded then
    LoadRemote(
        "ToxChat.lua",
        TOX_CHAT_URL
    )
end

if not getgenv().ToxSystemsLoaded then
    LoadRemote(
        "ToxSystems.lua",
        TOX_SYSTEMS_URL
    )
end

local detected =
    getgenv().CurrentGameModule

if detected
and getgenv().ApplyCurrentGameSharedSettings then
    getgenv().ApplyCurrentGameSharedSettings()
end

if detected
and detected.Ready
and detected.Url
and getgenv().GamePage then
    local env =
        getgenv()

    local gamePage =
        env.GamePage

    local moduleUrl =
        tostring(
            detected.Url
        )

    if detected.ShortName == "MM2"
    and detected.CoreUrl then
        env.ToxMM2CoreURL = tostring(detected.CoreUrl)
    end

    local alreadyLoaded =
        env.ToxGameModuleLoadedPage
            == gamePage
        and env.ToxGameModuleLoadedUrl
            == moduleUrl

    local alreadyLoading =
        env.ToxGameModuleLoadingPage
            == gamePage
        and env.ToxGameModuleLoadingUrl
            == moduleUrl

    if not alreadyLoaded
    and not alreadyLoading then
        env.ToxGameModuleLoadingPage =
            gamePage

        env.ToxGameModuleLoadingUrl =
            moduleUrl

        task.spawn(function()
            local ok, err =
                pcall(function()
                    local source =
                        game:HttpGet(
                            AddToxCacheBuster(moduleUrl)
                        )

                    local chunk,
                        compileError =
                        loadstring(
                            source
                        )

                    if not chunk then
                        error(
                            tostring(
                                compileError
                                or "invalid game module"
                            )
                        )
                    end

                    chunk()
                end)

            if env.ToxGameModuleLoadingPage
                == gamePage
            and env.ToxGameModuleLoadingUrl
                == moduleUrl then
                env.ToxGameModuleLoadingPage =
                    nil

                env.ToxGameModuleLoadingUrl =
                    nil
            end

            if ok then
                env.ToxGameModuleLoadedPage =
                    gamePage

                env.ToxGameModuleLoadedUrl =
                    moduleUrl
            else
                if env.ToxGameModuleLoadedPage
                    == gamePage
                and env.ToxGameModuleLoadedUrl
                    == moduleUrl then
                    env.ToxGameModuleLoadedPage =
                        nil

                    env.ToxGameModuleLoadedUrl =
                        nil
                end

                Notify(
                    tostring(
                        detected.ShortName
                        or "Game"
                    )
                    .. " module failed to load",
                    Color3.fromRGB(
                        255,
                        100,
                        100
                    ),
                    5
                )

                warn(
                    "[ToxHub Game Module Error]: "
                    .. tostring(err)
                )
            end
        end)
    end
end
