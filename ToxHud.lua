local function SafeLoad(url)
    local success, content = pcall(function()
        return game:HttpGet(url)
    end)
    if not success or not content or content:find("404") then
        warn("[ToxHud Error]: Nao foi possivel carregar " .. url)
        return false
    end
    local func, err = loadstring(content)
    if not func then
        warn("[ToxHud Syntax Error]: " .. tostring(err))
        return false
    end
    local runSuccess, runError = pcall(func)
    if not runSuccess then
        warn("[ToxHub Runtime Error]: " .. tostring(runError))
        return false
    end

    return true
end

if SafeLoad("https://raw.githubusercontent.com/BG-0o/Scripts/main/Module1.lua") then
    SafeLoad("https://raw.githubusercontent.com/BG-0o/Scripts/main/Module2.lua")
end
