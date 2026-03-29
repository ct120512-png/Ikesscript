-- LocalScript inside StarterPlayerScripts or StarterCharacterScripts

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

player.CharacterAdded:Connect(function(c)
    character = c
    humanoid = c:WaitForChild("Humanoid")
    rootPart = c:WaitForChild("HumanoidRootPart")
end)

-- State
local flying, flyConnection = false, nil
local currentSpeed = 16
local guiOpen = true
local activeTab = "Misc"
local infJumpEnabled = false
local noclipEnabled = false
local noclipConnection

-- Aimbot
local aimbotEnabled = false
local aimbotFOV = 150
local aimbotSmoothing = 1
local aimbotTarget = "Head"
local aimbotHoldMode = true
local aimbotToggled = false
local aimbotKey = Enum.KeyCode.Q
local listeningForKey = false
local currentLockedTarget = nil
local lockIndicatorType = "Circle"

-- ESP
local espEnabled = false
local espBoxes = true
local espNames = true
local espDistance = true
local espTracers = false
local espBoxColor = Color3.fromRGB(255, 50, 50)
local espNameColor = Color3.fromRGB(255, 255, 255)
local espTracerColor = Color3.fromRGB(255, 50, 50)
local espObjects = {}

-- Settings
local guiToggleKey = Enum.KeyCode.Y
local listeningForGuiKey = false

-- Theme
local THEME = {
    bg         = Color3.fromRGB(20, 20, 20),
    panel      = Color3.fromRGB(30, 30, 30),
    accent     = Color3.fromRGB(55, 55, 55),
    highlight  = Color3.fromRGB(180, 180, 180),
    text       = Color3.new(1, 1, 1),
    subtext    = Color3.fromRGB(160, 160, 160),
    green      = Color3.fromRGB(0, 200, 80),
    red        = Color3.fromRGB(200, 40, 40),
    tabActive  = Color3.fromRGB(65, 65, 65),
    tabInactive= Color3.fromRGB(35, 35, 35),
    btn        = Color3.fromRGB(50, 50, 50),
    btnActive  = Color3.fromRGB(75, 75, 75),
    section    = Color3.fromRGB(40, 40, 40),
}

-- Notif GUI
local notifGui = Instance.new("ScreenGui")
notifGui.Name = "NotifGui"
notifGui.ResetOnSpawn = false
notifGui.Parent = player.PlayerGui

local function sendNotif(text, color)
    color = color or THEME.accent
    local notif = Instance.new("Frame")
    notif.Size = UDim2.new(0, 240, 0, 42)
    notif.Position = UDim2.new(1, 10, 1, -60)
    notif.BackgroundColor3 = THEME.panel
    notif.BorderSizePixel = 0
    notif.Parent = notifGui
    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Thickness = 2
    stroke.Parent = notif
    Instance.new("UICorner", notif).CornerRadius = UDim.new(0, 8)
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 8, 0, 8)
    dot.Position = UDim2.new(0, 10, 0.5, -4)
    dot.BackgroundColor3 = color
    dot.BorderSizePixel = 0
    dot.Parent = notif
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
    local nl = Instance.new("TextLabel")
    nl.Size = UDim2.new(1, -30, 1, 0)
    nl.Position = UDim2.new(0, 26, 0, 0)
    nl.BackgroundTransparency = 1
    nl.TextColor3 = THEME.text
    nl.Text = text
    nl.Font = Enum.Font.GothamBold
    nl.TextSize = 13
    nl.TextXAlignment = Enum.TextXAlignment.Left
    nl.Parent = notif
    TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(1, -255, 1, -60)}):Play()
    task.delay(2.5, function()
        local t = TweenService:Create(notif, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Position = UDim2.new(1, 10, 1, -60)})
        t:Play()
        t.Completed:Connect(function() notif:Destroy() end)
    end)
end

-- Lock indicator GUI
local lockGui = Instance.new("ScreenGui")
lockGui.Name = "LockGui"
lockGui.ResetOnSpawn = false
lockGui.Parent = player.PlayerGui

local lockCircle = Instance.new("Frame")
lockCircle.Size = UDim2.new(0, 30, 0, 30)
lockCircle.BackgroundTransparency = 1
lockCircle.BorderSizePixel = 3
lockCircle.BorderColor3 = Color3.fromRGB(255, 50, 50)
lockCircle.Visible = false
lockCircle.Parent = lockGui
Instance.new("UICorner", lockCircle).CornerRadius = UDim.new(1, 0)

local lockCrossH = Instance.new("Frame")
lockCrossH.Size = UDim2.new(0, 24, 0, 3)
lockCrossH.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
lockCrossH.BorderSizePixel = 0
lockCrossH.Visible = false
lockCrossH.Parent = lockGui

local lockCrossV = Instance.new("Frame")
lockCrossV.Size = UDim2.new(0, 3, 0, 24)
lockCrossV.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
lockCrossV.BorderSizePixel = 0
lockCrossV.Visible = false
lockCrossV.Parent = lockGui

local function showLockIndicator(screenX, screenY)
    if lockIndicatorType == "Circle" then
        lockCircle.Visible = true
        lockCrossH.Visible = false
        lockCrossV.Visible = false
        lockCircle.Position = UDim2.new(0, screenX - 15, 0, screenY - 15)
    else
        lockCircle.Visible = false
        lockCrossH.Visible = true
        lockCrossV.Visible = true
        lockCrossH.Position = UDim2.new(0, screenX - 12, 0, screenY - 1)
        lockCrossV.Position = UDim2.new(0, screenX - 1, 0, screenY - 12)
    end
end

local function hideLockIndicator()
    lockCircle.Visible = false
    lockCrossH.Visible = false
    lockCrossV.Visible = false
end

