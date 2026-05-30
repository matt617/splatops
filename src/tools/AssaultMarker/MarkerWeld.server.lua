--!strict
-- Welds the marker's cosmetic parts to the Handle so the whole gun moves as one unit when
-- equipped. The Handle is the body; barrel, hopper, grip, and tank hang off it at fixed
-- offsets. Runs once when the tool comes alive (in a player's Backpack or in Workspace).

local tool = script.Parent
local handle = tool:WaitForChild("Handle") :: BasePart

-- offset of each cosmetic part relative to the Handle (matches the prototyped shape)
local OFFSETS: { [string]: CFrame } = {
	Barrel = CFrame.new(0, 0.2, -2.6) * CFrame.Angles(0, math.rad(90), 0),
	Hopper = CFrame.new(0, 0.85, -0.1),
	Grip = CFrame.new(0, -1.0, 0.65) * CFrame.Angles(math.rad(-12), 0, 0),
	Tank = CFrame.new(0, -0.5, 1.6) * CFrame.Angles(0, math.rad(90), 0),
}

for name, c0 in OFFSETS do
	local part = tool:FindFirstChild(name)
	if part and part:IsA("BasePart") then
		part.Massless = true
		part.CanCollide = false
		part.Anchored = false
		local weld = Instance.new("Weld")
		weld.Part0 = handle
		weld.Part1 = part
		weld.C0 = c0
		weld.Parent = handle
	end
end
