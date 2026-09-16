local env = getgenv()

if type(env.ToxUniversal2Cleanup) == "function" then
    pcall(env.ToxUniversal2Cleanup)
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local Workspace = game:GetService("Workspace")

local UserGameSettings = nil
pcall(function()
    UserGameSettings = UserSettings():GetService("UserGameSettings")
end)

local Player = Players.LocalPlayer
local originalCameraMaxZoomDistance = tonumber(Player.CameraMaxZoomDistance) or 400
local Settings = env.Settings or {}
local UniversalPage = env.UniversalPage
local FREECAM_BIND = "ToxUniversalFreecam"
local CAMERA_NOCLIP_BIND = "ToxCameraNoclip"
local FREECAM_ROTATION_SPEED_MOUSE = Vector2.new(1, 0.77) * math.rad(0.5)
local instanceToken = {}

env.ToxUniversal2Token = instanceToken
env.ToxUniversal2OwnsAimbot = true

Settings.UniversalCollapsedSections =
    typeof(Settings.UniversalCollapsedSections) == "table"
    and Settings.UniversalCollapsedSections
    or {}

Settings.NoclipCamera = Settings.NoclipCamera == true
Settings.Freecam = Settings.Freecam == true
Settings.AimbotMode = string.upper(tostring(Settings.AimbotMode or "CAMERA"))
if Settings.AimbotMode ~= "CAMERA" and Settings.AimbotMode ~= "MOUSE" then
    Settings.AimbotMode = "CAMERA"
end
Settings.AimbotBindEnabled = Settings.AimbotBindEnabled == true
Settings.AimbotKey = Settings.AimbotKey or Enum.KeyCode.E
Settings.AimbotBlatant = Settings.AimbotBlatant == true
Settings.Render3DDisabled = Settings.Render3DDisabled == true
Settings.Render3DColor = string.upper(tostring(Settings.Render3DColor or "BLACK"))
Settings.FreecamSpeed = tonumber(Settings.FreecamSpeed) or 50
Settings.ESPShowHealth = Settings.ESPShowHealth == true
Settings.ChamsOutlineColorName = nil
Settings.ChamsOutlineOpacity = nil
Settings.VisualRainbow = Settings.VisualRainbow == true
Settings.RainbowSpeed = math.clamp(tonumber(Settings.RainbowSpeed) or 10, 0.1, 100)
Settings.XRay = Settings.XRay == true
Settings.XRayTransparency = math.clamp(tonumber(Settings.XRayTransparency) or 0.7, 0, 1)
Settings.FakeLag = Settings.FakeLag == true
Settings.LagChance = math.clamp(tonumber(Settings.LagChance) or 70, 0, 100)
Settings.ShiftLockKey = Settings.ShiftLockKey == "Ctrl" and "Ctrl" or "Shift"
Settings.MaxZoomDistance = math.clamp(
    tonumber(Settings.MaxZoomDistance) or originalCameraMaxZoomDistance,
    math.max(0.5, tonumber(Player.CameraMinZoomDistance) or 0.5),
    10000
)

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
local cameraNoclipDistance = nil
local visualUIInstalled = false
local visualConnections = {}
local xrayDefaults = setmetatable({}, {__mode = "k"})
local fakeLagSleeping = setmetatable({}, {__mode = "k"})
local lastRainbowColor = nil
local fakeLagClock = 0
local VISUAL_BIND = "ToxUniversal2Visuals"
local healthBillboards = setmetatable({}, {__mode = "k"})
local CAMERA_MOVEMENT_FREEZE_BIND = "ToxUniversalCameraMovementFreeze"
local cameraMovementFrozen = false

local function SinkCameraMovement()
    return Enum.ContextActionResult.Sink
end

local function ShouldFreezeCameraMovement()
    return freecamActive == true or Settings.NoclipCamera == true
end

local function RestoreCameraMovementFreeze(force)
    if not force and ShouldFreezeCameraMovement() then
        return
    end

    pcall(function()
        ContextActionService:UnbindAction(CAMERA_MOVEMENT_FREEZE_BIND)
    end)

    cameraMovementFrozen = false
end

local function ApplyCameraMovementFreeze()
    if not ShouldFreezeCameraMovement() then
        RestoreCameraMovementFreeze(true)
        return
    end

    if not cameraMovementFrozen then
        cameraMovementFrozen = true

        pcall(function()
            ContextActionService:UnbindAction(CAMERA_MOVEMENT_FREEZE_BIND)
            ContextActionService:BindActionAtPriority(
                CAMERA_MOVEMENT_FREEZE_BIND,
                SinkCameraMovement,
                false,
                3000,
                Enum.KeyCode.W,
                Enum.KeyCode.A,
                Enum.KeyCode.S,
                Enum.KeyCode.D,
                Enum.KeyCode.Up,
                Enum.KeyCode.Down,
                Enum.KeyCode.Left,
                Enum.KeyCode.Right,
                Enum.KeyCode.Space
            )
        end)
    end

    local character = Player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if humanoid and humanoid.Health > 0 then
        pcall(function()
            humanoid:Move(Vector3.zero, false)
            humanoid.Jump = false
        end)
    end

    if root then
        pcall(function()
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end)
    end
end

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

local function SaveUniversal2Settings()
    if env.ToxOptionsReady == false then
        return
    end

    if type(env.AutoSaveConfiguration) == "function" then
        pcall(env.AutoSaveConfiguration)
    end
end

