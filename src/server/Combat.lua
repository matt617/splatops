--!strict
-- Server-authoritative combat core for the Assault Marker.
-- This module owns hit detection, damage, tag-out, and respawn. Nothing here trusts
-- the client beyond where it claims to be aiming, and even that gets sanity checked.
-- Kept as a module so the test harness can drive it directly with execute_luau.

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

local Combat = {}

local MARKER = Config.Weapons.AssaultMarker
local MAX_HITS = Config.Player.MaxHits

-- per-player fire cadence, enforced on the server so a fast client cannot out-shoot the marker
local lastFireByPlayer: { [Player]: number } = {}

-- per-player accuracy heat: grows with each shot, decays over time, blooms the spread
local spreadHeat: { [Player]: { value: number, last: number } } = {}

-- The client sends its camera position as the muzzle origin. In third person the
-- camera sits well behind the character, so we trust that origin for aim only when it
-- is within this range of the shooter. A farther (or spoofed) origin falls back to
-- firing from the character, which still works and cannot shoot through walls from
-- somewhere else.
local ORIGIN_TOLERANCE_STUDS = 24

local function teamPaintColor(player: Player?): Color3
	if player and player.Team then
		for _, team in Config.Teams do
			if team.Name == player.Team.Name then
				return team.PaintColor
			end
		end
	end
	-- unteamed shooter (e.g. the test harness): still drop a visible splat
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
	if not character then
		return nil
	end
	return character:FindFirstChildOfClass("Tool")
end

-- Refill the equipped marker after a delay. Safe to call any time; it no-ops if the
-- marker is already full or already reloading. Ammo lives on the Tool so it replicates
-- to the owner's HUD for free.
function Combat.reload(player: Player)
	local tool = getEquippedTool(player)
	if not tool or tool:GetAttribute("Reloading") == true then
		return
	end
	local ammo = (tool:GetAttribute("Ammo") :: number?) or MARKER.AmmoPerMag
	if ammo >= MARKER.AmmoPerMag then
		return
	end
	tool:SetAttribute("Reloading", true)
	task.delay(MARKER.ReloadSeconds, function()
		if tool.Parent then
			tool:SetAttribute("Ammo", MARKER.AmmoPerMag)
		end
		tool:SetAttribute("Reloading", false)
	end)
end

-- where the paintball leaves the marker: the held Handle if we can find it, else the chest
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

-- nudge the aim by a small random cone so rapid fire is not perfectly accurate
local function applySpread(dir: Vector3, degrees: number?): Vector3
	if not degrees or degrees <= 0 then
		return dir
	end
	local rad = math.rad(degrees)
	local pitch = (math.random() - 0.5) * rad
	local yaw = (math.random() - 0.5) * rad
	return (CFrame.lookAt(Vector3.zero, dir) * CFrame.Angles(pitch, yaw, 0)).LookVector
end

-- Current spread for this shot: base plus accumulated heat. Each call also adds heat for the
-- next shot, so a paced shooter stays accurate while a sprayer scatters. nil = test harness.
local function currentSpread(player: Player?): number
	if not player then
		return MARKER.SpreadDegrees
	end
	local now = os.clock()
	local heat = spreadHeat[player]
	if not heat then
		heat = { value = 0, last = now }
		spreadHeat[player] = heat
	end
	heat.value = math.max(0, heat.value - (now - heat.last) * MARKER.SpreadRecoverPerSec)
	local spread = MARKER.SpreadDegrees + heat.value
	heat.value = math.min(MARKER.SpreadMaxDegrees - MARKER.SpreadDegrees, heat.value + MARKER.SpreadPerShot)
	heat.last = now
	return spread
end

-- Drop per-player state when they leave so the tables do not grow forever.
function Combat.clearPlayer(player: Player)
	lastFireByPlayer[player] = nil
	spreadHeat[player] = nil
end

-- Solve a launch velocity (fixed speed) so an arced ball passes through the target point.
-- Returns nil if the target is out of range for that speed. Picks the flatter of the two
-- arcs so a tap reads as "shoot at that spot," just with a visible lob.
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

-- Initialize a character for combat. Safe to call on every spawn.
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

-- Freeze the target and start its respawn. Players get the ELIMINATED stamp and reload
-- at their base spawn. Dummies just drop so the tag-out reads clearly in testing.
function Combat.tagOut(character: Model, victimPlayer: Player?)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	humanoid:SetAttribute("TaggedOut", true)

	if victimPlayer then
		-- freeze without triggering the Roblox death screen, then respawn on our own clock
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

