local SBRPlaceId = 93660722909304
if game.PlaceId ~= SBRPlaceId and tostring(game.PlaceId) ~= "93660722909304" then
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
local ProximityPromptService = game:GetService("ProximityPromptService")
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
getgenv().ToxSBRGeneration = (tonumber(getgenv().ToxSBRGeneration) or 0) + 1
local CurrentGeneration = getgenv().ToxSBRGeneration
local SBRModuleVersion = "2026-11-04-sbr-v3"
if getgenv().ToxSBRModuleLoadedJobId == game.JobId
and getgenv().ToxSBRModuleVersion == SBRModuleVersion
and getgenv().ToxSBRModulePage == GamePage
and not getgenv().Destroyed then
    return
end
if getgenv().ToxSBRCleanup then
    pcall(getgenv().ToxSBRCleanup)
end
for _, child in ipairs(GamePage:GetChildren()) do
    if child:IsA("GuiObject") then
        child:Destroy()
    end
end
Settings.SBRCollapsedSections = typeof(Settings.SBRCollapsedSections) == "table"
    and Settings.SBRCollapsedSections
    or {}
Settings.SBRInstantCollect = Settings.SBRInstantCollect == true
Settings.SBRAutoCollect = Settings.SBRAutoCollect == true
Settings.SBRCollectRange = math.clamp(tonumber(Settings.SBRCollectRange) or 15, 8, 40)
Settings.SBRMonsterESP = Settings.SBRMonsterESP == true
Settings.SBRMonsterWarn = Settings.SBRMonsterWarn == true
Settings.SBRWarnDistance = math.clamp(tonumber(Settings.SBRWarnDistance) or 60, 30, 150)
Settings.SBRMachineESP = Settings.SBRMachineESP == true
Settings.SBRItemESP = Settings.SBRItemESP == true
Settings.SBRPlayerESP = Settings.SBRPlayerESP == true
Settings.SBRFullBright = Settings.SBRFullBright == true
Settings.SBRSpeedBoost = Settings.SBRSpeedBoost == true
Settings.SBRSpeedMultiplier = math.clamp(tonumber(Settings.SBRSpeedMultiplier) or 1.35, 1.0, 2.5)
Settings.SBRInfiniteJump = Settings.SBRInfiniteJump == true
Settings.SBRAntiAFK = Settings.SBRAntiAFK == true
local SBRConnections = {}
local SBRCurrentSection = nil
local SBRSections = {}
local MonsterESPObjects = {}
local MachineESPObjects = {}
local ItemESPObjects = {}
local PlayerESPObjects = {}
local KnownPrompts = {}
local OrigHoldDurations = setmetatable({}, { __mode = "k" })
local WarnScreenGui = nil
local WarnFrame = nil
local WarnLabel = nil
local SafePlatformPart = nil
local DefaultWalkSpeed = 16
local OrigLightingProps = {
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows
}
local EstimatedScrapValues = {
    ["chip"] = 180,
    ["cpu"] = 220,
    ["circuit"] = 160,
    ["core"] = 250,
    ["crystal"] = 200,
    ["gold"] = 260,
    ["motor"] = 110,
    ["battery"] = 90,
    ["gear"] = 75,
    ["valve"] = 80,
    ["radio"] = 95,
    ["tool"] = 70,
    ["bottle"] = 35,
    ["pipe"] = 40,
    ["sheet"] = 50,
    ["plate"] = 45,
    ["bolt"] = 25,
    ["wire"] = 30,
    ["scrap"] = 50
}
local function TrackConnection(conn)
    if conn then
        table.insert(SBRConnections, conn)
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
local function ResolvePromptPart(prompt)
    if not prompt then return nil end
    local p = prompt.Parent
    if not p then return nil end
    if p:IsA("BasePart") then return p end
    if p:IsA("Attachment") and p.Parent and p.Parent:IsA("BasePart") then
        return p.Parent
    end
    if p:IsA("Model") then
        return p.PrimaryPart or p:FindFirstChildWhichIsA("BasePart", true)
    end
    local curr = p.Parent
    while curr and curr ~= Workspace and curr ~= game do
        if curr:IsA("BasePart") then return curr end
        if curr:IsA("Model") then
            local part = curr.PrimaryPart or curr:FindFirstChildWhichIsA("BasePart", true)
            if part then return part end
        end
        curr = curr.Parent
    end
    return nil
end
local function TriggerPrompt(prompt)
    if not prompt or not prompt.Parent then return false end
    pcall(function()
        prompt.HoldDuration = 0
        prompt.RequiresLineOfSight = false
    end)
    pcall(function()
        if fireproximityprompt then
            fireproximityprompt(prompt)
            fireproximityprompt(prompt, 0, true)
            fireproximityprompt(prompt, 1, true)
        end
    end)
    pcall(function()
        if prompt.InputHoldBegin and prompt.InputHoldEnd then
            prompt:InputHoldBegin()
            task.wait(0.01)
            prompt:InputHoldEnd()
        end
    end)
    pcall(function()
        if getconnections then
            for _, conn in ipairs(getconnections(prompt.Triggered)) do
                conn:Fire(Player)
            end
        end
    end)
    return true