-- Main GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "IkesScript"
screenGui.ResetOnSpawn = false
screenGui.Parent = player.PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 420, 0, 500)
frame.Position = UDim2.new(0.5, -210, 0.5, -250)
frame.BackgroundColor3 = THEME.bg
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.ClipsDescendants = true
frame.Parent = screenGui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = THEME.accent
mainStroke.Thickness = 1.5
mainStroke.Parent = frame

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 42)
titleBar.BackgroundColor3 = THEME.panel
titleBar.BorderSizePixel = 0
titleBar.Parent = frame
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 12)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -10, 1, 0)
titleLabel.Position = UDim2.new(0, 14, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3 = THEME.text
titleLabel.Text = "Ike's Script"
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 16
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, 0, 0, 36)
tabBar.Position = UDim2.new(0, 0, 0, 42)
tabBar.BackgroundColor3 = THEME.panel
tabBar.BorderSizePixel = 0
tabBar.Parent = frame

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Parent = tabBar

local divider = Instance.new("Frame")
divider.Size = UDim2.new(1, 0, 0, 1)
divider.Position = UDim2.new(0, 0, 0, 78)
divider.BackgroundColor3 = THEME.accent
divider.BorderSizePixel = 0
divider.Parent = frame

local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, 0, 1, -79)
contentFrame.Position = UDim2.new(0, 0, 0, 79)
contentFrame.BackgroundTransparency = 1
contentFrame.ClipsDescendants = true
contentFrame.Parent = frame

local tabPages = {}
local tabButtons = {}

local function makeTabPage(name)
    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = THEME.accent
    page.CanvasSize = UDim2.new(0, 0, 0, 620)
    page.Visible = false
    page.Parent = contentFrame
    tabPages[name] = page
    return page
end

local function switchTab(name)
    for n, page in pairs(tabPages) do page.Visible = (n == name) end
    for n, btn in pairs(tabButtons) do
        btn.BackgroundColor3 = n == name and THEME.tabActive or THEME.tabInactive
        btn.TextColor3 = n == name and THEME.text or THEME.subtext
    end
    activeTab = name
end

local function makeTab(name, order)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 84, 1, 0)
    btn.BackgroundColor3 = THEME.tabInactive
    btn.TextColor3 = THEME.subtext
    btn.Text = name
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.BorderSizePixel = 0
    btn.LayoutOrder = order
    btn.Parent = tabBar
    tabButtons[name] = btn
    btn.MouseButton1Click:Connect(function() switchTab(name) end)
    return btn
end

local function makeSection(page, text, yPos)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -24, 0, 26)
    f.Position = UDim2.new(0, 12, 0, yPos)
    f.BackgroundColor3 = THEME.section
    f.BorderSizePixel = 0
    f.Parent = page
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
    local fl = Instance.new("TextLabel")
    fl.Size = UDim2.new(1, -10, 1, 0)
    fl.Position = UDim2.new(0, 10, 0, 0)
    fl.BackgroundTransparency = 1
    fl.TextColor3 = THEME.subtext
    fl.Text = text
    fl.Font = Enum.Font.GothamBold
    fl.TextSize = 12
    fl.TextXAlignment = Enum.TextXAlignment.Left
    fl.Parent = f
    return f
end

local function makeBtn(page, text, yPos, active)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -24, 0, 36)
    btn.Position = UDim2.new(0, 12, 0, yPos)
    btn.BackgroundColor3 = active and THEME.btnActive or THEME.btn
    btn.TextColor3 = THEME.text
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.BorderSizePixel = 0
    btn.Parent = page
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
    return btn
end

local function makeLabel(page, text, yPos)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -24, 0, 20)
    lbl.Position = UDim2.new(0, 12, 0, yPos)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = THEME.subtext
    lbl.Text = text
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = page
    return lbl
end

local function makeSlider(page, yPos, minVal, maxVal, defaultVal, onChanged)
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, -24, 0, 14)
    bg.Position = UDim2.new(0, 12, 0, yPos)
    bg.BackgroundColor3 = THEME.accent
    bg.BorderSizePixel = 0
    bg.Parent = page
    Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)
    local ratio0 = (defaultVal - minVal) / (maxVal - minVal)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(ratio0, 0, 1, 0)
    fill.BackgroundColor3 = THEME.highlight
    fill.BorderSizePixel = 0
    fill.Parent = bg
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    local handle = Instance.new("TextButton")
    handle.Size = UDim2.new(0, 18, 0, 18)
    handle.Position = UDim2.new(ratio0, -9, 0.5, -9)
    handle.BackgroundColor3 = THEME.text
    handle.Text = ""
    handle.BorderSizePixel = 0
    handle.Parent = bg
    Instance.new("UICorner", handle).CornerRadius = UDim.new(1, 0)
    local dragging = false
    handle.MouseButton1Down:Connect(function() dragging = true end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local r = math.clamp((i.Position.X - bg.AbsolutePosition.X) / bg.AbsoluteSize.X, 0, 1)
            local val = math.floor(minVal + r * (maxVal - minVal))
            fill.Size = UDim2.new(r, 0, 1, 0)
            handle.Position = UDim2.new(r, -9, 0.5, -9)
            onChanged(val, r)
        end
    end)
    return bg
end

local function makeToggleBtn(page, text, yPos, default, onToggle)
    local btn = makeBtn(page, (default and "[ON]  " or "[OFF] ") .. text, yPos, default)
    local state = default
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.Text = (state and "[ON]  " or "[OFF] ") .. text
        btn.BackgroundColor3 = state and THEME.btnActive or THEME.btn
        onToggle(state)
    end)
    return btn
end

