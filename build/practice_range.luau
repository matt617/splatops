--!strict
-- Lobby practice range: a warm-up hall north of the arena where players learn the controls
-- and test every marker before a match. Four distance lanes, one per weapon style:
--   CQB (Scattergun), Standard (Assault Marker), Long Range (Recon), Mortar Pit (lob).
-- Targets are static themed boards tagged "PracticeTarget"; the server (PracticeRange.server)
-- counts a splat the moment a shot lands on one. A wall rack hands out the markers to test
-- (WeaponRackService). Neutral lobby spawn, a Start Match pad, cover, and signage.
-- Gray-box now; SurfaceGui placeholders mark where the uploaded decals go in the art pass.
-- Run in Studio after the arena exists; re-runnable.

local Workspace = game:GetService("Workspace")
local Teams = game:GetService("Teams")
local CollectionService = game:GetService("CollectionService")

local old = Workspace:FindFirstChild("PracticeRange")
if old then
	old:Destroy()
end
local R = Instance.new("Folder")
R.Name = "PracticeRange"
R.Parent = Workspace

local GRAY = Color3.fromRGB(120, 124, 130)
local DARK = Color3.fromRGB(84, 88, 94)
local STEEL = Color3.fromRGB(70, 74, 80)
local OLIVE = Color3.fromRGB(96, 104, 76)
local WOOD = Color3.fromRGB(116, 92, 60)

