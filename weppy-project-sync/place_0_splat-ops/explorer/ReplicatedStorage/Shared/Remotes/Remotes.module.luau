--!strict
-- Splat Ops RemoteEvents and RemoteFunctions.
-- All client-server communication goes through these. Defined once, used everywhere.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

local function getOrCreateFolder(parent: Instance, name: string): Folder
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("Folder") then
		return existing
	end
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

local function getOrCreateRemote(parent: Folder, name: string, className: string): Instance
	local existing = parent:FindFirstChild(name)
	if existing then
		return existing
	end
	local remote = Instance.new(className)
	remote.Name = name
	remote.Parent = parent
	return remote
end

-- Folder that holds all our remotes, keeps ReplicatedStorage tidy
local remotesFolder = getOrCreateFolder(ReplicatedStorage, "SplatOpsRemotes")

-- Combat
Remotes.FireWeapon = getOrCreateRemote(remotesFolder, "FireWeapon", "RemoteEvent")
Remotes.PlayerTagged = getOrCreateRemote(remotesFolder, "PlayerTagged", "RemoteEvent")
Remotes.PaintHitVFX = getOrCreateRemote(remotesFolder, "PaintHitVFX", "RemoteEvent")

-- Economy / Quartermaster
Remotes.PurchaseItem = getOrCreateRemote(remotesFolder, "PurchaseItem", "RemoteFunction")
Remotes.CoinsChanged = getOrCreateRemote(remotesFolder, "CoinsChanged", "RemoteEvent")

-- Match flow
Remotes.MatchStarting = getOrCreateRemote(remotesFolder, "MatchStarting", "RemoteEvent")
Remotes.MatchEnded = getOrCreateRemote(remotesFolder, "MatchEnded", "RemoteEvent")
Remotes.TowerDamaged = getOrCreateRemote(remotesFolder, "TowerDamaged", "RemoteEvent")

-- Lobby
Remotes.CreateLobby = getOrCreateRemote(remotesFolder, "CreateLobby", "RemoteFunction")
Remotes.JoinLobby = getOrCreateRemote(remotesFolder, "JoinLobby", "RemoteFunction")

return Remotes
