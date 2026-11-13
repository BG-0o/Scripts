local env = getgenv()
if env.Destroyed or env.ToxUniversalLoaded then
    return
end
env.ToxUniversal = env.ToxUniversal or {}
local U = env.ToxUniversal
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Settings = env.Settings or {}
local NDSPlaceId = U.NDSPlaceId or 189707
local function ClearToxTable(t) if env.ClearToxTable then return env.ClearToxTable(t) end end
local function CustomNotify(...) if env.CustomNotify then return env.CustomNotify(...) end end
local function AutoSaveConfiguration(...) if env.AutoSaveConfiguration then return env.AutoSaveConfiguration(...) end end
local function AddConnection(...) if env.AddConnection then return env.AddConnection(...) end end
local GetHumanoidDefaults = U.GetHumanoidDefaults
local RestoreSpeed = U.RestoreSpeed
local CaptureNoclipDefaults = U.CaptureNoclipDefaults
local RestoreNoclipDefaults = U.RestoreNoclipDefaults
local RestoreAntiFlingDefaults = U.RestoreAntiFlingDefaults
do
local ToxActiveFlingTargets = getgenv().ToxActiveFlingTargets
if typeof(ToxActiveFlingTargets) ~= "table" then
    ToxActiveFlingTargets = setmetatable({}, {__mode = "k"})
    getgenv().ToxActiveFlingTargets = ToxActiveFlingTargets
end
local function GetToxFlingBlockReason(targetPlayer)
    if not targetPlayer
    or not targetPlayer.Parent
    or not targetPlayer.Character then
        return "unavailable"
    end
    local character = targetPlayer.Character
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
        or humanoid and humanoid.RootPart
    if not humanoid
    or humanoid.Health <= 0
    or not root then
        return "dead"
    end
    local activeUntil = ToxActiveFlingTargets[targetPlayer]
    if typeof(activeUntil) == "number"
    and activeUntil > tick() then
        return "busy"
    end
    local velocity = root.AssemblyLinearVelocity.Magnitude
    local angular = root.AssemblyAngularVelocity.Magnitude
    local state = humanoid:GetState()
    if humanoid.Sit
    or humanoid.PlatformStand
    or state == Enum.HumanoidStateType.Ragdoll
    or state == Enum.HumanoidStateType.FallingDown
    or state == Enum.HumanoidStateType.Physics
    or state == Enum.HumanoidStateType.Seated then
        return "unstable"
    end
    if velocity > 95
    or angular > 85 then
        return "moving"
    end
    return nil
end
local function CanStartToxFlingTarget(targetPlayer)
    local reason = GetToxFlingBlockReason(targetPlayer)
    return reason == nil, reason
