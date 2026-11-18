local env = getgenv()
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Settings = env.Settings
local MAIN_COLOR = env.MAIN_COLOR
local function AddConnection(...) if env.AddConnection then return env.AddConnection(...) end end
local function AutoSaveConfiguration(...) if env.AutoSaveConfiguration then return env.AutoSaveConfiguration(...) end end
local function CustomNotify(...) if env.CustomNotify then return env.CustomNotify(...) end end
pcall(function()
    if cleardrawcache then
        cleardrawcache()
    elseif Drawing and Drawing.clear then
        Drawing.clear()
    end
end)
if getgenv().FOVCircle then pcall(function() getgenv().FOVCircle:Remove() end) end
local FOVCircle = (Drawing and Drawing.new) and Drawing.new("Circle") or nil
if FOVCircle then
    FOVCircle.Color = Color3.fromRGB(0, 200, 255)
    FOVCircle.Thickness = 1.5
    FOVCircle.NumSides = 60
    FOVCircle.Filled = false
    FOVCircle.Visible = false
end
getgenv().FOVCircle = FOVCircle
if getgenv().CrosshairH then pcall(function() getgenv().CrosshairH:Remove() end) end
if getgenv().CrosshairV then pcall(function() getgenv().CrosshairV:Remove() end) end
local CrosshairH = (Drawing and Drawing.new) and Drawing.new("Line") or nil
local CrosshairV = (Drawing and Drawing.new) and Drawing.new("Line") or nil
if CrosshairH and CrosshairV then
    CrosshairH.Color = Color3.fromRGB(0, 255, 100)
    CrosshairH.Thickness = 1.5
    CrosshairH.Visible = false
    CrosshairV.Color = Color3.fromRGB(0, 255, 100)
    CrosshairV.Thickness = 1.5
    CrosshairV.Visible = false
end
getgenv().CrosshairH = CrosshairH
getgenv().CrosshairV = CrosshairV
local NotifGui = Instance.new("ScreenGui")
NotifGui.Name = "ToxNotifs"
NotifGui.DisplayOrder = 999
NotifGui.Parent = (gethui and gethui()) or game:GetService("CoreGui")
getgenv().NotifGui = NotifGui
local NotifContainer = Instance.new("Frame")
NotifContainer.Size = UDim2.new(0, 240, 1, -40)
NotifContainer.Position = UDim2.new(1, -250, 0, 20)
NotifContainer.BackgroundTransparency = 1
NotifContainer.Parent = NotifGui
local NotifLayout = Instance.new("UIListLayout")
NotifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
NotifLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
NotifLayout.SortOrder = Enum.SortOrder.LayoutOrder
NotifLayout.Padding = UDim.new(0, 0)
NotifLayout.Parent = NotifContainer
getgenv().ToxLastNotificationText = getgenv().ToxLastNotificationText or nil
getgenv().ToxLastNotificationTime = getgenv().ToxLastNotificationTime or 0
-- Notificacoes: card com barra colorida, entra deslizando da direita,
-- barra de tempo embaixo, clique pra fechar, e notificacoes fixas (pin).
local TextService = game:GetService("TextService")
local NOTIF_WIDTH = 270
local NOTIF_MAX_STACK = 6
NotifContainer.Size = UDim2.new(0, NOTIF_WIDTH, 1, -40)
NotifContainer.Position = UDim2.new(1, -NOTIF_WIDTH - 14, 0, 20)
local NotifOrder = 0
local ActiveNotifs = {}
local PinnedNotifs = {}

local function NotifTheme(key, fallback)
    local theme = env.Theme
    return (theme and theme[key]) or fallback
end

local function MeasureNotifHeight(text)
    local ok, size = pcall(function()
        return TextService:GetTextSize(text, 13, Enum.Font.GothamMedium, Vector2.new(NOTIF_WIDTH - 40, 1000))
    end)
    local textHeight = ok and size.Y or 16
    return math.max(44, math.min(textHeight, 48) + 26)
end

