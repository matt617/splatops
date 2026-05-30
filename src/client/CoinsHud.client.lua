--!strict
-- Shows the player's coin balance. The server keeps it on the Coins attribute, so this just
-- mirrors that. Spend coins at the quartermaster.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "CoinsHud"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.AnchorPoint = Vector2.new(1, 0)
label.Position = UDim2.new(1, -16, 0, 16)
label.Size = UDim2.fromOffset(150, 38)
label.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
label.BackgroundTransparency = 0.3
label.TextColor3 = Color3.fromRGB(255, 215, 80)
label.Font = Enum.Font.GothamBlack
label.TextScaled = true
label.Text = ""
label.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = label
local pad = Instance.new("UIPadding")
pad.PaddingLeft = UDim.new(0, 10)
pad.PaddingRight = UDim.new(0, 10)
pad.Parent = label

local function show(n: number)
	label.Text = "COINS  " .. tostring(n)
end

show(player:GetAttribute("Coins") :: number? or 0)
player:GetAttributeChangedSignal("Coins"):Connect(function()
	show(player:GetAttribute("Coins") :: number? or 0)
end)
Remotes.CoinsChanged.OnClientEvent:Connect(show)
