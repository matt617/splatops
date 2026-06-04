--!strict
-- Splat Ops arena blockout (v1 gray-box).
--
-- This is the source of truth for the map shape until the art pass. The geometry
-- lives in the Studio Workspace, which Rojo does not sync to disk, so this script
-- is how the blockout stays in git and stays reproducible. Run it through weppy
-- execute_luau (or paste into the Studio command bar) to rebuild the arena from
-- scratch. Re-running is safe: it clears the prior Arena and the default
-- baseplate/spawn first.
--
-- Layout: three-lane symmetric arena. Red command post west (-X), Blue east (+X).
-- 260 studs long, 130 wide, ~250 tower-to-tower. Walls 28 high enclose the field.

local Workspace = game:GetService("Workspace")
local Teams = game:GetService("Teams")

local GRAY = Color3.fromRGB(120, 124, 130)
local DARK = Color3.fromRGB(84, 88, 94)
local WOOD = Color3.fromRGB(116, 92, 60)
local AMBER = Color3.fromRGB(196, 158, 70)
local RED = Color3.fromRGB(220, 50, 50) -- Config.Teams.Red.PaintColor
local BLUE = Color3.fromRGB(50, 100, 220) -- Config.Teams.Blue.PaintColor

-- clean re-run
local prior = Workspace:FindFirstChild("Arena")
if prior then
	prior:Destroy()
end
for _, n in ipairs({ "Baseplate", "SpawnLocation" }) do
	local o = Workspace:FindFirstChild(n)
	if o then
		o:Destroy()
	end
end

local arena = Instance.new("Folder")
arena.Name = "Arena"
arena.Parent = Workspace

local function folder(name: string): Folder
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = arena
	return f
end

