local env = getgenv()
if env.Destroyed then
    return
end

local ExpectedPlaceId = 72858262610964
local TSRModuleVersion = "2026-11-12-tsr-v6"
if game.PlaceId ~= ExpectedPlaceId then
    return
end

if env.ToxTSRModuleLoadedJobId == game.JobId
and env.ToxTSRModuleVersion == TSRModuleVersion
and env.ToxTSRModulePage == env.GamePage then
    return
end

if env.ToxTSRCleanup then
    pcall(env.ToxTSRCleanup)
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")

local Player = Players.LocalPlayer
local Settings = env.Settings or {}
local GamePage = env.GamePage
local AutoSaveConfiguration = env.AutoSaveConfiguration or function() end
local CustomNotify = env.CustomNotify or function() end

local CreateSection = env.CreateSection
local CreateCard = env.CreateCard
local ClearActivePageCard = env.ClearActivePageCard
local CreateToggle = env.CreateToggle
local CreateSlider = env.CreateSlider
local CreateDropdown = env.CreateDropdown
local CreateButton = env.CreateButton

if not GamePage or not CreateToggle or not CreateButton then
    return
end

local function AddSection(title, icon)
    if CreateSection then
        return CreateSection(GamePage, title, icon)
    elseif CreateCard then
        return CreateCard(GamePage, title, icon)
    end
end

for _, child in ipairs(GamePage:GetChildren()) do
    if child:IsA("GuiObject") then
        child:Destroy()
    end
end

-- ============================================================================
-- SETTINGS DEFAULTS
-- ============================================================================
if Settings.TSRAutoTap == nil then Settings.TSRAutoTap = false end
if Settings.TSRTapsPerCycle == nil then Settings.TSRTapsPerCycle = 2 end
if Settings.TSRVirtualClick == nil then Settings.TSRVirtualClick = false end
if Settings.TSRAutoBreakables == nil then Settings.TSRAutoBreakables = false end
if Settings.TSRAutoChests == nil then Settings.TSRAutoChests = false end
if Settings.TSRChestTP == nil then Settings.TSRChestTP = false end
if Settings.TSRAutoCollect == nil then Settings.TSRAutoCollect = false end
if Settings.TSRAutoRebirth == nil then Settings.TSRAutoRebirth = false end
if Settings.TSRRebirthMode == nil then Settings.TSRRebirthMode = "Best available" end
if Settings.TSRRebirthDelayTenths == nil then Settings.TSRRebirthDelayTenths = 5 end
if Settings.TSRAutoHatch == nil then Settings.TSRAutoHatch = false end
if Settings.TSREggSelected == nil then Settings.TSREggSelected = "Best available" end
if Settings.TSREggBudgetPct == nil then Settings.TSREggBudgetPct = 50 end
if Settings.TSRHatchAmount == nil then Settings.TSRHatchAmount = "Auto" end
if Settings.TSREggApproach == nil then Settings.TSREggApproach = "Teleport" end
if Settings.TSRSkipAnimation == nil then Settings.TSRSkipAnimation = false end
if Settings.TSRAutoEquipBest == nil then Settings.TSRAutoEquipBest = false end
if Settings.TSRAutoCraft == nil then Settings.TSRAutoCraft = false end
if Settings.TSRCraftTier == nil then Settings.TSRCraftTier = "Normal -> Gold" end
if Settings.TSRCraftBatchSize == nil then Settings.TSRCraftBatchSize = 5 end
if Settings.TSRAutoDeletePets == nil then Settings.TSRAutoDeletePets = false end
if Settings.TSRDeleteRarity == nil then Settings.TSRDeleteRarity = "Common" end
if Settings.TSRAutoClaim == nil then Settings.TSRAutoClaim = false end
if Settings.TSRAutoUpgrades == nil then Settings.TSRAutoUpgrades = false end
if Settings.TSRAutoLuckyDucky == nil then Settings.TSRAutoLuckyDucky = false end
if Settings.TSRAutoPetDefense == nil then Settings.TSRAutoPetDefense = false end
if Settings.TSRRelicRewardMode == nil then Settings.TSRRelicRewardMode = "Replace" end
if Settings.TSRSelectedIsland == nil then Settings.TSRSelectedIsland = "Spawn" end
if Settings.TSRAutoUnlockIslands == nil then Settings.TSRAutoUnlockIslands = false end
if Settings.TSRAutoReturnSaved == nil then Settings.TSRAutoReturnSaved = false end
if Settings.TSRInfiniteJump == nil then Settings.TSRInfiniteJump = false end
if Settings.TSRSafeSpeed == nil then Settings.TSRSafeSpeed = false end
if Settings.TSRWalkSpeed == nil then Settings.TSRWalkSpeed = 36 end
if Settings.TSRAntiAFK == nil then Settings.TSRAntiAFK = true end

local TSR = {
    Connections = {},
    Network = nil,
    EggsModule = nil,
    Replication = nil,
    PetStats = nil,
    RebirthsModule = nil,
    RebirthAmounts = {},
    RebirthIndexByAmount = {},
    RemotesByName = {},
    EventsFolder = nil,
    FunctionsFolder = nil,
    RemoteCount = 0,
    EggOptions = { "Best available" },
    EggCatalog = {},
    IslandOptions = { "Spawn" },
    IslandPositions = {},
    SavedPosition = nil,
    LastRemoteScan = 0,
    HiddenHatchTargets = {},
    Cooldowns = {
        Rebirth = 0,
        Hatch = 0,
        Claim = 0,
        Upgrade = 0,
        Equip = 0,
        Craft = 0,
        Delete = 0,
        Ducky = 0,
        Defense = 0,
        Chests = 0,
        Breakables = 0,
        Collect = 0,
        Unlock = 0
    }
}

local function IsAliveSession()
    return not env.Destroyed
        and game.PlaceId == ExpectedPlaceId
        and env.ToxTSRModuleVersion == TSRModuleVersion
end

local function TrackConn(conn)
    if conn then
        table.insert(TSR.Connections, conn)
    end
    return conn
end

local function SafeCharState()
    local char = Player.Character
    if not char or not char.Parent then
        return nil, nil, nil
    end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    return char, hum, hrp
end

