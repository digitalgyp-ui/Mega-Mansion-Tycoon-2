
--==================================================
-- AUTO TYCOON VERSION 1.4 ALPHA
-- MAIN ENTRY POINT
-- MODULAR ARCHITECTURE
--==================================================

--==================================================
-- CONFIGURATION
--==================================================

local BASE_URL =
    "https://raw.githubusercontent.com/digitalgyp-ui/Mega-Mansion-Tycoon-2/main/"

-- Replace the placeholder URL after creating the repository.

--==================================================
-- SERVICES
--==================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

if not LocalPlayer then
    return
end

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--==================================================
-- PREVIOUS VERSION CLEANUP
--==================================================

local previousCleanups = {
    "AutoTycoonV132Cleanup",
    "AutoTycoonV134Cleanup",
    "AutoTycoonV133Cleanup",
    "AutoTycoonV12Cleanup",
    "AutoTycoonV125Cleanup",
    "AutoTycoonV126Cleanup",
    "AutoTycoonV13Cleanup",
}

for _, name in ipairs(previousCleanups) do

    pcall(function()

        local cleanup = _G[name]

        if type(cleanup) == "function" then
            cleanup()
        end
    end)
end

--==================================================
-- MODULE LOADER
--==================================================

local function loadModule(path)

    local url = BASE_URL .. path

    local success, source = pcall(function()
        return game:HttpGet(url)
    end)

    if not success then
        error(
            "Failed to download module: "
            .. path
            .. "\n"
            .. tostring(source)
        )
    end

    local loader, compileError = loadstring(source)

    if not loader then
        error(
            "Module compilation failed: "
            .. path
            .. "\n"
            .. tostring(compileError)
        )
    end

    return loader()
end

--==================================================
-- CORE MODULES
--==================================================

local State = loadModule("Core/State.lua")

local Helpers = loadModule("Core/Helpers.lua")(State)

--==================================================
-- GUI PARENT
--==================================================

local GUIParent

pcall(function()

    if typeof(gethui) == "function" then
        GUIParent = gethui()
    end
end)

GUIParent = GUIParent or PlayerGui

--==================================================
-- RAYFIELD
--==================================================

local RayfieldUI, rayfieldError =
    loadModule("UI/Rayfield.lua")()

if not RayfieldUI then
    error(rayfieldError or "Rayfield initialization failed.")
end

local Tabs = RayfieldUI

--==================================================
-- ACTIVITY
--==================================================

local Activity = loadModule("UI/Activity.lua")(
    Tabs.ActivityTab,
    Helpers
)

local function logActivity(message)
    Activity.log(message)
end

--==================================================
-- CHARACTER
--==================================================

local Character = loadModule("Systems/Character.lua")(
    State,
    Helpers,
    LocalPlayer,
    UserInputService
)

--==================================================
-- DYNAMIC ISLAND
--==================================================

local Island = loadModule("UI/DynamicIsland.lua")(
    State,
    Helpers,
    {
        TweenService = TweenService,
        RunService = RunService,
        UserInputService = UserInputService,
        GUIParent = GUIParent,
    }
)

--==================================================
-- DETECTION
--==================================================

local Detection = loadModule("Purchases/Detection.lua")(
    State,
    LocalPlayer
)

--==================================================
-- MONEY HELPERS
--==================================================

local function getMoneyObject()

    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")

    local money = leaderstats
        and leaderstats:FindFirstChild("Money")

    if money and money:IsA("ValueBase") then
        return money
    end

    return nil
end

local function getMoneyValue()

    local money = getMoneyObject()

    if money then
        return Helpers.parseNumber(money.Value)
    end

    return 0
end

local function waitForMoneyDelta(beforeMoney, timeout)

    timeout = timeout or 1.5

    local deadline = os.clock() + timeout
    local currentMoney = getMoneyValue()

    while State.running and os.clock() < deadline do

        currentMoney = getMoneyValue()

        if currentMoney > beforeMoney then

            task.wait(0.12)

            currentMoney = getMoneyValue()

            return math.max(
                0,
                currentMoney - beforeMoney
            )
        end

        task.wait(0.05)
    end

    currentMoney = getMoneyValue()

    return math.max(
        0,
        currentMoney - beforeMoney
    )
