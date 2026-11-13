local env = getgenv()

if type(env.ToxUniversal3Cleanup) == "function" then
    pcall(env.ToxUniversal3Cleanup)
end

local token = {}
env.ToxUniversal3Token = token
env.ToxUniversal3Loaded = true

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local Player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera or Workspace:FindFirstChildOfClass("Camera")

local Settings = env.Settings or {}
local RoleColors = {
    Murderer = Color3.fromRGB(255, 50, 50),
    Sheriff = Color3.fromRGB(50, 150, 255),
    Innocent = Color3.fromRGB(50, 255, 50),
    Hero = Color3.fromRGB(50, 255, 255)
}
local MM2UnknownColor = Color3.fromRGB(235, 235, 235)

local function IsLocalPlayer(p)
    if not p then return true end
    if p == Player then return true end
    if p.UserId and Player and p.UserId == Player.UserId then return true end
    if p.Name and Player and p.Name == Player.Name then return true end
    return false
end

local function SafeRemoveDrawing(d)
    if not d then return end
    pcall(function() d.Visible = false end)
    pcall(function() d.Transparency = 0 end)
    pcall(function() d.From = Vector2.new(-10000, -10000) end)
    pcall(function() d.To = Vector2.new(-10000, -10000) end)
    pcall(function() d.Position = Vector2.new(-10000, -10000) end)
    pcall(function() d:Remove() end)
    pcall(function() d:Destroy() end)
end

if env.ToxMasterDrawingsList then
    for _, d in ipairs(env.ToxMasterDrawingsList) do
        SafeRemoveDrawing(d)
    end
end
env.ToxMasterDrawingsList = {}

if env.ToxESPDrawings then
    for _, drawings in pairs(env.ToxESPDrawings) do
        if typeof(drawings) == "table" then
            for k, drawing in pairs(drawings) do
                if k == "Skeleton" and typeof(drawing) == "table" then
                    for _, line in pairs(drawing) do
                        SafeRemoveDrawing(line)
                    end
                else
                    SafeRemoveDrawing(drawing)
                end
            end
        end
    end
end
if typeof(cleardrawcache) == "function" then
    pcall(cleardrawcache)
end

if env.ToxESPHighlights then
    for _, highlight in pairs(env.ToxESPHighlights) do
        pcall(function() highlight:Destroy() end)
    end
end

if env.ToxESPLabels then
    for _, label in pairs(env.ToxESPLabels) do
        pcall(function() label:Destroy() end)
    end
end

local ESPDrawings = {}
local Highlights = {}
local ESPLabels = {}
local ESPCharacterRefs = {}

env.ToxESPDrawings = ESPDrawings
env.ToxESPHighlights = Highlights
env.ToxESPLabels = ESPLabels

local function CreateTrackedDrawing(drawingType)
    if not Drawing or not Drawing.new then return nil end
    local ok, d = pcall(Drawing.new, drawingType)
    if ok and d then
        pcall(function()
            d.Visible = false
            d.Transparency = 0
            if drawingType == "Line" then
                d.From = Vector2.new(-10000, -10000)
                d.To = Vector2.new(-10000, -10000)
            elseif drawingType == "Square" or drawingType == "Circle" then
                d.Position = Vector2.new(-10000, -10000)
            end
        end)
        table.insert(env.ToxMasterDrawingsList, d)
        return d
    end
    return nil
end

local function HidePlayerDrawings(p)
    local grp = ESPDrawings[p]
    if not grp then return end
    if grp.Line then
        pcall(function()
            grp.Line.Visible = false
            grp.Line.Transparency = 0
            grp.Line.From = Vector2.new(-10000, -10000)
            grp.Line.To = Vector2.new(-10000, -10000)
        end)
    end
    if grp.Box then
        pcall(function()
            grp.Box.Visible = false
            grp.Box.Transparency = 0
            grp.Box.Position = Vector2.new(-10000, -10000)
        end)
    end
    if grp.HeadDot then
        pcall(function()
            grp.HeadDot.Visible = false
            grp.HeadDot.Transparency = 0
            grp.HeadDot.Position = Vector2.new(-10000, -10000)
        end)
    end
    if grp.Skeleton and typeof(grp.Skeleton) == "table" then
        for _, line in pairs(grp.Skeleton) do
            pcall(function()
                line.Visible = false
                line.Transparency = 0
                line.From = Vector2.new(-10000, -10000)
                line.To = Vector2.new(-10000, -10000)
            end)
        end
    end
end

local function ClearESPForPlayer(p)
    if ESPDrawings[p] then
        HidePlayerDrawings(p)
        for k, d in pairs(ESPDrawings[p]) do
            if k == "Skeleton" and typeof(d) == "table" then
                for _, line in pairs(d) do
                    SafeRemoveDrawing(line)
                end
            else
                SafeRemoveDrawing(d)
            end
        end
        ESPDrawings[p] = nil
    end

    if Highlights[p] then
        pcall(function() Highlights[p]:Destroy() end)
        Highlights[p] = nil
    end

    if ESPLabels[p] then
        pcall(function() ESPLabels[p]:Destroy() end)
        ESPLabels[p] = nil
    end

    ESPCharacterRefs[p] = nil
end

local function OnPlayerCharacterDespawn(p)
    HidePlayerDrawings(p)
    if Highlights[p] then
        pcall(function() Highlights[p]:Destroy() end)
        Highlights[p] = nil
    end
    if ESPLabels[p] then
        pcall(function() ESPLabels[p]:Destroy() end)
        ESPLabels[p] = nil
    end
    ESPCharacterRefs[p] = nil
end

local function ClearAllESPVisuals()
    local targets = {}
    for p in pairs(ESPDrawings) do targets[p] = true end
    for p in pairs(Highlights) do targets[p] = true end
    for p in pairs(ESPLabels) do targets[p] = true end
    for p in pairs(ESPCharacterRefs) do targets[p] = true end

    for p in pairs(targets) do
        ClearESPForPlayer(p)
    end

    for _, targetPlayer in ipairs(Players:GetPlayers()) do
        local character = targetPlayer.Character
        if character then
            for _, object in ipairs(character:GetDescendants()) do
                if object.Name == "ToxChams" or object.Name == "ToxESPName" or object.Name == "ToxESPHealth" then
                    pcall(function() object:Destroy() end)
                end
            end
        end
    end

    for k in pairs(ESPDrawings) do ESPDrawings[k] = nil end
    for k in pairs(Highlights) do Highlights[k] = nil end
    for k in pairs(ESPLabels) do ESPLabels[k] = nil end
    for k in pairs(ESPCharacterRefs) do ESPCharacterRefs[k] = nil end

    env.ToxESPDrawings = ESPDrawings
    env.ToxESPHighlights = Highlights
    env.ToxESPLabels = ESPLabels
