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

-- the Start Match pad in the lobby
local range = Workspace:WaitForChild("PracticeRange")
local pad = range:WaitForChild("StartPad")
local debounce = false
pad.Touched:Connect(function(hit)
	if debounce or Match.state ~= "Lobby" then
		return
	end
	if not Players:GetPlayerFromCharacter(hit.Parent) then
		return
	end
	debounce = true
	Match.start()
	task.delay(2, function()
		debounce = false
	end)
end)
