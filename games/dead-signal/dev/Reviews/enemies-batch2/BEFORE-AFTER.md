# Source comparison, not a gameplay clip

The accepted Batch 1 implementation remains the baseline. No Batch 1 visual/model rewrite is included. These comparisons describe executed code/geometry fixtures, not an observed Studio animation or navmesh result.

| Trigger | Accepted baseline / reproduced gap | Batch 2 source behavior and evidence |
| --- | --- | --- |
| Native service reports Success with a waypoint through a wall | The exact `7aaf323` Navigation/Graph negative control commands that unchecked waypoint. | `enemy-b2-navigation` rejects the segment, holds its current location, retains HP/modifiers/quota and resumes when the obstruction clears. |
| Survivor in another room | Structural graph was used primarily after repeated native failures. | Normal pursuit targets successive real portal/stair legs. Direct movement requires a supported segment with retained body depth, lateral silhouette and head clearance. |
| Locked target / late path result | No semantic room-state gate on native pursuit acceptance. | Reachability selects an accessible survivor; closed gates/locked rooms are checked before movement; changed map/access/target discards asynchronous results. |
| Prolonged entered stuck state | General recovery could relocate an entered actor to an exterior entrance. | Entered pursuit replans, temporarily avoids failed nodes and reacquires targets. No actor retirement, HP reset or exterior relocation. Existing root-loss/out-of-world and window recovery are retained. |
| Crowded portal | No progress-renewed FIFO lease for normal room pursuit. | Bounded door reservation expires when its holder stops progressing; all 40 persistent waiters receive a turn in the controlled regression. |
| Awareness | No new-detection-specific R6 look pose. | LOS/life/access/distance gated detection produces capped 0.85s neck/upper-body motion; attack/traversal/hit/stun take priority. AUDIO consumes fresh run/target attributes. |
| QA | Existing general status lacked room-route legs, access failures and bounded event history. | Opt-in Studio snapshot includes target room/route/native waypoints, blocked doors, progress/stuck duration, request/replan/recovery counts and the last 128 trace events. |

Reproduce the first row by extracting the two accepted modules from `7aaf323` into `Validation/EnemyB2/BeforeSource/{server/Navigation,shared/NavigationGraph}.lua`, then running `lune run Tests/enemy-b2-navigation.luau before`. The after case uses the same blocked native response in the default test. No production assets or historical evidence are changed by this procedure.

Native screenshots/video of the look pose and actual movement remain required; see `STUDIO-VERIFICATION.md`. No generated mockup is offered as visual proof.
