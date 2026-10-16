# Dead Signal v1.8.0 — implementation, evidence and remaining work

Status: development candidate, validated offline. Roblox Studio engine play was unavailable in this environment. The files have not been published. Performance, actual physics/pathfinding, live asset loading and the requested graphics quality bar have not been certified.

The October 15 revision 2 handoff remains approved and is preserved in `Approved-Handoff-2026-10-15.txt`. The latest feedback changes immediate priorities: NPC pursuit/collision/models/ragdolls, weapon gaps, loading transition and substantial map/visual work come before mobile usability testing. The previous v1.7.0 native files and release notes are included under `Rollback/v1.7.0`.

## Delivered changes

| Area | Implemented | Evidence and limits |
|---|---|---|
| Pursuit | Live-player native path destinations; no mandatory source-room center; floor/root normalization; waypoint plane crossing; path retention during refresh; forward blockage recovery; bounded/fair scheduling; spatial crowd steering. | Deterministic regressions cover height mismatches, gallery separation, moving targets, failed refreshes, path tokens, budget fairness and unique route connectivity. Native navmesh and crowd movement need Studio. |
| Targeting and combat | Existing multiplayer-aware selection, invalid-target rejection, no activation radius, attack windups, range/line-of-sight and Warden damage caps retained. | Existing server integration tests pass. Real raycasts, wall attacks and latency need play. |
| Collision | Explicit living NPC↔NPC and NPC↔player collision; one floor-reaching body shell per live rig; limb hit zones; world-colliding corpses that do not pin living players. | Policy registration and native rig properties tested. No real contact solver or doorway crowd test performed. |
| Models and motion | Shared articulated anatomy for all five enemy types, consistent forward axis, corrected reaching/swing direction, new elbow/knee/wrist/ankle joints, forward-looking crawler head, hound anatomy rebuilt from closed textured body pieces with the retained detailed head, and textured joint coverage. | Exact runtime geometry reviewed offline; joint frames and native model round-trips tested. Existing source mesh art is reused. Character sculpting, deformation and production animation quality remain incomplete. |
| Ragdolls | All enemy eliminations capture a shared pose, disable limb motors and create constrained joints; delayed settling requires low velocity; 30-second cleanup and 50-body cap. | Every type tested for attachment coincidence, disabled motors, cleanup and duplicate-death guards using controlled services. Engine falls, stairs, impulses and settling remain untested. |
| Maps | Reauthored polygon floors/walls, mitered bent corridors, nine distinct sector links including 1↔5 and 3↔5, galleries and inset objectives/furniture. | 48 authored graph nodes per place are connected with gates open. Projected ground audit reaches all 29 objective/spawn approaches and all 36 portal points per map, plus full corridor centerline samples with conservative largest-agent clearance. Vertical navmesh, closed-door progression and safe spots remain engine acceptance work. |
| Guns | Continuous rounded receiver/stock/slide construction replaces open bevel pieces; retained imported meshes use double-sided rendering; material/optic presentation revised. | 4,986 interior receiver samples across six representative weapon types; all twenty weapon models build and serialize with muzzle markers and nonblocking presentation parts. First/third-person engine viewing and reload appearance still need inspection. |
| Loading | Separate high-order opaque full-viewport GUI; still artwork; no diorama camera; readiness-based one-frame removal; input blocked while covered; stale readiness tasks cancelled. | Arrival policy tested for Preparing/Wave/Intermission/Exfil, missing character/world/floor, travel and rejection. ScreenInsets/property usage reviewed. Actual teleport transitions and slow asset delivery need live checks. |
| Graphics | Polygon-aware architectural detail, practical lighting, revised grade, location silhouettes, reused PBR maps plus baked skin/fur material variants. | Offline art review only. The requested complete Black Ops-level graphics pass is **not achieved**. Further custom meshes, animation polish, scene dressing and in-engine lighting/performance work remain. |
| Difficulty | Existing v1.7.0 curves/director retained while removing AI defects. | Policy/accounting tests pass; no measured change in survival, damage taken or round-clear times. Further stat tuning waits for corrected-AI playtesting. |
| Mobile | Existing candidates, alternatives, settings, save migration and customization preserved. | Usability testing and selection of a strongest two-thumb layout are **deferred by owner request**. The mobile suite remains available but is excluded from this delivery's default test run. |