end
local function ApplyPromptInstant(prompt)
    if not prompt or not prompt.Parent then return end
    pcall(function()
        if Settings.SBRInstantCollect then
            if OrigHoldDurations[prompt] == nil then
                OrigHoldDurations[prompt] = prompt.HoldDuration
            end
            prompt.HoldDuration = 0
            prompt.RequiresLineOfSight = false
        elseif OrigHoldDurations[prompt] ~= nil then
            prompt.HoldDuration = OrigHoldDurations[prompt]
            OrigHoldDurations[prompt] = nil
        end
    end)
end
local function IsInLobbyOrShowcase(model)
    if not model or not model.Parent then return true end
    local mName = string.lower(model.Name)
    local ignoreKeywords = {
        "showcase", "display", "statue", "sample", "amostra", "shop", "menu"
    }
    for _, kw in ipairs(ignoreKeywords) do
        if string.find(mName, kw, 1, true) then
            return true
        end
    end
    local curr = model.Parent
    while curr and curr ~= Workspace and curr ~= game do
        local pName = string.lower(curr.Name)
        for _, kw in ipairs(ignoreKeywords) do
            if string.find(pName, kw, 1, true) then
                return true
            end
        end
        curr = curr.Parent
    end
    return false
end
local function GetMonsters()
    local monsters = {}
    local char = Player.Character
    local monsterFolders = {
        Workspace:FindFirstChild("Monsters"),
        Workspace:FindFirstChild("NPCs"),
        Workspace:FindFirstChild("Baboons"),
        Workspace:FindFirstChild("Entities"),
        Workspace:FindFirstChild("Enemies")
    }
    for _, folder in ipairs(monsterFolders) do
        if folder then
            for _, item in ipairs(folder:GetChildren()) do
                if item:IsA("Model") and item ~= char and not Players:GetPlayerFromCharacter(item) then
                    if not IsInLobbyOrShowcase(item) then
                        table.insert(monsters, item)
                    end
                end
            end
        end
    end
    if #monsters == 0 then
        for _, item in ipairs(Workspace:GetChildren()) do
            if item:IsA("Model") and item ~= char and not Players:GetPlayerFromCharacter(item) then
                local hum = item:FindFirstChildOfClass("Humanoid") or item:FindFirstChildOfClass("AnimationController")
                local nLow = string.lower(item.Name)
                local matchesMonster = hum
                    or string.find(nLow, "baboon")
                    or string.find(nLow, "meatman")
                    or string.find(nLow, "fred")
                    or string.find(nLow, "larry")
                    or string.find(nLow, "mimic")
                    or string.find(nLow, "white")
                    or string.find(nLow, "monster")
                if matchesMonster and not IsInLobbyOrShowcase(item) then
                    table.insert(monsters, item)
                end
            end
        end
    end
    return monsters
end
local function ExtractScrapInfo(prompt, part)
    local name = nil
    local value = nil
    local obj = prompt and prompt.Parent or part
    local model = (part and part:FindFirstAncestorOfClass("Model")) or (obj and obj:IsA("Model") and obj) or nil
    if model and model == Workspace then model = nil end
    local checkObjects = {}
    if prompt then table.insert(checkObjects, prompt) end
    if part then table.insert(checkObjects, part) end
    if obj and obj ~= part then table.insert(checkObjects, obj) end
    if model then table.insert(checkObjects, model) end
    for _, o in ipairs(checkObjects) do
        if not value then
            for _, attr in ipairs({ "Value", "Price", "Worth", "ScrapValue", "Amount", "Cash", "Money", "Cost" }) do
                local val = o:GetAttribute(attr)
                if typeof(val) == "number" and val > 0 then
                    value = math.floor(val)
                    break
                elseif typeof(val) == "string" then
                    local num = tonumber(string.match(val, "%d+"))
                    if num and num > 0 then
                        value = num
                        break
                    end
                end
            end
        end
        if not value then
            for _, cName in ipairs({ "Value", "Price", "Worth", "ScrapValue", "Amount", "Cash" }) do
                local valObj = o:FindFirstChild(cName)
                if valObj and (valObj:IsA("IntValue") or valObj:IsA("NumberValue")) and valObj.Value > 0 then
                    value = math.floor(valObj.Value)
                    break
                elseif valObj and valObj:IsA("StringValue") then
                    local num = tonumber(string.match(valObj.Value, "%d+"))
                    if num and num > 0 then
                        value = num
                        break
                    end
                end
            end
        end
    end
    if not value and prompt then
        local txt = tostring(prompt.ObjectText or "") .. " " .. tostring(prompt.ActionText or "")
        local match = string.match(txt, "%$%s*(%d+)")
            or string.match(txt, "(%d+)%s*[sS]crap")
            or string.match(txt, "%[%s*(%d+)%s*%]")
            or string.match(txt, "%(%s*(%d+)%s*%)")
        if match then
            value = tonumber(match)
        end
    end
    if not value and (model or part) then
        local txt = (model and model.Name) or (part and part.Name) or ""
        local match = string.match(txt, "%$%s*(%d+)")
            or string.match(txt, "(%d+)%s*[sS]crap")
            or string.match(txt, "%[%s*(%d+)%s*%]")
            or string.match(txt, "%(%s*(%d+)%s*%)")
            or string.match(txt, "_(%d+)")
        if match then
            value = tonumber(match)
        end
    end
    if not value and (model or part) then
        local target = model or part
        for _, d in ipairs(target:GetDescendants()) do
            if d:IsA("TextLabel") and d.Text ~= "" then
                local match = string.match(d.Text, "%$%s*(%d+)") or string.match(d.Text, "(%d+)%s*[sS]crap")
                if match then
                    value = tonumber(match)
                    break
                end
            end
        end
    end
    if prompt and typeof(prompt.ObjectText) == "string" and prompt.ObjectText ~= "" then
        local clean = string.gsub(prompt.ObjectText, "%b()", "")
        clean = string.gsub(clean, "%b[]", "")
        clean = string.gsub(clean, "%$%d+", "")
        clean = string.match(clean, "^%s*(.-)%s*$")
        if clean and clean ~= "" then
            name = clean
        end
    end
    if not name and model and model.Name ~= "Model" and model.Name ~= "Workspace" then
        local clean = string.gsub(model.Name, "%b()", "")
        clean = string.gsub(clean, "%b[]", "")
        clean = string.gsub(clean, "_%d+", "")
        clean = string.match(clean, "^%s*(.-)%s*$")
        if clean and clean ~= "" then
            name = clean
        end
    end
    if not name and part then
        local clean = string.gsub(part.Name, "%b()", "")
        clean = string.gsub(clean, "%b[]", "")
        clean = string.gsub(clean, "_%d+", "")
        clean = string.match(clean, "^%s*(.-)%s*$")
        if clean and clean ~= "" and clean ~= "Part" and clean ~= "MeshPart" and clean ~= "Union" then
            name = clean
        end
    end
    if not name or name == "" then
        name = "Scrap"
    end
    if not value or value == 0 then
        local nameLow = string.lower(name)
        for word, est in pairs(EstimatedScrapValues) do
            if string.find(nameLow, word, 1, true) then
                value = est
                break
            end
        end
        if not value then
            value = 50
        end
    end
    return name, value
