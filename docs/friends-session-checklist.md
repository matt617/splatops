# First big friends session checklist

Run through this before the squad joins.

## Before the session

- [ ] **Publish the place.** Studio work stays local until you publish. File > Publish to Roblox.
- [ ] Game privacy: keep it **Private**, friends join through the share code flow.
- [ ] Play one solo round on the published game (not Studio) from the iPad: shop opens, weapons fire, splats appear, sounds play.
- [ ] Check your son's account shows the ADMIN badge and fly works on the iPad.

## What is built to handle kids being kids

- **Late joiners** during a match drop straight onto the smaller team at that base.
- **A team emptying out** mid-round hands the win to the team still standing.
- **Teams reshuffle** every round, so siblings do not get stuck against each other all night.
- **Comeback coins**: the team well behind on tower damage earns extra per tag.
- **Backpack reset** every round transition: no carrying last round's arsenal.

## During the session, watch for

- iPad frame rate in big fights (8 players + drums + mortar splats). If it chugs, lower
  `Config.VFX.PaintSplatMaxOnScreen` (120) and `PaintMarksPerHit` (3) and republish.
- Kids stuck neutral or in the wrong spawn: should not happen, but if it does, the host
  leaving and restarting the lobby resets everything.
- The share-code teleport flow with more than 2 to 3 players at once.

## Quick fixes mid-session

- Match too long or short: `Config.Match.MatchTimeLimitSeconds` (900).
- Tower dies too fast or slow: `Config.Tower.HealthPerPlayer` (75 per attacker).
- Mortar too strong: `Config.Drums` and `Config.Weapons.Mortar` knobs.
- All changes need a republish to reach the iPads.
