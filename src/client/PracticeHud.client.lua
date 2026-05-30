--!strict
-- Lobby controls card. Shows the controls for the player's current device (PC, iPad touch,
-- or PlayStation/gamepad) and updates live when they switch input. Display only.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "PracticeHud"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0, 1)
panel.Position = UDim2.new(0, 16, 1, -16)
panel.Size = UDim2.fromOffset(248, 168)
panel.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
panel.BackgroundTransparency = 0.25
panel.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = panel
local pad = Instance.new("UIPadding")
pad.PaddingTop = UDim.new(0, 10)
pad.PaddingBottom = UDim.new(0, 10)
pad.PaddingLeft = UDim.new(0, 12)
pad.PaddingRight = UDim.new(0, 12)
pad.Parent = panel
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 4)
layout.Parent = panel

local function label(heading: boolean): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = UDim2.new(1, 0, 0, heading and 26 or 20)
	l.Font = heading and Enum.Font.GothamBlack or Enum.Font.Gotham
	l.TextColor3 = heading and Color3.fromRGB(255, 230, 90) or Color3.fromRGB(235, 235, 235)
	l.TextScaled = true
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = panel
	return l
end

-- which control scheme to show, by current input device
local function scheme(): { string }
	local last = UserInputService:GetLastInputType()
	if last == Enum.UserInputType.Touch or (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled and last == Enum.UserInputType.None) then
		return { "Move:  left thumbstick", "Aim:  drag", "Shoot:  tap", "Reload:  automatic" }
	elseif last == Enum.UserInputType.Gamepad1 or last == Enum.UserInputType.Gamepad2 or (UserInputService.GamepadEnabled and not UserInputService.KeyboardEnabled and last == Enum.UserInputType.None) then
		return { "Move:  Left Stick", "Aim:  Right Stick", "Shoot:  R2", "Reload:  Square" }
	end
	return { "Move:  W A S D", "Aim:  mouse", "Shoot:  click", "Reload:  R" }
end

local heading = label(true)
heading.Text = "PRACTICE RANGE"
heading.LayoutOrder = 0

local rows: { TextLabel } = {}
local function render()
	local lines = scheme()
	for i, text in ipairs(lines) do
		local row = rows[i]
		if not row then
			row = label(false)
			row.LayoutOrder = i
			rows[i] = row
		end
		row.Text = text
	end
	local splat = rows[#lines + 1]
	if not splat then
		splat = label(false)
		splat.LayoutOrder = 99
		splat.TextColor3 = Color3.fromRGB(120, 210, 255)
		rows[#lines + 1] = splat
	end
	splat.Text = "Splat the targets!"
end

render()
UserInputService.LastInputTypeChanged:Connect(render)
