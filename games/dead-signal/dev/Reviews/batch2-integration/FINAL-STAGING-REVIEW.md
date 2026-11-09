# Batch 2 — verified audio-active private-staging candidate

**Owner authorized PR #73 merge and exact-source private-staging deployment. Production remains unauthorized.**

PR #73 remains open/draft on `integration/dead-signal-batch2`. Immutable game source: **`a74a5f524eb0c6ddccb1e19d361d741a127823df`**. The later admission/evidence commit records this source; do not substitute its HEAD or a branch name as the workflow source. Main remains `7aaf323de6153134df2154c7ae3b1613a596495b`.

## Audio evidence and activation

All sixteen rows have rightsCleared, creatorReviewed, listeningApproved and robloxApproved true in the reviewed Config. Both actual experience grant sets remain true. Mandatory `activationUniverseId=10771141095` and the Effects gate restrict new-bank activation to private staging; production and unknown universes cannot activate them. Existing accepted Batch1 sound banks, loader/failure controls, voice budgets, mute/Low Effects, all 393 protected historical records and `DeadSignal_Profile_v1` remain unchanged.

The six private WAV hashes agree with the original intake and owner creation/no-third-party attestation. Original audio bytes remain private. The ten original generated music/stinger sources retain their reviewed generator and exact OGG hashes. All sixteen have independently observed explicit Roblox `status=ReviewApproved`, correct creator, Audio type and not archived.

The owner supplied the complete native Studio export captured 2026-11-09T02:11:56Z and stated **"I confirm all intended clips."** All sixteen exact callbacks report Success, IsLoaded is true, finite durations match the sources and playback advances. MAIN reviewed this owner-provided evidence; MAIN did not independently operate native Studio. The raw report SHA256 is `57a6b7c2f2f4f3c23992c2bbecf43b3438c7b0e6005b89f466aefd7520e61ea9`.

The client-side placeVersion remains **0**, not an attested server version. Roblox documents PlaceVersion as Not Replicated server metadata. The validator's positive-version bug was corrected, while exact staging context, IDs, callbacks, durations, progress and confirmation remain mandatory. The probe makes no game-source, published-client or gameplay acceptance claim.

Strict content comparison remains fourteen passes and two inconclusive results. Clothing drag also passed the fixed supplemental band/segment comparison. Steam failed both numerical thresholds and is accepted on owner intended-clip confirmation plus strong source correspondence; no numerical failure or threshold was rewritten. See the frozen comparison, supplemental report and NATIVE-AUDIO-REVIEW.json.

| Event | Exact asset ID |
|---|---:|
| `Music.Station.Calm` | `138465772345022` |
| `Music.Station.Pressure` | `130706797589872` |
| `Music.Foundry.Calm` | `127835878664881` |
| `Music.Foundry.Pressure` | `136397741479585` |
| `Music.Frost.Calm` | `76339621502898` |
| `Music.Frost.Pressure` | `76092484114227` |
| `Music.Lobby.Calm` | `78163810591784` |
| `Music.Warden` | `125448982783761` |
| `Music.Extraction` | `99490559372066` |
| `Atmosphere.Stinger` | `79202413557343` |
| `Atmosphere.Station.Creak` | `128855928185941` |
| `Atmosphere.Foundry.Steam` | `101059835221623` |
| `Atmosphere.Foundry.Impact` | `123384623508546` |
| `Atmosphere.Cry` | `124107740668584` |
| `Zombie.Breath` | `122477333598212` |
| `Zombie.Drag` | `92629845353488` |

## Verification

All 48 local and downloaded source-CI Lune suites passed, **1,266,143 assertions**. Root Python: **121 passed**. Development Python: **33 passed, 2 documented optional historical PCM skips**. Luau syntax compilation: **140 files**. All four staging and four production-configured offline binaries match the independently reviewed pins; extracted 61-script inventories/environment configurations and raw native properties pass for every file. Historical Batch1 eight-build reproduction also passes.

All five source-specific no-publish families succeeded; both push and PR families completed successfully on the same source. The selected admission runs are:

