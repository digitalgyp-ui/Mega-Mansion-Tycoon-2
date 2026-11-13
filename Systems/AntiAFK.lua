
--==================================================
-- AUTO TYCOON V1.4 ALPHA
-- SYSTEMS: ANTI-AFK
--==================================================

return function(State, Helpers, LocalPlayer, logActivity)

    local AntiAFK = {}

    local function sendAntiAFKPulse(reason)
        if not State.running or not State.antiAFKEnabled then
            return false
        end

        local ok, err = pcall(function()
            local VirtualUser = game:GetService("VirtualUser")

            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new(0, 0))
        end)

        if ok then
            State.antiAFKLastPulse = os.clock()

            logActivity(
                "Anti-AFK input attempted (" ..
                tostring(reason or "scheduled pulse") .. ")."
            )

            return true
        end

        if os.clock() - State.antiAFKLastWarning >= 60 then
            State.antiAFKLastWarning = os.clock()

            logActivity(
                "Anti-AFK input is unavailable in this client: " ..
                tostring(err)
            )
        end

        return false
    end

    function AntiAFK.setEnabled(enabled)
        State.antiAFKEnabled = enabled == true
        State.antiAFKLoopToken += 1

        local token = State.antiAFKLoopToken

        if not State.antiAFKEnabled then
            logActivity("Anti-AFK disabled.")
            return
        end

        State.antiAFKLastPulse = os.clock()

        logActivity(
            "Anti-AFK enabled. Pulse interval: 10 minutes."
        )

        task.spawn(function()
            local elapsed = 0

            while State.running
                and State.antiAFKEnabled
                and State.antiAFKLoopToken == token do

                task.wait(1)

                if not State.running
                    or not State.antiAFKEnabled
                    or State.antiAFKLoopToken ~= token then
                    break
                end

                elapsed += 1

                if elapsed >= State.antiAFKInterval then
                    elapsed = 0

                    if os.clock() - State.antiAFKLastPulse
                        >= State.antiAFKInterval then

                        sendAntiAFKPulse("10-minute timer")
                    end
                end
            end
        end)
    end

    function AntiAFK.start()
        Helpers.trackConnection(
            LocalPlayer.Idled:Connect(function()
                if not State.running or not State.antiAFKEnabled then
                    return
                end

                if os.clock() - State.antiAFKLastPulse
                    >= State.antiAFKInterval then

                    sendAntiAFKPulse("Roblox idle event")
                end
            end)
        )

        AntiAFK.setEnabled(true)
    end

    return AntiAFK
end