end
local function RegisterPrompt(prompt)
    if not prompt or not prompt.Parent then return end
    if KnownPrompts[prompt] then return end
    local parent = prompt.Parent
    if IsPartOfLocalPlayer(parent) then return end
    local part = ResolvePromptPart(prompt)
    if not part then return end
    local pName = string.lower(parent.Name)
    local actText = string.lower(prompt.ActionText or "")
    local objText = string.lower(prompt.ObjectText or "")
    local combined = pName .. " " .. actText .. " " .. objText
    local isIgnored = string.find(combined, "door", 1, true)
        or string.find(combined, "gate", 1, true)
        or string.find(combined, "closet", 1, true)
        or string.find(combined, "locker", 1, true)
        or string.find(combined, "hide", 1, true)
        or string.find(combined, "shop", 1, true)
        or string.find(combined, "vendor", 1, true)
    if isIgnored then return end
    local isMachine = string.find(combined, "generator", 1, true)
        or string.find(combined, "machine", 1, true)
        or string.find(combined, "fuse", 1, true)
        or string.find(combined, "terminal", 1, true)
        or string.find(combined, "power", 1, true)
        or string.find(combined, "breaker", 1, true)
        or string.find(combined, "repair", 1, true)
        or string.find(combined, "fix", 1, true)
        or string.find(combined, "lever", 1, true)
        or string.find(combined, "station", 1, true)
        or string.find(combined, "engine", 1, true)
    local itemModel = (part:FindFirstAncestorOfClass("Model") ~= Workspace and part:FindFirstAncestorOfClass("Model")) or parent
    if isMachine then
        KnownPrompts[prompt] = {
            Type = "Machine",
            Prompt = prompt,
            Part = part,
            Model = itemModel,
            Name = (prompt.ObjectText ~= "" and prompt.ObjectText) or itemModel.Name
        }
    else
        local sName, sVal = ExtractScrapInfo(prompt, part)
        KnownPrompts[prompt] = {
            Type = "Scrap",
            Prompt = prompt,
            Part = part,
            Model = itemModel,
            Name = sName,
            Value = sVal
        }
    end
    if Settings.SBRInstantCollect then
        ApplyPromptInstant(prompt)
    end
end
local function UnregisterPrompt(prompt)
    KnownPrompts[prompt] = nil
    if ItemESPObjects[prompt] then
        pcall(function()
            if ItemESPObjects[prompt].Highlight then ItemESPObjects[prompt].Highlight:Destroy() end
            if ItemESPObjects[prompt].Billboard then ItemESPObjects[prompt].Billboard:Destroy() end
        end)
        ItemESPObjects[prompt] = nil
    end
    if MachineESPObjects[prompt] then
        pcall(function()
            if MachineESPObjects[prompt].Highlight then MachineESPObjects[prompt].Highlight:Destroy() end
            if MachineESPObjects[prompt].Billboard then MachineESPObjects[prompt].Billboard:Destroy() end
        end)
        MachineESPObjects[prompt] = nil
    end