local function CreateNotif(text, color, pinned)
    local accent = NotifTheme("Accent", MAIN_COLOR or Color3.fromRGB(30, 95, 255))
    local barColor = color or accent
    local uiTransp = math.clamp(tonumber(Settings and Settings.ToxUITransparency) or 0, 0, 0.85)
    local height = MeasureNotifHeight(text)

    NotifOrder += 1
    local holder = Instance.new("Frame")
    holder.Name = pinned and "ToxNotifPinned" or "ToxNotif"
    holder.BackgroundTransparency = 1
    holder.ClipsDescendants = true
    holder.Size = UDim2.new(1, 0, 0, 0)
    holder.LayoutOrder = pinned and (-100000 + NotifOrder) or NotifOrder
    holder.Parent = NotifContainer

    local card = Instance.new("TextButton")
    card.Name = "Card"
    card.AutoButtonColor = false
    card.Text = ""
    card.Size = UDim2.new(1, -2, 0, height - 2)
    card.Position = UDim2.new(0, NOTIF_WIDTH + 24, 0, 1)
    card.BackgroundColor3 = NotifTheme("Panel", Color3.fromRGB(16, 16, 26))
    card.BackgroundTransparency = 1
    card.BorderSizePixel = 0
    card.Parent = holder
    local corner = Instance.new("UICorner") corner.CornerRadius = UDim.new(0, 8) corner.Parent = card
    local stroke = Instance.new("UIStroke")
    stroke.Color = accent
    stroke.Thickness = 1
    stroke.Transparency = 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = card

    -- brilho suave da cor da notificacao vindo da esquerda
    local glow = Instance.new("Frame")
    glow.Name = "Glow"
    glow.Size = UDim2.new(1, 0, 1, 0)
    glow.BackgroundColor3 = barColor
    glow.BackgroundTransparency = 1
    glow.BorderSizePixel = 0
    glow.Parent = card
    local glowCorner = Instance.new("UICorner") glowCorner.CornerRadius = UDim.new(0, 8) glowCorner.Parent = glow
    local glowGradient = Instance.new("UIGradient")
    glowGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.82),
        NumberSequenceKeypoint.new(0.45, 1),
        NumberSequenceKeypoint.new(1, 1),
    })
    glowGradient.Parent = glow

    local bar = Instance.new("Frame")
    bar.Name = "Bar"
    bar.Size = UDim2.new(0, 3, 1, -16)
    bar.Position = UDim2.new(0, 8, 0, 8)
    bar.BackgroundColor3 = barColor
    bar.BackgroundTransparency = 1
    bar.BorderSizePixel = 0
    bar.Parent = card
    local barCorner = Instance.new("UICorner") barCorner.CornerRadius = UDim.new(1, 0) barCorner.Parent = bar

    local label = Instance.new("TextLabel")
    label.Name = "Text"
    label.Size = UDim2.new(1, -32, 1, -6)
    label.Position = UDim2.new(0, 20, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = NotifTheme("Text", Color3.fromRGB(240, 240, 240))
    label.TextTransparency = 1
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 13
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextTruncate = Enum.TextTruncate.AtEnd
    label.Parent = card

    local progress = Instance.new("Frame")
    progress.Name = "Progress"
    progress.Size = UDim2.new(1, -28, 0, 2)
    progress.Position = UDim2.new(0, 20, 1, -6)
    progress.BackgroundColor3 = barColor
    progress.BackgroundTransparency = 1
    progress.BorderSizePixel = 0
    progress.Visible = not pinned
    progress.Parent = card
    local progressCorner = Instance.new("UICorner") progressCorner.CornerRadius = UDim.new(1, 0) progressCorner.Parent = progress

    local handle = { Holder = holder, Card = card, Label = label, Bar = bar, Glow = glow, Progress = progress, Pinned = pinned, Dismissed = false }

    local inInfo = TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    TweenService:Create(holder, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.new(1, 0, 0, height + 6) }):Play()
    TweenService:Create(card, inInfo, { Position = UDim2.new(0, 1, 0, 1), BackgroundTransparency = uiTransp }):Play()
    TweenService:Create(stroke, inInfo, { Transparency = 0.35 }):Play()
    TweenService:Create(glow, inInfo, { BackgroundTransparency = 0 }):Play()
    TweenService:Create(bar, inInfo, { BackgroundTransparency = 0 }):Play()
    TweenService:Create(label, inInfo, { TextTransparency = 0 }):Play()
    TweenService:Create(progress, inInfo, { BackgroundTransparency = 0.35 }):Play()

    if pinned then
        -- barra "respirando" enquanto esta fixa
        handle.PulseTween = TweenService:Create(bar, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { BackgroundTransparency = 0.6 })
        task.delay(0.45, function()
            if not handle.Dismissed and handle.PulseTween then handle.PulseTween:Play() end
        end)
    end

    function handle.Dismiss()
        if handle.Dismissed then return end
        handle.Dismissed = true
        if handle.PulseTween then pcall(function() handle.PulseTween:Cancel() end) end
        for index, other in ipairs(ActiveNotifs) do
            if other == handle then table.remove(ActiveNotifs, index) break end
        end
        if not holder.Parent then return end
        local outInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        TweenService:Create(card, outInfo, { Position = UDim2.new(0, NOTIF_WIDTH + 24, 0, 1), BackgroundTransparency = 1 }):Play()
        TweenService:Create(stroke, outInfo, { Transparency = 1 }):Play()
        TweenService:Create(glow, outInfo, { BackgroundTransparency = 1 }):Play()
        TweenService:Create(bar, outInfo, { BackgroundTransparency = 1 }):Play()
        TweenService:Create(progress, outInfo, { BackgroundTransparency = 1 }):Play()
        TweenService:Create(label, outInfo, { TextTransparency = 1 }):Play()
        task.delay(0.28, function()
            if not holder.Parent then return end
            local collapse = TweenService:Create(holder, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), { Size = UDim2.new(1, 0, 0, 0) })
            collapse.Completed:Connect(function() holder:Destroy() end)
            collapse:Play()
        end)
    end

    function handle.SetText(newText, newColor)
        if handle.Dismissed then return end
        label.Text = tostring(newText or "")
        if newColor then
            bar.BackgroundColor3 = newColor
            glow.BackgroundColor3 = newColor
            progress.BackgroundColor3 = newColor
        end
        local newHeight = MeasureNotifHeight(label.Text)
        local info = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        TweenService:Create(holder, info, { Size = UDim2.new(1, 0, 0, newHeight + 6) }):Play()
        TweenService:Create(card, info, { Size = UDim2.new(1, -2, 0, newHeight - 2) }):Play()
    end

    card.MouseButton1Click:Connect(function()
        if handle.Pinned then
            for id, other in pairs(PinnedNotifs) do
                if other == handle then PinnedNotifs[id] = nil end
            end
        end
        handle.Dismiss()
    end)

    return handle
