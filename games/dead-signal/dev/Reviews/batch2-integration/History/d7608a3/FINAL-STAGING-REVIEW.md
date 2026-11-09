# Batch 2 final gameplay-only staging review

PR #73 · branch `integration/dead-signal-batch2` · immutable game source `60b4a05689a92819f6f31bfe22862deb353fd5c9`. The final branch HEAD also includes a metadata checkpoint pointing to this source. No staging or production deployment has been authorized or dispatched.

Original-source rights/creator review is complete for all sixteen assets. Six private owner-recorded WAV fingerprints and the explicit ownership/no-third-party/no-other-performers declaration were reviewed; ten original synthesized compositions have no external audio inputs. Existing owner listening approval and both sets of sixteen experience grants are retained. The original private WAVs are not in this public repository.

All sixteen hosted web previews played. Fourteen strict decoded full-track comparisons pass; steam and clothing drag remain inconclusive. The explicit moderation metadata API rejected absent asset-read authentication. No moderation approval or native ContentProvider/Studio/device/multiplayer test is claimed.

## Exact audio exclusion

Every row below remains `robloxApproved=false` and unavailable in the proposed native candidate. Original-source `rightsCleared` and `creatorReviewed`, owner listening and both granted universes are true. Existing Batch 1 sound banks remain intact.

| Event | Roblox asset ID | Candidate disposition |
| --- | --- | --- |
| Music.Station.Calm | `138465772345022` | Disabled |
| Music.Station.Pressure | `130706797589872` | Disabled |
| Music.Foundry.Calm | `127835878664881` | Disabled |
| Music.Foundry.Pressure | `136397741479585` | Disabled |
| Music.Frost.Calm | `76339621502898` | Disabled |
| Music.Frost.Pressure | `76092484114227` | Disabled |
| Music.Lobby.Calm | `78163810591784` | Disabled |
| Music.Warden | `125448982783761` | Disabled |
| Music.Extraction | `99490559372066` | Disabled |
| Atmosphere.Stinger | `79202413557343` | Disabled |
| Atmosphere.Station.Creak | `128855928185941` | Disabled |
| Atmosphere.Foundry.Steam | `101059835221623` | Disabled |
| Atmosphere.Foundry.Impact | `123384623508546` | Disabled |
| Atmosphere.Cry | `124107740668584` | Disabled |
| Zombie.Breath | `122477333598212` | Disabled |
| Zombie.Drag | `92629845353488` | Disabled |

The full-audio admission retains its original sixteen-complete-approvals requirement. `batch-2-gameplay-staging.json` is a distinct scope and additionally requires explicit owner acceptance of the disabled audio, exact source, five CI families, four staging hash/size pins and the complete current recovery. It cannot assert full Batch 2 acceptance or authorize production.

## Exact source-only native artifacts

All eight outputs passed independent binary/property fidelity. All 61 runtime records, 13 reviewed Batch 2 deltas and 393 preserved historical files are pinned. Original Batch 1 eight-build hashes were separately reproduced exactly. All staging destinations remain isolated from production and `DeadSignal_Profile_v1` is unchanged.

| Environment | Place | Bytes | SHA-256 |
| --- | --- | ---: | --- |
| staging | dispatch | 2784279 | `f6e551ad1a6842700f53e5b33e62065a4df7b5dad3e819d5f5d8a1c4052c3d93` |
| staging | blackwater | 2755349 | `8ab9416564799907680b79677dc260892eaf5a02ff034c135bc9999b18b56af0` |
| staging | cinderworks | 2763212 | `aafb4c48850c9a041c1f2c2c8894a223a037ebfda2fa6eeee4665ac3af4fd83f` |
| staging | whiteout | 2764655 | `8c1152fc001864dbf69e68fa3df9ddce5e7208d959d2e154d97857da0d8d6bce` |
| production | dispatch | 2784295 | `186eb166df43d9f21ca1de4694c8447daec0cf01700405ad505a4ff5e38be2a9` |
| production | blackwater | 2755365 | `caefb22d8ee03526d7c340646f2e57e5df85190a54e8c288cda944469de02c47` |
| production | cinderworks | 2763229 | `940ed0e186a02a1c352209673f7112969b47e7cba1e4b020d59da274c38b4f4b` |
| production | whiteout | 2764672 | `651e7b7374d9e982e0f92ef31806f25d8714481efc92392488ff2a3a3c63b9bc` |

## Executed validation and recovery

Current local checks: 48 Lune suites / 1,251,174 assertions; 138 Luau compilation checks; 115 root Python passes; 33 development Python passes with the same two explicitly documented optional historical-PCM fixture skips. Current source-specific GitHub results and downloaded artifact provenance are in `CI.json` and `CI-ARTIFACTS.json`; all five completed successfully for the exact source. Both push and PR copies passed. `CONTROL-REHEARSAL.json` also records the actual source/ancestry/CI guard path exercised with disposable synthetic authorization; the real admission remains unauthorized.

Current staging rollback: deployment `40054332185`, artifact `12545195246`, archive SHA-256 `09840f969288228cf3dcc0c5a6fb05dfcbb66f152f08fff5d73d2e8ed1214036`, expiry `2027-01-22T02:28:53Z`. Four exact native members and environment-specific source/config/profile settings are verified. The latest staging deployment still matches.

Production stays at deployment `41800682585`. Recovery artifact `13309518810` is verified and unexpired through `2027-02-02T08:35:30Z`; predecessor `13283390341` is preserved. No production authorization, player-data reset, recovery-pointer rewrite or Batch 3 work is included.


| CI family | Successful source-specific run |
| --- | --- |
| `validate.yml` | [42536486273](https://github.com/stephennip9288-create/Roblox-Projects/actions/runs/42536486273) |
| `dead-signal-staging-preflight.yml` | [42536486281](https://github.com/stephennip9288-create/Roblox-Projects/actions/runs/42536486281) |
| `dead-signal-production-readiness.yml` | [42536486280](https://github.com/stephennip9288-create/Roblox-Projects/actions/runs/42536486280) |
| `dead-signal-lossless-patch.yml` | [42536486332](https://github.com/stephennip9288-create/Roblox-Projects/actions/runs/42536486332) |
| `dead-signal-source-ci.yml` | [42536481811](https://github.com/stephennip9288-create/Roblox-Projects/actions/runs/42536481811) |

## Final authorization and dispatch

Owner authorization and `ready_for_staging` remain false. After all source-specific safeguards pass, the requested authorization is to approve PR #73 controls/admission for `main` and deploy only game source `60b4a05689a92819f6f31bfe22862deb353fd5c9` to private staging universe `10771141095`, explicitly accepting all sixteen new audio banks disabled. Record that authorization before merging and dispatching.

After that separate approval and controls merge, use **Dead Signal Controlled Private Staging** (`dead-signal-private-staging.yml`):

| Field | Exact value |
| --- | --- |
| Workflow branch | `main` |
| operation | `deploy` |
| confirmation | `DEPLOY-PRIVATE-STAGING` |
| source_sha | `60b4a05689a92819f6f31bfe22862deb353fd5c9` |

The workflow publishes maps first and Dispatch last, verifies all four upload results and restores all four current staging binaries on a partial failure. This review does not authorize pressing Run workflow.

Follow `GAMEPLAY-STAGING-QA.md` after authorized publication. Native desktop/controller/Android/iOS, solo/two/four-player, movement/stamina, door/stair/window pursuit, Whiteout 7, approximately forty mixed enemies, combat/upgrades/revives/extraction/teleports, saved progress and repeat-session/performance checks remain unexecuted. New-audio engine QA requires a later fully cleared and separately authorized audio candidate.
