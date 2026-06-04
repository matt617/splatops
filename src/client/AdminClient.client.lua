--!strict
-- Admin client: flight, the ADMIN badge, and the "give fly" panel. The server owns who may fly
-- (the CanFly attribute) and who is admin (IsAdmin); this script just reads those and drives the
-- controls and UI. Flight follows the humanoid's move direction (so it works on keyboard, touch,
-- and gamepad) plus up/down. Admins get a panel to let one other player fly for 5 minutes.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local player = Players.LocalPlayer
local GOLD = Color3.fromRGB(255, 205, 70)

local function isAdmin(): boolean
	return player:GetAttribute("IsAdmin") == true
end
local function canFly(): boolean
	return player:GetAttribute("CanFly") == true
end

-- ===== UI =====
local gui = Instance.new("ScreenGui")
gui.Name = "AdminHud"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

-- admin badge, top-left
local badge = Instance.new("Frame")
badge.AnchorPoint = Vector2.new(0, 0)
badge.Position = UDim2.fromOffset(16, 16)
badge.Size = UDim2.fromOffset(150, 44)
badge.BackgroundColor3 = Color3.fromRGB(24, 26, 32)
badge.BackgroundTransparency = 0.2
badge.Visible = false
badge.Parent = gui
local badgeCorner = Instance.new("UICorner")
badgeCorner.CornerRadius = UDim.new(0, 10)
badgeCorner.Parent = badge
local badgeStroke = Instance.new("UIStroke")
badgeStroke.Color = GOLD
badgeStroke.Thickness = 2
badgeStroke.Parent = badge

local icon = Instance.new("ImageLabel")
icon.AnchorPoint = Vector2.new(0, 0.5)
icon.Position = UDim2.new(0, 6, 0.5, 0)
icon.Size = UDim2.fromOffset(34, 34)
icon.BackgroundTransparency = 1
icon.Image = Config.Admin.IconId
icon.Visible = Config.Admin.IconId ~= ""
icon.Parent = badge
local iconText = Instance.new("TextLabel") -- star fallback until the icon is uploaded
iconText.AnchorPoint = Vector2.new(0, 0.5)
iconText.Position = UDim2.new(0, 6, 0.5, 0)
iconText.Size = UDim2.fromOffset(34, 34)
iconText.BackgroundTransparency = 1
iconText.Text = "\u{2605}"
iconText.TextColor3 = GOLD
iconText.TextScaled = true
iconText.Font = Enum.Font.GothamBlack
iconText.Visible = Config.Admin.IconId == ""
iconText.Parent = badge

local badgeText = Instance.new("TextLabel")
badgeText.AnchorPoint = Vector2.new(1, 0.5)
badgeText.Position = UDim2.new(1, -10, 0.5, 0)
badgeText.Size = UDim2.fromOffset(96, 38)
badgeText.BackgroundTransparency = 1
badgeText.Text = "ADMIN"
badgeText.TextColor3 = GOLD
badgeText.Font = Enum.Font.GothamBlack
badgeText.TextScaled = true
badgeText.TextXAlignment = Enum.TextXAlignment.Right
badgeText.Parent = badge

-- fly status line under the badge
local flyStatus = Instance.new("TextLabel")
flyStatus.AnchorPoint = Vector2.new(0, 0)
flyStatus.Position = UDim2.fromOffset(16, 66)
flyStatus.Size = UDim2.fromOffset(220, 26)
flyStatus.BackgroundTransparency = 1
flyStatus.Text = ""
flyStatus.TextColor3 = Color3.fromRGB(120, 210, 255)
flyStatus.Font = Enum.Font.GothamBold
flyStatus.TextScaled = true
flyStatus.TextXAlignment = Enum.TextXAlignment.Left
flyStatus.Visible = false
flyStatus.Parent = gui

-- FLY toggle button (bottom-left), shown whenever this player may fly
local flyBtn = Instance.new("TextButton")
flyBtn.AnchorPoint = Vector2.new(0, 1)
flyBtn.Position = UDim2.new(0, 16, 1, -120)
flyBtn.Size = UDim2.fromOffset(96, 60)
flyBtn.BackgroundColor3 = Color3.fromRGB(40, 120, 220)
flyBtn.Text = "FLY"
flyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
flyBtn.Font = Enum.Font.GothamBlack
flyBtn.TextScaled = true
flyBtn.Visible = false
flyBtn.Parent = gui
local flyCorner = Instance.new("UICorner")
flyCorner.CornerRadius = UDim.new(0, 10)
flyCorner.Parent = flyBtn

