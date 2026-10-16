# Dead Signal — lossless source-only RBXL patching (developer preview)

## Workaround for the Lune full-place serialization problem

**The current successful staging binaries are older than the v1.8 Work code.** They are missing five modules (ArrivalRules, NPCPose, CollisionPolicy, RigAnatomy, VisualPass). Editing only existing script records would leave the resulting game incomplete. Rebuilding the entire place with Lune instead drops/retypes some raw Terrain/asset properties.

**Solution:** Take the _complete native four-place binaries_ that came in the original Dead Signal **v1.8.0 Pursuit Overhaul Work Kit**, verified offline to contain all **61 expected scripts in every place**, and patch **only `Script.Source`, `LocalScript.Source` and `ModuleScript.Source` property chunks** directly in the binary file. Every other original binary chunk (including unknown Terrain data and material/mesh references) remains byte-for-byte unchanged. Generate staging PlaceConfig from the active `deploy.json` files and replace that module's Source while retaining all other script/module metadata.

The importer must put the original Work binary files at:

```text
games/dead-signal/full-baselines/v1.8.0/dispatch.rbxl
games/dead-signal/full-baselines/v1.8.0/blackwater.rbxl
games/dead-signal/full-baselines/v1.8.0/cinderworks.rbxl
games/dead-signal/full-baselines/v1.8.0/whiteout.rbxl
games/dead-signal/full-baselines/v1.8.0/IMPORT-MANIFEST.json
games/dead-signal/full-baselines/v1.8.0/README.md
```

The one-time zip **DeadSignal-v1.8.0-Full-Baselines-Import.zip** is prepared from the owner's original Work package in ChatGPT. Extract the exact paths in a PR; validate SHA-256 from the embedded manifest; do not touch the existing `games/dead-signal/places/` binaries or active publish configurations. The full Work baseline has **production teleport IDs embedded** and is NOT staging-ready as-is.

## Current branch and CI

`scripts/patch_dead_signal_rbxl.py` operates on the above input files, verifies all four original hashes from the manifest, maps scripts by actual `INST` referents and `PRNT` hierarchy, requires all source module targets to exist, injects generated **staging-only** PlaceConfig, recompresses only the affected `PROP Source` records, and checks every unmodified chunk is byte-identical.

`.github/workflows/dead-signal-lossless-patch.yml` runs 27+ Python unit/integrity checks and will automatically run the four-place integration after the baseline files are imported. It compares against the **same original v1.8 native files**, not the older staging deployment files, and then archives four offline candidate files as GitHub Artifacts.

Until original native files are imported, this workflow explicitly skips the integration portion while still running Python checks, and reports a warning that full binaries are not yet validated.

## Acceptance and safety

- Four native original input files must match the exact manifest hashes.
- All 61 runtime source script paths must be accounted for, with no additions or deletions to the original DataModel; missing paths cause fail-closed.
- The raw RBXL auditor must pass, with exact unchanged raw chunks aside from Source PROP. This directly addresses `Terrain.VoxelGridAssetContentMap` and similar opaque properties.
- All source tests, Python tests and staging configuration isolation must pass.
- Candidate `.rbxl` files are **artifacts only**, not approved for upload or Roblox publication.
- Native v1.8 Work places themselves **have not been engine-playtested**; world behavior, engine/API compatibility, public assets and touch controls remain unproven.
- **First deployment must be an explicitly authorized private staging playtest, with rollback.** Never automatically publish to staging or production.
- Production remains unchanged until separate explicit authorization.

Reference: [Issue #5](https://github.com/stephennip9288-create/Roblox-Projects/issues/5).
