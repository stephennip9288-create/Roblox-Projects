# Enemy systems: audit, fixes and integration acceptance

Branch: `feature/dead-signal-enemy-systems`. PR target: `integration/dead-signal-next-release`.
Starting source SHA: `1a5b9f3b811137b6881090ad634a13624d33dd71`; main, integration and this lane matched at the initial audit. No open PRs were returned by the initial repository check.

## Gap audit and resulting changes

The baseline already implements five named events, preparation announcements, capped rare modifiers, armor/seams/reactors, articulated variant silhouettes, Alpha coordination, charge/ambush warnings, delayed LOS blasts, bounded smoke/fire, environmental counters, special rewards and round evolution. These remain source candidates. Existing tests cover their offline construction and decisions; they do not certify native physics, presentation or device performance. This change does not reimplement those systems.

| Verified gap in the baseline | Change and regression coverage |
| --- | --- |
| A target could become downed, eliminated, a spectator, travelling, disconnected or lose its character while attacks/ambush preparation survived selection of another operator. | Central living-target eligibility and action cancellation; replacement characters also invalidate preparation. Cooldowns survive cancellation. New lifecycle suite exercises all six invalidation cases and character replacement. |
| A Stalker melee windup could finish after its ambush window; a Warden shock could remain suspended while no target existed and fire on revival. | Resolve strikes only in the permitted attack window against the current eligible target. Stop movement with no target; discard suspended shock preparation so revival receives a fresh warning. |
| Flank offsets followed every turn/movement of the player and could prolong circling. Obstructed charges immediately resumed normal attacks. | Lock each flank approach for at most 1.75 seconds, then pursue directly for a 2.5-second cooldown. Abandon blocked/stalled/reached offsets. Blocked charges take the existing 0.4-second recovery. A dead cached Alpha no longer buffs followers. |
| Enemies outside a blocked breach had no timeout; normal recovery applied only after entry. | After 16 seconds without entry progress, use the existing relocation/third-attempt retirement policy. Board tearing resets the progress clock. Retirement creates no kill credit, drop or blast. |
| Recovery assigned Health before restoring MaxHealth, which could clamp surviving health after crew scaling fell; special cooldowns reset. | Restore the original maximum first, then exact health. Preserve ability/precision cooldowns as well as existing armor, reactor, phase and hit-reward state. Test both broken and partially damaged plates through recovery with a lower fresh spawn maximum. |
| Successful but empty/jumping paths did not accumulate failure state; waypoint retrieval errors escaped handling; a shifted goal could bypass failed-refresh backoff. | Reject all unusable results, count failures, retain a usable old route, and honor retry backoff. Tests cover ComputeAsync/GetWaypoints errors, empty/jumping paths, fallback access, cancellation, dead NPCs and stale runs. Stale results skip waypoint work. |
| An empty configured event rotation attempted modulo zero. | Treat an empty event list as no special events. |

The initial 12 suites passed 11,678 assertions despite these gaps. The two new suites failed on the original code for retained preparation and missing path-failure accounting before the fixes were applied.

## Interface and migration impact

Runtime edits are restricted to `server/Enemies.lua`, `server/Navigation.lua` and `shared/DirectorRules.lua`. Tests use new distinct filenames and the existing runner. No gated shared files, map geometry, Combat/UI lane files, remotes, place IDs, workflows, saved-data schemas or native binaries change. There are still 61 runtime script files, so no new native script record is needed by the existing lossless patcher.

Three enemy-owned tuning fields are added to `DirectorRules.tuning`: `flankSeconds = 1.75`, `flankCooldown = 2.5`, `entryRecoverySeconds = 16`. Existing Config and event payloads remain compatible. Charge/ambush pose timers reset to zero on cancellation; already-delivered warning effects expire normally. Save migration: none.

Map integration must preserve the existing contract:

