local Players = game:GetService("Players")
local player = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local TextChatService = game:GetService("TextChatService")
local RunService = game:GetService("RunService")

-- جدول لتخزين الأوامر المحددة والمفضلة
local selectedCommands = {}
local favoriteCommands = {}
local targetedPlayer = nil -- اللاعب المستهدف
local espEnabled = false -- حالة الـ ESP
local espHighlight = nil -- لتخزين الـ Highlight
local spamEnabled = false -- حالة السبام
local spamThread = nil -- لتخزين مؤشر السبام
local protectionEnabled = false -- حالة الحماية
local protectionConnections = {} -- لتخزين الاتصالات بمراقبة التغييرات

-- وظيفة تنظيف اسم اللاعب
local function cleanPlayerName(name)
    -- إزالة المسافات الزائدة والحروف الخاصة
    name = string.gsub(name, "^%s*(.-)%s*$", "%1") -- إزالة المسافات في البداية والنهاية
    name = string.gsub(name, "[^%w_]", "") -- إزالة أي حروف خاصة (يسمح فقط بالحروف، الأرقام، و _)
    return name
end

-- وظيفة البحث عن اللاعب (محدثة لتحسين المطابقة وإضافة تنظيف الأسماء)
local function findPlayer(partialName)
    if partialName == "" then 
        print("partialName فارغ، يتم إرجاع اسم اللاعب الحالي")
        return {player.Name} 
    end
    
    local playerNames = {}
    for name in string.gmatch(partialName, "[^,]+") do
        name = cleanPlayerName(name) -- تنظيف الاسم
        if name == "" then continue end -- تجاهل الأسماء الفارغة بعد التنظيف
        local found = false
        for _, p in pairs(Players:GetPlayers()) do
            local cleanedPlayerName = cleanPlayerName(p.Name)
            local cleanedDisplayName = p.DisplayName and cleanPlayerName(p.DisplayName) or ""
            local lowerSearchName = string.lower(name)
            if string.lower(cleanedPlayerName):find(lowerSearchName) or (p.DisplayName and string.lower(cleanedDisplayName):find(lowerSearchName)) then
                table.insert(playerNames, p.Name) -- نستخدم الاسم الأصلي للاعب (غير المنظف) لضمان التوافق
                found = true
                break
            end
        end
        if not found then
            print("⚠️ تحذير: لم يتم العثور على لاعب باسم: " .. name .. "، قد لا يتأثر بالأوامر!")
            table.insert(playerNames, name) -- مع ذلك، نضيفه للقائمة لمحاولة التنفيذ
        end
    end
    if #playerNames == 0 then
        print("⚠️ تحذير: لم يتم العثور على أي لاعبين مطابقين!")
    else
        print("اللاعبون المحددون: " .. table.concat(playerNames, ", "))
    end
    return playerNames
end

-- وظيفة للحصول على جميع اللاعبين في السيرفر
local function getAllPlayers()
    local playerNames = {}
    for _, p in pairs(Players:GetPlayers()) do
        table.insert(playerNames, p.Name)
    end
    local result = table.concat(playerNames, ", ")
    print("جميع اللاعبين في السيرفر: " .. result)
    return result
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
        print("تم نسخ: " .. text)
    else
        print("فشل النسخ إلى الحافظة: " .. tostring(err))
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "فشل النسخ",
            Text = "تعذر النسخ، تحقق من وحدة التحكم (F9)",
            Duration = 3
        })
    end
end

-- وظيفة لإرسال رسالة إلى الشات (محدثة للتأكد من التنفيذ مع تأخير)
local function sendMessageToChat(message)
    if message == "" then
        print("النص فارغ، لا يمكن إرسال رسالة!")
        return false
    end

    local chatService = game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents")
    if chatService then
        local sayMessageRequest = chatService:FindFirstChild("SayMessageRequest")
        print("Chat Service:", chatService, "SayMessageRequest:", sayMessageRequest)
        if sayMessageRequest then
            sayMessageRequest:FireServer(message, "All")
            print("تم إرسال الرسالة باستخدام DefaultChatSystemChatEvents: " .. message)
            wait(0.1) -- تأخير بسيط لضمان التنفيذ
            return true
        else
            print("تعذر العثور على SayMessageRequest")
        end
    else
        print("تعذر العثور على DefaultChatSystemChatEvents")
    end

    if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
        local textChannels = TextChatService:FindFirstChild("TextChannels")
        if textChannels then
            local channel = textChannels:FindFirstChild("RBXGeneral") or textChannels:FindFirstChildWhichIsA("TextChatChannel")
            if channel then
                channel:SendAsync(message)
                print("تم إرسال الرسالة باستخدام TextChatService: " .. message)
                wait(0.1) -- تأخير بسيط لضمان التنفيذ
                return true
            else
                print("تعذر العثور على قناة شات في TextChatService")
            end
        else
            print("تعذر العثور على TextChannels في TextChatService")
        end
    else
        print("TextChatService غير مفعل أو غير متوفر")
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
    info.location = "غير متوفر (يمكن تخصيصه)"
    info.thumbnailUrl = string.format("https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=420&height=420&format=png", userId)
    return info
end

-- وظيفة لتفعيل/إيقاف الـ ESP للاعب معين
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

