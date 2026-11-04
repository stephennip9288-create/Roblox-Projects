# Batch 1 audio release status — November 3, 2026

Owner accepted the latest combined private-staging build in actual gameplay (Issue #37 comment6403467780). Reviewed production game source is `c2d4fb020c3893cae569d346d2886862d8fe8401`. Production publication and production listening remain pending the owner's manual release.

## Approved bindings

| Event or component | Recording | Asset ID | Binding |
| --- | --- | --- | --- |
| Board.Break | board_fracture_1 | 121376790132442 | Alternative at confirmed board removal |
| Board.Break | wood_break_1 | 91133693743569 | Alternative at confirmed board removal |
| Enemy.Entry.Contact | window_contact_1 | 128395906553592 | Contact alternative |
| Enemy.Entry.Contact | frame_scrape_2 | 126280091004313 | Contact alternative |
| Unbound component | wood_debris_1 | 117834744541770 | Awaiting a suitable event contract |
| Unbound component | wood_stress_3 | 117522141638495 | Awaiting a suitable event contract |

Enemy.Entry.Land retains its separate approved landing bank. No new triggers, duplicate layers or stress/debris loops were introduced. Original84 recording records, historical templates, reload banks, spatial/near-far mix, limits, warning priorities, settings and cleanup remain intact. Production activation is restricted to universe10770732078 and preserves the accepted staging10771141095 behavior exactly.

All88 bound recording IDs independently returned `Already added` in production experience Permissions > Assets on October25. The two unbound components are not claimed as production-bound permissions. Owner approval of all six isolated supplemental samples remains recorded; no repeat approval is needed.

## Evidence and remaining checks

Exact source passed all five required CI families,39 Luau suites/1,071,963 assertions,61 compilations,28 Python audio tests(2 optional-input skips), eight staging/production native build/fidelity checks and488 embedded source/config comparisons. Production permission evidence is in `batch-1-production-audio-permissions.json`; exact build/CI/rollback pins are in `batch-1-production.json` and its linked history.

The11 specialized break-action, revolver and energy-mechanism reload stages retain tested silent-skip behavior as known recording gaps. These supplements do not close those gaps.

After a successful production deployment, verify actual asset loading/permissions, event timing, material fit, crowded waves, available mobile-speaker/headphone output, mute and repeat-session cleanup. Owner staging acceptance is broad actual gameplay signoff; it is not fabricated independent exhaustive device coverage or production playback evidence. Preserve player data and `DeadSignal_Profile_v1`. Batch2/3 changes are excluded.
