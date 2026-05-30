--!strict
-- Builds the marker's cosmetic parts at runtime and welds them to the Handle (the body),
-- so the whole gun moves as one. The glowing accents (hopper, muzzle, gauge) are tinted to
-- the wielder's squad color. Only the Handle lives on disk; the rest is described here.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local tool = script.Parent
local handle = tool:WaitForChild("Handle") :: BasePart

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

-- painted camo skin wrapped onto the boxy metal parts
local SKIN = "rbxassetid://113665300523857"
local FACES =
	{ Enum.NormalId.Top, Enum.NormalId.Bottom, Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right }
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

-- cosmetic parts, offset relative to the Handle (body) center. accent=true means it glows
-- in the team color.
local PARTS = {
	{ name = "Rail", size = V(0.5, 0.18, 1.6), cf = CFrame.new(0, 0.78, -0.2), color = BLACK },
	{ name = "Sight", size = V(1.0, 0.5, 0.5), cf = CFrame.new(0, 1.05, -0.3) * yaw(90), color = DARK, shape = CYL },
	{ name = "Hopper", size = V(1.35, 1.35, 1.35), cf = CFrame.new(0, 0.95, 0.5), accent = true, shape = BALL },
	{ name = "Barrel", size = V(4.0, 0.42, 0.42), cf = CFrame.new(0, 0.25, -2.9) * yaw(90), color = BLACK, shape = CYL },
	{ name = "Muzzle", size = V(0.5, 0.6, 0.6), cf = CFrame.new(0, 0.25, -4.8) * yaw(90), accent = true, shape = CYL },
	{ name = "Grip", size = V(0.6, 1.6, 0.85), cf = CFrame.new(0, -1.15, 0.7) * CFrame.Angles(math.rad(-14), 0, 0), color = BLACK, skin = true },
	{ name = "TriggerGuard", size = V(0.22, 0.7, 1.0), cf = CFrame.new(0, -0.5, 0.05), color = DARK },
	{ name = "StockArm", size = V(0.45, 0.45, 1.3), cf = CFrame.new(0, -0.05, 1.9), color = DARK },
	{ name = "StockPad", size = V(0.85, 1.3, 0.5), cf = CFrame.new(0, -0.05, 2.65), color = GUN, skin = true },
	{ name = "Tank", size = V(2.2, 0.72, 0.72), cf = CFrame.new(0, -0.75, 1.5) * yaw(90), color = DARK, shape = CYL },
	{ name = "Gauge", size = V(0.3, 0.45, 0.45), cf = CFrame.new(0, -0.45, 2.55) * yaw(90), accent = true, shape = CYL },
}

-- the wielder's squad color for the glowing accents, or a neutral white if unteamed
local function accentColor(): Color3
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

local accent = accentColor()

for _, spec in PARTS do
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

-- skin the body (Handle) too
wrap(handle, 2.5)
