-- // UI LIBRARY
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Random theme selection
local themes = {"Default", "Ocean", "AmberGlow", "Light", "Amethyst", "Green", "Bloom", "DarkBlue", "Serenity"}
local randomIndex = math.random(1, #themes)
local randomTheme = themes[randomIndex]

-- Create the Window with KeySystem enabled
local Window = Rayfield:CreateWindow({
    Name = "6RB Utility Script",
    LoadingTitle = "Utility Hub",
    LoadingSubtitle = "by 6RB",
    ConfigurationSaving = {
        Enabled = false
    },
    Discord = {
        Enabled = false
    },
    KeySystem = true,
    KeySettings = {
        Title = "6RB Utility Key",
        Subtitle = "Enter the key to unlock the script",
        Note = "Key: BYXVALLYPRISON2025_V2",
        Key = "BYXVALLYPRISON2025_V2",
        SaveKey = false,
        WrongKeyMessage = "Incorrect key! Please try again.",
        CorrectKeyMessage = "Script unlocked successfully!"
    },
    Theme = randomTheme
})

-- Verify KeySystem
if not Window then
    warn("KeySystem failed to initialize. Please enter the key: BYXVALLYPRISON2025_V2")
    return
else
    print("KeySystem validated successfully!")
end

-- // INFO TAB
local InfoTab = Window:CreateTab("Info", 4483362458)

InfoTab:CreateButton({
    Name = "Copy Discord Link",
    Callback = function()
        local link = "https://discord.gg/6RBHub"
        if setclipboard then
            setclipboard(link)
            Rayfield:Notify({
                Title = "Link Copied!",
                Content = "The Discord link has been copied to your clipboard.",
                Duration = 3,
                Image = 4483362458
            })
        else
            Rayfield:Notify({
                Title = "Error",
                Content = "Your executor does not support clipboard copying. Link: " .. link,
                Duration = 5,
                Image = 4483362458
            })
        end
    end
})

-- // ESP SECTION
local ESPTab = Window:CreateTab("ESP", 4483362458)

local ESPEnabled = false
local ShowHealth = false
local ESPObjects = {}
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

function CreateESP(player)
    if player == Players.LocalPlayer then return end
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") or not player.Character:FindFirstChild("Humanoid") then return end
    if not ESPObjects[player] then
        local espHolder = {}
        
        local highlight = Instance.new("Highlight")
        highlight.Parent = player.Character
        highlight.Adornee = player.Character
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.FillTransparency = 0.3
        highlight.OutlineTransparency = 1
        if player.Team and player.Team.TeamColor then
            highlight.FillColor = player.Team.TeamColor.Color
        else
            highlight.FillColor = Color3.fromRGB(255, 255, 255)
        end
        espHolder.Highlight = highlight

        local billboard = Instance.new("BillboardGui")
        billboard.Name = "ESP_Billboard"
        billboard.Parent = player.Character
        billboard.Adornee = player.Character:FindFirstChild("Head")
        billboard.Size = UDim2.new(0, 100, 0, 25)
        billboard.StudsOffset = Vector3.new(0, 2, 0)
        billboard.AlwaysOnTop = true
        billboard.Enabled = ESPEnabled

        local healthFrame = Instance.new("Frame")
        healthFrame.Name = "HealthBar"
        healthFrame.Parent = billboard
        healthFrame.Size = UDim2.new(0, 100, 0, 8)
        healthFrame.Position = UDim2.new(0, 0, 0, 0)
        healthFrame.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        healthFrame.BackgroundTransparency = 0.2
        healthFrame.BorderSizePixel = 1
        healthFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
        healthFrame.Visible = ShowHealth and ESPEnabled

        local healthBg = Instance.new("Frame")
        healthBg.Name = "HealthBarBg"
        healthBg.Parent = healthFrame
        healthBg.Size = UDim2.new(1, 0, 1, 0)
        healthBg.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        healthBg.BackgroundTransparency = 0.7
        healthBg.BorderSizePixel = 0
        healthBg.ZIndex = healthFrame.ZIndex - 1

        local healthText = Instance.new("TextLabel")
        healthText.Name = "HealthText"
        healthText.Parent = billboard
        healthText.Size = UDim2.new(0, 100, 0, 15)
        healthText.Position = UDim2.new(0, 0, 0, 10)
        healthText.BackgroundTransparency = 1
        healthText.TextColor3 = Color3.fromRGB(255, 255, 255)
        healthText.TextSize = 12
        healthText.Font = Enum.Font.SourceSansBold
        healthText.Text = "HP: N/A"
        healthText.Visible = ShowHealth and ESPEnabled

        local humanoid = player.Character:FindFirstChild("Humanoid")
        if humanoid then
            local function updateHealth()
                if not player.Character or not player.Character:FindFirstChild("Humanoid") or not healthFrame.Visible then
                    healthText.Text = "HP: N/A"
                    healthFrame.Size = UDim2.new(0, 100, 0, 8)
                    return
                end
                local currentHumanoid = player.Character:FindFirstChild("Humanoid")
                if currentHumanoid then
                    local healthPercent = currentHumanoid.Health / currentHumanoid.MaxHealth
                    healthFrame.Size = UDim2.new(0, 100 * healthPercent, 0, 8)
                    healthFrame.BackgroundColor3 = Color3.fromRGB(255 * (1 - healthPercent), 150 * healthPercent, 0)
                    healthText.Text = "HP: " .. math.floor(currentHumanoid.Health) .. "/" .. math.floor(currentHumanoid.MaxHealth)
                else
                    healthText.Text = "HP: N/A"
                    healthFrame.Size = UDim2.new(0, 100, 0, 8)
                end
            end
            updateHealth()
            humanoid:GetPropertyChangedSignal("Health"):Connect(updateHealth)
            humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(updateHealth)
        end

        espHolder.Billboard = billboard
        ESPObjects[player] = espHolder
    end
end

function RemoveESP(player)
    if ESPObjects[player] then
        if ESPObjects[player].Highlight then
            ESPObjects[player].Highlight:Destroy()
        end
        if ESPObjects[player].Billboard then
            ESPObjects[player].Billboard:Destroy()
        end
        ESPObjects[player] = nil
    end
end

for _, player in pairs(Players:GetPlayers()) do
    if player ~= Players.LocalPlayer then
        player.CharacterAdded:Connect(function()
            if ESPEnabled then
                task.wait(0.5)
                CreateESP(player)
            end
        end)
        if player.Character and ESPEnabled then
            task.spawn(function()
                task.wait(0.5)
                CreateESP(player)
            end)
        end
    end
end

Players.PlayerAdded:Connect(function(player)
    if player ~= Players.LocalPlayer then
        player.CharacterAdded:Connect(function()
            if ESPEnabled then
                task.wait(0.5)
                CreateESP(player)
            end
        end)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    RemoveESP(player)
end)

RunService.Heartbeat:Connect(function()
    if ESPEnabled then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= Players.LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") then
                task.spawn(function()
                    CreateESP(player)
                end)
            end
        end
    end
end)

local espToggle = ESPTab:CreateToggle({
    Name = "Enable ESP",
    CurrentValue = false,
    Flag = "ESP_TOGGLE",
    Callback = function(Value)
        ESPEnabled = Value
        if ESPEnabled then
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= Players.LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") then
                    task.spawn(function()
                        CreateESP(player)
                    end)
                end
            end
        else
            for _, espHolder in pairs(ESPObjects) do
                if espHolder.Highlight then
                    espHolder.Highlight:Destroy()
                end
                if espHolder.Billboard then
                    espHolder.Billboard:Destroy()
                end
            end
            ESPObjects = {}
        end
    end
})

local healthToggle = ESPTab:CreateToggle({
    Name = "Show Health Bar",
    CurrentValue = false,
    Flag = "SHOW_HEALTH",
    Callback = function(Value)
        ShowHealth = Value
        for _, player in pairs(Players:GetPlayers()) do
            if ESPObjects[player] and ESPObjects[player].Billboard then
                ESPObjects[player].Billboard.HealthBar.Visible = ShowHealth and ESPEnabled
                ESPObjects[player].Billboard.HealthText.Visible = ShowHealth and ESPEnabled
                if ESPObjects[player].Billboard.HealthText.Visible then
                    local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
                    if humanoid then
                        ESPObjects[player].Billboard.HealthText.Text = "HP: " .. math.floor(humanoid.Health) .. "/" .. math.floor(humanoid.MaxHealth)
                    else
                        ESPObjects[player].Billboard.HealthText.Text = "HP: N/A"
                    end
                end
            end
        end
    end
})

-- // AIMBOT SECTION
local AimbotTab = Window:CreateTab("Aimbot", 4483362458)

local AimbotEnabled = false
local FOVRadius = 150
local Smoothness = 0.15
local StickToTarget = false
local IgnoreWalls = false
local TeamCheck = false
local ShowFOVCircle = true
local CurrentTarget = nil
local TargetPart = "Head"
local FOVCircle = nil
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local function CreateFOVCircle()
    if FOVCircle then
        FOVCircle:Remove()
        FOVCircle = nil
    end
    task.wait(0.05)
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    FOVCircle.Radius = FOVRadius
    FOVCircle.Color = Color3.fromRGB(255, 0, 0)
    FOVCircle.Thickness = 2
    FOVCircle.Filled = false
    FOVCircle.Visible = AimbotEnabled and ShowFOVCircle
    print("FOV Circle created with fixed red color")
end

local function UpdateFOVCircle()
    if not FOVCircle then
        CreateFOVCircle()
        return
    end
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    FOVCircle.Radius = FOVRadius
    FOVCircle.Visible = AimbotEnabled and ShowFOVCircle
    print("FOV Circle updated")
end

local function IsVisible(target)
    if IgnoreWalls then return true end
    if not target or not target.Character or not target.Character:FindFirstChild(TargetPart) then return false end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character}
    local ray = workspace:Raycast(Camera.CFrame.Position, (target.Character[TargetPart].Position - Camera.CFrame.Position).Unit * 1000, params)
    return ray and ray.Instance and ray.Instance:IsDescendantOf(target.Character)
