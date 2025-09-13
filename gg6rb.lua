-- // UI LIBRARY
local success, Rayfield = pcall(function() return loadstring(game:HttpGet('https://sirius.menu/rayfield'))() end)
if not success then
    warn("Failed to load Rayfield! Check internet or executor.")
    return
end
print("Rayfield loaded successfully!")

-- Random theme selection
local themes = {"Ocean", "Amethyst", "DarkBlue"}
local randomIndex = math.random(1, #themes)
local randomTheme = themes[randomIndex]

-- Create the Window with KeySystem enabled
local Window = Rayfield:CreateWindow({
    Name = "Valley Prison ByX v2!",
    LoadingTitle = ".",
    LoadingSubtitle = "ByX",
    ConfigurationSaving = { Enabled = false },
    Discord = { Enabled = false },
    KeySystem = true,
    KeySettings = {
        Title = "Valley Prison ByX V2",
        Subtitle = "Enter the key to unlock the script",
        Note = ".",
        Key = "BYXVALLYPRISON_BEST2025ioiup_V2",
        SaveKey = false,
        WrongKeyMessage = "Incorrect key! Please try again.",
        CorrectKeyMessage = "Script unlocked successfully!"
    },
    Theme = randomTheme
})

-- Verify KeySystem
if not Window then
    warn("KeySystem failed to initialize. Please enter the key: BYXVALLYPRISON_BEST2025ioiup_V2")
    return
else
    print("KeySystem validated successfully!")
end

-- Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local prisonerTeams = {"Minimum Security", "Medium Security", "Maximum Security"}

-- // COMBAT TAB (Aimbot + FOV + Combat features)
local CombatTab = Window:CreateTab("Combat", 4483362458)

-- Aimbot Variables
local AimbotEnabled = false
local SilentAim = false
local FOVRadius = 150
local Smoothness = 0.15
local StickToTarget = false
local IgnoreWalls = false
local TeamCheck = false
local ShowFOVCircle = true
local PredictionEnabled = false
local BulletSpeed = 1000
local CurrentTarget = nil
local TargetPart = "Head"
local FOVCircle = nil

local function CreateFOVCircle()
    if FOVCircle then
        FOVCircle:Remove()
        FOVCircle = nil
    end
    task.wait(0.05)
    local success, result = pcall(function()
        FOVCircle = Drawing.new("Circle")
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        FOVCircle.Radius = FOVRadius
        FOVCircle.Color = Color3.fromRGB(255, 0, 0)
        FOVCircle.Thickness = 2
        FOVCircle.Filled = false
        FOVCircle.Visible = AimbotEnabled and ShowFOVCircle
    end)
    if not success then
        Rayfield:Notify({
            Title = "Error",
            Content = "Failed to create FOV Circle: " .. result,
            Duration = 5,
            Image = 4483362458
        })
    else
        print("FOV Circle created with fixed red color")
    end
end

local function UpdateFOVCircle()
    if not FOVCircle then
        CreateFOVCircle()
        return
    end
    if not Camera then
        Rayfield:Notify({
            Title = "Error",
            Content = "Camera not found. Try again.",
            Duration = 5,
            Image = 4483362458
        })
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
    if not player.Character or not player.Character:FindFirstChild(TargetPart) or not player.Character:FindFirstChild("Humanoid") then return false end
    if TeamCheck and LocalPlayer.Team and player.Team then
        local localPlayerIsPrisoner = table.find(prisonerTeams, LocalPlayer.Team.Name)
        local targetIsPrisoner = table.find(prisonerTeams, player.Team.Name)
        if localPlayerIsPrisoner and targetIsPrisoner then
            return false
        end
        if not localPlayerIsPrisoner or not targetIsPrisoner then
            if LocalPlayer.Team == player.Team then
                return false
            end
        end
    end
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

local function GetPredictedPosition(targetPart)
    if not PredictionEnabled then return targetPart.Position end
    local velocity = targetPart.Velocity
    local distance = (Camera.CFrame.Position - targetPart.Position).Magnitude
    local timeToHit = distance / BulletSpeed
    return targetPart.Position + (velocity * timeToHit)
end

local oldIndex = nil
local silentAimConnection = nil
local function EnableSilentAim()
    if silentAimConnection then return end
    local success, result = pcall(function()
        if getmetatable and getmetatable(game).__index then
            oldIndex = getmetatable(game).__index
            getmetatable(game).__index = function(self, index)
                if AimbotEnabled and SilentAim and CurrentTarget and self == Mouse then
                    if index == "Hit" then
                        local predictedPos = GetPredictedPosition(CurrentTarget.Character[TargetPart])
                        return CFrame.new(predictedPos)
                    elseif index == "Target" then
                        return CurrentTarget.Character[TargetPart]
                    end
                end
                return oldIndex(self, index)
            end
        else
            error("Executor does not support hookmetamethod")
        end
    end)
    if not success then
        Rayfield:Notify({
            Title = "Error",
            Content = "Silent Aim failed: " .. result,
            Duration = 5,
            Image = 4483362458
        })
    else
        silentAimConnection = true
        Rayfield:Notify({
            Title = "Success",
            Content = "Silent Aim enabled!",
            Duration = 3,
            Image = 4483362458
        })
    end
end

local function DisableSilentAim()
    if oldIndex then
        getmetatable(game).__index = oldIndex
    end
    silentAimConnection = nil
    Rayfield:Notify({
        Title = "Info",
        Content = "Silent Aim disabled!",
        Duration = 3,
        Image = 4483362458
    })
end

CombatTab:CreateToggle({
    Name = "Enable Aimbot",
    CurrentValue = false,
    Flag = "AIMBOT_TOGGLE",
    Callback = function(Value)
        AimbotEnabled = Value
        CurrentTarget = nil
        if not Camera then
            Rayfield:Notify({
                Title = "Error",
                Content = "Camera not found. Try again.",
                Duration = 5,
                Image = 4483362458
            })
            AimbotEnabled = false
            return
        end
        CreateFOVCircle()
        if AimbotEnabled then
            local connection
            connection = RunService.RenderStepped:Connect(function()
                if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("Humanoid") then
                    Rayfield:Notify({
                        Title = "Error",
                        Content = "Character not found. Aimbot disabled.",
                        Duration = 5,
                        Image = 4483362458
                    })
                    AimbotEnabled = false
                    connection:Disconnect()
                    return
                end
                UpdateFOVCircle()
                if AimbotEnabled then
                    if StickToTarget and CurrentTarget and IsInFOV(CurrentTarget) and IsValidTarget(CurrentTarget) then
                    else
                        CurrentTarget = GetClosestPlayerInFOV()
                    end
                    if not SilentAim and CurrentTarget and CurrentTarget.Character and CurrentTarget.Character:FindFirstChild(TargetPart) then
                        local predictedPos = GetPredictedPosition(CurrentTarget.Character[TargetPart])
                        local currentCFrame = Camera.CFrame
                        local targetCFrame = CFrame.new(currentCFrame.Position, predictedPos)
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
            DisableSilentAim()
        end
        Rayfield:Notify({
            Title = "Info",
            Content = "Aimbot " .. (Value and "enabled!" or "disabled!"),
            Duration = 3,
            Image = 4483362458
        })
    end
})

CombatTab:CreateToggle({
    Name = "Silent Aim",
    CurrentValue = false,
    Flag = "SILENT_AIM",
    Callback = function(Value)
        SilentAim = Value
        if SilentAim and AimbotEnabled then
            EnableSilentAim()
        else
            DisableSilentAim()
        end
    end
})

CombatTab:CreateToggle({
    Name = "Prediction",
    CurrentValue = false,
    Flag = "PREDICTION",
    Callback = function(Value)
        PredictionEnabled = Value
        Rayfield:Notify({
            Title = "Info",
            Content = "Prediction " .. (Value and "enabled!" or "disabled!"),
            Duration = 3,
            Image = 4483362458
        })
    end
})

CombatTab:CreateSlider({
    Name = "Bullet Speed",
    Range = {500, 2000},
    Increment = 100,
    CurrentValue = 1000,
    Flag = "BULLET_SPEED",
    Callback = function(Value)
        BulletSpeed = Value
        Rayfield:Notify({
            Title = "Info",
            Content = "Bullet Speed set to: " .. Value,
            Duration = 3,
            Image = 4483362458
        })
    end
})

CombatTab:CreateDropdown({
    Name = "Target Part",
    Options = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"},
    CurrentOption = {"Head"},
    MultipleOptions = false,
    Flag = "TARGET_PART",
    Callback = function(Option)
        TargetPart = Option[1]
        Rayfield:Notify({
            Title = "Info",
            Content = "Target Part set to: " .. TargetPart,
            Duration = 3,
            Image = 4483362458
        })
    end
})

CombatTab:CreateSlider({
    Name = "FOV Radius",
    Range = {50, 500},
    Increment = 10,
    CurrentValue = 150,
    Flag = "FOV_RADIUS",
    Callback = function(Value)
        FOVRadius = Value
        UpdateFOVCircle()
        Rayfield:Notify({
            Title = "Info",
            Content = "FOV Radius set to: " .. Value,
            Duration = 3,
            Image = 4483362458
        })
    end
})

CombatTab:CreateToggle({
    Name = "Show FOV Circle",
    CurrentValue = true,
    Flag = "SHOW_FOV_CIRCLE",
    Callback = function(Value)
        ShowFOVCircle = Value
        UpdateFOVCircle()
        Rayfield:Notify({
            Title = "Info",
            Content = "FOV Circle " .. (Value and "shown!" or "hidden!"),
            Duration = 3,
            Image = 4483362458
        })
    end
})

CombatTab:CreateSlider({
    Name = "Smoothness (Visible Aim)",
    Range = {0.05, 0.5},
    Increment = 0.01,
    CurrentValue = 0.15,
    Flag = "AIMBOT_SMOOTHNESS",
    Callback = function(Value)
        Smoothness = Value
        Rayfield:Notify({
            Title = "Info",
            Content = "Smoothness set to: " .. Value,
            Duration = 3,
            Image = 4483362458
        })
    end
})

CombatTab:CreateToggle({
    Name = "Stick to Target",
    CurrentValue = false,
    Flag = "STICK_TARGET",
    Callback = function(Value)
        StickToTarget = Value
        if not StickToTarget then
            CurrentTarget = nil
        end
        Rayfield:Notify({
            Title = "Info",
            Content = "Stick to Target " .. (Value and "enabled!" or "disabled!"),
            Duration = 3,
            Image = 4483362458
        })
    end
})

CombatTab:CreateToggle({
    Name = "Ignore Walls",
    CurrentValue = false,
    Flag = "IGNORE_WALLS",
    Callback = function(Value)
        IgnoreWalls = Value
        Rayfield:Notify({
            Title = "Info",
            Content = "Ignore Walls " .. (Value and "enabled!" or "disabled!"),
            Duration = 3,
            Image = 4483362458
        })
    end
})

CombatTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = false,
    Flag = "TEAM_CHECK",
    Callback = function(Value)
        TeamCheck = Value
        CurrentTarget = nil
        Rayfield:Notify({
            Title = "Info",
            Content = "Team Check " .. (Value and "enabled!" or "disabled!"),
            Duration = 3,
            Image = 4483362458
        })
    end
})

