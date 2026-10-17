# Approved Batch 1 — combined source traceability

All 31 approved IDs are implemented in the combined source candidate. This is source/offline completion, **not native visual, physics, listening, device or multiplayer acceptance**. Parent progress and all four specialist heads are preserved. Native Studio/private-client checks remain required after authorized staging; physical two-thumb controls comparison remains deferred.

| ID | Owner | Implemented behavior | Source / offline evidence |
| --- | --- | --- | --- |
| MAP-01 | Maps | Distinct asymmetric facility footprints, combat circuits and exterior silhouettes. | MapLayouts / Architecture / CinematicWorld; map_remaster, map_batch1; ground and elevated audits. |
| MAP-02 | Maps | Sector functions and equipment follow military communications, steelworks and polar research lore. | MapLayouts / MapDetail / CinematicWorld; map_batch1 facility/trace contracts. |
| MAP-03 | Maps | Purposeful dressing reserves objectives, approach/revive space, wall buys and traversal bays. | MapBuilder / MapDetail / MapRoutes; map_remaster; check_map_remaster.py. |
| MAP-04 | Maps | 27 themed purchasable obstructions retain authoritative payment and clear all collision/decor on purchase. | Architecture / MapLayouts; existing Game callbacks; map_batch1 actual purchase callbacks. |
| MAP-05 | Maps | Bastions, hexagons, rotundas, angled transfers and distinct optional links replace the shared grid. | MapLayouts / Architecture / NavigationGraph; 30 purchase states in ground audit. |
| MAP-06 | Maps | Six two-ended service circuits, 12 no-jump ramps and three supported contextual links per site. | Architecture / MapRoutes; map_batch1, infected-geometry; elevated sweep. |
| MAP-07 | Maps | Nonblocking layered compounds, rail/industrial works and polar facilities beyond playable bounds. | CinematicWorld; map_batch1 scenery bounds/counts. |
| MAP-08 | Maps | Facility-specific damage, containment equipment, papers, traces and functional displays. | MapDetail / CinematicWorld; map_batch1 facility/story contracts. |
| MAP-09 | Maps | Both gallery approaches remain reachable; low service pads have a normal side ramp and NPC ledge routes. | Architecture / MapRoutes / Navigation; map_batch1; infected-geometry support/swept links. |
| MAP-10 | Maps | Bounded beacons, cranes/exhaust and gusts cannot change gameplay collision, rounds or damage. | CinematicWorld; map_batch1 lifecycle and collision invariance. |
| MAP-11 | Maps | Site-specific barrier families and signs stand beyond full geometry at readable height. | Architecture / MapLayouts; map_batch1 barrier/sign clearance. |
| MAP-12 | Maps | Distinct lighting/fog/material treatments and at most three shadow lights; warnings retained. | MapBuilder / VisualPass / CinematicWorld; map_batch1 source budgets; native rendering pending. |
| EN-01 | Enemies | Retained native anatomy/texture assets gain bounded asymmetric infection and uniform detail. | InfectedWardrobe / EnemyRigs; infected-batch1 hitbox/rig comparisons. |
| EN-02 | Enemies | Six military families, three wear stages and map-specific radios, kit and damage. | InfectedWardrobe; infected-batch1 deterministic family/wear tests. |
| EN-03 | Enemies | Canine muzzle, chest/hocks, jaw/ears, contact/leap/landing poses and directional reactions. | HoundRig / NPCPose; infected-batch1, rigs. |
| EN-04 | Enemies | Visible approach/contact/cross/descent/settle/pursuit uses continuous geometry and occupant checks. | Enemies / Navigation / NPCPose; infected-batch1, infected-entrances, infected-geometry. |
| EN-05 | Enemies | Infantry, Security, SpecialOps, Officer, Hazmat and Heavy gear reflect each facility. | InfectedWardrobe; infected-batch1 family and collision checks. |
| EN-06 | Enemies | Working-dog harness/unit markings, injuries and animal articulation retain Alpha distinction. | HoundRig / EnemyRigs / NPCPose; infected-batch1, infected-geometry actual Alpha envelope. |
| EN-07 | Enemies | Enabled LowVault and up/down Ledge links cross actual low cover/service pads; doors and main routes retain native pursuit. | MapRoutes / Navigation / Enemies; 63 contextual plans and continuous sweeps; no-jump pad support; pursuit/recovery suites. |
| EN-08 | Enemies | Directional flinch/lethal impulse and cosmetic gear degradation follow confirmed hits/armor breaks. | Enemies / EnemyRigs / NPCPose; infected-batch1; existing damage/precision/armor tests. |
| EN-09 | Enemies | All ten exterior window approaches per site are animated, reserved and warned; Warden escorts enter outside. | WaveDirector / Enemies / Architecture; 210 actual agent/window combinations; no instantaneous interior spawn; entry audio adapters. |
| WPN-01 | Combat/UI | All 20 weapons and four tiers have fitted profiles, native arms/mesh retention and contact detail. | WeaponModels / WeaponDetail / WeaponBlueprints; weapons, weapons-batch1, combat-ui. |
| WPN-02 | Combat/UI | Receivers, actions, optics, magazines, stocks, grips and hardware fit individual weapon profiles. | WeaponModels / WeaponDetail; 160 model constructions plus base geometry tests. |
| WPN-03 | Combat/UI | Weapon-specific handling, recoil, switching and reversible reload timelines reconcile accepted state. | WeaponModels / Controller; weapons-batch1, combat-input. |
| WPN-04 | Combat/UI | Open optics and authored sight axes align across FOV/aspect/mobile HUD cases. | WeaponModels / Scope / Controller; 80 ADS tier models; 270 HUD scenarios. |
| WPN-05 | Combat/UI | Class silhouettes/action hardware remain distinct; upgraded Breaker has three real barrels/shells for its unchanged capacity. | WeaponBlueprints / WeaponModels / WeaponDetail; weapons-batch1 physical chamber/capacity check. |
| WPN-06 | Combat/UI | Centered reflex/iron/magnified sight picture follows actual aiming without opaque weapon masks. | Scope / WeaponModels / Controller; combat-ui, combat-input sight-axis checks. |
| WPN-07 | Combat/UI | Magazine/bolt/pump/tube/belt/cell/cylinder/break stages support cancellation and accepted reload resumption. | WeaponModels / Controller / Effects; weapons-batch1, combat-input, audio. |
| WPN-08 | Combat/UI | Bounded cached flash/smoke and global eight/two casing caps retain confirmed hit feedback. | WeaponModels / Controller; weapons-batch1 shared-source caps/teardown. |
| WPN-09 | Combat/UI | Steel/polymer/rubber/leather/wood/wear treatments and progressive geometric upgrade hardware. | WeaponDetail / WeaponModels; weapons-batch1 all tier/finish cases. |
| AUD-01 | Audio | Bounded mixer plus integrated world zones/events, NPC entry/Alpha/foley, acknowledged shots/reloads, phase/objective warnings and mute/lifecycle cleanup. | Effects / Controller; additive server presentation metadata; audio, batch1-integration, combat-input; six Python patch guards; asset matrix. |

