local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")
local SoundService = game:GetService("SoundService")
local TextChatService = game:GetService("TextChatService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Settings = getgenv().Settings
local MAIN_COLOR = getgenv().MAIN_COLOR or Color3.fromRGB(9, 0, 136)
local ColorMap = getgenv().ColorMap or {}

local CombatPage = getgenv().CombatPage
local PlayerPage = getgenv().PlayerPage
local VisualsPage = getgenv().VisualsPage
local FlingPage = getgenv().FlingPage
local ScriptsPage = getgenv().ScriptsPage
local ConfigPage = getgenv().ConfigPage

local CreateToggle = getgenv().CreateToggle
local CreateToggleWithValue = getgenv().CreateToggleWithValue
local CreateDropdown = getgenv().CreateDropdown
local CreateInputWithButton = getgenv().CreateInputWithButton
local CreateInputWithTwoButtons = getgenv().CreateInputWithTwoButtons
local CreateButton = getgenv().CreateButton
local CreateConfirmButton = getgenv().CreateConfirmButton
local CreateKeybindButton = getgenv().CreateKeybindButton
local CustomNotify = getgenv().CustomNotify
local AutoSaveConfiguration = getgenv().AutoSaveConfiguration
local UpdateMouseIcon = getgenv().UpdateMouseIcon
local UpdateAirWalk = getgenv().UpdateAirWalk
local UpdateFullbright = getgenv().UpdateFullbright
local ResetHitboxes = getgenv().ResetHitboxes
local AddConnection = getgenv().AddConnection

local function SkidFling(TargetPlayer)
    if not TargetPlayer or TargetPlayer == Player then return end
    local Character = Player.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local RootPart = Humanoid and Humanoid.RootPart or (Character and Character:FindFirstChild("HumanoidRootPart"))

    local TCharacter = TargetPlayer.Character
    if not TCharacter then return end
    local THumanoid = TCharacter:FindFirstChildOfClass("Humanoid")
    local TRootPart = THumanoid and THumanoid.RootPart or TCharacter:FindFirstChild("HumanoidRootPart")
    local THead = TCharacter:FindFirstChild("Head")

    if Character and Humanoid and RootPart and TRootPart then
        local OldPos = RootPart.CFrame
        local OldFPDH = workspace.FallenPartsDestroyHeight
        workspace.FallenPartsDestroyHeight = 0/0

        local BV = Instance.new("BodyVelocity")
        BV.Name = "ToxFlingVel"
        BV.Parent = RootPart
        BV.Velocity = Vector3.new(9e8, 9e8, 9e8)
        BV.MaxForce = Vector3.new(1/0, 1/0, 1/0)

        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)

        local SFBasePart = function(BasePart)
            local TimeToWait = 2
            local Time = tick()
            local Angle = 0

            repeat
                if RootPart and THumanoid and BasePart and BasePart.Parent then
                    Angle = Angle + 100
                    RootPart.CFrame = CFrame.new(BasePart.Position) * CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(Angle), 0, 0)
                    Character:SetPrimaryPartCFrame(RootPart.CFrame)
                    RootPart.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
                    RootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
                    task.wait()
                else
                    break
                end
            until BasePart.Velocity.Magnitude > 500 or BasePart.Parent ~= TargetPlayer.Character or TargetPlayer.Parent ~= Players or THumanoid.Sit or Humanoid.Health <= 0 or tick() > Time + TimeToWait
        end

        SFBasePart(TRootPart or THead)

        BV:Destroy()
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
        workspace.FallenPartsDestroyHeight = OldFPDH

        RootPart.CFrame = OldPos
        RootPart.Velocity = Vector3.new()
        RootPart.RotVelocity = Vector3.new()
    end
end

