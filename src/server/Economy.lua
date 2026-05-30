--!strict
-- Per-match coin economy. Coins live as a "Coins" attribute on the player (replicates to
-- their client for the HUD) and every change fires CoinsChanged. Tags and tower hits award
-- coins; the quartermaster spends them; matches reset them.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local Economy = {}

function Economy.get(player: Player): number
	return (player:GetAttribute("Coins") :: number?) or 0
end

function Economy.set(player: Player, amount: number)
	player:SetAttribute("Coins", amount)
	Remotes.CoinsChanged:FireClient(player, amount)
end

function Economy.award(player: Player, amount: number)
	if amount <= 0 then
		return
	end
	Economy.set(player, Economy.get(player) + amount)
end

-- Spend coins if the player can afford it. Returns true on success.
function Economy.spend(player: Player, amount: number): boolean
	if Economy.get(player) < amount then
		return false
	end
	Economy.set(player, Economy.get(player) - amount)
	return true
end

function Economy.reset(player: Player)
	Economy.set(player, Config.Economy.StartingCoins)
end

return Economy
