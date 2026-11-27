--[[
    noir
    ---------------------------------------------------------------
    local Library = loadstring(game:HttpGet("https://github.com/blacknoirs/azl/raw/main/verity.lua"))()

    local Window = Library:CreateWindow({
        Name = "MyHub",            -- unique id: GUI names + single-instance guard
        Title = "My Hub",          -- sidebar title
        Subtitle = "beta",         -- sidebar subtitle (defaults to Build)
        Build = "1.0",             -- footer / watermark text
        Folder = "myhub",          -- config folder (defaults to Name)
        ToggleKey = Enum.KeyCode.K,
        Icon = nil,                -- lucide name / asset id / url
        IconTint = nil,
        Watermark = true,          -- false to disable
        WatermarkText = "myhub",
        Sounds = true,             -- false to disable notification sounds
        AutoLoad = true,           -- auto load "default" config
    })

    local Tab = Window:CreateTab("Main", "home")
    local Cat = Tab:CreateCategory("General", "settings")
    local Sec = Cat:CreateSection("Section", "left", "sword")

    Sec:AddToggle / AddSlider / AddDropdown / AddButton / AddKeybind /
        AddInput / AddColorPicker / AddLabel

    Old style (Library:CreateToggle(sec, cfg), W:CreateTopTab, W:CreateCategory,
    Library:CreateSection) still works.
]]

local Library = {}
local TS = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local HS = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local Players = game:GetService("Players")

local genv = (getgenv and getgenv()) or _G

Library.IsMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled
Library.Guis = {}
Library.Connections = {}
Library.Components = {}
Library.Name = "UILib"
Library.Prefix = "UILib"

local ConfigSystem = {
    FolderName = "UILib",
    CurrentConfig = "default",
    Configs = {},
    Elements = {}
}

local function guiName(suffix)
    return Library.Prefix .. (suffix or "")
end

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
    Loading = false,
    Sounds = {},
    URLs = {
        Enable = "https://file.garden/ae9fcAfELjoYT26a/Function_ON.wav",
        Disable = "https://file.garden/ae9fcAfELjoYT26a/Function_OFF.wav"
    }
}

function Library:LoadNotificationSounds()
    if Library.NotificationSounds.Enabled or Library.NotificationSounds.Loading then return end
    Library.NotificationSounds.Loading = true

    task.spawn(function()
        for soundName, url in pairs(Library.NotificationSounds.URLs) do
            pcall(function()
                local filename = ConfigSystem.FolderName .. "_notif_" .. soundName:lower() .. ".wav"

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
        Library.NotificationSounds.Loading = false
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
    BG = Color3.fromRGB(10, 11, 15),
    Sidebar = Color3.fromRGB(13, 14, 19),
    TopBar = Color3.fromRGB(15, 16, 22),
    Section = Color3.fromRGB(19, 20, 28),
    Element = Color3.fromRGB(26, 27, 37),
    ElementHover = Color3.fromRGB(34, 36, 49),
    ElementActive = Color3.fromRGB(41, 43, 59),
    Accent = Color3.fromHex("7C8CFF"),
    Text = Color3.fromRGB(233, 235, 245),
    TextDim = Color3.fromRGB(139, 143, 166),
    TextMuted = Color3.fromRGB(92, 96, 118),
    Border = Color3.fromRGB(35, 37, 51),
    BorderStrong = Color3.fromRGB(54, 57, 78),
    SliderBg = Color3.fromRGB(40, 42, 57),
    Chip = Color3.fromRGB(32, 34, 46),
    Success = Color3.fromRGB(90, 220, 140),
    Warning = Color3.fromRGB(255, 190, 80),
    Danger = Color3.fromRGB(255, 95, 110)
}

Library.Colors = C
Library.Theme = C

Library.Metrics = {
    Radius = 12,
    RadiusMd = 8,
    RadiusSm = 6,
    Row = Library.IsMobile and 40 or 32,
    Slider = Library.IsMobile and 56 or 46,
    Input = Library.IsMobile and 62 or 56,
    Option = Library.IsMobile and 32 or 24,
    Gap = 6,
    Pad = 12,
    SectionHeader = 36,
    SidebarWide = 176,
    SidebarCompact = 56,
    TopBar = 48,
    CategoryStrip = 38,
    Footer = 24
}

local M = Library.Metrics

Library.AccentElements = {}
Library.AccentTextElements = {}
Library.AccentImages = {}
Library.AccentIcons = {}
Library.BorderGradients = {}

-- Call BEFORE CreateWindow to change the theme colors.
function Library:SetTheme(theme)
    for key, value in pairs(theme or {}) do
        if C[key] ~= nil and typeof(value) == "Color3" then
            C[key] = value
        end
    end
end

local function buildBorderSequence(accent)
    local mid = C.BorderStrong:Lerp(accent, 0.5)
    return ColorSequence.new({
        ColorSequenceKeypoint.new(0, C.BorderStrong),
        ColorSequenceKeypoint.new(0.25, mid),
        ColorSequenceKeypoint.new(0.5, C.BorderStrong),
        ColorSequenceKeypoint.new(0.75, mid),
        ColorSequenceKeypoint.new(1, C.BorderStrong)
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

local function Stroke(parent, color, thickness, transparency)
    return New("UIStroke", {
        Parent = parent,
        Color = color,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    })
end

local function Pad(parent, l, t, r, b)
    return New("UIPadding", {
        Parent = parent,
        PaddingLeft = UDim.new(0, l or 0),
        PaddingTop = UDim.new(0, t or 0),
        PaddingRight = UDim.new(0, r or 0),
        PaddingBottom = UDim.new(0, b or 0)
    })
end

local function Sheen(parent, radius, strength)
    local frame = New("Frame", {
        Name = "Sheen",
        Parent = parent,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Active = false
    })
    Corner(frame, radius)
    New("UIGradient", {
        Parent = frame,
        Rotation = 90,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1 - (strength or 0.045)),
            NumberSequenceKeypoint.new(1, 1)
        })
    })
    return frame
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
        local w = section.Category and section.Category.TopTab and section.Category.TopTab.Window
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

local Lucide = {
    Module = nil,
    Provider = nil,
    Loading = false,
    Ready = false,
    Cache = {},
    Registered = {},
    URLs = {
        "https://raw.githubusercontent.com/Footagesus/Icons/main/Main.lua"
    }
}

Library.Lucide = Lucide

local function normalizeName(name)
    if typeof(name) ~= "string" then return nil end
    local key = name:lower():gsub("^lucide[:%-]", ""):gsub("[_%s]+", "-")
    return key
end

local function normalizeIconData(a, b, c)
    local image, offset, size

    if typeof(a) == "table" then
        local meta = typeof(a[2]) == "table" and a[2] or a
        image = a.Image or a.Id or a.id or a[1]
        offset = meta.ImageRectPosition or meta.ImageRectOffset or meta.Offset or meta.Position
        size = meta.ImageRectSize or meta.Size
    elseif typeof(a) == "string" or typeof(a) == "number" then
        image = a
        if typeof(b) == "Vector2" then size = b end
        if typeof(c) == "Vector2" then offset = c end
        if typeof(b) == "table" then
            offset = b.ImageRectPosition or b.ImageRectOffset
            size = b.ImageRectSize
        end
    end

    if image == nil or image == "" then return nil end
    if typeof(image) == "number" then image = "rbxassetid://" .. tostring(image) end
    if typeof(image) ~= "string" then return nil end
    if image:match("^%d+$") then image = "rbxassetid://" .. image end

    return {
        Image = image,
        Offset = typeof(offset) == "Vector2" and offset or Vector2.new(0, 0),
        Size = typeof(size) == "Vector2" and size or Vector2.new(0, 0)
    }
end

function Lucide.Load()
    if Lucide.Loading or Lucide.Ready or Lucide.Module or Lucide.Provider then return end
    Lucide.Loading = true

    task.spawn(function()
        for _, url in ipairs(Lucide.URLs) do
            local ok, mod = pcall(function()
                return loadstring(game:HttpGet(url))()
            end)
            if ok and mod then
                Lucide.Module = mod
                pcall(function()
                    if mod.SetIconsType then mod.SetIconsType("lucide") end
                end)
                break
            end
        end
        Lucide.Loading = false
        Lucide.Ready = true
    end)
end

function Lucide.Resolve(name)
    local key = normalizeName(name)
    if not key or key == "" then return nil end
    if Lucide.Registered[key] then return Lucide.Registered[key] end
    if Lucide.Cache[key] ~= nil then return Lucide.Cache[key] or nil end

    local result

    if Lucide.Provider then
        local ok, a, b, c = pcall(Lucide.Provider, key)
        if ok then result = normalizeIconData(a, b, c) end
    elseif Lucide.Module then
        local mod = Lucide.Module

        local ok, a, b, c = pcall(function()
            return mod.GetIcon(key)
        end)

        if ok then
            result = normalizeIconData(a, b, c)
        end

        if not result then
            ok, a, b, c = pcall(function()
                return mod.Icon(key)
            end)

            if ok then
                result = normalizeIconData(a, b, c)
            end
        end
    end

    if Lucide.Ready or Lucide.Provider then
        Lucide.Cache[key] = result or false
    end

    return result
end

local function awaitLucide()
    Lucide.Load()
    local waited = 0
    while not (Lucide.Ready or Lucide.Provider) and waited < 10 do
        waited = waited + task.wait(0.05)
    end
end

function Library:SetIconProvider(fn)
    Lucide.Provider = fn
    Lucide.Cache = {}
end

function Library:SetIconSource(url)
    table.insert(Lucide.URLs, 1, url)
    Lucide.Module = nil
    Lucide.Ready = false
    Lucide.Loading = false
    Lucide.Cache = {}
    Lucide.Load()
end

function Library:RegisterIcon(name, image, offset, size)
    local key = normalizeName(name)
    if not key then return end
    Lucide.Registered[key] = normalizeIconData(image, size, offset)
end

local iconCache = {}

local function resolveRaw(icon)
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

local function looksLikeLucide(icon)
    if typeof(icon) ~= "string" then return false end
    if icon:match("^lucide[:%-]") then return true end
    if icon:match("^rbx") then return false end
    return icon:match("^%a[%w%-_ ]*$") ~= nil
end