end
local function SetupWarnGui()
    if WarnScreenGui and WarnScreenGui.Parent then return end
    local screen = Instance.new("ScreenGui")
    screen.Name = "SBR_WarnGui"
    screen.ResetOnSpawn = false
    screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screen.Parent = CoreGui
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 320, 0, 42)
    frame.Position = UDim2.new(0.5, -160, 0.12, 0)
    frame.BackgroundColor3 = Color3.fromRGB(160, 20, 20)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.Parent = screen
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 60, 60)
    stroke.Thickness = 1.5
    stroke.Parent = frame
    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, -16, 1, 0)
    text.Position = UDim2.new(0, 8, 0, 0)
    text.BackgroundTransparency = 1
    text.TextColor3 = Color3.fromRGB(255, 255, 255)
    text.TextSize = 13
    text.Font = Enum.Font.GothamBold
    text.Text = "MONSTER NEARBY"
    text.Parent = frame
    WarnScreenGui = screen
    WarnFrame = frame
    WarnLabel = text
end
local function CreateOrUpdateMonsterESP(monster)
    if not monster or not monster.Parent then return end
    local root = monster:FindFirstChild("HumanoidRootPart") or monster.PrimaryPart or monster:FindFirstChildWhichIsA("BasePart")
    if not root then
        if MonsterESPObjects[monster] then
            pcall(function()
                if MonsterESPObjects[monster].Highlight then MonsterESPObjects[monster].Highlight:Destroy() end
                if MonsterESPObjects[monster].Billboard then MonsterESPObjects[monster].Billboard:Destroy() end
            end)
            MonsterESPObjects[monster] = nil
        end
        return
    end
    local data = MonsterESPObjects[monster]
    if not data then
        local highlight = Instance.new("Highlight")
        highlight.Name = "SBR_MonsterHighlight"
        highlight.FillColor = Color3.fromRGB(255, 35, 35)
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.FillTransparency = 0.4
        highlight.OutlineTransparency = 0.1
        highlight.Adornee = monster
        highlight.Parent = CoreGui
        local bbg = Instance.new("BillboardGui")
        bbg.Name = "SBR_MonsterBillboard"
        bbg.Size = UDim2.new(0, 160, 0, 32)
        bbg.StudsOffset = Vector3.new(0, 3.8, 0)
        bbg.AlwaysOnTop = true
        bbg.Adornee = root
        bbg.Parent = CoreGui
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.fromRGB(255, 60, 60)
        label.TextSize = 12
        label.Font = Enum.Font.GothamBold
        label.TextStrokeTransparency = 0.2
        label.Parent = bbg
        data = {
            Highlight = highlight,
            Billboard = bbg,
            Label = label
        }
        MonsterESPObjects[monster] = data
    end
    local _, _, myRoot = GetCharacterState()
    local dist = (myRoot and (myRoot.Position - root.Position).Magnitude) or 0
    data.Label.Text = string.format("%s (%dm)", monster.Name, math.floor(dist))
end
local function UpdateMonsterESP()
    if not Settings.SBRMonsterESP then
        for monster, data in pairs(MonsterESPObjects) do
            pcall(function()
                if data.Highlight then data.Highlight:Destroy() end
                if data.Billboard then data.Billboard:Destroy() end
            end)
        end
        table.clear(MonsterESPObjects)
        return
    end
    local monsters = GetMonsters()
    local seen = {}
    for _, mon in ipairs(monsters) do
        seen[mon] = true
        CreateOrUpdateMonsterESP(mon)
    end
    for mon, data in pairs(MonsterESPObjects) do
        if not seen[mon] then
            pcall(function()
                if data.Highlight then data.Highlight:Destroy() end
                if data.Billboard then data.Billboard:Destroy() end
            end)
            MonsterESPObjects[mon] = nil
        end
    end
end
local function CreateOrUpdateMachineESP(prompt, mData)
    if not prompt or not prompt.Parent or not mData or not mData.Part then return end
    local root = mData.Part
    local data = MachineESPObjects[prompt]
    if not data then
        local highlight = Instance.new("Highlight")
        highlight.Name = "SBR_MachineHighlight"
        highlight.FillColor = Color3.fromRGB(255, 190, 40)
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0.2
        highlight.Adornee = mData.Model or mData.Part
        highlight.Parent = CoreGui
        local bbg = Instance.new("BillboardGui")
        bbg.Name = "SBR_MachineBillboard"
        bbg.Size = UDim2.new(0, 160, 0, 28)
        bbg.StudsOffset = Vector3.new(0, 2.5, 0)
        bbg.AlwaysOnTop = true
        bbg.Adornee = root
        bbg.Parent = CoreGui
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.fromRGB(255, 210, 60)
        label.TextSize = 11
        label.Font = Enum.Font.GothamBold
        label.TextStrokeTransparency = 0.2
        label.Parent = bbg
        data = {
            Highlight = highlight,
            Billboard = bbg,
            Label = label
        }
        MachineESPObjects[prompt] = data
    end
    local _, _, myRoot = GetCharacterState()
    local dist = (myRoot and (myRoot.Position - root.Position).Magnitude) or 0
    data.Label.Text = string.format("%s (%dm)", mData.Name, math.floor(dist))
end
local function UpdateMachineESP()
    if not Settings.SBRMachineESP then
        for prompt, data in pairs(MachineESPObjects) do
            pcall(function()
                if data.Highlight then data.Highlight:Destroy() end
                if data.Billboard then data.Billboard:Destroy() end
            end)
        end
        table.clear(MachineESPObjects)
        return
    end
    local seen = {}
    for prompt, data in pairs(KnownPrompts) do
        if data.Type == "Machine" and prompt and prompt.Parent then
            seen[prompt] = true
            CreateOrUpdateMachineESP(prompt, data)
        end
    end
    for prompt, data in pairs(MachineESPObjects) do
        if not seen[prompt] then
            pcall(function()
                if data.Highlight then data.Highlight:Destroy() end
                if data.Billboard then data.Billboard:Destroy() end
            end)
            MachineESPObjects[prompt] = nil
        end
    end
