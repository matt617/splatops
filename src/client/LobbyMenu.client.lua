--!strict
-- Entry-server menu: Create a private lobby or join a friend's with their code. After a
-- successful request the server teleports the player into the reserved lobby. Only shown on
-- the public landing server (in a party/reserved server, players are already in the lobby).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local Shared = ReplicatedStorage:WaitForChild("Shared")

-- read the server's authoritative role; the client cannot reliably detect a reserved server
local function serverMode(): string
	while not ReplicatedStorage:GetAttribute("ServerMode") do
		task.wait(0.1)
	end
	return ReplicatedStorage:GetAttribute("ServerMode") :: string
end
if serverMode() ~= "entry" then
	return -- already inside a party lobby; no menu here
end
local Remotes = require(Shared:WaitForChild("Remotes"))

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "LobbyMenu"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 10
gui.Parent = player:WaitForChild("PlayerGui")

local bg = Instance.new("Frame")
bg.Size = UDim2.fromScale(1, 1)
bg.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
bg.BackgroundTransparency = 0.05
bg.Parent = gui

local title = Instance.new("TextLabel")
title.AnchorPoint = Vector2.new(0.5, 0)
title.Position = UDim2.fromScale(0.5, 0.12)
title.Size = UDim2.fromScale(0.6, 0.14)
title.BackgroundTransparency = 1
title.Text = "SPLAT OPS"
title.TextColor3 = Color3.fromRGB(255, 230, 90)
title.Font = Enum.Font.GothamBlack
title.TextScaled = true
title.Parent = bg

local status = Instance.new("TextLabel")
status.AnchorPoint = Vector2.new(0.5, 0)
status.Position = UDim2.fromScale(0.5, 0.30)
status.Size = UDim2.fromScale(0.7, 0.06)
status.BackgroundTransparency = 1
status.Text = "Create a lobby, or join a friend with their code."
status.TextColor3 = Color3.fromRGB(220, 220, 220)
status.Font = Enum.Font.Gotham
status.TextScaled = true
status.Parent = bg

local function button(pos: number, color: Color3, text: string): TextButton
	local b = Instance.new("TextButton")
	b.AnchorPoint = Vector2.new(0.5, 0)
	b.Position = UDim2.fromScale(0.5, pos)
	b.Size = UDim2.fromScale(0.34, 0.1)
	b.BackgroundColor3 = color
	b.Text = text
	b.TextColor3 = Color3.fromRGB(255, 255, 255)
	b.Font = Enum.Font.GothamBlack
	b.TextScaled = true
	b.Parent = bg
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 10)
	c.Parent = b
	return b
end

local createBtn = button(0.42, Color3.fromRGB(70, 200, 100), "CREATE LOBBY")

local codeBox = Instance.new("TextBox")
codeBox.AnchorPoint = Vector2.new(0.5, 0)
codeBox.Position = UDim2.fromScale(0.5, 0.58)
codeBox.Size = UDim2.fromScale(0.34, 0.09)
codeBox.BackgroundColor3 = Color3.fromRGB(40, 42, 50)
codeBox.PlaceholderText = "ENTER CODE"
codeBox.Text = ""
codeBox.TextColor3 = Color3.fromRGB(255, 255, 255)
codeBox.Font = Enum.Font.GothamBold
codeBox.TextScaled = true
codeBox.ClearTextOnFocus = false
codeBox.Parent = bg
local cc = Instance.new("UICorner")
cc.CornerRadius = UDim.new(0, 10)
cc.Parent = codeBox

local joinBtn = button(0.69, Color3.fromRGB(60, 120, 220), "JOIN WITH CODE")

local busy = false
local token = 0 -- guards against a stale timeout resetting a newer request
local function setBusy(b: boolean, msg: string?)
	busy = b
	createBtn.AutoButtonColor = not b
	joinBtn.AutoButtonColor = not b
	if msg then
		status.Text = msg
	end
end

-- begin a request: show a message and arm a timeout so the menu can never hang forever
local function begin(msg: string): number
	token += 1
	local mine = token
	setBusy(true, msg)
	task.delay(15, function()
		if busy and token == mine then
			setBusy(false, "That took too long. Check your connection and try again.")
		end
	end)
	return mine
end

createBtn.MouseButton1Click:Connect(function()
	if busy then
		return
	end
	local mine = begin("Creating lobby...")
	task.spawn(function()
		local ok, res = pcall(function()
			return Remotes.CreateLobby:InvokeServer()
		end)
		if token ~= mine then
			return
		end
		if ok and res and res.ok then
			status.Text = "Code: " .. res.code .. "   -   teleporting..."
		else
			setBusy(false, (res and res.message) or "Could not create a lobby.")
		end
	end)
end)

joinBtn.MouseButton1Click:Connect(function()
	if busy then
		return
	end
	local code = string.upper((codeBox.Text:gsub("%s", "")))
	if #code < 3 then
		status.Text = "Enter your friend's code."
		return
	end
	local mine = begin("Joining " .. code .. "...")
	task.spawn(function()
		local ok, res = pcall(function()
			return Remotes.JoinLobby:InvokeServer(code)
		end)
		if token ~= mine then
			return
		end
		if ok and res and res.ok then
			status.Text = "Found it! Teleporting..."
		else
			setBusy(false, (res and res.message) or "Could not join that lobby.")
		end
	end)
end)

-- if the teleport itself fails, show why instead of sitting on "teleporting..."
TeleportService.TeleportInitFailed:Connect(function(who: Player, _result, message: string)
	if who == player then
		setBusy(false, "Teleport failed. Try again.\n" .. tostring(message))
	end
end)
