# Dead Signal Batch 2 — final source review and staging preparation

All four specialist contributions and all eight approved Batch 2 features remain integrated in PR #73 on `integration/dead-signal-batch2`. Room pursuit, tactical movement, Whiteout door 7 and the bounded atmosphere/music/foley implementation are retained. Batch 3 is excluded. No staging or production publication has occurred in this preparation.

The current candidate is a **gameplay-only private-staging proposal with all sixteen new audio banks disabled**. `SOURCE-CHECKPOINT.json` identifies the immutable source and source-specific CI/artifacts after verification. `batch-2-gameplay-staging.json` is a distinct admission; it remains unauthorized until the owner approves its exact source and audio exclusion. The full-audio `batch-2-staging.json` is retained as a blocked earlier checkpoint and its sixteen-asset gate has not been relaxed.

## Audio evidence and deliberate exclusions

The private six-WAV archive was obtained and independently rechecked: ZIP SHA-256 `41716d4d9daee68b8c76ec17816a8c8abb97ba63665f07ba51660d790559f19b`, six expected entries, valid CRC/PCM headers, all six source hashes match PR #73 comment 6728110538. The owner declares that these are personally recorded/performed, contain no third-party samples and include no other performers (Issue #62 comment 6728525723). Original WAVs remain private and are not committed. `AUDIO-SOURCE-REVIEW.json` records source fingerprints and clearly separates owner attestations from independently checked properties.

The ten musical compositions use the reviewed deterministic additive-synthesis generator without external audio inputs; all ten committed OGG hashes match the original inventory. MAIN accepts the original-source rights/creator review for these ten compositions and the six owner-attested effects. Config now records `rightsCleared=true`, `creatorReviewed=true`, the existing `listeningApproved=true`, exact asset IDs and both previously exported experience grants. `robloxApproved=false` for **all sixteen** keeps every new bank unavailable even if its file loads. The current integrated Lune suite executes this behavior in both universes and unknown universes, and preserves every Batch 1 sound bank.

All sixteen owner-authenticated Creator Store previews loaded (`readyState=4`) and playback advanced without a media error. Their downloaded, DOM-exposed hosted media were compared over the full track with the supplied originals, accounting for resampling/transcoding. `HOSTED-CONTENT-COMPARISON.json` records original and hosted hashes, frame coverage, channel correlations, delay and fitted RMS error. Fourteen pass the fixed strict threshold. Steam (`101059835221623`) and clothing drag (`92629845353488`) remain inconclusive; no threshold was relaxed. The encodings are not byte-identical.

An explicit moderation result is still unavailable: the documented asset metadata GET returned `Invalid authentication data provided`; this environment has no authorized asset-read API binding. A working owner preview, the Dashboard Source label **Uploaded**, and experience grants do not substitute for `moderationState`. Native Roblox ContentProvider playback is also untested. The full-audio release remains blocked. The distinct gameplay-only proposal does not audition those assets or claim audio acceptance.

All 32 existing grants remain independently evidenced by the read-only exports in `STAGING-GRANTS.csv` and `PRODUCTION-GRANTS.csv`. The owner already approved listening quality for all sixteen; no repeat listening confirmation is requested.

## Source integrity and validation

`REVIEWED-RUNTIME.json` pins the fixed 61-record inventory, 13 final Batch 2 deltas, all specialist heads and frozen pre-change snapshots. Only the additive Config source-review flags/comments changed after the preceding integration checkpoint; gameplay code was not restarted or rewritten. Both source and eight-build ledgers have independent pins in the trusted guard. The prior reviewed candidate's ledgers, CI and artifacts are retained under `History/fccea067/` and in git.

All 393 historical Batch 1/native/recovery files remain byte-identical. Historical tests still normalize only exact reviewed Batch 2 blobs against frozen source; the original ledgers are never regenerated. Production readiness separately reproduces all eight original Batch 1 hashes and verifies all eight new source-only build hashes. Existing production admission cannot authorize Batch 2.

All 48 suites remain registered once. Current executed results are recorded in `OFFLINE-VERIFICATION.json`, `LUNE-48-SUITES.json`, `CI.json` and `CI-ARTIFACTS.json`. The gameplay-only gate adds negative checks for missing authorization/exclusion, enabling even one new bank, changing source/CI/build/rollback evidence, false native acceptance and using the narrow admission as a full-audio release. The upload path still enforces all four exact staging hashes before any publish call.

Both four-place source-only builds preserve all untouched binary chunks/properties, the staging/production destination isolation, and `DeadSignal_Profile_v1`. Production-configured artifacts are offline outputs only.

## Recovery and authorization

The current staging recovery remains deployment `40054332185`, artifact `12545195246`, expiry January 22, 2027; all four verified native files are usable. Production remains deployment `41800682585`, recovery artifact `13309518810`, expiry February 2, 2027, with previous known-good `13283390341` preserved. Latest manual runs still match those records. No player-data reset or release-pointer rewrite is part of this change.

Follow `STAGING-PROCEDURE.md`. The source-specific checks and artifacts must pass before the final owner request. Only separately authorized controls/admission on `main` may dispatch `dead-signal-private-staging.yml` for the exact approved SHA. Authorization and `ready_for_staging` remain false until then; production authorization remains false throughout.

`GAMEPLAY-STAGING-QA.md` prepares desktop/controller/mobile, solo/multiplayer, doors/stairs/windows, Whiteout 7, approximately 40-enemy congestion and regression testing. No gameplay bug is marked Verified by offline tests. Audio QA for the sixteen excluded assets is deferred until a later fully reviewed audio candidate.
