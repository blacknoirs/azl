local Library = {}
local TS = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local HS = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local Players = game:GetService("Players")

Library.IsMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled
Library.Guis = {}
Library.Connections = {}

local ConfigSystem = {
    FolderName = "rubyazl",
    CurrentConfig = "default",
    Configs = {},
    Elements = {}
}

local function saveConfig(configName)
    configName = configName or ConfigSystem.CurrentConfig
    if not writefile then
        return false
    end

    local success = pcall(function()
        if not isfolder(ConfigSystem.FolderName) then
            makefolder(ConfigSystem.FolderName)
        end

        local configData = {
            version = 1,
            timestamp = os.time(),
            elements = {}
        }

        for path, element in pairs(ConfigSystem.Elements) do
            if element.GetValue then
                local ok, value = pcall(function() return element:GetValue() end)
                if ok then
                    configData.elements[path] = value
                end
            end
        end

        local configPath = ConfigSystem.FolderName .. "/" .. configName .. ".json"
        writefile(configPath, HS:JSONEncode(configData))
    end)

    return success
end

local function loadConfig(configName)
    configName = configName or ConfigSystem.CurrentConfig
    if not (readfile and isfile) then
        return false
    end

    local configPath = ConfigSystem.FolderName .. "/" .. configName .. ".json"
    if not isfile(configPath) then
        return false
    end

    local success = pcall(function()
        local fileContent = readfile(configPath)
        local configData = HS:JSONDecode(fileContent)

        ConfigSystem.CurrentConfig = configName

        for path, value in pairs(configData.elements or {}) do
            local element = ConfigSystem.Elements[path]
            if element and element.SetValue then
                pcall(function() element:SetValue(value, true) end)
            end
        end
    end)

    return success
end

local function deleteConfig(configName)
    if not (delfile and isfile) then return false end

    local configPath = ConfigSystem.FolderName .. "/" .. configName .. ".json"
    if not isfile(configPath) then return false end

    return (pcall(function() delfile(configPath) end))
end

local function listConfigs()
    if not listfiles then return {} end

    local configList = {}
    local success, files = pcall(function()
        return listfiles(ConfigSystem.FolderName)
    end)

    if success and files then
        for _, file in pairs(files) do
            if file:sub(-5) == ".json" then
                local configName = file:match(".*[/\\](.+)%.json")
                if configName then
                    table.insert(configList, configName)
                end
            end
        end
    end

    return configList
end

local saveQueued = false
local function autoSave()
    if not ConfigSystem.AutoSave then return end
    if saveQueued then return end
    saveQueued = true
    task.delay(0.6, function()
        saveQueued = false
        saveConfig(ConfigSystem.CurrentConfig)
    end)
end

ConfigSystem.Save = saveConfig
ConfigSystem.Load = loadConfig
ConfigSystem.Delete = deleteConfig
ConfigSystem.List = listConfigs
ConfigSystem.AutoSave = true

Library.ConfigSystem = ConfigSystem

Library.NotificationSounds = {
    Enabled = false,
    Sounds = {},
    URLs = {
        Enable = "https://file.garden/ae9fcAfELjoYT26a/Function_ON.wav",
        Disable = "https://file.garden/ae9fcAfELjoYT26a/Function_OFF.wav"
    }
}

function Library:LoadNotificationSounds()
    if Library.NotificationSounds.Enabled then return end

    task.spawn(function()
        for soundName, url in pairs(Library.NotificationSounds.URLs) do
            pcall(function()
                local filename = "rubyazl_notif_" .. soundName:lower() .. ".wav"

                local success, data = pcall(function()
                    return game:HttpGet(url, true)
                end)

                if not success or not data then return end
                if not writefile then return end

                writefile(filename, data)

                local getasset = getcustomasset or getsynasset
                if not getasset then return end

                local sound = Instance.new("Sound")
                local assetId = getasset(filename)

                if not assetId or assetId == "" then return end

                sound.SoundId = assetId
                sound.Volume = 0.5
                sound.Parent = game:GetService("SoundService")

                Library.NotificationSounds.Sounds[soundName] = sound
            end)
        end

        Library.NotificationSounds.Enabled = true
    end)
end

function Library:PlayNotificationSound(soundType)
    if not Library.NotificationSounds.Enabled then return end
    if Library.NotificationSoundsUserEnabled == false then return end

    local sound = Library.NotificationSounds.Sounds[soundType]
    if sound then
        pcall(function()
            if Library.NotificationSoundVolume then
                sound.Volume = Library.NotificationSoundVolume
            end
            sound:Play()
        end)
    end
end

local C = {
    BG = Color3.fromRGB(11, 11, 15),
    TopBar = Color3.fromRGB(14, 14, 19),
    Sidebar = Color3.fromRGB(13, 13, 18),
    Section = Color3.fromRGB(18, 18, 25),
    Element = Color3.fromRGB(26, 26, 35),
    ElementHover = Color3.fromRGB(34, 34, 46),
    Accent = Color3.fromHex("7C8CFF"),
    Text = Color3.fromRGB(228, 229, 238),
    TextDim = Color3.fromRGB(122, 124, 144),
    Border = Color3.fromRGB(36, 36, 48),
    SliderBg = Color3.fromRGB(38, 38, 50),
    Chip = Color3.fromRGB(33, 33, 44)
}

Library.AccentElements = {}
Library.AccentTextElements = {}
Library.AccentImages = {}
Library.BorderGradients = {}
Library.Colors = C

local function buildBorderSequence(accent)
    return ColorSequence.new({
        ColorSequenceKeypoint.new(0, C.Border),
        ColorSequenceKeypoint.new(0.25, accent),
        ColorSequenceKeypoint.new(0.5, C.Border),
        ColorSequenceKeypoint.new(0.75, accent),
        ColorSequenceKeypoint.new(1, C.Border)
    })
end

local function New(c, p)
    local o = Instance.new(c)
    for k, v in pairs(p) do o[k] = v end
    return o
end

local function Tween(o, p, t, s)
    s = s or Enum.EasingStyle.Quart
    TS:Create(o, TweenInfo.new(t or 0.2, s, Enum.EasingDirection.Out), p):Play()
end

local function Corner(parent, radius)
    return New("UICorner", { Parent = parent, CornerRadius = UDim.new(0, radius) })
end

local function mount(gui)
    if syn and syn.protect_gui then
        pcall(function() syn.protect_gui(gui) end)
        gui.Parent = game:GetService("CoreGui")
    elseif gethui then
        gui.Parent = gethui()
    else
        gui.Parent = game:GetService("CoreGui")
    end
    table.insert(Library.Guis, gui)
end

local function bind(signal, fn)
    local c = signal:Connect(fn)
    table.insert(Library.Connections, c)
    return c
end

local function keyName(key)
    if not key then return "None" end
    local n = key.Name
    if n:match("MouseButton") then n = n:gsub("MouseButton", "M") end
    return n
end

local function pathFor(section, name)
    return section.Category.TopTab.Name .. "_" .. section.Category.Name .. "_" .. section.Name .. "_" .. name
end

local function register(name, section, frame)
    task.spawn(function()
        task.wait(0.1)
        local w = Library.Windows and Library.Windows[1]
        if w and w.RegisterElement then
            w:RegisterElement(name, section.Category.TopTab.Name, section.Category.Name, frame, section.Frame,
                section.Column)
        end
    end)
end

local function closePickers()
    if Library.ColorPickers then
        for _, picker in pairs(Library.ColorPickers) do
            if picker.Close then picker:Close() end
        end
    end
end

local function makeLetters(parent, text, step, textSize)
    local letters = {}
    for i = 1, #text do
        local letter = New("TextLabel", {
            Parent = parent,
            Position = UDim2.new(0, (i - 1) * step, 0, 0),
            Size = UDim2.new(0, step, 1, 0),
            BackgroundTransparency = 1,
            Text = text:sub(i, i),
            TextColor3 = C.Accent,
            TextSize = textSize,
            TextXAlignment = Enum.TextXAlignment.Center,
            Font = Enum.Font.Code
        })
        table.insert(letters, letter)
    end

    task.spawn(function()
        while parent and parent.Parent do
            for _, letter in ipairs(letters) do
                if not letter.Parent then return end
                task.spawn(function()
                    local h, s, v = C.Accent:ToHSV()
                    local glow = Color3.fromHSV(h, math.max(s - 0.2, 0), math.min(v + 0.3, 1))
                    Tween(letter, { TextColor3 = glow }, 0.3, Enum.EasingStyle.Sine)
                    task.wait(0.3)
                    Tween(letter, { TextColor3 = C.Accent }, 0.4, Enum.EasingStyle.Sine)
                end)
                task.wait(0.08)
            end
            task.wait(1.5)
        end
    end)

    return letters
end

local iconCache = {}

local function resolveIcon(icon)
    if icon == nil or icon == "" then return nil end
    if iconCache[icon] then return iconCache[icon] end

    local result = nil

    if typeof(icon) == "number" then
        result = "rbxassetid://" .. tostring(icon)
    elseif typeof(icon) == "string" then
        if icon:match("^%d+$") then
            result = "rbxassetid://" .. icon
        elseif icon:match("^rbxassetid://") or icon:match("^rbxasset://") or icon:match("^rbxthumb://") or
            icon:match("^rbxgameasset://") or icon:match("^https?://www%.roblox%.com/asset") then
            result = icon
        elseif icon:match("^https?://") then
            local getasset = getcustomasset or getsynasset
            if writefile and getasset then
                pcall(function()
                    local hash = 0
                    for i = 1, #icon do
                        hash = (hash * 31 + icon:byte(i)) % 4294967296
                    end

                    if isfolder and makefolder and not isfolder(ConfigSystem.FolderName) then
                        makefolder(ConfigSystem.FolderName)
                    end

                    local cachePath = ConfigSystem.FolderName .. "/icon_" .. tostring(hash) .. ".png"

                    if not (isfile and isfile(cachePath)) then
                        local data = game:HttpGet(icon, true)
                        if data and #data > 0 then
                            writefile(cachePath, data)
                        end
                    end

                    if isfile and isfile(cachePath) then
                        result = getasset(cachePath)
                    end
                end)
            end
        else
            local getasset = getcustomasset or getsynasset
            if isfile and getasset then
                pcall(function()
                    if isfile(icon) then
                        result = getasset(icon)
                    end
                end)
            end
            if not result then
                result = icon
            end
        end
    end

    if result and result ~= "" then
        iconCache[icon] = result
    end

    return result
end

Library.ResolveIcon = resolveIcon

local function setImageAsync(imageLabel, icon)
    task.spawn(function()
        local resolved = resolveIcon(icon)
        if resolved and imageLabel and imageLabel.Parent then
            imageLabel.Image = resolved
        end
    end)
end

local function applyImageTint(img, tint)
    for i = #Library.AccentImages, 1, -1 do
        if Library.AccentImages[i] == img then
            table.remove(Library.AccentImages, i)
        end
    end

    if tint == true then
        img.ImageColor3 = C.Accent
        table.insert(Library.AccentImages, img)
    elseif typeof(tint) == "Color3" then
        img.ImageColor3 = tint
    else
        img.ImageColor3 = Color3.new(1, 1, 1)
    end
end

local function richBuild(accent)
    return string.format('build: <font color="rgb(%d,%d,%d)">alpha</font>',
        math.floor(accent.R * 255), math.floor(accent.G * 255), math.floor(accent.B * 255))
end

local function richUser(accent, name)
    return string.format('user: <font color="rgb(%d,%d,%d)">%s</font>',
        math.floor(accent.R * 255), math.floor(accent.G * 255), math.floor(accent.B * 255), name)
end

function Library:UpdateAccentColor(newColor)
    C.Accent = newColor

    for _, element in pairs(Library.AccentElements) do
        if element and element.Parent then
            if element:IsA("UIStroke") then
                element.Color = newColor
            else
                element.BackgroundColor3 = newColor
            end
        end
    end

    for _, element in pairs(Library.AccentTextElements) do
        if element and element.Parent then
            element.TextColor3 = newColor
        end
    end

    for _, element in pairs(Library.AccentImages) do
        if element and element.Parent then
            element.ImageColor3 = newColor
        end
    end

    for _, grad in pairs(Library.BorderGradients) do
        if grad and grad.Parent then
            grad.Color = buildBorderSequence(newColor)
        end
    end

    if Library.Windows then
        for _, window in pairs(Library.Windows) do
            if window.CurrentCategory and window.CurrentCategory.Button then
                window.CurrentCategory.Button.TextColor3 = newColor
                if window.CurrentCategory.Icon and window.CurrentCategory.Icon.Parent then
                    window.CurrentCategory.Icon.ImageColor3 = newColor
                end
            end

            if window.TitleLetters then
                for _, letter in pairs(window.TitleLetters) do
                    if letter and letter.Parent then
                        letter.TextColor3 = newColor
                    end
                end
            end

            if window.Watermark then
                if window.Watermark.Letters then
                    for _, letter in pairs(window.Watermark.Letters) do
                        if letter and letter.Parent then
                            letter.TextColor3 = newColor
                        end
                    end
                end

                if window.Watermark.TextElements then
                    for _, element in pairs(window.Watermark.TextElements) do
                        if element and element.Parent then
                            element.TextColor3 = newColor
                        end
                    end
                end
            end

            if window.BuildLabel and window.BuildLabel.Parent then
                window.BuildLabel.Text = richBuild(newColor)
            end
            if window.UserLabel and window.UserLabel.Parent and window.PlayerName then
                window.UserLabel.Text = richUser(newColor, window.PlayerName)
            end
        end
    end

    if Library.KeybindsWindow then
        if Library.KeybindsWindow.HeaderLetters then
            for _, letter in pairs(Library.KeybindsWindow.HeaderLetters) do
                if letter and letter.Parent then
                    letter.TextColor3 = newColor
                end
            end
        end

        if Library.KeybindsWindow.Items then
            for _, item in pairs(Library.KeybindsWindow.Items) do
                if item.KeyLabel and item.KeyLabel.Parent then
                    item.KeyLabel.TextColor3 = newColor
                end
            end
        end
    end
end

function Library:SetIcon(icon, tint)
    if Library.Windows then
        for _, window in pairs(Library.Windows) do
            if window.SetIcon then
                window:SetIcon(icon, tint)
            end
        end
    end
end

local TooltipGui, TooltipFrame, TooltipLabel
local tooltipToken = 0
local tooltipConn = nil

