--!strict
-- Quartermaster shop UI. Opens when the server says so (kiosk prompt), lists the buyable
-- weapons from Config with their prices, and buys via PurchaseItem. Party servers only.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

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
gui.Name = "QuartermasterUi"
gui.ResetOnSpawn = false
gui.Enabled = false
gui.DisplayOrder = 8
gui.Parent = player:WaitForChild("PlayerGui")

local dim = Instance.new("Frame")
dim.Size = UDim2.fromScale(1, 1)
dim.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
dim.BackgroundTransparency = 0.45
dim.Parent = gui

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(460, 420)
panel.BackgroundColor3 = Color3.fromRGB(24, 26, 32)
panel.Parent = dim
local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 12)
panelCorner.Parent = panel

local title = Instance.new("TextLabel")
title.Position = UDim2.fromScale(0.05, 0.03)
title.Size = UDim2.fromScale(0.7, 0.1)
title.BackgroundTransparency = 1
title.Text = "QUARTERMASTER"
title.TextColor3 = Color3.fromRGB(196, 158, 70)
title.Font = Enum.Font.GothamBlack
title.TextScaled = true
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local closeBtn = Instance.new("TextButton")
closeBtn.AnchorPoint = Vector2.new(1, 0)
closeBtn.Position = UDim2.new(1, -10, 0, 10)
closeBtn.Size = UDim2.fromOffset(40, 40)
closeBtn.BackgroundColor3 = Color3.fromRGB(80, 84, 92)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBlack
closeBtn.TextScaled = true
closeBtn.Parent = panel
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeBtn

local status = Instance.new("TextLabel")
status.AnchorPoint = Vector2.new(0.5, 1)
status.Position = UDim2.new(0.5, 0, 1, -8)
status.Size = UDim2.fromScale(0.9, 0.08)
status.BackgroundTransparency = 1
status.Text = "Spend coins on gear. It lasts the round."
status.TextColor3 = Color3.fromRGB(210, 210, 210)
status.Font = Enum.Font.Gotham
status.TextScaled = true
status.Parent = panel

local list = Instance.new("Frame")
list.Position = UDim2.fromScale(0.05, 0.16)
list.Size = UDim2.fromScale(0.9, 0.7)
list.BackgroundTransparency = 1
list.Parent = panel
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.Parent = list

local busy = false
local function buy(name: string)
	if busy then
		return
	end
	busy = true
	status.Text = "Buying…"
	local ok, res = pcall(function()
		return Remotes.PurchaseItem:InvokeServer(name)
	end)
	status.Text = (ok and res and res.message) or "Could not buy that."
	busy = false
end

-- one row per buyable weapon (Price > 0), cheapest first
local function buildRows()
	local items = {}
	for name, weapon in Config.Weapons do
		if (weapon.Price or 0) > 0 then
			table.insert(items, { name = name, weapon = weapon })
		end
	end
	table.sort(items, function(a, b)
		return a.weapon.Price < b.weapon.Price
	end)

	for i, item in ipairs(items) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 70)
		row.BackgroundColor3 = Color3.fromRGB(34, 37, 45)
		row.LayoutOrder = i
		row.Parent = list
		local rc = Instance.new("UICorner")
		rc.CornerRadius = UDim.new(0, 8)
		rc.Parent = row

		local name = Instance.new("TextLabel")
		name.Position = UDim2.fromScale(0.03, 0.1)
		name.Size = UDim2.fromScale(0.6, 0.45)
		name.BackgroundTransparency = 1
		name.Text = item.weapon.DisplayName
		name.TextColor3 = Color3.fromRGB(245, 245, 245)
		name.Font = Enum.Font.GothamBold
		name.TextScaled = true
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.Parent = row

		local desc = Instance.new("TextLabel")
		desc.Position = UDim2.fromScale(0.03, 0.55)
		desc.Size = UDim2.fromScale(0.6, 0.38)
		desc.BackgroundTransparency = 1
		desc.Text = item.weapon.Description or ""
		desc.TextColor3 = Color3.fromRGB(180, 180, 185)
		desc.Font = Enum.Font.Gotham
		desc.TextScaled = true
		desc.TextXAlignment = Enum.TextXAlignment.Left
		desc.Parent = row

		local buyBtn = Instance.new("TextButton")
		buyBtn.AnchorPoint = Vector2.new(1, 0.5)
		buyBtn.Position = UDim2.new(1, -10, 0.5, 0)
		buyBtn.Size = UDim2.fromOffset(120, 48)
		buyBtn.BackgroundColor3 = Color3.fromRGB(70, 200, 100)
		buyBtn.Text = item.weapon.Price .. " coins"
		buyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		buyBtn.Font = Enum.Font.GothamBold
		buyBtn.TextScaled = true
		buyBtn.Parent = row
		local bc = Instance.new("UICorner")
		bc.CornerRadius = UDim.new(0, 8)
		bc.Parent = buyBtn
		local bpad = Instance.new("UIPadding")
		bpad.PaddingLeft = UDim.new(0, 8)
		bpad.PaddingRight = UDim.new(0, 8)
		bpad.Parent = buyBtn

		buyBtn.MouseButton1Click:Connect(function()
			buy(item.name)
		end)
	end
end
buildRows()

closeBtn.MouseButton1Click:Connect(function()
	gui.Enabled = false
end)

Remotes.OpenShop.OnClientEvent:Connect(function()
	status.Text = "Spend coins on gear. It lasts the round."
	gui.Enabled = true
end)

-- close the shop when a match ends / lobby returns
Remotes.MatchStarting.OnClientEvent:Connect(function(active: boolean)
	if not active then
		gui.Enabled = false
	end
end)
