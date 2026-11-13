
--==================================================
-- AUTO TYCOON V1.4 ALPHA
-- AUTOMATION: AUTO COLLECT
--==================================================

return function(State, Helpers, Dependencies)

    local AutoCollect = {}

    local LocalPlayer = Dependencies.LocalPlayer
    local Character = Dependencies.Character
    local Island = Dependencies.Island
    local Detection = Dependencies.Detection

    local getMoneyValue = Dependencies.getMoneyValue
    local waitForMoneyDelta = Dependencies.waitForMoneyDelta
    local logActivity = Dependencies.logActivity

    local formatNumber = Helpers.formatNumber

    --==================================================
    -- MAILBOX DETECTION
    --==================================================

    function AutoCollect.findOwnedMailbox()

        local bases = workspace:FindFirstChild("TycoonBases")
            or workspace:FindFirstChild("TycoonBases", true)

        if not bases then
            return nil
        end

        for _, base in ipairs(bases:GetChildren()) do

            local owner = base:FindFirstChild("Owner", true)

            if owner and tostring(owner.Value) == LocalPlayer.Name then

                local mailbox = base:FindFirstChild("Mailbox", true)

                if mailbox then
                    return mailbox
                end
            end
        end

        return nil
    end

    --==================================================
    -- INSTANCE CFRAME
    --==================================================

    local function getInstanceCFrame(instance)

        if not instance then
            return nil
        end

        if instance:IsA("BasePart") then
            return instance.CFrame
        end

        if instance:IsA("Model") then
            return instance:GetPivot()
        end

        local part = instance:FindFirstChildWhichIsA(
            "BasePart",
            true
        )

        return part and part.CFrame or nil
    end

    --==================================================
    -- MAILBOX TOUCH PART DETECTION
    --==================================================

    function AutoCollect.findMailboxTouchPart(mailbox)

        if not mailbox then
            return nil
        end

        for _, descendant in ipairs(mailbox:GetDescendants()) do

            if descendant:IsA("BasePart") then

                local transmitter =
                    descendant:FindFirstChild("TouchInterest")
                    or descendant:FindFirstChildOfClass(
                        "TouchTransmitter"
                    )

                if transmitter then
                    return descendant
                end
            end
        end

        local children = mailbox:GetChildren()
        local knownTouchPart = children[5]

        if knownTouchPart and knownTouchPart:IsA("BasePart") then
            return knownTouchPart
        end

        return nil
    end

    --==================================================
    -- ISLAND STATUS HELPERS
    --==================================================

    local function updateAutomationIsland(force)

        local purchases = Detection.getAllPurchases()

        if #purchases == 0 then

            Island.setStatus(
                "WaitingForTask",
                nil,
                nil,
                force == true
            )

            return
        end

        if State.autoBuyEnabled then

            local target, money =
                Detection.getNextUnaffordablePurchase(getMoneyValue)

            if target then

                Island.setStatus(
                    "Saving",
                    {
                        item = target.name,
                        current = money,
                        price = target.price,
                        remaining = math.max(
                            0,
                            target.price - money
                        ),
                    },
                    nil,
                    force == true
                )

            else

                Island.setStatus(
                    "Scanning",
                    nil,
                    nil,
                    force == true
                )
            end

        elseif State.autoClaimEnabled then

            Island.setStatus(
                "CollectingMoney",
                nil,
                nil,
                force == true
            )

        else

            Island.setStatus(
                "WaitingForTask",
                nil,
                nil,
                force == true
            )
        end
    end

    local function displayCollectedAmount(amount, forceShow)

        if not forceShow
            and not Island.shouldShowCollectionStatus() then
            return
        end

        if amount <= 0 then
            return
        end

        Island.setStatus(
            "Collected",
            {
                amount = amount,
            },
            1.25,
            true
        )
    end

    --==================================================
    -- MAILBOX INTERACTION ADAPTER
    --==================================================

    local function triggerMailboxTouch(root, mailbox)

        if not root then
            return false, "Character HumanoidRootPart is missing."
        end

        local touchPart =
            AutoCollect.findMailboxTouchPart(mailbox)

        if not touchPart then
            return false, "Mailbox interaction part was not found."
        end

        local interact = Dependencies.mailboxInteraction

        if type(interact) ~= "function" then
            return false, "No supported mailbox interaction is configured."
        end

        local ok, result = pcall(interact, root, touchPart)

        if not ok then
            return false, tostring(result)
        end

        if result ~= true then
            return false, "Mailbox interaction was not confirmed."
        end

        return true
    end

    --==================================================
    -- MAILBOX COLLECTION
    --==================================================

    function AutoCollect.collectMailbox(
        reason,
        stayAtMailbox,
        forceIslandStatus
    )

        if State.movementBusy or not State.running then
            return false
        end

        local now = os.clock()

        if now - State.lastCollectionAttempt
            < State.COLLECTION_COOLDOWN then
            return false
        end

        local mailbox = AutoCollect.findOwnedMailbox()
        local root = Character.getRootPart()

        if not mailbox or not root then

            if now - State.lastMissingMailboxLog > 15 then

                State.lastMissingMailboxLog = now

                logActivity(
                    "Mailbox or character was not found for your tycoon."
                )
            end

            return false
        end

        local mailboxCFrame

        if State.collectionMethod == "Teleport" then

            mailboxCFrame = getInstanceCFrame(mailbox)

            if not mailboxCFrame then

                logActivity(
                    "Mailbox position could not be determined."
                )

                return false
            end

        else

            local touchPart =
                AutoCollect.findMailboxTouchPart(mailbox)

            if not touchPart then

                logActivity(
                    "Mailbox interaction part was not found."
                )

                return false
            end

            if type(Dependencies.mailboxInteraction) ~= "function" then

                logActivity(
                    "No supported mailbox interaction is configured."
                )

                return false
            end
        end

        State.lastCollectionAttempt = now

        local showStatus = forceIslandStatus == true
            or Island.shouldShowCollectionStatus()

        if showStatus then

            if forceIslandStatus then

                Island.setStatus(
                    "CollectingMoney",
                    nil,
                    2.2,
                    true
                )

            else

                updateAutomationIsland(true)

                Island.setStatus(
                    "CollectingMoney",
                    nil,
                    2.2,
                    true
                )
            end
        end

        local beforeMoney = getMoneyValue()
        local originalCFrame = root.CFrame

        State.movementBusy = true

        local ok, err

        if State.collectionMethod == "TouchInterest" then

            ok, err = triggerMailboxTouch(root, mailbox)

            State.autoClaimParkedAtMailbox = false
            State.autoClaimMailboxCFrame = nil

        else

            local targetCFrame =
                mailboxCFrame * CFrame.new(0, 2, 0)

            ok, err = pcall(function()

                root.CFrame = targetCFrame

                task.wait(0.40)

                if stayAtMailbox then

                    State.autoClaimMailboxCFrame = targetCFrame
                    State.autoClaimParkedAtMailbox = true

                elseif root.Parent then

                    root.CFrame = originalCFrame
                end
            end)

            if not ok and root.Parent then

                pcall(function()
                    root.CFrame = originalCFrame
                end)
            end
        end

        State.movementBusy = false

        if not ok then

            logActivity(
                "Mailbox collection failed: "
                .. tostring(err or "unknown error")
            )

            if showStatus then

                Island.setStatus(
                    Island.getIdleIslandStatus(),
                    nil,
                    nil,
                    true
                )
            end

            return false
        end

        local gained = waitForMoneyDelta(beforeMoney, 1.5)

        if gained > 0 then

            logActivity(
                "Collected $" ..
                formatNumber(gained) ..
                " from the mailbox."
            )

            displayCollectedAmount(
                gained,
                forceIslandStatus
            )

        else

            if showStatus then

                if forceIslandStatus then

                    Island.setStatus(
                        "AllCaughtUp",
                        nil,
                        1.2,
                        true
                    )

                else

                    updateAutomationIsland(true)
                end
            end

            if reason and reason ~= "Auto Collect Money" then

                logActivity(
                    "Mailbox checked (" ..
                    reason ..
                    "); no new money detected."
                )
            end
        end

        return true
    end

    --==================================================
    -- TELEPORT COLLECTION PULSE
    --==================================================

    function AutoCollect.pulseMailboxClaim()

        if State.movementBusy
            or State.purchaseBusy
            or not State.running
            or not State.autoClaimEnabled
            or State.collectionMethod ~= "Teleport" then

            return false
        end

        local now = os.clock()

        if now - State.lastCollectionAttempt
            < State.COLLECTION_COOLDOWN then

            return false
        end

        local mailbox = AutoCollect.findOwnedMailbox()
        local root = Character.getRootPart()
        local mailboxCFrame = getInstanceCFrame(mailbox)

        if not mailbox or not root or not mailboxCFrame then

            State.autoClaimParkedAtMailbox = false
            State.autoClaimMailboxCFrame = nil

            return false
        end

        local targetCFrame =
            mailboxCFrame * CFrame.new(0, 2, 0)

        local beforeMoney = getMoneyValue()

        State.lastCollectionAttempt = now
        State.movementBusy = true

        updateAutomationIsland(true)

        Island.setStatus(
            "CollectingMoney",
            nil,
            2.2,
            true
        )

        local ok, err = pcall(function()

            if (root.Position - targetCFrame.Position).Magnitude > 8 then

                root.CFrame = targetCFrame

                task.wait(0.35)

            else

                root.CFrame =
                    mailboxCFrame * CFrame.new(0, 5, 0)

                task.wait(0.18)

                root.CFrame = targetCFrame

                task.wait(0.35)
            end

            State.autoClaimMailboxCFrame = targetCFrame
            State.autoClaimParkedAtMailbox = true
        end)

        State.movementBusy = false

        if not ok then

            State.autoClaimParkedAtMailbox = false

            logActivity(
                "Auto Collect Money movement failed: "
                .. tostring(err)
            )

            return false
        end

        local gained = waitForMoneyDelta(beforeMoney, 1.5)

        if gained > 0 then

            logActivity(
                "Auto Collect Money collected $" ..
                formatNumber(gained) .. "."
            )

            displayCollectedAmount(gained)

        else

            updateAutomationIsland(true)
        end

        return true
    end

    --==================================================
    -- AUTO COLLECT LOOP
    --==================================================

    function AutoCollect.start()

        task.spawn(function()

            local nextCollectionCheck = 0

            while State.running do

                local now = os.clock()

                if State.autoClaimEnabled
                    and not State.purchaseBusy
                    and not State.movementBusy
                    and now >= nextCollectionCheck then

                    nextCollectionCheck =
                        now + State.COLLECTION_CHECK_INTERVAL

                    if State.collectionMethod == "TouchInterest" then

                        State.autoClaimParkedAtMailbox = false
                        State.autoClaimMailboxCFrame = nil

                        AutoCollect.collectMailbox(
                            "Auto Collect Money",
                            false
                        )

                    elseif not State.autoClaimParkedAtMailbox then

                        AutoCollect.collectMailbox(
                            "Auto Collect Money",
                            true
                        )

                    else

                        AutoCollect.pulseMailboxClaim()
                    end
                end

                task.wait(0.05)
            end
        end)
    end

    --==================================================
    -- AUTO COLLECT UI
    --==================================================

    function AutoCollect.createUI(AutomationsTab)

        AutomationsTab:CreateToggle({
            name = "Auto Collect Money",
            value = false,
            flag = "V133_AutoClaim",

            callback = function(value)

                State.autoClaimEnabled = value

                State.autoClaimParkedAtMailbox = false
                State.autoClaimMailboxCFrame = nil

                logActivity(
                    "Auto Collect Money "
                    .. (
                        value
                        and ("enabled using " .. State.collectionMethod .. ".")
                        or "disabled."
                    )
                )

                Island.refreshMode()

                if value then

                    Island.setStatus(
                        "CollectingMoney",
                        nil,
                        nil,
                        true
                    )
                end
            end,
        })

        -- MANUAL COLLECTION SECTION

        AutomationsTab:CreateSection({
            name = "Manual Collection",
        })

        AutomationsTab:CreateButton({
            name = "Collect Money Once",

            callback = function()

                task.spawn(function()

                    AutoCollect.collectMailbox(
                        "Manual Collect Money",
                        false,
                        true
                    )
                end)
            end,
        })
    end

    return AutoCollect
end