CreateToggle("Aimbot", CombatPage, Settings.Aimbot, function(v) Settings.Aimbot = v end)
CreateToggleWithValue("Smoothness", CombatPage, false, Settings.AimbotSmoothness, nil, function(v) Settings.AimbotSmoothness = math.clamp(v, 1, 10) end)
CreateDropdown("Aim Part", {"Head", "HumanoidRootPart", "Torso"}, CombatPage, Settings.AimPart, function(v) Settings.AimPart = v end)
CreateToggle("Wall Check", CombatPage, Settings.AimWallCheck, function(v) Settings.AimWallCheck = v end)
CreateToggle("Show FOV", CombatPage, Settings.ShowFOV, function(v) Settings.ShowFOV = v end)
CreateToggleWithValue("FOV Radius", CombatPage, false, Settings.FOVRadius, nil, function(v) Settings.FOVRadius = v end)
CreateToggle("Silent Aim", CombatPage, Settings.SilentAim, function(v) Settings.SilentAim = v end)
CreateToggle("Triggerbot", CombatPage, Settings.Triggerbot, function(v) Settings.Triggerbot = v end)
CreateToggleWithValue("Spinbot", CombatPage, Settings.Spinbot, Settings.SpinSpeed, function(v) Settings.Spinbot = v end, function(v) Settings.SpinSpeed = v end)
CreateToggleWithValue("Hitbox Expander", CombatPage, Settings.HitboxExpander, Settings.HitboxSize, function(v)
    Settings.HitboxExpander = v
    if not v then ResetHitboxes() end
end, function(v) Settings.HitboxSize = v end)
CreateToggleWithValue("Kill Aura", CombatPage, Settings.KillAura, Settings.KillAuraRange, function(v) Settings.KillAura = v end, function(v) Settings.KillAuraRange = v end)

CreateToggle("Noclip", PlayerPage, Settings.Noclip, function(v)
    Settings.Noclip = v
    if not v then getgenv().RestoreCollisions() end
end)
CreateToggle("Infinite Jump", PlayerPage, Settings.InfiniteJump, function(v) Settings.InfiniteJump = v end)
CreateToggleWithValue("WalkSpeed", PlayerPage, Settings.Speed, Settings.SpeedValue, function(v) Settings.Speed = v end, function(v) Settings.SpeedValue = v end)
CreateToggleWithValue("JumpPower", PlayerPage, Settings.Jump, Settings.JumpValue, function(v) Settings.Jump = v end, function(v) Settings.JumpValue = v end)
CreateToggleWithValue("Smooth Fly", PlayerPage, Settings.SmoothFly, Settings.FlySpeed, function(v) Settings.SmoothFly = v end, function(v) Settings.FlySpeed = v end)
CreateToggle("Normal Fly", PlayerPage, Settings.NormalFly, function(v) Settings.NormalFly = v end)
CreateToggleWithValue("BHop", PlayerPage, Settings.Bhop, Settings.BhopDelay, function(v) Settings.Bhop = v end, function(v) Settings.BhopDelay = math.clamp(v, 0.01, 1) end)
CreateToggle("Air Walk", PlayerPage, Settings.AirWalk, function(v)
    Settings.AirWalk = v
    UpdateAirWalk()
end)
CreateToggleWithValue("Car Speed", PlayerPage, Settings.CarSpeed, Settings.CarSpeedValue, function(v) Settings.CarSpeed = v end, function(v) Settings.CarSpeedValue = v end)
CreateToggleWithValue("Car Fly", PlayerPage, Settings.CarFly, Settings.CarFlySpeed, function(v) Settings.CarFly = v end, function(v) Settings.CarFlySpeed = v end)
CreateInputWithTwoButtons("Loop TP Target", PlayerPage, "", "TP", "LOOP", function(text, mode)
    if text ~= "" then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= Player and (p.Name:lower():find(text:lower()) or p.DisplayName:lower():find(text:lower())) then
                if mode == "TP" then
                    if Player.Character and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                        Player.Character:SetPrimaryPartCFrame(p.Character.HumanoidRootPart.CFrame)
                        CustomNotify("Teleported to " .. p.Name, Color3.fromRGB(100, 255, 100))
                    end
                elseif mode == "LOOP" then
                    if Settings.LoopTPTarget == p then
                        Settings.LoopTPTarget = nil
                        CustomNotify("Stopped Loop TP", Color3.fromRGB(255, 100, 100))
                    else
                        Settings.LoopTPTarget = p
                        CustomNotify("Loop TP on " .. p.Name, Color3.fromRGB(100, 255, 100))
                    end
                end
                break
            end
        end
    else
        Settings.LoopTPTarget = nil
    end
end)
CreateToggle("Anti Void", PlayerPage, Settings.AntiVoid, function(v) Settings.AntiVoid = v end)
CreateToggle("Anti Fling", PlayerPage, Settings.AntiFling, function(v) Settings.AntiFling = v end)
CreateToggle("Ctrl + Click TP", PlayerPage, Settings.CtrlClickTP, function(v) Settings.CtrlClickTP = v end)
CreateToggle("Anti AFK", PlayerPage, Settings.AntiAFK, function(v) Settings.AntiAFK = v end)