end

local function IsValidTarget(player)
    if player == LocalPlayer then return false end
    if TeamCheck and LocalPlayer.Team and player.Team and player.Team == LocalPlayer.Team then return false end
    if not player.Character or not player.Character:FindFirstChild(TargetPart) or not player.Character:FindFirstChild("Humanoid") then return false end
    return IsVisible(player)
end

local function GetClosestPlayerInFOV()
    local closestPlayer = nil
    local shortestDistance = FOVRadius
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in pairs(Players:GetPlayers()) do
        if IsValidTarget(player) then
            local targetPos = player.Character[TargetPart].Position
            local screenPos, onScreen = Camera:WorldToViewportPoint(targetPos)
            if onScreen then
                local screenPoint = Vector2.new(screenPos.X, screenPos.Y)
                local distance = (screenPoint - center).Magnitude
                if distance < shortestDistance then
                    closestPlayer = player
                    shortestDistance = distance
                end
            end
        end
    end
    return closestPlayer
end

local function IsInFOV(target)
    if not target or not target.Character or not target.Character:FindFirstChild(TargetPart) then return false end
    local targetPos = target.Character[TargetPart].Position
    local screenPos, onScreen = Camera:WorldToViewportPoint(targetPos)
    if onScreen then
        local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        local screenPoint = Vector2.new(screenPos.X, screenPos.Y)
        local distance = (screenPoint - center).Magnitude
        return distance < FOVRadius
    end
    return false
