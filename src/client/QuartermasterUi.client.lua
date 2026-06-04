--!strict
-- Quartermaster shop UI. Weapon list on the left, a detail pane on the right with the card
-- art, stat bars, and the buy button. Every number comes from Config.Weapons so the cards
-- can never drift from real gameplay values. Party servers only.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Sfx = require(Shared:WaitForChild("Sfx"))

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

-- ============================================================================
-- palette
-- ============================================================================

local C_PANEL = Color3.fromRGB(24, 26, 32)
local C_PANE = Color3.fromRGB(31, 34, 42)
local C_ROW = Color3.fromRGB(38, 42, 52)
local C_ROW_SELECTED = Color3.fromRGB(52, 58, 72)
local C_GOLD = Color3.fromRGB(255, 196, 60)
local C_GOLD_DARK = Color3.fromRGB(196, 158, 70)
local C_TEXT = Color3.fromRGB(245, 245, 245)
local C_TEXT_DIM = Color3.fromRGB(170, 174, 184)
local C_BAR_EMPTY = Color3.fromRGB(52, 56, 66)
local C_BUY = Color3.fromRGB(70, 200, 100)
local C_OWNED = Color3.fromRGB(46, 120, 76)
local C_LOCKED = Color3.fromRGB(70, 74, 84)

-- ============================================================================
-- weapon data, derived from Config
-- ============================================================================

type ShopItem = {
	name: string,
	weapon: any,
}

local items: { ShopItem } = {}
for name, weapon in Config.Weapons do
	table.insert(items, { name = name, weapon = weapon :: any })
end
table.sort(items, function(a, b)
	return (a.weapon.Price or 0) < (b.weapon.Price or 0)
end)

-- raw stat values used for the comparison bars
local function statValues(w: any): { [string]: number }
	return {
		damage = (w.Damage or 1) * (w.PelletsPerShot or 1) + (w.SplashDamage or 0),
		firerate = 1 / (w.FireRateSeconds or 1),
		range = math.sqrt(w.MaxRangeStuds or 0), -- sqrt so the sniper does not flatten everyone else
		ammo = math.sqrt(w.AmmoPerMag or 1),
		reload = 1 / (w.ReloadSeconds or 1),
	}
end

-- per-stat maximum across the lineup, so bars compare weapons fairly
local statMax: { [string]: number } = {}
for _, item in items do
	for key, value in statValues(item.weapon) do
		statMax[key] = math.max(statMax[key] or 0, value)
	end
end

local SEGMENTS = 5
local function pips(key: string, w: any): number
	local value = statValues(w)[key]
	local max = statMax[key] or 1
	return math.clamp(math.round(value / max * SEGMENTS), 1, SEGMENTS)
end

-- the small caption next to each bar, in plain kid words
local function statCaption(key: string, w: any): string
	if key == "damage" then
		if w.PelletsPerShot then
			return w.PelletsPerShot .. " pellets"
		elseif w.SplashDamage then
			return w.Damage .. " + splash"
		end
		return w.Damage .. " per hit"
	elseif key == "firerate" then
		return string.format("%.1f/sec", 1 / (w.FireRateSeconds or 1))
	elseif key == "range" then
		return (w.MaxRangeStuds or 0) .. " studs"
	elseif key == "ammo" then
		return (w.AmmoPerMag or 0) .. " per mag"
	elseif key == "reload" then
		return string.format("%.1fs", w.ReloadSeconds or 0)
	end
	return ""
end

local STAT_ROWS = {
	{ key = "damage", label = "DAMAGE" },
	{ key = "firerate", label = "FIRE RATE" },
	{ key = "range", label = "RANGE" },
	{ key = "ammo", label = "AMMO" },
	{ key = "reload", label = "RELOAD" },
}

local function coins(): number
	return (player:GetAttribute("Coins") :: number?) or 0
end