local function ensureTooltip()
    if TooltipGui and TooltipGui.Parent then return end

    TooltipGui = New("ScreenGui", {
        Name = "rubyazlTooltip",
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 1000
    })
    mount(TooltipGui)

    TooltipFrame = New("Frame", {
        Parent = TooltipGui,
        Size = UDim2.fromOffset(10, 24),
        BackgroundColor3 = Color3.fromRGB(20, 20, 27),
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 50
    })
    Corner(TooltipFrame, 7)
    New("UIStroke", { Parent = TooltipFrame, Color = C.Border, Thickness = 1, Transparency = 0.1 })

    TooltipLabel = New("TextLabel", {
        Parent = TooltipFrame,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -20, 1, 0),
        BackgroundTransparency = 1,
        TextColor3 = C.Text,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 51
    })
end

local function hideTooltip()
    tooltipToken = tooltipToken + 1
    if tooltipConn then
        tooltipConn:Disconnect()
        tooltipConn = nil
    end
    if TooltipFrame then
        TooltipFrame.Visible = false
    end
end

function Library:HideTooltip()
    hideTooltip()
end

local function placeTooltip()
    if not TooltipFrame then return end
    local m = UIS:GetMouseLocation()
    local cam = workspace.CurrentCamera
    local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)
    local sz = TooltipFrame.AbsoluteSize
    local x = math.min(m.X + 14, vp.X - sz.X - 6)
    local y = math.min(m.Y + 18, vp.Y - sz.Y - 6)
    TooltipFrame.Position = UDim2.fromOffset(x, y)
end

function Library:AttachTooltip(guiObject, text)
    if not guiObject or not text or text == "" or Library.IsMobile then return end

    guiObject.MouseEnter:Connect(function()
        tooltipToken = tooltipToken + 1
        local mine = tooltipToken
        task.delay(0.4, function()
            if mine ~= tooltipToken then return end
            ensureTooltip()
            local size = TextService:GetTextSize(text, 12, Enum.Font.Gotham, Vector2.new(260, 1000))
            TooltipLabel.Text = text
            TooltipFrame.Size = UDim2.fromOffset(size.X + 20, size.Y + 14)
            placeTooltip()
            TooltipFrame.Visible = true
            if tooltipConn then tooltipConn:Disconnect() end
            tooltipConn = RS.RenderStepped:Connect(placeTooltip)
        end)
    end)

    guiObject.MouseLeave:Connect(hideTooltip)
end

local function openModeMenu(anchor, getMode, setMode, onClosed)
    local ModeGui = New("ScreenGui", {
        Name = "KeybindModeSelector",
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false
    })
    mount(ModeGui)

    local ModeFrame = New("Frame", {
        Parent = ModeGui,
        Size = UDim2.fromOffset(80, 58),
        BackgroundColor3 = C.Element,
        BackgroundTransparency = 1,
        BorderSizePixel = 0
    })
    Corner(ModeFrame, 8)
    local frameStroke = New("UIStroke", { Parent = ModeFrame, Color = C.Accent, Thickness = 1, Transparency = 1 })

    local p = anchor.AbsolutePosition
    ModeFrame.Position = UDim2.fromOffset(p.X - 10, p.Y + anchor.AbsoluteSize.Y + 4)

    Tween(ModeFrame, { BackgroundTransparency = 0 }, 0.2, Enum.EasingStyle.Sine)
    Tween(frameStroke, { Transparency = 0.5 }, 0.2, Enum.EasingStyle.Sine)

    local closed = false
    local outsideConn
    local buttons = {}

    local function closeMenu()
        if closed then return end
        closed = true
        if outsideConn then outsideConn:Disconnect() end

        Tween(ModeFrame, { BackgroundTransparency = 1 }, 0.15, Enum.EasingStyle.Sine)
        Tween(frameStroke, { Transparency = 1 }, 0.15, Enum.EasingStyle.Sine)
        for _, b in pairs(buttons) do
            Tween(b, { BackgroundTransparency = 1, TextTransparency = 1 }, 0.15, Enum.EasingStyle.Sine)
        end

        if Library.ModeMenus then
            for i = #Library.ModeMenus, 1, -1 do
                if Library.ModeMenus[i].gui == ModeGui then
                    table.remove(Library.ModeMenus, i)
                    break
                end
            end
        end

        task.delay(0.16, function()
            ModeGui:Destroy()
            if onClosed then onClosed() end
        end)
    end

    for i, m in ipairs({ "Toggle", "Hold" }) do
        local b = New("TextButton", {
            Parent = ModeFrame,
            Position = UDim2.new(0, 4, 0, 4 + (i - 1) * 26),
            Size = UDim2.new(1, -8, 0, 22),
            BackgroundColor3 = getMode() == m and C.Accent or C.Section,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Text = m,
            TextColor3 = C.Text,
            TextTransparency = 1,
            TextSize = 12,
            Font = Enum.Font.GothamMedium,
            AutoButtonColor = false
        })
        Corner(b, 5)
        table.insert(buttons, b)
        Tween(b, { BackgroundTransparency = 0, TextTransparency = 0 }, 0.2, Enum.EasingStyle.Sine)

        b.MouseButton1Click:Connect(function()
            setMode(m)
            closeMenu()
        end)
        b.MouseEnter:Connect(function()
            if getMode() ~= m then Tween(b, { BackgroundColor3 = C.ElementHover }, 0.12) end
        end)
        b.MouseLeave:Connect(function()
            if getMode() ~= m then Tween(b, { BackgroundColor3 = C.Section }, 0.12) end
        end)
    end

    outsideConn = UIS.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local mp = Vector2.new(input.Position.X, input.Position.Y)
            local fp = ModeFrame.AbsolutePosition
            local fs = ModeFrame.AbsoluteSize
            if mp.X < fp.X or mp.X > fp.X + fs.X or mp.Y < fp.Y or mp.Y > fp.Y + fs.Y then
                closeMenu()
            end
        end
    end)

    if not Library.ModeMenus then Library.ModeMenus = {} end
    table.insert(Library.ModeMenus, { gui = ModeGui, close = closeMenu })
end

