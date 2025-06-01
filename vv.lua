-- Gui to Lua
-- Version: 3.2

-- Services and Variables
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local TextChatService = game:GetService("TextChatService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local selectedCommands = {}
local favoriteCommands = {}
local targetedPlayer = nil
local espEnabled = false
local espHighlight = nil
local protectionEnabled = false
local protectionConnections = {}
local includeSelf = true
local isDragging = false
local dragStart = nil
local dragPosition = nil

-- Clean player name
local function cleanPlayerName(name)
    name = string.gsub(name, "^%s*(.-)%s*$", "%1")
    name = string.gsub(name, "[^%w_]", "")
    return name
end

-- Find player by partial name
local function findPlayer(partialName)
    if partialName == "" then return {player.Name} end
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
            game:GetService("StarterGui"):SetCore("SendNotification", {Title = "⚠️", Text = "لم يتم العثور على لاعب باسم: " .. name, Duration = 3})
            table.insert(playerNames, name)
        end
    end
    return playerNames
end

-- Get all players
local function getAllPlayers()
    local playerNames = {}
    for _, p in pairs(Players:GetPlayers()) do
        if not includeSelf and p == player then continue end
        table.insert(playerNames, p.Name)
    end
    return table.concat(playerNames, ",")
end

-- Copy text to clipboard
local function copyToClipboard(text)
    local success, err = pcall(function() setclipboard(text) end)
    if success then
        game:GetService("StarterGui"):SetCore("SendNotification", {Title = "تم النسخ!", Text = text, Duration = 3})
    else
        game:GetService("StarterGui"):SetCore("SendNotification", {Title = "فشل النسخ", Text = "تعذر النسخ، تحقق من وحدة التحكم (F9)", Duration = 3})
    end
end

-- Get player info
local function getPlayerInfo(playerObj)
    local userId = playerObj.UserId
    local info = {
        userId = userId,
        displayName = playerObj.DisplayName,
        username = playerObj.Name
    }
    local success, result = pcall(function()
        return game:GetService("Players"):GetHumanoidDescriptionFromUserId(userId)
    end)
    info.creationDate = success and os.date("%Y-%m-%d", playerObj.AccountAge * 86400 + os.time()) or "غير متوفر"
    info.location = "غير متوفر (يمكن تخصيصه)"
    info.thumbnailUrl = string.format("https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=420&height=420&format=png", userId)
    return info
end

-- Toggle ESP
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

-- Toggle protection
local function toggleProtection(enable)
    if enable then
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            local humanoid = player.Character.Humanoid
            humanoid.MaxHealth = math.huge
            humanoid.Health = math.huge
            humanoid.WalkSpeed = 16
            humanoid.JumpPower = 50
            table.insert(protectionConnections, humanoid:GetPropertyChangedSignal("Health"):Connect(function()
                if protectionEnabled then humanoid.Health = math.huge end
            end))
            table.insert(protectionConnections, humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
                if protectionEnabled then humanoid.WalkSpeed = 16 end
            end))
            table.insert(protectionConnections, humanoid:GetPropertyChangedSignal("JumpPower"):Connect(function()
                if protectionEnabled then humanoid.JumpPower = 50 end
            end))
            table.insert(protectionConnections, humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(function()
                if protectionEnabled then humanoid.MaxHealth = math.huge humanoid.Health = math.huge end
            end))
        end
        if player.Character then
            for _, part in pairs(player.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    local originalSize = part.Size
                    local originalTransparency = part.Transparency
                    table.insert(protectionConnections, part:GetPropertyChangedSignal("Size"):Connect(function()
                        if protectionEnabled then part.Size = originalSize end
                    end))
                    table.insert(protectionConnections, part:GetPropertyChangedSignal("Transparency"):Connect(function()
                        if protectionEnabled then part.Transparency = originalTransparency end
                    end))
                    table.insert(protectionConnections, part:GetPropertyChangedSignal("CanCollide"):Connect(function()
                        if protectionEnabled then part.CanCollide = true end
                    end))
                end
            end
        end
        if player.Character then
            table.insert(protectionConnections, player.Character.ChildRemoved:Connect(function(child)
                if protectionEnabled and child:IsA("BasePart") then player:LoadCharacter() end
            end))
        end
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = player.Character.HumanoidRootPart
            local lastPosition = hrp.Position
            table.insert(protectionConnections, RunService.Heartbeat:Connect(function()
                if protectionEnabled then
                    local currentPosition = hrp.Position
                    local distance = (currentPosition - lastPosition).Magnitude
                    if distance > 50 then hrp.Position = lastPosition else lastPosition = currentPosition end
                end
            end))
        end
        table.insert(protectionConnections, player.CharacterAdded:Connect(function(character)
            if protectionEnabled then wait(0.1) toggleProtection(true) end
        end))
    else
        for _, connection in pairs(protectionConnections) do connection:Disconnect() end
        protectionConnections = {}
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            local humanoid = player.Character.Humanoid
            humanoid.MaxHealth = 100
            humanoid.Health = 100
            humanoid.WalkSpeed = 16
            humanoid.JumpPower = 50
        end
    end
end

-- Instances
local ScreenGui = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")
local UICorner = Instance.new("UICorner")
local Frame_2 = Instance.new("Frame")
local UICorner_2 = Instance.new("UICorner")
local home = Instance.new("TextButton")
local UICorner_3 = Instance.new("UICorner")
local player = Instance.new("TextButton")
local UICorner_4 = Instance.new("UICorner")
local asthdaf = Instance.new("TextButton")
local UICorner_5 = Instance.new("UICorner")
local aoamr = Instance.new("TextButton")
local UICorner_6 = Instance.new("UICorner")
local homefarm = Instance.new("Frame")
local TextLabel = Instance.new("TextLabel")
local TextLabel_2 = Instance.new("TextLabel")
local ImageLabel = Instance.new("ImageLabel")
local ImageLabel_2 = Instance.new("ImageLabel")
local Frame_3 = Instance.new("Frame")
local Frame_4 = Instance.new("Frame")
local ProfilePic = Instance.new("ImageLabel")
local TextButton = Instance.new("TextButton")
local playerfarm = Instance.new("Frame")
local SPEED = Instance.new("TextButton")
local TextBox = Instance.new("TextBox")
local NOCLIP = Instance.new("TextButton")
local FLY = Instance.new("TextButton")
local TextButton_2 = Instance.new("TextButton")
local Frame_5 = Instance.new("Frame")
local Frame_6 = Instance.new("Frame")
local ScrollingFrame = Instance.new("ScrollingFrame")
local ImageLabel_3 = Instance.new("ImageLabel")
local TextButton_3 = Instance.new("TextButton")
local TextBox_2 = Instance.new("TextBox")
local Frame_7 = Instance.new("Frame")
local TextButton_4 = Instance.new("TextButton")
local TextLabel_6 = Instance.new("TextLabel")
local Frame_8 = Instance.new("Frame")
local ScrollingFrame_2 = Instance.new("ScrollingFrame")
local TextBox_3 = Instance.new("TextBox")
local TextButton_5 = Instance.new("TextButton")
local TextButton_6 = Instance.new("TextButton")
local TextButton_7 = Instance.new("TextButton")
local TextButton_8 = Instance.new("TextButton")
local TextButton_9 = Instance.new("TextButton")
local TextButton_10 = Instance.new("TextButton")
local TextButton_11 = Instance.new("TextButton")
local TextButton_12 = Instance.new("TextButton")
local player_2 = Instance.new("TextButton")
local TextLabel_3 = Instance.new("TextLabel")
local TextBox_4 = Instance.new("TextBox")
local TextLabel_4 = Instance.new("TextLabel")
local TextBox_5 = Instance.new("TextBox")
local TextBox_6 = Instance.new("TextBox")
local TextBox_7 = Instance.new("TextBox")
local TextLabel_5 = Instance.new("TextLabel")
local Frame_9 = Instance.new("Frame")
local ImageButton = Instance.new("ImageButton")
local BackgroundImage = Instance.new("ImageLabel")

-- Properties
ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

Frame.Name = "فارم اساسي"
Frame.Parent = ScreenGui
Frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
Frame.BorderSizePixel = 0
Frame.Position = UDim2.new(0.195546955, 0, 0.221105531, 0)
Frame.Size = UDim2.new(0, 620, 0, 430)

UICorner.CornerRadius = UDim.new(0.1, 0)
UICorner.Parent = Frame

Frame_2.Parent = Frame
Frame_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Frame_2.BorderColor3 = Color3.fromRGB(0, 0, 0)
Frame_2.BorderSizePixel = 0
Frame_2.Position = UDim2.new(0.148387089, 0, 0.0267062169, 0)
Frame_2.Size = UDim2.new(0, 10, 0, 406)

UICorner_2.CornerRadius = UDim.new(77, 100)
UICorner_2.Parent = Frame_2

home.Name = "home"
home.Parent = Frame
home.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
home.BorderColor3 = Color3.fromRGB(0, 0, 0)
home.BorderSizePixel = 0
home.Position = UDim2.new(0.0310386419, 0, 0.0691215917, 0)
home.Size = UDim2.new(0, 58, 0, 37)
home.Font = Enum.Font.SourceSans
home.Text = "home"
home.TextColor3 = Color3.fromRGB(0, 0, 0)
home.TextSize = 14.000

UICorner_3.CornerRadius = UDim.new(0.5, 0)
UICorner_3.Parent = home

player.Name = "player"
player.Parent = Frame
player.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
player.BorderColor3 = Color3.fromRGB(0, 0, 0)
player.BorderSizePixel = 0
player.Position = UDim2.new(0.0310386419, 0, 0.280996978, 0)
player.Size = UDim2.new(0, 58, 0, 37)
player.Font = Enum.Font.SourceSans
player.Text = "الاعب"
player.TextColor3 = Color3.fromRGB(0, 0, 0)
player.TextSize = 14.000

UICorner_4.CornerRadius = UDim.new(0.5, 0)
UICorner_4.Parent = player

asthdaf.Name = "asthdaf"
asthdaf.Parent = Frame
asthdaf.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
asthdaf.BorderColor3 = Color3.fromRGB(0, 0, 0)
asthdaf.BorderSizePixel = 0
asthdaf.Position = UDim2.new(0.0310386419, 0, 0.486937582, 0)
asthdaf.Size = UDim2.new(0, 58, 0, 37)
asthdaf.Font = Enum.Font.SourceSans
asthdaf.Text = "استهداف"
asthdaf.TextColor3 = Color3.fromRGB(0, 0, 0)
asthdaf.TextSize = 14.000

UICorner_5.CornerRadius = UDim.new(0.5, 0)
UICorner_5.Parent = asthdaf

aoamr.Name = "aoamr"
aoamr.Parent = Frame
aoamr.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
aoamr.BorderColor3 = Color3.fromRGB(0, 0, 0)
aoamr.BorderSizePixel = 0
aoamr.Position = UDim2.new(0.0310386419, 0, 0.700524151, 0)
aoamr.Size = UDim2.new(0, 58, 0, 37)
aoamr.Font = Enum.Font.SourceSans
aoamr.Text = "اوامر"
aoamr.TextColor3 = Color3.fromRGB(0, 0, 0)
aoamr.TextSize = 14.000

UICorner_6.CornerRadius = UDim.new(0.5, 0)
UICorner_6.Parent = aoamr

homefarm.Name = "home farm"
homefarm.Parent = Frame
homefarm.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
homefarm.BackgroundTransparency = 1.000
homefarm.BorderColor3 = Color3.fromRGB(0, 0, 0)
homefarm.BorderSizePixel = 0
homefarm.Position = UDim2.new(0.190322578, 0, 0.0267062318, 0)
homefarm.Size = UDim2.new(0, 473, 0, 305)

TextLabel.Name = "فريق طرب"
TextLabel.Parent = homefarm
TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TextLabel.BackgroundTransparency = 1.000
TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
TextLabel.BorderSizePixel = 0
TextLabel.Position = UDim2.new(0.395348847, 0, 1.01311469, 0)
TextLabel.Size = UDim2.new(0, 200, 0, 50)
TextLabel.Font = Enum.Font.SourceSans
TextLabel.Text = "تطوير فريق 6RB "
TextLabel.TextColor3 = Color3.fromRGB(134, 255, 255)
TextLabel.TextSize = 81.000
TextLabel.TextStrokeColor3 = Color3.fromRGB(64, 255, 239)

TextLabel_2.Name = "قناه تيليجرام"
TextLabel_2.Parent = homefarm
TextLabel_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TextLabel_2.BackgroundTransparency = 1.000
TextLabel_2.BorderColor3 = Color3.fromRGB(0, 0, 0)
TextLabel_2.BorderSizePixel = 0
TextLabel_2.Position = UDim2.new(0.562367857, 0, 0.652458906, 0)
TextLabel_2.Size = UDim2.new(0, 67, 0, 33)
TextLabel_2.Font = Enum.Font.SourceSans
TextLabel_2.Text = "قناتنا في التيليجرام للتحديثات"
TextLabel_2.TextColor3 = Color3.fromRGB(134, 255, 255)
TextLabel_2.TextSize = 36.000
TextLabel_2.TextStrokeColor3 = Color3.fromRGB(64, 255, 239)

ImageLabel.Name = "تيليجرام صوره"
ImageLabel.Parent = homefarm
ImageLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ImageLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
ImageLabel.BorderSizePixel = 0
ImageLabel.Position = UDim2.new(0.272727281, 0, 0.78360647, 0)
ImageLabel.Size = UDim2.new(0, 32, 0, 31)
ImageLabel.Image = "http://www.roblox.com/asset/?id=18698848592"

ImageLabel_2.Name = "حزين صوره"
ImageLabel_2.Parent = homefarm
ImageLabel_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ImageLabel_2.BorderColor3 = Color3.fromRGB(0, 0, 0)
ImageLabel_2.BorderSizePixel = 0
ImageLabel_2.Position = UDim2.new(-0.00211416488, 0, 1.01311469, 0)
ImageLabel_2.Size = UDim2.new(0, 88, 0, 76)
ImageLabel_2.Image = "http://www.roblox.com/asset/?id=16846967991"

Frame_3.Name = "ايطار نص"
Frame_3.Parent = homefarm
Frame_3.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Frame_3.BackgroundTransparency = 1.000
Frame_3.BorderColor3 = Color3.fromRGB(0, 0, 0)
Frame_3.BorderSizePixel = 0
Frame_3.Position = UDim2.new(0.221987322, 0, 0.60655725, 0)
Frame_3.Size = UDim2.new(0, 378, 0, 212)

Frame_4.Name = "ايطار"
Frame_4.Parent = homefarm
Frame_4.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
Frame_4.BackgroundTransparency = 1.000
Frame_4.BorderColor3 = Color3.fromRGB(0, 0, 0)
Frame_4.BorderSizePixel = 0
Frame_4.Position = UDim2.new(-0.00211416488, 0, 0, 0)
Frame_4.Size = UDim2.new(0, 163, 0, 162)

ProfilePic.Name = "ProfilePic"
ProfilePic.Parent = homefarm
ProfilePic.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ProfilePic.BorderColor3 = Color3.fromRGB(0, 0, 0)
ProfilePic.BorderSizePixel = 0
ProfilePic.Position = UDim2.new(-0.00211416488, 0, 0, 0)
ProfilePic.Size = UDim2.new(0, 162, 0, 161)
ProfilePic.Image = string.format("https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=420&height=420&format=png", player.UserId)

TextButton.Parent = homefarm
TextButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TextButton.BackgroundTransparency = 1.000
TextButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
TextButton.BorderSizePixel = 0
TextButton.Position = UDim2.new(0.420718819, 0, 0.783606529, 0)
TextButton.Size = UDim2.new(0, 200, 0, 50)
TextButton.Font = Enum.Font.SourceSans
TextButton.Text = "اضغط هنا لنسخ رابط القناه"
TextButton.TextColor3 = Color3.fromRGB(255, 0, 0)
TextButton.TextSize = 27.000

playerfarm.Name = "player farm"
playerfarm.Parent = Frame
playerfarm.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
playerfarm.BackgroundTransparency = 1.000
playerfarm.BorderColor3 = Color3.fromRGB(0, 0, 0)
playerfarm.BorderSizePixel = 0
playerfarm.Position = UDim2.new(0.190322578, 0, 0.0267062318, 0)
playerfarm.Size = UDim2.new(0, 473, 0, 305)
playerfarm.Visible = false

SPEED.Name = "SPEED"
SPEED.Parent = playerfarm
SPEED.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SPEED.BorderColor3 = Color3.fromRGB(0, 0, 0)
SPEED.BorderSizePixel = 0
SPEED.Position = UDim2.new(1.29038384e-07, 0, 0.085245803, 0)
SPEED.Size = UDim2.new(0, 118, 0, 39)
SPEED.Font = Enum.Font.SourceSans
SPEED.Text = "SPEED"
SPEED.TextColor3 = Color3.fromRGB(0, 0, 0)
SPEED.TextSize = 34.000

TextBox.Parent = SPEED
TextBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TextBox.BorderColor3 = Color3.fromRGB(0, 0, 0)
TextBox.BorderSizePixel = 0
TextBox.Position = UDim2.new(0.237288132, 0, 1.38461542, 0)
TextBox.Size = UDim2.new(0, 61, 0, 39)
TextBox.Font = Enum.Font.SourceSans
TextBox.Text = "999-0"
TextBox.TextColor3 = Color3.fromRGB(0, 0, 0)
TextBox.TextSize = 14.000

NOCLIP.Name = "NOCLIP"
NOCLIP.Parent = playerfarm
NOCLIP.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
NOCLIP.BorderColor3 = Color3.fromRGB(0, 0, 0)
NOCLIP.BorderSizePixel = 0
NOCLIP.Position = UDim2.new(0.340380669, 0, 0.085245803, 0)
NOCLIP.Size = UDim2.new(0, 118, 0, 39)
NOCLIP.Font = Enum.Font.SourceSans
NOCLIP.Text = "NOCLIP"
NOCLIP.TextColor3 = Color3.fromRGB(0, 0, 0)
NOCLIP.TextSize = 34.000

FLY.Name = "FLY"
FLY.Parent = playerfarm
FLY.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
FLY.BorderColor3 = Color3.fromRGB(0, 0, 0)
FLY.BorderSizePixel = 0
FLY.Position = UDim2.new(0.691332042, 0, 0.085245803, 0)
FLY.Size = UDim2.new(0, 118, 0, 39)
FLY.Font = Enum.Font.SourceSans
FLY.Text = "FLY"
FLY.TextColor3 = Color3.fromRGB(0, 0, 0)
FLY.TextSize = 34.000

TextButton_2.Name = "حمايه من الاوامر"
TextButton_2.Parent = playerfarm
TextButton_2.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
TextButton_2.BorderColor3 = Color3.fromRGB(0, 0, 0)
TextButton_2.BorderSizePixel = 0
TextButton_2.Position = UDim2.new(0.141649172, 0, 0.51803267, 0)
TextButton_2.Size = UDim2.new(0, 306, 0, 39)
TextButton_2.Font = Enum.Font.SourceSans
TextButton_2.Text = "حماية من الاوامر"
TextButton_2.TextColor3 = Color3.fromRGB(0, 0, 0)
TextButton_2.TextSize = 34.000

Frame_5.Parent = playerfarm
Frame_5.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Frame_5.BackgroundTransparency = 1.000
Frame_5.BorderColor3 = Color3.fromRGB(0, 0, 0)
Frame_5.BorderSizePixel = 0
Frame_5.Position = UDim2.new(-0.0147991544, 0, 0, 0)
Frame_5.Size = UDim2.new(0, 460, 0, 214)

Frame_6.Name = "استهداف فارم"
Frame_6.Parent = Frame
Frame_6.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Frame_6.BackgroundTransparency = 1.000
Frame_6.BorderColor3 = Color3.fromRGB(0, 0, 0)
Frame_6.BorderSizePixel = 0
Frame_6.Position = UDim2.new(0.190322578, 0, 0.0267062318, 0)
Frame_6.Size = UDim2.new(0, 473, 0, 305)
Frame_6.Visible = false

ScrollingFrame.Parent = Frame_6
ScrollingFrame.Active = true
ScrollingFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ScrollingFrame.BackgroundTransparency = 1.000
ScrollingFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
ScrollingFrame.BorderSizePixel = 0
ScrollingFrame.Position = UDim2.new(0, 0, -5.00288166e-08, 0)
ScrollingFrame.Size = UDim2.new(0, 486, 0, 399)

ImageLabel_3.Name = "صوره الاعب (بروفايله)"
ImageLabel_3.Parent = ScrollingFrame
ImageLabel_3.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ImageLabel_3.BorderColor3 = Color3.fromRGB(0, 0, 0)
ImageLabel_3.BorderSizePixel = 0
ImageLabel_3.Position = UDim2.new(0.326925516, 0, 0.0219533816, 0)
ImageLabel_3.Size = UDim2.new(0, 147, 0, 137)
ImageLabel_3.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"

TextButton_3.Name = "انتقل اليه"
TextButton_3.Parent = ScrollingFrame
TextButton_3.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TextButton_3.BorderColor3 = Color3.fromRGB(0, 0, 0)
TextButton_3.BorderSizePixel = 0
TextButton_3.Position = UDim2.new(0.683271348, 0, 0.488721639, 0)
TextButton_3.Size = UDim2.new(0, 118, 0, 39)
TextButton_3.Font = Enum.Font.SourceSans
TextButton_3.Text = "انتقل اليه"
TextButton_3.TextColor3 = Color3.fromRGB(0, 0, 0)
TextButton_3.TextSize = 34.000

TextBox_2.Parent = ScrollingFrame
TextBox_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TextBox_2.BorderColor3 = Color3.fromRGB(0, 0, 0)
TextBox_2.BorderSizePixel = 0
TextBox_2.Position = UDim2.new(0.272444487, 0, 0.312013626, 0)
TextBox_2.Size = UDim2.new(0, 200, 0, 50)
TextBox_2.Font = Enum.Font.SourceSans
TextBox_2.Text = "اسم الاعب"
TextBox_2.TextColor3 = Color3.fromRGB(0, 0, 0)
TextBox_2.TextSize = 40.000

Frame_7.Parent = TextBox_2
Frame_7.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Frame_7.BackgroundTransparency = 1.000
Frame_7.BorderColor3 = Color3.fromRGB(0, 0, 0)
Frame_7.BorderSizePixel = 0
Frame_7.Size = UDim2.new(0, 200, 0, 50)
Frame_7.ZIndex = 0

TextButton_4.Name = "مشاهده"
TextButton_4.Parent = ScrollingFrame
TextButton_4.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TextButton_4.BorderColor3 = Color3.fromRGB(0, 0, 0)
TextButton_4.BorderSizePixel = 0
TextButton_4.Position = UDim2.new(0.0841142908, 0, 0.488721639, 0)
TextButton_4.Size = UDim2.new(0, 118, 0, 39)
TextButton_4.Font = Enum.Font.SourceSans
TextButton_4.Text = "مشاهده"
TextButton_4.TextColor3 = Color3.fromRGB(0, 0, 0)
TextButton_4.TextSize = 34.000

TextLabel_6.Name = "معلومات اللاعب"
TextLabel_6.Parent = ScrollingFrame
TextLabel_6.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TextLabel_6.BackgroundTransparency = 1.000
TextLabel_6.BorderColor3 = Color3.fromRGB(0, 0, 0)
TextLabel_6.BorderSizePixel = 0
TextLabel_6.Position = UDim2.new(0.0411522659, 0, 0.6265664101, 0)
TextLabel_6.Size = UDim2.new(0, 400, 0, 150)
TextLabel_6.Font = Enum.Font.SourceSans
TextLabel_6.Text = "لم يتم تحديد لاعب مستهدف بعد..."
TextLabel_6.TextColor3 = Color3.fromRGB(255, 255, 255)
TextLabel_6.TextSize = 20.000
TextLabel_6.TextWrapped = true
TextLabel_6.TextYAlignment = Enum.TextYAlignment.Top
TextLabel_6.TextScaled = true

Frame_8.Name = "فارم الاوامر"
Frame_8.Parent = Frame
Frame_8.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Frame_8.BackgroundTransparency = 1.000
Frame_8.BorderColor3 = Color3.fromRGB(0, 0, 0)
Frame_8.BorderSizePixel = 0
Frame_8.Position = UDim2.new(0.190322578, 0, 0.0267061815, 0)
Frame_8.Size = UDim2.new(0, 473, 0, 405)
Frame_8.Visible = false

ScrollingFrame_2.Parent = Frame_8
ScrollingFrame_2.Active = true
ScrollingFrame_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ScrollingFrame_2.BackgroundTransparency = 1.000
ScrollingFrame_2.BorderColor3 = Color3.fromRGB(0, 0, 0)
ScrollingFrame_2.BorderSizePixel = 0
ScrollingFrame_2.Size = UDim2.new(0, 493, 0, 418)
ScrollingFrame_2.CanvasSize = UDim2.new(0, 0, 0, 0)

TextBox_3.Name = "بحث عن امر"
TextBox_3.Parent = ScrollingFrame_2
TextBox_3.BackgroundColor3 = Color3.fromRGB(118, 118, 118)
TextBox_3.BorderColor3 = Color3.fromRGB(0, 0, 0)
TextBox_3.BorderSizePixel = 0
TextBox_3.Position = UDim2.new(0.126272917, 0, -0.000461049058, 0)
TextBox_3.Size = UDim2.new(0, 337, 0, 50)
TextBox_3.Font = Enum.Font.SourceSans
TextBox_3.PlaceholderColor3 = Color3.fromRGB(80, 80, 80)
TextBox_3.Text = "بحث عن امر"
TextBox_3.TextColor3 = Color3.fromRGB(0, 0, 0)
TextBox_3.TextSize = 26.000

TextButton_5.Name = "تحديد كل الاعبين"
TextButton_5.Parent = ScrollingFrame_2
TextButton_5.BackgroundColor3 = Color3.fromRGB(255, 224, 49)
TextButton_5.BorderColor3 = Color3.fromRGB(0, 0, 0)
TextButton_5.BorderSizePixel = 0
TextButton_5.Position = UDim2.new(0.765848339, 0, 0.0701975822, 0)
TextButton_5.Size = UDim2.new(0, 88, 0, 38)
TextButton_5.Font = Enum.Font.SourceSans
TextButton_5.Text = "تحديد كل الاعبين!"
TextButton_5.TextColor3 = Color3.fromRGB(0, 0, 0)
TextButton_5.TextScaled = true
TextButton_5.TextSize = 14.000
TextButton_5.TextWrapped = true

TextButton_6.Name = "نسخ المحدد"
TextButton_6.Parent = ScrollingFrame_2
TextButton_6.BackgroundColor3 = Color3.fromRGB(255, 224, 49)
TextButton_6.BorderColor3 = Color3.fromRGB(0, 0, 0)
TextButton_6.BorderSizePixel = 0
TextButton_6.Position = UDim2.new(0.532532334, 0, 0.0706484839, 0)
TextButton_6.Size = UDim2.new(0, 88, 0, 38)
TextButton_6.Font = Enum.Font.SourceSans
TextButton_6.Text = "نسخ المحدد!"
TextButton_6.TextColor3 = Color3.fromRGB(0, 0, 0)
TextButton_6.TextSize = 20.000

TextButton_7.Name = "الغاء تحديد كل الاعبين"
TextButton_7.Parent = ScrollingFrame_2
TextButton_7.BackgroundColor3 = Color3.fromRGB(255, 224, 49)
TextButton_7.BorderColor3 = Color3.fromRGB(0, 0, 0)
TextButton_7.BorderSizePixel = 0
TextButton_7.Position = UDim2.new(0.303161025, 0, 0.0691919625, 0)
TextButton_7.Size = UDim2.new(0, 88, 0, 38)
TextButton_7.Font = Enum.Font.SourceSans
TextButton_7.Text = "الغاء تحديد كل الاعبين!"
TextButton_7.TextColor3 = Color3.fromRGB(0, 0, 0)
TextButton_7.TextScaled = true
TextButton_7.TextSize = 15.000
TextButton_7.TextWrapped = true

TextButton_8.Name = "المفضله"
TextButton_8.Parent = ScrollingFrame_2
TextButton_8.BackgroundColor3 = Color3.fromRGB(223, 223, 223)
TextButton_8.BorderColor3 = Color3.fromRGB(0, 0, 0)
TextButton_8.BorderSizePixel = 0
TextButton_8.Position = UDim2.new(0.304623336, 0, 0.12993443, 0)
TextButton_8.Size = UDim2.new(0, 88, 0, 38)
TextButton_8.Font = Enum.Font.SourceSans
TextButton_8.Text = "المفضلة ⭐"
TextButton_8.TextColor3 = Color3.fromRGB(0, 0, 0)
TextButton_8.TextScaled = true
TextButton_8.TextSize = 15.000
TextButton_8.TextWrapped = true

TextButton_9.Name = "تحديد كل الاوامر"
TextButton_9.Parent = ScrollingFrame_2
TextButton_9.BackgroundColor3 = Color3.fromRGB(255, 224, 49)
TextButton_9.BorderColor3 = Color3.fromRGB(0, 0, 0)
TextButton_9.BorderSizePixel = 0
TextButton_9.Position = UDim2.new(0.767226219, 0, 0.130236462, 0)
TextButton_9.Size = UDim2.new(0, 88, 0, 38)
TextButton_9.Font = Enum.Font.SourceSans
TextButton_9.Text = "تحديد كل الاوامر!"
TextButton_9.TextColor3 = Color3.fromRGB(0, 0, 0)
TextButton_9.TextScaled = true
TextButton_9.TextSize = 14.000
TextButton_9.TextWrapped = true

TextButton_10.Name = "الغاء تحديد كل الاوامر"
TextButton_10.Parent = ScrollingFrame_2
TextButton_10.BackgroundColor3 = Color3.fromRGB(255, 224, 49)
TextButton_10.BorderColor3 = Color3.fromRGB(0, 0, 0)
TextButton_10.BorderSizePixel = 0
TextButton_10.Position = UDim2.new(0.532512248, 0, 0.129390523, 0)
TextButton_10.Size = UDim2.new(0, 88, 0, 38)
TextButton_10.Font = Enum.Font.SourceSans
TextButton_10.Text = "الغاء تحديد كل الاوامر!"
TextButton_10.TextColor3 = Color3.fromRGB(0, 0, 0)
TextButton_10.TextScaled = true
TextButton_10.TextSize = 14.000
TextButton_10.TextWrapped = true

TextButton_11.Name = "اوامر مع اراقم"
TextButton_11.Parent = ScrollingFrame_2
TextButton_11.BackgroundColor3 = Color3.fromRGB(85, 255, 255)
TextButton_11.BorderColor3 = Color3.fromRGB(0, 0, 0)
TextButton_11.BorderSizePixel = 0
TextButton_11.Position = UDim2.new(0.0462406911, 0, 0.129701018, 0)
TextButton_11.Size = UDim2.new(0, 88, 0, 38)
TextButton_11.Font = Enum.Font.SourceSans
TextButton_11.Text = "اوامر مع اراقم!"
TextButton_11.TextColor3 = Color3.fromRGB(0, 0, 0)
TextButton_11.TextScaled = true
TextButton_11.TextSize = 25.000
TextButton_11.TextWrapped = true

TextButton_12.Name = "عدم احتسابي"
TextButton_12.Parent = ScrollingFrame_2
TextButton_12.BackgroundColor3 = Color3.fromRGB(85, 255, 255)
TextButton_12.BorderColor3 = Color3.fromRGB(0, 0, 0)
TextButton_12.BorderSizePixel = 0
TextButton_12.Position = UDim2.new(0.0462406911, 0, 0.189701018, 0)
TextButton_12.Size = UDim2.new(0, 88, 0, 38)
TextButton_12.Font = Enum.Font.SourceSans
TextButton_12.Text = "عدم احتسابي!"
TextButton_12.TextColor3 = Color3.fromRGB(0, 0, 0)
TextButton_12.TextScaled = true
TextButton_12.TextSize = 25.000
TextButton_12.TextWrapped = true

player_2.Name = "اوامر player"
player_2.Parent = ScrollingFrame_2
player_2.BackgroundColor3 = Color3.fromRGB(85, 255, 255)
player_2.BorderColor3 = Color3.fromRGB(0, 0, 0)
player_2.BorderSizePixel = 0
player_2.Position = UDim2.new(0.0462406911, 0, 0.068048574, 0)
player_2.Size = UDim2.new(0, 88, 0, 38)
player_2.Font = Enum.Font.SourceSans
player_2.Text = "اوامر player!"
player_2.TextColor3 = Color3.fromRGB(0, 0, 0)
player_2.TextScaled = true
player_2.TextSize = 15.000
player_2.TextWrapped = true

TextLabel_3.Parent = ScrollingFrame_2
TextLabel_3.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TextLabel_3.BackgroundTransparency = 1.000
TextLabel_3.BorderColor3 = Color3.fromRGB(0, 0, 0)
TextLabel_3.BorderSizePixel = 0
TextLabel_3.Position = UDim2.new(0.309664696, 0, 0.209089726, 0)
TextLabel_3.Size = UDim2.new(0, 200, 0, 50)
TextLabel_3.Font = Enum.Font.SourceSans
TextLabel_3.Text = "------------------------------------------"
TextLabel_3.TextColor3 = Color3.fromRGB(255, 255, 255)
TextLabel_3.TextSize = 46.000

TextBox_4.Name = "اسم الاعب"
TextBox_4.Parent = ScrollingFrame_2
TextBox_4.BackgroundColor3 = Color3.fromRGB(118, 118, 118)
TextBox_4.BorderColor3 = Color3.fromRGB(0, 0, 0)
TextBox_4.BorderSizePixel = 0
TextBox_4.Position = UDim2.new(0.140079662, 0, 0.260316402, 0)
TextBox_4.Size = UDim2.new(0, 337, 0, 50)
TextBox_4.Font = Enum.Font.SourceSans
TextBox_4.PlaceholderColor3 = Color3.fromRGB(80, 80, 80)
TextBox_4.Text = "اسم الاعب"
TextBox_4.TextColor3 = Color3.fromRGB(0, 0, 0)
TextBox_4.TextSize = 26.000

TextLabel_4.Parent = ScrollingFrame_2
TextLabel_4.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TextLabel_4.BackgroundTransparency = 1.000
TextLabel_4.BorderColor3 = Color3.fromRGB(0, 0, 0)
TextLabel_4.BorderSizePixel = 0
TextLabel_4.Position = UDim2.new(0.274161726, 0, 0.310035378, 0)
TextLabel_4.Size = UDim2.new(0, 200, 0, 50)
TextLabel_4.Font = Enum.Font.SourceSans
TextLabel_4.Text = "--------------------------------"
TextLabel_4.TextColor3 = Color3.fromRGB(255, 255, 255)
TextLabel_4.TextSize = 46.000

TextBox_5.Name = "الارقام"
TextBox_5.Parent = ScrollingFrame_2
TextBox_5.BackgroundColor3 = Color3.fromRGB(118, 118, 118)
TextBox_5.BorderColor3 = Color3.fromRGB(0, 0, 0)
TextBox_5.BorderSizePixel = 0
TextBox_5.Position = UDim2.new(0.140079662, 0, 0.380038977, 0)
TextBox_5.Size = UDim2.new(0, 337, 0, 50)
TextBox_5.Font = Enum.Font.SourceSans
TextBox_5.PlaceholderColor3 = Color3.fromRGB(80, 80, 80)
TextBox_5.Text = "الارقام"
TextBox_5.TextColor3 = Color3.fromRGB(0, 0, 0)
TextBox_5.TextSize = 26.000

TextBox_6.Name = "اللون"
TextBox_6.Parent = ScrollingFrame_2
TextBox_6.BackgroundColor3 = Color3.fromRGB(118, 118, 118)
TextBox_6.BorderColor3 = Color3.fromRGB(0, 0, 0)
TextBox_6.BorderSizePixel = 0
TextBox_6.Position = UDim2.new(0.140079662, 0, 0.456933647, 0)
TextBox_6.Size = UDim2.new(0, 337, 0, 50)
TextBox_6.Font = Enum.Font.SourceSans
TextBox_6.PlaceholderColor3 = Color3.fromRGB(80, 80, 80)
TextBox_6.Text = "اللون"
TextBox_6.TextColor3 = Color3.fromRGB(0, 0, 0)
TextBox_6.TextSize = 26.000

TextBox_7.Name = "النص"
TextBox_7.Parent = ScrollingFrame_2
TextBox_7.BackgroundColor3 = Color3.fromRGB(118, 118, 118)
TextBox_7.BorderColor3 = Color3.fromRGB(0, 0, 0)
TextBox_7.BorderSizePixel = 0
TextBox_7.Position = UDim2.new(0.140079662, 0, 0.541346729, 0)
TextBox_7.Size = UDim2.new(0, 337, 0, 50)
TextBox_7.Font = Enum.Font.SourceSans
TextBox_7.PlaceholderColor3 = Color3.fromRGB(80, 80, 80)
TextBox_7.Text = "النص"
TextBox_7.TextColor3 = Color3.fromRGB(0, 0, 0)
TextBox_7.TextSize = 26.000

TextLabel_5.Parent = ScrollingFrame_2
TextLabel_5.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TextLabel_5.BackgroundTransparency = 1.000
TextLabel_5.BorderColor3 = Color3.fromRGB(0, 0, 0)
TextLabel_5.BorderSizePixel = 0
TextLabel_5.Position = UDim2.new(0.260355026, 0, 0.59640038, 0)
TextLabel_5.Size = UDim2.new(0, 200, 0, 50)
TextLabel_5.Font = Enum.Font.SourceSans
TextLabel_5.Text = "--------------------------------"
TextLabel_5.TextColor3 = Color3.fromRGB(255, 255, 255)
TextLabel_5.TextSize = 46.000

Frame_9.Parent = ScrollingFrame_2
Frame_9.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Frame_9.BackgroundTransparency = 1.000
Frame_9.BorderColor3 = Color3.fromRGB(0, 0, 0)
Frame_9.BorderSizePixel = 0
Frame_9.Position = UDim2.new(0.0710059181, 0, 0.646810412, 0)
Frame_9.Size = UDim2.new(0, 392, 0, 427)

ImageButton.Name = "هذه الزر تقفل و تظهر الواجهه"
ImageButton.Parent = ScreenGui
ImageButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ImageButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
ImageButton.BorderSizePixel = 0
ImageButton.Position = UDim2.new(0.128, 0, 0.108, 0)
ImageButton.Size = UDim2.new(0, 42, 0, 42)
ImageButton.Image = "http://www.roblox.com/asset/?id=15483082894"

BackgroundImage.Name = "BackgroundImage"
BackgroundImage.Parent = Frame
BackgroundImage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
BackgroundImage.BorderColor3 = Color3.fromRGB(0, 0, 0)
BackgroundImage.BorderSizePixel = 0
BackgroundImage.Position = UDim2.new(-0.000419272139, 0, -0.00144639122, 0)
BackgroundImage.Size = UDim2.new(0, 620, 0, 437)
BackgroundImage.ZIndex = 0
BackgroundImage.Image = "http://www.roblox.com/asset/?id=1748728214"
BackgroundImage.ImageColor3 = Color3.fromRGB(43, 43, 43)

-- Commands List
local allCommands = {
    { cmd = "ice", args = "<player>", category = "playerOnly" },
    { cmd = "jail", args = "<player>", category = "playerOnly" },
    { cmd = "kill", args = "<player>", category = "playerOnly" },
    { cmd = "kick", args = "<player>", category = "playerOnly" },
    { cmd = "ban", args = "<player>", category = "playerOnly" },
    { cmd = "size", args = "<player> <scale>", category = "withArgs" },
    { cmd = "paint", args = "<player> <color>", category = "withArgs" },
    { cmd = "title", args = "<player> <text>", category = "withArgs" }
}

-- Create Command Button
local function createCommandButton(cmdData, yOffset)
    local btnFrame = Instance.new("Frame")
    btnFrame.Parent = ScrollingFrame_2
    btnFrame.Size = UDim2.new(1, 0, 0, 60)
    btnFrame.Position = UDim2.new(0, 0, 0, yOffset)
    btnFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    btnFrame.Name = cmdData.cmd

    local cmdText = Instance.new("TextLabel")
    cmdText.Parent = btnFrame
    cmdText.Size = UDim2.new(1, -10, 0, 30)
    cmdText.Position = UDim2.new(0, 5, 0, 0)
    cmdText.Text = ";" .. cmdData.cmd .. " " .. cmdData.args
    cmdText.TextColor3 = Color3.new(1, 1, 1)
    cmdText.TextSize = 14
    cmdText.TextXAlignment = Enum.TextXAlignment.Left
    cmdText.BackgroundTransparency = 1
    cmdText.TextScaled = true
    cmdText.TextWrapped = true

    local copyBtn = Instance.new("TextButton")
    copyBtn.Parent = btnFrame
    copyBtn.Size = UDim2.new(0.2, 0, 0, 20)
    copyBtn.Position = UDim2.new(0, 5, 0, 35)
    copyBtn.Text = "نسخ"
    copyBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    copyBtn.TextColor3 = Color3.new(1, 1, 1)
    copyBtn.TextSize = 12
    copyBtn.TextScaled = true
    copyBtn.TextWrapped = true

    local favoriteBtn = Instance.new("TextButton")
    favoriteBtn.Parent = btnFrame
    favoriteBtn.Size = UDim2.new(0.2, 0, 0, 20)
    favoriteBtn.Position = UDim2.new(0.25, 0, 0, 35)
    favoriteBtn.Text = "⭐"
    favoriteBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
    favoriteBtn.TextColor3 = Color3.new(1, 1, 1)
    favoriteBtn.TextSize = 12
    favoriteBtn.TextScaled = true
    favoriteBtn.TextWrapped = true

    local selectCmdBtn = Instance.new("TextButton")
    selectCmdBtn.Parent = btnFrame
    selectCmdBtn.Size = UDim2.new(0.2, 0, 0, 20)
    selectCmdBtn.Position = UDim2.new(0.5, 0, 0, 35)
    selectCmdBtn.Text = "+"
    selectCmdBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    selectCmdBtn.TextColor3 = Color3.new(1, 1, 1)
    selectCmdBtn.TextSize = 12
    selectCmdBtn.TextScaled = true
    selectCmdBtn.TextWrapped = true

    local isSelected = false
    local isFavorite = false

    for _, cmd in ipairs(selectedCommands) do
        if cmd.cmd == cmdData.cmd then
            isSelected = true
            selectCmdBtn.Text = "✔"
            selectCmdBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            break
        end
    end

    for _, cmd in ipairs(favoriteCommands) do
        if cmd.cmd == cmdData.cmd then
            isFavorite = true
            favoriteBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
            btnFrame.BackgroundColor3 = Color3.fromRGB(100, 75, 0)
            break
        end
    end

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
        local playerNames = findPlayer(TextBox_4.Text)
        local commandsToCopy = {}
        for _, playerName in ipairs(playerNames) do
            local cleanedPlayerName = cleanPlayerName(playerName)
            if cleanedPlayerName == "" then continue end
            local commandText = ";" .. cmdData.cmd .. " " .. cleanedPlayerName
            if cmdData.category == "withArgs" then
                local replacementText = ""
                if string.find(cmdData.args, "<scale") then
                    replacementText = TextBox_5.Text
                elseif string.find(cmdData.args, "<color") then
                    replacementText = TextBox_6.Text
                elseif string.find(cmdData.args, "<text") then
                    replacementText = TextBox_7.Text
                end
                if replacementText ~= "" and replacementText ~= "الارقام" and replacementText ~= "اللون" and replacementText ~= "النص" then
                    commandText = string.gsub(commandText, "<[^>]+>", replacementText, 1)
                end
            end
            table.insert(commandsToCopy, commandText)
            wait(0.1)
        end
        local finalText = table.concat(commandsToCopy, "\n\n") .. "\n\n" .. string.rep(".", 500)
        copyToClipboard(finalText)
    end)

    return 70
