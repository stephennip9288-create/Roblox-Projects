# Batch 1 weapon fidelity — audit and integration record

Assigned follow-up: `feature/dead-signal-weapons-batch1`, starting at `533614972cd0c17212203d3099202f534a75aed8` (open parent PR #20). Latest handoffs read from main at `5e7cc679448e4a2c0b4db084fbba522e0c7167a5`. Main's later changes are coordination documents, not the parent weapon implementation. PRs #18, #19, #20 and #21 were open at audit; integration was `1a5b9f3b811137b6881090ad634a13624d33dd71`.

The integration lead subsequently merged #18/#21/#19/#20 and #25. Per the [recorded decision in #24](https://github.com/stephennip9288-create/Roblox-Projects/issues/24#issuecomment-6228240601), this branch brought integration `2b7073cda226882343b925569bcc2b51fa7dfd88` in with a normal fast-forward merge and targets `integration/dead-signal-next-release` directly. All 20 integrated suites are preserved; the new weapon suite is additive. Parent #20's branch and commits are untouched.

## Requirement inventory before implementation

| ID | Classification | Existing evidence and remaining work |
| --- | --- | --- |
| WPN-01 | Modified | `WeaponModels.build` already creates 20 identities; Kestrel/Longwatch retain imported art. Most procedural receivers share dimensions and grips/stock hardware need more coherent fit. Preserve native meshes; improve source-authored proportions and fittings. |
| WPN-02 | Modified | Chamfered receiver/stock, sights and `WeaponDetail.build` exist. Add fitted magazine wells, action hardware, stock locks, restrained surface detail and genuinely open reflex optics. |
| WPN-03 | Modified | #20 adds bounded kick and reload/empty-slide handling. Current action motion derives from accumulated recoil rather than a per-shot clock; build normalized, cancellable weapon-specific presentation. |
| WPN-04 | Already present, extended | #20 centers the authored sight axis and clears scoped ADS. Keep its alignment/visibility regressions; extend to reflex and additional FOV/aspect cases. |
| WPN-05 | Modified | Distinct barrel/stock configurations exist, but several shared dimensions and the AutoShot's pump-like motion are mechanically inconsistent. Give each current weapon an explicit construction/action profile. |
| WPN-06 | Genuinely new / modified | Iron and magnified sights exist; no reflex sight/reticle contract exists. Add an open housing and centered GUI reticle while preserving the magnified circular aperture. |
| WPN-07 | Modified | Generic sine-driven magazine/hand motion and style hints exist. Add staged magazine, tube, cylinder, break, belt, bolt and cell sequences tied to authoritative duration; clear visual state on swap/down/revive/run reset. |
| WPN-08 | Genuinely new / modified | Existing FX supplies generic smoke/tracer dust and a point-light flash; no casing pool exists. Add capped weapon-local flash/smoke/ejection and preserve confirmed hit feedback. Shared audio/impact contracts remain with integration/Audio. |
| WPN-09 | Modified | Existing steel/wood variants, paint and two neon upgrade conduits exist. Add purposeful material roles, bounded deterministic contact wear and tier-specific hardware rather than just recoloring. |

## Gun-by-gun baseline gaps (all tiers)

| Weapon | Current identity retained | Work beyond #20 |
| --- | --- | --- |
| Kestrel | Imported pistol mesh, slide, sights | Fit supplemental controls to native width/muzzle; staged pistol magazine and slide release; no native mesh replacement. |
| Carbine | Wood carbine | Slim receiver/wood proportions, barrel bands and sling hardware; magazine insertion and charging action. |
| Rook | Tube SMG / skeleton stock | Correct tube fittings and stamped magazine interface; bolt-cycle/ejection timing and stock latch. |
| Trench | Wood pump shotgun | Separate pump cycle from recoil; shell-loading and ejection at action opening; tube/mount detail. |
| Vandal | Conventional AR | Receiver/magwell/stock fit, open reflex option, carrier and charging sequence. |
| Harrier | Bullpup rifle | Rear magazine fit and rearward reload reach; carry bridge/reflex silhouette and butt hardware. |
| Anchor | Belt-fed heavy | Feed-cover/round/link groups move together; belt box change and charging sequence, restrained heavy hardware. |
| Longwatch | Imported wood bolt rifle / scope | Preserve mesh, fit supplemental hardware, timed bolt/ejection and loading; no native art substitution. |
| Cyclone | Drum-fed auto shotgun | Eliminate pump-like fire action; fixed forend and cycling bolt; drum insertion and action release. |
| Mantis | Top-feed PDW | Top-magwell and latch fit, horizontal insertion and open optic; compact stock/receiver proportions. |
| Signal | Heavy energy cannon | Cell couplers/insulators, bounded charge/vent presentation; no fictitious brass ejection. |
| Vigil | Revolver | Cylinder/crane/extractor/hammer groups, reload ejection and reseating; no auto-pistol slide/ejection. |
| Needle | Machine pistol | Frame/grip/magwell fit, bounded slide and stick-mag change; stock hardware. |
| Breaker | Double barrel | Entire front assembly/sight moves at hinge; two-shell breech loading/ejection during reload only. |
| Sable | Tactical pump | Tube loading and pump/ejection sequence, rail/forend fit and synthetic stock detail. |
| Meridian | Scoped DMR | Box-mag reload/charging, semiauto bolt cycle and scope mount/stock details. |
| Wasp | Compact folding-stock SMG | Compact receiver/magwell and stock lock; open reflex sight and fast magazine handling. |
| Bulwark | Drum-fed heavy | Drum/well/stock/bipod proportions; heavy carrier and drum change; no belt-cover behavior. |
| Halcyon | Precision bolt rifle | Stock/receiver/bipod fitting and scope hardware; bolt/extraction and magazine sequence. |
| Arc | Energy projector | Distinct capacitor/cell clamps, insulating finish and venting; no conventional cartridges. |

Source-authored geometry can improve construction and motion within the existing 61 script targets. Photoreal sculpted surfaces, new texture baking, custom hand rigs or replacement MeshParts are not asserted and would require a separate reviewed native import/build path and owner permission. Existing original/creator-owned weapon meshes, textures and material records are not overwritten.

## Approved integration contracts and dependencies

All implementation stays in owned weapon/Controller/Scope files. No edits to Config, Combat, Effects, server remotes, map placement, saved controls, workflows, native binaries or baselines are planned.

- Visual clocks expose semantic stages: `mag-out`, `mag-in`, `action-open`, `action-close`, `shell-in`, `cell-out`, `cell-in`, `charge`, `feed-open`, `feed-close`, plus `equip`, `fire`, `empty`, `cancel`. Normalized stage times use the server-confirmed reload duration; local cosmetics never refill ammo or confirm hits.
- The integrator approved optional Audio context `{weaponId, action, phase, token, position, firstPerson, tier, runId}` in #24/#23. Controller now supplies that context to the existing Equip/Empty/class-report/Reload calls; two-argument Effects remains compatible. Guarded `Weapon.Reload` stages require the optional `audioCancel` API and an acknowledged reload. Each source gets a cancellable string token; reset and resumption skip stale/replayed stages. No duplicate shot report or predicted Hit/Kill cue is added. `runId` is omitted because the existing State payload does not supply it; no remote extension is invented.
- **Audio dependency:** [PR #26](https://github.com/stephennip9288-create/Roblox-Projects/pull/26) is a separate proposal, not integrated runtime. Audio owns normalization of canonical `weaponId`/`sourceId` and phase-specific catalog resolution, voice budgets and recordings. The guarded hooks work with legacy Effects and do not require merging an unapproved implementation. Listening and bespoke/asset-permitted weapon foley are pending.
- Visual budgets: at most eight active local casings total per client (two reduced), including overlapping model sources. Each cached casing uses two non-queryable anchored parts and a .48-second analytical trajectory, not physics or raycasts. The current VM has one cached flash/smoke pair, at most two flash/two smoke particles per shot; reduced mode keeps one flash and no smoke. Flash light expires after .045 seconds, smoke opacity starts at .12 and lifetime is at most .20 seconds. Queue cap eight; semantic ledger cap 16. Teardown clears queues, emitters and cosmetic folders.
- MAP handoff: [MOUNT-BOUNDS.md](MOUNT-BOUNDS.md) gives all 20 tier-3 envelopes; [Geometry-Report.json](Geometry-Report.json) includes base/every upgrade before and after. X is width, Y is up, -Z is muzzle; bounds are physical studs at identity Root, with no map-scale multiplication of the gun. Maps owns mounting/clearance. The origin and sight authoring references remain available; Kestrel/Longwatch mesh content and native arms are retained.
- Shared impact/audio metadata and any server event extension require integrator review; the worker will not edit gated files to fabricate material hits or audio permission evidence.

## Verification and status

### Delivered source

| IDs | Implementation and evidence |
| --- | --- |
| WPN-01/02/05 | Explicit per-gun receiver/action/finish profiles; fitted magazine lips, pins, latches, stock hardware, guides and open reflex housing. Every weapon and tier is built in `weapons-batch1.luau`. Existing native weapon bodies are supplemented, not overwritten. |
| WPN-03/07 | Smooth normalized magazine/bullpup/top-feed/drum/cell/belt/tube/cylinder/break/bolt sequences, coherent feed/front groups, per-shot slide/carrier/pump/bolt clocks, chamber rotation and correct auto-shotgun fixed forend. Missing-round context controls shell stages. Original server ammo/stat/timing rules remain authoritative. |
| WPN-04/06 | Existing centered sight-axis/FOV adaptation retained; open reflex uses a centered GUI zero without glass/dot geometry obscuring a target; full magnified ADS hides the VM. Conservative aimed-ray tests span 20 guns x four tiers x nine viewports x five FOVs. |
| WPN-08 | Cached flash/smoke, shared capped ejection pool, finite queue/TTL and explicit cleanup. Existing server-confirmed hit captions, tracers/impact dust, elite/hazard/extraction/Warden cues remain. Material-specific impact facts require shared metadata and are not fabricated here. |
| WPN-09 | Steel/alloy/blued/stamped/polymers, wood and rubber roles, leather sling tabs represented with existing Fabric material, restrained deterministic wear. Tiers add couplers/fins, insulated leads and regulators beyond existing recolor/conduits. No new texture/material/mesh upload. |

The Controller additionally preserves a still-active authoritative reload across a phase reset, ignores stale reload packets for another held weapon, resumes cosmetic phases after input blocking without replay and invalidates effects/audio on swap, menu/focus/prompt/status/travel/character changes. Saved controls, HUD layout, server damage and economy stay on their existing interfaces.

### Evidence and reproduction

- [Construction sheet 1](Construction-1.png) and [sheet 2](Construction-2.png): actual source-part projections for all 20 guns, parent base versus Batch 1 base/tiers 1–3, at one stud scale. Gold rectangles are retained native MeshPart **bounds**, not their triangles/textures. These are not Studio screenshots or a realism claim.
- [ADS illustration](ADS-Projection.png): nine representative conservative geometry projections for iron/reflex/scope at small landscape, portrait and ultrawide. The scripted regression covers the full matrix. Actual rendered moving sight pictures remain a Studio check.
- `Tools/export-weapons-batch1.luau` uses the current modules and three parent #20 modules extracted with `git show 5336149:games/dead-signal/dev/Source/Runtime/shared/<name>.lua` into `Validation/WeaponsBatch1/BeforeSource/`. Run from dev, then `python Tools/render-weapons-batch1.py`. The exporter never serializes or overwrites a place.
- [Verification-Report.json](Verification-Report.json) records the tested source commit, runtime hashes, suite counts, caps and four-place lossless/fidelity results. Candidate files exist only under ignored `build/`; protected baseline/release assets are unchanged. No candidate is published or claimed engine-approved.

### Pending native acceptance

- [ ] Capture every gun at base and all upgrades in Studio, including native meshes/arm contact, stocks, magazine wells, material roles and wear. Decide whether source construction meets the visual bar; sculpted meshes/new baked textures need a separate asset review/import path.
- [ ] Check iron/reflex/scope alignment against actual server shots while walking, firing and moving through ADS at supported FOV/aspect settings; verify scope transitions never conceal an imminent threat.
- [ ] Test partial/empty reload, rapid fire, rejected/accepted swap, down/revive, rejoin, character respawn, run end, prompt/menu/focus and travel with latency. No ammo refill, phantom shot or prior-token cue may occur locally.
- [ ] Run solo/2-/4-client sessions on all three maps, with Warden/extraction/special waves, high-round loads and Low Effects; measure real FPS/part/particle/audio costs. Offline caps do not establish phone performance or network correctness.
- [ ] Verify wall-display rotated bounds, front approach, prompt/sign readability and navigation with Maps; no placement changes are included here.
- [ ] Integrate Audio separately, test canonical phase/token normalization, listen to stage/report balance and validate asset rights/permissions. Current stock placeholders are not realistic foley acceptance.
- [ ] Physical two-thumb comparisons remain deferred. Private staging and production each still require separate explicit owner approval.
