local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
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
local infJumpEnabled = false
local noclipEnabled = false
local noclipConnection
local flyVelocity, flyGyro = nil, nil

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
local currentOpenStyle = "Quad"
local currentCloseStyle = "Quad"
local openSpeedVal = 0.3
local closeSpeedVal = 0.2
local flySpeedVal = 1.2

-- Theme
local THEME = {
    bg         = Color3.fromRGB(15, 15, 15),
    panel      = Color3.fromRGB(22, 22, 22),
    card       = Color3.fromRGB(28, 28, 28),
    border     = Color3.fromRGB(40, 40, 40),
    tabActive  = Color3.fromRGB(255, 255, 255),
    tabInactive= Color3.fromRGB(80, 80, 80),
    tabBg      = Color3.fromRGB(30, 30, 30),
    tabActiveBg= Color3.fromRGB(45, 45, 45),
    text       = Color3.new(1, 1, 1),
    subtext    = Color3.fromRGB(130, 130, 130),
    accent     = Color3.fromRGB(100, 100, 255),
    green      = Color3.fromRGB(0, 200, 80),
    red        = Color3.fromRGB(220, 50, 50),
    toggleOn   = Color3.fromRGB(100, 100, 255),
    toggleOff  = Color3.fromRGB(50, 50, 50),
}

-- Notif
local notifGui = Instance.new("ScreenGui")
notifGui.Name = "NotifGui"
notifGui.ResetOnSpawn = false
notifGui.Parent = player.PlayerGui

local function sendNotif(text, color)
    color = color or THEME.accent
    local notif = Instance.new("Frame")
    notif.Size = UDim2.new(0, 220, 0, 38)
    notif.Position = UDim2.new(1, 10, 1, -55)
    notif.BackgroundColor3 = THEME.panel
    notif.BorderSizePixel = 0
    notif.Parent = notifGui
    Instance.new("UICorner", notif).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Thickness = 1
    stroke.Parent = notif
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 6, 0, 6)
    dot.Position = UDim2.new(0, 10, 0.5, -3)
    dot.BackgroundColor3 = color
    dot.BorderSizePixel = 0
    dot.Parent = notif
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
    local nl = Instance.new("TextLabel")
    nl.Size = UDim2.new(1, -26, 1, 0)
    nl.Position = UDim2.new(0, 24, 0, 0)
    nl.BackgroundTransparency = 1
    nl.TextColor3 = THEME.text
    nl.Text = text
    nl.Font = Enum.Font.GothamBold
    nl.TextSize = 12
    nl.TextXAlignment = Enum.TextXAlignment.Left
    nl.Parent = notif
    TweenService:Create(notif, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        {Position = UDim2.new(1, -230, 1, -55)}):Play()
    task.delay(2.2, function()
        local t = TweenService:Create(notif, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
            {Position = UDim2.new(1, 10, 1, -55)})
        t:Play()
        t.Completed:Connect(function() notif:Destroy() end)
    end)
end

-- Lock indicator
local lockGui = Instance.new("ScreenGui")
lockGui.Name = "LockGui"
lockGui.ResetOnSpawn = false
lockGui.Parent = player.PlayerGui

local lockCircle = Instance.new("Frame")
lockCircle.Size = UDim2.new(0, 28, 0, 28)
lockCircle.BackgroundTransparency = 1
lockCircle.BorderSizePixel = 2
lockCircle.BorderColor3 = THEME.red
lockCircle.Visible = false
lockCircle.Parent = lockGui
Instance.new("UICorner", lockCircle).CornerRadius = UDim.new(1, 0)

local lockCrossH = Instance.new("Frame")
lockCrossH.Size = UDim2.new(0, 20, 0, 2)
lockCrossH.BackgroundColor3 = THEME.red
lockCrossH.BorderSizePixel = 0
lockCrossH.Visible = false
lockCrossH.Parent = lockGui

local lockCrossV = Instance.new("Frame")
lockCrossV.Size = UDim2.new(0, 2, 0, 20)
lockCrossV.BackgroundColor3 = THEME.red
lockCrossV.BorderSizePixel = 0
lockCrossV.Visible = false
lockCrossV.Parent = lockGui

local function showLockIndicator(x, y)
    if lockIndicatorType == "Circle" then
        lockCircle.Visible = true
        lockCrossH.Visible = false
        lockCrossV.Visible = false
        lockCircle.Position = UDim2.new(0, x - 14, 0, y - 14)
    else
        lockCircle.Visible = false
        lockCrossH.Visible = true
        lockCrossV.Visible = true
        lockCrossH.Position = UDim2.new(0, x - 10, 0, y - 1)
        lockCrossV.Position = UDim2.new(0, x - 1, 0, y - 10)
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
frame.Size = UDim2.new(0, 380, 0, 480)
frame.Position = UDim2.new(0.5, -190, 0.5, -240)
frame.BackgroundColor3 = THEME.bg
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.ClipsDescendants = true
frame.Parent = screenGui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local frameBorder = Instance.new("UIStroke")
frameBorder.Color = THEME.border
frameBorder.Thickness = 1
frameBorder.Parent = frame

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = THEME.panel
titleBar.BorderSizePixel = 0
titleBar.Parent = frame
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 10)