end
getgenv().ToxCanFlingTarget = CanStartToxFlingTarget
local function SkidFling(TargetPlayer)
    local canFling, blockReason = CanStartToxFlingTarget(TargetPlayer)
    if not canFling then
        return false, blockReason
    end
    if not TargetPlayer or not TargetPlayer.Character then return false end
    local Character = Player.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local RootPart = Humanoid and Humanoid.RootPart
    local TCharacter = TargetPlayer.Character
    local THumanoid = TCharacter and TCharacter:FindFirstChildOfClass("Humanoid")
    local TRootPart = THumanoid and THumanoid.RootPart
    local THead = TCharacter and TCharacter:FindFirstChild("Head")
    local Accessory = TCharacter and TCharacter:FindFirstChildOfClass("Accessory")
    local Handle = Accessory and Accessory:FindFirstChild("Handle")
    if not (Character and Humanoid and RootPart and TCharacter) then return false end
    if THumanoid and THumanoid.Sit then return false end
    -- One fling at a time: overlapping flings overwrite the return position and the saved FPDH
    if getgenv().ToxFlingBusy and tick() < (tonumber(getgenv().ToxFlingBusyUntil) or 0) then
        return false, "busy"
    end
    getgenv().ToxFlingBusy = true
    getgenv().ToxFlingBusyUntil = tick() + 8
    local FlingStartCFrame = RootPart.CFrame
    getgenv().OldPos = FlingStartCFrame
    local oldCameraSubject = Camera.CameraSubject
    if THead then
        Camera.CameraSubject = THead
    elseif Handle then
        Camera.CameraSubject = Handle
    elseif THumanoid then
        Camera.CameraSubject = THumanoid
    end
    local targetBasePart = TRootPart or THead or Handle
    if not targetBasePart then
        Camera.CameraSubject = oldCameraSubject
        getgenv().ToxFlingBusy = false
        return false
    end
    ToxActiveFlingTargets[TargetPlayer] = tick() + 4
    do
        local currentFPDH = workspace.FallenPartsDestroyHeight
        -- Only remember a real value; a previous/overlapping fling may have left it as NaN
        if typeof(currentFPDH) == "number" and currentFPDH == currentFPDH then
            getgenv().FPDH = currentFPDH
        elseif typeof(getgenv().FPDH) ~= "number" or getgenv().FPDH ~= getgenv().FPDH then
            getgenv().FPDH = -500
        end
    end
    getgenv().ToxFlingBypassUntil =
        math.max(
            tonumber(
                getgenv().ToxFlingBypassUntil
            ) or 0,
            tick() + 4
        )
    local FPos = function(BasePart, Pos, Ang)
        if not RootPart or not BasePart or not BasePart.Parent then return end
        RootPart.CFrame = CFrame.new(BasePart.Position) * Pos * Ang
        pcall(function()
            Character:SetPrimaryPartCFrame(CFrame.new(BasePart.Position) * Pos * Ang)
        end)
        RootPart.AssemblyLinearVelocity = Vector3.new(200000, 200000, 200000)
        RootPart.AssemblyAngularVelocity = Vector3.new(999999, 999999, 999999)
        RootPart.Velocity = Vector3.new(9e7, 9e8, 9e7)
        RootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
    end
    local SFBasePart = function(BasePart)
        local TimeToWait = 2
        local Time = tick()
        local Angle = 0
        repeat
            if not RootPart or not THumanoid or Humanoid.Health <= 0 then break end
            if BasePart.Velocity.Magnitude < 50 then
                Angle = Angle + 100
                FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(2.25, 1.5, -2.25) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(-2.25, -1.5, 2.25) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle), 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle), 0, 0))
                task.wait()
            else
                FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, -1.5, -THumanoid.WalkSpeed), CFrame.Angles(0, 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                task.wait()
                local targetVelocity = TRootPart and TRootPart.Velocity.Magnitude / 1.25 or 0
                FPos(BasePart, CFrame.new(0, 1.5, targetVelocity), CFrame.Angles(math.rad(90), 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, -1.5, -targetVelocity), CFrame.Angles(0, 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, 1.5, targetVelocity), CFrame.Angles(math.rad(90), 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(-90), 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                task.wait()
            end
        until BasePart.Velocity.Magnitude > 500
            or BasePart.Parent ~= TargetPlayer.Character
            or TargetPlayer.Parent ~= Players
            or THumanoid.Sit
            or Humanoid.Health <= 0
            or tick() > Time + TimeToWait
    end
    pcall(function()
        workspace.FallenPartsDestroyHeight = 0/0
    end)
    local BV = Instance.new("BodyVelocity")
    BV.Name = "EpixVel"
    BV.Parent = RootPart
    BV.Velocity = Vector3.new(9e8, 9e8, 9e8)
    BV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    local BAV = Instance.new("BodyAngularVelocity")
    BAV.Name = "ToxFlingSpin"
    BAV.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    BAV.AngularVelocity = Vector3.new(0, 999999, 0)
    BAV.P = 1e9
    BAV.Parent = RootPart
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)

    -- Protected: if anything errors mid-fling we must still remove the 9e8 BodyVelocity,
    -- restore FallenPartsDestroyHeight and bring the player back. Otherwise the player
    -- gets launched into the void and never dies (FPDH stays NaN) -> "stuck in the middle of nothing".
    local flingOk, flingErr = pcall(function()
        if TRootPart and THead then
            if (TRootPart.Position - THead.Position).Magnitude > 5 then
                SFBasePart(THead)
            else
                SFBasePart(TRootPart)
            end
        elseif TRootPart then
            SFBasePart(TRootPart)
        elseif THead then
            SFBasePart(THead)
        elseif Handle then
            SFBasePart(Handle)
        end
    end)
    if not flingOk then
        warn("[ToxHub] Fling error (recovered): " .. tostring(flingErr))
    end

    pcall(function() if BAV and BAV.Parent then BAV:Destroy() end end)
    pcall(function() if BV and BV.Parent then BV:Destroy() end end)
    pcall(function() Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true) end)
    pcall(function() Camera.CameraSubject = Humanoid end)

    local OldPos = FlingStartCFrame
    local returnDeadline = tick() + 2.5
    repeat
        -- Stop if we died / respawned: the new character spawns normally
        if Player.Character ~= Character or not RootPart.Parent or Humanoid.Health <= 0 then
            break
        end
        RootPart.CFrame = OldPos * CFrame.new(0, 0.5, 0)
        pcall(function()
            Character:SetPrimaryPartCFrame(OldPos * CFrame.new(0, 0.5, 0))
        end)
        pcall(function() Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end)
        for _, x in ipairs(Character:GetChildren()) do
            if x:IsA("BasePart") then
                x.AssemblyLinearVelocity = Vector3.zero
                x.AssemblyAngularVelocity = Vector3.zero
            end
        end
        task.wait()
    until (RootPart.Position - OldPos.Position).Magnitude < 25 or tick() > returnDeadline

    pcall(function()
        local saved = getgenv().FPDH
        if typeof(saved) ~= "number" or saved ~= saved then saved = -500 end
        workspace.FallenPartsDestroyHeight = saved
    end)
    getgenv().ToxFlingBypassUntil =
        math.max(
            tonumber(
                getgenv().ToxFlingBypassUntil
            ) or 0,
            tick() + 0.25
        )
    if getgenv().SetNDSNoTPAnchor then
        pcall(function()
            getgenv().SetNDSNoTPAnchor(
                OldPos,
                true
            )
        end)
    end
    ToxActiveFlingTargets[TargetPlayer] = nil
    getgenv().ToxFlingBusy = false
    return true
end
getgenv().ToxFlingBypassUntil =
    tonumber(
        getgenv().ToxFlingBypassUntil
    ) or 0
getgenv().ToxFlingPlayer = SkidFling
local LastTeleportReturnCFrame =
    typeof(getgenv().ToxLastTeleportReturnCFrame) == "CFrame"
    and getgenv().ToxLastTeleportReturnCFrame
    or nil
local function GetLocalRoot()
    return Player.Character
        and Player.Character:FindFirstChild("HumanoidRootPart")
end
local function RecordTeleportReturn()
    local root = GetLocalRoot()
    if root then
        LastTeleportReturnCFrame = root.CFrame
        getgenv().ToxLastTeleportReturnCFrame = root.CFrame
        return true
    end
    return false
end
getgenv().RecordToxTeleportReturn = RecordTeleportReturn
local function ResolveSafeGroundCFrame(cframe)
    if typeof(cframe) ~= "CFrame" then
        return nil
    end
    local origin =
        cframe.Position
        + Vector3.new(0, 95, 0)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local excluded = {}
    if Player.Character then
        table.insert(excluded, Player.Character)
    end
    if getgenv().Gui then
        table.insert(excluded, getgenv().Gui)
    end
    params.FilterDescendantsInstances = excluded
    local result = workspace:Raycast(
        origin,
        Vector3.new(0, -220, 0),
        params
    )
    if result
    and result.Instance
    and result.Instance.CanCollide then
        local _, y, _ = cframe:ToOrientation()
        return CFrame.new(
            result.Position + Vector3.new(0, 4, 0)
        ) * CFrame.Angles(0, y, 0)
    end
    return cframe
end
getgenv().ToxSafeTeleportToCFrame = function(cframe, useGround, reason)
    local root = GetLocalRoot()
    local humanoid = Player.Character
        and Player.Character:FindFirstChildOfClass("Humanoid")
    if typeof(cframe) ~= "CFrame"
    or not root
    or not humanoid
    or humanoid.Health <= 0 then
        return false
    end
    RecordTeleportReturn()
    if getgenv().AllowToxTeleport then
        getgenv().AllowToxTeleport(1.5, reason or "ToxHub")
    end
    local targetCFrame = useGround and ResolveSafeGroundCFrame(cframe) or cframe
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    if Player.Character then
        Player.Character:PivotTo(targetCFrame)
    else
        root.CFrame = targetCFrame
    end
    if getgenv().SetNDSNoTPAnchor then
        pcall(function()
            getgenv().SetNDSNoTPAnchor(root.CFrame, true)
        end)
    end
    return true
end
getgenv().ToxReturnToLastTeleport = nil
local function ExecuteFling(TargetInput)
    if not TargetInput or TargetInput == "" then
        return CustomNotify("Enter username or 'all'", Color3.fromRGB(255, 100, 100))
    end
    if game.PlaceId == 189707
    and Settings.NDSNoTP
    and getgenv().SetNDSNoTP then
        pcall(function()
            getgenv().SetNDSNoTP(
                false,
                true
            )
        end)
        if getgenv().AutoSaveConfiguration then
            pcall(
                getgenv().AutoSaveConfiguration
            )
        end
    end
    local LowerInput = string.lower(TargetInput)
    if LowerInput == "all" or LowerInput == "others" then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= Player then
                local canFling = CanStartToxFlingTarget(p)
                if canFling then
                    task.spawn(function()
                        SkidFling(p)
                    end)
                end
            end
        end
        return
    end
    local target = nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player and (string.find(string.lower(p.Name), LowerInput, 1, true) or string.find(string.lower(p.DisplayName), LowerInput, 1, true)) then
            target = p
            break
        end
    end
    if target then
        local canFling, blockReason = CanStartToxFlingTarget(target)
        if canFling then
            task.spawn(function()
                SkidFling(target)
            end)
        else
            CustomNotify(
                "Fling skipped • " .. tostring(blockReason or "busy"),
                Color3.fromRGB(255, 180, 70)
            )
        end
    else
        CustomNotify("Player not found!", Color3.fromRGB(255, 100, 100))
    end
end
getgenv().ToxExecuteFling = ExecuteFling
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
            if Root then
                if getgenv().ToxSafeTeleportToCFrame then
                    getgenv().ToxSafeTeleportToCFrame(
                        tHrp.CFrame * CFrame.new(0, 0, -3),
                        false,
                        "Player TP"
                    )
                else
                    if getgenv().RecordToxTeleportReturn then
                        getgenv().RecordToxTeleportReturn()
                    end
                    if getgenv().AllowToxTeleport then
                        getgenv().AllowToxTeleport(1.25, "Player TP")
                    end
                    Root.CFrame = tHrp.CFrame * CFrame.new(0, 0, -3)
                end
            end
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
    U.SkidFling = SkidFling
    U.ExecuteFling = ExecuteFling
    U.ExecuteTeleport = ExecuteTeleport
end
do
local Render3DColorMap = {
    WHITE =
        Color3.fromRGB(
            190,
            190,
            200
        ),
    BLACK =
        Color3.fromRGB(
            5,
            5,
            8
        ),
    RED =
        Color3.fromRGB(
            95,
            8,
            12
        ),
    BLUE =
        Color3.fromRGB(
            9,
            0,
            110
        )
}
Settings.Render3DColor =
    string.upper(
        tostring(
            Settings.Render3DColor
            or "BLACK"
        )
    )
if not Render3DColorMap[
    Settings.Render3DColor
] then
    Settings.Render3DColor =
        "BLACK"
end
local oldRenderBackdrop =
    getgenv().ToxRenderBackdropGui
if oldRenderBackdrop then
    pcall(function()
        oldRenderBackdrop:
            Destroy()
    end)
end
local RenderBackdropGui =
    Instance.new("ScreenGui")
RenderBackdropGui.Name =
    "ToxRenderBackdrop"
RenderBackdropGui.IgnoreGuiInset = true
RenderBackdropGui.ResetOnSpawn = false
RenderBackdropGui.DisplayOrder = -100
RenderBackdropGui.ZIndexBehavior =
    Enum.ZIndexBehavior.Sibling
RenderBackdropGui.Parent =
    (gethui and gethui())
    or CoreGui
local RenderBackdrop =
    Instance.new("Frame")
RenderBackdrop.Size =
    UDim2.new(
        1,
        0,
        1,
        0
    )
RenderBackdrop.Position =
    UDim2.new(
        0,
        0,
        0,
        0
    )
RenderBackdrop.BorderSizePixel = 0
RenderBackdrop.ZIndex = 1
RenderBackdrop.Visible = false
RenderBackdrop.BackgroundColor3 =
    Render3DColorMap[Settings.Render3DColor]
    or Render3DColorMap.BLACK
RenderBackdrop.Parent =
    RenderBackdropGui
getgenv().ToxRenderBackdropGui =
    RenderBackdropGui
local function RefreshRenderBackdrop()
    RenderBackdrop.BackgroundColor3 =
        Render3DColorMap[
            Settings.Render3DColor
        ]
        or Render3DColorMap.BLACK
    RenderBackdrop.Visible =
        Settings.Render3D == false
end
local function SetRender3DEnabled(
    enabled
)
    Settings.Render3D =
        enabled == true
    pcall(function()
        RunService:
            Set3dRenderingEnabled(
                Settings.Render3D
            )
    end)
    RefreshRenderBackdrop()
end
local function SetRender3DColor(
    colorName
)
    local normalized =
        string.upper(
            tostring(
                colorName
                or "BLACK"
            )
        )
    if not Render3DColorMap[
        normalized
    ] then
        return false
    end
    Settings.Render3DColor =
        normalized
    RefreshRenderBackdrop()
    return true
end
getgenv().ToxSetRender3DEnabled = SetRender3DEnabled
getgenv().ToxSetRender3DColor = SetRender3DColor
    U.RenderBackdropGui = RenderBackdropGui
    U.SetRender3DEnabled = SetRender3DEnabled
    U.SetRender3DColor = SetRender3DColor
end
do
local FPSObjectDefaults = {}
local FPSLightingDefaults = nil
local FPSWorkspaceConnection = nil
local FPSLightingConnection = nil
local FPSImportantNames = {
    GunDrop = true,
    Gun = true,
    Knife = true,
    Revolver = true,
    Handle = true,
    HumanoidRootPart = true
}
local function IsPlayerCharacterObject(object)
    for _, target in ipairs(Players:GetPlayers()) do
        local character = target.Character
        if character
        and object:IsDescendantOf(character) then
            return true
        end
    end
    return false
end
local function HasImportantFPSAncestor(object)
    local current = object
    while current do
        if current:IsA("Tool")
        or current:IsA("Backpack")
        or current:IsA("Humanoid")
        or current:IsA("Highlight")
        or current:IsA("BillboardGui")
        or current:IsA("ScreenGui")
        or FPSImportantNames[current.Name] then
            return true
        end
        local lower = string.lower(tostring(current.Name or ""))
        if string.find(lower, "gundrop", 1, true)
        or string.find(lower, "weapon", 1, true)
        or string.find(lower, "knife", 1, true)
        or string.find(lower, "revolver", 1, true)
        or string.find(lower, "sheriff", 1, true)
        or string.find(lower, "murderer", 1, true)
        or string.find(lower, "tox", 1, true) then
            return true
        end
        current = current.Parent
    end
    return false
end
local function ShouldIgnoreFPSObject(object)
    if not object
    or not object.Parent then
        return true
    end
    if object == Camera
    or object:IsDescendantOf(CoreGui) then
        return true
    end
    if getgenv().Gui
    and object:IsDescendantOf(getgenv().Gui) then
        return true
    end
    if IsPlayerCharacterObject(object)
    or HasImportantFPSAncestor(object) then
        return true
    end
    return false
end
local function CaptureFPSObject(object)
    if ShouldIgnoreFPSObject(object)
    or FPSObjectDefaults[object] then
        return
    end
    local data = nil
    if object:IsA("BasePart") then
        data = {
            Kind = "BasePart",
            Material = object.Material,
            MaterialVariant = object.MaterialVariant,
            Reflectance = object.Reflectance,
            CastShadow = object.CastShadow,
            Color = object.Color,
            Transparency = object.Transparency,
            LocalTransparencyModifier = object.LocalTransparencyModifier
        }
    elseif object:IsA("Decal")
    or object:IsA("Texture") then
        data = {
            Kind = "Texture",
            Transparency = object.Transparency,
            Color3 = object.Color3,
            Texture = object.Texture
        }
    elseif object:IsA("ParticleEmitter") then
        data = {
            Kind = "ParticleEmitter",
            Enabled = object.Enabled,
            Rate = object.Rate
        }
    elseif object:IsA("Trail")
    or object:IsA("Beam") then
        data = {
            Kind = "Enabled",
            Enabled = object.Enabled
        }
    elseif object:IsA("Smoke")
    or object:IsA("Fire")
    or object:IsA("Sparkles") then
        data = {
            Kind = "Enabled",
            Enabled = object.Enabled
        }
    elseif object:IsA("BloomEffect")
    or object:IsA("BlurEffect")
    or object:IsA("ColorCorrectionEffect")
    or object:IsA("DepthOfFieldEffect")
    or object:IsA("SunRaysEffect") then
        data = {
            Kind = "Enabled",
            Enabled = object.Enabled
        }
    end
    if data then
        FPSObjectDefaults[object] = data
    end
end
local function ApplyFPSObject(object)
    if ShouldIgnoreFPSObject(object) then
        return
    end
    CaptureFPSObject(object)
    if object:IsA("BasePart") then
        object.Material = Enum.Material.SmoothPlastic
        object.MaterialVariant = ""
        object.Reflectance = 0
        object.CastShadow = false
    elseif object:IsA("Decal")
    or object:IsA("Texture") then
        object.Transparency = 1
    elseif object:IsA("ParticleEmitter") then
        object.Enabled = false
        object.Rate = 0
    elseif object:IsA("Trail")
    or object:IsA("Beam")
    or object:IsA("Smoke")
    or object:IsA("Fire")
    or object:IsA("Sparkles")
    or object:IsA("BloomEffect")
    or object:IsA("BlurEffect")
    or object:IsA("ColorCorrectionEffect")
    or object:IsA("DepthOfFieldEffect")
    or object:IsA("SunRaysEffect") then
        object.Enabled = false
    end
end
local function RestoreFPSObject(object, data)
    if not object
    or not object.Parent
    or typeof(data) ~= "table" then
        return
    end
    pcall(function()
        if data.Kind == "BasePart" then
            object.Material = data.Material
            object.MaterialVariant = data.MaterialVariant or ""
            object.Reflectance = data.Reflectance
            object.CastShadow = data.CastShadow
            object.Color = data.Color
            object.Transparency = data.Transparency
            object.LocalTransparencyModifier = data.LocalTransparencyModifier or 0
        elseif data.Kind == "Texture" then
            object.Transparency = data.Transparency
            object.Color3 = data.Color3
            object.Texture = data.Texture
        elseif data.Kind == "ParticleEmitter" then
            object.Enabled = data.Enabled
            object.Rate = data.Rate
        elseif data.Kind == "Enabled" then
            object.Enabled = data.Enabled
        end
    end)
end
local function CaptureFPSLighting()
    if FPSLightingDefaults then
        return
    end
    FPSLightingDefaults = {
        GlobalShadows = Lighting.GlobalShadows,
        FogEnd = Lighting.FogEnd,
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        Brightness = Lighting.Brightness,
        ExposureCompensation = Lighting.ExposureCompensation,
        EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
        EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale
    }
end
local function RestoreFPSLighting()
    if not FPSLightingDefaults then
        return
    end
    pcall(function()
        Lighting.GlobalShadows = FPSLightingDefaults.GlobalShadows
        Lighting.FogEnd = FPSLightingDefaults.FogEnd
        Lighting.Ambient = FPSLightingDefaults.Ambient
        Lighting.OutdoorAmbient = FPSLightingDefaults.OutdoorAmbient
        Lighting.Brightness = FPSLightingDefaults.Brightness
        Lighting.ExposureCompensation = FPSLightingDefaults.ExposureCompensation
        Lighting.EnvironmentDiffuseScale = FPSLightingDefaults.EnvironmentDiffuseScale
        Lighting.EnvironmentSpecularScale = FPSLightingDefaults.EnvironmentSpecularScale
    end)
    FPSLightingDefaults = nil
end
local function SetFPSBooster(enabled, silent)
    enabled = enabled == true
    Settings.FPSBooster = enabled
    if enabled then
        CaptureFPSLighting()
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        for _, object in ipairs(workspace:GetDescendants()) do
            pcall(ApplyFPSObject, object)
        end
        for _, object in ipairs(Lighting:GetDescendants()) do
            pcall(ApplyFPSObject, object)
        end
        if FPSWorkspaceConnection then
            FPSWorkspaceConnection:Disconnect()
        end
        if FPSLightingConnection then
            FPSLightingConnection:Disconnect()
        end
        FPSWorkspaceConnection = workspace.DescendantAdded:Connect(function(object)
            if Settings.FPSBooster then
                task.defer(function()
                    pcall(ApplyFPSObject, object)
                end)
            end
        end)
        FPSLightingConnection = Lighting.DescendantAdded:Connect(function(object)
            if Settings.FPSBooster then
                task.defer(function()
                    pcall(ApplyFPSObject, object)
                end)
            end
        end)
        if not silent then
            CustomNotify(
                "FPS Booster Enabled",
                Color3.fromRGB(100, 255, 100)
            )
        end
    else
        if FPSWorkspaceConnection then
            FPSWorkspaceConnection:Disconnect()
            FPSWorkspaceConnection = nil
        end
        if FPSLightingConnection then
            FPSLightingConnection:Disconnect()
            FPSLightingConnection = nil
        end
        RestoreFPSLighting()
        for object, data in pairs(FPSObjectDefaults) do
            RestoreFPSObject(object, data)
            FPSObjectDefaults[object] = nil
        end
        ClearToxTable(FPSObjectDefaults)
        if not silent then
            CustomNotify(
                "FPS Booster Restored",
                Color3.fromRGB(255, 180, 70)
            )
        end
    end
    return true
end
    U.SetFPSBooster = SetFPSBooster
end
do
local LastSafeCFrame = nil
local AntiVoidConnection = nil
local AntiVoidCharacterConnection = nil
local AntiVoidLastSave = 0
local AntiVoidLastRescue = 0
local function GetVoidThreshold()
    local fallen =
        tonumber(
            workspace.FallenPartsDestroyHeight
        ) or -500
    return math.max(
        fallen + 35,
        -250
    )
end
local function IsUsableSafeCFrame(cframe)
    if typeof(cframe) ~= "CFrame" then
        return false
    end
    return cframe.Position.Y
        > GetVoidThreshold() + 20
end
local function GetSpawnFallbackCFrame(root)
    local ndsSafe =
        getgenv().NDSSafeSpawnCFrame
    if game.PlaceId == 189707
    and IsUsableSafeCFrame(ndsSafe) then
        return ndsSafe
    end
    local spawn =
        workspace:
            FindFirstChildWhichIsA(
                "SpawnLocation",
                true
            )
    if spawn then
        return spawn.CFrame
            + Vector3.new(0, 4, 0)
    end
    if root then
        local origin =
            Vector3.new(
                root.Position.X,
                math.max(
                    root.Position.Y + 500,
                    500
                ),
                root.Position.Z
            )
        local result =
            workspace:Raycast(
                origin,
                Vector3.new(0, -2000, 0)
            )
        if result then
            return CFrame.new(
                result.Position
                + Vector3.new(0, 5, 0)
            )
        end
    end
    return nil
end
local function SetLastSafeCFrame(cframe)
    if IsUsableSafeCFrame(cframe) then
        LastSafeCFrame = cframe
        getgenv().ToxLastSafeCFrame =
            cframe
    end
end
getgenv().SetToxLastSafeCFrame =
    SetLastSafeCFrame
local function RescueFromVoid(
    character,
    humanoid,
    root
)
    if not character
    or not character.Parent
    or not humanoid
    or humanoid.Health <= 0
    or not root
    or not root.Parent then
        return false
    end
    if tick() - AntiVoidLastRescue < 0.8 then
        return false
    end
    AntiVoidLastRescue = tick()
    local safe =
        IsUsableSafeCFrame(LastSafeCFrame)
        and LastSafeCFrame
        or GetSpawnFallbackCFrame(root)
    if not safe then
        return false
    end
    local allow =
        getgenv().AllowToxTeleport
    if allow then
        allow(1.5, "Anti Void Restore")
    end
    if getgenv().SetNDSNoTPAnchor then
        pcall(function()
            getgenv().SetNDSNoTPAnchor(
                safe,
                true
            )
        end)
    end
    humanoid.Sit = false
    humanoid.PlatformStand = false
    root.AssemblyLinearVelocity =
        Vector3.zero
    root.AssemblyAngularVelocity =
        Vector3.zero
    root.CFrame = safe
    pcall(function()
        humanoid:ChangeState(
            Enum.HumanoidStateType.GettingUp
        )
    end)
    SetLastSafeCFrame(safe)
    return true
end
local function StopAntiVoid()
    if AntiVoidConnection then
        AntiVoidConnection:Disconnect()
        AntiVoidConnection = nil
    end
    if AntiVoidCharacterConnection then
        AntiVoidCharacterConnection:
            Disconnect()
        AntiVoidCharacterConnection = nil
    end
end
local function StartAntiVoid()
    StopAntiVoid()
    AntiVoidCharacterConnection =
        AddConnection(
            Player.CharacterAdded:
                Connect(function(character)
                    task.spawn(function()
                        local root =
                            character:
                                WaitForChild(
                                    "HumanoidRootPart",
                                    8
                                )
                        local humanoid =
                            character:
                                FindFirstChildOfClass(
                                    "Humanoid"
                                )
                        if not root
                        or not humanoid then
                            return
                        end
                        task.wait(0.45)
                        if not Settings.AntiVoid
                        or env.Destroyed then
                            return
                        end
                        if root.Position.Y
                        <= GetVoidThreshold() then
                            RescueFromVoid(
                                character,
                                humanoid,
                                root
                            )
                        end
                    end)
                end)
        )
    AntiVoidConnection =
        AddConnection(
            RunService.Heartbeat:
                Connect(function()
                    if env.Destroyed
                    or not env.ScriptLoaded
                    or not Settings.AntiVoid then
                        return
                    end
                    local character =
                        Player.Character
                    local root =
                        character
                        and character:
                            FindFirstChild(
                                "HumanoidRootPart"
                            )
                    local humanoid =
                        character
                        and character:
                            FindFirstChildOfClass(
                                "Humanoid"
                            )
                    if not root
                    or not humanoid
                    or humanoid.Health <= 0 then
                        return
                    end
                    local threshold =
                        GetVoidThreshold()
                    if humanoid.FloorMaterial
                    ~= Enum.Material.Air
                    and root.Position.Y
                        > threshold + 20
                    and root.AssemblyLinearVelocity.Y
                        > -25
                    and tick() - AntiVoidLastSave
                        >= 0.15 then
                        AntiVoidLastSave = tick()
                        SetLastSafeCFrame(
                            root.CFrame
                        )
                    end
                    if root.Position.Y
                    <= threshold then
                        RescueFromVoid(
                            character,
                            humanoid,
                            root
                        )
                    end
                end)
        )
end
    U.StartAntiVoid = StartAntiVoid
    U.StopAntiVoid = StopAntiVoid
end
do
-- No Fall Damage strength: Settings.NoFallSpeed 0-100%  ->  max fall speed 15..100 studs/s
-- (0% = floats down very slowly, 100% = almost a normal fall)
local function GetNoFallMaxSpeed()
    local pct = math.clamp(tonumber(Settings.NoFallSpeed) or 50, 0, 100)
    return 15 + pct * 0.85
end
getgenv().ToxGetNoFallMaxSpeed = GetNoFallMaxSpeed
local WalkFlingGeneration = 0
local WalkFlingImpulseActive = false
local WalkFlingRunning = false
getgenv().ToxWalkFlingImpulseActive = false

local function SetWalkFlingImpulse(active)
    WalkFlingImpulseActive = active
    getgenv().ToxWalkFlingImpulseActive = active
end

-- Our own "walking" velocity, clamped. Touching a flung player gives us a huge collision
-- impulse; if we reused that raw value every frame we would launch ourselves and die
-- from fall damage (this is what was killing in NDS).
local function GetSafeWalkVelocity(root, humanoid)
    local vel = root.AssemblyLinearVelocity
    if vel.X ~= vel.X or vel.Y ~= vel.Y or vel.Z ~= vel.Z then
        return Vector3.zero
    end
    local maxHorizontal = math.max(tonumber(humanoid.WalkSpeed) or 16, 16) * 1.5
    local horizontal = Vector3.new(vel.X, 0, vel.Z)
    if horizontal.Magnitude > maxHorizontal then
        horizontal = horizontal.Unit * maxHorizontal
    end
    local y = vel.Y
    local maxFall = GetNoFallMaxSpeed()
    if y < -maxFall then
        y = -maxFall       -- anti fall damage (strength from No Fall Damage %)
    elseif y > 60 then
        y = 60             -- normal jump still works, no self-launch
    end
    return Vector3.new(horizontal.X, y, horizontal.Z)
end

local function SetWalkFlingStates(humanoid, enabled)
    pcall(function()
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, enabled)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, enabled)
    end)