-- وظيفة لتفعيل/إيقاف الحماية
local function toggleProtection(enable)
    if enable then
        print("تم تفعيل الحماية!")
        -- 1. حماية ضد القتل (God Mode)
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            local humanoid = player.Character.Humanoid
            humanoid.MaxHealth = math.huge
            humanoid.Health = math.huge
            -- مراقبة تغيير الصحة
            table.insert(protectionConnections, humanoid:GetPropertyChangedSignal("Health"):Connect(function()
                if protectionEnabled then
                    humanoid.Health = math.huge
                end
            end))
        end

        -- 2. حماية ضد التجميد (Freeze) وتغيير الحركة
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            local humanoid = player.Character.Humanoid
            table.insert(protectionConnections, humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
                if protectionEnabled and humanoid.WalkSpeed <= 0 then
                    humanoid.WalkSpeed = 16 -- القيمة الافتراضية
                end
            end))
            table.insert(protectionConnections, humanoid:GetPropertyChangedSignal("JumpPower"):Connect(function()
                if protectionEnabled and humanoid.JumpPower <= 0 then
                    humanoid.JumpPower = 50 -- القيمة الافتراضية
                end
            end))
        end

        -- 3. حماية ضد التغييرات في الحجم أو الشفافية
        if player.Character then
            for _, part in pairs(player.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    -- حفظ الحجم الأصلي
                    local originalSize = part.Size
                    table.insert(protectionConnections, part:GetPropertyChangedSignal("Size"):Connect(function()
                        if protectionEnabled then
                            part.Size = originalSize
                        end
                    end))
                    -- حفظ الشفافية الأصلية
                    local originalTransparency = part.Transparency
                    table.insert(protectionConnections, part:GetPropertyChangedSignal("Transparency"):Connect(function()
                        if protectionEnabled then
                            part.Transparency = originalTransparency
                        end
                    end))
                end
            end
        end

        -- 4. حماية ضد الإزالة أو التغيير في الجسم (مثل التفجير أو إزالة الأجزاء)
        if player.Character then
            table.insert(protectionConnections, player.Character.ChildRemoved:Connect(function(child)
                if protectionEnabled and child:IsA("BasePart") then
                    -- إعادة تحميل الشخصية إذا تمت إزالة جزء مهم
                    player:LoadCharacter()
                end
            end))
        end

        -- 5. حماية ضد النقل (Teleport) أو التغيير في الموقع
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = player.Character.HumanoidRootPart
            local lastPosition = hrp.Position
            table.insert(protectionConnections, RunService.Heartbeat:Connect(function()
                if protectionEnabled then
                    local currentPosition = hrp.Position
                    local distance = (currentPosition - lastPosition).Magnitude
                    if distance > 50 then -- إذا تغير الموقع بشكل كبير (مثل النقل)
                        hrp.Position = lastPosition
                    else
                        lastPosition = currentPosition
                    end
                end
            end))
        end

        -- 6. إعادة تحميل الشخصية عند الموت (للحماية من أوامر مثل ;kill)
        table.insert(protectionConnections, player.CharacterAdded:Connect(function(character)
            if protectionEnabled then
                wait(0.1) -- انتظر حتى تكتمل إعادة التحميل
                toggleProtection(true) -- إعادة تفعيل الحماية
            end
        end))
    else
        print("تم إيقاف الحماية!")
        -- قطع جميع الاتصالات
        for _, connection in pairs(protectionConnections) do
            connection:Disconnect()
        end
        protectionConnections = {}
        -- إعادة تعيين الصحة إلى القيمة الافتراضية
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            local humanoid = player.Character.Humanoid
            humanoid.MaxHealth = 100
            humanoid.Health = 100
        end
    end
end

-- واجهة المستخدم
local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
screenGui.Name = "AdvancedCommandGUI"
screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 700, 0, 500)
mainFrame.Position = UDim2.new(0.3, 0, 0.2, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.ZIndex = 1

local title = Instance.new("TextLabel", mainFrame)
title.Size = UDim2.new(1, 0, 0, 30)
title.Text = "سكربت اوامر -بيتا- (مو كامل + احتمال فيه مشاكل)"
title.Font = Enum.Font.SourceSansBold
title.TextSize = 20
title.BackgroundColor3 = Color3.fromRGB(50, 0, 100)
title.TextColor3 = Color3.new(1, 1, 1)
title.ZIndex = 2

local hideBtn = Instance.new("TextButton", mainFrame)
hideBtn.Size = UDim2.new(0, 30, 0, 30)
hideBtn.Position = UDim2.new(1, -35, 0, 0)
hideBtn.Text = "X"
hideBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
hideBtn.TextColor3 = Color3.new(1, 1, 1)
hideBtn.ZIndex = 3

-- أزرار التبديل بين الصفحات (مع إضافة زر لقسم الحماية)
local tabsFrame = Instance.new("Frame", mainFrame)
tabsFrame.Size = UDim2.new(1, 0, 0, 30)
tabsFrame.Position = UDim2.new(0, 0, 0, 30)
tabsFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
tabsFrame.ZIndex = 2

local targetPageBtn = Instance.new("TextButton", tabsFrame)
targetPageBtn.Size = UDim2.new(0.2, 0, 1, 0) -- قسمنا الأزرار على 5 بدل 4
targetPageBtn.Position = UDim2.new(0, 0, 0, 0)
targetPageBtn.Text =  "الاستهداف"
targetPageBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
targetPageBtn.TextColor3 = Color3.new(1, 1, 1)
targetPageBtn.Font = Enum.Font.SourceSansBold
targetPageBtn.TextSize = 16
targetPageBtn.ZIndex = 3

local protectionPageBtn = Instance.new("TextButton", tabsFrame) -- زر جديد لقسم الحماية
protectionPageBtn.Size = UDim2.new(0.2, 0, 1, 0)
protectionPageBtn.Position = UDim2.new(0.2, 0, 0, 0)
protectionPageBtn.Text = "الحماية"
protectionPageBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
protectionPageBtn.TextColor3 = Color3.new(1, 1, 1)
protectionPageBtn.Font = Enum.Font.SourceSansBold
protectionPageBtn.TextSize = 16
protectionPageBtn.ZIndex = 3

local spamPageBtn = Instance.new("TextButton", tabsFrame)
spamPageBtn.Size = UDim2.new(0.2, 0, 1, 0)
spamPageBtn.Position = UDim2.new(0.4, 0, 0, 0)
spamPageBtn.Text = "اكتب الامر الي نسخته هنا (سبام)"
spamPageBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
spamPageBtn.TextColor3 = Color3.new(1, 1, 1)
spamPageBtn.Font = Enum.Font.SourceSansBold
spamPageBtn.TextSize = 16
spamPageBtn.ZIndex = 3

local commandsPageBtn = Instance.new("TextButton", tabsFrame)
commandsPageBtn.Size = UDim2.new(0.2, 0, 1, 0)
commandsPageBtn.Position = UDim2.new(0.6, 0, 0, 0)
commandsPageBtn.Text = "الاوامر"
commandsPageBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
commandsPageBtn.TextColor3 = Color3.new(1, 1, 1)
commandsPageBtn.Font = Enum.Font.SourceSansBold
commandsPageBtn.TextSize = 16
commandsPageBtn.ZIndex = 3

local infoPageBtn = Instance.new("TextButton", tabsFrame)
infoPageBtn.Size = UDim2.new(0.2, 0, 1, 0)
infoPageBtn.Position = UDim2.new(0.8, 0, 0, 0)
infoPageBtn.Text = "الصفحة الرئيسية"
infoPageBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
infoPageBtn.TextColor3 = Color3.new(1, 1, 1)
infoPageBtn.Font = Enum.Font.SourceSansBold
infoPageBtn.TextSize = 16
infoPageBtn.ZIndex = 3

-- الصفحات
local commandsPage = Instance.new("Frame", mainFrame)
commandsPage.Size = UDim2.new(1, 0, 1, -60)
commandsPage.Position = UDim2.new(0, 0, 0, 60)
commandsPage.BackgroundTransparency = 1
commandsPage.Visible = false
commandsPage.ZIndex = 2

local targetPage = Instance.new("Frame", mainFrame)
targetPage.Size = UDim2.new(1, 0, 1, -60)
targetPage.Position = UDim2.new(0, 0, 0, 60)
targetPage.BackgroundTransparency = 1
targetPage.Visible = false
targetPage.ZIndex = 2

local protectionPage = Instance.new("Frame", mainFrame) -- صفحة جديدة للحماية
protectionPage.Size = UDim2.new(1, 0, 1, -60)
protectionPage.Position = UDim2.new(0, 0, 0, 60)
protectionPage.BackgroundTransparency = 1
protectionPage.Visible = false
protectionPage.ZIndex = 2

local spamPage = Instance.new("Frame", mainFrame)
spamPage.Size = UDim2.new(1, 0, 1, -60)
spamPage.Position = UDim2.new(0, 0, 0, 60)
spamPage.BackgroundTransparency = 1
spamPage.Visible = false
spamPage.ZIndex = 2

local infoPage = Instance.new("Frame", mainFrame)
infoPage.Size = UDim2.new(1, 0, 1, -60)
infoPage.Position = UDim2.new(0, 0, 0, 60)
infoPage.BackgroundTransparency = 1
infoPage.Visible = true
infoPage.ZIndex = 2

-- خانة البحث (في صفحة الأوامر)
local searchBox = Instance.new("TextBox", commandsPage)
searchBox.Size = UDim2.new(1, -20, 0, 30)
searchBox.Position = UDim2.new(0, 10, 0, 10)
searchBox.PlaceholderText = "ابحث عن أمر..."
searchBox.Text = ""
searchBox.TextSize = 16
searchBox.TextColor3 = Color3.new(1, 1, 1)
searchBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
searchBox.ZIndex = 3
searchBox.TextScaled = true
searchBox.TextWrapped = true

-- أزرار التصفية (في صفحة الأوامر)
local selectBtn = Instance.new("TextButton", commandsPage)
selectBtn.Size = UDim2.new(0.12, -5, 0, 25)
selectBtn.Position = UDim2.new(0, 10, 0, 50)
selectBtn.Text = "تحديد الأوامر"
selectBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
selectBtn.TextColor3 = Color3.new(1, 1, 1)
selectBtn.Font = Enum.Font.SourceSansBold
selectBtn.TextSize = 14
selectBtn.ZIndex = 3
selectBtn.TextScaled = true
selectBtn.TextWrapped = true

local playerOnlyBtn = Instance.new("TextButton", commandsPage)
playerOnlyBtn.Size = UDim2.new(0.12, -5, 0, 25)
playerOnlyBtn.Position = UDim2.new(0.12, 5, 0, 50)
playerOnlyBtn.Text = "أوامر <player>"
playerOnlyBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 150)
playerOnlyBtn.TextColor3 = Color3.new(1, 1, 1)
playerOnlyBtn.Font = Enum.Font.SourceSansBold
playerOnlyBtn.TextSize = 14
playerOnlyBtn.ZIndex = 3
playerOnlyBtn.TextScaled = true
playerOnlyBtn.TextWrapped = true