local function resolveIconData(icon)
    if icon == nil or icon == "" then return nil end

    if looksLikeLucide(icon) then
        local key = normalizeName(icon)
        if Lucide.Registered[key] then return Lucide.Registered[key] end
        awaitLucide()
        return Lucide.Resolve(key)
    end

    local raw = resolveRaw(icon)
    if raw then
        return { Image = raw, Offset = Vector2.new(0, 0), Size = Vector2.new(0, 0) }
    end

    return nil
end

local function applyIconData(img, data)
    img.Image = data.Image
    img.ImageRectOffset = data.Offset
    img.ImageRectSize = data.Size
end

Library.ResolveIcon = function(icon)
    local data = resolveIconData(icon)
    return data and data.Image or nil
end

local function buildFallback(root, key, color)
    local parts, strokes = {}, {}

    local function bar(width, x, y, rotation, thickness)
        local f = New("Frame", {
            Parent = root,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(x, y),
            Size = UDim2.new(width, 0, 0, thickness or 2),
            BackgroundColor3 = color,
            BorderSizePixel = 0,
            Rotation = rotation or 0
        })
        Corner(f, 1)
        table.insert(parts, f)
    end

    if key == "x" then
        bar(0.85, 0.5, 0.5, 45)
        bar(0.85, 0.5, 0.5, -45)
    elseif key == "check" then
        bar(0.3, 0.3, 0.65, 45)
        bar(0.6, 0.6, 0.525, -48)
    elseif key == "chevron-down" then
        bar(0.42, 0.35, 0.5, 45)
        bar(0.42, 0.65, 0.5, -45)
    elseif key == "menu" then
        bar(0.7, 0.5, 0.28)
        bar(0.7, 0.5, 0.5)
        bar(0.7, 0.5, 0.72)
    elseif key == "search" then
        local ring = New("Frame", {
            Parent = root,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.43, 0.43),
            Size = UDim2.fromScale(0.56, 0.56),
            BackgroundTransparency = 1,
            BorderSizePixel = 0
        })
        Corner(ring, 99)
        table.insert(strokes, Stroke(ring, color, 2, 0))
        bar(0.34, 0.78, 0.78, 45)
    else
        local box = New("Frame", {
            Parent = root,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromScale(0.7, 0.7),
            BackgroundTransparency = 1,
            BorderSizePixel = 0
        })
        Corner(box, 4)
        table.insert(strokes, Stroke(box, color, 1.5, 0))
    end

    return parts, strokes
end

local function CreateIcon(parent, name, size, color, props)
    props = props or {}

    local I = {
        Color = color or C.TextDim,
        Parts = {},
        Strokes = {},
        Token = 0,
        Name = name
    }

    I.Root = New("Frame", {
        Name = "Icon",
        Parent = parent,
        AnchorPoint = props.AnchorPoint or Vector2.new(0, 0),
        Position = props.Position or UDim2.new(0, 0, 0, 0),
        Size = UDim2.fromOffset(size, size),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        LayoutOrder = props.LayoutOrder or 0
    })

    I.Image = New("ImageLabel", {
        Name = "Image",
        Parent = I.Root,
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Image = "",
        ImageColor3 = I.Color,
        ScaleType = Enum.ScaleType.Fit,
        Visible = false
    })

    function I:SetColor(c, t)
        I.Color = c
        if t and t > 0 then
            Tween(I.Image, { ImageColor3 = c }, t, Enum.EasingStyle.Sine)
            for _, p in ipairs(I.Parts) do
                if p.Parent then Tween(p, { BackgroundColor3 = c }, t, Enum.EasingStyle.Sine) end
            end
            for _, s in ipairs(I.Strokes) do
                if s.Parent then Tween(s, { Color = c }, t, Enum.EasingStyle.Sine) end
            end
        else
            I.Image.ImageColor3 = c
            for _, p in ipairs(I.Parts) do
                if p.Parent then p.BackgroundColor3 = c end
            end
            for _, s in ipairs(I.Strokes) do
                if s.Parent then s.Color = c end
            end
        end
    end

    function I:SetIcon(icon)
        I.Token = I.Token + 1
        local token = I.Token
        I.Name = icon

        for _, child in ipairs(I.Root:GetChildren()) do
            if child ~= I.Image then child:Destroy() end
        end

        I.Image.Visible = false
        I.Parts, I.Strokes = buildFallback(I.Root, normalizeName(icon) or "", I.Color)

        task.spawn(function()
            local data = resolveIconData(icon)
            if token ~= I.Token or not I.Root.Parent then return end
            if data then
                applyIconData(I.Image, data)
                I.Image.ImageColor3 = I.Color
                I.Image.Visible = true
                for _, child in ipairs(I.Root:GetChildren()) do
                    if child ~= I.Image then child:Destroy() end
                end
                I.Parts, I.Strokes = {}, {}
            end
        end)
    end

    if props.Accent then
        table.insert(Library.AccentIcons, I)
    end

    I:SetIcon(name)

    return I
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

local function richBuild(accent, build)
    return string.format('build: <font color="rgb(%d,%d,%d)">%s</font>',
        math.floor(accent.R * 255), math.floor(accent.G * 255), math.floor(accent.B * 255), tostring(build or ""))
end

local function richUser(accent, name)
    return string.format('user: <font color="rgb(%d,%d,%d)">%s</font>',
        math.floor(accent.R * 255), math.floor(accent.G * 255), math.floor(accent.B * 255), name)
end

local function rowCard(parent, height)
    local Frame = New("Frame", {
        Parent = parent,
        Size = UDim2.new(1, 0, 0, height),
        BackgroundColor3 = C.Element,
        BorderSizePixel = 0
    })
    Corner(Frame, M.RadiusSm)
    Stroke(Frame, C.Border, 1, 0.1)
    return Frame
end

