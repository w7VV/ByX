local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local TextChatService = game:GetService("TextChatService")

-- جدول لتخزين الأوامر المحددة والمفضلة
local selectedCommands = {}
local favoriteCommands = {}
local targetedPlayer = nil
local espEnabled = false
local espHighlight = nil
local spamEnabled = false
local spamThread = nil

-- وظيفة تنظيف اسم اللاعب
local function cleanPlayerName(name)
    name = string.gsub(name, "^%s*(.-)%s*$", "%1")
    name = string.gsub(name, "[^%w_]", "")
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

-- وظيفة للحصول على جميع اللاعبين
local function getAllPlayers()
    local playerNames = {}
    for _, p in pairs(Players:GetPlayers()) do
        table.insert(playerNames, p.Name)
    end
    return table.concat(playerNames, ", ")
end

-- وظيفة النسخ مع إشعار
local function copyToClipboard(text)
    local success, err = pcall(function()
        setclipboard(text)
    end)
    if success then
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "تم النسخ!",
            Text = text,
            Duration = 3
        })
    else
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "فشل النسخ",
            Text = "تعذر النسخ، تحقق من وحدة التحكم (F9)",
            Duration = 3
        })
    end
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

-- وظيفة لتفعيل/إيقاف الـ ESP
local function toggleESP(playerObj, enable)
    if not playerObj.Character then return end
    if enable then
        if espHighlight then espHighlight:Destroy() end
        espHighlight = Instance.new("Highlight")
        espHighlight.FillColor = Color3.fromRGB(255, 0, 0)
        espHighlight.OutlineColor = Color3.fromRGB(255, 255, 0)
        espHighlight.Adornee = playerObj.Character
        espHighlight.Parent = playerObj.Character
    else
        if espHighlight then
            espHighlight:Destroy()
            espHighlight = nil
        end
    end
end

-- إنشاء الواجهة
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = PlayerGui
ScreenGui.ResetOnSpawn = false

-- الـ Frame الرئيسي
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 400, 0, 300)
MainFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
MainFrame.BackgroundColor3 = Color3.fromRGB(60, 0, 0)
MainFrame.BackgroundTransparency = 0.2 -- شفافية الخلفية زي الصورة
MainFrame.ZIndex = 1

-- تأثير النيون للـ Frame
local StrokeInner = Instance.new("UIStroke", MainFrame)
StrokeInner.Color = Color3.fromRGB(0, 170, 255)
StrokeInner.Thickness = 10
StrokeInner.Transparency = 0
StrokeInner.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local StrokeOuter = Instance.new("UIStroke", MainFrame)
StrokeOuter.Color = Color3.fromRGB(0, 170, 255)
StrokeOuter.Thickness = 20
StrokeOuter.Transparency = 0.5
StrokeOuter.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

-- الصفحة الرئيسية (Page1)
local Page1 = Instance.new("Frame", MainFrame)
Page1.Name = "Page1"
Page1.Size = UDim2.new(1, 0, 1, 0)
Page1.Position = UDim2.new(0, 0, 0, 0)
Page1.BackgroundTransparency = 1
Page1.Visible = true
Page1.ZIndex = 2

-- صورة الأفاتار في الصفحة الرئيسية
local AvatarImage = Instance.new("ImageLabel", Page1)
AvatarImage.Size = UDim2.new(0, 80, 0, 80)
AvatarImage.Position = UDim2.new(0, 10, 0, 10)
AvatarImage.BackgroundTransparency = 1
AvatarImage.Image = getPlayerInfo(LocalPlayer).thumbnailUrl
AvatarImage.ImageTransparency = 0.3 -- الشفافية للصورة
AvatarImage.ZIndex = 2

-- نص العنوان في الصفحة الرئيسية
local TitleText = Instance.new("TextLabel", Page1)
TitleText.Size = UDim2.new(0, 200, 0, 30)
TitleText.Position = UDim2.new(0.5, -100, 0, 10)
TitleText.BackgroundTransparency = 1
TitleText.Text = "حووقه : 6rb"
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

-- زر "إغلاق" في الزاوية اليمنى العليا
local TopCloseButton = Instance.new("TextButton", Page1)
TopCloseButton.Size = UDim2.new(0, 30, 0, 30)
TopCloseButton.Position = UDim2.new(1, -40, 0, 10)
TopCloseButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TopCloseButton.Text = "إغلاق"
TopCloseButton.TextColor3 = Color3.fromRGB(0, 0, 0)
TopCloseButton.TextSize = 14
TopCloseButton.TextScaled = true
TopCloseButton.ZIndex = 3

-- القائمة الجانبية
local Sidebar = Instance.new("Frame", MainFrame)
Sidebar.Size = UDim2.new(0, 60, 1, 0)
Sidebar.Position = UDim2.new(0, 0, 0, 0)
Sidebar.BackgroundColor3 = Color3.fromRGB(40, 0, 0)
Sidebar.BackgroundTransparency = 0.2
Sidebar.ZIndex = 2

