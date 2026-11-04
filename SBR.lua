local VEPlaceId = 116448925875915
if game.PlaceId ~= VEPlaceId and tostring(game.PlaceId) ~= "116448925875915" then
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
local VirtualUser = game:GetService("VirtualUser")
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
getgenv().ToxVEGeneration = (tonumber(getgenv().ToxVEGeneration) or 0) + 1
local CurrentGeneration = getgenv().ToxVEGeneration
local VEModuleVersion = "2026-11-04-ve-v1"
if getgenv().ToxVEModuleLoadedJobId == game.JobId
and getgenv().ToxVEModuleVersion == VEModuleVersion
and getgenv().ToxVEModulePage == GamePage
and not getgenv().Destroyed then
    return
end
if getgenv().ToxVECleanup then
    pcall(getgenv().ToxVECleanup)
end
for _, child in ipairs(GamePage:GetChildren()) do
    if child:IsA("GuiObject") then
        child:Destroy()
    end
end
Settings.VECollapsedSections = typeof(Settings.VECollapsedSections) == "table"
    and Settings.VECollapsedSections
    or {}
Settings.VEAutoTrain = Settings.VEAutoTrain == true
Settings.VETrainArea = tostring(Settings.VETrainArea or "Auto Best")
Settings.VEAutoEvolve = Settings.VEAutoEvolve == true
Settings.VEAutoRebirth = Settings.VEAutoRebirth == true
Settings.VEAutoGifts = Settings.VEAutoGifts == true
Settings.VEAutoSpin = Settings.VEAutoSpin == true
Settings.VEAutoFarmStages = Settings.VEAutoFarmStages == true
Settings.VEKillAura = Settings.VEKillAura == true
Settings.VEFastAttack = Settings.VEFastAttack == true
Settings.VEAuraRange = math.clamp(tonumber(Settings.VEAuraRange) or 25, 10, 80)
Settings.VEHitboxExpander = Settings.VEHitboxExpander == true
Settings.VEHitboxSize = math.clamp(tonumber(Settings.VEHitboxSize) or 20, 5, 50)
Settings.VESafeFarm = Settings.VESafeFarm == true
Settings.VEAutoOpenEggs = Settings.VEAutoOpenEggs == true
Settings.VEEggChoice = tostring(Settings.VEEggChoice or "Starter Egg")
Settings.VEFastOpen = Settings.VEFastOpen == true
Settings.VEAutoEquipBest = Settings.VEAutoEquipBest == true
Settings.VEEnemyESP = Settings.VEEnemyESP == true
Settings.VEPlayerESP = Settings.VEPlayerESP == true
Settings.VEFullBright = Settings.VEFullBright == true
Settings.VESpeedBoost = Settings.VESpeedBoost == true
Settings.VESpeedMultiplier = math.clamp(tonumber(Settings.VESpeedMultiplier) or 1.5, 1.0, 3.5)
Settings.VEInfiniteJump = Settings.VEInfiniteJump == true
Settings.VEAntiAFK = Settings.VEAntiAFK == true
local VEConnections = {}
local VECurrentSection = nil
local VESections = {}
local PlayerESPObjects = {}
local EnemyESPObjects = {}
local CachedHitboxes = {}
local CachedRemotes = {}
local OrigLightingProps = {
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd
}
local function TrackConnection(conn)
    if conn then
        table.insert(VEConnections, conn)
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
    return false
end
local function FindRemote(keywords, isFunction)
    local cacheKey = table.concat(keywords, "_") .. (isFunction and "_F" or "_E")
    if CachedRemotes[cacheKey] and CachedRemotes[cacheKey].Parent then
        return CachedRemotes[cacheKey]
    end
    local targetClass = isFunction and "RemoteFunction" or "RemoteEvent"
    local searchContainers = { ReplicatedStorage, Workspace }
    for _, container in ipairs(searchContainers) do
        for _, desc in ipairs(container:GetDescendants()) do
            if desc:IsA(targetClass) then
                local dName = string.lower(desc.Name)
                for _, kw in ipairs(keywords) do
                    if string.find(dName, string.lower(kw), 1, true) then
                        CachedRemotes[cacheKey] = desc
                        return desc
                    end
                end
            end
        end
    end
    return nil
end
local function TriggerAttack(target)
    local atkRemote = FindRemote({ "attack", "punch", "hit", "damage", "slash", "combat", "strike", "click" }, false)
    if atkRemote then
        pcall(function()
            if target then
                atkRemote:FireServer(target)
            else
                atkRemote:FireServer()
            end
        end)
    end
    local char = Player.Character
    if char then
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then
            pcall(function()
                tool:Activate()
            end)
        else
            local bp = Player:FindFirstChild("Backpack")
            if bp then
                local bpTool = bp:FindFirstChildOfClass("Tool")
                local hum = char:FindFirstChildOfClass("Humanoid")
                if bpTool and hum then
                    pcall(function()
                        hum:EquipTool(bpTool)
                        bpTool:Activate()
                    end)
                end
            end
        end
    end
