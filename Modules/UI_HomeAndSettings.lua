local env = getgenv()
if env.Destroyed then return end
local UI = env.ToxUI or {}
env.ToxUI = UI

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

local Player = Players.LocalPlayer
local Settings = env.Settings or {}
local Theme = env.Theme or UI.Theme or {}
local RegisterThemedObject = env.RegisterThemedObject or UI.RegisterThemedObject or function() end
local CustomNotify = function(...) if env.CustomNotify then return env.CustomNotify(...) end end
local AutoSaveConfiguration = function(...) if env.AutoSaveConfiguration then return env.AutoSaveConfiguration(...) end end
local CreateCard = env.CreateCard or UI.CreateCard
local CreateButton = env.CreateButton
local RegisterSharedToggle = env.RegisterSharedToggle or UI.RegisterSharedToggle or function() end

local Gui = UI.Gui or env.Gui
local Main = UI.Main or env.Main
local DimmerFrame = UI.DimmerFrame or env.DimmerFrame
local HomePage = UI.HomePage or env.HomePage
local SettingsPage = UI.SettingsPage or env.SettingsPage
local ActivePageCards = UI.ActivePageCards or {}
local function InitializeHomePage()
    local targetPage = (getgenv and getgenv().HomePage) or HomePage
    if not targetPage then return end
    local plr = (Players and Players.LocalPlayer) or Player or (game:GetService("Players").LocalPlayer)
    local profileCard = CreateCard(targetPage, "Perfil do Usuário", "👤", 0, "Home_Profile")
    local bannerFrame = Instance.new("Frame")
    bannerFrame.Size = UDim2.new(1, -4, 0, 72)
    bannerFrame.BackgroundColor3 = Theme.Element
    bannerFrame.BorderSizePixel = 0
    bannerFrame.Parent = profileCard.Content
    local bCorner = Instance.new("UICorner") bCorner.CornerRadius = UDim.new(0, 8) bCorner.Parent = bannerFrame
    local bStroke = Instance.new("UIStroke") bStroke.Color = Theme.Outline bStroke.Thickness = 1 bStroke.Parent = bannerFrame
    RegisterThemedObject(bannerFrame, "BackgroundColor3", "Element")
    RegisterThemedObject(bStroke, "Color", "Outline")
    local avatarImg = Instance.new("ImageLabel")
    avatarImg.Size = UDim2.new(0, 52, 0, 52)
    avatarImg.Position = UDim2.new(0, 10, 0.5, -26)
    avatarImg.BackgroundColor3 = Theme.Panel
    avatarImg.BorderSizePixel = 0
    avatarImg.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(plr and plr.UserId or 0) .. "&w=150&h=150"
    avatarImg.Parent = bannerFrame
    local avCorner = Instance.new("UICorner") avCorner.CornerRadius = UDim.new(1, 0) avCorner.Parent = avatarImg
    local avStroke = Instance.new("UIStroke") avStroke.Color = Theme.Accent avStroke.Thickness = 1.5 avStroke.Parent = avatarImg
    RegisterThemedObject(avStroke, "Color", "Accent")
    local welcomeLbl = Instance.new("TextLabel")
    welcomeLbl.Size = UDim2.new(1, -78, 0, 20)
    welcomeLbl.Position = UDim2.new(0, 72, 0, 12)
    welcomeLbl.BackgroundTransparency = 1
    welcomeLbl.Text = "Bem-vindo, " .. tostring(plr and (plr.DisplayName or plr.Name) or "Player") .. " (@" .. tostring(plr and plr.Name or "Player") .. ")"
    welcomeLbl.TextColor3 = Theme.Text
    welcomeLbl.TextSize = 13
    welcomeLbl.Font = Enum.Font.GothamBold
    welcomeLbl.TextXAlignment = Enum.TextXAlignment.Left
    welcomeLbl.TextTruncate = Enum.TextTruncate.AtEnd
    welcomeLbl.Parent = bannerFrame
    RegisterThemedObject(welcomeLbl, "TextColor3", "Text")
    local subLbl = Instance.new("TextLabel")
    subLbl.Size = UDim2.new(1, -78, 0, 18)
    subLbl.Position = UDim2.new(0, 72, 0, 36)
    subLbl.BackgroundTransparency = 1
    subLbl.Text = "ToxHud 1.0.0 • Lifetime"
    subLbl.TextColor3 = Theme.Accent
    subLbl.TextSize = 11
    subLbl.Font = Enum.Font.GothamMedium
    subLbl.TextXAlignment = Enum.TextXAlignment.Left
    subLbl.TextTruncate = Enum.TextTruncate.AtEnd
    subLbl.Parent = bannerFrame
    RegisterThemedObject(subLbl, "TextColor3", "Accent")
    local supportCard = CreateCard(targetPage, "Loja & Loader", "🛒", 7, "Home_Support")
    ActivePageCards[targetPage] = supportCard
    CreateButton("Comprar Robux com R$ (BRL)", targetPage, function()
        if setclipboard then
            setclipboard("https://discord.gg/A7tZ9VbVvM")
        end
        CustomNotify("Link copiado! Acesse o Discord no canal #robux para comprar via PIX/BRL.", Color3.fromRGB(0, 230, 120), 6)
    end)
    CreateButton("Copiar Loader Oficial (ToxHud)", targetPage, function()
        if setclipboard then
            setclipboard('loadstring(game:HttpGet("https://raw.githubusercontent.com/BG-0o/Scripts/refs/heads/main/ToxHud.lua"))()')
        end
        CustomNotify("Loader do ToxHud copiado para a área de transferência!", Color3.fromRGB(0, 168, 255), 5)
    end)
    ActivePageCards[targetPage] = nil
end
getgenv().InitializeHomePage = InitializeHomePage
InitializeHomePage()
do
    local StartSessionTime = os.clock()
    UI.StartSessionTime = StartSessionTime
