# Dead Signal — Complete Batch 1 release gate

Status: **complete Batch 1 source is ready for owner-authorized private staging; no deployment is authorized or performed**. Owner instruction, 2026-10-17: wait for all four specialist assignments and prepare one complete update. Coordination: [issue #28](https://github.com/stephennip9288-create/Roblox-Projects/issues/28). The parent integration package is historical evidence, not the completed Batch 1 candidate.

## Source and policy selection

The existing Controlled Private Staging workflow is manual-only, runs from `main`, and requires a full lowercase 40-character integration SHA for deployment. The retired one-time push trigger is removed. It checks out pipeline controls and these release records from the workflow's exact `main` revision separately from the selected game source. Candidate branches cannot select a weaker publisher or their own completion record. Checkout credentials are not persisted and Roblox keys are available only to the final publisher step.

`batch-1.json` now selects integration **`9743b3e9ee59ba74da0d5d9a5e3f2e378230d6f7`** after reviewed integration #34 and source-admission #35. All four specialist heads and 31 source requirements are accounted for. `ready_for_staging: true` is source admission only; owner publishing authorization remains explicitly pending. MAIN DEV must repeat the reviewed record update for any later candidate after:

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

Maps #29, Enemies #31, Combat/UI #27 and Audio #26 are reviewed in one combined source candidate. Integration repairs and all 31 source requirements are recorded in `../dev/BATCH-1-TRACEABILITY.md`. The selected SHA and completed verification are recorded on trusted main through #35. The next action requires explicit owner private-staging approval. No Studio/private-client or native art/listening/device acceptance is claimed. Physical two-thumb controls comparison remains deferred.

Complete combined Python/Lune, four-place fidelity, current recovery and configuration checks, then prepare the final integration report and private-staging approval request. After owner testing and fixes, seek separate production authorization using the existing manual production workflow.


## Current release note — Complete Batch 1 RC1

- Complete integration #34: `9743b3e9ee59ba74da0d5d9a5e3f2e378230d6f7`; tested implementation `82cbf594729f33816f953ebc46eae4a578ff6d49`; evidence head `ac1cb2aa886a07ca567fd37548dec5e395b3e89a`. Four exact specialist parents are preserved; their PRs are closed as integrated through #34.
- Source-admission #35: `0e1b3fe5a9ed0e0f6888f54627cd15c58be0e748` (policy-only main merge; main gameplay remains the current production source). No publishing workflow dispatched.
- Evidence: 26 suites / 998,937 assertions; 78 pipeline Python tests plus six audio guards; 61 runtime compilations / 104 syntax files; 210 window and 63 contextual profiles; 30 purchase states / 4,017 elevated samples; eight source/fidelity builds; four native-reader reopens. All ten #34 and all ten #35 checks pass.
- CI artifact 12105612156 / run 39045133676: archive SHA-256 `824df67688710dcd372a2df52cda79a2904878919048ca8725b7d78a1251b469`; four binaries downloaded, CRC/hash verified and byte-equal to the release report. Original LoadingScreen blob `7aadee72efa020a0c798a8e10b90f4ebf89e358d` and 113 protected blobs remain unchanged.
- Native rendering/realistic-art quality, physics/networking, listening/permissions and device FPS remain untested. Source projections are not Studio screenshots. Physical two-thumb comparison remains deferred. Bespoke audio remains the Audio handoff's documented nonblocking asset dependency, with stock treatments/silent optional slots precisely inventoried.
- Owner action: approve private staging for the selected SHA, then run the complete checklist at `../dev/Reviews/batch1-integration/ACCEPTANCE.md`. Workflow: Controlled Private Staging, main, deploy, DEPLOY-PRIVATE-STAGING, source_sha equal to the full selected integration SHA. No public production promotion is authorized.
- Rollback: exact recorded staging release 10/9/9/9; production 28/22/21/21 with artwork hotfix. Recovery pointers/hashes are reviewed, historical backups untouched, expiry 2026-10-30. Reconcile any out-of-pipeline publication. After owner feedback/acceptance, prepare the final gameplay PR to main and seek separate production authorization.
