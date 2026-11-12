--[========================================================================[
    ToxHub Game Module: TSR (Tap Simulator REBORN)
    PlaceId: 72858262610964
    Version: 2026-11-12-tsr-v3
]========================================================================]
do
    local isTarget = (
        game.PlaceId == 72858262610964
        or game.GameId == 72858262610964
        or tostring(game.PlaceId) == "72858262610964"
    )
    local curMod = getgenv and getgenv().CurrentGameModule
    if not isTarget and curMod and curMod.ShortName == "TSR" then
        isTarget = true
    end
    if not isTarget then
        return
    end
end

local env = getgenv()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local Player = Players.LocalPlayer

local Settings = env.Settings
local GamePage = env.GamePage
local CreateToggle = env.CreateToggle
local CreateButton = env.CreateButton
local CreateDropdown = env.CreateDropdown
local CreateToggleWithValue = env.CreateToggleWithValue
local CreateSlider = env.CreateSlider
local CreateSection = env.CreateSection
local CustomNotify = env.CustomNotify or function() end
local AutoSaveConfiguration = env.AutoSaveConfiguration or function() end
local AddConnection = env.AddConnection or function(c) return c end

if not Settings or not GamePage or not CreateToggle or not CreateButton or not CreateDropdown then
    return
end

local TSRModuleVersion = "2026-11-12-tsr-v3"
if env.ToxTSRModuleLoadedJobId == game.JobId
and env.ToxTSRModuleVersion == TSRModuleVersion
and env.ToxTSRModulePage == GamePage
and not env.Destroyed then
    return
end

if env.ToxTSRCleanup then
    pcall(env.ToxTSRCleanup)
end

env.ToxTSRGeneration = (tonumber(env.ToxTSRGeneration) or 0) + 1
local CurrentGeneration = env.ToxTSRGeneration

for _, child in ipairs(GamePage:GetChildren()) do
    if child:IsA("GuiObject") then
        child:Destroy()
    end
end

-- ============================================================================
-- SETTINGS DEFAULTS
-- ============================================================================
Settings.TSRAutoTap = Settings.TSRAutoTap == true
Settings.TSRTapMode = tostring(Settings.TSRTapMode or "Hybrid (Remote + Click)")
Settings.TSRTapsPerCycle = math.clamp(tonumber(Settings.TSRTapsPerCycle) or 3, 1, 10)
Settings.TSRAutoBreakables = Settings.TSRAutoBreakables == true
Settings.TSRAutoCollect = Settings.TSRAutoCollect == true
Settings.TSRAutoClaim = Settings.TSRAutoClaim == true
Settings.TSRAutoRebirth = Settings.TSRAutoRebirth == true
Settings.TSRRebirthMode = tostring(Settings.TSRRebirthMode or "Best / Max")
Settings.TSRRebirthTier = math.clamp(tonumber(Settings.TSRRebirthTier) or 1, 1, 40)
Settings.TSRAutoUpgrades = Settings.TSRAutoUpgrades == true
Settings.TSRAutoHatch = Settings.TSRAutoHatch == true
Settings.TSRSelectedEgg = tostring(Settings.TSRSelectedEgg or "Best available")
Settings.TSREggBudget = math.clamp(tonumber(Settings.TSREggBudget) or 50, 1, 100)
Settings.TSRHatchAmount = tostring(Settings.TSRHatchAmount or "Auto (3 or 1)")
Settings.TSRTeleportToEgg = Settings.TSRTeleportToEgg == true
Settings.TSRAutoEquipBest = Settings.TSRAutoEquipBest == true
Settings.TSRAutoCraft = Settings.TSRAutoCraft == true
Settings.TSRMutationTarget = tostring(Settings.TSRMutationTarget or "Auto / Any")
Settings.TSRAutoDeletePets = Settings.TSRAutoDeletePets == true
Settings.TSRDeleteThreshold = tostring(Settings.TSRDeleteThreshold or "Common")
Settings.TSRSkipAnimation = Settings.TSRSkipAnimation == true
Settings.TSRAutoLuckyDucky = Settings.TSRAutoLuckyDucky == true
Settings.TSRAutoPetDefense = Settings.TSRAutoPetDefense == true
Settings.TSRRelicRewardMode = tostring(Settings.TSRRelicRewardMode or "Replace")
Settings.TSRSelectedIsland = tostring(Settings.TSRSelectedIsland or "Spawn")
Settings.TSRAutoUnlockIslands = Settings.TSRAutoUnlockIslands == true
Settings.TSRSafeSpeed = Settings.TSRSafeSpeed == true
Settings.TSRWalkSpeed = math.clamp(tonumber(Settings.TSRWalkSpeed) or 48, 16, 200)
Settings.TSRInfiniteJump = Settings.TSRInfiniteJump == true
Settings.TSRAntiAFK = Settings.TSRAntiAFK ~= false

-- ============================================================================
-- STATE & REMOTE / NETWORK RESOLVER
-- ============================================================================
local TSR = {
    Connections = {},
    NetworkModule = nil,
    Remotes = {},
    CapturedArgs = {},
    DiscoveredEggs = {},
    EggDisplayToName = {},
    EggPrices = {},
    EggPriceTexts = {},
    DiscoveredIslands = {},
    SavedFarmCFrame = typeof(Settings.TSRSavedFarmCFrame) == "CFrame" and Settings.TSRSavedFarmCFrame or nil,
    LastRemoteScan = 0,
    LastRebirthTry = 0,
    LastUpgradeTry = 0,
    LastClaimTry = 0,
    LastEquipTry = 0,
    LastCraftTry = 0,
    LastDeleteTry = 0,
    LastUnlockTry = 0,
    LastBreakableTry = 0,
    LastDuckyTry = 0,
    LastDefenseTry = 0,
}

local function IsAliveSession()
    return not env.Destroyed and env.ToxTSRGeneration == CurrentGeneration and game.PlaceId == 72858262610964
