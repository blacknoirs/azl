local Library = {}
local TS = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local HS = game:GetService("HttpService")

Library.IsMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled

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

        local saveCount = 0
        for path, element in pairs(ConfigSystem.Elements) do
            if element.GetValue then
                local ok, value = pcall(function() return element:GetValue() end)
                if ok then
                    configData.elements[path] = value
                    saveCount = saveCount + 1
                else
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
    if not readfile then
        return false
    end

    local success = pcall(function()
        local configPath = ConfigSystem.FolderName .. "/" .. configName .. ".json"

        if not isfile(configPath) then
            return false
        end

        local fileContent = readfile(configPath)
        local configData = HS:JSONDecode(fileContent)

        ConfigSystem.CurrentConfig = configName

        local loadCount, failCount = 0, 0
        for path, value in pairs(configData.elements or {}) do
            local element = ConfigSystem.Elements[path]
            if element and element.SetValue then
                local ok, err = pcall(function() element:SetValue(value, true) end)
                if ok then
                    loadCount = loadCount + 1
                else
                    failCount = failCount + 1
                end
            end
        end
    end)

    return success
end

local function deleteConfig(configName)
    if not delfile then return false end

    local success = pcall(function()
        local configPath = ConfigSystem.FolderName .. "/" .. configName .. ".json"
        if isfile(configPath) then
            delfile(configPath)
            return true
        end
        return false
    end)

    return success
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

