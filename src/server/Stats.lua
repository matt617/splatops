--!strict
-- Per-match scoreboard stats. Resets each round. Counts tags and tag-outs (from Combat.Tagged)
-- and tower hits (from Tower.Damaged), and derives coins earned from the economy rates. The
-- match flow snapshots this when a round ends to build the end-of-match scoreboard, and reads
-- per-team tower damage to settle a match that runs out the clock.

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Combat = require(ServerScriptService:WaitForChild("Combat"))
local Tower = require(ServerScriptService:WaitForChild("Tower"))

local Stats = {}

type Row = { tags: number, taggedOut: number, towerHits: number }
local byUser: { [number]: Row } = {}

local function row(userId: number): Row
	local r = byUser[userId]
	if not r then
		r = { tags = 0, taggedOut = 0, towerHits = 0 }
		byUser[userId] = r
	end
	return r
end

function Stats.reset()
	byUser = {}
end

-- tags and tag-outs: Combat fires this only for real humanoid tag-outs (players in a match),
-- never for the lobby practice targets (those have no humanoid and take a different path).
Combat.Tagged.Event:Connect(function(shooter: Player?, _model: Model, victim: Player?)
	if shooter then
		row(shooter.UserId).tags += 1
	end
	if victim then
		row(victim.UserId).taggedOut += 1
	end
end)

-- tower hits, credited to the shooter
Tower.Damaged.Event:Connect(function(shooter: Player?, _owner: string)
	if shooter then
		row(shooter.UserId).towerHits += 1
	end
end)

local function teamShort(player: Player): string?
	if player.Team then
		if player.Team.Name == "Red Squad" then
			return "Red"
		elseif player.Team.Name == "Blue Squad" then
			return "Blue"
		end
	end
	return nil
end

-- how much tower damage each team dealt to the enemy tower (the time-limit tiebreak)
function Stats.teamTowerDamage(): { Red: number, Blue: number }
	local totals = { Red = 0, Blue = 0 }
	for userId, r in byUser do
		local p = Players:GetPlayerByUserId(userId)
		local t = p and teamShort(p)
		if t then
			totals[t] += r.towerHits
		end
	end
	return totals
end

-- one row per current player, with coins derived from the economy rates
function Stats.snapshot(): { any }
	local rows = {}
	for _, player in Players:GetPlayers() do
		local r = byUser[player.UserId] or { tags = 0, taggedOut = 0, towerHits = 0 }
		local coins = r.tags * Config.Economy.CoinsPerTag + r.towerHits * Config.Economy.CoinsPerTowerHit
		table.insert(rows, {
			name = player.DisplayName,
			team = (player.Team and player.Team.Name) or "Neutral",
			tags = r.tags,
			taggedOut = r.taggedOut,
			towerHits = r.towerHits,
			coins = coins,
		})
	end
	return rows
end

return Stats