end

local function TrackConn(conn)
    if conn then
        table.insert(TSR.Connections, conn)
        pcall(AddConnection, conn)
    end
    return conn
end

local function SafeCharState()
    local char = Player and Player.Character
    if not char or not char.Parent then
        return nil, nil, nil
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
    return char, hum, root
end

local function SafeTeleportTo(targetPosOrCFrame)
    local char, _, root = SafeCharState()
    if not root or not targetPosOrCFrame then
        return false
    end
    if env.AllowToxTeleport then
        env.AllowToxTeleport(0.6, "TSR Teleport")
    end
    local cf = typeof(targetPosOrCFrame) == "CFrame"
        and targetPosOrCFrame
        or CFrame.new(targetPosOrCFrame + Vector3.new(0, 3.5, 0))
    pcall(function()
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        if char and char.PrimaryPart then
            char:PivotTo(cf)
        else
            root.CFrame = cf
        end
    end)
    return true
end

local NumberSuffixes = {
    k = 1e3, m = 1e6, b = 1e9, t = 1e12,
    qa = 1e15, qi = 1e18, qn = 1e18, sx = 1e21, sp = 1e24,
    oc = 1e27, no = 1e30, dc = 1e33, ud = 1e36, dd = 1e39,
}

local function ParseAbbrevNumber(raw)
    if typeof(raw) == "number" then
        return raw
    end
    local s = tostring(raw or ""):gsub(",", ""):gsub("%$", ""):gsub("%s+", "")
    local numStr, suf = string.match(s, "^([%d%.]+)(%a*)$")
    local base = tonumber(numStr)
    if not base then
        return tonumber(string.match(s, "([%d%.]+)"))
    end
    local mult = (suf and suf ~= "" and NumberSuffixes[string.lower(suf)]) or 1
    return base * mult
end

local function FormatAbbrevNumber(n)
    local num = tonumber(n)
    if not num or num <= 0 then return nil end
    local units = {
        { 1e24, "Sp" }, { 1e21, "Sx" }, { 1e18, "Qn" }, { 1e15, "Qa" },
        { 1e12, "T" },  { 1e9, "B" },   { 1e6, "M" },   { 1e3, "K" }
    }
    for _, u in ipairs(units) do
        if num >= u[1] then
            return string.format("%.2f%s", num / u[1], u[2])
        end
    end
    return tostring(math.floor(num + 0.5))
end

local function GetPlayerTapCurrency()
    local ls = Player and Player:FindFirstChild("leaderstats")
    if ls then
        for _, child in ipairs(ls:GetChildren()) do
            local ln = string.lower(child.Name)
            if (child:IsA("NumberValue") or child:IsA("IntValue"))
            and (string.find(ln, "tap", 1, true) or string.find(ln, "click", 1, true) or string.find(ln, "coin", 1, true) or string.find(ln, "cash", 1, true)) then
                return tonumber(child.Value) or 0
            end
        end
        for _, child in ipairs(ls:GetChildren()) do
            if child:IsA("NumberValue") or child:IsA("IntValue") then
                return tonumber(child.Value) or 0
            end
        end
    end
    for _, attrKey in ipairs({ "Clicks", "Taps", "Coins", "Cash" }) do
        local v = Player and Player:GetAttribute(attrKey)
        if tonumber(v) then return tonumber(v) end
    end
    return math.huge
end

local ActionPatterns = {
    Tap = { "tap", "click", "taps", "gain", "swing" },
    Rebirth = { "rebirth", "requestrebirth", "dorebirth" },
    Hatch = { "hatch", "buyegg", "openegg", "egg" },
    EquipBest = { "equipbest", "bestpet", "equip" },
    Craft = { "craft", "craftall", "mutate", "mutation", "golden", "rainbow", "evolve", "merge" },
    DeletePet = { "deletepet", "multidelete", "autodelete", "sellpet", "remove" },
    Breakable = { "breakable", "damage", "attack", "hit", "meteor", "chest" },
    LuckyDucky = { "duck", "luckyduck", "ducky", "minigame" },
    PetDefense = { "defense", "petdefense", "relic", "wave" },
    Upgrade = { "buyupgrade", "purchaseupgrade", "upgrade", "gemupgrade", "perk" },
    Claim = { "claim", "reward", "gift", "playtime", "daily", "quest", "achievement", "rank" },
    Teleport = { "teleport", "zone", "island", "world", "unlock" },
    Code = { "code", "redeem" },
}

local function ClassifyRemoteName(name)
    local lower = string.lower(tostring(name or ""))
    if lower == "" or lower:match("^%s+$") then
        return nil
    end
    for action, patterns in pairs(ActionPatterns) do
        for _, pat in ipairs(patterns) do
            if string.find(lower, pat, 1, true) then
                return action
            end
        end
    end
    return nil
end

local function RegisterRemoteCandidate(action, remote, keyHint)
    if not action or not remote then return end
    TSR.Remotes[action] = TSR.Remotes[action] or {}
    for _, existing in ipairs(TSR.Remotes[action]) do
        if existing == remote then
            return
        end
    end
    table.insert(TSR.Remotes[action], remote)
    if keyHint and not TSR.CapturedArgs[action] then
        TSR.CapturedArgs[action] = { KeyHint = keyHint }
    end
end

local function TryLoadNetworkModule()
    if TSR.NetworkModule then
        return TSR.NetworkModule
    end
    local candidates = {}
    local function scanForNet(container)
        if not container then return end
        for _, obj in ipairs(container:GetDescendants()) do
            if obj:IsA("ModuleScript") then
                local ln = string.lower(obj.Name)
                if string.find(ln, "network", 1, true)
                or string.find(ln, "remote", 1, true)
                or string.find(ln, "packet", 1, true)
                or string.find(ln, "bridge", 1, true) then
                    table.insert(candidates, obj)
                end
            end
        end
    end
    pcall(scanForNet, ReplicatedStorage)
    for _, mod in ipairs(candidates) do
        local ok, res = pcall(require, mod)
        if ok and typeof(res) == "table" then
            if type(res.FireServer) == "function"
            or type(res.InvokeServer) == "function"
            or type(res.Send) == "function"
            or type(res.Fire) == "function" then
                TSR.NetworkModule = res
                return res
            end
        end
    end
    return nil