end
local function GetEnemies()
    local enemies = {}
    local char = Player.Character
    local possibleFolders = {
        Workspace:FindFirstChild("Enemies"),
        Workspace:FindFirstChild("Mobs"),
        Workspace:FindFirstChild("NPCs"),
        Workspace:FindFirstChild("Bosses"),
        Workspace:FindFirstChild("Monsters"),
        Workspace:FindFirstChild("Stage"),
        Workspace:FindFirstChild("Fight")
    }
    for _, folder in ipairs(possibleFolders) do
        if folder then
            for _, item in ipairs(folder:GetChildren()) do
                if item:IsA("Model") then
                    local hum = item:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 and not Players:GetPlayerFromCharacter(item) and item ~= char then
                        table.insert(enemies, item)
                    end
                end
            end
        end
    end
    if #enemies == 0 then
        for _, item in ipairs(Workspace:GetChildren()) do
            if item:IsA("Model") and item ~= char then
                local hum = item:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 and not Players:GetPlayerFromCharacter(item) then
                    local nameLow = string.lower(item.Name)
                    if not string.find(nameLow, "vendor") and not string.find(nameLow, "shop") and not string.find(nameLow, "dummy") and not string.find(nameLow, "quest") then
                        table.insert(enemies, item)
                    end
                end
            end
        end
    end
    return enemies
end
local function GetTrainingSpeakers()
    local speakers = {}
    local possibleFolders = {
        Workspace:FindFirstChild("Speakers"),
        Workspace:FindFirstChild("Training"),
        Workspace:FindFirstChild("Zones"),
        Workspace:FindFirstChild("Pads"),
        Workspace:FindFirstChild("TrainPads")
    }
    for _, folder in ipairs(possibleFolders) do
        if folder then
            for _, item in ipairs(folder:GetChildren()) do
                table.insert(speakers, item)
            end
        end
    end
    if #speakers == 0 then
        for _, desc in ipairs(Workspace:GetDescendants()) do
            if desc:IsA("BasePart") or desc:IsA("Model") then
                local nLow = string.lower(desc.Name)
                if string.find(nLow, "speaker") or string.find(nLow, "sound") or string.find(nLow, "blast") or string.find(nLow, "train") then
                    if not desc:IsDescendantOf(Player.Character or Workspace) and not Players:GetPlayerFromCharacter(desc) then
                        table.insert(speakers, desc)
                        if #speakers >= 30 then
                            break
                        end
                    end
                end
            end
        end
    end
    return speakers
end
local function UpdateHitboxExpander()
    if not Settings.VEHitboxExpander then
        for part, orig in pairs(CachedHitboxes) do
            if part and part.Parent then
                pcall(function()
                    part.Size = orig.Size
                    part.CanCollide = orig.CanCollide
                    part.Transparency = orig.Transparency
                end)
            end
        end
        table.clear(CachedHitboxes)
        return
    end
    local size = Settings.VEHitboxSize or 20
    local targetSize = Vector3.new(size, size, size)
    local enemies = GetEnemies()
    for _, enemy in ipairs(enemies) do
        local root = enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart or enemy:FindFirstChildWhichIsA("BasePart")
        if root and not CachedHitboxes[root] then
            CachedHitboxes[root] = {
                Size = root.Size,
                CanCollide = root.CanCollide,
                Transparency = root.Transparency
            }
        end
        if root then
            pcall(function()
                root.Size = targetSize
                root.CanCollide = false
                root.Transparency = math.clamp(root.Transparency, 0.4, 0.8)
            end)
        end
    end
