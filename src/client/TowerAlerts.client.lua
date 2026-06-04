--!strict
-- Tower health banners. The server fires TowerAlert when a tower crosses a drama stage;
-- this shows the right message for your side: defend if it is yours, push if it is theirs.
-- Display only.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))
local Sfx = require(Shared:WaitForChild("Sfx"))

local player = Players.LocalPlayer

local TEAM_NAME = { Red = "Red Squad", Blue = "Blue Squad" }

local gui = Instance.new("ScreenGui")
gui.Name = "TowerAlerts"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local banner = Instance.new("TextLabel")
banner.AnchorPoint = Vector2.new(0.5, 0)
banner.Position = UDim2.new(0.5, 0, 0, 142)
banner.Size = UDim2.fromOffset(460, 40)
banner.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
banner.BackgroundTransparency = 0.25
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
local function flash(text: string, color: Color3)
	banner.Text = text
	banner.TextColor3 = color
	banner.Visible = true
	hideToken += 1
	local myToken = hideToken
	task.delay(4, function()
		if hideToken == myToken then
			banner.Visible = false
		end
	end)
end

Remotes.TowerAlert.OnClientEvent:Connect(function(ownerShort: string, stage: number)
	local mine = player.Team ~= nil and player.Team.Name == TEAM_NAME[ownerShort]
	if stage == 1 then
		if mine then
			flash("YOUR TOWER IS AT HALF HEALTH!", Color3.fromRGB(255, 170, 60))
		else
			flash("ENEMY TOWER AT HALF! KEEP GOING!", Color3.fromRGB(120, 255, 150))
		end
		Sfx.play("TowerWarning", 0.6)
	elseif stage == 2 then
		if mine then
			flash("YOUR TOWER IS ALMOST DOWN! DEFEND IT!", Color3.fromRGB(255, 80, 80))
		else
			flash("ENEMY TOWER ALMOST DOWN! PUSH!", Color3.fromRGB(120, 255, 150))
		end
		Sfx.play("TowerCritical", 0.7)
	end
end)
