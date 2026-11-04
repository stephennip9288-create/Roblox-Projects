# Dead Signal Batch 1.1 — staging retest checklist

Pending for all six defects. This checklist is not publication authorization. Use the complete selected patch only after a separately approved controlled deployment succeeds for all four places. Unpublished Studio testing may precede that deployment.

Record source SHA, workflow run, returned place versions, map/room/window id, device, crew count, mode, round, effects/volume settings and Output/clip. The initial reports do not identify every failing window or stair; cover all generated cases rather than assuming one example is sufficient.

| Bug | Required native checks | Pass condition |
|---|---|---|
| DS-B1-001 Audio | Creator-approved realistic samples/permissions; every weapon class and reload/cancel/swap; local/remote near/far and indoor/outdoor; zombie/hound/entry/elite/warning cues; 40 actors and Low Effects; mute/volume; slow/failed first load, travel/respawn/results/cleanup | Natural, synchronized effects and readable threat direction/urgency. No stale replay, inappropriate sword/chirp/voice substitutions, masked critical cue or leak. Silence is not the requested overhaul. |
| DS-B1-002 Enemies + Maps | All 30 windows with Shambler, Runner, Crawler, Hound, Alpha, Stalker and eligible Warden; actual exterior support/full bounds; intact/torn boards, queued actors, player-blocked approach/landing, interrupted/dead actor, moving/downed/disconnected target; blocked entrance reroute | Continuous fair approach/contact/vault-or-crawl/land/pursuit; live collision and correct facing; bounded work and no overlap, clipping, visible teleport, lost quota or permanently stalled wave. |
| DS-B1-003 Maps | All rooms and Dispatch; straight/angled/hexagonal/curved wall bays, signs, lights, fixtures, machines and decorations; front/back approaches at first-person/mobile eye height; purchases and interaction reach | Correct wall attachment, proper front-facing readable text, no perpendicular/mirrored/floating part or obscured interaction. |
| DS-B1-004 Maps | All 18 rooms by believable function/site; compare baseline and patch views; walk/revive/chase around installations; inspect windows/buys/objectives/extraction; normal/Low Effects under dense waves | Purposeful thematic density without clutter, route/interaction obstruction, query/collision excess or unacceptable device frame-time cost. |
| DS-B1-005 Maps | Every stair/ramp in both directions; center and both edges; walk/sprint/ADS/backpedal/strafe; full head/shoulder body near deck cut, rails and landing; two passing players, down/revive, pursuing large enemy | Wedge collision/treads/support and deck geometry align. No head catch, protruding edge, gap, trap, one-way ledge or forced jump. |
| DS-B1-006 Enemies | All military/site families and evolved kinds; front/side/back, idle/gait/turn/attack/flinch/death, flat/ramp/gallery; native meshes/materials; hit zones, armor/weak points, live collision and ragdoll | Believable undead anatomy/skin/clothing/facial silhouette/movement with preserved military identity and combat correctness. Source projections do not certify native art. |

For reproducible entry reports, use the existing WindowBarrier EntryId/EntryRoom and Approach/Breach/Landing attributes. The Studio-only read-only diagnostic in ../../Tools/diagnose-batch1-1-studio.lua can collect snapshots; it is syntax-tested, not a substitute for gameplay.

Repeat whole-game checks: Dispatch -> all three maps -> extraction/return; Survival and Lockdown; solo/2/4; spawns and revive; purchases/all doors/upgrades; server-confirmed shots/damage; rounds/named special waves/Warden/extraction precedence and victory; original loading artwork; saved credits/XP/settings and environment isolation. Keep physical two-thumb comparison deferred. Follow the complete baseline checklist in ../batch1-integration/ACCEPTANCE.md as well.

Record Pass/Fail and evidence per bug. Move a bug to Verified only after its implemented fix passes its relevant actual staging retest. Owner acceptance and a separate explicit production authorization remain required.


## Combined Batch 1.1 entry/physics stress cases

Use the exact artifact/source hash from Build-Report.json; keep the prior deployed Batch 1 versions 11/10/10/10 as the rollback. Test all 12 stairs and both gallery directions, full-width edge approaches and low head/shoulder clearance, including passing players, downed/revive bodies, Warden and extraction escorts.

For Cinderworks/Foundry window 10, inspect the canonical foot-floor target near world X 229.3600006: the offline exact-center ray detects a narrow wedge seam. The Navigation consumer may shift the supported target by at most 0.05 world studs and still checks real foot/paw support and complete sweeps. In Studio, walk the actual seam/apron/landing with player and each of 7 eligible profiles. A source-ray workaround is not proof that native collision is safe. Record whether that bounded target remains supported under real Roblox rays/physics and network replication.

Exercise mixed queues at 4/12/24/40 units, several approaching one window and converging nearby windows; blocked entry during approach/contact/cross/descent; repairs/death/stun; alive/downed player occupying destination. Confirm actual collision, fair queue drain, alternate supported landing, checked reversal and bounded physical recovery. With no safe admission slot, tickets must remain outside the live model list yet count toward cap/quota; no transient unsafe spawn, interior pop-in, silent retirement or false Warden defeat. Loss/removal of a live model must preserve HP/maxHP, armor/weak points/rewards and boss/ability cooldowns through readmission. If every eligible route is genuinely impossible, report a release-blocking geometry/navigation defect rather than deleting quota to end the wave.

Record actual Studio server/client and private-staging evidence separately for Survival/Lockdown and solo/2/4 crews. No test row can become Verified based on CI, SAT/rays, SVG bounds or Lune read-only deserialization.
