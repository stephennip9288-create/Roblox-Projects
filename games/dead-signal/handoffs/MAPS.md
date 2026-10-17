# Dead Signal — Work Thread: Three Existing Map Remasters

You own `feature/dead-signal-map-remaster` in `stephennip9288-create/Roblox-Projects`. Read `games/dead-signal/PARALLEL-DEVELOPMENT.md` and `dev/README.md` before editing. Start from the designated feature branch, record baseline SHA, check existing PRs, and coordinate shared edits with the main integrator. Do not alter production, publish, or merge to `main`.

**Goal:** Substantially **rework the existing three maps only**—Blackwater Station, Cinderworks, Whiteout Relay—not add new maps or cosmetically recolor identical layouts. Each should have its own architectural silhouette, playstyle, spatial navigation and environmental storytelling. Keep objective/door progression, round pacing, path coverage, extraction, revive and Warden compatibility. Preserve the existing map IDs/teleport destinations.

**Specific owner requests:** Move obstructive/awkward items away from travel and combat routes; mount all weapon-buy displays/models cleanly on walls rather than floating or standing in open passages; separate overlapping interaction targets and use sensible priorities/reach; redesign door/path unlock signs and lower them to first-person readable heights; improve contrast, lettering, legibility in motion and on mobile; remove collisions, visual clipping and stuck-player safe spots.

**Likely lane files:** `server/MapBuilder.lua`, `MapDetail.lua`, `Architecture.lua`, `MapRoutes.lua`, `WorldArt.lua`, `WorldFinish.lua`, `VisualPass.lua`, `CinematicWorld.lua`; `shared/MapLayouts.lua`, plus isolated new tests. Do not change enemy navigation contracts, shared Config, Game, Interactions, Effects, or other lanes without integrator agreement. The current layouts use sector and link definitions; understand their full use before changing coordinates.

**Major build constraint:** Existing lossless publishing only swaps script Source chunks and PlaceConfig into complete native baseline files. Audit which map geometry/decor is spawned at runtime versus stored as native instances. Prefer editable, fully-tested source-authored visuals/layouts when safe; if improvements require new non-script RBXL assets, propose a *separate parity-audited native-asset integration path* and stop before altering protected baselines. Never ship a scripts-only Rojo replacement or silently change backup binaries.

**Acceptance:** Test geometry continuity, blocked routes, zombie reachability and path decisions, no player exploit ledges, all buy/perk/objective/door interactions reachable and non-overlapping, ADS visibility at buys/signs, downed revive approach, Warden/extraction routes, lighting and performance on all three maps. Include mobile-size view captures, before/after geometry notes, collision/interact placement checks and Studio/live-test limitations.

**Deliver:** a focused PR to integration with actual editable changes, new map/layout tests, documented ownership impacts, representative images/clips if available, and a clear list of what needs Studio verification. If source changes cannot safely realize the full rework, deliver tested source improvements and an explicit native-world patch proposal without claiming full completion.

---

## Newly approved development handoff — Batch 1: Maps (2026-10-16)

**Read the full traceability matrix:** [BATCH-1-APPROVED.md](BATCH-1-APPROVED.md), IDs **MAP-01 through MAP-12**. All recommendations for environmental storytelling, meaningful vertical routes, dynamic events, thematic barriers, professional lighting, and surrounding inaccessible-world detail are approved and in scope. This is a **new follow-up batch**, distinct from existing open **PR #21**. Do not overwrite or silently expand #21; coordinate a fresh follow-up branch and stack/depend on or rebase after #21 as the integrator directs.

**Concrete work plan:**
1. Audit #21's actual source-generated geometry, clearance reports and preview images to identify **remaining gaps**, rather than rebuilding its accomplishments. Preserve the six-sector objective/door identifiers, map-config names and the three existing map identities; only change topology with explicit route contract/validation.
2. Produce a per-map **lore -> functional facility layout -> believable room use -> flow graph**. Avoid interchangeable maps and orthogonal grid loops. Contrast Blackwater's cramped tactical bunker/antenna routes, Cinderworks' heavy industrial vertical catwalks and Whiteout's polar station/ice-exterior exposure. Make layouts playable before dressing.
3. Add well-supported galleries, stairs, ramps, overlooks and alternate routes. Ensure enemy navigation, downed crawl/revive, Warden/elite dimensions and extraction flows are viable. No unreachable exploit balconies or safe zones.
4. Replace repetitive wall purchase gates with per-map debris, collapsed structures, bulkheads, frozen doors, machinery and dynamic barrier states. Keep readable eye-level prices, accessible prompts, clear collision transitions and no overlapping buys.
5. Add convincing exterior/nonplayable world layers visible from any elevation/window: Blackwater guard towers/antennae/fences/forest, Cinderworks smokestacks/railroads/cranes/machinery/smoke, Whiteout radio towers/distant polar facilities/ice/vehicles/blizzard. Design an explicit boundary: scenery **must not** invite or accidentally allow navigation outside play.
6. Add lore-consistent traces and ambient **visual** events, lighting, weather and sightline-safe haze. Optimize and level-of-detail distant scenery for mobile. Coordinate sound trigger regions, ambient events and landmark mappings with AUDIO DEV; audio owns final sound generation and mix.

**Required evidence and acceptance:** Before/after playable map diagram, themed world/landmark inventory, risk map for player/NPC access, exact barrier/type list, clear signage/interactions, performance counts for background assets and visible effects, and measurements/screenshots from desktop and small mobile aspect ratios. Test all doors, stairs, perches, weapon mounts and traversal connections; demonstrate no trapped wave or interaction deadlock. Studio snapshots or offline renders alone are not gameplay acceptance.

**Shared contracts:** ENEMY DEV owns traversal AI + spawn animation; Maps owns physical window/vent/opening anchors and exterior approaches. COMBAT-UI owns weapon models but Maps owns stable wall mount coordinates and buyer reach. AUDIO DEV owns mixing and ambient zones; Maps supplies semantic regions and event descriptions. Any changes to shared Game/Config/Interactions/NavigationGraph/Effects/Presentation must first be approved by MAIN DEV.

**Do not deliver a visual-only faux remaster** that reintroduces blocky copied rooms, floating weapons, unreadable signs, inaccessible paths or performance regressions. Keep a verified full-native-asset build path and all protected binary inputs untouched.
