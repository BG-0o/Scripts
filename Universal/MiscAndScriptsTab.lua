local env = getgenv()
if env.Destroyed or env.ToxUniversalLoaded then
    return
end
env.ToxUniversal = env.ToxUniversal or {}
local U = env.ToxUniversal
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Player = Players.LocalPlayer
local Settings = env.Settings or {}
local FlingPage = env.FlingPage
local ScriptsPage = env.ScriptsPage
local MusicGui = env.MusicGui
local WaypointsGui = env.WaypointsGui
local CreateToggle = env.CreateToggle
local CreateButton = env.CreateButton
local CreateInputWithTwoButtons = env.CreateInputWithTwoButtons
local CreateToggleCycleOption = U.CreateToggleCycleOption or env.CreateToggleCycleOption
local BeginUniversalSection = env.BeginUniversalSection or function() end
local function CustomNotify(...) if env.CustomNotify then return env.CustomNotify(...) end end
local function AddConnection(...) if env.AddConnection then return env.AddConnection(...) end end
local CaptureShiftLockDefaults = U.CaptureShiftLockDefaults or function() end
local RestoreShiftLockDefaults = U.RestoreShiftLockDefaults or function() end
local ExecuteFling = U.ExecuteFling or function() end
local ExecuteTeleport = U.ExecuteTeleport or function() end
BeginUniversalSection("Misc")
CreateToggle("Ctrl Click TP", FlingPage, Settings.CtrlClickTP, function(v)
    if getgenv().ToxSetSharedOption then getgenv().ToxSetSharedOption("CtrlClickTP", v) end
end, "CtrlClickTP")
local toggleWithSlider = CreateToggleWithSlider or (getgenv and getgenv().CreateToggleWithSlider)
if toggleWithSlider then
    local walkFlingControl = toggleWithSlider("Walk Fling", FlingPage, 1, 100, Settings.WalkFling, Settings.WalkFlingPower or 30, "%", function(v)
        if getgenv().ToxSetSharedOption then
            getgenv().ToxSetSharedOption("WalkFling", v)
        else
            Settings.WalkFling = v
        end
    end, function(val)
        Settings.WalkFlingPower = tonumber(val) or 30
        if getgenv().ToxOnSharedValueChanged then
            getgenv().ToxOnSharedValueChanged("WalkFling", val)
        end
    end, "WalkFling")
    if env.TrackUniversalControl then pcall(env.TrackUniversalControl, walkFlingControl, FlingPage) end
else
    CreateToggleWithValue("Walk Fling", FlingPage, Settings.WalkFling, Settings.WalkFlingPower or 30, function(v)
        if getgenv().ToxSetSharedOption then
            getgenv().ToxSetSharedOption("WalkFling", v)
        else
            Settings.WalkFling = v
        end
    end, function(val)
        Settings.WalkFlingPower = tonumber(val) or 30
        if getgenv().ToxOnSharedValueChanged then
            getgenv().ToxOnSharedValueChanged("WalkFling", val)
        end
    end, "WalkFling")
end
if toggleWithSlider then
    -- % = how fast you can fall (0% = very slow float, 100% = almost normal fall)
    local control = toggleWithSlider("No Fall Damage", FlingPage, 0, 100, Settings.NoFallDamage, Settings.NoFallSpeed or 50, "%", function(v)
        if getgenv().ToxSetSharedOption then getgenv().ToxSetSharedOption("NoFallDamage", v) end
    end, function(val)
        Settings.NoFallSpeed = math.clamp(tonumber(val) or 50, 0, 100)
        if getgenv().SyncValueVisuals then
            getgenv().SyncValueVisuals("NoFallDamage", Settings.NoFallSpeed)
        end
    end, "NoFallDamage")
    if env.TrackUniversalControl then pcall(env.TrackUniversalControl, control, FlingPage) end
else
    CreateToggle("No Fall Damage", FlingPage, Settings.NoFallDamage, function(v)
        if getgenv().ToxSetSharedOption then getgenv().ToxSetSharedOption("NoFallDamage", v) end
    end, "NoFallDamage")