-- fix title bar bottom corners
local titleFix = Instance.new("Frame")
titleFix.Size = UDim2.new(1, 0, 0, 10)
titleFix.Position = UDim2.new(0, 0, 1, -10)
titleFix.BackgroundColor3 = THEME.panel
titleFix.BorderSizePixel = 0
titleFix.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -16, 1, 0)
titleLabel.Position = UDim2.new(0, 14, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3 = THEME.text
titleLabel.Text = "Ike's Script"
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 14
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

-- Tab bar
local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -20, 0, 30)
tabBar.Position = UDim2.new(0, 10, 0, 48)
tabBar.BackgroundTransparency = 1
tabBar.Parent = frame

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Padding = UDim.new(0, 4)
tabLayout.Parent = tabBar

-- Divider
local divider = Instance.new("Frame")
divider.Size = UDim2.new(1, 0, 0, 1)
divider.Position = UDim2.new(0, 0, 0, 86)
divider.BackgroundColor3 = THEME.border
divider.BorderSizePixel = 0
divider.Parent = frame

-- Content
local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, 0, 1, -87)
contentFrame.Position = UDim2.new(0, 0, 0, 87)
contentFrame.BackgroundTransparency = 1
contentFrame.ClipsDescendants = true
contentFrame.Parent = frame

local tabPages = {}
local tabButtons = {}

local function makeTabPage(name, canvasH)
    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 2
    page.ScrollBarImageColor3 = THEME.border
    page.CanvasSize = UDim2.new(0, 0, 0, canvasH or 600)
    page.Visible = false
    page.Parent = contentFrame
    tabPages[name] = page
    return page
end

local function switchTab(name)
    for n, page in pairs(tabPages) do
        if n == name then
            page.Visible = true
        else
            page.Visible = false
        end
    end
    for n, btn in pairs(tabButtons) do
        if n == name then
            btn.TextColor3 = THEME.text
            btn.BackgroundColor3 = THEME.tabActiveBg
            TweenService:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Quint),
                {BackgroundColor3 = THEME.tabActiveBg, TextColor3 = THEME.text}):Play()
        else
            TweenService:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Quint),
                {BackgroundColor3 = THEME.tabBg, TextColor3 = THEME.tabInactive}):Play()
        end
    end
end

local function makeTab(name, order)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 70, 1, 0)
    btn.BackgroundColor3 = THEME.tabBg
    btn.TextColor3 = THEME.tabInactive
    btn.Text = name
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.BorderSizePixel = 0
    btn.LayoutOrder = order
    btn.Parent = tabBar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    tabButtons[name] = btn
    btn.MouseButton1Click:Connect(function() switchTab(name) end)
    return btn
end

-- Helpers
local function makeSection(page, text, yPos)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -24, 0, 20)
    lbl.Position = UDim2.new(0, 14, 0, yPos)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = THEME.subtext
    lbl.Text = text
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = page
    return lbl
end

local function makeLabel(page, text, yPos)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -24, 0, 18)
    lbl.Position = UDim2.new(0, 14, 0, yPos)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = THEME.subtext
    lbl.Text = text
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = page
    return lbl
end

local function makeRow(page, yPos)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -20, 0, 38)
    row.Position = UDim2.new(0, 10, 0, yPos)
    row.BackgroundColor3 = THEME.card
    row.BorderSizePixel = 0
    row.Parent = page
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 7)
    return row
end

local function makeRowLabel(row, text)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.6, 0, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = THEME.text
    lbl.Text = text
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row
    return lbl
end

-- Toggle switch
local function makeToggle(page, text, yPos, default, onToggle)
    local row = makeRow(page, yPos)
    makeRowLabel(row, text)

    local switchBg = Instance.new("Frame")
    switchBg.Size = UDim2.new(0, 40, 0, 22)
    switchBg.Position = UDim2.new(1, -52, 0.5, -11)
    switchBg.BackgroundColor3 = default and THEME.toggleOn or THEME.toggleOff
    switchBg.BorderSizePixel = 0
    switchBg.Parent = row
    Instance.new("UICorner", switchBg).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = default and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.BorderSizePixel = 0
    knob.Parent = switchBg
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local state = default
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = row

    btn.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(switchBg, TweenInfo.new(0.2, Enum.EasingStyle.Quint),
            {BackgroundColor3 = state and THEME.toggleOn or THEME.toggleOff}):Play()
        TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Quint),
            {Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)}):Play()
        onToggle(state)
    end)

    return row, function() return state end