CreateToggleWithValue("Custom Crosshair", VisualsPage, Settings.CustomMouseIcon, Settings.MouseIconID, function(v)
    Settings.CustomMouseIcon = v
    UpdateMouseIcon()
end, function(val)
    Settings.MouseIconID = tostring(val)
    UpdateMouseIcon()
end)
CreateToggle("Crosshair", VisualsPage, Settings.Crosshair, function(v) Settings.Crosshair = v end)
CreateToggle("ESP Names", VisualsPage, Settings.ESPNames, function(v) Settings.ESPNames = v end)
CreateToggle("ESP Distance", VisualsPage, Settings.ESPDistance, function(v) Settings.ESPDistance = v end)
CreateToggle("ESP Box", VisualsPage, Settings.ESPBox, function(v) Settings.ESPBox = v end)
CreateToggle("ESP Tracers", VisualsPage, Settings.ESPTracers, function(v) Settings.ESPTracers = v end)
CreateDropdown("Tracer Origin", {"DOWN", "CENTER", "MOUSE"}, VisualsPage, Settings.TracerOrigin, function(v) Settings.TracerOrigin = v end)
CreateToggle("ESP Head Dot", VisualsPage, Settings.ESPHeadDot, function(v) Settings.ESPHeadDot = v end)
CreateToggle("Chams", VisualsPage, Settings.Chams, function(v) Settings.Chams = v end)
CreateDropdown("ESP Color", {"White", "Red", "Green", "Blue", "Yellow", "Cyan", "Magenta", "Orange", "Purple", "Lime", "Pink", "Gold"}, VisualsPage, Settings.EspColorName, function(v)
    Settings.EspColorName = v
    Settings.EspColor = ColorMap[v] or Color3.fromRGB(255, 255, 255)
end)
CreateToggle("Fullbright", VisualsPage, Settings.Fullbright, function(v)
    Settings.Fullbright = v
    UpdateFullbright()
end)
CreateToggle("Force ShiftLock", VisualsPage, Settings.ForceShiftLock, function(v) Settings.ForceShiftLock = v end)
CreateToggleWithValue("Field of View", VisualsPage, Settings.FOVEnabled, Settings.FOVValue, function(v)
    Settings.FOVEnabled = v
    if not v then Camera.FieldOfView = 70 end
end, function(v) Settings.FOVValue = v end)

CreateInputWithButton("Fling Target", FlingPage, "", "Fling", function(text)
    if text ~= "" then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= Player and (p.Name:lower():find(text:lower()) or p.DisplayName:lower():find(text:lower())) then
                CustomNotify("Flinging " .. p.Name, Color3.fromRGB(255, 150, 50))
                SkidFling(p)
                break
            end
        end
    end
end)
CreateInputWithButton("Loop Fling", FlingPage, "", "Toggle", function(text)
    if text ~= "" then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= Player and (p.Name:lower():find(text:lower()) or p.DisplayName:lower():find(text:lower())) then
                if getgenv().LoopFlingTarget == p then
                    getgenv().LoopFlingTarget = nil
                    CustomNotify("Stopped Loop Fling", Color3.fromRGB(255, 100, 100))
                else
                    getgenv().LoopFlingTarget = p
                    CustomNotify("Loop Flinging " .. p.Name, Color3.fromRGB(100, 255, 100))
                end
                break
            end
        end
    else
        getgenv().LoopFlingTarget = nil
    end
end)
CreateButton("Fling All", FlingPage, function()
    CustomNotify("Flinging All Players...", Color3.fromRGB(255, 150, 50))
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player then SkidFling(p) end
    end
end)
CreateButton("Chat Logs Window", FlingPage, function()
    getgenv().ChatLogGui.Visible = not getgenv().ChatLogGui.Visible
end)
CreateButton("Waypoints Window", FlingPage, function()
    getgenv().WaypointsGui.Visible = not getgenv().WaypointsGui.Visible
end)
CreateButton("Music Player Window", FlingPage, function()
    getgenv().MusicGui.Visible = not getgenv().MusicGui.Visible
end)

