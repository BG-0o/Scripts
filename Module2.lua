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

for _, page in pairs(Pages) do
    for _, child in ipairs(page:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextButton") then
            child:Destroy()
        end
    end
end

local function SkidFling(TargetPlayer)
	if not TargetPlayer or not TargetPlayer.Character then return end
	local Char = Player.Character
	local Hum = Char and Char:FindFirstChildOfClass("Humanoid")
	local Root = Hum and Hum.RootPart or Char:FindFirstChild("HumanoidRootPart")
	local TRoot = TargetPlayer.Character:FindFirstChild("HumanoidRootPart") or TargetPlayer.Character:FindFirstChild("Torso")

	if Char and Hum and Root and TRoot then
		local oldPos = Root.CFrame
        local bav = Instance.new("BodyAngularVelocity")
        bav.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        bav.AngularVelocity = Vector3.new(0, 999999, 0)
        bav.Parent = Root

        local startTime = tick()
        while tick() - startTime < 1.8 do
            if not TRoot or not Root then break end
            Hum:ChangeState(Enum.HumanoidStateType.StrafingNoPhysics)
            Root.CFrame = TRoot.CFrame * CFrame.new(math.random(-1,1), math.random(-1,1), math.random(-1,1))
            Root.Velocity = Vector3.new(999999, 999999, 999999)
            RunService.Heartbeat:Wait()
        end

        bav:Destroy()
        Root.Velocity = Vector3.zero
        Root.RotVelocity = Vector3.zero
        Root.CFrame = oldPos
	end
end

local function ExecuteFling(TargetInput)
	if not TargetInput or TargetInput == "" then return CustomNotify("Enter username or 'all'", Color3.fromRGB(255, 100, 100)) end
	local LowerInput = string.lower(TargetInput)
	if LowerInput == "all" or LowerInput == "others" then
		for _, p in ipairs(Players:GetPlayers()) do if p ~= Player then SkidFling(p) end end
	else
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= Player and (string.find(string.lower(p.Name), LowerInput) or string.find(string.lower(p.DisplayName), LowerInput)) then
				SkidFling(p) break
			end
		end
	end
end

local function ExecuteTeleport(TargetInput, mode)
    if not TargetInput or TargetInput == "" then 
        if mode == "LOOP" then Settings.LoopTPTarget = nil CustomNotify("Loop TP Disabled", Color3.fromRGB(255, 100, 100)) end
        return CustomNotify("Enter username", Color3.fromRGB(255, 100, 100)) 
    end
    local LowerInput = string.lower(TargetInput)
    local targetObj = nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player and (string.find(string.lower(p.Name), LowerInput) or string.find(string.lower(p.DisplayName), LowerInput)) then
            targetObj = p break
        end
    end

    if targetObj and targetObj.Character and targetObj.Character:FindFirstChild("HumanoidRootPart") then
        local tHrp = targetObj.Character.HumanoidRootPart
        local Root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if mode == "TP" then
            if Root then Root.CFrame = tHrp.CFrame * CFrame.new(0, 0, -3) end
            CustomNotify("Teleported to " .. targetObj.DisplayName, Color3.fromRGB(100, 255, 100))
        elseif mode == "LOOP" then
            if Settings.LoopTPTarget == targetObj then
                Settings.LoopTPTarget = nil
                CustomNotify("Loop TP Disabled", Color3.fromRGB(255, 100, 100))
            else
                Settings.LoopTPTarget = targetObj
                CustomNotify("Loop TP Enabled on " .. targetObj.DisplayName, Color3.fromRGB(100, 255, 100))
            end
        end
    else
        CustomNotify("Player not found!", Color3.fromRGB(255, 100, 100))
    end
end

local function ServerHop()
    pcall(function()
        local sfUrl = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/0?sortOrder=Asc&limit=100"
        local req = game:HttpGet(sfUrl)
        local data = HttpService:JSONDecode(req)
        if data and data.data then
            for _, s in ipairs(data.data) do
                if s.playing < s.maxPlayers and s.id ~= game.JobId then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, Player)
                    CustomNotify("Teleporting to server...", Color3.fromRGB(100, 255, 100))
                    return
                end
            end
        end
        CustomNotify("No suitable server found", Color3.fromRGB(255, 100, 100))
    end)
end

local function BoostFPS()
    pcall(function()
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") then
                v.Material = Enum.Material.SmoothPlastic
                v.Reflectance = 0
            elseif v:IsA("Decal") or v:IsA("Texture") then
                v:Destroy()
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
                v.Enabled = false
            end
        end
        CustomNotify("FPS Boosted!", Color3.fromRGB(100, 255, 100))
    end)