end

--==================================================
-- PURCHASING INTERACTION ADAPTER
--==================================================

local function purchaseInteraction(data)

    local root = Character.getRootPart()

    if not root or not root.Parent then
        return false, "Character HumanoidRootPart is missing."
    end

    if not data or not data.hitbox or not data.hitbox.Parent then
        return false, "Purchase TouchHitbox is missing."
    end

    if State.movementBusy then
        return false, "Another character movement/touch action is already running."
    end

    local touchFunction = firetouchinterest
    local originalCFrame = root.CFrame

    State.movementBusy = true

    local ok, err = pcall(function()

        if State.purchaseMethod == "TouchInterest" then

            if typeof(touchFunction) ~= "function" then
                error("firetouchinterest is unavailable in this executor.")
            end

            touchFunction(root, data.hitbox, 0)
            task.wait(0.12)
            touchFunction(root, data.hitbox, 1)

        else

            root.CFrame = data.hitbox.CFrame * CFrame.new(0, 2, 0)
            task.wait(0.25)

            if typeof(touchFunction) == "function" then
                touchFunction(root, data.hitbox, 0)
                task.wait(0.12)
                touchFunction(root, data.hitbox, 1)
            end

            task.wait(0.12)

            if root.Parent then
                root.CFrame = originalCFrame
            end
        end
    end)

    if not ok and root.Parent then
        pcall(function()
            root.CFrame = originalCFrame
        end)
    end

    State.movementBusy = false

    if not ok then
        return false, tostring(err)
    end

    return true
end

--==================================================
-- PURCHASING
--==================================================

local purchaseDependencies = {

    Detection = Detection,
    Character = Character,
    Island = Island,

    getMoneyValue = getMoneyValue,
    logActivity = logActivity,

    purchaseInteraction = purchaseInteraction,
}

local Purchasing = loadModule("Purchases/Purchasing.lua")(
    State,
    Helpers,
    purchaseDependencies
)

--==================================================
-- AUTO BUY
--==================================================

local AutoBuy = loadModule("Automation/AutoBuy.lua")(
    State,
    {
        Detection = Detection,
        Purchasing = Purchasing,
        Island = Island,

        getMoneyValue = getMoneyValue,
        logActivity = logActivity,
    }
)

--==================================================
-- MAILBOX INTERACTION ADAPTER
--==================================================

local function mailboxInteraction(root, touchPart)

    if not root or not root.Parent then
        return false, "Character HumanoidRootPart is missing."
    end

    if not touchPart or not touchPart.Parent then
        return false, "Mailbox TouchInterest part is missing."
    end

    local touchFunction = firetouchinterest

    if typeof(touchFunction) ~= "function" then
        return false, "firetouchinterest is unavailable in this executor."
    end

    local ok, err = pcall(function()
        touchFunction(root, touchPart, 0)
        task.wait(0.10)
        touchFunction(root, touchPart, 1)
    end)

    if not ok then
        return false, tostring(err)
    end

    return true
end

--==================================================
-- AUTO COLLECT
--==================================================

local AutoCollect = loadModule("Automation/AutoCollect.lua")(
    State,
    Helpers,
    {
        LocalPlayer = LocalPlayer,
        Character = Character,
        Island = Island,
        Detection = Detection,

        getMoneyValue = getMoneyValue,
        waitForMoneyDelta = waitForMoneyDelta,
        logActivity = logActivity,

        mailboxInteraction = mailboxInteraction,
    }
)

--==================================================
-- ESP
--==================================================

local ESP = loadModule("Purchases/ESP.lua")(
    State,
    Helpers,
    {
        Detection = Detection,
        PlayerGui = PlayerGui,
        getMoneyValue = getMoneyValue,
    }
)

--==================================================
-- ANTI-AFK
--==================================================

local AntiAFK = loadModule("Systems/AntiAFK.lua")(
    State,
    Helpers,
    LocalPlayer,
    logActivity
)

--==================================================
-- LIGHTING
--==================================================

local LightingSystem = loadModule("Systems/Lighting.lua")(
    State,
    Lighting
)

--==================================================
-- CREATE UI
--==================================================