function Library:CreateWindow(config)
    config = config or {}

    local SG = New("ScreenGui", {
        Name = "rubyazlUI",
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false
    })
    mount(SG)

    local Backdrop = New("Frame", {
        Name = "Backdrop",
        Parent = SG,
        Position = UDim2.new(0, -100, 0, -100),
        Size = UDim2.new(1, 200, 1, 200),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 0
    })

    local backdropHideThread = nil
    local mainHideThread = nil

    local Main = New("CanvasGroup", {
        Name = "Main",
        Parent = SG,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.fromOffset(760, 480),
        BackgroundColor3 = C.BG,
        BorderSizePixel = 0,
        GroupTransparency = 1
    })
    Corner(Main, 14)

    local MainStroke = New("UIStroke", {
        Parent = Main,
        Color = Color3.new(1, 1, 1),
        Thickness = 1.5,
        Transparency = 0.05
    })

    local MainStrokeGradient = New("UIGradient", {
        Parent = MainStroke,
        Color = buildBorderSequence(C.Accent),
        Rotation = 0
    })
    table.insert(Library.BorderGradients, MainStrokeGradient)

    local MainUIScale = New("UIScale", { Parent = Main, Scale = 1 })

    local Rail = New("Frame", {
        Name = "Rail",
        Parent = Main,
        Size = UDim2.new(0, 68, 1, 0),
        BackgroundColor3 = C.Sidebar,
        BorderSizePixel = 0,
        ZIndex = 3
    })

    New("Frame", {
        Name = "RailLine",
        Parent = Rail,
        Position = UDim2.new(1, -1, 0, 0),
        Size = UDim2.new(0, 1, 1, 0),
        BackgroundColor3 = C.Border,
        BorderSizePixel = 0
    })

    local LogoMark = New("Frame", {
        Name = "LogoMark",
        Parent = Rail,
        Position = UDim2.new(0, 17, 0, 14),
        Size = UDim2.fromOffset(34, 34),
        BackgroundColor3 = C.Accent,
        BorderSizePixel = 0
    })
    Corner(LogoMark, 10)

    local LogoMarkDot = New("Frame", {
        Parent = LogoMark,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.fromOffset(12, 12),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0
    })
    Corner(LogoMarkDot, 99)

    local LogoImage = New("ImageLabel", {
        Name = "LogoImage",
        Parent = LogoMark,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScaleType = Enum.ScaleType.Fit,
        Image = "",
        Visible = false
    })

    table.insert(Library.AccentElements, LogoMark)

    local TopTabs = New("ScrollingFrame", {
        Name = "TopTabs",
        Parent = Rail,
        Position = UDim2.new(0, 0, 0, 66),
        Size = UDim2.new(1, -1, 1, -122),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y
    })

    New("UIListLayout", {
        Parent = TopTabs,
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        Padding = UDim.new(0, 6)
    })
    New("UIPadding", { Parent = TopTabs, PaddingTop = UDim.new(0, 4) })

    local Players_ = Players
    local playerName = Players_.LocalPlayer and Players_.LocalPlayer.Name or "Unknown"

    local Avatar = New("ImageLabel", {
        Name = "Avatar",
        Parent = Rail,
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -14),
        Size = UDim2.fromOffset(36, 36),
        BackgroundColor3 = C.Chip,
        BorderSizePixel = 0,
        Image = "",
        ScaleType = Enum.ScaleType.Crop
    })
    Corner(Avatar, 99)
    New("UIStroke", { Parent = Avatar, Color = C.Accent, Thickness = 1.5, Transparency = 0.4 })

    pcall(function()
        if Players_.LocalPlayer then
            Avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(Players_.LocalPlayer.UserId) ..
                "&w=150&h=150"
        end
    end)

    local Body = New("Frame", {
        Name = "Body",
        Parent = Main,
        Position = UDim2.new(0, 68, 0, 0),
        Size = UDim2.new(1, -68, 1, 0),
        BackgroundTransparency = 1
    })

    local TopBar = New("Frame", {
        Name = "TopBar",
        Parent = Body,
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundColor3 = C.TopBar,
        BorderSizePixel = 0,
        ZIndex = 6
    })

    New("Frame", {
        Name = "TopBarLine",
        Parent = TopBar,
        Position = UDim2.new(0, 0, 1, -1),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = C.Border,
        BorderSizePixel = 0
    })

    local TopAccentLine = New("Frame", {
        Name = "AccentLine",
        Parent = TopBar,
        Position = UDim2.new(0, 16, 1, -2),
        Size = UDim2.new(1, -32, 0, 2),
        BackgroundColor3 = C.Accent,
        BorderSizePixel = 0
    })

    local TopAccentGradient = New("UIGradient", {
        Parent = TopAccentLine,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.5, 0.15),
            NumberSequenceKeypoint.new(1, 1)
        })
    })

    table.insert(Library.AccentElements, TopAccentLine)

    bind(RS.Heartbeat, function(dt)
        if Main.Visible then
            MainStrokeGradient.Rotation = (MainStrokeGradient.Rotation + dt * 50) % 360
            TopAccentGradient.Offset = Vector2.new(math.sin(os.clock() * 1.2) * 0.25, 0)
        end
    end)

    local logoText = config.Title or "ReEvolution"

    local LogoContainer = New("Frame", {
        Name = "TitleLetters",
        Parent = TopBar,
        Position = UDim2.new(0, 18, 0, 7),
        Size = UDim2.new(0, #logoText * 10, 0, 18),
        BackgroundTransparency = 1
    })

    local titleLetters = makeLetters(LogoContainer, logoText, 10, 16)

    local TabTitle = New("TextLabel", {
        Name = "TabTitle",
        Parent = TopBar,
        Position = UDim2.new(0, 18, 0, 26),
        Size = UDim2.new(0, 200, 0, 14),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = C.TextDim,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    local CloseBtn = New("TextButton", {
        Name = "CloseButton",
        Parent = TopBar,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(26, 26),
        BackgroundColor3 = Color3.fromRGB(70, 28, 38),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "X",
        TextColor3 = C.TextDim,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false
    })
    Corner(CloseBtn, 8)

    CloseBtn.MouseEnter:Connect(function()
        Tween(CloseBtn, { BackgroundTransparency = 0, TextColor3 = Color3.fromRGB(255, 120, 135) }, 0.15,
            Enum.EasingStyle.Sine)
    end)

    CloseBtn.MouseLeave:Connect(function()
        Tween(CloseBtn, { BackgroundTransparency = 1, TextColor3 = C.TextDim }, 0.15, Enum.EasingStyle.Sine)
    end)

    local SearchContainer = New("Frame", {
        Name = "SearchContainer",
        Parent = TopBar,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -48, 0.5, 0),
        Size = UDim2.new(0, 190, 0, 28),
        BackgroundColor3 = C.Element,
        BorderSizePixel = 0
    })
    Corner(SearchContainer, 14)

    local SearchStroke = New("UIStroke", {
        Parent = SearchContainer,
        Color = C.Accent,
        Thickness = 1,
        Transparency = 0.75
    })
    table.insert(Library.AccentElements, SearchStroke)

    New("TextLabel", {
        Name = "SearchIcon",
        Parent = SearchContainer,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(0, 16, 1, 0),
        BackgroundTransparency = 1,
        Text = "🔍",
        TextColor3 = C.TextDim,
        TextSize = 12,
        Font = Enum.Font.Gotham
    })

    local SearchBox = New("TextBox", {
        Name = "SearchBox",
        Parent = SearchContainer,
        Position = UDim2.new(0, 32, 0, 0),
        Size = UDim2.new(1, -40, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        PlaceholderText = "Search features...",
        PlaceholderColor3 = C.TextDim,
        TextColor3 = C.Text,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false
    })

    local SearchResults = New("Frame", {
        Name = "SearchResults",
        Parent = SearchContainer,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 1, 6),
        Size = UDim2.new(0, 250, 0, 0),
        BackgroundColor3 = C.Element,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 10
    })
    Corner(SearchResults, 10)
    New("UIStroke", { Parent = SearchResults, Color = C.Accent, Thickness = 1, Transparency = 0.6 })

    local ResultsList = New("ScrollingFrame", {
        Name = "ResultsList",
        Parent = SearchResults,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = C.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ZIndex = 10
    })

    New("UIListLayout", {
        Parent = ResultsList,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2)
    })

    New("UIPadding", {
        Parent = ResultsList,
        PaddingTop = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 4),
        PaddingLeft = UDim.new(0, 4),
        PaddingRight = UDim.new(0, 4)
    })

    SearchContainer.MouseEnter:Connect(function()
        Tween(SearchContainer, { BackgroundColor3 = C.ElementHover }, 0.15)
        Tween(SearchStroke, { Transparency = 0.35 }, 0.15)
    end)

    SearchContainer.MouseLeave:Connect(function()
        if not SearchBox:IsFocused() then
            Tween(SearchContainer, { BackgroundColor3 = C.Element }, 0.15)
            Tween(SearchStroke, { Transparency = 0.75 }, 0.15)
        end
    end)

    SearchBox.Focused:Connect(function()
        Tween(SearchContainer, { BackgroundColor3 = C.ElementHover }, 0.15)
        Tween(SearchStroke, { Transparency = 0.2 }, 0.15)
    end)

    SearchBox.FocusLost:Connect(function()
        task.wait(0.1)
        SearchResults.Visible = false
        Tween(SearchContainer, { BackgroundColor3 = C.Element }, 0.15)
        Tween(SearchStroke, { Transparency = 0.75 }, 0.15)
    end)

    local CatStrip = New("Frame", {
        Name = "CategoryStrip",
        Parent = Body,
        Position = UDim2.new(0, 0, 0, 48),
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = C.BG,
        BorderSizePixel = 0,
        ZIndex = 4
    })

    New("Frame", {
        Name = "CatLine",
        Parent = CatStrip,
        Position = UDim2.new(0, 0, 1, -1),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = C.Border,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0
    })

    local CatList = New("ScrollingFrame", {
        Name = "List",
        Parent = CatStrip,
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(1, -28, 1, -1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 0,
        ScrollingDirection = Enum.ScrollingDirection.X,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.X
    })

    New("UIListLayout", {
        Parent = CatList,
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 6)
    })

    local Content = New("Frame", {
        Name = "Content",
        Parent = Body,
        Position = UDim2.new(0, 0, 0, 88),
        Size = UDim2.new(1, 0, 1, -114),
        BackgroundTransparency = 1,
        BorderSizePixel = 0
    })

    local ContentScroll = New("ScrollingFrame", {
        Name = "ContentScroll",
        Parent = Content,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = C.Accent,
        ScrollBarImageTransparency = 0.3,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y
    })

    local LeftColumn = New("Frame", {
        Name = "LeftColumn",
        Parent = ContentScroll,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(0.5, -6, 0, 0),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y
    })

    New("UIListLayout", {
        Parent = LeftColumn,
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 12)
    })

    local RightColumn = New("Frame", {
        Name = "RightColumn",
        Parent = ContentScroll,
        Position = UDim2.new(0.5, 6, 0, 0),
        Size = UDim2.new(0.5, -6, 0, 0),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y
    })

    New("UIListLayout", {
        Parent = RightColumn,
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 12)
    })

    New("UIPadding", {
        Parent = ContentScroll,
        PaddingTop = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 14),
        PaddingRight = UDim.new(0, 14),
        PaddingBottom = UDim.new(0, 12)
    })

    local Footer = New("Frame", {
        Name = "Footer",
        Parent = Body,
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 26),
        BackgroundColor3 = C.TopBar,
        BorderSizePixel = 0,
        ZIndex = 4
    })

    New("Frame", {
        Name = "FooterLine",
        Parent = Footer,
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = C.Border,
        BorderSizePixel = 0
    })

    local BuildLabel = New("TextLabel", {
        Name = "Build",
        Parent = Footer,
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(0, 90, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = C.TextDim,
        RichText = true,
        Text = richBuild(C.Accent)
    })

    local UserLabel = New("TextLabel", {
        Name = "User",
        Parent = Footer,
        Position = UDim2.new(0, 108, 0, 0),
        Size = UDim2.new(0, 190, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = C.TextDim,
        TextTruncate = Enum.TextTruncate.AtEnd,
        RichText = true,
        Text = richUser(C.Accent, playerName)
    })

    local toggleKey = config.ToggleKey or Enum.KeyCode.K

    local HintLabel = New("TextLabel", {
        Name = "Hint",
        Parent = Footer,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -14, 0, 0),
        Size = UDim2.new(0, 160, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextColor3 = C.TextDim,
        Text = "[" .. toggleKey.Name .. "] toggle menu"
    })

    local dragging, dragInput, dragStart, startPos

    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    bind(UIS.InputChanged, function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    bind(RS.RenderStepped, function(dt)
        if dragging and dragInput then
            local delta = dragInput.Position - dragStart
            local target = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale,
                startPos.Y.Offset + delta.Y)
            Main.Position = Main.Position:Lerp(target, math.clamp(dt * 22, 0, 1))
        end
    end)

    local W = {
        Main = Main,
        TopTabs = TopTabs,
        Sidebar = CatList,
        Content = ContentScroll,
        LeftColumn = LeftColumn,
        RightColumn = RightColumn,
        CurrentTopTab = nil,
        CurrentCategory = nil,
        TopTabButtons = {},
        Categories = {},
        Visible = false,
        ToggleKey = toggleKey,
        BuildLabel = BuildLabel,
        UserLabel = UserLabel,
        TabTitle = TabTitle,
        TitleLetters = titleLetters,
        PlayerName = playerName,
        BaseScale = 1,
        Icon = nil,
        IconTint = nil
    }

    function W:SetVisible(visible)
        W.Visible = visible

        if mainHideThread then
            pcall(function() task.cancel(mainHideThread) end)
            mainHideThread = nil
        end

        if backdropHideThread then
            pcall(function() task.cancel(backdropHideThread) end)
            backdropHideThread = nil
        end

        if visible then
            Main.Visible = true
            MainUIScale.Scale = W.BaseScale * 0.93
            Tween(MainUIScale, { Scale = W.BaseScale }, 0.5, Enum.EasingStyle.Back)
            Tween(Main, { GroupTransparency = 0 }, 0.3, Enum.EasingStyle.Quad)

            Backdrop.Visible = true
            Backdrop.BackgroundTransparency = 1
            Tween(Backdrop, { BackgroundTransparency = 0.55 }, 0.3, Enum.EasingStyle.Sine)
        else
            Tween(MainUIScale, { Scale = W.BaseScale * 0.95 }, 0.25, Enum.EasingStyle.Quad)
            Tween(Main, { GroupTransparency = 1 }, 0.25, Enum.EasingStyle.Quad)
            Tween(Backdrop, { BackgroundTransparency = 1 }, 0.3, Enum.EasingStyle.Sine)

            mainHideThread = task.spawn(function()
                task.wait(0.26)
                if not W.Visible then
                    Main.Visible = false
                    MainUIScale.Scale = W.BaseScale
                end
                mainHideThread = nil
            end)

            backdropHideThread = task.spawn(function()
                task.wait(0.35)
                if not W.Visible then
                    Backdrop.Visible = false
                end
                backdropHideThread = nil
            end)

            hideTooltip()
            closePickers()

            if Library.ModeMenus then
                for i = #Library.ModeMenus, 1, -1 do
                    local menu = Library.ModeMenus[i]
                    if menu and menu.close then
                        menu.close()
                    elseif menu and menu.gui and menu.gui.Parent then
                        menu.gui:Destroy()
                        table.remove(Library.ModeMenus, i)
                    end
                end
            end
        end
    end

    function W:Toggle()
        W:SetVisible(not W.Visible)
    end

    function W:SetToggleKey(key)
        W.ToggleKey = key
        HintLabel.Text = "[" .. key.Name .. "] toggle menu"
    end

    function W:SetUIScale(scale)
        local scaleValue = math.clamp(scale, 50, 150) / 100
        W.BaseScale = scaleValue
        MainUIScale.Scale = scaleValue
    end

    CloseBtn.MouseButton1Click:Connect(function()
        W:SetVisible(false)
    end)

    function W:SetIcon(icon, tint)
        W.Icon = icon
        if tint ~= nil then
            W.IconTint = tint
        end

        task.spawn(function()
            local img = icon and resolveIcon(icon)

            if not img then
                LogoImage.Visible = false
                LogoImage.Image = ""
                LogoMark.BackgroundTransparency = 0
                LogoMarkDot.Visible = true

                if W.MobileIconImage then
                    W.MobileIconImage.Visible = false
                    W.MobileIconImage.Image = ""
                end
                if W.MobileIconText then
                    W.MobileIconText.Visible = true
                end
                return
            end

            LogoImage.Image = img
            LogoImage.Visible = true
            LogoMark.BackgroundTransparency = 1
            LogoMarkDot.Visible = false
            applyImageTint(LogoImage, W.IconTint)

            if W.MobileIconImage then
                W.MobileIconImage.Image = img
                W.MobileIconImage.Visible = true
                applyImageTint(W.MobileIconImage, typeof(W.IconTint) == "Color3" and W.IconTint or nil)
            end
            if W.MobileIconText then
                W.MobileIconText.Visible = false
            end
        end)
    end

    bind(UIS.InputBegan, function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == W.ToggleKey then
            W:Toggle()
        end
    end)

    local isMobile = Library.IsMobile
    W.IsMobile = isMobile
    W.MobileButton = nil
    if isMobile then
        W.BaseScale = 0.60
        MainUIScale.Scale = 0.60
    end

    if isMobile then
        local MobileButton = New("Frame", {
            Name = "MobileToggleButton",
            Parent = SG,
            Size = UDim2.fromOffset(52, 52),
            Position = UDim2.fromOffset(15, 100),
            BackgroundColor3 = C.Accent,
            BackgroundTransparency = 0.1,
            BorderSizePixel = 0,
            ZIndex = 100,
            Active = true
        })
        Corner(MobileButton, 26)
        New("UIStroke", { Parent = MobileButton, Color = Color3.new(1, 1, 1), Thickness = 2, Transparency = 0.5 })

        local MobileIcon = New("TextLabel", {
            Parent = MobileButton,
            Position = UDim2.new(0.2, 0, 0.2, 0),
            Size = UDim2.new(0.6, 0, 0.6, 0),
            BackgroundTransparency = 1,
            Text = "\xE2\x98\xB0",
            TextColor3 = Color3.new(1, 1, 1),
            TextScaled = true,
            Font = Enum.Font.GothamBold,
            ZIndex = 101
        })

        local MobileIconImage = New("ImageLabel", {
            Name = "MobileIconImage",
            Parent = MobileButton,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0.58, 0, 0.58, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScaleType = Enum.ScaleType.Fit,
            Image = "",
            Visible = false,
            ZIndex = 101
        })

        local MobileInteract = New("TextButton", {
            Parent = MobileButton,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = "",
            ZIndex = 102,
            AutoButtonColor = false
        })

        table.insert(Library.AccentElements, MobileButton)

        W.MobileIconImage = MobileIconImage
        W.MobileIconText = MobileIcon

        local isDragging = false
        local wasDragged = false
        local mDragStart = nil
        local mStartPos = nil
        local dragThreshold = 8

        local function clampButtonPosition(x, y)
            local screenSize = SG.AbsoluteSize
            local btnSize = MobileButton.AbsoluteSize
            local cx = math.clamp(x, 5, math.max(5, screenSize.X - btnSize.X - 5))
            local cy = math.clamp(y, 5, math.max(5, screenSize.Y - btnSize.Y - 5))
            return cx, cy
        end

        MobileInteract.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                isDragging = true
                wasDragged = false
                mDragStart = Vector2.new(input.Position.X, input.Position.Y)
                mStartPos = MobileButton.Position
            end
        end)

        MobileInteract.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                if isDragging and not wasDragged then
                    W:Toggle()
                end
                isDragging = false
                wasDragged = false
            end
        end)

        bind(UIS.InputChanged, function(input)
            if not isDragging then return end
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
                local currentPos = Vector2.new(input.Position.X, input.Position.Y)
                local delta = currentPos - mDragStart
                if delta.Magnitude > dragThreshold then
                    wasDragged = true
                    local cx, cy = clampButtonPosition(mStartPos.X.Offset + delta.X, mStartPos.Y.Offset + delta.Y)
                    MobileButton.Position = UDim2.fromOffset(cx, cy)
                end
            end
        end)

        local _origSetVisible = W.SetVisible
        function W:SetVisible(visible)
            _origSetVisible(self, visible)
            if not MobileIconImage.Visible then
                MobileIcon.Text = visible and "\xE2\x9C\x95" or "\xE2\x98\xB0"
            end
            Tween(MobileButton, { BackgroundTransparency = visible and 0.4 or 0.1 }, 0.15, Enum.EasingStyle.Sine)
        end

        W.MobileButton = MobileButton
    end

    task.spawn(function()
        task.wait(1.0)
        if isfile and isfile(ConfigSystem.FolderName .. "/default.json") then
            ConfigSystem.Load("default")
        end
    end)

    W:SetVisible(true)

    if config.Icon ~= nil then
        W:SetIcon(config.Icon, config.IconTint)
    end

    Library:LoadNotificationSounds()

    local SearchIndex = {}

    function W:RegisterElement(name, tabName, categoryName, elementFrame, sectionFrame, column)
        table.insert(SearchIndex, {
            name = name,
            tabName = tabName,
            categoryName = categoryName,
            elementFrame = elementFrame,
            sectionFrame = sectionFrame,
            column = column
        })
    end

    local function flashHighlight(frame)
        if not (frame and frame.Parent) then return end

        local Highlight = New("Frame", {
            Name = "SearchHighlight",
            Parent = frame,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = C.Accent,
            BackgroundTransparency = 0.5,
            BorderSizePixel = 0,
            ZIndex = 100
        })
        Corner(Highlight, 8)

        task.spawn(function()
            for _ = 1, 3 do
                Tween(Highlight, { BackgroundTransparency = 0.85 }, 0.3, Enum.EasingStyle.Sine)
                task.wait(0.3)
                Tween(Highlight, { BackgroundTransparency = 0.5 }, 0.3, Enum.EasingStyle.Sine)
                task.wait(0.3)
            end
            Tween(Highlight, { BackgroundTransparency = 1 }, 0.5, Enum.EasingStyle.Sine)
            task.wait(0.5)
            Highlight:Destroy()
        end)
    end

    local function updateSearchResults()
        local query = SearchBox.Text:lower()

        for _, child in pairs(ResultsList:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end

        if query == "" or #query < 2 then
            SearchResults.Visible = false
            return
        end

        local matches = {}
        for _, entry in pairs(SearchIndex) do
            if entry.name:lower():find(query, 1, true) then
                table.insert(matches, entry)
            end
        end

        if #matches == 0 then
            SearchResults.Visible = false
            return
        end

        local count = math.min(#matches, 6)
        SearchResults.Size = UDim2.new(0, 250, 0, count * 38 + 8)

        for i = 1, count do
            local match = matches[i]
            local ResultBtn = New("TextButton", {
                Parent = ResultsList,
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = C.Section,
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false,
                ZIndex = 11
            })
            Corner(ResultBtn, 7)

            New("TextLabel", {
                Parent = ResultBtn,
                Position = UDim2.new(0, 10, 0, 3),
                Size = UDim2.new(1, -20, 0, 18),
                BackgroundTransparency = 1,
                Text = match.name,
                TextColor3 = C.Text,
                TextSize = 12,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                ZIndex = 12
            })

            New("TextLabel", {
                Parent = ResultBtn,
                Position = UDim2.new(0, 10, 0, 19),
                Size = UDim2.new(1, -20, 0, 14),
                BackgroundTransparency = 1,
                Text = match.tabName .. "  ›  " .. match.categoryName,
                TextColor3 = C.TextDim,
                TextSize = 10,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                ZIndex = 12
            })

            ResultBtn.MouseButton1Click:Connect(function()
                for _, tab in pairs(W.TopTabButtons) do
                    if tab.Name == match.tabName then
                        W:SelectTopTab(tab)
                        for _, cat in pairs(tab.Categories) do
                            if cat.Name == match.categoryName then
                                cat:Select()
                                task.wait(0.4)
                                flashHighlight(match.elementFrame)
                                break
                            end
                        end
                        break
                    end
                end

                SearchBox.Text = ""
                SearchResults.Visible = false
                SearchBox:ReleaseFocus()
            end)

            ResultBtn.MouseEnter:Connect(function()
                Tween(ResultBtn, { BackgroundColor3 = C.ElementHover }, 0.12)
            end)

            ResultBtn.MouseLeave:Connect(function()
                Tween(ResultBtn, { BackgroundColor3 = C.Section }, 0.12)
            end)
        end

        SearchResults.Visible = true
    end

    SearchBox:GetPropertyChangedSignal("Text"):Connect(updateSearchResults)
    SearchBox.Focused:Connect(updateSearchResults)

    local function CreateWatermark()
        local Watermark = New("ScreenGui", {
            Name = "rubyazlWatermark",
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            ResetOnSpawn = false
        })
        mount(Watermark)

        local WatermarkFrame = New("CanvasGroup", {
            Name = "WatermarkFrame",
            Parent = Watermark,
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, 12),
            Size = UDim2.new(0, 0, 0, 30),
            BackgroundColor3 = C.TopBar,
            BorderSizePixel = 0,
            AutomaticSize = Enum.AutomaticSize.X,
            GroupTransparency = 1
        })
        Corner(WatermarkFrame, 15)
        New("UIStroke", { Parent = WatermarkFrame, Color = C.Border, Thickness = 1, Transparency = 0.1 })

        local ContentFrame = New("Frame", {
            Name = "Content",
            Parent = WatermarkFrame,
            Size = UDim2.new(0, 0, 1, 0),
            BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.X
        })

        New("UIListLayout", {
            Parent = ContentFrame,
            FillDirection = Enum.FillDirection.Horizontal,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 0),
            VerticalAlignment = Enum.VerticalAlignment.Center
        })

        New("UIPadding", {
            Parent = ContentFrame,
            PaddingLeft = UDim.new(0, 14),
            PaddingRight = UDim.new(0, 14)
        })

        local wmText = config.WatermarkText or "rubyazl"
        local logoContainer = New("Frame", {
            Name = "Logo",
            Parent = ContentFrame,
            Size = UDim2.new(0, #wmText * 9, 1, 0),
            BackgroundTransparency = 1,
            LayoutOrder = 1
        })

        local logoLetters = makeLetters(logoContainer, wmText, 9, 15)

        local function sep(order)
            return New("TextLabel", {
                Parent = ContentFrame,
                Size = UDim2.new(0, 16, 1, 0),
                BackgroundTransparency = 1,
                Text = "•",
                TextColor3 = C.Accent,
                TextSize = 12,
                Font = Enum.Font.Gotham,
                LayoutOrder = order
            })
        end

        local Sep1 = sep(2)

        local UsernameLabel = New("TextLabel", {
            Name = "Username",
            Parent = ContentFrame,
            Size = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            Text = playerName,
            TextColor3 = C.Accent,
            TextSize = 12,
            Font = Enum.Font.GothamMedium,
            LayoutOrder = 3
        })

        local Sep2 = sep(4)

        local AlphaLabel = New("TextLabel", {
            Name = "Alpha",
            Parent = ContentFrame,
            Size = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            Text = "alpha",
            TextColor3 = C.Accent,
            TextSize = 12,
            Font = Enum.Font.GothamBold,
            LayoutOrder = 5
        })

        local Sep3 = sep(6)

        local PingLabel = New("TextLabel", {
            Name = "Ping",
            Parent = ContentFrame,
            Size = UDim2.new(0, 45, 1, 0),
            BackgroundTransparency = 1,
            Text = "0ms",
            TextColor3 = C.Accent,
            TextSize = 12,
            Font = Enum.Font.GothamMedium,
            LayoutOrder = 7
        })

        local WatermarkLine = New("Frame", {
            Name = "WatermarkLine",
            Parent = WatermarkFrame,
            Position = UDim2.new(0, 16, 1, -2),
            Size = UDim2.new(1, -32, 0, 2),
            BackgroundColor3 = C.Accent,
            BorderSizePixel = 0
        })

        New("UIGradient", {
            Parent = WatermarkLine,
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(0.5, 0.2),
                NumberSequenceKeypoint.new(1, 1)
            })
        })

        table.insert(Library.AccentElements, WatermarkLine)

        task.spawn(function()
            local Stats = game:GetService("Stats")
            while Watermark.Parent do
                pcall(function()
                    local ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
                    PingLabel.Text = tostring(ping) .. "ms"
                end)
                task.wait(1)
            end
        end)

        local wDragging, wDragInput, wDragStart, wStartPos

        WatermarkFrame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                wDragging = true
                wDragStart = input.Position
                wStartPos = WatermarkFrame.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        wDragging = false
                    end
                end)
            end
        end)

        bind(UIS.InputChanged, function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                wDragInput = input
            end
        end)

        bind(RS.RenderStepped, function(dt)
            if wDragging and wDragInput then
                local delta = wDragInput.Position - wDragStart
                local target = UDim2.new(wStartPos.X.Scale, wStartPos.X.Offset + delta.X, wStartPos.Y.Scale,
                    wStartPos.Y.Offset + delta.Y)
                WatermarkFrame.Position = WatermarkFrame.Position:Lerp(target, math.clamp(dt * 22, 0, 1))
            end
        end)

        task.wait(0.5)
        Tween(WatermarkFrame, { GroupTransparency = 0 }, 0.5, Enum.EasingStyle.Sine)

        return {
            Frame = Watermark,
            Letters = logoLetters,
            TextElements = { Sep1, UsernameLabel, Sep2, AlphaLabel, Sep3, PingLabel },
            SetVisible = function(visible)
                Watermark.Enabled = visible
            end
        }
    end

    W.Watermark = nil
    task.spawn(function()
        task.wait(0.2)
        if Library.IsMobile then return end
        W.Watermark = CreateWatermark()
    end)

    function W:CreateTopTab(name, icon)
        local T = { Name = name, Window = W, Categories = {}, LastSelectedCategory = nil }
        local hasIcon = icon ~= nil and icon ~= ""

        local Btn = New("TextButton", {
            Name = name,
            Parent = TopTabs,
            Size = UDim2.new(0, 54, 0, 52),
            BackgroundColor3 = C.Element,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = #W.TopTabButtons + 1
        })
        Corner(Btn, 12)

        local Label = New("TextLabel", {
            Name = "Label",
            Parent = Btn,
            Position = UDim2.new(0, 0, 1, -17),
            Size = UDim2.new(1, 0, 0, 12),
            BackgroundTransparency = 1,
            Text = name,
            TextColor3 = C.TextDim,
            TextSize = 9,
            Font = Enum.Font.GothamMedium,
            TextTruncate = Enum.TextTruncate.AtEnd
        })

        if hasIcon then
            local TabIcon = New("ImageLabel", {
                Name = "Icon",
                Parent = Btn,
                AnchorPoint = Vector2.new(0.5, 0),
                Position = UDim2.new(0.5, 0, 0, 8),
                Size = UDim2.fromOffset(22, 22),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Image = "",
                ImageColor3 = C.TextDim,
                ScaleType = Enum.ScaleType.Fit
            })
            T.Icon = TabIcon
            setImageAsync(TabIcon, icon)
        else
            T.Glyph = New("TextLabel", {
                Name = "Glyph",
                Parent = Btn,
                Position = UDim2.new(0, 0, 0, 5),
                Size = UDim2.new(1, 0, 0, 26),
                BackgroundTransparency = 1,
                Text = name:sub(1, 1):upper(),
                TextColor3 = C.TextDim,
                TextSize = 19,
                Font = Enum.Font.GothamBold
            })
        end

        local Line = New("Frame", {
            Name = "Line",
            Parent = Btn,
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 2, 0.5, 0),
            Size = UDim2.new(0, 3, 0, 0),
            BackgroundColor3 = C.Accent,
            BorderSizePixel = 0,
            Visible = false
        })
        Corner(Line, 99)
        table.insert(Library.AccentElements, Line)

        T.Button = Btn
        T.Label = Label
        T.Line = Line
        table.insert(W.TopTabButtons, T)

        Btn.MouseButton1Click:Connect(function()
            W:SelectTopTab(T)
        end)

        Btn.MouseEnter:Connect(function()
            if W.CurrentTopTab ~= T then
                Tween(Btn, { BackgroundTransparency = 0.6 }, 0.15)
                Tween(Label, { TextColor3 = Color3.fromRGB(190, 192, 212) }, 0.15)
                if T.Icon then Tween(T.Icon, { ImageColor3 = Color3.fromRGB(190, 192, 212) }, 0.15) end
                if T.Glyph then Tween(T.Glyph, { TextColor3 = Color3.fromRGB(190, 192, 212) }, 0.15) end
            end
        end)

        Btn.MouseLeave:Connect(function()
            if W.CurrentTopTab ~= T then
                Tween(Btn, { BackgroundTransparency = 1 }, 0.15)
                Tween(Label, { TextColor3 = C.TextDim }, 0.15)
                if T.Icon then Tween(T.Icon, { ImageColor3 = C.TextDim }, 0.15) end
                if T.Glyph then Tween(T.Glyph, { TextColor3 = C.TextDim }, 0.15) end
            end
        end)

        if #W.TopTabButtons == 1 then
            task.spawn(function()
                task.wait(0.1)
                W:SelectTopTab(T)
            end)
        end

        return T
    end

    function W:SelectTopTab(tab)
        if W.CurrentTopTab == tab then return end

        closePickers()

        for _, t in ipairs(W.TopTabButtons) do
            local active = (t == tab)
            Tween(t.Button, { BackgroundTransparency = active and 0 or 1 }, 0.2)
            Tween(t.Label, { TextColor3 = active and C.Text or C.TextDim }, 0.2)
            if t.Icon then Tween(t.Icon, { ImageColor3 = active and C.Text or C.TextDim }, 0.2) end
            if t.Glyph then Tween(t.Glyph, { TextColor3 = active and C.Text or C.TextDim }, 0.2) end

            if active then
                t.Line.Visible = true
                t.Line.Size = UDim2.new(0, 3, 0, 0)
                Tween(t.Line, { Size = UDim2.new(0, 3, 0, 22) }, 0.4, Enum.EasingStyle.Back)
            else
                t.Line.Visible = false
            end
        end

        W.CurrentTopTab = tab

        TabTitle.Text = tab.Name
        TabTitle.TextTransparency = 1
        Tween(TabTitle, { TextTransparency = 0 }, 0.3, Enum.EasingStyle.Sine)

        for _, c in pairs(CatList:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end

        for i, cat in ipairs(tab.Categories) do
            cat:Show()
            if cat.Button then
                task.spawn(function()
                    task.wait(i * 0.04)
                    if cat.Button and cat.Button.Parent then
                        Tween(cat.Button, { TextTransparency = 0 }, 0.2, Enum.EasingStyle.Sine)
                    end
                    if cat.Icon and cat.Icon.Parent then
                        Tween(cat.Icon, { ImageTransparency = 0 }, 0.2, Enum.EasingStyle.Sine)
                    end
                end)
            end
        end

        if #tab.Categories > 0 then
            if tab.LastSelectedCategory and table.find(tab.Categories, tab.LastSelectedCategory) then
                tab.LastSelectedCategory:Select(true)
            else
                tab.Categories[1]:Select(true)
            end
        end
    end

    function W:CreateCategory(topTab, name, icon)
        local Cat = { Name = name, TopTab = topTab, Sections = {}, Button = nil, IconId = icon }

        function Cat:Show(instant)
            local hasIcon = Cat.IconId ~= nil and Cat.IconId ~= ""
            local padLeft = hasIcon and 32 or 14
            local padRight = 14

            local Btn = New("TextButton", {
                Name = name,
                Parent = CatList,
                AutomaticSize = Enum.AutomaticSize.X,
                Size = UDim2.new(0, 0, 0, 28),
                BackgroundColor3 = C.Element,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Text = name,
                TextColor3 = C.TextDim,
                TextSize = 13,
                Font = Enum.Font.GothamMedium,
                AutoButtonColor = false,
                TextTransparency = instant and 0 or 1,
                LayoutOrder = (table.find(topTab.Categories, Cat) or 1)
            })

            Corner(Btn, 14)
            New("UIPadding", {
                Parent = Btn,
                PaddingLeft = UDim.new(0, padLeft),
                PaddingRight = UDim.new(0, padRight)
            })

            local Border = New("Frame", {
                Name = "Border",
                Parent = Btn,
                AnchorPoint = Vector2.new(0.5, 1),
                Position = UDim2.new(0.5, (padRight - padLeft) / 2, 1, 5),
                Size = UDim2.new(0, 18, 0, 2),
                BackgroundColor3 = C.Accent,
                BorderSizePixel = 0,
                Visible = false
            })
            Corner(Border, 99)
            table.insert(Library.AccentElements, Border)

            Cat.Button = Btn
            Cat.Border = Border
            Cat.Icon = nil

            if hasIcon then
                local CatIcon = New("ImageLabel", {
                    Name = "Icon",
                    Parent = Btn,
                    AnchorPoint = Vector2.new(0, 0.5),
                    Position = UDim2.new(0, -(padLeft - 10), 0.5, 0),
                    Size = UDim2.fromOffset(16, 16),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Image = "",
                    ImageColor3 = C.TextDim,
                    ImageTransparency = instant and 0 or 1,
                    ScaleType = Enum.ScaleType.Fit
                })
                Cat.Icon = CatIcon
                setImageAsync(CatIcon, Cat.IconId)
            end

            if W.CurrentCategory == Cat then
                Btn.TextColor3 = C.Accent
                Btn.BackgroundTransparency = 0
                Border.Visible = true
                if Cat.Icon then Cat.Icon.ImageColor3 = C.Accent end
            end

            Btn.MouseButton1Click:Connect(function()
                Cat:Select()
            end)

            Btn.MouseEnter:Connect(function()
                if W.CurrentCategory ~= Cat then
                    Tween(Btn, { TextColor3 = Color3.fromRGB(190, 192, 212), BackgroundTransparency = 0.6 }, 0.2,
                        Enum.EasingStyle.Sine)
                    if Cat.Icon then
                        Tween(Cat.Icon, { ImageColor3 = Color3.fromRGB(190, 192, 212) }, 0.2, Enum.EasingStyle.Sine)
                    end
                end
            end)

            Btn.MouseLeave:Connect(function()
                if W.CurrentCategory ~= Cat then
                    Tween(Btn, { TextColor3 = C.TextDim, BackgroundTransparency = 1 }, 0.2, Enum.EasingStyle.Sine)
                    if Cat.Icon then
                        Tween(Cat.Icon, { ImageColor3 = C.TextDim }, 0.2, Enum.EasingStyle.Sine)
                    end
                end
            end)
        end

        function Cat:Select(force)
            if W.CurrentCategory == Cat and not force then return end

            for _, c in pairs(CatList:GetChildren()) do
                if c:IsA("TextButton") then
                    Tween(c, { TextColor3 = C.TextDim, BackgroundTransparency = 1 }, 0.15, Enum.EasingStyle.Sine)
                    local b = c:FindFirstChild("Border")
                    if b then b.Visible = false end
                    local otherIcon = c:FindFirstChild("Icon")
                    if otherIcon then
                        Tween(otherIcon, { ImageColor3 = C.TextDim }, 0.15, Enum.EasingStyle.Sine)
                    end
                end
            end

            if Cat.Button and Cat.Button.Parent then
                Tween(Cat.Button, { TextColor3 = C.Accent, BackgroundTransparency = 0 }, 0.2, Enum.EasingStyle.Sine)
                if Cat.Icon then
                    Tween(Cat.Icon, { ImageColor3 = C.Accent }, 0.2, Enum.EasingStyle.Sine)
                end
                Cat.Border.Visible = true
                Cat.Border.Size = UDim2.new(0, 4, 0, 2)
                Tween(Cat.Border, { Size = UDim2.new(0, 18, 0, 2) }, 0.35, Enum.EasingStyle.Back)
            end

            W.CurrentCategory = Cat

            if Cat.TopTab then
                Cat.TopTab.LastSelectedCategory = Cat
            end

            for _, col in ipairs({ LeftColumn, RightColumn }) do
                for _, c in pairs(col:GetChildren()) do
                    if c:IsA("GuiObject") then
                        c.Visible = false
                    end
                end
            end

            ContentScroll.CanvasPosition = Vector2.new(0, 0)

            local stagger = 0
            for _, sec in pairs(Cat.Sections) do
                sec.Frame.Visible = true
                sec.Frame.GroupTransparency = 1
                local delayTime = stagger * 0.06
                stagger = stagger + 1
                task.delay(delayTime, function()
                    if sec.Frame and sec.Frame.Parent then
                        Tween(sec.Frame, { GroupTransparency = 0 }, 0.35, Enum.EasingStyle.Quad)
                    end
                end)
            end
        end

        table.insert(topTab.Categories, Cat)
        table.insert(W.Categories, Cat)

        if W.CurrentTopTab == topTab then
            Cat:Show(false)
            if Cat.Button then
                Tween(Cat.Button, { TextTransparency = 0 }, 0.2, Enum.EasingStyle.Sine)
                if Cat.Icon then Tween(Cat.Icon, { ImageTransparency = 0 }, 0.2, Enum.EasingStyle.Sine) end
            end
        end

        return Cat
    end

    if not Library.Windows then
        Library.Windows = {}
    end
    table.insert(Library.Windows, W)

    return W
end

function Library:CreateSection(category, name, column)
    column = column or "left"

    local S = { Name = name, Category = category, Column = column, Elements = {} }

    local parentColumn
    if category.TopTab and category.TopTab.Window then
        parentColumn = column == "left" and category.TopTab.Window.LeftColumn or category.TopTab.Window.RightColumn
    end

    local layoutOrder = 1
    for _, sec in pairs(category.Sections) do
        if sec.Column == column then
            layoutOrder = layoutOrder + 1
        end
    end

    local Frame = New("CanvasGroup", {
        Name = name,
        Parent = parentColumn,
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = C.Section,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        Visible = false,
        GroupTransparency = 0,
        LayoutOrder = layoutOrder
    })

    Corner(Frame, 12)
    New("UIStroke", { Parent = Frame, Color = C.Border, Thickness = 1, Transparency = 0.15 })

    local HeaderDot = New("Frame", {
        Name = "HeaderDot",
        Parent = Frame,
        Position = UDim2.new(0, 14, 0, 14),
        Size = UDim2.fromOffset(6, 6),
        BackgroundColor3 = C.Accent,
        BorderSizePixel = 0
    })
    Corner(HeaderDot, 99)
    table.insert(Library.AccentElements, HeaderDot)

    New("TextLabel", {
        Name = "Header",
        Parent = Frame,
        Position = UDim2.new(0, 28, 0, 7),
        Size = UDim2.new(1, -42, 0, 20),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = C.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamBold
    })

    New("Frame", {
        Name = "HeaderLine",
        Parent = Frame,
        Position = UDim2.new(0, 12, 0, 33),
        Size = UDim2.new(1, -24, 0, 1),
        BackgroundColor3 = C.Border,
        BorderSizePixel = 0
    })

    local Container = New("Frame", {
        Name = "Container",
        Parent = Frame,
        Position = UDim2.new(0, 0, 0, 40),
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y
    })

    New("UIListLayout", {
        Parent = Container,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6)
    })

    New("UIPadding", {
        Parent = Container,
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 12)
    })

    S.Frame = Frame
    S.Container = Container

    table.insert(category.Sections, S)

    return S