-- أزرار القائمة الجانبية
local CloseButton = Instance.new("TextButton", Sidebar)
CloseButton.Size = UDim2.new(0, 40, 0, 40)
CloseButton.Position = UDim2.new(0, 10, 0, 10)
CloseButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Text = "إغلاق"
CloseButton.TextColor3 = Color3.fromRGB(0, 0, 0)
CloseButton.TextSize = 14
CloseButton.TextScaled = true
CloseButton.ZIndex = 3

local SettingsButton = Instance.new("TextButton", Sidebar)
SettingsButton.Size = UDim2.new(0, 40, 0, 40)
SettingsButton.Position = UDim2.new(0, 10, 0, 60)
SettingsButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SettingsButton.Text = "إعدادات"
SettingsButton.TextColor3 = Color3.fromRGB(0, 0, 0)
SettingsButton.TextSize = 14
SettingsButton.TextScaled = true
SettingsButton.ZIndex = 3

local InfoSidebarButton = Instance.new("TextButton", Sidebar)
InfoSidebarButton.Size = UDim2.new(0, 40, 0, 40)
InfoSidebarButton.Position = UDim2.new(0, 10, 0, 110)
InfoSidebarButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
InfoSidebarButton.Text = "المعلومات"
InfoSidebarButton.TextColor3 = Color3.fromRGB(0, 0, 0)
InfoSidebarButton.TextSize = 14
InfoSidebarButton.TextScaled = true
InfoSidebarButton.ZIndex = 3

-- الصفحة الثانية (المعلومات - Page2)
local Page2 = Instance.new("Frame", MainFrame)
Page2.Name = "Page2"
Page2.Size = UDim2.new(0, 340, 0, 250)
Page2.Position = UDim2.new(0, 60, 0, 0)
Page2.BackgroundTransparency = 1
Page2.Visible = false
Page2.ZIndex = 2

-- صورة الأفاتار في صفحة المعلومات
local AvatarImagePage2 = Instance.new("ImageLabel", Page2)
AvatarImagePage2.Size = UDim2.new(0, 80, 0, 80)
AvatarImagePage2.Position = UDim2.new(0, 0, 0, 10)
AvatarImagePage2.BackgroundTransparency = 1
AvatarImagePage2.Image = getPlayerInfo(LocalPlayer).thumbnailUrl
AvatarImagePage2.ImageTransparency = 0.3 -- الشفافية للصورة
AvatarImagePage2.ZIndex = 2

-- نص العنوان في صفحة المعلومات
local TitleTextPage2 = Instance.new("TextLabel", Page2)
TitleTextPage2.Size = UDim2.new(0, 200, 0, 30)
TitleTextPage2.Position = UDim2.new(0.5, -100, 0, 10)
TitleTextPage2.BackgroundTransparency = 1
TitleTextPage2.Text = "حووقه : 6rb"
TitleTextPage2.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleTextPage2.Font = Enum.Font.Gotham
TitleTextPage2.TextSize = 20
TitleTextPage2.TextXAlignment = Enum.TextXAlignment.Right
TitleTextPage2.ZIndex = 2

-- نص المعلومات
local InfoText = Instance.new("TextLabel", Page2)
InfoText.Size = UDim2.new(1, -20, 0, 150)
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

-- الصفحة الثالثة (الأوامر - Page3)
local Page3 = Instance.new("Frame", MainFrame)
Page3.Name = "Page3"
Page3.Size = UDim2.new(0, 340, 0, 250)
Page3.Position = UDim2.new(0, 60, 0, 0)
Page3.BackgroundTransparency = 1
Page3.Visible = false
Page3.ZIndex = 2

-- صورة الأفاتار في صفحة الأوامر
local AvatarImagePage3 = Instance.new("ImageLabel", Page3)
AvatarImagePage3.Size = UDim2.new(0, 80, 0, 80)
AvatarImagePage3.Position = UDim2.new(0, 0, 0, 10)
AvatarImagePage3.BackgroundTransparency = 1
AvatarImagePage3.Image = getPlayerInfo(LocalPlayer).thumbnailUrl
AvatarImagePage3.ImageTransparency = 0.3 -- الشفافية للصورة
AvatarImagePage3.ZIndex = 2

-- نص العنوان في صفحة الأوامر
local TitleTextPage3 = Instance.new("TextLabel", Page3)
TitleTextPage3.Size = UDim2.new(0, 200, 0, 30)
TitleTextPage3.Position = UDim2.new(0.5, -100, 0, 10)
TitleTextPage3.BackgroundTransparency = 1
TitleTextPage3.Text = "حووقه : 6rb"
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

