# Dead Signal — four-place integration acceptance record

Candidate/runtime snapshot: `5912113a55899501eac0997c88c8829c536ff959`; use the final review SHA and candidate hashes in the delivered manifest for each session. Runtime 1.9.0. Publishing is not authorized. This checklist separates verified offline gates from actual gameplay evidence.

## Offline gate already passed

- [x] All four complete staging places built through the retained native lossless patcher.
- [x] Separate staging-only PlaceConfigs; no production destination leakage.
- [x] Independent raw native/property preservation; original binaries/backups unchanged.
- [x] All 61 intended sources verified per place by raw checks and native reader.
- [x] 20 suites / 580,040 assertions, 61 runtime compilations, 93 source/test/tool syntax checks and 59 Python tests passed.
- [x] Three-map projected clearance and 30 door purchase states passed.
- [x] Original artwork IDs/visibility hotfix and production profile namespace retained.

## Studio setup — no publication required

Open the delivered **Dispatch** RBXL in Roblox Studio. Press Play and walk into a departure bay to use the existing local operation preview; Studio cannot establish real cross-place teleport acceptance. The map is rebuilt from source at run start, so the edit-time native preview alone does not show the remaster. Use the supplied map RBXLs for each map's standalone checks. Keep the staging-only configuration as delivered. Discard any temporary accelerated-round settings before final runs.

The actual-loading-screen preview is in `dev/Tools/preview-loading-art-studio.lua`: run it once in the **Client** Command Bar during Play from Dispatch, before starting an operation. Select all four screens. Close it before gameplay. The normal Studio local-round shortcut does not exercise a teleport loading screen.

For each observation record: final SHA/hash, date, tester, device/viewport, map, mode, crew size, round/event, expected result, actual result, server/client Output and clip/screenshot reference. A blank row is pending, not PASS.

| Place | Offline build/source/native gate | Actual Studio | Private Roblox client |
| --- | --- | --- | --- |
| Dispatch | PASS | Pending | Pending |
| Blackwater Station | PASS | Pending | Pending |
| Cinderworks | PASS | Pending | Pending |
| Whiteout Relay | PASS | Pending | Pending |

## Required whole-run matrix

Run **Survival (`Standard`) and Lockdown**, each with **1, 2 and 4 players**, on **Blackwater, Cinderworks and Whiteout**: 18 scenarios. Include Dispatch boarding, map arrival and return in each private-client scenario. Record each cell independently; one successful solo run does not accept the squad/mode matrix.

| Map | Survival 1 / 2 / 4 | Lockdown 1 / 2 / 4 |
| --- | --- | --- |
| Blackwater | Pending / Pending / Pending | Pending / Pending / Pending |
| Cinderworks | Pending / Pending / Pending | Pending / Pending / Pending |
| Whiteout | Pending / Pending / Pending | Pending / Pending / Pending |

## Functional and presentation checks

1. **Dispatch/loading/travel:** join an empty and occupied bay; leader start/cancel; all three destinations; correct original picture, stable opaque loading layer and complete removal after supported spawn; no duplicated HUD. Extract/lose/return/reboard, repeat travel and reconnect. Confirm all four destinations are staging before any authorized private test.
2. **Routes and purchases:** buy every one of the nine gates and both optional loops; test partially open routes and all closed gates. Inspect room identity, elevation and exit orientation. Pursue a moving survivor across every connector/ramp/gallery with ordinary zombie, crawler, hound, Alpha, Ironbound and Warden. No room-center congregation, obstacle pinning, backwards travel, repeated forced recovery or inaccessible survivor position.
3. **Placements and eligibility:** operate each wall buy/refill, perk, ammo panel, fuse, breaker, dial, transmitter, forge, radio, counter, trap and all six box positions. Approach from the intended side, the back of its wall and nearby locked room. Confirm reach, LOS policy, price, text fit, priority and no closed-sector shortcut. Repair/buy/revive prompts must not steal each other's hold; test ADS beside them and down/revive at every reserved bay.
4. **Enemy lifecycle:** retarget during melee/charge/ambush; down, disconnect, travel, respawn or replace the selected character. New targets receive fresh warnings. Test blocked charge/flank/entry, board tearing and blocked landing occupancy. Confirm fair recovery preserves exact HP, broken/damaged armor, reactor and cooldowns without rewards on retirement. Existing entry remains the parent implementation; Batch 1's animated traversal must be accepted separately when delivered.
5. **Specials/armor/hazards:** test all five events with full preparation; ordinary/combined rarity and quotas after crew changes; break head/body independently and hit exposed seams. Sidestep warnings. Chain more than eight explosive deaths with walls and terrain between targets; hazards remain capped, LOS/fuses fair, cleanup complete and ventilation/suppression independent. Check silhouettes/cues with Low Effects and without relying on color.
6. **Weapons/HUD/input:** inspect every weapon and upgrade; hip/ADS while moving at narrow/normal/ultrawide FOV/aspects, scope transition, mechanical/reload pose, empty slide, recoil and actual shot alignment. Test chat, Roblox menu, focus loss, same/missing-slot swap, rejected/server-acknowledged swaps, reload, revive and grenade. Fire must not remain latched; authoritative ammo/hits must agree. Display event/boss/extraction/downed/status/long-name text simultaneously; saved mirrored/custom controls remain intact.
7. **Collision/death:** crowd doors with players/NPCs; eliminate every kind/elite mid-attack on floors/ramps/galleries. Living bodies collide; ragdolls remain connected, do not pin survivors and clean up after the existing lifetime. Test downed crawl, revive reach and disconnected teammates.
8. **Warden/objectives/extraction/profiles:** complete breaker/fuses/code, Warden phases/overload, round milestones and contested extraction with a downed ally. Specials never override boss/exfil priority or block victory. Verify rewards once, credits/XP/upgrades/settings after leave/rejoin and no namespace/reset/migration loss. Staging must not operate on the production universe.
9. **Rendering/audio/performance:** capture actual first-person views for all three maps and signs in powered/unpowered/event light. Record server/client frame time, FPS, memory, build hitch, path failures and active effects at 40 NPCs/eight hazards/corpse load. Compare normal/Low Effects and the released baseline. Existing audio uses stock fallbacks; no bespoke Audio-lane delivery is accepted here. Physical two-thumb control comparison remains deferred.

Use `V1.9-STAGING-PLAYTEST.md` for disposable local special-event selection instructions, preserving advertised warning durations. Studio doubles and offline projections do not replace these tests.

## Publication prerequisites and owner acceptance

- [ ] Address Studio defects and record final evidence against unchanged candidate hashes.
- [ ] Resolve main-only staging checkout versus pre-main integration acceptance through a separately reviewed compatible source selector or explicit owner decision.
- [ ] Identify current staging recovery point and reconcile production rollback selection with the live v1.9 release; historical v1.7 files remain untouched.
- [ ] Obtain explicit owner authorization for the particular private staging source SHA.
- [ ] Use the existing controlled workflow; record returned four place versions/run and perform the complete private-client matrix above.
- [ ] Owner accepts staging results and all remaining limitations.
- [ ] Prepare final reviewed game PR to main; obtain separate explicit production authorization.
- [ ] Existing manual production workflow uses production-only configs, the reviewed recovery set and accepted immutable source; record uploads and public smoke checks.

Owner Studio acceptance: **Pending**. Owner private-staging acceptance: **Pending**. Production recommendation: **Do not promote yet**.