end

local function makeBtn(page, text, yPos, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 36)
    btn.Position = UDim2.new(0, 10, 0, yPos)
    btn.BackgroundColor3 = color or THEME.card
    btn.TextColor3 = THEME.text
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.BorderSizePixel = 0
    btn.Parent = page
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)

    btn.MouseButton1Down:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1, Enum.EasingStyle.Quint),
            {BackgroundColor3 = Color3.fromRGB(
                math.clamp((btn.BackgroundColor3.R * 255) - 15, 0, 255),
                math.clamp((btn.BackgroundColor3.G * 255) - 15, 0, 255),
                math.clamp((btn.BackgroundColor3.B * 255) - 15, 0, 255)
            )}):Play()
    end)
    btn.MouseButton1Up:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1, Enum.EasingStyle.Quint),
            {BackgroundColor3 = color or THEME.card}):Play()
    end)
    return btn
end

local function makeSlider(page, yPos, label, minVal, maxVal, defaultVal, onChanged)
    local lbl = makeLabel(page, label .. ": " .. defaultVal, yPos)
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, -20, 0, 4)
    bg.Position = UDim2.new(0, 10, 0, yPos + 22)
    bg.BackgroundColor3 = THEME.border
    bg.BorderSizePixel = 0
    bg.Parent = page
    Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)

    local ratio0 = (defaultVal - minVal) / (maxVal - minVal)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(ratio0, 0, 1, 0)
    fill.BackgroundColor3 = THEME.accent
    fill.BorderSizePixel = 0
    fill.Parent = bg
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local handle = Instance.new("TextButton")
    handle.Size = UDim2.new(0, 14, 0, 14)
    handle.Position = UDim2.new(ratio0, -7, 0.5, -7)
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
            handle.Position = UDim2.new(r, -7, 0.5, -7)
            lbl.Text = label .. ": " .. val
            onChanged(val)
        end
    end)
    return lbl
end

local function makeColorPicker(page, text, yPos, onChanged)
    makeLabel(page, text, yPos)
    local colors = {
        {Color3.fromRGB(255,50,50),   "Red"},
        {Color3.fromRGB(50,150,255),  "Blue"},
        {Color3.fromRGB(50,255,80),   "Green"},
        {Color3.fromRGB(255,200,50),  "Yellow"},
        {Color3.fromRGB(255,255,255), "White"},
        {Color3.fromRGB(255,105,180), "Pink"},
        {Color3.fromRGB(160,80,255),  "Purple"},
        {Color3.fromRGB(50,220,200),  "Teal"},
    }
    local sf = Instance.new("Frame")
    sf.Size = UDim2.new(1, -20, 0, 24)
    sf.Position = UDim2.new(0, 10, 0, yPos + 20)
    sf.BackgroundTransparency = 1
    sf.Parent = page
    local sl = Instance.new("UIListLayout")
    sl.FillDirection = Enum.FillDirection.Horizontal
    sl.Padding = UDim.new(0, 6)
    sl.Parent = sf
    for _, c in ipairs(colors) do
        local sw = Instance.new("TextButton")
        sw.Size = UDim2.new(0, 24, 0, 24)
        sw.BackgroundColor3 = c[1]
        sw.Text = ""
        sw.BorderSizePixel = 0
        sw.Parent = sf
        Instance.new("UICorner", sw).CornerRadius = UDim.new(1, 0)
        sw.MouseButton1Click:Connect(function()
            onChanged(c[1])
            sendNotif(text .. ": " .. c[2], c[1])
        end)
    end
end

local function makeStatusBadge(page, yPos)
    local badge = Instance.new("Frame")
    badge.Size = UDim2.new(1, -20, 0, 30)
    badge.Position = UDim2.new(0, 10, 0, yPos)
    badge.BackgroundColor3 = THEME.red
    badge.BorderSizePixel = 0
    badge.Parent = page
    Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 6)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = THEME.text
    lbl.Text = "DISABLED"
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 12
    lbl.Parent = badge
    return badge, lbl
end

