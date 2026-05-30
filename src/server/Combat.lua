--!strict
-- Server-authoritative combat core. Owns hit detection, damage, tag-out, respawn, ammo, and
-- firing for ALL markers: it reads the stats of whatever weapon the player is holding from
-- Config.Weapons (keyed by the Tool's name). Nothing trusts the client beyond aim, and even
-- that is sanity checked. Kept as a module so the test harness can drive it.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local PaintSplat = require(Shared:WaitForChild("PaintSplat"))
local Tower = require(ServerScriptService:WaitForChild("Tower"))
local Projectile = require(ServerScriptService:WaitForChild("Projectile"))
local Economy = require(ServerScriptService:WaitForChild("Economy"))

local Combat = {}

-- fired when a humanoid is tagged out: (shooter?, targetModel, victimPlayer?). Used by the
-- practice counter now and the match scoreboard later.
Combat.Tagged = Instance.new("BindableEvent")

local DEFAULT_WEAPON = Config.Weapons.AssaultMarker -- used by the nil-player test harness
local MAX_HITS = Config.Player.MaxHits

local lastFireByPlayer: { [Player]: number } = {}
local spreadHeat: { [Player]: { value: number, last: number } } = {}

local ORIGIN_TOLERANCE_STUDS = 24

local function teamPaintColor(player: Player?): Color3
	if player and player.Team then
		for _, team in Config.Teams do
			if team.Name == player.Team.Name then
				return team.PaintColor
			end
		end
	end
	return Config.Teams.Red.PaintColor
end

local function sameTeam(a: Player?, b: Player?): boolean
	if not a or not b then
		return false
	end
	if not a.Team or not b.Team then
		return false
	end
	return a.Team == b.Team
end

local function getEquippedTool(player: Player): Tool?
	local character = player.Character
	return character and character:FindFirstChildOfClass("Tool") or nil
end

-- The weapon config for whatever the player holds (or the default for the test harness),
-- plus the tool instance. Returns nil config if they hold no configured weapon.
local function weaponFor(player: Player?): (any, Tool?)
	if not player then
		return DEFAULT_WEAPON, nil
	end
	local tool = getEquippedTool(player)
	if not tool then
		return nil, nil
	end
	return Config.Weapons[tool.Name], tool
end

function Combat.reload(player: Player)
	local weapon, tool = weaponFor(player)
	if not weapon or not tool or tool:GetAttribute("Reloading") == true then
		return
	end
	local ammo = (tool:GetAttribute("Ammo") :: number?) or weapon.AmmoPerMag
	if ammo >= weapon.AmmoPerMag then
		return
	end
	tool:SetAttribute("Reloading", true)
	task.delay(weapon.ReloadSeconds, function()
		if tool.Parent then
			tool:SetAttribute("Ammo", weapon.AmmoPerMag)
		end
		tool:SetAttribute("Reloading", false)
	end)
end

local function getMuzzle(shooterPlayer: Player?, fallback: Vector3): Vector3
	if shooterPlayer and shooterPlayer.Character then
		local character = shooterPlayer.Character
		local tool = character:FindFirstChildOfClass("Tool")
		local handle = tool and tool:FindFirstChild("Handle")
		if handle and handle:IsA("BasePart") then
			return handle.Position
		end
		local root = character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			return root.Position + Vector3.new(0, 1.5, 0)
		end
	end
	return fallback
end

local function applySpread(dir: Vector3, degrees: number?): Vector3
	if not degrees or degrees <= 0 then
		return dir
	end
	local rad = math.rad(degrees)
	local pitch = (math.random() - 0.5) * rad
	local yaw = (math.random() - 0.5) * rad
	return (CFrame.lookAt(Vector3.zero, dir) * CFrame.Angles(pitch, yaw, 0)).LookVector
end

-- Bloom spread for single-shot weapons: base plus accumulated heat that recovers over time.
-- Weapons without the bloom fields just use their flat SpreadDegrees.
local function currentSpread(player: Player?, weapon: any): number
	local base = weapon.SpreadDegrees or 0
	if not player or not weapon.SpreadPerShot then
		return base
	end
	local now = os.clock()
	local heat = spreadHeat[player]
	if not heat then
		heat = { value = 0, last = now }
		spreadHeat[player] = heat
	end
	heat.value = math.max(0, heat.value - (now - heat.last) * (weapon.SpreadRecoverPerSec or 0))
	local spread = base + heat.value
	heat.value = math.min((weapon.SpreadMaxDegrees or base) - base, heat.value + weapon.SpreadPerShot)
	heat.last = now
	return spread
end

function Combat.clearPlayer(player: Player)
	lastFireByPlayer[player] = nil
	spreadHeat[player] = nil
end

local function solveLaunch(p0: Vector3, target: Vector3, speed: number, gravity: number): Vector3?
	if gravity <= 0 then
		return (target - p0).Unit * speed
	end
	local delta = target - p0
	local flat = Vector3.new(delta.X, 0, delta.Z)
	local x = flat.Magnitude
	if x < 0.001 then
		return (target - p0).Unit * speed
	end
	local y = delta.Y
	local s2 = speed * speed
	local a = (gravity * x * x) / (2 * s2)
	local disc = x * x - 4 * a * (y + a)
	if disc < 0 then
		return nil
	end
	local root = math.sqrt(disc)
	local tanLow = math.min((x + root) / (2 * a), (x - root) / (2 * a))
	local theta = math.atan(tanLow)
	return flat.Unit * (speed * math.cos(theta)) + Vector3.new(0, speed * math.sin(theta), 0)
end

function Combat.setupCharacter(character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	humanoid:SetAttribute("Hits", 0)
	humanoid:SetAttribute("TaggedOut", false)
	humanoid.WalkSpeed = Config.Player.WalkSpeed
	humanoid.JumpPower = Config.Player.JumpPower
end

function Combat.tagOut(character: Model, victimPlayer: Player?)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	humanoid:SetAttribute("TaggedOut", true)
	if victimPlayer then
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		humanoid.PlatformStand = true
		Remotes.PlayerTagged:FireClient(victimPlayer)
		task.delay(Config.Player.RespawnSeconds, function()
			if victimPlayer.Parent then
				victimPlayer:LoadCharacter()
			end
		end)
	else
		humanoid.Health = 0
	end
end

-- Apply a marker hit for `damage` points. Returns true if it landed.
function Combat.applyHit(
	targetCharacter: Model,
	hitPosition: Vector3,
	hitNormal: Vector3,
	paintColor: Color3,
	shooterPlayer: Player?,
	damage: number?
): boolean
	local humanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid:GetAttribute("TaggedOut") == true then
		return false
	end
	local victimPlayer = Players:GetPlayerFromCharacter(targetCharacter)
	if not Config.Player.FriendlyFire and sameTeam(shooterPlayer, victimPlayer) then
		return false
	end

	PaintSplat.spawn(hitPosition, hitNormal, paintColor)
	if victimPlayer then
		Remotes.PaintHitVFX:FireClient(victimPlayer, paintColor)
	end
	humanoid:SetAttribute("LastHitBy", if shooterPlayer then shooterPlayer.UserId else 0)

	local hits = ((humanoid:GetAttribute("Hits") :: number?) or 0) + (damage or 1)
	humanoid:SetAttribute("Hits", hits)
	if hits >= MAX_HITS then
		if shooterPlayer then
			Economy.award(shooterPlayer, Config.Economy.CoinsPerTag)
		end
		Combat.Tagged:Fire(shooterPlayer, targetCharacter, victimPlayer)
		Combat.tagOut(targetCharacter, victimPlayer)
	end
	return true
end

-- Area damage around an impact point (used by the mortar's splash).
local function applySplash(center: Vector3, radius: number, damage: number, paintColor: Color3, shooterPlayer: Player?)
	for _, p in Players:GetPlayers() do
		local character = p.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") and (root.Position - center).Magnitude <= radius then
			Combat.applyHit(character, root.Position, Vector3.yAxis, paintColor, shooterPlayer, damage)
		end
	end
	local arena = Workspace:FindFirstChild("Arena")
	if arena then
		for _, baseName in { "RedBase", "BlueBase" } do
			local base = arena:FindFirstChild(baseName)
			local tower = base and base:FindFirstChild("CommsTower")
			if tower and tower:IsA("BasePart") and (tower.Position - center).Magnitude <= radius + 6 then
				Tower.applyDamage(tower, center, Vector3.yAxis, paintColor, shooterPlayer)
			end
		end
	end
end

-- Entry point for a fired shot. shooterPlayer is nil when the test harness drives this.
function Combat.handleFire(shooterPlayer: Player?, origin: Vector3, direction: Vector3)
	if Tower.isMatchOver() then
		return
	end
	local weapon, tool = weaponFor(shooterPlayer)
	if shooterPlayer and not weapon then
		return -- not holding a configured weapon
	end
	weapon = weapon or DEFAULT_WEAPON

	local rayOrigin = origin
	if shooterPlayer then
		local now = os.clock()
		if now - (lastFireByPlayer[shooterPlayer] or 0) < weapon.FireRateSeconds then
			return
		end
		lastFireByPlayer[shooterPlayer] = now

		if tool then
			if tool:GetAttribute("Reloading") == true then
				return
			end
			local ammo = (tool:GetAttribute("Ammo") :: number?) or weapon.AmmoPerMag
			if ammo <= 0 then
				Combat.reload(shooterPlayer)
				return
			end
			tool:SetAttribute("Ammo", ammo - 1)
		end

		local character = shooterPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") and (root.Position - origin).Magnitude > ORIGIN_TOLERANCE_STUDS then
			rayOrigin = root.Position
		end
	end

	-- weapon stats with safe defaults for guns that omit projectile fields
	local speed = weapon.ProjectileSpeed or 130
	local gravity = weapon.ProjectileGravity or 0
	local size = weapon.ProjectileSize or 0.8
	local range = weapon.MaxRangeStuds
	local damage = weapon.Damage or 1
	local paintColor = teamPaintColor(shooterPlayer)

	local aimParams = RaycastParams.new()
	aimParams.FilterType = Enum.RaycastFilterType.Exclude
	if shooterPlayer and shooterPlayer.Character then
		aimParams.FilterDescendantsInstances = { shooterPlayer.Character }
	end
	local aimHit = Workspace:Raycast(rayOrigin, direction.Unit * range, aimParams)
	local targetPoint = if aimHit then aimHit.Position else rayOrigin + direction.Unit * range

	local muzzle = getMuzzle(shooterPlayer, rayOrigin)
	local launchVel = solveLaunch(muzzle, targetPoint, speed, gravity)
	local baseDir = if launchVel then launchVel.Unit else (targetPoint - muzzle).Unit

	local function onHit(result: RaycastResult)
		local towerPart = Tower.resolveTowerPart(result.Instance)
		if towerPart then
			Tower.applyDamage(towerPart, result.Position, result.Normal, paintColor, shooterPlayer)
		else
			local hitModel = result.Instance:FindFirstAncestorOfClass("Model")
			if hitModel and hitModel:FindFirstChildOfClass("Humanoid") then
				Combat.applyHit(hitModel, result.Position, result.Normal, paintColor, shooterPlayer, damage)
			else
				PaintSplat.spawn(result.Position, result.Normal, paintColor)
			end
		end
		if weapon.SplashRadiusStuds and weapon.SplashRadiusStuds > 0 then
			applySplash(result.Position, weapon.SplashRadiusStuds, weapon.SplashDamage or 1, paintColor, shooterPlayer)
		end
	end

	-- pellets > 1 (e.g. Scattergun) spread within the weapon's cone; single shots use bloom
	local pellets = weapon.PelletsPerShot or 1
	local coneDeg = if pellets > 1 then (weapon.SpreadDegrees or 0) else currentSpread(shooterPlayer, weapon)
	local ignore = if shooterPlayer then shooterPlayer.Character else nil
	for _ = 1, pellets do
		Projectile.launch({
			origin = muzzle,
			direction = applySpread(baseDir, coneDeg),
			speed = speed,
			gravity = gravity,
			range = range,
			color = paintColor,
			size = size,
			ignore = ignore,
			onHit = onHit,
		})
	end
end

return Combat