local function SafeTouch(hrp, part)
    if not hrp or not part or not part.Parent then
        return false
    end
    if type(firetouchinterest) == "function" then
        pcall(firetouchinterest, hrp, part, 0)
        pcall(firetouchinterest, hrp, part, 1)
        return true
    end
    return false
end

-- ============================================================================
-- NUMBER & SUFFIX PARSING / FORMATTING
-- ============================================================================
local SuffixMultipliers = {
    k = 1e3, m = 1e6, b = 1e9, t = 1e12,
    qa = 1e15, qd = 1e15, qi = 1e18, sx = 1e21, sp = 1e24,
    oc = 1e27, no = 1e30, dc = 1e33, ud = 1e36, dd = 1e39,
    td = 1e42, tg = 1e42, qg = 1e45, qad = 1e45,
    sxq = 1e48, spq = 1e51, oq = 1e54, nq = 1e57, dcq = 1e60, sqx = 1e63
}

local SuffixDisplayOrder = {
    { 1e33, "DC" }, { 1e30, "NO" }, { 1e27, "OC" }, { 1e24, "SP" },
    { 1e21, "SX" }, { 1e18, "QI" }, { 1e15, "QD" }, { 1e12, "T" },
    { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" }
}

local function ParseAbbreviatedNumber(raw)
    if type(raw) == "number" then
        return raw
    end
    if type(raw) ~= "string" then
        return nil
    end
    local clean = string.gsub(raw, ",", "")
    clean = string.gsub(clean, "%s+", "")
    local numStr, suf = string.match(clean, "([%d%.]+)%s*([A-Za-z]*)")
    local base = tonumber(numStr)
    if not base then
        return nil
    end
    if suf and suf ~= "" then
        local mult = SuffixMultipliers[string.lower(suf)]
        if mult then
            return base * mult
        end
    end
    return base
end

local function FormatAbbreviatedNumber(num)
    local val = tonumber(num)
    if not val then
        return "?"
    end
    for _, entry in ipairs(SuffixDisplayOrder) do
        if val >= entry[1] then
            local scaled = val / entry[1]
            if scaled % 1 == 0 then
                return string.format("%.0f%s", scaled, entry[2])
            end
            return string.format("%.2f%s", scaled, entry[2])
        end
    end
    return tostring(math.floor(val))
end

local function ExtractRawEggName(label)
    if type(label) ~= "string" then
        return label
    end
    local stripped = string.match(label, "^(.-)%s*%b()$")
    if stripped and stripped ~= "" then
        return stripped
    end
    return label
end

-- ============================================================================
-- SAFE MODULE & REMOTE DISCOVERY (NO BLIND REQUIRE / NO NAMECALL HOOK)
-- ============================================================================
local function SafeRequireChild(parent, childName)
    if not parent then
        return nil
    end
    local target = parent:FindFirstChild(childName)
    if target and target:IsA("ModuleScript") then
        local ok, res = pcall(require, target)
        if ok then
            return res
        end
    end
    return nil
end

local function LoadKnownGameModules()
    local modulesFolder = ReplicatedStorage:FindFirstChild("Modules")
    if modulesFolder and not TSR.Network then
        local net = SafeRequireChild(modulesFolder, "Network")
        if type(net) == "table" and (type(net.FireServer) == "function" or type(net.InvokeServer) == "function") then
            TSR.Network = net
        end
    end

    local gameFolder = ReplicatedStorage:FindFirstChild("Game")
    if gameFolder then
        if not TSR.EggsModule then
            local eggs = SafeRequireChild(gameFolder, "Eggs")
            if type(eggs) == "table" then
                TSR.EggsModule = eggs
            end
        end
        if not TSR.Replication then
            local rep = SafeRequireChild(gameFolder, "Replication")
            if type(rep) == "table" then
                TSR.Replication = rep
            end
        end
        if not TSR.PetStats then
            local ps = SafeRequireChild(gameFolder, "PetStats")
            if type(ps) == "table" then
                TSR.PetStats = ps
            end
        end
        if not TSR.RebirthsModule then
            local reb = SafeRequireChild(gameFolder, "Rebirths")
            if type(reb) == "table" then
                TSR.RebirthsModule = reb
                if type(reb.fromIndex) == "function" and type(debug) == "table" and type(debug.getupvalues) == "function" then
                    pcall(function()
                        local upvals = debug.getupvalues(reb.fromIndex)
                        if type(upvals) == "table" and type(upvals[1]) == "table" then
                            local list = {}
                            local idxMap = {}
                            for idx, amt in pairs(upvals[1]) do
                                local nAmt = tonumber(amt)
                                local nIdx = tonumber(idx)
                                if nAmt and nIdx then
                                    idxMap[nAmt] = nIdx
                                    table.insert(list, nAmt)
                                end
                            end
                            table.sort(list)
                            TSR.RebirthAmounts = list
                            TSR.RebirthIndexByAmount = idxMap
                        end
                    end)
                end
            end
        end
    end
end

local function StoreRemoteEntry(name, remote, folder)
    if type(name) ~= "string" or name == "" or typeof(remote) ~= "Instance" then
        return
    end
    local cls = remote.ClassName
    if cls ~= "RemoteEvent" and cls ~= "RemoteFunction" and cls ~= "UnreliableRemoteEvent" then
        return
    end
    if not TSR.RemotesByName[name] then
        TSR.RemoteCount = TSR.RemoteCount + 1
    end
    TSR.RemotesByName[name] = remote
    if typeof(folder) == "Instance" then
        if folder.Name == "Events" then
            TSR.EventsFolder = folder
        elseif folder.Name == "Functions" then
            TSR.FunctionsFolder = folder
        end
    end
end

local function ScanRemotesSafe(force)
    local now = os.clock()
    if not force and (now - TSR.LastRemoteScan) < 4 then
        return
    end
    TSR.LastRemoteScan = now
    LoadKnownGameModules()

    -- Scan standard ReplicatedStorage folders cleanly
    for _, folderName in ipairs({ "Events", "Functions", "Remotes" }) do
        local folder = ReplicatedStorage:FindFirstChild(folderName)
        if folder then
            for _, child in ipairs(folder:GetChildren()) do
                local n = child.Name
                if #n > 0 and #n < 32 and not string.match(n, "^%x%x%x%x%x%x%x%x%-") and not string.match(n, "^%s+$") then
                    StoreRemoteEntry(n, child, folder)
                end
            end
        end
    end

    -- Non-destructive TapSimulator remote table discovery via getgc(true)
    if type(getgc) == "function" then
        pcall(function()
            for _, obj in ipairs(getgc(true)) do
                if type(obj) == "table" then
                    if rawget(obj, "OpenEgg") ~= nil or rawget(obj, "Tap") ~= nil then
                        for key, entry in pairs(obj) do
                            if type(entry) == "table" then
                                local rem = rawget(entry, "Remote")
                                local remName = rawget(entry, "Name") or (type(key) == "string" and key or nil)
                                local folder = rawget(entry, "Folder")
                                if typeof(rem) == "Instance" and type(remName) == "string" then
                                    StoreRemoteEntry(remName, rem, folder)
                                end
                            end
                        end
                    end
                end
            end
        end)
    end
end

local function FindRemote(name)
    if TSR.RemotesByName[name] then
        return TSR.RemotesByName[name]
    end
    local lower = string.lower(name)
    for k, rem in pairs(TSR.RemotesByName) do
        if string.lower(k) == lower then
            return rem
        end
    end
    return nil
end

local function FindRemoteMatching(patterns)
    for _, pat in ipairs(patterns) do
        local lp = string.lower(pat)
        for k, rem in pairs(TSR.RemotesByName) do
            if string.find(string.lower(k), lp, 1, true) then
                return k, rem
            end
        end
    end
    return nil, nil
end

local function CallGameRemote(mode, name, ...)
    ScanRemotesSafe(false)
    local args = { ... }

    local rem = FindRemote(name)
    if rem and rem.Parent then
        local cls = rem.ClassName
        if cls == "RemoteFunction" then
            local ok, res = pcall(function()
                return rem:InvokeServer(unpack(args))
            end)
            if ok then
                return true, res
            end
        elseif cls == "RemoteEvent" or cls == "UnreliableRemoteEvent" then
            local ok = pcall(function()
                rem:FireServer(unpack(args))
            end)
            if ok then
                return true
            end
        end
    end

    local net = TSR.Network
    if type(net) == "table" then
        if mode == "Fire" and type(net.FireServer) == "function" then
            local ok, res = pcall(function()
                return net:FireServer(name, unpack(args))
            end)
            if ok then
                return true, res
            end
        elseif type(net.InvokeServer) == "function" then
            local ok, res = pcall(function()
                return net:InvokeServer(name, unpack(args))
            end)
            if ok then
                return true, res
            end
        elseif type(net.FireServer) == "function" then
            local ok, res = pcall(function()
                return net:FireServer(name, unpack(args))
            end)
            if ok then
                return true, res
            end
        end
    end

    return false, nil
end

-- ============================================================================
-- PLAYER DATA & CURRENCY HELPERS
-- ============================================================================
local function GetCurrentClicks()
    if type(TSR.Replication) == "table" and type(TSR.Replication.Data) == "table" then
        local d = TSR.Replication.Data
        local val = tonumber(d.Clicks) or tonumber(d.Taps) or tonumber(d.Coins) or tonumber(d.Cash)
        if val then
            return val
        end
    end
    local ls = Player:FindFirstChild("leaderstats")
    if ls then
        for _, child in ipairs(ls:GetChildren()) do
            local ln = string.lower(child.Name)
            if (child:IsA("NumberValue") or child:IsA("IntValue"))
            and (string.find(ln, "click", 1, true) or string.find(ln, "tap", 1, true) or string.find(ln, "coin", 1, true)) then
                return tonumber(child.Value)
            end
        end
    end
    local pGui = Player:FindFirstChildOfClass("PlayerGui")
    if pGui then
        local sg = pGui:FindFirstChild("ScreenGui")
        local curr = sg and sg:FindFirstChild("Currencies")
        local c1 = curr and (curr:FindFirstChild("Currency1") or curr:FindFirstChild("Clicks") or curr:FindFirstChild("Taps"))
        local amt = c1 and c1:FindFirstChild("Amount")
        if amt and amt:IsA("TextLabel") then
            return ParseAbbreviatedNumber(amt.Text)
        end
    end
    return nil
end

-- ============================================================================
-- WORKSPACE SCANNERS (EGGS & ISLANDS)
-- ============================================================================
local function GetInstancePosition(obj)
    if not obj then
        return nil
    end
    if obj:IsA("BasePart") then
        return obj.Position
    end
    if obj:IsA("Model") then
        local ok, cf = pcall(function()
            return obj:GetPivot()
        end)
        if ok and typeof(cf) == "CFrame" then
            return cf.Position
        end
    end
    local part = obj:FindFirstChildWhichIsA("BasePart", true)
    return part and part.Position or nil
end

local function FindEggInWorkspace(rawEggName)
    local containers = {}
    local gameFolder = Workspace:FindFirstChild("Game")
    if gameFolder then
        table.insert(containers, gameFolder:FindFirstChild("Eggs"))
    end
    table.insert(containers, Workspace:FindFirstChild("Eggs"))
    table.insert(containers, Workspace:FindFirstChild("Capsules"))

    local lowerTarget = string.lower(rawEggName)
    for _, folder in ipairs(containers) do
        if folder then
            local direct = folder:FindFirstChild(rawEggName)
            if direct then
                return GetInstancePosition(direct)
            end
            for _, child in ipairs(folder:GetChildren()) do
                if string.lower(child.Name) == lowerTarget then
                    return GetInstancePosition(child)
                end
            end
        end
    end
    return nil
end

local function RefreshEggCatalog()
    LoadKnownGameModules()
    local entries = {}
    local seen = {}

    if type(TSR.EggsModule) == "table" then
        for eggName, info in pairs(TSR.EggsModule) do
            if type(eggName) == "string" and type(info) == "table" and not seen[eggName] then
                seen[eggName] = true
                local price = tonumber(info.Price) or tonumber(info.Cost) or ParseAbbreviatedNumber(info.Price) or 0
                table.insert(entries, {
                    Name = eggName,
                    Price = price,
                    Label = price > 0 and (eggName .. " (" .. FormatAbbreviatedNumber(price) .. ")") or eggName
                })
            end
        end
    end

    local gameFolder = Workspace:FindFirstChild("Game")
    local eggFolders = {
        gameFolder and gameFolder:FindFirstChild("Eggs") or nil,
        Workspace:FindFirstChild("Eggs")
    }
    for _, folder in ipairs(eggFolders) do
        if folder then
            for _, child in ipairs(folder:GetChildren()) do
                if not seen[child.Name] then
                    seen[child.Name] = true
                    local price = tonumber(child:GetAttribute("Price")) or tonumber(child:GetAttribute("Cost")) or 0
                    table.insert(entries, {
                        Name = child.Name,
                        Price = price,
                        Label = price > 0 and (child.Name .. " (" .. FormatAbbreviatedNumber(price) .. ")") or child.Name
                    })
                end
            end
        end
    end

    table.sort(entries, function(a, b)
        if a.Price ~= b.Price then
            return a.Price < b.Price
        end
        return a.Name < b.Name
    end)

    TSR.EggCatalog = entries
    table.clear(TSR.EggOptions)
    table.insert(TSR.EggOptions, "Best available")
    for _, entry in ipairs(entries) do
        table.insert(TSR.EggOptions, entry.Label)
    end
    return TSR.EggOptions
end

local function RefreshIslandCatalog()
    local islands = {}
    local seen = {}

    local function addIsland(name, obj)
        if type(name) ~= "string" or name == "" or seen[name] then
            return
        end
        local pos = GetInstancePosition(obj)
        if not pos then
            return
        end
        local spawnObj = obj:FindFirstChild("Spawn") or obj:FindFirstChild("Teleport") or obj:FindFirstChild("Pad")
        local spawnPos = GetInstancePosition(spawnObj) or pos
        seen[name] = true
        TSR.IslandPositions[name] = spawnPos + Vector3.new(0, 6, 0)
        table.insert(islands, name)
    end

    TSR.IslandPositions = {}
    local islFolder = Workspace:FindFirstChild("Island") or Workspace:FindFirstChild("Islands")
    if islFolder then
        for _, child in ipairs(islFolder:GetChildren()) do
            addIsland(child.Name, child)
        end
    end
    local gameFolder = Workspace:FindFirstChild("Game")
    local gameIsl = gameFolder and (gameFolder:FindFirstChild("Islands") or gameFolder:FindFirstChild("Island"))
    if gameIsl then
        for _, child in ipairs(gameIsl:GetChildren()) do
            addIsland(child.Name, child)
        end
    end

    table.sort(islands)
    table.clear(TSR.IslandOptions)
    if #islands == 0 then
        table.insert(TSR.IslandOptions, "Spawn")
    else
        for _, name in ipairs(islands) do
            table.insert(TSR.IslandOptions, name)
        end
    end
    return TSR.IslandOptions
end

local function BuildRebirthChoices()
    ScanRemotesSafe(false)
    local choices = { "Best available" }
    if #TSR.RebirthAmounts > 0 then
        for _, amt in ipairs(TSR.RebirthAmounts) do
            table.insert(choices, FormatAbbreviatedNumber(amt) .. " (" .. tostring(amt) .. ")")
        end
    else
        for _, v in ipairs({ "1", "5", "15", "50", "250", "1000" }) do
            table.insert(choices, v)
        end
    end
    return choices
end

-- ============================================================================
-- SAFE HATCH ANIMATION HIDING (NEVER BREAKS MAIN HUD)
-- ============================================================================
local function RestoreHiddenHatchTargets()
    for inst, prev in pairs(TSR.HiddenHatchTargets) do
        pcall(function()
            if inst and inst.Parent then
                if inst:IsA("ScreenGui") then
                    inst.Enabled = prev
                elseif inst:IsA("GuiObject") then
                    inst.Visible = prev
                end
            end
        end)
    end
    TSR.HiddenHatchTargets = {}
end

local function SuppressHatchAnimationFrame()
    local pGui = Player:FindFirstChildOfClass("PlayerGui")
    if pGui then
        for _, gui in ipairs(pGui:GetChildren()) do
            if gui:IsA("ScreenGui") then
                local ln = string.lower(gui.Name)
                if (string.find(ln, "egg", 1, true) or string.find(ln, "hatch", 1, true) or string.find(ln, "unbox", 1, true))
                and not gui:FindFirstChild("Currencies")
                and not gui:FindFirstChild("Menus") then
                    if gui.Enabled then
                        TSR.HiddenHatchTargets[gui] = true
                        gui.Enabled = false
                    end
                elseif ln == "screengui" then
                    for _, sub in ipairs(gui:GetChildren()) do
                        if sub:IsA("GuiObject") then
                            local sn = string.lower(sub.Name)
                            if (string.find(sn, "egghatch", 1, true) or string.find(sn, "hatchanim", 1, true) or string.find(sn, "eggopening", 1, true))
                            and sub.Visible then
                                TSR.HiddenHatchTargets[sub] = true
                                sub.Visible = false
                            end
                        end
                    end
                end
            end
        end
    end

    local cam = Workspace.CurrentCamera
    if cam then
        for _, child in ipairs(cam:GetChildren()) do
            local cn = string.lower(child.Name)
            if string.find(cn, "egg", 1, true) or string.find(cn, "hatch", 1, true) then
                pcall(function()
                    child:Destroy()
                end)
            end
        end
    end
end

-- ============================================================================
-- FEATURE ACTIONS
-- ============================================================================
local function DoAutoTap()
    local count = math.clamp(tonumber(Settings.TSRTapsPerCycle) or 2, 1, 10)
    for _ = 1, count do
        if not IsAliveSession() or not Settings.TSRAutoTap then
            break
        end
        CallGameRemote("Fire", "Tap", true, nil, true)
    end
    if Settings.TSRVirtualClick then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton1(Vector2.new(0, 0))
        end)
    end
