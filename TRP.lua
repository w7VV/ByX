local Player = game:GetService("Players").LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- إعدادات أساسية
local isAimbotActive = false
local isUIVisible = true
local isESPActive = false
local TargetPart = "Head"
local circleVisible = true

-- متغيرات الدائرة
local FOVCircle = nil

-- مستويات القوة
local strengthPresets = {
    {level=1, name="خفيف", smoothness=0.3, fov=100, desc="سلاسة عالية و قوي  - مناسب للمبتدئين"},
    {level=2, name="متوسط", smoothness=0.15, fov=150, desc="توازن بين السلاسة والدقة (إفتراضي)"},
    {level=3, name="قوي", smoothness=0.07, fov=200, desc="دقة عالية - للمحترفين"}
}
local currentStrength = 2

-- إنشاء الواجهة الرئيسية
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
ScreenGui.Name = "ArceusAimbotUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- زر التصغير/التكبير
local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "MinimizeButton"
ToggleButton.Size = UDim2.new(0, 40, 0, 40)
ToggleButton.Position = UDim2.new(0.95, -40, 0.05, 0)
ToggleButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ToggleButton.BorderSizePixel = 0
ToggleButton.Text = "≡"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 20
ToggleButton.ZIndex = 100
ToggleButton.Parent = ScreenGui

-- الواجهة الرئيسية
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainUI"
MainFrame.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
MainFrame.BorderColor3 = Color3.fromRGB(16, 16, 16)
MainFrame.Position = UDim2.new(0.3, 0, 0.3, 0)
MainFrame.Size = UDim2.new(0, 320, 0, 350)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Visible = true
MainFrame.Parent = ScreenGui

