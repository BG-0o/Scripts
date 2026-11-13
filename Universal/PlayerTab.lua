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


-- Toggle + slider (with typed value). Falls back to the old typed-only control.
local function ValueSlider(Name, Page, MinV, MaxV, Toggle, Value, OnToggle, OnValue, SyncKey)
    local withSlider = env.CreateToggleWithSlider or getgenv().CreateToggleWithSlider
    if type(withSlider) == "function" then
        local control = withSlider(Name, Page, MinV, MaxV, Toggle, Value, "", OnToggle, OnValue, SyncKey)
        if env.TrackUniversalControl then
            pcall(env.TrackUniversalControl, control, Page)
        end
        return control
    end
    return CreateToggleWithValue(Name, Page, Toggle, Value, OnToggle, OnValue, SyncKey)
end
env.ToxValueSlider = ValueSlider

-- The 3 flies share Settings.FlySpeed: keep all their sliders in sync
local function SetFlySpeed(val)
    Settings.FlySpeed = tonumber(val) or 10
    if getgenv().SyncValueVisuals then
        for _, key in ipairs({ "NormalFly", "SmoothFly", "FlyBypass" }) do
            pcall(getgenv().SyncValueVisuals, key, Settings.FlySpeed)
        end
    end
end

do
BeginUniversalSection("Player")
ValueSlider("Speed", PlayerPage, 0, 200, Settings.Speed, Settings.SpeedValue, function(v)
    if getgenv().ToxSetSharedOption then
        getgenv().ToxSetSharedOption("Speed", v)
    end
end, function(val)
    Settings.SpeedValue = val
end, "Speed")
ValueSlider("Jump", PlayerPage, 0, 300, Settings.Jump, Settings.JumpValue, function(v)
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
CreateToggle("Air Walk (Space Up / Ctrl Down)", PlayerPage, Settings.AirWalk, function(v)
    Settings.AirWalk = v
    UpdateAirWalk()
end)
ValueSlider("Normal Fly", PlayerPage, 0, 100, Settings.NormalFly, Settings.FlySpeed, function(v)
    if getgenv().ToxSetSharedOption then
        getgenv().ToxSetSharedOption("NormalFly", v)
    else
        Settings.NormalFly = v
        if v then
            Settings.SmoothFly = false
            Settings.FlyBypass = false
        end
    end
end, SetFlySpeed, "NormalFly")
ValueSlider("Smooth Fly", PlayerPage, 0, 100, Settings.SmoothFly, Settings.FlySpeed, function(v)
    if getgenv().ToxSetSharedOption then
        getgenv().ToxSetSharedOption("SmoothFly", v)
    else
        Settings.SmoothFly = v
        if v then
            Settings.NormalFly = false
            Settings.FlyBypass = false
        end
    end
end, SetFlySpeed, "SmoothFly")
do
    local function onFlyBypass(v)
        if getgenv().ToxSetSharedOption then
            getgenv().ToxSetSharedOption("FlyBypass", v)
        else
            Settings.FlyBypass = v
            if v then
                Settings.NormalFly = false
                Settings.SmoothFly = false
            end
        end
    end
    ValueSlider("Fly Bypass", PlayerPage, 0, 100, Settings.FlyBypass, Settings.FlySpeed or 10, onFlyBypass, SetFlySpeed, "FlyBypass")
end
CreateToggleWithValue("Bhop (Auto Jump)", PlayerPage, Settings.Bhop, Settings.BhopInterval, function(v)
    Settings.Bhop = v
end, function(val)
    Settings.BhopInterval =
        math.max(
            0.05,
            val
        )
end)
ValueSlider("Car Speed", PlayerPage, 0, 300, Settings.CarSpeed, Settings.CarSpeedValue, function(v)
    Settings.CarSpeed = v
end, function(val)
    Settings.CarSpeedValue = val
end)
ValueSlider("Car Fly", PlayerPage, 5, 300, Settings.CarFly, Settings.CarFlySpeed, function(v)
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
                    -- Top of the platform exactly at the feet (it used to sit 0.1 stud too high
                    -- and kept pushing the player up)
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    local standOffset = 3
                    if hum and hum.RigType == Enum.HumanoidRigType.R15 then
                        standOffset = hum.HipHeight + hrp.Size.Y / 2
                    end
                    airPlatform.CFrame = CFrame.new(hrp.Position.X, hrp.Position.Y - standOffset - 0.55, hrp.Position.Z)
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