local function autoSave(path, value)
    if not ConfigSystem.AutoSave then return end
    saveConfig(ConfigSystem.CurrentConfig)
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

    spawn(function()
        for soundName, url in pairs(Library.NotificationSounds.URLs) do
            pcall(function()
                local filename = "rubyazl_notif_" .. soundName:lower() .. ".wav"

                local success, data = pcall(function()
                    return game:HttpGet(url, true)
                end)

                if not success or not data then
                    return
                end

                if not writefile then
                    return
                end

                writefile(filename, data)

                local getasset = getcustomasset or getsynasset or function(path)
                    return "rbxasset://" .. path
                end

                if not getasset then
                    return
                end

                local sound = Instance.new("Sound")
                local assetId = getasset(filename)

                if not assetId or assetId == "" then
                    return
                end

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
    BG = Color3.fromRGB(12, 12, 16),
    TopBar = Color3.fromRGB(15, 15, 20),
    Sidebar = Color3.fromRGB(14, 14, 19),
    Section = Color3.fromRGB(20, 20, 27),
    Element = Color3.fromRGB(28, 28, 37),
    Accent = Color3.fromHex("6E8BFF"),
    Text = Color3.fromRGB(225, 226, 235),
    TextDim = Color3.fromRGB(128, 130, 148),
    Border = Color3.fromRGB(38, 38, 50),
    SliderBg = Color3.fromRGB(36, 36, 47),
    Chip = Color3.fromRGB(34, 34, 44)
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

-- ICON SYSTEM ------------------------------------------------------------
-- Accepted icon formats:
--   123456789                          (asset id number)
--   "123456789"                        (asset id string)
--   "rbxassetid://123456789"           (asset uri)
--   "https://example.com/icon.png"     (downloaded + cached, needs executor file functions)
--   "myfolder/icon.png"                (file in your executor workspace)
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

function Library:UpdateAccentColor(newColor)
    C.Accent = newColor

    local h, s, v = newColor:ToHSV()
    local glowColor = Color3.fromHSV(h, math.max(s - 0.2, 0), math.min(v + 0.3, 1))

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
        end
    end

    if Library.Windows then
        for _, window in pairs(Library.Windows) do
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
                        else
                        end
                    end
                else
                end
            else
            end

            if window.BuildLabel then
                pcall(function()
                    if window.BuildLabel.Parent then
                        window.BuildLabel.Text = string.format('build: <font color="rgb(%d,%d,%d)">alpha</font>',
                            math.floor(newColor.R * 255),
                            math.floor(newColor.G * 255),
                            math.floor(newColor.B * 255))
                    end
                end)
            end
            if window.UserLabel and window.PlayerName then
                pcall(function()
                    if window.UserLabel.Parent then
                        window.UserLabel.Text = string.format('user: <font color="rgb(%d,%d,%d)">%s</font>',
                            math.floor(newColor.R * 255),
                            math.floor(newColor.G * 255),
                            math.floor(newColor.B * 255),
                            window.PlayerName)
                    end
                end)
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

local function New(c, p)
    local o = Instance.new(c)
    for k, v in pairs(p) do o[k] = v end
    return o
end

local function Tween(o, p, t, s)
    s = s or Enum.EasingStyle.Quart
    TS:Create(o, TweenInfo.new(t or 0.2, s, Enum.EasingDirection.Out), p):Play()
end

-- TOOLTIP SYSTEM ---------------------------------------------------------
-- Any element config can take  Tooltip = "text"  (Toggle, Slider, Dropdown, Button, Input, ColorPicker)
-- You can also do  Library:AttachTooltip(someGuiObject, "text")  yourself.
local TooltipGui, TooltipFrame, TooltipLabel, TooltipStroke
local tooltipToken = 0



function Library:AttachTooltip(guiObject, text)
end

-- CreateWindow config (all optional):
--   Icon       = 123456789 / "rbxassetid://..." / "https://.../icon.png" / "folder/icon.png"
--   IconTint   = true (follows accent) / Color3 (fixed color) / nil (original image colors)
--   Title      = "ReEvolution"   (animated logo text)
--   WatermarkText = "rubyazl"
--   ToggleKey  = Enum.KeyCode.K
function Library:CreateWindow(config)
    config = config or {}

    local SG = New("ScreenGui", {
        Name = "rubyazlUI",
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false
    })

    if syn and syn.protect_gui then
        syn.protect_gui(SG)
        SG.Parent = game:GetService("CoreGui")
    elseif gethui then
        SG.Parent = gethui()
    else
        SG.Parent = game:GetService("CoreGui")
    end

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
        Size = UDim2.fromOffset(800, 460),
        BackgroundColor3 = C.BG,
        BorderSizePixel = 0,
        GroupTransparency = 1
    })

    New("UICorner", { Parent = Main, CornerRadius = UDim.new(0, 12) })

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

    local MainUIScale = New("UIScale", {
        Parent = Main,
        Scale = 1
    })

    local TopBar = New("Frame", {
        Name = "TopBar",
        Parent = Main,
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = C.TopBar,
        BorderSizePixel = 0,
        ZIndex = 5
    })

    New("UICorner", { Parent = TopBar, CornerRadius = UDim.new(0, 12) })

    New("Frame", {
        Name = "TopBarFill",
        Parent = TopBar,
        Position = UDim2.new(0, 0, 1, -12),
        Size = UDim2.new(1, 0, 0, 12),
        BackgroundColor3 = C.TopBar,
        BorderSizePixel = 0
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
        Position = UDim2.new(0, 16, 0, 0),
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

    RS.Heartbeat:Connect(function(dt)
        if Main.Visible then
            MainStrokeGradient.Rotation = (MainStrokeGradient.Rotation + dt * 50) % 360
            TopAccentGradient.Offset = Vector2.new(math.sin(os.clock() * 1.2) * 0.25, 0)
        end
    end)

    local LogoMark = New("Frame", {
        Name = "LogoMark",
        Parent = TopBar,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 12, 0.5, 0),
        Size = UDim2.fromOffset(22, 22),
        BackgroundColor3 = C.Accent,
        BorderSizePixel = 0
    })

    New("UICorner", { Parent = LogoMark, CornerRadius = UDim.new(0, 6) })

    local LogoMarkDot = New("Frame", {
        Parent = LogoMark,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.fromOffset(8, 8),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0
    })

    New("UICorner", { Parent = LogoMarkDot, CornerRadius = UDim.new(1, 0) })

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

    local logoText = config.Title or "ReEvolution"

    local LogoContainer = New("Frame", {
        Parent = TopBar,
        Position = UDim2.new(0, 42, 0, 0),
        Size = UDim2.new(0, #logoText * 10, 1, 0),
        BackgroundTransparency = 1
    })

    local letters = {}
    local baseColor = C.Accent
    local glowColor = Color3.fromRGB(220, 200, 255)

    for i = 1, #logoText do
        local char = logoText:sub(i, i)
        local letter = New("TextLabel", {
            Parent = LogoContainer,
            Position = UDim2.new(0, (i - 1) * 10, 0, 0),
            Size = UDim2.new(0, 10, 1, 0),
            BackgroundTransparency = 1,
            Text = char,
            TextColor3 = baseColor,
            TextSize = 16,
            TextXAlignment = Enum.TextXAlignment.Center,
            Font = Enum.Font.Code
        })
        table.insert(letters, letter)
    end

    spawn(function()
        while true do
            for i, letter in ipairs(letters) do
                spawn(function()
                    local h, s, v = C.Accent:ToHSV()
                    local currentGlow = Color3.fromHSV(h, math.max(s - 0.2, 0), math.min(v + 0.3, 1))

                    Tween(letter, { TextColor3 = currentGlow }, 0.3, Enum.EasingStyle.Sine)
                    task.wait(0.3)
                    Tween(letter, { TextColor3 = C.Accent }, 0.4, Enum.EasingStyle.Sine)
                end)
                task.wait(0.08)
            end
            task.wait(1.5)
        end
    end)

    local TopTabs = New("Frame", {
        Name = "TopTabs",
        Parent = TopBar,
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 0),
        Size = UDim2.new(0, 420, 1, 0),
        BackgroundTransparency = 1
    })

    local TabHighlight = New("Frame", {
        Name = "TabHighlight",
        Parent = TopTabs,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 80, 0, 26),
        BackgroundColor3 = C.Element,
        BorderSizePixel = 0,
        Visible = false
    })

    New("UICorner", { Parent = TabHighlight, CornerRadius = UDim.new(0, 8) })
    New("UIStroke", { Parent = TabHighlight, Color = C.Border, Thickness = 1, Transparency = 0.4 })

    local CloseBtn = New("TextButton", {
        Name = "CloseButton",
        Parent = TopBar,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.fromOffset(24, 24),
        BackgroundColor3 = Color3.fromRGB(70, 28, 38),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "✕",
        TextColor3 = C.TextDim,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false
    })

    New("UICorner", { Parent = CloseBtn, CornerRadius = UDim.new(0, 8) })

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
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(1, -204, 0.5, 0),
        Size = UDim2.new(0, 160, 0, 24),
        BackgroundColor3 = C.Element,
        BorderSizePixel = 0
    })

    New("UICorner", { Parent = SearchContainer, CornerRadius = UDim.new(0, 8) })

    local SearchStroke = New("UIStroke", {
        Parent = SearchContainer,
        Color = C.Accent,
        Thickness = 1,
        Transparency = 0.7
    })

    table.insert(Library.AccentElements, SearchStroke)

    spawn(function()
        while true do
            Tween(SearchStroke, { Transparency = 0.4 }, 1.5, Enum.EasingStyle.Sine)
            task.wait(1.5)
            Tween(SearchStroke, { Transparency = 0.7 }, 1.5, Enum.EasingStyle.Sine)
            task.wait(1.5)
        end
    end)

    local SearchIcon = New("TextLabel", {
        Name = "SearchIcon",
        Parent = SearchContainer,
        Position = UDim2.new(0, 7, 0, 0),
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
        Position = UDim2.new(0, 27, 0, 0),
        Size = UDim2.new(1, -33, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        PlaceholderText = "Search...",
        PlaceholderColor3 = C.TextDim,
        TextColor3 = C.Text,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        TextTransparency = 0
    })

    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        SearchBox.TextTransparency = 0.3
        Tween(SearchBox, { TextTransparency = 0 }, 0.2, Enum.EasingStyle.Sine)
    end)

    local SearchResults = New("Frame", {
        Name = "SearchResults",
        Parent = SearchContainer,
        Position = UDim2.new(0, 0, 1, 6),
        AnchorPoint = Vector2.new(0, 0),
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = C.Element,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 10
    })

    New("UICorner", { Parent = SearchResults, CornerRadius = UDim.new(0, 8) })
    New("UIStroke", {
        Parent = SearchResults,
        Color = C.Accent,
        Thickness = 1,
        Transparency = 0.6
    })

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
        Tween(SearchContainer, { BackgroundColor3 = Color3.fromRGB(36, 36, 48) }, 0.15)
        Tween(SearchStroke, { Transparency = 0.2 }, 0.15)
    end)

    SearchContainer.MouseLeave:Connect(function()
        if not SearchBox:IsFocused() then
            Tween(SearchContainer, { BackgroundColor3 = C.Element }, 0.15)
            Tween(SearchStroke, { Transparency = 0.7 }, 0.15)
        end
    end)

    SearchBox.Focused:Connect(function()
        Tween(SearchContainer, { BackgroundColor3 = Color3.fromRGB(36, 36, 48) }, 0.15)
        Tween(SearchStroke, { Transparency = 0.2 }, 0.15)
    end)

    SearchBox.FocusLost:Connect(function()
        task.wait(0.1)
        SearchResults.Visible = false
        Tween(SearchContainer, { BackgroundColor3 = C.Element }, 0.15)
        Tween(SearchStroke, { Transparency = 0.7 }, 0.15)
    end)

    local Sidebar = New("Frame", {
        Name = "Sidebar",
        Parent = Main,
        Position = UDim2.new(0, 0, 0, 40),
        Size = UDim2.new(0, 150, 1, -40),
        BackgroundColor3 = C.Sidebar,
        BorderSizePixel = 0
    })

    New("UICorner", { Parent = Sidebar, CornerRadius = UDim.new(0, 12) })

    New("Frame", {
        Name = "SidebarFillTop",
        Parent = Sidebar,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 0, 14),
        BackgroundColor3 = C.Sidebar,
        BorderSizePixel = 0
    })

    New("Frame", {
        Name = "SidebarFillRight",
        Parent = Sidebar,
        Position = UDim2.new(1, -14, 0, 0),
        Size = UDim2.new(0, 14, 1, 0),
        BackgroundColor3 = C.Sidebar,
        BorderSizePixel = 0
    })

    New("Frame", {
        Name = "SidebarLine",
        Parent = Sidebar,
        Position = UDim2.new(1, -1, 0, 0),
        Size = UDim2.new(0, 1, 1, 0),
        BackgroundColor3 = C.Border,
        BorderSizePixel = 0
    })

    local SideList = New("ScrollingFrame", {
        Name = "List",
        Parent = Sidebar,
        Position = UDim2.new(0, 8, 0, 12),
        Size = UDim2.new(1, -17, 1, -78),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = C.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y
    })

    New("UIListLayout", {
        Parent = SideList,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4)
    })

    local InfoFrame = New("Frame", {
        Name = "Info",
        Parent = Sidebar,
        Position = UDim2.new(0, 8, 1, -58),
        Size = UDim2.new(1, -17, 0, 48),
        BackgroundColor3 = C.Element,
        BorderSizePixel = 0
    })

    New("UICorner", { Parent = InfoFrame, CornerRadius = UDim.new(0, 10) })
    New("UIStroke", { Parent = InfoFrame, Color = C.Border, Thickness = 1, Transparency = 0.4 })

    local Players = game:GetService("Players")
    local playerName = Players.LocalPlayer and Players.LocalPlayer.Name or "Unknown"

    local Avatar = New("ImageLabel", {
        Name = "Avatar",
        Parent = InfoFrame,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 8, 0.5, 0),
        Size = UDim2.fromOffset(32, 32),
        BackgroundColor3 = C.Chip,
        BorderSizePixel = 0,
        Image = "",
        ScaleType = Enum.ScaleType.Crop
    })

    New("UICorner", { Parent = Avatar, CornerRadius = UDim.new(1, 0) })
    New("UIStroke", { Parent = Avatar, Color = C.Accent, Thickness = 1, Transparency = 0.5 })

    pcall(function()
        if Players.LocalPlayer then
            Avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(Players.LocalPlayer.UserId) ..
                "&w=150&h=150"
        end
    end)

    local BuildLabel = New("TextLabel", {
        Name = "Build",
        Parent = InfoFrame,
        Position = UDim2.new(0, 48, 0, 8),
        Size = UDim2.new(1, -54, 0, 15),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = C.TextDim,
        RichText = true
    })

    local UserLabel = New("TextLabel", {
        Name = "User",
        Parent = InfoFrame,
        Position = UDim2.new(0, 48, 0, 24),
        Size = UDim2.new(1, -54, 0, 15),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = C.TextDim,
        TextTruncate = Enum.TextTruncate.AtEnd,
        RichText = true
    })

    BuildLabel.Text = string.format('build: <font color="rgb(%d,%d,%d)">alpha</font>',
        math.floor(C.Accent.R * 255),
        math.floor(C.Accent.G * 255),
        math.floor(C.Accent.B * 255))

    UserLabel.Text = string.format('user: <font color="rgb(%d,%d,%d)">%s</font>',
        math.floor(C.Accent.R * 255),
        math.floor(C.Accent.G * 255),
        math.floor(C.Accent.B * 255),
        playerName)

    local Content = New("Frame", {
        Name = "Content",
        Parent = Main,
        Position = UDim2.new(0, 150, 0, 40),
        Size = UDim2.new(1, -150, 1, -40),
        BackgroundTransparency = 1,
        BorderSizePixel = 0
    })

    local ContentScroll = New("ScrollingFrame", {
        Name = "ContentScroll",
        Parent = Content,
        Position = UDim2.new(0, 0, 0, 6),
        Size = UDim2.new(1, 0, 1, -6),
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
        PaddingTop = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 14),
        PaddingRight = UDim.new(0, 14),
        PaddingBottom = UDim.new(0, 12)
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

    UIS.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    RS.RenderStepped:Connect(function(dt)
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
        Sidebar = SideList,
        Content = ContentScroll,
        LeftColumn = LeftColumn,
        RightColumn = RightColumn,
        CurrentTopTab = nil,
        CurrentCategory = nil,
        TopTabButtons = {},
        Categories = {},
        Visible = false,
        ToggleKey = config.ToggleKey or Enum.KeyCode.K,
        BuildLabel = BuildLabel,
        UserLabel = UserLabel,
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

            local success = pcall(function()
                Tween(Backdrop, { BackgroundTransparency = 0.55 }, 0.3, Enum.EasingStyle.Sine)
            end)
        else
            Tween(MainUIScale, { Scale = W.BaseScale * 0.95 }, 0.25, Enum.EasingStyle.Quad)
            Tween(Main, { GroupTransparency = 1 }, 0.25, Enum.EasingStyle.Quad)

            mainHideThread = task.spawn(function()
                task.wait(0.26)
                if not W.Visible then
                    Main.Visible = false
                    MainUIScale.Scale = W.BaseScale
                end
                mainHideThread = nil
            end)

            local success = pcall(function()
                Tween(Backdrop, { BackgroundTransparency = 1 }, 0.3, Enum.EasingStyle.Sine)
            end)

            backdropHideThread = task.spawn(function()
                task.wait(0.35)
                if not W.Visible then
                    Backdrop.Visible = false
                end
                backdropHideThread = nil
            end)
        end

        if not visible and Library.ColorPickers then
            for _, picker in pairs(Library.ColorPickers) do
                if picker.Close then
                    picker:Close()
                end
            end
        end

        if not visible and Library.ModeMenus then
            for i = #Library.ModeMenus, 1, -1 do
                local menu = Library.ModeMenus[i]
                if menu and menu.close then
                    menu.close()
                elseif menu and menu.gui and menu.gui.Parent then
                    menu.gui:Destroy()
                end
                table.remove(Library.ModeMenus, i)
            end
        end
    end

    function W:Toggle()
        W:SetVisible(not W.Visible)
    end

    function W:SetToggleKey(key)
        W.ToggleKey = key
    end

    function W:SetUIScale(scale)
        local scaleValue = math.clamp(scale, 50, 150) / 100
        W.BaseScale = scaleValue
        MainUIScale.Scale = scaleValue
    end

    CloseBtn.MouseButton1Click:Connect(function()
        W:SetVisible(false)
    end)

    -- Set / change / remove the window icon at any time.
    --   W:SetIcon(123456789)                     -> image as-is
    --   W:SetIcon("https://.../icon.png", true)  -> downloaded, tinted with accent color
    --   W:SetIcon(123456789, Color3.new(1,1,1))  -> fixed tint
    --   W:SetIcon(nil)                           -> back to the default logo mark
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

    UIS.InputBegan:Connect(function(input, gameProcessed)
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

        New("UICorner", { Parent = MobileButton, CornerRadius = UDim.new(0.5, 0) })

        New("UIStroke", {
            Parent = MobileButton,
            Color = Color3.new(1, 1, 1),
            Thickness = 2,
            Transparency = 0.5
        })

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
        local dragStart = nil
        local startPos = nil
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
                dragStart = Vector2.new(input.Position.X, input.Position.Y)
                startPos = MobileButton.Position
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

        UIS.InputChanged:Connect(function(input)
            if not isDragging then return end
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
                local currentPos = Vector2.new(input.Position.X, input.Position.Y)
                local delta = currentPos - dragStart
                if delta.Magnitude > dragThreshold then
                    wasDragged = true
                    local newX = startPos.X.Offset + delta.X
                    local newY = startPos.Y.Offset + delta.Y
                    local cx, cy = clampButtonPosition(newX, newY)
                    MobileButton.Position = UDim2.fromOffset(cx, cy)
                end
            end
        end)

        local _origSetVisible = W.SetVisible
        function W:SetVisible(visible)
            _origSetVisible(self, visible)
            if not MobileIconImage.Visible then
                if visible then
                    MobileIcon.Text = "\xE2\x9C\x95"
                else
                    MobileIcon.Text = "\xE2\x98\xB0"
                end
            end
            if visible then
                Tween(MobileButton, { BackgroundTransparency = 0.4 }, 0.15, Enum.EasingStyle.Sine)
            else
                Tween(MobileButton, { BackgroundTransparency = 0.1 }, 0.15, Enum.EasingStyle.Sine)
            end
        end

        W.MobileButton = MobileButton
    end

    spawn(function()
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
        SearchResults.Size = UDim2.new(1, 0, 0, count * 24 + 8)

        for i = 1, count do
            local match = matches[i]
            local ResultBtn = New("TextButton", {
                Parent = ResultsList,
                Size = UDim2.new(1, 0, 0, 22),
                BackgroundColor3 = C.Section,
                BorderSizePixel = 0,
                Text = match.name,
                TextColor3 = C.Text,
                TextSize = 12,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                AutoButtonColor = false,
                ZIndex = 11
            })

            New("UICorner", { Parent = ResultBtn, CornerRadius = UDim.new(0, 5) })
            New("UIPadding", {
                Parent = ResultBtn,
                PaddingLeft = UDim.new(0, 8),
                PaddingRight = UDim.new(0, 8)
            })

            ResultBtn.MouseButton1Click:Connect(function()
                for _, tab in pairs(W.TopTabButtons) do
                    if tab.Name == match.tabName then
                        W:SelectTopTab(tab)
                        for _, cat in pairs(tab.Categories) do
                            if cat.Name == match.categoryName then
                                cat:Select()

                                task.wait(0.4)

                                if match.elementFrame and match.elementFrame.Parent then
                                    local Highlight = New("Frame", {
                                        Name = "SearchHighlight",
                                        Parent = match.elementFrame,
                                        Size = UDim2.new(1, 0, 1, 0),
                                        BackgroundColor3 = C.Accent,
                                        BackgroundTransparency = 0.5,
                                        BorderSizePixel = 0,
                                        ZIndex = 100
                                    })

                                    New("UICorner", { Parent = Highlight, CornerRadius = UDim.new(0, 5) })

                                    spawn(function()
                                        for i = 1, 3 do
                                            Tween(Highlight, { BackgroundTransparency = 0.85 }, 0.3, Enum.EasingStyle
                                                .Sine)
                                            task.wait(0.3)
                                            Tween(Highlight, { BackgroundTransparency = 0.5 }, 0.3, Enum.EasingStyle
                                                .Sine)
                                            task.wait(0.3)
                                        end

                                        Tween(Highlight, { BackgroundTransparency = 1 }, 0.5, Enum.EasingStyle.Sine)
                                        task.wait(0.5)
                                        Highlight:Destroy()
                                    end)
                                end

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
                Tween(ResultBtn, { BackgroundColor3 = C.Accent }, 0.15)
            end)

            ResultBtn.MouseLeave:Connect(function()
                Tween(ResultBtn, { BackgroundColor3 = C.Section }, 0.15)
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

        if syn and syn.protect_gui then
            syn.protect_gui(Watermark)
            Watermark.Parent = game:GetService("CoreGui")
        elseif gethui then
            Watermark.Parent = gethui()
        else
            Watermark.Parent = game:GetService("CoreGui")
        end

        local WatermarkFrame = New("Frame", {
            Name = "WatermarkFrame",
            Parent = Watermark,
            Position = UDim2.new(0, 12, 0, 12),
            AnchorPoint = Vector2.new(0, 0),
            Size = UDim2.new(0, 0, 0, 30),
            BackgroundColor3 = Color3.fromRGB(14, 14, 19),
            BorderSizePixel = 0,
            AutomaticSize = Enum.AutomaticSize.X
        })

        New("UICorner", { Parent = WatermarkFrame, CornerRadius = UDim.new(0, 10) })
        New("UIStroke", {
            Parent = WatermarkFrame,
            Color = C.Border,
            Thickness = 1,
            Transparency = 0.2
        })

        local ContentFrame = New("Frame", {
            Name = "Content",
            Parent = WatermarkFrame,
            Size = UDim2.new(1, 0, 1, 0),
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
            PaddingLeft = UDim.new(0, 12),
            PaddingRight = UDim.new(0, 12),
            PaddingTop = UDim.new(0, 4),
            PaddingBottom = UDim.new(0, 4)
        })

        local logoText = config.WatermarkText or "rubyazl"
        local logoContainer = New("Frame", {
            Name = "Logo",
            Parent = ContentFrame,
            Size = UDim2.new(0, #logoText * 9, 1, 0),
            BackgroundTransparency = 1,
            LayoutOrder = 1
        })

        local logoLetters = {}
        local baseColor = C.Accent
        local glowColor = Color3.fromRGB(220, 200, 255)

        for i = 1, #logoText do
            local char = logoText:sub(i, i)
            local letter = New("TextLabel", {
                Parent = logoContainer,
                Position = UDim2.new(0, (i - 1) * 9, 0, 0),
                Size = UDim2.new(0, 9, 1, 0),
                BackgroundTransparency = 1,
                Text = char,
                TextColor3 = baseColor,
                TextSize = 15,
                Font = Enum.Font.Code,
                TextXAlignment = Enum.TextXAlignment.Center
            })
            table.insert(logoLetters, letter)
        end

        spawn(function()
            while true do
                for i, letter in ipairs(logoLetters) do
                    spawn(function()
                        local h, s, v = C.Accent:ToHSV()
                        local currentGlow = Color3.fromHSV(h, math.max(s - 0.2, 0), math.min(v + 0.3, 1))

                        Tween(letter, { TextColor3 = currentGlow }, 0.3, Enum.EasingStyle.Sine)
                        task.wait(0.3)
                        Tween(letter, { TextColor3 = C.Accent }, 0.4, Enum.EasingStyle.Sine)
                    end)
                    task.wait(0.08)
                end
                task.wait(1.5)
            end
        end)

        local Sep1 = New("TextLabel", {
            Name = "Sep1",
            Parent = ContentFrame,
            Size = UDim2.new(0, 16, 1, 0),
            BackgroundTransparency = 1,
            Text = "•",
            TextColor3 = C.Accent,
            TextSize = 12,
            Font = Enum.Font.Gotham,
            LayoutOrder = 2
        })

        local playerName = game:GetService("Players").LocalPlayer and game:GetService("Players").LocalPlayer.Name or
            "Unknown"
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

        local Sep2 = New("TextLabel", {
            Name = "Sep2",
            Parent = ContentFrame,
            Size = UDim2.new(0, 16, 1, 0),
            BackgroundTransparency = 1,
            Text = "•",
            TextColor3 = C.Accent,
            TextSize = 12,
            Font = Enum.Font.Gotham,
            LayoutOrder = 4
        })

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

        local Sep3 = New("TextLabel", {
            Name = "Sep3",
            Parent = ContentFrame,
            Size = UDim2.new(0, 16, 1, 0),
            BackgroundTransparency = 1,
            Text = "•",
            TextColor3 = C.Accent,
            TextSize = 12,
            Font = Enum.Font.Gotham,
            LayoutOrder = 6
        })

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
            Position = UDim2.new(0, 10, 1, -2),
            Size = UDim2.new(1, -20, 0, 2),
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

        spawn(function()
            local Stats = game:GetService("Stats")
            while true do
                local ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
                PingLabel.Text = tostring(ping) .. "ms"
                task.wait(1)
            end
        end)

        local dragging, dragInput, dragStart, startPos

        WatermarkFrame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = WatermarkFrame.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)

        UIS.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)

        RS.RenderStepped:Connect(function(dt)
            if dragging and dragInput then
                local delta = dragInput.Position - dragStart
                local target = UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + delta.Y
                )
                WatermarkFrame.Position = WatermarkFrame.Position:Lerp(target, math.clamp(dt * 22, 0, 1))
            end
        end)

        WatermarkFrame.BackgroundTransparency = 1
        for _, child in pairs(ContentFrame:GetDescendants()) do
            if child:IsA("TextLabel") then
                child.TextTransparency = 1
            end
        end

        task.wait(0.5)
        Tween(WatermarkFrame, { BackgroundTransparency = 0 }, 0.5, Enum.EasingStyle.Sine)
        for _, child in pairs(ContentFrame:GetDescendants()) do
            if child:IsA("TextLabel") and child.Name ~= "Logo" then
                Tween(child, { TextTransparency = 0 }, 0.5, Enum.EasingStyle.Sine)
            end
        end

        for i, letter in ipairs(logoLetters) do
            spawn(function()
                task.wait(0.5 + i * 0.05)
                Tween(letter, { TextTransparency = 0 }, 0.3, Enum.EasingStyle.Sine)
            end)
        end

        return {
            Frame = Watermark,
            Letters = logoLetters,
            TextElements = { Sep1, UsernameLabel, Sep2, AlphaLabel, Sep3, PingLabel },
            BaseColor = baseColor,
            GlowColor = glowColor,
            SetVisible = function(visible)
                Watermark.Enabled = visible
            end
        }
    end

    W.Watermark = nil
    spawn(function()
        task.wait(0.2)
        if Library.IsMobile then return end
        local watermark = CreateWatermark()
        W.Watermark = watermark
    end)

    local function layoutTabs()
        local total = 0
        for i, t in ipairs(W.TopTabButtons) do
            total = total + t.Button.Size.X.Offset + (i > 1 and 6 or 0)
        end

        local x = -total / 2
        for _, t in ipairs(W.TopTabButtons) do
            t.Button.Position = UDim2.new(0.5, x, 0.5, 0)
            t.TabX = x
            x = x + t.Button.Size.X.Offset + 6
        end

        if W.CurrentTopTab and W.CurrentTopTab.TabX then
            TabHighlight.Position = UDim2.new(0.5, W.CurrentTopTab.TabX, 0.5, 0)
            TabHighlight.Size = UDim2.new(0, W.CurrentTopTab.Button.Size.X.Offset, 0, 26)
        end
    end

    -- CreateTopTab(name, icon) : icon is optional, same formats as the window icon
    function W:CreateTopTab(name, icon)
        local T = { Name = name, Window = W, Categories = {}, LastSelectedCategory = nil }
        local hasIcon = icon ~= nil and icon ~= ""

        local Btn = New("TextButton", {
            Name = name,
            Parent = TopTabs,
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0, hasIcon and 100 or 80, 0, 26),
            BackgroundColor3 = C.Element,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Text = name,
            TextColor3 = C.TextDim,
            TextSize = 13,
            Font = Enum.Font.GothamMedium,
            AutoButtonColor = false
        })

        New("UICorner", { Parent = Btn, CornerRadius = UDim.new(0, 8) })

        if hasIcon then
            New("UIPadding", { Parent = Btn, PaddingLeft = UDim.new(0, 18) })

            local TabIcon = New("ImageLabel", {
                Name = "Icon",
                Parent = Btn,
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, -8, 0.5, 0),
                Size = UDim2.fromOffset(14, 14),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Image = "",
                ImageColor3 = C.TextDim,
                ScaleType = Enum.ScaleType.Fit
            })

            T.Icon = TabIcon
            setImageAsync(TabIcon, icon)
        end

        local Line = New("Frame", {
            Name = "Line",
            Parent = Btn,
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 1, -4),
            Size = UDim2.new(0, 0, 0, 2),
            BackgroundColor3 = C.Accent,
            BorderSizePixel = 0,
            Visible = false
        })

        New("UICorner", { Parent = Line, CornerRadius = UDim.new(1, 0) })

        table.insert(Library.AccentElements, Line)

        T.Button = Btn
        T.Line = Line
        table.insert(W.TopTabButtons, T)

        layoutTabs()

        Btn.MouseButton1Click:Connect(function()
            W:SelectTopTab(T)
        end)

        Btn.MouseEnter:Connect(function()
            if W.CurrentTopTab ~= T then
                Tween(Btn, { TextColor3 = Color3.fromRGB(190, 192, 212), BackgroundTransparency = 0.6 }, 0.15)
                if T.Icon then
                    Tween(T.Icon, { ImageColor3 = Color3.fromRGB(190, 192, 212) }, 0.15)
                end
            end
        end)

        Btn.MouseLeave:Connect(function()
            if W.CurrentTopTab ~= T then
                Tween(Btn, { TextColor3 = C.TextDim, BackgroundTransparency = 1 }, 0.15)
                if T.Icon then
                    Tween(T.Icon, { ImageColor3 = C.TextDim }, 0.15)
                end
            end
        end)

        if #W.TopTabButtons == 1 then
            spawn(function()
                task.wait(0.1)
                W:SelectTopTab(T)
            end)
        end

        return T
    end

    function W:SelectTopTab(tab)
        if W.CurrentTopTab == tab then return end

        if Library.ColorPickers then
            for _, picker in pairs(Library.ColorPickers) do
                if picker.Close then
                    picker:Close()
                end
            end
        end

        for _, t in pairs(W.TopTabButtons) do
            Tween(t.Button, { TextColor3 = C.TextDim, BackgroundTransparency = 1 }, 0.2)
            if t.Icon then
                Tween(t.Icon, { ImageColor3 = C.TextDim }, 0.2)
            end
            if t.Line.Visible and t ~= tab then
                t.Line.Visible = false
                t.Line.Size = UDim2.new(0, 0, 0, 2)
            end
        end

        Tween(tab.Button, { TextColor3 = C.Text, BackgroundTransparency = 1 }, 0.2)
        if tab.Icon then
            Tween(tab.Icon, { ImageColor3 = C.Text }, 0.2)
        end
        tab.Line.Visible = true
        tab.Line.Size = UDim2.new(0, 0, 0, 2)
        Tween(tab.Line, { Size = UDim2.new(0, 18, 0, 2) }, 0.4, Enum.EasingStyle.Back)

        local goalPos = UDim2.new(0.5, tab.TabX or 0, 0.5, 0)
        local goalSize = UDim2.new(0, tab.Button.Size.X.Offset, 0, 26)
        if not TabHighlight.Visible then
            TabHighlight.Position = goalPos
            TabHighlight.Size = goalSize
            TabHighlight.Visible = true
        else
            Tween(TabHighlight, { Position = goalPos, Size = goalSize }, 0.4, Enum.EasingStyle.Quint)
        end

        W.CurrentTopTab = tab

        for _, c in pairs(SideList:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end

        for i, cat in pairs(tab.Categories) do
            cat:Show()
            if cat.Button then
                spawn(function()
                    task.wait(i * 0.04)
                    Tween(cat.Button, { TextTransparency = 0 }, 0.2, Enum.EasingStyle.Sine)
                    if cat.Icon and cat.Icon.Parent then
                        Tween(cat.Icon, { ImageTransparency = 0 }, 0.2, Enum.EasingStyle.Sine)
                    end
                end)
            end
        end

        if #tab.Categories > 0 then
            if tab.LastSelectedCategory and table.find(tab.Categories, tab.LastSelectedCategory) then
                tab.LastSelectedCategory:Select()
            else
                tab.Categories[1]:Select()
            end
        end
    end

    -- CreateCategory(topTab, name, icon) : icon is optional
    function W:CreateCategory(topTab, name, icon)
        local Cat = { Name = name, TopTab = topTab, Sections = {}, Button = nil, IconId = icon }

        function Cat:Show()
            local hasIcon = Cat.IconId ~= nil and Cat.IconId ~= ""
            local padLeft = hasIcon and 38 or 16

            local Btn = New("TextButton", {
                Name = name,
                Parent = SideList,
                Size = UDim2.new(1, 0, 0, 32),
                BackgroundColor3 = C.Element,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Text = name,
                TextColor3 = C.TextDim,
                TextSize = 13,
                Font = Enum.Font.GothamMedium,
                AutoButtonColor = false,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTransparency = 1
            })

            New("UICorner", { Parent = Btn, CornerRadius = UDim.new(0, 8) })
            New("UIPadding", { Parent = Btn, PaddingLeft = UDim.new(0, padLeft) })

            local Border = New("Frame", {
                Name = "Border",
                Parent = Btn,
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, -(padLeft - 4), 0.5, 0),
                Size = UDim2.new(0, 3, 0, 16),
                BackgroundColor3 = C.Accent,
                BorderSizePixel = 0,
                Visible = false
            })

            New("UICorner", { Parent = Border, CornerRadius = UDim.new(1, 0) })

            table.insert(Library.AccentElements, Border)

            Cat.Button = Btn
            Cat.Border = Border
            Cat.Icon = nil

            if hasIcon then
                local CatIcon = New("ImageLabel", {
                    Name = "Icon",
                    Parent = Btn,
                    AnchorPoint = Vector2.new(0, 0.5),
                    Position = UDim2.new(0, -(padLeft - 14), 0.5, 0),
                    Size = UDim2.fromOffset(16, 16),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Image = "",
                    ImageColor3 = C.TextDim,
                    ImageTransparency = 1,
                    ScaleType = Enum.ScaleType.Fit
                })

                Cat.Icon = CatIcon
                setImageAsync(CatIcon, Cat.IconId)
            end

            Btn.MouseButton1Click:Connect(function()
                Cat:Select()
            end)

            Btn.MouseEnter:Connect(function()
                if W.CurrentCategory ~= Cat then
                    Tween(Btn, {
                        TextColor3 = Color3.fromRGB(190, 192, 212),
                        BackgroundTransparency = 0.6
                    }, 0.2, Enum.EasingStyle.Sine)
                    if Cat.Icon then
                        Tween(Cat.Icon, { ImageColor3 = Color3.fromRGB(190, 192, 212) }, 0.2, Enum.EasingStyle.Sine)
                    end
                end
            end)

            Btn.MouseLeave:Connect(function()
                if W.CurrentCategory ~= Cat then
                    Tween(Btn, {
                        TextColor3 = C.TextDim,
                        BackgroundTransparency = 1
                    }, 0.2, Enum.EasingStyle.Sine)
                    if Cat.Icon then
                        Tween(Cat.Icon, { ImageColor3 = C.TextDim }, 0.2, Enum.EasingStyle.Sine)
                    end
                end
            end)
        end

        function Cat:Select()
            if W.CurrentCategory == Cat then return end

            for _, c in pairs(SideList:GetChildren()) do
                if c:IsA("TextButton") then
                    Tween(c, { TextColor3 = C.TextDim, BackgroundTransparency = 1 }, 0.15, Enum.EasingStyle.Sine)
                    if c:FindFirstChild("Border") then
                        c.Border.Visible = false
                    end
                    local otherIcon = c:FindFirstChild("Icon")
                    if otherIcon then
                        Tween(otherIcon, { ImageColor3 = C.TextDim }, 0.15, Enum.EasingStyle.Sine)
                    end
                end
            end

            if Cat.Button then
                Tween(Cat.Button, { TextColor3 = C.Accent, BackgroundTransparency = 0 }, 0.2, Enum.EasingStyle.Sine)
                if Cat.Icon then
                    Tween(Cat.Icon, { ImageColor3 = C.Accent }, 0.2, Enum.EasingStyle.Sine)
                end
                Cat.Border.Visible = true
                Cat.Border.BackgroundTransparency = 1
                Cat.Border.Size = UDim2.new(0, 3, 0, 4)
                Tween(Cat.Border, { BackgroundTransparency = 0, Size = UDim2.new(0, 3, 0, 16) }, 0.3,
                    Enum.EasingStyle.Back)
            end

            W.CurrentCategory = Cat

            if Cat.TopTab then
                Cat.TopTab.LastSelectedCategory = Cat
            end

            if W.LeftColumn then
                for _, c in pairs(W.LeftColumn:GetChildren()) do
                    if c:IsA("GuiObject") then
                        c.Visible = false
                    end
                end
            end
            if W.RightColumn then
                for _, c in pairs(W.RightColumn:GetChildren()) do
                    if c:IsA("GuiObject") then
                        c.Visible = false
                    end
                end
            end

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

    New("UICorner", { Parent = Frame, CornerRadius = UDim.new(0, 10) })
    New("UIStroke", { Parent = Frame, Color = C.Border, Thickness = 1, Transparency = 0.2 })

    local HeaderPill = New("Frame", {
        Name = "HeaderPill",
        Parent = Frame,
        Position = UDim2.new(0, 14, 0, 10),
        Size = UDim2.new(0, 3, 0, 12),
        BackgroundColor3 = C.Accent,
        BorderSizePixel = 0
    })

    New("UICorner", { Parent = HeaderPill, CornerRadius = UDim.new(1, 0) })

    table.insert(Library.AccentElements, HeaderPill)

    local Header = New("TextLabel", {
        Name = "Header",
        Parent = Frame,
        Position = UDim2.new(0, 24, 0, 7),
        Size = UDim2.new(1, -38, 0, 18),
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
        Position = UDim2.new(0, 12, 0, 31),
        Size = UDim2.new(1, -24, 0, 1),
        BackgroundColor3 = C.Border,
        BorderSizePixel = 0
    })

    local Container = New("Frame", {
        Name = "Container",
        Parent = Frame,
        Position = UDim2.new(0, 0, 0, 38),
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

function Library:CreateToggle(section, config)
    config = config or {}
    local name = config.Name or "Toggle"
    local default = config.Default or false
    local callback = config.Callback or function() end
    local keybind = config.Keybind

    local configPath = section.Category.TopTab.Name .. "_" .. section.Category.Name .. "_" .. section.Name .. "_" .. name

    local T = {
        Value = default,
        Callback = callback,
        ConfigPath = configPath,
        HasKeybind = keybind ~= nil,
        KeybindKey = nil,
        Name = name
    }

    local Frame = New("Frame", {
        Parent = section.Container,
        Size = UDim2.new(1, 0, 0, 26),
        BackgroundColor3 = C.Element,
        BackgroundTransparency = 1,
        BorderSizePixel = 0
    })

    New("UICorner", { Parent = Frame, CornerRadius = UDim.new(0, 6) })

    local Box = New("Frame", {
        Parent = Frame,
        Position = UDim2.new(1, -6, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        Size = UDim2.fromOffset(30, 16),
        BackgroundColor3 = default and C.Accent or C.SliderBg,
        BorderSizePixel = 0
    })

    New("UICorner", { Parent = Box, CornerRadius = UDim.new(1, 0) })

    local BoxStroke = New("UIStroke", {
        Parent = Box,
        Color = C.Accent,
        Thickness = 1,
        Transparency = default and 0.55 or 1
    })

    local Knob = New("Frame", {
        Parent = Box,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = default and UDim2.new(1, -8, 0.5, 0) or UDim2.new(0, 8, 0.5, 0),
        Size = UDim2.fromOffset(12, 12),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0
    })

    New("UICorner", { Parent = Knob, CornerRadius = UDim.new(1, 0) })

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

    local labelWidth = keybind and -114 or -50

    local Label = New("TextLabel", {
        Parent = Frame,
        Position = UDim2.new(0, 8, 0, 0),
        Size = UDim2.new(1, labelWidth, 1, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = default and C.Text or Color3.fromRGB(165, 167, 186),
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

    Btn.MouseEnter:Connect(function()
        Tween(Frame, { BackgroundTransparency = 0.5 }, 0.15)
        Frame.BackgroundColor3 = C.Element
    end)

    Btn.MouseLeave:Connect(function()
        Tween(Frame, { BackgroundTransparency = 1 }, 0.15)
    end)

    if config.Tooltip then
        Library:AttachTooltip(Btn, config.Tooltip)
    end

    function T:SetValue(v, skipSave)
        T.Value = v

        Tween(Box, { BackgroundColor3 = v and C.Accent or C.SliderBg }, 0.25, Enum.EasingStyle.Sine)
        Tween(BoxStroke, { Transparency = v and 0.55 or 1 }, 0.25, Enum.EasingStyle.Sine)
        Tween(Knob, { Position = v and UDim2.new(1, -8, 0.5, 0) or UDim2.new(0, 8, 0.5, 0) }, 0.3, Enum.EasingStyle.Quint)
        Tween(Label, { TextColor3 = v and C.Text or Color3.fromRGB(165, 167, 186) }, 0.25, Enum.EasingStyle.Sine)

        Tween(Knob, { Size = UDim2.fromOffset(16, 12) }, 0.1, Enum.EasingStyle.Sine)
        task.delay(0.1, function()
            if Knob and Knob.Parent then
                Tween(Knob, { Size = UDim2.fromOffset(12, 12) }, 0.18, Enum.EasingStyle.Sine)
            end
        end)

        setAccentRegistered(v and true or false)

        callback(v)

        if T.HasKeybind and Library.KeybindsWindow then
            Library.KeybindsWindow:UpdateKeybind(name, T.KeybindKey and T.KeybindKey.Name or "None", v)
        end

        if not skipSave then
            autoSave(configPath, v)
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
            Position = UDim2.new(1, -44, 0.5, 0),
            Size = UDim2.new(0, 64, 0, 18),
            BackgroundColor3 = C.Chip,
            BorderSizePixel = 0,
            Text = "[" .. (keybind.Default and keybind.Default.Name or "None") .. "]",
            TextColor3 = C.TextDim,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Font = Enum.Font.GothamMedium,
            AutoButtonColor = false
        })

        New("UICorner", { Parent = KeyBtn, CornerRadius = UDim.new(0, 5) })

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
            if not editing and not modeMenuOpen then
                modeMenuOpen = true

                local ModeGui = New("ScreenGui", {
                    Name = "KeybindModeSelector",
                    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
                    ResetOnSpawn = false
                })

                if syn and syn.protect_gui then
                    syn.protect_gui(ModeGui)
                    ModeGui.Parent = game:GetService("CoreGui")
                elseif gethui then
                    ModeGui.Parent = gethui()
                else
                    ModeGui.Parent = game:GetService("CoreGui")
                end

                local ModeFrame = New("Frame", {
                    Name = "ModeFrame",
                    Parent = ModeGui,
                    Position = UDim2.new(0, 0, 0, 0),
                    Size = UDim2.new(0, 76, 0, 56),
                    BackgroundColor3 = C.Element,
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1
                })

                New("UICorner", { Parent = ModeFrame, CornerRadius = UDim.new(0, 8) })
                local frameStroke = New("UIStroke", {
                    Parent = ModeFrame,
                    Color = C.Accent,
                    Thickness = 1,
                    Transparency = 1
                })

                local btnPos = KeyBtn.AbsolutePosition
                ModeFrame.Position = UDim2.new(0, btnPos.X - 5, 0, btnPos.Y + 24)

                local ToggleBtn = New("TextButton", {
                    Name = "Toggle",
                    Parent = ModeFrame,
                    Position = UDim2.new(0, 4, 0, 4),
                    Size = UDim2.new(1, -8, 0, 22),
                    BackgroundColor3 = mode == "Toggle" and C.Accent or C.Section,
                    BorderSizePixel = 0,
                    Text = "Toggle",
                    TextColor3 = C.Text,
                    TextSize = 12,
                    Font = Enum.Font.GothamMedium,
                    AutoButtonColor = false,
                    BackgroundTransparency = 1,
                    TextTransparency = 1
                })

                New("UICorner", { Parent = ToggleBtn, CornerRadius = UDim.new(0, 5) })

                local HoldBtn = New("TextButton", {
                    Name = "Hold",
                    Parent = ModeFrame,
                    Position = UDim2.new(0, 4, 0, 30),
                    Size = UDim2.new(1, -8, 0, 22),
                    BackgroundColor3 = mode == "Hold" and C.Accent or C.Section,
                    BorderSizePixel = 0,
                    Text = "Hold",
                    TextColor3 = C.Text,
                    TextSize = 12,
                    Font = Enum.Font.GothamMedium,
                    AutoButtonColor = false,
                    BackgroundTransparency = 1,
                    TextTransparency = 1
                })

                New("UICorner", { Parent = HoldBtn, CornerRadius = UDim.new(0, 5) })

                Tween(ModeFrame, { BackgroundTransparency = 0 }, 0.2, Enum.EasingStyle.Sine)
                Tween(frameStroke, { Transparency = 0.5 }, 0.2, Enum.EasingStyle.Sine)
                Tween(ToggleBtn, { BackgroundTransparency = 0, TextTransparency = 0 }, 0.2, Enum.EasingStyle.Sine)
                Tween(HoldBtn, { BackgroundTransparency = 0, TextTransparency = 0 }, 0.2, Enum.EasingStyle.Sine)

                if mode == "Toggle" then
                    ToggleBtn.BackgroundColor3 = C.Accent
                    HoldBtn.BackgroundColor3 = C.Section
                else
                    HoldBtn.BackgroundColor3 = C.Accent
                    ToggleBtn.BackgroundColor3 = C.Section
                end

                local function closeMenu()
                    Tween(ModeFrame, { BackgroundTransparency = 1 }, 0.15, Enum.EasingStyle.Sine)
                    Tween(frameStroke, { Transparency = 1 }, 0.15, Enum.EasingStyle.Sine)
                    Tween(ToggleBtn, { BackgroundTransparency = 1, TextTransparency = 1 }, 0.15, Enum.EasingStyle.Sine)
                    Tween(HoldBtn, { BackgroundTransparency = 1, TextTransparency = 1 }, 0.15, Enum.EasingStyle.Sine)

                    task.wait(0.15)
                    ModeGui:Destroy()
                    modeMenuOpen = false

                    if Library.ModeMenus then
                        for i = #Library.ModeMenus, 1, -1 do
                            if Library.ModeMenus[i].gui == ModeGui then
                                table.remove(Library.ModeMenus, i)
                                break
                            end
                        end
                    end
                end

                ToggleBtn.MouseButton1Click:Connect(function()
                    mode = "Toggle"
                    T.KeybindMode = mode
                    Tween(ToggleBtn, { BackgroundColor3 = C.Accent }, 0.1)
                    Tween(HoldBtn, { BackgroundColor3 = C.Section }, 0.1)
                    closeMenu()
                end)

                HoldBtn.MouseButton1Click:Connect(function()
                    mode = "Hold"
                    T.KeybindMode = mode
                    Tween(HoldBtn, { BackgroundColor3 = C.Accent }, 0.1)
                    Tween(ToggleBtn, { BackgroundColor3 = C.Section }, 0.1)
                    closeMenu()
                end)

                ToggleBtn.MouseEnter:Connect(function()
                    if mode ~= "Toggle" then
                        Tween(ToggleBtn, { BackgroundColor3 = C.Accent }, 0.15)
                    end
                end)

                ToggleBtn.MouseLeave:Connect(function()
                    if mode ~= "Toggle" then
                        Tween(ToggleBtn, { BackgroundColor3 = C.Section }, 0.15)
                    end
                end)

                HoldBtn.MouseEnter:Connect(function()
                    if mode ~= "Hold" then
                        Tween(HoldBtn, { BackgroundColor3 = C.Accent }, 0.15)
                    end
                end)

                HoldBtn.MouseLeave:Connect(function()
                    if mode ~= "Hold" then
                        Tween(HoldBtn, { BackgroundColor3 = C.Section }, 0.15)
                    end
                end)

                local closeConnection = UIS.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        local mousePos = Vector2.new(input.Position.X, input.Position.Y)
                        local framePos = ModeFrame.AbsolutePosition
                        local frameSize = ModeFrame.AbsoluteSize

                        if mousePos.X < framePos.X or mousePos.X > framePos.X + frameSize.X or
                            mousePos.Y < framePos.Y or mousePos.Y > framePos.Y + frameSize.Y then
                            closeConnection:Disconnect()
                            closeMenu()
                        end
                    end
                end)

                if not Library.ModeMenus then
                    Library.ModeMenus = {}
                end
                table.insert(Library.ModeMenus, { gui = ModeGui, close = closeMenu })
            end
        end)

        KeyBtn.MouseEnter:Connect(function()
            if not editing then
                Tween(KeyBtn, { TextColor3 = C.Text }, 0.15)
            end
        end)

        KeyBtn.MouseLeave:Connect(function()
            if not editing then
                Tween(KeyBtn, { TextColor3 = C.TextDim }, 0.15)
            end
        end)

        UIS.InputBegan:Connect(function(input, gameProcessed)
            if editing then
                local key = input.KeyCode
                if key == Enum.KeyCode.Unknown and (input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3) then
                    key = input.UserInputType
                end
                if key ~= Enum.KeyCode.Unknown then
                    currentKey = key
                    T.KeybindKey = key
                    local keyName = key.Name
                    if keyName:match("MouseButton") then keyName = keyName:gsub("MouseButton", "M") end
                    KeyBtn.Text = "[" .. keyName .. "]"
                    editing = false
                    KeyBtn.TextColor3 = C.TextDim

                    if Library.KeybindsWindow then
                        Library.KeybindsWindow:UpdateKeybind(name, keyName, T.Value)
                    end
                end
            elseif not gameProcessed and (input.KeyCode == currentKey or input.UserInputType == currentKey) and currentKey then
                if mode == "Toggle" then
                    T:SetValue(not T.Value)
                elseif mode == "Hold" then
                    T:SetValue(true)
                end
            end
        end)

        UIS.InputEnded:Connect(function(input, gameProcessed)
            if not gameProcessed and (input.KeyCode == currentKey or input.UserInputType == currentKey) and currentKey and mode == "Hold" then
                T:SetValue(false)
            end
        end)

        T.GetKeybind = function() return currentKey end
        T.SetKeybind = function(key)
            currentKey = key
            T.KeybindKey = key
            KeyBtn.Text = "[" .. (key and key.Name or "None") .. "]"

            if Library.KeybindsWindow then
                Library.KeybindsWindow:UpdateKeybind(name, key and key.Name or "None", T.Value)
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

    ConfigSystem.Elements[configPath] = T

    spawn(function()
        task.wait(0.1)
        if Library.Windows and Library.Windows[1] and Library.Windows[1].RegisterElement then
            Library.Windows[1]:RegisterElement(name, section.Category.TopTab.Name, section.Category.Name, Frame,
                section.Frame, section.Column)
        end
    end)

    return T
end

function Library:CreateSlider(section, config)
    config = config or {}
    local name = config.Name or "Slider"
    local min = config.Min or 0
    local max = config.Max or 100
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

    local configPath = section.Category.TopTab.Name .. "_" .. section.Category.Name .. "_" .. section.Name .. "_" .. name

    default = snap(default)
    local S = { Value = default, Min = min, Max = max, Step = step, Callback = callback, ConfigPath = configPath }
    local sliderFrameH = Library.IsMobile and 48 or 40

    local Frame = New("Frame", {
        Parent = section.Container,
        Size = UDim2.new(1, 0, 0, sliderFrameH),
        BackgroundTransparency = 1
    })

    local Label = New("TextLabel", {
        Parent = Frame,
        Position = UDim2.new(0, 8, 0, 0),
        Size = UDim2.new(0.6, 0, 0, 16),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = C.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.Gotham
    })

    local Value = New("TextLabel", {
        Parent = Frame,
        Position = UDim2.new(1, -68, 0, 0),
        Size = UDim2.new(0, 60, 0, 16),
        BackgroundTransparency = 1,
        Text = fmt(default) .. suffix,
        TextColor3 = C.TextDim,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
        Font = Enum.Font.GothamMedium
    })

    local Track = New("Frame", {
        Parent = Frame,
        Position = UDim2.new(0, 8, 1, -(Library.IsMobile and 18 or 12)),
        Size = UDim2.new(1, -16, 0, Library.IsMobile and 12 or 6),
        BackgroundColor3 = C.SliderBg,
        BorderSizePixel = 0
    })

    New("UICorner", { Parent = Track, CornerRadius = UDim.new(1, 0) })

    local Fill = New("Frame", {
        Parent = Track,
        Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
        BackgroundColor3 = C.Accent,
        BorderSizePixel = 0
    })

    New("UICorner", { Parent = Fill, CornerRadius = UDim.new(1, 0) })

    New("UIGradient", {
        Parent = Fill,
        Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(180, 180, 205))
    })

    table.insert(Library.AccentElements, Fill)

    local knobSize = Library.IsMobile and 18 or 12
    local Knob = New("Frame", {
        Parent = Track,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new((default - min) / (max - min), 0, 0.5, 0),
        Size = UDim2.fromOffset(knobSize, knobSize),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 3
    })

    New("UICorner", { Parent = Knob, CornerRadius = UDim.new(1, 0) })

    local KnobStroke = New("UIStroke", {
        Parent = Knob,
        Color = C.Accent,
        Thickness = 2,
        Transparency = 1
    })

    table.insert(Library.AccentElements, KnobStroke)

    local btnHitH = Library.IsMobile and 44 or 1
    local btnHitW = Library.IsMobile and 24 or 0
    local Btn = New("TextButton", {
        Parent = Track,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = Library.IsMobile and UDim2.new(1, btnHitW, 0, btnHitH) or UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 5
    })

    Btn.MouseEnter:Connect(function()
        Tween(Track, { BackgroundColor3 = Color3.fromRGB(48, 48, 62) }, 0.15)
    end)

    Btn.MouseLeave:Connect(function()
        Tween(Track, { BackgroundColor3 = C.SliderBg }, 0.15)
    end)

    if config.Tooltip then
        Library:AttachTooltip(Btn, config.Tooltip)
        Library:AttachTooltip(Label, config.Tooltip)
    end

    local dragging = false
    local ancestorScrolls = {}
    do
        local p = Frame.Parent; while p and p ~= game do
            if p:IsA("ScrollingFrame") then table.insert(ancestorScrolls, p) end; p = p.Parent
        end
    end
    local function setScrollingEnabled(enabled) for _, sf in ipairs(ancestorScrolls) do sf.ScrollingEnabled = enabled end end

    local function endDragVisuals()
        Tween(Knob, { Size = UDim2.fromOffset(knobSize, knobSize) }, 0.15, Enum.EasingStyle.Sine)
        Tween(KnobStroke, { Transparency = 1 }, 0.2, Enum.EasingStyle.Sine)
        Tween(Value, { TextColor3 = C.TextDim }, 0.2, Enum.EasingStyle.Sine)
    end

    UIS.InputEnded:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            dragging = false; setScrollingEnabled(true)
            endDragVisuals()
        end
    end)

    function S:SetValue(v, skipSave)
        v = snap(v)
        S.Value = v
        local p = (v - min) / (max - min)
        Tween(Fill, { Size = UDim2.new(p, 0, 1, 0) }, 0.12, Enum.EasingStyle.Sine)
        Tween(Knob, { Position = UDim2.new(p, 0, 0.5, 0) }, 0.12, Enum.EasingStyle.Sine)
        Value.Text = fmt(v) .. suffix
        callback(v)
        if not skipSave then
            autoSave(configPath, v)
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
        local val = snap(min + (max - min) * pos)
        S:SetValue(val)
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

    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local trackW = Track.AbsoluteSize.X
            local pxPerStep = (step / (max - min)) * trackW
            if pxPerStep >= 1 then
                setFromPosition(input)
                dragAnchorX = input.Position.X
                dragAnchorVal = S.Value
            else
                local deltaPx = input.Position.X - dragAnchorX
                local val = snap(dragAnchorVal + deltaPx * step)
                S:SetValue(val)
            end
        end
    end)

    ConfigSystem.Elements[configPath] = S

    spawn(function()
        task.wait(0.1)
        if Library.Windows and Library.Windows[1] and Library.Windows[1].RegisterElement then
            Library.Windows[1]:RegisterElement(name, section.Category.TopTab.Name, section.Category.Name, Frame,
                section.Frame, section.Column)
        end
    end)

    return S