local withArgsBtn = Instance.new("TextButton", commandsPage)
withArgsBtn.Size = UDim2.new(0.12, -5, 0, 25)
withArgsBtn.Position = UDim2.new(0.24, 0, 0, 50)
withArgsBtn.Text = "أوامر مع وسيطات"
withArgsBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 150)
withArgsBtn.TextColor3 = Color3.new(1, 1, 1)
withArgsBtn.Font = Enum.Font.SourceSansBold
withArgsBtn.TextSize = 14
withArgsBtn.ZIndex = 3
withArgsBtn.TextScaled = true
withArgsBtn.TextWrapped = true

local favoritesBtn = Instance.new("TextButton", commandsPage)
favoritesBtn.Size = UDim2.new(0.12, -5, 0, 25)
favoritesBtn.Position = UDim2.new(0.36, -5, 0, 50)
favoritesBtn.Text = "⭐ المفضلة"
favoritesBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
favoritesBtn.TextColor3 = Color3.new(1, 1, 1)
favoritesBtn.Font = Enum.Font.SourceSansBold
favoritesBtn.TextSize = 14
favoritesBtn.ZIndex = 3
favoritesBtn.TextScaled = true
favoritesBtn:TextWrapped = true

-- زر تحديد كل اللاعبين (بدون RGB، لون أسود ثابت)
local selectAllBtn = Instance.new("TextButton", commandsPage)
selectAllBtn.Size = UDim2.new(0.12, -5, 0, 25)
selectAllBtn.Position = UDim2.new(0.48, -10, 0, 50)
selectAllBtn.Text = "تحديد كل اللاعبين"
selectAllBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0) -- لون أسود ثابت
selectAllBtn.TextColor3 = Color3.new(1, 1, 1)
selectAllBtn.Font = Enum.Font.SourceSansBold
selectAllBtn.TextSize = 14
selectAllBtn.ZIndex = 3
selectAllBtn.TextScaled = true
selectAllBtn.TextWrapped = true