AutoBuy.createUI(Tabs.AutomationsTab)

AutoCollect.createUI(Tabs.AutomationsTab)

ESP.createUI(
    Tabs.AutomationsTab,
    logActivity
)

Purchasing.createUI(
    Tabs.PurchasesTab,
    LocalPlayer
)

Character.createControls(
    Tabs.MiscTab,
    logActivity
)

--==================================================
-- HOME: LIVE LEADERSTATS
--==================================================

Tabs.HomeTab:CreateSection({
    name = "Live Leaderstats",
})

local MoneyStat = Tabs.HomeTab:CreateText({
    name = "Money",
    text = "Loading...",
})

local IncomeStat = Tabs.HomeTab:CreateText({
    name = "Money Per Second",
    text = "Loading...",
})

local NetWorthStat = Tabs.HomeTab:CreateText({
    name = "Net Worth",
    text = "Loading...",
})

--==================================================
-- LEADERSTAT BINDING
--==================================================

local leaderstatHandles = {
    Money = MoneyStat,
    ["/s"] = IncomeStat,
    ["Net Worth"] = NetWorthStat,
}

local function bindLeaderstat(statName, statHandle)

    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")

    if not leaderstats then

        pcall(function()
            statHandle:Set("Waiting for leaderstats...")
        end)

        return
    end

    local valueObject = leaderstats:FindFirstChild(statName)

    if not valueObject or not valueObject:IsA("ValueBase") then

        pcall(function()
            statHandle:Set("Waiting for " .. statName .. "...")
        end)

        return
    end

    local existing = State.leaderstatBindings[statName]

    if existing
        and existing.object == valueObject
        and existing.connection
        and existing.connection.Connected then

        return
    end

    if existing and existing.connection then
        existing.connection:Disconnect()
    end

    local function update()

        local rawValue = valueObject.Value

        local displayValue

        if statName == "/s" then
            displayValue = tostring(rawValue)
        else
            displayValue = "$" .. Helpers.formatNumber(rawValue)
        end

        pcall(function()
            statHandle:Set(displayValue)
        end)
    end

    update()

    local connection =
        valueObject:GetPropertyChangedSignal("Value"):Connect(update)

    Helpers.trackConnection(connection)

    State.leaderstatBindings[statName] = {
        object = valueObject,
        connection = connection,
    }
end

task.spawn(function()

    while State.running do

        for statName, handle in pairs(leaderstatHandles) do
            bindLeaderstat(statName, handle)
        end

        task.wait(2)
    end
end)

--==================================================
-- SETTINGS: PURCHASING
--==================================================

Tabs.SettingsTab:CreateSection({
    name = "Purchasing",
})

Tabs.SettingsTab:CreateDropdown({

    name = "Purchase Method",

    options = {
        "TouchInterest",
        "Teleport Purchase",
    },

    value = "TouchInterest",
    flag = "V125_PurchaseMethod",

    callback = function(value)

        State.purchaseMethod = value

        logActivity(
            "Purchase method set to " .. value .. "."
        )
    end,
})

Tabs.SettingsTab:CreateDropdown({

    name = "Purchase Priority",

    options = {
        "Cheapest First",
        "Most Expensive First",
        "Closest First",
    },

    value = "Cheapest First",
    flag = "V125_PurchasePriority",

    callback = function(value)

        State.purchasePriority = value

        logActivity(
            "Purchase priority set to " .. value .. "."
        )
    end,
})

--==================================================
-- SETTINGS: COLLECTION
--==================================================

Tabs.SettingsTab:CreateSection({
    name = "Collection",
})

Tabs.SettingsTab:CreateDropdown({

    name = "Collection Method",

    description = "Choose the mailbox collection method.",

    options = {
        "TouchInterest",
        "Teleport",
    },

    value = "TouchInterest",
    flag = "V134_CollectionMethod",

    callback = function(value)

        State.collectionMethod = value

        State.autoClaimParkedAtMailbox = false
        State.autoClaimMailboxCFrame = nil
        State.lastCollectionAttempt = -math.huge

        logActivity(
            "Collection method set to " .. value .. "."
        )

        Island.refreshMode()
    end,
})