-- Apply a single marker hit. Returns true if the hit landed (passed team and state checks).
function Combat.applyHit(
	targetCharacter: Model,
	hitPosition: Vector3,
	hitNormal: Vector3,
	paintColor: Color3,
	shooterPlayer: Player?
): boolean
	local humanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return false
	end
	if humanoid:GetAttribute("TaggedOut") == true then
		return false
	end

	local victimPlayer = Players:GetPlayerFromCharacter(targetCharacter)
	if not Config.Player.FriendlyFire and sameTeam(shooterPlayer, victimPlayer) then
		return false
	end

	-- world splat for everyone, screen flash just for the player who got tagged
	PaintSplat.spawn(hitPosition, hitNormal, paintColor)
	if victimPlayer then
		Remotes.PaintHitVFX:FireClient(victimPlayer, paintColor)
	end

	-- remember who landed the hit (used for tag credit and the practice counter)
	humanoid:SetAttribute("LastHitBy", if shooterPlayer then shooterPlayer.UserId else 0)

	local hits = ((humanoid:GetAttribute("Hits") :: number?) or 0) + MARKER.Damage
	humanoid:SetAttribute("Hits", hits)

	if hits >= MAX_HITS then
		Combat.tagOut(targetCharacter, victimPlayer)
	end
	return true
end

-- Entry point for a fired shot. shooterPlayer is nil when the test harness drives this.
function Combat.handleFire(shooterPlayer: Player?, origin: Vector3, direction: Vector3)
	if Tower.isMatchOver() then
		return
	end
	local rayOrigin = origin
	if shooterPlayer then
		local now = os.clock()
		local last = lastFireByPlayer[shooterPlayer] or 0
		if now - last < MARKER.FireRateSeconds then
			return
		end
		lastFireByPlayer[shooterPlayer] = now

		-- ammo: an empty marker does not fire, it auto-reloads instead
		local tool = getEquippedTool(shooterPlayer)
		if tool then
			if tool:GetAttribute("Reloading") == true then
				return
			end
			local ammo = (tool:GetAttribute("Ammo") :: number?) or MARKER.AmmoPerMag
			if ammo <= 0 then
				Combat.reload(shooterPlayer)
				return
			end
			tool:SetAttribute("Ammo", ammo - 1)
		end

		-- trust the camera origin only when it sits near the shooter, else fire from them
		local character = shooterPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") and (root.Position - origin).Magnitude > ORIGIN_TOLERANCE_STUDS then
			rayOrigin = root.Position
		end
	end

	-- find what the crosshair is pointing at, so the ball converges there from the muzzle
	local aimParams = RaycastParams.new()
	aimParams.FilterType = Enum.RaycastFilterType.Exclude
	if shooterPlayer and shooterPlayer.Character then
		aimParams.FilterDescendantsInstances = { shooterPlayer.Character }
	end
	local aimHit = Workspace:Raycast(rayOrigin, direction.Unit * MARKER.MaxRangeStuds, aimParams)
	local targetPoint = if aimHit then aimHit.Position else rayOrigin + direction.Unit * MARKER.MaxRangeStuds

	local muzzle = getMuzzle(shooterPlayer, rayOrigin)
	-- arc the ball so it lobs onto the point you aimed at, instead of dropping short
	local launchVel = solveLaunch(muzzle, targetPoint, MARKER.ProjectileSpeed, MARKER.ProjectileGravity)
	local baseDir = if launchVel then launchVel.Unit else (targetPoint - muzzle).Unit
	local launchDir = applySpread(baseDir, currentSpread(shooterPlayer))
	local paintColor = teamPaintColor(shooterPlayer)

	-- the paintball owns hit detection: it flies and resolves on impact
	Projectile.launch({
		origin = muzzle,
		direction = launchDir,
		speed = MARKER.ProjectileSpeed,
		gravity = MARKER.ProjectileGravity,
		range = MARKER.MaxRangeStuds,
		color = paintColor,
		size = MARKER.ProjectileSize,
		ignore = if shooterPlayer then shooterPlayer.Character else nil,
		onHit = function(result: RaycastResult)
			-- a comms tower hit damages the objective, not a player
			local towerPart = Tower.resolveTowerPart(result.Instance)
			if towerPart then
				Tower.applyDamage(towerPart, result.Position, result.Normal, paintColor, shooterPlayer)
				return
			end
			local hitModel = result.Instance:FindFirstAncestorOfClass("Model")
			if hitModel and hitModel:FindFirstChildOfClass("Humanoid") then
				Combat.applyHit(hitModel, result.Position, result.Normal, paintColor, shooterPlayer)
				return
			end
			-- otherwise just paint the surface
			PaintSplat.spawn(result.Position, result.Normal, paintColor)
		end,
	})
end

return Combat
