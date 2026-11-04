# Enemy corrections — Batch 1.1

Draft [PR #42](https://github.com/stephennip9288-create/Roblox-Projects/pull/42) delivers a source candidate for DS-B1-002 and the code portion of DS-B1-006. **Neither bug is Verified. DS-B1-006's complete visual overhaul remains incomplete** pending authored face/skin/body/uniform assets and actual Studio quality review. No native asset, staging or production publication is included.

## Behavior changes

Window entry now checks the retained rig, equipment, hit zones and live collider through approach, brace/contact, crossing, landing and settling. Mounting follows the opening's canonical inward direction; stand-off accounts for the whole world-aligned swept envelope. Feet/paws stay above the floor, hands brace/pull ahead of the chest, and an alternate landing clears the opening before moving to the free side. Other active climbers reserve their full current stage envelope.

Entry queues drain front rows before diagonal tail traffic. A unit appears only after a supported, unoccupied exterior slot exists. Otherwise it remains a separate pending wave ticket: it still counts toward quota, retries fairly at one ticket per 0.8 seconds and never receives invisible attacks/hazards. Controlled mixed 4/12/24-unit tests complete without deleting quota. If all geometry is invalid, retaining a unit is an explicit release blocker; this PR does not complete a wave by silently retiring it.

Forward blocking invokes checked reverse motion. A bounded timeout releases scripted anchoring into live collider/Humanoid recovery with server ownership. Ordinary recovery retains the same actor, HP, damaged armor, weak points, reactor, rewards and cooldowns; visible actors walk/replan. Relocation is allowed only to a checked exterior slot when the entire actor and destination are occluded from every participating alive/downed player and sufficiently distant, followed by another animated entrance. Destroyed roots/models become state-preserving pending tickets; Warden phase, health, damage limits, overload and attack clocks survive.

Presentation adds asymmetric undead carriage, dragging/running cadence, articulated ankle/paw planting, timed attack windup/strike/recovery, bracing/pulling/reversing poses and damaged/exposed equipment. Existing native meshes, hit zones, elite markers and death/ragdoll mechanisms are retained. This is useful motion/equipment work, **not a replacement for authored undead anatomy and materials**.

## Changed files

| Runtime file | Purpose |
|---|---|
| `server/Enemies.lua` | Queue admission, bounded traversal/recovery and preserved wave identity/state. |
| `server/Navigation.lua` | Complete pose envelopes, real floor/foot support, crowd/landing checks, canonical alignment and bounded seam target selection. |
| `server/EnemyRigs.lua` | Root-bind the live collider without changing its rest geometry or authoritative hit zones. |
| `server/InfectedWardrobe.lua` | Exposed communications headgear, displaced/worn equipment and explicit pending visual acceptance. |
| `shared/NPCPose.lua` | Asymmetrical gait/attack/entry motion and pure joint-frame evaluation for sweeps. |

New distinct tests: `enemy-b11-runtime`, `enemy-b11-appearance`, `enemy-b11-admission`, `enemy-b11-spatial`, `enemy-b11-geometry`, plus test-only `Support/EnemyB11Geometry.luau`. Two optional visual export/render tools and this review package are also added. No shared runner, Config/Game/Combat/Controller/NavigationGraph/RigAnatomy, other lane runtime, protected native file, ID, saved-data schema, workflow or deployment file is changed. The fixed runtime remains 61 records.

## Evidence and gates

Exact runtime source: [`5db50d29001bbbce78540767265f8bb3a2d859ad`](https://github.com/stephennip9288-create/Roblox-Projects/commit/5db50d29001bbbce78540767265f8bb3a2d859ad). [Tested-Runtime.json](Tested-Runtime.json) binds all 61 source hashes and the five immutable Maps overlays. [Evidence.json](Evidence.json) records commands, results, preserved native hashes and limitations; [Geometry.json](Geometry.json) contains every window/profile outcome and selected target.

| Check | Result |
|---|---|
| Actual modules with controlled physics: runtime | 1,011 assertions pass, including mixed queues, interruption, timeout, recovery, narrow seam/broad-hole rejection and converging climbers. |
| Retained art/hit-zone structure and joint poses | 11,349 assertions pass; this does not assess native character quality. |
| Actual Game/Director/Enemies accounting | 29 assertions pass: pending/admitted/defeated Warden, quota, cap40, fair retries, reset/stale runs, root/model loss and live-only hazard/nuke loops. |
| Test spatial broadphase versus unpruned SAT | 420 checks pass on the isolated enemy baseline; 552 on finalized Maps source. The optimization retains the original collision decisions. |
| Existing entrance contracts | 71 assertions pass, including protected downed-player landing and contextual traversal. |
| Existing full runner | 23/26 suites pass; 969,795 assertions recorded. Three legacy gates remain red and are listed below. |
| Syntax / repository Python | All 61 runtime scripts compile; all 78 root Python tests pass. |
| Actual-part Maps matrix | **210/210 plans pass**: Station70, Foundry70, Frost70; all 30 windows × seven profiles, no logical floor-region fill and stable source throughout each run. |
| Offline lossless artifacts | Four source-patched files built locally; 61 targets/place, unrelated chunks byte-identical and raw property signatures preserved. Enemy source only; not the combined Maps release and not published. |
| Protected native files | All 12 repository `.rbxl` blobs match the checkpoint; unlisted Git tree entries are preserved by scoped commits. |
| Studio / private client / physical phone | Not performed; no gameplay, native visual or device acceptance claimed. |

Automatic CI at the tested runtime commit is also red: four workflow families stop at these same legacy source gates before artifact steps; repository validation passes. [CI.json](CI.json) links the exact checks. The separate local lossless/raw-fidelity reports pass and do not waive CI.

The three red legacy gates are **not waived**: `enemy-lifecycle` uses the old Navigation mock and replacement/retirement assumptions; `infected-batch1` expects MilitaryRevision1 and disabled entry collision; `infected-geometry` starts on unsupported old map anchors on this isolated branch and uses the old sweep calls. MAIN owns fixture/expectation migration and combined runner registration. Preserve those tests' intended protections and rerun after serial integration; see [MAIN-INTEGRATION.md](MAIN-INTEGRATION.md).

The strict matrix initially rejected every old baseline approach anchor, then exposed floor-clipping poses and diagonal AABB stand-off defects. After those fixes, 203/210 plans passed against Maps. The remaining seven all concerned Foundry window10: its canonical landing `(229.3600006, 0, 295.2400208)` center ray falls through a narrow wedge seam to Y=-1.2200012. Rays only 0.001 studs to either side hit floor Y=0. The consumer now selects a real supported point at most 0.05 world studs away and still requires all actual feet/paws and the complete rig to fit. Wider holes and unsupported upper anchors reject. Canonical map frames are unchanged. MAP DEV/MAIN must inspect this seam and the selected target in native gameplay; this is not a claim that offline SAT matches Roblox physics.

## Visual comparisons and dependencies

[Blackwater](station-poses.svg) · [Cinderworks](foundry-poses.svg) · [Whiteout](frost-poses.svg). Each compares immutable parent `206ae616…` with the tested candidate: idle Shambler, running Runner, attacking Shambler and climbing Warden. These are explicitly labeled **offline part bounds and joints**. They do not render mesh triangles, faces, textures, lighting or multiplayer animation. No actual Studio before/after capture is supplied.

[Asset-Requirements.md](Asset-Requirements.md) and [Rig-Reference.json](Rig-Reference.json) specify the exact retained art, authoring/bind constraints, three map personnel themes, rights/permission handoff and shared adapter dependency. [Studio-Retest.md](Studio-Retest.md) covers every finalized map, densities, blockers, target changes, collision, authoritative combat, elites/hounds, Warden/special waves, revive/extraction, mobile and multiplayer. MAIN integrates Maps #39 → Enemies #42 → Audio #43 plus its #41 adapter and owns all verification/publish decisions.

## Reproduce

Use Lune 0.11.0 and luau-compile 0.743. Run from `games/dead-signal/dev`, with immutable full-native places available through the repository's approved local fixture workflow:

```sh
lune run Tests/enemy-b11-runtime.luau
lune run Tests/enemy-b11-appearance.luau
lune run Tests/enemy-b11-admission.luau
lune run Tests/enemy-b11-spatial.luau
python Tests/run.py --lune /path/to/lune --luau-compile /path/to/luau-compile
```

For strict geometry, in a **separate test-only checkout** overlay exactly the five Maps files named in Tested-Runtime.json from `9c50b6f…`; do not change the feature branch's ownership scope. Run:

```sh
lune run Tests/enemy-b11-geometry.luau 9c50b6f7ff65f6f79d4550526aab40d6b84a363f 5db50d29001bbbce78540767265f8bb3a2d859ad
```

For visual review, extract `EnemyRigs.lua`, `InfectedWardrobe.lua` and `NPCPose.lua` at immutable parent `206ae616a7de4fe8dd69b1c8019bae6ea8b6863d` into `Validation/EnemyB11/BeforeSource/`; then run `lune run Tools/export-enemy-b11.luau <candidate-sha>` and `python Tools/render-enemy-b11.py`. Tools read native baselines and write only review outputs. Root pipeline tests use `python -m unittest discover -s tests -v` from the repository root and mock publishing APIs.