end

local aimbotToggle = AimbotTab:CreateToggle({
    Name = "Enable Aimbot",
    CurrentValue = false,
    Flag = "AIMBOT_TOGGLE",
    Callback = function(Value)
        AimbotEnabled = Value
        CurrentTarget = nil
        CreateFOVCircle()
        if AimbotEnabled then
            local connection
            connection = RunService.RenderStepped:Connect(function()
                UpdateFOVCircle()
                if AimbotEnabled then
                    if StickToTarget and CurrentTarget and IsInFOV(CurrentTarget) and IsValidTarget(CurrentTarget) then
                    else
                        CurrentTarget = GetClosestPlayerInFOV()
                    end
                    if CurrentTarget and CurrentTarget.Character and CurrentTarget.Character:FindFirstChild(TargetPart) then
                        local targetPos = CurrentTarget.Character[TargetPart].Position
                        local currentCFrame = Camera.CFrame
                        local targetCFrame = CFrame.new(currentCFrame.Position, targetPos)
                        Camera.CFrame = currentCFrame:Lerp(targetCFrame, Smoothness)
                    end
                else
                    connection:Disconnect()
                end
            end)
        else
            if FOVCircle then
                FOVCircle:Remove()
                FOVCircle = nil
            end
        end
    end
})

local radiusSlider = AimbotTab:CreateSlider({
    Name = "FOV Radius",
    Range = {50, 500},
    Increment = 10,
    CurrentValue = 150,
    Flag = "FOV_RADIUS",
    Callback = function(Value)
        FOVRadius = Value
        UpdateFOVCircle()
    end
})

