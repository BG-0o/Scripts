local BEPlaceId = 70650894743738
if game.PlaceId ~= BEPlaceId and tostring(game.PlaceId) ~= "70650894743738" then
    return
end
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")
local Player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera or Workspace:FindFirstChildOfClass("Camera")
local Mouse = Player and Player:GetMouse()
local Settings = getgenv().Settings
local GamePage = getgenv().GamePage
local CreateToggle = getgenv().CreateToggle
local CreateToggleWithValue = getgenv().CreateToggleWithValue
local CreateButton = getgenv().CreateButton
local CreateDropdown = getgenv().CreateDropdown
local CreateToggleWithChoice = getgenv().CreateToggleWithChoice
local CustomNotify = getgenv().CustomNotify or function() end
local AutoSaveConfiguration = getgenv().AutoSaveConfiguration or function() end
local AddConnection = getgenv().AddConnection or function(c) return c end
local SyncToggleVisuals = getgenv().SyncToggleVisuals
if not Settings or not GamePage or not CreateToggle or not CreateButton then
    return
end
getgenv().ToxBEGeneration = (tonumber(getgenv().ToxBEGeneration) or 0) + 1
local CurrentGeneration = getgenv().ToxBEGeneration
local BEModuleVersion = "2026-11-04-be-v1"
if getgenv().ToxBEModuleLoadedJobId == game.JobId
and getgenv().ToxBEModuleVersion == BEModuleVersion
and getgenv().ToxBEModulePage == GamePage
and not getgenv().Destroyed then
    return
end
if getgenv().ToxBECleanup then
    pcall(getgenv().ToxBECleanup)
end
for _, child in ipairs(GamePage:GetChildren()) do
    if child:IsA("GuiObject") then
        child:Destroy()
    end
end
Settings.BECollapsedSections = typeof(Settings.BECollapsedSections) == "table"
    and Settings.BECollapsedSections
    or {}
Settings.BEAutoEat = Settings.BEAutoEat == true
Settings.BEEatRange = math.clamp(tonumber(Settings.BEEatRange) or 50, 15, 200)
Settings.BEAutoHuntNPCs = Settings.BEAutoHuntNPCs == true
Settings.BEHuntCocoons = Settings.BEHuntCocoons == true
Settings.BEAutoEvolve = Settings.BEAutoEvolve == true
Settings.BETargetEvolve = tostring(Settings.BETargetEvolve or "Auto Next")
Settings.BEAutoPerks = Settings.BEAutoPerks == true
Settings.BEPerkPriority = tostring(Settings.BEPerkPriority or "Damage")
Settings.BESmartKillAura = Settings.BESmartKillAura == true
Settings.BEAuraRange = math.clamp(tonumber(Settings.BEAuraRange) or 18, 10, 40)
Settings.BEOnlySmaller = Settings.BEOnlySmaller == true
Settings.BEFastAttack = Settings.BEFastAttack == true
Settings.BEHitboxExpander = Settings.BEHitboxExpander == true
Settings.BEHitboxSize = tonumber(Settings.BEHitboxSize) or 6
Settings.BEPredatorWarn = Settings.BEPredatorWarn == true
Settings.BEWarnDistance = tonumber(Settings.BEWarnDistance) or 60
Settings.BEAutoEscape = Settings.BEAutoEscape == true
Settings.BEEscapeHealth = tonumber(Settings.BEEscapeHealth) or 30
Settings.BEInfiniteStamina = Settings.BEInfiniteStamina == true
Settings.BEPlayerESP = Settings.BEPlayerESP == true
Settings.BEFoodESP = Settings.BEFoodESP == true
Settings.BECocoonESP = Settings.BECocoonESP == true
Settings.BEFullBright = Settings.BEFullBright == true
Settings.BESpeedBoost = Settings.BESpeedBoost == true
Settings.BESpeedMultiplier = math.clamp(tonumber(Settings.BESpeedMultiplier) or 1.5, 1.0, 3.0)
Settings.BEInfiniteJump = Settings.BEInfiniteJump == true
Settings.BEAntiAFK = Settings.BEAntiAFK == true
local BEConnections = {}
local BECurrentSection = nil
local BESections = {}
local FoodObjects = {}
local NPCObjects = {}
local PlayerESPObjects = {}
local FoodESPObjects = {}
local CocoonESPObjects = {}
local OrigLightingProps = {
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd
}
local WarnScreenGui = nil
local WarnFrame = nil
local WarnText = nil
local AntiAFKConnection = nil
local InfiniteJumpConnection = nil
local function TrackConnection(conn)
    if conn then
        table.insert(BEConnections, conn)
        AddConnection(conn)
    end
    return conn