-- أزرار التصفية
local SelectBtn = Instance.new("TextButton", Page3)
SelectBtn.Size = UDim2.new(0.3, 0, 0, 25)
SelectBtn.Position = UDim2.new(0, 10, 0, 90)
SelectBtn.Text = "تحديد الأوامر"
SelectBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
SelectBtn.TextColor3 = Color3.new(1, 1, 1)
SelectBtn.Font = Enum.Font.SourceSansBold
SelectBtn.TextSize = 14
SelectBtn.ZIndex = 3
SelectBtn.TextScaled = true
SelectBtn.TextWrapped = true

local PlayerOnlyBtn = Instance.new("TextButton", Page3)
PlayerOnlyBtn.Size = UDim2.new(0.3, 0, 0, 25)
PlayerOnlyBtn.Position = UDim2.new(0.35, 0, 0, 90)
PlayerOnlyBtn.Text = "أوامر <player>"
PlayerOnlyBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 150)
PlayerOnlyBtn.TextColor3 = Color3.new(1, 1, 1)
PlayerOnlyBtn.Font = Enum.Font.SourceSansBold
PlayerOnlyBtn.TextSize = 14
PlayerOnlyBtn.ZIndex = 3
PlayerOnlyBtn.TextScaled = true
PlayerOnlyBtn.TextWrapped = true

local WithArgsBtn = Instance.new("TextButton", Page3)
WithArgsBtn.Size = UDim2.new(0.3, 0, 0, 25)
WithArgsBtn.Position = UDim2.new(0.7, 0, 0, 90)
WithArgsBtn.Text = "أوامر مع وسيطات"
WithArgsBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 150)
WithArgsBtn.TextColor3 = Color3.new(1, 1, 1)
WithArgsBtn.Font = Enum.Font.SourceSansBold
WithArgsBtn.TextSize = 14
WithArgsBtn.ZIndex = 3
WithArgsBtn.TextScaled = true
WithArgsBtn.TextWrapped = true

local FavoritesBtn = Instance.new("TextButton", Page3)
FavoritesBtn.Size = UDim2.new(0.3, 0, 0, 25)
FavoritesBtn.Position = UDim2.new(0, 10, 0, 120)
FavoritesBtn.Text = "⭐ المفضلة"
FavoritesBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
FavoritesBtn.TextColor3 = Color3.new(1, 1, 1)
FavoritesBtn.Font = Enum.Font.SourceSansBold
FavoritesBtn.TextSize = 14
FavoritesBtn.ZIndex = 3
FavoritesBtn.TextScaled = true
FavoritesBtn.TextWrapped = true

local SelectAllBtn = Instance.new("TextButton", Page3)
SelectAllBtn.Size = UDim2.new(0.3, 0, 0, 25)
SelectAllBtn.Position = UDim2.new(0.35, 0, 0, 120)
SelectAllBtn.Text = "تحديد كل اللاعبين"
SelectAllBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
SelectAllBtn.TextColor3 = Color3.new(1, 1, 1)
SelectAllBtn.Font = Enum.Font.SourceSansBold
SelectAllBtn.TextSize = 14
SelectAllBtn.ZIndex = 3
SelectAllBtn.TextScaled = true
SelectAllBtn.TextWrapped = true

local ClearAllPlayersBtn = Instance.new("TextButton", Page3)
ClearAllPlayersBtn.Size = UDim2.new(0.3, 0, 0, 25)
ClearAllPlayersBtn.Position = UDim2.new(0.7, 0, 0, 120)
ClearAllPlayersBtn.Text = "إلغاء تحديد اللاعبين"
ClearAllPlayersBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
ClearAllPlayersBtn.TextColor3 = Color3.new(1, 1, 1)
ClearAllPlayersBtn.Font = Enum.Font.SourceSansBold
ClearAllPlayersBtn.TextSize = 14
ClearAllPlayersBtn.ZIndex = 3
ClearAllPlayersBtn.TextScaled = true
ClearAllPlayersBtn.TextWrapped = true

local CmdFrame = Instance.new("ScrollingFrame", Page3)
CmdFrame.Size = UDim2.new(1, -20, 0, 100)
CmdFrame.Position = UDim2.new(0, 10, 0, 150)
CmdFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
CmdFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
CmdFrame.ScrollBarThickness = 6
CmdFrame.ZIndex = 3

