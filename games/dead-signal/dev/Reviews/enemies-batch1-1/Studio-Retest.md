# Native gameplay retest — not yet performed

No Roblox Studio, private-client gameplay, multiplayer replication or physical-phone result is asserted by this branch. MAIN/owner should use a locally built, losslessly patched combined candidate with the exact Maps and Enemies commits recorded. Opening and testing a local candidate does not authorize publishing it.

## Entry verification

| Map | Required coverage |
|---|---|
| Blackwater / Station | All ten designated windows, initial and purchased sectors; communications personnel, all seven enemy/variant profiles. |
| Cinderworks / Foundry | All ten windows, including window 10 / Crucible Lab after MAP DEV repairs its reported landing support. Verify the actual landing floor before climbing tests. |
| Whiteout / Frost | All ten windows, winter personnel, angled openings and evolved Alpha/Warden clearances. |

For each map, repeatedly observe single arrivals and mixed 4/12/24/40-unit waves converging on one entrance, with the normal wave/director rules active. Repeat in solo and local 2-/4-player Studio sessions. Record actual completion counts, queued/pending counts, max anchored duration, retries, stuck actors, collisions and capture timestamps. Pending units count toward the wave and are separate from live models; they must become visible only in supported, unoccupied exterior slots.

Exercise approach, alignment, brace/contact, crossing, release/landing and pursuit. Watch full meshes, tactical gear, paws and live collider against jambs/header/sill/floors. Require natural visible movement, no interior spawn, no visible recovery relocation and no dead actor left in an entry reservation. Kill the active climber, repair boards during crossing, close a route, temporarily block the opening and then remove the blocker; verify cancellation/reverse or bounded physical handoff and normal re-entry afterward.

Put a downed player on the central landing, move an alive player across it, change/disconnect/teleport the pursued target, and force several enemies onto the same queue. Confirm alternate landing does not sweep through the downed body and enemies resume authoritative chasing/attacking after entry. With all exterior candidates obstructed, require bounded admission work, a retained quota, no unsafe spawn and an explicit unresolved-navigation report; do not approve release while an unreachable unit can stall a wave. Remove the obstruction and confirm fair admission resumes.

Inspect attributes such as `NavigationState`, `TraversalStage`, `TraversalDirection`, `EntryCue` and `ColliderRootBound`; observe the actual server root and clients together. A navigation timeout must release scripted anchoring and preserve live collision/server ownership. Repeated failure must not heal a unit, remove it from the wave, duplicate rewards, reset broken armor or bypass the entrance animation. Root/model destruction must retain the unit's identity, damaged state, Warden phase and quota through exterior readmission.

## Appearance and preservation

Capture matched before/after clips and close/medium gameplay views for all six humanoid families on every map, the Crawler, Runner, Stalker, Warden, Hound/Alpha and combined elites. Include shambling/running, attacks, climbing forward/reverse, hit reactions and deaths. Review facial appearance, infected skin and cloth/material detail using the native meshes and textures; a bounds projection is insufficient. Review authored-art dependencies in [Asset-Requirements.md](Asset-Requirements.md).

Verify head/body hits and server damage, armor break/exposed weak points, reactor detonation warnings, hound pack/charge behavior, high-round scaling and cap40, special wave cadence, pending/admitted/defeated Warden, extraction/revive, reset/death/corpse cleanup and client cue timing. Measure frame time/network/instance count during large waves with low effects and mobile emulation, then on the target physical phone when available. Record disagreements between server and client pose/collision.

## Signoff record

Provide exact source and built-artifact hashes, tester/date, Studio/client versions, crew/device, per-window outcomes and real screenshots/clips. MAIN owns tracker status and integration decisions. Both DS-B1-002 and DS-B1-006 remain **not Verified** until implementation plus real gameplay retesting satisfies the owner. No staging or production publication is authorized by this checklist.