end

getgenv().CustomNotify = function(text, color, customTime)
    local now = os.clock()
    local message = tostring(text or "")
    if getgenv().ToxLastNotificationText == message
    and now - getgenv().ToxLastNotificationTime < 1.5 then
        return
    end
    getgenv().ToxLastNotificationText = message
    getgenv().ToxLastNotificationTime = now
    local duration = (tonumber(customTime) or 3) + 1
    local handle = CreateNotif(message, color, false)
    table.insert(ActiveNotifs, handle)
    while #ActiveNotifs > NOTIF_MAX_STACK do
        ActiveNotifs[1].Dismiss()
    end
    TweenService:Create(handle.Progress, TweenInfo.new(duration + 0.2, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 2) }):Play()
    task.delay(duration, handle.Dismiss)
    return handle
end

-- Notificacao fixa: fica na tela ate ToxUnpinNotify(id). Chamar de novo com o
-- mesmo id so atualiza o texto.
getgenv().ToxPinNotify = function(id, text, color)
    id = tostring(id or "default")
    local message = tostring(text or "")
    local existing = PinnedNotifs[id]
    if existing and not existing.Dismissed and existing.Holder.Parent then
        if existing.Label.Text ~= message or color then
            existing.SetText(message, color)
        end
        return existing
    end
    local handle = CreateNotif(message, color, true)
    PinnedNotifs[id] = handle
    return handle
end

getgenv().ToxUnpinNotify = function(id)
    id = tostring(id or "default")
    local handle = PinnedNotifs[id]
    PinnedNotifs[id] = nil
    if handle then handle.Dismiss() end
end
local ToxChatPopupContainer =
    Instance.new("Frame")
ToxChatPopupContainer.Name =
    "ToxChatPopupContainer"
ToxChatPopupContainer.Size =
    UDim2.new(
        0,
        350,
        0.62,
        -30
    )
ToxChatPopupContainer.Position =
    UDim2.new(
        1,
        -365,
        0,
        18
    )
ToxChatPopupContainer.BackgroundTransparency = 1
ToxChatPopupContainer.Parent = NotifGui
local ToxChatPopupLayout =
    Instance.new("UIListLayout")
ToxChatPopupLayout.VerticalAlignment =
    Enum.VerticalAlignment.Top
ToxChatPopupLayout.HorizontalAlignment =
    Enum.HorizontalAlignment.Right
ToxChatPopupLayout.SortOrder =
    Enum.SortOrder.LayoutOrder
ToxChatPopupLayout.Padding =
    UDim.new(
        0,
        7
    )
ToxChatPopupLayout.Parent =
    ToxChatPopupContainer
