--[[
    Nexus UI
    A reusable Roblox Luau UI library.
    Place this ModuleScript in ReplicatedStorage (or another accessible location).
    Use from a LocalScript with require().

    This library uses supported Roblox APIs only. It does not include executor
    injection, exploit-only file APIs, or loadstring/HttpGet loaders.
]]

local Nexus = {}
Nexus.__index = Nexus

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local THEMES = {
    Dark = {
        Background = Color3.fromRGB(17, 19, 27),
        Panel = Color3.fromRGB(23, 26, 36),
        Element = Color3.fromRGB(31, 35, 48),
        ElementHover = Color3.fromRGB(40, 45, 61),
        Accent = Color3.fromRGB(133, 97, 255),
        Accent2 = Color3.fromRGB(65, 155, 255),
        Text = Color3.fromRGB(245, 246, 255),
        Muted = Color3.fromRGB(155, 161, 180),
        Border = Color3.fromRGB(55, 61, 80),
        Success = Color3.fromRGB(91, 207, 145),
        Danger = Color3.fromRGB(242, 94, 110)
    },
    Midnight = {
        Background = Color3.fromRGB(10, 15, 25),
        Panel = Color3.fromRGB(15, 23, 38),
        Element = Color3.fromRGB(23, 34, 54),
        ElementHover = Color3.fromRGB(31, 46, 70),
        Accent = Color3.fromRGB(45, 145, 255),
        Accent2 = Color3.fromRGB(80, 205, 255),
        Text = Color3.fromRGB(240, 248, 255),
        Muted = Color3.fromRGB(145, 165, 190),
        Border = Color3.fromRGB(45, 65, 90),
        Success = Color3.fromRGB(91, 207, 145),
        Danger = Color3.fromRGB(242, 94, 110)
    },
    Light = {
        Background = Color3.fromRGB(238, 240, 247),
        Panel = Color3.fromRGB(250, 251, 255),
        Element = Color3.fromRGB(231, 234, 244),
        ElementHover = Color3.fromRGB(218, 223, 238),
        Accent = Color3.fromRGB(111, 82, 230),
        Accent2 = Color3.fromRGB(55, 135, 230),
        Text = Color3.fromRGB(31, 35, 49),
        Muted = Color3.fromRGB(105, 111, 130),
        Border = Color3.fromRGB(205, 210, 225),
        Success = Color3.fromRGB(45, 160, 105),
        Danger = Color3.fromRGB(215, 65, 85)
    }
}

local function create(className, properties, parent)
    local object = Instance.new(className)
    for key, value in pairs(properties or {}) do
        object[key] = value
    end
    object.Parent = parent
    return object
end

local function corner(parent, radius)
    return create("UICorner", {CornerRadius = UDim.new(0, radius or 8)}, parent)
end

local function stroke(parent, color, transparency)
    return create("UIStroke", {
        Color = color or Color3.new(1, 1, 1),
        Transparency = transparency or 0.7,
        Thickness = 1
    }, parent)
end

local function padding(parent, left, right, top, bottom)
    return create("UIPadding", {
        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or 0),
        PaddingTop = UDim.new(0, top or 0),
        PaddingBottom = UDim.new(0, bottom or 0)
    }, parent)
end

local function label(parent, text, size, color, font)
    return create("TextLabel", {
        BackgroundTransparency = 1,
        Text = text or "",
        TextColor3 = color or Color3.new(1, 1, 1),
        TextSize = size or 14,
        Font = font or Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Size = UDim2.new(1, 0, 0, 20)
    }, parent)
end

local function safeCallback(callback, ...)
    if typeof(callback) ~= "function" then return end
    local ok, err = pcall(callback, ...)
    if not ok then
        warn("[Nexus UI] Callback error: " .. tostring(err))
    end
end

function Nexus:_tween(object, duration, properties, style, direction)
    if not self.Options.EnableAnimations then
        for key, value in pairs(properties) do object[key] = value end
        return nil
    end
    local info = TweenInfo.new(
        duration or self.Options.AnimationDuration,
        style or self.Options.AnimationStyle,
        direction or Enum.EasingDirection.Out
    )
    local tween = TweenService:Create(object, info, properties)
    tween:Play()
    return tween
