local Players=game:GetService("Players")
local Camera=workspace.CurrentCamera
local RunService=game:GetService("RunService")
local UserInputService=game:GetService("UserInputService")
local Player=Players.LocalPlayer
local isAimbotActive=false
local isUIVisible=true
local isESPActive=false
local isEnemiesOnlyESP=false
local isEnemiesOnlyAimbot=false
local TargetPart="Head"
local FOVCircle=nil
local FOVRadius=150
local strengthPresets={{level=1,smoothness=0.3,fov=100},{level=2,smoothness=0.15,fov=150},{level=3,smoothness=0.07,fov=200},{level=4,smoothness=0.05,fov=250}}
local currentStrength=2
local screenSize=Camera.ViewportSize
local content=Players:GetUserThumbnailAsync(Player.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size100x100)
local ScreenGui=Instance.new("ScreenGui",game.CoreGui)
ScreenGui.Name="TRP_AimbotUI"
ScreenGui.ResetOnSpawn=false
ScreenGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
local ToggleButton=Instance.new("TextButton")
ToggleButton.Size=UDim2.new(0,40,0,40)
ToggleButton.Position=UDim2.new(0.95,-40,0.05,0)
ToggleButton.BackgroundColor3=Color3.fromRGB(30,30,30)
ToggleButton.Text="≡"
ToggleButton.TextColor3=Color3.fromRGB(255,255,255)
ToggleButton.TextSize=20
ToggleButton.ZIndex=10
ToggleButton.Parent=ScreenGui
local MainFrame=Instance.new("Frame")
MainFrame.BackgroundColor3=Color3.fromRGB(31,31,31)
MainFrame.Position=UDim2.new(0.3,0,0.3,0)
MainFrame.Size=UDim2.new(0,500,0,400)
MainFrame.ZIndex=5
MainFrame.Parent=ScreenGui
local isDragging=false
local dragInputStartPos,dragFrameStartPos
local function startDragging(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 then
        isDragging=true
        dragInputStartPos=input.Position
        dragFrameStartPos=Vector2.new(MainFrame.Position.X.Offset,MainFrame.Position.Y.Offset)
    end
end
local function updateDragging(input)
    if isDragging and input.UserInputType==Enum.UserInputType.MouseMovement then
        local delta=input.Position-dragInputStartPos
        MainFrame.Position=UDim2.new(0,dragFrameStartPos.X+delta.X,0,dragFrameStartPos.Y+delta.Y)
    end
end
local function stopDragging(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 then
        isDragging=false
    end
end
MainFrame.InputBegan:Connect(startDragging)
UserInputService.InputChanged:Connect(updateDragging)
UserInputService.InputEnded:Connect(stopDragging)
local TitleFrame=Instance.new("Frame")
TitleFrame.BackgroundColor3=Color3.fromRGB(24,24,24)
TitleFrame.Size=UDim2.new(1,0,0,35)
TitleFrame.ZIndex=6
TitleFrame.Parent=MainFrame
local TitleLabel=Instance.new("TextLabel")
TitleLabel.Text="⚡ TRP AIMBOT & FOV V2 ⚡"
TitleLabel.TextColor3=Color3.fromRGB(255,255,255)
TitleLabel.Size=UDim2.new(1,0,1,0)
TitleLabel.BackgroundTransparency=1
TitleLabel.Font=Enum.Font.SourceSansBold
TitleLabel.TextSize=18
TitleLabel.ZIndex=7
TitleLabel.Parent=TitleFrame
local SidebarFrame=Instance.new("Frame")
SidebarFrame.BackgroundColor3=Color3.fromRGB(24,24,24)
SidebarFrame.Size=UDim2.new(0,100,1,-35)
SidebarFrame.Position=UDim2.new(0,0,0,35)
SidebarFrame.ZIndex=6
SidebarFrame.Parent=MainFrame
local buttonSpacing=0.05
local buttonHeight=50
local buttonPosY=0.05
local function createSidebarButton(text,posY,func)
    local btn=Instance.new("TextButton")
    btn.Size=UDim2.new(0,80,0,buttonHeight)
    btn.Position=UDim2.new(0.1,0,posY,0)
    btn.BackgroundColor3=Color3.fromRGB(50,50,50)
    btn.Text=text
    btn.TextColor3=Color3.fromRGB(255,255,255)
    btn.TextSize=14
    btn.TextWrapped=true
    btn.ZIndex=7
    btn.Parent=SidebarFrame
    local corner=Instance.new("UICorner")
    corner.CornerRadius=UDim.new(0,8)
    corner.Parent=btn
    btn.MouseButton1Click:Connect(function()
        func()
        print(text.." clicked")
    end)
    return btn
end
local PlayerInfoButton=createSidebarButton("Player Info",buttonPosY,function()showPlayerInfoSection()end)
buttonPosY=buttonPosY+(buttonHeight/MainFrame.Size.Y.Offset)+buttonSpacing
local AimBotButton=createSidebarButton("Aim Bot",buttonPosY,function()showAimBotSection()end)
buttonPosY=buttonPosY+(buttonHeight/MainFrame.Size.Y.Offset)+buttonSpacing
local ESPButton=createSidebarButton("ESP",buttonPosY,function()showESPSection()end)
buttonPosY=buttonPosY+(buttonHeight/MainFrame.Size.Y.Offset)+buttonSpacing
local CrosshairButton=createSidebarButton("Crosshair",buttonPosY,function()showCrosshairSection()end)
buttonPosY=buttonPosY+(buttonHeight/MainFrame.Size.Y.Offset)+buttonSpacing
local ColorPickerButton=createSidebarButton("Color Picker",buttonPosY,function()showColorPickerSection()end)
buttonPosY=buttonPosY+(buttonHeight/MainFrame.Size.Y.Offset)+buttonSpacing
local StretchFOVButton=createSidebarButton("Stretch FOV",buttonPosY,function()showStretchFOVSection()end)
local ContentFrame=Instance.new("Frame")
ContentFrame.BackgroundColor3=Color3.fromRGB(31,31,31)
ContentFrame.Size=UDim2.new(0,400,1,-35)
ContentFrame.Position=UDim2.new(0,100,0,35)
ContentFrame.ZIndex=6
ContentFrame.Parent=MainFrame
local CrosshairFrame=Instance.new("Frame")
CrosshairFrame.Size=UDim2.new(0,100,0,100)
CrosshairFrame.Position=UDim2.new(0.5,-50,0.5,-50)
CrosshairFrame.BackgroundTransparency=1
CrosshairFrame.Parent=ScreenGui
CrosshairFrame.Visible=false
CrosshairFrame.ZIndex=10
local CrosshairVertical=Instance.new("Frame")
CrosshairVertical.Size=UDim2.new(0,2,0,20)
CrosshairVertical.Position=UDim2.new(0.5,-1,0.5,-10)
CrosshairVertical.BackgroundColor3=Color3.fromRGB(255,0,0)
CrosshairVertical.Parent=CrosshairFrame
local CrosshairHorizontal=Instance.new("Frame")
CrosshairHorizontal.Size=UDim2.new(0,20,0,2)
CrosshairHorizontal.Position=UDim2.new(0.5,-10,0.5,-1)
CrosshairHorizontal.BackgroundColor3=Color3.fromRGB(255,0,0)
CrosshairHorizontal.Parent=CrosshairFrame
local function clearContentFrame()
    for _,child in pairs(ContentFrame:GetChildren())do
        child:Destroy()
    end
end
local function showPlayerInfoSection()
    clearContentFrame()
    local title=Instance.new("TextLabel")
    title.Size=UDim2.new(1,-40,0,35)
    title.Position=UDim2.new(0,10,0,0)
    title.BackgroundTransparency=1
    title.Text="Player Info"
    title.TextColor3=Color3.fromRGB(0,200,255)
    title.Font=Enum.Font.SourceSansBold
    title.TextSize=20
    title.TextXAlignment=Enum.TextXAlignment.Left
    title.ZIndex=7
    title.Parent=ContentFrame
    local avatar=Instance.new("ImageLabel")
    avatar.Size=UDim2.new(0,80,0,80)
    avatar.Position=UDim2.new(0.05,0,0.1,0)
    avatar.Image=content
    avatar.BackgroundTransparency=1
    avatar.ZIndex=7
    avatar.Parent=ContentFrame
    local nameLabel=Instance.new("TextLabel")
    nameLabel.Size=UDim2.new(1,-20,0,30)
    nameLabel.Position=UDim2.new(0,10,0.3,0)
    nameLabel.BackgroundTransparency=1
    nameLabel.Text="Username: "..Player.Name
    nameLabel.TextColor3=Color3.fromRGB(200,200,200)
    nameLabel.Font=Enum.Font.SourceSans
    nameLabel.TextSize=16
    nameLabel.TextXAlignment=Enum.TextXAlignment.Left
    nameLabel.ZIndex=7
    nameLabel.Parent=ContentFrame
    local idLabel=Instance.new("TextLabel")
    idLabel.Size=UDim2.new(1,-20,0,30)
    idLabel.Position=UDim2.new(0,10,0.4,0)
    idLabel.BackgroundTransparency=1
    idLabel.Text="UserID: "..Player.UserId
    idLabel.TextColor3=Color3.fromRGB(200,200,200)
    idLabel.Font=Enum.Font.SourceSans
    idLabel.TextSize=16
    idLabel.TextXAlignment=Enum.TextXAlignment.Left
    idLabel.ZIndex=7
    idLabel.Parent=ContentFrame
    local resLabel=Instance.new("TextLabel")
    resLabel.Size=UDim2.new(1,-20,0,30)
    resLabel.Position=UDim2.new(0,10,0.5,0)
    resLabel.BackgroundTransparency=1
    resLabel.Text="Resolution: "..screenSize.X.." x "..screenSize.Y
    resLabel.TextColor3=Color3.fromRGB(200,200,200)
    resLabel.Font=Enum.Font.SourceSans
    resLabel.TextSize=16
    resLabel.TextXAlignment=Enum.TextXAlignment.Left
    resLabel.ZIndex=7
    resLabel.Parent=ContentFrame
end
local AimbotToggle,AimbotLabel,RegenButton,FOVValue,IncreaseFOVBtn,DecreaseFOVBtn,CurrentStrength,StrengthDesc,StrengthLevel,EnemiesOnlyToggle,EnemiesOnlyLabel
local function showAimBotSection()
    clearContentFrame()
    AimbotToggle=Instance.new("TextButton")
    AimbotToggle.Position=UDim2.new(0.05,0,0.05,0)
    AimbotToggle.Size=UDim2.new(0,35,0,35)
    AimbotToggle.Text=""
    AimbotToggle.BackgroundColor3=isAimbotActive and Color3.fromRGB(0,200,0)or Color3.fromRGB(170,0,0)
    AimbotToggle.AutoButtonColor=false
    AimbotToggle.ZIndex=7
    local UICorner=Instance.new("UICorner")
    UICorner.CornerRadius=UDim.new(0.5,0)
    UICorner.Parent=AimbotToggle
    AimbotToggle.Parent=ContentFrame
    AimbotLabel=Instance.new("TextLabel")
    AimbotLabel.Position=UDim2.new(0.2,0,0.05,0)
    AimbotLabel.Size=UDim2.new(0,150,0,35)
    AimbotLabel.Text="Aimbot: "..(isAimbotActive and"ON"or"OFF")
    AimbotLabel.TextColor3=Color3.fromRGB(255,255,255)
    AimbotLabel.BackgroundTransparency=1
    AimbotLabel.TextXAlignment=Enum.TextXAlignment.Left
    AimbotLabel.Font=Enum.Font.SourceSansSemibold
    AimbotLabel.TextSize=16
    AimbotLabel.ZIndex=7
    AimbotLabel.Parent=ContentFrame
    EnemiesOnlyToggle=Instance.new("TextButton")
    EnemiesOnlyToggle.Position=UDim2.new(0.05,0,0.15,0)
    EnemiesOnlyToggle.Size=UDim2.new(0,35,0,35)
    EnemiesOnlyToggle.Text=""
    EnemiesOnlyToggle.BackgroundColor3=isEnemiesOnlyAimbot and Color3.fromRGB(0,200,0)or Color3.fromRGB(170,0,0)
    EnemiesOnlyToggle.AutoButtonColor=false
    EnemiesOnlyToggle.ZIndex=7
    local UICornerEnemies=Instance.new("UICorner")
    UICornerEnemies.CornerRadius=UDim.new(0.5,0)
    UICornerEnemies.Parent=EnemiesOnlyToggle
    EnemiesOnlyToggle.Parent=ContentFrame
    EnemiesOnlyLabel=Instance.new("TextLabel")
    EnemiesOnlyLabel.Position=UDim2.new(0.2,0,0.15,0)
    EnemiesOnlyLabel.Size=UDim2.new(0,150,0,35)
    EnemiesOnlyLabel.Text="الأعداء فقط: "..(isEnemiesOnlyAimbot and"ON"or"OFF")
    EnemiesOnlyLabel.TextColor3=Color3.fromRGB(255,255,255)
    EnemiesOnlyLabel.BackgroundTransparency=1
    EnemiesOnlyLabel.TextXAlignment=Enum.TextXAlignment.Left
    EnemiesOnlyLabel.Font=Enum.Font.SourceSansSemibold
    EnemiesOnlyLabel.TextSize=16
    EnemiesOnlyLabel.ZIndex=7
    EnemiesOnlyLabel.Parent=ContentFrame
    RegenButton=Instance.new("TextButton")
    RegenButton.Position=UDim2.new(0.05,0,0.25,0)
    RegenButton.Size=UDim2.new(0,35,0,35)
    RegenButton.Text="↻"
    RegenButton.BackgroundColor3=Color3.fromRGB(0,150,150)
    RegenButton.TextColor3=Color3.fromRGB(255,255,255)
    RegenButton.TextSize=20
    RegenButton.ZIndex=7
    local UICornerRegen=Instance.new("UICorner")
    UICornerRegen.CornerRadius=UDim.new(0.5,0)
    UICornerRegen.Parent=RegenButton
    RegenButton.Parent=ContentFrame
    local RegenLabel=Instance.new("TextLabel")
    RegenLabel.Position=UDim2.new(0.2,0,0.25,0)
    RegenLabel.Size=UDim2.new(0,150,0,35)
    RegenLabel.Text="إعادة إنشاء الدائرة"
    RegenLabel.TextColor3=Color3.fromRGB(255,255,255)
    RegenLabel.BackgroundTransparency=1
    RegenLabel.TextXAlignment=Enum.TextXAlignment.Left
    RegenLabel.Font=Enum.Font.SourceSansSemibold
    RegenLabel.TextSize=16
    RegenLabel.ZIndex=7
    RegenLabel.Parent=ContentFrame
    local FOVControlFrame=Instance.new("Frame")
    FOVControlFrame.BackgroundTransparency=1
    FOVControlFrame.Size=UDim2.new(0.9,0,0,50)
    FOVControlFrame.Position=UDim2.new(0.05,0,0.35,0)
    FOVControlFrame.ZIndex=7
    FOVControlFrame.Parent=ContentFrame
    local FOVTitle=Instance.new("TextLabel")
    FOVTitle.Text="حجم دائرة Aim Bot:"
    FOVTitle.TextColor3=Color3.fromRGB(200,200,200)
    FOVTitle.Size=UDim2.new(1,0,0,25)
    FOVTitle.BackgroundTransparency=1
    FOVTitle.TextXAlignment=Enum.TextXAlignment.Left
    FOVTitle.Font=Enum.Font.SourceSansSemibold
    FOVTitle.TextSize=16
    FOVTitle.ZIndex=7
    FOVTitle.Parent=FOVControlFrame
    FOVValue=Instance.new("TextLabel")
    FOVValue.Text="FOV: "..FOVRadius
    FOVValue.TextColor3=Color3.fromRGB(255,255,255)
    FOVValue.Size=UDim2.new(0,100,0,25)
    FOVValue.Position=UDim2.new(0.35,0,0.5,0)
    FOVValue.BackgroundTransparency=1
    FOVValue.Font=Enum.Font.SourceSansSemibold
    FOVValue.TextSize=16
    FOVValue.ZIndex=7
    FOVValue.Parent=FOVControlFrame
    IncreaseFOVBtn=Instance.new("TextButton")
    IncreaseFOVBtn.Text="+"
    IncreaseFOVBtn.Size=UDim2.new(0,40,0,25)
    IncreaseFOVBtn.Position=UDim2.new(0.7,0,0.5,0)
    IncreaseFOVBtn.BackgroundColor3=Color3.fromRGB(60,60,60)
    IncreaseFOVBtn.TextColor3=Color3.fromRGB(255,255,255)
    IncreaseFOVBtn.Font=Enum.Font.SourceSansBold
    IncreaseFOVBtn.TextSize=20
    IncreaseFOVBtn.ZIndex=7
    IncreaseFOVBtn.Parent=FOVControlFrame
    DecreaseFOVBtn=Instance.new("TextButton")
    DecreaseFOVBtn.Text="-"
    DecreaseFOVBtn.Size=UDim2.new(0,40,0,25)
    DecreaseFOVBtn.Position=UDim2.new(0,0,0.5,0)
    DecreaseFOVBtn.BackgroundColor3=Color3.fromRGB(60,60,60)
    DecreaseFOVBtn.TextColor3=Color3.fromRGB(255,255,255)
    DecreaseFOVBtn.Font=Enum.Font.SourceSansBold
    DecreaseFOVBtn.TextSize=20
    DecreaseFOVBtn.ZIndex=7
    DecreaseFOVBtn.Parent=FOVControlFrame
    local StrengthFrame=Instance.new("Frame")
    StrengthFrame.BackgroundTransparency=1
    StrengthFrame.Size=UDim2.new(0.9,0,0,150)
    StrengthFrame.Position=UDim2.new(0.05,0,0.45,0)
    StrengthFrame.ZIndex=7
    StrengthFrame.Parent=ContentFrame
    local StrengthTitle=Instance.new("TextLabel")
    StrengthTitle.Text="مستوى القوة:"
    StrengthTitle.TextColor3=Color3.fromRGB(200,200,200)
    StrengthTitle.Size=UDim2.new(1,0,0,25)
    StrengthTitle.BackgroundTransparency=1
    StrengthTitle.TextXAlignment=Enum.TextXAlignment.Left
    StrengthTitle.Font=Enum.Font.SourceSansSemibold
    StrengthTitle.TextSize=16
    StrengthTitle.ZIndex=7
    StrengthTitle.Parent=StrengthFrame
    CurrentStrength=Instance.new("TextLabel")
    CurrentStrength.Text=strengthPresets[currentStrength].name
    CurrentStrength.TextColor3=Color3.fromRGB(0,255,255)
    CurrentStrength.Size=UDim2.new(1,0,0,30)
    CurrentStrength.Position=UDim2.new(0,0,0.2,0)
    CurrentStrength.BackgroundTransparency=1
    CurrentStrength.TextXAlignment=Enum.TextXAlignment.Left
    CurrentStrength.Font=Enum.Font.SourceSansBold
    CurrentStrength.TextSize=18
    CurrentStrength.ZIndex=7
    CurrentStrength.Parent=StrengthFrame
    StrengthDesc=Instance.new("TextLabel")
    StrengthDesc.Text=strengthPresets[currentStrength].desc
    StrengthDesc.TextColor3=Color3.fromRGB(200,200,0)
    StrengthDesc.Size=UDim2.new(1,0,0,50)
    StrengthDesc.Position=UDim2.new(0,0,0.4,0)
    StrengthDesc.BackgroundTransparency=1
    StrengthDesc.TextXAlignment=Enum.TextXAlignment.Left
    StrengthDesc.TextWrapped=true
    StrengthDesc.Font=Enum.Font.SourceSans
    StrengthDesc.TextSize=14
    StrengthDesc.ZIndex=7
    StrengthDesc.Parent=StrengthFrame
    local ControlsFrame=Instance.new("Frame")
    ControlsFrame.BackgroundTransparency=1
    ControlsFrame.Size=UDim2.new(1,0,0,40)
    ControlsFrame.Position=UDim2.new(0,0,0.8,0)
    ControlsFrame.ZIndex=7
    ControlsFrame.Parent=StrengthFrame
    local DecreaseBtn=Instance.new("TextButton")
    DecreaseBtn.Text="-"
    DecreaseBtn.Size=UDim2.new(0,40,0,40)
    DecreaseBtn.Position=UDim2.new(0,0,0,0)
    DecreaseBtn.BackgroundColor3=Color3.fromRGB(60,60,60)
    DecreaseBtn.TextColor3=Color3.fromRGB(255,255,255)
    DecreaseBtn.Font=Enum.Font.SourceSansBold
    DecreaseBtn.TextSize=20
    DecreaseBtn.ZIndex=7
    DecreaseBtn.Parent=ControlsFrame
    StrengthLevel=Instance.new("TextLabel")
    StrengthLevel.Text="المستوى: "..currentStrength
    StrengthLevel.TextColor3=Color3.fromRGB(255,255,255)
    StrengthLevel.Size=UDim2.new(0,100,0,40)
    StrengthLevel.Position=UDim2.new(0.35,0,0,0)
    StrengthLevel.BackgroundTransparency=1
    StrengthLevel.Font=Enum.Font.SourceSansSemibold
    StrengthLevel.TextSize=16
    StrengthLevel.ZIndex=7
    StrengthLevel.Parent=ControlsFrame
    local IncreaseBtn=Instance.new("TextButton")
    IncreaseBtn.Text="+"
    IncreaseBtn.Size=UDim2.new(0,40,0,40)
    IncreaseBtn.Position=UDim2.new(0.7,0,0,0)
    IncreaseBtn.BackgroundColor3=Color3.fromRGB(60,60,60)
    IncreaseBtn.TextColor3=Color3.fromRGB(255,255,255)
    IncreaseBtn.Font=Enum.Font.SourceSansBold
    IncreaseBtn.TextSize=20
    IncreaseBtn.ZIndex=7
    IncreaseBtn.Parent=ControlsFrame
    AimbotToggle.MouseButton1Click:Connect(function()
        isAimbotActive=not isAimbotActive
        AimbotToggle.BackgroundColor3=isAimbotActive and Color3.fromRGB(0,200,0)or Color3.fromRGB(170,0,0)
        AimbotLabel.Text="Aimbot: "..(isAimbotActive and"ON"or"OFF")
        if FOVCircle then
            FOVCircle.Visible=isAimbotActive
        end
        print("Aimbot toggled")
    end)
    EnemiesOnlyToggle.MouseButton1Click:Connect(function()
        isEnemiesOnlyAimbot=not isEnemiesOnlyAimbot
        EnemiesOnlyToggle.BackgroundColor3=isEnemiesOnlyAimbot and Color3.fromRGB(0,200,0)or Color3.fromRGB(170,0,0)
        EnemiesOnlyLabel.Text="الأعداء فقط: "..(isEnemiesOnlyAimbot and"ON"or"OFF")
        print("Enemies Only Aimbot toggled")
    end)
    RegenButton.MouseButton1Click:Connect(function()
        createFOVCircle()
        if FOVCircle then
            FOVCircle.Visible=isAimbotActive
        end
        print("FOV Circle regenerated")
    end)
    IncreaseBtn.MouseButton1Click:Connect(function()
        currentStrength=math.min(#strengthPresets,currentStrength+1)
        CurrentStrength.Text=strengthPresets[currentStrength].name
        CurrentStrength.TextColor3=updateStrengthDisplay()
        StrengthDesc.Text=strengthPresets[currentStrength].desc
        StrengthLevel.Text="المستوى: "..currentStrength
        print("Strength increased")
    end)
    DecreaseBtn.MouseButton1Click:Connect(function()
        currentStrength=math.max(1,currentStrength-1)
        CurrentStrength.Text=strengthPresets[currentStrength].name
        CurrentStrength.TextColor3=updateStrengthDisplay()
        StrengthDesc.Text=strengthPresets[currentStrength].desc
        StrengthLevel.Text="المستوى: "..currentStrength
        print("Strength decreased")
    end)
    IncreaseFOVBtn.MouseButton1Click:Connect(function()
        FOVRadius=math.min(FOVRadius+10,500)
        FOVValue.Text="FOV: "..FOVRadius
        if FOVCircle then
            FOVCircle.Radius=FOVRadius
        end
        print("FOV increased")
    end)
    DecreaseFOVBtn.MouseButton1Click:Connect(function()
        FOVRadius=math.max(FOVRadius-10,50)
        FOVValue.Text="FOV: "..FOVRadius
        if FOVCircle then
            FOVCircle.Radius=FOVRadius
        end
        print("FOV decreased")
    end)
end
local ESPToggle,ESPLabel,EnemiesOnlyESPToggle,EnemiesOnlyESPLabel
local espHighlights={}
local function isEnemy(player)
    if not player or player==Player then
        return false
    end
    if player.Team and Player.Team then
        return player.Team~=Player.Team
    end
    return true
end
local function createESPHighlight(player)
    if player==Player or not player.Character then
        return
    end
    if isEnemiesOnlyESP and not isEnemy(player)then
        return
    end
    local char=player.Character
    local highlight=Instance.new("Highlight")
    highlight.Name="ESP_Highlight"
    highlight.Adornee=char
    highlight.FillTransparency=0.5
    highlight.OutlineTransparency=0
    highlight.OutlineColor=Color3.fromRGB(255,0,0)
    highlight.FillColor=Color3.fromRGB(255,0,0)
    highlight.Parent=char
    espHighlights[player]=highlight
    task.spawn(function()
        local t=0
        while highlight and highlight.Parent and isESPActive do
            if isEnemiesOnlyESP and not isEnemy(player)then
                highlight:Destroy()
                espHighlights[player]=nil
                break
            end
            t=t+RunService.Heartbeat:Wait()
            local r=math.sin(t*2)*0.5+0.5
            local g=math.sin(t*2+2)*0.5+0.5
            local b=math.sin(t*2+4)*0.5+0.5
            highlight.OutlineColor=Color3.new(r,g,b)
            highlight.FillColor=Color3.new(r,g,b)
            wait(0.1)
        end
    end)
end
local function startESP()
    isESPActive=true
    for _,player in pairs(Players:GetPlayers())do
        if player~=Player then
            if player.Character then
                createESPHighlight(player)
            end
            player.CharacterAdded:Connect(function()
                wait(1)
                if isESPActive then
                    createESPHighlight(player)
                end
            end)
        end
    end
end
local function stopESP()
    isESPActive=false
    for _,highlight in pairs(espHighlights)do
        if highlight and highlight.Parent then
            highlight:Destroy()
        end
    end
    espHighlights={}
end
local function showESPSection()
    clearContentFrame()
    ESPToggle=Instance.new("TextButton")
    ESPToggle.Position=UDim2.new(0.05,0,0.05,0)
    ESPToggle.Size=UDim2.new(0,35,0,35)
    ESPToggle.Text=""
    ESPToggle.BackgroundColor3=isESPActive and Color3.fromRGB(0,200,0)or Color3.fromRGB(0,100,200)
    ESPToggle.AutoButtonColor=false
    ESPToggle.ZIndex=7
    local UICorner=Instance.new("UICorner")
    UICorner.CornerRadius=UDim.new(0.5,0)
    UICorner.Parent=ESPToggle
    ESPToggle.Parent=ContentFrame
    ESPLabel=Instance.new("TextLabel")
    ESPLabel.Position=UDim2.new(0.2,0,0.05,0)
    ESPLabel.Size=UDim2.new(0,150,0,35)
    ESPLabel.Text="ESP: "..(isESPActive and"ON"or"OFF")
    ESPLabel.TextColor3=Color3.fromRGB(255,255,255)
    ESPLabel.BackgroundTransparency=1
    ESPLabel.TextXAlignment=Enum.TextXAlignment.Left
    ESPLabel.Font=Enum.Font.SourceSansSemibold
    ESPLabel.TextSize=16
    ESPLabel.ZIndex=7
    ESPLabel.Parent=ContentFrame
    EnemiesOnlyESPToggle=Instance.new("TextButton")
    EnemiesOnlyESPToggle.Position=UDim2.new(0.05,0,0.15,0)
    EnemiesOnlyESPToggle.Size=UDim2.new(0,35,0,35)
    EnemiesOnlyESPToggle.Text=""
    EnemiesOnlyESPToggle.BackgroundColor3=isEnemiesOnlyESP and Color3.fromRGB(0,200,0)or Color3.fromRGB(170,0,0)
    EnemiesOnlyESPToggle.AutoButtonColor=false
    EnemiesOnlyESPToggle.ZIndex=7
    local UICornerEnemiesESP=Instance.new("UICorner")
    UICornerEnemiesESP.CornerRadius=UDim.new(0.5,0)
    UICornerEnemiesESP.Parent=EnemiesOnlyESPToggle
    EnemiesOnlyESPToggle.Parent=ContentFrame
    EnemiesOnlyESPLabel=Instance.new("TextLabel")
    EnemiesOnlyESPLabel.Position=UDim2.new(0.2,0,0.15,0)
    EnemiesOnlyESPLabel.Size=UDim2.new(0,150,0,35)
    EnemiesOnlyESPLabel.Text="كشف الأعداء: "..(isEnemiesOnlyESP and"ON"or"OFF")
    EnemiesOnlyESPLabel.TextColor3=Color3.fromRGB(255,255,255)
    EnemiesOnlyESPLabel.BackgroundTransparency=1
    EnemiesOnlyESPLabel.TextXAlignment=Enum.TextXAlignment.Left
    EnemiesOnlyESPLabel.Font=Enum.Font.SourceSansSemibold
    ESPLabel.TextSize=16
    EnemiesOnlyESPLabel.ZIndex=7
    EnemiesOnlyESPLabel.Parent=ContentFrame
    ESPToggle.MouseButton1Click:Connect(function()
        if isESPActive then
            stopESP()
            ESPToggle.BackgroundColor3=Color3.fromRGB(0,100,200)
            ESPLabel.Text="ESP: OFF"
        else
            startESP()
            ESPToggle.BackgroundColor3=Color3.fromRGB(0,200,0)
            ESPLabel.Text="ESP: ON"
        end
        print("ESP toggled")
    end)
    EnemiesOnlyESPToggle.MouseButton1Click:Connect(function()
        isEnemiesOnlyESP=not isEnemiesOnlyESP
        EnemiesOnlyESPToggle.BackgroundColor3=isEnemiesOnlyESP and Color3.fromRGB(0,200,0)or Color3.fromRGB(170,0,0)
        EnemiesOnlyESPLabel.Text="كشف الأعداء: "..(isEnemiesOnlyESP and"ON"or"OFF")
        if isESPActive then
            stopESP()
            startESP()
        end
        print("Enemies Only ESP toggled")
    end)
end
local CrosshairToggle,CrosshairLabel
local function showCrosshairSection()
    clearContentFrame()
    CrosshairToggle=Instance.new("TextButton")
    CrosshairToggle.Position=UDim2.new(0.05,0,0.05,0)
    CrosshairToggle.Size=UDim2.new(0,35,0,35)
    CrosshairToggle.Text=""
    CrosshairToggle.BackgroundColor3=CrosshairFrame.Visible and Color3.fromRGB(200,100,0)or Color3.fromRGB(100,50,0)
    CrosshairToggle.ZIndex=7
    local UICorner=Instance.new("UICorner")
    UICorner.CornerRadius=UDim.new(0.5,0)
    UICorner.Parent=CrosshairToggle
    CrosshairToggle.Parent=ContentFrame
    CrosshairLabel=Instance.new("TextLabel")
    CrosshairLabel.Position=UDim2.new(0.2,0,0.05,0)
    CrosshairLabel.Size=UDim2.new(0,150,0,35)
    CrosshairLabel.Text="Crosshair: "..(CrosshairFrame.Visible and"ON"or"OFF")
    CrosshairLabel.TextColor3=Color3.fromRGB(255,255,255)
    CrosshairLabel.BackgroundTransparency=1
    CrosshairLabel.TextXAlignment=Enum.TextXAlignment.Left
    CrosshairLabel.Font=Enum.Font.SourceSansSemibold
    CrosshairLabel.TextSize=16
    CrosshairLabel.ZIndex=7
    CrosshairLabel.Parent=ContentFrame
    CrosshairToggle.MouseButton1Click:Connect(function()
        CrosshairFrame.Visible=not CrosshairFrame.Visible
        CrosshairToggle.BackgroundColor3=CrosshairFrame.Visible and Color3.fromRGB(200,100,0)or Color3.fromRGB(100,50,0)
        CrosshairLabel.Text="Crosshair: "..(CrosshairFrame.Visible and"ON"or"OFF")
        print("Crosshair toggled")
    end)
end
local RInput,GInput,BInput
local function showColorPickerSection()
    clearContentFrame()
    local ColorPickerFrame=Instance.new("Frame")
    ColorPickerFrame.Size=UDim2.new(0.9,0,0,200)
    ColorPickerFrame.Position=UDim2.new(0.05,0,0.05,0)
    ColorPickerFrame.BackgroundColor3=Color3.fromRGB(40,40,40)
    ColorPickerFrame.ZIndex=7
    ColorPickerFrame.Parent=ContentFrame
    local RLabel=Instance.new("TextLabel")
    RLabel.Size=UDim2.new(0,50,0,30)
    RLabel.Position=UDim2.new(0.1,0,0.05,0)
    RLabel.BackgroundTransparency=1
    RLabel.Text="R:"
    RLabel.TextColor3=Color3.fromRGB(255,255,255)
    RLabel.ZIndex=7
    RLabel.Parent=ColorPickerFrame
    RInput=Instance.new("TextBox")
    RInput.Size=UDim2.new(0,100,0,30)
    RInput.Position=UDim2.new(0.3,0,0.05,0)
    RInput.BackgroundColor3=Color3.fromRGB(60,60,60)
    RInput.Text="255"
    RInput.TextColor3=Color3.fromRGB(255,255,255)
    RInput.ZIndex=7
    RInput.Parent=ColorPickerFrame
    local GLabel=Instance.new("TextLabel")
    GLabel.Size=UDim2.new(0,50,0,30)
    GLabel.Position=UDim2.new(0.1,0,0.15,0)
    GLabel.BackgroundTransparency=1
    GLabel.Text="G:"
    GLabel.TextColor3=Color3.fromRGB(255,255,255)
    GLabel.ZIndex=7
    GLabel.Parent=ColorPickerFrame
    GInput=Instance.new("TextBox")
    GInput.Size=UDim2.new(0,100,0,30)
    GInput.Position=UDim2.new(0.3,0,0.15,0)
    GInput.BackgroundColor3=Color3.fromRGB(60,60,60)
    GInput.Text="0"
    GInput.TextColor3=Color3.fromRGB(255,255,255)
    GInput.ZIndex=7
    GInput.Parent=ColorPickerFrame
    local BLabel=Instance.new("TextLabel")
    BLabel.Size=UDim2.new(0,50,0,30)
    BLabel.Position=UDim2.new(0.1,0,0.25,0)
    BLabel.BackgroundTransparency=1
    BLabel.Text="B:"
    BLabel.TextColor3=Color3.fromRGB(255,255,255)
    BLabel.ZIndex=7
    BLabel.Parent=ColorPickerFrame
    BInput=Instance.new("TextBox")
    BInput.Size=UDim2.new(0,100,0,30)
    BInput.Position=UDim2.new(0.3,0,0.25,0)
    BInput.BackgroundColor3=Color3.fromRGB(60,60,60)
    BInput.Text="0"
    BInput.TextColor3=Color3.fromRGB(255,255,255)
    BInput.ZIndex=7
    BInput.Parent=ColorPickerFrame
    local ApplyColorButton=Instance.new("TextButton")
    ApplyColorButton.Size=UDim2.new(0,100,0,30)
    ApplyColorButton.Position=UDim2.new(0.3,0,0.35,0)
    ApplyColorButton.BackgroundColor3=Color3.fromRGB(50,50,50)
    ApplyColorButton.Text="Apply"
    ApplyColorButton.TextColor3=Color3.fromRGB(255,255,255)
    ApplyColorButton.ZIndex=7
    ApplyColorButton.Parent=ColorPickerFrame
    local function createColorButton(pos,color,r,g,b)
        local btn=Instance.new("TextButton")
        btn.Size=UDim2.new(0,50,0,50)
        btn.Position=pos
        btn.BackgroundColor3=color
        btn.Text=""
        btn.ZIndex=7
        local corner=Instance.new("UICorner")
        corner.CornerRadius=UDim.new(0,8)
        corner.Parent=btn
        btn.Parent=ColorPickerFrame
        btn.MouseButton1Click:Connect(function()
            applyColor(r,g,b)
            print("Color button clicked")
        end)
    end
    createColorButton(UDim2.new(0.1,0,0.5,0),Color3.fromRGB(255,0,0),255,0,0)
    createColorButton(UDim2.new(0.3,0,0.5,0),Color3.fromRGB(0,0,255),0,0,255)
    createColorButton(UDim2.new(0.5,0,0.5,0),Color3.fromRGB(0,255,0),0,255,0)
    createColorButton(UDim2.new(0.7,0,0.5,0),Color3.fromRGB(255,255,255),255,255,255)
    function applyColor(r,g,b)
        local newColor=Color3.fromRGB(r,g,b)
        CrosshairVertical.BackgroundColor3=newColor
        CrosshairHorizontal.BackgroundColor3=newColor
        RInput.Text=tostring(r)
        GInput.Text=tostring(g)
        BInput.Text=tostring(b)
    end
    ApplyColorButton.MouseButton1Click:Connect(function()
        local r=tonumber(RInput.Text)or 255
        local g=tonumber(GInput.Text)or 0
        local b=tonumber(BInput.Text)or 0
        r=math.clamp(r,0,255)
        g=math.clamp(g,0,255)
        b=math.clamp(b,0,255)
        applyColor(r,g,b)
        print("Apply color clicked")
    end)
end
local function createFOVButton(text,yPos,fov)
    local button=Instance.new("TextButton")
    button.Size=UDim2.new(0.9,0,0,35)
    button.Position=UDim2.new(0.05,0,0,yPos)
    button.BackgroundColor3=Color3.fromRGB(50,50,50)
    button.Text=text
    button.TextColor3=Color3.new(1,1,1)
    button.Font=Enum.Font.SourceSansSemibold
    button.TextSize=16
    button.ZIndex=7
    local UICorner=Instance.new("UICorner")
    UICorner.CornerRadius=UDim.new(0,8)
    UICorner.Parent=button
    button.Parent=ContentFrame
    button.MouseButton1Click:Connect(function()
        Camera.FieldOfView=fov
        print("FOV button clicked: "..text)
    end)
end
local function showStretchFOVSection()
    clearContentFrame()
    local title=Instance.new("TextLabel")
    title.Size=UDim2.new(1,-40,0,35)
    title.Position=UDim2.new(0,10,0,0)
    title.BackgroundTransparency=1
    title.Text="Stretch FOV Menu"
    title.TextColor3=Color3.fromRGB(0,200,255)
    title.Font=Enum.Font.SourceSansBold
    title.TextSize=20
    title.TextXAlignment=Enum.TextXAlignment.Left
    title.ZIndex=7
    title.Parent=ContentFrame
    createFOVButton("Normal (70)",80,70)
    createFOVButton("Stretch (90)",125,90)
    createFOVButton("Super Stretch (110)",170,110)
    local widthBox=Instance.new("TextBox")
    widthBox.Size=UDim2.new(0,120,0,35)
    widthBox.Position=UDim2.new(0.05,0,0,220)
    widthBox.PlaceholderText="Width (مثال: 1080)"
    widthBox.Font=Enum.Font.SourceSans
    widthBox.TextSize=14
    widthBox.TextColor3=Color3.new(1,1,1)
    widthBox.BackgroundColor3=Color3.fromRGB(50,50,50)
    widthBox.ZIndex=7
    local UICornerWidth=Instance.new("UICorner")
    UICornerWidth.CornerRadius=UDim.new(0,8)
    UICornerWidth.Parent=widthBox
    widthBox.Parent=ContentFrame
    local heightBox=widthBox:Clone()
    heightBox.Position=UDim2.new(0.5,0,0,220)
    heightBox.PlaceholderText="Height (مثال: 900)"
    heightBox.Parent=ContentFrame
    local applyBtn=Instance.new("TextButton")
    applyBtn.Size=UDim2.new(0.9,0,0,35)
    applyBtn.Position=UDim2.new(0.05,0,0,270)
    applyBtn.BackgroundColor3=Color3.fromRGB(0,80,130)
    applyBtn.Text="Apply Fake Stretch"
    applyBtn.TextColor3=Color3.new(1,1,1)
    applyBtn.Font=Enum.Font.SourceSansBold
    applyBtn.TextSize=16
    applyBtn.ZIndex=7
    local UICornerApply=Instance.new("UICorner")
    UICornerApply.CornerRadius=UDim.new(0,8)
    UICornerApply.Parent=applyBtn
    applyBtn.Parent=ContentFrame
    applyBtn.MouseButton1Click:Connect(function()
        local w=tonumber(widthBox.Text)
        local h=tonumber(heightBox.Text)
        if w and h then
            local ratio=w/h
            Camera.FieldOfView=70*(1+((ratio-(screenSize.X/screenSize.Y))*0.5))
            print("Fake stretch applied")
        end
    end)
end
local function createFOVCircle()
    if FOVCircle then
        pcall(function()
            FOVCircle:Remove()
        end)
    end
    local success=pcall(function()
        FOVCircle=Drawing.new("Circle")
        FOVCircle.Visible=isAimbotActive
        FOVCircle.Radius=FOVRadius
        FOVCircle.Color=Color3.fromRGB(255,0,0)
        FOVCircle.Thickness=2
        FOVCircle.Filled=false
        FOVCircle.Position=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)
    end)
end
local function GetClosestPlayerInFOV()
    if not FOVCircle then
        return nil
    end
    local closestPlayer=nil
    local shortestDistance=FOVCircle.Radius
    local center=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)
    for _,player in ipairs(Players:GetPlayers())do
        if player~=Player and player.Character and player.Character:FindFirstChild(TargetPart)then
            if isEnemiesOnlyAimbot and not isEnemy(player)then
                continue
            end
            local targetPos=player.Character[TargetPart].Position
            local screenPos,onScreen=Camera:WorldToViewportPoint(targetPos)
            if onScreen then
                local screenPoint=Vector2.new(screenPos.X,screenPos.Y)
                local distance=(screenPoint-center).Magnitude
                if distance<shortestDistance then
                    local rayOrigin=Camera.CFrame.Position
                    local rayDirection=(targetPos-rayOrigin).Unit*1000
                    local raycastParams=RaycastParams.new()
                    raycastParams.FilterDescendantsInstances={Player.Character}
                    raycastParams.FilterType=Enum.RaycastFilterType.Blacklist
                    local raycastResult=workspace:Raycast(rayOrigin,rayDirection,raycastParams)
                    if raycastResult and raycastResult.Instance:IsDescendantOf(player.Character)then
                        closestPlayer=player
                        shortestDistance=distance
                    end
                end
            end
        end
    end
    return closestPlayer
end
local function updateStrengthDisplay()
    local strengthColors={[1]=Color3.fromRGB(100,255,100),[2]=Color3.fromRGB(100,200,255),[3]=Color3.fromRGB(255,150,50),[4]=Color3.fromRGB(255,50,50)}
    return strengthColors[currentStrength]
end
-- Toggle UI: Show/hide main interface and change button icon
ToggleButton.MouseButton1Click:Connect(function()
    isUIVisible=not isUIVisible
    MainFrame.Visible=isUIVisible
    ToggleButton.Text=isUIVisible and "≡" or "☰"
    print("Toggle UI clicked")
end)
RunService.RenderStepped:Connect(function()
    if FOVCircle then
        FOVCircle.Position=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)
        FOVCircle.Visible=isAimbotActive
        if isAimbotActive then
            local target=GetClosestPlayerInFOV()
            if target and target.Character and target.Character:FindFirstChild(TargetPart)then
                local targetPos=target.Character[TargetPart].Position
                local currentCFrame=Camera.CFrame
                local targetCFrame=CFrame.new(currentCFrame.Position,targetPos)
                Camera.CFrame=currentCFrame:Lerp(targetCFrame,strengthPresets[currentStrength].smoothness)
            end
        end
    end
end)
Player.CharacterAdded:Connect(function()
    wait(1)
    createFOVCircle()
    if isESPActive then
        startESP()
    end
end)
Player.CharacterRemoving:Connect(function()
    if FOVCircle then
        FOVCircle:Remove()
    end
    stopESP()
end)
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        wait(1)
        if isESPActive then
            createESPHighlight(player)
        end
    end)
end)
wait(1)
createFOVCircle()
showPlayerInfoSection()