end
CreateToggle("Anti Void", FlingPage, Settings.AntiVoid, function(v)
    if getgenv().ToxSetSharedOption then getgenv().ToxSetSharedOption("AntiVoid", v) end
end, "AntiVoid")
CreateToggle("Anti Fling", FlingPage, Settings.AntiFling, function(v)
    if getgenv().ToxSetSharedOption then getgenv().ToxSetSharedOption("AntiFling", v) end
end, "AntiFling")
CreateToggle("Instant Proximity Prompts", FlingPage, Settings.InstantPrompts == true, function(v)
    Settings.InstantPrompts = v
    if v then
        for _, prompt in ipairs(workspace:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") then
                prompt.HoldDuration = 0
            end
        end
    end
end, "InstantPrompts")
AddConnection(workspace.DescendantAdded:Connect(function(desc)
    if Settings.InstantPrompts and not getgenv().Destroyed and desc:IsA("ProximityPrompt") then
        desc.HoldDuration = 0
    end
end))
CreateToggle("Tool Magnet", FlingPage, Settings.ToolMagnet == true, function(v)
    Settings.ToolMagnet = v
    if v then
        task.spawn(function()
            while Settings.ToolMagnet and not getgenv().Destroyed do
                local char = Player.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    for _, item in ipairs(workspace:GetChildren()) do
                        if item:IsA("BackpackItem") or item:IsA("Tool") then
                            local handle = item:FindFirstChild("Handle")
                            if handle then
                                handle.CFrame = hrp.CFrame
                            end
                        end
                    end
                end
                task.wait(0.5)
            end
        end)
    end
end, "ToolMagnet")
CreateToggleCycleOption(
    "Force Shift Lock",
    FlingPage,
    Settings.ForceShiftLock,
    {"Shift", "Ctrl"},
    Settings.ShiftLockKey or "Shift",
    function(v)
        if v then
            CaptureShiftLockDefaults()
        end
        Settings.ForceShiftLock = v == true
        if not Settings.ForceShiftLock then
            if U.SetShiftLockActive then U.SetShiftLockActive(false) end
            RestoreShiftLockDefaults()
        end
    end,
    function(v)
        Settings.ShiftLockKey = v == "Ctrl" and "Ctrl" or "Shift"
        if U.SetShiftLockActive then U.SetShiftLockActive(false) end
        if Settings.ForceShiftLock then
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        end
    end
)
U.LoopFlingInput = nil
U.LoopFlingGeneration = 0
local function ToggleLoopFling(
    text
)
    local cleaned =
        tostring(
            text
            or ""
        ):
            match(
                "^%s*(.-)%s*$"
            )
        or ""
    if cleaned == "" then
        U.LoopFlingInput = nil
        U.LoopFlingGeneration = (U.LoopFlingGeneration or 0) + 1
        CustomNotify(
            "Loop Fling Disabled",
            Color3.fromRGB(
                255,
                120,
                120
            )
        )
        return
    end
    local normalized =
        string.lower(
            cleaned
        )
    if U.LoopFlingInput
    and string.lower(
        U.LoopFlingInput
    ) == normalized then
        U.LoopFlingInput = nil
        U.LoopFlingGeneration = (U.LoopFlingGeneration or 0) + 1
        CustomNotify(
            "Loop Fling Disabled",
            Color3.fromRGB(
                255,
                120,
                120
            )
        )
        return
    end
    U.LoopFlingInput =
        cleaned
    U.LoopFlingGeneration = (U.LoopFlingGeneration or 0) + 1
    local generation =
        U.LoopFlingGeneration
    CustomNotify(
        "Loop Fling Enabled • "
        .. cleaned,
        Color3.fromRGB(
            100,
            255,
            130
        )
    )
    task.spawn(function()
        while U.LoopFlingInput
        and generation
            == U.LoopFlingGeneration
        and not getgenv().Destroyed do
            local activeInput =
                U.LoopFlingInput
            if not activeInput then
                break
            end
            local lower =
                string.lower(
                    activeInput
                )
            if lower ~= "all"
            and lower ~= "others" then
                local found = false
                for _, target in ipairs(
                    Players:
                        GetPlayers()
                ) do
                    if target ~= Player
                    and (
                        string.find(
                            string.lower(
                                target.Name
                            ),
                            lower,
                            1,
                            true
                        )
                        or string.find(
                            string.lower(
                                target.DisplayName
                            ),
                            lower,
                            1,
                            true
                        )
                    ) then
                        found = true
                        break
                    end
                end
                if not found then
                    U.LoopFlingInput = nil
                    CustomNotify(
                        "Loop Fling stopped • player left",
                        Color3.fromRGB(
                            255,
                            180,
                            70
                        )
                    )
                    break
                end
            end
            ExecuteFling(
                activeInput
            )
            task.wait(1.25)
        end
    end)
end
CreateInputWithTwoButtons(
    "Fling",
    FlingPage,
    "",
    "Fling",
    "Loop",
    function(text, mode)
        if mode == "LOOP" then
            ToggleLoopFling(
                text
            )
        else
            ExecuteFling(
                text
            )
        end
    end
)
CreateInputWithTwoButtons("Teleport", FlingPage, "", "TP", "Loop TP", function(text, mode) ExecuteTeleport(text, mode) end)

-- ==============================================================================
-- Shared player lookup (same matching as Fling / Teleport: name or display name)
-- ==============================================================================
-- forward declared: used by Select Player, built further below
local AvatarItemsGui = nil
local AvatarItemsLoad = nil

local function FindPlayerByInput(text)
    text = string.lower(tostring(text or ""))
    if text == "" then return nil end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player and (string.find(string.lower(p.Name), text, 1, true)
        or string.find(string.lower(p.DisplayName), text, 1, true)) then
            return p
        end
    end
    return nil
end

-- ==============================================================================
-- SPECTATE: camera follows the chosen player
-- ==============================================================================
local SpectateTarget = nil
local function StopSpectate(silent)
    SpectateTarget = nil
    local camera = workspace.CurrentCamera
    local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
    if camera and hum then
        camera.CameraSubject = hum
    end
    if not silent then
        CustomNotify("Spectate stopped", Color3.fromRGB(255, 120, 120))
    end
end

CreateInputWithTwoButtons("Spectate", FlingPage, "", "View", "Stop", function(text, mode)
    if mode ~= "TP" then
        StopSpectate()
        return
    end
    local target = FindPlayerByInput(text)
    local hum = target and target.Character and target.Character:FindFirstChildOfClass("Humanoid")
    if not hum then
        return CustomNotify("Player not found!", Color3.fromRGB(255, 100, 100))
    end
    SpectateTarget = target
    workspace.CurrentCamera.CameraSubject = hum
    CustomNotify("Spectating • " .. target.DisplayName, Color3.fromRGB(100, 200, 255))
end)

AddConnection(game:GetService("RunService").Heartbeat:Connect(function()
    if not SpectateTarget or env.Destroyed then return end
    if not SpectateTarget.Parent then
        StopSpectate(true)
        return CustomNotify("Spectate stopped • player left", Color3.fromRGB(255, 180, 70))
    end
    -- keep following after they respawn
    local hum = SpectateTarget.Character and SpectateTarget.Character:FindFirstChildOfClass("Humanoid")
    local camera = workspace.CurrentCamera
    if hum and camera and camera.CameraSubject ~= hum then
        camera.CameraSubject = hum
    end
end))

-- ==============================================================================
-- UP PLAYER: goes under the player's feet and rises, lifting them with your head.
-- Speed (studs/s) and Height (studs) are sliders. Then returns you to where you were.
-- ==============================================================================
Settings.UpPlayerSpeed = tonumber(Settings.UpPlayerSpeed) or 30
Settings.UpPlayerHeight = tonumber(Settings.UpPlayerHeight) or 50
local UpPlayerGeneration = 0

local UpPlayerRunning = false
local UpPlayerMode = "up"   -- "up" = rising/holding, "down" = bringing them back down

local function StopUpPlayer()
    UpPlayerGeneration = UpPlayerGeneration + 1
end

local function RunUpPlayer(target)
    local character = Player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local tRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    if not root or not humanoid or not tRoot then
        return CustomNotify("Up Player • player not available", Color3.fromRGB(255, 100, 100))
    end

    UpPlayerGeneration = UpPlayerGeneration + 1
    local generation = UpPlayerGeneration
    UpPlayerRunning = true
    UpPlayerMode = "up"
    local startCF = root.CFrame
    local RunService = game:GetService("RunService")

    -- our root sits so the top of our head touches their feet
    local UNDER = 5.6
    local currentY = tRoot.Position.Y - UNDER
    local reachedTop = false

    CustomNotify("Up Player • " .. target.DisplayName .. " (Down to bring back)", Color3.fromRGB(100, 255, 160))

    -- make sure we can actually push them
    local hadNoclip = Settings.Noclip
    Settings.Noclip = false
    local yaw = select(2, root.CFrame:ToOrientation())
    local baseY = currentY

    -- Only goes UP (never back down), then stays in the air until you press Stop
    while generation == UpPlayerGeneration and not env.Destroyed do
        local dt = RunService.Heartbeat:Wait()
        if not root.Parent or humanoid.Health <= 0 or not target.Parent then
            break
        end
        tRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
        if not tRoot then
            break
        end
        if env.AllowToxTeleport then env.AllowToxTeleport(0.3, "Up Player") end

        -- sliders can be changed while it runs
        local speed = math.max(tonumber(Settings.UpPlayerSpeed) or 30, 1)
        local wantedTop = math.max(baseY + math.max(tonumber(Settings.UpPlayerHeight) or 50, 1), currentY)
        if reachedTop and currentY < wantedTop - 0.05 then
            reachedTop = false   -- Height slider was raised while holding: keep going up
        end
        if UpPlayerMode == "down" then
            -- bring them back down at the same speed, then finish
            currentY = math.max(currentY - speed * dt, baseY)
            root.CFrame = CFrame.new(tRoot.Position.X, currentY, tRoot.Position.Z) * CFrame.Angles(0, yaw, 0)
            root.AssemblyLinearVelocity = Vector3.new(0, -speed, 0)
            root.AssemblyAngularVelocity = Vector3.zero
            if currentY <= baseY + 0.05 then
                break
            end
            continue
        end
        if not reachedTop then
            currentY = math.min(currentY + speed * dt, wantedTop)
            if currentY >= wantedTop - 0.05 then
                reachedTop = true
                CustomNotify("Up Player • holding in the air", Color3.fromRGB(100, 200, 255))
            end
        end

        root.CFrame = CFrame.new(tRoot.Position.X, currentY, tRoot.Position.Z) * CFrame.Angles(0, yaw, 0)
        root.AssemblyLinearVelocity = reachedTop and Vector3.zero or Vector3.new(0, speed, 0)
        root.AssemblyAngularVelocity = Vector3.zero
    end

    if generation == UpPlayerGeneration then
        UpPlayerRunning = false
        UpPlayerMode = "up"
    end
    Settings.Noclip = hadNoclip
    if root.Parent then
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        if Settings.UpPlayerReturn ~= false then
            -- back to where you were when you pressed Up
            if env.AllowToxTeleport then env.AllowToxTeleport(1, "Up Player return") end
            if env.ToxSafeTeleportToCFrame then
                pcall(env.ToxSafeTeleportToCFrame, startCF, false)
            else
                root.CFrame = startCF
            end
        end
    end
end

local UpPlayerBox = CreateInputWithTwoButtons("Up Player", FlingPage, "", "Up", "Down", function(text, mode)
    if mode ~= "TP" then
        if UpPlayerRunning then
            UpPlayerMode = "down"
            CustomNotify("Up Player • bringing down", Color3.fromRGB(255, 200, 120))
        else
            CustomNotify("Up Player is not running", Color3.fromRGB(255, 180, 70))
        end
        return
    end
    local target = FindPlayerByInput(text)
    if not target then
        return CustomNotify("Player not found!", Color3.fromRGB(255, 100, 100))
    end
    task.spawn(RunUpPlayer, target)
end)

-- Speed / Height sliders live INSIDE the Up Player option (one block instead of 3 rows)
if type(env.CreateSlider) == "function" and UpPlayerBox and UpPlayerBox:IsA("GuiObject") then
    local ROW = 42
    local speedSlider = env.CreateSlider("Speed", FlingPage, 5, 200, Settings.UpPlayerSpeed, " studs/s", function(v)
        Settings.UpPlayerSpeed = tonumber(v) or 30
        if env.AutoSaveConfiguration then env.AutoSaveConfiguration() end
    end, "UpPlayerSpeed", true)
    local heightSlider = env.CreateSlider("Height", FlingPage, 5, 500, Settings.UpPlayerHeight, " studs", function(v)
        Settings.UpPlayerHeight = tonumber(v) or 50
        if env.AutoSaveConfiguration then env.AutoSaveConfiguration() end
    end, "UpPlayerHeight", true)

    -- keep the original row (name, box, buttons) pinned to the top
    for _, child in ipairs(UpPlayerBox:GetChildren()) do
        if child:IsA("GuiObject") then
            if child.Position.Y.Scale == 0.5 then
                child.Position = UDim2.new(child.Position.X.Scale, child.Position.X.Offset, 0, ROW / 2 + child.Position.Y.Offset)
            end
            if child.Size.Y.Scale == 1 then
                child.Size = UDim2.new(child.Size.X.Scale, child.Size.X.Offset, 0, ROW)
            end
        end
    end

    local y = ROW
    for _, slider in ipairs({ speedSlider, heightSlider }) do
        if slider and slider:IsA("GuiObject") then
            slider.Parent = UpPlayerBox
            slider.AnchorPoint = Vector2.new(0, 0)
            slider.Position = UDim2.new(0, 8, 0, y)
            slider.Size = UDim2.new(1, -16, 0, slider.Size.Y.Offset)
            y = y + slider.Size.Y.Offset + 6
        end
    end
    -- "Return on Stop" inside the same block
    if Settings.UpPlayerReturn == nil then Settings.UpPlayerReturn = true end
    local createToggleRaw = (env.ToxUniversalRawCreators and env.ToxUniversalRawCreators.CreateToggle) or CreateToggle
    local returnToggle = createToggleRaw("Return to my spot after Down", FlingPage, Settings.UpPlayerReturn ~= false, function(v)
        Settings.UpPlayerReturn = v == true
        if env.AutoSaveConfiguration then env.AutoSaveConfiguration() end
    end, "UpPlayerReturn")
    if returnToggle and returnToggle:IsA("GuiObject") then
        returnToggle.Parent = UpPlayerBox
        returnToggle.AnchorPoint = Vector2.new(0, 0)
        returnToggle.Position = UDim2.new(0, 8, 0, y)
        returnToggle.Size = UDim2.new(1, -16, 0, returnToggle.Size.Y.Offset)
        y = y + returnToggle.Size.Y.Offset + 6
    end
    UpPlayerBox.Size = UDim2.new(UpPlayerBox.Size.X.Scale, UpPlayerBox.Size.X.Offset, 0, y + 2)
end

-- ==============================================================================
-- SELECT PLAYER: hold the key and click someone -> their name goes into
-- Fling / Teleport / Spectate / Up Player boxes.
-- ==============================================================================
local function GetSelectKeyName()
    local key = Settings.SelectPlayerKey
    if typeof(key) == "EnumItem" then return key.Name end
    if type(key) == "string" and key ~= "" then return key end
    return "LeftAlt"
end

if type(env.CreateKeybindButton) == "function" then
    env.CreateKeybindButton("Select Player (Hold + Click)", FlingPage, GetSelectKeyName(), function(key)
        if typeof(key) == "EnumItem" then
            Settings.SelectPlayerKey = key.Name
        else
            Settings.SelectPlayerKey = nil
        end
        if env.AutoSaveConfiguration then env.AutoSaveConfiguration() end
    end)
end

local function GetPlayerUnderMouse()
    local mouse = Player:GetMouse()
    local target = mouse and mouse.Target
    while target and target ~= workspace do
        local p = Players:GetPlayerFromCharacter(target)
        if p then return p end
        target = target.Parent
    end
    -- fallback: closest character to the mouse ray
    local camera = workspace.CurrentCamera
    local loc = UserInputService:GetMouseLocation()
    local ray = camera:ViewportPointToRay(loc.X, loc.Y)
    local best, bestDist = nil, 6
    for _, p in ipairs(Players:GetPlayers()) do
        local r = p ~= Player and p.Character and p.Character:FindFirstChild("HumanoidRootPart")
        if r then
            local toPoint = r.Position - ray.Origin
            local along = toPoint:Dot(ray.Direction)
            if along > 0 then
                local dist = (toPoint - ray.Direction * along).Magnitude
                if dist < bestDist then
                    best, bestDist = p, dist
                end
            end
        end
    end
    return best
end

AddConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if env.Destroyed or input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    local keyName = GetSelectKeyName()
    local ok, keyCode = pcall(function() return Enum.KeyCode[keyName] end)
    if not ok or not keyCode or not UserInputService:IsKeyDown(keyCode) then return end
    local target = GetPlayerUnderMouse()
    if not target then
        return CustomNotify("No player under the mouse", Color3.fromRGB(255, 180, 70))
    end
    local boxes = env.ToxNamedInputs or {}
    if AvatarItemsGui and AvatarItemsGui.Visible and AvatarItemsLoad then
        task.spawn(AvatarItemsLoad, target.Name)
    end
    for _, name in ipairs({ "Fling", "Teleport", "Spectate", "Up Player", "Avatar Items" }) do
        local box = boxes[name]
        if box and box.Parent then
            box.Text = target.Name
        end
    end
    CustomNotify("Selected • " .. target.DisplayName .. " (@" .. target.Name .. ")", Color3.fromRGB(100, 200, 255))
end))

