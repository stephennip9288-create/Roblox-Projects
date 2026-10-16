# Updated approach — direct Work source import is preferred

A newer Dead Signal **v1.8.0 Pursuit Overhaul** Work package is available in the user's ChatGPT file library. It includes editable client/server/shared Lua modules, tests, and tools. **Do not continue the experimental Rojo `syncback` workflow just to recover scripts.** The prior syncback failed at its Y/N confirmation and is now unnecessary for recovering code.

A source-only import archive has been prepared, to upload into [imports/](imports/README.md). Once uploaded, use the instructions there to have Codex Cloud extract and commit source on a feature branch, review it, and keep the validated .rbxl publishing pipeline unchanged.

This direct import gives Codex editable source code immediately, **not** yet a fully source-managed playable Roblox place. The v1.8.0 development candidate was validated offline but not certified through Roblox Studio, so do not overwrite staging or production place files with it as-is.

---

## Earlier optional syncback experiment (reference only)


The initial staging publishing milestone has been verified for **all four places**. Full `.rbxl` binary files are the current known-working deployment artifacts.

## Phase A — Extract editable code

Run [Extract Dead Signal Sources (No Publish)](https://github.com/stephennip9288-create/Roblox-Projects/actions/workflows/extract-dead-signal-sources.yml) from Actions, selecting **dispatch** first.

The manually triggered workflow:
- Reads only `games/dead-signal/places/<place>/staging.rbxl`.
- Runs the version-pinned Rojo `syncback` on the normal script-bearing services.
- Packages the extracted files as a workflow artifact in GitHub Actions (no repository commit).
- Does **NOT** access Roblox Open Cloud, any API key, or the live production experience.
- Does **NOT** publish, alter, or replace the known-good binary place files.

Download the artifact and review `EXTRACTION_REPORT.json`, Lua/Luau scripts, data models, and any `.rbxm` fallbacks. If extraction fails, inspect job logs and adjust source mappings. No live/staging game change occurs on failure.

The first pass intentionally excludes `Workspace`, `Lighting`, `SoundService`, terrain, and other world geometry. This means it is **NOT** a full-place backup or a deployable Rojo project.

## Phase B — Reconstruct a complete editable place safely

After code extraction is reviewed, plan a separate complete-world migration preserving Workspace, Terrain, visual models/meshes, lighting, sounds, UI, services and teleport configurations for **each** of the four places. Maintain separate staging and production build configurations to prevent real teleport ID leakage.

Compile candidate `.rbxl` artifacts using `rojo build`. Validate instance coverage, gameplay scripts, game data persistence, custom assets, and source-to-output changes against the original exported place. No automated promotions until visual, multiplayer, teleports, extraction and return tests match the known-good staging game.

## Phase C — Codex cloud editing + staged publishing

Only when candidate compiled places pass parity and multiplayer testing:
1. Put reviewed source files in version control.
2. Build complete artifacts in GitHub Actions.
3. Switch *staging* manifests to Rojo builds one place at a time.
4. Keep production on the original binary place source until the change is explicitly approved.
5. Enable Codex to propose source changes via PRs with CI checks, staged deployment and production approval.

Rojo documentation: https://github.com/rojo-rbx/rojo/releases (see v7.7 syncback).
