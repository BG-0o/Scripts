--[========================================================================[
    ToxHub Game Module: CF (Chicken Farm)
    Version: 2026-11-10-cf-native-v2
]========================================================================]
do
    local isTarget = (game.PlaceId == 137233438285284 or game.GameId == 137233438285284 or tostring(game.PlaceId) == "137233438285284")
    local curMod = getgenv and getgenv().CurrentGameModule
    if not isTarget and curMod and curMod.ShortName == "CF" then
        isTarget = true
    end
    if not isTarget then
        return
    end
end

local RunCFCommunityScript = nil
do
    local function CommunityEntry(...)
-- [TOXHUB_ORIGINAL_PAYLOAD_START]
local connection
local cy
local cn
local cq
local cB
local Options
local ci
local VirtualUser
local Library
local co
local cz
local cr
local cj
local cu
local Network
local Toggles
local cp
local cA
local LocalPlayer
local ch
local cv
local function fn3()
    for k in co do
        if Library.Unloaded or not Toggles.AutoBuy.Value then
            break
        end
        local dl_1 = cq[k]
        if dl_1 then
            pcall(dl_1)
            task.wait(0.15)
        end
    end
end
local function fn6()
    local Map = workspace:FindFirstChild("Map")
    local dg = Map and Map:FindFirstChild("EggMultiplierPart")
    local df_1 = dg
    if dg then
        dg = df_1:FindFirstChild("UI")
    end
    local df_2 = dg
    if dg then
        dg = df_2:FindFirstChild("Multi")
    end
    local df_3 = dg
    if dg then
        dg = tonumber(df_3.Text:match("%d+%.?%d*"))
    end
    local df_4 = dg
    if not df_4 or df_4 < Options.MinimumEggMultiplier.Value then
        return
    end
    pcall(function()
        Network.InvokeServer("Deposit Eggs")
    end)
end
local function autoCollectEggsLoop()
    while not Library.Unloaded do
        if Toggles.AutoCollectEggs.Value then
            cA()
        end
        task.wait(0.3)
    end
end
local function fn32()
    pcall(function()
        Network.InvokeServer("Merge Chickens")
    end)
end
local function fn33()
    Network.InvokeServer("Claim Group Reward")
end
local function fn42()
    local Eggs = workspace:FindFirstChild("Eggs")
    if not Eggs then
        return
    end
    for i, child in Eggs:GetChildren() do
        if Library.Unloaded or not Toggles.AutoCollectEggs.Value then
            break
        end
        Network.FireServer("Collect Egg", child.Name)
    end
end
local function fn58()
    local Eggs = workspace:FindFirstChild("Eggs")
    if not Eggs then
        return
    end
    for i, child in Eggs:GetChildren() do
        if Library.Unloaded or not Toggles.RemoveEggModels.Value then
            break
        end
        child:Destroy()
    end
end
local function fn64()
    if setclipboard then
        setclipboard(cj)
    elseif toclipboard then
        toclipboard(cj)
    end
    Library:Notify("Copied Discord invite to clipboard")