-- الأوامر من السكربت القديم
local allCommands = {
    {cmd = "ice", args = "<player>", category = "playerOnly"},
    {cmd = "jice", args = "<player>", category = "playerOnly"},
    {cmd = "jail", args = "<player>", category = "playerOnly"},
    {cmd = "buffify", args = "<player>", category = "playerOnly"},
    {cmd = "wormify", args = "<player>", category = "playerOnly"},
    {cmd = "chibify", args = "<player>", category = "playerOnly"},
    {cmd = "plushify", args = "<player>", category = "playerOnly"},
    {cmd = "freakify", args = "<player>", category = "playerOnly"},
    {cmd = "frogify", args = "<player>", category = "playerOnly"},
    {cmd = "spongify", args = "<player>", category = "playerOnly"},
    {cmd = "bigify", args = "<player>", category = "playerOnly"},
    {cmd = "creepify", args = "<player>", category = "playerOnly"},
    {cmd = "dinofy", args = "<player>", category = "playerOnly"},
    {cmd = "fatify", args = "<player>", category = "playerOnly"},
    {cmd = "glass", args = "<player>", category = "playerOnly"},
    {cmd = "neon", args = "<player>", category = "playerOnly"},
    {cmd = "shine", args = "<player>", category = "playerOnly"},
    {cmd = "ghost", args = "<player>", category = "playerOnly"},
    {cmd = "gold", args = "<player>", category = "playerOnly"},
    {cmd = "bigHead", args = "<player>", category = "playerOnly"},
    {cmd = "smallHead", args = "<player>", category = "playerOnly"},
    {cmd = "dwarf", args = "<player>", category = "playerOnly"},
    {cmd = "giantDwarf", args = "<player>", category = "playerOnly"},
    {cmd = "squash", args = "<player>", category = "playerOnly"},
    {cmd = "fat", args = "<player>", category = "playerOnly"},
    {cmd = "thin", args = "<player>", category = "playerOnly"},
    {cmd = "fire", args = "<player>", category = "playerOnly"},
    {cmd = "smoke", args = "<player>", category = "playerOnly"},
    {cmd = "sparkles", args = "<player>", category = "playerOnly"},
    {cmd = "jump", args = "<player>", category = "playerOnly"},
    {cmd = "sit", args = "<player>", category = "playerOnly"},
    {cmd = "invisible", args = "<player>", category = "playerOnly"},
    {cmd = "nightVision", args = "<player>", category = "playerOnly"},
    {cmd = "ping", args = "<player>", category = "playerOnly"},
    {cmd = "refresh", args = "<player>", category = "playerOnly"},
    {cmd = "jrespawn", args = "<player>", category = "playerOnly"},
    {cmd = "clearHats", args = "<player>", category = "playerOnly"},
    {cmd = "warp", args = "<player>", category = "playerOnly"},
    {cmd = "hideGuis", args = "<player>", category = "playerOnly"},
    {cmd = "showGuis", args = "<player>", category = "playerOnly"},
    {cmd = "freeze", args = "<player>", category = "playerOnly"},
    {cmd = "hideName", args = "<player>", category = "playerOnly"},
    {cmd = "potatoHead", args = "<player>", category = "playerOnly"},
    {cmd = "forceField", args = "<player>", category = "playerOnly"},
    {cmd = "cmds", args = "<player>", category = "playerOnly"},
    {cmd = "view", args = "<player>", category = "playerOnly"},
    {cmd = "god", args = "<player>", category = "playerOnly"},
    {cmd = "kill", args = "<player>", category = "playerOnly"},
    {cmd = "handTo", args = "<player>", category = "playerOnly"},
    {cmd = "sword", args = "<player>", category = "playerOnly"},
    {cmd = "explode", args = "<player>", category = "playerOnly"},
    {cmd = "size", args = "<player> <scale3>", category = "withArgs"},
    {cmd = "hotDance", args = "<player> <speed>", category = "withArgs"},
    {cmd = "touchDance", args = "<player> <speed>", category = "withArgs"},
    {cmd = "feetDance", args = "<player> <speed>", category = "withArgs"},
    {cmd = "spin", args = "<player> <number>", category = "withArgs"},
    {cmd = "width", args = "<player> <scale2>", category = "withArgs"},
    {cmd = "paint", args = "<player> <color>", category = "withArgs"},
    {cmd = "material", args = "<player> <material>", category = "withArgs"},
    {cmd = "reflectance", args = "<player> <number>", category = "withArgs"},
    {cmd = "transparency", args = "<player> <number2>", category = "withArgs"},
    {cmd = "laserEyes", args = "<player> <color>", category = "withArgs"},
    {cmd = "shirt", args = "<player> <number>", category = "withArgs"},
    {cmd = "pants", args = "<player> <number>", category = "withArgs"},
    {cmd = "hat", args = "<player> <number>", category = "withArgs"},
    {cmd = "face", args = "<player> <number>", category = "withArgs"},
    {cmd = "head", args = "<player> <number>", category = "withArgs"},
    {cmd = "name", args = "<player> <text>", category = "withArgs"},
    {cmd = "bodyTypeScale", args = "<player> <scale>", category = "withArgs"},
    {cmd = "depth", args = "<player> <scale2>", category = "withArgs"},
    {cmd = "headSize", args = "<player> <scale2>", category = "withArgs"},
    {cmd = "height", args = "<player> <scale>", category = "withArgs"},
    {cmd = "hipHeight", args = "<player> <scale>", category = "withArgs"},
    {cmd = "char", args = "<player> <userId/username>", category = "withArgs"},
    {cmd = "morph", args = "<player> <morph>", category = "withArgs"},
    {cmd = "bundle", args = "<player> <number>", category = "withArgs"},
    {cmd = "damage", args = "<player> <number3>", category = "withArgs"},
    {cmd = "teleport", args = "<player> <individual>", category = "withArgs"},
    {cmd = "bring", args = "<player> <individual>", category = "withArgs"},
    {cmd = "to", args = "<player> <individual>", category = "withArgs"},
    {cmd = "apparate", args = "<player> <studs>", category = "withArgs"},
    {cmd = "title", args = "<player> <text>", category = "withArgs"}
}

