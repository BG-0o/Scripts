local env = getgenv()
if env.Destroyed or env.ToxUniversalLoaded then
    return
end
env.ToxUniversal = env.ToxUniversal or {}
local U = env.ToxUniversal
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local Settings = env.Settings or {}
local PlayerPage = env.PlayerPage
local CreateToggle = env.CreateToggle
local CreateToggleWithValue = env.CreateToggleWithValue
local CreateDropdown = env.CreateDropdown
local BeginUniversalSection = env.BeginUniversalSection or function() end
local function CustomNotify(...) if env.CustomNotify then return env.CustomNotify(...) end end
local function UpdateAirWalk(...) if env.UpdateAirWalk then return env.UpdateAirWalk(...) end end
local GetHumanoidDefaults = U.GetHumanoidDefaults or function() end
local RestoreJump = U.RestoreJump or function() end

-- Fallback Combat UI if Universal/Combat.lua did not populate CombatPage
do
    local combatLoaded = env.ToxCombatLoaded == true
    local cPage = getgenv().CombatPage or getgenv().UniversalPage
    local hasChildren = false
    if cPage then
        for _, ch in ipairs(cPage:GetChildren()) do
            if ch:IsA("GuiObject") and not ch:IsA("UIListLayout") and not ch:IsA("UIPadding") then
                hasChildren = true
                break
            end
        end
    end
    if not combatLoaded or not hasChildren then
        local Settings = getgenv().Settings or Settings or {}
        local beginSection = getgenv().BeginUniversalSection or (typeof(BeginUniversalSection) == "function" and BeginUniversalSection)
        if typeof(beginSection) == "function" then
            beginSection("Combat")
        end
        local createToggle = getgenv().CreateToggle or (typeof(CreateToggle) == "function" and CreateToggle)
        local createToggleWithValue = getgenv().CreateToggleWithValue or (typeof(CreateToggleWithValue) == "function" and CreateToggleWithValue)
        local createDropdown = getgenv().CreateDropdown or (typeof(CreateDropdown) == "function" and CreateDropdown)
        if typeof(createToggle) == "function" then
            createToggle("Aimbot (Right Click)", cPage, Settings.Aimbot, function(v)
                Settings.Aimbot = v == true
                if getgenv().AutoSaveConfiguration then pcall(getgenv().AutoSaveConfiguration) end
            end, "Aimbot")
        end
        if typeof(createToggleWithValue) == "function" then
            createToggleWithValue("Aim Smoothness", cPage, Settings.AimbotSmoothnessEnabled, Settings.AimbotSmoothness or 2, function(v)
                Settings.AimbotSmoothnessEnabled = v == true
                if getgenv().AutoSaveConfiguration then pcall(getgenv().AutoSaveConfiguration) end
            end, function(val)
                Settings.AimbotSmoothness = tonumber(val) or 2
                if getgenv().AutoSaveConfiguration then pcall(getgenv().AutoSaveConfiguration) end
            end, "AimbotSmoothnessEnabled")
        end
        if typeof(createDropdown) == "function" then
            createDropdown("Aim Part", {"Head", "HumanoidRootPart", "Torso"}, cPage, Settings.AimPart or "Head", function(v)
                Settings.AimPart = v
                if getgenv().AutoSaveConfiguration then pcall(getgenv().AutoSaveConfiguration) end
            end)
        end
        if typeof(createToggle) == "function" then
            createToggle("Aim Wall Check", cPage, Settings.AimWallCheck, function(v)
                Settings.AimWallCheck = v == true
                if getgenv().AutoSaveConfiguration then pcall(getgenv().AutoSaveConfiguration) end
            end, "AimWallCheck")
        end
        if typeof(createToggleWithValue) == "function" then
            createToggleWithValue("Show FOV Circle", cPage, Settings.ShowFOV, Settings.FOVRadius or 120, function(v)
                Settings.ShowFOV = v == true
                if getgenv().AutoSaveConfiguration then pcall(getgenv().AutoSaveConfiguration) end
            end, function(val)
                Settings.FOVRadius = tonumber(val) or 120
                if getgenv().AutoSaveConfiguration then pcall(getgenv().AutoSaveConfiguration) end
            end, "ShowFOV")
        end
        if typeof(createToggle) == "function" then
            createToggle("Silent Aim", cPage, Settings.SilentAim, function(v)
                Settings.SilentAim = v == true
                if getgenv().AutoSaveConfiguration then pcall(getgenv().AutoSaveConfiguration) end
            end, "SilentAim")
        end
        if typeof(createToggle) == "function" then
            createToggle("Triggerbot", cPage, Settings.Triggerbot, function(v)
                Settings.Triggerbot = v == true
                if getgenv().AutoSaveConfiguration then pcall(getgenv().AutoSaveConfiguration) end
            end, "Triggerbot")
        end
        if typeof(createToggleWithValue) == "function" then
            createToggleWithValue("Spinbot", cPage, Settings.Spinbot, Settings.SpinSpeed or 50, function(v)
                Settings.Spinbot = v == true
                if getgenv().AutoSaveConfiguration then pcall(getgenv().AutoSaveConfiguration) end
            end, function(val)
                Settings.SpinSpeed = tonumber(val) or 50
                if getgenv().AutoSaveConfiguration then pcall(getgenv().AutoSaveConfiguration) end
            end, "Spinbot")
        end
        if typeof(createToggleWithValue) == "function" then
            createToggleWithValue("Hitbox Expander", cPage, Settings.HitboxExpander, Settings.HitboxSize or 10, function(v)
                Settings.HitboxExpander = v == true
                if not v and getgenv().RestoreHitboxDefaults then
                    pcall(getgenv().RestoreHitboxDefaults)
                end
                if getgenv().AutoSaveConfiguration then pcall(getgenv().AutoSaveConfiguration) end
            end, function(val)
                Settings.HitboxSize = tonumber(val) or 10
                if getgenv().AutoSaveConfiguration then pcall(getgenv().AutoSaveConfiguration) end
            end, "HitboxExpander")
        end
        if typeof(createToggleWithValue) == "function" then
            createToggleWithValue("Kill Aura", cPage, Settings.KillAura, Settings.KillAuraRange or 15, function(v)
                Settings.KillAura = v == true
                if getgenv().AutoSaveConfiguration then pcall(getgenv().AutoSaveConfiguration) end
            end, function(val)
                Settings.KillAuraRange = tonumber(val) or 15
                if getgenv().AutoSaveConfiguration then pcall(getgenv().AutoSaveConfiguration) end
            end, "KillAura")
        end
    end
