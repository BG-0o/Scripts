local env = getgenv()
if env.Destroyed or env.ToxUniversalLoaded then
    return
end
env.ToxUniversal = env.ToxUniversal or {}
local U = env.ToxUniversal
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Player = Players.LocalPlayer
local Settings = env.Settings or {}
local FlingPage = env.FlingPage
local ScriptsPage = env.ScriptsPage
local MusicGui = env.MusicGui
local WaypointsGui = env.WaypointsGui
local CreateToggle = env.CreateToggle
local CreateButton = env.CreateButton
local CreateInputWithTwoButtons = env.CreateInputWithTwoButtons
local CreateToggleCycleOption = U.CreateToggleCycleOption or env.CreateToggleCycleOption
local BeginUniversalSection = env.BeginUniversalSection or function() end
local function CustomNotify(...) if env.CustomNotify then return env.CustomNotify(...) end end
local function AddConnection(...) if env.AddConnection then return env.AddConnection(...) end end
local CaptureShiftLockDefaults = U.CaptureShiftLockDefaults or function() end
local RestoreShiftLockDefaults = U.RestoreShiftLockDefaults or function() end
local ExecuteFling = U.ExecuteFling or function() end
local ExecuteTeleport = U.ExecuteTeleport or function() end
BeginUniversalSection("Misc")
CreateToggle("Ctrl Click TP", FlingPage, Settings.CtrlClickTP, function(v)
    if getgenv().ToxSetSharedOption then getgenv().ToxSetSharedOption("CtrlClickTP", v) end
end, "CtrlClickTP")
CreateToggle("Walk Fling", FlingPage, Settings.WalkFling, function(v)
    if getgenv().ToxSetSharedOption then
        getgenv().ToxSetSharedOption(
            "WalkFling",
            v
        )
    end
end, "WalkFling")
CreateToggle("No Fall Damage", FlingPage, Settings.NoFallDamage, function(v)
    if getgenv().ToxSetSharedOption then getgenv().ToxSetSharedOption("NoFallDamage", v) end
end, "NoFallDamage")
CreateToggle("Anti Void", FlingPage, Settings.AntiVoid, function(v)
    if getgenv().ToxSetSharedOption then getgenv().ToxSetSharedOption("AntiVoid", v) end
end, "AntiVoid")
CreateToggle("Anti Fling", FlingPage, Settings.AntiFling, function(v)
    if getgenv().ToxSetSharedOption then getgenv().ToxSetSharedOption("AntiFling", v) end
end, "AntiFling")
CreateToggle("Instant Proximity Prompts", FlingPage, Settings.InstantPrompts == true, function(v)
    Settings.InstantPrompts = v
    if v then
        for _, prompt in ipairs(workspace:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") then
                prompt.HoldDuration = 0
            end
        end
    end
end, "InstantPrompts")
AddConnection(workspace.DescendantAdded:Connect(function(desc)
    if Settings.InstantPrompts and not getgenv().Destroyed and desc:IsA("ProximityPrompt") then
        desc.HoldDuration = 0
    end
end))
CreateToggle("Tool Magnet", FlingPage, Settings.ToolMagnet == true, function(v)
    Settings.ToolMagnet = v
    if v then
        task.spawn(function()
            while Settings.ToolMagnet and not getgenv().Destroyed do
                local char = Player.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    for _, item in ipairs(workspace:GetChildren()) do
                        if item:IsA("BackpackItem") or item:IsA("Tool") then
                            local handle = item:FindFirstChild("Handle")
                            if handle then
                                handle.CFrame = hrp.CFrame
                            end
                        end
                    end
                end
                task.wait(0.5)
            end
        end)
    end
end, "ToolMagnet")
CreateToggleCycleOption(
    "Force Shift Lock",
    FlingPage,
    Settings.ForceShiftLock,
    {"Shift", "Ctrl"},
    Settings.ShiftLockKey or "Shift",
    function(v)
        if v then
            CaptureShiftLockDefaults()
        end
        Settings.ForceShiftLock = v == true
        if not Settings.ForceShiftLock then
            if U.SetShiftLockActive then U.SetShiftLockActive(false) end
            RestoreShiftLockDefaults()
        end
    end,
    function(v)
        Settings.ShiftLockKey = v == "Ctrl" and "Ctrl" or "Shift"
        if U.SetShiftLockActive then U.SetShiftLockActive(false) end
        if Settings.ForceShiftLock then
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        end
    end
)
U.LoopFlingInput = nil
U.LoopFlingGeneration = 0
local function ToggleLoopFling(
    text
)
    local cleaned =
        tostring(
            text
            or ""
        ):
            match(
                "^%s*(.-)%s*$"
            )
        or ""
    if cleaned == "" then
        U.LoopFlingInput = nil
        U.LoopFlingGeneration = (U.LoopFlingGeneration or 0) + 1
        CustomNotify(
            "Loop Fling Disabled",
            Color3.fromRGB(
                255,
                120,
                120
            )
        )
        return
    end
    local normalized =
        string.lower(
            cleaned
        )
    if U.LoopFlingInput
    and string.lower(
        U.LoopFlingInput
    ) == normalized then
        U.LoopFlingInput = nil
        U.LoopFlingGeneration = (U.LoopFlingGeneration or 0) + 1
        CustomNotify(
            "Loop Fling Disabled",
            Color3.fromRGB(
                255,
                120,
                120
            )
        )
        return
    end
    U.LoopFlingInput =
        cleaned
    U.LoopFlingGeneration = (U.LoopFlingGeneration or 0) + 1
    local generation =
        U.LoopFlingGeneration
    CustomNotify(
        "Loop Fling Enabled • "
        .. cleaned,
        Color3.fromRGB(
            100,
            255,
            130
        )
    )
    task.spawn(function()
        while U.LoopFlingInput
        and generation
            == U.LoopFlingGeneration
        and not getgenv().Destroyed do
            local activeInput =
                U.LoopFlingInput
            if not activeInput then
                break
            end
            local lower =
                string.lower(
                    activeInput
                )
            if lower ~= "all"
            and lower ~= "others" then
                local found = false
                for _, target in ipairs(
                    Players:
                        GetPlayers()
                ) do
                    if target ~= Player
                    and (
                        string.find(
                            string.lower(
                                target.Name
                            ),
                            lower,
                            1,
                            true
                        )
                        or string.find(
                            string.lower(
                                target.DisplayName
                            ),
                            lower,
                            1,
                            true
                        )
                    ) then
                        found = true
                        break
                    end
                end
                if not found then
                    U.LoopFlingInput = nil
                    CustomNotify(
                        "Loop Fling stopped • player left",
                        Color3.fromRGB(
                            255,
                            180,
                            70
                        )
                    )
                    break
                end
            end
            ExecuteFling(
                activeInput
            )
            task.wait(1.25)
        end
    end)
end
CreateInputWithTwoButtons(
    "Fling",
    FlingPage,
    "",
    "Fling",
    "Loop",
    function(text, mode)
        if mode == "LOOP" then
            ToggleLoopFling(
                text
            )
        else
            ExecuteFling(
                text
            )
        end
    end
)
CreateInputWithTwoButtons("Teleport", FlingPage, "", "TP", "Loop TP", function(text, mode) ExecuteTeleport(text, mode) end)
CreateButton("Tox Music Player", FlingPage, function() MusicGui.Visible = not MusicGui.Visible end)
CreateButton("Tox Waypoints", FlingPage, function() WaypointsGui.Visible = not WaypointsGui.Visible end)
do
    local SCRIPTS_BASE = "https://raw.githubusercontent.com/BG-0o/Scripts/refs/heads/main/Scripts/"
    local function RunCommunityScript(label, relFile)
        local ok, err = pcall(function()
            local cacheBuster = "?toxcache=" .. tostring(os.time()) .. "_" .. tostring(math.random(1000, 999999))
            local src = game:HttpGet(SCRIPTS_BASE .. relFile .. cacheBuster)
            local chunk, compErr = loadstring(src)
            if not chunk then
                error(tostring(compErr or "compile error"))
            end
            chunk()
        end)
        if not ok then
            CustomNotify("Failed to load " .. label .. ": " .. tostring(err), Color3.fromRGB(255, 95, 95), 4)
        end
    end

    if getgenv().CreateSection then getgenv().CreateSection(ScriptsPage, "Community Scripts", "ðŸ“œ") end
    CreateButton("BigFroot", ScriptsPage, function()
        RunCommunityScript("BigFroot", "BigFroot.lua")
    end)
    CreateButton("FE Emotes", ScriptsPage, function()
        RunCommunityScript("FE Emotes", "FEEmotes.lua")
    end)
    CreateButton("PShade", ScriptsPage, function()
        RunCommunityScript("PShade", "PShade.lua")
    end)
    CreateButton("Infinite Yield", ScriptsPage, function()
        RunCommunityScript("Infinite Yield", "InfiniteYield.lua")
    end)
    CreateButton("Bundle Edit", ScriptsPage, function()
        RunCommunityScript("Bundle Edit", "BundleEdit.lua")
    end)
    if getgenv().ClearActivePageCard then
        pcall(getgenv().ClearActivePageCard, ScriptsPage)
    end
end
task.spawn(function()
    if getgenv().ScriptsPage then
        local function RunSaveGame(decompile)
            local modeText = decompile and " (Decompiled Scripts)" or " (Standard)"
            CustomNotify("Starting Save Game" .. modeText .. "...", Color3.fromRGB(218, 170, 42))
            task.spawn(function()
                local ok, err = pcall(function()
                    local SaveInstance = saveinstance or (getgenv and getgenv().saveinstance)
                    if not SaveInstance then
                        SaveInstance = loadstring(game:HttpGet("https://raw.githubusercontent.com/luau/UniversalSynSaveInstance/main/saveinstance.lua"))()
                        if type(SaveInstance) == "table" and SaveInstance.Save then
                            SaveInstance = SaveInstance.Save
                        end
                    end
                    if type(SaveInstance) == "function" then
                        if decompile then
                            SaveInstance({Decompile = true, DecompileTimeout = 10})
                        else
                            SaveInstance()
                        end
                    else
                        error("saveinstance API not supported by executor")
                    end
                end)
                if ok then
                    CustomNotify("Save Game completed successfully!", Color3.fromRGB(50, 220, 90))
                else
                    CustomNotify("Save Game failed: " .. tostring(err), Color3.fromRGB(255, 80, 80))
                end
            end)
        end
        if getgenv().CreateSection then getgenv().CreateSection(getgenv().ScriptsPage, "Save Game & World", "💾") end
        CreateButton("Save Place (Standard)", getgenv().ScriptsPage, function() RunSaveGame(false) end)
        CreateButton("Save Place (Decompile Scripts)", getgenv().ScriptsPage, function() RunSaveGame(true) end)
        if getgenv().ClearActivePageCard then
            pcall(getgenv().ClearActivePageCard, getgenv().ScriptsPage)
        end
    end
end)