local PinnedCard = CreateCard(HomePage, "Pinned", "📌", 1, "Home_Pinned")
local function AddPinnedCheckbox(name, defaultVal, isRisky, onToggled)
    local row = Instance.new("TextButton")
    row.Size = UDim2.new(1, 0, 0, 32)
    row.BackgroundColor3 = Theme.Element
    row.BorderSizePixel = 0
    row.Text = ""
    row.AutoButtonColor = false
    row.Parent = PinnedCard.Content
    local rCorner = Instance.new("UICorner") rCorner.CornerRadius = UDim.new(0, 5) rCorner.Parent = row
    RegisterThemedObject(row, "BackgroundColor3", "Element")
    local box = Instance.new("Frame")
    box.Size = UDim2.new(0, 18, 0, 18)
    box.Position = UDim2.new(0, 10, 0.5, -9)
    box.BackgroundColor3 = Theme.Panel
    box.BorderSizePixel = 0
    box.Parent = row
    local bCorner = Instance.new("UICorner") bCorner.CornerRadius = UDim.new(0, 4) bCorner.Parent = box
    local bStroke = Instance.new("UIStroke") bStroke.Color = Theme.Outline bStroke.Thickness = 1 bStroke.Parent = box
    RegisterThemedObject(box, "BackgroundColor3", "Panel")
    RegisterThemedObject(bStroke, "Color", "Outline")
    local check = Instance.new("TextLabel")
    check.Size = UDim2.new(1, 0, 1, 0)
    check.BackgroundTransparency = 1
    check.Text = defaultVal and "✓" or ""
    check.TextColor3 = Theme.Accent
    check.Font = Enum.Font.GothamBold
    check.TextSize = 13
    check.Parent = box
    RegisterThemedObject(check, "TextColor3", "Accent")
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -44, 1, 0)
    label.Position = UDim2.new(0, 38, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = isRisky and Theme.Risky or Theme.Text
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row
    if not isRisky then RegisterThemedObject(label, "TextColor3", "Text") else RegisterThemedObject(label, "TextColor3", "Risky") end
    local active = defaultVal == true
    local function SetState(val)
        active = val == true
        check.Text = active and "✓" or ""
    end
    row.MouseButton1Click:Connect(function()
        active = not active
        SetState(active)
        if onToggled then onToggled(active) end
        if getgenv().AutoSaveConfiguration then getgenv().AutoSaveConfiguration() end
    end)
    return SetState, row, label
end
local setEspPinned, espPinnedRow = AddPinnedCheckbox("Enable ESP", Settings.ESPEnabled, false, function(v)
    if getgenv().ToxSetSharedOption then
        getgenv().ToxSetSharedOption("ESPEnabled", v)
    else
        Settings.ESPEnabled = v
        if getgenv().SyncToggleVisuals then getgenv().SyncToggleVisuals("ESPEnabled", v) end
    end
    if not v then
        local clr = getgenv().ClearAllESPVisuals or getgenv().ClearAllToxESPVisuals
        if type(clr) == "function" then
            pcall(clr)
        end
    end
end)
RegisterSharedToggle("ESPEnabled", { Button = espPinnedRow, SetVisual = setEspPinned })

local pinnedGameKey = "Noclip"
local pinnedGameCallback = nil
local function ResolvePinnedGameConfig(mod)
    if game.PlaceId == 142823291 then
        return "MM2AutoFarmV2", "Farm Coins", Settings.MM2AutoFarmV2 == true, function(v)
            Settings.MM2AutoFarmV2 = v
            if getgenv().SyncToggleVisuals then getgenv().SyncToggleVisuals("MM2AutoFarmV2", v) end
        end
    elseif mod and mod.ShortName then
        local short = tostring(mod.ShortName)
        local key = short .. "AutoFarm"
        local altKey = short .. "Autofarm"
        local curVal = (Settings[key] == true) or (Settings[altKey] == true)
        return key, "Auto Farm (" .. short .. ")", curVal, function(v)
            Settings[key] = v
            Settings[altKey] = v
            if getgenv().SyncToggleVisuals then getgenv().SyncToggleVisuals(key, v) end
        end
    end
    return "Noclip", "Noclip", Settings.Noclip == true, function(v)
        if getgenv().ToxSetSharedOption then
            getgenv().ToxSetSharedOption("Noclip", v)
        else
            Settings.Noclip = v
            if getgenv().SyncToggleVisuals then getgenv().SyncToggleVisuals("Noclip", v) end
        end
    end
end

local initGameKey, pinnedActionName, pinnedActionVal, initGameFunc = ResolvePinnedGameConfig(getgenv().CurrentGameModule)
pinnedGameKey = initGameKey
pinnedGameCallback = initGameFunc
local setGamePinned, gamePinnedRow, gamePinnedLabel = AddPinnedCheckbox(pinnedActionName, pinnedActionVal, false, function(v)
    if pinnedGameCallback then pinnedGameCallback(v) end
end)
local registeredGamePinnedKeys = {}
local function RegisterGamePinnedKey(keyName)
    if not keyName or registeredGamePinnedKeys[keyName] then return end
    registeredGamePinnedKeys[keyName] = true
    RegisterSharedToggle(keyName, {
        Button = gamePinnedRow,
        SetVisual = function(v)
            if pinnedGameKey == keyName then
                setGamePinned(v)
            end
        end
    })
end
RegisterGamePinnedKey(pinnedGameKey)
getgenv().UpdateHomePinnedGameOption = function(mod)
    local nextKey, nextName, nextVal, nextFunc = ResolvePinnedGameConfig(mod or getgenv().CurrentGameModule)
    pinnedGameKey = nextKey
    pinnedGameCallback = nextFunc
    if gamePinnedLabel and gamePinnedLabel.Parent then
        gamePinnedLabel.Text = nextName
    end
    if setGamePinned then
        setGamePinned(nextVal)
    end
    RegisterGamePinnedKey(nextKey)
end

local setKillAuraPinned, killAuraPinnedRow = AddPinnedCheckbox("Kill Aura", Settings.KillAura, true, function(v)
    Settings.KillAura = v
    if getgenv().SyncToggleVisuals then getgenv().SyncToggleVisuals("KillAura", v) end
end)
RegisterSharedToggle("KillAura", { Button = killAuraPinnedRow, SetVisual = setKillAuraPinned })

local setAntiAfkPinned, antiAfkPinnedRow = AddPinnedCheckbox("Anti AFK", Settings.AntiAFK ~= false, false, function(v)
    Settings.AntiAFK = v
    if getgenv().SyncToggleVisuals then getgenv().SyncToggleVisuals("AntiAFK", v) end
end)
RegisterSharedToggle("AntiAFK", { Button = antiAfkPinnedRow, SetVisual = setAntiAfkPinned })
end
do
local StatusCard = CreateCard(HomePage, "Status", "🕒", 2, "Home_Status")
local StatusGrid = Instance.new("Frame")
StatusGrid.Size = UDim2.new(1, 0, 0, 96)
StatusGrid.BackgroundTransparency = 1
StatusGrid.Parent = StatusCard.Content
local StatUIGrid = Instance.new("UIGridLayout")
StatUIGrid.CellSize = UDim2.new(0.315, 0, 0, 44)
StatUIGrid.CellPadding = UDim2.new(0.027, 0, 0, 8)
StatUIGrid.Parent = StatusGrid
local function CreateStatusPill(initialVal, subText)
    local pill = Instance.new("Frame")
    pill.BackgroundColor3 = Theme.Element
    pill.BorderSizePixel = 0
    pill.Parent = StatusGrid
    local pCorner = Instance.new("UICorner") pCorner.CornerRadius = UDim.new(0, 6) pCorner.Parent = pill
    RegisterThemedObject(pill, "BackgroundColor3", "Element")
    local val = Instance.new("TextLabel")
    val.Size = UDim2.new(1, -6, 0, 22)
    val.Position = UDim2.new(0, 6, 0, 4)
    val.BackgroundTransparency = 1
    val.Text = initialVal
    val.TextColor3 = Theme.Text
    val.Font = Enum.Font.GothamBold
    val.TextSize = 13
    val.TextXAlignment = Enum.TextXAlignment.Left
    val.Parent = pill
    RegisterThemedObject(val, "TextColor3", "Text")
    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1, -6, 0, 16)
    sub.Position = UDim2.new(0, 6, 0, 24)
    sub.BackgroundTransparency = 1
    sub.Text = subText
    sub.TextColor3 = Theme.DimText
    sub.Font = Enum.Font.Gotham
    sub.TextSize = 10
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.Parent = pill
    RegisterThemedObject(sub, "TextColor3", "DimText")
    return function(newVal) val.Text = tostring(newVal) end
