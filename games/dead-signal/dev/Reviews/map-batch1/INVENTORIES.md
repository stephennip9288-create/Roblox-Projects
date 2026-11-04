# Exact Batch 1 map inventories

Generated from the tested source exports. Coordinates and agent dimensions are world studs. These counts do not measure native performance.

## Geometry and budgets

| Map | Parent parts | Batch parts | Colliders | Near / middle / far scenery | Lights / shadow lights | Galleries / ramps | Peak background particles per second |
| --- | ---: | ---: | ---: | --- | --- | --- | ---: |
| Station | 4,469 | 5,435 | 1,062 | 253 / 20 / 64 | 80 / 3 | 2 / 4 | 0 |
| Foundry | 5,346 | 5,835 | 1,215 | 138 / 32 / 8 | 79 / 3 | 2 / 4 | 3 |
| Frost | 5,263 | 6,034 | 1,167 | 56 / 0 / 24 | 85 / 3 | 2 / 4 | 8 |

Scenery cap: 450 parts per map; whole generated map cap: 6,500 parts. Near/middle/far are authored detail tiers with distant shadows disabled, not a claim of dynamic distance culling. One visual update per second per active map. Two exhaust emitters at rate 1.5/lifetime 3 give at most about 9 live background particles in Foundry; two gust emitters at rate 4/lifetime 2 give at most 16 in Frost. Station adds no background particles. Existing gameplay VFX budgets remain unchanged.

## Purchase vocabulary

All nine original slots and prices are retained. `GateN` remains the authoritative collider. Its noncolliding children and both price signs are hidden by the existing purchase callback. Every price sign is at 5.4 world studs and sits beyond the complete barrier bounds.

| Map | Gate | Sector connection | Cost | Family | Exact title |
| --- | ---: | --- | ---: | --- | --- |
| Station | 1 | 1 → 2 | 750 | Rubble | CHECKPOINT DEBRIS |
| Station | 2 | 1 → 4 | 900 | Rubble | COLLAPSED MASONRY |
| Station | 3 | 2 → 3 | 1250 | Bulkhead | GENERATOR SHUTTER |
| Station | 4 | 2 → 5 | 1000 | Machinery | FALLEN CABLE RACK |
| Station | 5 | 4 → 5 | 750 | Bulkhead | BLAST BULKHEAD |
| Station | 6 | 5 → 6 | 1500 | Rubble | SERVICE CAVE-IN |
| Station | 7 | 3 → 6 | 1000 | Machinery | GENERATOR WRECK |
| Station | 8 | 1 → 5 | 1100 | Gantry | BROKEN AERIAL |
| Station | 9 | 3 → 5 | 900 | Cargo | SEALED FIELD STORES |
| Foundry | 1 | 1 → 2 | 750 | Cargo | STEEL PALLET STACK |
| Foundry | 2 | 1 → 4 | 900 | Gantry | COLLAPSED GANTRY |
| Foundry | 3 | 2 → 3 | 1250 | Bulkhead | FURNACE BULKHEAD |
| Foundry | 4 | 2 → 5 | 1000 | Machinery | SLAG HOPPER |
| Foundry | 5 | 4 → 5 | 750 | Bulkhead | FREIGHT SHUTTER |
| Foundry | 6 | 5 → 6 | 1500 | Cargo | ROLLED STEEL LOAD |
| Foundry | 7 | 3 → 6 | 1000 | Machinery | DERAILED TRANSFER |
| Foundry | 8 | 2 → 4 | 1100 | Gantry | PIPE TRANSFER |
| Foundry | 9 | 3 → 5 | 900 | Machinery | BOILER MACHINERY |
| Frost | 1 | 1 → 2 | 750 | Ice | ICED PRESSURE DOOR |
| Frost | 2 | 1 → 4 | 900 | Ice | ICE FALL |
| Frost | 3 | 2 → 3 | 1250 | Bulkhead | SAFETY BULKHEAD |
| Frost | 4 | 2 → 5 | 1000 | Gantry | COLLAPSED MAST |
| Frost | 5 | 4 → 5 | 750 | Cargo | FROZEN CARGO |
| Frost | 6 | 5 → 6 | 1500 | Bulkhead | CRYO SHUTTER |
| Frost | 7 | 3 → 6 | 1000 | Machinery | SNOWBOUND HAULER |
| Frost | 8 | 1 → 5 | 1100 | Ice | LISTENING TUNNEL ICE |
| Frost | 9 | 2 → 6 | 900 | Bulkhead | RESEARCH BULKHEAD |

## Facility function and outbreak traces

| Map / sector | Facility function | Short environmental trace |
| --- | --- | --- |
| Station / 1 | Checkpoint and triage | TRIAGE / UNCLAIMED |
| Station / 2 | Antenna switching field | 03:17 / CARRIER LOST |
| Station / 3 | Diesel generation | DIESEL / HOLD LOAD |
| Station / 4 | Field repair and stores | REPAIR / SHIFT ABANDONED |
| Station / 5 | Carrier control watch | WATCH / NO REPLY |
| Station / 6 | Signal analysis lab | SIGNAL / QUARANTINE |
| Foundry / 1 | Shift clock and PPE | SHIFT 09 / NO RETURN |
| Foundry / 2 | Rail and casting yard | FREIGHT / EVACUATED |
| Foundry / 3 | Boiler pressure house | PRESSURE / ISOLATED |
| Foundry / 4 | Machine hall catwalk | TOOLS / DO NOT RESTART |
| Foundry / 5 | Furnace dispatch gallery | HEAT / INTERLOCK LOST |
| Foundry / 6 | Metallurgy and crucibles | SAMPLE / CONTAMINATED |
| Frost / 1 | Polar arrival and deicing | ARRIVALS / DEICE FIRST |
| Frost / 2 | Ice apron and rescue | RESCUE / MISSED CHECK-IN |
| Frost / 3 | Reactor thermal plant | THERMAL / HOLD OUTPUT |
| Frost / 4 | Storm supply depot | RATIONS / LAST INVENTORY |
| Frost / 5 | Listening array watch | ECHO / REPLY BELOW ICE |
| Frost / 6 | Cryogenic research stacks | CRYO / DO NOT THAW |

