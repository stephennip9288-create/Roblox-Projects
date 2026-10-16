# Dead Signal v1.8.0 — pursuit and environment overhaul candidate

This continues the v1.7.0 build. It contains four native Roblox Studio places, installed creator-owned art/material references, current source, offline checks, and the previous native milestone as a rollback. No live place was published or overwritten.

Mobile controls testing is deferred. Existing Tap, Left and Classic candidates, customization and saved preferences remain available. This delivery does not declare a device-tested winner.

## Play locally

1. Extract the ZIP, then open `Places/DeadSignal-v1.8.0-Station.rbxl` in Roblox Studio.
2. Press Play. The existing Studio preview admission starts the operation after its arrival period. Studio persistence remains disabled.
3. Test Foundry and Frost the same way. Open the Lobby file to test Dispatch. Production teleports require a published experience; they cannot be proved by local play.
4. For deliberate pursuit trials, use the server Command Bar:

```lua
local D = require(game.ServerScriptService.DeadSignalServer.Diagnostics)
D.openAll()
D.pursuit("Shambler") -- also Runner, Hound, Crawler, Warden
D.status()
```

Run between sectors, through both diagonal shortcuts, and up/down the galleries. `D.ragdoll("Hound")` spawns an NPC near the first operator and eliminates it after 0.8 seconds. Use this only in a disposable Studio session; eliminating a Warden changes boss state.

## What changed

- Pursuit now computes native paths to the moving player instead of following mandatory room-center anchors. Floor/root height normalization, waypoint plane progress, retained paths during asynchronous refresh, blocked-path recovery and crowd steering replace the previous movement loop.
- Living NPCs have physical collision bodies and collide with players and each other. Jointed limbs handle presentation and hit zones; corpses collide with the world without pinning living players.
- Zombies, runners, the Warden, hounds and crawlers use rebuilt articulated rigs. Forward is consistently negative Z; reaching/swing direction is corrected. Crawlers have raised, forward-facing heads. Hounds have a closed fur-textured body and articulated legs/tail with their detailed head retained. Existing textured assets are rebound and combined with new joint coverage. This is a model/rig revision, not a newly sculpted AAA asset pack.
- Every enemy elimination uses a pose-captured ragdoll. Articulated joints become constrained bodies. Only motionless corpses settle, with a 30-second lifetime and a count limit.
- Rooms now have actual round, hexagonal, octagonal and rectangular footprints. Nine **unique** sector pairs include new 1↔5 and 3↔5 diagonal routes. Floors, walls, corridor bends, galleries and objective placement were rebuilt around those shapes.
- Weapon bevels use continuous geometry; imported meshes render both sides. Material, receiver and optic presentation were revised while preserving weapon stats, reload groups and muzzle markers.
- Loading is a static, opaque full-viewport layer. It waits for admission, character/world readiness and local floor support; it no longer sits over playable Preparing time or fades translucently over gameplay. An eight-second readiness fallback prevents an indefinite layer.
- Polygon-aware practical lighting, structural detail, materials, floor storytelling and location-specific exterior silhouettes form the first visual pass. Black Ops-level fidelity remains an unmet quality target.

Difficulty health, damage, speed, quotas and director scaling remain at v1.7.0 values while the effect of corrected pursuit is assessed. There is no new claim of solo or squad balance.

## Existing place destinations

Keep the existing creator/experience relationships when publishing these files yourself. Check the destination before replacing a place.

| Native file | Existing place ID |
|---|---:|
| DeadSignal-v1.8.0-Lobby.rbxl | 92751255902679 |
| DeadSignal-v1.8.0-Station.rbxl | 88865473543027 |
| DeadSignal-v1.8.0-Foundry.rbxl | 110963636700767 |
| DeadSignal-v1.8.0-Frost.rbxl | 109169216914914 |

The profile store remains `DeadSignal_Profile_v1`. Original art meshes, material maps, loading-image IDs, audio references and place configurations are preserved. Two anatomy materials are baked into each file using existing texture IDs; no additional asset upload is required for them.

Read `IMPLEMENTED-AND-REMAINING.md` for the roadmap and test results. `STUDIO-ACCEPTANCE.md` lists the outstanding engine checks. `Rollback/v1.7.0` and `Backup` retain previous deliverables.
