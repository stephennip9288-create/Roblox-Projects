# Incoming Work-thread source packages

Upload the **source-only** archive `DeadSignal-v1.8.0-Work-Source-Import.zip` to this folder using GitHub > Add file > Upload files. It was prepared from the user's latest located Dead Signal Work-thread release, `DeadSignal-v1.8.0-Pursuit-Overhaul-Kit.zip`.

Next, use Codex Cloud (connected to this private repository) with this task:

> In the Roblox-Projects repo, inspect `games/dead-signal/imports/DeadSignal-v1.8.0-Work-Source-Import.zip`. Validate that every ZIP member stays below `games/dead-signal/work-source/v1.8.0/`, then extract it to those exact repository paths on a new feature branch. Review `IMPORT-MANIFEST.json` and commit all extracted code, tests, tools, and documentation. Do not alter `games/dead-signal/places/`, active `deploy.json` manifests, publish workflows or Roblox API keys. Do not publish or trigger Roblox workflows. Delete the temporary ZIP from the feature branch after extraction and open a pull request for review. The Work source is a development candidate, not a full Rojo world-build project. Specifically, do not deploy source place configs containing production teleport IDs into staging.

After the PR is reviewed and merged, the editable source will be in GitHub for Codex tasks. A **separate**, parity-tested, complete-place source build is required before switching deployment from the known-working `.rbxl` files to Rojo.

No automated deployment is triggered by adding a source ZIP or merging the source snapshot. Only the manually dispatched publishing workflow can publish a Roblox place.