local function makeColorPicker(page, text, yPos, onChanged)
    makeLabel(page, text, yPos)
    local colors = {
        {Color3.fromRGB(255,50,50),   "Red"},
        {Color3.fromRGB(50,200,255),  "Cyan"},
        {Color3.fromRGB(50,255,80),   "Green"},
        {Color3.fromRGB(255,255,50),  "Yellow"},
        {Color3.fromRGB(255,255,255), "White"},
        {Color3.fromRGB(255,105,180), "Pink"},
        {Color3.fromRGB(180,100,255), "Purple"},
    }
    local sf = Instance.new("Frame")
    sf.Size = UDim2.new(1, -24, 0, 28)
    sf.Position = UDim2.new(0, 12, 0, yPos + 22)
    sf.BackgroundTransparency = 1
    sf.Parent = page
    local sl = Instance.new("UIListLayout")
    sl.FillDirection = Enum.FillDirection.Horizontal
    sl.Padding = UDim.new(0, 5)
    sl.Parent = sf
    for _, c in ipairs(colors) do
        local sw = Instance.new("TextButton")
        sw.Size = UDim2.new(0, 28, 0, 28)
        sw.BackgroundColor3 = c[1]
        sw.Text = ""
        sw.BorderSizePixel = 0
        sw.Parent = sf
        Instance.new("UICorner", sw).CornerRadius = UDim.new(1, 0)
        sw.MouseButton1Click:Connect(function()
            onChanged(c[1])
            sendNotif(text .. ": " .. c[2])
        end)
    end
end

-- Tabs
makeTab("Misc",     1)
makeTab("Fly",      2)
makeTab("Aimbot",   3)
makeTab("ESP",      4)
makeTab("Settings", 5)

-- ══════════════════
-- MISC TAB
-- ══════════════════
local miscPage = makeTabPage("Misc")
makeSection(miscPage, "Movement", 10)

local speedLbl = makeLabel(miscPage, "WalkSpeed: 16", 44)
makeSlider(miscPage, 66, 1, 300, 16, function(val)
    currentSpeed = val
    humanoid.WalkSpeed = val
    speedLbl.Text = "WalkSpeed: " .. val
end)

local jumpLbl = makeLabel(miscPage, "JumpPower: 50", 90)
makeSlider(miscPage, 112, 1, 500, 50, function(val)
    humanoid.JumpPower = val
    jumpLbl.Text = "JumpPower: " .. val
end)

makeToggleBtn(miscPage, "Infinite Jump", 136, false, function(v)
    infJumpEnabled = v
    sendNotif(v and "Inf Jump ON" or "Inf Jump OFF")
end)

