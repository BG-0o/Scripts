local UNIVERSAL_URL =
    "https://raw.githubusercontent.com/BG-0o/Scripts/refs/heads/main/Universal.lua"

local TOX_SYSTEMS_URL =
    "https://raw.githubusercontent.com/BG-0o/Scripts/refs/heads/main/ToxSystems.lua"

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
    local ok, err =
        pcall(function()
            local source =
                game:HttpGet(url)

            local chunk =
                loadstring(source)

            if not chunk then
                error(
                    "invalid "
                    .. name
                    .. " source"
                )
            end

            chunk()
        end)

    if not ok then
        Notify(
            name
            .. " failed to load",
            Color3.fromRGB(
                255,
                100,
                100
            ),
            5
        )

        warn(
            "[ToxHub "
            .. name
            .. " Error]: "
            .. tostring(err)
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
    task.spawn(function()
        local ok, err =
            pcall(function()
                local source =
                    game:HttpGet(
                        detected.Url
                    )

                local chunk =
                    loadstring(source)

                if not chunk then
                    error(
                        "invalid game module"
                    )
                end

                chunk()
            end)

        if not ok then
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
