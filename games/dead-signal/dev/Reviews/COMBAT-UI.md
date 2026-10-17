# Combat/UI integration record

Branch: `feature/dead-signal-combat-ui` → `integration/dead-signal-next-release`.
Starting SHA: `1a5b9f3b811137b6881090ad634a13624d33dd71`.
Main, integration and the assigned branch matched at the initial audit. The source already contained v1.9 special-wave/enemy presentation and the merged loading-art fixes; this pass preserves those systems.

## Changes and evidence

- Open rear notches, restrained sight indexes and protected front blades; restore those authored sights after the Kestrel/Longwatch imported-art replacement. The actual imported muzzle determines their front-sight position. Native meshes/materials are retained.
- A sight-axis reference and FOV/aspect-aware eye distance keep full ADS centered. Idle/walking lateral bob fades completely at full ADS. Camera recoil and server spread remain intact; weapon kick is reduced during ADS so the barrel does not obstruct the target. Scope housings fade during the transition, and the whole first-person model clears the existing circular optic when engaged.
- Bounded slide/bolt cycling, empty-slide lockback and differentiated tube/cell/belt/bolt reload hand motions. Belt feed cover, revolver hammer and procedural triggers articulate with their moving groups. Equip/melee animation is retained.
- Cancel latched desktop fire/ADS on text focus and Roblox-menu opening. Revive/other prompt holds block combat actions until ended, triggered or hidden; down/travel/character changes release stale interaction locks. Swaps retain their local reload lock until the server confirms a different slot. Same-slot/missing-slot input cannot cancel a reload locally.
- HUD regions use the current saved touch rectangles, including mirror/custom positions. Notices, objective/extraction, Warden, revive count, vitals, inventory and status durations avoid those controls and the center sight area. Cosmetic perk text can yield space on saturated layouts. Grenades have a separate compact label, so long upgraded names cannot truncate their count. Real interactive/processed GUI keeps priority; a projected world-prompt fallback cannot swallow an otherwise unprocessed touch on a control.
- Crosshair spacing reflects angular hip spread plus visual recoil. Hit/head/kill feedback still comes only from server confirmations; HEAD/KILL text adds a cue independent of color. New hits cancel the previous fade. Existing hitmarker preference is respected.

[Before/after rectangle evidence](combat-ui-layout.svg) uses actual layout coordinates for a 568×280 Classic layout with concurrent notices/status. It is an offline geometry diagram, **not a Roblox screenshot**. No native screenshots, gameplay captures or physical phone observations were available in this execution environment.

## Contracts for the integration lead

No gated runtime file, cross-lane implementation, remote payload, Config setting, persistence key/schema, place ID, pipeline or native baseline is changed. There are still **61 runtime script records**. All native art is preserved by the source-only build path.

| Lane-local contract | Meaning |
| --- | --- |
| `WeaponModels.viewOffset(id, hip, alpha, fov, viewport)` | Returns a camera-local presentation offset. Does not change a shot origin/direction or server stats. |
| `WeaponModels.aim(model, enabled, alpha?)` | Existing boolean call remains valid; optional alpha fades the optic during transition. Full scoped ADS hides this local viewmodel only. |
| `WeaponModels.pose(..., recoil, empty?)` | Existing callers remain valid; optional empty flag holds a supported pistol slide open. |
| `WeaponBlueprints.reloadStyle` | Optional animation metadata; unspecified weapons keep magazine behavior. No reload timing/ammo rule changes. |
| `UI:setTouchLayout(settings)` | MobileControls supplies its resolved settings after resize. UI computes rectangles without modifying or saving them. |
| `TouchLayout.combatHUD(layout, settings, flags)` | Pure HUD-region allocator; optional cosmetic fields may be absent. `crowded` reports layouts where essential information cannot fit around deliberately congested custom controls. |
| `UI:reticle(def, fov, viewport, recoil)` | Local visual spread feedback; hit feedback stays server-confirmed. |

Existing special-wave/elite/hazard feeds and Effects implementations are unchanged. Downed world outlines, names and countdown billboards remain owned by `DownedPose`; the HUD adds a count/compact text only. Existing prompt object/action/price/key/hold and server reach validation remain authoritative. No jumping is reintroduced.

The runner adds `combat-ui`, `combat-input` and the existing deterministic `touch` suite. **Merge this list additively** with PR #18's `loadingpreview` and PR #19's `enemy-lifecycle` / `enemy-path-recovery` suites; do not resolve a `Tests/run.py` conflict by replacing another lane's list. No runtime overlap with those PRs was found in the audit.

## Maps handoff