end

env.ClearAllESPVisuals = ClearAllESPVisuals
env.ClearAllToxESPVisuals = ClearAllESPVisuals
env.ToxClearTracers = function()
    for _, grp in pairs(ESPDrawings) do
        if grp.Line then
            pcall(function()
                grp.Line.Visible = false
                grp.Line.From = Vector2.new(-10000, -10000)
                grp.Line.To = Vector2.new(-10000, -10000)
            end)
        end
    end
end
env.ToxClearSkeletons = function()
    for _, grp in pairs(ESPDrawings) do
        if grp.Skeleton and typeof(grp.Skeleton) == "table" then
            for _, line in pairs(grp.Skeleton) do
                pcall(function()
                    line.Visible = false
                    line.From = Vector2.new(-10000, -10000)
                    line.To = Vector2.new(-10000, -10000)
                end)
            end
        end
    end
end

local Theme_Panel = Color3.fromRGB(16, 16, 26)
local Theme_Outline = Color3.fromRGB(36, 36, 56)
local Theme_Accent = Color3.fromRGB(30, 95, 255)
local Theme_Text = Color3.fromRGB(255, 255, 255)
local Theme_DimText = Color3.fromRGB(140, 140, 160)

pcall(function()
    if env.ToxSpectatorsFrame then
        env.ToxSpectatorsFrame:Destroy()
        env.ToxSpectatorsFrame = nil
    end
    if env.ToxKeybindsFrame then
        env.ToxKeybindsFrame:Destroy()
        env.ToxKeybindsFrame = nil
    end
end)

local hudTargetParent = env.Gui or (gethui and gethui()) or CoreGui

-- 1. Spectator List Frame
local ToxSpectatorsFrame = Instance.new("Frame")
ToxSpectatorsFrame.Name = "ToxSpectatorsFrame"
ToxSpectatorsFrame.Size = UDim2.new(0, 180, 0, 120)
ToxSpectatorsFrame.Position = UDim2.new(0, 20, 0, 310)
ToxSpectatorsFrame.BackgroundColor3 = Theme_Panel
ToxSpectatorsFrame.BorderSizePixel = 0
ToxSpectatorsFrame.ZIndex = 999990
ToxSpectatorsFrame.Visible = Settings.SpectatorList == true
pcall(function() ToxSpectatorsFrame.Parent = hudTargetParent end)
env.ToxSpectatorsFrame = ToxSpectatorsFrame

local sfCorner = Instance.new("UICorner") sfCorner.CornerRadius = UDim.new(0, 6) sfCorner.Parent = ToxSpectatorsFrame
local sfStroke = Instance.new("UIStroke") sfStroke.Color = Theme_Outline sfStroke.Thickness = 1 sfStroke.Transparency = 0.3 sfStroke.Parent = ToxSpectatorsFrame

local sfAccent = Instance.new("Frame")
sfAccent.Size = UDim2.new(1, 0, 0, 2)
sfAccent.BackgroundColor3 = Theme_Accent
sfAccent.BorderSizePixel = 0
sfAccent.ZIndex = 999991
sfAccent.Parent = ToxSpectatorsFrame

local SpectatorsTitleLabel = Instance.new("TextLabel")
SpectatorsTitleLabel.Name = "Title"
SpectatorsTitleLabel.Size = UDim2.new(1, -12, 0, 22)
SpectatorsTitleLabel.Position = UDim2.new(0, 8, 0, 3)
SpectatorsTitleLabel.BackgroundTransparency = 1
SpectatorsTitleLabel.Font = Enum.Font.GothamBold
SpectatorsTitleLabel.TextSize = 11
SpectatorsTitleLabel.TextColor3 = Theme_Text
SpectatorsTitleLabel.Text = "Spectators (0)"
SpectatorsTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
SpectatorsTitleLabel.ZIndex = 999991
SpectatorsTitleLabel.Parent = ToxSpectatorsFrame

if env.RegisterThemedObject then
    env.RegisterThemedObject(ToxSpectatorsFrame, "BackgroundColor3", "Panel")
    env.RegisterThemedObject(sfStroke, "Color", "Outline")
    env.RegisterThemedObject(sfAccent, "BackgroundColor3", "Accent")
    env.RegisterThemedObject(SpectatorsTitleLabel, "TextColor3", "Text")
end
if env.ApplySavedGuiPosition then env.ApplySavedGuiPosition("Spectators", ToxSpectatorsFrame) end
if env.TrackGuiPosition then env.TrackGuiPosition("Spectators", ToxSpectatorsFrame) end

local SpectatorsContainer = Instance.new("ScrollingFrame")
SpectatorsContainer.Name = "Container"
SpectatorsContainer.Size = UDim2.new(1, -12, 1, -28)
SpectatorsContainer.Position = UDim2.new(0, 6, 0, 24)
SpectatorsContainer.BackgroundTransparency = 1
SpectatorsContainer.BorderSizePixel = 0
SpectatorsContainer.ScrollBarThickness = 2
SpectatorsContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
SpectatorsContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
SpectatorsContainer.ZIndex = 999991
SpectatorsContainer.Parent = ToxSpectatorsFrame

local scList = Instance.new("UIListLayout")
scList.SortOrder = Enum.SortOrder.LayoutOrder
scList.Padding = UDim.new(0, 2)
scList.Parent = SpectatorsContainer

if env.MakeDraggable then
    env.MakeDraggable(ToxSpectatorsFrame, ToxSpectatorsFrame)
end

-- 2. Keybinds List Frame
local ToxKeybindsFrame = Instance.new("Frame")
ToxKeybindsFrame.Name = "ToxKeybindsFrame"
ToxKeybindsFrame.Size = UDim2.new(0, 180, 0, 140)
ToxKeybindsFrame.Position = UDim2.new(0, 20, 0, 440)
ToxKeybindsFrame.BackgroundColor3 = Theme_Panel
ToxKeybindsFrame.BorderSizePixel = 0
ToxKeybindsFrame.ZIndex = 999990
ToxKeybindsFrame.Visible = Settings.KeybindsList == true
pcall(function() ToxKeybindsFrame.Parent = hudTargetParent end)
env.ToxKeybindsFrame = ToxKeybindsFrame