end

local LastSafeCFrame = nil
local AntiVoidConnection = nil
local function StartAntiVoid()
	if AntiVoidConnection then AntiVoidConnection:Disconnect() end
	AntiVoidConnection = AddConnection(RunService.Heartbeat:Connect(function()
		local Root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        local Hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
        if Destroyed or not ScriptLoaded or not Settings.AntiVoid or not Root or not Hum then return end
		if Hum.FloorMaterial ~= Enum.Material.Air and Root.Velocity.Y > -10 then LastSafeCFrame = Root.CFrame end
		local fpdh = workspace.FallenPartsDestroyHeight or -500
		if Root.Position.Y <= (fpdh + 25) or Root.Position.Y <= -250 then
			Root.Velocity = Vector3.zero
			Root.RotVelocity = Vector3.zero
			Root.CFrame = LastSafeCFrame or CFrame.new(Root.Position.X, 100, Root.Position.Z)
			CustomNotify("Anti Void Saved You!", Color3.fromRGB(100, 255, 100))
		end
	end))
end

local function IsPartVisible(part)
    if not Settings.AimWallCheck then return true end
    local origin = Camera.CFrame.Position
    local dir = part.Position - origin
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {Player.Character, part.Parent}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    local result = workspace:Raycast(origin, dir, raycastParams)
    return result == nil
end

local function GetClosestPlayerToMouse()
    local Closest = nil
    local ShortestDistance = Settings.FOVRadius or 120
    local MousePos = UserInputService:GetMouseLocation()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player and p.Character then
            local targetPart = p.Character:FindFirstChild(Settings.AimPart or "Head")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if targetPart and hum and hum.Health > 0 and IsPartVisible(targetPart) then
                local ScreenPos, OnScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if OnScreen then
                    local Dist = (Vector2.new(ScreenPos.X, ScreenPos.Y) - MousePos).Magnitude
                    if Dist < ShortestDistance then
                        ShortestDistance = Dist
                        Closest = targetPart
                    end
                end
            end
        end
    end
    return Closest
end

CreateToggle("Aimbot (Right Click)", CombatPage, Settings.Aimbot, function(v) Settings.Aimbot = v end)
CreateToggleWithValue("Aim Smoothness", CombatPage, true, Settings.AimbotSmoothness, function(v) end, function(val) Settings.AimbotSmoothness = val end)
CreateDropdown("Aim Part", {"Head", "HumanoidRootPart", "Torso"}, CombatPage, Settings.AimPart, function(v) Settings.AimPart = v end)
CreateToggle("Aim Wall Check", CombatPage, Settings.AimWallCheck, function(v) Settings.AimWallCheck = v end)
CreateToggleWithValue("Show FOV Circle", CombatPage, Settings.ShowFOV, Settings.FOVRadius, function(v) Settings.ShowFOV = v end, function(val) Settings.FOVRadius = val end)
CreateToggle("Silent Aim", CombatPage, Settings.SilentAim, function(v) Settings.SilentAim = v end)
CreateToggle("Triggerbot", CombatPage, Settings.Triggerbot, function(v) Settings.Triggerbot = v end)
CreateToggleWithValue("Spinbot", CombatPage, Settings.Spinbot, Settings.SpinSpeed, function(v) Settings.Spinbot = v end, function(val) Settings.SpinSpeed = val end)
CreateToggleWithValue("Hitbox Expander", CombatPage, Settings.HitboxExpander, Settings.HitboxSize, function(v) 
    Settings.HitboxExpander = v 
    if not v then ResetHitboxes() end
end, function(val) Settings.HitboxSize = val end)
CreateToggleWithValue("Kill Aura", CombatPage, Settings.KillAura, Settings.KillAuraRange, function(v) Settings.KillAura = v end, function(val) Settings.KillAuraRange = val end)