local function ownsWeapon(name: string): boolean
	local backpack = player:FindFirstChildOfClass("Backpack")
	if backpack and backpack:FindFirstChild(name) then
		return true
	end
	return player.Character ~= nil and player.Character:FindFirstChild(name) ~= nil
end

-- ============================================================================
-- gui scaffolding
-- ============================================================================

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
panel.Size = UDim2.fromOffset(760, 500)
panel.BackgroundColor3 = C_PANEL
panel.Parent = dim
local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 14)
panelCorner.Parent = panel
-- keep the panel on screen on small iPads
local panelScale = Instance.new("UIScale")
panelScale.Parent = panel
local function fitPanel()
	local view = gui.AbsoluteSize
	if view.X <= 0 then
		return
	end
	panelScale.Scale = math.min(1, (view.X - 24) / 760, (view.Y - 24) / 500)
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitPanel)
task.defer(fitPanel)

-- a small gold disc that reads as a coin next to a number
local function coinIcon(parent: Instance, size: number, x: UDim, y: UDim)
	local disc = Instance.new("Frame")
	disc.AnchorPoint = Vector2.new(0, 0.5)
	disc.Position = UDim2.new(x.Scale, x.Offset, y.Scale, y.Offset)
	disc.Size = UDim2.fromOffset(size, size)
	disc.BackgroundColor3 = C_GOLD
	disc.Parent = parent
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(1, 0)
	round.Parent = disc
	local inner = Instance.new("Frame")
	inner.AnchorPoint = Vector2.new(0.5, 0.5)
	inner.Position = UDim2.fromScale(0.5, 0.5)
	inner.Size = UDim2.fromScale(0.6, 0.6)
	inner.BackgroundColor3 = C_GOLD_DARK
	inner.Parent = disc
	local innerRound = Instance.new("UICorner")
	innerRound.CornerRadius = UDim.new(1, 0)
	innerRound.Parent = inner
	return disc
end

-- ===== header =====

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 54)
header.BackgroundTransparency = 1
header.Parent = panel

local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(20, 10)
title.Size = UDim2.fromOffset(320, 34)
title.BackgroundTransparency = 1
title.Text = "QUARTERMASTER"
title.TextColor3 = C_GOLD_DARK
title.Font = Enum.Font.GothamBlack
title.TextScaled = true
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local walletFrame = Instance.new("Frame")
walletFrame.AnchorPoint = Vector2.new(1, 0)
walletFrame.Position = UDim2.new(1, -64, 0, 10)
walletFrame.Size = UDim2.fromOffset(130, 34)
walletFrame.BackgroundColor3 = C_PANE
walletFrame.Parent = header
local walletCorner = Instance.new("UICorner")
walletCorner.CornerRadius = UDim.new(0, 8)
walletCorner.Parent = walletFrame
coinIcon(walletFrame, 18, UDim.new(0, 8), UDim.new(0.5, 0))

local walletLabel = Instance.new("TextLabel")
walletLabel.Position = UDim2.fromOffset(32, 0)
walletLabel.Size = UDim2.new(1, -40, 1, 0)
walletLabel.BackgroundTransparency = 1
walletLabel.Text = "0"
walletLabel.TextColor3 = C_GOLD
walletLabel.Font = Enum.Font.GothamBlack
walletLabel.TextScaled = true
walletLabel.TextXAlignment = Enum.TextXAlignment.Left
walletLabel.Parent = walletFrame

local closeBtn = Instance.new("TextButton")
closeBtn.AnchorPoint = Vector2.new(1, 0)
closeBtn.Position = UDim2.new(1, -12, 0, 10)
closeBtn.Size = UDim2.fromOffset(40, 34)
closeBtn.BackgroundColor3 = C_LOCKED
closeBtn.Text = "X"
closeBtn.TextColor3 = C_TEXT
closeBtn.Font = Enum.Font.GothamBlack
closeBtn.TextScaled = true
closeBtn.Parent = header
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeBtn

-- ===== left: weapon list =====

local listFrame = Instance.new("ScrollingFrame")
listFrame.Position = UDim2.fromOffset(16, 60)
listFrame.Size = UDim2.new(0, 220, 1, -76)
listFrame.BackgroundTransparency = 1
listFrame.BorderSizePixel = 0
listFrame.ScrollBarThickness = 4
listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
listFrame.CanvasSize = UDim2.new()
listFrame.Parent = panel
local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 8)
listLayout.Parent = listFrame

-- ===== right: detail pane =====

local detail = Instance.new("Frame")
detail.Position = UDim2.fromOffset(248, 60)
detail.Size = UDim2.new(1, -264, 1, -76)
detail.BackgroundColor3 = C_PANE
detail.Parent = panel
local detailCorner = Instance.new("UICorner")
detailCorner.CornerRadius = UDim.new(0, 12)
detailCorner.Parent = detail

local art = Instance.new("ImageLabel")
art.Position = UDim2.new(0.5, 0, 0, 10)
art.AnchorPoint = Vector2.new(0.5, 0)
art.Size = UDim2.new(1, -24, 0, 130)
art.BackgroundTransparency = 1
art.ScaleType = Enum.ScaleType.Fit
art.Parent = detail

local nameLabel = Instance.new("TextLabel")
nameLabel.Position = UDim2.fromOffset(18, 146)
nameLabel.Size = UDim2.new(1, -36, 0, 28)
nameLabel.BackgroundTransparency = 1
nameLabel.TextColor3 = C_TEXT
nameLabel.Font = Enum.Font.GothamBlack
nameLabel.TextScaled = true
nameLabel.TextXAlignment = Enum.TextXAlignment.Left
nameLabel.Parent = detail

local descLabel = Instance.new("TextLabel")
descLabel.Position = UDim2.fromOffset(18, 178)
descLabel.Size = UDim2.new(1, -36, 0, 18)
descLabel.BackgroundTransparency = 1
descLabel.TextColor3 = C_TEXT_DIM
descLabel.Font = Enum.Font.Gotham
descLabel.TextScaled = true
descLabel.TextXAlignment = Enum.TextXAlignment.Left
descLabel.Parent = detail

-- stat rows: label, segmented bar, caption
local statBars: { [string]: { segments: { Frame }, caption: TextLabel } } = {}
local statsTop = 204
for i, row in ipairs(STAT_ROWS) do
	local y = statsTop + (i - 1) * 26

	local label = Instance.new("TextLabel")
	label.Position = UDim2.fromOffset(18, y)
	label.Size = UDim2.fromOffset(86, 20)
	label.BackgroundTransparency = 1
	label.Text = row.label
	label.TextColor3 = C_TEXT_DIM
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = detail

	local segments = {}
	for s = 1, SEGMENTS do
		local seg = Instance.new("Frame")
		seg.Position = UDim2.fromOffset(112 + (s - 1) * 36, y + 4)
		seg.Size = UDim2.fromOffset(32, 12)
		seg.BackgroundColor3 = C_BAR_EMPTY
		seg.Parent = detail
		local segCorner = Instance.new("UICorner")
		segCorner.CornerRadius = UDim.new(0, 4)
		segCorner.Parent = seg
		segments[s] = seg
	end

	local caption = Instance.new("TextLabel")
	caption.AnchorPoint = Vector2.new(1, 0)
	caption.Position = UDim2.new(1, -18, 0, y)
	caption.Size = UDim2.fromOffset(110, 20)
	caption.BackgroundTransparency = 1
	caption.TextColor3 = C_TEXT_DIM
	caption.Font = Enum.Font.Gotham
	caption.TextScaled = true
	caption.TextXAlignment = Enum.TextXAlignment.Right
	caption.Parent = detail

	statBars[row.key] = { segments = segments, caption = caption }
end

