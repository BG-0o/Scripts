local env = getgenv()

if type(env.ToxUniversal2Cleanup) == "function" then
    pcall(env.ToxUniversal2Cleanup)
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Player = Players.LocalPlayer
local Settings = env.Settings or {}
local UniversalPage = env.UniversalPage
local FREECAM_BIND = "ToxUniversalFreecam"
local instanceToken = {}

env.ToxUniversal2Token = instanceToken

Settings.UniversalCollapsedSections =
    typeof(Settings.UniversalCollapsedSections) == "table"
    and Settings.UniversalCollapsedSections
    or {}

Settings.NoclipCamera = Settings.NoclipCamera == true
Settings.Freecam = Settings.Freecam == true
Settings.FreecamSpeed = tonumber(Settings.FreecamSpeed) or 50
Settings.ESPShowHealth = Settings.ESPShowHealth == true
Settings.ChamsOutlineColorName = tostring(Settings.ChamsOutlineColorName or "White")
Settings.ChamsOutlineOpacity = math.clamp(tonumber(Settings.ChamsOutlineOpacity) or 50, 0, 100)
Settings.VisualRainbow = Settings.VisualRainbow == true
Settings.RainbowSpeed = math.clamp(tonumber(Settings.RainbowSpeed) or 10, 0.1, 100)
Settings.XRay = Settings.XRay == true
Settings.XRayTransparency = math.clamp(tonumber(Settings.XRayTransparency) or 0.7, 0, 1)
Settings.FakeLag = Settings.FakeLag == true
Settings.LagChance = math.clamp(tonumber(Settings.LagChance) or 70, 0, 100)

env.Settings = Settings
env.ToxUniversalSections = {}
env.ToxUniversalCurrentSection = nil

local freecamActive = false
local freecamPosition = Vector3.zero
local freecamPitch = 0
local freecamYaw = 0
local freecamSaved = nil
local cameraNoclipCaptured = false
local originalOcclusionMode = nil
local cameraControlsInstalled = false
local visualUIInstalled = false
local visualConnections = {}
local xrayDefaults = setmetatable({}, {__mode = "k"})
local fakeLagSleeping = false
local lastRainbowColor = nil
local fakeLagClock = 0
local VISUAL_BIND = "ToxUniversal2Visuals"

local function ApplyUniversalSectionState(section)
    if typeof(section) ~= "table" then
        return
    end

    local collapsed = Settings.UniversalCollapsedSections[section.Key] == true

    if section.Header and section.Header.Parent then
        section.Header.Text = collapsed
            and "  > " .. section.Name
            or "  v " .. section.Name
    end

    for _, object in ipairs(section.Controls) do
        if object
        and object.Parent
        and object:IsA("GuiObject") then
            object.Visible = not collapsed
        end
    end
end

env.ApplyUniversalSectionState = ApplyUniversalSectionState

local function BaseBeginUniversalSection(name)
    if not UniversalPage then
        UniversalPage = env.UniversalPage
    end

    if not UniversalPage then
        return nil
    end

    local key = string.upper(tostring(name or "")):gsub("%s+", "")
    local header = Instance.new("TextButton")
    header.Size = UDim2.new(1, -5, 0, 30)
    header.BackgroundColor3 = Color3.fromRGB(13, 13, 21)
    header.BorderSizePixel = 0
    header.TextColor3 = Color3.fromRGB(255, 255, 255)
    header.Font = Enum.Font.GothamBold
    header.TextSize = 12
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.AutoButtonColor = false
    header.Parent = UniversalPage

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = header

    local section = {
        Name = tostring(name),
        Key = key,
        Header = header,
        Controls = {}
    }

    table.insert(env.ToxUniversalSections, section)
    env.ToxUniversalCurrentSection = section

    header.MouseButton1Click:Connect(function()
        Settings.UniversalCollapsedSections[key] =
            not Settings.UniversalCollapsedSections[key]

        ApplyUniversalSectionState(section)

        if env.AutoSaveConfiguration then
            env.AutoSaveConfiguration()
        elseif AutoSaveConfiguration then
            AutoSaveConfiguration()
        end
    end)

    ApplyUniversalSectionState(section)
    return section
end

local function TrackUniversalControl(object, page)
    local currentSection = env.ToxUniversalCurrentSection
    local universalPage = env.UniversalPage or UniversalPage

    if page == universalPage
    and currentSection
    and object
    and object:IsA("GuiObject") then
        table.insert(currentSection.Controls, object)
        ApplyUniversalSectionState(currentSection)
    end

    return object