getgenv().ShowToxChatPopup =
    function(
        displayName,
        message,
        blocked
    )
        if not ToxChatPopupContainer
        or not ToxChatPopupContainer.Parent then
            return
        end
        local frame =
            Instance.new("Frame")
        frame.Size =
            UDim2.new(
                1,
                0,
                0,
                66
            )
        frame.AutomaticSize =
            Enum.AutomaticSize.Y
        frame.BackgroundColor3 =
            (env.Theme and env.Theme.Panel)
            or Color3.fromRGB(
                16,
                16,
                26
            )
        frame.BackgroundTransparency =
            math.clamp(tonumber(Settings and Settings.ToxUITransparency) or 0, 0, 0.85)
        frame.BorderSizePixel = 0
        frame.ClipsDescendants = true
        frame.Parent =
            ToxChatPopupContainer
        local corner =
            Instance.new("UICorner")
        corner.CornerRadius =
            UDim.new(
                0,
                7
            )
        corner.Parent = frame
        local stroke =
            Instance.new("UIStroke")
        stroke.Color = (env.Theme and env.Theme.Accent) or MAIN_COLOR
        stroke.Thickness = 1
        stroke.Transparency = 0.25
        stroke.Parent = frame
        local title =
            Instance.new("TextLabel")
        title.Size =
            UDim2.new(
                1,
                -20,
                0,
                22
            )
        title.Position =
            UDim2.new(
                0,
                10,
                0,
                7
            )
        title.BackgroundTransparency = 1
        title.Text =
            "Tox Chat • "
            .. tostring(
                displayName
            )
        title.TextColor3 =
            blocked
            and Color3.fromRGB(
                255,
                120,
                120
            )
            or Color3.fromRGB(
                245,
                245,
                255
            )
        title.Font =
            Enum.Font.GothamBold
        title.TextSize = 14
        title.TextXAlignment =
            Enum.TextXAlignment.Left
        title.TextTruncate =
            Enum.TextTruncate.AtEnd
        title.Parent = frame
        local body =
            Instance.new("TextLabel")
        body.Size =
            UDim2.new(
                1,
                -20,
                0,
                0
            )
        body.Position =
            UDim2.new(
                0,
                10,
                0,
                31
            )
        body.AutomaticSize =
            Enum.AutomaticSize.Y
        body.BackgroundTransparency = 1
        body.Text =
            tostring(
                message
            )
        body.TextColor3 =
            blocked
            and Color3.fromRGB(
                255,
                145,
                145
            )
            or Color3.fromRGB(
                225,
                225,
                238
            )
        body.Font =
            Enum.Font.GothamMedium
        body.TextSize = 14
        body.TextWrapped = true
        body.TextXAlignment =
            Enum.TextXAlignment.Left
        body.TextYAlignment =
            Enum.TextYAlignment.Top
        body.Parent = frame
        local padding =
            Instance.new("UIPadding")
        padding.PaddingBottom =
            UDim.new(
                0,
                9
            )
        padding.Parent = frame
        frame.BackgroundTransparency = 1
        title.TextTransparency = 1
        body.TextTransparency = 1
        stroke.Transparency = 1
        local tweenInfo =
            TweenInfo.new(
                0.28,
                Enum.EasingStyle.Quart,
                Enum.EasingDirection.Out
            )
        TweenService:
            Create(
                frame,
                tweenInfo,
                {
                    BackgroundTransparency = 0
                }
            ):
            Play()
        TweenService:
            Create(
                title,
                tweenInfo,
                {
                    TextTransparency = 0
                }
            ):
            Play()
        TweenService:
            Create(
                body,
                tweenInfo,
                {
                    TextTransparency = 0
                }
            ):
            Play()
        TweenService:
            Create(
                stroke,
                tweenInfo,
                {
                    Transparency = 0
                }
            ):
            Play()
        task.delay(
            5,
            function()
                if not frame
                or not frame.Parent then
                    return
                end
                local tweenOut =
                    TweenInfo.new(
                        0.3,
                        Enum.EasingStyle.Quart,
                        Enum.EasingDirection.In
                    )
                local fade =
                    TweenService:
                        Create(
                            frame,
                            tweenOut,
                            {
                                BackgroundTransparency = 1
                            }
                        )
                TweenService:
                    Create(
                        title,
                        tweenOut,
                        {
                            TextTransparency = 1
                        }
                    ):
                    Play()
                TweenService:
                    Create(
                        body,
                        tweenOut,
                        {
                            TextTransparency = 1
                        }
                    ):
                    Play()
                TweenService:
                    Create(
                        stroke,
                        tweenOut,
                        {
                            Transparency = 1
                        }
                    ):
                    Play()
                fade:Play()
                fade.Completed:
                    Connect(function()
                        if frame
                        and frame.Parent then
                            frame:
                                Destroy()
                        end
                    end)
            end
        )
    end
