
--==================================================
-- AUTO TYCOON V1.4 ALPHA
-- SYSTEMS: LIGHTING
--==================================================

return function(State, Lighting)

    local LightingSystem = {}

    local originalLighting = {
        Brightness = Lighting.Brightness,
        ClockTime = Lighting.ClockTime,
        FogEnd = Lighting.FogEnd,
        GlobalShadows = Lighting.GlobalShadows,
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
    }

    function LightingSystem.setFullbright(enabled)
        State.fullbrightEnabled = enabled == true

        if State.fullbrightEnabled then
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false

            Lighting.Ambient = Color3.fromRGB(180, 180, 180)
            Lighting.OutdoorAmbient = Color3.fromRGB(180, 180, 180)

        else
            for property, value in pairs(originalLighting) do
                pcall(function()
                    Lighting[property] = value
                end)
            end
        end
    end

    return LightingSystem
end
