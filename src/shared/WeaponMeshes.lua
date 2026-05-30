--!strict
-- 3D model part lists for the uploaded weapon meshes. WeaponModel loads each MeshPart by id
-- (cached), scales it by `scale`, colors it by `role` (body, trim, or team for the squad-tinted
-- bits), and welds it to the Handle at `pos` (offset from the body, in the model's own units;
-- all imported parts share identity rotation). Add a weapon here and WeaponModel uses the 3D
-- model instead of the old part-built cosmetic. Offsets/sizes come from the uploaded import.

export type Part = { name: string, mesh: string, size: { number }, pos: { number }, role: string }
export type Def = { scale: number, parts: { Part } }

local WeaponMeshes: { [string]: Def } = {}

WeaponMeshes.AssaultMarker = {
	scale = 2.4,
	parts = {
		{ name = "Body", mesh = "rbxassetid://83465217184289", size = { 0.264, 0.194, 0.620 }, pos = { 0, 0, 0 }, role = "body" },
		{ name = "Barrel", mesh = "rbxassetid://132784618856889", size = { 0.090, 0.090, 0.760 }, pos = { 0, 0, -0.650 }, role = "body" },
		{ name = "Muzzle", mesh = "rbxassetid://138326523427660", size = { 0.110, 0.110, 0.100 }, pos = { 0, 0, -1.030 }, role = "trim" },
		{ name = "TopRail", mesh = "rbxassetid://116702896023833", size = { 0.100, 0.035, 0.340 }, pos = { 0, 0.115, -0.160 }, role = "trim" },
		{ name = "Sight", mesh = "rbxassetid://127260555481859", size = { 0.120, 0.050, 0.060 }, pos = { 0, 0.155, -0.250 }, role = "trim" },
		{ name = "FeedNeck", mesh = "rbxassetid://131613751075908", size = { 0.110, 0.110, 0.110 }, pos = { 0, 0.160, -0.020 }, role = "body" },
		{ name = "Hopper", mesh = "rbxassetid://72890377742358", size = { 0.432, 0.368, 0.368 }, pos = { 0, 0.320, 0 }, role = "team" },
		{ name = "HopperLid", mesh = "rbxassetid://72545707309436", size = { 0.140, 0.030, 0.140 }, pos = { 0, 0.500, 0 }, role = "team" },
		{ name = "Grip", mesh = "rbxassetid://95132335796485", size = { 0.160, 0.393, 0.201 }, pos = { 0, -0.270, 0.046 }, role = "body" },
		{ name = "TriggerGuard", mesh = "rbxassetid://75196047181587", size = { 0.110, 0.070, 0.100 }, pos = { 0, -0.090, 0 }, role = "trim" },
		{ name = "Foregrip", mesh = "rbxassetid://95581666204834", size = { 0.110, 0.220, 0.107 }, pos = { 0, -0.160, -0.360 }, role = "body" },
		{ name = "RearCap", mesh = "rbxassetid://131851104167336", size = { 0.160, 0.133, 0.180 }, pos = { 0, 0.010, 0.380 }, role = "trim" },
	},
}

return WeaponMeshes