-- up / down buttons (for touch), shown only while flying
local function makeArrow(text: string, yOff: number): TextButton
	local b = Instance.new("TextButton")
	b.AnchorPoint = Vector2.new(0, 1)
	b.Position = UDim2.new(0, 120, 1, yOff)
	b.Size = UDim2.fromOffset(60, 56)
	b.BackgroundColor3 = Color3.fromRGB(40, 120, 220)
	b.Text = text
	b.TextColor3 = Color3.fromRGB(255, 255, 255)
	b.Font = Enum.Font.GothamBlack
	b.TextScaled = true
	b.Visible = false
	b.Parent = gui
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 10)
	c.Parent = b
	return b
end
local upBtn = makeArrow("\u{25B2}", -124)
local downBtn = makeArrow("\u{25BC}", -62)

-- ===== flight =====
local flying = false
local bodyVel: BodyVelocity? = nil
local touchUp, touchDown = false, false

local function character(): Model?
	return player.Character
end

local function startFly()
	local char = character()
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end
	flying = true
	local bv = Instance.new("BodyVelocity")
	bv.MaxForce = Vector3.new(1, 1, 1) * 1e6
	bv.P = 6000
	bv.Velocity = Vector3.zero
	bv.Parent = hrp
	bodyVel = bv
end

local function stopFly()
	flying = false
	if bodyVel then
		bodyVel:Destroy()
		bodyVel = nil
	end
end

local function toggleFly()
	if flying then
		stopFly()
	elseif canFly() then
		startFly()
	end
end

-- per-frame velocity from input
RunService.RenderStepped:Connect(function()
	if not flying or not bodyVel then
		return
	end
	if not canFly() then -- permission revoked mid-flight
		stopFly()
		return
	end
	local char = character()
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum then
		return
	end
	local speed = Config.Admin.FlySpeed
	local horizontal = hum.MoveDirection * speed -- camera-relative on every device
	local up = 0
	if UserInputService:IsKeyDown(Enum.KeyCode.Space) or touchUp then
		up += 1
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or touchDown then
		up -= 1
	end
	bodyVel.Velocity = Vector3.new(horizontal.X, up * speed, horizontal.Z)
end)

-- ===== input bindings =====
flyBtn.MouseButton1Click:Connect(toggleFly)
upBtn.MouseButton1Down:Connect(function() touchUp = true end)
upBtn.MouseButton1Up:Connect(function() touchUp = false end)
downBtn.MouseButton1Down:Connect(function() touchDown = true end)
downBtn.MouseButton1Up:Connect(function() touchDown = false end)

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then
		return
	end
	if input.KeyCode == Enum.KeyCode.F or input.KeyCode == Enum.KeyCode.ButtonY then
		toggleFly()
	end
end)

-- ===== admin "give fly" panel =====
local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(360, 380)
panel.BackgroundColor3 = Color3.fromRGB(24, 26, 32)
panel.Visible = false
panel.Parent = gui
local pc = Instance.new("UICorner")
pc.CornerRadius = UDim.new(0, 12)
pc.Parent = panel
local pTitle = Instance.new("TextLabel")
pTitle.Position = UDim2.fromScale(0.05, 0.03)
pTitle.Size = UDim2.fromScale(0.9, 0.1)
pTitle.BackgroundTransparency = 1
pTitle.Text = "GIVE FLY (5 min)"
pTitle.TextColor3 = GOLD
pTitle.Font = Enum.Font.GothamBlack
pTitle.TextScaled = true
pTitle.Parent = panel
local pClose = Instance.new("TextButton")
pClose.AnchorPoint = Vector2.new(1, 0)
pClose.Position = UDim2.new(1, -8, 0, 8)
pClose.Size = UDim2.fromOffset(34, 34)
pClose.BackgroundColor3 = Color3.fromRGB(80, 84, 92)
pClose.Text = "X"
pClose.TextColor3 = Color3.fromRGB(255, 255, 255)
pClose.Font = Enum.Font.GothamBlack
pClose.TextScaled = true
pClose.Parent = panel
local pcc = Instance.new("UICorner")
pcc.CornerRadius = UDim.new(0, 8)
pcc.Parent = pClose
local pList = Instance.new("ScrollingFrame")
pList.Position = UDim2.fromScale(0.05, 0.15)
pList.Size = UDim2.fromScale(0.9, 0.82)
pList.BackgroundTransparency = 1
pList.ScrollBarThickness = 6
pList.CanvasSize = UDim2.new()
pList.AutomaticCanvasSize = Enum.AutomaticSize.Y
pList.Parent = panel
local pLayout = Instance.new("UIListLayout")
pLayout.Padding = UDim.new(0, 8)
pLayout.Parent = pList