end

local function rowCard(parent, height)
    local Frame = New("Frame", {
        Parent = parent,
        Size = UDim2.new(1, 0, 0, height),
        BackgroundColor3 = C.Element,
        BorderSizePixel = 0
    })
    Corner(Frame, 8)
    return Frame
end

local function hoverCard(frame, hitbox)
    hitbox.MouseEnter:Connect(function()
        Tween(frame, { BackgroundColor3 = C.ElementHover }, 0.15)
    end)
    hitbox.MouseLeave:Connect(function()
        Tween(frame, { BackgroundColor3 = C.Element }, 0.15)
    end)
end

function Library:CreateToggle(section, config)
    config = config or {}
    local name = config.Name or "Toggle"
    local default = config.Default or false
    local callback = config.Callback or function() end
    local keybind = config.Keybind

    local configPath = pathFor(section, name)

    local T = {
        Value = default,
        Callback = callback,
        ConfigPath = configPath,
        HasKeybind = keybind ~= nil,
        KeybindKey = nil,
        Name = name
    }

    local Frame = rowCard(section.Container, 30)

    local Box = New("Frame", {
        Parent = Frame,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.fromOffset(18, 18),
        BackgroundColor3 = default and C.Accent or C.SliderBg,
        BorderSizePixel = 0
    })
    Corner(Box, 5)

    local BoxStroke = New("UIStroke", {
        Parent = Box,
        Color = default and C.Accent or C.Border,
        Thickness = 1,
        Transparency = 0
    })

    local Check = New("TextLabel", {
        Parent = Box,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "✓",
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = default and 12 or 7,
        TextTransparency = default and 0 or 1,
        Font = Enum.Font.GothamBold
    })

    local function setAccentRegistered(on)
        for i = #Library.AccentElements, 1, -1 do
            local el = Library.AccentElements[i]
            if el == Box or el == BoxStroke then
                table.remove(Library.AccentElements, i)
            end
        end
        if on then
            table.insert(Library.AccentElements, Box)
            table.insert(Library.AccentElements, BoxStroke)
        end
    end

    if default then
        setAccentRegistered(true)
    end

    local labelWidth = keybind and -112 or -42

    local Label = New("TextLabel", {
        Parent = Frame,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, labelWidth, 1, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = default and C.Text or Color3.fromRGB(160, 162, 182),
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Font = Enum.Font.Gotham
    })

    local Btn = New("TextButton", {
        Parent = Frame,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = ""
    })

    hoverCard(Frame, Btn)

    if config.Tooltip then
        Library:AttachTooltip(Btn, config.Tooltip)
    end

    function T:SetValue(v, skipSave)
        v = v and true or false
        T.Value = v

        Tween(Box, { BackgroundColor3 = v and C.Accent or C.SliderBg }, 0.2, Enum.EasingStyle.Sine)
        Tween(BoxStroke, { Color = v and C.Accent or C.Border }, 0.2, Enum.EasingStyle.Sine)
        Tween(Check, { TextTransparency = v and 0 or 1, TextSize = v and 12 or 7 }, 0.2, Enum.EasingStyle.Back)
        Tween(Label, { TextColor3 = v and C.Text or Color3.fromRGB(160, 162, 182) }, 0.2, Enum.EasingStyle.Sine)

        setAccentRegistered(v)

        callback(v)

        if T.HasKeybind and Library.KeybindsWindow then
            Library.KeybindsWindow:UpdateKeybind(name, T.KeybindKey and keyName(T.KeybindKey) or "None", v)
        end

        if not skipSave then
            autoSave()
        end
    end

    function T:GetValue()
        return T.Value
    end

    Btn.MouseButton1Click:Connect(function()
        T:SetValue(not T.Value)
    end)

    if keybind then
        local KeyBtn = New("TextButton", {
            Parent = Frame,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -34, 0.5, 0),
            Size = UDim2.new(0, 66, 0, 20),
            BackgroundColor3 = C.Chip,
            BorderSizePixel = 0,
            Text = "[" .. keyName(keybind.Default) .. "]",
            TextColor3 = C.TextDim,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Font = Enum.Font.GothamMedium,
            AutoButtonColor = false
        })
        Corner(KeyBtn, 6)

        local editing = false
        local currentKey = keybind.Default
        local mode = keybind.Mode or "Toggle"
        local modeMenuOpen = false
        T.KeybindKey = currentKey
        T.KeybindMode = mode

        KeyBtn.MouseButton1Click:Connect(function()
            editing = true
            KeyBtn.Text = "[...]"
            KeyBtn.TextColor3 = C.Accent
        end)

        KeyBtn.MouseButton2Click:Connect(function()
            if editing or modeMenuOpen then return end
            modeMenuOpen = true
            openModeMenu(KeyBtn,
                function() return mode end,
                function(m)
                    mode = m
                    T.KeybindMode = m
                end,
                function() modeMenuOpen = false end)
        end)

        KeyBtn.MouseEnter:Connect(function()
            if not editing then Tween(KeyBtn, { TextColor3 = C.Text }, 0.15) end
        end)

        KeyBtn.MouseLeave:Connect(function()
            if not editing then Tween(KeyBtn, { TextColor3 = C.TextDim }, 0.15) end
        end)

        bind(UIS.InputBegan, function(input, gameProcessed)
            if editing then
                local key = input.KeyCode
                if key == Enum.KeyCode.Unknown and (input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3) then
                    key = input.UserInputType
                end

                if key == Enum.KeyCode.Escape then
                    editing = false
                    KeyBtn.Text = "[" .. keyName(currentKey) .. "]"
                    KeyBtn.TextColor3 = C.TextDim
                    return
                end

                if key ~= Enum.KeyCode.Unknown then
                    currentKey = key
                    T.KeybindKey = key
                    KeyBtn.Text = "[" .. keyName(key) .. "]"
                    editing = false
                    KeyBtn.TextColor3 = C.TextDim

                    if Library.KeybindsWindow then
                        Library.KeybindsWindow:UpdateKeybind(name, keyName(key), T.Value)
                    end
                end
                return
            end

            if gameProcessed or not currentKey then return end
            if input.KeyCode == currentKey or input.UserInputType == currentKey then
                if mode == "Toggle" then
                    T:SetValue(not T.Value)
                elseif mode == "Hold" then
                    T:SetValue(true)
                end
            end
        end)

        bind(UIS.InputEnded, function(input)
            if currentKey and mode == "Hold" and (input.KeyCode == currentKey or input.UserInputType == currentKey) then
                T:SetValue(false)
            end
        end)

        T.GetKeybind = function() return currentKey end
        T.SetKeybind = function(key)
            currentKey = key
            T.KeybindKey = key
            KeyBtn.Text = "[" .. keyName(key) .. "]"

            if Library.KeybindsWindow then
                Library.KeybindsWindow:UpdateKeybind(name, keyName(key), T.Value)
            end
        end

        T.GetMode = function() return mode end
        T.SetMode = function(newMode)
            mode = newMode == "Hold" and "Hold" or "Toggle"
            T.KeybindMode = mode
        end

        if not Library.KeybindToggles then
            Library.KeybindToggles = {}
        end
        table.insert(Library.KeybindToggles, T)
    end

    if not config.NoSave then
        ConfigSystem.Elements[configPath] = T
    end

    register(name, section, Frame)

    return T
