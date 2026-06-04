--!strict
-- Power-up announcements: a short top banner when the mid pickup spawns and when
-- someone grabs it. Display only; the server owns everything that matters.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "PowerUpHud"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local banner = Instance.new("TextLabel")
banner.AnchorPoint = Vector2.new(0.5, 0)
banner.Position = UDim2.new(0.5, 0, 0, 96)
banner.Size = UDim2.fromOffset(420, 40)
banner.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
banner.BackgroundTransparency = 0.25
banner.TextColor3 = Color3.fromRGB(255, 200, 40)
banner.Font = Enum.Font.GothamBlack
banner.TextScaled = true
banner.Visible = false
banner.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = banner
local pad = Instance.new("UIPadding")
pad.PaddingLeft = UDim.new(0, 14)
pad.PaddingRight = UDim.new(0, 14)
pad.Parent = banner

local hideToken = 0
local function flash(text: string)
	banner.Text = text
	banner.Visible = true
	hideToken += 1
	local myToken = hideToken
	task.delay(3, function()
		if hideToken == myToken then
			banner.Visible = false
		end
	end)
end

Remotes.PowerUpEvent.OnClientEvent:Connect(function(kind: string, who: string, displayName: string)
	if kind == "spawned" then
		flash(string.upper(displayName) .. " AT MID!")
	elseif kind == "claimed" then
		if who == player.Name then
			flash("YOU GRABBED THE " .. string.upper(displayName) .. "!")
		else
			flash(who .. " grabbed the " .. displayName .. "!")
		end
	end
end)