end

function Nexus:_track(connection)
    table.insert(self._connections, connection)
    return connection
end

function Nexus:_registerControl(control)
    table.insert(self._controls, control)
    return control
end

function Nexus:_applyTheme()
    local theme = self.Theme
    if not self.Gui then return end
    self.GuiRoot.BackgroundColor3 = theme.Background
    self.Main.BackgroundColor3 = theme.Panel
    self.Sidebar.BackgroundColor3 = theme.Background
    self.Topbar.BackgroundColor3 = theme.Panel
    self.Outline.Color = theme.Border
    for _, object in ipairs(self._themed) do
        if object and object.Parent then
            local property = object:GetAttribute("NexusThemeProperty")
            if property and theme[property] then
                object.BackgroundColor3 = theme[property]
            end
        end
    end
end

function Nexus:SetTheme(themeNameOrTable)
    if typeof(themeNameOrTable) == "string" then
        local theme = THEMES[themeNameOrTable]
        assert(theme, "Unknown Nexus theme: " .. themeNameOrTable)
        self.Theme = table.clone(theme)
    elseif typeof(themeNameOrTable) == "table" then
        local merged = table.clone(self.Theme)
        for key, value in pairs(themeNameOrTable) do
            if typeof(merged[key]) == "Color3" and typeof(value) == "Color3" then
                merged[key] = value
            end
        end
        self.Theme = merged
    else
        error("SetTheme expects a theme name or color table")
    end
    self:_applyTheme()
end

