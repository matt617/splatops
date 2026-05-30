--!strict
-- Lobby controls card: a quick reference for new players in the practice range.
-- Display only.

local Players = game:GetService("Players")

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "PracticeHud"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0, 1)
panel.Position = UDim2.new(0, 16, 1, -16)
panel.Size = UDim2.fromOffset(232, 158)
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

local function line(text: string, heading: boolean)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = UDim2.new(1, 0, 0, heading and 26 or 20)
	l.Font = heading and Enum.Font.GothamBlack or Enum.Font.Gotham
	l.TextColor3 = heading and Color3.fromRGB(255, 230, 90) or Color3.fromRGB(235, 235, 235)
	l.TextScaled = true
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Text = text
	l.Parent = panel
end

line("PRACTICE RANGE", true)
line("Move:  W A S D")
line("Aim:  mouse / tap")
line("Shoot:  click / tap")
line("Reload:  R")
line("Splat the targets!")