end
local UpdateSessionPill = CreateStatusPill("0m 0s", "session")
local UpdateFeaturesPill = CreateStatusPill("0", "features on")
local UpdateFPSPill = CreateStatusPill("60", "fps")
local UpdatePingPill = CreateStatusPill("50 ms", "ping")
local UpdatePlayersPill = CreateStatusPill(tostring(#Players:GetPlayers()) .. " / " .. tostring(Players.MaxPlayers), "players")
local UpdateKeyPill = CreateStatusPill("lifetime", "key time")
    UI.HomeStatus = {
        Session = UpdateSessionPill,
        Features = UpdateFeaturesPill,
        FPS = UpdateFPSPill,
        Ping = UpdatePingPill,
        Players = UpdatePlayersPill,
        Key = UpdateKeyPill
    }
end
do
local AnnounceCard = CreateCard(HomePage, "Announcements", "📢", 3, "Home_Announcements")
local AnnounceBox = Instance.new("Frame")
AnnounceBox.Size = UDim2.new(1, 0, 0, 0)
AnnounceBox.AutomaticSize = Enum.AutomaticSize.Y
AnnounceBox.BackgroundColor3 = Theme.Element
AnnounceBox.BorderSizePixel = 0
AnnounceBox.Parent = AnnounceCard.Content
local abCorner = Instance.new("UICorner") abCorner.CornerRadius = UDim.new(0, 6) abCorner.Parent = AnnounceBox
RegisterThemedObject(AnnounceBox, "BackgroundColor3", "Element")
local abPadding = Instance.new("UIPadding")
abPadding.PaddingTop = UDim.new(0, 8)
abPadding.PaddingBottom = UDim.new(0, 8)
abPadding.PaddingLeft = UDim.new(0, 10)
abPadding.PaddingRight = UDim.new(0, 10)
abPadding.Parent = AnnounceBox
local abLayout = Instance.new("UIListLayout")
abLayout.Padding = UDim.new(0, 4)
abLayout.Parent = AnnounceBox
local function AddAnnounceLine(text, isBold, color)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 0, isBold and 18 or 15)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = color or (isBold and Theme.Text or Theme.DimText)
    l.Font = isBold and Enum.Font.GothamBold or Enum.Font.Gotham
    l.TextSize = isBold and 12 or 11
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = AnnounceBox
    if not color then
        RegisterThemedObject(l, "TextColor3", isBold and "Text" or "DimText")
    end
end
AddAnnounceLine("v2.1 Update", true)
AddAnnounceLine("2026-11-13", false)
AddAnnounceLine("+ Keybinds on every option (Config > Keybinds)", false)
AddAnnounceLine("+ Sliders + typed values on Speed, Jump, Flies, Car", false)
AddAnnounceLine("+ New: Anti Social, Up Player, Spectate, Select Player", false)
AddAnnounceLine("+ NDS: Walk on Water, Mute Game Sounds, Clean Screen", false)
AddAnnounceLine("+ Ultra Instinct: ground circle + dodges away", false)
AddAnnounceLine("+ Fly Bypass, Walk Fling & No Fall Damage reworked", false)
AddAnnounceLine("+ Flies: Space up / Ctrl down everywhere", false)
AddAnnounceLine("+ MM2 Auto Farm & many bug fixes", false)

-- Live changelog: replaces the static text above with the latest commits of the
-- ToxHud repo, so it updates by itself on every push. Falls back to the static text.
task.spawn(function()
    local HttpService = game:GetService("HttpService")
    local url = "https://api.github.com/repos/BG-0o/Scripts/commits?per_page=25"
    local ok, body = pcall(function()
        return game:HttpGet(url)
    end)
    if (not ok or type(body) ~= "string") then
        local requestFn = (syn and syn.request) or (http and http.request) or http_request or request
        if requestFn then
            local okReq, res = pcall(requestFn, { Url = url, Method = "GET", Headers = { ["User-Agent"] = "ToxHub" } })
            if okReq and res and res.Body then
                ok, body = true, res.Body
            end
        end
    end
    if not ok or type(body) ~= "string" then return end
    local okJson, commits = pcall(function() return HttpService:JSONDecode(body) end)
    if not okJson or type(commits) ~= "table" or #commits == 0 then return end

    local lines = {}
    local newestDate = nil
    for _, entry in ipairs(commits) do
        local commit = type(entry) == "table" and entry.commit
        local message = commit and tostring(commit.message or "") or ""
        local firstLine = string.match(message, "^[^\n]+") or ""
        local kind = string.lower(string.match(firstLine, "^(%a+)") or "")
        -- skip housekeeping / merge commits
        if firstLine ~= "" and kind ~= "chore" and kind ~= "merge" and kind ~= "docs" then
            newestDate = newestDate or (commit.author and commit.author.date)
            -- "fix(walkfling): only apply ..." -> "Walkfling: only apply ..."
            local scope, rest = string.match(firstLine, "^%a+%(([^%)]+)%)!?:%s*(.+)$")
            if not rest then
                rest = string.match(firstLine, "^%a+!?:%s*(.+)$") or firstLine
            end
            local text = scope and (scope:gsub("^%l", string.upper) .. ": " .. rest) or (rest:gsub("^%l", string.upper))
            if #text > 58 then
                text = string.sub(text, 1, 55) .. "..."
            end
            local prefix = (kind == "fix") and "• " or "+ "
            table.insert(lines, prefix .. text)
            if #lines >= 8 then break end
        end
    end
    if #lines == 0 or getgenv().Destroyed or not AnnounceBox.Parent then return end

    for _, child in ipairs(AnnounceBox:GetChildren()) do
        if child:IsA("TextLabel") then
            child:Destroy()
        end
    end
    AddAnnounceLine("Latest Updates", true)
    if newestDate then
        AddAnnounceLine(string.sub(tostring(newestDate), 1, 10), false)
    end
    for _, line in ipairs(lines) do
        AddAnnounceLine(line, false)
    end
end)
end
do
local StatsCard = CreateCard(HomePage, "Stats", "📊", 4, "Home_Stats")
local StatsGrid = Instance.new("Frame")
StatsGrid.Size = UDim2.new(1, 0, 0, 88)
StatsGrid.BackgroundTransparency = 1
StatsGrid.Parent = StatsCard.Content
local StatGridLayout = Instance.new("UIGridLayout")
StatGridLayout.CellSize = UDim2.new(0.485, 0, 0, 40)
StatGridLayout.CellPadding = UDim2.new(0.03, 0, 0, 8)
StatGridLayout.Parent = StatsGrid
local function CreateStatCard(title, defaultVal)
    local f = Instance.new("Frame")
    f.BackgroundColor3 = Theme.Element
    f.BorderSizePixel = 0
    f.Parent = StatsGrid
    local fc = Instance.new("UICorner") fc.CornerRadius = UDim.new(0, 5) fc.Parent = f
    RegisterThemedObject(f, "BackgroundColor3", "Element")
    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1, -6, 0, 16)
    t.Position = UDim2.new(0, 6, 0, 4)
    t.BackgroundTransparency = 1
    t.Text = title
    t.TextColor3 = Theme.DimText
    t.Font = Enum.Font.Gotham
    t.TextSize = 10
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.Parent = f
    RegisterThemedObject(t, "TextColor3", "DimText")
    local v = Instance.new("TextLabel")
    v.Size = UDim2.new(1, -6, 0, 18)
    v.Position = UDim2.new(0, 6, 0, 18)
    v.BackgroundTransparency = 1
    v.Text = defaultVal
    v.TextColor3 = Theme.Text
    v.Font = Enum.Font.GothamBold
    v.TextSize = 11
    v.TextXAlignment = Enum.TextXAlignment.Left
    v.TextTruncate = Enum.TextTruncate.AtEnd
    v.Parent = f
    RegisterThemedObject(v, "TextColor3", "Text")
    return function(newVal) v.Text = tostring(newVal) end
end
local UpdateMurdererStat = nil
local UpdateSheriffStat = nil
local UpdateGameStat = nil
local UpdateStatusStat = nil
local isMM2Game = game.PlaceId == 142823291
if isMM2Game then
    UpdateMurdererStat = CreateStatCard("Murderer", "None")
    UpdateSheriffStat = CreateStatCard("Sheriff", "None")
else
    local curMod = getgenv().CurrentGameModule
    local gameTitle = (curMod and (curMod.GameName or curMod.ShortName)) or "Universal"
    UpdateGameStat = CreateStatCard("Game", gameTitle)
    UpdateStatusStat = CreateStatCard("Status", "Online")
