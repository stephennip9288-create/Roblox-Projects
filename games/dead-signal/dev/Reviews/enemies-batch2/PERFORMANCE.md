# Performance evidence — policy only

Actual retained rigs across seven profiles, the real Station room graph, 40 active actors at round 40 and 400 AI ticks / 60 virtual seconds. Controlled two-tick native latency, all native results NoPath and solid-wall LOS. This measures source policy execution only: native path computation, physics, networking, rendering and devices are excluded. Cold model creation and first-tick cache work are included separately, not concealed in steady percentiles. No native FPS acceptance is claimed.

| Diagnostics | Mean ms/tick | Median | p95 | Cold-inclusive maximum | 40-rig construction ms |
| --- | ---: | ---: | ---: | ---: | ---: |
| Off | 7.54 | 8.43 | 13.49 | 86.65 | 211.58 |
| On | 7.56 | 8.44 | 13.34 | 95.92 | 211.44 |

Both modes serve all 40 actors, with at most three outstanding native paths and 474 requests over 60 virtual seconds (global 12/sec admission + burst4 never exceeded). Structural plans are capped at four per rotating AI tick. No actor, HP, quota or root position is changed to resolve stationary failure. Diagnostics off allocates no event ring; on retains at most 128 events and snapshots at most 40 actors, 16 native + 16 structural points per actor. The optional Studio overlay pools 40 labels and 24 point/line pairs at 2 Hz and displays average path requests/sec.

The cold-inclusive peak is a material remaining performance risk to measure in Studio, along with native ComputeAsync/navmesh cost, crowd collisions, multiplayer replication and low-end animation/rendering. Do not interpret the p95 policy measurement as total frame time. See `STUDIO-VERIFICATION.md` for desktop/Android/iOS and 1/2/4-client acceptance.