local function hoverCard(frame, hitbox)
    local stroke = frame:FindFirstChildOfClass("UIStroke")
    hitbox.MouseEnter:Connect(function()
        Tween(frame, { BackgroundColor3 = C.ElementHover }, 0.15)
        if stroke then Tween(stroke, { Color = C.BorderStrong }, 0.15) end
    end)
    hitbox.MouseLeave:Connect(function()
        Tween(frame, { BackgroundColor3 = C.Element }, 0.15)
        if stroke then Tween(stroke, { Color = C.Border }, 0.15) end
    end)
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

    for _, icon in pairs(Library.AccentIcons) do
        if icon and icon.Root and icon.Root.Parent then
            icon:SetColor(newColor)
        end
    end

    for _, grad in pairs(Library.BorderGradients) do
        if grad and grad.Parent then
            grad.Color = buildBorderSequence(newColor)
        end
    end

    if Library.Windows then
        for _, window in pairs(Library.Windows) do
            if window.CurrentTopTab and window.CurrentTopTab.Icon then
                window.CurrentTopTab.Icon:SetColor(newColor)
            end

            if window.CurrentCategory and window.CurrentCategory.Button then
                window.CurrentCategory.Button.TextColor3 = newColor
                if window.CurrentCategory.Icon then
                    window.CurrentCategory.Icon:SetColor(newColor)
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
                window.BuildLabel.Text = richBuild(newColor, window.Build)
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
        Name = guiName("Tooltip"),
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 1000
    })
    mount(TooltipGui)

    TooltipFrame = New("Frame", {
        Parent = TooltipGui,
        Size = UDim2.fromOffset(10, 24),
        BackgroundColor3 = C.Section,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 50
    })
    Corner(TooltipFrame, M.RadiusSm)
    Stroke(TooltipFrame, C.BorderStrong, 1, 0)

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
        Name = guiName("KeybindModeSelector"),
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false,
        IgnoreGuiInset = true
    })
    mount(ModeGui)

    local ModeFrame = New("Frame", {
        Parent = ModeGui,
        Size = UDim2.fromOffset(88, 64),
        BackgroundColor3 = C.Section,
        BackgroundTransparency = 1,
        BorderSizePixel = 0
    })
    Corner(ModeFrame, M.RadiusMd)
    local frameStroke = Stroke(ModeFrame, C.BorderStrong, 1, 1)

    local p = anchor.AbsolutePosition
    ModeFrame.Position = UDim2.fromOffset(p.X - 14, p.Y + anchor.AbsoluteSize.Y + 4)

    Tween(ModeFrame, { BackgroundTransparency = 0 }, 0.2, Enum.EasingStyle.Sine)
    Tween(frameStroke, { Transparency = 0 }, 0.2, Enum.EasingStyle.Sine)

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
        local selected = getMode() == m
        local b = New("TextButton", {
            Parent = ModeFrame,
            Position = UDim2.new(0, 4, 0, 4 + (i - 1) * 28),
            Size = UDim2.new(1, -8, 0, 24),
            BackgroundColor3 = selected and C.ElementActive or C.Element,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Text = m,
            TextColor3 = selected and C.Accent or C.Text,
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
            if getMode() ~= m then Tween(b, { BackgroundColor3 = C.Element }, 0.12) end
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
    local isMobile = Library.IsMobile

    -- identity / per-script isolation ---------------------------------
    local rawName = tostring(config.Name or config.Title or "UILib")
    local prefix = rawName:gsub("[^%w_]", "")
    if prefix == "" then prefix = "UILib" end

    Library.Name = rawName
    Library.Prefix = prefix
    ConfigSystem.FolderName = tostring(config.Folder or config.ConfigFolder or prefix)

    -- destroy a previous instance of the same script (re-execute safe)
    local instanceKey = "__UILib_" .. prefix
    local previous = genv[instanceKey]
    if previous and previous ~= Library and typeof(previous) == "table" and previous.Destroy then
        pcall(function() previous:Destroy() end)
    end
    genv[instanceKey] = Library

    local buildText = tostring(config.Build or config.Version or "1.0")
    local titleText = tostring(config.Title or rawName)
    local subtitleText = tostring(config.Subtitle or buildText)

    local SG = New("ScreenGui", {
        Name = guiName("UI"),
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false,
        IgnoreGuiInset = true
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
    local isCompact = false
    local searchExpanded = true

    local Main = New("CanvasGroup", {
        Name = "Main",
        Parent = SG,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.fromOffset(940, 600),
        BackgroundColor3 = C.BG,
        BorderSizePixel = 0,
        GroupTransparency = 1
    })
    Corner(Main, M.Radius)

    local MainStroke = Stroke(Main, Color3.new(1, 1, 1), 1, 0)
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
        Size = UDim2.new(0, M.SidebarWide, 1, 0),
        BackgroundColor3 = C.Sidebar,
        BorderSizePixel = 0
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
        Position = UDim2.new(0, 14, 0, 13),
        Size = UDim2.fromOffset(30, 30),
        BackgroundColor3 = C.Accent,
        BorderSizePixel = 0
    })
    Corner(LogoMark, M.RadiusMd)

    local LogoMarkDot = New("Frame", {
        Parent = LogoMark,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.fromOffset(10, 10),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0
    })
    Corner(LogoMarkDot, 3)

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

    local LogoTitle = New("TextLabel", {
        Name = "Title",
        Parent = Rail,
        Position = UDim2.new(0, 54, 0, 11),
        Size = UDim2.new(1, -62, 0, 18),
        BackgroundTransparency = 1,
        Text = titleText,
        TextColor3 = C.Text,
        TextSize = 15,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd
    })

    local LogoSub = New("TextLabel", {
        Name = "Subtitle",
        Parent = Rail,
        Position = UDim2.new(0, 54, 0, 28),
        Size = UDim2.new(1, -62, 0, 14),
        BackgroundTransparency = 1,
        Text = subtitleText,
        TextColor3 = C.Accent,
        TextSize = 11,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    table.insert(Library.AccentTextElements, LogoSub)

    New("Frame", {
        Name = "BrandLine",
        Parent = Rail,
        Position = UDim2.new(0, 12, 0, 56),
        Size = UDim2.new(1, -25, 0, 1),
        BackgroundColor3 = C.Border,
        BorderSizePixel = 0
    })

    local TopTabs = New("ScrollingFrame", {
        Name = "TopTabs",
        Parent = Rail,
        Position = UDim2.new(0, 0, 0, 64),
        Size = UDim2.new(1, -1, 1, -128),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y
    })

    New("UIListLayout", {
        Parent = TopTabs,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4)
    })
    Pad(TopTabs, 8, 2, 8, 2)

    local playerName = Players.LocalPlayer and Players.LocalPlayer.Name or "Unknown"

    local UserCard = New("Frame", {
        Name = "UserCard",
        Parent = Rail,
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, -1, 0, 58),
        BackgroundTransparency = 1
    })

    New("Frame", {
        Name = "UserLine",
        Parent = UserCard,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -24, 0, 1),
        BackgroundColor3 = C.Border,
        BorderSizePixel = 0
    })

    local Avatar = New("ImageLabel", {
        Name = "Avatar",
        Parent = UserCard,
        Position = UDim2.new(0, 14, 0, 14),
        Size = UDim2.fromOffset(32, 32),
        BackgroundColor3 = C.Chip,
        BorderSizePixel = 0,
        Image = "",
        ScaleType = Enum.ScaleType.Crop
    })
    Corner(Avatar, M.RadiusMd)
    Stroke(Avatar, C.BorderStrong, 1, 0)

    pcall(function()
        if Players.LocalPlayer then
            Avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(Players.LocalPlayer.UserId) ..
                "&w=150&h=150"
        end
    end)

    local UserName = New("TextLabel", {
        Name = "UserName",
        Parent = UserCard,
        Position = UDim2.new(0, 54, 0, 14),
        Size = UDim2.new(1, -62, 0, 16),
        BackgroundTransparency = 1,
        Text = playerName,
        TextColor3 = C.Text,
        TextSize = 12,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd
    })

    local UserRole = New("TextLabel", {
        Name = "UserRole",
        Parent = UserCard,
        Position = UDim2.new(0, 54, 0, 30),
        Size = UDim2.new(1, -62, 0, 14),
        BackgroundTransparency = 1,
        Text = "online",
        TextColor3 = C.Success,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    local Body = New("Frame", {
        Name = "Body",
        Parent = Main,
        Position = UDim2.new(0, M.SidebarWide, 0, 0),
        Size = UDim2.new(1, -M.SidebarWide, 1, 0),
        BackgroundTransparency = 1
    })

    local TopBar = New("Frame", {
        Name = "TopBar",
        Parent = Body,
        Size = UDim2.new(1, 0, 0, M.TopBar),
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
        BorderSizePixel = 0,
        ZIndex = 6
    })

    local TopAccentLine = New("Frame", {
        Name = "AccentLine",
        Parent = TopBar,
        Position = UDim2.new(0, 16, 1, -2),
        Size = UDim2.new(1, -32, 0, 2),
        BackgroundColor3 = C.Accent,
        BorderSizePixel = 0,
        ZIndex = 6
    })

    local TopAccentGradient = New("UIGradient", {
        Parent = TopAccentLine,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.5, 0.35),
            NumberSequenceKeypoint.new(1, 1)
        })
    })

    table.insert(Library.AccentElements, TopAccentLine)

    bind(RS.Heartbeat, function(dt)
        if Main.Visible then
            MainStrokeGradient.Rotation = (MainStrokeGradient.Rotation + dt * 36) % 360
            TopAccentGradient.Offset = Vector2.new(math.sin(os.clock() * 1.2) * 0.25, 0)
        end
    end)

    local TabTitle = New("TextLabel", {
        Name = "TabTitle",
        Parent = TopBar,
        Position = UDim2.new(0, 16, 0, 8),
        Size = UDim2.new(0, 190, 0, 18),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = C.Text,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 7
    })

    local CategoryTitle = New("TextLabel", {
        Name = "CategoryTitle",
        Parent = TopBar,
        Position = UDim2.new(0, 16, 0, 26),
        Size = UDim2.new(0, 190, 0, 14),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = C.TextDim,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 7
    })

    local CloseBtn = New("TextButton", {
        Name = "CloseButton",
        Parent = TopBar,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(isMobile and 32 or 28, isMobile and 32 or 28),
        BackgroundColor3 = Color3.fromRGB(72, 30, 40),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 7
    })
    Corner(CloseBtn, M.RadiusSm)
    local CloseStroke = Stroke(CloseBtn, C.Danger, 1, 1)
    local CloseIcon = CreateIcon(CloseBtn, "x", 14, C.TextDim, {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0)
    })

    CloseBtn.MouseEnter:Connect(function()
        Tween(CloseBtn, { BackgroundTransparency = 0 }, 0.15, Enum.EasingStyle.Sine)
        Tween(CloseStroke, { Transparency = 0.6 }, 0.15, Enum.EasingStyle.Sine)
        CloseIcon:SetColor(C.Danger, 0.15)
    end)

    CloseBtn.MouseLeave:Connect(function()
        Tween(CloseBtn, { BackgroundTransparency = 1 }, 0.15, Enum.EasingStyle.Sine)
        Tween(CloseStroke, { Transparency = 1 }, 0.15, Enum.EasingStyle.Sine)
        CloseIcon:SetColor(C.TextDim, 0.15)
    end)

    local SearchContainer = New("Frame", {
        Name = "SearchContainer",
        Parent = TopBar,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -48, 0.5, 0),
        Size = UDim2.new(0, 200, 0, 30),
        BackgroundColor3 = C.Element,
        BorderSizePixel = 0,
        ZIndex = 7
    })
    Corner(SearchContainer, M.RadiusSm)

    local SearchStroke = Stroke(SearchContainer, C.Border, 1, 0)

    local SearchIcon = CreateIcon(SearchContainer, "search", 14, C.TextDim, {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 10, 0.5, 0)
    })

    local SearchBox = New("TextBox", {
        Name = "SearchBox",
        Parent = SearchContainer,
        Position = UDim2.new(0, 32, 0, 0),
        Size = UDim2.new(1, -40, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        PlaceholderText = "Search features...",
        PlaceholderColor3 = C.TextMuted,
        TextColor3 = C.Text,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false
    })

    local SearchHit = New("TextButton", {
        Name = "SearchHit",
        Parent = SearchContainer,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        Visible = false
    })

    local SearchResults = New("Frame", {
        Name = "SearchResults",
        Parent = SearchContainer,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 1, 6),
        Size = UDim2.new(0, 250, 0, 0),
        BackgroundColor3 = C.Section,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 10
    })
    Corner(SearchResults, M.RadiusMd)
    Stroke(SearchResults, C.BorderStrong, 1, 0)

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
    Pad(ResultsList, 4, 4, 4, 4)

    SearchContainer.MouseEnter:Connect(function()
        Tween(SearchContainer, { BackgroundColor3 = C.ElementHover }, 0.15)
        Tween(SearchStroke, { Color = C.BorderStrong }, 0.15)
    end)

    SearchContainer.MouseLeave:Connect(function()
        if not SearchBox:IsFocused() then
            Tween(SearchContainer, { BackgroundColor3 = C.Element }, 0.15)
            Tween(SearchStroke, { Color = C.Border }, 0.15)
        end
    end)

    SearchBox.Focused:Connect(function()
        Tween(SearchContainer, { BackgroundColor3 = C.ElementHover }, 0.15)
        Tween(SearchStroke, { Color = C.Accent }, 0.15)
        SearchIcon:SetColor(C.Accent, 0.15)
    end)

    local CatStrip = New("Frame", {
        Name = "CategoryStrip",
        Parent = Body,
        Position = UDim2.new(0, 0, 0, M.TopBar),
        Size = UDim2.new(1, 0, 0, M.CategoryStrip),
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
        BorderSizePixel = 0
    })

    local CatList = New("ScrollingFrame", {
        Name = "List",
        Parent = CatStrip,
        Position = UDim2.new(0, 8, 0, 0),
        Size = UDim2.new(1, -16, 1, -1),
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
        Padding = UDim.new(0, 2)
    })

    local Content = New("Frame", {
        Name = "Content",
        Parent = Body,
        Position = UDim2.new(0, 0, 0, M.TopBar + M.CategoryStrip),
        Size = UDim2.new(1, 0, 1, -(M.TopBar + M.CategoryStrip + M.Footer)),
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
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y
    })
    Pad(ContentScroll, M.Pad, M.Pad, 0, M.Pad)

    local Grid = New("Frame", {
        Name = "Grid",
        Parent = ContentScroll,
        Size = UDim2.new(1, -M.Pad, 0, 0),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y
    })

    local GridLayout = New("UIListLayout", {
        Parent = Grid,
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        Padding = UDim.new(0, M.Pad)
    })

    local LeftColumn = New("Frame", {
        Name = "LeftColumn",
        Parent = Grid,
        Size = UDim2.new(0.5, -M.Pad / 2, 0, 0),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 1
    })

    New("UIListLayout", {
        Parent = LeftColumn,
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, M.Pad)
    })

    local RightColumn = New("Frame", {
        Name = "RightColumn",
        Parent = Grid,
        Size = UDim2.new(0.5, -M.Pad / 2, 0, 0),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 2
    })

    New("UIListLayout", {
        Parent = RightColumn,
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, M.Pad)
    })

    local Footer = New("Frame", {
        Name = "Footer",
        Parent = Body,
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, M.Footer),
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

    local buildW = math.max(90, (7 + #buildText) * 7 + 8)

    local BuildLabel = New("TextLabel", {
        Name = "Build",
        Parent = Footer,
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(0, buildW, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = C.TextDim,
        TextTruncate = Enum.TextTruncate.AtEnd,
        RichText = true,
        Text = richBuild(C.Accent, buildText)
    })

    local UserLabel = New("TextLabel", {
        Name = "User",
        Parent = Footer,
        Position = UDim2.new(0, 14 + buildW + 4, 0, 0),
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
        TextColor3 = C.TextMuted,
        Visible = not isMobile,
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
        Grid = Grid,
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
        CategoryTitle = CategoryTitle,
        TitleLetters = {},
        PlayerName = playerName,
        Build = buildText,
        Name = rawName,
        BaseScale = 1,
        Icon = nil,
        IconTint = nil,
        IsMobile = isMobile,
        Compact = false
    }

    local function layoutSearch()
        local railW = isCompact and M.SidebarCompact or M.SidebarWide
        local bodyW = Main.Size.X.Offset - railW

        if not isCompact then
            SearchContainer.Size = UDim2.fromOffset(math.clamp(bodyW - 300, 150, 230), 30)
            SearchBox.Visible = true
            SearchHit.Visible = false
            TabTitle.Visible = true
            CategoryTitle.Visible = true
            SearchIcon.Root.AnchorPoint = Vector2.new(0, 0.5)
            SearchIcon.Root.Position = UDim2.new(0, 10, 0.5, 0)
        elseif searchExpanded then
            SearchContainer.Size = UDim2.fromOffset(math.max(120, bodyW - 64), 30)
            SearchBox.Visible = true
            SearchHit.Visible = false
            TabTitle.Visible = false
            CategoryTitle.Visible = false
            SearchIcon.Root.AnchorPoint = Vector2.new(0, 0.5)
            SearchIcon.Root.Position = UDim2.new(0, 10, 0.5, 0)
        else
            SearchContainer.Size = UDim2.fromOffset(32, 32)
            SearchBox.Visible = false
            SearchHit.Visible = true
            TabTitle.Visible = true
            CategoryTitle.Visible = true
            SearchIcon.Root.AnchorPoint = Vector2.new(0.5, 0.5)
            SearchIcon.Root.Position = UDim2.new(0.5, 0, 0.5, 0)
        end

        TabTitle.Size = UDim2.new(0, math.clamp(bodyW - 120, 60, 260), 0, 18)
        CategoryTitle.Size = TabTitle.Size
    end

    local function applyLayout()
        local vp = SG.AbsoluteSize
        if vp.X < 100 or vp.Y < 100 then return end

        local scale = W.BaseScale
        local availX = vp.X / scale
        local availY = vp.Y / scale

        isCompact = isMobile or availX < 700
        W.Compact = isCompact
        Library.Compact = isCompact

        local width, height
        if isCompact then
            width = math.clamp(availX - 24, 300, 640)
            height = math.clamp(availY - 24, 230, 430)
        else
            width = math.clamp(availX - 40, 560, 940)
            height = math.clamp(availY - 40, 380, 620)
        end

        Main.Size = UDim2.fromOffset(width, height)

        local railW = isCompact and M.SidebarCompact or M.SidebarWide
        Rail.Size = UDim2.new(0, railW, 1, 0)
        Body.Position = UDim2.new(0, railW, 0, 0)
        Body.Size = UDim2.new(1, -railW, 1, 0)

        LogoTitle.Visible = not isCompact
        LogoSub.Visible = not isCompact
        UserName.Visible = not isCompact
        UserRole.Visible = not isCompact
        LogoMark.Position = isCompact and UDim2.new(0.5, -15, 0, 13) or UDim2.new(0, 14, 0, 13)
        Avatar.Position = isCompact and UDim2.new(0.5, -16, 0, 14) or UDim2.new(0, 14, 0, 14)
        UserLabel.Visible = not isCompact

        for _, tab in ipairs(W.TopTabButtons) do
            tab:ApplyLayout(isCompact)
        end

        if isCompact then
            GridLayout.FillDirection = Enum.FillDirection.Vertical
            LeftColumn.Size = UDim2.new(1, 0, 0, 0)
            RightColumn.Size = UDim2.new(1, 0, 0, 0)
        else
            GridLayout.FillDirection = Enum.FillDirection.Horizontal
            LeftColumn.Size = UDim2.new(0.5, -M.Pad / 2, 0, 0)
            RightColumn.Size = UDim2.new(0.5, -M.Pad / 2, 0, 0)
        end

        layoutSearch()
    end

    function W:ApplyLayout()
        applyLayout()
    end

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
            applyLayout()
            Main.Visible = true
            MainUIScale.Scale = W.BaseScale * 0.94
            Tween(MainUIScale, { Scale = W.BaseScale }, 0.5, Enum.EasingStyle.Back)
            Tween(Main, { GroupTransparency = 0 }, 0.3, Enum.EasingStyle.Quad)

            Backdrop.Visible = true
            Backdrop.BackgroundTransparency = 1
            Tween(Backdrop, { BackgroundTransparency = 0.55 }, 0.3, Enum.EasingStyle.Sine)
        else
            Tween(MainUIScale, { Scale = W.BaseScale * 0.96 }, 0.25, Enum.EasingStyle.Quad)
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
        applyLayout()
    end

    function W:SetTitle(title, subtitle)
        if title then LogoTitle.Text = tostring(title) end
        if subtitle then LogoSub.Text = tostring(subtitle) end
    end

    function W:SetBuild(build)
        W.Build = tostring(build)
        BuildLabel.Text = richBuild(C.Accent, W.Build)
    end

    function W:Notify(cfg)
        Library:CreateNotification(cfg)
    end

    function W:SaveConfig(n) return saveConfig(n) end

    function W:LoadConfig(n) return loadConfig(n) end

    function W:Destroy()
        Library:Destroy()
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
            local data = icon and resolveIconData(icon)

            if not data then
                LogoImage.Visible = false
                LogoImage.Image = ""
                LogoMark.BackgroundTransparency = 0
                LogoMarkDot.Visible = true

                if W.MobileIconImage then
                    W.MobileIconImage.Visible = false
                    W.MobileIconImage.Image = ""
                end
                if W.MobileGlyph then
                    W.MobileGlyph.Root.Visible = true
                end
                return
            end

            applyIconData(LogoImage, data)
            LogoImage.Visible = true
            LogoMark.BackgroundTransparency = 1
            LogoMarkDot.Visible = false
            applyImageTint(LogoImage, W.IconTint)

            if W.MobileIconImage then
                applyIconData(W.MobileIconImage, data)
                W.MobileIconImage.Visible = true
                applyImageTint(W.MobileIconImage, typeof(W.IconTint) == "Color3" and W.IconTint or nil)
            end
            if W.MobileGlyph then
                W.MobileGlyph.Root.Visible = false
            end
        end)
    end

    bind(UIS.InputBegan, function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == W.ToggleKey then
            W:Toggle()
        end
    end)

    W.MobileButton = nil
    if isMobile then
        local MobileButton = New("Frame", {
            Name = "MobileToggleButton",
            Parent = SG,
            Size = UDim2.fromOffset(46, 46),
            Position = UDim2.fromOffset(15, 100),
            BackgroundColor3 = C.Accent,
            BackgroundTransparency = 0.05,
            BorderSizePixel = 0,
            ZIndex = 100,
            Active = true
        })
        Corner(MobileButton, 12)
        Stroke(MobileButton, Color3.new(1, 1, 1), 1.5, 0.6)

        local MobileGlyph = CreateIcon(MobileButton, "menu", 22, Color3.new(1, 1, 1), {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        })

        local MobileIconImage = New("ImageLabel", {
            Name = "MobileIconImage",
            Parent = MobileButton,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0.6, 0, 0.6, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScaleType = Enum.ScaleType.Fit,
            Image = "",
            Visible = false
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
        W.MobileGlyph = MobileGlyph

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
                MobileGlyph:SetIcon(visible and "x" or "menu")
            end
            Tween(MobileButton, { BackgroundTransparency = visible and 0.4 or 0.05 }, 0.15, Enum.EasingStyle.Sine)
        end

        W.MobileButton = MobileButton
    end

    -- auto load the "default" config once the script had time to build its elements
    if config.AutoLoad ~= false then
        task.spawn(function()
            task.wait(tonumber(config.AutoLoadDelay) or 1.0)
            if isfile and isfile(ConfigSystem.FolderName .. "/default.json") then
                ConfigSystem.Load("default")
            end
        end)
    end

    bind(SG:GetPropertyChangedSignal("AbsoluteSize"), function()
        applyLayout()
    end)

    applyLayout()
    W:SetVisible(true)

    if config.Icon ~= nil then
        W:SetIcon(config.Icon, config.IconTint)
    end

    if config.Sounds ~= false then
        Library:LoadNotificationSounds()
    end

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
        Corner(Highlight, M.RadiusSm)

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

        local bodyW = Main.Size.X.Offset - (isCompact and M.SidebarCompact or M.SidebarWide)
        local resultsW = math.clamp(math.max(SearchContainer.Size.X.Offset, 240), 200, bodyW - 24)
        local rowH = isMobile and 44 or 38
        local count = math.min(#matches, 6)
        SearchResults.Size = UDim2.new(0, resultsW, 0, count * (rowH + 2) + 8)

        for i = 1, count do
            local match = matches[i]
            local ResultBtn = New("TextButton", {
                Parent = ResultsList,
                Size = UDim2.new(1, 0, 0, rowH),
                BackgroundColor3 = C.Element,
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false,
                ZIndex = 11
            })
            Corner(ResultBtn, 6)

            New("TextLabel", {
                Parent = ResultBtn,
                Position = UDim2.new(0, 10, 0, 4),
                Size = UDim2.new(1, -20, 0, 17),
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
                Position = UDim2.new(0, 10, 0, 21),
                Size = UDim2.new(1, -20, 0, 14),
                BackgroundTransparency = 1,
                Text = match.tabName .. "  /  " .. match.categoryName,
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
                Tween(ResultBtn, { BackgroundColor3 = C.Element }, 0.12)
            end)
        end

        SearchResults.Visible = true
    end

    SearchBox:GetPropertyChangedSignal("Text"):Connect(updateSearchResults)
    SearchBox.Focused:Connect(updateSearchResults)

    SearchBox.FocusLost:Connect(function()
        task.wait(0.25)
        SearchResults.Visible = false
        Tween(SearchContainer, { BackgroundColor3 = C.Element }, 0.15)
        Tween(SearchStroke, { Color = C.Border }, 0.15)
        SearchIcon:SetColor(C.TextDim, 0.15)
        if isCompact and SearchBox.Text == "" then
            searchExpanded = false
            layoutSearch()
        end
    end)

    SearchHit.MouseButton1Click:Connect(function()
        searchExpanded = true
        layoutSearch()
        SearchBox:CaptureFocus()
    end)

    local function CreateWatermark()
        local Watermark = New("ScreenGui", {
            Name = guiName("Watermark"),
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            ResetOnSpawn = false,
            IgnoreGuiInset = true
        })
        mount(Watermark)

        local WatermarkFrame = New("CanvasGroup", {
            Name = "WatermarkFrame",
            Parent = Watermark,
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, 12),
            Size = UDim2.new(0, 0, 0, 32),
            BackgroundColor3 = C.TopBar,
            BorderSizePixel = 0,
            AutomaticSize = Enum.AutomaticSize.X,
            GroupTransparency = 1
        })
        Corner(WatermarkFrame, M.RadiusMd)
        Stroke(WatermarkFrame, C.BorderStrong, 1, 0)

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

        Pad(ContentFrame, 14, 0, 14, 0)

        local wmText = tostring(config.WatermarkText or titleText:lower())
        local logoContainer = New("Frame", {
            Name = "Logo",
            Parent = ContentFrame,
            Size = UDim2.new(0, #wmText * 9, 1, 0),
            BackgroundTransparency = 1,
            LayoutOrder = 1
        })

        local logoLetters = makeLetters(logoContainer, wmText, 9, 15)

        local function sep(order)
            return New("Frame", {
                Parent = ContentFrame,
                Size = UDim2.new(0, 1, 0, 14),
                BackgroundColor3 = C.Accent,
                BackgroundTransparency = 0.5,
                BorderSizePixel = 0,
                LayoutOrder = order
            })
        end

        local function gap(order)
            return New("Frame", {
                Parent = ContentFrame,
                Size = UDim2.new(0, 10, 1, 0),
                BackgroundTransparency = 1,
                LayoutOrder = order
            })
        end

        gap(2)
        local Sep1 = sep(3)
        gap(4)

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
            LayoutOrder = 5
        })

        gap(6)
        local Sep2 = sep(7)
        gap(8)

        local BuildWmLabel = New("TextLabel", {
            Name = "Build",
            Parent = ContentFrame,
            Size = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            Text = W.Build,
            TextColor3 = C.Accent,
            TextSize = 12,
            Font = Enum.Font.GothamBold,
            LayoutOrder = 9
        })

        gap(10)
        local Sep3 = sep(11)
        gap(12)

        local PingLabel = New("TextLabel", {
            Name = "Ping",
            Parent = ContentFrame,
            Size = UDim2.new(0, 45, 1, 0),
            BackgroundTransparency = 1,
            Text = "0ms",
            TextColor3 = C.Accent,
            TextSize = 12,
            Font = Enum.Font.GothamMedium,
            LayoutOrder = 13
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
                NumberSequenceKeypoint.new(0.5, 0.3),
                NumberSequenceKeypoint.new(1, 1)
            })
        })

        table.insert(Library.AccentElements, WatermarkLine)
        table.insert(Library.AccentElements, Sep1)
        table.insert(Library.AccentElements, Sep2)
        table.insert(Library.AccentElements, Sep3)

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
            TextElements = { UsernameLabel, BuildWmLabel, PingLabel },
            SetVisible = function(visible)
                Watermark.Enabled = visible
            end
        }
    end

    W.Watermark = nil
    if config.Watermark ~= false then
        task.spawn(function()
            task.wait(0.2)
            if Library.IsMobile then return end
            W.Watermark = CreateWatermark()
        end)
    end

    function W:CreateTopTab(name, icon)
        local T = { Name = name, Window = W, Categories = {}, LastSelectedCategory = nil }

        local Btn = New("TextButton", {
            Name = name,
            Parent = TopTabs,
            Size = UDim2.new(1, 0, 0, 36),
            BackgroundColor3 = C.Element,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = #W.TopTabButtons + 1
        })
        Corner(Btn, M.RadiusMd)
        local BtnStroke = Stroke(Btn, C.Border, 1, 1)

        local Label = New("TextLabel", {
            Name = "Label",
            Parent = Btn,
            Position = UDim2.new(0, 38, 0, 0),
            Size = UDim2.new(1, -46, 1, 0),
            BackgroundTransparency = 1,
            Text = name,
            TextColor3 = C.TextDim,
            TextSize = 13,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd
        })

        local hasIcon = icon ~= nil and icon ~= ""
        T.Icon = CreateIcon(Btn, hasIcon and icon or "layout-grid", 18, C.TextDim, {
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 12, 0.5, 0)
        })

        local Line = New("Frame", {
            Name = "Line",
            Parent = Btn,
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, -8, 0.5, 0),
            Size = UDim2.new(0, 3, 0, 0),
            BackgroundColor3 = C.Accent,
            BorderSizePixel = 0,
            Visible = false
        })
        Corner(Line, 2)
        table.insert(Library.AccentElements, Line)

        T.Button = Btn
        T.Label = Label
        T.Line = Line
        T.Stroke = BtnStroke
        table.insert(W.TopTabButtons, T)

        function T:ApplyLayout(compact)
            Btn.Size = UDim2.new(1, 0, 0, compact and 40 or 36)
            Label.Visible = not compact
            if compact then
                T.Icon.Root.Size = UDim2.fromOffset(20, 20)
                T.Icon.Root.AnchorPoint = Vector2.new(0.5, 0.5)
                T.Icon.Root.Position = UDim2.new(0.5, 0, 0.5, 0)
            else
                T.Icon.Root.Size = UDim2.fromOffset(18, 18)
                T.Icon.Root.AnchorPoint = Vector2.new(0, 0.5)
                T.Icon.Root.Position = UDim2.new(0, 12, 0.5, 0)
            end
        end

        -- friendly method-style API
        function T:CreateCategory(catName, catIcon)
            return W:CreateCategory(T, catName, catIcon)
        end

        function T:Select()
            W:SelectTopTab(T)
        end

        T:ApplyLayout(isCompact)

        Btn.MouseButton1Click:Connect(function()
            W:SelectTopTab(T)
        end)

        Btn.MouseEnter:Connect(function()
            if W.CurrentTopTab ~= T then
                Tween(Btn, { BackgroundTransparency = 0.55 }, 0.15)
                Tween(Label, { TextColor3 = C.Text }, 0.15)
                T.Icon:SetColor(C.Text, 0.15)
            end
        end)

        Btn.MouseLeave:Connect(function()
            if W.CurrentTopTab ~= T then
                Tween(Btn, { BackgroundTransparency = 1 }, 0.15)
                Tween(Label, { TextColor3 = C.TextDim }, 0.15)
                T.Icon:SetColor(C.TextDim, 0.15)
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

    -- alias
    function W:CreateTab(name, icon)
        return W:CreateTopTab(name, icon)
    end

    function W:SelectTopTab(tab)
        if W.CurrentTopTab == tab then return end

        closePickers()

        for _, t in ipairs(W.TopTabButtons) do
            local active = (t == tab)
            Tween(t.Button, { BackgroundTransparency = active and 0 or 1 }, 0.2)
            Tween(t.Stroke, { Transparency = active and 0.2 or 1 }, 0.2)
            Tween(t.Label, { TextColor3 = active and C.Text or C.TextDim }, 0.2)
            t.Icon:SetColor(active and C.Accent or C.TextDim, 0.2)

            if active then
                t.Line.Visible = true
                t.Line.Size = UDim2.new(0, 3, 0, 0)
                Tween(t.Line, { Size = UDim2.new(0, 3, 0, 18) }, 0.4, Enum.EasingStyle.Back)
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
                end)
            end
        end

        if #tab.Categories > 0 then
            if tab.LastSelectedCategory and table.find(tab.Categories, tab.LastSelectedCategory) then
                tab.LastSelectedCategory:Select(true)
            else
                tab.Categories[1]:Select(true)
            end
        else
            CategoryTitle.Text = ""
        end
    end

    function W:CreateCategory(topTab, name, icon)
        local Cat = { Name = name, TopTab = topTab, Sections = {}, Button = nil, IconId = icon }

        function Cat:SetActiveVisual(active, t)
            if not (Cat.Button and Cat.Button.Parent) then return end
            t = t or 0.2

            Tween(Cat.Button, { TextColor3 = active and C.Accent or C.TextDim }, t, Enum.EasingStyle.Sine)
            if Cat.Icon then
                Cat.Icon:SetColor(active and C.Accent or C.TextDim, t)
            end

            if active then
                Cat.Underline.Visible = true
                Cat.Underline.Size = UDim2.new(0, 0, 0, 2)
                Tween(Cat.Underline, { Size = UDim2.new(1, Cat.PadTotal, 0, 2) }, 0.3, Enum.EasingStyle.Back)
            else
                Cat.Underline.Visible = false
            end
        end

        function Cat:Show(instant)
            local hasIcon = Cat.IconId ~= nil and Cat.IconId ~= ""
            local padLeft = hasIcon and 34 or 12
            local padRight = 12
            Cat.PadTotal = padLeft + padRight

            local Btn = New("TextButton", {
                Name = name,
                Parent = CatList,
                AutomaticSize = Enum.AutomaticSize.X,
                Size = UDim2.new(0, 0, 0, M.CategoryStrip - 1),
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

            Pad(Btn, padLeft, 0, padRight, 0)

            local Underline = New("Frame", {
                Name = "Underline",
                Parent = Btn,
                AnchorPoint = Vector2.new(0.5, 1),
                Position = UDim2.new(0.5, (padRight - padLeft) / 2, 1, 0),
                Size = UDim2.new(1, Cat.PadTotal, 0, 2),
                BackgroundColor3 = C.Accent,
                BorderSizePixel = 0,
                Visible = false
            })
            Corner(Underline, 1)
            table.insert(Library.AccentElements, Underline)

            Cat.Button = Btn
            Cat.Underline = Underline
            Cat.Icon = nil

            if hasIcon then
                Cat.Icon = CreateIcon(Btn, Cat.IconId, 16, C.TextDim, {
                    AnchorPoint = Vector2.new(0, 0.5),
                    Position = UDim2.new(0, -(padLeft - 12), 0.5, 0)
                })
            end

            if W.CurrentCategory == Cat then
                Cat:SetActiveVisual(true, 0)
                Underline.Size = UDim2.new(1, Cat.PadTotal, 0, 2)
            end

            Btn.MouseButton1Click:Connect(function()
                Cat:Select()
            end)

            Btn.MouseEnter:Connect(function()
                if W.CurrentCategory ~= Cat then
                    Tween(Btn, { TextColor3 = C.Text }, 0.2, Enum.EasingStyle.Sine)
                    if Cat.Icon then Cat.Icon:SetColor(C.Text, 0.2) end
                end
            end)

            Btn.MouseLeave:Connect(function()
                if W.CurrentCategory ~= Cat then
                    Tween(Btn, { TextColor3 = C.TextDim }, 0.2, Enum.EasingStyle.Sine)
                    if Cat.Icon then Cat.Icon:SetColor(C.TextDim, 0.2) end
                end
            end)
        end

        function Cat:Select(force)
            if W.CurrentCategory == Cat and not force then return end

            for _, c in ipairs(topTab.Categories) do
                if c ~= Cat then c:SetActiveVisual(false, 0.15) end
            end

            W.CurrentCategory = Cat
            Cat:SetActiveVisual(true, 0.2)
            CategoryTitle.Text = Cat.Name

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

            local leftCount, rightCount = 0, 0
            local stagger = 0
            for _, sec in pairs(Cat.Sections) do
                if sec.Column == "left" then leftCount = leftCount + 1 else rightCount = rightCount + 1 end
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

            LeftColumn.Visible = leftCount > 0 or rightCount == 0
            RightColumn.Visible = rightCount > 0
        end

        -- friendly method-style API
        function Cat:CreateSection(secName, column, secIcon)
            return Library:CreateSection(Cat, secName, column, secIcon)
        end

        function Cat:CreateConfigSection(column)
            return Library:CreateConfigSection(Cat, column)
        end

        table.insert(topTab.Categories, Cat)
        table.insert(W.Categories, Cat)

        if W.CurrentTopTab == topTab then
            Cat:Show(false)
            if Cat.Button then
                Tween(Cat.Button, { TextTransparency = 0 }, 0.2, Enum.EasingStyle.Sine)
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

-- Sections get Add<Component> / Create<Component> methods automatically,
-- including components registered later with Library:RegisterComponent.
local SectionMethods = {
    __index = function(_, key)
        if type(key) ~= "string" then return nil end
        local comp = key:match("^Add(.+)$") or key:match("^Create(.+)$")
        local builder = comp and Library.Components[comp]
        if builder then
            return function(self, cfg)
                return builder(self, cfg)
            end
        end
        return nil
    end
}

function Library:CreateSection(category, name, column, icon)
    column = column or "left"

    local S = setmetatable({ Name = name, Category = category, Column = column, Elements = {} }, SectionMethods)

    local window = category.TopTab and category.TopTab.Window
    local parentColumn
    if window then
        parentColumn = column == "left" and window.LeftColumn or window.RightColumn
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

    Corner(Frame, M.RadiusMd + 2)
    Stroke(Frame, C.Border, 1, 0)
    Sheen(Frame, M.RadiusMd + 2, 0.04)

    local hasIcon = icon ~= nil and icon ~= ""
    local headerX = 12

    if hasIcon then
        CreateIcon(Frame, icon, 14, C.Accent, {
            Accent = true,
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 12, 0, M.SectionHeader / 2)
        })
        headerX = 32
    else
        local HeaderMark = New("Frame", {
            Name = "HeaderMark",
            Parent = Frame,
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 12, 0, M.SectionHeader / 2),
            Size = UDim2.fromOffset(3, 12),
            BackgroundColor3 = C.Accent,
            BorderSizePixel = 0
        })
        Corner(HeaderMark, 2)
        table.insert(Library.AccentElements, HeaderMark)
        headerX = 24
    end

    New("TextLabel", {
        Name = "Header",
        Parent = Frame,
        Position = UDim2.new(0, headerX, 0, 0),
        Size = UDim2.new(1, -(headerX + 12), 0, M.SectionHeader),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = C.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Font = Enum.Font.GothamBold
    })

    New("Frame", {
        Name = "HeaderLine",
        Parent = Frame,
        Position = UDim2.new(0, 0, 0, M.SectionHeader),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = C.Border,
        BorderSizePixel = 0
    })

    local Container = New("Frame", {
        Name = "Container",
        Parent = Frame,
        Position = UDim2.new(0, 0, 0, M.SectionHeader + 1),
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y
    })

    New("UIListLayout", {
        Parent = Container,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, M.Gap)
    })

    Pad(Container, 8, 8, 8, 10)

    S.Frame = Frame
    S.Container = Container

    table.insert(category.Sections, S)

    if window and window.CurrentCategory == category then
        Frame.Visible = true
        if parentColumn then parentColumn.Visible = true end
    end

    return S
