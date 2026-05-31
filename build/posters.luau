-- Mounts the parody recruitment posters: 9 around the arena side walls, 5 in the practice range.
-- Each is a framed board (dark border + poster decal) facing into the room. Re-runnable.
-- Run after arena_blockout + practice_range, via weppy execute_luau.

local Workspace = game:GetService("Workspace")
local arena = Workspace:WaitForChild("Arena")

local old = Workspace:FindFirstChild("Posters")
if old then
	old:Destroy()
end
local folder = Instance.new("Folder")
folder.Name = "Posters"
folder.Parent = Workspace

-- a framed poster at `pos` facing `faceDir` (the direction it should look, into the room)
local function poster(pos: Vector3, w: number, h: number, faceDir: Vector3, id: number)
	local frame = Instance.new("Part")
	frame.Anchored = true
	frame.CanCollide = false
	frame.CastShadow = false
	frame.Size = Vector3.new(w + 0.7, h + 0.7, 0.2)
	frame.Color = Color3.fromRGB(26, 26, 30)
	frame.Material = Enum.Material.SmoothPlastic
	frame.CFrame = CFrame.lookAt(pos, pos + faceDir)
	frame.Parent = folder

	local board = Instance.new("Part")
	board.Anchored = true
	board.CanCollide = false
	board.CastShadow = false
	board.Size = Vector3.new(w, h, 0.3)
	board.Color = Color3.fromRGB(15, 15, 18)
	board.Material = Enum.Material.SmoothPlastic
	board.CFrame = CFrame.lookAt(pos + faceDir * 0.12, pos + faceDir * 0.12 + faceDir)
	board.Parent = folder

	local decal = Instance.new("Decal")
	decal.Texture = "rbxassetid://" .. id
	decal.Face = Enum.NormalId.Front -- Front (-Z) = LookVector = faceDir, i.e. into the room
	decal.Parent = board
end

local NZ = Vector3.new(0, 0, -1)
local PZ = Vector3.new(0, 0, 1)
local NX = Vector3.new(-1, 0, 0)
local PX = Vector3.new(1, 0, 0)

-- ===== arena: 9 posters on the long side walls (z = +-63.5), clear of the bases and dividers =====
-- north wall (faces -z)
poster(Vector3.new(-90, 10, 63.5), 11, 14, NZ, 127064048042220) -- 01 Uncle Sam
poster(Vector3.new(-45, 10, 63.5), 11, 14, NZ, 127892520606244) -- 04 Few/Proud
poster(Vector3.new(0, 10, 63.5), 11, 14, NZ, 124470750860381) -- 05 Aim High
poster(Vector3.new(45, 10, 63.5), 11, 14, NZ, 102079109973019) -- 07 Loose Lips
poster(Vector3.new(90, 10, 63.5), 11, 14, NZ, 77129957863409) -- 08 Join Squad
-- south wall (faces +z)
poster(Vector3.new(-60, 10, -63.5), 11, 14, PZ, 103103462238479) -- 09 Don't Splat
poster(Vector3.new(-20, 10, -63.5), 11, 14, PZ, 101802051239919) -- 11 Buy More Paint
poster(Vector3.new(20, 10, -63.5), 11, 14, PZ, 118257314100298) -- 12 Defend the Tower
poster(Vector3.new(60, 10, -63.5), 11, 14, PZ, 97908107056429) -- 14 Victory

-- ===== lobby: 5 posters on the practice-range walls =====
local range = Workspace:FindFirstChild("PracticeRange")
if range then
	poster(Vector3.new(51, 9, 300), 6, 8, NX, 73992146327458) -- 02 We Can Splat (east wall)
	poster(Vector3.new(51, 9, 335), 6, 8, NX, 116635200289196) -- 03 Be All You Can Splat (east wall)
	poster(Vector3.new(-51, 9, 305), 6, 8, PX, 102966082698925) -- 06 Keep Calm (west wall)
	poster(Vector3.new(-51, 9, 335), 6, 8, PX, 129607120237945) -- 10 Army of Fun (west wall)
	poster(Vector3.new(-14, 8, 243.5), 6, 8, PZ, 106205773525895) -- 13 Teamwork (south wall, behind spawn)
end

print("[Posters] mounted: 9 arena, 5 lobby")
