local UNIVERSAL_URL =
    "https://raw.githubusercontent.com/BG-0o/Scripts/refs/heads/main/Universal.lua"

local UNIVERSAL2_URL =
    "https://raw.githubusercontent.com/BG-0o/Scripts/refs/heads/main/Universal2.lua"

local EXPECTED_UNIVERSAL2_VERSION = "2026-09-16-correct-universal-ui"

local TOX_CHAT_URL =
    "https://raw.githubusercontent.com/BG-0o/Scripts/refs/heads/main/ToxChat.lua"

local TOX_SYSTEMS_URL =
    "https://raw.githubusercontent.com/BG-0o/Scripts/refs/heads/main/ToxSystems.lua"

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

local function Notify(
    text,
    color,
    duration
)
    local notify =
        getgenv().CustomNotify

    if notify then
        notify(
            text,
            color,
            duration
        )
    end
end

local function LoadRemote(
    name,
    url
)
    local requestUrl =
        AddToxCacheBuster(url)

    local fetchOk, source =
        pcall(function()
            return game:HttpGet(requestUrl)
        end)

    if not fetchOk then
        Notify(
            name .. " download failed",
            Color3.fromRGB(255, 100, 100),
            5
        )
        warn(
            "[ToxHub "
            .. name
            .. " Download Error]: "
            .. tostring(source)
        )
        return false
    end

    local chunk, compileErr =
        loadstring(source)

    if not chunk then
        local detail =
            tostring(
                compileErr
                or "compile error"
            )

        Notify(
            name
            .. " compile: "
            .. string.sub(
                detail,
                1,
                75
            ),
            Color3.fromRGB(255, 100, 100),
            7
        )
        warn(
            "[ToxHub "
            .. name
            .. " Compile Error]: "
            .. detail
        )
        return false
    end

    local runOk, runErr =
        pcall(chunk)

    if not runOk then
        local detail =
            tostring(runErr)

        Notify(
            name
            .. " runtime: "
            .. string.sub(
                detail,
                1,
                75
            ),
            Color3.fromRGB(255, 100, 100),
            7
        )
        warn(
            "[ToxHub "
            .. name
            .. " Runtime Error]: "
            .. detail
        )
        return false
    end

    return true
end

if not getgenv().ToxUniversalLoaded then
    if not LoadRemote(
        "Universal.lua",
        UNIVERSAL_URL
    ) then
        return
    end
end

if getgenv().ToxUniversal2Version ~= EXPECTED_UNIVERSAL2_VERSION then
    getgenv().ToxUniversal2Loaded = nil
end

if not getgenv().ToxUniversal2Loaded then
    if not LoadRemote(
        "Universal2.lua",
        UNIVERSAL2_URL
    ) then
        return
    end
end

if getgenv().ToxUniversal2Version ~= EXPECTED_UNIVERSAL2_VERSION then
    Notify(
        "Universal2 version mismatch",
        Color3.fromRGB(255, 100, 100),
        7
    )
    warn(
        "[ToxHub Universal2 Version Error]: expected "
        .. EXPECTED_UNIVERSAL2_VERSION
        .. ", got "
        .. tostring(getgenv().ToxUniversal2Version)
    )
    return
end

if not getgenv().ToxChatLoaded then
    LoadRemote(
        "ToxChat.lua",
        TOX_CHAT_URL
    )
end

if not getgenv().ToxSystemsLoaded then
    LoadRemote(
        "ToxSystems.lua",
        TOX_SYSTEMS_URL
    )
end

local detected =
    getgenv().CurrentGameModule

if detected
and getgenv().ApplyCurrentGameSharedSettings then
    getgenv().ApplyCurrentGameSharedSettings()
end

if detected
and detected.Ready
and detected.Url
and getgenv().GamePage then
    local env =
        getgenv()

    local gamePage =
        env.GamePage

    local moduleUrl =
        tostring(
            detected.Url
        )

    if detected.ShortName == "MM2"
    and detected.CoreUrl then
        env.ToxMM2CoreURL =
            tostring(
                detected.CoreUrl
            )
    end

    local alreadyLoaded =
        env.ToxGameModuleLoadedPage
            == gamePage
        and env.ToxGameModuleLoadedUrl
            == moduleUrl

    local alreadyLoading =
        env.ToxGameModuleLoadingPage
            == gamePage
        and env.ToxGameModuleLoadingUrl
            == moduleUrl

    if not alreadyLoaded
    and not alreadyLoading then
        env.ToxGameModuleLoadingPage =
            gamePage

        env.ToxGameModuleLoadingUrl =
            moduleUrl

        task.spawn(function()
            local ok, err =
                pcall(function()
                    local source =
                        game:HttpGet(
                            AddToxCacheBuster(moduleUrl)
                        )

                    local chunk,
                        compileError =
                        loadstring(
                            source
                        )

                    if not chunk then
                        error(
                            tostring(
                                compileError
                                or "invalid game module"
                            )
                        )
                    end

                    chunk()
                end)

            if env.ToxGameModuleLoadingPage
                == gamePage
            and env.ToxGameModuleLoadingUrl
                == moduleUrl then
                env.ToxGameModuleLoadingPage =
                    nil

                env.ToxGameModuleLoadingUrl =
                    nil
            end

            if ok then
                env.ToxGameModuleLoadedPage =
                    gamePage

                env.ToxGameModuleLoadedUrl =
                    moduleUrl
            else
                if env.ToxGameModuleLoadedPage
                    == gamePage
                and env.ToxGameModuleLoadedUrl
                    == moduleUrl then
                    env.ToxGameModuleLoadedPage =
                        nil

                    env.ToxGameModuleLoadedUrl =
                        nil
                end

                Notify(
                    tostring(
                        detected.ShortName
                        or "Game"
                    )
                    .. " module failed to load",
                    Color3.fromRGB(
                        255,
                        100,
                        100
                    ),
                    5
                )

                warn(
                    "[ToxHub Game Module Error]: "
                    .. tostring(err)
                )
            end
        end)
    end
end
