# Dead Signal Batch 1 audio — runtime implementation

The audio runtime is implemented in the existing `client/Effects.lua` on `feature/dead-signal-audio-immersion`. MAIN DEV granted exclusive audio-only ownership in [issue #23](https://github.com/stephennip9288-create/Roblox-Projects/issues/23) and `INTEGRATION-CONTRACTS.md`. This is a development candidate, not native listening acceptance or a complete bespoke soundscape: creator-approved recordings, lane-owned caller hooks and integrated Studio/device checks remain pending.

## Baseline and ownership

| Ref / PR | Revision and result |
| --- | --- |
| Starting main/audio branch | `5e7cc679448e4a2c0b4db084fbba522e0c7167a5`; all 263 original blobs verified before the first proposal commit. |
| Combined integration used for final testing | `2b7073cda226882343b925569bcc2b51fa7dfd88`; brought into the audio feature branch with normal merge ancestry. |
| #18 loading preview | `6ca195b`; merged. Tool/test-only; no Effects runtime edit. Preserve artwork/preview acceptance. |
| #21 maps | `6311ea3`; merged. Map modules/layouts and tests; no Effects edit. |
| #19 enemies | `7d5f23f`; merged. Enemy/Navigation/DirectorRules and tests; no Effects edit. |
| #20 combat/UI | `5336149`; merged. Controller/UI/weapons/touch and tests; no Effects edit. |
| #25 combined acceptance | Merged at `2b7073c`; includes integration-contract tests and native release gates. |
| Audio ownership | Granted 2026-10-17 at 02:00 UTC in #23, for this first audio PR. No Controller/Config/remote/VFX ownership granted. |

The initial commit `3396a3a` was an uninstalled proposal while the grant was pending. This branch now applies the audio block and one `audioUpdate` call at the start of `FX:animate`; the old proposal-only status is superseded. No parent branch is rewritten and no worker PR is merged by Audio.

Relative to current integration, only **Effects.lua's sound implementation and audio tick** change at runtime. Particle, telegraph, hazard, animation and shake code is byte-preserved. All other runtime source, Config, profiles, remotes, place IDs, loading artwork, native/rollback binaries, workflows and the shared test runner remain unchanged. There are still 61 runtime script records.

## AUD-01 traceability

| Work package | Classification / implemented behavior | Remaining acceptance or dependency |
| --- | --- | --- |
| Central sound API | Existing implementation modified; preserve all previously audible keys and `FX:sound(key,position)`. Optional third context and `audioEvent` normalize approved aliases. | Native fallback playback and mix review. |
| Threat and encounter information | Existing cues retained; new canonical Enemy/Warden/Wave/Extraction families, fixed catalog priorities and bounded gain. | Lane owners map new entrance/animation/phase facts; legacy Howl remains ambiguous until caller split. |
| Voice budget / mix | New 20 normal / 12 Low Effects hard caps; 8 / 6 slots reserved for critical warnings, routine category caps, nearest-threat preemption, ducking and headroom. | Engine overlap/mono/headset listening and device profiling. Reservation is within the total and exceeds the contract's four-slot minimum. |
| Volume / categories | Existing saved master volume updates playing sounds; mute and transient six-category gains work without new persistence fields. | Optional category settings UI is not added. |
| Lifecycle / failure handling | New Ended/TTL/owner cleanup, map-identity cleanup, run epochs, cancellation invalidation, distance culling, bounded 256-entry cooldown/cancel caches, 128-entry failure cache and 30s retry backoff. | Controller/Enemy owners call precise travel/respawn/action/source lifecycle APIs. |
| World beds / activity | New distinct Dispatch/Station/Foundry/Frost slots, 0.8s loop fades, smooth indoor/outdoor gains, intensity and authored landmark positions. | Recordings, zones and source anchors. Unavailable slots stay silent. |
| Weapon detail / materials | Existing class reports and confirmed hit/reload retained. New report/weapon/tier/material resolution and all #24 approved mechanical stages; cancelled or prior-run callbacks are rejected. | Combat/UI hooks and original recordings. Own-shot audio remains predicted in unchanged Controller. |
| Infected / K9 / entry | Existing attacks plus new groan/gear/footstep/breath/snarl/Alpha/entry/death slots. | Enemy animation/entrance hooks and recordings. |
| Lore / acoustics | Existing optional ID slots extended with finite radio transmission and caller-supplied routine spatial EQ; no global reverb mutation. | Voice/ambience rights and engine acoustics checks; no automatic wall occlusion or room impulse simulation claimed. |

## Files and verification

- `Source/Runtime/client/Effects.lua` is the actual installed implementation.
- `Effects-audio.luau` is an exact review mirror of the inline audio block, not another runtime module. The patch guard verifies it matches the installed source and every non-audio byte.
- `prepare_audio_patch.py` reproduces a guarded patch against the old audited audio block and refuses duplicate application. The current runtime already includes it; do not reapply it.
- `verify_audio.py`, `Tests/audio.luau`, `Tests/test_audio_patch.py` and the old-block fixture provide isolated and combined regression checks.
- [Event/trigger contracts](EVENT-INVENTORY.md), [asset matrix](ASSET-MATRIX.md), [listening checklist](LISTENING-CHECKLIST.md), [offline evidence](Verification-Report.json).

From `games/dead-signal/dev`, using pinned Lune 0.11.0:

```sh
python Reviews/audio-immersion/verify_audio.py --lune lune --full --lossless
```

The verifier runs the installed audio suite, six patch guards, syntax compilation, 59 pipeline tests, four manifest validations, all 20 combined regression suites, and four lossless staging-configured builds/fidelity audits. It uses a temporary source copy and byte-checked staging fixtures. It does not modify checked-in runtime or native binaries and never uploads a candidate. Publisher tests use mocks.

The new audio suite has **4,433 assertions**, including 40-NPC overlap at both quality levels, 60 map changes, live mute, missing/denied assets, listener movement, teardown, all approved weapon stages, bounded source/token caches, prior-run rejection and map replacement before the next animation tick. The 20 combined suites pass 580,040 assertions; syntax compilation covers 90 source/test/tool files. The committed JSON records exact source hashes and four-place build evidence. Audio doubles establish authored control flow/properties, not actual audibility, permission, latency, acoustics, Roblox concurrency, network travel, native physics or device FPS. The known Lune Terrain warning is why builds use the established raw lossless patcher rather than Lune serialization.

The shared `Tests/run.py` remains integrator-owned and retains all 20 existing registrations. Standard CI syntax-checks the new audio suite but does not automatically execute it yet. MAIN DEV must add `audio` **additively**, or run the documented verifier during review; passing existing cloud workflows alone is not evidence that they executed the new audio assertions.

## Integration and remaining work

The compatible runtime works with current callers immediately. New map-zone, enemy traversal/pose and weapon action hooks remain with their respective owners, under #23/#24 and `INTEGRATION-CONTRACTS.md`. Use the canonical event table to avoid duplicating existing reports or warnings. No new remote or gameplay authority is needed.

Before accepting all of AUD-01, obtain creator-approved assets, verify experience permissions, wire those owner-controlled facts, and complete Studio/solo/2-/4-player desktop/mobile/Low Effects listening, threat readability, Warden/extraction/revive/travel/loading/profile and performance checks. Keep visual telegraphs useful when audio is muted. Any private staging publish requires separate owner authorization; production requires a later separate authorization.

Rollback is a scoped Effects source revert and lossless rebuild, plus reverting any later approved caller hooks. There is no profile migration. Protected native assets and historical backups remain untouched. Audio has not merged or published a game.
