local env = getgenv()
if env.Destroyed then return end
local UI = env.ToxUI or {}
env.ToxUI = UI

local Settings = env.Settings or {}
local Theme = env.Theme or UI.Theme or {}
local RegisterThemedObject = env.RegisterThemedObject or UI.RegisterThemedObject or function() end
local ApplySavedGuiPosition = function(...) if env.ApplySavedGuiPosition then return env.ApplySavedGuiPosition(...) end end
local TrackGuiPosition = function(...) if env.TrackGuiPosition then return env.TrackGuiPosition(...) end end

local Main = UI.Main or env.Main
local ChatPage = UI.ChatPage or env.ChatPage
local JoinPage = UI.JoinPage or env.JoinPage
do 
local ToxChatGui = Instance.new("Frame")
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
local ToxChatStroke = Instance.new("UIStroke") ToxChatStroke.Color = Theme.Outline ToxChatStroke.Thickness = 1 ToxChatStroke.Transparency = 0.32 ToxChatStroke.Parent = ToxChatGui
RegisterThemedObject(ToxChatStroke, "Color", "Outline")
local ToxChatTopBar = Instance.new("Frame")
ToxChatTopBar.Size = UDim2.new(1, 0, 0, 32)
ToxChatTopBar.BackgroundColor3 = Theme.Element
ToxChatTopBar.BorderSizePixel = 0
ToxChatTopBar.Parent = ToxChatGui
getgenv().ToxChatTopBar = ToxChatTopBar
RegisterThemedObject(ToxChatTopBar, "BackgroundColor3", "Element")
if getgenv().ToxRoundTopBar then getgenv().ToxRoundTopBar(ToxChatTopBar) end
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
local JoinGamesStroke = Instance.new("UIStroke") JoinGamesStroke.Color = Theme.Outline JoinGamesStroke.Thickness = 1 JoinGamesStroke.Transparency = 0.32 JoinGamesStroke.Parent = JoinGamesGui
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
end