end

-- Display Commands
local function displayCommands(commands)
    for _, child in ipairs(ScrollingFrame_2:GetChildren()) do
        if child.Name ~= "بحث عن امر" and child.Name ~= "تحديد كل الاعبين" and child.Name ~= "نسخ المحدد" and child.Name ~= "الغاء تحديد كل الاعبين" and child.Name ~= "المفضله" and child.Name ~= "تحديد كل الاوامر" and child.Name ~= "الغاء تحديد كل الاوامر" and child.Name ~= "اوامر مع اراقم" and child.Name ~= "اوامر player" and child.Name ~= "عدم احتسابي" and child.Name ~= "اسم الاعب" and child.Name ~= "الارقام" and child.Name ~= "اللون" and child.Name ~= "النص" and not child:IsA("TextLabel") then
            child:Destroy()
        end
    end

    local yOffset = 300
    local playerOnlyCommands = {}
    local withArgsCommands = {}

    for _, cmd in ipairs(commands) do
        if cmd.category == "playerOnly" then
            table.insert(playerOnlyCommands, cmd)
        else
            table.insert(withArgsCommands, cmd)
        end
    end

    TextBox_5.Visible = #withArgsCommands > 0
    TextBox_6.Visible = #withArgsCommands > 0
    TextBox_7.Visible = #withArgsCommands > 0

    if #playerOnlyCommands > 0 then
        local sectionLabel = Instance.new("TextLabel")
        sectionLabel.Parent = ScrollingFrame_2
        sectionLabel.Size = UDim2.new(1, 0, 0, 20)
        sectionLabel.Position = UDim2.new(0, 0, 0, yOffset)
        sectionLabel.Text = "الأوامر التي تحتوي على اسم اللاعب"
        sectionLabel.TextColor3 = Color3.new(1, 1, 1)
        sectionLabel.TextSize = 16
        sectionLabel.BackgroundTransparency = 1
        sectionLabel.TextScaled = true
        sectionLabel.TextWrapped = true
        yOffset = yOffset + 20

        for _, cmd in ipairs(playerOnlyCommands) do
            yOffset = yOffset + createCommandButton(cmd, yOffset)
            local divider = Instance.new("Frame")
            divider.Parent = ScrollingFrame_2
            divider.Size = UDim2.new(1, 0, 0, 1)
            divider.Position = UDim2.new(0, 0, 0, yOffset - 10)
            divider.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
            divider.BorderSizePixel = 0
        end
    end

    if #playerOnlyCommands > 0 and #withArgsCommands > 0 then
        local divider = Instance.new("Frame")
        divider.Parent = ScrollingFrame_2
        divider.Size = UDim2.new(1, 0, 0, 2)
        divider.Position = UDim2.new(0, 0, 0, yOffset)
        divider.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        divider.BorderSizePixel = 0
        yOffset = yOffset + 10
    end

    if #withArgsCommands > 0 then
        local sectionLabel = Instance.new("TextLabel")
        sectionLabel.Parent = ScrollingFrame_2
        sectionLabel.Size = UDim2.new(1, 0, 0, 20)
        sectionLabel.Position = UDim2.new(0, 0, 0, yOffset)
        sectionLabel.Text = "الأوامر التي تحتوي على أرقام وغيرها"
        sectionLabel.TextColor3 = Color3.new(1, 1, 1)
        sectionLabel.TextSize = 16
        sectionLabel.BackgroundTransparency = 1
        sectionLabel.TextScaled = true
        sectionLabel.TextWrapped = true
        yOffset = yOffset + 20

        for _, cmd in ipairs(withArgsCommands) do
            yOffset = yOffset + createCommandButton(cmd, yOffset)
            local divider = Instance.new("Frame")
            divider.Parent = ScrollingFrame_2
            divider.Size = UDim2.new(1, 0, 0, 1)
            divider.Position = UDim2.new(0, 0, 0, yOffset - 10)
            divider.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
            divider.BorderSizePixel = 0
        end
    end

    ScrollingFrame_2.CanvasSize = UDim2.new(0, 0, 0, yOffset)
