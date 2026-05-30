--!strict
-- Lobby practice range: keeps a respawning paint target on each stand so players warm up
-- the 3-hit tap-to-shoot. Targets are simple humanoid dummies, so the normal combat code
-- handles hits and tag-out. Each splat is credited to the shooter (via Combat.Tagged) and
-- reported to their HUD; tagged-out targets respawn after a short delay.

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

local RESPAWN_SECONDS = 2
local DUMMY = Color3.fromRGB(190, 195, 200)
local HEAD = Color3.fromRGB(210, 200, 185)

local range = Workspace:WaitForChild("PracticeRange")
local markers = range:WaitForChild("Targets")

local splatsByPlayer: { [Player]: number } = {}

local function spawnTarget(marker: BasePart)
	local base = marker.Position
	local model = Instance.new("Model")
	model.Name = "Target"

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.Anchored = true
	root.Color = DUMMY
	root.CFrame = CFrame.new(base + Vector3.new(0, 2.8, 0))
	root.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(1.4, 1.4, 1.4)
	head.Anchored = true
	head.Color = HEAD
	head.CFrame = CFrame.new(base + Vector3.new(0, 4.5, 0))
	head.Parent = model

	local humanoid = Instance.new("Humanoid")
	humanoid.Parent = model
	model.PrimaryPart = root
	model.Parent = range

	humanoid.Died:Connect(function()
		task.delay(RESPAWN_SECONDS, function()
			if model.Parent then
				model:Destroy()
			end
			if marker.Parent then
				spawnTarget(marker)
			end
		end)
	end)
end

-- credit the shooter when one of OUR practice targets (a dummy with no player) is tagged out
Combat.Tagged.Event:Connect(function(shooter: Player?, targetModel: Model, victimPlayer: Player?)
	if shooter and not victimPlayer and targetModel and targetModel.Parent == range then
		splatsByPlayer[shooter] = (splatsByPlayer[shooter] or 0) + 1
		Remotes.PracticeProgress:FireClient(shooter, splatsByPlayer[shooter])
	end
end)

for _, marker in markers:GetChildren() do
	if marker:IsA("BasePart") then
		spawnTarget(marker)
	end
end

Players.PlayerRemoving:Connect(function(player)
	splatsByPlayer[player] = nil
end)
