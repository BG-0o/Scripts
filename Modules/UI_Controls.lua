local env = getgenv()
if env.Destroyed then return end
local UI = env.ToxUI or {}
env.ToxUI = UI

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Settings = env.Settings or {}
local Theme = env.Theme or UI.Theme or {}
local RegisteredToggles = env.RegisteredToggles or UI.RegisteredToggles or {}
local RegisterThemedObject = env.RegisterThemedObject or UI.RegisterThemedObject or function() end
local ResolveElementParent = env.ResolveElementParent or UI.ResolveElementParent or function(p) return p end
local CustomNotify = function(...) if env.CustomNotify then return env.CustomNotify(...) end end
local AutoSaveConfiguration = function(...) if env.AutoSaveConfiguration then return env.AutoSaveConfiguration(...) end end
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
local DeferredStartupCallbacks = {}
local function RunWhenLoaded(isEnabledFn, callback)
    if type(callback) ~= "function" then
        return
    end
    if getgenv().ScriptLoaded == true then
        task.defer(function()
            if not getgenv().Destroyed and isEnabledFn() then
                pcall(callback, true)
            end
        end)
    else
        table.insert(DeferredStartupCallbacks, function()
            if not getgenv().Destroyed and isEnabledFn() then
                pcall(callback, true)
            end
        end)
    end