AddConnection(Players.PlayerAdded:Connect(function(p)
    if getgenv().ScriptLoaded then CustomNotify("(" .. p.Name .. ") joined", Color3.fromRGB(50, 255, 50), 3) end
end))
AddConnection(Players.PlayerRemoving:Connect(function(p)
    if getgenv().ScriptLoaded then CustomNotify("(" .. p.Name .. ") left", Color3.fromRGB(255, 50, 50), 3) end
end))
getgenv().MakeDraggable = function(Frame, DragHandle)
    local Dragging, DragInput, DragStart, StartPos
    DragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if getgenv().CloseToxDropdownOverlay then
                pcall(getgenv().CloseToxDropdownOverlay)
            end
            Dragging = true DragStart = input.Position StartPos = Frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    Dragging = false
                    if getgenv().ScriptLoaded then
                        AutoSaveConfiguration()
                    end
                end
            end)
        end
    end)
    DragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            DragInput = input
        end
    end)
    AddConnection(UserInputService.InputChanged:Connect(function(input)
        if Dragging and DragStart and StartPos and (input == DragInput or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local Delta = input.Position - DragStart
            Frame.Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + Delta.X, StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y)
        end
    end))
end
local GuiSizeSaveTokens = {}
getgenv().GetSavedGuiSize =
    function(
        key,
        defaultSize
    )
        key =
            tostring(
                key
                or ""
            )
        Settings.GUISizes =
            typeof(Settings.GUISizes)
                == "table"
            and Settings.GUISizes
            or {}
        local saved =
            Settings.GUISizes[
                key
            ]
        if typeof(saved)
            == "table" then
            local width =
                tonumber(
                    saved.Width
                )
            local height =
                tonumber(
                    saved.Height
                )
            if width
            and height
            and width >= 100
            and height >= 60 then
                return
                    UDim2.new(
                        0,
                        math.floor(
                            width + 0.5
                        ),
                        0,
                        math.floor(
                            height + 0.5
                        )
                    )
            end
        end
        return defaultSize
    end
