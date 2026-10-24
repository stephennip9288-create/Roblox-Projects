# Dead Signal — Batch 1 MAIN recovery and integration

MAP #52, ENEMY #53 and AUDIO #54 are integrated in the requested order. Combined offline tests and complete four-place staging/production-preview builds pass. **Ready for source/build review; native acceptance and controlled staging admission remain pending. Nothing was published.** Combined PR #44 stays open and draft.

Locally validated runtime/test source: `a4351f50198f073ad3a5cfd89160a5a27b9484ca`, tree `7dfc770bc9402fbb23412d226456332dff223c86`. The final intake/report adds explicit FFmpeg installation to Source CI; runtime and tests remain byte-identical. The previous review directory is historical; this directory supersedes its current-readiness statements without rewriting its evidence.

| Input | Reviewed specialist head | Merge commit |
| --- | --- | --- |
| MAP #52 | `7bf748868a6963f84a52dc8931c866689ea9fa34` | `e22160fe02bbb7cce2a6f94678ff55cabae17906` |
| ENEMY #53 | `09fa91eec648c67cfc7c4e3c7481469285dd1a03` | `5360967a6213f06a4148bad30205a1eec18065c0` |
| AUDIO #54 | `495b1350db04bde356f36a0a9cd8551ede73ccb3` | `16d570ab8fbba67832d12338f1fe7ea60a48fd48` |

Recovery began at actual integration `c80d55aeeae4b51ef8d836949a33bf440890c6b7`. All 555 base files and 88 specialist input files were checked against GitHub blobs. There were no merge conflicts or duplicate merges. Seven runtime files now exactly match their specialist heads: Architecture; Enemies, EnemyRigs, InfectedWardrobe, Navigation, NPCPose; and Effects. Existing completed work remains. No Batch 2 implementation occurred.

## Integration corrections

The runner registers four new suites: map-window-geometry, enemy-b1-r6, enemy-b1-entry-followup and audio-corrections-b1. It also counts the existing map suite's `checks:` result, which the old assertion parser missed. All prior suites remain registered.

The old provenance checks intentionally assumed isolated specialist branches and therefore rejected reviewed combined changes. [The additive ledger](REVIEWED-RUNTIME.json) and `Tests/runtime_provenance.py` explicitly pin Config #49 and the seven runtime changes to reviewed PR/head/blob tuples. Every one of the other runtime records must still match its prior reviewed blob. The historical ledger is preserved at blob `dcf56e871bb56f809df77515b73cfaa60fa32638`; the frozen c80 inventory remains at `a5f6c619624fa5a1372327c978cc4df86b08987b`. Frozen Effects fixtures, prefix/VFX guards, original 84-ID checks and approval flags remain enforced. Source CI now executes the Python audio/provenance audits as well as Luau.

The first combined cloud run passed all Luau suites and four other workflow families, then exposed an absent FFmpeg executable in the newly registered PCM audit. Source CI now installs that dependency explicitly; no audio check is skipped to resolve the failure. Final exact-head checks and artifact IDs are recorded in the completion checkpoint on issue #37 and PR #44, linked from CI.json.

## Validation

| Check | Combined result |
| --- | --- |
| Shared Luau runner | 37 suites; **1,071,355 assertions**, zero failures |
| All-window full-rig geometry | 210/210 cases; contextual traversal coverage retained |
| MAP support/mixed admission | 7,453 checks; 6,990 support probes, zero misses; 59 admissions / 61 safe deferrals |
| R6 / entry follow-up / audio corrections | 15,359 / 160 / 2,121 assertions |
| Existing map Batch 1.1 | 26,387 checks, zero failures; count now included |
| Pipeline Python | 81 passed |
| Audio/provenance Python | 21 cases: 19 passed, two optional input skips; separate six-case supplemental run passed with exact PCM reproduction, resolving one skip |
| Original prepared PCM | Optional 84-WAV input unavailable; all 84 committed OGG hashes and uploaded IDs still verified |
| Compilation | 121 editable Luau files; separate 61/61 runtime compiler passes and passive listening observer pass |
| Map spatial audits | 30 purchase states; 6,953 elevated clearance samples; zero failures |
| Complete binaries | Four staging + four production-preview; all 488 embedded source instances match |
| Binary fidelity | Eight independently reproduced byte-for-byte builds; original non-Source chunks/properties/Terrain/art preserved |
| Independent native reader | All eight files reopen read-only with exact source, meshes, SurfaceAppearances and materials retained |
| Protected inputs | 147 protected blobs unchanged, including native/production assets, manifests, releases and release safeguards |

[Tests](TESTS.json) · [Build hashes](BUILDS.json) · [Staging fidelity](STAGING-FIDELITY.json) · [Production-preview fidelity](PRODUCTION-FIDELITY.json) · [Native reader](NATIVE-REOPEN.json) · [Preservation](PRESERVATION.json) · [CI](CI.json).

These checks run source with Roblox datatypes/service doubles and inspect complete native files offline. They do not verify engine physics, navmesh, rendered appearance, real audio permissions/listening, physical devices or live multiplayer.

## Current staging and exact next-release rollback

