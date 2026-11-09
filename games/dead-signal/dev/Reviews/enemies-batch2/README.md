# Dead Signal ENEMY — Batch 2 review handoff

**OPEN DRAFT PR [#71](https://github.com/stephennip9288-create/Roblox-Projects/pull/71)** targets `integration/dead-signal-batch2`. Branch: `feature/dead-signal-b2-enemies`. Starting and still-current main: `7aaf323de6153134df2154c7ae3b1613a596495b`. Tested source checkpoint: `836734bf5ea19c45786c3f89aefa935104648355`; the final handoff commit adds evidence and the Studio overlay request-frequency display; runtime bytes are unchanged. Scope: Issue [#62](https://github.com/stephennip9288-create/Roblox-Projects/issues/62), B2-03/B2-04/B2-08. No specialist merge or publish.

Implementation is ready for MAIN source review. Integration requires MAP #69, AUDIO #70 for audible awareness, deliberate combined Batch 2 provenance intake, shared test registration reconciliation and native acceptance. The source-only branch intentionally does not include another lane's producer patch. It is **not merge-ready under the current frozen provenance gate**. No item is marked Verified by offline testing.

## Behavior and changed files

| Runtime file | Result |
| --- | --- |
| `server/Navigation.lua` | Normal pursuit follows successive real room/portal/stair legs, checks physical support/clearance and logical access before movement, rejects stale/invalid native results, preserves usable paths during failed refresh and applies bounded failure backoff. Progress-aware recovery replans/avoids failed nodes/reacquires eligible targets without relocating or retiring an entered enemy. Doorway FIFO leases expire if their holder stops progressing. |
| `shared/NavigationGraph.lua` | Backwards-compatible `route`, with additive `plan`, `reachable`, `stateKey` metadata and deterministic weighted routes. Uses existing producer node/edge IDs, corridor waypoints, locked rooms and door states; no schema/geometry change. |
| `server/Enemies.lua` | Accessible-target filtering, real detection facts for R6 presentation, rotating global route budgets, intentional pause bookkeeping, and removal of generic entered-stuck exterior relocation. Existing combat, wave quotas, root-loss and exterior entry recovery remain. |
| `shared/NPCPose.lua` | Subtle clamped 0.85s neck/upper-body look, three variants, smooth easing. Traversal, attacks, hits and stun retain priority. No hitbox/rig/death/model change. |
| `server/Diagnostics.lua` | `navigation(true/nil/false)` enables/snapshots/releases a Studio-only capped trace. No remote, production loop or automatic allocation. |

New tests: `enemy-b2-navigation`, `enemy-b2-awareness`, `enemy-b2-budget`, `enemy-b2-maps`, with distinct `Support/EnemyB2World.luau`. `Tests/run.py` adds those four registrations. `pursuit` and `enemy-path-recovery` fixtures now distinguish blocked long direct lines from clear short native legs; their behavioral assertions remain. A new regression separately rejects blocked native legs. `Tools/diagnose-navigation-b2-studio.lua` is an opt-in server Command Bar overlay.

Stable navigation depth comes from the retained root-bound BodyCollider and canonical radius; lateral silhouette and head height remain conservative. Noncolliding longitudinal hands/muzzles/tails no longer act as invisible walls against a slope. Actual support beneath the collider ends is checked within the existing 1.2-stud step allowance. Walls, unrelated overhead floors and unsupported gaps remain blockers. Full-rig window animation sweeps and the accepted entry state machine are retained.

## Shared contracts and dependencies

1. **MAP [#69](https://github.com/stephennip9288-create/Roblox-Projects/pull/69): required.** Final map branch head `7b8c2442530c11afc47cd40f50c03a03349f6c39`; implementation `82aa087f41683e3d96511da75192fc5433f5851a`. Tested exact Architecture blob `7ad97ec938268a0dffa4f9cb8d81da491e44ab03`. Whiteout door 7 (rooms 3↔6) waypoint 3 moves 2.25 layout studs along the existing entrance normal, to `(217.0839691,0,126.4410324)`. All physical geometry stays unchanged. With final ENEMY source and forced NoPath, baseline Warden traversal fails both directions; the exact producer overlay passes both. Do not waive the standalone branch's map dependency or copy the producer edit into this PR.
2. **AUDIO [#70](https://github.com/stephennip9288-create/Roblox-Projects/pull/70): required for new audible awareness.** Inspected head `577f0efb6415ca56dcc8a5078ae319b904ed7eb4`. Server sets `AwarenessTargetUserId` and `AwarenessRunId` before publishing fresh server-time `AwarenessAt` last. Yaw/pitch/duration/variant support the pose. Actual detection requires a living participating nontravelling player, room reachability, LOS and <=65 studs, with no entry/attack/stun. Actor cooldown >=12s; global bucket 2/s, burst 2. AUDIO's existing attribute observer additionally enforces current run/local target/freshness/distance and its playback limiters. **Do not add a second Feed handler** for `EnemyAwareness`; the compatibility Feed fact has a unique source/token but the attribute observer is the agreed audio path. No new asset ID, Controller/Effects/Config edit or audible-playback claim in this lane.
3. **MAIN provenance intake: required.** `PROPOSED-RUNTIME-DELTA.json` lists exactly five owned runtime blob changes with `reviewed:false`; `RUNTIME-MANIFEST.json` pins all 61 records. These are review inputs, not approval. Preserve historical Batch 1 ledgers, `runtime_provenance.py`, workflows and release safeguards. MAIN must review combined B2 deltas, reconcile the additive test list with MAP/AUDIO/COMBAT, and rerun the complete combined candidate. COMBAT [#72](https://github.com/stephennip9288-create/Roblox-Projects/pull/72) is not copied into this lane.

## Validation boundaries

See `VALIDATION.json`, per-suite/map reports, build/fidelity reports and `CI-SOURCE-CHECKPOINT.json` for exact executed results. Completed final result: **43/43 suites, 1,104,536 assertions; all 61 runtime scripts and all 129 Luau files compile. All 378 corridor and 168 stair simulations pass** (27 corridors × seven profiles × both directions; 12 stairs × seven profiles × both directions). The exact MAP #69 producer regression also passes 119,393 checks against this combined graph: all 46,080 gate-mask reachability cases and 72,450 full-rig sweeps have zero mismatches/rejections. Its test blob is `61919a6a0e15a3e8e041624537e9bec35147e044`, run only in the disposable overlay. Both ENEMY-only and ENEMY+MAP local four-place lossless/fidelity audits pass (eight total candidates). See `PERFORMANCE.md` for measured policy CPU, including cold spikes. Baseline accepted 39 suites passed 1,071,963 assertions before development. New controlled cases cover blocked native results, access changes, target replacement/travel, 40 persistent doorway waiters, unsupported gaps, normal/Studio diagnostics, R6 priorities, actual generated corridors/stairs and bounded native request admission.

The isolated integration test overlay changes only Architecture to MAP #69's exact blob alongside ENEMY source. No MAP/AUDIO/COMBAT source is committed by ENEMY. Actual-source geometry tests use real convex parts, exact wedge planes and a 0.0001-stud float-boundary tolerance; they do not fill logical floor polygons. Controlled movement uses bounded steps and forced NoPath to stress safe fallback. This is not native Humanoid/navmesh/physics evidence.

The policy benchmark uses the actual Station room graph, real retained rigs across seven profiles and 40 active actors at round 40 for 60 virtual seconds. It tests request/route/recovery policy under controlled latency and blocked NoPath responses. CPU timings exclude engine path computation, physics, rendering, mobile and networking. A normal stationary blocked leg is reprobed after roughly 0.3s, immediately invalidated by movement/access/goal changes. Request limits remain 12/sec plus burst 4, at most 3 outstanding native computations and at most 4 new room plans per rotating tick.

The unchanged dev Python suite has **24 pass, 2 frozen Batch 1 provenance failures, 2 optional PCM fixture skips**. Failures: `test_only_owned_audio_bytes_change` and `test_all_runtime_records_match_reviewed_integration`. GitHub Validate passes; all four other no-publish workflows stop at those same two guard assertions before Lune/build. Every source-checkpoint failed job log was inspected; skipped CI stages are not represented as passes. Local standalone builds/audits are separate evidence.

`STUDIO-VERIFICATION.md` lists remaining real three-map solo/2/4-player, 40-enemy, Warden/special/Hellhound, extraction/revive, locked gate, interrupted route, accepted window density, animation/audio and physical-device checks. `BEFORE-AFTER.md` provides the executed source comparison. There is no native screenshot/clip, measured native FPS or Studio pass in this delivery.

## Reproduce without publishing

Use Lune 0.11.0 and Luau compiler 0.743. Copy the four immutable `full-baselines/v1.8.0/*.rbxl` into ignored `dev/Places/DeadSignal-v1.8.0-{Lobby,Station,Foundry,Frost}.rbxl`; do not modify originals. Use a disposable checkout of this source plus only MAP #69's Architecture blob to reproduce the integration overlay.

From `games/dead-signal/dev`:

```sh
python Tests/run.py --lune /absolute/path/to/lune --luau-compile /absolute/path/to/luau-compile
lune run Tests/syntax.luau
lune run Tests/enemy-b2-maps.luau base Frost doors 7 Warden
```

The last command is a positive test in the MAP overlay and an expected negative in the uncombined ENEMY branch. `Tests/enemy-b2-maps.luau` accepts an Architecture file as its first argument instead of `base` for direct producer consumption. For the exact wall-pushing baseline negative, follow `BEFORE-AFTER.md`.

From repository root:

```sh
python -m unittest discover -s tests -v
python -m unittest discover -s games/dead-signal/dev/Tests -v
python scripts/patch_dead_signal_rbxl.py --environment staging
python scripts/audit_dead_signal_binary.py --candidate-dir build/dead-signal-lossless/staging --baseline-dir games/dead-signal/full-baselines/v1.8.0
```

These create local review artifacts only. No Roblox publish was run, no specialist branch was merged, and no protected native baseline/production asset, place ID, saved-data schema, deployment file or release guard was changed.
