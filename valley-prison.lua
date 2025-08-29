-- // UI LIBRARY
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Create the Window with KeySystem enabled
local Window = Rayfield:CreateWindow({
    Name = "Valley Prison ByX",
    LoadingTitle = "Valley Prison ByX",
    LoadingSubtitle = ".",
    ConfigurationSaving = {
        Enabled = false
    },
    Discord = {
        Enabled = false
    },
    KeySystem = true, -- Enable KeySystem
    KeySettings = {
        Title = "ByX",
        Subtitle = "Enter the key to unlock the script",
        Note = ".", -- You can remove this if you don’t want to show the key
        Key = "BYXVALLYPRISON2025", -- Key
        SaveKey = false, -- Don’t save the key automatically
        WrongKeyMessage = "Incorrect key! Please try again.",
        CorrectKeyMessage = "Script unlocked successfully!"
    }
})

--[[ 
Theme Customization Note:
- Rayfield may not support direct color changes via code.
- Desired colors: 
  - Light Cyan: Color3.fromRGB(102, 204, 255) (#66CCFF)
  - Purple: Color3.fromRGB(204, 102, 255) (#CC66FF)
- Check Rayfield documentation (https://sirius.menu/rayfield) for theme customization options.
- If you want to customize button or text colors in the ESP section, let me know, and I can add that manually.
]]

-- // ESP SECTION
local ESPTab = Window:CreateTab("ESP", 4483362458)
-- Attempt to customize Tab color if supported
-- ESPTab.BackgroundColor = Color3.fromRGB(102, 204, 255) -- Light Cyan
-- ESPTab.TextColor = Color3.fromRGB(204, 102, 255) -- Purple

local ESPEnabled = false
local ESPObjects = {}

function CreateESP(player)
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local highlight = Instance.new("Highlight")
        highlight.Parent = player.Character
        highlight.Adornee = player.Character
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.FillTransparency = 0.3
        highlight.OutlineTransparency = 1

        -- Use the player’s team color if available
        if player.Team and player.Team.TeamColor then
            highlight.FillColor = player.Team.TeamColor.Color
        else
            highlight.FillColor = Color3.fromRGB(255, 255, 255) -- Default white color
        end

        ESPObjects[player] = highlight
    end
end

function RemoveESP(player)
    if ESPObjects[player] then
        ESPObjects[player]:Destroy()
        ESPObjects[player] = nil
    end
end

game.Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        if ESPEnabled then
            task.wait(1)
            CreateESP(player)
        end
    end)
end)

game.Players.PlayerRemoving:Connect(function(player)
    RemoveESP(player)
end)

local espToggle = ESPTab:CreateToggle({
    Name = "Enable ESP",
    CurrentValue = false,
    Flag = "ESP_TOGGLE",
    Callback = function(Value)
        ESPEnabled = Value
        if ESPEnabled then
            for _, player in pairs(game.Players:GetPlayers()) do
                if player ~= game.Players.LocalPlayer then
                    CreateESP(player)
                end
            end
        else
            for _, highlight in pairs(ESPObjects) do
                highlight:Destroy()
            end
            ESPObjects = {}
        end
    end
})

-- // TELEPORT SECTION (Left in Arabic as requested)
local TeleportTab = Window:CreateTab("Teleports", 4483362458)
-- Attempt to customize Tab color if supported
-- TeleportTab.BackgroundColor = Color3.fromRGB(102, 204, 255) -- Light Cyan
-- TeleportTab.TextColor = Color3.fromRGB(204, 102, 255) -- Purple

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
            game.Players.LocalPlayer.Character:PivotTo(cf)
        end
    })
end

-- // Escapee Button
TeleportTab:CreateButton({
    Name = "Escapee",
    Callback = function()
        game.Players.LocalPlayer.Character:PivotTo(CFrame.new(307.06, 5.40, -177.88))
    end,
    TextColor = Color3.fromRGB(255, 0, 0) -- Red text
})

-- // 💳 Button
TeleportTab:CreateButton({
    Name = "Keycard 💳 ",
    Callback = function()
        game.Players.LocalPlayer.Character:PivotTo(CFrame.new(-12.13, 22.13, -27.36))
    end
})

print("✅ Script loaded successfully!")