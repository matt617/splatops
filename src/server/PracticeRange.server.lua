--!strict
-- Lobby practice range. Static themed targets (boards tagged "PracticeTarget", built by
-- build/practice_range.luau) register a hit the moment a shot lands on them: a splat from
-- combat, a quick color flash here, and a +1 on the shooter's practice counter. No health
-- and no respawn, so players can warm up any weapon at their own pace. Party servers only.

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))
local LobbyMode = require(Shared:WaitForChild("LobbyMode"))
if LobbyMode.get() ~= "party" then
	return -- practice targets only exist in a private-lobby (party) server
end

local Combat = require(ServerScriptService:WaitForChild("Combat"))

-- one shotgun blast is many pellets on the same board; collapse that to a single count
local HIT_DEBOUNCE = 0.2
local FLASH = Color3.fromRGB(255, 230, 90)

local splatsByPlayer: { [Player]: number } = {}
local lastHitAt: { [BasePart]: number } = {}

-- a brief highlight pulse so a kid sees the target react without it moving
local function flash(target: BasePart)
	if target:FindFirstChild("HitFlash") then
		return
	end
	local hl = Instance.new("Highlight")
	hl.Name = "HitFlash"
	hl.FillColor = FLASH
	hl.OutlineColor = FLASH
	hl.FillTransparency = 0.4
	hl.DepthMode = Enum.HighlightDepthMode.Occluded
	hl.Adornee = target
	hl.Parent = target
	task.delay(0.18, function()
		hl:Destroy()
	end)
end

Combat.PracticeTargetHit.Event:Connect(function(shooter: Player?, target: BasePart, _pos: Vector3)
	if not target then
		return
	end
	local now = os.clock()
	if now - (lastHitAt[target] or 0) < HIT_DEBOUNCE then
		return
	end
	lastHitAt[target] = now
	flash(target)
	if shooter then
		splatsByPlayer[shooter] = (splatsByPlayer[shooter] or 0) + 1
		Remotes.PracticeProgress:FireClient(shooter, splatsByPlayer[shooter])
	end
end)

Players.PlayerRemoving:Connect(function(player)
	splatsByPlayer[player] = nil
end)
