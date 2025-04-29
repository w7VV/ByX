local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local TextChatService = game:GetService("TextChatService")
local TweenService = game:GetService("TweenService")

-- وظيفة تنظيف اسم اللاعب
local function cleanPlayerName(name)
    name = string.gsub(name, "^%s*(.-)%s*$", "%1") -- إزالة المسافات في البداية والنهاية
    name = string.gsub(name, "[^%w_]", "") -- إزالة أي حروف خاصة (يسمح فقط بالحروف، الأرقام، و _)
    return name
end

-- وظيفة البحث عن اللاعب
local function findPlayer(partialName)
    if partialName == "" then 
        return {LocalPlayer.Name} 
    end
    
    local playerNames = {}
    for name in string.gmatch(partialName, "[^,]+") do
        name = cleanPlayerName(name)
        if name == "" then continue end
        local found = false
        for _, p in pairs(Players:GetPlayers()) do
            local cleanedPlayerName = cleanPlayerName(p.Name)
            local cleanedDisplayName = p.DisplayName and cleanPlayerName(p.DisplayName) or ""
            local lowerSearchName = string.lower(name)
            if string.lower(cleanedPlayerName):find(lowerSearchName) or (p.DisplayName and string.lower(cleanedDisplayName):find(lowerSearchName)) then
                table.insert(playerNames, p.Name)
                found = true
                break
            end
        end
        if not found then
            table.insert(playerNames, name)
        end
    end
    return playerNames
end

-- وظيفة لإرسال رسالة إلى الشات
local function sendMessageToChat(message)
    if message == "" then return false end

    local chatService = game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents")
    if chatService then
        local sayMessageRequest = chatService:FindFirstChild("SayMessageRequest")
        if sayMessageRequest then
            sayMessageRequest:FireServer(message, "All")
            wait(0.1)
            return true
        end
    end

    if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
        local textChannels = TextChatService:FindFirstChild("TextChannels")
        if textChannels then
            local channel = textChannels:FindFirstChild("RBXGeneral") or textChannels:FindFirstChildWhichIsA("TextChatChannel")
            if channel then
                channel:SendAsync(message)
                wait(0.1)
                return true
            end
        end
    end

    return false
end

-- وظيفة للحصول على معلومات اللاعب
local function getPlayerInfo(playerObj)
    local userId = playerObj.UserId
    local info = {}
    info.userId = userId
    info.displayName = playerObj.DisplayName
    info.username = playerObj.Name
    local success, result = pcall(function()
        return game:GetService("Players"):GetHumanoidDescriptionFromUserId(userId)
    end)
    if success then
        info.creationDate = os.date("%Y-%m-%d", playerObj.AccountAge * 86400 + os.time())
    else
        info.creationDate = "غير متوفر"
    end
    info.thumbnailUrl = string.format("https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=420&height=420&format=png", userId)
    return info
end

-- إنشاء الواجهة
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = PlayerGui
ScreenGui.ResetOnSpawn = false

-- الصفحة الرئيسية (Page1)
local Page1 = Instance.new("Frame", ScreenGui)
Page1.Name = "Page1"
Page1.Size = UDim2.new(0, 300, 0, 200)
Page1.Position = UDim2.new(0.5, -150, 0.5, -100)
Page1.BackgroundColor3 = Color3.fromRGB(60, 0, 0) -- لون الخلفية الأحمر الداكن
Page1.BackgroundTransparency = 0.2
Page1.Visible = true

-- تأثير النيون للـ Frame
local StrokeInner = Instance.new("UIStroke", Page1)
StrokeInner.Color = Color3.fromRGB(0, 170, 255)
StrokeInner.Thickness = 10
StrokeInner.Transparency = 0
StrokeInner.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local StrokeOuter = Instance.new("UIStroke", Page1)
StrokeOuter.Color = Color3.fromRGB(0, 170, 255)
StrokeOuter.Thickness = 20
StrokeOuter.Transparency = 0.5
StrokeOuter.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

-- صورة الأفاتار في الصفحة الرئيسية
local AvatarImage = Instance.new("ImageLabel", Page1)
AvatarImage.Size = UDim2.new(0, 80, 0, 80)
AvatarImage.Position = UDim2.new(0, 10, 0, 10)
AvatarImage.BackgroundTransparency = 1
AvatarImage.Image = getPlayerInfo(LocalPlayer).thumbnailUrl
AvatarImage.ZIndex = 2

