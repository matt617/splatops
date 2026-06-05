--!strict
-- Quartermaster gadgets: every non-weapon shop item from Config.Defenses and Config.Utility.
-- Purchases route here from the quartermaster; deployable placement routes here from the
-- placement tools. All validation and every effect is server-side. The client only renders
-- (double jump input and drone highlights live in GadgetsClient).

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local PaintSplat = require(Shared:WaitForChild("PaintSplat"))
local Economy = require(ServerScriptService:WaitForChild("Economy"))
local Combat = require(ServerScriptService:WaitForChild("Combat"))

local Gadgets = {}

local PLACE_RANGE_STUDS = 35 -- how far from yourself you can drop a deployable
local BASE_ZONE_STUDS = 55 -- "OWN_BASE_ONLY" means within this radius of your base kiosk

-- attributes that hold gadget state on a player; cleared at round transitions
Gadgets.PLAYER_ATTRS = { "SpeedBoostLife", "DoubleJump", "ShieldHits", "ShieldExpiry", "DroneUsedLife" }

local function gadgetConfig(name: string): any
	return (Config.Defenses :: any)[name] or (Config.Utility :: any)[name]
end

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

local function hasTool(player: Player, name: string): boolean
	local backpack = player:FindFirstChildOfClass("Backpack")
	if backpack and backpack:FindFirstChild(name) then
		return true
	end
	return player.Character ~= nil and player.Character:FindFirstChild(name) ~= nil
end

local function deployFolder(): Folder
	local f = Workspace:FindFirstChild("Deployables")
	if not f then
		f = Instance.new("Folder")
		f.Name = "Deployables"
		f.Parent = Workspace
	end
	return f :: Folder
end

-- ============================================================================
-- instant effects
-- ============================================================================

local function applySpeedBoost(player: Player): (boolean, string)
	local g = Config.Utility.SpeedBoost
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return false, "Respawn first."
	end
	player:SetAttribute("SpeedBoostLife", true)
	humanoid.WalkSpeed = Config.Player.WalkSpeed * g.WalkSpeedMultiplier
	return true, "Speed Boost active for this life!"
end

local function applyShield(player: Player): (boolean, string)
	local g = Config.Defenses.PersonalShield
	player:SetAttribute("ShieldHits", g.BlocksHits)
	player:SetAttribute("ShieldExpiry", os.clock() + g.DurationSeconds)
	return true, "Shield up! Blocks the next hit."
end

local function applyDrone(player: Player): (boolean, string)
	local g = Config.Utility.ScoutDrone
	player:SetAttribute("DroneUsedLife", true)
	Remotes.ScoutDrone:FireClient(player, g.RevealDurationSeconds)
	return true, "Drone up! Enemies revealed."
end

-- ============================================================================
-- deployables
-- ============================================================================

local function spawnWall(player: Player, position: Vector3)
	local g = Config.Defenses.DeployableWall
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local facing = Vector3.new(0, 0, 1)
	if root then
		local flat = (position - root.Position) * Vector3.new(1, 0, 1)
		if flat.Magnitude > 0.1 then
			facing = flat.Unit
		end
	end
	-- sit the wall on the ground under the aim point
	local ray = Workspace:Raycast(position + Vector3.new(0, 6, 0), Vector3.new(0, -40, 0))
	local groundY = ray and ray.Position.Y or position.Y

	local wall = Instance.new("Part")
	wall.Name = "PaintWall"
	wall.Size = Vector3.new(8, 6, 1.2)
	wall.Anchored = true
	wall.CastShadow = false
	wall.Color = teamPaint(player)
	wall.Material = Enum.Material.SmoothPlastic
	local center = Vector3.new(position.X, groundY + 3, position.Z)
	wall.CFrame = CFrame.lookAt(center, center + facing)
	wall:SetAttribute("DeployableHealth", g.Health)
	wall:SetAttribute("DeployableTeam", player.Team and player.Team.Name or "")
	wall.Parent = deployFolder()
	Debris:AddItem(wall, g.LifetimeSeconds)
end

