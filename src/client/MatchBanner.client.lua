--!strict
-- Match HUD: the comms-tower health readout and the match countdown clock at the top of the
-- screen. The end-of-match winner and scoreboard are handled by StatsScreen. Display only;
-- the server owns tower health, the clock, and the result.

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

-- match clock, top center
local clock = Instance.new("TextLabel")
clock.Name = "MatchClock"
clock.AnchorPoint = Vector2.new(0.5, 0)
clock.Position = UDim2.fromScale(0.5, 0.015)
clock.Size = UDim2.fromOffset(120, 34)
clock.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
clock.BackgroundTransparency = 0.4
clock.TextColor3 = Color3.fromRGB(235, 235, 235)
clock.Font = Enum.Font.GothamBlack
clock.TextScaled = true
clock.Text = ""
clock.Visible = false
clock.Parent = gui
local clockCorner = Instance.new("UICorner")
clockCorner.CornerRadius = UDim.new(0, 8)
clockCorner.Parent = clock

-- tower health readout, just below the clock
local status = Instance.new("TextLabel")
status.Name = "TowerStatus"
status.AnchorPoint = Vector2.new(0.5, 0)
status.Position = UDim2.fromScale(0.5, 0.075)
status.Size = UDim2.fromScale(0.42, 0.05)
status.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
status.BackgroundTransparency = 0.4
status.TextColor3 = Color3.fromRGB(235, 235, 235)
status.Font = Enum.Font.GothamBold
status.TextScaled = true
status.Text = ""
status.Visible = false
status.Parent = gui

local redHealth: number?, blueHealth: number?, redMax: number?, blueMax: number? = nil, nil, nil, nil

local function refresh()
	if not redMax and not blueMax then
		return
	end
	status.Visible = true
	status.Text = string.format(
		"RED  %d/%d        BLUE  %d/%d",
		redHealth or redMax or 0,
		redMax or 0,
		blueHealth or blueMax or 0,
		blueMax or 0
	)
end

Remotes.TowerDamaged.OnClientEvent:Connect(function(owner: string, health: number, max: number)
	if owner == "Red" then
		redHealth, redMax = health, max
	elseif owner == "Blue" then
		blueHealth, blueMax = health, max
	end
	refresh()
end)

local function fmt(seconds: number): string
	seconds = math.max(0, seconds)
	return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
end

Remotes.MatchClock.OnClientEvent:Connect(function(remaining: number)
	clock.Visible = true
	clock.Text = fmt(remaining)
	-- last minute turns red as a nudge
	clock.TextColor3 = if remaining <= 60 then Color3.fromRGB(235, 90, 90) else Color3.fromRGB(235, 235, 235)
end)

-- clear the match HUD when the lobby returns so it does not linger; the clock will reappear
-- on the next MatchClock tick when a round starts
Remotes.MatchStarting.OnClientEvent:Connect(function(active: boolean)
	if not active then
		status.Visible = false
		clock.Visible = false
		redHealth, blueHealth, redMax, blueMax = nil, nil, nil, nil
	end
end)