end

function Library:CreateSlider(section, config)
    config = config or {}
    local name = config.Name or "Slider"
    local min = config.Min or 0
    local max = config.Max or 100
    if max == min then max = min + 1 end
    local default = config.Default or min
    local suffix = config.Suffix or ""
    local callback = config.Callback or function() end
    local step = config.Step or 1
    local decimals = 0
    if step < 1 then
        local s = tostring(step):match("%.(%d+)")
        decimals = s and #s or 1
    end

    local function snap(v)
        v = math.clamp(v, min, max)
        local snapped = min + math.floor((v - min) / step + 0.5) * step
        snapped = math.clamp(snapped, min, max)
        if decimals > 0 then
            local mult = 10 ^ decimals
            snapped = math.floor(snapped * mult + 0.5) / mult
        end
        return snapped
    end

    local function fmt(v)
        if decimals > 0 then
            return string.format("%." .. decimals .. "f", v)
        end
        return tostring(v)
    end

    local configPath = pathFor(section, name)

    default = snap(default)
    local S = { Value = default, Min = min, Max = max, Step = step, Callback = callback, ConfigPath = configPath }
    local mobile = Library.IsMobile

    local Frame = rowCard(section.Container, mobile and 54 or 46)

    local Label = New("TextLabel", {
        Parent = Frame,
        Position = UDim2.new(0, 10, 0, 6),
        Size = UDim2.new(0.6, 0, 0, 16),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = C.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Font = Enum.Font.Gotham
    })

    local Value = New("TextLabel", {
        Parent = Frame,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -10, 0, 6),
        Size = UDim2.new(0, 70, 0, 16),
        BackgroundTransparency = 1,
        Text = fmt(default) .. suffix,
        TextColor3 = C.TextDim,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
        Font = Enum.Font.GothamMedium
    })

    local Track = New("Frame", {
        Parent = Frame,
        Position = UDim2.new(0, 10, 1, -(mobile and 20 or 13)),
        Size = UDim2.new(1, -20, 0, mobile and 12 or 6),
        BackgroundColor3 = C.SliderBg,
        BorderSizePixel = 0
    })
    Corner(Track, 99)

    local Fill = New("Frame", {
        Parent = Track,
        Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
        BackgroundColor3 = C.Accent,
        BorderSizePixel = 0
    })
    Corner(Fill, 99)
    table.insert(Library.AccentElements, Fill)

    local knobSize = mobile and 18 or 12
    local Knob = New("Frame", {
        Parent = Track,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new((default - min) / (max - min), 0, 0.5, 0),
        Size = UDim2.fromOffset(knobSize, knobSize),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 3
    })
    Corner(Knob, 99)

    local KnobStroke = New("UIStroke", {
        Parent = Knob,
        Color = C.Accent,
        Thickness = 2,
        Transparency = 1
    })
    table.insert(Library.AccentElements, KnobStroke)

    local Btn = New("TextButton", {
        Parent = Track,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = mobile and UDim2.new(1, 24, 0, 44) or UDim2.new(1, 0, 0, 18),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 5
    })

    Btn.MouseEnter:Connect(function()
        Tween(Track, { BackgroundColor3 = Color3.fromRGB(50, 50, 66) }, 0.15)
        Tween(Frame, { BackgroundColor3 = C.ElementHover }, 0.15)
    end)

    Btn.MouseLeave:Connect(function()
        Tween(Track, { BackgroundColor3 = C.SliderBg }, 0.15)
        Tween(Frame, { BackgroundColor3 = C.Element }, 0.15)
    end)

    if config.Tooltip then
        Library:AttachTooltip(Btn, config.Tooltip)
        Library:AttachTooltip(Label, config.Tooltip)
    end

    local dragging = false
    local ancestorScrolls = {}
    do
        local p = Frame.Parent
        while p and p ~= game do
            if p:IsA("ScrollingFrame") then table.insert(ancestorScrolls, p) end
            p = p.Parent
        end
    end

    local function setScrollingEnabled(enabled)
        for _, sf in ipairs(ancestorScrolls) do sf.ScrollingEnabled = enabled end
    end

    local function endDragVisuals()
        Tween(Knob, { Size = UDim2.fromOffset(knobSize, knobSize) }, 0.15, Enum.EasingStyle.Sine)
        Tween(KnobStroke, { Transparency = 1 }, 0.2, Enum.EasingStyle.Sine)
        Tween(Value, { TextColor3 = C.TextDim }, 0.2, Enum.EasingStyle.Sine)
    end

    bind(UIS.InputEnded, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            dragging = false
            setScrollingEnabled(true)
            endDragVisuals()
        end
    end)

    function S:SetValue(v, skipSave)
        v = snap(tonumber(v) or min)
        S.Value = v
        local p = (v - min) / (max - min)
        Tween(Fill, { Size = UDim2.new(p, 0, 1, 0) }, 0.12, Enum.EasingStyle.Sine)
        Tween(Knob, { Position = UDim2.new(p, 0, 0.5, 0) }, 0.12, Enum.EasingStyle.Sine)
        Value.Text = fmt(v) .. suffix
        callback(v)
        if not skipSave then
            autoSave()
        end
    end

    function S:GetValue()
        return S.Value
    end

    local dragAnchorX = 0
    local dragAnchorVal = 0

    local function setFromPosition(input)
        local pos = (input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X
        pos = math.clamp(pos, 0, 1)
        S:SetValue(snap(min + (max - min) * pos))
    end

    Btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setScrollingEnabled(false)
            Tween(Knob, { Size = UDim2.fromOffset(knobSize + 4, knobSize + 4) }, 0.15, Enum.EasingStyle.Back)
            Tween(KnobStroke, { Transparency = 0.45 }, 0.15, Enum.EasingStyle.Sine)
            Tween(Value, { TextColor3 = C.Text }, 0.2, Enum.EasingStyle.Sine)
            setFromPosition(input)
            dragAnchorX = input.Position.X
            dragAnchorVal = S.Value
        end
    end)

    Btn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            setScrollingEnabled(true)
            endDragVisuals()
        end
    end)

    bind(UIS.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local trackW = Track.AbsoluteSize.X
            local pxPerStep = (step / (max - min)) * trackW
            if pxPerStep >= 1 then
                setFromPosition(input)
                dragAnchorX = input.Position.X
                dragAnchorVal = S.Value
            else
                local deltaPx = input.Position.X - dragAnchorX
                S:SetValue(snap(dragAnchorVal + deltaPx * step))
            end
        end
    end)

    if not config.NoSave then
        ConfigSystem.Elements[configPath] = S
    end

    register(name, section, Frame)

    return S
