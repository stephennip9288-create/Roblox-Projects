# MAIN handoff — PR #54

DS-B1-001 source corrections are ready for review on `fix/dead-signal-b1-audio-corrections`, based on integration `c80d55aeeae4b51ef8d836949a33bf440890c6b7`. Retain Draft / unverified status until native evidence is attached. No merge or publication was performed.

## Dependencies and ownership

Depends on #43, owner uploaded-ID intake #48 and staging audition #49, already merged. Preserve their universe gate and approval flags. Incorporate through MAIN's combined integration sequence (#44); exclude Batch 2. Open #52 (Cinderworks window support) and #53 (window entry/R6 infected) are concurrent changes: recheck combined entry timing, threat cues and native listening after MAIN integrates them; do not overwrite their source or adopt their runtime blobs without review.

Only the existing Effects audio block changes at runtime. Config, Controller, server, other 60 runtime records, release workflows and native places are unchanged. Mirror and audio-owned tests are updated. MAIN owns runner registration: add `audio-corrections-b1` and run the new Python audit explicitly; `Tests/run.py` is unchanged here.

The historical Python quality audit now recognizes approved #49 Config and this guarded Effects change without rewriting MAIN's historical review lock. Both Python scope audits deliberately pin this source branch's other 60 runtime blobs. MAIN must review/reconcile those assertions when combining later approved specialist changes; do not silently regenerate baselines to bless unrelated edits. Retain the immutable prior Effects and prefix/VFX guards.

## Review points

- Reload begin silently prepares phase recordings; actual animation phases remain the onset facts. No outcome prediction or late-load event replay.
- Legacy equip/empty use their uploaded banks. Sword/water/unsheath physical fallbacks are removed. Missing physical clips skip with diagnostics.
- Contact and Land are independent. Current Board uses wood; future accepted `C.SoundIds["Board.Break"]` supplies fracture/debris at the existing confirmed break event. No Config edit is included.
- Mechanisms distinguish Cyclone automatic, Trench/Sable pump, Breaker break-action, Vigil cylinder/cartridge and energy cells. New bank names: `Weapon.BreakAction`, `Weapon.Cylinder`, `Weapon.Cartridge`; cells/charge also need recordings. Eleven actual reload stages remain intentional asset gaps.
- Fast shell stages use 0.045-second cooldown and 2/1 emitter tail bounds. Global limits, reserved warnings, distance mix and mute/cleanup remain.

Fourteen supplemental CC0 WAV/OGGs have pinned sources, recipes, headroom evidence and null IDs. They require sample review, owner upload, moderation and experience permissions before MAIN considers Board.Break/Contact Config additions. Cinder-block scrapes are disclosed material proxies. Keep separate Land clips. Standalone stress/debris needs a real event contract; use the one-voice composite for the existing break event where suitable. The old 84-name helper cannot import the new template. Record exact IDs/hashes and evidence; upload success alone must not set acceptance flags.

## Release provenance

Latest actual staging publication inspected: [39237971450](https://github.com/stephennip9288-create/Roblox-Projects/actions/runs/39237971450), source `409ae5118981ff5c9ba82802eb41c6a8326a4bc1`, Blackwater/Cinderworks/Whiteout/Dispatch versions **12/12/12/15**. Rollback artifact `12180281308`; deployment result `12180216574`. The older four-fix run and versions 12/11/11/11 are no longer the latest recovery point.

Before any separately authorized future release, MAIN should recheck live provenance and reconcile release/rollback controls with this successful audition deployment. The trusted gate selects the earlier audition, not this PR. This handoff changes no gate and authorizes no workflow dispatch, upload or publication.

Run [LISTENING-CHECKLIST.md](LISTENING-CHECKLIST.md) on the exact integrated SHA, all maps and supported devices. The optional Studio client capture is a bounded passive observer: it records existing cue/ID/owner/loaded state and can identify watery audio outside Effects. It never plays or approves a cue. Offline tests cannot establish Roblox decode timing, permissions, subjective quality or mobile FPS. DS-B1-001 remains Open until gameplay listening passes.