end
local function CreateOrUpdateItemESP(prompt, iData)
    if not prompt or not prompt.Parent or not iData or not iData.Part then return end
    local root = iData.Part
    local data = ItemESPObjects[prompt]
    if not data then
        local highlight = Instance.new("Highlight")
        highlight.Name = "SBR_ItemHighlight"
        highlight.FillColor = Color3.fromRGB(40, 255, 120)
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.FillTransparency = 0.45
        highlight.OutlineTransparency = 0.15
        highlight.Adornee = iData.Model or iData.Part
        highlight.Parent = CoreGui
        local bbg = Instance.new("BillboardGui")
        bbg.Name = "SBR_ItemBillboard"
        bbg.Size = UDim2.new(0, 160, 0, 26)
        bbg.StudsOffset = Vector3.new(0, 1.8, 0)
        bbg.AlwaysOnTop = true
        bbg.Adornee = root
        bbg.Parent = CoreGui
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.fromRGB(60, 255, 140)
        label.TextSize = 11
        label.Font = Enum.Font.GothamBold
        label.TextStrokeTransparency = 0.2
        label.Parent = bbg
        data = {
            Highlight = highlight,
            Billboard = bbg,
            Label = label
        }
        ItemESPObjects[prompt] = data
    end
    local _, _, myRoot = GetCharacterState()
    local dist = (myRoot and (myRoot.Position - root.Position).Magnitude) or 0
    data.Label.Text = string.format("%s - $%d (%dm)", iData.Name, iData.Value or 50, math.floor(dist))
end
local function UpdateItemESP()
    if not Settings.SBRItemESP then
        for prompt, data in pairs(ItemESPObjects) do
            pcall(function()
                if data.Highlight then data.Highlight:Destroy() end
                if data.Billboard then data.Billboard:Destroy() end
            end)
        end
        table.clear(ItemESPObjects)
        return
    end
    local seen = {}
    for prompt, data in pairs(KnownPrompts) do
        if data.Type == "Scrap" and prompt and prompt.Parent then
            seen[prompt] = true
            CreateOrUpdateItemESP(prompt, data)
        end
    end
    for prompt, data in pairs(ItemESPObjects) do
        if not seen[prompt] then
            pcall(function()
                if data.Highlight then data.Highlight:Destroy() end
                if data.Billboard then data.Billboard:Destroy() end
            end)
            ItemESPObjects[prompt] = nil
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
        highlight.Name = "SBR_PlayerHighlight"
        highlight.FillColor = Color3.fromRGB(0, 180, 255)
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0.2
        highlight.Adornee = pChar
        highlight.Parent = CoreGui
        local bbg = Instance.new("BillboardGui")
        bbg.Name = "SBR_PlayerBillboard"
        bbg.Size = UDim2.new(0, 140, 0, 26)
        bbg.StudsOffset = Vector3.new(0, 3.2, 0)
        bbg.AlwaysOnTop = true
        bbg.Adornee = root
        bbg.Parent = CoreGui
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.fromRGB(0, 210, 255)
        label.TextSize = 11
        label.Font = Enum.Font.GothamBold
        label.TextStrokeTransparency = 0.2
        label.Parent = bbg
        data = {
            Highlight = highlight,
            Billboard = bbg,
            Label = label
        }
        PlayerESPObjects[plr] = data
    end
    local _, _, myRoot = GetCharacterState()
    local dist = (myRoot and (myRoot.Position - root.Position).Magnitude) or 0
    data.Label.Text = string.format("%s (%dm)", plr.DisplayName or plr.Name, math.floor(dist))
end
local function UpdatePlayerESP()
    if not Settings.SBRPlayerESP then
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
local function UpdateMonsterWarning()
    if not Settings.SBRMonsterWarn then
        if WarnFrame then
            WarnFrame.Visible = false
        end
        return
    end
    SetupWarnGui()
    local _, _, myRoot = GetCharacterState()
    if not myRoot then
        if WarnFrame then WarnFrame.Visible = false end
        return
    end
    local monsters = GetMonsters()
    local warnDist = Settings.SBRWarnDistance or 60
    local closestDist = 9999
    local closestMonster = nil
    for _, mon in ipairs(monsters) do
        local root = mon:FindFirstChild("HumanoidRootPart") or mon.PrimaryPart or mon:FindFirstChildWhichIsA("BasePart")
        if root then
            local dist = (myRoot.Position - root.Position).Magnitude
            if dist <= warnDist and dist < closestDist then
                closestDist = dist
                closestMonster = mon
            end
        end
    end
    if closestMonster and WarnFrame and WarnLabel then
        WarnFrame.Visible = true
        WarnLabel.Text = string.format("WARNING: %s IS NEARBY (%dm)", string.upper(closestMonster.Name), math.floor(closestDist))
    elseif WarnFrame then
        WarnFrame.Visible = false
    end