end

function Library:RegisterComponent(name, builder)
    Library.Components[name] = builder
    Library["Create" .. name] = function(_, section, config)
        return builder(section, config)
    end
end

function Library:Create(name, section, config)
    local builder = Library.Components[name]
    if not builder then
        error(Library.Name .. ": unknown component '" .. tostring(name) .. "'")
    end
    return builder(section, config)
end

function Library:RegisterConfigElement(path, element)
    ConfigSystem.Elements[path] = element
end

Library.Util = {
    New = New,
    Tween = Tween,
    Corner = Corner,
    Stroke = Stroke,
    Pad = Pad,
    Sheen = Sheen,
    Icon = CreateIcon,
    RowCard = rowCard,
    HoverCard = hoverCard,
    Bind = bind,
    Register = register,
    PathFor = pathFor,
    KeyName = keyName,
    AutoSave = autoSave
}

local function buildToggle(section, config)
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

    local Frame = rowCard(section.Container, M.Row)

    local Box = New("Frame", {
        Parent = Frame,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.fromOffset(18, 18),
        BackgroundColor3 = default and C.Accent or C.SliderBg,
        BorderSizePixel = 0
    })
    Corner(Box, 5)

    local BoxStroke = Stroke(Box, default and C.Accent or C.BorderStrong, 1, 0)

    local Check = CreateIcon(Box, "check", 12, Color3.new(1, 1, 1), {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0)
    })
    Check.Root.Visible = default

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

    local Label = New("TextLabel", {
        Parent = Frame,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, keybind and -118 or -48, 1, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = default and C.Text or C.TextDim,
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
        Tween(BoxStroke, { Color = v and C.Accent or C.BorderStrong }, 0.2, Enum.EasingStyle.Sine)
        Tween(Label, { TextColor3 = v and C.Text or C.TextDim }, 0.2, Enum.EasingStyle.Sine)

        if v then
            Check.Root.Visible = true
            Check.Root.Size = UDim2.fromOffset(4, 4)
            Tween(Check.Root, { Size = UDim2.fromOffset(12, 12) }, 0.25, Enum.EasingStyle.Back)
        else
            Tween(Check.Root, { Size = UDim2.fromOffset(2, 2) }, 0.12, Enum.EasingStyle.Sine)
            task.delay(0.13, function()
                if not T.Value then
                    Check.Root.Visible = false
                end
            end)
        end

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
            Position = UDim2.new(1, -36, 0.5, 0),
            Size = UDim2.new(0, 64, 0, 20),
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
        Corner(KeyBtn, 5)
        Stroke(KeyBtn, C.Border, 1, 0.2)

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

local function buildSlider(section, config)
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

    local Frame = rowCard(section.Container, M.Slider)

    local Label = New("TextLabel", {
        Parent = Frame,
        Position = UDim2.new(0, 12, 0, 7),
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
        Position = UDim2.new(1, -10, 0, 5),
        Size = UDim2.new(0, 64, 0, 18),
        BackgroundColor3 = C.Chip,
        BorderSizePixel = 0,
        Text = fmt(default) .. suffix,
        TextColor3 = C.TextDim,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Center,
        Font = Enum.Font.GothamMedium
    })
    Corner(Value, 5)

    local Track = New("Frame", {
        Parent = Frame,
        Position = UDim2.new(0, 12, 1, -(mobile and 20 or 14)),
        Size = UDim2.new(1, -24, 0, mobile and 8 or 4),
        BackgroundColor3 = C.SliderBg,
        BorderSizePixel = 0
    })
    Corner(Track, 2)

    local Fill = New("Frame", {
        Parent = Track,
        Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
        BackgroundColor3 = C.Accent,
        BorderSizePixel = 0
    })
    Corner(Fill, 2)
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
    Corner(Knob, 4)

    local KnobStroke = Stroke(Knob, C.Accent, 2, 1)
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

    local frameStroke = Frame:FindFirstChildOfClass("UIStroke")

    Btn.MouseEnter:Connect(function()
        Tween(Track, { BackgroundColor3 = Color3.fromRGB(52, 55, 74) }, 0.15)
        Tween(Frame, { BackgroundColor3 = C.ElementHover }, 0.15)
        if frameStroke then Tween(frameStroke, { Color = C.BorderStrong }, 0.15) end
    end)

    Btn.MouseLeave:Connect(function()
        Tween(Track, { BackgroundColor3 = C.SliderBg }, 0.15)
        Tween(Frame, { BackgroundColor3 = C.Element }, 0.15)
        if frameStroke then Tween(frameStroke, { Color = C.Border }, 0.15) end
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

    local function refreshAncestors()
        ancestorScrolls = {}
        local p = Frame.Parent
        while p and p ~= game do
            if p:IsA("ScrollingFrame") then table.insert(ancestorScrolls, p) end
            p = p.Parent
        end
    end

    local function setScrollingEnabled(enabled)
        if #ancestorScrolls == 0 then refreshAncestors() end
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
            Tween(KnobStroke, { Transparency = 0.35 }, 0.15, Enum.EasingStyle.Sine)
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

local function buildDropdown(section, config)
    config = config or {}
    local name = config.Name or "Dropdown"
    local options = config.Options or {}
    local default = config.Default or (options[1] or "")
    local callback = config.Callback or function() end

    local configPath = pathFor(section, name)

    local D = { Value = default, Options = options, Callback = callback, Open = false, ConfigPath = configPath }

    local rowH = M.Row

    local Container = rowCard(section.Container, rowH)
    Container.ClipsDescendants = true

    local Row = New("Frame", {
        Parent = Container,
        Size = UDim2.new(1, 0, 0, rowH),
        BackgroundTransparency = 1
    })

    local Label = New("TextLabel", {
        Parent = Row,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(0.42, -12, 1, 0),
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
        Size = UDim2.new(0.58, -10, 0, rowH - 10),
        BackgroundColor3 = C.Chip,
        BorderSizePixel = 0,
        Text = tostring(default),
        TextColor3 = C.TextDim,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamMedium,
        TextTruncate = Enum.TextTruncate.AtEnd
    })
    Corner(Value, 5)
    Stroke(Value, C.Border, 1, 0.2)
    Pad(Value, 9, 0, 24, 0)

    local Arrow = CreateIcon(Row, "chevron-down", 12, C.TextDim, {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(1, -18, 0.5, 0)
    })

    local List = New("ScrollingFrame", {
        Parent = Container,
        Position = UDim2.new(0, 6, 0, rowH + 4),
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
    Corner(List, 6)
    New("UIListLayout", { Parent = List, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2) })
    Pad(List, 4, 4, 4, 4)

    local Btn = New("TextButton", {
        Parent = Row,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = ""
    })

    hoverCard(Container, Btn)

    Btn.MouseEnter:Connect(function()
        Tween(Value, { BackgroundColor3 = C.ElementActive }, 0.15)
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
                local selected = c.Text == tostring(D.Value)
                Tween(c, {
                    TextColor3 = selected and C.Accent or C.Text,
                    BackgroundColor3 = selected and C.ElementActive or C.Element
                }, 0.15, Enum.EasingStyle.Sine)
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
            local h = math.clamp(#D.Options * (M.Option + 2) + 8, 40, 172)

            Tween(Container, { Size = UDim2.new(1, 0, 0, rowH + 4 + h + 6) }, 0.3, Enum.EasingStyle.Quint)
            Tween(List, { Size = UDim2.new(1, -12, 0, h) }, 0.3, Enum.EasingStyle.Quint)
            Tween(Arrow.Root, { Rotation = 180 }, 0.25, Enum.EasingStyle.Quint)
            Arrow:SetColor(C.Accent, 0.25)
        else
            Tween(Container, { Size = UDim2.new(1, 0, 0, rowH) }, 0.25, Enum.EasingStyle.Quint)
            Tween(List, { Size = UDim2.new(1, -12, 0, 0) }, 0.25, Enum.EasingStyle.Quint)
            Tween(Arrow.Root, { Rotation = 0 }, 0.25, Enum.EasingStyle.Quint)
            Arrow:SetColor(C.TextDim, 0.25)

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
            local selected = opt == D.Value
            local O = New("TextButton", {
                Parent = List,
                Size = UDim2.new(1, 0, 0, M.Option),
                BackgroundColor3 = selected and C.ElementActive or C.Element,
                BorderSizePixel = 0,
                Text = tostring(opt),
                TextColor3 = selected and C.Accent or C.Text,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                Font = Enum.Font.GothamMedium,
                AutoButtonColor = false
            })
            Corner(O, 5)
            Pad(O, 8, 0, 8, 0)
            O.MouseButton1Click:Connect(function()
                D:SetValue(opt)
                D:Toggle(false)
            end)
            O.MouseEnter:Connect(function()
                if tostring(opt) ~= tostring(D.Value) then
                    Tween(O, { BackgroundColor3 = C.ElementHover }, 0.12, Enum.EasingStyle.Sine)
                end
            end)
            O.MouseLeave:Connect(function()
                if tostring(opt) ~= tostring(D.Value) then
                    Tween(O, { BackgroundColor3 = C.Element }, 0.12, Enum.EasingStyle.Sine)
                end
            end)
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

local function buildLabel(section, text)
    if type(text) == "table" then
        text = text.Text or text.Name
    end
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
    Pad(L, 4, 0, 4, 0)
    return L
end

local function buildButton(section, config)
    config = config or {}
    local name = config.Name or "Button"
    local callback = config.Callback or function() end

    local B = { Callback = callback }

    local Frame = New("Frame", {
        Parent = section.Container,
        Size = UDim2.new(1, 0, 0, M.Row),
        BackgroundColor3 = C.Element,
        BorderSizePixel = 0
    })
    Corner(Frame, M.RadiusSm)
    local BtnStroke = Stroke(Frame, C.BorderStrong, 1, 0.3)

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

    local BtnIcon
    if config.Icon then
        BtnIcon = CreateIcon(Frame, config.Icon, 14, C.TextDim, {
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 12, 0.5, 0)
        })
    end

    local hovering = false

    Btn.MouseEnter:Connect(function()
        hovering = true
        Tween(Frame, { BackgroundColor3 = C.ElementHover }, 0.2, Enum.EasingStyle.Sine)
        Tween(BtnStroke, { Color = C.Accent, Transparency = 0 }, 0.2, Enum.EasingStyle.Sine)
        if BtnIcon then BtnIcon:SetColor(C.Accent, 0.2) end
    end)

    Btn.MouseLeave:Connect(function()
        hovering = false
        Tween(Frame, { BackgroundColor3 = C.Element }, 0.2, Enum.EasingStyle.Sine)
        Tween(BtnStroke, { Color = C.BorderStrong, Transparency = 0.3 }, 0.2, Enum.EasingStyle.Sine)
        if BtnIcon then BtnIcon:SetColor(C.TextDim, 0.2) end
    end)

    Btn.MouseButton1Down:Connect(function()
        Tween(Frame, { BackgroundColor3 = C.Accent:Lerp(C.Element, 0.65) }, 0.06, Enum.EasingStyle.Sine)
    end)

    Btn.MouseButton1Up:Connect(function()
        Tween(Frame, { BackgroundColor3 = hovering and C.ElementHover or C.Element }, 0.15, Enum.EasingStyle.Sine)
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

local function buildKeybind(section, config)
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

    local Frame = rowCard(section.Container, M.Row)

    New("TextLabel", {
        Parent = Frame,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(0.5, -12, 1, 0),
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
        Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.new(0, 80, 0, 22),
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
    Corner(KeyBtn, 5)
    Stroke(KeyBtn, C.Border, 1, 0.2)

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

local function buildInput(section, config)
    config = config or {}
    local name = config.Name or "Input"
    local default = config.Default or ""
    local placeholder = config.Placeholder or "Enter text..."
    local callback = config.Callback or function() end

    local configPath = pathFor(section, name)

    local I = { Value = default, Callback = callback, ConfigPath = configPath }

    local Frame = rowCard(section.Container, M.Input)

    local Label = New("TextLabel", {
        Parent = Frame,
        Position = UDim2.new(0, 12, 0, 6),
        Size = UDim2.new(1, -24, 0, 16),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = C.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.Gotham
    })

    local boxH = Library.IsMobile and 28 or 24
    local Box = New("TextBox", {
        Parent = Frame,
        Position = UDim2.new(0, 8, 1, -(boxH + 7)),
        Size = UDim2.new(1, -16, 0, boxH),
        BackgroundColor3 = C.Chip,
        BorderSizePixel = 0,
        Text = default,
        PlaceholderText = placeholder,
        TextColor3 = C.Text,
        PlaceholderColor3 = C.TextMuted,
        TextSize = 12,
        Font = Enum.Font.GothamMedium,
        ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    Corner(Box, 5)
    Pad(Box, 10, 0, 10, 0)

    local BoxStroke = Stroke(Box, C.Border, 1, 0.1)

    Box.Focused:Connect(function()
        Tween(BoxStroke, { Color = C.Accent, Transparency = 0 }, 0.15)
    end)

    Box.FocusLost:Connect(function()
        Tween(BoxStroke, { Color = C.Border, Transparency = 0.1 }, 0.15)
        I:SetValue(Box.Text)
    end)

    Box.MouseEnter:Connect(function()
        Tween(Box, { BackgroundColor3 = C.ElementActive }, 0.15)
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

local function buildColorPicker(section, config)
    config = config or {}
    local name = config.Name or "Color"
    local default = config.Default or Color3.fromRGB(124, 140, 255)
    local callback = config.Callback or function() end

    local configPath = pathFor(section, name)

    local CP = { Color = default, Hue = 0, Sat = 0, Val = 0, Callback = callback, ConfigPath = configPath, Open = false }
    CP.Hue, CP.Sat, CP.Val = default:ToHSV()

    local Frame = rowCard(section.Container, M.Row)

    New("TextLabel", {
        Parent = Frame,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -64, 1, 0),
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
        Size = UDim2.fromOffset(34, 18),
        BackgroundColor3 = default,
        BorderSizePixel = 0
    })
    Corner(ColorBox, 5)
    Stroke(ColorBox, Color3.fromRGB(255, 255, 255), 1, 0.75)

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
        Name = guiName("ColorPicker"),
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false,
        IgnoreGuiInset = true
    })
    mount(PickerGui)

    local PickerFrame = New("Frame", {
        Name = "PickerFrame",
        Parent = PickerGui,
        Position = UDim2.new(0.5, -105, 0.5, -120),
        Size = UDim2.new(0, 210, 0, 244),
        BackgroundColor3 = C.Section,
        BorderSizePixel = 0,
        Visible = false
    })
    Corner(PickerFrame, M.RadiusMd + 2)
    Stroke(PickerFrame, C.BorderStrong, 1, 0)
    local PickerScale = New("UIScale", { Parent = PickerFrame, Scale = Library.IsMobile and 1.15 or 1 })

    New("TextLabel", {
        Parent = PickerFrame,
        Position = UDim2.new(0, 12, 0, 6),
        Size = UDim2.new(1, -24, 0, 20),
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
        Position = UDim2.new(0, 12, 0, 32),
        Size = UDim2.new(0, 160, 0, 160),
        BackgroundColor3 = Color3.fromHSV(CP.Hue, 1, 1),
        BorderSizePixel = 0,
        Image = "rbxassetid://8180999986",
        ImageColor3 = Color3.new(0, 0, 0),
        AutoButtonColor = false
    })
    Corner(SatVal, 6)
    Stroke(SatVal, C.Border, 1, 0)

    local SatValCursor = New("Frame", {
        Name = "Cursor",
        Parent = SatVal,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(CP.Sat, 1 - CP.Val),
        Size = UDim2.fromOffset(10, 10),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0
    })
    Corner(SatValCursor, 5)
    Stroke(SatValCursor, Color3.new(0, 0, 0), 2, 0)

    local HueSlider = New("ImageButton", {
        Name = "Hue",
        Parent = PickerFrame,
        Position = UDim2.new(0, 180, 0, 32),
        Size = UDim2.new(0, 18, 0, 160),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Image = "rbxassetid://8180989234",
        ScaleType = Enum.ScaleType.Crop,
        AutoButtonColor = false
    })
    Corner(HueSlider, 4)
    Stroke(HueSlider, C.Border, 1, 0)

    local HueCursor = New("Frame", {
        Name = "Cursor",
        Parent = HueSlider,
        Position = UDim2.fromScale(0, CP.Hue),
        Size = UDim2.new(1, 0, 0, 3),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0
    })
    Corner(HueCursor, 2)

    local HexBox = New("TextBox", {
        Name = "Hex",
        Parent = PickerFrame,
        Position = UDim2.new(0, 12, 0, 204),
        Size = UDim2.new(1, -24, 0, 26),
        BackgroundColor3 = C.Chip,
        BorderSizePixel = 0,
        Text = "#" .. default:ToHex():upper(),
        TextColor3 = C.Text,
        TextSize = 12,
        Font = Enum.Font.Code,
        ClearTextOnFocus = false
    })
    Corner(HexBox, 5)
    Stroke(HexBox, C.Border, 1, 0.1)
    Pad(HexBox, 8, 0, 8, 0)

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

        local pickerScale = PickerScale.Scale
        local pw, ph = 210 * pickerScale, 244 * pickerScale
        local boxPos = ColorBox.AbsolutePosition
        local screen = PickerGui.AbsoluteSize
        local x = math.clamp(boxPos.X - pw - 8, 6, math.max(6, screen.X - pw - 6))
        local y = math.clamp(boxPos.Y - 20, 6, math.max(6, screen.Y - ph - 6))
        PickerFrame.AnchorPoint = Vector2.new(0, 0)
        PickerFrame.Position = UDim2.fromOffset(x / pickerScale, y / pickerScale)

        CP.Open = true
        PickerScale.Scale = pickerScale * 0.92
        PickerFrame.Visible = true
        Tween(PickerScale, { Scale = pickerScale }, 0.3, Enum.EasingStyle.Back)
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

Library:RegisterComponent("Toggle", buildToggle)
Library:RegisterComponent("Slider", buildSlider)
Library:RegisterComponent("Dropdown", buildDropdown)
Library:RegisterComponent("Label", buildLabel)
Library:RegisterComponent("Button", buildButton)
Library:RegisterComponent("Keybind", buildKeybind)
Library:RegisterComponent("Input", buildInput)
Library:RegisterComponent("ColorPicker", buildColorPicker)

function Library:CreateKeybinds()
    if Library.IsMobile then
        local stub = { Items = {}, HeaderLetters = {} }
        function stub:SetVisible() end

        function stub:UpdateKeybind() end

        Library.KeybindsWindow = stub
        return stub
    end

    local KeybindsGui = New("ScreenGui", {
        Name = guiName("Keybinds"),
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false,
        IgnoreGuiInset = true
    })
    mount(KeybindsGui)

    local KeybindsFrame = New("CanvasGroup", {
        Name = "KeybindsFrame",
        Parent = KeybindsGui,
        Position = UDim2.new(0, 12, 0.5, -150),
        Size = UDim2.new(0, 196, 0, 0),
        BackgroundColor3 = C.TopBar,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        GroupTransparency = 1
    })

    Corner(KeybindsFrame, M.RadiusMd + 2)
    Stroke(KeybindsFrame, C.BorderStrong, 1, 0)

    local Header = New("Frame", {
        Name = "Header",
        Parent = KeybindsFrame,
        Size = UDim2.new(1, 0, 0, 34),
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
        Position = UDim2.new(0, 0, 0, 34),
        Size = UDim2.new(1, 0, 0, 1),
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
            NumberSequenceKeypoint.new(0.5, 0.3),
            NumberSequenceKeypoint.new(1, 1)
        })
    })

    table.insert(Library.AccentElements, KeybindsAccentLine)

    local Container = New("Frame", {
        Name = "Container",
        Parent = KeybindsFrame,
        Position = UDim2.new(0, 0, 0, 40),
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y
    })

    New("UIListLayout", {
        Parent = Container,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2)
    })

    Pad(Container, 10, 0, 10, 8)

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
            Size = UDim2.new(1, 0, 0, 24),
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
        Corner(AccentBar, 2)
        table.insert(Library.AccentElements, AccentBar)

        local NameLabel = New("TextLabel", {
            Name = "NameLabel",
            Parent = ItemFrame,
            Position = UDim2.new(0, 10, 0, 0),
            Size = UDim2.new(1, -70, 1, 0),
            BackgroundTransparency = 1,
            Text = name,
            TextColor3 = active and C.Text or C.TextDim,
            TextSize = 12,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd
        })

        local KeyLabel = New("TextLabel", {
            Name = "KeyLabel",
            Parent = ItemFrame,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.new(0, 56, 0, 18),
            BackgroundColor3 = C.Chip,
            BorderSizePixel = 0,
            Text = key or "None",
            TextColor3 = C.Accent,
            TextSize = 11,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextTruncate = Enum.TextTruncate.AtEnd
        })
        Corner(KeyLabel, 4)

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
                TextColor3 = newActive and C.Text or C.TextDim
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

function Library:CreateConfigSection(category, column)
    local sec = Library:CreateSection(category, "Configs", column or "right", "settings")

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
        Icon = "save",
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
        Icon = "folder-open",
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
        Icon = "trash-2",
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

    Library:CreateButton(sec, { Name = "Refresh list", Icon = "refresh-cw", Callback = refresh })

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
        success = C.Success,
        warning = C.Warning,
        error = C.Danger
    }
    local typeIcons = {
        success = "circle-check",
        warning = "triangle-alert",
        error = "circle-x"
    }
    local typeKey = tostring(config.Type or ""):lower()
    local barColor = typeColors[typeKey] or C.Accent
    local iconName = typeIcons[typeKey] or "info"
    local titleText = config.Title or (typeKey ~= "" and (typeKey:sub(1, 1):upper() .. typeKey:sub(2)) or "Notice")

    Library:PlayNotificationSound(soundType)

    if not Library.NotificationGui or not Library.NotificationGui.Parent then
        local NotifGui = New("ScreenGui", {
            Name = guiName("Notifications"),
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            ResetOnSpawn = false,
            IgnoreGuiInset = true
        })
        mount(NotifGui)

        Library.NotificationGui = NotifGui
        Library.Notifications = {}
    end

    local textSize = TextService:GetTextSize(message, 12, Enum.Font.GothamMedium, Vector2.new(300, 1000))
    local notifWidth = math.max(210, textSize.X + 40)
    local notifHeight = math.max(54, textSize.Y + 38)

    local Card = New("CanvasGroup", {
        Name = "Notification",
        Parent = Library.NotificationGui,
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, notifWidth + 30, 1, -16),
        Size = UDim2.fromOffset(notifWidth, notifHeight),
        BackgroundColor3 = C.Section,
        BorderSizePixel = 0,
        GroupTransparency = 1
    })
    Corner(Card, M.RadiusMd)
    Stroke(Card, C.BorderStrong, 1, 0)
    Sheen(Card, M.RadiusMd, 0.05)

    New("Frame", {
        Name = "AccentBar",
        Parent = Card,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(0, 3, 1, 0),
        BackgroundColor3 = barColor,
        BorderSizePixel = 0
    })

    CreateIcon(Card, iconName, 14, barColor, {
        AnchorPoint = Vector2.new(0, 0),
        Position = UDim2.new(0, 14, 0, 9)
    })

    New("TextLabel", {
        Name = "Title",
        Parent = Card,
        Position = UDim2.new(0, 34, 0, 8),
        Size = UDim2.new(1, -44, 0, 16),
        BackgroundTransparency = 1,
        Text = tostring(titleText):upper(),
        TextColor3 = barColor,
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    New("TextLabel", {
        Name = "Message",
        Parent = Card,
        Position = UDim2.new(0, 14, 0, 27),
        Size = UDim2.new(1, -26, 1, -34),
        BackgroundTransparency = 1,
        Text = message,
        TextColor3 = C.Text,
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

-- short alias
function Library:Notify(config)
    return Library:CreateNotification(config)
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

    Library.AccentElements = {}
    Library.AccentTextElements = {}
    Library.AccentImages = {}
    Library.AccentIcons = {}
    Library.BorderGradients = {}

    Library.Windows = nil
    Library.KeybindsWindow = nil
    Library.NotificationGui = nil
    Library.Notifications = {}
    Library.ColorPickers = nil
    Library.ModeMenus = nil
    Library.KeybindToggles = nil
    TooltipGui, TooltipFrame, TooltipLabel = nil, nil, nil
    hideTooltip()

    local key = "__UILib_" .. Library.Prefix
    if genv[key] == Library then
        genv[key] = nil
    end
end

Library.Unload = Library.Destroy

return Library
