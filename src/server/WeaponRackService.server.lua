--!strict
-- Lobby weapon rack. Each mount on the rack (a part with a "Weapon" attribute, built by
-- build/practice_range.luau) gets a prompt that hands the player that marker for free so
-- they can test it on the range. Rack weapons live in the backpack only, so the LoadCharacter
-- at match start wipes them: matches always begin with just the Assault Marker. Party only.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local StarterPack = game:GetService("StarterPack")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local LobbyMode = require(Shared:WaitForChild("LobbyMode"))
if LobbyMode.get() ~= "party" then
	return
end

local Match = require(ServerScriptService:WaitForChild("Match"))

local templates = ReplicatedStorage:WaitForChild("WeaponTemplates")

-- where each weapon's template lives. The Assault Marker ships in StarterPack; the rest are
-- in the shared WeaponTemplates folder.
local function templateFor(name: string): Instance?
	if name == "AssaultMarker" then
		return StarterPack:FindFirstChild("AssaultMarker")
	end
	return templates:FindFirstChild(name)
end

local function alreadyHas(player: Player, name: string): boolean
	local backpack = player:FindFirstChildOfClass("Backpack")
	if backpack and backpack:FindFirstChild(name) then
		return true
	end
	return player.Character ~= nil and player.Character:FindFirstChild(name) ~= nil
end

local function give(player: Player, name: string)
	if Match.state ~= "Lobby" then
		return -- the rack is a lobby fixture; no grabbing gear mid-match
	end
	if alreadyHas(player, name) then
		return
	end
	local template = templateFor(name)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if template and backpack then
		template:Clone().Parent = backpack
	end
end

local function hookMount(mount: Instance)
	if not mount:IsA("BasePart") then
		return
	end
	local weaponName = mount:GetAttribute("Weapon")
	if type(weaponName) ~= "string" then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Take " .. weaponName
	prompt.ObjectText = "Weapon Rack"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = mount
	prompt.Triggered:Connect(function(player)
		give(player, weaponName)
	end)
end

local range = Workspace:WaitForChild("PracticeRange")
local rack = range:WaitForChild("WeaponRack")
for _, mount in rack:GetChildren() do
	hookMount(mount)
end
rack.ChildAdded:Connect(hookMount)
