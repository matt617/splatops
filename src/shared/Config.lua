--!strict
-- Splat Ops central config.
-- All tunable gameplay values live here. Never hardcode these in logic scripts.
-- If a number controls how the game feels, it belongs in this file.

local Config = {}

-- ============================================================================
-- MATCH SETTINGS
-- ============================================================================

Config.Match = {
	PlayersPerTeam = 4,
	TeamCount = 2,
	MinPlayersToStart = 2, -- low for testing, raise for real play
	MatchTimeLimitSeconds = 900, -- 15 minute hard cap, then highest tower damage wins
	IntermissionSeconds = 8, -- stats screen duration after a win before the next round
	AutoRematch = true, -- after the stats screen, auto-start the next round if enough players remain
}

-- ============================================================================
-- PLAYER
-- ============================================================================

Config.Player = {
	MaxHits = 3, -- hits before tag-out
	RespawnSeconds = 5,
	WalkSpeed = 16,
	JumpPower = 50,
	FriendlyFire = false,
}

-- ============================================================================
-- COMMS TOWER (the team objective)
-- ============================================================================

Config.Tower = {
	-- tower health scales with the attacking team: maxHealth = HealthPerPlayer x attackers,
	-- so time-to-destroy stays similar at any team size (1v1 up to 4v4).
	HealthPerPlayer = 75,
	HitsToDamageRatio = 1, -- 1 paint hit = 1 damage by default
	RegenPerSecond = 0, -- no regen for v1, keep pressure meaningful
}

-- ============================================================================
-- PAINT DRUMS (the shootable exploding barrels around the arena)
-- ============================================================================

Config.Drums = {
	SplashRadiusStuds = 14, -- anyone this close gets painted when a drum bursts
	SplashDamage = 1,
	RespawnSeconds = 30, -- the drum reappears after this
	VFXScale = 3.5, -- burst splats render this many times bigger than a normal hit
}

-- ============================================================================
-- POWER-UPS (timed pickup where the lanes meet)
-- ============================================================================

Config.PowerUps = {
	SpawnX = 0, -- mid lane convergence; ground height found by raycast
	SpawnZ = 0,
	FirstSpawnSeconds = 20, -- after the match starts
	RespawnSeconds = 45, -- after one is claimed
	Types = {
		GoldenPaintball = {
			DisplayName = "Golden Paintball",
			DurationSeconds = 20,
			SplatScale = 2.5, -- your hits paint giant splats while active
			BonusCoinsPerTag = 25, -- extra coins on every tag while active
			Color = Color3.fromRGB(255, 200, 40),
		},
		SpeedCleats = {
			DisplayName = "Speed Cleats",
			DurationSeconds = 15,
			WalkSpeedMultiplier = 1.35,
			Color = Color3.fromRGB(70, 220, 255),
		},
		PaintBomb = {
			DisplayName = "Paint Bomb",
			RadiusStuds = 16, -- bursts the moment you grab it
			Damage = 1,
			Color = Color3.fromRGB(235, 80, 220),
		},
	},
}

-- ============================================================================
-- ECONOMY
-- ============================================================================

Config.Economy = {
	CoinsPerTag = 25,
	CoinsPerTowerHit = 5,
	StartingCoins = 0,
	CoinsResetEachMatch = true,
	-- comeback help: the team that is well behind on tower damage earns more per tag,
	-- so matches stay close without touching the shooting itself
	ComebackMultiplier = 1.5,
	ComebackThresholdHits = 15, -- tower-hit deficit before the bonus kicks in
}

-- ============================================================================
-- WEAPONS
-- ============================================================================
-- All weapons are paint markers. Names matter, keep them military-paintball-coded.