-- ==============================================================================
-- TOX AVATAR ITEMS: window with everything a player is wearing (thumbnail, name,
-- Copy ID, Copy All). Player = typed nick or picked with Select Player.
-- ==============================================================================
do
    local Theme = env.Theme or {}
    local RegisterThemedObject = env.RegisterThemedObject or function() end
    local MarketplaceService = game:GetService("MarketplaceService")
    local AssetNameCache = {}

    local function Themed(obj, prop, key, fallback)
        obj[prop] = Theme[key] or fallback
        RegisterThemedObject(obj, prop, key)
    end
    local function Corner(obj, r)
        local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, r or 6) c.Parent = obj
    end
    local function Stroke(obj, key)
        local st = Instance.new("UIStroke") st.Thickness = 1 st.Transparency = 0.35
        st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        Themed(st, "Color", key or "Outline", Color3.fromRGB(60, 60, 80))
        st.Parent = obj
        return st
    end
    local function Button(text, size, pos, parent)
        local b = Instance.new("TextButton")
        b.Size = size b.Position = pos b.BorderSizePixel = 0 b.AutoButtonColor = true
        b.Text = text b.Font = Enum.Font.GothamBold b.TextSize = 10
        Themed(b, "BackgroundColor3", "Element", Color3.fromRGB(25, 30, 40))
        Themed(b, "TextColor3", "Text", Color3.new(1, 1, 1))
        Corner(b, 4) Stroke(b) b.Parent = parent
        return b
    end
    local function CopyText(text)
        local fn = setclipboard or toclipboard or (Clipboard and Clipboard.set)
        if fn then
            pcall(fn, text)
            return true
        end
        return false
    end

    local gui = Instance.new("Frame")
    gui.Name = "ToxAvatarItemsFrame"
    gui.Size = UDim2.new(0, 380, 0, 380)
    gui.Position = UDim2.new(0.5, -190, 0.5, -190)
    gui.BorderSizePixel = 0
    gui.ClipsDescendants = true
    gui.Visible = false
    Themed(gui, "BackgroundColor3", "Panel", Color3.fromRGB(15, 18, 26))
    gui.Parent = env.Gui
    Corner(gui, 8)
    local gStroke = Stroke(gui, "Accent") gStroke.Transparency = 0.25
    if env.ApplySavedGuiPosition then pcall(env.ApplySavedGuiPosition, "AvatarItems", gui) end
    if env.TrackGuiPosition then pcall(env.TrackGuiPosition, "AvatarItems", gui) end

    local top = Instance.new("Frame")
    top.Size = UDim2.new(1, 0, 0, 32) top.BorderSizePixel = 0
    Themed(top, "BackgroundColor3", "Element", Color3.fromRGB(25, 30, 40))
    top.Parent = gui
    if env.ToxRoundTopBar then env.ToxRoundTopBar(top) end
    if env.MakeDraggable then pcall(env.MakeDraggable, gui, top) end
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -40, 1, 0) title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1 title.Text = "Tox Avatar Items"
    title.Font = Enum.Font.GothamBold title.TextSize = 13 title.TextXAlignment = Enum.TextXAlignment.Left
    Themed(title, "TextColor3", "Text", Color3.new(1, 1, 1))
    title.Parent = top
    local close = Button("X", UDim2.new(0, 22, 0, 20), UDim2.new(1, -26, 0.5, -10), top)
    close.MouseButton1Click:Connect(function() gui.Visible = false end)

    local nameBox = Instance.new("TextBox")
    nameBox.Size = UDim2.new(1, -150, 0, 26) nameBox.Position = UDim2.new(0, 8, 0, 40)
    nameBox.BorderSizePixel = 0 nameBox.ClearTextOnFocus = false
    nameBox.PlaceholderText = "Player nick (or Select Player)"
    nameBox.Text = "" nameBox.Font = Enum.Font.Gotham nameBox.TextSize = 11
    Themed(nameBox, "BackgroundColor3", "Element", Color3.fromRGB(25, 30, 40))
    Themed(nameBox, "TextColor3", "Text", Color3.new(1, 1, 1))
    Corner(nameBox, 4) Stroke(nameBox) nameBox.Parent = gui
    env.ToxNamedInputs = env.ToxNamedInputs or {}
    env.ToxNamedInputs["Avatar Items"] = nameBox

    local loadBtn = Button("Load", UDim2.new(0, 64, 0, 26), UDim2.new(1, -138, 0, 40), gui)
    local copyAllBtn = Button("Copy All", UDim2.new(0, 64, 0, 26), UDim2.new(1, -70, 0, 40), gui)

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, -16, 0, 16) status.Position = UDim2.new(0, 8, 0, 100)
    status.BackgroundTransparency = 1 status.Font = Enum.Font.Gotham status.TextSize = 10
    status.TextXAlignment = Enum.TextXAlignment.Left status.Text = "Type a nick and press Load"
    Themed(status, "TextColor3", "DimText", Color3.fromRGB(160, 160, 180))
    status.Parent = gui

    local list = Instance.new("ScrollingFrame")
    list.Size = UDim2.new(1, -16, 1, -126) list.Position = UDim2.new(0, 8, 0, 118)
    list.BackgroundTransparency = 1 list.BorderSizePixel = 0
    list.ScrollBarThickness = 4 list.CanvasSize = UDim2.new()
    list.AutomaticCanvasSize = Enum.AutomaticSize.Y
    list.Parent = gui
    local layout = Instance.new("UIListLayout") layout.Padding = UDim.new(0, 4)
    layout.SortOrder = Enum.SortOrder.LayoutOrder layout.Parent = list

    local currentIds = {}
    local loadToken = 0

    -- Source: "Server" = what they are wearing right now in this server (also changes
    -- made with in-game avatar editors / Catalog Avatar Creator), "Roblox" = their real
    -- saved Roblox avatar.
    local itemSource = "Server"
    local serverTab = Button("Server (now)", UDim2.new(0.5, -12, 0, 24), UDim2.new(0, 8, 0, 72), gui)
    local robloxTab = Button("Roblox (profile)", UDim2.new(0.5, -12, 0, 24), UDim2.new(0.5, 4, 0, 72), gui)
    local function PaintTabs()
        for _, pair in ipairs({ { serverTab, "Server" }, { robloxTab, "Roblox" } }) do
            local active = itemSource == pair[2]
            pair[1].BackgroundColor3 = active and (Theme.Accent or Color3.fromRGB(30, 95, 255)) or (Theme.Element or Color3.fromRGB(25, 30, 40))
            pair[1].TextColor3 = active and Color3.new(1, 1, 1) or (Theme.DimText or Color3.fromRGB(160, 160, 180))
        end
    end
    PaintTabs()

    local ACCESSORY_FIELDS = {
        { "HatAccessory", "Hat" }, { "HairAccessory", "Hair" }, { "FaceAccessory", "Face Acc." },
        { "NeckAccessory", "Neck" }, { "ShouldersAccessory", "Shoulders" }, { "FrontAccessory", "Front" },
        { "BackAccessory", "Back" }, { "WaistAccessory", "Waist" },
    }
    local SINGLE_FIELDS = {
        { "Shirt", "Shirt" }, { "Pants", "Pants" }, { "GraphicTShirt", "T-Shirt" }, { "Face", "Face" },
        { "Head", "Head" }, { "Torso", "Torso" }, { "LeftArm", "Left Arm" }, { "RightArm", "Right Arm" },
        { "LeftLeg", "Left Leg" }, { "RightLeg", "Right Leg" },
        { "IdleAnimation", "Idle Anim" }, { "WalkAnimation", "Walk Anim" }, { "RunAnimation", "Run Anim" },
        { "JumpAnimation", "Jump Anim" }, { "FallAnimation", "Fall Anim" }, { "ClimbAnimation", "Climb Anim" },
        { "SwimAnimation", "Swim Anim" },
    }

    local function CollectItems(target, source)
        local items, seen = {}, {}
        local function add(id, kind)
            id = tonumber(id)
            if id and id > 0 and not seen[id] then
                seen[id] = true
                table.insert(items, { Id = id, Kind = kind })
            end
        end
        local desc = nil
        if source == "Roblox" then
            pcall(function() desc = Players:GetHumanoidDescriptionFromUserId(target.UserId) end)
        else
            local hum = target.Character and target.Character:FindFirstChildOfClass("Humanoid")
            if hum then pcall(function() desc = hum:GetAppliedDescription() end) end
        end
        if not desc then return items end
        for _, f in ipairs(ACCESSORY_FIELDS) do
            for id in string.gmatch(tostring(desc[f[1]] or ""), "%d+") do add(id, f[2]) end
        end
        pcall(function()
            for _, acc in ipairs(desc:GetAccessories(true)) do
                add(acc.AssetId, tostring(acc.AccessoryType.Name))
            end
        end)
        for _, f in ipairs(SINGLE_FIELDS) do
            local ok, value = pcall(function() return desc[f[1]] end)
            if ok then add(value, f[2]) end
        end
        return items
    end

    local function MakeRow(item, order)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -6, 0, 46) row.BorderSizePixel = 0 row.LayoutOrder = order
        Themed(row, "BackgroundColor3", "Element", Color3.fromRGB(25, 30, 40))
        Corner(row, 6) row.Parent = list

        local thumb = Instance.new("ImageLabel")
        thumb.Size = UDim2.new(0, 38, 0, 38) thumb.Position = UDim2.new(0, 4, 0.5, -19)
        thumb.BackgroundTransparency = 1
        thumb.Image = "rbxthumb://type=Asset&id=" .. item.Id .. "&w=150&h=150"
        Corner(thumb, 4) thumb.Parent = row

        local name = Instance.new("TextLabel")
        name.Size = UDim2.new(1, -130, 0, 18) name.Position = UDim2.new(0, 48, 0, 5)
        name.BackgroundTransparency = 1 name.Font = Enum.Font.GothamMedium name.TextSize = 11
        name.TextXAlignment = Enum.TextXAlignment.Left name.TextTruncate = Enum.TextTruncate.AtEnd
        name.Text = AssetNameCache[item.Id] or "Loading..."
        Themed(name, "TextColor3", "Text", Color3.new(1, 1, 1))
        name.Parent = row

        local info = Instance.new("TextLabel")
        info.Size = UDim2.new(1, -130, 0, 14) info.Position = UDim2.new(0, 48, 0, 25)
        info.BackgroundTransparency = 1 info.Font = Enum.Font.Gotham info.TextSize = 10
        info.TextXAlignment = Enum.TextXAlignment.Left
        info.Text = item.Kind .. " • " .. item.Id
        Themed(info, "TextColor3", "DimText", Color3.fromRGB(160, 160, 180))
        info.Parent = row

        local copy = Button("Copy ID", UDim2.new(0, 70, 0, 24), UDim2.new(1, -76, 0.5, -12), row)
        copy.MouseButton1Click:Connect(function()
            if CopyText(tostring(item.Id)) then
                CustomNotify("Copied ID " .. item.Id, Color3.fromRGB(100, 255, 130))
            else
                CustomNotify("Your executor can't copy to clipboard", Color3.fromRGB(255, 120, 120))
            end
        end)

        if not AssetNameCache[item.Id] then
            task.spawn(function()
                local ok, info2 = pcall(function()
                    return MarketplaceService:GetProductInfo(item.Id, Enum.InfoType.Asset)
                end)
                local label = (ok and info2 and info2.Name) or ("Asset " .. item.Id)
                AssetNameCache[item.Id] = label
                if name.Parent then name.Text = label end
            end)
        end
    end

    AvatarItemsLoad = function(text)
        text = tostring(text or nameBox.Text)
        local target = FindPlayerByInput(text)
        if not target and string.lower(text) == string.lower(Player.Name) then
            target = Player
        end
        if not target then
            status.Text = "Player not found"
            return
        end
        nameBox.Text = target.Name
        loadToken = loadToken + 1
        local token = loadToken
        for _, child in ipairs(list:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end
        currentIds = {}
        local source = itemSource
        status.Text = "Loading " .. (source == "Roblox" and "Roblox avatar" or "server skin") .. " of " .. target.DisplayName .. "..."
        task.spawn(function()
            local items = CollectItems(target, source)
            if token ~= loadToken then return end
            for index, item in ipairs(items) do
                table.insert(currentIds, tostring(item.Id))
                MakeRow(item, index)
            end
            local where = source == "Roblox" and "Roblox" or "Server"
            status.Text = (#items > 0)
                and (where .. " • " .. #items .. " items • " .. target.DisplayName .. " (@" .. target.Name .. ")")
                or (where .. " • no items found for " .. target.DisplayName)
        end)
    end

    loadBtn.MouseButton1Click:Connect(function() AvatarItemsLoad(nameBox.Text) end)
    serverTab.MouseButton1Click:Connect(function()
        itemSource = "Server"
        PaintTabs()
        if nameBox.Text ~= "" then AvatarItemsLoad(nameBox.Text) end
    end)
    robloxTab.MouseButton1Click:Connect(function()
        itemSource = "Roblox"
        PaintTabs()
        if nameBox.Text ~= "" then AvatarItemsLoad(nameBox.Text) end
    end)
    nameBox.FocusLost:Connect(function(enter) if enter then AvatarItemsLoad(nameBox.Text) end end)
    copyAllBtn.MouseButton1Click:Connect(function()
        if #currentIds == 0 then
            return CustomNotify("Load a player first", Color3.fromRGB(255, 180, 70))
        end
        if CopyText(table.concat(currentIds, "\n")) then
            CustomNotify("Copied " .. #currentIds .. " IDs", Color3.fromRGB(100, 255, 130))
        else
            CustomNotify("Your executor can't copy to clipboard", Color3.fromRGB(255, 120, 120))
        end
    end)

    AvatarItemsGui = gui
    env.ToxAvatarItemsGui = gui
    env.ToxAvatarItemsLoad = AvatarItemsLoad

    -- Hide/collapse together with the main UI and get the "-" minimize button,
    -- like Music Player / Waypoints (Core may load after this file, so retry).
    task.spawn(function()
        local linked, minimized = false, false
        for _ = 1, 50 do
            if env.Destroyed then return end
            if not linked and env.RegisterToxLinkedSubGui then
                pcall(env.RegisterToxLinkedSubGui, "AvatarItems", gui)
                linked = true
            end
            if not minimized and env.RegisterToxSubGuiMinimize then
                pcall(env.RegisterToxSubGuiMinimize, gui, -52)
                minimized = true
            end
            if linked and minimized then return end
            task.wait(0.2)
        end
        -- fallback: at least hide with the main window
        env.ToxLinkedSubGuis = env.ToxLinkedSubGuis or {}
        env.ToxLinkedSubGuis.AvatarItems = gui
    end)
end
CreateButton("Tox Music Player", FlingPage, function() MusicGui.Visible = not MusicGui.Visible end)
CreateButton("Tox Waypoints", FlingPage, function() WaypointsGui.Visible = not WaypointsGui.Visible end)
CreateButton("Tox Avatar Items", FlingPage, function()
    if AvatarItemsGui then
        AvatarItemsGui.Visible = not AvatarItemsGui.Visible
    end
end)
do
    local SCRIPTS_BASE = "https://raw.githubusercontent.com/BG-0o/Scripts/refs/heads/main/Scripts/"
    local function RunCommunityScript(label, relFile)
        local ok, err = pcall(function()
            local cacheBuster = "?toxcache=" .. tostring(os.time()) .. "_" .. tostring(math.random(1000, 999999))
            local src = game:HttpGet(SCRIPTS_BASE .. relFile .. cacheBuster)
            local chunk, compErr = loadstring(src)
            if not chunk then
                error(tostring(compErr or "compile error"))
            end
            chunk()
        end)
        if not ok then
            CustomNotify("Failed to load " .. label .. ": " .. tostring(err), Color3.fromRGB(255, 95, 95), 4)
        end
    end

    if getgenv().CreateSection then getgenv().CreateSection(ScriptsPage, "Community Scripts", "📜") end
    CreateButton("BigFroot", ScriptsPage, function()
        RunCommunityScript("BigFroot", "BigFroot.lua")
    end)
    CreateButton("FE Emotes", ScriptsPage, function()
        RunCommunityScript("FE Emotes", "FEEmotes.lua")
    end)
    CreateButton("PShade", ScriptsPage, function()
        RunCommunityScript("PShade", "PShade.lua")
    end)
    CreateButton("Infinite Yield", ScriptsPage, function()
        RunCommunityScript("Infinite Yield", "InfiniteYield.lua")
    end)
    CreateButton("Bundle Edit", ScriptsPage, function()
        RunCommunityScript("Bundle Edit", "BundleEdit.lua")
    end)
    if getgenv().ClearActivePageCard then
        pcall(getgenv().ClearActivePageCard, ScriptsPage)
    end
end
task.spawn(function()
    if getgenv().ScriptsPage then
        local function RunSaveGame(decompile)
            local modeText = decompile and " (Decompiled Scripts)" or " (Standard)"
            CustomNotify("Starting Save Game" .. modeText .. "...", Color3.fromRGB(218, 170, 42))
            task.spawn(function()
                local ok, err = pcall(function()
                    local SaveInstance = saveinstance or (getgenv and getgenv().saveinstance)
                    if not SaveInstance then
                        SaveInstance = loadstring(game:HttpGet("https://raw.githubusercontent.com/luau/UniversalSynSaveInstance/main/saveinstance.lua"))()
                        if type(SaveInstance) == "table" and SaveInstance.Save then
                            SaveInstance = SaveInstance.Save
                        end
                    end
                    if type(SaveInstance) == "function" then
                        if decompile then
                            SaveInstance({Decompile = true, DecompileTimeout = 10})
                        else
                            SaveInstance()
                        end
                    else
                        error("saveinstance API not supported by executor")
                    end
                end)
                if ok then
                    CustomNotify("Save Game completed successfully!", Color3.fromRGB(50, 220, 90))
                else
                    CustomNotify("Save Game failed: " .. tostring(err), Color3.fromRGB(255, 80, 80))
                end
            end)
        end
        if getgenv().CreateSection then getgenv().CreateSection(getgenv().ScriptsPage, "Save Game & World", "💾") end
        CreateButton("Save Place (Standard)", getgenv().ScriptsPage, function() RunSaveGame(false) end)
        CreateButton("Save Place (Decompile Scripts)", getgenv().ScriptsPage, function() RunSaveGame(true) end)
        if getgenv().ClearActivePageCard then
            pcall(getgenv().ClearActivePageCard, getgenv().ScriptsPage)
        end
    end
end)
