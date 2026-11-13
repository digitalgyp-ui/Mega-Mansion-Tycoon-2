
--==================================================
-- AUTO TYCOON V1.4 ALPHA
-- UI: ACTIVITY
--==================================================

return function(ActivityTab, Helpers)

    local Activity = {}

    ActivityTab:CreateSection({
        name = "Automation History",
    })

    local ActivityConsole = ActivityTab:CreateConsole({
        name = "Activity Log",
        text = "Auto Tycoon Version 1.4 Alpha loaded. Waiting for automation events...",
        height = 330,
        follow = true,
        maxLines = 120,
    })

    -- ACTIVITY LOGGING

    function Activity.log(message)
        Helpers.logToConsole(ActivityConsole, message)
    end

    -- CLEAR ACTIVITY LOG

    ActivityTab:CreateButton({
        name = "Clear Activity Log",

        callback = function()
            ActivityConsole:Clear()
            Activity.log("Activity log cleared.")
        end,
    })

    Activity.console = ActivityConsole

    return Activity
end
