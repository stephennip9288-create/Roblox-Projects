# Dead Signal — Work Thread: Enemies, Hounds & Special Waves

You own `feature/dead-signal-enemy-systems` in `stephennip9288-create/Roblox-Projects`. Read `games/dead-signal/PARALLEL-DEVELOPMENT.md`, `V1.9-ROADMAP.md` and `V1.9-STAGING-PLAYTEST.md` before editing. Do not publish, change saved-data schema or merge directly to `main`.

**Start with a gap audit, not a reimplementation.** Current `main` contains `C.Version = "1.9.0"` and developed candidate systems for the Hunt/Redline/Iron March/Containment Breach/Critical Mass, elite modifiers, breakable armor, pack hounds, Stalkers, hazards and counters, rewards and evolution. These are **source candidates**, not proof of successful studio/native/live validation. Check implementation and test gaps, then improve precisely what is missing or flawed.

**Goals:** Robust, aggressive but fair hound charger/flanker/Alpha coordinated tactics; zombie navigation that avoids obstacle pinning and exploits; distinct accessible elite silhouettes/status (color alone insufficient), glowing eyes/markings/telegraphs/sound, breakable weakpoints and recovery logic; clear event announcements and pacing; fair rare combined modifiers and Stalker counterplay; high-round behavior evolution; optimized mobile effects and bounded hazards; Warden/extraction priority.

**Likely lane files:** `server/Enemies.lua`, `EnemyRigs.lua`, `HoundRig.lua`, `InfectedWardrobe.lua`, `Navigation.lua`, `WaveDirector.lua`; `shared/DirectorRules.lua`, `NPCPose.lua` and new tests in `dev/Tests/`. Changes to `server/Game.lua`, `Combat.lua`, `Interactions.lua`, `shared/Config.lua`, `NavigationGraph.lua`, `client/Effects.lua` need integrator contract approval. Do not modify map geometry owned by Maps or HUD owned by Combat/UI; record requirements as interfaces.

**Essential tests:** special wave cadence and no Warden/exfil conflicts, random caps, spawn quotas after crew changes, hound flanks and charge windup escape, target death/disconnect, Stalker warning and cover behavior, armor break persistence, explosions with LOS and chain delays, counter/hazard cleanup, collision and ragdoll path, pathfinding in remastered maps, large swarms and low-effects performance. Keep CPU/network budgets and mobile readability. Distinguish offline tests from Studio and real-client evidence.

**Deliver:** scoped branch PR to integration, reproducible regression tests, documented config/interface changes and migration risks (prefer none), setup for map-nav integration and a list of remaining physical gameplay validations. Do not mark features implemented based solely on an older chat's approval.

---

## Newly approved development handoff — Batch 1: Infected visual/animation overhaul (2026-10-16)

**Read the full traceability matrix:** [BATCH-1-APPROVED.md](BATCH-1-APPROVED.md), IDs **EN-01 through EN-09**. Owner has approved all military zombie/K9 archetypes, traversal and damage-reaction recommendations. This is a **new follow-up batch**, not permission to rewrite or overwrite open **PR #19** or redevelop v1.9's already-authored elite/wave features. Use a fresh follow-up branch coordinated by MAIN DEV, stacking or rebasing when #19 is integrated.

**Concrete work plan:**
1. Audit native and generated infected models, realistic skin/uniform material options, imported mesh rig attachment and current NPC visual hitbox/animation limitations. Record **existing, gaps, evidence**. Preserve gameplay-critical tagged hit zones and server authoritative damage. Do not claim realistic assets from basic geometric placeholders alone.
2. Build **military infected families**: varying infantry, tactical/security, operations, officer, heavy armor and hazmat gear, damaged uniform silhouettes, textures and stages of mutation. Theme them by outbreak location: Blackwater soldiers and comms staff; Cinderworks industrial/military containment responders; Whiteout cold-weather military/science personnel. Keep all recognizable as the same infection canon.
3. Rework **K9 hound** anatomy, four-legged gait, pack movement, attacks and distinct Alpha/elite mutations. Preserve strong tell differences with silhouette, animation and sound, not just glowing eyes.
4. Implement **actual window traversal**: select eligible exterior approach, align with a mount/breach point, scripted/animated contact & vault/crawl and landing, collision/safeguards and post-entry pathing. A player must visibly see/hear the entry and have fair reaction time; never spawn directly into the room. Backed-up paths cancel cleanly and failure/retry remains bounded.
5. Add contextual traversal variants (low obstacles, doors, ledges) and directional hit/flinch/death/armor reactions where appropriate; guard against perpetual recovery loops, desync, exploit collision, unbeatable stagger and ragdoll/corpse obstruction.
6. Make origin plausible through distant spawn zones, damaged doorways, vents and tunnels. Map anchors and approach/egress constraints are supplied by MAP DEV; timing/impact/howl/gear cues by AUDIO DEV; hit-reaction combat events coordinated through COMBAT-UI/MAIN DEV.

**Validation and performance:** Tests for correct state transitions (including target disconnect/downed, blocked window, abandoned route, exploding entity, destruction during animation, reentry/corpse cleanup), no teleporting, reliable sound timing, no Warden/extraction sequence break; no spawning on top of players; preserve round quotas, path fairness, low-end animation budgets and hit zones. Test navigation on ALL finalized maps at elevation; distinguish offline rig tests from Roblox physical animation and multiplayer observations.

**Do not add new runtime script records or make promises of working creator-owned mesh/audio assets without an approved patch/asset path.** Report blocked art authoring separately and keep testable code ready for later Studio acceptance.
