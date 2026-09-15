local env = getgenv()
local Settings = env.Settings or {}
local UniversalPage = env.UniversalPage

Settings.UniversalCollapsedSections =
    typeof(Settings.UniversalCollapsedSections) == "table"
    and Settings.UniversalCollapsedSections
    or {}

env.Settings = Settings
env.ToxUniversalSections = {}
env.ToxUniversalCurrentSection = nil

function ApplyUniversalSectionState(section)
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

function BeginUniversalSection(name)
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

env.BeginUniversalSection = BeginUniversalSection

function TrackUniversalControl(object, page)
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

env.ToxUniversal2Loaded = true
env.ToxUniversal2Version = "2026-09-14-universal-sections"
