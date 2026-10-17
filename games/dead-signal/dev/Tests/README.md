# Offline checks

Use Lune and optionally the Luau compiler. From the extracted kit:

```text
python Tests/run.py --lune /absolute/path/to/lune --luau-compile /absolute/path/to/luau-compile
```

The default run covers director policy, server combat/accounting, navigation scheduling, pursuit regressions, rig/collision/ragdoll construction, weapon geometry, arrival readiness and extraction. These execute delivered methods with Roblox datatypes and controlled services.

Physical mobile testing is deferred. The deterministic `touch.luau` suite is included again to guard the existing gestures while Combat/UI input and HUD changes are tested. This does not resume physical two-thumb comparisons or claim actual phone usability.

`Support/RuntimeLoader.luau` provides offline authoring transforms and service doubles. Lune does not run Roblox physics, a native navmesh, real raycasts, teleports, animation replication or touch input. Tests of ragdoll construction are not tests of falling bodies.

`Validation/Build-Report.json` records file reopening and graph counts. `Preservation-Report.json` compares original art/material data and configuration with v1.7.0. `Geometry-Report.json` is a projected ground-space audit, not an engine test. Follow `STUDIO-ACCEPTANCE.md` for the remaining engine work.

## v1.9 coverage

`evolution.luau` exercises scheduling/rarity, armor/reactor damage, telegraphed chain hazards, pack/ambush behavior, variant collision/ragdolls and safe counters on all maps. `events.luau` runs actual Game scheduling/spawn/reward/exfil methods. `presentation.luau` constructs and cleans client warning/smoke/fire effects at both quality levels. These are included in the existing runner and cloud workflows. Engine navigation/physics/rendering/audio and physical phone playtests remain separate acceptance checks.

## Combat/UI lane coverage

`combat-ui.luau` builds all 20 weapon types at tiers 0–3, checks conservative geometry against the aimed ray at nine viewport sizes/five FOVs, restores hip/optic visibility, exercises mechanical poses, and checks 270 HUD/control/notice combinations. It also executes the scope masks, reticle/hit feedback, compact inventory/status text, and prompt/control blocking methods. `combat-input.luau` starts the actual Controller with controlled services and a deterministic clock to exercise focus/menu cancellation, revive holds, reload/swap acknowledgments, missing slots, ADS and down/revive transitions.

The large geometric assertion count comes from sampling each visible part; it is not a count of engine playtests. See [Combat/UI integration and acceptance](../Reviews/COMBAT-UI.md) for contracts, limitations and the native review checklist.

## Batch 1 weapons

The additive `weapons-batch1.luau` suite builds 160 gun/tier/finish combinations, verifies retained native mesh content and fitted upgrade hardware, stages magazine/shell/action animations, and stresses bounded flash/ejection, multiple simultaneous sources, cancellation and cleanup at both quality settings. `combat-input.luau` also checks phase-change reload reconciliation, guarded canonical Audio stages and token invalidation. `integration-contracts.luau` checks the new weapon revision on actual remastered wall displays. All 20 earlier integrated suite registrations remain; the runner now has 21 suites.

See [Batch 1 weapon evidence](../Reviews/weapons-batch1/README.md) for measured Maps envelopes, reproducible before/after projections, exact-source verification and outstanding Studio/audio/mobile acceptance. Those projections do not render native mesh triangles or prove art realism.


Batch 1 integration adds `infected-batch1`, `infected-entrances`, `infected-geometry`, `audio` and `batch1-integration` to the shared runner; `weapons-batch1` remains registered. The map-remaster suite invokes map_batch1 once. Integration tests exercise the actual Controller adapters against replicated map/NPC facts, stale-run/sequence rejection, metadata from all three generated maps, master mute including default character sounds and teardown. Geometry checks exercise all 210 window/profile combinations plus 63 contextual-link plans and their complete sweeps. None is a Roblox engine/device playtest.

Also run `python -m unittest discover -s Tests -p 'test_*.py' -v` for the six audio patch guards, `python Tests/check_map_remaster.py` and `python Tests/check_map_batch1.py` after Lune produces map reports. The spatial Python audits use NumPy/SciPy locally; they do not simulate native navmesh/physics.