makeToggleBtn(miscPage, "Noclip", 178, false, function(v)
    noclipEnabled = v
    sendNotif(v and "Noclip ON" or "Noclip OFF")
    if v then
        noclipConnection = RunService.Stepped:Connect(function()
            if noclipEnabled and character then
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    else
        if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
        end
        if character then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
end)

UserInputService.JumpRequest:Connect(function()
    if infJumpEnabled and character and humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

makeSection(miscPage, "Other", 226)

local resetBtn = makeBtn(miscPage, "Reset Speed and Jump", 258)
resetBtn.MouseButton1Click:Connect(function()
    humanoid.WalkSpeed = 16
    humanoid.JumpPower = 50
    speedLbl.Text = "WalkSpeed: 16"
    jumpLbl.Text = "JumpPower: 50"
    sendNotif("Stats reset")
end)

local unloadBtn = makeBtn(miscPage, "Unload Script", 302)
unloadBtn.BackgroundColor3 = THEME.red
unloadBtn.MouseButton1Click:Connect(function()
    if flying then
        flying = false
        humanoid.PlatformStand = false
        if flyConnection then flyConnection:Disconnect() end
        local bp = rootPart:FindFirstChild("FlyBodyPosition")
        local bg2 = rootPart:FindFirstChild("FlyBodyGyro")
        if bp then bp:Destroy() end
        if bg2 then bg2:Destroy() end
    end
    if noclipConnection then noclipConnection:Disconnect() end
    if character then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = true end
        end
    end
    humanoid.WalkSpeed = 16
    humanoid.JumpPower = 50
    hideLockIndicator()
    for _, objs in pairs(espObjects) do
        for _, obj in pairs(objs) do
            if obj and obj.Parent then obj:Destroy() end
        end
    end
    espObjects = {}
    screenGui:Destroy()
    notifGui:Destroy()
    lockGui:Destroy()
end)

-- ══════════════════
-- FLY TAB
-- ══════════════════
-- ══════════════════
-- FLY TAB
-- ══════════════════
local flyPage = makeTabPage("Fly")
makeSection(flyPage, "Fly", 10)

local flyBtn = makeBtn(flyPage, "Fly: OFF", 44)
local flySpeedVal = 1.2
local flySpeedLbl = makeLabel(flyPage, "Fly Speed: 1.2", 90)
makeSlider(flyPage, 112, 1, 30, 3, function(val)
    flySpeedVal = val / 10
    flySpeedLbl.Text = "Fly Speed: " .. string.format("%.1f", flySpeedVal)
end)

local flyVelocity = nil
local flyGyro = nil

local function stopFly()
    flying = false
    flyBtn.Text = "Fly: OFF"
    flyBtn.BackgroundColor3 = THEME.btn
    humanoid.PlatformStand = false
    if flyConnection then flyConnection:Disconnect() flyConnection = nil end

    -- Clean up both old and new fly instances
    for _, name in ipairs({"FlyBodyPosition", "FlyBodyGyro", "FlyVelocity", "FlyGyro", "FlyAttachment"}) do
        local obj = rootPart:FindFirstChild(name)
        if obj then obj:Destroy() end
    end
    flyVelocity = nil
    flyGyro = nil
    sendNotif("Fly OFF")
end

local function startFly()
    flying = true
    flyBtn.Text = "Fly: ON"
    flyBtn.BackgroundColor3 = THEME.btnActive
    humanoid.PlatformStand = true

    -- Try new API first (works in all games)
    local success = pcall(function()
        local attachment = Instance.new("Attachment")
        attachment.Name = "FlyAttachment"
        attachment.Parent = rootPart

        local lv = Instance.new("LinearVelocity")
        lv.Name = "FlyVelocity"
        lv.Attachment0 = attachment
        lv.MaxForce = math.huge
        lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
        lv.VectorVelocity = Vector3.zero
        lv.Parent = rootPart
        flyVelocity = lv

        local ao = Instance.new("AlignOrientation")
        ao.Name = "FlyGyro"
        ao.Attachment0 = attachment
        ao.MaxTorque = math.huge
        ao.MaxAngularVelocity = math.huge
        ao.Responsiveness = 200
        ao.CFrame = rootPart.CFrame
        ao.Parent = rootPart
        flyGyro = ao
    end)

    -- Fallback to old API if new one fails
    if not success or not flyVelocity then
        pcall(function()
            local bp = Instance.new("BodyPosition")
            bp.Name = "FlyBodyPosition"
            bp.MaxForce = Vector3.new(1e5, 1e5, 1e5)
            bp.Position = rootPart.Position
            bp.Parent = rootPart

            local bg = Instance.new("BodyGyro")
            bg.Name = "FlyBodyGyro"
            bg.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
            bg.CFrame = rootPart.CFrame
            bg.Parent = rootPart
        end)
    end

    flyConnection = RunService.Heartbeat:Connect(function()
        if not flying then return end
        local cam = workspace.CurrentCamera
        local dir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.new(0,1,0) end

        local speed = flySpeedVal * 60

        if flyVelocity then
            -- New API
            flyVelocity.VectorVelocity = dir * speed
            if flyGyro then
                flyGyro.CFrame = cam.CFrame
            end
        else
            -- Old API fallback
            local bp = rootPart:FindFirstChild("FlyBodyPosition")
            local bg = rootPart:FindFirstChild("FlyBodyGyro")
            if bp then bp.Position += dir * flySpeedVal end
            if bg then bg.CFrame = cam.CFrame end
        end
    end)
    sendNotif("Fly ON")
end

flyBtn.MouseButton1Click:Connect(function()
    if flying then stopFly() else startFly() end
end)
-- ══════════════════
-- AIMBOT TAB
-- ══════════════════
local aimPage = makeTabPage("Aimbot")
makeSection(aimPage, "Aimbot", 10)

local aimStatusLbl = Instance.new("TextLabel")
aimStatusLbl.Size = UDim2.new(1, -24, 0, 30)
aimStatusLbl.Position = UDim2.new(0, 12, 0, 44)
aimStatusLbl.BackgroundColor3 = THEME.red
aimStatusLbl.TextColor3 = THEME.text
aimStatusLbl.Text = "DISABLED"
aimStatusLbl.Font = Enum.Font.GothamBold
aimStatusLbl.TextSize = 13
aimStatusLbl.BorderSizePixel = 0
aimStatusLbl.Parent = aimPage
Instance.new("UICorner", aimStatusLbl).CornerRadius = UDim.new(0, 7)

local aimBtn = makeBtn(aimPage, "Enable Aimbot", 82)
aimBtn.MouseButton1Click:Connect(function()
    aimbotEnabled = not aimbotEnabled
    aimBtn.Text = aimbotEnabled and "Disable Aimbot" or "Enable Aimbot"
    aimBtn.BackgroundColor3 = aimbotEnabled and THEME.btnActive or THEME.btn
    aimStatusLbl.Text = aimbotEnabled and "ENABLED" or "DISABLED"
    aimStatusLbl.BackgroundColor3 = aimbotEnabled and THEME.green or THEME.red
    if not aimbotEnabled then hideLockIndicator() end
    sendNotif(aimbotEnabled and "Aimbot ON" or "Aimbot OFF", aimbotEnabled and THEME.green or THEME.red)
end)

makeSection(aimPage, "Settings", 128)

local fovLbl = makeLabel(aimPage, "FOV: 150", 162)
makeSlider(aimPage, 184, 10, 600, 150, function(val)
    aimbotFOV = val
    fovLbl.Text = "FOV: " .. val
end)

local smoothLbl = makeLabel(aimPage, "Smoothing: instant", 208)
makeSlider(aimPage, 230, 1, 10, 10, function(val)
    aimbotSmoothing = val / 10
    smoothLbl.Text = aimbotSmoothing >= 1 and "Smoothing: instant" or "Smoothing: " .. string.format("%.1f", aimbotSmoothing)
end)

makeSection(aimPage, "Lock Target", 258)

local targetFrame = Instance.new("Frame")
targetFrame.Size = UDim2.new(1, -24, 0, 34)
targetFrame.Position = UDim2.new(0, 12, 0, 292)
targetFrame.BackgroundTransparency = 1
targetFrame.Parent = aimPage
local tfl = Instance.new("UIListLayout")
tfl.FillDirection = Enum.FillDirection.Horizontal
tfl.Padding = UDim.new(0, 6)
tfl.Parent = targetFrame

local targetBtns = {}
for _, part in ipairs({"Head", "Torso", "Root"}) do
    local realPart = part == "Root" and "HumanoidRootPart" or part
    local tb = Instance.new("TextButton")
    tb.Size = UDim2.new(0, 118, 1, 0)
    tb.BackgroundColor3 = realPart == aimbotTarget and THEME.btnActive or THEME.btn
    tb.TextColor3 = THEME.text
    tb.Text = part
    tb.Font = Enum.Font.GothamBold
    tb.TextSize = 12
    tb.BorderSizePixel = 0
    tb.Parent = targetFrame
    Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 7)
    targetBtns[realPart] = tb
    tb.MouseButton1Click:Connect(function()
        aimbotTarget = realPart
        for p, b in pairs(targetBtns) do
            b.BackgroundColor3 = p == realPart and THEME.btnActive or THEME.btn
        end
        sendNotif("Target: " .. part)
    end)
end

makeSection(aimPage, "Lock Indicator", 340)

local indFrame = Instance.new("Frame")
indFrame.Size = UDim2.new(1, -24, 0, 34)
indFrame.Position = UDim2.new(0, 12, 0, 374)
indFrame.BackgroundTransparency = 1
indFrame.Parent = aimPage
local ifl = Instance.new("UIListLayout")
ifl.FillDirection = Enum.FillDirection.Horizontal
ifl.Padding = UDim.new(0, 6)
ifl.Parent = indFrame

local circleBtn = Instance.new("TextButton")
circleBtn.Size = UDim2.new(0, 195, 1, 0)
circleBtn.BackgroundColor3 = THEME.btnActive
circleBtn.TextColor3 = THEME.text
circleBtn.Text = "Circle"
circleBtn.Font = Enum.Font.GothamBold
circleBtn.TextSize = 13
circleBtn.BorderSizePixel = 0
circleBtn.Parent = indFrame
Instance.new("UICorner", circleBtn).CornerRadius = UDim.new(0, 7)

local crossBtn = Instance.new("TextButton")
crossBtn.Size = UDim2.new(0, 195, 1, 0)
crossBtn.BackgroundColor3 = THEME.btn
crossBtn.TextColor3 = THEME.text
crossBtn.Text = "Cross"
crossBtn.Font = Enum.Font.GothamBold
crossBtn.TextSize = 13
crossBtn.BorderSizePixel = 0
crossBtn.Parent = indFrame
Instance.new("UICorner", crossBtn).CornerRadius = UDim.new(0, 7)

circleBtn.MouseButton1Click:Connect(function()
    lockIndicatorType = "Circle"
    circleBtn.BackgroundColor3 = THEME.btnActive
    crossBtn.BackgroundColor3 = THEME.btn
    sendNotif("Indicator: Circle")
end)
crossBtn.MouseButton1Click:Connect(function()
    lockIndicatorType = "Cross"
    crossBtn.BackgroundColor3 = THEME.btnActive
    circleBtn.BackgroundColor3 = THEME.btn
    sendNotif("Indicator: Cross")
end)

makeSection(aimPage, "Activation Mode", 422)

local modeFrame = Instance.new("Frame")
modeFrame.Size = UDim2.new(1, -24, 0, 34)
modeFrame.Position = UDim2.new(0, 12, 0, 456)
modeFrame.BackgroundTransparency = 1
modeFrame.Parent = aimPage
local mfl = Instance.new("UIListLayout")
mfl.FillDirection = Enum.FillDirection.Horizontal
mfl.Padding = UDim.new(0, 6)
mfl.Parent = modeFrame

local holdBtn = Instance.new("TextButton")
holdBtn.Size = UDim2.new(0, 195, 1, 0)
holdBtn.BackgroundColor3 = THEME.btnActive
holdBtn.TextColor3 = THEME.text
holdBtn.Text = "Hold"
holdBtn.Font = Enum.Font.GothamBold
holdBtn.TextSize = 13
holdBtn.BorderSizePixel = 0
holdBtn.Parent = modeFrame
Instance.new("UICorner", holdBtn).CornerRadius = UDim.new(0, 7)

local togBtn2 = Instance.new("TextButton")
togBtn2.Size = UDim2.new(0, 195, 1, 0)
togBtn2.BackgroundColor3 = THEME.btn
togBtn2.TextColor3 = THEME.text
togBtn2.Text = "Toggle"
togBtn2.Font = Enum.Font.GothamBold
togBtn2.TextSize = 13
togBtn2.BorderSizePixel = 0
togBtn2.Parent = modeFrame
Instance.new("UICorner", togBtn2).CornerRadius = UDim.new(0, 7)

holdBtn.MouseButton1Click:Connect(function()
    aimbotHoldMode = true
    holdBtn.BackgroundColor3 = THEME.btnActive
    togBtn2.BackgroundColor3 = THEME.btn
    sendNotif("Mode: Hold")
end)
togBtn2.MouseButton1Click:Connect(function()
    aimbotHoldMode = false
    togBtn2.BackgroundColor3 = THEME.btnActive
    holdBtn.BackgroundColor3 = THEME.btn
    sendNotif("Mode: Toggle")
end)

makeSection(aimPage, "Keybind", 504)
local keyBindBtn = makeBtn(aimPage, "Keybind: Q  (click to change)", 538)
keyBindBtn.MouseButton1Click:Connect(function()
    if listeningForKey then return end
    listeningForKey = true
    keyBindBtn.Text = "Press any key..."
    keyBindBtn.BackgroundColor3 = THEME.red
    local conn
    conn = UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard then
            aimbotKey = input.KeyCode
            keyBindBtn.Text = "Keybind: " .. input.KeyCode.Name .. "  (click to change)"
            keyBindBtn.BackgroundColor3 = THEME.btn
            listeningForKey = false
            sendNotif("Keybind: " .. input.KeyCode.Name)
            conn:Disconnect()
        end
    end)
end)