-- نص العنوان في الصفحة الرئيسية
local TitleText = Instance.new("TextLabel", Page1)
TitleText.Size = UDim2.new(0, 200, 0, 30)
TitleText.Position = UDim2.new(0.5, -100, 0, 10)
TitleText.BackgroundTransparency = 1
TitleText.Text = "حووقه : 6RB"
TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleText.Font = Enum.Font.Gotham
TitleText.TextSize = 20
TitleText.TextXAlignment = Enum.TextXAlignment.Right
TitleText.ZIndex = 2

-- نص الترحيب في الصفحة الرئيسية
local WelcomeText = Instance.new("TextLabel", Page1)
WelcomeText.Size = UDim2.new(1, -20, 0, 50)
WelcomeText.Position = UDim2.new(0, 10, 0, 50)
WelcomeText.BackgroundTransparency = 1
WelcomeText.Text = "الاستخدام مع اللاعبين ممنوع"
WelcomeText.TextColor3 = Color3.fromRGB(255, 255, 255)
WelcomeText.Font = Enum.Font.Gotham
WelcomeText.TextSize = 24
WelcomeText.TextWrapped = true
WelcomeText.TextXAlignment = Enum.TextXAlignment.Right
WelcomeText.ZIndex = 2

-- زر الإغلاق في الصفحة الرئيسية
local CloseButton = Instance.new("TextButton", Page1)
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(1, -40, 0, 10)
CloseButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Text = "إغلاق"
CloseButton.TextColor3 = Color3.fromRGB(0, 0, 0)
CloseButton.TextSize = 14
CloseButton.ZIndex = 3
CloseButton.TextScaled = true

-- زر "الأوامر" في الصفحة الرئيسية
local CommandsButton = Instance.new("TextButton", Page1)
CommandsButton.Size = UDim2.new(0, 100, 0, 40)
CommandsButton.Position = UDim2.new(0, 10, 1, -50)
CommandsButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
CommandsButton.Text = "الأوامر"
CommandsButton.TextColor3 = Color3.fromRGB(0, 0, 0)
CommandsButton.TextSize = 18
CommandsButton.ZIndex = 3
CommandsButton.TextScaled = true

-- زر "المعلومات" في الصفحة الرئيسية
local InfoButton = Instance.new("TextButton", Page1)
InfoButton.Size = UDim2.new(0, 100, 0, 40)
InfoButton.Position = UDim2.new(1, -110, 1, -50)
InfoButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
InfoButton.Text = "المعلومات"
InfoButton.TextColor3 = Color3.fromRGB(0, 0, 0)
InfoButton.TextSize = 18
InfoButton.ZIndex = 3
InfoButton.TextScaled = true

-- الصفحة الثانية (المعلومات - Page2)
local Page2 = Instance.new("Frame", ScreenGui)
Page2.Name = "Page2"
Page2.Size = UDim2.new(0, 300, 0, 200)
Page2.Position = UDim2.new(0.5, -150, 0.5, -100)
Page2.BackgroundColor3 = Color3.fromRGB(60, 0, 0)
Page2.BackgroundTransparency = 0.2
Page2.Visible = false

-- تأثير النيون للـ Page2
local StrokeInnerPage2 = Instance.new("UIStroke", Page2)
StrokeInnerPage2.Color = Color3.fromRGB(0, 170, 255)
StrokeInnerPage2.Thickness = 10
StrokeInnerPage2.Transparency = 0
StrokeInnerPage2.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local StrokeOuterPage2 = Instance.new("UIStroke", Page2)
StrokeOuterPage2.Color = Color3.fromRGB(0, 170, 255)
StrokeOuterPage2.Thickness = 20
StrokeOuterPage2.Transparency = 0.5
StrokeOuterPage2.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

-- صورة الأفاتار في صفحة المعلومات
local AvatarImagePage2 = Instance.new("ImageLabel", Page2)
AvatarImagePage2.Size = UDim2.new(0, 80, 0, 80)
AvatarImagePage2.Position = UDim2.new(0, 10, 0, 10)
AvatarImagePage2.BackgroundTransparency = 1
AvatarImagePage2.Image = getPlayerInfo(LocalPlayer).thumbnailUrl
AvatarImagePage2.ZIndex = 2

-- نص العنوان في صفحة المعلومات
local TitleTextPage2 = Instance.new("TextLabel", Page2)
TitleTextPage2.Size = UDim2.new(0, 200, 0, 30)
TitleTextPage2.Position = UDim2.new(0.5, -100, 0, 10)
TitleTextPage2.BackgroundTransparency = 1
TitleTextPage2.Text = "حووقه : 6RB"
TitleTextPage2.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleTextPage2.Font = Enum.Font.Gotham
TitleTextPage2.TextSize = 20
TitleTextPage2.TextXAlignment = Enum.TextXAlignment.Right
TitleTextPage2.ZIndex = 2

