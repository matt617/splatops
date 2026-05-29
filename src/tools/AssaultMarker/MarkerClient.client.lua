--!strict
-- Assault Marker, client side. Reads aim and trigger, asks the server to fire.
-- The server owns hit detection and damage. We only report where the player is aiming:
-- a ray from the camera through the mouse cursor, so you shoot what you point at.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local MARKER = Config.Weapons.AssaultMarker
local tool = script.Parent :: Tool
local mouse = Players.LocalPlayer:GetMouse()

tool.ToolTip = MARKER.DisplayName

-- client-side cadence gate, just for feel. the server enforces the real rate.
local lastFire = 0

tool.Activated:Connect(function()
	local now = os.clock()
	if now - lastFire < MARKER.FireRateSeconds then
		return
	end
	lastFire = now

	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	-- aim at wherever the cursor points, not the center of the screen
	local ray = camera:ScreenPointToRay(mouse.X, mouse.Y)
	Remotes.FireWeapon:FireServer(ray.Origin, ray.Direction)
end)
