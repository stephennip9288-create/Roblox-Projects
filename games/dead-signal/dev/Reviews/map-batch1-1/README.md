# Batch 1.1 map corrective patch

Prepared for MAIN review in [PR #39](https://github.com/stephennip9288-create/Roblox-Projects/pull/39). DS-B1-003/004/005 and map-side DS-B1-002 are implemented in source; native acceptance remains pending. No bug is marked Verified and nothing was published.

Runtime under test: [`529b44c6784053363785e8e04d4744f95ea079eb`](https://github.com/stephennip9288-create/Roblox-Projects/commit/529b44c6784053363785e8e04d4744f95ea079eb). Earlier checkpoints: [wall/stair producer repair](https://github.com/stephennip9288-create/Roblox-Projects/commit/ff67f2942ca3e5d65d724175b2de777a58ccbc80), [room dressing and exterior support](https://github.com/stephennip9288-create/Roblox-Projects/commit/e11666e51138c62084244fdfd5e6e5d534cd3514). Later evidence/test-only commits preserve these 61 runtime blobs; see [Tested-Runtime.json](Tested-Runtime.json).

The before source is exact coordination base `206ae616a7de4fe8dd69b1c8019bae6ea8b6863d`, whose runtime equals staged Batch 1 `9743b3e9ee59ba74da0d5d9a5e3f2e378230d6f7`. Previous map remaster #21 and Batch 1 #29 remain integrated. This is a distinct corrective patch targeting `integration/dead-signal-batch1-1`; MAIN owns its later integration into `integration/dead-signal-next-release`.

## Repairs and per-map inventory

| Map | Incorrect deck wedges repaired | Wall bays corrected | Ramps / flush landings | Supported window aprons | Static parts before → after | Lights / shadows |
|---|---:|---:|---:|---:|---:|---:|
| Blackwater Station | 32 | 33 | 4 / 4 | 10 | 5527 → 5771 | 78 / 3 |
| Cinderworks | 32 | 33 | 4 / 4 | 10 | 5920 → 6186 | 79 / 3 |
| Whiteout Relay | 24 | 33 | 4 / 4 | 10 | 6127 → 6415 | 85 / 3 |

**DS-B1-005:** floor triangles now split perpendicular to their longest edge. The former arbitrary base produced wedges beyond obtuse clipped polygons, including stair openings. Tests inspect actual WedgePart footprints, rather than trusting logical floor regions. Each ramp has a flush full-width top landing; a 1/32 author-stud overlap bridges the numeric seam, with less than .015 author-stud height difference from the final slope. Existing elevation, two-ended gallery routes, visible treads, rails and progression remain.

**DS-B1-003:** `wallFrame` derives a proper rotation with local -Z facing inward. It replaces reflected frames in wall bays, facility equipment, architectural cladding, the stopped clock and polar roof details. Utility conduits/stains and polar ice drips now follow actual wall spans. Crate and console labels face their usable side. Desk trays, work islands, pallet canvas, footlockers, lathe pieces, hoists, dishes and aerial companions emit with their support assembly, preventing orphaned decorations when a reservation omits the base. Door signs retain the 5.4-stud read height.

**DS-B1-004:** every room receives two reserved assemblies: purpose-specific retained furniture/equipment plus a damaged wall service panel and short outbreak trace. There are 36 assemblies across 18 rooms. New incidental dressing has no collision, query or touch cost and creates no new jump perch. It respects window, door, stair, gallery, spawn, traversal-bay and interaction reservations. All maps remain below 6500 static parts, with three shadow lights each. Existing cover and practical lighting remain; unsupported aerial lights are omitted with their bases.

| Map / room | Function and new equipment |
|---|---|
| Blackwater 1 | Checkpoint/triage: medical case, bandages, folded rescue canvas, casualty list |
| Blackwater 2 | Antenna switching: patch receiver, dead-channel traces and signal spools |
| Blackwater 3 | Diesel generation: service canisters, seals, filter tray and isolated feed line |
| Blackwater 4 | Repair/stores: vise, removed tools, rotor housing and interrupted job sheet |
| Blackwater 5 | Carrier watch: receiver, instrument glass and carrier spools |
| Blackwater 6 | Signal lab: receiver, analysis traces and recording spools |
| Cinderworks 1 | Shift/PPE: abandoned protective equipment and inventory tags |
| Cinderworks 2 | Casting yard: tooling, vise and unfinished casting work |
| Cinderworks 3 | Pressure house: sealed canisters, removed filter and isolated feed |
| Cinderworks 4 | Machine hall: bench tools, rotor and interrupted machine work |
| Cinderworks 5 | Furnace dispatch: interlock receiver, dead-channel traces and records |
| Cinderworks 6 | Metallurgy: sealed samples, canisters and removed tray |
| Whiteout 1 | Arrival/deicing: cold-weather drying rack and check-in inventory |
| Whiteout 2 | Ice apron/rescue: medical case, rescue canvas and unanswered list |
| Whiteout 3 | Thermal plant: filters, insulated canisters and isolated feed |
| Whiteout 4 | Storm depot: ration tins, inventory tags and last-shift clipboard |
| Whiteout 5 | Listening watch: receiver, instrument glass and recording reels |
| Whiteout 6 | Cryogenic research: sealed sample canisters, batch seals and removed tray |

**DS-B1-002 support:** each opening has a real 17 × 26 author-stud apron, outward 0..26, registered in `floorParts`. The canonical approach stays outward 11 at feet Y=0; landing, sill-top breach, inward -Z, schema 1, stable IDs, eligibility and legacy hints remain unchanged. The lead and two rear near-window footprints have actual support at a 2.4 world-stud radius. Existing exterior ground is also registered, at its true top Y=-1×scale. Deep queue candidates must be projected to that real floor and checked for whole-body clearance; a broad 40-slot rectangle is not promised clear. ENEMY accepted this contract on [issue #37](https://github.com/stephennip9288-create/Roblox-Projects/issues/37#issuecomment-6245306005). Queue admission, live occupancy, cancellation, recovery and wave accounting remain ENEMY-owned.

## Test results

See [Validation-Summary.json](Validation-Summary.json), [Geometry-Checks.json](Geometry-Checks.json) and [Staged-Reproduction.json](Staged-Reproduction.json).

| Check | Result |
|---|---|
| Existing 26 Lune suites | 1,009,642 assertions; all passed |
| New `map_batch11.luau` | 26,386 assertions; zero failures |
| Combined source assertions | 1,036,028 |
| Actual wedge containment | Before: 88 leaking wedges; after: zero |
| Complete ramp width / head-height support | 2940 samples across 12 ramps; zero failures |
| Supplemental elevated body clearance | 6953 samples, five ramp lanes and gallery circuits; zero obstructions |
| Ground routes | All 30 purchase states; all available sectors reachable; zero failures |
| Existing actual window/agent plans | All 210 profiles, 90 samples per plan; zero rejections/failures |
| Existing authored obstacle/ledge plans | All 63 profiles passed |
| Python pipeline / audio guards | 78 + 6 tests passed |
| Compilation | 101 Luau files, including all 61 runtime scripts; zero errors |
| Lossless builds | Four staging + four production artifacts built offline; all eight fidelity audits passed |
| Protected inputs | 152 workflow/pipeline/native/archive/config/release inputs unchanged |

The old supplemental elevated audit initially reported 88 obstacle hits against the newly named landing floors. It omitted `StairLanding` from its existing support list and interpolated feet linearly through the flat approaches. Its map-owned helper now recognizes that support and follows the real flat–slope–flat profile, with five lanes instead of one. This audit checks non-support colliders; the separate produced-wedge and head-height floor tests still detect deck overhangs, gaps and premature landings. The unchanged staged baseline fails those direct checks on six ramps.

Reports: [ground routes](Ground-Reachability.json), [elevated clearance](Elevated-Clearance.json), [compilation](Compilation.json), [protected inputs](Protected-Inputs.json), [staging fidelity](staging-Binary-Fidelity.json), [production fidelity](production-Binary-Fidelity.json). The recorded 210 entry plans use the existing staged enemy consumer/rigs; MAIN must rerun the revised ENEMY implementation against these exact map blobs.

All five no-publish workflows passed on runtime commit 529b44c: [source CI](https://github.com/stephennip9288-create/Roblox-Projects/actions/runs/39138452310), [lossless](https://github.com/stephennip9288-create/Roblox-Projects/actions/runs/39138452305), [staging preflight](https://github.com/stephennip9288-create/Roblox-Projects/actions/runs/39138452362), [production readiness](https://github.com/stephennip9288-create/Roblox-Projects/actions/runs/39138452311), [repository validation](https://github.com/stephennip9288-create/Roblox-Projects/actions/runs/39138452316). MAIN still needs to register the new map suite; these existing workflows do not independently run that unregistered suite.

## Before/after review images

These are exact source diagrams and primitive/retained-mesh-bounds projections, **not Roblox screenshots**. Reflected-frame coercion, native meshes/materials, lighting and engine physics are not simulated. The room views omit roofs/upper decks and lower walls to expose placement. They establish placement changes, not native art acceptance.

| Map | Stairs | All six rooms | Wall frames / desktop and mobile-aspect gate projections |
|---|---|---|---|
| Blackwater | [Before/after](Station-Stair-Collision.png) | [Before/after](Station-Rooms-Before-After.png) | [1280×720 / 844×390](Station-Wall-Viewports.png) |
| Cinderworks | [Before/after](Foundry-Stair-Collision.png) | [Before/after](Foundry-Rooms-Before-After.png) | [1280×720 / 844×390](Foundry-Wall-Viewports.png) |
| Whiteout | [Before/after](Frost-Stair-Collision.png) | [Before/after](Frost-Rooms-Before-After.png) | [1280×720 / 844×390](Frost-Wall-Viewports.png) |

[Projection measurements](Projection-Measurements.json) use 65° vertical FOV, a 5.4-stud eye and 12-stud gate distance. Physical desktop/mobile input, phone frame times, Roblox font rasterization and touch usability were not tested.

## Integration and Roblox verification

1. MAIN registers `map_batch11` once in its runner; `map_remaster` already invokes `map_batch1`, so do not double-count that older suite. Keep the strengthened map-owned supplemental Python audit.
2. Integrate Maps before ENEMY. Rerun ENEMY's revised full animated rig envelopes, safe pending admission, live blockers/queues, cancellation and quota checks on these final maps. No shared Game/Config/Controller/NavigationGraph/runner change is made here.
3. Open the combined offline candidates in Studio. On every ramp and landing, ascend, descend, stop, reverse, turn and approach both edges in first person. Check avatar sizes, downed crawl/revive, Warden, hound, crawler and elite pursuit; inspect rails, treads and headroom.
4. Test all 30 windows with several simultaneous enemies and high-round convergence. Block/unblock landing space with players/enemies, interrupt climbs, open doors and reset the run; verify no stuck actor, unsafe slot or lost quota.
5. Inspect every room, wall buy, sign, fixture and service assembly for native orientation, attachment, visual intersections, readable combat routes and environmental quality. Inspect gallery/extraction/revive sightlines and both normal/Low Effects lighting.
6. Owner retests the approved combined staging build on desktop and mobile with solo, two-player and four-player crews; record build, map/room/window, device, mode, round and observations. Check min/typical FPS, memory/server frame time, Warden, extraction, Dispatch travel and persistence. These remain outstanding.

MAIN decides review/status progression. Any staging publish still requires separate owner approval; production requires its own approval. No native baseline, rollback binary, place ID, save schema, release control or workflow was changed.

## Reproduce

From `games/dead-signal/dev`, with the normal four temporary native fixtures and Lune 0.11.0:

```text
lune run Tests/map_batch11.luau
lune run Tests/map_remaster.luau
python Tests/check_map_remaster.py
python Tests/check_map_batch1.py
python Tools/review-map-batch11.py
```

For before images, first extract **all 61** `dev/Source/Runtime` files from exact base 206ae616 into `Validation/MapBatch11/BeforeSource/{server,shared,client}` with their directory structure. Put the full base SHA in `BeforeSource/SHA.txt`, then run `lune run Tests/map_batch11.luau before`. That mode requires the full extraction, preserves native per-place PlaceConfig and records expected failures without asserting. It must not be used as a passing test. The default mode always installs current source and asserts zero failures.

The existing full runner is `python Tests/run.py --lune /absolute/path/to/lune`. Root pipeline tests, config validation and the lossless patch/audit scripts remain unchanged. Build artifacts and test fixtures stay temporary; no generated RBXL is committed.