end

env.TrackUniversalControl = TrackUniversalControl

local raw = {
    CreateToggle = env.CreateToggle,
    CreateToggleWithValue = env.CreateToggleWithValue,
    CreateInputWithButton = env.CreateInputWithButton,
    CreateInputWithTwoButtons = env.CreateInputWithTwoButtons,
    CreateDropdown = env.CreateDropdown,
    CreateButton = env.CreateButton,
    CreateConfirmButton = env.CreateConfirmButton,
    CreateKeybindButton = env.CreateKeybindButton,
    CreateKeybindToggle = env.CreateKeybindToggle
}

env.ToxUniversalRawCreators = raw

function CreateToggle(name, page, ...)
    return TrackUniversalControl(
        raw.CreateToggle(name, page, ...),
        page
    )
end

function CreateToggleWithValue(name, page, ...)
    return TrackUniversalControl(
        raw.CreateToggleWithValue(name, page, ...),
        page
    )
end

function CreateInputWithButton(name, page, ...)
    return TrackUniversalControl(
        raw.CreateInputWithButton(name, page, ...),
        page
    )
end

function CreateInputWithTwoButtons(name, page, ...)
    return TrackUniversalControl(
        raw.CreateInputWithTwoButtons(name, page, ...),
        page
    )
end

function CreateDropdown(name, options, page, ...)
    return TrackUniversalControl(
        raw.CreateDropdown(name, options, page, ...),
        page
    )
end

function CreateButton(name, page, ...)
    return TrackUniversalControl(
        raw.CreateButton(name, page, ...),
        page
    )
end

function CreateConfirmButton(name, page, ...)
    return TrackUniversalControl(
        raw.CreateConfirmButton(name, page, ...),
        page
    )
end

function CreateKeybindButton(name, page, ...)
    return TrackUniversalControl(
        raw.CreateKeybindButton(name, page, ...),
        page
    )
end

function CreateKeybindToggle(name, page, ...)
    return TrackUniversalControl(
        raw.CreateKeybindToggle(name, page, ...),
        page
    )
end

env.CreateToggle = CreateToggle
env.CreateToggleWithValue = CreateToggleWithValue
env.CreateInputWithButton = CreateInputWithButton
env.CreateInputWithTwoButtons = CreateInputWithTwoButtons
env.CreateDropdown = CreateDropdown
env.CreateButton = CreateButton
env.CreateConfirmButton = CreateConfirmButton
env.CreateKeybindButton = CreateKeybindButton
env.CreateKeybindToggle = CreateKeybindToggle

local function RestoreCameraNoclip()
    if not cameraNoclipCaptured then
        return
    end

    pcall(function()
        if originalOcclusionMode then
            Player.DevCameraOcclusionMode = originalOcclusionMode
        end
    end)

    cameraNoclipCaptured = false
    originalOcclusionMode = nil
end

local function SetNoclipCamera(enabled)
    enabled = enabled == true
    Settings.NoclipCamera = enabled

    if enabled then
        if not cameraNoclipCaptured then
            pcall(function()
                originalOcclusionMode = Player.DevCameraOcclusionMode
                cameraNoclipCaptured = true
            end)
        end

        pcall(function()
            Player.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
        end)
    else
        RestoreCameraNoclip()
    end
end

local function StopFreecam()
    pcall(function()
        RunService:UnbindFromRenderStep(FREECAM_BIND)
    end)

    if not freecamActive then
        return
    end

    freecamActive = false

    local camera = Workspace.CurrentCamera
    local saved = freecamSaved

    if camera and saved then
        pcall(function()
            local subject = saved.CameraSubject

            if not subject or subject.Parent == nil then
                subject = Player.Character
                    and Player.Character:FindFirstChildOfClass("Humanoid")
            end

            if subject then
                camera.CameraSubject = subject
            end

            camera.CameraType = saved.CameraType or Enum.CameraType.Custom
            camera.CFrame = saved.CFrame or camera.CFrame
            camera.Focus = saved.Focus or camera.Focus
        end)
    elseif camera then
        pcall(function()
            camera.CameraType = Enum.CameraType.Custom
            local humanoid = Player.Character
                and Player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                camera.CameraSubject = humanoid
            end
        end)
    end

    if saved then
        pcall(function()
            UserInputService.MouseBehavior = saved.MouseBehavior
            UserInputService.MouseIconEnabled = saved.MouseIconEnabled
        end)
    else
        pcall(function()
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
            UserInputService.MouseIconEnabled = true
        end)
    end

    freecamSaved = nil
