--!strict
-- Applies the uploaded military-paintball graphics to the arena built by
-- arena_blockout.luau. Run in Studio (weppy execute_luau or the command bar) after the
-- blockout exists. Re-runnable: it clears its own previously added art first, so tweak
-- and run again freely. All art lives under Workspace.Arena (not Rojo-synced), so this
-- script is the git record of both the asset IDs and where each graphic goes.

local Workspace = game:GetService("Workspace")
local arena = Workspace:WaitForChild("Arena")

-- uploaded Roblox asset IDs (Splat Ops art set)
local ASSET = {
	wallConcrete = "rbxassetid://109486455531656",
	floorMetal = "rbxassetid://86353199191650",
	redEmblem = "rbxassetid://99638679321458",
	blueEmblem = "rbxassetid://106128359802666",
	signLeft = "rbxassetid://129952796024219",
	signMid = "rbxassetid://136535698183332",
	signRight = "rbxassetid://133298225418323",
	quartermaster = "rbxassetid://86647313371824",
	commsTower = "rbxassetid://94227551691018",
	spawnRed = "rbxassetid://91916287298472",
	spawnBlue = "rbxassetid://100798919456363",
	crate = "rbxassetid://85914940942687",
	poster = "rbxassetid://123265496889577",
}

-- clear previously applied art so re-runs are clean
local oldFolder = arena:FindFirstChild("ArtProps")
if oldFolder then
	oldFolder:Destroy()
end
for _, d in arena:GetDescendants() do
	if (d:IsA("Decal") or d:IsA("Texture")) and d:GetAttribute("SplatOpsArt") == true then
		d:Destroy()
	end
end
local artFolder = Instance.new("Folder")
artFolder.Name = "ArtProps"
artFolder.Parent = arena

local function decal(part: Instance, face: Enum.NormalId, texture: string)
	local d = Instance.new("Decal")
	d.Texture = texture
	d.Face = face
	d:SetAttribute("SplatOpsArt", true)
	d.Parent = part
end

local function tiled(part: Instance, face: Enum.NormalId, texture: string, studs: number)
	local t = Instance.new("Texture")
	t.Texture = texture
	t.Face = face
	t.StudsPerTileU = studs
	t.StudsPerTileV = studs
	t:SetAttribute("SplatOpsArt", true)
	t.Parent = part
end

-- a flat sign board mounted in the world to carry a decal
local function board(name: string, cframe: CFrame, size: Vector3, face: Enum.NormalId, texture: string)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CastShadow = false
	p.Size = size
	p.CFrame = cframe
	p.Color = Color3.fromRGB(38, 40, 44)
	p.Material = Enum.Material.SmoothPlastic
	p.Parent = artFolder
	decal(p, face, texture)
end

-- perimeter walls: tiled concrete on the inward face
local walls = arena:WaitForChild("Perimeter")
tiled(walls.WallNorth, Enum.NormalId.Front, ASSET.wallConcrete, 24) -- z=+65, inward -Z
tiled(walls.WallSouth, Enum.NormalId.Back, ASSET.wallConcrete, 24) -- z=-65, inward +Z
tiled(walls.WallWest, Enum.NormalId.Right, ASSET.wallConcrete, 24) -- x=-130, inward +X
tiled(walls.WallEast, Enum.NormalId.Left, ASSET.wallConcrete, 24) -- x=+130, inward -X

-- floor: tiled metal on top
tiled(arena:WaitForChild("Floor"):WaitForChild("Floor"), Enum.NormalId.Top, ASSET.floorMetal, 24)

-- squad emblems on each base's back wall, behind the tower
board("RedBanner", CFrame.new(-128.6, 18, 0), Vector3.new(0.4, 16, 18), Enum.NormalId.Right, ASSET.redEmblem)
board("BlueBanner", CFrame.new(128.6, 18, 0), Vector3.new(0.4, 16, 18), Enum.NormalId.Left, ASSET.blueEmblem)

-- facility poster on the south wall near the red base
board("Poster", CFrame.new(-60, 12, -63.6), Vector3.new(12, 18, 0.4), Enum.NormalId.Back, ASSET.poster)

-- sector signs at the red base mouth, one per lane (faces red spawn, -X)
board("SignLeft", CFrame.new(-80, 8, -43), Vector3.new(0.4, 9, 12), Enum.NormalId.Left, ASSET.signLeft)
board("SignMid", CFrame.new(-80, 8, 0), Vector3.new(0.4, 9, 12), Enum.NormalId.Left, ASSET.signMid)
board("SignRight", CFrame.new(-80, 8, 43), Vector3.new(0.4, 9, 12), Enum.NormalId.Left, ASSET.signRight)

-- comms towers and quartermasters: decal on the field-facing side
decal(arena.RedBase.CommsTower, Enum.NormalId.Right, ASSET.commsTower)
decal(arena.BlueBase.CommsTower, Enum.NormalId.Left, ASSET.commsTower)
decal(arena.RedBase.Quartermaster, Enum.NormalId.Right, ASSET.quartermaster)
decal(arena.BlueBase.Quartermaster, Enum.NormalId.Left, ASSET.quartermaster)

-- spawn pads: top decal on each team spawn
for _, ch in arena.RedBase:GetChildren() do
	if ch:IsA("BasePart") and string.find(ch.Name, "SpawnRed") then
		decal(ch, Enum.NormalId.Top, ASSET.spawnRed)
	end
end
for _, ch in arena.BlueBase:GetChildren() do
	if ch:IsA("BasePart") and string.find(ch.Name, "SpawnBlue") then
		decal(ch, Enum.NormalId.Top, ASSET.spawnBlue)
	end
end

-- crates: paint-supply decal on all four sides
for _, ch in arena:WaitForChild("Cover"):GetChildren() do
	if ch.Name == "Crate" and ch:IsA("BasePart") then
		decal(ch, Enum.NormalId.Front, ASSET.crate)
		decal(ch, Enum.NormalId.Back, ASSET.crate)
		decal(ch, Enum.NormalId.Left, ASSET.crate)
		decal(ch, Enum.NormalId.Right, ASSET.crate)
	end
end

print("[Arena] art applied")
