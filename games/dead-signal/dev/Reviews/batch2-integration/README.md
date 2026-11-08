# Dead Signal Batch 2 — MAIN integration

Room pursuit, tactical movement and atmosphere now share one reviewed source candidate. Issue #62 B2-01 through B2-08 is the entire scope. All four specialist contributions are retained, including the exact Whiteout door 7 producer correction and both owners' Controller changes. Batch 3 is excluded.

**Source review/offline builds are complete. Staging publication is blocked.** Six physical recording sources/rights and the remaining creator/moderation/playback evidence are unresolved; no new bank is activated. The owner has already accepted listening quality for all 16 clips. Both experience grants are independently verified. No additional listening confirmation is needed.

See `SOURCE-CHECKPOINT.json` and `CI.json` for immutable source/control SHAs and final GitHub results. `SPECIALIST-MERGES.json` records each exact specialist head, merge commit and reviewed integration tree. These source merges do not authorize a deployment.

## Reviewed source and preservation

`REVIEWED-RUNTIME.json` pins all 61 current records, their exact accepted-main blobs, each specialist's original proposal and MAIN's 13 reviewed final deltas. Changed records have frozen pre-change snapshots in `Baseline/`. The ledger and eight-build manifest are independently pinned in `scripts/dead_signal_batch2_candidate.py`; an unexplained change, reversion, extra script, altered native input or rewritten historical ledger fails validation.

| Area | Reviewed runtime files |
| --- | --- |
| MAP | Architecture: exact #69 Whiteout door 7 waypoint 3, physical geometry unchanged |
| ENEMY | Enemies, Navigation, NavigationGraph, NPCPose, Diagnostics |
| COMBAT/UI | Game, Network, Movement, UI, Controller movement/input/render hunks |
| AUDIO | Effects, Controller audioBindings/single Results dispatch, additive Config policy |

Controller's merged script retains both feature sets. ENEMY publishes `AwarenessTargetUserId` and `AwarenessRunId` before `AwarenessAt`; AUDIO's attribute observer remains the sole audible-awareness path. No duplicate Feed audio handler is added. Navigation normalizes target roots to physical floor support before using actor-height-specific portal goals. Directional movement remains shared by prediction and server validation. The proposed balance values still need native playtesting.

All 393 existing Batch 1 review, native-place, deployment-manifest, release-admission and recovery files match accepted main byte-for-byte. AUDIO's updated historical review mirror was restored; its retained composition test checks the exact Batch 1 implementation, while new suites execute the real Batch 2 mixer. The old runtime-provenance assertions still check their original ledgers after strictly normalizing only exact newly reviewed blobs. No historical ledger is regenerated.

Production readiness reproduces all eight original Batch 1 builds from frozen source and compares them against the unchanged historical admission pins. It separately checks all eight new Batch 2 builds against `REVIEWED-BUILDS.json`. New source is never represented as identical to the old release. The production publication admission and original production authorization remain unchanged and cannot admit Batch 2.

## Audio intake

`AUDIO-INTAKE.json` maps the exact 16 supplied event/ID pairs. Creator Dashboard existing-permission CSV exports independently contain all 16 matching Audio/name/owner rows for staging universe `10771141095` and production universe `10770732078`. `STAGING-GRANTS.csv` and `PRODUCTION-GRANTS.csv` retain only the 16 relevant rows; full-export hashes and row counts are recorded. No Add/Save permission operation was used.

The existing owner listening acceptance is retained per clip from Issue #62 comment 6726308792. Config records those accepted listening flags and both verified universe grants. `rightsCleared`, `creatorReviewed` and `robloxApproved` remain false where evidence is missing, so the existing mixer refuses every new bank even if its sound file loads. Accepted Batch 1 banks and all 88 production grants are unchanged.

Ten delivered musical sources are deterministic original compositions without sample inputs; their existing source files and OGG hashes were inspected. This does not establish that each uploaded asset has the exact same audio bytes or supply missing creator/rights disposition. The six creak/steam/impact/cry/breath/drag recordings have no supplied source files, creator/performer identity or ownership/license record. The Dashboard's **Uploaded** text is its Source column, not a moderation result. No native playback or moderation acceptance is inferred from that label or from experience permissions.

The eleven specialized Batch 1 reload-stage gaps remain outside Batch 2.

## Validation and candidate artifacts

All 39 original suites plus eight specialist suites and the new integrated intake suite are registered once (48 total). `LUNE-48-SUITES.json`, `OFFLINE-VERIFICATION.json` and the source-specific CI record distinguish executed checks from unperformed native QA. Root Python has 109 passing tests; dev Python has 33 passes and two explicit historical-source PCM fixture skips. All 138 Luau files compile, including the fixed 61 runtime records. New negative checks reject changes to every reviewed delta, unrelated source, native files, old ledgers, current rollback evidence, IDs, grant evidence, review manifests and build pins; source review alone cannot authorize staging.

Both four-place source-only native builds pass independent binary/property fidelity and exact build-hash checks. Only existing script Source chunks change; unchanged chunks are byte-identical. Staging/production teleport destinations remain isolated, and `DeadSignal_Profile_v1` is unchanged. Production-configured outputs are offline artifacts only.

The exact current staging rollback ZIP (artifact `12545195246`, deployment `40054332185`) was downloaded and its archive, four member hashes/sizes and environment-specific scripts verified. It expires January 22, 2027. Production recovery `13309518810` remains available through February 2, 2027; previous known-good `13283390341` is preserved. Latest manual deployment runs still match the recorded staging and production releases. No new deployment was dispatched.

## Remaining acceptance

- Source/ownership or license evidence and original files for the six physical effects, plus creator/rights disposition and uploaded-content verification for all applicable clips.
- Independently evidenced Roblox moderation/playback eligibility. Actual ContentProvider loading/audition in an authorized private-staging build is still pending.
- Studio desktop/controller/Android/iOS; solo/two/four-player movement, latency/correction fairness and camera comfort; all maps/doors/stairs/windows, target changes, Whiteout 7 and mixed 40-enemy congestion; hounds/crawlers/elites/Warden, revive/extraction; mute/Low Effects/headphones/speakers and repeat-session cleanup. Specialist native checklists remain applicable.
- Separate explicit owner staging authorization after the candidate is concrete. `batch-2-staging.json` remains `owner_staging_authorization=false`, `ready_for_staging=false`, `production_authorization=false`. No gameplay defect is marked Verified from offline tests.

Follow `STAGING-PROCEDURE.md`. The current candidate is reviewable and safely blocked; it must not be described as ready to publish with all new audio enabled.