local function makeTargetBtns(page, yPos, options, default, onSelect)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -20, 0, 32)
    f.Position = UDim2.new(0, 10, 0, yPos)
    f.BackgroundTransparency = 1
    f.Parent = page
    local fl = Instance.new("UIListLayout")
    fl.FillDirection = Enum.FillDirection.Horizontal
    fl.Padding = UDim.new(0, 5)
    fl.Parent = f
    local btns = {}
    local btnW = math.floor((360 - 20 - (#options - 1) * 5) / #options)
    for _, opt in ipairs(options) do
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, btnW, 1, 0)
        b.BackgroundColor3 = opt == default and THEME.accent or THEME.card
        b.TextColor3 = THEME.text
        b.Text = opt
        b.Font = Enum.Font.GothamBold
        b.TextSize = 12
        b.BorderSizePixel = 0
        b.Parent = f
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
        btns[opt] = b
        b.MouseButton1Click:Connect(function()
            for o, btn in pairs(btns) do
                TweenService:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Quint),
                    {BackgroundColor3 = o == opt and THEME.accent or THEME.card}):Play()
            end
            onSelect(opt)
        end)
    end
    return btns
end

-- Tabs
makeTab("Misc",      1)
makeTab("Fly",       2)
makeTab("Aimbot",    3)
makeTab("ESP",       4)
makeTab("Settings",  5)
makeTab("Personalize", 6)

-- ══════════════════
-- MISC TAB
-- ══════════════════
local miscPage = makeTabPage("Misc", 500)

makeSection(miscPage, "MOVEMENT", 14)
local speedLbl = makeSlider(miscPage, 38, "WalkSpeed", 1, 300, 16, function(val)
    currentSpeed = val
    humanoid.WalkSpeed = val
end)
local jumpLbl = makeSlider(miscPage, 90, "JumpPower", 1, 500, 50, function(val)
    humanoid.JumpPower = val
end)

makeSection(miscPage, "TOGGLES", 148)
makeToggle(miscPage, "Infinite Jump", 172, false, function(v)
    infJumpEnabled = v
    sendNotif(v and "Inf Jump ON" or "Inf Jump OFF", v and THEME.green or THEME.red)
end)
makeToggle(miscPage, "Noclip", 218, false, function(v)
    noclipEnabled = v
    sendNotif(v and "Noclip ON" or "Noclip OFF", v and THEME.green or THEME.red)
    if v then
        noclipConnection = RunService.Stepped:Connect(function()
            if noclipEnabled and character then
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end)
    else
        if noclipConnection then noclipConnection:Disconnect() noclipConnection = nil end
        if character then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = true end
            end
        end
    end
end)

makeSection(miscPage, "OTHER", 270)
local resetBtn = makeBtn(miscPage, "Reset Speed and Jump", 294)
resetBtn.MouseButton1Click:Connect(function()
    humanoid.WalkSpeed = 16
    humanoid.JumpPower = 50
    sendNotif("Stats reset")
end)

local unloadBtn = makeBtn(miscPage, "Unload Script", 338, THEME.red)
unloadBtn.MouseButton1Click:Connect(function()
    if flying then
        flying = false
        humanoid.PlatformStand = false
        if flyConnection then flyConnection:Disconnect() end
        for _, n in ipairs({"FlyBodyPosition","FlyBodyGyro","FlyVelocity","FlyGyro","FlyAttachment"}) do
            local o = rootPart:FindFirstChild(n)
            if o then o:Destroy() end
        end
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
    screenGui:Destroy()
    notifGui:Destroy()
    lockGui:Destroy()
end)

