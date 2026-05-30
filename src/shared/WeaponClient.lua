--!strict
-- Shared client weapon logic. Each weapon Tool runs a one-line stub that calls
-- WeaponClient.attach(tool). This reads the tool's stats from Config.Weapons and handles
-- aiming (cursor/tap on PC/touch, screen center + R2 on gamepad), firing, reload (R / Square
-- / auto), the ammo HUD, and a muzzle flash. The server owns the shot, hit detection, ammo.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local Debris = game:GetService("Debris")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local WeaponClient = {}

local player = Players.LocalPlayer

-- one shared ammo readout reused by whatever weapon is equipped
local function getAmmoLabel(): TextLabel
	local pg = player:WaitForChild("PlayerGui")
	local hud = pg:FindFirstChild("WeaponHud")
	if hud then
		return hud:FindFirstChild("Ammo") :: TextLabel
	end
	hud = Instance.new("ScreenGui")
	hud.Name = "WeaponHud"
	hud.ResetOnSpawn = false
	hud.Parent = pg
	local label = Instance.new("TextLabel")
	label.Name = "Ammo"
	label.AnchorPoint = Vector2.new(1, 1)
	label.Position = UDim2.new(1, -16, 1, -16)
	label.Size = UDim2.fromOffset(150, 42)
	label.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	label.BackgroundTransparency = 0.35
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Text = ""
	label.Visible = false
	label.Parent = hud
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)
	pad.Parent = label
	return label
end

local function usingGamepad(): boolean
	local last = UserInputService:GetLastInputType()
	return last == Enum.UserInputType.Gamepad1 or last == Enum.UserInputType.Gamepad2
end

local function aimRay(): Ray?
	local camera = workspace.CurrentCamera
	if not camera then
		return nil
	end
	if usingGamepad() then
		local vp = camera.ViewportSize
		return camera:ViewportPointToRay(vp.X * 0.5, vp.Y * 0.5)
	end
	local mouse = player:GetMouse()
	return camera:ScreenPointToRay(mouse.X, mouse.Y)
end

local function muzzleFlash(tool: Instance)
	local barrel = tool:FindFirstChild("Barrel")
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

function WeaponClient.attach(tool: Tool)
	local cfg = Config.Weapons[tool.Name]
	if not cfg then
		return -- not a configured weapon
	end
	tool.ToolTip = cfg.DisplayName
	local ammoLabel = getAmmoLabel()

	local function refresh()
		local ammo = (tool:GetAttribute("Ammo") :: number?) or cfg.AmmoPerMag
		if tool:GetAttribute("Reloading") == true then
			ammoLabel.Text = "RELOADING"
			ammoLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
		else
			ammoLabel.Text = string.format("%d / %d", ammo, cfg.AmmoPerMag)
			ammoLabel.TextColor3 = if ammo <= 0 then Color3.fromRGB(235, 80, 80) else Color3.fromRGB(235, 235, 235)
		end
	end
	tool:GetAttributeChangedSignal("Ammo"):Connect(refresh)
	tool:GetAttributeChangedSignal("Reloading"):Connect(refresh)

	local lastFire = 0
	local function fire()
		local now = os.clock()
		if now - lastFire < cfg.FireRateSeconds then
			return
		end
		lastFire = now
		local ray = aimRay()
		if not ray then
			return
		end
		Remotes.FireWeapon:FireServer(ray.Origin, ray.Direction)
		muzzleFlash(tool)
	end
	tool.Activated:Connect(fire)

	local fireAction = "SplatOpsFire_" .. tool.Name
	local equipped = false
	tool.Equipped:Connect(function()
		equipped = true
		ammoLabel.Visible = true
		refresh()
		ContextActionService:BindAction(fireAction, function(_, state)
			if state == Enum.UserInputState.Begin then
				fire()
			end
			return Enum.ContextActionResult.Pass
		end, false, Enum.KeyCode.ButtonR2)
	end)
	tool.Unequipped:Connect(function()
		equipped = false
		ammoLabel.Visible = false
		ContextActionService:UnbindAction(fireAction)
	end)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or not equipped then
			return
		end
		if input.KeyCode == Enum.KeyCode.R or input.KeyCode == Enum.KeyCode.ButtonX then
			Remotes.ReloadWeapon:FireServer()
		end
	end)
end

return WeaponClient
