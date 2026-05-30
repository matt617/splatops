--!strict
-- 3D model part lists for the uploaded weapon meshes. WeaponModel loads each MeshPart by id
-- (cached), scales it by `scale`, colors it by `role` (body, trim, or team for the squad-tinted
-- bits), and welds it to the Handle at `pos` (offset from the body, in the model's own units;
-- all imported parts share identity rotation). Add a weapon here and WeaponModel uses the 3D
-- model instead of the old part-built cosmetic. Offsets/sizes come from the uploaded import.

export type Part = { name: string, mesh: string, size: { number }, pos: { number }, role: string }
export type Def = { scale: number, baseRot: CFrame?, parts: { Part } }

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

-- Recon: imported barrel-up (+Y). Rotate so the barrel points forward (-Z), scope up, grip down.
WeaponMeshes.ReconMarker = {
	scale = 0.8,
	baseRot = CFrame.fromMatrix(Vector3.zero, Vector3.new(-1, 0, 0), Vector3.new(0, 0, -1)),
	parts = {
		{ name = "Rounded_Main_Receiver", mesh = "rbxassetid://91292064290414", size = { 0.467, 2.170, 0.467 }, pos = { 0.000, 0.000, 0.000 }, role = "body" },
		{ name = "Lower_Rounded_Frame", mesh = "rbxassetid://73915960591556", size = { 0.269, 1.450, 0.269 }, pos = { 0.000, -0.080, 0.200 }, role = "body" },
		{ name = "Front_Barrel_Collar", mesh = "rbxassetid://86223664591573", size = { 0.310, 0.360, 0.310 }, pos = { 0.000, 0.930, -0.030 }, role = "body" },
		{ name = "Long_Sleek_Paintball_Barrel", mesh = "rbxassetid://105199337152115", size = { 0.136, 3.000, 0.136 }, pos = { 0.000, 2.480, -0.050 }, role = "body" },
		{ name = "Rounded_Muzzle_Cap", mesh = "rbxassetid://140021722069619", size = { 0.210, 0.220, 0.210 }, pos = { 0.000, 4.090, -0.050 }, role = "trim" },
		{ name = "Soft_Barrel_Ring_1", mesh = "rbxassetid://136597532145492", size = { 0.176, 0.120, 0.176 }, pos = { 0.000, 1.540, -0.050 }, role = "body" },
		{ name = "Soft_Barrel_Ring_2", mesh = "rbxassetid://95375517002887", size = { 0.164, 0.120, 0.164 }, pos = { 0.000, 2.440, -0.050 }, role = "body" },
		{ name = "Soft_Barrel_Ring_3", mesh = "rbxassetid://74272036614014", size = { 0.156, 0.120, 0.156 }, pos = { 0.000, 3.290, -0.050 }, role = "body" },
		{ name = "Chunky_Toy_Scope_Tube", mesh = "rbxassetid://70892232884722", size = { 0.310, 1.520, 0.310 }, pos = { 0.000, 0.330, -0.560 }, role = "trim" },
		{ name = "Scope_Front_Bevel", mesh = "rbxassetid://102388808744761", size = { 0.370, 0.160, 0.370 }, pos = { 0.000, 1.130, -0.560 }, role = "trim" },
		{ name = "Scope_Rear_Bevel", mesh = "rbxassetid://86986668985267", size = { 0.350, 0.160, 0.350 }, pos = { 0.000, -0.470, -0.560 }, role = "trim" },
		{ name = "Scope_Front_Blue_Lens", mesh = "rbxassetid://78348555202997", size = { 0.270, 0.020, 0.270 }, pos = { 0.000, 1.227, -0.560 }, role = "glass" },
		{ name = "Scope_Rear_Blue_Lens", mesh = "rbxassetid://97160822366937", size = { 0.250, 0.020, 0.250 }, pos = { 0.000, -0.567, -0.560 }, role = "glass" },
		{ name = "Scope_Top_Turret", mesh = "rbxassetid://119187508893307", size = { 0.120, 0.120, 0.170 }, pos = { 0.000, 0.330, -0.785 }, role = "trim" },
		{ name = "Scope_Side_Turret", mesh = "rbxassetid://120886990850261", size = { 0.145, 0.100, 0.100 }, pos = { -0.218, 0.330, -0.560 }, role = "trim" },
		{ name = "Rear_Scope_Mount_Post", mesh = "rbxassetid://74154926616118", size = { 0.110, 0.110, 0.180 }, pos = { 0.000, -0.320, -0.320 }, role = "trim" },
		{ name = "Front_Scope_Mount_Post", mesh = "rbxassetid://103329775387822", size = { 0.110, 0.110, 0.180 }, pos = { 0.000, 0.710, -0.320 }, role = "trim" },
		{ name = "Rounded_Scope_Mount_Rail", mesh = "rbxassetid://103710686046703", size = { 0.220, 1.350, 0.070 }, pos = { 0.000, 0.180, -0.295 }, role = "trim" },
		{ name = "Slim_Ball_Hopper_TeamColor", mesh = "rbxassetid://104059439629397", size = { 0.438, 1.154, 0.330 }, pos = { -0.370, -0.050, -0.800 }, role = "team" },
		{ name = "Rounded_Hopper_Lid_TeamColor", mesh = "rbxassetid://136357952330307", size = { 0.140, 0.800, 0.140 }, pos = { -0.370, -0.070, -0.920 }, role = "team" },
		{ name = "Paintball_Feed_Neck", mesh = "rbxassetid://91344743864955", size = { 0.210, 0.101, 0.428 }, pos = { -0.285, -0.050, -0.440 }, role = "body" },
		{ name = "Rounded_Pistol_Grip", mesh = "rbxassetid://108226693204115", size = { 0.229, 0.421, 0.869 }, pos = { 0.000, -0.595, 0.535 }, role = "body" },
		{ name = "Grip_End_Cap", mesh = "rbxassetid://85142501453438", size = { 0.239, 0.226, 0.277 }, pos = { 0.000, -0.645, 0.905 }, role = "body" },
		{ name = "Soft_Toy_Trigger_Tab", mesh = "rbxassetid://98732271953740", size = { 0.077, 0.126, 0.319 }, pos = { 0.000, -0.275, 0.420 }, role = "trim" },
		{ name = "Upper_Stock_Rod", mesh = "rbxassetid://74714324142831", size = { 0.120, 0.956, 0.248 }, pos = { 0.000, -1.400, -0.135 }, role = "body" },
		{ name = "Lower_Stock_Rod", mesh = "rbxassetid://98782716677055", size = { 0.119, 0.953, 0.219 }, pos = { 0.000, -1.380, 0.200 }, role = "body" },
		{ name = "Rounded_Shoulder_Stock_Buttpad", mesh = "rbxassetid://106637338670589", size = { 0.308, 0.308, 1.080 }, pos = { 0.000, -2.020, 0.005 }, role = "body" },
		{ name = "Stock_Bridge", mesh = "rbxassetid://118985498136673", size = { 0.090, 0.090, 0.410 }, pos = { 0.000, -1.890, 0.025 }, role = "body" },
		{ name = "Folded_Bipod_Hinge", mesh = "rbxassetid://77007022808419", size = { 0.480, 0.097, 0.100 }, pos = { 0.000, 1.850, 0.220 }, role = "trim" },
		{ name = "Folded_Bipod_Left_Leg", mesh = "rbxassetid://138381651167173", size = { 0.090, 0.893, 0.213 }, pos = { 0.165, 2.295, 0.335 }, role = "trim" },
		{ name = "Folded_Bipod_Right_Leg", mesh = "rbxassetid://99043362810330", size = { 0.090, 0.893, 0.213 }, pos = { -0.165, 2.295, 0.335 }, role = "trim" },
		{ name = "Bipod_Left_Foot", mesh = "rbxassetid://79530578481036", size = { 0.200, 0.051, 0.054 }, pos = { 0.180, 2.720, 0.430 }, role = "trim" },
		{ name = "Bipod_Right_Foot", mesh = "rbxassetid://123641037285642", size = { 0.200, 0.051, 0.054 }, pos = { -0.180, 2.720, 0.430 }, role = "trim" },
		{ name = "Soft_Side_Panel_Left", mesh = "rbxassetid://75018500879712", size = { 0.035, 0.720, 0.220 }, pos = { 0.205, 0.030, -0.000 }, role = "body" },
		{ name = "Soft_Side_Panel_Right", mesh = "rbxassetid://129956254932749", size = { 0.035, 0.720, 0.220 }, pos = { -0.205, 0.030, -0.000 }, role = "body" },
		{ name = "Small_Blue_Pressure_Dot", mesh = "rbxassetid://105384849357142", size = { 0.020, 0.100, 0.100 }, pos = { -0.245, -0.270, -0.060 }, role = "body" },
	},
}