end

local function UpdateFreecam(delta)
    if not freecamActive
    or Settings.Freecam ~= true
    or env.Destroyed then
        StopFreecam()
        return
    end

    local camera = Workspace.CurrentCamera
    if not camera then
        return
    end

    if camera.CameraType ~= Enum.CameraType.Scriptable then
        camera.CameraType = Enum.CameraType.Scriptable
    end

    local rotating = UserInputService:IsMouseButtonPressed(
        Enum.UserInputType.MouseButton2
    )

    if rotating then
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        UserInputService.MouseIconEnabled = false

        local mouseDelta = UserInputService:GetMouseDelta()
        freecamYaw = freecamYaw - mouseDelta.X * 0.0025
        freecamPitch = math.clamp(
            freecamPitch - mouseDelta.Y * 0.0025,
            math.rad(-89),
            math.rad(89)
        )
    elseif freecamSaved then
        UserInputService.MouseBehavior = freecamSaved.MouseBehavior
        UserInputService.MouseIconEnabled = freecamSaved.MouseIconEnabled
    end

    local orientation =
        CFrame.Angles(0, freecamYaw, 0)
        * CFrame.Angles(freecamPitch, 0, 0)

    local move = Vector3.zero

    if UserInputService:GetFocusedTextBox() == nil then
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            move += orientation.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            move -= orientation.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            move -= orientation.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            move += orientation.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.E)
        or UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            move += Vector3.yAxis
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Q)
        or UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            move -= Vector3.yAxis
        end
    end

    local speed = math.clamp(
        tonumber(Settings.FreecamSpeed) or 50,
        1,
        500
    )

    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
    or UserInputService:IsKeyDown(Enum.KeyCode.RightShift) then
        speed *= 3
    end

    if move.Magnitude > 0 then
        move = move.Unit
        freecamPosition += move * speed * math.max(tonumber(delta) or 0, 0)
    end

    local frame = CFrame.new(freecamPosition) * orientation
    camera.CFrame = frame
    camera.Focus = frame * CFrame.new(0, 0, -512)
end

local function StartFreecam()
    if freecamActive then
        return
    end

    local camera = Workspace.CurrentCamera
    if not camera then
        Settings.Freecam = false
        if env.SyncToggleVisuals then
            env.SyncToggleVisuals("Freecam", false)
        end
        return
    end

    local pitch, yaw = camera.CFrame:ToOrientation()

    freecamSaved = {
        CameraType = camera.CameraType,
        CameraSubject = camera.CameraSubject,
        CFrame = camera.CFrame,
        Focus = camera.Focus,
        MouseBehavior = UserInputService.MouseBehavior,
        MouseIconEnabled = UserInputService.MouseIconEnabled
    }

    freecamPosition = camera.CFrame.Position
    freecamPitch = pitch
    freecamYaw = yaw
    freecamActive = true

    camera.CameraType = Enum.CameraType.Scriptable

    pcall(function()
        RunService:UnbindFromRenderStep(FREECAM_BIND)
    end)

    RunService:BindToRenderStep(
        FREECAM_BIND,
        Enum.RenderPriority.Last.Value,
        UpdateFreecam
    )
end

local function SetFreecam(enabled)
    enabled = enabled == true
    Settings.Freecam = enabled

    if enabled then
        StartFreecam()
    else
        StopFreecam()
    end
end

local function SaveVisualSettings()
    if env.ScriptLoaded
    and env.ToxOptionsReady ~= false
    and type(env.AutoSaveConfiguration) == "function" then
        pcall(env.AutoSaveConfiguration)
    end
end

local function VisualNotify(text, color)
    if type(env.CustomNotify) == "function" then
        env.CustomNotify(text, color or Color3.fromRGB(180, 200, 255), 4)
    end
end

local function IsCharacterPart(part)
    local model = part and part:FindFirstAncestorOfClass("Model")
    return model ~= nil and model:FindFirstChildOfClass("Humanoid") ~= nil
end

