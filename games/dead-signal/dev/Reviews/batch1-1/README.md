# Dead Signal Batch 1.1 — final integration review

**NOT READY — Remaining Blockers Listed.** All four specialist PRs are integrated, the three reported regression failures are resolved, and one complete four-place native source-review build is verified. The promised six-bug overhaul is incomplete: realistic audio is not activated in Roblox, authored undead face/skin/body/uniform art is missing, and actual native gameplay retests are pending. No bug is Verified. Nothing was published or uploaded to Roblox.

## Exact integration

Built/tested source: `89fa864f6e5413a8f55780c4f6769b3b9807b077`; tree `09065452d9f8e6253799f661c134fc95dfcb10e9`. Existing branch: `integration/dead-signal-batch1-1`. Combined [draft PR #44](https://github.com/stephennip9288-create/Roblox-Projects/pull/44) targets `integration/dead-signal-next-release`. Current main stays `4ecc43cc3642eb56fb6e70beff77064d174cbbfa`; deployed Batch 1 stays `9743b3e9ee59ba74da0d5d9a5e3f2e378230d6f7`. Later reporting commits do not change the tested runtime/test source; the artifact SHA below remains immutable.

| Order / reviewed PR | Exact specialist head | Integration merge |
|---|---|---|
| 1 / Maps #39 | `9c50b6f7ff65f6f79d4550526aab40d6b84a363f` | `f89fcbaf6b87162eae4b74cac94f170f956bc974` |
| 2 / Enemies #42 | `aee7d5e38d42d862b3ebb66feaf63678be77d17d` | `0548a7e9cf9bf2f06695849b089dc1469cbf93f0` |
| 3 / MAIN adapter #41 | `848ccc9259b7e0059b9238280bdb70f4912afdf0` | `d656e754678f291385d343593bfab56f30e9cd18` |
| 4 / Audio #43 | `fd802c72f0401e00af022fd7df27dbd119c56005` | `89fa864f6e5413a8f55780c4f6769b3b9807b077` |

The enemy/audio merge commits include MAIN's reviewed shared-test integration; the exact specialist runtime blobs remain intact. Coordination #40 and actual staging-recovery repair #38 were already merged. Their protected controls are retained. No feature branches were recreated or overwritten, no direct-main merge occurred, and no Batch 2 work was added.

## Six-bug coverage

| Bug | Current status | Implemented / remaining evidence |
|---|---|---|
| DS-B1-001 Audio | In Progress — blocked | Recording-bank mixer, readiness, near/distant layers, acoustics, scheduling/cleanup and adapter integrated. 84 exact prepared recordings are review candidates; **zero Roblox IDs activated**. 73 catalog keys still have stock fallback paths, 27 are silent until suitable recordings. Specialty recording gaps and owner upload/moderation/permissions/native listening remain. |
| DS-B1-002 Windows | Ready for Retest — unverified | Supported exterior admission, queue fairness, full posed-rig sweeps, root-bound live collision, alternate landings and bounded checked recovery. Pending tickets preserve cap/quota separately from live models. All 210 window/profile plans and 63 contextual plans pass offline; native crowd/seam/physics acceptance pending. |
| DS-B1-003 Wall mounts | Ready for Retest — unverified | Proper right-handed frames repair 99 bays plus fixtures/signs/services on actual wall faces. Produced-transform tests pass; first-person/readability/native retest pending. |
| DS-B1-004 Sparse rooms | Ready for Retest — unverified | 36 functional dressing assemblies across 18 rooms; reservations, bounds and incidental no-collision/query/touch preserved. Native art-density and device-performance acceptance pending. |
| DS-B1-005 Stairs/decks | Ready for Retest — unverified | 88 leaking deck wedges repaired, 12 flush full-width landings, whole-width support/headroom and gallery-route checks. Actual walking, edge/shoulder collisions, revive, Warden/extraction pending. |
| DS-B1-006 Undead models | In Progress — blocked | Asymmetric gait and timed attacks; bracing/climb/reverse/landing poses; damaged/exposed equipment, with preserved native meshes, hit zones, armor, collision and ragdoll. **New undead faces, skin/body and uniform art are not delivered**; no native appearance acceptance. |

Foundry/Cinderworks window 10 has an exact-center offline wedge-seam support issue near X229.3600006. The reviewed consumer permits a real supported target shift of at most 0.05 world studs, still requiring full feet/paw support and entire posed-rig clearance. All seven profiles pass. This does not prove native collision safety; the seam remains an explicit Studio retest item. Impossible real geometry is a release blocker; enemies are never retired to conceal it.

## MAIN changes and shared interfaces

- `Tests/enemy-lifecycle.luau`: migrate Navigation doubles and obsolete replacement/third-failure-retirement assertions to the approved retained actor/quota/pending-admission contract. Assert exact HP/maxHP, broken/partial armor, reactor/rewards, cooldowns, failed geometry and Warden state. The three isolated PR42 failures remain recorded in its CI evidence; they were resolved, not waived.
- `Tests/infected-batch1.luau`: assert MilitaryRevision2 and live collider welded to the root during entry. Directional flinch is tested against the asymmetric neutral pose at the same timestamp, so the new idle lean cannot invalidate the directional reaction check. Existing attack/cancellation/ragdoll/clock/semantic cue assertions remain.
- `Tests/infected-geometry.luau`: actual support with **no polygon floor fill**, canonical inward facing and full stage-aware body bounds for all 210 window/profile and 63 contextual plans. End-of-suite rejection/failure gates remain mandatory.
- `Tests/Support/EnemyB11Geometry.luau` / `enemy-b11-spatial.luau`: conservative support-ray broadphase keeps the exact existing ray/SAT solver and original floor inventory. 3,441 parity assertions compare hit/miss, identity/height, seams, edges, ramps, elevated surfaces and oblique rays against the unpruned solver. No runtime collision tolerance was relaxed.
- `Tests/run.py`: 33 suites, including `map_batch11`, `audio-quality-b11` and five enemy suites exactly once. Existing `map_remaster` continues invoking `map_batch1` internally; it is not duplicated.
- `Tests/test_audio_quality_b11.py` / `REVIEWED-RUNTIME.json`: adapt the isolated Audio scope guard to an exact reviewed 61-record integration lock (12 named specialist blobs plus 49 frozen baseline blobs). The original Audio-only audit remains at PR43. The frozen Effects prefix/VFX suffix and six historical mirror guards remain intact.

Schema1 window IDs/eligibility, world-stud foot-floor approach/landing, sill-top breach, inward -Z frames and legacy hints are preserved. Enemy pending tickets are outside `enemies.list`, counted by `count()` and cleared on reset; actual Game/Director accounting tests cover cap, exactly-once quota, Warden, reset and live-only hazards/nuke iteration. Existing kind/routine/run/source facts drive Audio; there is no new remote, client damage authority, persistence field or runtime ModuleScript.

Runtime diff: Maps' Architecture, MapBuilder, MapDetail, VisualPass, MapLayouts; Enemies' Enemies, EnemyRigs, InfectedWardrobe, Navigation, NPCPose; MAIN Controller; Audio Effects (audio block only). Config, Game, Combat, Interactions, NavigationGraph, LoadingScreen, ProfileService, production IDs, workflows/builders and protected native inputs remain unchanged. All 31 prior Batch 1 IDs stay accounted for in ../../BATCH-1-TRACEABILITY.md; its historical source labels do not close the reopened audio/art quality defects.

## Validation actually completed

| Gate | Result / method |
|---|---|
| Full combined regression | **33/33 suites, 1,026,487 assertions** locally and GitHub. Original native v1.8 fixtures and historical staging fixtures both pass. No skipped/waived suite. |
| Syntax/runtime | **114 Luau files**, including all **61 runtime records**, compile. |
| Python | **78 root CI tests + 9 Audio quality tests with actual 84 WAVs/no PCM skip + 6 mirror guards = 93 cases passed**. The pruned local checkout lacks eight historical binaries, causing 22 missing-file errors in the initial local root run; the unchanged full GitHub checkout runs all 78 successfully. No fake backup or guard weakening was used. |
| Entries/accounting | 210/210 strict actual-part profiles; 63 contextual plans; runtime 1,011, appearance/pose 11,349, accounting 29, spatial parity 3,441; original entrance contracts 71 pass. Source geometry is not navmesh/physics evidence. |
| Maps/routes | Map Batch 1.1 checks 26,386; zero leaking wedges; 12 full-width ramp/landing probes; 30 ground purchase states; **6,953 elevated clearance samples**, zero obstruction. Parts Station 5,771 / Foundry 6,186 / Frost 6,415; three shadow lights per map. |
| Audio PCM | All 84 WAV and OGG hashes reproduced from 22 pinned source-declared CC0 archives. Format/peak/leading-silence and activation refusal checks pass; acting/mix/native timing and permissions are unverified. |
| GitHub | **10/10 success** across push + PR checks in all five existing automatic no-publish workflow families. See [CI.json](CI.json) for exact runs/jobs. |
| Full native build | All4 staging + all 4 production-preview files built by existing lossless process. Independent local `patch_bytes` reproduction matches every CI binary byte-for-byte. No Lune serialization. |
| Source/config | All 488 embedded source comparisons (61×8) exact; complete names/classes; generated environment PlaceConfig exact; opposite IDs absent; profile namespace and original artwork preserved. |
| Raw fidelity | Eight independent raw binary audits pass; unchanged world/asset/Terrain/property records preserved. One Source PROP chunk changes per place; untouched chunks Dispatch 1,513 / Station 1,496 / Foundry 1,500 / Frost 1,500 remain byte-identical. |
| Native read-only reopen | All8 deserialize and match all 61 sources. Native inventory retained: Dispatch 962 MeshParts/873 SurfaceAppearances; Station 726/661; Foundry 752/687; Frost 786/721. Each has 24 MaterialVariants and 1 Terrain. |
| Protected comparison | All 155 selected protected Git blobs unchanged. Of 382 pre-existing patch-base files, 363 unchanged and 19 intentional source/test/mirror edits; other additions are specialist assets/tests/evidence. See [Protected-Inputs.json](Protected-Inputs.json). |
| Actual Studio/Roblox/device tests | **Not run here; no Studio/native app is available.** Read-only Lune reopening, bounds projections and SAT/rays are offline checks. All gameplay acceptance is pending. |

Primary evidence: [Build-Report.json](Build-Report.json), [Tests-Report.json](Tests-Report.json), [CI-Tests-Report.json](CI-Tests-Report.json), [Artifact-Verification.json](Artifact-Verification.json), [Source-Inventories.json](Source-Inventories.json), both raw fidelity reports, [Native-Reopen.json](Native-Reopen.json), [Recovery-Verification.json](Recovery-Verification.json). Report keys inherit some historical v1.8 builder labels; the exact tested source 89fa864 and binary hashes below identify this patch.

## Complete native review artifacts

These are complete four-place source-review artifacts, **not the completed/authorized Batch 1.1 overhaul**. Use the packaged staging files for unpublished Studio review only. The production preview is an isolation/parity proof and must not be promoted.

| Staging file | Bytes | SHA256 |
|---|---:|---|
| Dispatch | 2745665 | `d9949b061ed7781aedb23f09e0e1770538526bbcac7e8b5c3bf15427a0434775` |
| Blackwater Station | 2716743 | `ccec7486d2180add45ede06a05f5490c4c5bc2b2676cbb5db7fc7a5e678fd435` |
| Cinderworks | 2724590 | `8eb56106aadd551f91bc4fe22ae73ccade40571388590cdc846cec6ba5aa645e` |
| Whiteout Relay | 2726049 | `2f4e1b9046bf72c5fb6ed49c62c3cffa922154df87f14492ba198fb691c38c43` |

Exact-source GitHub artifacts:

- [Staging lossless build run 39169706846](https://github.com/stephennip9288-create/Roblox-Projects/actions/runs/39169706846), artifact 12152570131, archive SHA256 `edfb1deee87fee2527258d6b8e309d37a3b297cd6af21238ce66d31af60de4a1`; expires 2026-11-01.
- [Production isolation/parity run 39169706812](https://github.com/stephennip9288-create/Roblox-Projects/actions/runs/39169706812), artifact 12152366475, archive SHA256 `a56d69b8ae6a42162354e7dced6aca86bb366112b78d45ce500337dc30b5fd05`; expires 2026-11-01.
- [Staging preflight run 39169706825](https://github.com/stephennip9288-create/Roblox-Projects/actions/runs/39169706825), artifact 12151833202, verified archive SHA256 `c945c884ad3884d3e589dce8a75d7bb29b28b09c2fb2de482138677bc8ebe755`.
- [Source/config run 39169706833](https://github.com/stephennip9288-create/Roblox-Projects/actions/runs/39169706833), artifact 12151659245, verified archive SHA256 `1d085ad27140295aead5537e7b658a7f8dd1862e26afa9c6aa3640a1a0bc1a44`.

All archives were downloaded and hash/CRC checked. [STAGING-SHA256SUMS.txt](STAGING-SHA256SUMS.txt) and the full8-build verification report include every binary hash. The original complete native contents remain in all files.

## Blockers, retest and rollback

1. **Audio:** owner/authorized Roblox creator must select/approve the prepared recordings, identify owning user/group, authorize/import them, pass moderation and grant/confirm access to private staging universe 10771141095. Complete the exact-ID/WAV-hash upload template; MAIN reviews the generated Config proposal and rebuilds. Dedicated LMG/proxy acceptance, energy, canine breath/howl/paws, metal boots, ice/steam/emergency/comms gaps remain explicit. No unauthorized upload, made-up ID, stock substitute or silence closes DS001.
2. **Undead art:** original/rights-cleared faces/body forms/skin and clothing atlases, source/UV/bind/provenance, approved IDs and preservation-aware asset intake remain required. Existing procedural poses/equipment do not replace that work. See [ASSET-ACTIONS.md](ASSET-ACTIONS.md) and the enemy [authored-art specification](../enemies-batch1-1/Asset-Requirements.md).
3. **Native acceptance:** actual Studio/client gameplay, all stairs/windows including Foundry 10, live collision/crowds/downed/revive, both modes, solo/2/4, dense waves, Warden/extraction, teleports, loading art, saves/purchases, sound/listening and mobile frame-time acceptance remain pending. Follow [ACCEPTANCE.md](ACCEPTANCE.md). Physical two-thumb comparison remains deferred.

Actual deployed Batch 1 rollback: source `9743b3e9ee59ba74da0d5d9a5e3f2e378230d6f7`, successful owner run 39056526660/attempt 1, versions Dispatch 11 / Station 10 / Foundry 10 / Frost 10. Retained artifact 12109702848, ZIP SHA256 `e969cc319cc71c6ff55d24c9ddc546d674f2035192e44f6586c5a6fe00b1117b`, available through 2027-01-15. MAIN re-downloaded/hash/CRC checked it and all four binary hashes, source inventory, staging configs and profile namespace. The separate current production recovery set is also checked and unchanged. Historical checked-in v1.7 files are preserved, not used as the current live rollback.

Trusted main recovery metadata from #38 is current. `batch-1-1.json` is updated as a **blocked informational record**: candidate_source_sha 89fa864; scope_complete=false; ready_for_staging=false; source_sha=null; both authorizations=false. Trusted main's existing batch-1.json admits only the previously deployed 9743b3e. The existing completion guard rejects 89fa864 as intended. No source-selection/publishing guard, workflow or rollback fallback was weakened.

After the asset/art blockers and necessary native preflight are resolved, rerun the final exact-SHA tests/builds, prepare the reviewed trusted-main source admission, and request owner approval for **one complete private-staging publication** through the existing main-only controlled workflow. Retain the exact candidate archive before use; deploy maps then Dispatch, with existing recorded-release recovery on failure. Complete owner staging retests/acceptance before any reviewed main promotion; production additionally requires separate explicit owner authorization and its production-only configs/manual workflow/current-release rollback. No current action publishes, requests credentials or changes player data.