end
local function CreateOrUpdateEnemyESP(enemy)
    if not enemy or not enemy.Parent then return end
    local hum = enemy:FindFirstChildOfClass("Humanoid")
    local root = enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart or enemy:FindFirstChildWhichIsA("BasePart")
    if not hum or hum.Health <= 0 or not root then
        if EnemyESPObjects[enemy] then
            pcall(function()
                if EnemyESPObjects[enemy].Highlight then EnemyESPObjects[enemy].Highlight:Destroy() end
                if EnemyESPObjects[enemy].Billboard then EnemyESPObjects[enemy].Billboard:Destroy() end
            end)
            EnemyESPObjects[enemy] = nil
        end
        return
    end
    local data = EnemyESPObjects[enemy]
    if not data then
        local highlight = Instance.new("Highlight")
        highlight.Name = "VE_EnemyESP"
        highlight.FillColor = Color3.fromRGB(255, 60, 60)
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0.1
        highlight.Adornee = enemy
        highlight.Parent = CoreGui
        local bbg = Instance.new("BillboardGui")
        bbg.Name = "VE_EnemyInfo"
        bbg.Size = UDim2.new(0, 160, 0, 40)
        bbg.StudsOffset = Vector3.new(0, 3.5, 0)
        bbg.AlwaysOnTop = true
        bbg.Adornee = root
        bbg.Parent = CoreGui
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, 0, 0, 18)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
        nameLabel.TextSize = 12
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextStrokeTransparency = 0.2
        nameLabel.Parent = bbg
        local hpLabel = Instance.new("TextLabel")
        hpLabel.Size = UDim2.new(1, 0, 0, 16)
        hpLabel.Position = UDim2.new(0, 0, 0, 18)
        hpLabel.BackgroundTransparency = 1
        hpLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        hpLabel.TextSize = 10
        hpLabel.Font = Enum.Font.Gotham
        hpLabel.TextStrokeTransparency = 0.2
        hpLabel.Parent = bbg
        data = {
            Highlight = highlight,
            Billboard = bbg,
            NameLabel = nameLabel,
            HpLabel = hpLabel
        }
        EnemyESPObjects[enemy] = data
    end
    local char, _, myRoot = GetCharacterState()
    local dist = (myRoot and (myRoot.Position - root.Position).Magnitude) or 0
    data.NameLabel.Text = string.format("%s (%dm)", enemy.Name, math.floor(dist))
    data.HpLabel.Text = string.format("HP: %d / %d", math.floor(hum.Health), math.floor(hum.MaxHealth))
end
local function UpdateEnemyESP()
    if not Settings.VEEnemyESP then
        for enemy, data in pairs(EnemyESPObjects) do
            pcall(function()
                if data.Highlight then data.Highlight:Destroy() end
                if data.Billboard then data.Billboard:Destroy() end
            end)
        end
        table.clear(EnemyESPObjects)
        return
    end
    local enemies = GetEnemies()
    local seen = {}
    for _, enemy in ipairs(enemies) do
        seen[enemy] = true
        CreateOrUpdateEnemyESP(enemy)
    end
    for enemy, data in pairs(EnemyESPObjects) do
        if not seen[enemy] then
            pcall(function()
                if data.Highlight then data.Highlight:Destroy() end
                if data.Billboard then data.Billboard:Destroy() end
            end)
            EnemyESPObjects[enemy] = nil
        end
    end
end
local function CreateOrUpdatePlayerESP(plr)
    if not plr or plr == Player then return end
    local pChar = plr.Character
    if not pChar or not pChar.Parent then
        if PlayerESPObjects[plr] then
            pcall(function()
                if PlayerESPObjects[plr].Highlight then PlayerESPObjects[plr].Highlight:Destroy() end
                if PlayerESPObjects[plr].Billboard then PlayerESPObjects[plr].Billboard:Destroy() end
            end)
            PlayerESPObjects[plr] = nil
        end
        return
    end
    local root = pChar:FindFirstChild("HumanoidRootPart") or pChar.PrimaryPart
    local hum = pChar:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 then
        if PlayerESPObjects[plr] then
            pcall(function()
                if PlayerESPObjects[plr].Highlight then PlayerESPObjects[plr].Highlight:Destroy() end
                if PlayerESPObjects[plr].Billboard then PlayerESPObjects[plr].Billboard:Destroy() end
            end)
            PlayerESPObjects[plr] = nil
        end
        return
    end
    local data = PlayerESPObjects[plr]
    if not data then
        local highlight = Instance.new("Highlight")
        highlight.Name = "VE_PlayerESP"
        highlight.FillColor = Color3.fromRGB(0, 180, 255)
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0.1
        highlight.Adornee = pChar
        highlight.Parent = CoreGui
        local bbg = Instance.new("BillboardGui")
        bbg.Name = "VE_PlayerInfo"
        bbg.Size = UDim2.new(0, 150, 0, 30)
        bbg.StudsOffset = Vector3.new(0, 3.2, 0)
        bbg.AlwaysOnTop = true
        bbg.Adornee = root
        bbg.Parent = CoreGui
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, 0, 1, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextColor3 = Color3.fromRGB(0, 220, 255)
        nameLabel.TextSize = 11
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextStrokeTransparency = 0.2
        nameLabel.Parent = bbg
        data = {
            Highlight = highlight,
            Billboard = bbg,
            NameLabel = nameLabel
        }
        PlayerESPObjects[plr] = data
    end
    local _, _, myRoot = GetCharacterState()
    local dist = (myRoot and (myRoot.Position - root.Position).Magnitude) or 0
    data.NameLabel.Text = string.format("%s (%dm)", plr.DisplayName or plr.Name, math.floor(dist))
