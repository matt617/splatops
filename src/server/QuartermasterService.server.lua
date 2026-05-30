--!strict
-- Quartermaster: a proximity prompt on each base kiosk opens the shop, and PurchaseItem
-- validates the buy, spends coins, and hands over the weapon. Party servers only.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local LobbyMode = require(Shared:WaitForChild("LobbyMode"))
if LobbyMode.get() ~= "party" then
	return
end

local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Economy = require(ServerScriptService:WaitForChild("Economy"))

local templates = ReplicatedStorage:WaitForChild("WeaponTemplates")

local function ownsWeapon(player: Player, name: string): boolean
	local backpack = player:FindFirstChildOfClass("Backpack")
	if backpack and backpack:FindFirstChild(name) then
		return true
	end
	return player.Character ~= nil and player.Character:FindFirstChild(name) ~= nil
end

Remotes.PurchaseItem.OnServerInvoke = function(player, itemName)
	local weapon = type(itemName) == "string" and Config.Weapons[itemName] or nil
	if not weapon or (weapon.Price or 0) <= 0 then
		return { ok = false, message = "That is not for sale." }
	end
	if not templates:FindFirstChild(itemName) then
		return { ok = false, message = "Out of stock." }
	end
	if ownsWeapon(player, itemName) then
		return { ok = false, message = "You already own that." }
	end
	if not Economy.spend(player, weapon.Price) then
		return { ok = false, message = "Not enough coins." }
	end
	local backpack = player:FindFirstChildOfClass("Backpack")
	if backpack then
		templates[itemName]:Clone().Parent = backpack
	end
	return { ok = true, message = "Bought the " .. weapon.DisplayName .. "!" }
end

-- a "Quartermaster" prompt on each base kiosk
local function hookKiosk(qm: Instance?)
	if not qm or not qm:IsA("BasePart") then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Quartermaster"
	prompt.ObjectText = "Buy gear"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = qm
	prompt.Triggered:Connect(function(player)
		Remotes.OpenShop:FireClient(player)
	end)
end

local arena = Workspace:WaitForChild("Arena")
for _, baseName in { "RedBase", "BlueBase" } do
	local base = arena:FindFirstChild(baseName)
	hookKiosk(base and base:FindFirstChild("Quartermaster"))
end