end
local function GetCharacterState()
    local char = Player.Character
    if not char or not char.Parent then return nil, nil, nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart or char:FindFirstChildWhichIsA("BasePart")
    return char, hum, root
end
local function IsPartOfLocalPlayer(inst)
    if not inst then return false end
    local char = Player.Character
    if char and (inst == char or inst:IsDescendantOf(char)) then
        return true
    end
    local bp = Player:FindFirstChild("Backpack")
    if bp and inst:IsDescendantOf(bp) then
        return true
    end
    if inst == Player or inst:IsDescendantOf(Player) then
        return true
    end
    local cam = Workspace.CurrentCamera or Camera
    if cam and (inst == cam or inst:IsDescendantOf(cam)) then
        return true
    end
    if char then
        local root = char:FindFirstChild("HumanoidRootPart")
        if inst:IsA("BasePart") and root and inst.AssemblyRootPart == root.AssemblyRootPart then
            return true
        end
    end
    local curr = inst
    while curr and curr ~= Workspace and curr ~= game do
        local cName = string.lower(curr.Name)
        if string.find(cName, "viewmodel") or string.find(cName, "arms") or string.find(cName, "fps") then
            return true
        end
        curr = curr.Parent
    end
    if cam and (inst:IsA("BasePart") or (inst:IsA("Model") and inst.PrimaryPart)) then
        local p = inst:IsA("BasePart") and inst or inst.PrimaryPart
        if p and (p.Position - cam.CFrame.Position).Magnitude <= 3.8 then
            return true
        end
    end
    return false
end
local function SafeTeleportTo(cf)
    local char, hum, root = GetCharacterState()
    if not root then return false end
    pcall(function()
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        if char.PrimaryPart then
            char:PivotTo(cf)
        else
            root.CFrame = cf
        end
    end)
    return true
end
local function GetBugStats(model, plr)
    local stats = {
        Level = 1,
        Size = 1,
        Species = "Spider",
        Health = 100,
        MaxHealth = 100
    }
    if not model then return stats end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if hum then
        stats.Health = hum.Health
        stats.MaxHealth = hum.MaxHealth
    end
    local holders = { model, plr }
    for _, h in ipairs(holders) do
        if h then
            for _, attr in ipairs({ "Level", "level", "Lvl", "lvl", "BugLevel" }) do
                local val = h:GetAttribute(attr)
                if typeof(val) == "number" then
                    stats.Level = val
                    break
                end
            end
            for _, attr in ipairs({ "Species", "Bug", "BugType", "Creature", "Tier" }) do
                local val = h:GetAttribute(attr)
                if typeof(val) == "string" and val ~= "" then
                    stats.Species = val
                    break
                end
            end
            for _, attr in ipairs({ "Size", "Scale", "Growth" }) do
                local val = h:GetAttribute(attr)
                if typeof(val) == "number" then
                    stats.Size = val
                    break
                end
            end
        end
    end
    if stats.Size == 1 and model:IsA("Model") then
        local cf, size = model:GetBoundingBox()
        stats.Size = size.X * size.Y * size.Z
    end
    return stats
end
local function ClassifyThreat(targetPlr, targetChar)
    local myChar = Player.Character
    if not myChar or not targetChar then return "NEUTRAL", Color3.fromRGB(240, 240, 240) end
    local myStats = GetBugStats(myChar, Player)
    local targetStats = GetBugStats(targetChar, targetPlr)
    if targetStats.Level > (myStats.Level + 1) or targetStats.Size > (myStats.Size * 1.3) then
        return "PREDATOR", Color3.fromRGB(255, 45, 60)
    elseif targetStats.Level < myStats.Level or targetStats.Size < (myStats.Size * 0.85) then
        return "PREY", Color3.fromRGB(50, 230, 100)
    else
        return "NEUTRAL", Color3.fromRGB(255, 205, 50)
    end
end
local function GetAttackRemotes()
    local remotes = {}
    pcall(function()
        for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
            if desc:IsA("RemoteEvent") or desc:IsA("RemoteFunction") then
                local n = string.lower(desc.Name)
                if string.find(n, "attack") or string.find(n, "bite") or string.find(n, "hit")
                or string.find(n, "damage") or string.find(n, "swing") or string.find(n, "eat")
                or string.find(n, "combat") or string.find(n, "sting") then
                    table.insert(remotes, desc)
                end
            end
        end
    end)
    return remotes
