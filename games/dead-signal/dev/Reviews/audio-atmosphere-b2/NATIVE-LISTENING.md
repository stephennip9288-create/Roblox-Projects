# Native audition and mobile acceptance — pending

No item below has passed in Roblox Studio or a native Roblox client during this development. Offline tests and codec inspection do not substitute for listening. Batch 1 is already owner-accepted; compare its accepted build to a later authorized integrated Batch 2 candidate at the same device/master level. Record candidate SHA, universe, map, device/OS, headphones or speaker, quality mode, player count and clip/time for each result. MAIN obtains publication authorization separately.

| Scenario | Before / after listening check | Pass criterion | Status |
| --- | --- | --- | --- |
| Blackwater | Power, radio, exterior wind, distant metal/cry and calm/pressure music; walk every room and corridor. | Recognizable military horror identity, plausible source directions and natural room changes; no false nearby threat. | Pending new assets and native audition |
| Cinderworks | Machinery/furnace/vent beds, new steam/steel events and industrial music. | Distinct heavy industry; no drowning of reloads, attacks or communications. | Pending new assets and native audition |
| Whiteout | Exterior storm, indoor relay/structure, distant muffled cries and sparse music. | Lonely cold character; enter/leave rooms without abrupt level or phase jumps. | Pending new assets and native audition |
| Dispatch | Return from each map and remain in HQ for five minutes. | Calm room/score, no scare scheduler, stale attacks or surviving run loops. | Pending music and native audition |
| Phase transitions | Exploration → wave → intermission; special warning; Warden phases; extraction; downed/revive; eliminated; Results. Trigger rapid repeated state updates. | Smooth latest-state transitions; no duplicate warning, score pile-up or stale enemy foley. Low fades through one score voice acceptably. | Pending |
| Infected movement | Idle/jitter, approach from front/back/side, varied surfaces, crawler and hound, entry/attack/armor/death. | Physical movement sounds match visible contacts and family. No watery/sword substitutions or repeated chorus; entry/attack timing stays correct. | Pending breath/drag and native audition |
| Real detection | Integrate ENEMY #71; lose/reacquire LOS, switch targets, use one/two/four clients; test stale/out-of-run facts. | Exactly one appropriate reaction at real acquisition; no proximity guess or duplicate Feed sound. | Pending integration |
| Crowded wave | 4, 12, 24 and 40 enemies with one/two/four players firing/reloading and using critical warnings. | Threat direction and attack timing remain readable. Reload/communications audible; peak comfortable; quiet opportunities recover. | Pending |
| Critical pressure | Charge, Stalker, volatile fuse, Alpha, Warden and extraction during sustained fire/ambience/music. | Warning audibility survives voice contention and ducking; no delayed backlogged scares. | Pending |
| Near/far and rooms | Walk through 8/38/65/70/115/175-stud distances and cross room/corridor/hall/exterior boundaries. | Existing gun near/far behavior preserved, distant events sound distant, rolloff and indoor/outdoor changes remain smooth. | Pending |
| Loading/permissions | Cold cache, denied new score, partial grants, slow download and reconnection. | Accepted beds keep working; existing score held during a cold transition; no wrong stock substitute, stale replay or unbounded requests. | Pending |
| Mute/settings | Master 0/25/65/100%, mute during reload/warning/music, switch Low/Normal, unmute after a minute. | All owned and character sounds follow controls, score loops release, no catch-up scare burst, critical slots preserved. | Pending |
| Codec/music seams | Listen to every uploaded loop for at least five complete wraps and every crossfade on headphones and mono speaker. | No clicks, loud codec overshoot, sudden start, rumble-only inaudibility, masking or distracting repetition. Reject/revise candidates if needed. | Pending owner/uploaded audition |
| Repeat sessions | Ten HQ → map → Results → HQ cycles, death/revive, character replacement and rejoin. | Audio objects/connections/cache stabilize; no carried score/actor audio, monotonic leak or growing preload queue. | Pending |

## Real-device measurement

Measure a lower-end Android phone and an iPhone, both mono speaker and headphones, with Normal and Low Effects. Use desktop as the comparison. For the same seeded 40-enemy wave, capture at least 60 seconds after warmup and a separate cold-load trace: frame time p50/p95/max, client Lua time, audio CPU/decode cost where exposed, memory before/after ten sessions, active native voices, preload jobs/queue, device volume and thermal state. Record network/player conditions. Compare accepted Batch 1 against integrated Batch 2 with new assets both enabled and disabled.

The offline adapter benchmark covers 40 tracked actors over 250 ticks / 25 virtual seconds per quality mode with fake replicated objects; it excludes Roblox API/replication, native audio mixing, decoding, device scheduling, network and GPU. Its results are not mobile FPS, a real-time guarantee or gameplay acceptance. Native profiling must check that the 20/12 mixer voice ceilings, two load jobs and cache/queue bounds hold during actual play.

Keep B2 audio and any unverified audio-quality issue open until the integrated candidate passes owner gameplay listening. A source test passing or a permission grant alone does not meet that acceptance criterion.
