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
	IntermissionSeconds = 30, -- between matches in a persistent lobby
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
	MaxHealth = 500, -- tune so a sustained team push takes ~2 to 4 minutes
	HitsToDamageRatio = 1, -- 1 paint hit = 1 damage by default
	RegenPerSecond = 0, -- no regen for v1, keep pressure meaningful
}

-- ============================================================================
-- ECONOMY
-- ============================================================================

Config.Economy = {
	CoinsPerTag = 25,
	CoinsPerTowerHit = 5,
	StartingCoins = 0,
	CoinsResetEachMatch = true,
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
		SpreadDegrees = 0, -- 0 = the ball lands where you tap (kid friendly); raise to scatter
	},
	ReconMarker = {
		DisplayName = "Recon Marker",
		Description = "Long-range sniper. Slow but precise.",
		Price = 150,
		Damage = 2, -- two-tap from range
		FireRateSeconds = 1.0,
		MaxRangeStuds = 500,
		AmmoPerMag = 5,
		ReloadSeconds = 2.5,
		PaintColor = "TEAM",
	},
	Scattergun = {
		DisplayName = "Scattergun",
		Description = "Close-range spread. Devastating in corridors.",
		Price = 125,
		Damage = 1, -- per pellet, ~6 pellets per shot
		PelletsPerShot = 6,
		SpreadDegrees = 12,
		FireRateSeconds = 0.6,
		MaxRangeStuds = 60,
		AmmoPerMag = 6,
		ReloadSeconds = 2.0,
		PaintColor = "TEAM",
	},
	Mortar = {
		DisplayName = "Paint Mortar",
		Description = "Lobbed paint shell. Splashes on impact.",
		Price = 200,
		Damage = 2, -- direct hit, splash does 1
		SplashDamage = 1,
		SplashRadiusStuds = 12,
		FireRateSeconds = 2.0,
		ProjectileSpeed = 75,
		ArcGravity = true,
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
}

return Config
