
--==================================================
-- AUTO TYCOON V1.4 ALPHA
-- UI: DYNAMIC ISLAND
--==================================================

return function(State, Helpers, Dependencies)

    local Island = {}

    local TweenService = Dependencies.TweenService
    local RunService = Dependencies.RunService
    local UserInputService = Dependencies.UserInputService
    local GUIParent = Dependencies.GUIParent

    local COLORS = State.COLORS

    local escapeRichText = Helpers.escapeRichText
    local colorHex = Helpers.colorHex
    local formatNumber = Helpers.formatNumber
    local formatCompactNumber = Helpers.formatCompactNumber
    local trackConnection = Helpers.trackConnection

    --==================================================
    -- GUI CREATION
    --==================================================

    local islandGui = Instance.new("ScreenGui")
    islandGui.Name = "AutoTycoonV133DynamicIsland"
    islandGui.ResetOnSpawn = false
    islandGui.IgnoreGuiInset = true
    islandGui.DisplayOrder = 9999
    islandGui.Enabled = State.showDynamicIsland
    islandGui.Parent = GUIParent

    local hitbox = Instance.new("TextButton")
    hitbox.Name = "InteractionArea"
    hitbox.Size = UDim2.fromOffset(230, 48)
    hitbox.Position = UDim2.new(0.5, -115, 0, 78)
    hitbox.BackgroundTransparency = 1
    hitbox.BorderSizePixel = 0
    hitbox.Text = ""
    hitbox.AutoButtonColor = false
    hitbox.Active = true
    hitbox.Parent = islandGui

    local visual = Instance.new("Frame")
    visual.Name = "VisualIsland"
    visual.AnchorPoint = Vector2.new(0.5, 0.5)
    visual.Position = UDim2.fromScale(0.5, 0.5)
    visual.Size = UDim2.fromOffset(230, 48)
    visual.BackgroundColor3 = Color3.new(1, 1, 1)
    visual.BorderSizePixel = 0
    visual.Parent = hitbox

    local visualCorner = Instance.new("UICorner")
    visualCorner.CornerRadius = UDim.new(1, 0)
    visualCorner.Parent = visual

    local visualScale = Instance.new("UIScale")
    visualScale.Scale = 1
    visualScale.Parent = visual

    local gradient = Instance.new("UIGradient")
    gradient.Rotation = 0
    gradient.Parent = visual

    local borderStroke = Instance.new("UIStroke")
    borderStroke.Color = Color3.fromRGB(150, 165, 183)
    borderStroke.Thickness = 4
    borderStroke.Transparency = 0.88
    borderStroke.Parent = visual

    local inner = Instance.new("Frame")
    inner.Name = "InnerPill"
    inner.Position = UDim2.fromOffset(4, 4)
    inner.Size = UDim2.new(1, -8, 1, -8)
    inner.BackgroundColor3 = Color3.fromRGB(5, 7, 10)
    inner.BorderSizePixel = 0
    inner.Parent = visual

    local innerCorner = Instance.new("UICorner")
    innerCorner.CornerRadius = UDim.new(1, 0)
    innerCorner.Parent = inner

    local islandHeader = Instance.new("TextLabel")
    islandHeader.Name = "Header"
    islandHeader.BackgroundTransparency = 1
    islandHeader.Position = UDim2.fromOffset(0, 3)
    islandHeader.Size = UDim2.new(1, 0, 0, 11)
    islandHeader.Font = Enum.Font.GothamBold
    islandHeader.Text = "A U T O  T Y C O O N"
    islandHeader.TextSize = 9
    islandHeader.TextColor3 = Color3.fromRGB(125, 132, 143)
    islandHeader.TextXAlignment = Enum.TextXAlignment.Center
    islandHeader.TextTruncate = Enum.TextTruncate.AtEnd
    islandHeader.ZIndex = 3
    islandHeader.Parent = inner

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "Status"
    statusLabel.BackgroundTransparency = 1
    statusLabel.Position = UDim2.fromOffset(7, 14)
    statusLabel.Size = UDim2.new(1, -14, 0, 23)
    statusLabel.Font = Enum.Font.GothamBold
    statusLabel.Text = "Waiting For Task"
    statusLabel.TextSize = 16
    statusLabel.TextColor3 = Color3.fromRGB(205, 210, 218)
    statusLabel.TextXAlignment = Enum.TextXAlignment.Center
    statusLabel.TextYAlignment = Enum.TextYAlignment.Center
    statusLabel.TextTruncate = Enum.TextTruncate.AtEnd
    statusLabel.RichText = true
    statusLabel.ZIndex = 3
    statusLabel.Parent = inner

    local successLabel = Instance.new("TextLabel")
    successLabel.Name = "PurchasedMessage"
    successLabel.BackgroundTransparency = 1
    successLabel.Position = UDim2.fromOffset(5, 14)
    successLabel.Size = UDim2.new(1, -10, 0, 23)
    successLabel.Font = Enum.Font.GothamBold
    successLabel.Text = ""
    successLabel.TextSize = 13
    successLabel.TextColor3 = COLORS.Success
    successLabel.TextTransparency = 1
    successLabel.TextXAlignment = Enum.TextXAlignment.Center
    successLabel.TextYAlignment = Enum.TextYAlignment.Center
    successLabel.RichText = true
    successLabel.Visible = false
    successLabel.ZIndex = 5
    successLabel.Parent = inner

    --==================================================
    -- NORMAL GRADIENT GENERATOR
    --==================================================

    local function gradientFor(color)
        local dark = Color3.fromRGB(3, 5, 8)

        local deep = color:Lerp(dark, 0.78)
        local medium = color:Lerp(dark, 0.48)

        local highlight = color:Lerp(
            Color3.fromRGB(255, 255, 255),
            0.20
        )

        return ColorSequence.new({
            ColorSequenceKeypoint.new(0.00, dark),
            ColorSequenceKeypoint.new(0.30, deep),
            ColorSequenceKeypoint.new(0.40, medium),
            ColorSequenceKeypoint.new(0.50, highlight),
            ColorSequenceKeypoint.new(0.60, medium),
            ColorSequenceKeypoint.new(0.70, deep),
            ColorSequenceKeypoint.new(1.00, dark),
        })
    end

    gradient.Color = gradientFor(COLORS.Grey)

    --==================================================
    -- GRADIENT ROTATION
    --==================================================

    local rotationTween = TweenService:Create(
        gradient,
        TweenInfo.new(
            12,
            Enum.EasingStyle.Linear,
            Enum.EasingDirection.InOut,
            -1
        ),
        {
            Rotation = 360,
        }
    )

    rotationTween:Play()

    --==================================================
    -- MODE DETECTION
    --==================================================

    local function getIslandHeader()
        local collectActive = State.autoClaimEnabled

        if State.autoBuyEnabled and collectActive then
            return "A U T O  T Y C O O N"
        elseif State.autoBuyEnabled then
            return "A U T O  B U Y"
        elseif State.autoClaimEnabled then
            return "A U T O  C O L L E C T  M O N E Y"
        end

        return "A U T O  T Y C O O N"
    end

    function Island.shouldShowCollectionStatus()
        return State.autoBuyEnabled or State.autoClaimEnabled
    end

    function Island.getIdleIslandStatus()
        if State.autoBuyEnabled then
            return "Scanning"
        elseif State.autoClaimEnabled then
            return "CollectingMoney"
        end

        return "WaitingForTask"
    end

    --==================================================
    -- GRADIENT COLOR SAMPLER
    --==================================================

    local function sampleGradient(sequence, position)
        local points = sequence.Keypoints

        for i = 1, #points - 1 do
            local first = points[i]
            local second = points[i + 1]

            if position <= second.Time then
                local alpha = (position - first.Time)
                    / (second.Time - first.Time)

                return first.Value:Lerp(second.Value, alpha)
            end
        end

        return points[#points].Value
    end

    --==================================================
    -- PURCHASE SUCCESS GRADIENT
    --==================================================

    local successGradient = ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(3, 5, 8)),
        ColorSequenceKeypoint.new(0.04, Color3.fromRGB(3, 5, 8)),
        ColorSequenceKeypoint.new(0.09, Color3.fromRGB(12, 65, 35)),
        ColorSequenceKeypoint.new(0.17, Color3.fromRGB(35, 155, 83)),
        ColorSequenceKeypoint.new(0.30, Color3.fromRGB(55, 220, 115)),
        ColorSequenceKeypoint.new(0.42, Color3.fromRGB(85, 245, 140)),
        ColorSequenceKeypoint.new(0.50, Color3.fromRGB(125, 255, 165)),
        ColorSequenceKeypoint.new(0.58, Color3.fromRGB(85, 245, 140)),
        ColorSequenceKeypoint.new(0.70, Color3.fromRGB(55, 220, 115)),
        ColorSequenceKeypoint.new(0.83, Color3.fromRGB(35, 155, 83)),
        ColorSequenceKeypoint.new(0.91, Color3.fromRGB(12, 65, 35)),
        ColorSequenceKeypoint.new(0.96, Color3.fromRGB(3, 5, 8)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(3, 5, 8)),
    })

    --==================================================
    -- FAST GREEN GRADIENT WIPE
    --==================================================

    local function animatePurchaseGradient()

        State.gradientWipeToken += 1

        local myToken = State.gradientWipeToken
        local originalGradient = gradientFor(COLORS.Green)
        local startTime = os.clock()
        local duration = 0.12

        task.spawn(function()

            while State.running
                and State.purchaseAnimationActive
                and myToken == State.gradientWipeToken do

                local progress = math.clamp(
                    (os.clock() - startTime) / duration,
                    0,
                    1
                )

                local radius = -0.025 + (progress * 0.445)
                local points = {}

                for i = 0, 18 do
                    local x = i / 18

                    local base = sampleGradient(originalGradient, x)
                    local target = sampleGradient(successGradient, x)
                    local distance = math.abs(x - 0.5)

                    local amount = math.clamp(
                        (radius - distance + 0.025) / 0.05,
                        0,
                        1
                    )

                    amount = amount * amount * (3 - 2 * amount)

                    local finalColor = base:Lerp(target, amount)

                    table.insert(
                        points,
                        ColorSequenceKeypoint.new(x, finalColor)
                    )
                end

                gradient.Color = ColorSequence.new(points)

                if progress >= 1 then
                    gradient.Color = successGradient
                    break
                end

                RunService.RenderStepped:Wait()
            end
        end)
    end

    --==================================================
    -- DYNAMIC ISLAND HEADER FORMATTING
    --==================================================

    local function formatIslandHeader(text)
        local formattedWords = {}

        for word in tostring(text or ""):upper():gmatch("%S+") do
            local letters = {}

            for index = 1, #word do
                table.insert(letters, word:sub(index, index))
            end

            table.insert(formattedWords, table.concat(letters, " "))
        end

        return table.concat(formattedWords, "  ")
    end

    --==================================================
    -- RENDER DYNAMIC ISLAND
    --==================================================

    local function renderDynamicIsland()

        if not State.running or State.purchaseAnimationActive then
            return
        end