local smoothnessSlider = AimbotTab:CreateSlider({
    Name = "Smoothness",
    Range = {0.05, 0.5},
    Increment = 0.01,
    CurrentValue = 0.15,
    Flag = "AIMBOT_SMOOTHNESS",
    Callback = function(Value)
        Smoothness = Value
    end
})

local stickToggle = AimbotTab:CreateToggle({
    Name = "Stick to Target",
    CurrentValue = false,
    Flag = "STICK_TARGET",
    Callback = function(Value)
        StickToTarget = Value
        if not StickToTarget then
            CurrentTarget = nil
        end
    end
})

local ignoreWallsToggle = AimbotTab:CreateToggle({
    Name = "Ignore Walls",
    CurrentValue = false,
    Flag = "IGNORE_WALLS",
    Callback = function(Value)
        IgnoreWalls = Value
    end
})

local teamCheckToggle = AimbotTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = false,
    Flag = "TEAM_CHECK",
    Callback = function(Value)
        TeamCheck = Value
        CurrentTarget = nil
    end
})

local showFOVToggle = AimbotTab:CreateToggle({
    Name = "Show FOV Circle",
    CurrentValue = true,
    Flag = "SHOW_FOV_CIRCLE",
    Callback = function(Value)
        ShowFOVCircle = Value
        UpdateFOVCircle()
    end
})

-- // FOV SECTION
local FOVTab = Window:CreateTab("FOV", 4483362458)

local FOVEnabled = false
local DefaultFOV = 70
local CustomFOV = 90
local Camera = workspace.CurrentCamera

local function UpdateFOV()
    if FOVEnabled then
        Camera.FieldOfView = CustomFOV
    else
        Camera.FieldOfView = DefaultFOV
    end
end

local fovToggle = FOVTab:CreateToggle({
    Name = "Enable Custom FOV",
    CurrentValue = false,
    Flag = "FOV_TOGGLE",
    Callback = function(Value)
        FOVEnabled = Value
        UpdateFOV()
        print(FOVEnabled and "Custom FOV enabled!" or "Custom FOV disabled!")
    end
})

local fovSlider = FOVTab:CreateSlider({
    Name = "FOV Value",
    Range = {30, 200},
    Increment = 1,
    CurrentValue = 90,
    Flag = "FOV_SLIDER",
    Callback = function(Value)
        CustomFOV = Value
        if FOVEnabled then
            Camera.FieldOfView = CustomFOV
        end
        print("FOV set to: " .. CustomFOV)
    end
})

-- // TELEPORT SECTION
local TeleportTab = Window:CreateTab("Teleports", 4483362458)

local locations = {
    ["ورشه"] = CFrame.new(172.34, 23.10, -143.87),
    ["المراقبه"] = CFrame.new(224.47, 23.10, -167.90),
    ["القارد co"] = CFrame.new(137.60, 23.10, -169.93),
    ["الروت لوكرز الفباي"] = CFrame.new(165.63, 23.10, -192.25),
    ["الدخله"] = CFrame.new(76.96, -7.02, -19.21),
    ["الماكس"] = CFrame.new(101.84, -8.82, -141.41),
    ["الماطور"] = CFrame.new(100.95, -8.82, -57.59),
    ["برا"] = CFrame.new(350.22, 5.40, -171.09),
    ["المنجم"] = CFrame.new(749.02, -0.97, -470.45)
}

for name, cf in pairs(locations) do
    TeleportTab:CreateButton({
        Name = name,
        Callback = function()
            game.Players.LocalPlayer.Character:PivotTo(cf)
        end
    })
end

TeleportTab:CreateButton({
    Name = "Escapee",
    Callback = function()
        game.Players.LocalPlayer.Character:PivotTo(CFrame.new(307.06, 5.40, -177.88))
    end
})

-- Adding back the Keycard button
TeleportTab:CreateButton({
    Name = "Keycard (💳)",
    Callback = function()
        game.Players.LocalPlayer.Character:PivotTo(CFrame.new(165.63, 23.10, -192.25)) -- Location linked to "الروت لوكرز الفباي"
    end
})

-- // ITEMS SECTION
local ItemsTab = Window:CreateTab("Items", 4483362458)

