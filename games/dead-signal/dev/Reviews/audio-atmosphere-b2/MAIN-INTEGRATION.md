# MAIN DEV integration handoff

Issue #62 approved AUDIO B2-02/05/07. Branch `feature/dead-signal-b2-audio-atmosphere`, OPEN DRAFT [PR #70](https://github.com/stephennip9288-create/Roblox-Projects/pull/70), target `integration/dead-signal-batch2`, starting main `7aaf323de6153134df2154c7ae3b1613a596495b`. Final exact source hashes and test/build evidence are in `PROPOSED-RUNTIME-DELTA.json` and `VERIFICATION.json`; the PR head is the canonical commit reference. Source is ready for review/intake; assets and native acceptance remain dependencies. AUDIO does not merge or deploy.

## Shared hunks to preserve

| File | AUDIO-owned boundary | Integration requirement |
| --- | --- | --- |
| `client/Effects.lua` | Existing audio marker through immediately before `function FX:part(`. | Preserve original preamble and VFX suffix; no additional ModuleScript or server authority. The historical review mirror contains only this audio segment. |
| `client/Controller.lua` | `Controller.audioBindings` and replacement of the one existing Results audio call with `audioBindings:results(s.state)`. | COMBAT #72 owns movement/input/render code. Its specialist explicitly preserves the accepted audio sections; merge both lane hunks without copying an entire competing Controller. |
| `shared/Config.lua` | Additive seven-line `BATCH 2 AUDIO POLICY` block, initially empty new assets. | Original accepted sound banks and staging/production permission ledgers remain exact. Real asset intake is a later reviewed Config delta. |
| `Tests/run.py` / provenance helpers | Two new suite registrations and narrowly scoped audio normalization. | Combine MAP/ENEMY/COMBAT registrations additively and establish a reviewed combined B2 delta. Never regenerate historical B1 ledgers from current files. |

The audio scope adapter validates main7aaf snapshots, exact policy bytes, non-audio Effects and Controller boundaries, and all other original runtime blobs through the existing guards. It allows the owner-approved audio implementation within those boundaries; it does not represent integrator approval and does not approve Architecture, Graph, Game, Movement, Navigation or other lane changes. Review the actual diff and proposed 61-record manifest. Other specialists' documented frozen-B1 guard failures require MAIN's explicit combined intake, not loosening this adapter.

`batch1-integration.luau` now moves both infected fixtures 2.5 studs rather than one: the new two-stud grounded-stride requirement intentionally suppresses jitter. All old assertions remain.

## ENEMY awareness dependency — agreed contract

Consume [ENEMY #71](https://github.com/stephennip9288-create/Roblox-Projects/pull/71), final handoff head `f8b2c49f88046af43a8133f7bfeec5e4437c34a9`, tested implementation `836734bf5ea19c45786c3f89aefa935104648355` (recheck head before integration). Producer writes `AwarenessTargetUserId` and `AwarenessRunId` first, then `AwarenessAt` **last**, using workspace server time. Producer validates a genuine LOS acquisition, life/access/participation, distance ≤65, no entry/attack/stun, ≥12 seconds per actor and a global 2/s burst-two budget.

The existing attribute observer is the sole audio delivery path. It requires matching run and local target, age within 1.5 seconds and distance <65; it consumes timestamps even when stale or budgeted, with client per-actor eight-second/global 2.5-second throttles. Hounds select `Hound.Snarl`, humans `Enemy.Awareness`. **Do not add another Feed handler for EnemyAwareness.** Without the producer, routine/movement audio still functions and no fake detection is generated.

MAP #69 retains the authored zone/landmark schema used by audio; no geometry edit is required by this lane. Its final head is `7b8c2442530c11afc47cd40f50c03a03349f6c39`. COMBAT #72 final handoff is `26bcbfe5558f6fc0ff6e067c200649578a5502be`. These are coordination references, not patches included or approved by this specialist.

## Asset intake and verification

The owner package includes ten original synthesized music candidates, not accepted physical recordings. Creator/rights/listening review, Roblox moderation and grants are pending. Six additional physical recording categories are requested. No IDs are invented and no new assets are activated. Suitable existing beds/groans/radio/machinery/relay/creaks and all approved Batch 1 recordings continue.

After reviewed assets and merged lane source are concrete, MAIN applies new banks under `C.AudioAtmosphere.assets` with all required flags and exact-universe permissions, establishes reviewed provenance, reruns all combined tests and local lossless builds, then runs the native/mobile checklist on an explicitly authorized candidate. Preserve the eleven known Batch 1 specialized reload-stage limitations; no Batch 3 work is included.

Offline build outputs here are disposable artifacts, not changes to committed native places or releases. Binary chunk and property-signature preservation does not prove rendering, physics, asset loading or audible quality. No Studio/native gameplay or phone acceptance is claimed. Keep the PR/acceptance gates open until MAIN finishes review and owner listening passes; only the owner can authorize publication.