local function block(parent: Instance, name: string, pos: Vector3, size: Vector3, color: Color3?, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = CFrame.new(pos)
	p.Color = color or GRAY
	p.Material = material or Enum.Material.Concrete
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local LEN, WID, WALL_H = 260, 130, 28

-- floor + perimeter
local fFloor = folder("Floor")
block(fFloor, "Floor", Vector3.new(0, -0.5, 0), Vector3.new(LEN, 1, WID), DARK)
local fWalls = folder("Perimeter")
block(fWalls, "WallNorth", Vector3.new(0, WALL_H / 2, WID / 2), Vector3.new(LEN, WALL_H, 2), GRAY)
block(fWalls, "WallSouth", Vector3.new(0, WALL_H / 2, -WID / 2), Vector3.new(LEN, WALL_H, 2), GRAY)
block(fWalls, "WallWest", Vector3.new(-LEN / 2, WALL_H / 2, 0), Vector3.new(2, WALL_H, WID), GRAY)
block(fWalls, "WallEast", Vector3.new(LEN / 2, WALL_H / 2, 0), Vector3.new(2, WALL_H, WID), GRAY)

-- lane dividers: two segmented walls -> Left / Mid / Right, symmetric, with crossing gaps
local fLanes = folder("LaneDividers")
local DIV_H = 11
for _, z in ipairs({ -21.5, 21.5 }) do
	for _, x in ipairs({ -63, -21, 21, 63 }) do
		block(fLanes, "Divider", Vector3.new(x, DIV_H / 2, z), Vector3.new(26, DIV_H, 3), GRAY)
	end
end

-- command posts, mirrored: side -1 = Red (west), +1 = Blue (east)
local function buildBase(side: number, teamColor: Color3, teamName: string)
	local f = folder(teamName .. "Base")
	block(f, "Platform", Vector3.new(side * 118, 1, 0), Vector3.new(28, 2, 70), GRAY, Enum.Material.Metal)
	local tower = block(f, "CommsTower", Vector3.new(side * 125, 16, 0), Vector3.new(9, 32, 9), teamColor, Enum.Material.Metal)
	tower:SetAttribute("Team", teamName)
	block(f, "CommsTowerTip", Vector3.new(side * 125, 33.5, 0), Vector3.new(3, 5, 3), teamColor, Enum.Material.Neon)
	local qm = block(f, "Quartermaster", Vector3.new(side * 116, 5.5, 24), Vector3.new(7, 7, 7), AMBER, Enum.Material.Metal)
	qm:SetAttribute("Team", teamName)
	for i, dz in ipairs({ -12, 12 }) do
		local sp = Instance.new("SpawnLocation")
		sp.Name = "Spawn" .. teamName .. i
		sp.Anchored = true
		sp.Size = Vector3.new(6, 1, 6)
		sp.CFrame = CFrame.new(side * 108, 2.5, dz)
		sp.Color = teamColor
		sp.Material = Enum.Material.SmoothPlastic
		sp.Neutral = false
		sp.TeamColor = BrickColor.new(teamColor)
		sp.Duration = 0
		sp.Parent = f
	end
	-- cover at the base mouth so you are not shot the moment you leave spawn
	block(f, "BaseCoverA", Vector3.new(side * 92, 3, -30), Vector3.new(4, 6, 14), GRAY)
	block(f, "BaseCoverB", Vector3.new(side * 92, 3, 30), Vector3.new(4, 6, 14), GRAY)
end
buildBase(-1, RED, "Red")
buildBase(1, BLUE, "Blue")

-- cover layer
local fCover = folder("Cover")
local function crate(x: number, z: number, s: number?)
	local size = s or 4
	block(fCover, "Crate", Vector3.new(x, size / 2, z), Vector3.new(size, size, size), WOOD, Enum.Material.WoodPlanks)
end
local function crateSym(x: number, z: number, s: number?) -- mirror across X=0
	crate(x, z, s)
	crate(-x, z, s)
end

-- mid lane (Z=0)
crate(0, 0, 6)
crateSym(20, 9, 4)
crateSym(20, -9, 4)
crateSym(74, 0, 4)
-- left lane (Z=-43)
crate(0, -43, 5)
crateSym(24, -43, 5)
crateSym(60, -43, 4)
-- right lane (Z=43)
crate(0, 43, 5)
crateSym(24, 43, 5)
crateSym(60, 43, 4)

-- watchtowers flanking the mid lane; ramp faces each team's own base
local function watchtower(cx: number, cz: number, side: number)
	for _, dx in ipairs({ -3.5, 3.5 }) do
		for _, dz in ipairs({ -3.5, 3.5 }) do
			block(fCover, "TowerLeg", Vector3.new(cx + dx, 4.5, cz + dz), Vector3.new(1, 9, 1), DARK, Enum.Material.Metal)
		end
	end
	block(fCover, "TowerDeck", Vector3.new(cx, 9.5, cz), Vector3.new(10, 1, 10), GRAY, Enum.Material.Metal)
	block(fCover, "TowerRail", Vector3.new(cx, 11, cz - 4.75), Vector3.new(10, 2, 0.5), GRAY)
	block(fCover, "TowerRail", Vector3.new(cx, 11, cz + 4.75), Vector3.new(10, 2, 0.5), GRAY)
	block(fCover, "TowerRail", Vector3.new(cx - 4.75 * side, 11, cz), Vector3.new(0.5, 2, 10), GRAY)
	local a = Vector3.new(cx + side * 16, 0.5, cz)
	local b = Vector3.new(cx + side * 5, 9.5, cz)
	local mid = (a + b) / 2
	local len = (b - a).Magnitude
	local r = Instance.new("Part")
	r.Name = "TowerRamp"
	r.Anchored = true
	r.Size = Vector3.new(6, 1, len)
	r.CFrame = CFrame.lookAt(mid, b)
	r.Color = DARK
	r.Material = Enum.Material.Metal
	r.Parent = fCover
end
watchtower(50, 0, 1)
watchtower(-50, 0, -1)

-- hidden dog portrait: tucked under the east watchtower deck, found by standing under the
-- tower and looking up. Easter egg, keep it. See also the squad photo in the practice range.
do
	block(fCover, "DogPortraitFrame", Vector3.new(50, 8.95, 0), Vector3.new(4.4, 0.2, 4.4), Color3.fromRGB(28, 28, 32), Enum.Material.SmoothPlastic)
	local photo = block(fCover, "DogPortrait", Vector3.new(50, 8.83, 0), Vector3.new(4, 0.15, 4), Color3.fromRGB(18, 18, 22), Enum.Material.SmoothPlastic)
	game:GetService("CollectionService"):AddTag(photo, "DogPortrait") -- shooting it wipes your coins
	local d = Instance.new("Decal")
	d.Texture = "rbxassetid://88147646373265"
	d.Face = Enum.NormalId.Bottom -- faces down, seen by looking up from under the deck
	d.Parent = photo
end

-- second hidden dog portrait under the WEST watchtower deck (the other one is under the east)
do
	block(fCover, "DogPortraitFrame2", Vector3.new(-50, 8.95, 0), Vector3.new(4.4, 0.2, 4.4), Color3.fromRGB(28, 28, 32), Enum.Material.SmoothPlastic)
	local photo = block(fCover, "DogPortrait2", Vector3.new(-50, 8.83, 0), Vector3.new(4, 0.15, 4), Color3.fromRGB(18, 18, 22), Enum.Material.SmoothPlastic)
	game:GetService("CollectionService"):AddTag(photo, "DogPortrait") -- shooting it wipes your coins
	local d = Instance.new("Decal")
	d.Texture = "rbxassetid://89437952628120"
	d.Face = Enum.NormalId.Bottom
	d.Parent = photo
end

-- teams (names match Config.Teams[*].Name so the combat team checks line up)
local function ensureTeam(name: string, color: Color3)
	local t = Teams:FindFirstChild(name)
	if not t then
		t = Instance.new("Team")
		t.Name = name
		t.Parent = Teams
	end
	;(t :: Team).TeamColor = BrickColor.new(color)
	;(t :: Team).AutoAssignable = true
end
ensureTeam("Red Squad", RED)
ensureTeam("Blue Squad", BLUE)

print("[Arena] blockout built: " .. #arena:GetDescendants() .. " parts")
