# Batch 2 audio — B2-02, B2-05, B2-07

Source implementation is ready for MAIN review in [PR #70](https://github.com/stephennip9288-create/Roblox-Projects/pull/70). It targets `integration/dead-signal-batch2` from owner checkpoint `7aaf323de6153134df2154c7ae3b1613a596495b`. Keep the PR open for integration. No publication or native listening acceptance is recorded here.

The existing mixer now supports map-specific horror events with intentional pauses, calm Dispatch, bounded dynamic music transitions and movement-aware infected presence. All accepted Batch 1 banks, uploaded recordings and permission evidence remain intact. The known eleven specialized reload-stage gaps remain outside this expansion.

## Implemented behavior

| Feature | Source behavior | Asset readiness |
| --- | --- | --- |
| B2-02 map identity | Existing Station power/radio/wind, Foundry machinery/furnace/vent, Frost wind/relay/structure and Dispatch room beds continue. Distant event pools use authored landmark positions; no random close threat locations. | Existing approved recordings function immediately. New physical categories below are silent until reviewed. |
| Controlled scares | First opportunity after 30–65 seconds; subsequent opportunities 35–70 seconds Normal or 52.5–105 seconds Low. No consecutive identical key, alternating authored positions where available, one atmospheric voice. Scares pause for foreground audio, warnings, high pressure and end states. | Five suitable atmospheric aliases reuse accepted banks. A musical stinger is included for audition; metal, steam, impact and distant cry clips still need recording. |
| B2-05 score | Calm/pressure identities for each survival map, calm Dispatch, Warden and extraction overrides. Exploration, waves, intermissions, special warnings, death and Results select appropriate states. Smooth gain transitions; Normal crossfades at most two score voices, Low fades through one. Cold/denied incoming music retains a working score. | Nine original music loops plus one rare stinger are supplied as audition candidates. No new IDs are installed. |
| Foreground readability | Reload/mechanics, gunfire and communications duck score/atmosphere. Critical warning priority, reserved voices and the existing peak ceiling remain. | Automated policy checks pass; gameplay mix acceptance is pending. |
| B2-07 infected | Actual grounded travel and surface choose existing footsteps; idle jitter and teleports cannot create steps. Clothing cadence is bounded. Crawlers select a dedicated drag slot. Optional nearby breath alternates with approved groans once available. | Accepted footsteps/gear/groans/hound recordings retained. Breath and drag need suitable new recordings. |
| Detection reaction | Fresh server `AwarenessTargetUserId` / `AwarenessRunId` / `AwarenessAt` facts supply one optional acquisition cue; canine reactions use canine banks. No proximity-invented detection. | Agreed ENEMY #71 dependency; no second Feed audio handler. |

## Limits and lifecycle

Native voice limits remain 20 Normal / 12 Low, with 8 / 6 reserved for critical cues. Score uses at most 2 / 1 and distant atmosphere at most 1. Preload stays at two jobs, a 32-item queue, 32 / 16 cached probes and an eight-second timeout. Existing rolloff, near/far reports, material banks, room acoustics, occlusion approximation, master volume/mute and character sound mixing remain.

Atmospheric placement requires an authored anchor 64–175 studs away (80–175 Low); absent anchors cause silence. Stingers are optional candidates with an 8% eligibility roll and at least 180 seconds between successful plays; they are not guaranteed at an interval. Scare opportunities are skipped rather than queued. Map/run/character replacement, loading, Results, death, mute and teardown have regression coverage.

## Assets and evidence

- [MANIFEST.json](MANIFEST.json): all 22 added event slots, reused banks, upload gaps, review gates and lane dependencies.
- [EVENT-INVENTORY.json](EVENT-INVENTORY.json): 125 actual-source event definitions/default banks for staging and production. Phase/material/weapon variants remain in unchanged Config and existing Batch 1 manifests.
- [MUSIC-RECORDINGS.json](MUSIC-RECORDINGS.json), [Audio](Audio): ten original synthesized musical compositions; these are not physical recordings or owner-approved final music. WAV masters are in the owner ZIP and reproducible with `prepare_music.py`.
- [UPLOAD-INSTRUCTIONS.md](UPLOAD-INSTRUCTIONS.md), [UPLOAD-RETURN.csv](UPLOAD-RETURN.csv), [RECORDING-REQUESTS.csv](RECORDING-REQUESTS.csv), [LISTEN.html](LISTEN.html): owner review and upload package.
- [VERIFICATION.json](VERIFICATION.json), [CODEC-QA.json](CODEC-QA.json): automated source/build/codec evidence, with native results explicitly pending.
- [NATIVE-LISTENING.md](NATIVE-LISTENING.md): before/after gameplay, mobile and crowded-wave pass criteria.
- [MAIN-INTEGRATION.md](MAIN-INTEGRATION.md): exact owned boundaries, attribute ordering and combined provenance obligations.

The six unavailable physical categories are `Atmosphere.Station.Creak`, `Atmosphere.Foundry.Steam`, `Atmosphere.Foundry.Impact`, `Atmosphere.Cry`, `Zombie.Breath` and `Zombie.Drag`. Existing suitable beds and groans continue as fallbacks; missing physical recordings are never replaced by unrelated stock effects. All sixteen new asset slots require explicit creator/rights/listening/moderation approval and the exact experience permission before they can play.

Offline tests establish timing, budgets and cleanup policy, not perceived quality or Roblox/mobile performance. MAIN must integrate the lanes, obtain new asset acceptance and run the native checklist before claiming the Batch 2 atmosphere or music has passed. No staging or production publish was performed.
