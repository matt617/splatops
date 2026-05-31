-- Places the uploaded 3D prop models into the arena, over the existing gray-box so gameplay
-- never depends on the meshes. The comms towers, mid watchtowers and quartermaster kiosks keep
-- their gray-box parts as the functional layer (invisible but still colliding / still the tower
-- hitbox / still holding the shop prompt); the models sit on top as visuals. Base crates become
-- random solid stacks. Standalone cover (drum, sandbag, concrete, hesco) is added as solid props.
-- Every part is colored from its name (the models ship with named parts: gunmetal, rubber,
-- screen, wood, cabinet, etc.) so the props read with their intended colors without textures.
-- Re-runnable. Run AFTER arena_blockout (and practice_range), via weppy execute_luau.

local Workspace = game:GetService("Workspace")
local InsertService = game:GetService("InsertService")

local RED = Color3.fromRGB(220, 50, 50)
local BLUE = Color3.fromRGB(50, 100, 220)
local STEEL = Color3.fromRGB(74, 78, 86)
local DARKMETAL = Color3.fromRGB(46, 49, 55)
local BLACK = Color3.fromRGB(26, 26, 30)
local WOOD = Color3.fromRGB(125, 96, 56)
local OLIVE = Color3.fromRGB(106, 112, 78)
local CONCRETE = Color3.fromRGB(150, 154, 160)
local TAN = Color3.fromRGB(198, 178, 134)
local GLASS = Color3.fromRGB(120, 170, 235)
local BEACON = Color3.fromRGB(255, 150, 40)

local IDS = {
	tower = 103302952105387, watchtower = 133320127977802, crate = 136790839484466, drum = 123891449640864,
	sandbag = 98725300972524, concrete = 94985129662656, hesco = 78963301407705, kiosk = 78453486089917,
}

local UPRIGHT = CFrame.Angles(math.pi / 2, 0, 0) -- tower/watchtower/drum import top-toward-(-Z)

local arena = Workspace:WaitForChild("Arena")
local old = Workspace:FindFirstChild("Props")
if old then old:Destroy() end
local propsFolder = Instance.new("Folder")
propsFolder.Name = "Props"
propsFolder.Parent = Workspace

local cache = {}
local function loadModel(key)
	local tmpl = cache[key]
	if not tmpl then
		local ok, m = pcall(function() return InsertService:LoadAsset(IDS[key]) end)
		if not ok or not m then return nil end
		cache[key] = m
		tmpl = m
	end
	return tmpl:Clone()
end

local function has(n, s)
	return string.find(n, s, 1, true) ~= nil
end

-- pick a color from a part's name, falling back to the prop's base color
local function paletteColor(name, team, fallback)
	local n = string.lower(name)
	if has(n, "team") then return team or OLIVE end
	if has(n, "glass") or has(n, "lens") then return GLASS end
	if has(n, "beacon") or has(n, "lamp") then return BEACON end
	if has(n, "screen") then return Color3.fromRGB(30, 34, 42) end
	if has(n, "rubber") or has(n, "black") then return BLACK end
	if has(n, "wood") or has(n, "crate") or has(n, "plank") or has(n, "timber") then return WOOD end
	if has(n, "sand") or has(n, "burlap") or has(n, "earth") or has(n, "gabion") then return TAN end
	if has(n, "olive") or has(n, "drab") or has(n, "canvas") then return OLIVE end
	if has(n, "concrete") or has(n, "stone") then return CONCRETE end
	if has(n, "gunmetal") or has(n, "dark") then return DARKMETAL end
	if has(n, "gray") or has(n, "grey") or has(n, "detail") or has(n, "dish") or has(n, "antenna") then return CONCRETE end
	if has(n, "metal") or has(n, "steel") or has(n, "barrel") or has(n, "beam") or has(n, "leg")
		or has(n, "rail") or has(n, "bolt") or has(n, "frame") or has(n, "cap") or has(n, "ring")
		or has(n, "muzzle") or has(n, "lattice") or has(n, "post") or has(n, "rod") then return STEEL end
	return fallback
end

local function finalize(model, collide, query, team, fallback)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = collide
			d.CanQuery = query
			d.CastShadow = false
			local n = string.lower(d.Name)
			d.Color = paletteColor(d.Name, team, fallback)
			if has(n, "beacon") or has(n, "lamp") then
				d.Material = Enum.Material.Neon
			end
		end
	end
	model.Parent = propsFolder
end

local function place(key, basePos, targetHeight, tallExtent, yawDeg, needsUpright, collide, query, team, fallback)
	local model = loadModel(key)
	if not model then return nil end
	model.WorldPivot = model:GetBoundingBox()
	model:ScaleTo(targetHeight / tallExtent)
	local rot = CFrame.Angles(0, math.rad(yawDeg), 0) * (needsUpright and UPRIGHT or CFrame.identity)
	model:PivotTo(CFrame.new(basePos + Vector3.new(0, targetHeight / 2, 0)) * rot)
	finalize(model, collide, query, team, fallback)
	return model
end

-- hide a gray-box part we replace, including its arena-art decals, keeping collision/query
local function hide(part)
	part.Transparency = 1
	for _, c in part:GetChildren() do
		if c:IsA("Decal") or c:IsA("Texture") then
			c.Transparency = 1
		elseif c:IsA("SurfaceGui") then
			c.Enabled = false
		end
	end
end

