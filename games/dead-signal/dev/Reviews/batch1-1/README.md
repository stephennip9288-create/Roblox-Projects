# Dead Signal Batch 1.1 — integration intake checkpoint

**Status: coordination and recovery preparation are ready for review; no combined bug-fix candidate exists yet.** All six bugs are In Progress, with source PRs and staging retests outstanding. Nothing has been published by this work.

## Audited sources

| Item | Exact revision/evidence |
|---|---|
| Deployed Batch 1 / existing integration | 9743b3e9ee59ba74da0d5d9a5e3f2e378230d6f7 |
| Staging release | Run39056526660 / attempt1; Dispatch11 / Blackwater10 / Cinderworks10 / Whiteout10 |
| Patch coordination baseline / all three fix branches at intake | 206ae616a7de4fe8dd69b1c8019bae6ea8b6863d |
| Trusted main after recovery repair #38 | 4ecc43cc3642eb56fb6e70beff77064d174cbbfa |
| Recovery PR source | a035dab817e62e58cb0d4ce21f6907baf10c896b; all ten no-publish checks passed |
| Production remains | 1a5b9f3b811137b6881090ad634a13624d33dd71; original artwork hotfix |

Issue [#37](https://github.com/stephennip9288-create/Roblox-Projects/issues/37) records ownership, diagnoses and exact handoffs. No specialist implementation commit or open PR was present at this intake refresh. A source diagnosis or former temporary checkout is not a delivered fix.

## Completed integration preparation

- Reconciled trusted staging recovery to the actual successful Batch 1 artifact/run/versions in reviewed, merged #38; preserved its predecessor and unchanged production recovery. No runtime, workflow, ID or native binary changed in that PR.
- Created isolated Maps, Enemies and Audio branches plus integration/dead-signal-batch1-1. The final combined PR targets integration/dead-signal-next-release; completed Batch 1 branches are retained.
- Froze foot-floor/sill window geometry, actual rig bounds/collision/queue/recovery, semantic audio timing/lifecycle and exclusive shared-file contracts in [BATCH-1-1-FIXES.md](../../../handoffs/BATCH-1-1-FIXES.md).
- Clarified direct source checkpoints/draft PRs by each assigned specialist, avoiding dependence on temporary cross-thread filesystem paths. MAIN retains shared modules, runner, release selection, review and merge ownership.
- Added BUGS.json, native retest checklist, a Studio-only read-only entry diagnostic, and an informational blocked patch record. No bug is Verified.

## Recovery after session maintenance

Temporary workspaces were pruned. The current editable source was restored from the exact GitHub coordination revision; all 61 runtime records match their Git blob hashes. The original v1.8 native package was recovered and checked against archive SHA-256 ea9179dd9df9c68dba1d995f3ccbf0b199190eee8eac24573abdcfd2e09bfb10 and the repository's four native-baseline blob hashes.

The retained complete Studio package matches SHA-256 f40e3cb35adf87faa2853c8c93459cf9adbd2e6f141bf90ecff9c7872c49b2a7. Its four staging binaries match the actual deployed recovery record. The separately retained production package's four binaries also match production recovery hashes. Historical committed v1.7 rollback files remain on GitHub unchanged; they are not substituted with these newer recovery files.

Lune0.11.0 and Luau0.743 were recovered from official pinned releases with matching release asset digests. Restoration is not new gameplay acceptance or proof that the requested fixes are implemented.

## Bug coverage and handoffs

See BUGS.json for all six IDs, priorities, owners, likely causes and required evidence. Maps owns 003/004/005 plus physical entrance support for002; Enemies owns002/006; Audio owns001. Worker findings include reflected wall frames, actual wedge footprints outside logical cuts, missing exterior support/queue envelopes, failed-entry quota retirement and unsuitable sound substitutions. MAIN must review actual code and reproductions before accepting those fixes.

**DS-B1-001 remains a material release blocker:** appropriate authorized recordings, functioning sample activation and native permission/listening results must be supplied. Removing unsuitable sounds or preparing silent custom slots does not complete the requested realistic overhaul. Native model/physics/visual/device acceptance is also outstanding for the relevant bugs.

## Next integration sequence and tests

1. Receive source commits and draft PRs from all three owned branches; inspect exact diffs and test evidence.
2. Review Maps physical solids/mounts/dressing first, then Enemies against that exact map revision, then Audio/adapters. Resolve shared edits serially and register new suites additively.
3. Run all existing Python/Lune/syntax/runtime-compile suites plus corrective regressions; retain all31 approved Batch1 requirements. Cover all30 windows/seven profiles, actual wedge/body sweeps, dynamic occupancy and cancellation, audio load/lifecycle/caps, core gameplay and save/config isolation.
4. Rebuild through the existing lossless patcher; audit raw binary fidelity for all four staging and four production-comparison files; reopen all four staging candidates read-only; compare protected blobs and exact runtime source. Never serialize a replacement native world or use an incomplete build.
5. Produce the bug-by-bug combined report with exact PR/head/source/binary hashes, changed files, tests and limitations. Only then consider a reviewed trusted source-selection update and request new owner private-staging approval.

The prior 26-suite/998,937-assertion result is **Batch1 baseline evidence**, not a Batch1.1 pass. Current preparation CI does not fix that distinction.

## Release/rollback decision

**Hold Batch1.1 publication.** The informational batch-1-1.json remains ready_for_staging=false with no selected source. Trusted main batch-1.json still admits only the existing Batch1 SHA. No partial fix, stale candidate or source from a worker branch may be published. Production remains separately blocked.

If a future authorized complete patch fails, use the exact recorded successful Batch1 staging set (11/10/10/10), maps-first/Dispatch-last, through the existing controlled rollback workflow. Artifact12109702848 has archive SHA-256 e969cc319cc71c6ff55d24c9ddc546d674f2035192e44f6586c5a6fe00b1117b and expires2027-01-15. Reconcile the latest release run before deployment; do not silently use historical backups. Production recovery remains separate and expires2026-10-30.
