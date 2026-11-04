# DS-B1-001 — before/after listening acceptance

**All native rows are Pending.** Compare staged source `9743b3e9ee59ba74da0d5d9a5e3f2e378230d6f7` with the exact reviewed combined Batch 1.1 build after accepted assets are activated. A source-only build with empty IDs is not the accepted “after” audio build. Isolated OGG auditions are sample review, not game listening evidence.

Record source SHA, asset-map hash, creator/universe permission evidence, map/room/window, device/OS, speaker/headphones, crew, mode, round, weapon and settings. Capture matched before/after paths at the same volume and enemy density. Record failures explicitly; do not infer a whole-map pass from one location.

| Check | Required after behavior | Result |
| --- | --- | --- |
| Weapon categories | Appropriate pistol/SMG/rifle/shotgun/LMG/sniper/energy identity; no stock sword pop accepted as a real report | Pending |
| Sustained fire | Full magazines at highest RPM: timely acknowledged onsets, no tail-induced missing shots, clipped stutter, click or delayed replay; final tails end naturally | Pending |
| Actions/reload | Equip, empty, magazine, bolt/pump, shell, cell/feed match accepted animation phases; swap/cancel/death stops old foley | Pending |
| Near/far | Same shooter at 5/40/75/110/170 studs and moving listener: plausible timbre, no hard switch, phasey duplicate or unintended extra shot; Low Effects compromise accepted | Pending |
| Enclosures | Every map: exterior, corridor, room and hall transition smoothly; decay/muffling plausible; critical warnings remain clear | Pending |
| Impacts/hits | Miss/body/head/kill/armor/wood/metal/ground: feedback only from actual confirmation; restrained balance, no water sound accepted as armor/explosion | Pending |
| Infected density | 1/10/40 enemies: no synchronized choir or identical loops; approximate direction and urgency readable with eyes closed | Pending |
| Hounds | Distinct credible breath/snarl/bark/howl/Alpha/attack/charge/death/paws; missing samples block acceptance; no pitched human replacement | Pending |
| Window lifecycle | Representative windows after Maps/Enemies merge: approach/contact/land at actual transitions once, distinct contact/landing, no stale cancelled/re-entry voice | Pending |
| Blackwater | Military communications/power/wind identity, no unlicensed speech/music; distant cue agrees with visible landmark | Pending |
| Cinderworks | Machinery, ventilation, furnace equipment, steam/metal identity without overwhelming drones | Pending |
| Whiteout | Harsh cold exterior and quieter facility; no inappropriate bags/wildlife/noise; convincing ice/structure | Pending |
| Threat mix | 40 NPCs, four shooters, special event and Warden/extraction: warnings and direction readable without escalating loudness; routine layers yield | Pending |
| Mute/volume | Both report layers, loops and default character group obey master/category controls; no new muted cue or replay burst on unmute/travel/respawn | Pending |
| Physical mobile | Android/iOS mono speakers and headphones, dense route: 12 active voices, one report layer; stable decode/memory/FPS and accepted mix | Pending |
| Repeat sessions | Thirty wave/map/respawn/results/travel cycles plus leave/rejoin: no retained anchors, loops, callback or stale preload; counts settle after exit | Pending |

Studio diagnostics: `fx:audioDiagnostics()` reports active voices, queued/pending/cache counts, epoch, fallback/custom counts and owned-FX peak budget. `fx:audioInventory()` reports cue/fallback configuration. Neither verifies licensing, native audibility or device performance. No remote is added.

The offline 35 ms check concerns **leading silence in prepared PCM files**, not Roblox network/decode/output-driver/animation latency. Observe actual accepted Shot/reload markers against playback under cold/denied assets and multiplayer delay.

MAIN reviews Maps → Enemies → Audio plus the adapter and registers all suites. Any new private staging publication needs explicit owner authorization. DS-B1-001 stays Open until actual integrated gameplay listening and owner evidence support verification; no source test or audition closes it.
