
--==================================================
-- AUTO TYCOON V1.4 ALPHA
-- UI: RAYFIELD GEN2
--==================================================

return function()

    local Rayfield
    local window

    local loaded = pcall(function()
        Rayfield = loadstring(
            game:HttpGet("https://sirius.menu/gen2")
        )()
    end)

    if not loaded or not Rayfield then
        return nil, "Rayfield failed to load."
    end

    local createdWindow = pcall(function()
        window = Rayfield:CreateWindow({
            name = "AUTO TYCOON",
            subtitle = "Version 1.4 Alpha",

            sidebarLayout = true,

            configuration = {
                autoSave = true,
                autoLoad = true,
                fileName = "AutoTycoonV125Beta",
            },
        })
    end)

    if not createdWindow or not window then
        return nil, "Rayfield window creation failed."
    end

    --==================================================
    -- TABS
    --==================================================

    local HomeTab = window:CreateTab({
        name = "Home",
        icon = 80387863064905,
    })

    local AutomationsTab = window:CreateTab({
        name = "Automations",
        icon = 84750991656135,
    })

    local PurchasesTab = window:CreateTab({
        name = "Purchases",
        icon = 100604009889706,
    })

    local ActivityTab = window:CreateTab({
        name = "Activity",
        icon = 125823673784681,
    })

    local MiscTab = window:CreateTab({
        name = "Misc",
        icon = 83277910885129,
    })

    local SettingsTab = window:CreateTab({
        name = "Settings",
        icon = 129180860773723,
    })

    return {
        Rayfield = Rayfield,
        window = window,

        HomeTab = HomeTab,
        AutomationsTab = AutomationsTab,
        PurchasesTab = PurchasesTab,
        ActivityTab = ActivityTab,
        MiscTab = MiscTab,
        SettingsTab = SettingsTab,
    }
end