end

local function ResolveRebirthIndex()
    local mode = tostring(Settings.TSRRebirthMode or "Best available")
    if mode ~= "Best available" then
        local parenNum = tonumber(string.match(mode, "%((%d+)%)")) or tonumber(mode)
        if parenNum and TSR.RebirthIndexByAmount[parenNum] then
            return TSR.RebirthIndexByAmount[parenNum]
        end
        if parenNum then
            return parenNum
        end
    end
    local list = TSR.RebirthAmounts
    if #list > 0 then
        local mid = math.clamp(math.floor(#list * 0.5), 1, #list)
        local amt = list[mid]
        return TSR.RebirthIndexByAmount[amt] or mid
    end
    return 1
end

local function DoAutoRebirth()
    local now = os.clock()
    local delaySec = math.clamp((tonumber(Settings.TSRRebirthDelayTenths) or 5) / 10, 0.1, 5)
    if (now - TSR.Cooldowns.Rebirth) < delaySec then
        return
    end
    TSR.Cooldowns.Rebirth = now
    local idx = ResolveRebirthIndex()
    CallGameRemote("Invoke", "Rebirth", idx)
end

local function PickTargetEgg()
    if #TSR.EggCatalog == 0 then
        RefreshEggCatalog()
    end
    local selected = tostring(Settings.TSREggSelected or "Best available")
    if selected ~= "Best available" then
        local raw = ExtractRawEggName(selected)
        for _, entry in ipairs(TSR.EggCatalog) do
            if entry.Name == raw or entry.Label == selected then
                return entry
            end
        end
        return { Name = raw, Price = 0 }
    end

    local budgetRatio = math.clamp((tonumber(Settings.TSREggBudgetPct) or 50) / 100, 0.05, 1)
    local clicks = GetCurrentClicks()
    if clicks then
        local maxSpend = clicks * budgetRatio
        local best = nil
        for _, entry in ipairs(TSR.EggCatalog) do
            if entry.Price <= maxSpend and FindEggInWorkspace(entry.Name) then
                best = entry
            end
        end
        if best then
            return best
        end
    end
    return TSR.EggCatalog[1]
end

local function ApproachEgg(eggName)
    local approach = tostring(Settings.TSREggApproach or "Teleport")
    if approach == "None" then
        return
    end
    local eggPos = FindEggInWorkspace(eggName)
    local _, hum, hrp = SafeCharState()
    if not eggPos or not hrp then
        return
    end
    local dist = (hrp.Position - eggPos).Magnitude
    if dist <= 8.5 then
        return
    end
    if approach == "Teleport" then
        hrp.CFrame = CFrame.new(eggPos + Vector3.new(0, 3.5, 4), eggPos)
    elseif approach == "Walk" and hum and hum.Health > 0 then
        hum:MoveTo(eggPos)
    end
end

local function ResolveHatchCount(eggEntry)
    local mode = tostring(Settings.TSRHatchAmount or "Auto")
    if mode ~= "Auto" then
        return tonumber(mode) or 1
    end
    local clicks = GetCurrentClicks()
    local price = eggEntry and tonumber(eggEntry.Price) or 0
    if clicks and price > 0 and clicks >= (price * 3) then
        return 3
    end
    return 1
end

local function DoAutoHatch()
    local now = os.clock()
    if (now - TSR.Cooldowns.Hatch) < 0.3 then
        return
    end
    TSR.Cooldowns.Hatch = now

    local egg = PickTargetEgg()
    if not egg or not egg.Name then
        return
    end
    ApproachEgg(egg.Name)
    local amount = ResolveHatchCount(egg)
    CallGameRemote("Invoke", "OpenEgg", egg.Name, amount)
end

local function DoFarmChests()
    local now = os.clock()
    if (now - TSR.Cooldowns.Chests) < 0.2 then
        return
    end
    TSR.Cooldowns.Chests = now
    local _, _, hrp = SafeCharState()
    if not hrp then
        return
    end

    local gameFolder = Workspace:FindFirstChild("Game")
    local worldChests = gameFolder and gameFolder:FindFirstChild("WorldChests")
    if worldChests then
        for _, v in ipairs(worldChests:GetChildren()) do
            local hitbox = v:FindFirstChild("Hitbox")
            if hitbox and hitbox:IsA("BasePart") then
                if Settings.TSRChestTP then
                    hrp.CFrame = hitbox.CFrame + Vector3.new(0, 4, 0)
                end
                SafeTouch(hrp, hitbox)
            end
        end
    end

    local islands = Workspace:FindFirstChild("Island") or Workspace:FindFirstChild("Islands")
    if islands then
        for _, island in ipairs(islands:GetChildren()) do
            local props = island:FindFirstChild("Props")
            if props then
                for _, prop in ipairs(props:GetChildren()) do
                    if prop.Name == "ClickerChest" then
                        local hitbox = prop:FindFirstChild("Hitbox")
                        if hitbox and hitbox:IsA("BasePart") then
                            if Settings.TSRChestTP then
                                hrp.CFrame = hitbox.CFrame + Vector3.new(0, 4, 0)
                            end
                            SafeTouch(hrp, hitbox)
                        end
                    end
                end
            end
        end
    end
end

local function DoAttackBreakables()
    local now = os.clock()
    if (now - TSR.Cooldowns.Breakables) < 0.2 then
        return
    end
    TSR.Cooldowns.Breakables = now
    local _, _, hrp = SafeCharState()
    if not hrp then
        return
    end

    local gameFolder = Workspace:FindFirstChild("Game")
    local folder = (gameFolder and gameFolder:FindFirstChild("Breakables")) or Workspace:FindFirstChild("Breakables")
    if not folder then
        return
    end

    local nearest, nearestDist = nil, 250
    for _, item in ipairs(folder:GetChildren()) do
        local pos = GetInstancePosition(item)
        if pos then
            local d = (hrp.Position - pos).Magnitude
            if d < nearestDist then
                nearestDist = d
                nearest = item
            end
        end
    end

    if nearest then
        local hb = nearest:FindFirstChild("Hitbox") or nearest:FindFirstChildWhichIsA("BasePart", true)
        if hb then
            SafeTouch(hrp, hb)
        end
        local remName = FindRemoteMatching({ "AttackBreakable", "DamageBreakable", "Breakable", "HitObject" })
        if remName then
            CallGameRemote("Auto", remName, nearest.Name)
            CallGameRemote("Auto", remName, nearest)
        end
    end
end

local function DoCollectDrops()
    local now = os.clock()
    if (now - TSR.Cooldowns.Collect) < 0.25 then
        return
    end
    TSR.Cooldowns.Collect = now
    local _, _, hrp = SafeCharState()
    if not hrp then
        return
    end

    local gameFolder = Workspace:FindFirstChild("Game")
    local folders = {
        gameFolder and gameFolder:FindFirstChild("Drops") or nil,
        gameFolder and gameFolder:FindFirstChild("Orbs") or nil,
        Workspace:FindFirstChild("Drops"),
        Workspace:FindFirstChild("Orbs")
    }
    for _, folder in ipairs(folders) do
        if folder then
            for _, obj in ipairs(folder:GetChildren()) do
                local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart", true)
                if part then
                    SafeTouch(hrp, part)
                end
            end
        end
    end
end

local RarityRank = {
    Common = 1,
    Uncommon = 2,
    Rare = 3,
    Epic = 4,
    Legendary = 5
}

local function DoPetManagement()
    local now = os.clock()

    if Settings.TSRAutoEquipBest and (now - TSR.Cooldowns.Equip) >= 2.5 then
        TSR.Cooldowns.Equip = now
        CallGameRemote("Invoke", "EquipBest")
    end

    if type(TSR.Replication) ~= "table" or type(TSR.Replication.Data) ~= "table" then
        return
    end
    local pets = TSR.Replication.Data.Pets
    if type(pets) ~= "table" then
        return
    end

    if Settings.TSRAutoDeletePets and (now - TSR.Cooldowns.Delete) >= 1.5 and TSR.PetStats then
        TSR.Cooldowns.Delete = now
        local threshold = RarityRank[tostring(Settings.TSRDeleteRarity or "Common")] or 1
        local deleted = 0
        for _, pet in pairs(pets) do
            if deleted >= 6 then
                break
            end
            if type(pet) == "table" and pet.Id and pet.Name and not pet.Equipped and not pet.Locked then
                local okR, rarity = pcall(function()
                    return TSR.PetStats:GetRarity(pet.Name)
                end)
                local rank = okR and RarityRank[tostring(rarity)]
                if rank and rank <= threshold then
                    CallGameRemote("Invoke", "DeletePet", tostring(pet.Id))
                    deleted = deleted + 1
                end
            end
        end
    end

    if Settings.TSRAutoCraft and (now - TSR.Cooldowns.Craft) >= 2.0 then
        TSR.Cooldowns.Craft = now
        local wantTier = Settings.TSRCraftTier == "Gold -> Rainbow" and "Golden" or "Normal"
        local batchSize = math.clamp(tonumber(Settings.TSRCraftBatchSize) or 5, 1, 6)
        local grouped = {}
        for _, pet in pairs(pets) do
            if type(pet) == "table" and pet.Id and pet.Name and not pet.Equipped and not pet.Locked then
                if pet.Tier == wantTier or Settings.TSRCraftTier == "Any Tier" then
                    grouped[pet.Name] = grouped[pet.Name] or {}
                    table.insert(grouped[pet.Name], pet.Id)
                end
            end
        end
        for _, ids in pairs(grouped) do
            if #ids >= batchSize then
                local batch = {}
                for i = 1, batchSize do
                    table.insert(batch, ids[i])
                end
                CallGameRemote("Invoke", "CraftPets", batch)
                break
            end
        end
    end
end

local function DoClaimsAndEvents()
    local now = os.clock()

    if Settings.TSRAutoClaim and (now - TSR.Cooldowns.Claim) >= 3.0 then
        TSR.Cooldowns.Claim = now
        CallGameRemote("Invoke", "ClaimRankReward")
        for _, cand in ipairs({ "ClaimDailyReward", "ClaimPlaytimeReward", "ClaimGift", "ClaimQuest", "ClaimAllGifts" }) do
            if FindRemote(cand) then
                CallGameRemote("Auto", cand)
            end
        end
    end

    if Settings.TSRAutoUpgrades and (now - TSR.Cooldowns.Upgrade) >= 2.5 then
        TSR.Cooldowns.Upgrade = now
        local upgRem = FindRemoteMatching({ "BuyUpgrade", "PurchaseUpgrade", "Upgrade" })
        if upgRem then
            for idx = 1, 5 do
                CallGameRemote("Auto", upgRem, idx)
            end
        end
    end

    if Settings.TSRAutoLuckyDucky and (now - TSR.Cooldowns.Ducky) >= 1.5 then
        TSR.Cooldowns.Ducky = now
        local _, _, hrp = SafeCharState()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and string.find(string.lower(obj.Name), "duck", 1, true) then
                SafeTouch(hrp, obj)
            end
        end
        local duckRem = FindRemoteMatching({ "LuckyDucky", "Ducky", "SpinWheel" })
        if duckRem then
            CallGameRemote("Auto", duckRem)
        end
    end

    if Settings.TSRAutoPetDefense and (now - TSR.Cooldowns.Defense) >= 1.5 then
        TSR.Cooldowns.Defense = now
        local defRem = FindRemoteMatching({ "PetDefense", "Defense" })
        if defRem then
            CallGameRemote("Auto", defRem)
        end
        local relRem = FindRemoteMatching({ "Relic" })
        if relRem then
            CallGameRemote("Auto", relRem, tostring(Settings.TSRRelicRewardMode or "Replace"))
        end
    end

    if Settings.TSRAutoUnlockIslands and (now - TSR.Cooldowns.Unlock) >= 3.0 then
        TSR.Cooldowns.Unlock = now
        local portRem = FindRemoteMatching({ "UnlockIsland", "BuyIsland", "UnlockWorld" })
        if portRem then
            for _, isl in ipairs(TSR.IslandOptions) do
                CallGameRemote("Auto", portRem, isl)
            end
        end
    end
end

-- ============================================================================
-- INITIAL DISCOVERY & UI CONSTRUCTION
-- ============================================================================
pcall(ScanRemotesSafe, true)
pcall(RefreshEggCatalog)
pcall(RefreshIslandCatalog)
local okReb, rebirthChoices = pcall(BuildRebirthChoices)
if not okReb or type(rebirthChoices) ~= "table" or #rebirthChoices == 0 then
    rebirthChoices = { "Best available", "1", "5", "15", "50", "250", "1000" }
end

do
    AddSection("Auto Tap & Farm")
    CreateToggle("Auto Tap (Real Network)", GamePage, Settings.TSRAutoTap, function(v)
        Settings.TSRAutoTap = v == true
        AutoSaveConfiguration()
    end, "TSRAutoTap")
    CreateSlider("Taps Per Cycle", GamePage, 1, 10, Settings.TSRTapsPerCycle, "", function(v)
        Settings.TSRTapsPerCycle = v
    end, "TSRTapsPerCycle")
    CreateToggle("Virtual Mouse Click (Extra)", GamePage, Settings.TSRVirtualClick, function(v)
        Settings.TSRVirtualClick = v == true
        AutoSaveConfiguration()
    end, "TSRVirtualClick")
    CreateToggle("Auto Farm World & Island Chests", GamePage, Settings.TSRAutoChests, function(v)
        Settings.TSRAutoChests = v == true
        AutoSaveConfiguration()
    end, "TSRAutoChests")
    CreateToggle("Teleport to Chests", GamePage, Settings.TSRChestTP, function(v)
        Settings.TSRChestTP = v == true
        AutoSaveConfiguration()
    end, "TSRChestTP")
    CreateToggle("Auto Attack Breakables", GamePage, Settings.TSRAutoBreakables, function(v)
        Settings.TSRAutoBreakables = v == true
        AutoSaveConfiguration()
    end, "TSRAutoBreakables")
    CreateToggle("Auto Collect Drops / Orbs", GamePage, Settings.TSRAutoCollect, function(v)
        Settings.TSRAutoCollect = v == true
        AutoSaveConfiguration()
    end, "TSRAutoCollect")
end

do
    AddSection("Auto Rebirth")
    CreateDropdown("Rebirth Tier", rebirthChoices, GamePage, Settings.TSRRebirthMode, function(opt)
        Settings.TSRRebirthMode = opt
    end)
    CreateSlider("Rebirth Delay (x0.1s)", GamePage, 1, 50, Settings.TSRRebirthDelayTenths, "", function(v)
        Settings.TSRRebirthDelayTenths = v
    end, "TSRRebirthDelayTenths")
    CreateToggle("Auto Rebirth", GamePage, Settings.TSRAutoRebirth, function(v)
        Settings.TSRAutoRebirth = v == true
        AutoSaveConfiguration()
    end, "TSRAutoRebirth")
end

do
    AddSection("Eggs & Auto Hatch")
    CreateDropdown("Select Egg", TSR.EggOptions, GamePage, Settings.TSREggSelected, function(opt)
        Settings.TSREggSelected = opt
    end)
    CreateSlider("Best Egg Budget", GamePage, 5, 100, Settings.TSREggBudgetPct, "%", function(v)
        Settings.TSREggBudgetPct = v
    end, "TSREggBudgetPct")
    CreateDropdown("Hatch Amount", { "Auto", "1", "3", "8" }, GamePage, Settings.TSRHatchAmount, function(opt)
        Settings.TSRHatchAmount = opt
    end)
    CreateDropdown("Egg Approach (~10 stud rule)", { "Teleport", "Walk", "None" }, GamePage, Settings.TSREggApproach, function(opt)
        Settings.TSREggApproach = opt
    end)
    CreateToggle("Auto Hatch", GamePage, Settings.TSRAutoHatch, function(v)
        Settings.TSRAutoHatch = v == true
        AutoSaveConfiguration()
    end, "TSRAutoHatch")
    CreateToggle("Hide Hatch Animation (Safe)", GamePage, Settings.TSRSkipAnimation, function(v)
        Settings.TSRSkipAnimation = v == true
        if not Settings.TSRSkipAnimation then
            RestoreHiddenHatchTargets()
        end
        AutoSaveConfiguration()
    end, "TSRSkipAnimation")
end

do
    AddSection("Pets, Craft & Auto Delete")
    CreateToggle("Auto Equip Best Pets", GamePage, Settings.TSRAutoEquipBest, function(v)
        Settings.TSRAutoEquipBest = v == true
        AutoSaveConfiguration()
    end, "TSRAutoEquipBest")
    CreateDropdown("Craft Tier", { "Normal -> Gold", "Gold -> Rainbow", "Any Tier" }, GamePage, Settings.TSRCraftTier, function(opt)
        Settings.TSRCraftTier = opt
    end)
    CreateSlider("Craft Batch Size", GamePage, 1, 6, Settings.TSRCraftBatchSize, "", function(v)
        Settings.TSRCraftBatchSize = v
    end, "TSRCraftBatchSize")
    CreateToggle("Auto Craft Pets", GamePage, Settings.TSRAutoCraft, function(v)
        Settings.TSRAutoCraft = v == true
        AutoSaveConfiguration()
    end, "TSRAutoCraft")
    CreateDropdown("Delete Rarity (<=)", { "Common", "Uncommon", "Rare", "Epic", "Legendary" }, GamePage, Settings.TSRDeleteRarity, function(opt)
        Settings.TSRDeleteRarity = opt
    end)
    CreateToggle("Auto Delete Unlocked Pets", GamePage, Settings.TSRAutoDeletePets, function(v)
        Settings.TSRAutoDeletePets = v == true
        AutoSaveConfiguration()
    end, "TSRAutoDeletePets")
end

do
    AddSection("Islands & Saved Position")
    CreateDropdown("Island", TSR.IslandOptions, GamePage, Settings.TSRSelectedIsland, function(opt)
        Settings.TSRSelectedIsland = opt
    end)
    CreateButton("Teleport to Island", GamePage, function()
        RefreshIslandCatalog()
        local _, _, hrp = SafeCharState()
        local targetPos = TSR.IslandPositions[Settings.TSRSelectedIsland]
        if hrp and targetPos then
            hrp.CFrame = CFrame.new(targetPos)
        else
            CustomNotify("Island position not found: " .. tostring(Settings.TSRSelectedIsland), Color3.fromRGB(255, 170, 70), 2.5)
        end
    end)
    CreateButton("Save Current Position", GamePage, function()
        local _, _, hrp = SafeCharState()
        if hrp then
            TSR.SavedPosition = hrp.CFrame
            CustomNotify("Grind position saved!", Color3.fromRGB(80, 255, 130), 2)
        end
    end)
    CreateButton("Teleport to Saved Position", GamePage, function()
        local _, _, hrp = SafeCharState()
        if hrp and TSR.SavedPosition then
            hrp.CFrame = TSR.SavedPosition
        else
            CustomNotify("Save a position first!", Color3.fromRGB(255, 170, 70), 2)
        end
    end)
    CreateToggle("Auto Unlock Islands / Portals", GamePage, Settings.TSRAutoUnlockIslands, function(v)
        Settings.TSRAutoUnlockIslands = v == true
        AutoSaveConfiguration()
    end, "TSRAutoUnlockIslands")
end

do
    AddSection("Events, Minigames & Claims")
    CreateToggle("Auto Claim Rank & Rewards", GamePage, Settings.TSRAutoClaim, function(v)
        Settings.TSRAutoClaim = v == true
        AutoSaveConfiguration()
    end, "TSRAutoClaim")
    CreateToggle("Auto Buy Upgrades", GamePage, Settings.TSRAutoUpgrades, function(v)
        Settings.TSRAutoUpgrades = v == true
        AutoSaveConfiguration()
    end, "TSRAutoUpgrades")
    CreateToggle("Auto Lucky Ducky", GamePage, Settings.TSRAutoLuckyDucky, function(v)
        Settings.TSRAutoLuckyDucky = v == true
        AutoSaveConfiguration()
    end, "TSRAutoLuckyDucky")
    CreateDropdown("Relic Reward", { "Replace", "Keep Best", "Skip" }, GamePage, Settings.TSRRelicRewardMode, function(opt)
        Settings.TSRRelicRewardMode = opt
    end)
    CreateToggle("Auto Pet Defense", GamePage, Settings.TSRAutoPetDefense, function(v)
        Settings.TSRAutoPetDefense = v == true
        AutoSaveConfiguration()
    end, "TSRAutoPetDefense")
    CreateButton("Redeem Known Codes", GamePage, function()
        local codeRem = FindRemoteMatching({ "RedeemCode", "Code", "Redeem" }) or "RedeemCode"
        for _, code in ipairs({ "30MVISITS", "HEAVEN", "SPOOKY", "BOO!" }) do
            CallGameRemote("Invoke", codeRem, code)
            task.wait(0.15)
        end
        CustomNotify("Attempted to redeem TSR codes!", Color3.fromRGB(80, 255, 130), 2.5)
    end)
end

do
    AddSection("Player & Diagnostics")
    CreateToggle("Infinite Jump", GamePage, Settings.TSRInfiniteJump, function(v)
        Settings.TSRInfiniteJump = v == true
        AutoSaveConfiguration()
    end, "TSRInfiniteJump")
    CreateToggle("Safe WalkSpeed", GamePage, Settings.TSRSafeSpeed, function(v)
        Settings.TSRSafeSpeed = v == true
        AutoSaveConfiguration()
    end, "TSRSafeSpeed")
    CreateSlider("WalkSpeed Value", GamePage, 16, 250, Settings.TSRWalkSpeed, "", function(v)
        Settings.TSRWalkSpeed = v
    end, "TSRWalkSpeed")
    CreateToggle("Anti-AFK", GamePage, Settings.TSRAntiAFK, function(v)
        Settings.TSRAntiAFK = v == true
        AutoSaveConfiguration()
    end, "TSRAntiAFK")
    CreateButton("Refresh Remotes, Eggs & Islands", GamePage, function()
        ScanRemotesSafe(true)
        RefreshEggCatalog()
        RefreshIslandCatalog()
        local msg = string.format(
            "Net:%s | Remotes:%d | Eggs:%d | Islands:%d",
            TSR.Network and "OK" or "Fallback",
            TSR.RemoteCount,
            #TSR.EggCatalog,
            #TSR.IslandOptions
        )
        CustomNotify(msg, Color3.fromRGB(100, 210, 255), 4)
    end)
    CreateButton("Rejoin Same Server", GamePage, function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Player)
    end)
end

if ClearActivePageCard then
    pcall(ClearActivePageCard, GamePage)
end

-- ============================================================================
-- BACKGROUND LOOPS (LIGHTWEIGHT, CLEAN TEARDOWN)
-- ============================================================================
TrackConn(UserInputService.JumpRequest:Connect(function()
    if not IsAliveSession() or not Settings.TSRInfiniteJump then
        return
    end
    local _, hum = SafeCharState()
    if hum then
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end))

TrackConn(Player.Idled:Connect(function()
    if not IsAliveSession() or not Settings.TSRAntiAFK then
        return
    end
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end))

TrackConn(RunService.Heartbeat:Connect(function()
    if not IsAliveSession() then
        return
    end
    if Settings.TSRSafeSpeed then
        local _, hum = SafeCharState()
        if hum and hum.Health > 0 then
            hum.WalkSpeed = tonumber(Settings.TSRWalkSpeed) or 36
        end
    end
    if Settings.TSRSkipAnimation then
        SuppressHatchAnimationFrame()
    end
end))

task.spawn(function()
    while IsAliveSession() do
        if env.ScriptLoaded then
            if Settings.TSRAutoTap then
                pcall(DoAutoTap)
            end
            if Settings.TSRAutoChests then
                pcall(DoFarmChests)
            end
            if Settings.TSRAutoBreakables then
                pcall(DoAttackBreakables)
            end
            if Settings.TSRAutoCollect then
                pcall(DoCollectDrops)
            end
            if Settings.TSRAutoRebirth then
                pcall(DoAutoRebirth)
            end
            if Settings.TSRAutoHatch then
                pcall(DoAutoHatch)
            end
            if Settings.TSRAutoEquipBest or Settings.TSRAutoDeletePets or Settings.TSRAutoCraft then
                pcall(DoPetManagement)
            end
            if Settings.TSRAutoClaim or Settings.TSRAutoUpgrades or Settings.TSRAutoLuckyDucky or Settings.TSRAutoPetDefense or Settings.TSRAutoUnlockIslands then
                pcall(DoClaimsAndEvents)
            end
        end
        task.wait(Settings.TSRAutoTap and 0.05 or 0.12)
    end
end)

env.ToxTSRCleanup = function()
    RestoreHiddenHatchTargets()
    for _, conn in ipairs(TSR.Connections) do
        pcall(function()
            conn:Disconnect()
        end)
    end
    TSR.Connections = {}
end

env.ToxTSRModuleLoadedJobId = game.JobId
env.ToxTSRModuleVersion = TSRModuleVersion
env.ToxTSRModulePage = GamePage
CustomNotify("Tap Simulator REBORN loaded!", Color3.fromRGB(80, 255, 130), 3)