-- FOV Camera (from original script, moved to Combat Tab)
local FOVEnabled = false
local DefaultFOV = 70
local CustomFOV = 90

local function UpdateFOV()
    if not Camera then
        Rayfield:Notify({
            Title = "Error",
            Content = "Camera not found. Try again.",
            Duration = 5,
            Image = 4483362458
        })
        return
    end
    if FOVEnabled then
        Camera.FieldOfView = CustomFOV
    else
        Camera.FieldOfView = DefaultFOV
    end
end

CombatTab:CreateToggle({
    Name = "Enable Custom FOV",
    CurrentValue = false,
    Flag = "FOV_TOGGLE",
    Callback = function(Value)
        FOVEnabled = Value
        UpdateFOV()
        Rayfield:Notify({
            Title = "Info",
            Content = "Custom FOV " .. (Value and "enabled!" or "disabled!"),
            Duration = 3,
            Image = 4483362458
        })
    end
})

CombatTab:CreateSlider({
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
        Rayfield:Notify({
            Title = "Info",
            Content = "FOV set to: " .. Value,
            Duration = 3,
            Image = 4483362458
        })
    end
})

-- Combat Features (No Recoil, No Spread, Fire Rate)
local noRecoilEnabled = false
local noSpreadEnabled = false
local fireRateMultiplier = 1
local originalGunSettings = {}

