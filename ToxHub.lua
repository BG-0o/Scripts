if not game:IsLoaded() then
    pcall(function() game.Loaded:Wait() end)
end

local waitPlaceTries = 0
while (not game.PlaceId or game.PlaceId == 0) and waitPlaceTries < 10 do
    task.wait(0.1)
    waitPlaceTries = waitPlaceTries + 1
end

local MyBootLock = nil
if getgenv then
    -- Second copy started a few seconds after the first one in the same server
    -- (auto-execute + the teleport queue both run after changing games): just stop,
    -- no "ToxHub is already running" prompt. A manual re-execute later still asks.
    -- Also while the first copy is STILL LOADING (up to 60s): a second copy used to
    -- "re-execute" over it mid-load, leaving the window open with every page empty.
    local lock = getgenv().__ToxHubBootLock
    if typeof(lock) == "table" and lock.Game == game then
        local age = os.clock() - (tonumber(lock.StartedAt) or 0)
        if age < 15 or (age < 60 and getgenv().ScriptLoaded ~= true) then
            return
        end
    end
    -- Take the lock right now (no yield since the check above). Two copies started
    -- together (Join's teleport queue + the executor's auto-execute) both passed
    -- this check before either one's Boot set the lock, so both loaded on top of
    -- each other and the hub ended up broken/empty.
    MyBootLock = { Game = game, StartedAt = os.clock() }
    getgenv().__ToxHubBootLock = MyBootLock
    getgenv().Destroyed = false
    getgenv().__ToxHubReexecCancelled = nil
end
local function StillOwnsBoot()
    return not getgenv or getgenv().__ToxHubBootLock == MyBootLock
end

local REPO_BASE = "https://raw.githubusercontent.com/BG-0o/Scripts/refs/heads/main/"

local CORE_MODULES = {
    { Path = "Modules/Boot.lua",               Required = true },
    { Path = "Modules/Registry.lua",           Required = true },
    { Path = "Modules/Config.lua",             Required = true },
    { Path = "Modules/Helpers.lua",            Required = true },
    { Path = "Modules/UI_Core.lua",            Required = true },
    { Path = "Modules/UI_CardsAndPages.lua",   Required = true },
    { Path = "Modules/UI_Controls.lua",        Required = true },
    { Path = "Modules/UI_HomeAndSettings.lua", Required = true },
    { Path = "Modules/UI_QuickPages.lua",      Required = true },
    { Path = "Modules/LightingEngine.lua",     Required = false },
    { Path = "Modules/ModuleLoader.lua",       Required = true },
}

local function AddCacheBuster(url)
    url = tostring(url or "")
    if url == "" then
        return url
    end
    local separator = string.find(url, "?", 1, true) and "&" or "?"
    return url
        .. separator
        .. "toxcache="
        .. tostring(os.time())
        .. "_"
        .. tostring(math.random(1000, 999999))
end

local function FetchSource(relPath)
    local requestUrl = AddCacheBuster(REPO_BASE .. relPath)
    local success, content = pcall(function()
        return game:HttpGet(requestUrl)
    end)
    return success, content
end

local function ToxLoadError(msg)
    warn(msg)
    -- warn() is invisible on some executors, so also show it on screen
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "ToxHub - erro ao carregar",
            Text = string.sub(tostring(msg), 1, 180),
            Duration = 20,
        })
    end)
    if getgenv then
        getgenv().__ToxHubLastError = msg
        if getgenv().__ToxHubBootLock == MyBootLock then
            getgenv().__ToxHubBootLock = nil
        end
    end
end

local function RunFetchedSource(relPath, success, content)
    if not success or type(content) ~= "string" or content == "" or content == "404: Not Found" or content:sub(1, 15):find("404") then
        ToxLoadError("[ToxHub Error]: Nao foi possivel carregar " .. tostring(relPath))
        return false
    end

    local func, err = loadstring(content, "@" .. relPath)
    if not func then
        ToxLoadError("[ToxHub Syntax Error] (" .. tostring(relPath) .. "): " .. tostring(err))
        return false
    end

    if getgenv and relPath == CORE_MODULES[1].Path then
        getgenv().__ToxHubBootCaller = MyBootLock
    end
    local runOk, runErr = pcall(func)
    if not runOk then
        ToxLoadError("[ToxHub Runtime Error] (" .. tostring(relPath) .. "): " .. tostring(runErr))
        return false
    end

    return true
end

-- Execute Boot first so re-execution confirm/cleanup runs cleanly before fetching remaining modules
do
    local okFetch, bootSrc = FetchSource(CORE_MODULES[1].Path)
    if not RunFetchedSource(CORE_MODULES[1].Path, okFetch, bootSrc) then
        return
    end
    if not StillOwnsBoot() then
        return
    end
    if getgenv and (getgenv().Destroyed or getgenv().__ToxHubReexecCancelled) then
        if getgenv().__ToxHubReexecCancelled then
            getgenv().__ToxHubReexecCancelled = nil
        end
        return
    end
end

-- Pre-fetch remaining core modules concurrently while executing them in strict order
local prefetched = {}
for idx = 2, #CORE_MODULES do
    local modPath = CORE_MODULES[idx].Path
    task.spawn(function()
        local ok, body = FetchSource(modPath)
        prefetched[idx] = { Ok = ok, Body = body }
    end)
end

for idx = 2, #CORE_MODULES do
    local mod = CORE_MODULES[idx]
    while not prefetched[idx] do
        task.wait()
    end
    local res = prefetched[idx]
    local ok = RunFetchedSource(mod.Path, res.Ok, res.Body)
    if not ok and mod.Required then
        return
    end
    if getgenv and getgenv().Destroyed then
        return
    end
    if not StillOwnsBoot() then
        return
    end
end

if getgenv and getgenv().__ToxHubBootLock == MyBootLock then
    getgenv().__ToxHubBootLock = nil
end

-- ConfigAndRuntime's loading sequence reveals Main and activates staged options once ScriptLoaded becomes true.
local settings = getgenv and getgenv().Settings
if getgenv and getgenv().ScriptLoaded == true and not (settings and settings.StartHidden) then
    if getgenv().Main and getgenv().Main.Parent then
        getgenv().Main.Visible = true
    end
    if getgenv().ToggleToxGui then
        pcall(function() getgenv().ToggleToxGui(true) end)
    end
end
