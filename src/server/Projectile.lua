--!strict
-- Server-authoritative paintball projectiles. Spawns a visible ball that flies along
-- its path, raycasting each frame so a fast ball cannot tunnel through walls or players.
-- On impact it calls the supplied onHit with the raycast result; the caller decides what
-- the hit means (a player tag, tower damage, or just a splat on the world).

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local Projectile = {}

export type LaunchOpts = {
	origin: Vector3,
	direction: Vector3,
	speed: number,
	gravity: number?,
	range: number,
	color: Color3,
	size: number?,
	ignore: Instance?,
	onHit: ((RaycastResult) -> ())?,
}

type Active = {
	pos: Vector3,
	vel: Vector3,
	gravity: number,
	traveled: number,
	maxDist: number,
	ball: BasePart,
	params: RaycastParams,
	onHit: ((RaycastResult) -> ())?,
}

local active: { Active } = {}
local stepperStarted = false

local function getFolder(): Folder
	local existing = Workspace:FindFirstChild("Projectiles")
	if existing and existing:IsA("Folder") then
		return existing
	end
	local folder = Instance.new("Folder")
	folder.Name = "Projectiles"
	folder.Parent = Workspace
	return folder
end

local function startStepper()
	if stepperStarted then
		return
	end
	stepperStarted = true
	RunService.Heartbeat:Connect(function(dt)
		for i = #active, 1, -1 do
			local p = active[i]
			local nextPos = p.pos + p.vel * dt
			p.vel = p.vel - Vector3.new(0, p.gravity * dt, 0)
			local segment = nextPos - p.pos
			local result = Workspace:Raycast(p.pos, segment, p.params)
			if result then
				p.ball:Destroy()
				table.remove(active, i)
				if p.onHit then
					task.spawn(p.onHit, result)
				end
			else
				p.traveled += segment.Magnitude
				p.pos = nextPos
				p.ball.CFrame = CFrame.new(nextPos)
				if p.traveled >= p.maxDist then
					p.ball:Destroy()
					table.remove(active, i)
				end
			end
		end
	end)
end

function Projectile.launch(opts: LaunchOpts)
	local dir = opts.direction.Unit
	local size = opts.size or 0.8

	local ball = Instance.new("Part")
	ball.Name = "Paintball"
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.new(size, size, size)
	ball.Color = opts.color
	ball.Material = Enum.Material.Neon
	ball.Anchored = true
	ball.CanCollide = false
	ball.CanQuery = false -- never let a ball block another ball's raycast
	ball.CastShadow = false
	ball.CFrame = CFrame.new(opts.origin)
	ball.Parent = getFolder()
	Debris:AddItem(ball, 5) -- safety net; the stepper removes it well before this

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	if opts.ignore then
		params.FilterDescendantsInstances = { opts.ignore }
	end

	table.insert(active, {
		pos = opts.origin,
		vel = dir * opts.speed,
		gravity = opts.gravity or 0,
		traveled = 0,
		maxDist = opts.range,
		ball = ball,
		params = params,
		onHit = opts.onHit,
	})
	startStepper()
end

return Projectile