end
local function UpdatePlayerESP()
    if not Settings.VEPlayerESP then
        for plr, data in pairs(PlayerESPObjects) do
            pcall(function()
                if data.Highlight then data.Highlight:Destroy() end
                if data.Billboard then data.Billboard:Destroy() end
            end)
        end
        table.clear(PlayerESPObjects)
        return
    end
    local seen = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Player then
            seen[plr] = true
            CreateOrUpdatePlayerESP(plr)
        end
    end
    for plr, data in pairs(PlayerESPObjects) do
        if not seen[plr] then
            pcall(function()
                if data.Highlight then data.Highlight:Destroy() end
                if data.Billboard then data.Billboard:Destroy() end
            end)
            PlayerESPObjects[plr] = nil
        end
    end
end
local function ApplyFullBright(enabled)
    if enabled then
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
    else
        Lighting.Ambient = OrigLightingProps.Ambient
        Lighting.OutdoorAmbient = OrigLightingProps.OutdoorAmbient
        Lighting.Brightness = OrigLightingProps.Brightness
        Lighting.ClockTime = OrigLightingProps.ClockTime
        Lighting.FogEnd = OrigLightingProps.FogEnd
    end
end
local function RedeemAllCodes()
    local codes = { "RELEASE", "HAPPY30K", "HAPPY50K", "WORLD2", "WORLD3" }
    local redeemRemote = FindRemote({ "code", "redeem", "redeemcode", "claimcode" }, false)
        or FindRemote({ "code", "redeem", "redeemcode", "claimcode" }, true)
    if not redeemRemote then
        CustomNotify("Codes", "Code remote not found", 3)
        return
    end
    local count = 0
    for _, code in ipairs(codes) do
        pcall(function()
            if redeemRemote:IsA("RemoteFunction") then
                redeemRemote:InvokeServer(code)
            else
                redeemRemote:FireServer(code)
            end
            count = count + 1
        end)
        task.wait(0.2)
    end
    CustomNotify("Codes", string.format("Attempted %d codes", count), 3)