-- زر إلغاء تحديد كل اللاعبين
local clearAllPlayersBtn = Instance.new("TextButton", commandsPage)
clearAllPlayersBtn.Size = UDim2.new(0.12, -5, 0, 25)
clearAllPlayersBtn.Position = UDim2.new(0.60, -15, 0, 50)
clearAllPlayersBtn.Text = "إلغاء تحديد اللاعبين"
clearAllPlayersBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
clearAllPlayersBtn.TextColor3 = Color3.new(1, 1, 1)
clearAllPlayersBtn.Font = Enum.Font.SourceSansBold
clearAllPlayersBtn.TextSize = 14
clearAllPlayersBtn.ZIndex = 3
clearAllPlayersBtn.TextScaled = true
clearAllPlayersBtn.TextWrapped = true

local copySelectedBtn = Instance.new("TextButton", commandsPage)
copySelectedBtn.Size = UDim2.new(0.12, -5, 0, 25)
copySelectedBtn.Position = UDim2.new(0.72, -20, 0, 50)
copySelectedBtn.Text = "نسخ المحدد"
copySelectedBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
copySelectedBtn.TextColor3 = Color3.new(1, 1, 1)
copySelectedBtn.Font = Enum.Font.SourceSansBold
copySelectedBtn.TextSize = 14
copySelectedBtn.ZIndex = 3
copySelectedBtn.TextScaled = true
copySelectedBtn.TextWrapped = true

local clearSelectionBtn = Instance.new("TextButton", commandsPage)
clearSelectionBtn.Size = UDim2.new(0.12, -5, 0, 25)
clearSelectionBtn.Position = UDim2.new(0.84, -25, 0, 50)
clearSelectionBtn.Text = "إلغاء التحديد"
clearSelectionBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
clearSelectionBtn.TextColor3 = Color3.new(1, 1, 1)
clearSelectionBtn.Font = Enum.Font.SourceSansBold
clearSelectionBtn.TextSize = 14
clearSelectionBtn.ZIndex = 3
clearSelectionBtn.TextScaled = true
clearSelectionBtn.TextWrapped = true

local nameBox = Instance.new("TextBox", commandsPage)
nameBox.Size = UDim2.new(1, -20, 0, 30)
nameBox.Position = UDim2.new(0, 10, 0, 85)
nameBox.PlaceholderText = "اسم الاعب"
nameBox.Text = player.Name
nameBox.TextSize = 16
nameBox.TextColor3 = Color3.new(1, 1, 1)
nameBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
nameBox.ZIndex = 3
nameBox.TextScaled = true
nameBox.TextWrapped = true

local dividerLine = Instance.new("Frame", commandsPage)
dividerLine.Size = UDim2.new(1, -20, 0, 2)
dividerLine.Position = UDim2.new(0, 10, 0, 120)
dividerLine.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
dividerLine.BorderSizePixel = 0
dividerLine.ZIndex = 3

-- تقسيم صندوق القيمة إلى ثلاثة صناديق
local numberBox = Instance.new("TextBox", commandsPage)
numberBox.Size = UDim2.new(1, -20, 0, 30)
numberBox.Position = UDim2.new(0, 10, 0, 130)
numberBox.PlaceholderText = "الأرقام (مثل 10، 0.5...)"
numberBox.Text = ""
numberBox.TextSize = 16
numberBox.TextColor3 = Color3.new(1, 1, 1)
numberBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
numberBox.Visible = false
numberBox.ZIndex = 3
numberBox.TextScaled = true
numberBox.TextWrapped = true

local colorBox = Instance.new("TextBox", commandsPage)
colorBox.Size = UDim2.new(1, -20, 0, 30)
colorBox.Position = UDim2.new(0, 10, 0, 165)
colorBox.PlaceholderText = "اللون (مثل red، blue...)"
colorBox.Text = ""
colorBox.TextSize = 16
colorBox.TextColor3 = Color3.new(1, 1, 1)
colorBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
colorBox.Visible = false
colorBox.ZIndex = 3
colorBox.TextScaled = true
colorBox.TextWrapped = true

local textBox = Instance.new("TextBox", commandsPage)
textBox.Size = UDim2.new(1, -20, 0, 30)
textBox.Position = UDim2.new(0, 10, 0, 200)
textBox.PlaceholderText = "النص (مثل hello، test...)"
textBox.Text = ""
textBox.TextSize = 16
textBox.TextColor3 = Color3.new(1, 1, 1)
textBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
textBox.Visible = false
textBox.ZIndex = 3
textBox.TextScaled = true
textBox.TextWrapped = true

