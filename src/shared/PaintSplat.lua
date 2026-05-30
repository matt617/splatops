--!strict
-- Paint splatter spawner. Server calls this on every confirmed hit so all clients see the same
-- marks. With splatter images configured (Config.VFX.PaintSplatterImages) it stamps 1-3 random
-- decals per hit (random image, rotation, size) tinted to the team color, plus a quick droplet
-- particle burst, for a real paint look. With none configured it falls back to a plain disc.
-- Old marks are recycled past a cap so a long match stays light.

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

-- recycle the oldest marks past the cap
local active: { Instance } = {}
local function track(part: Instance)
	table.insert(active, part)
	while #active > Config.VFX.PaintSplatMaxOnScreen do
		local oldest = table.remove(active, 1)
		if oldest then
			oldest:Destroy()
		end
	end
end

-- two unit vectors spanning the surface plane, for scattering satellite marks
local function tangents(normal: Vector3): (Vector3, Vector3)
	local ref = math.abs(normal.Y) > 0.99 and Vector3.xAxis or Vector3.yAxis
	local t1 = normal:Cross(ref).Unit
	return t1, normal:Cross(t1).Unit
end

-- the original placeholder: a thin team-colored disc (used when no images are set)
local function spawnDisc(position: Vector3, normal: Vector3, color: Color3)
	local diameter = Config.VFX.PaintSplatterSizeStuds
	local splat = Instance.new("Part")
	splat.Name = "PaintSplat"
	splat.Shape = Enum.PartType.Cylinder
	splat.Size = Vector3.new(0.15, diameter, diameter)
	splat.Color = color
	splat.Material = Enum.Material.SmoothPlastic
	splat.Anchored = true
	splat.CanCollide = false
	splat.CanQuery = false
	splat.CastShadow = false
	local eye = position + normal * 0.05
	splat.CFrame = CFrame.lookAt(eye, eye + normal) * CFrame.Angles(0, math.rad(90), 0)
	splat.Parent = getContainer()
	track(splat)
	Debris:AddItem(splat, Config.VFX.PaintSplatterDecalDurationSeconds)
end

-- a short burst of paint droplets flying off the surface on impact
local function spawnBurst(position: Vector3, normal: Vector3, color: Color3)
	if Config.VFX.PaintDropletImage == "" then
		return
	end
	local t1 = tangents(normal)
	local emitterPart = Instance.new("Part")
	emitterPart.Size = Vector3.new(0.2, 0.2, 0.2)
	emitterPart.Transparency = 1
	emitterPart.Anchored = true
	emitterPart.CanCollide = false
	emitterPart.CanQuery = false
	emitterPart.CastShadow = false
	emitterPart.CFrame = CFrame.fromMatrix(position + normal * 0.2, t1, normal) -- Top (+Y) = normal

	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = Config.VFX.PaintDropletImage
	emitter.Color = ColorSequence.new(color)
	emitter.Lifetime = NumberRange.new(0.3, 0.6)
	emitter.Speed = NumberRange.new(7, 13)
	emitter.SpreadAngle = Vector2.new(45, 45)
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.6),
		NumberSequenceKeypoint.new(1, 0.05),
	})
	emitter.Acceleration = Vector3.new(0, -35, 0) -- gravity, so droplets arc down
	emitter.Rate = 0
	emitter.EmissionDirection = Enum.NormalId.Top
	emitter.Parent = emitterPart

	emitterPart.Parent = getContainer()
	emitter:Emit(math.random(8, 14))
	Debris:AddItem(emitterPart, 1)
end

function PaintSplat.spawn(position: Vector3, normal: Vector3, color: Color3)
	local images = Config.VFX.PaintSplatterImages
	if #images == 0 then
		spawnDisc(position, normal, color)
		return
	end

	local t1, t2 = tangents(normal)
	local base = Config.VFX.PaintSplatterSizeStuds
	local marks = math.random(1, math.max(1, Config.VFX.PaintMarksPerHit))
	for i = 1, marks do
		local size = base * (0.6 + math.random() * 0.9)
		-- first mark is centered; the rest scatter a little around the impact
		local spread = (i == 1) and 0 or base * (0.3 + math.random() * 0.5)
		local ang = math.random() * math.pi * 2
		local offset = (t1 * math.cos(ang) + t2 * math.sin(ang)) * spread

		local part = Instance.new("Part")
		part.Name = "PaintSplat"
		part.Size = Vector3.new(size, size, 0.08)
		part.Transparency = 1 -- invisible part; only the decal shows
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CastShadow = false
		local eye = position + offset + normal * (0.03 + i * 0.006) -- layer to avoid z-fighting
		part.CFrame = CFrame.lookAt(eye, eye + normal) * CFrame.Angles(0, 0, math.random() * math.pi * 2)

		local decal = Instance.new("Decal")
		decal.Texture = images[math.random(#images)]
		decal.Color3 = color -- tint the white splatter to the team color
		decal.Face = Enum.NormalId.Front -- faces along the surface normal
		decal.Parent = part

		part.Parent = getContainer()
		track(part)
		Debris:AddItem(part, Config.VFX.PaintSplatterDecalDurationSeconds)
	end

	spawnBurst(position, normal, color)
end

return PaintSplat