end

local function ScanAllRemotes(force)
    local now = os.clock()
    if not force and (now - TSR.LastRemoteScan) < 4 then
        return
    end
    TSR.LastRemoteScan = now
    TryLoadNetworkModule()

    for _, inst in ipairs(ReplicatedStorage:GetDescendants()) do
        if inst:IsA("RemoteEvent")
        or inst:IsA("RemoteFunction")
        or inst:IsA("UnreliableRemoteEvent") then
            local action = ClassifyRemoteName(inst.Name)
            if action then
                RegisterRemoteCandidate(action, inst, inst.Name)
            end
        end
    end

    if type(getgc) == "function" then
        pcall(function()
            for _, obj in ipairs(getgc(true)) do
                if typeof(obj) == "table" then
                    for k, v in pairs(obj) do
                        if typeof(k) == "string" and typeof(v) == "Instance" then
                            if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") or v:IsA("UnreliableRemoteEvent") then
                                local act = ClassifyRemoteName(k)
                                if act then
                                    RegisterRemoteCandidate(act, v, k)
                                end
                            end
                        end
                    end
                end
            end
        end)
    end
end

do
    if type(hookmetamethod) == "function" and type(getnamecallmethod) == "function" and not env.ToxTSRHooked then
        pcall(function()
            local oldNamecall
            oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
                if env.Destroyed then
                    return oldNamecall(self, ...)
                end
                local method = getnamecallmethod()
                if (method == "FireServer" or method == "InvokeServer")
                and typeof(self) == "Instance"
                and (self:IsA("RemoteEvent") or self:IsA("RemoteFunction") or self:IsA("UnreliableRemoteEvent"))
                and not (type(checkcaller) == "function" and checkcaller()) then
                    local args = { ... }
                    local first = tostring(args[1] or "")
                    local act = ClassifyRemoteName(self.Name) or ClassifyRemoteName(first)
                    if not act and #args >= 1 and typeof(args[1]) == "boolean" and #args <= 4 then
                        act = "Tap"
                    end
                    if act then
                        RegisterRemoteCandidate(act, self, first)
                        TSR.CapturedArgs[act] = args
                    end
                end
                return oldNamecall(self, ...)
            end)
            env.ToxTSRHooked = true
        end)
    end
end

local function FireAction(action, ...)
    ScanAllRemotes(false)
    local payload = { ... }
    local fired = false

    local net = TSR.NetworkModule
    if net then
        local keysToTry = ActionPatterns[action] or { string.lower(action) }
        for _, key in ipairs(keysToTry) do
            local fn = net.FireServer or net.Send or net.Fire
            if type(fn) == "function" then
                local ok = pcall(function()
                    fn(net, key, table.unpack(payload))
                end)
                if ok then fired = true end
            end
        end
    end

    local list = TSR.Remotes[action]
    if list and #list > 0 then
        for _, remote in ipairs(list) do
            if remote and remote.Parent then
                pcall(function()
                    if remote:IsA("RemoteEvent") or remote:IsA("UnreliableRemoteEvent") then
                        remote:FireServer(table.unpack(payload))
                        fired = true
                    elseif remote:IsA("RemoteFunction") then
                        task.spawn(function()
                            pcall(function()
                                remote:InvokeServer(table.unpack(payload))
                            end)
                        end)
                        fired = true
                    end
                end)
            end
        end
    end

    if not fired and TSR.CapturedArgs[action] and TSR.Remotes[action] then
        local remote = TSR.Remotes[action][1]
        if remote and remote.Parent then
            pcall(function()
                if remote:IsA("RemoteEvent") or remote:IsA("UnreliableRemoteEvent") then
                    remote:FireServer(table.unpack(TSR.CapturedArgs[action]))
                    fired = true
                end
            end)
        end
    end

    return fired
end

-- ============================================================================
-- WORKSPACE SCANNERS (EGGS + PRICES, ISLANDS, BREAKABLES, EVENTS)
-- ============================================================================
local DefaultEggs = {
    "Basic Egg",
    "Forest Egg",
    "Desert Egg",
    "Mushroom Egg",
    "Crystal",
    "Heaven Egg",
    "Time Rift Egg",
    "Prehistoric Egg",
    "Ice Age Egg",
}

local DefaultIslands = {
    "Spawn",
    "Sky Island",
    "Autumn",
    "Mushroom",
    "Desert",
    "Crystal Cave",
    "Heaven",
    "Time Rift",
    "Prehistoric",
    "Ice Age",
}

local function GetInstanceWorldPos(inst)
    if not inst then return nil end
    if inst:IsA("BasePart") then return inst.Position end
    if inst:IsA("Model") then
        if inst.PrimaryPart then return inst.PrimaryPart.Position end
        local ok, cf = pcall(function() return inst:GetPivot() end)
        if ok and typeof(cf) == "CFrame" then return cf.Position end
        local bp = inst:FindFirstChildWhichIsA("BasePart", true)
        if bp then return bp.Position end
    end
    return nil
end