function Nexus:CreateWindow(options)
    options = options or {}
    self.Options = {
        Name = options.Name or "Nexus UI",
        Subtitle = options.Subtitle or "Modern Interface",
        Theme = options.Theme or "Dark",
        ToggleKey = options.ToggleKey or Enum.KeyCode.RightControl,
        Size = options.Size or UDim2.fromOffset(700, 470),
        EnableAnimations = options.EnableAnimations ~= false,
        AnimationDuration = options.AnimationDuration or 0.22,
        AnimationStyle = options.AnimationStyle or Enum.EasingStyle.Quart,
        Resizable = options.Resizable ~= false
    }
    self.Theme = table.clone(THEMES[self.Options.Theme] or THEMES.Dark)
    self._connections = {}
    self._controls = {}
    self._tabs = {}
    self._themed = {}
    self._notifications = {}
    self._destroyed = false
    self._minimized = false

    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    local gui = create("ScreenGui", {
        Name = "NexusUI",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    }, playerGui)
    self.Gui = gui

    local root = create("Frame", {
        Name = "Root",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = self.Options.Size,
        BackgroundColor3 = self.Theme.Panel,
        BorderSizePixel = 0,
        ClipsDescendants = true
    }, gui)
    corner(root, 13)
    self.GuiRoot = root
    self.Outline = stroke(root, self.Theme.Border, 0.35)

    local scale = create("UIScale", {Scale = 1}, root)
    self.UIScale = scale
    local function updateScale()
        local camera = workspace.CurrentCamera
        if not camera then return end
        local viewport = camera.ViewportSize
        local factor = math.min(1, viewport.X / 850, viewport.Y / 620)
        scale.Scale = math.max(0.65, factor)
    end
    updateScale()
    self:_track(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(updateScale))
    if workspace.CurrentCamera then
        self:_track(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale))
    end

    local topbar = create("Frame", {
        Name = "Topbar",
        Size = UDim2.new(1, 0, 0, 58),
        BackgroundColor3 = self.Theme.Panel,
        BorderSizePixel = 0
    }, root)
    self.Topbar = topbar
    label(topbar, self.Options.Name, 16, self.Theme.Text, Enum.Font.GothamBold).Position = UDim2.fromOffset(18, 7)
    local subtitle = label(topbar, self.Options.Subtitle, 11, self.Theme.Muted)
    subtitle.Position = UDim2.fromOffset(18, 30)

    local close = create("TextButton", {
        Name = "Close",
        Text = "×",
        Font = Enum.Font.Gotham,
        TextSize = 25,
        TextColor3 = self.Theme.Muted,
        BackgroundColor3 = self.Theme.Element,
        Size = UDim2.fromOffset(32, 30),
        Position = UDim2.new(1, -44, 0, 14),
        BorderSizePixel = 0,
        AutoButtonColor = false
    }, topbar)
    corner(close, 8)
    local minimize = create("TextButton", {
        Name = "Minimize",
        Text = "—",
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextColor3 = self.Theme.Muted,
        BackgroundColor3 = self.Theme.Element,
        Size = UDim2.fromOffset(32, 30),
        Position = UDim2.new(1, -82, 0, 14),
        BorderSizePixel = 0,
        AutoButtonColor = false
    }, topbar)
    corner(minimize, 8)

    local sidebar = create("Frame", {
        Name = "Sidebar",
        Position = UDim2.fromOffset(0, 58),
        Size = UDim2.new(0, 165, 1, -58),
        BackgroundColor3 = self.Theme.Background,
        BorderSizePixel = 0
    }, root)
    self.Sidebar = sidebar
    padding(sidebar, 10, 10, 12, 10)
    local tabList = create("ScrollingFrame", {
        Name = "TabList",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        CanvasSize = UDim2.new()
    }, sidebar)
    local tabLayout = create("UIListLayout", {
        Padding = UDim.new(0, 7),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, tabList)
    tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        tabList.CanvasSize = UDim2.fromOffset(0, tabLayout.AbsoluteContentSize.Y + 5)
    end)
    self.TabList = tabList

    local main = create("Frame", {
        Name = "Main",
        Position = UDim2.fromOffset(165, 58),
        Size = UDim2.new(1, -165, 1, -58),
        BackgroundColor3 = self.Theme.Panel,
        BorderSizePixel = 0
    }, root)
    self.Main = main

    local dragStart, startPosition
    self:_track(topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragStart = input.Position
            startPosition = root.Position
        end
    end))
    self:_track(UserInputService.InputChanged:Connect(function(input)
        if dragStart and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            root.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X,
                startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
        end
    end))
    self:_track(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragStart = nil
        end
    end))

    self:_track(close.Activated:Connect(function() self:Destroy() end))
    self:_track(minimize.Activated:Connect(function() self:SetMinimized(not self._minimized) end))
    self:_track(UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == self.Options.ToggleKey then
            root.Visible = not root.Visible
        end
    end))

    self:_tween(root, 0.3, {Size = self.Options.Size})
    return self
end

function Nexus:SetVisible(visible)
    if self.GuiRoot then self.GuiRoot.Visible = visible == true end
end

function Nexus:SetMinimized(value)
    self._minimized = value == true
    if self._minimized then
        self:_tween(self.GuiRoot, 0.2, {Size = UDim2.new(self.Options.Size.X.Scale, self.Options.Size.X.Offset, 0, 58)})
    else
        self:_tween(self.GuiRoot, 0.2, {Size = self.Options.Size})
    end
end