-- Mortar: imported barrel along +Z; flip 180 so it points forward (-Z) like the others.
WeaponMeshes.Mortar = {
	scale = 1.25,
	baseRot = CFrame.Angles(0, math.pi, 0),
	parts = {
		{ name = "Body_Gunmetal_mesh", mesh = "rbxassetid://109470586516573", size = { 0.880, 1.408, 3.028 }, pos = { 0.000, 0.000, 0.000 }, role = "body" },
		{ name = "TeamColor_canister_mesh", mesh = "rbxassetid://115653446225554", size = { 0.650, 0.877, 1.295 }, pos = { 0.000, 0.570, 0.089 }, role = "team" },
		{ name = "Grip_Rubber_mesh", mesh = "rbxassetid://113317615667543", size = { 0.900, 1.180, 2.500 }, pos = { 0.000, -0.541, -0.424 }, role = "body" },
		{ name = "Muzzle_Dark_mesh", mesh = "rbxassetid://73717324551116", size = { 0.570, 0.566, 0.110 }, pos = { -0.000, 0.272, 1.459 }, role = "trim" },
		{ name = "Sight_Matte_Black_mesh", mesh = "rbxassetid://131475875391075", size = { 0.200, 0.524, 0.545 }, pos = { 0.440, 0.451, 0.308 }, role = "trim" },
	},
}

