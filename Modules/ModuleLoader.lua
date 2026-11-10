local env = getgenv()
if env.Destroyed then
    return
end

local BASE_REPO = "https://raw.githubusercontent.com/BG-0o/Scripts/refs/heads/main/"

local UNIVERSAL_MODULES = {
    { Name = "Universal/Core.lua",                  Path = "Universal/Core.lua" },
    { Name = "Universal/NetworkAndJoin.lua",        Path = "Universal/NetworkAndJoin.lua" },
    { Name = "Universal/MovementAndWorld.lua",      Path = "Universal/MovementAndWorld.lua" },
    { Name = "Universal/Extras.lua",                Path = "Universal/Extras.lua" },
    { Name = "Universal/Combat.lua",                Path = "Universal/Combat.lua" },
    { Name = "Universal/PlayerTab.lua",             Path = "Universal/PlayerTab.lua" },
    { Name = "Universal/VisualsAndLightingTab.lua", Path = "Universal/VisualsAndLightingTab.lua" },
    { Name = "Universal/ESP.lua",                   Path = "Universal/ESP.lua" },
    { Name = "Universal/MiscAndScriptsTab.lua",     Path = "Universal/MiscAndScriptsTab.lua" },
    { Name = "Universal/ConfigAndRuntime.lua",      Path = "Universal/ConfigAndRuntime.lua" },
}

local TOX_CHAT_URL = BASE_REPO .. "Modules/ToxChat.lua"
local TOX_SYSTEMS_URL = BASE_REPO .. "Modules/ToxSystems.lua"

local function AddToxCacheBuster(url)
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

local function Notify(text, color, duration)
    local notify = getgenv().CustomNotify
    if notify then
        notify(text, color, duration)
    end
end

local function LoadRemote(name, url)
    local fetchOk, source = pcall(function()
        return game:HttpGet(AddToxCacheBuster(url))
    end)
    if not fetchOk or type(source) ~= "string" or source == "" or source:sub(1, 15):find("404") then
        Notify(name .. " download failed", Color3.fromRGB(255, 100, 100), 5)
        warn("[ToxHub " .. name .. " Download Error]: " .. tostring(source))
        return false
    end
    local chunk, compileErr = loadstring(source)
    if not chunk then
        local detail = tostring(compileErr or "compile error")
        Notify(name .. " compile: " .. string.sub(detail, 1, 75), Color3.fromRGB(255, 100, 100), 7)
        warn("[ToxHub " .. name .. " Compile Error]: " .. detail)
        return false
    end
    local runOk, runErr = pcall(chunk)
    if not runOk then
        local detail = tostring(runErr)
        Notify(name .. " runtime: " .. string.sub(detail, 1, 75), Color3.fromRGB(255, 100, 100), 7)
        warn("[ToxHub " .. name .. " Runtime Error]: " .. detail)
        return false
    end
    return true
end

if not getgenv().ToxUniversalLoaded then
    for _, mod in ipairs(UNIVERSAL_MODULES) do
        if env.Destroyed then
            return
        end
        local ok = LoadRemote(mod.Name, BASE_REPO .. mod.Path)
        if not ok and mod.Path == "Universal/ConfigAndRuntime.lua" then
            return
        end
    end
end

if not getgenv().ToxChatLoaded then
    LoadRemote("Modules/ToxChat.lua", TOX_CHAT_URL)
end

if not getgenv().ToxSystemsLoaded then
    LoadRemote("Modules/ToxSystems.lua", TOX_SYSTEMS_URL)
end

local detected = getgenv().CurrentGameModule
if not detected and getgenv().ResolveCurrentGameModule then
    detected = getgenv().ResolveCurrentGameModule()
    getgenv().CurrentGameModule = detected
end
if detected and getgenv().EnsureGameTabCreated then
    pcall(getgenv().EnsureGameTabCreated, detected)
end
if detected and getgenv().ApplyCurrentGameSharedSettings then
    getgenv().ApplyCurrentGameSharedSettings()
end

if detected and detected.Ready and detected.Url and getgenv().GamePage then
    local gamePage = env.GamePage
    local moduleUrl = tostring(detected.Url)
    if detected.ShortName == "MM2" and detected.CoreUrl then
        env.ToxMM2CoreURL = tostring(detected.CoreUrl)
    end
    local alreadyLoaded =
        env.ToxGameModuleLoadedPage == gamePage
        and env.ToxGameModuleLoadedUrl == moduleUrl
    local alreadyLoading =
        env.ToxGameModuleLoadingPage == gamePage
        and env.ToxGameModuleLoadingUrl == moduleUrl
    if not alreadyLoaded and not alreadyLoading then
        env.ToxGameModuleLoadingPage = gamePage
        env.ToxGameModuleLoadingUrl = moduleUrl
        task.spawn(function()
            local ok, err = pcall(function()
                local source = game:HttpGet(AddToxCacheBuster(moduleUrl))
                local chunk, compileError = loadstring(source)
                if not chunk then
                    error(tostring(compileError or "invalid game module"))
                end
                chunk()
            end)
            if env.ToxGameModuleLoadingPage == gamePage
            and env.ToxGameModuleLoadingUrl == moduleUrl then
                env.ToxGameModuleLoadingPage = nil
                env.ToxGameModuleLoadingUrl = nil
            end
            if ok then
                env.ToxGameModuleLoadedPage = gamePage
                env.ToxGameModuleLoadedUrl = moduleUrl
            else
                if env.ToxGameModuleLoadedPage == gamePage
                and env.ToxGameModuleLoadedUrl == moduleUrl then
                    env.ToxGameModuleLoadedPage = nil
                    env.ToxGameModuleLoadedUrl = nil
                end
                Notify(
                    tostring(detected.ShortName or "Game") .. " module failed to load",
                    Color3.fromRGB(255, 100, 100),
                    5
                )
                warn("[ToxHub Game Module Error]: " .. tostring(err))
            end
        end)
    end
end
