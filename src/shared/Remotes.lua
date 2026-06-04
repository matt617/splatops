--!strict
-- Splat Ops RemoteEvents and RemoteFunctions.
-- All client-server communication goes through these. Defined once, used everywhere.
-- The server is the sole creator; the client waits for them to replicate. That way the
-- client never fires on a local-only stand-in that the server cannot hear.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local IS_SERVER = RunService:IsServer()

local Remotes = {}

local function getFolder(): Folder
	if IS_SERVER then
		local existing = ReplicatedStorage:FindFirstChild("SplatOpsRemotes")
		if existing and existing:IsA("Folder") then
			return existing
		end
		local folder = Instance.new("Folder")
		folder.Name = "SplatOpsRemotes"
		folder.Parent = ReplicatedStorage
		return folder
	end
	return ReplicatedStorage:WaitForChild("SplatOpsRemotes") :: Folder
end

local remotesFolder = getFolder()

local function remote(name: string, className: string): Instance
	if IS_SERVER then
		local existing = remotesFolder:FindFirstChild(name)
		if existing then
			return existing
		end
		local r = Instance.new(className)
		r.Name = name
		r.Parent = remotesFolder
		return r
	end
	return remotesFolder:WaitForChild(name)
end

-- Combat
Remotes.FireWeapon = remote("FireWeapon", "RemoteEvent")
Remotes.ReloadWeapon = remote("ReloadWeapon", "RemoteEvent")
Remotes.PlayerTagged = remote("PlayerTagged", "RemoteEvent")
Remotes.PaintHitVFX = remote("PaintHitVFX", "RemoteEvent")

-- Lobby practice / tutorial
Remotes.PracticeProgress = remote("PracticeProgress", "RemoteEvent")

-- Economy / Quartermaster
Remotes.PurchaseItem = remote("PurchaseItem", "RemoteFunction")
Remotes.CoinsChanged = remote("CoinsChanged", "RemoteEvent")
Remotes.OpenShop = remote("OpenShop", "RemoteEvent") -- server tells a client to open the shop
Remotes.DogShot = remote("DogShot", "RemoteEvent") -- you splatted a hidden dog portrait, coins gone
Remotes.PowerUpEvent = remote("PowerUpEvent", "RemoteEvent") -- mid power-up spawned / claimed announcements
Remotes.StreakEvent = remote("StreakEvent", "RemoteEvent") -- tag streak banners (name, label, count)

-- Match flow
Remotes.MatchStarting = remote("MatchStarting", "RemoteEvent")
Remotes.MatchEnded = remote("MatchEnded", "RemoteEvent")
Remotes.TowerDamaged = remote("TowerDamaged", "RemoteEvent")
Remotes.RequestStart = remote("RequestStart", "RemoteEvent") -- client asks to start (force?)
Remotes.ConfirmStart = remote("ConfirmStart", "RemoteEvent") -- server asks to confirm a short-handed start
Remotes.MatchStats = remote("MatchStats", "RemoteEvent") -- end-of-match scoreboard (winner, rows, intermission)
Remotes.MatchClock = remote("MatchClock", "RemoteEvent") -- match time remaining, in seconds
Remotes.TowerAlert = remote("TowerAlert", "RemoteEvent") -- tower health stage changed (ownerShort, stage)

-- Lobby
Remotes.CreateLobby = remote("CreateLobby", "RemoteFunction")
Remotes.JoinLobby = remote("JoinLobby", "RemoteFunction")

-- Admin
Remotes.GrantFly = remote("GrantFly", "RemoteEvent") -- admin asks the server to let a player fly
Remotes.AdminPowerUp = remote("AdminPowerUp", "RemoteEvent") -- admin gives themself a power-up effect

return Remotes