end

local function SettleCharacterAfterWalkFling()
    local character = Player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if root and humanoid then
        pcall(function()
            root.AssemblyLinearVelocity = GetSafeWalkVelocity(root, humanoid)
            root.AssemblyAngularVelocity = Vector3.zero
        end)
        SetWalkFlingStates(humanoid, true)
    end
end

-- ==========================================================================
-- External teleport guard: when the GAME teleports us (round start, spawn...),
-- the server moves a part we own while we are pushing fling velocity / falling,
-- which can kill instantly. Detect jumps we didn't cause and stabilize for a moment.
-- ==========================================================================
local EXTERNAL_TP_DISTANCE = 30     -- studs in a single frame
local EXTERNAL_TP_GUARD_TIME = 2.0  -- seconds of protection after a game teleport
local GuardLastRoot = nil
local GuardLastPos = nil
getgenv().ToxExternalTeleportUntil = 0

local function IsOwnTeleportActive()
    if getgenv().ToxIsToxTeleportAllowed and getgenv().ToxIsToxTeleportAllowed() then
        return true
    end
    if tick() < (tonumber(getgenv().ToxFlingBypassUntil) or 0) then
        return true
    end
    if getgenv().ToxFlingBusy and tick() < (tonumber(getgenv().ToxFlingBusyUntil) or 0) then
        return true
    end
    return false
