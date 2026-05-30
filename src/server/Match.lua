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

-- split players evenly across the two squads
local function assignTeams()
	local red, blue = squad("Red Squad"), squad("Blue Squad")
	if not red or not blue then
		return
	end
	for i, player in ipairs(Players:GetPlayers()) do
		player.Neutral = false
		player.Team = (i % 2 == 1) and red or blue
	end
end

function Match.start()
	if Match.state ~= "Lobby" then
		return
	end
	Match.state = "Match"
	Tower.registerAll() -- reset tower health and clear the match-over flag
	setLobbySpawnEnabled(false) -- so team players spawn at their base, not back in the lobby
	assignTeams()
	if Config.Economy.CoinsResetEachMatch then
		for _, player in Players:GetPlayers() do
			Economy.reset(player)
		end
	end
	for _, player in Players:GetPlayers() do
		player:LoadCharacter() -- respawns at the player's team spawn in the arena
	end
	Remotes.MatchStarting:FireAllClients(true)
end

function Match.returnToLobby()
	Match.state = "Lobby"
	Tower.registerAll() -- clear match-over so lobby practice fire works again
	setLobbySpawnEnabled(true) -- neutral players spawn back in the practice range
	for _, player in Players:GetPlayers() do
		player.Team = nil
		player.Neutral = true
		player:LoadCharacter() -- respawns at the neutral lobby spawn
	end
	Remotes.MatchStarting:FireAllClients(false)
end

return Match