end
local function ApplyFullBright(enabled)
    if enabled then
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
    else
        Lighting.Ambient = OrigLightingProps.Ambient
        Lighting.OutdoorAmbient = OrigLightingProps.OutdoorAmbient
        Lighting.Brightness = OrigLightingProps.Brightness
        Lighting.ClockTime = OrigLightingProps.ClockTime
        Lighting.FogEnd = OrigLightingProps.FogEnd
        Lighting.GlobalShadows = OrigLightingProps.GlobalShadows
    end
end
local function EnforceWalkSpeed()
    local _, hum = GetCharacterState()
    if hum and hum.Health > 0 then
        if Settings.SBRSpeedBoost then
            local mult = math.clamp(tonumber(Settings.SBRSpeedMultiplier) or 1.35, 1.0, 2.5)
            local target = math.floor(DefaultWalkSpeed * mult)
            if hum.WalkSpeed ~= target then
                hum.WalkSpeed = target
            end
        elseif hum.WalkSpeed ~= DefaultWalkSpeed then
            hum.WalkSpeed = DefaultWalkSpeed
        end
    end
end
local function TriggerNearbyPrompts()
    local _, _, root = GetCharacterState()
    if not root then return end
    local range = Settings.SBRCollectRange or 15
    local triggered = 0
    for prompt, data in pairs(KnownPrompts) do
        if prompt and prompt.Parent and data.Part then
            local dist = (root.Position - data.Part.Position).Magnitude
            if dist <= range then
                TriggerPrompt(prompt)
                triggered = triggered + 1
            end
        end
    end
    if triggered > 0 then
        CustomNotify("Interact", string.format("Triggered %d prompts", triggered), 2)
    end
end
local function ToggleSafePlatform()
    local char, hum, root = GetCharacterState()
    if not root then return end
    if SafePlatformPart and SafePlatformPart.Parent then
        SafePlatformPart:Destroy()
        SafePlatformPart = nil
        CustomNotify("Safe Platform", "Safe platform removed", 2)
    else
        local plat = Instance.new("Part")
        plat.Name = "SBR_SafePlatform"
        plat.Size = Vector3.new(16, 1, 16)
        plat.Anchored = true
        plat.CanCollide = true
        plat.Transparency = 0.5
        plat.Color = Color3.fromRGB(0, 180, 255)
        plat.Material = Enum.Material.ForceField
        plat.CFrame = root.CFrame + Vector3.new(0, 25, 0)
        plat.Parent = Workspace
        SafePlatformPart = plat
        SafeTeleportTo(plat.CFrame + Vector3.new(0, 3, 0))
        CustomNotify("Safe Platform", "Teleported to safe platform", 3)
    end
end
for _, desc in ipairs(Workspace:GetDescendants()) do
    if desc:IsA("ProximityPrompt") then
        pcall(RegisterPrompt, desc)
    end
end
TrackConnection(Workspace.DescendantAdded:Connect(function(desc)
    if CurrentGeneration ~= getgenv().ToxSBRGeneration or getgenv().Destroyed then return end
    if desc:IsA("ProximityPrompt") then
        pcall(RegisterPrompt, desc)
    end
end))
TrackConnection(Workspace.DescendantRemoving:Connect(function(desc)
    if desc:IsA("ProximityPrompt") then
        pcall(UnregisterPrompt, desc)
    end
end))
TrackConnection(ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt, plr)
    if CurrentGeneration ~= getgenv().ToxSBRGeneration or getgenv().Destroyed then return end
    if plr and plr ~= Player then return end
    if Settings.SBRInstantCollect then
        TriggerPrompt(prompt)
    end
end))
TrackConnection(ProximityPromptService.PromptShown:Connect(function(prompt)
    if CurrentGeneration ~= getgenv().ToxSBRGeneration or getgenv().Destroyed then return end
    pcall(RegisterPrompt, prompt)
    if Settings.SBRInstantCollect then
        ApplyPromptInstant(prompt)
    end
end))
TrackConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if CurrentGeneration ~= getgenv().ToxSBRGeneration or getgenv().Destroyed then return end
    if not Settings.SBRInstantCollect then return end
    if input.KeyCode == Enum.KeyCode.E or input.UserInputType == Enum.UserInputType.MouseButton1 then
        local _, _, root = GetCharacterState()
        if not root then return end
        local bestPrompt = nil
        local bestDist = 14
        for prompt, data in pairs(KnownPrompts) do
            if prompt and prompt.Parent and data.Part then
                local dist = (root.Position - data.Part.Position).Magnitude
                if dist <= (prompt.MaxActivationDistance or 10) and dist < bestDist then
                    bestDist = dist
                    bestPrompt = prompt
                end
            end
        end
        if bestPrompt then
            TriggerPrompt(bestPrompt)
        end
    end
