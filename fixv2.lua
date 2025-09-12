-- // UI LIBRARY
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
print("Rayfield loaded!")  -- Check console

-- Random theme
local themes = {"Ocean", "Amethyst", "DarkBlue"}
local randomTheme = themes[math.random(1, #themes)]

-- Create Window (no key for testing)
local Window = Rayfield:CreateWindow({
    Name = "Valley Prison ByX v2! (Light Mode)",
    LoadingTitle = ".",
    LoadingSubtitle = "ByX",
    ConfigurationSaving = { Enabled = false },
    Discord = { Enabled = false },
    KeySystem = false,
    Theme = randomTheme
})

if not Window then
    warn("Window failed! Check HttpGet in console.")
    return
end
print("Window created!")

-- Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local prisonerTeams = {"Minimum Security", "Medium Security", "Maximum Security"}

-- // INFO TAB
local InfoTab = Window:CreateTab("Info", 4483362458)
InfoTab:CreateButton({
    Name = "Copy YT Link",
    Callback = function()
        setclipboard("https://www.youtube.com/@6rb-l5r")
        Rayfield:Notify({Title = "Copied!", Content = "YT Link copied!", Duration = 3, Image = 4483362458})
    end
})

-- // ESP TAB (Light version)
local ESPTab = Window:CreateTab("ESP", 4483362458)
local ESPEnabled = false
local ShowHealth = false
local ShowInventory = false
local ESPObjects = {}

local function updateInventory(player, invText)
    if not player.Backpack or not player.Character then return end
    local inv = {}
    for _, tool in pairs(player.Backpack:GetChildren()) do
        if tool:IsA("Tool") then table.insert(inv, tool.Name) end
    end
    local equipped = player.Character:FindFirstChildOfClass("Tool")
    if equipped then table.insert(inv, equipped.Name .. " (eq)") end
    invText.Text = #inv > 0 and "Inv: " .. table.concat(inv, ", ") or "Inv: Empty"
end

function CreateESP(player)
    if player == LocalPlayer or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") or not player.Character:FindFirstChild("Humanoid") or ESPObjects[player] then return end
    local espHolder = {}
    
    -- Highlight
    local highlight = Instance.new("Highlight")
    highlight.Parent = player.Character
    highlight.Adornee = player.Character
    highlight.FillTransparency = 0.3
    highlight.OutlineTransparency = 1
    highlight.FillColor = player.Team and player.Team.TeamColor.Color or Color3.new(1,1,1)
    espHolder.Highlight = highlight

    -- Billboard
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_Billboard"
    billboard.Parent = player.Character
    billboard.Adornee = player.Character.Head
    billboard.Size = UDim2.new(0, 200, 0, 60)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.AlwaysOnTop = true
    billboard.Enabled = ESPEnabled

    -- Health
    local healthText = Instance.new("TextLabel")
    healthText.Name = "HealthText"
    healthText.Parent = billboard
    healthText.Size = UDim2.new(1, 0, 0, 15)
    healthText.Position = UDim2.new(0, 0, 0, 0)
    healthText.BackgroundTransparency = 1
    healthText.TextColor3 = Color3.new(1,1,1)  -- White fixed
    healthText.TextSize = 12
    healthText.Font = Enum.Font.SourceSansBold
    healthText.TextStrokeTransparency = 0
    healthText.TextStrokeColor3 = Color3.new(0,0,0)
    healthText.Text = "HP: N/A"
    healthText.Visible = ShowHealth and ESPEnabled
    espHolder.HealthText = healthText

    -- Inventory
    local invText = Instance.new("TextLabel")
    invText.Name = "InventoryText"
    invText.Parent = billboard
    invText.Size = UDim2.new(1, 0, 0, 15)
    invText.Position = UDim2.new(0, 0, 0, 15)
    invText.BackgroundTransparency = 1
    invText.TextColor3 = player.Team and player.Team.TeamColor.Color or Color3.new(1,1,1)  -- Team color
    invText.TextSize = 12
    invText.Font = Enum.Font.SourceSansBold
    invText.TextStrokeTransparency = 0
    invText.TextStrokeColor3 = Color3.new(0,0,0)
    invText.Text = "Inv: N/A"
    invText.Visible = ShowInventory and ESPEnabled and table.find(prisonerTeams, player.Team.Name)
    espHolder.InventoryText = invText

    -- Update health
    local humanoid = player.Character.Humanoid
    local function updateHealth()
        if humanoid then
            local hp = math.floor(humanoid.Health) .. "/" .. math.floor(humanoid.MaxHealth)
            healthText.Text = "HP: " .. hp
        end
    end
    updateHealth()
    humanoid.HealthChanged:Connect(updateHealth)

    -- Update inventory if prisoner
    if table.find(prisonerTeams, player.Team.Name) then
        updateInventory(player, invText)
        player.Backpack.ChildAdded:Connect(function() updateInventory(player, invText) end)
        player.Backpack.ChildRemoved:Connect(function() updateInventory(player, invText) end)
    end

    ESPObjects[player] = espHolder
end

function RemoveAllESP()
    for player, holder in pairs(ESPObjects) do
        if holder.Highlight then holder.Highlight:Destroy() end
        if holder.Billboard then holder.Billboard:Destroy() end
    end
    ESPObjects = {}
end

-- Connections
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        if ESPEnabled then task.wait(0.5); CreateESP(player) end
    end)
end)

