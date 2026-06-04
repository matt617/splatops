--!strict
-- Exploding paint drums. Any drum prop in the arena bursts when shot: a big paint splash
-- tags everyone nearby (same rules as the mortar splash), then the drum despawns and
-- respawns after Config.Drums.RespawnSeconds. Server-authoritative end to end: the burst
-- runs off Combat's hit detection, never off anything the client reports.

local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local PaintSplat = require(Shared:WaitForChild("PaintSplat"))
local Combat = require(ServerScriptService:WaitForChild("Combat"))

local TAG = "PaintDrum"

-- part -> its drum model, and per-drum live state
local drumOf: { [BasePart]: Model } = {}
local exploded: { [Model]: boolean } = {}

-- find the drum prop models (they carry a DrumBody part) and tag every part in each
local function registerDrums()
	local props = Workspace:FindFirstChild("Props")
	if not props then
		return 0
	end
	local count = 0
	for _, inst in props:GetDescendants() do
		if inst:IsA("BasePart") and inst.Name:find("DrumBody") then
			local drum = inst:FindFirstAncestorOfClass("Model")
			if drum and exploded[drum] == nil then
				exploded[drum] = false
				count += 1
				for _, pt in drum:GetDescendants() do
					if pt:IsA("BasePart") then
						CollectionService:AddTag(pt, TAG)
						drumOf[pt] = drum
					end
				end
			end
		end
	end
	return count
end

local function setHidden(drum: Model, hidden: boolean)
	for _, pt in drum:GetDescendants() do
		if pt:IsA("BasePart") then
			pt.Transparency = hidden and 1 or 0
			pt.CanCollide = not hidden
			pt.CanQuery = not hidden
		end
	end
end

local function explode(drum: Model, shooter: Player?, paintColor: Color3)
	if exploded[drum] then
		return
	end
	exploded[drum] = true

	local cf, ext = drum:GetBoundingBox()
	local center = cf.Position

	-- tag everyone in range, then paint the ground big where the drum stood
	Combat.splash(center, Config.Drums.SplashRadiusStuds, Config.Drums.SplashDamage, paintColor, shooter)
	local ground = Vector3.new(center.X, center.Y - ext.Y / 2 + 0.1, center.Z)
	PaintSplat.spawn(ground, Vector3.yAxis, paintColor, Config.Drums.VFXScale)

	-- the boom, heard across a good chunk of the arena
	if Config.Sounds.DrumBoom ~= "" then
		local sndPart = Instance.new("Part")
		sndPart.Size = Vector3.new(0.2, 0.2, 0.2)
		sndPart.Transparency = 1
		sndPart.Anchored = true
		sndPart.CanCollide = false
		sndPart.CanQuery = false
		sndPart.Position = center
		sndPart.Parent = Workspace
		local snd = Instance.new("Sound")
		snd.SoundId = Config.Sounds.DrumBoom
		snd.Volume = 1
		snd.RollOffMaxDistance = 200
		snd.Parent = sndPart
		snd:Play()
		game:GetService("Debris"):AddItem(sndPart, 4)
	end

	setHidden(drum, true)
	task.delay(Config.Drums.RespawnSeconds, function()
		if drum.Parent then
			setHidden(drum, false)
			exploded[drum] = false
		end
	end)
end

local function teamPaint(player: Player?): Color3
	if player and player.Team then
		for _, team in Config.Teams do
			if team.Name == player.Team.Name then
				return team.PaintColor
			end
		end
	end
	return Color3.fromRGB(255, 140, 40) -- neutral burst orange
end

Combat.DrumHit.Event:Connect(function(shooter: Player?, part: BasePart, _position: Vector3)
	local drum = drumOf[part]
	if drum then
		explode(drum, shooter, teamPaint(shooter))
	end
end)

local registered = registerDrums()
print("[PaintDrums] registered " .. registered .. " drums")