islandHeader.Text = formatIslandHeader(getIslandHeader())

        local state = State.currentIslandState
        local kind = state.kind
        local data = state.data or {}

        statusLabel.RichText = true
        statusLabel.Visible = true
        statusLabel.TextTransparency = 0

        local function plain(text, color, size, gradientColor)
            statusLabel.Text = escapeRichText(text)
            statusLabel.TextColor3 = color
            statusLabel.TextSize = size or 15
            gradient.Color = gradientFor(gradientColor or color)
        end

        if kind == "WaitingForTask" then

            local automationActive =
                State.autoBuyEnabled or State.autoClaimEnabled

            local textColor = automationActive and COLORS.Blue or COLORS.Muted
            local gradientColor = automationActive and COLORS.Blue or COLORS.Grey

            islandHeader.Text = "A U T O  T Y C O O N"

            plain("Waiting For Task", textColor, 14, gradientColor)

        elseif kind == "Scanning" then

            plain("Scanning...", COLORS.Blue, 15)

        elseif kind == "Target" then

            local itemName = escapeRichText(data.item or "Unknown")
            local price = "$" .. formatNumber(data.price or 0)

            statusLabel.Text =
                '<font color="#EFF4FA">'
                .. itemName
                .. '</font> <font color="#8994A4">·</font> '
                .. '<font color="'
                .. colorHex(COLORS.Red)
                .. '">'
                .. price
                .. '</font>'

            statusLabel.TextColor3 = COLORS.White
            statusLabel.TextSize = 13
            gradient.Color = gradientFor(COLORS.Red)

        elseif kind == "Buying" then

            local itemName = escapeRichText(data.item or "Unknown")
            local price = "$" .. formatNumber(data.price or 0)

            local priceColor = data.affordable == false
                and COLORS.Red
                or COLORS.Green

            statusLabel.Text =
                '<font color="#EFF4FA">Buying '
                .. itemName
                .. '</font> <font color="#8994A4">·</font> '
                .. '<font color="'
                .. colorHex(priceColor)
                .. '">'
                .. price
                .. '</font>'

            statusLabel.TextColor3 = COLORS.White
            statusLabel.TextSize = 13
            gradient.Color = gradientFor(priceColor)

        elseif kind == "Saving" then

            local itemName = tostring(data.item or "Purchase")

            islandHeader.Text =
                formatIslandHeader("Saving For " .. itemName)

            local remaining = formatCompactNumber(data.remaining or 0)

            statusLabel.Text = "REMAINING: $" .. remaining
            statusLabel.TextColor3 = COLORS.White
            statusLabel.TextSize = 11

            gradient.Color = gradientFor(COLORS.Blue)

        elseif kind == "CannotAfford" then

            local itemName = tostring(data.item or "Purchase")

            islandHeader.Text =
                formatIslandHeader("Cannot Afford " .. itemName)

            plain(
                "Need $" .. formatCompactNumber(data.remaining or 0) .. " more",
                COLORS.Red,
                13,
                COLORS.Red
            )

        elseif kind == "CollectingMoney" then

            islandHeader.Text = formatIslandHeader("Collecting Money")

            plain("Collecting...", COLORS.White, 15, COLORS.Blue)

        elseif kind == "Collected" then

            islandHeader.Text = formatIslandHeader("Money Collected")

            plain(
                "+$" .. formatCompactNumber(data.amount or 0),
                COLORS.Green,
                15,
                COLORS.Blue
            )

        elseif kind == "AllCaughtUp" then

            islandHeader.Text = formatIslandHeader("Collection Complete")

            plain("No Money To Collect", COLORS.CaughtUp, 13)

        elseif kind == "WaitingButtons" then

            plain("Waiting for Buttons...", COLORS.Blue, 13)

        else

            plain(tostring(data.text or "Scanning..."), COLORS.Blue, 14)
        end
    end

    --==================================================
    -- SET ISLAND STATUS
    --==================================================

    function Island.setStatus(kind, data, holdDuration, force)

        if not State.running then
            return
        end

        if not force and os.clock() < State.islandStatusHoldUntil then

            if kind ~= "Buying" and kind ~= "CollectingMoney" then
                return
            end
        end

        State.currentIslandState = {
            kind = kind,
            data = data or {},
        }

        State.islandStatusRevision += 1

        local revision = State.islandStatusRevision

        if force then
            State.islandStatusHoldUntil = 0
        end

        if holdDuration then

            State.islandStatusHoldUntil = os.clock() + holdDuration

            task.delay(holdDuration, function()

                if not State.running then
                    return
                end

                if revision ~= State.islandStatusRevision then
                    return
                end

                if State.currentIslandState.kind ~= kind then
                    return
                end

                Island.setStatus(
                    Island.getIdleIslandStatus(),
                    nil,
                    nil,
                    true
                )
            end)
        end

        renderDynamicIsland()
    end

    --==================================================
    -- PURCHASE SUCCESS ANIMATION
    --==================================================

    function Island.playPurchaseSuccessEffect(
        itemName,
        deductedAmount,
        source
    )

        if not State.running or State.purchaseAnimationActive then
            return
        end

        State.purchaseAnimationActive = true
        State.animationToken += 1

        local myToken = State.animationToken

        State.currentIslandState = {
            kind = Island.getIdleIslandStatus(),
            data = {},
        }

        local safeItem = escapeRichText(itemName)
        local formattedDeduction = "-$" .. formatNumber(deductedAmount)

        successLabel.Text =
            '<font color="#55DC91">Purchased '
            .. safeItem
            .. '</font> <font color="#8994A4">•</font> '
            .. '<font color="#FF535B">'
            .. formattedDeduction
            .. '</font>'

        successLabel.Visible = true
        successLabel.TextTransparency = 1
        successLabel.TextSize = 13

        statusLabel.Visible = false

        animatePurchaseGradient()

        TweenService:Create(
            successLabel,
            TweenInfo.new(
                0.12,
                Enum.EasingStyle.Back,
                Enum.EasingDirection.Out
            ),
            {
                TextTransparency = 0,
                TextSize = 14,
            }
        ):Play()

        local fadeInDuration = 0.12
        local fullyVisibleDuration =
            source == "Individual Buy" and 0.85 or 0.27

        local fadeOutDuration = 0.12

        local fadeOutAt =
            fadeInDuration + fullyVisibleDuration

        local cleanupAt =
            fadeOutAt + fadeOutDuration

        task.delay(fadeOutAt, function()

            if not State.running or myToken ~= State.animationToken then
                return
            end

            TweenService:Create(
                successLabel,
                TweenInfo.new(
                    fadeOutDuration,
                    Enum.EasingStyle.Quad,
                    Enum.EasingDirection.Out
                ),
                {
                    TextTransparency = 1,
                    TextSize = 13,
                }
            ):Play()
        end)

        task.delay(cleanupAt, function()

            if not State.running or myToken ~= State.animationToken then
                return
            end

            State.gradientWipeToken += 1

            successLabel.Visible = false
            successLabel.TextTransparency = 1
            successLabel.TextSize = 13

            statusLabel.Visible = true
            statusLabel.TextTransparency = 0

            State.purchaseAnimationActive = false

            renderDynamicIsland()
        end)
    end

    --==================================================
    -- IDLE ISLAND MODE
    --==================================================

    function Island.refreshMode()

        State.islandStatusHoldUntil = 0

        Island.setStatus(
            Island.getIdleIslandStatus(),
            nil,
            nil,
            true
        )
    end

    --==================================================
    -- HOVER EFFECT
    --==================================================

    local hoverTween

    local function setIslandHover(isHovering)

        if not State.running then
            return
        end

        if hoverTween then
            hoverTween:Cancel()
        end

        hoverTween = TweenService:Create(
            visualScale,
            TweenInfo.new(
                0.20,
                Enum.EasingStyle.Quart,
                Enum.EasingDirection.Out
            ),
            {
                Scale = isHovering and 0.86 or 1,
            }
        )

        hoverTween:Play()
        Island.resources.hoverTween = hoverTween
    end

    trackConnection(hitbox.MouseEnter:Connect(function()
        setIslandHover(true)
    end))

    trackConnection(hitbox.MouseLeave:Connect(function()
        setIslandHover(false)
    end))

    --==================================================
    -- ISLAND CLICK EFFECT
    --==================================================

    local islandClickTweens = {}
    local islandClickSequence = 0

    local function playIslandClickEffect()

        if not State.running or State.purchaseAnimationActive then
            return
        end

        islandClickSequence += 1

        local sequence = islandClickSequence

        for _, tweenObject in ipairs(islandClickTweens) do
            pcall(function()
                tweenObject:Cancel()
            end)
        end

        table.clear(islandClickTweens)

        gradient.Offset = Vector2.new(-0.65, 0)
        borderStroke.Transparency = 0.88

        local shimmer = TweenService:Create(
            gradient,
            TweenInfo.new(
                0.40,
                Enum.EasingStyle.Quad,
                Enum.EasingDirection.Out
            ),
            {
                Offset = Vector2.new(0.65, 0),
            }
        )

        local glow = TweenService:Create(
            borderStroke,
            TweenInfo.new(
                0.30,
                Enum.EasingStyle.Quad,
                Enum.EasingDirection.Out
            ),
            {
                Transparency = 0.40,
            }
        )

        table.insert(islandClickTweens, shimmer)
        table.insert(islandClickTweens, glow)

        shimmer:Play()
        glow:Play()

        task.spawn(function()

            shimmer.Completed:Wait()

            if not State.running or sequence ~= islandClickSequence then
                return
            end

            local settle = TweenService:Create(
                gradient,
                TweenInfo.new(
                    0.35,
                    Enum.EasingStyle.Sine,
                    Enum.EasingDirection.Out
                ),
                {
                    Offset = Vector2.new(0, 0),
                }
            )

            local restoreGlow = TweenService:Create(
                borderStroke,
                TweenInfo.new(
                    0.45,
                    Enum.EasingStyle.Sine,
                    Enum.EasingDirection.Out
                ),
                {
                    Transparency = 0.88,
                }
            )

            table.insert(islandClickTweens, settle)
            table.insert(islandClickTweens, restoreGlow)

            settle:Play()
            restoreGlow:Play()
        end)
    end

    --==================================================
    -- DRAGGING
    --==================================================

    local draggingIsland = false
    local islandDragMoved = false
    local islandDragStart = nil
    local islandStartPosition = nil
    local islandDragType = nil

    trackConnection(hitbox.InputBegan:Connect(function(input)

        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            draggingIsland = true
            islandDragMoved = false
            islandDragStart = input.Position
            islandStartPosition = hitbox.Position
            islandDragType = input.UserInputType
        end
    end))

    trackConnection(UserInputService.InputChanged:Connect(function(input)

        if not draggingIsland then
            return
        end

        local isMouseMove =
            islandDragType == Enum.UserInputType.MouseButton1
            and input.UserInputType == Enum.UserInputType.MouseMovement

        local isTouchMove =
            islandDragType == Enum.UserInputType.Touch
            and input.UserInputType == Enum.UserInputType.Touch

        if isMouseMove or isTouchMove then

            local delta = input.Position - islandDragStart

            if delta.Magnitude > 5 then
                islandDragMoved = true
            end

            if islandDragMoved then

                hitbox.Position = UDim2.new(
                    islandStartPosition.X.Scale,
                    islandStartPosition.X.Offset + delta.X,
                    islandStartPosition.Y.Scale,
                    islandStartPosition.Y.Offset + delta.Y
                )
            end
        end
    end))

    trackConnection(UserInputService.InputEnded:Connect(function(input)

        if not draggingIsland then
            return
        end

        local endedMouse =
            islandDragType == Enum.UserInputType.MouseButton1
            and input.UserInputType == Enum.UserInputType.MouseButton1

        local endedTouch =
            islandDragType == Enum.UserInputType.Touch
            and input.UserInputType == Enum.UserInputType.Touch

        if endedMouse or endedTouch then

            local wasClick = not islandDragMoved

            draggingIsland = false
            islandDragMoved = false
            islandDragType = nil

            if wasClick then
                playIslandClickEffect()
            end
        end
    end))

    --==================================================
    -- VISIBILITY
    --==================================================

    function Island.setVisible(enabled)

        State.showDynamicIsland = enabled == true
        islandGui.Enabled = State.showDynamicIsland
    end

    --==================================================
    -- RESOURCE REFERENCES
    --==================================================

    Island.resources = {
        islandGui = islandGui,
        rotationTween = rotationTween,
        hoverTween = nil,
        islandClickTweens = islandClickTweens,
    }

    Island.gui = islandGui

    return Island
end
