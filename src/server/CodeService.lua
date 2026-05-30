--!strict
-- Share codes for private lobbies. Creating a lobby reserves a match server and stores a
-- short code -> access code mapping in MemoryStore so any server can look it up. Friends
-- redeem the code to teleport into the host's reserved server. Every external call is
-- wrapped so a service hiccup returns nil rather than throwing.

local TeleportService = game:GetService("TeleportService")
local MemoryStoreService = game:GetService("MemoryStoreService")

local CodeService = {}

local CODE_TTL = 3600 -- a code is good for an hour
local ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" -- no ambiguous O/0/I/1
local rng = Random.new()

-- lazily fetch the hash map so module load never fails on a service problem
local map
local function getMap()
	if map then
		return map
	end
	local ok, result = pcall(function()
		return MemoryStoreService:GetHashMap("SplatOpsLobbies")
	end)
	if ok then
		map = result
	else
		warn("[CodeService] GetHashMap failed:", result)
	end
	return map
end

local function randomCode(): string
	local chars = {}
	for i = 1, 5 do
		local n = rng:NextInteger(1, #ALPHABET)
		chars[i] = string.sub(ALPHABET, n, n)
	end
	return table.concat(chars)
end

-- Reserve a match server and register a fresh code for it. Returns (code, accessCode) or nil.
function CodeService.createLobby(): (string?, string?)
	local hashMap = getMap()
	if not hashMap then
		return nil, nil
	end
	local ok, accessCode = pcall(function()
		return TeleportService:ReserveServer(game.PlaceId)
	end)
	if not ok or type(accessCode) ~= "string" then
		warn("[CodeService] ReserveServer failed:", accessCode)
		return nil, nil
	end
	local code = randomCode()
	local setOk, setErr = pcall(function()
		hashMap:SetAsync(code, accessCode, CODE_TTL)
	end)
	if not setOk then
		warn("[CodeService] SetAsync failed:", setErr)
		return nil, nil
	end
	return code, accessCode
end

-- Look up the reserved-server access code for a share code, or nil if unknown/expired.
function CodeService.lookup(code: string): string?
	local hashMap = getMap()
	if not hashMap then
		return nil
	end
	local ok, accessCode = pcall(function()
		return hashMap:GetAsync(string.upper(code))
	end)
	if ok and type(accessCode) == "string" then
		return accessCode
	end
	return nil
end

return CodeService