end
task.spawn(function()
    while CurrentGeneration == getgenv().ToxVEGeneration and not getgenv().Destroyed do
        if Settings.VEKillAura or Settings.VEFastAttack then
            local char, hum, root = GetCharacterState()
            if char and hum and root and hum.Health > 0 then
                local range = Settings.VEAuraRange or 25
                local enemies = GetEnemies()
                local closestEnemy = nil
                local closestDist = range
                for _, enemy in ipairs(enemies) do
                    local eRoot = enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart or enemy:FindFirstChildWhichIsA("BasePart")
                    if eRoot then
                        local dist = (root.Position - eRoot.Position).Magnitude
                        if dist <= range and dist < closestDist then
                            closestDist = dist
                            closestEnemy = enemy
                        end
                    end
                end
                if closestEnemy then
                    if Settings.VESafeFarm then
                        local eRoot = closestEnemy:FindFirstChild("HumanoidRootPart") or closestEnemy.PrimaryPart or closestEnemy:FindFirstChildWhichIsA("BasePart")
                        if eRoot then
                            local safePos = eRoot.Position + Vector3.new(0, 12, 0)
                            pcall(function()
                                root.AssemblyLinearVelocity = Vector3.zero
                                root.CFrame = CFrame.new(safePos, eRoot.Position)
                            end)
                        end
                    end
                    local attacks = Settings.VEFastAttack and 6 or 1
                    for i = 1, attacks do
                        TriggerAttack(closestEnemy)
                    end
                end
            end
        end
        task.wait(Settings.VEFastAttack and 0.05 or 0.2)
    end
end)
task.spawn(function()
    while CurrentGeneration == getgenv().ToxVEGeneration and not getgenv().Destroyed do
        if Settings.VEAutoTrain then
            local char, hum, root = GetCharacterState()
            if char and hum and root and hum.Health > 0 then
                local trainRemote = FindRemote({ "train", "blast", "speaker", "soundtrain", "addvenom" }, false)
                if trainRemote then
                    pcall(function()
                        trainRemote:FireServer()
                    end)
                end
                local speakers = GetTrainingSpeakers()
                if #speakers > 0 then
                    local targetSpeaker = speakers[1]
                    local spRoot = targetSpeaker:IsA("BasePart") and targetSpeaker or (targetSpeaker:FindFirstChildWhichIsA("BasePart") or targetSpeaker.PrimaryPart)
                    if spRoot then
                        local dist = (root.Position - spRoot.Position).Magnitude
                        if dist > 8 then
                            SafeTeleportTo(spRoot.CFrame + Vector3.new(0, 3, 0))
                        end
                    end
                end
            end
        end
        task.wait(0.5)
    end
end)
task.spawn(function()
    while CurrentGeneration == getgenv().ToxVEGeneration and not getgenv().Destroyed do
        if Settings.VEAutoEvolve then
            local evolveRemote = FindRemote({ "evolve", "evolution", "mutate", "symbiote" }, false)
                or FindRemote({ "evolve", "evolution", "mutate", "symbiote" }, true)
            if evolveRemote then
                pcall(function()
                    if evolveRemote:IsA("RemoteFunction") then
                        evolveRemote:InvokeServer()
                    else
                        evolveRemote:FireServer()
                    end
                end)
            end
        end
        task.wait(1.5)
    end
end)
task.spawn(function()
    while CurrentGeneration == getgenv().ToxVEGeneration and not getgenv().Destroyed do
        if Settings.VEAutoRebirth then
            local rebirthRemote = FindRemote({ "rebirth", "ascend", "prestige" }, false)
                or FindRemote({ "rebirth", "ascend", "prestige" }, true)
            if rebirthRemote then
                pcall(function()
                    if rebirthRemote:IsA("RemoteFunction") then
                        rebirthRemote:InvokeServer()
                    else
                        rebirthRemote:FireServer()
                    end
                end)
            end
        end
        task.wait(3.0)
    end
end)
task.spawn(function()
    while CurrentGeneration == getgenv().ToxVEGeneration and not getgenv().Destroyed do
        if Settings.VEAutoGifts or Settings.VEAutoSpin then
            local giftRemote = FindRemote({ "claimgift", "playtimereward", "freegift", "claimreward" }, false)
            if giftRemote then
                pcall(function()
                    for idx = 1, 12 do
                        giftRemote:FireServer(idx)
                    end
                end)
            end
            local spinRemote = FindRemote({ "spinwheel", "freespin", "wheelspin", "spin" }, false)
            if spinRemote then
                pcall(function()
                    spinRemote:FireServer()
                end)
            end
        end
        task.wait(5.0)
    end
end)
task.spawn(function()
    while CurrentGeneration == getgenv().ToxVEGeneration and not getgenv().Destroyed do
        if Settings.VEAutoOpenEggs then
            local eggRemote = FindRemote({ "openegg", "buyegg", "hatch", "egg" }, false)
                or FindRemote({ "openegg", "buyegg", "hatch", "egg" }, true)
            if eggRemote then
                pcall(function()
                    local eggName = Settings.VEEggChoice or "Starter Egg"
                    if eggRemote:IsA("RemoteFunction") then
                        eggRemote:InvokeServer(eggName, 1)
                    else
                        eggRemote:FireServer(eggName, 1)
                    end
                end)
            end
        end
        task.wait(Settings.VEFastOpen and 0.25 or 0.8)
    end
end)
task.spawn(function()
    while CurrentGeneration == getgenv().ToxVEGeneration and not getgenv().Destroyed do
        if Settings.VEAutoEquipBest then
            local equipRemote = FindRemote({ "equipbest", "bestpet", "autoequip" }, false)
            if equipRemote then
                pcall(function()
                    equipRemote:FireServer()
                end)
            end
        end
        task.wait(5.0)
    end
end)
task.spawn(function()
    while CurrentGeneration == getgenv().ToxVEGeneration and not getgenv().Destroyed do
        pcall(UpdateHitboxExpander)
        pcall(UpdateEnemyESP)
        task.wait(0.4)
    end
end)
task.spawn(function()
    while CurrentGeneration == getgenv().ToxVEGeneration and not getgenv().Destroyed do
        pcall(UpdatePlayerESP)
        task.wait(0.8)
    end
end)
TrackConnection(RunService.RenderStepped:Connect(function()
    if CurrentGeneration ~= getgenv().ToxVEGeneration or getgenv().Destroyed then return end
    if Settings.VESpeedBoost then
        local char, hum, root = GetCharacterState()
        if char and hum and root and hum.MoveDirection.Magnitude > 0 then
            local mult = math.clamp(tonumber(Settings.VESpeedMultiplier) or 1.5, 1.0, 3.5)
            local extra = hum.WalkSpeed * (mult - 1)
            local addVel = hum.MoveDirection * extra
            root.AssemblyLinearVelocity = Vector3.new(
                root.AssemblyLinearVelocity.X + (addVel.X * 0.25),
                root.AssemblyLinearVelocity.Y,
                root.AssemblyLinearVelocity.Z + (addVel.Z * 0.25)
            )
        end
    end
end))
TrackConnection(UserInputService.JumpRequest:Connect(function()
    if CurrentGeneration ~= getgenv().ToxVEGeneration or getgenv().Destroyed then return end
    if Settings.VEInfiniteJump then
        local _, hum = GetCharacterState()
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end))
TrackConnection(Player.Idled:Connect(function()
    if CurrentGeneration ~= getgenv().ToxVEGeneration or getgenv().Destroyed then return end
    if Settings.VEAntiAFK then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new(0, 0))
        end)
    end
