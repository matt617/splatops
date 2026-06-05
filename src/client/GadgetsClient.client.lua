--!strict
-- Client side of the gadgets: the double jump input and the scout drone highlights.
-- Both abilities are granted server-side (attributes / the ScoutDrone event); this only
-- renders and reads input.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))

local player = Players.LocalPlayer

-- ===== double jump =====
-- Granted by the DoubleJump attribute. One extra jump per airtime, reset on landing.

local usedDouble = false

local function watchHumanoid(humanoid: Humanoid)
	humanoid.StateChanged:Connect(function(_old, new)
		if new == Enum.HumanoidStateType.Landed or new == Enum.HumanoidStateType.Running then
			usedDouble = false
		end
	end)
end

UserInputService.JumpRequest:Connect(function()
	if player:GetAttribute("DoubleJump") ~= true or usedDouble then
		return
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local state = humanoid:GetState()
	if state == Enum.HumanoidStateType.Freefall then
		usedDouble = true
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end)

local function onCharacter(character: Model)
	usedDouble = false
	local humanoid = character:WaitForChild("Humanoid", 5) :: Humanoid?
	if humanoid then
		watchHumanoid(humanoid)
	end
end
if player.Character then
	onCharacter(player.Character)
end
player.CharacterAdded:Connect(onCharacter)

-- ===== scout drone =====
-- The server says "reveal for N seconds"; we highlight everyone not on our team.

Remotes.ScoutDrone.OnClientEvent:Connect(function(duration: number)
	for _, other in Players:GetPlayers() do
		if other ~= player and other.Team ~= nil and other.Team ~= player.Team and other.Character then
			local highlight = Instance.new("Highlight")
			highlight.FillColor = Color3.fromRGB(255, 90, 90)
			highlight.FillTransparency = 0.6
			highlight.OutlineColor = Color3.fromRGB(255, 60, 60)
			highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			highlight.Parent = other.Character
			Debris:AddItem(highlight, duration)
		end
	end
end)
