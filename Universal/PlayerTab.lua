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
        if v then
            Settings.SmoothFly = false
            Settings.FlyBypass = false
        end
    end
end, function(val) Settings.FlySpeed = val end, "NormalFly")
CreateToggleWithValue("Smooth Fly", PlayerPage, Settings.SmoothFly, Settings.FlySpeed, function(v)
    if getgenv().ToxSetSharedOption then
        getgenv().ToxSetSharedOption("SmoothFly", v)
    else
        Settings.SmoothFly = v
        if v then
            Settings.NormalFly = false
            Settings.FlyBypass = false
        end
    end
end, function(val) Settings.FlySpeed = val end, "SmoothFly")
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
    local withSlider = env.CreateToggleWithSlider or getgenv().CreateToggleWithSlider
    if type(withSlider) == "function" then
        -- Slider 0-100 plus typed value (click the number to type)
        local control = withSlider("Fly Bypass", PlayerPage, 0, 100, Settings.FlyBypass, Settings.FlySpeed or 10, "", onFlyBypass, function(val)
            Settings.FlySpeed = tonumber(val) or 10
        end, "FlyBypass")
        if env.TrackUniversalControl then
            pcall(env.TrackUniversalControl, control, PlayerPage)
        end
    else
        CreateToggleWithValue("Fly Bypass", PlayerPage, Settings.FlyBypass, Settings.FlySpeed, onFlyBypass, function(val) Settings.FlySpeed = val end, "FlyBypass")
    end
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
