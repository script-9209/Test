--[[

	Exodus Hub Interface Suite
	A Rayfield-inspired UI Library with Custom Styling

	Features:
	- Draggable Logo Toggle Button
	- Semi-black theme with glowing blue outline
	- All Rayfield elements: Button, Toggle, Slider, Dropdown, Input, Keybind, ColorPicker, Label, Paragraph
	- Configuration Saving
	- Notifications
	- Smooth animations

]]

local ExodusHub = {}
ExodusHub.Flags = {}
ExodusHub.Theme = {
	TextColor = Color3.fromRGB(230, 240, 255),
	Background = Color3.fromRGB(12, 12, 14),
	Topbar = Color3.fromRGB(18, 18, 22),
	Shadow = Color3.fromRGB(5, 5, 8),

	NotificationBackground = Color3.fromRGB(12, 12, 14),
	NotificationActionsBackground = Color3.fromRGB(30, 80, 150),

	TabBackground = Color3.fromRGB(20, 20, 25),
	TabStroke = Color3.fromRGB(0, 120, 255),
	TabBackgroundSelected = Color3.fromRGB(0, 100, 220),
	TabTextColor = Color3.fromRGB(180, 200, 255),
	SelectedTabTextColor = Color3.fromRGB(255, 255, 255),

	ElementBackground = Color3.fromRGB(18, 18, 22),
	ElementBackgroundHover = Color3.fromRGB(25, 28, 35),
	SecondaryElementBackground = Color3.fromRGB(15, 15, 18),
	ElementStroke = Color3.fromRGB(0, 100, 220),
	SecondaryElementStroke = Color3.fromRGB(0, 80, 180),

	SliderBackground = Color3.fromRGB(30, 30, 35),
	SliderProgress = Color3.fromRGB(0, 120, 255),
	SliderStroke = Color3.fromRGB(0, 150, 255),

	ToggleBackground = Color3.fromRGB(25, 25, 30),
	ToggleEnabled = Color3.fromRGB(0, 120, 255),
	ToggleDisabled = Color3.fromRGB(60, 60, 70),
	ToggleEnabledStroke = Color3.fromRGB(0, 150, 255),
	ToggleDisabledStroke = Color3.fromRGB(80, 80, 90),
	ToggleEnabledOuterStroke = Color3.fromRGB(0, 100, 200),
	ToggleDisabledOuterStroke = Color3.fromRGB(50, 50, 60),

	DropdownSelected = Color3.fromRGB(0, 80, 180),
	DropdownUnselected = Color3.fromRGB(20, 20, 25),

	InputBackground = Color3.fromRGB(20, 20, 25),
	InputStroke = Color3.fromRGB(0, 100, 220),
	PlaceholderColor = Color3.fromRGB(120, 140, 180)
}

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Configuration
local CFileName = nil
local CEnabled = false
local Minimised = false
local Hidden = false
local Debounce = false
local searchOpen = false
local Notifications = {}
local SelectedTheme = ExodusHub.Theme
local exodusDestroyed = false
local dragOffset = 255

-- Utility Functions
local function getService(name)
	local service = game:GetService(name)
	return if cloneref then cloneref(service) else service
end

local function callSafely(func, ...)
	if func then
		local success, result = pcall(func, ...)
		if not success then
			warn("ExodusHub | Function failed: ", result)
			return false
		else
			return result
		end
	end
end

local function ensureFolder(folderPath)
	if isfolder and not callSafely(isfolder, folderPath) then
		callSafely(makefolder, folderPath)
	end
end

local function PackColor(Color)
	return {R = Color.R * 255, G = Color.G * 255, B = Color.B * 255}
end

local function UnpackColor(Color)
	return Color3.fromRGB(Color.R, Color.G, Color.B)
end

-- Draggable Function
local function makeDraggable(object, dragObject)
	local dragging = false
	local relative = nil
	local offset = Vector2.zero

	dragObject.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			relative = object.AbsolutePosition + object.AbsoluteSize * object.AnchorPoint - UserInputService:GetMouseLocation()
		end
	end)

	local inputEnded = UserInputService.InputEnded:Connect(function(input)
		if not dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	local renderStepped = RunService.RenderStepped:Connect(function()
		if dragging then
			local position = UserInputService:GetMouseLocation() + relative + offset
			object.Position = UDim2.fromOffset(position.X, position.Y)
		end
	end)

	object.Destroying:Connect(function()
		if inputEnded then inputEnded:Disconnect() end
		if renderStepped then renderStepped:Disconnect() end
	end)
end

-- Create Main GUI
local ExodusGui = Instance.new("ScreenGui")
ExodusGui.Name = "ExodusHub"
ExodusGui.ResetOnSpawn = false
ExodusGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ExodusGui.DisplayOrder = 999

if gethui then
	ExodusGui.Parent = gethui()
elseif syn and syn.protect_gui then
	syn.protect_gui(ExodusGui)
	ExodusGui.Parent = CoreGui
elseif CoreGui:FindFirstChild("RobloxGui") then
	ExodusGui.Parent = CoreGui:FindFirstChild("RobloxGui")
else
	ExodusGui.Parent = CoreGui
end

-- Notification Container
local NotificationContainer = Instance.new("Frame")
NotificationContainer.Name = "Notifications"
NotificationContainer.Parent = ExodusGui
NotificationContainer.BackgroundTransparency = 1
NotificationContainer.Size = UDim2.new(0, 300, 1, -20)
NotificationContainer.Position = UDim2.new(1, -320, 0, 10)
NotificationContainer.ClipsDescendants = true

local NotifListLayout = Instance.new("UIListLayout")
NotifListLayout.Parent = NotificationContainer
NotifListLayout.SortOrder = Enum.SortOrder.LayoutOrder
NotifListLayout.Padding = UDim.new(0, 8)
NotifListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom

-- Draggable Toggle Button (Logo)
local ToggleButton = Instance.new("Frame")
ToggleButton.Name = "ExodusToggle"
ToggleButton.Parent = ExodusGui
ToggleButton.BackgroundColor3 = Color3.fromRGB(12, 12, 14)
ToggleButton.BorderSizePixel = 0
ToggleButton.Size = UDim2.new(0, 55, 0, 55)
ToggleButton.Position = UDim2.new(0, 20, 0.5, -27)
ToggleButton.ZIndex = 100
ToggleButton.Active = true

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(1, 0)
ToggleCorner.Parent = ToggleButton

local ToggleStroke = Instance.new("UIStroke")
ToggleStroke.Parent = ToggleButton
ToggleStroke.Color = Color3.fromRGB(0, 120, 255)
ToggleStroke.Thickness = 2
ToggleStroke.Transparency = 0.3

local ToggleGlow = Instance.new("ImageLabel")
ToggleGlow.Name = "Glow"
ToggleGlow.Parent = ToggleButton
ToggleGlow.BackgroundTransparency = 1
ToggleGlow.Size = UDim2.new(1.4, 0, 1.4, 0)
ToggleGlow.Position = UDim2.new(-0.2, 0, -0.2, 0)
ToggleGlow.Image = "rbxassetid://10804938406"
ToggleGlow.ImageColor3 = Color3.fromRGB(0, 120, 255)
ToggleGlow.ImageTransparency = 0.7
ToggleGlow.ZIndex = 99

local ToggleImage = Instance.new("ImageLabel")
ToggleImage.Name = "Logo"
ToggleImage.Parent = ToggleButton
ToggleImage.BackgroundTransparency = 1
ToggleImage.Size = UDim2.new(0.8, 0, 0.8, 0)
ToggleImage.Position = UDim2.new(0.1, 0, 0.1, 0)
ToggleImage.Image = "rbxassetid://0" -- REPLACE WITH YOUR LOGO ASSET ID
ToggleImage.ZIndex = 101

-- Glow Animation
local glowTween = TweenService:Create(ToggleStroke, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
	Color = Color3.fromRGB(0, 180, 255),
	Transparency = 0
})
glowTween:Play()

local glowPulse = TweenService:Create(ToggleGlow, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
	ImageTransparency = 0.4,
	Size = UDim2.new(1.6, 0, 1.6, 0),
	Position = UDim2.new(-0.3, 0, -0.3, 0)
})
glowPulse:Play()

makeDraggable(ToggleButton, ToggleButton)

-- Main Window
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Parent = ExodusGui
Main.BackgroundColor3 = SelectedTheme.Background
Main.BorderSizePixel = 0
Main.Size = UDim2.new(0, 500, 0, 475)
Main.Position = UDim2.new(0.5, -250, 0.5, -237)
Main.Visible = false
Main.Active = true
Main.ClipsDescendants = true

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Parent = Main
MainStroke.Color = Color3.fromRGB(0, 100, 220)
MainStroke.Thickness = 1.5
MainStroke.Transparency = 0.5

local MainShadow = Instance.new("ImageLabel")
MainShadow.Name = "Shadow"
MainShadow.Parent = Main
MainShadow.BackgroundTransparency = 1
MainShadow.Size = UDim2.new(1, 60, 1, 60)
MainShadow.Position = UDim2.new(0, -30, 0, -30)
MainShadow.Image = "rbxassetid://5587865193"
MainShadow.ImageColor3 = SelectedTheme.Shadow
MainShadow.ImageTransparency = 0.6
MainShadow.ScaleType = Enum.ScaleType.Slice
MainShadow.SliceCenter = Rect.new(30, 30, 450, 450)
MainShadow.ZIndex = -1

-- Topbar
local Topbar = Instance.new("Frame")
Topbar.Name = "Topbar"
Topbar.Parent = Main
Topbar.BackgroundColor3 = SelectedTheme.Topbar
Topbar.BorderSizePixel = 0
Topbar.Size = UDim2.new(1, 0, 0, 45)

