# Splat Ops

A 4v4 paintball Roblox game. Private lobbies, military paintball aesthetic, destroy-the-comms-tower win condition.

Built with Claude Code + the weppy-roblox-mcp server for live Studio integration.

## One-time setup

### 1. Install Aftman (toolchain manager)

```bash
brew install aftman
cd splat-ops
aftman init
aftman add rojo-rbx/rojo
aftman install
```

### 2. Install the Rojo plugin in Studio

Open Studio, go to the Toolbox, search for "Rojo", install the official plugin from Roblox Corporation.

### 3. Verify weppy MCP is connected

The weppy-roblox-mcp server should already be configured in your Claude Code MCP settings. If `weppy-roblox-mcp:system_info` returns a successful ping, you're good.

### 4. Initialize git

```bash
cd splat-ops
git init
git add .
git commit -m "Initial Splat Ops scaffold"
```

Optional, push to a private repo:

```bash
gh repo create splat-ops --private --source=. --push
```

## Starting a session

### Start Rojo

```bash
rojo serve
```

Leave this running. It serves the file system to Studio on port 34872.

### Open Studio

Open a fresh baseplate place, then in the Rojo plugin panel click "Connect". Studio is now live-syncing from disk.

### Start Claude Code

```bash
claude
```

When it asks what to work on, paste the first-session prompt below.

## First-session prompt

Paste this into Claude Code on the first run.

```
Read CLAUDE.md before doing anything else.

Then verify the weppy MCP connection with system_info. If it fails, stop and tell me.

Once connected, ship the v1 Assault Marker:

1. Build it as a Tool in src/tools/AssaultMarker/ (per Rojo, this goes into StarterPack)
2. Server-authoritative: client fires a RemoteEvent on activation, server does the raycast, applies damage, replicates the VFX
3. 3-hit health tracked as a NumberValue or attribute on the Humanoid
4. Team-aware: no friendly fire (use Config.Player.FriendlyFire)
5. Paint splatter VFX on hit (placeholder is fine, just colored decals on the hit surface)
6. ELIMINATED stamp UI on tag-out, then respawn at base after Config.Player.RespawnSeconds
7. Use values from src/shared/Config.lua, never hardcode
8. Use the RemoteEvents already defined in src/shared/Remotes.lua

Verification before declaring done:
- Spawn a test dummy 20 studs in front of the default spawn
- Use execute_luau to fire three simulated hits
- Confirm the dummy's hit count increments and it tags out on the third hit
- Take a screenshot of the paint splatter on the dummy
- Check manage_logs for errors
- Clean up the test dummy when done

Stop and ask if anything in CLAUDE.md or Config.lua needs clarifying before you build.
```

## Project structure

```
splat-ops/
├── default.project.json       Rojo config, maps folders to Studio services
├── CLAUDE.md                  Project context, design constraints, conventions
├── README.md                  This file
├── src/
│   ├── server/                → ServerScriptService
│   ├── client/                → StarterPlayerScripts
│   ├── shared/                → ReplicatedStorage/Shared
│   │   ├── Config.lua         All tunable values
│   │   └── Remotes.lua        All RemoteEvents and RemoteFunctions
│   └── tools/                 → StarterPack (weapons)
└── .gitignore
```

## Build order

Ship each step playable before moving to the next.

1. Weapon system (Assault Marker)
2. Map blockout (gray boxes)
3. Comms tower with destroy logic and win condition
4. Private lobby system
5. Quartermaster and per-round economy
6. Stats screen between matches
7. Art pass over the map and tools