local function refreshPanel()
	for _, c in pList:GetChildren() do
		if c:IsA("TextButton") then
			c:Destroy()
		end
	end
	for _, other in Players:GetPlayers() do
		if other ~= player and other:GetAttribute("IsAdmin") ~= true then
			local row = Instance.new("TextButton")
			row.Size = UDim2.new(1, 0, 0, 48)
			row.BackgroundColor3 = Color3.fromRGB(40, 120, 220)
			row.Text = other.DisplayName
			row.TextColor3 = Color3.fromRGB(255, 255, 255)
			row.Font = Enum.Font.GothamBold
			row.TextScaled = true
			row.Parent = pList
			local rc = Instance.new("UICorner")
			rc.CornerRadius = UDim.new(0, 8)
			rc.Parent = row
			row.MouseButton1Click:Connect(function()
				Remotes.GrantFly:FireServer(other.Name)
				panel.Visible = false
			end)
		end
	end
end

-- ===== admin power-up buttons (stacked above GIVE FLY, bottom-right) =====
local powerBtns: { TextButton } = {}
do
	local names = {}
	for name in Config.PowerUps.Types do
		table.insert(names, name)
	end
	table.sort(names)
	for i, typeName in ipairs(names) do
		local t = (Config.PowerUps.Types :: any)[typeName]
		local b = Instance.new("TextButton")
		b.AnchorPoint = Vector2.new(1, 1)
		b.Position = UDim2.new(1, -16, 1, -184 - (i - 1) * 52)
		b.Size = UDim2.fromOffset(150, 44)
		b.BackgroundColor3 = t.Color
		b.Text = string.upper(t.DisplayName)
		b.TextColor3 = Color3.fromRGB(20, 20, 24)
		b.Font = Enum.Font.GothamBlack
		b.TextScaled = true
		b.Visible = false
		b.Parent = gui
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 10)
		c.Parent = b
		b.MouseButton1Click:Connect(function()
			Remotes.AdminPowerUp:FireServer(typeName)
		end)
		table.insert(powerBtns, b)
	end
end

-- the GIVE FLY launcher button (admin only), bottom-right
local giveBtn = Instance.new("TextButton")
giveBtn.AnchorPoint = Vector2.new(1, 1)
giveBtn.Position = UDim2.new(1, -16, 1, -120)
giveBtn.Size = UDim2.fromOffset(150, 56)
giveBtn.BackgroundColor3 = Color3.fromRGB(196, 158, 70)
giveBtn.Text = "GIVE FLY"
giveBtn.TextColor3 = Color3.fromRGB(20, 20, 24)
giveBtn.Font = Enum.Font.GothamBlack
giveBtn.TextScaled = true
giveBtn.Visible = false
giveBtn.Parent = gui
local gc = Instance.new("UICorner")
gc.CornerRadius = UDim.new(0, 10)
gc.Parent = giveBtn
giveBtn.MouseButton1Click:Connect(function()
	-- if a grant is active, the button is showing the countdown and does nothing
	if ReplicatedStorage:GetAttribute("FlyGrantee") ~= "" then
		return
	end
	refreshPanel()
	panel.Visible = true
end)
pClose.MouseButton1Click:Connect(function() panel.Visible = false end)

-- ===== refresh loop: badge / buttons / countdowns =====
local function fmt(sec: number): string
	sec = math.max(0, sec)
	return string.format("%d:%02d", sec // 60, sec % 60)
end

RunService.Heartbeat:Connect(function()
	local admin = isAdmin()
	badge.Visible = admin
	giveBtn.Visible = admin
	flyBtn.Visible = canFly()
	upBtn.Visible = flying
	downBtn.Visible = flying
	for _, b in powerBtns do
		b.Visible = admin
	end

	-- admin: show whether a guest is currently flying
	if admin then
		local grantee = ReplicatedStorage:GetAttribute("FlyGrantee")
		local expiry = ReplicatedStorage:GetAttribute("FlyGranteeExpiry") or 0
		if grantee and grantee ~= "" then
			giveBtn.Text = grantee .. "  " .. fmt(expiry - os.time())
			giveBtn.BackgroundColor3 = Color3.fromRGB(90, 94, 102)
		else
			giveBtn.Text = "GIVE FLY"
			giveBtn.BackgroundColor3 = Color3.fromRGB(196, 158, 70)
		end
		flyStatus.Visible = flying
		flyStatus.Text = flying and "FLYING  (F or button to stop)" or ""
	elseif canFly() then
		-- a guest who was granted fly: show their countdown
		local expiry = ReplicatedStorage:GetAttribute("FlyGranteeExpiry") or 0
		flyStatus.Visible = true
		flyStatus.TextColor3 = GOLD
		flyStatus.Text = "FLY ENABLED  " .. fmt(expiry - os.time())
	else
		flyStatus.Visible = false
	end
end)

-- stop flying on respawn (the BodyVelocity lived on the old character)
player.CharacterAdded:Connect(function()
	flying = false
	bodyVel = nil
end)