end

function Library:CreateDropdown(section, config)
    config = config or {}
    local name = config.Name or "Dropdown"
    local options = config.Options or {}
    local default = config.Default or (options[1] or "")
    local callback = config.Callback or function() end

    local configPath = pathFor(section, name)

    local D = { Value = default, Options = options, Callback = callback, Open = false, ConfigPath = configPath }

    local Container = New("Frame", {
        Parent = section.Container,
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = C.Element,
        BorderSizePixel = 0,
        ClipsDescendants = true
    })
    Corner(Container, 8)

    local Row = New("Frame", {
        Parent = Container,
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundTransparency = 1
    })

    local Label = New("TextLabel", {
        Parent = Row,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(0.45, -10, 1, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = C.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Font = Enum.Font.Gotham
    })

    local Value = New("TextLabel", {
        Parent = Row,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -6, 0.5, 0),
        Size = UDim2.new(0.55, -10, 0, 22),
        BackgroundColor3 = C.Chip,
        BorderSizePixel = 0,
        Text = tostring(default),
        TextColor3 = C.TextDim,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamMedium,
        TextTruncate = Enum.TextTruncate.AtEnd
    })
    Corner(Value, 6)
    New("UIPadding", { Parent = Value, PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 22) })

    local Arrow = New("TextLabel", {
        Parent = Row,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.new(0, 14, 0, 22),
        BackgroundTransparency = 1,
        Text = "›",
        TextColor3 = C.TextDim,
        TextSize = 18,
        Font = Enum.Font.GothamBold,
        Rotation = 0
    })

    local List = New("ScrollingFrame", {
        Parent = Container,
        Position = UDim2.new(0, 6, 0, 36),
        Size = UDim2.new(1, -12, 0, 0),
        BackgroundColor3 = C.Section,
        BorderSizePixel = 0,
        Visible = false,
        ClipsDescendants = true,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = C.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y
    })
    Corner(List, 7)
    New("UIListLayout", { Parent = List, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2) })
    New("UIPadding", {
        Parent = List,
        PaddingTop = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 4),
        PaddingLeft = UDim.new(0, 4),
        PaddingRight = UDim.new(0, 4)
    })

    local Btn = New("TextButton", {
        Parent = Row,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = ""
    })

    Btn.MouseEnter:Connect(function()
        Tween(Value, { BackgroundColor3 = Color3.fromRGB(44, 44, 58) }, 0.15)
        Tween(Container, { BackgroundColor3 = C.ElementHover }, 0.15)
    end)

    Btn.MouseLeave:Connect(function()
        Tween(Value, { BackgroundColor3 = C.Chip }, 0.15)
        Tween(Container, { BackgroundColor3 = C.Element }, 0.15)
    end)

    if config.Tooltip then
        Library:AttachTooltip(Btn, config.Tooltip)
    end

    local function updateSelected()
        for _, c in pairs(List:GetChildren()) do
            if c:IsA("TextButton") then
                Tween(c, { TextColor3 = (c.Text == tostring(D.Value)) and C.Accent or C.Text }, 0.15,
                    Enum.EasingStyle.Sine)
            end
        end
    end

    function D:SetValue(v, skipSave)
        D.Value = v
        Value.Text = tostring(v)
        updateSelected()
        callback(v)
        if not skipSave then
            autoSave()
        end
    end

    function D:GetValue()
        return D.Value
    end

    function D:Toggle(state)
        if state == nil then state = not D.Open end
        D.Open = state

        if state then
            List.Visible = true
            local h = math.clamp(#D.Options * 24 + 8, 40, 168)

            Tween(Container, { Size = UDim2.new(1, 0, 0, 32 + 4 + h + 6) }, 0.3, Enum.EasingStyle.Quint)
            Tween(List, { Size = UDim2.new(1, -12, 0, h) }, 0.3, Enum.EasingStyle.Quint)
            Tween(Arrow, { Rotation = 90, TextColor3 = C.Accent }, 0.25, Enum.EasingStyle.Quint)
        else
            Tween(Container, { Size = UDim2.new(1, 0, 0, 32) }, 0.25, Enum.EasingStyle.Quint)
            Tween(List, { Size = UDim2.new(1, -12, 0, 0) }, 0.25, Enum.EasingStyle.Quint)
            Tween(Arrow, { Rotation = 0, TextColor3 = C.TextDim }, 0.25, Enum.EasingStyle.Quint)

            task.delay(0.27, function()
                if not D.Open then
                    List.Visible = false
                end
            end)
        end
    end

    function D:Refresh(newOpts)
        for _, c in pairs(List:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        D.Options = newOpts
        for _, opt in pairs(newOpts) do
            local O = New("TextButton", {
                Parent = List,
                Size = UDim2.new(1, 0, 0, 22),
                BackgroundColor3 = C.Element,
                BorderSizePixel = 0,
                Text = tostring(opt),
                TextColor3 = (opt == D.Value) and C.Accent or C.Text,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                Font = Enum.Font.GothamMedium,
                AutoButtonColor = false
            })
            Corner(O, 5)
            New("UIPadding", { Parent = O, PaddingLeft = UDim.new(0, 8) })
            O.MouseButton1Click:Connect(function()
                D:SetValue(opt)
                D:Toggle(false)
            end)
            O.MouseEnter:Connect(function() Tween(O, { BackgroundColor3 = C.ElementHover }, 0.12, Enum.EasingStyle.Sine) end)
            O.MouseLeave:Connect(function() Tween(O, { BackgroundColor3 = C.Element }, 0.12, Enum.EasingStyle.Sine) end)
        end
    end

    Btn.MouseButton1Click:Connect(function() D:Toggle() end)
    D:Refresh(options)

    if not config.NoSave then
        ConfigSystem.Elements[configPath] = D
    end

    register(name, section, Container)

    return D
end

function Library:CreateLabel(section, text)
    local L = New("TextLabel", {
        Parent = section.Container,
        Size = UDim2.new(1, 0, 0, 18),
        BackgroundTransparency = 1,
        Text = text or "",
        TextColor3 = C.TextDim,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.Gotham
    })
    New("UIPadding", { Parent = L, PaddingLeft = UDim.new(0, 4) })
    return L
end

function Library:CreateButton(section, config)
    config = config or {}
    local name = config.Name or "Button"
    local callback = config.Callback or function() end

    local B = { Callback = callback }

    local Frame = New("Frame", {
        Parent = section.Container,
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = C.Element,
        BorderSizePixel = 0
    })
    Corner(Frame, 8)
    local BtnStroke = New("UIStroke", { Parent = Frame, Color = C.Border, Thickness = 1, Transparency = 0.2 })

    local Btn = New("TextButton", {
        Parent = Frame,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = C.Text,
        TextSize = 13,
        Font = Enum.Font.GothamMedium,
        AutoButtonColor = false
    })

    local hovering = false

    Btn.MouseEnter:Connect(function()
        hovering = true
        Tween(Frame, { BackgroundColor3 = C.Accent }, 0.2, Enum.EasingStyle.Sine)
        Tween(BtnStroke, { Transparency = 1 }, 0.2, Enum.EasingStyle.Sine)
    end)

    Btn.MouseLeave:Connect(function()
        hovering = false
        Tween(Frame, { BackgroundColor3 = C.Element }, 0.2, Enum.EasingStyle.Sine)
        Tween(BtnStroke, { Transparency = 0.2 }, 0.2, Enum.EasingStyle.Sine)
    end)

    Btn.MouseButton1Down:Connect(function()
        Tween(Frame, { BackgroundColor3 = C.Accent:Lerp(Color3.new(0, 0, 0), 0.3) }, 0.06, Enum.EasingStyle.Sine)
    end)

    Btn.MouseButton1Up:Connect(function()
        Tween(Frame, { BackgroundColor3 = hovering and C.Accent or C.Element }, 0.15, Enum.EasingStyle.Sine)
    end)

    Btn.MouseButton1Click:Connect(function()
        callback()
    end)

    if config.Tooltip then
        Library:AttachTooltip(Btn, config.Tooltip)
    end

    function B:SetText(text)
        Btn.Text = text
    end

    register(name, section, Frame)

    return B
end

function Library:CreateKeybind(section, config)
    config = config or {}
    local name = config.Name or "Keybind"
    local default = config.Default or Enum.KeyCode.E
    local mode = config.Mode or "Toggle"
    local callback = config.Callback or function() end

    local configPath = pathFor(section, name)

    local K = {
        Key = default,
        Mode = mode,
        Callback = callback,
        Active = false,
        Editing = false,
        ConfigPath = configPath,
        Name = name
    }

    local Frame = rowCard(section.Container, 30)

    New("TextLabel", {
        Parent = Frame,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(0.5, -10, 1, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = C.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Font = Enum.Font.Gotham
    })

    local KeyBtn = New("TextButton", {
        Parent = Frame,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -6, 0.5, 0),
        Size = UDim2.new(0, 76, 0, 20),
        BackgroundColor3 = C.Chip,
        BorderSizePixel = 0,
        Text = "[" .. keyName(default) .. "]",
        TextColor3 = C.TextDim,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Font = Enum.Font.GothamMedium,
        AutoButtonColor = false
    })
    Corner(KeyBtn, 6)

    if config.Tooltip then
        Library:AttachTooltip(KeyBtn, config.Tooltip)
    end

    K.ManualWatermark = config.ManualWatermark == true
    local function refreshKeybindsWindow()
        if K.ManualWatermark then return end
        if Library.KeybindsWindow then
            Library.KeybindsWindow:UpdateKeybind(name, keyName(K.Key), K.Active)
        end
    end

    function K:SetKey(key)
        K.Key = key
        KeyBtn.Text = "[" .. keyName(key) .. "]"
        autoSave()
        refreshKeybindsWindow()
    end

    function K:SetActive(v)
        K.Active = v and true or false
        refreshKeybindsWindow()
    end

    function K:GetValue()
        return { Key = K.Key and K.Key.Name or nil, Mode = K.Mode }
    end

    function K:SetValue(data, skipSave)
        if type(data) == "table" then
            if data.Key then
                local s, k = pcall(function() return Enum.KeyCode[data.Key] end)
                if not s or not k then
                    s, k = pcall(function() return Enum.UserInputType[data.Key] end)
                end
                if s and k then K.Key = k end
            end
            if data.Mode then
                K.Mode = data.Mode
            end
            KeyBtn.Text = "[" .. keyName(K.Key) .. "]"
            refreshKeybindsWindow()
        end
    end

    KeyBtn.MouseButton1Click:Connect(function()
        K.Editing = true
        KeyBtn.Text = "[...]"
        KeyBtn.TextColor3 = C.Accent
    end)

    local modeMenuOpen = false
    KeyBtn.MouseButton2Click:Connect(function()
        if K.Editing or modeMenuOpen then return end
        modeMenuOpen = true
        openModeMenu(KeyBtn,
            function() return K.Mode end,
            function(m)
                K.Mode = m
                if K.Active then
                    K.Active = false
                    callback(false)
                    refreshKeybindsWindow()
                end
                autoSave()
            end,
            function() modeMenuOpen = false end)
    end)

    KeyBtn.MouseEnter:Connect(function()
        if not K.Editing then Tween(KeyBtn, { TextColor3 = C.Text }, 0.15) end
    end)
    KeyBtn.MouseLeave:Connect(function()
        if not K.Editing then Tween(KeyBtn, { TextColor3 = C.TextDim }, 0.15) end
    end)

    bind(UIS.InputBegan, function(input, gameProcessed)
        if K.Editing then
            local key = input.KeyCode
            if key == Enum.KeyCode.Unknown and (input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3) then
                key = input.UserInputType
            end

            if key == Enum.KeyCode.Escape then
                K.Editing = false
                KeyBtn.Text = "[" .. keyName(K.Key) .. "]"
                KeyBtn.TextColor3 = C.TextDim
                return
            end

            if key ~= Enum.KeyCode.Unknown then
                K:SetKey(key)
                K.Editing = false
                KeyBtn.TextColor3 = C.TextDim
            end
            return
        end

        if gameProcessed then return end
        if not K.Key or (input.KeyCode ~= K.Key and input.UserInputType ~= K.Key) then return end

        if K.Mode == "Toggle" then
            K.Active = not K.Active
            refreshKeybindsWindow()
            callback(K.Active)
        elseif K.Mode == "Hold" then
            K.Active = true
            refreshKeybindsWindow()
            callback(true)
        end
    end)

    bind(UIS.InputEnded, function(input)
        if K.Key and (input.KeyCode == K.Key or input.UserInputType == K.Key) and K.Mode == "Hold" then
            K.Active = false
            refreshKeybindsWindow()
            callback(false)
        end
    end)

    task.spawn(function()
        for _ = 1, 40 do
            if Library.KeybindsWindow then break end
            task.wait(0.1)
        end
        refreshKeybindsWindow()
    end)

    if not config.NoSave then
        ConfigSystem.Elements[configPath] = K
    end

    register(name, section, Frame)

    return K
end

function Library:CreateInput(section, config)
    config = config or {}
    local name = config.Name or "Input"
    local default = config.Default or ""
    local placeholder = config.Placeholder or "Enter text..."
    local callback = config.Callback or function() end

    local configPath = pathFor(section, name)

    local I = { Value = default, Callback = callback, ConfigPath = configPath }

    local Frame = rowCard(section.Container, 56)

    local Label = New("TextLabel", {
        Parent = Frame,
        Position = UDim2.new(0, 10, 0, 5),
        Size = UDim2.new(1, -20, 0, 16),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = C.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.Gotham
    })

    local Box = New("TextBox", {
        Parent = Frame,
        Position = UDim2.new(0, 8, 0, 25),
        Size = UDim2.new(1, -16, 0, 24),
        BackgroundColor3 = C.Chip,
        BorderSizePixel = 0,
        Text = default,
        PlaceholderText = placeholder,
        TextColor3 = C.Text,
        PlaceholderColor3 = C.TextDim,
        TextSize = 12,
        Font = Enum.Font.GothamMedium,
        ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    Corner(Box, 6)
    New("UIPadding", { Parent = Box, PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) })

    local BoxStroke = New("UIStroke", {
        Parent = Box,
        Color = C.Border,
        Thickness = 1,
        Transparency = 0.2
    })

    Box.Focused:Connect(function()
        Tween(BoxStroke, { Color = C.Accent, Transparency = 0 }, 0.15)
    end)

    Box.FocusLost:Connect(function()
        Tween(BoxStroke, { Color = C.Border, Transparency = 0.2 }, 0.15)
        I:SetValue(Box.Text)
    end)

    Box.MouseEnter:Connect(function()
        Tween(Box, { BackgroundColor3 = Color3.fromRGB(44, 44, 58) }, 0.15)
    end)

    Box.MouseLeave:Connect(function()
        Tween(Box, { BackgroundColor3 = C.Chip }, 0.15)
    end)

    if config.Tooltip then
        Library:AttachTooltip(Box, config.Tooltip)
        Library:AttachTooltip(Label, config.Tooltip)
    end

    function I:SetValue(v, skipSave)
        I.Value = v
        Box.Text = v
        callback(v)
        if not skipSave then
            autoSave()
        end
    end

    function I:GetValue()
        return I.Value
    end

    if not config.NoSave then
        ConfigSystem.Elements[configPath] = I
    end

    register(name, section, Frame)

    return I
end

function Library:CreateKeybinds()
    if Library.IsMobile then
        local stub = { Items = {}, HeaderLetters = {} }
        function stub:SetVisible() end

        function stub:UpdateKeybind() end

        Library.KeybindsWindow = stub
        return stub
    end

    local KeybindsGui = New("ScreenGui", {
        Name = "rubyazlKeybinds",
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false
    })
    mount(KeybindsGui)

    local KeybindsFrame = New("CanvasGroup", {
        Name = "KeybindsFrame",
        Parent = KeybindsGui,
        Position = UDim2.new(0, 12, 0.5, -150),
        Size = UDim2.new(0, 190, 0, 0),
        BackgroundColor3 = C.TopBar,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        GroupTransparency = 1
    })

    Corner(KeybindsFrame, 12)
    New("UIStroke", { Parent = KeybindsFrame, Color = C.Border, Thickness = 1, Transparency = 0.15 })

    local Header = New("Frame", {
        Name = "Header",
        Parent = KeybindsFrame,
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundTransparency = 1
    })

    local HeaderText = "keybinds"
    local letterSpacing = 9
    local headerContainer = New("Frame", {
        Name = "HeaderContainer",
        Parent = Header,
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(0, #HeaderText * letterSpacing, 1, 0),
        BackgroundTransparency = 1
    })

    local headerLetters = makeLetters(headerContainer, HeaderText, letterSpacing, 14)

    New("Frame", {
        Name = "Separator",
        Parent = KeybindsFrame,
        Position = UDim2.new(0, 10, 0, 32),
        Size = UDim2.new(1, -20, 0, 1),
        BackgroundColor3 = C.Border,
        BorderSizePixel = 0
    })

    local KeybindsAccentLine = New("Frame", {
        Name = "AccentLine",
        Parent = KeybindsFrame,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -24, 0, 2),
        BackgroundColor3 = C.Accent,
        BorderSizePixel = 0
    })

    New("UIGradient", {
        Parent = KeybindsAccentLine,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.5, 0.2),
            NumberSequenceKeypoint.new(1, 1)
        })
    })

    table.insert(Library.AccentElements, KeybindsAccentLine)

    local Container = New("Frame", {
        Name = "Container",
        Parent = KeybindsFrame,
        Position = UDim2.new(0, 0, 0, 38),
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y
    })

    New("UIListLayout", {
        Parent = Container,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2)
    })

    New("UIPadding", {
        Parent = Container,
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 8)
    })

    local KB = {
        Frame = KeybindsFrame,
        Container = Container,
        Items = {},
        HeaderLetters = headerLetters
    }

    local kDragging, kDragInput, kDragStart, kStartPos

    KeybindsFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            kDragging = true
            kDragStart = input.Position
            kStartPos = KeybindsFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    kDragging = false
                end
            end)
        end
    end)

    bind(UIS.InputChanged, function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            kDragInput = input
        end
    end)

    bind(RS.RenderStepped, function(dt)
        if kDragging and kDragInput then
            local delta = kDragInput.Position - kDragStart
            local target = UDim2.new(kStartPos.X.Scale, kStartPos.X.Offset + delta.X, kStartPos.Y.Scale,
                kStartPos.Y.Offset + delta.Y)
            KeybindsFrame.Position = KeybindsFrame.Position:Lerp(target, math.clamp(dt * 22, 0, 1))
        end
    end)

    function KB:UpdateKeybind(name, key, active)
        for _, item in pairs(KB.Items) do
            if item.Name == name then
                item:Update(key, active)
                return
            end
        end

        local ItemFrame = New("Frame", {
            Parent = Container,
            Size = UDim2.new(1, 0, 0, 22),
            BackgroundTransparency = 1
        })

        local AccentBar = New("Frame", {
            Name = "AccentBar",
            Parent = ItemFrame,
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 0, 0.5, 0),
            Size = UDim2.new(0, 3, 0, 12),
            BackgroundColor3 = C.Accent,
            BorderSizePixel = 0,
            Visible = active or false
        })
        Corner(AccentBar, 99)
        table.insert(Library.AccentElements, AccentBar)

        local NameLabel = New("TextLabel", {
            Name = "NameLabel",
            Parent = ItemFrame,
            Position = UDim2.new(0, 10, 0, 0),
            Size = UDim2.new(1, -66, 1, 0),
            BackgroundTransparency = 1,
            Text = name,
            TextColor3 = active and Color3.fromRGB(255, 255, 255) or C.TextDim,
            TextSize = 12,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd
        })

        local KeyLabel = New("TextLabel", {
            Name = "KeyLabel",
            Parent = ItemFrame,
            Position = UDim2.new(1, -54, 0, 0),
            Size = UDim2.new(0, 54, 1, 0),
            BackgroundTransparency = 1,
            Text = key or "None",
            TextColor3 = C.Accent,
            TextSize = 11,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Right,
            TextTruncate = Enum.TextTruncate.AtEnd
        })

        local item = {
            Name = name,
            Frame = ItemFrame,
            AccentBar = AccentBar,
            NameLabel = NameLabel,
            KeyLabel = KeyLabel
        }

        function item:Update(newKey, newActive)
            KeyLabel.Text = newKey or "None"
            AccentBar.Visible = newActive and true or false
            Tween(NameLabel, {
                TextColor3 = newActive and Color3.fromRGB(255, 255, 255) or C.TextDim
            }, 0.2, Enum.EasingStyle.Sine)
        end

        function item:Remove()
            ItemFrame:Destroy()
            for i, v in pairs(KB.Items) do
                if v == item then
                    table.remove(KB.Items, i)
                    break
                end
            end
        end

        table.insert(KB.Items, item)
    end

    function KB:RemoveKeybind(name)
        for _, item in pairs(KB.Items) do
            if item.Name == name then
                item:Remove()
                break
            end
        end
    end

    function KB:Clear()
        for _, item in pairs(KB.Items) do
            item.Frame:Destroy()
        end
        KB.Items = {}
    end

    function KB:SetVisible(visible)
        KeybindsGui.Enabled = visible
    end

    Library.KeybindsWindow = KB

    if Library.KeybindToggles then
        for _, toggle in pairs(Library.KeybindToggles) do
            if toggle.HasKeybind and toggle.KeybindKey then
                KB:UpdateKeybind(toggle.Name, keyName(toggle.KeybindKey), toggle.Value)
            end
        end
    end

    Tween(KeybindsFrame, { GroupTransparency = 0 }, 0.5, Enum.EasingStyle.Sine)

    return KB