getgenv().MakeResizable =
    function(
        frame,
        key,
        minRatio,
        maxRatio
    )
        if not frame
        or not frame:IsA("GuiObject") then
            return nil
        end
        key =
            tostring(
                key
                or frame.Name
                or "GUI"
            )
        Settings.GUISizes =
            typeof(Settings.GUISizes)
                == "table"
            and Settings.GUISizes
            or {}
        local oldScale =
            frame:
                FindFirstChild(
                    "ToxGuiScale"
                )
        if oldScale then
            oldScale:
                Destroy()
        end
        local initialWidth =
            frame.Size.X.Offset
        local initialHeight =
            frame.Size.Y.Offset
        if initialWidth <= 0 then
            initialWidth = 330
        end
        if initialHeight <= 0 then
            initialHeight = 395
        end
        local minWidth = 120
        local minHeight = 60
        local maxWidth = 8192
        local maxHeight = 8192
        if typeof(minRatio) == "Vector2" then
            minWidth = minRatio.X
            minHeight = minRatio.Y
        elseif typeof(minRatio) == "number" then
            minWidth = math.max(100, math.floor(initialWidth * minRatio))
            minHeight = math.max(50, math.floor(initialHeight * minRatio))
        end
        if typeof(maxRatio) == "Vector2" then
            maxWidth = maxRatio.X
            maxHeight = maxRatio.Y
        elseif typeof(maxRatio) == "number" then
            maxWidth = math.max(minWidth, math.floor(initialWidth * maxRatio))
            maxHeight = math.max(minHeight, math.floor(initialHeight * maxRatio))
        end
        local saved =
            Settings.GUISizes[
                key
            ]
        if typeof(saved)
            == "table" then
            local width =
                tonumber(
                    saved.Width
                )
            local height =
                tonumber(
                    saved.Height
                )
            if width
            and height then
                frame.Size =
                    UDim2.new(
                        0,
                        math.clamp(
                            math.floor(
                                width + 0.5
                            ),
                            minWidth,
                            maxWidth
                        ),
                        0,
                        math.clamp(
                            math.floor(
                                height + 0.5
                            ),
                            minHeight,
                            maxHeight
                        )
                    )
            end
        end
        local oldHandle =
            frame:
                FindFirstChild(
                    "ToxResizeHandle"
                )
        if oldHandle then
            oldHandle:
                Destroy()
        end
        local handle =
            Instance.new(
                "TextButton"
            )
        handle.Name =
            "ToxResizeHandle"
        handle.Size =
            UDim2.new(
                0,
                20,
                0,
                20
            )
        handle.Position =
            UDim2.new(
                1,
                -20,
                1,
                -20
            )
        handle.BackgroundTransparency = 1
        handle.BorderSizePixel = 0
        handle.Text = "◢"
        handle.TextColor3 =
            Color3.fromRGB(
                175,
                175,
                195
            )
        handle.TextSize = 15
        handle.Font =
            Enum.Font.GothamBold
        handle.AutoButtonColor = false
        handle.Active = true
        handle.ZIndex = 100
        handle.Parent = frame
        local resizing = false
        local resizeInput = nil
        local dragStart = nil
        local startWidth = 0
        local startHeight = 0
        local function isFrameMinimized()
            if frame == getgenv().Main
            and getgenv().ToxMainMinimized == true then
                return true
            end
            if frame:FindFirstChild("ToxSubGuiMinimize")
            and frame.AbsoluteSize.Y <= 44 then
                return true
            end
            return false
        end
        local function saveSize()
            if isFrameMinimized() then
                return
            end
            local currentSize =
                frame.AbsoluteSize
            Settings.GUISizes[
                key
            ] = {
                Width =
                    math.floor(
                        currentSize.X
                        + 0.5
                    ),
                Height =
                    math.floor(
                        currentSize.Y
                        + 0.5
                    )
            }
            GuiSizeSaveTokens[
                key
            ] =
                (
                    GuiSizeSaveTokens[
                        key
                    ]
                    or 0
                )
                + 1
            local token =
                GuiSizeSaveTokens[
                    key
                ]
            task.delay(
                0.35,
                function()
                    if GuiSizeSaveTokens[
                        key
                    ] == token
                    and not env.Destroyed then
                        AutoSaveConfiguration()
                    end
                end
            )
        end
        handle.InputBegan:
            Connect(function(input)
                if input.UserInputType
                    ~= Enum.UserInputType.MouseButton1
                and input.UserInputType
                    ~= Enum.UserInputType.Touch then
                    return
                end
                if isFrameMinimized() then
                    resizing = false
                    return
                end
                if getgenv().CloseToxDropdownOverlay then
                    pcall(getgenv().CloseToxDropdownOverlay)
                end
                resizing = true
                resizeInput = input
                dragStart =
                    input.Position
                local currentSize =
                    frame.AbsoluteSize
                startWidth =
                    currentSize.X
                startHeight =
                    currentSize.Y
                input.Changed:
                    Connect(function()
                        if input.UserInputState
                            == Enum.UserInputState.End then
                            resizing = false
                            saveSize()
                        end
                    end)
            end)
        handle.InputChanged:
            Connect(function(input)
                if input.UserInputType
                    == Enum.UserInputType.MouseMovement
                or input.UserInputType
                    == Enum.UserInputType.Touch then
                    resizeInput =
                        input
                end
            end)
        AddConnection(
            UserInputService.InputChanged:
                Connect(function(input)
                    if not resizing
                    or not dragStart then
                        return
                    end
                    if input.UserInputType ~= Enum.UserInputType.MouseMovement
                    and input ~= resizeInput then
                        return
                    end
                    if isFrameMinimized() then
                        resizing = false
                        return
                    end
                    local delta =
                        input.Position
                        - dragStart
                    local newWidth =
                        math.clamp(
                            math.floor(
                                startWidth
                                + delta.X
                                + 0.5
                            ),
                            minWidth,
                            maxWidth
                        )
                    local newHeight =
                        math.clamp(
                            math.floor(
                                startHeight
                                + delta.Y
                                + 0.5
                            ),
                            minHeight,
                            maxHeight
                        )
                    frame.Size =
                        UDim2.new(
                            0,
                            newWidth,
                            0,
                            newHeight
                        )
                end)
        )
        return handle
    end
local GuiPositionSaveTokens = {}
getgenv().EncodeGuiPosition = function(position)
    return {
        XS = position.X.Scale,
        XO = position.X.Offset,
        YS = position.Y.Scale,
        YO = position.Y.Offset
    }
end
getgenv().DecodeGuiPosition = function(data)
    if typeof(data) ~= "table" then
        return nil
    end
    if typeof(data.XS) ~= "number"
    or typeof(data.XO) ~= "number"
    or typeof(data.YS) ~= "number"
    or typeof(data.YO) ~= "number" then
        return nil
    end
    return UDim2.new(data.XS, data.XO, data.YS, data.YO)
end
getgenv().GetSavedGuiPosition = function(key)
    return getgenv().DecodeGuiPosition(getgenv().UIPositions[key])
