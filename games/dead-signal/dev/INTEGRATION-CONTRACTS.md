# Dead Signal integration contracts — 2026-10-16

Owner: MAIN DEV / integration lead. Base audited: main `5e7cc679448e4a2c0b4db084fbba522e0c7167a5`; released runtime: `1a5b9f3b811137b6881090ad634a13624d33dd71`. The intervening main changes are Batch 1 handoff documents only. These decisions authorize development within the listed boundaries, not publication or asset uploads.

## Parent PRs and serial ownership

Integrate the reviewed parent PRs before assessing Batch 1 completion: #18 loading preview (`6ca195b`), #21 maps (`6311ea3`), #19 enemies (`7d5f23f`), #20 combat/UI (`5336149`). Preserve their exact changes; combine the test runner additively. New Batch 1 branches depend on their parent and target integration once that parent is integrated. No worker may force-update another lane or its parent PR.

| File/interface | Decision and current owner |
| --- | --- |
| Config, Game, Combat, Interactions, NavigationGraph, Presentation, LoadingScreen, PlaceConfig | Integrator retains ownership. Existing signatures, payloads, economy, profile and four-place IDs are frozen. Propose additive changes in the specialist PR before integration. |
| MapBuilder/Architecture/MapLayouts and generated geometry | Maps owns subsequent changes. Preserve the contracts below; integrator may make a documented integration repair serially. |
| Enemies/Navigation/DirectorRules and rigs/poses | Enemies owns subsequent changes. No map-coordinate edits. |
| Controller/UI/weapon presentation/touch layout | Combat/UI owns subsequent changes. No server damage, map-placement or saved-control changes. |
| Effects sound implementation | **Audio receives exclusive scoped ownership for its first Batch 1 PR**, from this record until that PR is integrated/withdrawn or the integrator explicitly reallocates it. Allowed: sound tables, voice scheduling/mixing, spatial anchors, audio initialization/reset and audio tests. Existing particle, telegraph, hazard, animation and shake implementations remain integrator-owned. Combat/UI must not edit this file concurrently. |
| Tests/run.py | Integrator combines all suite registrations; specialists use distinct test filenames. |
| Native assets/builders/deployment workflows | Integrator only. Current delivery remains 61 existing runtime script records with lossless Source replacement. No native asset change is approved by this record. |

## Maps → enemies and interactions

All runtime coordinates are physical world studs after `map.scale`; layout authoring coordinates are unscaled. Do not scale twice. Preserve six room IDs, the first seven purchase links/prices, all nine door slots, ten breach windows, four crew spawns and existing objective associations. `Layouts.links(mapId)` selects optional loop endpoints; consumers must use the built `map.doors`, not assume all sites have Blackwater's links.

`map.rooms` retains center, unlocked, polygon and optional stairBase/stairTop/upperCenter/rise. `map.doors` retains a/b/open/part/cost/position and four ordered world-space waypoints. `NavigationGraph` uses these actual doors. Purchase changes increment `map.navigationRevision`; enemies invalidate old paths. Native paths pursue the live target; graph nodes are recovery hints and must not create room-center detours. Floors, ramps and reachable galleries belong in `map.floorParts`; roofs, dressing and exterior scenery do not.

Existing windows retain room/part/boards/count/inside/outside/nextTear and optional nextEntry. Batch 1 may add an **optional** `window.entry` descriptor, without deleting those fields:

| Field | Contract |
| --- | --- |
| schema/id/kind/room | `1`, stable map-local string, `Window` initially, existing room ID. Vents/tunnels require a reviewed kind-specific traversal before spawning from them. |
| approach/breach/landing | World-space CFrames, forward axis -Z points in the direction of travel. Approach is outside playable rooms; landing is supported interior floor, not a gallery projection onto ground. |
| clearance | `{radius, height}` in physical studs. Must accommodate the actual agent attributes, including Alpha/Ironbound/Warden where eligible. |
| allowedKinds | Explicit list. An omitted list retains existing eligibility; no new entrance may silently admit an oversized agent. |

Maps supplies geometry/anchors and conservative clearance evidence. Enemies owns approach → contact → traverse → landing → pursuit timing, occupancy checks, collision handoff, cancellation and bounded retries. A missing/blocked descriptor uses the existing safe entry/recovery path until the complete new traversal is integrated. No instant room spawn may be presented as implemented animated entry. Keep 12 path requests/second, three concurrent requests, 40 live NPCs and eight hazards unless a separately measured change is reviewed.

