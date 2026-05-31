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
local WOOD = Color3.fromRGB(125, 96, 56)
local OLIVE = Color3.fromRGB(106, 112, 78)

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

-- tall axis of each import (from inspection): tower/watchtower import lying along +Z with their
-- top toward -Z, so rotate +90 about X to stand them up the right way (top -> +Y). The rest
-- already stand on +Y.
local UPRIGHT = CFrame.Angles(math.pi / 2, 0, 0)

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
		-- face the field, and pull the visual in off the back wall (the hitbox stays put)
		local sign = tower.Position.X > 0 and 1 or -1
		place("tower", Vector3.new(tower.Position.X - sign * 8, 0, tower.Position.Z), 32, 8.59, tower.Position.X > 0 and 180 or 0, true, false, false, team)
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

	-- ===== base crates: a random stack of crate models per spot (the stack IS the cover) =====
	for _, crate in cover:GetChildren() do
		if crate.Name == "Crate" and crate:IsA("BasePart") then
			local size = crate.Size.X
			crate.Transparency = 1
			crate.CanCollide = false -- the visible stack provides the collision now
			for _, c in crate:GetChildren() do
				if c:IsA("Decal") or c:IsA("Texture") then
					c.Transparency = 1
				elseif c:IsA("SurfaceGui") then
					c.Enabled = false
				end
			end
			local footprint = math.clamp(size * 0.78, 2.6, 4.2)
			local crateH = 0.96 * (footprint / 2.98)
			local stack = math.random(1, 3) -- random tall vs short
			local groundY = crate.Position.Y - size / 2
			for i = 1, stack do
				local m = loadModel("crate")
				if m then
					m.WorldPivot = m:GetBoundingBox()
					m:ScaleTo(footprint / 2.98)
					local jx = (math.random() - 0.5) * 0.5
					local jz = (math.random() - 0.5) * 0.5
					local yaw = math.random(-14, 14) + (i % 2 == 0 and 90 or 0) -- cross-stack
					m:PivotTo(CFrame.new(crate.Position.X + jx, groundY + crateH * (i - 0.5), crate.Position.Z + jz) * CFrame.Angles(0, math.rad(yaw), 0))
					for _, d in m:GetDescendants() do
						if d:IsA("BasePart") then
							d.Anchored = true
							d.CanCollide = true
							d.CanQuery = true
							d.CastShadow = false
							d.Color = string.find(string.lower(d.Name), "team") and OLIVE or WOOD
						end
					end
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
		hideKeepCollision(qm) -- keeps the shop ProximityPrompt
		local team = base.Name == "RedBase" and RED or (base.Name == "BlueBase" and BLUE or nil)
		local yaw = qm.Position.X > 0 and 180 or 0
		local k = place("kiosk", Vector3.new(qm.Position.X, 0, qm.Position.Z), 6.5, 2.39, yaw, false, true, true, team)
		if k then
			-- color the bare mesh: olive base, wood crates, dark screen, team-colored sign
			for _, d in k:GetDescendants() do
				if d:IsA("BasePart") then
					local n = string.lower(d.Name)
					if string.find(n, "team") then
						d.Color = team or OLIVE
					elseif string.find(n, "screen") then
						d.Color = Color3.fromRGB(30, 34, 42)
					elseif string.find(n, "crate") or string.find(n, "wood") or string.find(n, "sandbag") then
						d.Color = WOOD
					else
						d.Color = OLIVE
					end
				end
			end
		end
	end
end

-- ===== extra cover dressing (solid props, symmetric) =====
-- {key, x, z, targetHeight, tallExtent, yaw, needsUpright, tint}
local function coverPair(key, x, z, h, ext, yaw, upright, tint)
	place(key, Vector3.new(x, 0, z), h, ext, yaw, upright, true, true, tint)
	place(key, Vector3.new(-x, 0, z), h, ext, yaw, upright, true, true, tint)
end
coverPair("drum", 100, 28, 3.0, 1.22, 0, true, OLIVE) -- drum stands up; body tinted olive
coverPair("drum", 100, -28, 3.0, 1.22, 0, true, OLIVE)
coverPair("concrete", 18, 34, 1.9, 1.10, 90, false, nil)
coverPair("concrete", 18, -34, 1.9, 1.10, 90, false, nil)
coverPair("hesco", 70, 22, 2.0, 1.04, 0, false, nil)
coverPair("hesco", 70, -22, 2.0, 1.04, 0, false, nil)
coverPair("sandbag", 38, 0, 1.2, 0.52, 0, false, nil)

print("[Props] placed: towers, watchtowers, crates, kiosks, cover dressing")