-- Aimbot loop
local function getClosestPlayer()
    local closest, closestDist = nil, aimbotFOV
    local cx, cy = Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local part = p.Character:FindFirstChild(aimbotTarget)
            if part then
                local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local d = math.sqrt((sp.X-cx)^2 + (sp.Y-cy)^2)
                    if d < closestDist then closestDist = d; closest = part end
                end
            end
        end
    end
    return closest
end

RunService.Heartbeat:Connect(function()
    if not aimbotEnabled then
        if currentLockedTarget then
            currentLockedTarget = nil
            hideLockIndicator()
        end
        return
    end
    local active = aimbotHoldMode and UserInputService:IsKeyDown(aimbotKey)
        or (not aimbotHoldMode and aimbotToggled)
    if not active then
        if currentLockedTarget then
            currentLockedTarget = nil
            hideLockIndicator()
        end
        return
    end
    local target = getClosestPlayer()
    if target then
        currentLockedTarget = target
        local targetCF = CFrame.new(Camera.CFrame.Position, target.Position)
        Camera.CFrame = Camera.CFrame:Lerp(targetCF, math.clamp(aimbotSmoothing, 0.1, 1))
        local sp, onScreen = Camera:WorldToViewportPoint(target.Position)
        if onScreen then
            showLockIndicator(sp.X, sp.Y)
        else
            hideLockIndicator()
        end
    else
        currentLockedTarget = nil
        hideLockIndicator()
    end
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe or listeningForKey or listeningForGuiKey then return end
    if input.KeyCode == aimbotKey and not aimbotHoldMode then
        aimbotToggled = not aimbotToggled
        if not aimbotToggled then hideLockIndicator() end
        sendNotif(aimbotToggled and "Aimbot ON" or "Aimbot OFF",
            aimbotToggled and THEME.green or THEME.red)
    end
    if input.KeyCode == guiToggleKey then
        if guiOpen then closeGui() else openGui() end
    end
end)