end
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
    ClickBtn.MouseEnter:Connect(function()
        if getgenv().Destroyed then return end
        TweenService:Create(Container, TweenInfo.new(0.12), { BackgroundColor3 = Theme.Hover }):Play()
    end)
    ClickBtn.MouseLeave:Connect(function()
        if getgenv().Destroyed then return end
        TweenService:Create(Container, TweenInfo.new(0.12), { BackgroundColor3 = Theme.Element }):Play()
    end)
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
    local initialValue = DefaultValue
    if SyncKey and Settings[SyncKey] ~= nil then
        initialValue = Settings[SyncKey]
    end
    local Enabled = (initialValue == true)
    local ToggleBg = Instance.new("Frame")
    ToggleBg.Size = UDim2.new(0, 38, 0, 20)
    ToggleBg.Position = UDim2.new(1, -48, 0.5, -10)
    ToggleBg.BackgroundColor3 = Enabled and Theme.Accent or Theme.Panel
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
    Indicator.Position = Enabled and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
    Indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Indicator.BorderSizePixel = 0
    Indicator.Parent = ToggleBg
    local indCorner = Instance.new("UICorner") indCorner.CornerRadius = UDim.new(1, 0) indCorner.Parent = Indicator
    local function Update()
        TweenService:Create(ToggleBg, TweenInfo.new(0.2), {
            BackgroundColor3 = Enabled and Theme.Accent or Theme.Panel
        }):Play()
        TweenService:Create(Indicator, TweenInfo.new(0.2), {
            Position = Enabled and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
        }):Play()
    end
    table.insert(RegisteredToggles, {
        UpdateColor = function()
            ToggleBg.BackgroundColor3 = Enabled and Theme.Accent or Theme.Panel
            tgStroke.Color = Theme.Outline
            cStroke.Color = Theme.Outline
        end
    })
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
    if Enabled and Callback then
        RunWhenLoaded(function()
            return Enabled
        end, Callback)
    end
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
    local initialToggle = DefaultToggle
    if SyncKey and Settings[SyncKey] ~= nil then
        initialToggle = Settings[SyncKey]
    end
    local Enabled = (initialToggle == true)
    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Size = UDim2.new(0, 38, 0, 20)
    ToggleButton.Position = UDim2.new(1, -48, 0.5, -10)
    ToggleButton.BackgroundColor3 = Enabled and Theme.Accent or Theme.Panel
    ToggleButton.BorderSizePixel = 0
    ToggleButton.Text = ""
    ToggleButton.AutoButtonColor = false
    ToggleButton.Parent = Container
    local tgCorner = Instance.new("UICorner") tgCorner.CornerRadius = UDim.new(1, 0) tgCorner.Parent = ToggleButton
    local tgStroke = Instance.new("UIStroke") tgStroke.Color = Theme.Outline tgStroke.Thickness = 1 tgStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border tgStroke.Parent = ToggleButton
    RegisterThemedObject(tgStroke, "Color", "Outline")
    local Indicator = Instance.new("Frame")
    Indicator.Size = UDim2.new(0, 14, 0, 14)
    Indicator.Position = Enabled and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
    Indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Indicator.BorderSizePixel = 0
    Indicator.Parent = ToggleButton
    local indCorner = Instance.new("UICorner") indCorner.CornerRadius = UDim.new(1, 0) indCorner.Parent = Indicator
    local function UpdateToggle()
        TweenService:Create(ToggleButton, TweenInfo.new(0.2), {
            BackgroundColor3 = Enabled and Theme.Accent or Theme.Panel
        }):Play()
        TweenService:Create(Indicator, TweenInfo.new(0.2), {
            Position = Enabled and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
        }):Play()
    end
    table.insert(RegisteredToggles, {
        UpdateColor = function()
            ToggleButton.BackgroundColor3 = Enabled and Theme.Accent or Theme.Panel
            tgStroke.Color = Theme.Outline
            cStroke.Color = Theme.Outline
            inStroke.Color = Theme.Outline
        end
    })
    local Controller = {
        Button = Container,
        SetVisual = function(Value)
            Enabled = Value == true
            UpdateToggle()
        end,
        SetValue = function(Value)
            if tonumber(Value) then
                DefaultValue = Value
                Input.Text = tostring(Value)
            end
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
            if SyncKey and getgenv().SyncValueVisuals and tostring(SyncKey) ~= "MM2AutoFarmV2" then
                getgenv().SyncValueVisuals(SyncKey, num)
            end
            AutoSaveConfiguration()
        else
            Input.Text = tostring(DefaultValue)
        end
    end)
    UpdateToggle()
    if Enabled and CallbackToggle then
        RunWhenLoaded(function()
            return Enabled
        end, CallbackToggle)
    end
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
    local initialToggle = DefaultToggle
    if SyncKey and Settings[SyncKey] ~= nil then
        initialToggle = Settings[SyncKey]
    end
    local Enabled = (initialToggle == true)
    local initialChoice = DefaultChoice
    if SyncKey and Settings[SyncKey .. "Target"] ~= nil then
        initialChoice = Settings[SyncKey .. "Target"]
    elseif SyncKey and Settings[SyncKey .. "Choice"] ~= nil then
        initialChoice = Settings[SyncKey .. "Choice"]
    end
    ChoiceBtn.Text = tostring(initialChoice)
    local isChoiceOpen = false
    local choiceItemHeight = 22
    local choiceListHeight = math.min(#Options * (choiceItemHeight + 2), 100)
    local choiceOpenHeight = 36 + choiceListHeight + 8
    Container.ClipsDescendants = true
    local ChoiceScroll = Instance.new("ScrollingFrame")
    ChoiceScroll.Size = UDim2.new(1, -16, 0, choiceListHeight)
    ChoiceScroll.Position = UDim2.new(0, 8, 0, 36)
    ChoiceScroll.BackgroundColor3 = Theme.Panel
    ChoiceScroll.BorderSizePixel = 0
    ChoiceScroll.ScrollBarThickness = 3
    ChoiceScroll.ScrollBarImageColor3 = Theme.Accent
    ChoiceScroll.CanvasSize = UDim2.new(0, 0, 0, #Options * (choiceItemHeight + 2))
    ChoiceScroll.Visible = false
    ChoiceScroll.Parent = Container
    local csCorner = Instance.new("UICorner") csCorner.CornerRadius = UDim.new(0, 4) csCorner.Parent = ChoiceScroll
    local csStroke = Instance.new("UIStroke") csStroke.Color = Theme.Outline csStroke.Thickness = 1 csStroke.Parent = ChoiceScroll
    RegisterThemedObject(ChoiceScroll, "BackgroundColor3", "Panel")
    RegisterThemedObject(csStroke, "Color", "Outline")
    local csLayout = Instance.new("UIListLayout")
    csLayout.Padding = UDim.new(0, 2)
    csLayout.SortOrder = Enum.SortOrder.LayoutOrder
    csLayout.Parent = ChoiceScroll
    local csPadding = Instance.new("UIPadding")
    csPadding.PaddingTop = UDim.new(0, 2)
    csPadding.PaddingBottom = UDim.new(0, 2)
    csPadding.PaddingLeft = UDim.new(0, 4)
    csPadding.PaddingRight = UDim.new(0, 4)
    csPadding.Parent = ChoiceScroll
    local choiceButtons = {}
    local function RefreshChoiceButtons()
        for optVal, btn in pairs(choiceButtons) do
            if optVal == initialChoice then
                btn.TextColor3 = Theme.Accent
                btn.BackgroundColor3 = Theme.Element
            else
                btn.TextColor3 = Theme.Text
                btn.BackgroundColor3 = Theme.Panel
            end
        end
    end
    for idx, opt in ipairs(Options) do
        local cOptBtn = Instance.new("TextButton")
        cOptBtn.Size = UDim2.new(1, -2, 0, choiceItemHeight)
        cOptBtn.BackgroundColor3 = (opt == initialChoice) and Theme.Element or Theme.Panel
        cOptBtn.BorderSizePixel = 0
        cOptBtn.Text = tostring(opt)
        cOptBtn.TextColor3 = (opt == initialChoice) and Theme.Accent or Theme.Text
        cOptBtn.TextSize = 11
        cOptBtn.Font = Enum.Font.GothamMedium
        cOptBtn.TextXAlignment = Enum.TextXAlignment.Left
        cOptBtn.LayoutOrder = idx
        cOptBtn.Parent = ChoiceScroll
        local cbCorner2 = Instance.new("UICorner") cbCorner2.CornerRadius = UDim.new(0, 3) cbCorner2.Parent = cOptBtn
        local cbPad2 = Instance.new("UIPadding") cbPad2.PaddingLeft = UDim.new(0, 8) cbPad2.Parent = cOptBtn
        choiceButtons[opt] = cOptBtn
        cOptBtn.MouseButton1Click:Connect(function()
            if getgenv().Destroyed then return end
            initialChoice = opt
            ChoiceBtn.Text = tostring(opt)
            RefreshChoiceButtons()
            isChoiceOpen = false
            ChoiceScroll.Visible = false
            TweenService:Create(Container, TweenInfo.new(0.18, Enum.EasingStyle.Quad), { Size = UDim2.new(1, -4, 0, 36) }):Play()
            if CallbackChoice then CallbackChoice(opt) end
            AutoSaveConfiguration()
        end)
    end
    local function ToggleChoiceOpen()
        isChoiceOpen = not isChoiceOpen
        if isChoiceOpen then
            ChoiceScroll.Visible = true
            RefreshChoiceButtons()
            TweenService:Create(Container, TweenInfo.new(0.2, Enum.EasingStyle.Quad), { Size = UDim2.new(1, -4, 0, choiceOpenHeight) }):Play()
        else
            TweenService:Create(Container, TweenInfo.new(0.18, Enum.EasingStyle.Quad), { Size = UDim2.new(1, -4, 0, 36) }):Play()
            task.delay(0.2, function()
                if not isChoiceOpen then ChoiceScroll.Visible = false end
            end)
        end
    end
    ChoiceBtn.MouseButton1Click:Connect(function()
        if getgenv().Destroyed  then return end
        ToggleChoiceOpen()
    end)
    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Size = UDim2.new(0, 38, 0, 20)
    ToggleButton.Position = UDim2.new(1, -48, 0.5, -10)
    ToggleButton.BackgroundColor3 = Enabled and Theme.Accent or Theme.Panel
    ToggleButton.BorderSizePixel = 0
    ToggleButton.Text = ""
    ToggleButton.AutoButtonColor = false
    ToggleButton.Parent = Container
    local tgCorner = Instance.new("UICorner") tgCorner.CornerRadius = UDim.new(1, 0) tgCorner.Parent = ToggleButton
    local tgStroke = Instance.new("UIStroke") tgStroke.Color = Theme.Outline tgStroke.Thickness = 1 tgStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border tgStroke.Parent = ToggleButton
    RegisterThemedObject(tgStroke, "Color", "Outline")
    local Indicator = Instance.new("Frame")
    Indicator.Size = UDim2.new(0, 14, 0, 14)
    Indicator.Position = Enabled and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
    Indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Indicator.BorderSizePixel = 0
    Indicator.Parent = ToggleButton
    local indCorner = Instance.new("UICorner") indCorner.CornerRadius = UDim.new(1, 0) indCorner.Parent = Indicator
    local function UpdateToggle()
        TweenService:Create(ToggleButton, TweenInfo.new(0.2), {
            BackgroundColor3 = Enabled and Theme.Accent or Theme.Panel
        }):Play()
        TweenService:Create(Indicator, TweenInfo.new(0.2), {
            Position = Enabled and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
        }):Play()
    end
    table.insert(RegisteredToggles, {
        UpdateColor = function()
            ToggleButton.BackgroundColor3 = Enabled and Theme.Accent or Theme.Panel
            tgStroke.Color = Theme.Outline
            cStroke.Color = Theme.Outline
            cbStroke.Color = Theme.Outline
            ChoiceBtn.TextColor3 = Theme.Accent
            ChoiceBtn.BackgroundColor3 = Theme.Panel
        end
    })
    local Controller = {
        Button = Container,
        SetVisual = function(Value)
            Enabled = Value == true
            UpdateToggle()
        end,
        SetValue = function(Value)
            initialChoice = Value
            ChoiceBtn.Text = tostring(Value)
            RefreshChoiceButtons()
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
getgenv().CreateTextBox = function(Name, Page, DefaultText, Callback, Placeholder)
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
    Label.Size = UDim2.new(1, -140, 1, 0)
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
    Input.Size = UDim2.new(0, 120, 0, 24)
    Input.Position = UDim2.new(1, -130, 0.5, -12)
    Input.BackgroundColor3 = Theme.Panel
    Input.BorderSizePixel = 0
    Input.Text = tostring(DefaultText or "")
    Input.PlaceholderText = Placeholder or "Type..."
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
    Input.FocusLost:Connect(function()
        if Callback then
            Callback(Input.Text)
        end
    end)
    if getgenv().RegisterToxSearchControl then
        getgenv().RegisterToxSearchControl(Name, Page, Box)
    end
    return Box
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
    Box.ClipsDescendants = true
    Box.Parent = parentTarget
    local bCorner = Instance.new("UICorner") bCorner.CornerRadius = UDim.new(0, 6) bCorner.Parent = Box
    local bStroke = Instance.new("UIStroke") bStroke.Color = Theme.Outline bStroke.Thickness = 1 bStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border bStroke.Parent = Box
    RegisterThemedObject(Box, "BackgroundColor3", "Element")
    RegisterThemedObject(bStroke, "Color", "Outline")
    local TopRow = Instance.new("Frame")
    TopRow.Size = UDim2.new(1, 0, 0, 36)
    TopRow.BackgroundTransparency = 1
    TopRow.Parent = Box
    local risky = IsFeatureRisky(Name)
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -140, 1, 0)
    Label.Position = UDim2.new(0, 12, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = Name
    Label.TextColor3 = risky and Theme.Risky or Theme.Text
    Label.TextSize = 12
    Label.Font = Enum.Font.GothamMedium
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = TopRow
    RegisterThemedObject(Label, "TextColor3", risky and "Risky" or "Text")
    local SelectedOption = DefaultOption
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(0, 120, 0, 24)
    Button.Position = UDim2.new(1, -128, 0.5, -12)
    Button.BackgroundColor3 = Theme.Panel
    Button.BorderSizePixel = 0
    Button.Text = tostring(DefaultOption) .. "  ▼"
    Button.TextColor3 = Theme.Accent
    Button.TextSize = 11
    Button.Font = Enum.Font.GothamBold
    Button.TextTruncate = Enum.TextTruncate.AtEnd
    Button.Parent = TopRow
    local btnCorner = Instance.new("UICorner") btnCorner.CornerRadius = UDim.new(0, 4) btnCorner.Parent = Button
    local btnStroke = Instance.new("UIStroke") btnStroke.Color = Theme.Outline btnStroke.Thickness = 1 btnStroke.Parent = Button
    RegisterThemedObject(Button, "BackgroundColor3", "Panel")
    RegisterThemedObject(Button, "TextColor3", "Accent")
    RegisterThemedObject(btnStroke, "Color", "Outline")
    local itemHeight = 24
    local maxVisibleItems = 5
    local listHeight = math.min(#Options * (itemHeight + 2), maxVisibleItems * (itemHeight + 2))
    local totalOpenHeight = 36 + listHeight + 8
    local DropdownScroll = Instance.new("ScrollingFrame")
    DropdownScroll.Size = UDim2.new(1, -16, 0, listHeight)
    DropdownScroll.Position = UDim2.new(0, 8, 0, 36)
    DropdownScroll.BackgroundColor3 = Theme.Panel
    DropdownScroll.BorderSizePixel = 0
    DropdownScroll.ScrollBarThickness = 3
    DropdownScroll.ScrollBarImageColor3 = Theme.Accent
    DropdownScroll.CanvasSize = UDim2.new(0, 0, 0, #Options * (itemHeight + 2))
    DropdownScroll.Visible = false
    DropdownScroll.Parent = Box
    local dsCorner = Instance.new("UICorner") dsCorner.CornerRadius = UDim.new(0, 4) dsCorner.Parent = DropdownScroll
    local dsStroke = Instance.new("UIStroke") dsStroke.Color = Theme.Outline dsStroke.Thickness = 1 dsStroke.Parent = DropdownScroll
    RegisterThemedObject(DropdownScroll, "BackgroundColor3", "Panel")
    RegisterThemedObject(dsStroke, "Color", "Outline")
    local dsLayout = Instance.new("UIListLayout")
    dsLayout.Padding = UDim.new(0, 2)
    dsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    dsLayout.Parent = DropdownScroll
    local dsPadding = Instance.new("UIPadding")
    dsPadding.PaddingTop = UDim.new(0, 2)
    dsPadding.PaddingBottom = UDim.new(0, 2)
    dsPadding.PaddingLeft = UDim.new(0, 4)
    dsPadding.PaddingRight = UDim.new(0, 4)
    dsPadding.Parent = DropdownScroll
    local isOpen = false
    local OptionButtons = {}
    local function RefreshOptionButtons()
        for optVal, optBtn in pairs(OptionButtons) do
            if optVal == SelectedOption then
                optBtn.TextColor3 = Theme.Accent
                optBtn.BackgroundColor3 = Theme.Element
            else
                optBtn.TextColor3 = Theme.Text
                optBtn.BackgroundColor3 = Theme.Panel
            end
        end
    end
    for idx, opt in ipairs(Options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Size = UDim2.new(1, -2, 0, itemHeight)
        optBtn.BackgroundColor3 = (opt == SelectedOption) and Theme.Element or Theme.Panel
        optBtn.BorderSizePixel = 0
        optBtn.Text = tostring(opt)
        optBtn.TextColor3 = (opt == SelectedOption) and Theme.Accent or Theme.Text
        optBtn.TextSize = 11
        optBtn.Font = Enum.Font.GothamMedium
        optBtn.TextXAlignment = Enum.TextXAlignment.Left
        optBtn.LayoutOrder = idx
        optBtn.Parent = DropdownScroll
        local obCorner = Instance.new("UICorner") obCorner.CornerRadius = UDim.new(0, 3) obCorner.Parent = optBtn
        local obPad = Instance.new("UIPadding") obPad.PaddingLeft = UDim.new(0, 8) obPad.Parent = optBtn
        OptionButtons[opt] = optBtn
        optBtn.MouseButton1Click:Connect(function()
            if getgenv().Destroyed then return end
            SelectedOption = opt
            Button.Text = tostring(opt) .. "  ▼"
            RefreshOptionButtons()
            isOpen = false
            DropdownScroll.Visible = false
            TweenService:Create(Box, TweenInfo.new(0.18, Enum.EasingStyle.Quad), { Size = UDim2.new(1, -4, 0, 36) }):Play()
            if Callback then Callback(opt) end
            AutoSaveConfiguration()
        end)
    end
    local function ToggleOpen()
        isOpen = not isOpen
        if isOpen then
            DropdownScroll.Visible = true
            RefreshOptionButtons()
            Button.Text = tostring(SelectedOption) .. "  ▲"
            TweenService:Create(Box, TweenInfo.new(0.2, Enum.EasingStyle.Quad), { Size = UDim2.new(1, -4, 0, totalOpenHeight) }):Play()
        else
            Button.Text = tostring(SelectedOption) .. "  ▼"
            TweenService:Create(Box, TweenInfo.new(0.18, Enum.EasingStyle.Quad), { Size = UDim2.new(1, -4, 0, 36) }):Play()
            task.delay(0.2, function()
                if not isOpen then DropdownScroll.Visible = false end
            end)
        end
    end
    Button.MouseButton1Click:Connect(function()
        if getgenv().Destroyed then return end
        ToggleOpen()
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
    Button.MouseEnter:Connect(function()
        if getgenv().Destroyed then return end
        TweenService:Create(Button, TweenInfo.new(0.12), { BackgroundColor3 = Theme.Hover }):Play()
    end)
    Button.MouseLeave:Connect(function()
        if getgenv().Destroyed then return end
        TweenService:Create(Button, TweenInfo.new(0.12), { BackgroundColor3 = Theme.Element }):Play()
    end)
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
    Button.MouseEnter:Connect(function()
        if getgenv().Destroyed or Confirming then return end
        TweenService:Create(Button, TweenInfo.new(0.12), { BackgroundColor3 = Theme.Hover }):Play()
    end)
    Button.MouseLeave:Connect(function()
        if getgenv().Destroyed or Confirming then return end
        TweenService:Create(Button, TweenInfo.new(0.12), { BackgroundColor3 = Theme.Element }):Play()
    end)
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
    local initialToggle = DefaultToggle
    if SyncKey and Settings[SyncKey] ~= nil then
        initialToggle = Settings[SyncKey]
    end
    local Enabled = (initialToggle == true)
    local Toggle = Instance.new("TextButton")
    Toggle.Size = UDim2.new(0, 38, 0, 20)
    Toggle.Position = UDim2.new(1, -48, 0.5, -10)
    Toggle.BackgroundColor3 = Enabled and Theme.Accent or Theme.Panel
    Toggle.BorderSizePixel = 0
    Toggle.Text = ""
    Toggle.AutoButtonColor = false
    Toggle.Parent = Box
    local tgCorner = Instance.new("UICorner") tgCorner.CornerRadius = UDim.new(1, 0) tgCorner.Parent = Toggle
    local tgStroke = Instance.new("UIStroke") tgStroke.Color = Theme.Outline tgStroke.Thickness = 1 tgStroke.Parent = Toggle
    RegisterThemedObject(tgStroke, "Color", "Outline")
    local Indicator = Instance.new("Frame")
    Indicator.Size = UDim2.new(0, 14, 0, 14)
    Indicator.Position = Enabled and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
    Indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Indicator.BorderSizePixel = 0
    Indicator.Parent = Toggle
    local indCorner = Instance.new("UICorner") indCorner.CornerRadius = UDim.new(1, 0) indCorner.Parent = Indicator
    local Binding = false
    local CurrentKey = DefaultKey
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
        if env.Destroyed or Binding then return end
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
    for _, runFn in ipairs(DeferredStartupCallbacks) do
        task.defer(runFn)
    end
    DeferredStartupCallbacks = {}
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
UI.RegisterSharedToggle = RegisterSharedToggle
UI.RegisterStartupToggleCallback = RegisterStartupToggleCallback
UI.RegisterSharedValue = RegisterSharedValue
