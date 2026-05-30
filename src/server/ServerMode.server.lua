--!strict
-- Publishes this server's role (entry/party) to clients as an attribute. Clients MUST read
-- this instead of computing it themselves: PrivateServerId is not reliably visible on the
-- client, so a reserved (party) server can otherwise look like an entry server and wrongly
-- show the Create/Join menu.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LobbyMode = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("LobbyMode"))

ReplicatedStorage:SetAttribute("ServerMode", LobbyMode.get())