-- ══════════════════
-- ESP TAB
-- ══════════════════
local espPage = makeTabPage("ESP")
makeSection(espPage, "ESP", 10)

local espStatusLbl = Instance.new("TextLabel")
espStatusLbl.Size = UDim2.new(1, -24, 0, 30)
espStatusLbl.Position = UDim2.new(0, 12, 0, 44)
espStatusLbl.BackgroundColor3 = THEME.red
espStatusLbl.TextColor3 = THEME.text
espStatusLbl.Text = "DISABLED"
espStatusLbl.Font = Enum.Font.GothamBold
espStatusLbl.TextSize = 13
espStatusLbl.BorderSizePixel = 0
espStatusLbl.Parent = espPage
Instance.new("UICorner", espStatusLbl).CornerRadius = UDim.new(0, 7)

local espBtn = makeBtn(espPage, "Enable ESP", 82)
espBtn.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    espBtn.Text = espEnabled and "Disable ESP" or "Enable ESP"
    espBtn.BackgroundColor3 = espEnabled and THEME.btnActive or THEME.btn
    espStatusLbl.Text = espEnabled and "ENABLED" or "DISABLED"
    espStatusLbl.BackgroundColor3 = espEnabled and THEME.green or THEME.red
    sendNotif(espEnabled and "ESP ON" or "ESP OFF", espEnabled and THEME.green or THEME.red)
    if not espEnabled then
        for _, objs in pairs(espObjects) do
            for _, obj in pairs(objs) do
                if obj and obj.Parent then obj:Destroy() end
            end
        end
        espObjects = {}
    end
end)

makeSection(espPage, "Toggles", 128)
makeToggleBtn(espPage, "Boxes",    162, true,  function(v) espBoxes = v end)
makeToggleBtn(espPage, "Names",    204, true,  function(v) espNames = v end)
makeToggleBtn(espPage, "Distance", 246, true,  function(v) espDistance = v end)
makeToggleBtn(espPage, "Tracers",  288, false, function(v) espTracers = v end)

makeSection(espPage, "Colors", 340)
makeColorPicker(espPage, "Box Color", 374, function(c)
    espBoxColor = c
    for _, objs in pairs(espObjects) do
        if objs.box then objs.box.BorderColor3 = c end
    end
end)
makeColorPicker(espPage, "Name Color", 422, function(c)
    espNameColor = c
    for _, objs in pairs(espObjects) do
        if objs.nameTag then objs.nameTag.TextColor3 = c end
    end
end)
makeColorPicker(espPage, "Tracer Color", 470, function(c)
    espTracerColor = c
    for _, objs in pairs(espObjects) do
        if objs.tracer then objs.tracer.BackgroundColor3 = c end
    end
end)

local espGui = Instance.new("ScreenGui")
espGui.Name = "ESPGui"
espGui.ResetOnSpawn = false
espGui.Parent = player.PlayerGui

local function cleanupESPForPlayer(p)
    if espObjects[p] then
        for _, obj in pairs(espObjects[p]) do
            if obj and obj.Parent then obj:Destroy() end
        end
        espObjects[p] = nil
    end
end

local function getESPObjects(p)
    if not espObjects[p] then
        espObjects[p] = {}
        local box = Instance.new("Frame")
        box.BackgroundTransparency = 1
        box.BorderSizePixel = 2
        box.BorderColor3 = espBoxColor
        box.Visible = false
        box.Parent = espGui
        espObjects[p].box = box
        local nameTag = Instance.new("TextLabel")
        nameTag.BackgroundTransparency = 1
        nameTag.TextColor3 = espNameColor
        nameTag.Font = Enum.Font.GothamBold
        nameTag.TextSize = 12
        nameTag.BorderSizePixel = 0
        nameTag.Visible = false
        nameTag.Parent = espGui
        espObjects[p].nameTag = nameTag
        local tracer = Instance.new("Frame")
        tracer.BackgroundColor3 = espTracerColor
        tracer.BorderSizePixel = 0
        tracer.Visible = false
        tracer.Parent = espGui
        espObjects[p].tracer = tracer
    end
    return espObjects[p]
end

Players.PlayerRemoving:Connect(cleanupESPForPlayer)

RunService.RenderStepped:Connect(function()
    local allPlayers = {}
    for _, p in ipairs(Players:GetPlayers()) do allPlayers[p] = true end
    for p in pairs(espObjects) do
        if not allPlayers[p] then cleanupESPForPlayer(p) end
    end
    if not espEnabled then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p == player then continue end
        if not p.Character then cleanupESPForPlayer(p) continue end
        local hrp  = p.Character:FindFirstChild("HumanoidRootPart")
        local head = p.Character:FindFirstChild("Head")
        if not hrp or not head then cleanupESPForPlayer(p) continue end
        local objs = getESPObjects(p)
        local screenPos, onScreen   = Camera:WorldToViewportPoint(hrp.Position)
        local headPos, headOnScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.7, 0))
        if not onScreen or not headOnScreen then
            objs.box.Visible = false
            objs.nameTag.Visible = false
            objs.tracer.Visible = false
            continue
        end
        local height = math.abs(screenPos.Y - headPos.Y) * 2.2
        local width  = height * 0.55
        local dist   = math.floor((rootPart.Position - hrp.Position).Magnitude)
        objs.box.Visible      = espBoxes
        objs.box.BorderColor3 = espBoxColor
        objs.box.Size         = UDim2.new(0, width, 0, height)
        objs.box.Position     = UDim2.new(0, headPos.X - width/2, 0, headPos.Y)
        objs.nameTag.Visible    = espNames or espDistance
        objs.nameTag.TextColor3 = espNameColor
        local txt = espNames and p.Name or ""
        if espDistance then txt = txt .. (espNames and " [" or "[") .. dist .. "m]" end
        objs.nameTag.Text     = txt
        objs.nameTag.Size     = UDim2.new(0, 200, 0, 18)
        objs.nameTag.Position = UDim2.new(0, headPos.X - 100, 0, headPos.Y - 22)
        objs.tracer.Visible          = espTracers
        objs.tracer.BackgroundColor3 = espTracerColor
        local botX = Camera.ViewportSize.X / 2
        local botY = Camera.ViewportSize.Y
        local dx   = screenPos.X - botX
        local dy   = screenPos.Y - botY
        local len  = math.sqrt(dx*dx + dy*dy)
        objs.tracer.Size     = UDim2.new(0, 2, 0, len)
        objs.tracer.Position = UDim2.new(0, botX, 0, botY)
        objs.tracer.Rotation = math.deg(math.atan2(dy, dx)) + 90
    end