end))
if Settings.VEFullBright then
    pcall(function() ApplyFullBright(true) end)
end
local function TrackControl(control)
    if not control then return nil end
    if VECurrentSection then
        table.insert(VECurrentSection.Controls, control)
        control.Visible = not VECurrentSection.Collapsed
    end
    return control
end
local function CreateVESection(text)
    local name = tostring(text)
    local key = string.gsub(name, "%s+", "")
    local Header = Instance.new("TextButton")
    Header.Size = UDim2.new(1, -5, 0, 24)
    Header.BackgroundColor3 = Color3.fromRGB(13, 13, 21)
    Header.BorderSizePixel = 0
    Header.Text = ""
    Header.AutoButtonColor = false
    Header.Parent = GamePage
    local HeaderCorner = Instance.new("UICorner")
    HeaderCorner.CornerRadius = UDim.new(0, 4)
    HeaderCorner.Parent = Header
    local HeaderStroke = Instance.new("UIStroke")
    HeaderStroke.Color = Color3.fromRGB(28, 28, 42)
    HeaderStroke.Thickness = 1
    HeaderStroke.Parent = Header
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
        Collapsed = Settings.VECollapsedSections[key] == true,
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
        Settings.VECollapsedSections[key] = sectionData.Collapsed
        UpdateVisuals()
        AutoSaveConfiguration()
    end)
    UpdateVisuals()
    table.insert(VESections, sectionData)
    VECurrentSection = sectionData
    return sectionData
end
local function VECreateToggle(...)
    return TrackControl(CreateToggle(...))
end
local function VECreateButton(...)
    return TrackControl(CreateButton(...))
end
local function VECreateDropdown(...)
    if CreateDropdown then
        return TrackControl(CreateDropdown(...))
    end
    return nil