Tabs.SettingsTab:CreateToggle({

    name = "Skip Buttons With Rebirth Requirement",

    description = "Exclude buttons containing a RebirthReq value.",

    value = true,
    flag = "V125_SkipRebirth",

    callback = function(value)

        State.skipRebirthRequirements = value

        logActivity(
            "Skip Buttons With Rebirth Requirement "
            .. (value and "enabled." or "disabled.")
        )

        Purchasing.syncPurchaseButtons()
        ESP.refresh()
    end,
})

--==================================================
-- SETTINGS: INTERFACE
--==================================================

Tabs.SettingsTab:CreateSection({
    name = "Interface",
})

Tabs.SettingsTab:CreateToggle({

    name = "Show Dynamic Island",

    description = "Hides or shows the HUD without stopping automation.",

    value = true,
    flag = "V125_ShowDynamicIsland",

    callback = function(value)

        Island.setVisible(value)

        logActivity(
            "Dynamic Island "
            .. (value and "shown." or "hidden.")
        )
    end,
})

--==================================================
-- MISC: SESSION
--==================================================

Tabs.MiscTab:CreateSection({
    name = "Session",
})

Tabs.MiscTab:CreateToggle({

    name = "Anti-AFK",

    description = "Attempts an input every 10 minutes to reduce idle disconnects.",

    value = true,
    flag = "V132_AntiAFK",

    callback = function(value)

        AntiAFK.setEnabled(value)
    end,
})

--==================================================
-- MISC: LIGHTING
--==================================================

Tabs.MiscTab:CreateSection({
    name = "Lighting",
})

Tabs.MiscTab:CreateToggle({

    name = "Fullbright",

    value = false,
    flag = "V125_Fullbright",

    callback = function(value)

        LightingSystem.setFullbright(value)

        logActivity(
            "Fullbright "
            .. (value and "enabled." or "disabled.")
        )
    end,
})

--==================================================
-- CLEANUP
--==================================================

local Resources = Island.resources

Resources.window = Tabs.window
Resources.islandGui = Island.gui
Resources.clearAllESP = ESP.clearAllESP

Resources.logActivity = logActivity

Resources.applyFullbright = function(enabled)
    LightingSystem.setFullbright(enabled)
end

local Cleanup = loadModule("Core/Cleanup.lua")(
    State,
    Helpers,
    Resources
)

--==================================================
-- UNLOAD BUTTON
--==================================================

Tabs.SettingsTab:CreateSection({
    name = "Script",
})

Tabs.SettingsTab:CreateButton({

    name = "Unload Auto Tycoon",

    callback = function()
        Cleanup.unload()
    end,
})

--==================================================
-- REGISTER CLEANUP
--==================================================

_G.AutoTycoonV13Cleanup = Cleanup.unload
_G.AutoTycoonV132Cleanup = Cleanup.unload
_G.AutoTycoonV133Cleanup = Cleanup.unload
_G.AutoTycoonV134Cleanup = Cleanup.unload

--==================================================
-- START SYSTEMS
--==================================================

Character.start()

AntiAFK.start()

AutoBuy.start()

AutoCollect.start()

ESP.start()

--==================================================
-- PURCHASE LIST REFRESH
--==================================================

task.spawn(function()

    while State.running do

        Purchasing.syncPurchaseButtons()

        task.wait(1.5)
    end
end)

--==================================================
-- INITIAL DYNAMIC ISLAND
--==================================================

Island.setStatus(
    "WaitingForTask",
    nil,
    nil,
    true
)

--==================================================
-- FINAL LOAD
--==================================================

logActivity(
    "Welcome, "
    .. LocalPlayer.DisplayName
    .. ". Auto Tycoon Version 1.4 Alpha is ready."
)

print("================================")
print("AUTO TYCOON VERSION 1.4 ALPHA")
print("MODULAR ARCHITECTURE INITIALIZED")
print("================================")
print("Rayfield: LOADED")
print("Dynamic Island: LOADED")
print("Money Detection: ENABLED")
print("Auto Buy: READY")
print("Auto Collect: READY")
print("Button ESP: READY")
print("Anti-AFK: READY")
print("House Progression: NOT IMPLEMENTED")
print("================================")