end)

-- ══════════════════
-- SETTINGS TAB
-- ══════════════════
local settingsPage = makeTabPage("Settings")
makeSection(settingsPage, "GUI Toggle Key", 10)

local guiKeyLbl = makeLabel(settingsPage, "Current key: Y", 44)
local guiKeyBtn = makeBtn(settingsPage, "Change Key (click then press key)", 66)
guiKeyBtn.MouseButton1Click:Connect(function()
    if listeningForGuiKey then return end
    listeningForGuiKey = true
    guiKeyBtn.Text = "Press any key..."
    guiKeyBtn.BackgroundColor3 = THEME.red
    local conn
    conn = UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard then
            guiToggleKey = input.KeyCode
            guiKeyLbl.Text = "Current key: " .. input.KeyCode.Name
            guiKeyBtn.Text = "Change Key (click then press key)"
            guiKeyBtn.BackgroundColor3 = THEME.btn
            listeningForGuiKey = false
            sendNotif("GUI key: " .. input.KeyCode.Name)
            conn:Disconnect()
        end
    end)
end)

makeSection(settingsPage, "Open / Close Animation", 116)
local animStyles = {"Back", "Bounce", "Elastic", "Quad", "Sine"}
local currentOpenStyle = "Back"
local currentCloseStyle = "Quad"

makeLabel(settingsPage, "Open style:", 150)
local openStyleFrame = Instance.new("Frame")
openStyleFrame.Size = UDim2.new(1, -24, 0, 34)
openStyleFrame.Position = UDim2.new(0, 12, 0, 172)
openStyleFrame.BackgroundTransparency = 1
openStyleFrame.Parent = settingsPage
local ofl = Instance.new("UIListLayout")
ofl.FillDirection = Enum.FillDirection.Horizontal
ofl.Padding = UDim.new(0, 5)
ofl.Parent = openStyleFrame

local openStyleBtns = {}
for _, style in ipairs(animStyles) do
    local sb = Instance.new("TextButton")
    sb.Size = UDim2.new(0, 72, 1, 0)
    sb.BackgroundColor3 = style == currentOpenStyle and THEME.btnActive or THEME.btn
    sb.TextColor3 = THEME.text
    sb.Text = style
    sb.Font = Enum.Font.GothamBold
    sb.TextSize = 11
    sb.BorderSizePixel = 0
    sb.Parent = openStyleFrame
    Instance.new("UICorner", sb).CornerRadius = UDim.new(0, 6)
    openStyleBtns[style] = sb
    sb.MouseButton1Click:Connect(function()
        currentOpenStyle = style
        for s, b in pairs(openStyleBtns) do
            b.BackgroundColor3 = s == style and THEME.btnActive or THEME.btn
        end
        sendNotif("Open style: " .. style)
    end)
end

makeLabel(settingsPage, "Close style:", 216)
local closeStyleFrame = Instance.new("Frame")
closeStyleFrame.Size = UDim2.new(1, -24, 0, 34)
closeStyleFrame.Position = UDim2.new(0, 12, 0, 238)
closeStyleFrame.BackgroundTransparency = 1
closeStyleFrame.Parent = settingsPage
local cfl = Instance.new("UIListLayout")
cfl.FillDirection = Enum.FillDirection.Horizontal
cfl.Padding = UDim.new(0, 5)
cfl.Parent = closeStyleFrame

local closeStyleBtns = {}
for _, style in ipairs(animStyles) do
    local sb = Instance.new("TextButton")
    sb.Size = UDim2.new(0, 72, 1, 0)
    sb.BackgroundColor3 = style == currentCloseStyle and THEME.btnActive or THEME.btn
    sb.TextColor3 = THEME.text
    sb.Text = style
    sb.Font = Enum.Font.GothamBold
    sb.TextSize = 11
    sb.BorderSizePixel = 0
    sb.Parent = closeStyleFrame
    Instance.new("UICorner", sb).CornerRadius = UDim.new(0, 6)
    closeStyleBtns[style] = sb
    sb.MouseButton1Click:Connect(function()
        currentCloseStyle = style
        for s, b in pairs(closeStyleBtns) do
            b.BackgroundColor3 = s == style and THEME.btnActive or THEME.btn
        end
        sendNotif("Close style: " .. style)
    end)
end

makeSection(settingsPage, "Speed", 286)
local openSpeedVal = 0.35
local closeSpeedVal = 0.25

local openSpeedLbl = makeLabel(settingsPage, "Open speed: 0.35s", 320)
makeSlider(settingsPage, 342, 1, 20, 4, function(val)
    openSpeedVal = val / 10
    openSpeedLbl.Text = "Open speed: " .. string.format("%.2f", openSpeedVal) .. "s"
end)

