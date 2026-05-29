--!strict
-- Match HUD: a tower-health readout at the top and a win banner when a tower falls.
-- Display only. The server decides tower health and the winner.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "SplatOpsMatchHud"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

-- tower health readout, top center
local status = Instance.new("TextLabel")
status.Name = "TowerStatus"
status.AnchorPoint = Vector2.new(0.5, 0)
status.Position = UDim2.fromScale(0.5, 0.02)
status.Size = UDim2.fromScale(0.42, 0.05)
status.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
status.BackgroundTransparency = 0.4
status.TextColor3 = Color3.fromRGB(235, 235, 235)
status.Font = Enum.Font.GothamBold
status.TextScaled = true
status.Text = ""
status.Visible = false
status.Parent = gui

local maxHealth: number? = nil
local redHealth: number? = nil
local blueHealth: number? = nil

local function refresh()
	if not maxHealth then
		return
	end
	status.Visible = true
	status.Text = string.format(
		"RED  %d/%d        BLUE  %d/%d",
		redHealth or maxHealth,
		maxHealth,
		blueHealth or maxHealth,
		maxHealth
	)
end

Remotes.TowerDamaged.OnClientEvent:Connect(function(owner: string, health: number, max: number)
	maxHealth = max
	if owner == "Red" then
		redHealth = health
	elseif owner == "Blue" then
		blueHealth = health
	end
	refresh()
end)

-- win banner, center screen
local banner = Instance.new("TextLabel")
banner.Name = "WinBanner"
banner.AnchorPoint = Vector2.new(0.5, 0.5)
banner.Position = UDim2.fromScale(0.5, 0.5)
banner.Size = UDim2.fromScale(0.7, 0.2)
banner.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
banner.BackgroundTransparency = 0.1
banner.TextColor3 = Color3.fromRGB(255, 230, 90)
banner.Font = Enum.Font.GothamBlack
banner.TextScaled = true
banner.Text = ""
banner.Visible = false
banner.ZIndex = 5
banner.Parent = gui

Remotes.MatchEnded.OnClientEvent:Connect(function(winningTeam: string)
	banner.Text = tostring(winningTeam) .. " WINS"
	banner.Visible = true
end)
