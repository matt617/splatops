--!strict
-- Tiny client sound helper. Sfx.play("Splat") plays the configured sound non-spatially.
-- Unset config entries are silently skipped, so sounds are always safe to call.

local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Sfx = {}

function Sfx.play(name: string, volume: number?, speed: number?)
	local id = (Config.Sounds :: any)[name]
	if not id or id == "" then
		return
	end
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = volume or 0.5
	s.PlaybackSpeed = speed or 1
	s.Parent = SoundService
	s:Play()
	Debris:AddItem(s, 5)
end

return Sfx