-- ===== comms towers: model visual over the invisible gray-box hitbox =====
for _, base in arena:GetChildren() do
	local tower = base:FindFirstChild("CommsTower")
	if tower and tower:IsA("BasePart") then
		local owner = tower:GetAttribute("Team")
		local team = (owner == "Red" and RED) or (owner == "Blue" and BLUE) or nil
		hide(tower)
		local tip = base:FindFirstChild("CommsTowerTip")
		if tip and tip:IsA("BasePart") then hide(tip) end
		local sign = tower.Position.X > 0 and 1 or -1
		place("tower", Vector3.new(tower.Position.X - sign * 8, 0, tower.Position.Z), 32, 8.59, tower.Position.X > 0 and 180 or 0, true, false, false, team, STEEL)
	end
end

local cover = arena:FindFirstChild("Cover")
if cover then
	-- ===== mid watchtowers: model visual over the climbable gray-box =====
	for _, deck in cover:GetChildren() do
		if deck.Name == "TowerDeck" and deck:IsA("BasePart") then
			local cx, cz = deck.Position.X, deck.Position.Z
			-- keep the RAMP and DECK visible+solid so players have a clear way up and a floor to
			-- stand on; only hide the gray legs/rails. The model sits over this as the visual.
			for _, p in cover:GetChildren() do
				if p:IsA("BasePart") and (p.Name == "TowerLeg" or p.Name == "TowerRail") then
					if math.abs(p.Position.X - cx) < 12 and math.abs(p.Position.Z - cz) < 12 then
						p.Transparency = 1
					end
				end
			end
			place("watchtower", Vector3.new(cx, 0, cz), 13, 5.63, 0, true, false, false, cx > 0 and BLUE or RED, STEEL)
		end
	end

	-- ===== base crates: random 1-3 high cross-stacks (the stack IS the cover) =====
	for _, crate in cover:GetChildren() do
		if crate.Name == "Crate" and crate:IsA("BasePart") then
			local size = crate.Size.X
			crate.Transparency = 1
			crate.CanCollide = false
			for _, c in crate:GetChildren() do
				if c:IsA("Decal") or c:IsA("Texture") then c.Transparency = 1 elseif c:IsA("SurfaceGui") then c.Enabled = false end
			end
			local footprint = math.clamp(size * 1.15, 4.5, 6.5)
			local crateH = 0.96 * (footprint / 2.98)
			local stack = math.random(2, 3)
			local groundY = crate.Position.Y - size / 2
			for i = 1, stack do
				local m = loadModel("crate")
				if m then
					m.WorldPivot = m:GetBoundingBox()
					m:ScaleTo(footprint / 2.98)
					local jx = (math.random() - 0.5) * 0.5
					local jz = (math.random() - 0.5) * 0.5
					local yaw = math.random(-14, 14) + (i % 2 == 0 and 90 or 0)
					m:PivotTo(CFrame.new(crate.Position.X + jx, groundY + crateH * (i - 0.5), crate.Position.Z + jz) * CFrame.Angles(0, math.rad(yaw), 0))
					finalize(m, true, true, OLIVE, WOOD)
					m.Parent = propsFolder
				end
			end
		end
	end
end

-- ===== quartermaster kiosks: model at each base's prompt part =====
for _, base in arena:GetChildren() do
	local qm = base:FindFirstChild("Quartermaster")
	if qm and qm:IsA("BasePart") then
		hide(qm)
		local team = base.Name == "RedBase" and RED or (base.Name == "BlueBase" and BLUE or nil)
		place("kiosk", Vector3.new(qm.Position.X, 0, qm.Position.Z), 6.5, 2.39, qm.Position.X > 0 and 180 or 0, false, true, true, team, OLIVE)
	end
end

-- ===== extra cover dressing (solid props, symmetric) =====
local function coverPair(key, x, z, h, ext, yaw, upright, fallback)
	place(key, Vector3.new(x, 0, z), h, ext, yaw, upright, true, true, nil, fallback)
	place(key, Vector3.new(-x, 0, z), h, ext, yaw, upright, true, true, nil, fallback)
end
coverPair("drum", 100, 28, 3.6, 1.22, 0, true, STEEL)
coverPair("drum", 100, -28, 3.6, 1.22, 0, true, STEEL)
coverPair("concrete", 18, 34, 2.8, 1.10, 90, false, CONCRETE)
coverPair("concrete", 18, -34, 2.8, 1.10, 90, false, CONCRETE)
coverPair("hesco", 70, 22, 2.8, 1.04, 0, false, TAN)
coverPair("hesco", 70, -22, 2.8, 1.04, 0, false, TAN)

-- sandbags: one low row is puny, so stack 3 rows into a proper wall on each side of mid
local function sandbagWall(x, z)
	local s = 6.5 / 4.25 -- target row length / model long extent
	local rowH = 0.52 * s
	for side = 1, -1, -2 do
		for r = 0, 2 do
			local m = loadModel("sandbag")
			if m then
				m.WorldPivot = m:GetBoundingBox()
				m:ScaleTo(s)
				m:PivotTo(CFrame.new(side * x, rowH * (r + 0.5), z) * CFrame.Angles(0, math.rad((r % 2 == 0) and 0 or 5), 0))
				finalize(m, true, true, nil, TAN)
				m.Parent = propsFolder
			end
		end
	end
end
sandbagWall(40, 0)
sandbagWall(16, 0)

print("[Props] placed with name-based palette coloring")
