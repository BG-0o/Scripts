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

local function SafeLoad(url)
    local requestUrl = AddCacheBuster(url)

    local success, content = pcall(function()
        return game:HttpGet(requestUrl)
    end)

    if not success or not content or content == "404: Not Found" or content:sub(1, 15):find("404") then
        warn("[ToxHud Error]: Nao foi possivel carregar " .. tostring(url))
        return false
    end

    local func, err = loadstring(content)

    if not func then
        warn("[ToxHud Syntax Error]: " .. tostring(err))
        return false
    end

    local runOk, runErr = pcall(func)

    if not runOk then
        warn("[ToxHud Runtime Error]: " .. tostring(runErr))
        return false
    end

    return true
end

-- 1. Core Systems & Configuration Backend
if not SafeLoad("https://raw.githubusercontent.com/BG-0o/Scripts/main/Module1.lua") then
    return
end

-- 2. Revolution UI Engine (BigFroot / Wasor Style)
if not SafeLoad("https://raw.githubusercontent.com/BG-0o/Scripts/main/Module2.lua") then
    return
end

-- 3. Sub-Windows & Game Loaders
SafeLoad("https://raw.githubusercontent.com/BG-0o/Scripts/main/Module3.lua")

if getgenv and getgenv().Main and getgenv().Main.Parent then
    getgenv().Main.Visible = true
end
if getgenv and getgenv().ToggleToxGui then
    pcall(function() getgenv().ToggleToxGui(true) end)
end