end

function Library:CreateDropdown(section, config)
    config = config or {}
    local name = config.Name or "Dropdown"
    local options = config.Options or {}
    local default = config.Default or (options[1] or "")
    local callback = config.Callback or function() end

    local configPath = section.Category.TopTab.Name .. "_" .. section.Category.Name .. "_" .. section.Name .. "_" .. name

    local D = { Value = default, Options = options, Callback = callback, Open = false, ConfigPath = configPath }

    local Container = New("Frame", {
        Parent = section.Container,
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundTransparency = 1
    })

    local Frame = New("Frame", {
        Parent = Container,
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundTransparency = 1
    })

    local Label = New("TextLabel", {
        Parent = Frame,
        Position = UDim2.new(0, 8, 0, 0),
        Size = UDim2.new(0.45, -8, 1, 0),
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
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0.45, 0, 0.5, 0),
        Size = UDim2.new(0.55, 0, 0, 24),
        BackgroundColor3 = C.Chip,
        BorderSizePixel = 0,
        Text = default,
        TextColor3 = C.TextDim,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamMedium,
        TextTruncate = Enum.TextTruncate.AtEnd
    })

    New("UICorner", { Parent = Value, CornerRadius = UDim.new(0, 6) })
    New("UIPadding", { Parent = Value, PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 22) })

    local Arrow = New("TextLabel", {
        Parent = Frame,
        Position = UDim2.new(1, -20, 0, 0),
        Size = UDim2.new(0, 14, 1, 0),
        BackgroundTransparency = 1,
        Text = "›",
        TextColor3 = C.TextDim,
        TextSize = 18,
        Font = Enum.Font.GothamBold,
        Rotation = 0
    })

    local List = New("ScrollingFrame", {
        Parent = Container,
        Position = UDim2.new(0, 0, 0, 32),
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = C.Element,
        BorderSizePixel = 0,
        Visible = false,
        ClipsDescendants = true,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = C.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y
    })

    New("UICorner", { Parent = List, CornerRadius = UDim.new(0, 8) })
    New("UIStroke", { Parent = List, Color = C.Border, Thickness = 1, Transparency = 0.2 })
    New("UIListLayout", { Parent = List, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2) })
    New("UIPadding",
        {
            Parent = List,
            PaddingTop = UDim.new(0, 4),
            PaddingBottom = UDim.new(0, 4),
            PaddingLeft = UDim.new(0, 4),
            PaddingRight =
                UDim.new(0, 4)
        })

    local Btn = New("TextButton", {
        Parent = Frame,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = ""
    })

    Btn.MouseEnter:Connect(function()
        Tween(Value, { BackgroundColor3 = Color3.fromRGB(44, 44, 58) }, 0.15)
    end)

    Btn.MouseLeave:Connect(function()
        Tween(Value, { BackgroundColor3 = C.Chip }, 0.15)
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
        Value.Text = v
        updateSelected()
        callback(v)
        if not skipSave then
            autoSave(configPath, v)
        end
    end

    function D:GetValue()
        return D.Value
    end

    function D:Toggle()
        D.Open = not D.Open
        if D.Open then
            List.Visible = true
            local h = math.max(88, math.min(#D.Options * 24 + 8, 200))

            Tween(Container, { Size = UDim2.new(1, 0, 0, 32 + h) }, 0.35, Enum.EasingStyle.Quint)
            Tween(List, { Size = UDim2.new(1, 0, 0, h) }, 0.35, Enum.EasingStyle.Quint)

            Tween(Arrow, { Rotation = 90, TextColor3 = C.Accent }, 0.25, Enum.EasingStyle.Quint)
        else
            Tween(Container, { Size = UDim2.new(1, 0, 0, 28) }, 0.3, Enum.EasingStyle.Quint)
            Tween(List, { Size = UDim2.new(1, 0, 0, 0) }, 0.3, Enum.EasingStyle.Quint)

            Tween(Arrow, { Rotation = 0, TextColor3 = C.TextDim }, 0.25, Enum.EasingStyle.Quint)

            task.wait(0.3)
            List.Visible = false
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
                BackgroundColor3 = C.Section,
                BorderSizePixel = 0,
                Text = opt,
                TextColor3 = (opt == D.Value) and C.Accent or C.Text,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                Font = Enum.Font.GothamMedium,
                AutoButtonColor = false
            })
            New("UICorner", { Parent = O, CornerRadius = UDim.new(0, 5) })
            New("UIPadding", { Parent = O, PaddingLeft = UDim.new(0, 8) })
            O.MouseButton1Click:Connect(function()
                D:SetValue(opt)
                D:Toggle()
            end)
            O.MouseEnter:Connect(function() Tween(O, { BackgroundColor3 = Color3.fromRGB(44, 44, 58) }, 0.15, Enum.EasingStyle.Sine) end)
            O.MouseLeave:Connect(function() Tween(O, { BackgroundColor3 = C.Section }, 0.15, Enum.EasingStyle.Sine) end)
        end
    end

    Btn.MouseButton1Click:Connect(function() D:Toggle() end)
    D:Refresh(options)

    ConfigSystem.Elements[configPath] = D

    spawn(function()
        task.wait(0.1)
        if Library.Windows and Library.Windows[1] and Library.Windows[1].RegisterElement then
            Library.Windows[1]:RegisterElement(name, section.Category.TopTab.Name, section.Category.Name, Container,
                section.Frame, section.Column)
        end
    end)

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
    New("UIPadding", { Parent = L, PaddingLeft = UDim.new(0, 8) })
    return L
end

function Library:CreateButton(section, config)
    config = config or {}
    local name = config.Name or "Button"
    local callback = config.Callback or function() end

    local B = { Callback = callback }

    local Frame = New("Frame", {
        Parent = section.Container,
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundColor3 = C.Element,
        BorderSizePixel = 0
    })

    New("UICorner", { Parent = Frame, CornerRadius = UDim.new(0, 8) })
    local BtnStroke = New("UIStroke", { Parent = Frame, Color = C.Border, Thickness = 1, Transparency = 0.3 })

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
        Tween(BtnStroke, { Transparency = 0.3 }, 0.2, Enum.EasingStyle.Sine)
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

    spawn(function()
        task.wait(0.1)
        if Library.Windows and Library.Windows[1] and Library.Windows[1].RegisterElement then
            Library.Windows[1]:RegisterElement(name, section.Category.TopTab.Name, section.Category.Name, Frame,
                section.Frame, section.Column)
        end
    end)

    return B
end

function Library:CreateKeybind(section, config)
    config = config or {}
    local name = config.Name or "Keybind"
    local default = config.Default or Enum.KeyCode.E
    local mode = config.Mode or "Toggle"
    local callback = config.Callback or function() end

    local configPath = section.Category.TopTab.Name .. "_" .. section.Category.Name .. "_" .. section.Name .. "_" .. name

    local K = {
        Key = default,
        Mode = mode,
        Callback = callback,
        Active = false,
        Editing = false,
        ConfigPath = configPath,
        Name = name
    }

    local Frame = New("Frame", {
        Parent = section.Container,
        Size = UDim2.new(1, 0, 0, 26),
        BackgroundTransparency = 1
    })

    local Label = New("TextLabel", {
        Parent = Frame,
        Position = UDim2.new(0, 8, 0, 0),
        Size = UDim2.new(0.5, -8, 1, 0),
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
        Size = UDim2.new(0, 72, 0, 20),
        BackgroundColor3 = C.Chip,
        BorderSizePixel = 0,
        Text = "[" .. (default and default.Name or "None") .. "]",
        TextColor3 = C.TextDim,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Font = Enum.Font.GothamMedium,
        AutoButtonColor = false
    })

    New("UICorner", { Parent = KeyBtn, CornerRadius = UDim.new(0, 6) })

    K.ManualWatermark = config.ManualWatermark == true
    local function refreshKeybindsWindow()
        if K.ManualWatermark then return end
        if Library.KeybindsWindow then
            Library.KeybindsWindow:UpdateKeybind(name, K.Key and K.Key.Name or "None", K.Active)
        end
    end

    function K:SetKey(key)
        K.Key = key
        local kName = key and key.Name or "None"
        if kName:match("MouseButton") then kName = kName:gsub("MouseButton", "M") end
        KeyBtn.Text = "[" .. kName .. "]"
        autoSave(configPath, { Key = key and key.Name or nil, Mode = K.Mode })
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
            local kName = K.Key and K.Key.Name or "None"
            if kName:match("MouseButton") then kName = kName:gsub("MouseButton", "M") end
            KeyBtn.Text = "[" .. kName .. "]"
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

        local ModeGui = New("ScreenGui", {
            Name = "KeybindModeSelector",
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            ResetOnSpawn = false
        })
        if syn and syn.protect_gui then
            syn.protect_gui(ModeGui); ModeGui.Parent = game:GetService("CoreGui")
        elseif gethui then
            ModeGui.Parent = gethui()
        else
            ModeGui.Parent = game:GetService("CoreGui")
        end

        local ModeFrame = New("Frame", {
            Parent = ModeGui,
            Size = UDim2.new(0, 76, 0, 56),
            BackgroundColor3 = C.Element,
            BorderSizePixel = 0,
            BackgroundTransparency = 1
        })
        New("UICorner", { Parent = ModeFrame, CornerRadius = UDim.new(0, 8) })
        local frameStroke = New("UIStroke", { Parent = ModeFrame, Color = C.Accent, Thickness = 1, Transparency = 1 })

        local btnPos = KeyBtn.AbsolutePosition
        ModeFrame.Position = UDim2.new(0, btnPos.X - 5, 0, btnPos.Y + 26)

        local ToggleBtn = New("TextButton", {
            Parent = ModeFrame,
            Position = UDim2.new(0, 4, 0, 4),
            Size = UDim2.new(1, -8, 0, 22),
            BackgroundColor3 = K.Mode == "Toggle" and C.Accent or C.Section,
            BorderSizePixel = 0,
            Text = "Toggle",
            TextColor3 = C.Text,
            TextSize = 12,
            Font = Enum.Font.GothamMedium,
            AutoButtonColor = false,
            BackgroundTransparency = 1,
            TextTransparency = 1
        })
        New("UICorner", { Parent = ToggleBtn, CornerRadius = UDim.new(0, 5) })

        local HoldBtn = New("TextButton", {
            Parent = ModeFrame,
            Position = UDim2.new(0, 4, 0, 30),
            Size = UDim2.new(1, -8, 0, 22),
            BackgroundColor3 = K.Mode == "Hold" and C.Accent or C.Section,
            BorderSizePixel = 0,
            Text = "Hold",
            TextColor3 = C.Text,
            TextSize = 12,
            Font = Enum.Font.GothamMedium,
            AutoButtonColor = false,
            BackgroundTransparency = 1,
            TextTransparency = 1
        })
        New("UICorner", { Parent = HoldBtn, CornerRadius = UDim.new(0, 5) })

        Tween(ModeFrame, { BackgroundTransparency = 0 }, 0.2, Enum.EasingStyle.Sine)
        Tween(frameStroke, { Transparency = 0.5 }, 0.2, Enum.EasingStyle.Sine)
        Tween(ToggleBtn, { BackgroundTransparency = 0, TextTransparency = 0 }, 0.2, Enum.EasingStyle.Sine)
        Tween(HoldBtn, { BackgroundTransparency = 0, TextTransparency = 0 }, 0.2, Enum.EasingStyle.Sine)

        local function closeMenu()
            Tween(ModeFrame, { BackgroundTransparency = 1 }, 0.15, Enum.EasingStyle.Sine)
            Tween(frameStroke, { Transparency = 1 }, 0.15, Enum.EasingStyle.Sine)
            Tween(ToggleBtn, { BackgroundTransparency = 1, TextTransparency = 1 }, 0.15, Enum.EasingStyle.Sine)
            Tween(HoldBtn, { BackgroundTransparency = 1, TextTransparency = 1 }, 0.15, Enum.EasingStyle.Sine)
            task.wait(0.15)
            ModeGui:Destroy()
            modeMenuOpen = false
            if Library.ModeMenus then
                for i = #Library.ModeMenus, 1, -1 do
                    if Library.ModeMenus[i].gui == ModeGui then
                        table.remove(Library.ModeMenus, i); break
                    end
                end
            end
        end

        ToggleBtn.MouseButton1Click:Connect(function()
            K.Mode = "Toggle"
            if K.Active then
                K.Active = false; callback(false); refreshKeybindsWindow()
            end
            Tween(ToggleBtn, { BackgroundColor3 = C.Accent }, 0.1)
            Tween(HoldBtn, { BackgroundColor3 = C.Section }, 0.1)
            autoSave(configPath, { Key = K.Key and K.Key.Name or nil, Mode = K.Mode })
            closeMenu()
        end)
        HoldBtn.MouseButton1Click:Connect(function()
            K.Mode = "Hold"
            if K.Active then
                K.Active = false; callback(false); refreshKeybindsWindow()
            end
            Tween(HoldBtn, { BackgroundColor3 = C.Accent }, 0.1)
            Tween(ToggleBtn, { BackgroundColor3 = C.Section }, 0.1)
            autoSave(configPath, { Key = K.Key and K.Key.Name or nil, Mode = K.Mode })
            closeMenu()
        end)

        ToggleBtn.MouseEnter:Connect(function()
            if K.Mode ~= "Toggle" then
                Tween(ToggleBtn, {
                    BackgroundColor3 = C
                        .Accent
                }, 0.15)
            end
        end)
        ToggleBtn.MouseLeave:Connect(function()
            if K.Mode ~= "Toggle" then
                Tween(ToggleBtn,
                    { BackgroundColor3 = C.Section }, 0.15)
            end
        end)
        HoldBtn.MouseEnter:Connect(function()
            if K.Mode ~= "Hold" then
                Tween(HoldBtn, { BackgroundColor3 = C.Accent },
                    0.15)
            end
        end)
        HoldBtn.MouseLeave:Connect(function()
            if K.Mode ~= "Hold" then
                Tween(HoldBtn, { BackgroundColor3 = C.Section },
                    0.15)
            end
        end)

        local closeConnection = UIS.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                local mp = Vector2.new(input.Position.X, input.Position.Y)
                local fp = ModeFrame.AbsolutePosition
                local fs = ModeFrame.AbsoluteSize
                if mp.X < fp.X or mp.X > fp.X + fs.X or mp.Y < fp.Y or mp.Y > fp.Y + fs.Y then
                    closeConnection:Disconnect()
                    closeMenu()
                end
            end
        end)

        if not Library.ModeMenus then Library.ModeMenus = {} end
        table.insert(Library.ModeMenus, { gui = ModeGui, close = closeMenu })
    end)

    KeyBtn.MouseEnter:Connect(function()
        if not K.Editing then Tween(KeyBtn, { TextColor3 = C.Text }, 0.15) end
    end)
    KeyBtn.MouseLeave:Connect(function()
        if not K.Editing then Tween(KeyBtn, { TextColor3 = C.TextDim }, 0.15) end
    end)

    UIS.InputBegan:Connect(function(input, gameProcessed)
        if K.Editing then
            local key = input.KeyCode
            if key == Enum.KeyCode.Unknown and (input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3) then
                key = input.UserInputType
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

    UIS.InputEnded:Connect(function(input, _gameProcessed)
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

    ConfigSystem.Elements[configPath] = K

    return K
end

function Library:CreateInput(section, config)
    config = config or {}
    local name = config.Name or "Input"
    local default = config.Default or ""
    local placeholder = config.Placeholder or "Enter text..."
    local callback = config.Callback or function() end

    local configPath = section.Category.TopTab.Name .. "_" .. section.Category.Name .. "_" .. section.Name .. "_" .. name

    local I = { Value = default, Callback = callback, ConfigPath = configPath }

    local Frame = New("Frame", {
        Parent = section.Container,
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundTransparency = 1
    })

    local Label = New("TextLabel", {
        Parent = Frame,
        Position = UDim2.new(0, 8, 0, 0),
        Size = UDim2.new(1, -8, 0, 16),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = C.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.Gotham
    })

    local Box = New("TextBox", {
        Parent = Frame,
        Position = UDim2.new(0, 0, 0, 20),
        Size = UDim2.new(1, 0, 0, 26),
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

    New("UICorner", { Parent = Box, CornerRadius = UDim.new(0, 7) })
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

    Box.FocusLost:Connect(function(enterPressed)
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
            autoSave(configPath, v)
        end
    end

    function I:GetValue()
        return I.Value
    end

    ConfigSystem.Elements[configPath] = I

    spawn(function()
        task.wait(0.1)
        if Library.Windows and Library.Windows[1] and Library.Windows[1].RegisterElement then
            Library.Windows[1]:RegisterElement(name, section.Category.TopTab.Name, section.Category.Name, Frame,
                section.Frame, section.Column)
        end
    end)

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

    if syn and syn.protect_gui then
        syn.protect_gui(KeybindsGui)
        KeybindsGui.Parent = game:GetService("CoreGui")
    elseif gethui then
        KeybindsGui.Parent = gethui()
    else
        KeybindsGui.Parent = game:GetService("CoreGui")
    end

    local KeybindsFrame = New("Frame", {
        Name = "KeybindsFrame",
        Parent = KeybindsGui,
        Position = UDim2.new(0, 12, 0.5, -150),
        Size = UDim2.new(0, 190, 0, 0),
        BackgroundColor3 = Color3.fromRGB(14, 14, 19),
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y
    })

    New("UICorner", { Parent = KeybindsFrame, CornerRadius = UDim.new(0, 10) })
    New("UIStroke", {
        Parent = KeybindsFrame,
        Color = C.Border,
        Thickness = 1,
        Transparency = 0.2
    })

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
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(0, #HeaderText * letterSpacing, 1, 0),
        BackgroundTransparency = 1
    })

    local headerLetters = {}
    local baseColor = C.Accent
    local glowColor = Color3.fromRGB(220, 200, 255)

    for i = 1, #HeaderText do
        local char = HeaderText:sub(i, i)
        local letter = New("TextLabel", {
            Parent = headerContainer,
            Position = UDim2.new(0, (i - 1) * letterSpacing, 0, 0),
            Size = UDim2.new(0, letterSpacing, 1, 0),
            BackgroundTransparency = 1,
            Text = char,
            TextColor3 = baseColor,
            TextSize = 14,
            Font = Enum.Font.Code,
            TextXAlignment = Enum.TextXAlignment.Center
        })
        table.insert(headerLetters, letter)
    end

    spawn(function()
        while true do
            for i, letter in ipairs(headerLetters) do
                spawn(function()
                    local h, s, v = C.Accent:ToHSV()
                    local currentGlow = Color3.fromHSV(h, math.max(s - 0.2, 0), math.min(v + 0.3, 1))

                    Tween(letter, { TextColor3 = currentGlow }, 0.3, Enum.EasingStyle.Sine)
                    task.wait(0.3)
                    Tween(letter, { TextColor3 = C.Accent }, 0.4, Enum.EasingStyle.Sine)
                end)
                task.wait(0.08)
            end
            task.wait(1.5)
        end
    end)

    local Separator = New("Frame", {
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
        PaddingBottom = UDim.new(0, 8),
        PaddingTop = UDim.new(0, 0)
    })

    local KB = {
        Frame = KeybindsFrame,
        Container = Container,
        Items = {},
        HeaderLetters = headerLetters,
        GlowColor = glowColor
    }

    local dragging, dragInput, dragStart, startPos

    KeybindsFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = KeybindsFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    RS.RenderStepped:Connect(function(dt)
        if dragging and dragInput then
            local delta = dragInput.Position - dragStart
            local target = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
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

        New("UICorner", { Parent = AccentBar, CornerRadius = UDim.new(1, 0) })

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
            AccentBar.Visible = newActive
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

    KeybindsFrame.BackgroundTransparency = 1
    for _, child in pairs(KeybindsFrame:GetDescendants()) do
        if child:IsA("TextLabel") or child:IsA("Frame") then
            if child:IsA("TextLabel") then
                child.TextTransparency = 1
            elseif child.Name ~= "KeybindsFrame" and child.Name ~= "Container" and child.Name ~= "HeaderContainer" then
                child.BackgroundTransparency = 1
            end
        end
    end

    task.wait(0.3)
    Tween(KeybindsFrame, { BackgroundTransparency = 0 }, 0.5, Enum.EasingStyle.Sine)
    for _, child in pairs(KeybindsFrame:GetDescendants()) do
        if child:IsA("TextLabel") then
            Tween(child, { TextTransparency = 0 }, 0.5, Enum.EasingStyle.Sine)
        elseif child:IsA("Frame") and (child.Name == "Separator" or child.Name == "AccentLine") then
            Tween(child, { BackgroundTransparency = 0 }, 0.5, Enum.EasingStyle.Sine)
        end
    end

    Library.KeybindsWindow = KB

    function KB:SetVisible(visible)
        KeybindsGui.Enabled = visible
    end

    if Library.KeybindToggles then
        for _, toggle in pairs(Library.KeybindToggles) do
            if toggle.HasKeybind and toggle.KeybindKey then
                KB:UpdateKeybind(toggle.Name, toggle.KeybindKey.Name, toggle.Value)
            end
        end
    end

    return KB
end

function Library:CreateColorPicker(section, config)
    config = config or {}
    local name = config.Name or "Color"
    local default = config.Default or Color3.fromRGB(110, 139, 255)
    local callback = config.Callback or function() end

    local configPath = section.Category.TopTab.Name .. "_" .. section.Category.Name .. "_" .. section.Name .. "_" .. name

    local CP = { Color = default, Hue = 0, Sat = 0, Val = 0, Callback = callback, ConfigPath = configPath, Open = false }
    CP.Hue, CP.Sat, CP.Val = default:ToHSV()

    local Frame = New("Frame", { Parent = section.Container, Size = UDim2.new(1, 0, 0, 26), BackgroundColor3 = C.Element, BackgroundTransparency = 1, BorderSizePixel = 0 })
    New("UICorner", { Parent = Frame, CornerRadius = UDim.new(0, 6) })
    local Label = New("TextLabel",
        {
            Parent = Frame,
            Position = UDim2.new(0, 8, 0, 0),
            Size = UDim2.new(1, -48, 1, 0),
            BackgroundTransparency = 1,
            Text = name,
            TextColor3 = C.Text,
            TextSize = 13,
            TextXAlignment =
                Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Font = Enum.Font.Gotham
        })
    local ColorBox = New("Frame",
        {
            Parent = Frame,
            Position = UDim2.new(1, -6, 0.5, 0),
            AnchorPoint = Vector2.new(1, 0.5),
            Size = UDim2
                .fromOffset(28, 16),
            BackgroundColor3 = default,
            BorderSizePixel = 0
        })
    New("UICorner", { Parent = ColorBox, CornerRadius = UDim.new(0, 5) })
    New("UIStroke", { Parent = ColorBox, Color = Color3.fromRGB(255, 255, 255), Thickness = 1, Transparency = 0.8 })

    local Btn = New("TextButton", { Parent = Frame, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "" })
    Btn.MouseEnter:Connect(function()
        Tween(Frame, { BackgroundTransparency = 0.5 }, 0.15); Frame.BackgroundColor3 = C.Element
    end)
    Btn.MouseLeave:Connect(function() Tween(Frame, { BackgroundTransparency = 1 }, 0.15) end)

    if config.Tooltip then
        Library:AttachTooltip(Btn, config.Tooltip)
    end

    local PickerGui = New("ScreenGui",
        { Name = "ColorPicker", ZIndexBehavior = Enum.ZIndexBehavior.Sibling, ResetOnSpawn = false })
    if syn and syn.protect_gui then
        syn.protect_gui(PickerGui); PickerGui.Parent = game:GetService("CoreGui")
    elseif gethui then
        PickerGui.Parent = gethui()
    else
        PickerGui.Parent = game:GetService("CoreGui")
    end

    local PickerFrame = New("Frame",
        {
            Name = "PickerFrame",
            Parent = PickerGui,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0, 200,
                0, 206),
            BackgroundColor3 = C.Section,
            BorderSizePixel = 0,
            Visible = false
        })
    New("UICorner", { Parent = PickerFrame, CornerRadius = UDim.new(0, 10) })
    New("UIStroke", { Parent = PickerFrame, Color = C.Accent, Thickness = 1, Transparency = 0.5 })
    local PickerScale = New("UIScale", { Parent = PickerFrame, Scale = 1 })

    local SatVal = New("ImageButton",
        {
            Name = "SatVal",
            Parent = PickerFrame,
            Position = UDim2.new(0, 10, 0, 10),
            Size = UDim2.new(0, 160, 0, 160),
            BackgroundColor3 =
                Color3.fromHSV(CP.Hue, 1, 1),
            BorderSizePixel = 0,
            Image = "rbxassetid://8180999986",
            ImageColor3 = Color3.new(0,
                0, 0),
            AutoButtonColor = false
        })
    New("UICorner", { Parent = SatVal, CornerRadius = UDim.new(0, 6) })

    local SatValCursor = New("Frame",
        {
            Name = "Cursor",
            Parent = SatVal,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(CP.Sat,
                1 - CP.Val),
            Size = UDim2.fromOffset(10, 10),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0
        })
    New("UICorner", { Parent = SatValCursor, CornerRadius = UDim.new(1, 0) })
    New("UIStroke", { Parent = SatValCursor, Color = Color3.new(0, 0, 0), Thickness = 2 })

    local HueSlider = New("ImageButton",
        {
            Name = "Hue",
            Parent = PickerFrame,
            Position = UDim2.new(0, 175, 0, 10),
            Size = UDim2.new(0, 15, 0, 160),
            BackgroundColor3 =
                Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            Image = "rbxassetid://8180989234",
            ScaleType = Enum.ScaleType.Crop,
            AutoButtonColor = false
        })
    New("UICorner", { Parent = HueSlider, CornerRadius = UDim.new(1, 0) })
    local HueCursor = New("Frame",
        {
            Name = "Cursor",
            Parent = HueSlider,
            Position = UDim2.fromScale(0, CP.Hue),
            Size = UDim2.new(1, 0, 0, 3),
            BackgroundColor3 =
                Color3.new(1, 1, 1),
            BorderSizePixel = 0
        })
    New("UICorner", { Parent = HueCursor, CornerRadius = UDim.new(1, 0) })

    local HexBox = New("TextBox",
        {
            Name = "Hex",
            Parent = PickerFrame,
            Position = UDim2.new(0, 10, 0, 177),
            Size = UDim2.new(1, -20, 0, 20),
            BackgroundColor3 =
                C.Chip,
            BorderSizePixel = 0,
            Text = "#" .. default:ToHex():upper(),
            TextColor3 = C.Text,
            TextSize = 12,
            Font =
                Enum.Font.Code,
            ClearTextOnFocus = false
        })
    New("UICorner", { Parent = HexBox, CornerRadius = UDim.new(0, 6) })
    New("UIPadding", { Parent = HexBox, PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) })

    function CP:UpdateColor(skipSave)
        CP.Color = Color3.fromHSV(CP.Hue, CP.Sat, CP.Val)
        ColorBox.BackgroundColor3 = CP.Color
        SatVal.BackgroundColor3 = Color3.fromHSV(CP.Hue, 1, 1)
        HexBox.Text = "#" .. CP.Color:ToHex():upper()
        SatValCursor.Position = UDim2.fromScale(CP.Sat, 1 - CP.Val)
        HueCursor.Position = UDim2.fromScale(0, CP.Hue)
        callback(CP.Color)
        if not skipSave then
            autoSave(configPath, { CP.Hue, CP.Sat, CP.Val })
        end
    end

    function CP:SetValue(color, skipSave)
        if typeof(color) == "Color3" then
            CP.Color = color
            CP.Hue, CP.Sat, CP.Val = color:ToHSV()
        elseif typeof(color) == "table" and #color == 3 then
            CP.Hue, CP.Sat, CP.Val = color[1], color[2], color[3]
            CP.Color = Color3.fromHSV(CP.Hue, CP.Sat, CP.Val)
        end

        ColorBox.BackgroundColor3 = CP.Color
        SatVal.BackgroundColor3 = Color3.fromHSV(CP.Hue, 1, 1)
        HexBox.Text = "#" .. CP.Color:ToHex():upper()
        SatValCursor.Position = UDim2.fromScale(CP.Sat, 1 - CP.Val)
        HueCursor.Position = UDim2.fromScale(0, CP.Hue)

        callback(CP.Color)

        if not skipSave then
            autoSave(configPath, { CP.Hue, CP.Sat, CP.Val })
        end
    end

    function CP:GetValue() return { CP.Hue, CP.Sat, CP.Val } end

    local satValDragging = false
    SatVal.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            satValDragging = true; local pos = (Vector2.new(input.Position.X, input.Position.Y) - SatVal.AbsolutePosition) /
                SatVal.AbsoluteSize; CP.Sat = math.clamp(pos.X, 0, 1); CP.Val = math.clamp(1 - pos.Y, 0, 1); CP
                :UpdateColor()
        end
    end)
    SatVal.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then satValDragging = false end end)
    UIS.InputChanged:Connect(function(input)
        if satValDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local pos = (Vector2.new(input.Position.X, input.Position.Y) - SatVal.AbsolutePosition) / SatVal
                .AbsoluteSize; CP.Sat = math.clamp(pos.X, 0, 1); CP.Val = math.clamp(1 - pos.Y, 0, 1); CP:UpdateColor()
        end
    end)

    local hueDragging = false
    HueSlider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            hueDragging = true; local pos = (input.Position.Y - HueSlider.AbsolutePosition.Y) / HueSlider.AbsoluteSize.Y; CP.Hue =
                math.clamp(pos, 0, 1); CP:UpdateColor()
        end
    end)
    HueSlider.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then hueDragging = false end end)
    UIS.InputChanged:Connect(function(input)
        if hueDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local pos = (input.Position.Y - HueSlider.AbsolutePosition.Y) / HueSlider.AbsoluteSize.Y; CP.Hue = math
                .clamp(pos, 0, 1); CP:UpdateColor()
        end
    end)

    HexBox.FocusLost:Connect(function()
        pcall(function()
            local hex = HexBox.Text:gsub("#", ""); local color = Color3.fromHex(hex); CP:SetValue(color)
        end)
    end)

    function CP:Close()
        CP.Open = false
        PickerFrame.Visible = false
    end

    Btn.MouseButton1Click:Connect(function()
        if CP.Open then
            CP:Close()
        else
            local anyOtherOpen = false
            if Library.ColorPickers then
                for _, picker in pairs(Library.ColorPickers) do
                    if picker ~= CP and picker.Open then
                        anyOtherOpen = true
                        break
                    end
                end
            end

            if not anyOtherOpen then
                CP.Open = true
                PickerScale.Scale = 0.9
                PickerFrame.Visible = true
                Tween(PickerScale, { Scale = 1 }, 0.3, Enum.EasingStyle.Back)
            end
        end
    end)

    local closeConnection
    closeConnection = UIS.InputBegan:Connect(function(input, gameProcessed)
        if CP.Open and input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mousePos = Vector2.new(input.Position.X, input.Position.Y)
            local framePos = PickerFrame.AbsolutePosition
            local frameSize = PickerFrame.AbsoluteSize

            if mousePos.X < framePos.X or mousePos.X > framePos.X + frameSize.X or
                mousePos.Y < framePos.Y or mousePos.Y > framePos.Y + frameSize.Y then
                CP:Close()
            end
        end
    end)

    ConfigSystem.Elements[configPath] = CP

    if not Library.ColorPickers then
        Library.ColorPickers = {}
    end
    table.insert(Library.ColorPickers, CP)

    return CP