end
local UpdatePlayersStat = CreateStatCard("Players", tostring(#Players:GetPlayers()))
local UpdateMapStat = CreateStatCard("Place ID", tostring(game.PlaceId))
    UI.HomeStats = {
        Murderer = UpdateMurdererStat,
        Sheriff = UpdateSheriffStat,
        Game = UpdateGameStat,
        Status = UpdateStatusStat,
        Players = UpdatePlayersStat,
        Map = UpdateMapStat,
        IsMM2 = isMM2Game
    }
end
do
    local WatermarkFrame = UI.WatermarkFrame
local QuickCard = CreateCard(HomePage, "Quick actions", "⚡", 5, "Home_QuickActions")
local QuickGrid = Instance.new("Frame")
QuickGrid.Size = UDim2.new(1, 0, 0, 0)
QuickGrid.AutomaticSize = Enum.AutomaticSize.Y
QuickGrid.BackgroundTransparency = 1
QuickGrid.Parent = QuickCard.Content
local QuickGridLayout = Instance.new("UIGridLayout")
QuickGridLayout.CellSize = UDim2.new(0.485, 0, 0, 32)
QuickGridLayout.CellPadding = UDim2.new(0.03, 0, 0, 8)
QuickGridLayout.Parent = QuickGrid
local function CreateQuickActionBtn(text, onClick)
    local btn = Instance.new("TextButton")
    btn.BackgroundColor3 = Theme.Element
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = Theme.Text
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 11
    btn.Parent = QuickGrid
    local bc = Instance.new("UICorner") bc.CornerRadius = UDim.new(0, 5) bc.Parent = btn
    RegisterThemedObject(btn, "BackgroundColor3", "Element")
    RegisterThemedObject(btn, "TextColor3", "Text")
    btn.MouseEnter:Connect(function()
        if getgenv().Destroyed then return end
        TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = Theme.Hover }):Play()
    end)
    btn.MouseLeave:Connect(function()
        if getgenv().Destroyed then return end
        TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = Theme.Element }):Play()
    end)
    btn.MouseButton1Click:Connect(function()
        if getgenv().Destroyed then return end
        if onClick then onClick() end
    end)
    return btn
end
CreateQuickActionBtn("Copy Discord", function()
    pcall(function() setclipboard("https://discord.gg/A7tZ9VbVvM") end)
    CustomNotify("Discord link copied to clipboard!", Theme.Accent, 3)
end)
CreateQuickActionBtn("Load last config", function()
    if env.LoadConfiguration then
        env.LoadConfiguration()
        CustomNotify("Configuration reloaded successfully!", Theme.Accent, 3)
    end
end)
CreateQuickActionBtn("Rejoin", function()
    pcall(function()
        if getgenv().AllowToxTeleport then getgenv().AllowToxTeleport(15, "Rejoin") end
        if #Players:GetPlayers() <= 1 then
            TeleportService:Teleport(game.PlaceId, Player)
        else
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Player)
        end
    end)
end)
CreateQuickActionBtn("Server hop", function()
    CustomNotify("Finding server...", Theme.Accent, 2)
    task.spawn(function()
        local success, result = pcall(function()
            local url = "https://games.roblox.com/v1/games/" .. tostring(game.PlaceId) .. "/servers/Public?sortOrder=Asc&limit=100"
            return HttpService:JSONDecode(game:HttpGet(url))
        end)
        if success and result and result.data then
            for _, s in ipairs(result.data) do
                if s.playing and s.playing < s.maxPlayers and s.id ~= game.JobId then
                    if getgenv().AllowToxTeleport then getgenv().AllowToxTeleport(15, "Server Hop") end
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, Player)
                    return
                end
            end
        end
        CustomNotify("No alternate server found", Color3.fromRGB(255, 100, 100), 3)
    end)
end)

CreateQuickActionBtn("Toggle watermark", function()
    Settings.Watermark = not Settings.Watermark
    WatermarkFrame.Visible = Settings.Watermark == true
    local _wmFn = UI.SetWatermarkSettingVisual; if _wmFn then _wmFn(Settings.Watermark == true)
    end
    if getgenv().AutoSaveConfiguration then getgenv().AutoSaveConfiguration() end
end)
CreateQuickActionBtn("Respawn", function()
    local plr = Players.LocalPlayer or Player
    local character = plr and plr.Character
    local hum = character and character:FindFirstChildOfClass("Humanoid")
    if hum then hum.Health = 0 end
end)
local AccountCard = CreateCard(HomePage, "Account", "🔑", 6, "Home_Account")
local AccRow = Instance.new("Frame")
AccRow.Size = UDim2.new(1, 0, 0, 34)
AccRow.BackgroundColor3 = Theme.Element
AccRow.BorderSizePixel = 0
AccRow.Parent = AccountCard.Content
local acCorner = Instance.new("UICorner") acCorner.CornerRadius = UDim.new(0, 5) acCorner.Parent = AccRow
RegisterThemedObject(AccRow, "BackgroundColor3", "Element")
local KeyStatusTitle = Instance.new("TextLabel")
KeyStatusTitle.Size = UDim2.new(0.5, -10, 1, 0)
KeyStatusTitle.Position = UDim2.new(0, 10, 0, 0)
KeyStatusTitle.BackgroundTransparency = 1
KeyStatusTitle.Text = "Key status"
KeyStatusTitle.TextColor3 = Theme.Text
KeyStatusTitle.Font = Enum.Font.GothamMedium
KeyStatusTitle.TextSize = 12
KeyStatusTitle.TextXAlignment = Enum.TextXAlignment.Left
KeyStatusTitle.Parent = AccRow
RegisterThemedObject(KeyStatusTitle, "TextColor3", "Text")
local KeyStatusVal = Instance.new("TextLabel")
KeyStatusVal.Size = UDim2.new(0.5, -10, 1, 0)
KeyStatusVal.Position = UDim2.new(0.5, 0, 0, 0)
KeyStatusVal.BackgroundTransparency = 1
KeyStatusVal.Text = "Premium"
KeyStatusVal.TextColor3 = Theme.Accent
KeyStatusVal.Font = Enum.Font.GothamBold
KeyStatusVal.TextSize = 12
KeyStatusVal.TextXAlignment = Enum.TextXAlignment.Right
KeyStatusVal.Parent = AccRow
RegisterThemedObject(KeyStatusVal, "TextColor3", "Accent")
local ReplaceKeyBtn = Instance.new("TextButton")
ReplaceKeyBtn.Size = UDim2.new(1, 0, 0, 32)
ReplaceKeyBtn.BackgroundColor3 = Theme.Element
ReplaceKeyBtn.BorderSizePixel = 0
ReplaceKeyBtn.Text = "Replace key"
ReplaceKeyBtn.TextColor3 = Theme.Text
ReplaceKeyBtn.Font = Enum.Font.GothamMedium
ReplaceKeyBtn.TextSize = 11
ReplaceKeyBtn.Parent = AccountCard.Content
local rkCorner = Instance.new("UICorner") rkCorner.CornerRadius = UDim.new(0, 5) rkCorner.Parent = ReplaceKeyBtn
RegisterThemedObject(ReplaceKeyBtn, "BackgroundColor3", "Element")
RegisterThemedObject(ReplaceKeyBtn, "TextColor3", "Text")
ReplaceKeyBtn.MouseButton1Click:Connect(function()
    CustomNotify("Key verified (Lifetime License)", Theme.Accent, 3)
end)
end
do
    local WatermarkFrame = UI.WatermarkFrame
    local MobileToggleBtn = UI.MobileToggleBtn
    local function StartWeatherEngine() if UI.StartWeatherEngine then return UI.StartWeatherEngine() end end
    local setWatermarkSettingVisual = nil
