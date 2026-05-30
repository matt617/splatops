--!strict
-- Per-tool stub: hand this marker to the shared weapon client, which reads its stats from
-- Config.Weapons by the tool's name and runs all firing/aim/reload/HUD logic.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("WeaponClient")).attach(script.Parent)
