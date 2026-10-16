# Dead Signal — promoting v1.8 to production (NOT YET DEPLOYED)

**Do not run production until the v1.8 loading artwork fallback is deployed to and visually checked in private staging.** Earlier v1.8 staging gameplay worked, but a missing background was reported on Dispatch and map travel screens. The patch adds distinct original fallback themes for Dispatch, Blackwater, Cinderworks, and Whiteout if uploaded artwork is unowned, inaccessible, or still loading. This ensures a designed-looking load screen, **not a promise that the originally configured images will load**. For actual custom illustration/photo artwork, upload creator-owned images in Roblox and give the experience permission to use them.

## Production IDs are generated automatically

There is **no manual switch of PlaceConfig IDs**. The production build reads the existing `deploy.json` manifests:

| Place | Production Place ID |
| --- | --- |
| Dispatch | `92751255902679` |
| Blackwater | `88865473543027` |
| Cinderworks | `110963636700767` |
| Whiteout | `109169216914914` |

Production universe `10770732078` is entirely separate from private staging universe `10771141095`. Only `PlaceConfig.lua` differs between isolated staging and production builds; the other 60 runtime scripts are checked for exact equality. Unknown Terrain/asset records remain byte-for-byte unchanged relative to the original full Work v1.8 release.

## First-time GitHub setup

1. Open private repo Settings → Secrets and variables → Actions → Repository secrets. Add `ROBLOX_PRODUCTION_API_KEY`. Generate a **separate**, production-scoped Roblox Open Cloud API key granting only the required universe place publish/write permission to universe `10770732078`, with appropriate expiration and restricted network settings. **Never paste the key in a chat or commit.** Keep staging key separate.
2. Open Settings → Environments → New environment and name it `dead-signal-production`. Configure **required reviewers** and preferably restrict deployments to `main`. This provides a separate human release-approval gate in addition to the typed confirmation. The workflow can exist without configured protection, but for a real public release this is strongly recommended.
3. Ensure no other workflow or Roblox Studio user is modifying the public experience during the promotion. The rollback files are the previously committed `games/dead-signal/places/*/production.rbxl` files; **they are NOT a snapshot retrieved from Roblox at release time**. If live production was changed outside this repository, obtain/verify a fresh backup first.

## Deploy to production (only after final staging acceptance)

Open [Dead Signal Production Release (Manual Only)](https://github.com/stephennip9288-create/Roblox-Projects/actions/workflows/dead-signal-production-release.yml):

- Click **Run workflow**, choose branch `main`.
- Operation: `deploy`.
- Confirmation (exactly): `PUBLISH-V18-PRODUCTION`.
- Approve the `dead-signal-production` environment prompt if GitHub asks for approval.
- Check the GitHub run: 48+ tests, Lune suites, four staging/production candidate builds, original asset preservation, production-only teleport IDs, backup manifest artifact, then published versions of Blackwater → Cinderworks → Whiteout → Dispatch last.
- Do not infer game acceptance merely from a green job. Test all map teleports, DataStore profiles, purchases/credits, extraction, mobile fire/ADS, and asset loading in the actual public Roblox experience.

## Roll back production if required

In that same workflow select operation `rollback`, confirmation `RESTORE-PREVIOUS-PRODUCTION`, on `main`. It restores the **four previously committed production RBXL files** and does not require the v1.8 candidate builder to work.

If an upload fails mid-deploy, the workflow attempts automatic restoration of all four old production files. Review failure logs and `PUBLISH-RESULT.json`; partial restore failure requires urgent manual intervention. Roblox deployments aren't an atomic four-place operation. Production DataStore changes to player records cannot be undone by re-publishing old place binaries.

## Safety and scope

- The workflow is **manual only**, has no `push` or `pull_request` publishing event.
- It reads `ROBLOX_PRODUCTION_API_KEY` only in the final, authorized publishing step.
- The legacy `Publish Roblox Place` workflow **does not deploy this v1.8 source**: it copies old `production.rbxl` sources. Never use it to attempt the v1.8 promotion.
- Version numbers of the updated production places are unknown until Roblox returns them; do not invent them.
- The staging and production experiences remain separate and data persistence is backed by their own Roblox universes.
- Follow the [staging playtest checklist](STAGING-PLAYTEST.md), then decide whether to release to real players.
