-- Part-built quartermaster stalls at both bases, replacing the broken imported kiosk scene.
-- Re-runnable: destroys and rebuilds Workspace.QuartermasterStalls. The invisible gray-box
-- Quartermaster part stays as the ProximityPrompt holder; everything here is visual dressing.
-- Styled to match the shop UI: dark panels, gold trim, the weapon cards on display.
-- Plain Lua so it pastes straight into weppy execute_luau.

local Workspace = game:GetService("Workspace")

-- uploaded art. Empty string = placeholder until the id exists, then re-run.
local IDS = {
	sign = "rbxassetid://90741391919626", -- wide QUARTERMASTER banner
	coin = "rbxassetid://116190464693527", -- square coin emblem (counter front)
	pricelist = "rbxassetid://98928429394165", -- portrait price list board (weapons)
	gearlist = "rbxassetid://80917917546247", -- portrait gear list board (gadgets)
}
-- shop card art, cheapest first, same ids as Config.Weapons CardImage
local CARDS = {
	"rbxassetid://139159382174571", -- assault
	"rbxassetid://86080782756370", -- scattergun
	"rbxassetid://121820949874382", -- recon
	"rbxassetid://128414709052987", -- mortar
}
local REGISTER_ID = 74881674829702 -- cartoon cash register model, one per counter

local DARK = Color3.fromRGB(24, 26, 32)
local PANE = Color3.fromRGB(31, 34, 42)
local GOLD = Color3.fromRGB(255, 196, 60)
local POST = Color3.fromRGB(62, 46, 34)
local TOP = Color3.fromRGB(133, 100, 62)
local CRATE = Color3.fromRGB(120, 86, 52)

local old = Workspace:FindFirstChild("QuartermasterStalls")
if old then
	old:Destroy()
end
-- clear the exploded imported kiosk scenes if any are still around
local props = Workspace:FindFirstChild("Props")
if props then
	for _, m in props:GetDescendants() do
		if m.Name == "ArmorySupplyKioskScene" then
			m:Destroy()
		end
	end
end

local folder = Instance.new("Folder")
folder.Name = "QuartermasterStalls"
folder.Parent = Workspace

local function part(parent, size, cf, color, material, collide)
	local pt = Instance.new("Part")
	pt.Anchored = true
	pt.CastShadow = false
	pt.CanCollide = collide == true
	pt.Size = size
	pt.CFrame = cf
	pt.Color = color
	pt.Material = material or Enum.Material.SmoothPlastic
	pt.Parent = parent
	return pt
end

local function decal(pt, id)
	local d = Instance.new("Decal")
	d.Texture = id
	d.Face = Enum.NormalId.Front
	d.Parent = pt
end

local function signText(pt, text)
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Front
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 50
	sg.LightInfluence = 0
	sg.Brightness = 1.5
	sg.Parent = pt
	local l = Instance.new("TextLabel")
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextColor3 = GOLD
	l.Font = Enum.Font.GothamBlack
	l.TextScaled = true
	l.Parent = sg
end

-- the cash register import, loaded once and cloned per stall
local registerTemplate = nil
do
	local ok, asset = pcall(function()
		return game:GetService("InsertService"):LoadAsset(REGISTER_ID)
	end)
	if ok and asset then
		registerTemplate = asset:FindFirstChildOfClass("Model")
		if registerTemplate then
			registerTemplate.Parent = nil
		end
		asset:Destroy()
	end
end