-- وظيفة إنشاء أزرار الأوامر
local function createCommandButton(cmdData, yOffset)
    local btnFrame = Instance.new("Frame", CmdFrame)
    btnFrame.Size = UDim2.new(1, 0, 0, 60)
    btnFrame.Position = UDim2.new(0, 0, 0, yOffset)
    btnFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    btnFrame.Name = cmdData.cmd
    btnFrame.ZIndex = 4

    local cmdText = Instance.new("TextLabel", btnFrame)
    cmdText.Size = UDim2.new(1, -10, 0, 30)
    cmdText.Position = UDim2.new(0, 5, 0, 0)
    cmdText.Text = ";"..cmdData.cmd.." "..cmdData.args
    cmdText.TextColor3 = Color3.new(1, 1, 1)
    cmdText.TextSize = 14
    cmdText.TextXAlignment = Enum.TextXAlignment.Left
    cmdText.BackgroundTransparency = 1
    cmdText.ZIndex = 5
    cmdText.TextScaled = true
    cmdText.TextWrapped = true

    local copyBtn = Instance.new("TextButton", btnFrame)
    copyBtn.Size = UDim2.new(0.2, 0, 0, 20)
    copyBtn.Position = UDim2.new(0, 5, 0, 35)
    copyBtn.Text = "نسخ"
    copyBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    copyBtn.TextColor3 = Color3.new(1, 1, 1)
    copyBtn.TextSize = 12
    copyBtn.ZIndex = 5
    copyBtn.TextScaled = true
    copyBtn.TextWrapped = true

    local favoriteBtn = Instance.new("TextButton", btnFrame)
    favoriteBtn.Size = UDim2.new(0.2, 0, 0, 20)
    favoriteBtn.Position = UDim2.new(0.25, 0, 0, 35)
    favoriteBtn.Text = "⭐"
    favoriteBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
    favoriteBtn.TextColor3 = Color3.new(1, 1, 1)
    favoriteBtn.TextSize = 12
    favoriteBtn.ZIndex = 5
    favoriteBtn.TextScaled = true
    favoriteBtn.TextWrapped = true

    local selectCmdBtn = Instance.new("TextButton", btnFrame)
    selectCmdBtn.Size = UDim2.new(0.2, 0, 0, 20)
    selectCmdBtn.Position = UDim2.new(0.5, 0, 0, 35)
    selectCmdBtn.Text = "+"
    selectCmdBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    selectCmdBtn.TextColor3 = Color3.new(1, 1, 1)
    selectCmdBtn.TextSize = 12
    selectCmdBtn.ZIndex = 5
    selectCmdBtn.TextScaled = true
    selectCmdBtn.TextWrapped = true

    local isSelected = false
    local isFavorite = false

    selectCmdBtn.MouseButton1Click:Connect(function()
        isSelected = not isSelected
        if isSelected then
            selectCmdBtn.Text = "✔"
            selectCmdBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            table.insert(selectedCommands, cmdData)
        else
            selectCmdBtn.Text = "+"
            selectCmdBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            for i, cmd in ipairs(selectedCommands) do
                if cmd.cmd == cmdData.cmd then
                    table.remove(selectedCommands, i)
                    break
                end
            end
        end
    end)

    favoriteBtn.MouseButton1Click:Connect(function()
        isFavorite = not isFavorite
        if isFavorite then
            favoriteBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
            btnFrame.BackgroundColor3 = Color3.fromRGB(100, 75, 0)
            table.insert(favoriteCommands, cmdData)
        else
            favoriteBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
            btnFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            for i, cmd in ipairs(favoriteCommands) do
                if cmd.cmd == cmdData.cmd then
                    table.remove(favoriteCommands, i)
                    break
                end
            end
        end
    end)

    copyBtn.MouseButton1Click:Connect(function()
        local playerNames = findPlayer(NameBox.Text)
        local commandsToCopy = {}
        for _, playerName in ipairs(playerNames) do
            local cleanedPlayerName = cleanPlayerName(playerName)
            if cleanedPlayerName == "" then continue end
            local commandText = ";" .. cmdData.cmd .. " " .. cleanedPlayerName
            table.insert(commandsToCopy, commandText)
            wait(0.1)
        end
        local finalText = table.concat(commandsToCopy, "\n") .. "\n" .. string.rep(".", 500)
        copyToClipboard(finalText)
    end)

    return 70
