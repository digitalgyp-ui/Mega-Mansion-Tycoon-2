
--==================================================
-- AUTO TYCOON V1.4 ALPHA
-- AUTOMATION: AUTO BUY
--==================================================

return function(State, Dependencies)

    local AutoBuy = {}

    local Detection = Dependencies.Detection
    local Purchasing = Dependencies.Purchasing
    local Island = Dependencies.Island

    local getMoneyValue = Dependencies.getMoneyValue
    local logActivity = Dependencies.logActivity

    --==================================================
    -- AUTO BUY LOOP
    --==================================================

    function AutoBuy.start()

        task.spawn(function()

            while State.running do

                if State.autoBuyEnabled
                    and not State.purchaseBusy
                    and not State.purchaseAnimationActive then

                    local purchases = Detection.getAllPurchases()

                    Detection.sortPurchases(purchases)

                    local money = getMoneyValue()
                    local target

                    for _, data in ipairs(purchases) do

                        if data.price <= money then
                            target = data
                            break
                        end
                    end

                    if target then

                        Island.setStatus(
                            "Buying",
                            {
                                item = target.name,
                                price = target.price,
                                affordable = true,
                            }
                        )

                        Purchasing.runPurchaseAsync(
                            target,
                            "Auto Buy"
                        )

                    elseif #purchases > 0 then

                        local nextPurchase = purchases[1]

                        local status =
                            State.autoClaimEnabled
                            and "Saving"
                            or "CannotAfford"

                        Island.setStatus(
                            status,
                            {
                                item = nextPurchase.name,
                                current = money,
                                price = nextPurchase.price,
                                remaining = math.max(
                                    0,
                                    nextPurchase.price - money
                                ),
                            }
                        )

                    else

                        Island.setStatus("WaitingForTask")
                    end

                elseif not State.autoBuyEnabled
                    and State.autoClaimEnabled then

                    local purchases = Detection.getAllPurchases()

                    if #purchases == 0 then
                        Island.setStatus("WaitingForTask")
                    else
                        Island.setStatus("CollectingMoney")
                    end

                elseif not State.autoBuyEnabled
                    and not State.autoClaimEnabled then

                    if not State.purchaseAnimationActive then
                        Island.setStatus("WaitingForTask")
                    end
                end

                task.wait(0.45)
            end
        end)
    end

    --==================================================
    -- AUTO BUY UI
    --==================================================

    function AutoBuy.createUI(AutomationsTab)

        AutomationsTab:CreateSection({
            name = "Purchase Automation",
        })

        AutomationsTab:CreateToggle({
            name = "Auto Buy",
            value = false,
            flag = "V133_AutoBuy",

            callback = function(value)

                State.autoBuyEnabled = value

                if value then

                    logActivity("Auto Buy enabled.")

                    Island.setStatus(
                        "Scanning",
                        nil,
                        nil,
                        true
                    )

                else

                    logActivity("Auto Buy disabled.")

                    Island.refreshMode()
                end
            end,
        })
    end

    return AutoBuy
end
