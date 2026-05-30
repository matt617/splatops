--!strict
-- Shows the lobby's share code at the top of the screen so the host can read it out to
-- friends. Party servers only; hidden until a code exists (e.g. in Studio there is none).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- read the server's authoritative role; the client cannot reliably detect a reserved server
local function serverMode(): string
	while not ReplicatedStorage:GetAttribute("ServerMode") do
		task.wait(0.1)
	end
	return ReplicatedStorage:GetAttribute("ServerMode") :: string
end
if serverMode() ~= "party" then
	return
end

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "LobbyCodeHud"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.AnchorPoint = Vector2.new(0.5, 0)
label.Position = UDim2.new(0.5, 0, 0, 12)
label.Size = UDim2.fromOffset(320, 40)
label.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
label.BackgroundTransparency = 0.25
label.TextColor3 = Color3.fromRGB(120, 255, 150)
label.Font = Enum.Font.GothamBlack
label.TextScaled = true
label.Visible = false
label.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = label
local pad = Instance.new("UIPadding")
pad.PaddingLeft = UDim.new(0, 12)
pad.PaddingRight = UDim.new(0, 12)
pad.Parent = label

local function refresh()
	local code = ReplicatedStorage:GetAttribute("LobbyCode")
	if code then
		label.Text = "SHARE CODE:  " .. tostring(code)
		label.Visible = true
	else
		label.Visible = false
	end
end

refresh()
ReplicatedStorage:GetAttributeChangedSignal("LobbyCode"):Connect(refresh)
