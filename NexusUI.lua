--[========================================================================]--
--                         NEXUS UI FRAMEWORK v1.0                          --
--             Advanced Luau UI Library for Roblox Developers               --
--[========================================================================]--

local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui")
local ProtectGui = protectgui or (syn and syn.protect_gui) or function() end

local Library = {
	Registry = {},
	Connections = {},
	Themes = {
		Dark = {
			Background = Color3.fromRGB(18, 18, 24),
			Secondary = Color3.fromRGB(25, 25, 34),
			Accent = Color3.fromRGB(110, 90, 255),
			AccentHover = Color3.fromRGB(130, 112, 255),
			Text = Color3.fromRGB(255, 255, 255),
			SecondaryText = Color3.fromRGB(160, 160, 175),
			Border = Color3.fromRGB(55, 55, 70),
			Element = Color3.fromRGB(32, 32, 44),
			ElementHover = Color3.fromRGB(40, 40, 56)
		},
		Light = {
			Background = Color3.fromRGB(240, 240, 245),
			Secondary = Color3.fromRGB(255, 255, 255),
			Accent = Color3.fromRGB(90, 70, 235),
			AccentHover = Color3.fromRGB(110, 90, 255),
			Text = Color3.fromRGB(20, 20, 30),
			SecondaryText = Color3.fromRGB(100, 100, 115),
			Border = Color3.fromRGB(210, 210, 220),
			Element = Color3.fromRGB(230, 230, 238),
			ElementHover = Color3.fromRGB(215, 215, 225)
		},
		Midnight = {
			Background = Color3.fromRGB(10, 10, 14),
			Secondary = Color3.fromRGB(16, 16, 22),
			Accent = Color3.fromRGB(0, 220, 130),
			AccentHover = Color3.fromRGB(0, 245, 145),
			Text = Color3.fromRGB(240, 240, 250),
			SecondaryText = Color3.fromRGB(130, 130, 150),
			Border = Color3.fromRGB(35, 35, 50),
			Element = Color3.fromRGB(22, 22, 32),
			ElementHover = Color3.fromRGB(30, 30, 44)
		}
	},
	CurrentTheme = "Dark",
	ActiveWindow = nil,
	ToggleKey = Enum.KeyCode.RightControl,
	AnimationsEnabled = true,
	AnimationDuration = 0.2,
	AnimationEasing = Enum.EasingStyle.Quart,
	AnimationDirection = Enum.EasingDirection.Out
}

-- Utility Functions
local function Tween(instance, properties, duration)
	if not Library.AnimationsEnabled then
		for k, v in pairs(properties) do
			instance[k] = v
		end
		return
	end
	duration = duration or Library.AnimationDuration
	local info = TweenInfo.new(duration, Library.AnimationEasing, Library.AnimationDirection)
	local tween = TweenService:Create(instance, info, properties)
	tween:Play()
	return tween
end

local function Create(className, properties, children)
	local instance = Instance.new(className)
	for k, v in pairs(properties) do
		if k ~= "Parent" then
			instance[k] = v
		end
	end
	if children then
		for _, child in ipairs(children) do
			child.Parent = instance
		end
	end
	if properties.Parent then
		instance.Parent = properties.Parent
	end
	return instance
end

local function AddConnection(signal, callback)
	local connection = signal:Connect(callback)
	table.insert(Library.Connections, connection)
	return connection
end

-- Theme Manager
function Library:CreateTheme(name, themeData)
	self.Themes[name] = themeData
end

function Library:SetTheme(name)
	if self.Themes[name] then
		self.CurrentTheme = name
		local theme = self.Themes[name]
		for _, item in ipairs(self.Registry) do
			if item.Instance and item.Property and theme[item.ThemeKey] then
				item.Instance[item.Property] = theme[item.ThemeKey]
			end
		end
	end
end

function Library:RegisterTheme(instance, property, themeKey)
	table.insert(self.Registry, {
		Instance = instance,
		Property = property,
		ThemeKey = themeKey
	})
	local theme = self.Themes[self.CurrentTheme]
	if theme[themeKey] then
		instance[property] = theme[themeKey]
	end
