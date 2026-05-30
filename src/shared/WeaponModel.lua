--!strict
-- Builds a marker's cosmetic parts at runtime and welds them to the Handle (the body), so
-- the whole gun moves as one. One shape shared by every weapon, with small per-weapon tweaks
-- (barrel length/width, scope) so the sniper/shotgun/mortar read differently. Glowing accents
-- (hopper, muzzle, gauge) are tinted to the wielder's squad color; boxy parts get the camo skin.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetService = game:GetService("AssetService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local WeaponMeshes = require(Shared:WaitForChild("WeaponMeshes"))

local WeaponModel = {}

local function V(x: number, y: number, z: number): Vector3
	return Vector3.new(x, y, z)
end
local function yaw(d: number): CFrame
	return CFrame.Angles(0, math.rad(d), 0)
end
local CYL, BALL = Enum.PartType.Cylinder, Enum.PartType.Ball
local METAL = Enum.Material.Metal

local GUN = Color3.fromRGB(54, 58, 64)
local BLACK = Color3.fromRGB(24, 24, 28)
local DARK = Color3.fromRGB(40, 42, 46)
local SKIN = "rbxassetid://113665300523857"
local FACES =
	{ Enum.NormalId.Top, Enum.NormalId.Bottom, Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right }

-- per-weapon barrel/scope so each gun is recognizable
local STYLES = {
	AssaultMarker = { barrelLen = 4.0, barrelW = 0.42, scope = false },
	ReconMarker = { barrelLen = 6.5, barrelW = 0.34, scope = true },
	Scattergun = { barrelLen = 2.2, barrelW = 0.85, scope = false },
	Mortar = { barrelLen = 2.8, barrelW = 1.3, scope = false },
}

local function wrap(part: BasePart, studs: number)
	for _, face in FACES do
		local t = Instance.new("Texture")
		t.Texture = SKIN
		t.Face = face
		t.StudsPerTileU = studs
		t.StudsPerTileV = studs
		t.Parent = part
	end
end

local function accentColor(tool: Instance): Color3
	local owner = Players:GetPlayerFromCharacter(tool.Parent)
	if not owner then
		local parent = tool.Parent
		if parent and (parent:IsA("Backpack") or parent:IsA("StarterGear")) then
			owner = parent.Parent :: Player
		end
	end
	if owner and owner.Team then
		for _, team in Config.Teams do
			if team.Name == owner.Team.Name then
				return team.PaintColor
			end
		end
	end
	return Color3.fromRGB(230, 235, 245)
end

local function specsFor(style): { any }
	local len, w = style.barrelLen, style.barrelW
	local barrelZ = -(0.9 + len / 2)
	local muzzleZ = barrelZ - len / 2 - 0.05
	local sightSize = if style.scope then V(1.5, 0.7, 0.7) else V(1.0, 0.5, 0.5)
	local sightY = if style.scope then 1.2 else 1.05
	return {
		{ name = "Rail", size = V(0.5, 0.18, 1.6), cf = CFrame.new(0, 0.78, -0.2), color = BLACK },
		{ name = "Sight", size = sightSize, cf = CFrame.new(0, sightY, -0.3) * yaw(90), color = DARK, shape = CYL },
		{ name = "Hopper", size = V(1.35, 1.35, 1.35), cf = CFrame.new(0, 0.95, 0.5), accent = true, shape = BALL },
		{ name = "Barrel", size = V(len, w, w), cf = CFrame.new(0, 0.25, barrelZ) * yaw(90), color = BLACK, shape = CYL },
		{ name = "Muzzle", size = V(0.5, w + 0.18, w + 0.18), cf = CFrame.new(0, 0.25, muzzleZ) * yaw(90), accent = true, shape = CYL },
		{ name = "Grip", size = V(0.6, 1.6, 0.85), cf = CFrame.new(0, -1.15, 0.7) * CFrame.Angles(math.rad(-14), 0, 0), color = BLACK, skin = true },
		{ name = "TriggerGuard", size = V(0.22, 0.7, 1.0), cf = CFrame.new(0, -0.5, 0.05), color = DARK },
		{ name = "StockArm", size = V(0.45, 0.45, 1.3), cf = CFrame.new(0, -0.05, 1.9), color = DARK },
		{ name = "StockPad", size = V(0.85, 1.3, 0.5), cf = CFrame.new(0, -0.05, 2.65), color = GUN, skin = true },
		{ name = "Tank", size = V(2.2, 0.72, 0.72), cf = CFrame.new(0, -0.75, 1.5) * yaw(90), color = DARK, shape = CYL },
		{ name = "Gauge", size = V(0.3, 0.45, 0.45), cf = CFrame.new(0, -0.45, 2.55) * yaw(90), accent = true, shape = CYL },
	}