CreateToggleWithValue("Speed", PlayerPage, Settings.Speed, Settings.SpeedValue, function(v) Settings.Speed = v end, function(val) Settings.SpeedValue = val end)
CreateToggleWithValue("Jump", PlayerPage, Settings.Jump, Settings.JumpValue, function(v) Settings.Jump = v end, function(val) Settings.JumpValue = val end)
CreateToggle("Air Walk (Platform)", PlayerPage, Settings.AirWalk, function(v) Settings.AirWalk = v UpdateAirWalk() end)
CreateToggleWithValue("Smooth Fly", PlayerPage, Settings.SmoothFly, Settings.FlySpeed, function(v) Settings.SmoothFly = v if v then Settings.NormalFly = false end end, function(val) Settings.FlySpeed = val end)
CreateToggleWithValue("Normal Fly", PlayerPage, Settings.NormalFly, Settings.FlySpeed, function(v) Settings.NormalFly = v if v then Settings.SmoothFly = false end end, function(val) Settings.FlySpeed = val end)
CreateToggle("Noclip", PlayerPage, Settings.Noclip, function(v) 
    Settings.Noclip = v 
    if not v then RestoreCollisions() end
end)
CreateToggle("Infinite Jump", PlayerPage, Settings.InfiniteJump, function(v) Settings.InfiniteJump = v end)
CreateToggle("Bhop (Auto Jump)", PlayerPage, Settings.Bhop, function(v) Settings.Bhop = v end)
CreateToggleWithValue("Car Speed", PlayerPage, Settings.CarSpeed, Settings.CarSpeedValue, function(v) Settings.CarSpeed = v end, function(val) Settings.CarSpeedValue = val end)
CreateToggleWithValue("Car Fly", PlayerPage, Settings.CarFly, Settings.CarFlySpeed, function(v) Settings.CarFly = v end, function(val) Settings.CarFlySpeed = val end)

CreateToggle("Chams (Wallhack)", VisualsPage, Settings.Chams, function(v) Settings.Chams = v end)
CreateToggle("Names / Display", VisualsPage, Settings.ESPNames, function(v) Settings.ESPNames = v end)
CreateToggle("Distance", VisualsPage, Settings.ESPDistance, function(v) Settings.ESPDistance = v end)
CreateToggle("2D Box ESP", VisualsPage, Settings.ESPBox, function(v) Settings.ESPBox = v end)
CreateToggle("Head Dot ESP", VisualsPage, Settings.ESPHeadDot, function(v) Settings.ESPHeadDot = v end)
CreateToggle("Tracers", VisualsPage, Settings.ESPTracers, function(v) Settings.ESPTracers = v end)
CreateDropdown("Tracer Mode", {"DOWN", "UP", "MOUSE"}, VisualsPage, Settings.TracerOrigin, function(v) Settings.TracerOrigin = v end)
CreateToggle("Custom Crosshair", VisualsPage, Settings.Crosshair, function(v) Settings.Crosshair = v end)
CreateInputWithButton("Mouse Icon (Decal ID)", VisualsPage, Settings.MouseIconID, "Set", function(text) 
    Settings.MouseIconID = text 
    Settings.CustomMouseIcon = (text ~= "")
    UpdateMouseIcon()
    AutoSaveConfiguration()
end)
CreateToggleWithValue("Camera FOV", VisualsPage, Settings.FOVEnabled, Settings.FOVValue, function(v) Settings.FOVEnabled = v end, function(val) Settings.FOVValue = val end)
CreateDropdown("Shift Lock Key", {"Shift", "Ctrl"}, VisualsPage, Settings.ShiftLockKey, function(v) Settings.ShiftLockKey = v end)
CreateToggle("Force Shift Lock", VisualsPage, Settings.ForceShiftLock, function(v) Settings.ForceShiftLock = v end)
CreateToggleWithValue("ESP Max Dist", VisualsPage, true, Settings.EspMaxDistance, function(v) end, function(val) Settings.EspMaxDistance = val end)
CreateDropdown("ESP Color", {"White", "Red", "Green", "Blue", "Yellow", "Cyan", "Magenta", "Orange", "Purple", "Lime", "Pink", "Gold"}, VisualsPage, Settings.EspColorName, function(v) 
    Settings.EspColorName = v 
    Settings.EspColor = ColorMap[v] or Color3.fromRGB(255, 255, 255) 
end)

local ESPDrawings = {}
local Highlights = {}

local function ClearESPForPlayer(p)
    if ESPDrawings[p] then
        for _, d in pairs(ESPDrawings[p]) do pcall(function() d:Remove() end) end
        ESPDrawings[p] = nil
    end
    if Highlights[p] then
        pcall(function() Highlights[p]:Destroy() end)
        Highlights[p] = nil
    end
end

CreateButton("Reload ESP", VisualsPage, function()
    for p, _ in pairs(ESPDrawings) do ClearESPForPlayer(p) end
    ESPDrawings = {}
    Highlights = {}
    CustomNotify("ESP Reloaded!", Color3.fromRGB(100, 255, 100))
end)