local cmdFrame = Instance.new("ScrollingFrame", commandsPage)
cmdFrame.Size = UDim2.new(1, -20, 1, -260)
cmdFrame.Position = UDim2.new(0, 10, 0, 260)
cmdFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
cmdFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
cmdFrame.ScrollBarThickness = 6
cmdFrame.ZIndex = 3

-- صفحة السبام
local spamContainer = Instance.new("Frame", spamPage)
spamContainer.Size = UDim2.new(1, -20, 1, -20)
spamContainer.Position = UDim2.new(0, 10, 0, 10)
spamContainer.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
spamContainer.BorderSizePixel = 0
spamContainer.ZIndex = 2

local spamTextBox = Instance.new("TextBox", spamContainer)
spamTextBox.Size = UDim2.new(0.8, 0, 0, 50)
spamTextBox.Position = UDim2.new(0.1, 0, 0.3, 0)
spamTextBox.PlaceholderText = "اكتب النص المراد إرساله كسبام..."
spamTextBox.Text = ""
spamTextBox.TextSize = 16
spamTextBox.TextColor3 = Color3.new(1, 1, 1)
spamTextBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
spamTextBox.TextWrapped = true
spamTextBox.ZIndex = 3
spamTextBox.TextScaled = true

local spamBtn = Instance.new("TextButton", spamContainer)
spamBtn.Size = UDim2.new(0.3, 0, 0, 30)
spamBtn.Position = UDim2.new(0.35, 0, 0.5, 0)
spamBtn.Text = "تفعيل السبام"
spamBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
spamBtn.TextColor3 = Color3.new(1, 1, 1)
spamBtn.Font = Enum.Font.SourceSansBold
spamBtn.TextSize = 16
spamBtn.ZIndex = 3
spamBtn.TextScaled = true
spamBtn.TextWrapped = true

-- صفحة الصفحة الرئيسية
local infoContainer = Instance.new("Frame", infoPage)
infoContainer.Size = UDim2.new(1, -20, 1, -20)
infoContainer.Position = UDim2.new(0, 10, 0, 10)
infoContainer.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
infoContainer.BorderSizePixel = 0
infoContainer.ZIndex = 2

local profileImage = Instance.new("ImageLabel", infoContainer)
profileImage.Size = UDim2.new(0, 150, 0, 150)
profileImage.Position = UDim2.new(0, 10, 0, 10)
profileImage.BackgroundTransparency = 1
profileImage.Image = string.format("https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=420&height=420&format=png", player.UserId)
profileImage.ZIndex = 3

local infoLabel = Instance.new("TextLabel", infoContainer)
infoLabel.Size = UDim2.new(1, -180, 1, -20)
infoLabel.Position = UDim2.new(0, 170, 0, 10)
infoLabel.Text = "جارٍ التحميل..."
infoLabel.TextColor3 = Color3.new(1, 1, 1)
infoLabel.TextSize = 16
infoLabel.BackgroundTransparency = 1
infoLabel.TextWrapped = true
infoLabel.TextYAlignment = Enum.TextYAlignment.Top
infoLabel.ZIndex = 3
infoLabel.TextScaled = true

-- صفحة قائمة الاستهداف
local targetContainer = Instance.new("Frame", targetPage)
targetContainer.Size = UDim2.new(1, -20, 1, -60)
targetContainer.Position = UDim2.new(0, 10, 0, 10)
targetContainer.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
targetContainer.BorderSizePixel = 0
targetContainer.ZIndex = 2

local targetProfileImage = Instance.new("ImageLabel", targetContainer)
targetProfileImage.Size = UDim2.new(0, 150, 0, 150)
targetProfileImage.Position = UDim2.new(0, 10, 0, 10)
targetProfileImage.BackgroundTransparency = 1
targetProfileImage.ZIndex = 3

local targetInfoLabel = Instance.new("TextLabel", targetContainer)
targetInfoLabel.Size = UDim2.new(1, -180, 1, -20)
targetInfoLabel.Position = UDim2.new(0, 170, 0, 10)
targetInfoLabel.Text = "لم يتم تحديد لاعب مستهدف بعد..."
targetInfoLabel.TextColor3 = Color3.new(1, 1, 1)
targetInfoLabel.TextSize = 16
targetInfoLabel.BackgroundTransparency = 1
targetInfoLabel.TextWrapped = true
targetInfoLabel.TextYAlignment = Enum.TextYAlignment.Top
targetInfoLabel.ZIndex = 3
targetInfoLabel.TextScaled = true

local espBtn = Instance.new("TextButton", targetPage)
espBtn.Size = UDim2.new(0.3, 0, 0, 30)
espBtn.Position = UDim2.new(0.35, 0, 0.85, 0)
espBtn.Text = "تفعيل ESP"
espBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
espBtn.TextColor3 = Color3.new(1, 1, 1)
espBtn.Font = Enum.Font.SourceSansBold
espBtn.TextSize = 16
espBtn.ZIndex = 3
espBtn.TextScaled = true
espBtn.TextWrapped = true

-- صفحة الحماية (جديدة)
local protectionContainer = Instance.new("Frame", protectionPage)
protectionContainer.Size = UDim2.new(1, -20, 1, -20)
protectionContainer.Position = UDim2.new(0, 10, 0, 10)
protectionContainer.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
protectionContainer.BorderSizePixel = 0
protectionContainer.ZIndex = 2

