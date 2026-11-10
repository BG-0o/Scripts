if not game:IsLoaded() then
    pcall(function() game.Loaded:Wait() end)
end

local waitPlaceTries = 0
while (not game.PlaceId or game.PlaceId == 0) and waitPlaceTries < 15 do
    task.wait(0.2)
    waitPlaceTries = waitPlaceTries + 1
end

if getgenv then
    getgenv().Destroyed = nil
    getgenv().__ToxHubBootLock = nil
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

local function SafeLoad(relPath)
    local url = REPO_BASE .. relPath
    local requestUrl = AddCacheBuster(url)

    local success, content = pcall(function()
        return game:HttpGet(requestUrl)
    end)

    if not success or type(content) ~= "string" or content == "" or content == "404: Not Found" or content:sub(1, 15):find("404") then
        warn("[ToxHud Error]: Nao foi possivel carregar " .. tostring(relPath))
        return false
    end

    local func, err = loadstring(content, "@" .. relPath)
    if not func then
        warn("[ToxHud Syntax Error] (" .. tostring(relPath) .. "): " .. tostring(err))
        return false
    end

    local runOk, runErr = pcall(func)
    if not runOk then
        warn("[ToxHud Runtime Error] (" .. tostring(relPath) .. "): " .. tostring(runErr))
        return false
    end

    return true
end

for _, mod in ipairs(CORE_MODULES) do
    local ok = SafeLoad(mod.Path)
    if not ok and mod.Required then
        return
    end
    if getgenv and getgenv().Destroyed then
        return
    end
end

local settings = getgenv and getgenv().Settings
if not (settings and settings.StartHidden) then
    if getgenv and getgenv().Main and getgenv().Main.Parent then
        getgenv().Main.Visible = true
    end
    if getgenv and getgenv().ToggleToxGui then
        pcall(function() getgenv().ToggleToxGui(true) end)
    end
end