local function block(name: string, pos: Vector3, size: Vector3, color: Color3?, mat: Enum.Material?, parent: Instance?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = CFrame.new(pos)
	p.Color = color or GRAY
	p.Material = mat or Enum.Material.Concrete
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent or R
	return p
end

-- a flat text label on one face: the gray-box stand-in for a decal we will upload later
local function label(part: BasePart, face: Enum.NormalId, text: string, color: Color3?)
	local sg = Instance.new("SurfaceGui")
	sg.Face = face
	sg.Parent = part
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Text = text
	t.TextColor3 = color or Color3.fromRGB(255, 230, 90)
	t.Font = Enum.Font.GothamBlack
	t.TextScaled = true
	t.Parent = sg
end

-- the uploaded paintball target face, applied as a decal to each target part
local BULLSEYE_ID = "rbxassetid://77350606379459"
local function bullseye(part: BasePart, face: Enum.NormalId)
	local d = Instance.new("Decal")
	d.Texture = BULLSEYE_ID
	d.Face = face
	d.Parent = part
end

-- a static target board on a stand; tagged so combat counts a hit. Faces south (the shooter).
local function target(name: string, pos: Vector3, size: Vector2, parent: Instance)
	local board = Instance.new("Part")
	board.Name = name
	board.Anchored = true
	board.Size = Vector3.new(size.X, size.Y, 0.5)
	board.CFrame = CFrame.new(pos)
	board.Color = Color3.fromRGB(54, 58, 64)
	board.Material = Enum.Material.SmoothPlastic
	board.Parent = parent
	bullseye(board, Enum.NormalId.Front) -- Front (-Z) faces the firing line to the south
	CollectionService:AddTag(board, "PracticeTarget")
	-- stand
	block(name .. "Post", pos - Vector3.new(0, size.Y / 2 + 1.2, 0), Vector3.new(0.6, 2.4, 0.6), STEEL, Enum.Material.Metal, parent)
end

-- a horizontal target pad (for the lobbed mortar); bullseye on top, tagged.
local function pad(name: string, pos: Vector3, size: number, parent: Instance)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = Vector3.new(size, 0.4, size)
	p.CFrame = CFrame.new(pos)
	p.Color = Color3.fromRGB(54, 58, 64)
	p.Material = Enum.Material.SmoothPlastic
	p.Parent = parent
	bullseye(p, Enum.NormalId.Top)
	CollectionService:AddTag(p, "PracticeTarget")
end

-- ===== shell =====
block("Floor", Vector3.new(0, -0.5, 300), Vector3.new(104, 1, 116), DARK)
block("WallN", Vector3.new(0, 10, 358), Vector3.new(104, 20, 2), GRAY)
block("WallS", Vector3.new(0, 10, 242), Vector3.new(104, 20, 2), GRAY)
block("WallW", Vector3.new(-52, 10, 300), Vector3.new(2, 20, 116), GRAY)
block("WallE", Vector3.new(52, 10, 300), Vector3.new(2, 20, 116), GRAY)

-- firing line stripe across the floor
local stripe = block("FiringLine", Vector3.new(0, 0.05, 266), Vector3.new(88, 0.1, 1.2), Color3.fromRGB(255, 210, 70), Enum.Material.Neon)
stripe.CanCollide = false

-- ===== neutral lobby spawn (players land here, off any team), facing the lanes =====
local sp = Instance.new("SpawnLocation")
sp.Name = "LobbySpawn"
sp.Anchored = true
sp.Size = Vector3.new(10, 1, 10)
sp.CFrame = CFrame.new(0, 0.5, 252) * CFrame.Angles(0, math.pi, 0) -- look north toward the lanes
sp.Color = Color3.fromRGB(80, 170, 90)
sp.Material = Enum.Material.SmoothPlastic
sp.Neutral = true
sp.Duration = 0
sp.Parent = R

-- ===== Start Match pad (to the right of spawn) =====
local startPad = block("StartPad", Vector3.new(20, 0.5, 254), Vector3.new(14, 1, 9), Color3.fromRGB(70, 200, 100), Enum.Material.Neon)
startPad.CanCollide = true
label(startPad, Enum.NormalId.Top, "▶  START MATCH", Color3.fromRGB(255, 255, 255))

-- ===== weapon rack (west alcove): grab any marker to test, free, lobby only =====
local rack = Instance.new("Folder")
rack.Name = "WeaponRack"
rack.Parent = R
-- backing panel + big sign
-- plain backing panel the markers mount on; the ARMORY sign sits above so the mounts never cover it
local rackPanel = block("RackPanel", Vector3.new(-50.5, 4, 268), Vector3.new(1, 8, 26), STEEL, Enum.Material.DiamondPlate)
local armorySign = block("ArmorySign", Vector3.new(-50.5, 10.5, 268), Vector3.new(1, 4, 11), Color3.fromRGB(40, 43, 48), Enum.Material.SmoothPlastic)
do
	local d = Instance.new("Decal")
	d.Texture = "rbxassetid://89863094908814" -- ARMORY sign
	d.Face = Enum.NormalId.Right -- Right (+X) faces the room
	d.Parent = armorySign
end
local rackWeapons = { "AssaultMarker", "Scattergun", "ReconMarker", "Mortar" }
-- cartoony weapon cards shown on each mount (Right face, facing the room)
local rackCards = {
	AssaultMarker = "rbxassetid://139159382174571",
	ReconMarker = "rbxassetid://121820949874382",
	Scattergun = "rbxassetid://86080782756370",
	Mortar = "rbxassetid://128414709052987",
}
for i, weaponName in ipairs(rackWeapons) do
	local z = 258 + (i - 1) * 6.5
	local mount = Instance.new("Part")
	mount.Name = "Mount_" .. weaponName
	mount.Anchored = true
	mount.Size = Vector3.new(0.6, 3.6, 5.2)
	mount.CFrame = CFrame.new(-49.7, 4.7, z)
	mount.Color = Color3.fromRGB(40, 43, 48)
	mount.Material = Enum.Material.Metal
	mount:SetAttribute("Weapon", weaponName) -- WeaponRackService reads this to wire the prompt
	mount.Parent = rack
	local card = Instance.new("Decal")
	card.Texture = rackCards[weaponName]
	card.Face = Enum.NormalId.Right -- Right (+X) faces into the room
	card.Parent = mount
end
-- floor cue pointing players at the rack
local cue = block("ArmoryCue", Vector3.new(-30, 0.05, 258), Vector3.new(14, 0.1, 4), Color3.fromRGB(196, 158, 70), Enum.Material.Neon)
cue.CanCollide = false
label(cue, Enum.NormalId.Top, "◄ ARMORY", Color3.fromRGB(30, 30, 30))

-- ===== lanes =====
local T = Instance.new("Folder")
T.Name = "Targets"
T.Parent = R

-- lane dividers (low, so you can see across)
for _, x in ipairs({ -20, 1, 23 }) do
	block("Divider", Vector3.new(x, 2, 312), Vector3.new(0.6, 4, 92), DARK, Enum.Material.Metal)
end

-- north-wall banner per lane. Front (-Z) faces the room. With an asset id it shows the real
-- banner decal; without one it falls back to the gray-box text placeholder.
local function laneBanner(x: number, text: string, assetId: number?)
	-- ~16:9 board so the banner art is not squished
	local b = block("Banner", Vector3.new(x, 11, 357), Vector3.new(16, 9, 0.4), Color3.fromRGB(40, 43, 48), Enum.Material.SmoothPlastic)
	if assetId then
		local d = Instance.new("Decal")
		d.Texture = "rbxassetid://" .. assetId
		d.Face = Enum.NormalId.Front
		d.Parent = b
	else
		label(b, Enum.NormalId.Front, text, Color3.fromRGB(120, 210, 255))
	end
end

-- small distance marker post in front of each lane's targets
local function distanceMarker(x: number, z: number, text: string)
	local post = block("DistPost", Vector3.new(x, 1.5, z), Vector3.new(3, 1.6, 0.3), Color3.fromRGB(255, 210, 70), Enum.Material.SmoothPlastic, T)
	label(post, Enum.NormalId.Front, text, Color3.fromRGB(30, 30, 30))
end

-- Lane A: CQB / Scattergun (close, three boards)
laneBanner(-30, "CQB\nSCATTERGUN", 81911169212899)
distanceMarker(-30, 278, "~15m")
target("CqbTargetL", Vector3.new(-38, 4.5, 290), Vector2.new(6, 6), T)
target("CqbTargetM", Vector3.new(-30, 4.5, 292), Vector2.new(6, 6), T)
target("CqbTargetR", Vector3.new(-22, 4.5, 290), Vector2.new(6, 6), T)

-- Lane B: Standard / Assault Marker (mid, two boards)
laneBanner(-10, "STANDARD\nASSAULT", 91622776109553)
distanceMarker(-10, 286, "~30m")
target("StdTargetNear", Vector3.new(-13, 4.5, 304), Vector2.new(6, 6), T)
target("StdTargetFar", Vector3.new(-7, 4.5, 320), Vector2.new(5, 5), T)

-- Lane C: Long Range / Recon (far, small board)
laneBanner(12, "LONG RANGE\nRECON", 77383142939055)
distanceMarker(12, 300, "~65m")
target("LongTarget", Vector3.new(12, 5, 350), Vector2.new(4.5, 4.5), T)

-- Lane D: Mortar Pit (lob over a sandbag wall onto ground pads)
laneBanner(34, "MORTAR PIT\nLOB IT", 108744903192699)
local sandbag = block("SandbagWall", Vector3.new(34, 2.5, 300), Vector3.new(20, 5, 2), OLIVE, Enum.Material.Sand, T)
label(sandbag, Enum.NormalId.Front, "LOB OVER", Color3.fromRGB(245, 245, 235))
pad("MortarPadL", Vector3.new(28, 0.25, 322), 7, T)
pad("MortarPadR", Vector3.new(40, 0.25, 330), 7, T)
pad("MortarPadC", Vector3.new(34, 0.25, 344), 7, T)

-- hidden squad photo: on the back (north) face of the sandbag wall, only seen by players who
-- wander downrange into the mortar pit. Easter egg, the kids as their Roblox avatars. Keep it.
do
	block("SquadPhotoFrame", Vector3.new(38, 3, 301.1), Vector3.new(5.6, 5.6, 0.2), Color3.fromRGB(28, 28, 32), Enum.Material.SmoothPlastic, T)
	local photo = block("SquadPhoto", Vector3.new(38, 3, 301.3), Vector3.new(5, 5, 0.15), Color3.fromRGB(18, 18, 22), Enum.Material.SmoothPlastic, T)
	local decal = Instance.new("Decal")
	decal.Texture = "rbxassetid://101017294556294"
	decal.Face = Enum.NormalId.Back -- Back (+Z) faces into the pit to the north
	decal.Parent = photo
end

-- ===== cover + props near the firing line =====
block("CoverL", Vector3.new(-12, 2, 274), Vector3.new(5, 4, 5), WOOD, Enum.Material.WoodPlanks)
block("CoverR", Vector3.new(12, 2, 274), Vector3.new(5, 4, 5), WOOD, Enum.Material.WoodPlanks)
-- a couple of barrels for set dressing
for _, x in ipairs({ -24, 26 }) do
	local barrel = Instance.new("Part")
	barrel.Name = "Barrel"
	barrel.Shape = Enum.PartType.Cylinder
	barrel.Anchored = true
	barrel.Size = Vector3.new(4, 2.6, 2.6)
	barrel.CFrame = CFrame.new(x, 2, 270) * CFrame.Angles(0, 0, math.rad(90))
	barrel.Color = OLIVE
	barrel.Material = Enum.Material.Metal
	barrel.Parent = R
end

-- ===== signage =====
local sign = block("Sign", Vector3.new(0, 17, 357), Vector3.new(30, 4, 0.4), DARK, Enum.Material.SmoothPlastic)
label(sign, Enum.NormalId.Front, "PRACTICE RANGE", Color3.fromRGB(255, 230, 90))
-- briefing board on the east wall: the RANGE RULES poster (portrait), facing the room
local briefing = block("BriefingBoard", Vector3.new(51, 7.5, 270), Vector3.new(0.4, 13, 9), Color3.fromRGB(28, 30, 34), Enum.Material.SmoothPlastic)
do
	local d = Instance.new("Decal")
	d.Texture = "rbxassetid://137260448358919"
	d.Face = Enum.NormalId.Left -- Left (-X) faces the room
	d.Parent = briefing
end

-- hidden dog portrait: low on the south wall behind the lobby spawn, found by turning around
-- on spawn. Easter egg, keep it. (The kids' squad photo is hidden in the mortar pit.)
do
	block("DogPortraitFrame", Vector3.new(12, 3, 243.0), Vector3.new(4.4, 4.4, 0.2), Color3.fromRGB(28, 28, 32), Enum.Material.SmoothPlastic)
	local photo = block("DogPortrait", Vector3.new(12, 3, 243.2), Vector3.new(4, 4, 0.15), Color3.fromRGB(18, 18, 22), Enum.Material.SmoothPlastic)
	local d = Instance.new("Decal")
	d.Texture = "rbxassetid://134540405441809"
	d.Face = Enum.NormalId.Back -- Back (+Z) faces into the room
	d.Parent = photo
end

-- ===== light strips =====
for _, z in ipairs({ 270, 300, 330 }) do
	local strip = block("Light", Vector3.new(0, 19.4, z), Vector3.new(90, 0.3, 2), Color3.fromRGB(255, 250, 235), Enum.Material.Neon)
	strip.CanCollide = false
	local pl = Instance.new("PointLight")
	pl.Range = 40
	pl.Brightness = 1.4
	pl.Parent = strip
end

-- players stay neutral in the lobby until match mode assigns teams
for _, t in Teams:GetChildren() do
	if t:IsA("Team") then
		t.AutoAssignable = false
	end
end

print("[PracticeRange] built: 4 lanes, weapon rack, static targets")