UserInputService.JumpRequest:Connect(function()
    if infJumpEnabled and character and humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- ══════════════════
-- FLY TAB
-- ══════════════════
local flyPage = makeTabPage("Fly", 300)
makeSection(flyPage, "FLY", 14)

local flyBtn = makeBtn(flyPage, "Fly: OFF", 38)
makeSlider(flyPage, 88, "Fly Speed", 1, 30, 3, function(val)
    flySpeedVal = val / 10
end)

local function stopFly()
    flying = false
    flyBtn.Text = "Fly: OFF"
    TweenService:Create(flyBtn, TweenInfo.new(0.15, Enum.EasingStyle.Quint),
        {BackgroundColor3 = THEME.card}):Play()
    humanoid.PlatformStand = false
    if flyConnection then flyConnection:Disconnect() flyConnection = nil end
    for _, n in ipairs({"FlyBodyPosition","FlyBodyGyro","FlyVelocity","FlyGyro","FlyAttachment"}) do
        local o = rootPart:FindFirstChild(n)
        if o then o:Destroy() end
    end
    flyVelocity = nil
    flyGyro = nil
    sendNotif("Fly OFF", THEME.red)
end

local function startFly()
    flying = true
    flyBtn.Text = "Fly: ON"
    TweenService:Create(flyBtn, TweenInfo.new(0.15, Enum.EasingStyle.Quint),
        {BackgroundColor3 = THEME.accent}):Play()
    humanoid.PlatformStand = true

    local success = pcall(function()
        local att = Instance.new("Attachment")
        att.Name = "FlyAttachment"
        att.Parent = rootPart
        local lv = Instance.new("LinearVelocity")
        lv.Name = "FlyVelocity"
        lv.Attachment0 = att
        lv.MaxForce = math.huge
        lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
        lv.VectorVelocity = Vector3.zero
        lv.Parent = rootPart
        flyVelocity = lv
        local ao = Instance.new("AlignOrientation")
        ao.Name = "FlyGyro"
        ao.Attachment0 = att
        ao.MaxTorque = math.huge
        ao.MaxAngularVelocity = math.huge
        ao.Responsiveness = 200
        ao.CFrame = rootPart.CFrame
        ao.Parent = rootPart
        flyGyro = ao
    end)

    if not success or not flyVelocity then
        pcall(function()
            local bp = Instance.new("BodyPosition")
            bp.Name = "FlyBodyPosition"
            bp.MaxForce = Vector3.new(1e5,1e5,1e5)
            bp.Position = rootPart.Position
            bp.Parent = rootPart
            local bg = Instance.new("BodyGyro")
            bg.Name = "FlyBodyGyro"
            bg.MaxTorque = Vector3.new(1e5,1e5,1e5)
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
            flyVelocity.VectorVelocity = dir * speed
            if flyGyro then flyGyro.CFrame = cam.CFrame end
        else
            local bp = rootPart:FindFirstChild("FlyBodyPosition")
            local bg = rootPart:FindFirstChild("FlyBodyGyro")
            if bp then bp.Position += dir * flySpeedVal end
            if bg then bg.CFrame = cam.CFrame end
        end
    end)
    sendNotif("Fly ON", THEME.green)
end

flyBtn.MouseButton1Click:Connect(function()
    if flying then stopFly() else startFly() end
end)

-- ══════════════════
-- AIMBOT TAB
-- ══════════════════
local aimPage = makeTabPage("Aimbot", 620)
makeSection(aimPage, "AIMBOT", 14)

local aimBadge, aimBadgeLbl = makeStatusBadge(aimPage, 38)
local aimBtn = makeBtn(aimPage, "Enable Aimbot", 78)
aimBtn.MouseButton1Click:Connect(function()
    aimbotEnabled = not aimbotEnabled
    aimBtn.Text = aimbotEnabled and "Disable Aimbot" or "Enable Aimbot"
    TweenService:Create(aimBadge, TweenInfo.new(0.2, Enum.EasingStyle.Quint),
        {BackgroundColor3 = aimbotEnabled and THEME.green or THEME.red}):Play()
    aimBadgeLbl.Text = aimbotEnabled and "ENABLED" or "DISABLED"
    TweenService:Create(aimBtn, TweenInfo.new(0.15, Enum.EasingStyle.Quint),
        {BackgroundColor3 = aimbotEnabled and THEME.accent or THEME.card}):Play()
    if not aimbotEnabled then hideLockIndicator() end
    sendNotif(aimbotEnabled and "Aimbot ON" or "Aimbot OFF", aimbotEnabled and THEME.green or THEME.red)
end)

makeSection(aimPage, "SETTINGS", 128)
makeSlider(aimPage, 150, "FOV", 10, 600, 150, function(val) aimbotFOV = val end)
makeSlider(aimPage, 202, "Smoothing", 1, 10, 10, function(val)
    aimbotSmoothing = val / 10
end)

makeSection(aimPage, "LOCK TARGET", 258)
makeTargetBtns(aimPage, 282, {"Head", "Torso", "Root"}, "Head", function(opt)
    aimbotTarget = opt == "Root" and "HumanoidRootPart" or opt
    sendNotif("Target: " .. opt)
end)

makeSection(aimPage, "INDICATOR", 328)
makeTargetBtns(aimPage, 352, {"Circle", "Cross"}, "Circle", function(opt)
    lockIndicatorType = opt
    sendNotif("Indicator: " .. opt)
end)

makeSection(aimPage, "MODE", 398)
makeTargetBtns(aimPage, 422, {"Hold", "Toggle"}, "Hold", function(opt)
    aimbotHoldMode = opt == "Hold"
    sendNotif("Mode: " .. opt)
end)

makeSection(aimPage, "KEYBIND", 468)
local keyBindBtn = makeBtn(aimPage, "Keybind: Q  —  click to change", 492)
keyBindBtn.MouseButton1Click:Connect(function()
    if listeningForKey then return end
    listeningForKey = true
    keyBindBtn.Text = "Press any key..."
    TweenService:Create(keyBindBtn, TweenInfo.new(0.15),
        {BackgroundColor3 = THEME.red}):Play()
    local conn
    conn = UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard then
            aimbotKey = input.KeyCode
            keyBindBtn.Text = "Keybind: " .. input.KeyCode.Name .. "  —  click to change"
            TweenService:Create(keyBindBtn, TweenInfo.new(0.15),
                {BackgroundColor3 = THEME.card}):Play()
            listeningForKey = false
            sendNotif("Keybind: " .. input.KeyCode.Name)
            conn:Disconnect()
        end
    end)
end)