local protectionLabel = Instance.new("TextLabel", protectionContainer)
protectionLabel.Size = UDim2.new(1, 0, 0, 50)
protectionLabel.Position = UDim2.new(0, 0, 0, 10)
protectionLabel.Text = "الحماية: تمنع الأوامر من التأثير عليك"
protectionLabel.TextColor3 = Color3.new(1, 1, 1)
protectionLabel.TextSize = 18
protectionLabel.BackgroundTransparency = 1
protectionLabel.TextWrapped = true
protectionLabel.TextYAlignment = Enum.TextYAlignment.Center
protectionLabel.ZIndex = 3
protectionLabel.TextScaled = true

local protectionBtn = Instance.new("TextButton", protectionContainer)
protectionBtn.Size = UDim2.new(0.3, 0, 0, 30)
protectionBtn.Position = UDim2.new(0.35, 0, 0.5, 0)
protectionBtn.Text = "تفعيل الحماية"
protectionBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
protectionBtn.TextColor3 = Color3.new(1, 1, 1)
protectionBtn.Font = Enum.Font.SourceSansBold
protectionBtn.TextSize = 16LogicalLine 1: protectionBtn.ZIndex = 3
protectionBtn.TextScaled = true
protectionBtn.TextWrapped = true

-- تحديث معلومات اللاعب
local function updateInfoPage()
    local info = getPlayerInfo(player)
    infoLabel.Text = string.format(
        "معلوماتك:\n\nالاسم: %s\nاسم العرض: %s\nالمعرف: %d\nتاريخ الإنشاء: %s\nالموقع: %s",
        info.username, info.displayName, info.userId, info.creationDate, info.location
    )
end

-- تحديث معلومات اللاعب المستهدف
local function updateTargetPage()
    if targetedPlayer then
        local info = getPlayerInfo(targetedPlayer)
        targetProfileImage.Image = info.thumbnailUrl
        targetInfoLabel.Text = string.format(
            "معلومات اللاعب المستهدف:\n\nالاسم: %s\nاسم العرض: %s\nالمعرف: %d\nتاريخ الإنشاء: %s\nالموقع: %s",
            info.username, info.displayName, info.userId, info.creationDate, info.location
        )
    else
        targetProfileImage.Image = ""
        targetInfoLabel.Text = "لم يتم تحديد لاعب مستهدف بعد..."
    end
end

-- تحديث معلومات اللاعب عند تحميل السكربت
updateInfoPage()

-- تحديث اللاعب المستهدف عند تغيير اسم اللاعب في لوحة الأوامر
nameBox:GetPropertyChangedSignal("Text"):Connect(function()
    local playerNames = findPlayer(nameBox.Text)
    if #playerNames == 1 then
        targetedPlayer = Players:FindFirstChild(playerNames[1])
    else
        targetedPlayer = nil -- لا يمكن تطبيق ESP على لاعبين متعددين
    end
    updateTargetPage()
end)

-- الأوامر (مع إضافة ;ice في الأعلى)
local allCommands = {
    {cmd = "ice", args = "<player>", category = "playerOnly"}, -- الأمر الجديد
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

-- وظيفة إنشاء أزرار الأوامر (محدثة لتحسين ترتيب الأوامر)
local function createCommandButton(cmdData, yOffset)
    local btnFrame = Instance.new("Frame", cmdFrame)
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
        print("تم النقر على زر التحديد للأمر: " .. cmdData.cmd)
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
        print("تم النقر على زر المفضلة للأمر: " .. cmdData.cmd)
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
        print("تم النقر على زر النسخ للأمر: " .. cmdData.cmd)
        local playerNames = findPlayer(nameBox.Text)
        local commandsToCopy = {}
        for _, playerName in ipairs(playerNames) do
            local cleanedPlayerName = cleanPlayerName(playerName)
            if cleanedPlayerName == "" then continue end -- تجاهل الأسماء الفارغة
            local commandText = ";" .. cmdData.cmd .. " " .. cleanedPlayerName
            if cmdData.category == "withArgs" then
                local replacementText = ""
                if string.find(cmdData.args, "<number") or string.find(cmdData.args, "<scale") then
                    replacementText = numberBox.Text
                elseif string.find(cmdData.args, "<color") then
                    replacementText = colorBox.Text
                elseif string.find(cmdData.args, "<text") or string.find(cmdData.args, "<material") then
                    replacementText = textBox.Text
                end
                if replacementText ~= "" then
                    commandText = string.gsub(commandText, "<[^>]+>", replacementText, 1)
                end
            end
            table.insert(commandsToCopy, commandText)
            wait(0.1) -- تأخير بسيط بين كل أمر لضمان التنفيذ
        end
        -- تنسيق الأوامر: كل أمر في سطر منفصل
        local finalText = table.concat(commandsToCopy, "\n") .. "\n" .. string.rep(".", 500) -- إضافة 500 نقطة
        copyToClipboard(finalText)
    end)

    return 70
end

