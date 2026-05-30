--!strict
-- Lobby practice range: keeps a respawning paint target on each stand so players warm up
-- the 3-hit tap-to-shoot. Targets reuse the normal combat path (they are simple humanoid
-- dummies), so shooting one three times tags it out; it then vanishes and a fresh one pops
-- up after a short delay. Each splat is credited to the shooter and reported to their HUD.

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

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

	-- shot out (3 hits) -> combat sets Health to 0 -> credit the shooter, then respawn
	humanoid.Died:Connect(function()
		local id = humanoid:GetAttribute("LastHitBy") :: number?
		if id and id ~= 0 then
			local shooter = Players:GetPlayerByUserId(id)
			if shooter then
				splatsByPlayer[shooter] = (splatsByPlayer[shooter] or 0) + 1
				Remotes.PracticeProgress:FireClient(shooter, splatsByPlayer[shooter])
			end
		end
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

for _, marker in markers:GetChildren() do
	if marker:IsA("BasePart") then
		spawnTarget(marker)
	end
end

Players.PlayerRemoving:Connect(function(player)
	splatsByPlayer[player] = nil
end)
