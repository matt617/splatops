--!strict
-- Places the uploaded 3D prop models into the arena, over the existing gray-box so gameplay
-- never depends on the meshes. The comms towers, mid watchtowers, base crates and quartermaster
-- kiosks keep their gray-box parts as the functional layer (made invisible but still colliding /
-- still the tower hitbox / still holding the shop prompt); the models sit on top as non-colliding,
-- non-querying visuals. Standalone cover (drum, sandbag, concrete, hesco) is added as solid props.
-- Tinted to team colors where the model has a "TeamColor" part. Re-runnable.
-- Run AFTER arena_blockout (and practice_range), via weppy execute_luau.

local Workspace = game:GetService("Workspace")
local InsertService = game:GetService("InsertService")

local RED = Color3.fromRGB(220, 50, 50)
local BLUE = Color3.fromRGB(50, 100, 220)

local IDS = {
	tower = 103302952105387,
	watchtower = 133320127977802,
	crate = 136790839484466,
	drum = 123891449640864,
	sandbag = 98725300972524,
	concrete = 94985129662656,
	hesco = 78963301407705,
	kiosk = 78453486089917,
}

-- tall axis of each import (from inspection): tower/watchtower import lying along +Z, the rest
-- stand on +Y. We rotate the +Z ones upright.
local UPRIGHT = CFrame.Angles(-math.pi / 2, 0, 0)

local arena = Workspace:WaitForChild("Arena")
local old = Workspace:FindFirstChild("Props")
if old then old:Destroy() end
local propsFolder = Instance.new("Folder")
propsFolder.Name = "Props"
propsFolder.Parent = Workspace

-- load each asset once, then clone per placement
local cache: { [string]: Model } = {}
local function loadModel(key: string): Model?
	local tmpl = cache[key]
	if not tmpl then
		local ok, m = pcall(function()
			return InsertService:LoadAsset(IDS[key])
		end)
		if not ok or not m then
			return nil
		end
		cache[key] = m
		tmpl = m
	end
	return tmpl:Clone()
end

local function finalize(model: Model, collide: boolean, query: boolean, team: Color3?)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = collide
			d.CanQuery = query
			d.CastShadow = false
			if team and string.find(string.lower(d.Name), "team") then
				d.Color = team
			end
		end
	end
	model.Parent = propsFolder
end

-- Place a model standing with its base at basePos, scaled so its tall extent = targetHeight.
-- needsUpright rotates a +Z-tall import to +Y.
local function place(key: string, basePos: Vector3, targetHeight: number, tallExtent: number, yawDeg: number, needsUpright: boolean, collide: boolean, query: boolean, team: Color3?): Model?
	local model = loadModel(key)
	if not model then
		return nil
	end
	local bcf = model:GetBoundingBox()
	model.WorldPivot = bcf
	model:ScaleTo(targetHeight / tallExtent)
	local rot = CFrame.Angles(0, math.rad(yawDeg), 0) * (needsUpright and UPRIGHT or CFrame.identity)
	model:PivotTo(CFrame.new(basePos + Vector3.new(0, targetHeight / 2, 0)) * rot)
	finalize(model, collide, query, team)
	return model
end

-- hide a gray-box part we are replacing with a model, including any arena-art decals on it,
-- but keep its collision/query behavior (it stays the hitbox / collider / prompt holder)
local function hideKeepCollision(part: BasePart)
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
		hideKeepCollision(tower) -- stays the hitbox: CanQuery/CanCollide untouched
		local tip = base:FindFirstChild("CommsTowerTip")
		if tip and tip:IsA("BasePart") then
			hideKeepCollision(tip)
		end
		-- face the field (toward x=0)
		local yaw = tower.Position.X > 0 and 180 or 0
		place("tower", Vector3.new(tower.Position.X, 0, tower.Position.Z), 32, 8.59, yaw, true, false, false, team)
	end
end

-- ===== mid watchtowers: model visual over the climbable gray-box =====
local cover = arena:FindFirstChild("Cover")
if cover then
	for _, deck in cover:GetChildren() do
		if deck.Name == "TowerDeck" and deck:IsA("BasePart") then
			local cx, cz = deck.Position.X, deck.Position.Z
			-- hide the gray watchtower visuals around this deck but keep them colliding (climb still works)
			for _, p in cover:GetChildren() do
				if p:IsA("BasePart") and (p.Name == "TowerDeck" or p.Name == "TowerLeg" or p.Name == "TowerRail" or p.Name == "TowerRamp") then
					if math.abs(p.Position.X - cx) < 12 and math.abs(p.Position.Z - cz) < 12 then
						p.Transparency = 1
					end
				end
			end
			local team = cx > 0 and BLUE or RED
			place("watchtower", Vector3.new(cx, 0, cz), 11, 5.63, 0, true, false, false, team)
		end
	end

	-- ===== base crates: model visual over the invisible gray cube collider =====
	for _, crate in cover:GetChildren() do
		if crate.Name == "Crate" and crate:IsA("BasePart") then
			local size = crate.Size.X
			hideKeepCollision(crate) -- gray cube stays the collider/cover
			place("crate", Vector3.new(crate.Position.X, crate.Position.Y - size / 2, crate.Position.Z), size, 2.98, 0, false, false, false, nil)
		end
	end
end

-- ===== quartermaster kiosks: model at each base's prompt part =====
for _, base in arena:GetChildren() do
	local qm = base:FindFirstChild("Quartermaster")
	if qm and qm:IsA("BasePart") then
		hideKeepCollision(qm) -- keeps the shop ProximityPrompt
		local team = base.Name == "RedBase" and RED or (base.Name == "BlueBase" and BLUE or nil)
		local yaw = qm.Position.X > 0 and 180 or 0
		place("kiosk", Vector3.new(qm.Position.X, 0, qm.Position.Z), 4.5, 2.39, yaw, false, true, true, team)
	end
end

-- ===== extra cover dressing (solid props, symmetric) =====
-- {key, x, z, targetHeight, tallExtent, yaw}
local function coverPair(key, x, z, h, ext, yaw)
	place(key, Vector3.new(x, 0, z), h, ext, yaw, false, true, true, nil)
	place(key, Vector3.new(-x, 0, z), h, ext, yaw, false, true, true, nil)
end
coverPair("drum", 100, 28, 3.0, 1.22, 0)
coverPair("drum", 100, -28, 3.0, 1.22, 0)
coverPair("concrete", 18, 34, 1.9, 1.10, 90)
coverPair("concrete", 18, -34, 1.9, 1.10, 90)
coverPair("hesco", 70, 22, 2.0, 1.04, 0)
coverPair("hesco", 70, -22, 2.0, 1.04, 0)
coverPair("sandbag", 38, 0, 1.2, 0.52, 0)

print("[Props] placed: towers, watchtowers, crates, kiosks, cover dressing")