end
local function onAntiAfk(a2)
    if a2 then
        if not connection then
            connection = LocalPlayer.Idled:Connect(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end
    elseif connection then
        connection:Disconnect()
        connection = nil
    end
end
local function fn140()
    Network.InvokeServer("Merge Chickens")
end
local function fn148(aG)
    local DiscordGroup = aG:AddLeftGroupbox("Discord")
    DiscordGroup:AddButton({ Text = "Join Discord to Make Money", Func = cv })
    DiscordGroup:AddButton({ Text = "Join Discord for Keyless Scripts", Func = cv })
end
local function autoMergeLoop()
    while not Library.Unloaded do
        if Toggles.AutoMerge.Value then
            cr()
        end
        task.wait(0.5)
    end
end
local function autoUpgradeLoop()
    while not Library.Unloaded do
        if Toggles.AutoUpgrade.Value then
            ci()
        end
        task.wait(0.5)
    end
end
local function fn159()
    if connection then
        connection:Disconnect()
        connection = nil
    end
    print("Chicken Farm unloaded")
end
local function onUpgrades(aW)
    local dJ = {}
    for k, v in aW do
        if v then
            dJ[k] = true
        end
    end
    ch = dJ
end
local function fn174()
    Network.InvokeServer("Upgrade Buy Tier Level")
end
local function autoCollectCashLoop()
    while not Library.Unloaded do
        if Toggles.AutoCollectCash.Value then
            cn()
        end
        task.wait(0.5)
    end
end
local function autoDepositLoop()
    while not Library.Unloaded do
        if Toggles.AutoDeposit.Value then
            cp()
        end
        task.wait(0.5)
    end
end
local function onUnload()
    Library:Unload()
end
local function fn228()
    pcall(function()
        Network.InvokeServer("Collect Cash")
    end)
end
local function removeEggModelsLoop()
    while not Library.Unloaded do
        if Toggles.RemoveEggModels.Value then
            cu()
        end
        task.wait(0.3)
    end
end
local function autoBuyLoop()
    while not Library.Unloaded do
        if Toggles.AutoBuy.Value then
            cz()
        end
        task.wait(0.5)
    end
end
local function onBuyables(aN)
    local dz = {}
    for k, v in aN do
        if v then
            dz[k] = true
        end
    end
    co = dz
end
local function fn251()
    Network.InvokeServer("Upgrade Process Level")
end
local function fn258()
    Network.InvokeServer("Buy Chickens", cy)
end
local function onBuyChickensAmount(aS)
    if type(aS) == "number" then
        aS = cB[aS]
    end
    local dH = tonumber(aS) or 1
    cy = dH
end
ch = nil
ci = nil
cj = nil
connection = nil
Library = nil
Network = nil
cn = nil
co = nil
cp = nil
cq = nil
cr = nil
LocalPlayer = nil
Options = nil
cu = nil
cv = nil
VirtualUser = nil
Toggles = nil
cy = nil
cz = nil
cA = nil
cB = nil
VirtualUser, LocalPlayer, Library, Toggles, Options, Network, cj, cB, cy, cq, co, ch, cA, cu, cp, cn, cz, cr, ci, cv = nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
VirtualUser = game:GetService("VirtualUser")
LocalPlayer = Players.LocalPlayer
Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua"))()
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/addons/SaveManager.lua"))()
Toggles = Library.Toggles
Options = Library.Options
local Paper = require(ReplicatedStorage.Paper)
Network = Paper.Network
cj = "https://discord.gg/ehKVq7pf7v"
cB = { "1", "5", "25", "100" }
cy = 1
local cL = {
    "Buy Chickens",
    "Merge Chickens",
    "Upgrade Process Level",
    "Upgrade Buy Tier Level",
    "Claim Group Reward"
}
cq = {
    ["Buy Chickens"] = fn258,
    ["Merge Chickens"] = fn140,
    ["Upgrade Process Level"] = fn251,
    ["Upgrade Buy Tier Level"] = fn174,
    ["Claim Group Reward"] = fn33
}
co = {}
local cK = { "Upgrade Process Level", "Upgrade Buy Tier Level" }
ch = {}
cA = fn42
cu = fn58
cp = fn6
cn = fn228
cz = fn3
cr = fn32
ci = function()
    for k in ch do
        local dx = k
        if Library.Unloaded or not Toggles.AutoUpgrade.Value then
            break
        end
        pcall(function()
            Network.InvokeServer(dx)
        end)
        task.wait(0.15)
    end
end
cv = fn64
local Window = Library:CreateWindow({
    Title = "Chicken Farm",
    Footer = "Ouroboros Hub",
    Icon = 18657887261,
    NotifySide = "Right",
    Size = UDim2.fromOffset(900, 640)
})
local cN = { Main = Window:AddTab("Main", "egg"), Settings = Window:AddTab("Settings", "settings") }
for k, v in cN do
    fn148(v)
end
connection = nil
local FarmGroup = cN.Main:AddLeftGroupbox("Farm", "wheat")
FarmGroup:AddToggle("AutoCollectEggs", { Text = "Auto Collect Eggs", Default = false })
FarmGroup:AddLabel("Auto Collect works, but collected eggs stay on the conveyor visually. Enable Remove Egg Models to clear them locally.", true)
FarmGroup:AddToggle("RemoveEggModels", { Text = "Remove Egg Models", Default = false })
FarmGroup:AddToggle("AutoDeposit", { Text = "Auto Deposit", Default = false })
FarmGroup:AddSlider("MinimumEggMultiplier", { Text = "Minimum Egg Multiplier", Default = 1.01, Min = 0.7, Max = 2, Rounding = 2, Suffix = "x" })
FarmGroup:AddToggle("AutoCollectCash", { Text = "Auto Collect Cash", Default = false })
local AutoBuyGroup = cN.Main:AddRightGroupbox("Auto Buy", "shopping-cart")
AutoBuyGroup:AddToggle("AutoBuy", { Text = "Auto Buy", Default = false })
AutoBuyGroup:AddDropdown("Buyables", { Text = "Buyables", Values = cL, Default = {}, Multi = true, Callback = onBuyables })
AutoBuyGroup:AddDropdown("BuyChickensAmount", {
    Text = "Buy Chickens Amount",
    Values = cB,
    Default = 1,
    Multi = false,
    Callback = onBuyChickensAmount
})
local Merge_UpgradeGroup = cN.Main:AddRightGroupbox("Merge & Upgrade", "trending-up")
Merge_UpgradeGroup:AddToggle("AutoMerge", { Text = "Auto Merge", Default = false })
Merge_UpgradeGroup:AddToggle("AutoUpgrade", { Text = "Auto Upgrade", Default = false })
Merge_UpgradeGroup:AddDropdown("Upgrades", { Text = "Upgrades", Values = cK, Default = {}, Multi = true, Callback = onUpgrades })
local MenuGroup = cN.Settings:AddLeftGroupbox("Menu", "wrench")
MenuGroup:AddLabel("UI Keybind"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "UI Keybind" })
MenuGroup:AddToggle("AntiAfk", { Text = "Anti-AFK", Default = true, Callback = onAntiAfk })
MenuGroup:AddButton("Unload", onUnload)
Library.ToggleKeybind = Options.MenuKeybind
Library:OnUnload(fn159)
ThemeManager:SetLibrary(Library)
ThemeManager:SetFolder("OuroborosHub")
ThemeManager:SaveDefault("Mint")
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
SaveManager:SetFolder("OuroborosHub/ChickenFarm")
SaveManager:BuildConfigSection(cN.Settings)
ThemeManager:ApplyToTab(cN.Settings)
ThemeManager:LoadDefault()
SaveManager:LoadAutoloadConfig()
task.spawn(autoCollectEggsLoop)
task.spawn(removeEggModelsLoop)
task.spawn(autoDepositLoop)
task.spawn(autoCollectCashLoop)
task.spawn(autoBuyLoop)
task.spawn(autoMergeLoop)
task.spawn(autoUpgradeLoop)