end
do
BeginUniversalSection("Player")
CreateToggleWithValue("Speed", PlayerPage, Settings.Speed, Settings.SpeedValue, function(v)
    if getgenv().ToxSetSharedOption then
        getgenv().ToxSetSharedOption("Speed", v)
    end
end, function(val)
    Settings.SpeedValue = val
end, "Speed")
CreateToggleWithValue("Jump", PlayerPage, Settings.Jump, Settings.JumpValue, function(v)
    if v then
        local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
        GetHumanoidDefaults(hum)
    end
    Settings.Jump = v
    if not v then
        RestoreJump()
    end
end, function(val) Settings.JumpValue = val end)
CreateToggle("Noclip", PlayerPage, Settings.Noclip, function(v)
    if getgenv().ToxSetSharedOption then
        getgenv().ToxSetSharedOption("Noclip", v)
    end
end, "Noclip")
CreateToggle("Infinite Jump", PlayerPage, Settings.InfiniteJump, function(v)
    Settings.InfiniteJump = v
end)
CreateToggle("Air Walk (E Up / Q Down)", PlayerPage, Settings.AirWalk, function(v)
    Settings.AirWalk = v
    UpdateAirWalk()
end)
CreateToggleWithValue("Normal Fly", PlayerPage, Settings.NormalFly, Settings.FlySpeed, function(v)
    if getgenv().ToxSetSharedOption then
        getgenv().ToxSetSharedOption("NormalFly", v)
    else
        Settings.NormalFly = v
        if v then Settings.SmoothFly = false end
    end
end, function(val) Settings.FlySpeed = val end, "NormalFly")
CreateToggleWithValue("Smooth Fly", PlayerPage, Settings.SmoothFly, Settings.FlySpeed, function(v)
    if getgenv().ToxSetSharedOption then
        getgenv().ToxSetSharedOption("SmoothFly", v)
    else
        Settings.SmoothFly = v
        if v then Settings.NormalFly = false end
    end
end, function(val) Settings.FlySpeed = val end, "SmoothFly")
CreateToggleWithValue("Bhop (Auto Jump)", PlayerPage, Settings.Bhop, Settings.BhopInterval, function(v)
    Settings.Bhop = v
end, function(val)
    Settings.BhopInterval =
        math.max(
            0.05,
            val
        )
end)
CreateToggleWithValue("Car Speed", PlayerPage, Settings.CarSpeed, Settings.CarSpeedValue, function(v)
    Settings.CarSpeed = v
end, function(val)
    Settings.CarSpeedValue = val
end)
CreateToggleWithValue("Car Fly", PlayerPage, Settings.CarFly, Settings.CarFlySpeed, function(v)
    if getgenv().ToxSetSharedOption then
        getgenv().ToxSetSharedOption("CarFly", v)
    else
        Settings.CarFly = v
    end
end, function(val)
    Settings.CarFlySpeed = val
end, "CarFly")