-- Aimbot loop
RunService.Heartbeat:Connect(function()
    if not aimbotEnabled then
        if currentLockedTarget then currentLockedTarget = nil hideLockIndicator() end
        return
    end
    local active = aimbotHoldMode and UserInputService:IsKeyDown(aimbotKey)
        or (not aimbotHoldMode and aimbotToggled)
    if not active then
        if currentLockedTarget then currentLockedTarget = nil hideLockIndicator() end
        return
    end
    local closest, closestDist = nil, aimbotFOV
    local cx, cy = Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local part = p.Character:FindFirstChild(aimbotTarget)
            if part then
                local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local d = math.sqrt((sp.X-cx)^2+(sp.Y-cy)^2)
                    if d < closestDist then closestDist = d closest = part end
                end
            end
        end
    end
    if closest then
        currentLockedTarget = closest
        local targetCF = CFrame.new(Camera.CFrame.Position, closest.Position)
        Camera.CFrame = Camera.CFrame:Lerp(targetCF, math.clamp(aimbotSmoothing, 0.1, 1))
        local sp, onScreen = Camera:WorldToViewportPoint(closest.Position)
        if onScreen then showLockIndicator(sp.X, sp.Y) else hideLockIndicator() end
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
local espPage = makeTabPage("ESP", 560)
makeSection(espPage, "ESP", 14)

local espBadge, espBadgeLbl = makeStatusBadge(espPage, 38)
local espBtn = makeBtn(espPage, "Enable ESP", 78)
espBtn.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    espBtn.Text = espEnabled and "Disable ESP" or "Enable ESP"
    TweenService:Create(espBadge, TweenInfo.new(0.2, Enum.EasingStyle.Quint),
        {BackgroundColor3 = espEnabled and THEME.green or THEME.red}):Play()
    espBadgeLbl.Text = espEnabled and "ENABLED" or "DISABLED"
    TweenService:Create(espBtn, TweenInfo.new(0.15, Enum.EasingStyle.Quint),
        {BackgroundColor3 = espEnabled and THEME.accent or THEME.card}):Play()
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

makeSection(espPage, "TOGGLES", 124)
makeToggle(espPage, "Boxes",    148, true,  function(v) espBoxes = v end)
makeToggle(espPage, "Names",    194, true,  function(v) espNames = v end)
makeToggle(espPage, "Distance", 240, true,  function(v) espDistance = v end)
makeToggle(espPage, "Tracers",  286, false, function(v) espTracers = v end)

makeSection(espPage, "COLORS", 340)
makeColorPicker(espPage, "Box Color",    364, function(c)
    espBoxColor = c
    for _, o in pairs(espObjects) do if o.box then o.box.BorderColor3 = c end end
end)
makeColorPicker(espPage, "Name Color",   410, function(c)
    espNameColor = c
    for _, o in pairs(espObjects) do if o.nameTag then o.nameTag.TextColor3 = c end end
end)
makeColorPicker(espPage, "Tracer Color", 456, function(c)
    espTracerColor = c
    for _, o in pairs(espObjects) do if o.tracer then o.tracer.BackgroundColor3 = c end end
end)

local espGui = Instance.new("ScreenGui")
espGui.Name = "ESPGui"
espGui.ResetOnSpawn = false
espGui.Parent = player.PlayerGui

local function cleanupESP(p)
    if espObjects[p] then
        for _, obj in pairs(espObjects[p]) do
            if obj and obj.Parent then obj:Destroy() end
        end
        espObjects[p] = nil
    end
end

local function getESPObjs(p)
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
        nameTag.TextSize = 11
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

Players.PlayerRemoving:Connect(cleanupESP)

RunService.RenderStepped:Connect(function()
    local all = {}
    for _, p in ipairs(Players:GetPlayers()) do all[p] = true end
    for p in pairs(espObjects) do if not all[p] then cleanupESP(p) end end
    if not espEnabled then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p == player then continue end
        if not p.Character then cleanupESP(p) continue end
        local hrp  = p.Character:FindFirstChild("HumanoidRootPart")
        local head = p.Character:FindFirstChild("Head")
        if not hrp or not head then cleanupESP(p) continue end
        local objs = getESPObjs(p)
        local sp, onScreen = Camera:WorldToViewportPoint(hrp.Position)
        local hp, hOnScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0,0.7,0))
        if not onScreen or not hOnScreen then
            objs.box.Visible = false
            objs.nameTag.Visible = false
            objs.tracer.Visible = false
            continue
        end
        local h = math.abs(sp.Y - hp.Y) * 2.2
        local w = h * 0.55
        local dist = math.floor((rootPart.Position - hrp.Position).Magnitude)
        objs.box.Visible = espBoxes
        objs.box.BorderColor3 = espBoxColor
        objs.box.Size = UDim2.new(0, w, 0, h)
        objs.box.Position = UDim2.new(0, hp.X - w/2, 0, hp.Y)
        objs.nameTag.Visible = espNames or espDistance
        objs.nameTag.TextColor3 = espNameColor
        local txt = espNames and p.Name or ""
        if espDistance then txt = txt .. (espNames and " [" or "[") .. dist .. "m]" end
        objs.nameTag.Text = txt
        objs.nameTag.Size = UDim2.new(0, 200, 0, 16)
        objs.nameTag.Position = UDim2.new(0, hp.X - 100, 0, hp.Y - 20)
        objs.tracer.Visible = espTracers
        objs.tracer.BackgroundColor3 = espTracerColor
        local bx, by = Camera.ViewportSize.X/2, Camera.ViewportSize.Y
        local dx, dy = sp.X - bx, sp.Y - by
        objs.tracer.Size = UDim2.new(0, 2, 0, math.sqrt(dx*dx+dy*dy))
        objs.tracer.Position = UDim2.new(0, bx, 0, by)
        objs.tracer.Rotation = math.deg(math.atan2(dy, dx)) + 90
    end
