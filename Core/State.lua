
--==================================================
-- AUTO TYCOON V1.4 ALPHA
-- CORE: SHARED STATE
--==================================================

local State = {}

-- Script state
State.running = true
State.connections = {}

-- Automation
State.autoBuyEnabled = false
State.autoClaimEnabled = false
State.buttonESPEnabled = false
State.buttonHighlightEnabled = false

-- Anti-AFK
State.antiAFKEnabled = true
State.antiAFKInterval = 600
State.antiAFKLastPulse = os.clock()
State.antiAFKLoopToken = 0
State.antiAFKLastWarning = 0

-- Purchasing
State.purchaseMethod = "TouchInterest"
State.purchasePriority = "Cheapest First"
State.skipRebirthRequirements = true
State.purchaseBusy = false

-- Collection
State.collectionMethod = "TouchInterest"
State.COLLECTION_COOLDOWN = 2
State.COLLECTION_CHECK_INTERVAL = 2
State.movementBusy = false
State.lastMissingMailboxLog = 0
State.autoClaimParkedAtMailbox = false
State.autoClaimMailboxCFrame = nil
State.lastCollectionAttempt = -math.huge

-- Interface
State.showDynamicIsland = true

-- Character
State.walkSpeedValue = 16
State.jumpHeightValue = 7.2
State.infiniteJumpEnabled = false

State.movementDefaults = {
    WalkSpeed = 16,
    JumpHeight = 7.2,
    JumpPower = 50,
    UseJumpPower = true,
}

-- Lighting
State.fullbrightEnabled = false

-- Dynamic Island animation
State.purchaseAnimationActive = false
State.animationToken = 0
State.gradientWipeToken = 0
State.islandStatusRevision = 0
State.islandStatusHoldUntil = 0

State.currentIslandState = {
    kind = "WaitingForTask",
    data = {},
}

-- Tracking
State.purchaseHandles = {}
State.purchasedModels = {}
State.espObjects = {}
State.leaderstatBindings = {}

-- Colors
State.COLORS = {
    Grey = Color3.fromRGB(75, 86, 101),
    Green = Color3.fromRGB(55, 220, 145),
    Red = Color3.fromRGB(245, 83, 91),
    Blue = Color3.fromRGB(80, 170, 255),
    Orange = Color3.fromRGB(255, 166, 66),
    Gold = Color3.fromRGB(255, 207, 82),

    White = Color3.fromRGB(239, 244, 250),
    Muted = Color3.fromRGB(145, 155, 175),

    Success = Color3.fromRGB(145, 255, 185),
    Collected = Color3.fromRGB(105, 195, 255),
    CaughtUp = Color3.fromRGB(165, 216, 255),
}

return State
