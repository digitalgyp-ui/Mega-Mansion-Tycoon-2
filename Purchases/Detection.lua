
--==================================================
-- AUTO TYCOON V1.4 ALPHA
-- PURCHASES: DETECTION
--==================================================

return function(State, LocalPlayer)

    local Detection = {}

    --==================================================
    -- TYCOON BUTTON DETECTION
    --==================================================

    function Detection.getButtonsFolder()

        local storageName = LocalPlayer.Name .. "_TycoonStorage"
        local storage = workspace:FindFirstChild(storageName)

        if not storage then
            storage = workspace:FindFirstChild(storageName, true)
        end

        if not storage then
            return nil
        end

        return storage:FindFirstChild("Buttons")
    end

    --==================================================
    -- GOLDIFY DETECTION
    --==================================================

    function Detection.isGoldifyButton(model)

        if not model then
            return false
        end

        if string.find(string.lower(model.Name), "goldify", 1, true) then
            return true
        end

        for _, descendant in ipairs(model:GetDescendants()) do

            if string.find(
                string.lower(descendant.Name),
                "goldify",
                1,
                true
            ) then
                return true
            end

            if descendant:IsA("StringValue") then

                if string.find(
                    string.lower(tostring(descendant.Value)),
                    "goldify",
                    1,
                    true
                ) then
                    return true
                end

            elseif descendant:IsA("TextLabel")
                or descendant:IsA("TextButton") then

                if string.find(
                    string.lower(descendant.Text),
                    "goldify",
                    1,
                    true
                ) then
                    return true
                end
            end
        end

        return false
    end

    --==================================================
    -- PURCHASE DATA
    --==================================================

    function Detection.getPurchaseData(
        model,
        buttonsFolder,
        includeRebirth
    )

        if not model
            or not model.Parent
            or State.purchasedModels[model] then
            return nil
        end

        buttonsFolder = buttonsFolder or Detection.getButtonsFolder()

        if not buttonsFolder
            or not model:IsDescendantOf(buttonsFolder) then
            return nil
        end

        if model:FindFirstChild("DevProduct", true)
            or Detection.isGoldifyButton(model) then
            return nil
        end

        local priceObject = model:FindFirstChild("Price", true)

        if not priceObject or not priceObject:IsA("ValueBase") then
            return nil
        end

        local price = tonumber(priceObject.Value)

        if price == nil then
            return nil
        end

        if State.skipRebirthRequirements
            and not includeRebirth
            and model:FindFirstChild("RebirthReq", true) then
            return nil
        end

        local hitboxPart = model:FindFirstChild("TouchHitbox", true)

        if not hitboxPart or not hitboxPart:IsA("BasePart") then
            return nil
        end

        return {
            model = model,
            name = model.Name,
            price = price,
            hitbox = hitboxPart,
            buttonsFolder = buttonsFolder,
        }
    end

    --==================================================
    -- ALL PURCHASES
    --==================================================

    function Detection.getAllPurchases()

        local buttonsFolder = Detection.getButtonsFolder()

        if not buttonsFolder then
            return {}, nil
        end

        local purchases = {}

        for _, child in ipairs(buttonsFolder:GetChildren()) do

            local data = Detection.getPurchaseData(
                child,
                buttonsFolder
            )

            if data then
                table.insert(purchases, data)
            end
        end

        return purchases, buttonsFolder
    end

    --==================================================
    -- PURCHASE DISTANCE
    --==================================================

    function Detection.getDistanceTo(data)

        local character = LocalPlayer.Character

        local root = character
            and character:FindFirstChild("HumanoidRootPart")

        if not root
            or not data.hitbox
            or not data.hitbox.Parent then
            return math.huge
        end

        return (root.Position - data.hitbox.Position).Magnitude
    end

    --==================================================
    -- PURCHASE SORTING
    --==================================================

    function Detection.sortPurchases(purchases)

        table.sort(purchases, function(a, b)

            if State.purchasePriority == "Most Expensive First" then

                if a.price == b.price then
                    return a.name < b.name
                end

                return a.price > b.price

            elseif State.purchasePriority == "Closest First" then

                local distanceA = Detection.getDistanceTo(a)
                local distanceB = Detection.getDistanceTo(b)

                if distanceA == distanceB then
                    return a.price < b.price
                end

                return distanceA < distanceB

            else

                if a.price == b.price then
                    return a.name < b.name
                end

                return a.price < b.price
            end
        end)

        return purchases
    end

    function Detection.getSortedPurchases()

        local purchases = Detection.getAllPurchases()

        return Detection.sortPurchases(purchases)
    end

    --==================================================
    -- NEXT UNAFFORDABLE PURCHASE
    --==================================================

    function Detection.getNextUnaffordablePurchase(getMoneyValue)

        local purchases = Detection.getAllPurchases()

        Detection.sortPurchases(purchases)

        local money = getMoneyValue()

        for _, data in ipairs(purchases) do

            if data.price > money then
                return data, money
            end
        end

        return nil, money
    end

    return Detection
end
