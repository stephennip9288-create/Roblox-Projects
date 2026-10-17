# MAP Batch 1 — development and integration record

Branch `feature/dead-signal-map-world-batch1`; start/parent #21 head `6311ea3063bc789eea9cb0bc8876ef1f43f9b800`. Requirements read from main `5e7cc679448e4a2c0b4db084fbba522e0c7167a5`. PR #21 was open at the initial audit and is now merged. This follow-up adopts reviewed integration `2b7073cda226882343b925569bcc2b51fa7dfd88`, which includes #18/#21/#19/#20; no map-module conflict occurred. The parent feature branch stays unchanged. No staging/production authorization exists.

## Audit before implementation

| ID | Classification at start | Existing evidence and remaining work |
| --- | --- | --- |
| MAP-01 | Modified | #21 adds distinct shells and optional links; six-room plans still follow similar rows. Rework facility placement and asymmetric footprints. |
| MAP-02 | Modified | Existing Config lore and room names retained. Add explicit facility functions, landmarks and zone inventory. |
| MAP-03 | Modified | MapDetail has desks, radios, tanks and machinery; #21 reserves interaction approaches. Extend purpose-driven dressing within those reservations. |
| MAP-04 | Genuinely new | Architecture builds nine visually identical metal Gate parts. Add site-specific barrier geometry without changing purchase callbacks. |
| MAP-05 | Modified | #21 adds diagonal links but remains largely orthogonal. Change physical blockouts while preserving exact sector/door graph contracts. |
| MAP-06 | Modified | Existing galleries have one stair each. Add continuous elevated routes with a second ground connection and graph-compatible recovery anchors. |
| MAP-07 | Modified | VisualPass has a small northern skyline. Add layered surroundings on all sides and explicit scenery boundaries/budgets. |
| MAP-08 | Modified | Existing labels/props imply setting. Add short outbreak traces integrated with believable facility equipment. |
| MAP-09 | Genuinely new | Existing gallery is a one-ended overlook. Add alternate ascending/descending paths and inspect NPC/crawl clearance. |
| MAP-10 | Genuinely new | No bounded autonomous map visual events exist. Add scenery-only deterministic events with destruction cleanup. |
| MAP-11 | Genuinely new | Purchase gates share one vocabulary. Add exact per-map barrier/type inventories and state metadata. |
| MAP-12 | Modified | Existing practical lighting/fog and eye-height signs retained. Tune source lighting, cap shadow lights and keep ambient events away from threat cues. |

Other active work at start: #18 original loading preview, #19 enemy recovery, #20 combat/ADS/HUD. None is merged or proof of live acceptance. Preserve their code ownership and the parent's tested wall mounts/signs. Shared source files and runtime module inventory remain fixed.

## Adopted additive integration contracts

