# Batch 2 gameplay-only private-staging QA

Status: PREPARED, NOT EXECUTED. Do not mark a feature or defect Verified until its native checks pass. Record device, player count, map, source SHA/place version, steps, expected/observed behavior and evidence for every result.

| Area | Native checks | Required coverage |
| --- | --- | --- |
| Movement | Forward-only sprint; slower strafe/backpedal; diagonal direction changes; stamina/exhaustion; aiming/reload interactions; feedback and server correction | Desktop keyboard/mouse, controller, Android and iOS; solo, two and four players; normal and elevated latency |
| Pursuit | Survivor in adjacent room reached through actual openings; locked/unlocked doors; stairs, windows and chokepoints; target changes; obstruction and stuck recovery | Blackwater, Cinderworks, Whiteout; specifically Whiteout door 7; approximately forty mixed enemies and high-round congestion |
| Enemy regressions | Hounds, crawlers, elites and Warden; awareness targeting; changing floors; survivor death/revive; diagnostic output disabled outside Studio | Multiple player targets and repeated runs; mobile performance |
| Combat and game flow | Weapons/ammunition/upgrades; hit fairness; damage/revives; Warden and extraction; round transitions/results; lobby/map teleports | All four places; solo/two/four players; reconnect and repeat-session stability |
| Data | Existing progress loads; earned progress persists; no resets; correct profile namespace | Existing and fresh test accounts; `DeadSignal_Profile_v1` retained |
| Audio retained in this candidate | Existing Batch 1 banks, mute, Low Effects, volume/spatial behavior and cleanup remain functional | Headphones/speakers; desktop/mobile; repeated sessions |
| New Batch 2 audio exclusion | All sixteen newly mapped banks remain unavailable even when downloaded/preloaded; no unexpected music/creak/steam/impact/cry/breath/drag/stinger from those IDs | All four places; normal and intense combat, Warden/extraction, mute/Low Effects |

The sixteen new assets are deliberately excluded from acceptance in this candidate. Their working web previews do not establish engine playback. Per-map new score/atmosphere identity, new spatial events, loading/ContentProvider errors, transitions/crossfades, clipping and repeated-session audio cleanup need a later authorized full-audio candidate with complete asset evidence.

If a defect occurs, retain the current rollback. Do not reset player data, publish production, expand Batch 3, or mark earlier Batch 1 defects Verified without their separate native evidence.
