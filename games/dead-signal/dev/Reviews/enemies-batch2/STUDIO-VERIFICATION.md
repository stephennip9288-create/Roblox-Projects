# Batch 2 enemy native verification — pending

Source and convex geometry tests do not execute Roblox PathfindingService, Humanoid physics, network replication, animation rendering or phone GPUs. No native pass is recorded by this specialist. Run a disposable candidate built from MAIN's reviewed combined Batch 2 source. Do not save/publish a running QA place or use the tools against live play.

## Setup and evidence

1. Record the exact combined source SHA, RBXL SHA256, Studio version, device, player count, map, round, enemy mix and all relevant door states. Start a server with one, two and four clients. Repeat on desktop and physical Android/iOS with low effects.
2. In the **server** Command Bar, initialize the existing match normally, then use `local D=require(game.ServerScriptService.DeadSignalServer.Diagnostics); D.navigation(true)`. `D.navigation()` returns a bounded snapshot; `D.navigation(false)` releases its ring. A normal server must reject these calls. Diagnostics are off by default.
3. Optionally paste `Tools/diagnose-navigation-b2-studio.lua` in the running Studio server. The pooled overlay displays at most 40 actor labels, 24 points/segments, and updates at 2 Hz. Set `Workspace.DeadSignalNavigationReview.InspectEnemyId` to inspect an actor. Remove that folder to disconnect and disable diagnostics.
4. Capture screen recordings, server snapshots, MicroProfiler/pathfinding timings, script CPU and network/physics/render statistics. Compare diagnostics off/on. Record p50/p95 and spikes; the offline policy benchmark is not an engine frame-time target or mobile acceptance result.

## Required scenarios on Blackwater, Cinderworks and Whiteout

| Scenario | Required observation |
| --- | --- |
| Adjacent rooms separated by a solid wall | Enemy selects an accessible doorway/corridor, walks around the wall and resumes pursuit. No wall attacks or unchecked direct MoveTo. |
| Ground and upper floors; ascent and descent | Seven retained profiles fit the route, reach the intended floor and do not get pinned at landings, stair lips or overhead decks. |
| Locked/unlocked rooms and gates | Locked areas remain inaccessible; opening a gate permits pursuit. Close/reopen during pending native computation and reject stale routes. |
| Moving survivors / changed targets | Cross rooms/floors, reverse direction, down, die, disconnect, respawn and travel. No stale target roots, false awareness or stale path resurrection. |
| Narrow doorways / two directions of traffic | Converge 4, 12, 24 and 40 active actors, including Warden/Alpha. Waiters make progress without permanent starvation or oscillation; record lease churn. |
| Interrupted or blocked route | Temporarily obstruct a doorway, interrupt movement and force NoPath. Retry work stays bounded, alternatives and eligible targets are reacquired, and actors recover after the obstruction clears. |
| Windows / exterior admission | Repeat accepted Batch 1 approach, align, mount, vault/crawl, land and post-entry pursuit at densities 4/12/24. Interrupt traversal and change targets. No visible relocation, interior spawning or quota loss. |
| Combat and wave lifecycle | HP, armor/weak points, modifiers, kills, quotas and wave completion remain correct. Include Hellhound charges/packs, Stalker, all special waves, Warden, revive and extraction. |
| R6 awareness and audio | A real nearby visible survivor causes a subtle 0.85s head/body response and smooth pursuit. No reaction through walls or during attacks, traversal, hit/stun. Test look up/down and three variants. |
| AUDIO #70 integrated | `AwarenessTargetUserId`/`AwarenessRunId` arrive before fresh `AwarenessAt`. Only the intended local survivor hears the configured occasional cue. No duplicate Feed audio handler. Check asset permissions and actual audible playback. |
| Normal gameplay | No diagnostic folder/ring/trace allocation, route markers or QA controls. No new remote or runtime record. |

## Recording acceptance

Keep B2-03/B2-04/B2-08 pending native acceptance until the above clips and results are reviewed. If an avoidable path error still strands the final enemy, record the actor ID, target/room, selected leg, support/obstruction, retry/failure trace and exact source. Escalate a producer geometry defect to MAP DEV with that evidence; do not hide it by teleporting, deleting or decrementing wave quota.