function Nexus:CreateTab(options)
    options = options or {}
    local tab = {Library = self, Name = options.Name or "Tab", Controls = {}}
    local button = create("TextButton", {
        Name = "Tab_" .. tab.Name,
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = self.Theme.Element,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = options.Name or "Tab",
        TextColor3 = self.Theme.Muted,
        TextSize = 13,
        Font = Enum.Font.GothamMedium,
        AutoButtonColor = false
    }, self.TabList)
    corner(button, 8)

    local page = create("ScrollingFrame", {
        Name = "Page_" .. tab.Name,
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = self.Theme.Accent,
        Visible = false,
        CanvasSize = UDim2.new()
    }, self.Main)
    padding(page, 17, 17, 16, 18)
    local layout = create("UIListLayout", {
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, page)
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 30)
    end)

    function tab:_addControl(object)
        object.Parent = page
        table.insert(self.Controls, object)
        return object
    end

    function tab:CreateSection(name)
        local frame = create("Frame", {
            Size = UDim2.new(1, 0, 0, 27),
            BackgroundTransparency = 1
        }, page)
        local text = label(frame, string.upper(name or "SECTION"), 11, self.Library.Theme.Accent, Enum.Font.GothamBold)
        text.Size = UDim2.new(1, 0, 1, 0)
        local line = create("Frame", {
            Position = UDim2.new(0, 0, 1, -1),
            Size = UDim2.new(1, 0, 0, 1),
            BackgroundColor3 = self.Library.Theme.Border,
            BorderSizePixel = 0
        }, frame)
        return frame
    end

    function tab:CreateParagraph(config)
        config = config or {}
        local frame = create("Frame", {
            Size = UDim2.new(1, 0, 0, 68),
            BackgroundColor3 = self.Library.Theme.Element,
            BorderSizePixel = 0
        }, page)
        corner(frame, 9)
        padding(frame, 12, 12, 8, 8)
        local title = label(frame, config.Title or "Paragraph", 13, self.Library.Theme.Text, Enum.Font.GothamBold)
        local body = label(frame, config.Content or "", 11, self.Library.Theme.Muted)
        body.Position = UDim2.fromOffset(0, 25)
        body.Size = UDim2.new(1, 0, 0, 32)
        body.TextWrapped = true
        body.TextYAlignment = Enum.TextYAlignment.Top
        local object = {}
        function object:SetTitle(value) title.Text = tostring(value) end
        function object:SetContent(value) body.Text = tostring(value) end
        function object:Destroy() frame:Destroy() end
        return object
    end

    function tab:CreateLabel(text)
        local frame = create("Frame", {Size = UDim2.new(1, 0, 0, 25), BackgroundTransparency = 1}, page)
        local textLabel = label(frame, text or "", 12, self.Library.Theme.Muted)
        local object = {}
        function object:Set(value) textLabel.Text = tostring(value) end
        function object:Destroy() frame:Destroy() end
        return object
    end

    function tab:CreateDivider()
        local frame = create("Frame", {
            Size = UDim2.new(1, 0, 0, 1),
            BackgroundColor3 = self.Library.Theme.Border,
            BorderSizePixel = 0
        }, page)
        return {Destroy = function() frame:Destroy() end}
    end

    function tab:CreateButton(config)
        config = config or {}
        local frame = create("TextButton", {
            Size = UDim2.new(1, 0, 0, config.Description and 58 or 43),
            BackgroundColor3 = self.Library.Theme.Element,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false
        }, page)
        corner(frame, 9)
        local title = label(frame, config.Name or "Button", 13, self.Library.Theme.Text, Enum.Font.GothamMedium)
        title.Position = UDim2.fromOffset(12, config.Description and 7 or 0)
        title.Size = UDim2.new(1, -24, 0, 23)
        if config.Description then
            local desc = label(frame, config.Description, 10, self.Library.Theme.Muted)
            desc.Position = UDim2.fromOffset(12, 30)
            desc.Size = UDim2.new(1, -24, 0, 17)
        end
        frame.MouseEnter:Connect(function() self.Library:_tween(frame, 0.12, {BackgroundColor3 = self.Library.Theme.ElementHover}) end)
        frame.MouseLeave:Connect(function() self.Library:_tween(frame, 0.12, {BackgroundColor3 = self.Library.Theme.Element}) end)
        frame.Activated:Connect(function()
            self.Library:_tween(frame, 0.08, {BackgroundColor3 = self.Library.Theme.Accent})
            task.delay(0.1, function()
                if frame.Parent then self.Library:_tween(frame, 0.15, {BackgroundColor3 = self.Library.Theme.Element}) end
            end)
            safeCallback(config.Callback)
        end)
        return {Destroy = function() frame:Destroy() end, SetText = function(_, value) title.Text = tostring(value) end}
    end

    function tab:CreateToggle(config)
        config = config or {}
        local value = config.Default == true
        local frame = create("Frame", {Size = UDim2.new(1, 0, 0, 46), BackgroundColor3 = self.Library.Theme.Element, BorderSizePixel = 0}, page)
        corner(frame, 9)
        local title = label(frame, config.Name or "Toggle", 13, self.Library.Theme.Text, Enum.Font.GothamMedium)
        title.Position = UDim2.fromOffset(12, 0)
        title.Size = UDim2.new(1, -75, 1, 0)
        local track = create("Frame", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -12, 0.5, 0),
            Size = UDim2.fromOffset(39, 21),
            BackgroundColor3 = value and self.Library.Theme.Accent or self.Library.Theme.Border,
            BorderSizePixel = 0
        }, frame)
        corner(track, 20)
        local knob = create("Frame", {
            Size = UDim2.fromOffset(15, 15),
            Position = value and UDim2.new(1, -18, 0.5, -7) or UDim2.fromOffset(3, 3),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0
        }, track)
        corner(knob, 20)
        local object = {}
        function object:SetValue(newValue, fire)
            value = newValue == true
            self.Library:_tween(track, 0.16, {BackgroundColor3 = value and self.Library.Theme.Accent or self.Library.Theme.Border})
            self.Library:_tween(knob, 0.16, {Position = value and UDim2.new(1, -18, 0.5, -7) or UDim2.fromOffset(3, 3)})
            if fire ~= false then safeCallback(config.Callback, value) end
        end
        function object:GetValue() return value end
        function object:Destroy() frame:Destroy() end
        object.Library = self.Library
        local hit = create("TextButton", {BackgroundTransparency = 1, Text = "", Size = UDim2.fromScale(1, 1)}, frame)
        hit.Activated:Connect(function() object:SetValue(not value) end)
        return self.Library:_registerControl(object)
    end

    function tab:CreateSlider(config)
        config = config or {}
        local range = config.Range or {0, 100}
        local minimum, maximum = tonumber(range[1]) or 0, tonumber(range[2]) or 100
        assert(maximum > minimum, "Slider maximum must exceed minimum")
        local increment = math.max(tonumber(config.Increment) or 1, 0.000001)
        local value = math.clamp(tonumber(config.CurrentValue) or minimum, minimum, maximum)
        local frame = create("Frame", {Size = UDim2.new(1, 0, 0, 64), BackgroundColor3 = self.Library.Theme.Element, BorderSizePixel = 0}, page)
        corner(frame, 9)
        local title = label(frame, config.Name or "Slider", 12, self.Library.Theme.Text, Enum.Font.GothamMedium)
        title.Position = UDim2.fromOffset(12, 5)
        title.Size = UDim2.new(1, -90, 0, 20)
        local readout = label(frame, tostring(value), 11, self.Library.Theme.Accent, Enum.Font.GothamBold)
        readout.Position = UDim2.new(1, -72, 0, 5)
        readout.Size = UDim2.fromOffset(60, 20)
        readout.TextXAlignment = Enum.TextXAlignment.Right
        local bar = create("Frame", {Position = UDim2.fromOffset(12, 39), Size = UDim2.new(1, -24, 0, 6), BackgroundColor3 = self.Library.Theme.Border, BorderSizePixel = 0}, frame)
        corner(bar, 5)
        local fill = create("Frame", {Size = UDim2.new((value - minimum) / (maximum - minimum), 0, 1, 0), BackgroundColor3 = self.Library.Theme.Accent, BorderSizePixel = 0}, bar)
        corner(fill, 5)
        local knob = create("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new((value - minimum) / (maximum - minimum), 0, 0.5, 0), Size = UDim2.fromOffset(14, 14), BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0}, bar)
        corner(knob, 10)
        local dragging = false
        local object = {Library = self.Library}
        local function setFromX(x, fire)
            local alpha = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            local raw = minimum + (maximum - minimum) * alpha
            value = math.clamp(minimum + math.floor((raw - minimum) / increment + 0.5) * increment, minimum, maximum)
            local ratio = (value - minimum) / (maximum - minimum)
            readout.Text = tostring(value)
            self.Library:_tween(fill, 0.07, {Size = UDim2.new(ratio, 0, 1, 0)})
            self.Library:_tween(knob, 0.07, {Position = UDim2.new(ratio, 0, 0.5, 0)})
            if fire ~= false then safeCallback(config.Callback, value) end
        end
        function object:SetValue(newValue, fire)
            newValue = math.clamp(tonumber(newValue) or minimum, minimum, maximum)
            local ratio = (newValue - minimum) / (maximum - minimum)
            setFromX(bar.AbsolutePosition.X + ratio * bar.AbsoluteSize.X, fire)
        end
        function object:GetValue() return value end
        function object:Destroy() frame:Destroy() end
        bar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                setFromX(input.Position.X)
            end
        end)
        self.Library:_track(UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                setFromX(input.Position.X)
            end
        end))
        self.Library:_track(UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
        end))
        return self.Library:_registerControl(object)
    end

    function tab:CreateDropdown(config)
        config = config or {}
        local optionsList = config.Options or {}
        local selected = config.CurrentOption
        local expanded = false
        local frame = create("Frame", {Size = UDim2.new(1, 0, 0, 48), BackgroundColor3 = self.Library.Theme.Element, ClipsDescendants = true, BorderSizePixel = 0}, page)
        corner(frame, 9)
        local head = create("TextButton", {Size = UDim2.new(1, 0, 0, 48), BackgroundTransparency = 1, Text = "", AutoButtonColor = false}, frame)
        local title = label(head, config.Name or "Dropdown", 12, self.Library.Theme.Text, Enum.Font.GothamMedium)
        title.Position = UDim2.fromOffset(12, 2)
        title.Size = UDim2.new(0.55, 0, 0, 20)
        local current = label(head, tostring(selected or "Select"), 11, self.Library.Theme.Accent)
        current.Position = UDim2.new(0.55, 0, 0, 2)
        current.Size = UDim2.new(0.4, -20, 0, 20)
        current.TextXAlignment = Enum.TextXAlignment.Right
        local list = create("Frame", {Position = UDim2.fromOffset(8, 46), Size = UDim2.new(1, -16, 0, 0), BackgroundTransparency = 1}, frame)
        local listLayout = create("UIListLayout", {Padding = UDim.new(0, 4)}, list)
        local object = {Library = self.Library}
        local function rebuild()
            for _, child in ipairs(list:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
            for _, option in ipairs(optionsList) do
                local item = create("TextButton", {Size = UDim2.new(1, 0, 0, 27), BackgroundColor3 = self.Library.Theme.Panel, Text = tostring(option), TextColor3 = self.Library.Theme.Text, TextSize = 11, Font = Enum.Font.Gotham, BorderSizePixel = 0, AutoButtonColor = false}, list)
                corner(item, 6)
                item.Activated:Connect(function()
                    selected = option
                    current.Text = tostring(option)
                    object:SetExpanded(false)
                    safeCallback(config.Callback, option)
                end)
            end
            local height = math.min(#optionsList * 31, 155)
            list.Size = UDim2.new(1, -16, 0, height)
            if expanded then frame.Size = UDim2.new(1, 0, 0, 48 + height) end
        end
        function object:SetExpanded(state)
            expanded = state == true
            local height = math.min(#optionsList * 31, 155)
            self.Library:_tween(frame, 0.18, {Size = UDim2.new(1, 0, 0, expanded and (48 + height) or 48)})
        end
        function object:SetOptions(newOptions)
            optionsList = newOptions or {}
            rebuild()
            if selected and not table.find(optionsList, selected) then selected = nil; current.Text = "Select" end
        end
        function object:SetValue(value, fire)
            if table.find(optionsList, value) then
                selected = value
                current.Text = tostring(value)
                if fire ~= false then safeCallback(config.Callback, value) end
            end
        end
        function object:GetValue() return selected end
        function object:Destroy() frame:Destroy() end
        head.Activated:Connect(function() object:SetExpanded(not expanded) end)
        rebuild()
        return self.Library:_registerControl(object)
    end

    function tab:CreateInput(config)
        config = config or {}
        local frame = create("Frame", {Size = UDim2.new(1, 0, 0, 54), BackgroundColor3 = self.Library.Theme.Element, BorderSizePixel = 0}, page)
        corner(frame, 9)
        local title = label(frame, config.Name or "Input", 11, self.Library.Theme.Muted)
        title.Position = UDim2.fromOffset(12, 3)
        local box = create("TextBox", {
            Position = UDim2.fromOffset(10, 24),
            Size = UDim2.new(1, -20, 0, 24),
            BackgroundColor3 = self.Library.Theme.Panel,
            Text = config.Default or "",
            PlaceholderText = config.Placeholder or "Type here...",
            TextColor3 = self.Library.Theme.Text,
            PlaceholderColor3 = self.Library.Theme.Muted,
            TextSize = 11,
            Font = Enum.Font.Gotham,
            ClearTextOnFocus = false,
            BorderSizePixel = 0
        }, frame)
        corner(box, 6)
        local object = {}
        function object:SetValue(value) box.Text = tostring(value) end
        function object:GetValue() return box.Text end
        function object:Destroy() frame:Destroy() end
        box.FocusLost:Connect(function(enterPressed)
            local value = box.Text
            if config.Validate then
                local ok, valid = pcall(config.Validate, value)
                if not ok or valid == false then
                    self.Library:_tween(box, 0.12, {BackgroundColor3 = self.Library.Theme.Danger})
                    task.delay(0.25, function() if box.Parent then box.BackgroundColor3 = self.Library.Theme.Panel end end)
                    return
                end
            end
            safeCallback(config.Callback, value, enterPressed)
        end)
        return self.Library:_registerControl(object)
    end

    function tab:CreateKeybind(config)
        config = config or {}
        local key = config.Default or Enum.KeyCode.RightShift
        local listening = false
        local frame = create("TextButton", {Size = UDim2.new(1, 0, 0, 44), BackgroundColor3 = self.Library.Theme.Element, Text = "", BorderSizePixel = 0, AutoButtonColor = false}, page)
        corner(frame, 9)
        local title = label(frame, config.Name or "Keybind", 12, self.Library.Theme.Text)
        title.Position = UDim2.fromOffset(12, 0)
        local keyLabel = label(frame, key.Name, 11, self.Library.Theme.Accent)
        keyLabel.Position = UDim2.new(1, -100, 0, 0)
        keyLabel.Size = UDim2.fromOffset(85, 44)
        keyLabel.TextXAlignment = Enum.TextXAlignment.Right
        local object = {}
        function object:SetKey(newKey)
            if typeof(newKey) == "EnumItem" and newKey.EnumType == Enum.KeyCode then
                key = newKey
                keyLabel.Text = key.Name
            end
        end
        function object:GetKey() return key end
        function object:Destroy() frame:Destroy() end
        frame.Activated:Connect(function() listening = true; keyLabel.Text = "Press key..." end)
        self.Library:_track(UserInputService.InputBegan:Connect(function(input, processed)
            if listening then
                if input.KeyCode ~= Enum.KeyCode.Unknown then
                    key = input.KeyCode
                    keyLabel.Text = key.Name
                    listening = false
                end
            elseif not processed and input.KeyCode == key then
                safeCallback(config.Callback, key)
            end
        end))
        return self.Library:_registerControl(object)
    end

    local function selectTab()
        for _, entry in ipairs(self.Library._tabs) do
            local active = entry == tab
            entry.Page.Visible = active
            self.Library:_tween(entry.Button, 0.15, {
                BackgroundTransparency = active and 0 or 1,
                TextColor3 = active and self.Library.Theme.Text or self.Library.Theme.Muted
            })
        end
    end
    tab.Page, tab.Button = page, button
    button.Activated:Connect(selectTab)
    table.insert(self.Library._tabs, tab)
    if #self.Library._tabs == 1 then selectTab() end
    return tab
end

function Nexus:CreateNotification(config)
    config = config or {}
    local holder = self.Gui:FindFirstChild("NotificationHolder")
    if not holder then
        holder = create("Frame", {
            Name = "NotificationHolder",
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -18, 1, -18),
            Size = UDim2.fromOffset(290, 300),
            BackgroundTransparency = 1
        }, self.Gui)
        create("UIListLayout", {VerticalAlignment = Enum.VerticalAlignment.Bottom, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 8)}, holder)
    end
    local card = create("Frame", {Size = UDim2.fromOffset(280, 70), BackgroundColor3 = self.Theme.Panel, BorderSizePixel = 0}, holder)
    corner(card, 10)
    stroke(card, self.Theme.Border, 0.35)
    local accent = create("Frame", {Size = UDim2.new(0, 3, 1, -18), Position = UDim2.fromOffset(0, 9), BackgroundColor3 = self.Theme.Accent, BorderSizePixel = 0}, card)
    corner(accent, 3)
    local title = label(card, config.Title or "Notification", 12, self.Theme.Text, Enum.Font.GothamBold)
    title.Position = UDim2.fromOffset(14, 8)
    title.Size = UDim2.new(1, -25, 0, 20)
    local desc = label(card, config.Content or config.Description or "", 10, self.Theme.Muted)
    desc.Position = UDim2.fromOffset(14, 30)
    desc.Size = UDim2.new(1, -25, 0, 30)
    desc.TextWrapped = true
    card.BackgroundTransparency = 1
    self:_tween(card, 0.2, {BackgroundTransparency = 0})
    task.delay(tonumber(config.Duration) or 4, function()
        if card.Parent then
            self:_tween(card, 0.18, {BackgroundTransparency = 1, Size = UDim2.fromOffset(250, 60)})
            task.wait(0.2)
            if card.Parent then card:Destroy() end
        end
    end)
    return card
end

function Nexus:CreateSearch(tab)
    assert(tab and tab.Page, "CreateSearch requires a tab")
    local box = create("TextBox", {
        Name = "Search",
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = self.Theme.Element,
        PlaceholderText = "Search this tab...",
        Text = "",
        TextColor3 = self.Theme.Text,
        PlaceholderColor3 = self.Theme.Muted,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        ClearTextOnFocus = false,
        BorderSizePixel = 0,
        LayoutOrder = -100
    }, tab.Page)
    corner(box, 8)
    box:GetPropertyChangedSignal("Text"):Connect(function()
        local query = string.lower(box.Text)
        for _, child in ipairs(tab.Page:GetChildren()) do
            if child:IsA("GuiObject") and child ~= box and not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
                local text = string.lower(child.Name .. " " .. (child:IsA("TextLabel") and child.Text or ""))
                child.Visible = query == "" or string.find(text, query, 1, true) ~= nil
            end
        end
    end)
    return box
end

function Nexus:GetConfig()
    local config = {}
    for index, control in ipairs(self._controls) do
        if control.GetValue then
            local ok, value = pcall(function() return control:GetValue() end)
            if ok then config[tostring(index)] = value end
        end
    end
    return config
end

function Nexus:LoadConfig(config)
    if typeof(config) ~= "table" then return false end
    for index, control in ipairs(self._controls) do
        local value = config[tostring(index)]
        if value ~= nil and control.SetValue then
            pcall(function() control:SetValue(value, false) end)
        end
    end
    return true
end

function Nexus:Destroy()
    if self._destroyed then return end
    self._destroyed = true
    for _, connection in ipairs(self._connections) do
        if connection.Connected then connection:Disconnect() end
    end
    table.clear(self._connections)
    if self.Gui then self.Gui:Destroy() end
    table.clear(self._controls)
    table.clear(self._tabs)
end

return setmetatable({}, Nexus)
