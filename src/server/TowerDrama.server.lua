--!strict
-- Tower drama. As a comms tower loses health it starts smoking (warning), then sparking
-- with a red strobe (critical), with TowerAlert announcements at each stage. Pure
-- presentation driven by the Health attribute that Tower.lua owns; resets when the
-- attribute returns to max at round start. Party servers only.

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local LobbyMode = require(Shared:WaitForChild("LobbyMode"))
if LobbyMode.get() ~= "party" then
	return
end

local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

type State = {
	stage: number,
	anchor: BasePart?,
	smoke: ParticleEmitter?,
	sparks: ParticleEmitter?,
	light: PointLight?,
	beacon: BasePart?,
	alarm: Sound?,
}
local towers: { [BasePart]: State } = {}

local folder = Workspace:FindFirstChild("TowerDrama") or Instance.new("Folder")
folder.Name = "TowerDrama"
folder.Parent = Workspace

local function buildAnchor(towerPart: BasePart): BasePart
	local anchor = Instance.new("Part")
	anchor.Name = "DramaAnchor"
	anchor.Size = Vector3.new(0.4, 0.4, 0.4)
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	-- sit at the upper third of the tower so smoke rises off the structure
	anchor.Position = towerPart.Position + Vector3.new(0, towerPart.Size.Y * 0.25, 0)
	anchor.Parent = folder
	return anchor
end

local function startWarning(state: State, towerPart: BasePart)
	if not state.anchor then
		state.anchor = buildAnchor(towerPart)
	end
	local smoke = Instance.new("ParticleEmitter")
	smoke.Color = ColorSequence.new(Color3.fromRGB(70, 70, 75))
	smoke.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 2),
		NumberSequenceKeypoint.new(1, 6),
	})
	smoke.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(1, 1),
	})
	smoke.Lifetime = NumberRange.new(1.5, 2.5)
	smoke.Speed = NumberRange.new(3, 6)
	smoke.SpreadAngle = Vector2.new(15, 15)
	smoke.Rate = 8
	smoke.Parent = state.anchor
	state.smoke = smoke
end

local function startCritical(state: State, towerPart: BasePart)
	if not state.anchor then
		state.anchor = buildAnchor(towerPart)
	end
	if state.smoke then
		state.smoke.Rate = 22 -- heavier smoke once critical
	end
	local sparks = Instance.new("ParticleEmitter")
	sparks.Color = ColorSequence.new(Color3.fromRGB(255, 180, 60), Color3.fromRGB(255, 80, 40))
	sparks.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 0.1),
	})
	sparks.Lifetime = NumberRange.new(0.3, 0.7)
	sparks.Speed = NumberRange.new(12, 20)
	sparks.SpreadAngle = Vector2.new(60, 60)
	sparks.Rate = 14
	sparks.Parent = state.anchor
	state.sparks = sparks

	local beacon = Instance.new("Part")
	beacon.Name = "DramaBeacon"
	beacon.Shape = Enum.PartType.Ball
	beacon.Size = Vector3.new(1.6, 1.6, 1.6)
	beacon.Color = Color3.fromRGB(255, 40, 40)
	beacon.Material = Enum.Material.Neon
	beacon.Anchored = true
	beacon.CanCollide = false
	beacon.CanQuery = false
	beacon.Position = towerPart.Position + Vector3.new(0, towerPart.Size.Y * 0.55, 0)
	beacon.Parent = folder
	state.beacon = beacon

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 50, 50)
	light.Range = 30
	light.Brightness = 0
	light.Parent = beacon
	state.light = light

	if Config.Sounds.TowerAlarm ~= "" then
		local alarm = Instance.new("Sound")
		alarm.SoundId = Config.Sounds.TowerAlarm
		alarm.Looped = true
		alarm.Volume = 0.7
		alarm.RollOffMaxDistance = 150
		alarm.Parent = beacon
		alarm:Play()
		state.alarm = alarm
	end
end

local function teardown(state: State)
	if state.anchor then
		state.anchor:Destroy()
	end
	if state.beacon then
		state.beacon:Destroy()
	end
	state.anchor = nil
	state.smoke = nil
	state.sparks = nil
	state.light = nil
	state.beacon = nil
	state.alarm = nil
	state.stage = 0
end

local function onHealthChanged(towerPart: BasePart)
	local state = towers[towerPart]
	if not state then
		return
	end
	local maxHp = (towerPart:GetAttribute("MaxHealth") :: number?) or 1
	local health = (towerPart:GetAttribute("Health") :: number?) or maxHp
	local pct = health / math.max(1, maxHp)
	local owner = towerPart:GetAttribute("Team") :: string?

	-- back to full = new round, clear everything
	if pct >= 1 then
		teardown(state)
		return
	end

	local stage = 0
	if pct <= Config.TowerDrama.CriticalAt then
		stage = 2
	elseif pct <= Config.TowerDrama.WarningAt then
		stage = 1
	end

	-- escalate only; de-escalation never happens mid-round (no tower regen in v1)
	if stage >= 1 and state.stage < 1 then
		startWarning(state, towerPart)
		if owner then
			Remotes.TowerAlert:FireAllClients(owner, 1)
		end
	end
	if stage >= 2 and state.stage < 2 then
		startCritical(state, towerPart)
		if owner then
			Remotes.TowerAlert:FireAllClients(owner, 2)
		end
	end
	state.stage = math.max(state.stage, stage)
end

-- one pulse loop drives every active strobe
local pulseAge = 0
RunService.Heartbeat:Connect(function(dt)
	pulseAge += dt
	local pulse = (math.sin(pulseAge * 6) + 1) / 2 -- 0..1
	for _, state in towers do
		if state.light then
			state.light.Brightness = pulse * 4
		end
		if state.beacon then
			state.beacon.Transparency = 0.2 + (1 - pulse) * 0.5
		end
	end
end)

-- hook every comms tower
for _, part in Workspace:GetDescendants() do
	if part:IsA("BasePart") and part.Name == "CommsTower" then
		towers[part] = { stage = 0 }
		part:GetAttributeChangedSignal("Health"):Connect(function()
			onHealthChanged(part)
		end)
	end
end