local function SaveOriginalGunSettings(gun)
    if not originalGunSettings[gun] then
        originalGunSettings[gun] = {
            recoil = gun:FindFirstChild("Recoil") and gun.Recoil.Value or 0,
            spread = gun:FindFirstChild("Spread") and gun.Spread.Value or 0,
            fireRate = gun:FindFirstChild("FireRate") and gun.FireRate.Value or 1
        }
    end
end

local function ApplyGunSettings(gun)
    if noRecoilEnabled and gun:FindFirstChild("Recoil") then
        gun.Recoil.Value = 0
    end
    if noSpreadEnabled and gun:FindFirstChild("Spread") then
        gun.Spread.Value = 0
    end
    if fireRateMultiplier ~= 1 and gun:FindFirstChild("FireRate") then
        gun.FireRate.Value = originalGunSettings[gun].fireRate / fireRateMultiplier
    end
end

local function RestoreGunSettings(gun)
    if originalGunSettings[gun] then
        if gun:FindFirstChild("Recoil") then
            gun.Recoil.Value = originalGunSettings[gun].recoil
        end
        if gun:FindFirstChild("Spread") then
            gun.Spread.Value = originalGunSettings[gun].spread
        end
        if gun:FindFirstChild("FireRate") then
            gun.FireRate.Value = originalGunSettings[gun].fireRate
        end
    end
