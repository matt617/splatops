--!strict
-- Lobby practice range: a warm-up room north of the arena where players learn the
-- tap-to-shoot before a match. Neutral lobby spawn, five target stands (the server
-- spawns a respawning dummy on each), cover, and a sign. Also turns off team
-- auto-assign so players land here neutral instead of on an arena team spawn.
-- Run in Studio after the arena exists; re-runnable.

local Workspace = game:GetService("Workspace")
local Teams = game:GetService("Teams")

local old = Workspace:FindFirstChild("PracticeRange")
if old then
	old:Destroy()
end
local R = Instance.new("Folder")
R.Name = "PracticeRange"
R.Parent = Workspace

local GRAY = Color3.fromRGB(120, 124, 130)
local DARK = Color3.fromRGB(84, 88, 94)
local function block(name: string, pos: Vector3, size: Vector3, color: Color3?, mat: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = CFrame.new(pos)
	p.Color = color or GRAY
	p.Material = mat or Enum.Material.Concrete
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = R
	return p
end

block("Floor", Vector3.new(0, -0.5, 280), Vector3.new(80, 1, 60), DARK)
block("WallN", Vector3.new(0, 8, 310), Vector3.new(80, 16, 2), GRAY)
block("WallS", Vector3.new(0, 8, 250), Vector3.new(80, 16, 2), GRAY)
block("WallW", Vector3.new(-40, 8, 280), Vector3.new(2, 16, 60), GRAY)
block("WallE", Vector3.new(40, 8, 280), Vector3.new(2, 16, 60), GRAY)

-- neutral lobby spawn: players land here, off any team
local sp = Instance.new("SpawnLocation")
sp.Name = "LobbySpawn"
sp.Anchored = true
sp.Size = Vector3.new(10, 1, 10)
sp.CFrame = CFrame.new(0, 0.5, 258)
sp.Color = Color3.fromRGB(80, 170, 90)
sp.Material = Enum.Material.SmoothPlastic
sp.Neutral = true
sp.Duration = 0
sp.Parent = R

-- target stands: the server (PracticeRange.server.lua) spawns a respawning dummy on each
local T = Instance.new("Folder")
T.Name = "Targets"
T.Parent = R
for _, x in ipairs({ -28, -14, 0, 14, 28 }) do
	local mk = Instance.new("Part")
	mk.Name = "TargetSpawn"
	mk.Anchored = true
	mk.Size = Vector3.new(4, 0.4, 4)
	mk.CFrame = CFrame.new(x, 0.2, 302)
	mk.Color = Color3.fromRGB(200, 180, 60)
	mk.Material = Enum.Material.Neon
	mk.Transparency = 0.35
	mk.CanCollide = false
	mk.Parent = T
end

-- cover to duck behind
block("Cover1", Vector3.new(-12, 2, 278), Vector3.new(5, 4, 5), Color3.fromRGB(116, 92, 60), Enum.Material.WoodPlanks)
block("Cover2", Vector3.new(12, 2, 283), Vector3.new(5, 4, 5), Color3.fromRGB(116, 92, 60), Enum.Material.WoodPlanks)

-- range sign facing the player
local sign = block("Sign", Vector3.new(0, 12, 309), Vector3.new(42, 6, 0.4), DARK, Enum.Material.SmoothPlastic)
local sg = Instance.new("SurfaceGui")
sg.Face = Enum.NormalId.Front
sg.Parent = sign
local lbl = Instance.new("TextLabel")
lbl.Size = UDim2.fromScale(1, 1)
lbl.BackgroundTransparency = 1
lbl.Text = "PRACTICE RANGE"
lbl.TextColor3 = Color3.fromRGB(255, 230, 90)
lbl.Font = Enum.Font.GothamBlack
lbl.TextScaled = true
lbl.Parent = sg

-- players stay neutral in the lobby until match mode assigns teams
for _, t in Teams:GetChildren() do
	if t:IsA("Team") then
		t.AutoAssignable = false
	end
end

print("[PracticeRange] built")