## Exterior landmarks and visual events

| Map | Authored world layers | Bounded activity |
| --- | --- | --- |
| Station | Four guard towers, perimeter fencing, broadcast mast, 32 far pines, three abandoned field trucks | Carrier beacon: 3 seconds every 43; cosmetic opacity only |
| Foundry | Two rail sidings, four smokestacks, two portal cranes with suspended cables, six pipe-yard buildings, eight far rolling mills | Crane trolley and cable: 8 seconds every 61, at most 8 authoring studs; two capped exhaust emitters |
| Frost | Four remote huts and radio masts, 24 far ice ridges, two snowbound tracked research vehicles | Relay beacon: 4 seconds every 47; two polar gusts: 5 seconds every 53 |

None adds playable terrain, damage, gates, audio, round state, support floors or combat-query geometry. All scenery part centers lie outside BoundaryGuard playable regions. Existing boundary walls, collision groups and floor support enforcement retain containment. Native corner/crowding exploits remain a required playtest.

Stable landmark anchors:

| Map | ID | Kind / tier | World position (X, Y, Z) |
| --- | --- | --- | --- |
| Station | `Station_guard_1` | GuardTower / Near | -236.0, 26.0, -153.0 |
| Station | `Station_guard_2` | GuardTower / Near | 197.0, 26.0, -153.0 |
| Station | `Station_guard_3` | GuardTower / Near | 197.0, 26.0, 264.0 |
| Station | `Station_guard_4` | GuardTower / Near | -236.0, 26.0, 264.0 |
| Station | `Station_broadcast_mast` | AntennaField / Middle | -19.5, 50.0, -206.0 |
| Foundry | `Foundry_stack_1` | Smokestack / Middle | -325.7, 97.6, -261.1 |
| Foundry | `Foundry_stack_2` | Smokestack / Middle | -92.3, 78.1, -261.1 |
| Foundry | `Foundry_stack_3` | Smokestack / Middle | 141.1, 97.6, -261.1 |
| Foundry | `Foundry_stack_4` | Smokestack / Middle | 374.5, 78.1, -261.1 |
| Foundry | `Foundry_crane_1` | GantryCrane / Near | 330.6, 51.2, -196.4 |
| Foundry | `Foundry_crane_2` | GantryCrane / Near | -281.8, 51.2, 342.8 |
| Frost | `Frost_remote_hut_1` | RemotePolarFacility / Near | -280.5, 6.6, -228.8 |
| Frost | `Frost_remote_hut_2` | RemotePolarFacility / Near | 267.3, 6.6, -228.8 |
| Frost | `Frost_remote_hut_3` | RemotePolarFacility / Near | 267.3, 6.6, 292.6 |
| Frost | `Frost_remote_hut_4` | RemotePolarFacility / Near | -280.5, 6.6, 292.6 |
| Frost | `Frost_frozen_rover_1` | FrozenResearchVehicle / Near | -320.1, 5.5, 31.9 |
| Frost | `Frost_frozen_rover_2` | FrozenResearchVehicle / Near | 306.9, 5.5, 31.9 |

## Native access risks to verify

| Location | Offline evidence | Required native verification |
| --- | --- | --- |
| Every gallery (Station 4/5; Foundry 4/5; Frost 5/6) | Full supported circuit, two physical ramps, swept largest-agent envelope, no premature deck lip or blocked rail opening | Human crawl/revive, turning/crowding, native no-jump paths, no unreachable perches |
| Gates 1–9 on each map | Sequential actual Game callbacks, repeat/inaccessible purchase rejection, decoration/sign cleanup; 30 physical purchase states match graph | Both-side prompt reach/LOS, combat crowding, no visual collision mismatch |
| Ten entries per map | Legacy fields retained; schema 1 CFrames, explicit eligibility, largest rig dimensions; outside approach excluded from playable area | Entry animation/collision timing and root-height fit through ENEMY integration; no instant appearance claim |
| All 33 wall bays per map | Real-wall backing, complete weapon plaque bounds, separation and reachable side-by-side revive space | ADS/reticle/HUD at all buys, both sides of walls and competing prompts |
| Exterior layers | Noncolliding, non-queryable, non-support; fixed detail/effect caps and stale callback cleanup | Camera sightlines from windows/elevation, containment and target-phone frame times |

The envelope combines the maximum actual radius (Alpha Hound, 1.856) and maximum height (Warden, 8.33), then adds 0.15 radius in the 3D audit. Ironbound and every base kind are measured from actual rig builders. This conservative mixed envelope still does not simulate Roblox pathfinding or capsule physics.