end
getgenv().ApplySavedGuiPosition = function(key, gui)
    if not gui then
        return nil
    end
    local saved = getgenv().GetSavedGuiPosition(key)
    if saved then
        gui.Position = saved
    end
    return saved or gui.Position
end
-- Lembra quais janelas (Waypoints, Music, Magnet, etc.) ficaram abertas e
-- reabre elas na proxima execucao. Fica salvo junto com as posicoes,
-- em UIPositions.__Open, entao nao precisa mexer no formato do config.
local OPEN_STATE_KEY = "__Open"
local OpenStateIgnored = {
    Main = true, MobileToggle = true, Watermark = true, Keybinds = true,
    Spectators = true, ServerInfo = true, MM2RoundTimer = true,
}
local OpenStateTracked = {}
local OpenStateRestored = false
local OpenStateSaveToken = 0

local function GetOpenStateTable()
    local positions = getgenv().UIPositions
    if typeof(positions) ~= "table" then
        positions = {}
        getgenv().UIPositions = positions
    end
    if typeof(positions[OPEN_STATE_KEY]) ~= "table" then
        positions[OPEN_STATE_KEY] = {}
    end
    return positions[OPEN_STATE_KEY]
end

local function IsMainShown()
    local main = getgenv().Main
    return main ~= nil and main.Parent ~= nil and main.Visible == true
end

local function RecordOpenState(key, gui)
    if not OpenStateRestored
    or not getgenv().ScriptLoaded
    or env.Destroyed
    or getgenv().Destroyed
    or not gui.Parent
    or not IsMainShown() then
        -- Esconder tudo pela tecla da GUI / fechar o hub nao conta como "fechei a janela"
        return
    end
    local open = GetOpenStateTable()
    local value = gui.Visible == true
    if open[key] == value then
        return
    end
    open[key] = value
    OpenStateSaveToken += 1
    local token = OpenStateSaveToken
    task.delay(0.25, function()
        if OpenStateSaveToken == token and not env.Destroyed then
            AutoSaveConfiguration()
        end
    end)
end

local function RestoreOpenGuis()
    local open = GetOpenStateTable()
    for key, gui in pairs(OpenStateTracked) do
        if open[key] == true and gui and gui.Parent then
            gui.Visible = true
        end
    end
end

task.spawn(function()
    repeat
        task.wait(0.2)
    until getgenv().ScriptLoaded or env.Destroyed or getgenv().Destroyed
    -- da tempo dos modulos terminarem de montar as janelas (todas nascem fechadas)
    task.wait(0.8)
    local waited = 0
    while not IsMainShown() and not env.Destroyed and not getgenv().Destroyed do
        -- Start Hidden: so reabre quando o hub for aberto
        task.wait(0.2)
        waited += 0.2
        if waited > 600 then break end
    end
    if env.Destroyed or getgenv().Destroyed then return end
    task.wait(0.1)
    RestoreOpenGuis()
    OpenStateRestored = true
end)

getgenv().TrackGuiPosition = function(key, gui)
    if not gui then
        return
    end
    if not OpenStateIgnored[key] and OpenStateTracked[key] ~= gui then
        OpenStateTracked[key] = gui
        AddConnection(gui:GetPropertyChangedSignal("Visible"):Connect(function()
            RecordOpenState(key, gui)
        end))
        if OpenStateRestored and IsMainShown() and GetOpenStateTable()[key] == true then
            -- janela criada depois do load (ex: modulo do jogo)
            task.defer(function()
                if gui.Parent then gui.Visible = true end
            end)
        end
    end
    AddConnection(gui:GetPropertyChangedSignal("Position"):Connect(function()
        if not getgenv().ScriptLoaded or gui:GetAttribute("ToxIgnorePosTrack") == true then
            return
        end
        getgenv().UIPositions[key] = getgenv().EncodeGuiPosition(gui.Position)
        GuiPositionSaveTokens[key] = (GuiPositionSaveTokens[key] or 0) + 1
        local token = GuiPositionSaveTokens[key]
        task.delay(0.25, function()
            if GuiPositionSaveTokens[key] == token and not env.Destroyed then
                AutoSaveConfiguration()
            end
        end)
    end))
