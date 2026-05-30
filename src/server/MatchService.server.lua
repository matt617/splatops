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
Players.PlayerAdded:Connect(captureCode)

-- tower fell -> after the intermission, send everyone back to the lobby
Tower.Destroyed.Event:Connect(function()
	task.delay(Config.Match.IntermissionSeconds, function()
		Match.returnToLobby()
	end)
end)

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