local function ApplyXRayPart(part)
    if not Settings.XRay
    or not part
    or not part:IsA("BasePart")
    or IsCharacterPart(part) then
        return
    end

    if xrayDefaults[part] == nil then
        local ok, value = pcall(function()
            return part.LocalTransparencyModifier
        end)
        xrayDefaults[part] = ok and value or 0
    end

    pcall(function()
        part.LocalTransparencyModifier = math.max(
            tonumber(xrayDefaults[part]) or 0,
            math.clamp(tonumber(Settings.XRayTransparency) or 0.7, 0, 1)
        )
    end)
end

local function ApplyXRayAll()
    if not Settings.XRay then
        return
    end

    for _, object in ipairs(Workspace:GetDescendants()) do
        if object:IsA("BasePart") then
            ApplyXRayPart(object)
        end
    end
end

local function RestoreXRay()
    for part, value in pairs(xrayDefaults) do
        if part and part.Parent then
            pcall(function()
                part.LocalTransparencyModifier = tonumber(value) or 0
            end)
        end
    end

    xrayDefaults = setmetatable({}, {__mode = "k"})
end

local function SetXRay(enabled)
    Settings.XRay = enabled == true

    if Settings.XRay then
        ApplyXRayAll()
    else
        RestoreXRay()
    end
end

local function SetFakeLag(enabled)
    Settings.FakeLag = enabled == true

    if not Settings.FakeLag and fakeLagSleeping then
        local root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if root and type(sethiddenproperty) == "function" then
            pcall(sethiddenproperty, root, "NetworkIsSleeping", false)
        end
        fakeLagSleeping = false
    end
end

local function SetNetworkSleeping(root, sleeping)
    if not root or type(sethiddenproperty) ~= "function" then
        return false
    end

    local ok = pcall(sethiddenproperty, root, "NetworkIsSleeping", sleeping == true)
    if ok then
        fakeLagSleeping = sleeping == true
    end
    return ok
end

local function ApplyRainbow()
    if not Settings.VisualRainbow then
        if lastRainbowColor ~= nil then
            local colors = env.ColorMap
            local restore = typeof(colors) == "table"
                and colors[Settings.EspColorName]
                or nil

            if typeof(restore) == "Color3" then
                Settings.EspColor = restore
            end

            lastRainbowColor = nil
        end
        return
    end

    local speed = math.clamp(tonumber(Settings.RainbowSpeed) or 10, 0.1, 100)
    local hue = (tick() * speed * 0.025) % 1
    local color = Color3.fromHSV(hue, 1, 1)
    lastRainbowColor = color
    Settings.EspColor = color

    local highlights = env.ToxESPHighlights
    if typeof(highlights) == "table" then
        for _, highlight in pairs(highlights) do
            if highlight and highlight.Parent then
                pcall(function()
                    highlight.FillColor = color
                    highlight.OutlineColor = color
                end)
            end
        end
    end

    local drawings = env.ToxESPDrawings
    if typeof(drawings) == "table" then
        for _, group in pairs(drawings) do
            if typeof(group) == "table" then
                for _, drawing in pairs(group) do
                    pcall(function()
                        drawing.Color = color
                    end)
                end
            end
        end
    end

    local labels = env.ToxESPLabels
    if typeof(labels) == "table" then
        for _, billboard in pairs(labels) do
            local label = billboard and billboard:FindFirstChild("Label")
            if label then
                label.TextColor3 = color
            end
        end
    end
end

local function ApplyOutlineSettings()
    local highlights = env.ToxESPHighlights
    if typeof(highlights) ~= "table" then
        return
    end

    local colors = env.ColorMap
    local outline = typeof(colors) == "table"
        and colors[Settings.ChamsOutlineColorName]
        or Color3.fromRGB(255, 255, 255)
    local transparency = 1 - (
        math.clamp(tonumber(Settings.ChamsOutlineOpacity) or 50, 0, 100) / 100
    )

    for _, highlight in pairs(highlights) do
        if highlight and highlight.Parent then
            pcall(function()
                if Settings.VisualRainbow and lastRainbowColor then
                    highlight.OutlineColor = lastRainbowColor
                else
                    highlight.OutlineColor = outline
                end
                highlight.OutlineTransparency = transparency
            end)
        end
    end
end

