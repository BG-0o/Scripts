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

    if not success or not content or content:find("404") then
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

if not SafeLoad("https://raw.githubusercontent.com/BG-0o/Scripts/main/Module1.lua") then
    return
end

SafeLoad("https://raw.githubusercontent.com/BG-0o/Scripts/main/Module2.lua")