end

CombatTab:CreateToggle({
    Name = "No Recoil",
    CurrentValue = false,
    Flag = "NO_RECOIL",
    Callback = function(Value)
        noRecoilEnabled = Value
        for _, gun in pairs(LocalPlayer.Backpack:GetChildren()) do
            if gun:IsA("Tool") then
                SaveOriginalGunSettings(gun)
                ApplyGunSettings(gun)
            end
        end
        if LocalPlayer.Character then
            local equipped = LocalPlayer.Character:FindFirstChildOfClass("Tool")
            if equipped then
                SaveOriginalGunSettings(equipped)
                ApplyGunSettings(equipped)
            end
        end
        Rayfield:Notify({
            Title = "Info",
            Content = "No Recoil " .. (Value and "enabled!" or "disabled!"),
            Duration = 3,
            Image = 4483362458
        })
    end
})

CombatTab:CreateToggle({
    Name = "No Spread",
    CurrentValue = false,
    Flag = "NO_SPREAD",
    Callback = function(Value)
        noSpreadEnabled = Value
        for _, gun in pairs(LocalPlayer.Backpack:GetChildren()) do
            if gun:IsA("Tool") then
                SaveOriginalGunSettings(gun)
                ApplyGunSettings(gun)
            end
        end
        if LocalPlayer.Character then
            local equipped = LocalPlayer.Character:FindFirstChildOfClass("Tool")
            if equipped then
                SaveOriginalGunSettings(equipped)
                ApplyGunSettings(equipped)
            end
        end
        Rayfield:Notify({
            Title = "Info",
            Content = "No Spread " .. (Value and "enabled!" or "disabled!"),
            Duration = 3,
            Image = 4483362458
        })
    end
})

CombatTab:CreateSlider({
    Name = "Fire Rate Multiplier",
    Range = {1, 5},
    Increment = 0.5,
    CurrentValue = 1,
    Flag = "FIRE_RATE_MULTIPLIER",
    Callback = function(Value)
        fireRateMultiplier = Value
        for _, gun in pairs(LocalPlayer.Backpack:GetChildren()) do
            if gun:IsA("Tool") then
                SaveOriginalGunSettings(gun)
                ApplyGunSettings(gun)
            end
        end
        if LocalPlayer.Character then
            local equipped = LocalPlayer.Character:FindFirstChildOfClass("Tool")
            if equipped then
                SaveOriginalGunSettings(equipped)
                ApplyGunSettings(equipped)
            end
        end
        Rayfield:Notify({
            Title = "Info",
            Content = "Fire Rate Multiplier set to: " .. Value .. "x",
            Duration = 3,
            Image = 4483362458
        })
    end
})

LocalPlayer.Backpack.ChildAdded:Connect(function(child)
    if child:IsA("Tool") then
        SaveOriginalGunSettings(child)
        ApplyGunSettings(child)
    end
})