local function CreateToggleCycleControl(name, options, page, defaultToggle, defaultMode, toggleCallback, modeCallback, syncKey)
    if not page then
        return nil
    end

    local box = Instance.new("Frame")
    box.Size = UDim2.new(1, -5, 0, 39)
    box.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
    box.BorderSizePixel = 0
    box.Parent = page

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -158, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(240, 240, 240)
    label.TextSize = 13
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = box

    local modeButton = Instance.new("TextButton")
    modeButton.Size = UDim2.new(0, 84, 0, 25)
    modeButton.Position = UDim2.new(1, -138, 0.5, -12)
    modeButton.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
    modeButton.BorderSizePixel = 0
    modeButton.Text = tostring(defaultMode or options[1])
    modeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    modeButton.TextSize = 10
    modeButton.Font = Enum.Font.GothamBold
    modeButton.Parent = box

    local modeCorner = Instance.new("UICorner")
    modeCorner.CornerRadius = UDim.new(0, 4)
    modeCorner.Parent = modeButton

    local toggleButton = Instance.new("TextButton")
    toggleButton.Size = UDim2.new(0, 38, 0, 20)
    toggleButton.Position = UDim2.new(1, -48, 0.5, -10)
    toggleButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    toggleButton.BorderSizePixel = 0
    toggleButton.Text = ""
    toggleButton.AutoButtonColor = false
    toggleButton.Parent = box

    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 4)
    toggleCorner.Parent = toggleButton

    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 14, 0, 14)
    indicator.Position = UDim2.new(0, 3, 0.5, -7)
    indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    indicator.BorderSizePixel = 0
    indicator.Parent = toggleButton

    local indicatorCorner = Instance.new("UICorner")
    indicatorCorner.CornerRadius = UDim.new(0, 3)
    indicatorCorner.Parent = indicator

    local state = env.ToxOptionsReady == false and false or defaultToggle == true

    local function updateToggle()
        if state then
            toggleButton.BackgroundColor3 = Color3.fromRGB(50, 180, 70)
            indicator.Position = UDim2.new(1, -17, 0.5, -7)
        else
            toggleButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
            indicator.Position = UDim2.new(0, 3, 0.5, -7)
        end
    end

    local function setVisual(value)
        state = value == true
        updateToggle()
    end

    if syncKey and type(env.RegisterSharedToggle) == "function" then
        pcall(env.RegisterSharedToggle, syncKey, {
            Button = box,
            SetVisual = setVisual
        })
    elseif syncKey and type(RegisterSharedToggle) == "function" then
        pcall(RegisterSharedToggle, syncKey, {
            Button = box,
            SetVisual = setVisual
        })
    end

    if syncKey and type(env.RegisterStartupToggleCallback) == "function" then
        pcall(env.RegisterStartupToggleCallback, syncKey, toggleCallback)
    end

    toggleButton.MouseButton1Click:Connect(function()
        if env.Destroyed or env.ToxOptionsReady == false then
            return
        end

        state = not state
        updateToggle()
        toggleCallback(state)

        if syncKey and type(env.SyncToggleVisuals) == "function" then
            pcall(env.SyncToggleVisuals, syncKey, state)
        end

        SaveUniversal2Settings()
    end)

    modeButton.MouseButton1Click:Connect(function()
        if env.Destroyed or env.ToxOptionsReady == false then
            return
        end

        local index = 1
        for i, option in ipairs(options) do
            if tostring(option) == tostring(modeButton.Text) then
                index = i
                break
            end
        end

        index += 1
        if index > #options then
            index = 1
        end

        modeButton.Text = tostring(options[index])
        modeCallback(options[index])
        SaveUniversal2Settings()
    end)

    updateToggle()
    TrackUniversalControl(box, page)

    if type(env.RegisterToxSearchControl) == "function" then
        env.RegisterToxSearchControl(name, page, box, options)
    end

    return box, setVisual
end

local function ApplyRender3DDisabled(disabled)
    disabled = disabled == true
    Settings.Render3DDisabled = disabled

    if type(env.ToxSetRender3DEnabled) == "function" then
        pcall(env.ToxSetRender3DEnabled, not disabled)
    else
        Settings.Render3D = not disabled
        pcall(function()
            RunService:Set3dRenderingEnabled(not disabled)
        end)
    end
end

local function ApplyRender3DColor(value)
    local normalized = string.upper(tostring(value or "BLACK"))
    Settings.Render3DColor = normalized

    if type(env.ToxSetRender3DColor) == "function" then
        pcall(env.ToxSetRender3DColor, normalized)
    end
end

function CreateToggle(name, page, ...)
    if name == "Aimbot (Right Click)" then
        return CreateToggleCycleControl(
            "Aimbot",
            {"CAMERA", "MOUSE"},
            page,
            Settings.Aimbot,
            Settings.AimbotMode,
            function(value)
                Settings.Aimbot = value == true
            end,
            function(value)
                Settings.AimbotMode = string.upper(tostring(value or "CAMERA"))
            end,
            "Aimbot"
        )
    end

    if name == "3D Rendering" then
        local control, setVisual = CreateToggleCycleControl(
            "3D Rendering",
            {"WHITE", "BLACK", "RED", "BLUE"},
            page,
            Settings.Render3DDisabled,
            Settings.Render3DColor,
            ApplyRender3DDisabled,
            ApplyRender3DColor,
            "Render3DDisabled"
        )

        env.ToxRender3DSetVisual = setVisual
        return control
    end

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
    if name == "3D Background" then
        return nil
    end

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

local function SetMaxZoomDistance(value)
    local minimum = math.max(0.5, tonumber(Player.CameraMinZoomDistance) or 0.5)
    local maximum = math.max(minimum, 10000)
    local distance = math.clamp(
        tonumber(value) or originalCameraMaxZoomDistance,
        minimum,
        maximum
    )

    Settings.MaxZoomDistance = distance

    pcall(function()
        Player.CameraMaxZoomDistance = distance
    end)

    return distance
end

local function RestoreCameraNoclip()
    pcall(function()
        RunService:UnbindFromRenderStep(CAMERA_NOCLIP_BIND)
    end)

    if cameraNoclipCaptured then
        pcall(function()
            if originalOcclusionMode then
                Player.DevCameraOcclusionMode = originalOcclusionMode
            end
        end)
    end

    cameraNoclipCaptured = false
    originalOcclusionMode = nil
    cameraNoclipDistance = nil
end

local function SetNoclipCamera(enabled)
    enabled = enabled == true
    Settings.NoclipCamera = enabled

    if enabled then
        if not cameraNoclipCaptured then
            pcall(function()
                originalOcclusionMode = Player.DevCameraOcclusionMode
            end)

            cameraNoclipCaptured = true
        end

        -- Invisicam keeps Roblox's native camera zoom/scroll behavior while
        -- allowing the camera to remain behind/through obstructing geometry.
        pcall(function()
            Player.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
        end)

        -- Make sure the old manual camera override from previous versions is gone.
        pcall(function()
            RunService:UnbindFromRenderStep(CAMERA_NOCLIP_BIND)
        end)

        ApplyCameraMovementFreeze()
    else
        RestoreCameraNoclip()
        RestoreCameraMovementFreeze()
    end
end

SetMaxZoomDistance(Settings.MaxZoomDistance)

