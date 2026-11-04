# Three-map remaster — integration review

Branch: `feature/dead-signal-map-remaster` → `integration/dead-signal-next-release`.
Starting feature/main/integration SHA: `1a5b9f3b811137b6881090ad634a13624d33dd71`.
This is an editable source candidate. Studio, published multiplayer, physical-phone and frame-time acceptance are pending. Nothing has been published or merged.

## Source and native-world audit

`Game:startRun` calls `MapBuilder.build`, which destroys `Workspace.DeadSignalMap` and constructs the playable map from `MapLayouts`, `Architecture`, `MapDetail` and `VisualPass`. `WorldArt` clones existing retained art templates and applies existing native material variants. This makes the structural remaster and placements deliverable through existing script Source patches. The native edit-time preview remains the old preview until a run/preview is built.

There are still exactly **61 runtime scripts**; no new module, mesh, texture, terrain, material, place destination, profile schema, workflow, or native-instance patch is required. The lossless builder preserves every unrelated native chunk. Protected native baselines, staging/production binaries, archives and manifests are unchanged. Do not use the optional visual exporters as place builders.

## Before and after

| Map | Baseline | This candidate | Intended play difference |
| --- | --- | --- | --- |
| Blackwater Station | Mixed polygon rooms, two galleries, generic bunker interiors | Orthogonal station wings, elongated reception/maintenance, one maintenance gallery; brick/plaster shell, ceramic dado, transoms, stopped 03:17 clock and platform markings | Compact sightline changes and a single watch position; retain both signal-underpass loops |
| Cinderworks | Similar six-sector cluster with rounded yard/boiler and short shop | Large rectangular industrial halls, tall sawtooth clerestories, gantries, corrugated steel/steam headers, flush casting-channel grates; long machine-shop and dispatch galleries | Longer industrial sightlines and larger turning space; optional yard-to-machine-shop gantry transfer replaces the station's west diagonal |
| Whiteout Relay | Similar clustered plan with two galleries and rectangular lab | Staggered hexagonal polar modules, faceted snow roofs, insulated wall bands/panel latches, central Operations rotunda gallery, longer east airlock return | Angular navigation and long transfers; optional yard-to-lab eastern airlock replaces the station's east diagonal |

The six sector IDs, objective-room assignments, four crew spawn slots, ten enemy windows, nine purchase slots, all prices and the first seven progression links remain intact. Only optional link 8/9 endpoints vary by location. No enemy navigation contract changes: existing room polygons, four-point door waypoints, stairs, support floors, areas and graph data are preserved. `navigationRevision`/layout/visual revision advances to 9.

| Map | Baseline parts | Candidate parts | Colliders | Wall bays | Galleries |
| --- | ---: | ---: | ---: | ---: | ---: |
| Blackwater | 4,246 | 4,469 | 694 | 33 | 1 |
| Cinderworks | 4,384 | 5,346 | 795 | 33 | 2 |
| Whiteout | 4,629 | 5,263 | 762 | 33 | 1 |

These static-part counts are authoring inventories, **not device-performance measurements**. Foundry's added cladding/gantries are the largest performance risk and should be profiled with the combined enemy lane.

## Placement and readability changes

- Wall bays use actual solid polygon-wall spans, including multiple separated portals on a straight wall. Deterministic, bounded placement planning reserves wide machines before narrow targets; generated same-room bay centers have at least 20.5 physical studs of separation.
- Every weapon display is backed by a real wall and its actual gun bounds are recentered sideways wholly in front of its plaque. Starter ammo is a wall plate; its former crate-art replacement is removed. Gun blueprints, combat/ADS and weapon ownership remain unchanged.
- Perks, fuses, power, dials, transmitter, upgrade machine, radio, all potential supply-box positions and environmental counters have perimeter bays and reserved standing/revive approaches. Cabinets and signs face the room. Counter pedestals and central trap posts are removed; trap emitters are flush and non-colliding.
- Gate signs face both approaches at **5.4 physical studs**, independent of map scale. They disappear with the existing gate-open hide routine. Signs use higher contrast, bold lettering and lighting-independent text. Weapon captions sit below the displayed gun. Two old high/floating room labels are removed.
- Existing no-jump ramps, boundaries and support-floor enforcement remain active. Roofs/decor are not added to support-floor lists; new identity details neither collide nor intercept shots. Vertical cable transforms now use a nonparallel up vector.

Spatial separation uses the existing `OnePerButton` behavior. `Game`/`Interactions` prompt distance, `allowWall` behavior, eligibility and priority code are unchanged. The integrator must test both sides of walls/locked gates and competing repair/buy/revive prompts in Studio; any eligibility-policy adjustment belongs to the shared-system lane.

## Offline verification

