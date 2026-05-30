--!strict
-- Public landing server: handles "Create Lobby" and "Join with Code" from the menu, then
-- teleports the player into a reserved private-lobby server. Only runs on entry servers.

local TeleportService = game:GetService("TeleportService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local LobbyMode = require(Shared:WaitForChild("LobbyMode"))
if LobbyMode.get() ~= "entry" then
	return -- party servers run the lobby/match instead
end

local CodeService = require(ServerScriptService:WaitForChild("CodeService"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local function sendToLobby(player: Player, accessCode: string, code: string)
	local options = Instance.new("TeleportOptions")
	options.ReservedServerAccessCode = accessCode
	options:SetTeleportData({ code = code })
	local ok = pcall(function()
		TeleportService:TeleportAsync(game.PlaceId, { player }, options)
	end)
	if not ok then
		Remotes.MatchEnded:FireClient(player, "Teleport failed, try again")
	end
end

Remotes.CreateLobby.OnServerInvoke = function(player)
	local code, accessCode = CodeService.createLobby()
	if not code or not accessCode then
		return { ok = false, message = "Could not create a lobby right now." }
	end
	task.spawn(sendToLobby, player, accessCode, code)
	return { ok = true, code = code }
end

Remotes.JoinLobby.OnServerInvoke = function(player, code)
	if type(code) ~= "string" or #code < 3 then
		return { ok = false, message = "Enter a lobby code." }
	end
	local accessCode = CodeService.lookup(code)
	if not accessCode then
		return { ok = false, message = "No lobby found for that code." }
	end
	task.spawn(sendToLobby, player, accessCode, string.upper(code))
	return { ok = true }
end
