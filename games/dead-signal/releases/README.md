# Dead Signal — Complete Batch 1 release gate

Status: **not ready for staging; no deployment authorized**. Owner instruction, 2026-10-17: wait for all four specialist assignments and prepare one complete update. Coordination: [issue #28](https://github.com/stephennip9288-create/Roblox-Projects/issues/28). The parent integration package is historical evidence, not the completed Batch 1 candidate.

## Source and policy selection

The existing Controlled Private Staging workflow is manual-only, runs from `main`, and requires a full lowercase 40-character integration SHA for deployment. The retired one-time push trigger is removed. It checks out pipeline controls and these release records from the workflow's exact `main` revision separately from the selected game source. Candidate branches cannot select a weaker publisher or their own completion record. Checkout credentials are not persisted and Roblox keys are available only to the final publisher step.

`batch-1.json` deliberately has `ready_for_staging: false` and no approved candidate SHA. MAIN DEV updates it through a reviewed control-only PR after:

1. All four specialist PRs are complete and reviewed, including exact head SHAs. Each head must be an ancestor of the selected integration candidate.
2. All 31 IDs (MAP-01..12, EN-01..09, WPN-01..09, AUD-01) have complete implementation and concrete evidence. Placeholders or unresolved integration dependencies are not completion.
3. Combined regressions, four-place fidelity, environment isolation, shared contracts and recovery verification pass at that immutable SHA.
4. The final report names remaining native Studio checks, the precise candidate hashes and the private-staging approval request. Offline CI is not gameplay or listening acceptance.

The completion record is an admission gate, **not deployment approval**. Do not set it true to test a partial branch. The release workflow verifies all 61 runtime source records against the selected commit before candidate tests and again afterward, reinstalls trusted pipeline controls, and verifies that built sources match the selected runtime exactly. Existing production source-pin support remains available for separately authorized hotfixes; it does not waive staging acceptance or production authorization for Batch 1.

## Recorded recovery sets

| Environment | Successfully published source | Run / attempt | Dispatch / Blackwater / Cinderworks / Whiteout versions |
| --- | --- | --- | --- |
| Private staging | `2a7e99e36ccb36b941990c70e8d43a09b2ed131d` | [38954616169](https://github.com/stephennip9288-create/Roblox-Projects/actions/runs/38954616169) / 1 | 10 / 9 / 9 / 9 |
| Production | `1a5b9f3b811137b6881090ad634a13624d33dd71` | [38985770842](https://github.com/stephennip9288-create/Roblox-Projects/actions/runs/38985770842) / 4 | 28 / 22 / 21 / 21 |

`recovery-staging.json` and `recovery-production.json` pin the existing CI artifact and its workflow head SHA, archive SHA-256, each exact binary member, bytes, place/universe IDs, successful deployment and returned version numbers. Production recovery retains the original artwork hotfix. Staging recovery describes its actual prior release; it is not substituted with production IDs or a newer unaccepted game build.

The archived bytes were downloaded, hash/CRC checked, parsed and verified for all eight files on 2026-10-17. Each has 61 script sources, the exact generated environment-only PlaceConfig and `DeadSignal_Profile_v1`. These artifacts correspond to the recorded pipeline releases; they are **not fresh downloads of current Roblox places**. Reconcile any publication outside the pipeline before authorizing a new deployment.

Actual rollout code now refuses historical committed `places/*/staging.rbxl` or `production.rbxl` backups. Those immutable historical files remain untouched. A missing, expired, changed, wrong-source or wrong-environment artifact blocks publishing. There is no fallback to an old release. Before a new deployment, the latest preceding deployment run/attempt must still match the recorded successful release; newer or failed runs require reconciliation. The workflow excludes its own current run from that check.

An explicitly authorized manual rollback can restore the pinned known-good set after a failed release. It requires no candidate build or candidate test suites, but still verifies artifact provenance, every binary hash and environment IDs. All four places are restored in maps-first/Dispatch-last order. Automatic recovery after any failed upload attempts all four, including the request that may have timed out after acceptance. Network or Roblox failures can still prevent restoration; result artifacts record every failure.

## Artifact lifecycle and later releases

Current recovery artifacts expire **2026-10-30**. Expiry blocks deployment; refresh the verified recovery artifact through a reviewed record update before relying on it. Do not silently choose a similar filename or a historical backup. The controlled workflows retain future exact candidate binaries for 90 days before attempting their upload.

After a successful authorized release, MAIN DEV must record the exact candidate artifact ID/archive hash/member hashes, selected game source SHA, artifact workflow head SHA (which may differ from the game source pin), successful deployment run/attempt and returned place versions in a reviewed recovery-record PR. Confirm actual live state if any upload/recovery failed. Until that record matches the latest release, the next deployment is intentionally blocked. Preserve the previous known-good recovery artifact for rollback review; no automatic commit or production promotion is introduced.

## Remaining gates

Maps #29, Enemies #31, Combat/UI #27 and Audio #26 are reviewed in one combined source candidate. Integration repairs and all 31 source requirements are recorded in `../dev/BATCH-1-TRACEABILITY.md`. The selected immutable final SHA and completed verification must be recorded through a separate main-control review before the gate can open. No Studio/private-client or native art/listening/device acceptance is claimed. Physical two-thumb controls comparison remains deferred.

Complete combined Python/Lune, four-place fidelity, current recovery and configuration checks, then prepare the final integration report and private-staging approval request. After owner testing and fixes, seek separate production authorization using the existing manual production workflow.