local function CreateVisualNumberOption(name, page, defaultValue, minValue, maxValue, callback)
    local box = Instance.new("Frame")
    box.Size = UDim2.new(1, -5, 0, 39)
    box.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
    box.BorderSizePixel = 0
    box.Parent = page

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -80, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(240, 240, 240)
    label.TextSize = 13
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = box

    local input = Instance.new("TextBox")
    input.Size = UDim2.new(0, 64, 0, 25)
    input.Position = UDim2.new(1, -72, 0.5, -12)
    input.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
    input.BorderSizePixel = 0
    input.Text = tostring(defaultValue)
    input.TextColor3 = Color3.fromRGB(255, 255, 255)
    input.TextSize = 11
    input.Font = Enum.Font.Gotham
    input.ClearTextOnFocus = false
    input.Parent = box

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = input

    input.FocusLost:Connect(function()
        if env.Destroyed or env.ToxOptionsReady == false then
            return
        end

        local value = tonumber(input.Text)
        if not value then
            input.Text = tostring(defaultValue)
            return
        end

        value = math.clamp(value, minValue, maxValue)
        input.Text = tostring(value)
        callback(value)
        SaveVisualSettings()
    end)

    if type(env.TrackUniversalControl) == "function" then
        env.TrackUniversalControl(box, page)
    end

    if type(env.RegisterToxSearchControl) == "function" then
        env.RegisterToxSearchControl(name, page, box)
    end

    return box
end

local function InstallVisualUI(page)
    if visualUIInstalled or not page then
        return
    end

    local Toggle = env.CreateToggle
    local ToggleWithValue = env.CreateToggleWithValue
    local Dropdown = env.CreateDropdown

    if type(Toggle) ~= "function"
    or type(ToggleWithValue) ~= "function"
    or type(Dropdown) ~= "function" then
        return
    end

    visualUIInstalled = true

    Toggle(
        "Show Health",
        page,
        Settings.ESPShowHealth,
        function(value)
            Settings.ESPShowHealth = value == true
        end,
        "ESPShowHealth"
    )

    Dropdown(
        "Outline Color",
        {"White", "Red", "Green", "Blue", "Yellow", "Cyan", "Magenta", "Orange", "Purple", "Lime", "Pink", "Gold"},
        page,
        Settings.ChamsOutlineColorName,
        function(value)
            Settings.ChamsOutlineColorName = tostring(value)
        end
    )

    CreateVisualNumberOption(
        "Outline Opacity",
        page,
        Settings.ChamsOutlineOpacity,
        0,
        100,
        function(value)
            Settings.ChamsOutlineOpacity = value
        end
    )

    Toggle(
        "Rainbow",
        page,
        Settings.VisualRainbow,
        function(value)
            Settings.VisualRainbow = value == true
            if not Settings.VisualRainbow then
                ApplyRainbow()
            end
        end,
        "VisualRainbow"
    )

    CreateVisualNumberOption(
        "Rainbow Speed",
        page,
        Settings.RainbowSpeed,
        0.1,
        100,
        function(value)
            Settings.RainbowSpeed = value
        end
    )

    ToggleWithValue(
        "XRay",
        page,
        Settings.XRay,
        Settings.XRayTransparency,
        SetXRay,
        function(value)
            Settings.XRayTransparency = math.clamp(tonumber(value) or 0.7, 0, 1)
            if Settings.XRay then
                ApplyXRayAll()
            end
        end,
        "XRay"
    )

    Toggle(
        "Fake Lag",
        page,
        Settings.FakeLag,
        function(value)
            if value and type(sethiddenproperty) ~= "function" then
                Settings.FakeLag = false
                if type(env.SyncToggleVisuals) == "function" then
                    env.SyncToggleVisuals("FakeLag", false)
                end
                VisualNotify("Fake Lag unsupported by this executor", Color3.fromRGB(255, 180, 70))
                return
            end
            SetFakeLag(value)
        end,
        "FakeLag"
    )

    CreateVisualNumberOption(
        "Lag Chance",
        page,
        Settings.LagChance,
        0,
        100,
        function(value)
            Settings.LagChance = value
        end
    )
end

local function InstallCameraControls(page)
    if cameraControlsInstalled or not page then
        return
    end

    cameraControlsInstalled = true

    CreateToggle(
        "Noclip Camera",
        page,
        Settings.NoclipCamera,
        SetNoclipCamera,
        "NoclipCamera"
    )

    CreateToggleWithValue(
        "Freecam",
        page,
        Settings.Freecam,
        Settings.FreecamSpeed,
        SetFreecam,
        function(value)
            Settings.FreecamSpeed = math.clamp(
                tonumber(value) or 50,
                1,
                500
            )
        end,
        "Freecam"
    )