end

-- وظيفة لعرض الأوامر
local function displayCommands(commands)
    CmdFrame:ClearAllChildren()
    local yOffset = 0

    local playerOnlyCommands = {}
    local withArgsCommands = {}
    for _, cmd in ipairs(commands) do
        if cmd.category == "playerOnly" then
            table.insert(playerOnlyCommands, cmd)
        else
            table.insert(withArgsCommands, cmd)
        end
    end

    if #playerOnlyCommands > 0 then
        local sectionLabel = Instance.new("TextLabel", CmdFrame)
        sectionLabel.Size = UDim2.new(1, 0, 0, 20)
        sectionLabel.Position = UDim2.new(0, 0, 0, yOffset)
        sectionLabel.Text = "الأوامر التي تحتوي على <player>"
        sectionLabel.TextColor3 = Color3.new(1, 1, 1)
        sectionLabel.TextSize = 16
        sectionLabel.BackgroundTransparency = 1
        sectionLabel.ZIndex = 4
        sectionLabel.TextScaled = true
        sectionLabel.TextWrapped = true
        yOffset = yOffset + 20

        for _, cmd in ipairs(playerOnlyCommands) do
            yOffset = yOffset + createCommandButton(cmd, yOffset)
            local divider = Instance.new("Frame", CmdFrame)
            divider.Size = UDim2.new(1, 0, 0, 1)
            divider.Position = UDim2.new(0, 0, 0, yOffset - 10)
            divider.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
            divider.BorderSizePixel = 0
            divider.ZIndex = 4
        end
    end

    if #playerOnlyCommands > 0 and #withArgsCommands > 0 then
        local divider = Instance.new("Frame", CmdFrame)
        divider.Size = UDim2.new(1, 0, 0, 2)
        divider.Position = UDim2.new(0, 0, 0, yOffset)
        divider.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        divider.BorderSizePixel = 0
        divider.ZIndex = 4
        yOffset = yOffset + 10
    end

    if #withArgsCommands > 0 then
        local sectionLabel = Instance.new("TextLabel", CmdFrame)
        sectionLabel.Size = UDim2.new(1, 0, 0, 20)
        sectionLabel.Position = UDim2.new(0, 0, 0, yOffset)
        sectionLabel.Text = "الأوامر التي تحتوي على وسيطات إضافية"
        sectionLabel.TextColor3 = Color3.new(1, 1, 1)
        sectionLabel.TextSize = 16
        sectionLabel.BackgroundTransparency = 1
        sectionLabel.ZIndex = 4
        sectionLabel.TextScaled = true
        sectionLabel.TextWrapped = true
        yOffset = yOffset + 20

        for _, cmd in ipairs(withArgsCommands) do
            yOffset = yOffset + createCommandButton(cmd, yOffset)
            local divider = Instance.new("Frame", CmdFrame)
            divider.Size = UDim2.new(1, 0, 0, 1)
            divider.Position = UDim2.new(0, 0, 0, yOffset - 10)
            divider.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
            divider.BorderSizePixel = 0
            divider.ZIndex = 4
        end
    end

    CmdFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset)
end

-- عرض كل الأوامر في البداية
displayCommands(allCommands)

-- الصفحة الرابعة (السبام - Page4)
local Page4 = Instance.new("Frame", MainFrame)
Page4.Name = "Page4"
Page4.Size = UDim2.new(0, 340, 0, 250)
Page4.Position = UDim2.new(0, 60, 0, 0)
Page4.BackgroundTransparency = 1
Page4.Visible = false
Page4.ZIndex = 2

-- صورة الأفاتار في صفحة السبام
local AvatarImagePage4 = Instance.new("ImageLabel", Page4)
AvatarImagePage4.Size = UDim2.new(0, 80, 0, 80)
AvatarImagePage4.Position = UDim2.new(0, 0, 0, 10)
AvatarImagePage4.BackgroundTransparency = 1
AvatarImagePage4.Image = getPlayerInfo(LocalPlayer).thumbnailUrl
AvatarImagePage4.ImageTransparency = 0.3 -- الشفافية للصورة
AvatarImagePage4.ZIndex = 2