LocalPlayer.Backpack.ChildRemoved:Connect(function(child)
    if child:IsA("Tool") then
        RestoreGunSettings(child)
    end
})

LocalPlayer.CharacterAdded:Connect(function(character)
    character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            SaveOriginalGunSettings(child)
            ApplyGunSettings(child)
        end
    end)
    character.ChildRemoved:Connect(function(child)
        if child:IsA("Tool") then
            RestoreGunSettings(child)
        end
    end)
end)

-- // VISUALS TAB (replacing ESP)
local VisualsTab = Window:CreateTab("Visuals", 4483362458)

local ESPEnabled = false
local ShowHealth = false
local ShowInventory = false
local ESPObjects = {}

local function updateInventory(player, espHolder)
    if not player or not espHolder or not player.Backpack or not player.Character then
        espHolder.InventoryText.Text = "Inventory: N/A"
        return
    end
    local inv = {}
    for _, tool in pairs(player.Backpack:GetChildren()) do
        if tool:IsA("Tool") then
            table.insert(inv, tool.Name)
        end
    end
    local equipped = player.Character:FindFirstChildOfClass("Tool")
    if equipped then
        table.insert(inv, equipped.Name .. " (equipped)")
    end
    if #inv == 0 then
        espHolder.InventoryText.Text = "Inventory: Empty"
    else
        espHolder.InventoryText.Text = "Inventory: " .. table.concat(inv, ", ")
    end
end

function CreateESP(player)
    if player == LocalPlayer then return end
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
        billboard.Size = UDim2.new(0, 200, 0, 100)
        billboard.StudsOffset = Vector3.new(0, 2, 0)
        billboard.AlwaysOnTop = true
        billboard.Enabled = ESPEnabled

        local healthFrame = Instance.new("Frame")
        healthFrame.Name = "HealthBar"
        healthFrame.Parent = billboard
        healthFrame.Size = UDim2.new(1, 0, 0, 8)
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
        healthText.Size = UDim2.new(1, 0, 0, 15)
        healthText.Position = UDim2.new(0, 0, 0, 10)
        healthText.BackgroundTransparency = 1
        healthText.TextColor3 = Color3.fromRGB(255, 255, 255)
        healthText.TextSize = 12
        healthText.Font = Enum.Font.SourceSansBold
        healthText.TextStrokeTransparency = 0
        healthText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        healthText.Text = "HP: N/A"
        healthText.Visible = ShowHealth and ESPEnabled

        local inventoryText = Instance.new("TextLabel")
        inventoryText.Name = "InventoryText"
        inventoryText.Parent = billboard
        inventoryText.Size = UDim2.new(1, 0, 0, 15)
        inventoryText.Position = UDim2.new(0, 0, 0, 25)
        inventoryText.BackgroundTransparency = 1
        inventoryText.TextColor3 = player.Team and player.Team.TeamColor and player.Team.TeamColor.Color or Color3.fromRGB(255, 255, 255)
        inventoryText.TextSize = 12
        inventoryText.Font = Enum.Font.SourceSansBold
        inventoryText.TextStrokeTransparency = 0
        inventoryText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        inventoryText.Text = "Inventory: N/A"
        inventoryText.Visible = ShowInventory and ESPEnabled and player.Team and table.find(prisonerTeams, player.Team.Name)

        local humanoid = player.Character:FindFirstChild("Humanoid")
        if humanoid then
            local function updateHealth()
                if not player.Character or not player.Character:FindFirstChild("Humanoid") or not healthFrame.Visible then
                    healthText.Text = "HP: N/A"
                    healthFrame.Size = UDim2.new(1, 0, 0, 8)
                    return
                end
                local currentHumanoid = player.Character:FindFirstChild("Humanoid")
                if currentHumanoid then
                    local healthPercent = currentHumanoid.Health / currentHumanoid.MaxHealth
                    healthFrame.Size = UDim2.new(healthPercent, 0, 0, 8)
                    healthFrame.BackgroundColor3 = Color3.fromRGB(255 * (1 - healthPercent), 150 * healthPercent, 0)
                    healthText.Text = "HP: " .. math.floor(currentHumanoid.Health) .. "/" .. math.floor(currentHumanoid.MaxHealth)
                else
                    healthText.Text = "HP: N/A"
                    healthFrame.Size = UDim2.new(1, 0, 0, 8)
                end
            end
            updateHealth()
            humanoid:GetPropertyChangedSignal("Health"):Connect(updateHealth)
            humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(updateHealth)
        end

        if player.Team and table.find(prisonerTeams, player.Team.Name) then
            updateInventory(player, { InventoryText = inventoryText })
            player.Backpack.ChildAdded:Connect(function()
                updateInventory(player, { InventoryText = inventoryText })
            end)
            player.Backpack.ChildRemoved:Connect(function()
                updateInventory(player, { InventoryText = inventoryText })
            end)
            player.Character.ChildAdded:Connect(function(child)
                if child:IsA("Tool") then
                    updateInventory(player, { InventoryText = inventoryText })
                end
            end)
            player.Character.ChildRemoved:Connect(function(child)
                if child:IsA("Tool") then
                    updateInventory(player, { InventoryText = inventoryText })
                end
            end)
        end

        espHolder.Billboard = billboard
        espHolder.HealthFrame = healthFrame
        espHolder.HealthText = healthText
        espHolder.InventoryText = inventoryText
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