end)

-- ══════════════════
-- SETTINGS TAB
-- ══════════════════
local settingsPage = makeTabPage("Settings", 700)
settingsPage.CanvasSize = UDim2.new(0, 0, 0, 700)

makeSection(settingsPage, "GUI TOGGLE KEY", 14)
local guiKeyLbl = makeLabel(settingsPage, "Current key: Y", 38)
local guiKeyBtn = makeBtn(settingsPage, "Click to change key", 58)
guiKeyBtn.MouseButton1Click:Connect(function()
    if listeningForGuiKey then return end
    listeningForGuiKey = true
    guiKeyBtn.Text = "Press any key..."
    TweenService:Create(guiKeyBtn, TweenInfo.new(0.15), {BackgroundColor3 = THEME.red}):Play()
    local conn
    conn = UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard then
            guiToggleKey = input.KeyCode
            guiKeyLbl.Text = "Current key: " .. input.KeyCode.Name
            guiKeyBtn.Text = "Click to change key"
            TweenService:Create(guiKeyBtn, TweenInfo.new(0.15), {BackgroundColor3 = THEME.card}):Play()
            listeningForGuiKey = false
            sendNotif("GUI key: " .. input.KeyCode.Name)
            conn:Disconnect()
        end
    end)
end)

makeSection(settingsPage, "OPEN ANIMATION", 108)
makeTargetBtns(settingsPage, 132, {"Back","Bounce","Elastic","Quad","Sine"}, "Quad", function(opt)
    currentOpenStyle = opt
    sendNotif("Open: " .. opt)
end)

makeSection(settingsPage, "CLOSE ANIMATION", 178)
makeTargetBtns(settingsPage, 202, {"Back","Bounce","Elastic","Quad","Sine"}, "Quad", function(opt)
    currentCloseStyle = opt
    sendNotif("Close: " .. opt)
end)

makeSection(settingsPage, "SPEED", 248)
makeSlider(settingsPage, 272, "Open speed (x10)", 1, 20, 3, function(val)
    openSpeedVal = val / 10
end)
makeSlider(settingsPage, 324, "Close speed (x10)", 1, 20, 2, function(val)
    closeSpeedVal = val / 10
end)

makeSection(settingsPage, "SAVE / LOAD", 378)
local saveStatusLbl = makeLabel(settingsPage, "No save found", 402)
local saveBtn = makeBtn(settingsPage, "Save Settings", 422)
local loadBtn = makeBtn(settingsPage, "Load Settings", 466)

