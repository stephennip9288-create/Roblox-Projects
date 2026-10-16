# Dead Signal — source-only cloud RBXL patching (offline-tested)

## Working build path

The original four **native v1.8.0 Work place binaries** have been imported and SHA-256 verified at `games/dead-signal/full-baselines/v1.8.0/` in PR #8. They are immutable **development candidates**, not the deployed staging binaries.

The older staging binaries do not contain five later v1.8 modules. A full-place rebuild with Lune altered/lost Terrain and asset property records. The **lossless workaround** implemented in PR #6 updates only the raw `ModuleScript.Source`, `Script.Source` and `LocalScript.Source` property chunks of the original complete Work files, preserving every other original binary chunk byte-for-byte.

The patcher requires exact known original hashes, validates script hierarchy through INST/PRNT referents, refuses missing/wrong script paths, and injects the per-place **staging-only PlaceConfig** generated from active manifests.

## Verified GitHub Actions run

[First four-place lossless integration run](https://github.com/stephennip9288-create/Roblox-Projects/actions/runs/38850094617), [post-merge main run](https://github.com/stephennip9288-create/Roblox-Projects/actions/runs/38850248320).

- **Dispatch:** 61 script targets, 1 changed staging PlaceConfig PROP, 1,513 unchanged chunks.
- **Blackwater:** 61 targets, 1 changed PROP, 1,496 unchanged chunks.
- **Cinderworks:** 61 targets, 1 changed PROP, 1,500 unchanged chunks.
- **Whiteout:** 61 targets, 1 changed PROP, 1,500 unchanged chunks.
- Independent raw class/PROP schema audit passed across all four places.
- Full imported Work offline Lune test suite passed and Python pipeline tests passed.
- Four candidate places were generated as a **GitHub Actions artifact**, not uploaded to Roblox.

A future Codex source change may edit additional Source PROP chunks. That is expected; all **unrelated chunks must still remain byte-identical**.

## How development now proceeds

1. Codex edits the source in `games/dead-signal/dev/Source/Runtime/`, and adds regression tests.
2. GitHub runs source CI and the non-publishing [Dead Signal Lossless Source Patch](https://github.com/stephennip9288-create/Roblox-Projects/actions/workflows/dead-signal-lossless-patch.yml).
3. Workflow archives four staging candidate .rbxl files plus `LOSSLESS-REPORT.json` and `BINARY-FIDELITY-REPORT.json`.
4. Review failures/diffs and repeat. The historical full-place Lune serializer is now **manual diagnostics only**, because it cannot preserve some raw data.
5. **Only after explicit user approval**, privately publish candidate places to staging with originals retained for rollback, test Lobby/teleports/all maps, 2+ player networking, gameplay, mobile controls and assets.
6. Production remains separate and requires a new explicit authorization. The existing working `games/dead-signal/places/` binaries and publish manifests remain unchanged.

## Important limits

- Byte-preservation is relative to original **v1.8 native Work places**, not parity against the *older* currently deployed staging maps.
- Script-only patching preserves original non-code data without proving the Work release itself is playable or visually correct.
- The v1.8 Work files originally embed **production Place IDs**; the generated staging PlaceConfig is required. Never publish an unpatched Work binary.
- Source tests and binary record audits are not Roblox Studio or actual published-client tests; they cannot certify NPC physics, navmesh, UI, teleport admission or mobile interactions.
- The one-time GitHub Actions ZIP importer (which needed `contents:write`) was retired after the upload. The standalone importer verification script and provenance manifest remain.
- No Roblox API keys or publishing functionality are present in the source-patch workflow.

Issue [#5](https://github.com/stephennip9288-create/Roblox-Projects/issues/5) tracks remaining **private engine staging acceptance** and production safeguards.