Players.PlayerRemoving:Connect(function(player) ESPObjects[player] = nil end)

RunService.Heartbeat:Connect(function()
    if ESPEnabled then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") and not ESPObjects[player] then
                CreateESP(player)
            end
        end
    end
end)

-- Toggles
ESPTab:CreateToggle({
    Name = "Enable ESP",
    CurrentValue = false,
    Callback = function(Value)
        ESPEnabled = Value
        if Value then
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then CreateESP(player) end
            end
        else
            RemoveAllESP()
        end
    end
})

ESPTab:CreateToggle({
    Name = "Show Health (White Text)",
    CurrentValue = false,
    Callback = function(Value)
        ShowHealth = Value
        for _, holder in pairs(ESPObjects) do
            if holder.HealthText then holder.HealthText.Visible = Value and ESPEnabled end
        end
    end
})

ESPTab:CreateToggle({
    Name = "Show Inventory (Team Color Text)",
    CurrentValue = false,
    Callback = function(Value)
        ShowInventory = Value
        for player, holder in pairs(ESPObjects) do
            if holder.InventoryText then
                holder.InventoryText.Visible = Value and ESPEnabled and table.find(prisonerTeams, player.Team.Name)
                if holder.InventoryText.Visible then updateInventory(player, holder.InventoryText) end
            end
        end
    end
})

ESPTab:CreateButton({
    Name = "Refresh ESP",
    Callback = function()
        if not ESPEnabled then Rayfield:Notify({Title = "Error", Content = "Enable ESP first!", Duration = 3}) return end
        RemoveAllESP()
        for _, player in pairs(Players:GetPlayers()) do CreateESP(player) end
        Rayfield:Notify({Title = "Done", Content = "ESP refreshed!", Duration = 3})
    end
})

-- // AIMBOT TAB (Light version with team check)
local AimbotTab = Window:CreateTab("Aimbot", 4483362458)
local AimbotEnabled = false
local TeamCheck = false
local FOVRadius = 150
local TargetPart = "Head"
local CurrentTarget = nil
local FOVCircle = Drawing.new("Circle")

local function IsValidTarget(player)
    if player == LocalPlayer then return false end
    if TeamCheck and LocalPlayer.Team and player.Team then
        local localIsPrisoner = table.find(prisonerTeams, LocalPlayer.Team.Name)
        local targetIsPrisoner = table.find(prisonerTeams, player.Team.Name)
        if localIsPrisoner and targetIsPrisoner then return false end  -- Same "prisoner" group
        if LocalPlayer.Team == player.Team then return false end
    end
    return player.Character and player.Character:FindFirstChild(TargetPart) and player.Character:FindFirstChild("Humanoid")
end

local function GetClosestTarget()
    local closest, dist = nil, FOVRadius
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    for _, player in pairs(Players:GetPlayers()) do
        if IsValidTarget(player) then
            local pos, onScreen = Camera:WorldToViewportPoint(player.Character[TargetPart].Position)
            if onScreen then
                local screenPos = Vector2.new(pos.X, pos.Y)
                local d = (screenPos - center).Magnitude
                if d < dist then closest, dist = player, d end
            end
        end
    end
    return closest
end

AimbotTab:CreateToggle({
    Name = "Enable Aimbot",
    CurrentValue = false,
    Callback = function(Value)
        AimbotEnabled = Value
        CurrentTarget = nil
        FOVCircle.Visible = Value
        if Value then
            RunService.RenderStepped:Connect(function()
                if not AimbotEnabled then return end
                CurrentTarget = GetClosestTarget()
                if CurrentTarget and CurrentTarget.Character[TargetPart] then
                    Camera.CFrame = Camera.CFrame:lerp(CFrame.lookAt(Camera.CFrame.Position, CurrentTarget.Character[TargetPart].Position), 0.15)
                end
            end)
        end
    end
})