local function saveSettings()
    local ok = pcall(function()
        local data = {
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
        writefile("IkesScript_settings.json", HttpService:JSONEncode(data))
    end)
    saveStatusLbl.Text = ok and "Saved!" or "Save failed"
    sendNotif(ok and "Settings saved" or "Save failed", ok and THEME.green or THEME.red)
end

local function loadSettings()
    local ok = pcall(function()
        local data = HttpService:JSONDecode(readfile("IkesScript_settings.json"))
        if data.walkSpeed then currentSpeed = data.walkSpeed humanoid.WalkSpeed = currentSpeed end
        if data.flySpeed then flySpeedVal = data.flySpeed end
        if data.aimbotFOV then aimbotFOV = data.aimbotFOV end
        if data.aimbotSmoothing then aimbotSmoothing = data.aimbotSmoothing end
        if data.aimbotTarget then aimbotTarget = data.aimbotTarget end
        if data.aimbotHoldMode ~= nil then aimbotHoldMode = data.aimbotHoldMode end
        if data.aimbotKey then pcall(function() aimbotKey = Enum.KeyCode[data.aimbotKey] end) end
        if data.lockIndicator then lockIndicatorType = data.lockIndicator end
        if data.guiKey then
            pcall(function()
                guiToggleKey = Enum.KeyCode[data.guiKey]
                guiKeyLbl.Text = "Current key: " .. data.guiKey
            end)
        end
        if data.openStyle then currentOpenStyle = data.openStyle end
        if data.closeStyle then currentCloseStyle = data.closeStyle end
    end)
    saveStatusLbl.Text = ok and "Loaded!" or "No save found"
    sendNotif(ok and "Settings loaded" or "No save found", ok and THEME.green or THEME.red)
end

saveBtn.MouseButton1Click:Connect(saveSettings)
loadBtn.MouseButton1Click:Connect(loadSettings)

-- ══════════════════
-- PERSONALIZE TAB
-- ══════════════════
local personalizePage = makeTabPage("Personalize", 600)
makeSection(personalizePage, "ACCENT COLOR", 14)
makeColorPicker(personalizePage, "Changes buttons, sliders, toggles", 38, function(c)
    THEME.accent = c
    THEME.toggleOn = c
    sendNotif("Accent changed")
end)

makeSection(personalizePage, "BACKGROUND COLOR", 90)
makeColorPicker(personalizePage, "Main background", 114, function(c)
    THEME.bg = c
    TweenService:Create(frame, TweenInfo.new(0.2), {BackgroundColor3 = c}):Play()
    sendNotif("Background changed")
end)

makeSection(personalizePage, "CARD COLOR", 166)
makeColorPicker(personalizePage, "Row and card backgrounds", 190, function(c)
    THEME.card = c
    sendNotif("Card color changed")
end)

makeSection(personalizePage, "TEXT COLOR", 242)
makeColorPicker(personalizePage, "Main text color", 266, function(c)
    THEME.text = c
    titleLabel.TextColor3 = c
    sendNotif("Text color changed")
end)

makeSection(personalizePage, "PANEL COLOR", 318)
makeColorPicker(personalizePage, "Title bar and tab bar", 342, function(c)
    THEME.panel = c
    titleBar.BackgroundColor3 = c
    titleFix.BackgroundColor3 = c
    sendNotif("Panel color changed")
end)

makeSection(personalizePage, "BORDER COLOR", 394)
makeColorPicker(personalizePage, "Outlines and dividers", 418, function(c)
    THEME.border = c
    frameBorder.Color = c
    divider.BackgroundColor3 = c
    sendNotif("Border color changed")
end)

-- ══════════════════
-- TOGGLE BUTTON + ANIM
-- ══════════════════
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 110, 0, 28)
toggleBtn.Position = UDim2.new(0.5, -55, 0, 8)
toggleBtn.BackgroundColor3 = THEME.panel
toggleBtn.TextColor3 = THEME.subtext
toggleBtn.Text = "Ike's Script"
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 11
toggleBtn.BorderSizePixel = 0
toggleBtn.ZIndex = 10
toggleBtn.Parent = screenGui
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 6)
local tgs = Instance.new("UIStroke")
tgs.Color = THEME.border
tgs.Thickness = 1
tgs.Parent = toggleBtn

function openGui()
    guiOpen = true
    frame.Visible = true
    frame.Size = UDim2.new(0, 380, 0, 0)
    frame.BackgroundTransparency = 1
    local style = Enum.EasingStyle[currentOpenStyle] or Enum.EasingStyle.Quint
    TweenService:Create(frame, TweenInfo.new(openSpeedVal, style, Enum.EasingDirection.Out),
        {Size = UDim2.new(0, 380, 0, 480), BackgroundTransparency = 0}):Play()
    toggleBtn.Text = "Close"
    toggleBtn.TextColor3 = THEME.text
end

function closeGui()
    guiOpen = false
    local style = Enum.EasingStyle[currentCloseStyle] or Enum.EasingStyle.Quint
    local t = TweenService:Create(frame, TweenInfo.new(closeSpeedVal, style, Enum.EasingDirection.In),
        {Size = UDim2.new(0, 380, 0, 0), BackgroundTransparency = 1})
    t:Play()
    t.Completed:Connect(function() frame.Visible = false end)
    toggleBtn.Text = "Ike's Script"
    toggleBtn.TextColor3 = THEME.subtext
end

frame.Visible = false
switchTab("Misc")
openGui()

toggleBtn.MouseButton1Click:Connect(function()
    if guiOpen then closeGui() else openGui() end
end)

sendNotif("Ike's Script loaded!", THEME.accent)