Wall buys and machines must preserve front clearance, standing/revive approaches, non-queryable decorative gun parts, eye-height signage and normal reach. `allowWall` and prompt eligibility are unchanged in the parent integration. Test the back side of walls/closed gates before staging acceptance; any policy correction is an integrator-owned change with a behavioral regression test.

## Sound contracts across all four lanes

Preserve `FX:sound(key, position)` and every existing key/caller. Audio may add an optional third context argument or a compatible `FX:audioEvent(key, context)` adapter. Context fields are optional: `position` (Vector3), `map` (existing map ID), `room` (sector ID), `sourceId`, `runId`, `eventId`, `phase`, `weaponId`, `enemyKind`, `variant`, `duration`, `serverTime`. These are presentation facts, never client authority to damage, reward, spawn or change timing. Validate finite positions/durations and bounded strings. Unknown/missing keys fail quietly without a loop or retry storm.

| Semantic event family | Trigger owner and timing |
| --- | --- |
| World.Zone / World.Ambient / World.Landmark | Maps supplies optional zone/landmark metadata, indoor/outdoor identity, position and visual-event timing. Audio resolves listener transition/crossfade; no new polling remote. |
| Enemy.Entry.Approach / Contact / Land | Enemies emits once at the actual traversal state transition; cancellation terminates the source lifecycle. No contact sound for an abandoned traversal. |
| Enemy.Charge.Warn / Enemy.Ambush.Warn / Enemy.Blast.Warn | Existing authoritative warning events and their full advertised durations. Never reschedule attacks to match sound and never duplicate an existing warning through a second hook. |
| Enemy.Alpha / Enemy.Armor.Break / Enemy.Death | Enemy/Combat server facts through existing feeds. Armor/death cues are one-shot and follow actual confirmed changes. |
| Weapon.Report / Weapon.Mechanism / Weapon.Reload / Weapon.Equip | Combat/UI owns presentation hooks and cancellation. Local mechanics are cosmetic; remote reports use existing shot confirmation. Include weapon category and phase, not client-invented hits. |
| Combat.Hit / Combat.Kill | Existing server-confirmed Hit payload only. No predicted damage-confirmation cue. |
| Wave.Prepare / Wave.Start / Warden.Warn / Extraction.Warn | Existing Game/Effects feed paths; priority information remains audible and visible with Low Effects. |

Initial mix budget ceiling: 20 active voices normally, 12 with Low Effects, with capacity for four critical warning voices within those limits. Evict/duck low-priority ambience before critical warnings; deduplicate per source/event and bound cooldowns. Preserve `settings.volume`, including zero. Stop loops, queued mechanics, delayed callbacks and spatial anchors on source removal, map/run changes and shutdown; tokens must prevent prior-run playback. The Audio PR must demonstrate caps and cleanup offline, then undergo engine listening/performance acceptance.

Use existing `C.SoundIds` / `C.Evolution.audio` and documented stock fallback when IDs are unavailable. No new persistence keys or arbitrary audio IDs. Additional config defaults or remote fields need the integrator's specific review. Maintain an asset matrix distinguishing creator-verified, stock fallback and unavailable/custom-upload-needed; this contract does not establish rights, asset permissions or sound quality.

## Build, acceptance and recovery

All parent map improvements are source-generated at run start and reuse retained native templates; the fixed 61-target lossless builder can deliver them. A new mesh/terrain/texture/audio upload or runtime ModuleScript requires a separate reviewed path. Do not use Lune serialization to overwrite native worlds; its Terrain warning is why preservation is checked by the raw binary auditor.

Original loading-art blob `7aadee72efa020a0c798a8e10b90f4ebf89e358d` and original IDs are frozen. Owner reports the released production artwork works. This does not certify this combined candidate's travel, physics or visuals. Physical mobile shooting comparison remains deferred.

Production recovery reference: release run `38985770842`, attempt 4, source `1a5b9f3`, versions Dispatch 28 / Blackwater 22 / Cinderworks 21 / Whiteout 21. The checked-in production rollback binaries contain v1.7.0 and are historical, **not the current live rollback**. Keep them untouched. Before another deployment, reconcile a current known-good recovery set with the workflow's actual rollback selection; an offline source-equivalent release artifact alone does not change that selection. Staging must likewise have an explicitly identified recovery point.

No staging/production dispatch, main merge, profile migration or native upload is authorized here. The integrator owns the exact-SHA build report, risk register and acceptance record. Studio and private-client evidence must remain separate from offline tests.