end

function Library:CreateColorPicker(section, config)
    config = config or {}
    local name = config.Name or "Color"
    local default = config.Default or Color3.fromRGB(124, 140, 255)
    local callback = config.Callback or function() end

    local configPath = pathFor(section, name)

    local CP = { Color = default, Hue = 0, Sat = 0, Val = 0, Callback = callback, ConfigPath = configPath, Open = false }
    CP.Hue, CP.Sat, CP.Val = default:ToHSV()

    local Frame = rowCard(section.Container, 30)

    New("TextLabel", {
        Parent = Frame,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -56, 1, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = C.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Font = Enum.Font.Gotham
    })

    local ColorBox = New("Frame", {
        Parent = Frame,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.fromOffset(30, 18),
        BackgroundColor3 = default,
        BorderSizePixel = 0
    })
    Corner(ColorBox, 6)
    New("UIStroke", { Parent = ColorBox, Color = Color3.fromRGB(255, 255, 255), Thickness = 1, Transparency = 0.8 })

    local Btn = New("TextButton", {
        Parent = Frame,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = ""
    })

    hoverCard(Frame, Btn)

    if config.Tooltip then
        Library:AttachTooltip(Btn, config.Tooltip)
    end

    local PickerGui = New("ScreenGui", {
        Name = "ColorPicker",
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false
    })
    mount(PickerGui)

    local PickerFrame = New("Frame", {
        Name = "PickerFrame",
        Parent = PickerGui,
        Position = UDim2.new(0.5, -100, 0.5, -114),
        Size = UDim2.new(0, 200, 0, 232),
        BackgroundColor3 = C.Section,
        BorderSizePixel = 0,
        Visible = false
    })
    Corner(PickerFrame, 12)
    New("UIStroke", { Parent = PickerFrame, Color = C.Accent, Thickness = 1, Transparency = 0.5 })
    local PickerScale = New("UIScale", { Parent = PickerFrame, Scale = 1 })

    New("TextLabel", {
        Parent = PickerFrame,
        Position = UDim2.new(0, 12, 0, 6),
        Size = UDim2.new(1, -24, 0, 18),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = C.Text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Font = Enum.Font.GothamBold
    })

    local SatVal = New("ImageButton", {
        Name = "SatVal",
        Parent = PickerFrame,
        Position = UDim2.new(0, 10, 0, 30),
        Size = UDim2.new(0, 160, 0, 160),
        BackgroundColor3 = Color3.fromHSV(CP.Hue, 1, 1),
        BorderSizePixel = 0,
        Image = "rbxassetid://8180999986",
        ImageColor3 = Color3.new(0, 0, 0),
        AutoButtonColor = false
    })
    Corner(SatVal, 6)

    local SatValCursor = New("Frame", {
        Name = "Cursor",
        Parent = SatVal,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(CP.Sat, 1 - CP.Val),
        Size = UDim2.fromOffset(10, 10),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0
    })
    Corner(SatValCursor, 99)
    New("UIStroke", { Parent = SatValCursor, Color = Color3.new(0, 0, 0), Thickness = 2 })

    local HueSlider = New("ImageButton", {
        Name = "Hue",
        Parent = PickerFrame,
        Position = UDim2.new(0, 175, 0, 30),
        Size = UDim2.new(0, 15, 0, 160),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Image = "rbxassetid://8180989234",
        ScaleType = Enum.ScaleType.Crop,
        AutoButtonColor = false
    })
    Corner(HueSlider, 99)

    local HueCursor = New("Frame", {
        Name = "Cursor",
        Parent = HueSlider,
        Position = UDim2.fromScale(0, CP.Hue),
        Size = UDim2.new(1, 0, 0, 3),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0
    })
    Corner(HueCursor, 99)

    local HexBox = New("TextBox", {
        Name = "Hex",
        Parent = PickerFrame,
        Position = UDim2.new(0, 10, 0, 199),
        Size = UDim2.new(1, -20, 0, 22),
        BackgroundColor3 = C.Chip,
        BorderSizePixel = 0,
        Text = "#" .. default:ToHex():upper(),
        TextColor3 = C.Text,
        TextSize = 12,
        Font = Enum.Font.Code,
        ClearTextOnFocus = false
    })
    Corner(HexBox, 6)
    New("UIPadding", { Parent = HexBox, PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) })

    local function refreshVisuals()
        CP.Color = Color3.fromHSV(CP.Hue, CP.Sat, CP.Val)
        ColorBox.BackgroundColor3 = CP.Color
        SatVal.BackgroundColor3 = Color3.fromHSV(CP.Hue, 1, 1)
        HexBox.Text = "#" .. CP.Color:ToHex():upper()
        SatValCursor.Position = UDim2.fromScale(CP.Sat, 1 - CP.Val)
        HueCursor.Position = UDim2.fromScale(0, CP.Hue)
    end

    function CP:UpdateColor(skipSave)
        refreshVisuals()
        callback(CP.Color)
        if not skipSave then
            autoSave()
        end
    end

    function CP:SetValue(color, skipSave)
        if typeof(color) == "Color3" then
            CP.Hue, CP.Sat, CP.Val = color:ToHSV()
        elseif typeof(color) == "table" and #color == 3 then
            CP.Hue, CP.Sat, CP.Val = color[1], color[2], color[3]
        end

        refreshVisuals()
        callback(CP.Color)

        if not skipSave then
            autoSave()
        end
    end

    function CP:GetValue() return { CP.Hue, CP.Sat, CP.Val } end

    local function isPointer(input)
        return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
    end

    local function isMove(input)
        return input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch
    end

    local function setSatVal(input)
        local pos = (Vector2.new(input.Position.X, input.Position.Y) - SatVal.AbsolutePosition) / SatVal.AbsoluteSize
        CP.Sat = math.clamp(pos.X, 0, 1)
        CP.Val = math.clamp(1 - pos.Y, 0, 1)
        CP:UpdateColor()
    end

    local function setHue(input)
        local pos = (input.Position.Y - HueSlider.AbsolutePosition.Y) / HueSlider.AbsoluteSize.Y
        CP.Hue = math.clamp(pos, 0, 1)
        CP:UpdateColor()
    end

    local satValDragging = false
    SatVal.InputBegan:Connect(function(input)
        if isPointer(input) then
            satValDragging = true
            setSatVal(input)
        end
    end)
    SatVal.InputEnded:Connect(function(input)
        if isPointer(input) then satValDragging = false end
    end)

    local hueDragging = false
    HueSlider.InputBegan:Connect(function(input)
        if isPointer(input) then
            hueDragging = true
            setHue(input)
        end
    end)
    HueSlider.InputEnded:Connect(function(input)
        if isPointer(input) then hueDragging = false end
    end)

    bind(UIS.InputChanged, function(input)
        if not isMove(input) then return end
        if satValDragging then
            setSatVal(input)
        elseif hueDragging then
            setHue(input)
        end
    end)

    HexBox.FocusLost:Connect(function()
        pcall(function()
            local hex = HexBox.Text:gsub("#", "")
            CP:SetValue(Color3.fromHex(hex))
        end)
    end)

    function CP:Close()
        CP.Open = false
        PickerFrame.Visible = false
    end

    Btn.MouseButton1Click:Connect(function()
        if CP.Open then
            CP:Close()
            return
        end

        closePickers()

        local boxPos = ColorBox.AbsolutePosition
        local screen = PickerGui.AbsoluteSize
        local x = math.clamp(boxPos.X - 210, 6, math.max(6, screen.X - 206))
        local y = math.clamp(boxPos.Y - 20, 6, math.max(6, screen.Y - 238))
        PickerFrame.Position = UDim2.fromOffset(x, y)

        CP.Open = true
        PickerScale.Scale = 0.9
        PickerFrame.Visible = true
        Tween(PickerScale, { Scale = 1 }, 0.3, Enum.EasingStyle.Back)
    end)

    bind(UIS.InputBegan, function(input)
        if CP.Open and isPointer(input) then
            local mousePos = Vector2.new(input.Position.X, input.Position.Y)
            local framePos = PickerFrame.AbsolutePosition
            local frameSize = PickerFrame.AbsoluteSize
            local boxP = Frame.AbsolutePosition
            local boxS = Frame.AbsoluteSize

            local insidePicker = not (mousePos.X < framePos.X or mousePos.X > framePos.X + frameSize.X or
                mousePos.Y < framePos.Y or mousePos.Y > framePos.Y + frameSize.Y)
            local insideRow = not (mousePos.X < boxP.X or mousePos.X > boxP.X + boxS.X or
                mousePos.Y < boxP.Y or mousePos.Y > boxP.Y + boxS.Y)

            if not insidePicker and not insideRow then
                CP:Close()
            end
        end
    end)

    if not config.NoSave then
        ConfigSystem.Elements[configPath] = CP
    end

    if not Library.ColorPickers then
        Library.ColorPickers = {}
    end
    table.insert(Library.ColorPickers, CP)

    register(name, section, Frame)

    return CP