local function ExtractEggPrice(eggInst)
    if not eggInst then return nil end
    for _, attr in ipairs({ "Price", "Cost", "CostAmount", "Amount" }) do
        local v = eggInst:GetAttribute(attr)
        if tonumber(v) and tonumber(v) > 0 then
            return tonumber(v)
        end
    end
    for _, vName in ipairs({ "Price", "Cost" }) do
        local valObj = eggInst:FindFirstChild(vName, true)
        if valObj and (valObj:IsA("NumberValue") or valObj:IsA("IntValue")) and valObj.Value > 0 then
            return valObj.Value
        elseif valObj and valObj:IsA("StringValue") then
            local p = ParseAbbrevNumber(valObj.Value)
            if p and p > 0 then return p end
        end
    end
    for _, desc in ipairs(eggInst:GetDescendants()) do
        if desc:IsA("TextLabel") then
            local p = ParseAbbrevNumber(desc.Text)
            if p and p > 0 then
                return p
            end
        end
    end
    return nil
end

local function ScanEggsInWorkspace()
    local found = { "Best available" }
    local seen = { ["Best available"] = true }
    TSR.EggDisplayToName = { ["Best available"] = "Best available" }

    local function addEgg(name, obj)
        if not name or name == "" then return end
        local clean = tostring(name)
        local price = obj and ExtractEggPrice(obj) or TSR.EggPrices[clean]
        if price then
            TSR.EggPrices[clean] = price
        end
        local priceFmt = price and FormatAbbrevNumber(price) or nil
        local label = priceFmt and (clean .. " (" .. priceFmt .. ")") or clean
        if not seen[label] then
            seen[label] = true
            table.insert(found, label)
        end
        TSR.EggDisplayToName[label] = clean
        TSR.DiscoveredEggs[clean] = obj
    end

    for _, desc in ipairs(Workspace:GetDescendants()) do
        if desc:IsA("Model") or desc:IsA("BasePart") then
            local lname = string.lower(desc.Name)
            local pname = desc.Parent and string.lower(desc.Parent.Name) or ""
            if (string.find(pname, "egg", 1, true) or string.find(lname, "egg", 1, true))
            and not Players:GetPlayerFromCharacter(desc)
            and #desc.Name > 2
            and #desc.Name < 42 then
                local hasPromptOrPrice = desc:FindFirstChildOfClass("ProximityPrompt", true)
                    or desc:FindFirstChild("Price", true)
                    or desc:FindFirstChild("Cost", true)
                    or desc:FindFirstChild("BillboardGui", true)
                    or string.find(pname, "egg", 1, true)
                if hasPromptOrPrice then
                    addEgg(desc.Name, desc)
                end
            end
        end
    end

    if #found == 1 then
        for _, name in ipairs(DefaultEggs) do
            addEgg(name, nil)
        end
    end

    return found
end

local function ResolveTargetEggName()
    local rawChoice = tostring(Settings.TSRSelectedEgg or "Best available")
    local mapped = TSR.EggDisplayToName[rawChoice] or rawChoice
    if mapped ~= "Best available" then
        return mapped, TSR.EggPrices[mapped]
    end

    if next(TSR.DiscoveredEggs) == nil then
        ScanEggsInWorkspace()
    end

    local wallet = GetPlayerTapCurrency()
    local budgetPct = math.clamp(tonumber(Settings.TSREggBudget) or 50, 1, 100) / 100
    local maxSpend = (wallet == math.huge) and math.huge or (wallet * budgetPct)

    local bestEgg = nil
    local bestPrice = -1
    for eggName, eggObj in pairs(TSR.DiscoveredEggs) do
        if eggName ~= "Best available" and eggObj and eggObj.Parent then
            local price = TSR.EggPrices[eggName] or ExtractEggPrice(eggObj)
            if price and price <= maxSpend and price > bestPrice then
                bestPrice = price
                bestEgg = eggName
            end
        end
    end

    if not bestEgg then
        local _, _, root = SafeCharState()
        local bestDist = math.huge
        for eggName, eggObj in pairs(TSR.DiscoveredEggs) do
            if eggName ~= "Best available" and eggObj and eggObj.Parent then
                local pos = GetInstanceWorldPos(eggObj)
                if pos and root then
                    local d = (root.Position - pos).Magnitude
                    if d < bestDist then
                        bestDist = d
                        bestEgg = eggName
                    end
                elseif not bestEgg then
                    bestEgg = eggName
                end
            end
        end
    end

    bestEgg = bestEgg or "Basic Egg"
    return bestEgg, TSR.EggPrices[bestEgg]
end

local function ScanIslandsInWorkspace()
    local found = {}
    local seen = {}

    local function addIsland(name, obj)
        if not name or name == "" then return end
        local clean = tostring(name)
        if not seen[clean] then
            seen[clean] = true
            table.insert(found, clean)
        end
        TSR.DiscoveredIslands[clean] = obj
    end

    local containerNames = { "Worlds", "Islands", "Zones", "Portals", "Areas", "Maps", "Teleports" }
    for _, cname in ipairs(containerNames) do
        local folder = Workspace:FindFirstChild(cname)
        if folder then
            for _, child in ipairs(folder:GetChildren()) do
                if child:IsA("Model") or child:IsA("BasePart") or child:IsA("Folder") then
                    addIsland(child.Name, child)
                end
            end
        end
    end

    for _, desc in ipairs(Workspace:GetDescendants()) do
        if desc:IsA("BasePart") and (string.find(string.lower(desc.Name), "teleport", 1, true) or string.find(string.lower(desc.Name), "portal", 1, true)) then
            local label = desc.Parent and desc.Parent ~= Workspace and desc.Parent.Name or desc.Name
            if label ~= "Portals" and label ~= "Teleports" then
                addIsland(label, desc)
            end
        end
    end

    if #found == 0 then
        for _, name in ipairs(DefaultIslands) do
            addIsland(name, nil)
        end
    end

    return found
end

-- ============================================================================
-- FEATURE ACTIONS
-- ============================================================================
local function PerformTapOnce()
    local mode = Settings.TSRTapMode
    if mode ~= "Fast Click" then
        local sent = FireAction("Tap", true, nil, false)
        if not sent then
            FireAction("Tap")
        end
    end
    if mode ~= "Remote Only" then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton1(Vector2.new(0, 0))
        end)
    end