-- a turret tags the nearest visible enemy once a second until it dies or expires
local function runTurret(turret: Model, head: BasePart, owner: Player)
	local g = Config.Defenses.AutoTurret
	local color = teamPaint(owner)
	local deadline = os.clock() + g.LifetimeSeconds
	task.spawn(function()
		while turret.Parent and os.clock() < deadline do
			task.wait(1 / math.max(1, g.DamagePerSecond))
			if not turret.Parent then
				break
			end
			-- nearest living enemy in range
			local best: Model? = nil
			local bestDist = g.RangeStuds
			for _, p in Players:GetPlayers() do
				if p ~= owner and p.Team and owner.Team and p.Team ~= owner.Team then
					local char = p.Character
					local hum = char and char:FindFirstChildOfClass("Humanoid")
					local root = char and char:FindFirstChild("HumanoidRootPart")
					if char and hum and root and root:IsA("BasePart") and hum:GetAttribute("TaggedOut") ~= true then
						local dist = (root.Position - head.Position).Magnitude
						if dist < bestDist then
							best = char
							bestDist = dist
						end
					end
				end
			end
			if best then
				local root = best:FindFirstChild("HumanoidRootPart") :: BasePart
				-- only shoot what the turret can actually see
				local rp = RaycastParams.new()
				rp.FilterType = Enum.RaycastFilterType.Exclude
				rp.FilterDescendantsInstances = { turret, owner.Character :: Instance }
				local hit = Workspace:Raycast(head.Position, root.Position - head.Position, rp)
				if hit and hit.Instance:IsDescendantOf(best) then
					head.CFrame = CFrame.lookAt(head.Position, root.Position)
					-- tracer beam for a tenth of a second
					local dist = (root.Position - head.Position).Magnitude
					local beam = Instance.new("Part")
					beam.Anchored = true
					beam.CanCollide = false
					beam.CanQuery = false
					beam.CastShadow = false
					beam.Material = Enum.Material.Neon
					beam.Color = color
					beam.Size = Vector3.new(0.15, 0.15, dist)
					beam.CFrame = CFrame.lookAt(head.Position, root.Position) * CFrame.new(0, 0, -dist / 2)
					beam.Parent = deployFolder()
					Debris:AddItem(beam, 0.1)
					Combat.applyHit(best, hit.Position, hit.Normal, color, owner, 1)
				end
			end
		end
		if turret.Parent then
			turret:Destroy()
		end
	end)
end

local function spawnTurret(player: Player, position: Vector3)
	local g = Config.Defenses.AutoTurret
	local color = teamPaint(player)
	local ray = Workspace:Raycast(position + Vector3.new(0, 6, 0), Vector3.new(0, -40, 0))
	local groundY = ray and ray.Position.Y or position.Y

	local turret = Instance.new("Model")
	turret.Name = "AutoTurret"
	turret:SetAttribute("DeployableHealth", g.Health)
	turret:SetAttribute("DeployableTeam", player.Team and player.Team.Name or "")

	local function part(size: Vector3, cf: CFrame, color3: Color3, material: Enum.Material): BasePart
		local pt = Instance.new("Part")
		pt.Anchored = true
		pt.CastShadow = false
		pt.Size = size
		pt.CFrame = cf
		pt.Color = color3
		pt.Material = material
		pt.Parent = turret
		return pt
	end

	local base = part(Vector3.new(2.4, 0.8, 2.4), CFrame.new(position.X, groundY + 0.4, position.Z), Color3.fromRGB(58, 60, 66), Enum.Material.Metal)
	part(Vector3.new(0.8, 1.6, 0.8), CFrame.new(position.X, groundY + 1.6, position.Z), Color3.fromRGB(90, 94, 102), Enum.Material.Metal)
	local head = part(Vector3.new(1.4, 1, 2), CFrame.new(position.X, groundY + 2.8, position.Z), color, Enum.Material.SmoothPlastic)
	base.CanCollide = true

	turret.WorldPivot = CFrame.new(position.X, groundY + 1.5, position.Z)
	turret.Parent = deployFolder()
	runTurret(turret, head, player)
end

-- own-base check for OWN_BASE_ONLY items
local function nearOwnBase(player: Player, position: Vector3): boolean
	local baseName = nil
	if player.Team then
		baseName = if player.Team.Name == Config.Teams.Red.Name then "RedBase" else "BlueBase"
	end
	if not baseName then
		return false
	end
	local arena = Workspace:FindFirstChild("Arena")
	local base = arena and arena:FindFirstChild(baseName)
	local kiosk = base and base:FindFirstChild("Quartermaster")
	if kiosk and kiosk:IsA("BasePart") then
		return (Vector3.new(position.X, kiosk.Position.Y, position.Z) - kiosk.Position).Magnitude <= BASE_ZONE_STUDS
	end
	return false
