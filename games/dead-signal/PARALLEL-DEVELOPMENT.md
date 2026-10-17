# Dead Signal — Parallel Work Development Protocol

**Setup baseline:** `main` at `2a7e99e36ccb36b941990c70e8d43a09b2ed131d` (2026-10-16 inspection). This is a coordination baseline, **not** certification that its source has been released. Refresh/rebase against current `main` before integration.

## Purpose and authoritative sources
Four specialist Work threads develop (1) existing map remasters, (2) enemy behavior/evolution, (3) weapons/combat/HUD/mobile, and (4) audio/immersion. A fifth **main integrator Work thread** reviews, merges, builds, and prepares releases. New chats have no shared live state: **GitHub PRs and this protocol are their coordination contract**, not chat memory.

Read `games/dead-signal/dev/README.md`, `CLOUD-DEVELOPMENT.md`, `LOSSLESS-PATCH-WORKFLOW.md`, `V1.9-ROADMAP.md`, `V1.9-STAGING-PLAYTEST.md`, and the applicable worker brief in `handoffs/` before touching code. Historical README/release docs may be stale. Current repository source, artifacts, exact SHAs, and verified production observations take priority.

**Critical baseline facts:** Four-place game: Dispatch + Blackwater Station (`Station`), Cinderworks (`Foundry`), Whiteout Relay (`Frost`). Editable runtime scripts live in `games/dead-signal/dev/Source/Runtime/{server,client,shared}`, tests in `games/dead-signal/dev/Tests`. `main` presently declares `C.Version = "1.9.0"`; v1.9 candidate gameplay is source-side, **not proof of staging or live acceptance**. Loading-art PRs #15/#16 were merged during setup on 2026-10-16. Preserve their changes and re-check current GitHub state before integrating overlapping loading code. The prior planning backlog is closed; do not reopen it from chat summaries or reimplement existing v1.9 systems blindly.

## Lanes and exclusive branches
| Lane | Branch | Lead files, not a blanket authorization |
| --- | --- | --- |
| Maps & visuals | `feature/dead-signal-map-remaster` | `server/MapBuilder.lua`, `MapDetail.lua`, `Architecture.lua`, `MapRoutes.lua`, `WorldArt.lua`, `WorldFinish.lua`, `VisualPass.lua`, `CinematicWorld.lua`, `shared/MapLayouts.lua` |
| Enemy systems | `feature/dead-signal-enemy-systems` | `server/Enemies.lua`, `EnemyRigs.lua`, `HoundRig.lua`, `InfectedWardrobe.lua`, `Navigation.lua`, `WaveDirector.lua`, `shared/DirectorRules.lua`, `NPCPose.lua` |
| Combat & UI | `feature/dead-signal-combat-ui` | `client/Controller.lua`, `Scope.lua`, `AimAssist.lua`, `MobileControls.lua`, `UI.lua`, `shared/WeaponModels.lua`, `WeaponDetail.lua`, `WeaponBlueprints.lua`, `TouchInput.lua`, `TouchLayout.lua`, `ControlSettings.lua` |
| Audio & immersion | `feature/dead-signal-audio-immersion` | Audio-facing code within `client/Effects.lua` **only after integrator grants scoped ownership**; existing `SoundIds` / `Evolution.audio` contracts, audio tests and event inventory |
| Integrator | `integration/dead-signal-next-release` | Shared contracts, cross-domain fixes, combined candidate, validation; PR to `main` only after review |

**Shared / gated files:** `shared/Config.lua`, `server/Game.lua`, `Combat.lua`, `Interactions.lua`, `NavigationGraph.lua`, `client/Effects.lua`, `shared/Presentation.lua`, `shared/LoadingScreen.lua`, `PlaceConfig.lua`, plus workflow, pipeline, and deployment files. Workers must propose an explicit interface change to the integrator before editing these; preserve compatibility and add tests. The audio specialist may change only the sound-specific portion of `client/Effects.lua` after exclusive temporary ownership is granted and no concurrent Combat/UI edits are underway. The existing fixed 61-script lossless build may not include any newly added runtime script records. Tests under distinct new filenames minimize conflicts. If a worker needs a file owned by another lane, coordinate a reviewed contract rather than directly editing that lane. PR reviewers inspect actual changed-file lists.