end

local function CollectNearbyDrops()
    local _, _, root = SafeCharState()
    if not root or type(firetouchinterest) ~= "function" then return end

    local folderHints = { "drops", "orbs", "coins", "gems", "pickups", "gifts", "candy", "candies", "collect", "relic" }
    for _, child in ipairs(Workspace:GetChildren()) do
        local ln = string.lower(child.Name)
        local isDropFolder = false
        for _, hint in ipairs(folderHints) do
            if string.find(ln, hint, 1, true) then
                isDropFolder = true
                break
            end
        end
        if isDropFolder then
            for _, part in ipairs(child:GetDescendants()) do
                if part:IsA("BasePart") then
                    pcall(function()
                        firetouchinterest(root, part, 0)
                        firetouchinterest(root, part, 1)
                    end)
                end
            end
        end
    end
end

local function AttackNearbyBreakables()
    if os.clock() - TSR.LastBreakableTry < 0.2 then return end
    TSR.LastBreakableTry = os.clock()

    local _, _, root = SafeCharState()
    local closestObj = nil
    local closestDist = math.huge
    for _, folderName in ipairs({ "Breakables", "Chests", "Meteors", "Objects", "Targets", "Nodes" }) do
        local folder = Workspace:FindFirstChild(folderName)
        if folder then
            for _, item in ipairs(folder:GetChildren()) do
                local pos = GetInstanceWorldPos(item)
                if pos and root then
                    local d = (root.Position - pos).Magnitude
                    if d < closestDist then
                        closestDist = d
                        closestObj = item
                    end
                elseif not closestObj then
                    closestObj = item
                end
            end
        end
    end

    if closestObj then
        FireAction("Breakable", closestObj)
        FireAction("Breakable", closestObj.Name)
        local prompt = closestObj:FindFirstChildOfClass("ProximityPrompt", true)
        if prompt and type(fireproximityprompt) == "function" then
            pcall(fireproximityprompt, prompt)
        end
    else
        FireAction("Breakable")
    end
end

local function RunLuckyDucky()
    if os.clock() - TSR.LastDuckyTry < 0.4 then return end
    TSR.LastDuckyTry = os.clock()

    local _, _, root = SafeCharState()
    for _, desc in ipairs(Workspace:GetDescendants()) do
        if desc:IsA("Model") or desc:IsA("BasePart") then
            local ln = string.lower(desc.Name)
            if string.find(ln, "ducky", 1, true) or string.find(ln, "luckyduck", 1, true) then
                local pos = GetInstanceWorldPos(desc)
                if pos and root and (root.Position - pos).Magnitude > 14 then
                    SafeTeleportTo(pos)
                end
                local prompt = desc:FindFirstChildOfClass("ProximityPrompt", true)
                if prompt and type(fireproximityprompt) == "function" then
                    pcall(fireproximityprompt, prompt)
                end
                FireAction("LuckyDucky", desc)
                FireAction("LuckyDucky")
                return
            end
        end
    end
    FireAction("LuckyDucky")
end

local function RunPetDefense()
    if os.clock() - TSR.LastDefenseTry < 0.6 then return end
    TSR.LastDefenseTry = os.clock()

    local relicChoice = tostring(Settings.TSRRelicRewardMode or "Replace")
    FireAction("PetDefense", "Start")
    FireAction("PetDefense", relicChoice)
    FireAction("PetDefense")
end

local function TriggerRebirth()
    if os.clock() - TSR.LastRebirthTry < 0.45 then return end
    TSR.LastRebirthTry = os.clock()

    if Settings.TSRRebirthMode == "Target Tier" then
        FireAction("Rebirth", Settings.TSRRebirthTier)
    elseif Settings.TSRRebirthMode == "Max / Single" then
        FireAction("Rebirth", 1)
        FireAction("Rebirth")
    else
        FireAction("Rebirth", "Max")
        FireAction("Rebirth", Settings.TSRRebirthTier)
        FireAction("Rebirth", 1)
    end
end

local function TriggerUpgrades()
    if os.clock() - TSR.LastUpgradeTry < 2.0 then return end
    TSR.LastUpgradeTry = os.clock()
    local upgradeNames = {
        "ClickMultiplier", "TapPower", "AutoClicker", "ClickSpeed",
        "EggLuck", "PetSlots", "PetStorage", "RebirthMultiplier", "WalkSpeed", "GemMultiplier"
    }
    for _, uName in ipairs(upgradeNames) do
        FireAction("Upgrade", uName)
    end
end

local function TriggerClaims()
    if os.clock() - TSR.LastClaimTry < 5.0 then return end
    TSR.LastClaimTry = os.clock()
    FireAction("Claim")
    for i = 1, 12 do
        FireAction("Claim", i)
    end
end

local function ReachEggWithin10Studs(eggPos)
    local _, hum, root = SafeCharState()
    if not eggPos or not root then
        return true
    end
    local dist = (root.Position - eggPos).Magnitude
    if dist <= 9.5 then
        return true
    end
    local approachSpot = eggPos + Vector3.new(0, 0, 4)
    if Settings.TSRTeleportToEgg then
        SafeTeleportTo(approachSpot)
        task.wait(0.05)
        return true
    elseif hum and hum.Health > 0 then
        hum:MoveTo(approachSpot)
        return false
    end
    return false
end

local function ComputeHatchCount(eggPrice)
    local amountMode = tostring(Settings.TSRHatchAmount or "Auto (3 or 1)")
    if string.find(amountMode, "Auto", 1, true) then
        if eggPrice and eggPrice > 0 then
            local wallet = GetPlayerTapCurrency()
            local budgetPct = math.clamp(tonumber(Settings.TSREggBudget) or 50, 1, 100) / 100
            if wallet == math.huge or (wallet * budgetPct) >= (eggPrice * 3) then
                return 3
            end
            return 1
        end
        return 3
    elseif string.find(amountMode, "Triple", 1, true) then
        return 3
    elseif string.find(amountMode, "Max", 1, true) then
        return 8
    end
    return 1
