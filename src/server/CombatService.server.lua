--!strict
-- Wires the combat core to the game: sets up each spawned character and routes the
-- FireWeapon remote. Logic lives in Combat.lua so the test harness can reuse it.

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Combat = require(ServerScriptService:WaitForChild("Combat"))
local Tower = require(ServerScriptService:WaitForChild("Tower"))
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

-- set the comms towers to full health for the round
Tower.registerAll()

Players.PlayerAdded:Connect(function(player)
	player:SetAttribute("Coins", Config.Economy.StartingCoins)
	player.CharacterAdded:Connect(function(character)
		Combat.setupCharacter(character)
	end)
	if player.Character then
		Combat.setupCharacter(player.Character)
	end
end)

Remotes.FireWeapon.OnServerEvent:Connect(function(player, origin, direction)
	-- never trust these blindly: the client only says where it aimed, the server decides the rest
	if typeof(origin) ~= "Vector3" or typeof(direction) ~= "Vector3" then
		return
	end
	Combat.handleFire(player, origin, direction)
end)