end))
TrackConnection(RunService.Heartbeat:Connect(function()
    if CurrentGeneration ~= getgenv().ToxSBRGeneration or getgenv().Destroyed then return end
    EnforceWalkSpeed()
    if Settings.SBRInstantCollect then
        local _, _, root = GetCharacterState()
        if root then
            for prompt, data in pairs(KnownPrompts) do
                if prompt and prompt.Parent and data.Part then
                    if (root.Position - data.Part.Position).Magnitude <= 16 then
                        if prompt.HoldDuration ~= 0 then
                            prompt.HoldDuration = 0
                            prompt.RequiresLineOfSight = false
                        end
                    end
                end
            end
        end
    end
end))
TrackConnection(UserInputService.JumpRequest:Connect(function()
    if CurrentGeneration ~= getgenv().ToxSBRGeneration or getgenv().Destroyed then return end
    if Settings.SBRInfiniteJump then
        local _, hum = GetCharacterState()
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end))
TrackConnection(Player.Idled:Connect(function()
    if CurrentGeneration ~= getgenv().ToxSBRGeneration or getgenv().Destroyed then return end
    if Settings.SBRAntiAFK then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new(0, 0))
        end)
    end
end))
task.spawn(function()
    while CurrentGeneration == getgenv().ToxSBRGeneration and not getgenv().Destroyed do
        if Settings.SBRAutoCollect then
            local _, _, root = GetCharacterState()
            if root then
                local range = Settings.SBRCollectRange or 15
                for prompt, data in pairs(KnownPrompts) do
                    if data.Type == "Scrap" and prompt and prompt.Parent and data.Part then
                        local dist = (root.Position - data.Part.Position).Magnitude
                        if dist <= range then
                            TriggerPrompt(prompt)
                        end
                    end
                end
            end
        end
        task.wait(0.25)
    end
end)
task.spawn(function()
    while CurrentGeneration == getgenv().ToxSBRGeneration and not getgenv().Destroyed do
        pcall(UpdateMonsterESP)
        pcall(UpdateMonsterWarning)
        task.wait(0.2)
    end
end)
task.spawn(function()
    while CurrentGeneration == getgenv().ToxSBRGeneration and not getgenv().Destroyed do
        pcall(UpdateMachineESP)
        pcall(UpdateItemESP)
        task.wait(0.35)
    end
end)
task.spawn(function()
    while CurrentGeneration == getgenv().ToxSBRGeneration and not getgenv().Destroyed do
        pcall(UpdatePlayerESP)
        task.wait(0.8)
    end
end)
if Settings.SBRFullBright then
    pcall(function() ApplyFullBright(true) end)
end
if Settings.SBRInstantCollect then
    for prompt, _ in pairs(KnownPrompts) do
        ApplyPromptInstant(prompt)
    end
end
local function TrackControl(control)
    if not control then return nil end
    if SBRCurrentSection then
        table.insert(SBRCurrentSection.Controls, control)
        control.Visible = not SBRCurrentSection.Collapsed
    end
    return control
end
local function CreateSBRSection(text)
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
        Collapsed = Settings.SBRCollapsedSections[key] == true,
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
        Settings.SBRCollapsedSections[key] = sectionData.Collapsed
        UpdateVisuals()
        AutoSaveConfiguration()
    end)
    UpdateVisuals()
    table.insert(SBRSections, sectionData)
    SBRCurrentSection = sectionData
    return sectionData
end
local function SBRCreateToggle(...)
    return TrackControl(CreateToggle(...))
end
local function SBRCreateButton(...)
    return TrackControl(CreateButton(...))
end
local function SBRCreateDropdown(...)
    if CreateDropdown then
        return TrackControl(CreateDropdown(...))
    end
    return nil