local kfCorner = Instance.new("UICorner") kfCorner.CornerRadius = UDim.new(0, 6) kfCorner.Parent = ToxKeybindsFrame
local kfStroke = Instance.new("UIStroke") kfStroke.Color = Theme_Outline kfStroke.Thickness = 1 kfStroke.Transparency = 0.3 kfStroke.Parent = ToxKeybindsFrame

local kfAccent = Instance.new("Frame")
kfAccent.Size = UDim2.new(1, 0, 0, 2)
kfAccent.BackgroundColor3 = Theme_Accent
kfAccent.BorderSizePixel = 0
kfAccent.ZIndex = 999991
kfAccent.Parent = ToxKeybindsFrame

local KeybindsTitleLabel = Instance.new("TextLabel")
KeybindsTitleLabel.Name = "Title"
KeybindsTitleLabel.Size = UDim2.new(1, -12, 0, 22)
KeybindsTitleLabel.Position = UDim2.new(0, 8, 0, 3)
KeybindsTitleLabel.BackgroundTransparency = 1
KeybindsTitleLabel.Font = Enum.Font.GothamBold
KeybindsTitleLabel.TextSize = 11
KeybindsTitleLabel.TextColor3 = Theme_Text
KeybindsTitleLabel.Text = "Keybinds"
KeybindsTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
KeybindsTitleLabel.ZIndex = 999991
KeybindsTitleLabel.Parent = ToxKeybindsFrame

if env.RegisterThemedObject then
    env.RegisterThemedObject(ToxKeybindsFrame, "BackgroundColor3", "Panel")
    env.RegisterThemedObject(kfStroke, "Color", "Outline")
    env.RegisterThemedObject(kfAccent, "BackgroundColor3", "Accent")
    env.RegisterThemedObject(KeybindsTitleLabel, "TextColor3", "Text")
end
if env.ApplySavedGuiPosition then env.ApplySavedGuiPosition("Keybinds", ToxKeybindsFrame) end
if env.TrackGuiPosition then env.TrackGuiPosition("Keybinds", ToxKeybindsFrame) end

local KeybindsContainer = Instance.new("ScrollingFrame")
KeybindsContainer.Name = "Container"
KeybindsContainer.Size = UDim2.new(1, -12, 1, -28)
KeybindsContainer.Position = UDim2.new(0, 6, 0, 24)
KeybindsContainer.BackgroundTransparency = 1
KeybindsContainer.BorderSizePixel = 0
KeybindsContainer.ScrollBarThickness = 2
KeybindsContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
KeybindsContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
KeybindsContainer.ZIndex = 999991
KeybindsContainer.Parent = ToxKeybindsFrame

local kcList = Instance.new("UIListLayout")
kcList.SortOrder = Enum.SortOrder.LayoutOrder
kcList.Padding = UDim.new(0, 2)
kcList.Parent = KeybindsContainer

if env.MakeDraggable then
    env.MakeDraggable(ToxKeybindsFrame, ToxKeybindsFrame)
end