CreateInputWithButton("Fling", FlingPage, "", "Fling", function(text) ExecuteFling(text) end)
CreateInputWithTwoButtons("Teleport", FlingPage, "", "TP", "Loop TP", function(text, mode) ExecuteTeleport(text, mode) end)
CreateToggle("Ctrl Click TP", FlingPage, Settings.CtrlClickTP, function(v) Settings.CtrlClickTP = v end)
CreateToggle("No Fall Damage", FlingPage, Settings.NoFallDamage, function(v) Settings.NoFallDamage = v end)
CreateToggle("Anti Void", FlingPage, Settings.AntiVoid, function(v) Settings.AntiVoid = v if v then StartAntiVoid() end end)
CreateToggle("Anti Fling", FlingPage, Settings.AntiFling, function(v) Settings.AntiFling = v end)
CreateToggle("Fullbright", FlingPage, Settings.Fullbright, function(v) Settings.Fullbright = v UpdateFullbright() end)
CreateButton("Tox Music Player", FlingPage, function() MusicGui.Visible = not MusicGui.Visible end)
CreateButton("Tox Waypoints", FlingPage, function() WaypointsGui.Visible = not WaypointsGui.Visible end)

CreateButton("FE Emotes", ScriptsPage, function()
    loadstring(game:HttpGet(('https://raw.githubusercontent.com/VenezzaX/Usefulthings/refs/heads/main/FeEmotes.lua'),true))()
end)

CreateButton("PShade", ScriptsPage, function()
    loadstring(game:HttpGet('https://raw.githubusercontent.com/randomstring0/pshade-ultimate/refs/heads/main/src/cd.lua'))()
end)

CreateButton("Infinite Yield", ScriptsPage, function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
end)

CreateToggle("Anti AFK", ConfigPage, Settings.AntiAFK, function(v) Settings.AntiAFK = v end)
CreateToggle("Chat Logs", ConfigPage, Settings.ChatLogs, function(v) Settings.ChatLogs = v ChatLogGui.Visible = v end)
CreateToggle("3D Rendering", ConfigPage, Settings.Render3D, function(v) 
    Settings.Render3D = v 
    pcall(function() RunService:Set3dRenderingEnabled(v) end)
end)
CreateKeybindButton("GUI Keybind", ConfigPage, Settings.GUIKeybind, function(key) Settings.GUIKeybind = key end)
CreateConfirmButton("Server Hop", ConfigPage, function() ServerHop() end)
CreateConfirmButton("FPS Booster", ConfigPage, function() BoostFPS() end)
CreateConfirmButton("Rejoin Server", ConfigPage, function()
	if #Players:GetPlayers() <= 1 then TeleportService:Teleport(game.PlaceId, Player)
	else TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Player) end
end)

CreateConfirmButton("DESTROY", ConfigPage, function()
    Destroyed = true
    pcall(function() RunService:Set3dRenderingEnabled(true) end)
    
    Settings.Fullbright = false
    UpdateFullbright()
    
    Settings.AirWalk = false
    UpdateAirWalk()

    Settings.CustomMouseIcon = false
    UpdateMouseIcon()

    local Hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
    if Hum then
        Hum.WalkSpeed = 16
        Hum.JumpPower = 50
        Hum.PlatformStand = false
    end
    RestoreCollisions()
    ResetHitboxes()

    for _, hl in pairs(Highlights) do pcall(function() hl:Destroy() end) end
    Highlights = {}

    for _, esp in pairs(ESPDrawings) do
        for _, d in pairs(esp) do pcall(function() d:Remove() end) end
    end
    ESPDrawings = {}

    if FOVCircle then pcall(function() FOVCircle:Remove() end) end
    if CrosshairH then pcall(function() CrosshairH:Remove() end) end
    if CrosshairV then pcall(function() CrosshairV:Remove() end) end
    if getgenv().ActiveSound then getgenv().ActiveSound:Destroy() getgenv().ActiveSound = nil end

    for _, conn in ipairs(ScriptConnections) do pcall(function() conn:Disconnect() end) end

    pcall(function() NotifGui:Destroy() end)
    pcall(function() Gui:Destroy() end)
end)

local isShiftLockActive = false
AddConnection(UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and Settings.ForceShiftLock then
        local key = Settings.ShiftLockKey
        local match = false
        if key == "Shift" and (input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift) then
            match = true
        elseif key == "Ctrl" and (input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl) then
            match = true
        end
        if match then
            isShiftLockActive = not isShiftLockActive
            UserInputService.MouseBehavior = isShiftLockActive and Enum.MouseBehavior.LockCenter or Enum.MouseBehavior.Default
        end
    end
end))

AddConnection(UserInputService.JumpRequest:Connect(function()
    local Hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
    if ScriptLoaded and Settings.InfiniteJump and Hum and Hum.Health > 0 then
        Hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end))

AddConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and Settings.CtrlClickTP and input.UserInputType == Enum.UserInputType.MouseButton1 then
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then
            local mouse = Player:GetMouse()
            local Root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if mouse and mouse.Hit and Root then
                Root.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
            end
        end
    end
    if Settings.GUIKeybind and input.KeyCode == Settings.GUIKeybind then
        Main.Visible = not Main.Visible
    end
end))

AddConnection(Player.Idled:Connect(function()
    if ScriptLoaded and Settings.AntiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end))

AddConnection(RunService.Stepped:Connect(function()
    if Destroyed or not ScriptLoaded then return end

    if Settings.Noclip and Player.Character then
        for _, part in ipairs(Player.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end

    if Settings.AntiFling then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= Player and p.Character then
                for _, part in ipairs(p.Character:GetChildren()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end
    end

    local Root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if Settings.NoFallDamage and Root and Root.AssemblyLinearVelocity.Y < -40 then
        Root.AssemblyLinearVelocity = Vector3.new(Root.AssemblyLinearVelocity.X, -35, Root.AssemblyLinearVelocity.Z)
    end

    UpdateAirWalk()
    UpdateMouseIcon()
    if Settings.Fullbright then UpdateFullbright() end
end))

local FlyBV, FlyBG
local function DisableNormalFlyPhysics()
    local Hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
    if FlyBV then FlyBV:Destroy() FlyBV = nil end
    if FlyBG then FlyBG:Destroy() FlyBG = nil end
    if Hum then Hum.PlatformStand = false end
end

AddConnection(RunService.RenderStepped:Connect(function(delta)
	if Destroyed or not ScriptLoaded then return end

    local Hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
    local Root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")

    if Hum and Hum.Health > 0 then
        Hum.WalkSpeed = Settings.Speed and Settings.SpeedValue or 16
        Hum.UseJumpPower = true
        Hum.JumpPower = Settings.Jump and Settings.JumpValue or 50

        if Settings.Bhop and UserInputService:IsKeyDown(Enum.KeyCode.Space) and (Hum.FloorMaterial ~= Enum.Material.Air or Hum:GetState() == Enum.HumanoidStateType.Landed) then
            Hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end

    if Settings.FOVEnabled then Camera.FieldOfView = Settings.FOVValue or 70 end

    if Settings.ForceShiftLock then
        Player.DevEnableMouseLock = true
        if isShiftLockActive and Root then
            Camera.CFrame = Camera.CFrame * CFrame.new(1.7, 0.5, 0)
            Root.CFrame = CFrame.new(Root.Position, Root.Position + Vector3.new(Camera.CFrame.LookVector.X, 0, Camera.CFrame.LookVector.Z))
        end
    end

    if Settings.LoopTPTarget and Settings.LoopTPTarget.Character and Settings.LoopTPTarget.Character:FindFirstChild("HumanoidRootPart") and Root then
        Root.CFrame = Settings.LoopTPTarget.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -3)
    end

    local seat = Hum and Hum.SeatPart
    if seat then
        if Settings.CarSpeed then
            seat.AssemblyLinearVelocity = seat.CFrame.LookVector * (Settings.CarSpeedValue or 100)
        end
        if Settings.CarFly then
            local flySpeed = (Settings.CarFlySpeed or 80)
            local dir = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) or UserInputService:IsKeyDown(Enum.KeyCode.E) then dir = dir + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.Q) then dir = dir - Vector3.new(0, 1, 0) end
            
            seat.AssemblyLinearVelocity = dir * flySpeed
        end
    end

    if Settings.Spinbot and Root then
        Root.CFrame = Root.CFrame * CFrame.Angles(0, math.rad(Settings.SpinSpeed or 50), 0)
    end

    local actualFlySpeed = (Settings.FlySpeed or 10) * 10

    if Settings.SmoothFly and Root and Hum and Hum.Health > 0 then
        DisableNormalFlyPhysics()
        Hum.PlatformStand = true
        Root.AssemblyLinearVelocity = Vector3.zero
        Root.AssemblyAngularVelocity = Vector3.zero

        local moveDir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) or UserInputService:IsKeyDown(Enum.KeyCode.E) then moveDir = moveDir + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.Q) then moveDir = moveDir - Vector3.new(0, 1, 0) end

        if moveDir.Magnitude > 0 then
            moveDir = moveDir.Unit
            Root.CFrame = Root.CFrame + (moveDir * (actualFlySpeed * delta))
        end
    elseif Settings.NormalFly and Root and Hum and Hum.Health > 0 then
        if not FlyBV or FlyBV.Parent ~= Root then
            DisableNormalFlyPhysics()
            FlyBV = Instance.new("BodyVelocity")
            FlyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            FlyBV.Velocity = Vector3.zero
            FlyBV.Parent = Root

            FlyBG = Instance.new("BodyGyro")
            FlyBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            FlyBG.CFrame = Root.CFrame
            FlyBG.Parent = Root
        end

        Hum.PlatformStand = true
        local dir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) or UserInputService:IsKeyDown(Enum.KeyCode.E) then dir = dir + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.Q) then dir = dir - Vector3.new(0, 1, 0) end

        FlyBV.Velocity = dir * actualFlySpeed
        FlyBG.CFrame = Camera.CFrame
    else
        DisableNormalFlyPhysics()
    end

    if FOVCircle then
        FOVCircle.Visible = Settings.Aimbot and Settings.ShowFOV
        FOVCircle.Radius = Settings.FOVRadius or 120
        FOVCircle.Position = UserInputService:GetMouseLocation()
    end

    if CrosshairH and CrosshairV then
        CrosshairH.Visible = Settings.Crosshair
        CrosshairV.Visible = Settings.Crosshair
        if Settings.Crosshair then
            local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            CrosshairH.From = Vector2.new(center.X - 10, center.Y)
            CrosshairH.To = Vector2.new(center.X + 10, center.Y)
            CrosshairV.From = Vector2.new(center.X, center.Y - 10)
            CrosshairV.To = Vector2.new(center.X, center.Y + 10)
        end
    end

    if Settings.Aimbot and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local Target = GetClosestPlayerToMouse()
        if Target then
            local Smooth = Settings.AimbotSmoothness or 2
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, Target.Position), 1 / Smooth)
        end
    end

    if Settings.Triggerbot then
        local mousePos = UserInputService:GetMouseLocation()
        local ray = Camera:ViewportPointToRay(mousePos.X, mousePos.Y)
        local result = workspace:Raycast(ray.Origin, ray.Direction * 1000)
        if result and result.Instance then
            local targetModel = result.Instance:FindFirstAncestorOfClass("Model")
            local targetPlayer = targetModel and Players:GetPlayerFromCharacter(targetModel)
            if targetPlayer and targetPlayer ~= Player then
                local tool = Player.Character and Player.Character:FindFirstChildOfClass("Tool")
                if tool then tool:Activate() end
            end
        end
    end

    for p, _ in pairs(ESPDrawings) do
        if not p or not p.Parent or not Players:FindFirstChild(p.Name) then
            ClearESPForPlayer(p)
        end
    end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player then
            if p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChildOfClass("Humanoid") then
                local char = p.Character
                local hrp = char.HumanoidRootPart
                local hum = char:FindFirstChildOfClass("Humanoid")

                if Settings.Chams then
                    local hl = Highlights[p]
                    if not hl or hl.Parent ~= char then
                        if hl then hl:Destroy() end
                        hl = Instance.new("Highlight")
                        hl.Name = "ToxChams"
                        hl.Adornee = char
                        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        hl.Parent = char
                        Highlights[p] = hl
                    end
                    hl.FillColor = Settings.EspColor
                    hl.OutlineColor = Settings.EspColor
                    hl.FillTransparency = 0.5
                else
                    if Highlights[p] then Highlights[p]:Destroy() Highlights[p] = nil end
                end

                local hasAnyESP = Settings.ESPNames or Settings.ESPDistance or Settings.ESPTracers or Settings.ESPBox or Settings.ESPHeadDot
                local distFromMe = Root and (Root.Position - hrp.Position).Magnitude or 0
                local withinDist = (Settings.EspMaxDistance <= 0) or (distFromMe <= Settings.EspMaxDistance)

                if hasAnyESP and Drawing and hum.Health > 0 and withinDist then
                    local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                    if not ESPDrawings[p] then
                        ESPDrawings[p] = {
                            Text = Drawing.new("Text"),
                            Line = Drawing.new("Line"),
                            Box = Drawing.new("Square"),
                            HeadDot = Drawing.new("Circle")
                        }
                    end

                    local textDraw = ESPDrawings[p].Text
                    local lineDraw = ESPDrawings[p].Line
                    local boxDraw = ESPDrawings[p].Box
                    local headDraw = ESPDrawings[p].HeadDot

                    if onScreen then
                        local textStr = ""
                        if Settings.ESPNames then textStr = textStr .. p.DisplayName .. " (@" .. p.Name .. ")\n" end
                        if Settings.ESPDistance then textStr = textStr .. "Dist: " .. math.floor(distFromMe) .. "m" end

                        textDraw.Text = textStr
                        textDraw.Font = Drawing.Fonts.Plex
                        textDraw.Size = 13
                        textDraw.Center = true
                        textDraw.Outline = true
                        textDraw.OutlineColor = Color3.fromRGB(0, 0, 0)
                        textDraw.Color = Settings.EspColor
                        textDraw.Position = Vector2.new(pos.X, pos.Y - 38)
                        textDraw.Visible = (textStr ~= "")

                        if Settings.ESPTracers then
                            local startVector = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                            if Settings.TracerOrigin == "UP" then
                                startVector = Vector2.new(Camera.ViewportSize.X / 2, 0)
                            elseif Settings.TracerOrigin == "MOUSE" then
                                startVector = UserInputService:GetMouseLocation()
                            end

                            lineDraw.From = startVector
                            lineDraw.To = Vector2.new(pos.X, pos.Y)
                            lineDraw.Color = Settings.EspColor
                            lineDraw.Thickness = 1
                            lineDraw.Visible = true
                        else
                            lineDraw.Visible = false
                        end

                        if Settings.ESPBox then
                            local boxHeight = math.clamp(1000 / pos.Z, 10, 300)
                            local boxWidth = boxHeight * 0.65
                            boxDraw.Size = Vector2.new(boxWidth, boxHeight)
                            boxDraw.Position = Vector2.new(pos.X - boxWidth / 2, pos.Y - boxHeight / 2)
                            boxDraw.Color = Settings.EspColor
                            boxDraw.Thickness = 1.5
                            boxDraw.Filled = false
                            boxDraw.Visible = true
                        else
                            boxDraw.Visible = false
                        end

                        local head = char:FindFirstChild("Head")
                        if Settings.ESPHeadDot and head then
                            local headPos, headOnScreen = Camera:WorldToViewportPoint(head.Position)
                            if headOnScreen then
                                headDraw.Position = Vector2.new(headPos.X, headPos.Y)
                                headDraw.Radius = math.clamp(300 / pos.Z, 2, 10)
                                headDraw.Color = Settings.EspColor
                                headDraw.Filled = true
                                headDraw.Visible = true
                            else
                                headDraw.Visible = false
                            end
                        else
                            headDraw.Visible = false
                        end
                    else
                        textDraw.Visible = false
                        lineDraw.Visible = false
                        boxDraw.Visible = false
                        headDraw.Visible = false
                    end
                else
                    ClearESPForPlayer(p)
                end
            else
                ClearESPForPlayer(p)
            end
        end
    end

    if Settings.HitboxExpander then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= Player and p.Character then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.Size = Vector3.new(Settings.HitboxSize or 10, Settings.HitboxSize or 10, Settings.HitboxSize or 10)
                    hrp.Transparency = 0.7
                    hrp.CanCollide = false
                end
            end
        end
    end

    if Settings.KillAura and Root then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= Player and p.Character then
                local tHrp = p.Character:FindFirstChild("HumanoidRootPart")
                local tHum = p.Character:FindFirstChildOfClass("Humanoid")
                if tHrp and tHum and tHum.Health > 0 then
                    if (Root.Position - tHrp.Position).Magnitude <= (Settings.KillAuraRange or 15) then
                        local tool = Player.Character and Player.Character:FindFirstChildOfClass("Tool")
                        if tool then tool:Activate() end
                    end
                end
            end
        end
    end
