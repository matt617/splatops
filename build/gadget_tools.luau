-- Builds the two deployable placement Tools into ReplicatedStorage.GadgetTemplates.
-- Run in EDIT MODE via weppy execute_luau (LocalScript.Source is only writable there).
-- Re-runnable: replaces the folder. The quartermaster clones these on purchase; clicking
-- with one equipped fires PlaceDeployable and the server does all validation.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local old = ReplicatedStorage:FindFirstChild("GadgetTemplates")
if old then
	old:Destroy()
end
local folder = Instance.new("Folder")
folder.Name = "GadgetTemplates"
folder.Parent = ReplicatedStorage

-- the placement LocalScript: click/tap somewhere, ask the server to place there
local PLACER_SOURCE = [[
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local tool = script.Parent
local remotes = ReplicatedStorage:WaitForChild("SplatOpsRemotes")
local place = remotes:WaitForChild("PlaceDeployable")
local player = Players.LocalPlayer
tool.Activated:Connect(function()
	local mouse = player:GetMouse()
	if mouse and mouse.Hit then
		place:FireServer(tool.Name, mouse.Hit.Position)
	end
end)
]]

local function buildTool(name, tip, color)
	local tool = Instance.new("Tool")
	tool.Name = name
	tool.ToolTip = tip
	tool.RequiresHandle = true
	tool.CanBeDropped = false

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.8, 0.8, 2)
	handle.Color = color
	handle.Material = Enum.Material.SmoothPlastic
	handle.CanCollide = false
	handle.CastShadow = false
	handle.Parent = tool

	-- a little screen on the device so it reads as a gadget remote
	local screen = Instance.new("Part")
	screen.Name = "Screen"
	screen.Size = Vector3.new(0.6, 0.1, 0.9)
	screen.Color = Color3.fromRGB(120, 230, 140)
	screen.Material = Enum.Material.Neon
	screen.CanCollide = false
	screen.CastShadow = false
	screen.Parent = tool
	local weld = Instance.new("Weld")
	weld.Part0 = handle
	weld.Part1 = screen
	weld.C0 = CFrame.new(0, 0.45, -0.3)
	weld.Parent = handle

	local placer = Instance.new("LocalScript")
	placer.Name = "Placer"
	placer.Source = PLACER_SOURCE
	placer.Parent = tool

	tool.Parent = folder
end

buildTool("DeployableWall", "Click the ground to drop instant cover", Color3.fromRGB(196, 158, 70))
buildTool("AutoTurret", "Click near your base to set up the turret", Color3.fromRGB(58, 60, 66))

print("[GadgetTools] built DeployableWall and AutoTurret placement tools")