-- نص العنوان في صفحة السبام
local TitleTextPage4 = Instance.new("TextLabel", Page4)
TitleTextPage4.Size = UDim2.new(0, 200, 0, 30)
TitleTextPage4.Position = UDim2.new(0.5, -100, 0, 10)
TitleTextPage4.BackgroundTransparency = 1
TitleTextPage4.Text = "حووقه : 6rb"
TitleTextPage4.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleTextPage4.Font = Enum.Font.Gotham
TitleTextPage4.TextSize = 20
TitleTextPage4.TextXAlignment = Enum.TextXAlignment.Right
TitleTextPage4.ZIndex = 2

-- خانة إدخال رسالة السبام
local SpamBox = Instance.new("TextBox", Page4)
SpamBox.Size = UDim2.new(1, -20, 0, 30)
SpamBox.Position = UDim2.new(0, 10, 0, 50)
SpamBox.PlaceholderText = "أدخل رسالة السبام..."
SpamBox.Text = ""
SpamBox.TextSize = 16
SpamBox.TextColor3 = Color3.fromRGB(255, 255, 255)
SpamBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
SpamBox.TextXAlignment = Enum.TextXAlignment.Right
SpamBox.ZIndex = 3
SpamBox.TextScaled = true
SpamBox.TextWrapped = true

-- زر تفعيل/إيقاف السبام
local SpamToggleBtn = Instance.new("TextButton", Page4)
SpamToggleBtn.Size = UDim2.new(0, 100, 0, 30)
SpamToggleBtn.Position = UDim2.new(0, 10, 0, 90)
SpamToggleBtn.Text = "تفعيل السبام"
SpamToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
SpamToggleBtn.TextColor3 = Color3.new(1, 1, 1)
SpamToggleBtn.TextSize = 14
SpamToggleBtn.ZIndex = 3
SpamToggleBtn.TextScaled = true
SpamToggleBtn.TextWrapped = true

-- الصفحة الخامسة (قائمة الاستهداف - Page5)
local Page5 = Instance.new("Frame", MainFrame)
Page5.Name = "Page5"
Page5.Size = UDim2.new(0, 340, 0, 250)
Page5.Position = UDim2.new(0, 60, 0, 0)
Page5.BackgroundTransparency = 1
Page5.Visible = false
Page5.ZIndex = 2

-- صورة الأفاتار في صفحة الاستهداف
local AvatarImagePage5 = Instance.new("ImageLabel", Page5)
AvatarImagePage5.Size = UDim2.new(0, 80, 0, 80)
AvatarImagePage5.Position = UDim2.new(0, 0, 0, 10)
AvatarImagePage5.BackgroundTransparency = 1
AvatarImagePage5.Image = getPlayerInfo(LocalPlayer).thumbnailUrl
AvatarImagePage5.ImageTransparency = 0.3 -- الشفافية للصورة
AvatarImagePage5.ZIndex = 2

-- نص العنوان في صفحة الاستهداف
local TitleTextPage5 = Instance.new("TextLabel", Page5)
TitleTextPage5.Size = UDim2.new(0, 200, 0, 30)
TitleTextPage5.Position = UDim2.new(0.5, -100, 0, 10)
TitleTextPage5.BackgroundTransparency = 1
TitleTextPage5.Text = "حووقه : 6rb"
TitleTextPage5.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleTextPage5.Font = Enum.Font.Gotham
TitleTextPage5.TextSize = 20
TitleTextPage5.TextXAlignment = Enum.TextXAlignment.Right
TitleTextPage5.ZIndex = 2

-- خانة إدخال اسم اللاعب المستهدف
local TargetBox = Instance.new("TextBox", Page5)
TargetBox.Size = UDim2.new(1, -20, 0, 30)
TargetBox.Position = UDim2.new(0, 10, 0, 50)
TargetBox.PlaceholderText = "اسم اللاعب المستهدف..."
TargetBox.Text = ""
TargetBox.TextSize = 16
TargetBox.TextColor3 = Color3.fromRGB(255, 255, 255)
TargetBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
TargetBox.TextXAlignment = Enum.TextXAlignment.Right
TargetBox.ZIndex = 3
TargetBox.TextScaled = true
TargetBox.TextWrapped = true

-- زر تفعيل/إيقاف الـ ESP
local ESPToggleBtn = Instance.new("TextButton", Page5)
ESPToggleBtn.Size = UDim2.new(0, 100, 0, 30)
ESPToggleBtn.Position = UDim2.new(0, 10, 0, 90)
ESPToggleBtn.Text = "تفعيل ESP"
ESPToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
ESPToggleBtn.TextColor3 = Color3.new(1, 1, 1)
ESPToggleBtn.TextSize = 14
ESPToggleBtn.ZIndex = 3
ESPToggleBtn.TextScaled = true
ESPToggleBtn.TextWrapped = true

