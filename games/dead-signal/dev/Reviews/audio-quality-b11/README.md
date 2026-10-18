# DS-B1-001 — Batch 1.1 audio quality candidate

**Status: Open. Source and recording candidates are ready for review; the realism target is not achieved or verified while custom Roblox IDs remain empty. No upload or publication has occurred.** The unchanged Config still selects the temporary stock effects listed below. Offline tests and sample auditions do not establish native audio quality, ownership permissions or physical-device performance.

Branch `fix/dead-signal-batch1-1-audio`, frozen base `206ae616a7de4fe8dd69b1c8019bae6ea8b6863d`, target `integration/dead-signal-batch1-1`. [Draft PR #43](https://github.com/stephennip9288-create/Roblox-Projects/pull/43) follows merged audio [#26](https://github.com/stephennip9288-create/Roblox-Projects/pull/26). [MAIN adapter #41](https://github.com/stephennip9288-create/Roblox-Projects/pull/41) supplies the optional kind/routine facts; Audio has not edited Controller, Config or the test runner.

## Source implementation

Only the audio block of `client/Effects.lua` changes. Its SHA256 is `5c6f649fd02fa9f788d15016669bea50874414f07c6b838c2059cd85216d862e`. Everything before the block and from `FX:part` onward is byte-identical to the frozen base. All other 60 runtime records are unchanged; the runtime inventory remains 61. Existing semantic callers, acknowledged Shot/reload timing, source/run tokens, cancellation, deduplication, VFX and combat authority are preserved.

- **Real recording banks:** legacy scalar/array IDs remain compatible. Optional `variants`, `near`, `far`, `indoor`, `outdoor` and bounded `gain` select recordings. Rotation is independent of unrelated UI, avoids immediate repeats and retains original recording speed. Human vocals or wood breaks cannot silently become hound breath/paws/death or gear foley.
- **Readiness:** two silent preload jobs maximum, a 32-item queue, and 32 ready Sounds (16 in Low Effects). Already-loaded samples skip another fetch. Cold cache is distinct from a failed permission/fetch. Actual failures or an eight-second watchdog receive 30-second backoff. Completion only caches a silent Sound; it never queues/replays an old game event. Epoch/reset/destroy cancels work and removes cache objects.
- **Weapons:** class/weapon/phase/material selection and independent mag-out/mag-in identity. When ready and within budget, separate near/distant recordings use an equal-power transition over 40–110 studs. Both count as native voices. Low Effects selects one recording. Sustained fire replaces older same-emitter tails (two report events normally, one in Low Effects) so long sample tails cannot suppress acknowledged onsets; final tails remain finite.
- **Threats:** real attack/entry events can replace routine infected sounds without taking the critical reserve. Global routine vocal cadence reduces synchronized groan clusters. Critical charge/ambush/explosive/Warden/extraction cues retain immediate, dry, unfiltered priority and the existing 8/6 reserved slots.
- **Acoustics:** existing bounded map polygons identify outdoors, small rooms, corridors and halls. Source classification is cached; listener classification refreshes only on zone change. Modest per-Sound reverb, smooth exterior/indoor bank changes and map-only occlusion (two rays per 200 ms; one in Low Effects) avoid global SoundService changes. This is a bounded approximation, not full sound propagation. Critical warnings bypass muffling.
- **World lifecycle:** map-specific physical anchors and visible-world event edges remain the trigger source. Loops vary their start positions and can crossfade indoor/outdoor recordings. Optional `interval`/`duration` makes structural texture intermittent instead of repeating every second.
- **Mix:** recording calibration is separate from stock levels. Master/category mute reaches both report layers and loops. Hard active native voice limits remain 20/12. Owned-FX aggregate volume is capped conservatively at 0.82 with critical voices allocated first. This is not a guarantee about total device output. Silent cache objects never Play; native decoder memory/FPS still require measurement.

The historical `audio-immersion/Effects-audio.luau` mirror is synchronized for the existing six patch-integrity tests; it is not another runtime script. New tests have distinct Batch 1.1 names. MAIN retains runner registration and serial integration.

## Recording and event inventory

[LISTEN.html](LISTEN.html) and its [Auditions](Auditions) folder provide **84 isolated OGG candidates**, not a capture of the Roblox mix. [RECORDINGS.json](RECORDINGS.json) gives every selected file, proposed slots, source member, exact WAV/OGG hashes, trim point, duration, gain, peak/RMS and false/null approval fields. [RECORDING-RECIPES.json](RECORDING-RECIPES.json) reproduces the edits. Source cuts, mono downmix, peak control and loop crossfades do not substitute a pitch effect for a real discharge or animal.

[SOURCES.json](SOURCES.json) pins **22 source downloads** by byte count/SHA256, creator credit, primary source page and declared CC0 license. Credits are retained. Source-declared CC0 permits the proposed reuse, but this inventory does not establish Roblox creator ownership, moderation or experience playback permissions. The ambiguous-provenance “Gunshots” pack and synthesized PureData wind were excluded.

| Family | Provenance and acceptance limit |
| --- | --- |
| Firearms | [Free Firearm Sound Library](https://opengameart.org/content/the-free-firearm-sound-library), Ben Jaszczak, Brian Nelson, Kevin Heras, Matthew Nanney. Separate recorded near and **mid-distance** positions; “far” names the distant mix role, not extreme-distance capture. Heavy uses a disclosed AK-47 automatic-rifle proxy; dedicated LMG acceptance/replacement remains open. |
| Mechanisms | [SpringySpringo](https://opengameart.org/content/gun-reload-sounds), recorded airsoft mechanisms; [Brian MacIntosh/BMacZero](https://opengameart.org/content/mechanical-sounds), mechanical foley. Exact phase cuts require listening with the actual animation. |
| Infected | [ianzazz](https://opengameart.org/content/zombie-noises-and-moans), original performed effects. Acting and attack/death suitability remain listening gates. |
| Hounds | [qubodup](https://opengameart.org/content/dog-snarl-grunt-grumble), [bonebrah](https://opengameart.org/content/dog-growl), [pauliuw](https://opengameart.org/content/dog-sounds), canine recordings. Barks are not described as howls. Older recordings have disclosed noise. |
| Impacts/steps | [Kenney Impact Sounds](https://kenney.nl/assets/impact-sounds), CC0 game foley candidates. Dedicated concrete/wood/snow banks; concrete is a disclosed generic boot fallback. Actual metal/paws are not claimed. |
| Cloth | [Iochi Glaucus](https://opengameart.org/content/fabric-rustling), AT2020 fabric recording cut into distinct movements; not authenticated military kit. |
| Machinery | rubberduck [pack 1](https://opengameart.org/content/100-cc0-sfx) and [pack 2](https://opengameart.org/content/100-cc0-sfx-2). Distinct machinery/air candidates; furnace equipment is not claimed to be recorded fire/steam. |
| Wind/radio | [Thimras](https://opengameart.org/content/park-ambiences), open-field winter wind; [Bashar3A](https://opengameart.org/content/mild-wind-background-noise), stronger wind with disclosed bags; [xhunterko](https://opengameart.org/content/static), designed untuned static. No third-party speech/music. Polar-storm identity is not yet accepted. |

[EVENT-INVENTORY.json](EVENT-INVENTORY.json) audits all **100 keys** with category, priority, range, cooldown/TTL, looping, configured status, fallback path/pitch and separate recording gain. With the current empty configuration, **73 have temporary stock fallback paths; 27 are silent until an appropriate recording is supplied**. This is a catalog audit, not a claim all 100 keys have callers.

| Currently audible stock fallback | Current use / status |
| --- | --- |
| `swordslash.wav`, `swordlunge.wav` | Legacy firearm reports with pitch/cut treatment. Functional placeholder, **not realistic gunfire**. |
| `uuhhh.mp3` | Legacy infected/hound/ambush/death. Human stock, **not a new canine recording**. |
| `impact_water.mp3` | Hit/board/entry/grenade/armor/vent. **Not realistic hard surfaces, explosions or armor**. |
| `unsheath.wav` | Mechanics/UI/special-event fallback. **Not the prepared mechanical/environment recording**. |
| `action_get_up.mp3` | Wave/revive/victory/event feedback. Temporary notification treatment. |
| `silent-until-upload` | Optional world/foley/hound banks. No fabricated loop or inappropriate borrowed recording. |

## Upload and activation blockers

All Roblox IDs are null and approvals false. The owning Roblox creator/group and available account quota are unknown; GitHub ownership does not identify the Roblox asset owner. Owner-selected samples need upload, moderation and verified usage access for **private staging universe `10771141095`**. No production permission or publication approval is inferred. The [Roblox audio requirements](https://create.roblox.com/docs/audio/assets) and [asset privacy documentation](https://create.roblox.com/docs/projects/assets/privacy) describe those separate steps.

Prepared upload WAVs are mono 48 kHz PCM16, at most ten seconds and under 1 MB each. Recreate them from repository root:

```bash
python games/dead-signal/dev/Reviews/audio-quality-b11/prepare_recordings.py --cache /absolute/audio-cache --output build/dead-signal-audio-b11 --fetch
```

This uses only pinned sources and needs numpy/scipy, ffmpeg/ffprobe and Linux libarchive. Decoder/encoder version changes may change derivative bytes; keep the recorded version or re-review changed outputs. Committed OGG files/hashes are the exact reviewed snapshot, not a bit-identity claim across encoders.

[UPLOAD-MAP.template.json](UPLOAD-MAP.template.json) deliberately has no usable IDs. After real owner evidence, `emit_bindings.py --uploads owner-records.json --output build/audio-bindings-review.lua` emits a MAIN Config proposal, rejecting unapproved, wrong-universe or wrong-WAV inputs. `--allow-partial` is only a Studio audition proposal: missing slots retain their existing fallback. The helper does not independently contact Roblox to verify attestations and never applies Config, uploads or publishes.

Remaining recording/acceptance gaps: dedicated LMG if the proxy is rejected; energy-weapon design; canine breath, true howl/Alpha identity and paws; convincing ice/structural cracking; metal boots; steam/emergency equipment; military communication performance if required. Mechanism phase cuts, infected acting, source noise/wildlife/bags, material mapping and initial gain calibration all need listening acceptance. Missing assets are not silently marked complete.

See [MAIN-INTEGRATION.md](MAIN-INTEGRATION.md), [VALIDATION.json](VALIDATION.json), and the [before/after listening checklist](LISTENING-CHECKLIST.md). DS-B1-001 cannot close until the activated, integrated system passes actual gameplay listening.
