--!strict
-- Match flavor: tag streak banners and the comeback flag. Streaks count consecutive tags
-- since your last tag-out and announce at the milestones below. The LosingTeam attribute
-- marks whichever team is well behind on tower damage; Combat pays that team extra per tag.
-- Party servers only.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local LobbyMode = require(Shared:WaitForChild("LobbyMode"))
if LobbyMode.get() ~= "party" then
	return
end

local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Combat = require(ServerScriptService:WaitForChild("Combat"))
local Stats = require(ServerScriptService:WaitForChild("Stats"))
local Match = require(ServerScriptService:WaitForChild("Match"))

local MILESTONES: { [number]: string } = {
	[3] = "IS ON A ROLL!",
	[5] = "IS UNSTOPPABLE!",
	[7] = "IS A PAINT STORM!",
}

local streaks: { [number]: number } = {}

Combat.Tagged.Event:Connect(function(shooter: Player?, _target: Model, victim: Player?)
	if victim then
		streaks[victim.UserId] = 0
	end
	if shooter and Match.state == "Match" then
		local s = (streaks[shooter.UserId] or 0) + 1
		streaks[shooter.UserId] = s
		local label = MILESTONES[s]
		if label then
			Remotes.StreakEvent:FireAllClients(shooter.DisplayName, label, s)
		end
	end
end)

-- keep the comeback flag current while a match runs
local lastState = Match.state
task.spawn(function()
	while true do
		task.wait(3)
		if Match.state ~= lastState then
			lastState = Match.state
			streaks = {} -- fresh round, fresh streaks
		end
		local losing = ""
		if Match.state == "Match" then
			local d = Stats.teamTowerDamage()
			local threshold = Config.Economy.ComebackThresholdHits
			if d.Red - d.Blue >= threshold then
				losing = "Blue" -- Red has dealt far more tower damage, Blue needs the help
			elseif d.Blue - d.Red >= threshold then
				losing = "Red"
			end
		end
		ReplicatedStorage:SetAttribute("LosingTeam", losing)
	end
end)

ReplicatedStorage:SetAttribute("LosingTeam", "")
