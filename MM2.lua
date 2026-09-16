if game.PlaceId ~= 142823291 then
    return
end

local env = getgenv()
local loaderVersion = "2026-09-16-mm2-loader-current-base-1"
local coreUrl = tostring(
    env.ToxMM2CoreURL
    or "https://raw.githubusercontent.com/BG-0o/Scripts/refs/heads/main/ModuleMM2.lua"
)

local function AddCacheBuster(url)
    local separator = string.find(url, "?", 1, true) and "&" or "?"
    return url
        .. separator
        .. "toxcache="
        .. tostring(os.time())
        .. "_"
        .. tostring(math.random(1000, 999999))
end

local function Notify(text, color, duration)
    if type(env.CustomNotify) == "function" then
        pcall(env.CustomNotify, text, color, duration)
    end
end

if env.ToxMM2LoaderJobId == game.JobId
and env.ToxMM2LoaderVersion == loaderVersion
and env.ToxMM2LoaderPage == env.GamePage
and env.ToxMM2CoreReady == true
and env.Destroyed ~= true then
    return
end

local fetchOk, source = pcall(function()
    return game:HttpGet(AddCacheBuster(coreUrl))
end)

if not fetchOk or type(source) ~= "string" or source == "" then
    Notify("MM2 core download failed", Color3.fromRGB(255, 100, 100), 6)
    error("[ToxHub MM2 Loader Download Error]: " .. tostring(source))
end

local chunk, compileError = loadstring(source)

if not chunk then
    Notify("MM2 core compile failed", Color3.fromRGB(255, 100, 100), 7)
    error("[ToxHub MM2 Loader Compile Error]: " .. tostring(compileError))
end

local runOk, runError = pcall(chunk)

if not runOk then
    Notify("MM2 core runtime failed", Color3.fromRGB(255, 100, 100), 7)
    error("[ToxHub MM2 Loader Runtime Error]: " .. tostring(runError))
end

if env.ToxMM2CoreReady ~= true then
    Notify("MM2 core did not initialize", Color3.fromRGB(255, 100, 100), 7)
    error("[ToxHub MM2 Loader Error]: core did not initialize")
end

env.ToxMM2LoaderJobId = game.JobId
env.ToxMM2LoaderVersion = loaderVersion
env.ToxMM2LoaderPage = env.GamePage