## Exact specialist inputs

- Maps #29: `069d247b39988801fb067c16843e322a34649a5d`.
- Enemies #31: `7c1b15a79a154c36c86a890db46ca3a72fc80673`, including its later normalization/recovery improvements.
- Combat/UI #27: `14960d82bdbabcb7c0032d7446a1ed40e47be0e6`.
- Audio #26: `bd4394d598af0539078dee747e2355653ab588c6`.

## Scope and acceptance limits

Source-created geometry/poses preserve native mesh/material records and the existing 61-script delivery path. No proprietary/third-party art/audio or new uploaded assets are substituted. Source projections and static bounds do not establish realistic-art quality; the owner must assess the native game.

AUD-01 retains documented bundled treatments. Bespoke map beds/radio/realistic weapons/K9/foley have no supplied creator-verified IDs; unavailable slots remain silent or use the existing honest fallback. The Audio handoff explicitly treats asset/permission dependencies as nonblocking, and they remain listed in `Reviews/audio-immersion/ASSET-MATRIX.md`. Default character footsteps remain available and now honor master volume through a dedicated group; material-specific NPC slots are wired. Custom player-footstep replacement, full reverb/automatic wall occlusion and unapproved vent/tunnel spawning are not claimed.

The approved existing window/sill entry, low cover, supported ledges, no-jump ramps and opened-door pursuit are enabled. Optional generic Door/Vent/Tunnel consumers remain gated for future authored content; this release does not invent those entrances.

No new staging or production release is authorized by this table. The independent trusted-main release record must select the final reviewed integration SHA, and the owner must separately authorize private staging and later production.