local MenuCard = CreateCard(SettingsPage, "Menu", "☰", 1, "Settings_Menu")
local function AddSettingsToggle(parent, name, defaultVal, callback)
    local row = Instance.new("TextButton")
    row.Size = UDim2.new(1, 0, 0, 34)
    row.BackgroundColor3 = Theme.Element
    row.BorderSizePixel = 0
    row.Text = ""
    row.AutoButtonColor = false
    row.Parent = parent
    local rCorner = Instance.new("UICorner") rCorner.CornerRadius = UDim.new(0, 5) rCorner.Parent = row
    RegisterThemedObject(row, "BackgroundColor3", "Element")
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -60, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Theme.Text
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row
    RegisterThemedObject(label, "TextColor3", "Text")
    local toggleBg = Instance.new("Frame")
    toggleBg.Size = UDim2.new(0, 36, 0, 18)
    toggleBg.Position = UDim2.new(1, -46, 0.5, -9)
    toggleBg.BackgroundColor3 = defaultVal and Theme.Accent or Theme.Panel
    toggleBg.BorderSizePixel = 0
    toggleBg.Parent = row
    local tCorner = Instance.new("UICorner") tCorner.CornerRadius = UDim.new(1, 0) tCorner.Parent = toggleBg
    local tStroke = Instance.new("UIStroke") tStroke.Color = Theme.Outline tStroke.Thickness = 1 tStroke.Parent = toggleBg
    RegisterThemedObject(tStroke, "Color", "Outline")
    local ball = Instance.new("Frame")
    ball.Size = UDim2.new(0, 14, 0, 14)
    ball.Position = defaultVal and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
    ball.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ball.BorderSizePixel = 0
    ball.Parent = toggleBg
    local bCorner = Instance.new("UICorner") bCorner.CornerRadius = UDim.new(1, 0) bCorner.Parent = ball
    local enabled = defaultVal == true
    local function UpdateVisual(val)
        enabled = val == true
        TweenService:Create(toggleBg, TweenInfo.new(0.2), {
            BackgroundColor3 = enabled and Theme.Accent or Theme.Panel
        }):Play()
        TweenService:Create(ball, TweenInfo.new(0.2), {
            Position = enabled and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
        }):Play()
    end
    row.MouseButton1Click:Connect(function()
        enabled = not enabled
        UpdateVisual(enabled)
        if callback then callback(enabled) end
        if getgenv().AutoSaveConfiguration then getgenv().AutoSaveConfiguration() end
    end)
    return UpdateVisual
end
AddSettingsToggle(MenuCard.Content, "Auto hide UI after execute", Settings.AutoCloseExecute, function(v)
    Settings.AutoCloseExecute = v
end)
setWatermarkSettingVisual = AddSettingsToggle(MenuCard.Content, "Watermark", Settings.Watermark == true, function(v)
    Settings.Watermark = v
    WatermarkFrame.Visible = v
end)
AddSettingsToggle(MenuCard.Content, "Mobile toggle button", Settings.MobileToggle ~= false, function(v)
    Settings.MobileToggle = v
    MobileToggleBtn.Visible = v
end)
AddSettingsToggle(MenuCard.Content, "Dim background", Settings.DimBackground == true, function(v)
    Settings.DimBackground = v
    if DimmerFrame then
        DimmerFrame.Visible = (v and Main.Visible)
    end
end)
local WeatherCard = CreateCard(SettingsPage, "Weather", "⛅", 2, "Settings_Weather")
local function AddSettingsDropdown(parent, name, options, defaultOption, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 36)
    row.BackgroundColor3 = Theme.Element
    row.BorderSizePixel = 0
    row.Parent = parent
    local rCorner = Instance.new("UICorner") rCorner.CornerRadius = UDim.new(0, 5) rCorner.Parent = row
    RegisterThemedObject(row, "BackgroundColor3", "Element")
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -110, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Theme.Text
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row
    RegisterThemedObject(label, "TextColor3", "Text")
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 108, 0, 24)
    btn.Position = UDim2.new(1, -118, 0.5, -12)
    btn.BackgroundColor3 = Theme.Panel
    btn.BorderSizePixel = 0
    btn.Text = tostring(defaultOption) .. "  v"
    btn.TextColor3 = Theme.Accent
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.TextTruncate = Enum.TextTruncate.AtEnd
    btn.Parent = row
    local bc = Instance.new("UICorner") bc.CornerRadius = UDim.new(0, 4) bc.Parent = btn
    local bs = Instance.new("UIStroke") bs.Color = Theme.Outline bs.Thickness = 1 bs.Parent = btn
    RegisterThemedObject(btn, "BackgroundColor3", "Panel")
    RegisterThemedObject(btn, "TextColor3", "Accent")
    RegisterThemedObject(bs, "Color", "Outline")
    local currentOpt = defaultOption
    btn.MouseButton1Click:Connect(function()
        if getgenv().ShowToxDropdownOverlay then
            btn.Text = tostring(currentOpt) .. "  ^"
            getgenv().ShowToxDropdownOverlay(btn, options, currentOpt, function(opt)
                currentOpt = opt
                btn.Text = tostring(opt) .. "  v"
                if callback then callback(opt) end
                if getgenv().AutoSaveConfiguration then getgenv().AutoSaveConfiguration() end
            end, function()
                btn.Text = tostring(currentOpt) .. "  v"
            end)
        end
    end)
end
AddSettingsDropdown(WeatherCard.Content, "Weather style", {"Off", "Snow", "Rain", "Stars"}, Settings.Weather or "Off", function(v)
    Settings.Weather = v
    StartWeatherEngine()
end)
AddSettingsDropdown(WeatherCard.Content, "Weather area", {"Inside UI", "Screen"}, Settings.WeatherArea or "Inside UI", function(v)
    Settings.WeatherArea = v
    StartWeatherEngine()
end)
local function AddSettingsSlider(parent, name, minVal, maxVal, defaultVal, suffix, callback)
    minVal = tonumber(minVal) or 0
    maxVal = tonumber(maxVal) or 100
    defaultVal = tonumber(defaultVal) or minVal
    if maxVal <= minVal then maxVal = minVal + 1 end
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 42)
    row.BackgroundColor3 = Theme.Element
    row.BorderSizePixel = 0
    row.Parent = parent
    local rCorner = Instance.new("UICorner") rCorner.CornerRadius = UDim.new(0, 5) rCorner.Parent = row
    RegisterThemedObject(row, "BackgroundColor3", "Element")
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -60, 0, 18)
    label.Position = UDim2.new(0, 10, 0, 4)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Theme.Text
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row
    RegisterThemedObject(label, "TextColor3", "Text")
    local valLabel = Instance.new("TextLabel")
    valLabel.Size = UDim2.new(0, 50, 0, 18)
    valLabel.Position = UDim2.new(1, -60, 0, 4)
    valLabel.BackgroundTransparency = 1
    valLabel.Text = tostring(defaultVal) .. (suffix or "")
    valLabel.TextColor3 = Theme.DimText
    valLabel.Font = Enum.Font.GothamBold
    valLabel.TextSize = 11
    valLabel.TextXAlignment = Enum.TextXAlignment.Right
    valLabel.Parent = row
    RegisterThemedObject(valLabel, "TextColor3", "DimText")
    local barWrap = Instance.new("TextButton")
    barWrap.Size = UDim2.new(1, -20, 0, 14)
    barWrap.Position = UDim2.new(0, 10, 0, 24)
    barWrap.BackgroundTransparency = 1
    barWrap.BorderSizePixel = 0
    barWrap.Text = ""
    barWrap.AutoButtonColor = false
    barWrap.Parent = row
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, 0, 0, 6)
    bar.Position = UDim2.new(0, 0, 0.5, -3)
    bar.BackgroundColor3 = Theme.Panel
    bar.BorderSizePixel = 0
    bar.Parent = barWrap
    local bc = Instance.new("UICorner") bc.CornerRadius = UDim.new(1, 0) bc.Parent = bar
    RegisterThemedObject(bar, "BackgroundColor3", "Panel")
    local initRel = math.clamp((defaultVal - minVal) / (maxVal - minVal), 0, 1)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(initRel, 0, 1, 0)
    fill.BackgroundColor3 = Theme.Accent
    fill.BorderSizePixel = 0
    fill.Parent = bar
    local fc = Instance.new("UICorner") fc.CornerRadius = UDim.new(1, 0) fc.Parent = fill
    RegisterThemedObject(fill, "BackgroundColor3", "Accent")
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 13, 0, 13)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new(initRel, 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.ZIndex = bar.ZIndex + 2
    knob.Parent = barWrap
    local kc = Instance.new("UICorner") kc.CornerRadius = UDim.new(1, 0) kc.Parent = knob
    local ks = Instance.new("UIStroke") ks.Color = Theme.Accent ks.Thickness = 1.5 ks.Parent = knob
    RegisterThemedObject(ks, "Color", "Accent")
    local currentVal = defaultVal
    local function Update(inpX)
        local rel = math.clamp((inpX - barWrap.AbsolutePosition.X) / math.max(barWrap.AbsoluteSize.X, 1), 0, 1)
        currentVal = math.floor(minVal + rel * (maxVal - minVal) + 0.5)
        valLabel.Text = tostring(currentVal) .. (suffix or "")
        fill.Size = UDim2.new(rel, 0, 1, 0)
        knob.Position = UDim2.new(rel, 0, 0.5, 0)
        if callback then callback(currentVal, true) end
    end
    barWrap.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            TweenService:Create(knob, TweenInfo.new(0.1), {Size = UDim2.new(0, 15, 0, 15)}):Play()
            Update(inp.Position.X)
            local moveConn, endConn
            moveConn = UserInputService.InputChanged:Connect(function(change)
                if change.UserInputType == Enum.UserInputType.MouseMovement or change.UserInputType == Enum.UserInputType.Touch then
                    Update(change.Position.X)
                end
            end)
            endConn = UserInputService.InputEnded:Connect(function(ended)
                if ended.UserInputType == Enum.UserInputType.MouseButton1 or ended.UserInputType == Enum.UserInputType.Touch then
                    TweenService:Create(knob, TweenInfo.new(0.1), {Size = UDim2.new(0, 13, 0, 13)}):Play()
                    if moveConn then pcall(function() moveConn:Disconnect() end) end
                    if endConn then pcall(function() endConn:Disconnect() end) end
                    if callback then callback(currentVal, false) end
                    if getgenv().AutoSaveConfiguration then getgenv().AutoSaveConfiguration() end
                end
            end)
        end
    end)