## Branch and PR discipline
1. Start each Work thread from its named branch and record starting SHA; perform a brief audit of `main` and active PRs before coding. Never direct-commit to `main`.
2. One thread owns and writes to each branch. Commit in small logical increments, with `dead-signal` scope and tests. Keep changes in `games/dead-signal/dev/` unless agreed otherwise.
3. Open a PR to **integration branch**, not directly to production or `main`. The integrator may cherry-pick reviewed commits on its branch if GitHub PR targeting/ancestry is inconvenient. Document exact SHA, dependencies and test status. No worker may merge or deploy.
4. Integrator merges/rebases one lane at a time, resolves cross-file conflicts, runs full offline checks and lossless binary audits, then manually obtains owner approval for any private-staging publish. Record SHA of built candidates.
5. After human staging/playtest acceptance, integrator opens reviewed PR from integration branch to `main`. A **separate explicit owner authorization** is required for production. No worker, integration plan, or approved game design is itself permission to publish.
6. Once `main` advances, integrator coordinates rebase or integration updates. Never force-push a shared branch or overwrite another thread's pending work.

## Build and safety boundaries
- Current lossless RBXL patcher changes scripts and per-environment PlaceConfig inside verified full native v1.8 baselines while preserving all other binary records. **Do not assume it can apply edited native map meshes, terrain, models, or lighting.** Map team must first determine which elements are runtime-generated through source scripts versus static native instances; provide an explicit preservation-aware native-asset strategy if needed, with offline checks and Studio visual acceptance.
- Do not mutate `games/dead-signal/full-baselines/`, `games/dead-signal/places/*/{production,staging}.rbxl`, rollback files, `work-source/v1.8.0/`, secrets, live place IDs, production DataStore schema, or release workflows from worker branches.
- Never publish from worker branches, and never use an unreviewed scripts-only Rojo build to replace a complete place. Staging and production are separate universes; teleport IDs must be generated and audited per environment.
- The production workflow is **manual and main-only**. The current repo's `main` branch is not marked protected in GitHub metadata. Add branch protection/required checks through repository Settings when feasible; this protocol alone does not enforce rules.
- Baseline README text may describe older v1.8 states. Check live git refs, running Actions, latest PRs and the actual scripts before representing a feature as missing or implemented.

## Minimal PR acceptance checklist
- [ ] Scope, branch, starting SHA, change list, and cross-lane interface impact documented
- [ ] New/updated regression tests for normal and edge cases; CI green or specific blockers listed
- [ ] No production IDs/secrets leaked; no unsupported native assets/baselines rewritten
- [ ] Solo, 2-player, 4-player; first-person, mobile readability/input; collision/pathing/performance risk documented as tested or pending
- [ ] Evidence of offline tests vs actual Studio vs private Roblox client explicitly separated
- [ ] No claim of production/staging deployment without actual workflow logs and owner confirmation
- [ ] Reproduction/rollback notes and representative before/after screenshots or clips for visual changes
- [ ] Downed/revive, Warden, extraction, persistence, Dispatch teleports and loading-art regression impacts assessed

## Developer briefs
- [Main integrator](handoffs/MAIN-INTEGRATOR.md)
- [Map remaster](handoffs/MAPS.md)
- [Enemy systems](handoffs/ENEMIES.md)
- [Combat & UI](handoffs/COMBAT-UI.md)
- [Audio & Immersion](handoffs/AUDIO.md)
- [Approved Batch 1 — all 31 requirements](handoffs/BATCH-1-APPROVED.md)

## Newly approved Batch 1 and active-PR protection (2026-10-16)

The owner approved [Batch 1](handoffs/BATCH-1-APPROVED.md) **for development only**: 12 map items, 9 infected/AI items, 9 weapon/UI items and AUD-01. This batch follows—and must not silently overwrite—the earlier active PRs: #21 map remaster, #19 enemy recovery, #20 combat/UI, #18 loading-preview tooling. The same existing three Work chats may continue as specialists, but they must check whether their previous PR is merged before starting new changes. The new AUDIO DEV is a **separate fourth specialist** and uses its newly created feature branch.

**Follow-up strategy:** New Batch 1 edits should be placed on their own follow-up branches (ideally based on the relevant current parent PR head if not yet merged), with their parent PR dependency declared. Stacked PRs may first target the parent branch and later retarget the integration branch after the parent merges, or may wait for integration; the integrator chooses. Do not change parent PR content, rebase someone else's active branch, force-push or claim independent mergeability for stacked work. Audio is independent except for shared contract gates.

**Architecture:** `client/Effects.lua` currently contains the only existing central `FX:sound(key,position)` implementation, and audio config exists within `shared/Config.lua`. Preserve current callers; design a backwards-compatible, named event contract instead of duplicate sound systems. Avoid introducing another runtime script while the lossless patcher is locked to its known 61 target names. Coordinate map sound zones, infected animation cues and weapon timing through main integration. All audio recordings/assets must be creator-owned or rights-cleared; document stock fallbacks and asset permissions.

This planning approval does **not** approve publishing, uploading new user-owned assets, changing Roblox place IDs, removing backups, or rewriting active release workflows.