local buyBtn = Instance.new("TextButton")
buyBtn.AnchorPoint = Vector2.new(0.5, 1)
buyBtn.Position = UDim2.new(0.5, 0, 1, -12)
buyBtn.Size = UDim2.fromOffset(240, 46)
buyBtn.Font = Enum.Font.GothamBlack
buyBtn.TextScaled = true
buyBtn.TextColor3 = C_TEXT
buyBtn.Parent = detail
local buyCorner = Instance.new("UICorner")
buyCorner.CornerRadius = UDim.new(0, 10)
buyCorner.Parent = buyBtn
local buyPad = Instance.new("UIPadding")
buyPad.PaddingLeft = UDim.new(0, 12)
buyPad.PaddingRight = UDim.new(0, 12)
buyPad.PaddingTop = UDim.new(0, 8)
buyPad.PaddingBottom = UDim.new(0, 8)
buyPad.Parent = buyBtn

local status = Instance.new("TextLabel")
status.AnchorPoint = Vector2.new(0.5, 1)
status.Position = UDim2.new(0.5, 0, 1, -66)
status.Size = UDim2.new(0.9, 0, 0, 18)
status.BackgroundTransparency = 1
status.Text = ""
status.TextColor3 = C_GOLD
status.Font = Enum.Font.GothamBold
status.TextScaled = true
status.Parent = detail

-- ============================================================================
-- behavior
-- ============================================================================

local selectedName: string? = nil
local listRows: { [string]: { row: TextButton, tag: TextLabel, stroke: UIStroke } } = {}
local busy = false

local function refreshBuyButton(item: ShopItem)
	local price = item.weapon.Price or 0
	if price <= 0 then
		buyBtn.Text = "STANDARD ISSUE"
		buyBtn.BackgroundColor3 = C_OWNED
		buyBtn.AutoButtonColor = false
	elseif ownsWeapon(item.name) then
		buyBtn.Text = "OWNED"
		buyBtn.BackgroundColor3 = C_OWNED
		buyBtn.AutoButtonColor = false
	elseif coins() >= price then
		buyBtn.Text = "BUY FOR " .. price
		buyBtn.BackgroundColor3 = C_BUY
		buyBtn.AutoButtonColor = true
	else
		buyBtn.Text = "NEED " .. (price - coins()) .. " MORE"
		buyBtn.BackgroundColor3 = C_LOCKED
		buyBtn.AutoButtonColor = false
	end
end

local function refreshListRow(item: ShopItem)
	local entry = listRows[item.name]
	if not entry then
		return
	end
	local price = item.weapon.Price or 0
	if price <= 0 or ownsWeapon(item.name) then
		entry.tag.Text = "OWNED"
		entry.tag.TextColor3 = C_BUY
	else
		entry.tag.Text = price .. " COINS"
		entry.tag.TextColor3 = if coins() >= price then C_GOLD else C_TEXT_DIM
	end
	entry.stroke.Enabled = item.name == selectedName
	entry.row.BackgroundColor3 = if item.name == selectedName then C_ROW_SELECTED else C_ROW
end

local function refresh()
	walletLabel.Text = tostring(coins())
	for _, item in items do
		refreshListRow(item)
		if item.name == selectedName then
			refreshBuyButton(item)
		end
	end
end

local function select(item: ShopItem)
	selectedName = item.name
	local w = item.weapon
	art.Image = w.CardImage or ""
	nameLabel.Text = string.upper(w.DisplayName or item.name)
	descLabel.Text = w.Description or ""
	for _, row in ipairs(STAT_ROWS) do
		local bar = statBars[row.key]
		local filled = pips(row.key, w)
		for s, seg in ipairs(bar.segments) do
			seg.BackgroundColor3 = if s <= filled then C_GOLD else C_BAR_EMPTY
		end
		bar.caption.Text = statCaption(row.key, w)
	end
	status.Text = ""
	refresh()
end

