--!strict
-- Mid-lane power-up. During a match, a glowing pickup spawns where the lanes converge.
-- First player to touch it claims the effect. Server-authoritative: spawn timing, claim
-- validation, and every effect run here. Party servers only.

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local LobbyMode = require(Shared:WaitForChild("LobbyMode"))
if LobbyMode.get() ~= "party" then
	return
end

local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local PaintSplat = require(Shared:WaitForChild("PaintSplat"))
local Combat = require(ServerScriptService:WaitForChild("Combat"))
local Economy = require(ServerScriptService:WaitForChild("Economy"))
local Match = require(ServerScriptService:WaitForChild("Match"))

local CFG = Config.PowerUps
local typeNames = {}
for name in CFG.Types do
	table.insert(typeNames, name)
end
table.sort(typeNames) -- deterministic order, random pick below

local function teamPaint(player: Player?): Color3
	if player and player.Team then
		for _, team in Config.Teams do
			if team.Name == player.Team.Name then
				return team.PaintColor
			end
		end
	end
	return Color3.fromRGB(255, 140, 40)
end

-- ============================================================================
-- effects
-- ============================================================================

local function applyEffect(player: Player, typeName: string)
	local t = (CFG.Types :: any)[typeName]
	if typeName == "GoldenPaintball" then
		player:SetAttribute("BigSplatsUntil", os.clock() + t.DurationSeconds)
	elseif typeName == "SpeedCleats" then
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = Config.Player.WalkSpeed * t.WalkSpeedMultiplier
			task.delay(t.DurationSeconds, function()
				-- only restore if this same humanoid is still around (respawn resets anyway)
				if humanoid.Parent then
					humanoid.WalkSpeed = Config.Player.WalkSpeed
				end
			end)
		end
	elseif typeName == "PaintBomb" then
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			local color = teamPaint(player)
			Combat.splash(root.Position, t.RadiusStuds, t.Damage, color, player)
			PaintSplat.spawn(root.Position - Vector3.new(0, 2.5, 0), Vector3.yAxis, color, 3)
		end
	end
end

-- Golden Paintball pays bonus coins on every tag while active
Combat.Tagged.Event:Connect(function(shooter: Player?, _target: Model, _victim: Player?)
	if shooter and ((shooter:GetAttribute("BigSplatsUntil") :: number?) or 0) > os.clock() then
		Economy.award(shooter, CFG.Types.GoldenPaintball.BonusCoinsPerTag)
	end
end)

-- ============================================================================
-- the pickup itself
-- ============================================================================

local current: BasePart? = nil
local spinConn: RBXScriptConnection? = nil
local spawnToken = 0

local function clearPickup()
	if spinConn then
		spinConn:Disconnect()
		spinConn = nil
	end
	if current then
		current:Destroy()
		current = nil
	end
end

local function groundAtMid(): number
	local ray = Workspace:Raycast(Vector3.new(CFG.SpawnX, 60, CFG.SpawnZ), Vector3.new(0, -120, 0))
	return ray and ray.Position.Y or 0
end

local function spawnPickup()
	clearPickup()
	local typeName = typeNames[math.random(#typeNames)]
	local t = (CFG.Types :: any)[typeName]

	local ball = Instance.new("Part")
	ball.Name = "PowerUp"
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.new(3, 3, 3)
	ball.Anchored = true
	ball.CanCollide = false
	ball.Color = t.Color
	ball.Material = Enum.Material.Neon
	local baseY = groundAtMid() + 4
	ball.Position = Vector3.new(CFG.SpawnX, baseY, CFG.SpawnZ)

	local light = Instance.new("PointLight")
	light.Color = t.Color
	light.Brightness = 2
	light.Range = 18
	light.Parent = ball

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(220, 36)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = ball
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = t.DisplayName
	label.TextColor3 = t.Color
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextStrokeTransparency = 0.4
	label.Parent = billboard

	ball.Parent = Workspace
	current = ball

	-- spin and bob
	local age = 0
	spinConn = RunService.Heartbeat:Connect(function(dt)
		age += dt
		if ball.Parent then
			ball.CFrame = CFrame.new(CFG.SpawnX, baseY + math.sin(age * 2) * 0.6, CFG.SpawnZ) * CFrame.Angles(0, age * 2, 0)
		end
	end)

	local claimed = false
	ball.Touched:Connect(function(hit)
		if claimed or Match.state ~= "Match" then
			return
		end
		local character = hit:FindFirstAncestorOfClass("Model")
		local player = character and Players:GetPlayerFromCharacter(character)
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not player or not humanoid or humanoid:GetAttribute("TaggedOut") == true then
			return
		end
		claimed = true
		applyEffect(player, typeName)
		Remotes.PowerUpEvent:FireAllClients("claimed", player.Name, t.DisplayName)
		clearPickup()
		-- next one, same match only
		local myToken = spawnToken
		task.delay(CFG.RespawnSeconds, function()
			if spawnToken == myToken and Match.state == "Match" then
				spawnPickup()
			end
		end)
	end)

	Remotes.PowerUpEvent:FireAllClients("spawned", "", t.DisplayName)
end

-- follow the match state: spawn during matches, clear in the lobby
local lastState = Match.state
task.spawn(function()
	while true do
		task.wait(1)
		if Match.state ~= lastState then
			lastState = Match.state
			spawnToken += 1
			if Match.state == "Match" then
				local myToken = spawnToken
				task.delay(CFG.FirstSpawnSeconds, function()
					if spawnToken == myToken and Match.state == "Match" then
						spawnPickup()
					end
				end)
			else
				clearPickup()
			end
		end
	end
end)
