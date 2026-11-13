
--==================================================
-- AUTO TYCOON V1.4 ALPHA
-- CORE: HELPERS
--==================================================

return function(State)

    local Helpers = {}

    -- CONNECTION MANAGEMENT

    function Helpers.trackConnection(connection)
        table.insert(State.connections, connection)
        return connection
    end

    function Helpers.disconnectAll()
        for _, connection in ipairs(State.connections) do
            pcall(function()
                connection:Disconnect()
            end)
        end

        table.clear(State.connections)
    end

    -- NUMBER FORMATTING

    function Helpers.formatNumber(value)
        value = tonumber(value) or 0

        local rounded = math.floor(math.abs(value) + 0.5)

        local formatted = tostring(rounded)
            :reverse()
            :gsub("(%d%d%d)", "%1,")
            :reverse()

        if formatted:sub(1, 1) == "," then
            formatted = formatted:sub(2)
        end

        if value < 0 then
            formatted = "-" .. formatted
        end

        return formatted
    end

    function Helpers.parseNumber(value)
        local number = tonumber(value)

        if number then
            return number
        end

        if type(value) ~= "string" then
            return 0
        end

        local cleaned = value
            :gsub(",", "")
            :gsub("%$", "")
            :gsub("%s", "")
            :gsub("/s$", "")
            :gsub("/S$", "")

        cleaned = cleaned:gsub("[^%d%.%-KkMmBb]", "")

        local suffix = cleaned:match("([KkMmBb])$")
        local base = tonumber(cleaned:gsub("[KkMmBb]$", ""))

        if not base then
            return 0
        end

        local multiplier = 1

        if suffix then
            suffix = string.upper(suffix)

            multiplier = suffix == "K" and 1e3
                or suffix == "M" and 1e6
                or suffix == "B" and 1e9
                or 1
        end

        return base * multiplier
    end

    function Helpers.formatCompactNumber(value)
        value = tonumber(value) or 0
        local absolute = math.abs(value)

        if absolute < 1000 then
            return Helpers.formatNumber(value)
        end

        local suffix
        local divisor

        if absolute >= 1e9 then
            suffix = "B"
            divisor = 1e9
        elseif absolute >= 1e6 then
            suffix = "M"
            divisor = 1e6
        else
            suffix = "K"
            divisor = 1e3
        end

        local rounded = math.floor(
            (absolute / divisor) * 100 + 0.5
        ) / 100

        local compact = string.format("%.2f", rounded)
            :gsub("0+$", "")
            :gsub("%.$", "")

        if value < 0 then
            compact = "-" .. compact
        end

        return compact .. suffix
    end

    -- RICH TEXT HELPERS

    function Helpers.escapeRichText(value)
        value = tostring(value or "")

        value = value:gsub("&", "&amp;")
        value = value:gsub("<", "&lt;")
        value = value:gsub(">", "&gt;")
        value = value:gsub('"', "&quot;")
        value = value:gsub("'", "&apos;")

        return value
    end

    function Helpers.colorHex(color)
        return string.format(
            "#%02X%02X%02X",
            math.floor(color.R * 255 + 0.5),
            math.floor(color.G * 255 + 0.5),
            math.floor(color.B * 255 + 0.5)
        )
    end

    -- ACTIVITY LOGGING

    function Helpers.logToConsole(consoleObject, message)
        if not consoleObject then
            return
        end

        local line = string.format(
            "[%s] %s",
            os.date("%H:%M:%S"),
            tostring(message)
        )

        pcall(function()
            consoleObject:Append(line)
        end)
    end

    return Helpers
end
