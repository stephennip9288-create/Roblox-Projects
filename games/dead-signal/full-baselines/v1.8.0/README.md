# Original Dead Signal v1.8.0 Work place baselines

These complete native Roblox place files were extracted byte-for-byte from the Work-thread v1.8.0 Pursuit Overhaul Kit. They are a DEVELOPMENT CANDIDATE. They contain LIVE PRODUCTION PlaceConfig IDs, so NEVER publish them directly to staging or production.

Intended use: raw script-only binary patch tool reads these as immutable world/asset baselines, replacing only Script/ModuleScript/LocalScript Source PROP values with editable dev source and generated staging-only PlaceConfig. Offline results are artifacts only, subject to strict audit and Roblox Studio testing before any staging publishing.

Do not alter any file under games/dead-signal/places/ or deploy.json or workflows/publish.yml when importing. The four existing staging places remain the rollback baseline.

See IMPORT-MANIFEST.json for SHA256 hashes and upstream full-kit provenance.