Coordination request: [comment on parent #21](https://github.com/stephennip9288-create/Roblox-Projects/pull/21#issuecomment-6228133750). The lead subsequently froze these interfaces in [INTEGRATION-CONTRACTS.md](../../INTEGRATION-CONTRACTS.md). [Continuation update](https://github.com/stephennip9288-create/Roblox-Projects/pull/21#issuecomment-6231157837) records adoption. No gated-file or consumer source is edited by Maps.

- Existing room IDs 1–6, all nine door IDs/costs/endpoints and four waypoints remain intact. Ground/upper retain levels 0/1 and existing navigation node/edge fields.
- Maps may supply optional `window.entry` physical anchor metadata while preserving `inside`, `outside`, `part`, `boards`, `count`. Enemy animation/AI consumes only after integration review.
- Maps supplies semantic `audioZones`, `landmarks` and ambient event descriptions. AUDIO/MAIN owns sound generation, mix and any consumer changes. No duplicate audio system, remotes or Config additions.

All MAP-01–12 have source implementations and offline evidence below. Integrated Studio/gameplay acceptance is pending for every row; these are not release approvals.

## Implementation and traceability

Source commit: `d6ce0f9322a68fe34fb3b86584ca26800ec0eb75`. The follow-up contains seven map-owned runtime modules, isolated tests and optional review tools. The fixed **61 runtime script records** remain unchanged. No shared Config/Game/Interactions/NavigationGraph/Effects/Presentation, runner, loading art, workflow, place IDs, save schema or native asset is edited.

| ID | Source result | Evidence and acceptance limit |
| --- | --- | --- |
| MAP-01 | Independently positioned facilities: Blackwater's bent bunker wings; Cinderworks' broad industrial crescent; Whiteout's separated listening/research spine | Three before/after plans; six-sector and objective identifiers retained. Combat rhythm requires native playtesting. |
| MAP-02 | All 18 sectors have explicit facility functions, equipment and short traces | Exact function/trace and landmark inventories; same three identities and Config lore. |
| MAP-03 | Purpose-built cabinets, drawers, gauges, recovered orders, polar samples and field equipment reuse existing map dressing | Wall backing, polygon corners, protected approaches; only cabinet bodies collide, visual hardware does not. |
| MAP-04 | Rubble, cargo, machinery, ice, collapsed gantries and bulkheads replace repeated plain gates | 27 exact barrier records; actual existing purchase handlers tested, including denial/repeat and complete visual cleanup. |
| MAP-05 | Asymmetric bastions, chamfered halls, hexagons, polar rotundas and diagonal transfers | All nine door endpoints/prices/four waypoints retained; Frost portal hints keep independent routes from crossing. |
| MAP-06 | Two continuous service walks per map, each with two physical no-jump ramps and additive recovery nodes | 12 ramps; real floor support, deck openings, headroom, guard clearance and connected graph edges. Native navmesh/crowding pending. |
| MAP-07 | Detailed foreground assemblies, middle skyline and reduced far silhouettes surround all sides | Noncollision/query/support exclusion, 450-part scenery cap; see exact inventories and cutaways. No dynamic-culling claim. |
| MAP-08 | 18 wall-backed outbreak traces follow the facility's use | Triage/carrier/diesel, evacuated steelworks/pressure/sample, missed rescue/ice reply/cryo; no mandatory long text. |
| MAP-09 | Service circuits provide two ground exits and opposite approaches | Actual Alpha/Warden/Ironbound envelopes, landing support and conservative swept collision audit. Exploit-free gameplay is not certified offline. |
| MAP-10 | Carrier/relay beacons, distant crane cycles and short polar gusts are bounded scenery events | Collision invariance, distance/particle caps, deterministic phases and stale-map callback cleanup; no damage/round/gate mutation. |
| MAP-11 | Per-map obstruction families, titles, action verbs and two-sided prices | 5.4-stud eye height; panels automatically stand beyond complete barrier bounds. Both sides clear on purchase. |
| MAP-12 | Per-map practical colors, morning/night exposure, fog/haze and at most three shadow lights | Source lighting presets and static light counts. Native PBR, powered/unpowered threat readability and phone performance remain pending. |

Every area is rebuilt at run start by the existing `Game:startRun` → `MapBuilder.build` path. Existing native templates/materials remain retained and cloned through `WorldArt`. No native geometry patch is needed; edit-time native previews remain unchanged until a generated run/preview is built. The existing lossless Source patcher delivers the complete maps without replacing native place data.

## Facility use and flow

| Map | Lore → functional layout → room use → intended flow |
| --- | --- |
| Blackwater Station | Military carrier station → checkpoint/triage, antenna field, diesel wing, repair stores, control watch, analysis lab → grounded field equipment and lost-carrier traces → angled bunker approaches with two service circuits and the retained signal/auxiliary loops |
| Cinderworks | Abandoned steelworks → shift/PPE, rail casting yard, boiler house, machine hall, furnace dispatch, metallurgy → pressure gauges, production hardware and evacuation traces → longer industrial lanes, heavy catwalk rooms and retained gantry/boiler returns |
| Whiteout Relay | Polar listening/research outpost → arrival/deicing, rescue apron, reactor, storm depot, listening watch, cryogenic stacks → sealed samples and missed-check-in traces → separated angular transfers, two upper circuits and retained listening tunnel/east airlock |

Six sector IDs, original objective assignments, four crew spawns, ten breach windows, 33 separated wall bays, seven weapon/ammo buys, six supply-box candidates, three fuses/frequency panels and nine progression purchases remain intact per map. Parent weapon mounting and interaction policies are preserved; integrated #20 weapon presentation is reused, not reauthored by Maps.

## Integration producers

The canonical producer follows the lead's [frozen contracts](../../INTEGRATION-CONTRACTS.md). Existing enemy callers can continue using every legacy window field.

```lua
window.entry = {
    schema = 1, id = "Station_entry_1", kind = "Window", room = 1,
    approach = CFrame, breach = CFrame, landing = CFrame,
    clearance = { radius = number, height = number },
    allowedKinds = { "Shambler", "Runner", "Crawler", "Hound", "Stalker", "Warden" },
    inward = Vector3, width = number, height = number, sillHeight = number,
}
```

All frames are physical world studs and face inward along -Z. Landing retains the legacy supported interior anchor, not an elevated-floor projection. Clearances are checked against actual base, Alpha and Ironbound rig attributes. Maps does not implement spawn/vault animation or collision handoff; ENEMY/MAIN must validate the future consumer with these physical openings. New vents/tunnels are not silently added as enemy entrances.

`map.audioZones` supplies six room polygons, two service-walk polygon sets and nine corridor region sets per map. `map.landmarks` supplies stable IDs/kinds/world positions/distance tiers; `map.visualEvents` supplies stable IDs, period/duration, position and current activity. `MapSemantics` replicates these as schema-1 folders/attributes (`Coordinates = WorldStuds`) under the generated map, with no new remote or runtime script. Window descriptors are replicated as attributes on their existing barrier parts. AUDIO/MAIN owns listener resolution, consumer wiring, event matching, final mix and asset permission checks. These producers create no Sound instances.

Ground and upper levels remain 0/1. The original room, door and graph node/edge fields remain; additional service-ring and second-ramp anchors use those fields. Initial navigation revision stays 9; existing purchase callbacks continue incrementing it. `Batch1MapRevision = 1` identifies the new generated world without breaking the parent layout/visual revision contract.

## Review evidence

[Exact inventories and native access risks](INVENTORIES.md) list every barrier/type/price, facility function/trace, landmark anchor, static part/light/effect budget and risky access location.

| Map | Parent → Batch 1 access plan | Layered-world cutaway | Desktop/mobile proportions |
| --- | --- | --- | --- |
| Blackwater | [Plan and access risks](Station-Access-Plan.png) | [Source cutaway](Station-World-Cutaway.png) | [1280×720 / 844×390](Station-Sign-Projections.png) |
| Cinderworks | [Plan and access risks](Foundry-Access-Plan.png) | [Source cutaway](Foundry-World-Cutaway.png) | [1280×720 / 844×390](Foundry-Sign-Projections.png) |
| Whiteout | [Plan and access risks](Frost-Access-Plan.png) | [Source cutaway](Frost-World-Cutaway.png) | [1280×720 / 844×390](Frost-Sign-Projections.png) |

All nine images are **offline geometry diagrams/projections**, not Roblox screenshots or phone captures. Plans use actual floor polygons; cutaways remove roofs and clip interior height. The software renderer uses flat primitive bounds, including retained meshes, and approximates sign fonts. Native textures/material variants, particle appearance, fog, shadows, HUD/ADS occlusion, true GUI font fitting and device usability are not rendered or accepted. Parent diagrams use exact #21 sources; Batch images also contain already-integrated #20 weapon changes.

## Verification and reproduction

**20 combined suites / 805,469 assertions passed**, including **222,651 new Batch map assertions** (244,859 combined map assertions). All 61 runtime scripts and 90 total Luau source/test/tool files compile. **59 repository Python tests**, four manifest checks, 30 purchase states and 4,017 elevated envelope samples pass. All four lossless candidates pass raw binary fidelity.

See [Verification-Report.json](Verification-Report.json) for source fingerprints and exact results. Checked-in raw reports distinguish source construction, the combined regression suite, projected clearance and binary fidelity. No report certifies a release.

- The standard runner executes the Batch 1 suite through maps-owned `map_remaster.luau`; `Tests/run.py` remains exactly the integrator's additive registration. CI therefore covers the new contract suite without another shared-runner edit.
- Source construction tests retain the parent wall/weapon/interaction checks and add eight real rig envelopes, both ramps/full circuits, supported graph edges, deck openings, actual purchase callbacks, complete barrier cleanup, panel stand-off, collision/effect invariance, deterministic bays and destroyed-map lifecycle.
- Ground projection uses a 0.75-stud grid with radius `1.85 × map.scale`. Ten purchase states per map match the purchased-door graph; all open approaches include corridor samples, windows, wall buys, objectives, spawn, extraction and side-by-side revive space.
- The separate 3D audit sweeps 4,017 samples along both ramps and full service circuits using conservative oriented collider hulls/vertical intervals. It combines the measured Alpha radius and Warden height plus 0.15 radius; support geometry is checked separately by the Luau suite. It cannot reproduce humanoid stepping or native navmesh.
- Four complete local staging candidates retain 61 script targets and preserve 1,513 / 1,496 / 1,500 / 1,500 unrelated native chunks. Raw binary/property fidelity passes; none is uploaded or published. Publisher regression tests use mocks.

Prepare the four temporary `dev/Places/DeadSignal-v1.8.0-*.rbxl` fixtures from protected full baselines as the existing CI does, then run from `dev/`:

```sh
python Tests/run.py --lune /path/to/lune --luau-compile /path/to/luau-compile
python Tests/check_map_remaster.py
python Tests/check_map_batch1.py
```

The projection auditors require NumPy/SciPy and are optional local checks outside standard CI. From repository root:

```sh
python -m unittest discover -s tests -v
python scripts/validate.py
python scripts/patch_dead_signal_rbxl.py
python scripts/audit_dead_signal_binary.py --candidate-dir build/dead-signal-lossless/staging --baseline-dir games/dead-signal/full-baselines/v1.8.0
```

For optional images, extract **all** parent server/shared source files from `6311ea3063bc789eea9cb0bc8876ef1f43f9b800` into `Validation/MapBatch1/BeforeSource/{server,shared}` (`git ls-tree --full-tree --name-only SHA:directory`, then `git show SHA:path`). `Tools/export-map-batch1.luau` refuses empty/current-source parent inputs. Run it with Lune, then `python Tools/review-map-batch1.py` (NumPy/Pillow). No exporter serializes a place or edits protected native files.

## Required native verification and rollback

MAIN DEV must review the optional Enemy/Audio consumers and perform integrated Studio acceptance. This PR does not certify those systems or install a parallel audio path. All parent dependencies are already in the adopted integration base; future cross-lane Batch 1 consumers still require combined regression and native validation.

Before release acceptance, capture real desktop/mobile views and play all three maps solo/2-/4-player, both modes, default/Low Effects and high-round load:

1. Pursuit, window entry, both ramps/full circuits, all 27 gates and optional loops for ordinary/crawler/hound/Alpha/Ironbound/Warden; test crowding, rail corners and possible safe spots. No jumping is added.
2. Every buy/perk/objective/counter/supply-box location: reach, priority, LOS and back sides of walls/closed gates; actual ADS, sightline and sign readability while moving and fighting.
3. Downed crawl/revive at stair landings, bays and doors; power/fuses/signal, Warden phases, extraction rally/hold, Dispatch travel, original loading art and persistence continuity.
4. Native materials and lighting while unpowered/powered and during hazards/warnings; confirm scenery haze/ambient activity does not hide threats. Verify distant-world sightlines from windows and galleries.
5. Profile build hitch, client/server frame time, memory, shadow cost, particles, 40 NPCs, hazards/corpses and cleanup on the target phone. Static source caps are not a frame-rate guarantee. Larger/longer facilities also need pacing review.

Rollback: revert this follow-up's map/test/tool commits and rebuild the prior reviewed source through the same lossless pipeline. No data migration or protected binary restoration is needed. Existing deployment recovery gates in the integration acceptance record still apply. No merging, main write, native upload, staging publish or production publish is performed by this specialist PR; staging and production each require separate explicit owner approval.