end
AddSettingsSlider(WeatherCard.Content, "Weather amount", 10, 100, Settings.WeatherAmount or 100, "%", function(v)
    Settings.WeatherAmount = v
    StartWeatherEngine()
end)
AddSettingsSlider(WeatherCard.Content, "Weather size", 30, 200, Settings.WeatherSize or 100, "%", function(v)
    Settings.WeatherSize = v
    StartWeatherEngine()
end)
    UI.AddSettingsToggle = AddSettingsToggle
    UI.AddSettingsDropdown = AddSettingsDropdown
    UI.AddSettingsSlider = AddSettingsSlider
    UI.SetWatermarkSettingVisual = setWatermarkSettingVisual
end
do
    local AddSettingsToggle = UI.AddSettingsToggle
    local AddSettingsSlider = UI.AddSettingsSlider
    local function SetSidebarCollapsed(v) if UI.SetSidebarCollapsed then UI.SetSidebarCollapsed(v) end end
    local function OpenColorPicker(k, s) if UI.OpenColorPicker then UI.OpenColorPicker(k, s) end end
    local CardLayoutOrder = UI.CardLayoutOrder or {}
    local CardRegistry = UI.CardRegistry or {}
    local MainGradient = UI.MainGradient
    local WallpaperImage = UI.WallpaperImage
    local HubLogo = UI.HubLogo
    local MobileToggleBtn = UI.MobileToggleBtn
local LayoutCard = CreateCard(SettingsPage, "Layout", "📐", 3, "Settings_Layout")
AddSettingsToggle(LayoutCard.Content, "Draggable cards", Settings.DraggableCards ~= false, function(v)
    Settings.DraggableCards = v
end)
AddSettingsToggle(LayoutCard.Content, "Collapse sidebar", Settings.CollapseSidebar == true, function(v)
    SetSidebarCollapsed(v)
end)
local ResetLayoutBtn = Instance.new("TextButton")
ResetLayoutBtn.Size = UDim2.new(1, 0, 0, 32)
ResetLayoutBtn.BackgroundColor3 = Theme.Element
ResetLayoutBtn.BorderSizePixel = 0
ResetLayoutBtn.Text = "Reset card layout"
ResetLayoutBtn.TextColor3 = Theme.Text
ResetLayoutBtn.Font = Enum.Font.GothamMedium
ResetLayoutBtn.TextSize = 11
ResetLayoutBtn.Parent = LayoutCard.Content
local rlbCorner = Instance.new("UICorner") rlbCorner.CornerRadius = UDim.new(0, 5) rlbCorner.Parent = ResetLayoutBtn
RegisterThemedObject(ResetLayoutBtn, "BackgroundColor3", "Element")
RegisterThemedObject(ResetLayoutBtn, "TextColor3", "Text")
ResetLayoutBtn.MouseButton1Click:Connect(function()
    for k in pairs(CardLayoutOrder) do CardLayoutOrder[k] = nil end
    Settings.CardLayoutOrder = {}
    for _, card in ipairs(CardRegistry) do
        if card and card.Parent then
            local def = card:GetAttribute("DefaultOrder") or 1
            card.LayoutOrder = def
        end
    end
    if getgenv().AutoSaveConfiguration then getgenv().AutoSaveConfiguration() end
    CustomNotify("Card layout reset to defaults!", Theme.Accent, 3)
end)
AddSettingsToggle(LayoutCard.Content, "Auto scale to screen", Settings.AutoScaleScreen ~= false, function(v)
    Settings.AutoScaleScreen = v
end)
local ColorsCard = CreateCard(SettingsPage, "Colors", "🎨", 4, "Settings_Colors")
AddSettingsToggle(ColorsCard.Content, "Window gradient", Settings.WindowGradient ~= false, function(v)
    Settings.WindowGradient = v
    MainGradient.Enabled = v
end)
AddSettingsToggle(ColorsCard.Content, "UI Rainbow (All Colors)", Settings.UIRainbow == true, function(v)
    Settings.UIRainbow = v
    if not v and getgenv().ApplyToxTheme then
        getgenv().ApplyToxTheme()
    end
end)
AddSettingsSlider(ColorsCard.Content, "UI Rainbow speed", 1, 100, math.floor(tonumber(Settings.UIRainbowSpeed) or 35), "%", function(v)
    Settings.UIRainbowSpeed = v
end)
AddSettingsSlider(ColorsCard.Content, "UI Transparency", 0, 100, math.floor((tonumber(Settings.ToxUITransparency) or 0) * 100 + 0.5), "%", function(v, isDragging)
    if getgenv().SetToxUITransparency then
        getgenv().SetToxUITransparency(v / 100, isDragging == true)
    end
    if getgenv().SyncValueVisuals then
        getgenv().SyncValueVisuals("UITransparencyPct", v)
    end
end)
local function AddColorSwatchRow(name, colorKey)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 34)
    row.BackgroundColor3 = Theme.Element
    row.BorderSizePixel = 0
    row.Parent = ColorsCard.Content
    local rc = Instance.new("UICorner") rc.CornerRadius = UDim.new(0, 5) rc.Parent = row
    RegisterThemedObject(row, "BackgroundColor3", "Element")
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -60, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Theme.Text
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row
    RegisterThemedObject(label, "TextColor3", "Text")
    local swatch = Instance.new("TextButton")
    swatch.Size = UDim2.new(0, 36, 0, 20)
    swatch.Position = UDim2.new(1, -46, 0.5, -10)
    swatch.BackgroundColor3 = Theme[colorKey] or Color3.fromRGB(255, 255, 255)
    swatch.BorderSizePixel = 0
    swatch.Text = ""
    swatch.AutoButtonColor = false
    swatch.Parent = row
    local sc = Instance.new("UICorner") sc.CornerRadius = UDim.new(0, 4) sc.Parent = swatch
    local ss = Instance.new("UIStroke") ss.Color = Theme.Outline ss.Thickness = 1 ss.Parent = swatch
    RegisterThemedObject(ss, "Color", "Outline")
    RegisterThemedObject(swatch, "BackgroundColor3", colorKey)
    swatch.MouseButton1Click:Connect(function()
        OpenColorPicker(colorKey, swatch)
    end)