-- Update Spectators List
local lastSpecUpdate = 0
local function ToxUpdateSpectators()
    if not Settings.SpectatorList then
        if ToxSpectatorsFrame.Visible then ToxSpectatorsFrame.Visible = false end
        return
    end
    if not ToxSpectatorsFrame.Visible then ToxSpectatorsFrame.Visible = true end

    local now = tick()
    if now - lastSpecUpdate < 0.4 then return end
    lastSpecUpdate = now

    local myChar = Player.Character
    local spectators = {}
    if myChar then
        local myRoot = myChar:FindFirstChild("HumanoidRootPart")
        for _, p in ipairs(Players:GetPlayers()) do
            if not IsLocalPlayer(p) and p.Character then
                local isSpectating = false
                pcall(function()
                    local pCam = Workspace.CurrentCamera
                    if pCam and pCam.CameraSubject and pCam.CameraSubject:IsDescendantOf(myChar) then
                        isSpectating = true
                    end
                end)
                if not isSpectating and myRoot and p.Character:FindFirstChild("HumanoidRootPart") then
                    local pRoot = p.Character.HumanoidRootPart
                    local dist = (pRoot.Position - myRoot.Position).Magnitude
                    local pHum = p.Character:FindFirstChildOfClass("Humanoid")
                    if dist < 4 and pHum and pHum.Health <= 0 then
                        isSpectating = true
                    end
                end
                if isSpectating then
                    table.insert(spectators, p.DisplayName or p.Name)
                end
            end
        end
    end

    SpectatorsTitleLabel.Text = "Spectators (" .. tostring(#spectators) .. ")"

    for _, child in ipairs(SpectatorsContainer:GetChildren()) do
        if child:IsA("TextLabel") then
            child:Destroy()
        end
    end

    if #spectators == 0 then
        local emptyLbl = Instance.new("TextLabel")
        emptyLbl.Size = UDim2.new(1, 0, 0, 18)
        emptyLbl.BackgroundTransparency = 1
        emptyLbl.Font = Enum.Font.Gotham
        emptyLbl.TextSize = 10
        emptyLbl.TextColor3 = Theme_DimText
        emptyLbl.Text = "No spectators"
        emptyLbl.TextXAlignment = Enum.TextXAlignment.Center
        emptyLbl.ZIndex = 999992
        emptyLbl.Parent = SpectatorsContainer
    else
        for _, name in ipairs(spectators) do
            local itemLbl = Instance.new("TextLabel")
            itemLbl.Size = UDim2.new(1, 0, 0, 18)
            itemLbl.BackgroundTransparency = 1
            itemLbl.Font = Enum.Font.GothamMedium
            itemLbl.TextSize = 10
            itemLbl.TextColor3 = Theme_Text
            itemLbl.Text = "• " .. name
            itemLbl.TextXAlignment = Enum.TextXAlignment.Left
            itemLbl.ZIndex = 999992
            itemLbl.Parent = SpectatorsContainer
        end
    end
end
env.ToxUpdateSpectators = ToxUpdateSpectators

-- Update Keybinds List
local lastKeyUpdate = 0
local function ToxUpdateKeybinds()
    if not Settings.KeybindsList then
        if ToxKeybindsFrame.Visible then ToxKeybindsFrame.Visible = false end
        return
    end
    if not ToxKeybindsFrame.Visible then ToxKeybindsFrame.Visible = true end

    local now = tick()
    if now - lastKeyUpdate < 0.3 then return end
    lastKeyUpdate = now

    local activeBinds = {}

    local function resolveKeyString(key)
        if typeof(key) == "EnumItem" then
            return key.Name
        elseif type(key) == "string" and key ~= "" then
            return key
        end
        return nil
    end

    if Settings.Aimbot then
        local k = resolveKeyString(Settings.AimbotKey) or "RMB"
        table.insert(activeBinds, { Name = "Aimbot", Key = k, Active = Settings.Aimbot == true })
    end
    if Settings.Speed then
        table.insert(activeBinds, { Name = "Speed", Key = "Toggle", Active = Settings.Speed == true })
    end
    if Settings.NormalFly or Settings.SmoothFly or Settings.FlyBypass then
        table.insert(activeBinds, { Name = "Fly", Key = "Toggle", Active = true })
    end
    if Settings.Noclip then
        table.insert(activeBinds, { Name = "Noclip", Key = "Toggle", Active = Settings.Noclip == true })
    end
    if Settings.CtrlClickTP then
        table.insert(activeBinds, { Name = "Ctrl TP", Key = "Ctrl+Click", Active = Settings.CtrlClickTP == true })
    end
    if Settings.ForceShiftLock then
        local k = Settings.ShiftLockKey or "Shift"
        table.insert(activeBinds, { Name = "ShiftLock", Key = k, Active = Settings.ForceShiftLock == true })
    end
    if Settings.TargetESP then
        table.insert(activeBinds, { Name = "Target ESP", Key = "Active", Active = Settings.TargetESP == true })
    end

    for _, child in ipairs(KeybindsContainer:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextLabel") then
            child:Destroy()
        end
    end

    if #activeBinds == 0 then
        local emptyLbl = Instance.new("TextLabel")
        emptyLbl.Size = UDim2.new(1, 0, 0, 18)
        emptyLbl.BackgroundTransparency = 1
        emptyLbl.Font = Enum.Font.Gotham
        emptyLbl.TextSize = 10
        emptyLbl.TextColor3 = Theme_DimText
        emptyLbl.Text = "No active binds"
        emptyLbl.TextXAlignment = Enum.TextXAlignment.Center
        emptyLbl.ZIndex = 999992
        emptyLbl.Parent = KeybindsContainer
    else
        for _, b in ipairs(activeBinds) do
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 18)
            row.BackgroundTransparency = 1
            row.ZIndex = 999992
            row.Parent = KeybindsContainer

            local nameLbl = Instance.new("TextLabel")
            nameLbl.Size = UDim2.new(0.6, 0, 1, 0)
            nameLbl.Position = UDim2.new(0, 0, 0, 0)
            nameLbl.BackgroundTransparency = 1
            nameLbl.Font = Enum.Font.GothamMedium
            nameLbl.TextSize = 10
            nameLbl.TextColor3 = Theme_Text
            nameLbl.Text = b.Name
            nameLbl.TextXAlignment = Enum.TextXAlignment.Left
            nameLbl.ZIndex = 999992
            nameLbl.Parent = row

            local keyLbl = Instance.new("TextLabel")
            keyLbl.Size = UDim2.new(0.4, 0, 1, 0)
            keyLbl.Position = UDim2.new(0.6, 0, 0, 0)
            keyLbl.BackgroundTransparency = 1
            keyLbl.Font = Enum.Font.GothamBold
            keyLbl.TextSize = 10
            keyLbl.TextColor3 = b.Active and Theme_Accent or Theme_DimText
            keyLbl.Text = b.Key
            keyLbl.TextXAlignment = Enum.TextXAlignment.Right
            keyLbl.ZIndex = 999992
            keyLbl.Parent = row
        end
    end
end
env.ToxUpdateKeybinds = ToxUpdateKeybinds

-- ==============================================================================
-- MM2 ROLE SYSTEM & FALLBACKS
-- ==============================================================================
local MM2GameId = 66654135
local MM2PlaceId = 142823291
local MM2RoleCache = {}
local MM2DeadCache = {}
local MM2RoleCacheTime = 0
local MM2PlayerDataRemote = nil
local MM2HasAuthoritativeData = false
env.ToxMM2StableRoleCache = env.ToxMM2StableRoleCache or {}

local function NormalizeRoleName(value)
    if typeof(value) ~= "string" or value == "" then return nil end
    local role = string.lower(value):gsub("[%s_%-%.]", "")
    if role == "murder" or role == "murderer" or role == "murderers" or role == "killer" then
        return "Murderer"
    end
    if role == "sheriff" or role == "detective" or role == "cop" or role == "officer" then
        return "Sheriff"
    end
    if role == "hero" or role == "savior" then
        return "Hero"
    end
    if role == "innocent" or role == "innocents" or role == "civilian" or role == "bystander" or role == "victim" then
        return "Innocent"
    end
    return nil
end

local function ResolveMM2Player(nameOrId)
    if typeof(nameOrId) == "Instance" and nameOrId:IsA("Player") then return nameOrId end
    if typeof(nameOrId) == "number" then
        for _, p in ipairs(Players:GetPlayers()) do
            if p.UserId == nameOrId then return p end
        end
        return nil
    end
    if typeof(nameOrId) == "string" and nameOrId ~= "" then
        local byExact = Players:FindFirstChild(nameOrId)
        if byExact and byExact:IsA("Player") then return byExact end
        local targetName = string.lower(nameOrId)
        for _, p in ipairs(Players:GetPlayers()) do
            if string.lower(p.Name) == targetName or string.lower(p.DisplayName) == targetName then
                return p
            end
        end
    end
    return nil
end

local function LooksLikeMM2PlayerData(data)
    if typeof(data) ~= "table" then return false end
    for key, value in pairs(data) do
        if ResolveMM2Player(key) then return true end
        if typeof(value) == "table" then
            for subKey, subValue in pairs(value) do
                if subKey == "Role" or subKey == "role" or NormalizeRoleName(subValue) then return true end
            end
        end
    end
    return false
end

local function NormalizeMM2PlayerDataContainer(data)
    if typeof(data) ~= "table" then return nil end
    if LooksLikeMM2PlayerData(data) then return data end
    for _, value in pairs(data) do
        if typeof(value) == "table" and LooksLikeMM2PlayerData(value) then return value end
    end
    return nil
end

local function ApplyMM2PlayerData(data)
    local container = NormalizeMM2PlayerDataContainer(data)
    if not container then return false end
    local applied = false
    local nextRoles = {}
    local nextDead = {}
    for playerKey, info in pairs(container) do
        local p = ResolveMM2Player(playerKey)
        if p and typeof(info) == "table" then
            applied = true
            local role = NormalizeRoleName(info.Role or info.role or info.Team or info.team)
            local dead = info.Killed or info.killed or info.Dead or info.dead
            if role then
                nextRoles[p] = role
            elseif dead ~= true then
                nextRoles[p] = "Innocent"
            end
            if dead ~= nil then nextDead[p] = dead == true end
        end
    end
    if applied then
        MM2RoleCache = nextRoles
        MM2DeadCache = nextDead
        env.ToxMM2StableRoleCache = {}
        for p, r in pairs(nextRoles) do
            env.ToxMM2StableRoleCache[p] = r
        end
        MM2RoleCacheTime = tick()
        MM2HasAuthoritativeData = true
    end
    return applied
end

local function ApplyMM2PlayerUpdate(playerKey, info)
    local p = ResolveMM2Player(playerKey)
    if not p or typeof(info) ~= "table" then return false end
    local role = NormalizeRoleName(info.Role or info.role or info.Team or info.team)
    local dead = info.Killed or info.killed or info.Dead or info.dead
    local changed = false
    if role then
        MM2RoleCache[p] = role
        env.ToxMM2StableRoleCache[p] = role
        changed = true
    end
    if dead ~= nil then
        MM2DeadCache[p] = dead == true
        changed = true
    end
    if changed then
        MM2RoleCacheTime = tick()
        MM2HasAuthoritativeData = true
    end
    return changed
end

local function HasNamedTool(p, names)
    if not p then return false end
    local char = p.Character
    local backpack = p:FindFirstChild("Backpack")
    for _, name in ipairs(names) do
        if char and char:FindFirstChild(name) then return true end
        if backpack and backpack:FindFirstChild(name) then return true end
    end
    if char then
        for _, obj in ipairs(char:GetChildren()) do
            if obj:IsA("Tool") then
                local lname = string.lower(obj.Name)
                for _, target in ipairs(names) do
                    if string.find(lname, string.lower(target), 1, true) then
                        return true
                    end
                end
            end
        end
    end
    if backpack then
        for _, obj in ipairs(backpack:GetChildren()) do
            if obj:IsA("Tool") then
                local lname = string.lower(obj.Name)
                for _, target in ipairs(names) do
                    if string.find(lname, string.lower(target), 1, true) then
                        return true
                    end
                end
            end
        end
    end
    return false
end

local function GetAttributeRole(p)
    if not p then return nil end
    local roleAttr = p:GetAttribute("Role") or p:GetAttribute("role")
    local direct = NormalizeRoleName(roleAttr)
    if direct then return direct end
    local char = p.Character
    if char then
        local charRole = char:GetAttribute("Role") or char:GetAttribute("role")
        direct = NormalizeRoleName(charRole)
        if direct then return direct end
    end
    return nil
end

local MM2SheriffNames = {"Gun", "Revolver", "SheriffGun", "DefaultGun"}
local MM2MurdererNames = {"Knife", "Blade", "Dagger", "DefaultKnife", "Sword"}

local function OverlayLiveMM2Tools()
    for _, p in ipairs(Players:GetPlayers()) do
        if HasNamedTool(p, MM2MurdererNames) then
            MM2RoleCache[p] = "Murderer"
            env.ToxMM2StableRoleCache[p] = "Murderer"
        elseif HasNamedTool(p, MM2SheriffNames) then
            local cur = MM2RoleCache[p]
            local nextRole = (cur == "Hero") and "Hero" or "Sheriff"
            MM2RoleCache[p] = nextRole
            env.ToxMM2StableRoleCache[p] = nextRole
        else
            local attrRole = GetAttributeRole(p)
            if attrRole then
                MM2RoleCache[p] = attrRole
                env.ToxMM2StableRoleCache[p] = attrRole
            elseif not MM2RoleCache[p] and not env.ToxMM2StableRoleCache[p] then
                MM2RoleCache[p] = "Innocent"
            end
        end
    end
end

local function FetchMM2PlayerDataFromRemote()
    if game.GameId ~= MM2GameId and game.PlaceId ~= MM2PlaceId then
        return false
    end
    if not MM2PlayerDataRemote or not MM2PlayerDataRemote.Parent then
        MM2PlayerDataRemote = ReplicatedStorage:FindFirstChild("GetPlayerData", true)
    end
    if not MM2PlayerDataRemote or not MM2PlayerDataRemote:IsA("RemoteFunction") then
        return false
    end
    local ok, data = pcall(function()
        return MM2PlayerDataRemote:InvokeServer()
    end)
    if ok and typeof(data) == "table" then
        if next(data) == nil then
            MM2HasAuthoritativeData = false
            MM2RoleCache = {}
            MM2DeadCache = {}
            env.ToxMM2StableRoleCache = {}
            OverlayLiveMM2Tools()
            MM2RoleCacheTime = tick()
            return false
        end
        local applied = ApplyMM2PlayerData(data)
        OverlayLiveMM2Tools()
        return applied
    end
    return false
end

local function BuildMM2FallbackRoles()
    local nextRoles = {}

    for _, p in ipairs(Players:GetPlayers()) do
        local attrRole = GetAttributeRole(p)
        if attrRole then
            nextRoles[p] = attrRole
        else
            local hasKnife = HasNamedTool(p, MM2MurdererNames)
            local hasGun = HasNamedTool(p, MM2SheriffNames)
            if hasKnife then
                nextRoles[p] = "Murderer"
            elseif hasGun then
                nextRoles[p] = "Sheriff"
            elseif env.ToxMM2StableRoleCache[p] then
                nextRoles[p] = env.ToxMM2StableRoleCache[p]
            else
                nextRoles[p] = "Innocent"
            end
        end
    end
    return nextRoles
end

local function RefreshMM2Roles(force)
    if (game.GameId ~= MM2GameId and game.PlaceId ~= MM2PlaceId) then return end
    local now = tick()
    if not force and (now - MM2RoleCacheTime) < 0.35 then return end

    if not MM2HasAuthoritativeData or force then
        local fallback = BuildMM2FallbackRoles()
        for p, r in pairs(fallback) do
            if not MM2HasAuthoritativeData or not MM2RoleCache[p] then
                MM2RoleCache[p] = r
            end
        end
    end
    OverlayLiveMM2Tools()
    MM2RoleCacheTime = now
end

local function GetESPVisualInfo(p)
    local defaultColor = Settings.EspColor or Color3.fromRGB(255, 255, 255)
    local mm2RoleESPActive = (game.GameId == MM2GameId or game.PlaceId == MM2PlaceId) and Settings.MM2RoleESP == true

    if Settings.VisualRainbow == true and not mm2RoleESPActive then
        local speed = math.clamp(tonumber(Settings.RainbowSpeed) or 25, 1, 100)
        local hue = (os.clock() * (speed / 140)) % 1
        return Color3.fromHSV(hue, 0.98, 1), nil
    end

    if not Settings.ESPTeamColors and not mm2RoleESPActive then
        return defaultColor, nil
    end

    if game.GameId == MM2GameId or game.PlaceId == MM2PlaceId then
        local role = MM2RoleCache[p] or env.ToxMM2StableRoleCache[p] or GetAttributeRole(p)
        if not role then
            if HasNamedTool(p, MM2MurdererNames) then
                role = "Murderer"
            elseif HasNamedTool(p, MM2SheriffNames) then
                role = "Sheriff"
            else
                role = "Innocent"
            end
        end
        return RoleColors[role] or MM2UnknownColor, role
    end

    local attributeRole = GetAttributeRole(p)
    if attributeRole then
        return RoleColors[attributeRole] or defaultColor, attributeRole
    end

    if p and p.Team then
        local ok, teamColor = pcall(function() return p.TeamColor.Color end)
        if ok and typeof(teamColor) == "Color3" then
            return teamColor, p.Team.Name
        end
    end

    return defaultColor, nil
end

env.GetToxMM2Role = function(p)
    if not p then return nil end
    local cached = MM2RoleCache[p] or env.ToxMM2StableRoleCache[p]
    if cached then return cached end
    if HasNamedTool(p, MM2MurdererNames) then return "Murderer" end
    if HasNamedTool(p, MM2SheriffNames) then return "Sheriff" end
    return nil
end
env.ToxGetMM2Role = env.GetToxMM2Role
env.ToxRefreshMM2Roles = function(force)
    RefreshMM2Roles(force == true)
    task.spawn(function()
        pcall(FetchMM2PlayerDataFromRemote)
        OverlayLiveMM2Tools()
    end)
end
env.ToxClearMM2Roles = function()
    MM2RoleCache = {}
    MM2DeadCache = {}
    env.ToxMM2StableRoleCache = {}
    MM2HasAuthoritativeData = false
    MM2RoleCacheTime = 0
end

-- ReplicatedStorage Remote Events for MM2
local mm2Connections = {}
if game.GameId == MM2GameId or game.PlaceId == MM2PlaceId then
    pcall(function()
        local updatePlayerData = ReplicatedStorage:FindFirstChild("UpdatePlayerData", true)
        if updatePlayerData and updatePlayerData:IsA("RemoteEvent") then
            table.insert(mm2Connections, updatePlayerData.OnClientEvent:Connect(function(...)
                local args = {...}
                if #args >= 2 and ApplyMM2PlayerUpdate(args[1], args[2]) then return end
                for _, value in ipairs(args) do
                    if ApplyMM2PlayerData(value) then return end
                end
                task.defer(function() RefreshMM2Roles(true) end)
            end))
        end

        local roleSelect = ReplicatedStorage:FindFirstChild("RoleSelect", true)
        if roleSelect and roleSelect:IsA("RemoteEvent") then
            table.insert(mm2Connections, roleSelect.OnClientEvent:Connect(function(...)
                local args = {...}
                for _, value in ipairs(args) do
                    local normalized = NormalizeRoleName(value)
                    if normalized then
                        MM2RoleCache[Player] = normalized
                        env.ToxMM2StableRoleCache[Player] = normalized
                        MM2DeadCache[Player] = false
                        MM2RoleCacheTime = tick()
                        break
                    end
                end
                task.delay(0.1, function() RefreshMM2Roles(true) end)
            end))
        end

        table.insert(mm2Connections, Players.PlayerRemoving:Connect(function(p)
            MM2RoleCache[p] = nil
            MM2DeadCache[p] = nil
            env.ToxMM2StableRoleCache[p] = nil
            ClearESPForPlayer(p)
        end))
    end)

    task.spawn(function()
        while env.ToxUniversal3Token == token and not env.Destroyed do
            if env.ScriptLoaded and (Settings.MM2RoleESP or Settings.ESPEnabled or Settings.ESPTeamColors) then
                pcall(FetchMM2PlayerDataFromRemote)
                pcall(OverlayLiveMM2Tools)
                task.wait(0.75)
            else
                task.wait(0.35)
            end
        end
    end)
end

-- ==============================================================================
-- MAIN ESP & HUD RENDER LOOP (RunService.RenderStepped)
-- ==============================================================================
local lastMM2ToolTick = 0
local espConnection = nil
espConnection = RunService.RenderStepped:Connect(function(delta)
    if env.Destroyed or env.ToxUniversal3Token ~= token then
        if espConnection then
            espConnection:Disconnect()
            espConnection = nil
        end
        return
    end
    if not env.ScriptLoaded then return end

    Camera = Workspace.CurrentCamera or Camera
    if not Camera then return end

    -- Floating HUD Updates
    if Settings.SpectatorList then
        ToxUpdateSpectators()
    end
    if Settings.KeybindsList then
        ToxUpdateKeybinds()
    end

    -- Determine ESP State
    local mm2RoleESPActive = (game.GameId == MM2GameId or game.PlaceId == MM2PlaceId) and Settings.MM2RoleESP == true
    if (game.GameId == MM2GameId or game.PlaceId == MM2PlaceId) and (mm2RoleESPActive or Settings.ESPTeamColors) then
        local now = tick()
        if now - lastMM2ToolTick >= 0.25 then
            lastMM2ToolTick = now
            OverlayLiveMM2Tools()
        end
    end
    local effectiveESPEnabled = Settings.ESPEnabled or mm2RoleESPActive
    local effectiveESPNames = Settings.ESPNames or mm2RoleESPActive
    local effectiveChams = Settings.Chams or mm2RoleESPActive
    local effectiveTeamColors = Settings.ESPTeamColors or mm2RoleESPActive

    local anyESPActive = effectiveESPEnabled and (
        effectiveESPNames
        or Settings.ESPDistance
        or Settings.ESPTracers
        or Settings.ESPBox
        or Settings.ESPHeadDot
        or Settings.ESPSkeleton
        or effectiveChams
    )

    -- If all ESP is disabled, cleanly hide everything
    if not anyESPActive then
        for p, _ in pairs(ESPDrawings) do
            HidePlayerDrawings(p)
        end
        for p, hl in pairs(Highlights) do
            pcall(function() hl:Destroy() end)
            Highlights[p] = nil
        end
        for p, bb in pairs(ESPLabels) do
            pcall(function() bb:Destroy() end)
            ESPLabels[p] = nil
        end
        return
    end

    -- Clean up disconnected players
    for p, _ in pairs(ESPDrawings) do
        if not p or not p.Parent or not Players:FindFirstChild(p.Name) then
            ClearESPForPlayer(p)
        end
    end

    local localChar = Player.Character
    local localRoot = localChar and localChar:FindFirstChild("HumanoidRootPart")

    -- Process each player
    for _, p in ipairs(Players:GetPlayers()) do
        if not IsLocalPlayer(p) then
            local char = p.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")

            if char and hrp and hum and hum.Health > 0 then
                if ESPCharacterRefs[p] and ESPCharacterRefs[p] ~= char then
                    OnPlayerCharacterDespawn(p)
                end
                ESPCharacterRefs[p] = char

                local distFromMe = localRoot and (localRoot.Position - hrp.Position).Magnitude or (Camera.CFrame.Position - hrp.Position).Magnitude
                local maxDist = (Settings.EspMaxDistEnabled == true) and (tonumber(Settings.EspMaxDistance) or 1000) or 0
                local withinDist = (maxDist <= 0) or (distFromMe <= maxDist)

                if withinDist then
                    local espColor, espRole = GetESPVisualInfo(p)
                    local isCurrentTarget = Settings.TargetESP and env.ToxCurrentTarget and (char == env.ToxCurrentTarget)
                    if isCurrentTarget then
                        espColor = Settings.TargetESPColor or Color3.fromRGB(255, 30, 30)
                    end

                    -- 1. Chams / Highlights
                    if effectiveChams then
                        local hl = Highlights[p]
                        if not hl or hl.Parent ~= char then
                            if hl then pcall(function() hl:Destroy() end) end
                            hl = Instance.new("Highlight")
                            hl.Name = "ToxChams"
                            hl.Adornee = char
                            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                            hl.Parent = char
                            Highlights[p] = hl
                        end
                        if isCurrentTarget then
                            hl.FillColor = Settings.TargetESPColor or Color3.fromRGB(255, 30, 30)
                            hl.OutlineColor = Color3.fromRGB(255, 0, 0)
                            hl.FillTransparency = 0.3
                        else
                            hl.FillColor = espColor
                            hl.OutlineColor = espColor
                            hl.FillTransparency = 0.5
                        end
                    elseif Highlights[p] then
                        pcall(function() Highlights[p]:Destroy() end)
                        Highlights[p] = nil
                    end

                    -- 2. Billboard Text (Names / Distance)
                    if (effectiveESPNames or Settings.ESPDistance) and withinDist then
                        local billboard = ESPLabels[p]
                        if not billboard or billboard.Parent ~= char then
                            if billboard then pcall(function() billboard:Destroy() end) end
                            billboard = Instance.new("BillboardGui")
                            billboard.Name = "ToxESPName"
                            billboard.Adornee = char:FindFirstChild("Head") or hrp
                            billboard.AlwaysOnTop = true
                            billboard.Size = UDim2.fromOffset(320, 44)
                            billboard.StudsOffset = Vector3.new(0, 3.2, 0)
                            billboard.MaxDistance = maxDist > 0 and maxDist or 100000
                            billboard.Parent = char

                            local label = Instance.new("TextLabel")
                            label.Name = "Label"
                            label.Size = UDim2.fromScale(1, 1)
                            label.BackgroundTransparency = 1
                            label.TextColor3 = espColor
                            label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                            label.TextStrokeTransparency = 0
                            label.TextSize = 13
                            label.Font = Enum.Font.Gotham
                            label.TextWrapped = true
                            label.TextXAlignment = Enum.TextXAlignment.Center
                            label.TextYAlignment = Enum.TextYAlignment.Center
                            label.Parent = billboard

                            ESPLabels[p] = billboard
                        end

                        local label = billboard:FindFirstChild("Label")
                        local lines = {}

                        if effectiveESPNames then
                            local mode = Settings.ESPNameMode or "Display"
                            local nameText = p.DisplayName
                            if mode == "Name" then
                                nameText = "@" .. p.Name
                            elseif mode == "Name + Display" then
                                nameText = p.DisplayName .. " (@" .. p.Name .. ")"
                            end

                            if effectiveTeamColors and espRole then
                                nameText = nameText .. " [" .. espRole .. "]"
                            end
                            if isCurrentTarget then
                                nameText = "[TARGET] " .. nameText
                            end
                            table.insert(lines, nameText)
                        end

                        if Settings.ESPDistance then
                            table.insert(lines, "Dist: " .. math.floor(distFromMe) .. "m")
                        end

                        if label then
                            label.Text = table.concat(lines, "\n")
                            label.TextColor3 = espColor
                        end
                        billboard.Enabled = #lines > 0
                    elseif ESPLabels[p] then
                        pcall(function() ESPLabels[p]:Destroy() end)
                        ESPLabels[p] = nil
                    end

                    -- 3. Drawing ESP: Tracers, 2D Box, Head Dot, Skeletons
                    local hasDrawingESP = Drawing and (Settings.ESPTracers or Settings.ESPBox or Settings.ESPHeadDot or Settings.ESPSkeleton)
                    if hasDrawingESP then
                        local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)

                        if not ESPDrawings[p] then
                            ESPDrawings[p] = {
                                Line = CreateTrackedDrawing("Line"),
                                Box = CreateTrackedDrawing("Square"),
                                HeadDot = CreateTrackedDrawing("Circle")
                            }
                        end

                        local lineDraw = ESPDrawings[p].Line
                        local boxDraw = ESPDrawings[p].Box
                        local headDraw = ESPDrawings[p].HeadDot

                        -- CRITICAL: Only draw if onScreen and strictly in front of the camera (pos.Z > 1)
                        if onScreen and pos.Z > 1 then
                            -- Tracers
                            if Settings.ESPTracers and lineDraw then
                                local startVector = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                                if Settings.TracerOrigin == "UP" then
                                    startVector = Vector2.new(Camera.ViewportSize.X / 2, 0)
                                elseif Settings.TracerOrigin == "MOUSE" then
                                    startVector = UserInputService:GetMouseLocation()
                                end

                                lineDraw.From = startVector
                                lineDraw.To = Vector2.new(pos.X, pos.Y)
                                lineDraw.Color = espColor
                                lineDraw.Thickness = isCurrentTarget and 2.5 or 1.2
                                lineDraw.Transparency = 1
                                lineDraw.Visible = true
                            elseif lineDraw then
                                lineDraw.Visible = false
                                lineDraw.From = Vector2.new(-10000, -10000)
                                lineDraw.To = Vector2.new(-10000, -10000)
                            end

                            -- 2D Box
                            if Settings.ESPBox and boxDraw then
                                local boxHeight = math.clamp(1000 / pos.Z, 12, 350)
                                local boxWidth = boxHeight * 0.65
                                boxDraw.Size = Vector2.new(boxWidth, boxHeight)
                                boxDraw.Position = Vector2.new(pos.X - boxWidth / 2, pos.Y - boxHeight / 2)
                                boxDraw.Color = espColor
                                boxDraw.Thickness = isCurrentTarget and 2.5 or 1.5
                                boxDraw.Filled = false
                                boxDraw.Transparency = 1
                                boxDraw.Visible = true
                            elseif boxDraw then
                                boxDraw.Visible = false
                                boxDraw.Position = Vector2.new(-10000, -10000)
                            end

                            -- Head Dot
                            if Settings.ESPHeadDot and headDraw then
                                local head = char:FindFirstChild("Head")
                                if head then
                                    local hp, hon = Camera:WorldToViewportPoint(head.Position)
                                    if hon and hp.Z > 1 then
                                        headDraw.Position = Vector2.new(hp.X, hp.Y)
                                        headDraw.Radius = isCurrentTarget and 6 or 4
                                        headDraw.Filled = true
                                        headDraw.Color = espColor
                                        headDraw.Transparency = 1
                                        headDraw.Visible = true
                                    else
                                        headDraw.Visible = false
                                        headDraw.Position = Vector2.new(-10000, -10000)
                                    end
                                else
                                    headDraw.Visible = false
                                    headDraw.Position = Vector2.new(-10000, -10000)
                                end
                            elseif headDraw then
                                headDraw.Visible = false
                                headDraw.Position = Vector2.new(-10000, -10000)
                            end

                            -- Skeletons
                            if Settings.ESPSkeleton then
                                local bonesR15 = {
                                    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
                                    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
                                    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
                                    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
                                    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}
                                }
                                local bonesR6 = {
                                    {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"},
                                    {"Torso", "Left Leg"}, {"Torso", "Right Leg"}
                                }
                                local isR15 = char:FindFirstChild("UpperTorso") ~= nil
                                local boneList = isR15 and bonesR15 or bonesR6

                                if not ESPDrawings[p].Skeleton then
                                    ESPDrawings[p].Skeleton = {}
                                end
                                local skelLines = ESPDrawings[p].Skeleton

                                for idx, pair in ipairs(boneList) do
                                    if not skelLines[idx] then
                                        skelLines[idx] = CreateTrackedDrawing("Line")
                                    end
                                    local sLine = skelLines[idx]
                                    local partA = char:FindFirstChild(pair[1])
                                    local partB = char:FindFirstChild(pair[2])

                                    if sLine and partA and partB then
                                        local posA, onA = Camera:WorldToViewportPoint(partA.Position)
                                        local posB, onB = Camera:WorldToViewportPoint(partB.Position)
                                        if posA.Z > 1 and posB.Z > 1 and onA and onB then
                                            sLine.From = Vector2.new(posA.X, posA.Y)
                                            sLine.To = Vector2.new(posB.X, posB.Y)
                                            sLine.Color = espColor
                                            sLine.Thickness = isCurrentTarget and 2.5 or 1.5
                                            sLine.Transparency = 1
                                            sLine.Visible = true
                                        else
                                            sLine.Visible = false
                                            sLine.From = Vector2.new(-10000, -10000)
                                            sLine.To = Vector2.new(-10000, -10000)
                                        end
                                    elseif sLine then
                                        sLine.Visible = false
                                        sLine.From = Vector2.new(-10000, -10000)
                                        sLine.To = Vector2.new(-10000, -10000)
                                    end
                                end

                                for i = #boneList + 1, #skelLines do
                                    if skelLines[i] then
                                        skelLines[i].Visible = false
                                        skelLines[i].From = Vector2.new(-10000, -10000)
                                        skelLines[i].To = Vector2.new(-10000, -10000)
                                    end
                                end
                            elseif ESPDrawings[p].Skeleton then
                                for _, line in ipairs(ESPDrawings[p].Skeleton) do
                                    line.Visible = false
                                    line.From = Vector2.new(-10000, -10000)
                                    line.To = Vector2.new(-10000, -10000)
                                end
                            end
                        else
                            -- NOT onScreen or behind camera: IMMEDIATELY hide all drawings!
                            HidePlayerDrawings(p)
                        end
                    elseif ESPDrawings[p] then
                        HidePlayerDrawings(p)
                    end
                else
                    -- Exceeds max distance: hide
                    HidePlayerDrawings(p)
                    if Highlights[p] then pcall(function() Highlights[p]:Destroy() end) Highlights[p] = nil end
                    if ESPLabels[p] then pcall(function() ESPLabels[p]:Destroy() end) ESPLabels[p] = nil end
                end
            else
                OnPlayerCharacterDespawn(p)
            end
        end
    end
end)

-- Full Cleanup Routine
env.ToxUniversal3Cleanup = function()
    if espConnection then
        pcall(function() espConnection:Disconnect() end)
        espConnection = nil
    end

    for _, conn in ipairs(mm2Connections) do
        pcall(function() conn:Disconnect() end)
    end
    mm2Connections = {}

    pcall(function()
        if ToxSpectatorsFrame then
            ToxSpectatorsFrame:Destroy()
            env.ToxSpectatorsFrame = nil
        end
        if ToxKeybindsFrame then
            ToxKeybindsFrame:Destroy()
            env.ToxKeybindsFrame = nil
        end
    end)

    ClearAllESPVisuals()
end