end

local function CheckExternalTeleport(root)
    local pos = root.Position
    if GuardLastRoot ~= root or not GuardLastPos then
        GuardLastRoot = root
        GuardLastPos = pos
        return false
    end
    local jumped = (pos - GuardLastPos).Magnitude > EXTERNAL_TP_DISTANCE
    GuardLastPos = pos
    if jumped and not IsOwnTeleportActive() then
        getgenv().ToxExternalTeleportUntil = tick() + EXTERNAL_TP_GUARD_TIME
        return true
    end
    return false
end

local function IsExternalTeleportGuardActive()
    return tick() < (tonumber(getgenv().ToxExternalTeleportUntil) or 0)
end
getgenv().ToxIsExternalTeleportGuardActive = IsExternalTeleportGuardActive

AddConnection(RunService.Heartbeat:Connect(function()
    if env.Destroyed then return end
    local character = Player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root or not humanoid or humanoid.Health <= 0 then
        return
    end

    local justTeleported = CheckExternalTeleport(root)

    if justTeleported or IsExternalTeleportGuardActive() then
        -- Land softly: no leftover fling / fall velocity, no spin, no ragdoll
        pcall(function()
            root.AssemblyLinearVelocity = GetSafeWalkVelocity(root, humanoid)
            root.AssemblyAngularVelocity = Vector3.zero
        end)
        SetWalkFlingStates(humanoid, false)
        if justTeleported then
            pcall(function()
                root.AssemblyLinearVelocity = Vector3.zero
                humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            end)
            if getgenv().SetNDSNoTPAnchor then
                -- Accept the game's teleport as the new anchor instead of fighting it
                pcall(getgenv().SetNDSNoTPAnchor, root.CFrame, true)
            end
        end
    elseif not WalkFlingRunning then
        -- Guard just ended and walkfling is off: give normal states back
        if humanoid:GetStateEnabled(Enum.HumanoidStateType.FallingDown) == false then
            SetWalkFlingStates(humanoid, true)
        end
    end
end))