end
AddColorSwatchRow("Background", "Background")
AddColorSwatchRow("Panel", "Panel")
AddColorSwatchRow("Element", "Element")
AddColorSwatchRow("Hover", "Hover")
AddColorSwatchRow("Outline", "Outline")
AddColorSwatchRow("Accent", "Accent")
AddColorSwatchRow("Accent 2", "Accent2")
AddColorSwatchRow("Text", "Text")
AddColorSwatchRow("DimText", "DimText")
AddColorSwatchRow("Risky", "Risky")
local WallpaperCard = CreateCard(SettingsPage, "Wallpaper", "🖼️", 5, "Settings_Wallpaper")
local WallUrlBox = Instance.new("TextBox")
WallUrlBox.Size = UDim2.new(1, 0, 0, 30)
WallUrlBox.BackgroundColor3 = Theme.Element
WallUrlBox.BorderSizePixel = 0
WallUrlBox.Text = Settings.WallpaperUrl or ""
WallUrlBox.PlaceholderText = "https://raw.githubusercontent.com/... or rbxassetid://..."
WallUrlBox.PlaceholderColor3 = Theme.DimText
WallUrlBox.TextColor3 = Theme.Text
WallUrlBox.Font = Enum.Font.Gotham
WallUrlBox.TextSize = 11
WallUrlBox.ClearTextOnFocus = false
WallUrlBox.Parent = WallpaperCard.Content
local wbCorner = Instance.new("UICorner") wbCorner.CornerRadius = UDim.new(0, 5) wbCorner.Parent = WallUrlBox
local wbPadding = Instance.new("UIPadding") wbPadding.PaddingLeft = UDim.new(0, 8) wbPadding.Parent = WallUrlBox
RegisterThemedObject(WallUrlBox, "BackgroundColor3", "Element")
RegisterThemedObject(WallUrlBox, "TextColor3", "Text")
RegisterThemedObject(WallUrlBox, "PlaceholderColor3", "DimText")
AddSettingsSlider(WallpaperCard.Content, "Wallpaper dim", 0, 100, math.floor((Settings.WallpaperDim or 0.25) * 100), "%", function(v)
    local dim = v / 100
    Settings.WallpaperDim = dim
    WallpaperImage.ImageTransparency = dim
end)
local WallBtnRow = Instance.new("Frame")
WallBtnRow.Size = UDim2.new(1, 0, 0, 30)
WallBtnRow.BackgroundTransparency = 1
WallBtnRow.Parent = WallpaperCard.Content
local ApplyWallBtn = Instance.new("TextButton")
ApplyWallBtn.Size = UDim2.new(0.65, -4, 1, 0)
ApplyWallBtn.BackgroundColor3 = Theme.Accent
ApplyWallBtn.BorderSizePixel = 0
ApplyWallBtn.Text = "Apply wallpaper"
ApplyWallBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ApplyWallBtn.Font = Enum.Font.GothamBold
ApplyWallBtn.TextSize = 11
ApplyWallBtn.Parent = WallBtnRow
local awCorner = Instance.new("UICorner") awCorner.CornerRadius = UDim.new(0, 5) awCorner.Parent = ApplyWallBtn
RegisterThemedObject(ApplyWallBtn, "BackgroundColor3", "Accent")
local ClearWallBtn = Instance.new("TextButton")
ClearWallBtn.Size = UDim2.new(0.35, -4, 1, 0)
ClearWallBtn.Position = UDim2.new(0.65, 4, 0, 0)
ClearWallBtn.BackgroundColor3 = Theme.Element
ClearWallBtn.BorderSizePixel = 0
ClearWallBtn.Text = "Clear"
ClearWallBtn.TextColor3 = Theme.Text
ClearWallBtn.Font = Enum.Font.GothamMedium
ClearWallBtn.TextSize = 11
ClearWallBtn.Parent = WallBtnRow
local cwCorner = Instance.new("UICorner") cwCorner.CornerRadius = UDim.new(0, 5) cwCorner.Parent = ClearWallBtn
RegisterThemedObject(ClearWallBtn, "BackgroundColor3", "Element")
RegisterThemedObject(ClearWallBtn, "TextColor3", "Text")
ApplyWallBtn.MouseButton1Click:Connect(function()
    local url = tostring(WallUrlBox.Text or "")
    Settings.WallpaperUrl = url
    WallpaperImage.Image = url
    if getgenv().AutoSaveConfiguration then getgenv().AutoSaveConfiguration() end
    CustomNotify("Wallpaper applied successfully!", Theme.Accent, 3)
end)
ClearWallBtn.MouseButton1Click:Connect(function()
    Settings.WallpaperUrl = ""
    WallUrlBox.Text = ""
    WallpaperImage.Image = ""
    if getgenv().AutoSaveConfiguration then getgenv().AutoSaveConfiguration() end
    CustomNotify("Wallpaper cleared", Theme.Accent, 2)
end)
local IconCard = CreateCard(SettingsPage, "Icon", "⭐", 6, "Settings_Icon")
local IconUrlBox = Instance.new("TextBox")
IconUrlBox.Size = UDim2.new(1, 0, 0, 30)
IconUrlBox.BackgroundColor3 = Theme.Element
IconUrlBox.BorderSizePixel = 0
IconUrlBox.Text = Settings.CustomIconUrl or ""
IconUrlBox.PlaceholderText = "image url or rbxassetid://..."
IconUrlBox.PlaceholderColor3 = Theme.DimText
IconUrlBox.TextColor3 = Theme.Text
IconUrlBox.Font = Enum.Font.Gotham
IconUrlBox.TextSize = 11
IconUrlBox.ClearTextOnFocus = false
IconUrlBox.Parent = IconCard.Content
local ibCorner = Instance.new("UICorner") ibCorner.CornerRadius = UDim.new(0, 5) ibCorner.Parent = IconUrlBox
local ibPadding = Instance.new("UIPadding") ibPadding.PaddingLeft = UDim.new(0, 8) ibPadding.Parent = IconUrlBox
RegisterThemedObject(IconUrlBox, "BackgroundColor3", "Element")
RegisterThemedObject(IconUrlBox, "TextColor3", "Text")
RegisterThemedObject(IconUrlBox, "PlaceholderColor3", "DimText")
local ApplyIconBtn = Instance.new("TextButton")
ApplyIconBtn.Size = UDim2.new(1, 0, 0, 30)
ApplyIconBtn.BackgroundColor3 = Theme.Element
ApplyIconBtn.BorderSizePixel = 0
ApplyIconBtn.Text = "Apply icon"
ApplyIconBtn.TextColor3 = Theme.Text
ApplyIconBtn.Font = Enum.Font.GothamMedium
ApplyIconBtn.TextSize = 11
ApplyIconBtn.Parent = IconCard.Content
local aibCorner = Instance.new("UICorner") aibCorner.CornerRadius = UDim.new(0, 5) aibCorner.Parent = ApplyIconBtn
RegisterThemedObject(ApplyIconBtn, "BackgroundColor3", "Element")
RegisterThemedObject(ApplyIconBtn, "TextColor3", "Text")
ApplyIconBtn.MouseButton1Click:Connect(function()
    local url = tostring(IconUrlBox.Text or "")
    if url ~= "" then
        Settings.CustomIconUrl = url
        HubLogo.Image = url
        MobileToggleBtn.Image = url
        if getgenv().AutoSaveConfiguration then getgenv().AutoSaveConfiguration() end
        CustomNotify("Custom icon applied!", Theme.Accent, 3)
    end
end)
end
do
    local StartSessionTime = UI.StartSessionTime or os.clock()
    local WatermarkFrame = UI.WatermarkFrame
    local WatermarkLabel = UI.WatermarkLabel
    local hs = UI.HomeStatus or {}
    local st = UI.HomeStats or {}
    local UpdateSessionPill = hs.Session or function() end
    local UpdateFeaturesPill = hs.Features or function() end
    local UpdateFPSPill = hs.FPS or function() end
    local UpdatePingPill = hs.Ping or function() end
    local UpdatePlayersPill = hs.Players or function() end
    local UpdatePlayersStat = st.Players
    local UpdateGameStat = st.Game
    local isMM2Game = st.IsMM2
    local UpdateMurdererStat = st.Murderer
    local UpdateSheriffStat = st.Sheriff