local airPlatform = nil
CreateToggle("Air Walk Platform", PlayerPage, Settings.AirWalkPlatform == true, function(v)
    Settings.AirWalkPlatform = v
    if v then
        task.spawn(function()
            while Settings.AirWalkPlatform and not getgenv().Destroyed do
                local char = Player.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    if not airPlatform or not airPlatform.Parent then
                        airPlatform = Instance.new("Part")
                        airPlatform.Name = "ToxAirPlatform"
                        airPlatform.Size = Vector3.new(6, 1, 6)
                        airPlatform.Anchored = true
                        airPlatform.Transparency = 0.8
                        airPlatform.CanCollide = true
                        local activeTheme = getgenv().Theme
                        airPlatform.Color = (activeTheme and activeTheme.Accent) or Color3.fromRGB(45, 95, 255)
                        airPlatform.Parent = workspace
                    end
                    airPlatform.CFrame = CFrame.new(hrp.Position.X, hrp.Position.Y - 3.4, hrp.Position.Z)
                end
                task.wait(0.03)
            end
            if airPlatform then pcall(function() airPlatform:Destroy() end) airPlatform = nil end
        end)
    else
        if airPlatform then pcall(function() airPlatform:Destroy() end) airPlatform = nil end
    end
end, "AirWalkPlatform")

local lastDeathCFrame = nil
Player.CharacterAdded:Connect(function(char)
    if Settings.ReturnByDeath and lastDeathCFrame then
        task.wait(0.5)
        local hrp = char:WaitForChild("HumanoidRootPart", 5)
        if hrp and lastDeathCFrame then
            hrp.CFrame = lastDeathCFrame
            CustomNotify("Returned to death location!", Color3.fromRGB(80, 255, 140))
            lastDeathCFrame = nil
        end
    end
    local hum = char:WaitForChild("Humanoid", 5)
    if hum then
        hum.Died:Connect(function()
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                lastDeathCFrame = hrp.CFrame
            end
        end)
    end
end)
CreateToggle("Return By Death", PlayerPage, Settings.ReturnByDeath == true, function(v)
    Settings.ReturnByDeath = v
end, "ReturnByDeath")
end