-- Scattergun: imported barrel-up (+Y) like the Recon; same rotation to barrel-forward.
WeaponMeshes.Scattergun = {
	scale = 0.7,
	baseRot = CFrame.fromMatrix(Vector3.zero, Vector3.new(-1, 0, 0), Vector3.new(0, 0, -1)),
	parts = {
		{ name = "BlackRubber", mesh = "rbxassetid://139091976473196", size = { 0.736, 3.900, 1.528 }, pos = { 0.000, 0.000, 0.000 }, role = "trim" },
		{ name = "DarkGunmetal", mesh = "rbxassetid://123192519986175", size = { 0.922, 3.710, 1.043 }, pos = { 0.000, 0.035, -0.442 }, role = "body" },
		{ name = "TeamColor", mesh = "rbxassetid://129872914114454", size = { 1.112, 2.078, 1.627 }, pos = { 0.000, 0.506, -0.920 }, role = "team" },
		{ name = "DetailGray", mesh = "rbxassetid://94537357405597", size = { 1.030, 1.016, 1.220 }, pos = { 0.000, -0.045, -0.654 }, role = "body" },
		{ name = "SoftBlueGlass", mesh = "rbxassetid://95174327251050", size = { 0.240, 0.035, 0.140 }, pos = { 0.000, 0.335, -1.154 }, role = "glass" },
	},
}

return WeaponMeshes