-- Immediate stop (script unload / restart). Normal disabling uses the ramp in SetWalkFling.
local function StopWalkFling()
    WalkFlingGeneration = WalkFlingGeneration + 1
    WalkFlingRunning = false
    SetWalkFlingImpulse(false)
    SettleCharacterAfterWalkFling()
end

local function StartWalkFling()
    if not Settings.WalkFling or env.Destroyed then
        return
    end

    if WalkFlingRunning then
        return
    end

    WalkFlingGeneration = WalkFlingGeneration + 1
    local generation = WalkFlingGeneration
    WalkFlingRunning = true

    task.spawn(function()
        local movel = 0.1
        local statesCharacter = nil

        while generation == WalkFlingGeneration
        and not env.Destroyed
        and env.ScriptLoaded do
            if not Settings.WalkFling then
                break
            end

            RunService.Heartbeat:Wait()
            if generation ~= WalkFlingGeneration then
                break
            end

            local character = Player.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            local root = character and character:FindFirstChild("HumanoidRootPart")

            if not character or not character.Parent or not humanoid or humanoid.Health <= 0 or not root or not root.Parent then
                SetWalkFlingImpulse(false)
                task.wait(0.1)
            else
                if statesCharacter ~= character then
                    statesCharacter = character
                    SetWalkFlingStates(humanoid, false)
                end

                -- Solid ground collision (never fall through floors / islands)
                local torso = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
                if torso and not Settings.Noclip then
                    torso.CanCollide = true
                end

                local normalVel = GetSafeWalkVelocity(root, humanoid)
                root.AssemblyAngularVelocity = Vector3.zero

                local power = math.clamp(tonumber(Settings.WalkFlingPower) or 30, 1, 100)

                -- Game just teleported us: no fling impulse until we've landed safely
                if CheckExternalTeleport(root) or IsExternalTeleportGuardActive() then
                    power = 0
                    normalVel = Vector3.zero
                end

                if power < 1 then
                    SetWalkFlingImpulse(false)
                    root.AssemblyLinearVelocity = normalVel
                else
                    SetWalkFlingImpulse(true)
                    local mult = power * 200

                    local moveDir = humanoid.MoveDirection
                    if moveDir.Magnitude < 0.1 then
                        moveDir = root.CFrame.LookVector
                    end

                    -- Classic walkfling cycle (same order as Infinite Yield):
                    --  Heartbeat (after physics): huge velocity -> replicates and flings whoever touches us
                    --  RenderStepped: back to our normal (clamped) velocity
                    --  Stepped (before physics): normal velocity + tiny jitter, so OUR physics never uses the huge value
                    -- Never apply the huge velocity on Stepped, or the local character gets launched.
                    root.AssemblyLinearVelocity = Vector3.new(moveDir.X * mult, mult * 0.75, moveDir.Z * mult)

                    RunService.RenderStepped:Wait()
                    if root.Parent then
                        root.AssemblyLinearVelocity = normalVel
                        root.AssemblyAngularVelocity = Vector3.zero
                    end

                    RunService.Stepped:Wait()
                    if root.Parent then
                        root.AssemblyLinearVelocity = normalVel + Vector3.new(0, movel, 0)
                        root.AssemblyAngularVelocity = Vector3.zero
                        movel = -movel
                    end
                end
            end
        end

        if generation == WalkFlingGeneration then
            WalkFlingRunning = false
        end
        SetWalkFlingImpulse(false)

        if not WalkFlingRunning then
            SettleCharacterAfterWalkFling()
        end
    end)
