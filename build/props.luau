-- Places the uploaded 3D prop models into the arena over the gray-box, so gameplay never depends
-- on the meshes. Comms towers and kiosks keep their gray-box parts as the functional layer
-- (invisible hitbox / prompt holder); watchtowers keep an invisible solid deck plus a climbable
-- truss ladder; base crates become solid stacks; standalone cover sits clear of the lane dividers.
-- Each part gets a color AND a real Roblox material from its name (wood, metal, concrete, sand,
-- fabric, glass) so the props look textured without any uploads. Re-runnable. Run after arena_blockout.

local Workspace = game:GetService("Workspace")
local InsertService = game:GetService("InsertService")

local RED = Color3.fromRGB(220, 50, 50)
local BLUE = Color3.fromRGB(50, 100, 220)
local STEEL = Color3.fromRGB(96, 100, 108)
local DARKMETAL = Color3.fromRGB(54, 57, 64)
local BLACK = Color3.fromRGB(26, 26, 30)
local WOOD = Color3.fromRGB(150, 110, 64)
local OLIVE = Color3.fromRGB(106, 112, 78)
local CONCRETE = Color3.fromRGB(158, 160, 165)
local TAN = Color3.fromRGB(205, 184, 138)
local GLASS = Color3.fromRGB(120, 170, 235)
local BEACON = Color3.fromRGB(255, 150, 40)

local M = Enum.Material

local IDS = {
	tower = 103302952105387, watchtower = 133320127977802, crate = 136790839484466, drum = 123891449640864,
	sandbag = 98725300972524, concrete = 94985129662656, hesco = 78963301407705, kiosk = 78453486089917,
}

local UPRIGHT = CFrame.Angles(math.pi / 2, 0, 0)

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

local function has(n, s) return string.find(n, s, 1, true) ~= nil end

local function paletteColor(name, team, fallback)
	local n = string.lower(name)
	if has(n, "team") then return team or OLIVE end
	if has(n, "glass") or has(n, "lens") then return GLASS end
	if has(n, "beacon") or has(n, "lamp") then return BEACON end
	if has(n, "screen") then return Color3.fromRGB(30, 34, 42) end
	if has(n, "rubber") or has(n, "black") then return BLACK end
	if has(n, "wood") or has(n, "crate") or has(n, "plank") or has(n, "timber") then return WOOD end
	if has(n, "sand") or has(n, "burlap") or has(n, "earth") or has(n, "gabion") then return TAN end
	if has(n, "concrete") or has(n, "stone") then return CONCRETE end
	if has(n, "gunmetal") or has(n, "dark") then return DARKMETAL end
	if has(n, "gray") or has(n, "grey") or has(n, "detail") or has(n, "dish") or has(n, "antenna") then return CONCRETE end
	if has(n, "metal") or has(n, "steel") or has(n, "barrel") or has(n, "beam") or has(n, "leg")
		or has(n, "rail") or has(n, "bolt") or has(n, "frame") or has(n, "cap") or has(n, "ring")
		or has(n, "muzzle") or has(n, "lattice") or has(n, "post") or has(n, "rod") then return STEEL end
	if has(n, "olive") or has(n, "drab") or has(n, "canvas") then return OLIVE end
	return fallback
end

local function paletteMaterial(name)
	local n = string.lower(name)
	if has(n, "glass") or has(n, "lens") then return M.Glass end
	if has(n, "beacon") or has(n, "lamp") then return M.Neon end
	if has(n, "screen") then return M.SmoothPlastic end
	if has(n, "wood") or has(n, "crate") or has(n, "plank") or has(n, "timber") then return M.WoodPlanks end
	if has(n, "sand") or has(n, "burlap") or has(n, "gabion") then return M.Sand end
	if has(n, "concrete") or has(n, "stone") or has(n, "earth") then return M.Concrete end
	if has(n, "canvas") or has(n, "fabric") then return M.Fabric end
	if has(n, "rubber") then return M.SmoothPlastic end
	if has(n, "dish") or has(n, "antenna") or has(n, "detail") then return M.Metal end
	return M.Metal -- structural / unnamed parts read as metal
end

-- force overrides a single color/material onto every part (for props whose parts are not
-- descriptively named, like the bare crates and sandbags)
local function finalize(model, collide, query, team, fallback, force, forceMat)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = collide
			d.CanQuery = query
			d.CastShadow = false
			d.Color = force or paletteColor(d.Name, team, fallback)
			d.Material = forceMat or paletteMaterial(d.Name)
		end
	end
	model.Parent = propsFolder
end

local function place(key, basePos, targetHeight, tallExtent, yawDeg, needsUpright, collide, query, team, fallback, force, forceMat)
	local model = loadModel(key)
	if not model then return nil end
	model.WorldPivot = model:GetBoundingBox()
	model:ScaleTo(targetHeight / tallExtent)
	local rot = CFrame.Angles(0, math.rad(yawDeg), 0) * (needsUpright and UPRIGHT or CFrame.identity)
	model:PivotTo(CFrame.new(basePos + Vector3.new(0, targetHeight / 2, 0)) * rot)
	finalize(model, collide, query, team, fallback, force, forceMat)
	return model
end

local function hide(part)
	part.Transparency = 1
	for _, c in part:GetChildren() do
		if c:IsA("Decal") or c:IsA("Texture") then c.Transparency = 1 elseif c:IsA("SurfaceGui") then c.Enabled = false end
	end
end