Config.Weapons = {
	AssaultMarker = {
		DisplayName = "Assault Marker",
		Description = "Starter marker. Reliable at medium range.",
		Price = 0, -- starter weapon
		CardImage = "rbxassetid://139159382174571", -- cartoony card art, shared with the armory rack
		IconImage = "rbxassetid://93438725738260", -- square hotbar slot icon
		Damage = 1, -- 3 hits to tag-out
		FireRateSeconds = 0.2,
		MaxRangeStuds = 120, -- aim/travel cap; effective hit range is shorter (set by ballistics below)
		AmmoPerMag = 25,
		ReloadSeconds = 1.5,
		PaintColor = "TEAM", -- uses team color
		-- projectile feel: a paintball that flies and splats, not an instant laser
		ProjectileSpeed = 90, -- studs per second; with gravity below, effective range ~90 studs
		ProjectileGravity = 90, -- studs/s^2 downward; gives the paintball a visible arc
		ProjectileSize = 0.8, -- ball diameter in studs
		-- accuracy: tight on a single shot, blooms while you spray, recovers when you pause
		SpreadDegrees = 0.5, -- base spread per shot (small so single taps stay accurate)
		SpreadMaxDegrees = 6, -- worst-case spread while spraying
		SpreadPerShot = 1.7, -- spread added each shot (must out-pace recovery to bloom while spraying)
		SpreadRecoverPerSec = 6, -- spread recovered per second of not firing
	},
	ReconMarker = {
		DisplayName = "Recon Marker",
		Description = "Long-range sniper. Slow but precise.",
		Price = 150,
		CardImage = "rbxassetid://121820949874382",
		IconImage = "rbxassetid://127424298114216",
		Damage = 2, -- two-tap from range
		FireRateSeconds = 1.0,
		MaxRangeStuds = 500,
		AmmoPerMag = 5,
		ReloadSeconds = 2.5,
		PaintColor = "TEAM",
		ProjectileSpeed = 280, -- fast, flat sniper round
		ProjectileGravity = 0,
		ProjectileSize = 0.5,
		SpreadDegrees = 0, -- pinpoint
	},
	Scattergun = {
		DisplayName = "Scattergun",
		Description = "Close-range spread. Devastating in corridors.",
		Price = 125,
		CardImage = "rbxassetid://86080782756370",
		IconImage = "rbxassetid://73320649581293",
		Damage = 1, -- per pellet, ~6 pellets per shot
		PelletsPerShot = 6,
		SpreadDegrees = 12,
		FireRateSeconds = 0.6,
		MaxRangeStuds = 60,
		AmmoPerMag = 6,
		ReloadSeconds = 2.0,
		PaintColor = "TEAM",
		ProjectileSpeed = 110, -- short range, pellets spread by SpreadDegrees above
		ProjectileGravity = 0,
		ProjectileSize = 0.35,
	},
	Mortar = {
		DisplayName = "Paint Mortar",
		Description = "Lobbed paint shell. Splashes on impact.",
		Price = 200,
		CardImage = "rbxassetid://128414709052987",
		IconImage = "rbxassetid://88110252182024",
		Damage = 2, -- direct hit, splash does 1
		SplashDamage = 1,
		SplashRadiusStuds = 18, -- generous: the mortar is slow and hard to aim, the boom is the payoff
		SplashVFXScale = 3, -- impact splats render this many times bigger than a normal hit
		FireRateSeconds = 2.0,
		ProjectileSpeed = 75,
		ProjectileGravity = 110, -- big lobbed arc
		ProjectileSize = 1.0,
		MaxRangeStuds = 130,
		SpreadDegrees = 1,
		AmmoPerMag = 3,
		ReloadSeconds = 3.5,
		PaintColor = "TEAM",
	},
}

-- ============================================================================
-- DEFENSES (deployable items from the quartermaster)
-- ============================================================================

Config.Defenses = {
	AutoTurret = {
		DisplayName = "Auto Turret",
		Description = "Deployable turret that tags enemies in range.",
		Price = 175,
		Health = 50,
		DamagePerSecond = 1,
		RangeStuds = 40,
		LifetimeSeconds = 60,
		PlacementZone = "OWN_BASE_ONLY",
	},
	DeployableWall = {
		DisplayName = "Deployable Wall",
		Description = "Drop instant cover anywhere.",
		Price = 75,
		Health = 100,
		LifetimeSeconds = 45,
		PlacementZone = "ANYWHERE",
	},
	PersonalShield = {
		DisplayName = "Personal Shield",
		Description = "Blocks the next hit. One use.",
		Price = 100,
		BlocksHits = 1,
		DurationSeconds = 30,
	},
}

-- ============================================================================
-- UTILITY (player buffs from the quartermaster)
-- ============================================================================