end

local function TriggerHatchEgg()
    local eggName, eggPrice = ResolveTargetEggName()
    local count = ComputeHatchCount(eggPrice)

    local eggObj = TSR.DiscoveredEggs[eggName]
    local eggPos = GetInstanceWorldPos(eggObj)
    if eggPos then
        local inRange = ReachEggWithin10Studs(eggPos)
        if not inRange then
            return
        end
    end

    if eggObj then
        local prompt = eggObj:FindFirstChildOfClass("ProximityPrompt", true)
        if prompt and type(fireproximityprompt) == "function" then
            pcall(fireproximityprompt, prompt)
        end
    end

    local ok = FireAction("Hatch", eggName, count)
    if not ok then
        FireAction("Hatch", eggName, count == 3)
    end
end

local function TeleportToIslandByName(name)
    local target = TSR.DiscoveredIslands[name]
    local pos = GetInstanceWorldPos(target)
    if pos then
        SafeTeleportTo(pos)
        CustomNotify("Teleported to " .. tostring(name), Color3.fromRGB(80, 255, 130), 2.5)
        return true
    end
    local fired = FireAction("Teleport", name)
    if fired then
        CustomNotify("Requested TP to " .. tostring(name), Color3.fromRGB(100, 200, 255), 2.5)
    else
        CustomNotify("Island position not found: " .. tostring(name), Color3.fromRGB(255, 180, 70), 3)
    end
    return fired
end

local ActiveCodes = {
    "30MVISITS",
    "HEAVEN",
    "SPOOKY",
    "BOO!",
    "20MVISITS",
    "10MVISITS",
    "REBORN",
    "RELEASE",
    "LUCKY",
    "UPDATE1",
    "UPDATE2",
}