end

-- the placement tools call this through PlaceDeployable
function Gadgets.place(player: Player, name: string, position: Vector3): (boolean, string)
	local g = gadgetConfig(name)
	if not g or not g.PlacementZone then
		return false, "That cannot be placed."
	end
	if not hasTool(player, name) then
		return false, "You are not carrying that."
	end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return false, "Respawn first."
	end
	if (position - root.Position).Magnitude > PLACE_RANGE_STUDS then
		return false, "Too far away. Aim closer."
	end
	if g.PlacementZone == "OWN_BASE_ONLY" and not nearOwnBase(player, position) then
		return false, "Turrets only work near your own base."
	end

	if name == "DeployableWall" then
		spawnWall(player, position)
	elseif name == "AutoTurret" then
		spawnTurret(player, position)
	else
		return false, "That cannot be placed."
	end

	-- consume the placement tool
	local backpack = player:FindFirstChildOfClass("Backpack")
	local tool = (player.Character and player.Character:FindFirstChild(name)) or (backpack and backpack:FindFirstChild(name))
	if tool then
		tool:Destroy()
	end
	return true, ""
end

-- ============================================================================
-- purchases (called by the quartermaster)
-- ============================================================================

function Gadgets.purchase(player: Player, name: string): { ok: boolean, message: string }
	local g = gadgetConfig(name)
	if not g or (g.Price or 0) <= 0 then
		return { ok = false, message = "That is not for sale." }
	end

	-- per-gadget "already have it" checks before spending anything
	if name == "SpeedBoost" and player:GetAttribute("SpeedBoostLife") == true then
		return { ok = false, message = "Speed Boost is already active." }
	end
	if name == "DoubleJump" and player:GetAttribute("DoubleJump") == true then
		return { ok = false, message = "You already have Double Jump." }
	end
	if name == "PersonalShield" then
		local hits = (player:GetAttribute("ShieldHits") :: number?) or 0
		local expiry = (player:GetAttribute("ShieldExpiry") :: number?) or 0
		if hits > 0 and expiry > os.clock() then
			return { ok = false, message = "Your shield is already up." }
		end
	end
	if name == "ScoutDrone" and player:GetAttribute("DroneUsedLife") == true then
		return { ok = false, message = "One drone per life. Respawn first." }
	end
	if (name == "DeployableWall" or name == "AutoTurret") and hasTool(player, name) then
		return { ok = false, message = "Place the one you are carrying first." }
	end

	if not Economy.spend(player, g.Price) then
		return { ok = false, message = "Not enough coins." }
	end

	if name == "SpeedBoost" then
		local ok, msg = applySpeedBoost(player)
		return { ok = ok, message = msg }
	elseif name == "DoubleJump" then
		player:SetAttribute("DoubleJump", true)
		return { ok = true, message = "Double Jump unlocked for the match!" }
	elseif name == "PersonalShield" then
		local ok, msg = applyShield(player)
		return { ok = ok, message = msg }
	elseif name == "ScoutDrone" then
		local ok, msg = applyDrone(player)
		return { ok = ok, message = msg }
	else
		-- wall / turret: hand over the placement tool
		local templates = ReplicatedStorage:FindFirstChild("GadgetTemplates")
		local template = templates and templates:FindFirstChild(name)
		if not template then
			Economy.award(player, g.Price) -- refund, the template is missing
			return { ok = false, message = "Out of stock." }
		end
		local backpack = player:FindFirstChildOfClass("Backpack")
		if backpack then
			template:Clone().Parent = backpack
		end
		return { ok = true, message = "Got it! Equip and click where to place it." }
	end
end

-- per-life state resets when the character respawns
local function hookPlayer(player: Player)
	player.CharacterAdded:Connect(function()
		player:SetAttribute("SpeedBoostLife", nil)
		player:SetAttribute("DroneUsedLife", nil)
		player:SetAttribute("ShieldHits", nil)
		player:SetAttribute("ShieldExpiry", nil)
	end)
end
for _, p in Players:GetPlayers() do
	hookPlayer(p)
end
Players.PlayerAdded:Connect(hookPlayer)

return Gadgets