end

function Library:CreateConfigSection(category, column)
    local sec = Library:CreateSection(category, "Configs", column or "right")

    local nameInput = Library:CreateInput(sec, {
        Name = "Config name",
        Default = ConfigSystem.CurrentConfig,
        Placeholder = "my config...",
        NoSave = true
    })

    local dropdown
    dropdown = Library:CreateDropdown(sec, {
        Name = "Saved configs",
        Options = listConfigs(),
        Default = "",
        NoSave = true,
        Callback = function(v)
            if v and v ~= "" then
                nameInput:SetValue(v, true)
            end
        end
    })

    local function refresh()
        dropdown:Refresh(listConfigs())
    end

    Library:CreateButton(sec, {
        Name = "Save config",
        Callback = function()
            local n = nameInput:GetValue()
            if n == "" then
                Library:CreateNotification({ Message = "Enter a config name first", Type = "warning" })
                return
            end
            ConfigSystem.CurrentConfig = n
            if saveConfig(n) then
                Library:CreateNotification({ Message = "Saved config: " .. n, Type = "success" })
            else
                Library:CreateNotification({ Message = "Could not save config", Type = "error" })
            end
            refresh()
        end
    })

    Library:CreateButton(sec, {
        Name = "Load config",
        Callback = function()
            local n = nameInput:GetValue()
            if loadConfig(n) then
                Library:CreateNotification({ Message = "Loaded config: " .. n, Type = "success" })
            else
                Library:CreateNotification({ Message = "Config not found: " .. n, Type = "error" })
            end
        end
    })

    Library:CreateButton(sec, {
        Name = "Delete config",
        Callback = function()
            local n = nameInput:GetValue()
            if deleteConfig(n) then
                Library:CreateNotification({ Message = "Deleted config: " .. n, Type = "warning" })
            else
                Library:CreateNotification({ Message = "Config not found: " .. n, Type = "error" })
            end
            refresh()
        end
    })

    Library:CreateButton(sec, { Name = "Refresh list", Callback = refresh })

    return sec
end

local function restackNotifications()
    local y = 0
    for i = #Library.Notifications, 1, -1 do
        local n = Library.Notifications[i]
        if n and n.Parent then
            Tween(n, { Position = UDim2.new(1, -16, 1, -(16 + y)) }, 0.35, Enum.EasingStyle.Quint)
            y = y + n.AbsoluteSize.Y + 8
        end
    end
end

function Library:CreateNotification(config)
    config = config or {}
    local message = config.Message or "Notification"
    local duration = config.Duration or 3
    local soundType = config.Sound or "Enable"

    local typeColors = {
        success = Color3.fromRGB(90, 220, 140),
        warning = Color3.fromRGB(255, 190, 80),
        error = Color3.fromRGB(255, 95, 110)
    }
    local typeKey = tostring(config.Type or ""):lower()
    local barColor = typeColors[typeKey] or C.Accent
    local titleText = typeKey ~= "" and (typeKey:sub(1, 1):upper() .. typeKey:sub(2)) or "Notice"

    Library:PlayNotificationSound(soundType)

    if not Library.NotificationGui or not Library.NotificationGui.Parent then
        local NotifGui = New("ScreenGui", {
            Name = "rubyazlNotifications",
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            ResetOnSpawn = false
        })
        mount(NotifGui)

        Library.NotificationGui = NotifGui
        Library.Notifications = {}
    end

    local textSize = TextService:GetTextSize(message, 12, Enum.Font.GothamMedium, Vector2.new(300, 1000))
    local notifWidth = math.max(190, textSize.X + 44)
    local notifHeight = math.max(46, textSize.Y + 32)

    local Card = New("CanvasGroup", {
        Name = "Notification",
        Parent = Library.NotificationGui,
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, notifWidth + 30, 1, -16),
        Size = UDim2.fromOffset(notifWidth, notifHeight),
        BackgroundColor3 = Color3.fromRGB(18, 18, 24),
        BorderSizePixel = 0,
        GroupTransparency = 1
    })
    Corner(Card, 10)
    New("UIStroke", { Parent = Card, Color = C.Border, Thickness = 1, Transparency = 0.1 })

    New("Frame", {
        Name = "AccentBar",
        Parent = Card,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(0, 3, 1, 0),
        BackgroundColor3 = barColor,
        BorderSizePixel = 0
    })

    New("TextLabel", {
        Name = "Title",
        Parent = Card,
        Position = UDim2.new(0, 14, 0, 6),
        Size = UDim2.new(1, -24, 0, 12),
        BackgroundTransparency = 1,
        Text = titleText:upper(),
        TextColor3 = barColor,
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    New("TextLabel", {
        Name = "Message",
        Parent = Card,
        Position = UDim2.new(0, 14, 0, 19),
        Size = UDim2.new(1, -24, 1, -26),
        BackgroundTransparency = 1,
        Text = message,
        TextColor3 = Color3.fromRGB(230, 230, 240),
        TextSize = 12,
        Font = Enum.Font.GothamMedium,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top
    })

    local Progress = New("Frame", {
        Name = "Progress",
        Parent = Card,
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 2),
        BackgroundColor3 = barColor,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0
    })

    table.insert(Library.Notifications, Card)

    task.spawn(function()
        Tween(Card, { GroupTransparency = 0 }, 0.3, Enum.EasingStyle.Quad)
        restackNotifications()
        Tween(Progress, { Size = UDim2.new(0, 0, 0, 2) }, duration, Enum.EasingStyle.Linear)

        task.wait(duration)

        Tween(Card, { GroupTransparency = 1, Position = UDim2.new(1, notifWidth + 30, Card.Position.Y.Scale, Card.Position.Y.Offset) },
            0.3, Enum.EasingStyle.Quad)

        task.wait(0.3)

        for i, notif in pairs(Library.Notifications) do
            if notif == Card then
                table.remove(Library.Notifications, i)
                break
            end
        end

        Card:Destroy()
        restackNotifications()
    end)
end

function Library:Destroy()
    for _, c in pairs(Library.Connections) do
        pcall(function() c:Disconnect() end)
    end
    Library.Connections = {}

    for _, g in pairs(Library.Guis) do
        pcall(function() g:Destroy() end)
    end
    Library.Guis = {}

    Library.Windows = nil
    Library.KeybindsWindow = nil
    Library.NotificationGui = nil
    Library.Notifications = {}
    Library.ColorPickers = nil
    Library.ModeMenus = nil
    Library.KeybindToggles = nil
    hideTooltip()
end

Library.Unload = Library.Destroy

return Library