-- نص المعلومات بدل الحقوق والتحذير
local InfoText = Instance.new("TextLabel", Page2)
InfoText.Size = UDim2.new(1, -20, 0, 100)
InfoText.Position = UDim2.new(0, 10, 0, 50)
InfoText.BackgroundTransparency = 1
InfoText.TextColor3 = Color3.fromRGB(255, 255, 255)
InfoText.Font = Enum.Font.Gotham
InfoText.TextSize = 18
InfoText.TextWrapped = true
InfoText.TextXAlignment = Enum.TextXAlignment.Right
InfoText.ZIndex = 2

-- ملء نص المعلومات
local playerInfo = getPlayerInfo(LocalPlayer)
InfoText.Text = string.format(
    "معلوماتك:\n\nالاسم: %s\nاسم العرض: %s\nالمعرف: %d\nتاريخ الإنشاء: %s",
    playerInfo.username, playerInfo.displayName, playerInfo.userId, playerInfo.creationDate
)

-- زر الرجوع في صفحة المعلومات
local BackButtonPage2 = Instance.new("TextButton", Page2)
BackButtonPage2.Size = UDim2.new(0, 100, 0, 40)
BackButtonPage2.Position = UDim2.new(0, 10, 1, -50)
BackButtonPage2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
BackButtonPage2.Text = "رجوع"
BackButtonPage2.TextColor3 = Color3.fromRGB(0, 0, 0)
BackButtonPage2.TextSize = 18
BackButtonPage2.ZIndex = 3
BackButtonPage2.TextScaled = true

-- زر "الأوامر" في صفحة المعلومات
local CommandsButtonPage2 = Instance.new("TextButton", Page2)
CommandsButtonPage2.Size = UDim2.new(0, 100, 0, 40)
CommandsButtonPage2.Position = UDim2.new(1, -110, 1, -50)
CommandsButtonPage2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
CommandsButtonPage2.Text = "الأوامر"
CommandsButtonPage2.TextColor3 = Color3.fromRGB(0, 0, 0)
CommandsButtonPage2.TextSize = 18
CommandsButtonPage2.ZIndex = 3
CommandsButtonPage2.TextScaled = true

-- الصفحة الثالثة (الأوامر - Page3)
local Page3 = Instance.new("Frame", ScreenGui)
Page3.Name = "Page3"
Page3.Size = UDim2.new(0, 300, 0, 200)
Page3.Position = UDim2.new(0.5, -150, 0.5, -100)
Page3.BackgroundColor3 = Color3.fromRGB(60, 0, 0)
Page3.BackgroundTransparency = 0.2
Page3.Visible = false

-- تأثير النيون للـ Page3
local StrokeInnerPage3 = Instance.new("UIStroke", Page3)
StrokeInnerPage3.Color = Color3.fromRGB(0, 170, 255)
StrokeInnerPage3.Thickness = 10
StrokeInnerPage3.Transparency = 0
StrokeInnerPage3.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local StrokeOuterPage3 = Instance.new("UIStroke", Page3)
StrokeOuterPage3.Color = Color3.fromRGB(0, 170, 255)
StrokeOuterPage3.Thickness = 20
StrokeOuterPage3.Transparency = 0.5
StrokeOuterPage3.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

-- صورة الأفاتار في صفحة الأوامر
local AvatarImagePage3 = Instance.new("ImageLabel", Page3)
AvatarImagePage3.Size = UDim2.new(0, 80, 0, 80)
AvatarImagePage3.Position = UDim2.new(0, 10, 0, 10)
AvatarImagePage3.BackgroundTransparency = 1
AvatarImagePage3.Image = getPlayerInfo(LocalPlayer).thumbnailUrl
AvatarImagePage3.ZIndex = 2

-- نص العنوان في صفحة الأوامر
local TitleTextPage3 = Instance.new("TextLabel", Page3)
TitleTextPage3.Size = UDim2.new(0, 200, 0, 30)
TitleTextPage3.Position = UDim2.new(0.5, -100, 0, 10)
TitleTextPage3.BackgroundTransparency = 1
TitleTextPage3.Text = "حووقه : 6RB"
TitleTextPage3.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleTextPage3.Font = Enum.Font.Gotham
TitleTextPage3.TextSize = 20
TitleTextPage3.TextXAlignment = Enum.TextXAlignment.Right
TitleTextPage3.ZIndex = 2

