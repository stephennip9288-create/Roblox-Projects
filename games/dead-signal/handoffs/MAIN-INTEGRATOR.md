# Dead Signal — Main Work / Integration Lead Handoff

You are the sole integration and release coordinator for the private GitHub repository `stephennip9288-create/Roblox-Projects`. Coordinate three independent Work feature branches: `feature/dead-signal-map-remaster`, `feature/dead-signal-enemy-systems`, and `feature/dead-signal-combat-ui`. Use `integration/dead-signal-next-release` for integration, and `main` only for reviewed final changes. Read `games/dead-signal/PARALLEL-DEVELOPMENT.md` and all specialist handoffs before acting.

**First task:** Audit current `main`, the named feature branches, merged loading-art PRs #15/#16, current GitHub Actions pipelines, place manifests and safety guards. The protocol was drafted against `2a7e99e36ccb36b941990c70e8d43a09b2ed131d`; never assume that remains the latest SHA. `main` already contains version-1.9 candidate evolution code; do not duplicate it. PRs #15/#16 merged during setup; review their newly added loading tests and production source-pin controls, and always confirm current status.

**Ownership:** Define/freeze contracts for shared `Config.lua`, `Game.lua`, `Combat.lua`, `Interactions.lua`, `NavigationGraph.lua`, `Effects.lua`, `Presentation.lua`, and similar cross-lane interfaces; review proposed schema/API changes first. Keep lane-specific edits in their branches. Manage integration order, risk register, merge conflicts, CI failures, candidate SHA hashes, and staging acceptance records. Do not ask different threads to edit the same large shared file concurrently.

**Integration sequence:** (1) make sure coordination docs PR is reviewed/merged; (2) verify current source and each worker PR's exact file diffs; (3) merge/cherry-pick in dependency order (map geometry -> enemy navigation -> combat presentation, as appropriate); (4) run all existing Python + Lune source and regression suites, config isolation, lossless source patch and binary fidelity checks for all four places; (5) for map native edits, verify the separate complete-world asset delivery strategy and parity before building any artifact; (6) perform actual Studio + private-client staging tests, not merely CI; (7) present findings to owner for staging approval; (8) after acceptance, prepare reviewed PR to main and request a *separate* explicit owner production authorization.

**Core compatibility:** 4 places; Dispatch -> 3 maps -> extraction/return; two game modes; Warden/extraction precedence; authoritative enemies and damage; mobile HUD/ADS; revive; currencies and persistent profiles. Preserve staging/production PlaceConfig isolation, native assets and production save schema. Do not overwrite currently released production with mismatched or scripts-only binaries. Keep historical backups untouched and verify rollback points correspond to the actual live release.

**Release gate:** You may review, test, merge *feature code into integration*, and prepare artifacts/PRs. Do not publish even to staging without the owner's explicit authorization, and never publish production without separately explicit authorization. No automatic deployment triggered by feature PRs. Maintain a short release note: merged SHAs, test evidence, visually tested items, known limitations, user actions and rollback.

**Deliver:** (a) shared-interface decisions, (b) combined integration PR / build report, (c) verified four-place staging acceptance checklist, (d) production-readiness recommendation—not an unapproved live deployment.

---

## Approved Batch 1 handoff — integrate FOUR specialist lanes (2026-10-16)

The owner has approved **all 31 requirements** in [BATCH-1-APPROVED.md](BATCH-1-APPROVED.md): MAP-01..12, EN-01..09, WPN-01..09 and AUD-01. **This is permission to develop and prepare review PRs only.** Staging publication and production release still require separate explicit owner approvals. Treat this batch as additional work *after* the previous Work round, not as retroactive authorization to release existing v1.9.

**New fourth lane:** **AUDIO DEV** uses `feature/dead-signal-audio-immersion` and [AUDIO.md](AUDIO.md). You are responsible for granting/denying its requested scoped control of `client/Effects.lua` audio path and defining compatible sound-event contracts across Maps, Enemies and Combat. If release patcher limits prevent new runtime modules, route implementation through existing script records or separately approve an audited toolchain upgrade; never silently append scripts to the 61-target patcher.

**In-progress PR gate:** On 2026-10-16 PR #21 (Maps), #19 (Enemies), #20 (Combat/UI), and #18 (Loading Preview) were open against integration. Recheck their current status, exact heads and diff/tests first. Evaluate and integrate those on their own merits **before** treating Batch 1 as an implementation of them. Preserve their tested state; avoid multiple workers editing their PR branch concurrently. New follow-up branches may depend on corresponding parent PR heads and must be rebased/retargeted after parent merges.

**Contract decisions to publish to workers before merging new Batch 1 code:**
- MAP -> EN: entrance/window/vent anchor schema, approach/landing points, path widths/vertical links, collision/safe spawn rules and geometry dependencies.
- EN -> AUDIO: semantic cues, enemy kind and context, world position, event timing for window entry, hound/Alpha charge, armor, ambush/explosion; no timing ambiguity.
- COMBAT -> AUDIO: mechanical and gun category cues, first-/third-person spatial routing, authoritative hit confirm, reload and weapon-swap event lifecycle.
- MAP -> AUDIO: room/zone identity and weather/world event source, transition priorities, local/ambient location, distant landmarks.
- Shared owner: Config/Game/Combat/Interactions/NavigationGraph/Effects/Presentation, tests runner, native asset builder, remote/schema changes and effects budgets; allocate ownership serially, not concurrently.

**Integration milestones:** parent PRs reviewed -> freeze contracts -> Batch 1 specialist PRs reviewed/dependency tracked -> offline integration and exact asset/script preservation audit -> Roblox Studio functional and aesthetics check -> explicit staging publish approval -> multi-place private client playtesting (solo, 2, 4 players on all maps, desktop/mobile/low effects, Warden/extraction/revive/profiles/loading art) -> owner acceptance -> separate production authorization. Include a detailed traceability matrix with each ID status (implemented/tested/pending/blocked), test evidence, build SHA, audio asset rights and rollback provenance.

**Do not claim that publishing these plans has started Work chats or implemented any features.** Users will dispatch each work thread; keep PR and merged commit as the durable cross-chat source of truth.
