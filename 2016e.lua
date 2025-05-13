-- Load external scriptsw
loadstring(game:HttpGet("https://pastebin.com/raw/xDXkjWKk",true))()
loadstring(game:HttpGet("https://pastebin.com/raw/XuVPGayq",true))()

-- Function to handle character setup for any player
local function onCharacterAdded(character)
    local parent = character
    local function waitForChild(parent, childName)
        local child = parent:FindFirstChild(childName)
        if child then
            return child
        end
        return parent:WaitForChild(childName)
    end

    local humanoid = waitForChild(character, "Humanoid")
    local head = waitForChild(character, "HumanoidRootPart")
    -- Wait for sounds to be present
    local gettingUpSound = waitForChild(head, "GettingUp")
    local diedSound = waitForChild(head, "Died")
    local freeFallingSound = waitForChild(head, "FreeFalling")
    local jumpingSound = waitForChild(head, "Jumping")
    local landingSound = waitForChild(head, "Landing")
    local splashSound = waitForChild(head, "Splash")
    local runningSound = waitForChild(head, "Running")
    local swimmingSound = waitForChild(head, "Swimming")
    local climbingSound = waitForChild(head, "Climbing")

    -- Set looping and volume
    runningSound.Looped = true
    runningSound.Volume = 2
    swimmingSound.Looped = true

    -- State variables
    local currentState = "None"
    local fallVelocity = 0
    local fallCount = 0

    -- Functions to control sounds
    local function stopLoopedSounds()
        runningSound:Stop()
        climbingSound:Stop()
        swimmingSound:Stop()
    end

    local function onDied()
        stopLoopedSounds()
        diedSound:Play()
    end

    local function onStateFall(isFalling, sound)
        fallCount += 1
        if isFalling then
            sound.Volume = 0
            sound:Play()
            task.spawn(function()
                local currentFallCount = fallCount
                local timer = 0
                while timer < 1.5 and fallCount == currentFallCount do
                    local volume = math.max(timer - 0.3, 0)
                    sound.Volume = volume
                    task.wait(0.1)
                    timer += 0.1
                end
            end)
        else
            sound:Stop()
        end
        local previousVelocity = fallVelocity
        local currentVelocity = math.abs(head.Velocity.Y)
        fallVelocity = math.max(previousVelocity, currentVelocity)
    end

    local function onStateNoStop(shouldPlay, sound)
        if shouldPlay then
            sound:Play()
        end
    end

    local function onRunning(speed)
        climbingSound:Stop()
        swimmingSound:Stop()
        if currentState == "FreeFall" and fallVelocity > 0.1 then
            local volume = math.clamp((fallVelocity - 50) / 110, 0, 1)
            landingSound.Volume = volume
            landingSound:Play()
            fallVelocity = 0
        end
        if speed > 0.1 then
            runningSound:Play()
            runningSound.Pitch = speed / 8
        else
            runningSound:Stop()
        end
        currentState = "Run"
    end

    local function onSwimming(speed)
        if currentState ~= "Swim" and speed > 0.1 then
            local volume = math.clamp(speed / 350, 0, 1)
            splashSound.Volume = volume
            splashSound:Play()
            currentState = "Swim"
        end
        climbingSound:Stop()
        runningSound:Stop()
        swimmingSound.Pitch = 1.6
        swimmingSound:Play()
    end

    local function onClimbing(speed)
        runningSound:Stop()
        swimmingSound:Stop()
        if speed > 0.01 then
            climbingSound:Play()
            climbingSound.Pitch = speed / 5.5
        else
            climbingSound:Stop()
        end
        currentState = "Climb"
    end

    -- Connect humanoid events
    humanoid.Died:Connect(onDied)
    humanoid.Running:Connect(onRunning)
    humanoid.Swimming:Connect(onSwimming)
    humanoid.Climbing:Connect(onClimbing)
    humanoid.Jumping:Connect(function(isJumping)
        onStateNoStop(isJumping, jumpingSound)
        currentState = "Jump"
    end)
    humanoid.GettingUp:Connect(function(isGettingUp)
        stopLoopedSounds()
        onStateNoStop(isGettingUp, gettingUpSound)
        currentState = "GetUp"
    end)
    humanoid.FreeFalling:Connect(function(isFreeFalling)
        stopLoopedSounds()
        onStateFall(isFreeFalling, freeFallingSound)
        currentState = "FreeFall"
    end)
    humanoid.FallingDown:Connect(stopLoopedSounds)
    humanoid.StateChanged:Connect(function(_, newState)
        local name = newState.Name
        if name ~= "Dead" and name ~= "Running" and name ~= "RunningNoPhysics" and name ~= "Swimming" and name ~= "Jumping" and name ~= "GettingUp" and name ~= "Freefall" and name ~= "FallingDown" then
            stopLoopedSounds()
        end
    end)
end

-- Apply to existing players
for _, player in pairs(game.Players:GetPlayers()) do
    if player.Character then
        onCharacterAdded(player.Character)
    end
    -- Listen for new characters
    player.CharacterAdded:Connect(onCharacterAdded)
end

-- Listen for players joining later
game.Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(onCharacterAdded)
end)
