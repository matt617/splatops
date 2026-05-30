--!strict
-- Lobby tutorial: a short guided sequence with a live target counter. Steps advance as the
-- player does each thing (move, splat a target, reload, splat five). Display only; the
-- server reports the splat count. Cross-platform: triggers are device-agnostic (character
-- movement, server splat count, and the marker's Reloading state).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GOAL = 5
local splatted = 0
local moved = false
local reloaded = false
local stepIndex = 1

local gui = Instance.new("ScreenGui")
gui.Name = "TutorialGuide"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local prompt = Instance.new("TextLabel")
prompt.AnchorPoint = Vector2.new(0.5, 0)
prompt.Position = UDim2.new(0.5, 0, 0, 92)
prompt.Size = UDim2.fromOffset(440, 48)
prompt.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
prompt.BackgroundTransparency = 0.2
prompt.TextColor3 = Color3.fromRGB(255, 230, 90)
prompt.Font = Enum.Font.GothamBold
prompt.TextScaled = true
prompt.Text = ""
prompt.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = prompt
local ppad = Instance.new("UIPadding")
ppad.PaddingLeft = UDim.new(0, 14)
ppad.PaddingRight = UDim.new(0, 14)
ppad.Parent = prompt

local counter = Instance.new("TextLabel")
counter.AnchorPoint = Vector2.new(0.5, 0)
counter.Position = UDim2.new(0.5, 0, 0, 146)
counter.Size = UDim2.fromOffset(280, 30)
counter.BackgroundTransparency = 1
counter.TextColor3 = Color3.fromRGB(120, 210, 255)
counter.Font = Enum.Font.GothamBlack
counter.TextScaled = true
counter.Text = ""
counter.Parent = gui

local steps = {
	{ text = "Move around to get a feel for it!", done = function() return moved end },
	{ text = "Aim at a target and splat it! (3 hits)", done = function() return splatted >= 1 end },
	{ text = "Out of paint? Reload your marker!", done = function() return reloaded end },
	{ text = "Splat " .. GOAL .. " targets to finish!", done = function() return splatted >= GOAL end },
}

local finished = false
local function refresh()
	if finished then
		return
	end
	while stepIndex <= #steps and steps[stepIndex].done() do
		stepIndex += 1
	end
	if stepIndex > #steps then
		finished = true
		prompt.Text = "You're ready, paintballer!"
		prompt.TextColor3 = Color3.fromRGB(120, 255, 150)
		counter.Text = ""
		task.delay(4, function()
			gui.Enabled = false
		end)
		return
	end
	prompt.Text = steps[stepIndex].text
	counter.Text = "Targets splatted:  " .. splatted .. " / " .. GOAL
end

Remotes.PracticeProgress.OnClientEvent:Connect(function(count: number)
	splatted = count
	refresh()
end)

-- movement: any move input makes the humanoid run
local function watchCharacter(character: Model)
	local humanoid = character:WaitForChild("Humanoid", 5) :: Humanoid?
	if humanoid then
		humanoid.Running:Connect(function(speed: number)
			if speed > 0.1 and not moved then
				moved = true
				refresh()
			end
		end)
	end
	-- reload: the marker's Reloading attribute flips true on any reload (manual or auto)
	local function watchTool(tool: Instance)
		if tool.Name == "AssaultMarker" then
			tool:GetAttributeChangedSignal("Reloading"):Connect(function()
				if tool:GetAttribute("Reloading") == true and not reloaded then
					reloaded = true
					refresh()
				end
			end)
		end
	end
	character.ChildAdded:Connect(watchTool)
	for _, t in character:GetChildren() do
		watchTool(t)
	end
	local backpack = player:FindFirstChildOfClass("Backpack")
	if backpack then
		backpack.ChildAdded:Connect(watchTool)
		for _, t in backpack:GetChildren() do
			watchTool(t)
		end
	end
end

if player.Character then
	watchCharacter(player.Character)
end
player.CharacterAdded:Connect(watchCharacter)

refresh()