end

-- Update Target Page
local function updateTargetPage()
    if targetedPlayer then
        local info = getPlayerInfo(targetedPlayer)
        ImageLabel_3.Image = info.thumbnailUrl
        TextLabel_6.Text = string.format(
            "معلومات اللاعب المستهدف:\n\nالاسم: %s\nاسم العرض: %s\nالمعرف: %d\nتاريخ الإنشاء: %s\nالموقع: %s",
            info.username, info.displayName, info.userId, info.creationDate, info.location
        )
    else
        ImageLabel_3.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
        TextLabel_6.Text = "لم يتم تحديد لاعب مستهدف بعد..."
    end
end

-- Scripts
local function setupGUI()
    local tabs = {
        home = "home farm",
        player = "player farm",
        asthdaf = "استهداف فارم",
        aoamr = "فارم الاوامر",
    }

    local function hideAllTabs()
        for _, sectionName in pairs(tabs) do
            local section = Frame:FindFirstChild(sectionName)
            if section then section.Visible = false end
        end
    end

    for buttonName, sectionName in pairs(tabs) do
        local button = Frame:FindFirstChild(buttonName)
        local section = Frame:FindFirstChild(sectionName)
        if button and section then
            button.MouseButton1Click:Connect(function()
                hideAllTabs()
                section.Visible = true
                button.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
                wait(0.1)
                button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            end)
        end
    end

    hideAllTabs()
    homefarm.Visible = true

    local function onInputBegan(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = true
            dragStart = input.Position
            dragPosition = Vector2.new(Frame.Position.X.Offset, Frame.Position.Y.Offset)
        end
    end

    local function onInputChanged(input)
        if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            Frame.Position = UDim2.new(0, dragPosition.X + delta.X, 0, dragPosition.Y + delta.Y)
        end
    end

    local function onInputEnded(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = false
        end
    end

    Frame.InputBegan:Connect(onInputBegan)
    UserInputService.InputChanged:Connect(onInputChanged)
    UserInputService.InputEnded:Connect(onInputEnded)

    local isVisible = true
    ImageButton.MouseButton1Click:Connect(function()
        isVisible = not isVisible
        Frame.Visible = isVisible
        ImageButton.BackgroundColor3 = isVisible and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(0, 255, 0)
    end)

    TextButton_2.MouseButton1Click:Connect(function()
        protectionEnabled = not protectionEnabled
        TextButton_2.Text = protectionEnabled and "إيقاف الحماية" or "حماية من الاوامر"
        TextButton_2.BackgroundColor3 = protectionEnabled and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(255, 0, 0)
        toggleProtection(protectionEnabled)
    end)

    TextBox_2:GetPropertyChangedSignal("Text"):Connect(function()
        local playerNames = findPlayer(TextBox_2.Text)
        if #playerNames == 1 then
            targetedPlayer = Players:FindFirstChild(playerNames[1])
        else
            targetedPlayer = nil
        end
        updateTargetPage()
    end)

    TextButton_3.MouseButton1Click:Connect(function()
        if targetedPlayer and targetedPlayer.Character and targetedPlayer.Character:FindFirstChild("HumanoidRootPart") and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            player.Character.HumanoidRootPart.CFrame = targetedPlayer.Character.HumanoidRootPart.CFrame
        else
            copyToClipboard("لم يتم تحديد لاعب مستهدف أو اللاعب غير موجود!")
        end
    end)

    TextButton_4.MouseButton1Click:Connect(function()
        if not targetedPlayer then
            copyToClipboard("لم يتم تحديد لاعب مستهدف!")
            return
        end
        espEnabled = not espEnabled
        TextButton_4.Text = espEnabled and "إيقاف ESP" or "مشاهده"
        TextButton_4.BackgroundColor3 = espEnabled and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(255, 255, 255)
        toggleESP(targetedPlayer, espEnabled)
    end)

    displayCommands(allCommands)

    TextBox_3:GetPropertyChangedSignal("Text"):Connect(function()
        local searchText = string.lower(TextBox_3.Text)
        if searchText == "" or searchText == "بحث عن امر" then
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

    player_2.MouseButton1Click:Connect(function()
        local filteredCommands = {}
        for _, cmd in ipairs(allCommands) do
            if cmd.category == "playerOnly" then
                table.insert(filteredCommands, cmd)
            end
        end
        displayCommands(filteredCommands)
    end)

    TextButton_11.MouseButton1Click:Connect(function()
        local filteredCommands = {}
        for _, cmd in ipairs(allCommands) do
            if cmd.category == "withArgs" then
                table.insert(filteredCommands, cmd)
            end
        end
        displayCommands(filteredCommands)
    end)

    TextButton_8.MouseButton1Click:Connect(function()
        if #favoriteCommands == 0 then
            copyToClipboard("لا توجد أوامر مفضلة!")
            return
        end
        displayCommands(favoriteCommands)
    end)

    TextButton_5.MouseButton1Click:Connect(function()
        local allPlayers = getAllPlayers()
        if allPlayers == "" then
            copyToClipboard("لا يوجد لاعبون في السيرفر!")
            return
        end
        TextBox_4.Text = allPlayers
        copyToClipboard("تم تحديد جميع اللاعبين: " .. allPlayers)
    end)

    TextButton_7.MouseButton1Click:Connect(function()
        TextBox_4.Text = player.Name
        copyToClipboard("تم إلغاء تحديد جميع اللاعبين")
    end)

    TextButton_12.MouseButton1Click:Connect(function()
        includeSelf = not includeSelf
        TextButton_12.BackgroundColor3 = includeSelf and Color3.fromRGB(85, 255, 255) or Color3.fromRGB(255, 0, 0)
        copyToClipboard(includeSelf and "تم احتسابك مع اللاعبين!" or "تم استثناؤك من اللاعبين!")
    end)

    TextButton_6.MouseButton1Click:Connect(function()
        if #selectedCommands == 0 then
            copyToClipboard("لم يتم تحديد أي أوامر!")
            return
        end
        local playerNames = findPlayer(TextBox_4.Text)
        local combinedCommands = {}
        for _, cmdData in ipairs(selectedCommands) do
            for _, playerName in ipairs(playerNames) do
                local cleanedPlayerName = cleanPlayerName(playerName)
                if cleanedPlayerName == "" then continue end
                local commandText = ";" .. cmdData.cmd .. " " .. cleanedPlayerName
                if cmdData.category == "withArgs" then
                    local replacementText = ""
                    if string.find(cmdData.args, "<scale") then
                        replacementText = TextBox_5.Text
                    elseif string.find(cmdData.args, "<color") then
                        replacementText = TextBox_6.Text
                    elseif string.find(cmdData.args, "<text") then
                        replacementText = TextBox_7.Text
                    end
                    if replacementText ~= "" and replacementText ~= "الارقام" and replacementText ~= "اللون" and replacementText ~= "النص" then
                        commandText = string.gsub(commandText, "<[^>]+>", replacementText, 1)
                    end
                end
                table.insert(combinedCommands