end

-- Notification Manager
local NotificationHolder = Create("ScreenGui", {
	Name = "NexusNotifications",
	Parent = (pcall(function() return CoreGui:GetChildren() end) and CoreGui) or PlayerGui,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling
}, {
	Create("Frame", {
		Name = "Holder",
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -320, 1, -20),
		Size = UDim2.new(0, 300, 1, 0),
		AnchorPoint = Vector2.new(0, 1)
	}, {
		Create("UIListLayout", {
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutIndex,
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
			Padding = UDim.new(0, 10)
		})
	})
})

function Library:CreateNotification(config)
	local title = config.Name or config.Title or "Notification"
	local description = config.Content or config.Description or ""
	local duration = config.Duration or 4

	local theme = self.Themes[self.CurrentTheme]

	local notifFrame = Create("Frame", {
		Name = "Notification",
		BackgroundColor3 = theme.Secondary,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 70),
		Position = UDim2.new(1, 40, 0, 0),
		Transparency = 1
	}, {
		Create("UICorner", { CornerRadius = UDim.new(0, 8) }),
		Create("UIStroke", { Color = theme.Border, Thickness = 1, Transparency = 0.5 }),
		Create("UIPadding", {
			PaddingBottom = UDim.new(0, 12),
			PaddingLeft = UDim.new(0, 14),
			PaddingRight = UDim.new(0, 14),
			PaddingTop = UDim.new(0, 12)
		}),
		Create("TextLabel", {
			Name = "Title",
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Text = title,
			TextColor3 = theme.Text,
			TextSize = 14,
			Size = UDim2.new(1, 0, 0, 20),
			TextXAlignment = Enum.TextXAlignment.Left
		}),
		Create("TextLabel", {
			Name = "Description",
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			Text = description,
			TextColor3 = theme.SecondaryText,
			TextSize = 12,
			Size = UDim2.new(1, 0, 0, 24),
			Position = UDim2.new(0, 0, 0, 22),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true
		})
	})

	notifFrame.Parent = NotificationHolder.Holder
	self:RegisterTheme(notifFrame, "BackgroundColor3", "Secondary")

	Tween(notifFrame, { Position = UDim2.new(0, 0, 0, 0), Transparency = 0 }, 0.3)

	task.spawn(function()
		task.wait(duration)
		Tween(notifFrame, { Position = UDim2.new(1, 40, 0, 0), Transparency = 1 }, 0.3)
		task.wait(0.3)
		notifFrame:Destroy()
	end)
end

