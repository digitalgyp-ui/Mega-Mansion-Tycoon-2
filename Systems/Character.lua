
--==================================================
-- AUTO TYCOON V1.4 ALPHA
-- SYSTEMS: CHARACTER
--==================================================

return function(State, Helpers, LocalPlayer, UserInputService)

    local Character = {}

    -- CHARACTER HELPERS

    function Character.getCharacter()
        return LocalPlayer.Character
            or LocalPlayer.CharacterAdded:Wait()
    end

    function Character.getHumanoid()
        local character = Character.getCharacter()

        return character:FindFirstChildOfClass("Humanoid")
            or character:WaitForChild("Humanoid", 5)
    end

    function Character.getRootPart()
        local character = Character.getCharacter()

        return character:FindFirstChild("HumanoidRootPart")
            or character:WaitForChild("HumanoidRootPart", 5)
    end

    function Character.captureMovementDefaults(humanoid)
        if not humanoid then
            return
        end

        State.movementDefaults = {
            WalkSpeed = humanoid.WalkSpeed,
            JumpHeight = humanoid.JumpHeight,
            JumpPower = humanoid.JumpPower,
            UseJumpPower = humanoid.UseJumpPower,
        }
    end

    -- INITIAL CHARACTER

    local initialCharacter = LocalPlayer.Character
    local initialHumanoid = initialCharacter
        and initialCharacter:FindFirstChildOfClass("Humanoid")

    if initialHumanoid then
        Character.captureMovementDefaults(initialHumanoid)
    else
        task.spawn(function()
            local humanoid = Character.getHumanoid()

            if humanoid then
                Character.captureMovementDefaults(humanoid)
            end
        end)
    end

    -- CHARACTER CONTROLS

    function Character.createControls(MiscTab, logActivity)

        MiscTab:CreateSection({
            name = "Character",
        })

        local walkSpeedSlider
        local jumpHeightSlider

        walkSpeedSlider = MiscTab:CreateSlider({
            name = "WalkSpeed",
            range = { 0, 100 },
            increment = 1,
            value = 16,
            suffix = "",
            flag = "V125_WalkSpeed",

            callback = function(value)
                State.walkSpeedValue = value

                local humanoid = Character.getHumanoid()

                if humanoid then
                    humanoid.WalkSpeed = value
                end
            end,
        })

        jumpHeightSlider = MiscTab:CreateSlider({
            name = "JumpHeight",
            range = { 0, 50 },
            increment = 0.1,
            value = 7.2,
            suffix = "",
            flag = "V125_JumpHeight",

            callback = function(value)
                State.jumpHeightValue = value

                local humanoid = Character.getHumanoid()

                if humanoid then
                    humanoid.JumpHeight = value
                end
            end,
        })

        MiscTab:CreateButton({
            name = "Reset WalkSpeed",

            callback = function()
                local defaultSpeed =
                    tonumber(State.movementDefaults.WalkSpeed) or 16

                State.walkSpeedValue = defaultSpeed

                local humanoid = Character.getHumanoid()

                if humanoid then
                    humanoid.WalkSpeed = defaultSpeed
                end

                pcall(function()
                    walkSpeedSlider:Set(defaultSpeed)
                end)

                logActivity(
                    "WalkSpeed reset to the character's original value (" ..
                    tostring(defaultSpeed) .. ")."
                )
            end,
        })

        MiscTab:CreateButton({
            name = "Reset JumpPower",
            description = "Restores both JumpPower and JumpHeight to the character's original values.",

            callback = function()
                local defaultJumpHeight =
                    tonumber(State.movementDefaults.JumpHeight) or 7.2

                local defaultJumpPower =
                    tonumber(State.movementDefaults.JumpPower) or 50

                State.jumpHeightValue = defaultJumpHeight

                local humanoid = Character.getHumanoid()

                if humanoid then
                    humanoid.JumpHeight = defaultJumpHeight
                    humanoid.JumpPower = defaultJumpPower
                end

                pcall(function()
                    jumpHeightSlider:Set(defaultJumpHeight)
                end)

                logActivity(
                    "JumpPower and JumpHeight reset to the character's original values."
                )
            end,
        })

        MiscTab:CreateToggle({
            name = "Infinite Jump",
            value = false,
            flag = "V125_InfiniteJump",

            callback = function(value)
                State.infiniteJumpEnabled = value

                logActivity(
                    "Infinite Jump " ..
                    (value and "enabled." or "disabled.")
                )
            end,
        })
    end

    -- CHARACTER EVENTS

    function Character.start()

        Helpers.trackConnection(
            UserInputService.JumpRequest:Connect(function()
                if not State.running
                    or not State.infiniteJumpEnabled then
                    return
                end

                local humanoid = Character.getHumanoid()

                if humanoid then
                    humanoid:ChangeState(
                        Enum.HumanoidStateType.Jumping
                    )
                end
            end)
        )

        Helpers.trackConnection(
            LocalPlayer.CharacterAdded:Connect(function(character)

                State.autoClaimParkedAtMailbox = false
                State.autoClaimMailboxCFrame = nil

                task.wait(0.4)

                local humanoid =
                    character:FindFirstChildOfClass("Humanoid")

                if humanoid then
                    Character.captureMovementDefaults(humanoid)

                    humanoid.WalkSpeed = State.walkSpeedValue
                    humanoid.JumpHeight = State.jumpHeightValue
                end
            end)
        )
    end

    return Character
end
