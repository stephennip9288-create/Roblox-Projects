# DS-B1-001 — owner-approved supplemental audio intake

The owner accepted all six uploaded recordings and confirmed access after being asked specifically about private staging universe **10771141095**: “I like all of those uploaded sounds. All have been granted access.” The earlier ID receipt is [QA comment 6355970139](https://github.com/stephennip9288-create/Roblox-Projects/issues/37#issuecomment-6355970139).

This follow-up records that acceptance and supplies a tested **proposal for MAIN-owned Config**. Runtime is unchanged by this PR. The current integrated/staged source remains `15b08518917482d737f60a7bd8f9c7b9c3bd0a06` until MAIN reviews/applies the patch, creates a new source candidate and follows the release controls. Do not repeat merged #54 or assume earlier staging authorization covers a changed source candidate.

| Accepted recording | Owner-reported asset ID | Proposed use |
| --- | --- | --- |
| board_fracture_1 | 121376790132442 | Board.Break variant: combined strike, fracture and debris |
| wood_break_1 | 91133693743569 | Board.Break alternative: simple fracture |
| window_contact_1 | 128395906553592 | Enemy.Entry.Contact variant |
| frame_scrape_2 | 126280091004313 | Enemy.Entry.Contact alternative; rough masonry source disclosed and owner accepted |
| wood_debris_1 | 117834744541770 | Approved component; no separate existing trigger, unbound |
| wood_stress_3 | 117522141638495 | Approved component; no separate existing trigger, unbound |

The board composite already includes debris. Each existing fact chooses one variant; no extra simultaneous layer, loop or predicted event is added. Window landing, all mechanical/reload banks and original 84 intake records remain unchanged. Missing break-action/revolver/energy recordings remain separate gaps. The other eight review candidates need not all be uploaded.

## Apply after MAIN review

`STAGING-CONFIG.patch` adds only a staging-universe guard with two bank assignments, immediately after the unchanged original 84-asset audition block. The exact base Config Git blob is `1c7a4dffde21e4cfd3d383d9a0304d06ceb585b2`. The helper refuses another base or in-place output. From the repository root, MAIN can review/apply with:

```sh
git apply --check games/dead-signal/dev/Reviews/audio-supplement-intake-b1/STAGING-CONFIG.patch
git apply games/dead-signal/dev/Reviews/audio-supplement-intake-b1/STAGING-CONFIG.patch
```

Or render a separate candidate from `games/dead-signal/dev`:

```sh
python Reviews/audio-supplement-intake-b1/prepare_bindings.py --source Source/Runtime/shared/Config.lua --output /tmp/DeadSignalSupplementalConfig.lua
```

MAIN must reconcile the deliberately exact Config/runtime ledger and audition guard tests for this new reviewed change, retain their historical original-84 locks, run the combined tests/build/fidelity gates, and prepare a new release candidate. This intake does not alter those MAIN-owned tests/ledgers or bypass them. No release control, place binary, production bank, profile or workflow is changed.

## Evidence and remaining acceptance

`OWNER-APPROVALS.json` distinguishes owner-confirmed isolated listening and reported staging access from independently unverified moderation, engine permission/loading and native gameplay/mobile acceptance. Historical null-ID templates and source inventories remain immutable; this new record carries the six reported IDs and original prepared-file hashes. Those hashes identify our source files, not a byte-for-byte verification of Roblox's transcoded assets. CC0 provenance remains in `../audio-corrections-b1/SUPPLEMENTAL-SOURCES.json` and its pinned recipes. No pitch/speed changes or new recordings are introduced.

The new Python audit checks IDs, owner confirmation, original hashes, the exact protected base and independently applies the patch in a temporary tree. The new Luau audit executes actual Config and Effects with the proposal, checks complete non-staging Config equality, unchanged other banks/settings, both variants at each existing event, spatial one-shots, mute, cold-load silence and teardown in normal/Low modes. The original four source/fixture inputs used locally match the current integrated Git blobs. See `VALIDATION.json` for results.

```sh
python Tests/test_audio_supplement_intake.py -v
lune run Tests/audio-supplement-intake.luau
```

Run native gameplay/mobile listening and asset permission checks after MAIN applies/integrates the source and a separately authorized candidate is available. Use the existing before/after checklist. **DS-B1-001 remains Open / unverified**. No merge, new asset upload or staging/production publication is performed by this intake.