The latest successful GitHub controlled staging deployment remains [run 39237971450](https://github.com/stephennip9288-create/Roblox-Projects/actions/runs/39237971450), selected source `409ae5118981ff5c9ba82802eb41c6a8326a4bc1`, control `4f41b306d2deec283fe97ac4f7af314bd9055b2f`. Actual upload log versions: Blackwater **12**, Cinderworks **12**, Whiteout **12**, Dispatch **15**. No newer controlled staging deployment was found during recovery; live Roblox APIs were not queried.

The exact retained deployed binary set is **artifact 12180128738**, archive SHA-256 `e543b305b755bb2be330f34404ddfa064d2a1979a9fdb1c184536a1ae74ad197`, retained through January 17, 2027. Re-downloading verified that digest, all four file hashes/sizes, all 244 source instances and independent raw binary fidelity. The 409ae511 runtime tree exactly matches the c80 base; generated staging PlaceConfigs also match. See [verified recovery metadata](VERIFIED-STAGING-RECOVERY.json).

**Artifact 12180281308 is the pre-audition rollback manifest.** It references the earlier c466248b / run39187149546 four-fix build, versions 11/11/11/12. It is not the binary set currently deployed. Deployment-result artifact 12180216574 separately confirms all four audition uploads. Do not use a similarly named old manifest as current recovery.

The candidate branch still contains its historical recovery record; trusted main contains the later, also now outdated c466248b pointer. Main's special audition gate admits only 409ae511, not this combined source. Before a future separately authorized deployment, a reviewed trusted-control intake must pin the exact new candidate and current-deployment recovery set above, retaining all authorization and production restrictions. This integration deliberately changes no release controls or approval flags. Expired/missing recovery artifacts must block release.

## Six-defect tracker and remaining blockers

| ID | Category / priority | Status | Cause addressed / remaining acceptance |
| --- | --- | --- | --- |
| DS-B1-001 | Audio / High | In Progress, unverified | Incorrect phase routing and sword/water fallbacks corrected; suitable missing recordings, native permission evidence and listening still required |
| DS-B1-002 | Enemies + Maps / High | Ready for Retest, unverified | Foundry10 landing seam, unreachable low queue slots, stale reservations, exclusion expiry and post-entry physics addressed; native crowds/end-wave recovery pending |
| DS-B1-003 | Maps / Medium | Ready for Retest, unverified | Earlier wall-frame corrections retained; native object/sign orientation and readability pending |
| DS-B1-004 | Maps / Medium | Ready for Retest, unverified | Earlier thematic dressing retained; native density/performance review pending |
| DS-B1-005 | Maps / High | Ready for Retest, unverified | Earlier stair/deck corrections retained; native collision/traversal/revive/extraction retest pending |
| DS-B1-006 | Enemies / High | Ready for Retest, unverified | Native R6 presentation replaces broken custom humanoids; actual faces/materials/motion/hit authority/mobile cost pending |

[Audio asset status](AUDIO-ASSET-STATUS.md) lists the 14 unuploaded candidates separately. Original 84 IDs/config, staging-only audio activation guard and all false approval attestations remain unchanged. Eleven actual reload stages lack suitable mechanism recordings and intentionally skip rather than play unrelated substitutes. No audio upload, activation or acceptance was inferred from these tests.

Follow [ACCEPTANCE.md](ACCEPTANCE.md) for the combined native retest. Scope/gameplay acceptance remain incomplete; release authorization remains false. The source/build review candidate is complete, but **publication is blocked pending trusted-control intake and separate owner staging authorization**. Production remains separately blocked. Missing recordings and native acceptance must remain visible during any limited QA audition.

## Recovery and reproduction

Continue from current `integration/dead-signal-batch1-1` / draft #44. Do not re-merge #52/#53/#54, recreate their branches or redo specialist development. Review any newer comments on #37 before continuing. This directory preserves the source and release evidence needed after interruption.

From repository root, use pinned Lune 0.11.0 and the existing native fixture preparation in Source CI:

```sh
python -m unittest discover -s tests -v
python -m unittest discover -s games/dead-signal/dev/Tests -p 'test_*.py' -v
python scripts/validate.py
python scripts/generate_dead_signal_place_configs.py
python scripts/patch_dead_signal_rbxl.py --environment staging
python scripts/patch_dead_signal_rbxl.py --environment production
python scripts/audit_dead_signal_binary.py --candidate-dir build/dead-signal-lossless/staging --baseline-dir games/dead-signal/full-baselines/v1.8.0
python scripts/audit_dead_signal_binary.py --candidate-dir build/dead-signal-lossless/production --baseline-dir games/dead-signal/full-baselines/v1.8.0
python scripts/check_dead_signal_production.py
```

From `games/dead-signal/dev`, run `lune run Tests/syntax.luau`, `python Tests/run.py --lune /absolute/lune`, `python Tests/check_map_remaster.py`, `python Tests/check_map_batch1.py` and `lune run Tools/inspect-integration-candidates.luau`. The native-reader helper's existing staging path can be changed in a disposable copy to read the production-preview directory; never reserialize a native baseline. Optional source-cache/PCM reproduction commands are documented in Tests/README.md. These commands publish nothing.

## Current supplemental audio application

The follow-up source and deployment evidence above is historical. The latest recorded staging release is now source `15b08518917482d737f60a7bd8f9c7b9c3bd0a06`, run39884224314, Dispatch19 / maps15/15/15, recovery artifact12472042399. Its archive and all244 source records have been reverified. Six supplements have since been uploaded and accepted by the owner; four are bound in the new candidate and two remain unbound. See [current application and readiness](../audio-supplement-integration-b1/README.md), [audio status](AUDIO-ASSET-STATUS.md) and Issue #37 for the exact new SHA. Native playback/listening and DS-B1-001 remain Open/unverified. This source application publishes nothing.
