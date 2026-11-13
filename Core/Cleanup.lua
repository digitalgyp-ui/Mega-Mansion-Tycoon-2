
--==================================================
-- AUTO TYCOON V1.4 ALPHA
-- CORE: CLEANUP
--==================================================

return function(State, Helpers, Resources)

    local Cleanup = {}

    Resources = Resources or {}

    local function safeCall(callback, ...)
        if type(callback) ~= "function" then
            return
        end

        pcall(callback, ...)
    end

    local function cancelTween(tween)
        if tween then
            pcall(function()
                tween:Cancel()
            end)
        end
    end

    function Cleanup.unload()
        if not State.running then
            return
        end

        safeCall(
            Resources.logActivity,
            "Unloading Auto Tycoon Version 1.4 Alpha..."
        )

        -- Stop script loops
        State.running = false

        -- Invalidate active animations
        State.animationToken += 1
        State.gradientWipeToken += 1
        State.purchaseAnimationActive = false

        -- Stop Anti-AFK
        State.antiAFKEnabled = false
        State.antiAFKLoopToken += 1

        -- Disconnect tracked connections
        Helpers.disconnectAll()

        -- Clear purchase ESP
        safeCall(Resources.clearAllESP)

        -- Cancel Dynamic Island animations
        cancelTween(Resources.rotationTween)
        cancelTween(Resources.hoverTween)

        if Resources.islandClickTweens then
            for _, tween in ipairs(Resources.islandClickTweens) do
                cancelTween(tween)
            end
        end

        -- Restore original lighting
        if State.fullbrightEnabled then
            safeCall(Resources.applyFullbright, false)
        end

        -- Remove Dynamic Island
        if Resources.islandGui then
            pcall(function()
                Resources.islandGui:Destroy()
            end)
        end

        -- Unload Rayfield
        if Resources.window then
            pcall(function()
                Resources.window:Unload()
            end)
        end

        -- Clear previous cleanup registrations
        _G.AutoTycoonV13Cleanup = nil
        _G.AutoTycoonV132Cleanup = nil
        _G.AutoTycoonV133Cleanup = nil
        _G.AutoTycoonV134Cleanup = nil

    end

    return Cleanup
end