end

-- 3D-model path: load each MeshPart once (cached), then clone, color, scale, and weld to the
-- Handle. Used when the weapon has an entry in WeaponMeshes; otherwise the part-built path runs.
local meshCache: { [string]: MeshPart } = {}
local function meshTemplate(meshId: string): MeshPart?
	local cached = meshCache[meshId]
	if cached then
		return cached
	end
	local ok, part = pcall(function()
		return AssetService:CreateMeshPartAsync(meshId, { CollisionFidelity = Enum.CollisionFidelity.Box })
	end)
	if not ok or not part then
		return nil
	end
	meshCache[meshId] = part
	return part
end

local GLASS = Color3.fromRGB(120, 170, 235)

local function buildFromMeshes(tool: Tool, def, accent: Color3)
	local handle = tool:WaitForChild("Handle") :: BasePart
	handle.Transparency = 1
	handle.Material = Enum.Material.SmoothPlastic
	handle.CanCollide = false
	local body = def.parts[1]
	handle.Size = Vector3.new(body.size[1] * def.scale, body.size[2] * def.scale, body.size[3] * def.scale)

	-- per-weapon rotation so each imported model ends up barrel-forward (-Z), grip down, scope up
	local baseRot = def.baseRot or CFrame.identity

	for _, part in def.parts do
		local template = meshTemplate(part.mesh)
		if template then
			local mp = template:Clone()
			mp.Name = part.name
			mp.Size = Vector3.new(part.size[1] * def.scale, part.size[2] * def.scale, part.size[3] * def.scale)
			mp.Anchored = false
			mp.CanCollide = false
			mp.Massless = true
			mp.CastShadow = false
			mp.Material = Enum.Material.SmoothPlastic
			if part.role == "team" then
				mp.Color = accent
			elseif part.role == "glass" then
				mp.Color = GLASS
				mp.Material = Enum.Material.Glass
				mp.Transparency = 0.25
			elseif part.role == "trim" then
				mp.Color = DARK
			else
				mp.Color = GUN
			end
			local cf = baseRot * CFrame.new(part.pos[1] * def.scale, part.pos[2] * def.scale, part.pos[3] * def.scale)
			mp.CFrame = handle.CFrame * cf
			mp.Parent = tool
			local weld = Instance.new("Weld")
			weld.Part0 = handle
			weld.Part1 = mp
			weld.C0 = cf
			weld.Parent = handle
		end
	end
end

function WeaponModel.build(tool: Tool)
	local meshDef = WeaponMeshes[tool.Name]
	if meshDef then
		buildFromMeshes(tool, meshDef, accentColor(tool))
		return
	end

	local handle = tool:WaitForChild("Handle") :: BasePart
	local style = STYLES[tool.Name] or STYLES.AssaultMarker
	local accent = accentColor(tool)

	for _, spec in specsFor(style) do
		local p = Instance.new("Part")
		p.Name = spec.name
		p.Size = spec.size
		p.Anchored = false
		p.CanCollide = false
		p.Massless = true
		p.CastShadow = false
		if spec.shape then
			p.Shape = spec.shape
		end
		if spec.accent then
			p.Color = accent
			p.Material = Enum.Material.Neon
		else
			p.Color = spec.color
			p.Material = METAL
		end
		p.CFrame = handle.CFrame * spec.cf
		p.Parent = tool

		local weld = Instance.new("Weld")
		weld.Part0 = handle
		weld.Part1 = p
		weld.C0 = spec.cf
		weld.Parent = handle

		if spec.skin then
			wrap(p, 2)
		end
	end

	wrap(handle, 2.5)
end

return WeaponModel