end
local function ExecuteBugAttack(targetModel)
    local char = Player.Character
    if not char then return end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            pcall(function() tool:Activate() end)
        end
    end
    local tHum = targetModel and targetModel:FindFirstChildOfClass("Humanoid")
    local tRoot = targetModel and (targetModel:FindFirstChild("HumanoidRootPart") or targetModel.PrimaryPart)
    for _, rem in ipairs(GetAttackRemotes()) do
        pcall(function()
            if rem:IsA("RemoteEvent") then
                rem:FireServer(targetModel)
                if tHum then rem:FireServer(tHum) end
                if tRoot then rem:FireServer(tRoot) end
            end
        end)
    end
end
local function CreateOrUpdateHighlight(instance, color, name)
    if not instance or not instance.Parent then return nil end
    local hlName = name or "ToxBE_HL"
    if IsPartOfLocalPlayer(instance) then
        local old = instance:FindFirstChild(hlName)
        if old then pcall(function() old:Destroy() end) end
        return nil
    end
    local hl = instance:FindFirstChild(hlName)
    if not hl or not hl:IsA("Highlight") then
        hl = Instance.new("Highlight")
        hl.Name = hlName
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.FillTransparency = 0.35
        hl.OutlineTransparency = 0.05
        hl.Adornee = instance
        hl.Parent = instance
    else
        if hl.Adornee ~= instance then
            hl.Adornee = instance
        end
    end
    if hl.FillColor ~= color then
        hl.FillColor = color
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    end
    if not hl.Enabled then
        hl.Enabled = true
    end
    return hl
end
local function CreateOrUpdateBillboard(adornee, name, text, color, offset)
    if not adornee or not adornee.Parent or IsPartOfLocalPlayer(adornee) then return nil end
    local bb = adornee:FindFirstChild(name)
    local label = nil
    if not bb or not bb:IsA("BillboardGui") then
        bb = Instance.new("BillboardGui")
        bb.Name = name
        bb.Size = UDim2.new(0, 160, 0, 28)
        bb.StudsOffset = offset or Vector3.new(0, 2.5, 0)
        bb.AlwaysOnTop = true
        bb.MaxDistance = 350
        bb.Adornee = adornee
        label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.TextColor3 = color
        label.TextStrokeTransparency = 0.2
        label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        label.Font = Enum.Font.GothamBold
        label.TextSize = 11
        label.Text = text
        label.Parent = bb
        bb.Parent = adornee
    else
        label = bb:FindFirstChildOfClass("TextLabel")
        if label then
            label.Text = text
            label.TextColor3 = color
        end
    end
    if not bb.Enabled then bb.Enabled = true end
    return bb, label
end
local function UpdatePlayerESP(charRoot)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Player then
            local char = plr.Character
            local root = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart or char:FindFirstChildWhichIsA("BasePart"))
            if char and char.Parent and root and Settings.BEPlayerESP then
                local classification, color = ClassifyThreat(plr, char)
                local stats = GetBugStats(char, plr)
                local dist = charRoot and (root.Position - charRoot.Position).Magnitude or 0
                local tagText = string.format("[%s] %s\nLv.%d - %s (%dm)", classification, plr.DisplayName or plr.Name, stats.Level, stats.Species, math.floor(dist))
                local hl = CreateOrUpdateHighlight(char, color, "ToxBE_PlayerHL")
                local bb, label = CreateOrUpdateBillboard(root, "ToxBE_PlayerBB", tagText, color, Vector3.new(0, 3.2, 0))
                PlayerESPObjects[plr] = { Highlight = hl, Billboard = bb, Label = label }
            else
                if PlayerESPObjects[plr] then
                    pcall(function()
                        if PlayerESPObjects[plr].Highlight then PlayerESPObjects[plr].Highlight:Destroy() end
                        if PlayerESPObjects[plr].Billboard then PlayerESPObjects[plr].Billboard:Destroy() end
                    end)
                    PlayerESPObjects[plr] = nil
                end
            end
        end
    end
