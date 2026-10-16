> v1.9 development: [integrated roadmap](../V1.9-ROADMAP.md) and [private staging acceptance plan](../V1.9-STAGING-PLAYTEST.md). Continue from verified v1.8; existing workflows and native baselines remain authoritative.

# Dead Signal — editable development workspace

This is the **active editable working tree** for Codex. Its initial 82 files were copied byte-for-byte from the reviewed Work v1.8.0 release. The archival import remains intact at `../work-source/v1.8.0/`.

## What Codex may edit

- `Source/Runtime/server/`: zombie pursuit/navigation, combat, waves, maps, models, hounds, extraction, lobby/travel
- `Source/Runtime/client/`: mobile firing, HUD, animation and loading
- `Source/Runtime/shared/`: gameplay rules, weapons, config, effects, movement
- `Tests/`: offline Lune regression suites and authoring test helpers
- `Tools/`: prototype offline authoring code (see warning below)

## Testing changes

GitHub's **Dead Signal Work Source CI (No Publish)** workflow automatically runs on changes here. It installs pinned Lune, runs 15 Python validation/config tests, generates separate staging/production PlaceConfig modules, and runs all 8 existing Work regression suites (8,444 assertions at initial import). The test suite uses temporary copies of the four previously validated **staging .rbxl** files as data-model fixtures, then installs source modules under test. The fixtures are NOT the Work v1.8.0 candidate places; passing does not prove a new source-built game is playable. Actual studio/mobile/teleport tests remain necessary.

Run locally after installing Lune 0.11.0 (see `rokit.toml`):
```text
python Tests/run.py --lune lune
```
Most suites require `Places/DeadSignal-v1.8.0-*.rbxl` test fixtures. The GitHub workflow prepares these from existing staging files automatically. Do not commit these temporary files back into `dev/`.

## HARD SAFETY RULES

1. **DO NOT publish any generated file, touch live Roblox credentials, or switch active publish manifests from binary to Rojo in a source-change PR.**
2. The unchanged source files under `Source/Places/*-PlaceConfig.lua` and `Source/Runtime/shared/PlaceConfig.lua` contain **production Place IDs** from the upstream Work kit. Treat these as hazardous legacy examples, **not as staging-ready configs**.
3. Run `python scripts/generate_dead_signal_place_configs.py` from repository root to create safe, environment-specific modules in `build/dead-signal-place-configs/{staging,production}/`. These files are **not yet connected to an approved complete-place builder**.
4. `Tools/build-places.luau` is **not ready for this repo**: it expects rollback v1.7.0 place binaries excluded from the source import. Do not attempt to use it for deployment. A separate complete-place preservation and safe build process must replace it.
5. Maintain the four known-working `games/dead-signal/places/<place>/staging.rbxl` and `production.rbxl` files as the rollback baseline until a new artifact passes source/asset parity and real Roblox client tests.
6. Source tests can prove specific offline logic and basic compatibility, **not** engine physics, navmesh, animation, network travel, performance, art quality, nor phone-control usability.

## Future build integration

Proposed follow-up: create a staged, non-publishing overlay builder using complete baseline `.rbxl` files, apply only validated updated sources to matching Roblox instances, inject generated staging PlaceConfig, serialize/reopen candidate .rbxl, audit preserved instances/models/art/IDs, publish candidate to **staging only** after explicit user authorization, and playtest every map. Production promotion remains a separate, explicit approval.

For a future Codex PR, modify **this `dev/` tree**, add regression tests, and wait for CI. The archival v1.8.0 import should not be modified.
