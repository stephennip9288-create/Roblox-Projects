# Dead Signal — Batch 1 deployed / Batch 1.1 corrective gate

Batch 1 was successfully published to private staging by the owner on 2026-10-17. Initial owner gameplay testing identified six defects. This is **not full staging acceptance** and does not authorize another deployment or production promotion. Corrective work is tracked in [#37](https://github.com/stephennip9288-create/Roblox-Projects/issues/37); the historical integration ledger remains [#28](https://github.com/stephennip9288-create/Roblox-Projects/issues/28).

## Actual release provenance

| Environment | Game source | Control source / successful run / attempt | Dispatch / Blackwater / Cinderworks / Whiteout versions |
|---|---|---|---|
| Private staging | `9743b3e9ee59ba74da0d5d9a5e3f2e378230d6f7` | `5f6d0a0c1ab3d462bc0a3f4413d3ce4593a3e6bb` / [39056526660](https://github.com/stephennip9288-create/Roblox-Projects/actions/runs/39056526660) / 1 | 11 / 10 / 10 / 10 |
| Production | `1a5b9f3b811137b6881090ad634a13624d33dd71` | same source / [38985770842](https://github.com/stephennip9288-create/Roblox-Projects/actions/runs/38985770842) / 4 | 28 / 22 / 21 / 21 |

The successful staging job logs show the selected game SHA and all four returned version numbers. PUBLISH-RESULT confirms four published places and production_touched=false. These are pipeline publication records; they are not fresh Roblox downloads or evidence of later out-of-pipeline changes.

The retained exact staging candidate is artifact `12109702848` from that same run, archive SHA-256 `e969cc319cc71c6ff55d24c9ddc546d674f2035192e44f6586c5a6fe00b1117b`. It was downloaded, hash/CRC checked and all four RBXLs match the original Batch 1 candidate hashes. Each has the generated staging-only PlaceConfig, 61 source records and the unchanged production profile schema. Native instance/assets are retained through the existing lossless Source patch.

## Recovery pointers and expiry

`recovery-staging.json` now names the actual successfully published Batch 1 set, including separate game/control SHAs, artifact members/hashes, deployment attempt and versions. The preceding staging record is preserved at `history/staging-38954616169.json`; its artifact is not substituted automatically. Production recovery is unchanged and retains the original artwork hotfix.

Staging's retained artifact expires **2027-01-15**; production's current artifact expires **2026-10-30**. Missing/expired/wrong-source/wrong-environment archives block deployment. Historical checked-in `places/*/{staging,production}.rbxl` backups remain untouched and are not used by the actual publisher. Reconcile a manual Roblox publication or failed release before relying on a recorded recovery point.

The deployment guard compares the latest preceding release run/attempt with the recorded successful deployment, excluding its own run. Candidate controls are checked out from exact trusted main separately from the immutable game source. Runtime source bytes are verified before and after tests; trusted controls/manifests are reinstalled; candidate binaries must match the chosen 61 records and generated environment config. Roblox keys are scoped to the final publishing step. No fallback to historical v1.7 binaries exists.

An explicitly authorized rollback restores the pinned set after verifying provenance, archive/member hashes and IDs, without requiring a candidate build or fresh candidate CI. All four places are attempted maps-first/Dispatch-last, including ambiguous failed upload requests during automatic recovery. Network/API failures may still prevent restoration; inspect the result artifact. Keep the previous archive available for separately reviewed emergency recovery.

## Batch 1.1 corrective gate

The six owner reports are artificial audio, stuck exterior window entries, incorrect wall mounts, empty rooms, stair/deck traps and mannequin-like infected. New isolated branches must preserve all completed Batch 1 changes and all 31 approved requirements. Review the frozen `handoffs/BATCH-1-1-FIXES.md` contract on the patch integration branch. No defect is Verified until its implemented fix passes the appropriate actual staging retest.

`batch-1.json` still selects only the previously reviewed Batch 1 SHA `9743b3e9ee59ba74da0d5d9a5e3f2e378230d6f7`. It **does not admit any Batch 1.1 candidate**. Do not repin it for partial work. The complete corrective patch needs reviewed Maps -> Enemies -> Audio source, bug-by-bug evidence, all Python/Lune/compile regressions, config isolation, raw four-place fidelity and reconciled current recovery. A substantive realistic-audio requirement cannot be claimed complete from unsuitable stock fallbacks or silent asset slots. Identify suitable authorized samples, permissions and required listening checks explicitly.

After those gates pass, prepare one complete immutable candidate and a reviewed source-selection update, then request **new explicit owner private-staging publication approval**. The previous Batch 1 approval does not apply to this patch. The manual workflow remains Controlled Private Staging on main, with deploy / DEPLOY-PRIVATE-STAGING / full selected source_sha. No partial publication, push-trigger workaround or automatic production promotion is allowed.

Following the owner's staging retest and acceptance, prepare the reviewed final gameplay PR to main and obtain **separate explicit production authorization**. Use the existing manual production workflow, production-only configs and verified production recovery. Do not substitute staging IDs.

## Prior Batch 1 evidence and limits

Integration #34 at `9743b3e` retained all four specialist parents; source admission #35 and documentation #36 changed main controls/docs while main gameplay remains the production source. Baseline evidence was 26 suites / 998,937 assertions, 78 pipeline Python tests plus six audio guards, 61 runtime compilations, 210 window profiles, 63 contextual profiles, 30 purchase states and 4,017 elevated samples, eight lossless/config/fidelity builds and four reader reopens. The original LoadingScreen source and 113 protected blobs were unchanged.

Owner testing has since found real defects; those offline passes did not establish native physics, asset quality, sound quality/permissions, networking or device FPS. Physical two-thumb controls comparison remains deferred. Preserve the initial test report and exact deployment while tracking corrective evidence separately.
