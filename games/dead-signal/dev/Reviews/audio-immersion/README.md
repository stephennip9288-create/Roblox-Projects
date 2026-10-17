# Dead Signal Batch 1 audio — executable proposal, awaiting ownership grant

**AUD-01 is partially prepared, not integrated or complete.** This branch contains an implemented and offline-tested inline audio engine, guarded patch composer, event contracts and asset/listening evidence. It deliberately leaves **every runtime source file unchanged** while the explicit shared-file ownership gate is pending in [issue #23](https://github.com/stephennip9288-create/Roblox-Projects/issues/23).

`handoffs/AUDIO.md` requires: “Request exclusive time-limited ownership of the **audio-facing** portion of `client/Effects.lua` from the integration lead.” The parallel protocol additionally permits these changes “**only after integrator grants scoped ownership**.” No grant had been recorded when this proposal was prepared. This is a coordination dependency, not a request to deploy or an assumption of approval. The standalone proposal can be reviewed and tested before that decision.

## Baseline and existing work audit

| Ref / PR | Observed revision | Finding |
| --- | --- | --- |
| `main`, audio feature branch starting point | `5e7cc679448e4a2c0b4db084fbba522e0c7167a5` | Approved Batch 1 handoffs merged; source snapshot verified against all Git tree blobs. |
| `integration/dead-signal-next-release` | `1a5b9f3b811137b6881090ad634a13624d33dd71` | Behind main's approved handoff merge. Bring forward those docs through integration; they are inherited ancestry, not audio edits. |
| #18 loading preview | `6ca195b0b021f95a34ee8946d3d1bc884f902815`, open | Tool/test-only; no Effects runtime edit. Preserve artwork and preview acceptance. |
| #19 enemy recovery | `7d5f23f48eb61fb57a0f785378b22010594237c9`, open | Enemy/Navigation/DirectorRules plus tests; no Effects edit. |
| #20 combat/UI | `533614972cd0c17212203d3099202f534a75aed8`, open | Controller/UI/weapons/touch files plus tests; no Effects edit. Audio caller wiring belongs to this owner/integrator. |
| #21 maps | `6311ea3063bc789eea9cb0bc8876ef1f43f9b800`, open | Map modules/layouts plus tests/evidence; no Effects edit. Audio zones need this owner/integrator. |

Actual changed-file lists, current main source and all required handoffs/release docs were inspected, not just PR titles. This audio branch does not stack or duplicate those four implementation diffs. Its runtime proposal has no code dependency on their unmerged changes; final combined map/animation/weapon triggers and acceptance do depend on integration. Every parent PR's additive `Tests/run.py` registration must be preserved. This branch leaves that gated runner unchanged.

## AUD-01 traceability

| Work package | Classification at audit | Evidence and proposal | Remaining dependency |
| --- | --- | --- | --- |
| Central FX sound path | Already present; modified in proposal | Existing `FX:sound(key,position)` and configured ID slots; preserve legacy audible keys. | Scoped Effects grant/application. |
| Warnings, special waves, hit/reload confirmation | Already present; modified in proposal | Controller handles SpecialWave, EnemyTelegraph, HazardWarning, ShockWarning, ArmorBreak, Hit and Reload. | Semantic separation of charge vs regular Howl; new event hooks. |
| Polyphony/ducking/headroom | Genuinely new proposal | 20 normal / 12 Low Effects voices; 8 / 6 reserved threat slots; caps per routine category; nearest critical preemption. | Engine listening/performance. |
| Live volume, category gains | Modified / new proposal | Existing master slider now affects playing voices; session-only six-category gains, mute, input clamping. | UI category controls/persistence are not added; schema stays unchanged. |
| Lifecycle and failure handling | Genuinely new proposal | Ended/TTL/owner cleanup, cancellation tokens, range culling, 256-entry cooldown bound, 128-entry asset failure bound and 30s retry backoff. | Controller map/travel/respawn/weapon lifecycle calls. |
| Distinct map beds/landmark activity | Genuinely new proposal; assets blocked | Separate Station/Foundry/Frost/Dispatch slots, 0.8s fades, indoor/outdoor gains, intensity, positioned landmarks. | Approved recordings/IDs, zones and source anchors. Empty slots remain silent. |
| Weapons/mechanics/material impacts/steps | Partly present; extended in proposal | Class reports and ack reload/hit already present. New pump/bolt/shell/magazine/material/weapon/upgrade slots. | Combat owner acknowledgment/cancellation/animation triggers and recordings. Local shot remains predicted in unchanged Controller. |
| Infected locomotion/window/K9 | Some attack cues present; extended in proposal | Groan/gear/entry/footstep/breath/snarl/Alpha/charge semantic slots. | Enemy owner animation/entrance hooks and recordings. |
| Lore transmissions/acoustics | Config slots already present; new optional treatment | Finite radio slot, caller-supplied occlusion EQ for routine spatial sounds, no global reverb mutations. | Rights-cleared voice/ambience; authored zone/occlusion data and Studio verification. No automatic wall occlusion claimed. |

## Files and scope

- `Effects-audio.luau`: inline replacement block for the existing Effects script; **not a new ModuleScript and not a required runtime dependency**.
- `prepare_audio_patch.py`: composes an exact proposal and refuses concurrent audio edits or duplicate application. It cannot write to runtime Effects.lua.
- `verify_audio.py`, `Tests/audio.luau`, `Tests/test_audio_patch.py`: execute the proposal, guard every non-audio byte, and exercise temporary candidate builds.
- `Tests/Fixtures/Effects-audio-before.txt`: exact audited old audio block used to keep patch tests reproducible after approved integration.
- [Event inventory and trigger contract](EVENT-INVENTORY.md), [asset availability](ASSET-MATRIX.md), [listening acceptance](LISTENING-CHECKLIST.md), [offline evidence](Verification-Report.json).

The eventual patch changes only the old audio block and adds `self:audioUpdate(dt)` at the **start** of `FX:animate`, before its existing early return. Particles, hazard visuals, rig animation and public legacy calls are byte-preserved. No Config, Controller, map/enemy, profile, remote, native asset, PlaceConfig, workflow, archive or rollback file is edited here.

## Reproduce

From `games/dead-signal/dev`, with pinned Lune 0.11.0:

```sh
python Reviews/audio-immersion/verify_audio.py --lune lune --full --lossless
```

This executes audio assertions and patch guards, compiles the candidate, runs all 59 pipeline tests, validates four manifests, runs the 12 existing Lune suites against the proposed Effects in a temporary source tree, and builds/fidelity-audits all four temporary staging-configured native candidates. Temporary fixtures are byte-checked copies of the existing staging binaries. No candidate is uploaded. Publisher test logs use mocks; text such as “published” in those tests is not a deployment.

The committed evidence records 4,395 audio assertions, 6 patch-guard tests, 11,678 existing regression assertions, 84 syntax-compiled source/test/tool files and the 61 runtime record count. Unrelated native chunks remain byte-identical: Dispatch 1,513; Blackwater 1,496; Cinderworks and Whiteout 1,500 each. Audio tests use deterministic clock/Sound/signal doubles; they prove control flow and authored properties, **not** audibility, permissions, acoustics, engine concurrency, client latency, physics, networking or target-device frame time. Lune's known Terrain read warning does not authorize serializer replacement; candidates use the established raw lossless patcher.

Existing CI syntax-checks the new Luau test but does **not** run the new audio assertions until the integrator registers them or runs the command above. Existing cloud checks alone must not be represented as coverage of the new audio behavior. After runtime application, the audio suite exercises the installed source; before application it composes the proposal in memory.

## Integrator next actions

1. Record the scoped Effects ownership decision and approve event contracts in #23. Recheck current Effects and competing diffs.
2. After granting access, emit the guarded patch and review it:

   ```sh
   python games/dead-signal/dev/Reviews/audio-immersion/prepare_audio_patch.py --output /tmp/dead-signal-audio.patch
   git apply --check /tmp/dead-signal-audio.patch
   git apply /tmp/dead-signal-audio.patch
   ```

3. Coordinate caller hooks with lane owners using the inventory. Add `audio` to `Tests/run.py` **additively** and run the Python guard suite; do not remove any #18–#21 suite. No runtime script is added.
4. Fill approved asset slots only after ownership/rights review, then perform Studio/device listening and integrated solo/2/4-player acceptance. Preserve all visible threat telegraphs even with audio muted.
5. Review exact source SHA and four-place preservation evidence. Any private staging publication needs separate owner approval; production needs a later separate authorization.

Rollback before application is removal of these proposal/test/docs files, with no game behavior or data changes. After approved application, revert the scoped audio patch/caller changes and rebuild through the established lossless process; there is no data migration. No merge or publication is performed by this audio work.