local function RefreshESP()
    if not ESPEnabled then
        Rayfield:Notify({
            Title = "Info",
            Content = "ESP must be enabled to refresh!",
            Duration = 3,
            Image = 4483362458
        })
        return
    end
    for _, espHolder in pairs(ESPObjects) do
        if espHolder.Highlight then
            espHolder.Highlight:Destroy()
        end
        if espHolder.Billboard then
            espHolder.Billboard:Destroy()
        end
    end
    ESPObjects = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") then
            task.spawn(function()
                CreateESP(player)
            end)
        end
    end
    Rayfield:Notify({
        Title = "Success",
        Content = "ESP refreshed for all players!",
        Duration = 3,
        Image = 4483362458
    })
end

for _, player in pairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
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
    if player ~= LocalPlayer then
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
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") then
                task.spawn(function()
                    CreateESP(player)
                end)
            end
        end
    end
end)

VisualsTab:CreateToggle({
    Name = "Enable ESP",
    CurrentValue = false,
    Flag = "ESP_TOGGLE",
    Callback = function(Value)
        ESPEnabled = Value
        if ESPEnabled then
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") then
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
        Rayfield:Notify({
            Title = "Info",
            Content = "ESP " .. (Value and "enabled!" or "disabled!"),
            Duration = 3,
            Image = 4483362458
        })
    end
})

VisualsTab:CreateToggle({
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
        Rayfield:Notify({
            Title = "Info",
            Content = "Show Health Bar " .. (Value and "enabled!" or "disabled!"),
            Duration = 3,
            Image = 4483362458
        })
    end
})

VisualsTab:CreateToggle({
    Name = "Show Inventory",
    CurrentValue = false,
    Flag = "SHOW_INVENTORY",
    Callback = function(Value)
        ShowInventory = Value
        for _, player in pairs(Players:GetPlayers()) do
            if ESPObjects[player] and ESPObjects[player].Billboard then
                if player.Team and table.find(prisonerTeams, player.Team.Name) then
                    ESPObjects[player].Billboard.InventoryText.Visible = ShowInventory and ESPEnabled
                    if ESPObjects[player].Billboard.InventoryText.Visible then
                        updateInventory(player, ESPObjects[player])
                    end
                else
                    ESPObjects[player].Billboard.InventoryText.Visible = false
                end
            end
        end
        Rayfield:Notify({
            Title = "Info",
            Content = "Show Inventory " .. (Value and "enabled!" or "disabled!"),
            Duration = 3,
            Image = 4483362458
        })
    end
})

VisualsTab:CreateButton({
    Name = "Refresh ESP",
    Callback = function()
        RefreshESP()
    end
})

-- // TELEPORT SECTION
local TeleportTab = Window:CreateTab("Teleports", 4483362458)

local locations = {
    ["MAINTENANCE"] = CFrame.new(172.34, 23.10, -143.87),
    ["SECURITY"] = CFrame.new(224.47, 23.10, -167.90),
    ["OC LOCKERS"] = CFrame.new(137.60, 23.10, -169.93),
    ["RIOT LOCKERS"] = CFrame.new(165.63, 23.10, -192.25),
    ["VENT"] = CFrame.new(76.96, -7.02, -19.21),
    ["Maximum"] = CFrame.new(101.84, -8.82, -141.41),
    ["Generator"] = CFrame.new(100.95, -8.82, -57.59),
    ["OUTSIDE"] = CFrame.new(350.22, 5.40, -171.09),
    ["Escapee Base"] = CFrame.new(749.02, -0.97, -470.45)
}