end))

local function ShowCenterLoadSequence()
    local blur = Instance.new("BlurEffect")
    blur.Size = 18
    blur.Parent = Lighting

    local SplashFrame = Instance.new("Frame")
    SplashFrame.Size = UDim2.new(0, 360, 0, 110)
    SplashFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    SplashFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    SplashFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 16)
    SplashFrame.BorderSizePixel = 0
    SplashFrame.ClipsDescendants = true
    SplashFrame.Parent = NotifGui

    local Corner = Instance.new("UICorner") Corner.CornerRadius = UDim.new(0, 10) Corner.Parent = SplashFrame
    local Stroke = Instance.new("UIStroke") Stroke.Color = MAIN_COLOR Stroke.Thickness = 2 Stroke.Parent = SplashFrame

    local SplashLogo = Instance.new("ImageLabel")
    SplashLogo.Size = UDim2.new(0, 48, 0, 48)
    SplashLogo.Position = UDim2.new(0, 18, 0, 16)
    SplashLogo.BackgroundTransparency = 1
    SplashLogo.Image = LOGO_ID
    SplashLogo.Parent = SplashFrame

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -85, 0, 24)
    TitleLabel.Position = UDim2.new(0, 78, 0, 16)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = "Tox Loading..."
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextSize = 15
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = SplashFrame

    local SubLabel = Instance.new("TextLabel")
    SubLabel.Size = UDim2.new(1, -85, 0, 20)
    SubLabel.Position = UDim2.new(0, 78, 0, 40)
    SubLabel.BackgroundTransparency = 1
    SubLabel.Text = "ToxHud v1 Utility Suite"
    SubLabel.TextColor3 = Color3.fromRGB(150, 150, 180)
    SubLabel.Font = Enum.Font.GothamMedium
    SubLabel.TextSize = 12
    SubLabel.TextXAlignment = Enum.TextXAlignment.Left
    SubLabel.Parent = SplashFrame

    local BarBackground = Instance.new("Frame")
    BarBackground.Size = UDim2.new(1, -36, 0, 8)
    BarBackground.Position = UDim2.new(0, 18, 1, -22)
    BarBackground.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
    BarBackground.BorderSizePixel = 0
    BarBackground.Parent = SplashFrame

    local BarCorner = Instance.new("UICorner") BarCorner.CornerRadius = UDim.new(0, 4) BarCorner.Parent = BarBackground
    local BarFill = Instance.new("Frame")
    BarFill.Size = UDim2.new(0, 0, 1, 0)
    BarFill.BackgroundColor3 = MAIN_COLOR
    BarFill.BorderSizePixel = 0
    BarFill.Parent = BarBackground
    local BarFillCorner = Instance.new("UICorner") BarFillCorner.CornerRadius = UDim.new(0, 4) BarFillCorner.Parent = BarFill

    local PercentLabel = Instance.new("TextLabel")
    PercentLabel.Size = UDim2.new(0, 40, 0, 18)
    PercentLabel.Position = UDim2.new(1, -58, 0, 16)
    PercentLabel.BackgroundTransparency = 1
    PercentLabel.Text = "0%"
    PercentLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    PercentLabel.Font = Enum.Font.GothamBold
    PercentLabel.TextSize = 12
    PercentLabel.TextXAlignment = Enum.TextXAlignment.Right
    PercentLabel.Parent = SplashFrame

    local duration = 5.0
    local steps = 50
    for i = 1, steps do
        local p = i / steps
        BarFill.Size = UDim2.new(p, 0, 1, 0)
        PercentLabel.Text = math.floor(p * 100) .. "%"
        if i == steps then TitleLabel.Text = "ToxHud Loaded Successfully" end
        task.wait(duration / steps)
    end

    ScriptLoaded = true
    if blur then blur:Destroy() end

    local fallTween = TweenService:Create(SplashFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
        Position = UDim2.new(0.5, 0, 1.3, 0),
        BackgroundTransparency = 1
    })
    fallTween:Play()
    fallTween.Completed:Connect(function()
        SplashFrame:Destroy()
        if not Destroyed then
            Main.Size = UDim2.new(0, 0, 0, 0)
            Main.Position = UDim2.new(0.5, 0, 0.5, 0)
            Main.Visible = true

            Main:TweenSizeAndPosition(
                UDim2.new(0, 330, 0, 395),
                UDim2.new(0.5, -165, 0.5, -197),
                Enum.EasingDirection.Out,
                Enum.EasingStyle.Back,
                0.5,
                true
            )
            CustomNotify("ToxHud v1 Loaded Successfully!", Color3.fromRGB(100, 255, 100))
        end
    end)
