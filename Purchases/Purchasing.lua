
--==================================================
-- AUTO TYCOON V1.4 ALPHA
-- PURCHASES: PURCHASING
--==================================================

return function(State, Helpers, Dependencies)

    local Purchasing = {}

    local Detection = Dependencies.Detection
    local Character = Dependencies.Character
    local Island = Dependencies.Island

    local getMoneyValue = Dependencies.getMoneyValue
    local logActivity = Dependencies.logActivity

    local formatNumber = Helpers.formatNumber

    --==================================================
    -- PURCHASE HANDLE VISIBILITY
    --==================================================

    function Purchasing.hidePurchaseHandle(model)

        local handle = State.purchaseHandles[model]

        if handle and handle.main then
            handle.main.Visible = false
        end
    end

    --==================================================
    -- ATTEMPT PURCHASE
    --==================================================

    function Purchasing.attemptPurchase(data, source)

        if State.purchaseBusy
            or State.purchaseAnimationActive
            or not State.running then
            return false
        end

        local freshData = data
            and Detection.getPurchaseData(
                data.model,
                Detection.getButtonsFolder()
            )

        if not freshData then
            logActivity("Purchase skipped: button is no longer available.")
            return false
        end

        State.purchaseBusy = true

        local beforeMoney = getMoneyValue()

        if beforeMoney < freshData.price then

            if State.autoClaimEnabled then

                Island.setStatus(
                    "Saving",
                    {
                        item = freshData.name,
                        current = beforeMoney,
                        price = freshData.price,
                        remaining = freshData.price - beforeMoney,
                    },
                    nil,
                    true
                )

            else

                Island.setStatus(
                    "CannotAfford",
                    {
                        item = freshData.name,
                        price = freshData.price,
                        current = beforeMoney,
                        remaining = freshData.price - beforeMoney,
                    },
                    nil,
                    true
                )
            end

            logActivity(
                "Not enough money for "
                .. freshData.name
                .. " ($"
                .. formatNumber(freshData.price)
                .. ")."
            )

            State.purchaseBusy = false
            return false
        end

        Island.setStatus(
            "Buying",
            {
                item = freshData.name,
                price = freshData.price,
                affordable = true,
            },
            nil,
            true
        )

        logActivity(
            "Attempting "
            .. freshData.name
            .. " for $"
            .. formatNumber(freshData.price)
            .. " using "
            .. State.purchaseMethod
            .. "."
        )

        --==================================================
        -- PURCHASE INTERACTION
        --==================================================

        -- Use the game's supported purchase interaction here.
        -- The original executor-only touch/teleport interaction
        -- is intentionally not reproduced in this module.

        local triggered = false
        local triggerError = "No supported purchase interaction configured."

        if type(Dependencies.purchaseInteraction) == "function" then

            local ok, result, err = pcall(
                Dependencies.purchaseInteraction,
                freshData
            )

            triggered = ok and result == true
            triggerError = ok and err or tostring(result)
        end

        if not triggered then

            logActivity(
                "Could not trigger "
                .. freshData.name
                .. ": "
                .. tostring(triggerError)
            )

            Island.setStatus(
                "Target",
                {
                    item = freshData.name,
                    price = freshData.price,
                },
                nil,
                true
            )

            State.purchaseBusy = false
            return false
        end

        --==================================================
        -- PURCHASE CONFIRMATION
        --==================================================

        local confirmed = false
        local buttonsFolder = freshData.buttonsFolder

        for _ = 1, 24 do

            task.wait(0.10)

            if not freshData.model.Parent
                or not buttonsFolder
                or not freshData.model:IsDescendantOf(buttonsFolder) then

                confirmed = true
                break
            end

            local currentMoney = getMoneyValue()

            if freshData.price > 0
                and currentMoney < beforeMoney then

                confirmed = true
                break
            end
        end

        --==================================================
        -- PURCHASE RESULT
        --==================================================

        if confirmed then

            State.purchasedModels[freshData.model] = true

            Purchasing.hidePurchaseHandle(freshData.model)

            logActivity(
                "Purchased "
                .. freshData.name
                .. " for $"
                .. formatNumber(freshData.price)
                .. "."
            )

            Island.playPurchaseSuccessEffect(
                freshData.name,
                freshData.price,
                source
            )

        else

            logActivity(
                "Purchase not confirmed for "
                .. freshData.name
                .. ". It remains available for retrying."
            )

            if State.autoBuyEnabled then

                Island.setStatus(
                    "Target",
                    {
                        item = freshData.name,
                        price = freshData.price,
                    },
                    nil,
                    true
                )

            elseif State.autoClaimEnabled then

                Island.setStatus(
                    "CollectingMoney",
                    nil,
                    nil,
                    true
                )

            else

                Island.setStatus(
                    "WaitingForTask",
                    nil,
                    nil,
                    true
                )
            end
        end

        State.purchaseBusy = false

        return confirmed
    end

    --==================================================
    -- ASYNC PURCHASE
    --==================================================

    function Purchasing.runPurchaseAsync(data, source)

        task.spawn(function()

            local ok, err = pcall(
                Purchasing.attemptPurchase,
                data,
                source
            )

            if not ok then

                State.purchaseBusy = false
                State.movementBusy = false

                logActivity(
                    "Purchase error: " .. tostring(err)
                )

                if State.autoBuyEnabled then

                    Island.setStatus(
                        "Scanning",
                        nil,
                        nil,
                        true
                    )
                end
            end
        end)
    end

    --==================================================
    -- PURCHASE LIST UI
    --==================================================

    function Purchasing.createUI(PurchasesTab, LocalPlayer)

        PurchasesTab:CreateSection({
            name = "Available Purchases",
        })

        local purchaseStatusText = PurchasesTab:CreateText({
            text = "Scanning your tycoon buttons...",
        })

        function Purchasing.syncPurchaseButtons()

            local purchases, buttonsFolder =
                Detection.getAllPurchases()

            local present = {}

            for _, data in ipairs(purchases) do

                present[data.model] = true

                local handle = State.purchaseHandles[data.model]

                local displayName = string.format(
                    "%s  •  $%s",
                    data.name,
                    formatNumber(data.price)
                )

                if not handle then

                    local modelForButton = data.model
                    local nameForButton = data.name

                    handle = PurchasesTab:CreateButton({
                        name = displayName,

                        callback = function()

                            local current =
                                Detection.getPurchaseData(
                                    modelForButton,
                                    Detection.getButtonsFolder()
                                )

                            if current then

                                Purchasing.runPurchaseAsync(
                                    current,
                                    "Individual Buy"
                                )

                            else

                                Purchasing.hidePurchaseHandle(
                                    modelForButton
                                )

                                logActivity(
                                    nameForButton
                                    .. " is no longer available."
                                )
                            end
                        end,
                    })

                    State.purchaseHandles[data.model] = handle

                    logActivity(
                        "Purchase detected: "
                        .. nameForButton
                        .. " ($"
                        .. formatNumber(data.price)
                        .. ")."
                    )

                else

                    if handle.title then
                        handle.title.Text = displayName
                    end

                    if handle.main then
                        handle.main.Visible = true
                    end
                end
            end

            for model, handle in pairs(State.purchaseHandles) do

                if not present[model] and handle.main then
                    handle.main.Visible = false
                end
            end

            local count = #purchases

            local instructions =
                'Teleport to your base to load buttons. If buttons aren\'t loaded, press "Refresh Purchase List" to reload them.'

            if not buttonsFolder then

                purchaseStatusText:Set(
                    "Waiting for "
                    .. LocalPlayer.Name
                    .. "_TycoonStorage.Buttons...\n"
                    .. instructions
                )

            elseif count == 0 then

                purchaseStatusText:Set(
                    "No available normal purchases detected.\n"
                    .. instructions
                )

            else

                purchaseStatusText:Set(
                    string.format(
                        "%d available purchase(s).\n%s",
                        count,
                        instructions
                    )
                )
            end
        end

        PurchasesTab:CreateButton({
            name = "Refresh Purchase List",

            callback = function()

                if Purchasing.syncPurchaseButtons then

                    Purchasing.syncPurchaseButtons()

                    logActivity(
                        "Purchase list refreshed manually."
                    )
                end
            end,
        })

        return purchaseStatusText
    end

    return Purchasing
end