end
getgenv().SetWalkFling = function(
    Value,
    Silent
)
    local enabled = Value == true
    Settings.WalkFling = enabled
    if enabled then
        StartWalkFling()
    else
        StopWalkFling()
    end
    if getgenv().SyncToggleVisuals then
        getgenv().SyncToggleVisuals(
            "WalkFling",
            enabled
        )
    end
    if not Silent
    and getgenv().AutoSaveConfiguration then
        getgenv().AutoSaveConfiguration()
    end
end
    U.StartWalkFling = StartWalkFling
    U.StopWalkFling = StopWalkFling
    U.GetWalkFlingImpulseActive = function() return WalkFlingImpulseActive end
end
do
local CarFlyVelocity = nil
local CarFlyGyro = nil
local CarFlySeat = nil
local CarFlyRoot = nil
local CarFlyControlModule = nil
local function DestroyCarFlyMovers()
    if CarFlyVelocity then
        pcall(function()
            CarFlyVelocity:
                Destroy()
        end)
        CarFlyVelocity = nil
    end
    if CarFlyGyro then
        pcall(function()
            CarFlyGyro:
                Destroy()
        end)
        CarFlyGyro = nil
    end
    CarFlySeat = nil
    CarFlyRoot = nil
end
local function GetCarFlyMoveVector()
    if not CarFlyControlModule then
        pcall(function()
            local playerModule =
                Player.PlayerScripts:
                    WaitForChild(
                        "PlayerModule",
                        2
                    )
            local controlModule =
                playerModule
                and playerModule:
                    WaitForChild(
                        "ControlModule",
                        2
                    )
            if controlModule then
                CarFlyControlModule =
                    require(
                        controlModule
                    )
            end
        end)
    end
    if CarFlyControlModule
    and CarFlyControlModule.GetMoveVector then
        local ok, vector =
            pcall(function()
                return
                    CarFlyControlModule:
                        GetMoveVector()
            end)
        if ok
        and typeof(vector)
            == "Vector3" then
            return vector
        end
    end
    local vector =
        Vector3.zero
    if UserInputService:
        IsKeyDown(
            Enum.KeyCode.W
        ) then
        vector = vector + Vector3.new(0, 0, -1)
    end
    if UserInputService:
        IsKeyDown(
            Enum.KeyCode.S
        ) then
        vector = vector + Vector3.new(0, 0, 1)
    end
    if UserInputService:
        IsKeyDown(
            Enum.KeyCode.A
        ) then
        vector = vector + Vector3.new(-1, 0, 0)
    end
    if UserInputService:
        IsKeyDown(
            Enum.KeyCode.D
        ) then
        vector = vector + Vector3.new(1, 0, 0)
    end
    return vector