local TopbarCorner = Instance.new("UICorner")
TopbarCorner.CornerRadius = UDim.new(0, 10)
TopbarCorner.Parent = Topbar

local TopbarRepair = Instance.new("Frame")
TopbarRepair.Name = "CornerRepair"
TopbarRepair.Parent = Topbar
TopbarRepair.BackgroundColor3 = SelectedTheme.Topbar
TopbarRepair.BorderSizePixel = 0
TopbarRepair.Size = UDim2.new(1, 0, 0, 10)
TopbarRepair.Position = UDim2.new(0, 0, 1, -10)

local TopbarTitle = Instance.new("TextLabel")
TopbarTitle.Name = "Title"
TopbarTitle.Parent = Topbar
TopbarTitle.BackgroundTransparency = 1
TopbarTitle.Size = UDim2.new(1, -150, 1, 0)
TopbarTitle.Position = UDim2.new(0, 15, 0, 0)
TopbarTitle.Font = Enum.Font.GothamBold
TopbarTitle.Text = "Exodus Hub"
TopbarTitle.TextColor3 = SelectedTheme.TextColor
TopbarTitle.TextSize = 16
TopbarTitle.TextXAlignment = Enum.TextXAlignment.Left

local TopbarDivider = Instance.new("Frame")
TopbarDivider.Name = "Divider"
TopbarDivider.Parent = Topbar
TopbarDivider.BackgroundColor3 = SelectedTheme.ElementStroke
TopbarDivider.BorderSizePixel = 0
TopbarDivider.Size = UDim2.new(1, 0, 0, 1)
TopbarDivider.Position = UDim2.new(0, 0, 1, 0)

-- Topbar Buttons
local function createTopbarButton(name, icon, position)
	local btn = Instance.new("ImageButton")
	btn.Name = name
	btn.Parent = Topbar
	btn.BackgroundTransparency = 1
	btn.Size = UDim2.new(0, 22, 0, 22)
	btn.Position = position
	btn.Image = icon
	btn.ImageColor3 = SelectedTheme.TextColor
	btn.ImageTransparency = 0.8
	return btn
end

local HideBtn = createTopbarButton("Hide", "rbxassetid://10137832201", UDim2.new(1, -35, 0.5, -11))
local MinimiseBtn = createTopbarButton("Minimise", "rbxassetid://10137941941", UDim2.new(1, -65, 0.5, -11))

-- Tab List
local TabList = Instance.new("ScrollingFrame")
TabList.Name = "TabList"
TabList.Parent = Main
TabList.BackgroundTransparency = 1
TabList.Size = UDim2.new(1, -20, 0, 35)
TabList.Position = UDim2.new(0, 10, 0, 50)
TabList.ScrollBarThickness = 0
TabList.ScrollingDirection = Enum.ScrollingDirection.X
TabList.CanvasSize = UDim2.new(0, 0, 0, 0)

local TabListLayout = Instance.new("UIListLayout")
TabListLayout.Parent = TabList
TabListLayout.FillDirection = Enum.FillDirection.Horizontal
TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabListLayout.Padding = UDim.new(0, 8)

-- Elements Container
local Elements = Instance.new("Frame")
Elements.Name = "Elements"
Elements.Parent = Main
Elements.BackgroundTransparency = 1
Elements.Size = UDim2.new(1, -20, 1, -100)
Elements.Position = UDim2.new(0, 10, 0, 90)
Elements.ClipsDescendants = true

local ElementsLayout = Instance.new("UIPageLayout")
ElementsLayout.Parent = Elements
ElementsLayout.FillDirection = Enum.FillDirection.Horizontal
ElementsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ElementsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
ElementsLayout.EasingStyle = Enum.EasingStyle.Exponential
ElementsLayout.EasingDirection = Enum.EasingDirection.InOut
ElementsLayout.TweenTime = 0.4
ElementsLayout.ScrollWheelInputEnabled = false

-- Loading Frame
local LoadingFrame = Instance.new("Frame")
LoadingFrame.Name = "LoadingFrame"
LoadingFrame.Parent = Main
LoadingFrame.BackgroundTransparency = 1
LoadingFrame.Size = UDim2.new(1, 0, 1, -45)
LoadingFrame.Position = UDim2.new(0, 0, 0, 45)
LoadingFrame.Visible = false

local LoadingTitle = Instance.new("TextLabel")
LoadingTitle.Name = "Title"
LoadingTitle.Parent = LoadingFrame
LoadingTitle.BackgroundTransparency = 1
LoadingTitle.Size = UDim2.new(1, 0, 0, 40)
LoadingTitle.Position = UDim2.new(0, 0, 0.35, 0)
LoadingTitle.Font = Enum.Font.GothamBold
LoadingTitle.Text = "Exodus Hub"
LoadingTitle.TextColor3 = SelectedTheme.TextColor
LoadingTitle.TextSize = 28

local LoadingSubtitle = Instance.new("TextLabel")
LoadingSubtitle.Name = "Subtitle"
LoadingSubtitle.Parent = LoadingFrame
LoadingSubtitle.BackgroundTransparency = 1
LoadingSubtitle.Size = UDim2.new(1, 0, 0, 20)
LoadingSubtitle.Position = UDim2.new(0, 0, 0.35, 45)
LoadingSubtitle.Font = Enum.Font.Gotham
LoadingSubtitle.Text = "Interface Suite"
LoadingSubtitle.TextColor3 = SelectedTheme.TextColor
LoadingSubtitle.TextSize = 14
LoadingSubtitle.TextTransparency = 0.5

-- Search Bar
local SearchBar = Instance.new("Frame")
SearchBar.Name = "Search"
SearchBar.Parent = Main
SearchBar.BackgroundColor3 = SelectedTheme.Topbar
SearchBar.BorderSizePixel = 0
SearchBar.Size = UDim2.new(1, -20, 0, 35)
SearchBar.Position = UDim2.new(0, 10, 0, 50)
SearchBar.Visible = false
SearchBar.ZIndex = 10

local SearchCorner = Instance.new("UICorner")
SearchCorner.CornerRadius = UDim.new(0, 6)
SearchCorner.Parent = SearchBar

local SearchStroke = Instance.new("UIStroke")
SearchStroke.Parent = SearchBar
SearchStroke.Color = SelectedTheme.ElementStroke
SearchStroke.Transparency = 0.8

local SearchIcon = Instance.new("ImageLabel")
SearchIcon.Name = "Icon"
SearchIcon.Parent = SearchBar
SearchIcon.BackgroundTransparency = 1
SearchIcon.Size = UDim2.new(0, 18, 0, 18)
SearchIcon.Position = UDim2.new(0, 10, 0.5, -9)
SearchIcon.Image = "rbxassetid://18458939117"
SearchIcon.ImageColor3 = SelectedTheme.TextColor
SearchIcon.ImageTransparency = 0.5

local SearchInput = Instance.new("TextBox")
SearchInput.Name = "Input"
SearchInput.Parent = SearchBar
SearchInput.BackgroundTransparency = 1
SearchInput.Size = UDim2.new(1, -40, 1, 0)
SearchInput.Position = UDim2.new(0, 35, 0, 0)
SearchInput.Font = Enum.Font.Gotham
SearchInput.Text = ""
SearchInput.PlaceholderText = "Search elements..."
SearchInput.TextColor3 = SelectedTheme.TextColor
SearchInput.PlaceholderColor3 = SelectedTheme.PlaceholderColor
SearchInput.TextSize = 13
SearchInput.TextXAlignment = Enum.TextXAlignment.Left
SearchInput.ClearTextOnFocus = false

makeDraggable(Main, Topbar)