local closeSpeedLbl = makeLabel(settingsPage, "Close speed: 0.25s", 366)
makeSlider(settingsPage, 388, 1, 20, 3, function(val)
    closeSpeedVal = val / 10
    closeSpeedLbl.Text = "Close speed: " .. string.format("%.2f", closeSpeedVal) .. "s"
end)
-- Save/Load settings
makeSection(settingsPage, "Save Settings", 420)

local saveBtn = makeBtn(settingsPage, "Save Current Settings", 454)
local loadBtn = makeBtn(settingsPage, "Load Saved Settings", 498)
local saveStatusLbl = makeLabel(settingsPage, "No saved settings found", 542)

local function getSettings()
    return {
        walkSpeed = currentSpeed,
        flySpeed = flySpeedVal,
        aimbotFOV = aimbotFOV,
        aimbotSmoothing = aimbotSmoothing,
        aimbotTarget = aimbotTarget,
        aimbotHoldMode = aimbotHoldMode,
        aimbotKey = aimbotKey.Name,
        lockIndicator = lockIndicatorType,
        guiKey = guiToggleKey.Name,
        openStyle = currentOpenStyle,
        closeStyle = currentCloseStyle,
    }
end

local function saveSettings()
    local ok, err = pcall(function()
        local data = getSettings()
        local json = game:GetService("HttpService"):JSONEncode(data)
        writefile("IkesScript_settings.json", json)
    end)
    if ok then
        saveStatusLbl.Text = "Settings saved!"
        sendNotif("Settings saved", THEME.green)
    else
        saveStatusLbl.Text = "Save failed (executor may not support it)"
        sendNotif("Save failed", THEME.red)
    end
end

local function loadSettings()
    local ok, err = pcall(function()
        local json = readfile("IkesScript_settings.json")
        local data = game:GetService("HttpService"):JSONDecode(json)

        if data.walkSpeed then
            currentSpeed = data.walkSpeed
            humanoid.WalkSpeed = currentSpeed
            speedLbl.Text = "WalkSpeed: " .. currentSpeed
        end
        if data.flySpeed then flySpeedVal = data.flySpeed end
        if data.aimbotFOV then aimbotFOV = data.aimbotFOV end
        if data.aimbotSmoothing then aimbotSmoothing = data.aimbotSmoothing end
        if data.aimbotTarget then aimbotTarget = data.aimbotTarget end
        if data.aimbotHoldMode ~= nil then aimbotHoldMode = data.aimbotHoldMode end
        if data.aimbotKey then
            local ok2, key = pcall(function() return Enum.KeyCode[data.aimbotKey] end)
            if ok2 then aimbotKey = key end
        end
        if data.lockIndicator then lockIndicatorType = data.lockIndicator end
        if data.guiKey then
            local ok2, key = pcall(function() return Enum.KeyCode[data.guiKey] end)
            if ok2 then
                guiToggleKey = key
                guiKeyLbl.Text = "Current key: " .. data.guiKey
            end
        end
        if data.openStyle then currentOpenStyle = data.openStyle end
        if data.closeStyle then currentCloseStyle = data.closeStyle end
    end)
    if ok then
        saveStatusLbl.Text = "Settings loaded!"
        sendNotif("Settings loaded", THEME.green)
    else
        saveStatusLbl.Text = "No save file found"
        sendNotif("No save found", THEME.red)
    end
end

saveBtn.MouseButton1Click:Connect(saveSettings)
loadBtn.MouseButton1Click:Connect(loadSettings)

-- Theme customization
makeSection(settingsPage, "GUI Customization", 566)

makeColorPicker(settingsPage, "Accent Color", 600, function(c)
    THEME.btnActive = c
    THEME.tabActive = c
    sendNotif("Accent color changed")
end)

makeColorPicker(settingsPage, "Button Color", 648, function(c)
    THEME.btn = c
    sendNotif("Button color changed")
end)

makeColorPicker(settingsPage, "Background Color", 696, function(c)
    THEME.bg = c
    frame.BackgroundColor3 = c
    sendNotif("Background color changed")
end)

makeColorPicker(settingsPage, "Text Color", 744, function(c)
    THEME.text = c
    titleLabel.TextColor3 = c
    sendNotif("Text color changed")
end)
-- ══════════════════
-- TOGGLE BUTTON + ANIM
-- ══════════════════
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 130, 0, 32)
toggleBtn.Position = UDim2.new(0.5, -65, 0, 10)
toggleBtn.BackgroundColor3 = THEME.panel
toggleBtn.TextColor3 = THEME.text
toggleBtn.Text = "Ike's Script"
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 12
toggleBtn.BorderSizePixel = 0
toggleBtn.ZIndex = 10
toggleBtn.Parent = screenGui
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 8)
local tgs = Instance.new("UIStroke")
tgs.Color = THEME.accent
tgs.Thickness = 1.5
tgs.Parent = toggleBtn

function openGui()
    guiOpen = true
    frame.Visible = true
    frame.Size = UDim2.new(0, 420, 0, 0)
    local style = Enum.EasingStyle[currentOpenStyle] or Enum.EasingStyle.Back
    TweenService:Create(frame, TweenInfo.new(openSpeedVal, style, Enum.EasingDirection.Out),
        {Size = UDim2.new(0, 420, 0, 500)}):Play()
    toggleBtn.Text = "Close"
end

function closeGui()
    guiOpen = false
    local style = Enum.EasingStyle[currentCloseStyle] or Enum.EasingStyle.Quad
    local t = TweenService:Create(frame, TweenInfo.new(closeSpeedVal, style, Enum.EasingDirection.In),
        {Size = UDim2.new(0, 420, 0, 0)})
    t:Play()
    t.Completed:Connect(function() frame.Visible = false end)
    toggleBtn.Text = "Ike's Script"
end

frame.Visible = false
switchTab("Misc")
openGui()

toggleBtn.MouseButton1Click:Connect(function()
    if guiOpen then closeGui() else openGui() end
end)

sendNotif("Ike's Script loaded!")
