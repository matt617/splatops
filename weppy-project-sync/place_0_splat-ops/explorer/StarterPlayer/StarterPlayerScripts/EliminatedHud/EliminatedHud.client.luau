--!strict
-- Client feedback for getting tagged: the ELIMINATED stamp and a paint hit flash.
-- No gameplay logic here. The server already decided the outcome; this just shows it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "SplatOpsHud"
gui.ResetOnSpawn = false -- survive respawns so the stamp can outlast the character
gui.IgnoreGuiInset = true
gui.Parent = playerGui

-- full-screen paint flash when this player takes a hit
local flash = Instance.new("Frame")
flash.Name = "HitFlash"
flash.Size = UDim2.fromScale(1, 1)
flash.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
flash.BackgroundTransparency = 1
flash.ZIndex = 1
flash.Parent = gui

-- ELIMINATED stamp, hidden until the server tags this player out
local stamp = Instance.new("TextLabel")
stamp.Name = "EliminatedStamp"
stamp.AnchorPoint = Vector2.new(0.5, 0.5)
stamp.Position = UDim2.fromScale(0.5, 0.5)
stamp.Size = UDim2.fromScale(0.6, 0.18)
stamp.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
stamp.BackgroundTransparency = 0.15
stamp.TextColor3 = Color3.fromRGB(235, 60, 60)
stamp.Font = Enum.Font.GothamBlack
stamp.TextScaled = true
stamp.Text = "ELIMINATED"
stamp.Rotation = -8
stamp.Visible = false
stamp.ZIndex = 2
stamp.Parent = gui

Remotes.PlayerTagged.OnClientEvent:Connect(function()
	stamp.Visible = true
	-- keep it up through the respawn wait, then clear
	task.delay(Config.Player.RespawnSeconds, function()
		stamp.Visible = false
	end)
end)

Remotes.PaintHitVFX.OnClientEvent:Connect(function(color: Color3?)
	if color then
		flash.BackgroundColor3 = color
	end
	flash.BackgroundTransparency = 0.4
	task.wait(Config.VFX.HitFlashDurationSeconds)
	flash.BackgroundTransparency = 1
end)
