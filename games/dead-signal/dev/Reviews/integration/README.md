# Dead Signal — combined parent integration report

Prepared 2026-10-16 for `integration/dead-signal-next-release`. Runtime version remains 1.9.0; this is an unpublished next-release candidate. It is separate from the newly approved 31-item Batch 1, whose follow-up implementation is tracked in [BATCH-1-TRACEABILITY.md](../../BATCH-1-TRACEABILITY.md).

## Integrated source

| Change | Reviewed feature head | Integration merge |
| --- | --- | --- |
| #18 actual loading-screen preview and tests | `6ca195b0b021f95a34ee8946d3d1bc884f902815` | `2ee30ed1518bf279650f3a2184ffdfb24f70aedf` |
| #21 three-map remaster / wall interactions | `6311ea3063bc789eea9cb0bc8876ef1f43f9b800` | `d16e845030c709b5d50d0bf256a3df232f6e6e9e` |
| #19 enemy retargeting / flanks / recovery | `7d5f23f48eb61fb57a0f785378b22010594237c9` | `de41aed95974d2319f1db8012737751bf039e4f3` |
| #20 weapons / ADS / combat input / HUD | `533614972cd0c17212203d3099202f534a75aed8` | `5912113a55899501eac0997c88c8829c536ff959` |

Main's latest Batch 1 planning documents (`5e7cc679`) were carried into integration first; they change no runtime source. Shared contracts, scoped Audio ownership and the 31-row follow-up traceability record are committed at `cfd816ac`. No specialist parent branch was rewritten. Conflicts were confined to the test runner and resolved by retaining every suite.

Maps now have different proportions, room shapes, optional loop endpoints, galleries and architectural details; buys, machines and objectives use separated wall bays with eye-height signs and reserved approaches. Enemies cancel stale prepared attacks on target changes, bound flank attempts, handle unusable native path responses and recover blocked entrances while preserving health/armor/cooldowns. Combat/UI improves sights, FOV-aware ADS, weapon mechanisms, focus/reload/swap cancellation and compact HUD placement around saved controls. The loading preview uses the actual retained module. Detailed lane reports and their offline illustrations are preserved beside this report; those pictures are not engine captures.

This integration adds 487 cross-lane regression assertions: every isolated gate, gallery recovery routes, the combined wall-display weapon revision, and six actual rig configurations against all three maps' portal dimensions and floor-height contracts. A read-only native candidate inspection verifies all 61 script sources and retained native art in each place. It never reserializes a world.

## Verified offline

| Check | Result |
| --- | --- |
| Combined Lune 0.11.0 suites | **20 passed / 580,040 assertions** |
| Runtime Luau compilation | **61 passed**, Luau 0.743 |
| All source/test/tool syntax | **93 files passed** |
| Existing Python pipeline tests | **59 passed** |
| Deployment manifests and configs | Four manifests; eight separate staging/production configs passed |
| Projected remaster clearance | Three maps; 30 purchase states; no projected clearance failures |
| Lossless builds and independent raw-property audit | All four staging and all four production comparison candidates passed |
| Source equivalence | 60 non-PlaceConfig scripts identical across environments; all 61 match the intended source/config for each place |
| Native reader | All four staging places reopen; 61 scripts each; existing meshes/materials retained |
| Protected inputs | **132 paths** verified against the original tree, including all native/backup binaries, historical source, workflows, scripts and active manifests |
| Original artwork | LoadingScreen remains blob `7aadee72efa020a0c798a8e10b90f4ebf89e358d`; original image IDs unchanged |

Runtime snapshot: `5912113a55899501eac0997c88c8829c536ff959`. Additional integrator changes are tests, tooling and records only. The downloadable package records its final review SHA and hashes; `Build-Report.json` contains every runtime source digest and all eight candidate hashes. Staging/production binaries differ only in generated PlaceConfig. Historical v1.8 labels in existing checker reports are infrastructure labels; inspected runtime Config is 1.9.0.