end
local function SetupWarningHUD()
    if WarnScreenGui then return end
    pcall(function()
        local parent = (gethui and gethui()) or CoreGui:FindFirstChild("RobloxGui") or CoreGui
        WarnScreenGui = Instance.new("ScreenGui")
        WarnScreenGui.Name = "ToxBE_WarnGui"
        WarnScreenGui.ResetOnSpawn = false
        WarnScreenGui.Parent = parent
        WarnFrame = Instance.new("Frame")
        WarnFrame.Size = UDim2.new(0, 320, 0, 36)
        WarnFrame.Position = UDim2.new(0.5, -160, 0.12, 0)
        WarnFrame.BackgroundColor3 = Color3.fromRGB(24, 10, 14)
        WarnFrame.BorderSizePixel = 0
        WarnFrame.Visible = false
        WarnFrame.Parent = WarnScreenGui
        local corner = Instance.new("UICorner") corner.CornerRadius = UDim.new(0, 6) corner.Parent = WarnFrame
        local stroke = Instance.new("UIStroke") stroke.Color = Color3.fromRGB(255, 45, 60) stroke.Thickness = 1.5 stroke.Parent = WarnFrame
        WarnText = Instance.new("TextLabel")
        WarnText.Size = UDim2.new(1, 0, 1, 0)
        WarnText.BackgroundTransparency = 1
        WarnText.Text = "WARNING: PREDATOR NEARBY!"
        WarnText.TextColor3 = Color3.fromRGB(255, 65, 75)
        WarnText.Font = Enum.Font.GothamBold
        WarnText.TextSize = 12
        WarnText.Parent = WarnFrame
    end)
end
local function ApplyFullBright()
    if Settings.BEFullBright then
        Lighting.Brightness = 2.5
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.OutdoorAmbient = Color3.fromRGB(160, 160, 160)
        Lighting.Ambient = Color3.fromRGB(145, 145, 145)
    else
        Lighting.Brightness = OrigLightingProps.Brightness or 2
        Lighting.ClockTime = OrigLightingProps.ClockTime or 14
        Lighting.FogEnd = OrigLightingProps.FogEnd or 10000
        Lighting.OutdoorAmbient = OrigLightingProps.OutdoorAmbient or Color3.fromRGB(128, 128, 128)
        Lighting.Ambient = OrigLightingProps.Ambient or Color3.fromRGB(0, 0, 0)
    end