end
local function EnsureCarFlyMovers(
    root,
    seat
)
    if not root
    or not seat then
        DestroyCarFlyMovers()
        return false
    end
    if CarFlySeat ~= seat
    or CarFlyRoot ~= root then
        DestroyCarFlyMovers()
        CarFlySeat = seat
        CarFlyRoot = root
    end
    if not CarFlyVelocity
    or CarFlyVelocity.Parent
        ~= root then
        if CarFlyVelocity then
            CarFlyVelocity:
                Destroy()
        end
        CarFlyVelocity =
            Instance.new(
                "BodyVelocity"
            )
        CarFlyVelocity.Name =
            "ToxCarFlyVelocity"
        CarFlyVelocity.MaxForce =
            Vector3.new(
                9e9,
                9e9,
                9e9
            )
        CarFlyVelocity.Velocity =
            Vector3.zero
        CarFlyVelocity.Parent =
            root
    end
    if not CarFlyGyro
    or CarFlyGyro.Parent
        ~= root then
        if CarFlyGyro then
            CarFlyGyro:
                Destroy()
        end
        CarFlyGyro =
            Instance.new(
                "BodyGyro"
            )
        CarFlyGyro.Name =
            "ToxCarFlyGyro"
        CarFlyGyro.MaxTorque =
            Vector3.new(
                9e9,
                9e9,
                9e9
            )
        CarFlyGyro.P = 9e4
        CarFlyGyro.CFrame =
            root.CFrame
        CarFlyGyro.Parent =
            root
    end
    return true
