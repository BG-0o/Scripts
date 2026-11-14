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
NotifLayout.Padding = UDim.new(0, 6)
NotifLayout.Parent = NotifContainer
getgenv().ToxLastNotificationText = getgenv().ToxLastNotificationText or nil
getgenv().ToxLastNotificationTime = getgenv().ToxLastNotificationTime or 0
getgenv().CustomNotify = function(text, color, customTime)
    local now = os.clock()
    local message = tostring(text or "")
    if getgenv().ToxLastNotificationText == message
    and now - getgenv().ToxLastNotificationTime < 1.5 then
        return
    end
    getgenv().ToxLastNotificationText = message
    getgenv().ToxLastNotificationTime = now
    local uiTheme = env.Theme
    local uiTransp = math.clamp(tonumber(Settings and Settings.ToxUITransparency) or 0, 0, 0.85)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 38)
    Frame.BackgroundColor3 = (uiTheme and uiTheme.Panel) or Color3.fromRGB(16, 16, 26)
    Frame.BorderSizePixel = 0
    Frame.ClipsDescendants = true
    Frame.Parent = NotifContainer
    local Corner = Instance.new("UICorner") Corner.CornerRadius = UDim.new(0, 6) Corner.Parent = Frame
    local Stroke = Instance.new("UIStroke") Stroke.Color = (uiTheme and uiTheme.Accent) or MAIN_COLOR Stroke.Thickness = 1 Stroke.Transparency = 0.25 Stroke.Parent = Frame
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -16, 1, 0)
    Label.Position = UDim2.new(0, 10, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = color or (uiTheme and uiTheme.Text) or Color3.fromRGB(240, 240, 240)
    Label.Font = Enum.Font.GothamMedium
    Label.TextSize = 13
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextTruncate = Enum.TextTruncate.AtEnd
    Label.Parent = Frame
    Frame.BackgroundTransparency = 1 Label.TextTransparency = 1 Stroke.Transparency = 1
    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    TweenService:Create(Frame, tweenInfo, {BackgroundTransparency = uiTransp}):Play()
    TweenService:Create(Label, tweenInfo, {TextTransparency = 0}):Play()
    TweenService:Create(Stroke, tweenInfo, {Transparency = 0.25}):Play()
    task.delay(customTime or 3, function()
        if Frame and Frame.Parent then
            local tweenOut = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
            local t1 = TweenService:Create(Frame, tweenOut, {BackgroundTransparency = 1})
            local t2 = TweenService:Create(Label, tweenOut, {TextTransparency = 1})
            local t3 = TweenService:Create(Stroke, tweenOut, {Transparency = 1})
            t1:Play() t2:Play() t3:Play()
            t1.Completed:Connect(function() Frame:Destroy() end)
        end
    end)
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
getgenv().TrackGuiPosition = function(key, gui)
    if not gui then
        return
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
