# Batch 1 audio corrections — DS-B1-001

PR #54 corrects event routing and inappropriate physical fallbacks responsible for the reported sword reload and watery barricade/window sounds. Source implementation is complete; gameplay quality acceptance is pending. This package does not claim the final realism target has been achieved.

## Audited baseline and scope

Branch `fix/dead-signal-b1-audio-corrections` targets `integration/dead-signal-batch1-1` at `c80d55aeeae4b51ef8d836949a33bf440890c6b7`. Prior audio #43, owner upload intake #48 and audition #49 are merged there. Combined integration PR #44 remains open.

The latest successful staging publication inspected is [run 39237971450](https://github.com/stephennip9288-create/Roblox-Projects/actions/runs/39237971450), October 19, 2026, selected source `409ae5118981ff5c9ba82802eb41c6a8326a4bc1`. Blackwater/Cinderworks/Whiteout/Dispatch versions are **12/12/12/15**. Publication success establishes the listening baseline, not sound suitability or permission acceptance.

Runtime scope is the existing audio block in `client/Effects.lua`. All other 60 runtime records, the pre-audio prefix and VFX suffix remain byte-identical to the branch point. The historical audio mirror is synchronized. Config, Controller, server, release workflows and native places are unchanged.

## Corrected behavior

| Trigger | Previous behavior | Corrected behavior |
| --- | --- | --- |
| Server-acknowledged Reload / begin | Legacy unsheath could play before animation phases | Silent bounded preparation; actual animation phases own audible onsets |
| Legacy Equip / Empty | Missed uploaded Weapon banks | Uses staged equip/dry-mechanical bank |
| Magazine/bolt/pump/feed/cell/shell | Generic reload/equip stock could substitute | Strict phase/mechanism banks; unavailable physical clips skip with diagnostics |
| Automatic/break-action/revolver | Category alone could select pump, bolt or shotgun shell | Existing model/reload style selects the mechanism; optional new BreakAction, Cylinder and Cartridge banks |
| Barricade damage/break | Missing/cold recordings could become water | Existing wood Board bank; optional Board.Break for confirmed break; no water |
| Window contact/landing | Shared Board alias and water substitute | Independent Contact and Land banks |
| Fast shell insertion | Cooldown/tails could suppress valid stages | 0.045-second admission and bounded emitter tails, preserving global/category limits |

No effective catalog entry plays sword slash/lunge, unsheath or impact-water stock. Missing physical recordings are quiet with `asset`/`loading` diagnostics and missing/unready counters. Critical attention/notification cues retain a disclosed generic `action_get_up.mp3` fallback. Remaining legacy human infected/player/confirmation cues may retain `uuhhh.mp3`; they are not approved final realism assets. Canine cues do not borrow human vocal stock.

Spatial mix, settings, rolloff, near/far reports, acoustics, occlusion, critical reserve, crowd cadence and cleanup remain. Default/Low native voice caps are 20/12 with 8/6 reserved critical slots. Preload work stays bounded to two jobs, queue 32 and cache 32/16. Urgent mechanical requests move queued work forward without cancelling in-flight loads or replaying missed game events. Server authority and reload cancellation are unchanged.

## Inventory and asset status

[EVENT-ASSET-AUDIT.json](EVENT-ASSET-AUDIT.json) executes the actual Config, Effects and WeaponModels. It contains 14 explicit caller/phase examples with exact uploaded IDs and recording names, all **94 reload stages across 20 weapons**, and the **103-entry** effective root catalog for staging and production. Eleven reload stages intentionally report missing mechanism assets.

The unchanged staging Config has 52 bank definitions / 108 assignment uses. Forty catalog root keys have direct staged banks; 67 catalog entries have silent physical fallbacks. These are different measures: phase-specific child banks do not count as directly configured root keys. Original 84-recording upload inventory and audition OGG hashes are preserved. Upload/sharing does not establish native permission or listening acceptance; all existing acceptance flags remain false. Production does not receive staging-only banks.

| New review candidates | Count | Intended use / limitation |
| --- | ---: | --- |
| wood_break | 2 | Dry fracture for confirmed Board.Break |
| wood_stress | 3 | Stress components; a separate cue requires a real event fact |
| wood_debris | 2 | Debris components; no predicted/per-frame event introduced |
| frame_scrape | 3 | Cinder-block scrape recordings; material proxy requiring acceptance |
| board_fracture | 2 | Wood strike + fracture + debris composites using one runtime voice |
| window_contact | 2 | Wood contact + short rough scrape; separate landing retained |

All 14 are mono 48 kHz PCM16 WAV plus OGG, with no pitch/speed manipulation. WAV total: 572,812 bytes; OGG total: 114,514 bytes. Zero clipped PCM samples; highest measured 4x oversampled peak: -5.3871 dBFS. These establish headroom, not perceptual quality.

[SUPPLEMENTAL-SOURCES.json](SUPPLEMENTAL-SOURCES.json) pins two new source archives and existing Kenney contact provenance. Creators declare CC0: rubberduck's [wood/metal collection](https://opengameart.org/content/100-cc0-metal-and-wood-sfx), AntumDeluge's [Scrapes](https://opengameart.org/content/scrapes), and [Kenney Impact Sounds](https://kenney.nl/assets/impact-sounds). CC0 does not grant Roblox experience permissions. The scrape source describes objects dragged across a cinder block; these are not represented as verified window-frame captures.

Open [LISTEN.html](LISTEN.html) locally for OGG playback and WAV links. [SUPPLEMENTAL-RECORDINGS.json](SUPPLEMENTAL-RECORDINGS.json) records ingredients, hashes, measurements and unset approvals. [SUPPLEMENTAL-UPLOAD.template.json](SUPPLEMENTAL-UPLOAD.template.json) has null IDs and false acceptance/activation flags. None is bound in Config, uploaded or activated.

Obtain suitable break-action open/close, revolver cylinder open/close and cartridge insertion, and energy cell/charge recordings. Do not assign door latches, generic reloads or shotgun shells to these gaps. Dedicated LMG report acceptance, energy discharge, canine breathing/howl/paws and remaining realism items from the earlier package still need review. Existing suitable magazine/bolt/pump/shell/wood/contact/landing banks remain usable in staging.

After owner review/upload/moderation/staging permission and listening acceptance, MAIN reviews Config additions. The old 84-name `emit_bindings.py` is not a supported importer for this supplement. Standalone stress/debris hooks need MAIN event coordination; single-voice fracture composites require no extra event.

## Validation and reproduction

[VALIDATION.json](VALIDATION.json) records results and limitations. The existing 33-suite runner passed and reports 1,026,490 parsed assertions; the separate correction suite passed 2,121. The map Batch 1.1 suite additionally prints 26,386 checks with zero failures, outside that old parser's assertion total. Mirror, staging guards, original OGG hashes, supplemental PCM checks and reproduction passed.

From `games/dead-signal/dev`:

```sh
python Tests/run.py --lune /path/to/lune
/path/to/lune run Tests/audio-corrections-b1.luau
python Tests/test_audio_patch.py -v
python Tests/test_audio_quality_b11.py -v
python Tests/test_audio_corrections_b1.py --source-cache /path/to/pinned-archives -v
python Reviews/audio-corrections-b1/prepare_supplemental.py --cache /path/to/pinned-archives --output /path/to/review-output --fetch
```

Preparation requires NumPy, SciPy and ffmpeg. `--fetch` downloads only pinned public archives; it never uploads or edits Config. All 14 WAVs reproduced bit-for-bit in this environment. OGG encoder/serial output can vary; committed hashes identify this snapshot. The older quality test skips optional original WAV measurements when their external directory is absent; original committed OGGs are still hash-checked.

Actual engine timing, permissions, material fit, dense-wave threat readability, mobile performance and native repeated-session cleanup remain pending. Use [LISTENING-CHECKLIST.md](LISTENING-CHECKLIST.md). Keep DS-B1-001 Open until integrated gameplay listening passes. Further publication requires explicit user authorization.
