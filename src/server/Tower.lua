--!strict
-- Server-authoritative comms tower objective. Tracks each tower's health, applies
-- paint damage, awards coins for tower hits, and ends the match when a tower falls.
-- The team that destroys the enemy tower wins.

local Workspace = game:GetService("Workspace")
local Teams = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local PaintSplat = require(Shared:WaitForChild("PaintSplat"))
local Economy = require(game:GetService("ServerScriptService"):WaitForChild("Economy"))

local Tower = {}

-- fired on the server when a tower falls, with the winning team's full name. The match
-- flow listens to this to end the round.
Tower.Destroyed = Instance.new("BindableEvent")

local HEALTH_PER_PLAYER = Config.Tower.HealthPerPlayer
local DAMAGE_PER_HIT = Config.Tower.HitsToDamageRatio

-- Towers store a short owner tag ("Red"/"Blue") in their Team attribute, set by the
-- arena blockout. Map that to the full team names used by the Teams service.
local TEAM_NAME = { Red = "Red Squad", Blue = "Blue Squad" }
local ENEMY_NAME = { Red = "Blue Squad", Blue = "Red Squad" }

local matchOver = false

function Tower.isMatchOver(): boolean
	return matchOver
end

-- how many players are on the team that attacks this tower (its enemy)
local function attackerCount(owner: string): number
	local team = Teams:FindFirstChild(ENEMY_NAME[owner])
	if team and team:IsA("Team") then
		return #team:GetPlayers()
	end
	return 0
end

-- Set each tower's health, scaled to its attacking team's size. Call on match start.
function Tower.registerAll()
	matchOver = false
	for _, part in Workspace:GetDescendants() do
		if part:IsA("BasePart") and part.Name == "CommsTower" then
			local owner = part:GetAttribute("Team") :: string?
			local attackers = if owner then attackerCount(owner) else 0
			local maxHp = HEALTH_PER_PLAYER * math.max(1, attackers)
			part:SetAttribute("MaxHealth", maxHp)
			part:SetAttribute("Health", maxHp)
			part:SetAttribute("Destroyed", false)
		end
	end
end

-- Map a raycast-hit instance to its owning comms tower part, or nil. The neon tip
-- counts as a hit on the tower it sits on.
function Tower.resolveTowerPart(instance: Instance): BasePart?
	if instance.Name == "CommsTower" and instance:IsA("BasePart") then
		return instance
	end
	if instance.Name == "CommsTowerTip" and instance.Parent then
		local tower = instance.Parent:FindFirstChild("CommsTower")
		if tower and tower:IsA("BasePart") then
			return tower
		end
	end
	return nil
end

function Tower.applyDamage(towerPart: BasePart, hitPosition: Vector3, hitNormal: Vector3, paintColor: Color3, shooterPlayer: Player?)
	if matchOver or towerPart:GetAttribute("Destroyed") == true then
		return
	end

	local owner = towerPart:GetAttribute("Team") :: string?
	if not owner then
		return
	end

	-- you cannot damage your own tower
	if shooterPlayer and shooterPlayer.Team and shooterPlayer.Team.Name == TEAM_NAME[owner] then
		return
	end

	PaintSplat.spawn(hitPosition, hitNormal, paintColor)

	local maxHp = (towerPart:GetAttribute("MaxHealth") :: number?) or HEALTH_PER_PLAYER
	local health = math.max(0, ((towerPart:GetAttribute("Health") :: number?) or maxHp) - DAMAGE_PER_HIT)
	towerPart:SetAttribute("Health", health)
	if shooterPlayer then
		Economy.award(shooterPlayer, Config.Economy.CoinsPerTowerHit)
	end
	Remotes.TowerDamaged:FireAllClients(owner, health, maxHp)

	if health <= 0 then
		towerPart:SetAttribute("Destroyed", true)
		matchOver = true
		Remotes.MatchEnded:FireAllClients(ENEMY_NAME[owner])
		Tower.Destroyed:Fire(ENEMY_NAME[owner])
	end
end

return Tower