CreateButton("Bundle Edit", ScriptsPage, function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/BG-0o/All/refs/heads/main/BundleEdit.lua"))()
end)
CreateButton("Infinity Yield", ScriptsPage, function()
    loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
end)
CreateButton("Dex Explorer", ScriptsPage, function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/dex.lua"))()
end)
CreateButton("Remote Spy", ScriptsPage, function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/exserter/SimpleSpy/main/SimpleSpy.lua"))()
end)

CreateButton("Save Configuration", ConfigPage, function()
    AutoSaveConfiguration()
    CustomNotify("Configuration Saved!", Color3.fromRGB(100, 255, 100))
end)
CreateConfirmButton("Reset Configuration", ConfigPage, function()
    if isfile and isfile("ToxV1_Data/config.json") then
        delfile("ToxV1_Data/config.json")
    end
    CustomNotify("Config Reset! Rejoin to apply.", Color3.fromRGB(255, 100, 100))
end)
CreateKeybindButton("Toggle GUI Keybind", ConfigPage, Settings.GUIKeybind, function(key)
    Settings.GUIKeybind = key
    CustomNotify("Keybind Set: " .. key.Name, Color3.fromRGB(100, 255, 100))
end)
CreateConfirmButton("Destroy Script", ConfigPage, function()
    getgenv().Destroyed = true
    getgenv().ScriptLoaded = false
    if getgenv().Gui then getgenv().Gui:Destroy() end
    if getgenv().NotifGui then getgenv().NotifGui:Destroy() end
    if getgenv().FOVCircle then getgenv().FOVCircle:Remove() end
    if getgenv().CrosshairH then getgenv().CrosshairH:Remove() end
    if getgenv().CrosshairV then getgenv().CrosshairV:Remove() end
    if getgenv().ActiveSound then getgenv().ActiveSound:Destroy() end
    pcall(function() Player:GetMouse().Icon = "" end)
    getgenv().RestoreCollisions()
    ResetHitboxes()
    Settings.Fullbright = false
    UpdateFullbright()
    if getgenv().ScriptConnections then
        for _, conn in ipairs(getgenv().ScriptConnections) do pcall(function() conn:Disconnect() end) end
    end
end)

local function GetClosestTarget()
    local closest = nil
    local shortestDistance = Settings.FOVRadius

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player and p.Character then
            local targetPart = p.Character:FindFirstChild(Settings.AimPart) or p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if targetPart and hum and hum.Health > 0 then
                if Settings.AimWallCheck then
                    local parts = Camera:GetPartsObscuringTarget({targetPart.Position}, {Player.Character, p.Character})
                    if #parts > 0 then continue end
                end

                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local mousePos = UserInputService:GetMouseLocation()
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if dist < shortestDistance then
                        shortestDistance = dist
                        closest = targetPart
                    end
                end
            end
        end
    end
    return closest
end

