# Roblox Projects — cloud development starter

Private source repository for Roblox experiences, managed with Codex/ChatGPT, GitHub Actions, Rojo (where suitable), and Roblox Open Cloud.

**Current state:** Source-control setup only. No Roblox games, API keys, or place IDs have been configured. **Nothing will publish to Roblox automatically.**

## Safety rules

- **Do not replace an existing production place with a scripts-only Rojo build.** A complete-place Open Cloud upload replaces the entire place. Maps, terrain, lighting, models, and other instances must be included.
- Start with a complete backup of each place exported from Roblox Studio as `.rbxl` or `.rbxlx`.
- Configure an isolated **staging experience** with different Universe ID and Place ID before touching production. For multi-place games, configure *each* lobby/level/dispatch place independently.
- Keep API keys only in GitHub Actions secrets, **never in code, chat, or commits**.
- Production publishing requires a manually dispatched workflow from `main` and confirmation text `PUBLISH`. It is not triggered on pushes.
- Always playtest staging manually; successful upload and unit tests do not establish multiplayer gameplay correctness.

## Layout

| Path | Purpose |
| --- | --- |
| `.github/workflows/validate.yml` | Automatic tests and manifest validation, **no deployment** |
| `.github/workflows/publish.yml` | Manual staging or manually confirmed production publishing |
| `scripts/` | Place validation, preparation and Open Cloud upload |
| `games/` | One folder per game, then one folder per place |
| `examples/` | Inactive deployment manifest examples |
| `rokit.toml` | Rojo CLI toolchain declaration |

## Onboard your first Roblox game

1. Back up its complete places in Studio (`File > Save to File`); verify the backups open.
2. Create a separate unpublished/private staging experience and places with matching structure.
3. Choose one game and place; copy `examples/place.deploy.example.json` to `games/<game-slug>/places/<place-slug>/deploy.json` and fill in the real staging and production Universe/Place IDs.
4. Upload the matching **complete** place file, or supply an entirely source-managed Rojo project. Only a complete source-managed project should use `mode: rojo`.
5. Test the `Validate Roblox Cloud Project` GitHub Action.
6. Configure restricted GitHub Actions secrets `ROBLOX_STAGING_API_KEY` and `ROBLOX_PRODUCTION_API_KEY`, each with Roblox `universe-places:write` access to its own universe. Keep keys out of this chat.
7. Manually run `Publish Roblox Place` targeting **staging**, then thoroughly test it.
8. Only after approving results, manually target production from `main` and type `PUBLISH`.

**Limitations:** Existing binary place files cannot be edited as source code by Codex. Code-driven iterative development requires a complete Rojo-managed place or a verified process to assemble source edits with existing maps/assets. Open Cloud place publishing currently has a 10 MiB payload limit and limitations for certain Studio assets (e.g. EditableMesh, EditableImage, PartOperation, SurfaceAppearance and BaseWrap). Large/complex places may need a different publishing approach.

**Docs:** [Roblox place publishing](https://create.roblox.com/docs/cloud/guides/usage-place-publishing) · [Rojo](https://rojo.space/docs/) · [GitHub Actions](https://docs.github.com/en/actions).

The setup scripts are **scaffolding**, not a connected or tested production release system.