-- وظيفة لعرض الأوامر مع التقسيم
local function displayCommands(commands)
    cmdFrame:ClearAllChildren()
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

    numberBox.Visible = #withArgsCommands > 0
    colorBox.Visible = #withArgsCommands > 0
    textBox.Visible = #withArgsCommands > 0

    if #playerOnlyCommands > 0 then
        local sectionLabel = Instance.new("TextLabel", cmdFrame)
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
            local divider = Instance.new("Frame", cmdFrame)
            divider.Size = UDim2.new(1, 0, 0, 1)
            divider.Position = UDim2.new(0, 0, 0, yOffset - 10)
            divider.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
            divider.BorderSizePixel = 0
            divider.ZIndex = 4
        end
    end

    if #playerOnlyCommands > 0 and #withArgsCommands > 0 then
        local divider = Instance.new("Frame", cmdFrame)
        divider.Size = UDim2.new(1, 0, 0, 2)
        divider.Position = UDim2.new(0, 0, 0, yOffset)
        divider.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        divider.BorderSizePixel = 0
        divider.ZIndex = 4
        yOffset = yOffset + 10
    end

    if #withArgsCommands > 0 then
        local sectionLabel = Instance.new("TextLabel", cmdFrame)
        sectionLabel.Size = UDim2.new(1, 0, 0, 20)
        sectionLabel.Position = UDim2.new(0, 0, 0, yOffset)
        sectionLabel.Text = "الاوامر الي تحتوي على اراقم الخ"
        sectionLabel.TextColor3 = Color3.new(1, 1, 1)
        sectionLabel.TextSize = 16
        sectionLabel.BackgroundTransparency = 1
        sectionLabel.ZIndex = 4
        sectionLabel.TextScaled = true
        sectionLabel.TextWrapped = true
        yOffset = yOffset + 20

        for _, cmd in ipairs(withArgsCommands) do
            yOffset = yOffset + createCommandButton(cmd, yOffset)
            local divider = Instance.new("Frame", cmdFrame)
            divider.Size = UDim2.new(1, 0, 0, 1)
            divider.Position = UDim2.new(0, 0, 0, yOffset - 10)
            divider.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
            divider.BorderSizePixel = 0
            divider.ZIndex = 4
        end
    end

    cmdFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset)
end

-- عرض كل الأوامر في البداية
displayCommands(allCommands)

-- البحث عن الأوامر
searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    print("تم تغيير نص البحث إلى: " .. searchBox.Text)
    local searchText = string.lower(searchBox.Text)
    if searchText == "" then
        displayCommands(allCommands)
        return
    end
    local filteredCommands = {}
    for _, cmd in ipairs(allCommands) do
        if string.lower(cmd.cmd):find(searchText) then
            table.insert(filteredCommands, cmd)
        end
    end
    displayCommands(filteredCommands)
end)

playerOnlyBtn.MouseButton1Click:Connect(function()
    print("تم النقر على زر أوامر <player>")
    local filteredCommands = {}
    for _, cmd in ipairs(allCommands) do
        if cmd.category == "playerOnly" then
            table.insert(filteredCommands, cmd)
        end
    end
    displayCommands(filteredCommands)
end)

withArgsBtn.MouseButton1Click:Connect(function()
    print("تم النقر على زر أوامر مع وسيطات")
    local filteredCommands = {}
    for _, cmd in ipairs(allCommands) do
        if cmd.category == "withArgs" then
            table.insert(filteredCommands, cmd)
        end
    end
    displayCommands(filteredCommands)
end)

favoritesBtn.MouseButton1Click:Connect(function()
    print("تم النقر على زر المفضلة")
    if #favoriteCommands == 0 then
        copyToClipboard("لا توجد أوامر مفضلة!")
        return
    end
    displayCommands(favoriteCommands)
end)

selectBtn.MouseButton1Click:Connect(function()
    print("تم النقر على زر تحديد الأوامر")
    displayCommands(allCommands)
end)

-- زر تحديد كل اللاعبين
selectAllBtn.MouseButton1Click:Connect(function()
    print("تم النقر على زر تحديد كل اللاعبين")
    local allPlayers = getAllPlayers()
    if allPlayers == "" then
        copyToClipboard("لا يوجد لاعبون في السيرفر!")
        return
    end
    nameBox.Text = allPlayers
    copyToClipboard("تم تحديد جميع اللاعبين: " .. allPlayers)
end)

-- زر إلغاء تحديد كل اللاعبين
clearAllPlayersBtn.MouseButton1Click:Connect(function()
    print("تم النقر على زر إلغاء تحديد كل اللاعبين")
    nameBox.Text = player.Name
    copyToClipboard("تم إلغاء تحديد جميع اللاعبين")
end)

copySelectedBtn.MouseButton1Click:Connect(function()
    print("تم النقر على زر نسخ المحدد")
    if #selectedCommands == 0 then
        copyToClipboard("لم يتم تحديد أي أوامر!")
        return
    end
    local playerNames = findPlayer(nameBox.Text)
    local combinedCommands = {}
    for _, cmdData in ipairs(selectedCommands) do
        for _, playerName in ipairs(playerNames) do
            local cleanedPlayerName = cleanPlayerName(playerName)
            if cleanedPlayerName == "" then continue end -- تجاهل الأسماء الفارغة
            local commandText = ";" .. cmdData.cmd .. " " .. cleanedPlayerName
            if cmdData.category == "withArgs" then
                local replacementText = ""
                if string.find(cmdData.args, "<number") or string.find(cmdData.args, "<scale") then
                    replacementText = numberBox.Text
                elseif string.find(cmdData.args, "<color") then
                    replacementText = colorBox.Text
                elseif string.find(cmdData.args, "<text") or string.find(cmdData.args, "<material") then
                    replacementText = textBox.Text
                end
                if replacementText ~= "" then
                    commandText = string.gsub(commandText, "<[^>]+>", replacementText, 1)
                end
            end
            table.insert(combinedCommands, commandText)
            wait(0.1) -- تأخير بسيط بين كل أمر لضمان التنفيذ
        end
    end
    -- تنسيق الأوامر: كل أمر في سطر منفصل
    local finalText = table.concat(combinedCommands, "\n") .. "\n" .. string.rep(".", 500) -- إضافة 500 نقطة
    copyToClipboard(finalText)
    for _, child in ipairs(cmdFrame:GetChildren()) do
        if child:IsA("Frame") then
            local isFavorite = false
            for _, favCmd in ipairs(favoriteCommands) do
                if favCmd.cmd == child.Name then
                    isFavorite = true
                    break
                end
            end
            child.BackgroundColor3 = isFavorite and Color3.fromRGB(100, 75, 0) or Color3.fromRGB(45, 45, 45)
            local selectBtn = child:FindFirstChildWhichIsA("TextButton")
            if selectBtn and (selectBtn.Text == "+" or selectBtn.Text == "✔") then
                selectBtn.Text = "+"
                selectBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            end
        end
    end
    selectedCommands = {}
end)

