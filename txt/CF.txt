--[========================================================================[
    ToxHub Game Module: CF (Chicken Farm)
    PlaceId: 137233438285284
]========================================================================]
local CFPlaceId = 137233438285284
if game.PlaceId ~= CFPlaceId and tostring(game.PlaceId) ~= "137233438285284" then
    return
end

local Settings = getgenv().Settings
local GamePage = getgenv().GamePage
local CreateToggle = getgenv().CreateToggle
local CreateButton = getgenv().CreateButton
local CustomNotify = getgenv().CustomNotify or function() end

getgenv().ToxCFGeneration = (tonumber(getgenv().ToxCFGeneration) or 0) + 1
local CurrentGeneration = getgenv().ToxCFGeneration
local CFModuleVersion = "2026-11-09-cf-v1"

if getgenv().ToxCFModuleLoadedJobId == game.JobId
and getgenv().ToxCFModuleVersion == CFModuleVersion
and getgenv().ToxCFModulePage == GamePage
and not getgenv().Destroyed then
    return
end

if getgenv().ToxCFCleanup then
    pcall(getgenv().ToxCFCleanup)
end

if GamePage then
    for _, child in ipairs(GamePage:GetChildren()) do
        if child:IsA("GuiObject") then
            child:Destroy()
        end
    end

    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -5, 0, 75)
    card.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
    card.BorderSizePixel = 0
    card.Parent = GamePage

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 6)
    cardCorner.Parent = card

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = Color3.fromRGB(9, 0, 136)
    cardStroke.Thickness = 1.5
    cardStroke.Parent = card

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 26)
    title.Position = UDim2.new(0, 12, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = "Chicken Farm (CF)"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = card

    local desc = Instance.new("TextLabel")
    desc.Size = UDim2.new(1, -20, 0, 26)
    desc.Position = UDim2.new(0, 12, 0, 36)
    desc.BackgroundTransparency = 1
    desc.Text = "Status: Script Running • Features Active"
    desc.TextColor3 = Color3.fromRGB(120, 255, 120)
    desc.Font = Enum.Font.Gotham
    desc.TextSize = 11
    desc.TextXAlignment = Enum.TextXAlignment.Left
    desc.Parent = card

    if CreateButton then
        CreateButton("Recarregar Script (CF)", GamePage, function()
            CustomNotify("Recarregando Chicken Farm...", Color3.fromRGB(9, 0, 136))
            pcall(function()
                if getgenv().ToxCFCleanup then
                    getgenv().ToxCFCleanup()
                end
                loadstring(game:HttpGet("https://raw.githubusercontent.com/BG-0o/Scripts/refs/heads/main/CF.lua"))()
            end)
        end)
    end
end

getgenv().ToxCFModuleLoadedJobId = game.JobId
getgenv().ToxCFModuleVersion = CFModuleVersion
getgenv().ToxCFModulePage = GamePage

-- Original Game Script:
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