- Full runtime suite: **30,978 assertions** passed, including per-part transform checks; see `Tests-Report.json` for the recorded result.
- All **61 runtime scripts** compile. Repository Python pipeline suite: **59 tests**, plus four-place manifest validation.
- New `Tests/map_remaster.luau` runs in the existing CI runner. It constructs all three maps from current source against each map's complete native fixture; verifies replacement of the old preview, readiness, retained progression/objectives, graph connectivity, gallery ramps, support-floor contracts, wall backing, bay separation, gun/plaque clearance, sign height/faces, static geometry budget and finite transforms.
- `Tests/check_map_remaster.py` audits actual generated oriented colliders/floor polygons on a **0.75-stud grid**, inflated by **1.85 × map scale**. Every corridor centerline, interaction standing approach, window approach, extraction center, spawn and side-by-side revive position is reachable with all doors open. Ten purchase states per map match the exact purchased-door graph, including all gates closed. See `Clearance-Report.json`. This projection cannot prove a Roblox navmesh or full 3D physics.
- Four complete lossless staging candidates build locally; **61 expected source targets**, 21 sources different from native v1.8, with **1,513 / 1,496 / 1,500 / 1,500** unrelated chunks byte-preserved. Raw binary/property fidelity passes on all four. These counts include source already on main before this lane. See `LOSSLESS-REPORT.json` and `BINARY-FIDELITY-REPORT.json`.

### Review images

These are **offline source-geometry projections**, not Roblox screenshots or phone captures. They use exact exported transforms, simplified shading/materials and original weapon meshes where available. Unavailable world-prop originals are represented by their exported bounds; baseline invalid vertical cables are omitted. Native GUI font fitting, PBR/lighting fidelity, HUD occlusion and device usability still need engine captures.

| Map | Cutaway comparison | 844 × 390 gate projections |
| --- | --- | --- |
| Blackwater | [Before / after](Station-Before-After.png) | [Mobile-size eye-height comparison](Station-Mobile-Gate.png) |
| Cinderworks | [Before / after](Foundry-Before-After.png) | [Mobile-size eye-height comparison](Foundry-Mobile-Gate.png) |
| Whiteout | [Before / after](Frost-Before-After.png) | [Mobile-size eye-height comparison](Frost-Mobile-Gate.png) |

## Reproduction

Prepare the four temporary `dev/Places/DeadSignal-v1.8.0-*.rbxl` fixtures from the retained full native baselines, exactly as the existing lossless CI workflow does. From `dev/`:

```sh
python Tests/run.py --lune /path/to/lune --luau-compile /path/to/luau-compile
python Tests/check_map_remaster.py
```

The separate projected auditor needs NumPy and SciPy. It is a local extra check; the standard CI runner executes the new Luau construction/contract suite without those dependencies. Run the existing repository Python validation and `scripts/patch_dead_signal_rbxl.py`/`scripts/audit_dead_signal_binary.py` from repository root. Build outputs stay under `build/`.

Optional images: extract the seven changed runtime source modules from the starting SHA into `Validation/MapRemaster/BeforeSource/{server,shared}`, then run `lune run Tools/export-map-remaster.luau`. Run `Tools/render-map-remaster.py` with NumPy, Pillow, trimesh, pyrender and EGL; optionally pass `--art-directory` for the existing modular glTF originals. This never serializes native places.

## Integrator acceptance and rollback

The only potentially overlapping non-map edit is the one-line registration of `map_remaster` in `Tests/run.py`; retain every other lane's suite when resolving that line. Map data fields are additive (`wallFaces`, `mounts`); shared Game, Interactions, Config, NavigationGraph, Effects, loading art and deployment code are untouched. Combine the PR one lane at a time, rebuild with the current lossless pipeline and keep its exact source SHA.

Before any release approval, obtain actual Studio/Roblox evidence for **all three maps, solo/2-player/4-player and both modes**:

1. Closed/unlocked gates and optional loops; barricade entries; native pursuit for ordinary zombies, crawler, hound, Alpha and Warden; no routing stalls or gallery safe spots. Test every stair/landing and pushing/crowding beside props.
2. Buy/refill/perk/power/fuse/dial/transmitter/forge/radio/counter/supply-box operation, including every relocated box position. Test intended facing, reach, LOS, priority, both sides of walls and closed gates, and ADS readability beside each display.
3. Crawl/down/revive at bays, doorways, windows, stairs and extraction. Complete signal progression, Warden phases, extraction rally/hold and return to Dispatch. Check save continuity and preserved original loading artwork.
4. Capture actual first-person desktop and mobile-size views at unpowered/powered lighting and during special-wave warnings/smoke. Inspect all signs from both approaches and alongside the combined HUD/weapon lane. Physical two-thumb testing remains deferred per project instructions.
5. Compare low-effects/default client/server frame times and memory to the released baseline with 40 enemies, hazards and corpse cleanup; measure build hitch and Foundry's added static detail on a target phone.

Revert this lane's source/test/docs commit and rebuild through the same lossless pipeline to roll back. No protected binary needs restoration because none was edited. Later bespoke native terrain/mesh/lighting work must use a separate parity-audited native integration path; it is not needed to apply this source remaster. Staging and production publication require separate owner authorizations through the integrator.