| Family | Run | Result |
|---|---|---|
| dead-signal-lossless-patch.yml | [42551062845](https://github.com/stephennip9288-create/Roblox-Projects/actions/runs/42551062845) | success |
| dead-signal-production-readiness.yml | [42551062764](https://github.com/stephennip9288-create/Roblox-Projects/actions/runs/42551062764) | success |
| dead-signal-source-ci.yml | [42551062778](https://github.com/stephennip9288-create/Roblox-Projects/actions/runs/42551062778) | success |
| dead-signal-staging-preflight.yml | [42551062800](https://github.com/stephennip9288-create/Roblox-Projects/actions/runs/42551062800) | success |
| validate.yml | [42551062777](https://github.com/stephennip9288-create/Roblox-Projects/actions/runs/42551062777) | success |

Downloaded artifacts: staging **13645457849** / run **42551069879**, archive SHA256 `b3b4140201dd0e5a7765150a66e26fb5537481c4146534a3358a5d8255582102`; production-configured offline **13645068379** / run **42551062764**, archive SHA256 `0167bd1ea00a3090f15d2c0149bd63453edbf794535c89f4c1a121f1c04d75cb`; source CI **13645328446** / run **42551069957**, archive SHA256 `f7e623eb9c10f57d6a4dfb507b6f797e102a00fcac802b910ca1fd0740b6567b`. All archive CRCs and exact member pins were checked, and all eight downloaded native binaries were independently re-audited.

| Environment | Place | Bytes | SHA256 |
|---|---|---:|---|
| staging | dispatch | 2784393 | `c2f1574bb68157f6997aaa250a368fd79f934651a306361e1865963346b518eb` |
| staging | blackwater | 2755463 | `40ea745ae4126a8259b54eebaac235b8aeaef594234e06891c295d45ed2be695` |
| staging | cinderworks | 2763322 | `1ea386060417ff3fc9536a4022c436417a6ce7928bac25252c729cd20faf43fb` |
| staging | whiteout | 2764769 | `cf2fda90a203321b33be5c6a29111c875e972b19d373743869f7f63d0c1edf9e` |
| production | dispatch | 2784409 | `2b9980cb73e49205200dae8f5b3d75bd0ba17492fe267505cb4ab5103c0e1c9d` |
| production | blackwater | 2755479 | `2ef8aeaca574aea7cdf4a989d3be0a217ba37523cc15efa5b6090cf4e4822991` |
| production | cinderworks | 2763339 | `e365351f1bda1946691e607b639ac9a8adfb26943b69459eeb2c4144ab84bbb0` |
| production | whiteout | 2764786 | `e7ab0eba679a3acef459c9f87a3d40a06f0abb8c9fefbb90a0adb69aa9f442b7` |

## Rollback and trusted controls

Current staging recovery: run **40054332185**, artifact **12545195246**, source `f4a7d6ba0c6981a3ebe3679e64b5eea37e1dce2d`; Dispatch version **20**, all three maps **16**. Archive SHA256 `09840f969288228cf3dcc0c5a6fb05dfcbb66f152f08fff5d73d2e8ed1214036`, expires **2027-01-22T02:28:53Z**. Current production recovery: run **41800682585**, artifact **13309518810**, expires **2027-02-02T08:35:30Z**. Both archives and four members each, exact sources, environment IDs and profile namespace are verified; remote expiration/latest manual deployment metadata was rechecked read-only. All existing rollback artifacts remain intact.

The offline control rehearsal uses the real immutable source and just-retrieved GitHub CI responses, with synthetic approval only in a temporary copy and networking/publisher mocked. The actual unapproved admission is rejected; modified runtime is rejected; trusted controls reinstall after candidate tests; actual four-candidate/four-recovery preflight passes; simulated success uploads maps before Dispatch; a simulated second-upload failure restores all four exact current staging files. No Roblox request was sent. See CONTROL-REHEARSAL.json.

## Owner-controlled release and remaining work

The owner answered **"Yes"** to the explicit question authorizing PR #73 merge and deployment of this exact source to private staging. See OWNER-STAGING-AUTHORIZATION.json. `batch-2-staging.json` now has owner_staging_authorization=true, ready_for_staging=true and production_authorization=false. Finish the required control checks and trusted main merge, then dispatch only the exact admitted source. The previously disabled gameplay-only proposal stays withdrawn.

Authorization is recorded. After the trusted merge, use these exact controlled GitHub Actions values:

| Field | Exact value |
|---|---|
| Workflow | Dead Signal Controlled Private Staging / dead-signal-private-staging.yml |
| Branch | main |
| operation | deploy |
| confirmation | DEPLOY-PRIVATE-STAGING |
| source_sha | a74a5f524eb0c6ddccb1e19d361d741a127823df |

Recheck no newer staging release exists and recovery has more than fourteen days left before dispatch. The main-trusted workflow verifies the source/admission, current CI/recovery, regression checks, fidelity and exact build pins, uses only the staging API key/universe, and restores all four staging files after a partial upload failure. See STAGING-PROCEDURE.md.

No staging deployment or production publication has occurred. After authorized deployment, verify all actual place versions and retained recovery artifacts, then run native gameplay/audio QA across all three maps: desktop/controller/physical mobile, multiplayer, high-round zombies, movement, room navigation/windows, Warden, extraction, dynamic music/scare cues, positional mixing and audio settings. Offline CI and this per-ID Studio probe do not establish those outcomes. No new gameplay defect is marked Verified. Batch3 remains excluded.