- `map.model` contains physical route obstructions; `map.floorParts` includes reachable floors, ramps and galleries for downward casts. Decorations must not masquerade as walkable floor.
- `map.navigationRevision` increments when doors or routes change. Existing `NavigationGraph` room/door/portal data must reflect the remastered connectivity, unlock state and elevation. Native paths pursue live targets; graph nodes are recovery hints.
- Each breach supplies `inside`, `outside`, `room`, `part`, `count`, `boards`, `nextTear` and optional `nextEntry`. Entry slots need solid floor and clear body volume for ordinary, Alpha and Ironbound agents; players and live enemies must not overlap the selected slot.
- Preserve the `DeadSignalEnemies` and `DeadSignalShots` collision/query behavior. Variant navigation radius/root clearance remains derived from the actual rig attributes.

No shared-system approval is required for this diff. Any remaster requiring a changed graph schema, collision policy, new navigation primitive or client telegraph payload must be proposed to the integration lead before editing gated files. Merge/rebase the lanes one at a time and rerun combined tests. Review the actual changed-file list against the lane rules.

## Reproduce offline verification

From `games/dead-signal/dev`, prepare the four temporary `Places/DeadSignal-v1.8.0-{Lobby,Station,Foundry,Frost}.rbxl` fixtures exactly as the existing source-CI workflow does, then run:

```text
lune run Tests/syntax.luau
python Tests/run.py --lune /absolute/path/to/lune --luau-compile /absolute/path/to/luau-compile
```

Lune is pinned to 0.11.0. Local result: 14 suites, 11,796 assertions; new lifecycle suite 70 and path-recovery suite 48; all 61 runtime scripts compile. Syntax-only validation compiles 85 source/test/tool files. Local fixtures were byte-verified copies of the branch's staging files; no native assets were rewritten or serialized back to them. The existing Lune Terrain-property warning is not a native terrain validation.

From the repository root, configuration isolation and synthetic lossless-patcher tests also pass (7 + 6 tests), and `python scripts/validate.py` validates all four manifests. Full cloud source, lossless patch/fidelity, staging preflight and production-readiness results belong to the exact PR revision and must be reviewed before integration acceptance. Passing these commands never authorizes publication.

## Remaining physical acceptance

Not run here: Roblox Studio, native pathfinding/physics, real multiplayer, audio/rendering review, phone usability, low-end-device performance or published travel. Capture clips and server/client output with the exact candidate SHA for these checks:

1. Test solo, two and four operators on all three remastered maps, both modes, lower floors/galleries/ramps, newly opened doors and dense furniture. All variants must reach survivors without pinning, jumping or repeated relocation/retirement. The finite retirement policy prevents a stuck wave; it does not prove a map has no safe-spot exploit.
2. Block a breached entry slot, then clear it; observe separation, continued boarding progress and bounded recovery. Window-vault animation/physics remains the existing implementation and needs visual acceptance.
3. Sidestep announced charge endpoints; rotate/move during flank approaches; block a charge; eliminate the Alpha; down, disconnect or travel with the selected target during both charge and Stalker warning. New targets must never inherit a prepared ambush. Check cover/no-cover approaches and escape after warnings.
4. Break helmet/chest independently, leave another plate partly damaged, then exercise navigation recovery after crew reduction. Inspect exact health, exposed seams, query surfaces, stagger cooldown and ragdoll collision on stairs/galleries.
5. Confirm five event announcements/preparation/cadence, rare-combination caps and special spawn quotas through down/disconnect/revive. Warden rounds and extraction retain priority; a revived operator must receive a fresh shock warning if no living target remained.
6. Chain more than eight hound/Volatile deaths with walls between victims. Each accepted blast needs its full warning and LOS; excess hazards must fizzle. Vent/suppression fields must affect current and future hazards independently. Verify clear/reset/extraction leaves no damage from an earlier run.
7. Compare normal/Low Effects at 40 live NPCs and eight hazards. Record path failures, server frame time, client FPS/memory, network activity and warning readability on the actual target devices. Existing caps remain 12 path requests/second, three concurrent paths and eight hazards; offline tests do not measure engine budgets.
8. Recheck downed/revive, event rewards, Warden phase caps, extraction holds, profile continuity, Dispatch/map loading art and four-place travel on the integrated candidate. Existing offline suites cover their logic but do not replace these checks.

Rollback: revert the scoped enemy change commit(s), rebuild with the existing lossless path and compare non-source records. No data migration or production asset rollback is required for this source-only PR. The integrator owns combined builds and review. Staging and production publication each require the owner's explicit authorization.
