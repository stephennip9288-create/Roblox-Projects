# Dead Signal v1.8.0 — controlled private staging rollout and rollback

## Rollout scope

**ONLY PRIVATE STAGING** Universe ID `10771141095`. This does not modify production Universe `10770732078`, its 4 place files, its keys, or any production publishing workflow.

The single four-place rollout job publishes **Blackwater**, **Cinderworks**, **Whiteout**, and **Dispatch last**, after running all source, binary-fidelity, environment isolation, and rollback checks. It uses the *existing* GitHub secret `ROBLOX_STAGING_API_KEY`; the production key is not referenced.

The rollout uses one of two explicit authorizations:
- Reviewed one-time `games/dead-signal/rollouts/v1.8.0-private-staging.json` on a merged push to `main`, which triggers a single staging-only deployment.
- Manual [Dead Signal Controlled Private Staging](https://github.com/stephennip9288-create/Roblox-Projects/actions/workflows/dead-signal-private-staging.yml) on `main`, choose `deploy` with confirmation `DEPLOY-PRIVATE-STAGING`, or `rollback` with `RESTORE-PRIVATE-STAGING`.

**Do not trigger the ordinary `Publish Roblox Place` workflow concurrently** with this four-place rollout. It uses a different concurrency group, so simultaneous manual runs could race.

## Recovery

The rollback source is the four previously confirmed working staging binaries committed to `games/dead-signal/places/{dispatch,blackwater,cinderworks,whiteout}/staging.rbxl`, not the unverified v1.8 Work files. The rollout verifies their script PlaceConfig does not contain production place IDs, makes a checksum/ID backup manifest, and archives that manifest before any upload.

If any rollout upload fails, the job attempts to re-publish **all four** original staging files, including a timed-out or ambiguous in-flight upload. Failure to restore any place is a critical manual-intervention alert in `PUBLISH-RESULT.json` and GitHub Actions logs. A green rollout only means Roblox accepted four uploads; it does **not** mean gameplay works.

If publishing succeeds but gameplay fails: open the linked workflow, choose **Run workflow**, branch **main**, operation **rollback**, confirmation exactly `RESTORE-PRIVATE-STAGING`, then run it. It verifies the old binaries without depending on any newly generated v1.8 candidate artifacts. Confirm all four restored versions from the log before testing the old game again.

The committed originals are our rollback baseline, but they are not a live download of whatever version was on Roblox immediately before the rollout; concurrent external edits to the staging places may not be reflected in them. Avoid independent Studio/Roblox publishing during the test window.

## Staging smoke tests (Roblox client, not just offline CI)

**Do these after the staging-only workflow reports all four publishes successful:**

1. Open the **staging** Dead Signal experience, not the public production game. Verify Dispatch's 3D lobby, player spawn, GUI and map choice.
2. Launch a Blackwater match and verify players load *into staging Blackwater* (no teleport to the production universe); reach a playable round.
3. Launch Cinderworks and Whiteout in separate tests, checking themed maps, spawn, scripted interactions and waves.
4. Run with **at least two real clients** in the same match: downing, revives, joins/leaves, zombie targeting between rooms, no invisible safe spots, extraction, and returning to Dispatch.
5. On mobile, test movement/camera, weapon firing, aiming/ADS, interacting, revives, HUD overlap and performance, especially hectic enemy waves.
6. Confirm enemies (zombies/hounds/crawlers) route sensibly and do not stick at room centers, face backwards, collide incorrectly or stack. Confirm weapons and UI load without errors.
7. Verify Roblox client and server logs for runtime errors, and observe any broken asset meshes/materials or Terrain changes.
8. Test both a normal successful extraction and a failure/last-survivor return to the lobby; test reentry.

**Decision gate:** If any major regression or unintended production teleport appears, roll back private staging via `rollback` immediately and report the log/screenshots. Never promote to production merely because the GitHub CI passes.

## Development status distinction

This is **v1.8.0 Work development candidate** source, original native Work world files, and generated staging-only PlaceConfig, built with a script-Source-only binary patcher. Offline preservation confirms the Work binary's non-code chunks remain byte-identical; it does not establish parity with the earlier staging world's map, physics, NPC AI, UI, assets or multiplayer behavior.

The user must verify a real Roblox session before we mark the build as accepted. Production remains unchanged unless separately and explicitly authorized.