end
local AirWalkPart = nil
local LockedAirWalkY = nil
local AirWalkLastUpdate = tick()
local function UpdateAirWalk()
    local now = tick()
    local deltaTime =
        math.clamp(
            now - AirWalkLastUpdate,
            0,
            0.08
        )
    AirWalkLastUpdate = now
    local Root =
        Player.Character
        and Player.Character:
            FindFirstChild(
                "HumanoidRootPart"
            )
    if Settings.AirWalk
    and Root then
        if not LockedAirWalkY then
            LockedAirWalkY =
                Root.Position.Y
                - 3.4
        end
        local vertical = 0
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            vertical = vertical + 1
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
        or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then
            vertical = vertical - 1
        end
        if vertical ~= 0 then
            LockedAirWalkY = LockedAirWalkY + (vertical * 28 * deltaTime)
        end
        if not AirWalkPart
        or not AirWalkPart.Parent then
            AirWalkPart =
                Instance.new(
                    "Part"
                )
            AirWalkPart.Name =
                "ToxAirWalk"
            AirWalkPart.Size =
                Vector3.new(
                    8,
                    1,
                    8
                )
            AirWalkPart.Transparency = 1
            AirWalkPart.Anchored = true
            AirWalkPart.CanCollide = true
            AirWalkPart.Parent = workspace
        end
        AirWalkPart.CFrame =
            CFrame.new(
                Root.Position.X,
                LockedAirWalkY,
                Root.Position.Z
            )
    else
        LockedAirWalkY = nil
        if AirWalkPart then
            AirWalkPart:
                Destroy()
            AirWalkPart = nil
        end
    end
end
getgenv().UpdateAirWalk =
    UpdateAirWalk
if not getgenv().__ToxModule1AirWalkHooked then
    getgenv().__ToxModule1AirWalkHooked = true
    RunService.Heartbeat:Connect(function()
        if Settings.AirWalk then
            pcall(UpdateAirWalk)
        end
    end)
end
local function UpdateMouseIcon()
    pcall(function()
        if Settings.Crosshair and Settings.MouseIconID ~= "" then
            local cleanID = tostring(Settings.MouseIconID):match("%d+")
            local sz = Settings.MouseIconSize or 150
            if cleanID then
                Player:GetMouse().Icon = "rbxthumb://type=Asset&id=" .. cleanID .. "&w=" .. tostring(sz) .. "&h=" .. tostring(sz)
            else
                Player:GetMouse().Icon = ""
            end
        else
            Player:GetMouse().Icon = ""
        end
    end)
end
getgenv().UpdateMouseIcon = UpdateMouseIcon
local function RestoreCollisions()
    if Player.Character then
        for _, part in ipairs(Player.Character:GetChildren()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.CanCollide = true
            end
        end
        local Hum = Player.Character:FindFirstChildOfClass("Humanoid")
        if Hum then
            Hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end
end
getgenv().RestoreCollisions = RestoreCollisions
local function ResetHitboxes()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.Size = Vector3.new(2, 2, 1)
                hrp.Transparency = 1
            end
        end
    end
end
getgenv().ResetHitboxes = ResetHitboxes
local FullbrightDefaults = nil
local FullbrightActive = false
local function CaptureFullbrightDefaults()
    return {
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        Brightness = Lighting.Brightness,
        ClockTime = Lighting.ClockTime,
        FogStart = Lighting.FogStart,
        FogEnd = Lighting.FogEnd,
        FogColor = Lighting.FogColor,
        GlobalShadows = Lighting.GlobalShadows,
        ExposureCompensation = Lighting.ExposureCompensation,
        ShadowSoftness = Lighting.ShadowSoftness,
        EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
        EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale
    }
end
local function RestoreFullbrightDefaults()
    local defaults = FullbrightDefaults
    FullbrightDefaults = nil
    FullbrightActive = false
    if not defaults then
        return
    end
    for property, value in pairs(defaults) do
        pcall(function()
            Lighting[property] = value
        end)
    end
end
local function UpdateFullbright()
    if Settings.Fullbright then
        if not FullbrightActive then
            FullbrightDefaults = CaptureFullbrightDefaults()
            FullbrightActive = true
        end
        pcall(function() Lighting.Ambient = Color3.fromRGB(180, 180, 180) end)
        pcall(function() Lighting.OutdoorAmbient = Color3.fromRGB(180, 180, 180) end)
        pcall(function() Lighting.Brightness = 1.2 end)
        pcall(function() Lighting.ClockTime = 14 end)
        pcall(function() Lighting.FogStart = 0 end)
        pcall(function() Lighting.FogEnd = 100000 end)
        pcall(function() Lighting.GlobalShadows = false end)
        pcall(function() Lighting.ExposureCompensation = 0 end)
    elseif FullbrightActive or FullbrightDefaults then
        RestoreFullbrightDefaults()
    end
end
getgenv().UpdateFullbright = UpdateFullbright
getgenv().RestoreFullbrightDefaults = RestoreFullbrightDefaults
