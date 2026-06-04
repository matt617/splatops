--!strict
-- Wires the match flow: the lobby Start pad begins a match, and a fallen tower ends it.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local LobbyMode = require(Shared:WaitForChild("LobbyMode"))
if LobbyMode.get() ~= "party" then
	return -- the match loop only runs in a private-lobby (party) server
end

local Match = require(ServerScriptService:WaitForChild("Match"))
local Tower = require(ServerScriptService:WaitForChild("Tower"))
local Stats = require(ServerScriptService:WaitForChild("Stats"))
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

-- capture the share code carried in on teleport so the lobby can display it to the host
local function captureCode(player: Player)
	if ReplicatedStorage:GetAttribute("LobbyCode") then
		return
	end
	local ok, data = pcall(function()
		return player:GetJoinData().TeleportData
	end)
	if ok and type(data) == "table" and type(data.code) == "string" then
		ReplicatedStorage:SetAttribute("LobbyCode", data.code)
	end
end
for _, p in Players:GetPlayers() do
	captureCode(p)
end
Players.PlayerAdded:Connect(function(player)
	captureCode(player)
	-- joined while a round is running: drop them straight onto the smaller team
	if Match.state == "Match" then
		task.delay(1, function() -- give their client a moment to finish loading
			if player.Parent and Match.state == "Match" then
				Match.addLatecomer(player)
			end
		end)
	end
end)

-- if a whole team empties out mid-round, hand the round to the team still standing
Players.PlayerRemoving:Connect(function()
	task.defer(function()
		if Match.state ~= "Match" or Tower.isMatchOver() then
			return
		end
		local Teams = game:GetService("Teams")
		local red = Teams:FindFirstChild("Red Squad")
		local blue = Teams:FindFirstChild("Blue Squad")
		if not (red and blue) then
			return
		end
		local redCount = #(red :: Team):GetPlayers()
		local blueCount = #(blue :: Team):GetPlayers()
		if redCount == 0 and blueCount > 0 then
			Tower.forceEnd("Blue Squad")
		elseif blueCount == 0 and redCount > 0 then
			Tower.forceEnd("Red Squad")
		end
	end)
end)

-- The match clock. Each round bumps the generation so a stale clock from the previous round
-- stops ticking. When it runs out with no tower down, the team that dealt the most tower
-- damage wins (a draw if it is even).
local matchGen = 0

local function startClock()
	matchGen += 1
	local gen = matchGen
	task.spawn(function()
		local remaining = Config.Match.MatchTimeLimitSeconds
		Remotes.MatchClock:FireAllClients(remaining)
		while gen == matchGen and not Tower.isMatchOver() do
			task.wait(1)
			if gen ~= matchGen or Tower.isMatchOver() then
				break
			end
			remaining -= 1
			Remotes.MatchClock:FireAllClients(remaining)
			if remaining <= 0 then
				local dmg = Stats.teamTowerDamage()
				local winner = "Draw"
				if dmg.Red > dmg.Blue then
					winner = "Red Squad"
				elseif dmg.Blue > dmg.Red then
					winner = "Blue Squad"
				end
				Tower.forceEnd(winner)
				break
			end
		end
	end)
end

-- Round over (tower fell or clock ran out): freeze the clock, send the scoreboard, hold for the
-- intermission, then auto-rematch if enough players remain, otherwise drop back to the lobby.
local function endRound(winner: string)
	matchGen += 1 -- cancel the running clock
	Remotes.MatchStats:FireAllClients(winner, Stats.snapshot(), Config.Match.IntermissionSeconds)
	task.delay(Config.Match.IntermissionSeconds, function()
		if Config.Match.AutoRematch and #Players:GetPlayers() >= Config.Match.MinPlayersToStart then
			Match.rematch()
			startClock()
		else
			Match.returnToLobby()
		end
	end)
end

Tower.Destroyed.Event:Connect(endRound)

-- a start request from the lobby UI button or the Start pad. Below the minimum player count
-- it asks the requester to confirm rather than starting (unless they force it).
local function requestStart(player: Player, force: boolean)
	if Match.state ~= "Lobby" then
		return
	end
	local count = #Players:GetPlayers()
	if not force and count < Config.Match.MinPlayersToStart then
		Remotes.ConfirmStart:FireClient(player, count, Config.Match.MinPlayersToStart)
		return
	end
	Match.start()
	startClock()
end

Remotes.RequestStart.OnServerEvent:Connect(function(player, force)
	requestStart(player, force == true)
end)

-- stepping on the Start pad is an alternate way to request a start
local range = Workspace:WaitForChild("PracticeRange")
local pad = range:WaitForChild("StartPad")
local debounce = false
pad.Touched:Connect(function(hit)
	if debounce then
		return
	end
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if not player then
		return
	end
	debounce = true
	requestStart(player, false)
	task.delay(2, function()
		debounce = false
	end)
end)
