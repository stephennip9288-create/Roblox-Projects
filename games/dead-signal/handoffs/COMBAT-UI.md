# Dead Signal — Work Thread: Combat, Weapons, HUD & Mobile

You own `feature/dead-signal-combat-ui` in `stephennip9288-create/Roblox-Projects`. Read `games/dead-signal/PARALLEL-DEVELOPMENT.md` and `dev/README.md` first. Start from your named branch, audit current source, and coordinate interface changes with the main integration thread. Never publish or modify production backups/manifests.

**Goals:** More polished and detailed weapon viewmodels and animations, credible sights and usable ADS without blocking the target, correct sight-picture alignment at varied field-of-view/device ratios, consistent recoil/crosshair/hit feedback and weapon interactions. Improve HUD hierarchy, readability and first-person immersion without clutter, including event warnings, revive markers and weapon-buy prompts. Maintain touch controls responsive on different screen sizes, avoiding HUD covering movement/fire/aim surfaces, while preserving existing user settings and saved progression.

**Existing owner decisions:** Previously closed mobile FPS requirements are not a fresh request to redesign all controls. Treat current control layouts and behavior as the baseline; fix verified problems and seek new approval for behavior-breaking redesigns. No jumping unless explicitly reapproved. No changes to map placement; deliver mounting/interaction visual requirements to Maps thread. Maintain server-authoritative hit/damage validation.

**Likely lane files:** `client/Controller.lua`, `Scope.lua`, `AimAssist.lua`, `MobileControls.lua`, `UI.lua`; `shared/WeaponModels.lua`, `WeaponDetail.lua`, `WeaponBlueprints.lua`, `TouchInput.lua`, `TouchLayout.lua`, `ControlSettings.lua`; add focused `dev/Tests` cases. `server/Combat.lua`, `shared/Config.lua`, `client/Effects.lua`, `shared/Presentation.lua`, `server/Interactions.lua` are shared: get integrator approval for interfaces before changes. Do not replace working enemy/elites UI event cues.

**Tests:** ADS sight line against all weapon classes/upgrades, hipfire/ADS switching while walking, recoil+spread+hit registration, reload/cancel/ammo/revive transitions, device scaling (small/mobile/tablet/desktop), two-thumb fire/aim layouts when physical test authorized, input focus, buttons over map prompts, low-effects performance, color-independent status warnings. No UI overlap with extraction/Warden/special events; test the existing loading art after integration.

**Deliver:** branch PR into integration with tested source changes, before/after screenshots or captures if available, precise shared contracts, visual QA checklist and honest pending Studio/mobile acceptance items. Do not assert physical phone usability based only on offline checks.

---

## Newly approved development handoff — Batch 1: Weapon fidelity (2026-10-16)

**Read the full traceability matrix:** [BATCH-1-APPROVED.md](BATCH-1-APPROVED.md), IDs **WPN-01 through WPN-09**. All high-fidelity parts, ADS, gun-specific animation, recoil/particles and finish recommendations are approved. This is a **new follow-up batch**, NOT the already-open focused **PR #20**. Avoid overwriting or bloating #20; create a fresh follow-up branch coordinated by MAIN DEV after reviewing that PR's improvements.

**Concrete work plan:**
1. Audit #20's weapon parts, sight clearance and HUD fixes and establish the **remaining visual-fidelity gaps for EACH current weapon and upgrade**, documenting whether source code can realistically meet the visual targets or creator-owned mesh/material assets will be needed.
2. Produce consistent scale, realistic stocks/barrels/grips/receivers/sights, magazines/charging mechanisms, materials and aging; maintain original weapons' names/identities, stat schema, costs and damage authority.
3. Calibrate ADS axis at all current FOVs, standard and ultrawide aspects, desktop and small phones; optics, reticle, sight post, muzzle and actual shot direction must agree. Maintain target visibility while aiming/moving and through scope transitions.
4. Implement weapon-specific, mechanically plausible presentation with synchronized **but non-authoritative** animated bolts/slides, magazine insertion, shell loading, idle and switch, pump action and recoil. Server continues owning hits, ammo, fire/reload timing and valid state transitions. Cancel/reset visual timelines when weapons change, run ends or player revives.
5. Improve muzzle flashes, smoke, ejection, impact and wear/material finish details with bounded client effects and safe reduced-settings equivalence. Coordinate sound event names/timing/character with **AUDIO DEV**; never edit core FX sound or shared Config without integration contract.
6. Preserve already-customizable mobile layout/input, existing HUD improvements, revive markers, extraction/Warden/elite cues and clean wall-mounted model/buy art. Send mount dimensions/sightline requirements to MAP DEV; map team decides placement.

**Acceptance:** gun-by-gun evidence (original and upgraded), sight obstruction screenshots at multiple aspect ratios, confirmed shot alignment/server authority, reload cancel/rejoin/revive sequences, muzzle/effects caps, UI scaling, mobile overlap and color-independent warnings. Visual realism is an in-Studio/art-review claim, not a conclusion from module tests or concept imagery.

**Do not overwrite existing original/creator-owned weapon models, release binaries or production configs.** If new MeshParts or texture uploads are required, stop and request a reviewed native asset import and parity build method rather than claiming the fixed-script source patcher ships these directly.
