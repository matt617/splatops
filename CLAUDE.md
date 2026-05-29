# Splat Ops

A 4v4 paintball Roblox game built for an 8-year-old and his friends. Private lobbies only.
First team to destroy the enemy comms tower wins the match.

## Design constraints (DO NOT CHANGE WITHOUT ASKING)

These are locked decisions. Confirm with the user before deviating.

### Core gameplay
- 4v4, two teams (Red, Blue)
- Win condition: destroy enemy comms tower
- Player health: 3 hits, no health regen mid-life
- Respawn: 5 seconds at own base
- Match length: target 5 to 15 minutes
- Per-round economy, resets every match

### Visuals and tone
- Military paintball facility aesthetic
- All hits are paint splatters, never blood
- Tag-out shows an ELIMINATED stamp, not death
- No damage numbers, just splat VFX
- Target audience is 8-year-olds, keep it kid-appropriate

### Architecture
- Server-authoritative for ALL hit detection, damage, economy, and respawn logic
- Client only handles input, camera, prediction, and visual effects
- Never trust the client for anything that affects gameplay state
- Private lobbies only for v1, no matchmaking

### Progression
- In-match economy: coins from tags and tower damage, spent at the quartermaster
- Meta progression is cosmetic only, never gameplay advantages

## Map layout

One polished map for v1. Three-lane symmetric military paintball arena.

- Two command posts at opposite ends, each with a comms tower, quartermaster, and respawn point
- Three sectors connect the bases: Left, Mid, Right
- Vertical cover: crates, watchtowers, rooftops
- Contested middle area where lanes converge
- Cover everywhere so players being outshot can break line of sight

## Code conventions

- Luau with `--!strict` at the top of modules where practical
- Server scripts: `*.server.lua`
- Client scripts: `*.client.lua`
- Module scripts: `*.lua`
- One responsibility per script
- All tunable values live in `src/shared/Config.lua`, never hardcoded in logic
- All RemoteEvents and RemoteFunctions defined once in `src/shared/Remotes.lua`
- Type definitions live in `src/shared/Types.lua`

## Writing style (for any user-facing text, comments, and chat responses)

- No em dashes anywhere
- Plain, direct sentences
- Active voice
- No AI-sounding language ("delve", "tapestry", "navigate the landscape", etc.)
- Comments explain WHY, not what

## Build workflow with weppy MCP

Studio is live and connected via the weppy-roblox-mcp server. Use it.

### For code changes
- Prefer writing to disk via the Rojo project (so changes are in git)
- For quick experiments, `manage_scripts` can edit Studio directly, but commit important changes to disk

### For level and map changes
- Use `mutate_instances`, `manage_terrain`, `manage_lighting`, `manage_properties`
- Build gray-box blockouts first, art-pass later

### Verification is mandatory
Before declaring any task done:
1. Verify the change with `query_instances` or `workspace_state`
2. For visual changes, take a screenshot with `manage_camera` and `manage_studio`
3. Check `manage_logs` for errors
4. For new weapons or systems, spawn a test dummy and run `execute_luau` to simulate the interaction

### Cleanup
- Remove test dummies, temporary parts, and debug prints when a task is done
- Do not leave clutter in the workspace between sessions

## Build order (v1)

Ship each step playable before moving to the next.

1. Weapon system: Tool with paint hits, 3-hit health, server-authoritative
2. One map blockout: gray boxes, no art, just shapes that play well
3. Comms tower object with destroy logic and win condition
4. Private lobby system: host, share code, teleport friends in
5. Quartermaster and per-round economy
6. Stats screen and match-to-match flow
7. Art pass over the map and tools

## Known constraints

- The 3D map will need some manual work in Studio. weppy can build gray-box, you finish the polish.
- Studio is fragile, commit to git often
- Use Play Solo for gameplay testing, not edit-mode mutations
