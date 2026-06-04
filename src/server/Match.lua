--!strict
-- Match flow: the server-side lobby <-> match loop. In Lobby, players are neutral in the
-- practice range. On start it splits everyone into Red/Blue, resets the towers, and spawns
-- them into the arena. When a tower falls the round ends; after an intermission everyone
-- returns to the lobby.

local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Tower = require(ServerScriptService:WaitForChild("Tower"))
local Economy = require(ServerScriptService:WaitForChild("Economy"))
local Stats = require(ServerScriptService:WaitForChild("Stats"))

local Match = {}
Match.state = "Lobby"

local function squad(name: string): Team?
	local t = Teams:FindFirstChild(name)
	return (t and t:IsA("Team")) and t or nil
end

-- the neutral lobby spawn. It must be disabled during a match, otherwise team players can
-- respawn there instead of at their base (which looks like "Start did nothing").
local function setLobbySpawnEnabled(enabled: boolean)
	local range = Workspace:FindFirstChild("PracticeRange")
	local spawn = range and range:FindFirstChild("LobbySpawn")
	if spawn and spawn:IsA("SpawnLocation") then
		spawn.Enabled = enabled
	end
end

-- Strip every tool off a player. The backpack survives a respawn, so rack-test markers and
-- last round's shop buys would otherwise carry over. We clear here and let LoadCharacter
-- re-add the StarterPack loadout (just the Assault Marker) for a clean slate each transition.
local function clearLoadout(player: Player)
	local function purge(container: Instance?)
		if container then
			for _, item in container:GetChildren() do
				if item:IsA("Tool") then
					item:Destroy()
				end
			end
		end
	end
	purge(player:FindFirstChildOfClass("Backpack"))
	purge(player.Character)
end

-- split players evenly across the two squads, shuffled so the teams remix every round
local function assignTeams()
	local red, blue = squad("Red Squad"), squad("Blue Squad")
	if not red or not blue then
		return
	end
	local pool = Players:GetPlayers()
	for i = #pool, 2, -1 do
		local j = math.random(i)
		pool[i], pool[j] = pool[j], pool[i]
	end
	for i, player in ipairs(pool) do
		player.Neutral = false
		player.Team = (i % 2 == 1) and red or blue
	end
end

-- Set up a fresh round: reset towers, split teams, reset coins and stats, and spawn everyone
-- into the arena. Shared by the first start and the auto-rematch.
local function beginRound()
	Tower.registerAll() -- reset tower health and clear the match-over flag
	setLobbySpawnEnabled(false) -- so team players spawn at their base, not back in the lobby
	assignTeams()
	Stats.reset()
	if Config.Economy.CoinsResetEachMatch then
		for _, player in Players:GetPlayers() do
			Economy.reset(player)
		end
	end
	for _, player in Players:GetPlayers() do
		clearLoadout(player) -- drop any rack-test markers so matches start with just the Assault Marker
		player:LoadCharacter() -- respawns at the player's team spawn in the arena
	end
	Remotes.MatchStarting:FireAllClients(true)
end

function Match.start()
	if Match.state ~= "Lobby" then
		return
	end
	Match.state = "Match"
	beginRound()
end

-- Auto-rematch: start the next round directly from a finished match, no lobby round trip.
function Match.rematch()
	if Match.state ~= "Match" then
		return
	end
	beginRound()
end

-- A player who joins while a match is running: put them on the smaller team and spawn
-- them at that base. Without this they would stay neutral with the lobby spawn disabled
-- and drop at the world origin.
function Match.addLatecomer(player: Player)
	if Match.state ~= "Match" then
		return
	end
	local red, blue = squad("Red Squad"), squad("Blue Squad")
	if not red or not blue then
		return
	end
	player.Neutral = false
	player.Team = if #red:GetPlayers() <= #blue:GetPlayers() then red else blue
	Economy.reset(player)
	clearLoadout(player)
	player:LoadCharacter()
	Remotes.MatchStarting:FireClient(player, true)
end

function Match.returnToLobby()
	Match.state = "Lobby"
	Tower.registerAll() -- clear match-over so lobby practice fire works again
	setLobbySpawnEnabled(true) -- neutral players spawn back in the practice range
	for _, player in Players:GetPlayers() do
		player.Team = nil
		player.Neutral = true
		clearLoadout(player) -- back to a clean Assault Marker loadout; grab test gear from the rack again
		player:LoadCharacter() -- respawns at the neutral lobby spawn
	end
	Remotes.MatchStarting:FireAllClients(false)
end

return Match