Keep buy models mounted flush to a readable wall/backing at normal first-person reach; leave their decorative parts non-queryable/non-colliding. Keep the prompt and price readable from the usable approach, away from adjacent interactions and door edges. Reserve sight lines through the front of a wall-buy, room to step back, downed/revive paths and the center of phone viewports. Use the existing server prompt contract; have the integration lead review any new attributes, custom prompt GUI, reach/pricing or interaction-priority change. This branch moves no map objects or signs.

## Offline verification

Run from repository root:

```text
python -m unittest discover -s tests -v
python scripts/validate.py
python scripts/generate_dead_signal_place_configs.py
python games/dead-signal/dev/Tests/run.py --lune /path/to/lune --luau-compile /path/to/luau-compile
python scripts/patch_dead_signal_rbxl.py --environment staging
python scripts/audit_dead_signal_binary.py --baseline-dir games/dead-signal/full-baselines/v1.8.0 --candidate-dir build/dead-signal-lossless/staging
```

Prepare the four `dev/Places` temporary fixtures from checked-in staging files as the unchanged source-CI workflow does. Never stage fixtures, candidates, Validation reports or protected binaries as source edits.

- 59 Python tests pass; all four manifests validate; eight environment-isolated config modules generate.
- 15 Lune suites pass. `combat-ui`: 80 weapon/tier models, nine viewport sizes, five FOVs and 270 HUD scenarios. `combat-input`: 29 controlled-controller assertions. Existing touch gestures: 512 assertions. All 61 runtime scripts compile.
- Sampled safe-area sizes: 568×280, 640×320, 740×340, 800×360, 360×740, 1024×700, 1280×760, 1920×1080, 2560×1080. ADS FOVs: 34, 44, 57, 80, 100. Geometry uses conservative oriented part bounds, not rendered mesh triangles.
- Four offline staging candidates patch successfully: Dispatch preserves 1,513 non-target chunks; Blackwater 1,496; Cinderworks/Whiteout 1,500 each. Independent binary fidelity passes for all four. Candidate scripts include pre-existing v1.9/loading changes as well as this lane; changed-script counts are relative to the native v1.8 baselines.

No Studio, real multiplayer, real raycast/network/physics, device FPS, audio-permission or physical mobile result is claimed. Dense custom layouts can still exhaust the available pixels; the allocator preserves preferences and essential labels, and exposes `crowded` for inspection rather than silently moving the player's controls. Native text wrapping and minimum-font readability need the checks below.

## Native acceptance remaining

- [ ] Open the integration lead's exact-SHA lossless candidates in Studio; capture before/after weapon/HUD views on all three maps and Dispatch. Verify original artwork/loading exit and arrival/travel in all four places.
- [ ] Equip all 20 classes at all upgrade tiers and finish/skin variants; hip/ADS while moving, sprinting, equipping and taking damage. Verify rear/front alignment, unobstructed target, scope transitions and recoil at low/high FOV and portrait/landscape/tablet/desktop ratios.
- [ ] Inspect tube, break-action, cylinder, belt, cell and bolt reload poses; empty slide, ammo updates, interrupted reload, successful/rejected/same-slot swap, melee and grenade transitions. Mechanical appearance and hand contact require actual engine review.
- [ ] Solo, two- and four-player firing/hit validation under latency; hit/head/kill flashes, confirmed ammo reconciliation, down/revive/respawn and another operator's prompt hold. Check chat, Roblox menu and window focus require a fresh firing gesture after closing.
- [ ] Show extraction, Warden phases/overload, each special preparation/warning, three active power-ups, long upgraded weapon names, three long crew names/downed markers and buy prompts. Check no clipping/occlusion, grenade/down counters remain visible, and normal/Low Effects retain all essential cues.
- [ ] In the existing HUD editor, resize/rotate and check saved custom/mirrored layouts. Confirm ordinary buy/revive GUI consumes its actual touch and controls near projected world prompts remain responsive. If controls themselves overlap, resolve through the existing editor rather than overwriting a saved profile.
- [ ] When the owner resumes physical mobile comparison, test Tap/Left/Classic two-thumb move/look/fire/aim/reload/swap on the target phones/tablets. Measure crowded-wave frame time and UI cost against the current baseline. This work does not resume the deferred comparison by itself.
- [ ] Confirm settings/credits/progression persist, Dispatch→map→extraction/return works, and no cross-lane enemy/map regression appears after combining sources.

Rollback is a scoped revert of this lane's source commits followed by the established lossless rebuild. No data migration or native asset replacement is involved. Workers do not merge or publish; integration and any staging/production publication remain with the integration lead and the owner's separate approvals.
