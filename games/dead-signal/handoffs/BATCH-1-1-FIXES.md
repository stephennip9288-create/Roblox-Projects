# Dead Signal — Batch 1.1 corrective contracts

Owner: MAIN integration lead. Coordination: [#37](https://github.com/stephennip9288-create/Roblox-Projects/issues/37). Scope is the six owner-reported Batch 1 staging defects, not Batch 2.

## Audited starting point

- Current main controls: `5f6d0a0c1ab3d462bc0a3f4413d3ce4593a3e6bb`.
- Current integration / deployed game source: `9743b3e9ee59ba74da0d5d9a5e3f2e378230d6f7`.
- Successful staging run `39056526660`, attempt 1, 2026-10-17; Dispatch 11 / Blackwater 10 / Cinderworks 10 / Whiteout 10.
- Retained artifact `12109702848`, archive SHA-256 `e969cc319cc71c6ff55d24c9ddc546d674f2035192e44f6586c5a6fe00b1117b`, expires 2027-01-15. All four binaries were downloaded, hash/CRC checked and match the frozen Batch 1 candidate.
- No open specialist PRs existed at this audit. Completed Batch 1 branches and their exact heads remain untouched. Existing full-native baselines and 61 runtime records are retained.
- Main's staging recovery record predates this successful deployment. MAIN must review/update it from these actual artifacts and logs. Production recovery stays at its original-artwork release.

## Isolated work and ownership

| Lane | New branch | Bugs / exclusive files |
|---|---|---|
| Combined patch | integration/dead-signal-batch1-1 | MAIN owns integration, runner, reports and shared adapters. Final PR targets integration/dead-signal-next-release. |
| MAP DEV | fix/dead-signal-batch1-1-maps | DS-B1-003/004/005 and geometry support for 002. Own Architecture, MapBuilder, MapDetail, MapRoutes, WorldArt, WorldFinish, VisualPass, CinematicWorld and MapLayouts. |
| ENEMY DEV | fix/dead-signal-batch1-1-enemies | DS-B1-002/006. Own Enemies, Navigation, EnemyRigs, HoundRig, InfectedWardrobe, NPCPose, WaveDirector and DirectorRules. |
| AUDIO DEV | fix/dead-signal-batch1-1-audio | DS-B1-001. Exclusive audio-facing Effects.lua edits and distinct audio tests/docs only. Preserve all VFX/telegraph methods and existing callers. |

Specialist PRs target the combined patch branch. Each lane must deliver actual source changes, meaningful automated tests and an evidence/limitations report. MAIN commits the reviewed isolated snapshots to their GitHub branches and opens the scoped PRs. Do not concurrently edit another lane's files. Config, Game, Combat, Controller, Interactions, NavigationGraph, Presentation, LoadingScreen, PlaceConfig, test registration, builders, workflows and release records remain MAIN-owned. Propose any required change first.

## Window producer/consumer contract — DS-B1-002

Keep schema 1 and legacy inside/outside hints. All canonical approach/landing CFrames are world-stud **foot-floor** locations; breach is the physical sill top; -Z faces inward. Scale once. Preserve stable id, room, kind, allowedKinds, clearance, width, height, sillHeight and inward fields. No required new field, entrance kind or remote is approved.

MAP DEV owns actual walls, sills, headers, floors, exterior support and clearance. ENEMY DEV owns placement, visible approach/contact/vault/crawl/land/recovery, collision handoff, dynamic occupancy and cancellation. Geometry validation must include the whole actual rig envelope and floor support, not only root centers or an empty-instance mock. Include all 30 windows and seven existing agent/variant envelopes across the finalized maps.

Do not silently ignore live blockers, remove collision with players/enemies, teleport actors into rooms, discard quota to hide stuck actors or create repeat re-entry loops. Bound obstruction/backoff and retries, recover toward a different eligible opening where necessary, preserve hitboxes and server authority. Publish any revised collider/trajectory assumptions before integration; MAIN consumes Maps first, then reruns enemy tests against that exact geometry.

## Placement and stairs — DS-B1-003/004/005

Use a consistent local wall basis: tangential axis follows wall, thickness axis follows its normal. Signs' actual SurfaceGui front must face the usable room approach. Include angled/curved/hexagonal wall spans. Tests must inspect produced transforms/colliders and representative render projections; source-string assertions alone are insufficient.

Ramps, wedge collision, visible treads, deck cutouts, rails and top landings must agree across the complete player-width/headroom envelope, including both travel directions and off-center edge approaches. Avoid ledges/overhangs that catch heads/shoulders. Preserve supported floors, ground and elevated loops, all doors/interaction approaches, revive/extraction clearance and NPC eligibility.

Dress under-detailed rooms by function and theme, with bounded prop/lighting counts and no collision/query cost for incidental detail. Respect every window, stair, door, objective and interaction reservation. Retain the three identities and all four native place contents.

## Sound and undead — DS-B1-001/006

Preserve the semantic event names and acknowledged Shot/reload timing, source/run tokens, deduplication, volume/mute and 20/12 voice limits. Enemy.Entry Approach/Contact/Land must follow actual transitions once; cancellation stops the source. No new remote or client combat authority. AUDIO may improve sample selection/treatment within the existing Effects implementation; any Config or Controller need is a concrete MAIN proposal.

Do not pass stock notification chirps off as realistic gunfire, animals, machinery or room ambience. Audit every currently active fallback and report what is audible, unavailable or disabled. Never invent rights-cleared IDs or claim permissions/listening from offline tests. If suitable creator-approved assets are unavailable, deliver the useful code and exact asset/acceptance blockers; DS-B1-001 and the combined release cannot be claimed complete on that basis.

Undead changes must improve anatomy, worn/infected skin and clothing, facial silhouette, asymmetry and gait while preserving the approved military/site variation. Do not merely add tactical accessories. Preserve tagged authoritative hit zones, elite/armor/weak-point readability, facing, live collision, ragdoll and bounded geometry/animation cost. Procedural projections are review aids, not native art acceptance.

## Combined acceptance and release boundary

All six bugs begin Open, become In Progress during implementation, and may become Ready for Retest only with reviewed source/tests. **Verified requires the relevant actual staging gameplay retest and owner evidence.** Record map/room/window, build, device, crew, mode, round and observations; never infer success from CI.

Integrate Maps -> Enemies -> Audio, run all existing suites plus new regressions, 61-script compilation, Python tests/config isolation, ground/elevated and entry envelopes, eight environment builds and four-place raw binary fidelity. Compare protected blobs against the audited baseline. Keep saves, purchases, economy, rounds/special waves, Warden/extraction, damage, mobile controls, original artwork and IDs unchanged.

Prepare one combined candidate and bug-by-bug report with exact SHAs, file diffs, tests, blockers and current-release rollback. A draft artifact with an unresolved bug is not a complete release-ready patch. No partial staging publication, no Batch 1.1 publication authorization, and no production authorization. Request the respective explicit owner approval only when the complete reviewable patch is ready.