clearSelectionBtn.MouseButton1Click:Connect(function()
    print("تم النقر على زر إلغاء التحديد")
    for _, child in ipairs(cmdFrame:GetChildren()) do
        if child:IsA("Frame") then
            local isFavorite = false
            for _, favCmd in ipairs(favoriteCommands) do
                if favCmd.cmd == child.Name then
                    isFavorite = true
                    break
                end
            end
            child.BackgroundColor3 = isFavorite and Color3.fromRGB(100, 75, 0) or Color3.fromRGB(45, 45, 45)
            local selectBtn = child:FindFirstChildWhichIsA("TextButton")
            if selectBtn and (selectBtn.Text == "+" or selectBtn.Text == "✔") then
                selectBtn.Text = "+"
                selectBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            end
        end
    end
    selectedCommands = {}
end)

-- التبديل بين الصفحات
local function showPage(page)
    commandsPage.Visible = (page == commandsPage)
    targetPage.Visible = (page == targetPage)
    protectionPage.Visible = (page == protectionPage)
    spamPage.Visible = (page == spamPage)
    infoPage.Visible = (page == infoPage)
    targetPageBtn.BackgroundColor3 = (page == targetPage) and Color3.fromRGB(80, 80, 80) or Color3.fromRGB(60, 60, 60)
    protectionPageBtn.BackgroundColor3 = (page == protectionPage) and Color3.fromRGB(80, 80, 80) or Color3.fromRGB(60, 60, 60)
    spamPageBtn.BackgroundColor3 = (page == spamPage) and Color3.fromRGB(80, 80, 80) or Color3.fromRGB(60, 60, 60)
    commandsPageBtn.BackgroundColor3 = (page == commandsPage) and Color3.fromRGB(80, 80, 80) or Color3.fromRGB(60, 60, 60)
    infoPageBtn.BackgroundColor3 = (page == infoPage) and Color3.fromRGB(80, 80, 80) or Color3.fromRGB(60, 60, 60)
end

targetPageBtn.MouseButton1Click:Connect(function()
    print("تم النقر على زر قائمة الاستهداف")
    showPage(targetPage)
end)

protectionPageBtn.MouseButton1Click:Connect(function()
    print("تم النقر على زر الحماية")
    showPage(protectionPage)
end)

spamPageBtn.MouseButton1Click:Connect(function()
    print("تم النقر على زر السبام")
    showPage(spamPage)
end)

commandsPageBtn.MouseButton1Click:Connect(function()
    print("تم النقر على زر لوحة الأوامر")
    showPage(commandsPage)
end)

infoPageBtn.MouseButton1Click:Connect(function()
    print("تم النقر على زر الصفحة الرئيسية")
    showPage(infoPage)
end)

-- تفعيل/إيقاف الـ ESP
espBtn.MouseButton1Click:Connect(function()
    print("تم النقر على زر تفعيل/إيقاف ESP")
    if not targetedPlayer then
        copyToClipboard("لم يتم تحديد لاعب مستهدف!")
        return
    end
    espEnabled = not espEnabled
    espBtn.Text = espEnabled and "إيقاف ESP" or "تفعيل ESP"
    espBtn.BackgroundColor3 = espEnabled and Color3.fromRGB(200, 0, 0) or Color3.fromRGB(0, 150, 0)
    toggleESP(targetedPlayer, espEnabled)
end)

-- تفعيل/إيقاف السبام
spamBtn.MouseButton1Click:Connect(function()
    print("تم النقر على زر تفعيل/إيقاف السبام")
    spamEnabled = not spamEnabled
    spamBtn.Text = spamEnabled and "إيقاف السبام" or "تفعيل السبام"
    spamBtn.BackgroundColor3 = spamEnabled and Color3.fromRGB(200, 0, 0) or Color3.fromRGB(0, 150, 0)

    if spamEnabled then
        local message = spamTextBox.Text
        if message == "" then
            copyToClipboard("يرجى إدخال نص للسبام!")
            spamEnabled = false
            spamBtn.Text = "تفعيل السبام"
            spamBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
            return
        end
        spamThread = coroutine.create(function()
            while spamEnabled do
                sendMessageToChat(message)
                wait(0.5) -- تأخير بسيط بين كل رسالة
            end
        end)
        coroutine.resume(spamThread)
    else
        spamThread = nil
    end
end)

-- تفعيل/إيقاف الحماية
protectionBtn.MouseButton1Click:Connect(function()
    print("تم النقر على زر تفعيل/إيقاف الحماية")
    protectionEnabled = not protectionEnabled
    protectionBtn.Text = protectionEnabled and "إيقاف الحماية" or "تفعيل الحماية"
    protectionBtn.BackgroundColor3 = protectionEnabled and Color3.fromRGB(200, 0, 0) or Color3.fromRGB(0, 150, 0)
    toggleProtection(protectionEnabled)
end)

-- إغلاق الواجهة
hideBtn.MouseButton1Click:Connect(function()
    print("تم النقر على زر الإغلاق")
    screenGui:Destroy()
    if espEnabled then
        toggleESP(targetedPlayer, false)
    end
    if spamEnabled then
        spamEnabled = false
        spamThread = nil
    end
    if protectionEnabled then
        toggleProtection(false)
    end
end)