end

task.spawn(ShowCenterLoadSequence)

local SubGuisPreMinimizedState = {}
local Minimize = getgenv().Minimize
local Minimized = false

if Minimize then
    Minimize.MouseButton1Click:Connect(function()
        Minimized = not Minimized
        Main.Size = Minimized and UDim2.new(0, 330, 0, 38) or UDim2.new(0, 330, 0, 395)
        Tabs.Visible = not Minimized
        if getgenv().CurrentPage then getgenv().CurrentPage.Visible = not Minimized end
        Minimize.Text = Minimized and "+" or "-"

        if Minimized then
            SubGuisPreMinimizedState.ChatLog = ChatLogGui.Visible
            SubGuisPreMinimizedState.Music = MusicGui.Visible
            SubGuisPreMinimizedState.Waypoints = WaypointsGui.Visible
            ChatLogGui.Visible = false
            MusicGui.Visible = false
            WaypointsGui.Visible = false
        else
            if SubGuisPreMinimizedState.ChatLog ~= nil then ChatLogGui.Visible = SubGuisPreMinimizedState.ChatLog end
            if SubGuisPreMinimizedState.Music ~= nil then MusicGui.Visible = SubGuisPreMinimizedState.Music end
            if SubGuisPreMinimizedState.Waypoints ~= nil then WaypointsGui.Visible = SubGuisPreMinimizedState.Waypoints end
        end
    end)
end

if Settings.AntiVoid then StartAntiVoid() end