-- ===== comms towers =====
for _, base in arena:GetChildren() do
	local tower = base:FindFirstChild("CommsTower")
	if tower and tower:IsA("BasePart") then
		local owner = tower:GetAttribute("Team")
		local team = (owner == "Red" and RED) or (owner == "Blue" and BLUE) or nil
		hide(tower)
		local tip = base:FindFirstChild("CommsTowerTip")
		if tip and tip:IsA("BasePart") then hide(tip) end
		local s = tower.Position.X > 0 and 1 or -1
		place("tower", Vector3.new(tower.Position.X - s * 8, 0, tower.Position.Z), 32, 8.59, tower.Position.X > 0 and 180 or 0, true, false, false, team, STEEL)
	end
end

local cover = arena:FindFirstChild("Cover")
if cover then
	-- ===== watchtowers: model is the visual; you stand on an invisible floor at the platform
	-- height (under the roof), and a wood truss tops out there so you cannot overshoot to the roof.
	local platformY = 7.5 -- standing height inside the tower; tune if you stand too high/low
	for _, deck in cover:GetChildren() do
		if deck.Name == "TowerDeck" and deck:IsA("BasePart") then
			local cx, cz = deck.Position.X, deck.Position.Z
			local s = cx > 0 and 1 or -1
			for _, p in cover:GetChildren() do
				if p:IsA("BasePart") and (p.Name == "TowerLeg" or p.Name == "TowerRail" or p.Name == "TowerRamp" or p.Name == "TowerDeck") then
					if math.abs(p.Position.X - cx) < 14 and math.abs(p.Position.Z - cz) < 14 then
						p.Transparency = 1
						p.CanCollide = false -- the invisible floor below provides footing now
					end
				end
			end
			local floor = Instance.new("Part")
			floor.Size = Vector3.new(6, 0.5, 6)
			floor.Anchored = true
			floor.CanCollide = true
			floor.Transparency = 1
			floor.CFrame = CFrame.new(cx, platformY, cz)
			floor.Parent = propsFolder
			local truss = Instance.new("TrussPart")
			truss.Size = Vector3.new(2, platformY + 1, 2)
			truss.Anchored = true
			truss.CanCollide = true
			truss.Material = M.WoodPlanks
			truss.Color = Color3.fromRGB(120, 95, 60)
			truss.CFrame = CFrame.new(cx + 4.75 * s, (platformY + 1) / 2, cz)
			truss.Parent = propsFolder
			place("watchtower", Vector3.new(cx, 0, cz), 13, 5.63, 0, true, false, false, cx > 0 and BLUE or RED, STEEL)
		end
	end

	-- ===== base crates: chunky wood stacks =====
	for _, crate in cover:GetChildren() do
		if crate.Name == "Crate" and crate:IsA("BasePart") then
			local size = crate.Size.X
			crate.Transparency = 1
			crate.CanCollide = false
			for _, c in crate:GetChildren() do
				if c:IsA("Decal") or c:IsA("Texture") then c.Transparency = 1 elseif c:IsA("SurfaceGui") then c.Enabled = false end
			end
			local footprint = math.clamp(size * 1.5, 6.0, 7.5)
			local crateH = 0.96 * (footprint / 2.98)
			local stack = math.random(3, 4)
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
					finalize(m, true, true, OLIVE, WOOD, WOOD, M.WoodPlanks) -- force wood look
					m.Parent = propsFolder
				end
			end
		end
	end
end

-- ===== quartermaster kiosks =====
for _, base in arena:GetChildren() do
	local qm = base:FindFirstChild("Quartermaster")
	if qm and qm:IsA("BasePart") then
		hide(qm)
		local team = base.Name == "RedBase" and RED or (base.Name == "BlueBase" and BLUE or nil)
		place("kiosk", Vector3.new(qm.Position.X, 0, qm.Position.Z), 8.5, 2.39, qm.Position.X > 0 and 180 or 0, false, true, true, team, OLIVE)
	end
end

-- ===== standalone cover, clear of dividers (x=+-21,+-63, z=+-22) =====
local function coverPair(key, x, z, h, ext, yaw, upright, fallback, force, forceMat)
	place(key, Vector3.new(x, 0, z), h, ext, yaw, upright, true, true, nil, fallback, force, forceMat)
	place(key, Vector3.new(-x, 0, z), h, ext, yaw, upright, true, true, nil, fallback, force, forceMat)
end
coverPair("drum", 100, 30, 4.5, 1.22, 0, true, STEEL, nil, M.Metal)
coverPair("drum", 100, -30, 4.5, 1.22, 0, true, STEEL, nil, M.Metal)
coverPair("concrete", 45, 14, 4.0, 1.10, 90, false, CONCRETE, CONCRETE, M.Concrete)
coverPair("concrete", 45, -14, 4.0, 1.10, 90, false, CONCRETE, CONCRETE, M.Concrete)
coverPair("hesco", 90, 18, 4.0, 1.04, 0, false, TAN, TAN, M.Sand)
coverPair("hesco", 90, -18, 4.0, 1.04, 0, false, TAN, TAN, M.Sand)

-- sandbags: tapered tan wall, forced sand material
local function sandbagWall(x, z)
	local sc = 9 / 4.25
	local rowH = 0.52 * sc
	for side = 1, -1, -2 do
		for r = 0, 4 do
			local m = loadModel("sandbag")
			if m then
				m.WorldPivot = m:GetBoundingBox()
				m:ScaleTo(sc * (1 - r * 0.07))
				m:PivotTo(CFrame.new(side * x, rowH * (r + 0.5), z) * CFrame.Angles(0, math.rad((r % 2 == 0) and 0 or 6), 0))
				finalize(m, true, true, nil, TAN, TAN, M.Sand)
				m.Parent = propsFolder
			end
		end
	end
end
sandbagWall(42, 0)
sandbagWall(16, 0)

print("[Props] placed with name-based color + Roblox materials")
