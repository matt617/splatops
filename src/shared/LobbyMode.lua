--!strict
-- One place, two roles:
--   "entry" = the public landing server, where players create or join a private lobby.
--   "party" = a reserved private-lobby server (the practice range + matches run here).
-- In Studio we always report "party" so the lobby and match loop are testable without
-- teleports (which do not work in Studio anyway).

local RunService = game:GetService("RunService")

local LobbyMode = {}

function LobbyMode.get(): string
	if RunService:IsStudio() then
		return "party"
	end
	-- reserved servers (from TeleportService:ReserveServer) have a private id and no owner
	if game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0 then
		return "party"
	end
	return "entry"
end

return LobbyMode
