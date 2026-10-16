# Dead Signal — four-place onboarding

**Status: eight binary place files are in GitHub (staging and production copies for all four places).** Configuration is still incomplete: only inactive `deploy.example.json` templates are present, and no active `deploy.json` manifests have been committed. API-key secrets cannot be inspected here. The failed publish run stopped before any Roblox upload.

## Confirmed place layout

| Repo place slug | Existing live place | Function | PlaceConfig role/map |
|---|---|---|---|
| `dispatch` | Dispatch (start/lobby) | Lobby, 24 player capacity | `Role="Lobby", Map="Station"` |
| `blackwater` | Blackwater Station | Round-based operation, 4 players | `Role="Match", Map="Station"` |
| `cinderworks` | Cinderworks | Round-based operation, 4 players | `Role="Match", Map="Foundry"` |
| `whiteout` | Whiteout Relay | Round-based operation, 4 players | `Role="Match", Map="Frost"` |

## Phase 1: back up CURRENT live game, do not replace

On Windows, open **Creator Dashboard > Dead Signal > Places > Edit in Studio** for **each of the four existing places**. Stop play. Use **File > Save to File** or **Download a Copy**, save to separate clearly named `.rbxlx` or `.rbxl` files, and reopen each local file to check it contains the full Workspace, scripts, lighting, and assets. Never substitute an earlier generated kit for a newer live place unless intentionally rolling back.

Record the **production Universe ID** once from Dashboard, and each of the **four distinct production Place IDs** from Dashboard > Places. Place IDs are NOT Universe IDs.

## Phase 2: independent staging experience

In Roblox Studio create an entirely **new private experience** named `Dead Signal - Staging` (not a new place in the existing public Dead Signal experience).

Publish a copy of Dispatch as its **start place** in that staging experience. Add three additional places within the **same staging experience** by opening the other saved place files and selecting **File > Publish As > Dead Signal - Staging > Add as a new place**. Name them Blackwater Station, Cinderworks, Whiteout Relay. The new staging experience now has **one staging Universe ID** and **four new staging Place IDs**.

Update staging copies ONLY: In **each** staging place, edit `ReplicatedStorage > DeadSignal > PlaceConfig` so `LobbyPlaceId` and `MapPlaceIds` use all four **staging** Place IDs, not production IDs. Confirm `Role` and `Map` match the table above; keep `Config.ProfileStore` identical between the four staging places. Because staging is a separate universe, its DataStores are isolated even if the store name matches. Re-check any matchmaking, developer product, gamepass, asset ownership, cross-experience URLs, or purchase prompts that assume live IDs, and disable purchases in staging until verified. Do not run the original v1.5 `Configure-Places.lua` against staging without filling in the staging IDs first.

Use File > Save to File **again** after configuring each staging place; those files are the **staging source files**. Separately retain the unmodified **production backup** files. Do not mix them. Publish all four staging places from Studio once, to install initial maps and verify configurations.

### Source filenames in GitHub

Use one folder per place, with two *distinct complete-place files*:

- `games/dead-signal/places/dispatch/staging.rbxl` and `production.rbxl`
- `games/dead-signal/places/blackwater/staging.rbxl` and `production.rbxl`
- `games/dead-signal/places/cinderworks/staging.rbxl` and `production.rbxl`
- `games/dead-signal/places/whiteout/staging.rbxl` and `production.rbxl`

The current GitHub files use the binary `.rbxl` format, and the inactive `deploy.example.json` templates now reference that extension. Browser uploads on GitHub are limited to 25 MiB per file; check sizes before uploading. Do not commit generated secrets, access tokens, or keys.

The current starter publishes **one place per manual run**; it does not automatically promote four places together or rewrite teleport IDs. Staging and production source files are intentionally different.

## Phase 3: four deployment manifests

In each place directory, copy the **existing local `deploy.example.json`** into **`deploy.json`**, keeping the existing `staging.rbxl` and `production.rbxl` source paths and filling in both environments' Universe ID and Place ID for that place. Each staging entry shares one staging Universe ID; each production entry shares one production Universe ID. Place IDs differ between places.

**Do not commit a `deploy.json` manifest until both complete source files exist and all IDs are verified.** The validation workflow will reject missing files and placeholder IDs.

## Phase 4: cloud credentials

1. In Creator Dashboard > API Keys, make **DeadSignal-Staging-Publisher** with `universe-places` / Write, restricted to **Dead Signal - Staging**.
2. In GitHub > this repo > Settings > Secrets and variables > Actions > New repository secret, paste it under exact name `ROBLOX_STAGING_API_KEY`.
3. Later, **only after staging succeeds**, make a second key restricted to **live Dead Signal**, and save as `ROBLOX_PRODUCTION_API_KEY`. Never paste API keys into chat or commit them.
4. GitHub-hosted runner IP addresses are dynamic. If API key IP restrictions are enabled, you must provide an allowed runner egress strategy; otherwise leave IP restriction disabled and compensate with minimal key scope, secret storage, and rotation.

## Phase 5: test publish, safely

Run **Actions > Validate Roblox Cloud Project** and confirm passing. To test a staging deploy, open **Actions > Publish Roblox Place > Run workflow**, choose the main branch, enter `game=dead-signal`, `place=dispatch`, and `target=staging`. Leave production confirmation blank.

Once a staging publish succeeds, test all four places through the pipeline one at a time. Play the staging experience in the **Roblox application**, not Studio, to verify Dispatch -> map travel -> extraction -> return, solo and multiplayer. TeleportService doesn't operate in normal Studio play tests.

For production, the action requires main branch, manual `production` target, and exact word `PUBLISH`. Do NOT enable production until the maps/teleports and assets work in staging, code/assets are reviewed, and live backups are available.

## Caveats and follow-up automation

- Cloud place publishing may not update certain Roblox instances, including EditableImage, EditableMesh, PartOperation, SurfaceAppearance, BaseWrap. Use Studio publishing when those modified instances need it.
- Current pipeline imposes a **conservative 10 MiB place-file cap**, which is a starter implementation limit, not a claimed Roblox-wide hard limit. Contact us if any actual export exceeds it before attempting to publish.
- The file-based workflow can safely upload complete places without Studio running, but won't let Codex easily edit those full binary place files. For fully automated *game development*, the next phase is to migrate each place to complete editable Rojo-managed source/assets; Rojo 7.7.1 has a `syncback` migration feature. Validate round-trip parity before switching the manifests to Rojo.
- Roblox assets with ownership restrictions and marketplace configuration might require separate upload/verification.
- **Do not use one staging and production place file** because teleport destinations would be wrong; each target needs a distinct source as enforced in the validator.

Official documentation:
- https://create.roblox.com/docs/projects/place-files
- https://create.roblox.com/docs/production/publishing/publish-games-and-places
- https://create.roblox.com/docs/cloud/guides/usage-place-publishing
- https://create.roblox.com/docs/cloud/auth/api-keys
- https://create.roblox.com/docs/projects/teleport
