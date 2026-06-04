--!strict
-- Plays the feedback sounds for game events. Display-layer only: every sound here
-- reacts to a server event that already happened.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))
local Sfx = require(Shared:WaitForChild("Sfx"))

Remotes.PaintHitVFX.OnClientEvent:Connect(function()
	Sfx.play("HitTaken", 0.6)
end)

Remotes.PlayerTagged.OnClientEvent:Connect(function()
	Sfx.play("TaggedOut", 0.7)
end)

Remotes.MatchStarting.OnClientEvent:Connect(function(active: boolean)
	if active then
		Sfx.play("MatchStart", 0.6)
	end
end)

Remotes.MatchStats.OnClientEvent:Connect(function()
	Sfx.play("Victory", 0.7)
end)

Remotes.PowerUpEvent.OnClientEvent:Connect(function(kind: string)
	if kind == "spawned" then
		Sfx.play("PowerUpSpawn", 0.5)
	elseif kind == "claimed" then
		Sfx.play("PowerUpClaim", 0.6)
	end
end)

Remotes.StreakEvent.OnClientEvent:Connect(function()
	Sfx.play("Streak", 0.5)
end)

Remotes.DogShot.OnClientEvent:Connect(function()
	Sfx.play("DogShot", 0.6)
end)
