--!strict
-- Assault Marker, client side. Fires where you click or tap (cursor stays visible, so the
-- same input works for mouse and iPad touch), shows an ammo readout, and reloads on R.
-- The server owns the paintball, hit detection, and ammo; we only report aim and intent.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local MARKER = Config.Weapons.AssaultMarker
local tool = script.Parent :: Tool
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mouse = player:GetMouse()

tool.ToolTip = MARKER.DisplayName

-- ammo HUD, bottom-right, shown only while equipped. Clear any stale copy from a past life.
local stale = playerGui:FindFirstChild("MarkerHud")
if stale then
	stale:Destroy()
end

local hud = Instance.new("ScreenGui")
hud.Name = "MarkerHud"
hud.ResetOnSpawn = false
hud.Enabled = false
hud.Parent = playerGui

local ammoLabel = Instance.new("TextLabel")
ammoLabel.AnchorPoint = Vector2.new(1, 1)
ammoLabel.Position = UDim2.new(1, -16, 1, -16)
ammoLabel.Size = UDim2.fromOffset(150, 42)
ammoLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
ammoLabel.BackgroundTransparency = 0.35
ammoLabel.Font = Enum.Font.GothamBold
ammoLabel.TextScaled = true
ammoLabel.Text = ""
ammoLabel.Parent = hud
local pad = Instance.new("UIPadding")
pad.PaddingLeft = UDim.new(0, 10)
pad.PaddingRight = UDim.new(0, 10)
pad.Parent = ammoLabel

local function refresh()
	local ammo = (tool:GetAttribute("Ammo") :: number?) or MARKER.AmmoPerMag
	if tool:GetAttribute("Reloading") == true then
		ammoLabel.Text = "RELOADING"
		ammoLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
	else
		ammoLabel.Text = string.format("%d / %d", ammo, MARKER.AmmoPerMag)
		ammoLabel.TextColor3 = if ammo <= 0 then Color3.fromRGB(235, 80, 80) else Color3.fromRGB(235, 235, 235)
	end
end

tool:GetAttributeChangedSignal("Ammo"):Connect(refresh)
tool:GetAttributeChangedSignal("Reloading"):Connect(refresh)

local equipped = false
tool.Equipped:Connect(function()
	equipped = true
	hud.Enabled = true
	refresh()
end)
tool.Unequipped:Connect(function()
	equipped = false
	hud.Enabled = false
end)

-- quick muzzle flash at the barrel tip. Local feedback for the shooter.
local function muzzleFlash()
	local character = player.Character
	local gun = character and character:FindFirstChild("AssaultMarker")
	local barrel = gun and gun:FindFirstChild("Barrel")
	if not barrel or not barrel:IsA("BasePart") then
		return
	end
	local flash = Instance.new("Part")
	flash.Shape = Enum.PartType.Ball
	flash.Size = Vector3.new(0.85, 0.85, 0.85)
	flash.Color = Color3.fromRGB(255, 232, 150)
	flash.Material = Enum.Material.Neon
	flash.Anchored = true
	flash.CanCollide = false
	flash.CanQuery = false
	flash.CastShadow = false
	flash.CFrame = barrel.CFrame * CFrame.new(barrel.Size.X / 2 + 0.3, 0, 0)
	flash.Parent = workspace
	Debris:AddItem(flash, 0.05)
end

-- client-side cadence gate, just for feel. the server enforces the real rate and ammo.
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
	local ray = camera:ScreenPointToRay(mouse.X, mouse.Y)
	Remotes.FireWeapon:FireServer(ray.Origin, ray.Direction)

	-- local feel: flash the muzzle
	muzzleFlash()
end)

-- manual reload on PC; touch devices auto-reload when the marker runs dry (server-side)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or not equipped then
		return
	end
	if input.KeyCode == Enum.KeyCode.R then
		Remotes.ReloadWeapon:FireServer()
	end
end)
