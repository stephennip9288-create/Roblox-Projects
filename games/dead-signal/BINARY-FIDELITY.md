# Dead Signal binary fidelity — independent guard

## Why this audit exists

The original cloud candidate build passed a non-script *instance/selected-property* check using Lune's Roblox deserializer. That did **not** prove complete binary preservation. A historical Dead Signal uploaded place file contains `Terrain.VoxelGridAssetContentMap` (RBXL property type `0x23`), which Rojo had warned it did not understand.

The independent `scripts/audit_dead_signal_binary.py` reads the **raw Roblox place format**, parsing compressed Zstd/LZ4 `INST` and `PROP` records through standard Linux codecs, **without relying on Lune or Rojo's parsed model**. It compares every baseline class and property signature/type with the regenerated candidate file.

The audit is conservative: missing or retyped original properties are treated as blockers until investigated. The report's `passed` refers only to class/property signature coverage. It is not a Roblox runtime, binary-value or rendering test.

## Findings in the current staging baselines

On the first comparative GitHub run, each of the four rebuilt candidates had **104 or 105 raw property signatures missing or retyped**. Notable differences:

- `Tags` records originally encoded as type `0x1c` now appear as string (`0x01`). This could be a serialization encoding change, **not necessarily loss of tags**, but equivalence has not been established.
- `MeshPart.MeshId`, `MeshPart.TextureID`, `SurfaceAppearance.*Map`, `SpecialMesh.*Id`, and `MaterialVariant.*Map` are no longer present as original string properties; newer `*Content` properties appear instead. **Value-preservation must be tested separately** before assuming compatibility.
- `Terrain.VoxelGridAssetContentMap` (type `0x23`) appears in **all four original staging baselines** and is **absent in all four regenerated candidates**. The source record is small; that is not proof of a visible terrain voxel loss, but the missing data is a hard safety blocker until its meaning/preservation is verified.

These differences prove the older selected-property inventory was insufficient to declare complete fidelity. This guard prevents accidental promotion of the candidates on the basis of that old success.

## Workflow behavior

The [Audit Dead Signal Candidates (No Publish)](https://github.com/stephennip9288-create/Roblox-Projects/actions/workflows/dead-signal-candidates.yml) GitHub workflow now:

1. Validates manifests, tests and environment-specific configs, overlays editable dev sources on the four complete baseline staging files, and performs the existing selected-property inventory test.
2. Runs the **independent raw binary property audit** on each place.
3. Always publishes a diagnostic artifact containing `BINARY-FIDELITY-REPORT.json` and `CANDIDATE-REPORT.json`.
4. **Quarantines candidate `.rbxl` downloads** whenever any property/class record is missing or changed in the raw binary: the candidate artifact upload is conditioned on `steps.fidelity.outputs.eligible == 'true'`. The workflow records a warning while completing successfully as a diagnostic job. **A green workflow does NOT mean candidate binaries are deployable.**
5. Never accesses Roblox API keys, never runs `scripts/publish.py`, and never modifies any staged/live place.

The audit script itself **exits with nonzero status** on any mismatch. Any future publish pipeline must explicitly require a successful strict audit, strong property/asset/value preservation, engine playtests and user authorization.

## What to do before staging a source-built candidate

- Determine whether a Roblox Studio-authored export or a truly lossless binary-preserving script patch can retain unknown Terrain properties, tags and asset contents without reserialization losses. **Do not blindly paste raw chunk bytes or transfer string-pool indices:** binary referent/string encoding can change.
- Verify full property values, Terrain voxel cells/material maps and all asset IDs using an independent parser and Roblox Studio inspection.
- Compare candidate behavior in an isolated Studio/playtest session, then an explicitly approved private staging test with rollback.
- Keep `games/dead-signal/places/\*/staging.rbxl` and `production.rbxl` unchanged as rollback baselines.
- Continue Code/Codex development and Lune regression tests in `games/dead-signal/dev/`; those do not require risky place overwrites.

## Scope and limits

The audit confirms presence/type/instance-count relationships of serialized records; it does **not** check each property value or the full native Terrain/SharedString material content. It deliberately reports unsupported formats as blockers rather than silently skipping them. A future lossless builder should be tested against **all four** places before source-derived place files can be used for publication.