local lastBhop = 0
AddConnection(RunService.Heartbeat:Connect(function()
    if getgenv().Destroyed then return end
    local Char = Player.Character
    local Hum = Char and Char:FindFirstChildOfClass("Humanoid")
    local Root = Char and Char:FindFirstChild("HumanoidRootPart")

    if Settings.Bhop and Hum then
        if Hum.FloorMaterial ~= Enum.Material.Air and Hum.MoveDirection.Magnitude > 0 then
            local delayTime = tonumber(Settings.BhopDelay) or 0.05
            if tick() - lastBhop >= delayTime then
                Hum:ChangeState(Enum.HumanoidStateType.Jumping)
                lastBhop = tick()
            end
        end
    end

    if Settings.Noclip and Char then
        for _, part in ipairs(Char:GetChildren()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end

    if Settings.Speed and Hum then Hum.WalkSpeed = Settings.SpeedValue end
    if Settings.Jump and Hum then Hum.JumpPower = Settings.JumpValue end

    if Settings.SmoothFly and Root then
        local flyVel = Vector3.new()
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then flyVel = flyVel + Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then flyVel = flyVel - Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then flyVel = flyVel - Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then flyVel = flyVel + Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then flyVel = flyVel + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then flyVel = flyVel - Vector3.new(0, 1, 0) end
        Root.Velocity = flyVel * (Settings.FlySpeed * 5)
    end

    if Settings.NormalFly and Root then
        Root.Velocity = Vector3.new(0, 2, 0)
    end

    if Settings.AirWalk then UpdateAirWalk() end

    if Settings.LoopTPTarget and Settings.LoopTPTarget.Character and Root then
        local trp = Settings.LoopTPTarget.Character:FindFirstChild("HumanoidRootPart")
        if trp then Root.CFrame = trp.CFrame * CFrame.new(0, 0, 3) end
    end

    if getgenv().LoopFlingTarget then
        SkidFling(getgenv().LoopFlingTarget)
    end

    if Settings.Spinbot and Root then
        Root.CFrame = Root.CFrame * CFrame.Angles(0, math.rad(Settings.SpinSpeed or 50), 0)
    end

    if Settings.HitboxExpander then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= Player and p.Character then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.Size = Vector3.new(Settings.HitboxSize, Settings.HitboxSize, Settings.HitboxSize)
                    hrp.Transparency = 0.7
                    hrp.CanCollide = false
                end
            end
        end
    end

    if Settings.KillAura and Root then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= Player and p.Character then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                if hrp and hum and hum.Health > 0 then
                    if (hrp.Position - Root.Position).Magnitude <= Settings.KillAuraRange then
                        local tool = Char:FindFirstChildOfClass("Tool")
                        if tool then tool:Activate() end
                    end
                end
            end
        end
    end

    if Settings.AntiVoid and Root and Root.Position.Y < -100 then
        Root.Velocity = Vector3.new(0, 100, 0)
        Root.CFrame = Root.CFrame + Vector3.new(0, 150, 0)
    end

    if Settings.ForceShiftLock then
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    end

    if Settings.FOVEnabled then
        Camera.FieldOfView = Settings.FOVValue
    end
end))

AddConnection(UserInputService.JumpRequest:Connect(function()
    if Settings.InfiniteJump and Player.Character then
        local hum = Player.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end))

AddConnection(UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if Settings.GUIKeybind and input.KeyCode == Settings.GUIKeybind then
        getgenv().Main.Visible = not getgenv().Main.Visible
    end
    if Settings.CtrlClickTP and input.UserInputType == Enum.UserInputType.MouseButton1 and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        local mouse = Player:GetMouse()
        if mouse and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
            Player.Character.HumanoidRootPart.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
        end
    end
end))

AddConnection(RunService.RenderStepped:Connect(function()
    if getgenv().Destroyed then return end

    if getgenv().FOVCircle then
        getgenv().FOVCircle.Visible = Settings.ShowFOV
        getgenv().FOVCircle.Radius = Settings.FOVRadius
        getgenv().FOVCircle.Position = UserInputService:GetMouseLocation()
    end

    if getgenv().CrosshairH and getgenv().CrosshairV then
        local mousePos = UserInputService:GetMouseLocation()
        local vis = Settings.Crosshair
        getgenv().CrosshairH.Visible = vis
        getgenv().CrosshairV.Visible = vis
        if vis then
            getgenv().CrosshairH.From = Vector2.new(mousePos.X - 10, mousePos.Y)
            getgenv().CrosshairH.To = Vector2.new(mousePos.X + 10, mousePos.Y)
            getgenv().CrosshairV.From = Vector2.new(mousePos.X, mousePos.Y - 10)
            getgenv().CrosshairV.To = Vector2.new(mousePos.X, mousePos.Y + 10)
        end
    end

    if Settings.Aimbot and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local target = GetClosestTarget()
        if target then
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, target.Position), 1 / math.clamp(Settings.AimbotSmoothness, 1, 10))
        end
    end

    if Settings.Triggerbot then
        local mouse = Player:GetMouse()
        if mouse.Target and mouse.Target.Parent then
            local p = Players:GetPlayerFromCharacter(mouse.Target.Parent)
            if p and p ~= Player then
                local tool = Player.Character and Player.Character:FindFirstChildOfClass("Tool")
                if tool then tool:Activate() end
            end
        end
    end
end))

