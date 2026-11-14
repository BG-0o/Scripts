if not game:IsLoaded() then
    pcall(function() game.Loaded:Wait() end)
end

local waitPlaceTries = 0
while (not game.PlaceId or game.PlaceId == 0) and waitPlaceTries < 10 do
    task.wait(0.1)
    waitPlaceTries = waitPlaceTries + 1
end

if getgenv then
    getgenv().Destroyed = false
    getgenv().__ToxHubBootLock = nil
    getgenv().__ToxHubReexecCancelled = nil
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

local function RunFetchedSource(relPath, success, content)
    if not success or type(content) ~= "string" or content == "" or content == "404: Not Found" or content:sub(1, 15):find("404") then
        warn("[ToxHub Error]: Nao foi possivel carregar " .. tostring(relPath))
        return false
    end

    local func, err = loadstring(content, "@" .. relPath)
    if not func then
        warn("[ToxHub Syntax Error] (" .. tostring(relPath) .. "): " .. tostring(err))
        return false
    end

    local runOk, runErr = pcall(func)
    if not runOk then
        warn("[ToxHub Runtime Error] (" .. tostring(relPath) .. "): " .. tostring(runErr))
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
end

if getgenv then
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