-- زر "الأوامر" في الأسفل
local CommandsButton = Instance.new("TextButton", MainFrame)
CommandsButton.Size = UDim2.new(0, 100, 0, 40)
CommandsButton.Position = UDim2.new(0, 60, 1, -50)
CommandsButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
CommandsButton.Text = "الأوامر"
CommandsButton.TextColor3 = Color3.fromRGB(0, 0, 0)
CommandsButton.TextSize = 18
CommandsButton.ZIndex = 3
CommandsButton.TextScaled = true

-- زر "المعلومات" في الأسفل
local InfoButton = Instance.new("TextButton", MainFrame)
InfoButton.Size = UDim2.new(0, 100, 0, 40)
InfoButton.Position = UDim2.new(1, -110, 1, -50)
InfoButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
InfoButton.Text = "المعلومات"
InfoButton.TextColor3 = Color3.fromRGB(0, 0, 0)
InfoButton.TextSize = 18
InfoButton.ZIndex = 3
InfoButton.TextScaled = true

-- وظيفة التنقل بين الصفحات
local function showPage(page)
    Page1.Visible = (page == Page1)
    Page2.Visible = (page == Page2)
    Page3.Visible = (page == Page3)
    Page4.Visible = (page == Page4)
    Page5.Visible = (page == Page5)
end

-- ربط الأزرار بالتنقل
CommandsButton.MouseButton1Click:Connect(function()
    showPage(Page3)
end)

InfoButton.MouseButton1Click:Connect(function()
    showPage(Page2)
end)

InfoSidebarButton.MouseButton1Click:Connect(function()
    showPage(Page2)
end)

CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

TopCloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

SettingsButton.MouseButton1Click:Connect(function()
    -- يمكن إضافة وظيفة الإعدادات هنا
    copyToClipboard("الإعدادات غير متاحة حاليًا!")
end)

-- أحداث أزرار التصفية
SelectBtn.MouseButton1Click:Connect(function()
    displayCommands(allCommands)
end)

PlayerOnlyBtn.MouseButton1Click:Connect(function()
    local filteredCommands = {}
    for _, cmd in ipairs(allCommands) do
        if cmd.category == "playerOnly" then
            table.insert(filteredCommands, cmd)
        end
    end
    displayCommands(filteredCommands)
end)

WithArgsBtn.MouseButton1Click:Connect(function()
    local filteredCommands = {}
    for _, cmd in ipairs(allCommands) do
        if cmd.category == "withArgs" then
            table.insert(filteredCommands, cmd)
        end
    end
    displayCommands(filteredCommands)
end)

FavoritesBtn.MouseButton1Click:Connect(function()
    if #favoriteCommands == 0 then
        copyToClipboard("لا توجد أوامر مفضلة!")
        return
    end
    displayCommands(favoriteCommands)
end)

SelectAllBtn.MouseButton1Click:Connect(function()
    local allPlayers = getAllPlayers()
    if allPlayers == "" then
        copyToClipboard("لا يوجد لاعبون في السيرفر!")
        return
    end
    NameBox.Text = allPlayers
    copyToClipboard("تم تحديد جميع اللاعبين: " .. allPlayers)
end)

ClearAllPlayersBtn.MouseButton1Click:Connect(function()
    NameBox.Text = LocalPlayer.Name
    copyToClipboard("تم إلغاء تحديد جميع اللاعبين")
end)

-- أحداث السبام
SpamToggleBtn.MouseButton1Click:Connect(function()
    spamEnabled = not spamEnabled
    if spamEnabled then
        SpamToggleBtn.Text = "إيقاف السبام"
        SpamToggleBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        spamThread = coroutine.create(function()
            while spamEnabled do
                sendMessageToChat(SpamBox.Text)
                wait(1)
            end
        end)
        coroutine.resume(spamThread)
    else
        SpamToggleBtn.Text = "تفعيل السبام"
        SpamToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        if spamThread then
            coroutine.close(spamThread)
            spamThread = nil
        end
    end
end)

-- أحداث الاستهداف
TargetBox:GetPropertyChangedSignal("Text"):Connect(function()
    local playerNames = findPlayer(TargetBox.Text)
    if #playerNames == 1 then
        targetedPlayer = Players:FindFirstChild(playerNames[1])
    else
        targetedPlayer = nil
    end
end)

ESPToggleBtn.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    if espEnabled then
        ESPToggleBtn.Text = "إيقاف ESP"
        ESPToggleBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        if targetedPlayer then
            toggleESP(targetedPlayer, true)
        end
    else
        ESPToggleBtn.Text = "تفعيل ESP"
        ESPToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        if targetedPlayer then
            toggleESP(targetedPlayer, false)
        end
    end
end)

-- إعادة تحميل الـ ESP عند إعادة تحميل الشخصية
Players.PlayerAdded:Connect(function(newPlayer)
    if newPlayer == targetedPlayer and espEnabled then
        wait(1)
        toggleESP(newPlayer, espEnabled)
    end
end)