end
local function FindNearbyFood(root, maxDist)
    local bestFood = nil
    local minDist = maxDist or 50
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not IsPartOfLocalPlayer(obj) then
            local n = string.lower(obj.Name)
            local pName = obj.Parent and string.lower(obj.Parent.Name) or ""
            local isFood = string.find(n, "food") or string.find(n, "orb") or string.find(n, "pellet")
                        or string.find(n, "apple") or string.find(n, "meat") or string.find(n, "xp")
                        or string.find(n, "seed") or string.find(n, "berry")
                        or string.find(pName, "food") or string.find(pName, "orbs")
            if isFood and obj.Size.X < 15 and obj.Size.Z < 15 then
                local dist = (obj.Position - root.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    bestFood = obj
                end
            end
        end
    end
    return bestFood, minDist
end
local function ProcessAutoEat(root)
    local food, dist = FindNearbyFood(root, Settings.BEEatRange or 50)
    if food and food.Parent then
        pcall(function()
            if firetouchinterest then
                firetouchinterest(root, food, 0)
                task.wait(0.01)
                firetouchinterest(root, food, 1)
            end
        end)
        for _, prompt in ipairs(food:GetChildren()) do
            if prompt:IsA("ProximityPrompt") and prompt.Enabled then
                pcall(function()
                    fireproximityprompt(prompt, 0)
                end)
            end
        end
        if dist > 3 and dist < 25 then
            root.CFrame = CFrame.new(root.Position:Lerp(food.Position + Vector3.new(0, 0.5, 0), 0.35), food.Position)
        end
    end
end
local function ProcessSmartKillAura(root)
    local bestTarget = nil
    local minDist = Settings.BEAuraRange or 18
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Player then
            local char = plr.Character
            local tRoot = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if char and tRoot and hum and hum.Health > 0 then
                local classification = ClassifyThreat(plr, char)
                local canAttack = not Settings.BEOnlySmaller or (classification == "PREY")
                if canAttack then
                    local dist = (tRoot.Position - root.Position).Magnitude
                    if dist <= minDist then
                        minDist = dist
                        bestTarget = char
                    end
                end
            end
        end
    end
    if not bestTarget and (Settings.BEAutoHuntNPCs or Settings.BEHuntCocoons) then
        for _, m in ipairs(Workspace:GetChildren()) do
            if m:IsA("Model") and m ~= Player.Character and not Players:GetPlayerFromCharacter(m) then
                local hum = m:FindFirstChildOfClass("Humanoid")
                local mRoot = m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
                local mName = string.lower(m.Name)
                local isCocoon = string.find(mName, "cocoon")
                if mRoot and ((isCocoon and Settings.BEHuntCocoons) or (hum and hum.Health > 0 and Settings.BEAutoHuntNPCs)) then
                    local dist = (mRoot.Position - root.Position).Magnitude
                    if dist <= minDist then
                        minDist = dist
                        bestTarget = m
                    end
                end
            end
        end
    end
    if bestTarget then
        ExecuteBugAttack(bestTarget)
    end
end
local function ProcessAutoEscape(hum, root)
    if not hum or not root then return end
    local hpPercent = (hum.Health / math.max(hum.MaxHealth, 1)) * 100
    if hpPercent <= (Settings.BEEscapeHealth or 30) then
        local escapeCF = root.CFrame + Vector3.new(0, 45, 0)
        SafeTeleportTo(escapeCF)
        CustomNotify("Low HP: Auto Escaped to Safety!", Color3.fromRGB(0, 255, 140), 2)
    end
end
local function ProcessInfiniteStamina()
    local char = Player.Character
    if not char then return end
    for _, name in ipairs({ "Stamina", "Energy", "Boost", "RunEnergy" }) do
        local val = char:GetAttribute(name)
        if typeof(val) == "number" and val < 100 then
            pcall(function() char:SetAttribute(name, 100) end)
        end
        local obj = char:FindFirstChild(name)
        if obj and (obj:IsA("NumberValue") or obj:IsA("IntValue")) and obj.Value < 100 then
            pcall(function() obj.Value = 100 end)
        end
    end
end
local function ProcessAutoEvolve()
    pcall(function()
        for _, rem in ipairs(ReplicatedStorage:GetDescendants()) do
            if rem:IsA("RemoteEvent") or rem:IsA("RemoteFunction") then
                local n = string.lower(rem.Name)
                if string.find(n, "evolve") or string.find(n, "evolution") or string.find(n, "unlockbug") then
                    if rem:IsA("RemoteEvent") then
                        rem:FireServer()
                        rem:FireServer(Settings.BETargetEvolve)
                    end
                end
            end
        end
    end)
end
local function ProcessAutoPerks()
    pcall(function()
        for _, rem in ipairs(ReplicatedStorage:GetDescendants()) do
            if rem:IsA("RemoteEvent") then
                local n = string.lower(rem.Name)
                if string.find(n, "perk") or string.find(n, "stat") or string.find(n, "upgrade") or string.find(n, "skill") then
                    rem:FireServer(Settings.BEPerkPriority)
                    rem:FireServer(1)
                end
            end
        end
    end)
end
local LastAuraTick = 0
local LastEatTick = 0
local LastEvolveTick = 0
local LastESPTick = 0
TrackConnection(RunService.Heartbeat:Connect(function()
    if getgenv().ToxBEGeneration ~= CurrentGeneration or getgenv().Destroyed then return end
    local char, hum, root = GetCharacterState()
    local now = os.clock()
    if char then
        for _, c in ipairs(char:GetDescendants()) do
            if c:IsA("Highlight") and string.find(c.Name, "ToxBE") then
                pcall(function() c:Destroy() end)
            end
        end
    end
    local cam = Workspace.CurrentCamera or Camera
    if cam then
        for _, c in ipairs(cam:GetDescendants()) do
            if c:IsA("Highlight") and string.find(c.Name, "ToxBE") then
                pcall(function() c:Destroy() end)
            end
        end
    end
    if not root or not hum or hum.Health <= 0 then return end
    if Settings.BESpeedBoost and hum then
        local baseSpeed = 16
        hum.WalkSpeed = math.max(baseSpeed * (Settings.BESpeedMultiplier or 1.5), hum.WalkSpeed)
    end
    if Settings.BEInfiniteStamina then
        ProcessInfiniteStamina()
    end
    if Settings.BEAutoEscape then
        ProcessAutoEscape(hum, root)
    end
    if Settings.BEHitboxExpander then
        local head = char:FindFirstChild("Head") or char:FindFirstChild("Jaw") or char:FindFirstChild("Mouth")
        if head and head:IsA("BasePart") then
            local s = Settings.BEHitboxSize or 6
            head.Size = Vector3.new(s, s, s)
            head.CanCollide = false
        end
    end
    if Settings.BEAutoEat and (now - LastEatTick >= 0.15) then
        LastEatTick = now
        ProcessAutoEat(root)
    end
    if Settings.BESmartKillAura and (now - LastAuraTick >= 0.1) then
        LastAuraTick = now
        ProcessSmartKillAura(root)
    end
    if (Settings.BEAutoEvolve or Settings.BEAutoPerks) and (now - LastEvolveTick >= 2.5) then
        LastEvolveTick = now
        if Settings.BEAutoEvolve then ProcessAutoEvolve() end
        if Settings.BEAutoPerks then ProcessAutoPerks() end
    end
    if now - LastESPTick >= 0.18 then
        LastESPTick = now
        UpdatePlayerESP(root)
        if Settings.BEPredatorWarn and WarnFrame then
            local closestPredatorDist = 9999
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= Player and plr.Character then
                    local pRoot = plr.Character:FindFirstChild("HumanoidRootPart") or plr.Character.PrimaryPart
                    if pRoot then
                        local classification = ClassifyThreat(plr, plr.Character)
                        if classification == "PREDATOR" then
                            local d = (pRoot.Position - root.Position).Magnitude
                            if d < closestPredatorDist then
                                closestPredatorDist = d
                            end
                        end
                    end
                end
            end
            local warnDist = Settings.BEWarnDistance or 60
            if closestPredatorDist <= warnDist then
                WarnFrame.Visible = true
                WarnText.Text = string.format("WARNING: APEX PREDATOR %d STUDS AWAY!", math.floor(closestPredatorDist))
            else
                WarnFrame.Visible = false
            end
        elseif WarnFrame then
            WarnFrame.Visible = false
        end
    end
end))
local function SetupInfiniteJump(enable)
    if InfiniteJumpConnection then
        InfiniteJumpConnection:Disconnect()
        InfiniteJumpConnection = nil
    end
    if enable then
        InfiniteJumpConnection = UserInputService.JumpRequest:Connect(function()
            if Settings.BEInfiniteJump then
                local _, hum = GetCharacterState()
                if hum then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end)
        TrackConnection(InfiniteJumpConnection)
    end
end
local function SetupAntiAFK(enable)
    if AntiAFKConnection then
        AntiAFKConnection:Disconnect()
        AntiAFKConnection = nil
    end
    if enable then
        local vu = game:GetService("VirtualUser")
        AntiAFKConnection = Player.Idled:Connect(function()
            if Settings.BEAntiAFK then
                pcall(function()
                    vu:Button2Down(Vector2.zero, Workspace.CurrentCamera.CFrame)
                    task.wait(0.1)
                    vu:Button2Up(Vector2.zero, Workspace.CurrentCamera.CFrame)
                end)
            end
        end)
        TrackConnection(AntiAFKConnection)
    end
end
SetupWarningHUD()
if Settings.BEFullBright then
    pcall(ApplyFullBright)
end
if Settings.BEInfiniteJump then
    pcall(function() SetupInfiniteJump(true) end)
end
if Settings.BEAntiAFK then
    pcall(function() SetupAntiAFK(true) end)
end
local function TrackControl(control)
    if not control then return nil end
    if BECurrentSection then
        table.insert(BECurrentSection.Controls, control)
        control.Visible = not BECurrentSection.Collapsed
    end
    return control
end
local function CreateBESection(text)
    local name = tostring(text)
    local key = string.gsub(name, "%s+", "")
    local Header = Instance.new("TextButton")
    Header.Size = UDim2.new(1, -5, 0, 24)
    Header.BackgroundColor3 = Color3.fromRGB(13, 13, 21)
    Header.BorderSizePixel = 0
    Header.Text = ""
    Header.AutoButtonColor = false
    Header.Parent = GamePage
    local HeaderCorner = Instance.new("UICorner") HeaderCorner.CornerRadius = UDim.new(0, 4) HeaderCorner.Parent = Header
    local HeaderStroke = Instance.new("UIStroke") HeaderStroke.Color = Color3.fromRGB(28, 28, 42) HeaderStroke.Thickness = 1 HeaderStroke.Parent = Header
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -50, 1, 0)
    Title.Position = UDim2.new(0, 8, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = string.upper(name)
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 10
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Header
    local Indicator = Instance.new("TextLabel")
    Indicator.Size = UDim2.new(0, 20, 1, 0)
    Indicator.Position = UDim2.new(1, -24, 0, 0)
    Indicator.BackgroundTransparency = 1
    Indicator.TextColor3 = Color3.fromRGB(200, 200, 200)
    Indicator.TextSize = 11
    Indicator.Font = Enum.Font.GothamBold
    Indicator.Parent = Header
    local sectionData = {
        Key = key,
        Header = Header,
        Indicator = Indicator,
        Collapsed = Settings.BECollapsedSections[key] == true,
        Controls = {}
    }
    local function UpdateVisuals()
        Indicator.Text = sectionData.Collapsed and "+" or "-"
        for _, ctrl in ipairs(sectionData.Controls) do
            ctrl.Visible = not sectionData.Collapsed
        end
    end
    Header.MouseButton1Click:Connect(function()
        if getgenv().Destroyed or getgenv().ToxOptionsReady == false then return end
        sectionData.Collapsed = not sectionData.Collapsed
        Settings.BECollapsedSections[key] = sectionData.Collapsed
        UpdateVisuals()
        AutoSaveConfiguration()
    end)
    UpdateVisuals()
    table.insert(BESections, sectionData)
    BECurrentSection = sectionData
    return sectionData
end
local function BECreateToggle(...)
    return TrackControl(CreateToggle(...))
end
local function BECreateButton(...)
    return TrackControl(CreateButton(...))
end
local function BECreateDropdown(...)
    if CreateDropdown then
        return TrackControl(CreateDropdown(...))
    end
    return nil
end
CreateBESection("FARMING & PROGRESSION")
BECreateToggle(
    "Auto Eat",
    GamePage,
    Settings.BEAutoEat,
    function(v)
        Settings.BEAutoEat = v == true
        AutoSaveConfiguration()
    end,
    "BEAutoEat"
)
BECreateDropdown(
    "Eat Range",
    { "25 studs", "50 studs", "100 studs", "150 studs" },
    GamePage,
    (Settings.BEEatRange or 50) .. " studs",
    function(choice)
        local num = tonumber(string.match(choice, "%d+")) or 50
        Settings.BEEatRange = num
        AutoSaveConfiguration()
    end
)
BECreateToggle(
    "Auto Hunt NPCs",
    GamePage,
    Settings.BEAutoHuntNPCs,
    function(v)
        Settings.BEAutoHuntNPCs = v == true
        AutoSaveConfiguration()
    end,
    "BEAutoHuntNPCs"
)
BECreateToggle(
    "Hunt Cocoons",
    GamePage,
    Settings.BEHuntCocoons,
    function(v)
        Settings.BEHuntCocoons = v == true
        AutoSaveConfiguration()
    end,
    "BEHuntCocoons"
)
BECreateToggle(
    "Auto Evolve",
    GamePage,
    Settings.BEAutoEvolve,
    function(v)
        Settings.BEAutoEvolve = v == true
        AutoSaveConfiguration()
    end,
    "BEAutoEvolve"
)
BECreateDropdown(
    "Target Evolution",
    { "Auto Next", "Spider", "Ant", "Fly", "Grasshopper", "Hornet", "Tarantula", "Mantis" },
    GamePage,
    Settings.BETargetEvolve or "Auto Next",
    function(choice)
        Settings.BETargetEvolve = tostring(choice)
        AutoSaveConfiguration()
    end
)
BECreateToggle(
    "Auto Upgrade Perks",
    GamePage,
    Settings.BEAutoPerks,
    function(v)
        Settings.BEAutoPerks = v == true
        AutoSaveConfiguration()
    end,
    "BEAutoPerks"
)
BECreateDropdown(
    "Perk Priority",
    { "Damage", "Speed", "Max Health", "Stamina" },
    GamePage,
    Settings.BEPerkPriority or "Damage",
    function(choice)
        Settings.BEPerkPriority = tostring(choice)
        AutoSaveConfiguration()
    end
)
CreateBESection("COMBAT")
BECreateToggle(
    "Smart Kill Aura",
    GamePage,
    Settings.BESmartKillAura,
    function(v)
        Settings.BESmartKillAura = v == true
        AutoSaveConfiguration()
    end,
    "BESmartKillAura"
)
BECreateToggle(
    "Only Smaller Bugs",
    GamePage,
    Settings.BEOnlySmaller,
    function(v)
        Settings.BEOnlySmaller = v == true
        AutoSaveConfiguration()
    end,
    "BEOnlySmaller"
)
BECreateDropdown(
    "Aura Range",
    { "12 studs", "18 studs", "25 studs", "35 studs" },
    GamePage,
    (Settings.BEAuraRange or 18) .. " studs",
    function(choice)
        local num = tonumber(string.match(choice, "%d+")) or 18
        Settings.BEAuraRange = num
        AutoSaveConfiguration()
    end
)
BECreateToggle(
    "Hitbox Expander",
    GamePage,
    Settings.BEHitboxExpander,
    function(v)
        Settings.BEHitboxExpander = v == true
        if not v then
            local char = Player.Character
            local head = char and (char:FindFirstChild("Head") or char:FindFirstChild("Jaw"))
            if head and head:IsA("BasePart") then head.Size = Vector3.new(2, 1, 1) end
        end
        AutoSaveConfiguration()
    end,
    "BEHitboxExpander"
)
CreateBESection("SURVIVAL")
BECreateToggle(
    "Predator Warning",
    GamePage,
    Settings.BEPredatorWarn,
    function(v)
        Settings.BEPredatorWarn = v == true
        if not v and WarnFrame then WarnFrame.Visible = false end
        AutoSaveConfiguration()
    end,
    "BEPredatorWarn"
)
BECreateToggle(
    "Auto Escape",
    GamePage,
    Settings.BEAutoEscape,
    function(v)
        Settings.BEAutoEscape = v == true
        AutoSaveConfiguration()
    end,
    "BEAutoEscape"
)
BECreateDropdown(
    "Escape Health",
    { "20% HP", "30% HP", "40% HP", "50% HP" },
    GamePage,
    (Settings.BEEscapeHealth or 30) .. "% HP",
    function(choice)
        local num = tonumber(string.match(choice, "%d+")) or 30
        Settings.BEEscapeHealth = num
        AutoSaveConfiguration()
    end
)
BECreateToggle(
    "Infinite Stamina",
    GamePage,
    Settings.BEInfiniteStamina,
    function(v)
        Settings.BEInfiniteStamina = v == true
        AutoSaveConfiguration()
    end,
    "BEInfiniteStamina"
)
CreateBESection("VISUALS")
BECreateToggle(
    "Player ESP",
    GamePage,
    Settings.BEPlayerESP,
    function(v)
        Settings.BEPlayerESP = v == true
        if not v then
            for _, esp in pairs(PlayerESPObjects) do
                if esp.Highlight then esp.Highlight.Enabled = false end
                if esp.Billboard then esp.Billboard.Enabled = false end
            end
        end
        AutoSaveConfiguration()
    end,
    "BEPlayerESP"
)
BECreateToggle(
    "FullBright",
    GamePage,
    Settings.BEFullBright,
    function(v)
        Settings.BEFullBright = v == true
        ApplyFullBright()
        AutoSaveConfiguration()
    end,
    "BEFullBright"
)
CreateBESection("MOVEMENT & MISC")
BECreateToggle(
    "Speed Boost",
    GamePage,
    Settings.BESpeedBoost,
    function(v)
        Settings.BESpeedBoost = v == true
        if not v then
            local _, hum = GetCharacterState()
            if hum then hum.WalkSpeed = 16 end
        end
        AutoSaveConfiguration()
    end,
    "BESpeedBoost"
)
BECreateDropdown(
    "Speed Multiplier",
    { "1.25x", "1.5x", "2.0x", "2.5x" },
    GamePage,
    (Settings.BESpeedMultiplier or 1.5) .. "x",
    function(choice)
        local num = tonumber(string.match(choice, "[%d%.]+")) or 1.5
        Settings.BESpeedMultiplier = num
        AutoSaveConfiguration()
    end
)
BECreateToggle(
    "Infinite Jump",
    GamePage,
    Settings.BEInfiniteJump,
    function(v)
        Settings.BEInfiniteJump = v == true
        SetupInfiniteJump(v == true)
        AutoSaveConfiguration()
    end,
    "BEInfiniteJump"
)
BECreateToggle(
    "Anti AFK",
    GamePage,
    Settings.BEAntiAFK,
    function(v)
        Settings.BEAntiAFK = v == true
        SetupAntiAFK(v == true)
        AutoSaveConfiguration()
    end,
    "BEAntiAFK"
)
BECreateButton("Rejoin Server", GamePage, function()
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Player)
end)
getgenv().ToxBECleanup = function()
    getgenv().ToxBEGeneration = (tonumber(getgenv().ToxBEGeneration) or 0) + 1
    SetupInfiniteJump(false)
    SetupAntiAFK(false)
    for _, conn in ipairs(BEConnections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(BEConnections)
    for _, esp in pairs(PlayerESPObjects) do
        pcall(function()
            if esp.Highlight then esp.Highlight:Destroy() end
            if esp.Billboard then esp.Billboard:Destroy() end
        end)
    end
    table.clear(PlayerESPObjects)
    if WarnScreenGui then
        pcall(function() WarnScreenGui:Destroy() end)
        WarnScreenGui = nil
        WarnFrame = nil
        WarnText = nil
    end
    pcall(function()
        Lighting.Brightness = OrigLightingProps.Brightness or 2
        Lighting.ClockTime = OrigLightingProps.ClockTime or 14
        Lighting.FogEnd = OrigLightingProps.FogEnd or 10000
        Lighting.OutdoorAmbient = OrigLightingProps.OutdoorAmbient or Color3.fromRGB(128, 128, 128)
        Lighting.Ambient = OrigLightingProps.Ambient or Color3.fromRGB(0, 0, 0)
    end)
end
getgenv().ToxBEModuleLoadedJobId = game.JobId
getgenv().ToxBEModuleVersion = BEModuleVersion
getgenv().ToxBEModulePage = GamePage
CustomNotify("ToxHub: Bug Evolution Loaded!", Color3.fromRGB(50, 230, 100), 3)