AimbotTab:CreateToggle({
    Name = "Team Check (Prisoners Same Team)",
    CurrentValue = false,
    Callback = function(Value)
        TeamCheck = Value
        CurrentTarget = nil
    end
})

AimbotTab:CreateSlider({
    Name = "FOV Radius",
    Range = {50, 500},
    Increment = 10,
    CurrentValue = 150,
    Callback = function(Value)
        FOVRadius = Value
        FOVCircle.Radius = Value
    end
})

AimbotTab:CreateDropdown({
    Name = "Target Part",
    Options = {"Head", "HumanoidRootPart"},
    CurrentOption = {"Head"},
    Callback = function(Option)
        TargetPart = Option[1]
    end
})

-- // FOV TAB
local FOVTab = Window:CreateTab("FOV", 4483362458)
local FOVEnabled = false
local CustomFOV = 90
FOVTab:CreateToggle({
    Name = "Custom FOV",
    CurrentValue = false,
    Callback = function(Value)
        FOVEnabled = Value
        Camera.FieldOfView = Value and CustomFOV or 70
    end
})
FOVTab:CreateSlider({
    Name = "FOV Value",
    Range = {30, 120},
    Increment = 1,
    CurrentValue = 90,
    Callback = function(Value)
        CustomFOV = Value
        if FOVEnabled then Camera.FieldOfView = Value end
    end
})

-- // TELEPORTS TAB
local TeleTab = Window:CreateTab("Teleports", 4483362458)
local locations = {
    ["Maintenance"] = CFrame.new(172.34, 23.10, -143.87),
    ["Security"] = CFrame.new(224.47, 23.10, -167.90),
    ["OC Lockers"] = CFrame.new(137.60, 23.10, -169.93),
    ["Riot Lockers"] = CFrame.new(165.63, 23.10, -192.25),
    ["Vent"] = CFrame.new(76.96, -7.02, -19.21),
    ["Maximum"] = CFrame.new(101.84, -8.82, -141.41),
    ["Generator"] = CFrame.new(100.95, -8.82, -57.59),
    ["Outside"] = CFrame.new(350.22, 5.40, -171.09),
    ["Escapee Base"] = CFrame.new(749.02, -0.97, -470.45),
    ["Escapee"] = CFrame.new(307.06, 5.40, -177.88),
    ["Keycard"] = CFrame.new(-13.36, 22.13, -27.47)
}
for name, cf in pairs(locations) do
    TeleTab:CreateButton({
        Name = name,
        Callback = function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = cf
            end
        end
    })
end

-- // ITEMS TAB
local ItemsTab = Window:CreateTab("Items", 4483362458)
ItemsTab:CreateButton({
    Name = "Get Fake Keycard",
    Callback = function()
        local player = LocalPlayer
        if not table.find(prisonerTeams, player.Team.Name) then
            Rayfield:Notify({Title = "Denied", Content = "Prisoners only!", Duration = 3})
            return
        end
        local function findKeycard()
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj:IsA("Tool") and string.find(string.lower(obj.Name), "keycard") then
                    local clone = obj:Clone()
                    clone.Parent = player.Backpack
                    player.Character.Humanoid:EquipTool(clone)
                    Rayfield:Notify({Title = "Success", Content = "Keycard got!", Duration = 3})
                    return true
                end
            end
            return false
        end
        if not findKeycard() then Rayfield:Notify({Title = "Error", Content = "Keycard not found!", Duration = 3}) end
    end
})

-- // STAMINA TAB
local StaminaTab = Window:CreateTab("Stamina", 4483362458)
local infStam = false
StaminaTab:CreateButton({
    Name = "Infinite Stamina",
    Callback = function()
        infStam = not infStam
        local sv = LocalPlayer:FindFirstChild("ServerVariables")
        if sv and sv:FindFirstChild("Sprint") then
            local stam = sv.Sprint:FindFirstChild("Stamina")
            local maxStam = sv.Sprint:FindFirstChild("MaxStamina")
            if stam and maxStam then
                if infStam then
                    RunService.RenderStepped:Connect(function()
                        if infStam then stam.Value = maxStam.Value end
                    end)
                    Rayfield:Notify({Title = "On", Content = "Inf Stamina!", Duration = 3})
                else
                    Rayfield:Notify({Title = "Off", Content = "Stamina normal.", Duration = 3})
                end
            end
        else
            Rayfield:Notify({Title = "Error", Content = "Stamina not found!", Duration = 3})
        end
    end
})

print("✅ Light Script loaded! Check console for issues.")
