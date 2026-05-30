--!strict
-- End-of-match scoreboard. On a round end the server sends the winner, a row per player, and
-- the intermission length. This shows the winner, a sorted table (tags, tagged out, tower hits,
-- coins), stars the MVP, and counts down to the next round. Display only.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))

local player = Players.LocalPlayer

local TEAM_COLOR: { [string]: Color3 } = {
	["Red Squad"] = Color3.fromRGB(196, 72, 72),
	["Blue Squad"] = Color3.fromRGB(72, 116, 206),
}

local gui = Instance.new("ScreenGui")
gui.Name = "SplatOpsStats"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 10
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local dim = Instance.new("Frame")
dim.Size = UDim2.fromScale(1, 1)
dim.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
dim.BackgroundTransparency = 0.4
dim.Parent = gui

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(640, 480)
panel.BackgroundColor3 = Color3.fromRGB(24, 26, 32)
panel.Parent = dim
local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 14)
panelCorner.Parent = panel

local title = Instance.new("TextLabel")
title.Position = UDim2.fromScale(0.04, 0.02)
title.Size = UDim2.fromScale(0.92, 0.13)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBlack
title.TextScaled = true
title.Text = ""
title.Parent = panel

-- column header
local function cell(parent: Instance, x: number, w: number, text: string, color: Color3, bold: boolean, align: Enum.TextXAlignment)
	local t = Instance.new("TextLabel")
	t.Position = UDim2.fromScale(x, 0)
	t.Size = UDim2.fromScale(w, 1)
	t.BackgroundTransparency = 1
	t.Text = text
	t.TextColor3 = color
	t.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
	t.TextScaled = true
	t.TextXAlignment = align
	t.Parent = parent
	return t
end

-- column layout: name | tags | out | tower | coins
local COLS = { name = 0.04, tags = 0.50, out = 0.63, tower = 0.74, coins = 0.88 }
local COLW = { name = 0.46, tags = 0.12, out = 0.10, tower = 0.13, coins = 0.12 }

local header = Instance.new("Frame")
header.Position = UDim2.fromScale(0.04, 0.17)
header.Size = UDim2.fromScale(0.92, 0.07)
header.BackgroundTransparency = 1
header.Parent = panel
local hc = Color3.fromRGB(150, 156, 168)
cell(header, COLS.name - 0.04, COLW.name, "PLAYER", hc, true, Enum.TextXAlignment.Left)
cell(header, COLS.tags - 0.04, COLW.tags, "TAGS", hc, true, Enum.TextXAlignment.Center)
cell(header, COLS.out - 0.04, COLW.out, "OUT", hc, true, Enum.TextXAlignment.Center)
cell(header, COLS.tower - 0.04, COLW.tower, "TOWER", hc, true, Enum.TextXAlignment.Center)
cell(header, COLS.coins - 0.04, COLW.coins, "COINS", hc, true, Enum.TextXAlignment.Center)

local list = Instance.new("Frame")
list.Position = UDim2.fromScale(0.04, 0.25)
list.Size = UDim2.fromScale(0.92, 0.62)
list.BackgroundTransparency = 1
list.Parent = panel
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.Parent = list

local footer = Instance.new("TextLabel")
footer.AnchorPoint = Vector2.new(0.5, 1)
footer.Position = UDim2.new(0.5, 0, 1, -10)
footer.Size = UDim2.fromScale(0.9, 0.07)
footer.BackgroundTransparency = 1
footer.Font = Enum.Font.GothamBold
footer.TextScaled = true
footer.TextColor3 = Color3.fromRGB(210, 210, 215)
footer.Text = ""
footer.Parent = panel

local function clearRows()
	for _, c in list:GetChildren() do
		if c:IsA("Frame") then
			c:Destroy()
		end
	end
end

local function addRow(i: number, data: any, isMvp: boolean)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 40)
	row.LayoutOrder = i
	local tint = TEAM_COLOR[data.team] or Color3.fromRGB(90, 94, 102)
	row.BackgroundColor3 = tint
	row.BackgroundTransparency = 0.55
	row.Parent = list
	local rc = Instance.new("UICorner")
	rc.CornerRadius = UDim.new(0, 6)
	rc.Parent = row

	local nameText = (isMvp and "★ " or "") .. tostring(data.name)
	cell(row, COLS.name, COLW.name, nameText, Color3.fromRGB(245, 245, 245), true, Enum.TextXAlignment.Left)
	cell(row, COLS.tags, COLW.tags, tostring(data.tags), Color3.fromRGB(245, 245, 245), false, Enum.TextXAlignment.Center)
	cell(row, COLS.out, COLW.out, tostring(data.taggedOut), Color3.fromRGB(220, 220, 220), false, Enum.TextXAlignment.Center)
	cell(row, COLS.tower, COLW.tower, tostring(data.towerHits), Color3.fromRGB(220, 220, 220), false, Enum.TextXAlignment.Center)
	cell(row, COLS.coins, COLW.coins, tostring(data.coins), Color3.fromRGB(255, 215, 80), true, Enum.TextXAlignment.Center)
end

local countdownToken = 0

local function show(winner: string, rows: { any }, intermission: number)
	-- winner headline
	if winner == "Draw" then
		title.Text = "DRAW!"
		title.TextColor3 = Color3.fromRGB(235, 235, 235)
	else
		title.Text = string.upper(tostring(winner)) .. " WINS!"
		title.TextColor3 = TEAM_COLOR[winner] or Color3.fromRGB(255, 230, 90)
	end

	-- sort: most tags, then tower hits, then fewest times tagged out
	table.sort(rows, function(a, b)
		if a.tags ~= b.tags then
			return a.tags > b.tags
		end
		if a.towerHits ~= b.towerHits then
			return a.towerHits > b.towerHits
		end
		return a.taggedOut < b.taggedOut
	end)

	clearRows()
	for i, data in ipairs(rows) do
		addRow(i, data, i == 1 and data.tags > 0)
	end

	gui.Enabled = true

	-- local countdown to the next round
	countdownToken += 1
	local mine = countdownToken
	task.spawn(function()
		local left = math.floor(intermission)
		while left > 0 and countdownToken == mine and gui.Enabled do
			footer.Text = "Next round in " .. left .. "…"
			task.wait(1)
			left -= 1
		end
		if countdownToken == mine then
			footer.Text = "Next round starting…"
		end
	end)
end

Remotes.MatchStats.OnClientEvent:Connect(show)

-- a new round (or the lobby return) clears the scoreboard
Remotes.MatchStarting.OnClientEvent:Connect(function()
	countdownToken += 1
	gui.Enabled = false
end)
