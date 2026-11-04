# Dead Signal - current Batch 1 production release preparation

The owner accepted the latest combined private-staging zombie, window, map and audio corrections in actual gameplay and requested production release. No new staging deployment is needed. Batch2/3 remain separate.

The reviewed game-source pin is c2d4fb020c3893cae569d346d2886862d8fe8401. Source#65, combined#44 and main promotion#67 are merged. Main retains its newer release safeguards, deployment records, native assets and player-data namespace. Final admission/runbook/recovery controls are reviewed in#66; require that PR merged and final main checks successful before owner dispatch.

See [the owner release procedure](../BATCH-1-PRODUCTION-RELEASE.md), [current audio status](BATCH-1-AUDIO-STATUS.md), batch-1-production.json and Issue#63 for exact inputs and evidence. Publication remains pending the owner's manual workflow and required production-environment approval. No production success or new place versions are claimed.

Current known-good production rollback remains game source1a5b9f3b811137b6881090ad634a13624d33dd71, successful production run38985770842 attempt4, Dispatch28/Blackwater22/Cinderworks21/Whiteout21. The exact original files were renewed in artifact13283390341 from no-publish run41744401356, ZIP SHA25685bdbbf6519bbe086bb8683a310f6c34d4a2c084a82585c28b16a7b4f1f7085f, expires2027-02-02T00:07:12Z. All four files match their original hashes, sizes,61-script inventory, production PlaceConfig and profile namespace. The trusted guard downloads and verifies the actual pinned archive and latest successful release; no historical fallback or rebuilding is permitted.

Current staging remains owner-run40054332185, game sourcef4a7d6ba0c6981a3ebe3679e64b5eea37e1dce2d, Dispatch20/maps16/16/16, recovery12545195246. Original84 asset records and source-specific staging QA evidence are retained. The prior phase README is preserved at history/release-readme-before-production-2026-11-03.md.

Use only the existing main/manual Dead Signal Production Release workflow with the reviewed c2 source and exact PUBLISH-V18-PRODUCTION confirmation after every gate passes. Preserve DeadSignal_Profile_v1 and all player data. After actual successful publication, record real four-place results, native gameplay/audio smoke checks and the new exact production recovery through review.
