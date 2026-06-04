--!strict
-- Lobby Start Match button + a "not enough players, start anyway?" confirm. Party servers
-- only. Hidden during a match.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

-- party servers only (read the server's published role)
local function serverMode(): string
	while not ReplicatedStorage:GetAttribute("ServerMode") do
		task.wait(0.1)
	end
	return ReplicatedStorage:GetAttribute("ServerMode") :: string
end
if serverMode() ~= "party" then
	return
end

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "StartMatchUi"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local startBtn = Instance.new("TextButton")
startBtn.AnchorPoint = Vector2.new(0.5, 1)
-- sits above the backpack hotbar so the weapon slots never cover it
startBtn.Position = UDim2.new(0.5, 0, 1, -130)
startBtn.Size = UDim2.fromOffset(240, 56)
startBtn.BackgroundColor3 = Color3.fromRGB(70, 200, 100)
startBtn.Text = "START MATCH"
startBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
startBtn.Font = Enum.Font.GothamBlack
startBtn.TextScaled = true
startBtn.Parent = gui
local bc = Instance.new("UICorner")
bc.CornerRadius = UDim.new(0, 10)
bc.Parent = startBtn

startBtn.MouseButton1Click:Connect(function()
	Remotes.RequestStart:FireServer(false)
end)

-- confirm dialog (hidden until the server asks)
local dim = Instance.new("Frame")
dim.Size = UDim2.fromScale(1, 1)
dim.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
dim.BackgroundTransparency = 0.5
dim.Visible = false
dim.Parent = gui

local box = Instance.new("Frame")
box.AnchorPoint = Vector2.new(0.5, 0.5)
box.Position = UDim2.fromScale(0.5, 0.5)
box.Size = UDim2.fromOffset(400, 210)
box.BackgroundColor3 = Color3.fromRGB(25, 27, 33)
box.Parent = dim
local boxc = Instance.new("UICorner")
boxc.CornerRadius = UDim.new(0, 12)
boxc.Parent = box

local msg = Instance.new("TextLabel")
msg.Position = UDim2.fromScale(0.06, 0.1)
msg.Size = UDim2.fromScale(0.88, 0.42)
msg.BackgroundTransparency = 1
msg.TextColor3 = Color3.fromRGB(255, 235, 140)
msg.Font = Enum.Font.GothamBold
msg.TextScaled = true
msg.TextWrapped = true
msg.Text = ""
msg.Parent = box

local function dialogButton(anchorRight: boolean, color: Color3, text: string): TextButton
	local b = Instance.new("TextButton")
	b.AnchorPoint = Vector2.new(anchorRight and 1 or 0, 1)
	b.Position = UDim2.new(anchorRight and 0.94 or 0.06, 0, 0.92, 0)
	b.Size = UDim2.fromScale(0.42, 0.28)
	b.BackgroundColor3 = color
	b.Text = text
	b.TextColor3 = Color3.fromRGB(255, 255, 255)
	b.Font = Enum.Font.GothamBlack
	b.TextScaled = true
	b.Parent = box
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = b
	return b
end

local anyway = dialogButton(false, Color3.fromRGB(70, 200, 100), "START ANYWAY")
local wait = dialogButton(true, Color3.fromRGB(80, 84, 92), "WAIT")

Remotes.ConfirmStart.OnClientEvent:Connect(function(count: number, min: number)
	local plural = if count == 1 then "" else "s"
	msg.Text = "Only " .. count .. " player" .. plural .. " here (best with " .. min .. "+). Start anyway?"
	dim.Visible = true
end)
anyway.MouseButton1Click:Connect(function()
	dim.Visible = false
	Remotes.RequestStart:FireServer(true)
end)
wait.MouseButton1Click:Connect(function()
	dim.Visible = false
end)

-- hide the start UI during a match
Remotes.MatchStarting.OnClientEvent:Connect(function(active: boolean)
	startBtn.Visible = not active
	if active then
		dim.Visible = false
	end
end)