-- Notification System
function ExodusHub:Notify(data)
	task.spawn(function()
		local notif = Instance.new("Frame")
		notif.Name = data.Title or "Notification"
		notif.Parent = NotificationContainer
		notif.BackgroundColor3 = SelectedTheme.NotificationBackground
		notif.BorderSizePixel = 0
		notif.Size = UDim2.new(1, 0, 0, 0)
		notif.ClipsDescendants = true

		local notifCorner = Instance.new("UICorner")
		notifCorner.CornerRadius = UDim.new(0, 8)
		notifCorner.Parent = notif

		local notifStroke = Instance.new("UIStroke")
		notifStroke.Parent = notif
		notifStroke.Color = Color3.fromRGB(0, 120, 255)
		notifStroke.Thickness = 1
		notifStroke.Transparency = 0.7

		local notifTitle = Instance.new("TextLabel")
		notifTitle.Name = "Title"
		notifTitle.Parent = notif
		notifTitle.BackgroundTransparency = 1
		notifTitle.Size = UDim2.new(1, -20, 0, 22)
		notifTitle.Position = UDim2.new(0, 15, 0, 10)
		notifTitle.Font = Enum.Font.GothamBold
		notifTitle.Text = data.Title or "Notification"
		notifTitle.TextColor3 = SelectedTheme.TextColor
		notifTitle.TextSize = 14
		notifTitle.TextXAlignment = Enum.TextXAlignment.Left

		local notifDesc = Instance.new("TextLabel")
		notifDesc.Name = "Description"
		notifDesc.Parent = notif
		notifDesc.BackgroundTransparency = 1
		notifDesc.Size = UDim2.new(1, -20, 0, 20)
		notifDesc.Position = UDim2.new(0, 15, 0, 32)
		notifDesc.Font = Enum.Font.Gotham
		notifDesc.Text = data.Content or ""
		notifDesc.TextColor3 = SelectedTheme.TextColor
		notifDesc.TextSize = 12
		notifDesc.TextTransparency = 0.3
		notifDesc.TextXAlignment = Enum.TextXAlignment.Left
		notifDesc.TextWrapped = true

		local notifGlow = Instance.new("ImageLabel")
		notifGlow.Name = "Glow"
		notifGlow.Parent = notif
		notifGlow.BackgroundTransparency = 1
		notifGlow.Size = UDim2.new(1, 20, 1, 20)
		notifGlow.Position = UDim2.new(0, -10, 0, -10)
		notifGlow.Image = "rbxassetid://10804938406"
		notifGlow.ImageColor3 = Color3.fromRGB(0, 120, 255)
		notifGlow.ImageTransparency = 0.9
		notifGlow.ZIndex = -1

		local bounds = math.max(notifTitle.TextBounds.Y + notifDesc.TextBounds.Y + 25, 60)

		notif.BackgroundTransparency = 1
		notifTitle.TextTransparency = 1
		notifDesc.TextTransparency = 1
		notifStroke.Transparency = 1

		TweenService:Create(notif, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Size = UDim2.new(1, 0, 0, bounds), BackgroundTransparency = 0.1}):Play()
		TweenService:Create(notifTitle, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
		TweenService:Create(notifDesc, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {TextTransparency = 0.3}):Play()
		TweenService:Create(notifStroke, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {Transparency = 0.7}):Play()

		local waitDuration = math.min(math.max((#(data.Content or "") * 0.1) + 2.5, 3), 10)
		task.wait(data.Duration or waitDuration)

		TweenService:Create(notif, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
		TweenService:Create(notifTitle, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
		TweenService:Create(notifDesc, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
		TweenService:Create(notifStroke, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
		TweenService:Create(notif, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Size = UDim2.new(1, 0, 0, 0)}):Play()

		task.wait(0.5)
		notif:Destroy()
	end)
end

-- Hide/Unhide Functions
local function Hide()
	if Debounce then return end
	Debounce = true

	TweenService:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 500, 0, 0)}):Play()
	TweenService:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
	TweenService:Create(Topbar, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
	TweenService:Create(TopbarTitle, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
	TweenService:Create(MainStroke, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
	TweenService:Create(MainShadow, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {ImageTransparency = 1}):Play()
	TweenService:Create(ToggleButton, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()

	for _, child in ipairs(TabList:GetChildren()) do
		if child:IsA("Frame") then
			TweenService:Create(child, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
			for _, c in ipairs(child:GetDescendants()) do
				if c:IsA("TextLabel") then
					TweenService:Create(c, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
				elseif c:IsA("UIStroke") then
					TweenService:Create(c, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
				end
			end
		end
	end

	for _, page in ipairs(Elements:GetChildren()) do
		if page:IsA("ScrollingFrame") then
			for _, elem in ipairs(page:GetChildren()) do
				if elem:IsA("Frame") and elem.Name ~= "UIListLayout" then
					TweenService:Create(elem, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
					for _, c in ipairs(elem:GetDescendants()) do
						if c:IsA("TextLabel") or c:IsA("TextBox") then
							TweenService:Create(c, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
						elseif c:IsA("UIStroke") then
							TweenService:Create(c, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
						end
					end
				end
			end
		end
	end

	task.wait(0.5)
	Main.Visible = false
	Hidden = true
	Debounce = false
end

local function Unhide()
	if Debounce then return end
	Debounce = true

	Main.Visible = true
	TweenService:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 500, 0, 475)}):Play()
	TweenService:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
	TweenService:Create(Topbar, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
	TweenService:Create(TopbarTitle, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
	TweenService:Create(MainStroke, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
	TweenService:Create(MainShadow, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {ImageTransparency = 0.6}):Play()

	for _, child in ipairs(TabList:GetChildren()) do
		if child:IsA("Frame") then
			TweenService:Create(child, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.7}):Play()
			for _, c in ipairs(child:GetDescendants()) do
				if c:IsA("TextLabel") then
					TweenService:Create(c, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 0.2}):Play()
				elseif c:IsA("UIStroke") then
					TweenService:Create(c, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
				end
			end
		end
	end

	for _, page in ipairs(Elements:GetChildren()) do
		if page:IsA("ScrollingFrame") then
			for _, elem in ipairs(page:GetChildren()) do
				if elem:IsA("Frame") and elem.Name ~= "UIListLayout" then
					TweenService:Create(elem, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
					for _, c in ipairs(elem:GetDescendants()) do
						if c:IsA("TextLabel") or c:IsA("TextBox") then
							TweenService:Create(c, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
						elseif c:IsA("UIStroke") then
							TweenService:Create(c, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
						end
					end
				end
			end
		end
	end

	Hidden = false
	Debounce = false
end

-- Toggle Button Click
ToggleButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		if Hidden then
			Unhide()
		else
			Hide()
		end
	end
end)

-- Hover effects for toggle
ToggleButton.MouseEnter:Connect(function()
	TweenService:Create(ToggleButton, TweenInfo.new(0.3), {Size = UDim2.new(0, 60, 0, 60)}):Play()
	TweenService:Create(ToggleButton, TweenInfo.new(0.3), {Position = ToggleButton.Position - UDim2.new(0, 2.5, 0, 2.5)}):Play()
end)

ToggleButton.MouseLeave:Connect(function()
	TweenService:Create(ToggleButton, TweenInfo.new(0.3), {Size = UDim2.new(0, 55, 0, 55)}):Play()
	TweenService:Create(ToggleButton, TweenInfo.new(0.3), {Position = ToggleButton.Position + UDim2.new(0, 2.5, 0, 2.5)}):Play()
end)

-- Topbar Buttons
HideBtn.MouseButton1Click:Connect(function()
	Hide()
end)

MinimiseBtn.MouseButton1Click:Connect(function()
	if Debounce then return end
	Debounce = true
	if Minimised then
		Minimised = false
		TweenService:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 500, 0, 475)}):Play()
		for _, page in ipairs(Elements:GetChildren()) do
			if page:IsA("ScrollingFrame") then
				page.Visible = true
			end
		end
	else
		Minimised = true
		TweenService:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 500, 0, 45)}):Play()
		for _, page in ipairs(Elements:GetChildren()) do
			if page:IsA("ScrollingFrame") then
				page.Visible = false
			end
		end
	end
	task.wait(0.5)
	Debounce = false
end)

-- Hover effects for topbar buttons
for _, btn in ipairs({HideBtn, MinimiseBtn}) do
	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.3), {ImageTransparency = 0}):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.3), {ImageTransparency = 0.8}):Play()
	end)
end

-- Keybind to toggle
local toggleKey = Enum.KeyCode.K
local keybindConnection = UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == toggleKey then
		if Hidden then
			Unhide()
		else
			Hide()
		end
	end
end)

-- Configuration Functions
local function SaveConfiguration()
	if not CEnabled then return end
	local Data = {}
	for i, v in pairs(ExodusHub.Flags) do
		if v.Type == "ColorPicker" then
			Data[i] = PackColor(v.Color)
		else
			Data[i] = v.CurrentValue or v.CurrentKeybind or v.CurrentOption or v.Color
		end
	end
	callSafely(writefile, "ExodusHub/" .. CFileName .. ".exodus", tostring(HttpService:JSONEncode(Data)))
end

local function LoadConfiguration(Configuration)
	local success, Data = pcall(function() return HttpService:JSONDecode(Configuration) end)
	if not success then warn("ExodusHub | Failed to decode config") return end

	for FlagName, Flag in pairs(ExodusHub.Flags) do
		local FlagValue = Data[FlagName]
		if FlagValue ~= nil then
			task.spawn(function()
				if Flag.Type == "ColorPicker" then
					Flag:Set(UnpackColor(FlagValue))
				else
					Flag:Set(FlagValue)
				end
			end)
		end
	end
end

function ExodusHub:LoadConfiguration()
	if not CEnabled then return end
	if isfile and isfile("ExodusHub/" .. CFileName .. ".exodus") then
		local config = readfile("ExodusHub/" .. CFileName .. ".exodus")
		LoadConfiguration(config)
		ExodusHub:Notify({Title = "Configuration", Content = "Loaded saved configuration successfully!", Duration = 5})
	end
end

-- Create Window
function ExodusHub:CreateWindow(Settings)
	Settings = Settings or {}

	-- Setup config saving
	if Settings.ConfigurationSaving then
		CFileName = Settings.ConfigurationSaving.FileName or tostring(game.PlaceId)
		CEnabled = Settings.ConfigurationSaving.Enabled or false
		if CEnabled then
			ensureFolder("ExodusHub")
		end
	end

	TopbarTitle.Text = Settings.Name or "Exodus Hub"

	-- Show loading
	LoadingFrame.Visible = true
	LoadingTitle.Text = Settings.LoadingTitle or "Exodus Hub"
	LoadingSubtitle.Text = Settings.LoadingSubtitle or "Interface Suite"

	Main.Size = UDim2.new(0, 500, 0, 45)
	Main.Visible = true
	Main.BackgroundTransparency = 1
	MainStroke.Transparency = 1
	MainShadow.ImageTransparency = 1

	TweenService:Create(Main, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
	TweenService:Create(MainStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
	TweenService:Create(MainShadow, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {ImageTransparency = 0.6}):Play()

	-- Loading animation
	task.wait(0.3)
	TweenService:Create(LoadingTitle, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
	task.wait(0.1)
	TweenService:Create(LoadingSubtitle, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 0.5}):Play()

	task.wait(1)
	TweenService:Create(LoadingTitle, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
	TweenService:Create(LoadingSubtitle, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()

	LoadingFrame.Visible = false

	-- Show main UI
	TweenService:Create(Main, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 500, 0, 475)}):Play()

	local Window = {}
	local FirstTab = false

	-- Create Tab
	function Window:CreateTab(Name, Icon)
		local TabButton = Instance.new("Frame")
		TabButton.Name = Name
		TabButton.Parent = TabList
		TabButton.BackgroundColor3 = SelectedTheme.TabBackground
		TabButton.BorderSizePixel = 0
		TabButton.Size = UDim2.new(0, 0, 0, 30)
		TabButton.AutomaticSize = Enum.AutomaticSize.X
		TabButton.BackgroundTransparency = 1

		local TabBtnCorner = Instance.new("UICorner")
		TabBtnCorner.CornerRadius = UDim.new(0, 6)
		TabBtnCorner.Parent = TabButton

		local TabBtnStroke = Instance.new("UIStroke")
		TabBtnStroke.Parent = TabButton
		TabBtnStroke.Color = SelectedTheme.TabStroke
		TabBtnStroke.Transparency = 1
		TabBtnStroke.Thickness = 1

		local TabBtnTitle = Instance.new("TextLabel")
		TabBtnTitle.Name = "Title"
		TabBtnTitle.Parent = TabButton
		TabBtnTitle.BackgroundTransparency = 1
		TabBtnTitle.Size = UDim2.new(0, 0, 1, 0)
		TabBtnTitle.AutomaticSize = Enum.AutomaticSize.X
		TabBtnTitle.Position = UDim2.new(0, 12, 0, 0)
		TabBtnTitle.Font = Enum.Font.GothamSemibold
		TabBtnTitle.Text = Name
		TabBtnTitle.TextColor3 = SelectedTheme.TabTextColor
		TabBtnTitle.TextSize = 13
		TabBtnTitle.TextTransparency = 1

		local TabBtnPadding = Instance.new("UIPadding")
		TabBtnPadding.Parent = TabButton
		TabBtnPadding.PaddingLeft = UDim.new(0, 8)
		TabBtnPadding.PaddingRight = UDim.new(0, 8)

		if Icon then
			TabBtnTitle.Position = UDim2.new(0, 32, 0, 0)
			local TabBtnIcon = Instance.new("ImageLabel")
			TabBtnIcon.Name = "Icon"
			TabBtnIcon.Parent = TabButton
			TabBtnIcon.BackgroundTransparency = 1
			TabBtnIcon.Size = UDim2.new(0, 18, 0, 18)
			TabBtnIcon.Position = UDim2.new(0, 8, 0.5, -9)
			TabBtnIcon.Image = "rbxassetid://" .. tostring(Icon)
			TabBtnIcon.ImageTransparency = 1
			TabBtnIcon.ImageColor3 = SelectedTheme.TabTextColor
		end

		local TabPage = Instance.new("ScrollingFrame")
		TabPage.Name = Name
		TabPage.Parent = Elements
		TabPage.BackgroundTransparency = 1
		TabPage.Size = UDim2.new(1, 0, 1, 0)
		TabPage.ScrollBarThickness = 2
		TabPage.ScrollBarImageColor3 = Color3.fromRGB(0, 120, 255)
		TabPage.CanvasSize = UDim2.new(0, 0, 0, 0)
		TabPage.Visible = true

		local PageLayout = Instance.new("UIListLayout")
		PageLayout.Parent = TabPage
		PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
		PageLayout.Padding = UDim.new(0, 8)

		local PagePadding = Instance.new("UIPadding")
		PagePadding.Parent = TabPage
		PagePadding.PaddingLeft = UDim.new(0, 5)
		PagePadding.PaddingRight = UDim.new(0, 5)
		PagePadding.PaddingTop = UDim.new(0, 5)
		PagePadding.PaddingBottom = UDim.new(0, 5)

		PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			TabPage.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 10)
		end)

		if not FirstTab then
			FirstTab = true
			TabButton.BackgroundColor3 = SelectedTheme.TabBackgroundSelected
			TabBtnTitle.TextColor3 = SelectedTheme.SelectedTabTextColor
			ElementsLayout:JumpTo(TabPage)

			TweenService:Create(TabButton, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
			TweenService:Create(TabBtnTitle, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
			TweenService:Create(TabBtnStroke, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Transparency = 0.3}):Play()
			if TabButton:FindFirstChild("Icon") then
				TweenService:Create(TabButton.Icon, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {ImageTransparency = 0}):Play()
			end
		else
			TweenService:Create(TabButton, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.7}):Play()
			TweenService:Create(TabBtnTitle, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 0.2}):Play()
			TweenService:Create(TabBtnStroke, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Transparency = 0.7}):Play()
			if TabButton:FindFirstChild("Icon") then
				TweenService:Create(TabButton.Icon, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {ImageTransparency = 0.3}):Play()
			end
		end

		TabButton.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				ElementsLayout:JumpTo(TabPage)

				-- Update tab visuals
				for _, btn in ipairs(TabList:GetChildren()) do
					if btn:IsA("Frame") then
						if btn == TabButton then
							TweenService:Create(btn, TweenInfo.new(0.3), {BackgroundColor3 = SelectedTheme.TabBackgroundSelected, BackgroundTransparency = 0}):Play()
							TweenService:Create(btn.Title, TweenInfo.new(0.3), {TextColor3 = SelectedTheme.SelectedTabTextColor, TextTransparency = 0}):Play()
							TweenService:Create(btn.UIStroke, TweenInfo.new(0.3), {Transparency = 0.3}):Play()
							if btn:FindFirstChild("Icon") then
								TweenService:Create(btn.Icon, TweenInfo.new(0.3), {ImageColor3 = SelectedTheme.SelectedTabTextColor, ImageTransparency = 0}):Play()
							end
						else
							TweenService:Create(btn, TweenInfo.new(0.3), {BackgroundColor3 = SelectedTheme.TabBackground, BackgroundTransparency = 0.7}):Play()
							TweenService:Create(btn.Title, TweenInfo.new(0.3), {TextColor3 = SelectedTheme.TabTextColor, TextTransparency = 0.2}):Play()
							TweenService:Create(btn.UIStroke, TweenInfo.new(0.3), {Transparency = 0.7}):Play()
							if btn:FindFirstChild("Icon") then
								TweenService:Create(btn.Icon, TweenInfo.new(0.3), {ImageColor3 = SelectedTheme.TabTextColor, ImageTransparency = 0.3}):Play()
							end
						end
					end
				end
			end
		end)

		local Tab = {}

		-- Helper to create element base
		local function createElementBase(name, height)
			local elem = Instance.new("Frame")
			elem.Name = name
			elem.Parent = TabPage
			elem.BackgroundColor3 = SelectedTheme.ElementBackground
			elem.BorderSizePixel = 0
			elem.Size = UDim2.new(1, -10, 0, height or 40)
			elem.BackgroundTransparency = 1

			local elemCorner = Instance.new("UICorner")
			elemCorner.CornerRadius = UDim.new(0, 8)
			elemCorner.Parent = elem

			local elemStroke = Instance.new("UIStroke")
			elemStroke.Parent = elem
			elemStroke.Color = SelectedTheme.ElementStroke
			elemStroke.Transparency = 1
			elemStroke.Thickness = 1

			local elemTitle = Instance.new("TextLabel")
			elemTitle.Name = "Title"
			elemTitle.Parent = elem
			elemTitle.BackgroundTransparency = 1
			elemTitle.Size = UDim2.new(1, -20, 0, 20)
			elemTitle.Position = UDim2.new(0, 12, 0, 10)
			elemTitle.Font = Enum.Font.GothamSemibold
			elemTitle.Text = name
			elemTitle.TextColor3 = SelectedTheme.TextColor
			elemTitle.TextSize = 13
			elemTitle.TextXAlignment = Enum.TextXAlignment.Left
			elemTitle.TextTransparency = 1

			TweenService:Create(elem, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
			TweenService:Create(elemStroke, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
			TweenService:Create(elemTitle, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()

			elem.MouseEnter:Connect(function()
				TweenService:Create(elem, TweenInfo.new(0.3), {BackgroundColor3 = SelectedTheme.ElementBackgroundHover}):Play()
			end)

			elem.MouseLeave:Connect(function()
				TweenService:Create(elem, TweenInfo.new(0.3), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
			end)

			return elem
		end

		-- Button
		function Tab:CreateButton(ButtonSettings)
			ButtonSettings = ButtonSettings or {}
			local Button = createElementBase(ButtonSettings.Name or "Button", 40)

			local btnInteract = Instance.new("TextButton")
			btnInteract.Name = "Interact"
			btnInteract.Parent = Button
			btnInteract.BackgroundTransparency = 1
			btnInteract.Size = UDim2.new(1, 0, 1, 0)
			btnInteract.Text = ""

			local btnIndicator = Instance.new("TextLabel")
			btnIndicator.Name = "Indicator"
			btnIndicator.Parent = Button
			btnIndicator.BackgroundTransparency = 1
			btnIndicator.Size = UDim2.new(0, 30, 0, 20)
			btnIndicator.Position = UDim2.new(1, -40, 0.5, -10)
			btnIndicator.Font = Enum.Font.GothamBold
			btnIndicator.Text = ">"
			btnIndicator.TextColor3 = SelectedTheme.TextColor
			btnIndicator.TextSize = 14
			btnIndicator.TextTransparency = 0.9

			btnInteract.MouseButton1Click:Connect(function()
				local success, err = pcall(ButtonSettings.Callback or function() end)
				if not success then
					warn("ExodusHub | Button callback error: " .. tostring(err))
					Button.Title.Text = "Error!"
					task.wait(0.5)
					Button.Title.Text = ButtonSettings.Name or "Button"
				else
					TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundColor3 = SelectedTheme.ElementBackgroundHover}):Play()
					TweenService:Create(btnIndicator, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
					task.wait(0.15)
					TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
					TweenService:Create(btnIndicator, TweenInfo.new(0.2), {TextTransparency = 0.9}):Play()
				end
			end)

			return ButtonSettings
		end

		-- Toggle
		function Tab:CreateToggle(ToggleSettings)
			ToggleSettings = ToggleSettings or {}
			ToggleSettings.Type = "Toggle"
			local Toggle = createElementBase(ToggleSettings.Name or "Toggle", 40)

			local toggleSwitch = Instance.new("Frame")
			toggleSwitch.Name = "Switch"
			toggleSwitch.Parent = Toggle
			toggleSwitch.BackgroundColor3 = SelectedTheme.ToggleBackground
			toggleSwitch.BorderSizePixel = 0
			toggleSwitch.Size = UDim2.new(0, 44, 0, 24)
			toggleSwitch.Position = UDim2.new(1, -56, 0.5, -12)

			local switchCorner = Instance.new("UICorner")
			switchCorner.CornerRadius = UDim.new(1, 0)
			switchCorner.Parent = toggleSwitch

			local switchStroke = Instance.new("UIStroke")
			switchStroke.Parent = toggleSwitch
			switchStroke.Color = SelectedTheme.ToggleDisabledOuterStroke
			switchStroke.Thickness = 2

			local toggleIndicator = Instance.new("Frame")
			toggleIndicator.Name = "Indicator"
			toggleIndicator.Parent = toggleSwitch
			toggleIndicator.BackgroundColor3 = SelectedTheme.ToggleDisabled
			toggleIndicator.BorderSizePixel = 0
			toggleIndicator.Size = UDim2.new(0, 18, 0, 18)
			toggleIndicator.Position = UDim2.new(0, 3, 0.5, -9)

			local indicatorCorner = Instance.new("UICorner")
			indicatorCorner.CornerRadius = UDim.new(1, 0)
			indicatorCorner.Parent = toggleIndicator

			local indicatorStroke = Instance.new("UIStroke")
			indicatorStroke.Parent = toggleIndicator
			indicatorStroke.Color = SelectedTheme.ToggleDisabledStroke
			indicatorStroke.Thickness = 1.5

			local toggleInteract = Instance.new("TextButton")
			toggleInteract.Name = "Interact"
			toggleInteract.Parent = Toggle
			toggleInteract.BackgroundTransparency = 1
			toggleInteract.Size = UDim2.new(1, 0, 1, 0)
			toggleInteract.Text = ""

			local function updateToggle(value)
				ToggleSettings.CurrentValue = value
				if value then
					TweenService:Create(toggleIndicator, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Position = UDim2.new(1, -21, 0.5, -9)}):Play()
					TweenService:Create(toggleIndicator, TweenInfo.new(0.3), {BackgroundColor3 = SelectedTheme.ToggleEnabled}):Play()
					TweenService:Create(indicatorStroke, TweenInfo.new(0.3), {Color = SelectedTheme.ToggleEnabledStroke}):Play()
					TweenService:Create(switchStroke, TweenInfo.new(0.3), {Color = SelectedTheme.ToggleEnabledOuterStroke}):Play()
				else
					TweenService:Create(toggleIndicator, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Position = UDim2.new(0, 3, 0.5, -9)}):Play()
					TweenService:Create(toggleIndicator, TweenInfo.new(0.3), {BackgroundColor3 = SelectedTheme.ToggleDisabled}):Play()
					TweenService:Create(indicatorStroke, TweenInfo.new(0.3), {Color = SelectedTheme.ToggleDisabledStroke}):Play()
					TweenService:Create(switchStroke, TweenInfo.new(0.3), {Color = SelectedTheme.ToggleDisabledOuterStroke}):Play()
				end

				local success, err = pcall(function()
					if ToggleSettings.Callback then
						ToggleSettings.Callback(value)
					end
				end)
				if not success then warn("ExodusHub | Toggle callback error: " .. tostring(err)) end

				if ToggleSettings.Flag then
					SaveConfiguration()
				end
			end

			toggleInteract.MouseButton1Click:Connect(function()
				updateToggle(not ToggleSettings.CurrentValue)
			end)

			if ToggleSettings.CurrentValue then
				updateToggle(true)
			end

			function ToggleSettings:Set(value)
				updateToggle(value)
			end

			if ToggleSettings.Flag then
				ExodusHub.Flags[ToggleSettings.Flag] = ToggleSettings
			end

			return ToggleSettings
		end

		-- Slider
		function Tab:CreateSlider(SliderSettings)
			SliderSettings = SliderSettings or {}
			SliderSettings.Type = "Slider"
			local Slider = createElementBase(SliderSettings.Name or "Slider", 50)

			local sliderValue = Instance.new("TextLabel")
			sliderValue.Name = "Value"
			sliderValue.Parent = Slider
			sliderValue.BackgroundTransparency = 1
			sliderValue.Size = UDim2.new(0, 50, 0, 20)
			sliderValue.Position = UDim2.new(1, -60, 0, 5)
			sliderValue.Font = Enum.Font.Gotham
			sliderValue.Text = tostring(SliderSettings.CurrentValue or SliderSettings.Range[1]) .. (SliderSettings.Suffix or "")
			sliderValue.TextColor3 = SelectedTheme.TextColor
			sliderValue.TextSize = 12
			sliderValue.TextTransparency = 1
			sliderValue.TextXAlignment = Enum.TextXAlignment.Right
			TweenService:Create(sliderValue, TweenInfo.new(0.5), {TextTransparency = 0.3}):Play()

			local sliderBar = Instance.new("Frame")
			sliderBar.Name = "Bar"
			sliderBar.Parent = Slider
			sliderBar.BackgroundColor3 = SelectedTheme.SliderBackground
			sliderBar.BorderSizePixel = 0
			sliderBar.Size = UDim2.new(1, -24, 0, 6)
			sliderBar.Position = UDim2.new(0, 12, 0, 32)

			local barCorner = Instance.new("UICorner")
			barCorner.CornerRadius = UDim.new(1, 0)
			barCorner.Parent = sliderBar

			local barStroke = Instance.new("UIStroke")
			barStroke.Parent = sliderBar
			barStroke.Color = SelectedTheme.SliderStroke
			barStroke.Transparency = 0.4

			local sliderProgress = Instance.new("Frame")
			sliderProgress.Name = "Progress"
			sliderProgress.Parent = sliderBar
			sliderProgress.BackgroundColor3 = SelectedTheme.SliderProgress
			sliderProgress.BorderSizePixel = 0
			sliderProgress.Size = UDim2.new(0, 0, 1, 0)

			local progressCorner = Instance.new("UICorner")
			progressCorner.CornerRadius = UDim.new(1, 0)
			progressCorner.Parent = sliderProgress

			local sliderInteract = Instance.new("TextButton")
			sliderInteract.Name = "Interact"
			sliderInteract.Parent = sliderBar
			sliderInteract.BackgroundTransparency = 1
			sliderInteract.Size = UDim2.new(1, 0, 1, 10)
			sliderInteract.Position = UDim2.new(0, 0, 0, -5)
			sliderInteract.Text = ""

			local function updateSlider(newValue)
				local min = SliderSettings.Range[1]
				local max = SliderSettings.Range[2]
				local increment = SliderSettings.Increment or 1

				newValue = math.clamp(newValue, min, max)
				newValue = math.floor(newValue / increment + 0.5) * increment

				SliderSettings.CurrentValue = newValue
				local percent = (newValue - min) / (max - min)

				TweenService:Create(sliderProgress, TweenInfo.new(0.2), {Size = UDim2.new(percent, 0, 1, 0)}):Play()
				sliderValue.Text = tostring(newValue) .. (SliderSettings.Suffix or "")

				local success, err = pcall(function()
					if SliderSettings.Callback then
						SliderSettings.Callback(newValue)
					end
				end)
				if not success then warn("ExodusHub | Slider callback error: " .. tostring(err)) end

				if SliderSettings.Flag then
					SaveConfiguration()
				end
			end

			local dragging = false

			sliderInteract.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					dragging = true
					TweenService:Create(barStroke, TweenInfo.new(0.2), {Transparency = 0}):Play()
				end
			end)

			UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					dragging = false
					TweenService:Create(barStroke, TweenInfo.new(0.2), {Transparency = 0.4}):Play()
				end
			end)

			RunService.RenderStepped:Connect(function()
				if dragging then
					local mousePos = UserInputService:GetMouseLocation().X
					local barPos = sliderBar.AbsolutePosition.X
					local barSize = sliderBar.AbsoluteSize.X
					local percent = math.clamp((mousePos - barPos) / barSize, 0, 1)
					local min = SliderSettings.Range[1]
					local max = SliderSettings.Range[2]
					local newValue = min + percent * (max - min)
					updateSlider(newValue)
				end
			end)

			if SliderSettings.CurrentValue then
				updateSlider(SliderSettings.CurrentValue)
			end

			function SliderSettings:Set(value)
				updateSlider(value)
			end

			if SliderSettings.Flag then
				ExodusHub.Flags[SliderSettings.Flag] = SliderSettings
			end

			return SliderSettings
		end

		-- Dropdown
		function Tab:CreateDropdown(DropdownSettings)
			DropdownSettings = DropdownSettings or {}
			DropdownSettings.Type = "Dropdown"
			local Dropdown = createElementBase(DropdownSettings.Name or "Dropdown", 45)

			local selectedText = Instance.new("TextLabel")
			selectedText.Name = "Selected"
			selectedText.Parent = Dropdown
			selectedText.BackgroundTransparency = 1
			selectedText.Size = UDim2.new(0, 150, 0, 20)
			selectedText.Position = UDim2.new(1, -165, 0, 10)
			selectedText.Font = Enum.Font.Gotham
			selectedText.Text = DropdownSettings.CurrentOption and DropdownSettings.CurrentOption[1] or "None"
			selectedText.TextColor3 = SelectedTheme.TextColor
			selectedText.TextSize = 12
			selectedText.TextTransparency = 1
			selectedText.TextXAlignment = Enum.TextXAlignment.Right
			TweenService:Create(selectedText, TweenInfo.new(0.5), {TextTransparency = 0.3}):Play()

			local dropdownArrow = Instance.new("ImageLabel")
			dropdownArrow.Name = "Arrow"
			dropdownArrow.Parent = Dropdown
			dropdownArrow.BackgroundTransparency = 1
			dropdownArrow.Size = UDim2.new(0, 16, 0, 16)
			dropdownArrow.Position = UDim2.new(1, -28, 0.5, -8)
			dropdownArrow.Image = "rbxassetid://4483362458"
			dropdownArrow.ImageColor3 = SelectedTheme.TextColor
			dropdownArrow.ImageTransparency = 0.5

			local dropdownList = Instance.new("Frame")
			dropdownList.Name = "List"
			dropdownList.Parent = Dropdown
			dropdownList.BackgroundColor3 = SelectedTheme.Background
			dropdownList.BorderSizePixel = 0
			dropdownList.Size = UDim2.new(1, 0, 0, 0)
			dropdownList.Position = UDim2.new(0, 0, 1, 5)
			dropdownList.Visible = false
			dropdownList.ZIndex = 10

			local listCorner = Instance.new("UICorner")
			listCorner.CornerRadius = UDim.new(0, 8)
			listCorner.Parent = dropdownList

			local listStroke = Instance.new("UIStroke")
			listStroke.Parent = dropdownList
			listStroke.Color = SelectedTheme.ElementStroke
			listStroke.Thickness = 1

			local listLayout = Instance.new("UIListLayout")
			listLayout.Parent = dropdownList
			listLayout.SortOrder = Enum.SortOrder.LayoutOrder
			listLayout.Padding = UDim.new(0, 2)

			local listPadding = Instance.new("UIPadding")
			listPadding.Parent = dropdownList
			listPadding.PaddingTop = UDim.new(0, 5)
			listPadding.PaddingBottom = UDim.new(0, 5)
			listPadding.PaddingLeft = UDim.new(0, 5)
			listPadding.PaddingRight = UDim.new(0, 5)

			local dropdownOpen = false

			local function refreshOptions()
				for _, child in ipairs(dropdownList:GetChildren()) do
					if child:IsA("TextButton") then
						child:Destroy()
					end
				end

				for _, option in ipairs(DropdownSettings.Options or {}) do
					local optBtn = Instance.new("TextButton")
					optBtn.Name = option
					optBtn.Parent = dropdownList
					optBtn.BackgroundColor3 = SelectedTheme.DropdownUnselected
					optBtn.BorderSizePixel = 0
					optBtn.Size = UDim2.new(1, 0, 0, 28)
					optBtn.Font = Enum.Font.Gotham
					optBtn.Text = option
					optBtn.TextColor3 = SelectedTheme.TextColor
					optBtn.TextSize = 12
					optBtn.ZIndex = 11

					local optCorner = Instance.new("UICorner")
					optCorner.CornerRadius = UDim.new(0, 6)
					optCorner.Parent = optBtn

					optBtn.MouseEnter:Connect(function()
						TweenService:Create(optBtn, TweenInfo.new(0.2), {BackgroundColor3 = SelectedTheme.DropdownSelected}):Play()
					end)

					optBtn.MouseLeave:Connect(function()
						if not (DropdownSettings.CurrentOption and table.find(DropdownSettings.CurrentOption, option)) then
							TweenService:Create(optBtn, TweenInfo.new(0.2), {BackgroundColor3 = SelectedTheme.DropdownUnselected}):Play()
						end
					end)

					optBtn.MouseButton1Click:Connect(function()
						if DropdownSettings.MultipleOptions then
							if not DropdownSettings.CurrentOption then
								DropdownSettings.CurrentOption = {}
							end
							if table.find(DropdownSettings.CurrentOption, option) then
								table.remove(DropdownSettings.CurrentOption, table.find(DropdownSettings.CurrentOption, option))
								TweenService:Create(optBtn, TweenInfo.new(0.2), {BackgroundColor3 = SelectedTheme.DropdownUnselected}):Play()
							else
								table.insert(DropdownSettings.CurrentOption, option)
								TweenService:Create(optBtn, TweenInfo.new(0.2), {BackgroundColor3 = SelectedTheme.DropdownSelected}):Play()
							end
							if #DropdownSettings.CurrentOption == 0 then
								selectedText.Text = "None"
							elseif #DropdownSettings.CurrentOption == 1 then
								selectedText.Text = DropdownSettings.CurrentOption[1]
							else
								selectedText.Text = "Various"
							end
						else
							DropdownSettings.CurrentOption = {option}
							selectedText.Text = option
							for _, btn in ipairs(dropdownList:GetChildren()) do
								if btn:IsA("TextButton") then
									TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = SelectedTheme.DropdownUnselected}):Play()
								end
							end
							TweenService:Create(optBtn, TweenInfo.new(0.2), {BackgroundColor3 = SelectedTheme.DropdownSelected}):Play()

							-- Close dropdown
							dropdownOpen = false
							TweenService:Create(Dropdown, TweenInfo.new(0.3), {Size = UDim2.new(1, -10, 0, 45)}):Play()
							TweenService:Create(dropdownArrow, TweenInfo.new(0.3), {Rotation = 0}):Play()
							task.wait(0.3)
							dropdownList.Visible = false
						end

						local success, err = pcall(function()
							if DropdownSettings.Callback then
								DropdownSettings.Callback(DropdownSettings.CurrentOption)
							end
						end)
						if not success then warn("ExodusHub | Dropdown callback error: " .. tostring(err)) end

						if DropdownSettings.Flag then
							SaveConfiguration()
						end
					end)

					if DropdownSettings.CurrentOption and table.find(DropdownSettings.CurrentOption, option) then
						optBtn.BackgroundColor3 = SelectedTheme.DropdownSelected
					end
				end

				listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
					dropdownList.Size = UDim2.new(1, 0, 0, math.min(listLayout.AbsoluteContentSize.Y + 10, 150))
				end)
			end

			refreshOptions()

			local dropdownInteract = Instance.new("TextButton")
			dropdownInteract.Name = "Interact"
			dropdownInteract.Parent = Dropdown
			dropdownInteract.BackgroundTransparency = 1
			dropdownInteract.Size = UDim2.new(1, 0, 1, 0)
			dropdownInteract.Text = ""

			dropdownInteract.MouseButton1Click:Connect(function()
				dropdownOpen = not dropdownOpen
				if dropdownOpen then
					dropdownList.Visible = true
					TweenService:Create(Dropdown, TweenInfo.new(0.3), {Size = UDim2.new(1, -10, 0, math.min(45 + dropdownList.Size.Y.Offset + 10, 200))}):Play()
					TweenService:Create(dropdownArrow, TweenInfo.new(0.3), {Rotation = 180}):Play()
				else
					TweenService:Create(Dropdown, TweenInfo.new(0.3), {Size = UDim2.new(1, -10, 0, 45)}):Play()
					TweenService:Create(dropdownArrow, TweenInfo.new(0.3), {Rotation = 0}):Play()
					task.wait(0.3)
					dropdownList.Visible = false
				end
			end)

			function DropdownSettings:Set(options)
				DropdownSettings.CurrentOption = options
				if type(options) == "string" then
					DropdownSettings.CurrentOption = {options}
				end
				if DropdownSettings.CurrentOption and #DropdownSettings.CurrentOption > 0 then
					selectedText.Text = DropdownSettings.CurrentOption[1]
				else
					selectedText.Text = "None"
				end
				refreshOptions()
			end

			function DropdownSettings:Refresh(options)
				DropdownSettings.Options = options
				refreshOptions()
			end

			if DropdownSettings.Flag then
				ExodusHub.Flags[DropdownSettings.Flag] = DropdownSettings
			end

			return DropdownSettings
		end

		-- Input
		function Tab:CreateInput(InputSettings)
			InputSettings = InputSettings or {}
			InputSettings.Type = "Input"
			local Input = createElementBase(InputSettings.Name or "Input", 40)

			local inputBox = Instance.new("TextBox")
			inputBox.Name = "InputBox"
			inputBox.Parent = Input
			inputBox.BackgroundColor3 = SelectedTheme.InputBackground
			inputBox.BorderSizePixel = 0
			inputBox.Size = UDim2.new(0, 120, 0, 26)
			inputBox.Position = UDim2.new(1, -132, 0.5, -13)
			inputBox.Font = Enum.Font.Gotham
			inputBox.Text = InputSettings.CurrentValue or ""
			inputBox.PlaceholderText = InputSettings.PlaceholderText or "Enter text..."
			inputBox.TextColor3 = SelectedTheme.TextColor
			inputBox.PlaceholderColor3 = SelectedTheme.PlaceholderColor
			inputBox.TextSize = 12
			inputBox.ClearTextOnFocus = false

			local inputCorner = Instance.new("UICorner")
			inputCorner.CornerRadius = UDim.new(0, 6)
			inputCorner.Parent = inputBox

			local inputStroke = Instance.new("UIStroke")
			inputStroke.Parent = inputBox
			inputStroke.Color = SelectedTheme.InputStroke
			inputStroke.Thickness = 1

			inputBox.Focused:Connect(function()
				TweenService:Create(inputStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(0, 150, 255)}):Play()
			end)

			inputBox.FocusLost:Connect(function()
				TweenService:Create(inputStroke, TweenInfo.new(0.2), {Color = SelectedTheme.InputStroke}):Play()
				InputSettings.CurrentValue = inputBox.Text

				local success, err = pcall(function()
					if InputSettings.Callback then
						InputSettings.Callback(inputBox.Text)
					end
				end)
				if not success then warn("ExodusHub | Input callback error: " .. tostring(err)) end

				if InputSettings.Flag then
					SaveConfiguration()
				end
			end)

			function InputSettings:Set(text)
				inputBox.Text = text
				InputSettings.CurrentValue = text
			end

			if InputSettings.Flag then
				ExodusHub.Flags[InputSettings.Flag] = InputSettings
			end

			return InputSettings
		end

		-- Keybind
		function Tab:CreateKeybind(KeybindSettings)
			KeybindSettings = KeybindSettings or {}
			KeybindSettings.Type = "Keybind"
			local Keybind = createElementBase(KeybindSettings.Name or "Keybind", 40)

			local keyBox = Instance.new("TextButton")
			keyBox.Name = "KeyBox"
			keyBox.Parent = Keybind
			keyBox.BackgroundColor3 = SelectedTheme.InputBackground
			keyBox.BorderSizePixel = 0
			keyBox.Size = UDim2.new(0, 60, 0, 26)
			keyBox.Position = UDim2.new(1, -72, 0.5, -13)
			keyBox.Font = Enum.Font.GothamBold
			keyBox.Text = KeybindSettings.CurrentKeybind or "None"
			keyBox.TextColor3 = SelectedTheme.TextColor
			keyBox.TextSize = 11

			local keyCorner = Instance.new("UICorner")
			keyCorner.CornerRadius = UDim.new(0, 6)
			keyCorner.Parent = keyBox

			local keyStroke = Instance.new("UIStroke")
			keyStroke.Parent = keyBox
			keyStroke.Color = SelectedTheme.InputStroke
			keyStroke.Thickness = 1

			local listening = false

			keyBox.MouseButton1Click:Connect(function()
				listening = true
				keyBox.Text = "..."
				TweenService:Create(keyStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(0, 150, 255)}):Play()
			end)

			UserInputService.InputBegan:Connect(function(input, processed)
				if listening and input.KeyCode ~= Enum.KeyCode.Unknown then
					listening = false
					local keyName = tostring(input.KeyCode):gsub("Enum.KeyCode.", "")
					keyBox.Text = keyName
					KeybindSettings.CurrentKeybind = keyName
					TweenService:Create(keyStroke, TweenInfo.new(0.2), {Color = SelectedTheme.InputStroke}):Play()

					local success, err = pcall(function()
						if KeybindSettings.Callback then
							KeybindSettings.Callback(keyName)
						end
					end)
					if not success then warn("ExodusHub | Keybind callback error: " .. tostring(err)) end

					if KeybindSettings.Flag then
						SaveConfiguration()
					end
				elseif not processed and KeybindSettings.CurrentKeybind and input.KeyCode == Enum.KeyCode[KeybindSettings.CurrentKeybind] then
					if KeybindSettings.HoldToInteract then
						local held = true
						local conn = input.Changed:Connect(function()
							if input.UserInputState == Enum.UserInputState.End then
								held = false
								conn:Disconnect()
							end
						end)

						local loop
						loop = RunService.Stepped:Connect(function()
							if not held then
								local success, err = pcall(function()
									if KeybindSettings.Callback then
										KeybindSettings.Callback(false)
									end
								end)
								loop:Disconnect()
							else
								local success, err = pcall(function()
									if KeybindSettings.Callback then
										KeybindSettings.Callback(true)
									end
								end)
							end
						end)
					else
						local success, err = pcall(function()
							if KeybindSettings.Callback then
								KeybindSettings.Callback()
							end
						end)
						if not success then warn("ExodusHub | Keybind callback error: " .. tostring(err)) end
					end
				end
			end)

			function KeybindSettings:Set(key)
				keyBox.Text = key
				KeybindSettings.CurrentKeybind = key
			end

			if KeybindSettings.Flag then
				ExodusHub.Flags[KeybindSettings.Flag] = KeybindSettings
			end

			return KeybindSettings
		end

		-- ColorPicker
		function Tab:CreateColorPicker(ColorPickerSettings)
			ColorPickerSettings = ColorPickerSettings or {}
			ColorPickerSettings.Type = "ColorPicker"
			local ColorPicker = createElementBase(ColorPickerSettings.Name or "Color Picker", 45)

			local colorDisplay = Instance.new("Frame")
			colorDisplay.Name = "Display"
			colorDisplay.Parent = ColorPicker
			colorDisplay.BackgroundColor3 = ColorPickerSettings.Color or Color3.fromRGB(255, 255, 255)
			colorDisplay.BorderSizePixel = 0
			colorDisplay.Size = UDim2.new(0, 35, 0, 22)
			colorDisplay.Position = UDim2.new(1, -47, 0.5, -11)

			local displayCorner = Instance.new("UICorner")
			displayCorner.CornerRadius = UDim.new(0, 4)
			displayCorner.Parent = colorDisplay

			local displayStroke = Instance.new("UIStroke")
			displayStroke.Parent = colorDisplay
			displayStroke.Color = SelectedTheme.ElementStroke
			displayStroke.Thickness = 1

			local pickerOpen = false
			local pickerFrame = Instance.new("Frame")
			pickerFrame.Name = "Picker"
			pickerFrame.Parent = ColorPicker
			pickerFrame.BackgroundColor3 = SelectedTheme.Background
			pickerFrame.BorderSizePixel = 0
			pickerFrame.Size = UDim2.new(1, 0, 0, 0)
			pickerFrame.Position = UDim2.new(0, 0, 1, 5)
			pickerFrame.Visible = false
			pickerFrame.ZIndex = 10

			local pickerCorner = Instance.new("UICorner")
			pickerCorner.CornerRadius = UDim.new(0, 8)
			pickerCorner.Parent = pickerFrame

			local pickerStroke = Instance.new("UIStroke")
			pickerStroke.Parent = pickerFrame
			pickerStroke.Color = SelectedTheme.ElementStroke
			pickerStroke.Thickness = 1

			local hueSlider = Instance.new("Frame")
			hueSlider.Name = "Hue"
			hueSlider.Parent = pickerFrame
			hueSlider.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
			hueSlider.BorderSizePixel = 0
			hueSlider.Size = UDim2.new(1, -20, 0, 12)
			hueSlider.Position = UDim2.new(0, 10, 0, 10)

			local hueGradient = Instance.new("UIGradient")
			hueGradient.Parent = hueSlider
			hueGradient.Color = ColorSequence.new{
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
				ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255, 255, 0)),
				ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0, 255, 0)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
				ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0, 0, 255)),
				ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255, 0, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
			}

			local hueCorner = Instance.new("UICorner")
			hueCorner.CornerRadius = UDim.new(1, 0)
			hueCorner.Parent = hueSlider

			local hueIndicator = Instance.new("Frame")
			hueIndicator.Name = "Indicator"
			hueIndicator.Parent = hueSlider
			hueIndicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			hueIndicator.BorderSizePixel = 0
			hueIndicator.Size = UDim2.new(0, 8, 0, 8)
			hueIndicator.Position = UDim2.new(0, -4, 0.5, -4)
			hueIndicator.CornerRadius = UDim.new(1, 0)

			local satValFrame = Instance.new("Frame")
			satValFrame.Name = "SatVal"
			satValFrame.Parent = pickerFrame
			satValFrame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
			satValFrame.BorderSizePixel = 0
			satValFrame.Size = UDim2.new(1, -20, 0, 80)
			satValFrame.Position = UDim2.new(0, 10, 0, 30)

			local satValCorner = Instance.new("UICorner")
			satValCorner.CornerRadius = UDim.new(0, 6)
			satValCorner.Parent = satValFrame

			local satGradient = Instance.new("UIGradient")
			satGradient.Parent = satValFrame
			satGradient.Color = ColorSequence.new{
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
			}

			local valOverlay = Instance.new("Frame")
			valOverlay.Name = "ValOverlay"
			valOverlay.Parent = satValFrame
			valOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			valOverlay.BorderSizePixel = 0
			valOverlay.Size = UDim2.new(1, 0, 1, 0)

			local valGradient = Instance.new("UIGradient")
			valGradient.Parent = valOverlay
			valGradient.Rotation = 90
			valGradient.Color = ColorSequence.new{
				ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
			}
			valGradient.Transparency = NumberSequence.new{
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(1, 0)
			}

			local satValIndicator = Instance.new("Frame")
			satValIndicator.Name = "Indicator"
			satValIndicator.Parent = satValFrame
			satValIndicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			satValIndicator.BorderSizePixel = 0
			satValIndicator.Size = UDim2.new(0, 8, 0, 8)
			satValIndicator.Position = UDim2.new(0.5, -4, 0.5, -4)

			local svIndicatorCorner = Instance.new("UICorner")
			svIndicatorCorner.CornerRadius = UDim.new(1, 0)
			svIndicatorCorner.Parent = satValIndicator

			local rgbText = Instance.new("TextLabel")
			rgbText.Name = "RGB"
			rgbText.Parent = pickerFrame
			rgbText.BackgroundTransparency = 1
			rgbText.Size = UDim2.new(1, -20, 0, 16)
			rgbText.Position = UDim2.new(0, 10, 0, 116)
			rgbText.Font = Enum.Font.Gotham
			rgbText.Text = "R: 255  G: 255  B: 255"
			rgbText.TextColor3 = SelectedTheme.TextColor
			rgbText.TextSize = 11

			local h, s, v = 0, 1, 1
			if ColorPickerSettings.Color then
				h, s, v = ColorPickerSettings.Color:ToHSV()
			end

			local function updateColor()
				local color = Color3.fromHSV(h, s, v)
				ColorPickerSettings.Color = color
				colorDisplay.BackgroundColor3 = color
				satValFrame.BackgroundColor3 = Color3.fromHSV(h, 1, 1)

				local r = math.floor(color.R * 255)
				local g = math.floor(color.G * 255)
				local b = math.floor(color.B * 255)
				rgbText.Text = string.format("R: %d  G: %d  B: %d", r, g, b)

				satValIndicator.Position = UDim2.new(s, -4, 1 - v, -4)
				hueIndicator.Position = UDim2.new(h, -4, 0.5, -4)
			end

			updateColor()

			local hueDragging = false
			local satValDragging = false

			hueSlider.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					hueDragging = true
				end
			end)

			satValFrame.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					satValDragging = true
				end
			end)

			UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					hueDragging = false
					satValDragging = false
					if ColorPickerSettings.Flag then
						SaveConfiguration()
					end
				end
			end)

			RunService.RenderStepped:Connect(function()
				if hueDragging then
					local mouseX = UserInputService:GetMouseLocation().X
					local pos = math.clamp((mouseX - hueSlider.AbsolutePosition.X) / hueSlider.AbsoluteSize.X, 0, 1)
					h = pos
					updateColor()
					local success, err = pcall(function()
						if ColorPickerSettings.Callback then
							ColorPickerSettings.Callback(ColorPickerSettings.Color)
						end
					end)
					if not success then warn("ExodusHub | ColorPicker callback error: " .. tostring(err)) end
				end
				if satValDragging then
					local mousePos = UserInputService:GetMouseLocation()
					s = math.clamp((mousePos.X - satValFrame.AbsolutePosition.X) / satValFrame.AbsoluteSize.X, 0, 1)
					v = 1 - math.clamp((mousePos.Y - satValFrame.AbsolutePosition.Y) / satValFrame.AbsoluteSize.Y, 0, 1)
					updateColor()
					local success, err = pcall(function()
						if ColorPickerSettings.Callback then
							ColorPickerSettings.Callback(ColorPickerSettings.Color)
						end
					end)
					if not success then warn("ExodusHub | ColorPicker callback error: " .. tostring(err)) end
				end
			end)

			local pickerInteract = Instance.new("TextButton")
			pickerInteract.Name = "Interact"
			pickerInteract.Parent = ColorPicker
			pickerInteract.BackgroundTransparency = 1
			pickerInteract.Size = UDim2.new(1, 0, 1, 0)
			pickerInteract.Text = ""

			pickerInteract.MouseButton1Click:Connect(function()
				pickerOpen = not pickerOpen
				if pickerOpen then
					pickerFrame.Visible = true
					TweenService:Create(ColorPicker, TweenInfo.new(0.3), {Size = UDim2.new(1, -10, 0, 170)}):Play()
				else
					TweenService:Create(ColorPicker, TweenInfo.new(0.3), {Size = UDim2.new(1, -10, 0, 45)}):Play()
					task.wait(0.3)
					pickerFrame.Visible = false
				end
			end)

			function ColorPickerSettings:Set(color)
				ColorPickerSettings.Color = color
				h, s, v = color:ToHSV()
				updateColor()
			end

			if ColorPickerSettings.Flag then
				ExodusHub.Flags[ColorPickerSettings.Flag] = ColorPickerSettings
			end

			return ColorPickerSettings
		end

		-- Label
		function Tab:CreateLabel(LabelText)
			local Label = Instance.new("Frame")
			Label.Name = LabelText or "Label"
			Label.Parent = TabPage
			Label.BackgroundColor3 = SelectedTheme.SecondaryElementBackground
			Label.BorderSizePixel = 0
			Label.Size = UDim2.new(1, -10, 0, 35)
			Label.BackgroundTransparency = 1

			local labelCorner = Instance.new("UICorner")
			labelCorner.CornerRadius = UDim.new(0, 8)
			labelCorner.Parent = Label

			local labelStroke = Instance.new("UIStroke")
			labelStroke.Parent = Label
			labelStroke.Color = SelectedTheme.SecondaryElementStroke
			labelStroke.Transparency = 1

			local labelText = Instance.new("TextLabel")
			labelText.Name = "Title"
			labelText.Parent = Label
			labelText.BackgroundTransparency = 1
			labelText.Size = UDim2.new(1, -20, 1, 0)
			labelText.Position = UDim2.new(0, 10, 0, 0)
			labelText.Font = Enum.Font.Gotham
			labelText.Text = LabelText or "Label"
			labelText.TextColor3 = SelectedTheme.TextColor
			labelText.TextSize = 13
			labelText.TextTransparency = 1
			labelText.TextWrapped = true

			TweenService:Create(Label, TweenInfo.new(0.5), {BackgroundTransparency = 0.3}):Play()
			TweenService:Create(labelStroke, TweenInfo.new(0.5), {Transparency = 0.7}):Play()
			TweenService:Create(labelText, TweenInfo.new(0.5), {TextTransparency = 0.2}):Play()

			return Label
		end

		-- Paragraph
		function Tab:CreateParagraph(ParagraphSettings)
			ParagraphSettings = ParagraphSettings or {}
			local Paragraph = Instance.new("Frame")
			Paragraph.Name = ParagraphSettings.Title or "Paragraph"
			Paragraph.Parent = TabPage
			Paragraph.BackgroundColor3 = SelectedTheme.SecondaryElementBackground
			Paragraph.BorderSizePixel = 0
			Paragraph.Size = UDim2.new(1, -10, 0, 60)
			Paragraph.BackgroundTransparency = 1

			local paraCorner = Instance.new("UICorner")
			paraCorner.CornerRadius = UDim.new(0, 8)
			paraCorner.Parent = Paragraph

			local paraStroke = Instance.new("UIStroke")
			paraStroke.Parent = Paragraph
			paraStroke.Color = SelectedTheme.SecondaryElementStroke
			paraStroke.Transparency = 1

			local paraTitle = Instance.new("TextLabel")
			paraTitle.Name = "Title"
			paraTitle.Parent = Paragraph
			paraTitle.BackgroundTransparency = 1
			paraTitle.Size = UDim2.new(1, -20, 0, 20)
			paraTitle.Position = UDim2.new(0, 10, 0, 8)
			paraTitle.Font = Enum.Font.GothamBold
			paraTitle.Text = ParagraphSettings.Title or "Title"
			paraTitle.TextColor3 = SelectedTheme.TextColor
			paraTitle.TextSize = 13
			paraTitle.TextTransparency = 1
			paraTitle.TextXAlignment = Enum.TextXAlignment.Left

			local paraContent = Instance.new("TextLabel")
			paraContent.Name = "Content"
			paraContent.Parent = Paragraph
			paraContent.BackgroundTransparency = 1
			paraContent.Size = UDim2.new(1, -20, 0, 30)
			paraContent.Position = UDim2.new(0, 10, 0, 28)
			paraContent.Font = Enum.Font.Gotham
			paraContent.Text = ParagraphSettings.Content or "Content"
			paraContent.TextColor3 = SelectedTheme.TextColor
			paraContent.TextSize = 12
			paraContent.TextTransparency = 1
			paraContent.TextWrapped = true
			paraContent.TextXAlignment = Enum.TextXAlignment.Left

			TweenService:Create(Paragraph, TweenInfo.new(0.5), {BackgroundTransparency = 0.3}):Play()
			TweenService:Create(paraStroke, TweenInfo.new(0.5), {Transparency = 0.7}):Play()
			TweenService:Create(paraTitle, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
			TweenService:Create(paraContent, TweenInfo.new(0.5), {TextTransparency = 0.4}):Play()

			return Paragraph
		end

		-- Section
		function Tab:CreateSection(SectionName)
			local Section = Instance.new("Frame")
			Section.Name = SectionName or "Section"
			Section.Parent = TabPage
			Section.BackgroundTransparency = 1
			Section.Size = UDim2.new(1, -10, 0, 30)

			local sectionText = Instance.new("TextLabel")
			sectionText.Name = "Title"
			sectionText.Parent = Section
			sectionText.BackgroundTransparency = 1
			sectionText.Size = UDim2.new(1, 0, 1, 0)
			sectionText.Font = Enum.Font.GothamBold
			sectionText.Text = SectionName or "Section"
			sectionText.TextColor3 = SelectedTheme.TextColor
			sectionText.TextSize = 14
			sectionText.TextTransparency = 1
			sectionText.TextXAlignment = Enum.TextXAlignment.Left

			TweenService:Create(sectionText, TweenInfo.new(0.5), {TextTransparency = 0.4}):Play()

			return Section
		end

		-- Divider
		function Tab:CreateDivider()
			local Divider = Instance.new("Frame")
			Divider.Name = "Divider"
			Divider.Parent = TabPage
			Divider.BackgroundTransparency = 1
			Divider.Size = UDim2.new(1, -10, 0, 10)

			local dividerLine = Instance.new("Frame")
			dividerLine.Name = "Line"
			dividerLine.Parent = Divider
			dividerLine.BackgroundColor3 = SelectedTheme.ElementStroke
			dividerLine.BorderSizePixel = 0
			dividerLine.Size = UDim2.new(1, 0, 0, 1)
			dividerLine.Position = UDim2.new(0, 0, 0.5, 0)
			dividerLine.BackgroundTransparency = 1

			TweenService:Create(dividerLine, TweenInfo.new(0.5), {BackgroundTransparency = 0.85}):Play()

			return Divider
		end

		return Tab
	end

	return Window
end

-- Destroy function
function ExodusHub:Destroy()
	exodusDestroyed = true
	if keybindConnection then
		keybindConnection:Disconnect()
	end
	ExodusGui:Destroy()
end

-- Visibility functions
function ExodusHub:SetVisibility(visible)
	if visible then
		Unhide()
	else
		Hide()
	end
end

function ExodusHub:IsVisible()
	return not Hidden
end

-- Set logo function
function ExodusHub:SetLogo(assetId)
	if ToggleImage then
		ToggleImage.Image = "rbxassetid://" .. tostring(assetId)
	end
end

return ExodusHub