local function buildStall(cx, cz, teamColor)
	local f = cx < 0 and 1 or -1 -- which way the stall faces (toward arena center)

	-- ground height, ignoring the invisible prompt hitboxes
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	local exclude = { folder }
	for _, bn in { "RedBase", "BlueBase" } do
		local b = Workspace.Arena:FindFirstChild(bn)
		local q = b and b:FindFirstChild("Quartermaster")
		if q then
			table.insert(exclude, q)
		end
	end
	rp.FilterDescendantsInstances = exclude
	local ray = Workspace:Raycast(Vector3.new(cx, 50, cz), Vector3.new(0, -100, 0), rp)
	local g = ray and ray.Position.Y or 0

	local dir = Vector3.new(f, 0, 0)
	local function p(dx, y, dz)
		return Vector3.new(cx + dx * f, g + y, cz + dz)
	end
	local function facing(pos) -- Front faces the arena center
		return CFrame.lookAt(pos, pos + dir)
	end

	local model = Instance.new("Model")
	model.Name = "QuartermasterStall"
	model.Parent = folder

	-- back wall, dark like the shop panel, with a gold top trim
	part(model, Vector3.new(14, 7, 0.5), facing(p(-3, 3.5, 0)), PANE, nil, true)
	part(model, Vector3.new(14.5, 0.3, 0.8), facing(p(-3, 7.1, 0)), GOLD, Enum.Material.Metal)

	-- front posts
	part(model, Vector3.new(0.7, 8.4, 0.7), facing(p(3, 4.2, -6.8)), POST, Enum.Material.Wood, true)
	part(model, Vector3.new(0.7, 8.4, 0.7), facing(p(3, 4.2, 6.8)), POST, Enum.Material.Wood, true)

	-- canvas canopy in the team color, front edge raised like a marquee, gold fringe
	part(model, Vector3.new(15.6, 0.3, 8.4), facing(p(0.4, 7.7, 0)) * CFrame.Angles(math.rad(8), 0, 0), teamColor, Enum.Material.Fabric)
	part(model, Vector3.new(15.7, 0.55, 0.3), facing(p(4.55, 7.95, 0)), GOLD, Enum.Material.Metal)

	-- sign board above the canopy front
	local sign = part(model, Vector3.new(12.6, 2.8, 0.45), facing(p(4.3, 9.9, 0)), DARK)
	if IDS.sign ~= "" then
		decal(sign, IDS.sign)
	else
		signText(sign, "QUARTERMASTER")
	end
	local signLight = Instance.new("PointLight")
	signLight.Color = Color3.fromRGB(255, 220, 150)
	signLight.Brightness = 1.2
	signLight.Range = 10
	signLight.Parent = sign

	-- counter: dark front panel, gold lip, wood top
	local panel = part(model, Vector3.new(12.6, 3.2, 0.5), facing(p(2.6, 1.6, 0)), DARK, nil, true)
	part(model, Vector3.new(12.6, 0.22, 0.55), facing(p(2.6, 3.12, 0)), GOLD, Enum.Material.Metal)
	part(model, Vector3.new(13.2, 0.35, 2.2), facing(p(2.6, 3.4, 0)), TOP, Enum.Material.WoodPlanks, true)
	if IDS.coin ~= "" then
		for _, dz in { -4.3, 4.3 } do
			local emblem = part(model, Vector3.new(1.9, 1.9, 0.1), facing(p(2.92, 1.7, dz)), DARK)
			decal(emblem, IDS.coin)
		end
	end

	-- the four weapon cards on the back wall, gold framed like the shop list
	for i, dz in { -5.4, -1.8, 1.8, 5.4 } do
		part(model, Vector3.new(3.2, 2.15, 0.12), facing(p(-2.62, 5.3, dz)), GOLD, Enum.Material.Metal)
		local card = part(model, Vector3.new(2.95, 1.92, 0.14), facing(p(-2.52, 5.3, dz)), Color3.fromRGB(15, 15, 18))
		decal(card, CARDS[i])
	end

	-- price list board resting on a crate beside the counter
	part(model, Vector3.new(1.6, 1.6, 1.6), facing(p(1.8, 0.8, 8.8)), CRATE, Enum.Material.WoodPlanks, true)
	local board = part(model, Vector3.new(3.4, 4.6, 0.3), facing(p(1.6, 3.8, 8.8)) * CFrame.Angles(math.rad(-7), 0, 0), DARK)
	if IDS.pricelist ~= "" then
		decal(board, IDS.pricelist)
	else
		signText(board, "PRICE LIST")
	end

	-- crate stack on the other side, with the gear list board leaning against it
	part(model, Vector3.new(2.5, 2.5, 2.5), facing(p(2.2, 1.25, -8.6)), CRATE, Enum.Material.WoodPlanks, true)
	part(model, Vector3.new(1.7, 1.7, 1.7), facing(p(2.2, 3.35, -8.6)) * CFrame.Angles(0, math.rad(20), 0), CRATE, Enum.Material.WoodPlanks, true)
	local gearBoard = part(model, Vector3.new(3.4, 4.6, 0.3), facing(p(3.6, 2.4, -8.6)) * CFrame.Angles(math.rad(-12), 0, 0), DARK)
	if IDS.gearlist ~= "" then
		decal(gearBoard, IDS.gearlist)
	else
		signText(gearBoard, "GEAR LIST")
	end

	-- paint jars on the counter (glass cylinders) plus a little stack of coins
	local jarColors = { Color3.fromRGB(220, 60, 60), Color3.fromRGB(255, 196, 60), Color3.fromRGB(60, 110, 220) }
	for i, dz in { -2.8, -3.8, -4.8 } do
		local jar = part(model, Vector3.new(1.05, 0.95, 0.95), CFrame.new(p(2.6, 4.1, dz)) * CFrame.Angles(0, 0, math.rad(90)), jarColors[i], Enum.Material.Glass)
		jar.Shape = Enum.PartType.Cylinder
		jar.Transparency = 0.1
		local lid = part(model, Vector3.new(0.16, 1.0, 1.0), CFrame.new(p(2.6, 4.68, dz)) * CFrame.Angles(0, 0, math.rad(90)), GOLD, Enum.Material.Metal)
		lid.Shape = Enum.PartType.Cylinder
	end
	for i = 1, 2 do
		local coin = part(model, Vector3.new(0.2, 0.9, 0.9), CFrame.new(p(2.6, 3.68 + (i - 1) * 0.21, 3.9)) * CFrame.Angles(0, 0, math.rad(90)), GOLD, Enum.Material.Metal)
		coin.Shape = Enum.PartType.Cylinder
	end

	-- cartoon cash register on the counter, keypad facing the customer
	if registerTemplate then
		local reg = registerTemplate:Clone()
		reg.Name = "CashRegister"
		reg:ScaleTo(2.7)
		reg.WorldPivot = reg:GetBoundingBox()
		local _, ext = reg:GetBoundingBox()
		reg:PivotTo(CFrame.new(p(2.6, 3.575 + ext.Y / 2, 1.5)) * CFrame.Angles(0, math.rad(-90 * f), 0))
		for _, pt in reg:GetDescendants() do
			if pt:IsA("BasePart") then
				pt.Anchored = true
				pt.CastShadow = false
				pt.CanCollide = false
				if pt.Name:find("TeamColor") then
					pt.Color = teamColor
					pt.Material = Enum.Material.SmoothPlastic
				elseif pt.Name:find("OlivePaint") then
					pt.Color = Color3.fromRGB(110, 116, 78)
					pt.Material = Enum.Material.SmoothPlastic
				elseif pt.Name:find("DarkGunmetal") then
					pt.Color = Color3.fromRGB(58, 60, 66)
					pt.Material = Enum.Material.Metal
				else
					pt.Color = Color3.fromRGB(150, 154, 160)
					pt.Material = Enum.Material.Metal
				end
			end
		end
		reg.Parent = model
	end

	-- warm light under the canopy plus a string of gold bulbs along the front
	local lamp = part(model, Vector3.new(0.2, 0.2, 0.2), facing(p(1, 6.6, 0)), DARK)
	lamp.Transparency = 1
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 220, 150)
	light.Brightness = 1.3
	light.Range = 15
	light.Shadows = false
	light.Parent = lamp
	for _, dz in { -6, -3, 0, 3, 6 } do
		local bulb = part(model, Vector3.new(0.4, 0.4, 0.4), facing(p(4.5, 7.45, dz)), GOLD, Enum.Material.Neon)
		bulb.Shape = Enum.PartType.Ball
	end
end

buildStall(-116, 24, Color3.fromRGB(220, 50, 50)) -- red base
buildStall(116, 24, Color3.fromRGB(50, 100, 220)) -- blue base

print("[QuartermasterStall] built both stalls")