end

function BeginUniversalSection(name)
    local key = string.upper(tostring(name or "")):gsub("%s+", "")

    if key == "MISC" then
        local visualPage = env.VisualsPage or UniversalPage

        if not cameraControlsInstalled then
            InstallCameraControls(visualPage)
        end

        if not visualUIInstalled then
            InstallVisualUI(visualPage)
        end
    end

    return BaseBeginUniversalSection(name)
end

env.BeginUniversalSection = BeginUniversalSection

env.ToxSetNoclipCamera = SetNoclipCamera
env.ToxSetFreecam = SetFreecam
env.ToxSetXRay = SetXRay
env.ToxSetFakeLag = SetFakeLag
env.ToxResetPart2Visuals = function()
    RestoreXRay()
    SetFakeLag(false)
    ApplyRainbow()
end

visualConnections[#visualConnections + 1] = Workspace.DescendantAdded:Connect(function(object)
    if Settings.XRay and object:IsA("BasePart") then
        task.defer(ApplyXRayPart, object)
    end
end)

pcall(function()
    RunService:UnbindFromRenderStep(VISUAL_BIND)
end)

RunService:BindToRenderStep(
    VISUAL_BIND,
    Enum.RenderPriority.Last.Value + 50,
    function(delta)
        if env.ToxUniversal2Token ~= instanceToken
        or env.Destroyed
        or not env.ScriptLoaded then
            return
        end

        ApplyRainbow()
        ApplyOutlineSettings()

        fakeLagClock += math.max(tonumber(delta) or 0, 0)
        if Settings.FakeLag and fakeLagClock >= 0.14 then
            fakeLagClock = 0
            local root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            local chance = math.clamp(tonumber(Settings.LagChance) or 70, 0, 100)
            local shouldSleep = math.random(1, 100) <= chance
            SetNetworkSleeping(root, shouldSleep)
        elseif not Settings.FakeLag then
            fakeLagClock = 0
            if fakeLagSleeping then
                SetFakeLag(false)
            end
        end
    end
)

task.spawn(function()
    while env.ToxUniversal2Token == instanceToken
    and not env.Destroyed
    and not env.ScriptLoaded do
        task.wait(0.05)
    end

    if env.ToxUniversal2Token == instanceToken
    and not env.Destroyed
    and Settings.XRay then
        ApplyXRayAll()
    end
end)

env.ToxUniversal2Cleanup = function()
    if type(env.ToxUniversal3Cleanup) == "function" then
        pcall(env.ToxUniversal3Cleanup)
    end

    pcall(function()
        RunService:UnbindFromRenderStep(VISUAL_BIND)
    end)

    for _, connection in ipairs(visualConnections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    visualConnections = {}

    RestoreXRay()
    SetFakeLag(false)

    if Settings.VisualRainbow then
        Settings.VisualRainbow = false
        ApplyRainbow()
        Settings.VisualRainbow = true
    else
        ApplyRainbow()
    end

    StopFreecam()
    RestoreCameraNoclip()

    if env.ToxUniversal2Token == instanceToken then
        env.ToxUniversal2Token = nil
    end
end

task.spawn(function()
    while env.ToxUniversal2Token == instanceToken
    and not env.Destroyed do
        task.wait(0.1)
    end

    if env.ToxUniversal2Token == instanceToken
    and env.Destroyed then
        env.ToxUniversal2Cleanup()
    end
end)

local universal3Ok, universal3Error = pcall(function()
    local source = game:HttpGet(
        "https://raw.githubusercontent.com/BG-0o/Scripts/refs/heads/main/Universal3.lua?toxv=2026-09-14-part1-part2-merged"
    )
    local chunk, compileError = loadstring(source)

    if not chunk then
        error(compileError)
    end

    chunk()
end)

if not universal3Ok then
    if type(env.CustomNotify) == "function" then
        env.CustomNotify(
            "Universal3.lua failed: " .. string.sub(tostring(universal3Error), 1, 90),
            Color3.fromRGB(255, 100, 100),
            6
        )
    end

    warn("[ToxHub Universal3.lua Error]: " .. tostring(universal3Error))
end

env.ToxUniversal2Loaded = true
env.ToxUniversal2Version = "2026-09-14-camera-visuals-plus-universal3"