end
CreateSBRSection("INTERACTION & UTILITIES")
SBRCreateToggle(
    "Instant Collect",
    GamePage,
    Settings.SBRInstantCollect,
    function(v)
        Settings.SBRInstantCollect = v == true
        for prompt, _ in pairs(KnownPrompts) do
            ApplyPromptInstant(prompt)
        end
        AutoSaveConfiguration()
    end,
    "SBRInstantCollect"
)
SBRCreateToggle(
    "Auto Collect",
    GamePage,
    Settings.SBRAutoCollect,
    function(v)
        Settings.SBRAutoCollect = v == true
        AutoSaveConfiguration()
    end,
    "SBRAutoCollect"
)
SBRCreateDropdown(
    "Collect Range",
    { "10 studs", "15 studs", "20 studs", "30 studs" },
    GamePage,
    (Settings.SBRCollectRange or 15) .. " studs",
    function(choice)
        local num = tonumber(string.match(choice, "%d+")) or 15
        Settings.SBRCollectRange = num
        AutoSaveConfiguration()
    end
)
SBRCreateButton(
    "Trigger Nearby Prompts",
    GamePage,
    function()
        TriggerNearbyPrompts()
    end
)
CreateSBRSection("VISUALS & DETECTION")
SBRCreateToggle(
    "Monster ESP",
    GamePage,
    Settings.SBRMonsterESP,
    function(v)
        Settings.SBRMonsterESP = v == true
        UpdateMonsterESP()
        AutoSaveConfiguration()
    end,
    "SBRMonsterESP"
)
SBRCreateToggle(
    "Monster Warning",
    GamePage,
    Settings.SBRMonsterWarn,
    function(v)
        Settings.SBRMonsterWarn = v == true
        UpdateMonsterWarning()
        AutoSaveConfiguration()
    end,
    "SBRMonsterWarn"
)
SBRCreateDropdown(
    "Warn Distance",
    { "40 studs", "60 studs", "80 studs", "120 studs" },
    GamePage,
    (Settings.SBRWarnDistance or 60) .. " studs",
    function(choice)
        local num = tonumber(string.match(choice, "%d+")) or 60
        Settings.SBRWarnDistance = num
        AutoSaveConfiguration()
    end
)
SBRCreateToggle(
    "Machine ESP",
    GamePage,
    Settings.SBRMachineESP,
    function(v)
        Settings.SBRMachineESP = v == true
        UpdateMachineESP()
        AutoSaveConfiguration()
    end,
    "SBRMachineESP"
)
SBRCreateToggle(
    "Scrap ESP",
    GamePage,
    Settings.SBRItemESP,
    function(v)
        Settings.SBRItemESP = v == true
        UpdateItemESP()
        AutoSaveConfiguration()
    end,
    "SBRItemESP"
)
SBRCreateToggle(
    "Player ESP",
    GamePage,
    Settings.SBRPlayerESP,
    function(v)
        Settings.SBRPlayerESP = v == true
        UpdatePlayerESP()
        AutoSaveConfiguration()
    end,
    "SBRPlayerESP"
)
SBRCreateToggle(
    "FullBright",
    GamePage,
    Settings.SBRFullBright,
    function(v)
        Settings.SBRFullBright = v == true
        ApplyFullBright(Settings.SBRFullBright)
        AutoSaveConfiguration()
    end,
    "SBRFullBright"
)
CreateSBRSection("SURVIVAL & MOVEMENT")
SBRCreateToggle(
    "Speed Boost",
    GamePage,
    Settings.SBRSpeedBoost,
    function(v)
        Settings.SBRSpeedBoost = v == true
        EnforceWalkSpeed()
        AutoSaveConfiguration()
    end,
    "SBRSpeedBoost"
)
SBRCreateDropdown(
    "Speed Multiplier",
    { "1.2x", "1.35x", "1.5x", "1.75x", "2.0x" },
    GamePage,
    (Settings.SBRSpeedMultiplier or 1.35) .. "x",
    function(choice)
        local num = tonumber(string.match(choice, "%d+%.?%d*")) or 1.35
        Settings.SBRSpeedMultiplier = num
        EnforceWalkSpeed()
        AutoSaveConfiguration()
    end
)
SBRCreateToggle(
    "Infinite Jump",
    GamePage,
    Settings.SBRInfiniteJump,
    function(v)
        Settings.SBRInfiniteJump = v == true
        AutoSaveConfiguration()
    end,
    "SBRInfiniteJump"
)
SBRCreateButton(
    "Toggle Safe Platform",
    GamePage,
    function()
        ToggleSafePlatform()
    end
)
SBRCreateToggle(
    "Anti AFK",
    GamePage,
    Settings.SBRAntiAFK,
    function(v)
        Settings.SBRAntiAFK = v == true
        AutoSaveConfiguration()
    end,
    "SBRAntiAFK"
)
getgenv().ToxSBRModuleLoadedJobId = game.JobId
getgenv().ToxSBRModuleVersion = SBRModuleVersion
getgenv().ToxSBRModulePage = GamePage
getgenv().ToxSBRCleanup = function()
    for _, conn in ipairs(SBRConnections) do
        pcall(function()
            conn:Disconnect()
        end)
    end
    table.clear(SBRConnections)
    for mon, data in pairs(MonsterESPObjects) do
        pcall(function()
            if data.Highlight then data.Highlight:Destroy() end
            if data.Billboard then data.Billboard:Destroy() end
        end)
    end
    table.clear(MonsterESPObjects)
    for prompt, data in pairs(MachineESPObjects) do
        pcall(function()
            if data.Highlight then data.Highlight:Destroy() end
            if data.Billboard then data.Billboard:Destroy() end
        end)
    end
    table.clear(MachineESPObjects)
    for prompt, data in pairs(ItemESPObjects) do
        pcall(function()
            if data.Highlight then data.Highlight:Destroy() end
            if data.Billboard then data.Billboard:Destroy() end
        end)
    end
    table.clear(ItemESPObjects)
    for plr, data in pairs(PlayerESPObjects) do
        pcall(function()
            if data.Highlight then data.Highlight:Destroy() end
            if data.Billboard then data.Billboard:Destroy() end
        end)
    end
    table.clear(PlayerESPObjects)
    table.clear(KnownPrompts)
    for prompt, hold in pairs(OrigHoldDurations) do
        pcall(function()
            prompt.HoldDuration = hold
        end)
    end
    table.clear(OrigHoldDurations)
    local _, hum = GetCharacterState()
    if hum then
        hum.WalkSpeed = DefaultWalkSpeed
    end
    if SafePlatformPart and SafePlatformPart.Parent then
        pcall(function() SafePlatformPart:Destroy() end)
        SafePlatformPart = nil
    end
    if WarnScreenGui and WarnScreenGui.Parent then
        pcall(function() WarnScreenGui:Destroy() end)
        WarnScreenGui = nil
    end
    pcall(function()
        ApplyFullBright(false)
    end)
    for _, sec in ipairs(SBRSections) do
        if sec.Header and sec.Header.Parent then
            sec.Header:Destroy()
        end
    end
    table.clear(SBRSections)
    SBRCurrentSection = nil
    getgenv().ToxSBRModuleLoadedJobId = nil
    getgenv().ToxSBRModuleVersion = nil
    getgenv().ToxSBRModulePage = nil
end
