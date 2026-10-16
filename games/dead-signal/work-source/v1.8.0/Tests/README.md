# Offline checks

Use Lune and optionally the Luau compiler. From the extracted kit:

```text
python Tests/run.py --lune /absolute/path/to/lune --luau-compile /absolute/path/to/luau-compile
```

The default run covers director policy, server combat/accounting, navigation scheduling, pursuit regressions, rig/collision/ragdoll construction, weapon geometry, arrival readiness and extraction. These execute delivered methods with Roblox datatypes and controlled services.

Mobile testing is deferred. The preserved `touch.luau` suite is excluded from the default run; it is available for later resumption. No actual phone usability or native input test is claimed.

`Support/RuntimeLoader.luau` provides offline authoring transforms and service doubles. Lune does not run Roblox physics, a native navmesh, real raycasts, teleports, animation replication or touch input. Tests of ragdoll construction are not tests of falling bodies.

`Validation/Build-Report.json` records file reopening and graph counts. `Preservation-Report.json` compares original art/material data and configuration with v1.7.0. `Geometry-Report.json` is a projected ground-space audit, not an engine test. Follow `STUDIO-ACCEPTANCE.md` for the remaining engine work.
