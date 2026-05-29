--!strict
-- Assault Marker, client side. Fires where you click or tap. The cursor stays visible,
-- and on a touch screen (iPad) tapping the screen activates the tool, so the same code
-- works for mouse and touch. The server owns the paintball and all hit detection; we
-- only report the ray the player aimed through.

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
	-- aim through the cursor on PC, or the tapped point on a touch screen
	local ray = camera:ScreenPointToRay(mouse.X, mouse.Y)
	Remotes.FireWeapon:FireServer(ray.Origin, ray.Direction)
end)
