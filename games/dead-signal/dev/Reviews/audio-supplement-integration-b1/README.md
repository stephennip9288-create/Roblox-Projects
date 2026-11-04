# Batch 1 approved supplemental audio — MAIN application

The prepared #59 patch is now applied to Runtime/shared/Config.lua. This directory is the current integration evidence; prior intake and follow-up reports retain their historical meaning. The exact candidate SHA is the containing source commit, recorded explicitly in draft PR #44 and Issue #37. **No staging or production publication is authorized or performed. DS-B1-001 remains Open / unverified.**

## Inputs and applied mappings

Started from verified integration/staging source15b08518917482d737f60a7bd8f9c7b9c3bd0a06. MAP#52, ENEMY#53 and AUDIO#54 were already merged and were not repeated. Reviewed #59 at c598b26dfa2bf45d74e80128f930325ab6156321 (eight new files, no Runtime changes, four automatic checks passing); merged as d9d82116d7d8bd9310cafb78c95d616ac5ded1fe. Applied its exact STAGING-CONFIG.patch separately; original Config blob1c7a4dffde21e4cfd3d383d9a0304d06ceb585b2 becomes88cccbed93fabff62c72c170a595ea7f6338216e.

| Existing bank | Accepted alternatives in universe10771141095 |
| --- | --- |
| Board.Break | board_fracture_1 /121376790132442; wood_break_1 /91133693743569 |
| Enemy.Entry.Contact | window_contact_1 /128395906553592; frame_scrape_2 /126280091004313 |

The existing Board caller selects Board.Break at confirmed board removal. Each fact selects one variant; no new triggers, simultaneous layers or loops. Enemy.Entry.Land remains separate. Approved wood_debris_1 /117834744541770 and wood_stress_3 /117522141638495 remain unbound. The owner accepted all six isolated samples and reports staging access granted; that confirmation is retained without requesting it again. Native loading/moderation and integrated listening remain pending.

Only one of the fixed61 runtime files changes. Original84 records/audition bytes, historical templates and runtime ledgers are unchanged. The additive [reviewed delta](REVIEWED-DELTA.json) records a patch application, rather than falsely attributing Runtime bytes to the proposal-only PR head. Runtime provenance enforces exact input/head/patch/bindings/approval/config hashes and reconstructs the exact old Config. Existing correction tests now exercise the actual applied banks; original84 guards and immutable evidence remain. The intake suite is registered in Tests/run.py.

## Local validation

| Gate | Result |
| --- | --- |
| Combined offline runtime | 38 suites;1,071,772 assertions; all pass |
| Required supplemental intake | 4 Python cases;417 actual Config/Effects assertions after application; pre-application proposal also passed417 |
| Python pipeline | 82 cases; all pass |
| Audio/provenance Python discovery | 25 cases;23 passed,2 optional-input skips; the14-PCM reproduction skip was separately resolved with pinned cached sources (6 correction cases all pass). Original84 prepared-WAV audit remains an optional skip |
| Compilation | 122 source/test/tool Luau files;61/61 runtime compiler passes |
| Binary source/fidelity/isolation | Four complete staging plus four production-preview places;488 exact source instances; eight raw property audits; byte-identical independent reproduction |
| Independent native file reader | Eight read-only reopens;61 exact sources each; native mesh/appearance/terrain inventories retained; no serialization |
| Preservation | 148 protected blobs unchanged versus15b08518, including pipelines, scripts, native baselines, archived source, all place/deploy files and release records |
| Negative provenance probes | Six disposable mutations rejected: extra Config edit, duplicate block, unrelated runtime edit, historical ledger edit, prior ledger edit and false intake head |

See [tests](TESTS.json), [build hashes](BUILDS.json), [native reopen](NATIVE-REOPEN.json), [protected blobs](PRESERVATION.json), and [negative probes](NEGATIVE-PROVENANCE-PROBES.json). Final automatic cloud checks and artifact digests are recorded on PR#44 / Issue#37 against the exact containing commit. No new automatic CI result is inferred from the local checks.

## Latest recorded staging and next release

The latest successful GitHub staging deployment remains39884224314, source15b08518, Dispatch19 / Blackwater15 / Cinderworks15 / Whiteout15. Re-read the successful job, exact source and returned versions. Current trusted main0d319dc86d3e2c1c78ae416488319cd5ab0acbce pins artifact12472042399, ZIP SHA256c1aec94bffd44f0a4f70bedd1246013ab89cc1b089727728298f5b40ee9f9698, expiring2027-01-21. Remote artifact availability/digest, cached ZIP CRC/digest, four member sizes/hashes and all244 source records match. This is pipeline provenance, not a fresh live Roblox download or verification of out-of-pipeline publications. See [recovery verification](RECOVERY-VERIFICATION.json).

The current deployment is still the predecessor; the new Config is not audible there. A release-control proposal must use this exact new source/artifact and retain that current rollback set. Publication requires separate owner authorization through the existing manual workflow; this handoff grants source integration/testing/preparation only. Active trusted records, owner authorizations, guard code, production assets and player data are unchanged by this source application.

Native checks remain [explicitly pending](ACCEPTANCE.md): asset loading/permissions/moderation, event timing and material fit, crowded waves, mobile speakers/headphones, mute, cancellation and repeat-session cleanup. The original11 missing break-action/revolver/energy phases remain unresolved; the six supplements do not supply those mechanisms. [Current14-candidate status](../batch1-1-followup/AUDIO-ASSET-STATUS.md) now distinguishes six uploaded/accepted samples, four candidate bindings, two unbound components and eight unuploaded candidates. All six Batch1 defects remain unverified. No Batch2 development occurred.