local CachedResolvedGameName = nil
task.spawn(function()
    pcall(function()
        if game.PlaceId and game.PlaceId ~= 0 then
            local info = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
            if info and info.Name and info.Name ~= "" then
                CachedResolvedGameName = info.Name
            end
        end
    end)
end)
task.spawn(function()
    local frameCount = 0
    local lastFpsTime = os.clock()
    local currentFps = 60
    RunService.RenderStepped:Connect(function()
        frameCount = frameCount + 1
        local now = os.clock()
        if now - lastFpsTime >= 0.5 then
            currentFps = math.floor(frameCount / (now - lastFpsTime) + 0.5)
            frameCount = 0
            lastFpsTime = now
        end
    end)
    while not getgenv().Destroyed do
        local elapsed = os.clock() - (StartSessionTime or os.clock())
        local mins = math.floor(elapsed / 60)
        local secs = math.floor(elapsed % 60)
        local timeStr = tostring(mins) .. "m " .. tostring(secs) .. "s"
        UpdateSessionPill(timeStr)
        local activeFeatures = 0
        if getgenv().ScriptLoaded == true then
            for k, v in pairs(Settings) do
                if v == true
                and k ~= "DraggableCards"
                and k ~= "AutoScaleScreen"
                and k ~= "WindowGradient"
                and k ~= "Render3D"
                and k ~= "MobileToggle"
                and k ~= "Watermark"
                and k ~= "UIRainbow"
                and k ~= "CustomAccentActive"
                and k ~= "CollapseSidebar"
                and k ~= "DimBackground"
                and k ~= "AutoCloseExecute"
                and k ~= "MM2AutoFarmAvoidMurderer"
                and k ~= "MM2VoteInfinite" then
                    activeFeatures = activeFeatures + 1
                end
            end
        end
        UpdateFeaturesPill(tostring(activeFeatures))
        UpdateFPSPill(tostring(currentFps))
        local pingVal = 45
        pcall(function()
            local raw = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValueString()
            local num = tonumber(string.match(raw, "%d+"))
            if num then pingVal = num end
        end)
        UpdatePingPill(tostring(pingVal) .. " ms")
        local pCount = #Players:GetPlayers()
        local maxP = Players.MaxPlayers
        UpdatePlayersPill(tostring(pCount) .. " / " .. tostring(maxP))
        if WatermarkFrame and WatermarkFrame.Visible and WatermarkLabel then
            WatermarkLabel.Text = "<b>ToxHud</b> v2.0  |  FPS: " .. tostring(currentFps) .. "  |  Ping: " .. tostring(pingVal) .. "ms"
        end
        pcall(function()
            if UpdatePlayersStat then
                UpdatePlayersStat(tostring(pCount))
            end
            if UpdateGameStat then
                local curMod = getgenv().CurrentGameModule
                if curMod then
                    UpdateGameStat(curMod.GameName or curMod.ShortName or "Universal")
                elseif CachedResolvedGameName then
                    UpdateGameStat(CachedResolvedGameName)
                end
            end
            if isMM2Game and UpdateMurdererStat and UpdateSheriffStat then
                local murd, sher = "None", "None"
                for _, p in ipairs(Players:GetPlayers()) do
                    local char = p.Character
                    local bp = p:FindFirstChild("Backpack")
                    if (char and char:FindFirstChild("Knife")) or (bp and bp:FindFirstChild("Knife")) then
                        murd = p.DisplayName
                    end
                    if (char and char:FindFirstChild("Gun")) or (bp and bp:FindFirstChild("Gun")) then
                        sher = p.DisplayName
                    end
                end
                UpdateMurdererStat(murd)
                UpdateSheriffStat(sher)
            end
        end)
        task.wait(1)
    end
end)
do
local SubGuisPreKeyHiddenState = getgenv().SubGuisPreKeyHiddenState or {}
getgenv().SubGuisPreKeyHiddenState = SubGuisPreKeyHiddenState
local function ToggleToxGui(forceVisible)
    if getgenv().CloseToxDropdownOverlay then
        pcall(getgenv().CloseToxDropdownOverlay)
    end
    local targetVisible = forceVisible
    if targetVisible == nil then
        targetVisible = not Main.Visible
    end
    Main.Visible = targetVisible
    if DimmerFrame then
        DimmerFrame.Visible = (Settings.DimBackground == true and targetVisible)
    end
    if not targetVisible then
        if getgenv().ChatLogGui and getgenv().ChatLogGui.Parent then
            SubGuisPreKeyHiddenState.ChatLog = getgenv().ChatLogGui.Visible
            getgenv().ChatLogGui.Visible = false
        end
        if getgenv().MusicGui and getgenv().MusicGui.Parent then
            SubGuisPreKeyHiddenState.Music = getgenv().MusicGui.Visible
            getgenv().MusicGui.Visible = false
        end
        if getgenv().WaypointsGui and getgenv().WaypointsGui.Parent then
            SubGuisPreKeyHiddenState.Waypoints = getgenv().WaypointsGui.Visible
            getgenv().WaypointsGui.Visible = false
        end
        for key, gui in pairs(getgenv().ToxLinkedSubGuis or {}) do
            if gui and gui.Parent then
                SubGuisPreKeyHiddenState["Extra_" .. tostring(key)] = gui.Visible
                gui.Visible = false
            end
        end
    else
        if not getgenv().ToxMainMinimized then
            if SubGuisPreKeyHiddenState.ChatLog ~= nil and getgenv().ChatLogGui and getgenv().ChatLogGui.Parent then
                getgenv().ChatLogGui.Visible = SubGuisPreKeyHiddenState.ChatLog
            end
            if SubGuisPreKeyHiddenState.Music ~= nil and getgenv().MusicGui and getgenv().MusicGui.Parent then
                getgenv().MusicGui.Visible = SubGuisPreKeyHiddenState.Music
            end
            if SubGuisPreKeyHiddenState.Waypoints ~= nil and getgenv().WaypointsGui and getgenv().WaypointsGui.Parent then
                getgenv().WaypointsGui.Visible = SubGuisPreKeyHiddenState.Waypoints
            end
            for key, gui in pairs(getgenv().ToxLinkedSubGuis or {}) do
                if gui and gui.Parent and SubGuisPreKeyHiddenState["Extra_" .. tostring(key)] ~= nil then
                    gui.Visible = SubGuisPreKeyHiddenState["Extra_" .. tostring(key)]
                end
            end
        end
    end
end
getgenv().ToggleToxGui = ToggleToxGui
UserInputService.InputBegan:Connect(function(input, gp)
    if gp or getgenv().Destroyed or not getgenv().ScriptLoaded then return end
    local matchKey = false
    if typeof(Settings.GUIKeybind) == "EnumItem" then
        matchKey = (input.KeyCode == Settings.GUIKeybind)
    elseif typeof(Settings.GUIKeybind) == "string" then
        matchKey = (input.KeyCode.Name == Settings.GUIKeybind)
    end
    if matchKey then
        ToggleToxGui()
    end
end)
end
    if UI.ToxOpenPage then
        UI.ToxOpenPage(HomePage)
    end
end