-- إطار العنوان
local TitleFrame = Instance.new("Frame")
TitleFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
TitleFrame.Size = UDim2.new(1, 0, 0, 35)
TitleFrame.BorderSizePixel = 0
TitleFrame.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Text = "⚡ TRP AIMBOT ⚡"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Size = UDim2.new(1, 0, 1, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.TextSize = 18
TitleLabel.Parent = TitleFrame

-- زر التفعيل
local AimbotToggle = Instance.new("TextButton")
AimbotToggle.Position = UDim2.new(0.05, 0, 0.15, 0)
AimbotToggle.Size = UDim2.new(0, 35, 0, 35)
AimbotToggle.Text = ""
AimbotToggle.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
AimbotToggle.AutoButtonColor = false
local UICorner2 = Instance.new("UICorner")
UICorner2.CornerRadius = UDim.new(0.5, 0)
UICorner2.Parent = AimbotToggle
AimbotToggle.Parent = MainFrame

local AimbotLabel = Instance.new("TextLabel")
AimbotLabel.Position = UDim2.new(0.25, 0, 0.15, 0)
AimbotLabel.Size = UDim2.new(0, 150, 0, 35)
AimbotLabel.Text = "Aimbot: OFF"
AimbotLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
AimbotLabel.BackgroundTransparency = 1
AimbotLabel.TextXAlignment = Enum.TextXAlignment.Left
AimbotLabel.Font = Enum.Font.SourceSansSemibold
AimbotLabel.TextSize = 16
AimbotLabel.Parent = MainFrame

-- زر ESP
local ESPToggle = Instance.new("TextButton")
ESPToggle.Position = UDim2.new(0.05, 0, 0.3, 0)
ESPToggle.Size = UDim2.new(0, 35, 0, 35)
ESPToggle.Text = ""
ESPToggle.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
ESPToggle.AutoButtonColor = false
local UICorner3 = Instance.new("UICorner")
UICorner3.CornerRadius = UDim.new(0.5, 0)
UICorner3.Parent = ESPToggle
ESPToggle.Parent = MainFrame

local ESPLabel = Instance.new("TextLabel")
ESPLabel.Position = UDim2.new(0.25, 0, 0.3, 0)
ESPLabel.Size = UDim2.new(0, 150, 0, 35)
ESPLabel.Text = "ESP: OFF"
ESPLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
ESPLabel.BackgroundTransparency = 1
ESPLabel.TextXAlignment = Enum.TextXAlignment.Left
ESPLabel.Font = Enum.Font.SourceSansSemibold
ESPLabel.TextSize = 16
ESPLabel.Parent = MainFrame

-- زر إعادة إنشاء الدائرة
local RegenButton = Instance.new("TextButton")
RegenButton.Position = UDim2.new(0.05, 0, 0.45, 0)
RegenButton.Size = UDim2.new(0, 35, 0, 35)
RegenButton.Text = "↻"
RegenButton.BackgroundColor3 = Color3.fromRGB(0, 150, 150)
RegenButton.TextColor3 = Color3.fromRGB(255, 255, 255)
RegenButton.TextSize = 20
local UICorner4 = Instance.new("UICorner")
UICorner4.CornerRadius = UDim.new(0.5, 0)
UICorner4.Parent = RegenButton
RegenButton.Parent = MainFrame

local RegenLabel = Instance.new("TextLabel")
RegenLabel.Position = UDim2.new(0.25, 0, 0.45, 0)
RegenLabel.Size = UDim2.new(0, 150, 0, 35)
RegenLabel.Text = "إعادة إنشاء الدائرة"
RegenLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
RegenLabel.BackgroundTransparency = 1
RegenLabel.TextXAlignment = Enum.TextXAlignment.Left
RegenLabel.Font = Enum.Font.SourceSansSemibold
RegenLabel.TextSize = 16
RegenLabel.Parent = MainFrame

-- إعدادات القوة
local StrengthFrame = Instance.new("Frame")
StrengthFrame.BackgroundTransparency = 1
StrengthFrame.Size = UDim2.new(0.9, 0, 0, 150)
StrengthFrame.Position = UDim2.new(0.05, 0, 0.55, 0)
StrengthFrame.Parent = MainFrame

local StrengthTitle = Instance.new("TextLabel")
StrengthTitle.Text = "مستوى القوة:"
StrengthTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
StrengthTitle.Size = UDim2.new(1, 0, 0, 25)
StrengthTitle.BackgroundTransparency = 1
StrengthTitle.TextXAlignment = Enum.TextXAlignment.Left
StrengthTitle.Font = Enum.Font.SourceSansSemibold
StrengthTitle.TextSize = 16
StrengthTitle.Parent = StrengthFrame

local CurrentStrength = Instance.new("TextLabel")
CurrentStrength.Text = strengthPresets[currentStrength].name
CurrentStrength.TextColor3 = Color3.fromRGB(0, 255, 255)
CurrentStrength.Size = UDim2.new(1, 0, 0, 30)
CurrentStrength.Position = UDim2.new(0, 0, 0.2, 0)
CurrentStrength.BackgroundTransparency = 1
CurrentStrength.TextXAlignment = Enum.TextXAlignment.Left
CurrentStrength.Font = Enum.Font.SourceSansBold
CurrentStrength.TextSize = 18
CurrentStrength.Parent = StrengthFrame

local StrengthDesc = Instance.new("TextLabel")
StrengthDesc.Text = strengthPresets[currentStrength].desc
StrengthDesc.TextColor3 = Color3.fromRGB(200, 200, 0)
StrengthDesc.Size = UDim2.new(1, 0, 0, 50)
StrengthDesc.Position = UDim2.new(0, 0, 0.4, 0)
StrengthDesc.BackgroundTransparency = 1
StrengthDesc.TextXAlignment = Enum.TextXAlignment.Left
StrengthDesc.TextWrapped = true
StrengthDesc.Font = Enum.Font.SourceSans
StrengthDesc.TextSize = 14
StrengthDesc.Parent = StrengthFrame

local ControlsFrame = Instance.new("Frame")
ControlsFrame.BackgroundTransparency = 1
ControlsFrame.Size = UDim2.new(1, 0, 0, 40)
ControlsFrame.Position = UDim2.new(0, 0, 0.8, 0)
ControlsFrame.Parent = StrengthFrame

local DecreaseBtn = Instance.new("TextButton")
DecreaseBtn.Text = "-"
DecreaseBtn.Size = UDim2.new(0, 40, 0, 40)
DecreaseBtn.Position = UDim2.new(0, 0, 0, 0)
DecreaseBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
DecreaseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
DecreaseBtn.Font = Enum.Font.SourceSansBold
DecreaseBtn.TextSize = 20
DecreaseBtn.Parent = ControlsFrame

local StrengthLevel = Instance.new("TextLabel")
StrengthLevel.Text = "المستوى: " .. currentStrength
StrengthLevel.TextColor3 = Color3.fromRGB(255, 255, 255)
StrengthLevel.Size = UDim2.new(0, 100, 0, 40)
StrengthLevel.Position = UDim2.new(0.35, 0, 0, 0)
StrengthLevel.BackgroundTransparency = 1
StrengthLevel.Font = Enum.Font.SourceSansSemibold
StrengthLevel.TextSize = 16
StrengthLevel.Parent = ControlsFrame

local IncreaseBtn = Instance.new("TextButton")
IncreaseBtn.Text = "+"
IncreaseBtn.Size = UDim2.new(0, 40, 0, 40)
IncreaseBtn.Position = UDim2.new(0.7, 0, 0, 0)
IncreaseBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
IncreaseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
IncreaseBtn.Font = Enum.Font.SourceSansBold
IncreaseBtn.TextSize = 20
IncreaseBtn.Parent = ControlsFrame

-- دوال ESP
local highlights = {}

local function createHighlight(player)
    if player == Player or not player.Character then return end
    
    local char = player.Character
    if char:FindFirstChild("ESP_Highlight") then return end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.Adornee = char
    highlight.FillTransparency = 1
    highlight.OutlineTransparency = 0
    highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
    highlight.Parent = char
    
    highlights[player] = highlight
    
    task.spawn(function()
        local t = 0
        while highlight and highlight.Parent and isESPActive do
            t = t + RunService.Heartbeat:Wait()
            local r = math.sin(t * 2) * 0.5 + 0.5
            local g = math.sin(t * 2 + 2) * 0.5 + 0.5
            local b = math.sin(t * 2 + 4) * 0.5 + 0.5
            highlight.OutlineColor = Color3.new(r, g, b)
        end
    end)
end

local function startESP()
    isESPActive = true
    ESPToggle.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
    ESPLabel.Text = "ESP: ON"
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= Player then
            if player.Character then
                createHighlight(player)
            end
            player.CharacterAdded:Connect(function(char)
                wait(1)
                if isESPActive then
                    createHighlight(player)
                end
            end)
        end
    end
end

local function stopESP()
    isESPActive = false
    ESPToggle.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
    ESPLabel.Text = "ESP: OFF"
    
    for player, highlight in pairs(highlights) do
        if highlight and highlight.Parent then
            highlight:Destroy()
        end
    end
    highlights = {}
end

-- دوال FOV وAimbot
local function createFOVCircle()
    if FOVCircle then 
        pcall(function() FOVCircle:Remove() end) 
    end
    
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Visible = isAimbotActive
    FOVCircle.Radius = strengthPresets[currentStrength].fov
    FOVCircle.Color = Color3.fromRGB(255, 0, 0)
    FOVCircle.Thickness = 2
    FOVCircle.Filled = false
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
end

local function GetClosestPlayerInFOV()
    if not FOVCircle then return nil end
    
    local closestPlayer = nil
    local shortestDistance = FOVCircle.Radius
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Player and player.Character and player.Character:FindFirstChild(TargetPart) then
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

local function updateStrengthDisplay()
    local preset = strengthPresets[currentStrength]
    CurrentStrength.Text = preset.name
    StrengthDesc.Text = preset.desc
    StrengthLevel.Text = "المستوى: " .. currentStrength
    
    local strengthColors = {
        [1] = Color3.fromRGB(100, 255, 100),
        [2] = Color3.fromRGB(100, 200, 255),
        [3] = Color3.fromRGB(255, 150, 50)
    }
    CurrentStrength.TextColor3 = strengthColors[currentStrength]
    
    if FOVCircle then
        FOVCircle.Radius = preset.fov
    end
end

-- أحداث التحكم
ToggleButton.MouseButton1Click:Connect(function()
    isUIVisible = not isUIVisible
    MainFrame.Visible = isUIVisible
    ToggleButton.Text = isUIVisible and "≡" or "☰"
end)

AimbotToggle.MouseButton1Click:Connect(function()
    isAimbotActive = not isAimbotActive
    if isAimbotActive then
        AimbotToggle.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
        AimbotLabel.Text = "Aimbot: ON"
    else
        AimbotToggle.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
        AimbotLabel.Text = "Aimbot: OFF"
    end
    if FOVCircle then
        FOVCircle.Visible = isAimbotActive
    end
end)

ESPToggle.MouseButton1Click:Connect(function()
    if isESPActive then
        stopESP()
    else
        startESP()
    end
end)

RegenButton.MouseButton1Click:Connect(function()
    createFOVCircle()
    if FOVCircle then
        FOVCircle.Visible = isAimbotActive
    end
    print("تم إعادة إنشاء الدائرة بنجاح!")
end)

IncreaseBtn.MouseButton1Click:Connect(function()
    currentStrength = math.min(#strengthPresets, currentStrength + 1)
    updateStrengthDisplay()
end)

DecreaseBtn.MouseButton1Click:Connect(function()
    currentStrength = math.max(1, currentStrength - 1)
    updateStrengthDisplay()
end)

-- التحديث المستمر
RunService.RenderStepped:Connect(function()
    if FOVCircle then
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        FOVCircle.Visible = isAimbotActive
        
        if isAimbotActive then
            local target = GetClosestPlayerInFOV()
            if target and target.Character and target.Character:FindFirstChild(TargetPart) then
                local targetPos = target.Character[TargetPart].Position
                local currentCFrame = Camera.CFrame
                local targetCFrame = CFrame.new(currentCFrame.Position, targetPos)
                Camera.CFrame = currentCFrame:Lerp(targetCFrame, strengthPresets[currentStrength].smoothness)
            end
        end
    end
end)

-- إعادة إنشاء عند الموت
Player.CharacterAdded:Connect(function()
    wait(0.5)
    createFOVCircle()
    if isESPActive then
        startESP()
    end
end)

-- التنظيف عند الخروج
Player.CharacterRemoving:Connect(function()
    if FOVCircle then
        FOVCircle:Remove()
    end
    stopESP()
end)

-- التهيئة الأولية
createFOVCircle()
updateStrengthDisplay()

-- متابعة اللاعبين الجدد للESP
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        wait(1)
        if isESPActive then
            createHighlight(player)
        end
    end)
end)

print("✅ تم تحميل السكربت بنجاح!")