## Checks actually run

| Check | Result |
|---|---|
| Runtime Luau compilation | 61 scripts, zero compiler failures |
| Director policy | 431 offline assertions |
| Server integration | 35 offline assertions |
| Navigation scheduling/fairness | 13 offline assertions |
| Pursuit regressions and sector routes | 90 offline assertions |
| Rigs, collision policy and ragdoll construction | 309 offline assertions |
| Weapon geometry/model checks | 7,518 offline assertions, including 4,986 receiver samples |
| Arrival readiness policy | 28 offline assertions |
| Extraction regressions | 20 offline assertions |
| Total | 8,444 offline assertions |
| Native place serialization/reopening | Four files reopen; 614 original art meshes and 549 original SurfaceAppearances retained in each |
| Material preservation | Original 11 environment variants retained; 2 new anatomy variants authored from existing map references |
| Source/configuration preservation | Embedded sources match delivery; place IDs/configs, profile store, artwork and sound references match v1.7.0 |
| Ground geometry | All 29 objective/spawn approaches and 36 portal points reachable; 876 corridor centerline samples pass across the three maps (plus 256 for the Lobby preview) with 1.70 × map-scale collider inflation |
| Roblox Studio play / actual pathfinding / physics | Not run |
| Physical phone / two-thumb comparison | Deferred; not run |
| Published multiplayer / teleports / asset permissions | Not run |

Counts describe deterministic checks, not minutes of gameplay or proof of production readiness. The geometry audit projects colliders onto ground space; it cannot certify stairs, ceilings, jumping/climbing exploits or the engine's voxel navmesh. Offline previews show shipped geometry under a separate renderer and are clearly labeled; they are not Studio screenshots.

## Roadmap integrated with the approved handoff

| Priority | Next acceptance milestone | Preserved scope |
|---|---|---|
| P0 | In-engine pursuit across every sector and gallery, each enemy type, open/closed gates and moving targets. Resolve any stalls before balance tuning. | Continuous hunting, fair scheduling, multiplayer target changes, no-jump routes and bounded recovery. |
| P0 | Physical crowd/collision and ragdoll trials on floors, doors, ramps and galleries. | No live body overlap; no permanent corpse obstruction; all enemy deaths ragdoll. |
| P0 | Complete custom enemy art/animation and weapon view inspection, then finish the graphics pass in-engine. | Corrupted-radio identity, Black Ops-inspired readability, map landmarks and stable performance. |
| P1 | Solo and 2/3/4-active-player balance trials with corrected pursuit; measure clear time, damage and recoveries. | Configurable adaptive director, safe distributed spawns, Warden and round-15 finale. |
| P1 | Full route progression, objective spacing and safe-spot audit, including upstairs/downstairs. | Power, barricades, traps, fuses/frequencies, perks, upgrades, rescue and return-to-Dispatch. |
| P1 | Loading and published reserved-server travel regression with slow connections and rejection/retry paths. | Existing place relationships, crew continuity, profile locking and save safety. |
| Deferred | Resume Tap versus Left two-thumb trials only when requested. Retain Classic and customization. | No final winner claimed; assistance and optional auto-fire remain separate settings. |
| Later approved scope | Continue the original handoff's polish, replayability, progression, audio, performance and release requirements after the P0 gates. | All original requirements remain approved; this milestone does not delete or silently mark them complete. |

Implementation references: `Source/Runtime/server/Navigation.lua`, `RigAnatomy.lua`, `EnemyRigs.lua`, `Architecture.lua`, `VisualPass.lua`; `Source/Runtime/shared/NPCPose.lua`, `NavigationGraph.lua`, `LoadingScreen.lua`, `ArrivalRules.lua`, `WeaponModels.lua`. Material map authoring is confined to `Tools/AnatomyMaterials.luau`, because those writes require authoring privileges.