end
CreateVESection("FARMING & PROGRESSION")
VECreateToggle(
    "Auto Train",
    GamePage,
    Settings.VEAutoTrain,
    function(v)
        Settings.VEAutoTrain = v == true
        AutoSaveConfiguration()
    end,
    "VEAutoTrain"
)
VECreateDropdown(
    "Training Area",
    { "Auto Best", "Area 1 - Starter", "Area 2 - Sonic", "Area 3 - Blast", "Area 4 - Mega", "Area 5 - Titan" },
    GamePage,
    Settings.VETrainArea or "Auto Best",
    function(choice)
        Settings.VETrainArea = tostring(choice)
        AutoSaveConfiguration()
    end
)
VECreateToggle(
    "Auto Evolve",
    GamePage,
    Settings.VEAutoEvolve,
    function(v)
        Settings.VEAutoEvolve = v == true
        AutoSaveConfiguration()
    end,
    "VEAutoEvolve"
)
VECreateToggle(
    "Auto Rebirth",
    GamePage,
    Settings.VEAutoRebirth,
    function(v)
        Settings.VEAutoRebirth = v == true
        AutoSaveConfiguration()
    end,
    "VEAutoRebirth"
)
VECreateToggle(
    "Auto Claim Gifts",
    GamePage,
    Settings.VEAutoGifts,
    function(v)
        Settings.VEAutoGifts = v == true
        AutoSaveConfiguration()
    end,
    "VEAutoGifts"
)
VECreateToggle(
    "Auto Spin Wheel",
    GamePage,
    Settings.VEAutoSpin,
    function(v)
        Settings.VEAutoSpin = v == true
        AutoSaveConfiguration()
    end,
    "VEAutoSpin"
)
VECreateButton(
    "Redeem All Codes",
    GamePage,
    function()
        RedeemAllCodes()
    end
)
CreateVESection("COMBAT & STAGES")
VECreateToggle(
    "Kill Aura",
    GamePage,
    Settings.VEKillAura,
    function(v)
        Settings.VEKillAura = v == true
        AutoSaveConfiguration()
    end,
    "VEKillAura"
)
VECreateToggle(
    "Fast Attack",
    GamePage,
    Settings.VEFastAttack,
    function(v)
        Settings.VEFastAttack = v == true
        AutoSaveConfiguration()
    end,
    "VEFastAttack"
)
VECreateDropdown(
    "Aura Range",
    { "15 studs", "25 studs", "40 studs", "60 studs" },
    GamePage,
    (Settings.VEAuraRange or 25) .. " studs",
    function(choice)
        local num = tonumber(string.match(choice, "%d+")) or 25
        Settings.VEAuraRange = num
        AutoSaveConfiguration()
    end
)
VECreateToggle(
    "Hitbox Expander",
    GamePage,
    Settings.VEHitboxExpander,
    function(v)
        Settings.VEHitboxExpander = v == true
        UpdateHitboxExpander()
        AutoSaveConfiguration()
    end,
    "VEHitboxExpander"
)
VECreateDropdown(
    "Hitbox Size",
    { "10 studs", "20 studs", "30 studs", "50 studs" },
    GamePage,
    (Settings.VEHitboxSize or 20) .. " studs",
    function(choice)
        local num = tonumber(string.match(choice, "%d+")) or 20
        Settings.VEHitboxSize = num
        UpdateHitboxExpander()
        AutoSaveConfiguration()
    end
)
VECreateToggle(
    "Safe Farm",
    GamePage,
    Settings.VESafeFarm,
    function(v)
        Settings.VESafeFarm = v == true
        AutoSaveConfiguration()
    end,
    "VESafeFarm"
)
CreateVESection("EGGS & PETS")
VECreateToggle(
    "Auto Open Eggs",
    GamePage,
    Settings.VEAutoOpenEggs,
    function(v)
        Settings.VEAutoOpenEggs = v == true
        AutoSaveConfiguration()
    end,
    "VEAutoOpenEggs"
)
VECreateDropdown(
    "Egg Choice",
    { "Starter Egg", "Sonic Egg", "Venom Egg", "Carnage Egg", "Riot Egg", "Void Egg" },
    GamePage,
    Settings.VEEggChoice or "Starter Egg",
    function(choice)
        Settings.VEEggChoice = tostring(choice)
        AutoSaveConfiguration()
    end
)
VECreateToggle(
    "Fast Open",
    GamePage,
    Settings.VEFastOpen,
    function(v)
        Settings.VEFastOpen = v == true
        AutoSaveConfiguration()
    end,
    "VEFastOpen"
)
VECreateToggle(
    "Auto Equip Best",
    GamePage,
    Settings.VEAutoEquipBest,
    function(v)
        Settings.VEAutoEquipBest = v == true
        AutoSaveConfiguration()
    end,
    "VEAutoEquipBest"
)
CreateVESection("TELEPORTS & WORLDS")
local SelectedWorld = "Spawn / Lobby"
VECreateDropdown(
    "World Select",
    { "Spawn / Lobby", "World 1", "World 2", "World 3", "World 4", "World 5" },
    GamePage,
    "Spawn / Lobby",
    function(choice)
        SelectedWorld = tostring(choice)
    end
)
VECreateButton(
    "Teleport to World",
    GamePage,
    function()
        local portalFolder = Workspace:FindFirstChild("Portals") or Workspace:FindFirstChild("Worlds")
        local tpTarget = nil
        if portalFolder then
            for _, item in ipairs(portalFolder:GetChildren()) do
                if string.find(string.lower(item.Name), string.lower(string.gsub(SelectedWorld, "%s+", ""))) then
                    tpTarget = item:IsA("BasePart") and item or (item:FindFirstChildWhichIsA("BasePart") or item.PrimaryPart)
                    break
                end
            end
        end
        if tpTarget then
            SafeTeleportTo(tpTarget.CFrame + Vector3.new(0, 4, 0))
            CustomNotify("Teleport", "Teleported to " .. SelectedWorld, 3)
        else
            CustomNotify("Teleport", "World portal not found in area", 3)
        end
    end
)
local SelectedArea = "Training Speakers"
VECreateDropdown(
    "Area Select",
    { "Training Speakers", "Boss Arena", "Egg Shop", "Tower Entrance", "Rebirth Station" },
    GamePage,
    "Training Speakers",
    function(choice)
        SelectedArea = tostring(choice)
    end
)
VECreateButton(
    "Teleport to Area",
    GamePage,
    function()
        local char, hum, root = GetCharacterState()
        if not root then return end
        if SelectedArea == "Training Speakers" then
            local sps = GetTrainingSpeakers()
            if #sps > 0 then
                local spRoot = sps[1]:IsA("BasePart") and sps[1] or (sps[1]:FindFirstChildWhichIsA("BasePart") or sps[1].PrimaryPart)
                if spRoot then
                    SafeTeleportTo(spRoot.CFrame + Vector3.new(0, 4, 0))
                    CustomNotify("Teleport", "Teleported to Speakers", 3)
                    return
                end
            end
        end
        local areaName = string.lower(string.gsub(SelectedArea, "%s+", ""))
        local foundPart = nil
        for _, desc in ipairs(Workspace:GetDescendants()) do
            if desc:IsA("BasePart") or desc:IsA("Model") then
                local dLow = string.lower(desc.Name)
                if string.find(dLow, areaName) then
                    foundPart = desc:IsA("BasePart") and desc or (desc:FindFirstChildWhichIsA("BasePart") or desc.PrimaryPart)
                    if foundPart then break end
                end
            end
        end
        if foundPart then
            SafeTeleportTo(foundPart.CFrame + Vector3.new(0, 4, 0))
            CustomNotify("Teleport", "Teleported to " .. SelectedArea, 3)
        else
            CustomNotify("Teleport", "Area not found nearby", 3)
        end
    end
)
CreateVESection("VISUALS & ESP")
VECreateToggle(
    "Enemy ESP",
    GamePage,
    Settings.VEEnemyESP,
    function(v)
        Settings.VEEnemyESP = v == true
        UpdateEnemyESP()
        AutoSaveConfiguration()
    end,
    "VEEnemyESP"
)
VECreateToggle(
    "Player ESP",
    GamePage,
    Settings.VEPlayerESP,
    function(v)
        Settings.VEPlayerESP = v == true
        UpdatePlayerESP()
        AutoSaveConfiguration()
    end,
    "VEPlayerESP"
)
VECreateToggle(
    "FullBright",
    GamePage,
    Settings.VEFullBright,
    function(v)
        Settings.VEFullBright = v == true
        ApplyFullBright(Settings.VEFullBright)
        AutoSaveConfiguration()
    end,
    "VEFullBright"
)
CreateVESection("MOVEMENT & UTILITIES")
VECreateToggle(
    "Speed Boost",
    GamePage,
    Settings.VESpeedBoost,
    function(v)
        Settings.VESpeedBoost = v == true
        AutoSaveConfiguration()
    end,
    "VESpeedBoost"
)
VECreateDropdown(
    "Speed Multiplier",
    { "1.5x", "2.0x", "2.5x", "3.0x" },
    GamePage,
    (Settings.VESpeedMultiplier or 1.5) .. "x",
    function(choice)
        local num = tonumber(string.match(choice, "%d+%.?%d*")) or 1.5
        Settings.VESpeedMultiplier = num
        AutoSaveConfiguration()
    end
)
VECreateToggle(
    "Infinite Jump",
    GamePage,
    Settings.VEInfiniteJump,
    function(v)
        Settings.VEInfiniteJump = v == true
        AutoSaveConfiguration()
    end,
    "VEInfiniteJump"
)
VECreateToggle(
    "Anti AFK",
    GamePage,
    Settings.VEAntiAFK,
    function(v)
        Settings.VEAntiAFK = v == true
        AutoSaveConfiguration()
    end,
    "VEAntiAFK"
)
getgenv().ToxVEModuleLoadedJobId = game.JobId
getgenv().ToxVEModuleVersion = VEModuleVersion
getgenv().ToxVEModulePage = GamePage
getgenv().ToxVECleanup = function()
    for _, conn in ipairs(VEConnections) do
        pcall(function()
            conn:Disconnect()
        end)
    end
    table.clear(VEConnections)
    for enemy, data in pairs(EnemyESPObjects) do
        pcall(function()
            if data.Highlight then data.Highlight:Destroy() end
            if data.Billboard then data.Billboard:Destroy() end
        end)
    end
    table.clear(EnemyESPObjects)
    for plr, data in pairs(PlayerESPObjects) do
        pcall(function()
            if data.Highlight then data.Highlight:Destroy() end
            if data.Billboard then data.Billboard:Destroy() end
        end)
    end
    table.clear(PlayerESPObjects)
    for part, orig in pairs(CachedHitboxes) do
        if part and part.Parent then
            pcall(function()
                part.Size = orig.Size
                part.CanCollide = orig.CanCollide
                part.Transparency = orig.Transparency
            end)
        end
    end
    table.clear(CachedHitboxes)
    pcall(function()
        ApplyFullBright(false)
    end)
    for _, sec in ipairs(VESections) do
        if sec.Header and sec.Header.Parent then
            sec.Header:Destroy()
        end
    end
    table.clear(VESections)
    VECurrentSection = nil
    getgenv().ToxVEModuleLoadedJobId = nil
    getgenv().ToxVEModuleVersion = nil
    getgenv().ToxVEModulePage = nil
end