ItemsTab:CreateButton({
    Name = "Auto Get & Equip Keycard",
    Callback = function()
        local player = game.Players.LocalPlayer
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            Rayfield:Notify({
                Title = "Error",
                Content = "Cannot find your character!",
                Duration = 3,
                Image = 4483362458
            })
            return
        end

        local prisonerTeams = {"Minimum Security", "Medium Security", "Maximum Security"}
        local isPrisoner = false
        if player.Team and table.find(prisonerTeams, player.Team.Name) then
            isPrisoner = true
        end
        if not isPrisoner then
            Rayfield:Notify({
                Title = "Access Denied",
                Content = "Only prisoners can take this item!",
                Duration = 3,
                Image = 4483362458
            })
            return
        end

        local maxAttempts = 3
        local attempt = 1

        local function tryGetKeycard()
            local foundItem = nil
            local function searchInContainer(container)
                for _, obj in pairs(container:GetDescendants()) do
                    if obj:IsA("Tool") and obj.Name:lower():find("keycard") then
                        foundItem = obj
                        return
                    end
                end
            end
            searchInContainer(workspace)
            if not foundItem then searchInContainer(game:GetService("ReplicatedStorage")) end
            if not foundItem then searchInContainer(game:GetService("ServerStorage")) end

            if foundItem then
                if foundItem:FindFirstChild("Handle") then
                    local clonedTool = foundItem:Clone()
                    clonedTool.Parent = player.Backpack
                    local humanoid = player.Character:FindFirstChild("Humanoid")
                    if humanoid then
                        humanoid:EquipTool(clonedTool)
                        Rayfield:Notify({
                            Title = "Success",
                            Content = "Keycard added to Backpack and equipped!",
                            Duration = 3,
                            Image = 4483362458
                        })
                    else
                        Rayfield:Notify({
                            Title = "Warning",
                            Content = "Keycard added to Backpack, but equipping failed. Check your character.",
                            Duration = 5,
                            Image = 4483362458
                        })
                    end
                else
                    Rayfield:Notify({
                        Title = "Warning",
                        Content = "Keycard is non-functional. Try teleporting to interact.",
                        Duration = 5,
                        Image = 4483362458
                    })
                end
            elseif attempt < maxAttempts then
                attempt = attempt + 1
                task.wait(0.5)
                tryGetKeycard()
            else
                Rayfield:Notify({
                    Title = "Error",
                    Content = "Try again later or teleport to a keycard location.",
                    Duration = 5,
                    Image = 4483362458
                })
                print("Keycard not found after " .. maxAttempts .. " attempts in workspace, ReplicatedStorage, or ServerStorage.")
            end
        end

        tryGetKeycard()
    end
})

-- // STAMINA SECTION
local StaminaTab = Window:CreateTab("Stamina", 4483362458)

local RunService = game:GetService("RunService")
local LocalPlayer = game.Players.LocalPlayer
local infiniteStaminaEnabled = false

-- Button to toggle Infinite Stamina
StaminaTab:CreateButton({
    Name = "Toggle Infinite Stamina",
    Callback = function()
        infiniteStaminaEnabled = not infiniteStaminaEnabled
        local player = game.Players.LocalPlayer
        local serverVariables = player:FindFirstChild("ServerVariables")
        if serverVariables and serverVariables:FindFirstChild("Sprint") then
            local sprint = serverVariables.Sprint
            local stamina = sprint:FindFirstChild("Stamina")
            local maxStamina = sprint:FindFirstChild("MaxStamina")
            if stamina and maxStamina then
                if infiniteStaminaEnabled then
                    local connection = RunService.RenderStepped:Connect(function()
                        if infiniteStaminaEnabled then
                            stamina.Value = maxStamina.Value
                        else
                            connection:Disconnect()
                        end
                    end)
                    Rayfield:Notify({
                        Title = "Success",
                        Content = "Infinite Stamina enabled!",
                        Duration = 5,
                        Image = 4483362458
                    })
                else
                    Rayfield:Notify({
                        Title = "Info",
                        Content = "Infinite Stamina disabled!",
                        Duration = 5,
                        Image = 4483362458
                    })
                end
            else
                print("Stamina or MaxStamina not found to toggle infinite stamina.")
                Rayfield:Notify({
                    Title = "Error",
                    Content = "Stamina or MaxStamina not found. Check your character setup.",
                    Duration = 5,
                    Image = 4483362458
                })
                infiniteStaminaEnabled = false
            end
        else
            print("No ServerVariables or Sprint found to toggle infinite stamina.")
            Rayfield:Notify({
                Title = "Error",
                Content = "No ServerVariables or Sprint detected. Check your character setup.",
                Duration = 5,
                Image = 4483362458
            })
            infiniteStaminaEnabled = false
        end
    end
})

print("✅ Script loaded successfully!")
