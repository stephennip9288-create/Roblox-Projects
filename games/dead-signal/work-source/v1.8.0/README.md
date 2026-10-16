# Dead Signal v1.8.0 — editable Work-thread source import

This folder is an untouched source snapshot (except directory packaging) from the v1.8.0 Pursuit Overhaul Work release. The full binary place files are intentionally excluded; the existing GitHub `games/dead-signal/places/...` .rbxl files remain the validated staging deployment baseline.

## What is here

- `Source/Runtime/client`, `server`, `shared` (editable Lua/Luau modules)
- `Source/Places` (place-specific configs; **contain production IDs and must NOT be used in staging as-is**)
- `Tests/` and `Tools/` from Work
- Release and acceptance notes
- `IMPORT-MANIFEST.json` with original ZIP SHA-256 and per-file hashes

## Critical limitation

This is **not** a full drop-in Rojo project or a build that can replace the existing .rbxl places. We need to build complete per-place projects that retain terrain/maps, art, assets, and place-specific configs, and verify them in private staging. v1.8.0 was offline tested in Work but not engine-playtested or published. The previously successful staging uploads should not be overwritten merely because source was imported.

## Next development steps

1. Commit this entire folder as a source snapshot, separately from deployment files.
2. Add a separate source-build project for staging using the existing complete place as preservation baseline; ensure **all** required instances are incorporated.
3. Compare built .rbxl files to originals; test in Studio/client and publish to staging only with explicit approval.
4. After staging parity, use Codex to edit Lua modules with PRs; maintain staged deploy and production approval.