for name, cf in pairs(locations) do
    TeleportTab:CreateButton({
        Name = name,
        Callback = function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character:PivotTo(cf)
                Rayfield:Notify({
                    Title = "Success",
                    Content = "Teleported to " .. name .. "!",
                    Duration = 3,
                    Image = 4483362458
                })
            else
                Rayfield:Notify({
                    Title = "Error",
                    Content = "Character not found. Try again.",
                    Duration = 5,
                    Image = 4483362458
                })
            end
        end
    })
end

TeleportTab:CreateButton({
    Name = "Escapee",
    Callback = function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character:PivotTo(CFrame.new(307.06, 5.40, -177.88))
            Rayfield:Notify({
                Title = "Success",
                Content = "Teleported to Escapee!",
                Duration = 3,
                Image = 4483362458
            })
        else
            Rayfield:Notify({
                Title = "Error",
                Content = "Character not found. Try again.",
                Duration = 5,
                Image = 4483362458
            })
        end
    end
})

TeleportTab:CreateButton({
    Name = "Keycard (💳)",
    Callback = function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character:PivotTo(CFrame.new(-13.36, 22.13, -27.47))
            Rayfield:Notify({
                Title = "Success",
                Content = "Teleported to Keycard!",
                Duration = 3,
                Image = 4483362458
            })
        else
            Rayfield:Notify({
                Title = "Error",
                Content = "Character not found. Try again.",
                Duration = 5,
                Image = 4483362458
            })
        end
    end
})

-- // ITEMS SECTION
local ItemsTab = Window:CreateTab("Items", 4483362458)

ItemsTab:CreateButton({
    Name = "Get FAKE Keycard (Players can see it)",
    Callback = function()
        local player = LocalPlayer
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            Rayfield:Notify({
                Title = "Error",
                Content = "Cannot find your character!",
                Duration = 3,
                Image = 4483362458
            })
            return
        end

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
                        Content = "Keycard added to Backpack, but equipping failed. Check your character.",
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
                    Content = "Keycard not found. Try again.",
                    Duration = 5,
                    Image = 4483362458
                })
                print("Keycard not found after " .. maxAttempts .. " attempts.")
            end
        end

        tryGetKeycard()
    end
})

-- // PLAYER SECTION
local PlayerTab = Window:CreateTab("Player", 4483362458)

local infiniteStaminaEnabled = false
local speed = 16
local fakerun = false
local infjumpv2 = false
local xrayEnabled = false
local fling = false

PlayerTab:CreateButton({
    Name = "Infinite Stamina",
    Callback = function()
        infiniteStaminaEnabled = not infiniteStaminaEnabled
        local player = LocalPlayer
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
                print("Stamina or MaxStamina not found.")
                Rayfield:Notify({
                    Title = "Error",
                    Content = "Stamina or MaxStamina not found. Check your character setup.",
                    Duration = 5,
                    Image = 4483362458
                })
                infiniteStaminaEnabled = false
            end
        else
            print("ServerVariables or Sprint not found.")
            Rayfield:Notify({
                Title = "Error",
                Content = "ServerVariables or Sprint not found. Try again.",
                Duration = 5,
                Image = 4483362458
            })
            infiniteStaminaEnabled = false
        end
    end
})

PlayerTab:CreateSlider({
    Name = "Speed",
    Range = {1, 100},
    Increment = 1,
    Suffix = "USpeed",
    CurrentValue = 16,
    Flag = "UserSpeed",
    Callback = function(Value)
        speed = Value
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("Humanoid") then
            character.Humanoid.WalkSpeed = Value
            Rayfield:Notify({
                Title = "Info",
                Content = "Walk Speed set to: " .. Value,
                Duration = 3,
                Image = 4483362458
            })
        else
            Rayfield:Notify({
                Title = "Error",
                Content = "Character not found. Try again.",
                Duration = 5,
                Image = 4483362458
            })
        end
    end
})