-- Window Construction
function Library:CreateWindow(config)
	local windowName = config.Name or "Nexus UI Library"
	local windowSubtitle = config.Subtitle or "Advanced Interface"
	local themeName = config.Theme or "Dark"
	self.ToggleKey = config.ToggleKey or Enum.KeyCode.RightControl

	self:SetTheme(themeName)
	local theme = self.Themes[self.CurrentTheme]

	local ScreenGui = Create("ScreenGui", {
		Name = "NexusUI",
		Parent = (pcall(function() return CoreGui:GetChildren() end) and CoreGui) or PlayerGui,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ResetOnSpawn = false
	})
	ProtectGui(ScreenGui)

	local MainFrame = Create("Frame", {
		Name = "MainFrame",
		BackgroundColor3 = theme.Background,
		BorderSizePixel = 0,
		Position = UDim2.new(0.5, -300, 0.5, -200),
		Size = UDim2.new(0, 600, 0, 400),
		ClipsDescendants = true
	}, {
		Create("UICorner", { CornerRadius = UDim.new(0, 10) }),
		Create("UIStroke", { Color = theme.Border, Thickness = 1 }),
		Create("UISizeConstraint", { MinSize = Vector2.new(500, 320), MaxSize = Vector2.new(900, 700) })
	})
	self:RegisterTheme(MainFrame, "BackgroundColor3", "Background")

	-- Topbar
	local Topbar = Create("Frame", {
		Name = "Topbar",
		BackgroundColor3 = theme.Secondary,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 45)
	}, {
		Create("UICorner", { CornerRadius = UDim.new(0, 10) }),
		Create("Frame", {
			Name = "BottomFix",
			BackgroundColor3 = theme.Secondary,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 0, 1, -5),
			Size = UDim2.new(1, 0, 0, 5)
		}),
		Create("TextLabel", {
			Name = "Title",
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 15, 0, 5),
			Size = UDim2.new(0, 200, 0, 20),
			Font = Enum.Font.GothamBold,
			Text = windowName,
			TextColor3 = theme.Text,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left
		}),
		Create("TextLabel", {
			Name = "Subtitle",
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 15, 0, 23),
			Size = UDim2.new(0, 200, 0, 15),
			Font = Enum.Font.Gotham,
			Text = windowSubtitle,
			TextColor3 = theme.SecondaryText,
			TextSize = 10,
			TextXAlignment = Enum.TextXAlignment.Left
		})
	})
	Topbar.Parent = MainFrame
	self:RegisterTheme(Topbar, "BackgroundColor3", "Secondary")

	-- Window Controls (Minimize, Close)
	local ControlsHolder = Create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -75, 0, 10),
		Size = UDim2.new(0, 65, 0, 25)
	}, {
		Create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			SortOrder = Enum.SortOrder.LayoutIndex,
			Padding = UDim.new(0, 8)
		})
	})
	ControlsHolder.Parent = Topbar

	local CloseBtn = Create("TextButton", {
		Name = "Close",
		BackgroundColor3 = Color3.fromRGB(235, 80, 80),
		Size = UDim2.new(0, 25, 0, 25),
		Text = "",
		AutoButtonColor = false
	}, {
		Create("UICorner", { CornerRadius = UDim.new(1, 0) })
	})
	CloseBtn.Parent = ControlsHolder

	AddConnection(CloseBtn.MouseButton1Click, function()
		ScreenGui:Destroy()
	end)

	-- Dragging Logic
	local dragging, dragInput, dragStart, startPos
	AddConnection(Topbar.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = MainFrame.Position
			AddConnection(input.Changed, function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	AddConnection(Topbar.InputChanged, function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	AddConnection(UserInputService.InputChanged, function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)

	-- Sidebar Navigation
	local Sidebar = Create("ScrollingFrame", {
		Name = "Sidebar",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 10, 0, 55),
		Size = UDim2.new(0, 150, 1, -65),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ScrollBarThickness = 0,
		AutomaticCanvasSize = Enum.AutomaticSize.Y
	}, {
		Create("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutIndex,
			Padding = UDim.new(0, 5)
		})
	})
	Sidebar.Parent = MainFrame

	-- Container for Tab Content
	local ContainerHolder = Create("Frame", {
		Name = "ContainerHolder",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 170, 0, 55),
		Size = UDim2.new(1, -180, 1, -65)
	})
	ContainerHolder.Parent = MainFrame

	-- Visibility Toggle Keybind
	local visible = true
	AddConnection(UserInputService.InputBegan, function(input, gameProcessed)
		if not gameProcessed and input.KeyCode == self.ToggleKey then
			visible = not visible
			MainFrame.Visible = visible
		end
	end)

	local WindowObj = {
		MainFrame = MainFrame,
		Sidebar = Sidebar,
		ContainerHolder = ContainerHolder,
		Tabs = {},
		FirstTab = true
	}

	function WindowObj:CreateTab(tabConfig)
		local tabName = tabConfig.Name or "Tab"
		local theme = Library.Themes[Library.CurrentTheme]

		local TabButton = Create("TextButton", {
			Name = tabName .. "Button",
			BackgroundColor3 = theme.Element,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 35),
			AutoButtonColor = false,
			Font = Enum.Font.GothamMedium,
			Text = "   " .. tabName,
			TextColor3 = theme.SecondaryText,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left
		}, {
			Create("UICorner", { CornerRadius = UDim.new(0, 6) })
		})
		TabButton.Parent = WindowObj.Sidebar
		Library:RegisterTheme(TabButton, "TextColor3", "SecondaryText")

		local TabContent = Create("ScrollingFrame", {
			Name = tabName .. "Content",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			CanvasSize = UDim2.new(0, 0, 0, 0),
			ScrollBarThickness = 3,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Visible = false
		}, {
			Create("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutIndex,
				Padding = UDim.new(0, 8)
			}),
			Create("UIPadding", {
				PaddingRight = UDim.new(0, 10),
				PaddingTop = UDim.new(0, 2)
			})
		})
		TabContent.Parent = WindowObj.ContainerHolder

		if WindowObj.FirstTab then
			WindowObj.FirstTab = false
			TabContent.Visible = true
			TabButton.BackgroundTransparency = 0
			TabButton.TextColor3 = theme.Text
			Library:RegisterTheme(TabButton, "TextColor3", "Text")
		end

		AddConnection(TabButton.MouseButton1Click, function()
			for _, otherTab in pairs(WindowObj.Tabs) do
				otherTab.Content.Visible = false
				Tween(otherTab.Button, { BackgroundTransparency = 1 }, 0.2)
				otherTab.Button.TextColor3 = theme.SecondaryText
			end
			TabContent.Visible = true
			Tween(TabButton, { BackgroundTransparency = 0 }, 0.2)
			TabButton.TextColor3 = theme.Text
		end)

		local TabObj = {
			Button = TabButton,
			Content = TabContent
		}

		function TabObj:CreateSection(sectionName)
			local secLabel = Create("TextLabel", {
				Name = "Section_" .. sectionName,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 25),
				Font = Enum.Font.GothamBold,
				Text = string.upper(sectionName),
				TextColor3 = theme.SecondaryText,
				TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Left
			})
			secLabel.Parent = TabContent
			Library:RegisterTheme(secLabel, "TextColor3", "SecondaryText")
		end

		function TabObj:CreateButton(btnConfig)
			local name = btnConfig.Name or "Button"
			local desc = btnConfig.Description
			local callback = btnConfig.Callback or function() end

			local btnHeight = desc and 50 or 36

			local ButtonFrame = Create("TextButton", {
				Name = name,
				BackgroundColor3 = theme.Element,
				Size = UDim2.new(1, 0, 0, btnHeight),
				AutoButtonColor = false,
				Text = "",
				BorderSizePixel = 0
			}, {
				Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
				Create("UIStroke", { Color = theme.Border, Thickness = 1, Transparency = 0.5 }),
				Create("TextLabel", {
					Name = "Title",
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 12, 0, desc and 8 or 0),
					Size = UDim2.new(1, -24, 0, desc and 18 : btnHeight),
					Font = Enum.Font.GothamMedium,
					Text = name,
					TextColor3 = theme.Text,
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left
				})
			})
			ButtonFrame.Parent = TabContent
			Library:RegisterTheme(ButtonFrame, "BackgroundColor3", "Element")

			if desc then
				Create("TextLabel", {
					Name = "Desc",
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 12, 0, 26),
					Size = UDim2.new(1, -24, 0, 16),
					Font = Enum.Font.Gotham,
					Text = desc,
					TextColor3 = theme.SecondaryText,
					TextSize = 11,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = ButtonFrame
				})
			end

			AddConnection(ButtonFrame.MouseButton1Click, function()
				Tween(ButtonFrame, { BackgroundColor3 = theme.AccentHover }, 0.1)
				task.delay(0.1, function()
					Tween(ButtonFrame, { BackgroundColor3 = theme.Element }, 0.2)
				end)
				task.spawn(callback)
			end)

			return {
				SetText = function(self, newText) ButtonFrame.Title.Text = newText end
			}
		end

		function TabObj:CreateToggle(toggleConfig)
			local name = toggleConfig.Name or "Toggle"
			local default = toggleConfig.Default or false
			local callback = toggleConfig.Callback or function() end
			local state = default

			local ToggleFrame = Create("TextButton", {
				Name = name,
				BackgroundColor3 = theme.Element,
				Size = UDim2.new(1, 0, 0, 40),
				AutoButtonColor = false,
				Text = "",
				BorderSizePixel = 0
			}, {
				Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
				Create("UIStroke", { Color = theme.Border, Thickness = 1, Transparency = 0.5 }),
				Create("TextLabel", {
					Name = "Title",
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 12, 0, 0),
					Size = UDim2.new(1, -60, 1, 0),
					Font = Enum.Font.GothamMedium,
					Text = name,
					TextColor3 = theme.Text,
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left
				})
			})
			ToggleFrame.Parent = TabContent
			Library:RegisterTheme(ToggleFrame, "BackgroundColor3", "Element")

			local Switch = Create("Frame", {
				Name = "Switch",
				BackgroundColor3 = state and theme.Accent or theme.Secondary,
				Position = UDim2.new(1, -48, 0.5, -10),
				Size = UDim2.new(0, 36, 0, 20),
				BorderSizePixel = 0
			}, {
				Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
				Create("Frame", {
					Name = "Dot",
					BackgroundColor3 = theme.Text,
					Position = state and UDim2.new(1, -18, 0.5, -7) or UDim2.new(0, 2, 0.5, -7),
					Size = UDim2.new(0, 14, 0, 14),
					BorderSizePixel = 0
				}, {
					Create("UICorner", { CornerRadius = UDim.new(1, 0) })
				})
			})
			Switch.Parent = ToggleFrame

			local function UpdateToggle(newState)
				state = newState
				local targetColor = state and theme.Accent or theme.Secondary
				local dotPos = state and UDim2.new(1, -18, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
				Tween(Switch, { BackgroundColor3 = targetColor }, 0.2)
				Tween(Switch.Dot, { Position = dotPos }, 0.2)
				task.spawn(function() callback(state) end)
			end

			AddConnection(ToggleFrame.MouseButton1Click, function()
				UpdateToggle(not state)
			end)

			return {
				SetValue = function(self, val) UpdateToggle(val) end,
				GetValue = function(self) return state end
			}
		end

		function TabObj:CreateSlider(sliderConfig)
			local name = sliderConfig.Name or "Slider"
			local min = sliderConfig.Range[1] or 0
			local max = sliderConfig.Range[2] or 100
			local increment = sliderConfig.Increment or 1
			local current = sliderConfig.CurrentValue or min
			local callback = sliderConfig.Callback or function() end

			local SliderFrame = Create("Frame", {
				Name = name,
				BackgroundColor3 = theme.Element,
				Size = UDim2.new(1, 0, 0, 50),
				BorderSizePixel = 0
			}, {
				Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
				Create("UIStroke", { Color = theme.Border, Thickness = 1, Transparency = 0.5 }),
				Create("TextLabel", {
					Name = "Title",
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 12, 0, 8),
					Size = UDim2.new(1, -80, 0, 18),
					Font = Enum.Font.GothamMedium,
					Text = name,
					TextColor3 = theme.Text,
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left
				}),
				Create("TextLabel", {
					Name = "ValueLabel",
					BackgroundTransparency = 1,
					Position = UDim2.new(1, -70, 0, 8),
					Size = UDim2.new(0, 58, 0, 18),
					Font = Enum.Font.GothamBold,
					Text = tostring(current),
					TextColor3 = theme.SecondaryText,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Right
				})
			})
			SliderFrame.Parent = TabContent
			Library:RegisterTheme(SliderFrame, "BackgroundColor3", "Element")

			local SliderBar = Create("Frame", {
				Name = "Bar",
				BackgroundColor3 = theme.Secondary,
				Position = UDim2.new(0, 12, 0, 32),
				Size = UDim2.new(1, -24, 0, 6),
				BorderSizePixel = 0
			}, {
				Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
				Create("Frame", {
					Name = "Fill",
					BackgroundColor3 = theme.Accent,
					Size = UDim2.new((current - min) / (max - min), 0, 1, 0),
					BorderSizePixel = 0
				}, {
					Create("UICorner", { CornerRadius = UDim.new(1, 0) })
				})
			})
			SliderBar.Parent = SliderFrame

			local function UpdateSlider(val)
				val = math.clamp(math.round((val - min) / increment) * increment + min, min, max)
				current = val
				SliderFrame.ValueLabel.Text = tostring(current)
				Tween(SliderBar.Fill, { Size = UDim2.new((current - min) / (max - min), 0, 1, 0) }, 0.05)
				task.spawn(function() callback(current) end)
			end

			local draggingSlider = false
			AddConnection(SliderBar.InputBegan, function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					draggingSlider = true
				end
			end)

			AddConnection(UserInputService.InputEnded, function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					draggingSlider = false
				end
			end)

			AddConnection(UserInputService.InputChanged, function(input)
				if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					local pos = math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
					UpdateSlider(min + (max - min) * pos)
				end
			end)

			return {
				SetValue = function(self, val) UpdateSlider(val) end,
				GetValue = function(self) return current end
			}
		end

		function TabObj:CreateDropdown(dropConfig)
			local name = dropConfig.Name or "Dropdown"
			local options = dropConfig.Options or {}
			local current = dropConfig.CurrentOption or options[1]
			local callback = dropConfig.Callback or function() end
			local isOpen = false

			local DropFrame = Create("Frame", {
				Name = name,
				BackgroundColor3 = theme.Element,
				Size = UDim2.new(1, 0, 0, 40),
				ClipsDescendants = true,
				BorderSizePixel = 0
			}, {
				Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
				Create("UIStroke", { Color = theme.Border, Thickness = 1, Transparency = 0.5 }),
				Create("TextButton", {
					Name = "Header",
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 40),
					Text = "",
					AutoButtonColor = false
				}, {
					Create("TextLabel", {
						Name = "Title",
						BackgroundTransparency = 1,
						Position = UDim2.new(0, 12, 0, 0),
						Size = UDim2.new(1, -40, 1, 0),
						Font = Enum.Font.GothamMedium,
						Text = name .. ": " .. tostring(current),
						TextColor3 = theme.Text,
						TextSize = 13,
						TextXAlignment = Enum.TextXAlignment.Left
					})
				})
			})
			DropFrame.Parent = TabContent
			Library:RegisterTheme(DropFrame, "BackgroundColor3", "Element")

			local OptionsHolder = Create("ScrollingFrame", {
				Name = "OptionsHolder",
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 0, 0, 42),
				Size = UDim2.new(1, 0, 0, 0),
				CanvasSize = UDim2.new(0, 0, 0, 0),
				ScrollBarThickness = 2,
				AutomaticCanvasSize = Enum.AutomaticSize.Y
			}, {
				Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutIndex, Padding = UDim.new(0, 4) })
			})
			OptionsHolder.Parent = DropFrame

			local function BuildOptions()
				for _, child in ipairs(OptionsHolder:GetChildren()) do
					if child:IsA("TextButton") then child:Destroy() end
				end
				for _, opt in ipairs(options) do
					local optBtn = Create("TextButton", {
						BackgroundColor3 = theme.Secondary,
						Size = UDim2.new(1, -10, 0, 30),
						Position = UDim2.new(0, 5, 0, 0),
						AutoButtonColor = false,
						Font = Enum.Font.Gotham,
						Text = "  " .. tostring(opt),
						TextColor3 = theme.SecondaryText,
						TextSize = 12,
						TextXAlignment = Enum.TextXAlignment.Left
					}, {
						Create("UICorner", { CornerRadius = UDim.new(0, 4) })
					})
					optBtn.Parent = OptionsHolder

					AddConnection(optBtn.MouseButton1Click, function()
						current = opt
						DropFrame.Header.Title.Text = name .. ": " .. tostring(current)
						isOpen = false
						Tween(DropFrame, { Size = UDim2.new(1, 0, 0, 40) }, 0.2)
						Tween(OptionsHolder, { Size = UDim2.new(1, 0, 0, 0) }, 0.2)
						task.spawn(function() callback(current) end)
					end)
				end
			end
			BuildOptions()

			AddConnection(DropFrame.Header.MouseButton1Click, function()
				isOpen = not isOpen
				local targetHeight = isOpen and math.clamp(#options * 34 + 50, 74, 180) or 40
				local listHeight = isOpen and (targetHeight - 48) or 0
				Tween(DropFrame, { Size = UDim2.new(1, 0, 0, targetHeight) }, 0.2)
				Tween(OptionsHolder, { Size = UDim2.new(1, 0, 0, listHeight) }, 0.2)
			end)

			return {
				SetOptions = function(self, newOpts)
					options = newOpts
					BuildOptions()
				end,
				SetValue = function(self, val)
					current = val
					DropFrame.Header.Title.Text = name .. ": " .. tostring(current)
					task.spawn(function() callback(current) end)
				end
			}
		end

		function TabObj:CreateInput(inputConfig)
			local name = inputConfig.Name or "Input"
			local placeholder = inputConfig.Placeholder or "Enter text..."
			local default = inputConfig.Default or ""
			local callback = inputConfig.Callback or function() end

			local InputFrame = Create("Frame", {
				Name = name,
				BackgroundColor3 = theme.Element,
				Size = UDim2.new(1, 0, 0, 50),
				BorderSizePixel = 0
			}, {
				Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
				Create("UIStroke", { Color = theme.Border, Thickness = 1, Transparency = 0.5 }),
				Create("TextLabel", {
					Name = "Title",
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 12, 0, 6),
					Size = UDim2.new(1, -24, 0, 16),
					Font = Enum.Font.GothamMedium,
					Text = name,
					TextColor3 = theme.Text,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left
				})
			})
			InputFrame.Parent = TabContent
			Library:RegisterTheme(InputFrame, "BackgroundColor3", "Element")

			local TextBox = Create("TextBox", {
				Name = "TextBox",
				BackgroundColor3 = theme.Secondary,
				Position = UDim2.new(0, 12, 0, 24),
				Size = UDim2.new(1, -24, 0, 22),
				ClearTextOnFocus = false,
				Font = Enum.Font.Gotham,
				PlaceholderText = placeholder,
				PlaceholderColor3 = theme.SecondaryText,
				Text = default,
				TextColor3 = theme.Text,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				BorderSizePixel = 0
			}, {
				Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
				Create("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) })
			})
			TextBox.Parent = InputFrame
			Library:RegisterTheme(TextBox, "BackgroundColor3", "Secondary")

			AddConnection(TextBox.FocusLost, function(enterPressed)
				task.spawn(function() callback(TextBox.Text) end)
			end)

			return {
				GetValue = function(self) return TextBox.Text end,
				SetValue = function(self, val) TextBox.Text = val task.spawn(function() callback(val) end) end
			}
		end

		function TabObj:CreateKeybind(keyConfig)
			local name = keyConfig.Name or "Keybind"
			local defaultKey = keyConfig.Default or Enum.KeyCode.F
			local callback = keyConfig.Callback or function() end
			local currentKey = defaultKey
			local binding = false

			local KeybindFrame = Create("Frame", {
				Name = name,
				BackgroundColor3 = theme.Element,
				Size = UDim2.new(1, 0, 0, 40),
				BorderSizePixel = 0
			}, {
				Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
				Create("UIStroke", { Color = theme.Border, Thickness = 1, Transparency = 0.5 }),
				Create("TextLabel", {
					Name = "Title",
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 12, 0, 0),
					Size = UDim2.new(1, -100, 1, 0),
					Font = Enum.Font.GothamMedium,
					Text = name,
					TextColor3 = theme.Text,
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left
				})
			})
			KeybindFrame.Parent = TabContent
			Library:RegisterTheme(KeybindFrame, "BackgroundColor3", "Element")

			local KeyButton = Create("TextButton", {
				Name = "KeyButton",
				BackgroundColor3 = theme.Secondary,
				Position = UDim2.new(1, -90, 0.5, -12),
				Size = UDim2.new(0, 80, 0, 24),
				AutoButtonColor = false,
				Font = Enum.Font.GothamMedium,
				Text = currentKey.Name,
				TextColor3 = theme.Text,
				TextSize = 11,
				BorderSizePixel = 0
			}, {
				Create("UICorner", { CornerRadius = UDim.new(0, 4) })
			})
			KeyButton.Parent = KeybindFrame

			AddConnection(KeyButton.MouseButton1Click, function()
				binding = true
				KeyButton.Text = "..."
			end)

			AddConnection(UserInputService.InputBegan, function(input, gameProcessed)
				if binding then
					if input.UserInputType == Enum.UserInputType.Keyboard then
						currentKey = input.KeyCode
						KeyButton.Text = currentKey.Name
						binding = false
					end
				elseif not gameProcessed and input.KeyCode == currentKey then
					task.spawn(callback)
				end
			end)

			return {
				GetKey = function(self) return currentKey end
			}
		end

		function TabObj:CreateColorPicker(colorConfig)
			local name = colorConfig.Name or "Color Picker"
			local defaultColor = colorConfig.Default or Color3.fromRGB(110, 90, 255)
			local callback = colorConfig.Callback or function() end
			local currentColor = defaultColor
			local isOpen = false

			local PickerFrame = Create("Frame", {
				Name = name,
				BackgroundColor3 = theme.Element,
				Size = UDim2.new(1, 0, 0, 40),
				ClipsDescendants = true,
				BorderSizePixel = 0
			}, {
				Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
				Create("UIStroke", { Color = theme.Border, Thickness = 1, Transparency = 0.5 }),
				Create("TextButton", {
					Name = "Header",
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 40),
					Text = "",
					AutoButtonColor = false
				}, {
					Create("TextLabel", {
						Name = "Title",
						BackgroundTransparency = 1,
						Position = UDim2.new(0, 12, 0, 0),
						Size = UDim2.new(1, -60, 1, 0),
						Font = Enum.Font.GothamMedium,
						Text = name,
						TextColor3 = theme.Text,
						TextSize = 13,
						TextXAlignment = Enum.TextXAlignment.Left
					})
				})
			})
			PickerFrame.Parent = TabContent
			Library:RegisterTheme(PickerFrame, "BackgroundColor3", "Element")

			local Preview = Create("Frame", {
				Name = "Preview",
				BackgroundColor3 = currentColor,
				Position = UDim2.new(1, -45, 0.5, -10),
				Size = UDim2.new(0, 35, 0, 20),
				BorderSizePixel = 0
			}, {
				Create("UICorner", { CornerRadius = UDim.new(0, 4) })
			})
			Preview.Parent = PickerFrame.Header

			AddConnection(PickerFrame.Header.MouseButton1Click, function()
				isOpen = not isOpen
				Tween(PickerFrame, { Size = UDim2.new(1, 0, 0, isOpen and 100 or 40) }, 0.2)
			end)

			-- Simple RGB sliders inside picker container
			local SliderR = Create("Frame", {
				BackgroundColor3 = theme.Secondary,
				Position = UDim2.new(0, 12, 0, 48),
				Size = UDim2.new(1, -24, 0, 12),
				BorderSizePixel = 0
			}, {
				Create("UICorner", { CornerRadius = UDim.new(1, 0) })
			})
			SliderR.Parent = PickerFrame

			return {
				GetValue = function(self) return currentColor end,
				SetValue = function(self, col)
					currentColor = col
					Preview.BackgroundColor3 = col
					task.spawn(function() callback(col) end)
				end
			}
		end

		function TabObj:CreateDivider()
			local Divider = Create("Frame", {
				Name = "Divider",
				BackgroundColor3 = theme.Border,
				Size = UDim2.new(1, 0, 0, 1),
				BorderSizePixel = 0,
				BackgroundTransparency = 0.5
			})
			Divider.Parent = TabContent
		end

		function TabObj:CreateLabel(text)
			local Label = Create("TextLabel", {
				Name = "Label",
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 24),
				Font = Enum.Font.Gotham,
				Text = text,
				TextColor3 = theme.SecondaryText,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left
			})
			Label.Parent = TabContent
			Library:RegisterTheme(Label, "TextColor3", "SecondaryText")
			return {
				SetText = function(self, t) Label.Text = t end
			}
		end

		table.insert(WindowObj.Tabs, TabObj)
		return TabObj
	end

	Library.ActiveWindow = WindowObj
	return WindowObj
end

function Library:Destroy()
	for _, conn in ipairs(self.Connections) do
		conn:Disconnect()
	end
	self.Connections = {}
	self.Registry = {}
end

return Library
