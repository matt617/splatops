--!strict
-- Admin powers. Admins (Config.Admin.UserIds) always get: fly, every weapon, and infinite ammo
-- (Combat skips ammo for them). The server is the source of truth: it sets the IsAdmin / CanFly
-- attributes the client reads, hands out the weapons, and tags the player list. An admin can also
-- let ONE other player fly at a time for FlyGrantSeconds; after that they can grant again.

local Players = game:GetService("Players")
local StarterPack = game:GetService("StarterPack")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local templates = ReplicatedStorage:WaitForChild("WeaponTemplates")

local function isAdmin(player: Player): boolean
	return Config.Admin.UserIds[player.UserId] == true
end

-- give the admin one of every marker (skips ones they already hold)
local function giveAllWeapons(player: Player)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then
		return
	end
	local function giveOne(template: Instance?)
		if not template then
			return
		end
		local held = backpack:FindFirstChild(template.Name)
			or (player.Character and player.Character:FindFirstChild(template.Name))
		if not held then
			template:Clone().Parent = backpack
		end
	end
	giveOne(StarterPack:FindFirstChild("AssaultMarker"))
	for _, t in templates:GetChildren() do
		giveOne(t)
	end
end

-- a Rank entry in leaderstats shows up as a column in the Roblox player list
local function setRank(player: Player, rank: string)
	local stats = player:FindFirstChild("leaderstats")
	if not stats then
		stats = Instance.new("Folder")
		stats.Name = "leaderstats"
		stats.Parent = player
	end
	local r = stats:FindFirstChild("Rank") :: StringValue?
	if not r then
		r = Instance.new("StringValue")
		r.Name = "Rank"
		r.Parent = stats
	end
	r.Value = rank
end

-- one guest fly grant at a time
local granteeUserId: number? = nil
local grantToken = 0

local function publishGrant(name: string, expiry: number)
	ReplicatedStorage:SetAttribute("FlyGrantee", name)
	ReplicatedStorage:SetAttribute("FlyGranteeExpiry", expiry)
end

local function clearGrant()
	if granteeUserId then
		local p = Players:GetPlayerByUserId(granteeUserId)
		if p and not isAdmin(p) then
			p:SetAttribute("CanFly", false)
		end
	end
	granteeUserId = nil
	publishGrant("", 0)
end

local function grantFly(admin: Player, target: Player?)
	if not isAdmin(admin) or not target or target == admin or isAdmin(target) then
		return
	end
	-- only one active grant; the admin waits for it to expire before granting again
	if granteeUserId and Players:GetPlayerByUserId(granteeUserId) then
		return
	end
	clearGrant()
	granteeUserId = target.UserId
	grantToken += 1
	local myToken = grantToken
	target:SetAttribute("CanFly", true)
	publishGrant(target.Name, os.time() + Config.Admin.FlyGrantSeconds)
	task.delay(Config.Admin.FlyGrantSeconds, function()
		if grantToken == myToken then
			clearGrant()
		end
	end)
end

Remotes.GrantFly.OnServerEvent:Connect(function(admin, targetName)
	local target = type(targetName) == "string" and Players:FindFirstChild(targetName) or nil
	grantFly(admin, target :: Player?)
end)

local function setupPlayer(player: Player)
	if isAdmin(player) then
		player:SetAttribute("IsAdmin", true)
		player:SetAttribute("CanFly", true)
		setRank(player, "\u{2605} ADMIN")
	end
	local function onCharacter(_character: Model)
		if isAdmin(player) then
			task.wait(0.4) -- let the StarterPack loadout populate first
			giveAllWeapons(player)
		end
	end
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		onCharacter(player.Character)
	end
end

for _, p in Players:GetPlayers() do
	setupPlayer(p)
end
Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(function(p)
	if granteeUserId == p.UserId then
		clearGrant()
	end
end)

publishGrant("", 0)
