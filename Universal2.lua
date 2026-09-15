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

    if key == "MISC" and not cameraControlsInstalled then
        InstallCameraControls(env.VisualsPage or UniversalPage)
    end

    return BaseBeginUniversalSection(name)
end

env.BeginUniversalSection = BeginUniversalSection

env.ToxSetNoclipCamera = SetNoclipCamera
env.ToxSetFreecam = SetFreecam

env.ToxUniversal2Cleanup = function()
    if type(env.ToxUniversal3Cleanup) == "function" then
        pcall(env.ToxUniversal3Cleanup)
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
        "https://raw.githubusercontent.com/BG-0o/Scripts/refs/heads/main/Universal3.lua?toxv=2026-09-14-part1-split"
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
env.ToxUniversal2Version = "2026-09-14-camera-features-plus-universal3"
