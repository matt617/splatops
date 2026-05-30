--!strict
-- Public landing server: handles "Create Lobby" and "Join with Code" from the menu, then
-- teleports the player into a reserved private-lobby server. Only runs on entry servers.
-- The request handlers are always installed and always return a result, so the client menu
-- never hangs waiting on a reply.

local TeleportService = game:GetService("TeleportService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local LobbyMode = require(Shared:WaitForChild("LobbyMode"))
if LobbyMode.get() ~= "entry" then
	return -- party servers run the lobby/match instead
end

local Remotes = require(Shared:WaitForChild("Remotes"))

-- load the code service defensively so a service hiccup can't stop the handlers from being set
local CodeService
do
	local ok, mod = pcall(function()
		return require(ServerScriptService:WaitForChild("CodeService"))
	end)
	if ok then
		CodeService = mod
	else
		warn("[EntryService] CodeService failed to load:", mod)
	end
end

local function sendToLobby(player: Player, accessCode: string, code: string)
	local options = Instance.new("TeleportOptions")
	options.ReservedServerAccessCode = accessCode
	options:SetTeleportData({ code = code })
	local ok, err = pcall(function()
		TeleportService:TeleportAsync(game.PlaceId, { player }, options)
	end)
	if not ok then
		warn("[EntryService] teleport failed for", player.Name, err)
	end
end

Remotes.CreateLobby.OnServerInvoke = function(player)
	if not CodeService then
		return { ok = false, message = "Lobby service is unavailable right now." }
	end
	local ok, code, accessCode = pcall(CodeService.createLobby)
	print("[EntryService] CreateLobby for", player.Name, "->", ok, code)
	if not ok or type(code) ~= "string" or type(accessCode) ~= "string" then
		return { ok = false, message = "Could not create a lobby. Try again." }
	end
	task.spawn(sendToLobby, player, accessCode, code)
	return { ok = true, code = code }
end

Remotes.JoinLobby.OnServerInvoke = function(player, code)
	if not CodeService then
		return { ok = false, message = "Lobby service is unavailable right now." }
	end
	if type(code) ~= "string" or #code < 3 then
		return { ok = false, message = "Enter a lobby code." }
	end
	local ok, accessCode = pcall(CodeService.lookup, code)
	print("[EntryService] JoinLobby", code, "for", player.Name, "->", ok, accessCode ~= nil)
	if not ok or type(accessCode) ~= "string" then
		return { ok = false, message = "No lobby found for that code." }
	end
	task.spawn(sendToLobby, player, accessCode, string.upper(code))
	return { ok = true }
end