pcall(function()
    local rawMetatable = getrawmetatable(game)
    local oldNamecall = rawMetatable.__namecall
    setreadonly(rawMetatable, false)

    rawMetatable.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if not getgenv().Destroyed and Settings.SilentAim and tostring(method) == "Raycast" then
            local target = GetClosestTarget()
            if target then
                local args = {...}
                args[2] = (target.Position - args[1]).Unit * 1000
                return oldNamecall(self, unpack(args))
            end
        end
        return oldNamecall(self, ...)
    end)
    setreadonly(rawMetatable, true)
end)

local ESPObjects = {}
AddConnection(RunService.RenderStepped:Connect(function()
    if getgenv().Destroyed then
        for _, esp in pairs(ESPObjects) do
            for _, obj in pairs(esp) do pcall(function() obj:Remove() end) end
        end
        return
    end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = p.Character.HumanoidRootPart
            local head = p.Character:FindFirstChild("Head")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")

            if not ESPObjects[p] then
                ESPObjects[p] = {
                    Box = Drawing.new("Square"),
                    Name = Drawing.new("Text"),
                    Tracer = Drawing.new("Line"),
                    HeadDot = Drawing.new("Circle")
                }
            end

            local esp = ESPObjects[p]
            local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            local dist = (Camera.CFrame.Position - hrp.Position).Magnitude

            if onScreen and dist <= Settings.EspMaxDistance and hum and hum.Health > 0 then
                local color = Settings.EspColor

                if Settings.ESPBox then
                    local sizeY = math.clamp(2000 / dist, 10, 500)
                    local sizeX = sizeY * 0.6
                    esp.Box.Visible = true
                    esp.Box.Size = Vector2.new(sizeX, sizeY)
                    esp.Box.Position = Vector2.new(pos.X - sizeX / 2, pos.Y - sizeY / 2)
                    esp.Box.Color = color
                    esp.Box.Thickness = 1.5
                else esp.Box.Visible = false end

                if Settings.ESPNames or Settings.ESPDistance then
                    esp.Name.Visible = true
                    local txt = ""
                    if Settings.ESPNames then txt = txt .. p.Name end
                    if Settings.ESPDistance then txt = txt .. " [" .. math.floor(dist) .. "m]" end
                    esp.Name.Text = txt
                    esp.Name.Position = Vector2.new(pos.X, pos.Y - 25)
                    esp.Name.Color = color
                    esp.Name.Center = true
                    esp.Name.Size = 13
                else esp.Name.Visible = false end

                if Settings.ESPTracers then
                    esp.Tracer.Visible = true
                    esp.Tracer.To = Vector2.new(pos.X, pos.Y)
                    esp.Tracer.Color = color
                    esp.Tracer.Thickness = 1
                    if Settings.TracerOrigin == "DOWN" then
                        esp.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    elseif Settings.TracerOrigin == "CENTER" then
                        esp.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                    else
                        esp.Tracer.From = UserInputService:GetMouseLocation()
                    end
                else esp.Tracer.Visible = false end

                if Settings.ESPHeadDot and head then
                    local headPos, headOn = Camera:WorldToViewportPoint(head.Position)
                    if headOn then
                        esp.HeadDot.Visible = true
                        esp.HeadDot.Position = Vector2.new(headPos.X, headPos.Y)
                        esp.HeadDot.Radius = math.clamp(500 / dist, 2, 10)
                        esp.HeadDot.Color = color
                        esp.HeadDot.Filled = true
                    else esp.HeadDot.Visible = false end
                else esp.HeadDot.Visible = false end

                if Settings.Chams then
                    if not p.Character:FindFirstChild("ToxHighlight") then
                        local hl = Instance.new("Highlight")
                        hl.Name = "ToxHighlight"
                        hl.FillColor = color
                        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                        hl.FillTransparency = 0.5
                        hl.Parent = p.Character
                    else
                        p.Character.ToxHighlight.FillColor = color
                    end
                else
                    if p.Character:FindFirstChild("ToxHighlight") then p.Character.ToxHighlight:Destroy() end
                end
            else
                esp.Box.Visible = false
                esp.Name.Visible = false
                esp.Tracer.Visible = false
                esp.HeadDot.Visible = false
            end
        elseif ESPObjects[p] then
            for _, obj in pairs(ESPObjects[p]) do obj.Visible = false end
        end
    end
end))

