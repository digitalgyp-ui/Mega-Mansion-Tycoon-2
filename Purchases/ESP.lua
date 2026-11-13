
--==================================================
-- AUTO TYCOON V1.4 ALPHA
-- PURCHASES: ESP
--==================================================

return function(State, Helpers, Dependencies)

    local ESP = {}

    local Detection = Dependencies.Detection
    local PlayerGui = Dependencies.PlayerGui
    local getMoneyValue = Dependencies.getMoneyValue

    local formatNumber = Helpers.formatNumber
    local COLORS = State.COLORS

    --==================================================
    -- REMOVE ESP
    --==================================================

    function ESP.removeESPFor(model)

        local bundle = State.espObjects[model]

        if not bundle then
            return
        end

        pcall(function()
            if bundle.highlight then
                bundle.highlight:Destroy()
            end
        end)

        pcall(function()
            if bundle.billboard then
                bundle.billboard:Destroy()
            end
        end)

        State.espObjects[model] = nil
    end

    --==================================================
    -- CLEAR ALL ESP
    --==================================================

    function ESP.clearAllESP()

        for model in pairs(State.espObjects) do
            ESP.removeESPFor(model)
        end
    end

    --==================================================
    -- REBIRTH REQUIREMENT TEXT
    --==================================================

    local function getRebirthRequirementText(requirementObject)

        if not requirementObject then
            return nil
        end

        local rawValue = requirementObject:IsA("ValueBase")
            and requirementObject.Value
            or requirementObject.Name

        local numericValue = tonumber(rawValue)

        if numericValue then
            return formatNumber(numericValue)
                .. " Rebirths Required"
        end

        local text = tostring(rawValue)

        if text == "true" or text == "false" then
            return "Rebirth Required"
        end

        return text .. " Rebirths Required"
    end

    --==================================================
    -- ESP BUTTON DATA
    --==================================================

    function ESP.getESPButtonData()

        local buttonsFolder = Detection.getButtonsFolder()

        if not buttonsFolder then
            return {}
        end

        local results = {}

        for _, model in ipairs(buttonsFolder:GetChildren()) do

            local hitbox = model:FindFirstChild("TouchHitbox", true)

            if hitbox and hitbox:IsA("BasePart") then

                local goldify =
                    Detection.isGoldifyButton(model)

                local rebirthObject =
                    model:FindFirstChild("RebirthReq", true)

                local rebirthText =
                    getRebirthRequirementText(rebirthObject)

                local devProduct =
                    model:FindFirstChild("DevProduct", true) ~= nil

                local priceObject =
                    model:FindFirstChild("Price", true)

                local price =
                    priceObject and priceObject:IsA("ValueBase")
                    and tonumber(priceObject.Value)
                    or nil

                local include = false

                local entry = {
                    model = model,
                    name = model.Name,
                    hitbox = hitbox,
                    isGoldify = goldify,
                    isRebirth = rebirthObject ~= nil,
                    rebirthText = rebirthText,
                    price = price,
                }

                if goldify then
                    entry.price = 39
                    include = true

                elseif rebirthObject and not devProduct then
                    include = true

                elseif not devProduct and price ~= nil then
                    include = true
                end

                if include then
                    table.insert(results, entry)
                end
            end
        end

        return results
    end

    --==================================================
    -- CREATE BILLBOARD
    --==================================================

    local function createESPBillboard(bundle, data)

        if bundle.billboard then
            return
        end

        local billboard = Instance.new("BillboardGui")

        billboard.Name = "AutoTycoonButtonLabel"
        billboard.Adornee = data.hitbox

        billboard.Size = UDim2.fromOffset(
            170,
            data.isRebirth and 48 or 42
        )

        billboard.StudsOffset = Vector3.new(0, 2.5, 0)
        billboard.AlwaysOnTop = true
        billboard.LightInfluence = 0
        billboard.Parent = PlayerGui

        local label = Instance.new("TextLabel")

        label.Size = UDim2.fromScale(1, 1)
        label.BackgroundColor3 = Color3.fromRGB(5, 10, 17)
        label.BackgroundTransparency = 0.12
        label.BorderSizePixel = 0
        label.Font = Enum.Font.GothamBold
        label.TextSize = 12
        label.TextColor3 = COLORS.White
        label.TextStrokeTransparency = 0.8
        label.TextWrapped = true
        label.Parent = billboard

        local corner = Instance.new("UICorner")

        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = label

        local stroke = Instance.new("UIStroke")

        stroke.Color = COLORS.Blue
        stroke.Transparency = 0.25
        stroke.Parent = label

        bundle.billboard = billboard
        bundle.label = label
        bundle.stroke = stroke
    end

    --==================================================
    -- REMOVE BILLBOARD
    --==================================================

    local function removeESPBillboard(bundle)

        if bundle and bundle.billboard then

            pcall(function()
                bundle.billboard:Destroy()
            end)

            bundle.billboard = nil
            bundle.label = nil
            bundle.stroke = nil
        end
    end

    --==================================================
    -- ADD / UPDATE ESP
    --==================================================

    local function addOrUpdateESP(data, money)

        local model = data.model
        local bundle = State.espObjects[model]

        if not bundle then

            local highlight = Instance.new("Highlight")

            highlight.Name = "AutoTycoonButtonHighlight"
            highlight.Adornee = model
            highlight.DepthMode =
                Enum.HighlightDepthMode.AlwaysOnTop

            highlight.Parent = model

            bundle = {
                highlight = highlight,
            }

            State.espObjects[model] = bundle
        end

        bundle.highlight.Adornee = model

        if State.buttonESPEnabled then

            local affordable =
                data.price ~= nil and data.price <= money

            local espColor
            local outlineColor
            local labelText

            if data.isGoldify then

                espColor = COLORS.Gold
                outlineColor = Color3.fromRGB(255, 224, 130)
                labelText = "Goldify\n39 Robux"

            elseif data.isRebirth then

                espColor = COLORS.Orange
                outlineColor = Color3.fromRGB(255, 190, 112)

                labelText = data.name
                    .. "\n"
                    .. tostring(
                        data.rebirthText or "Rebirth Required"
                    )

                if data.price and data.price > 0 then

                    labelText = labelText
                        .. "\n$"
                        .. formatNumber(data.price)
                end

            else

                espColor = affordable and COLORS.Green or COLORS.Red

                outlineColor = affordable
                    and Color3.fromRGB(145, 255, 185)
                    or Color3.fromRGB(255, 155, 160)

                labelText = data.name
                    .. "\n$"
                    .. formatNumber(data.price or 0)
            end

            bundle.highlight.FillColor = espColor
            bundle.highlight.OutlineColor = outlineColor
            bundle.highlight.FillTransparency = 0.82
            bundle.highlight.OutlineTransparency = 0.08

            createESPBillboard(bundle, data)

            bundle.billboard.Adornee = data.hitbox

            bundle.billboard.Size = UDim2.fromOffset(
                170,
                data.isRebirth and 48 or 42
            )

            bundle.label.Text = labelText
            bundle.label.TextColor3 = espColor
            bundle.stroke.Color = espColor

        else

            -- Outline-only mode.

            removeESPBillboard(bundle)

            bundle.highlight.FillColor = COLORS.Blue
            bundle.highlight.OutlineColor =
                Color3.fromRGB(125, 195, 255)

            bundle.highlight.FillTransparency = 1
            bundle.highlight.OutlineTransparency = 0.05
        end
    end

    --==================================================
    -- REFRESH ESP / HIGHLIGHT
    --==================================================

    function ESP.refresh()

        if not State.buttonESPEnabled
            and not State.buttonHighlightEnabled then

            ESP.clearAllESP()
            return
        end

        local entries = ESP.getESPButtonData()
        local money = getMoneyValue()
        local present = {}

        for _, data in ipairs(entries) do

            present[data.model] = true

            addOrUpdateESP(data, money)
        end

        for model in pairs(State.espObjects) do

            if not present[model] then
                ESP.removeESPFor(model)
            end
        end
    end

    --==================================================
    -- ESP LOOP
    --==================================================

    function ESP.start()

        task.spawn(function()

            while State.running do

                ESP.refresh()

                task.wait(0.4)
            end

            ESP.clearAllESP()
        end)
    end

    --==================================================
    -- ESP UI
    --==================================================

    function ESP.createUI(AutomationsTab, logActivity)

        AutomationsTab:CreateSection({
            name = "Detection",
        })

        AutomationsTab:CreateToggle({
            name = "Button ESP",
            value = false,
            flag = "V133_ButtonESP",

            callback = function(value)

                State.buttonESPEnabled = value

                ESP.refresh()

                logActivity(
                    "Button ESP "
                    .. (value and "enabled." or "disabled.")
                )
            end,
        })

        AutomationsTab:CreateToggle({
            name = "Button Highlight",
            description =
                "Shows button outlines only, without prices or labels.",

            value = false,
            flag = "V133_ButtonHighlight",

            callback = function(value)

                State.buttonHighlightEnabled = value

                ESP.refresh()

                logActivity(
                    "Button Highlight "
                    .. (value and "enabled." or "disabled.")
                )
            end,
        })
    end

    return ESP
end
