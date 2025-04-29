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
MainFrame.BackgroundTransparency = 0.2
MainFrame.ZIndex = 1

-- تأثير النيون للـ Frame
local StrokeInner = Instance.new("UIStroke", MainFrame)
Stroke