Config.Utility = {
	SpeedBoost = {
		DisplayName = "Speed Boost",
		Description = "Faster movement for one life.",
		Price = 50,
		WalkSpeedMultiplier = 1.4,
		DurationLives = 1,
	},
	DoubleJump = {
		DisplayName = "Double Jump",
		Description = "Jump again in mid-air. Persists for the match.",
		Price = 100,
		Persists = "MATCH",
	},
	ScoutDrone = {
		DisplayName = "Scout Drone",
		Description = "Reveals enemy positions for 10 seconds.",
		Price = 125,
		RevealDurationSeconds = 10,
		Cooldown = "ONCE_PER_LIFE",
	},
}

-- ============================================================================
-- SOUNDS
-- ============================================================================
-- Engine-shipped sounds (rbxasset paths verified to load). Swap any for an
-- uploaded rbxassetid to upgrade it. Empty string disables that sound.

Config.Sounds = {
	Splat = "rbxasset://sounds/splat.wav", -- every paint impact, spatial
	DrumBoom = "rbxasset://sounds/impact_water.mp3", -- paint drum burst
	HitTaken = "rbxasset://sounds/snap.mp3", -- you took a hit
	TaggedOut = "rbxasset://sounds/uuhhh.mp3", -- the classic, on tag-out
	MatchStart = "rbxasset://sounds/electronicpingshort.wav",
	Victory = "rbxasset://sounds/victory.wav", -- end-of-match fanfare
	PowerUpSpawn = "rbxasset://sounds/electronicpingshort.wav",
	PowerUpClaim = "rbxasset://sounds/short spring sound.wav",
	Streak = "rbxasset://sounds/flashbulb.wav", -- streak banner sting
	DogShot = "rbxasset://sounds/glassbreak.wav", -- you splatted Luna
	Purchase = "rbxasset://sounds/button.wav", -- shop buy
}

-- ============================================================================
-- TEAM COLORS (used for paint, UI, team markers)
-- ============================================================================

Config.Teams = {
	Red = {
		Name = "Red Squad",
		PaintColor = Color3.fromRGB(220, 50, 50),
		SpawnSide = "WEST",
	},
	Blue = {
		Name = "Blue Squad",
		PaintColor = Color3.fromRGB(50, 100, 220),
		SpawnSide = "EAST",
	},
}

-- ============================================================================
-- VFX / FEEL
-- ============================================================================

Config.VFX = {
	PaintSplatterSizeStuds = 2,
	PaintSplatterDecalDurationSeconds = 30,
	HitFlashDurationSeconds = 0.15,
	EliminatedStampDurationSeconds = 2.0,
	TaggedOutAnimation = "CHICKEN", -- placeholder identifier, swap with actual asset

	-- Paint splatter art. Grayscale (white) splatter images with alpha, tinted to the team color.
	-- Fill PaintSplatterImages with the uploaded asset ids; with none set, splats fall back to the
	-- plain disc. 1 to MarksPerHit decals spawn per hit, each a random image/rotation/size.
	PaintSplatterImages = {
		"rbxassetid://103190875348978",
		"rbxassetid://102882379151953",
		"rbxassetid://115401322885775",
		"rbxassetid://86256540759573",
		"rbxassetid://115106813588253",
		"rbxassetid://139407973278090",
		"rbxassetid://138243015157213",
		"rbxassetid://83113244165417",
	},
	PaintDropletImage = "rbxassetid://134349679205486", -- single droplet, used for the impact particle burst
	PaintMarksPerHit = 3, -- up to this many overlapping marks per confirmed hit
	PaintSplatMaxOnScreen = 120, -- recycle the oldest beyond this, to stay light on iPad
}

-- ============================================================================
-- ADMIN
-- ============================================================================

Config.Admin = {
	-- always-admin user ids. Admins fly, hold every weapon, and never run out of ammo.
	UserIds = {
		[9391744435] = true, -- the host's son
	},
	FlyGrantSeconds = 300, -- an admin can let one other player fly for this long, then grant again
	FlySpeed = 80, -- studs/sec while flying
	IconId = "rbxassetid://102774377713516", -- admin HUD badge image
}

return Config