local function RedeemAllCodes()
    ScanAllRemotes(true)
    for _, code in ipairs(ActiveCodes) do
        FireAction("Code", code)
        task.wait(0.12)
    end
    CustomNotify("Tried " .. tostring(#ActiveCodes) .. " active TSR codes!", Color3.fromRGB(80, 255, 130), 3)
end

-- ============================================================================
-- UI CONTROLS
-- ============================================================================
do
    local function Sec(title, icon)
        if CreateSection then
            pcall(CreateSection, GamePage, title, icon)
        end
    end

    Sec("Farm & Automation", "⚡")
    CreateToggle("Auto Tap", GamePage, Settings.TSRAutoTap, function(v)
        Settings.TSRAutoTap = v == true
        AutoSaveConfiguration()
    end, "TSRAutoTap")

    CreateDropdown("Tap Mode", { "Hybrid (Remote + Click)", "Remote Only", "Fast Click" }, GamePage, Settings.TSRTapMode, function(opt)
        Settings.TSRTapMode = opt
        AutoSaveConfiguration()
    end)

    if CreateSlider then
        CreateSlider("Taps Per Cycle", GamePage, 1, 10, Settings.TSRTapsPerCycle, "x", function(val)
            Settings.TSRTapsPerCycle = math.clamp(tonumber(val) or 3, 1, 10)
        end, "TSRTapsPerCycle")
    end

    CreateButton("Save Current Position", GamePage, function()
        local _, _, root = SafeCharState()
        if root then
            TSR.SavedFarmCFrame = root.CFrame
            Settings.TSRSavedFarmCFrame = root.CFrame
            AutoSaveConfiguration()
            CustomNotify("Saved farm position!", Color3.fromRGB(80, 255, 130), 2.5)
        else
            CustomNotify("Character not found", Color3.fromRGB(255, 180, 70), 2.5)
        end
    end)

    CreateButton("TP to Saved Position", GamePage, function()
        if TSR.SavedFarmCFrame then
            SafeTeleportTo(TSR.SavedFarmCFrame)
            CustomNotify("Returned to saved farm position!", Color3.fromRGB(100, 200, 255), 2.5)
        else
            CustomNotify("Save a position first", Color3.fromRGB(255, 180, 70), 2.5)
        end
    end)

    CreateToggle("Auto Attack Breakables", GamePage, Settings.TSRAutoBreakables, function(v)
        Settings.TSRAutoBreakables = v == true
        AutoSaveConfiguration()
    end, "TSRAutoBreakables")

    CreateToggle("Auto Collect Drops / Orbs", GamePage, Settings.TSRAutoCollect, function(v)
        Settings.TSRAutoCollect = v == true
        AutoSaveConfiguration()
    end, "TSRAutoCollect")

    CreateToggle("Auto Claim Rewards / Gifts", GamePage, Settings.TSRAutoClaim, function(v)
        Settings.TSRAutoClaim = v == true
        AutoSaveConfiguration()
    end, "TSRAutoClaim")

    Sec("Rebirth & Upgrades", "🔄")
    CreateToggle("Auto Rebirth", GamePage, Settings.TSRAutoRebirth, function(v)
        Settings.TSRAutoRebirth = v == true
        AutoSaveConfiguration()
    end, "TSRAutoRebirth")

    CreateDropdown("Rebirth Mode", { "Best / Max", "Max / Single", "Target Tier" }, GamePage, Settings.TSRRebirthMode, function(opt)
        Settings.TSRRebirthMode = opt
        AutoSaveConfiguration()
    end)

    if CreateSlider then
        CreateSlider("Target Rebirth Tier", GamePage, 1, 40, Settings.TSRRebirthTier, "", function(val)
            Settings.TSRRebirthTier = math.clamp(tonumber(val) or 1, 1, 40)
        end, "TSRRebirthTier")
    end

    CreateToggle("Auto Buy Gem Upgrades", GamePage, Settings.TSRAutoUpgrades, function(v)
        Settings.TSRAutoUpgrades = v == true
        AutoSaveConfiguration()
    end, "TSRAutoUpgrades")

    Sec("Eggs & Auto Hatch", "🥚")
    local initialEggs = ScanEggsInWorkspace()
    if not TSR.EggDisplayToName[Settings.TSRSelectedEgg] then
        Settings.TSRSelectedEgg = "Best available"
    end

    CreateDropdown("Select Egg", initialEggs, GamePage, Settings.TSRSelectedEgg, function(opt)
        Settings.TSRSelectedEgg = tostring(opt)
        AutoSaveConfiguration()
    end)

    if CreateSlider then
        CreateSlider("Egg Budget", GamePage, 1, 100, Settings.TSREggBudget, "%", function(val)
            Settings.TSREggBudget = math.clamp(tonumber(val) or 50, 1, 100)
        end, "TSREggBudget")
    end

    CreateDropdown("Hatch Amount", { "Auto (3 or 1)", "Single (1)", "Triple (3)", "Max (8)" }, GamePage, Settings.TSRHatchAmount, function(opt)
        Settings.TSRHatchAmount = opt
        AutoSaveConfiguration()
    end)

    CreateToggle("Auto Hatch", GamePage, Settings.TSRAutoHatch, function(v)
        Settings.TSRAutoHatch = v == true
        AutoSaveConfiguration()
    end, "TSRAutoHatch")

    CreateToggle("Auto TP Egg", GamePage, Settings.TSRTeleportToEgg, function(v)
        Settings.TSRTeleportToEgg = v == true
        AutoSaveConfiguration()
    end, "TSRTeleportToEgg")

    CreateToggle("Hide Egg Hatch Animation", GamePage, Settings.TSRSkipAnimation, function(v)
        Settings.TSRSkipAnimation = v == true
        AutoSaveConfiguration()
    end, "TSRSkipAnimation")

    CreateButton("TP to Selected Egg Now", GamePage, function()
        ScanEggsInWorkspace()
        local eggName = ResolveTargetEggName()
        local pos = GetInstanceWorldPos(TSR.DiscoveredEggs[eggName])
        if pos then
            SafeTeleportTo(pos + Vector3.new(0, 3, 4))
            CustomNotify("Teleported to " .. tostring(eggName), Color3.fromRGB(80, 255, 130), 2.5)
        else
            CustomNotify("Egg not found in current world", Color3.fromRGB(255, 180, 70), 3)
        end
    end)

    Sec("Pets, Crafting & Delete", "✨")
    CreateToggle("Auto Equip Best Pets", GamePage, Settings.TSRAutoEquipBest, function(v)
        Settings.TSRAutoEquipBest = v == true
        AutoSaveConfiguration()
    end, "TSRAutoEquipBest")

    CreateButton("Equip Best Pets Now", GamePage, function()
        FireAction("EquipBest")
        CustomNotify("Requested Equip Best!", Color3.fromRGB(100, 200, 255), 2)
    end)

    CreateToggle("Auto Craft / Mutate Pets", GamePage, Settings.TSRAutoCraft, function(v)
        Settings.TSRAutoCraft = v == true
        AutoSaveConfiguration()
    end, "TSRAutoCraft")

    CreateDropdown("Mutation Target", { "Auto / Any", "Golden", "Rainbow", "Shiny", "Void" }, GamePage, Settings.TSRMutationTarget, function(opt)
        Settings.TSRMutationTarget = opt
        AutoSaveConfiguration()
    end)

    CreateToggle("Auto Delete Pets", GamePage, Settings.TSRAutoDeletePets, function(v)
        Settings.TSRAutoDeletePets = v == true
        AutoSaveConfiguration()
    end, "TSRAutoDeletePets")

    CreateDropdown("Delete Rarity", { "Common", "Common + Uncommon", "Up to Rare", "Up to Epic" }, GamePage, Settings.TSRDeleteThreshold, function(opt)
        Settings.TSRDeleteThreshold = opt
        AutoSaveConfiguration()
    end)

    Sec("Minigames & Events", "🎮")
    CreateToggle("Auto Lucky Ducky", GamePage, Settings.TSRAutoLuckyDucky, function(v)
        Settings.TSRAutoLuckyDucky = v == true
        AutoSaveConfiguration()
    end, "TSRAutoLuckyDucky")

    CreateToggle("Auto Pet Defense", GamePage, Settings.TSRAutoPetDefense, function(v)
        Settings.TSRAutoPetDefense = v == true
        AutoSaveConfiguration()
    end, "TSRAutoPetDefense")

    CreateDropdown("Relic Reward", { "Replace", "Keep", "Skip" }, GamePage, Settings.TSRRelicRewardMode, function(opt)
        Settings.TSRRelicRewardMode = opt
        AutoSaveConfiguration()
    end)

    Sec("Islands & Worlds", "🗺️")
    local initialIslands = ScanIslandsInWorkspace()
    if not TSR.DiscoveredIslands[Settings.TSRSelectedIsland] and #initialIslands > 0 then
        Settings.TSRSelectedIsland = initialIslands[1]
    end

    CreateDropdown("Island", initialIslands, GamePage, Settings.TSRSelectedIsland, function(opt)
        Settings.TSRSelectedIsland = tostring(opt)
        AutoSaveConfiguration()
    end)

    CreateButton("Teleport to Island", GamePage, function()
        ScanIslandsInWorkspace()
        TeleportToIslandByName(Settings.TSRSelectedIsland)
    end)

    CreateToggle("Auto Unlock Islands", GamePage, Settings.TSRAutoUnlockIslands, function(v)
        Settings.TSRAutoUnlockIslands = v == true
        AutoSaveConfiguration()
    end, "TSRAutoUnlockIslands")

    CreateButton("Scan Remotes / Refresh Map", GamePage, function()
        ScanAllRemotes(true)
        local e = ScanEggsInWorkspace()
        local isl = ScanIslandsInWorkspace()
        CustomNotify(
            string.format("Found %d eggs & %d islands", math.max(0, #e - 1), #isl),
            Color3.fromRGB(100, 200, 255),
            3
        )
    end)

    Sec("Codes & Player", "🎁")
    CreateButton("Redeem All Active Codes", GamePage, function()
        task.spawn(RedeemAllCodes)
    end)

    if CreateToggleWithValue then
        CreateToggleWithValue("WalkSpeed Boost", GamePage, Settings.TSRSafeSpeed, Settings.TSRWalkSpeed, function(v)
            Settings.TSRSafeSpeed = v == true
            if not Settings.TSRSafeSpeed then
                local _, hum = SafeCharState()
                if hum then hum.WalkSpeed = 16 end
            end
            AutoSaveConfiguration()
        end, function(val)
            Settings.TSRWalkSpeed = math.clamp(tonumber(val) or 48, 16, 200)
            AutoSaveConfiguration()
        end, "TSRSafeSpeed")
    end

    CreateToggle("Infinite Jump", GamePage, Settings.TSRInfiniteJump, function(v)
        Settings.TSRInfiniteJump = v == true
        AutoSaveConfiguration()
    end, "TSRInfiniteJump")

    CreateToggle("Anti-AFK", GamePage, Settings.TSRAntiAFK, function(v)
        Settings.TSRAntiAFK = v == true
        AutoSaveConfiguration()
    end, "TSRAntiAFK")

    CreateButton("Rejoin Same Server", GamePage, function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Player)
    end)

    if getgenv().ClearActivePageCard then
        pcall(getgenv().ClearActivePageCard, GamePage)
    end
end

-- ============================================================================
-- BACKGROUND LOOPS & HOOKS
-- ============================================================================
TrackConn(UserInputService.JumpRequest:Connect(function()
    if not IsAliveSession() or not Settings.TSRInfiniteJump then return end
    local _, hum = SafeCharState()
    if hum then
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end))

TrackConn(Player.Idled:Connect(function()
    if not IsAliveSession() or not Settings.TSRAntiAFK then return end
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end))

TrackConn(RunService.Heartbeat:Connect(function()
    if not IsAliveSession() then return end
    if Settings.TSRSafeSpeed then
        local _, hum = SafeCharState()
        if hum and hum.Health > 0 then
            hum.WalkSpeed = Settings.TSRWalkSpeed
        end
    end
    if Settings.TSRSkipAnimation then
        local pGui = Player:FindFirstChildOfClass("PlayerGui")
        if pGui then
            for _, gui in ipairs(pGui:GetChildren()) do
                local ln = string.lower(gui.Name)
                if string.find(ln, "hatch", 1, true) or string.find(ln, "unbox", 1, true) then
                    if gui:IsA("ScreenGui") and gui.Enabled then
                        gui.Enabled = false
                    end
                end
            end
        end
    end
end))

task.spawn(function()
    ScanAllRemotes(true)
    while IsAliveSession() do
        if env.ScriptLoaded then
            if Settings.TSRAutoTap then
                local count = math.clamp(tonumber(Settings.TSRTapsPerCycle) or 3, 1, 10)
                for _ = 1, count do
                    if not Settings.TSRAutoTap or not IsAliveSession() then break end
                    PerformTapOnce()
                end
            end
            if Settings.TSRAutoBreakables then
                pcall(AttackNearbyBreakables)
            end
            if Settings.TSRAutoCollect then
                pcall(CollectNearbyDrops)
            end
            if Settings.TSRAutoRebirth then
                pcall(TriggerRebirth)
            end
            if Settings.TSRAutoUpgrades then
                pcall(TriggerUpgrades)
            end
            if Settings.TSRAutoClaim then
                pcall(TriggerClaims)
            end
            if Settings.TSRAutoLuckyDucky then
                pcall(RunLuckyDucky)
            end
            if Settings.TSRAutoPetDefense then
                pcall(RunPetDefense)
            end
            if Settings.TSRAutoUnlockIslands and (os.clock() - TSR.LastUnlockTry) >= 3.0 then
                TSR.LastUnlockTry = os.clock()
                for islName in pairs(TSR.DiscoveredIslands) do
                    pcall(FireAction, "Teleport", islName)
                end
            end
            if Settings.TSRAutoHatch then
                pcall(TriggerHatchEgg)
            end
            if Settings.TSRAutoEquipBest and (os.clock() - TSR.LastEquipTry) >= 3.0 then
                TSR.LastEquipTry = os.clock()
                pcall(FireAction, "EquipBest")
            end
            if Settings.TSRAutoCraft and (os.clock() - TSR.LastCraftTry) >= 4.0 then
                TSR.LastCraftTry = os.clock()
                if Settings.TSRMutationTarget == "Auto / Any" then
                    pcall(FireAction, "Craft", "All")
                    pcall(FireAction, "Craft")
                else
                    pcall(FireAction, "Craft", Settings.TSRMutationTarget)
                    pcall(FireAction, "Craft", "All", Settings.TSRMutationTarget)
                end
            end
            if Settings.TSRAutoDeletePets and (os.clock() - TSR.LastDeleteTry) >= 3.5 then
                TSR.LastDeleteTry = os.clock()
                pcall(FireAction, "DeletePet", Settings.TSRDeleteThreshold)
            end
        end
        task.wait(Settings.TSRAutoTap and 0.05 or 0.15)
    end
end)

env.ToxTSRCleanup = function()
    for _, c in ipairs(TSR.Connections) do
        pcall(function() c:Disconnect() end)
    end
    TSR.Connections = {}
end

env.ToxTSRModuleLoadedJobId = game.JobId
env.ToxTSRModuleVersion = TSRModuleVersion
env.ToxTSRModulePage = GamePage
CustomNotify("Tap Simulator REBORN loaded!", Color3.fromRGB(80, 255, 130), 3)
