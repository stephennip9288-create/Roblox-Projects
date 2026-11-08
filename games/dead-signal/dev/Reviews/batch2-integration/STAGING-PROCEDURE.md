# Owner-controlled Batch 2 private-staging procedure

**Current admission: BLOCKED. No workflow has been dispatched.** The exact reviewed source and CI references are in `SOURCE-CHECKPOINT.json`; the main-trusted record is `games/dead-signal/releases/batch-2-staging.json`. Source integration and owner listening acceptance do not authorize staging publication.

1. Supply the remaining recording source/rights and creator/content evidence and verify each asset's moderation/playback eligibility. Keep the existing owner listening acceptance and verified 32 experience grants. MAIN applies only evidenced flags; if any runtime policy bytes change, MAIN reviews/pins a new source manifest, rebuilds/pins all eight outputs and reruns all five workflow families on the new immutable source. No automatic flag flipping or reused build hashes.
2. Review the final four-place candidate, native-fidelity reports, open native-QA checklist and exact rollback. The staging recovery must still identify the latest successful deployment, contain four verified native files and have more than 14 days remaining. Refresh through the existing owner-controlled process if required; never overwrite the previous known-good archive.
3. Give separate explicit authorization for that exact Batch 2 private-staging source. MAIN records its evidence, exact full 40-character source SHA, source-specific successful CI, complete audio gates and four staging build pins in the admission. The source record must remain production-unauthorized. An owner-approved controls PR must place the reviewed staging controls/admission on `main`; this integration task does not merge to main or dispatch a deployment.
4. On GitHub Actions choose **Dead Signal Controlled Private Staging**, workflow file `dead-signal-private-staging.yml`, **Use workflow from: main**. Enter **operation: deploy**, **confirmation: DEPLOY-PRIVATE-STAGING**, **source_sha: the exact full SHA in the approved Batch 2 staging admission**. Do not substitute an integration-branch name, latest branch head, old Batch 1 source or an unreviewed SHA.
5. The workflow checks main-trusted source admission, exact checkout and specialist ancestry, current CI, source/asset gates, current rollback, all offline suites, four lossless builds/fidelity and exact binary pins, then reinstalls trusted controls before upload. It uses only the staging key and universe, uploads Blackwater/Cinderworks/Whiteout first and Dispatch last, and retains the reviewed candidate and rollback manifest for 90 days. Any preflight failure stops publication. An upload failure triggers restoration of all four recorded staging files; inspect every rollback result before further action.
6. Verify all four deployment results and retain the run/artifact/version IDs. Update the current staging recovery record only after the successful deployed output is independently checked, preserving its predecessor. Perform the outstanding native/device/multiplayer and audio QA. Report actual results and defects; do not infer gameplay acceptance from CI or binary fidelity. Production requires a later, separately reviewed release and explicit owner authorization.

After those gates pass, the equivalent owner CLI is:

```bash
gh workflow run dead-signal-private-staging.yml \
  --repo stephennip9288-create/Roblox-Projects \
  --ref main \
  -f operation=deploy \
  -f confirmation=DEPLOY-PRIVATE-STAGING \
  -f source_sha=FULL_SHA_FROM_THE_APPROVED_BATCH_2_ADMISSION
```

The placeholder is intentional: the current record is not authorized and enabling the still-gated audio will require a newly reviewed source. MAIN must provide the resulting concrete SHA before the owner dispatches this command.

The existing owner-only recovery operation remains:

```bash
gh workflow run dead-signal-private-staging.yml \
  --repo stephennip9288-create/Roblox-Projects \
  --ref main \
  -f operation=rollback \
  -f confirmation=RESTORE-PRIVATE-STAGING
```

Rollback selects the exact recorded current staging recovery, with no new `source_sha`; it remains usable when candidate CI or audio intake fails. These instructions do not authorize running either command now.
