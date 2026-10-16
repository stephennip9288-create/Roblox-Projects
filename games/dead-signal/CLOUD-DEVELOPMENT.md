# Dead Signal cloud development workflow

**Current stable baseline:** Four verified `.rbxl` staging places in `games/dead-signal/places/`, successfully published via the manually dispatched `Publish Roblox Place` GitHub Actions workflow. This is a historical working baseline; new changes still need in-game testing.

**Editable source:** `games/dead-signal/dev/`, copied from the v1.8.0 Work-thread development candidate. Historical import: `games/dead-signal/work-source/v1.8.0/`.

**CI:** `.github/workflows/dead-signal-source-ci.yml`. Uses Lune 0.11.0 and read-only GitHub permissions, no Roblox secrets. Testing does not publish a game.

**Safety:** `scripts/generate_dead_signal_place_configs.py` reads actual `deploy.json` files and generates separate `PlaceConfig.lua` artifacts for both staging and production with cross-universe and cross-place checks. It does **not** modify published `.rbxl` files. The original Work source contains production IDs; do not copy these unchanged into staging.

## Codex workflow

1. Select private repo `stephennip9288-create/Roblox-Projects` and begin on a new feature branch.
2. Work only in `games/dead-signal/dev/` plus new tests/docs as needed.
3. Open a PR; GitHub runs source CI and Python pipeline validation.
4. Review test reports. Lune suites use **current baseline staging .rbxl files as temporary fixtures**; they are not newly built playable places.
5. Build/asset parity and full Roblox Studio/client gameplay tests are required before publishing new source-derived binaries.
6. Production publishing remains manually approved and is never part of this CI.

## Next uncompleted milestone

Implement a candidate builder that composes current editable modules and full baseline place assets *without* deleting maps, terrain, art, lighting, or teleport configuration. Keep it artifact-only until parity analysis and user approval. Then validate in four-place private staging before considering any production update.