-- خانة إدخال اسم اللاعب
local NameBox = Instance.new("TextBox", Page3)
NameBox.Size = UDim2.new(1, -20, 0, 30)
NameBox.Position = UDim2.new(0, 10, 0, 50)
NameBox.PlaceholderText = "اسم اللاعب (اختياري)"
NameBox.Text = LocalPlayer.Name
NameBox.TextSize = 16
NameBox.TextColor3 = Color3.fromRGB(255, 255, 255)
NameBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
NameBox.TextXAlignment = Enum.TextXAlignment.Right
NameBox.ZIndex = 3
NameBox.TextScaled = true
NameBox.TextWrapped = true

-- أزرار الأوامر
local KillButton = Instance.new("TextButton", Page3)
KillButton.Size = UDim2.new(0, 80, 0, 30)
KillButton.Position = UDim2.new(0, 10, 0, 90)
KillButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
KillButton.Text = "Kill"
KillButton.TextColor3 = Color3.fromRGB(0, 0, 0)
KillButton.TextSize = 18
KillButton.ZIndex = 3
KillButton.TextScaled = true

local IceButton = Instance.new("TextButton", Page3)
IceButton.Size = UDim2.new(0, 80, 0, 30)
IceButton.Position = UDim2.new(0, 100, 0, 90)
IceButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
IceButton.Text = "Ice"
IceButton.TextColor3 = Color3.fromRGB(0, 0, 0)
IceButton.TextSize = 18
IceButton.ZIndex = 3
IceButton.TextScaled = true

local JailButton = Instance.new("TextButton", Page3)
JailButton.Size = UDim2.new(0, 80, 0, 30)
JailButton.Position = UDim2.new(0, 190, 0, 90)
JailButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
JailButton.Text = "Jail"
JailButton.TextColor3 = Color3.fromRGB(0, 0, 0)
JailButton.TextSize = 18
JailButton.ZIndex = 3
JailButton.TextScaled = true

-- زر الرجوع في صفحة الأوامر
local BackButtonPage3 = Instance.new("TextButton", Page3)
BackButtonPage3.Size = UDim2.new(0, 100, 0, 40)
BackButtonPage3.Position = UDim2.new(0, 10, 1, -50)
BackButtonPage3.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
BackButtonPage3.Text = "رجوع"
BackButtonPage3.TextColor3 = Color3.fromRGB(0, 0, 0)
BackButtonPage3.TextSize = 18
BackButtonPage3.ZIndex = 3
BackButtonPage3.TextScaled = true

-- زر "المعلومات" في صفحة الأوامر
local InfoButtonPage3 = Instance.new("TextButton", Page3)
InfoButtonPage3.Size = UDim2.new(0, 100, 0, 40)
InfoButtonPage3.Position = UDim2.new(1, -110, 1, -50)
InfoButtonPage3.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
InfoButtonPage3.Text = "المعلومات"
InfoButtonPage3.TextColor3 = Color3.fromRGB(0, 0, 0)
InfoButtonPage3.TextSize = 18
InfoButtonPage3.ZIndex = 3
InfoButtonPage3.TextScaled = true

-- وظيفة التنقل بين الصفحات
local function showPage(page)
    Page1.Visible = (page == Page1)
    Page2.Visible = (page == Page2)
    Page3.Visible = (page == Page3)
end

-- ربط الأزرار بالتنقل
CommandsButton.MouseButton1Click:Connect(function()
    showPage(Page3)
end)

InfoButton.MouseButton1Click:Connect(function()
    showPage(Page2)
end)

BackButtonPage2.MouseButton1Click:Connect(function()
    showPage(Page1)
end)

CommandsButtonPage2.MouseButton1Click:Connect(function()
    showPage(Page3)
end)

BackButtonPage3.MouseButton1Click:Connect(function()
    showPage(Page1)
end)

InfoButtonPage3.MouseButton1Click:Connect(function()
    showPage(Page2)
end)

CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- ربط أزرار الأوامر
KillButton.MouseButton1Click:Connect(function()
    local playerNames = findPlayer(NameBox.Text)
    for _, playerName in ipairs(playerNames) do
        local command = ";kill " .. playerName
        sendMessageToChat(command)
    end
end)

IceButton.MouseButton1Click:Connect(function()
    local playerNames = findPlayer(NameBox.Text)
    for _, playerName in ipairs(playerNames) do
        local command = ";ice " .. playerName
        sendMessageToChat(command)
    end
end)

JailButton.MouseButton1Click:Connect(function()
    local playerNames = findPlayer(NameBox.Text)
    for _, playerName in ipairs(playerNames) do
        local command = ";jail " .. playerName
        sendMessageToChat(command)
    end
end)