end
    U.DestroyCarFlyMovers = DestroyCarFlyMovers
    U.GetCarFlyMoveVector = GetCarFlyMoveVector
    U.EnsureCarFlyMovers = EnsureCarFlyMovers
    U.SetCarFlyTarget = function(velocity, cframe)
        if CarFlyVelocity then CarFlyVelocity.Velocity = velocity end
        if CarFlyGyro then CarFlyGyro.CFrame = cframe end
    end
end
do
    local StartAntiVoid = U.StartAntiVoid
    local StopAntiVoid = U.StopAntiVoid
    local DestroyCarFlyMovers = U.DestroyCarFlyMovers
local SharedToggleSettingMap = {
    Speed = "Speed",
    Noclip = "Noclip",
    NoFallDamage = "NoFallDamage",
    AntiVoid = "AntiVoid",
    AntiFling = "AntiFling",
    WalkFling = "WalkFling",
    CtrlClickTP = "CtrlClickTP",
    CarFly = "CarFly",
    ESPEnabled = "ESPEnabled",
    Chams = "Chams",
    ESPNames = "ESPNames",
    ESPTeamColors = "ESPTeamColors",
    SmoothFly = "SmoothFly",
    NormalFly = "NormalFly",
    FlyBypass = "FlyBypass"
}
local SharedValueSettingMap = {
    Speed = "SpeedValue",
    CarFly = "CarFlySpeed",
    SmoothFly = "FlySpeed",
    NormalFly = "FlySpeed",
    FlyBypass = "FlySpeed",
    WalkFling = "WalkFlingPower",
    WalkFlingPower = "WalkFlingPower",
    UltraInstinctRange = "UltraInstinctRange"
}
local function GetGlobalSharedState()
    getgenv().BaseSharedSettings =
        getgenv().BaseSharedSettings or {}
    return getgenv().BaseSharedSettings
end
local function RecordSharedToggle(Key, Value)
    if getgenv().ToxApplyingGameState then
        return
    end
    local settingKey = SharedToggleSettingMap[Key]
    if not settingKey then
        return
    end
    local globalState = GetGlobalSharedState()
    globalState[settingKey] = Value == true
    Settings[settingKey] = Value == true
end
getgenv().ToxOnSharedValueChanged = function(Key, Value)
    if getgenv().ToxApplyingGameState then
        return
    end
    local settingKey = SharedValueSettingMap[Key]
    local number = tonumber(Value)
    if not settingKey or not number then
        return
    end
    local globalState = GetGlobalSharedState()
    globalState[settingKey] = number
    Settings[settingKey] = number
end
getgenv().ToxSetSharedOption = function(Key, Value)
    local enabled = Value == true
    RecordSharedToggle(Key, enabled)
    if Key == "Speed" then
        if enabled then
            local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
            GetHumanoidDefaults(hum)
        end
        Settings.Speed = enabled
        if not enabled then
            RestoreSpeed()
        end
    elseif Key == "Noclip" then
        if enabled then
            CaptureNoclipDefaults()
        end
        Settings.Noclip = enabled
        if not enabled then
            RestoreNoclipDefaults()
        end
    elseif Key == "NoFallDamage" then
        Settings.NoFallDamage = enabled
        if getgenv().SetNDSNoFall then
            getgenv().SetNDSNoFall(enabled, true)
        end
    elseif Key == "AntiVoid" then
        Settings.AntiVoid = enabled
        if enabled then
            StartAntiVoid()
        else
            StopAntiVoid()
        end
    elseif Key == "AntiFling" then
        Settings.AntiFling = enabled
        if not enabled then
            RestoreAntiFlingDefaults()
        end
    elseif Key == "WalkFling" then
        getgenv().SetWalkFling(
            enabled,
            true
        )
    elseif Key == "CtrlClickTP" then
        Settings.CtrlClickTP = enabled
    elseif Key == "CarFly" then
        Settings.CarFly = enabled
        if not enabled then
            DestroyCarFlyMovers()
        end
    elseif Key == "FlyBypass" then
        Settings.FlyBypass = enabled
        if enabled then
            Settings.SmoothFly = false
            Settings.NormalFly = false
            if getgenv().SyncToggleVisuals then
                getgenv().SyncToggleVisuals("SmoothFly", false)
                getgenv().SyncToggleVisuals("NormalFly", false)
            end
            if getgenv().SetNDSWaterFly then
                getgenv().SetNDSWaterFly(false, true)
            end
        end
    elseif Key == "SmoothFly" then
        Settings.SmoothFly = enabled
        if enabled then
            Settings.NormalFly = false
            Settings.FlyBypass = false
            if getgenv().SyncToggleVisuals then
                getgenv().SyncToggleVisuals("NormalFly", false)
                getgenv().SyncToggleVisuals("FlyBypass", false)
            end
            if getgenv().SetNDSWaterFly then
                getgenv().SetNDSWaterFly(false, true)
            end
        end
    elseif Key == "NormalFly" then
        Settings.NormalFly = enabled
        if enabled then
            Settings.SmoothFly = false
            Settings.FlyBypass = false
            if getgenv().SyncToggleVisuals then
                getgenv().SyncToggleVisuals("SmoothFly", false)
                getgenv().SyncToggleVisuals("FlyBypass", false)
            end
            if getgenv().SetNDSWaterFly then
                getgenv().SetNDSWaterFly(false, true)
            end
        end
    else
        Settings[Key] = enabled
    end
    if getgenv().SyncToggleVisuals then
        getgenv().SyncToggleVisuals(Key, enabled)
    end
end
getgenv().ApplyCurrentGameSharedSettings = function()
    local globalState = GetGlobalSharedState()
    getgenv().ToxApplyingGameState = true
    for Key, settingKey in pairs(SharedValueSettingMap) do
        local value = globalState[settingKey]
        if value == nil then
            value = Settings[settingKey]
        end
        if value ~= nil then
            Settings[settingKey] = value
            globalState[settingKey] = value
            if getgenv().SyncValueVisuals then
                getgenv().SyncValueVisuals(
                    Key,
                    value
                )
            end
        end
    end
    for Key, settingKey in pairs(SharedToggleSettingMap) do
        local value = globalState[settingKey]
        if value == nil then
            value = Settings[settingKey]
        end
        if value ~= nil then
            globalState[settingKey] =
                value == true
            getgenv().ToxSetSharedOption(
                Key,
                value == true
            )
        end
    end
    getgenv().ToxApplyingGameState = false
end
end