end

-- CreateNotification config:
--   Message  = "text"
--   Duration = 3
--   Sound    = "Enable" / "Disable"
--   Type     = "success" / "warning" / "error"   (optional, changes the bar color; default uses accent)
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
    local barColor = typeColors[tostring(config.Type or ""):lower()] or C.Accent

    Library:PlayNotificationSound(soundType)

    if not Library.NotificationGui then
        local NotifGui = New("ScreenGui", {
            Name = "rubyazlNotifications",
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            ResetOnSpawn = false
        })

        if syn and syn.protect_gui then
            syn.protect_gui(NotifGui)
            NotifGui.Parent = game:GetService("CoreGui")
        elseif gethui then
            NotifGui.Parent = gethui()
        else
            NotifGui.Parent = game:GetService("CoreGui")
        end

        Library.NotificationGui = NotifGui
        Library.Notifications = {}
    end

    local TextService = game:GetService("TextService")
    local textSize = TextService:GetTextSize(message, 13, Enum.Font.GothamMedium, Vector2.new(math.huge, 20))
    local notifWidth = textSize.X + 36

    local notifCount = #Library.Notifications
    local yOffset = notifCount * 38

    local NotifContainer = New("Frame", {
        Name = "NotificationContainer",
        Parent = Library.NotificationGui,
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 0.92, -yOffset + 16),
        Size = UDim2.new(0, notifWidth, 0, 30),
        BackgroundTransparency = 1,
        ZIndex = 10
    })

    local NotifFrame = New("Frame", {
        Name = "Notification",
        Parent = NotifContainer,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(18, 18, 24),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 10
    })

    New("UICorner", { Parent = NotifFrame, CornerRadius = UDim.new(0, 8) })

    local NotifStroke = New("UIStroke", {
        Parent = NotifFrame,
        Color = C.Border,
        Thickness = 1,
        Transparency = 1
    })

    local AccentBar = New("Frame", {
        Name = "AccentBar",
        Parent = NotifContainer,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 8, 0.5, 0),
        Size = UDim2.new(0, 3, 0, 14),
        BackgroundColor3 = barColor,
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        ZIndex = 11
    })

    New("UICorner", { Parent = AccentBar, CornerRadius = UDim.new(1, 0) })

    local Progress = New("Frame", {
        Name = "Progress",
        Parent = NotifContainer,
        Position = UDim2.new(0, 12, 1, -4),
        Size = UDim2.new(1, -24, 0, 2),
        BackgroundColor3 = barColor,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 12
    })

    New("UICorner", { Parent = Progress, CornerRadius = UDim.new(1, 0) })

    local MessageText = New("TextLabel", {
        Name = "Message",
        Parent = NotifFrame,
        Position = UDim2.new(0, 16, 0, 0),
        Size = UDim2.new(1, -22, 1, -2),
        BackgroundTransparency = 1,
        Text = message,
        TextColor3 = Color3.fromRGB(230, 230, 240),
        TextSize = 13,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTransparency = 1,
        ZIndex = 11
    })

    table.insert(Library.Notifications, NotifContainer)

    spawn(function()
        Tween(NotifContainer, { Position = UDim2.new(0.5, 0, 0.92, -yOffset) }, 0.45, Enum.EasingStyle.Back)
        Tween(AccentBar, { BackgroundTransparency = 0 }, 0.3, Enum.EasingStyle.Quad)
        Tween(NotifFrame, { BackgroundTransparency = 0.05 }, 0.3, Enum.EasingStyle.Quad)
        Tween(NotifStroke, { Transparency = 0.3 }, 0.3, Enum.EasingStyle.Quad)
        Tween(MessageText, { TextTransparency = 0 }, 0.3, Enum.EasingStyle.Quad)
        Tween(Progress, { BackgroundTransparency = 0.45 }, 0.3, Enum.EasingStyle.Quad)

        Tween(Progress, { Size = UDim2.new(0, 0, 0, 2) }, duration, Enum.EasingStyle.Linear)

        task.wait(duration)

        Tween(AccentBar, { BackgroundTransparency = 1 }, 0.3, Enum.EasingStyle.Quad)
        Tween(NotifFrame, { BackgroundTransparency = 1 }, 0.3, Enum.EasingStyle.Quad)
        Tween(NotifStroke, { Transparency = 1 }, 0.3, Enum.EasingStyle.Quad)
        Tween(MessageText, { TextTransparency = 1 }, 0.3, Enum.EasingStyle.Quad)
        Tween(Progress, { BackgroundTransparency = 1 }, 0.3, Enum.EasingStyle.Quad)

        task.wait(0.3)

        for i, notif in pairs(Library.Notifications) do
            if notif == NotifContainer then
                table.remove(Library.Notifications, i)
                break
            end
        end

        NotifContainer:Destroy()

        for i, notif in pairs(Library.Notifications) do
            if notif and notif.Parent then
                Tween(notif, { Position = UDim2.new(0.5, 0, 0.92, -((i - 1) * 38)) }, 0.3, Enum.EasingStyle.Quint)
            end
        end
    end)
end

return Library