local LoadScreen = Instance.new("ScreenGui")
LoadScreen.Name = "ToxLoading"
LoadScreen.DisplayOrder = 999999999
LoadScreen.Parent = (gethui and gethui()) or game:GetService("CoreGui")

local LoadFrame = Instance.new("Frame")
LoadFrame.Size = UDim2.new(0, 320, 0, 180)
LoadFrame.Position = UDim2.new(0.5, -160, 0.5, -90)
LoadFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 16)
LoadFrame.BorderSizePixel = 0
LoadFrame.ClipsDescendants = true
LoadFrame.Parent = LoadScreen

local LoadCorner = Instance.new("UICorner") LoadCorner.CornerRadius = UDim.new(0, 10) LoadCorner.Parent = LoadFrame
local LoadStroke = Instance.new("UIStroke") LoadStroke.Color = MAIN_COLOR LoadStroke.Thickness = 2 LoadStroke.Parent = LoadFrame

local LoadLogo = Instance.new("ImageLabel")
LoadLogo.Size = UDim2.new(0, 48, 0, 48)
LoadLogo.Position = UDim2.new(0.5, -24, 0, 18)
LoadLogo.BackgroundTransparency = 1
LoadLogo.Image = getgenv().LOGO_ID or "rbxassetid://120675082996894"
LoadLogo.Parent = LoadFrame

local LoadTitle = Instance.new("TextLabel")
LoadTitle.Size = UDim2.new(1, 0, 0, 22)
LoadTitle.Position = UDim2.new(0, 0, 0, 72)
LoadTitle.BackgroundTransparency = 1
LoadTitle.Text = "ToxHub"
LoadTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
LoadTitle.Font = Enum.Font.GothamBold
LoadTitle.TextSize = 16
LoadTitle.Parent = LoadFrame

local BarBg = Instance.new("Frame")
BarBg.Size = UDim2.new(0.8, 0, 0, 8)
BarBg.Position = UDim2.new(0.1, 0, 0, 105)
BarBg.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
BarBg.BorderSizePixel = 0
BarBg.Parent = LoadFrame
local BarBgCorner = Instance.new("UICorner") BarBgCorner.CornerRadius = UDim.new(0, 4) BarBgCorner.Parent = BarBg

local BarFill = Instance.new("Frame")
BarFill.Size = UDim2.new(0, 0, 1, 0)
BarFill.BackgroundColor3 = MAIN_COLOR
BarFill.BorderSizePixel = 0
BarFill.Parent = BarBg
local BarFillCorner = Instance.new("UICorner") BarFillCorner.CornerRadius = UDim.new(0, 4) BarFillCorner.Parent = BarFill

local WatermarkLbl = Instance.new("TextLabel")
WatermarkLbl.Size = UDim2.new(1, 0, 0, 20)
WatermarkLbl.Position = UDim2.new(0, 0, 1, -24)
WatermarkLbl.BackgroundTransparency = 1
WatermarkLbl.Text = "made by @BG_0o"
WatermarkLbl.TextColor3 = Color3.fromRGB(150, 150, 180)
WatermarkLbl.Font = Enum.Font.Gotham
WatermarkLbl.TextSize = 11
WatermarkLbl.Parent = LoadFrame

local fillTween = TweenService:Create(BarFill, TweenInfo.new(1.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 1, 0)})
fillTween:Play()

fillTween.Completed:Connect(function()
    task.wait(0.2)
    LoadScreen:Destroy()
    
    local MainFrame = getgenv().Main
    if MainFrame then
        MainFrame.Visible = true
        MainFrame.Size = UDim2.new(0, 0, 0, 0)
        MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
        TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 520, 0, 360),
            Position = UDim2.new(0.5, -260, 0.5, -180)
        }):Play()
    end

    getgenv().ScriptLoaded = true
    CustomNotify("ToxHub Loaded Successfully!", Color3.fromRGB(100, 255, 100), 4)
    UpdateMouseIcon()
end)

getgenv().Minimize.MouseButton1Click:Connect(function()
    local MainFrame = getgenv().Main
    if MainFrame then
        MainFrame.Visible = false
        CustomNotify("Press " .. (Settings.GUIKeybind and Settings.GUIKeybind.Name or "Keybind") .. " to open GUI", Color3.fromRGB(200, 200, 255), 3)
    end
end)