local function StopFreecam()
    pcall(function()
        RunService:UnbindFromRenderStep(FREECAM_BIND)
    end)

    if not freecamActive then
        RestoreCameraMovementFreeze()
        return
    end

    freecamActive = false
    RestoreCameraMovementFreeze()

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
        local invertY = 1
        local sensitivity = 1

        if UserGameSettings then
            pcall(function()
                invertY = UserGameSettings:GetCameraYInvertValue()
            end)

            pcall(function()
                sensitivity = tonumber(UserGameSettings.MouseSensitivity) or 1
            end)
        end

        sensitivity = math.clamp(sensitivity, 0.01, 20)

        freecamYaw =
            freecamYaw
            - mouseDelta.X
                * FREECAM_ROTATION_SPEED_MOUSE.X
                * sensitivity

        freecamPitch = math.clamp(
            freecamPitch
            - mouseDelta.Y
                * FREECAM_ROTATION_SPEED_MOUSE.Y
                * sensitivity
                * invertY,
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
    ApplyCameraMovementFreeze()

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

local function SetNetworkSleeping(root, sleeping)
    if not root or type(sethiddenproperty) ~= "function" then
        return false
    end

    local ok = pcall(sethiddenproperty, root, "NetworkIsSleeping", sleeping == true)

    if ok then
        if sleeping then
            fakeLagSleeping[root] = true
        else
            fakeLagSleeping[root] = nil
        end
    end

    return ok
end

local function SetFakeLag(enabled)
    Settings.FakeLag = enabled == true

    if not Settings.FakeLag then
        for root in pairs(fakeLagSleeping) do
            if root and root.Parent then
                SetNetworkSleeping(root, false)
            else
                fakeLagSleeping[root] = nil
            end
        end
    end
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

local function ClearHealthBillboards()
    for player, billboard in pairs(healthBillboards) do
        if billboard then
            pcall(function()
                billboard:Destroy()
            end)
        end
        healthBillboards[player] = nil
    end
end

local function UpdateHealthESP()
    if not Settings.ESPShowHealth
    or not Settings.ESPEnabled then
        ClearHealthBillboards()
        return
    end

    local localRoot = Player.Character
        and Player.Character:FindFirstChild("HumanoidRootPart")
    local maxDistance = tonumber(Settings.EspMaxDistance) or 1000

    for player, billboard in pairs(healthBillboards) do
        if not player
        or not player.Parent
        or not billboard
        or not billboard.Parent then
            if billboard then
                pcall(function() billboard:Destroy() end)
            end
            healthBillboards[player] = nil
        end
    end

    for _, target in ipairs(Players:GetPlayers()) do
        if target ~= Player then
            local character = target.Character
            local humanoid = character
                and character:FindFirstChildOfClass("Humanoid")
            local root = character
                and character:FindFirstChild("HumanoidRootPart")
            local head = character
                and character:FindFirstChild("Head")

            local inRange = humanoid
                and root
                and humanoid.Health > 0

            if inRange
            and localRoot
            and maxDistance > 0 then
                inRange = (localRoot.Position - root.Position).Magnitude <= maxDistance
            end

            if inRange then
                local billboard = healthBillboards[target]

                if not billboard or billboard.Parent ~= character then
                    if billboard then
                        pcall(function() billboard:Destroy() end)
                    end

                    billboard = Instance.new("BillboardGui")
                    billboard.Name = "ToxESPHealth"
                    billboard.Adornee = head or root
                    billboard.AlwaysOnTop = true
                    billboard.Size = UDim2.fromOffset(180, 22)
                    billboard.StudsOffset = Vector3.new(0, 2.55, 0)
                    billboard.MaxDistance = maxDistance > 0 and maxDistance or 100000
                    billboard.Parent = character

                    local label = Instance.new("TextLabel")
                    label.Name = "HealthLabel"
                    label.Size = UDim2.fromScale(1, 1)
                    label.BackgroundTransparency = 1
                    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                    label.TextStrokeTransparency = 0
                    label.TextColor3 = Color3.fromRGB(255, 255, 255)
                    label.TextSize = 12
                    label.Font = Enum.Font.Gotham
                    label.TextXAlignment = Enum.TextXAlignment.Center
                    label.Parent = billboard

                    healthBillboards[target] = billboard
                end

                billboard.MaxDistance = maxDistance > 0 and maxDistance or 100000
                local label = billboard:FindFirstChild("HealthLabel")
                if label then
                    label.Text = "HP: "
                        .. tostring(math.floor(humanoid.Health + 0.5))
                        .. "/"
                        .. tostring(math.floor(humanoid.MaxHealth + 0.5))

                    if Settings.VisualRainbow and lastRainbowColor then
                        label.TextColor3 = lastRainbowColor
                    else
                        local colors = env.ColorMap
                        local color = typeof(colors) == "table"
                            and colors[Settings.EspColorName]
                            or nil
                        label.TextColor3 = typeof(color) == "Color3"
                            and color
                            or Color3.fromRGB(255, 255, 255)
                    end
                end
            else
                local billboard = healthBillboards[target]
                if billboard then
                    pcall(function() billboard:Destroy() end)
                    healthBillboards[target] = nil
                end
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

    if type(Toggle) ~= "function"
    or type(ToggleWithValue) ~= "function" then
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

    ToggleWithValue(
        "Rainbow",
        page,
        Settings.VisualRainbow,
        Settings.RainbowSpeed,
        function(value)
            Settings.VisualRainbow = value == true
            if not Settings.VisualRainbow then
                ApplyRainbow()
            end
        end,
        function(value)
            Settings.RainbowSpeed = math.clamp(tonumber(value) or 10, 0.1, 100)
        end,
        "VisualRainbow"
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

end

function BeginUniversalSection(name)
    local key = string.upper(tostring(name or "")):gsub("%s+", "")

    if key == "MISC" then
        local visualPage = env.VisualsPage or UniversalPage

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
        UpdateHealthESP()

        fakeLagClock += math.max(tonumber(delta) or 0, 0)
        if Settings.FakeLag and fakeLagClock >= 0.14 then
            fakeLagClock = 0
            local root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            local chance = math.clamp(tonumber(Settings.LagChance) or 70, 0, 100)
            local shouldSleep = math.random(1, 100) <= chance
            SetNetworkSleeping(root, shouldSleep)
        elseif not Settings.FakeLag then
            fakeLagClock = 0
            if next(fakeLagSleeping) ~= nil then
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
    if type(env.ToxUniversal2ExtraCleanup) == "function" then
        pcall(env.ToxUniversal2ExtraCleanup)
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

    Settings.XRay = false
    RestoreXRay()
    SetFakeLag(false)
    ClearHealthBillboards()

    Settings.VisualRainbow = false
    ApplyRainbow()

    Settings.Freecam = false
    StopFreecam()
    Settings.NoclipCamera = false
    RestoreCameraNoclip()
    RestoreCameraMovementFreeze(true)

    pcall(function()
        Player.CameraMaxZoomDistance = originalCameraMaxZoomDistance
    end)

    Settings.Render3DDisabled = false
    if type(env.ToxSetRender3DEnabled) == "function" then
        pcall(env.ToxSetRender3DEnabled, true)
    else
        pcall(function()
            RunService:Set3dRenderingEnabled(true)
        end)
    end

    env.ToxUniversal2OwnsAimbot = nil

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

local mergedFeaturesOk, mergedFeaturesError = pcall(function()
    local env = getgenv()
    
    if type(env.ToxUniversal2ExtraCleanup) == "function" then
        pcall(env.ToxUniversal2ExtraCleanup)
    end
    
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local Workspace = game:GetService("Workspace")
    
    local Player = Players.LocalPlayer
    local Settings = env.Settings or {}
    local RENDER_BIND = "ToxUniversal2Combat"
    local instanceToken = {}
    
    Settings.AimbotMode = string.upper(tostring(Settings.AimbotMode or "CAMERA"))
    if Settings.AimbotMode ~= "CAMERA" and Settings.AimbotMode ~= "MOUSE" then
        Settings.AimbotMode = "CAMERA"
    end
    Settings.AimbotBindEnabled = Settings.AimbotBindEnabled == true
    Settings.AimbotKey = Settings.AimbotKey or Enum.KeyCode.E
    Settings.AimbotBlatant = Settings.AimbotBlatant == true
    Settings.AimLock = Settings.AimLock == true
    Settings.LockRadius = math.clamp(tonumber(Settings.LockRadius) or 110, 1, 2000)
    Settings.AimTargets = tostring(Settings.AimTargets or "Players Only")
    Settings.IgnoreFriends = Settings.IgnoreFriends == true
    Settings.ProjectileSpeed = nil
    Settings.ProjectileDrop = nil
    Settings.RageMode = nil
    Settings.RageDistance = nil
    Settings.AntiAim = nil
    Settings.AntiAimType = nil
    Settings.NormalizeAnimations = Settings.NormalizeAnimations == true
    Settings.ForceJump = Settings.ForceJump == true
    Settings.FixUnanchoredParts = Settings.FixUnanchoredParts == true
    Settings.StartHidden = Settings.StartHidden == true
    Settings.UnlockCursor = Settings.UnlockCursor == true
    
    env.Settings = Settings
    env.ToxUniversal2ExtraToken = instanceToken
    
    local friendCache = {}
    local npcCache = {}
    local npcCacheTime = 0
    local lockedTarget = nil
    local aimbotBindHeld = false
    local animationDefaults = setmetatable({}, {__mode = "k"})
    local forceJumpDefaults = setmetatable({}, {__mode = "k"})
    local normalizeClock = 0
    local connections = {}
    local combatUIInstalled = false
    local playerUIInstalled = false
    local miscUIInstalled = false
    local configUIInstalled = false
    local cursorDefaults = nil
    local fixClock = 0
    local lastUniversalSection = nil
    
    local function AddConnection(connection)
        if connection then
            connections[#connections + 1] = connection
        end
        return connection
    end
    
    local function Save()
        if env.ToxOptionsReady == false then
            return
        end
    
        if type(env.AutoSaveConfiguration) == "function" then
            pcall(env.AutoSaveConfiguration)
        end
    end
    
    local function IsFriend(targetPlayer)
        if not Settings.IgnoreFriends
        or not targetPlayer
        or targetPlayer == Player then
            return false
        end
    
        local userId = tonumber(targetPlayer.UserId) or 0
    
        if friendCache[userId] ~= nil then
            return friendCache[userId] == true
        end
    
        local result = false
        pcall(function()
            result = Player:IsFriendsWith(userId) == true
        end)
    
        friendCache[userId] = result
        return result
    end
    
    local function GetModelAimPart(model)
        if not model then
            return nil
        end
    
        local wanted = tostring(Settings.AimPart or "Head")
        local part = model:FindFirstChild(wanted)
    
        if part and part:IsA("BasePart") then
            return part
        end
    
        part = model:FindFirstChild("Head")
            or model:FindFirstChild("HumanoidRootPart")
            or model:FindFirstChild("UpperTorso")
            or model:FindFirstChild("Torso")
    
        if part and part:IsA("BasePart") then
            return part
        end
    
        return nil
    end
    
    local function RefreshNPCCache()
        local now = tick()
    
        if now - npcCacheTime < 1 then
            return
        end
    
        npcCacheTime = now
        npcCache = {}
    
        local count = 0
    
        for _, object in ipairs(Workspace:GetDescendants()) do
            if object:IsA("Humanoid")
            and object.Health > 0 then
                local model = object.Parent
    
                if model
                and model:IsA("Model")
                and not Players:GetPlayerFromCharacter(model) then
                    local part = GetModelAimPart(model)
    
                    if part then
                        npcCache[#npcCache + 1] = model
                        count += 1
    
                        if count >= 200 then
                            break
                        end
                    end
                end
            end
        end
    end
    
    local function IsVisible(target)
        if Settings.AimbotBlatant then
            return true
        end

        if not Settings.AimWallCheck then
            return true
        end
    
        local camera = Workspace.CurrentCamera
        local part = target and target.Part
        local model = target and target.Model
    
        if not camera or not part then
            return false
        end
    
        local origin = camera.CFrame.Position
        local direction = part.Position - origin
    
        if direction.Magnitude <= 0.05 then
            return true
        end
    
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.IgnoreWater = true
        params.FilterDescendantsInstances = Player.Character and {Player.Character} or {}
    
        local result = Workspace:Raycast(origin, direction, params)
    
        if not result then
            return true
        end
    
        return model ~= nil and result.Instance:IsDescendantOf(model)
    end
    
    local function TargetValid(target)
        if typeof(target) ~= "table"
        or not target.Part
        or not target.Part.Parent
        or not target.Humanoid
        or target.Humanoid.Health <= 0 then
            return false
        end
    
        if target.Player then
            if target.Player == Player
            or target.Player.Parent ~= Players
            or IsFriend(target.Player) then
                return false
            end
        end
    
        return IsVisible(target)
    end
    
    local function GetCandidates()
        local mode = tostring(Settings.AimTargets or "Players Only")
        local candidates = {}
    
        if mode ~= "NPCs Only" then
            for _, targetPlayer in ipairs(Players:GetPlayers()) do
                if targetPlayer ~= Player
                and targetPlayer.Character
                and not IsFriend(targetPlayer) then
                    local humanoid = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
                    local part = GetModelAimPart(targetPlayer.Character)
    
                    if humanoid
                    and humanoid.Health > 0
                    and part then
                        candidates[#candidates + 1] = {
                            Part = part,
                            Humanoid = humanoid,
                            Player = targetPlayer,
                            Model = targetPlayer.Character
                        }
                    end
                end
            end
        end
    
        if mode == "NPCs Only"
        or mode == "Players + NPCs" then
            RefreshNPCCache()
    
            for _, model in ipairs(npcCache) do
                local humanoid = model and model:FindFirstChildOfClass("Humanoid")
                local part = GetModelAimPart(model)
    
                if humanoid
                and humanoid.Health > 0
                and part then
                    candidates[#candidates + 1] = {
                        Part = part,
                        Humanoid = humanoid,
                        Player = nil,
                        Model = model
                    }
                end
            end
        end
    
        return candidates
    end
    
    local function GetMouseTarget()
        local camera = Workspace.CurrentCamera
    
        if not camera then
            return nil
        end
    
        local mousePosition = UserInputService:GetMouseLocation()
        local radius = Settings.AimbotBlatant
            and math.huge
            or math.max(1, tonumber(Settings.LockRadius) or 110)
        local best = nil
        local bestDistance = radius
    
        for _, target in ipairs(GetCandidates()) do
            if TargetValid(target) then
                local screen, onScreen = camera:WorldToViewportPoint(target.Part.Position)
    
                if onScreen and screen.Z > 0 then
                    local distance = (
                        Vector2.new(screen.X, screen.Y)
                        - mousePosition
                    ).Magnitude
    
                    if distance < bestDistance then
                        bestDistance = distance
                        best = target
                    end
                end
            end
        end
    
        return best
    end
    
    local function RestoreAnimations()
        for track, speed in pairs(animationDefaults) do
            pcall(function()
                if track and track.IsPlaying then
                    track:AdjustSpeed(speed)
                end
            end)
        end
    
        animationDefaults = setmetatable({}, {__mode = "k"})
    end
    
    local function NormalizeAnimations()
        local character = Player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
    
        if not animator then
            return
        end
    
        for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
            if animationDefaults[track] == nil then
                animationDefaults[track] = tonumber(track.Speed) or 1
            end
    
            pcall(function()
                track:AdjustSpeed(1)
            end)
        end
    end
    
    local function CaptureForceJump(humanoid)
        if not humanoid
        or forceJumpDefaults[humanoid] then
            return
        end
    
        local jumpStateEnabled = true
    
        pcall(function()
            jumpStateEnabled = humanoid:GetStateEnabled(
                Enum.HumanoidStateType.Jumping
            )
        end)
    
        forceJumpDefaults[humanoid] = {
            UseJumpPower = humanoid.UseJumpPower,
            JumpPower = humanoid.JumpPower,
            JumpHeight = humanoid.JumpHeight,
            JumpStateEnabled = jumpStateEnabled
        }
    end
    
    local function ApplyForceJump(humanoid)
        if not humanoid
        or humanoid.Health <= 0 then
            return
        end
    
        CaptureForceJump(humanoid)
    
        pcall(function()
            humanoid:SetStateEnabled(
                Enum.HumanoidStateType.Jumping,
                true
            )
        end)
    
        if humanoid.UseJumpPower then
            humanoid.JumpPower = math.max(tonumber(humanoid.JumpPower) or 0, 50)
        else
            humanoid.JumpHeight = math.max(tonumber(humanoid.JumpHeight) or 0, 7.2)
        end
    end
    
    local function RestoreForceJump()
        for humanoid, defaults in pairs(forceJumpDefaults) do
            if humanoid and humanoid.Parent then
                pcall(function()
                    humanoid.UseJumpPower = defaults.UseJumpPower
                    humanoid.JumpPower = defaults.JumpPower
                    humanoid.JumpHeight = defaults.JumpHeight
                    humanoid:SetStateEnabled(
                        Enum.HumanoidStateType.Jumping,
                        defaults.JumpStateEnabled
                    )
                end)
            end
        end
    
        forceJumpDefaults = setmetatable({}, {__mode = "k"})
    end
    
    local function IsCharacterPart(part)
        local model = part and part:FindFirstAncestorOfClass("Model")
        return model ~= nil and model:FindFirstChildOfClass("Humanoid") ~= nil
    end
    
    local function SetUnlockCursor(enabled)
        Settings.UnlockCursor = enabled == true
    
        if Settings.UnlockCursor then
            if not cursorDefaults then
                cursorDefaults = {
                    MouseBehavior = UserInputService.MouseBehavior,
                    MouseIconEnabled = UserInputService.MouseIconEnabled
                }
            end
    
            pcall(function()
                UserInputService.MouseBehavior = Enum.MouseBehavior.Default
                UserInputService.MouseIconEnabled = true
            end)
        elseif cursorDefaults then
            pcall(function()
                UserInputService.MouseBehavior = cursorDefaults.MouseBehavior
                UserInputService.MouseIconEnabled = cursorDefaults.MouseIconEnabled
            end)
            cursorDefaults = nil
        end
    end
    
    local function FixDangerousUnanchoredParts()
        local character = Player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
    
        if not root then
            return
        end
    
        local params = OverlapParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {character}
    
        local ok, parts = pcall(function()
            return Workspace:GetPartBoundsInRadius(root.Position, 45, params)
        end)
    
        if not ok or typeof(parts) ~= "table" then
            return
        end
    
        for _, part in ipairs(parts) do
            if part:IsA("BasePart")
            and not part.Anchored
            and not IsCharacterPart(part) then
                local linear = part.AssemblyLinearVelocity.Magnitude
                local angular = part.AssemblyAngularVelocity.Magnitude
    
                if linear > 120 or angular > 70 then
                    pcall(function()
                        part.AssemblyLinearVelocity = Vector3.zero
                        part.AssemblyAngularVelocity = Vector3.zero
                    end)
                end
            end
        end
    end
    
    local function PanicDisable()
        for key, value in pairs(Settings) do
            if typeof(value) == "boolean"
            and key ~= "StartHidden" then
                Settings[key] = false
                if type(env.SyncToggleVisuals) == "function" then
                    pcall(env.SyncToggleVisuals, key, false)
                end
            end
        end
    
        Settings.Render3D = true
        SetUnlockCursor(false)
    
        if type(env.ToxSetXRay) == "function" then
            pcall(env.ToxSetXRay, false)
        end
    
        if type(env.ToxSetFakeLag) == "function" then
            pcall(env.ToxSetFakeLag, false)
        end
    
        if type(env.ToxResetPart2Visuals) == "function" then
            pcall(env.ToxResetPart2Visuals)
        end
    
        if type(env.ToxSetFreecam) == "function" then
            pcall(env.ToxSetFreecam, false)
        end
    
        if type(env.ToxSetNoclipCamera) == "function" then
            pcall(env.ToxSetNoclipCamera, false)
        end
    
        local main = env.Main
        if main then
            main.Visible = false
        end
    
        if type(env.CustomNotify) == "function" then
            env.CustomNotify(
                "PANIC • all toggles disabled",
                Color3.fromRGB(255, 120, 120),
                4
            )
        end
    end
    
    local function CreateNumberOption(name, page, defaultValue, minValue, maxValue, callback)
        if not page then
            return nil
        end
    
        local container = Instance.new("Frame")
        container.Size = UDim2.new(1, -5, 0, 39)
        container.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
        container.BorderSizePixel = 0
        container.Parent = page
    
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -90, 1, 0)
        label.Position = UDim2.new(0, 12, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = name
        label.TextColor3 = Color3.fromRGB(240, 240, 240)
        label.TextSize = 13
        label.Font = Enum.Font.GothamMedium
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = container
    
        local input = Instance.new("TextBox")
        input.Size = UDim2.new(0, 72, 0, 25)
        input.Position = UDim2.new(1, -82, 0.5, -12)
        input.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
        input.BorderSizePixel = 0
        input.Text = tostring(defaultValue)
        input.TextColor3 = Color3.fromRGB(255, 255, 255)
        input.TextSize = 12
        input.Font = Enum.Font.Gotham
        input.ClearTextOnFocus = false
        input.Parent = container
    
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 4)
        corner.Parent = input
    
        input.FocusLost:Connect(function()
            local value = tonumber(input.Text)
    
            if value == nil then
                input.Text = tostring(defaultValue)
                return
            end
    
            value = math.clamp(value, minValue, maxValue)
            input.Text = tostring(value)
            callback(value)
            Save()
        end)
    
        if type(env.TrackUniversalControl) == "function" then
            env.TrackUniversalControl(container, page)
        end
    
        if type(env.RegisterToxSearchControl) == "function" then
            env.RegisterToxSearchControl(name, page, container)
        end
    
        return container
    end
    
    local function InstallCombatUI()
        if combatUIInstalled then
            return
        end
    
        local page = env.CombatPage or env.UniversalPage
        local CreateToggle = env.CreateToggle
        local CreateToggleWithValue = env.CreateToggleWithValue
        local CreateDropdown = env.CreateDropdown
        local CreateKeybindToggle = env.CreateKeybindToggle
    
        if not page
        or type(CreateToggle) ~= "function"
        or type(CreateToggleWithValue) ~= "function"
        or type(CreateDropdown) ~= "function"
        or type(CreateKeybindToggle) ~= "function" then
            return
        end
    
        combatUIInstalled = true

        local bindControl = CreateKeybindToggle(
            "Aimbot Bind",
            page,
            Settings.AimbotKey,
            Settings.AimbotBindEnabled,
            function(key)
                Settings.AimbotKey = key
                aimbotBindHeld = false
            end,
            function(value)
                Settings.AimbotBindEnabled = value == true
                if not Settings.AimbotBindEnabled then
                    aimbotBindHeld = false
                end
            end,
            "AimbotBindEnabled"
        )

        if bindControl then
            for _, object in ipairs(bindControl:GetDescendants()) do
                if object:IsA("TextLabel") and object.Text == "AUTO" then
                    object.Text = ""
                    object.Visible = false
                elseif object:IsA("TextButton")
                and object.Size.X.Offset == 62
                and object.Size.Y.Offset == 27 then
                    object.Position = UDim2.new(1, -108, 0.5, -13)
                end
            end
        end
    
        CreateToggleWithValue(
            "Aim Lock",
            page,
            Settings.AimLock,
            Settings.LockRadius,
            function(value)
                Settings.AimLock = value == true
                if not Settings.AimLock then
                    lockedTarget = nil
                end
            end,
            function(value)
                Settings.LockRadius = math.clamp(tonumber(value) or 110, 1, 2000)
                lockedTarget = nil
            end,
            "AimLock"
        )

        CreateToggle(
            "Blatant",
            page,
            Settings.AimbotBlatant,
            function(value)
                Settings.AimbotBlatant = value == true
                lockedTarget = nil
            end,
            "AimbotBlatant"
        )
    
        CreateDropdown(
            "Aim Targets",
            {"Players Only", "NPCs Only", "Players + NPCs"},
            page,
            Settings.AimTargets,
            function(value)
                Settings.AimTargets = tostring(value)
                lockedTarget = nil
            end
        )
    
        CreateToggle(
            "Ignore Friends",
            page,
            Settings.IgnoreFriends,
            function(value)
                Settings.IgnoreFriends = value == true
                friendCache = {}
                lockedTarget = nil
            end,
            "IgnoreFriends"
        )
    
    end
    
    local function InstallPlayerUI()
        if playerUIInstalled then
            return
        end

        local page = env.PlayerPage or env.UniversalPage
        local CreateToggleWithValue = env.CreateToggleWithValue

        if not page
        or type(CreateToggleWithValue) ~= "function" then
            return
        end

        playerUIInstalled = true

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

        CreateVisualNumberOption(
            "Max Zoom",
            page,
            Settings.MaxZoomDistance,
            0.5,
            10000,
            function(value)
                SetMaxZoomDistance(value)
            end
        )
    end
    
    local function InstallMiscUI()
        if miscUIInstalled then
            return
        end

        local page = env.FlingPage or env.UniversalPage
        local CreateToggle = env.CreateToggle
        local CreateToggleWithValue = env.CreateToggleWithValue

        if not page
        or type(CreateToggle) ~= "function"
        or type(CreateToggleWithValue) ~= "function" then
            return
        end

        miscUIInstalled = true

        CreateToggle(
            "Noclip Camera",
            page,
            Settings.NoclipCamera,
            SetNoclipCamera,
            "NoclipCamera"
        )

        CreateToggle(
            "Normalize Animations",
            page,
            Settings.NormalizeAnimations,
            function(value)
                Settings.NormalizeAnimations = value == true
                if not Settings.NormalizeAnimations then
                    RestoreAnimations()
                end
            end,
            "NormalizeAnimations"
        )

        CreateToggle(
            "Fix Unanchored Parts",
            page,
            Settings.FixUnanchoredParts,
            function(value)
                Settings.FixUnanchoredParts = value == true
            end,
            "FixUnanchoredParts"
        )

        CreateToggle(
            "Force Jump",
            page,
            Settings.ForceJump,
            function(value)
                Settings.ForceJump = value == true
                if not Settings.ForceJump then
                    RestoreForceJump()
                end
            end,
            "ForceJump"
        )

        CreateToggleWithValue(
            "Fake Lag (%)",
            page,
            Settings.FakeLag,
            Settings.LagChance,
            function(value)
                if value and type(sethiddenproperty) ~= "function" then
                    Settings.FakeLag = false
                    if type(env.SyncToggleVisuals) == "function" then
                        task.defer(function()
                            env.SyncToggleVisuals("FakeLag", false)
                        end)
                    end
                    VisualNotify(
                        "Fake Lag unsupported by this executor",
                        Color3.fromRGB(255, 180, 70)
                    )
                    return
                end
                SetFakeLag(value)
            end,
            function(value)
                local clamped = math.clamp(
                    tonumber(value) or 70,
                    0,
                    100
                )
                Settings.LagChance = clamped

                if type(env.SyncValueVisuals) == "function" then
                    task.defer(function()
                        env.SyncValueVisuals("FakeLag", clamped)
                    end)
                end
            end,
            "FakeLag"
        )
    end
    
    local function ControlHasName(control, name)
        if not control or not control.Parent then
            return false
        end

        if (control:IsA("TextLabel") or control:IsA("TextButton"))
        and control.Text == name then
            return true
        end

        for _, object in ipairs(control:GetDescendants()) do
            if (object:IsA("TextLabel") or object:IsA("TextButton"))
            and object.Text == name then
                return true
            end
        end

        return false
    end

    local function FindSection(key)
        key = string.upper(tostring(key or "")):gsub("%s+", "")

        for _, section in ipairs(env.ToxUniversalSections or {}) do
            if section.Key == key then
                return section
            end
        end

        return nil
    end

    local function FindControl(name)
        for _, section in ipairs(env.ToxUniversalSections or {}) do
            for index, control in ipairs(section.Controls or {}) do
                if ControlHasName(control, name) then
                    return control, section, index
                end
            end
        end

        return nil, nil, nil
    end

    local function RemoveControlReference(section, control)
        if not section or not control then
            return
        end

        for index = #(section.Controls or {}), 1, -1 do
            if section.Controls[index] == control then
                table.remove(section.Controls, index)
            end
        end
    end

    local function DestroyControl(name)
        local control, section = FindControl(name)

        if not control then
            return false
        end

        RemoveControlReference(section, control)
        pcall(function()
            control:Destroy()
        end)
        return true
    end

    local function MoveControlToSection(name, targetKey)
        local control, oldSection = FindControl(name)
        local targetSection = FindSection(targetKey)

        if not control or not targetSection then
            return false
        end

        if oldSection ~= targetSection then
            RemoveControlReference(oldSection, control)
            table.insert(targetSection.Controls, control)
        end

        return true
    end

    local function MoveBefore(section, name, anchorName)
        if not section then
            return false
        end

        local controlIndex = nil
        local anchorIndex = nil

        for index, control in ipairs(section.Controls or {}) do
            if ControlHasName(control, name) then
                controlIndex = index
            end
            if ControlHasName(control, anchorName) then
                anchorIndex = index
            end
        end

        if not controlIndex or not anchorIndex or controlIndex == anchorIndex then
            return false
        end

        local control = table.remove(section.Controls, controlIndex)

        if controlIndex < anchorIndex then
            anchorIndex -= 1
        end

        table.insert(section.Controls, math.max(1, anchorIndex), control)
        return true
    end

    local function MoveAfter(section, name, anchorName)
        if not section then
            return false
        end

        local controlIndex = nil
        local anchorIndex = nil

        for index, control in ipairs(section.Controls or {}) do
            if ControlHasName(control, name) then
                controlIndex = index
            end
            if ControlHasName(control, anchorName) then
                anchorIndex = index
            end
        end

        if not controlIndex or not anchorIndex or controlIndex == anchorIndex then
            return false
        end

        local control = table.remove(section.Controls, controlIndex)

        if controlIndex < anchorIndex then
            anchorIndex -= 1
        end

        table.insert(section.Controls, anchorIndex + 1, control)
        return true
    end

    local function RebuildUniversalLayout()
        Settings.ShiftLockKey = Settings.ShiftLockKey == "Ctrl" and "Ctrl" or "Shift"

        MoveControlToSection("Fullbright", "PLAYER")
        MoveControlToSection("XRay", "PLAYER")

        local combatSection = FindSection("COMBAT")
        local playerSection = FindSection("PLAYER")
        local visualSection = FindSection("VISUALS") or FindSection("VISUAL")
        local miscSection = FindSection("MISC")

        MoveAfter(combatSection, "Aimbot Bind", "Aimbot")
        MoveAfter(combatSection, "Aim Smoothness", "Aimbot Bind")
        MoveAfter(combatSection, "Aim Lock", "Aim Smoothness")
        MoveAfter(combatSection, "Blatant", "Aim Lock")
        MoveAfter(combatSection, "Aim Targets", "Blatant")
        MoveAfter(combatSection, "Ignore Friends", "Aim Targets")

        MoveAfter(playerSection, "Freecam", "Jump")
        MoveAfter(playerSection, "XRay", "Freecam")
        MoveAfter(playerSection, "Max Zoom", "XRay")
        MoveAfter(playerSection, "Fullbright", "Air Walk (E Up / Q Down)")

        MoveAfter(visualSection, "Show Health", "Names")
        MoveBefore(visualSection, "Rainbow", "ESP Color")

        MoveBefore(miscSection, "Walk Fling", "Ctrl Click TP")
        MoveAfter(miscSection, "Noclip Camera", "Ctrl Click TP")
        MoveAfter(miscSection, "Normalize Animations", "No Fall Damage")
        MoveAfter(miscSection, "Fix Unanchored Parts", "Normalize Animations")
        MoveAfter(miscSection, "Force Jump", "Fix Unanchored Parts")
        MoveAfter(miscSection, "Fake Lag (%)", "Force Shift Lock")

        local layoutOrder = 1

        for _, section in ipairs(env.ToxUniversalSections or {}) do
            if section.Header and section.Header.Parent then
                section.Header.LayoutOrder = layoutOrder
                layoutOrder += 1
            end

            local validControls = {}

            for _, control in ipairs(section.Controls or {}) do
                if control and control.Parent and control:IsA("GuiObject") then
                    validControls[#validControls + 1] = control
                    control.LayoutOrder = layoutOrder
                    layoutOrder += 1
                end
            end

            section.Controls = validControls

            if type(env.ApplyUniversalSectionState) == "function" then
                env.ApplyUniversalSectionState(section)
            end
        end
    end

    local function RenameGuiToggleLabel()
        local page = env.ConfigPage
        if not page then
            return
        end
    
        for _, object in ipairs(page:GetDescendants()) do
            if (object:IsA("TextLabel") or object:IsA("TextButton"))
            and object.Text == "GUI Keybind" then
                object.Text = "GUI Toggle"
            end
        end
    end
    
    local function RebuildConfigLayout()
        local page = env.ConfigPage
        if not page then
            return false
        end

        local controls = {}
        local panic = nil
        local guiToggle = nil

        for _, child in ipairs(page:GetChildren()) do
            if child:IsA("GuiObject") then
                if ControlHasName(child, "Panic Key") then
                    panic = child
                elseif ControlHasName(child, "GUI Toggle")
                or ControlHasName(child, "GUI Keybind") then
                    guiToggle = child
                end
                controls[#controls + 1] = child
            end
        end

        if not panic or not guiToggle then
            return false
        end

        local reordered = {}
        for _, control in ipairs(controls) do
            if control ~= panic then
                reordered[#reordered + 1] = control
                if control == guiToggle then
                    reordered[#reordered + 1] = panic
                end
            end
        end

        for index, control in ipairs(reordered) do
            control.LayoutOrder = index
        end

        return true
    end

    local function InstallConfigUI()
        if configUIInstalled then
            return
        end
    
        local page = env.ConfigPage
        local CreateToggle = env.CreateToggle
        local CreateKeybindButton = env.CreateKeybindButton
    
        if not page
        or type(CreateToggle) ~= "function"
        or type(CreateKeybindButton) ~= "function" then
            return
        end
    
        configUIInstalled = true
        RenameGuiToggleLabel()
    
        CreateKeybindButton(
            "Panic Key",
            page,
            Settings.PanicKey,
            function(key)
                Settings.PanicKey = key
                Save()
            end
        )
    
        CreateToggle(
            "Start Hidden",
            page,
            Settings.StartHidden,
            function(value)
                Settings.StartHidden = value == true
            end,
            "StartHidden"
        )
    
        CreateToggle(
            "Unlock Cursor",
            page,
            Settings.UnlockCursor,
            SetUnlockCursor,
            "UnlockCursor"
        )
    end
    
    local previousBeginUniversalSection = env.BeginUniversalSection or BeginUniversalSection
    
    function BeginUniversalSection(name)
        local nextKey = string.upper(tostring(name or "")):gsub("%s+", "")
    
        if lastUniversalSection == "COMBAT" then
            InstallCombatUI()
        elseif lastUniversalSection == "PLAYER" then
            InstallPlayerUI()
        end
    
        local result = nil
    
        if type(previousBeginUniversalSection) == "function" then
            result = previousBeginUniversalSection(name)
        end
    
        if nextKey == "MISC" then
            InstallMiscUI()
        end
    
        lastUniversalSection = nextKey
        return result
    end
    
    env.BeginUniversalSection = BeginUniversalSection
    env.ToxSetUnlockCursor = SetUnlockCursor
    
    InstallConfigUI()

    task.spawn(function()
        for _ = 1, 180 do
            if env.ToxUniversal2ExtraToken ~= instanceToken
            or env.Destroyed then
                return
            end

            RenameGuiToggleLabel()
            if RebuildConfigLayout() then
                break
            end

            task.wait(0.05)
        end
    end)

    task.spawn(function()
        for _ = 1, 160 do
            if env.ToxUniversal2ExtraToken ~= instanceToken
            or env.Destroyed then
                return
            end

            local hasShiftLock = FindControl("Force Shift Lock") ~= nil
            local hasFullbright = FindControl("Fullbright") ~= nil
            local hasJump = FindControl("Jump") ~= nil
            local hasAirWalk = FindControl("Air Walk (E Up / Q Down)") ~= nil
            local hasCtrlClick = FindControl("Ctrl Click TP") ~= nil
            local hasMaxZoom = FindControl("Max Zoom") ~= nil

            if hasShiftLock
            and hasFullbright
            and hasJump
            and hasAirWalk
            and hasCtrlClick
            and hasMaxZoom then
                RebuildUniversalLayout()
                break
            end

            task.wait(0.05)
        end
    end)
    
    task.spawn(function()
        while env.ToxUniversal2ExtraToken == instanceToken
        and not env.Destroyed
        and not env.ScriptLoaded do
            task.wait(0.05)
        end
    
        if env.ToxUniversal2ExtraToken == instanceToken
        and not env.Destroyed then
            RenameGuiToggleLabel()
    
            if Settings.StartHidden and env.Main then
                task.wait()
                if env.Main then
                    env.Main.Visible = false
                end
            end
        end
    end)
    
    AddConnection(UserInputService.InputBegan:Connect(function(input, processed)
        if env.Destroyed
        or not env.ScriptLoaded
        or input.UserInputType ~= Enum.UserInputType.Keyboard
        or UserInputService:GetFocusedTextBox() then
            return
        end

        if not processed
        and Settings.AimbotBindEnabled
        and Settings.AimbotKey
        and input.KeyCode == Settings.AimbotKey then
            aimbotBindHeld = true
        end

        if not processed
        and Settings.PanicKey
        and input.KeyCode == Settings.PanicKey then
            PanicDisable()
        end
    end))

    AddConnection(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard
        and Settings.AimbotKey
        and input.KeyCode == Settings.AimbotKey then
            aimbotBindHeld = false
        end
    end))
    
    AddConnection(UserInputService.JumpRequest:Connect(function()
        if not env.ScriptLoaded
        or env.Destroyed
        or not Settings.ForceJump then
            return
        end
    
        local character = Player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    
        if humanoid and humanoid.Health > 0 then
            ApplyForceJump(humanoid)
            humanoid.Jump = true
            pcall(function()
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end)
        end
    end))
    
    pcall(function()
        RunService:UnbindFromRenderStep(RENDER_BIND)
    end)
    
    RunService:BindToRenderStep(
        RENDER_BIND,
        Enum.RenderPriority.Last.Value,
        function(delta)
            if env.ToxUniversal2ExtraToken ~= instanceToken
            or env.Destroyed then
                return
            end
    
            if not env.ScriptLoaded then
                return
            end
    
            local character = Player.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            local root = character and character:FindFirstChild("HumanoidRootPart")

            if ShouldFreezeCameraMovement() then
                ApplyCameraMovementFreeze()
            else
                RestoreCameraMovementFreeze()
            end
    
            if Settings.UnlockCursor then
                pcall(function()
                    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
                    UserInputService.MouseIconEnabled = true
                end)
            end
    
            fixClock += math.max(tonumber(delta) or 0, 0)
            if Settings.FixUnanchoredParts and fixClock >= 0.18 then
                fixClock = 0
                FixDangerousUnanchoredParts()
            elseif not Settings.FixUnanchoredParts then
                fixClock = 0
            end
    
            if Settings.ForceJump and humanoid then
                ApplyForceJump(humanoid)
            elseif next(forceJumpDefaults) ~= nil then
                RestoreForceJump()
            end
    
            if Settings.NormalizeAnimations then
                normalizeClock += math.max(tonumber(delta) or 0, 0)
    
                if normalizeClock >= 0.25 then
                    normalizeClock = 0
                    NormalizeAnimations()
                end
            else
                normalizeClock = 0
    
                if next(animationDefaults) ~= nil then
                    RestoreAnimations()
                end
            end
    
            local blatant = Settings.AimbotBlatant == true
            local bindActive = Settings.AimbotBindEnabled == true
                and aimbotBindHeld
            local mainActive = Settings.Aimbot == true
            local rightClickActive = mainActive
                and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
            local blatantActive = blatant and (mainActive or bindActive)
            local triggerActive = bindActive or rightClickActive or blatantActive

            if not triggerActive then
                lockedTarget = nil
                return
            end

            local camera = Workspace.CurrentCamera

            if not camera then
                lockedTarget = nil
                return
            end

            local target = nil

            if Settings.AimLock then
                target = lockedTarget

                if target and not TargetValid(target) then
                    target = nil
                end
            end

            if not target then
                target = GetMouseTarget()
            end

            lockedTarget = Settings.AimLock and target or nil

            if not target or not target.Part then
                return
            end

            local smooth = blatant and 1 or math.max(
                1,
                tonumber(Settings.AimbotSmoothness) or 2
            )

            if Settings.AimbotMode == "MOUSE" then
                local screen, onScreen = camera:WorldToViewportPoint(target.Part.Position)

                if not onScreen or screen.Z <= 0 then
                    return
                end

                local mousePosition = UserInputService:GetMouseLocation()
                local dx = (screen.X - mousePosition.X) / smooth
                local dy = (screen.Y - mousePosition.Y) / smooth

                if type(mousemoverel) == "function" then
                    pcall(mousemoverel, dx, dy)
                elseif type(mouse_move_relative) == "function" then
                    pcall(mouse_move_relative, dx, dy)
                else
                    camera.CFrame = camera.CFrame:Lerp(
                        CFrame.new(camera.CFrame.Position, target.Part.Position),
                        1 / smooth
                    )
                end

                return
            end

            camera.CFrame = camera.CFrame:Lerp(
                CFrame.new(camera.CFrame.Position, target.Part.Position),
                1 / smooth
            )
        end
    )
    
    env.ToxUniversal2ExtraCleanup = function()
        pcall(function()
            RunService:UnbindFromRenderStep(RENDER_BIND)
        end)
    
        for _, connection in ipairs(connections) do
            pcall(function()
                connection:Disconnect()
            end)
        end
    
        connections = {}
        lockedTarget = nil
        aimbotBindHeld = false
        Settings.Aimbot = false
        Settings.AimbotBindEnabled = false
        Settings.AimbotBlatant = false
        Settings.AimLock = false
        RestoreAnimations()
        RestoreForceJump()
        SetUnlockCursor(false)
    
        if env.ToxUniversal2ExtraToken == instanceToken then
            env.ToxUniversal2ExtraToken = nil
        end
    end
    
    task.spawn(function()
        while env.ToxUniversal2ExtraToken == instanceToken
        and not env.Destroyed do
            task.wait(0.15)
        end
    
        if env.ToxUniversal2ExtraToken == instanceToken
        and env.Destroyed then
            env.ToxUniversal2ExtraCleanup()
        end
    end)
    
    env.ToxUniversal2ExtraLoaded = true
    env.ToxUniversal2ExtraVersion = "2026-09-15-reorganized-two-module"
end)

if not mergedFeaturesOk then
    if type(env.CustomNotify) == "function" then
        env.CustomNotify(
            "Universal2 extra features failed: " .. string.sub(tostring(mergedFeaturesError), 1, 90),
            Color3.fromRGB(255, 100, 100),
            6
        )
    end

    warn("[ToxHub Universal2 Extra Error]: " .. tostring(mergedFeaturesError))
end

env.ToxUniversal2Loaded = true
env.ToxUniversal2Version = "2026-09-16-camera-aim-shift-zoom-1"