PlayerTab:CreateToggle({
    Name = "Fake Run",
    CurrentValue = false,
    Flag = "FR",
    Callback = function(Value)
        fakerun = Value
        Rayfield:Notify({
            Title = "Info",
            Content = "Fake Run " .. (Value and "enabled!" or "disabled!"),
            Duration = 3,
            Image = 4483362458
        })
    end
})

PlayerTab:CreateToggle({
    Name = "(Stable) Inf Jump",
    CurrentValue = false,
    Flag = "IJ",
    Callback = function(Value)
        infjumpv2 = Value
        Rayfield:Notify({
            Title = "Info",
            Content = "(Stable) Inf Jump " .. (Value and "enabled!" or "disabled!"),
            Duration = 3,
            Image = 4483362458
        })
    end
})

PlayerTab:CreateToggle({
    Name = "Xray",
    CurrentValue = false,
    Flag = "Xray",
    Callback = function(Value)
        xrayEnabled = Value
        if Value then
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("BasePart") then
                    v.LocalTransparencyModifier = 0.5
                end
            end
            Rayfield:Notify({
                Title = "Info",
                Content = "Xray enabled!",
                Duration = 3,
                Image = 4483362458
            })
        else
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("BasePart") then
                    v.LocalTransparencyModifier = 0
                end
            end
            Rayfield:Notify({
                Title = "Info",
                Content = "Xray disabled!",
                Duration = 3,
                Image = 4483362458
            })
        end
    end
})

PlayerTab:CreateToggle({
    Name = "Walkfling",
    CurrentValue = false,
    Flag = "WF",
    Callback = function(Value)
        fling = Value
        if not Value then
            running = false
        end
        Rayfield:Notify({
            Title = "Info",
            Content = "Walkfling " .. (Value and "enabled!" or "disabled!"),
            Duration = 3,
            Image = 4483362458
        })
    end
})

-- RenderStepped connections from old script (literal copy paste)
RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = speed
    end
end)

local function RunRenderFakeRun()
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then
        if fakerun then
            Rayfield:Notify({
                Title = "Error",
                Content = "Character not found for Fake Run. Try again.",
                Duration = 5,
                Image = 4483362458
            })
        end
        return
    end
    if fakerun then
        root.AssemblyLinearVelocity = Vector3.new(0, 0, 50)
        root.Anchored = true
    else
        root.Anchored = false
    end
end
RunService.RenderStepped:Connect(RunRenderFakeRun)

local running = false
local function start()
    if running or not fling then return end
    running = true
    while fling and task.wait() do
        local foundTarget = false
        for _, v in ipairs(workspace:GetChildren()) do
            if v:IsA("Model") then
                local p = Players:GetPlayerFromCharacter(v)
                if p and p ~= LocalPlayer then
                    local char = p.Character
                    if char then
                        local root = char:FindFirstChild("HumanoidRootPart")
                        if root then
                            root.AssemblyLinearVelocity = Vector3.new(0, 1000000, 0)
                            foundTarget = true
                        end
                    end
                end
            end
        end
        if not foundTarget and fling then
            Rayfield:Notify({
                Title = "Warning",
                Content = "No valid targets found for Walkfling.",
                Duration = 5,
                Image = 4483362458
            })
        end
    end
    running = false
end
RunService.RenderStepped:Connect(start)

UserInputService.JumpRequest:Connect(function()
    local char = LocalPlayer.Character
    if not char then
        if infjumpv2 then
            Rayfield:Notify({
                Title = "Error",
                Content = "Character not found for Infinite Jump. Try again.",
                Duration = 5,
                Image = 4483362458
            })
        end
        return
    end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if infjumpv2 and humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        Rayfield:Notify({
            Title = "Success",
            Content = "Infinite Jump triggered!",
            Duration = 2,
            Image = 4483362458
        })
    end
end)

-- // INFO TAB
local InfoTab = Window:CreateTab("Info", 4483362458)

InfoTab:CreateButton({
    Name = "Copy yt Link",
    Callback = function()
        local link = "https://www.youtube.com/@6rb-l5r"
        if setclipboard then
            setclipboard(link)
            Rayfield:Notify({
                Title = "Link Copied!",
                Content = "The link has been copied to your clipboard.",
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

print("✅ Script loaded successfully!")