-- [TOXHUB_ORIGINAL_PAYLOAD_END]
    end
    RunCFCommunityScript = CommunityEntry
end

do
    local env = getgenv()
    if env.Destroyed then
        return
    end

    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local CollectionService = game:GetService("CollectionService")
    local Workspace = game:GetService("Workspace")
    local VirtualUser = game:GetService("VirtualUser")

    local Player = Players.LocalPlayer
    local Settings = env.Settings
    if not Settings then
        return
    end

    local GamePage = env.GamePage
    if not GamePage and type(env.EnsureGameTabCreated) == "function" then
        local okPage, ensured = pcall(env.EnsureGameTabCreated, env.CurrentGameModule)
        if okPage and ensured then
            GamePage = ensured
        end
    end

    local CreateSection = env.CreateSection
    local CreateToggle = env.CreateToggle
    local CreateToggleWithValue = env.CreateToggleWithValue
    local CreateDropdown = env.CreateDropdown
    local CreateButton = env.CreateButton
    local CustomNotify = env.CustomNotify or function() end
    local AutoSaveConfiguration = env.AutoSaveConfiguration or function() end
    local SyncToggleVisuals = env.SyncToggleVisuals

    if not GamePage or not CreateToggle or not CreateButton then
        return
    end

    local ModuleVersion = "2026-11-10-cf-native-v2"
    if env.ToxCFModuleLoadedJobId == game.JobId
    and env.ToxCFModuleVersion == ModuleVersion
    and env.ToxCFModulePage == GamePage
    and not env.Destroyed then
        return
    end

    if type(env.ToxCFCleanup) == "function" then
        pcall(env.ToxCFCleanup)
    end

    env.ToxCFGeneration = (tonumber(env.ToxCFGeneration) or 0) + 1
    local CurrentGeneration = env.ToxCFGeneration

    for _, child in ipairs(GamePage:GetChildren()) do
        if child:IsA("GuiObject") then
            child:Destroy()
        end
    end
    if type(env.ClearActivePageCard) == "function" then
        pcall(env.ClearActivePageCard, GamePage)
    end

    local Connections = {}
    local function TrackConnection(conn)
        if conn then
            table.insert(Connections, conn)
        end
        return conn
    end

    local function IsAlive()
        return not env.Destroyed and env.ToxCFGeneration == CurrentGeneration
    end

    local function MakeSection(title, icon)
        if type(CreateSection) == "function" then
            pcall(CreateSection, GamePage, title, icon)
        end
    end

    env.ToxCFCleanup = function()
        if env.ToxCFGeneration == CurrentGeneration then
            env.ToxCFGeneration = CurrentGeneration + 1
        end
        for _, conn in ipairs(Connections) do
            pcall(function()
                conn:Disconnect()
            end)
        end
        Connections = {}
        env.ToxCFModuleLoadedJobId = nil
        env.ToxCFModuleVersion = nil
        env.ToxCFModulePage = nil
        Settings.CFAutoFarm = false
        Settings.CFAutofarm = false
        Settings.CFAutoCollectEggs = false
        Settings.CFAutoDeposit = false
        Settings.CFAutoCash = false
        Settings.CFAutoMerge = false
        Settings.CFAutoBuyChickens = false
        Settings.CFAutoUpgradeProcess = false
        Settings.CFAutoUpgradeTier = false
    end

    Settings.CFAutoFarm = Settings.CFAutoFarm == true or Settings.CFAutofarm == true
    Settings.CFAutofarm = Settings.CFAutoFarm
    Settings.CFAutoCollectEggs = Settings.CFAutoCollectEggs == true
    Settings.CFAutoDeposit = Settings.CFAutoDeposit == true
    Settings.CFMinMultiplier = tonumber(Settings.CFMinMultiplier) or 1
    Settings.CFAutoCash = Settings.CFAutoCash == true
    Settings.CFAutoMerge = Settings.CFAutoMerge == true
    Settings.CFBuyAmount = tostring(Settings.CFBuyAmount or "1")
    Settings.CFAutoBuyChickens = Settings.CFAutoBuyChickens == true
    Settings.CFAutoUpgradeProcess = Settings.CFAutoUpgradeProcess == true
    Settings.CFAutoUpgradeTier = Settings.CFAutoUpgradeTier == true

    local cachedNetwork = nil
    local function GetCFNetwork()
        if cachedNetwork then
            return cachedNetwork
        end
        local ok, net = pcall(function()
            local paperMod = ReplicatedStorage:FindFirstChild("Paper") or ReplicatedStorage:WaitForChild("Paper", 5)
            if paperMod then
                local paper = require(paperMod)
                return paper and paper.Network
            end
            return nil
        end)
        if ok and net then
            cachedNetwork = net
            return net
        end
        return nil
    end

    local function GetEggMultiplier()
        local val = 1
        pcall(function()
            local mapFolder = Workspace:FindFirstChild("Map")
            local part = mapFolder and mapFolder:FindFirstChild("EggMultiplierPart")
            local ui = part and part:FindFirstChild("UI")
            local multi = ui and ui:FindFirstChild("Multi")
            if multi and multi.Text then
                local cleaned = tostring(multi.Text):gsub("[^%d%.]", "")
                local parsed = tonumber(cleaned)
                if parsed then
                    val = parsed
                end
            end
        end)
        return val
    end

    local function CollectAllEggs()
        local net = GetCFNetwork()
        local eggsFolder = Workspace:FindFirstChild("Eggs")
        if not net or not eggsFolder then
            return
        end
        for _, egg in ipairs(eggsFolder:GetChildren()) do
            if not IsAlive() then
                break
            end
            pcall(function()
                net.FireServer("Collect Egg", egg.Name)
            end)
        end
    end

    local function DepositEggs(respectMin)
        local net = GetCFNetwork()
        if not net then
            return
        end
        if respectMin then
            local minReq = tonumber(Settings.CFMinMultiplier) or 1
            if GetEggMultiplier() < minReq then
                return
            end
        end
        pcall(function()
            net.InvokeServer("Deposit Eggs")
        end)
    end

    MakeSection("Farming & Ovos", "🐔")
    CreateToggle("Auto Farm (CF)", GamePage, Settings.CFAutoFarm, function(v)
        local state = v == true
        Settings.CFAutoFarm = state
        Settings.CFAutofarm = state
    end, "CFAutoFarm")

    CreateToggle("Auto Collect Eggs", GamePage, Settings.CFAutoCollectEggs, function(v)
        Settings.CFAutoCollectEggs = v == true
    end, "CFAutoCollectEggs")

    if type(CreateToggleWithValue) == "function" then
        CreateToggleWithValue("Auto Deposit Eggs (Min Multi)", GamePage, Settings.CFAutoDeposit, Settings.CFMinMultiplier, function(v)
            Settings.CFAutoDeposit = v == true
        end, function(val)
            Settings.CFMinMultiplier = math.max(0, tonumber(val) or 1)
        end, "CFAutoDeposit")
    else
        CreateToggle("Auto Deposit Eggs", GamePage, Settings.CFAutoDeposit, function(v)
            Settings.CFAutoDeposit = v == true
        end, "CFAutoDeposit")
    end

    CreateToggle("Auto Collect Cash", GamePage, Settings.CFAutoCash, function(v)
        Settings.CFAutoCash = v == true
    end, "CFAutoCash")

    CreateButton("Depositar Ovos Agora", GamePage, function()
        DepositEggs(false)
        CustomNotify("Ovos depositados!", Color3.fromRGB(90, 235, 130), 2)
    end)

    CreateButton("Coletar Cash Agora", GamePage, function()
        local net = GetCFNetwork()
        if net then
            pcall(function()
                net.InvokeServer("Collect Cash")
            end)
            CustomNotify("Cash coletado!", Color3.fromRGB(90, 235, 130), 2)
        end
    end)

    MakeSection("Galinhas & Upgrades", "🛒")
    CreateToggle("Auto Merge Chickens", GamePage, Settings.CFAutoMerge, function(v)
        Settings.CFAutoMerge = v == true
    end, "CFAutoMerge")

    if type(CreateDropdown) == "function" then
        CreateDropdown("Quantidade de Galinhas", {"1", "5", "25", "100"}, GamePage, Settings.CFBuyAmount, function(opt)
            Settings.CFBuyAmount = tostring(opt)
        end)
    end

    CreateToggle("Auto Buy Chickens", GamePage, Settings.CFAutoBuyChickens, function(v)
        Settings.CFAutoBuyChickens = v == true
    end, "CFAutoBuyChickens")

    CreateButton("Comprar Galinhas Agora", GamePage, function()
        local net = GetCFNetwork()
        if net then
            local amt = tonumber(Settings.CFBuyAmount) or 1
            pcall(function()
                net.InvokeServer("Buy Chickens", amt)
            end)
            CustomNotify("Compra enviada (" .. tostring(amt) .. "x)", Color3.fromRGB(90, 235, 130), 2)
        end
    end)

    CreateToggle("Auto Upgrade Process", GamePage, Settings.CFAutoUpgradeProcess, function(v)
        Settings.CFAutoUpgradeProcess = v == true
    end, "CFAutoUpgradeProcess")

    CreateToggle("Auto Upgrade Tier", GamePage, Settings.CFAutoUpgradeTier, function(v)
        Settings.CFAutoUpgradeTier = v == true
    end, "CFAutoUpgradeTier")

    CreateButton("Resgatar Group Reward", GamePage, function()
        local net = GetCFNetwork()
        if net then
            pcall(function()
                net.InvokeServer("Claim Group Reward")
            end)
            CustomNotify("Tentativa de Group Reward enviada!", Color3.fromRGB(90, 235, 130), 2)
        end
    end)

    task.spawn(function()
        local lastCashTick = 0
        local lastShopTick = 0
        while IsAlive() do
            if Settings.CFAutoFarm or Settings.CFAutoCollectEggs then
                CollectAllEggs()
            end
            if Settings.CFAutoDeposit then
                DepositEggs(true)
            elseif Settings.CFAutoFarm then
                DepositEggs(false)
            end
            local now = os.clock()
            if now - lastCashTick >= 0.6 then
                lastCashTick = now
                if Settings.CFAutoFarm or Settings.CFAutoCash then
                    local net = GetCFNetwork()
                    if net then
                        pcall(function()
                            net.InvokeServer("Collect Cash")
                        end)
                    end
                end
            end
            if now - lastShopTick >= 0.8 then
                lastShopTick = now
                local net = GetCFNetwork()
                if net then
                    if Settings.CFAutoMerge then
                        pcall(function()
                            net.InvokeServer("Merge Chickens")
                        end)
                    end
                    if Settings.CFAutoBuyChickens then
                        local amt = tonumber(Settings.CFBuyAmount) or 1
                        pcall(function()
                            net.InvokeServer("Buy Chickens", amt)
                        end)
                    end
                    if Settings.CFAutoUpgradeProcess then
                        pcall(function()
                            net.InvokeServer("Upgrade Process Level")
                        end)
                    end
                    if Settings.CFAutoUpgradeTier then
                        pcall(function()
                            net.InvokeServer("Upgrade Buy Tier Level")
                        end)
                    end
                end
            end
            task.wait(0.25)
        end
    end)

    local communityExecuted = false
    MakeSection("Community Hub & Extras", "🧰")
    CreateButton("Executar Community Hub (CF)", GamePage, function()
        if communityExecuted then
            CustomNotify("Community Hub (CF) ja esta ativo nesta sessao.", Color3.fromRGB(255, 200, 80), 3)
            return
        end
        communityExecuted = true
        CustomNotify("Iniciando Community Hub (CF)...", Color3.fromRGB(110, 185, 255), 3)
        task.spawn(function()
            local ok, err = pcall(RunCFCommunityScript)
            if not ok then
                communityExecuted = false
                CustomNotify("Erro Community Hub (CF): " .. tostring(err), Color3.fromRGB(255, 95, 95), 5)
                warn("[ToxHub CF Community Error]: " .. tostring(err))
            end
        end)
    end)

    CreateButton("Recarregar Modulo (CF)", GamePage, function()
        CustomNotify("Recarregando Chicken Farm (CF)...", Color3.fromRGB(90, 175, 255), 2)
        task.spawn(function()
            if type(env.ToxCFCleanup) == "function" then
                pcall(env.ToxCFCleanup)
            end
            local ok, err = pcall(function()
                local url = "https://raw.githubusercontent.com/BG-0o/Scripts/refs/heads/main/Games/CF.lua?toxv=" .. tostring(os.time()) .. "_" .. tostring(math.random(1000, 999999))
                local src = game:HttpGet(url)
                local chunk, compErr = loadstring(src)
                if not chunk then
                    error(tostring(compErr or "compile error"))
                end
                chunk()
            end)
            if not ok then
                CustomNotify("Falha ao recarregar (CF): " .. tostring(err), Color3.fromRGB(255, 95, 95), 4)
            end
        end)
    end)

    if type(env.ClearActivePageCard) == "function" then
        pcall(env.ClearActivePageCard, GamePage)
    end

    env.ToxCFModuleLoadedJobId = game.JobId
    env.ToxCFModuleVersion = ModuleVersion
    env.ToxCFModulePage = GamePage
end
