--!strict
-- Wires the match flow: the lobby Start pad begins a match, and a fallen tower ends it.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Match = require(ServerScriptService:WaitForChild("Match"))
local Tower = require(ServerScriptService:WaitForChild("Tower"))
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

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