Unrelated raw chunks remain byte-identical: Dispatch 1,513; Blackwater 1,496; Cinderworks and Whiteout 1,500 each. Native MeshPart/SurfaceAppearance/MaterialVariant counts are Dispatch 962/873/24, Blackwater 726/661/24, Cinderworks 752/687/24, Whiteout 786/721/24. Lune's unsupported Terrain-property warning does not affect delivery: only the raw lossless patcher writes the candidate and the independent binary auditor checks preservation.

Reproduce from repository root: `python -m unittest discover -s tests -v`; `python scripts/validate.py`; `python scripts/generate_dead_signal_place_configs.py`; prepare the unchanged four staging fixtures as source CI does; run `dev/Tests/run.py` with pinned Lune and the Luau compiler; run `Tests/syntax.luau`, `Tests/check_map_remaster.py`, both environments of `scripts/patch_dead_signal_rbxl.py` / `scripts/audit_dead_signal_binary.py`, and `scripts/check_dead_signal_production.py`. From `dev`, run `Tools/inspect-integration-candidates.luau`. No publisher is part of these commands.

## Native acceptance and risk register

**No combined-candidate Studio, private Roblox-client, phone, real multiplayer or performance result is claimed.** The owner confirmed original artwork in the previously published production build; that result is retained as baseline evidence and must be regressed on this candidate. Use [ACCEPTANCE.md](ACCEPTANCE.md) to record actual observations and failures against an immutable candidate SHA.

| Risk / release gate | State and required action |
| --- | --- |
| Actual navmesh/physics, crowded gates, galleries, entry separation | Pending Studio and solo/2/4-client acceptance across all maps and both modes. Projected clearance and recovery timeouts do not prove the absence of safe spots. |
| Weapon/hand/ADS/HUD/sign quality | Pending actual rendering, font fitting, gun-by-gun and aspect-ratio review. Offline geometry is not a realism or readability acceptance result. |
| Performance | Foundry has the largest static detail increase. Measure build hitch, frame time, memory and path failures with 40 NPCs/eight hazards and corpses; compare normal/Low Effects on real target devices. |
| Interaction back sides | Existing reach/eligibility/allowWall policy is preserved. Check all wall targets, gates, overlapping repair/buy/revive prompts, and every box position. A demonstrated bypass needs an integrator-owned fix/test before release. |
| Current production recovery | Live release is source `1a5b9f3`, run `38985770842` attempt 4; versions Dispatch 28, Blackwater 22, Cinderworks 21, Whiteout 21. Checked-in production rollback files still contain **v1.7.0** and do not restore that live release. Preserve them; reconcile the actual workflow rollback selection with a current release recovery set before another publication. |
| Staging source selection | Existing controlled staging workflow checks out main and is main-only; it has no reviewed integration-SHA selector. Do not merge unaccepted game code to main merely to bypass this. A separately reviewed minimal source-pin extension or an owner-approved revision to the staging/merge order is a prerequisite to publishing this integration candidate. No workflow was changed or dispatched in this integration. |
| Repository enforcement | Branch metadata is unprotected; ruleset lookup reports private-repository plan restrictions. Protocol/CI are coordination controls, not an independently enforced required-review rule. |
| Audio / new Batch 1 work | Scoped audio contract granted; no Audio implementation accepted here. Custom recordings, rights/permissions, new military/K9 art and advanced traversal remain specialist follow-up requirements, not completed by these parent PRs. |
| Physical mobile comparison | Still deferred by owner. Saved layouts/input/settings remain compatible; no two-thumb comparison is claimed. |

Recommendation: **ready for an unpublished Studio review; not ready for production promotion**. Private staging publication remains separately unauthorized and blocked on the identified source-selection/recovery prerequisites. After Studio fixes, explicit staging authorization, private-client evidence and owner acceptance, prepare the reviewed final game PR to main. Production then needs a separate explicit owner authorization through the existing manual release system.

No deployment, native asset upload, profile migration or production update occurred. Revert scoped source merges and rebuild to undo this integration; never substitute a scripts-only world or overwrite historical native files.
