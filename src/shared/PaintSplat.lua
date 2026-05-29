--!strict
-- Paint splatter spawner. Server calls this on every confirmed hit so all clients
-- see the same marks. Placeholder art: a thin team-colored disc. Swap for a real
-- decal in the art pass.

local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local PaintSplat = {}

local function getContainer(): Folder
	local existing = Workspace:FindFirstChild("PaintSplats")
	if existing and existing:IsA("Folder") then
		return existing
	end
	local folder = Instance.new("Folder")
	folder.Name = "PaintSplats"
	folder.Parent = Workspace
	return folder
end

function PaintSplat.spawn(position: Vector3, normal: Vector3, color: Color3)
	local diameter = Config.VFX.PaintSplatterSizeStuds

	local splat = Instance.new("Part")
	splat.Name = "PaintSplat"
	splat.Shape = Enum.PartType.Cylinder
	-- cylinder axis runs along local X: thin thickness, round face of `diameter`
	splat.Size = Vector3.new(0.15, diameter, diameter)
	splat.Color = color
	splat.Material = Enum.Material.SmoothPlastic
	splat.Anchored = true
	splat.CanCollide = false
	splat.CanQuery = false -- keep splats out of weapon raycasts
	splat.CastShadow = false

	-- nudge off the surface to avoid z-fighting, then aim the round face down the normal
	local eye = position + normal * 0.05
	splat.CFrame = CFrame.lookAt(eye, eye + normal) * CFrame.Angles(0, math.rad(90), 0)
	splat.Parent = getContainer()

	Debris:AddItem(splat, Config.VFX.PaintSplatterDecalDurationSeconds)
end

return PaintSplat