local function buy(item: ShopItem)
	if busy or (item.weapon.Price or 0) <= 0 or ownsWeapon(item.name) then
		return
	end
	if coins() < (item.weapon.Price or 0) then
		status.Text = "Earn coins with tags and tower hits!"
		return
	end
	busy = true
	status.Text = "Buying..."
	local ok, res = pcall(function()
		return Remotes.PurchaseItem:InvokeServer(item.name)
	end)
	status.Text = (ok and res and res.message) or "Could not buy that."
	if ok and res and res.ok then
		Sfx.play("Purchase", 0.6)
	end
	busy = false
	refresh()
end

-- build the list rows once
for i, item in ipairs(items) do
	local row = Instance.new("TextButton")
	row.Size = UDim2.new(1, -8, 0, 58)
	row.BackgroundColor3 = C_ROW
	row.Text = ""
	row.LayoutOrder = i
	row.Parent = listFrame
	local rowCorner = Instance.new("UICorner")
	rowCorner.CornerRadius = UDim.new(0, 10)
	rowCorner.Parent = row
	local stroke = Instance.new("UIStroke")
	stroke.Color = C_GOLD
	stroke.Thickness = 2
	stroke.Enabled = false
	stroke.Parent = row

	local thumb = Instance.new("ImageLabel")
	thumb.Position = UDim2.fromOffset(6, 5)
	thumb.Size = UDim2.fromOffset(48, 48)
	thumb.BackgroundTransparency = 1
	thumb.ScaleType = Enum.ScaleType.Fit
	thumb.Image = item.weapon.CardImage or ""
	thumb.Parent = row

	local rowName = Instance.new("TextLabel")
	rowName.Position = UDim2.fromOffset(60, 8)
	rowName.Size = UDim2.new(1, -68, 0, 22)
	rowName.BackgroundTransparency = 1
	rowName.Text = item.weapon.DisplayName or item.name
	rowName.TextColor3 = C_TEXT
	rowName.Font = Enum.Font.GothamBold
	rowName.TextScaled = true
	rowName.TextXAlignment = Enum.TextXAlignment.Left
	rowName.Parent = row

	local tag = Instance.new("TextLabel")
	tag.Position = UDim2.fromOffset(60, 32)
	tag.Size = UDim2.new(1, -68, 0, 16)
	tag.BackgroundTransparency = 1
	tag.Text = ""
	tag.Font = Enum.Font.GothamBold
	tag.TextScaled = true
	tag.TextXAlignment = Enum.TextXAlignment.Left
	tag.Parent = row

	listRows[item.name] = { row = row, tag = tag, stroke = stroke }
	row.MouseButton1Click:Connect(function()
		select(item)
	end)
end

buyBtn.MouseButton1Click:Connect(function()
	for _, item in items do
		if item.name == selectedName then
			buy(item)
			return
		end
	end
end)

closeBtn.MouseButton1Click:Connect(function()
	gui.Enabled = false
end)

-- keep money and owned states live while the shop is open
player:GetAttributeChangedSignal("Coins"):Connect(refresh)
player.ChildAdded:Connect(function(child)
	if child:IsA("Backpack") then
		child.ChildAdded:Connect(refresh)
	end
end)
local backpack = player:FindFirstChildOfClass("Backpack")
if backpack then
	backpack.ChildAdded:Connect(refresh)
end

-- open on the cheapest unowned weapon so the buy path is one tap
local function defaultSelection(): ShopItem
	for _, item in ipairs(items) do
		if (item.weapon.Price or 0) > 0 and not ownsWeapon(item.name) then
			return item
		end
	end
	return items[1]
end

Remotes.OpenShop.OnClientEvent:Connect(function()
	select(defaultSelection())
	gui.Enabled = true
end)

-- close the shop when a match ends / lobby returns
Remotes.MatchStarting.OnClientEvent:Connect(function(active: boolean)
	if not active then
		gui.Enabled = false
	end
end)

select(items[1])
