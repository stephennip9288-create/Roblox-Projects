# Audio Batch 1.1 — MAIN integration

**DS-B1-001 remains Open.** Source/recording candidates are for review. No assets are uploaded or activated, no native permission/listening/FPS claim is made, and no staging/production publication is authorized.

Audio branch is `fix/dead-signal-batch1-1-audio`, base `206ae616a7de4fe8dd69b1c8019bae6ea8b6863d`, PR [#43](https://github.com/stephennip9288-create/Roblox-Projects/pull/43), target `integration/dead-signal-batch1-1`. Old Audio #26 is merged. Use the combined Maps → Enemies → Audio order; integrate matching MAIN adapter [#41](https://github.com/stephennip9288-create/Roblox-Projects/pull/41), pinned at `848ccc9259b7e0059b9238280bdb70f4912afdf0`. Do not mix this work with Batch 2 or describe it as a complete release-ready patch.

Only Effects' audio block, its guarded old review mirror, and audio-specific tests/docs/recording review files change. Config, Controller, all other 60 runtime records, VFX/telegraph methods, native files, original artwork/IDs, stores, workflows and release records remain untouched. `BASELINE-RUNTIME.json` and the frozen Effects fixture guard this boundary. There are still 61 runtime records.

Existing integrated callers already own server-acknowledged Shot/reload phases, deduplication, source/run IDs, map zones, entry transitions and cancellation. Preserve them. The scoped MAIN adapter forwards existing facts only:

1. Routine vocal context: `kind=kind,routine=true`.
2. NPC movement context: `kind=kind`, letting the existing `Zombie.Footstep` call route to `Hound.Footstep`. A real paw bank is required before accepting that refinement; human boot audio is not silently substituted.
3. Existing hound EnemyAttack: `Hound.Attack` instead of routine `Hound.Snarl`.
4. EnemyDeath: existing server `data.kind` forwarded, enabling independent canine death.

No new remote, server event, combat authority or profile field is requested. Hound breath/howl and material-aware world impacts are not invented trigger events. Supply suitable recordings and owner-approved real trigger paths before enabling them. Config activation remains MAIN-owned after creator upload/moderation/experience permission evidence; the review helper does not apply it.

Register `audio-quality-b11` in MAIN's Luau runner. Run the specialist Python tests explicitly; root discovery does not include them. The heavyweight PCM check deliberately skips during ordinary discovery unless `--wav-dir` is supplied; the reported specialist run supplies it and has no skip.

```bash
# games/dead-signal/dev
lune run Tests/syntax.luau
python Tests/run.py --lune /absolute/path/to/lune
lune run Tests/audio-quality-b11.luau
python Tests/test_audio_quality_b11.py --wav-dir ../../../build/dead-signal-audio-b11/WAV -v
python -m unittest discover -s Tests -p test_audio_patch.py -v
# repository root
python -m unittest discover -s tests -v
python scripts/validate.py
python scripts/generate_dead_signal_place_configs.py
```

The Python 60-record comparison is an isolated Audio-branch scope audit. Intentional Maps/Enemies changes in a combined checkout require commit-diff scope review against the frozen Audio base; do not alter other specialists' work to satisfy that comparison. The standalone specialist test command above applies before serial integration.

The new harness executes actual Effects with asynchronous preload and instance doubles: cold versus failed assets, no stale replay, watchdog/epoch teardown, 20/12 accounting including report pairs, 900 RPM sustained fire, source variation, phase cancellation, attack preemption, crowd cadence, cached room classification, bounded occlusion, world transitions/intermittence, mute and thirty repeat sessions. It also consumes #41's kind fact to ensure human/wood/boot banks cannot masquerade as canine or gear audio.

`VALIDATION.json` records exact hashes/counts and the test-only overlay of #41. Native warnings about unsupported Terrain metadata in Lune test deserialization are not ignored preservation evidence: the separate raw lossless patch/audit checks preserve all untouched binary chunks for all four places and both environment artifacts. Those local artifacts are not approved for deployment. MAIN must rerun the complete combined candidate and preserve the existing rollback/source-selection gates.

Studio/device dependencies: actual ContentProvider readiness/cancellation and denied permissions; network/animation-to-play timing; subjective near/far blending and reverb/occlusion; acting/noise/material fit; default character audio against the new banks; decoder/cache memory and FPS; physical mobile mono/headphone compatibility; complete before/after listening. Silent cache objects are bounded at 32/16 plus two pending probes, but engine cache lifetime and native performance are not proven offline.

Keep the complete candidate and DS-B1-001 open while any recording, upload, permission or gameplay listening gate is unresolved. No publishing workflow was dispatched by Audio.
